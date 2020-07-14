if not WeakAuras.IsCorrectVersion() then return end

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local LSM = LibStub("LibSharedMedia-3.0");

local wipe, tinsert = wipe, tinsert
local GetNumShapeshiftForms, GetShapeshiftFormInfo = GetNumShapeshiftForms, GetShapeshiftFormInfo
local GetNumSpecializationsForClassID, GetSpecializationInfoForClassID = GetNumSpecializationsForClassID, GetSpecializationInfoForClassID
local WrapTextInColorCode, GetClassColor = WrapTextInColorCode, GetClassColor -- for Classic

WeakAuras.glow_action_types = {
  show = L["Show"],
  hide = L["Hide"]
}

WeakAuras.glow_frame_types = {
  UNITFRAME = L["Unit Frame"],
  NAMEPLATE = L["Nameplate"],
  FRAMESELECTOR = L["Frame Selector"]
}

WeakAuras.circular_group_constant_factor_types = {
  RADIUS = L["Radius"],
  SPACING = L["Spacing"]
}

WeakAuras.frame_strata_types = {
  [1] = L["Inherited"],
  [2] = "BACKGROUND",
  [3] = "LOW",
  [4] = "MEDIUM",
  [5] = "HIGH",
  [6] = "DIALOG",
  [7] = "FULLSCREEN",
  [8] = "FULLSCREEN_DIALOG",
  [9] = "TOOLTIP"
}

WeakAuras.hostility_types = {
  hostile = L["Hostile"],
  friendly = L["Friendly"]
}

WeakAuras.character_types = {
  player = L["Player Character"],
  npc = L["Non-player Character"]
}

WeakAuras.group_sort_types = {
  ascending = L["Ascending"],
  descending = L["Descending"],
  hybrid = L["Hybrid"],
  none = L["None"],
  custom = L["Custom"]
}

WeakAuras.group_hybrid_position_types = {
  hybridFirst = L["Marked First"],
  hybridLast = L["Marked Last"]
}

WeakAuras.group_hybrid_sort_types = {
  ascending = L["Ascending"],
  descending = L["Descending"]
}

WeakAuras.precision_types = {
  [0] = "12",
  [1] = "12.3",
  [2] = "12.34",
  [3] = "12.345",
}

WeakAuras.big_number_types = {
  ["AbbreviateNumbers"] = L["AbbreviateNumbers (Blizzard)"],
  ["AbbreviateLargeNumbers"] = L["AbbreviateLargeNumbers (Blizzard)"]
}

WeakAuras.round_types = {
  floor = L["Floor"],
  ceil = L["Ceil"],
  round = L["Round"]
}

WeakAuras.unit_color_types = {
  none = L["None"],
  class = L["Class"]
}

WeakAuras.unit_realm_name_types = {
  never = L["Never"],
  star = L["* Suffix"],
  differentServer = L["Only if on a different realm"],
  always = L["Always include realm"]
}

local simpleFormatters = {
  AbbreviateNumbers = function(value, state)
    return (type(value) == "number") and AbbreviateNumbers(value) or value
  end,
  AbbreviateLargeNumbers = function(value, state)
    return (type(value) == "number") and AbbreviateLargeNumbers(Round(value)) or value
  end,
  floor = function(value)
    return (type(value) == "number") and floor(value) or value
  end,
  ceil = function(value)
    return (type(value) == "number") and ceil(value) or value
  end,
  round = function(value)
    return (type(value) == "number") and Round(value) or value
  end
}

WeakAuras.format_types = {
  none = {
    display = L["None"],
    AddOptions = function() end,
    CreateFormatter = function() end
  },
  timed = {
    display = L["Time Format"],
    AddOptions = function(symbol, hidden, addOption, get)
      addOption(symbol .. "_time_precision", {
        type = "select",
        name = L["Precision"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.precision_types,
        hidden = hidden
      })
      addOption(symbol .. "_time_dynamic", {
        type = "toggle",
        name = L["Dynamic"],
        desc = L["Increased Precision below 3s"],
        width = WeakAuras.normalWidth,
        hidden = hidden,
        disabled = function() return get(symbol .. "_time_precision") == 0 end
      })
    end,
    CreateFormatter = function(symbol, get)
      local precision = get(symbol .. "_time_precision", 1)
      local dynamic = get(symbol .. "_time_dynamic", false)

      if dynamic then
        if precision == 1 or precision == 2 or precision == 3 then
          precision = precision + 3
        end
      end

      return function(value, state)
        return WeakAuras.dynamic_texts.p.func(value, state, precision)
      end
    end
  },
  BigNumber = {
    display = L["Big Number"],
    AddOptions = function(symbol, hidden, addOption)
      addOption(symbol .. "_big_number_format", {
        type = "select",
        name = L["Format"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.big_number_types,
        hidden = hidden
      })
      addOption(symbol .. "_big_number_space", {
        type = "description",
        name = "",
        width = WeakAuras.normalWidth,
        hidden = hidden
      })
    end,
    CreateFormatter = function(symbol, get)
      local format = get(symbol .. "_big_number_format", "AbbreviateNumbers")
      if (format == "AbbreviateNumbers") then
        return simpleFormatters.AbbreviateNumbers
      end
      return simpleFormatters.AbbreviateLargeNumbers
    end
  },
  Number = {
    display = L["Number"],
    AddOptions = function(symbol, hidden, addOption, get)
      addOption(symbol .. "_decimal_precision", {
        type = "select",
        name = L["Precision"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.precision_types,
        hidden = hidden
      })
      addOption(symbol .. "_round_type", {
        type = "select",
        name = L["Round Mode"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.round_types,
        hidden = hidden,
        disabled = function()
          return get(symbol .. "_decimal_precision") ~= 0
        end
      })
    end,
    CreateFormatter = function(symbol, get)
      local precision = get(symbol .. "_decimal_precision", 1)
      if precision == 0 then
        local type = get(symbol .. "_round_type", "floor")
        return simpleFormatters[type]
      else
        local format = "%." .. precision .. "f"
        return function(value)
          return (type(value) == "number") and string.format(format, value) or value
        end
      end
    end
  },
  Unit = {
    display = L["Formats |cFFFF0000%unit|r"],
    AddOptions = function(symbol, hidden, addOption, get)
      addOption(symbol .. "_color", {
        type = "select",
        name = L["Color"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.unit_color_types,
        hidden = hidden,
      })
      addOption(symbol .. "_realm_name", {
        type = "select",
        name = L["Realm Name"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.unit_realm_name_types,
        hidden = hidden,
      })
      addOption(symbol .. "_abbreviate", {
        type = "toggle",
        name = L["Abbreviate"],
        width = WeakAuras.normalWidth,
        hidden = hidden,
      })
      addOption(symbol .. "_abbreviate_max", {
        type = "range",
        name = L["Max Char "],
        width = WeakAuras.normalWidth,
        hidden = hidden,
        min = 1,
        max = 20,
        hidden = hidden,
        step = 1,
        disabled = function()
          return not get(symbol .. "_abbreviate")
        end
      })
    end,
    CreateFormatter = function(symbol, get)
      local color = get(symbol .. "_color", true)
      local realm = get(symbol .. "_realm_name", "never")
      local abbreviate = get(symbol .. "_abbreviate", false)
      local abbreviateMax = get(symbol .. "_abbreviate_max", 8)

      local nameFunc
      local colorFunc
      local abbreviateFunc
      if color == "class" then
        colorFunc = function(unit, text)
          if unit and UnitPlayerControlled(unit) then
            return GetClassColoredTextForUnit(unit, text)
          end
          return text
        end
      end

      if realm == "never" then
        nameFunc = function(unit)
          return unit and UnitName(unit)
        end
      elseif realm == "star" then
        nameFunc = function(unit)
          if not unit then
            return ""
          end
          local name, realm = UnitName(unit)
          if realm then
            return name .. "*"
          end
          return name
        end
      elseif realm == "differentServer" then
        nameFunc = function(unit)
          if not unit then
            return ""
          end
          local name, realm = UnitName(unit)
          if realm then
            return name .. "-" .. realm
          end
          return name
        end
      elseif realm == "always" then
        nameFunc = function(unit)
          if not unit then
            return ""
          end
          local name, realm = WeakAuras.UnitNameWithRealm(unit)
          return name .. "-" .. realm
        end
      end

      if abbreviate then
        abbreviateFunc = function(input)
          return WeakAuras.WA_Utf8Sub(input, abbreviateMax)
        end
      end

      -- Do the checks on what is necessary here instead of inside the returned
      -- formatter
      if colorFunc then
        if abbreviateFunc then
          return function(unit)
            local name = abbreviateFunc(nameFunc(unit))
            return colorFunc(unit, name)
          end
        else
          return function(unit)
            local name = nameFunc(unit)
            return colorFunc(unit, name)
          end
        end
      else
        if abbreviateFunc then
          return function(unit)
            local name = nameFunc(unit)
            return abbreviateFunc(name)
          end
        else
          return nameFunc
        end
      end
    end
  },
  guid = {
    display = L["Formats Player's |cFFFF0000%guid|r"],
    AddOptions = function(symbol, hidden, addOption, get)
      addOption(symbol .. "_color", {
        type = "select",
        name = L["Color"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.unit_color_types,
        hidden = hidden,
      })
      addOption(symbol .. "_realm_name", {
        type = "select",
        name = L["Realm Name"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.unit_realm_name_types,
        hidden = hidden,
      })
      addOption(symbol .. "_abbreviate", {
        type = "toggle",
        name = L["Abbreviate"],
        width = WeakAuras.normalWidth,
        hidden = hidden,
      })
      addOption(symbol .. "_abbreviate_max", {
        type = "range",
        name = L["Max Char "],
        width = WeakAuras.normalWidth,
        hidden = hidden,
        min = 1,
        max = 20,
        hidden = hidden,
        disabled = function()
          return not get(symbol .. "_abbreviate")
        end
      })
    end,
    CreateFormatter = function(symbol, get)
      local color = get(symbol .. "_color", true)
      local realm = get(symbol .. "_realm_name", "never")
      local abbreviate = get(symbol .. "_abbreviate", false)
      local abbreviateMax = get(symbol .. "_abbreviate_max", 8)

      local nameFunc
      local colorFunc
      local abbreviateFunc
      if color == "class" then
        colorFunc = function(class, text)
          if class then
            return RAID_CLASS_COLORS[class]:WrapTextInColorCode(text)
          else
            return text
          end
        end
      end

      if realm == "never" then
        nameFunc = function(name, realm)
          return name
        end
      elseif realm == "star" then
        nameFunc = function(name, realm)
          if realm ~= "" then
            return name .. "*"
          end
          return name
        end
      elseif realm == "differentServer" then
        nameFunc = function(name, realm)
          if realm ~= "" then
            return name .. "-" .. realm
          end
          return name
        end
      elseif realm == "always" then
        nameFunc = function(name, realm)
          if realm == "" then
            realm = select(2, WeakAuras.UnitNameWithRealm("player"))
          end
          return name .. "-" .. realm
        end
      end

      if abbreviate then
        abbreviateFunc = function(input)
          return WeakAuras.WA_Utf8Sub(input, abbreviateMax)
        end
      end

      -- Do the checks on what is necessary here instead of inside the returned
      -- formatter
      if colorFunc then
        if abbreviateFunc then
          return function(guid)
            local ok, _, class, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, guid)
            if ok then
              local name = abbreviateFunc(nameFunc(name, realm))
              return colorFunc(class, name)
            end
          end
        else
          return function(guid)
            local ok, _, class, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, guid)
            if ok then
              return colorFunc(class, nameFunc(name, realm))
            end
          end
        end
      else
        if abbreviateFunc then
          return function(guid)
            local ok, _, class, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, guid)
            if ok then
              return abbreviateFunc(nameFunc(name, realm))
            end
          end
        else
          return function(guid)
            local ok, _, class, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, guid)
            if ok then
              return nameFunc(name, realm)
            end
          end
        end
      end
    end
  },
  GCDTime = {
    display = L["Time in GCDs"],
    AddOptions = function(symbol, hidden, addOption, get)
      addOption(symbol .. "_gcd_gcd", {
        type = "toggle",
        name = L["Subtract GCD"],
        width = WeakAuras.normalWidth,
        hidden = hidden
      })
      addOption(symbol .. "_gcd_cast", {
        type = "toggle",
        name = L["Subtract Cast"],
        width = WeakAuras.normalWidth,
        hidden = hidden
      })
      addOption(symbol .. "_gcd_channel", {
        type = "toggle",
        name = L["Subtract Channel"],
        width = WeakAuras.normalWidth,
        hidden = hidden
      })
      addOption(symbol .. "_gcd_hide_zero", {
        type = "toggle",
        name = L["Hide 0 cooldowns"],
        width = WeakAuras.normalWidth,
        hidden = hidden
      })

      addOption(symbol .. "_decimal_precision", {
        type = "select",
        name = L["Precision"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.precision_types,
        hidden = hidden
      })
      addOption(symbol .. "_round_type", {
        type = "select",
        name = L["Round Mode"],
        width = WeakAuras.normalWidth,
        values = WeakAuras.round_types,
        hidden = hidden,
        disabled = function()
          return get(symbol .. "_decimal_precision") ~= 0
        end
      })
    end,
    CreateFormatter = function(symbol, get)
      local gcd = get(symbol .. "_gcd_gcd", true)
      local cast = get(symbol .. "_gcd_cast", false)
      local channel = get(symbol .. "_gcd_channel", false)
      local hideZero = get(symbol .. "_gcd_hide_zero", false)
      local precision = get(symbol .. "_decimal_precision", 1)

      local numberToStringFunc
      if precision ~= 0 then
        local format = "%." .. precision .. "f"
        numberToStringFunc = function(number)
          return string.format(format, number)
        end
      else
        local type = get(symbol .. "_round_type", "ceil")
        numberToStringFunc = simpleFormatters[type]
      end

      return function(value, state)
        if state.progressType ~= "timed" or type(value) ~= "number" then
          return value
        end

        WeakAuras.WatchGCD()
        local result = value
        local now = GetTime()
        if gcd then
          local gcdDuration, gcdExpirationTime = WeakAuras.GetGCDInfo()
          if gcdDuration ~= 0 then
            result = now + value - gcdExpirationTime
          end
        end

        if cast then
          local _, _, _, _, endTime = WeakAuras.UnitCastingInfo("player")
          local castExpirationTIme = endTime and endTime > 0 and (endTime / 1000) or 0
          if castExpirationTIme > 0 then
            result = min(result, now + value - castExpirationTIme)
          end
        end
        if channel then
          local _, _, _, _, endTime = WeakAuras.UnitChannelInfo("player")
          local castExpirationTIme = endTime and endTime > 0 and (endTime / 1000) or 0
          if castExpirationTIme > 0 then
            result = min(result, now + value - castExpirationTIme)
          end
        end

        if result <= 0 then
          return hideZero and "" or "0"
        end

        return numberToStringFunc(result / WeakAuras.CalculatedGcdDuration())
      end
    end
  }
}

WeakAuras.format_types_display = {}
for k, v in pairs(WeakAuras.format_types) do WeakAuras.format_types_display[k] = v.display end


WeakAuras.sound_channel_types = {
  Master = L["Master"],
  SFX = ENABLE_SOUNDFX,
  Ambience = ENABLE_AMBIENCE,
  Music = ENABLE_MUSIC,
  Dialog = ENABLE_DIALOG
}

WeakAuras.sound_condition_types = {
  Play = L["Play"],
  Loop = L["Loop"],
  Stop = L["Stop"]
}

WeakAuras.trigger_require_types = {
  any = L["Any Triggers"],
  all = L["All Triggers"],
  custom = L["Custom Function"]
}

WeakAuras.trigger_require_types_one = {
  any = L["Trigger 1"],
  custom = L["Custom Function"]
}

WeakAuras.trigger_modes = {
  ["first_active"] = -10,
}

WeakAuras.debuff_types = {
  HELPFUL = L["Buff"],
  HARMFUL = L["Debuff"]
}

WeakAuras.tooltip_count = {
  [1] = L["First"],
  [2] = L["Second"],
  [3] = L["Third"]
}

WeakAuras.aura_types = {
  BUFF = L["Buff"],
  DEBUFF = L["Debuff"]
}

WeakAuras.debuff_class_types = {
  magic = L["Magic"],
  curse = L["Curse"],
  disease = L["Disease"],
  poison = L["Poison"],
  enrage = L["Enrage"],
  none = L["None"]
}

WeakAuras.unit_types = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  group = L["Group"],
  member = L["Specific Unit"],
  pet = L["Pet"],
  multi = L["Multi-target"]
}

WeakAuras.unit_types_bufftrigger_2 = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  group = L["Smart Group"],
  raid = L["Raid"],
  party = L["Party"],
  boss = L["Boss"],
  arena = L["Arena"],
  nameplate = L["Nameplate"],
  pet = L["Pet"],
  member = L["Specific Unit"],
  multi = L["Multi-target"]
}

WeakAuras.actual_unit_types_with_specific = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  pet = L["Pet"],
  member = L["Specific Unit"]
}

WeakAuras.actual_unit_types_cast = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  group = L["Smart Group"],
  party = L["Party"],
  raid = L["Raid"],
  boss = L["Boss"],
  arena = L["Arena"],
  nameplate = L["Nameplate"],
  pet = L["Pet"],
  member = L["Specific Unit"],
}

WeakAuras.actual_unit_types = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  pet = L["Pet"]
}

