if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

-- Lua APIs
local tinsert, tsort = table.insert, table.sort
local tostring = tostring
local select, pairs, type = select, pairs, type
local ceil, min = ceil, min

-- WoW APIs
local GetTalentInfo = GetTalentInfo
local GetNumSpecializationsForClassID, GetSpecialization = GetNumSpecializationsForClassID, GetSpecialization
local UnitClass, UnitHealth, UnitHealthMax, UnitName, UnitStagger, UnitPower, UnitPowerMax = UnitClass, UnitHealth, UnitHealthMax, UnitName, UnitStagger, UnitPower, UnitPowerMax
local GetSpellInfo, GetItemInfo, GetItemCount, GetItemIcon = GetSpellInfo, GetItemInfo, GetItemCount, GetItemIcon
local GetShapeshiftFormInfo, GetShapeshiftForm = GetShapeshiftFormInfo, GetShapeshiftForm
local GetRuneCooldown, UnitCastingInfo, UnitChannelInfo = GetRuneCooldown, UnitCastingInfo, UnitChannelInfo
local UnitDetailedThreatSituation, UnitThreatSituation = UnitDetailedThreatSituation, UnitThreatSituation
local CastingInfo, ChannelInfo = CastingInfo, ChannelInfo
local MAX_NUM_TALENTS = MAX_NUM_TALENTS or 20

local WeakAuras = WeakAuras
local L = WeakAuras.L

local SpellRange = LibStub("SpellRange-1.0")
function WeakAuras.IsSpellInRange(spellId, unit)
  return SpellRange.IsSpellInRange(spellId, unit)
end

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

local RangeCacheStrings = {friend = "", harm = "", misc = ""}
local function RangeCacheUpdate()
  local friend, harm, misc = {}, {}, {}
  local friendString, harmString, miscString

  for range in LibRangeCheck:GetFriendCheckers() do
    tinsert(friend, range)
  end
  tsort(friend)
  for range in LibRangeCheck:GetHarmCheckers() do
    tinsert(harm, range)
  end
  tsort(harm)
  for range in LibRangeCheck:GetMiscCheckers() do
    tinsert(misc, range)
  end
  tsort(misc)

  for _, key in pairs(friend) do
    friendString = (friendString and (friendString .. ", ") or "") .. key
  end
  for _, key in pairs(harm) do
    harmString = (harmString and (harmString .. ", ") or "") .. key
  end
  for _, key in pairs(misc) do
      miscString = (miscString and (miscString .. ", ") or "") .. key
  end
  RangeCacheStrings.friend, RangeCacheStrings.harm, RangeCacheStrings.misc = friendString, harmString, miscString
end

LibRangeCheck:RegisterCallback(LibRangeCheck.CHECKERS_CHANGED, RangeCacheUpdate)

function WeakAuras.UnitDetailedThreatSituation(unit1, unit2)
  local ok, aggro, status, threatpct, rawthreatpct, threatvalue = pcall(UnitDetailedThreatSituation, unit1, unit2)
  if ok then
    return aggro, status, threatpct, rawthreatpct, threatvalue
  end
end

local LibClassicCasterino
if WeakAuras.IsClassic() then
  LibClassicCasterino = LibStub("LibClassicCasterino")
end

if WeakAuras.IsRetail() then
  WeakAuras.UnitCastingInfo = UnitCastingInfo
elseif WeakAuras.IsBCC() then
  WeakAuras.UnitCastingInfo = function(unit)
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, spellId = UnitCastingInfo(unit)
    return name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, nil, spellId
  end
else
  WeakAuras.UnitCastingInfo = function(unit)
    if UnitIsUnit(unit, "player") then
      return CastingInfo()
    else
      return LibClassicCasterino:UnitCastingInfo(unit)
    end
  end
end

if WeakAuras.IsRetail() then
  WeakAuras.UnitChannelInfo = UnitChannelInfo
elseif WeakAuras.IsBCC() then
  WeakAuras.UnitChannelInfo = function(unit)
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, spellId  = UnitChannelInfo(unit)
    return name, text, texture, startTimeMS, endTimeMS, isTradeSkill, nil, spellId
  end
else
  WeakAuras.UnitChannelInfo = function(unit)
    if UnitIsUnit(unit, "player") then
      return ChannelInfo()
    else
      return LibClassicCasterino:UnitChannelInfo(unit)
    end
  end
end

local constants = {
  nameRealmFilterDesc = L[" Filter formats: 'Name', 'Name-Realm', '-Realm'. \n\nSupports multiple entries, separated by commas\n"],
}

if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
  WeakAuras.UnitRaidRole = function(unit)
    local raidID = UnitInRaid(unit)
    if raidID then
      return select(10, GetRaidRosterInfo(raidID)) or "NONE"
    end
  end
end

local encounter_list = ""
local zoneId_list = ""
function Private.InitializeEncounterAndZoneLists()
  if encounter_list ~= "" then
    return
  end
  if WeakAuras.IsClassic() or WeakAuras.IsBCC() then

    local classic_raids = {
      [L["Black Wing Lair"]] = {
          { L["Razorgore the Untamed"], 610 },
          { L["Vaelastrasz the Corrupt"], 611 },
          { L["Broodlord Lashlayer"], 612 },
          { L["Firemaw"], 613 },
          { L["Ebonroc"], 614 },
          { L["Flamegor"], 615 },
          { L["Chromaggus"], 616 },
          { L["Nefarian"], 617 }
      },
      [L["Molten Core"]] = {
          { L["Lucifron"], 663 },
          { L["Magmadar"], 664 },
          { L["Gehennas"], 665 },
          { L["Garr"], 666 },
          { L["Shazzrah"], 667 },
          { L["Baron Geddon"], 668 },
          { L["Sulfuron Harbinger"], 669 },
          { L["Golemagg the Incinerator"], 670 },
          { L["Majordomo Executus"], 671 },
          { L["Ragnaros"], 672 }
      },
      [L["Ahn'Qiraj"]] = {
          { L["The Prophet Skeram"], 709 },
          { L["Silithid Royalty"], 710 },
          { L["Battleguard Sartura"], 711 },
          { L["Fankriss the Unyielding"], 712 },
          { L["Viscidus"], 713 },
          { L["Princess Huhuran"], 714 },
          { L["Twin Emperors"], 715 },
          { L["Ouro"], 716 },
          { L["C'thun"], 717 }
      },
      [L["Ruins of Ahn'Qiraj"]] = {
          { L["Kurinnaxx"], 718 },
          { L["General Rajaxx"], 719 },
          { L["Moam"], 720 },
          { L["Buru the Gorger"], 721 },
          { L["Ayamiss the Hunter"], 722 },
          { L["Ossirian the Unscarred"], 723 }
      },
      [L["Zul'Gurub"]] = {
          { L["High Priest Venoxis"], 784 },
          { L["High Priestess Jeklik"], 785 },
          { L["High Priestess Mar'li"], 786 },
          { L["Bloodlord Mandokir"], 787 },
          { L["Edge of Madness"], 788 },
          { L["High Priest Thekal"], 789 },
          { L["Gahz'ranka"], 790 },
          { L["High Priestess Arlokk"], 791 },
          { L["Jin'do the Hexxer"], 792 },
          { L["Hakkar"], 793 }
      },
      [L["Onyxia's Lair"]] = {
          { L["Onyxia"], 1084 }
      },
      [L["Naxxramas"]] = {
          -- The Arachnid Quarter
          { L["Anub'Rekhan"], 1107 },
          { L["Grand Widow Faerlina"], 1110 },
          { L["Maexxna"], 1116 },
          -- The Plague Quarter
          { L["Noth the Plaguebringer"], 1117 },
          { L["Heigan the Unclean"], 1112 },
          { L["Loatheb"], 1115 },
          -- The Military Quarter
          { L["Instructor Razuvious"], 1113 },
          { L["Gothik the Harvester"], 1109 },
          { L["The Four Horsemen"], 1121 },
          -- The Construct Quarter
          { L["Patchwerk"], 1118 },
          { L["Grobbulus"], 1111 },
          { L["Gluth"], 1108 },
          { L["Thaddius"], 1120 },
          -- Frostwyrm Lair
          { L["Sapphiron"], 1119 },
          { L["Kel'Thuzad"], 1114 }
      }
    }
    for instance_name, instance_boss in pairs(classic_raids) do
      encounter_list = ("%s|cffffd200%s|r\n"):format(encounter_list, instance_name)
      for _, data in ipairs(instance_boss) do
          encounter_list = ("%s%s: %d\n"):format(encounter_list, data[1], data[2])
      end
      encounter_list = encounter_list .. "\n"
    end
  else
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
  end

  encounter_list = encounter_list:sub(1, -3) .. "\n\n" .. L["Supports multiple entries, separated by commas\n"]
end

local function get_encounters_list()
  return encounter_list
end

local function get_zoneId_list()
  if not WeakAuras.IsRetail() then return "" end
  local currentmap_id = C_Map.GetBestMapForUnit("player")
  local currentmap_info = C_Map.GetMapInfo(currentmap_id)
  local currentmap_name = currentmap_info and currentmap_info.name or ""
  local currentmap_zone_name = ""
  local mapGroupId = C_Map.GetMapGroupID(currentmap_id)
  if mapGroupId then
    currentmap_zone_name = string.format("|cffffd200%s|r%s: g%d\n\n",
                                         L["Current Zone Group\n"], currentmap_name, mapGroupId)

    -- if map is in a group, its real name is (or should be?) found in GetMapGroupMembersInfo
    for k, map in ipairs(C_Map.GetMapGroupMembersInfo(mapGroupId)) do
      if map.mapID and map.mapID == currentmap_id and map.name then
        currentmap_name = map.name
        break
      end
    end
  end

  return ("%s|cffffd200%s|r%s: %d\n\n%s%s"):format(
    zoneId_list,
    L["Current Zone\n"],
    currentmap_name,
    currentmap_id,
    currentmap_zone_name,
    L["Supports multiple entries, separated by commas. Group Zone IDs must be prefixed with 'g', e.g. g277."]
  )
end

