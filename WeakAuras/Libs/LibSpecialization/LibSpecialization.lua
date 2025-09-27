--@curseforge-project-slug: libspecialization@
local wowID = WOW_PROJECT_ID
local cataWowID = 14
local mistsWowID = 19
if wowID ~= 1 and wowID ~= cataWowID and wowID ~= mistsWowID then return end -- Retail, Cata, Mists

local LS, oldminor = LibStub:NewLibrary("LibSpecialization", 23)
if not LS then return end -- No upgrade needed

LS.callbackMapGroup = LS.callbackMapGroup or {}
LS.callbackMapGuild = LS.callbackMapGuild or {}
LS.callbackMapPlayerSpecChange = LS.callbackMapPlayerSpecChange or {}
LS.frame = LS.frame or CreateFrame("Frame")

-- Positions of roles
local positionTable = wowID == cataWowID and {
	-- Death Knight
	[398] = "MELEE", -- Blood (Tank)
	[399] = "MELEE", -- Frost (DPS)
	[400] = "MELEE", -- Unholy (DPS)
	-- Druid
	[752] = "RANGED", -- Balance (DPS Owl)
	[750] = "MELEE", -- Feral Combat (DPS Cat AND Tank Bear)
	[748] = "RANGED", -- Restoration (Heal)
	-- Hunter
	[811] = "RANGED", -- Beast Mastery
	[807] = "RANGED", -- Marksmanship
	[809] = "RANGED", -- Survival
	-- Mage
	[799] = "RANGED", -- Arcane
	[851] = "RANGED", -- Fire
	[823] = "RANGED", -- Frost
	-- Paladin
	[831] = "RANGED", -- Holy (Heal)
	[839] = "MELEE", -- Protection (Tank)
	[855] = "MELEE", -- Retribution (DPS)
	-- Priest
	[760] = "RANGED", -- Discipline (Heal)
	[813] = "RANGED", -- Holy (Heal)
	[795] = "RANGED", -- Shadow (DPS)
	-- Rogue
	[182] = "MELEE", -- Assassination
	[181] = "MELEE", -- Combat
	[183] = "MELEE", -- Subtlety
	-- Shaman
	[261] = "RANGED", -- Elemental (DPS)
	[263] = "MELEE", -- Enhancement (DPS)
	[262] = "RANGED", -- Restoration (Heal)
	-- Warlock
	[871] = "RANGED", -- Affliction
	[867] = "RANGED", -- Demonology
	[865] = "RANGED", -- Destruction
	-- Warrior
	[746] = "MELEE", -- Arms (DPS)
	[815] = "MELEE", -- Fury (DPS)
	[845] = "MELEE", -- Protection (Tank)
} or {
	-- Death Knight
	[250] = "MELEE", -- Blood (Tank)
	[251] = "MELEE", -- Frost (DPS)
	[252] = "MELEE", -- Unholy (DPS)
	-- Demon Hunter
	[577] = "MELEE", -- Havoc (DPS)
	[581] = "MELEE", -- Vengeance (Tank)
	-- Druid
	[102] = "RANGED", -- Balance (DPS Owl)
	[103] = "MELEE", -- Feral (DPS Cat)
	[104] = "MELEE", -- Guardian (Tank Bear)
	[105] = "RANGED", -- Restoration (Heal)
	-- Evoker
	[1467] = "RANGED", -- Devastation (DPS)
	[1468] = "RANGED", -- Preservation (Heal)
	[1473] = "RANGED", -- Augmentation (DPS)
	-- Hunter
	[253] = "RANGED", -- Beast Mastery
	[254] = "RANGED", -- Marksmanship
	[255] = wowID == mistsWowID and "RANGED" or "MELEE", -- Survival [Ranged on Mists, Melee on Retail]
	-- Mage
	[62] = "RANGED", -- Arcane
	[63] = "RANGED", -- Fire
	[64] = "RANGED", -- Frost
	-- Monk
	[268] = "MELEE", -- Brewmaster (Tank)
	[269] = "MELEE", -- Windwalker (DPS)
	[270] = "MELEE", -- Mistweaver (Heal)
	-- Paladin
	[65] = wowID == mistsWowID and "RANGED" or "MELEE", -- Holy (Heal) [Ranged on Mists, Melee on Retail]
	[66] = "MELEE", -- Protection (Tank)
	[70] = "MELEE", -- Retribution (DPS)
	-- Priest
	[256] = "RANGED", -- Discipline (Heal)
	[257] = "RANGED", -- Holy (Heal)
	[258] = "RANGED", -- Shadow (DPS)
	-- Rogue
	[259] = "MELEE", -- Assassination
	[260] = "MELEE", -- Outlaw [Retail] / Combat [Mists]
	[261] = "MELEE", -- Subtlety
	-- Shaman
	[262] = "RANGED", -- Elemental (DPS)
	[263] = "MELEE", -- Enhancement (DPS)
	[264] = "RANGED", -- Restoration (Heal)
	-- Warlock
	[265] = "RANGED", -- Affliction
	[266] = "RANGED", -- Demonology
	[267] = "RANGED", -- Destruction
	-- Warrior
	[71] = "MELEE", -- Arms (DPS)
	[72] = "MELEE", -- Fury (DPS)
	[73] = "MELEE", -- Protection (Tank)
}
-- Player roles
local roleTable = wowID == cataWowID and {
	-- Death Knight
	[398] = "TANK", -- Blood (Tank)
	[399] = "DAMAGER", -- Frost (DPS)
	[400] = "DAMAGER", -- Unholy (DPS)
	-- Druid
	[752] = "DAMAGER", -- Balance (DPS Owl)
	[750] = "TANK", -- Feral Combat (DPS Cat AND Tank Bear) Oh noooooooooooooooooooooooooooooo, talent checks incoming
	[748] = "HEALER", -- Restoration (Heal)
	-- Hunter
	[811] = "DAMAGER", -- Beast Mastery
	[807] = "DAMAGER", -- Marksmanship
	[809] = "DAMAGER", -- Survival
	-- Mage
	[799] = "DAMAGER", -- Arcane
	[851] = "DAMAGER", -- Fire
	[823] = "DAMAGER", -- Frost
	-- Paladin
	[831] = "HEALER", -- Holy (Heal)
	[839] = "TANK", -- Protection (Tank)
	[855] = "DAMAGER", -- Retribution (DPS)
	-- Priest
	[760] = "HEALER", -- Discipline (Heal)
	[813] = "HEALER", -- Holy (Heal)
	[795] = "DAMAGER", -- Shadow (DPS)
	-- Rogue
	[182] = "DAMAGER", -- Assassination
	[181] = "DAMAGER", -- Combat
	[183] = "DAMAGER", -- Subtlety
	-- Shaman
	[261] = "DAMAGER", -- Elemental (DPS)
	[263] = "DAMAGER", -- Enhancement (DPS)
	[262] = "HEALER", -- Restoration (Heal)
	-- Warlock
	[871] = "DAMAGER", -- Affliction
	[867] = "DAMAGER", -- Demonology
	[865] = "DAMAGER", -- Destruction
	-- Warrior
	[746] = "DAMAGER", -- Arms (DPS)
	[815] = "DAMAGER", -- Fury (DPS)
	[845] = "TANK", -- Protection (Tank)
} or {
	-- Death Knight
	[250] = "TANK", -- Blood (Tank)
	[251] = "DAMAGER", -- Frost (DPS)
	[252] = "DAMAGER", -- Unholy (DPS)
	-- Demon Hunter
	[577] = "DAMAGER", -- Havoc (DPS)
	[581] = "TANK", -- Vengeance (Tank)
	-- Druid
	[102] = "DAMAGER", -- Balance (DPS Owl)
	[103] = "DAMAGER", -- Feral (DPS Cat)
	[104] = "TANK", -- Guardian (Tank Bear)
	[105] = "HEALER", -- Restoration (Heal)
	-- Evoker
	[1467] = "DAMAGER", -- Devastation (DPS)
	[1468] = "HEALER", -- Preservation (Heal)
	[1473] = "DAMAGER", -- Augmentation (DPS)
	-- Hunter
	[253] = "DAMAGER", -- Beast Mastery
	[254] = "DAMAGER", -- Marksmanship
	[255] = "DAMAGER", -- Survival
	-- Mage
	[62] = "DAMAGER", -- Arcane
	[63] = "DAMAGER", -- Fire
	[64] = "DAMAGER", -- Frost
	-- Monk
	[268] = "TANK", -- Brewmaster (Tank)
	[269] = "DAMAGER", -- Windwalker (DPS)
	[270] = "HEALER", -- Mistweaver (Heal)
	-- Paladin
	[65] = "HEALER", -- Holy (Heal)
	[66] = "TANK", -- Protection (Tank)
	[70] = "DAMAGER", -- Retribution (DPS)
	-- Priest
	[256] = "HEALER", -- Discipline (Heal)
	[257] = "HEALER", -- Holy (Heal)
	[258] = "DAMAGER", -- Shadow (DPS)
	-- Rogue
	[259] = "DAMAGER", -- Assassination
	[260] = "DAMAGER", -- Outlaw [Retail] / Combat [Mists]
	[261] = "DAMAGER", -- Subtlety
	-- Shaman
	[262] = "DAMAGER", -- Elemental (DPS)
	[263] = "DAMAGER", -- Enhancement (DPS)
	[264] = "HEALER", -- Restoration (Heal)
	-- Warlock
	[265] = "DAMAGER", -- Affliction
	[266] = "DAMAGER", -- Demonology
	[267] = "DAMAGER", -- Destruction
	-- Warrior
	[71] = "DAMAGER", -- Arms (DPS)
	[72] = "DAMAGER", -- Fury (DPS)
	[73] = "TANK", -- Protection (Tank)
}
-- Starter specs
local starterSpecs = {
	[1444] = true, -- Shaman
	[1446] = true, -- Warrior
	[1447] = true, -- Druid
	[1448] = true, -- Hunter
	[1449] = true, -- Mage
	[1450] = true, -- Monk
	[1451] = true, -- Paladin
	[1452] = true, -- Priest
	[1453] = true, -- Rogue
	[1454] = true, -- Warlock
	[1455] = true, -- Death Knight
	[1456] = true, -- Demon Hunter
	[1465] = true, -- Evoker
}

