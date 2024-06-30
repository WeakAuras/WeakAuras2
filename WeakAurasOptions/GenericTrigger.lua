if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L;

local function GetCustomTriggerOptions(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local function appendToTriggerPath(...)
    local ret = {...};
    tinsert(ret, 1, "trigger");
    tinsert(ret, 1, triggernum);
    tinsert(ret, 1, "triggers");
    return ret;
  end

  local function appendToUntriggerPath(...)
    local ret = {...};
    tinsert(ret, 1, "untrigger");
    tinsert(ret, 1, triggernum);
    tinsert(ret, 1, "triggers");
    return ret;
  end

  local customOptions =
  {
    custom_type = {
      type = "select",
      name = L["Event Type"],
      order = 7,
      width = WeakAuras.doubleWidth,
      values = OptionsPrivate.Private.custom_trigger_types,
      hidden = function() return not (trigger.type == "custom") end,
      get = function()
        return trigger.custom_type
      end,
      set = function(info, v)
        trigger.custom_type = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.ClearAndUpdateOptions(data.id);
      end
    },
    check = {
      type = "select",
      name = L["Check On..."],
      width = WeakAuras.doubleWidth,
      order = 8,
      values = OptionsPrivate.Private.check_types,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check ~= "update")
      end,
      get = function() return trigger.check end,
      set = function(info, v)
        trigger.check = v;
        WeakAuras.Add(data);
      end
    },
    check2 = {
      type = "select",
      name = L["Check On..."],
      order = 9,
      width = WeakAuras.doubleWidth,
      values = OptionsPrivate.Private.check_types,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check == "update")
      end,
      get = function() return trigger.check end,
      set = function(info, v)
        trigger.check = v;
        WeakAuras.Add(data);
      end
    },
    events = {
      type = "input",
      multiline = true,
      control = "WeakAuras-MultiLineEditBoxWithEnter",
      LAAC = { disableFunctions = true, disableSystems = true },
      width = WeakAuras.doubleWidth,
      name = L["Event(s)"],
      desc = L["Custom trigger status tooltip"],
      order = 8.1,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check ~= "update") end,
      get = function() return trigger.events end,
      set = function(info, v)
        trigger.events = v;
        WeakAuras.Add(data);
      end
    },
    events2 = {
      type = "input",
      multiline = true,
      control = "WeakAuras-MultiLineEditBoxWithEnter",
      LAAC = { disableFunctions = true, disableSystems = true },
      name = L["Event(s)"],
      desc = L["Custom trigger event tooltip"],
      width = WeakAuras.doubleWidth,
      order = 9.1,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event") end,
      get = function() return trigger.events end,
      set = function(info, v)
        trigger.events = v;
        WeakAuras.Add(data);
      end
    },
    event_customError = {
      type = "description",
      name = function()
        local events = trigger.custom_type == "event" and trigger.events2 or trigger.events
        -- Check for errors
        for _, event in pairs(WeakAuras.split(events)) do
          local trueEvent
          for i in event:gmatch("[^:]+") do
            if not trueEvent then
              trueEvent = string.upper(i)
            elseif trueEvent == "CLEU" or trueEvent == "COMBAT_LOG_EVENT_UNFILTERED" then
              local subevent = string.upper(i)
              if not OptionsPrivate.Private.IsCLEUSubevent(subevent) then
                return "|cFFFF0000"..L["%s is not a valid SubEvent for COMBAT_LOG_EVENT_UNFILTERED"]:format(subevent)
              end
            elseif trueEvent:match("^UNIT_") then
              local unit = string.lower(i)
              if not OptionsPrivate.Private.baseUnitId[unit] and not OptionsPrivate.Private.multiUnitId[unit] then
                return "|cFFFF0000"..L["Unit %s is not a valid unit for RegisterUnitEvent"]:format(unit)
              end
            elseif trueEvent == "TRIGGER" then
              local requestedTriggernum = tonumber(i)
              if requestedTriggernum then
                if OptionsPrivate.Private.watched_trigger_events[data.id]
                and OptionsPrivate.Private.watched_trigger_events[data.id][triggernum]
                and OptionsPrivate.Private.watched_trigger_events[data.id][triggernum][requestedTriggernum] then
                  return "|cFFFF0000"..L["Reciprocal TRIGGER:# requests will be ignored!"]
                end
              end
            end
          end
        end

        -- Check for warnings
        for _, event in pairs(WeakAuras.split(events)) do
          if event == "CLEU" or event == "COMBAT_LOG_EVENT_UNFILTERED" then
            return "|cFFFF0000"..L["COMBAT_LOG_EVENT_UNFILTERED with no filter can trigger frame drops in raid environment."]
          end
        end
        return ""
      end,
      width = WeakAuras.doubleWidth,
      order = 9.201,
      hidden = function()
        if not (
          trigger.type == "custom"
          and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate" or trigger.custom_type == "event")
          and trigger.check ~= "update"
        )
        then
          return true
        end
        local events = trigger.custom_type == "event" and trigger.events2 or trigger.events
        -- Check for errors
        for _, event in pairs(WeakAuras.split(events)) do
          local trueEvent
          for i in event:gmatch("[^:]+") do
            if not trueEvent then
              trueEvent = string.upper(i)
            elseif trueEvent == "CLEU" or trueEvent == "COMBAT_LOG_EVENT_UNFILTERED" then
              if not OptionsPrivate.Private.IsCLEUSubevent(string.upper(i)) then
                return false
              end
            elseif trueEvent:match("^UNIT_") then
              local unit = string.lower(i)
              if not OptionsPrivate.Private.baseUnitId[unit] then
                return false
              end
            elseif trueEvent == "TRIGGER" then
              local requestedTriggernum = tonumber(i)
              if requestedTriggernum then
                if OptionsPrivate.Private.watched_trigger_events[data.id]
                and OptionsPrivate.Private.watched_trigger_events[data.id][triggernum]
                and OptionsPrivate.Private.watched_trigger_events[data.id][triggernum][requestedTriggernum] then
                  return false
                end
              end
            end
          end
        end
        -- Check for warnings
        for _, event in pairs(WeakAuras.split(events)) do
          if event == "CLEU" or event == "COMBAT_LOG_EVENT_UNFILTERED" then
            return false
          end
        end
        return true
      end
    },
    -- texteditor below
    custom_hide = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Hide"],
      order = 12,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom") end,
      values = OptionsPrivate.Private.eventend_types,
      get = function() trigger.custom_hide = trigger.custom_hide or "timed"; return trigger.custom_hide end,
      set = function(info, v)
        trigger.custom_hide = v;
        WeakAuras.Add(data);
      end
    },
    custom_hide2 = {
      type = "select",
      name = L["Hide"],
      order = 12,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide == "custom") end,
      values = OptionsPrivate.Private.eventend_types,
      get = function() return trigger.custom_hide end,
      set = function(info, v)
        trigger.custom_hide = v;
        WeakAuras.Add(data);
      end
    },
    dynamicDuration = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Dynamic Duration"],
      order = 12.5,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom") end,
      get = function()
        return trigger.dynamicDuration
      end,
      set = function(info, v)
        trigger.dynamicDuration = v;
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id);
      end
    },
    duration = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Duration (s)"],
      order = 13,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom" and not trigger.dynamicDuration) end,
      get = function()
        return trigger.duration
      end,
      set = function(info, v)
        trigger.duration = v
        WeakAuras.Add(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    },
    addOverlayFunction = {
      type = "execute",
      name = L["Add Overlay"],
      order = 17.9,
      width = WeakAuras.doubleWidth,
      hidden = function()
        if (trigger.type ~= "custom") then
          return true;
        end
        if (trigger.custom_type == "stateupdate") then
          return true;
        end

        for i = 1, 7 do
          if (trigger["customOverlay" .. i] == nil) then
            return false;
          end
        end
        return true;
      end,
      func = function()
        for i = 1, 7 do
          if (trigger["customOverlay" .. i] == nil) then
            trigger["customOverlay" .. i] = "";
            break;
          end
        end
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    }
  };

  local function extraSetFunction()
    WeakAuras.UpdateThumbnail(data);
  end

  local function extraSetFunctionReload()
    extraSetFunction();
    WeakAuras.ClearAndUpdateOptions(data.id);
  end

  local function hideCustomTrigger()
    return not (trigger.type == "custom")
  end
  OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, L["Custom Trigger"], "custom_trigger", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-trigger",
                          10, hideCustomTrigger, appendToTriggerPath("custom"), false, {multipath = false, extraSetFunction = extraSetFunction, reloadOptions = true});

  local function hideCustomVariables()
    return not (trigger.type == "custom" and trigger.custom_type == "stateupdate");
  end

  local validTypes = {
    bool = true,
    number = true,
    timer = true,
    elapsedTimer = true,
    select = true,
    string = true,
  }

  local validProperties = {
    display = "string",
    type = "string",
    test = "function",
    events = "table",
    values = "table",
    total = "string",
    inverse = "string",
    paused = "string",
    remaining = "string",
    modRate = "string",
    useModRate = "boolean"
  }

  local function validateCustomVariables(variables)
    if (type(variables) ~= "table") then
      return L["Not a table"]
    end

    OptionsPrivate.Private.ExpandCustomVariables(variables)

    for k, v in pairs(variables) do
      if k == "additionalProgress" then
        -- Skip over additionalProgress
      elseif type(v) ~= "table" then
        return string.format(L["Could not parse '%s'. Expected a table."], k)
      elseif not validTypes[v.type] then
        return string.format(L["Invalid type for '%s'. Expected 'bool', 'number', 'select', 'string', 'timer' or 'elapsedTimer'."], k)
      elseif v.type == "select" and not v.values then
        return string.format(L["Type 'select' for '%s' requires a values member'"], k)
      else
        for property, propertyValue in pairs(v) do
          if not validProperties[property] then
            return string.format(L["Unknown property '%s' found in '%s'"], property, k)
          end
          if type(propertyValue) ~= validProperties[property] then
            return string.format(L["Invalid type for property '%s' in '%s'. Expected '%s'"], property, k, validProperties[property])
          end
        end
      end
    end
  end

  OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, L["Custom Variables"], "custom_variables", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-variables",
                          11, hideCustomVariables, appendToTriggerPath("customVariables"), false,
                          {multipath = false, extraSetFunction = extraSetFunctionReload, reloadOptions = true, validator = validateCustomVariables });

  local function hideCustomUntrigger()
    return not (trigger.type == "custom"
      and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom")))
  end
  OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, L["Custom Untrigger"], "custom_untrigger", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-untrigger",
                          14, hideCustomUntrigger, appendToUntriggerPath("custom"), false, {multipath = false, extraSetFunction = extraSetFunction});

  local function hideCustomDuration()
    return not (trigger.type == "custom"
      and (trigger.custom_type == "status"
           or (trigger.custom_type == "event" and (trigger.custom_hide ~= "timed" or trigger.dynamicDuration))))
  end
  OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, L["Duration Info"], "custom_duration", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#duration-info",
                          16, hideCustomDuration, appendToTriggerPath("customDuration"), false, { multipath = false, extraSetFunction = extraSetFunctionReload });

  local function hideIfTriggerStateUpdate()
    return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate")
  end

  for i = 1, 7 do
    local function hideOverlay()
      if (trigger["customOverlay" .. i] == nil) then
        return true;
      end
      return hideIfTriggerStateUpdate();
    end

    local function removeOverlay()
      for j = i, 7 do
        trigger["customOverlay" .. j] = trigger["customOverlay" .. (j +1)];
      end
      WeakAuras.Add(data);
      WeakAuras.ClearAndUpdateOptions(data.id)
      WeakAuras.FillOptions()
    end

    local extraFunctions = {
      {
        buttonLabel = L["Remove"],
        func = removeOverlay
      }
    }

    OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, string.format(L["Overlay %s Info"], i), "custom_overlay" .. i, "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#overlay-info",
                            17 + i / 10, hideOverlay, appendToTriggerPath("customOverlay" .. i), false, { multipath = false, extraSetFunction = extraSetFunctionReload, extraFunctions = extraFunctions});
  end

  OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, L["Name Info"], "custom_name",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#name-info",
                          18, hideIfTriggerStateUpdate, appendToTriggerPath("customName"), false,
                          { multipath = false, extraSetFunction = extraSetFunctionReload});
  OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, L["Icon Info"], "custom_icon",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#icon-info",
                          20, hideIfTriggerStateUpdate, appendToTriggerPath("customIcon"), false,
                          { multipath = false, extraSetFunction = extraSetFunction});
  OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, L["Texture Info"], "custom_texture",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#texture-info",
                          22, hideIfTriggerStateUpdate, appendToTriggerPath("customTexture"), false,
                          { multipath = false, extraSetFunction = extraSetFunction});
  OptionsPrivate.commonOptions.AddCodeOption(customOptions, data, L["Stack Info"], "custom_stacks",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#stack-info",
                          23, hideIfTriggerStateUpdate, appendToTriggerPath("customStacks"), false,
                          { multipath = false, extraSetFunction = extraSetFunctionReload});

  return customOptions;
