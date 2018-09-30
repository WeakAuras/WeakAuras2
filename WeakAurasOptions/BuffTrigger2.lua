local L = WeakAuras.L;

local operator_types = WeakAuras.operator_types;
local debuff_types = WeakAuras.debuff_types;
local tooltip_count = WeakAuras.tooltip_count;
local unit_types = WeakAuras.unit_types;
local actual_unit_types_with_specific = WeakAuras.actual_unit_types_with_specific;
local group_aura_name_info_types = WeakAuras.group_aura_name_info_types;
local group_aura_stack_info_types = WeakAuras.group_aura_stack_info_types;

local function getAuraMatchesLabel(name)
  local iconCache = WeakAuras.spellCache.Get();
  local ids = iconCache[name]
  if(ids) then
    local descText = "";
    local numMatches = 0;
    for id, _ in pairs(ids) do
      numMatches = numMatches + 1;
    end
    return tostring(numMatches);
  else
    return "";
  end
end

local function getAuraMatchesList(name)
  local iconCache = WeakAuras.spellCache.Get();
  local ids = iconCache[name]
  if(ids) then
    local descText = "";
    for id, _ in pairs(ids) do
      local name, _, icon = GetSpellInfo(id);
      if(icon) then
        if(descText == "") then
          descText = "|T"..icon..":0|t: "..id;
        else
          descText = descText.."\n|T"..icon..":0|t: "..id;
        end
      end
    end
    return descText;
  else
    return "";
  end
end

local function shiftTable(tbl, pos)
  for i = pos, 9, 1 do
    tbl[i] = tbl[i + 1]
  end
end