local callbackMapGroup = LS.callbackMapGroup
local callbackMapGuild = LS.callbackMapGuild

local type, error, format = type, error, string.format
local geterrorhandler, GetTime = geterrorhandler, GetTime

do
	local result = C_ChatInfo.RegisterAddonMessagePrefix("LibSpec")
	-- 0=success, 1=duplicate, 2=invalid, 3=toomany
	if type(result) == "number" and result > 1 then
		error("LibSpecialization: Failed to register the addon prefix.")
	end
end

-- Handle groups (comms are automatic)
function LS.RegisterGroup(addon, func)
	if type(addon) ~= "table" or addon == LS then
		error("LibSpecialization: The function lib.RegisterGroup expects your own addon object as the first arg.")
	end

	local t = type(func)
	if t == "function" then
		callbackMapGroup[addon] = func
	else
		error("LibSpecialization: The function lib.RegisterGroup expects your own function as the second arg.")
	end
end

function LS.UnregisterGroup(addon)
	if type(addon) ~= "table" or addon == LS then
		error("LibSpecialization: The function lib.UnregisterGroup expects your own addon object.")
	end
	callbackMapGroup[addon] = nil
end

-- Handle guilds (comms are on manual request)
function LS.RegisterGuild(addon, func)
	if type(addon) ~= "table" or addon == LS then
		error("LibSpecialization: The function lib.RegisterGuild expects your own addon object as the first arg.")
	end

	local t = type(func)
	if t == "function" then
		callbackMapGuild[addon] = func
	else
		error("LibSpecialization: The function lib.RegisterGuild expects your own function as the second arg.")
	end