end

local function GetGenericTriggerOptions(data, triggernum)
  local id = data.id;

  local trigger = data.triggers[triggernum].trigger;
  local triggerType = trigger.type;

  local subtypes = OptionsPrivate.Private.category_event_prototype[trigger.type]

  local needsTypeSelection = subtypes and next(subtypes, next(subtypes))

  local options = {}

  if needsTypeSelection then
    options.event = {
      type = "select",
      name = "",
      order = 7.1,
      width = WeakAuras.normalWidth,
      values = subtypes,
      sorting = OptionsPrivate.Private.SortOrderForValues(subtypes),
      get = function(info)
        return trigger.event
      end,
      set = function(info, v)
        trigger.event = v
        WeakAuras.Add(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end,
    }
  end

  OptionsPrivate.commonOptions.AddCommonTriggerOptions(options, data, triggernum, not needsTypeSelection)
  OptionsPrivate.AddTriggerMetaFunctions(options, data, triggernum)

  local combatLogCategory = WeakAuras.GetTriggerCategoryFor("Combat Log")
  local combatLogOptions =
  {
    subeventPrefix = {
      type = "select",
      name = L["Subevent"],
      width = WeakAuras.normalWidth,
      order = 8,
      values = OptionsPrivate.Private.subevent_prefix_types,
      sorting = OptionsPrivate.Private.SortOrderForValues(OptionsPrivate.Private.subevent_prefix_types),
      hidden = function() return not (trigger.type == combatLogCategory and trigger.event == "Combat Log"); end,
      get = function(info)
        return trigger.subeventPrefix
      end,
      set = function(info, v)
        trigger.subeventPrefix = v
        WeakAuras.Add(data)
      end
    },
    subeventSuffix = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Subevent Suffix"],
      order = 9,
      values = OptionsPrivate.Private.subevent_suffix_types,
      sorting = OptionsPrivate.Private.SortOrderForValues(OptionsPrivate.Private.subevent_suffix_types),
      hidden = function() return not (trigger.type == combatLogCategory and trigger.event == "Combat Log" and OptionsPrivate.Private.subevent_actual_prefix_types[trigger.subeventPrefix]); end,
      get = function(info)
        return trigger.subeventSuffix
      end,
      set = function(info, v)
        trigger.subeventSuffix = v
        WeakAuras.Add(data)
      end
    },
    spacer_suffix = {
      type = "description",
      name = "",
      order = 9.1,
      hidden = function() return not (trigger.type == combatLogCategory and trigger.event == "Combat Log"); end
    },
  }

  if (triggerType == "custom") then
    Mixin(options, GetCustomTriggerOptions(data, triggernum));
  elseif (OptionsPrivate.Private.category_event_prototype[triggerType]) then
    local prototypeOptions;
    local trigger = data.triggers[triggernum].trigger
    if(OptionsPrivate.Private.event_prototypes[trigger.event]) then
      prototypeOptions = OptionsPrivate.ConstructOptions(OptionsPrivate.Private.event_prototypes[trigger.event], data, 10, triggernum);
      if (trigger.event == "Combat Log") then
        Mixin(prototypeOptions, combatLogOptions);
      end
    else
      print("|cFF8800FFWeakAuras|r: No prototype for", trigger.event);
    end
    if (prototypeOptions) then
      Mixin(options, prototypeOptions);
    end
  end


  return {
    ["trigger." .. triggernum .. "." .. (trigger.event or "unknown")] = options
  }
end

WeakAuras.RegisterTriggerSystemOptions(WeakAuras.genericTriggerTypes, GetGenericTriggerOptions);
