local wowID = WOW_PROJECT_ID
local cataWowID = 14
local isWotLK = (wowID == WOW_PROJECT_WRATH_CLASSIC) -- 新增WLK检测
if wowID ~= 1 and wowID ~= cataWowID and not isWotLK then return end -- 允许WLK加载

local LS, oldminor = LibStub:NewLibrary("LibSpecialization", 10)
if not LS then return end -- No upgrade needed

LS.callbackMap = LS.callbackMap or {}
LS.frame = LS.frame or CreateFrame("Frame")

-- Positions of roles
local positionTable = wowID == cataWowID and {...}
or isWotLK and { -- 新增WLK映射
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
	[255] = "MELEE", -- Survival
	-- Mage
	[62] = "RANGED", -- Arcane
	[63] = "RANGED", -- Fire
	[64] = "RANGED", -- Frost
	-- Monk
	[268] = "MELEE", -- Brewmaster (Tank)
	[269] = "MELEE", -- Windwalker (DPS)
	[270] = "MELEE", -- Mistweaver (Heal)
	-- Paladin
	[65] = "MELEE", -- Holy (Heal)
	[66] = "MELEE", -- Protection (Tank)
	[70] = "MELEE", -- Retribution (DPS)
	-- Priest
	[256] = "RANGED", -- Discipline (Heal)
	[257] = "RANGED", -- Holy (Heal)
	[258] = "RANGED", -- Shadow (DPS)
	-- Rogue
	[259] = "MELEE", -- Assassination
	[260] = "MELEE", -- Outlaw
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
	[260] = "DAMAGER", -- Outlaw
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

local callbackMap = LS.callbackMap
local frame = LS.frame

local next, type, error, tonumber, format, strsplit = next, type, error, tonumber, string.format, string.split
local Ambiguate, GetTime, IsInGroup = Ambiguate, GetTime, IsInGroup
local GetSpecialization, GetSpecializationInfo = GetSpecialization, GetSpecializationInfo
local C_ClassTalents_GetActiveConfigID = C_ClassTalents and C_ClassTalents.GetActiveConfigID
local C_Traits_GenerateImportString = C_Traits.GenerateImportString
local SendAddonMessage, CTimerAfter = C_ChatInfo.SendAddonMessage, C_Timer.After
local pName = UnitName("player")

do
	local result = C_ChatInfo.RegisterAddonMessagePrefix("LibSpec")
	if type(result) == "number" and result > 2 then
		error("LibSpecialization: Failed to register the addon prefix.")
	end
end

do
	local currentSpecId, currentTalentString, currentRole = 0, nil, nil

	local PrepareForInstance
	do
		local timerInstance = false
		local function SendToInstance()
			timerInstance = false
			if IsInGroup(2) then
				if currentRole then -- Cataclysm Feral Druids
					local result = SendAddonMessage("LibSpec", format("%d,,%s", currentSpecId, currentRole), "INSTANCE_CHAT")
					if result == 9 then
						timerInstance = true
						CTimerAfter(3, SendToInstance)
					end
				else
					local result = SendAddonMessage("LibSpec", format("%d,%s", currentSpecId, currentTalentString or ""), "INSTANCE_CHAT")
					if result == 9 then
						timerInstance = true
						CTimerAfter(3, SendToInstance)
					end
				end
			end
		end
		function PrepareForInstance()
			local specId, role, _, talentString = LS:MySpecialization()
			if specId then
				currentSpecId = specId
				currentTalentString = talentString
				currentRole = specId == 750 and role or nil -- Cataclysm Feral Druids
				if not timerInstance then
					timerInstance = true
					CTimerAfter(3, SendToInstance)
				end
			end
		end
	end

	local PrepareForGroup
	do
		local timerGroup = false
		local function SendToGroup()
			timerGroup = false
			if IsInGroup(1) then
				if currentRole then -- Cataclysm Feral Druids
					local result = SendAddonMessage("LibSpec", format("%d,,%s", currentSpecId, currentRole), "RAID") -- RAID auto downgrades to PARTY as needed
					if result == 9 then
						timerGroup = true
						CTimerAfter(3, SendToGroup)
					end
				else
					local result = SendAddonMessage("LibSpec", format("%d,%s", currentSpecId, currentTalentString or ""), "RAID") -- RAID auto downgrades to PARTY as needed
					if result == 9 then
						timerGroup = true
						CTimerAfter(3, SendToGroup)
					end
				end
			end
		end
		function PrepareForGroup()
			local specId, role, _, talentString = LS:MySpecialization()
			if specId then
				currentSpecId = specId
				currentTalentString = talentString
				currentRole = specId == 750 and role or nil -- Cataclysm Feral Druids
				if not timerGroup then
					timerGroup = true
					CTimerAfter(3, SendToGroup)
				end
			end
		end
	end

	local approved = {
		["RAID"] = true,
		["PARTY"] = true,
		["INSTANCE_CHAT"] = true,
	}
	frame:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
		if event == "CHAT_MSG_ADDON" then
			if prefix == "LibSpec" and approved[channel] then -- Only approved channels
				if msg == "R" then
					if channel == "INSTANCE_CHAT" then
						PrepareForInstance()
					else -- RAID/PARTY
						PrepareForGroup()
					end
					return
				end

				local spec, talentString, cataDruidRole = strsplit(",", msg)
				local specId = tonumber(spec)
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
					for _,func in next, callbackMap do
						func(specId, role, position, playerName, talents)
					end
				end
			end
		elseif event == "GROUP_FORMED" then -- Join new group
			LS:RequestSpecialization()
		elseif event == "PLAYER_TALENT_UPDATE" or ((event == "ACTIVE_COMBAT_CONFIG_CHANGED" or event == "TRAIT_CONFIG_UPDATED") and prefix == C_ClassTalents_GetActiveConfigID()) then
			if IsInGroup() then
				if IsInGroup(2) then -- Instance group
					PrepareForInstance()
				end
				if IsInGroup(1) then -- Normal group
					PrepareForGroup()
				end
			else
				local specId, role, position, talentString = LS:MySpecialization()
				if specId then
					for _,func in next, callbackMap do
						func(specId, role, position, pName, talentString) -- This allows us to show our own spec info when not grouped
					end
				end
			end
		elseif event == "PLAYER_LOGIN" then
			LS:RequestSpecialization()
		end
	end)