end

function LS.UnregisterGuild(addon)
	if type(addon) ~= "table" or addon == LS then
		error("LibSpecialization: The function lib.UnregisterGuild expects your own addon object.")
	end
	callbackMapGuild[addon] = nil
end

function LS.RegisterPlayerSpecChange(addon, func)
	if type(addon) ~= "table" or addon == LS then
		error("LibSpecialization: The function lib.RegisterPlayerSpecChange expects your own addon object as the first arg.")
	end

	local t = type(func)
	if t == "function" then
		LS.callbackMapPlayerSpecChange[addon] = func
	else
		error("LibSpecialization: The function lib.RegisterPlayerSpecChange expects your own function as the second arg.")
	end
end

function LS.UnregisterPlayerSpecChange(addon)
	if type(addon) ~= "table" or addon == LS then
		error("LibSpecialization: The function lib.UnregisterPlayerSpecChange expects your own addon object.")
	end
	LS.callbackMapPlayerSpecChange[addon] = nil
end

local GetInfo
if wowID == cataWowID then
	function GetInfo()
		local specIndex = GetPrimaryTalentTree()
		if specIndex then
			local specId = GetTalentTabInfo(specIndex)
			if type(specId) == "number" and specId > 0 then
				local position = positionTable[specId]
				local role = roleTable[specId]
				if position and role then
					if specId == 750 and not IsPlayerSpell(57880) then -- Cataclysm Feral Druids, if you don't have 2 points in 'Natural Reaction' we assume you're a cat
						return specId, "DAMAGER", position
					end
					return specId, role, position
				else
					geterrorhandler()(format("LibSpecialization: Unknown specId %q", specId))
				end
			end
		end
	end
