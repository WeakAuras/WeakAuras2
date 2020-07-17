if not WeakAuras.IsCorrectVersion() then return end

local L = WeakAuras.L

local operator_types = WeakAuras.operator_types
local debuff_types = WeakAuras.debuff_types

local function getAuraMatchesLabel(name)
  local ids = WeakAuras.spellCache.GetSpellsMatching(name)
  if ids then
    local numMatches = 0
    for id, _ in pairs(ids) do
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
      local name, _, icon = GetSpellInfo(id)
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

local function CreateNameOptions(aura_options, data, trigger, size, isExactSpellId, isIgnoreList, prefix, baseOrder, useKey, optionKey, name, desc)
  local spellCache = WeakAuras.spellCache

  for i = 1, size do
    local hiddenFunction
    if isIgnoreList then
      hiddenFunction = function()
        return not (trigger.type == "aura2" and trigger[useKey] and (i == 1 or trigger[optionKey] and trigger[optionKey][i - 1]) and trigger.unit ~= "multi" and not IsSingleMissing(trigger))
      end
    else
      hiddenFunction = function()
        return not (trigger.type == "aura2" and trigger[useKey] and (i == 1 or trigger[optionKey] and trigger[optionKey][i - 1]))
      end
    end

    if i ~= 1 then
      aura_options[prefix .. "space" .. i] = {
        type = "execute",
        name = L["or"],
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
      hidden = hiddenFunction
    }

    if isExactSpellId then
      aura_options[iconOption].name = ""
      aura_options[iconOption].desc = function()
        local name = GetSpellInfo(trigger[optionKey] and trigger[optionKey][i])
        return name
      end
      aura_options[iconOption].image = function()
        local icon = select(3, GetSpellInfo(trigger.auraspellids and trigger.auraspellids[i]))
        return icon and tostring(icon) or "", 18, 18
      end
      aura_options[iconOption].disabled = function()
        return not trigger[optionKey] or not trigger[optionKey][i] or not select(3, GetSpellInfo(trigger[optionKey] and trigger[optionKey][i]))
      end
    else
      aura_options[iconOption].name = function()
        local spellId = trigger[optionKey] and trigger[optionKey][i] and WeakAuras.SafeToNumber(trigger[optionKey][i])
        if spellId then
          return getAuraMatchesLabel(GetSpellInfo(spellId))
        else
          return getAuraMatchesLabel(trigger[optionKey] and trigger[optionKey][i])
        end
      end

      aura_options[iconOption].desc = function()
        local spellId = trigger[optionKey] and trigger[optionKey][i] and WeakAuras.SafeToNumber(trigger[optionKey][i])
        if spellId then
          local name = GetSpellInfo(spellId)
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
          icon = select(3, GetSpellInfo(spellId))
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
      get = function(info) return trigger[optionKey] and trigger[optionKey][i] end,
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
        WeakAuras.UpdateDisplayButton(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end,
      validate = isExactSpellId and WeakAuras.ValidateNumeric or nil
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

  local ValidateNumeric = WeakAuras.ValidateNumeric
  local aura_options = {
    useUnit = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Unit"],
      order = 10,
      disabled = true,
      hidden = function() return not trigger.type == "aura2" end,
      get = function() return true end
    },
    unit = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Unit"],
      order = 10.1,
      values = function()
        return WeakAuras.unit_types_bufftrigger_2
      end,
      hidden = function() return not trigger.type == "aura2" end
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
    useDebuffType = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Aura Type"],
      order = 11,
      disabled = true,
      hidden = function() return not trigger.type == "aura2" end,
      get = function() return true end
    },
    debuffType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Aura Type"],
      order = 11.1,
      values = debuff_types,
      hidden = function() return not trigger.type == "aura2" end
    },
    use_debuffClass = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Debuff Type"],
      order = 11.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end
    },
    debuffClass = {
      type = "multiselect",
      width = WeakAuras.normalWidth,
      name = L["Debuff Type"],
      order = 11.3,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "multi"
          and not IsSingleMissing(trigger)
          and trigger.use_debuffClass)
      end,
      values = WeakAuras.debuff_class_types,
    },
    debuffClassSpace = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 11.4,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "multi"
          and not IsSingleMissing(trigger)
          and not trigger.use_debuffClass)
      end
    },
    useName = {
      type = "toggle",
      name = L["Name(s)"],
      order = 12,
      width = WeakAuras.normalWidth - 0.2,
      hidden = function() return not trigger.type == "aura2" end
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
      hidden = function() return not trigger.type == "aura2" end
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
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end
    },
    useIgnoreNameSpace = {
      type = "description",
      name = "",
      order = 32.1,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and not trigger.useIgnoreName and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end
    },
    useIgnoreExactSpellId = {
      type = "toggle",
      name = L["Ignored Exact Spell ID(s)"],
      width = WeakAuras.normalWidth - 0.2,
      order = 42,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end
    },
    useIgnoreExactSpellIddSpace = {
      type = "description",
      name = "",
      order = 42.1,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and not trigger.useIgnoreExactSpellId and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end
    },

    useNamePattern = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Name Pattern Match"],
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
      values = WeakAuras.string_operator_types
    },
    namePattern_name = {
      type = "input",
      name = L["Aura Name Pattern"],
      width = WeakAuras.doubleWidth,
      order = 55.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and trigger.useNamePattern) end
    },
    useStacks = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Stack Count"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end,
      order = 60
    },
    stacksOperator = {
      type = "select",
      name = L["Operator"],
      order = 60.1,
      width = WeakAuras.halfWidth,
      values = operator_types,
      disabled = function() return not trigger.useStacks end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useStacks) end,
      get = function() return trigger.useStacks and trigger.stacksOperator or nil end
    },
    stacks = {
      type = "input",
      name = L["Stack Count"],
      validate = ValidateNumeric,
      order = 60.2,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useStacks) end,
      get = function() return trigger.useStacks and trigger.stacks or nil end
    },
    useStacksSpace = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 60.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.useStacks) end
    },
    useRem = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Remaining Time"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end,
      order = 61
    },
    remOperator = {
      type = "select",
      name = L["Operator"],
      order = 61.1,
      width = WeakAuras.halfWidth,
      values = operator_types,
      disabled = function() return not trigger.useRem end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useRem) end,
      get = function() return trigger.useRem and trigger.remOperator or nil end
    },
    rem = {
      type = "input",
      name = L["Remaining Time"],
      validate = ValidateNumeric,
      order = 61.2,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useRem) end,
      get = function() return trigger.useRem and trigger.rem or nil end
    },
    useRemSpace = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 61.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.useRem) end
    },
    useTotal = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Total Time"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end,
      order = 61.4
    },
    totalOperator = {
      type = "select",
      name = L["Operator"],
      order = 61.5,
      width = WeakAuras.halfWidth,
      values = operator_types,
      disabled = function() return not trigger.useTotal end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useTotal) end,
      get = function() return trigger.useTotal and trigger.totalOperator or nil end
    },
    total = {
      type = "input",
      name = L["Total Time"],
      validate = ValidateNumeric,
      order = 61.6,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useTotal) end,
      get = function() return trigger.useTotal and trigger.total or nil end
    },
    useTotalSpace = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 61.7,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.useTotal) end
    },
    fetchTooltip = {
      type = "toggle",
      name = L["Use Tooltip Information"],
      desc = L["This adds %tooltip, %tooltip1, %tooltip2, %tooltip3 as text replacements."],
      order = 62,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end
    },
    use_tooltip = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip Pattern Match"],
      order = 62.1,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.fetchTooltip) end
    },
    use_tooltipSpace = {
      type = "description",
      name = "",
      order = 62.2,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.use_tooltip and trigger.fetchTooltip) end
    },
    tooltip_operator = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Operator"],
      order = 62.3,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.use_tooltip and trigger.fetchTooltip) end,
      values = WeakAuras.string_operator_types
    },
    tooltip = {
      type = "input",
      name = L["Tooltip Content"],
      width = WeakAuras.doubleWidth,
      order = 62.4,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.use_tooltip and trigger.fetchTooltip) end
    },
    use_tooltipValue = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip Value"],
      order = 63.1,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.fetchTooltip) end
    },
    tooltipValueNumber = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Tooltip Value #"],
      order = 63.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.use_tooltipValue and trigger.fetchTooltip) end,
      values = WeakAuras.tooltip_count
    },
    use_tooltipValueSpace = {
      type = "description",
      name = "",
      order = 63.2,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.use_tooltipValue and trigger.fetchTooltip) end
    },
    tooltipValue_operator = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Operator"],
      order = 63.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.use_tooltipValue and trigger.fetchTooltip) end,
      values = WeakAuras.operator_types
    },
    tooltipValue = {
      type = "input",
      name = L["Tooltip"],
      width = WeakAuras.normalWidth,
      validate = ValidateNumeric,
      order = 63.4,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.use_tooltipValue and trigger.fetchTooltip) end
    },
    use_stealable = {
      type = "toggle",
      name = function(input)
        local value = trigger.use_stealable
        if value == nil then return L["Is Stealable"]
        elseif value == false then return "|cFFFF0000 "..L["Negator"].." "..L["Is Stealable"]
        else return "|cFF00FF00"..L["Is Stealable"] end
      end,
      width = WeakAuras.doubleWidth,
      order = 64,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end,
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
    useAffected = {
      type = "toggle",
      name = L["Fetch Affected/Unaffected Names"],
      width = WeakAuras.doubleWidth,
      order = 65,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")) end
    },
    ownOnly = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = function()
        local value = trigger.ownOnly
        if value == nil then return L["Own Only"]
        elseif value == false then return "|cFFFF0000 "..L["Negator"].." "..L["Own Only"]
        else return "|cFF00FF00"..L["Own Only"] end
      end,
      desc = function()
        local value = trigger.ownOnly
        if value == nil then return L["Only match auras cast by the player or his pet"]
        elseif value == false then return L["Only match auras cast by people other than the player or his pet"]
        else return L["Only match auras cast by the player or his pet"] end
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
      order = 66,
      hidden = function() return not trigger.type == "aura2" end
    },
    useGroupRole = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Group Role"],
      order = 67.1,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"))
        or WeakAuras.IsClassic()
      end
    },
    group_role = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Group Role"],
      values = WeakAuras.role_types,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and trigger.useGroupRole) end,
      order = 67.2
    },
    group_roleSpace = {
      type = "description",
      name = "",
      order = 67.2,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and not trigger.useGroupRole) end
    },
    ignoreSelf = {
      type = "toggle",
      name = L["Ignore Self"],
      order = 67.3,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party" or trigger.unit == "nameplate")) end
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

    useHostility = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = WeakAuras.newFeatureString .. L["Filter by Nameplate Type"],
      order = 68.4,
      hidden = function() return
        not (trigger.type == "aura2" and trigger.unit == "nameplate")
      end
    },
    hostility = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Hostility"],
      values = WeakAuras.hostility_types,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "nameplate" and trigger.useHostility) end,
      order = 68.5
    },
    hostilitySpace = {
      type = "description",
      name = "",
      order = 68.6,
      width = WeakAuras.normalWidth,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "nameplate" and not trigger.useHostility) end
    },

    ignoreDead = {
      type = "toggle",
      name = WeakAuras.newFeatureString .. L["Ignore Dead"],
      order = 68.7,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")) end
    },

    ignoreDisconnected = {
      type = "toggle",
      name = WeakAuras.newFeatureString .. L["Ignore Disconnected"],
      order = 68.8,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")) end
    },
    ignoreInvisible = {
      type = "toggle",
      name = WeakAuras.newFeatureString .. L["Ignore out of checking range"],
      desc = L["Uses UnitIsVisible() to check if in range. This is polled every second."],
      order = 68.9,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party")) end
    },

    useUnitName = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["UnitName Filter"],
      order = 69.1,
      hidden = function() return
        not (trigger.type == "aura2" and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party"))
      end
    },
    unitName = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Unit Name Filter"],
      desc = L["Filter formats: 'Name', 'Name-Realm', '-Realm'.\n\nSupports multiple entries, separated by commas\n"],
      order = 69.2,
      hidden = function()
        return not (trigger.type == "aura2"
                    and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and trigger.useUnitName)
      end
    },
    unitNameSpace = {
      type = "description",
      name = "",
      order = 69.3,
      width = WeakAuras.normalWidth,
      hidden = function()
        return not (trigger.type == "aura2"
                    and (trigger.unit == "group" or trigger.unit == "raid" or trigger.unit == "party") and not trigger.useUnitName)
      end
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
          local groupType = WeakAuras.unit_types_bufftrigger_2[trigger.unit or "group"] or "|cFFFF0000Error|r"
          return L["Group aura count description"]:format(groupType, groupType, groupType, groupType, groupType, groupType, groupType)
        end
      end,
      order = 70.2,
      width = WeakAuras.halfWidth,
      values = operator_types,
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
          local groupType = WeakAuras.unit_types_bufftrigger_2[trigger.unit or "group"] or "|cFFFF0000Error|r"
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
      values = WeakAuras.bufftrigger_2_progress_behavior_types,
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
      values = operator_types,
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
      values = WeakAuras.bufftrigger_2_per_unit_mode,
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
      values = WeakAuras.bufftrigger_2_preferred_match_types,
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
                    L["Enter an Aura Name, partial Aura Name, or Spell ID. A Spell ID will match any spells with the same name."])


  CreateNameOptions(aura_options, data, trigger, spellOptionsSize,
                    true, false, "spellid", 22, "useExactSpellId", "auraspellids",
                    L["Spell ID"], L["Enter a Spell ID"])

  CreateNameOptions(aura_options, data, trigger, ignoreNameOptionSize,
                    false, true, "ignorename", 32, "useIgnoreName", "ignoreAuraNames",
                    L["Ignored Aura Name"],
                    L["Enter an Aura Name, partial Aura Name, or Spell ID. A Spell ID will match any spells with the same name."])

  CreateNameOptions(aura_options, data, trigger, ignoreSpellOptionsSize,
                    true, true, "ignorespellid", 42, "useIgnoreExactSpellId", "ignoreAuraSpellids",
                    L["Ignored Spell ID"], L["Enter a Spell ID"])

  WeakAuras.commonOptions.AddCommonTriggerOptions(aura_options, data, triggernum)
  WeakAuras.commonOptions.AddTriggerGetterSetter(aura_options, data, triggernum)
  WeakAuras.AddTriggerMetaFunctions(aura_options, data, triggernum)


  return {
    ["trigger." .. triggernum .. ".aura_options"] = aura_options
  }
end

WeakAuras.RegisterTriggerSystemOptions({"aura2"}, GetBuffTriggerOptions)