-- 修改后的事件注册部分
frame:UnregisterAllEvents()
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("GROUP_FORMED")

-- 版本特异性事件
if wowID == cataWowID or isWotLK then
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
else
    frame:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED")
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
end

frame:RegisterEvent("PLAYER_LOGIN") -- 所有版本都需要
end
-- Allow requesting only your specialization
function LS:MySpecialization()
    if isWotLK then
        -- WLK天赋树检测逻辑
        local maxPoints, currentSpecId = 0, 1
        for tab = 1, 3 do -- 遍历3个天赋树
            local points = 0
            for index = 1, GetNumTalents(tab) do
                local _, _, _, _, rank = GetTalentInfo(tab, index)
                points = points + rank
            end
            if points > maxPoints then
                maxPoints = points
                currentSpecId = tab -- 天赋树索引作为伪专精ID
            end
        end
        
        -- 映射到Cata专精ID（示例：战士）
        local class = UnitClassBase("player")
        local specMap = {
            WARRIOR = { [1] = 746, [2] = 815, [3] = 845 }, -- Arms, Fury, Prot
            MAGE    = { [1] = 799, [2] = 851, [3] = 823 }, -- Arcane, Fire, Frost
            -- 其他职业映射...
        }
        local realSpecId = specMap[class] and specMap[class][currentSpecId] or currentSpecId
        
        return realSpecId, roleTable[realSpecId], positionTable[realSpecId]
    elseif wowID == cataWowID then
		local specIndex = GetPrimaryTalentTree()
		if specIndex then
			local specId = GetTalentTabInfo(specIndex)
			if specId then
				local position = positionTable[specId]
				local role = roleTable[specId]
				if position and role then
					if specId == 750 and not IsPlayerSpell(57880) then -- Cataclysm Feral Druids, if you don't have 2 points in 'Natural Reaction' we assume you're a cat
						return specId, "DAMAGER", position
					end
					return specId, role, position
				else
					error(format("LibSpecialization: Unknown specId %q", specId))
				end
			end
		end
	else
		local spec = GetSpecialization()
		if type(spec) == "number" and spec > 0 then
			local specId = GetSpecializationInfo(spec)

			if specId then
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
					error(format("LibSpecialization: Unknown specId %q", specId))
				end
			end
		end
	end
end

do
	local prev = 0
	local timer = false
	function LS:RequestSpecialization()
		local specId, role, position, talentString = LS:MySpecialization()
		if specId then
			for _,func in next, callbackMap do
				func(specId, role, position, pName, talentString) -- This allows us to show our own spec info when not grouped
			end
		end

		if IsInGroup() then
			local t = GetTime()
			if t-prev > 3 then
				timer = false
				prev = t
				if IsInGroup(2) then
					SendAddonMessage("LibSpec", "R", "INSTANCE_CHAT")
				end
				if IsInGroup(1) then
					SendAddonMessage("LibSpec", "R", "RAID")
				end
			elseif not timer then
				timer = true
				CTimerAfter(3.1-(t-prev), LS.RequestSpecialization)
			end
		end
	end
end

if IsLoggedIn() and not oldminor then -- Player is logged in and library isn't upgrading
	LS:RequestSpecialization()
end

function LS:Register(addon, func)
	if not addon or addon == LS then
		error("LibSpecialization: You must pass your own addon name or object to :Register.")
	end

	local t = type(func)
	if t == "string" then
		callbackMap[addon] = function(...) addon[func](addon, ...) end
	elseif t == "function" then
		callbackMap[addon] = func
	else
		error("LibSpecialization: Incorrect function type for :Register.")
	end
end

function LS:Unregister(addon)
	if not addon or addon == LS then
		error("LibSpecialization: You must pass your own addon name or object to :Unregister.")
	end
	callbackMap[addon] = nil
end