local function GetBuffTriggerOptions(data, optionTriggerChoices)
  local trigger;
  if (not data.controlledChildren) then
    local triggernum = optionTriggerChoices[data.id];
    if (triggernum) then
      trigger = data.triggers[triggernum].trigger;
    end
  end

  -- TODO LIST, aka what's missing?
  -- fullscan
  --   aura names: IsExactly/Contains/Pattern Matching for
  --    match on tooltip:
  --    tooltip size

  -- multi trigger
  -- * This should use the same match data, with less data and auto hiding
  -- * Might not work
  -- Specific Unit
  -- * Be better than the old one and try to detect when the specific unit changed
  -- * E.g. watch their GUID ? On UNIT_AURA changes, check if the GUID matches any watched specific unit and update it too
  -- Group:
  --   * scanFuncs are per unit type (?)
  --   * ScanUnit takes a specific unit, so raidX
  --   * No need to scan all auras when one unit changes
  --   group member count
  --   * match data for all units is in UpdateTriggerState, so should be easier to do
  --   group role, ignore self
  --   * Check group role / ignore self can be decided before iteration, by checking the unit
  --   name info of group triggers
  --   stack info of group triggers
  --   * Offer both options for name/stack as state "functions". Needs a bit of extensions of states and text replacements
  ---  * Needs a bit of design work
  --   hide alone
  --   * Meta data for scanFunc
  -- The biggest unaswered question is how to best store the scanFuncs so that we can easily figure out which scanFuncs to call.

  local function effectiveShowOnIsShowOnActive(trigger)
    local effectiveShowOn = true;
    if (trigger.matchesShowOn) then
      effectiveShowOn = trigger.matchesShowOn == "showOnActive";
    end
    return effectiveShowOn;
  end

  local spellCache = WeakAuras.spellCache;
  local ValidateNumeric = WeakAuras.ValidateNumeric;
  local aura_options = {
    useUnit = {
      type = "toggle",
      name = L["Unit"],
      order = 10,
      disabled = true,
      hidden = function() return not (trigger.type == "aura2"); end,
      get = function() return true end
    },
    unit = {
      type = "select",
      name = L["Unit"],
      order = 10.1,
      values = function()
        return WeakAuras.actual_unit_types;
      end,
      hidden = function() return not (trigger.type == "aura2"); end,
    },
    useDebuffType = {
      type = "toggle",
      name = L["Aura Type"],
      order = 11,
      disabled = true,
      hidden = function() return not (trigger.type == "aura2"); end,
      get = function() return true end
    },
    debuffType = {
      type = "select",
      name = L["Aura Type"],
      order = 11.1,
      values = debuff_types,
      hidden = function() return not (trigger.type == "aura2"); end
    },

    -- Name/Exact Spell ID options added below
    useName = {
      type = "toggle",
      name = L["Name"],
      order = 12,
      width = 0.8,
      hidden = function() return not (trigger.type == "aura2"); end,
    },
    useNameSpace = {
      type = "description",
      name = "",
      order = 12.1,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and not trigger.useName); end,
    },
    useExactSpellId = {
      type = "toggle",
      name = L["Exact Spell Id"],
      width = 0.8,
      order = 22,
      hidden = function() return not (trigger.type == "aura2"); end,
    },
    useExactSpellIdSpace = {
      type = "description",
      name = "",
      order = 22.1,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and not trigger.useExactSpellId); end,
    },
    useStacks = {
      type = "toggle",
      name = L["Stack Count"],
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end,
      order = 60
    },
    stacksOperator = {
      type = "select",
      name = L["Operator"],
      order = 60.1,
      width = "half",
      values = operator_types,
      disabled = function() return not trigger.useStacks; end,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end,
      get = function() return trigger.useStacks and trigger.stacksOperator or nil end
    },
    stacks = {
      type = "input",
      name = L["Stack Count"],
      validate = ValidateNumeric,
      order = 60.2,
      width = "half",
      disabled = function() return not trigger.useStacks; end,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end,
      get = function() return trigger.useStacks and trigger.stacks or nil end
    },
    useRem = {
      type = "toggle",
      name = L["Remaining Time"],
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end,
      order = 61
    },
    remOperator = {
      type = "select",
      name = L["Operator"],
      order = 61.1,
      width = "half",
      values = operator_types,
      disabled = function() return not trigger.useRem; end,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end,
      get = function() return trigger.useRem and trigger.remOperator or nil end
    },
    rem = {
      type = "input",
      name = L["Remaining Time"],
      validate = ValidateNumeric,
      order = 61.2,
      width = "half",
      disabled = function() return not trigger.useRem; end,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end,
      get = function() return trigger.useRem and trigger.rem or nil end
    },
    use_tooltip = {
      type = "toggle",
      name = L["Tooltip"],
      order = 62,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end
    },
    use_tooltipSpace = {
      type = "description",
      name = "",
      order = 62.1,
      width = "normal",
      hidden = function() return not (trigger.type == "aura2" and not trigger.use_tooltip); end,
    },
    tooltip_operator = {
      type = "select",
      name = L["Operator"],
      order = 62.2,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger) and trigger.use_tooltip); end,
      values = WeakAuras.string_operator_types
    },
    tooltip = {
      type = "input",
      name = L["Tooltip"],
      width = "double",
      order = 62.3,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger) and trigger.use_tooltip); end
    },
    use_stealable = {
      type = "toggle",
      name = function(input)
        local value = trigger.use_stealable;
        if(value == nil) then return L["Stealable"];
        elseif(value == false) then return "|cFFFF0000 "..L["Negator"].." "..L["Stealable"];
        else return "|cFF00FF00"..L["Stealable"]; end
      end,
      width = "double",
      order = 63,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end,
      get = function()
        local value = trigger.use_stealable;
        if(value == nil) then return false;
        elseif(value == false) then return "false";
        else return "true"; end
      end,
      set = function(info, v)
        if(v) then
          trigger.use_stealable = true;
        else
          local value = trigger.use_stealable;
          if(value == false) then trigger.use_stealable = nil;
          else trigger.use_stealable = false end
        end
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
      end
    },
    use_debuffClass = {
      type = "toggle",
      name = L["Debuff Type"],
      order = 64.1,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end
    },
    debuffClass = {
      type = "select",
      name = L["Debuff Type"],
      order = 64.2,
      disabled = function() return not trigger.use_debuffClass end,
      hidden = function() return not (trigger.type == "aura2" and effectiveShowOnIsShowOnActive(trigger)); end,
      values = WeakAuras.debuff_class_types
    },
    ownOnly = {
      type = "toggle",
      width = "double",
      name = function()
        local value = trigger.ownOnly;
        if(value == nil) then return L["Own Only"];
        elseif(value == false) then return "|cFFFF0000 "..L["Negator"].." "..L["Own Only"];
        else return "|cFF00FF00"..L["Own Only"]; end
      end,
      desc = function()
        local value = trigger.ownOnly;
        if(value == nil) then return L["Only match auras cast by the player"];
        elseif(value == false) then return L["Only match auras cast by people other than the player"];
        else return L["Only match auras cast by the player"]; end
      end,
      get = function()
        local value = trigger.ownOnly;
        if(value == nil) then return false;
        elseif(value == false) then return "false";
        else return "true"; end
      end,
      set = function(info, v)
        if(v) then
          trigger.ownOnly = true;
        else
          local value = trigger.ownOnly;
          if(value == false) then trigger.ownOnly = nil;
          else trigger.ownOnly = false end
        end
        WeakAuras.Add(data);
      end,
      order = 70,
      hidden = function() return not (trigger.type == "aura2"); end
    },
    matchesShowOn = {
      type = "select",
      name = L["Show On"],
      values = WeakAuras.bufftrigger_2_progress_behavior_types,
      order = 71,
      hidden = function()
        return not (trigger.type == "aura2");
      end,
      get = function()
        return trigger.matchesShowOn or "showOnActive";
      end
    },
    combineMatches = {
      type = "select",
      name = "Combine matches",
      values = WeakAuras.bufftrigger_2_match_types,
      order = 71.5,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.matchesShowOn ~= "showOnMissing");
      end,
      get = function()
        return trigger.combineMatches or "showLowest";
      end
    },
    unitExists = {
      type = "toggle",
      name = L["Show If Unit Is Invalid"],
      order = 72,
      hidden = function()
        return not (trigger.type == "aura2" and trigger.unit ~= "player");
      end
    },

  };

  -- Names
  for i = 1, 9 do
    if (i ~= 1) then
      aura_options["namespace" .. i] = {
        type = "execute",
        name = L["or"],
        width = 0.8,
        image = function() return "", 0, 0 end,
        order = i + 11.1,
        hidden = function() return not (trigger.type == "aura2" and trigger.useName and trigger.auranames and trigger.auranames[i - 1]); end,
      }
    end

    aura_options["nameicon" .. i] = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.auranames and trigger.auranames[i]) end,
      desc = function() return getAuraMatchesList(trigger.auranames and trigger.auranames[i]) end,
      width = 0.2,
      image = function()
        local icon = spellCache.GetIcon(trigger.auranames and trigger.auranames[i]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = i + 11.2,
      disabled = function() return not spellCache.GetIcon(trigger.auranames and trigger.auranames[i]) end,
      hidden = function() return not (trigger.type == "aura2" and trigger.useName and (i == 1 or trigger.auranames and trigger.auranames[i - 1])); end
    }

    aura_options["name" .. i] = {
      type = "input",
      name = L["Aura Name"],
      desc = L["Enter an aura name, partial aura name, or spell id"],
      order = i + 11.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.useName and (i == 1 or trigger.auranames and trigger.auranames[i - 1])); end,
      get = function(info) return trigger.auranames and trigger.auranames[i] end,
      set = function(info, v)
        trigger.auranames = trigger.auranames or {};
        if (v == "") then
          shiftTable(trigger.auranames, i);
        else
          local spellId = tonumber(v);
          if (spellId) then
            WeakAuras.spellCache.CorrectAuraName(v);
          else
            trigger.auranames[i] = spellCache.BestKeyMatch(v);
          end
        end

        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    }
  end
  -- Exact Spell IDs
  for i = 1, 9 do
    if (i ~= 1) then
      aura_options["spellidspace" .. i] = {
        type = "execute",
        name = L["or"],
        width = 0.8,
        image = function() return "", 0, 0 end,
        order = i + 21.1,
        hidden = function() return not (trigger.type == "aura2" and trigger.useExactSpellId and trigger.auraspellids and trigger.auraspellids[i - 1]); end,
      }
    end

    aura_options["spellidicon" .. i] = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.auraspellids and trigger.auraspellids[i]) end,
      desc = function() return getAuraMatchesList(trigger.auraspellids and trigger.auraspellids[i]) end,
      width = 0.2,
      image = function()
        local icon = spellCache.GetIcon(trigger.auraspellids and trigger.auraspellids[i]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = i + 21.2,
      disabled = function() return not spellCache.GetIcon(trigger.auraspellids and trigger.auraspellids[i]) end,
      hidden = function() return not (trigger.type == "aura2" and trigger.useExactSpellId and (i == 1 or trigger.auraspellids and trigger.auraspellids[i - 1])); end
    }

    aura_options["spellid" .. i] = {
      type = "input",
      name = L["Spell Id"],
      desc = L["Enter a spell id"],
      order = i + 21.3,
      hidden = function() return not (trigger.type == "aura2" and trigger.useExactSpellId and (i == 1 or trigger.auraspellids and trigger.auraspellids[i - 1])); end,
      get = function(info) return trigger.auraspellids and trigger.auraspellids[i] end,
      set = function(info, v)
        trigger.auraspellids = trigger.auraspellids or {};
        if (v == "") then
          shiftTable(trigger.auraspellids, i);
        else
          trigger.auraspellids[i] = v;
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      validate = ValidateNumeric,
    }
  end

  return aura_options;
end

WeakAuras.RegisterTriggerSystemOptions({"aura2"}, GetBuffTriggerOptions);