elseif wowID == mistsWowID then
	local GetSpecialization, GetSpecializationInfo = C_SpecializationInfo.GetSpecialization, C_SpecializationInfo.GetSpecializationInfo
	local GetTalentInfo, GetGlyphSocketInfo = C_SpecializationInfo.GetTalentInfo, GetGlyphSocketInfo
	local SerializeJSON = C_EncodingUtil.SerializeJSON
	function GetInfo()
		local spec = GetSpecialization()
		if type(spec) == "number" and spec > 0 then
			local specId = GetSpecializationInfo(spec)

			if type(specId) == "number" and specId > 0 then
				local position = positionTable[specId]
				local role = roleTable[specId]
				if position and role then
					local storageTable = {
						talents = {0, 0, 0, 0, 0, 0}, -- 6 tiers/rows
						glyphs = {0, 0, 0, 0, 0, 0}, -- 6 glyphs
					}

					-- Fill in the talents
					for tier = 1, 6 do -- 6 rows
						for column = 1, 3 do -- 3 columns
							local talentInfo = GetTalentInfo({tier=tier, column=column})
							if talentInfo.known and type(talentInfo.talentID) == "number" then
								storageTable.talents[tier] = talentInfo.talentID
								break
							end
						end
					end

					-- Fill in the glyphs
					for glyphSlot = 1, 6 do -- There are 6 glyphs in total, 3 major and 3 minor
						local _, _, _, _, _, glyphID = GetGlyphSocketInfo(glyphSlot)
						if type(glyphID) == "number" then
							storageTable.glyphs[glyphSlot] = glyphID
						end
					end

					local talentsAndGlyphsJSON = SerializeJSON(storageTable)
					return specId, role, position, talentsAndGlyphsJSON
				elseif not starterSpecs[specId] then
					geterrorhandler()(format("LibSpecialization: Unknown specId %q", specId))
				end
			end
		end
	end
else
	local C_Traits_GenerateImportString = C_Traits.GenerateImportString
	local C_ClassTalents_GetActiveConfigID = C_ClassTalents.GetActiveConfigID
	local GetSpecialization, GetSpecializationInfo = C_SpecializationInfo.GetSpecialization, C_SpecializationInfo.GetSpecializationInfo
	function GetInfo()
		local spec = GetSpecialization()
		if type(spec) == "number" and spec > 0 then
			local specId = GetSpecializationInfo(spec)

			if type(specId) == "number" and specId > 0 then
				local position = positionTable[specId]
				local role = roleTable[specId]
				if position and role then
					local activeConfigID = C_ClassTalents_GetActiveConfigID()
					if activeConfigID then
						local talentString = C_Traits_GenerateImportString(activeConfigID)
						return specId, role, position, talentString
					end
					return specId, role, position
				elseif not starterSpecs[specId] then
					geterrorhandler()(format("LibSpecialization: Unknown specId %q", specId))
				end
			end
		end
	end
end
LS.MySpecialization = GetInfo

