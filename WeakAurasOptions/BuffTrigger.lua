if not WeakAuras.IsCorrectVersion() then return end

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

-- the spell id table is sparse, so tremove doesn't work
local function spellId_tremove(tbl, pos)
  for i = pos, 9, 1 do
    tbl[i] = tbl[i + 1]
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

function WeakAuras.GetBuffConversionOptions(data, optionTriggerChoices)
  local trigger;
  if (not data.controlledChildren) then
    local triggernum = optionTriggerChoices[data.id];
    if (triggernum) then
      trigger = data.triggers[triggernum].trigger;
    end
  end
  local aura_options = {
    convertToBuffTrigger2SpaceBefore = {
      type = "description",
      width = 0.3,
      order = 8.4,
      name = "",
      hidden = function()
        -- For those that update without restarting
        return not WeakAuras.CanConvertBuffTrigger2
      end,
    },
    convertToBuffTrigger2 = {
      type = "execute",
      width = WeakAuras.doubleWidth - 0.6,
      name = L["Convert to New Aura Trigger"],
      order = 8.5,
      hidden = function()
        -- For those that update without restarting
        return not WeakAuras.CanConvertBuffTrigger2
      end,
      disabled = function()
        if (not WeakAuras.CanConvertBuffTrigger2) then
          return true;
        end
        if (not WeakAuras.CanConvertBuffTrigger2(trigger)) then
          return true;
        end
        return false;
      end,
      desc = function()
        local _, err = WeakAuras.CanConvertBuffTrigger2(trigger);
        return err or ""
      end,
      func = function()
        if(data.controlledChildren) then
          for index, childId in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            local trigger = childData.triggers[optionTriggerChoices[childId]] and childData.triggers[optionTriggerChoices[childId]].trigger;
            if (trigger) then
              WeakAuras.ConvertBuffTrigger2(trigger);
              WeakAuras.Add(childData);
              WeakAuras.ReloadTriggerOptions(childData);
            end
          end
          WeakAuras.Add(data);
          WeakAuras.ReloadTriggerOptions(data);
        else
          WeakAuras.ConvertBuffTrigger2(trigger);
          WeakAuras.Add(data);
          WeakAuras.ReloadTriggerOptions(data);
        end
      end
    },
    convertToBuffTrigger2SpaceAfter = {
      type = "description",
      width = 0.3,
      order = 8.6,
      name = "",
      hidden = function()
        -- For those that update without restarting
        return not WeakAuras.CanConvertBuffTrigger2
      end,
    },
    convertToBuffTrigger2SpaceBeforeDesc = {
      type = "description",
      width = 0.4,
      order = 8.1,
      name = "",
      hidden = function()
        -- For those that update without restarting
        return not WeakAuras.CanConvertBuffTrigger2
      end,
    },
    convertToBuffTrigger2Desc = {
      type = "description",
      width = WeakAuras.doubleWidth - 0.8,
      order = 8.2,
      name = function()
        if (not WeakAuras.CanConvertBuffTrigger2) then
          return "";
        end
        local _, err = WeakAuras.CanConvertBuffTrigger2(trigger);
        return err or "";
      end,
      hidden = function()
        -- For those that update without restarting
        return not WeakAuras.CanConvertBuffTrigger2
      end,
    },
    convertToBuffTrigger2SpaceAfterDesc = {
      type = "description",
      width = 0.4,
      order = 8.3,
      name = "",
      hidden = function()
        -- For those that update without restarting
        return not WeakAuras.CanConvertBuffTrigger2
      end,
    },
  }
  return aura_options;
end

