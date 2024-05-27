if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

---@class WeakAuras
local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local encounter_list = ""
local zoneId_list = ""
function Private.InitializeEncounterAndZoneLists()
	local currTier = EJ_GetCurrentTier()
  if encounter_list ~= "" then
    return
  end
	for tier = EJ_GetNumTiers(), EJ_GetNumTiers() do
		EJ_SelectTier(tier)
		local tierName = EJ_GetTierInfo(tier)
		for _, inRaid in ipairs({false, true}) do
			local instance_index = 1
			local instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)
			local title = ("%s %s"):format(tierName , inRaid and L["Raids"] or L["Dungeons"])
			local zones = ""
			while instance_id do
				EJ_SelectInstance(instance_id)
				local instance_name, _, _, _, _, _, dungeonAreaMapID = EJ_GetInstanceInfo(instance_id)
				local ej_index = 1
				local boss, _, _, _, _, _, encounter_id = EJ_GetEncounterInfoByIndex(ej_index, instance_id)

				-- zone ids
				if dungeonAreaMapID and dungeonAreaMapID ~= 0 then
					local mapGroupId = C_Map.GetMapGroupID(dungeonAreaMapID)
					if mapGroupId then -- If there's a group id, only list that one
						zones = ("%s%s: g%d\n"):format(zones, instance_name, mapGroupId)
					else
						zones = ("%s%s: %d\n"):format(zones, instance_name, dungeonAreaMapID)
					end
				end

				-- Encounter ids
				if inRaid then
					while boss do
						if encounter_id then
							if instance_name then
								encounter_list = ("%s|cffffd200%s|r\n"):format(encounter_list, instance_name)
								instance_name = nil -- Only add it once per section
							end
							encounter_list = ("%s%s: %d\n"):format(encounter_list, boss, encounter_id)
						end
						ej_index = ej_index + 1
						boss, _, _, _, _, _, encounter_id = EJ_GetEncounterInfoByIndex(ej_index, instance_id)
					end
					encounter_list = encounter_list .. "\n"
				end
				instance_index = instance_index + 1
				instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)
			end
			if zones ~= "" then
				zoneId_list = ("%s|cffffd200%s|r\n"):format(zoneId_list, title)
				zoneId_list = zoneId_list .. zones.. "\n"
			end
		end
	end
	EJ_SelectTier(currTier) -- restore previously selected tier

  encounter_list = encounter_list:sub(1, -3) .. "\n\n" .. L["Supports multiple entries, separated by commas\n"]
end

function Private.get_encounters_list()
  return encounter_list
end

function Private.get_zoneId_list()
  return zoneId_list
end

local backgroundAlias = {
	-- DK
	[250] = "talents-background-deathknight-blood",
	[251] = "talents-background-deathknight-frost",
	[252] = "talents-background-deathknight-unholy",

	-- DH
	[577] = "talents-background-demonhunter-havoc",
	[581] = "talents-background-demonhunter-vengeance",

	-- Druid
	[102] = "talents-background-druid-balance",
	[103] = "talents-background-druid-feral",
	[104] = "talents-background-druid-guardian",
	[105] = "talents-background-druid-restoration",

	-- Evoker
	[1467] = "talents-background-evoker-devastation",
	[1468] = "talents-background-evoker-preservation",

	-- Hunter
	[253] = "talents-background-hunter-beastmastery",
	[254] = "talents-background-hunter-marksmanship",
	[255] = "talents-background-hunter-survival",

	-- Mage
	[62] = "talents-background-mage-arcane",
	[63] = "talents-background-mage-fire",
	[64] = "talents-background-mage-frost",

	-- Monk
	[268] = "talents-background-monk-brewmaster",
	[269] = "talents-background-monk-windwalker",
	[270] = "talents-background-monk-mistweaver",

	-- Paladin
	[65] = "talents-background-paladin-holy",
	[66] = "talents-background-paladin-protection",
	[70] = "talents-background-paladin-retribution",

	-- Priest
	[256] = "talents-background-priest-discipline",
	[257] = "talents-background-priest-holy",
	[258] = "talents-background-priest-shadow",

	-- Rogue
	[259] = "talents-background-rogue-assassination",
	[260] = "talents-background-rogue-outlaw",
	[261] =  "talents-background-rogue-subtlety",

	-- Shaman
	[262] = "talents-background-shaman-elemental",
	[263] = "talents-background-shaman-enhancement",
	[264] = "talents-background-shaman-restoration",

	-- Warlock
	[265] = "talents-background-warlock-affliction",
	[266] = "talents-background-warlock-demonology",
	[267] = "talents-background-warlock-destruction",

	-- Warrior
	[71] = "talents-background-warrior-arms",
	[72] = "talents-background-warrior-fury",
	[73] = "talents-background-warrior-protection",
}

