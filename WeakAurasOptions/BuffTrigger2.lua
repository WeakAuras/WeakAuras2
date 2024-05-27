if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L

local function getAuraMatchesLabel(name)
  local ids = WeakAuras.spellCache.GetSpellsMatching(name)
  if ids then
    local numMatches = 0
    for _ in pairs(ids) do
      numMatches = numMatches + 1
    end
    return tostring(numMatches)
  else
    return ""
  end
end

local function getAuraMatchesList(name)
  local ids = WeakAuras.spellCache.GetSpellsMatching(name)
  if ids then
    local descText = ""
    for id, _ in pairs(ids) do
      local icon = OptionsPrivate.Private.ExecEnv.GetSpellIcon(id)
      if icon then
        if descText == "" then
          descText = "|T"..icon..":0|t: "..id
        else
          descText = descText.."\n|T"..icon..":0|t: "..id
        end
      end
    end
    return descText
  else
    return ""
  end
end

local function shiftTable(tbl, pos)
  local size = #tbl
  for i = pos, size, 1 do
    tbl[i] = tbl[i + 1]
  end
end

-- Counts the Names or SpellIds in a aura, recursively.
local function CountNames(data, triggernum, name)
  local result = 0
  local trigger = data.triggers[triggernum].trigger
  if trigger[name] then
    result = #trigger[name]
  end
  return result
end

local function IsGroupTrigger(trigger)
  return trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"
         or trigger.unit == "boss" or trigger.unit == "nameplate" or trigger.unit == "arena" or trigger.unit == "multi"
end

local function IsSingleMissing(trigger)
  return not IsGroupTrigger(trigger) and trigger.matchesShowOn == "showOnMissing"
end

local function CanHaveMatchCheck(trigger)
  if IsGroupTrigger(trigger) then
    return true
  end
  if trigger.matchesShowOn == "showOnMissing" then
    return false
  end
  if trigger.matchesShowOn == "showOnActive" or trigger.matchesShowOn == "showOnMatches" or not trigger.matchesShowOn then
    return true
  end
  -- Always: If clones are shown
  return trigger.showClones
end

local function CreateNameOptions(aura_options, data, trigger, size, isExactSpellId, isIgnoreList, prefix, baseOrder, useKey, optionKey, name, desc, inverse)
  local spellCache = WeakAuras.spellCache

  for i = 1, size do
    local hiddenFunction
    if isIgnoreList then
      hiddenFunction = function()
        return not (trigger.type == "aura2" and trigger[useKey] and (i == 1 or trigger[optionKey] and trigger[optionKey][i - 1]) and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger))
      end
    else
      hiddenFunction = function()
        return not (trigger.type == "aura2" and trigger[useKey] and (i == 1 or trigger[optionKey] and trigger[optionKey][i - 1]))
      end
    end

    if i ~= 1 then
      aura_options[prefix .. "space" .. i] = {
        type = "execute",
        name = inverse and L["and"] or L["or"],
        width = WeakAuras.normalWidth - 0.2,
        image = function() return "", 0, 0 end,
        order = baseOrder + i / 100 + 0.0001,
        hidden = hiddenFunction
      }
    end

    local iconOption = prefix .. "icon" .. i
    aura_options[iconOption] = {
      type = "execute",
      width = 0.2,
      order = baseOrder + i / 100 + 0.0002,
      hidden = hiddenFunction,
      control = "WeakAurasIcon"
    }

    if isExactSpellId then
      aura_options[iconOption].name = function()
        return OptionsPrivate.Private.ExecEnv.GetSpellName(WeakAuras.SafeToNumber(trigger[optionKey] and trigger[optionKey][i]) or "")
      end
      aura_options[iconOption].image = function()
        local icon = OptionsPrivate.Private.ExecEnv.GetSpellIcon(trigger[optionKey] and trigger[optionKey][i] or "")
        return icon and tostring(icon) or "", 18, 18
      end
      aura_options[iconOption].disabled = function()
        return not trigger[optionKey] or not trigger[optionKey][i] or not OptionsPrivate.Private.ExecEnv.GetSpellIcon(trigger[optionKey] and trigger[optionKey][i])
      end
    else
      aura_options[iconOption].name = function()
        local spellId = trigger[optionKey] and trigger[optionKey][i] and WeakAuras.SafeToNumber(trigger[optionKey][i])
        if spellId then
          return getAuraMatchesLabel(OptionsPrivate.Private.ExecEnv.GetSpellName(spellId))
        else
          return getAuraMatchesLabel(trigger[optionKey] and trigger[optionKey][i])
        end
      end

      aura_options[iconOption].desc = function()
        local spellId = trigger[optionKey] and trigger[optionKey][i] and WeakAuras.SafeToNumber(trigger[optionKey][i])
        if spellId then
          local name = OptionsPrivate.Private.ExecEnv.GetSpellName(spellId)
          if name then
            local auraDesc = getAuraMatchesList(name)
            if auraDesc then
              auraDesc = name .. "\n" .. auraDesc
            end
            return auraDesc
          end
        else
          return getAuraMatchesList(trigger[optionKey] and trigger[optionKey][i])
        end
      end
      aura_options[iconOption].image = function()
        local icon
        local spellId = trigger[optionKey] and trigger[optionKey][i] and WeakAuras.SafeToNumber(trigger[optionKey][i])
        if spellId then
          icon = OptionsPrivate.Private.ExecEnv.GetSpellIcon(spellId)
        else
          icon = spellCache.GetIcon(trigger[optionKey] and trigger[optionKey][i])
        end
        return icon and tostring(icon) or "", 18, 18
      end
    end

    aura_options[prefix .. i] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = name,
      desc = desc,
      order = baseOrder + i / 100 + 0.0003,
      hidden = hiddenFunction,
      get = function(info)
        local rawString = trigger[optionKey] and trigger[optionKey][i] or ""
        local spellName, _, _, _, _, _, spellID = OptionsPrivate.Private.ExecEnv.GetSpellInfo(WeakAuras.SafeToNumber(rawString))
        if spellName and spellID then
          return ("%s (%s)"):format(spellID, spellName) .. "\0" .. rawString
        else
          return rawString .. "\0" .. rawString
        end
      end,
      set = function(info, v)
        trigger[optionKey] = trigger[optionKey] or {}
        if v == "" then
          shiftTable(trigger[optionKey], i)
        else
          if isExactSpellId then
            trigger[optionKey][i] = v
          else
            local spellId = tonumber(v)
            if spellId then
              WeakAuras.spellCache.CorrectAuraName(v)
              trigger[optionKey][i] = v
            else
              trigger[optionKey][i] = spellCache.BestKeyMatch(v)
            end
          end
        end

        WeakAuras.Add(data)
        WeakAuras.UpdateThumbnail(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end,
      validate = isExactSpellId and WeakAuras.ValidateNumeric or nil,
      control = "WeakAurasInputFocus",
    }
  end
  -- VALIDATE ?
