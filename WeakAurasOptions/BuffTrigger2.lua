local L = WeakAuras.L

local operator_types = WeakAuras.operator_types
local debuff_types = WeakAuras.debuff_types

local function GetAuraMatchesLabel(name)
  local iconCache = WeakAuras.spellCache.Get()
  local ids = iconCache[name]
  if ids then
    local descText = ""
    local numMatches = 0
    for id, _ in pairs(ids) do
      numMatches = numMatches + 1
    end
    return tostring(numMatches)
  else
    return ""
  end
end

local function GetAuraMatchesList(name)
  local iconCache = WeakAuras.spellCache.Get()
  local ids = iconCache[name]
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

local function ShiftTable(tbl, pos)
  for i = pos, 9, 1 do
    tbl[i] = tbl[i + 1]
  end
end

local function GetBuffTriggerOptions(data, optionTriggerChoices)
  local trigger
  if not data.controlledChildren then
    local triggernum = optionTriggerChoices[data.id]
    if triggernum then
      trigger = data.triggers[triggernum].trigger
    end
  end

  local function IsGroupTrigger(trigger)
    return trigger.unit == "group" or trigger.unit == "boss" or trigger.unit == "nameplate" or trigger.unit == "arena" or trigger.unit == "multi"
  end

  local function IsSingleMissing(trigger)
    return not IsGroupTrigger(trigger) and trigger.matchShowOn == "showOnMissing";
  end

  local function HasMatchCount(trigger)
    if IsGroupTrigger(trigger) then
      return trigger.useMatchCount
    else
      return trigger.matchShowOn == "showOnMatches"
    end
  end

  local spellCache = WeakAuras.spellCache
  local ValidateNumeric = WeakAuras.ValidateNumeric
  local aura_options = {
    useUnit = {
      type = "toggle",
      name = L["Unit"],
      order = 10,
      disabled = true,
      hidden = function() return not trigger.type == "aura2" end,
      get = function() return true end
    },
    unit = {
      type = "select",
      name = L["Unit"],
      order = 10.1,
      values = function()
        return WeakAuras.unit_types_bufftrigger_2
      end,
      hidden = function() return not trigger.type == "aura2" end
    },
    useSpecificUnit = {
      type = "toggle",
      name = L["Specific Unit"],
      order = 10.2,
      disabled = true,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "member") end,
      get = function() return true end
    },
    specificUnit = {
      type = "input",
      name = L["Specific Unit"],
      order = 10.3,
      desc = L["Can be a Name or a Unit ID (e.g. party1). A name only works on friendly players in your group."],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "member") end
    },
    useDebuffType = {
      type = "toggle",
      name = L["Aura Type"],
      order = 11,
      disabled = true,
      hidden = function() return not trigger.type == "aura2" end,
      get = function() return true end
    },
    debuffType = {
      type = "select",
      name = L["Aura Type"],
      order = 11.1,
      values = debuff_types,
      hidden = function() return not trigger.type == "aura2" end
    },
    useDebuffClass = {
      type = "toggle",
      name = L["Debuff Type"],
      order = 11.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.debuffType == "HARMFUL") end
    },
    debuffClass = {
      type = "select",
      name = L["Debuff Type"],
      order = 11.3,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "multi"
          and not IsSingleMissing(trigger)
          and trigger.debuffType == "HARMFUL"
          and trigger.useDebuffClass)
      end,
      values = WeakAuras.debuff_class_types
    },
    debuffClassSpace = {
      type = "description",
      name = "",
      order = 11.4,
      width = "normal",
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "multi"
          and not IsSingleMissing(trigger)
          and trigger.debuffType == "HARMFUL"
          and not trigger.useDebuffClass)
      end
    },
    useName = {
      type = "toggle",
      name = L["Name(s)"],
      order = 12,
      width = 0.8,
      hidden = function() return not trigger.type == "aura2" end
    },
    useNameSpace = {
      type = "description",
      name = "",
      order = 12.1,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and not trigger.useName) end
    },
    useExactSpellId = {
      type = "toggle",
      name = L["Exact Spell ID(s)"],
      width = 0.8,
      order = 22,
      hidden = function() return not trigger.type == "aura2" end
    },
    useExactSpellIdSpace = {
      type = "description",
      name = "",
      order = 22.1,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and not trigger.useExactSpellId) end
    },
    useNamePattern = {
      type = "toggle",
      name = L["Name Pattern Match"],
      order = 25,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi") end
    },
    useNamePatternSpace = {
      type = "description",
      name = "",
      order = 25.2,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not trigger.useNamePattern) end
    },
    namePattern_operator = {
      type = "select",
      name = L["Operator"],
      order = 25.1,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and trigger.useNamePattern) end,
      values = WeakAuras.string_operator_types
    },
    namePattern_name = {
      type = "input",
      name = L["Aura Name Pattern"],
      width = "double",
      order = 25.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and trigger.useNamePattern) end
    },
    useStacks = {
      type = "toggle",
      name = L["Stack Count"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end,
      order = 60
    },
    stacksOperator = {
      type = "select",
      name = L["Operator"],
      order = 60.1,
      width = "half",
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
      width = "half",
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useStacks) end,
      get = function() return trigger.useStacks and trigger.stacks or nil end
    },
    useStacksSpace = {
      type = "description",
      name = "",
      order = 60.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.useStacks) end
    },
    useRem = {
      type = "toggle",
      name = L["Remaining Time"],
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end,
      order = 61
    },
    remOperator = {
      type = "select",
      name = L["Operator"],
      order = 61.1,
      width = "half",
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
      width = "half",
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useRem) end,
      get = function() return trigger.useRem and trigger.rem or nil end
    },
    useRemSpace = {
      type = "description",
      name = "",
      order = 61.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.useRem) end
    },
    fetchTooltip = {
      type = "toggle",
      name = L["Use Tooltip Information"],
      desc = L["This adds %tooltip, %tooltip1, %tooltip2, %tooltip3 as text replacements."],
      order = 62,
      width = "double",
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end
    },
    useTooltip = {
      type = "toggle",
      name = L["Tooltip Pattern Mach"],
      order = 62.1,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.fetchTooltip) end
    },
    useTooltipSpace = {
      type = "description",
      name = "",
      order = 62.2,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.useTooltip and trigger.fetchTooltip) end
    },
    tooltipOperator = {
      type = "select",
      name = L["Operator"],
      order = 62.3,
      disabled = function() return not trigger.useTooltip end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useTooltip and trigger.fetchTooltip) end,
      values = WeakAuras.string_operator_types
    },
    tooltip = {
      type = "input",
      name = L["Tooltip Content"],
      width = "double",
      order = 62.4,
      disabled = function() return not trigger.useTooltip end,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useTooltip and trigger.fetchTooltip) end
    },
    useTooltipValue = {
      type = "toggle",
      name = L["Tooltip Value"],
      order = 63.1,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.fetchTooltip) end
    },
    tooltipValueNumber = {
      type = "select",
      name = L["Tooltip Value #"],
      order = 63.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useTooltipValue and trigger.fetchTooltip) end,
      values = WeakAuras.tooltipCount
    },
    useTooltipValueSpace = {
      type = "description",
      name = "",
      order = 63.2,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and not trigger.useTooltipValue and trigger.fetchTooltip) end
    },
    tooltipValueOperator = {
      type = "select",
      name = L["Operator"],
      order = 63.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useTooltipValue and trigger.fetchTooltip) end,
      values = WeakAuras.operator_types
    },
    tooltipValue = {
      type = "input",
      name = L["Tooltip"],
      width = "normal",
      validate = ValidateNumeric,
      order = 63.4,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useTooltipValue and trigger.fetchTooltip) end
    },
    useStealable = {
      type = "toggle",
      name = function(input)
        local value = trigger.useStealable
        if value == nil then return L["Is Stealable"]
        elseif value == false then return "|cFFFF0000 "..L["Negator"].." "..L["Is Stealable"]
        else return "|cFF00FF00"..L["Is Stealable"] end
      end,
      width = "double",
      order = 64,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit ~= "multi" and not IsSingleMissing(trigger)) end,
      get = function()
        local value = trigger.useStealable
        if value == nil then return false
        elseif value == false then return "false"
        else return "true" end
      end,
      set = function(info, v)
        if v then
          trigger.useStealable = true
        else
          local value = trigger.useStealable
          if value == false then trigger.useStealable = nil
          else trigger.useStealable = false end
        end
        WeakAuras.Add(data)
        WeakAuras.SetIconNames(data)
      end
    },
    useAffected = {
      type = "toggle",
      name = L["Fetch Unit Names"],
      width = "double",
      order = 65,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "group") end
    },
    useOwnOnly = {
      type = "toggle",
      width = "double",
      name = function()
        local value = trigger.useOwnOnly
        if value == nil then return L["Own Only"]
        elseif value == false then return "|cFFFF0000 "..L["Negator"].." "..L["Own Only"]
        else return "|cFF00FF00"..L["Own Only"] end
      end,
      desc = function()
        local value = trigger.useOwnOnly
        if value == nil then return L["Only match auras cast by the player"]
        elseif value == false then return L["Only match auras cast by people other than the player"]
        else return L["Only match auras cast by the player"] end
      end,
      get = function()
        local value = trigger.useOwnOnly
        if value == nil then return false
        elseif value == false then return "false"
        else return "true" end
      end,
      set = function(info, v)
        if v then
          trigger.useOwnOnly = true
        else
          local value = trigger.useOwnOnly
          if value == false then trigger.useOwnOnly = nil
          else trigger.useOwnOnly = false end
        end
        WeakAuras.Add(data)
      end,
      order = 66,
      hidden = function() return not trigger.type == "aura2" end
    },
    useGroupRole = {
      type = "toggle",
      name = L["Filter by Group Role"],
      order = 67.1,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "group") end
    },
    groupRole = {
      type = "select",
      name = L["Group Role"],
      values = WeakAuras.role_types,
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "group" and trigger.useGroupRole) end,
      order = 67.2
    },
    groupRoleSpace = {
      type = "description",
      name = "",
      order = 67.2,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "group"and not trigger.useGroupRole) end
    },
    useIgnoreSelf = {
      type = "toggle",
      name = L["Ignore Self"],
      order = 67.3,
      width = "double",
      hidden = function() return not (trigger.type == "aura2" and trigger.unit == "group") end
    },
    useGroupCount = {
      type = "toggle",
      name = L["Group Member Count"],
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger)) end,
      order = 68
    },
    useGroupCountSpace = {
      type = "description",
      name = "",
      order = 68.1,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and not trigger.useGroupCount) end
    },
    groupCountOperator = {
      type = "select",
      name = L["Operator"],
      order = 68.2,
      width = "half",
      values = operator_types,
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and trigger.useGroupCount) end,
      get = function() return trigger.groupCountOperator end
    },
    groupCount = {
      type = "input",
      name = L["Count"],
      desc = function()
        local groupType = WeakAuras.unit_types_bufftrigger_2[trigger.unit or "group"] or "|cFFFF0000Error|r"
        return L["Group Aura Count Description"]:format(groupType, groupType, groupType, groupType, groupType, groupType, groupType)
      end,
      order = 68.3,
      width = "half",
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and trigger.useGroupCount) end,
    },
    useMatchShowOn = {
      type = "toggle",
      name = L["Show On"],
      order = 71,
      hidden = function() return not (trigger.type == "aura2" and not IsGroupTrigger(trigger)) end,
      get = function() return true end,
      disabled = true
    },
    matchShowOn = {
      type = "select",
      name = L["Show On"],
      values = WeakAuras.bufftrigger_2_progress_behavior_types,
      order = 71.1,
      hidden = function() return not (trigger.type == "aura2" and not IsGroupTrigger(trigger)) end,
      get = function()
        return trigger.matchShowOn or "showOnActive"
      end
    },
    useMatchCount = {
      type = "toggle",
      name = L["Match Count"],
      hidden = function() return not (trigger.type == "aura2" and IsGroupTrigger(trigger)) end,
      order = 71.2
    },
    useMatchCountSpace = {
      type = "description",
      name = "",
      order = 71.3,
      width = "normal",
      hidden = function()
        if trigger.type ~= "aura2" then
          return true;
        end
        if IsGroupTrigger(trigger) then
          return trigger.useMatchCount
        else
          return trigger.matchShowOn == "matchShowOn"
        end
      end
    },
    matchCountOperator = {
      type = "select",
      name = L["Operator"],
      order = 71.4,
      width = "half",
      values = operator_types,
      hidden = function() return not (trigger.type == "aura2" and HasMatchCount(trigger)) end,
    },
    matchCount = {
      type = "input",
      name = L["Count"],
      order = 71.5,
      width = "half",
      hidden = function() return not (trigger.type == "aura2" and HasMatchCount(trigger)) end,
      validate = ValidateNumeric
    },
    showClones = {
      type = "toggle",
      name = L["Auto-Clone (Show All Matches)"],
      order = 72,
      hidden = function() return not (trigger.type == "aura2" and not IsSingleMissing(trigger)) end,
      width = "double",
      set = function(info, v)
        trigger.showClones = v
        if v == true then
          WeakAuras.UpdateCloneConfig(data)
        else
          WeakAuras.CollapseAllClones(data.id)
        end
        WeakAuras.Add(data)
      end
    },
    combinePerUnit = {
      type = "toggle",
      name = L["Combine Matches Per Unit"],
      width = "double",
      order = 72.2,
      hidden = function()
        return not (trigger.type == "aura2" and IsGroupTrigger(trigger) and trigger.showClones and trigger.unit ~= "multi")
      end
    },
    useCombineMode = {
      type = "toggle",
      name = L["Preferred Match"],
      order = 72.3,
      hidden = function()
        return not (trigger.type == "aura2" and not IsSingleMissing(trigger) and (IsGroupTrigger(trigger) and trigger.combinePerUnit or not trigger.showClones))
      end,
      get = function() return true end,
      disabled = true
    },
    combineMode = {
      type = "select",
      name = L["Preferred Match"],
      values = WeakAuras.bufftrigger_2_preferred_match_types,
      order = 72.4,
      width = "normal",
      hidden = function()
        return not (trigger.type == "aura2" and not IsSingleMissing(trigger) and (IsGroupTrigger(trigger) and trigger.combinePerUnit or not trigger.showClones))
      end,
      get = function()
        return trigger.combineMode or "showLowest"
      end
    },
    unitExists = {
      type = "toggle",
      name = L["Show If Unit Is Invalid"],
      order = 73,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "player" and not IsGroupTrigger(trigger))
      end
    },
  }

  -- Names
  for i = 1, 9 do
    if i ~= 1 then
      aura_options["namespace" .. i] = {
        type = "execute",
        name = L["or"],
        width = 0.8,
        image = function() return "", 0, 0 end,
        order = i + 11.1,
        hidden = function() return not (trigger.type == "aura2" and trigger.useName and trigger.auranames and trigger.auranames[i - 1]) end
      }
    end

    aura_options["nameicon" .. i] = {
      type = "execute",
      name = function()
        local spellId = trigger.auranames and trigger.auranames[i] and tonumber(trigger.auranames[i]);
        if spellId then
          return GetAuraMatchesLabel(GetSpellInfo(trigger.auraspellids and trigger.auraspellids[i]))
        else
          return GetAuraMatchesLabel(trigger.auranames and trigger.auranames[i])
        end
      end,
      desc = function()
        local spellId = trigger.auranames and trigger.auranames[i] and tonumber(trigger.auranames[i]);
        if spellId then
          local name = GetSpellInfo(spellId)
          if name then
            local auraDesc = GetAuraMatchesList(name)
            if auraDesc then
              auraDesc = name .. "\n" .. auraDesc
            end
            return auraDesc
          end
        else
          return GetAuraMatchesList(trigger.auranames and trigger.auranames[i])
        end
      end,
      width = 0.2,
      image = function()
        local icon;
        local spellId = trigger.auranames and trigger.auranames[i] and tonumber(trigger.auranames[i]);
        if spellId then
          icon = select(3, GetSpellInfo(spellId));
        else
          icon = spellCache.GetIcon(trigger.auranames and trigger.auranames[i])
        end
        return icon and tostring(icon) or "", 18, 18
      end,
      order = i + 11.2,
      hidden = function() return not (trigger.type == "aura2" and trigger.useName and (i == 1 or trigger.auranames and trigger.auranames[i - 1])) end
    }

    aura_options["name" .. i] = {
      type = "input",
      name = L["Aura Name"],
      desc = L["Enter an Aura Name, partial Aura Name, or Spell ID. A Spell ID will match any spells with the same name."],
      order = i + 11.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.useName and (i == 1 or trigger.auranames and trigger.auranames[i - 1])) end,
      get = function(info) return trigger.auranames and trigger.auranames[i] end,
      set = function(info, v)
        trigger.auranames = trigger.auranames or {}
        if v == "" then
          ShiftTable(trigger.auranames, i)
        else
          local spellId = tonumber(v)
          if spellId then
            WeakAuras.spellCache.CorrectAuraName(v)
            trigger.auranames[i] = v
          else
            trigger.auranames[i] = spellCache.BestKeyMatch(v)
          end
        end

        WeakAuras.Add(data)
        WeakAuras.SetThumbnail(data)
        WeakAuras.SetIconNames(data)
        WeakAuras.UpdateDisplayButton(data)
      end
    }
  end
  -- Exact Spell IDs
  for i = 1, 9 do
    if i ~= 1 then
      aura_options["spellidspace" .. i] = {
        type = "execute",
        name = L["or"],
        width = 0.8,
        image = function() return "", 0, 0 end,
        order = i + 21.1,
        hidden = function() return not (trigger.type == "aura2" and trigger.useExactSpellId and trigger.auraspellids and trigger.auraspellids[i - 1]) end
      }
    end

    aura_options["spellidicon" .. i] = {
      type = "execute",
      name = function()
        return " ";
      end,
      desc = function()
        local name = GetSpellInfo(trigger.auraspellids and trigger.auraspellids[i])
        return name;
      end,
      width = 0.2,
      image = function()
        local icon = select(3, GetSpellInfo(trigger.auraspellids and trigger.auraspellids[i]))
        return icon and tostring(icon) or "", 18, 18
      end,
      order = i + 21.2,
      disabled = function() return not trigger.auraspellids or not trigger.auraspellids[i] or not select(3, GetSpellInfo(trigger.auraspellids and trigger.auraspellids[i])) end,
      hidden = function() return not (trigger.type == "aura2" and trigger.useExactSpellId and (i == 1 or trigger.auraspellids and trigger.auraspellids[i - 1])) end
    }

    aura_options["spellid" .. i] = {
      type = "input",
      name = L["Spell ID"],
      desc = L["Enter a Spell ID"],
      order = i + 21.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.useExactSpellId and (i == 1 or trigger.auraspellids and trigger.auraspellids[i - 1])) end,
      get = function(info) return trigger.auraspellids and trigger.auraspellids[i] end,
      set = function(info, v)
        trigger.auraspellids = trigger.auraspellids or {}
        if v == "" then
          ShiftTable(trigger.auraspellids, i)
        else
          trigger.auraspellids[i] = v
        end
        WeakAuras.Add(data)
        WeakAuras.SetThumbnail(data)
        WeakAuras.SetIconNames(data)
        WeakAuras.UpdateDisplayButton(data)
      end,
      validate = ValidateNumeric
    }
  end

  return aura_options
end

WeakAuras.RegisterTriggerSystemOptions({"aura2"}, GetBuffTriggerOptions)