local classIDToOffsets = {
	[1] = { extraOffsetX = WeakAuras.IsTWW() and 60 or 30, extraOffsetY = 31, }, -- Warrior
	[2] = { extraOffsetX = -60, extraOffsetY = -29, }, -- Paladin
	[3] = { extraOffsetX = 0, extraOffsetY = -29, }, -- Hunter
	[4] = { extraOffsetX = 30, extraOffsetY = -29, }, -- Rogue
	[5] = { extraOffsetX = -30, extraOffsetY = -29, }, -- Priest
	[6] = { extraOffsetX = 0, extraOffsetY = 1, }, -- DK
	[7] = { extraOffsetX = 0, extraOffsetY = 1, }, -- Shaman
	[8] = { extraOffsetX = 30, extraOffsetY = -29, }, -- Mage
	[9] = { extraOffsetX = 0, extraOffsetY = 1, }, -- Warlock
	[10] = { extraOffsetX = 0, extraOffsetY = -29, }, -- Monk
	[11] = { extraOffsetX = 30, extraOffsetY = -29, }, -- Druid
	[12] = { extraOffsetX = 30, extraOffsetY = -29, }, -- Demon Hunter
	[13] = { extraOffsetX = 30, extraOffsetY = -29, }, -- Evoker
}
local initialBasePanOffsetX = 4
local initialBasePanOffsetY = -30

function Private.GetTalentInfo(specId)
  local talents = {}
  local talentInfo = Private.talentInfo[specId]
  if talentInfo then
    for talentId, talentData in pairs(talentInfo) do
      local spellName, _, icon = Private.ExecEnv.GetSpellInfo(talentData[1])
      if spellName then
        talents[talentId] = ("|T"..icon..":16|t " .. spellName)
      end
    end
  end
  return talents
end

Private.talentInfo = {}

local function GetClassId(classFile)
	for classID = 1, GetNumClasses() do
		local _, thisClassFile = GetClassInfo(classID)
		if classFile == thisClassFile then
			return classID
		end
	end
end