WeakAuras.threat_unit_types = {
  target = L["Target"],
  focus = L["Focus"],
  member = L["Specific Unit"],
  none = L["At Least One Enemy"]
}

WeakAuras.unit_types_range_check = {
  target = L["Target"],
  focus = L["Focus"],
  pet = L["Pet"],
  member = L["Specific Unit"]
}

WeakAuras.unit_threat_situation_types = {
  [-1] = L["Not On Threat Table"],
  [0] = "|cFFB0B0B0"..L["Lower Than Tank"],
  [1] = "|cFFFFFF77"..L["Higher Than Tank"],
  [2] = "|cFFFF9900"..L["Tanking But Not Highest"],
  [3] = "|cFFFF0000"..L["Tanking And Highest"]
}

WeakAuras.class_types = {}
WeakAuras.class_color_types = {} -- TODO: it should be removed together with Bufftrigger (unused)
for classID = 1, 20 do -- 20 is for GetNumClasses() but that function doesn't exists on Classic
  local classInfo = C_CreatureInfo.GetClassInfo(classID)
  if classInfo then
    if WeakAuras.IsClassic() then
      WeakAuras.class_types[classInfo.classFile] = WrapTextInColorCode(classInfo.className, select(4, GetClassColor(classInfo.classFile)))
      WeakAuras.class_color_types[classInfo.classFile] = select(4, GetClassColor(classInfo.classFile))
    else
      WeakAuras.class_types[classInfo.classFile] = C_ClassColor.GetClassColor(classInfo.classFile):WrapTextInColorCode(classInfo.className)
      WeakAuras.class_color_types[classInfo.classFile] = C_ClassColor.GetClassColor(classInfo.classFile):GenerateHexColorMarkup()
    end
  end
end

WeakAuras.race_types = {}
do
  local unplayableRace = {
    [12] = true,
    [13] = true,
    [14] = true,
    [15] = true,
    [16] = true,
    [17] = true,
    [18] = true,
    [19] = true,
    [20] = true,
    [21] = true,
    [23] = true,
    [33] = true
  }
  local raceID = 1
  local raceInfo = C_CreatureInfo.GetRaceInfo(raceID)
  while raceInfo do
    if not unplayableRace[raceID] then
      WeakAuras.race_types[raceInfo.clientFileString] = raceInfo.raceName
    end
    raceID = raceID + 1
    raceInfo = C_CreatureInfo.GetRaceInfo(raceID)
  end
end

WeakAuras.faction_group = {
  Alliance = L["Alliance"],
  Horde = L["Horde"],
  Neutral = L["Neutral"]
}

WeakAuras.form_types = {};
local function update_forms()
  wipe(WeakAuras.form_types);
  WeakAuras.form_types[0] = "0 - "..L["Humanoid"]
  for i = 1, GetNumShapeshiftForms() do
    local _, _, _, id = GetShapeshiftFormInfo(i);
    if(id) then
      local name = GetSpellInfo(id);
      if(name) then
        WeakAuras.form_types[i] = i.." - "..name
      end
    end
  end
end
local form_frame = CreateFrame("frame");
form_frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
form_frame:RegisterEvent("PLAYER_LOGIN")
form_frame:SetScript("OnEvent", update_forms);

WeakAuras.blend_types = {
  ADD = L["Glow"],
  BLEND = L["Opaque"]
}

WeakAuras.texture_wrap_types = {
  CLAMP = L["Clamp"],
  MIRROR = L["Mirror"],
  REPEAT = L["Repeat"]
}

WeakAuras.slant_mode = {
  INSIDE = L["Keep Inside"],
  EXTEND = L["Extend Outside"]
}

WeakAuras.text_check_types = {
  update = L["Every Frame"],
  event = L["Trigger Update"]
}

WeakAuras.check_types = {
  update = L["Every Frame"],
  event = L["Event(s)"]
}

WeakAuras.point_types = {
  BOTTOMLEFT = L["Bottom Left"],
  BOTTOM = L["Bottom"],
  BOTTOMRIGHT = L["Bottom Right"],
  RIGHT = L["Right"],
  TOPRIGHT = L["Top Right"],
  TOP = L["Top"],
  TOPLEFT = L["Top Left"],
  LEFT = L["Left"],
  CENTER = L["Center"]
}

WeakAuras.default_types_for_anchor = {}
for k, v in pairs(WeakAuras.point_types) do
  WeakAuras.default_types_for_anchor[k] = {
    display = v,
    type = "point"
  }
end

WeakAuras.default_types_for_anchor["ALL"] = {
  display = L["Whole Area"],
  type = "area"
}

WeakAuras.aurabar_anchor_areas = {
  icon = L["Icon"],
  fg = L["Foreground"],
  bg = L["Background"],
  bar = L["Bar"],
}

WeakAuras.inverse_point_types = {
  BOTTOMLEFT = "TOPRIGHT",
  BOTTOM = "TOP",
  BOTTOMRIGHT = "TOPLEFT",
  RIGHT = "LEFT",
  TOPRIGHT = "BOTTOMLEFT",
  TOP = "BOTTOM",
  TOPLEFT = "BOTTOMRIGHT",
  LEFT = "RIGHT",
  CENTER = "CENTER"
}

WeakAuras.anchor_frame_types = {
  SCREEN = L["Screen/Parent Group"],
  PRD = L["Personal Resource Display"],
  MOUSE = L["Mouse Cursor"],
  SELECTFRAME = L["Select Frame"],
  NAMEPLATE = WeakAuras.newFeatureString..L["Nameplates"],
  UNITFRAME = WeakAuras.newFeatureString..L["Unit Frames"],
  CUSTOM = WeakAuras.newFeatureString..L["Custom"]
}

WeakAuras.anchor_frame_types_group = {
  SCREEN = L["Screen/Parent Group"],
  PRD = L["Personal Resource Display"],
  MOUSE = L["Mouse Cursor"],
  SELECTFRAME = L["Select Frame"],
  CUSTOM = WeakAuras.newFeatureString..L["Custom"]
}

WeakAuras.spark_rotation_types = {
  AUTO = L["Automatic Rotation"],
  MANUAL = L["Manual Rotation"]
}

WeakAuras.spark_hide_types = {
  NEVER = L["Never"],
  FULL  = L["Full"],
  EMPTY = L["Empty"],
  BOTH  = L["Full/Empty"]
}

WeakAuras.tick_placement_modes = {
  AtValue = L["At Value"],
  AtMissingValue = L["At missing Value"],
  AtPercent = L["At Percent"],
  ValueOffset = L["Offset from progress"]
}

WeakAuras.containment_types = {
  OUTSIDE = L["Outside"],
  INSIDE = L["Inside"]
}

WeakAuras.font_flags = {
  None = L["None"],
  MONOCHROME = L["Monochrome"],
  OUTLINE = L["Outline"],
  THICKOUTLINE  = L["Thick Outline"],
  ["MONOCHROME|OUTLINE"] = L["Monochrome Outline"],
  ["MONOCHROME|THICKOUTLINE"] = L["Monochrome Thick Outline"]
}

WeakAuras.text_automatic_width = {
  Auto = L["Automatic"],
  Fixed = L["Fixed"]
}

WeakAuras.text_word_wrap = {
  WordWrap = L["Wrap"],
  Elide = L["Elide"]
}

WeakAuras.event_types = {};
for name, prototype in pairs(WeakAuras.event_prototypes) do
  if(prototype.type == "event") then
    WeakAuras.event_types[name] = prototype.name;
  end
end

WeakAuras.status_types = {};
for name, prototype in pairs(WeakAuras.event_prototypes) do
  if(prototype.type == "status") then
    WeakAuras.status_types[name] = prototype.name;
  end
end

WeakAuras.subevent_prefix_types = {
  SWING = L["Swing"],
  RANGE = L["Range"],
  SPELL = L["Spell"],
  SPELL_PERIODIC = L["Periodic Spell"],
  SPELL_BUILDING = L["Spell (Building)"],
  ENVIRONMENTAL = L["Environmental"],
  DAMAGE_SHIELD = L["Damage Shield"],
  DAMAGE_SPLIT = L["Damage Split"],
  DAMAGE_SHIELD_MISSED = L["Damage Shield Missed"],
  PARTY_KILL = L["Party Kill"],
  UNIT_DIED = L["Unit Died"],
  UNIT_DESTROYED = L["Unit Destroyed"],
  UNIT_DISSIPATES = L["Unit Dissipates"],
  ENCHANT_APPLIED = L["Enchant Applied"],
  ENCHANT_REMOVED = L["Enchant Removed"]
}

