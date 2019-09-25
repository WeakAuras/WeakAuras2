if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local tinsert = table.insert
local tostring = tostring
local select, pairs, type = select, pairs, type
local ceil, min = ceil, min

-- WoW APIs
local GetTalentInfo = GetTalentInfo
local GetNumSpecializationsForClassID, GetSpecialization = GetNumSpecializationsForClassID, GetSpecialization
local UnitClass, UnitHealth, UnitHealthMax, UnitName, UnitStagger, UnitPower, UnitPowerMax = UnitClass, UnitHealth, UnitHealthMax, UnitName, UnitStagger, UnitPower, UnitPowerMax
local UnitAlternatePowerInfo, UnitAlternatePowerTextureInfo = UnitAlternatePowerInfo, UnitAlternatePowerTextureInfo
local GetSpellInfo, GetItemInfo, GetItemCount, GetItemIcon = GetSpellInfo, GetItemInfo, GetItemCount, GetItemIcon
local GetShapeshiftFormInfo, GetShapeshiftForm = GetShapeshiftFormInfo, GetShapeshiftForm
local GetRuneCooldown, UnitCastingInfo, UnitChannelInfo = GetRuneCooldown, UnitCastingInfo, UnitChannelInfo
local CastingInfo, ChannelInfo = CastingInfo, ChannelInfo

local WeakAuras = WeakAuras
local L = WeakAuras.L

local SpellRange = LibStub("SpellRange-1.0")
function WeakAuras.IsSpellInRange(spellId, unit)
  return SpellRange.IsSpellInRange(spellId, unit)
end

if not WeakAuras.IsClassic() then
  local LibRangeCheck = LibStub("LibRangeCheck-2.0")

  function WeakAuras.GetRange(unit, checkVisible)
    return LibRangeCheck:GetRange(unit, checkVisible);
  end

  function WeakAuras.CheckRange(unit, range, operator)
    local min, max = LibRangeCheck:GetRange(unit, true);
    if (type(range) ~= "number") then
      range = tonumber(range);
    end
    if (not range) then
      return
    end
    if (operator == "<=") then
      return (max or 999) <= range;
    else
      return (min or 0) >= range;
    end
  end
end

local LibClassicCasterino
if WeakAuras.IsClassic() then
  LibClassicCasterino = LibStub("LibClassicCasterino")
end

if not WeakAuras.IsClassic() then
  WeakAuras.UnitCastingInfo = UnitCastingInfo
else
  WeakAuras.UnitCastingInfo = function(unit)
    if UnitIsUnit(unit, "player") then
      return CastingInfo()
    else
      return LibClassicCasterino:UnitCastingInfo(unit)
    end
  end
end

function WeakAuras.UnitChannelInfo(unit)
  if not WeakAuras.IsClassic() then
    return UnitChannelInfo(unit)
  elseif UnitIsUnit(unit, "player") then
    return ChannelInfo()
  else
    return LibClassicCasterino:UnitChannelInfo(unit)
  end
end

-- encounterJournalID => encounterID
WeakAuras.encounter_table = {
  -- Uldir
  [2168] = 2144, -- Taloc the Corrupted
  [2167] = 2141, -- MOTHER
  [2146] = 2128, -- Fetid Devourer
  [2169] = 2136, -- Zek'voz, Herald of N'zoth
  [2195] = 2145, -- Zul, Reborn
  [2194] = 2135, -- Mythrax the Unraveler
  [2166] = 2134, -- Vectis
  [2147] = 2122, -- G'huun
  [2344] = 2265, -- Champion of the Light
  -- Battle for Dazar'alor
  --[2344] = 2265, -- Champion of the Light (A)
  [2333] = 2265, -- Champion of the Light (H)
  [2340] = 2284, -- Grong, the Revenant (A)
  [2325] = 2263, -- Grong, the Jungle Lord (H)
  [2323] = 2285, -- Jadefire Masters (A)
  [2341] = 2266, -- Jadefire Masters (H)
  [2342] = 2271, -- Opulence
  [2330] = 2268, -- Conclave of the Chosen
  [2334] = 2276, -- High Tinker Mekkatorque
  [2335] = 2272, -- King Rastakhan
  [2337] = 2280, -- Stormwall Blockade
  [2343] = 2281, -- Lady Jaina Proudmoore
  -- Crucible of Storms
  [2328] = 2269, -- The Restless Cabal
  [2332] = 2273, -- Uu'nat, Harbinger of the Void
  -- The Eternal Palace
  [2352] = 2298, -- Abyssal Commander Sivara
  [2353] = 2305, -- Radiance of Ashara
  [2347] = 2289, -- Blackwater Behemoth
  [2354] = 2304, -- Lady Ashvane
  [2351] = 2303, -- The Hatchery (Orgozoa)
  [2359] = 2311, -- The Queen's Court
  [2349] = 2293, -- Za'qul, Herald of N'zoth
  [2361] = 2299, -- Queen Azshara
}

local function get_encounters_list()
  if WeakAuras.IsClassic() then return "" end
  local encounter_list = ""

  EJ_SelectTier(EJ_GetNumTiers())
  local instance_index = 1
  local instance_id = EJ_GetInstanceByIndex(instance_index, true)
  while instance_id do
    EJ_SelectInstance(instance_id)
    local name = EJ_GetInstanceInfo()
    local ej_index = 1
    local boss, _, ej_id = EJ_GetEncounterInfoByIndex(ej_index)
    while boss do
      local encounter_id = WeakAuras.encounter_table[ej_id]
      if encounter_id then
        if ej_index == 1 then
          encounter_list = ("%s|cffffd200%s|r\n"):format(encounter_list, name)
        end
        encounter_list = ("%s%s: %d\n"):format(encounter_list, boss, WeakAuras.encounter_table[ej_id])
      end
      ej_index = ej_index + 1
      boss, _, ej_id = EJ_GetEncounterInfoByIndex(ej_index)
    end
    instance_index = instance_index + 1
    instance_id = EJ_GetInstanceByIndex(instance_index, true)
    encounter_list = encounter_list .. "\n"
  end

  return encounter_list:sub(1, -3) .. "\n\n" .. L["Supports multiple entries, separated by commas\n"]
end

local function get_zoneId_list()
  if WeakAuras.IsClassic() then return "" end
  local zoneId_list = ""
  EJ_SelectTier(EJ_GetNumTiers())
  for _,inRaid in ipairs({false, true}) do
    local instance_index = 1
    local instance_id
    local title = inRaid and L["Raids"] or L["Dungeons"]
    zoneId_list = ("%s|cffffd200%s|r\n"):format(zoneId_list, title)
    repeat
      instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)
      instance_index = instance_index + 1
      if instance_id then
        EJ_SelectInstance(instance_id)
        local iname,_,_, _,_,_,dungeonAreaMapID = EJ_GetInstanceInfo();
        if dungeonAreaMapID and dungeonAreaMapID ~= 0 then
          local mapGroupId = C_Map.GetMapGroupID(dungeonAreaMapID)
          if mapGroupId then
            local maps = ""
            for k, map in ipairs(C_Map.GetMapGroupMembersInfo(mapGroupId)) do
              if map.mapID then
                maps = maps .. map.mapID .. ", "
              end
            end
            maps = maps:match "^(.*), \n?$" or "" -- trim last ", "
            zoneId_list = ("%s%s: %s\n"):format(zoneId_list, iname, maps)
          else
            zoneId_list = ("%s%s: %d\n"):format(zoneId_list, iname, dungeonAreaMapID)
          end
        end
      end
    until not instance_id
    zoneId_list = zoneId_list .. "\n"
  end
  local currentmap_id = C_Map.GetBestMapForUnit("player")
  local currentmap_info = C_Map.GetMapInfo(currentmap_id)
  local currentmap_name = currentmap_info and currentmap_info.name or ""
  local mapGroupId = C_Map.GetMapGroupID(currentmap_id)
  if mapGroupId then
    -- if map is in a group, its real name is (or should be?) found in GetMapGroupMembersInfo
    for k, map in ipairs(C_Map.GetMapGroupMembersInfo(mapGroupId)) do
      if map.mapID and map.mapID == currentmap_id and map.name then
        currentmap_name = map.name
        break
      end
    end
  end
  return ("%s|cffffd200%s|r%s: %d\n\n%s"):format(
    zoneId_list,
    L["Current Zone\n"],
    currentmap_name,
    currentmap_id,
    L["Supports multiple entries, separated by commas"]
  )
end

local function get_zoneGroupId_list()
  if WeakAuras.IsClassic() then return "" end
  local zoneGroupId_list = ""
  EJ_SelectTier(EJ_GetNumTiers())
  for _,inRaid in ipairs({false, true}) do
    local instance_index = 1
    local instance_id
    local title = inRaid and L["Raids"] or L["Dungeons"]
    zoneGroupId_list = ("%s|cffffd200%s|r\n"):format(zoneGroupId_list, title)
    repeat
      instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)
      instance_index = instance_index + 1
      if instance_id then
        EJ_SelectInstance(instance_id)
        local iname,_,_, _,_,_,dungeonAreaMapID = EJ_GetInstanceInfo();
        if dungeonAreaMapID and dungeonAreaMapID ~= 0 then
          local mapGroupId = C_Map.GetMapGroupID(dungeonAreaMapID)
          if mapGroupId then
            zoneGroupId_list = ("%s%s: %d\n"):format(zoneGroupId_list, iname, mapGroupId)
          end
        end
      end
    until not instance_id
    zoneGroupId_list = zoneGroupId_list .. "\n"
  end
  local currentmap_id = C_Map.GetBestMapForUnit("player")
  local currentmap_info = C_Map.GetMapInfo(currentmap_id)
  local currentmap_name = currentmap_info and currentmap_info.name
  local currentmapgroup_id = C_Map.GetMapGroupID(currentmap_id)
  return ("%s|cffffd200%s|r\n%s%s\n\n%s"):format(
    zoneGroupId_list,
    L["Current Zone Group"],
    currentmapgroup_id and currentmap_name and currentmap_name..": " or "",
    currentmapgroup_id or L["None"],
    L["Supports multiple entries, separated by commas"]
  )
end

WeakAuras.function_strings = {
  count = [[
    return function(count)
      if(count %s %s) then
        return true
      else
        return false
      end
    end
  ]],
  count_fraction = [[
    return function(count, max)
      local fraction = count/max
      if(fraction %s %s) then
        return true
      else
        return false
      end
    end
  ]],
  always = [[
    return function()
      return true
    end
  ]]
};

local hsvFrame = CreateFrame("Colorselect")

-- HSV transition, for a much prettier color transition in many cases
-- see http://www.wowinterface.com/forums/showthread.php?t=48236
function WeakAuras.GetHSVTransition(perc, r1, g1, b1, a1, r2, g2, b2, a2)
  --get hsv color for colorA
  hsvFrame:SetColorRGB(r1, g1, b1)
  local h1, s1, v1 = hsvFrame:GetColorHSV() -- hue, saturation, value
  --get hsv color for colorB
  hsvFrame:SetColorRGB(r2, g2, b2)
  local h2, s2, v2 = hsvFrame:GetColorHSV() -- hue, saturation, value
  local h3 = floor(h1 - (h1 - h2) * perc)
  -- find the shortest arc through the color circle, then interpolate
  local diff = h2 - h1
  if diff < -180 then
    diff = diff + 360
  elseif diff > 180 then
    diff = diff - 360
  end

  h3 = (h1 + perc * diff) % 360
  local s3 = s1 - ( s1 - s2 ) * perc
  local v3 = v1 - ( v1 - v2 ) * perc
  --get the RGB values of the new color
  hsvFrame:SetColorHSV(h3, s3, v3)
  local r, g, b = hsvFrame:GetColorRGB()
  --interpolate alpha
  local a = a1 - ( a1 - a2 ) * perc
  --return the new color
  return r, g, b, a
end


WeakAuras.anim_function_strings = {
  straight = [[
    function(progress, start, delta)
      return start + (progress * delta)
    end
  ]],
  straightTranslate = [[
    function(progress, startX, startY, deltaX, deltaY)
      return startX + (progress * deltaX), startY + (progress * deltaY)
    end
  ]],
  straightScale = [[
    function(progress, startX, startY, scaleX, scaleY)
      return startX + (progress * (scaleX - startX)), startY + (progress * (scaleY - startY))
    end
  ]],
  straightColor = [[
    function(progress, r1, g1, b1, a1, r2, g2, b2, a2)
      return r1 + (progress * (r2 - r1)), g1 + (progress * (g2 - g1)), b1 + (progress * (b2 - b1)), a1 + (progress * (a2 - a1))
    end
  ]],
  straightHSV = [[
    function(progress, r1, g1, b1, a1, r2, g2, b2, a2)
      return WeakAuras.GetHSVTransition(progress, r1, g1, b1, a1, r2, g2, b2, a2)
    end
  ]],
  circle = [[
    function(progress, startX, startY, deltaX, deltaY)
      local angle = progress * 2 * math.pi
      return startX + (deltaX * math.cos(angle)), startY + (deltaY * math.sin(angle))
    end
  ]],
  circle2 = [[
    function(progress, startX, startY, deltaX, deltaY)
      local angle = progress * 2 * math.pi
      return startX + (deltaX * math.sin(angle)), startY + (deltaY * math.cos(angle))
    end
  ]],
  spiral = [[
    function(progress, startX, startY, deltaX, deltaY)
      local angle = progress * 2 * math.pi
      return startX + (progress * deltaX * math.cos(angle)), startY + (progress * deltaY * math.sin(angle))
    end
  ]],
  spiralandpulse = [[
    function(progress, startX, startY, deltaX, deltaY)
      local angle = (progress + 0.25) * 2 * math.pi
      return startX + (math.cos(angle) * deltaX * math.cos(angle*2)), startY + (math.abs(math.cos(angle)) * deltaY * math.sin(angle*2))
    end
  ]],
  shake = [[
    function(progress, startX, startY, deltaX, deltaY)
      local prog
      if(progress < 0.25) then
        prog = progress * 4
      elseif(progress < .75) then
        prog = 2 - (progress * 4)
      else
        prog = (progress - 1) * 4
      end
      return startX + (prog * deltaX), startY + (prog * deltaY)
    end
  ]],
  bounceDecay = [[
    function(progress, startX, startY, deltaX, deltaY)
      local prog = (progress * 3.5) % 1
      local bounce = math.ceil(progress * 3.5)
      local bounceDistance = math.sin(prog * math.pi) * (bounce / 4)
    return startX + (bounceDistance * deltaX), startY + (bounceDistance * deltaY)
  end
  ]],
  bounce = [[
    function(progress, startX, startY, deltaX, deltaY)
      local bounceDistance = math.sin(progress * math.pi)
      return startX + (bounceDistance * deltaX), startY + (bounceDistance * deltaY)
    end
  ]],
  flash = [[
    function(progress, start, delta)
      local prog
      if(progress < 0.5) then
        prog = progress * 2
      else
        prog = (progress - 1) * 2
      end
      return start + (prog * delta)
    end
  ]],
  pulse = [[
    function(progress, startX, startY, scaleX, scaleY)
      local angle = (progress * 2 * math.pi) - (math.pi / 2)
      return startX + (((math.sin(angle) + 1)/2) * (scaleX - 1)), startY + (((math.sin(angle) + 1)/2) * (scaleY - 1))
    end
  ]],
  alphaPulse = [[
    function(progress, start, delta)
      local angle = (progress * 2 * math.pi) - (math.pi / 2)
      return start + (((math.sin(angle) + 1)/2) * delta)
    end
  ]],
  pulseColor = [[
    function(progress, r1, g1, b1, a1, r2, g2, b2, a2)
      local angle = (progress * 2 * math.pi) - (math.pi / 2)
      local newProgress = ((math.sin(angle) + 1)/2);
      return r1 + (newProgress * (r2 - r1)),
           g1 + (newProgress * (g2 - g1)),
           b1 + (newProgress * (b2 - b1)),
           a1 + (newProgress * (a2 - a1))
    end
  ]],
  pulseHSV = [[
    function(progress, r1, g1, b1, a1, r2, g2, b2, a2)
      local angle = (progress * 2 * math.pi) - (math.pi / 2)
      local newProgress = ((math.sin(angle) + 1)/2);
      return WeakAuras.GetHSVTransition(newProgress, r1, g1, b1, a1, r2, g2, b2, a2)
    end
  ]],
  fauxspin = [[
    function(progress, startX, startY, scaleX, scaleY)
      local angle = progress * 2 * math.pi
      return math.cos(angle) * scaleX, startY + (progress * (scaleY - startY))
    end
  ]],
  fauxflip = [[
    function(progress, startX, startY, scaleX, scaleY)
      local angle = progress * 2 * math.pi
      return startX + (progress * (scaleX - startX)), math.cos(angle) * scaleY
    end
  ]],
  backandforth = [[
    function(progress, start, delta)
    local prog
    if(progress < 0.25) then
      prog = progress * 4
      elseif(progress < .75) then
      prog = 2 - (progress * 4)
    else
      prog = (progress - 1) * 4
    end
    return start + (prog * delta)
    end
  ]],
  wobble = [[
    function(progress, start, delta)
    local angle = progress * 2 * math.pi
    return start + math.sin(angle) * delta
    end
  ]],
  hide = [[
    function()
    return 0
    end
  ]]
};

WeakAuras.anim_presets = {
  -- Start and Finish
  slidetop = {
    type = "custom",
    duration = 0.25,
    use_translate = true,
    x = 0, y = 50,
    use_alpha = true,
    alpha = 0
  },
  slideleft = {
    type = "custom",
    duration = 0.25,
    use_translate = true,
    x = -50,
    y = 0,
    use_alpha = true,
    alpha = 0
  },
  slideright = {
    type = "custom",
    duration = 0.25,
    use_translate = true,
    x = 50,
    y = 0,
    use_alpha = true,
    alpha = 0
  },
  slidebottom = {
    type = "custom",
    duration = 0.25,
    use_translate = true,
    x = 0,
    y = -50,
    use_alpha = true,
    alpha = 0
  },
  fade = {
    type = "custom",
    duration = 0.25,
    use_alpha = true,
    alpha = 0
  },
  grow = {
    type = "custom",
    duration = 0.25,
    use_scale = true,
    scalex = 2,
    scaley = 2,
    use_alpha = true,
    alpha = 0
  },
  shrink = {
    type = "custom",
    duration = 0.25,
    use_scale = true,
    scalex = 0,
    scaley = 0,
    use_alpha = true,
    alpha = 0
  },
  spiral = {
    type = "custom",
    duration = 0.5,
    use_translate = true,
    x = 100,
    y = 100,
    translateType = "spiral",
    use_alpha = true,
    alpha = 0
  },
  bounceDecay = {
    type = "custom",
    duration = 1.5,
    use_translate = true,
    x = 50,
    y = 50,
    translateType = "bounceDecay",
    use_alpha = true,
    alpha = 0
  },

  -- Main
  shake = {
    type = "custom",
    duration = 0.5,
    use_translate = true,
    x = 10,
    y = 0,
    translateType = "circle2"
  },
  spin = {
    type = "custom",
    duration = 1,
    use_scale = true,
    scalex = 1,
    scaley = 1,
    scaleType = "fauxspin"
  },
  flip = {
    type = "custom",
    duration = 1,
    use_scale = true,
    scalex = 1,
    scaley = 1,
    scaleType = "fauxflip"
  },
  wobble = {
    type = "custom",
    duration = 0.5,
    use_rotate = true,
    rotate = 3,
    rotateType = "wobble"
  },
  pulse = {
    type = "custom",
    duration = 0.75,
    use_scale = true,
    scalex = 1.05,
    scaley = 1.05,
    scaleType = "pulse"
  },
  alphaPulse = {
    type = "custom",
    duration = 0.5,
    use_alpha = true,
    alpha = 0.5,
    alphaType = "alphaPulse"
  },
  rotateClockwise = {
    type = "custom",
    duration = 4,
    use_rotate = true,
    rotate = -360
  },
  rotateCounterClockwise = {
    type = "custom",
    duration = 4,
    use_rotate = true,
    rotate = 360
  },
  spiralandpulse = {
    type = "custom",
    duration = 6,
    use_translate = true,
    x = 100,
    y = 100,
    translateType = "spiralandpulse"
  },
  circle = {
    type = "custom",
    duration = 4,
    use_translate = true,
    x = 100,
    y = 100,
    translateType = "circle"
  },
  orbit = {
    type = "custom",
    duration = 4,
    use_translate = true,
    x = 100,
    y = 100,
    translateType = "circle",
    use_rotate = true,
    rotate = 360
  },
  bounce = {
    type = "custom",
    duration = 0.6,
    use_translate = true,
    x = 0,
    y = 25,
    translateType = "bounce"
  }
};

WeakAuras.class_ids = {}
for classID = 1, 20 do -- GetNumClasses not supported by wow classic
  local classInfo = C_CreatureInfo.GetClassInfo(classID)
  if classInfo then
    WeakAuras.class_ids[classInfo.classFile] = classInfo.classID
  end
