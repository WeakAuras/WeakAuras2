if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

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
	[1] = { extraOffsetX = 30, extraOffsetY = 31, }, -- Warrior
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
      local spellName, _, icon = GetSpellInfo(talentData[1])
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
		return Private.talentInfo[specId]
	end
  local specData = {}
	C_ClassTalents.InitializeViewLoadout(specId, 70)
	C_ClassTalents.ViewLoadout({})
  local configId = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
  local configInfo = C_Traits.GetConfigInfo(configId)
  if configInfo == nil then return end
  for _, treeId in ipairs(configInfo.treeIDs) do
    local nodes = C_Traits.GetTreeNodes(treeId)
    for _, nodeId in ipairs(nodes) do
      local node = C_Traits.GetNodeInfo(configId, nodeId)
      if node and node.ID ~= 0 then
        for idx, talentId in ipairs(node.entryIDs) do
          local entryInfo = C_Traits.GetEntryInfo(configId, talentId)
          local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
          local spellName = GetSpellInfo(definitionInfo.spellID)
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
            tinsert(specData, talentData)
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
	Private.talentInfo[specId] = specData
  return specData
end

