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
    if(numMatches == 1) then
      return L["1 Match"];
    else
      return L["%i Matches"]:format(numMatches);
    end
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

local function GetBuffTriggerOptions(data, optionTriggerChoices)
  local trigger;
  if (not data.controlledChildren) then
    local triggernum = optionTriggerChoices[data.id];
    if (triggernum) then
      trigger = data.triggers[triggernum].trigger;
    end
  end

  -- TODO LIST, aka what's missing?
  -- remaining time
  -- show on: always/not buffed, unit not exists
  -- autoclone
  -- fullscan
  --   aura names: IsExactly/Contains/Pattern Matching for
  --    match on tooltip:
  --    Stealable
  --    spellId
  --    debuffClass
  --    tooltip size
  -- multi trigger
  -- Multiple aura names
  -- Specific Unit
  -- Group:
  --   group member count
  --   group role
  --   ignore self
  --   name info
  --   stack info
  --   hide alone
  --

  local spellCache = WeakAuras.spellCache;
  local ValidateNumeric = WeakAuras.ValidateNumeric;
  local aura_options = {

    useName = {
      type = "toggle",
      name = L["Aura(s)"],
      width = "half",
      order = 10,
      hidden = function() return not (trigger.type == "aura2"); end,
      disabled = true,
      get = function() return true end
    },
    nameicon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.name) end,
      desc = function() return getAuraMatchesList(trigger.name) end,
      width = "half",
      image = function()
        local icon = spellCache.GetIcon(trigger.name);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 11,
      disabled = function() return not spellCache.GetIcon(trigger.name) end,
      hidden = function() return not (trigger.type == "aura2"); end
    },
    name = {
      type = "input",
      name = L["Aura Name"],
      desc = L["Enter an aura name, partial aura name, or spell id"],
      order = 12,
      hidden = function() return not (trigger.type == "aura2"); end,
      get = function(info) return trigger.spellId and tostring(trigger.spellId) or trigger.name end,
      set = function(info, v)
        if(v == "") then
          if(trigger.name) then
            trigger.name = nil;
            trigger.spellId = nil;
          end
        else
          trigger.name, trigger.spellId = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    useUnit = {
      type = "toggle",
      name = L["Unit"],
      order = 40,
      disabled = true,
      hidden = function() return not (trigger.type == "aura2"); end,
      get = function() return true end
    },
    unit = {
      type = "select",
      name = L["Unit"],
      order = 41,
      values = function()
        return WeakAuras.actual_unit_types;
      end,
      hidden = function() return not (trigger.type == "aura2"); end,
    },
    useDebuffType = {
      type = "toggle",
      name = L["Aura Type"],
      order = 50,
      disabled = true,
      hidden = function() return not (trigger.type == "aura2"); end,
      get = function() return true end
    },
    debuffType = {
      type = "select",
      name = L["Aura Type"],
      order = 51,
      values = debuff_types,
      hidden = function() return not (trigger.type == "aura2"); end
    },
    useCount = {
      type = "toggle",
      name = L["Stack Count"],
      hidden = function() return not (trigger.type == "aura2"); end,
      order = 60
    },
    countOperator = {
      type = "select",
      name = L["Operator"],
      order = 62,
      width = "half",
      values = operator_types,
      disabled = function() return not trigger.useCount; end,
      hidden = function() return not (trigger.type == "aura2"); end,
      get = function() return trigger.useCount and trigger.countOperator or nil end
    },
    count = {
      type = "input",
      name = L["Stack Count"],
      validate = ValidateNumeric,
      order = 65,
      width = "half",
      disabled = function() return not trigger.useCount; end,
      hidden = function() return not (trigger.type == "aura2"); end,
      get = function() return trigger.useCount and trigger.count or nil end
    },
    ownOnly = {
      type = "toggle",
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
  };
  return aura_options;
end

WeakAuras.RegisterTriggerSystemOptions({"aura2"}, GetBuffTriggerOptions);