function Private.GetTalentData(specId)
	if Private.talentInfo[specId] then
		return unpack(Private.talentInfo[specId])
	end
	local configId = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
	local specData = {}
	local heroData = {}
	C_ClassTalents.InitializeViewLoadout(specId, 70)
	C_ClassTalents.ViewLoadout({})
	local configInfo = C_Traits.GetConfigInfo(configId)
	local subTreeIDs = WeakAuras.IsTWW() and C_ClassTalents.GetHeroTalentSpecsForClassSpec(configId, specId) or {}
	if configInfo == nil then return end
	for _, treeId in ipairs(configInfo.treeIDs) do
		local nodes = C_Traits.GetTreeNodes(treeId)
		for _, nodeId in ipairs(nodes) do
			local node = C_Traits.GetNodeInfo(configId, nodeId)
			if node and node.ID ~= 0 then
				for idx, talentId in ipairs(node.entryIDs) do
					local entryInfo = C_Traits.GetEntryInfo(configId, talentId)
					local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
					if definitionInfo.spellID then
						local spellName = Private.ExecEnv.GetSpellName(definitionInfo.spellID)
						if spellName then
							local talentData = {
								talentId,
								definitionInfo.spellID,
								{ node.posX, node.posY, idx, #node.entryIDs },
								{}
							}
							for _, edge in pairs(node.visibleEdges) do
								local targetNodeId = edge.targetNode
								local targetNode = C_Traits.GetNodeInfo(configId, targetNodeId)
								local targetNodeTalentId1 = targetNode.entryIDs[1]
								if targetNodeTalentId1 then
									-- add as target 1st talentId
									-- because we don't save nodes
									tinsert(talentData[4], targetNodeTalentId1)
								end
							end
							if node.subTreeID then
								local subTreeInfo = C_Traits.GetSubTreeInfo(configId, node.subTreeID)
								talentData[3][1] = node.posX - subTreeInfo.posX
								talentData[3][2] = node.posY - subTreeInfo.posY
								talentData[3][5] = tIndexOf(subTreeIDs, node.subTreeID)
								tinsert(heroData, talentData)
							else
								tinsert(specData, talentData)
							end
						end
					end
				end
			end
		end
	end

	local classFile = select(6, GetSpecializationInfoByID(specId))
	local classID = GetClassId(classFile)
	local classOffsets = classIDToOffsets[classID]
	local basePanOffsetX = initialBasePanOffsetX - (classOffsets and classOffsets.extraOffsetX or 0)
	local basePanOffsetY = initialBasePanOffsetY - (classOffsets and classOffsets.extraOffsetY or 0)
	specData[999] = backgroundAlias[specId]
	specData[1000] = { offsetX = basePanOffsetX, offsetY = basePanOffsetY }
	heroData[999] = backgroundAlias[specId]
	heroData[1001] = true
	Private.talentInfo[specId] = { specData, heroData }
	return specData, heroData
end

WeakAuras.StopMotion = {
	texture_data = {},
	texture_types = {
		Blizzard = {}
	}
}
local texture_data = {}

local replacementString = {}
-- Action bar GCD
texture_data["UI-HUD-ActionBar-GCD-Flipbook-2x"] = { rows = 11, columns = 2, count = 22 }
-- Arcane shock
texture_data["UF-Arcane-ShockFX"] = { rows = 5, columns = 6, count = 28 }
-- Checkmark
texture_data["activities-checkmark_flipbook-large"] = { rows = 2, columns = 4, count = 8 }
-- Chi wind
texture_data["UF-Chi-WindFX"] = { rows = 3, columns = 6, count = 17 }
-- Death knight runes
replacementString = {
	"Blood",
	"Default",
	"Frost",
	"Unholy"
}
for _, v in ipairs(replacementString) do
	local name = ("UF-DKRunes-%sDeplete"):format(v)
	texture_data[name] = { rows = 4, columns = 6, count = 23 }
end
-- Dice
texture_data["lootroll-animdice"] = { rows = 9, columns = 5, count = 44 }
-- Dragonriding vigor
texture_data["dragonriding_vigor_fill_flipbook"] = { rows = 5, columns = 4, count = 20 }
-- Druid combo points
texture_data["UF-DruidCP-Slash"] = { rows = 3, columns = 8, count = 20 }
-- Essence spinner
texture_data["UF-Essence-Flipbook-FX-Circ"] = { rows = 3, columns = 10, count = 29 }
-- Experience bars
replacementString = {
	"Rested",
	"Reputation",
	"Experience",
	"Honor",
	"ArtifactPower"
}
for _, v in ipairs(replacementString) do
	local name = ("UI-HUD-ExperienceBar-Fill-%s-2x-Flipbook"):format(v)
	texture_data[name] = { rows = 30, columns = 1, count = 30 }
end
replacementString = {
	"Rested",
	"Reputation",
	"XP",
	"Faction-Orange",
	"ArtifactPower"
}
for _, v in ipairs(replacementString) do
	local name = ("UI-HUD-ExperienceBar-Flare-%s-2x-Flipbook"):format(v)
	texture_data[name] = { rows = 7, columns = 4, count = 28 }
end
-- Great vault unlocking
texture_data["greatVault-unlocked-anim"] = { rows = 11, columns = 5, count = 54 }
-- Group finder eye
texture_data["groupfinder-eye-flipbook-initial"] = { rows = 5, columns = 11, count = 52 }
texture_data["groupfinder-eye-flipbook-searching"] = { rows = 8, columns = 11, count = 80 }
texture_data["groupfinder-eye-flipbook-mouseover"] = { rows = 1, columns = 12, count = 12 }
texture_data["groupfinder-eye-flipbook-foundfx"] = { rows = 5, columns = 15, count = 75 }
texture_data["groupfinder-eye-flipbook-found-initial"] = { rows = 7, columns = 11, count = 70 }
texture_data["groupfinder-eye-flipbook-found-loop"] = { rows = 4, columns = 11, count = 41 }
texture_data["groupfinder-eye-flipbook-poke-initial"] = { rows = 6, columns = 11, count = 66 }
texture_data["groupfinder-eye-flipbook-poke-loop"] = { rows = 6, columns = 11, count = 62 }
texture_data["groupfinder-eye-flipbook-poke-end"] = { rows = 4, columns = 11, count = 38 }
-- Holy power runes
for i = 1, 5 do
	local name = ("UF-HolyPower-DepleteRune%d"):format(i)
	texture_data[name] = { rows = 5, columns = 6, count = 26 }
end

-- Loot roll reveal
texture_data["lootroll-animreveal-a"] = { rows = 2, columns = 6, count = 12 }
-- Mail
texture_data["UI-HUD-Minimap-Mail-New-Flipbook-2x"] = { rows = 5, columns = 4, count = 20 }
texture_data["UI-HUD-Minimap-Mail-Reminder-Flipbook-2x"] = { rows = 3, columns = 4, count = 12 }
-- Ping markers
replacementString = {
	"Assist",
	"Attack",
	"OnMyWay",
	"Warning",
	"NonThreat",
	"Threat"
}
for _, v in ipairs(replacementString) do
	local name = ("Ping_Marker_FlipBook_%s"):format(v)
	texture_data[name] = { rows = 4, columns = 6, count = 21 }
end
-- Player rest
texture_data["UI-HUD-UnitFrame-Player-Rest-Flipbook"] = { rows = 7, columns = 6, count = 42 }
-- Priest void bar
texture_data["Unit_Priest_Void_Fill_Flipbook"] = { rows = 9, columns = 5, count = 45 }
-- Professions
replacementString = {
	"Alchemy",
	"Blacksmithing",
	"Cooking",
	"Engineering",
	"Fishing",
	"Herbalism",
	"Inscription",
	"Leatherworking",
	"Mining",
	"Skinning",
	"Tailoring"
}
for _, v in ipairs(replacementString) do
	local name = ("Skillbar_Fill_Flipbook_%s"):format(v)
	texture_data[name] = { rows = 30, columns = 2, count = 60 }
end
texture_data["Skillbar_Fill_Flipbook_Enchanting"] = { rows = 37, columns = 2, count = 74 }
texture_data["Skillbar_Fill_Flipbook_Jewelcrafting"] = { rows = 22, columns = 2, count = 44 }
replacementString = {
	"Alchemy",
	"Blacksmithing",
	"Enchanting",
	"Engineering",
	"Herbalism",
	"Inscription",
	"Jewelcrafting",
	"Leatherworking",
	"Mining",
	"Skinning",
	"Tailoring"
}
for _, v in ipairs(replacementString) do
	local name = ("SpecDial_Fill_Flipbook_%s"):format(v)
	texture_data[name] = { rows = 6, columns = 6, count = 36 }
	name = ("SpecDial_Pip_Flipbook_%s"):format(v)
	texture_data[name] = { rows = 4, columns = 4, count = 16 }
	name = ("SpecDial_EndPip_Flipbook_%s"):format(v)
	texture_data[name] = { rows = 4, columns = 6, count = 24 }
end
for i = 1, 5 do
	local name = ("GemAppear_T%d_Flipbook"):format(i)
	texture_data[name] = { rows = 3, columns = 4, count = 12 }
	name = ("Quality-BarFill-Flipbook-T%d-x2"):format(i)
	texture_data[name] = { rows = 15, columns = 4, count = 60 }
end
for i = 1, 4 do
	local name = ("GemDissolve_T%d_Flipbook"):format(i)
	texture_data[name] = { rows = 3, columns = 4, count = 12 }
end
-- Rogue combo points
replacementString = {
	"Red",
	"Blue"
}
for _, v in ipairs(replacementString) do
	local name = ("UF-RogueCP-Slash-%s"):format(v)
	texture_data[name] = { rows = 3, columns = 6, count = 17 }
end
-- Soul shards
replacementString = {
	"A",
	"B",
	"C"
}
for _, v in ipairs(replacementString) do
	local name = ("UF-SoulShards-Flipbook-Deplete%s"):format(v)
	texture_data[name] = { rows = 3, columns = 6, count = 15 }
end
texture_data["UF-SoulShards-Flipbook-Soul"] = { rows = 3, columns = 7, count = 18 }
-- Dragonriding
do
	local flipbooks = {
		{ pattern = "%s_fill_flipbook", duration = 1.2, rows = 5, columns = 4, count = 20 },
		{ pattern = "%s_filled_flipbook", duration = 0.6, rows = 2, columns = 4, count = 8 },
		{ pattern = "%s_burst_flipbook", duration = 0.55, rows = 4, columns = 4, count = 16 },
		{ pattern = "%s_decor_flipbook_left", duration = 0.3, rows = 2, columns = 4, count = 8 },
		{ pattern = "%s_decor_flipbook_right", duration = 0.3, rows = 2, columns = 4, count = 8 },
	}
	local kitName = "dragonriding_sgvigor"
	for _, flipbook in ipairs(flipbooks) do
		local name = flipbook.pattern:format(kitName)
		texture_data[name] = { rows = flipbook.rows, columns = flipbook.columns, count = flipbook.count }
	end
end

-- Supplement the data
for k, v in pairs(texture_data) do
	local atlasInfo = C_Texture.GetAtlasInfo(k)
	if atlasInfo then
		if atlasInfo.rawSize then
			v.tileWidth = atlasInfo.rawSize.x / v.columns
			v.tileHeight = atlasInfo.rawSize.y / v.rows
		end
		v.isBlizzardFlipbook = true
		WeakAuras.StopMotion.texture_data[k] = v
		WeakAuras.StopMotion.texture_types.Blizzard[k] = k
	end
end