Private.function_strings = {
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
      if max == 0 then
        return false
      end
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


Private.anim_function_strings = {
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

starShakeDecay = [[
function(progress, startX, startY, deltaX, deltaY)
    local spokes = 10
    local fullCircles = 4

    local r = min(abs(deltaX), abs(deltaY))
    local xScale = deltaX / r
    local yScale = deltaY / r

    local deltaAngle = fullCircles *2 / spokes * math.pi
    local p = progress * spokes
    local i1 = floor(p)
    p = p - i1

    local angle1 = i1 * deltaAngle
    local angle2 = angle1 + deltaAngle

    local x1 = r * math.cos(angle1)
    local y1 = r * math.sin(angle1)

    local x2 = r * math.cos(angle2)
    local y2 = r * math.sin(angle2)

    local x, y = p * x2 + (1-p) * x1, p * y2 + (1-p) * y1
    local ease = math.sin(progress * math.pi / 2)
    return ease * x * xScale, ease * y * yScale
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

Private.anim_presets = {
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
  starShakeDecay = {
    type = "custom",
    duration = 1,
    use_translate = true,
    x = 50,
    y = 50,
    translateType = "starShakeDecay",
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

if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
  function WeakAuras.CheckTalentByIndex(index, extraOption)
    local tab = ceil(index / MAX_NUM_TALENTS)
    local num_talent = (index - 1) % MAX_NUM_TALENTS + 1
    local _, _, _, _, rank  = GetTalentInfo(tab, num_talent)
    return rank and rank > 0;
  end
else
  function WeakAuras.CheckTalentByIndex(index, extraOption)
    local tier = ceil(index / 3)
    local column = (index - 1) % 3 + 1
    local _, _, _, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
    if extraOption == 0 or extraOption == 2 then
      return selected or known
    else
      return selected
    end
  end
end

function WeakAuras.CheckPvpTalentByIndex(index)
  local checkTalentSlotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(1)
  if checkTalentSlotInfo then
    local checkTalentId = checkTalentSlotInfo.availableTalentIDs[index]
    for i = 1, 3 do
      local talentSlotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(i)
      if talentSlotInfo and (talentSlotInfo.selectedTalentID == checkTalentId) then
        return true, checkTalentId
      end
    end
    return false, checkTalentId
  end
  return false
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

function WeakAuras.CheckString(ids, currentId)
  if (not ids or not currentId) then
    return false;
  end

  for id in ids:gmatch('([^,]+)') do
    if id:trim() == currentId then
      return true
    end
  end

  return false;
end

function WeakAuras.ValidateNumeric(info, val)
  if val ~= nil and val ~= "" and (not tonumber(val) or tonumber(val) >= 2^31) then
    return false;
  end
  return true
end

function WeakAuras.ValidateNumericOrPercent(info, val)
  if val ~= nil and val ~= "" then
    local percent = string.match(val, "(%d+)%%")
    local number = percent and tonumber(percent) or tonumber(val)
    if(not number or number >= 2^31) then
      return false;
    end
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
  if type(flags) ~= "number" then return end
  if(flagToCheck == "Mine") then
    return bit.band(flags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0
  elseif (flagToCheck == "InGroup") then
    return bit.band(flags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0
  elseif (flagToCheck == "NotInGroup") then
    return bit.band(flags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0
  end
end

function WeakAuras.CheckCombatLogFlagsReaction(flags, flagToCheck)
  if type(flags) ~= "number" then return end
  if (flagToCheck == "Hostile") then
    return bit.band(flags, 64) ~= 0;
  elseif (flagToCheck == "Neutral") then
    return bit.band(flags, 32) ~= 0;
  elseif (flagToCheck == "Friendly") then
    return bit.band(flags, 16) ~= 0;
  end
end

local objectTypeToBit = {
  Object = 16384,
  Guardian = 8192,
  Pet = 4096,
  NPC = 2048,
  Player = 1024,
}

function WeakAuras.CheckCombatLogFlagsObjectType(flags, flagToCheck)
  if type(flags) ~= "number" then return end
  local bitToCheck = objectTypeToBit[flagToCheck]
  if not bitToCheck then return end
  return bit.band(flags, bitToCheck) ~= 0;
end

function WeakAuras.CheckRaidFlags(flags, flagToCheck)
  flagToCheck = tonumber(flagToCheck)
  if not flagToCheck or not flags then return end --bailout
  if flagToCheck == 0 then --no raid mark
    return bit.band(flags, COMBATLOG_OBJECT_RAIDTARGET_MASK) == 0
  elseif flagToCheck == 9 then --any raid mark
    return bit.band(flags, COMBATLOG_OBJECT_RAIDTARGET_MASK) > 0
  else -- specific raid mark
    return bit.band(flags, _G['COMBATLOG_OBJECT_RAIDTARGET'..flagToCheck]) > 0
  end
end

function WeakAuras.IsSpellKnownForLoad(spell, exact)
  local result = WeakAuras.IsSpellKnown(spell)
  if exact or result then
    return result
  end
  -- Dance through the spellname to the current spell id
  spell = GetSpellInfo(spell)
  if (spell) then
    spell = select(7, GetSpellInfo(spell))
  end
  if spell then
    return WeakAuras.IsSpellKnown(spell)
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
  -- In shadow form void eruption is overridden by void bolt, yet IsSpellKnown for void bolt
  -- returns false, whereas it returns true for void eruption
  local baseSpell = FindBaseSpellByID(spell);
  if (not baseSpell) then
    return false;
  end
  if (baseSpell ~= spell) then
    return WeakAuras.IsSpellKnown(baseSpell) or WeakAuras.IsSpellKnown(baseSpell, true);
  end
end

function WeakAuras.CompareSpellIds(a, b, exactCheck)
  if exactCheck then
    return tonumber(a) == tonumber(b)
  else
    return GetSpellInfo(a) == GetSpellInfo(b)
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

function WeakAuras.GetEffectiveAttackPower()
  local base, pos, neg = UnitAttackPower("player")
  return base + pos + neg
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
    if WeakAuras.IsRetail() then
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
    if(single_class and Private.talent_types_specific[single_class]
      and single_spec and Private.talent_types_specific[single_class][single_spec]) then
      return Private.talent_types_specific[single_class][single_spec];
    elseif((WeakAuras.IsClassic() or WeakAuras.IsBCC()) and single_class and Private.talent_types_specific[single_class]
      and Private.talent_types_specific[single_class]) then
      return Private.talent_types_specific[single_class];
    else
      return Private.talent_types;
    end
  end
end

Private.load_prototype = {
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
      name = "alive",
      display = L["Alive"],
      type = "tristate",
      init = "arg",
      width = WeakAuras.normalWidth,
      optional = true,
      events = {"PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST"}
    },
    {
      name = "warmode",
      display = L["War Mode Active"],
      type = "tristate",
      init = "arg",
      width = WeakAuras.normalWidth,
      optional = true,
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
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
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"PET_BATTLE_OPENING_START", "PET_BATTLE_CLOSE"}
    },
    {
      name = "vehicle",
      display = (WeakAuras.IsClassic() or WeakAuras.IsBCC()) and L["On Taxi"] or L["In Vehicle"],
      type = "tristate",
      init = "arg",
      width = WeakAuras.normalWidth,
      optional = true,
      events = (WeakAuras.IsClassic() or WeakAuras.IsBCC()) and {"UNIT_FLAGS"}
               or {"VEHICLE_UPDATE", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "UPDATE_OVERRIDE_ACTIONBAR", "UNIT_FLAGS"}
    },
    {
      name = "vehicleUi",
      display = L["Has Vehicle UI"],
      type = "tristate",
      init = "arg",
      width = WeakAuras.normalWidth,
      optional = true,
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"VEHICLE_UPDATE", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "UPDATE_OVERRIDE_ACTIONBAR", "UPDATE_VEHICLE_ACTIONBAR"}
    },
    {
      name = "ingroup",
      display = L["In Group"],
      type = "multiselect",
      width = WeakAuras.normalWidth,
      init = "arg",
      values = "group_types",
      events = {"GROUP_ROSTER_UPDATE"}
    },
    {
      name = "player",
      hidden = true,
      init = "arg",
      test = "true"
    },
    {
      name = "realm",
      hidden = true,
      init = "arg",
      test = "true"
    },
    {
      name = "namerealm",
      display = L["Player Name/Realm"],
      type = "string",
      test = "nameRealmChecker:Check(player, realm)",
      preamble = "local nameRealmChecker = WeakAuras.ParseNameCheck(%q)",
      desc = constants.nameRealmFilterDesc,
    },
    {
      name = "ignoreNameRealm",
      display = L["|cFFFF0000Not|r Player Name/Realm"],
      type = "string",
      test = "not nameRealmIgnoreChecker:Check(player, realm)",
      preamble = "local nameRealmIgnoreChecker = WeakAuras.ParseNameCheck(%q)",
      desc = constants.nameRealmFilterDesc,
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
              return Private.spec_types_2;
            elseif(min_specs < 4) then
              return Private.spec_types_3;
            else
              return Private.spec_types;
            end
          end
        end
      end,
      init = "arg",
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"PLAYER_TALENT_UPDATE"}
    },
    {
      name = "class_and_spec",
      display = L["Class and Specialization"],
      type = "multiselect",
      values = "spec_types_all",
      init = "arg",
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"PLAYER_TALENT_UPDATE"}
    },
    {
      name = "talent",
      display = L["Talent"],
      type = "multiselect",
      values = valuesForTalentFunction,
      test = "WeakAuras.CheckTalentByIndex(%d, %d)",
      events = not WeakAuras.IsRetail() and {"CHARACTER_POINTS_CHANGED"} or {"PLAYER_TALENT_UPDATE"},
      inverse = function(load)
        -- Check for multi select!
        return load.talent_extraOption == 2 or load.talent_extraOption == 3
      end,
      extraOption = {
        display = "",
        values = function()
          return Private.talent_extra_option_types
        end
      },
    },
    {
      name = "talent2",
      display = L["And Talent"],
      type = "multiselect",
      values = valuesForTalentFunction,
      test = "WeakAuras.CheckTalentByIndex(%d, %d)",
      enable = function(trigger)
        return trigger.use_talent ~= nil or trigger.use_talent2 ~= nil;
      end,
      events = WeakAuras.IsRetail() and {"PLAYER_TALENT_UPDATE"} or {"CHARACTER_POINTS_CHANGED"},
      inverse = function(load)
        return load.talent2_extraOption == 2 or load.talent2_extraOption == 3
      end,
      extraOption = {
        display = "",
        values = function()
          return Private.talent_extra_option_types
        end,
      }
    },
    {
      name = "talent3",
      display = L["And Talent"],
      type = "multiselect",
      values = valuesForTalentFunction,
      test = "WeakAuras.CheckTalentByIndex(%d, %d)",
      enable = function(trigger)
        return (trigger.use_talent ~= nil and trigger.use_talent2 ~= nil) or trigger.use_talent3 ~= nil;
      end,
      events = WeakAuras.IsRetail() and {"PLAYER_TALENT_UPDATE"} or {"CHARACTER_POINTS_CHANGED"},
      inverse = function(load)
        return load.talent3_extraOption == 2 or load.talent3_extraOption == 3
      end,
      extraOption = {
        display = "",
        values = function()
          return Private.talent_extra_option_types
        end,
      },
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
          if(single_class and Private.pvp_talent_types_specific[single_class]
            and single_spec and Private.pvp_talent_types_specific[single_class][single_spec]) then
            return Private.pvp_talent_types_specific[single_class][single_spec];
          else
            return Private.pvp_talent_types;
          end
        end
      end,
      test = "WeakAuras.CheckPvpTalentByIndex(%d)",
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"PLAYER_PVP_TALENT_UPDATE"}
    },
    {
      name = "spellknown",
      display = L["Spell Known"],
      type = "spell",
      test = "WeakAuras.IsSpellKnownForLoad(%s, %s)",
      events = {"SPELLS_CHANGED"},
      showExactOption = true
    },
    {
      name = "covenant",
      display = WeakAuras.newFeatureString .. L["Player Covenant"],
      type = "multiselect",
      values = "covenant_types",
      init = "arg",
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"COVENANT_CHOSEN"}
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
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"PLAYER_LEVEL_UP", "UNIT_FLAGS", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"}
    },
    {
      name = "zone",
      display = L["Zone Name"],
      type = "string",
      init = "arg",
      test = "WeakAuras.CheckString(%q, zone)",
      events = {"ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "VEHICLE_UPDATE"},
      desc = L["Supports multiple entries, separated by commas"]
    },
    {
      name = "zoneId",
      hidden = true,
      init = "arg",
      test = "true",
      enable = WeakAuras.IsRetail(),
    },
    {
      name = "zonegroupId",
      hidden = true,
      init = "arg",
      test = "true",
      enable = WeakAuras.IsRetail(),
    },
    {
      name = "zoneIds",
      display = L["Zone ID(s)"],
      type = "string",
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "VEHICLE_UPDATE"},
      desc = get_zoneId_list,
      preamble = "local zoneChecker = WeakAuras.ParseZoneCheck(%q)",
      test = "zoneChecker:Check(zoneId, zonegroupId)"
    },
    {
      name = "encounterid",
      display = L["Encounter ID(s)"],
      type = "string",
      init = "arg",
      desc = get_encounters_list,
      test = "WeakAuras.CheckNumericIds(%q, encounterid)",
      events = {"ENCOUNTER_START", "ENCOUNTER_END"}
    },
    {
      name = "size",
      display = L["Instance Size Type"],
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
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"PLAYER_DIFFICULTY_CHANGED", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"}
    },
    {
      name = "instance_type",
      display = L["Instance Type"],
      type = "multiselect",
      values = "instance_difficulty_types",
      init = "arg",
      control = "WeakAurasSortedDropdown",
      events = {"PLAYER_DIFFICULTY_CHANGED", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA"},
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
    },
    {
      name = "role",
      display = L["Spec Role"],
      type = "multiselect",
      values = "role_types",
      init = "arg",
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"PLAYER_ROLES_ASSIGNED", "PLAYER_TALENT_UPDATE"}
    },
    {
      name = "raid_role",
      display = WeakAuras.newFeatureString .. L["Raid Role"],
      type = "multiselect",
      values = "raid_role_types",
      init = "arg",
      enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
      hidden = WeakAuras.IsRetail(),
      events = {"PLAYER_ROLES_ASSIGNED"}
    },
    {
      name = "affixes",
      display = L["Mythic+ Affix"],
      type = "multiselect",
      values = "mythic_plus_affixes",
      init = "arg",
      test = "WeakAuras.CheckMPlusAffixIds(%d, affixes)",
      enable = WeakAuras.IsRetail(),
      hidden = not WeakAuras.IsRetail(),
      events = {"CHALLENGE_MODE_START", "CHALLENGE_MODE_COMPLETED"},
    },
    {
      name = "itemequiped",
      display = L["Item Equipped"],
      type = "item",
      test = "IsEquippedItem(%s)",
      events = { "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED"}
    },
    {
      name = "itemtypeequipped",
      display = WeakAuras.newFeatureString .. L["Item Type Equipped"],
      type = "multiselect",
      test = "IsEquippedItemType(WeakAuras.GetItemSubClassInfo(%s))",
      events = { "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED"},
      values = "item_weapon_types"
    },
    {
      name = "item_bonusid_equipped",
      display =  WeakAuras.newFeatureString .. L["Item Bonus Id Equipped"],
      type = "string",
      test = "WeakAuras.CheckForItemBonusId(%q)",
      events = { "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED"},
      desc = function()
        return WeakAuras.GetLegendariesBonusIds()
               .. L["\n\nSupports multiple entries, separated by commas"]
      end
    },
    {
      name = "not_item_bonusid_equipped",
      display =  WeakAuras.newFeatureString .. L["|cFFFF0000Not|r Item Bonus Id Equipped"],
      type = "string",
      test = "not WeakAuras.CheckForItemBonusId(%q)",
      events = { "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED"},
      desc = function()
        return WeakAuras.GetLegendariesBonusIds()
               .. L["\n\nSupports multiple entries, separated by commas"]
      end
    }
  }
};

local function AddUnitChangeInternalEvents(triggerUnit, t)
  if (triggerUnit == nil) then
    return
  end
  if (triggerUnit == "multi") then
    -- Handled by normal events"
  elseif triggerUnit == "pet" then
    WeakAuras.WatchForPetDeath();
    tinsert(t, "PET_UPDATE")
  else
    if Private.multiUnitUnits[triggerUnit] then
      for unit in pairs(Private.multiUnitUnits[triggerUnit]) do
        tinsert(t, "UNIT_CHANGED_" .. string.lower(unit))
        WeakAuras.WatchUnitChange(unit)
      end
    else
      tinsert(t, "UNIT_CHANGED_" .. string.lower(triggerUnit))
      WeakAuras.WatchUnitChange(triggerUnit)
    end
  end
end

local function AddUnitRoleChangeInternalEvents(triggerUnit, t)
  if (triggerUnit == nil) then
    return
  end

  if Private.multiUnitUnits[triggerUnit] then
    for unit in pairs(Private.multiUnitUnits[triggerUnit]) do
      tinsert(t, "UNIT_ROLE_CHANGED_" .. string.lower(unit))
    end
  else
    tinsert(t, "UNIT_ROLE_CHANGED_" .. string.lower(triggerUnit))
  end
end

local function AddRemainingCastInternalEvents(triggerUnit, t)
  if (triggerUnit == nil) then
    return
  end

  if Private.multiUnitUnits[triggerUnit] then
    for unit in pairs(Private.multiUnitUnits[triggerUnit]) do
      tinsert(t, "CAST_REMAINING_CHECK_" .. string.lower(unit))
    end
  else
    tinsert(t, "CAST_REMAINING_CHECK_" .. string.lower(triggerUnit))
  end
end

local function AddUnitEventForEvents(result, unit, event)
  if unit then
    if not result.unit_events then
      result.unit_events = {}
    end
    if not result.unit_events[unit] then
      result.unit_events[unit] = {}
    end
    tinsert(result.unit_events[unit], event)
  else
    if not result.events then
      result.events = {}
    end
    tinsert(result.events, event)
  end
end

local unitHelperFunctions = {
  UnitChangedForceEvents = function(trigger)
    local events = {}
    if Private.multiUnitUnits[trigger.unit] then
      for unit in pairs(Private.multiUnitUnits[trigger.unit]) do
        tinsert(events, {"UNIT_CHANGED_" .. unit, unit})
      end
    else
      if trigger.unit then
        tinsert(events, {"UNIT_CHANGED_" .. trigger.unit, trigger.unit})
      end
    end
    return events
  end,

  SpecificUnitCheck = function(trigger)
    if not trigger.use_specific_unit then
      return "local specificUnitCheck = true\n"
    end

    if trigger.unit == nil then
      return "local specificUnitCheck = false\n"
    end

    return string.format([=[
      local specificUnitCheck = UnitIsUnit(%q, unit)
    ]=], trigger.unit or "")
  end
}

Private.event_categories = {
  spell = {
    name = L["Spell"],
    default = "Cooldown Progress (Spell)"
  },
  item = {
    name = L["Item"],
    default = "Cooldown Progress (Item)"
  },
  unit = {
    name = L["Player/Unit Info"],
    default = "Health"
  },
  addons = {
    name = L["Other Addons"],
    default = "GTFO"
  },
  combatlog = {
    name = L["Combat Log"],
    default = "Combat Log",
  },
  event = {
    name = L["Other Events"],
    default = "Chat Message"
  },
  custom = {
    name = L["Custom"],
  }
}

Private.event_prototypes = {
  ["Unit Characteristics"] = {
    type = "unit",
    events = function(trigger)
      local unit = trigger.unit
      local result = {}
      AddUnitEventForEvents(result, unit, "UNIT_LEVEL")
      AddUnitEventForEvents(result, unit, "UNIT_FACTION")
      AddUnitEventForEvents(result, unit, "UNIT_NAME_UPDATE")
      AddUnitEventForEvents(result, unit, "UNIT_FLAGS")
      return result;
    end,
    internal_events = function(trigger)
      local unit = trigger.unit
      local result = {}
      AddUnitChangeInternalEvents(unit, result)
      if trigger.unitisunit then
        AddUnitChangeInternalEvents(trigger.unitisunit, result)
      end
      AddUnitRoleChangeInternalEvents(unit, result)
      return result
    end,
    force_events = unitHelperFunctions.UnitChangedForceEvents,
    name = L["Unit Characteristics"],
    init = function(trigger)
      trigger.unit = trigger.unit or "target";
      local ret = [=[
        unit = string.lower(unit)
        local smart = %s
        local extraUnit = %q;
        local name, realm = WeakAuras.UnitNameWithRealm(unit)
      ]=];

      ret = ret .. unitHelperFunctions.SpecificUnitCheck(trigger)

      return ret:format(trigger.unit == "group" and "true" or "false", trigger.unitisunit or "");
    end,
    statesParameter = "unit",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_cast",
        test = "true",
        store = true
      },
      {
        name = "unitisunit",
        display = L["Unit is Unit"],
        type = "unit",
        init = "UnitIsUnit(unit, extraUnit)",
        values = "actual_unit_types_with_specific",
        test = "unitisunit",
        store = true,
        conditionType = "bool",
        desc = function() return L["Can be used for e.g. checking if \"boss1target\" is the same as \"player\"."] end,
        enable = function(trigger) return not Private.multiUnitUnits[trigger.unit] end
      },
      {
        name = "name",
        display = L["Name"],
        type = "string",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "realm",
        display = L["Realm"],
        type = "string",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "namerealm",
        display = L["Unit Name/Realm"],
        type = "string",
        preamble = "local nameRealmChecker = WeakAuras.ParseNameCheck(%q)",
        test = "nameRealmChecker:Check(name, realm)",
        conditionType = "string",
        conditionPreamble = function(input)
          return WeakAuras.ParseNameCheck(input)
        end,
        conditionTest = function(state, needle, op, preamble)
          return preamble:Check(state.name, state.realm)
        end,
        operator_types = "none",
      },
      {
        name = "class",
        display = L["Class"],
        type = "select",
        init = "select(2, UnitClass(unit))",
        values = "class_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "classification",
        display = L["Classification"],
        type = "multiselect",
        init = "UnitClassification(unit)",
        values = "classification_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "role",
        display = L["Assigned Role"],
        type = "select",
        init = "UnitGroupRolesAssigned(unit)",
        values = "role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return WeakAuras.IsRetail() and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        end
      },
      {
        name = "raid_role",
        display = L["Assigned Role"],
        type = "select",
        init = "WeakAuras.UnitRaidRole(unit)",
        values = "raid_role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return (WeakAuras.IsClassic() or WeakAuras.IsBCC()) and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        end
      },
      {
        name = "ignoreSelf",
        display = L["Ignore Self"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "nameplate" or trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsUnit(\"player\", unit)"
      },
      {
        name = "ignoreDead",
        display = L["Ignore Dead"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsDeadOrGhost(unit)"
      },
      {
        name = "ignoreDisconnected",
        display = L["Ignore Disconnected"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "UnitIsConnected(unit)"
      },
      {
        name = "hostility",
        display = L["Hostility"],
        type = "select",
        init = "WeakAuras.GetPlayerReaction(unit)",
        values = "hostility_types",
        store = true,
        conditionType = "select",
      },
      {
        name = "character",
        display = L["Character Type"],
        type = "select",
        init = "UnitIsPlayer(unit) and 'player' or 'npc'",
        values = "character_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "level",
        display = L["Level"],
        type = "number",
        init = "UnitLevel(unit)",
        store = true,
        conditionType = "number"
      },
      {
        name = "npcId",
        display = L["Npc ID"],
        type = "string",
        store = true,
        conditionType = "string",
        test = "select(6, strsplit('-', UnitGUID(unit) or '')) == %q",
      },
      {
        name = "attackable",
        display = L["Attackable"],
        type = "tristate",
        init = "UnitCanAttack('player', unit)",
        store = true,
        conditionType = "bool"
      },
      {
        name = "inCombat",
        display = L["In Combat"],
        type = "tristate",
        init = "UnitAffectingCombat(unit)",
        store = true,
        conditionType = "bool"
      },
      {
        hidden = true,
        test = "WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck"
      }
    },
    automaticrequired = true
  },
  ["Faction Reputation"] = {
    type = "unit",
    canHaveDuration = false,
    events = {
      ["events"] = {
        "UPDATE_FACTION",
      }
    },
    internal_events = {"WA_DELAYED_PLAYER_ENTERING_WORLD"},
    force_events = "UPDATE_FACTION",
    name = L["Faction Reputation"],
    init = function(trigger)
      local ret = [=[
        local factionID = %q
        local name, description, standingId, bottomValue, topValue, earnedValue, _, _, isHeader, _, _, _, _, factionID = GetFactionInfoByID(factionID)
        local standing
        if tonumber(standingId) then
           standing = getglobal("FACTION_STANDING_LABEL"..standingId)
        end
      ]=]
      return ret:format(trigger.factionID or 0)
    end,
    statesParameter = "one",
    args = {
      {
        name = "factionID",
        display = L["Faction"],
        required = true,
        type = "select",
        values = function()
          local ret = {}
          for i = 1, GetNumFactions() do
            local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
            if not isHeader and factionID then
              ret[factionID] = name
            end
          end
          return ret
        end,
        conditionType = "select",
        test = "true"
      },
      {
        name = "name",
        display = L["Faction Name"],
        type = "string",
        store = "true",
        hidden = "true",
        init = "name",
        test = "true"
      },
      {
        name = "total",
        display = L["Total"],
        type = "number",
        store = true,
        init = [[topValue - bottomValue]],
        hidden = true,
        test = "true",
        conditionType = "number",
      },
      {
        name = "value",
        display = L["Value"],
        type = "number",
        store = true,
        init = [[earnedValue - bottomValue]],
        hidden = true,
        test = "true",
        conditionType = "number",
      },
      {
        name = "standingId",
        display = L["Standing"],
        type = "select",
        values = function()
          local ret = {}
          for i = 0, 8 do
            ret[i] = getglobal("FACTION_STANDING_LABEL"..i)
          end
          return ret
        end,
        init = "standingId",
        store = "true",
        conditionType = "select",
      },
      {
        name = "standing",
        display = L["Standing"],
        type = "string",
        init = "standing",
        store = "true",
        hidden = "true",
        test = "true"
      },
      {
        name = "progressType",
        hidden = true,
        init = "'static'",
        store = true,
        test = "true"
      },
    },
    automaticrequired = true
  },
  ["Experience"] = {
    type = "unit",
    canHaveDuration = false,
    events = {
      ["events"] = {
        "PLAYER_XP_UPDATE",
      }
    },
    internal_events = {"WA_DELAYED_PLAYER_ENTERING_WORLD"},
    force_events = "PLAYER_XP_UPDATE",
    name = L["Player Experience"],
    init = function(trigger)
      return ""
    end,
    statesParameter = "one",
    args = {
      {
        name = "level",
        display = L["Level"],
        required = false,
        type = "number",
        store = true,
        init = [[UnitLevel("player")]],
        conditionType = "number",
      },
      {
        name = "currentXP",
        display = L["Current Experience"],
        type = "number",
        store = true,
        init = [[UnitXP("player")]],
        conditionType = "number",
      },
      {
        name = "totalXP",
        display = L["Total Experience"],
        type = "number",
        store = true,
        init = [[UnitXPMax("player")]],
        conditionType = "number",
      },
      {
        name = "value",
        type = "number",
        store = true,
        init = "currentXP",
        hidden = true,
        test = "true",
      },
      {
        name = "total",
        type = "number",
        store = true,
        init = "totalXP",
        hidden = true,
        test = "true",
      },
      {
        name = "progressType",
        hidden = true,
        init = "'static'",
        store = true,
        test = "true"
      },
      {
        name = "percentXP",
        display = L["Experience (%)"],
        type = "number",
        init = "total ~= 0 and (value / total) * 100 or nil",
        store = true,
        conditionType = "number"
      },
      {
        name = "showRested",
        display = L["Show Rested Overlay"],
        type = "toggle",
        test = "true",
        reloadOptions = true,
      },
      {
        name = "restedXP",
        display = L["Rested Experience"],
        init = [[GetXPExhaustion() or 0]],
        type = "number",
        store = true,
        conditionType = "number",
      },
      {
        name = "percentrested",
        display = L["Rested Experience (%)"],
        init = "total ~= 0 and (restedXP / total) * 100 or nil",
        type = "number",
        store = true,
        conditionType = "number",
      },
    },
    overlayFuncs = {
      {
        name = L["Rested"],
        func = function(trigger, state)
          return "forward", state.restedXP
        end,
        enable = function(trigger)
          return trigger.use_showRested
        end
      },
    },
    automaticrequired = true
  },
  ["Health"] = {
    type = "unit",
    canHaveDuration = true,
    events = function(trigger)
      local unit = trigger.unit
      local result = {}
      AddUnitEventForEvents(result, unit, "UNIT_HEALTH")
      AddUnitEventForEvents(result, unit, "UNIT_NAME_UPDATE")
      if WeakAuras.IsRetail() then
        if trigger.use_showAbsorb then
          AddUnitEventForEvents(result, unit, "UNIT_ABSORB_AMOUNT_CHANGED")
        end
        if trigger.use_showIncomingHeal then
          AddUnitEventForEvents(result, unit, "UNIT_HEAL_PREDICTION")
        end
      end
      if trigger.use_ignoreDead or trigger.use_ignoreDisconnected then
        AddUnitEventForEvents(result, unit, "UNIT_FLAGS")
      end
      return result
    end,
    internal_events = function(trigger)
      local unit = trigger.unit
      local result = {}
      AddUnitChangeInternalEvents(unit, result)
      AddUnitRoleChangeInternalEvents(unit, result)
      return result
    end,
    force_events = unitHelperFunctions.UnitChangedForceEvents,
    name = L["Health"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        unit = string.lower(unit)
        local name, realm = WeakAuras.UnitNameWithRealm(unit)
        local smart = %s
      ]=];

      ret = ret .. unitHelperFunctions.SpecificUnitCheck(trigger)

      return ret:format(trigger.unit == "group" and "true" or "false");
    end,
    statesParameter = "unit",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_cast",
        test = "true",
        store = true
      },
      {
        name = "health",
        display = L["Health"],
        type = "number",
        init = "UnitHealth(unit)",
        store = true,
        conditionType = "number"
      },
      {
        name = "value",
        hidden = true,
        init = "health",
        store = true,
        test = "true"
      },
      {
        name = "total",
        hidden = true,
        init = "UnitHealthMax(unit)",
        store = true,
        test = "true"
      },
      {
        name = "progressType",
        hidden = true,
        init = "'static'",
        store = true,
        test = "true"
      },
      {
        name = "percenthealth",
        display = L["Health (%)"],
        type = "number",
        init = "total ~= 0 and (value / total) * 100 or nil",
        store = true,
        conditionType = "number"
      },
      {
        name = "showAbsorb",
        display = L["Show Absorb"],
        type = "toggle",
        test = "true",
        reloadOptions = true,
        enable = WeakAuras.IsRetail(),
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "absorbMode",
        display = L["Absorb Display"],
        type = "select",
        test = "true",
        values = "absorb_modes",
        required = true,
        enable = function(trigger) return WeakAuras.IsRetail() and trigger.use_showAbsorb end,
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "showIncomingHeal",
        display = L["Show Incoming Heal"],
        type = "toggle",
        test = "true",
        reloadOptions = true,
        enable = WeakAuras.IsRetail(),
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "absorb",
        type = "number",
        display = L["Absorb"],
        init = "UnitGetTotalAbsorbs(unit)",
        store = true,
        conditionType = "number",
        enable = function(trigger) return WeakAuras.IsRetail() and trigger.use_showAbsorb end,
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "healprediction",
        type = "number",
        display = L["Incoming Heal"],
        init = "UnitGetIncomingHeals(unit)",
        store = true,
        conditionType = "number",
        enable = function(trigger) return WeakAuras.IsRetail() and trigger.use_showIncomingHeal end,
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "name",
        display = L["Unit Name"],
        type = "string",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "realm",
        display = L["Realm"],
        type = "string",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "namerealm",
        display = L["Unit Name/Realm"],
        type = "string",
        preamble = "local nameRealmChecker = WeakAuras.ParseNameCheck(%q)",
        test = "nameRealmChecker:Check(name, realm)",
        conditionType = "string",
        conditionPreamble = function(input)
          return WeakAuras.ParseNameCheck(input)
        end,
        conditionTest = function(state, needle, op, preamble)
          return preamble:Check(state.name, state.realm)
        end,
        operator_types = "none",
        desc = constants.nameRealmFilterDesc,
      },
      {
        name = "npcId",
        display = L["Npc ID"],
        type = "string",
        store = true,
        conditionType = "string",
        test = "select(6, strsplit('-', UnitGUID(unit) or '')) == %q",
      },
      {
        name = "class",
        display = L["Class"],
        type = "select",
        init = "select(2, UnitClass(unit))",
        values = "class_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "role",
        display = L["Assigned Role"],
        type = "select",
        init = "UnitGroupRolesAssigned(unit)",
        values = "role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return WeakAuras.IsRetail() and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        end
      },
      {
        name = "raid_role",
        display = L["Assigned Role"],
        type = "select",
        init = "WeakAuras.UnitRaidRole(unit)",
        values = "raid_role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return (WeakAuras.IsClassic() or WeakAuras.IsBCC()) and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        end
      },
      {
        name = "ignoreSelf",
        display = L["Ignore Self"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "nameplate" or trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsUnit(\"player\", unit)"
      },
      {
        name = "ignoreDead",
        display = L["Ignore Dead"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsDeadOrGhost(unit)"
      },
      {
        name = "ignoreDisconnected",
        display = L["Ignore Disconnected"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "UnitIsConnected(unit)"
      },
      {
        name = "nameplateType",
        display = L["Nameplate Type"],
        type = "select",
        init = "WeakAuras.GetPlayerReaction(unit)",
        values = "hostility_types",
        conditionType = "select",
        store = true,
        enable = function(trigger)
          return trigger.unit == "nameplate"
        end
      },
      {
        name = "name",
        hidden = true,
        init = "UnitName(unit)",
        test = "true"
      },
      {
        hidden = true,
        test = "WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck"
      }
    },
    overlayFuncs = {
      {
        name = L["Absorb"],
        func = function(trigger, state)
          local absorb = state.absorb
          if (trigger.absorbMode == "OVERLAY_FROM_START") then
            return 0, absorb;
          else
            return "forward", absorb;
          end
        end,
        enable = function(trigger)
          return WeakAuras.IsRetail() and trigger.use_showAbsorb;
        end
      },
      {
        name = L["Incoming Heal"],
        func = function(trigger, state)
          if (trigger.use_showIncomingHeal) then
            local heal = state.healprediction;
            return "forward", heal;
          end
        end,
        enable = function(trigger)
          return WeakAuras.IsRetail() and trigger.use_showIncomingHeal;
        end
      }
    },
    automaticrequired = true
  },
  ["Power"] = {
    type = "unit",
    canHaveDuration = true,
    events = function(trigger)
      local unit = trigger.unit
      local result = {}
      AddUnitEventForEvents(result, unit, "UNIT_POWER_FREQUENT")
      AddUnitEventForEvents(result, unit, "UNIT_MAXPOWER")
      AddUnitEventForEvents(result, unit, "UNIT_DISPLAYPOWER")
      AddUnitEventForEvents(result, unit, "UNIT_NAME_UPDATE")

      -- The api for spell power costs is not meant to be for other units
      if trigger.use_showCost and trigger.unit == "player" then
        AddUnitEventForEvents(result, "player", "UNIT_SPELLCAST_START")
        AddUnitEventForEvents(result, "player", "UNIT_SPELLCAST_STOP")
        AddUnitEventForEvents(result, "player", "UNIT_SPELLCAST_FAILED")
        AddUnitEventForEvents(result, "player", "UNIT_SPELLCAST_SUCCEEDED")
      end
      if trigger.use_powertype and trigger.powertype == 99 then
        AddUnitEventForEvents(result, unit, "UNIT_ABSORB_AMOUNT_CHANGED")
      end
      if trigger.use_ignoreDead or trigger.use_ignoreDisconnected then
        AddUnitEventForEvents(result, unit, "UNIT_FLAGS")
      end

      if WeakAuras.IsRetail()
          and trigger.use_powertype and trigger.powertype == 4
      then
        AddUnitEventForEvents(result, unit, "UNIT_POWER_POINT_CHARGE")
      end
      return result;
    end,
    internal_events = function(trigger)
      local unit = trigger.unit
      local result = {}
      AddUnitChangeInternalEvents(unit, result)
      AddUnitRoleChangeInternalEvents(unit, result)

      return result
    end,
    force_events = unitHelperFunctions.UnitChangedForceEvents,
    name = L["Power"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        unit = string.lower(unit)
        local name, realm = WeakAuras.UnitNameWithRealm(unit)
        local smart = %s
        local powerType = %s;
        local unitPowerType = UnitPowerType(unit);
        local powerTypeToCheck = powerType or unitPowerType;
        local powerThirdArg = WeakAuras.UseUnitPowerThirdArg(powerTypeToCheck);
        if not WeakAuras.IsRetail() and powerType == 99 then powerType = 1 end
      ]=];
      ret = ret:format(trigger.unit == "group" and "true" or "false", trigger.use_powertype and trigger.powertype or "nil");

      ret = ret .. unitHelperFunctions.SpecificUnitCheck(trigger)

      if (trigger.use_powertype and trigger.powertype == 99 and WeakAuras.IsRetail()) then
        ret = ret ..[[
          local UnitPower = WeakAuras.UnitStagger
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
          if (event == "UNIT_DISPLAYPOWER") then
            local cost = WeakAuras.GetSpellCost(powerTypeToCheck)
            if state.cost ~= cost then
              state.cost = cost
              state.changed = true
            end
          elseif ( (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_SUCCEEDED") and unit == "player") then
            local cost = WeakAuras.GetSpellCost(powerTypeToCheck)
            if state.cost ~= cost then
              state.cost = cost
              state.changed = true
            end
          end
        ]]
      end
      if WeakAuras.IsRetail()
          and trigger.unit == 'player' and trigger.use_powertype and trigger.powertype == 4
      then
        ret = ret .. [[
          local chargedComboPoint = GetUnitChargedPowerPoints('player')
          chargedComboPoint = chargedComboPoint and chargedComboPoint[1]
          if state.chargedComboPoint ~= chargedComboPoint then
            state.chargedComboPoint = chargedComboPoint
            state.changed = true
          end
        ]]
      end

      return ret
    end,
    statesParameter = "unit",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_cast",
        test = "true",
        store = true
      },
      {
        name = "powertype",
        display = L["Power Type"],
        type = "select",
        values = function() return not WeakAuras.IsRetail() and Private.power_types or Private.power_types_with_stagger end,
        init = "unitPowerType",
        test = "true",
        store = true,
        conditionType = "select",
        reloadOptions = true
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
        name = "showChargedComboPoints",
        display = WeakAuras.newFeatureString .. L["Overlay Charged Combo Points"],
        type = "toggle",
        test = "true",
        reloadOptions = true,
        enable = function(trigger)
          return WeakAuras.IsRetail() and trigger.unit == 'player' and trigger.use_powertype and trigger.powertype == 4
        end,
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "chargedComboPoint",
        type = "number",
        display = WeakAuras.newFeatureString .. L["Charged Combo Point"],
        store = true,
        conditionType = "number",
        enable = function(trigger)
          return WeakAuras.IsRetail() and trigger.unit == 'player'and trigger.use_powertype and trigger.powertype == 4
        end,
        hidden = true,
        test = "true"
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
        init = not WeakAuras.IsRetail() and "powerType == 4 and GetComboPoints(unit, unit .. '-target') or UnitPower(unit, powerType, powerThirdArg)"
                                     or "UnitPower(unit, powerType, powerThirdArg) / WeakAuras.UnitPowerDisplayMod(powerTypeToCheck)",
        store = true,
        conditionType = "number",
      },
      {
        name = "value",
        hidden = true,
        init = "power",
        store = true,
        test = "true"
      },
      {
        name = "total",
        hidden = true,
        init = not WeakAuras.IsRetail() and "powerType == 4 and (math.max(1, UnitPowerMax(unit, 14))) or math.max(1, UnitPowerMax(unit, powerType, powerThirdArg))"
                                      or "math.max(1, UnitPowerMax(unit, powerType, powerThirdArg)) / WeakAuras.UnitPowerDisplayMod(powerTypeToCheck)",
        store = true,
        test = "true"
      },
      {
        name = "stacks",
        hidden = true,
        init = "power",
        store = true,
        test = "true"
      },
      {
        name = "progressType",
        hidden = true,
        init = "'static'",
        store = true,
        test = "true"
      },
      {
        name = "percentpower",
        display = L["Power (%)"],
        type = "number",
        init = "total ~= 0 and (value / total) * 100 or nil",
        store = true,
        conditionType = "number"
      },
      {
        name = "name",
        display = L["Unit Name"],
        type = "string",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "realm",
        display = L["Realm"],
        type = "string",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "namerealm",
        display = L["Unit Name/Realm"],
        type = "string",
        preamble = "local nameRealmChecker = WeakAuras.ParseNameCheck(%q)",
        test = "nameRealmChecker:Check(name, realm)",
        conditionType = "string",
        conditionPreamble = function(input)
          return WeakAuras.ParseNameCheck(input)
        end,
        conditionTest = function(state, needle, op, preamble)
          return preamble:Check(state.name, state.realm)
        end,
        operator_types = "none",
        desc = constants.nameRealmFilterDesc,
      },
      {
        name = "npcId",
        display = L["Npc ID"],
        type = "string",
        store = true,
        conditionType = "string",
        test = "select(6, strsplit('-', UnitGUID(unit) or '')) == %q",
      },
      {
        name = "class",
        display = L["Class"],
        type = "select",
        init = "select(2, UnitClass(unit))",
        values = "class_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "role",
        display = L["Assigned Role"],
        type = "select",
        init = "UnitGroupRolesAssigned(unit)",
        values = "role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return WeakAuras.IsRetail() and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        end
      },
      {
        name = "raid_role",
        display = L["Assigned Role"],
        type = "select",
        init = "WeakAuras.UnitRaidRole(unit)",
        values = "raid_role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return not WeakAuras.IsRetail() and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        end
      },
      {
        name = "ignoreSelf",
        display = L["Ignore Self"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "nameplate" or trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsUnit(\"player\", unit)"
      },
      {
        name = "ignoreDead",
        display = L["Ignore Dead"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsDeadOrGhost(unit)"
      },
      {
        name = "ignoreDisconnected",
        display = L["Ignore Disconnected"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "UnitIsConnected(unit)"
      },
      {
        name = "nameplateType",
        display = L["Nameplate Type"],
        type = "select",
        init = "WeakAuras.GetPlayerReaction(unit)",
        values = "hostility_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return trigger.unit == "nameplate"
        end
      },
      {
        hidden = true,
        test = "WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck"
      }
    },
    overlayFuncs = {
      {
        name = L["Spell Cost"],
        func = function(trigger, state)
          return "back", type(state.cost) == "number" and state.cost;
        end,
        enable = function(trigger)
          return trigger.use_showCost and (not trigger.use_powertype or trigger.powertype ~= 99) and trigger.unit == "player";
        end
      },
      {
        name = L["Charged Combo Point"],
        func = function(trigger, state)
          if type(state.chargedComboPoint) == "number" then
            return state.chargedComboPoint - 1, state.chargedComboPoint
          end
          return 0, 0
        end,
        enable = function(trigger)
          return WeakAuras.IsRetail() and trigger.unit == 'player' and trigger.use_powertype and trigger.powertype == 4 and trigger.use_showChargedComboPoints
        end,
      }
    },
    automaticrequired = true
  },
  ["Alternate Power"] = {
    type = "unit",
    canHaveDuration = true,
    events = function(trigger)
      local unit = trigger.unit
      local result = {}
      AddUnitEventForEvents(result, unit, "UNIT_POWER_FREQUENT")
      AddUnitEventForEvents(result, unit, "UNIT_NAME_UPDATE")
      if trigger.use_ignoreDead or trigger.use_ignoreDisconnected then
        AddUnitEventForEvents(result, unit, "UNIT_FLAGS")
      end
      AddUnitEventForEvents(result, unit, "UNIT_POWER_BAR_SHOW")
      return result
    end,
    internal_events = function(trigger)
      local unit = trigger.unit
      local result = { }
      AddUnitChangeInternalEvents(unit, result)
      AddUnitRoleChangeInternalEvents(unit, result)
      return result
    end,
    force_events = unitHelperFunctions.UnitChangedForceEvents,
    name = L["Alternate Power"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        unit = string.lower(unit)
        local unitname, realm = WeakAuras.UnitNameWithRealm(unit)
        local smart = %s
      ]=]

      ret = ret .. unitHelperFunctions.SpecificUnitCheck(trigger)

      return ret:format(trigger.unit == "group" and "true" or "false");
    end,
    statesParameter = "unit",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = "actual_unit_types_cast",
        test = "true",
        store = true
      },
      {
        name = "power",
        display = L["Alternate Power"],
        type = "number",
        init = "UnitPower(unit, 10)"
      },
      {
        name = "value",
        hidden = true,
        init = "power",
        store = true,
        test = "true"
      },
      {
        name = "total",
        hidden = true,
        init = "UnitPowerMax(unit, 10)",
        store = true,
        test = "true"
      },
      {
        name = "progressType",
        hidden = true,
        init = "'static'",
        store = true,
        test = "true"
      },
      {
        name = "name",
        hidden = true,
        init = "GetUnitPowerBarStrings(unit)",
        store = true,
        test = "true"
      },
      {
        name = "unitname",
        display = L["Unit Name"],
        type = "string",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "unitrealm",
        display = L["Realm"],
        type = "string",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "namerealm",
        display = L["Unit Name/Realm"],
        type = "string",
        preamble = "local nameRealmChecker = WeakAuras.ParseNameCheck(%q)",
        test = "nameRealmChecker:Check(unitname, unitrealm)",
        conditionType = "string",
        conditionPreamble = function(input)
          return WeakAuras.ParseNameCheck(input)
        end,
        conditionTest = function(state, needle, op, preamble)
          return preamble:Check(state.unitname, state.unitrealm)
        end,
        operator_types = "none",
        desc = constants.nameRealmFilterDesc,
      },
      {
        name = "icon",
        hidden = true,
        init = "GetUnitPowerBarTextureInfo(unit, 1)",
        store = true,
        test = "true"
      },
      {
        name = "class",
        display = L["Class"],
        type = "select",
        init = "select(2, UnitClass(unit))",
        values = "class_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "role",
        display = L["Assigned Role"],
        type = "select",
        init = "UnitGroupRolesAssigned(unit)",
        values = "role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return WeakAuras.IsRetail() and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        end
      },
      {
        name = "raid_role",
        display = L["Assigned Role"],
        type = "select",
        init = "WeakAuras.UnitRaidRole(unit)",
        values = "raid_role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return not WeakAuras.IsRetail() and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        end
      },
      {
        name = "ignoreSelf",
        display = L["Ignore Self"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "nameplate" or trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsUnit(\"player\", unit)"
      },
      {
        name = "ignoreDead",
        display = L["Ignore Dead"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsDeadOrGhost(unit)"
      },
      {
        name = "ignoreDisconnected",
        display = L["Ignore Disconnected"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "UnitIsConnected(unit)"
      },
      {
        name = "nameplateType",
        display = L["Nameplate Type"],
        type = "select",
        init = "WeakAuras.GetPlayerReaction(unit)",
        values = "hostility_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return trigger.unit == "nameplate"
        end
      },
      {
        hidden = true,
        test = "name and WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck"
      }
    },
    automaticrequired = true
  },
  ["Combat Log"] = {
    type = "combatlog",
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
        store = true,
        display = L["Source GUID"]
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
        conditionType = "select",
        conditionTest = function(state, needle, op)
          return state and state.show and ((state.sourceGUID or '') == (UnitGUID(needle) or '')) == (op == "==")
        end
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
        display = L["Source Affiliation"],
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
        name = "sourceFlags2",
        display = L["Source Reaction"],
        type = "select",
        values = "combatlog_flags_check_reaction",
        test = "WeakAuras.CheckCombatLogFlagsReaction(sourceFlags, %q)",
        conditionType = "select",
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckCombatLogFlagsReaction(state.sourceFlags, needle);
        end
      },
      {
        name = "sourceFlags3",
        display = L["Source Object Type"],
        type = "select",
        values = "combatlog_flags_check_object_type",
        test = "WeakAuras.CheckCombatLogFlagsObjectType(sourceFlags, %q)",
        conditionType = "select",
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckCombatLogFlagsObjectType(state.sourceFlags, needle);
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
        store = true,
        display = L["Destination GUID"]
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
        conditionType = "select",
        conditionTest = function(state, needle, op)
          return state and state.show and ((state.destGUID or '') == (UnitGUID(needle) or '')) == (op == "==")
        end
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
        display = L["Destination Affiliation"],
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
      {
        name = "destFlags2",
        display = L["Destination Reaction"],
        type = "select",
        values = "combatlog_flags_check_reaction",
        test = "WeakAuras.CheckCombatLogFlagsReaction(destFlags, %q)",
        conditionType = "select",
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckCombatLogFlagsReaction(state.destFlags, needle);
        end,
        enable = function(trigger)
          return not (trigger.subeventPrefix == "SPELL" and trigger.subeventSuffix == "_CAST_START");
        end,
      },
      {
        name = "destFlags3",
        display = L["Destination Object Type"],
        type = "select",
        values = "combatlog_flags_check_object_type",
        test = "WeakAuras.CheckCombatLogFlagsObjectType(destFlags, %q)",
        conditionType = "select",
        conditionTest = function(state, needle)
          return state and state.show and WeakAuras.CheckCombatLogFlagsObjectType(state.destFlags, needle);
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
          return trigger.subeventPrefix and (trigger.subeventPrefix:find("SPELL") or trigger.subeventPrefix == "RANGE" or trigger.subeventPrefix:find("DAMAGE"))
        end,
        test = WeakAuras.IsClassic() and "GetSpellInfo(%q) == spellName" or nil,
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
          return trigger.subeventSuffix and trigger.subeventPrefix and (trigger.subeventSuffix == "_ABSORBED" or trigger.subeventSuffix == "_DAMAGE" or trigger.subeventSuffix == "_HEAL" or trigger.subeventSuffix == "_ENERGIZE" or trigger.subeventSuffix == "_DRAIN" or trigger.subeventSuffix == "_LEECH" or trigger.subeventPrefix:find("DAMAGE"))
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
          return trigger.subeventSuffix and trigger.subeventPrefix and (
                 trigger.subeventSuffix == "_DAMAGE" or trigger.subeventPrefix == "DAMAGE_SHIELD" or trigger.subeventPrefix == "DAMAGE_SPLIT"
                 or trigger.subeventSuffix == "_MISSED" or trigger.subeventPrefix == "DAMAGE_SHIELD_MISSED")
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
        init = "(not WeakAuras.IsRetail() and spellName and select(3, GetSpellInfo(spellName))) or (WeakAuras.IsRetail() and spellId and select(3, GetSpellInfo(spellId))) or 'Interface\\\\Icons\\\\INV_Misc_QuestionMark'",
        store = true,
        test = "true"
      }
    },
    timedrequired = true
  },
  ["Spell Activation Overlay"] = {
    type = "spell",
    events = {
    },
    internal_events = {
      "WA_UPDATE_OVERLAY_GLOW"
    },
    force_events = "WA_UPDATE_OVERLAY_GLOW",
    name = L["Spell Activation Overlay Glow"],
    loadFunc = function(trigger)
      if (trigger.use_exact_spellName) then
        WeakAuras.WatchSpellActivation(tonumber(trigger.spellName));
      else
        WeakAuras.WatchSpellActivation(type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName);
      end
    end,
    init = function(trigger)
      local spellName
      if (trigger.use_exact_spellName) then
        spellName = trigger.spellName
        return string.format("local spellName = %s\n", tonumber(spellName) or "nil");
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName;
        return string.format("local spellName = %q\n", spellName or "");
      end
    end,
    args = {
      {
        name = "spellName",
        required = true,
        display = L["Spell"],
        type = "spell",
        test = "true",
        showExactOption = true
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
    type = "spell",
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
    name = L["Cooldown/Charges/Count"],
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
        local startTime, duration, gcdCooldown, readyTime = WeakAuras.GetSpellCooldown(spellname, ignoreRuneCD, showgcd, ignoreSpellKnown, track);
        local charges, maxCharges, spellCount, chargeGainTime, chargeLostTime = WeakAuras.GetSpellCharges(spellname, ignoreSpellKnown);
        local stacks = maxCharges and maxCharges ~= 1 and charges or (spellCount and spellCount > 0 and spellCount) or nil;
        if (charges == nil) then
          -- Use fake charges for spells that use GetSpellCooldown
          charges = (duration == 0 or gcdCooldown) and 1 or 0;
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
              WeakAuras.ScheduleScan(expirationTime - remainingCheck);
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
              text = text .. L["Disabled Spell Known Check"]
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
        display = L["Disable Spell Known Check"],
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
        display = L["Charges"],
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
        hidden = true,
        name = "readyTime",
        display = L["Since Ready"],
        conditionType = "elapsedTimer",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        name = "chargeGainTime",
        display = L["Since Charge Gain"],
        conditionType = "elapsedTimer",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        name = "chargeLostTime",
        display = L["Since Charge Lost"],
        conditionType = "elapsedTimer",
        store = true,
        test = "true"
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
    type = "spell",
    events = {},
    internal_events = {
      "SPELL_COOLDOWN_READY",
    },
    name = L["Cooldown Ready Event"],
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
  ["Charges Changed"] = {
    type = "spell",
    events = {},
    internal_events = {
      "SPELL_CHARGES_CHANGED",
    },
    name = L["Charges Changed Event"],
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
      end
      spellName = string.format("%q", spellName or "");
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
    type = "item",
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
            WeakAuras.ScheduleScan(expirationTime - remainingCheck);
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
  },
  ["Cooldown Progress (Equipment Slot)"] = {
    type = "item",
    events = {
      ["unit_events"] = {
        ["player"] = {"UNIT_INVENTORY_CHANGED"}
      }
    },
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
    name = L["Cooldown Progress (Slot)"],
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
            WeakAuras.ScheduleScan(expirationTime - remainingCheck);
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
    stacksFunc = function(trigger)
      local count = GetInventoryItemCount("player", trigger.itemSlot or 0)
      if ((count == 1) and (not GetInventoryItemTexture("player", trigger.itemSlot or 0))) then
        count = 0
      end
      return count
    end,
    iconFunc = function(trigger)
      return GetInventoryItemTexture("player", trigger.itemSlot or 0) or "Interface\\Icons\\INV_Misc_QuestionMark";
    end,
    automaticrequired = true,
  },
  ["Cooldown Ready (Item)"] = {
    type = "item",
    events = {},
    internal_events = {
      "ITEM_COOLDOWN_READY",
    },
    name = L["Cooldown Ready Event (Item)"],
    loadFunc = function(trigger)
      trigger.itemName = trigger.itemName or 0;
      WeakAuras.WatchItemCooldown(trigger.itemName);
    end,
    init = function(trigger)
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
    type = "item",
    events = {},
    internal_events = {
      "ITEM_SLOT_COOLDOWN_READY"
    },
    name = L["Cooldown Ready Event (Slot)"],
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
      local item = GetInventoryItemID("player", trigger.itemSlot or 0);
      if (item) then
        return GetItemInfo(item)
      else
        return ""
      end
    end,
    iconFunc = function(trigger)
      return GetInventoryItemTexture("player", trigger.itemSlot or 0) or "Interface\\Icons\\INV_Misc_QuestionMark";
    end,
    hasItemID = true,
    timedrequired = true
  },
  ["GTFO"] = {
    type = "addons",
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
    type = "addons",
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
    type = "addons",
    events = {},
    internal_events = {
      "DBM_TimerStart", "DBM_TimerStop", "DBM_TimerStopAll", "DBM_TimerUpdate", "DBM_TimerForce", "DBM_TimerResume", "DBM_TimerPause"
    },
    force_events = "DBM_TimerForce",
    name = L["DBM Timer"],
    canHaveDuration = "timed",
    triggerFunction = function(trigger)
      WeakAuras.RegisterDBMCallback("DBM_TimerStart")
      WeakAuras.RegisterDBMCallback("DBM_TimerStop")
      WeakAuras.RegisterDBMCallback("DBM_TimerPause")
      WeakAuras.RegisterDBMCallback("DBM_TimerResume")
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
            if event == "DBM_TimerStart"
            or event == "DBM_TimerPause"
            or event == "DBM_TimerResume"
            then
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
  },
  -- BigWigs
  ["BigWigs Message"] = {
    type = "addons",
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
    type = "addons",
    events = {},
    internal_events = {
      "BigWigs_StartBar", "BigWigs_StopBar", "BigWigs_Timer_Update", "BigWigs_PauseBar", "BigWigs_ResumeBar"
    },
    force_events = "BigWigs_Timer_Force",
    name = L["BigWigs Timer"],
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
            if event == "BigWigs_StartBar"
            or event == "BigWigs_PauseBar"
            or event == "BigWigs_ResumeBar"
            then
              if WeakAuras.BigWigsTimerMatches(id, triggerText, triggerTextOperator, triggerSpellId, triggerCount, triggerCast) then
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
                if WeakAuras.BigWigsTimerMatches(id, triggerText, triggerTextOperator, triggerSpellId, triggerCount, triggerCast) then
                  copyOrSchedule(bar, id)
                end
              end
            elseif event == "BigWigs_Timer_Force" then
              wipe(states)
              for id, bar in pairs(WeakAuras.GetAllBigWigsTimers()) do
                if WeakAuras.BigWigsTimerMatches(id, triggerText, triggerTextOperator, triggerSpellId, triggerCount, triggerCast) then
                  copyOrSchedule(bar, id)
                end
              end
            end
          else
            if event == "BigWigs_StartBar" then
              if extendTimer ~= 0 then
                if WeakAuras.BigWigsTimerMatches(id, triggerText, triggerTextOperator, triggerSpellId, triggerCount, triggerCast) then
                  local bar = WeakAuras.GetBigWigsTimerById(id)
                  WeakAuras.ScheduleBigWigsCheck(bar.expirationTime + extendTimer)
                end
              end
            end
            local bar = WeakAuras.GetBigWigsTimer(triggerText, triggerTextOperator, triggerSpellId, extendTimer, triggerCount, triggerCast)
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
    type = "spell",
    events = {},
    internal_events = {
      "GCD_START",
      "GCD_CHANGE",
      "GCD_END",
      "GCD_UPDATE",
      "WA_DELAYED_PLAYER_ENTERING_WORLD"
    },
    force_events = "GCD_UPDATE",
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
  },
  ["Swing Timer"] = {
    type = "unit",
    events = {},
    internal_events = {
      "SWING_TIMER_START",
      "SWING_TIMER_CHANGE",
      "SWING_TIMER_END",
      "SWING_TIMER_UPDATE"
    },
    force_events = "SWING_TIMER_UPDATE",
    name = L["Swing Timer"],
    loadFunc = function()
      WeakAuras.InitSwingTimer();
    end,
    init = function(trigger)
      local ret = [=[
        local inverse = %s;
        local hand = %q;
        local triggerRemaining = %s
        local duration, expirationTime, name, icon = WeakAuras.GetSwingTimerInfo(hand)
        local remaining = expirationTime and expirationTime - GetTime()
        local remainingCheck = not triggerRemaining or remaining and remaining %s triggerRemaining

        if triggerRemaining and remaining and remaining >= triggerRemaining and remaining > 0 then
          WeakAuras.ScheduleScan(expirationTime - triggerRemaining, "SWING_TIMER_UPDATE")
        end
      ]=];
      return ret:format(
        (trigger.use_inverse and "true" or "false"),
        trigger.hand or "main",
        trigger.use_remaining and tonumber(trigger.remaining or 0) or "nil",
        trigger.remaining_operator or "<"
      );
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
        name = "duration",
        hidden = true,
        init = "duration",
        test = "true",
        store = true
      },
      {
        name = "expirationTime",
        init = "expirationTime",
        hidden = true,
        test = "true",
        store = true
      },
      {
        name = "progressType",
        hidden = true,
        init = "'timed'",
        test = "true",
        store = true
      },
      {
        name = "name",
        hidden = true,
        init = "spell",
        test = "true",
        store = true
      },
      {
        name = "icon",
        hidden = true,
        init = "icon or 'Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon'",
        test = "true",
        store = true
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return not trigger.use_inverse end,
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
      },
      {
        hidden = true,
        test = "remainingCheck"
      }
    },
    automaticrequired = true,
    canHaveDuration = true,
    statesParameter = "one"
  },
  ["Action Usable"] = {
    type = "spell",
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
        local startTime, duration, gcdCooldown, readyTime = WeakAuras.GetSpellCooldown(spellName);
        local charges, _, spellCount, chargeGainTime, chargeLostTime = WeakAuras.GetSpellCharges(spellName);
        if (charges == nil) then
          charges = (duration == 0 or gcdCooldown) and 1 or 0;
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
        hidden = true,
        name = "readyTime",
        display = L["Since Ready"],
        conditionType = "elapsedTimer",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        name = "chargeGainTime",
        display = L["Since Charge Gain"],
        conditionType = "elapsedTimer",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        name = "chargeLostTime",
        display = L["Since Charge Lost"],
        conditionType = "elapsedTimer",
        store = true,
        test = "true"
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
    type = "unit",
    events = function()
      local events
      if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
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
    force_events = WeakAuras.IsRetail() and "PLAYER_TALENT_UPDATE" or "CHARACTER_POINTS_CHANGED",
    name = L["Talent Known"],
    init = function(trigger)
      local inverse = trigger.use_inverse;
      if (trigger.use_talent) then
        -- Single selection
        local index = trigger.talent and trigger.talent.single;
        local tier, column
        if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
          tier = index and ceil(index / MAX_NUM_TALENTS)
          column = index and ((index - 1) % MAX_NUM_TALENTS + 1)
        else
          tier = index and ceil(index / 3)
          column = index and ((index - 1) % 3 + 1)
        end

        local ret = [[
          local tier = %s;
          local column = %s;
        ]]
        if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
          ret = ret .. [[
          local active, _, rank
          _, _, _, _, rank  = GetTalentInfo(tier, column)
          active = rank > 0
          ]]
        else
          if trigger.use_onlySelected then
            ret = ret .. [[
            local active, _, activeName, activeIcon, selected, known
            _, activeName, activeIcon, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
            active = selected
            ]]
          else
            ret = ret .. [[
            local active, _, activeName, activeIcon, selected, known
            _, activeName, activeIcon, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
            active = selected or known
            ]]
          end
        end
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
            if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
              tier = index and ceil(index / MAX_NUM_TALENTS)
              column = index and ((index - 1) % MAX_NUM_TALENTS + 1)
            else
              tier = index and ceil(index / 3)
              column = index and ((index - 1) % 3 + 1)
            end
            local ret2 = [[
              if (not active) then
                tier = %s
                column = %s
            ]]
            if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
              ret2 = ret2 .. [[
                local name, icon, _, _, rank  = GetTalentInfo(tier, column)
                if rank > 0 then
                  active = true;
                  activeName = name;
                  activeIcon = icon;
                end
              ]]
            else
              if trigger.use_onlySelected then
                ret2 = ret2 .. [[
                  local _, name, icon, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
                  if (selected) then
                    active = true;
                    activeName = name;
                    activeIcon = icon;
                  end
                ]]
              else
                ret2 = ret2 .. [[
                  local _, name, icon, selected, _, _, _, _, _, _, known  = GetTalentInfo(tier, column, 1)
                  if (selected or known) then
                    active = true;
                    activeName = name;
                    activeIcon = icon;
                  end
                ]]
              end
            end
            ret2 = ret2 .. [[
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
        display = L["Talent"],
        type = "multiselect",
        values = function()
          local class = select(2, UnitClass("player"));
          local spec =  WeakAuras.IsRetail() and GetSpecialization();
          if(Private.talent_types_specific[class] and  Private.talent_types_specific[class][spec]) then
            return Private.talent_types_specific[class][spec];
          elseif not WeakAuras.IsRetail() and Private.talent_types_specific[class] then
            return Private.talent_types_specific[class];
          else
            return Private.talent_types;
          end
        end,
        test = "active",
      },
      {
        name = "onlySelected",
        display = L["Only if selected"],
        type = "boolean",
        test = "true",
        enable = WeakAuras.IsRetail(),
        hidden = not WeakAuras.IsRetail(),
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
  },
  ["PvP Talent Selected"] = {
    type = "unit",
    events = function()
      return {
        ["events"] = { "PLAYER_PVP_TALENT_UPDATE" }
      }
    end,
    force_events = "PLAYER_PVP_TALENT_UPDATE",
    name = L["PvP Talent Selected"],
    init = function(trigger)
      local inverse = trigger.use_inverse;
      if (trigger.use_talent) then
        -- Single selection
        local index = trigger.talent and trigger.talent.single;
        local ret = [[
          local index = %s
          local activeName, activeIcon, _

          local active, talentId = WeakAuras.CheckPvpTalentByIndex(index)
          if talentId then
            _, activeName, activeIcon = GetPvpTalentInfoByID(talentId)
          end
        ]]
        if (inverse) then
          ret = ret .. [[
          active = not (active);
          ]]
        end
        return ret:format(index or 0)
      elseif (trigger.use_talent == false) then
        if (trigger.talent.multi) then
          local ret = [[
            local active = false;
            local activeIcon;
            local activeName
            local talentId
            local _
          ]]
          for index in pairs(trigger.talent.multi) do
            local ret2 = [[
              if (not active) then
                local index = %s
                active, talentId = WeakAuras.CheckPvpTalentByIndex(index)
                if active and talentId then
                  _, activeName, activeIcon = GetPvpTalentInfoByID(talentId)
                end
              end
            ]]
            ret = ret .. ret2:format(index)
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
          local spec =  GetSpecialization();
          if(Private.pvp_talent_types_specific[class] and  Private.pvp_talent_types_specific[class][spec]) then
            return Private.pvp_talent_types_specific[class][spec];
          else
            return Private.pvp_talent_types;
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
  },
  ["Class/Spec"] = {
    type = "unit",
    events = function()
      local events = { "PLAYER_TALENT_UPDATE" }
      return {
        ["events"] = events
      }
    end,
    force_events = "PLAYER_TALENT_UPDATE",
    name = L["Class and Specialization"],
    init = function(trigger)
      return [[
         local specId, specName, _, specIcon = GetSpecializationInfo(GetSpecialization())
      ]]
    end,
    args = {
      {
        name = "specId",
        display = L["Class and Specialization"],
        type = "multiselect",
        values = "spec_types_all",
      },
      {
        hidden = true,
        name = "icon",
        init = "specIcon",
        store = "true",
        test = "true"
      },
      {
        hidden = true,
        name = "name",
        init = "specName",
        store = "true",
        test = "true"
      },
    },
    automaticrequired = true,
    statesParameter = "one",
  },
  ["Totem"] = {
    type = "spell",
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
    canHaveDuration = "timed",
    triggerFunction = function(trigger)
      local ret = [[return
      function (states)
        local totemType = %s;
        local triggerTotemName = %q
        local triggerTotemPattern = %q
        local triggerTotemPatternOperator = %q
        local clone = %s
        local inverse = %s
        local remainingCheck = %s

        local function checkActive(remaining)
          return remaining %s remainingCheck;
        end

        if (totemType) then -- Check a specific totem slot
          local _, totemName, startTime, duration, icon = GetTotemInfo(totemType);
          active = (startTime and startTime ~= 0);

          if not WeakAuras.CheckTotemName(totemName, triggerTotemName, triggerTotemPattern, triggerTotemPatternOperator) then
            active = false;
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
              WeakAuras.ScheduleScan(expirationTime - remainingCheck);
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
            if ((startTime and startTime ~= 0) and
                WeakAuras.CheckTotemName(totemName, triggerTotemName, triggerTotemPattern, triggerTotemPatternOperator)
            ) then
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

            if not WeakAuras.CheckTotemName(totemName, triggerTotemName, triggerTotemPattern, triggerTotemPatternOperator) then
              active = false;
            end
            if (active and remainingCheck) then
              local expirationTime = startTime and (startTime + duration) or 0;
              local remainingTime = expirationTime - GetTime()
              if (remainingTime >= remainingCheck) then
                WeakAuras.ScheduleScan(expirationTime - remainingCheck);
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
        trigger.use_totemName and totemName or "",
        trigger.use_totemNamePattern and trigger.totemNamePattern or "",
        trigger.use_totemNamePattern and trigger.totemNamePattern_operator or "",
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
        name = "totemNamePattern",
        display = L["Totem Name Pattern Match"],
        type = "longstring",
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
        enable = function(trigger) return (trigger.use_totemName or trigger.use_totemNamePattern) and not trigger.use_clones end
      }
    },
    automaticrequired = true
  },
  ["Item Count"] = {
    type = "item",
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
      return C_Item.GetItemNameByID(trigger.itemName) or trigger.itemName;
    end,
    iconFunc = function(trigger)
      return GetItemIcon(trigger.itemName);
    end,
    hasItemID = true,
    automaticrequired = true
  },
  ["Stance/Form/Aura"] = {
    type = "unit",
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
        local form = GetShapeshiftForm()
        local active = false
      ]]
      if trigger.use_form and trigger.form and trigger.form.single then
        -- Single selection
        ret = ret .. [[
          local trigger_form = %d
          active = form == trigger_form
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
              active = form == index
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
      elseif trigger.use_form == nil then
        ret = ret .. [[
          active = true
        ]]
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
      local form = GetShapeshiftForm()
      if form and form > 0 then
        icon = GetShapeshiftFormInfo(form);
      end
      return icon or "136116"
    end,
    automaticrequired = true
  },
  ["Weapon Enchant"] = {
    type = "item",
    events = {},
    internal_events = {
      "TENCH_UPDATE",
    },
    force_events = "TENCH_UPDATE",
    name = WeakAuras.IsRetail() and L["Weapon Enchant / Fishing Lure"] or L["Weapon Enchant"],
    init = function(trigger)
      WeakAuras.TenchInit();

      local ret = [[
        local triggerWeaponType = %q
        local triggerName = %q
        local triggerStack = %s
        local triggerRemaining = %s
        local triggerShowOn = %q
        local _, expirationTime, duration, name, icon, stacks, enchantID

        if triggerWeaponType == "main" then
          expirationTime, duration, name, shortenedName, icon, stacks, enchantID = WeakAuras.GetMHTenchInfo()
        else
          expirationTime, duration, name, shortenedName, icon, stacks, enchantID = WeakAuras.GetOHTenchInfo()
        end

        local remaining = expirationTime and expirationTime - GetTime()

        local nameCheck = triggerName == "" or name and triggerName == name or shortenedName and triggerName == shortenedName or tonumber(triggerName) and enchantID and tonumber(triggerName) == enchantID
        local stackCheck = not triggerStack or stacks and stacks %s triggerStack
        local remainingCheck = not triggerRemaining or remaining and remaining %s triggerRemaining
        local found = expirationTime and nameCheck and stackCheck and remainingCheck

        if(triggerRemaining and remaining and remaining >= triggerRemaining and remaining > 0) then
          WeakAuras.ScheduleScan(expirationTime - triggerRemaining, "TENCH_UPDATE");
        end

        if not found then
          expirationTime = nil
          duration = nil
          remaining = nil
        end
      ]];

      local showOnActive = trigger.showOn == 'showOnActive' or not trigger.showOn

      return ret:format(trigger.weapon or "main",
      trigger.use_enchant and trigger.enchant or "",
      showOnActive and trigger.use_stack and tonumber(trigger.stack or 0) or "nil",
      showOnActive and trigger.use_remaining and tonumber(trigger.remaining or 0) or "nil",
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
        name = "stacks",
        display = L["Stack Count"],
        type = "number",
        test = "true",
        enable = function(trigger)
          return not WeakAuras.IsRetail() and (not trigger.showOn or trigger.showOn == "showOnActive")
        end,
        hidden = WeakAuras.IsRetail(),
        store = true
      },
      {
        name = "duration",
        hidden = true,
        init = "duration",
        test = "true",
        store = true
      },
      {
        name = "expirationTime",
        init = "expirationTime",
        hidden = true,
        test = "true",
        store = true
      },
      {
        name = "progressType",
        hidden = true,
        init = "duration and 'timed'",
        test = "true",
        store = true
      },
      {
        name = "name",
        hidden = true,
        init = "spell",
        test = "true",
        store = true
      },
      {
        name = "icon",
        hidden = true,
        init = "icon or 'Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon'",
        test = "true",
        store = true
      },
      {
        name = "enchanted",
        display = L["Enchanted"],
        hidden = true,
        init = "found ~= nil",
        test = "true",
        store = true,
        conditionType = "bool",
        conditionTest = function(state, needle)
          return state and state.show and state.enchanted == (needle == 1)
        end,
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        test = "true",
        enable = function(trigger)
          return not trigger.showOn or trigger.showOn == "showOnActive"
        end
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
    automaticrequired = true,
    canHaveDuration = true,
    statesParameter = "one"
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
    timedrequired = true
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
    type = "unit",
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
          WeakAuras.ScheduleScan(expirationTime - remainingCheck);
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
        enable = function(trigger) return trigger.use_rune end,
        required = true
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
    type = "item",
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
  ["Item Type Equipped"] = {
    type = "item",
    events = {
      ["events"] = {
        "UNIT_INVENTORY_CHANGED",
        "PLAYER_EQUIPMENT_CHANGED",
      }
    },
    internal_events = { "WA_DELAYED_PLAYER_ENTERING_WORLD", },
    force_events = "UNIT_INVENTORY_CHANGED",
    name = L["Item Type Equipped"],
    args = {
      {
        name = "itemTypeName",
        display = L["Item Type"],
        type = "multiselect",
        values = "item_weapon_types",
        test = "IsEquippedItemType(WeakAuras.GetItemSubClassInfo(%s))"
      },
    },
    automaticrequired = true
  },
  ["Item Bonus Id Equipped"] = {
    type = "item",
    events = {
      ["events"] = {
        "UNIT_INVENTORY_CHANGED",
        "PLAYER_EQUIPMENT_CHANGED",
      }
    },
    internal_events = { "WA_DELAYED_PLAYER_ENTERING_WORLD", },
    force_events = "UNIT_INVENTORY_CHANGED",
    name = L["Item Bonus Id Equipped"],
    statesParameter = "one",
    init = function(trigger)
      local ret = [=[
        local fetchLegendaryPower = %s
        local item = %q
        local inverse = %s
        local useItemSlot, slotSelected = %s, %d

        local itemBonusId, itemId, itemName, icon, itemSlot, itemSlotString = WeakAuras.GetBonusIdInfo(item, useItemSlot and slotSelected)
        local itemBonusId = tonumber(itemBonusId)
        if fetchLegendaryPower then
          itemName, icon = WeakAuras.GetLegendaryData(itemBonusId or item)
        end

        local slotValidation = (useItemSlot and itemSlot == slotSelected) or (not useItemSlot)
      ]=]
      return ret:format(trigger.use_legendaryIcon and "true" or "false", trigger.itemBonusId or "", trigger.use_inverse and "true" or "false",
                        trigger.use_itemSlot and "true" or "false", trigger.itemSlot)
    end,
    args = {
      {
        name = "itemBonusId",
        display = L["Item Bonus Id"],
        type = "string",
        store = "true",
        test = "true",
        required = true,
        desc = function()
          return WeakAuras.GetLegendariesBonusIds()
          .. L["\n\nSupports multiple entries, separated by commas"]
        end,
        conditionType = "number",
      },
      {
        name = "legendaryIcon",
        display = L["Fetch Legendary Power"],
        type = "toggle",
        test = "true",
        desc = L["Fetches the name and icon of the Legendary Power that matches this bonus id."],
        enable = WeakAuras.IsRetail(),
        hidden = not WeakAuras.IsRetail(),
      },
      {
        name = "name",
        display = L["Item Name"],
        hidden = "true",
        init = "itemName",
        store = "true",
        test = "true",
      },
      {
        name = "icon",
        hidden = "true",
        init = "icon or 'Interface/Icons/INV_Misc_QuestionMark'",
        store = "true",
        test = "true",
      },
      {
        name = "itemId",
        display = L["Item Id"],
        hidden = "true",
        store = "true",
        test = "true",
        conditionType = "number",
        operator_types = "only_equal",
      },
      {
        name = "itemSlot",
        display = L["Item Slot"],
        type = "select",
        store = "true",
        conditionType = "select",
        values = "item_slot_types",
        test = "true",
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
      },
      {
        name = "itemSlotString",
        display = L["Item Slot String"],
        hidden = "true",
        store = "true",
        test = "true",
      },
      {
        hidden = true,
        test = "not inverse == (itemBonusId and slotValidation or false)",
      }
    },
    automaticrequired = true
  },
  ["Item Set"] = {
    type = "item",
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
          if WeakAuras.IsRetail() then
            return L["Set IDs can be found on websites such as wowhead.com/item-sets"]
          elseif WeakAuras.IsClassic() then
            return L["Set IDs can be found on websites such as classic.wowhead.com/item-sets"]
          elseif WeakAuras.IsBCC() then
            return L["Set IDs can be found on websites such as tbc.wowhead.com/item-sets"]
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
    type = "item",
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
    type = "unit",
    events = function(trigger)
      local result = {}
      if trigger.threatUnit and trigger.threatUnit ~= "none" then
        AddUnitEventForEvents(result, trigger.threatUnit, "UNIT_THREAT_LIST_UPDATE")
      else
        AddUnitEventForEvents(result, "player", "UNIT_THREAT_SITUATION_UPDATE")
      end
      return result
    end,
    internal_events = function(trigger)
      local result = {}
      if trigger.threatUnit and trigger.threatUnit ~= "none" then
        AddUnitChangeInternalEvents(trigger.threatUnit, result)
      end
      return result
    end,
    force_events = "UNIT_THREAT_LIST_UPDATE",
    name = L["Threat Situation"],
    init = function(trigger)
      local ret = [[
        local unit = %s
        local ok = true
        local aggro, status, threatpct, rawthreatpct, threatvalue, threattotal
        if unit then
          aggro, status, threatpct, rawthreatpct, threatvalue = WeakAuras.UnitDetailedThreatSituation('player', unit)
          threattotal = (threatvalue or 0) * 100 / (threatpct ~= 0 and threatpct or 1)
        else
          status = UnitThreatSituation('player')
          aggro = status == 2 or status == 3
          threatpct, rawthreatpct, threatvalue, threattotal = 100, 100, 0, 100
        end
      ]];
      return ret:format(trigger.threatUnit and trigger.threatUnit ~= "none" and "[["..trigger.threatUnit.."]]" or "nil");
    end,
    canHaveDuration = true,
    statesParameter = "one",
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
        values = "unit_threat_situation_types",
        store = true,
        conditionType = "select"
      },
      {
        name = "aggro",
        display = L["Aggro"],
        type = "tristate",
        store = true,
        conditionType = "bool",
      },
      {
        name = "threatpct",
        display = L["Threat Percent"],
        desc = L["Your threat on the mob as a percentage of the amount required to pull aggro. Will pull aggro at 100."],
        type = "number",
        store = true,
        conditionType = "number",
        enable = function(trigger) return trigger.threatUnit ~= "none" end,
      },
      {
        name = "rawthreatpct",
        display = L["Raw Threat Percent"],
        desc = L["Your threat as a percentage of the tank's current threat."],
        type = "number",
        store = true,
        conditionType = "number",
        enable = function(trigger) return trigger.threatUnit ~= "none" end,
      },
      {
        name = "threatvalue",
        display = L["Threat Value"],
        desc = L["Your total threat on the mob."],
        type = "number",
        store = true,
        conditionType = "number",
        enable = function(trigger) return trigger.threatUnit ~= "none" end,
      },
      {
        name = "value",
        hidden = true,
        init = "threatvalue",
        store = true,
        test = "true"
      },
      {
        name = "total",
        hidden = true,
        init = "threattotal",
        store = true,
        test = "true"
      },
      {
        name = "progressType",
        hidden = true,
        init = "'static'",
        store = true,
        test = "true"
      },
      {
        hidden = true,
        test = "status ~= nil and ok"
      }
    },
    automaticrequired = true
  },
  ["Crowd Controlled"] = {
    type = "unit",
    events = {
      ["events"] = {
        "LOSS_OF_CONTROL_UPDATE"
      }
    },
    force_events = "LOSS_OF_CONTROL_UPDATE",
    name = L["Crowd Controlled"],
    canHaveDuration = true,
    statesParameter = "one",
    init = function(trigger)
      local ret = [=[
          local show = false
          local use_controlType = %s
          local controlType = %s
          local inverse = %s
          local use_interruptSchool = %s
          local interruptSchool = tonumber(%q)
          local duration, expirationTime, spellName, icon, spellName, spellId, locType, lockoutSchool, name, _
          for i = 1, C_LossOfControl.GetActiveLossOfControlDataCount() do
            local data = C_LossOfControl.GetActiveLossOfControlData(i)
            if data then
              if (not use_controlType)
              or (data.locType == controlType and (controlType ~= "SCHOOL_INTERRUPT" or ((not use_interruptSchool) or bit.band(data.lockoutSchool, interruptSchool) > 0)))
              then
                spellId = data.spellID
                spellName, _, icon = GetSpellInfo(data.spellID)
                duration = data.duration
                if data.startTime and data.duration then
                  expirationTime = data.startTime + data.duration
                end
                locType = data.locType
                lockoutSchool = data.lockoutSchool
                name = data.displayText
                show = true
                break
              end
            end
          end
      ]=]
      ret = ret:format(
        trigger.use_controlType and "true" or "false",
        type(trigger.controlType) == "string" and "[["..trigger.controlType.."]]" or [["STUN"]],
        trigger.use_inverse and "true" or "false",
        trigger.use_interruptSchool and "true" or "false",
        trigger.interruptSchool or 0
      )
      return ret
    end,
    args = {
      {
        name = "controlType",
        display = L["Specific Type"],
        type = "select",
        values = "loss_of_control_types",
        conditionType = "select",
        test = "true",
        default = "STUN",
        init = "locType",
        store = true,
      },
      {
        name = "interruptSchool",
        display = L["Interrupt School"],
        type = "select",
        values = "main_spell_schools",
        conditionType = "select",
        default = 1,
        test = "true",
        enable = function(trigger) return trigger.controlType == "SCHOOL_INTERRUPT" end,
        init = "lockoutSchool",
        store = true,
      },
      {
        name = "inverse",
        display = L["Inverse"],
        type = "toggle",
        test = "true",
      },
      {
        name = "name",
        display = L["Name"],
        hidden = true,
        conditionType = "string",
        store = true,
        test = "true",
      },
      {
        name = "spellName",
        display = L["Spell Name"],
        hidden = true,
        conditionType = "string",
        store = true,
        test = "true",
      },
      {
        name = "spellId",
        display = L["Spell Id"],
        hidden = true,
        conditionType = "number",
        operator_types = "only_equal",
        store = true,
        test = "true",
      },
      {
        name = "lockoutSchool",
        display = L["Interrupted School Text"],
        hidden = true,
        init = "lockoutSchool and lockoutSchool > 0 and GetSchoolString(lockoutSchool) or nil",
        store = true,
        test = "true",
      },
      {
        name = "icon",
        hidden = true,
        store = true,
        test = "true",
      },
      {
        name = "duration",
        hidden = true,
        store = true,
        test = "true",
      },
      {
        name = "expirationTime",
        hidden = true,
        store = true,
        test = "true",
      },
      {
        name = "progressType",
        hidden = true,
        init = "'timed'",
        store = true,
        test = "true",
      },
      {
        hidden = true,
        test = "inverse ~= show",
      },
    },
    automaticrequired = true,
  },
  ["Cast"] = {
    type = "unit",
    events = function(trigger)
      local result = {}
      local unit = trigger.unit
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_START")
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_DELAYED")
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_STOP")
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_CHANNEL_START")
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_CHANNEL_UPDATE")
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_CHANNEL_STOP")
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_INTERRUPTIBLE")
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
      AddUnitEventForEvents(result, unit, "UNIT_SPELLCAST_INTERRUPTED")
      AddUnitEventForEvents(result, unit, "UNIT_NAME_UPDATE")
      if WeakAuras.IsClassic() and unit ~= "player" then
        LibClassicCasterino.RegisterCallback("WeakAuras", "UNIT_SPELLCAST_START", WeakAuras.ScanUnitEvents)
        LibClassicCasterino.RegisterCallback("WeakAuras", "UNIT_SPELLCAST_DELAYED", WeakAuras.ScanUnitEvents) -- only for player
        LibClassicCasterino.RegisterCallback("WeakAuras", "UNIT_SPELLCAST_STOP", WeakAuras.ScanUnitEvents)
        LibClassicCasterino.RegisterCallback("WeakAuras", "UNIT_SPELLCAST_CHANNEL_START", WeakAuras.ScanUnitEvents)
        LibClassicCasterino.RegisterCallback("WeakAuras", "UNIT_SPELLCAST_CHANNEL_UPDATE", WeakAuras.ScanUnitEvents) -- only for player
        LibClassicCasterino.RegisterCallback("WeakAuras", "UNIT_SPELLCAST_CHANNEL_STOP", WeakAuras.ScanUnitEvents)
        LibClassicCasterino.RegisterCallback("WeakAuras", "UNIT_SPELLCAST_INTERRUPTED", WeakAuras.ScanUnitEvents)
      end
      AddUnitEventForEvents(result, unit, "UNIT_TARGET")
      if trigger.use_showLatency and unit == "player" then
        result.events = result.events or {}
        tinsert(result.events, "CAST_LATENCY_UPDATE")
      end
      return result
    end,
    internal_events = function(trigger)
      local unit = trigger.unit
      local result = {}
      if WeakAuras.IsClassic() and unit ~= "player" then
        tinsert(result, "UNIT_SPELLCAST_START")
        tinsert(result, "UNIT_SPELLCAST_DELAYED")
        tinsert(result, "UNIT_SPELLCAST_CHANNEL_START")
      end
      AddRemainingCastInternalEvents(unit, result)
      AddUnitChangeInternalEvents(unit, result)
      AddUnitRoleChangeInternalEvents(unit, result)
      return result
    end,
    loadFunc = function(trigger)
      if trigger.use_showLatency and trigger.unit == "player" then
        WeakAuras.WatchForCastLatency()
      end
    end,
    force_events = unitHelperFunctions.UnitChangedForceEvents,
    canHaveDuration = "timed",
    name = L["Cast"],
    init = function(trigger)
      trigger.unit = trigger.unit or "player";
      local ret = [=[
        unit = string.lower(unit)
        local destUnit = unit .. '-target'
        local sourceName, sourceRealm = WeakAuras.UnitNameWithRealm(unit)
        local destName, destRealm = WeakAuras.UnitNameWithRealm(destUnit)
        destName = destName or ""
        destRealm = destRealm or ""
        local smart = %s
        local remainingCheck = %s
        local inverseTrigger = %s

        local show, expirationTime, castType, spell, icon, startTime, endTime, interruptible, spellId, remaining, _

        spell, _, icon, startTime, endTime, _, _, interruptible, spellId = WeakAuras.UnitCastingInfo(unit)
        if spell then
          castType = "cast"
        else
          spell, _, icon, startTime, endTime, _, interruptible, spellId = WeakAuras.UnitChannelInfo(unit)
          if spell then
            castType = "channel"
          end
        end
        interruptible = not interruptible
        expirationTime = endTime and endTime > 0 and (endTime / 1000) or 0
        remaining = expirationTime - GetTime()

        if remainingCheck and remaining >= remainingCheck and remaining > 0 then
          WeakAuras.ScheduleCastCheck(expirationTime - remainingCheck, unit)
        end
      ]=];

      ret = ret:format(trigger.unit == "group" and "true" or "false",
                        trigger.use_remaining and tonumber(trigger.remaining or 0) or "nil",
                        trigger.use_inverse and "true" or "false");

      if trigger.unit == "player" and trigger.use_showLatency then
        ret = ret .. [[
          if event == "CAST_LATENCY_UPDATE" then
            state.sendTime = GetTime()
          elseif event == "UNIT_SPELLCAST_START" and tonumber(state.sendTime) then
            state.latency = GetTime() - state.sendTime
            state.changed = true
          end
        ]]
      end
      ret = ret .. unitHelperFunctions.SpecificUnitCheck(trigger)

      return ret
    end,
    statesParameter = "unit",
    args = {
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "arg",
        values = function(trigger)
          if trigger.use_inverse then
            return Private.actual_unit_types_with_specific
          else
            return Private.actual_unit_types_cast
          end
        end,
        test = "true",
        store = true
      },
      {
        name = "spellId",
        display = L["Spell"],
        type = "spell",
        enable = function(trigger) return not trigger.use_inverse end,
        conditionType = "number",
        showExactOption = true,
        test = "WeakAuras.CompareSpellIds(spellId, %s, %s)",
        store = true,
      },
      {
        name = "spell",
        display = L["Legacy Spellname"],
        type = "string",
        enable = function(trigger) return not trigger.use_inverse end,
        conditionType = "string",
        store = true,
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
        enable = function(trigger) return not WeakAuras.IsBCC() and not trigger.use_inverse end,
        store = true,
        conditionType = "bool",
        hidden = WeakAuras.IsBCC()
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
        enable = function(trigger) return not trigger.use_inverse end,
      },
      {
        name = "name",
        hidden = true,
        init = "spell",
        test = "true",
        store = true
      },
      {
        name = "icon",
        hidden = true,
        init = "icon or 'Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon'",
        test = "true",
        store = true
      },
      {
        name = "duration",
        hidden = true,
        init = "endTime and startTime and (endTime - startTime)/1000 or 0",
        test = "true",
        store = true
      },
      {
        name = "expirationTime",
        init = "expirationTime",
        hidden = true,
        test = "true",
        store = true
      },
      {
        name = "progressType",
        hidden = true,
        init = "'timed'",
        test = "true",
        store = true
      },
      {
        name = "inverse",
        hidden = true,
        init = "castType == 'cast'",
        test = "true",
        store = true
      },
      {
        name = "autoHide",
        hidden = true,
        init = "true",
        test = "true",
        store = true
      },
      {
        name = "npcId",
        display = L["Npc ID"],
        type = "string",
        store = true,
        conditionType = "string",
        test = "select(6, strsplit('-', UnitGUID(unit) or '')) == %q",
        enable = function(trigger)
          return not trigger.use_inverse
        end
      },
      {
        name = "class",
        display = L["Class"],
        type = "select",
        init = "select(2, UnitClass(unit))",
        values = "class_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return not trigger.use_inverse
        end
      },
      {
        name = "role",
        display = L["Assigned Role"],
        type = "select",
        init = "UnitGroupRolesAssigned(unit)",
        values = "role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return WeakAuras.IsRetail() and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
                 and not trigger.use_inverse
        end
      },
      {
        name = "raid_role",
        display = L["Assigned Role"],
        type = "select",
        init = "WeakAuras.UnitRaidRole(unit)",
        values = "raid_role_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
          return not WeakAuras.IsRetail() and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
                 and not trigger.use_inverse
        end
      },
      {
        name = "ignoreSelf",
        display = L["Ignore Self"],
        type = "toggle",
        width = WeakAuras.doubleWidth,
        enable = function(trigger)
          return trigger.unit == "nameplate" or trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
        end,
        init = "not UnitIsUnit(\"player\", unit)"
      },
      {
        name = "nameplateType",
        display = L["Nameplate Type"],
        type = "select",
        init = "WeakAuras.GetPlayerReaction(unit)",
        values = "hostility_types",
        store = true,
        conditionType = "select",
        enable = function(trigger)
           return trigger.unit == "nameplate"
         end
      },
      {
        name = "sourceUnit",
        init = "unit",
        display = L["Caster"],
        type = "unit",
        values = "actual_unit_types_with_specific",
        conditionType = "unit",
        conditionTest = function(state, unit, op)
          return state and state.show and state.unit and (UnitIsUnit(state.sourceUnit, unit) == (op == "=="))
        end,
        store = true,
        hidden = true,
        enable = function(trigger) return not trigger.use_inverse end,
        test = "true"
      },
      {
        name = "sourceName",
        display = L["Caster Name"],
        type = "string",
        store = true,
        hidden = true,
        test = "true",
        enable = function(trigger) return not trigger.use_inverse end,
      },
      {
        name = "sourceRealm",
        display = L["Caster Realm"],
        type = "string",
        store = true,
        hidden = true,
        test = "true",
        enable = function(trigger) return not trigger.use_inverse end,
      },
      {
        name = "sourceNameRealm",
        display = L["Source Unit Name/Realm"],
        type = "string",
        preamble = "local sourceNameRealmChecker = WeakAuras.ParseNameCheck(%q)",
        test = "sourceNameRealmChecker:Check(sourceName, sourceRealm)",
        conditionType = "string",
        conditionPreamble = function(input)
          return WeakAuras.ParseNameCheck(input)
        end,
        conditionTest = function(state, needle, op, preamble)
          return preamble:Check(state.sourceName, state.sourceRealm)
        end,
        operator_types = "none",
        enable = function(trigger) return not trigger.use_inverse end,
        desc = constants.nameRealmFilterDesc,
      },
      {
        name = "destUnit",
        display = L["Caster's Target"],
        type = "unit",
        values = "actual_unit_types_with_specific",
        conditionType = "unit",
        conditionTest = function(state, unit, op)
          return state and state.show and state.destUnit and (UnitIsUnit(state.destUnit, unit) == (op == "=="))
        end,
        store = true,
        enable = function(trigger) return not trigger.use_inverse end,
        test = "UnitIsUnit(destUnit, [[%s]])"
      },
      {
        name = "destName",
        display = L["Name of Caster's Target"],
        type = "string",
        store = true,
        hidden = true,
        test = "true",
        enable = function(trigger) return not trigger.use_inverse end,
      },
      {
        name = "destRealm",
        display = L["Realm of Caster's Target"],
        type = "string",
        store = true,
        hidden = true,
        test = "true",
        enable = function(trigger) return not trigger.use_inverse end,
      },
      {
        name = "destNameRealm",
        display = L["Name/Realm of Caster's Target"],
        type = "string",
        preamble = "local destNameRealmChecker = WeakAuras.ParseNameCheck(%q)",
        test = "destNameRealmChecker:Check(destName, destRealm)",
        conditionType = "string",
        conditionPreamble = function(input)
          return WeakAuras.ParseNameCheck(input)
        end,
        conditionTest = function(state, needle, op, preamble)
          return preamble:Check(state.destName, state.destRealm)
        end,
        operator_types = "none",
        enable = function(trigger) return not trigger.use_inverse end,
        desc = constants.nameRealmFilterDesc,
      },
      {
        name = "showLatency",
        display = L["Overlay Latency"],
        type = "toggle",
        test = "true",
        enable = function(trigger)
          return trigger.unit == "player"
        end,
        reloadOptions = true
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
        test = "WeakAuras.UnitExistsFixed(unit, smart) and ((not inverseTrigger and spell) or (inverseTrigger and not spell)) and specificUnitCheck"
      }
    },
    overlayFuncs = {
      {
        name = L["Latency"],
        func = function(trigger, state)
          return 0, type(state.latency) == "number" and state.latency
        end,
        enable = function(trigger)
          return trigger.use_showLatency and trigger.unit == "player"
        end
      },
    },
    automaticrequired = true,
  },
  ["Character Stats"] = {
    type = "unit",
    name = L["Character Stats"],
    events = {
      ["events"] = {
        "COMBAT_RATING_UPDATE",
        "PLAYER_TARGET_CHANGED"
      },
      ["unit_events"] = {
        ["player"] = {"UNIT_STATS", "UNIT_ATTACK_POWER", "UNIT_AURA"}
      }
    },
    internal_events = function(trigger, untrigger)
      local events = { "WA_DELAYED_PLAYER_ENTERING_WORLD", "PLAYER_MOVING_UPDATE" }
      if trigger.use_moveSpeed then
        tinsert(events, "PLAYER_MOVE_SPEED_UPDATE")
      end
      return events
    end,
    loadFunc = function(trigger)
      if trigger.use_moveSpeed then
        WeakAuras.WatchPlayerMoveSpeed()
      end
      WeakAuras.WatchForPlayerMoving()
    end,
    init = function()
      local ret = [[
        local main_stat, _
        if WeakAuras.IsRetail() then
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
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "strength",
        display = L["Strength"],
        type = "number",
        init = "UnitStat('player', LE_UNIT_STAT_STRENGTH)",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
      },
      {
        name = "agility",
        display = L["Agility"],
        type = "number",
        init = "UnitStat('player', LE_UNIT_STAT_AGILITY)",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
      },
     {
        name = "intellect",
        display = L["Intellect"],
        type = "number",
        init = "UnitStat('player', LE_UNIT_STAT_INTELLECT)",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
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
        init = "max(GetCombatRating(CR_CRIT_MELEE), GetCombatRating(CR_CRIT_RANGED), GetCombatRating(CR_CRIT_SPELL))",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "criticalpercent",
        display = L["Critical (%)"],
        type = "number",
        init = "WeakAuras.GetCritChance()",
        store = true,
        conditionType = "number"
      },
      {
        name = "hasterating",
        display = L["Haste Rating"],
        type = "number",
        init = "GetCombatRating(CR_HASTE_SPELL)",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
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
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "masterypercent",
        display = L["Mastery (%)"],
        type = "number",
        init = "GetMasteryEffect()",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "versatilityrating",
        display = L["Versatility Rating"],
        type = "number",
        init = "GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "versatilitypercent",
        display = L["Versatility (%)"],
        type = "number",
        init = "GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "attackpower",
        display = L["Attack Power"],
        type = "number",
        init = "WeakAuras.GetEffectiveAttackPower()",
        store = true,
        conditionType = "number"
      },
      {
        name = "resistanceholy",
        display = L["Holy Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 1))",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
      },
      {
        name = "resistancefire",
        display = L["Fire Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 2))",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
      },
      {
        name = "resistancenature",
        display = L["Nature Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 3))",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
      },
      {
        name = "resistancefrost",
        display = L["Frost Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 4))",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
      },
      {
        name = "resistanceshadow",
        display = L["Shadow Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 5))",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
      },
      {
        name = "resistancearcane",
        display = L["Arcane Resistance"],
        type = "number",
        init = "select(2, UnitResistance('player', 6))",
        store = true,
        enable = WeakAuras.IsClassic() or WeakAuras.IsBCC(),
        conditionType = "number",
        hidden = WeakAuras.IsRetail()
      },
      {
        name = "leechrating",
        display = L["Leech Rating"],
        type = "number",
        init = "GetCombatRating(CR_LIFESTEAL)",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "leechpercent",
        display = L["Leech (%)"],
        type = "number",
        init = "GetLifesteal()",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "movespeedrating",
        display = L["Movement Speed Rating"],
        type = "number",
        init = "GetCombatRating(CR_SPEED)",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "moveSpeed",
        display = L["Continuously update Movement Speed"],
        type = "boolean",
        test = true,
        width = WeakAuras.doubleWidth
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
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "avoidancepercent",
        display = L["Avoidance (%)"],
        type = "number",
        init = "GetAvoidance()",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "dodgerating",
        display = L["Dodge Rating"],
        type = "number",
        init = "GetCombatRating(CR_DODGE)",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
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
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
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
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
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
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "armortargetpercent",
        display = L["Armor against Target (%)"],
        type = "number",
        init = "PaperDollFrame_GetArmorReductionAgainstTarget(select(2, UnitArmor('player')))",
        store = true,
        enable = WeakAuras.IsRetail(),
        conditionType = "number",
        hidden = not WeakAuras.IsRetail()
      },
    },
    automaticrequired = true
  },
  ["Conditions"] = {
    type = "unit",
    events = function(trigger, untrigger)
      local events = {}
      if trigger.use_incombat ~= nil then
        tinsert(events, "PLAYER_REGEN_ENABLED")
        tinsert(events, "PLAYER_REGEN_DISABLED")
        tinsert(events, "PLAYER_ENTERING_WORLD")
      end
      if trigger.use_pvpflagged ~= nil or trigger.use_afk ~= nil then
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
      if trigger.use_vehicle ~= nil then
        if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
          tinsert(unit_events, "UNIT_FLAGS")
        else
          tinsert(unit_events, "UNIT_ENTERED_VEHICLE")
          tinsert(unit_events, "UNIT_EXITED_VEHICLE")
        end
        tinsert(events, "PLAYER_ENTERING_WORLD")
      end
      if trigger.use_HasPet ~= nil then
        tinsert(pet_unit_events, "UNIT_HEALTH")
      end
      if trigger.use_ingroup ~= nil then
        tinsert(events, "GROUP_ROSTER_UPDATE")
      end

      if trigger.use_instance_size ~= nil then
        tinsert(events, "ZONE_CHANGED")
        tinsert(events, "ZONE_CHANGED_INDOORS")
        tinsert(events, "ZONE_CHANGED_NEW_AREA")
      end

      if trigger.use_instance_difficulty ~= nil or trigger.use_instance_type then
        tinsert(events, "PLAYER_DIFFICULTY_CHANGED")
        tinsert(events, "ZONE_CHANGED")
        tinsert(events, "ZONE_CHANGED_INDOORS")
        tinsert(events, "ZONE_CHANGED_NEW_AREA")
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
        enable = WeakAuras.IsRetail(),
        hidden = not WeakAuras.IsRetail()
      },
      {
        name = "alive",
        display = L["Alive"],
        type = "tristate",
        init = "not UnitIsDeadOrGhost('player')"
      },
      {
        name = "vehicle",
        display = not WeakAuras.IsRetail() and L["On Taxi"] or L["In Vehicle"],
        type = "tristate",
        init = not WeakAuras.IsRetail() and "UnitOnTaxi('player')" or "UnitInVehicle('player')",
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
      },
      {
        name = "afk",
        display = L["Is Away from Keyboard"],
        type = "tristate",
        init = "UnitIsAFK('player')"
      },
      {
        name = "ingroup",
        display = L["In Group"],
        type = "multiselect",
        values = "group_types",
        init = "WeakAuras.GroupType()",
      },
      {
        name = "instance_size",
        display = L["Instance Size Type"],
        type = "multiselect",
        values = "instance_types",
        init = "WeakAuras.InstanceType()",
        control = "WeakAurasSortedDropdown",
      },
      {
        name = "instance_difficulty",
        display = L["Instance Difficulty"],
        type = "multiselect",
        values = "difficulty_types",
        init = "WeakAuras.InstanceDifficulty()",
        enable = WeakAuras.IsRetail(),
        hidden = not WeakAuras.IsRetail(),
      },
      {
        name = "instance_type",
        display = L["Instance Type"],
        type = "multiselect",
        values = "instance_difficulty_types",
        init = "WeakAuras.InstanceTypeRaw()",
        enable = WeakAuras.IsRetail(),
        hidden = not WeakAuras.IsRetail(),
      },
    },
    automaticrequired = true
  },

  ["Spell Known"] = {
    type = "spell",
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
        spellName = tonumber(trigger.spellName) or "nil";
        if spellName == 0 then
          spellName = "nil"
        end
        local ret = [[
          local spellName = %s;
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
    nameFunc = function(trigger)
      return GetSpellInfo(trigger.spellName or 0)
    end,
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    automaticrequired = true
  },

  ["Pet Behavior"] = {
    type = "unit",
    events = function(trigger)
      local result = {};
      if (trigger.use_behavior) then
        tinsert(result, "PET_BAR_UPDATE");
      end
      if (trigger.use_petspec) then
        tinsert(result, "PET_SPECIALIZATION_CHANGED");
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
            local name, i, active, behavior, _
            for index = 1, NUM_PET_ACTION_SLOTS do
              name, i, _, active = GetPetActionInfo(index)
              if active then
                activeIcon = _G[i]
                if name == "PET_MODE_AGGRESSIVE" then
                  behavior = "aggressive"
                  break
                elseif name == "PET_MODE_ASSIST" then
                  behavior = "assist"
                  break
                elseif name == "PET_MODE_DEFENSIVEASSIST" then
                  behavior = "defensive"
                  break
                elseif name == "PET_MODE_DEFENSIVE" then
                  behavior = "defensive"
                  break
                elseif name == "PET_MODE_PASSIVE" then
                  behavior = "passive"
                  break
                end
              end
            end
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

  ["Queued Action"] = {
    type = "spell",
    events = {
      ["events"] = {"ACTIONBAR_UPDATE_STATE"}
    },
    internal_events = {
      "ACTIONBAR_SLOT_CHANGED",
      "ACTIONBAR_PAGE_CHANGED"
    },
    name = L["Queued Action"],
    init = function(trigger)
      trigger.spellName = trigger.spellName or 0
      local spellName
      if trigger.use_exact_spellName then
        spellName = trigger.spellName
      else
        spellName = type(trigger.spellName) == "number" and GetSpellInfo(trigger.spellName) or trigger.spellName
      end
      local ret = [=[
        local spellname = %q
        local spellid = select(7, GetSpellInfo(spellname))
        local button
        if spellid then
            local slotList = C_ActionBar.FindSpellActionButtons(spellid)
            button = slotList and slotList[1]
        end
      ]=]
      return ret:format(spellName)
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
        hidden = true,
        test = "button and IsCurrentAction(button)";
      },
    },
    iconFunc = function(trigger)
      local _, _, icon = GetSpellInfo(trigger.spellName or 0);
      return icon;
    end,
    automaticrequired = true
  },

  ["Range Check"] = {
    type = "unit",
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
        text = function() return L["Note: This trigger type estimates the range to the hitbox of a unit. The actual range of friendly players is usually 3 yards more than the estimate. Range checking capabilities depend on your current class and known abilities as well as the type of unit being checked. Some of the ranges may also not work with certain NPCs.|n|n|cFFAAFFAAFriendly Units:|r %s|n|cFFFFAAAAHarmful Units:|r %s|n|cFFAAAAFFMiscellanous Units:|r %s"]:format(RangeCacheStrings.friend or "", RangeCacheStrings.harm or "", RangeCacheStrings.misc or "") end
      },
      {
        name = "unit",
        required = true,
        display = L["Unit"],
        type = "unit",
        init = "unit",
        values = "unit_types_range_check",
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
        operator_types = "without_equal",
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

if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
  if not UnitDetailedThreatSituation then
    Private.event_prototypes["Threat Situation"] = nil
  end
  Private.event_prototypes["Death Knight Rune"] = nil
  Private.event_prototypes["Alternate Power"] = nil
  Private.event_prototypes["Equipment Set"] = nil
  Private.event_prototypes["Spell Activation Overlay"] = nil
  Private.event_prototypes["Crowd Controlled"] = nil
  Private.event_prototypes["PvP Talent Selected"] = nil
  Private.event_prototypes["Class/Spec"] = nil
else
  Private.event_prototypes["Queued Action"] = nil
end

Private.dynamic_texts = {
  ["p"] = {
    get = function(state)
      if not state then return nil end
      if state.progressType == "static" then
        return state.value or nil
      end
      if state.progressType == "timed" then
        if state.paused then
          return state.remaining and state.remaining >= 0 and state.remaining or nil
        end

        if not state.expirationTime or not state.duration then
          return nil
        end
        local remaining = state.expirationTime - GetTime();
        return remaining >= 0 and remaining or nil
      end
    end,
    func = function(remaining, state, progressPrecision)
      progressPrecision = progressPrecision or 1

      if not state or state.progressType ~= "timed" then
        return remaining
      end
      if type(remaining) ~= "number" then
        return ""
      end

      local remainingStr = "";
      if remaining == math.huge then
        remainingStr = " ";
      elseif remaining > 60 then
        remainingStr = string.format("%i:", math.floor(remaining / 60));
        remaining = remaining % 60;
        remainingStr = remainingStr..string.format("%02i", remaining);
      elseif remaining > 0 then
        if progressPrecision == 4 and remaining <= 3 then
          remainingStr = remainingStr..string.format("%.1f", remaining);
        elseif progressPrecision == 5 and remaining <= 3 then
          remainingStr = remainingStr..string.format("%.2f", remaining);
        elseif progressPrecision == 6 and remaining <= 3 then
          remainingStr = remainingStr..string.format("%.3f", remaining);
        elseif (progressPrecision == 4 or progressPrecision == 5 or progressPrecision == 6) and remaining > 3 then
          remainingStr = remainingStr..string.format("%d", remaining);
        else
          remainingStr = remainingStr..string.format("%.".. progressPrecision .."f", remaining);
        end
      else
        remainingStr = " ";
      end
      return remainingStr
    end
  },
  ["t"] = {
    get = function(state)
      if not state then return "" end
      if state.progressType == "static" then
        return state.total, false
      end
      if state.progressType == "timed" then
        if not state.duration then
          return nil
        end
        return state.duration, true
      end
    end,
    func = function(duration, state, totalPrecision)
      if not state or state.progressType ~= "timed" then
        return duration
      end
      if type(duration) ~= "number" then
        return ""
      end
      local durationStr = "";
      if math.abs(duration) == math.huge or tostring(duration) == "nan" then
        durationStr = " ";
      elseif duration > 60 then
        durationStr = string.format("%i:", math.floor(duration / 60));
        duration = duration % 60;
        durationStr = durationStr..string.format("%02i", duration);
      elseif duration > 0 then
        if totalPrecision == 4 and duration <= 3 then
          durationStr = durationStr..string.format("%.1f", duration);
        elseif totalPrecision == 5 and duration <= 3 then
          durationStr = durationStr..string.format("%.2f", duration);
        elseif totalPrecision == 6 and duration <= 3 then
          durationStr = durationStr..string.format("%.3f", duration);
        elseif (totalPrecision == 4 or totalPrecision == 5 or totalPrecision == 6) and duration > 3 then
          durationStr = durationStr..string.format("%d", duration);
        else
          durationStr = durationStr..string.format("%."..totalPrecision.."f", duration);
        end
      else
        durationStr = " ";
      end
      return durationStr
    end
  },
  ["n"] = {
    get = function(state)
      if not state then return "" end
      return state.name or state.id or "", true
    end,
    func = function(v)
      return v
    end
  },
  ["i"] = {
    get = function(state)
      if not state then return "" end
      return state.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    end,
    func = function(v)
      return "|T".. v ..":12:12:0:0:64:64:4:60:4:60|t"
    end
  },
  ["s"] = {
    get = function(state)
      if not state or state.stacks == 0 then return "" end
      return state.stacks
    end,
    func = function(v)
      return v
    end
  }
};