WeakAuras.subevent_actual_prefix_types = {
  SWING = L["Swing"],
  RANGE = L["Range"],
  SPELL = L["Spell"],
  SPELL_PERIODIC = L["Periodic Spell"],
  SPELL_BUILDING = L["Spell (Building)"],
  ENVIRONMENTAL = L["Environmental"]
}

WeakAuras.subevent_suffix_types = {
  _ABSORBED = L["Absorbed"],
  _DAMAGE = L["Damage"],
  _MISSED = L["Missed"],
  _HEAL = L["Heal"],
  _ENERGIZE = L["Energize"],
  _DRAIN = L["Drain"],
  _LEECH = L["Leech"],
  _INTERRUPT = L["Interrupt"],
  _DISPEL = L["Dispel"],
  _DISPEL_FAILED = L["Dispel Failed"],
  _STOLEN = L["Stolen"],
  _EXTRA_ATTACKS = L["Extra Attacks"],
  _AURA_APPLIED = L["Aura Applied"],
  _AURA_REMOVED = L["Aura Removed"],
  _AURA_APPLIED_DOSE = L["Aura Applied Dose"],
  _AURA_REMOVED_DOSE = L["Aura Removed Dose"],
  _AURA_REFRESH = L["Aura Refresh"],
  _AURA_BROKEN = L["Aura Broken"],
  _AURA_BROKEN_SPELL = L["Aura Broken Spell"],
  _CAST_START = L["Cast Start"],
  _CAST_SUCCESS = L["Cast Success"],
  _CAST_FAILED = L["Cast Failed"],
  _INSTAKILL = L["Instakill"],
  _DURABILITY_DAMAGE = L["Durability Damage"],
  _DURABILITY_DAMAGE_ALL = L["Durability Damage All"],
  _CREATE = L["Create"],
  _SUMMON = L["Summon"],
  _RESURRECT = L["Resurrect"]
}

WeakAuras.power_types = {
  [0] = POWER_TYPE_MANA,
  [1] = POWER_TYPE_RED_POWER,
  [2] = POWER_TYPE_FOCUS,
  [3] = POWER_TYPE_ENERGY,
  [4] = COMBO_POINTS,
  [6] = RUNIC_POWER,
  [7] = SOUL_SHARDS_POWER,
  [8] = POWER_TYPE_LUNAR_POWER,
  [9] = HOLY_POWER,
  [11] = POWER_TYPE_MAELSTROM,
  [12] = CHI_POWER,
  [13] = POWER_TYPE_INSANITY,
  [16] = POWER_TYPE_ARCANE_CHARGES,
  [17] = POWER_TYPE_FURY_DEMONHUNTER,
  [18] = POWER_TYPE_PAIN
}

WeakAuras.power_types_with_stagger = {
  [0] = POWER_TYPE_MANA,
  [1] = POWER_TYPE_RED_POWER,
  [2] = POWER_TYPE_FOCUS,
  [3] = POWER_TYPE_ENERGY,
  [4] = COMBO_POINTS,
  [6] = RUNIC_POWER,
  [7] = SOUL_SHARDS_POWER,
  [8] = POWER_TYPE_LUNAR_POWER,
  [9] = HOLY_POWER,
  [11] = POWER_TYPE_MAELSTROM,
  [12] = CHI_POWER,
  [13] = POWER_TYPE_INSANITY,
  [16] = POWER_TYPE_ARCANE_CHARGES,
  [17] = POWER_TYPE_FURY_DEMONHUNTER,
  [18] = POWER_TYPE_PAIN,
  [99] = STAGGER
}

WeakAuras.miss_types = {
  ABSORB = L["Absorb"],
  BLOCK = L["Block"],
  DEFLECT = L["Deflect"],
  DODGE = L["Dodge"],
  EVADE = L["Evade"],
  IMMUNE = L["Immune"],
  MISS = L["Miss"],
  PARRY = L["Parry"],
  REFLECT = L["Reflect"],
  RESIST = L["Resist"]
}

WeakAuras.environmental_types = {
  Drowning = STRING_ENVIRONMENTAL_DAMAGE_DROWNING,
  Falling = STRING_ENVIRONMENTAL_DAMAGE_FALLING,
  Fatigue = STRING_ENVIRONMENTAL_DAMAGE_FATIGUE,
  Fire = STRING_ENVIRONMENTAL_DAMAGE_FIRE,
  Lava = STRING_ENVIRONMENTAL_DAMAGE_LAVA,
  Slime = STRING_ENVIRONMENTAL_DAMAGE_SLIME
}

WeakAuras.combatlog_flags_check_type = {
  InGroup = L["In Group"],
  NotInGroup = L["Not in Group"]
}

WeakAuras.combatlog_flags_check_reaction = {
  Hostile = L["Hostile"],
  Neutral = L["Neutral"],
  Friendly = L["Friendly"]
}

WeakAuras.combatlog_flags_check_object_type = {
  Object = L["Object"],
  Guardian = L["Guardian"],
  Pet = L["Pet"],
  NPC = L["NPC"],
  Player = L["Player"]
}

WeakAuras.combatlog_raid_mark_check_type = {
  [0] = RAID_TARGET_NONE,
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1:14|t " .. RAID_TARGET_1, -- Star
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_2:14|t " .. RAID_TARGET_2, -- Circle
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_3:14|t " .. RAID_TARGET_3, -- Diamond
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_4:14|t " .. RAID_TARGET_4, -- Triangle
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_5:14|t " .. RAID_TARGET_5, -- Moon
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6:14|t " .. RAID_TARGET_6, -- Square
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_7:14|t " .. RAID_TARGET_7, -- Cross
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8:14|t " .. RAID_TARGET_8, -- Skull
  L["Any"]
}

WeakAuras.orientation_types = {
  HORIZONTAL_INVERSE = L["Left to Right"],
  HORIZONTAL = L["Right to Left"],
  VERTICAL = L["Bottom to Top"],
  VERTICAL_INVERSE = L["Top to Bottom"]
}

WeakAuras.orientation_with_circle_types = {
  HORIZONTAL_INVERSE = L["Left to Right"],
  HORIZONTAL = L["Right to Left"],
  VERTICAL = L["Bottom to Top"],
  VERTICAL_INVERSE = L["Top to Bottom"],
  CLOCKWISE = L["Clockwise"],
  ANTICLOCKWISE = L["Anticlockwise"]
}

WeakAuras.spec_types = {
  [1] = SPECIALIZATION.." 1",
  [2] = SPECIALIZATION.." 2",
  [3] = SPECIALIZATION.." 3",
  [4] = SPECIALIZATION.." 4"
}

WeakAuras.spec_types_3 = {
  [1] = SPECIALIZATION.." 1",
  [2] = SPECIALIZATION.." 2",
  [3] = SPECIALIZATION.." 3"
}

WeakAuras.spec_types_2 = {
  [1] = SPECIALIZATION.." 1",
  [2] = SPECIALIZATION.." 2"
}

WeakAuras.spec_types_specific = {}
WeakAuras.spec_types_all = {}
local function update_specs()
  for classFileName, classID in pairs(WeakAuras.class_ids) do
    WeakAuras.spec_types_specific[classFileName] = {}
    local classTexcoords = CLASS_ICON_TCOORDS[classFileName]
    local numSpecs = GetNumSpecializationsForClassID(classID)
    for i=1, numSpecs do
      local specId, tabName, _, icon = GetSpecializationInfoForClassID(classID, i);
      if tabName then
        tinsert(WeakAuras.spec_types_specific[classFileName], "|T"..(icon or "error")..":0|t "..(tabName or "error"));
        WeakAuras.spec_types_all[specId] = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:256:256:"
         .. classTexcoords[1] * 256 .. ":" .. classTexcoords[2] * 256 .. ":" .. classTexcoords[3] * 256 .. ":" .. classTexcoords[4] * 256
         .. ":0|t"
         .. "|T"..(icon or "error")..":0|t "..(tabName or "error");
      end
    end
  end
end


WeakAuras.talent_types = {}
if not WeakAuras.IsClassic() then
  local spec_frame = CreateFrame("frame");
  spec_frame:RegisterEvent("PLAYER_LOGIN")
  spec_frame:SetScript("OnEvent", update_specs);
  local numTalents, numTiers, numColumns = MAX_TALENT_TIERS * NUM_TALENT_COLUMNS, MAX_TALENT_TIERS, NUM_TALENT_COLUMNS
  local talentId, tier, column = 1, 1, 1
  while talentId <= numTalents do
    while tier <= numTiers do
      while column <= numColumns do
        WeakAuras.talent_types[talentId] = L["Tier "]..tier.." - "..column
        column = column + 1
        talentId = talentId + 1
      end
      column = 1
      tier = tier + 1
    end
    tier = 1
  end
else
  for tab = 1, 5 do
    for num_talent = 1, 20 do
      local talentId = (tab - 1)*20+num_talent
      WeakAuras.talent_types[talentId] = L["Tab "]..tab.." - "..num_talent
    end
  end
end

if not WeakAuras.IsClassic() then
  WeakAuras.pvp_talent_types = {
    select(2, GetPvpTalentInfoByID(3589)),
    select(2, GetPvpTalentInfoByID(3588)),
    select(2, GetPvpTalentInfoByID(3587)),
    nil
  };
  for i = 1,10 do
    tinsert(WeakAuras.pvp_talent_types, string.format(L["PvP Talent %i"], i));
  end
else
  WeakAuras.pvp_talent_types = {}
end

-- GetTotemInfo() only works for the first 5 totems
WeakAuras.totem_types = {};
local totemString = L["Totem #%i"];
for i = 1, 5 do
  WeakAuras.totem_types[i] = totemString:format(i);
end