local function GetBuffTriggerOptions(data, optionTriggerChoices)
  local trigger;
  if (not data.controlledChildren) then
    local triggernum = optionTriggerChoices[data.id];
    if (triggernum) then
      trigger = data.triggers[triggernum].trigger;
    end
  end

  local spellCache = WeakAuras.spellCache;
  local ValidateNumeric = WeakAuras.ValidateNumeric;
  local aura_options = {
    fullscan = {
      type = "toggle",
      name = L["Use Full Scan (High CPU)"],
      width = WeakAuras.doubleWidth,
      order = 9,
    },
    autoclone = {
      type = "toggle",
      name = L["Show all matches (Auto-clone)"],
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end,
      set = function(info, v)
        trigger.autoclone = v;
        if(v == true) then
          WeakAuras.ShowCloneDialog(data);
        end
        WeakAuras.Add(data);
      end,
      order = 9.5
    },
    useName = {
      type = "toggle",
      name = L["Aura(s)"],
      width = WeakAuras.halfWidth,
      order = 10,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end,
      disabled = true,
      get = function() return true end
    },
    use_name = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Aura Name"],
      order = 10,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end
    },
    name_operator = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Operator"],
      order = 11,
      disabled = function() return not trigger.use_name end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end,
      values = WeakAuras.string_operator_types
    },
    name = {
      type = "input",
      name = L["Aura Name"],
      width = WeakAuras.doubleWidth,
      order = 12,
      disabled = function() return not trigger.use_name end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end,
      set = function(info, v)
        if (tonumber(v)) then
          trigger.spellId = tonumber(v);
          trigger.name = nil;
        else
          trigger.spellId = nil;
          trigger.name = v;
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    use_tooltip = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip"],
      order = 13,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end
    },
    tooltip_operator = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Operator"],
      order = 14,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end,
      values = WeakAuras.string_operator_types
    },
    tooltip = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = L["Tooltip"],
      order = 15,
      disabled = function() return not trigger.use_tooltip end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end
    },
    use_stealable = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = function(input)
        local value = trigger.use_stealable;
        if(value == nil) then return L["Stealable"];
        elseif(value == false) then return "|cFFFF0000 "..L["Negator"].." "..L["Stealable"];
        else return "|cFF00FF00"..L["Stealable"]; end
      end,
      order = 16,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end,
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
    use_spellId = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Spell ID"],
      order = 17,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end
    },
    spellId = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Spell ID"],
      order = 18,
      disabled = function() return not trigger.use_spellId end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.unit ~= "multi"); end
    },
    use_debuffClass = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Debuff Type"],
      order = 19,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end
    },
    debuffClass = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Debuff Type"],
      order = 20,
      disabled = function() return not trigger.use_debuffClass end,
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan); end,
      values = WeakAuras.debuff_class_types
    },
    multiuse_name = {
      type = "toggle",
      width = WeakAuras.halfWidth,
      name = L["Aura Name"],
      order = 10,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit == "multi"); end,
      disabled = true,
      get = function() return true end
    },
    multiicon = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = "",
      image = function()
        if (not trigger.name) then return "" end;
        local icon =  spellCache.GetIcon(trigger.name);
        return icon and tostring(icon) or "", 18, 18 end,
      order = 11,
      disabled = function() return not trigger.name and spellCache.GetIcon(trigger.name) end,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit == "multi"); end
    },
    multiname = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Aura Name"],
      desc = L["Enter an aura name, partial aura name, or spell id"],
      order = 12,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit == "multi"); end,
      get = function(info) return trigger.spellId and tostring(trigger.spellId) or trigger.name end,
      set = function(info, v)
        if(v == "") then
          trigger.name = nil;
          trigger.spellId = nil;
        else
          trigger.name, trigger.spellId = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name1icon = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = function() return getAuraMatchesLabel(trigger.names[1]) end,
      desc = function() return getAuraMatchesList(trigger.names[1]) end,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[1]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 11,
      disabled = function() return not spellCache.GetIcon(trigger.names[1]) end,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end
    },
    name1 = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Aura Name"],
      desc = L["Enter an aura name, partial aura name, or spell id"],
      order = 12,
      hidden = function() return not (trigger.type == "aura" and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[1] and tostring(trigger.spellIds[1]) or trigger.names[1] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[1]) then
            tremove(trigger.names, 1);
            spellId_tremove(trigger.spellIds, 1);
          end
        else
          trigger.names[1], trigger.spellIds[1] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name2space = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = L["or"],
      image = function() return "", 0, 0 end,
      order = 13,
      hidden = function() return not (trigger.type == "aura" and trigger.names[1] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name2icon = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = function() return getAuraMatchesLabel(trigger.names[2]) end,
      desc = function() return getAuraMatchesList(trigger.names[2]) end,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[2]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 14,
      disabled = function() return not spellCache.GetIcon(trigger.names[2]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[1] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name2 = {
      type = "input",
      width = WeakAuras.normalWidth,
      order = 15,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[1] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[2] and tostring(trigger.spellIds[2]) or trigger.names[2] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[2]) then
            tremove(trigger.names, 2);
            spellId_tremove(trigger.spellIds, 2);
          end
        else
          trigger.names[2], trigger.spellIds[2] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name3space = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = "",
      image = function() return "", 0, 0 end,
      order = 16,
      hidden = function() return not (trigger.type == "aura" and trigger.names[2] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name3icon = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = function() return getAuraMatchesLabel(trigger.names[3]) end,
      desc = function() return getAuraMatchesList(trigger.names[3]) end,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[3]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 17,
      disabled = function() return not spellCache.GetIcon(trigger.names[3]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[2] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name3 = {
      type = "input",
      width = WeakAuras.normalWidth,
      order = 18,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[2] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[3] and tostring(trigger.spellIds[3]) or trigger.names[3] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[3]) then
            tremove(trigger.names, 3);
            spellId_tremove(trigger.spellIds, 3);
          end
        else
          trigger.names[3], trigger.spellIds[3] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name4space = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = "",
      image = function() return "", 0, 0 end,
      order = 19,
      hidden = function() return not (trigger.type == "aura" and trigger.names[3] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name4icon = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = function() return getAuraMatchesLabel(trigger.names[4]) end,
      desc = function() return getAuraMatchesList(trigger.names[4]) end,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[4]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 20,
      disabled = function() return not spellCache.GetIcon(trigger.names[4]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[3] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name4 = {
      type = "input",
      order = 21,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[3] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[4] and tostring(trigger.spellIds[4]) or trigger.names[4] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[4]) then
            tremove(trigger.names, 4);
            spellId_tremove(trigger.spellIds, 4);
          end
        else
          trigger.names[4], trigger.spellIds[4] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name5space = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = "",
      image = function() return "", 0, 0 end,
      order = 22,
      disabled = function() return not spellCache.GetIcon(trigger.names[5]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[4] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name5icon = {
      type = "execute",
      width = WeakAuras.halfWidth,
      name = function() return getAuraMatchesLabel(trigger.names[5]) end,
      desc = function() return getAuraMatchesList(trigger.names[5]) end,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[5]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 23,
      hidden = function() return not (trigger.type == "aura" and trigger.names[4] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name5 = {
      type = "input",
      width = WeakAuras.normalWidth,
      order = 24,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[4] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[5] and tostring(trigger.spellIds[5]) or trigger.names[5] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[5]) then
            tremove(trigger.names, 5);
            spellId_tremove(trigger.spellIds, 5);
          end
        else
          trigger.names[5], trigger.spellIds[5] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name6space = {
      type = "execute",
      name = "",
      width = WeakAuras.halfWidth,
      image = function() return "", 0, 0 end,
      order = 25,
      hidden = function() return not (trigger.type == "aura" and trigger.names[5] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name6icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[6]) end,
      desc = function() return getAuraMatchesList(trigger.names[6]) end,
      width = WeakAuras.halfWidth,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[6]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 26,
      disabled = function() return not spellCache.GetIcon(trigger.names[6]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[5] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name6 = {
      type = "input",
      width = WeakAuras.normalWidth,
      order = 27,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[5] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[6] and tostring(trigger.spellIds[6]) or trigger.names[6] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[6]) then
            tremove(trigger.names, 6);
            spellId_tremove(trigger.spellIds, 6);
          end
        else
          trigger.names[6], trigger.spellIds[6] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name7space = {
      type = "execute",
      name = "",
      width = WeakAuras.halfWidth,
      image = function() return "", 0, 0 end,
      order = 28,
      hidden = function() return not (trigger.type == "aura" and trigger.names[6] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name7icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[7]) end,
      desc = function() return getAuraMatchesList(trigger.names[7]) end,
      width = WeakAuras.halfWidth,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[7]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 29,
      disabled = function() return not spellCache.GetIcon(trigger.names[7]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[6] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name7 = {
      type = "input",
      width = WeakAuras.normalWidth,
      order = 30,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[6] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[7] and tostring(trigger.spellIds[7]) or trigger.names[7] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[7]) then
            tremove(trigger.names, 7);
            spellId_tremove(trigger.spellIds, 7);
          end
        else
          trigger.names[7], trigger.spellIds[7] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name8space = {
      type = "execute",
      name = "",
      width = WeakAuras.halfWidth,
      image = function() return "", 0, 0 end,
      order = 31,
      hidden = function() return not (trigger.type == "aura" and trigger.names[7] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name8icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[8]) end,
      desc = function() return getAuraMatchesList(trigger.names[8]) end,
      width = WeakAuras.halfWidth,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[8]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 32,
      disabled = function() return not spellCache.GetIcon(trigger.names[8]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[7] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name8 = {
      type = "input",
      width = WeakAuras.normalWidth,
      order = 33,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[7] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[8] and tostring(trigger.spellIds[8]) or trigger.names[8] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[8]) then
            tremove(trigger.names, 8);
            spellId_tremove(trigger.spellIds, 8);
          end
        else
          trigger.names[8], trigger.spellIds[8] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    name9space = {
      type = "execute",
      name = "",
      width = WeakAuras.halfWidth,
      image = function() return "", 0, 0 end,
      order = 34,
      hidden = function() return not (trigger.type == "aura" and trigger.names[8] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name9icon = {
      type = "execute",
      name = function() return getAuraMatchesLabel(trigger.names[9]) end,
      desc = function() return getAuraMatchesList(trigger.names[9]) end,
      width = WeakAuras.halfWidth,
      image = function()
        local icon = spellCache.GetIcon(trigger.names[9]);
        return icon and tostring(icon) or "", 18, 18
      end,
      order = 35,
      disabled = function() return not spellCache.GetIcon(trigger.names[9]) end,
      hidden = function() return not (trigger.type == "aura" and trigger.names[8] and not trigger.fullscan and trigger.unit ~= "multi"); end,
    },
    name9 = {
      type = "input",
      width = WeakAuras.normalWidth,
      order = 36,
      name = "",
      hidden = function() return not (trigger.type == "aura" and trigger.names[8] and not trigger.fullscan and trigger.unit ~= "multi"); end,
      get = function(info) return trigger.spellIds[9] and tostring(trigger.spellIds[9]) or trigger.names[9] end,
      set = function(info, v)
        if(v == "") then
          if(trigger.names[9]) then
            tremove(trigger.names, 9);
            spellId_tremove(trigger.spellIds, 9);
          end
        else
          trigger.names[9], trigger.spellIds[9] = WeakAuras.spellCache.CorrectAuraName(v);
        end
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
    },
    useUnit = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Unit"],
      order = 40,
      disabled = true,
      hidden = function() return not (trigger.type == "aura"); end,
      get = function() return true end
    },
    unit = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Unit"],
      order = 41,
      values = function()
        if(trigger.fullscan) then
          return actual_unit_types_with_specific;
        else
          return unit_types;
        end
      end,
      hidden = function() return not (trigger.type == "aura"); end,
      set = function(info, v)
        trigger.unit = v;
        trigger.use_specific_unit = (v == "member");
        if(v == "multi") then
          WeakAuras.ShowCloneDialog(data);
        end
        WeakAuras.Add(data);
      end,
      get = function()
        if(trigger.fullscan and (trigger.unit == "group" or trigger.unit == "multi")) then
          trigger.unit = "player";
        end
        return trigger.unit;
      end
    },
    useSpecificUnit = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Specific Unit"],
      order = 42,
      disabled = true,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "member") end,
      get = function() return true end
    },
    specificUnit = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Specific Unit"],
      order = 43,
      desc = L["Can be a Name or a Unit ID (e.g. party1). A name only works on friendly players in your group."],
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "member") end
    },
    useGroup_count = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Group Member Count"],
      disabled = true,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      get = function() return true; end,
      order = 45
    },
    group_countOperator = {
      type = "select",
      name = L["Operator"],
      order = 46,
      width = WeakAuras.halfWidth,
      values = operator_types,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      get = function() return trigger.group_countOperator; end
    },
    group_count = {
      type = "input",
      name = L["Count"],
      desc = function()
        local groupType = unit_types[trigger.unit or "group"] or "|cFFFF0000error|r";
        return L["Group aura count description"]:format(groupType, groupType, groupType, groupType, groupType, groupType, groupType);
      end,
      order = 47,
      width = WeakAuras.halfWidth,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      get = function() return trigger.group_count; end,
      set = function(info, v)
        if(WeakAuras.ParseNumber(v)) then
          trigger.group_count = v;
        else
          trigger.group_count = "";
        end
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    useGroupRole = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Filter by Group Role"],
      order = 47.1,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
    },
    group_role = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Group Role"],
      values = WeakAuras.role_types,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      disabled = function() return not trigger.useGroupRole; end,
      get = function() return trigger.group_role; end,
      order = 47.2
    },
    ignoreSelf = {
      type = "toggle",
      name = L["Ignore self"],
      order = 47.3,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
    },
    groupclone = {
      type = "toggle",
      name = L["Show all matches (Auto-clone)"],
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
      set = function(info, v)
        trigger.groupclone = v;
        if(v == true) then
          WeakAuras.ShowCloneDialog(data);
        end
        WeakAuras.Add(data);
      end,
      order = 47.4
    },
    name_info = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Name Info"],
      order = 47.5,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group" and not trigger.groupclone); end,
      disabled = function() return not WeakAuras.CanShowNameInfo(data); end,
      get = function()
        if(WeakAuras.CanShowNameInfo(data)) then
          return trigger.name_info;
        else
          return nil;
        end
      end,
      values = group_aura_name_info_types
    },
    stack_info = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Stack Info"],
      order = 47.6,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group" and not trigger.groupclone); end,
      disabled = function() return not WeakAuras.CanShowStackInfo(data); end,
      get = function()
        if(WeakAuras.CanShowStackInfo(data)) then
          return trigger.stack_info;
        else
          return nil;
        end
      end,
      values = group_aura_stack_info_types
    },
    hideAlone = {
      type = "toggle",
      name = L["Hide When Not In Group"],
      order = 47.7,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "aura" and trigger.unit == "group"); end,
    },
    useDebuffType = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Aura Type"],
      order = 50,
      disabled = true,
      hidden = function() return not (trigger.type == "aura"); end,
      get = function() return true end
    },
    debuffType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Aura Type"],
      order = 51,
      values = debuff_types,
      hidden = function() return not (trigger.type == "aura"); end
    },
    subcount = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Use tooltip \"size\" instead of stacks"],
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan) end,
      order = 55
    },
    subcountCount = {
      type = "select",
      values = tooltip_count,
      width = WeakAuras.doubleWidth,
      name = L["Use nth value from tooltip:"],
      hidden = function() return not (trigger.type == "aura" and trigger.fullscan and trigger.subcount) end,
      order = 55.5
    },
    useRem = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Remaining Time"],
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      order = 56
    },
    remOperator = {
      type = "select",
      name = L["Operator"],
      order = 57,
      width = WeakAuras.halfWidth,
      values = operator_types,
      disabled = function() return not trigger.useRem; end,
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      get = function() return trigger.useRem and trigger.remOperator or nil end
    },
    rem = {
      type = "input",
      name = L["Remaining Time"],
      validate = ValidateNumeric,
      order = 58,
      width = WeakAuras.halfWidth,
      disabled = function() return not trigger.useRem; end,
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      get = function() return trigger.useRem and trigger.rem or nil end
    },
    useCount = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Stack Count"],
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      order = 60
    },
    countOperator = {
      type = "select",
      name = L["Operator"],
      order = 62,
      width = WeakAuras.halfWidth,
      values = operator_types,
      disabled = function() return not trigger.useCount; end,
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      get = function() return trigger.useCount and trigger.countOperator or nil end
    },
    count = {
      type = "input",
      name = L["Stack Count"],
      validate = ValidateNumeric,
      order = 65,
      width = WeakAuras.halfWidth,
      disabled = function() return not trigger.useCount; end,
      hidden = function() return not (trigger.type == "aura" and trigger.unit ~= "multi"); end,
      get = function() return trigger.useCount and trigger.count or nil end
    },
    ownOnly = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
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
      hidden = function() return not (trigger.type == "aura"); end
    },
    useBuffShowOn = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show On"],
      order = 71,
      disabled = true,
      hidden = function()
        return not (trigger.type == "aura" and not(trigger.unit ~= "group" and trigger.fullscan and trigger.autoclone) and trigger.unit ~= "multi" and not(trigger.unit == "group" and not trigger.groupclone));
      end,
      get = function() return true end
    },
    buffShowOn = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = "",
      values = WeakAuras.bufftrigger_progress_behavior_types,
      order = 71.1,
      get = function() return trigger.buffShowOn end,
      hidden = function()
        return not (trigger.type == "aura" and not(trigger.unit ~= "group" and trigger.fullscan and trigger.autoclone) and trigger.unit ~= "multi" and not(trigger.unit == "group" and not trigger.groupclone));
      end
    },
    unitExists = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show If Unit Is Invalid"],
      order = 72,
      hidden = function()
        return not (trigger.type == "aura"
          and not(trigger.unit ~= "group" and trigger.fullscan and trigger.autoclone)
          and trigger.unit ~= "multi"
          and trigger.unit ~= "group"
          and trigger.unit ~= "player");
      end
    },
    linespacer = {
      type = "description",
      order = 73,
      width = WeakAuras.doubleWidth,
      name = "",
      hidden = function()
        -- For those that update without restarting
        return not WeakAuras.CanConvertBuffTrigger2
      end,
    },

  };
  return aura_options;
end

WeakAuras.RegisterTriggerSystemOptions({"aura"}, GetBuffTriggerOptions);