end

function WeakAuras.CheckTalentByIndex(index)
  if WeakAuras.IsClassic() then
    local tab = ceil(index / 20)
    local num_talent = (index - 1) % 20 + 1
    local _, _, _, _, rank  = GetTalentInfo(tab, num_talent)
    return rank and rank > 0;
  else
    local tier = ceil(index / 3)
    local column = (index - 1) % 3 + 1
    local _, _, _, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
    return selected or known;
  end
end

-- The one true order of the first 3 talents, see the setup of WeakAuras.pvp_talent_types
local pvpTalentId = { 3589, 3588, 3587 };

function WeakAuras.CheckPvpTalentByIndex(index)
  if (index <= 3) then
    local talentSlotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(1);
    if (not talentSlotInfo or not talentSlotInfo.selectedTalentID) then
      return false;
    end
    return select(3, GetPvpTalentInfoByID(pvpTalentId[index])) == select(3, GetPvpTalentInfoByID(talentSlotInfo.selectedTalentID));
  else
    local checkTalentSlotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(2)
    if checkTalentSlotInfo then
      local checkTalentId = checkTalentSlotInfo.availableTalentIDs[index - 3];
      for i = 2, 4 do
        local talentSlotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(i);
        if talentSlotInfo and (talentSlotInfo.selectedTalentID == checkTalentId) then
          return true;
        end
      end
    end
    return false;
  end
end

function WeakAuras.CheckNumericIds(loadids, currentId)
  if (not loadids or not currentId) then
    return false;
  end

  local searchFrom = 0;
  local startI, endI = string.find(loadids, currentId, searchFrom);
  while (startI) do
    searchFrom = endI + 1; -- start next search from end
    if (startI == 1 or tonumber(string.sub(loadids, startI - 1, startI - 1)) == nil) then
      -- Either right at start, or character before is not a number
      if (endI == string.len(loadids) or tonumber(string.sub(loadids, endI + 1, endI + 1)) == nil) then
        return true;
      end
    end
    startI, endI = string.find(loadids, currentId, searchFrom);
  end
  return false;
end

function WeakAuras.ValidateNumeric(info, val)
  if val ~= nil and val ~= "" and (not tonumber(val) or tonumber(val) >= 2^31) then
    return false;
  end
  return true
end

function WeakAuras.CheckMPlusAffixIds(loadids, currentId)
  if (not loadids or not currentId) or type(currentId) ~= "table" then
    return false
  end
  for i=1, #currentId do
    if loadids == currentId[i] then
      return true
    end
  end
  return false
end

function WeakAuras.CheckChargesDirection(direction, triggerDirection)
  return triggerDirection == "CHANGED"
    or (triggerDirection == "GAINED" and direction > 0)
    or (triggerDirection == "LOST" and direction < 0)
end

function WeakAuras.CheckCombatLogFlags(flags, flagToCheck)
  if (flagToCheck == "InGroup") then
    return bit.band(flags, 7) > 0;
  elseif (flagToCheck == "NotInGroup") then
    return bit.band(flags, 7) == 0;
  end
end

function WeakAuras.CheckRaidFlags(flags, flagToCheck)
  flagToCheck = tonumber(flagToCheck)
  if not flagToCheck then return end --bailout
  if flagToCheck == 0 then --no raid mark
    return bit.band(flags, COMBATLOG_OBJECT_RAIDTARGET_MASK) == 0
  elseif flagToCheck == 9 then --any raid mark
    return bit.band(flags, COMBATLOG_OBJECT_RAIDTARGET_MASK) > 0
  else -- specific raid mark
    return bit.band(flags, _G['COMBATLOG_OBJECT_RAIDTARGET'..flagToCheck]) > 0
  end
end

function WeakAuras.IsSpellKnown(spell, pet)
  if (pet) then
    return IsSpellKnown(spell, pet);
  end
  return IsPlayerSpell(spell) or IsSpellKnown(spell);
end

function WeakAuras.IsSpellKnownIncludingPet(spell)
  if (not tonumber(spell)) then
    spell = select(7, GetSpellInfo(spell));
  end
  if (not spell) then
    return false;
  end
  if (WeakAuras.IsSpellKnown(spell) or WeakAuras.IsSpellKnown(spell, true)) then
    return true;
  end
  -- WORKAROUND brain damage around void eruption
  -- In shadow form void eruption is overriden by void bolt, yet IsSpellKnown for void bolt
  -- returns false, whereas it returns true for void eruption
  local baseSpell = FindBaseSpellByID(spell);
  if (not baseSpell) then
    return false;
  end
  if (baseSpell ~= spell) then
    return WeakAuras.IsSpellKnown(baseSpell) or WeakAuras.IsSpellKnown(baseSpell, true);
  end
end

function WeakAuras.UnitPowerDisplayMod(powerType)
  if (powerType == 7) then
    return 10;
  end
  return 1;
end

function WeakAuras.UseUnitPowerThirdArg(powerType)
  if (powerType == 7) then
    return true;
  end
  return nil;
end

function WeakAuras.GetNumSetItemsEquipped(setID)
  if not setID or not type(setID) == "number" then return end
  if not WeakAuras.IsClassic() then
    local itemList = C_LootJournal.GetItemSetItems(setID)
    if not itemList then return end
    local setName = GetItemSetInfo(setID)
    local max = #itemList
    local equipped = 0
    for _,v in ipairs(itemList) do
      if IsEquippedItem(v.itemID) then
        equipped = equipped + 1
      end
    end
   return equipped, max, setName
  else
    local equipped = 0
    local setName = GetItemSetInfo(setID)
    for i = 1, 18 do
      local item = GetInventoryItemID("player", i)
      if item and select(16, GetItemInfo(item)) == setID then
        equipped = equipped + 1
      end
    end
    return equipped, 18, setName
  end
end

local function valuesForTalentFunction(trigger)
  return function()
    local single_class;
    -- First check to use if the class load is on multi-select with only one class selected
    if(trigger.use_class == false and trigger.class and trigger.class.multi) then
      local num_classes = 0;
      for class in pairs(trigger.class.multi) do
        single_class = class;
        num_classes = num_classes + 1;
      end
      if(num_classes ~= 1) then
        single_class = nil;
      end
    end
    -- If that is not the case, see if it is on single-select
    if((not single_class) and trigger.use_class and trigger.class and trigger.class.single) then
      single_class = trigger.class.single
    end

    if (trigger.use_class == nil) then -- no class selected, fallback to current class
      single_class = select(2, UnitClass("player"));
    end

    local single_spec;
    if not WeakAuras.IsClassic() then
      if single_class then
        if(trigger.use_spec == false and trigger.spec and trigger.spec.multi) then
          local num_specs = 0;
          for spec in pairs(trigger.spec.multi) do
            single_spec = spec;
            num_specs = num_specs + 1;
          end
          if (num_specs ~= 1) then
            single_spec = nil;
          end
        end
      end
      if ((not single_spec) and trigger.use_spec and trigger.spec and trigger.spec.single) then
        single_spec = trigger.spec.single;
      end

      if (trigger.use_spec == nil) then
        single_spec = GetSpecialization();
      end
    end

    -- If a single specific class was found, load the specific list for it
    if(single_class and WeakAuras.talent_types_specific[single_class]
      and single_spec and WeakAuras.talent_types_specific[single_class][single_spec]) then
      return WeakAuras.talent_types_specific[single_class][single_spec];
    elseif(WeakAuras.IsClassic() and single_class and WeakAuras.talent_types_specific[single_class]
      and WeakAuras.talent_types_specific[single_class]) then
      return WeakAuras.talent_types_specific[single_class];
    else
      return WeakAuras.talent_types;
    end
  end
end

WeakAuras.load_prototype = {
  args = {
    {
      name = "combat",
      display = L["In Combat"],
      type = "tristate",
      width = WeakAuras.normalWidth,
      init = "arg",
      optional = true,
      events = {"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}
    },
    {
      name = "encounter",
      display = L["In Encounter"],
      type = "tristate",
      width = WeakAuras.normalWidth,
      init = "arg",
      optional = true,
      events = {"ENCOUNTER_START", "ENCOUNTER_END"}
    },
    {
      name = "warmode",
      display = L["War Mode Active"],
      type = "tristate",
      init = "arg",
      width = WeakAuras.doubleWidth,
      optional = true,
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"UNIT_FLAGS"}
    },
    {
      name = "never",
      display = L["Never"],
      type = "toggle",
      width = WeakAuras.normalWidth,
      init = "false",
    },
    {
      name = "petbattle",
      display = L["In Pet Battle"],
      type = "tristate",
      init = "arg",
      width = WeakAuras.normalWidth,
      optional = true,
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"PET_BATTLE_OPENING_START", "PET_BATTLE_CLOSE"}
    },
    {
      name = "vehicle",
      display = L["In Vehicle"],
      type = "tristate",
      init = "arg",
      width = WeakAuras.normalWidth,
      optional = true,
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"VEHICLE_UPDATE", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "UPDATE_OVERRIDE_ACTIONBAR", "UNIT_FLAGS"}
    },
    {
      name = "vehicleUi",
      display = L["Has Vehicle UI"],
      type = "tristate",
      init = "arg",
      width = WeakAuras.normalWidth,
      optional = true,
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"VEHICLE_UPDATE", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "UPDATE_OVERRIDE_ACTIONBAR"}
    },
    {
      name = "ingroup",
      display = L["In Group"],
      type = "multiselect",
      width = WeakAuras.normalWidth,
      init = "arg",
      values = "group_types",
      events = {"GROUP_LEFT", "GROUP_JOINED"}
    },
    {
      name = "name",
      display = L["Player Name"],
      type = "tristatestring",
      init = "arg"
    },
    {
      name = "realm",
      display = L["Realm"],
      type = "tristatestring",
      init = "arg"
    },
    {
      name = "class",
      display = L["Player Class"],
      type = "multiselect",
      values = "class_types",
      init = "arg"
    },
    {
      name = "spec",
      display = L["Talent Specialization"],
      type = "multiselect",
      values = function(trigger)
        return function()
          local single_class;
          local min_specs = 4;
          -- First check to use if the class load is on multi-select with only one class selected
          -- Also check the number of specs for each class selected in the multi-select and keep track of the minimum
          -- (i.e., 3 unless Druid is the only thing selected, but this method is flexible in case another spec gets added to another class)
          if(trigger.use_class == false and trigger.class and trigger.class.multi) then
            local num_classes = 0;
            for class in pairs(trigger.class.multi) do
              single_class = class;
              -- If any checked class has only 3 specs, min_specs will become 3
              min_specs = min(min_specs, GetNumSpecializationsForClassID(WeakAuras.class_ids[class]))
              num_classes = num_classes + 1;
            end
            if(num_classes ~= 1) then
              single_class = nil;
            end
          end
          -- If that is not the case, see if it is on single-select
          if((not single_class) and trigger.use_class and trigger.class and trigger.class.single) then
            single_class = trigger.class.single
          end

          if (trigger.use_class == nil) then -- no class selected, fallback to current class
            single_class = select(2, UnitClass("player"));
          end

          -- If a single specific class was found, load the specific list for it
          if(single_class) then
            return WeakAuras.spec_types_specific[single_class];
          else
            -- List 4 specs if no class is specified, but if any multi-selected classes have less than 4 specs, list 3 instead
            if (min_specs < 3) then
              return WeakAuras.spec_types_2;
            elseif(min_specs < 4) then
              return WeakAuras.spec_types_3;
            else
              return WeakAuras.spec_types;
            end
          end
        end
      end,
      init = "arg",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"PLAYER_TALENT_UPDATE"}
    },
    {
      name = "class_and_spec",
      display = L["Class and Specialization"],
      type = "multiselect",
      values = "spec_types_all",
      init = "arg",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"PLAYER_TALENT_UPDATE"}
    },
    {
      name = "talent",
      display = L["Talent selected"],
      type = "multiselect",
      values = valuesForTalentFunction,
      test = "WeakAuras.CheckTalentByIndex(%d)",
      events = {"PLAYER_TALENT_UPDATE"}
    },
    {
      name = "talent2",
      display = L["And Talent selected"],
      type = "multiselect",
      values = valuesForTalentFunction,
      test = "WeakAuras.CheckTalentByIndex(%d)",
      enable = function(trigger)
        return trigger.use_talent ~= nil or trigger.use_talent2 ~= nil;
      end,
      events = {"PLAYER_TALENT_UPDATE"}
    },
    {
      name = "talent3",
      display = L["And Talent selected"],
      type = "multiselect",
      values = valuesForTalentFunction,
      test = "WeakAuras.CheckTalentByIndex(%d)",
      enable = function(trigger)
        return (trigger.use_talent ~= nil and trigger.use_talent2 ~= nil) or trigger.use_talent3 ~= nil;
      end,
      events = {"PLAYER_TALENT_UPDATE"}
    },
    {
      name = "pvptalent",
      display = L["PvP Talent selected"],
      type = "multiselect",
      values = function(trigger)
        return function()
          local single_class;
          -- First check to use if the class load is on multi-select with only one class selected
          if(trigger.use_class == false and trigger.class and trigger.class.multi) then
            local num_classes = 0;
            for class in pairs(trigger.class.multi) do
              single_class = class;
              num_classes = num_classes + 1;
            end
            if(num_classes ~= 1) then
              single_class = nil;
            end
          end
          -- If that is not the case, see if it is on single-select
          if((not single_class) and trigger.use_class and trigger.class and trigger.class.single) then
            single_class = trigger.class.single
          end

          if (trigger.use_class == nil) then -- no class selected, fallback to current class
            single_class = select(2, UnitClass("player"));
          end

          local single_spec;
          if (single_class) then
            if(trigger.use_spec == false and trigger.spec and trigger.spec.multi) then
              local num_specs = 0;
              for spec in pairs(trigger.spec.multi) do
                single_spec = spec;
                num_specs = num_specs + 1;
              end
              if (num_specs ~= 1) then
                single_spec = nil;
              end
            end
          end
          if ((not single_spec) and trigger.use_spec and trigger.spec and trigger.spec.single) then
            single_spec = trigger.spec.single;
          end

          if (trigger.use_spec == nil) then
            single_spec = GetSpecialization();
          end

          -- print ("Using talent cache", single_class, single_spec);
          -- If a single specific class was found, load the specific list for it
          if(single_class and WeakAuras.pvp_talent_types_specific[single_class]
            and single_spec and WeakAuras.pvp_talent_types_specific[single_class][single_spec]) then
            return WeakAuras.pvp_talent_types_specific[single_class][single_spec];
          else
            return WeakAuras.pvp_talent_types;
          end
        end
      end,
      test = "WeakAuras.CheckPvpTalentByIndex(%d)",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"PLAYER_PVP_TALENT_UPDATE"}
    },
    {
      name = "spellknown",
      display = L["Spell Known"],
      type = "spell",
      test = "WeakAuras.IsSpellKnown(%s)",
      events = {"SPELLS_CHANGED"}
    },
    {
      name = "race",
      display = L["Player Race"],
      type = "multiselect",
      values = "race_types",
      init = "arg"
    },
    {
      name = "faction",
      display = L["Player Faction"],
      type = "multiselect",
      values = "faction_group",
      init = "arg"
    },
    {
      name = "level",
      display = L["Player Level"],
      type = "number",
      init = "arg",
      events = {"PLAYER_LEVEL_UP"}
    },
    {
      name = "effectiveLevel",
      display = L["Player Effective Level"],
      type = "number",
      init = "arg",
      desc = L["The effective level differs from the level in e.g. Time Walking dungeons."],
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"PLAYER_LEVEL_UP", "UNIT_FLAGS", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"}
    },
    {
      name = "zone",
      display = L["Zone Name"],
      type = "string",
      init = "arg",
      events = {"ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"}
    },
    {
      name = "zoneId",
      display = L["Zone ID(s)"],
      type = "string",
      init = "arg",
      desc = get_zoneId_list,
      test = "WeakAuras.CheckNumericIds(%q, zoneId)",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"}
    },
    {
      name = "zonegroupId",
      display = L["Zone Group ID(s)"],
      type = "string",
      init = "arg",
      desc = get_zoneGroupId_list,
      test = "WeakAuras.CheckNumericIds(%q, zonegroupId)",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"}
    },
    {
      name = "encounterid",
      display = L["Encounter ID(s)"],
      type = "string",
      init = "arg",
      desc = get_encounters_list,
      test = "WeakAuras.CheckNumericIds(%q, encounterid)",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"ENCOUNTER_START", "ENCOUNTER_END"}
    },
    {
      name = "size",
      display = L["Instance Type"],
      type = "multiselect",
      values = "instance_types",
      init = "arg",
      control = "WeakAurasSortedDropdown",
      events = {"ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"}
    },
    {
      name = "difficulty",
      display = L["Instance Difficulty"],
      type = "multiselect",
      values = "difficulty_types",
      init = "arg",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"PLAYER_DIFFICULTY_CHANGED", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"}
    },
    {
      name = "role",
      display = L["Spec Role"],
      type = "multiselect",
      values = "role_types",
      init = "arg",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"PLAYER_ROLES_ASSIGNED", "PLAYER_TALENT_UPDATE"}
    },
    {
      name = "affixes",
      display = L["Mythic+ Affix"],
      type = "multiselect",
      values = "mythic_plus_affixes",
      init = "arg",
      test = "WeakAuras.CheckMPlusAffixIds(%d, affixes)",
      enable = not WeakAuras.IsClassic(),
      hidden = WeakAuras.IsClassic(),
      events = {"CHALLENGE_MODE_START", "CHALLENGE_MODE_COMPLETED"}
    },
    {
      name = "itemequiped",
      display = L["Item Equipped"],
      type = "item",
      test = "IsEquippedItem(%s)",
      events = { "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED"}
    }
  }
};

local function AddUnitChangeInternalEvents(unit, t)
  if (unit == "player" or unit == "multi" or unit == "target" or unit == "focus") then
    -- Handled by normal events
  elseif unit == "pet" then
    WeakAuras.WatchForPetDeath();
    tinsert(t, "PET_UPDATE")
  else
    WeakAuras.WatchUnitChange(unit)
    tinsert(t, "UNIT_CHANGED_" .. string.upper(unit))
  end
end

local function AddUnitEventForEvents(result, unit, event)
  if not unit or not (WeakAuras.baseUnitId[unit] or WeakAuras.multiUnitId[unit]) then
    if not result.events then
      result.events = {}
    end
    tinsert(result.events, event)
  else
    if not result.unit_events then
      result.unit_events = {}
    end
    if not result.unit_events[unit] then
      result.unit_events[unit] = {}
    end
    tinsert(result.unit_events[unit], event)
  end
end

local function AddUnitChangeEvents(unit, t)
  if (unit == "player" or unit == "multi") then

  elseif (unit == "target") then
    AddUnitEventForEvents(t, nil, "PLAYER_TARGET_CHANGED")
  elseif (unit == "focus") then
    AddUnitEventForEvents(t, nil, "PLAYER_FOCUS_CHANGED")
  else
    -- Handled by WatchUnitChange
  end
end

