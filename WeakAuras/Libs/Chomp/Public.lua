--[[
	© Justin Snelgrove
	© Morgane Parize

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

local Chomp = LibStub:GetLibrary("Chomp", true)
local Internal = Chomp and Chomp.Internal or nil

if not Chomp or not Internal or not Internal.LOADING then
	return
end

local DEFAULT_PRIORITY = "NORMAL"
local PRIORITIES_HASH = { HIGH = true, MEDIUM = true, LOW = true }
local PRIORITY_TO_CTL = { LOW = "BULK", MEDIUM = "NORMAL", HIGH = "ALERT" }

function Chomp.SendAddonMessage(prefix, text, kind, target, priority, queue, callback, callbackArg)
	if type(prefix) ~= "string" then
		error("Chomp.SendAddonMessage: prefix: expected string, got " .. type(prefix), 2)
	elseif type(text) ~= "string" then
		error("Chomp.SendAddonMessage: text: expected string, got " .. type(text), 2)
	elseif kind == "WHISPER" and type(target) ~= "string" then
		error("Chomp.SendAddonMessage: target: expected string, got " .. type(target), 2)
	elseif kind == "CHANNEL" and type(target) ~= "number" then
		error("Chomp.SendAddonMessage: target: expected number, got " .. type(target), 2)
	elseif priority and not PRIORITIES_HASH[priority] then
		error("Chomp.SendAddonMessage: priority: expected \"HIGH\", \"MEDIUM\", \"LOW\", or nil, got " .. tostring(priority), 2)
	elseif queue and type(queue) ~= "string" then
		error("Chomp.SendAddonMessage: queue: expected string or nil, got " .. type(queue), 2)
	elseif callback and type(callback) ~= "function" then
		error("Chomp.SendAddonMessage: callback: expected function or nil, got " .. type(callback), 2)
	end

	local length = #text
	if length > 255 then
		error("Chomp.SendAddonMessage: text length cannot exceed 255 bytes", 2)
	elseif #prefix > 16 then
		error("Chomp.SendAddonMessage: prefix: length cannot exceed 16 bytes", 2)
	end

	if not kind then
		kind = "PARTY"
	else
		kind = kind:upper()
	end

	ChatThrottleLib:SendAddonMessage(PRIORITY_TO_CTL[priority] or DEFAULT_PRIORITY, prefix, text, kind, target, queue, callback, callbackArg)
end

function Chomp.SendAddonMessageLogged(prefix, text, kind, target, priority, queue, callback, callbackArg)
	if type(prefix) ~= "string" then
		error("Chomp.SendAddonMessageLogged: prefix: expected string, got " .. type(prefix), 2)
	elseif type(text) ~= "string" then
		error("Chomp.SendAddonMessageLogged: text: expected string, got " .. type(text), 2)
	elseif kind == "WHISPER" and type(target) ~= "string" then
		error("Chomp.SendAddonMessageLogged: target: expected string, got " .. type(target), 2)
	elseif kind == "CHANNEL" and type(target) ~= "number" then
		error("Chomp.SendAddonMessageLogged: target: expected number, got " .. type(target), 2)
	elseif priority and not PRIORITIES_HASH[priority] then
		error("Chomp.SendAddonMessageLogged: priority: expected \"HIGH\", \"MEDIUM\", \"LOW\", or nil, got " .. tostring(priority), 2)
	elseif queue and type(queue) ~= "string" then
		error("Chomp.SendAddonMessageLogged: queue: expected string or nil, got " .. type(queue), 2)
	elseif callback and type(callback) ~= "function" then
		error("Chomp.SendAddonMessageLogged: callback: expected function or nil, got " .. type(callback), 2)
	end

	local length = #text
	if length > 255 then
		error("Chomp.SendAddonMessageLogged: text length cannot exceed 255 bytes", 2)
	elseif #prefix > 16 then
		error("Chomp.SendAddonMessageLogged: prefix: length cannot exceed 16 bytes", 2)
	end

	if not kind then
		kind = "PARTY"
	else
		kind = kind:upper()
	end

	ChatThrottleLib:SendAddonMessageLogged(PRIORITY_TO_CTL[priority] or DEFAULT_PRIORITY, prefix, text, kind, target, queue, callback, callbackArg)
end

function Chomp.SendChatMessage(text, kind, language, target, priority, queue, callback, callbackArg)
	if type(text) ~= "string" then
		error("Chomp.SendChatMessage: text: expected string, got " .. type(text), 2)
	elseif language and type(language) ~= "string" and type(language) ~= "number" then
		error("Chomp.SendChatMessage: language: expected string or number, got " .. type(language), 2)
	elseif kind == "WHISPER" and type(target) ~= "string" then
		error("Chomp.SendChatMessage: target: expected string, got " .. type(target), 2)
	elseif kind == "CHANNEL" and type(target) ~= "number" then
		error("Chomp.SendChatMessage: target: expected number, got " .. type(target), 2)
	elseif priority and not PRIORITIES_HASH[priority] then
		error("Chomp.SendChatMessage: priority: expected \"HIGH\", \"MEDIUM\", \"LOW\", or nil, got " .. tostring(priority), 2)
	elseif queue and type(queue) ~= "string" then
		error("Chomp.SendChatMessage: queue: expected string or nil, got " .. type(queue), 2)
	elseif callback and type(callback) ~= "function" then
		error("Chomp.SendChatMessage: callback: expected function or nil, got " .. type(callback), 2)
	end

	local length = #text
	if length > 255 then
		error("Chomp.SendChatMessage: text length cannot exceed 255 bytes", 2)
	end

	if not kind then
		kind = "SAY"
	else
		kind = kind:upper()
	end

	ChatThrottleLib:SendChatMessage(PRIORITY_TO_CTL[priority] or DEFAULT_PRIORITY, "Chomp", text, kind, language, target, queue, callback, callbackArg)
end

function Chomp.BNSendGameData(bnetIDGameAccount, prefix, text, priority, queue, callback, callbackArg)
	if type(prefix) ~= "string" then
		error("Chomp.BNSendGameData: prefix: expected string, got " .. type(text), 2)
	elseif type(text) ~= "string" then
		error("Chomp.BNSendGameData: text: expected string, got " .. type(text), 2)
	elseif type(bnetIDGameAccount) ~= "number" then
		error("Chomp.BNSendGameData: bnetIDGameAccount: expected number, got " .. type(bnetIDGameAccount), 2)
	elseif priority and not PRIORITIES_HASH[priority] then
		error("Chomp.BNSendGameData: priority: expected \"HIGH\", \"MEDIUM\", \"LOW\", or nil, got " .. tostring(priority), 2)
	elseif queue and type(queue) ~= "string" then
		error("Chomp.BNSendGameData: queue: expected string or nil, got " .. type(queue), 2)
	elseif callback and type(callback) ~= "function" then
		error("Chomp.BNSendGameData: callback: expected function or nil, got " .. type(callback), 2)
	end

	local length = #text
	if length > 255 then
		error("Chomp.BNSendGameData: text: length cannot exceed 255 bytes", 2)
	elseif #prefix > 16 then
		error("Chomp.BNSendGameData: prefix: length cannot exceed 16 bytes", 2)
	end

	local kind = "WHISPER"
	ChatThrottleLib:BNSendGameData(PRIORITY_TO_CTL[priority] or DEFAULT_PRIORITY, prefix, text, kind, bnetIDGameAccount, queue, callback, callbackArg)
end

function Chomp.IsSending()
	-- v26+: Removed with no replacement.
	return false
end

local DEFAULT_SETTINGS = {
	fullMsgOnly = true,
	validTypes = {
		["string"] = true,
	},
}
function Chomp.RegisterAddonPrefix(prefix, callback, prefixSettings)
	local prefixType = type(prefix)
	if prefixType ~= "string" then
		error("Chomp.RegisterAddonPrefix: prefix: expected string, got " .. prefixType, 2)
	elseif prefixType == "string" and #prefix > 16 then
		error("Chomp.RegisterAddonPrefix: prefix: length cannot exceed 16 bytes", 2)
	elseif type(callback) ~= "function" then
		error("Chomp.RegisterAddonPrefix: callback: expected function, got " .. type(callback), 2)
	elseif prefixSettings and type(prefixSettings) ~= "table" then
		error("Chomp.RegisterAddonPrefix: prefixSettings: expected table or nil, got " .. type(prefixSettings), 2)
	end
	if not prefixSettings then
		prefixSettings = DEFAULT_SETTINGS
	end
	if prefixSettings.validTypes and type(prefixSettings.validTypes) ~= "table" then
		error("Chomp.RegisterAddonPrefix: prefixSettings.validTypes: expected table or nil, got " .. type(prefixSettings.validTypes), 2)
	elseif prefixSettings.rawCallback and type(prefixSettings.rawCallback) ~= "function" then
		error("Chomp.RegisterAddonPrefix: prefixSettings.rawCallback: expected function or nil, got " .. type(prefixSettings.rawCallback), 2)
	end
	local prefixData = Internal.Prefixes[prefix]
	if not prefixData then
		prefixData = {
			callback = callback,
			rawCallback = prefixSettings.rawCallback,
			fullMsgOnly = prefixSettings.fullMsgOnly,
			broadcastPrefix = prefixSettings.broadcastPrefix,
		}
		local validTypes = prefixSettings.validTypes or DEFAULT_SETTINGS.validTypes
		prefixData.validTypes = {}
		for dataType, func in pairs(Internal.Serialize) do
			if validTypes[dataType] then
				prefixData.validTypes[dataType] = true
			end
		end
		Internal.Prefixes[prefix] = prefixData
		if not C_ChatInfo.IsAddonMessagePrefixRegistered(prefix) then
			C_ChatInfo.RegisterAddonMessagePrefix(prefix)
		end
	else
		error("Chomp.RegisterAddonPrefix: prefix handler already registered, Chomp currently supports only one handler per prefix")
	end
end

function Chomp.IsAddonPrefixRegistered(prefix)
	return Internal.Prefixes[prefix] ~= nil
end

local nextSessionID = math.random(0, 4095)
local function SplitAndSend(sendFunc, maxSize, bitField, prefix, text, ...)
	local textLen = #text
	-- Subtract Chomp metadata from maximum size.
	maxSize = maxSize - 12
	local totalOffset = 0
	local msgID = 0
	local totalMsg = math.ceil(textLen / maxSize)
	local sessionID = nextSessionID
	nextSessionID = (nextSessionID + 1) % 4096
	local position = 1
	while position <= textLen do
		-- Only *need* to do a safe substring for encoded channels, but doing so
		-- always shouldn't hurt.
		local msgText, offset = Chomp.SafeSubString(text, position, position + maxSize - 1, textLen)
		if offset > 0 then
			-- Update total offset and total message number if needed.
			totalOffset = totalOffset + offset
			totalMsg = math.ceil((textLen + totalOffset) / maxSize)
		end
		msgID = msgID + 1
		msgText = ("%03X%03X%03X%03X%s"):format(bitField, sessionID, msgID, totalMsg, msgText)
		sendFunc(prefix, msgText, ...)
		position = position + maxSize - offset
	end
end

local function ToInGame(bitField, prefix, text, kind, target, priority, queue)
	return SplitAndSend(Chomp.SendAddonMessage, 255, bitField, prefix, text, kind, target, priority, queue)
end

local function ToInGameLogged(bitField, prefix, text, kind, target, priority, queue)
	return SplitAndSend(Chomp.SendAddonMessageLogged, 255, bitField, prefix, text, kind, target, priority, queue)
end

local function BNSendGameDataRearrange(prefix, text, bnetIDGameAccount, ...)
	return Chomp.BNSendGameData(bnetIDGameAccount, prefix, text, ...)
end

local function ToBattleNet(bitField, prefix, text, kind, bnetIDGameAccount, priority, queue)
	return SplitAndSend(BNSendGameDataRearrange, 255, bitField, prefix, text, bnetIDGameAccount, priority, queue)
end

local DEFAULT_OPTIONS = {}
function Chomp.SmartAddonMessage(prefix, data, kind, target, messageOptions)
	local prefixData = Internal.Prefixes[prefix]
	if not prefixData then
		error("Chomp.SmartAddonMessage: prefix: prefix has not been registered with Chomp", 2)
	elseif type(kind) ~= "string" then
		error("Chomp.SmartAddonMessage: kind: expected string, got " .. type(kind), 2)
	elseif kind == "WHISPER" and type(target) ~= "string" then
		error("Chomp.SmartAddonMessage: target: expected string, got " .. type(target), 2)
	elseif kind == "CHANNEL" and type(target) ~= "number" then
		error("Chomp.SmartAddonMessage: target: expected number, got " .. type(target), 2)
	elseif target and kind ~= "WHISPER" and kind ~= "CHANNEL" then
		error("Chomp.SmartAddonMessage: target: expected nil, got " .. type(target), 2)
	end

	if not messageOptions then
		messageOptions = DEFAULT_OPTIONS
	end

	local dataType = type(data)
	if not prefixData.validTypes[dataType] then
		error("Chomp.SmartAddonMessage: data: type not registered as valid: " .. dataType, 2)
	elseif dataType ~= "string" and not messageOptions.serialize then
		error("Chomp.SmartAddonMessage: data: no serialization requested, but serialization required for type: " .. dataType, 2)
	elseif messageOptions.priority and not PRIORITIES_HASH[messageOptions.priority] then
		error("Chomp.SmartAddonMessage: messageOptions.priority: expected \"HIGH\", \"MEDIUM\", or \"LOW\", got " .. tostring(messageOptions.priority), 2)
	elseif messageOptions.queue and type(messageOptions.queue) ~= "string" then
		error("Chomp.SmartAddonMessage: messageOptions.queue: expected string or nil, got " .. type(messageOptions.queue), 2)
	end

	local bitField = 0x000

	-- v32: Always set the VERSION16 and CODECV2 bits. Versions older than
	--      this will discard messages without these bits set. Once newer
	--      versions are widely distributed, we can stop setting these bits.
	bitField = bit.bor(bitField, Internal.BITS.VERSION16, Internal.BITS.CODECV2)

	if messageOptions.serialize then
		bitField = bit.bor(bitField, Internal.BITS.SERIALIZE)
		data = Chomp.Serialize(data)
	end
	if not messageOptions.binaryBlob then
		local permitted, reason = Chomp.CheckLoggedContents(data)
		if not permitted then
			error(("Chomp.SmartAddonMessage: data: messageOptions.binaryBlob not specified, but disallowed sequences found, code: %s"):format(reason), 2)
		end
	end

	if kind == "WHISPER" then
		target = Chomp.NameMergedRealm(target)
	end

	if kind == "WHISPER" then
		-- GetBattleNetAccountID() only returns an ID for crossfaction and
		-- crossrealm targets.
		local bnetIDGameAccount = Internal:GetBattleNetAccountID(target)
		if bnetIDGameAccount then
			ToBattleNet(bitField, prefix, Internal.EncodeQuotedPrintable(data, false), kind, bnetIDGameAccount, messageOptions.priority, messageOptions.queue)
			return "BATTLENET"
		end
	end

	if not messageOptions.binaryBlob then
		ToInGameLogged(bitField, prefix, Internal.EncodeQuotedPrintable(data, true), kind, target, messageOptions.priority, messageOptions.queue)
		return "LOGGED"
	end
	ToInGame(bitField, prefix, data, kind, target, messageOptions.priority, messageOptions.queue)
	return "UNLOGGED"
end

function Chomp.CheckReportGUID(prefix, guid)
	-- v26+: Removed with no replacement.
	return false
end

function Chomp.ReportGUID(prefix, guid, customMessage)
	-- v26+: Removed with no replacement.
	return false, ""
end

Chomp.Event = {
	OnMessageReceived = "OnMessageReceived",
	OnError = "OnError",
}

function Chomp.RegisterCallback(event, func, owner)
	if type(event) ~= "string" then
		error("Chomp.RegisterCallback: 'event' must be a string")
	elseif not Chomp.Event[event] then
		error(string.format("Chomp.RegisterCallback: event %q does not exist", event))
	elseif type(func) ~= "function" and type(func) ~= "table" then
		error("Chomp.RegisterCallback: 'func' must be callable")
	elseif type(owner) ~= "string" and type(owner) ~= "table" and type(owner) ~= "thread" then
		error("Chomp.RegisterCallback: 'owner' must be string, table, or coroutine")
	end

	Internal.RegisterCallback(owner, event, function(_, ...) return func(owner, ...) end)
end

function Chomp.UnregisterCallback(event, owner)
	if type(event) ~= "string" then
		error("Chomp.UnregisterCallback: 'event' must be a string")
	elseif not Chomp.Event[event] then
		error(string.format("Chomp.UnregisterCallback: event %q does not exist", event))
	elseif type(owner) ~= "string" and type(owner) ~= "table" and type(owner) ~= "thread" then
		error("Chomp.UnregisterCallback: 'owner' must be string, table, or coroutine")
	end

	Internal.UnregisterCallback(owner, event)
end

function Chomp.UnregisterAllCallbacks(owner)
	if type(owner) ~= "string" and type(owner) ~= "table" and type(owner) ~= "thread" then
		error("Chomp.UnregisterAllCallbacks: 'owner' must be string, table, or coroutine")
	end

	Internal.UnregisterAllCallbacks(owner)
end

function Chomp.RegisterErrorCallback(callback)
	-- v18+: RegisterErrorCallback is deprecated in favor of the generic
	--       RegisterCallback system.

	local event = "OnError"
	local func  = function(_, ...) return callback(...) end
	local owner = tostring(callback)

	Chomp.RegisterCallback(event, func, owner)

	return true
end

function Chomp.UnregisterErrorCallback(callback)
	-- v18+: UnregisterErrorCallback is deprecated in favor of the generic
	--       UnregisterCallback system.

	local event = "OnError"
	local owner = tostring(callback)

	Chomp.UnregisterCallback(event, owner)

	return true
end

-- v18+: Deprecated alias for the old typo'd function name.
Chomp.UnegisterErrorCallback = Chomp.UnregisterErrorCallback

function Chomp.GetBPS()
	return ChatThrottleLib.MAX_CPS, ChatThrottleLib.BURST
end

function Chomp.SetBPS(bps, burst)
	ChatThrottleLib.MAX_CPS = bps
	ChatThrottleLib.BURST = burst
end

function Chomp.GetVersion()
	return Internal.VERSION
end