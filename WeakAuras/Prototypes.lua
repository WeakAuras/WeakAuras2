-- Lua APIs
local tinsert = table.insert
local tostring = tostring
local select, pairs, type = select, pairs, type
local ceil, min = ceil, min

-- WoW APIs
local GetPvpTalentInfo, GetTalentInfo = GetPvpTalentInfo, GetTalentInfo
local GetNumSpecializationsForClassID, GetSpecialization = GetNumSpecializationsForClassID, GetSpecialization
local UnitClass, UnitHealth, UnitHealthMax, UnitName, UnitStagger, UnitPower, UnitPowerMax = UnitClass, UnitHealth, UnitHealthMax, UnitName, UnitStagger, UnitPower, UnitPowerMax
local UnitAlternatePowerInfo, UnitAlternatePowerTextureInfo = UnitAlternatePowerInfo, UnitAlternatePowerTextureInfo
local GetSpellInfo, GetItemInfo, GetItemCount, GetItemIcon = GetSpellInfo, GetItemInfo, GetItemCount, GetItemIcon
local GetShapeshiftFormInfo, GetShapeshiftForm = GetShapeshiftFormInfo, GetShapeshiftForm
local GetRuneCooldown, UnitCastingInfo, UnitChannelInfo = GetRuneCooldown, UnitCastingInfo, UnitChannelInfo

local WeakAuras = WeakAuras
local L = WeakAuras.L

-- luacheck: globals C_SpecializationInfo C_Map

local SpellRange = LibStub("SpellRange-1.0")
function WeakAuras.IsSpellInRange(spellId, unit)
  -- WORKAROUND https://wow.curseforge.com/projects/libspellrange-1-0/issues/2
  return SpellRange.IsSpellInRange(spellId, unit) or IsSpellInRange(spellId, unit);
end

local LibRangeCheck = LibStub("LibRangeCheck-2.0")

function WeakAuras.GetRange(unit)
  return LibRangeCheck:GetRange(unit);
end

function WeakAuras.CheckRange(unit, range, operator)
  local min, max = LibRangeCheck:GetRange(unit);
  if (operator == "<=") then
    return (max or 0) <= range;
  else
    return (min or 1000) >= range;
  end
end

WeakAuras.encounter_table = {
  [2168] = 2144, -- Taloc the Corrupted
  [2167] = 2141, -- MOTHER
  [2146] = 2128, -- Fetid Devourer
  [2169] = 2136, -- Zek'voz, Herald of N'zoth
  [2195] = 2145, -- TODO Needs checking-- Zul, Reborn
  [2194] = 2135, -- Mythrax the Unraveler
  [2166] = 2134, -- Vectis
  [2147] = 2122, -- G'huun
}

local function get_encounters_list()
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

  return encounter_list:sub(1, -3) .. L["\n\nSupports multiple entries, separated by commas\n"]
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
local classID = 1;
local _, classFileName;
while(GetClassInfo(classID)) do
  _, classFileName = GetClassInfo(classID)
  WeakAuras.class_ids[classFileName] = classID;
  classID = classID + 1;
end

function WeakAuras.CheckTalentByIndex(index)
  local tier = ceil(index / 3)
  local column = (index - 1) % 3 + 1
  local _, _, _, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
  return selected or known;
end

function WeakAuras.CheckPvpTalentByIndex(index)
  if (index <= 3) then
    local talentSlotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(1);
    local checkTalentId = talentSlotInfo.availableTalentIDs[index];
    return talentSlotInfo.selectedTalentID == checkTalentId;
  else
    local checkTalentId = C_SpecializationInfo.GetPvpTalentSlotInfo(2).availableTalentIDs[index - 3];
    for i = 2, 4 do
      local talentSlotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(i);
      if (talentSlotInfo.selectedTalentID == checkTalentId) then
        return true;
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

    -- If a single specific class was found, load the specific list for it
    if(single_class and WeakAuras.talent_types_specific[single_class]
      and single_spec and WeakAuras.talent_types_specific[single_class][single_spec]) then
      return WeakAuras.talent_types_specific[single_class][single_spec];
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
      width = "normal",
      init = "arg"
    },
    {
      name = "never",
      display = L["Never"],
      type = "toggle",
      width = "normal",
      init = "false"
    },
    {
      name = "vehicle",
      display = L["In Vehicle"],
      type = "tristate",
      init = "arg",
      width = "normal",
    },
    {
      name = "vehicleUi",
      display = L["Has Vehicle UI"],
      type = "tristate",
      init = "arg",
      width = "normal",
    },
    {
      name = "petbattle",
      display = L["In Pet Battle"],
      type = "tristate",
      init = "arg",
      width = "normal",
    },
    {
      name = "ingroup",
      display = L["In Group"],
      type = "multiselect",
      width = "normal",
      init = "arg",
      values = "group_types"
    },
    {
      name = "name",
      display = L["Player Name"],
      type = "string",
      init = "arg"
    },
    {
      name = "realm",
      display = L["Realm"],
      type = "string",
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
      init = "arg"
    },
    {
      name = "talent",
      display = L["Talent selected"],
      type = "multiselect",
      values = valuesForTalentFunction,
      test = "WeakAuras.CheckTalentByIndex(%d)"
    },
    {
      name = "talent2",
      display = L["And Talent selected"],
      type = "multiselect",
      values = valuesForTalentFunction,
      test = "WeakAuras.CheckTalentByIndex(%d)",
      enable = function(trigger)
        return trigger.use_talent ~= nil or trigger.use_talent2 ~= nil;
      end
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
      test = "WeakAuras.CheckPvpTalentByIndex(%d)"
    },
    {
      name = "spellknown",
      display = L["Spell Known"],
      type = "spell",
      test = "WeakAuras.IsSpellKnown(%s)"
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
      init = "arg"
    },
    {
      name = "zone",
      display = L["Zone Name"],
      type = "string",
      init = "arg"
    },
    {
      name = "zoneId",
      display = L["Zone ID(s)"],
      type = "string",
      init = "arg",
      desc = function()
         return L["Supports multiple entries, separated by commas\n"] .. L["Current Zone ID: "] .. C_Map.GetBestMapForUnit("player")
       end,
      test = "WeakAuras.CheckNumericIds([[%s]], zoneId)"
    },
    {
      name = "encounterid",
      display = L["Encounter ID(s)"],
      type = "string",
      init = "arg",
      desc = get_encounters_list,
      test = "WeakAuras.CheckNumericIds([[%s]], encounterid)"
    },
    {
      name = "size",
      display = L["Instance Type"],
      type = "multiselect",
      values = "instance_types",
      init = "arg",
      control = "WeakAurasSortedDropdown"
    },
    {
      name = "difficulty",
      display = L["Instance Difficulty"],
      type = "multiselect",
      values = "difficulty_types",
      init = "arg"
    },
    {
      name = "role",
      display = L["Spec Role"],
      type = "multiselect",
      values = "role_types",
      init = "arg"
    },
  }
};