local throttleTimer = 3 -- Seconds
local pName = UnitNameUnmodified("player")
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local IsInGroup = IsInGroup
local CTimerNewTimer = C_Timer.NewTimer
local next, securecallfunction = next, securecallfunction
do
	local currentSpecId, currentTalentString, currentRole = 0, nil, nil

	local PrepareForInstance
	do
		local timerInstance = nil
		local function SendToInstance()
			timerInstance = nil
			if IsInGroup(2) then
				if currentRole then -- Cataclysm Feral Druids
					local result = SendAddonMessage("LibSpec", format("%d,,%s", currentSpecId, currentRole), "INSTANCE_CHAT")
					if result == 9 then
						timerInstance = CTimerNewTimer(throttleTimer, SendToInstance)
					end
				else
					local result = SendAddonMessage("LibSpec", format("%d,%s", currentSpecId, currentTalentString or ""), "INSTANCE_CHAT")
					if result == 9 then
						timerInstance = CTimerNewTimer(throttleTimer, SendToInstance)
					end
				end
			end
		end
		function PrepareForInstance()
			local specId, role, _, talentString = GetInfo()
			if specId then
				currentSpecId = specId
				currentTalentString = talentString
				currentRole = specId == 750 and role or nil -- Cataclysm Feral Druids
				if not timerInstance then
					timerInstance = CTimerNewTimer(throttleTimer, SendToInstance)
				end
			end
		end
	end

	local PrepareForGroup
	do
		local timerGroup = nil
		local function SendToGroup()
			timerGroup = nil
			if IsInGroup(1) then
				if currentRole then -- Cataclysm Feral Druids
					local result = SendAddonMessage("LibSpec", format("%d,,%s", currentSpecId, currentRole), "RAID") -- RAID auto downgrades to PARTY as needed
					if result == 9 then
						timerGroup = CTimerNewTimer(throttleTimer, SendToGroup)
					end
				else
					local result = SendAddonMessage("LibSpec", format("%d,%s", currentSpecId, currentTalentString or ""), "RAID") -- RAID auto downgrades to PARTY as needed
					if result == 9 then
						timerGroup = CTimerNewTimer(throttleTimer, SendToGroup)
					end
				end
			end
		end
		function PrepareForGroup()
			local specId, role, _, talentString = GetInfo()
			if specId then
				currentSpecId = specId
				currentTalentString = talentString
				currentRole = specId == 750 and role or nil -- Cataclysm Feral Druids
				if not timerGroup then
					timerGroup = CTimerNewTimer(throttleTimer, SendToGroup)
				end
			end
		end
	end

	local PrepareForGuild
	do
		local guildTimer = nil
		local prev = 0
		local function SendToGuild()
			if guildTimer then
				guildTimer:Cancel()
				guildTimer = nil
			end
			if IsInGuild() then
				if currentRole then -- Cataclysm Feral Druids
					local result = SendAddonMessage("LibSpec", format("%d,,%s", currentSpecId, currentRole), "GUILD")
					if result == 9 then
						guildTimer = CTimerNewTimer(throttleTimer, SendToGuild)
					end
				else
					local result = SendAddonMessage("LibSpec", format("%d,%s", currentSpecId, currentTalentString or ""), "GUILD")
					if result == 9 then
						guildTimer = CTimerNewTimer(throttleTimer, SendToGuild)
					end
				end
			end
		end
		function PrepareForGuild()
			local specId, role, _, talentString = GetInfo()
			if specId then
				currentSpecId = specId
				currentTalentString = talentString
				currentRole = specId == 750 and role or nil -- Cataclysm Feral Druids
				if not guildTimer then
					local t = GetTime()
					if t-prev > throttleTimer then
						prev = t
						SendToGuild()
					else
						guildTimer = CTimerNewTimer(throttleTimer-(t-prev), SendToGuild)
					end
				end
			end
		end
	end

	local approved = {
		RAID = callbackMapGroup,
		PARTY = callbackMapGroup,
		INSTANCE_CHAT = callbackMapGroup,
		GUILD = callbackMapGuild,
	}
	local tonumber, strmatch = tonumber, string.match
	local Ambiguate = Ambiguate
	local C_ClassTalents_GetActiveConfigID = C_ClassTalents and C_ClassTalents.GetActiveConfigID
	LS.frame:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
		if event == "CHAT_MSG_ADDON" then
			if prefix == "LibSpec" and approved[channel] then -- Only approved channels
				if msg == "R" then
					if channel == "GUILD" then
						PrepareForGuild()
					elseif channel == "INSTANCE_CHAT" then
						PrepareForInstance()
					else -- RAID/PARTY
						PrepareForGroup()
					end
					return
				end

				local spec, talentString = strmatch(msg, "(%d+),(.+)")
				local specId = tonumber(spec)
				local cataDruidRole
				if specId == 750 then -- Cataclysm Feral Druids
					talentString = nil
					cataDruidRole = strmatch(msg, "%d+,,(.+)")
				end

				local role, position = roleTable[specId], positionTable[specId]
				if role and position then
					if specId == 750 then -- Cataclysm Feral Druids
						if cataDruidRole == "TANK" or cataDruidRole == "DAMAGER" then
							role = cataDruidRole
						else
							return
						end
					end
					local playerName = Ambiguate(sender, "none")
					local talents = talentString and #talentString > 2 and talentString or nil
					for _,func in next, approved[channel] do
						securecallfunction(func, specId, role, position, playerName, talents)
					end
				end
			end
		elseif event == "GROUP_FORMED" then -- Join new group
			LS.RequestGroupSpecialization()
		elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" or ((event == "ACTIVE_COMBAT_CONFIG_CHANGED" or event == "TRAIT_CONFIG_UPDATED") and prefix == C_ClassTalents_GetActiveConfigID()) then
			for _,func in next, LS.callbackMapPlayerSpecChange do
				securecallfunction(func) -- Notify when the player has changed their spec
			end
			if IsInGroup() then
				if IsInGroup(2) then -- Instance group
					PrepareForInstance()
				end
				if IsInGroup(1) then -- Normal group
					PrepareForGroup()
				end
			else
				local specId, role, position, talentString = GetInfo()
				if specId then
					for _,func in next, callbackMapGroup do
						securecallfunction(func, specId, role, position, pName, talentString) -- This allows us to show our own spec info when not grouped
					end
				end
			end
		elseif event == "PLAYER_LOGIN" then
			LS.RequestGroupSpecialization()
		end
	end)
	LS.frame:RegisterEvent("CHAT_MSG_ADDON")
	LS.frame:RegisterEvent("GROUP_FORMED")
	if wowID == cataWowID then
		LS.frame:RegisterEvent("PLAYER_TALENT_UPDATE")
	elseif wowID == mistsWowID then
		LS.frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
	else
		LS.frame:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED")
		LS.frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
	end
	LS.frame:RegisterEvent("PLAYER_LOGIN")
