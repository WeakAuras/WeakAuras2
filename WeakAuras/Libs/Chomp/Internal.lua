--[[
	© Justin Snelgrove

	Permission to use, copy, modify, and distribute this software for any
	purpose with or without fee is hereby granted, provided that the above
	copyright notice and this permission notice appear in all copies.

	THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
	WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
	SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
	WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
	OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
	CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

local VERSION = 32

if IsLoggedIn() then
	error(("Chomp Message Library (embedded: %s) cannot be loaded after login."):format((...)))
	return
end

local Chomp = LibStub:NewLibrary("Chomp", VERSION)

if not Chomp then
	return
end

Chomp.Internal = Chomp.Internal or __chomp_internal or CreateFrame("Frame")
Chomp.Internal.LOADING = true

local Internal = Chomp.Internal

Internal.callbacks = LibStub:GetLibrary("CallbackHandler-1.0"):New(Internal)

--[[
	INTERNAL TABLES
]]

if not Internal.Filter then
	Internal.Filter = {}
end

if not Internal.Prefixes then
	Internal.Prefixes = {}
end

if Internal.ErrorCallbacks then
	-- v18+: Use CallbackHandler internally; relocate any registered error
	--       callbacks to the registry.

	for _, callback in ipairs(Internal.ErrorCallbacks) do
		local event = "OnError"
		local func  = function(_, ...) return callback(...) end
		local owner = tostring(callback)

		Internal.RegisterCallback(owner, event, func)
	end

	Internal.ErrorCallbacks = nil
end

Internal.BITS = {
	SERIALIZE = 0x001,
	CODECV2   = 0x002,  -- Indicates the message should be processed with codec version 2. Relies upon VERSION16.
	UNUSED9   = 0x004,
	VERSION16 = 0x008,  -- Indicates v16+ of Chomp is in use from the sender.
	BROADCAST = 0x010,
	NOTUSED6  = 0x020,  -- This is unused but won't report as such on receipt; use sparingly!
	UNUSED5   = 0x040,
	UNUSED4   = 0x080,
	UNUSED3   = 0x100,
	UNUSED2   = 0x200,
	UNUSED1   = 0x400,
	DEPRECATE = 0x800,
}

Internal.KNOWN_BITS = 0

for purpose, bits in pairs(Internal.BITS) do
	if not purpose:find("UNUSED", nil, true) then
		Internal.KNOWN_BITS = bit.bor(Internal.KNOWN_BITS, bits)
	end
end

--[[
	HELPER FUNCTIONS
]]

local oneTimeError
local function HandleMessageIn(prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)
	if not Internal.isReady then
		if not Internal.IncomingQueue then
			Internal.IncomingQueue = {}
		end
		local q = Internal.IncomingQueue
		q[#q + 1] = { prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID }
		return
	end

	local prefixData = Internal.Prefixes[prefix]
	if not prefixData then
		return
	end

	local bitField, sessionID, msgID, msgTotal, userText = text:match("^(%x%x%x)(%x%x%x)(%x%x%x)(%x%x%x)(.*)$")
	bitField = bitField and tonumber(bitField, 16) or 0
	sessionID = sessionID and tonumber(sessionID, 16) or -1
	msgID = msgID and tonumber(msgID, 16) or 1
	msgTotal = msgTotal and tonumber(msgTotal, 16) or 1

	if userText then
		text = userText
	end

	local method = channel:match("%:(%u+)$")
	if method == "BATTLENET" or method == "LOGGED" then
		text = Internal.DecodeQuotedPrintable(text, method == "LOGGED")
	end

	if bit.bor(bitField, Internal.KNOWN_BITS) ~= Internal.KNOWN_BITS or bit.band(bitField, Internal.BITS.DEPRECATE) == Internal.BITS.DEPRECATE then
		-- Uh, found an unknown bit, or a bit we're explicitly not to parse.
		if not oneTimeError then
			oneTimeError = true
			error("Chomp: Received an addon message that cannot be parsed, check your addons for updates. (This message will only display once per session, but there may be more unusable addon messages.)")
		end
		return
	end

	if not prefixData[sender] then
		prefixData[sender] = {}
	end

	local isBroadcast = bit.band(bitField, Internal.BITS.BROADCAST) == Internal.BITS.BROADCAST
	if isBroadcast then
		if not prefixData.broadcastPrefix then
			-- If the prefix doesn't want broadcast data, don't even parse
			-- further at all.
			return
		end
		if msgID == 1 then
			local broadcastTarget, broadcastText = text:match("^([^\058\127]*)[\058\127](.*)$")
			local ourName = Chomp.NameMergedRealm(UnitFullName("player"))
			if sender == ourName or broadcastTarget ~= "" and broadcastTarget ~= ourName then
				-- Not for us, quit processing.
				return
			else
				target = ourName
				text = broadcastText
			end
		elseif not prefixData[sender][sessionID] then
			-- Already determined this session ID is not for us, or we came in
			-- somewhere in the middle (and can't determine if it was for us).
			return
		else
			target = prefixData[sender][sessionID].broadcastTarget
		end
		-- Last but not least, fake the channel type.
		channel = channel:gsub("^[^%:]+", "WHISPER")
	end

	if prefixData.rawCallback then
		securecallfunction(prefixData.rawCallback, prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID, nil, nil, nil, sessionID, msgID, msgTotal, bitField)
	end

	local deserialize = bit.band(bitField, Internal.BITS.SERIALIZE) == Internal.BITS.SERIALIZE
	local fullMsgOnly = prefixData.fullMsgOnly or deserialize

	if not prefixData[sender][sessionID] then
		prefixData[sender][sessionID] = {}
		if isBroadcast then
			prefixData[sender][sessionID].broadcastTarget = target
		end
	end
	local buffer = prefixData[sender][sessionID]
	buffer[msgID] = text

	local runHandler = true
	for i = 1, msgTotal do
		if buffer[i] == nil then
			-- msgTotal has changed, either by virtue of being the first
			-- message or by correction in other side's calculations.
			buffer[i] = true
			runHandler = false
		elseif buffer[i] == true then
			-- Need to hold this message until we're ready to process.
			runHandler = false
		elseif runHandler and buffer[i] and (not fullMsgOnly or i == msgTotal) then
			local handlerData = buffer[i]
			-- This message is ready for processing.
			if fullMsgOnly then
				handlerData = table.concat(buffer)
				if deserialize then
					local success, original = pcall(Chomp.Deserialize, handlerData)
					if success then
						handlerData = original
					else
						handlerData = nil
					end
				end
			end
			if prefixData.validTypes[type(handlerData)] then
				securecallfunction(prefixData.callback, prefix, handlerData, channel, sender, target, zoneChannelID, localID, name, instanceID, nil, nil, nil, sessionID, msgID, msgTotal, bitField)
				Internal:TriggerEvent("OnMessageReceived", prefix, handlerData, channel, sender, target, zoneChannelID, localID, name, instanceID, nil, nil, nil, sessionID, msgID, msgTotal, bitField)
			end
			buffer[i] = false
			if i == msgTotal then
				-- Tidy up the garbage when we've processed the last
				-- pending message.
				prefixData[sender][sessionID] = nil
			end
		end
	end
end

local function ParseInGameMessage(prefix, text, kind, sender, target, zoneChannelID, localID, name, instanceID)
	if kind == "WHISPER" then
		target = Chomp.NameMergedRealm(target)
	end
	return prefix, text, kind, Chomp.NameMergedRealm(sender), target, zoneChannelID, localID, name, instanceID
end

local function ParseInGameMessageLogged(prefix, text, kind, sender, target, zoneChannelID, localID, name, instanceID)
	if kind == "WHISPER" then
		target = Chomp.NameMergedRealm(target)
	end
	return prefix, text, ("%s:LOGGED"):format(kind), Chomp.NameMergedRealm(sender), target, zoneChannelID, localID, name, instanceID
end

local function ParseBattleNetMessage(prefix, text, kind, bnetIDGameAccount)
	local name = Internal:GetBattleNetAccountName(bnetIDGameAccount)

	if not name then
		return
	end

	return prefix, text, ("%s:BATTLENET"):format(kind), name, Chomp.NameMergedRealm(UnitName("player")), 0, 0, "", 0
end

function Internal:TriggerEvent(event, ...)
	return self.callbacks:Fire(event, ...)
end

--[[
	FUNCTION HOOKS
]]

-- Hooks don't trigger if the hooked function errors, so there's no need to
-- check parameters, if those parameters cause errors (which most don't now).

local FILTER_PATTERN = ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)")
local lastFilteredLineID = nil

if not Internal.MessageFilterKeyCache then
	Internal.MessageFilterKeyCache = {}
end

local function GenerateMessageFilterKey(target)
	-- Due to systemic issues across ourselves, LibMSP, TRP, etc. this
	-- filter has been hacked to only use the character name of the player
	-- and to discard the realm.

	local filterKey = string.split("-", target, 2)

	if string.utf8lower then
		filterKey = string.utf8lower(filterKey)
	else
		filterKey = string.lower(filterKey)
	end

	return filterKey
end

setmetatable(Internal.MessageFilterKeyCache, {
	__index = function(self, target)
		local filterKey = GenerateMessageFilterKey(target)
		self[target] = filterKey
		return filterKey
	end,
})

local function MessageEventFilter_SYSTEM (self, event, text, ...)
	local name = text:match(FILTER_PATTERN)
	if not name then
		return false
	end

	local filterKey = Internal.MessageFilterKeyCache[name]

	if not Internal.Filter[filterKey] or Internal.Filter[filterKey] < GetTime() then
		Internal.Filter[filterKey] = nil
		return false
	end

	local lineID = select(10, ...)

	if lineID ~= lastFilteredLineID then
		Internal:TriggerEvent("OnError", name)
		lastFilteredLineID = lineID
	end

	return true
end

local function HookSendAddonMessage(prefix, text, kind, target)
	if kind == "WHISPER" and target then
		local filterKey = Internal.MessageFilterKeyCache[target]
		Internal.Filter[filterKey] = GetTime() + (select(3, GetNetStats()) * 0.001) + 5.000
	end
end

local function HookSendAddonMessageLogged(prefix, text, kind, target)
	if kind == "WHISPER" and target then
		local filterKey = Internal.MessageFilterKeyCache[target]
		Internal.Filter[filterKey] = GetTime() + (select(3, GetNetStats()) * 0.001) + 5.000
	end
end

--[[
	BATTLE.NET WRAPPER API
]]

local function EnumerateFriendGameAccounts()
	local friendIndex  = 0
	local friendCount  = BNGetNumFriends()
	local accountIndex = 0
	local accountCount = 0

	local function NextGameAccount()
		repeat
			accountIndex = accountIndex + 1

			if accountIndex > accountCount then
				friendIndex  = friendIndex + 1
				accountIndex = 1
				accountCount = C_BattleNet.GetFriendNumGameAccounts(friendIndex)
			end
		until accountIndex <= accountCount or friendIndex > friendCount

		if friendIndex <= friendCount and accountIndex <= accountCount then
			return friendIndex, accountIndex, C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex)
		end
	end

	return NextGameAccount
end

local function CanExchangeWithGameAccount(account)
	if not account.isOnline then
		return false  -- Friend isn't even online.
	elseif account.clientProgram ~= BNET_CLIENT_WOW then
		return false  -- Friend isn't playing WoW. Imagine.
	elseif not account.isInCurrentRegion then
		return false
	end

	local characterName = account.characterName
	local realmName     = account.realmName and Chomp.NormalizeRealmName(account.realmName) or nil
	local factionName   = account.factionName

	if not characterName or characterName == "" or characterName == UNKNOWNOBJECT then
		return false  -- Character name is invalid.
	elseif not realmName or realmName == "" then
		return false  -- Realm name is invalid.
	elseif Internal.SameRealm[realmName] and factionName == UnitFactionGroup("player") then
		return false  -- This character is on the same faction and realm.
	else
		return true
	end
end

function Internal:UpdateBattleNetAccountData()
	self.bnetGameAccounts = {}

	if not BNFeaturesEnabledAndConnected() then
		return  -- Player isn't connected to Battle.net.
	elseif not IsLoggedIn() then
		return  -- Player hasn't yet logged in.
	end

	for _, _, account in EnumerateFriendGameAccounts() do
		if CanExchangeWithGameAccount(account) then
			local characterName = account.characterName
			local realmName = Chomp.NormalizeRealmName(account.realmName)
			local mergedName = Chomp.NameMergedRealm(characterName, realmName)

			self.bnetGameAccounts[mergedName] = account.gameAccountID
		end
	end
end

function Internal:GetBattleNetAccountName(senderAccountID)
	if not BNFeaturesEnabledAndConnected() then
		return nil  -- Player isn't connected to Battle.net.
	elseif not self.bnetGameAccounts then
		return nil  -- We have no game accounts to search.
	end

	for playerName, gameAccountID in pairs(self.bnetGameAccounts) do
		if gameAccountID == senderAccountID then
			return playerName
		end
	end

	return nil
end

function Internal:GetBattleNetAccountID(targetName)
	if not BNFeaturesEnabledAndConnected() then
		return nil  -- Player isn't connected to Battle.net.
	elseif not self.bnetGameAccounts then
		return nil  -- We have no game accounts to search.
	elseif UnitGUID(Ambiguate(targetName, "none")) then
		return nil  -- We think the player is in our group.
	end

	for playerName, gameAccountID in pairs(self.bnetGameAccounts) do
		if strcmputf8i(playerName, targetName) == 0 then
			return gameAccountID
		end
	end

	return nil
end

--[[
	FRAME SCRIPTS
]]

Internal:Hide()
Internal:RegisterEvent("ADDON_LOADED")
Internal:RegisterEvent("CHAT_MSG_ADDON")
Internal:RegisterEvent("CHAT_MSG_ADDON_LOGGED")
Internal:RegisterEvent("BN_CHAT_MSG_ADDON")
Internal:RegisterEvent("PLAYER_LOGIN")
Internal:RegisterEvent("PLAYER_LEAVING_WORLD")
Internal:RegisterEvent("PLAYER_ENTERING_WORLD")
Internal:RegisterEvent("BN_CONNECTED")
Internal:RegisterEvent("BN_DISCONNECTED")
Internal:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
Internal:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
Internal:RegisterEvent("BN_FRIEND_INFO_CHANGED")
Internal:RegisterEvent("FRIENDLIST_UPDATE")

Internal:SetScript("OnEvent", function(self, event, ...)
	if event == "CHAT_MSG_ADDON" then
		HandleMessageIn(ParseInGameMessage(...))
	elseif event == "CHAT_MSG_ADDON_LOGGED" then
		HandleMessageIn(ParseInGameMessageLogged(...))
	elseif event == "BN_CHAT_MSG_ADDON" then
		HandleMessageIn(ParseBattleNetMessage(...))
	elseif event == "BN_CONNECTED"
		or event == "BN_DISCONNECTED"
		or event == "BN_FRIEND_ACCOUNT_OFFLINE"
		or event == "BN_FRIEND_ACCOUNT_ONLINE"
		or event == "BN_FRIEND_INFO_CHANGED"
		or event == "FRIENDLIST_UPDATE" then
		Internal:UpdateBattleNetAccountData()
	elseif event == "PLAYER_LOGIN" then
		_G.__chomp_internal = nil
		hooksecurefunc(C_ChatInfo, "SendAddonMessage", HookSendAddonMessage)
		hooksecurefunc(C_ChatInfo, "SendAddonMessageLogged", HookSendAddonMessageLogged)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", MessageEventFilter_SYSTEM)
		self.SameRealm = {}
		self.SameRealm[(Chomp.NormalizeRealmName(GetRealmName()))] = true
		for i, realm in ipairs(GetAutoCompleteRealms()) do
			self.SameRealm[(Chomp.NormalizeRealmName(realm))] = true
		end
		Internal.isReady = true
		if self.IncomingQueue then
			for i, q in ipairs(self.IncomingQueue) do
				HandleMessageIn(unpack(q, 1, 4))
			end
			self.IncomingQueue = nil
		end
		Internal:UpdateBattleNetAccountData()
	elseif event == "PLAYER_LEAVING_WORLD" then
		self.unloadTime = GetTime()
	elseif event == "PLAYER_ENTERING_WORLD" and self.unloadTime then
		local loadTime = GetTime() - self.unloadTime
		for filterKey, filterTime in pairs(self.Filter) do
			if filterTime >= self.unloadTime then
				self.Filter[filterKey] = filterTime + loadTime
			else
				self.Filter[filterKey] = nil
			end
		end
		self.unloadTime = nil
		Internal:UpdateBattleNetAccountData()
	elseif event == "ADDON_LOADED" then
		-- Tweak CTL's conservative estimates.
		if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
			ChatThrottleLib.BURST = math.max(ChatThrottleLib.BURST, 6144)
			ChatThrottleLib.MAX_CPS = math.max(ChatThrottleLib.MAX_CPS, 2048)
			ChatThrottleLib.MSG_OVERHEAD = math.min(32, ChatThrottleLib.MSG_OVERHEAD)
		end
	end
end)

Internal.VERSION = VERSION

-- v18+: The future is now old man. These need to exist for compatibility, and
--       to prevent issues where pre-v18 versions would replace newer ones if
--       __chomp_internal were to just disappear.
--
--       Note that we still clear __chomp_internal once PLAYER_LOGIN has
--       fired, but we don't remove  access to it from the library table
--       because being able to inspect it at runtime is nice.

_G.__chomp_internal = Internal
_G.AddOn_Chomp = Chomp