local function AddUnitChangeEvents(unit, t)
  if (unit == "player") then

  elseif (unit == "target") then
    tinsert(t, "PLAYER_TARGET_CHANGED");
  elseif (unit == "focus") then
    tinsert(t, "PLAYER_FOCUS_CHANGED");
  elseif (unit == "pet") then
    tinsert(t, "UNIT_PET")
  else
    tinsert(t, "PLAYER_TARGET_CHANGED");
    tinsert(t, "PLAYER_FOCUS_CHANGED");
    tinsert(t, "UNIT_TARGET");
    tinsert(t, "INSTANCE_ENCOUNTER_ENGAGE_UNIT");
    tinsert(t, "GROUP_ROSTER_UPDATE");
  end
end

WeakAuras.event_prototypes = {
  ["Unit Characteristics"] = {
    type = "status",
    events = function(trigger)
      local result = {
        "UNIT_LEVEL",
        "UNIT_FACTION"
      };
      AddUnitChangeEvents(trigger.unit, result);
      if trigger.unitisunit then
        AddUnitChangeEvents(trigger.unitisunit, result);
      end
      return result;
    end,
    force_events = "UNIT_LEVEL",
    name = L["Unit Characteristics"],
    init = function(trigger)
      trigger.unit = trigger.unit or "target";
      local ret = [=[
        local unit = [[%s]];
        local concernedUnit = [[%s]];
        local extraUnit = [[%s]];
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
        test = "(event ~= 'UNIT_LEVEL' and event ~= 'UNIT_FACTION') or UnitIsUnit(unit, '%s' or '')"
      },
      {
        name = "unitisunit",
        display = L["Unit is Unit"],
        type = "unit",
        init = "UnitIsUnit(concernedUnit, extraUnit)",
        values = "actual_unit_types_with_specific",
        test = "unitisunit",
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
    automatic = true
  },
  ["Health"] = {
    type = "status",
    events = function(trigger)
      local result = {
        "UNIT_HEALTH_FREQUENT",
      };
      AddUnitChangeEvents(trigger.unit, result);
      if (trigger.use_showAbsorb) then
        tinsert(result, "UNIT_ABSORB_AMOUNT_CHANGED");
      end
      if (trigger.use_showIncomingHeal) then
        tinsert(result, "UNIT_HEAL_PREDICTION");
      end
      return result;
    end,
    internal_events = { "WA_UNIT_PET", "WA_DELAYED_PLAYER_ENTERING_WORLD" },
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Health"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        local unit = unit or [[%s]];
        local concernedUnit = [[%s]];
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
        test = "event ~= 'UNIT_HEALTH_FREQUENT' or UnitIsUnit(unit, '%s' or '')"
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
        reloadOptions = true
      },
      {
        name = "absorbMode",
        display = L["Absorb Display"],
        type = "select",
        test = "true",
        values = "absorb_modes",
        required = true,
        enable = function(trigger) return trigger.use_showAbsorb end
      },
      {
        name = "showIncomingHeal",
        display = L["Show Incoming Heal"],
        type = "toggle",
        test = "true",
        reloadOptions = true
      },
      {
        name = "absorb",
        type = "number",
        display = L["Absorb"],
        init = "UnitGetTotalAbsorbs(concernedUnit)",
        store = true,
        conditionType = "number",
        enable = function(trigger) return trigger.use_showAbsorb end
      },
      {
        name = "healprediction",
        type = "number",
        display = L["Incoming Heal"],
        init = "UnitGetIncomingHeals(concernedUnit)",
        store = true,
        conditionType = "number",
        enable = function(trigger) return trigger.use_showIncomingHeal end
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
          return trigger.use_showAbsorb;
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
          return trigger.use_showIncomingHeal;
        end
      }
    },
    automatic = true
  },
  ["Power"] = {
    type = "status",
    events = function(trigger)
      local result = {
        "UNIT_POWER_FREQUENT",
        "UNIT_DISPLAYPOWER"
      };
      AddUnitChangeEvents(trigger.unit, result);
      if (trigger.use_showCost) then
        tinsert(result, "UNIT_SPELLCAST_START");
        tinsert(result, "UNIT_SPELLCAST_STOP");
        tinsert(result, "UNIT_SPELLCAST_FAILED");
      end
      if (trigger.use_powertype and trigger.powertype == 99) then
        tinsert(result, "UNIT_ABSORB_AMOUNT_CHANGED");
      end
      return result;
    end,
    internal_events = { "WA_DELAYED_PLAYER_ENTERING_WORLD" },
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Power"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        local unit = unit or [[%s]];
        local concernedUnit = [[%s]];
        local powerType = %s;
        local unitPowerType = UnitPowerType(concernedUnit);
        local powerTypeToCheck = powerType or unitPowerType;
        local powerThirdArg = WeakAuras.UseUnitPowerThirdArg(powerTypeToCheck);
      ]=];
      ret = ret:format(trigger.unit, trigger.unit, trigger.use_powertype and trigger.powertype or "nil");
      if (trigger.use_powertype and trigger.powertype == 99) then
        ret = ret .. [[
        local UnitPower = UnitStagger;
        local UnitPowerMax = UnitHealthMax;
      ]]
      end
      if (trigger.use_showCost) then
        ret = ret .. [[
          if (event == "UNIT_SPELLCAST_START" and unit == "player") then
            local spellID = select(9, UnitCastingInfo("player"));
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
        test = "event ~= 'UNIT_POWER_FREQUENT' or UnitIsUnit(unit, '%s' or '')"
      },
      {
        name = "powertype",
        display = L["Power Type"],
        type = "select",
        values = "power_types_with_stagger",
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
        name = "power",
        display = L["Power"],
        type = "number",
        init = "UnitPower(concernedUnit, powerType, powerThirdArg) / WeakAuras.UnitPowerDisplayMod(powerTypeToCheck)",
        store = true,
        conditionType = "number"
      },
      {
        name = "percentpower",
        display = L["Power (%)"],
        type = "number",
        init = "(power or 0) / math.max(1, UnitPowerMax(concernedUnit, powerType, powerThirdArg)) * 100;",
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
      if (powerType == 99) then
        return UnitStagger(trigger.unit), math.max(1, UnitHealthMax(trigger.unit)), "fastUpdate";
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
      if (powerType == 99) then
        return UnitStagger(trigger.unit);
      end
      local powerTypeToCheck = trigger.powertype or UnitPowerType(trigger.unit);
      local pdm = WeakAuras.UnitPowerDisplayMod(powerTypeToCheck);
      local useThirdArg = WeakAuras.UseUnitPowerThirdArg(powerTypeToCheck)
      return UnitPower(trigger.unit, powerType, useThirdArg) / pdm;
    end,
    automatic = true
  },
  ["Alternate Power"] = {
    type = "status",
    events = function(trigger)
      local result = {
        "UNIT_POWER_FREQUENT",
      };
      AddUnitChangeEvents(trigger.unit, result);
      return result;
    end,
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Alternate Power"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        local unit = unit or [[%s]]
        local concernedUnit = [[%s]]
        local _, _, _, _, _, _, _, _, _, _, name = UnitAlternatePowerInfo([[%s]]);
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
        test = "event ~= 'UNIT_POWER_FREQUENT' or UnitIsUnit(unit, '%s' or '')"
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
    automatic = true
  },
  -- Todo: Give useful options to condition based on GUID and flag info
  ["Combat Log"] = {
    type = "event",
    events = {
      "COMBAT_LOG_EVENT_UNFILTERED"
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
        test = "(sourceGUID or '') == (UnitGUID([[%s]]) or '') and sourceGUID",
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
        name = "sourceFlags",
        display = L["Source In Group"],
        type = "select",
        values = "combatlog_flags_check_type",
        init = "arg",
        store = true,
        test = "WeakAuras.CheckCombatLogFlags(sourceFlags, '%s')",
        conditionType = "select",
        conditionTest = "state and state.show and WeakAuras.CheckCombatLogFlags(sourceFlags, '%s')",
      },
      {
        name = "sourceRaidFlags",
        display = L["Source Raid Mark"],
        type = "select",
        values = "combatlog_raid_mark_check_type",
        init = "arg",
        store = true,
        test = "WeakAuras.CheckRaidFlags(sourceRaidFlags,'%s')",
        conditionType = "select",
        conditionTest = "state and state.show and WeakAuras.CheckRaidFlags(sourceRaidFlags,'%s')",
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
        test = "(destGUID or '') == (UnitGUID([[%s]]) or '') and destGUID",
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
        test = "WeakAuras.CheckCombatLogFlags(destFlags, '%s')",
        conditionType = "select",
        conditionTest = "state and state.show and WeakAuras.CheckCombatLogFlags(destFlags, '%s')",
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
        test = "WeakAuras.CheckRaidFlags(destRaidFlags,'%s')",
        conditionType = "select",
        conditionTest = "state and state.show and WeakAuras.CheckRaidFlags(destRaidFlags,'%s')",
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
          return trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end,
        store = true,
        conditionType = "number"
      },
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
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
        end
      }, -- extraSpellId ignored with _ argument
      {
        name = "extraSpellName",
        display = L["Extra Spell Name"],
        type = "string",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
        end,
        store = true,
        conditionType = "string"
      },
      {
        enable = function(trigger)
          return trigger.subeventSuffix and (trigger.subeventSuffix == "_INTERRUPT" or trigger.subeventSuffix == "_DISPEL" or trigger.subeventSuffix == "_DISPEL_FAILED" or trigger.subeventSuffix == "_STOLEN" or trigger.subeventSuffix == "_AURA_BROKEN_SPELL")
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
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventSuffix == "_MISSED" or trigger.subeventSuffix == "_HEAL" or trigger.subeventSuffix == "_ENERGIZE" or trigger.subeventSuffix == "_DRAIN" or trigger.subeventSuffix == "_LEECH" or trigger.subeventPrefix:find("DAMAGE"))
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
        name = "multistrike",
        display = L["Multistrike"],
        type = "tristate",
        init = "arg",
        enable = function(trigger)
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT" or trigger.subeventSuffix == "_HEAL")
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
    }
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
    events = {

    },
    internal_events = function(trigger, untrigger)
      local events = {
        "SPELL_COOLDOWN_READY",
        "SPELL_COOLDOWN_CHANGED",
        "SPELL_COOLDOWN_STARTED",
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
      local spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      WeakAuras.WatchSpellCooldown(spellName, trigger.use_matchedRune);
      if (trigger.use_showgcd) then
        WeakAuras.WatchGCD();
      end
    end,
    init = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      trigger.realSpellName = spellName; -- Cache
      local ret = [=[
        local spellname = [[%s]]
        local ignoreRuneCD = %s
        local showgcd = %s;
        local startTime, duration, gcdCooldown = WeakAuras.GetSpellCooldown(spellname, ignoreRuneCD, showgcd);
        local charges, maxCharges = WeakAuras.GetSpellCharges(spellname);
        if (charges == nil) then
          charges = (duration == 0) and 1 or 0;
        end
        local showOn = %s
        local expirationTime = startTime + duration
      ]=];
      if (not trigger.trackcharge) then
        ret = ret .. [=[
          if (state.expirationTime ~= expirationTime) then
            state.expirationTime = expirationTime;
            state.resort = true;
            state.changed = true;
          end
          if (state.duration ~= duration) then
            state.duration = duration;
            state.resort = true;
            state.changed = true;
          end
          state.progressType = 'timed';
        ]=];
      else
        local ret2 = [=[
          local trackedCharge = %s
          if (charges < trackedCharge) then
            if (state.value ~= 0) then
              state.value = duration;
              state.resort = true;
              state.changed = true;
            end
            if (state.total ~= duration) then
              state.total = duration;
              state.resort = true;
              state.changed = true;
            end

            state.expirationTime = nil;
            state.duration = nil;
            state.progressType = 'static';
          elseif (charges > trackedCharge) then
            if (state.expirationTime ~= 0) then
              state.expirationTime = 0;
              state.resort = true;
              state.changed = true;
            end
            if (state.duration ~= 0) then
              state.duration = 0;
              state.resort = true;
              state.changed = true;
            end
            state.value = nil;
            state.total = nil;
            state.progressType = 'timed';
          else
            if (state.expirationTime ~= expirationTime) then
              state.expirationTime = expirationTime;
              state.changed = true;
              state.resort = true;
              state.changed = true;
            end
            if (state.duration ~= duration) then
              state.duration = duration;
              state.resort = true;
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
      if(trigger.use_remaining and trigger.showOn ~= "showOnReady") then
        local ret2 = [[
          local remaining = expirationTime > 0 and (expirationTime - GetTime()) or 0;
          local remainingCheck = %s;
          if(remaining >= remainingCheck) then
            WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining or 0) or 0);
      end
      return ret:format(spellName,
        (trigger.use_matchedRune and "true" or "false"),
        (trigger.use_showgcd and "true" or "false"),
        "[[" .. (trigger.showOn or "") .. "]]");
    end,
    statesParameter = "one",
    canHaveDuration = "timed",
    args = {
      {
      }, -- Ignore first argument (id)
      {
        name = "matchedRune",
        display = L["Ignore Rune CD"],
        type = "toggle",
        test = "true",
      },
      {
        name = "showgcd",
        display = L["Show Global Cooldown"],
        type = "toggle",
        test = "true"
      },
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        test = "true"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return (trigger.showOn ~= "showOnReady") end
      },
      {
        name = "charges",
        display = L["Show if Charges"],
        type = "number",
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
        name = "trackcharge",
        display = L["Show CD of Charge"],
        type = "number",
        enable = function(trigger) return (trigger.showOn ~= "showOnReady") end,
        test = "true",
        noOperator = true,
      },
      {
        name = "showOn",
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
        conditionTest = "(state and state.show and not state.gcdCooldown and state.expirationTime and state.expirationTime > GetTime()) == (%s == 1)",
      },
      {
        hidden = true,
        name = "gcdCooldown",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        test = "(showOn == \"showOnReady\" and (startTime == 0 or gcdCooldown)) " ..
        "or (showOn == \"showOnCooldown\" and startTime > 0 and not gcdCooldown) " ..
        "or (showOn == \"showAlways\")"
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
      return WeakAuras.GetSpellCharges(trigger.realSpellName);
    end,
    hasSpellID = true,
    automaticrequired = true,
    automaticAutoHide = false
  },
  ["Cooldown Ready (Spell)"] = {
    type = "event",
    events = {
    },
    internal_events = {
      "SPELL_COOLDOWN_READY",
    },
    name = L["Cooldown Ready (Spell)"],
    loadFunc = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      WeakAuras.WatchSpellCooldown(trigger.spellName or 0);
    end,
    init = function(trigger)
      --trigger.spellName = WeakAuras.CorrectSpellName(trigger.spellName) or 0;
      trigger.spellName = trigger.spellName or 0;
    end,
    args = {
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        init = "arg"
      }
    },
    nameFunc = function(trigger)
      local name = GetSpellInfo(trigger.spellName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    hasSpellID = true
  },
  ["Charges Changed (Spell)"] = {
    type = "event",
    events = {
    },
    internal_events = {
      "SPELL_CHARGES_CHANGED",
    },
    name = L["Charges Changed (Spell)"],
    loadFunc = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      WeakAuras.WatchSpellCooldown(trigger.spellName or 0);
    end,
    init = function(trigger)
      --trigger.spellName = WeakAuras.CorrectSpellName(trigger.spellName) or 0;
      trigger.spellName = trigger.spellName or 0;
      return "";
    end,
    statesParameter = "one",
    args = {
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        init = "arg"
      },
      {
        name = "direction",
        required = true,
        display = L["Charge gained/lost"],
        type = "select",
        values = "charges_change_type",
        init = "arg",
        test = "WeakAuras.CheckChargesDirection(direction, '%s')",
        store = true,
        conditionType = "select",
        conditionValues = "charges_change_condition_type";
        conditionTest = "state and state.show and WeakAuras.CheckChargesDirection(state.direction, '%s')",
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
      local name = GetSpellInfo(trigger.spellName or 0);
      if(name) then
        return name;
      else
        return "Invalid";
      end
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    hasSpellID = true
  },
  ["Cooldown Progress (Item)"] = {
    type = "status",
    events = {

    },
    internal_events = {
      "ITEM_COOLDOWN_READY",
      "ITEM_COOLDOWN_CHANGED",
      "ITEM_COOLDOWN_STARTED",
      "COOLDOWN_REMAINING_CHECK",
    },
    force_events = "ITEM_COOLDOWN_FORCE",
    name = L["Cooldown Progress (Item)"],
    loadFunc = function(trigger)
      trigger.itemName = trigger.itemName or 0;
      local itemName = type(trigger.itemName) == "number" and trigger.itemName or "[["..trigger.itemName.."]]";
      WeakAuras.WatchItemCooldown(trigger.itemName);
    end,
    init = function(trigger)
      --trigger.itemName = WeakAuras.CorrectItemName(trigger.itemName) or 0;
      trigger.itemName = trigger.itemName or 0;
      local itemName = type(trigger.itemName) == "number" and trigger.itemName or "[["..trigger.itemName.."]]";
      local ret = [[
        local startTime, duration = WeakAuras.GetItemCooldown(%s);
        local showOn = %s
      ]];
      if(trigger.use_remaining and trigger.showOn ~= "showOnReady") then
        local ret2 = [[
          local expirationTime = startTime + duration
          local remaining = expirationTime > 0 and (expirationTime - GetTime()) or 0;
          local remainingCheck = %s;
          if(remaining >= remainingCheck) then
            WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining or 0) or 0);
      end
      return ret:format(itemName,  "[[" .. (trigger.showOn or "") .. "]]");
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
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return (trigger.showOn ~= "showOnReady") end,
        init = "remaining"
      },
      {
        name = "showOn",
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
        conditionTest = "(state and state.show and state.expirationTime and state.expirationTime > GetTime()) == (%s == 1)",
      },
      {
        hidden = true,
        test = "(showOn == \"showOnReady\" and startTime == 0) " ..
        "or (showOn == \"showOnCooldown\" and startTime > 0) " ..
        "or (showOn == \"showAlways\")"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration = WeakAuras.GetItemCooldown(type(trigger.itemName) == "number" and trigger.itemName or 0);
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
    internal_events = {
      "ITEM_SLOT_COOLDOWN_STARTED",
      "ITEM_SLOT_COOLDOWN_CHANGED",
      "COOLDOWN_REMAINING_CHECK",
      "ITEM_SLOT_COOLDOWN_ITEM_CHANGED",
      "ITEM_SLOT_COOLDOWN_READY"
    },
    force_events = "ITEM_COOLDOWN_FORCE",
    name = L["Cooldown Progress (Equipment Slot)"],
    loadFunc = function(trigger)
      WeakAuras.WatchItemSlotCooldown(trigger.itemSlot);
    end,
    init = function(trigger)
      local ret = [[
        local startTime, duration, enable = WeakAuras.GetItemSlotCooldown(%s);
        local showOn = %s
        local remaining = startTime + duration - GetTime();
      ]];
      if(trigger.use_remaining and trigger.showOn ~= "showOnReady") then
        local ret2 = [[
          local expirationTime = startTime + duration
          local remaining = expirationTime > 0 and (expirationTime - GetTime()) or 0;
          local remainingCheck = %s;
          if(remaining >= remainingCheck) then
            WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
          end
        ]];
        ret = ret..ret2:format(tonumber(trigger.remaining or 0) or 0);
      end
      return ret:format(trigger.itemSlot or "0",  "[[" .. (trigger.showOn or "") .. "]]");
    end,
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
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return (trigger.showOn ~= "showOnReady") end,
        init = "remaining"
      },
      {
        name = "testForCooldown",
        display = L["is useable"],
        type = "toggle",
        test = "enable == 1"
      },
      {
        name = "showOn",
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
        conditionTest = "(state and state.show and state.expirationTime and state.expirationTime > GetTime()) == (%s == 1)",
      },
      {
        hidden = true,
        test = "(showOn == \"showOnReady\" and startTime == 0) " ..
        "or (showOn == \"showOnCooldown\" and startTime > 0) " ..
        "or (showOn == \"showAlways\")"
      }
    },
    durationFunc = function(trigger)
      local startTime, duration = GetInventoryItemCooldown("player", trigger.itemSlot or 0);
      startTime = startTime or 0;
      duration = duration or 0;
      return duration, startTime + duration;
    end,
    nameFunc = function(trigger)
      return "";
    end,
    iconFunc = function(trigger)
      return GetInventoryItemTexture("player", trigger.itemSlot or 0) or "Interface\\Icons\\INV_Misc_QuestionMark";
    end,
    automaticrequired = true,
    automaticAutoHide = false
  },
  ["Cooldown Ready (Item)"] = {
    type = "event",
    events = {
          },
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
    hasItemID = true
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
    hasItemID = true
  },
  ["GTFO"] = {
    type = "event",
    events = {
      "GTFO_DISPLAY"
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
  },
  -- DBM events
  ["DBM Announce"] = {
    type = "event",
    events = {
    },
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
    }
  },
  ["DBM Timer"] = {
    type = "status",
    events = {

    },
    internal_events = {
      "DBM_TimerStart", "DBM_TimerStop", "DBM_TimerStopAll", "DBM_TimerUpdate", "DBM_TimerForce"
    },
    force_events = "DBM_TimerForce",
    name = L["DBM Timer"],
    canHaveAuto = true,
    canHaveDuration = "timed",
    triggerFunction = function(trigger)
      WeakAuras.RegisterDBMCallback("DBM_TimerStart");
      WeakAuras.RegisterDBMCallback("DBM_TimerStop");
      WeakAuras.RegisterDBMCallback("wipe");
      WeakAuras.RegisterDBMCallback("kill");

      local ret = "return function (states, event, id)\n"
      -- ret = ret .. "          print(event, id)\n";
      if (trigger.use_id) then
        ret = ret .. "          local triggerId = \"" .. (trigger.id or "") .. "\"\n";
      else
        ret = ret .. "          local triggerId = nil\n";
      end

      if (trigger.use_message) then
        local ret2 = [=[
          local triggerMessage = [[%s]]
          local triggerOperator = [[%s]]
        ]=]
        ret = ret .. ret2:format(trigger.message or "", trigger.message_operator  or "")
      else
        ret = ret .. [[
          local triggerMessage = nil;
          local triggerOperator = nil;
        ]]
      end

      if (trigger.use_spellId and trigger.spellId) then
        local ret2 = [=[
          local triggerSpellId = [[%s]];
        ]=];
        ret = ret .. ret2:format(trigger.spellId or "");
      else
        ret = ret .. [[
          local triggerSpellId = nil;
        ]];
      end
      local copyOrSchedule;
      if (trigger.use_remaining) then
        local ret2 = [[
          local remainingCheck = %s;
        ]];
        ret = ret .. ret2:format(trigger.remaining or 0);
        copyOrSchedule = [[
          local remainingTime = bar.expirationTime - GetTime()
          if (remainingTime %s %s) then
            WeakAuras.CopyBarToState(bar, states, id);
          elseif (states[id] and states[id].show) then
              states[id].show = false;
              states[id].changed = true;
          end
          if (remainingTime >= remainingCheck) then
            WeakAuras.ScheduleDbmCheck(bar.expirationTime - remainingCheck);
          end
        ]]
        copyOrSchedule = copyOrSchedule:format(trigger.remaining_operator or "<", trigger.remaining or 0);
      else
        copyOrSchedule = [[
          WeakAuras.CopyBarToState(bar, states, id);
          ]];
      end
      if (trigger.use_cloneId) then
        ret = ret .. [[
          if (event == "DBM_TimerStart") then
            if (WeakAuras.DBMTimerMatches(id, triggerId, triggerMessage, triggerOperator, triggerSpellId)) then
              local bar = WeakAuras.GetDBMTimerById(id);
          ]]
        ret = ret .. copyOrSchedule;
        ret = ret .. [[
            end
          elseif (event == "DBM_TimerUpdate") then
            for id, bar in pairs(WeakAuras.GetAllDBMTimers()) do
              if (WeakAuras.DBMTimerMatches(id, triggerId, triggerMessage, triggerOperator, triggerSpellId)) then
                ]]
        ret = ret .. copyOrSchedule;
        ret = ret .. [[
              end
            end

          elseif (event == "DBM_TimerStop") then
            if (states[id]) then
              states[id].show = false;
              states[id].changed = true;
            end
          elseif (event == "DBM_TimerStopAll") then
            for _, state in pairs(states) do
              state.show = false;
              state.changed = false;
            end
          elseif (event == "DBM_TimerForce") then
            wipe(states);
            for id, bar in pairs(WeakAuras.GetAllDBMTimers()) do
              if (WeakAuras.DBMTimerMatches(id, triggerId, triggerMessage, triggerOperator, triggerSpellId)) then
                ]]
        ret = ret .. copyOrSchedule;
        ret = ret .. [[
              end
            end
          end
          return true;
        end
        ]]
        --print(ret);
        return ret
      else -- no clones
        ret = ret .. [[
          local bar = WeakAuras.GetDBMTimer(triggerId, triggerMessage, triggerOperator, triggerSpellId);
          local id = "";
          if (bar) then
        ]]
      ret = ret .. copyOrSchedule;
      ret = ret .. [[
          else
            if (states[""] and states[""].show) then
              states[""].show = false;
              states[""].changed = true;
            end
          end
          return true;
        end]]
      --print(ret);
      return ret;
      end
    end,
    statesParameter = "full",
    args = {
      {
        name = "id",
        display = L["Id"],
        type = "string"
      },
      {
        name = "message",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "spellId",
        display = L["Spell/Encounter Id"],
        type = "string",
        store = true,
        conditionType = "string"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
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
    }
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
      WeakAuras.RegisterBigWigsTimer();
      local ret = [=[
        return function(states, event, id)
        local triggerAddon = %s;
        local triggerSpellId = %q;
        local triggerText = %s;
        local triggerTextOperator = [[%s]];
      ]=]

      ret = ret:format(trigger.use_addon and ('[[' .. (trigger.addon or '') .. ']]') or "nil",
        trigger.use_spellId and tostring(trigger.spellId) or "",
        trigger.use_text and ('[[' .. (trigger.text or '') .. ']]') or "nil",
        trigger.use_text and trigger.text_operator or ""
      );

      local copyOrSchedule;
      if (trigger.use_remaining) then
        local ret2 = [[
          local remainingCheck = %s;
        ]];
        ret = ret .. ret2:format(trigger.remaining or 0);
        copyOrSchedule = [[
          local remainingTime = bar.expirationTime - GetTime()
          if (remainingTime %s %s) then
            WeakAuras.CopyBigWigsTimerToState(bar, states, id);
          elseif (states[id] and states[id].show) then
              states[id].show = false;
              states[id].changed = true;
          end
          if (remainingTime >= remainingCheck) then
            WeakAuras.ScheduleBigWigsCheck(bar.expirationTime - remainingCheck);
          end
          ]]
        copyOrSchedule = copyOrSchedule:format(trigger.remaining_operator or "", trigger.remaining or 0);
      else
        copyOrSchedule = [[
          WeakAuras.CopyBigWigsTimerToState(bar, states, id);
          ]];
      end

      if (trigger.use_cloneId) then
        ret = ret .. [[
          if (event == "BigWigs_StartBar") then
            if (WeakAuras.BigWigsTimerMatches(id, triggerAddon, triggerSpellId, triggerTextOperator, triggerText)) then
              local bar = WeakAuras.GetBigWigsTimerById(id);
          ]]
        ret = ret .. copyOrSchedule;
        ret = ret .. [[
            end
          elseif (event == "BigWigs_StopBar") then
            if (states[id]) then
              states[id].show = false;
              states[id].changed = true;
            end
          elseif (event == "BigWigs_Timer_Update") then
            for id, bar in pairs(WeakAuras.GetAllBigWigsTimers()) do
              if (WeakAuras.BigWigsTimerMatches(id, triggerAddon, triggerSpellId, triggerTextOperator, triggerText)) then
                ]]
        ret = ret .. copyOrSchedule;
        ret = ret .. [[
              end
            end
          elseif (event == "BigWigs_Timer_Force") then
            wipe(states);
            for id, bar in pairs(WeakAuras.GetAllBigWigsTimers()) do
              if (WeakAuras.BigWigsTimerMatches(id, triggerAddon, triggerSpellId, triggerTextOperator, triggerText)) then
                ]]
        ret = ret .. copyOrSchedule;
        ret = ret .. [[
              end
            end
          end
          return true;
        end
        ]]
        return ret;
      else
        ret = ret .. [[
          local bar = WeakAuras.GetBigWigsTimer(triggerAddon, triggerSpellId, triggerTextOperator, triggerText);
          local id = "";
          if (bar) then
        ]]
        ret = ret .. copyOrSchedule;
        ret = ret .. [[
          else
            if (states[""] and states[""].show) then
              states[""].show = false;
              states[""].changed = true;
            end
          end
          return true;
        end]]
        --print(ret);
        return ret;
      end
    end,
    statesParameter = "full",
    args = {
      {
        name = "addon",
        display = L["BigWigs Addon"],
        type = "string",
      },
      {
        name = "spellId",
        display = L["Spell Id"], -- Correct?
        type = "string",
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
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''"
      }
    },
    automaticrequired = true,
    automaticAutoHide = false
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
    events = {
    },
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
        local hand = [[%s]];
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
      "SPELL_UPDATE_USABLE",
      "PLAYER_TARGET_CHANGED",
      "UNIT_POWER_FREQUENT",
      "RUNE_POWER_UPDATE",
    },
    internal_events = {
      "SPELL_COOLDOWN_READY",
      "SPELL_COOLDOWN_CHANGED",
      "SPELL_COOLDOWN_STARTED",
    },
    force_events = "SPELL_UPDATE_USABLE",
    name = L["Action Usable"],
    loadFunc = function(trigger)
      trigger.spellName = trigger.spellName or 0;
      local spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      trigger.realSpellName = spellName; -- Cache
      WeakAuras.WatchSpellCooldown(spellName);
    end,
    init = function(trigger)
      --trigger.spellName = WeakAuras.CorrectSpellName(trigger.spellName) or 0;
      trigger.spellName = trigger.spellName or 0;
      local spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
      trigger.realSpellName = spellName; -- Cache
      local ret = [=[
        local spellname = [[%s]]
        local startTime, duration = WeakAuras.GetSpellCooldown(spellname);
        local charges = WeakAuras.GetSpellCharges(spellname);
        if (charges == nil) then
          charges = (duration == 0) and 1 or 0;
        end
        local ready = startTime == 0 or charges > 0
        local active = IsUsableSpell(spellname) and ready
      ]=]
      if(trigger.use_targetRequired) then
        ret = ret.."active = active and WeakAuras.IsSpellInRange(spellname or '', 'target')\n";
      end
      if(trigger.use_inverse) then
        ret = ret.."active = not active\n";
      end

      return ret:format(spellName)
    end,
    args = {
      {
        name = "spellName",
        display = L["Spell"],
        required = true,
        type = "spell",
        test = "true"
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
        enable = function(trigger) return not(trigger.use_inverse) end
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        reloadOptions = true
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
      return WeakAuras.GetSpellCharges(trigger.realSpellName);
    end,
    hasSpellID = true,
    automaticrequired = true
  },
  ["Totem"] = {
    type = "status",
    events = {
      "PLAYER_TOTEM_UPDATE",
      "PLAYER_ENTERING_WORLD"
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
      "BAG_UPDATE",
      "PLAYER_ENTERING_WORLD"
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
      "UPDATE_SHAPESHIFT_FORM",
    },
    internal_events = { "WA_DELAYED_PLAYER_ENTERING_WORLD" },
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Stance/Form/Aura"],
    init = function(trigger)
      local ret = [[
      local form = GetShapeshiftForm();
      local inverse = %s;
    ]];

      return ret:format(trigger.use_inverse and "true" or "false");
    end,
    statesParameter = "one",
    args = {
      {
        name = "form",
        display = L["Form"],
        type = "select",
        values = "form_types",
        test = "inverse == (form ~= %s)",
        store = true,
        conditionType = "select"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        enable = function(trigger) return trigger.use_form end
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
      local _, class = UnitClass("player");
      if(class == trigger.class) then
        local form = GetShapeshiftForm();
        local icon = form > 0 and GetShapeshiftFormInfo(form) or "Interface\\Icons\\Achievement_Character_Human_Male";
        return icon;
      else
        return nil;
      end
    end,
    automaticrequired = true
  },
  ["Weapon Enchant"] = {
    type = "status",
    events = { },
    internal_events = {
      "MAINHAND_TENCH_UPDATE",
      "OFFHAND_TENCH_UPDATE"
    },
    force_events = "MAINHAND_TENCH_UPDATE",
    name = L["Fishing Lure / Weapon Enchant (Old)"],
    init = function(trigger)
      WeakAuras.TenchInit();
      local ret = [[
        local exists, _, name
        local inverse
      ]];
      if(trigger.weapon == "main") then
        ret = ret .. [[
          exists, _, name = WeakAuras.GetMHTenchInfo()
        ]];
      elseif(trigger.weapon == "off") then
        ret = ret .. [[
          exists, _, name = WeakAuras.GetOHTenchInfo()
        ]];
      end

      if(trigger.use_inverse) then
        ret = ret..[[
          inverse = true;
        ]];
      end

      if(trigger.use_enchant and trigger.enchant and trigger.enchant ~= "") then
        ret = ret .. [[
          exists = name == ']] .. trigger.enchant .. [[';
        ]]
      end
      return ret;
    end,
    args = {
      {
        name = "weapon",
        display = L["Weapon"],
        type = "select",
        values = "weapon_types",
        test = "(inverse and not exists) or (not inverse and exists)"
      },
      {
        name = "enchant",
        display = L["Weapon Enchant"],
        type = "string",
        test = "true"
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true"
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
        _, _, _, icon = WeakAuras.GetMHTenchInfo();
      elseif(trigger.weapon == "off") then
        _, _, _, icon = WeakAuras.GetOHTenchInfo();
      end
      return icon;
    end,
    automaticrequired = true
  },
  ["Chat Message"] = {
    type = "event",
    events = {
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
      "CHAT_MSG_SYSTEM"
    },
    name = L["Chat Message"],
    init = function(trigger)
      local ret = [[
        if (event:find('LEADER')) then
          event = event:sub(0, -8);
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
        test = "event=='%s'",
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
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''"
      },
    }
  },
  ["Ready Check"] = {
    type = "event",
    events = {
      "READY_CHECK",
    },
    name = L["Ready Check"],
    args = {}
  },
  ["Combat Events"] = {
    type = "event",
    events = {
      "PLAYER_REGEN_ENABLED",
      "PLAYER_REGEN_DISABLED"
    },
    name = L["Entering/Leaving Combat"],
    args = {
      {
        name = "eventtype",
        required = true,
        display = L["Type"],
        type = "select",
        values = "combat_event_type",
        test = "event == (\"%s\")"
      }
    }
  },
  ["Death Knight Rune"] = {
    type = "status",
    events = {
      "RUNE_POWER_UPDATE",
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
      local showOn = %s

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
        if(remaining >= remainingCheck) then
          WeakAuras.ScheduleCooldownScan(expirationTime - remainingCheck);
        end
      ]];
        ret = ret..ret2:format(tonumber(trigger.remaining or 0) or 0);
      end
      return ret:format(trigger.rune, "[[" .. (trigger.showOn or "") .. "]]");
    end,
    args = {
      {
        name = "rune",
        display = L["Rune"],
        type = "select",
        values = "rune_specific_types",
        test = "(showOn == \"showOnReady\" and (startTime == 0)) " ..
               "or (showOn == \"showOnCooldown\" and startTime > 0) "  ..
               "or (showOn == \"showAlways\")",
        enable = function(trigger) return not trigger.use_runesCount end,
        reloadOptions = true
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return trigger.use_rune and not(trigger.showOn == "showOnReady") end
      },
      {
        name = "showOn",
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
        conditionTest = "(state and state.show and state.expirationTime and state.expirationTime > GetTime()) == (%s == 1)",
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
    automaticAutoHide = false
  },
  ["Item Equipped"] = {
    type = "status",
    events = {
      "UNIT_INVENTORY_CHANGED",
      "PLAYER_EQUIPMENT_CHANGED",
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
      "PLAYER_EQUIPMENT_CHANGED",
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
      "PLAYER_EQUIPMENT_CHANGED",
      "WEAR_EQUIPMENT_SET",
      "EQUIPMENT_SETS_CHANGED",
      "EQUIPMENT_SWAP_FINISHED",
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
    events = function(trigger)
      local result = {
        "UNIT_THREAT_SITUATION_UPDATE",
      };
      AddUnitChangeEvents(trigger.threatUnit, result);
      return result;
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
    automatic = true
  },
  ["Crowd Controlled"] = {
    type = "status",
    events = {
      "UNIT_AURA"
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
      local result = {
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_CHANNEL_UPDATE",
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_DELAYED",
        "UNIT_SPELLCAST_INTERRUPTIBLE",
        "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
      };
      AddUnitChangeEvents(trigger.unit, result);
      return result;
    end,
    internal_events = {
      "CAST_REMAINING_CHECK"
    },
    force_events = "CAST_REMAINING_CHECK",
    name = L["Cast"],
    init = function(trigger)
      trigger.unit = trigger.unit or "";
      local ret = [=[
        local unit = [[%s]]
        local inverse = %s
        local spell, interruptible, _;
        local castType;
        local endTime;
        spell, _, _, _, endTime, _, _, interruptible = UnitCastingInfo(unit)
        if(spell) then
          castType = "cast"
        else
          spell, _, _, _, endTime, _, interruptible = UnitChannelInfo(unit)
          if(spell) then
            castType = "channel"
          end
        end
        interruptible = not interruptible;
      ]=];
      ret = ret:format(trigger.unit, trigger.use_inverse and "true" or "false");

      if(trigger.use_remaining) then
        local ret2 = [[
          local expirationTime = endTime and endTime > 0 and (endTime / 1000) or 0;
          local remaining = expirationTime - GetTime();
          local remainingCheck = %s;
          if(remaining >= remainingCheck) then
            WeakAuras.ScheduleCastCheck(expirationTime - remainingCheck);
          end
        ]];
        ret = ret .. ret2:format(tonumber(trigger.remaining or 0) or 0);
      end
      return ret;
    end,
    statesParameter = "one",
    args = {
      {
        name = "unit",
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_with_specific",
        required = true,
        test = "event:sub(1,14) ~= 'UNIT_SPELLCAST' or UnitIsUnit(unit, '%s' or '')"
      },
      {
        name = "spell",
        display = L["Spell Name"],
        type = "string" ,
        enable = function(trigger) return not(trigger.use_inverse) end,
        store = true,
        conditionType = "string",
      },
      {
        name = "castType",
        display = L["Cast Type"],
        type = "select",
        values = "cast_types",
        enable = function(trigger) return not(trigger.use_inverse) end,
        store = true,
        conditionType = "select"
      },
      {
        name = "interruptible",
        display = L["Interruptible"],
        type = "tristate",
        enable = function(trigger) return not(trigger.use_inverse) end,
        store = true,
        conditionType = "bool"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return not(trigger.use_inverse) end,
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        reloadOptions = true
      },
      {
        hidden = true,
        test = "UnitExists(unit) and ((not inverse and spell) or (inverse and not spell))"
      }
    },
    durationFunc = function(trigger)
      local _, _, _, startTime, endTime = UnitCastingInfo(trigger.unit);
      if not(startTime) then
        local _, _, _, startTime, endTime = UnitChannelInfo(trigger.unit);
        if not(startTime) then
          return 0, math.huge;
        else
          return (endTime - startTime)/1000, endTime/1000;
        end
      else
        return (endTime - startTime)/1000, endTime/1000, nil, true;
      end
    end,
    nameFunc = function(trigger)
      local name = UnitCastingInfo(trigger.unit);
      if not(name) then
        local name = UnitChannelInfo(trigger.unit);
        if not(name) then
          return trigger.spell or L["Spell Name"];
        else
          return name;
        end
      else
        return name;
      end
    end,
    iconFunc = function(trigger)
      local _, _, icon = UnitCastingInfo(trigger.unit);
      if not(icon) then
        local _, _, icon = UnitChannelInfo(trigger.unit);
        if not(icon) then
          return "Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon";
        else
          return icon;
        end
      else
        return icon;
      end
    end,
    automaticrequired = true,
    automaticAutoHide = false
  },
  ["Conditions"] = {
    type = "status",
    events = function(trigger, untrigger)
      local events = {};
      if (trigger.use_incombat ~= nil) then
        tinsert(events, "PLAYER_REGEN_ENABLED");
        tinsert(events, "PLAYER_REGEN_DISABLED");
      end
      if (trigger.use_pvpflagged ~= nil) then
        tinsert(events, "PLAYER_FLAGS_CHANGED");
      end

      if (trigger.use_alive ~= nil) then
        tinsert(events, "PLAYER_DEAD");
        tinsert(events, "PLAYER_ALIVE");
        tinsert(events, "PLAYER_UNGHOST");
      end

      if (trigger.use_vehicle ~= nil) then
        tinsert(events, "UNIT_ENTERED_VEHICLE");
        tinsert(events, "UNIT_EXITED_VEHICLE");
      end

      if (trigger.use_resting ~= nil) then
        tinsert(events, "PLAYER_UPDATE_RESTING");
      end

      if (trigger.use_HasPet ~= nil) then
        tinsert(events, "UNIT_PET");
      end

      return events;
    end,
    internal_events = function(trigger, untrigger)
      local events = { "CONDITIONS_CHECK"};
      if (trigger.use_mounted ~= nil) then
        tinsert(events, "MOUNTED_UPDATE");
      end

      if (trigger.use_HasPet ~= nil) then
        tinsert(events, "PET_UPDATE");
      end

      if (trigger.use_ismoving ~= nil) then
        tinsert(events, "PLAYER_MOVING_UPDATE");
      end
      return events;
    end,
    force_events = "CONDITIONS_CHECK",
    name = L["Conditions"],
    loadFunc = function(trigger)
      if(trigger.use_mounted ~= nil) then
        WeakAuras.WatchForMounts();
      end
      if (trigger.use_HasPet ~= nil) then
        WeakAuras.WatchForPetDeath();
      end
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
        init = "UnitIsPVP('player')"
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
        init = "UnitInVehicle('player')"
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
      "SPELLS_CHANGED",
      "UNIT_PET",
    },
    internal_events = {
      "WA_DELAYED_PLAYER_ENTERING_WORLD",
      "WA_SPELL_CHECK"
    },
    force_events = "WA_SPELL_CHECK",
    name = L["Spell Known"],
    init = function(trigger)
      local ret = [[
        local spellName = tonumber(%q);
        local usePet = %s;
      ]]
      return ret:format(trigger.spellName or "", trigger.use_petspell and "true" or "false");
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
    events = {
      "PET_BAR_UPDATE",
      "UNIT_PET",
    },
    internal_events = {
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = "WA_DELAYED_PLAYER_ENTERING_WORLD",
    name = L["Pet Behavior"],
    init = function(trigger)
      local ret = [[
          local inverse = %s
          local check_behavior = %s
          local name, i, active
          local activeIcon
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
      return ret:format(trigger.use_inverse and "true" or "false", trigger.use_behavior and ('"' .. (trigger.behavior or "") .. '"') or "nil");
    end,
    statesParameter = "one",
    canHaveAuto = true,
    args = {
      {
        name = "behavior",
        display = L["Pet Behavior"],
        type = "select",
        values = "pet_behavior_types",
        test = "true",
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
        enable = function(trigger) return trigger.use_behavior end
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
        test = "UnitExists('pet') and (not check_behavior or (inverse and check_behavior ~= behavior) or (not inverse and check_behavior == behavior))"
      }
    },
    automaticrequired = true
  },

  ["Range Check"] = {
    type = "status",
    events = {
      "FRAME_UPDATE",
    },
    name = L["Range Check"],
    init = function(trigger)
      trigger.unit = trigger.unit or "target";
      local ret = [=[
          local unit = [[%s]];
          local min, max = WeakAuras.GetRange(unit);
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
        conditionTest = "state and state.show and WeakAuras.CheckRange(state.unit, %s, '%s')",
      },
      {
        hidden = true,
        test = "UnitExists(unit)"
      }
    },
    automaticrequired = true
  },

};

WeakAuras.dynamic_texts = {
  ["%p"] = {
    unescaped = "%p",
    name = L["Progress"],
    value = "progress",
    static = "8.0"
  },
  ["%t"] = {
    unescaped = "%t",
    name = L["Total"],
    value = "duration",
    static = "12.0"
  },
  ["%n"] = {
    unescaped = "%n",
    name = L["Name"],
    value = "name"
  },
  ["%i"] = {
    unescaped = "%i",
    name = L["Icon"],
    value = "icon"
  },
  ["%s"] = {
    unescaped = "%s",
    name = L["Stacks"],
    value = "stacks",
    static = 1
  },
  ["%c"] = {
    unescaped = "%c",
    name = L["Custom"],
    value = "custom",
    static = L["Custom"]
  }
};
