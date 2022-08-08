if not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local encounter_list = ""
local zoneId_list = ""
function Private.InitializeEncounterAndZoneLists()
  if encounter_list ~= "" then
    return
  end
  EJ_SelectTier(EJ_GetCurrentTier())

  for _, inRaid in ipairs({false, true}) do
    local instance_index = 1
    local instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)
    local title = inRaid and L["Raids"] or L["Dungeons"]
    zoneId_list = ("%s|cffffd200%s|r\n"):format(zoneId_list, title)

    while instance_id do
      EJ_SelectInstance(instance_id)
      local instance_name, _, _, _, _, _, dungeonAreaMapID = EJ_GetInstanceInfo(instance_id)
      local ej_index = 1
      local boss, _, _, _, _, _, encounter_id = EJ_GetEncounterInfoByIndex(ej_index, instance_id)

      -- zone ids
      if dungeonAreaMapID and dungeonAreaMapID ~= 0 then
        local mapGroupId = C_Map.GetMapGroupID(dungeonAreaMapID)
        if mapGroupId then -- If there's a group id, only list that one
          zoneId_list = ("%s%s: g%d\n"):format(zoneId_list, instance_name, mapGroupId)
        else
          zoneId_list = ("%s%s: %d\n"):format(zoneId_list, instance_name, dungeonAreaMapID)
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
    zoneId_list = zoneId_list .. "\n"
  end

  encounter_list = encounter_list:sub(1, -3) .. "\n\n" .. L["Supports multiple entries, separated by commas\n"]
end

function Private.get_encounters_list()
  return encounter_list
end

function Private.get_zoneId_list()
  return zoneId_list
end