WeakAuras.event_prototypes = {
  ["Unit Characteristics"] = {
    type = "status",
    events = function(trigger)
      local result = {}
      AddUnitEventForEvents(result, trigger.unit, "UNIT_LEVEL")
      AddUnitEventForEvents(result, trigger.unit, "UNIT_FACTION")
      AddUnitChangeEvents(trigger.unit, result)
      if trigger.unitisunit then
        AddUnitChangeEvents(trigger.unitisunit, result);
      end
      return result;
    end,
    internal_events = function(trigger)
      local result = {
        "WA_DELAYED_PLAYER_ENTERING_WORLD"
      }
      AddUnitChangeInternalEvents(trigger.unit, result)
      if trigger.unitisunit then
        AddUnitChangeInternalEvents(trigger.unitisunit, result)
      end
      return result
    end,
    force_events = "UNIT_LEVEL",
    name = L["Unit Characteristics"],
    init = function(trigger)
      trigger.unit = trigger.unit or "target";
      local ret = [=[
        local unit = %q;
        local concernedUnit = %q;
        local extraUnit = %q;
      ]=];

      return ret:format(trigger.unit, trigger.unit, trigger.unitisunit or "");
    end,
    statesParameter = "one",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific",
        test = "(event ~= 'UNIT_LEVEL' and event ~= 'UNIT_FACTION') or UnitIsUnit(unit, %q)"
      },
      {
        name = "unitisunit",
        display = L["Unit is Unit"],
        type = "unit",
        init = "UnitIsUnit(concernedUnit, extraUnit)",
        values = "actual_unit_types_with_specific",
        test = "unitisunit",
        store = true,
        conditionType = "bool",
        desc = function() return L["Can be used for e.g. checking if \"boss1target\" is the same as \"player\"."] end
      },
      {
        name = "name",
        display = L["Name"],
        type = "string",
        init = "UnitName(concernedUnit)",
        store = true,
        conditionType = "string"
      },
      {
        name = "class",
        display = L["Class"],
        type = "select",
        init = "select(2, UnitClass(concernedUnit))",
        values = "class_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "hostility",
        display = L["Hostility"],
        type = "select",
        init = "UnitIsEnemy('player', concernedUnit) and 'hostile' or 'friendly'",
        values = "hostility_types",
        store = true,
        conditionType = "select",
      },
      {
        name = "character",
        display = L["Character Type"],
        type = "select",
        init = "UnitIsPlayer(concernedUnit) and 'player' or 'npc'",
        values = "character_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "level",
        display = L["Level"],
        type = "number",
        init = "UnitLevel(concernedUnit)",
        store = true,
        conditionType = "number"
      },
      {
        name = "attackable",
        display = L["Attackable"],
        type = "tristate",
        init = "UnitCanAttack('player', concernedUnit)",
        store = true,
        conditionType = "bool"
      },
      {
        hidden = true,
        test = "UnitExists(concernedUnit)"
      }
    },
    automaticrequired = true
  },
  ["Health"] = {
    type = "status",
    events = function(trigger)
      local result = {}
      AddUnitChangeEvents(trigger.unit, result)
      AddUnitEventForEvents(result, trigger.unit, "UNIT_HEALTH_FREQUENT")
      if not WeakAuras.IsClassic() then
        if trigger.use_showAbsorb then
          AddUnitEventForEvents(result, trigger.unit, "UNIT_ABSORB_AMOUNT_CHANGED")
        end
        if trigger.use_showIncomingHeal then
          AddUnitEventForEvents(result, trigger.unit, "UNIT_HEAL_PREDICTION")
        end
      end
      return result
    end,
    internal_events = function(trigger)
      local result = { "WA_DELAYED_PLAYER_ENTERING_WORLD" }
      AddUnitChangeInternalEvents(trigger.unit, result)
      return result
    end,
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Health"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        local unit = unit or %q;
        local concernedUnit = %q;
      ]=];

      return ret:format(trigger.unit, trigger.unit);
    end,
    statesParameter = "one",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific",
        test = "event ~= 'UNIT_HEALTH_FREQUENT' or UnitIsUnit(unit, %q)"
      },
      {
        name = "health",
        display = L["Health"],
        type = "number",
        init = "UnitHealth(concernedUnit)",
        store = true,
        conditionType = "number"
      },
      {
        name = "percenthealth",
        display = L["Health (%)"],
        type = "number",
        init = "(UnitHealth(concernedUnit) / math.max(1, UnitHealthMax(concernedUnit))) * 100",
        store = true,
        conditionType = "number"
      },
      {
        name = "showAbsorb",
        display = L["Show Absorb"],
        type = "toggle",
        test = "true",
        reloadOptions = true,
        enable = not WeakAuras.IsClassic(),
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "absorbMode",
        display = L["Absorb Display"],
        type = "select",
        test = "true",
        values = "absorb_modes",
        required = true,
        enable = function(trigger) return WeakAuras.IsClassic() and trigger.use_showAbsorb end,
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "showIncomingHeal",
        display = L["Show Incoming Heal"],
        type = "toggle",
        test = "true",
        reloadOptions = true,
        enable = not WeakAuras.IsClassic(),
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "absorb",
        type = "number",
        display = L["Absorb"],
        init = "UnitGetTotalAbsorbs(concernedUnit)",
        store = true,
        conditionType = "number",
        enable = function(trigger) return not WeakAuras.IsClassic() and trigger.use_showAbsorb end,
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "healprediction",
        type = "number",
        display = L["Incoming Heal"],
        init = "UnitGetIncomingHeals(concernedUnit)",
        store = true,
        conditionType = "number",
        enable = function(trigger) return not WeakAuras.IsClassic() and trigger.use_showIncomingHeal end,
        hidden = WeakAuras.IsClassic()
      },
      {
        hidden = true,
        test = "UnitExists(concernedUnit)"
      }
    },
    durationFunc = function(trigger)
      return UnitHealth(trigger.unit), UnitHealthMax(trigger.unit), true;
    end,
    nameFunc = function(trigger)
      return UnitName(trigger.unit);
    end,
    overlayFuncs = {
      {
        name = L["Absorb"],
        func = function(trigger, state)
          local absorb = UnitGetTotalAbsorbs(trigger.unit);
          if (trigger.absorbMode == "OVERLAY_FROM_START") then
            return 0, absorb;
          else
            return "forward", absorb;
          end
        end,
        enable = function(trigger)
          return not WeakAuras.IsClassic() and trigger.use_showAbsorb;
        end
      },
      {
        name = L["Incoming Heal"],
        func = function(trigger, state)
          if (trigger.use_showIncomingHeal) then
            local heal = UnitGetIncomingHeals(trigger.unit);
            return "forward", heal;
          end
        end,
        enable = function(trigger)
          return not WeakAuras.IsClassic() and trigger.use_showIncomingHeal;
        end
      }
    },
    automaticrequired = true
  },
  ["Power"] = {
    type = "status",
    events = function(trigger)
      local result = {}
      AddUnitEventForEvents(result, trigger.unit, "UNIT_POWER_FREQUENT")
      AddUnitEventForEvents(result, trigger.unit, "UNIT_MAXPOWER")
      AddUnitEventForEvents(result, trigger.unit, "UNIT_DISPLAYPOWER")
      if trigger.use_showCost then
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_START")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_STOP")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_FAILED")
      end
      if trigger.use_powertype and trigger.powertype == 99 then
        AddUnitEventForEvents(result, trigger.unit, "UNIT_ABSORB_AMOUNT_CHANGED")
      end
      AddUnitChangeEvents(trigger.unit, result);
      return result;
    end,
    internal_events = function(trigger)
      local result = { "WA_DELAYED_PLAYER_ENTERING_WORLD" }
      AddUnitChangeInternalEvents(trigger.unit, result)
      return result
    end,
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Power"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        local unit = unit or %q;
        local concernedUnit = %q;
        local powerType = %s;
        local unitPowerType = UnitPowerType(concernedUnit);
        local powerTypeToCheck = powerType or unitPowerType;
        local powerThirdArg = WeakAuras.UseUnitPowerThirdArg(powerTypeToCheck);
        if WeakAuras.IsClassic() and powerType == 99 then powerType = 1 end
      ]=];
      ret = ret:format(trigger.unit, trigger.unit, trigger.use_powertype and trigger.powertype or "nil");
      if (trigger.use_powertype and trigger.powertype == 99 and not WeakAuras.IsClassic()) then
        ret = ret .. [[
          local UnitPower = UnitStagger;
          local UnitPowerMax = UnitHealthMax;
        ]]
        if (trigger.use_scaleStagger and trigger.scaleStagger) then
          ret = ret .. string.format([[
            local UnitPowerMax = function(unit)
              return UnitHealthMax(unit) * %s
            end
          ]], trigger.scaleStagger)
        else
          ret = ret .. [[
          local UnitPowerMax = UnitHealthMax;
        ]]
        end
      end
      local canEnableShowCost = (not trigger.use_powertype or trigger.powertype ~= 99) and trigger.unit == "player";
      if (canEnableShowCost and trigger.use_showCost) then
        ret = ret .. [[
          if (event == "UNIT_SPELLCAST_START" and unit == "player") then
            local spellID = select(9, WeakAuras.UnitCastingInfo("player"))
            if spellID then
              local costTable = GetSpellPowerCost(spellID);
              for _, costInfo in pairs(costTable) do
                if costInfo.type == powerTypeToCheck then
                  state.cost = costInfo.cost;
                  break;
                end
              end
            end
            state.changed = true;
          elseif (event == "UNIT_DISPLAYPOWER") then
            local spellID;
            if WeakAuras.IsClassic() then
              spellID = select(9, CastingInfo());
            else
              spellID = select(9, UnitCastingInfo("player"));
            end
            if spellID then
              local costTable = GetSpellPowerCost(spellID);
              local cost;
              for _, costInfo in pairs(costTable) do
                if costInfo.type == powerTypeToCheck then
                  cost = costInfo.cost;
                  break;
                end
              end
              if (state.cost ~= cost) then
                state.cost = cost;
                state.changed = true;
              end
            end
            state.changed = true;
          elseif ( (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED") and unit == "player") then
            state.cost = nil;
            state.changed = true;
          end
        ]]
      end

      return ret
    end,
    statesParameter = "one",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific",
        test = "event ~= 'UNIT_POWER_FREQUENT' or UnitIsUnit(unit, %q)"
      },
      {
        name = "powertype",
        display = L["Power Type"],
        type = "select",
        values = function() return WeakAuras.IsClassic() and WeakAuras.power_types or WeakAuras.power_types_with_stagger end,
        init = "unitPowerType",
        test = "true",
        store = true,
        conditionType = "select"
      },
      {
        name = "requirePowerType",
        display = L["Only if Primary"],
        type = "toggle",
        test = "unitPowerType == powerType",
        enable = function(trigger)
          return trigger.use_powertype
        end,
      },
      {
        name = "showCost",
        display = L["Overlay Cost of Casts"],
        type = "toggle",
        test = "true",
        enable = function(trigger)
          return (not trigger.use_powertype or trigger.powertype ~= 99) and trigger.unit == "player";
        end,
        reloadOptions = true
      },
      {
        name = "scaleStagger",
        display = L["Stagger Scale"],
        type = "string",
        validate = WeakAuras.ValidateNumeric,
        enable = function(trigger)
          return trigger.use_powertype and trigger.powertype == 99
        end,
        test = "true"
      },
      {
        name = "power",
        display = L["Power"],
        type = "number",
        init = WeakAuras.IsClassic() and "powerType == 4 and GetComboPoints(unit, 'target') or UnitPower(concernedUnit, powerType, powerThirdArg) / WeakAuras.UnitPowerDisplayMod(powerTypeToCheck)" or "UnitPower(concernedUnit, powerType, powerThirdArg) / WeakAuras.UnitPowerDisplayMod(powerTypeToCheck)",
        store = true,
        conditionType = "number"
      },
      {
        name = "percentpower",
        display = L["Power (%)"],
        type = "number",
        init = WeakAuras.IsClassic() and "powerType == 4 and (GetComboPoints(unit, 'target') / math.max(1, UnitPowerMax(unit, 14)) * 100) or (power or 0) / math.max(1, UnitPowerMax(concernedUnit, powerType, powerThirdArg)) * 100" or "(power or 0) / math.max(1, UnitPowerMax(concernedUnit, powerType, powerThirdArg)) * 100 * WeakAuras.UnitPowerDisplayMod(powerTypeToCheck)",
        store = true,
        conditionType = "number"
      },
      {
        hidden = true,
        test = "UnitExists(concernedUnit)"
      }
    },
    durationFunc = function(trigger)
      local powerType = trigger.use_powertype and trigger.powertype or nil;
      if powerType == 99 then
        if WeakAuras.IsClassic() then return end
        if trigger.use_scaleStagger and trigger.scaleStagger then
          return UnitStagger(trigger.unit), math.max(1, UnitHealthMax(trigger.unit) * trigger.scaleStagger), "fastUpdate";
        else
          return UnitStagger(trigger.unit), math.max(1, UnitHealthMax(trigger.unit)), "fastUpdate";
        end
      elseif (WeakAuras.IsClassic() and powerType == 4) then -- combo points
        return GetComboPoints(trigger.unit, "target"), UnitPowerMax(trigger.unit, 14), true
      end
      local powerTypeToCheck = trigger.powertype or UnitPowerType(trigger.unit);
      local pdm = WeakAuras.UnitPowerDisplayMod(powerTypeToCheck);
      local useThirdArg = WeakAuras.UseUnitPowerThirdArg(powerTypeToCheck)

      local value = UnitPower(trigger.unit, powerType, useThirdArg) / pdm;
      local total = math.max(1, UnitPowerMax(trigger.unit, powerType, useThirdArg)) / pdm;

      return value, total, true;
    end,
    overlayFuncs = {
      {
        name = L["Spell Cost"],
        func = function(trigger, state)
          return "back", state.cost;
        end,
        enable = function(trigger)
          return trigger.use_showCost and (not trigger.use_powertype or trigger.powertype ~= 99) and trigger.unit == "player";
        end
      }
    },
    stacksFunc = function(trigger)
      local powerType = trigger.use_powertype and trigger.powertype or nil;
      if powerType == 99 then
        if WeakAuras.IsClassic() then return end
        return UnitStagger(trigger.unit);
      end
      local powerTypeToCheck = trigger.powertype or UnitPowerType(trigger.unit);
      local pdm = WeakAuras.UnitPowerDisplayMod(powerTypeToCheck);
      local useThirdArg = WeakAuras.UseUnitPowerThirdArg(powerTypeToCheck)
      return UnitPower(trigger.unit, powerType, useThirdArg) / pdm;
    end,
    automaticrequired = true
  },
  ["Alternate Power"] = {
    type = "status",
    events = function(trigger)
      local result = {}
      AddUnitEventForEvents(result, trigger.unit, "UNIT_POWER_FREQUENT")
      AddUnitChangeEvents(trigger.unit, result)
      return result
    end,
    internal_events = function(trigger)
      local result = {"WA_DELAYED_PLAYER_ENTERING_WORLD"}
      AddUnitChangeInternalEvents(trigger.unit, result)
      return result
    end,
    name = L["Alternate Power"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        local unit = unit or %q
        local concernedUnit = %q
        local _, _, _, _, _, _, _, _, _, _, name = UnitAlternatePowerInfo(%q);
      ]=]
      return ret:format(trigger.unit, trigger.unit, trigger.unit);
    end,
    statesParameter = "one",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific",
        test = "event ~= 'UNIT_POWER_FREQUENT' or UnitIsUnit(unit, %q)"
      },
      {
        name = "power",
        display = L["Alternate Power"],
        type = "number",
        init = "UnitPower(concernedUnit, 10)"
      },
      {
        hidden = true,
        test = "UnitExists(concernedUnit) and name"
      }
    },
    durationFunc = function(trigger)
      return UnitPower(trigger.unit, 10), math.max(1, UnitPowerMax(trigger.unit, 10)), "fastUpdate";
    end,
    nameFunc = function(trigger)
      local _, _, _, _, _, _, _, _, _, _, name = UnitAlternatePowerInfo(trigger.unit);
      return name;
    end,
    iconFunc = function(trigger)
      local icon = UnitAlternatePowerTextureInfo(trigger.unit, 0);
      return icon;
    end,
    automaticrequired = true
  },
  -- Todo: Give useful options to condition based on GUID and flag info
  ["Combat Log"] = {
    type = "event",
    events = {
      ["events"] = {"COMBAT_LOG_EVENT_UNFILTERED"}
    },
    init = function(trigger)
      local ret = [[
        local use_cloneId = %s;
      ]];
      return ret:format(trigger.use_cloneId and "true" or "false");
    end,
    name = L["Combat Log"],
    canHaveAuto = true,
    statesParameter = "all",
    args = {
      {}, -- timestamp ignored with _ argument
      {}, -- messageType ignored with _ argument (it is checked before the dynamic function)
      {}, -- hideCaster ignored with _ argument
      {
        name = "sourceGUID",
        init = "arg",
        hidden = "true",
        test = "true",
        store = true
      },
      {
        name = "sourceUnit",
        display = L["Source Unit"],
        type = "unit",
        test = "(sourceGUID or '') == (UnitGUID(%q) or '') and sourceGUID",
        values = "actual_unit_types_with_specific",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "ENVIRONMENTAL")
        end,
        store = true,
        conditionType = "select"
      },
      {
        name = "sourceName",
        display = L["Source Name"],
        type = "string",
        init = "arg",
        store = true,
        conditionType = "string"
      },
      {
        name = "sourceNpcId",
        display = L["Source NPC Id"],
        type = "string",
        test = "select(6, strsplit('-', sourceGUID or '')) == %q",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "ENVIRONMENTAL")
        end,
      },
      {
        name = "sourceFlags",
        display = L["Source In Group"],
        type = "select",
        values = "combatlog_flags_check_type",
        init = "arg",
        store = true,
        test = "WeakAuras.CheckCombatLogFlags(sourceFlags, %q)",
        conditionType = "select",
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckCombatLogFlags(state.sourceFlags, needle);
        end
      },
      {
        name = "sourceRaidFlags",
        display = L["Source Raid Mark"],
        type = "select",
        values = "combatlog_raid_mark_check_type",
        init = "arg",
        store = true,
        test = "WeakAuras.CheckRaidFlags(sourceRaidFlags, %q)",
        conditionType = "select",
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckRaidFlags(state.sourceRaidFlags, needle);
        end
      },
      {
        name = "destGUID",
        init = "arg",
        hidden = "true",
        test = "true",
        store = true
      },
      {
        name = "destUnit",
        display = L["Destination Unit"],
        type = "unit",
        test = "(destGUID or '') == (UnitGUID(%q) or '') and destGUID",
        values = "actual_unit_types_with_specific",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end,
        store = true,
        conditionType = "select"
      },
      {
        name = "destName",
        display = L["Destination Name"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end,
        store = true,
        conditionType = "string"
      },
      {
        name = "destNpcId",
        display = L["Destination NPC Id"],
        type = "string",
        test = "select(6, strsplit('-', destGUID or '')) == %q",
        enable = function(trigger)
          return not (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end,
      },
      { -- destName ignore for SPELL_CAST_START
        enable = function(trigger)
          return (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end
      },
      {
        name = "destFlags",
        display = L["Destination In Group"],
        type = "select",
        values = "combatlog_flags_check_type",
        init = "arg",
        store = true,
        test = "WeakAuras.CheckCombatLogFlags(destFlags, %q)",
        conditionType = "select",
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckCombatLogFlags(state.destFlags, needle);
        end,
        enable = function(trigger)
          return not (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end,
      },
      {-- destFlags ignore for SPELL_CAST_START
        enable = function(trigger)
          return (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end,
      },
      {
        name = "destRaidFlags",
        display = L["Dest Raid Mark"],
        type = "select",
        values = "combatlog_raid_mark_check_type",
        init = "arg",
        store = true,
        test = "WeakAuras.CheckRaidFlags(destRaidFlags, %q)",
        conditionType = "select",
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckRaidFlags(state.destRaidFlags, needle);
        end,
        enable = function(trigger)
          return not (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end,
      },
      { -- destRaidFlags ignore for SPELL_CAST_START
        enable = function(trigger)
          return (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end
      },
      {
        name = "spellId",
        display = L["Spell Id"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return not WeakAuras.IsClassic() and trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end,
        hidden = WeakAuras.IsClassic(),
        store = true,
        conditionType = "number"
      },
      {
        enable = function(trigger)
          return WeakAuras.IsClassic() and trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end
      }, -- spellId ignored on classic
      {
        name = "spellName",
        display = L["Spell Name"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end,
        store = true,
        conditionType = "string"
      },
      {
        enable = function(trigger)
          return trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end
      }, -- spellSchool ignored with _ argument
      {
        name = "environmentalType",
        display = L["Environment Type"],
        type = "select",
        init = "arg",
        values = "environmental_types",
        enable = function(trigger)
          return trigger.subeventPrefix == "ENVIRONMENTAL"
        end,
        store = true,
        conditionType = "select"
      },
      {
        name = "missType",
        display = L["Miss Type"],
        type = "select",
        init = "arg",
        values = "miss_types",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_MISSED" or trigger.subeventPrefix == "DAMAGE_SHIELD_MISSED")
        end,
        conditionType = "select",
        store = true
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ABSORBED")
        end
      }, -- source of absorb GUID ignored with SPELL_ABSORBED
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ABSORBED")
        end
      }, -- source of absorb Name ignored with SPELL_ABSORBED
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ABSORBED")
        end
      }, -- source of absorb Flags ignored with SPELL_ABSORBED
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ABSORBED")
        end
      }, -- source of absorb Raid Flags ignored with SPELL_ABSORBED
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ABSORBED" or trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
        end
      }, -- extraSpellId ignored with SPELL_ABSORBED
      {
        name = "extraSpellName",
        display = L["Extra Spell Name"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ABSORBED" or trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
        end,
        store = true,
        conditionType = "string"
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ABSORBED" or trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
        end
      }, -- extraSchool ignored with _ argument
      {
        name = "auraType",
        display = L["Aura Type"],
        type = "select",
        init = "arg",
        values = "aura_types",
        store = true,
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix:find("AURA") or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_STOLEN")
        end,
        conditionType = "select"
      },
      {
        name = "amount",
        display = L["Amount"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_ABSORBED" or trigger.subeventSuffix == "_DAMAGE" or trigger.subeventSuffix == "_MISSED" or trigger.subeventSuffix == "_HEAL" or trigger.subeventSuffix == "_ENERGIZE" or trigger.subeventSuffix == "_DRAIN" or trigger.subeventSuffix == "_LEECH" or trigger.subeventPrefix:find("DAMAGE"))
        end,
        store = true,
        conditionType = "number"
      },
      {
        name = "overkill",
        display = L["Overkill"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end,
        store = true,
        conditionType = "number"
      },
      {
        name = "overhealing",
        display = L["Overhealing"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventSuffix == "_HEAL"
        end,
        store = true,
        conditionType = "number"
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end
      }, -- damage school ignored with _ argument
      {
        name = "resisted",
        display = L["Resisted"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end,
        store = true,
        conditionType = "number"
      },
      {
        name = "blocked",
        display = L["Blocked"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end,
        store = true,
        conditionType = "number"
      },
      {
        name = "absorbed",
        display = L["Absorbed"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT" or trigger.subeventSuffix == "_HEAL")
        end,
        store = true,
        conditionType = "number"
      },
      {
        name = "critical",
        display = L["Critical"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT" or trigger.subeventSuffix == "_HEAL")
        end,
        store = true,
        conditionType = "bool"
      },
      {
        name = "glancing",
        display = L["Glancing"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end,
        store = true,
        conditionType = "bool"
      },
      {
        name = "crushing",
        display = L["Crushing"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end,
        store = true,
        conditionType = "bool"
      },
      {
        name = "isOffHand",
        display = L["Is Off Hand"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT")
        end,
        store = true,
        conditionType = "bool"
      },
      {
        name = "number",
        display = L["Number"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_EXTRA_ATTACKS" or trigger.subeventSuffix:find("DOSE"))
        end,
        store = true,
        conditionType = "number"
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ENERGIZE")
        end
      }, -- unknown argument for _ENERGIZE ignored
      {
        name = "powerType",
        display = L["Power Type"],
        type = "select",
        init = "arg",
        values = "power_types",
        store = true,
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ENERGIZE" or trigger.subeventSuffix == "_DRAIN" or trigger.subeventSuffix == "_LEECH")
        end,
        conditionType = "select"
      },
      {
        name = "extraAmount",
        display = L["Extra Amount"],
        type = "number",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_ENERGIZE" or trigger.subeventSuffix == "_DRAIN" or trigger.subeventSuffix == "_LEECH")
        end,
        store = true,
        conditionType = "number"
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix == "_CAST_FAILED"
        end
      }, -- failedType ignored with _ argument - theoretically this is not necessary because it is the last argument in the event, but it is added here for completeness
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''"
      },
      {
        hidden = true,
        name = "icon",
        init = "spellId and select(3, GetSpellInfo(spellId)) or 'Interface\\\\Icons\\\\INV_Misc_QuestionMark'",
        store = true,
        test = "true"
      }
    },
    timedrequired = true
  },
  ["Spell Activation Overlay"] = {
    type = "status",
    events = {
    },
    internal_events = {
      "WA_UPDATE_OVERLAY_GLOW"
    },
    force_events = "WA_UPDATE_OVERLAY_GLOW",
    name = L["Spell Activation Overlay Glow"],
    loadFunc = function(trigger)
      WeakAuras.WatchSpellActivation(tonumber(trigger.spellName));
    end,
    init = function(trigger)
      return string.format("local spellName = tonumber(%q)", trigger.spellName or "");
    end,
    args = {
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        test = "true"
      },
      {
        hidden = true,
        test = "WeakAuras.SpellActivationActive(spellName)";
      }
    },
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    automaticrequired = true
  },
  ["Cooldown Progress (Spell)"] = {
    type = "status",
    events = {},
    internal_events = function(trigger, untrigger)
      local events = {
        "SPELL_COOLDOWN_CHANGED",
        "COOLDOWN_REMAINING_CHECK",
        "WA_DELAYED_PLAYER_ENTERING_WORLD"
      };
      if (trigger.use_showgcd) then
        tinsert(events, "GCD_START");
        tinsert(events, "GCD_CHANGE");
        tinsert(events, "GCD_END");
      end
      return events;
    end,
    force_events = "SPELL_COOLDOWN_FORCE",
    name = L["Cooldown Progress (Spell)"],
    loadFunc = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName;
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      end
      WeakAuras.WatchSpellCooldown(spellName, trigger.use_matchedRune);
      if (trigger.use_showgcd) then
        WeakAuras.WatchGCD();
      end
    end,
    init = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName;
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      end
      trigger.realSpellName = spellName; -- Cache
      local ret = [=[
        local spellname = %s
        local ignoreRuneCD = %s
        local showgcd = %s;
        local ignoreSpellKnown = %s;
        local track = %q
        local startTime, duration, gcdCooldown = WeakAuras.GetSpellCooldown(spellname, ignoreRuneCD, showgcd, ignoreSpellKnown, track);
        local charges, maxCharges, spellCount = WeakAuras.GetSpellCharges(spellname, ignoreSpellKnown);
        local stacks = maxCharges and maxCharges ~= 1 and charges or (spellCount and spellCount > 0 and spellCount) or nil;
        if (charges == nil) then
          -- Use fake charges for spells that use GetSpellCooldown
          charges = (duration == 0) and 1 or 0;
        end
        local genericShowOn = %s
        local expirationTime = startTime and duration and startTime + duration
        state.spellname = spellname;
      ]=];

      local showOnCheck = "false";
      if (trigger.genericShowOn == "showOnReady") then
        showOnCheck = "startTime and startTime == 0 or gcdCooldown";
      elseif (trigger.genericShowOn == "showOnCooldown") then
        showOnCheck = "startTime and startTime > 0 and not gcdCooldown";
      elseif (trigger.genericShowOn == "showAlways") then
        showOnCheck = "startTime ~= nil";
      end

      if (type(spellName) == "string") then
        spellName = "[[" .. spellName .. "]]";
      end
      ret = ret:format(spellName,
        (trigger.use_matchedRune and "true" or "false"),
        (trigger.use_showgcd and "true" or "false"),
        (trigger.use_ignoreSpellKnown and "true" or "false"),
        (trigger.track or "auto"),
        showOnCheck
      );

      if (not trigger.use_trackcharge or not trigger.trackcharge) then
        ret = ret .. [=[
          if (state.expirationTime ~= expirationTime) then
            state.expirationTime = expirationTime;
            state.changed = true;
          end
          if (state.duration ~= duration) then
            state.duration = duration;
            state.changed = true;
          end
          state.progressType = 'timed';
        ]=];
      else
        local ret2 = [=[
          local trackedCharge = %s
          if (charges < trackedCharge) then
            if (state.value ~= duration) then
              state.value = duration;
              state.changed = true;
            end
            if (state.total ~= duration) then
              state.total = duration;
              state.changed = true;
            end

            state.expirationTime = nil;
            state.duration = nil;
            state.progressType = 'static';
          elseif (charges > trackedCharge) then
            if (state.expirationTime ~= 0) then
              state.expirationTime = 0;
              state.changed = true;
            end
            if (state.duration ~= 0) then
              state.duration = 0;
              state.changed = true;
            end
            state.value = nil;
            state.total = nil;
            state.progressType = 'timed';
          else
            if (state.expirationTime ~= expirationTime) then
              state.expirationTime = expirationTime;
              state.changed = true;
              state.changed = true;
            end
            if (state.duration ~= duration) then
              state.duration = duration;
              state.changed = true;
            end
            state.value = nil;
            state.total = nil;
            state.progressType = 'timed';
          end
        ]=];
        local trackedCharge = tonumber(trigger.trackcharge or 1) or 1;
        ret = ret .. ret2:format(trackedCharge - 1);
      end
      if(trigger.use_remaining and trigger.genericShowOn ~= "showOnReady") then
        local ret2 = [[
          local remaining = 0;
          if (expirationTime and expirationTime > 0) then
            remaining = expirationTime - GetTime();
            local remainingCheck = %s;
            if(remaining >= remainingCheck and remaining > 0) then
              WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
            end
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining or 0) or 0);
      end

      return ret;
    end,
    statesParameter = "one",
    canHaveDuration = "timed",
    args = {
      {
      }, -- Ignore first argument (id)
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        test = "true",
        showExactOption = true,
      },
      {
        name = "extra Cooldown Progress (Spell)",
        display = function(trigger)
          return function()
            local text = "";
            if trigger.track == "charges" then
              text = L["Tracking Charge CDs"]
            elseif trigger.track == "cooldown" then
              text = L["Tracking Only Cooldown"]
            end
            if trigger.use_showgcd then
              if text ~= "" then text = text .. "; " end
              text = text .. L["Show GCD"]
            end

            if trigger.use_matchedRune then
              if text ~= "" then text = text .. "; " end
              text = text ..L["Ignore Rune CDs"]
            end

            if trigger.use_ignoreSpellKnown then
              if text ~= "" then text = text .. "; " end
              text = text .. L["Ignore Unknown Spell"]
            end

            if trigger.genericShowOn ~= "showOnReady" and trigger.track ~= "cooldown" then
              if trigger.use_trackcharge and trigger.trackcharge then
                if text ~= "" then text = text .. "; " end
                text = text .. L["Tracking Charge %i"]:format(trigger.trackcharge)
              end
            end
            if text == "" then
              return L["|cFFffcc00Extra Options:|r None"]
            end
            return L["|cFFffcc00Extra Options:|r %s"]:format(text)
          end
        end,
        type = "collapse",
      },
      {
        name = "track",
        display = L["Track Cooldowns"],
        type = "select",
        values = "cooldown_types",
        collapse = "extra Cooldown Progress (Spell)",
        test = "true",
        required = true,
        default = "auto"
      },
      {
        name = "showgcd",
        display = L["Show Global Cooldown"],
        type = "toggle",
        test = "true",
        collapse = "extra Cooldown Progress (Spell)"
      },
      {
        name = "matchedRune",
        display = L["Ignore Rune CD"],
        type = "toggle",
        test = "true",
        collapse = "extra Cooldown Progress (Spell)"
      },
      {
        name = "ignoreSpellKnown",
        display = L["Ignore Spell Known"],
        type = "toggle",
        test = "true",
        collapse = "extra Cooldown Progress (Spell)"
      },
      {
        name = "trackcharge",
        display = L["Show CD of Charge"],
        type = "number",
        enable = function(trigger)
          return (trigger.genericShowOn ~= "showOnReady") and trigger.track ~= "cooldown"
        end,
        test = "true",
        noOperator = true,
        collapse = "extra Cooldown Progress (Spell)"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return (trigger.genericShowOn ~= "showOnReady") end
      },
      {
        name = "charges",
        display = L["Stacks"],
        type = "number",
        store = true,
        conditionType = "number"
      },
      {
        name = "spellCount",
        display = L["Spell Count"],
        type = "number",
        store = true,
        conditionType = "number"
      },
      {
        name = "stacks",
        init = "stacks",
        hidden = true,
        test = "true",
        store = true
      },
      {
        hidden  = true,
        name = "maxCharges",
        store = true,
        display = L["Max Charges"],
        conditionType = "number",
        test = "true",
      },
      {
        name = "genericShowOn",
        display =  L["Show"],
        type = "select",
        values = "cooldown_progress_behavior_types",
        test = "true",
        required = true,
        default = "showOnCooldown"
      },
      {
        hidden = true,
        name = "onCooldown",
        test = "true",
        display = L["On Cooldown"],
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (not state.gcdCooldown and state.expirationTime and state.expirationTime > GetTime()) == (needle == 1)
        end,
      },
      {
        hidden = true,
        name = "gcdCooldown",
        store = true,
        test = "true"
      },
      {
        name = "spellUsable",
        display = L["Spell Usable"],
        hidden = true,
        test = "true",
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (IsUsableSpell(state.spellname) == (needle == 1))
        end,
        conditionEvents = {
          "SPELL_UPDATE_USABLE",
          "PLAYER_TARGET_CHANGED",
          "UNIT_POWER_FREQUENT",
        },
      },
      {
        name = "insufficientResources",
        display = L["Insufficient Resources"],
        hidden = true,
        test = "true",
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (select(2, IsUsableSpell(state.spellname)) == (needle == 1));
        end,
        conditionEvents = {
          "SPELL_UPDATE_USABLE",
          "PLAYER_TARGET_CHANGED",
          "UNIT_POWER_FREQUENT",
        }
      },
      {
        name = "spellInRange",
        display = L["Spell in Range"],
        hidden = true,
        test = "true",
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (UnitExists('target') and state.spellname and WeakAuras.IsSpellInRange(state.spellname, 'target') == needle)
        end,
        conditionEvents = {
          "PLAYER_TARGET_CHANGED",
          "WA_SPELL_RANGECHECK",
        }
      },
      {
        hidden = true,
        test = "genericShowOn"
      }
    },
    nameFunc = function(trigger)
      local name = GetSpellInfo(trigger.realSpellName or 0);
      if(name) then
        return name;
      end
      name = GetSpellInfo(trigger.spellName or 0);
      if (name) then
        return name;
      end
      return "Invalid";
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.realSpellName or 0);
      if (not icon) then
        icon = select(3, GetSpellInfo(trigger.spellName or 0));
      end
      return icon;
    end,
    hasSpellID = true,
    automaticrequired = true,
  },
  ["Cooldown Ready (Spell)"] = {
    type = "event",
    events = {},
    internal_events = {
      "SPELL_COOLDOWN_READY",
    },
    name = L["Cooldown Ready (Spell)"],
    loadFunc = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName;
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      end
      trigger.realSpellName = spellName; -- Cache
      WeakAuras.WatchSpellCooldown(spellName);
    end,
    init = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName;
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      end

      if (type(spellName) == "string") then
        spellName = "[[" .. spellName .. "]]";
      end

      local ret = [=[
        local spellname = %s
      ]=]
      return ret:format(spellName);
    end,
    args = {
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        init = "arg",
        showExactOption = true,
        test = "spellname == spellName"
      }
    },
    nameFunc = function(trigger)
      local name = GetSpellInfo(trigger.realSpellName or 0);
      if(name) then
        return name;
      end
      name = GetSpellInfo(trigger.spellName or 0);
      if (name) then
        return name;
      end
      return "Invalid";
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.realSpellName or 0);
      if (not icon) then
        icon = select(3, GetSpellInfo(trigger.spellName or 0));
      end
      return icon;
    end,
    hasSpellID = true,
    timedrequired = true
  },
  ["Charges Changed (Spell)"] = {
    type = "event",
    events = {},
    internal_events = {
      "SPELL_CHARGES_CHANGED",
    },
    name = L["Charges Changed (Spell)"],
    loadFunc = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName;
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      end
      trigger.realSpellName = spellName; -- Cache
      WeakAuras.WatchSpellCooldown(spellName);
    end,
    init = function(trigger)
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName;
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
        spellName = string.format("%q", spellName or "");
      end
      return string.format("local spell = %s;\n", spellName);
    end,
    statesParameter = "one",
    args = {
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        init = "arg",
        showExactOption = true,
        test = "spell == spellName"
      },
      {
        name = "direction",
        required = true,
        display = L["Charge gained/lost"],
        type = "select",
        values = "charges_change_type",
        init = "arg",
        test = "WeakAuras.CheckChargesDirection(direction, %q)",
        store = true,
        conditionType = "select",
        conditionValues = "charges_change_condition_type";
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckChargesDirection(state.direction, needle)
        end,
      },
      {
        name = "charges",
        display = L["Charges"],
        type = "number",
        init = "arg",
        store = true,
        conditionType = "number"
      }
    },
    nameFunc = function(trigger)
      local name = GetSpellInfo(trigger.realSpellName or 0);
      if(name) then
        return name;
      end
      name = GetSpellInfo(trigger.spellName or 0);
      if (name) then
        return name;
      end
      return "Invalid";
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.realSpellName or 0);
      if (not icon) then
        icon = select(3, GetSpellInfo(trigger.spellName or 0));
      end
      return icon;
    end,
    hasSpellID = true,
    timedrequired = true
  },
  ["Cooldown Progress (Item)"] = {
    type = "status",
    events = {},
    internal_events = function(trigger, untrigger)
      local events = {
        "ITEM_COOLDOWN_READY",
        "ITEM_COOLDOWN_CHANGED",
        "ITEM_COOLDOWN_STARTED",
        "COOLDOWN_REMAINING_CHECK",
      }
      if (trigger.use_showgcd) then
        tinsert(events, "GCD_START");
        tinsert(events, "GCD_CHANGE");
        tinsert(events, "GCD_END");
      end
      return events
    end,
    force_events = "ITEM_COOLDOWN_FORCE",
    name = L["Cooldown Progress (Item)"],
    loadFunc = function(trigger)
      trigger.itemName = trigger.itemName or 0;
      local itemName = type(trigger.itemName) == "number" and trigger.itemName or "[["..trigger.itemName.."]]";
      WeakAuras.WatchItemCooldown(trigger.itemName);
      if (trigger.use_showgcd) then
        WeakAuras.WatchGCD();
      end
    end,
    init = function(trigger)
      --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
      trigger.itemName = trigger.itemName or 0;
      local itemName = type(trigger.itemName) == "number" and trigger.itemName or "[["..trigger.itemName.."]]";
      local ret = [=[
        local itemname = %s;
        local showgcd = %s
        local startTime, duration, enabled, gcdCooldown = WeakAuras.GetItemCooldown(itemname, showgcd);
        local genericShowOn = %s
        state.itemname = itemname;
      ]=];
      if(trigger.use_remaining and trigger.genericShowOn ~= "showOnReady") then
        local ret2 = [[
          local expirationTime = startTime + duration
          local remaining = expirationTime > 0 and (expirationTime - GetTime()) or 0;
          local remainingCheck = %s;
          if(remaining >= remainingCheck and remaining > 0) then
            WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining or 0) or 0);
      end
      return ret:format(itemName,
                        trigger.use_showgcd and "true" or "false",
                        "[[" .. (trigger.genericShowOn or "") .. "]]");
    end,
    statesParameter = "one",
    args = {
      {
        name = "itemName",
        required = true,
        display = L["Item"],
        type = "item",
        test = "true"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return (trigger.genericShowOn ~= "showOnReady") end,
        init = "remaining"
      },
      {
        name = "extra Cooldown Progress (Item)",
        display = function(trigger)
          return function()
            local text = "";
            if trigger.use_showgcd then
              if text ~= "" then text = text .. "; " end
              text = text .. L["Show GCD"]
            end
            if text == "" then
              return L["|cFFffcc00Extra Options:|r None"]
            end
            return L["|cFFffcc00Extra Options:|r %s"]:format(text)
          end
        end,
        type = "collapse",
      },
      {
        name = "showgcd",
        display = L["Show Global Cooldown"],
        type = "toggle",
        test = "true",
        collapse = "extra Cooldown Progress (Item)"
      },
      {
        name = "genericShowOn",
        display =  L["Show"],
        type = "select",
        values = "cooldown_progress_behavior_types",
        test = "true",
        required = true,
        default = "showOnCooldown"
      },
      {
        hidden = true,
        name = "enabled",
        store = true,
        test = "true",
      },
      {
        hidden = true,
        name = "onCooldown",
        test = "true",
        display = L["On Cooldown"],
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (not state.gcdCooldown and state.expirationTime and state.expirationTime > GetTime() or state.enabled == 0) == (needle == 1)
        end,
      },
      {
        name = "itemInRange",
        display = L["Item in Range"],
        hidden = true,
        test = "true",
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (UnitExists('target') and IsItemInRange(state.itemname, 'target')) == (needle == 1)
        end,
        conditionEvents = {
          "PLAYER_TARGET_CHANGED",
          "WA_SPELL_RANGECHECK",
        }
      },
      {
        hidden = true,
        name = "gcdCooldown",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        test = "(genericShowOn == \"showOnReady\" and (startTime == 0 and enabled == 1 or gcdCooldown))" ..
        "or (genericShowOn == \"showOnCooldown\" and (startTime > 0 or enabled == 0) and not gcdCooldown) " ..
        "or (genericShowOn == \"showAlways\")"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration = WeakAuras.GetItemCooldown(type(trigger.itemName) == "number" and trigger.itemName or 0, trigger.use_showgcd);
      startTime = startTime or 0;
      duration = duration or 0;
      return duration, startTime + duration;
    end,
    nameFunc = function(trigger)
      local name = GetItemInfo(trigger.itemName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, _, _, icon = GetItemInfoInstant(trigger.itemName or 0);
      return icon;
    end,
    hasItemID = true,
    automaticrequired = true,
    automaticAutoHide = false
  },
  ["Cooldown Progress (Equipment Slot)"] = {
    type = "status",
    events = {},
    internal_events = function(trigger, untrigger)
      local events = {
        "ITEM_SLOT_COOLDOWN_STARTED",
        "ITEM_SLOT_COOLDOWN_CHANGED",
        "COOLDOWN_REMAINING_CHECK",
        "ITEM_SLOT_COOLDOWN_ITEM_CHANGED",
        "ITEM_SLOT_COOLDOWN_READY",
        "WA_DELAYED_PLAYER_ENTERING_WORLD"
      }

      if (trigger.use_showgcd) then
        tinsert(events, "GCD_START");
        tinsert(events, "GCD_CHANGE");
        tinsert(events, "GCD_END");
      end

      return events
    end,
    force_events = "ITEM_COOLDOWN_FORCE",
    name = L["Cooldown Progress (Equipment Slot)"],
    loadFunc = function(trigger)
      WeakAuras.WatchItemSlotCooldown(trigger.itemSlot);
      if (trigger.use_showgcd) then
        WeakAuras.WatchGCD();
      end
    end,
    init = function(trigger)
      local ret = [[
        local showgcd = %s
        local startTime, duration, enable, gcdCooldown = WeakAuras.GetItemSlotCooldown(%s, showgcd);
        local genericShowOn = %s
        local remaining = startTime + duration - GetTime();
      ]];
      if(trigger.use_remaining and trigger.genericShowOn ~= "showOnReady") then
        local ret2 = [[
          local expirationTime = startTime + duration
          local remaining = expirationTime > 0 and (expirationTime - GetTime()) or 0;
          local remainingCheck = %s;
          if(remaining >= remainingCheck and remaining > 0) then
            WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining or 0) or 0);
      end
      return ret:format(trigger.use_showgcd and "true" or "false",
                        trigger.itemSlot or "0",
                        "[[" .. (trigger.genericShowOn or "") .. "]]");
    end,
    statesParameter = "one",
    args = {
      {
        name = "itemSlot",
        required = true,
        display = L["Equipment Slot"],
        type = "select",
        values = "item_slot_types",
        test = "true"
      },
      {
        name = "extra Cooldown Progress (Equipment Slot)",
        display = function(trigger)
          return function()
            local text = "";
            if trigger.use_showgcd then
              if text ~= "" then text = text .. "; " end
              text = text .. L["Show GCD"]
            end
            if text == "" then
              return L["|cFFffcc00Extra Options:|r None"]
            end
            return L["|cFFffcc00Extra Options:|r %s"]:format(text)
          end
        end,
        type = "collapse",
      },
      {
        name = "showgcd",
        display = L["Show Global Cooldown"],
        type = "toggle",
        test = "true",
        collapse = "extra Cooldown Progress (Equipment Slot)"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return (trigger.genericShowOn ~= "showOnReady") end,
        init = "remaining"
      },
      {
        name = "testForCooldown",
        display = L["is useable"],
        type = "toggle",
        test = "enable == 1"
      },
      {
        name = "genericShowOn",
        display =  L["Show"],
        type = "select",
        values = "cooldown_progress_behavior_types",
        test = "true",
        required = true,
        default = "showOnCooldown"
      },
      {
        hidden = true,
        name = "onCooldown",
        test = "true",
        display = L["On Cooldown"],
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (not state.gcdCooldown and state.expirationTime and state.expirationTime > GetTime()) == (needle == 1);
        end,
      },
      {
        hidden = true,
        name = "gcdCooldown",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        test = "(genericShowOn == \"showOnReady\" and (startTime == 0 or gcdCooldown)) " ..
        "or (genericShowOn == \"showOnCooldown\" and startTime > 0 and not gcdCooldown) " ..
        "or (genericShowOn == \"showAlways\")"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration = WeakAuras.GetItemSlotCooldown(trigger.itemSlot or 0, trigger.use_showgcd);
      startTime = startTime or 0;
      duration = duration or 0;
      return duration, startTime + duration;
    end,
    nameFunc = function(trigger)
      local item = GetInventoryItemID("player", trigger.itemSlot or 0);
      if (item) then
        return GetItemInfo(item);
      end
    end,
    iconFunc = function(trigger)
      return GetInventoryItemTexture("player", trigger.itemSlot or 0) or "Interface\\Icons\\INV_Misc_QuestionMark";
    end,
    automaticrequired = true,
  },
  ["Cooldown Ready (Item)"] = {
    type = "event",
    events = {},
    internal_events = {
      "ITEM_COOLDOWN_READY",
    },
    name = L["Cooldown Ready (Item)"],
    loadFunc = function(trigger)
      trigger.itemName = trigger.itemName or 0;
      WeakAuras.WatchItemCooldown(trigger.itemName);
    end,
    init = function(trigger)
      --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
      trigger.itemName = trigger.itemName or 0;
    end,
    args = {
      {
        name = "itemName",
        required = true,
        display = L["Item"],
        type = "item",
        init = "arg"
      }
    },
    nameFunc = function(trigger)
      local name = GetItemInfo(trigger.itemName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, _, _, icon = GetItemInfoInstant(trigger.itemName or 0);
      return icon;
    end,
    hasItemID = true,
    timedrequired = true
  },
  ["Cooldown Ready (Equipment Slot)"] = {
    type = "event",
    events = {},
    internal_events = {
      "ITEM_SLOT_COOLDOWN_READY"
    },
    name = L["Cooldown Ready (Equipment Slot)"],
    loadFunc  = function(trigger)
      WeakAuras.WatchItemSlotCooldown(trigger.itemSlot);
    end,
    init = function(trigger)
    end,
    args = {
      {
        name = "itemSlot",
        required = true,
        display = L["Equipment Slot"],
        type = "select",
        values = "item_slot_types",
        init = "arg"
      }
    },
    nameFunc = function(trigger)
      return "";
    end,
    iconFunc = function(trigger)
      return GetInventoryItemTexture("player", trigger.itemSlot or 0) or "Interface\\Icons\\INV_Misc_QuestionMark";
    end,
    hasItemID = true,
    timedrequired = true
  },
  ["GTFO"] = {
    type = "event",
    events = {
      ["events"] = {"GTFO_DISPLAY"}
    },
    name = L["GTFO Alert"],
    statesParameter = "one",
    args = {
      {
        name = "alertType",
        display = L["Alert Type"],
        type = "select",
        init = "arg",
        values = "gtfo_types",
        store = true,
        conditionType = "select"
      },
    },
    timedrequired = true
  },
  -- DBM events
  ["DBM Announce"] = {
    type = "event",
    events = {},
    internal_events = {
      "DBM_Announce"
    },
    name = L["DBM Announce"],
    init = function(trigger)
      WeakAuras.RegisterDBMCallback("DBM_Announce");
      local ret = "local use_cloneId = %s;"
      return ret:format(trigger.use_cloneId and "true" or "false");
    end,
    statesParameter = "all",
    canHaveAuto = true,
    args = {
      {
        name = "message",
        init = "arg",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "name",
        init = "message",
        hidden = true,
        test = "true",
        store = true,
      },
      {
        name = "icon",
        init = "arg",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''"
      },
    },
    timedrequired = true
  },
  ["DBM Timer"] = {
    type = "status",
    events = {},
    internal_events = {
      "DBM_TimerStart", "DBM_TimerStop", "DBM_TimerStopAll", "DBM_TimerUpdate", "DBM_TimerForce"
    },
    force_events = "DBM_TimerForce",
    name = L["DBM Timer"],
    canHaveAuto = true,
    canHaveDuration = "timed",
    triggerFunction = function(trigger)
      WeakAuras.RegisterDBMCallback("DBM_TimerStart")
      WeakAuras.RegisterDBMCallback("DBM_TimerStop")
      WeakAuras.RegisterDBMCallback("DBM_TimerUpdate")
      WeakAuras.RegisterDBMCallback("wipe")
      WeakAuras.RegisterDBMCallback("kill")

      local ret = [=[
        return function (states, event, id)
          local triggerId = %q
          local triggerSpellId = %q
          local triggerText = %q
          local triggerTextOperator = %q
          local useClone = %s
          local extendTimer = %s
          local triggerUseRemaining = %s
          local triggerRemaining = %s
          local triggerCount = %q
          local triggerDbmType = %s
          local cloneId = useClone and id or ""
          local state = states[cloneId]

          function copyOrSchedule(bar, cloneId)
            if triggerUseRemaining then
              local remainingTime = bar.expirationTime - GetTime() + extendTimer
              if remainingTime %s triggerRemaining then
                WeakAuras.CopyBarToState(bar, states, cloneId, extendTimer)
              else
                local state = states[cloneId]
                if state and state.show then
                  state.show = false
                  state.changed = true
                end
              end
              if remainingTime >= triggerRemaining then
                WeakAuras.ScheduleDbmCheck(bar.expirationTime - triggerRemaining + extendTimer)
              end
            else
              WeakAuras.CopyBarToState(bar, states, cloneId, extendTimer)
            end
          end

          if useClone then
            if event == "DBM_TimerStart" then
              if WeakAuras.DBMTimerMatches(id, triggerId, triggerText, triggerTextOperator, triggerSpellId, triggerDbmType, triggerCount) then
                local bar = WeakAuras.GetDBMTimerById(id)
                if bar then
                  copyOrSchedule(bar, cloneId)
                end
              end
            elseif event == "DBM_TimerStop" and state then
              local bar_remainingTime = GetTime() - state.expirationTime + (state.extend or 0)
              if state.extend == 0 or bar_remainingTime > 0.2 then
                state.show = false
                state.changed = true
              end
            elseif event == "DBM_TimerUpdate" then
              for id, bar in pairs(WeakAuras.GetAllDBMTimers()) do
                if WeakAuras.DBMTimerMatches(id, triggerId, triggerText, triggerTextOperator, triggerSpellId, triggerDbmType, triggerCount) then
                  copyOrSchedule(bar, id)
                else
                  local state = states[id]
                  if state then
                    local bar_remainingTime = GetTime() - state.expirationTime + (state.extend or 0)
                    if state.extend == 0 or bar_remainingTime > 0.2 then
                      state.show = false
                      state.changed = true
                    end
                  end
                end
              end
            elseif event == "DBM_TimerForce" then
              wipe(states)
              for id, bar in pairs(WeakAuras.GetAllDBMTimers()) do
                if WeakAuras.DBMTimerMatches(id, triggerId, triggerText, triggerTextOperator, triggerSpellId, triggerDbmType, triggerCount) then
                  copyOrSchedule(bar, cloneId)
                end
              end
            end
          else
            if event == "DBM_TimerStart" or event == "DBM_TimerUpdate" then
              if extendTimer ~= 0 then
                if WeakAuras.DBMTimerMatches(id, triggerId, triggerText, triggerTextOperator, triggerSpellId, triggerDbmType, triggerCount) then
                  local bar = WeakAuras.GetDBMTimerById(id)
                  WeakAuras.ScheduleDbmCheck(bar.expirationTime + extendTimer)
                end
              end
            end
            local bar = WeakAuras.GetDBMTimer(triggerId, triggerText, triggerTextOperator, triggerSpellId, extendTimer, triggerDbmType, triggerCount)
            if bar then
              if extendTimer == 0
                or not (state and state.show)
                or (state and state.show and state.expirationTime > (bar.expirationTime + extendTimer))
              then
                copyOrSchedule(bar, cloneId)
              end
            else
              if state and state.show then
                local bar_remainingTime = GetTime() - state.expirationTime + (state.extend or 0)
                if state.extend == 0 or bar_remainingTime > 0.2 then
                  state.show = false
                  state.changed = true
                end
              end
            end
          end
          return true
        end
        ]=]

      return ret:format(
        trigger.use_id and trigger.id or "",
        trigger.use_spellId and trigger.spellId or "",
        trigger.use_message and trigger.message or "",
        trigger.use_message and trigger.message_operator or "",
        trigger.use_cloneId and "true" or "false",
        trigger.use_extend and tonumber(trigger.extend or 0) or 0,
        trigger.use_remaining and "true" or "false",
        trigger.remaining or 0,
        trigger.use_count and trigger.count or "",
        trigger.use_dbmType and trigger.dbmType or "nil",
        trigger.remaining_operator or "<"
      )
    end,
    statesParameter = "full",
    args = {
      {
        name = "id",
        display = L["Timer Id"],
        type = "string",
      },
      {
        name = "spellId",
        display = L["Spell Id"],
        type = "string",
        store = true,
        conditionType = "string"
      },
      {
        name = "message",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
      },
      {
        name = "extend",
        display = L["Offset Timer"],
        type = "string",
      },
      {
        name = "count",
        display = L["Count"],
        desc = L["Only if DBM shows it on it's bar"],
        type = "string",
        conditionType = "string",
      },
      {
        name = "dbmType",
        display = L["Type"],
        type = "select",
        values = "dbm_types",
        conditionType = "select",
        test = "true"
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle"
      }
    },
    automaticrequired = true,
    automaticAutoHide = false
  },
  -- BigWigs
  ["BigWigs Message"] = {
    type = "event",
    events = {},
    internal_events = {
      "BigWigs_Message"
    },
    name = L["BigWigs Message"],
    init = function(trigger)
      WeakAuras.RegisterBigWigsCallback("BigWigs_Message");
      local ret = "local use_cloneId = %s;"
      return ret:format(trigger.use_cloneId and "true" or "false");
    end,
    statesParameter = "all",
    canHaveAuto = true,
    args = {
      {
        name = "addon",
        init = "arg",
        display = L["BigWigs Addon"],
        type = "string"
      },
      {
        name = "spellId",
        init = "arg",
        display = L["Spell Id"],
        type = "longstring"
      },
      {
        name = "text",
        init = "arg",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "name",
        init = "text",
        hidden = true,
        test = "true",
        store = true
      },
      {}, -- Importance, might be useful
      {
        name = "icon",
        init = "arg",
        hidden = true,
        test = "true",
        store = true
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''"
      },
    },
    timedrequired = true
  },
  ["BigWigs Timer"] = {
    type = "status",
    events = {},
    internal_events = {
      "BigWigs_StartBar", "BigWigs_StopBar", "BigWigs_Timer_Update",
    },
    force_events = "BigWigs_Timer_Force",
    name = L["BigWigs Timer"],
    canHaveAuto = true,
    canHaveDuration = "timed",
    triggerFunction = function(trigger)
      WeakAuras.RegisterBigWigsTimer()
      local ret = [=[
        return function(states, event, id)
          local triggerSpellId = %q
          local triggerText = %q
          local triggerTextOperator = %q
          local useClone = %s
          local extendTimer = %s
          local triggerUseRemaining = %s
          local triggerRemaining = %s
          local triggerEmphasized = %s
          local triggerCount = %q
          local triggerCast = %s
          local cloneId = useClone and id or ""
          local state = states[cloneId]

          function copyOrSchedule(bar, cloneId)
            if triggerUseRemaining then
              local remainingTime = bar.expirationTime - GetTime() + extendTimer
              if remainingTime %s triggerRemaining then
                WeakAuras.CopyBigWigsTimerToState(bar, states, cloneId, extendTimer)
              else
                local state = states[cloneId]
                if state and state.show then
                  state.show = false
                  state.changed = true
                end
              end
              if remainingTime >= triggerRemaining then
                WeakAuras.ScheduleBigWigsCheck(bar.expirationTime - triggerRemaining + extendTimer)
              end
            else
              WeakAuras.CopyBigWigsTimerToState(bar, states, cloneId, extendTimer)
            end
          end

          if useClone then
            if event == "BigWigs_StartBar" then
              if WeakAuras.BigWigsTimerMatches(id, triggerText, triggerTextOperator, triggerSpellId, triggerEmphasized, triggerCount, triggerCast) then
                local bar = WeakAuras.GetBigWigsTimerById(id)
                if bar then
                  copyOrSchedule(bar, cloneId)
                end
              end
            elseif event == "BigWigs_StopBar" and state then
              local bar_remainingTime = GetTime() - state.expirationTime + (state.extend or 0)
              if state.extend == 0 or bar_remainingTime > 0.2 then
                state.show = false
                state.changed = true
              end
            elseif event == "BigWigs_Timer_Update" then
              for id, bar in pairs(WeakAuras.GetAllBigWigsTimers()) do
                if WeakAuras.BigWigsTimerMatches(id, triggerText, triggerTextOperator, triggerSpellId, triggerEmphasized, triggerCount, triggerCast) then
                  copyOrSchedule(bar, id)
                end
              end
            elseif event == "BigWigs_Timer_Force" then
              wipe(states)
              for id, bar in pairs(WeakAuras.GetAllBigWigsTimers()) do
                if WeakAuras.BigWigsTimerMatches(id, triggerText, triggerTextOperator, triggerSpellId, triggerEmphasized, triggerCount, triggerCast) then
                  copyOrSchedule(bar, id)
                end
              end
            end
          else
            if event == "BigWigs_StartBar" then
              if extendTimer ~= 0 then
                if WeakAuras.BigWigsTimerMatches(id, triggerText, triggerTextOperator, triggerSpellId, triggerEmphasized, triggerCount, triggerCast) then
                  local bar = WeakAuras.GetBigWigsTimerById(id)
                  WeakAuras.ScheduleBigWigsCheck(bar.expirationTime + extendTimer)
                end
              end
            end
            local bar = WeakAuras.GetBigWigsTimer(triggerText, triggerTextOperator, triggerSpellId, extendTimer, triggerEmphasized, triggerCount, triggerCast)
            if bar then
              if extendTimer == 0
                or not (state and state.show)
                or (state and state.show and state.expirationTime > (bar.expirationTime + extendTimer))
              then
                copyOrSchedule(bar, cloneId)
              end
            else
              if state and state.show then
                local bar_remainingTime = GetTime() - state.expirationTime + (state.extend or 0)
                if state.extend == 0 or bar_remainingTime > 0.2 then
                  state.show = false
                  state.changed = true
                end
              end
            end
          end
          return true
        end
      ]=]
      return ret:format(
        trigger.use_spellId and trigger.spellId or "",
        trigger.use_text and trigger.text or "",
        trigger.use_text and trigger.text_operator or "",
        trigger.use_cloneId and "true" or "false",
        trigger.use_extend and tonumber(trigger.extend or 0) or 0,
        trigger.use_remaining and "true" or "false",
        trigger.remaining or 0,
        trigger.use_emphasized == nil and "nil" or trigger.use_emphasized and "true" or "false",
        trigger.use_count and trigger.count or "",
        trigger.use_cast == nil and "nil" or trigger.use_cast and "true" or "false",
        trigger.remaining_operator or "<"
      )
    end,
    statesParameter = "full",
    args = {
      {
        name = "spellId",
        display = L["Spell Id"],
        type = "string",
        conditionType = "string",
      },
      {
        name = "text",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
      },
      {
        name = "extend",
        display = L["Offset Timer"],
        type = "string",
      },
      {
        name = "count",
        display = L["Count"],
        desc = L["Only if BigWigs shows it on it's bar"],
        type = "string",
        conditionType = "string",
      },
      {
        name = "emphasized",
        display = L["Emphasized"],
        type = "tristate",
        desc = L["Emphasized option checked in BigWigs's spell options"],
        test = "true",
        init = "false",
        conditionType = "bool"
      },
      {
        name = "cast",
        display = L["Cast Bar"],
        desc = L["Filter messages with format <message>"],
        type = "tristate",
        test = "true",
        init = "false",
        conditionType = "bool"
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "false"
      },
    },
    automaticrequired = true,
  },
  ["Global Cooldown"] = {
    type = "status",
    events = {},
    internal_events = {
      "GCD_START",
      "GCD_CHANGE",
      "GCD_END",
      "GCD_UPDATE",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    name = L["Global Cooldown"],
    loadFunc = function(trigger)
      WeakAuras.WatchGCD();
    end,
    init = function(trigger)
      local ret = [[
        local inverse = %s;
        local onGCD = WeakAuras.GetGCDInfo();
        local hasSpellName = WeakAuras.GcdSpellName();
      ]];
      return ret:format(trigger.use_inverse and "true" or "false");
    end,
    args = {
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and onGCD == 0) or (not inverse and onGCD > 0 and hasSpellName)"
      }
    },
    durationFunc = function(trigger)
      local duration, expirationTime = WeakAuras.GetGCDInfo();
      return duration, expirationTime;
    end,
    nameFunc = function(trigger)
      local _, _, name = WeakAuras.GetGCDInfo();
      return name;
    end,
    iconFunc = function(trigger)
      local _, _, _, icon = WeakAuras.GetGCDInfo();
      return icon;
    end,
    hasSpellID = true,
    automaticrequired = true,
    automaticAutoHide = false
  },
  ["Swing Timer"] = {
    type = "status",
    events = {},
    internal_events = {
      "SWING_TIMER_START",
      "SWING_TIMER_CHANGE",
      "SWING_TIMER_END"
    },
    name = L["Swing Timer"],
    loadFunc = function(trigger)
      WeakAuras.InitSwingTimer();
    end,
    init = function(trigger)
      trigger.hand = trigger.hand or "main";
      local ret = [=[
        local inverse = %s;
        local hand = %q;
        local duration, expirationTime = WeakAuras.GetSwingTimerInfo(hand);
      ]=];
      return ret:format((trigger.use_inverse and "true" or "false"), trigger.hand);
    end,
    args = {
      {
        name = "hand",
        required = true,
        display = L["Weapon"],
        type = "select",
        values = "swing_types",
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and duration == 0) or (not inverse and duration > 0)"
      }
    },
    durationFunc = function(trigger)
      local duration, expirationTime = WeakAuras.GetSwingTimerInfo(trigger.hand);
      return duration, expirationTime;
    end,
    nameFunc = function(trigger)
      local _, _, name = WeakAuras.GetSwingTimerInfo(trigger.hand);
      return name;
    end,
    iconFunc = function(trigger)
      local _, _, _, icon = WeakAuras.GetSwingTimerInfo(trigger.hand);
      return icon;
    end,
    automaticrequired = true
  },
  ["Action Usable"] = {
    type = "status",
    events = {
      ["events"] = {
        "SPELL_UPDATE_USABLE",
        "PLAYER_TARGET_CHANGED",
        "RUNE_POWER_UPDATE",
      },
      ["unit_events"] = {
        ["player"] = { "UNIT_POWER_FREQUENT" }
      }
    },
    internal_events = {
      "SPELL_COOLDOWN_CHANGED",
    },
    force_events = "SPELL_UPDATE_USABLE",
    name = L["Action Usable"],
    statesParameter = "one",
    loadFunc = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName;
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      end
      trigger.realSpellName = spellName; -- Cache
      WeakAuras.WatchSpellCooldown(spellName);
    end,
    init = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName;
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      end
      trigger.realSpellName = spellName; -- Cache
      local ret = [=[
        local spellName = %s
        local startTime, duration = WeakAuras.GetSpellCooldown(spellName);
        local charges, _, spellCount = WeakAuras.GetSpellCharges(spellName);
        if (charges == nil) then
          charges = (duration == 0) and 1 or 0;
        end
        local ready = startTime == 0 or charges > 0
        local active = IsUsableSpell(spellName) and ready
      ]=]
      if(trigger.use_targetRequired) then
        ret = ret.."active = active and WeakAuras.IsSpellInRange(spellName or '', 'target')\n";
      end
      if(trigger.use_inverse) then
        ret = ret.."active = not active\n";
      end

      if (type(spellName) == "string") then
        spellName = "[[" .. spellName .. "]]";
      end

      return ret:format(spellName)
    end,
    args = {
      {
        name = "spellName",
        display = L["Spell"],
        required = true,
        type = "spell",
        test = "true",
        showExactOption = true,
        store = true
      },
      -- This parameter uses the IsSpellInRange API function, but it does not check spell range at all
      -- IsSpellInRange returns nil for invalid targets, 0 for out of range, 1 for in range (0 and 1 are both "positive" values)
      {
        name = "targetRequired",
        display = L["Require Valid Target"],
        type = "toggle",
        test = "true"
      },
      {
        name = "charges",
        display = L["Charges"],
        type = "number",
        enable = function(trigger) return not(trigger.use_inverse) end,
        store = true,
        conditionType = "number"
      },
      {
        name = "spellCount",
        display = L["Spell Count"],
        type = "number",
        enable = function(trigger) return not(trigger.use_inverse) end,
        store = true,
        conditionType = "number"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        reloadOptions = true
      },
      {
        name = "spellInRange",
        display = L["Spell in Range"],
        hidden = true,
        test = "true",
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (UnitExists('target') and state.spellName and WeakAuras.IsSpellInRange(state.spellName, 'target') == needle)
        end,
        conditionEvents = {
          "PLAYER_TARGET_CHANGED",
          "WA_SPELL_RANGECHECK",
        }
      },
      {
        hidden = true,
        test = "active"
      }
    },
    nameFunc = function(trigger)
      local name = GetSpellInfo(trigger.realSpellName or 0);
      if(name) then
        return name;
      end
      name = GetSpellInfo(trigger.spellName or 0);
      if (name) then
        return name;
      end
      return "Invalid";
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.realSpellName or 0);
      if (not icon) then
        icon = select(3, GetSpellInfo(trigger.spellName or 0));
      end
      return icon;
    end,
    stacksFunc = function(trigger)
      local charges, maxCharges, spellCount = WeakAuras.GetSpellCharges(trigger.realSpellName);
      if maxCharges and maxCharges > 1 then
        return charges
      elseif spellCount and spellCount > 0 then
        return spellCount
      end
    end,
    hasSpellID = true,
    automaticrequired = true
  },
  ["Talent Known"] = {
    type = "status",
    events = function()
      local events
      if WeakAuras.IsClassic() then
        events = {
          "CHARACTER_POINTS_CHANGED",
          "SPELLS_CHANGED"
        }
      else
        events = { "PLAYER_TALENT_UPDATE" }
      end
      return {
        ["events"] = events
      }
    end,
    force_events = "PLAYER_TALENT_UPDATE",
    name = L["Talent Selected"],
    init = function(trigger)
      local inverse = trigger.use_inverse;
      if (trigger.use_talent) then
        -- Single selection
        local index = trigger.talent and trigger.talent.single;
        local tier, column
        if WeakAuras.IsClassic() then
          tier = index and ceil(index / 20)
          column = index and ((index - 1) % 20 + 1)
        else
          tier = index and ceil(index / 3)
          column = index and ((index - 1) % 3 + 1)
        end

        local ret = [[
          local tier = %s;
          local column = %s;
          local active, _, activeName, activeIcon, selected, known, rank
          if WeakAuras.IsClassic() then
            _, _, _, _, rank  = GetTalentInfo(tier, column)
            active = rank > 0
          else
            _, activeName, activeIcon, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
            active = selected or known;
          end
        ]]
        if (inverse) then
          ret = ret .. [[
          active = not (active);
          ]]
        end
        return ret:format(tier or 0, column or 0)
      elseif (trigger.use_talent == false) then
        if (trigger.talent.multi) then
          local ret = [[
            local tier
            local column
            local active = false;
            local activeIcon;
            local activeName;
          ]]
          for index in pairs(trigger.talent.multi) do
            local tier, column
            if WeakAuras.IsClassic() then
              tier = index and ceil(index / 20)
              column = index and ((index - 1) % 20 + 1)
            else
              tier = index and ceil(index / 3)
              column = index and ((index - 1) % 3 + 1)
            end
            local ret2 = [[
              if (not active) then
                tier = %s
                column = %s
                if WeakAuras.IsClassic() then
                  local name, icon, _, _, rank  = GetTalentInfo(tier, column)
                  if rank > 0 then
                    active = true;
                    activeName = name;
                    activeIcon = icon;
                  end
                else
                  local _, name, icon, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
                  if (selected or known) then
                    active = true;
                    activeName = name;
                    activeIcon = icon;
                  end
                end
              end
            ]]
            ret = ret .. ret2:format(tier, column);
          end
          if (inverse) then
            ret = ret .. [[
            active = not (active);
            ]]
          end
          return ret;
        end
      end
      return "";
    end,
    args = {
      {
        name = "talent",
        display = L["Talent selected"],
        type = "multiselect",
        values = function()
          local class = select(2, UnitClass("player"));
          local spec =  not WeakAuras.IsClassic() and GetSpecialization();
          if(WeakAuras.talent_types_specific[class] and  WeakAuras.talent_types_specific[class][spec]) then
            return WeakAuras.talent_types_specific[class][spec];
          elseif WeakAuras.IsClassic() and WeakAuras.talent_types_specific[class] then
            return WeakAuras.talent_types_specific[class];
          else
            return WeakAuras.talent_types;
          end
        end,
        test = "active",
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        name = "icon",
        init = "activeIcon",
        store = "true",
        test = "true"
      },
      {
        hidden = true,
        name = "name",
        init = "activeName",
        store = "true",
        test = "true"
      },
    },
    automaticrequired = true,
    statesParameter = "one",
    canHaveAuto = true
  },
  ["Totem"] = {
    type = "status",
    events = {
      ["events"] = {
        "PLAYER_TOTEM_UPDATE",
        "PLAYER_ENTERING_WORLD"
      }
    },
    internal_events = {
      "COOLDOWN_REMAINING_CHECK",
    },
    force_events = "PLAYER_ENTERING_WORLD",
    name = L["Totem"],
    statesParameter = "full",
    canHaveAuto = true,
    canHaveDuration = "timed",
    triggerFunction = function(trigger)
      local ret = [[return
      function (states)
        local totemType = %s;
        local triggerTotemName = %s
        local clone = %s
        local inverse = %s
        local remainingCheck = %s

        local function checkActive(remaining)
          return remaining %s remainingCheck;
        end

        if (totemType) then -- Check a specific totem slot
          local _, totemName, startTime, duration, icon = GetTotemInfo(totemType);
          active = (startTime and startTime ~= 0);
          if (triggerTotemName) then
            if (triggerTotemName ~= totemName) then
              active = false;
            end
          end
          if (inverse) then
            active = not active;
            if (triggerTotemName) then
              icon = select(3, GetSpellInfo(triggerTotemName));
            end
          elseif (active and remainingCheck) then
            local expirationTime = startTime and (startTime + duration) or 0;
            local remainingTime = expirationTime - GetTime()
            if (remainingTime >= remainingCheck) then
              WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
            end
            active = checkActive(remainingTime);
          end
          states[""] = states[""] or {}
          local state = states[""];
          state.show = active;
          state.changed = true;
          if (active) then
            state.name = totemName;
            state.totemName = totemName;
            state.progressType = "timed";
            state.duration = duration;
            state.expirationTime = startTime and (startTime + duration);
            state.icon = icon;
          end
        elseif inverse then -- inverse without a specific slot
          local found = false;
          for i = 1, 5 do
            local _, totemName, startTime, duration, icon = GetTotemInfo(i);
            if ((startTime and startTime ~= 0) and triggerTotemName == totemName) then
              found = true;
            end
          end
          local cloneId = "";
          states[cloneId] = states[cloneId] or {};
          local state = states[cloneId];
          state.show = not found;
          state.changed = true;
          state.name = triggerTotemName;
          state.totemName = triggerTotemName;
          if (triggerTotemName) then
            state.icon = select(3, GetSpellInfo(triggerTotemName));
          end
        else -- check all slots
          for i = 1, 5 do
            local _, totemName, startTime, duration, icon = GetTotemInfo(i);
            active = (startTime and startTime ~= 0);
            if (triggerTotemName) then
              if (triggerTotemName ~= totemName) then
                active = false;
              end
            end
            if (active and remainingCheck) then
              local expirationTime = startTime and (startTime + duration) or 0;
              local remainingTime = expirationTime - GetTime()
              if (remainingTime >= remainingCheck) then
                WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
              end
              active = checkActive(remainingTime);
            end

            local cloneId = clone and tostring(i) or "";
            states[cloneId] = states[cloneId] or {};
            local state = states[cloneId];
            state.show = active;
            state.changed = true;
            if (active) then
              state.name = totemName;
              state.totemName = totemName;
              state.progressType = "timed";
              state.duration = duration;
              state.expirationTime = startTime and (startTime + duration);
              state.icon = icon;
            end
            if (active and not clone) then
              break;
            end
          end
        end
        return true;
      end
      ]];
      local totemName = tonumber(trigger.totemName) and GetSpellInfo(tonumber(trigger.totemName)) or trigger.totemName;
      ret = ret:format(trigger.use_totemType and tonumber(trigger.totemType) or "nil",
        trigger.use_totemName and "[[" .. (totemName or "")  .. "]]" or "nil",
        trigger.use_clones and "true" or "false",
        trigger.use_inverse and "true" or "false",
        trigger.use_remaining and trigger.remaining or "nil",
        trigger.use_remaining and trigger.remaining_operator or "<");
      return ret;
    end,
    args = {
      {
        name = "totemType",
        display = L["Totem Number"],
        type = "select",
        values = "totem_types"
      },
      {
        name = "totemName",
        display = L["Totem Name"],
        type = "string",
        conditionType = "string",
        store = true
      },
      {
        name = "clones",
        display = L["Clone per Match"],
        type = "toggle",
        test = "true",
        enable = function(trigger) return not trigger.use_totemType end,
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return not(trigger.use_inverse) end
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        enable = function(trigger) return trigger.use_totemName and not trigger.use_clones end
      }
    },
    automaticrequired = true
  },
  ["Item Count"] = {
    type = "status",
    events = {
      ["events"] = {
        "BAG_UPDATE",
        "BAG_UPDATE_COOLDOWN",
        "PLAYER_ENTERING_WORLD"
      }
    },
    internal_events = {
      "ITEM_COUNT_UPDATE",
    },
    force_events = "BAG_UPDATE",
    name = L["Item Count"],
    loadFunc = function(trigger)
      if(trigger.use_includeCharges) then
        WeakAuras.RegisterItemCountWatch();
      end
    end,
    init = function(trigger)
      --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
      trigger.itemName = trigger.itemName or 0;
      local itemName = type(trigger.itemName) == "number" and trigger.itemName or "[["..trigger.itemName.."]]";
      local ret = [[
        local count = GetItemCount(%s, %s, %s);
      ]];
      return ret:format(itemName, trigger.use_includeBank and "true" or "nil", trigger.use_includeCharges and "true" or "nil");
    end,
    args = {
      {
        name = "itemName",
        required = true,
        display = L["Item"],
        type = "item",
        test = "true"
      },
      {
        name = "includeBank",
        display = L["Include Bank"],
        type = "toggle",
        test = "true"
      },
      {
        name = "includeCharges",
        display = L["Include Charges"],
        type = "toggle",
        test = "true"
      },
      {
        name = "count",
        display = L["Item Count"],
        type = "number"
      }
    },
    durationFunc = function(trigger)
      local count = GetItemCount(trigger.itemName, trigger.use_includeBank, trigger.use_includeCharges);
      return count, 0, true;
    end,
    stacksFunc = function(trigger)
      local count = GetItemCount(trigger.itemName, trigger.use_includeBank, trigger.use_includeCharges);
      return count, 0, true;
    end,
    nameFunc = function(trigger)
      return trigger.itemName;
    end,
    iconFunc = function(trigger)
      return GetItemIcon(trigger.itemName);
    end,
    hasItemID = true,
    automaticrequired = true
  },
  ["Stance/Form/Aura"] = {
    type = "status",
    events = {
      ["events"] = {
        "UPDATE_SHAPESHIFT_FORM",
        "UPDATE_SHAPESHIFT_COOLDOWN"
      }
    },
    internal_events = { "WA_DELAYED_PLAYER_ENTERING_WORLD" },
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Stance/Form/Aura"],
    init = function(trigger)
      local inverse = trigger.use_inverse;
      local ret = [[
        local form
        local active = false
      ]]
      if trigger.use_form and trigger.form and trigger.form.single then
        -- Single selection
        ret = ret .. [[
          local trigger_form = %d
          if WeakAuras.IsClassic() then
            for i=1, GetNumShapeshiftForms() do
              local _, isActive = GetShapeshiftFormInfo(i)
              if isActive then
                form = i
                active = i == trigger_form
              end
            end
          else
            form = GetShapeshiftForm()
            active = form == trigger_form
          end
        ]]
        if inverse then
          ret = ret .. [[
            active = not active
          ]]
        end
        return ret:format(trigger.form.single)
      elseif trigger.use_form == false and trigger.form and trigger.form.multi then
        for index in pairs(trigger.form.multi) do
          local ret2 = [[
            if not active then
              local index = %d
              if WeakAuras.IsClassic() then
                local _, isActive = GetShapeshiftFormInfo(index)
                if isActive then
                  form = index
                  active = true
                end
              else
                if GetShapeshiftForm() == index then
                  form = index
                  active = true
                end
              end
            end
          ]]
          ret = ret .. ret2:format(index)
        end
        if inverse then
          ret = ret .. [[
            active = not active
          ]]
        end
        return ret
      end
    end,
    statesParameter = "one",
    args = {
      {
        name = "form",
        display = L["Form"],
        type = "multiselect",
        values = "form_types",
        test = "active",
        store = true,
        conditionType = "select"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        enable = function(trigger) return type(trigger.use_form) == "boolean" end
      },
    },
    nameFunc = function(trigger)
      local _, class = UnitClass("player");
      local name
      if(class == trigger.class) then
        local form = GetShapeshiftForm();
        if form > 0 then
          local _, name = GetShapeshiftFormInfo(form);
        else
          name = "Humanoid";
        end
        return name;
      else
        local types = WeakAuras[class:lower().."_form_types"];
        if(types) then
          return types[GetShapeshiftForm()];
        end
      end
    end,
    iconFunc = function(trigger)
      local icon = "136116"
      if WeakAuras.IsClassic() then
        for i=1, GetNumShapeshiftForms() do
          local texture, isActive = GetShapeshiftFormInfo(i)
          if isActive then
            icon = texture
          end
        end
      else
        local form = GetShapeshiftForm()
        if form and form > 0 then
          icon = GetShapeshiftFormInfo(form);
        end
      end
      return icon or "136116"
    end,
    automaticrequired = true
  },
  ["Weapon Enchant"] = {
    type = "status",
    events = {},
    internal_events = {
      "TENCH_UPDATE",
    },
    force_events = "TENCH_UPDATE",
    name = WeakAuras.IsClassic() and L["Weapon Enchant"] or L["Fishing Lure / Weapon Enchant (Old)"],
    init = function(trigger)
      WeakAuras.TenchInit();

      local ret = [[
        local triggerWeaponType = %q
        local triggerName = %q
        local triggerStack = %s
        local triggerRemaining = %s
        local triggerShowOn = %q
        local _, expirationTime, duration, name, stack, enchantID

        if triggerWeaponType == "main" then
          expirationTime, duration, name, shortenedName, _, stack, enchantID = WeakAuras.GetMHTenchInfo()
        else
          expirationTime, duration, name, shortenedName, _, stack, enchantID = WeakAuras.GetOHTenchInfo()
        end

        local remaining = expirationTime and expirationTime - GetTime()

        local nameCheck = triggerName == "" or name and triggerName == name or shortenedName and triggerName == shortenedName or tonumber(triggerName) and enchantID and tonumber(triggerName) == enchantID
        local stackCheck = not triggerStack or stack and stack %s triggerStack
        local remainingCheck = not triggerRemaining or remaining and remaining %s triggerRemaining
        local found = expirationTime and nameCheck and stackCheck and remainingCheck
      ]];

      return ret:format(trigger.weapon or "main",
      trigger.use_enchant and trigger.enchant or "",
      trigger.use_stack and tonumber(trigger.stack or 0) or "nil",
      trigger.use_remaining and tonumber(trigger.remaining or 0) or "nil",
      trigger.showOn or "showOnActive",
      trigger.stack_operator or "<",
      trigger.remaining_operator or "<")
    end,
    args = {
      {
        name = "weapon",
        display = L["Weapon"],
        type = "select",
        values = "weapon_types",
        test = "true",
        default = "main",
        required = true
      },
      {
        name = "enchant",
        display = L["Weapon Enchant"],
        desc = L["Enchant Name or ID"],
        type = "string",
        test = "true"
      },
      {
        name = "stack",
        display = L["Stack Count"],
        type = "number",
        test = "true",
        enable = WeakAuras.IsClassic(),
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        test = "true"
      },
      {
        name = "showOn",
        display = L["Show On"],
        type = "select",
        values = "weapon_enchant_types",
        test = 'true',
        default = "showOnActive",
        required = true
      },
      {
        hidden = true,
        test = "(triggerShowOn == 'showOnActive' and found) " ..
        "or (triggerShowOn == 'showOnMissing' and not found) "  ..
        "or (triggerShowOn == 'showAlways')"
      }
    },
    durationFunc = function(trigger)
      local expirationTime, duration;
      if(trigger.weapon == "main") then
        expirationTime, duration = WeakAuras.GetMHTenchInfo();
      elseif(trigger.weapon == "off") then
        expirationTime, duration = WeakAuras.GetOHTenchInfo();
      end
      if(expirationTime) then
        return duration, expirationTime;
      else
        return 0, math.huge;
      end
    end,
    nameFunc = function(trigger)
      local _, name;
      if(trigger.weapon == "main") then
        _, _, name = WeakAuras.GetMHTenchInfo();
      elseif(trigger.weapon == "off") then
        _, _, name = WeakAuras.GetOHTenchInfo();
      end
      return name;
    end,
    iconFunc = function(trigger)
      local _, icon;
      if(trigger.weapon == "main") then
        _, _, _, _, icon = WeakAuras.GetMHTenchInfo();
      elseif(trigger.weapon == "off") then
        _, _, _, _, icon = WeakAuras.GetOHTenchInfo();
      end
      return icon;
    end,
    stacksFunc = function(trigger)
      local _, charges;
      if(trigger.weapon == "main") then
        _, _, _, _, _, charges = WeakAuras.GetMHTenchInfo();
      elseif(trigger.weapon == "off") then
        _, _, _, _, _, charges = WeakAuras.GetOHTenchInfo();
      end
      return charges;
    end,
    automaticrequired = true
  },
  ["Chat Message"] = {
    type = "event",
    events = {
      ["events"] = {
        "CHAT_MSG_INSTANCE_CHAT",
        "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_BG_SYSTEM_ALLIANCE",
        "CHAT_MSG_BG_SYSTEM_HORDE",
        "CHAT_MSG_BG_SYSTEM_NEUTRAL",
        "CHAT_MSG_BN_WHISPER",
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_EMOTE",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_MONSTER_EMOTE",
        "CHAT_MSG_MONSTER_PARTY",
        "CHAT_MSG_MONSTER_SAY",
        "CHAT_MSG_MONSTER_WHISPER",
        "CHAT_MSG_MONSTER_YELL",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_BOSS_EMOTE",
        "CHAT_MSG_RAID_BOSS_WHISPER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_SAY",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_YELL",
        "CHAT_MSG_SYSTEM",
        "CHAT_MSG_TEXT_EMOTE"
      }
    },
    name = L["Chat Message"],
    init = function(trigger)
      local ret = [[
        if (event:find('LEADER')) then
          event = event:sub(1, -8);
        end
        if (event == 'CHAT_MSG_TEXT_EMOTE') then
          event = 'CHAT_MSG_EMOTE';
        end
         local use_cloneId = %s;
      ]];
      return ret:format(trigger.use_cloneId and "true" or "false");
    end,
    statesParameter = "all",
    args = {
      {
        name = "messageType",
        display = L["Message Type"],
        type = "select",
        values = "chat_message_types",
        test = "event == %q",
        control = "WeakAurasSortedDropdown"
      },
      {
        name = "message",
        display = L["Message"],
        init = "arg",
        type = "longstring",
        store = true,
        conditionType = "string",
      },
      {
        name = "sourceName",
        display = L["Source Name"],
        init = "arg",
        type = "string",
        store = true,
        conditionType = "string",
      },
      { -- language Name
      },
      { -- Channel Name
      },
      {
        name = "destName",
        display = L["Destination Name"],
        init = "arg",
        type = "string",
        store = true,
        conditionType = "string",
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''",
        reloadOptions = true
      },
    },
    timedrequired = function(trigger)
      return trigger.use_cloneId
    end
  },
  ["Ready Check"] = {
    type = "event",
    events = {
      ["events"] = {"READY_CHECK"}
    },
    name = L["Ready Check"],
    args = {},
    timedrequired = true
  },
  ["Combat Events"] = {
    type = "event",
    events = {
      ["events"] = {
        "PLAYER_REGEN_ENABLED",
        "PLAYER_REGEN_DISABLED"
      }
    },
    name = L["Entering/Leaving Combat"],
    args = {
      {
        name = "eventtype",
        required = true,
        display = L["Type"],
        type = "select",
        values = "combat_event_type",
        test = "event == %q"
      }
    },
    timedrequired = true
  },
  ["Death Knight Rune"] = {
    type = "status",
    events = {
      ["events"] = {"RUNE_POWER_UPDATE"}
    },
    internal_events = {
      "RUNE_COOLDOWN_READY",
      "RUNE_COOLDOWN_CHANGED",
      "RUNE_COOLDOWN_STARTED",
      "COOLDOWN_REMAINING_CHECK",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = "RUNE_COOLDOWN_FORCE",
    name = L["Death Knight Rune"],
    loadFunc = function(trigger)
      trigger.rune = trigger.rune or 0;
      if (trigger.use_rune) then
        WeakAuras.WatchRuneCooldown(trigger.rune);
      else
        for i = 1, 6 do
          WeakAuras.WatchRuneCooldown(i);
        end
      end
    end,
    init = function(trigger)
      trigger.rune = trigger.rune or 0;
      local ret = [[
      local rune = %s;
      local startTime, duration = WeakAuras.GetRuneCooldown(rune);
      local genericShowOn = %s

      local numRunes = 0;
      for index = 1, 6 do
        local startTime = WeakAuras.GetRuneCooldown(index);
        if startTime == 0 then
          numRunes = numRunes  + 1;
        end
      end

    ]];
      if(trigger.use_remaining and not trigger.use_inverse) then
        local ret2 = [[
        local expirationTime = startTime + duration
        local remaining = expirationTime - GetTime();
        local remainingCheck = %s;
        if(remaining >= remainingCheck and remaining > 0) then
          WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
        end
      ]];
        ret = ret..ret2:format(tonumber(trigger.remaining or 0) or 0);
      end
      return ret:format(trigger.rune, "[[" .. (trigger.genericShowOn or "") .. "]]");
    end,
    args = {
      {
        name = "rune",
        display = L["Rune"],
        type = "select",
        values = "rune_specific_types",
        test = "(genericShowOn == \"showOnReady\" and (startTime == 0)) " ..
        "or (genericShowOn == \"showOnCooldown\" and startTime > 0) "  ..
        "or (genericShowOn == \"showAlways\")",
        enable = function(trigger) return not trigger.use_runesCount end,
        reloadOptions = true
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return trigger.use_rune and not(trigger.genericShowOn == "showOnReady") end
      },
      {
        name = "genericShowOn",
        display =  L["Show"],
        type = "select",
        values = "cooldown_progress_behavior_types",
        test = "true",
        enable = function(trigger) return trigger.use_rune end
      },
      {
        name = "runesCount",
        display = L["Runes Count"],
        type = "number",
        init = "numRunes",
        enable = function(trigger) return not trigger.use_rune end
      },
      {
        hidden = true,
        name = "onCooldown",
        test = "true",
        display = L["On Cooldown"],
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and (state.expirationTime and state.expirationTime > GetTime()) == (needle == 1)
        end,
        enable = function(trigger) return trigger.use_rune end
      },
    },
    durationFunc = function(trigger)
      if trigger.use_rune then
        local startTime, duration
        if not(trigger.use_inverse) then
          startTime, duration = WeakAuras.GetRuneCooldown(trigger.rune);
        end

        startTime = startTime or 0;
        duration = duration or 0;

        return duration, startTime + duration;
      else
        local numRunes = 0;
        for index = 1, 6 do
          local startTime = GetRuneCooldown(index);
          if startTime == 0 then
            numRunes = numRunes  + 1;
          end
        end
        return numRunes, 6, true;
      end
    end,
    stacksFunc = function(trigger)
      local numRunes = 0;
      for index = 1, 6 do
        local startTime = select(1, GetRuneCooldown(index));
        if startTime == 0 then
          numRunes = numRunes  + 1;
        end
      end
      return numRunes;
    end,
    iconFunc = function(trigger)
      return "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune";
    end,
    automaticrequired = true,
  },
  ["Item Equipped"] = {
    type = "status",
    events = {
      ["events"] = {
        "UNIT_INVENTORY_CHANGED",
        "PLAYER_EQUIPMENT_CHANGED",
      }
    },
    internal_events = { "WA_DELAYED_PLAYER_ENTERING_WORLD", },
    force_events = "UNIT_INVENTORY_CHANGED",
    name = L["Item Equipped"],
    init = function(trigger)
      --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
      trigger.itemName = trigger.itemName or 0;
      local itemName = type(trigger.itemName) == "number" and trigger.itemName or "[[" .. trigger.itemName .. "]]";

      local ret = [[
        local inverse = %s;
        local equipped = IsEquippedItem(%s);
      ]];

      return ret:format(trigger.use_inverse and "true" or "false", itemName);
    end,
    args = {
      {
        name = "itemName",
        display = L["Item"],
        type = "item",
        required = true,
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and not equipped) or (equipped and not inverse)"
      }
    },
    nameFunc = function(trigger)
      if not trigger.use_inverse then
        local name = GetItemInfo(trigger.itemName);
        return name;
      else
        return nil;
      end
    end,
    iconFunc = function(trigger)
      if not trigger.use_inverse then
        local _, _, _, _, icon = GetItemInfoInstant(trigger.itemName or 0);
        return icon;
      else
        return nil;
      end
    end,
    hasItemID = true,
    automaticrequired = true
  },
  ["Item Set"] = {
    type = "status",
    events = {
      ["events"] = {"PLAYER_EQUIPMENT_CHANGED"}
    },
    force_events = "PLAYER_EQUIPMENT_CHANGED",
    name = L["Item Set Equipped"],
    automaticrequired = true,
    init = function(trigger)
      return string.format("local setid = %s;\n", trigger.itemSetId and tonumber(trigger.itemSetId) or "0");
    end,
    statesParameter = "one",
    args = {
      {
        name = "itemSetId",
        display = L["Item Set Id"],
        type = "string",
        test = "true",
        store = "true",
        required = true,
        validate = WeakAuras.ValidateNumeric,
        desc = function()
          if not WeakAuras.IsClassic() then
            local classFilter, specFilter = C_LootJournal.GetClassAndSpecFilters();
            local currentClass = select(3, UnitClass("player"));
            local specID = GetSpecializationInfo(GetSpecialization());

            C_LootJournal.SetClassAndSpecFilters(currentClass, specID);
            local sets = C_LootJournal.GetFilteredItemSets();
            C_LootJournal.SetClassAndSpecFilters(classFilter, specFilter);

            local description = "";
            for index, set in ipairs(sets) do
              description = description .. set.name .. ": " .. set.setID .. "\n";
            end

            description = description .. "\n" .. L["Older set IDs can be found on websites such as wowhead.com/item-sets"];

            return description;
          else
            return L["Set IDs can be found on websites such as classic.wowhead.com/item-sets"]
          end
        end
      },
      {
        name = "equipped",
        display = L["Equipped"],
        type = "number",
        init = "WeakAuras.GetNumSetItemsEquipped(setid)",
        store = true,
        required = true,
        conditionType = "number"
      }
    },
    durationFunc = function(trigger)
      return WeakAuras.GetNumSetItemsEquipped(trigger.itemSetId and tonumber(trigger.itemSetId) or 0)
    end,
    nameFunc = function(trigger)
      return select(3, WeakAuras.GetNumSetItemsEquipped(trigger.itemSetId and tonumber(trigger.itemSetId) or 0));
    end
  },
  ["Equipment Set"] = {
    type = "status",
    events = {
      ["events"] = {
        "PLAYER_EQUIPMENT_CHANGED",
        "WEAR_EQUIPMENT_SET",
        "EQUIPMENT_SETS_CHANGED",
        "EQUIPMENT_SWAP_FINISHED",
      }
    },
    internal_events = {"WA_DELAYED_PLAYER_ENTERING_WORLD"},
    force_events = "PLAYER_EQUIPMENT_CHANGED",
    name = L["Equipment Set Equipped"],
    init = function(trigger)
      trigger.itemSetName = trigger.itemSetName or "";
      local itemSetName = type(trigger.itemSetName) == "string" and ("[=[" .. trigger.itemSetName .. "]=]") or "nil";

      local ret = [[
        local useItemSetName = %s;
        local triggerItemSetName = %s;
        local inverse = %s;
        local partial = %s;

      ]];

      return ret:format(trigger.use_itemSetName and "true" or "false", itemSetName, trigger.use_inverse and "true" or "false", trigger.use_partial and "true" or "false");
    end,
    statesParameter = "one",
    args = {
      {
        name = "itemSetName",
        display = L["Equipment Set"],
        type = "string",
        test = "true",
        store = true,
        conditionType = "string",
        init = "WeakAuras.GetEquipmentSetInfo(useItemSetName and triggerItemSetName or nil, partial)"
      },
      {
        name = "partial",
        display = L["Allow partial matches"],
        type = "toggle",
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "(inverse and itemSetName == nil) or (not inverse and itemSetName)"
      }
    },
    nameFunc = function(trigger)
      return WeakAuras.GetEquipmentSetInfo(trigger.use_itemSetName and trigger.itemSetName or nil, trigger.use_partial);
    end,
    iconFunc = function(trigger)
      local _, icon = WeakAuras.GetEquipmentSetInfo(trigger.use_itemSetName and trigger.itemSetName or nil, trigger.use_partial);
      return icon;
    end,
    durationFunc = function(trigger)
      local _, _, numEquipped, numItems = WeakAuras.GetEquipmentSetInfo(trigger.use_itemSetName and trigger.itemSetName or nil, trigger.use_partial);
      return numEquipped, numItems, true;
    end,
    hasItemID = true,
    automaticrequired = true
  },
  ["Threat Situation"] = {
    type = "status",
    events = {
      ["unit_events"] = {
        ["player"] = {"UNIT_THREAT_SITUATION_UPDATE"}
      }
    },
    internal_events = function(trigger)
      local result = {}
      AddUnitChangeInternalEvents(trigger.unit, result)
      return result
    end,
    force_events = "UNIT_THREAT_SITUATION_UPDATE",
    name = L["Threat Situation"],
    init = function(trigger)
      local ret = [[
        local status = UnitThreatSituation('player', %s) or -1;
        local aggro = status == 2 or status == 3;
      ]];

      return ret:format(trigger.threatUnit and trigger.threatUnit ~= "none" and "[["..trigger.threatUnit.."]]" or "nil");
    end,
    args = {
      {
        name = "threatUnit",
        display = L["Unit"],
        required = true,
        type = "unit",
        values = "threat_unit_types",
        test = "true",
        default = "target"
      },
      {
        name = "status",
        display = L["Status"],
        type = "select",
        values = "unit_threat_situation_types"
      },
      {
        name = "aggro",
        display = L["Aggro"],
        type = "tristate"
      },
      {
        hidden = true,
        test = "status ~= -1"
      },
    },
    automaticrequired = true
  },
  ["Crowd Controlled"] = {
    type = "status",
    events = {
      ["unit_events"] = {
        ["player"] = {"UNIT_AURA"}
      }
    },
    force_events = "UNIT_AURA",
    name = L["Crowd Controlled"],
    args = {
      {
        name = "controlled",
        display = L["Crowd Controlled"],
        type = "tristate",
        init = "not HasFullControl()"
      }
    },
    automaticrequired = true
  },
  ["Cast"] = {
    type = "status",
    events = function(trigger)
      local result = {}
      if trigger.unit == "nameplate" then
        AddUnitEventForEvents(result, trigger.unit, "NAME_PLATE_UNIT_ADDED")
        AddUnitEventForEvents(result, trigger.unit, "NAME_PLATE_UNIT_REMOVED")
      end
      if not (WeakAuras.IsClassic() and trigger.unit ~= "player") then
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_CHANNEL_START")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_START")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_STOP")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_DELAYED")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_CHANNEL_UPDATE")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_INTERRUPTIBLE")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_CHANNEL_STOP")
        AddUnitEventForEvents(result, trigger.unit, "UNIT_SPELLCAST_INTERRUPTED")
      else
        LibClassicCasterino:RegisterCallback("PLAYER_TARGET_CHANGED", WeakAuras.ScanEvents)
        LibClassicCasterino:RegisterCallback("UNIT_SPELLCAST_START", WeakAuras.ScanEvents)
        LibClassicCasterino:RegisterCallback("UNIT_SPELLCAST_STOP", WeakAuras.ScanEvents)
        LibClassicCasterino:RegisterCallback("UNIT_SPELLCAST_FAILED", WeakAuras.ScanEvents)
        LibClassicCasterino:RegisterCallback("UNIT_SPELLCAST_CHANNEL_START", WeakAuras.ScanEvents)
        LibClassicCasterino:RegisterCallback("UNIT_SPELLCAST_CHANNEL_STOP", WeakAuras.ScanEvents)
        LibClassicCasterino:RegisterCallback("UNIT_SPELLCAST_INTERRUPTED", WeakAuras.ScanEvents)
      end
      AddUnitEventForEvents(result, trigger.unit, "UNIT_TARGET")
      if trigger.use_destUnit and trigger.destUnit and trigger.destUnit ~= "" then
        AddUnitEventForEvents(result, trigger.destUnit, "UNIT_TARGET")
      end
      AddUnitChangeEvents(trigger.unit, result)
      return result
    end,
    internal_events = function(trigger)
      local result = {"CAST_REMAINING_CHECK", "WA_DELAYED_PLAYER_ENTERING_WORLD"}
      if WeakAuras.IsClassic() and trigger.unit ~= "player" then
        tinsert(result, "PLAYER_TARGET_CHANGED")
        tinsert(result, "UNIT_SPELLCAST_START")
        tinsert(result, "UNIT_SPELLCAST_DELAYED")
        tinsert(result, "UNIT_SPELLCAST_CHANNEL_START")
      end
      AddUnitChangeInternalEvents(trigger.unit, result)
      return result
    end,
    force_events = {"CAST_REMAINING_CHECK", "WA_DELAYED_PLAYER_ENTERING_WORLD"},
    canHaveAuto = true,
    canHaveDuration = "timed",
    name = L["Cast"],
    triggerFunction = function(trigger)
      local ret = [=[
        return function(states, event, sourceUnit)
          local trigger_inverse = %s
          local trigger_unit = %q
          local trigger_spellName = %q
          local trigger_spellId = %q
          local trigger_interruptible = %s
          local trigger_castType = %q
          local remainingCheck = %s
          local trigger_target = %q
          local trigger_clone = %s
          local localizedSpellName = %q
          local cloneId = ""

          local multi_unit = WeakAuras.multiUnitId[trigger_unit] and true or false
          if multi_unit and trigger_clone and sourceUnit and UnitExists(sourceUnit) then
            cloneId = UnitGUID(sourceUnit)
          end
          if event == "PLAYER_TARGET_CHANGED"
          or event == "PLAYER_FOCUS_CHANGED"
          or (event == "WA_DELAYED_PLAYER_ENTERING_WORLD" and trigger_inverse)
          then
            sourceUnit = trigger_unit
          end
          local destUnit = sourceUnit and sourceUnit .. "-target"
          local sourceGUID = sourceUnit and UnitGUID(sourceUnit)

          if sourceUnit and UnitExists(sourceUnit) and (multi_unit or UnitIsUnit(sourceUnit, trigger_unit)) then
            local show, expirationTime, castType, spell, icon, startTime, endTime, interruptible, spellId, remaining

            if event == "UNIT_SPELLCAST_STOP"
            or event == "UNIT_SPELLCAST_CHANNEL_STOP"
            or event == "UNIT_SPELLCAST_INTERRUPTED"
            or event == "NAME_PLATE_UNIT_REMOVED"
            then
              show = false
            else
              spell, _, icon, startTime, endTime, _, _, interruptible, spellId = WeakAuras.UnitCastingInfo(sourceUnit)
              if spell then
                castType = "cast"
              else
                spell, _, icon, startTime, endTime, _, interruptible, spellId = WeakAuras.UnitChannelInfo(sourceUnit)
                if spell then
                  castType = "channel"
                end
              end
              interruptible = not interruptible
              expirationTime = endTime and endTime > 0 and (endTime / 1000) or 0
              remaining = expirationTime - GetTime()
              if not spell
              or trigger_spellId ~= "" and GetSpellInfo(trigger_spellId) ~= spell
              or trigger_spellName ~= "" and trigger_spellName ~= spell
              or trigger_castType  ~= "" and trigger_castType ~= castType
              or trigger_interruptible ~= nil and trigger_interruptible ~= interruptible
              or trigger_target ~= "" and not UnitIsUnit(trigger_target, destUnit)
              or remainingCheck and not (remaining %s remainingCheck)
              then
                show = false
              else
                show = true
              end
              if remainingCheck and remaining >= remainingCheck and remaining > 0 then
                WeakAuras.ScheduleCastCheck(expirationTime - remainingCheck, sourceUnit)
              end
            end
            if (show and not trigger_inverse) or (not show and trigger_inverse) then
              states[cloneId] = {
                name = trigger_inverse and localizedSpellName or spell,
                icon = trigger_inverse and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon" or icon,
                duration = trigger_inverse and 0 or (endTime - startTime)/1000,
                expirationTime = trigger_inverse and math.huge or expirationTime,
                progressType = "timed",
                autoHide = true,
                interruptible = interruptible,
                unit = sourceUnit,
                sourceUnit = sourceUnit,
                sourceName = sourceUnit and UnitName(sourceUnit) or "",
                sourceGUID = sourceGUID,
                destUnit = UnitExists(destUnit) and destUnit,
                destName = UnitExists(destUnit) and UnitName(destUnit) or "",
                spellId = spellId or 0,
                spell = spell,
                castType = castType,
                show = true,
                changed = true,
                inverse = castType == "cast",
              }
              local duration = trigger_inverse and 0 or (endTime - startTime)/1000
              local expirationTime = trigger_inverse and math.huge or expirationTime
            else
              local state = states[cloneId]
              if state and state.show
              and (
                not multi_unit
                or (multi_unit and state.sourceGUID == sourceGUID)
              )
              then
                state.show = false
                state.changed = true
              end
            end
          else
            if sourceUnit == trigger_unit and not UnitExists(trigger_unit) then
              local state = states[cloneId]
              if state and state.show then
                state.show = false
                state.changed = true
              end
            end
          end
          return true
        end
      ]=]
      ret = ret:format(
        trigger.use_inverse and "true" or "false",
        trigger.unit or "",
        trigger.use_spell and trigger.spell or "",
        trigger.use_spellId and trigger.spellId or "",
        trigger.use_interruptible and "true" or trigger.use_interruptible == false and "false" or "nil",
        trigger.use_castType and trigger.castType or "",
        trigger.use_remaining and tonumber(trigger.remaining or 0) or "nil",
        trigger.use_destUnit and trigger.destUnit or "",
        trigger.use_clone and "true" or "false",
        L["Spell Name"],
        trigger.remaining_operator or "<"
      )
      return ret
    end,
    statesParameter = "full",
    args = {
      {
        name = "unit",
        display = L["Unit"],
        type = "unit",
        values = function(trigger)
          if trigger.use_inverse then
            return WeakAuras.actual_unit_types_with_specific
          else
            return WeakAuras.actual_unit_types_cast
          end
        end,
        required = true,
      },
      {
        name = "spell",
        display = L["Spell Name"],
        type = "string",
        enable = function(trigger) return not trigger.use_inverse end,
        conditionType = "string",
      },
      {
        name = "spellId",
        display = L["Spell Id"],
        type = "spell",
        enable = function(trigger) return not trigger.use_inverse end,
        conditionType = "number",
        forceExactOption = true,
      },
      {
        name = "castType",
        display = L["Cast Type"],
        type = "select",
        values = "cast_types",
        enable = function(trigger) return not trigger.use_inverse end,
        store = true,
        conditionType = "select"
      },
      {
        name = "interruptible",
        display = L["Interruptible"],
        type = "tristate",
        enable = function(trigger) return not trigger.use_inverse end,
        store = true,
        conditionType = "bool"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return not trigger.use_inverse end,
      },
      {
        name = "sourceUnit",
        display = L["Caster"],
        type = "unit",
        values = "actual_unit_types_with_specific",
        conditionType = "unit",
        conditionTest = function(state, unit, op)
          return state and state.show and (UnitIsUnit(state.sourceUnit, unit) == (op == "=="))
        end,
        store = true,
        hidden = true,
        enable = function(trigger) return not trigger.use_inverse end
      },
      {
        name = "sourceName",
        display = L["Caster Name"],
        store = true,
        hidden = true
      },
      {
        name = "destUnit",
        display = L["Caster's Target "],
        type = "unit",
        values = "actual_unit_types_with_specific",
        conditionType = "unit",
        conditionTest = function(state, unit, op)
          return state and state.show and state.destUnit and (UnitIsUnit(state.destUnit, unit) == (op == "=="))
        end,
        store = true,
        test = "true",
        enable = function(trigger) return not trigger.use_inverse end
      },
      {
        name = "destName",
        display = L["Name of Caster's Target"],
        store = true,
        hidden = true
      },
      {
        name = "clone",
        display = L["Auto-Clone (Show all Matches)"],
        type = "toggle",
        test = "true",
        init = "false",
        enable = function(trigger) return not trigger.use_inverse and (trigger.unit == "nameplate" or trigger.unit == "arena" or trigger.unit == "boss" or trigger.unit == "group" ) end,
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        reloadOptions = true
      }
    },
    automaticrequired = true,
  },
  ["Character Stats"] = {
    type = "status",
    name = L["Character Stats"],
    events = {
      ["events"] = {
        "COMBAT_RATING_UPDATE",
        "PLAYER_TARGET_CHANGED"
      },
      ["unit_events"] = {
        ["player"] = {"UNIT_STATS"}
      }
    },
    internal_events = {
      "WA_DELAYED_PLAYER_ENTERING_WORLD",
      "PLAYER_MOVING_UPDATE"
    },
    loadFunc = function()
      WeakAuras.WatchForPlayerMoving();
    end,
    init = function()
      local ret = [[
        local main_stat
        if not WeakAuras.IsClassic() then
          _, _, _, _, _, main_stat = GetSpecializationInfo(GetSpecialization() or 0)
        end
      ]]
      return ret;
    end,
    force_events = "CONDITIONS_CHECK",
    statesParameter = "one",
    args = {
      {
        name = "mainstat",
        display = L["Main Stat"],
        type = "number",
        init = "UnitStat('player', main_stat or 1)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "strength",
        display = L["Strength"],
        type = "number",
        init = "UnitStat('player', LE_UNIT_STAT_STRENGTH)",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "agility",
        display = L["Agility"],
        type = "number",
        init = "UnitStat('player', LE_UNIT_STAT_AGILITY)",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
     {
        name = "intellect",
        display = L["Intellect"],
        type = "number",
        init = "UnitStat('player', LE_UNIT_STAT_INTELLECT)",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "stamina",
        display = L["Stamina"],
        type = "number",
        init = "select(2, UnitStat('player', LE_UNIT_STAT_STAMINA)) * GetUnitMaxHealthModifier('player')",
        store = true,
        conditionType = "number"
      },
      {
        name = "criticalrating",
        display = L["Critical Rating"],
        type = "number",
        init = "GetCombatRating(CR_CRIT_SPELL)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "criticalpercent",
        display = L["Critical (%)"],
        type = "number",
        init = "GetCritChance()",
        store = true,
        conditionType = "number"
      },
      {
        name = "hasterating",
        display = L["Haste Rating"],
        type = "number",
        init = "GetCombatRating(CR_HASTE_SPELL)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "hastepercent",
        display = L["Haste (%)"],
        type = "number",
        init = "GetHaste()",
        store = true,
        conditionType = "number"
      },
      {
        name = "masteryrating",
        display = L["Mastery Rating"],
        type = "number",
        init = "GetCombatRating(CR_MASTERY)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "masterypercent",
        display = L["Mastery (%)"],
        type = "number",
        init = "GetMasteryEffect()",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "versatilityrating",
        display = L["Versatility Rating"],
        type = "number",
        init = "GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "versatilitypercent",
        display = L["Versatility (%)"],
        type = "number",
        init = "GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "resistanceholy",
        display = L["Holy Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 1))",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "resistancefire",
        display = L["Fire Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 2))",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "resistancenature",
        display = L["Nature Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 3))",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "resistancefrost",
        display = L["Frost Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 4))",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "resistanceshadow",
        display = L["Shadow Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 5))",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "resistancearcane",
        display = L["Arcane Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 6))",
        store = true,
        enable = WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = not WeakAuras.IsClassic()
      },
      {
        name = "leechrating",
        display = L["Leech Rating"],
        type = "number",
        init = "GetCombatRating(CR_LIFESTEAL)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "leechpercent",
        display = L["Leech (%)"],
        type = "number",
        init = "GetLifesteal()",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "movespeedrating",
        display = L["Movement Speed Rating"],
        type = "number",
        init = "GetCombatRating(CR_SPEED)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "movespeedpercent",
        display = L["Movement Speed (%)"],
        type = "number",
        init = "GetUnitSpeed('player') / 7 * 100",
        store = true,
        conditionType = "number"
      },
      {
        name = "avoidancerating",
        display = L["Avoidance Rating"],
        type = "number",
        init = "GetCombatRating(CR_AVOIDANCE)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "avoidancepercent",
        display = L["Avoidance (%)"],
        type = "number",
        init = "GetAvoidance()",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "dodgerating",
        display = L["Dodge Rating"],
        type = "number",
        init = "GetCombatRating(CR_DODGE)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "dodgepercent",
        display = L["Dodge (%)"],
        type = "number",
        init = "GetDodgeChance()",
        store = true,
        conditionType = "number"
      },
      {
        name = "parryrating",
        display = L["Parry Rating"],
        type = "number",
        init = "GetCombatRating(CR_PARRY)",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "parrypercent",
        display = L["Parry (%)"],
        type = "number",
        init = "GetParryChance()",
        store = true,
        conditionType = "number"
      },
      {
        name = "blockpercent",
        display = L["Block (%)"],
        type = "number",
        init = "GetBlockChance()",
        store = true,
        conditionType = "number"
      },
      {
        name = "blocktargetpercent",
        display = L["Block against Target (%)"],
        type = "number",
        init = "PaperDollFrame_GetArmorReductionAgainstTarget(GetShieldBlock())",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "armorrating",
        display = L["Armor Rating"],
        type = "number",
        init = "select(2, UnitArmor('player'))",
        store = true,
        conditionType = "number"
      },
      {
        name = "armorpercent",
        display = L["Armor (%)"],
        type = "number",
        init = "PaperDollFrame_GetArmorReduction(select(2, UnitArmor('player')), UnitEffectiveLevel('player'))",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "armortargetpercent",
        display = L["Armor against Target (%)"],
        type = "number",
        init = "PaperDollFrame_GetArmorReductionAgainstTarget(select(2, UnitArmor('player')))",
        store = true,
        enable = not WeakAuras.IsClassic(),
        conditionType = "number",
        hidden = WeakAuras.IsClassic()
      },
    },
    automaticrequired = true
  },
  ["Conditions"] = {
    type = "status",
    events = function(trigger, untrigger)
      local events = {}
      if trigger.use_incombat ~= nil then
        tinsert(events, "PLAYER_REGEN_ENABLED")
        tinsert(events, "PLAYER_REGEN_DISABLED")
        tinsert(events, "PLAYER_ENTERING_WORLD")
      end
      if trigger.use_pvpflagged ~= nil then
        tinsert(events, "PLAYER_FLAGS_CHANGED")
      end
      if trigger.use_alive ~= nil then
        tinsert(events, "PLAYER_DEAD")
        tinsert(events, "PLAYER_ALIVE")
        tinsert(events, "PLAYER_UNGHOST")
      end
      if trigger.use_resting ~= nil then
        tinsert(events, "PLAYER_UPDATE_RESTING")
        tinsert(events, "PLAYER_ENTERING_WORLD")
      end
      if trigger.use_mounted ~= nil then
        tinsert(events, "PLAYER_MOUNT_DISPLAY_CHANGED")
        tinsert(events, "PLAYER_ENTERING_WORLD")
      end
      local unit_events = {}
      local pet_unit_events = {}
      if not WeakAuras.IsClassic() and trigger.use_vehicle ~= nil then
        tinsert(unit_events, "UNIT_ENTERED_VEHICLE")
        tinsert(unit_events, "UNIT_EXITED_VEHICLE")
        tinsert(events, "PLAYER_ENTERING_WORLD")
      end
      if trigger.use_HasPet ~= nil then
        tinsert(pet_unit_events, "UNIT_HEALTH")
      end
      return {
        ["events"] = events,
        ["unit_events"] = {
          ["player"] = unit_events,
          ["pet"] = pet_unit_events
        }
      }
    end,
    internal_events = function(trigger, untrigger)
      local events = { "CONDITIONS_CHECK"};

      if (trigger.use_ismoving ~= nil) then
        tinsert(events, "PLAYER_MOVING_UPDATE");
      end

      if (trigger.use_HasPet ~= nil) then
        AddUnitChangeInternalEvents("pet", events)
      end

      return events;
    end,
    force_events = "CONDITIONS_CHECK",
    name = L["Conditions"],
    loadFunc = function(trigger)

      if (trigger.use_ismoving ~= nil) then
        WeakAuras.WatchForPlayerMoving();
      end
    end,
    init = function(trigger)
      return "";
    end,
    args = {
      {
        name = "alwaystrue",
        display = L["Always active trigger"],
        type = "tristate",
        init = "true"
      },
      {
        name = "incombat",
        display = L["In Combat"],
        type = "tristate",
        init = "UnitAffectingCombat('player')"
      },
      {
        name = "pvpflagged",
        display = L["PvP Flagged"],
        type = "tristate",
        init = "UnitIsPVP('player')",
        enable = not WeakAuras.IsClassic(),
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "alive",
        display = L["Alive"],
        type = "tristate",
        init = "not UnitIsDeadOrGhost('player')"
      },
      {
        name = "vehicle",
        display = L["In Vehicle"],
        type = "tristate",
        init = "not WeakAuras.IsClassic() and UnitInVehicle('player')",
        enable = not WeakAuras.IsClassic(),
        hidden = WeakAuras.IsClassic()
      },
      {
        name = "resting",
        display = L["Resting"],
        type = "tristate",
        init = "IsResting()"
      },
      {
        name = "mounted",
        display = L["Mounted"],
        type = "tristate",
        init = "IsMounted()"
      },
      {
        name = "HasPet",
        display = L["HasPet"],
        type = "tristate",
        init = "UnitExists('pet') and not UnitIsDead('pet')"
      },
      {
        name = "ismoving",
        display = L["Is Moving"],
        type = "tristate",
        init = "IsPlayerMoving()"
      }
    },
    automaticrequired = true
  },

  ["Spell Known"] = {
    type = "status",
    events = {
      ["events"] = {"SPELLS_CHANGED"},
      ["unit_events"] = {
        ["player"] = {"UNIT_PET"}
      }
    },
    internal_events = {
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = "SPELLS_CHANGED",
    name = L["Spell Known"],
    init = function(trigger)
      local spellName;
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName or "";
        local ret = [[
          local spellName = tonumber(%q);
          local usePet = %s;
        ]]
        return ret:format(spellName, trigger.use_petspell and "true" or "false");
      else
        local name = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName or "";
        local ret = [[
          local spellName = select(7, GetSpellInfo(%q));
          local usePet = %s;
        ]]
        return ret:format(name, trigger.use_petspell and "true" or "false");
      end
    end,
    args = {
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        test = "true",
        showExactOption = true,
      },
      {
        name = "petspell",
        display = L["Pet Spell"],
        type = "toggle",
        test = "true"
      },
      {
        hidden = true,
        test = "spellName and WeakAuras.IsSpellKnown(spellName, usePet)";
      }
    },
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    automaticrequired = true
  },

  ["Pet Behavior"] = {
    type = "status",
    events = function(trigger)
      local result = {};
      if (trigger.use_behavior) then
        tinsert(result, "PET_BAR_UPDATE");
      end
      if (trigger.use_petspec) then
        tinsert(result, "PET_SPECIALIZATION_CHANGED ");
      end
      return {
        ["events"] = result,
        ["unit_events"] = {
          ["player"] = {"UNIT_PET"}
        }
      };
    end,
    internal_events = {
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Pet"],
    init = function(trigger)
      local ret = "local activeIcon\n";
      if (trigger.use_behavior) then
        ret = [[
            local inverse = %s
            local check_behavior = %s
            local name, i, active
            local behavior
            local index = 1
            repeat
              name,i, _,active = GetPetActionInfo(index);
              if (active) then
                activeIcon = _G[i];
              end
              index = index + 1
              if(name == "PET_MODE_ASSIST" and active == true) then
                behavior = "assist"
              elseif(name == "PET_MODE_DEFENSIVE" and active == true) then
                behavior = "defensive"
              elseif(name == "PET_MODE_PASSIVE" and active == true) then
                behavior = "passive"
              end
            until index == 12
        ]]
        ret = ret:format(trigger.use_inverse and "true" or "false", trigger.use_behavior and ('"' .. (trigger.behavior or "") .. '"') or "nil");
      end
      if (trigger.use_petspec) then
        ret = ret .. [[
          local petspec = GetSpecialization(false, true)
          if (petspec) then
            activeIcon = select(4, GetSpecializationInfo(petspec, false, true));
          end
        ]]
      end
      return ret;
    end,
    statesParameter = "one",
    canHaveAuto = true,
    args = {
      {
        name = "behavior",
        display = L["Pet Behavior"],
        type = "select",
        values = "pet_behavior_types",
        test = "UnitExists('pet') and (not check_behavior or (inverse and check_behavior ~= behavior) or (not inverse and check_behavior == behavior))",
      },
      {
        name = "inverse",
        display = L["Inverse Pet Behavior"],
        type = "toggle",
        test = "true",
        enable = function(trigger) return trigger.use_behavior end
      },
      {
        name = "petspec",
        display = L["Pet Specialization"],
        type = "select",
        values = "pet_spec_types",
      },
      {
        hidden = true,
        name = "icon",
        init = "activeIcon",
        store = "true",
        test = "true"
      },
    },
    automaticrequired = true
  },

  ["Range Check"] = {
    type = "status",
    events = {
      ["events"] = {"FRAME_UPDATE"}
    },
    name = L["Range Check"],
    init = function(trigger)
      trigger.unit = trigger.unit or "target";
      local ret = [=[
          local unit = %q;
          local min, max = WeakAuras.GetRange(unit, true);
          min = min or 0;
          max = max or 999;
          local triggerResult = true;
      ]=]
      if (trigger.use_range) then
        trigger.range = trigger.range or 8;
        if (trigger.range_operator == "<=") then
          ret = ret .. "triggerResult = max <= " .. tostring(trigger.range) .. "\n";
        else
          ret = ret .. "triggerResult = min >= " .. tostring(trigger.range).. "\n";
        end
      end
      return ret:format(trigger.unit);
    end,
    statesParameter = "one",
    args = {
      {
        name = "note",
        type = "description",
        display = "",
        text = L["Note: This trigger type estimates the range to the hitbox of a unit. The actual range of friendly players is usually 3 yards more than the estimate."],
      },
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "unit",
        values = "actual_unit_types_with_specific",
        test = "true",
        store = true
      },
      {
        hidden = true,
        name = "minRange",
        display = L["Minimum Estimate"],
        type = "number",
        init = "min",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        name = "maxRange",
        display = L["Maximum Estimate"],
        type = "number",
        init = "max",
        store = true,
        test = "true"
      },
      {
        name = "range",
        display = L["Distance"],
        type = "number",
        operator_types_without_equal = true,
        test = "triggerResult",
        conditionType = "number",
        conditionTest = function(state, needle, needle2)
          return state and state.show and WeakAuras.CheckRange(state.unit, needle, needle2);
        end,
      },
      {
        hidden = true,
        test = "UnitExists(unit)"
      }
    },
    automaticrequired = true
  },

};

if WeakAuras.IsClassic() then
  WeakAuras.event_prototypes["Threat Situation"] = nil
  WeakAuras.event_prototypes["Death Knight Rune"] = nil
  WeakAuras.event_prototypes["Alternate Power"] = nil
  WeakAuras.event_prototypes["Equipment Set"] = nil
  WeakAuras.event_prototypes["Range Check"] = nil
  WeakAuras.event_prototypes["Spell Activation Overlay"] = nil
end

WeakAuras.dynamic_texts = {
  ["p"] = {
    func = function(state, region)
      if not state then return "" end
      if state.progressType == "static" then
        return state.value or ""
      end
      if state.progressType == "timed" then
        if not state.expirationTime or not state.duration then
          return ""
        end
        local remaining  = state.expirationTime - GetTime();
        local duration  = state.duration;

        local remainingStr     = "";
        if remaining == math.huge then
          remainingStr     = " ";
        elseif remaining > 60 then
          remainingStr     = string.format("%i:", math.floor(remaining / 60));
          remaining        = remaining % 60;
          remainingStr     = remainingStr..string.format("%02i", remaining);
        elseif remaining > 0 then
          local progressPrecision = region.progressPrecision and math.abs(region.progressPrecision) or 1
          -- remainingStr = remainingStr..string.format("%."..(data.progressPrecision or 1).."f", remaining);
          if progressPrecision == 4 and remaining <= 3 then
            remainingStr = remainingStr..string.format("%.1f", remaining);
          elseif progressPrecision == 5 and remaining <= 3 then
            remainingStr = remainingStr..string.format("%.2f", remaining);
          elseif (progressPrecision == 4 or progressPrecision == 5) and remaining > 3 then
            remainingStr = remainingStr..string.format("%d", remaining);
          else
            remainingStr = remainingStr..string.format("%.".. progressPrecision .."f", remaining);
          end
        else
          remainingStr     = " ";
        end
        return remainingStr
      end
    end
  },
  ["t"] = {
    func = function(state, region)
      if not state then return "" end
      if state.progressType == "static" then
        return state.total or ""
      end
      if state.progressType == "timed" then
        if not state.duration then
          return ""
        end
        -- Format a duration time string
        local durationStr     = "";
        local duration = state.duration
        if math.abs(duration) == math.huge or tostring(duration) == "nan" then
          durationStr = " ";
        elseif duration > 60 then
          durationStr     = string.format("%i:", math.floor(duration / 60));
          duration       = duration % 60;
          durationStr     = durationStr..string.format("%02i", duration);
        elseif duration > 0 then
          local totalPrecision = region.totalPrecision and math.abs(region.totalPrecision) or 1
          if totalPrecision == 4 and duration <= 3 then
            durationStr = durationStr..string.format("%.1f", duration);
          elseif totalPrecision == 5 and duration <= 3 then
            durationStr = durationStr..string.format("%.2f", duration);
          elseif (totalPrecision == 4 or totalPrecision == 5) and duration > 3 then
            durationStr = durationStr..string.format("%d", duration);
          else
            durationStr = durationStr..string.format("%."..totalPrecision.."f", duration);
          end
        else
          durationStr     = " ";
        end
        return durationStr
      end
    end
  },
  ["n"] = {
    func = function(state)
      if not state then return "" end
      return state.name or state.id
    end
  },
  ["i"] = {
    func = function(state)
      if not state or not state.icon then return "|TInterface\\Icons\\INV_Misc_QuestionMark:12:12:0:0:64:64:4:60:4:60|t" end
      return "|T".. state.icon ..":12:12:0:0:64:64:4:60:4:60|t"
    end
  },
  ["s"] = {
    func = function(state)
      if not state or state.stacks == 0 then return "" end
      return state.stacks
    end
  }
};