WeakAuras.texture_types = {
  ["Blizzard Alerts"] = {
    ["1027131"]	= "Arcane Missiles 1",
    ["1027132"]	= "Arcane Missiles 2",
    ["1027133"]	= "Arcane Missiles 3",
    ["450913"] 	= "Art of War",
    ["801266"] 	= "Backlash_Green",
    ["460830"] 	= "Backslash",
    ["1030393"]	= "Bandits Guile",
    ["510822"] 	= "Berserk",
    ["511104"] 	= "Blood Boil",
    ["449487"] 	= "Blood Surge",
    ["449488"] 	= "Brain Freeze",
    ["603338"] 	= "Dark Tiger",
    ["461878"] 	= "Dark Transformation",
    ["459313"] 	= "Daybreak",
    ["511469"] 	= "Denounce",
    ["1057288"]	= "Echo of the Elements",
    ["450914"] 	= "Eclipse Moon",
    ["450915"] 	= "Eclipse Sun",
    ["450916"] 	= "Focus Fire",
    ["449489"] 	= "Frozen Fingers",
    ["467696"] 	= "Fulmination",
    ["460831"] 	= "Fury of Stormrage",
    ["450917"] 	= "Generic Arc 1",
    ["450918"] 	= "Generic Arc 2",
    ["450919"] 	= "Generic Arc 3",
    ["450920"] 	= "Generic Arc 4",
    ["450921"] 	= "Generic Arc 5",
    ["450922"] 	= "Generic Arc 6",
    ["450923"] 	= "Generic Top 1",
    ["450924"] 	= "Generic Top 2",
    ["450925"] 	= "Grand Crusader",
    ["459314"] 	= "Hand of Light",
    ["449490"] 	= "Hot Streak",
    ["801267"] 	= "Imp Empowerment Green",
    ["449491"] 	= "Imp Empowerment",
    ["457658"] 	= "Impact",
    ["458740"] 	= "Killing Machine",
    ["450926"] 	= "Lock and Load",
    ["1028136"]	= "Maelstrom Weapon 1",
    ["1028137"]	= "Maelstrom Weapon 2",
    ["1028138"]	= "Maelstrom Weapon 3",
    ["1028139"]	= "Maelstrom Weapon 4",
    ["450927"] 	= "Maelstrom Weapon",
    ["450928"] 	= "Master Marksman",
    ["801268"] 	= "Molten Core Green",
    ["458741"] 	= "Molten Core",
    ["1001511"]	= "Monk Blackout Kick",
    ["1028091"]	= "Monk Ox 2",
    ["1028092"]	= "Monk Ox 3",
    ["623950"] 	= "Monk Ox",
    ["623951"] 	= "Monk Serpent",
    ["1001512"]	= "Monk Tiger Palm",
    ["623952"] 	= "Monk Tiger",
    ["450929"] 	= "Nature's Grace",
    ["511105"] 	= "Necropolis",
    ["449492"] 	= "Nightfall",
    ["510823"] 	= "Omen of Clarity (Feral)",
    ["898423"] 	= "Predatory Swiftness",
    ["962497"] 	= "Raging Blow",
    ["450930"] 	= "Rime",
    ["469752"] 	= "Serendipity",
    ["656728"] 	= "Shadow Word Insanity",
    ["627609"] 	= "Shadow of Death",
    ["463452"] 	= "Shooting Stars",
    ["450931"] 	= "Slice and Dice",
    ["424570"] 	= "Spell Activation Overlay 0",
    ["449493"] 	= "Sudden Death",
    ["450932"] 	= "Sudden Doom",
    ["592058"] 	= "Surge of Darkness",
    ["450933"] 	= "Surge of Light",
    ["449494"] 	= "Sword and Board",
    ["1029138"]	= "Thrill of the Hunt 1",
    ["1029139"]	= "Thrill of the Hunt 2",
    ["1029140"]	= "Thrill of the Hunt 3",
    ["774420"] 	= "Tooth and Claw",
    ["627610"] 	= "Ultimatum",
    ["603339"] 	= "White Tiger",
  },
  ["Icons"] = {
    ["166662"] = "Shield",
    ["165558"] = "Paw",
    ["166989"] = "Stun Whirl",
    ["166036"] = "Rage",
    ["165610"] = "Monkey",
    ["165607"] = "Lion",
    ["240925"] = "Holy Ruin",
    ["166058"] = "Eyes",
    ["166606"] = "Leaf",
    ["166706"] = "Reticle",
    ["166984"] = "Crossed Swords",
    ["166418"] = "Inner Fire",
    ["165608"] = "Cheetah",
    ["240972"] = "Poison Skull",
    ["166680"] = "Rampage",
    ["165605"] = "Feathers",
    ["166423"] = "Intellect",
    ["165609"] = "Hawk",
    ["240961"] = "Crescent",
    ["166056"] = "Eye",
    ["165611"] = "Snake",
    ["241049"] = "Star",
    ["166386"] = "Snowflake",
    ["165612"] = "Wolf",
    ["166948"] = "Spirit",
    ["166954"] = "Bull",
    ["166683"] = "Rapid Fire",
    ["166125"] = "Fire",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\cancel-icon.tga"] = "Cancel Icon",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\cancel-mark.tga"] = "Cancel Mark",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\emoji.tga"] = "Emoji",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\exclamation-mark.tga"] = "Exclamation Mark",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\eyes.tga"] = "Eyes",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\ok-icon.tga"] = "Ok Icon",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\targeting-mark.tga"] = "Targeting Mark",

  },
  ["Runes"] = {
    ["165630"] = "Ringed Aura Rune",
    ["166341"] = "Holy Cross Rune",
    ["166757"] = "Circular Frost Rune",
    ["241005"] = "Dense Circular Rune",
    ["165927"] = "Demon Rune",
    ["241004"] = "Octagonal Skulls",
    ["166753"] = "Heavy BC Rune",
    ["165638"] = "Small Tri-Circle Aura Rune",
    ["165639"] = "Sliced Aura Rune",
    ["165885"] = "Death Rune",
    ["166749"] = "Ringed Circular Rune",
    ["165922"] = "Demonic Summon",
    ["165928"] = "Demon Rune",
    ["165633"] = "Tri-Circle Aura Rune",
    ["165929"] = "Demon Rune",
    ["165634"] = "Tri-Circle Ringed Aura Rune",
    ["165635"] = "Spike-Ringed Aura Rune",
    ["166750"] = "Sparse Circular Rune",
    ["241003"] = "Dual Blades",
    ["165631"] = "Square Aura Rune",
    ["165881"] = "Dark Summon",
    ["166340"] = "Holy Rune",
    ["165640"] = "Oblong Aura Rune",
    ["166748"] = "Filled Circular Rune",
    ["166754"] = "Light BC Rune",
    ["166979"] = "Star Rune",
  },
  ["PvP Emblems"] = {
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-1"] = "Wheelchair",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-2"] = "Recycle",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-3"] = "Biohazard",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-4"] = "Heart",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-5"] = "Lightning Bolt",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-6"] = "Bone",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-7"] = "Glove",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-2"] = "Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-3"] = "Bird Claw",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-4"] = "Canary",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-5"] = "Mushroom",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-6"] = "Cherries",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-7"] = "Ninja",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-8"] = "Dog Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-9"] = "Circled Drop",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-10"] = "Circled Glove",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-11"] = "Winged Blade",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-12"] = "Circled Cross",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-13"] = "Dynamite",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-14"] = "Intellect",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-15"] = "Feather",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-16"] = "Present",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-17"] = "Giant Jaws",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-18"] = "Drums",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-19"] = "Panda",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-20"] = "Crossed Clubs",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-21"] = "Skeleton Key",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-22"] = "Heart Potion",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-23"] = "Trophy",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-24"] = "Crossed Mallets",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-25"] = "Circled Cheetah",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-26"] = "Mutated Chicken",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-27"] = "Anvil",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-28"] = "Dwarf Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-29"] = "Brooch",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-30"] = "Spider",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-31"] = "Dual Hawks",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-32"] = "Cleaver",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-33"] = "Spiked Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-34"] = "Fist of Thunder",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-35"] = "Lean Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-36"] = "Mug",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-37"] = "Sliced Circle",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-38"] = "Totem",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-39"] = "Skull and Crossbones",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-40"] = "Voodoo Doll",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-41"] = "Dual Wolves",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-42"] = "Wolf",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-43"] = "Crossed Wrenches",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-44"] = "Saber-toothed Tiger",
    --["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-45"] = "Targeting Eye", -- Duplicate of 53
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-46"] = "Artifact Disc",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-47"] = "Dice",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-48"] = "Fish Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-49"] = "Crossed Axes",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-50"] = "Doughnut",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-51"] = "Human Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-52"] = "Eyeball",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-53"] = "Targeting Eye",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-54"] = "Monkey Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-55"] = "Circle Skull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-56"] = "Tipped Glass",
    --["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-57"] = "Saber-toothed Tiger", -- Duplicate of 44
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-58"] = "Pile of Weapons",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-59"] = "Mushrooms",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-60"] = "Pounding Mallet",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-61"] = "Winged Mask",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-62"] = "Axe",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-63"] = "Spiked Shield",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-64"] = "The Horns",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-65"] = "Ice Cream Cone",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-66"] = "Ornate Lockbox",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-67"] = "Roasting Marshmallow",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-68"] = "Smiley Bomb",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-69"] = "Fist",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-70"] = "Spirit Wings",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-71"] = "Ornate Pipe",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-72"] = "Scarab",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-73"] = "Glowing Ball",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-74"] = "Circular Rune",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-75"] = "Tree",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-76"] = "Flower Pot",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-77"] = "Night Elf Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-78"] = "Nested Egg",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-79"] = "Helmed Chicken",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-80"] = "Winged Boot",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-81"] = "Skull and Cross-Wrenches",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-82"] = "Cracked Skull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-83"] = "Rocket",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-84"] = "Wooden Whistle",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-85"] = "Cogwheel",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-86"] = "Lizard Eye",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-87"] = "Baited Hook",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-88"] = "Beast Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-89"] = "Talons",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-90"] = "Rabbit",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-91"] = "4-Toed Pawprint",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-92"] = "Paw",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-93"] = "Mask",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-94"] = "Spiked Helm",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-95"] = "Dog Treat",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-96"] = "Targeted Orc",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-97"] = "Bird Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-98"] = "Lollipop",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-99"] = "5-Toed Pawprint",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-100"] = "Frightened Cat",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-101"] = "Eagle Face"
  },
  ["Beams"] = {
    ["186198"] = "Lightning",
    ["186187"] = "Red Drops Beam",
    ["167096"] = "Gold Chain",
    ["186205"] = "Mana Burn Beam",
    ["186208"] = "Rope",
    ["186185"] = "Purple Beam",
    ["167099"] = "Red Fire Beam",
    ["186214"] = "Soul Beam",
    ["186189"] = "Drain Mana Lightning",
    ["167103"] = "Red Vine",
    ["186192"] = "Ethereal Ribbon",
    ["186201"] = "Red Lightning",
    ["241099"] = "Summon Gargoyle Beam",
    ["167104"] = "Blue Water Beam",
    ["167098"] = "Green Fire Beam",
    ["186186"] = "Red Beam",
    ["167101"] = "Grey Smoke Beam",
    ["186194"] = "Purple Ghost Chain",
    ["167102"] = "Green Vine",
    ["369750"] = "Shadow Beam",
    ["186195"] = "Heal Beam",
    ["167100"] = "Brown Smoke Beam",
    ["186202"] = "Mana Beam",
    ["369749"] = "Straight Purple Beam",
    ["241098"] = "Spirit Link Beam",
    ["167105"] = "Green Water Beam",
    ["167097"] = "Iron Chain",
    ["186193"] = "Ghost Chain",
    ["186211"] = "Shock Lightning",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\rainbowbar"] = "Rainbow Bar",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\StripedTexture"] = "Striped Bar",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\stripe-bar.tga"] = "Striped Bar 2",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\stripe-rainbow-bar.tga"] = "Rainbow Bar 2",
  },
  ["Shapes"] = {
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth"] = "Smooth Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth_Border"] = "Smooth Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Squirrel"] = "Spiralled Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Squirrel_Border"] = "Spiralled Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_White"] = "Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_White_Border"] = "Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth"] = "Smooth Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border"] = "Smooth Square with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border2"] = "Smooth Square with Border 2",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Squirrel"] = "Spiralled Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Squirrel_Border"] = "Spiralled Square with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White"] = "Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White_Border"] = "Square with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite"] = "Full White Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Triangle45"] = "45° Triangle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Trapezoid"] = "Trapezoid",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\triangle-border.tga"] = "Triangle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\triangle.tga"] = "Triangle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth2.tga"] = "Smooth Circle Small",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\circle_border5.tga"] = "Circle Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\ring_glow3.tga"] = "Circle Border Glow",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\square_mini.tga"] = "Small Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\target_indicator.tga"] = "Target Indicator",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\target_indicator_glow.tga"] = "Target Indicator Glow",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\arrows_target.tga"] = "Arrows Target",

    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_AlphaGradient_In.tga"] = "Circle Alpha Gradient In",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_AlphaGradient_Out.tga"] = "Circle Alpha Gradient Out",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_10px.tga"] = "Ring 10px",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"] = "Ring 20px",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_30px.tga"] = "Ring 30px",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_40px.tga"] = "Ring 40px",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_AlphaGradient.tga"] = "Square Alpha Gradient",
  },
  ["Sparks"] = {
    ["130877"] = "Blizzard Spark",
    ["Insanity-Spark"] = "Blizzard Insanity Spark",
    ["XPBarAnim-OrangeSpark"] = "Blizzard XPBar Spark",
    ["GarrMission_EncounterBar-Spark"] = "Blizzard Garrison Mission Encounter Spark",
    ["Legionfall_BarSpark"]= "Blizzard Legionfall Spark",
    ["honorsystem-bar-spark"] = "Blizzard Honor System Spark",
    ["bonusobjectives-bar-spark"] = "Bonus Objectives Spark"
  },
  [BINDING_HEADER_RAID_TARGET] = {
    ["Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"] = RAID_TARGET_1,
    ["Interface\\TargetingFrame\\UI-RaidTargetingIcon_2"] = RAID_TARGET_2,
    ["Interface\\TargetingFrame\\UI-RaidTargetingIcon_3"] = RAID_TARGET_3,
    ["Interface\\TargetingFrame\\UI-RaidTargetingIcon_4"] = RAID_TARGET_4,
    ["Interface\\TargetingFrame\\UI-RaidTargetingIcon_5"] = RAID_TARGET_5,
    ["Interface\\TargetingFrame\\UI-RaidTargetingIcon_6"] = RAID_TARGET_6,
    ["Interface\\TargetingFrame\\UI-RaidTargetingIcon_7"] = RAID_TARGET_7,
    ["Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"] = RAID_TARGET_8,
  }
}
local BuildInfo = select(4, GetBuildInfo())
if BuildInfo <= 80100 then -- 8.1.5
  WeakAuras.texture_types.Sparks["worldstate-capturebar-spark-green"] = "Capture Bar Green Spark"
  WeakAuras.texture_types.Sparks["worldstate-capturebar-spark-yellow"] = "Capture Bar Yellow Spark"