end

local function GetBuffTriggerOptions(data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  local function HasMatchCount(trigger)
    if IsGroupTrigger(trigger) then
      return trigger.useMatch_count
    else
      return trigger.matchesShowOn == "showOnMatches"
    end
  end

  local function HasMatchPerUnitCount(trigger)
    if trigger.type == "aura2" and IsGroupTrigger(trigger)
      and trigger.showClones and trigger.combinePerUnit and trigger.perUnitMode ~= "unaffected"
    then
      return trigger.useMatchPerUnit_count
    end
  end

  local ValidateNumeric = WeakAuras.ValidateNumeric
  local aura_options = {
    useUnit = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Unit"],
      order = 10,
      disabled = true,
      get = function() return true end
    },
    unit = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Unit"],
      order = 10.1,
      values = function()
        return OptionsPrivate.Private.unit_types_bufftrigger_2
      end,
      desc = L["• |cff00ff00Player|r, |cff00ff00Target|r, |cff00ff00Focus|r, and |cff00ff00Pet|r correspond directly to those individual unitIDs.\n• |cff00ff00Specific Unit|r lets you provide a specific valid unitID to watch.\n|cffff0000Note|r: The game will not fire events for all valid unitIDs, making some untrackable by this trigger.\n• |cffffff00Party|r, |cffffff00Raid|r, |cffffff00Boss|r, |cffffff00Arena|r, and |cffffff00Nameplate|r can match multiple corresponding unitIDs.\n• |cffffff00Smart Group|r adjusts to your current group type, matching just the \"player\" when solo, \"party\" units (including \"player\") in a party or \"raid\" units in a raid.\n• |cffffff00Multi-target|r attempts to use the Combat Log events, rather than unitID, to track affected units.\n|cffff0000Note|r: Without a direct relationship to actual unitIDs, results may vary.\n\n|cffffff00*|r Yellow Unit settings can match multiple units and will default to being active even while no affected units are found without a Unit Count or Match Count setting."],
    },
    useSpecificUnit = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Specific Unit"],
      order = 10.2,
      disabled = true,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "member") end,
      get = function() return true end
    },
    specificUnit = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Specific Unit"],
      order = 10.3,
      desc = L["A Unit ID (e.g., party1)."],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "member") end
    },
    warnSpecifcUnit = {
      type = "description",
      width = WeakAuras.doubleWidth,
      name = function()
        return L["|cFFFF0000Note:|r The unit '%s' is not a trackable unit."]:format(trigger.specificUnit or "")
      end,
      order = 10.4,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "member" and WeakAuras.UntrackableUnit(trigger.specificUnit)) end
    },
    warnSoftTarget = {
      type = "description",
      width = WeakAuras.doubleWidth,
      name = function()
        return L["|cFFFF0000Note:|r The unit '%s' requires soft target cvars to be enabled."]:format(trigger.unit or "")
      end,
      order = 10.4,
      hidden = function() return not WeakAuras.IsUntrackableSoftTarget(trigger.unit) end
    },
    useDebuffType = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Aura Type"],
      order = 11,
      disabled = true,
      get = function() return true end
    },
    debuffType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Aura Type"],
      order = 11.1,
      values = OptionsPrivate.Private.debuff_types,
    },
    spell_filters_header = {
      type = "header",
      name = L["Spell Selection Filters"],
      order = 11.15,
    },
    use_debuffClass = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Debuff Type"],
      order = 11.2,
      desc = L["Filter to only dispellable de/buffs of the given type(s)"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end
    },
    debuffClass = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Debuff Type"],
      order = 11.3,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "multi"
          and CanHaveMatchCheck(trigger)
          and trigger.use_debuffClass)
      end,
      values = OptionsPrivate.Private.debuff_class_types,
    },
    debuffClassSpace = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 11.4,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "multi"
          and CanHaveMatchCheck(trigger)
          and not trigger.use_debuffClass)
      end
    },
    useName = {
      type = "toggle",
      name = L["Name(s)"],
      order = 12,
      width = WeakAuras.normalWidth - 0.2,
    },
    useNameSpace = {
      type = "description",
      name = "",
      order = 12.1,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and not trigger.useName) end
    },
    useExactSpellId = {
      type = "toggle",
      name = L["Exact Spell ID(s)"],
      width = WeakAuras.normalWidth - 0.2,
      order = 22,
    },
    useExactSpellIdSpace = {
      type = "description",
      name = "",
      order = 22.1,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and not trigger.useExactSpellId) end
    },
    useIgnoreName = {
      type = "toggle",
      name = L["Ignored Name(s)"],
      order = 32,
      width = WeakAuras.normalWidth - 0.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end
    },
    useIgnoreNameSpace = {
      type = "description",
      name = "",
      order = 32.1,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and not trigger.useIgnoreName and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end
    },
    useIgnoreExactSpellId = {
      type = "toggle",
      name = L["Ignored Exact Spell ID(s)"],
      width = WeakAuras.normalWidth - 0.2,
      order = 42,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end
    },
    useIgnoreExactSpellIddSpace = {
      type = "description",
      name = "",
      order = 42.1,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and not trigger.useIgnoreExactSpellId and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end
    },

    useNamePattern = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Name Pattern Match"],
      desc = L["Filter based on the spell Name string."],
      order = 55,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi") end
    },
    useNamePatternSpace = {
      type = "description",
      name = "",
      order = 55.2,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not trigger.useNamePattern) end
    },
    namePattern_operator = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Operator"],
      order = 55.1,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and trigger.useNamePattern) end,
      values = OptionsPrivate.Private.string_operator_types
    },
    namePattern_name = {
      type = "input",
      name = L["Aura Name Pattern"],
      width = WeakAuras.doubleWidth,
      order = 55.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and trigger.useNamePattern) end
    },
    aura_filters_header = {
      type = "header",
      name = L["Active Aura Filters and Info"],
      order = 59.9,
    },
    useStacks = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Stack Count"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end,
      order = 60
    },
    stacksOperator = {
      type = "select",
      name = L["Operator"],
      order = 60.1,
      width = WeakAuras.halfWidth,
      values = OptionsPrivate.Private.operator_types,
      disabled = function() return not trigger.useStacks end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.useStacks) end,
      get = function() return trigger.useStacks and trigger.stacksOperator or nil end
    },
    stacks = {
      type = "input",
      name = L["Stack Count"],
      validate = ValidateNumeric,
      order = 60.2,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.useStacks) end,
      get = function() return trigger.useStacks and trigger.stacks or nil end
    },
    useStacksSpace = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 60.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and not trigger.useStacks) end
    },
    useRem = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Remaining Time"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end,
      order = 61
    },
    remOperator = {
      type = "select",
      name = L["Operator"],
      order = 61.1,
      width = WeakAuras.halfWidth,
      values = OptionsPrivate.Private.operator_types,
      disabled = function() return not trigger.useRem end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.useRem) end,
      get = function() return trigger.useRem and trigger.remOperator or nil end
    },
    rem = {
      type = "input",
      name = L["Remaining Time"],
      validate = ValidateNumeric,
      order = 61.2,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.useRem) end,
      get = function() return trigger.useRem and trigger.rem or nil end
    },
    useRemSpace = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 61.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and not trigger.useRem) end
    },
    useTotal = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Total Time"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end,
      order = 61.4
    },
    totalOperator = {
      type = "select",
      name = L["Operator"],
      order = 61.5,
      width = WeakAuras.halfWidth,
      values = OptionsPrivate.Private.operator_types,
      disabled = function() return not trigger.useTotal end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.useTotal) end,
      get = function() return trigger.useTotal and trigger.totalOperator or nil end
    },
    total = {
      type = "input",
      name = L["Total Time"],
      validate = ValidateNumeric,
      order = 61.6,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.useTotal) end,
      get = function() return trigger.useTotal and trigger.total or nil end
    },
    useTotalSpace = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 61.7,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and not trigger.useTotal) end
    },
    use_stealable = {
      type = "toggle",
      name = function(input)
        local value = trigger.use_stealable
        if value == nil then return L["Is Stealable"]
        elseif value == false then return "|cFFFF0000 " .. L["Negator"] .. " " .. L["Is Stealable"] .. "|r"
        else return "|cFF00FF00" .. L["Is Stealable"] .. "|r" end
      end,
      width = WeakAuras.doubleWidth,
      order = 64,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end,
      get = function()
        local value = trigger.use_stealable
        if value == nil then return false
        elseif value == false then return "false"
        else return "true" end
      end,
      set = function(info, v)
        if v then
          trigger.use_stealable = true
        else
          local value = trigger.use_stealable
          if value == false then trigger.use_stealable = nil
          else trigger.use_stealable = false end
        end
        WeakAuras.Add(data)
      end
    },
    use_isBossDebuff = {
      type = "toggle",
      name = function(input)
        local value = trigger.use_isBossDebuff
        if value == nil then return L["Is Boss Debuff"]
        elseif value == false then return "|cFFFF0000 " .. L["Negator"] .. " " .. L["Is Boss Debuff"] .. "|r"
        else return "|cFF00FF00" .. L["Is Boss Debuff"] .. "|r" end
      end,
      width = WeakAuras.doubleWidth,
      order = 64.1,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end,
      get = function()
        local value = trigger.use_isBossDebuff
        if value == nil then return false
        elseif value == false then return "false"
        else return "true" end
      end,
      set = function(info, v)
        if v then
          trigger.use_isBossDebuff = true
        else
          local value = trigger.use_isBossDebuff
          if value == false then trigger.use_isBossDebuff = nil
          else trigger.use_isBossDebuff = false end
        end
        WeakAuras.Add(data)
      end
    },
    use_castByPlayer = {
      type = "toggle",
      name = function()
        local value = trigger.use_castByPlayer
        if value == nil then return L["Cast by a Player Character"]
        elseif value == false then return "|cFFFF0000 "..L["Negator"].." "..L["Cast by a Player Character"]
        else return "|cFF00FF00"..L["Cast by a Player Character"] end
      end,
      desc = L["Only Match auras cast by a player (not an npc)"],
      width = WeakAuras.doubleWidth,
      order = 64.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger)) end,
      get = function()
        local value = trigger.use_castByPlayer
        if value == nil then return false
        elseif value == false then return "false"
        else return "true" end
      end,
      set = function(info, v)
        if v then
          trigger.use_castByPlayer = true
        else
          local value = trigger.use_castByPlayer
          if value == false then trigger.use_castByPlayer = nil
          else trigger.use_castByPlayer = false end
        end
        WeakAuras.Add(data)
      end
    },
    ownOnly = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = function()
        local value = trigger.ownOnly
        if value == nil then return L["Own Only"]
        elseif value == false then return "|cFFFF0000 " .. L["Negator"] .. " " .. L["Own Only"] .. "|r"
        else return "|cFF00FF00" .. L["Own Only"] .. "|r" end
      end,
      desc = function()
        local value = trigger.ownOnly
        if value == nil then return L["Only match auras cast by the player or their pet"]
        elseif value == false then return L["Only match auras cast by people other than the player or their pet"]
        else return L["Only match auras cast by the player or their pet"] end
      end,
      get = function()
        local value = trigger.ownOnly
        if value == nil then return false
        elseif value == false then return "false"
        else return "true" end
      end,
      set = function(info, v)
        if v then
          trigger.ownOnly = true
        else
          local value = trigger.ownOnly
          if value == false then trigger.ownOnly = nil
          else trigger.ownOnly = false end
        end
        WeakAuras.Add(data)
      end,
      order = 64.3,
      hidden = function() return not trigger.type == "aura2" end
    },

    fetchTooltip = {
      type = "toggle",
      name = L["Fetch Tooltip Information"],
      desc = L["This adds %tooltip, %tooltip1, %tooltip2, %tooltip3 and %tooltip4 as text replacements and also allows filtering based on the tooltip content/values."],
      order = 64.5,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end
    },
    use_tooltip = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip Pattern Match"],
      order = 64.51,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.fetchTooltip) end
    },
    use_tooltipSpace = {
      type = "description",
      name = "",
      order = 64.52,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and not trigger.use_tooltip and trigger.fetchTooltip) end
    },
    tooltip_operator = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Operator"],
      order = 64.53,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.use_tooltip and trigger.fetchTooltip) end,
      values = OptionsPrivate.Private.string_operator_types
    },
    tooltip = {
      type = "input",
      name = L["Tooltip Content"],
      width = WeakAuras.doubleWidth,
      order = 64.54,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.use_tooltip and trigger.fetchTooltip) end
    },
    use_tooltipValue = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip Value"],
      order = 64.55,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.fetchTooltip) end
    },
    tooltipValueNumber = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Tooltip Value #"],
      order = 64.56,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.use_tooltipValue and trigger.fetchTooltip) end,
      values = OptionsPrivate.Private.tooltip_count
    },
    use_tooltipValueSpace = {
      type = "description",
      name = "",
      order = 64.57,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and not trigger.use_tooltipValue and trigger.fetchTooltip) end
    },
    tooltipValue_operator = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Operator"],
      order = 64.58,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.use_tooltipValue and trigger.fetchTooltip) end,
      values = OptionsPrivate.Private.operator_types
    },
    tooltipValue = {
      type = "input",
      name = L["Tooltip"],
      width = WeakAuras.normalWidth,
      validate = ValidateNumeric,
      order = 64.59,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and CanHaveMatchCheck(trigger) and trigger.use_tooltipValue and trigger.fetchTooltip) end
    },
    unit_filters_header = {
      type = "header",
      name = L["Affected Unit Filters and Info"],
      order = 65,
      hidden = function() return trigger.unit == "multi" end,
    },
    useAffected = {
      type = "toggle",
      name = L["Fetch Affected/Unaffected Names and Units"],
      width = WeakAuras.doubleWidth,
      order = 65.1,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")) end
    },
    fetchRole = {
      type = "toggle",
      name = L["Fetch Role Information"],
      desc = L["This adds %role, %roleIcon as text replacements. Does nothing if the unit is not a group member."],
      order = 65.2,
      width = WeakAuras.doubleWidth,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "multi")
               or WeakAuras.IsClassicEra()
      end
    },
    fetchRaidMark = {
      type = "toggle",
      name = L["Fetch Raid Mark Information"],
      desc = L["This adds %raidMark as text replacements."],
      order = 65.3,
      width = WeakAuras.doubleWidth,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "multi")
      end
    },
    use_includePets = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Include Pets"],
      order = 66.1,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"))
      end
    },
    includePets = {
      type = "select",
      values = OptionsPrivate.Private.include_pets_types,
      width = WeakAuras.normalWidth,
      name = L["Include Pets"],
      order = 66.15,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and trigger.use_includePets) end,
    },
    includePetsSpace = {
      type = "description",
      name = "",
      order = 66.16,
      width = WeakAuras.normalWidth,
      hidden = function()
        return not (trigger.type == "aura2"
                    and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and not trigger.use_includePets)
      end
    },

    useActualSpec = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Specialization"],
      desc = L["Requires LibSpecialization, that is e.g. a up-to date WeakAuras version"],
      order = 66.3,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
        and WeakAuras.IsCataOrRetail())
      end,
    },
    actualSpec = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Actual Spec"],
      desc = L["Requires syncing the specialization via LibSpecialization."],
      values = OptionsPrivate.Private.spec_types_all,
      hidden = function()
        return not (trigger.type == "aura2"
                    and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
                    and trigger.useActualSpec
                    and WeakAuras.IsCataOrRetail())
      end,
      order = 66.4
    },
    actualSpecSpace = {
      type = "description",
      name = "",
      order = 66.5,
      width = WeakAuras.normalWidth,
      hidden = function()
        return not (trigger.type == "aura2"
                    and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")
                    and not trigger.useActualSpec
                    and WeakAuras.IsCataOrRetail())
      end
    },

    useGroupRole = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Group Role"],
      order = 67.1,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"))
        or WeakAuras.IsClassicEra()
      end
    },
    group_role = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Group Role"],
      values = OptionsPrivate.Private.role_types,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and trigger.useGroupRole)
        or WeakAuras.IsClassicEra()
      end,
      order = 67.2
    },
    group_roleSpace = {
      type = "description",
      name = "",
      order = 67.3,
      width = WeakAuras.normalWidth,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and not trigger.useGroupRole)
        or WeakAuras.IsClassicEra()
      end
    },
    useRaidRole = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Raid Role"],
      order = 67.4,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"))
        or WeakAuras.IsRetail()
      end
    },
    raid_role = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Raid Role"],
      values = OptionsPrivate.Private.raid_role_types,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and trigger.useRaidRole)
        or WeakAuras.IsRetail()
      end,
      order = 67.5
    },
    raid_roleSpace = {
      type = "description",
      name = "",
      order = 67.6,
      width = WeakAuras.normalWidth,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and not trigger.useRaidRole)
        or WeakAuras.IsRetail()
      end
    },
    useArenaSpec = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Arena Spec"],
      order = 67.8,
      hidden = function() return
        not (WeakAuras.IsRetail() and trigger.type == "aura2" and trigger.unit == "arena")
      end
    },
    arena_spec = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Specialization"],
      values = OptionsPrivate.Private.spec_types_all,
      hidden = function()
        return not (WeakAuras.IsRetail() and trigger.type == "aura2" and trigger.unit == "arena" and trigger.useArenaSpec)
      end,
      order = 67.9
    },
    arena_specSpace = {
      type = "description",
      name = "",
      order = 67.91,
      width = WeakAuras.normalWidth,
      hidden = function()
        return not (WeakAuras.IsRetail() and trigger.type == "aura2" and trigger.unit == "arena" and not trigger.useArenaSpec)
      end,
    },

    useClass = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Class"],
      order = 68.1,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"))
      end
    },
    class = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Class"],
      values = WeakAuras.class_types,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and trigger.useClass) end,
      order = 68.2
    },
    classSpace = {
      type = "description",
      name = "",
      order = 68.3,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and not trigger.useClass) end
    },

    useUnitName = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Unit Name"],
      order = 68.4,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"))
      end
    },
    unitName = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Filter by Unit Name"],
      desc = L["Filter formats: 'Name', 'Name-Realm', '-Realm'.\n\nSupports multiple entries, separated by commas\nCan use \\ to escape -."],
      order = 68.5,
      hidden = function()
        return not (trigger.type == "aura2"
                    and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and trigger.useUnitName)
      end
    },
    unitNameSpace = {
      type = "description",
      name = "",
      order = 68.5,
      width = WeakAuras.normalWidth,
      hidden = function()
        return not (trigger.type == "aura2"
                    and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and not trigger.useUnitName)
      end
    },

    useHostility = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Nameplate Type"],
      order = 69.1,
      hidden = function() return
        not (trigger.type == "aura2" and trigger.unit == "nameplate")
      end
    },
    hostility = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Hostility"],
      values = OptionsPrivate.Private.hostility_types,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "nameplate" and trigger.useHostility) end,
      order = 69.2
    },
    hostilitySpace = {
      type = "description",
      name = "",
      order = 69.3,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "nameplate" and not trigger.useHostility) end
    },

    useNpcId = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Npc ID"],
      order = 69.31,
      hidden = function() return
        not (trigger.type == "aura2" and trigger.unit == "nameplate")
      end
    },
    npcId = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Npc ID"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "nameplate" and trigger.useNpcId) end,
      order = 69.32,
      desc = L["Supports multiple entries, separated by commas"]
    },
    npcIdSpace = {
      type = "description",
      name = "",
      order = 69.33,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "nameplate" and not trigger.useNpcId) end
    },

    ignoreSelf = {
      type = "toggle",
      name = L["Ignore Self"],
      order = 69.35,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party" or trigger.unit == "nameplate")) end
    },

    ignoreDead = {
      type = "toggle",
      name = L["Ignore Dead"],
      order = 69.4,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")) end
    },

    ignoreDisconnected = {
      type = "toggle",
      name = L["Ignore Disconnected"],
      order = 69.8,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")) end
    },
    inRange = {
      type = "toggle",
      name = L["Ignore out of casting range"],
      desc = L["Uses UnitInRange() to check if in range. Matches default raid frames out of range behavior, which is between 25 to 40 yards depending on your class and spec."],
      order = 69.81,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and WeakAuras.IsRetail()) end
    },
    ignoreInvisible = {
      type = "toggle",
      name = L["Ignore out of checking range"],
      desc = L["Uses UnitIsVisible() to check if game client has loaded a object for this unit. This distance is around 100 yards. This is polled every second."],
      order = 69.9,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")) end
    },

    show_settings_header = {
      type = "header",
      name = L["Show and Clone Settings"],
      order = 69.91,
    },
    multi_unit_hint = {
      type = "description",
      order = 69.92,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger)) end,
      name = L["|cff999999Triggers tracking multiple units will default to being active even while no affected units are found without a Unit Count or Match Count setting applied.|r"],
    },
    useGroup_count = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Unit Count"],
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger)) end,
      order = 70
    },
    useGroup_countSpace = {
      type = "description",
      name = "",
      order = 70.1,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and not trigger.useGroup_count) end
    },
    group_countOperator = {
      type = "select",
      name = L["Operator"],
      desc = function()
        if (trigger.unit == "multi") then
          return L["Compare against the number of units affected."]
        else
          local groupType = OptionsPrivate.Private.unit_types_bufftrigger_2[trigger.unit or "group"] or "|cFFFF0000Error|r"
          return L["Group aura count description"]:format(groupType, groupType, groupType, groupType, groupType, groupType, groupType)
        end
      end,
      order = 70.2,
      width = WeakAuras.halfWidth,
      values = OptionsPrivate.Private.operator_types,
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and trigger.useGroup_count) end,
      get = function() return trigger.group_countOperator end
    },
    group_count = {
      type = "input",
      name = L["Count"],
      desc = function()
        if (trigger.unit == "multi") then
          return L["Compare against the number of units affected."]
        else
          local groupType = OptionsPrivate.Private.unit_types_bufftrigger_2[trigger.unit or "group"] or "|cFFFF0000Error|r"
          return L["Group aura count description"]:format(groupType, groupType, groupType, groupType, groupType, groupType, groupType)
        end
      end,
      order = 70.3,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and trigger.useGroup_count) end,
    },

    use_matchesShowOn = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show On"],
      order = 71,
      hidden = function() return not (trigger.type == "aura2" and not IsGroupTrigger(trigger)) end,
      get = function() return true end,
      disabled = true
    },
    matchesShowOn = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Show On"],
      values = OptionsPrivate.Private.bufftrigger_2_progress_behavior_types,
      order = 71.1,
      hidden = function() return not (trigger.type == "aura2" and not IsGroupTrigger(trigger)) end,
      get = function()
        return trigger.matchesShowOn or "showOnActive"
      end
    },
    useMatch_count = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Match Count"],
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger)) end,
      order = 71.2
    },
    useMatch_countSpace = {
      type = "description",
      name = "",
      order = 71.3,
      width = WeakAuras.normalWidth,
      hidden = function()
        if trigger.type ~= "aura2" then
          return true
        end
        if IsGroupTrigger(trigger) then
          return trigger.useMatch_count
        else
          return trigger.matchesShowOn ~= "showOnMatches"
        end
      end
    },
    match_countOperator = {
      type = "select",
      name = L["Operator"],
      order = 71.4,
      width = WeakAuras.halfWidth,
      values = OptionsPrivate.Private.operator_types,
      hidden = function() return not (trigger.type == "aura2" and HasMatchCount(trigger)) end,
      desc = L["Counts the number of matches over all units."]
    },
    match_count = {
      type = "input",
      name = L["Count"],
      order = 71.5,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura2" and HasMatchCount(trigger)) end,
      validate = ValidateNumeric,
      desc = L["Counts the number of matches over all units."]
    },
    useMatchPerUnit_count = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Match Count per Unit"],
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger)
        and trigger.showClones and trigger.combinePerUnit and trigger.perUnitMode ~= "unaffected") end,
      order = 71.6
    },
    useMatchPerUnit_countSpace = {
      type = "description",
      name = "",
      order = 71.7,
      width = WeakAuras.normalWidth,
      hidden = function()
        if trigger.type == "aura2" and IsGroupTrigger(trigger)
          and trigger.showClones and trigger.combinePerUnit and trigger.perUnitMode ~= "unaffected" then
            return trigger.useMatchPerUnit_count
        end
        return true
      end
    },
    matchPerUnit_countOperator = {
      type = "select",
      name = L["Operator"],
      order = 71.8,
      width = WeakAuras.halfWidth,
      values = OptionsPrivate.Private.operator_types,
      hidden = function() return not (HasMatchPerUnitCount(trigger)) end,
      desc = L["Counts the number of matches per unit."]
    },
    matchPerUnit_count = {
      type = "input",
      name = L["Count"],
      order = 71.9,
      width = WeakAuras.halfWidth,
      hidden = function() return not (HasMatchPerUnitCount(trigger)) end,
      validate = ValidateNumeric,
      desc = L["Counts the number of matches per unit."]
    },
    showClones = {
      type = "toggle",
      name = L["Auto-Clone (Show All Matches)"],
      order = 72,
      hidden = function() return not (trigger.type == "aura2" and not IsSingleMissing(trigger)) end,
      width = WeakAuras.doubleWidth,
      set = function(info, v)
        trigger.showClones = v
        WeakAuras.Add(data)
      end
    },
    combinePerUnit = {
      type = "toggle",
      name = L["Combine Matches Per Unit"],
      width = WeakAuras.doubleWidth,
      order = 72.2,
      hidden = function()
        return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and trigger.showClones)
      end
    },
    use_perUnitMode = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Matches for Units"],
      order = 72.3,
      hidden = function()
        return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and trigger.showClones and trigger.unit ~= "multi" and trigger.combinePerUnit)
      end,
      get = function() return true end,
      disabled = true
    },
    perUnitMode = {
      type = "select",
      name = L["Show Matches for"],
      values = OptionsPrivate.Private.bufftrigger_2_per_unit_mode,
      order = 72.4,
      width = WeakAuras.normalWidth,
      hidden = function()
        return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and trigger.showClones and trigger.unit ~= "multi" and trigger.combinePerUnit)
      end,
      get = function()
        return trigger.perUnitMode or "affected"
      end
    },
    use_combineMode = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Preferred Match"],
      order = 72.5,
      hidden = function()
        if (trigger.type == "aura2") then
          if (IsGroupTrigger(trigger)) then
            if trigger.showClones then
              return not (trigger.combinePerUnit and trigger.perUnitMode ~= "unaffected")
            else
              return false
            end
          else
            return not (not IsSingleMissing(trigger) and not trigger.showClones)
          end
        end
        return true
      end,
      get = function() return true end,
      disabled = true
    },
    combineMode = {
      type = "select",
      name = L["Preferred Match"],
      values = OptionsPrivate.Private.bufftrigger_2_preferred_match_types,
      order = 72.6,
      width = WeakAuras.normalWidth,
      hidden = function()
        if (trigger.type == "aura2") then
          if (IsGroupTrigger(trigger)) then
            if trigger.showClones then
              return not (trigger.combinePerUnit and trigger.perUnitMode ~= "unaffected")
            else
              return false
            end
          else
            return not (not IsSingleMissing(trigger) and not trigger.showClones)
          end
        end
        return true
      end,
      get = function()
        return trigger.combineMode or "showLowest"
      end
    },
    unitExists = {
      type = "toggle",
      name = L["Show If Unit Does Not Exist"],
      width = WeakAuras.doubleWidth,
      order = 73,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "player" and not IsGroupTrigger(trigger))
      end,
    },
  }

  -- Names
  local nameOptionSize = CountNames(data, triggernum, "auranames") + 1
  local spellOptionsSize = CountNames(data, triggernum, "auraspellids") + 1
  local ignoreNameOptionSize = CountNames(data, triggernum, "ignoreAuraNames") + 1
  local ignoreSpellOptionsSize = CountNames(data, triggernum, "ignoreAuraSpellids") + 1

  CreateNameOptions(aura_options, data, trigger, nameOptionSize,
                    false, false, "name", 12, "useName", "auranames",
                    L["Aura Name"],
                    L["Enter an Aura Name, partial Aura Name, or Spell ID. A Spell ID will match any spells with the same name."],
                    IsSingleMissing(trigger))


  CreateNameOptions(aura_options, data, trigger, spellOptionsSize,
                    true, false, "spellid", 22, "useExactSpellId", "auraspellids",
                    L["Spell ID"], L["Enter a Spell ID. You can use the addon idTip to determine spell ids."],
                    IsSingleMissing(trigger))

  CreateNameOptions(aura_options, data, trigger, ignoreNameOptionSize,
                    false, true, "ignorename", 32, "useIgnoreName", "ignoreAuraNames",
                    L["Ignored Aura Name"],
                    L["Enter an Aura Name, partial Aura Name, or Spell ID. A Spell ID will match any spells with the same name."],
                    IsSingleMissing(trigger))

  CreateNameOptions(aura_options, data, trigger, ignoreSpellOptionsSize,
                    true, true, "ignorespellid", 42, "useIgnoreExactSpellId", "ignoreAuraSpellids",
                    L["Ignored Spell ID"], L["Enter a Spell ID. You can use the addon idTip to determine spell ids."],
                    IsSingleMissing(trigger))

  OptionsPrivate.commonOptions.AddCommonTriggerOptions(aura_options, data, triggernum, true)
  OptionsPrivate.commonOptions.AddTriggerGetterSetter(aura_options, data, triggernum)
  OptionsPrivate.AddTriggerMetaFunctions(aura_options, data, triggernum)


  return {
    ["trigger." .. triggernum .. ".aura_options"] = aura_options
  }
end

WeakAuras.RegisterTriggerSystemOptions({"aura2"}, GetBuffTriggerOptions)