end

do
	local prev = 0
	local timer = nil
	function LS.RequestGroupSpecialization() -- Group comms are automatic, you should never need to use this
		local specId, role, position, talentString = GetInfo()
		if specId then
			for _,func in next, callbackMapGroup do
				securecallfunction(func, specId, role, position, pName, talentString) -- This allows us to show our own spec info when not grouped
			end
		end

		if IsInGroup() then
			local t = GetTime()
			if t-prev > throttleTimer then
				if timer then
					timer:Cancel()
					timer = nil
				end
				prev = t
				if IsInGroup(2) then
					SendAddonMessage("LibSpec", "R", "INSTANCE_CHAT")
				end
				if IsInGroup(1) then
					SendAddonMessage("LibSpec", "R", "RAID")
				end
			elseif not timer then
				timer = CTimerNewTimer((throttleTimer+0.1)-(t-prev), LS.RequestGroupSpecialization)
			end
		end
	end
end

do
	local prev = 0
	local timer = nil
	function LS.RequestGuildSpecialization() -- Guild comms are manual, you will need to manually request data each time
		local specId, role, position, talentString = GetInfo()
		if specId then
			for _,func in next, callbackMapGuild do
				securecallfunction(func, specId, role, position, pName, talentString) -- This allows us to show our own spec info when not grouped
			end
		end

		if IsInGuild() then
			local t = GetTime()
			if t-prev > throttleTimer then
				if timer then
					timer:Cancel()
					timer = nil
				end
				prev = t
				SendAddonMessage("LibSpec", "R", "GUILD")
			elseif not timer then
				timer = CTimerNewTimer((throttleTimer+0.1)-(t-prev), LS.RequestGuildSpecialization)
			end
		end
	end
end

if IsLoggedIn() and not oldminor then -- Player is logged in and library isn't upgrading
	LS.RequestGroupSpecialization()
end