end
if WeakAuras.IsClassic() then -- Classic
  WeakAuras.texture_types["Blizzard Alerts"] = nil
  do
    local beams = WeakAuras.texture_types["Beams"]
    local beams_ids = {167096, 167097, 167098, 167099, 167100, 167101, 167102, 167103, 167104, 167105, 186192, 186193, 186194, 241098, 241099, 369749, 369750}
    for _, v in ipairs(beams_ids) do
      beams[tostring(v)] = nil
    end
  end
  do
    local icons = WeakAuras.texture_types["Icons"]
    local icons_ids = {165605, 166036, 166680, 166948, 166989, 240925, 240961, 240972, 241049}
    for _, v in ipairs(icons_ids) do
      icons[tostring(v)] = nil
    end
  end
  do
    local runes = WeakAuras.texture_types["Runes"]
    local runes_ids = {165633, 165885, 165922, 166340, 166753, 166754, 241003, 241004, 241005}
    for _, v in ipairs(runes_ids) do
      runes[tostring(v)] = nil
    end
  end
end

if(WeakAuras.PowerAurasPath ~= "") then
  WeakAuras.texture_types["PowerAuras Heads-Up"] = {
    [WeakAuras.PowerAurasPath.."Aura1"] = "Runed Text",
    [WeakAuras.PowerAurasPath.."Aura2"] = "Runed Text On Ring",
    [WeakAuras.PowerAurasPath.."Aura3"] = "Power Waves",
    [WeakAuras.PowerAurasPath.."Aura4"] = "Majesty",
    [WeakAuras.PowerAurasPath.."Aura5"] = "Runed Ends",
    [WeakAuras.PowerAurasPath.."Aura6"] = "Extra Majesty",
    [WeakAuras.PowerAurasPath.."Aura7"] = "Triangular Highlights",
    [WeakAuras.PowerAurasPath.."Aura11"] = "Oblong Highlights",
    [WeakAuras.PowerAurasPath.."Aura16"] = "Thin Crescents",
    [WeakAuras.PowerAurasPath.."Aura17"] = "Crescent Highlights",
    [WeakAuras.PowerAurasPath.."Aura18"] = "Dense Runed Text",
    [WeakAuras.PowerAurasPath.."Aura23"] = "Runed Spiked Ring",
    [WeakAuras.PowerAurasPath.."Aura24"] = "Smoke",
    [WeakAuras.PowerAurasPath.."Aura28"] = "Flourished Text",
    [WeakAuras.PowerAurasPath.."Aura33"] = "Droplet Highlights"
  }
  WeakAuras.texture_types["PowerAuras Icons"] = {
    [WeakAuras.PowerAurasPath.."Aura8"] = "Rune",
    [WeakAuras.PowerAurasPath.."Aura9"] = "Stylized Ghost",
    [WeakAuras.PowerAurasPath.."Aura10"] = "Skull and Crossbones",
    [WeakAuras.PowerAurasPath.."Aura12"] = "Snowflake",
    [WeakAuras.PowerAurasPath.."Aura13"] = "Flame",
    [WeakAuras.PowerAurasPath.."Aura14"] = "Holy Rune",
    [WeakAuras.PowerAurasPath.."Aura15"] = "Zig-Zag Exclamation Point",
    [WeakAuras.PowerAurasPath.."Aura19"] = "Crossed Swords",
    [WeakAuras.PowerAurasPath.."Aura21"] = "Shield",
    [WeakAuras.PowerAurasPath.."Aura22"] = "Glow",
    [WeakAuras.PowerAurasPath.."Aura25"] = "Cross",
    [WeakAuras.PowerAurasPath.."Aura26"] = "Droplet",
    [WeakAuras.PowerAurasPath.."Aura27"] = "Alert",
    [WeakAuras.PowerAurasPath.."Aura29"] = "Paw",
    [WeakAuras.PowerAurasPath.."Aura30"] = "Bull",
    --   [WeakAuras.PowerAurasPath.."Aura31"] = "Hieroglyphics Horizontal",
    [WeakAuras.PowerAurasPath.."Aura32"] = "Hieroglyphics",
    [WeakAuras.PowerAurasPath.."Aura34"] = "Circled Arrow",
    [WeakAuras.PowerAurasPath.."Aura35"] = "Short Sword",
    --   [WeakAuras.PowerAurasPath.."Aura36"] = "Short Sword Horizontal",
    [WeakAuras.PowerAurasPath.."Aura45"] = "Circular Glow",
    [WeakAuras.PowerAurasPath.."Aura48"] = "Totem",
    [WeakAuras.PowerAurasPath.."Aura49"] = "Dragon Blade",
    [WeakAuras.PowerAurasPath.."Aura50"] = "Ornate Design",
    [WeakAuras.PowerAurasPath.."Aura51"] = "Inverted Holy Rune",
    [WeakAuras.PowerAurasPath.."Aura52"] = "Stylized Skull",
    [WeakAuras.PowerAurasPath.."Aura53"] = "Exclamation Point",
    [WeakAuras.PowerAurasPath.."Aura54"] = "Nonagon",
    [WeakAuras.PowerAurasPath.."Aura68"] = "Wings",
    [WeakAuras.PowerAurasPath.."Aura69"] = "Rectangle",
    [WeakAuras.PowerAurasPath.."Aura70"] = "Low Mana",
    [WeakAuras.PowerAurasPath.."Aura71"] = "Ghostly Eye",
    [WeakAuras.PowerAurasPath.."Aura72"] = "Circle",
    [WeakAuras.PowerAurasPath.."Aura73"] = "Ring",
    [WeakAuras.PowerAurasPath.."Aura74"] = "Square",
    [WeakAuras.PowerAurasPath.."Aura75"] = "Square Brackets",
    [WeakAuras.PowerAurasPath.."Aura76"] = "Bob-omb",
    [WeakAuras.PowerAurasPath.."Aura77"] = "Goldfish",
    [WeakAuras.PowerAurasPath.."Aura78"] = "Check",
    [WeakAuras.PowerAurasPath.."Aura79"] = "Ghostly Face",
    [WeakAuras.PowerAurasPath.."Aura84"] = "Overlapping Boxes",
    --   [WeakAuras.PowerAurasPath.."Aura85"] = "Overlapping Boxes 45°",
    --   [WeakAuras.PowerAurasPath.."Aura86"] = "Overlapping Boxes 270°",
    [WeakAuras.PowerAurasPath.."Aura87"] = "Fairy",
    [WeakAuras.PowerAurasPath.."Aura88"] = "Comet",
    [WeakAuras.PowerAurasPath.."Aura95"] = "Dual Spiral",
    [WeakAuras.PowerAurasPath.."Aura96"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura97"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura98"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura99"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura100"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura101"] = "Ball of Flame",
    [WeakAuras.PowerAurasPath.."Aura102"] = "Zig-Zag",
    [WeakAuras.PowerAurasPath.."Aura103"] = "Thorny Ring",
    [WeakAuras.PowerAurasPath.."Aura110"] = "Hunter's Mark",
    --   [WeakAuras.PowerAurasPath.."Aura111"] = "Hunter's Mark Horizontal",
    [WeakAuras.PowerAurasPath.."Aura112"] = "Kaleidoscope",
    [WeakAuras.PowerAurasPath.."Aura113"] = "Jesus Face",
    [WeakAuras.PowerAurasPath.."Aura114"] = "Green Mushroom",
    [WeakAuras.PowerAurasPath.."Aura115"] = "Red Mushroom",
    [WeakAuras.PowerAurasPath.."Aura116"] = "Fire Flower",
    [WeakAuras.PowerAurasPath.."Aura117"] = "Radioactive",
    [WeakAuras.PowerAurasPath.."Aura118"] = "X",
    [WeakAuras.PowerAurasPath.."Aura119"] = "Flower",
    [WeakAuras.PowerAurasPath.."Aura120"] = "Petal",
    [WeakAuras.PowerAurasPath.."Aura130"] = "Shoop Da Woop",
    [WeakAuras.PowerAurasPath.."Aura131"] = "8-Bit Symbol",
    [WeakAuras.PowerAurasPath.."Aura132"] = "Cartoon Skull",
    [WeakAuras.PowerAurasPath.."Aura138"] = "Stop",
    [WeakAuras.PowerAurasPath.."Aura139"] = "Thumbs Up",
    [WeakAuras.PowerAurasPath.."Aura140"] = "Palette",
    [WeakAuras.PowerAurasPath.."Aura141"] = "Blue Ring",
    [WeakAuras.PowerAurasPath.."Aura142"] = "Ornate Ring",
    [WeakAuras.PowerAurasPath.."Aura143"] = "Ghostly Skull"
  }
  WeakAuras.texture_types["PowerAuras Separated"] = {
    [WeakAuras.PowerAurasPath.."Aura46"] = "8-Part Ring 1",
    [WeakAuras.PowerAurasPath.."Aura47"] = "8-Part Ring 2",
    [WeakAuras.PowerAurasPath.."Aura55"] = "Skull on Gear 1",
    [WeakAuras.PowerAurasPath.."Aura56"] = "Skull on Gear 2",
    [WeakAuras.PowerAurasPath.."Aura57"] = "Skull on Gear 3",
    [WeakAuras.PowerAurasPath.."Aura58"] = "Skull on Gear 4",
    [WeakAuras.PowerAurasPath.."Aura59"] = "Rune Ring Full",
    [WeakAuras.PowerAurasPath.."Aura60"] = "Rune Ring Empty",
    [WeakAuras.PowerAurasPath.."Aura61"] = "Rune Ring Left",
    [WeakAuras.PowerAurasPath.."Aura62"] = "Rune Ring Right",
    [WeakAuras.PowerAurasPath.."Aura63"] = "Spiked Rune Ring Full",
    [WeakAuras.PowerAurasPath.."Aura64"] = "Spiked Rune Ring Empty",
    [WeakAuras.PowerAurasPath.."Aura65"] = "Spiked Rune Ring Left",
    [WeakAuras.PowerAurasPath.."Aura66"] = "Spiked Rune Ring Bottom",
    [WeakAuras.PowerAurasPath.."Aura67"] = "Spiked Rune Ring Right",
    [WeakAuras.PowerAurasPath.."Aura80"] = "Spiked Helm Background",
    [WeakAuras.PowerAurasPath.."Aura81"] = "Spiked Helm Full",
    [WeakAuras.PowerAurasPath.."Aura82"] = "Spiked Helm Bottom",
    [WeakAuras.PowerAurasPath.."Aura83"] = "Spiked Helm Top",
    [WeakAuras.PowerAurasPath.."Aura89"] = "5-Part Ring 1",
    [WeakAuras.PowerAurasPath.."Aura90"] = "5-Part Ring 2",
    [WeakAuras.PowerAurasPath.."Aura91"] = "5-Part Ring 3",
    [WeakAuras.PowerAurasPath.."Aura92"] = "5-Part Ring 4",
    [WeakAuras.PowerAurasPath.."Aura93"] = "5-Part Ring 5",
    [WeakAuras.PowerAurasPath.."Aura94"] = "5-Part Ring Full",
    [WeakAuras.PowerAurasPath.."Aura104"] = "Shield Center",
    [WeakAuras.PowerAurasPath.."Aura105"] = "Shield Full",
    [WeakAuras.PowerAurasPath.."Aura106"] = "Shield Top Right",
    [WeakAuras.PowerAurasPath.."Aura107"] = "Shiled Top Left",
    [WeakAuras.PowerAurasPath.."Aura108"] = "Shield Bottom Right",
    [WeakAuras.PowerAurasPath.."Aura109"] = "Shield Bottom Left",
    [WeakAuras.PowerAurasPath.."Aura121"] = "Vine Top Right Leaf",
    [WeakAuras.PowerAurasPath.."Aura122"] = "Vine Left Leaf",
    [WeakAuras.PowerAurasPath.."Aura123"] = "Vine Bottom Right Leaf",
    [WeakAuras.PowerAurasPath.."Aura124"] = "Vine Stem",
    [WeakAuras.PowerAurasPath.."Aura125"] = "Vine Thorns",
    [WeakAuras.PowerAurasPath.."Aura126"] = "3-Part Circle 1",
    [WeakAuras.PowerAurasPath.."Aura127"] = "3-Part Circle 2",
    [WeakAuras.PowerAurasPath.."Aura128"] = "3-Part Circle 3",
    [WeakAuras.PowerAurasPath.."Aura129"] = "3-Part Circle Full",
    [WeakAuras.PowerAurasPath.."Aura133"] = "Sliced Orb 1",
    [WeakAuras.PowerAurasPath.."Aura134"] = "Sliced Orb 2",
    [WeakAuras.PowerAurasPath.."Aura135"] = "Sliced Orb 3",
    [WeakAuras.PowerAurasPath.."Aura136"] = "Sliced Orb 4",
    [WeakAuras.PowerAurasPath.."Aura137"] = "Sliced Orb 5",
    [WeakAuras.PowerAurasPath.."Aura144"] = "Taijitu Bottom",
    [WeakAuras.PowerAurasPath.."Aura145"] = "Taijitu Top"
  }
  WeakAuras.texture_types["PowerAuras Words"] = {
    [WeakAuras.PowerAurasPath.."Aura20"] = "Power",
    [WeakAuras.PowerAurasPath.."Aura37"] = "Slow",
    [WeakAuras.PowerAurasPath.."Aura38"] = "Stun",
    [WeakAuras.PowerAurasPath.."Aura39"] = "Silence",
    [WeakAuras.PowerAurasPath.."Aura40"] = "Root",
    [WeakAuras.PowerAurasPath.."Aura41"] = "Disorient",
    [WeakAuras.PowerAurasPath.."Aura42"] = "Dispel",
    [WeakAuras.PowerAurasPath.."Aura43"] = "Danger",
    [WeakAuras.PowerAurasPath.."Aura44"] = "Buff",
    [WeakAuras.PowerAurasPath.."Aura44"] = "Buff",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\interrupt"] = "Interrupt"
  }
end

WeakAuras.operator_types = {
  ["=="] = "=",
  ["~="] = "!=",
  [">"] = ">",
  ["<"] = "<",
  [">="] = ">=",
  ["<="] = "<="
}

WeakAuras.equality_operator_types = {
  ["=="] = "=",
  ["~="] = "!="
}

WeakAuras.operator_types_without_equal = {
  [">="] = ">=",
  ["<="] = "<="
}

WeakAuras.string_operator_types = {
  ["=="] = L["Is Exactly"],
  ["find('%s')"] = L["Contains"],
  ["match('%s')"] = L["Matches (Pattern)"]
}

WeakAuras.weapon_types = {
  ["main"] = MAINHANDSLOT,
  ["off"] = SECONDARYHANDSLOT
}

WeakAuras.swing_types = {
  ["main"] = MAINHANDSLOT,
  ["off"] = SECONDARYHANDSLOT
}

if WeakAuras.IsClassic() then
  WeakAuras.swing_types["ranged"] = RANGEDSLOT
end

WeakAuras.rune_specific_types = {
  [1] = L["Rune #1"],
  [2] = L["Rune #2"],
  [3] = L["Rune #3"],
  [4] = L["Rune #4"],
  [5] = L["Rune #5"],
  [6] = L["Rune #6"]
}

WeakAuras.custom_trigger_types = {
  ["event"] = L["Event"],
  ["status"] = L["Status"],
  ["stateupdate"] = L["Trigger State Updater (Advanced)"]
}

WeakAuras.eventend_types = {
  ["timed"] = L["Timed"],
  ["custom"] = L["Custom"]
}

WeakAuras.autoeventend_types = {
  ["auto"] = L["Automatic"],
  ["custom"] = L["Custom"]
}

WeakAuras.timedeventend_types = {
  ["timed"] = L["Timed"],
}

WeakAuras.justify_types = {
  ["LEFT"] = L["Left"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Right"]
}

WeakAuras.grow_types = {
  ["LEFT"] = L["Left"],
  ["RIGHT"] = L["Right"],
  ["UP"] = L["Up"],
  ["DOWN"] = L["Down"],
  ["HORIZONTAL"] = L["Centered Horizontal"],
  ["VERTICAL"] = L["Centered Vertical"],
  ["CIRCLE"] = L["Counter Clockwise"],
  ["COUNTERCIRCLE"] = L["Clockwise"],
  ["GRID"] = L["Grid"],
  ["CUSTOM"] = L["Custom"],
}

-- horizontal types: R (right), L (left)
-- vertical types: U (up), D (down)
WeakAuras.grid_types = {
  RU = L["Right, then Up"],
  UR = L["Up, then Right"],
  LU = L["Left, then Up"],
  UL = L["Up, then Left"],
  RD = L["Right, then Down"],
  DR = L["Down, then Right"],
  LD = L["Left, then Down"],
  DL = L["Down, then Left"],
}

WeakAuras.text_rotate_types = {
  ["LEFT"] = L["Left"],
  ["NONE"] = L["None"],
  ["RIGHT"] = L["Right"]
}

WeakAuras.align_types = {
  ["LEFT"] = L["Left"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Right"]
}

WeakAuras.rotated_align_types = {
  ["LEFT"] = L["Top"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Bottom"]
}

WeakAuras.icon_side_types = {
  ["LEFT"] = L["Left"],
  ["RIGHT"] = L["Right"]
}

WeakAuras.rotated_icon_side_types = {
  ["LEFT"] = L["Top"],
  ["RIGHT"] = L["Bottom"]
}

WeakAuras.anim_types = {
  none = L["None"],
  preset = L["Preset"],
  custom = L["Custom"]
}

WeakAuras.anim_ease_types = {
  none = L["None"],
  easeIn = L["Ease In"],
  easeOut = L["Ease Out"],
  easeOutIn = L["Ease In and Out"]
}

WeakAuras.anim_ease_functions = {
  none = function(percent) return percent end,
  easeIn = function(percent, power)
    return percent ^ power;
  end,
  easeOut = function(percent, power)
    return 1.0 - (1.0 - percent) ^ power;
  end,
  easeOutIn = function(percent, power)
    if percent < .5 then
        return (percent * 2.0) ^ power * .5;
    end
    return 1.0 - ((1.0 - percent) * 2.0) ^ power * .5;
  end
}

WeakAuras.anim_translate_types = {
  straightTranslate = L["Normal"],
  circle = L["Circle"],
  spiral = L["Spiral"],
  spiralandpulse = L["Spiral In And Out"],
  shake = L["Shake"],
  bounce = L["Bounce"],
  bounceDecay = L["Bounce with Decay"],
  custom = L["Custom Function"]
}

WeakAuras.anim_scale_types = {
  straightScale = L["Normal"],
  pulse = L["Pulse"],
  fauxspin = L["Spin"],
  fauxflip = L["Flip"],
  custom = L["Custom Function"]
}

WeakAuras.anim_alpha_types = {
  straight = L["Normal"],
  alphaPulse = L["Pulse"],
  hide = L["Hide"],
  custom = L["Custom Function"]
}

WeakAuras.anim_rotate_types = {
  straight = L["Normal"],
  backandforth = L["Back and Forth"],
  wobble = L["Wobble"],
  custom = L["Custom Function"]
}

WeakAuras.anim_color_types = {
  straightColor = L["Legacy RGB Gradient"],
  straightHSV = L["Gradient"],
  pulseColor = L["Legacy RGB Gradient Pulse"],
  pulseHSV = L["Gradient Pulse"],
  custom = L["Custom Function"]
}

WeakAuras.instance_types = {
  none = L["No Instance"],
  scenario = L["Scenario"],
  party = L["5 Man Dungeon"],
  ten = L["10 Man Raid"],
  twenty = L["20 Man Raid"],
  twentyfive = L["25 Man Raid"],
  fortyman = L["40 Man Raid"],
  flexible = L["Flex Raid"],
  pvp = L["Battleground"],
  arena = L["Arena"]
}

WeakAuras.group_types = {
  solo = L["Not in Group"],
  group = L["In Group"],
  raid = L["In Raid"]
}

WeakAuras.difficulty_types = {
  none = L["None"],
  normal = PLAYER_DIFFICULTY1,
  heroic = PLAYER_DIFFICULTY2,
  mythic = PLAYER_DIFFICULTY6,
  timewalking = PLAYER_DIFFICULTY_TIMEWALKER,
  lfr = PLAYER_DIFFICULTY3,
  challenge = PLAYER_DIFFICULTY5
}

WeakAuras.role_types = {
  TANK = INLINE_TANK_ICON.." "..TANK,
  DAMAGER = INLINE_DAMAGER_ICON.." "..DAMAGER,
  HEALER = INLINE_HEALER_ICON.." "..HEALER
}

WeakAuras.classification_types = {
  worldboss = L["World Boss"],
  rareelite = L["Rare Elite"],
  elite = L["Elite"],
  rare = L["Rare"],
  normal = L["Normal"],
  trivial = L["Trivial (Low Level)"],
  minus = L["Minus (Small Nameplate)"]
}

WeakAuras.anim_start_preset_types = {
  slidetop = L["Slide from Top"],
  slideleft = L["Slide from Left"],
  slideright = L["Slide from Right"],
  slidebottom = L["Slide from Bottom"],
  fade = L["Fade In"],
  shrink = L["Grow"],
  grow = L["Shrink"],
  spiral = L["Spiral"],
  bounceDecay = L["Bounce"],
  starShakeDecay = L["Star Shake"],
}

WeakAuras.anim_main_preset_types = {
  shake = L["Shake"],
  spin = L["Spin"],
  flip = L["Flip"],
  wobble = L["Wobble"],
  pulse = L["Pulse"],
  alphaPulse = L["Flash"],
  rotateClockwise = L["Rotate Right"],
  rotateCounterClockwise = L["Rotate Left"],
  spiralandpulse = L["Spiral"],
  orbit = L["Orbit"],
  bounce = L["Bounce"]
}

WeakAuras.anim_finish_preset_types = {
  slidetop = L["Slide to Top"],
  slideleft = L["Slide to Left"],
  slideright = L["Slide to Right"],
  slidebottom = L["Slide to Bottom"],
  fade = L["Fade Out"],
  shrink = L["Shrink"],
  grow =L["Grow"],
  spiral = L["Spiral"],
  bounceDecay = L["Bounce"],
  starShakeDecay = L["Star Shake"],
};

WeakAuras.chat_message_types = {
  CHAT_MSG_INSTANCE_CHAT = L["Instance"],
  CHAT_MSG_BG_SYSTEM_NEUTRAL = L["BG-System Neutral"],
  CHAT_MSG_BG_SYSTEM_ALLIANCE = L["BG-System Alliance"],
  CHAT_MSG_BG_SYSTEM_HORDE = L["BG-System Horde"],
  CHAT_MSG_BN_WHISPER = L["Battle.net Whisper"],
  CHAT_MSG_CHANNEL = L["Channel"],
  CHAT_MSG_EMOTE = L["Emote"],
  CHAT_MSG_GUILD = L["Guild"],
  CHAT_MSG_MONSTER_YELL = L["Monster Yell"],
  CHAT_MSG_MONSTER_EMOTE = L["Monster Emote"],
  CHAT_MSG_MONSTER_SAY = L["Monster Say"],
  CHAT_MSG_MONSTER_WHISPER = L["Monster Whisper"],
  CHAT_MSG_MONSTER_PARTY = L["Monster Party"],
  CHAT_MSG_OFFICER = L["Officer"],
  CHAT_MSG_PARTY = L["Party"],
  CHAT_MSG_RAID = L["Raid"],
  CHAT_MSG_RAID_BOSS_EMOTE = L["Boss Emote"],
  CHAT_MSG_RAID_BOSS_WHISPER = L["Boss Whisper"],
  CHAT_MSG_RAID_WARNING = L["Raid Warning"],
  CHAT_MSG_SAY = L["Say"],
  CHAT_MSG_WHISPER = L["Whisper"],
  CHAT_MSG_YELL = L["Yell"],
  CHAT_MSG_SYSTEM = L["System"]
}

WeakAuras.send_chat_message_types = {
  WHISPER = L["Whisper"],
  SAY = L["Say"],
  EMOTE = L["Emote"],
  YELL = L["Yell"],
  PARTY = L["Party"],
  GUILD = L["Guild"],
  OFFICER = L["Officer"],
  RAID = L["Raid"],
  SMARTRAID = L["BG>Raid>Party>Say"],
  RAID_WARNING = L["Raid Warning"],
  INSTANCE_CHAT = L["Instance"],
  COMBAT = L["Blizzard Combat Text"],
  PRINT = L["Chat Frame"]
}

WeakAuras.group_aura_name_info_types = {
  aura = L["Aura Name"],
  players = L["Player(s) Affected"],
  nonplayers = L["Player(s) Not Affected"]
}

WeakAuras.group_aura_stack_info_types = {
  count = L["Number Affected"],
  stack = L["Aura Stack"]
}

WeakAuras.cast_types = {
  cast = L["Cast"],
  channel = L["Channel (Spell)"]
}

-- register sounds
LSM:Register("sound", "Batman Punch", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BatmanPunch.ogg")
LSM:Register("sound", "Bike Horn", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BikeHorn.ogg")
LSM:Register("sound", "Boxing Arena Gong", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BoxingArenaSound.ogg")
LSM:Register("sound", "Bleat", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Bleat.ogg")
LSM:Register("sound", "Cartoon Hop", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonHop.ogg")
LSM:Register("sound", "Cat Meow", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CatMeow2.ogg")
LSM:Register("sound", "Kitten Meow", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\KittenMeow.ogg")
LSM:Register("sound", "Robot Blip", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RobotBlip.ogg")
LSM:Register("sound", "Sharp Punch", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SharpPunch.ogg")
LSM:Register("sound", "Water Drop", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\WaterDrop.ogg")
LSM:Register("sound", "Air Horn", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\AirHorn.ogg")
LSM:Register("sound", "Applause", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Applause.ogg")
LSM:Register("sound", "Banana Peel Slip", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BananaPeelSlip.ogg")
LSM:Register("sound", "Blast", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Blast.ogg")
LSM:Register("sound", "Cartoon Voice Baritone", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonVoiceBaritone.ogg")
LSM:Register("sound", "Cartoon Walking", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonWalking.ogg")
LSM:Register("sound", "Cow Mooing", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CowMooing.ogg")
LSM:Register("sound", "Ringing Phone", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RingingPhone.ogg")
LSM:Register("sound", "Roaring Lion", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RoaringLion.ogg")
LSM:Register("sound", "Shotgun", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Shotgun.ogg")
LSM:Register("sound", "Squish Fart", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SquishFart.ogg")
LSM:Register("sound", "Temple Bell", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\TempleBellHuge.ogg")
LSM:Register("sound", "Torch", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Torch.ogg")
LSM:Register("sound", "Warning Siren", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\WarningSiren.ogg")
LSM:Register("sound", "Lich King Apocalypse", 554003) -- Sound\Creature\LichKing\IC_Lich King_Special01.ogg

LSM:Register("sound", "Voice: Adds", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Adds.ogg")
LSM:Register("sound", "Voice: Boss", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Boss.ogg")
LSM:Register("sound", "Voice: Circle", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Circle.ogg")
LSM:Register("sound", "Voice: Cross", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Cross.ogg")
LSM:Register("sound", "Voice: Diamond", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Diamond.ogg")
LSM:Register("sound", "Voice: Don't Release", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\DontRelease.ogg")
LSM:Register("sound", "Voice: Empowered", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Empowered.ogg")
LSM:Register("sound", "Voice: Focus", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Focus.ogg")
LSM:Register("sound", "Voice: Idiot", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Idiot.ogg")
LSM:Register("sound", "Voice: Left", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Left.ogg")
LSM:Register("sound", "Voice: Moon", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Moon.ogg")
LSM:Register("sound", "Voice: Next", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Next.ogg")
LSM:Register("sound", "Voice: Portal", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Portal.ogg")
LSM:Register("sound", "Voice: Protected", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Protected.ogg")
LSM:Register("sound", "Voice: Release", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Release.ogg")
LSM:Register("sound", "Voice: Right", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Right.ogg")
LSM:Register("sound", "Voice: Run Away", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RunAway.ogg")
LSM:Register("sound", "Voice: Skull", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Skull.ogg")
LSM:Register("sound", "Voice: Spread", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Spread.ogg")
LSM:Register("sound", "Voice: Square", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Square.ogg")
LSM:Register("sound", "Voice: Stack", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Stack.ogg")
LSM:Register("sound", "Voice: Star", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Star.ogg")
LSM:Register("sound", "Voice: Switch", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Switch.ogg")
LSM:Register("sound", "Voice: Taunt", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Taunt.ogg")
LSM:Register("sound", "Voice: Triangle", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Triangle.ogg")


if(WeakAuras.PowerAurasSoundPath ~= "") then
  LSM:Register("sound", "Aggro", WeakAuras.PowerAurasSoundPath.."aggro.ogg")
  LSM:Register("sound", "Arrow Swoosh", WeakAuras.PowerAurasSoundPath.."Arrow_swoosh.ogg")
  LSM:Register("sound", "Bam", WeakAuras.PowerAurasSoundPath.."bam.ogg")
  LSM:Register("sound", "Polar Bear", WeakAuras.PowerAurasSoundPath.."bear_polar.ogg")
  LSM:Register("sound", "Big Kiss", WeakAuras.PowerAurasSoundPath.."bigkiss.ogg")
  LSM:Register("sound", "Bite", WeakAuras.PowerAurasSoundPath.."BITE.ogg")
  LSM:Register("sound", "Burp", WeakAuras.PowerAurasSoundPath.."burp4.ogg")
  LSM:Register("sound", "Cat", WeakAuras.PowerAurasSoundPath.."cat2.ogg")
  LSM:Register("sound", "Chant Major 2nd", WeakAuras.PowerAurasSoundPath.."chant2.ogg")
  LSM:Register("sound", "Chant Minor 3rd", WeakAuras.PowerAurasSoundPath.."chant4.ogg")
  LSM:Register("sound", "Chimes", WeakAuras.PowerAurasSoundPath.."chimes.ogg")
  LSM:Register("sound", "Cookie Monster", WeakAuras.PowerAurasSoundPath.."cookie.ogg")
  LSM:Register("sound", "Electrical Spark", WeakAuras.PowerAurasSoundPath.."ESPARK1.ogg")
  LSM:Register("sound", "Fireball", WeakAuras.PowerAurasSoundPath.."Fireball.ogg")
  LSM:Register("sound", "Gasp", WeakAuras.PowerAurasSoundPath.."Gasp.ogg")
  LSM:Register("sound", "Heartbeat", WeakAuras.PowerAurasSoundPath.."heartbeat.ogg")
  LSM:Register("sound", "Hiccup", WeakAuras.PowerAurasSoundPath.."hic3.ogg")
  LSM:Register("sound", "Huh?", WeakAuras.PowerAurasSoundPath.."huh_1.ogg")
  LSM:Register("sound", "Hurricane", WeakAuras.PowerAurasSoundPath.."hurricane.ogg")
  LSM:Register("sound", "Hyena", WeakAuras.PowerAurasSoundPath.."hyena.ogg")
  LSM:Register("sound", "Kaching", WeakAuras.PowerAurasSoundPath.."kaching.ogg")
  LSM:Register("sound", "Moan", WeakAuras.PowerAurasSoundPath.."moan.ogg")
  LSM:Register("sound", "Panther", WeakAuras.PowerAurasSoundPath.."panther1.ogg")
  LSM:Register("sound", "Phone", WeakAuras.PowerAurasSoundPath.."phone.ogg")
  LSM:Register("sound", "Punch", WeakAuras.PowerAurasSoundPath.."PUNCH.ogg")
  LSM:Register("sound", "Rain", WeakAuras.PowerAurasSoundPath.."rainroof.ogg")
  LSM:Register("sound", "Rocket", WeakAuras.PowerAurasSoundPath.."rocket.ogg")
  LSM:Register("sound", "Ship's Whistle", WeakAuras.PowerAurasSoundPath.."shipswhistle.ogg")
  LSM:Register("sound", "Gunshot", WeakAuras.PowerAurasSoundPath.."shot.ogg")
  LSM:Register("sound", "Snake Attack", WeakAuras.PowerAurasSoundPath.."snakeatt.ogg")
  LSM:Register("sound", "Sneeze", WeakAuras.PowerAurasSoundPath.."sneeze.ogg")
  LSM:Register("sound", "Sonar", WeakAuras.PowerAurasSoundPath.."sonar.ogg")
  LSM:Register("sound", "Splash", WeakAuras.PowerAurasSoundPath.."splash.ogg")
  LSM:Register("sound", "Squeaky Toy", WeakAuras.PowerAurasSoundPath.."Squeakypig.ogg")
  LSM:Register("sound", "Sword Ring", WeakAuras.PowerAurasSoundPath.."swordecho.ogg")
  LSM:Register("sound", "Throwing Knife", WeakAuras.PowerAurasSoundPath.."throwknife.ogg")
  LSM:Register("sound", "Thunder", WeakAuras.PowerAurasSoundPath.."thunder.ogg")
  LSM:Register("sound", "Wicked Male Laugh", WeakAuras.PowerAurasSoundPath.."wickedmalelaugh1.ogg")
  LSM:Register("sound", "Wilhelm Scream", WeakAuras.PowerAurasSoundPath.."wilhelm.ogg")
  LSM:Register("sound", "Wicked Female Laugh", WeakAuras.PowerAurasSoundPath.."wlaugh.ogg")
  LSM:Register("sound", "Wolf Howl", WeakAuras.PowerAurasSoundPath.."wolf5.ogg")
  LSM:Register("sound", "Yeehaw", WeakAuras.PowerAurasSoundPath.."yeehaw.ogg")
end

WeakAuras.sound_types = {
  [" custom"] = " " .. L["Custom"],
  [" KitID"] = " " .. L["Sound by Kit ID"]
}

for name, path in next, LSM:HashTable("sound") do
  WeakAuras.sound_types[path] = name
end

LSM.RegisterCallback(WeakAuras, "LibSharedMedia_Registered", function(_, mediatype, key)
  if mediatype == "sound" then
    local path = LSM:Fetch(mediatype, key)
    if path then
      WeakAuras.sound_types[path] = key
    end
  end
end)

-- register options font
LSM:Register("font", "Fira Mono Medium", "Interface\\Addons\\WeakAuras\\Media\\Fonts\\FiraMono-Medium.ttf", LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)

-- register plain white border
LSM:Register("border", "Square Full White", [[Interface\AddOns\WeakAuras\Media\Textures\Square_FullWhite.tga]])

WeakAuras.duration_types = {
  seconds = L["Seconds"],
  relative = L["Relative"]
}

WeakAuras.duration_types_no_choice = {
  seconds = L["Seconds"]
}

WeakAuras.gtfo_types = {
  [1] = L["High Damage"],
  [2] = L["Low Damage"],
  [3] = L["Fail Alert"],
  [4] = L["Friendly Fire"]
}

WeakAuras.pet_behavior_types = {
  passive = PET_MODE_PASSIVE,
  defensive = PET_MODE_DEFENSIVE,
  assist = PET_MODE_ASSIST
}

if WeakAuras.IsClassic() then
  WeakAuras.pet_behavior_types.aggressive = PET_MODE_AGGRESSIVE
  WeakAuras.pet_behavior_types.assist = nil
end

if not WeakAuras.IsClassic() then
  WeakAuras.pet_spec_types = {
    [1] = select(2, GetSpecializationInfoByID(74)), -- Ferocity
    [2] = select(2, GetSpecializationInfoByID(81)), -- Tenacity
    [3] = select(2, GetSpecializationInfoByID(79)) -- Cunning
  }
else
  WeakAuras.pet_spec_types = {}
end

WeakAuras.cooldown_progress_behavior_types = {
  showOnCooldown = L["On Cooldown"],
  showOnReady = L["Not on Cooldown"],
  showAlways = L["Always"]
}

WeakAuras.cooldown_types = {
  auto = L["Auto"],
  charges = L["Charges"],
  cooldown = L["Cooldown"]
}

WeakAuras.bufftrigger_progress_behavior_types = {
  showOnActive = L["Buffed/Debuffed"],
  showOnMissing = L["Missing"],
  showAlways= L["Always"]
}

WeakAuras.bufftrigger_2_progress_behavior_types = {
  showOnActive = L["Aura(s) Found"],
  showOnMissing = L["Aura(s) Missing"],
  showAlways = L["Always"],
  showOnMatches = L["Match Count"]
}

WeakAuras.bufftrigger_2_preferred_match_types =
{
  showLowest = L["Least remaining time"],
  showHighest = L["Most remaining time"]
}

WeakAuras.bufftrigger_2_per_unit_mode = {
  affected = L["Affected"],
  unaffected = L["Unaffected"],
  all = L["All"]
}

WeakAuras.item_slot_types = {
  [1]  = HEADSLOT,
  [2]  = NECKSLOT,
  [3]  = SHOULDERSLOT,
  [5]  = CHESTSLOT,
  [6]  = WAISTSLOT,
  [7]  = LEGSSLOT,
  [8]  = FEETSLOT,
  [9]  = WRISTSLOT,
  [10] = HANDSSLOT,
  [11] = FINGER0SLOT_UNIQUE,
  [12] = FINGER1SLOT_UNIQUE,
  [13] = TRINKET0SLOT_UNIQUE,
  [14] = TRINKET1SLOT_UNIQUE,
  [15] = BACKSLOT,
  [16] = MAINHANDSLOT,
  [17] = SECONDARYHANDSLOT,
  [19] = TABARDSLOT
}

WeakAuras.charges_change_type = {
  GAINED = L["Gained"],
  LOST = L["Lost"],
  CHANGED = L["Changed"]
}

WeakAuras.charges_change_condition_type = {
  GAINED = L["Gained"],
  LOST = L["Lost"]
}

WeakAuras.combat_event_type = {
  PLAYER_REGEN_ENABLED = L["Leaving"],
  PLAYER_REGEN_DISABLED = L["Entering"]
}

WeakAuras.bool_types = {
  [0] = L["False"],
  [1] = L["True"]
}

WeakAuras.absorb_modes = {
  OVERLAY_FROM_START = L["Attach to Start"],
  OVERLAY_FROM_END = L["Attach to End"]
}

WeakAuras.mythic_plus_affixes = {}

local mythic_plus_ignorelist = {
  [1] = true,
  [15] = true
}

if not WeakAuras.IsClassic() then
  for i = 1, 255 do
    local r = not mythic_plus_ignorelist[i] and C_ChallengeMode.GetAffixInfo(i)
    if r then
      WeakAuras.mythic_plus_affixes[i] = r
    end
  end
end

WeakAuras.update_categories = {
  {
    name = "anchor",
    fields = {
      "xOffset",
      "yOffset",
      "selfPoint",
      "anchorPoint",
      "anchorFrameType",
      "anchorFrameFrame",
      "frameStrata",
      "height",
      "width",
      "fontSize",
      "scale",
    },
    default = false,
    label = L["Size & Position"],
  },
  {
    name = "userconfig",
    fields = {"config"},
    default = false,
    label = L["Custom Configuration"],
  },
  {
    name = "name",
    fields = {"id"},
    default = true,
    label = L["Aura Names"],
  },
  {
    name = "display",
    fields = {},
    default = true,
    label = L["Display"],
  },
  {
    name = "trigger",
    fields = {"triggers"},
    default = true,
    label = L["Trigger"],
  },
  {
    name = "conditions",
    fields = {"conditions"},
    default = true,
    label = L["Conditions"],
  },
  {
    name = "load",
    fields = {"load"},
    default = true,
    label = L["Load Conditions"],
  },
  {
    name = "action",
    fields = {"actions"},
    default = true,
    label = L["Actions"],
  },
  {
    name = "animation",
    fields = {"animation"},
    default = true,
    label = L["Animations"],
  },
  {
    name = "authoroptions",
    fields = {"authorOptions"},
    default = true,
    label = L["Author Options"]
  },
  {
    name = "arrangement",
    fields = {
      "grow",
      "space",
      "stagger",
      "sort",
      "hybridPosition",
      "radius",
      "align",
      "rotation",
      "constantFactor",
      "hybridSortMode",
    },
    default = true,
    label = L["Group Arrangement"],
  },
  {
    name = "oldchildren",
    fields = {},
    default = true,
    label = L["Remove Obsolete Auras"],
  },
  {
    name = "newchildren",
    fields = {},
    default = true,
    label = L["Add Missing Auras"],
  },
  {
    name = "metadata",
    fields = {
      "url",
      "desc",
      "version",
    },
    default = true,
    label = L["Meta Data"],
  },
}

-- fields that are handled as special cases when importing
-- mismatch of internal fields is not counted as a difference
WeakAuras.internal_fields = {
  uid = true,
  internalVersion = true,
  sortHybridTable = true,
}

-- fields that are not included in exported data
-- these represent information which is only meaningful inside the db,
-- or are represented in other ways in exported
WeakAuras.non_transmissable_fields = {
  controlledChildren = true,
  parent = true,
  authorMode = true,
  skipWagoUpdate = true,
  ignoreWagoUpdate = true,
  preferToUpdate = true,
}

WeakAuras.data_stub = {
  -- note: this is the minimal data stub which prevents false positives in WeakAuras.diff upon reimporting an aura.
  -- pending a refactor of other code which adds unnecessary fields, it is possible to shrink it
  triggers = {
    {
      trigger = {
        type = "aura2",
        names = {},
        event = "Health",
        subeventPrefix = "SPELL",
        subeventSuffix = "_CAST_START",
        spellIds = {},
        unit = "player",
        debuffType = "HELPFUL",
      },
      untrigger = {},
    },
  },
  load = {
    size = {
      multi = {},
    },
    spec = {
      multi = {},
    },
    class = {
      multi = {},
    },
  },
  actions = {
    init = {},
    start = {},
    finish = {},
  },
  animation = {
    start = {
      type = "none",
      duration_type = "seconds",
      easeType = "none",
      easeStrength = 3,
    },
    main = {
      type = "none",
      duration_type = "seconds",
      easeType = "none",
      easeStrength = 3,
    },
    finish = {
      type = "none",
      duration_type = "seconds",
      easeType = "none",
      easeStrength = 3,
    },
  },
  conditions = {},
  config = {},
  authorOptions = {},
}

WeakAuras.author_option_classes = {
  toggle = "simple",
  input = "simple",
  number = "simple",
  range = "simple",
  color = "simple",
  select = "simple",
  multiselect = "simple",
  description = "noninteractive",
  space = "noninteractive",
  header = "noninteractive",
  group = "group"
}

WeakAuras.author_option_types = {
  toggle = L["Toggle"],
  input = L["String"],
  number = L["Number"],
  range = L["Slider"],
  description = L["Description"],
  color = L["Color"],
  select = L["Dropdown Menu"],
  space = L["Space"],
  multiselect = L["Toggle List"],
  header = L["Separator"],
  group = WeakAuras.newFeatureString .. L["Option Group"],
}

WeakAuras.author_option_fields = {
  common = {
    type = true,
    name = true,
    useDesc = true,
    desc = true,
    key = true,
    width = true,
  },
  number = {
    min = 0,
    max = 1,
    step = .05,
    default = 0,
  },
  range = {
    min = 0,
    max = 1,
    step = .05,
    default = 0,
  },
  input = {
    default = "",
    useLength = false,
    length = 10,
    multiline = false,
  },
  toggle = {
    default = false,
  },
  description = {
    text = "",
    fontSize = "medium",
  },
  color = {
    default = {1, 1, 1, 1},
  },
  select = {
    values = {"val1"},
    default = 1,
  },
  space = {
    variableWidth = true,
    useHeight = false,
    height = 1,
  },
  multiselect = {
    default = {true},
    values = {"val1"},
  },
  header = {
    useName = false,
    text = "",
    noMerge = false
  },
  group = {
    groupType = "simple",
    useCollapse = true,
    collapse = false,
    limitType = "none",
    size = 10,
    nameSource = 0,
    hideReorder = true,
    entryNames = nil, -- handled as a special case in code
    subOptions = {},
  }
}

WeakAuras.array_entry_name_types = {
  [-1] = L["Fixed Names"],
  [0] = L["Entry Order"],
  -- the rest is auto-populated with indices which are valid entry name sources
}

WeakAuras.name_source_option_types = {
  -- option types which can be used to generate entry names on arrays
  input = true,
  number = true,
  range = true,
}

WeakAuras.group_limit_types = {
  none = L["Unlimited"],
  max = L["Limited"],
  fixed = L["Fixed Size"],
}

WeakAuras.group_option_types = {
  simple = L["Simple"],
  array = L["Array"],
}

WeakAuras.difficulty_info = {
  [1] = {
    size = "party",
    difficulty = "normal",
  },
  [2] = {
    size = "party",
    difficulty = "heroic",
  },
  [3] = {
    size = "ten",
    difficulty = "normal",
  },
  [4] = {
    size = "twentyfive",
    difficulty = "normal",
  },
  [5] = {
    size = "ten",
    difficulty = "heroic",
  },
  [6] = {
    size = "twentyfive",
    difficulty = "heroic",
  },
  [7] = {
    size = "twentyfive",
    difficulty = "lfr",
  },
  [8] = {
    size = "party",
    difficulty = "challenge",
  },
  [9] = {
    size = "fortyman",
    difficulty = "normal",
  },
  [11] = {
    size = "scenario",
    difficulty = "heroic",
  },
  [12] = {
    size = "scenario",
    difficulty = "normal",
  },
  -- 13 is unused
  [14] = {
    size = "flexible",
    difficulty = "normal",
  },
  [15] = {
    size = "flexible",
    difficulty = "heroic",
  },
  [16] = {
    size = "twenty",
    difficulty = "mythic",
  },
  [17] = {
    size = "flexible",
    difficulty = "lfr",
  },
  [23] = {
    size = "party",
    difficulty = "mythic",
  },
  [24] = {
    size = "party",
    difficulty = "timewalking",
  },
  [33] = {
    size = "flexible",
    difficulty = "timewalking",
  },
  [148] = {
    size = "twenty",
    difficulty = "normal",
  },
}

WeakAuras.glow_types = {
  ACShine = L["Autocast Shine"],
  Pixel = L["Pixel Glow"],
  buttonOverlay = L["Action Button Glow"],
}

WeakAuras.font_sizes = {
  small = L["Small"],
  medium = L["Medium"],
  large = L["Large"],
}

-- unitIds registerable with RegisterUnitEvent
WeakAuras.baseUnitId = {
  ["player"] = true,
  ["target"] = true,
  ["pet"] = true,
  ["focus"] = true,
  ["vehicle"] = true
}

WeakAuras.multiUnitId = {
  ["nameplate"] = true,
  ["boss"] = true,
  ["arena"] = true,
  ["group"] = true,
  ["party"] = true,
  ["raid"] = true,
}

WeakAuras.multiUnitUnits = {
  ["nameplate"] = {},
  ["boss"] = {},
  ["arena"] = {},
  ["group"] = {},
  ["party"] = {},
  ["raid"] = {}
}

WeakAuras.multiUnitUnits.group["player"] = true
WeakAuras.multiUnitUnits.party["player"] = true

for i = 1, 4 do
  WeakAuras.baseUnitId["party"..i] = true
  WeakAuras.baseUnitId["partypet"..i] = true
  WeakAuras.multiUnitUnits.group["party"..i] = true
  WeakAuras.multiUnitUnits.party["party"..i] = true
end

if not WeakAuras.IsClassic() then
  for i = 1, MAX_BOSS_FRAMES do
    WeakAuras.baseUnitId["arena"..i] = true
    WeakAuras.baseUnitId["boss"..i] = true
    WeakAuras.multiUnitUnits.arena["arena"..i] = true
    WeakAuras.multiUnitUnits.boss["boss"..i] = true
  end
end

for i = 1, 40 do
  WeakAuras.baseUnitId["raid"..i] = true
  WeakAuras.baseUnitId["raidpet"..i] = true
  WeakAuras.baseUnitId["nameplate"..i] = true
  WeakAuras.multiUnitUnits.nameplate["nameplate"..i] = true
  WeakAuras.multiUnitUnits.group["raid"..i] = true
  WeakAuras.multiUnitUnits.raid["raid"..i] = true
end

WeakAuras.dbm_types = {
  [1] = L["Add"],
  [2] = L["AOE"],
  [3] = L["Targeted"],
  [4] = L["Interrupt"],
  [5] = L["Role"],
  [6] = L["Phase"],
  [7] = L["Important"]
}

WeakAuras.weapon_enchant_types = {
  showOnActive = L["Enchant Found"],
  showOnMissing = L["Enchant Missing"],
  showAlways = L["Always"],
}

WeakAuras.EJIcons = {
  tank =      "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:7:25:7:25|t",
  dps =       "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:39:57:7:25|t",
  healer =    "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:71:89:7:25|t",
  mythic =    "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:103:121:7:25|t",
  deadly =    "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:135:153:7:25|t",
  important = "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:167:185:7:25|t",
  interrupt = "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:199:217:7:25|t",
  magic =     "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:231:249:7:25|t",
  curse =     "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:7:25:39:57|t",
  poison =    "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:39:57:39:57|t",
  disease =   "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:71:89:39:57|t",
  enrage =    "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:103:121:39:57|t",
}

WeakAuras.reset_swing_spells = {}
WeakAuras.reset_ranged_swing_spells = {
  [2480] = true, -- Shoot Bow
  [7919] = true, -- Shoot Crossbow
  [7918] = true, -- Shoot Gun
  [2764] = true, -- Throw
  [5019] = true, -- Shoot Wands
  [75] = true, -- Auto Shot
}

if WeakAuras.IsClassic() then
  WeakAuras.baseUnitId.focus = nil
  WeakAuras.baseUnitId.vehicle = nil
  WeakAuras.multiUnitId.boss = nil
  WeakAuras.multiUnitId.arena = nil
  wipe(WeakAuras.multiUnitUnits.boss)
  wipe(WeakAuras.multiUnitUnits.arena)
  WeakAuras.unit_types.focus = nil
  WeakAuras.unit_types_bufftrigger_2.focus = nil
  WeakAuras.unit_types_bufftrigger_2.boss = nil
  WeakAuras.unit_types_bufftrigger_2.arena = nil
  WeakAuras.actual_unit_types_with_specific.focus = nil
  WeakAuras.actual_unit_types_cast.boss = nil
  WeakAuras.actual_unit_types_cast.arena = nil
  WeakAuras.actual_unit_types_cast.focus = nil
  WeakAuras.actual_unit_types.focus = nil
  WeakAuras.unit_types_range_check.focus = nil
  WeakAuras.threat_unit_types.focus = nil
  WeakAuras.item_slot_types[0] = AMMOSLOT
  WeakAuras.item_slot_types[18] = RANGEDSLOT

  local reset_swing_spell_list = {
    1464, 8820, 11604, 11605, -- Slam
    78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286, -- Heroic Strike
    845, 7369, 11608, 11609, 20569, -- Cleave
    2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266, -- Raptor Strike
    6807, 6808, 6809, 8972, 9745, 9880, 9881, -- Maul
    20549, -- War Stomp
  }
  for i, spellid in ipairs(reset_swing_spell_list) do
    WeakAuras.reset_swing_spells[spellid] = true
  end

  WeakAuras.glow_types.ACShine = nil
end
