if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local LSM = LibStub("LibSharedMedia-3.0");

local wipe, tinsert = wipe, tinsert
local GetNumShapeshiftForms, GetShapeshiftFormInfo = GetNumShapeshiftForms, GetShapeshiftFormInfo
local GetNumSpecializationsForClassID, GetSpecializationInfoForClassID = GetNumSpecializationsForClassID, GetSpecializationInfoForClassID
local WrapTextInColorCode = WrapTextInColorCode
local MAX_NUM_TALENTS = MAX_NUM_TALENTS or 20

local function WA_GetClassColor(classFilename)
  local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classFilename]
  if color then
    return color.colorStr
  end

  return "ffffffff"
end

Private.glow_action_types = {
  show = L["Show"],
  hide = L["Hide"]
}

Private.glow_frame_types = {
  UNITFRAME = L["Unit Frame"],
  NAMEPLATE = L["Nameplate"],
  FRAMESELECTOR = L["Frame Selector"]
}

Private.circular_group_constant_factor_types = {
  RADIUS = L["Radius"],
  SPACING = L["Spacing"]
}

Private.frame_strata_types = {
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

Private.hostility_types = {
  hostile = L["Hostile"],
  friendly = L["Friendly"]
}

Private.character_types = {
  player = L["Player Character"],
  npc = L["Non-player Character"]
}


Private.group_sort_types = {
  ascending = L["Ascending"],
  descending = L["Descending"],
  hybrid = L["Hybrid"],
  none = L["None"],
  custom = L["Custom"]
}

Private.group_hybrid_position_types = {
  hybridFirst = L["Marked First"],
  hybridLast = L["Marked Last"]
}

Private.group_hybrid_sort_types = {
  ascending = L["Ascending"],
  descending = L["Descending"]
}

if WeakAuras.IsClassic() then
  Private.time_format_types = {
    [0] = L["WeakAuras Built-In (63:42 | 3:07 | 10 | 2.4)"],
    [1] = L["Blizzard (2h | 3m | 10s | 2.4)"],
  }
else
  Private.time_format_types = {
    [0] = L["WeakAuras Built-In (63:42 | 3:07 | 10 | 2.4)"],
    [1] = L["Old Blizzard (2h | 3m | 10s | 2.4)"],
    [2] = L["Modern Blizzard (1h 3m | 3m 7s | 10s | 2.4)"],
  }
end

Private.time_precision_types = {
  [1] = "12.3",
  [2] = "12.34",
  [3] = "12.345",
}

Private.precision_types = {
  [0] = "12",
  [1] = "12.3",
  [2] = "12.34",
  [3] = "12.345",
}

Private.big_number_types = {
  ["AbbreviateNumbers"] = L["AbbreviateNumbers (Blizzard)"],
  ["AbbreviateLargeNumbers"] = L["AbbreviateLargeNumbers (Blizzard)"]
}

Private.round_types = {
  floor = L["Floor"],
  ceil = L["Ceil"],
  round = L["Round"]
}

Private.unit_color_types = {
  none = L["None"],
  class = L["Class"]
}

Private.unit_realm_name_types = {
  never = L["Never"],
  star = L["* Suffix"],
  differentServer = L["Only if on a different realm"],
  always = L["Always include realm"]
}

local timeFormatter = {}
if WeakAuras.IsRetail() then
  Mixin(timeFormatter, SecondsFormatterMixin)
  timeFormatter:Init(0, SecondsFormatter.Abbreviation.OneLetter)

  -- The default time formatter adds a space between the value and the unit
  -- While there is a API to strip it, that API does not work on all locales, e.g. german
  -- Thus, copy the interval descriptions, strip the whitespace from them
  -- and hack the timeFormatter to use our interval descriptions
  local timeFormatIntervalDescriptionFixed = {}
  timeFormatIntervalDescriptionFixed = CopyTable(SecondsFormatter.IntervalDescription)
  for i, interval in ipairs(timeFormatIntervalDescriptionFixed) do
    interval.formatString = CopyTable(SecondsFormatter.IntervalDescription[i].formatString)
    for j, formatString in ipairs(interval.formatString) do
      interval.formatString[j] = formatString:gsub(" ", "")
    end
  end

  timeFormatter.GetIntervalDescription = function(self, interval)
    return timeFormatIntervalDescriptionFixed[interval]
  end

  timeFormatter.GetMaxInterval = function(self)
    return #timeFormatIntervalDescriptionFixed
  end
end

local simpleFormatters = {
  AbbreviateNumbers = function(value)
    if type(value) == "string" then value = tonumber(value) end
    return (type(value) == "number") and AbbreviateNumbers(value) or value
  end,
  AbbreviateLargeNumbers = function(value)
    if type(value) == "string" then value = tonumber(value) end
    return (type(value) == "number") and AbbreviateLargeNumbers(Round(value)) or value
  end,
  floor = function(value)
    if type(value) == "string" then value = tonumber(value) end
    return (type(value) == "number") and floor(value) or value
  end,
  ceil = function(value)
    if type(value) == "string" then value = tonumber(value) end
    return (type(value) == "number") and ceil(value) or value
  end,
  round = function(value)
    if type(value) == "string" then value = tonumber(value) end
    return (type(value) == "number") and Round(value) or value
  end,
  time = {
    [0] = function(value)
      if type(value) == "string" then value = tonumber(value) end
      if type(value) == "number" then
        if value > 60 then
          return string.format("%i:", math.floor(value / 60)) .. string.format("%02i", value % 60)
        else
          return string.format("%d", value)
        end
      end
    end,
    -- Old Blizzard
    [1] = function(value)
      local fmt, time = SecondsToTimeAbbrev(value)
      -- Remove the space between the value and unit
      return fmt:gsub(" ", ""):format(time)
    end,
    -- Modern Blizzard
    [2] = WeakAuras.IsRetail() and function(value)
      return timeFormatter:Format(value)
    end,
    -- Fixed built-in formatter
    [99] = function(value)
      if type(value) == "string" then value = tonumber(value) end
      if type(value) == "number" then
        value = ceil(value)
        if value > 60 then
          return string.format("%i:", math.floor(value / 60)) .. string.format("%02i", value % 60)
        else
          return string.format("%d", value)
        end
      end
    end,
  },
}

Private.format_types = {
  none = {
    display = L["None"],
    AddOptions = function() end,
    CreateFormatter = function() end
  },
  string = {
    display = L["String"],
    AddOptions = function(symbol, hidden, addOption, get)
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
        min = 1,
        softMax = 20,
        hidden = hidden,
        step = 1,
        disabled = function()
          return not get(symbol .. "_abbreviate")
        end
      })
    end,
    CreateFormatter = function(symbol, get)
      local abbreviate = get(symbol .. "_abbreviate", false)
      local abbreviateMax = get(symbol .. "_abbreviate_max", 8)
      if abbreviate then
        return function(input)
          return WeakAuras.WA_Utf8Sub(input, abbreviateMax)
        end
      end
      return nil
    end
  },
  timed = {
    display = L["Time Format"],
    AddOptions = function(symbol, hidden, addOption, get)
      addOption(symbol .. "_time_format", {
        type = "select",
        name = L["Format"],
        width = WeakAuras.doubleWidth,
        values = Private.time_format_types,
        hidden = hidden
      })

      addOption(symbol .. "_time_dynamic_threshold", {
        type = "range",
        min = 0,
        max = 60,
        step = 1,
        name = L["Increase Precision Below"],
        width = WeakAuras.normalWidth,
        hidden = hidden,
      })

      addOption(symbol .. "_time_precision", {
        type = "select",
        name = L["Precision"],
        width = WeakAuras.normalWidth,
        values = Private.time_precision_types,
        hidden = hidden,
        disabled = function() return get(symbol .. "_time_dynamic_threshold") == 0 end
      })

      addOption(symbol .. "_time_mod_rate", {
        type = "toggle",
        name = L["Blizzard Cooldown Reduction"],
        desc = L["Cooldown Reduction changes the duration of seconds instead of showing the real time seconds."],
        width = WeakAuras.normalWidth,
        hidden = hidden,
      })

      addOption(symbol .. "_time_legacy_floor", {
        type = "toggle",
        name = L["Use Legacy floor rounding"],
        desc = L["Enables (incorrect) round down of seconds, which was the previous default behavior."],
        width = WeakAuras.normalWidth,
        hidden = hidden,
        disabled = function() return get(symbol .. "_time_format", 0) ~= 0 end
      })
    end,
    CreateFormatter = function(symbol, get)
      local format = get(symbol .. "_time_format", 0)
      local threshold = get(symbol .. "_time_dynamic_threshold", 60)
      local precision = get(symbol .. "_time_precision", 1)
      local modRate = get(symbol .. "_time_mod_rate", true)
      local legacyRoundingMode = get(symbol .. "_time_legacy_floor", false)

      if format == 0 and not legacyRoundingMode then
        format = 99
      end
      if not simpleFormatters.time[format] then
        format = 99
      end
      local mainFormater = simpleFormatters.time[format]

      local formatter
      if threshold == 0 then
        formatter = function(value, state)
          if type(value) ~= 'number' or value == math.huge then
            return ""
          end
          if value <= 0 then
            return ""
          end

          if modRate then
            value = value / (state.modRate or 1.0)
          end

          return mainFormater(value)
        end
      else
        local formatString = "%." .. precision .. "f"
        formatter = function(value, state)
          if type(value) ~= 'number' or value == math.huge then
            return ""
          end
          if value <= 0 then
            return ""
          end
          if modRate then
            value = value / (state.modRate or 1.0)
          end
          if value < threshold then
            return string.format(formatString, value)
          else
            return mainFormater(value)
          end
        end
      end

      local triggerNum, sym = string.match(symbol, "(.+)%.(.+)")
      sym = sym or symbol
      if sym == "p" or sym == "t" then
        -- Special case %p and %t. Since due to how the formatting
        -- work previously, the time formatter only formats %p and %t
        -- if the progress type is timed!
        return function(value, state)
          if not state or state.progressType ~= "timed" then
            return value
          end
          return formatter(value, state)
        end
      else
        return formatter
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
        values = Private.big_number_types,
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
        values = Private.precision_types,
        hidden = hidden
      })
      addOption(symbol .. "_round_type", {
        type = "select",
        name = L["Round Mode"],
        width = WeakAuras.normalWidth,
        values = Private.round_types,
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
    AddOptions = function(symbol, hidden, addOption, get, withoutColor)
      if not withoutColor then
        addOption(symbol .. "_color", {
          type = "select",
          name = L["Color"],
          width = WeakAuras.normalWidth,
          values = Private.unit_color_types,
          hidden = hidden,
        })
      end
      addOption(symbol .. "_realm_name", {
        type = "select",
        name = L["Realm Name"],
        width = WeakAuras.normalWidth,
        values = Private.unit_realm_name_types,
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
        min = 1,
        max = 20,
        hidden = hidden,
        step = 1,
        disabled = function()
          return not get(symbol .. "_abbreviate")
        end
      })
    end,
    CreateFormatter = function(symbol, get, withoutColor)
      local color = not withoutColor and get(symbol .. "_color", true)
      local realm = get(symbol .. "_realm_name", "never")
      local abbreviate = get(symbol .. "_abbreviate", false)
      local abbreviateMax = get(symbol .. "_abbreviate_max", 8)

      local nameFunc
      local colorFunc
      local abbreviateFunc
      if color == "class" then
        colorFunc = function(unit, text)
          if unit and Private.UnitPlayerControlledFixed(unit) then
            local classFilename = select(2, UnitClass(unit))
            if classFilename then
              return WrapTextInColorCode(text, WA_GetClassColor(classFilename))
            end
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
    AddOptions = function(symbol, hidden, addOption, get, withoutColor)
      if not withoutColor then
        addOption(symbol .. "_color", {
          type = "select",
          name = L["Color"],
          width = WeakAuras.normalWidth,
          values = Private.unit_color_types,
          hidden = hidden,
        })
      end
      addOption(symbol .. "_realm_name", {
        type = "select",
        name = L["Realm Name"],
        width = WeakAuras.normalWidth,
        values = Private.unit_realm_name_types,
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
        min = 1,
        max = 20,
        hidden = hidden,
        disabled = function()
          return not get(symbol .. "_abbreviate")
        end
      })
    end,
    CreateFormatter = function(symbol, get, withoutColor)
      local color = not withoutColor and get(symbol .. "_color", true)
      local realm = get(symbol .. "_realm_name", "never")
      local abbreviate = get(symbol .. "_abbreviate", false)
      local abbreviateMax = get(symbol .. "_abbreviate_max", 8)

      local nameFunc
      local colorFunc
      local abbreviateFunc
      if color == "class" then
        colorFunc = function(class, text)
          if class then
            return WrapTextInColorCode(text, WA_GetClassColor(class))
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
        values = Private.precision_types,
        hidden = hidden
      })
      addOption(symbol .. "_round_type", {
        type = "select",
        name = L["Round Mode"],
        width = WeakAuras.normalWidth,
        values = Private.round_types,
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

Private.format_types_display = {}
for k, v in pairs(Private.format_types) do Private.format_types_display[k] = v.display end


Private.sound_channel_types = {
  Master = L["Master"],
  SFX = ENABLE_SOUNDFX,
  Ambience = ENABLE_AMBIENCE,
  Music = ENABLE_MUSIC,
  Dialog = ENABLE_DIALOG
}

Private.sound_condition_types = {
  Play = L["Play"],
  Loop = L["Loop"],
  Stop = L["Stop"]
}

Private.trigger_require_types = {
  any = L["Any Triggers"],
  all = L["All Triggers"],
  custom = L["Custom Function"]
}

Private.trigger_require_types_one = {
  any = L["Trigger 1"],
  custom = L["Custom Function"]
}

Private.trigger_modes = {
  ["first_active"] = -10,
}

Private.debuff_types = {
  HELPFUL = L["Buff"],
  HARMFUL = L["Debuff"],
  BOTH = L["Buff/Debuff"]
}

Private.tooltip_count = {
  [1] = L["First"],
  [2] = L["Second"],
  [3] = L["Third"]
}

Private.aura_types = {
  BUFF = L["Buff"],
  DEBUFF = L["Debuff"],
}


Private.debuff_class_types = {
  magic = L["Magic"],
  curse = L["Curse"],
  disease = L["Disease"],
  poison = L["Poison"],
  enrage = L["Enrage"],
  none = L["None"]
}

Private.unit_types = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  group = L["Group"],
  member = L["Specific Unit"],
  pet = L["Pet"],
  multi = L["Multi-target"]
}

Private.unit_types_bufftrigger_2 = {
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

Private.actual_unit_types_with_specific = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  pet = L["Pet"],
  member = L["Specific Unit"]
}

Private.actual_unit_types_cast = {
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

Private.actual_unit_types_cast_tooltip = L["• |cff00ff00Player|r, |cff00ff00Target|r, |cff00ff00Focus|r, and |cff00ff00Pet|r correspond directly to those individual unitIDs.\n• |cff00ff00Specific Unit|r lets you provide a specific valid unitID to watch.\n|cffff0000Note|r: The game will not fire events for all valid unitIDs, making some untrackable by this trigger.\n• |cffffff00Party|r, |cffffff00Raid|r, |cffffff00Boss|r, |cffffff00Arena|r, and |cffffff00Nameplate|r can match multiple corresponding unitIDs.\n• |cffffff00Smart Group|r adjusts to your current group type, matching just the \"player\" when solo, \"party\" units (including \"player\") in a party or \"raid\" units in a raid.\n\n|cffffff00*|r Yellow Unit settings will create clones for each matching unit while this trigger is providing Dynamic Info to the Aura."]

Private.threat_unit_types = {
  target = L["Target"],
  focus = L["Focus"],
  nameplate = L["Nameplate"],
  boss = L["Boss"],
  member = L["Specific Unit"],
  none = L["At Least One Enemy"]
}

Private.unit_types_range_check = {
  target = L["Target"],
  focus = L["Focus"],
  pet = L["Pet"],
  member = L["Specific Unit"]
}

Private.unit_threat_situation_types = {
  [-1] = L["Not On Threat Table"],
  [0] = "|cFFB0B0B0"..L["Lower Than Tank"].."|r",
  [1] = "|cFFFFFF77"..L["Higher Than Tank"].."|r",
  [2] = "|cFFFF9900"..L["Tanking But Not Highest"].."|r",
  [3] = "|cFFFF0000"..L["Tanking And Highest"].."|r"
}

WeakAuras.class_types = {}
for classID = 1, 20 do -- 20 is for GetNumClasses() but that function doesn't exists on Classic
  local classInfo = C_CreatureInfo.GetClassInfo(classID)
  if classInfo and classID ~=14 then -- 14 == Adventurer
    WeakAuras.class_types[classInfo.classFile] = WrapTextInColorCode(classInfo.className, WA_GetClassColor(classInfo.classFile))
  end
end


WeakAuras.race_types = {}
do
  local races = {
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [8] = true,
    [9] = not WeakAuras.IsClassicOrBCCOrWrath() and true or nil, -- Goblin
    [10] = true,
    [11] = true,
    [22] = true,
    [24] = true,
    [25] = true,
    [26] = true,
    [27] = true,
    [28] = true,
    [29] = true,
    [30] = true,
    [31] = true,
    [32] = true,
    [34] = true,
    [35] = true,
    [36] = true,
    [37] = true,
    [52] = true, -- Dracthyr
    [70] = true, -- Dracthyr
  }

  for raceId, enabled in pairs(races) do
    local raceInfo = C_CreatureInfo.GetRaceInfo(raceId)
    if raceInfo then
      WeakAuras.race_types[raceInfo.clientFileString] = raceInfo.raceName
    end
  end
end

if WeakAuras.IsRetail() then
  Private.covenant_types = {}
  Private.covenant_types[0] = L["None"]
  for i = 1, 4 do
    Private.covenant_types[i] = C_Covenants.GetCovenantData(i).name
  end
end

Private.faction_group = {
  Alliance = L["Alliance"],
  Horde = L["Horde"],
  Neutral = L["Neutral"]
}

Private.form_types = {};
local function update_forms()
  wipe(Private.form_types);
  Private.form_types[0] = "0 - "..L["Humanoid"]
  for i = 1, GetNumShapeshiftForms() do
    local _, _, _, id = GetShapeshiftFormInfo(i);
    if(id) then
      local name = GetSpellInfo(id);
      if(name) then
        Private.form_types[i] = i.." - "..name
      end
    end
  end
end
local form_frame = CreateFrame("Frame");
form_frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
form_frame:RegisterEvent("PLAYER_LOGIN")
form_frame:SetScript("OnEvent", update_forms);

Private.blend_types = {
  ADD = L["Glow"],
  BLEND = L["Opaque"]
}

Private.texture_wrap_types = {
  CLAMP = L["Clamp"],
  MIRROR = L["Mirror"],
  REPEAT = L["Repeat"],
  CLAMPTOBLACKADDITIVE = L["No Extend"]
}

Private.slant_mode = {
  INSIDE = L["Keep Inside"],
  EXTEND = L["Extend Outside"]
}

Private.text_check_types = {
  update = L["Every Frame"],
  event = L["Trigger Update"]
}

Private.check_types = {
  update = L["Every Frame (High CPU usage)"],
  event = L["Event(s)"]
}

Private.point_types = {
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

Private.default_types_for_anchor = {}
for k, v in pairs(Private.point_types) do
  Private.default_types_for_anchor[k] = {
    display = v,
    type = "point"
  }
end

Private.default_types_for_anchor["ALL"] = {
  display = L["Whole Area"],
  type = "area"
}

Private.aurabar_anchor_areas = {
  icon = L["Icon"],
  fg = L["Foreground"],
  bg = L["Background"],
  bar = L["Full Bar"],
}

Private.inverse_point_types = {
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

Private.anchor_frame_types = {
  SCREEN = L["Screen/Parent Group"],
  PRD = L["Personal Resource Display"],
  MOUSE = L["Mouse Cursor"],
  SELECTFRAME = L["Select Frame"],
  NAMEPLATE = L["Nameplates"],
  UNITFRAME = L["Unit Frames"],
  CUSTOM = L["Custom"]
}

Private.anchor_frame_types_group = {
  SCREEN = L["Screen/Parent Group"],
  PRD = L["Personal Resource Display"],
  MOUSE = L["Mouse Cursor"],
  SELECTFRAME = L["Select Frame"],
  CUSTOM = L["Custom"]
}

Private.spark_rotation_types = {
  AUTO = L["Automatic Rotation"],
  MANUAL = L["Manual Rotation"]
}

Private.spark_hide_types = {
  NEVER = L["Never"],
  FULL  = L["Full"],
  EMPTY = L["Empty"],
  BOTH  = L["Full/Empty"]
}

Private.tick_placement_modes = {
  AtValue = L["At Value"],
  AtMissingValue = L["At missing Value"],
  AtPercent = L["At Percent"],
  ValueOffset = L["Offset from progress"]
}

Private.font_flags = {
  None = L["None"],
  MONOCHROME = L["Monochrome"],
  OUTLINE = L["Outline"],
  THICKOUTLINE  = L["Thick Outline"],
  ["MONOCHROME|OUTLINE"] = L["Monochrome Outline"],
  ["MONOCHROME|THICKOUTLINE"] = L["Monochrome Thick Outline"]
}

Private.text_automatic_width = {
  Auto = L["Automatic"],
  Fixed = L["Fixed"]
}

Private.text_word_wrap = {
  WordWrap = L["Wrap"],
  Elide = L["Elide"]
}

Private.include_pets_types = {
  PlayersAndPets = L["Players and Pets"],
  PetsOnly = L["Pets only"]
}

Private.subevent_prefix_types = {
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

Private.subevent_actual_prefix_types = {
  SWING = L["Swing"],
  RANGE = L["Range"],
  SPELL = L["Spell"],
  SPELL_PERIODIC = L["Periodic Spell"],
  SPELL_BUILDING = L["Spell (Building)"],
  ENVIRONMENTAL = L["Environmental"]
}

Private.subevent_suffix_types = {
  _ABSORBED = L["Absorbed"],
  _DAMAGE = L["Damage"],
  _MISSED = L["Missed"],
  _HEAL = L["Heal"],
  _HEAL_ABSORBED = L["Heal Absorbed"],
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
  _EMPOWER_START = L["Empower Cast Start"],
  _EMPOWER_END = L["Empower Cast End"],
  _EMPOWER_INTERRUPT = L["Empower Cast Interrupt"],
  _INSTAKILL = L["Instakill"],
  _DURABILITY_DAMAGE = L["Durability Damage"],
  _DURABILITY_DAMAGE_ALL = L["Durability Damage All"],
  _CREATE = L["Create"],
  _SUMMON = L["Summon"],
  _RESURRECT = L["Resurrect"]
}

Private.power_types = {
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
if WeakAuras.IsRetail() then
  Private.power_types[99] = STAGGER
  Private.power_types[19] = POWER_TYPE_ESSENCE
end

Private.miss_types = {
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

Private.environmental_types = {
  Drowning = STRING_ENVIRONMENTAL_DAMAGE_DROWNING,
  Falling = STRING_ENVIRONMENTAL_DAMAGE_FALLING,
  Fatigue = STRING_ENVIRONMENTAL_DAMAGE_FATIGUE,
  Fire = STRING_ENVIRONMENTAL_DAMAGE_FIRE,
  Lava = STRING_ENVIRONMENTAL_DAMAGE_LAVA,
  Slime = STRING_ENVIRONMENTAL_DAMAGE_SLIME
}

Private.combatlog_flags_check_type = {
  Mine = L["Mine"],
  InGroup = L["In Group"],
  InParty = L["In Party"],
  NotInGroup = L["Not in Smart Group"]
}

Private.combatlog_flags_check_reaction = {
  Hostile = L["Hostile"],
  Neutral = L["Neutral"],
  Friendly = L["Friendly"]
}

Private.combatlog_flags_check_object_type = {
  Object = L["Object"],
  Guardian = L["Guardian"],
  Pet = L["Pet"],
  NPC = L["NPC"],
  Player = L["Player"]
}

Private.combatlog_spell_school_types = {
  [1] = STRING_SCHOOL_PHYSICAL,
  [2] = STRING_SCHOOL_HOLY,
  [4] = STRING_SCHOOL_FIRE,
  [8] = STRING_SCHOOL_NATURE,
  [16] = STRING_SCHOOL_FROST,
  [32] = STRING_SCHOOL_SHADOW,
  [64] = STRING_SCHOOL_ARCANE,
  [3] = STRING_SCHOOL_HOLYSTRIKE,
  [5] = STRING_SCHOOL_FLAMESTRIKE,
  [6] = STRING_SCHOOL_HOLYFIRE,
  [9] = STRING_SCHOOL_STORMSTRIKE,
  [10] = STRING_SCHOOL_HOLYSTORM,
  [12] = STRING_SCHOOL_FIRESTORM,
  [17] = STRING_SCHOOL_FROSTSTRIKE,
  [18] = STRING_SCHOOL_HOLYFROST,
  [20] = STRING_SCHOOL_FROSTFIRE,
  [24] = STRING_SCHOOL_FROSTSTORM,
  [33] = STRING_SCHOOL_SHADOWSTRIKE,
  [34] = STRING_SCHOOL_SHADOWLIGHT,
  [36] = STRING_SCHOOL_SHADOWFLAME,
  [40] = STRING_SCHOOL_SHADOWSTORM,
  [48] = STRING_SCHOOL_SHADOWFROST,
  [65] = STRING_SCHOOL_SPELLSTRIKE,
  [66] = STRING_SCHOOL_DIVINE,
  [68] = STRING_SCHOOL_SPELLFIRE,
  [72] = STRING_SCHOOL_SPELLSTORM,
  [80] = STRING_SCHOOL_SPELLFROST,
  [96] = STRING_SCHOOL_SPELLSHADOW,
  [28] = STRING_SCHOOL_ELEMENTAL,
  [62] = STRING_SCHOOL_CHROMATIC,
  [106] = STRING_SCHOOL_COSMIC,
  [124] = STRING_SCHOOL_CHAOS,
  [126] = STRING_SCHOOL_MAGIC,
  [127] = STRING_SCHOOL_CHAOS,
}

Private.combatlog_spell_school_types_for_ui = {}
for id, str in pairs(Private.combatlog_spell_school_types) do
  Private.combatlog_spell_school_types_for_ui[id] = ("%.3d - %s"):format(id, str)
end

Private.combatlog_raid_mark_check_type = {
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

Private.combatlog_raidFlags = {
  [0] = 0,
  [1] = 1,
  [2] = 2,
  [4] = 3,
  [8] = 4,
  [16] = 5,
  [32] = 6,
  [64] = 7,
  [128] = 8,
}

Private.raid_mark_check_type = CopyTable(Private.combatlog_raid_mark_check_type)
Private.raid_mark_check_type[9] = nil

Private.orientation_types = {
  HORIZONTAL_INVERSE = L["Left to Right"],
  HORIZONTAL = L["Right to Left"],
  VERTICAL = L["Bottom to Top"],
  VERTICAL_INVERSE = L["Top to Bottom"]
}

Private.orientation_with_circle_types = {
  HORIZONTAL_INVERSE = L["Left to Right"],
  HORIZONTAL = L["Right to Left"],
  VERTICAL = L["Bottom to Top"],
  VERTICAL_INVERSE = L["Top to Bottom"],
  CLOCKWISE = L["Clockwise"],
  ANTICLOCKWISE = L["Anticlockwise"]
}

Private.spec_types = {
  [1] = SPECIALIZATION.." 1",
  [2] = SPECIALIZATION.." 2",
  [3] = SPECIALIZATION.." 3",
  [4] = SPECIALIZATION.." 4"
}

Private.spec_types_3 = {
  [1] = SPECIALIZATION.." 1",
  [2] = SPECIALIZATION.." 2",
  [3] = SPECIALIZATION.." 3"
}

Private.spec_types_2 = {
  [1] = SPECIALIZATION.." 1",
  [2] = SPECIALIZATION.." 2"
}

WeakAuras.spec_types_specific = {}
Private.spec_types_all = {}
local function update_specs()
  for classFileName, classID in pairs(WeakAuras.class_ids) do
    WeakAuras.spec_types_specific[classFileName] = {}
    local numSpecs = GetNumSpecializationsForClassID(classID)
    for i=1, numSpecs do
      local specId, tabName, _, icon = GetSpecializationInfoForClassID(classID, i);
      if tabName then
        tinsert(WeakAuras.spec_types_specific[classFileName], "|T"..(icon or "error")..":0|t "..(tabName or "error"));
        if WeakAuras.IsRetail() then
          Private.spec_types_all[specId] = CreateAtlasMarkup(GetClassAtlas(classFileName:lower()))
          .. "|T"..(icon or "error")..":0|t "..(tabName or "error");
        end
      end
    end
  end
end


Private.talent_types = {}
if WeakAuras.IsRetail() then
  local spec_frame = CreateFrame("Frame");
  spec_frame:RegisterEvent("PLAYER_LOGIN")
  spec_frame:SetScript("OnEvent", update_specs);
else
  for tab = 1, GetNumTalentTabs() do
    for num_talent = 1, GetNumTalents(tab) do
      local talentId = (tab - 1) * MAX_NUM_TALENTS + num_talent
      Private.talent_types[talentId] = L["Tab "]..tab.." - "..num_talent
    end
  end
end

Private.pvp_talent_types = {}
if WeakAuras.IsRetail() then
  for i = 1,10 do
    tinsert(Private.pvp_talent_types, string.format(L["PvP Talent %i"], i));
  end
end

Private.talent_extra_option_types = {
    [0] = L["Talent Known"],
    [1] = L["Talent Selected"],
    [2] = L["Talent |cFFFF0000Not|r Known"],
    [3] = L["Talent |cFFFF0000Not|r Selected"],
}

-- GetTotemInfo() only works for the first 5 totems
Private.totem_types = {};
local totemString = L["Totem #%i"];
for i = 1, 5 do
  Private.totem_types[i] = totemString:format(i);
end

Private.loss_of_control_types = {
  NONE = "NONE",
  CHARM = "CHARM",
  CONFUSE = "CONFUSE",
  DISARM = "DISARM",
  FEAR = "FEAR",
  FEAR_MECHANIC = "FEAR_MECHANIC",
  PACIFY = "PACIFY",
  SILENCE = "SILENCE",
  PACIFYSILENCE = "PACIFYSILENCE",
  POSSESS = "POSSESS",
  ROOT = "ROOT",
  SCHOOL_INTERRUPT = "SCHOOL_INTERRUPT",
  STUN = "STUN",
  STUN_MECHANIC = "STUN_MECHANIC",
}

Private.main_spell_schools = {
  [1] = GetSchoolString(1),
  [2] = GetSchoolString(2),
  [4] = GetSchoolString(4),
  [8] = GetSchoolString(8),
  [16] = GetSchoolString(16),
  [32] = GetSchoolString(32),
  [64] = GetSchoolString(64),
}

Private.texture_types = {
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
    ["2851787"] = "Demonic Core",
    ["2888300"] = "Demonic Core Vertical",
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
    ["2851788"] = "High Tide",
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

    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\square_border_1px.tga"] = "Square Border 1px",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\square_border_5px.tga"] = "Square Border 5px",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\square_border_10px.tga"] = "Square Border 10px",
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
  },
  ["WeakAuras"] = {
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\logo_64.tga"] = "WeakAuras logo 64px",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\logo_256.tga"] = "WeakAuras logo 256px"
  }
}
local BuildInfo = select(4, GetBuildInfo())
if BuildInfo <= 80100 then -- 8.1.5
  Private.texture_types.Sparks["worldstate-capturebar-spark-green"] = "Capture Bar Green Spark"
  Private.texture_types.Sparks["worldstate-capturebar-spark-yellow"] = "Capture Bar Yellow Spark"
end
if WeakAuras.IsClassic() then -- Classic
  Private.texture_types["Blizzard Alerts"] = nil
  do
    local beams = Private.texture_types["Beams"]
    local beams_ids = {167096, 167097, 167098, 167099, 167100, 167101, 167102, 167103, 167104, 167105, 186192, 186193, 186194, 241098, 241099, 369749, 369750}
    for _, v in ipairs(beams_ids) do
      beams[tostring(v)] = nil
    end
  end
  do
    local icons = Private.texture_types["Icons"]
    local icons_ids = {165605, 166036, 166680, 166948, 166989, 240925, 240961, 240972, 241049}
    for _, v in ipairs(icons_ids) do
      icons[tostring(v)] = nil
    end
  end
  do
    local runes = Private.texture_types["Runes"]
    local runes_ids = {165633, 165885, 165922, 166340, 166753, 166754, 241003, 241004, 241005}
    for _, v in ipairs(runes_ids) do
      runes[tostring(v)] = nil
    end
  end
elseif WeakAuras.IsBCCOrWrath() then
  Private.texture_types["Blizzard Alerts"] = nil
  do
    local beams = Private.texture_types["Beams"]
    local beams_ids = {186193, 186194, 241098, 241099, 369749, 369750}
    for _, v in ipairs(beams_ids) do
      beams[tostring(v)] = nil
    end
  end
  do
    local icons = Private.texture_types["Icons"]
    local icons_ids = {165605, 240925, 240961, 240972, 241049}
    for _, v in ipairs(icons_ids) do
      icons[tostring(v)] = nil
    end
  end
  do
    local runes = Private.texture_types["Runes"]
    local runes_ids = {165922, 241003, 241004, 241005}
    for _, v in ipairs(runes_ids) do
      runes[tostring(v)] = nil
    end
  end
end

local PowerAurasPath = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\"
Private.texture_types["PowerAuras Heads-Up"] = {
  [PowerAurasPath.."Aura1"] = "Runed Text",
  [PowerAurasPath.."Aura2"] = "Runed Text On Ring",
  [PowerAurasPath.."Aura3"] = "Power Waves",
  [PowerAurasPath.."Aura4"] = "Majesty",
  [PowerAurasPath.."Aura5"] = "Runed Ends",
  [PowerAurasPath.."Aura6"] = "Extra Majesty",
  [PowerAurasPath.."Aura7"] = "Triangular Highlights",
  [PowerAurasPath.."Aura11"] = "Oblong Highlights",
  [PowerAurasPath.."Aura16"] = "Thin Crescents",
  [PowerAurasPath.."Aura17"] = "Crescent Highlights",
  [PowerAurasPath.."Aura18"] = "Dense Runed Text",
  [PowerAurasPath.."Aura23"] = "Runed Spiked Ring",
  [PowerAurasPath.."Aura24"] = "Smoke",
  [PowerAurasPath.."Aura28"] = "Flourished Text",
  [PowerAurasPath.."Aura33"] = "Droplet Highlights"
}
Private.texture_types["PowerAuras Icons"] = {
  [PowerAurasPath.."Aura8"] = "Rune",
  [PowerAurasPath.."Aura9"] = "Stylized Ghost",
  [PowerAurasPath.."Aura10"] = "Skull and Crossbones",
  [PowerAurasPath.."Aura12"] = "Snowflake",
  [PowerAurasPath.."Aura13"] = "Flame",
  [PowerAurasPath.."Aura14"] = "Holy Rune",
  [PowerAurasPath.."Aura15"] = "Zig-Zag Exclamation Point",
  [PowerAurasPath.."Aura19"] = "Crossed Swords",
  [PowerAurasPath.."Aura21"] = "Shield",
  [PowerAurasPath.."Aura22"] = "Glow",
  [PowerAurasPath.."Aura25"] = "Cross",
  [PowerAurasPath.."Aura26"] = "Droplet",
  [PowerAurasPath.."Aura27"] = "Alert",
  [PowerAurasPath.."Aura29"] = "Paw",
  [PowerAurasPath.."Aura30"] = "Bull",
  --   [PowerAurasPath.."Aura31"] = "Hieroglyphics Horizontal",
  [PowerAurasPath.."Aura32"] = "Hieroglyphics",
  [PowerAurasPath.."Aura34"] = "Circled Arrow",
  [PowerAurasPath.."Aura35"] = "Short Sword",
  --   [PowerAurasPath.."Aura36"] = "Short Sword Horizontal",
  [PowerAurasPath.."Aura45"] = "Circular Glow",
  [PowerAurasPath.."Aura48"] = "Totem",
  [PowerAurasPath.."Aura49"] = "Dragon Blade",
  [PowerAurasPath.."Aura50"] = "Ornate Design",
  [PowerAurasPath.."Aura51"] = "Inverted Holy Rune",
  [PowerAurasPath.."Aura52"] = "Stylized Skull",
  [PowerAurasPath.."Aura53"] = "Exclamation Point",
  [PowerAurasPath.."Aura54"] = "Nonagon",
  [PowerAurasPath.."Aura68"] = "Wings",
  [PowerAurasPath.."Aura69"] = "Rectangle",
  [PowerAurasPath.."Aura70"] = "Low Mana",
  [PowerAurasPath.."Aura71"] = "Ghostly Eye",
  [PowerAurasPath.."Aura72"] = "Circle",
  [PowerAurasPath.."Aura73"] = "Ring",
  [PowerAurasPath.."Aura74"] = "Square",
  [PowerAurasPath.."Aura75"] = "Square Brackets",
  [PowerAurasPath.."Aura76"] = "Bob-omb",
  [PowerAurasPath.."Aura77"] = "Goldfish",
  [PowerAurasPath.."Aura78"] = "Check",
  [PowerAurasPath.."Aura79"] = "Ghostly Face",
  [PowerAurasPath.."Aura84"] = "Overlapping Boxes",
  --   [PowerAurasPath.."Aura85"] = "Overlapping Boxes 45°",
  --   [PowerAurasPath.."Aura86"] = "Overlapping Boxes 270°",
  [PowerAurasPath.."Aura87"] = "Fairy",
  [PowerAurasPath.."Aura88"] = "Comet",
  [PowerAurasPath.."Aura95"] = "Dual Spiral",
  [PowerAurasPath.."Aura96"] = "Japanese Character",
  [PowerAurasPath.."Aura97"] = "Japanese Character",
  [PowerAurasPath.."Aura98"] = "Japanese Character",
  [PowerAurasPath.."Aura99"] = "Japanese Character",
  [PowerAurasPath.."Aura100"] = "Japanese Character",
  [PowerAurasPath.."Aura101"] = "Ball of Flame",
  [PowerAurasPath.."Aura102"] = "Zig-Zag",
  [PowerAurasPath.."Aura103"] = "Thorny Ring",
  [PowerAurasPath.."Aura110"] = "Hunter's Mark",
  --   [PowerAurasPath.."Aura111"] = "Hunter's Mark Horizontal",
  [PowerAurasPath.."Aura112"] = "Kaleidoscope",
  [PowerAurasPath.."Aura113"] = "Jesus Face",
  [PowerAurasPath.."Aura114"] = "Green Mushroom",
  [PowerAurasPath.."Aura115"] = "Red Mushroom",
  [PowerAurasPath.."Aura116"] = "Fire Flower",
  [PowerAurasPath.."Aura117"] = "Radioactive",
  [PowerAurasPath.."Aura118"] = "X",
  [PowerAurasPath.."Aura119"] = "Flower",
  [PowerAurasPath.."Aura120"] = "Petal",
  [PowerAurasPath.."Aura130"] = "Shoop Da Woop",
  [PowerAurasPath.."Aura131"] = "8-Bit Symbol",
  [PowerAurasPath.."Aura132"] = "Cartoon Skull",
  [PowerAurasPath.."Aura138"] = "Stop",
  [PowerAurasPath.."Aura139"] = "Thumbs Up",
  [PowerAurasPath.."Aura140"] = "Palette",
  [PowerAurasPath.."Aura141"] = "Blue Ring",
  [PowerAurasPath.."Aura142"] = "Ornate Ring",
  [PowerAurasPath.."Aura143"] = "Ghostly Skull"
}
Private.texture_types["PowerAuras Separated"] = {
  [PowerAurasPath.."Aura46"] = "8-Part Ring 1",
  [PowerAurasPath.."Aura47"] = "8-Part Ring 2",
  [PowerAurasPath.."Aura55"] = "Skull on Gear 1",
  [PowerAurasPath.."Aura56"] = "Skull on Gear 2",
  [PowerAurasPath.."Aura57"] = "Skull on Gear 3",
  [PowerAurasPath.."Aura58"] = "Skull on Gear 4",
  [PowerAurasPath.."Aura59"] = "Rune Ring Full",
  [PowerAurasPath.."Aura60"] = "Rune Ring Empty",
  [PowerAurasPath.."Aura61"] = "Rune Ring Left",
  [PowerAurasPath.."Aura62"] = "Rune Ring Right",
  [PowerAurasPath.."Aura63"] = "Spiked Rune Ring Full",
  [PowerAurasPath.."Aura64"] = "Spiked Rune Ring Empty",
  [PowerAurasPath.."Aura65"] = "Spiked Rune Ring Left",
  [PowerAurasPath.."Aura66"] = "Spiked Rune Ring Bottom",
  [PowerAurasPath.."Aura67"] = "Spiked Rune Ring Right",
  [PowerAurasPath.."Aura80"] = "Spiked Helm Background",
  [PowerAurasPath.."Aura81"] = "Spiked Helm Full",
  [PowerAurasPath.."Aura82"] = "Spiked Helm Bottom",
  [PowerAurasPath.."Aura83"] = "Spiked Helm Top",
  [PowerAurasPath.."Aura89"] = "5-Part Ring 1",
  [PowerAurasPath.."Aura90"] = "5-Part Ring 2",
  [PowerAurasPath.."Aura91"] = "5-Part Ring 3",
  [PowerAurasPath.."Aura92"] = "5-Part Ring 4",
  [PowerAurasPath.."Aura93"] = "5-Part Ring 5",
  [PowerAurasPath.."Aura94"] = "5-Part Ring Full",
  [PowerAurasPath.."Aura104"] = "Shield Center",
  [PowerAurasPath.."Aura105"] = "Shield Full",
  [PowerAurasPath.."Aura106"] = "Shield Top Right",
  [PowerAurasPath.."Aura107"] = "Shield Top Left",
  [PowerAurasPath.."Aura108"] = "Shield Bottom Right",
  [PowerAurasPath.."Aura109"] = "Shield Bottom Left",
  [PowerAurasPath.."Aura121"] = "Vine Top Right Leaf",
  [PowerAurasPath.."Aura122"] = "Vine Left Leaf",
  [PowerAurasPath.."Aura123"] = "Vine Bottom Right Leaf",
  [PowerAurasPath.."Aura124"] = "Vine Stem",
  [PowerAurasPath.."Aura125"] = "Vine Thorns",
  [PowerAurasPath.."Aura126"] = "3-Part Circle 1",
  [PowerAurasPath.."Aura127"] = "3-Part Circle 2",
  [PowerAurasPath.."Aura128"] = "3-Part Circle 3",
  [PowerAurasPath.."Aura129"] = "3-Part Circle Full",
  [PowerAurasPath.."Aura133"] = "Sliced Orb 1",
  [PowerAurasPath.."Aura134"] = "Sliced Orb 2",
  [PowerAurasPath.."Aura135"] = "Sliced Orb 3",
  [PowerAurasPath.."Aura136"] = "Sliced Orb 4",
  [PowerAurasPath.."Aura137"] = "Sliced Orb 5",
  [PowerAurasPath.."Aura144"] = "Taijitu Bottom",
  [PowerAurasPath.."Aura145"] = "Taijitu Top"
}

Private.texture_types["PowerAuras Words"] = {
  [PowerAurasPath.."Aura20"] = "Power",
  [PowerAurasPath.."Aura37"] = "Slow",
  [PowerAurasPath.."Aura38"] = "Stun",
  [PowerAurasPath.."Aura39"] = "Silence",
  [PowerAurasPath.."Aura40"] = "Root",
  [PowerAurasPath.."Aura41"] = "Disorient",
  [PowerAurasPath.."Aura42"] = "Dispel",
  [PowerAurasPath.."Aura43"] = "Danger",
  [PowerAurasPath.."Aura44"] = "Buff",
  [PowerAurasPath.."Aura44"] = "Buff",
  ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\interrupt"] = "Interrupt"
}

Private.operator_types = {
  ["=="] = "=",
  ["~="] = "!=",
  [">"] = ">",
  ["<"] = "<",
  [">="] = ">=",
  ["<="] = "<="
}

Private.equality_operator_types = {
  ["=="] = "=",
  ["~="] = "!="
}

Private.operator_types_without_equal = {
  [">="] = ">=",
  ["<="] = "<="
}

Private.string_operator_types = {
  ["=="] = L["Is Exactly"],
  ["find('%s')"] = L["Contains"],
  ["match('%s')"] = L["Matches (Pattern)"]
}

Private.weapon_types = {
  ["main"] = MAINHANDSLOT,
  ["off"] = SECONDARYHANDSLOT
}

Private.swing_types = {
  ["main"] = MAINHANDSLOT,
  ["off"] = SECONDARYHANDSLOT
}

if WeakAuras.IsClassicOrBCCOrWrath() then
  Private.swing_types["ranged"] = RANGEDSLOT
end

if WeakAuras.IsWrathClassic() then
  Private.rune_specific_types = {
    [1] = L["Blood Rune #1"],
    [2] = L["Blood Rune #2"],
    [3] = L["Unholy Rune #1"],
    [4] = L["Unholy Rune #2"],
    [5] = L["Frost Rune #1"],
    [6] = L["Frost Rune #2"],
  }
else
  Private.rune_specific_types = {
    [1] = L["Rune #1"],
    [2] = L["Rune #2"],
    [3] = L["Rune #3"],
    [4] = L["Rune #4"],
    [5] = L["Rune #5"],
    [6] = L["Rune #6"]
  }
end

Private.custom_trigger_types = {
  ["event"] = L["Event"],
  ["status"] = L["Status"],
  ["stateupdate"] = L["Trigger State Updater (Advanced)"]
}

Private.eventend_types = {
  ["timed"] = L["Timed"],
  ["custom"] = L["Custom"]
}

Private.timedeventend_types = {
  ["timed"] = L["Timed"],
}

Private.justify_types = {
  ["LEFT"] = L["Left"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Right"]
}

Private.grow_types = {
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
Private.grid_types = {
  RU = L["Right, then Up"],
  UR = L["Up, then Right"],
  LU = L["Left, then Up"],
  UL = L["Up, then Left"],
  RD = L["Right, then Down"],
  DR = L["Down, then Right"],
  LD = L["Left, then Down"],
  DL = L["Down, then Left"],
}

Private.text_rotate_types = {
  ["LEFT"] = L["Left"],
  ["NONE"] = L["None"],
  ["RIGHT"] = L["Right"]
}

Private.align_types = {
  ["LEFT"] = L["Left"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Right"]
}

Private.rotated_align_types = {
  ["LEFT"] = L["Top"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Bottom"]
}

Private.icon_side_types = {
  ["LEFT"] = L["Left"],
  ["RIGHT"] = L["Right"]
}

Private.rotated_icon_side_types = {
  ["LEFT"] = L["Top"],
  ["RIGHT"] = L["Bottom"]
}

Private.anim_types = {
  none = L["None"],
  preset = L["Preset"],
  custom = L["Custom"]
}

Private.anim_ease_types = {
  none = L["None"],
  easeIn = L["Ease In"],
  easeOut = L["Ease Out"],
  easeOutIn = L["Ease In and Out"]
}

Private.anim_ease_functions = {
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

Private.anim_translate_types = {
  straightTranslate = L["Normal"],
  circle = L["Circle"],
  spiral = L["Spiral"],
  spiralandpulse = L["Spiral In And Out"],
  shake = L["Shake"],
  bounce = L["Bounce"],
  bounceDecay = L["Bounce with Decay"],
  custom = L["Custom Function"]
}

Private.anim_scale_types = {
  straightScale = L["Normal"],
  pulse = L["Pulse"],
  fauxspin = L["Spin"],
  fauxflip = L["Flip"],
  custom = L["Custom Function"]
}

Private.anim_alpha_types = {
  straight = L["Normal"],
  alphaPulse = L["Pulse"],
  hide = L["Hide"],
  custom = L["Custom Function"]
}

Private.anim_rotate_types = {
  straight = L["Normal"],
  backandforth = L["Back and Forth"],
  wobble = L["Wobble"],
  custom = L["Custom Function"]
}

Private.anim_color_types = {
  straightColor = L["Legacy RGB Gradient"],
  straightHSV = L["Gradient"],
  pulseColor = L["Legacy RGB Gradient Pulse"],
  pulseHSV = L["Gradient Pulse"],
  custom = L["Custom Function"]
}

Private.instance_types = {
  none = L["No Instance"],
  scenario = L["Scenario"],
  party = L["5 Man Dungeon"],
  ten = L["10 Man Raid"],
  twenty = L["20 Man Raid"],
  twentyfive = L["25 Man Raid"],
  fortyman = L["40 Man Raid"],
  flexible = L["Flex Raid"],
  pvp = L["Battleground"],
  arena = L["Arena"],
  ratedpvp = L["Rated Battleground"],
  ratedarena = L["Rated Arena"]
}

if WeakAuras.IsClassic() then
  Private.instance_types["ratedpvp"] = nil
  Private.instance_types["arena"] = nil
  Private.instance_types["ratedarena"] = nil
end

Private.instance_difficulty_types = {

}

do
  -- Fill out instance_difficulty_types automatically.
  -- Unfortunately the names BLizzard gives are not entirely unique,
  -- so try hard to disambiguate them via the type, and if nothing works by
  -- including the plain id.

  local unused = {}

  local instance_difficulty_names = {
    [1] = L["Dungeon (Normal)"],
    [2] = L["Dungeon (Heroic)"],
    [3] = L["10 Player Raid (Normal)"],
    [4] = L["25 Player Raid (Normal)"],
    [5] = L["10 Player Raid (Heroic)"],
    [6] = L["25 Player Raid (Heroic)"],
    [7] = L["Legacy Looking for Raid"],
    [8] = L["Mythic Keystone"],
    [9] = L["40 Player Raid"],
    [11] = L["Scenario (Heroic)"],
    [12] = L["Scenario (Normal)"],
    [14] = L["Raid (Normal)"],
    [15] = L["Raid (Heroic)"],
    [16] = L["Raid (Mythic)"],
    [17] = L["Looking for Raid"],
    [18] = unused, -- Event Raid
    [19] = unused, -- Event Party
    [20] = unused, -- Event Scenario
    [23] = L["Dungeon (Mythic)"],
    [24] = L["Dungeon (Timewalking)"],
    [25] = unused, -- World PvP Scenario
    [29] = unused, -- PvEvP Scenario
    [30] = unused, -- Event Scenario
    [32] = unused, -- World PvP Scenario
    [33] = L["Raid (Timewalking)"],
    [34] = unused, -- PvP
    [38] = L["Island Expedition (Normal)"],
    [39] = L["Island Expedition (Heroic)"],
    [40] = L["Island Expedition (Mythic)"],
    [45] = L["Island Expeditions (PvP)"],
    [147] = L["Warfront (Normal)"],
    [148] = L["20 Player Raid"],
    [149] = L["Warfront (Heroic)"],
    [152] = L["Visions of N'Zoth"],
    [150] = unused, -- Normal Party
    [151] = unused, -- LfR
    [153] = unused, -- Teeming Islands
    [167] = L["Torghast"],
    [168] = L["Path of Ascension: Courage"],
    [169] = L["Path of Ascension: Loyalty"],
    [171] = L["Path of Ascension: Humility"],
    [170] = L["Path of Ascension: Wisdom"],
    [172] = unused, -- World Boss
    [173] = L["Normal Party"],
    [174] = L["Heroic Party"],
    [175] = L["10 Player Raid"],
    [176] = L["25 Player Raid"],
    [192] = L["Dungeon (Mythic+)"], -- "Challenge Level 1" TODO: check if this label is correct
    [193] = L["10 Player Raid (Heroic)"],
    [194] = L["25 Player Raid (Heroic)"],
  }

  for i = 1, 200 do
    local name, type = GetDifficultyInfo(i)
    if name then
      if instance_difficulty_names[i] then
        if instance_difficulty_names[i] ~= unused then
          Private.instance_difficulty_types[i] = instance_difficulty_names[i]
        end
      else
        Private.instance_difficulty_types[i] = name
        WeakAuras.prettyPrint(string.format("Unknown difficulty id found. Please report as a bug: %s %s %s", i, name, type))
      end
    end
  end
end

Private.TocToExpansion = {
   [1] = L["Classic"],
   [2] = L["Burning Crusade"],
   [3] = L["Wrath of the Lich King"],
   [4] = L["Cataclysm"],
   [5] = L["Mists of Pandaria"],
   [6] = L["Warlords of Draenor"],
   [7] = L["Legion"],
   [8] = L["Battle for Azeroth"],
   [9] = L["Shadowlands"],
  [10] = L["Dragonflight"]
}

Private.group_types = {
  solo = L["Not in Group"],
  group = L["In Party"],
  raid = L["In Raid"]
}

if WeakAuras.IsRetail() then
  Private.difficulty_types = {
    none = L["None"],
    normal = PLAYER_DIFFICULTY1,
    heroic = PLAYER_DIFFICULTY2,
    mythic = PLAYER_DIFFICULTY6,
    timewalking = PLAYER_DIFFICULTY_TIMEWALKER,
    lfr = PLAYER_DIFFICULTY3,
    challenge = PLAYER_DIFFICULTY5
  }
elseif WeakAuras.IsBCCOrWrath() then
  Private.difficulty_types = {
    none = L["None"],
    normal = PLAYER_DIFFICULTY1,
    heroic = PLAYER_DIFFICULTY2,
  }
end


if WeakAuras.IsClassicOrBCCOrWrath() then
  Private.raid_role_types = {
    MAINTANK = "|TInterface\\GroupFrame\\UI-Group-maintankIcon:16:16|t "..MAINTANK,
    MAINASSIST = "|TInterface\\GroupFrame\\UI-Group-mainassistIcon:16:16|t "..MAINASSIST,
    NONE = L["Other"]
  }
end
if WeakAuras.IsWrathOrRetail() then
  Private.role_types = {
    TANK = INLINE_TANK_ICON.." "..TANK,
    DAMAGER = INLINE_DAMAGER_ICON.." "..DAMAGER,
    HEALER = INLINE_HEALER_ICON.." "..HEALER
  }
end

Private.group_member_types = {
  LEADER = L["Leader"],
  ASSIST = L["Assist"],
  NONE = L["None"]
}

Private.classification_types = {
  worldboss = L["World Boss"],
  rareelite = L["Rare Elite"],
  elite = L["Elite"],
  rare = L["Rare"],
  normal = L["Normal"],
  trivial = L["Trivial (Low Level)"],
  minus = L["Minus (Small Nameplate)"]
}

Private.anim_start_preset_types = {
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

Private.anim_main_preset_types = {
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

Private.anim_finish_preset_types = {
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

Private.chat_message_types = {
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

Private.send_chat_message_types = {
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
  PRINT = L["Chat Frame"],
  ERROR = L["Error Frame"]
}


Private.send_chat_message_types.TTS = L["Text-to-speech"]
Private.tts_voices = {}
for i, voiceInfo in pairs(C_VoiceChat.GetTtsVoices()) do
  Private.tts_voices[voiceInfo.voiceID] = voiceInfo.name
end

Private.group_aura_name_info_types = {
  aura = L["Aura Name"],
  players = L["Player(s) Affected"],
  nonplayers = L["Player(s) Not Affected"]
}

Private.group_aura_stack_info_types = {
  count = L["Number Affected"],
  stack = L["Aura Stack"]
}

Private.cast_types = {
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
-- Sounds from freesound.org, see commits for attributions
LSM:Register("sound", "Sheep Blerping", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SheepBleat.ogg")
LSM:Register("sound", "Rooster Chicken Call", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RoosterChickenCalls.ogg")
LSM:Register("sound", "Goat Bleeting", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\GoatBleating.ogg")
LSM:Register("sound", "Acoustic Guitar", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\AcousticGuitar.ogg")
LSM:Register("sound", "Synth Chord", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SynthChord.ogg")
LSM:Register("sound", "Chicken Alarm", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\ChickenAlarm.ogg")
LSM:Register("sound", "Xylophone", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Xylophone.ogg")
LSM:Register("sound", "Drums", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Drums.ogg")
LSM:Register("sound", "Tada Fanfare", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\TadaFanfare.ogg")
LSM:Register("sound", "Squeaky Toy Short", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SqueakyToyShort.ogg")
LSM:Register("sound", "Error Beep", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\ErrorBeep.ogg")
LSM:Register("sound", "Oh No", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\OhNo.ogg")
LSM:Register("sound", "Double Whoosh", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\DoubleWhoosh.ogg")
LSM:Register("sound", "Brass", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Brass.mp3")
LSM:Register("sound", "Glass", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Glass.mp3")

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

local PowerAurasSoundPath = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\"
LSM:Register("sound", "Aggro", PowerAurasSoundPath.."aggro.ogg")
LSM:Register("sound", "Arrow Swoosh", PowerAurasSoundPath.."Arrow_swoosh.ogg")
LSM:Register("sound", "Bam", PowerAurasSoundPath.."bam.ogg")
LSM:Register("sound", "Polar Bear", PowerAurasSoundPath.."bear_polar.ogg")
LSM:Register("sound", "Big Kiss", PowerAurasSoundPath.."bigkiss.ogg")
LSM:Register("sound", "Bite", PowerAurasSoundPath.."BITE.ogg")
LSM:Register("sound", "Burp", PowerAurasSoundPath.."burp4.ogg")
LSM:Register("sound", "Cat", PowerAurasSoundPath.."cat2.ogg")
LSM:Register("sound", "Chant Major 2nd", PowerAurasSoundPath.."chant2.ogg")
LSM:Register("sound", "Chant Minor 3rd", PowerAurasSoundPath.."chant4.ogg")
LSM:Register("sound", "Chimes", PowerAurasSoundPath.."chimes.ogg")
LSM:Register("sound", "Cookie Monster", PowerAurasSoundPath.."cookie.ogg")
LSM:Register("sound", "Electrical Spark", PowerAurasSoundPath.."ESPARK1.ogg")
LSM:Register("sound", "Fireball", PowerAurasSoundPath.."Fireball.ogg")
LSM:Register("sound", "Gasp", PowerAurasSoundPath.."Gasp.ogg")
LSM:Register("sound", "Heartbeat", PowerAurasSoundPath.."heartbeat.ogg")
LSM:Register("sound", "Hiccup", PowerAurasSoundPath.."hic3.ogg")
LSM:Register("sound", "Huh?", PowerAurasSoundPath.."huh_1.ogg")
LSM:Register("sound", "Hurricane", PowerAurasSoundPath.."hurricane.ogg")
LSM:Register("sound", "Hyena", PowerAurasSoundPath.."hyena.ogg")
LSM:Register("sound", "Kaching", PowerAurasSoundPath.."kaching.ogg")
LSM:Register("sound", "Moan", PowerAurasSoundPath.."moan.ogg")
LSM:Register("sound", "Panther", PowerAurasSoundPath.."panther1.ogg")
LSM:Register("sound", "Phone", PowerAurasSoundPath.."phone.ogg")
LSM:Register("sound", "Punch", PowerAurasSoundPath.."PUNCH.ogg")
LSM:Register("sound", "Rain", PowerAurasSoundPath.."rainroof.ogg")
LSM:Register("sound", "Rocket", PowerAurasSoundPath.."rocket.ogg")
LSM:Register("sound", "Ship's Whistle", PowerAurasSoundPath.."shipswhistle.ogg")
LSM:Register("sound", "Gunshot", PowerAurasSoundPath.."shot.ogg")
LSM:Register("sound", "Snake Attack", PowerAurasSoundPath.."snakeatt.ogg")
LSM:Register("sound", "Sneeze", PowerAurasSoundPath.."sneeze.ogg")
LSM:Register("sound", "Sonar", PowerAurasSoundPath.."sonar.ogg")
LSM:Register("sound", "Splash", PowerAurasSoundPath.."splash.ogg")
LSM:Register("sound", "Squeaky Toy", PowerAurasSoundPath.."Squeakypig.ogg")
LSM:Register("sound", "Sword Ring", PowerAurasSoundPath.."swordecho.ogg")
LSM:Register("sound", "Throwing Knife", PowerAurasSoundPath.."throwknife.ogg")
LSM:Register("sound", "Thunder", PowerAurasSoundPath.."thunder.ogg")
LSM:Register("sound", "Wicked Male Laugh", PowerAurasSoundPath.."wickedmalelaugh1.ogg")
LSM:Register("sound", "Wilhelm Scream", PowerAurasSoundPath.."wilhelm.ogg")
LSM:Register("sound", "Wicked Female Laugh", PowerAurasSoundPath.."wlaugh.ogg")
LSM:Register("sound", "Wolf Howl", PowerAurasSoundPath.."wolf5.ogg")
LSM:Register("sound", "Yeehaw", PowerAurasSoundPath.."yeehaw.ogg")


Private.sound_types = {
  [" custom"] = " " .. L["Custom"],
  [" KitID"] = " " .. L["Sound by Kit ID"]
}

for name, path in next, LSM:HashTable("sound") do
  Private.sound_types[path] = name
end

LSM.RegisterCallback(WeakAuras, "LibSharedMedia_Registered", function(_, mediatype, key)
  if mediatype == "sound" then
    local path = LSM:Fetch(mediatype, key)
    if path then
      Private.sound_types[path] = key
    end
  end
end)

-- register options font
LSM:Register("font", "Fira Mono Medium", "Interface\\Addons\\WeakAuras\\Media\\Fonts\\FiraMono-Medium.ttf", LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)

-- register plain white border
LSM:Register("border", "Square Full White", [[Interface\AddOns\WeakAuras\Media\Textures\Square_FullWhite.tga]])

--
LSM:Register("statusbar", "Clean", [[Interface\AddOns\WeakAuras\Media\Textures\Statusbar_Clean]])
LSM:Register("statusbar", "Stripes", [[Interface\AddOns\WeakAuras\Media\Textures\Statusbar_Stripes]])
LSM:Register("statusbar", "Thick Stripes", [[Interface\AddOns\WeakAuras\Media\Textures\Statusbar_Stripes_Thick]])
LSM:Register("statusbar", "Thin Stripes", [[Interface\AddOns\WeakAuras\Media\Textures\Statusbar_Stripes_Thin]])
LSM:Register("border", "Drop Shadow", [[Interface\AddOns\WeakAuras\Media\Textures\Border_DropShadow]])

Private.duration_types = {
  seconds = L["Seconds"],
  relative = L["Relative"]
}

Private.duration_types_no_choice = {
  seconds = L["Seconds"]
}

Private.gtfo_types = {
  [1] = L["High Damage"],
  [2] = L["Low Damage"],
  [3] = L["Fail Alert"],
  [4] = L["Friendly Fire"]
}

Private.pet_behavior_types = {
  passive = PET_MODE_PASSIVE,
  defensive = PET_MODE_DEFENSIVE,
  assist = PET_MODE_ASSIST
}

if WeakAuras.IsClassicOrBCCOrWrath() then
  Private.pet_behavior_types.aggressive = PET_MODE_AGGRESSIVE
  Private.pet_behavior_types.assist = nil
end

if WeakAuras.IsRetail() then
  Private.pet_spec_types = {
    [1] = select(2, GetSpecializationInfoByID(74)), -- Ferocity
    [2] = select(2, GetSpecializationInfoByID(81)), -- Tenacity
    [3] = select(2, GetSpecializationInfoByID(79)) -- Cunning
  }
else
  Private.pet_spec_types = {}
end

Private.cooldown_progress_behavior_types = {
  showOnCooldown = L["On Cooldown"],
  showOnReady = L["Not on Cooldown"],
  showAlways = L["Always"]
}

Private.cooldown_types = {
  auto = L["Auto"],
  charges = L["Charges"],
  cooldown = L["Cooldown"]
}

Private.bufftrigger_progress_behavior_types = {
  showOnActive = L["Buffed/Debuffed"],
  showOnMissing = L["Missing"],
  showAlways= L["Always"]
}

Private.bufftrigger_2_progress_behavior_types = {
  showOnActive = L["Aura(s) Found"],
  showOnMissing = L["Aura(s) Missing"],
  showAlways = L["Always"],
  showOnMatches = L["Match Count"]
}

Private.bufftrigger_2_preferred_match_types = {
  showLowest = L["Least remaining time"],
  showHighest = L["Most remaining time"]
}

Private.bufftrigger_2_per_unit_mode = {
  affected = L["Affected"],
  unaffected = L["Unaffected"],
  all = L["All"]
}

Private.item_slot_types = {
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

Private.charges_change_type = {
  GAINED = L["Gained"],
  LOST = L["Lost"],
  CHANGED = L["Changed"]
}

Private.charges_change_condition_type = {
  GAINED = L["Gained"],
  LOST = L["Lost"]
}

Private.combat_event_type = {
  PLAYER_REGEN_ENABLED = L["Leaving"],
  PLAYER_REGEN_DISABLED = L["Entering"]
}

Private.bool_types = {
  [0] = L["False"],
  [1] = L["True"]
}

Private.absorb_modes = {
  OVERLAY_FROM_START = L["Attach to Start"],
  OVERLAY_FROM_END = L["Attach to End"]
}

Private.mythic_plus_affixes = {}

local mythic_plus_ignorelist = {
  [1] = true,
  [15] = true
}

if WeakAuras.IsRetail() then
  for i = 1, 255 do
    local r = not mythic_plus_ignorelist[i] and C_ChallengeMode.GetAffixInfo(i)
    if r then
      Private.mythic_plus_affixes[i] = r
    end
  end
end

Private.update_categories = {
  {
    name = "anchor",
    -- Note, these are special cased for child auras and considered arrangement
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
    skipInSummary = true
  },
  {
    name = "newchildren",
    fields = {},
    default = true,
    label = L["Add Missing Auras"],
    skipInSummary = true
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
Private.internal_fields = {
  uid = true,
  internalVersion = true,
  sortHybridTable = true,
  tocversion = true,
  parent = true,
  controlledChildren = true,
  source = true
}

-- fields that are not included in exported data
-- these represent information which is only meaningful inside the db,
-- or are represented in other ways in exported
Private.non_transmissable_fields = {
  controlledChildren = true,
  parent = true,
  authorMode = true,
  skipWagoUpdate = true,
  ignoreWagoUpdate = true,
  preferToUpdate = true,
  information = {
    saved = true
  }
}

-- For nested groups, we do transmit parent + controlledChildren
Private.non_transmissable_fields_v2000 = {
  authorMode = true,
  skipWagoUpdate = true,
  ignoreWagoUpdate = true,
  preferToUpdate = true,
  information = {
    saved = true
  }
}

Private.data_stub = {
  -- note: this is the minimal data stub which prevents false positives in diff upon reimporting an aura.
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
    talent = {
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
  information = {},
}

Private.author_option_classes = {
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

Private.author_option_types = {
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
  group = L["Option Group"],
}

Private.author_option_fields = {
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
    noMerge = false,
  }
}

Private.array_entry_name_types = {
  [-1] = L["Fixed Names"],
  [0] = L["Entry Order"],
  -- the rest is auto-populated with indices which are valid entry name sources
}

Private.name_source_option_types = {
  -- option types which can be used to generate entry names on arrays
  input = true,
  number = true,
  range = true,
}

Private.group_limit_types = {
  none = L["Unlimited"],
  max = L["Limited"],
  fixed = L["Fixed Size"],
}

Private.group_option_types = {
  simple = L["Simple"],
  array = L["Array"],
}

Private.difficulty_info = {
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
  [173] = {
    size = "party",
    difficulty = "normal",
  },
  [174] = {
    size = "party",
    difficulty = "heroic",
  },
  [175] = {
    size = "ten",
    difficulty = "heroic",
  },
  [176] = {
    size = "twentyfive",
    difficulty = "heroic",
  }
}

Private.glow_types = {
  ACShine = L["Autocast Shine"],
  Pixel = L["Pixel Glow"],
  buttonOverlay = L["Action Button Glow"],
}

Private.font_sizes = {
  small = L["Small"],
  medium = L["Medium"],
  large = L["Large"],
}

-- unitIds registerable with RegisterUnitEvent
Private.baseUnitId = {
  ["player"] = true,
  ["target"] = true,
  ["pet"] = true,
  ["focus"] = true,
  ["vehicle"] = true
}

Private.multiUnitId = {
  ["nameplate"] = true,
  ["boss"] = true,
  ["arena"] = true,
  ["group"] = true,
  ["grouppets"] = true,
  ["grouppetsonly"] = true,
  ["party"] = true,
  ["partypets"] = true,
  ["partypetsonly"] = true,
  ["raid"] = true,
}

Private.multiUnitUnits = {
  ["nameplate"] = {},
  ["boss"] = {},
  ["arena"] = {},
  ["group"] = {},
  ["party"] = {},
  ["raid"] = {}
}

Private.multiUnitUnits.group["player"] = true
Private.multiUnitUnits.party["player"] = true

Private.multiUnitUnits.group["pet"] = true
Private.multiUnitUnits.party["pet"] = true

for i = 1, 4 do
  Private.baseUnitId["party"..i] = true
  Private.baseUnitId["partypet"..i] = true
  Private.multiUnitUnits.group["party"..i] = true
  Private.multiUnitUnits.party["party"..i] = true
  Private.multiUnitUnits.group["partypet"..i] = true
  Private.multiUnitUnits.party["partypet"..i] = true
end

if WeakAuras.IsRetail() then
  for i = 1, 10 do
    Private.baseUnitId["boss"..i] = true
    Private.multiUnitUnits.boss["boss"..i] = true
  end
end

if WeakAuras.IsBCCOrWrathOrRetail() then
  for i = 1, 5 do
    Private.baseUnitId["arena"..i] = true
    Private.multiUnitUnits.arena["arena"..i] = true
  end
end

for i = 1, 40 do
  Private.baseUnitId["raid"..i] = true
  Private.baseUnitId["raidpet"..i] = true
  Private.baseUnitId["nameplate"..i] = true
  Private.multiUnitUnits.nameplate["nameplate"..i] = true
  Private.multiUnitUnits.group["raid"..i] = true
  Private.multiUnitUnits.raid["raid"..i] = true
  Private.multiUnitUnits.group["raidpet"..i] = true
  Private.multiUnitUnits.raid["raidpet"..i] = true
end

Private.dbm_types = {
  [1] = L["Add"],
  [2] = L["AOE"],
  [3] = L["Targeted"],
  [4] = L["Interrupt"],
  [5] = L["Role"],
  [6] = L["Phase"],
  [7] = L["Important"]
}

Private.weapon_enchant_types = {
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
  bleed =     "|TInterface\\EncounterJournal\\UI-EJ-Icons:::::256:64:158:192:32:64|t",
}

Private.reset_swing_spells = {}
Private.reset_ranged_swing_spells = {
  [2480] = true, -- Shoot Bow
  [7919] = true, -- Shoot Crossbow
  [7918] = true, -- Shoot Gun
  [2764] = true, -- Throw
  [5019] = true, -- Shoot Wands
  [75] = true, -- Auto Shot
  [5384] = true, -- Feign Death
}

Private.noreset_swing_spells = {
  [23063] = true, -- Dense Dynamite
  [4054] = true, -- Rough Dynamite
  [4064] = true, -- Rough Copper Bomb
  [4061] = true, -- Coarse Dynamite
  [8331] = true, -- Ez-Thro Dynamite
  [4065] = true, -- Large Copper Bomb
  [4066] = true, -- Small Bronze Bomb
  [4062] = true, -- Heavy Dynamite
  [4067] = true, -- Big Bronze Bomb
  [4068] = true, -- Iron Grenade
  [23000] = true, -- Ez-Thro Dynamite II
  [12421] = true, -- Mithril Frag Bomb
  [4069] = true, -- Big Iron Bomb
  [12562] = true, -- The Big One
  [12543] = true, -- Hi-Explosive Bomb
  [19769] = true, -- Thorium Grenade
  [19784] = true, -- Dark Iron Bomb
  [30216] = true, -- Fel Iron Bomb
  [19821] = true, -- Arcane Bomb
  [39965] = true, -- Frost Grenade
  [30461] = true, -- The Bigger One
  [30217] = true, -- Adamantite Grenade
  [35476] = true, -- Drums of Battle
  [35475] = true, -- Drums of War
  [35477] = true, -- Drums of Speed
  [35478] = true, -- Drums of Restoration
  [34120] = true, -- Steady Shot (rank 1)
  [19434] = true, -- Aimed Shot (rank 1)
  [1464] = true, -- Slam (rank 1)
  [8820] = true, -- Slam (rank 2)
  [11604] = true, -- Slam (rank 3)
  [11605] = true, -- Slam (rank 4)
  [25241] = true, -- Slam (rank 5)
  [25242] = true, -- Slam (rank 6)
  --35474 Drums of Panic DO reset the swing timer, do not add
}

Private.item_weapon_types = {}

local skippedWeaponTypes = {}
skippedWeaponTypes[11] = true -- Bear Claws
skippedWeaponTypes[12] = true -- Cat Claws
skippedWeaponTypes[14] = true -- Misc
skippedWeaponTypes[17] = true -- Spears
if WeakAuras.IsClassicOrBCCOrWrath() then
  skippedWeaponTypes[9] = true -- Glaives
else
  skippedWeaponTypes[16] = true -- Thrown
end

for i = 0, 20 do
  if not skippedWeaponTypes[i] then
    Private.item_weapon_types[2 * 256 + i] = GetItemSubClassInfo(2, i)
  end
end

-- Shields
Private.item_weapon_types[4 * 256 + 6] = GetItemSubClassInfo(4, 6)
WeakAuras.item_weapon_types = Private.item_weapon_types

WeakAuras.StopMotion = {}
WeakAuras.StopMotion.texture_types = {
}

WeakAuras.StopMotion.texture_types.Basic = {
  ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion"] = "Example",
}

WeakAuras.StopMotion.texture_data = {
}

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion"] = {
     ["count"] = 64,
     ["rows"] = 8,
     ["columns"] = 8
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Basic\\circle"] = {
     ["count"] = 256,
     ["rows"] = 16,
     ["columns"] = 16
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Basic\\checkmark"] = {
     ["count"] = 64,
     ["rows"] = 8,
     ["columns"] = 8
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Basic\\redx"] = {
     ["count"] = 64,
     ["rows"] = 8,
     ["columns"] = 8
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Basic\\leftarc"] = {
     ["count"] = 256,
     ["rows"] = 16,
     ["columns"] = 16
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Basic\\rightarc"] = {
     ["count"] = 256,
     ["rows"] = 16,
     ["columns"] = 16
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Basic\\fireball"] = {
     ["count"] = 7,
     ["rows"] = 5,
     ["columns"] = 5
  }


WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Runes\\AURARUNE8"] = {
     ["count"] = 256,
     ["rows"] = 16,
     ["columns"] = 16
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Runes\\legionv"] = {
     ["count"] = 64,
     ["rows"] = 8,
     ["columns"] = 8
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Runes\\legionw"] = {
     ["count"] = 64,
     ["rows"] = 8,
     ["columns"] = 8
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Runes\\legionf"] = {
     ["count"] = 64,
     ["rows"] = 8,
     ["columns"] = 8
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Runes\\legionword"] = {
     ["count"] = 64,
     ["rows"] = 8,
     ["columns"] = 8
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Kaitan\\CellRing"] = {
      ["count"] = 32,
      ["rows"] = 8,
      ["columns"] = 4
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Kaitan\\Gadget"] = {
     ["count"] = 32,
     ["rows"] = 8,
     ["columns"] = 4
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Kaitan\\Radar"] = {
     ["count"] = 32,
     ["rows"] = 8,
     ["columns"] = 4
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Kaitan\\RadarComplex"] = {
     ["count"] = 32,
     ["rows"] = 8,
     ["columns"] = 4
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Kaitan\\Saber"] = {
     ["count"] = 32,
     ["rows"] = 8,
     ["columns"] = 4
  }

WeakAuras.StopMotion.texture_data["Interface\\AddOns\\WeakAurasStopMotion\\Textures\\Kaitan\\Waveform"] = {
     ["count"] = 32,
     ["rows"] = 8,
     ["columns"] = 4
  }


WeakAuras.StopMotion.animation_types = {
  loop = L["Loop"],
  bounce = L["Forward, Reverse Loop"],
  once = L["Forward"],
  progress = L["Progress"]
}


if WeakAuras.IsClassic() then
  Private.baseUnitId.focus = nil
  Private.baseUnitId.vehicle = nil
  Private.multiUnitId.boss = nil
  Private.multiUnitId.arena = nil
  wipe(Private.multiUnitUnits.boss)
  wipe(Private.multiUnitUnits.arena)
  Private.unit_types.focus = nil
  Private.unit_types_bufftrigger_2.focus = nil
  Private.unit_types_bufftrigger_2.boss = nil
  Private.unit_types_bufftrigger_2.arena = nil
  Private.actual_unit_types_with_specific.focus = nil
  Private.actual_unit_types_cast.boss = nil
  Private.actual_unit_types_cast.arena = nil
  Private.actual_unit_types_cast.focus = nil
  Private.unit_types_range_check.focus = nil
  Private.threat_unit_types.focus = nil
  Private.item_slot_types[0] = AMMOSLOT
  Private.item_slot_types[18] = RANGEDSLOT
  Private.talent_extra_option_types[0] = nil
  Private.talent_extra_option_types[2] = nil

  local reset_swing_spell_list = {
    1464, 8820, 11604, 11605, -- Slam
    78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286, -- Heroic Strike
    845, 7369, 11608, 11609, 20569, -- Cleave
    2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266, -- Raptor Strike
    6807, 6808, 6809, 8972, 9745, 9880, 9881, -- Maul
    20549, -- War Stomp
    2480, 7919, 7918, 2764, 5019, -- Shoots
    5384, -- Feign Death
  }
  for _, spellid in ipairs(reset_swing_spell_list) do
    Private.reset_swing_spells[spellid] = true
  end
end

if WeakAuras.IsBCCOrWrath() then
  Private.item_slot_types[0] = AMMOSLOT
  Private.item_slot_types[18] = RANGEDSLOT
  Private.talent_extra_option_types[0] = nil
  Private.talent_extra_option_types[2] = nil
  Private.multiUnitId.boss = nil
  wipe(Private.multiUnitUnits.boss)
  Private.unit_types_bufftrigger_2.boss = nil
  Private.actual_unit_types_cast.boss = nil

  local reset_swing_spell_list = {
    1464, 8820, 11604, 11605, 25241, 25242, -- Slam
    78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286, 29707, 30324, -- Heroic Strike
    845, 7369, 11608, 11609, 20569, 25231, -- Cleave
    2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266, 27014, -- Raptor Strike
    6807, 6808, 6809, 8972, 9745, 9880, 9881, 26996, -- Maul
    20549, -- War Stomp
    2764, 3018, -- Shoots,
    19434, 20900, 20901, 20902, 20903, 20904, 27065, -- Aimed Shot
    20066, -- Repentance
    11350, -- Fire Shield (Oil of Immolation)
    50986, -- Sulfuron Slammer
    439, 440, 441, 2024, 4042, 17534, 28495, -- Minor/Lesser/Greater/Superior/Major/Super Healing Potion
    41619, 41620, -- Cenarion Healing Salve/Bottled Nethergon Vapor
    5384, -- Feign Death
  }
  for _, spellid in ipairs(reset_swing_spell_list) do
    Private.reset_swing_spells[spellid] = true
  end

  local reset_ranged_swing_spell_list = {
    2764, 3018, -- Shoots
    19434, 20900, 20901, 20902, 20903, 20904, 27065 -- Aimed Shot
  }

  for _, spellid in ipairs(reset_ranged_swing_spell_list) do
    Private.reset_ranged_swing_spells[spellid] = true
  end
end
