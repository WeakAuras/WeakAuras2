if not WeakAuras.IsCorrectVersion() then return end

local L = WeakAuras.L;

local event_types = WeakAuras.event_types;
local status_types = WeakAuras.status_types;
local check_types = WeakAuras.check_types;
local subevent_prefix_types = WeakAuras.subevent_prefix_types;
local subevent_actual_prefix_types = WeakAuras.subevent_actual_prefix_types;
local subevent_suffix_types = WeakAuras.subevent_suffix_types;
local custom_trigger_types = WeakAuras.custom_trigger_types;
local eventend_types = WeakAuras.eventend_types;

local function GetCustomTriggerOptions(data, optionTriggerChoices, trigger)
  local id = data.id;

  local appendToTriggerPath, appendToUntriggerPath;

  if (data.controlledChildren) then
    function appendToTriggerPath(...)
      local baseRet = {...};
      local result = {};

      for index, childId in pairs(data.controlledChildren) do
        local ret = {};
        WeakAuras.DeepCopy(baseRet, ret);
        local optionTriggerChoice = optionTriggerChoices[childId];
        tinsert(ret, 1, "trigger");
        tinsert(ret, 1, optionTriggerChoice)
        tinsert(ret, 1, "triggers")
        result[childId] = ret;
      end
      return result;
    end
    function appendToUntriggerPath(...)
      local baseRet = {...};
      local result = {};

      for index, childId in pairs(data.controlledChildren) do
        local ret = {};
        WeakAuras.DeepCopy(baseRet, ret);
        local optionTriggerChoice = optionTriggerChoices[childId];
        tinsert(ret, 1, "untrigger");
        tinsert(ret, 1, optionTriggerChoice);
        tinsert(ret, 1, "triggers");
        result[childId] = ret;
      end
      return result;
    end
  else
    function appendToTriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "trigger");
      tinsert(ret, 1, optionTriggerChoices[id]);
      tinsert(ret, 1, "triggers");
      return ret;
    end

    function appendToUntriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "untrigger");
      tinsert(ret, 1, optionTriggerChoices[id]);
      tinsert(ret, 1, "triggers");
      return ret;
    end
  end

  local customOptions =
  {
    custom_type = {
      type = "select",
      name = L["Event Type"],
      order = 7,
      width = WeakAuras.doubleWidth,
      values = custom_trigger_types,
      hidden = function() return not (trigger.type == "custom") end,
      set = function(info, v)
        trigger.custom_type = v;
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.ReloadOptions(data.id);
      end
    },
    check = {
      type = "select",
      name = L["Check On..."],
      width = WeakAuras.doubleWidth / 3,
      order = 8,
      values = check_types,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check ~= "update")
      end,
      get = function() return trigger.check end,
      set = function(info, v)
        trigger.check = v;
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    check2 = {
      type = "select",
      name = L["Check On..."],
      order = 9,
      width = WeakAuras.doubleWidth,
      values = check_types,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check == "update")
      end,
      get = function() return trigger.check end,
      set = function(info, v)
        trigger.check = v;
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    events = {
      type = "input",
      width = WeakAuras.doubleWidth * 2 / 3,
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
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    events2 = {
      type = "input",
      name = L["Event(s)"],
      desc = L["Custom trigger event tooltip"],
      width = WeakAuras.doubleWidth,
      order = 9.1,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event") end,
      get = function() return trigger.events end,
      set = function(info, v)
        trigger.events = v;
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    event_customError = {
      type = "description",
      name = function()
        local events = trigger.custom_type == "event" and trigger.events2 or trigger.events
        for index, event in pairs(WeakAuras.split(events)) do
          local trueEvent
          for i in event:gmatch("[^:]+") do
            if not trueEvent then
              trueEvent = string.upper(i)
            elseif trueEvent == "CLEU" or trueEvent == "COMBAT_LOG_EVENT_UNFILTERED" then
              local subevent = string.upper(i)
              if not WeakAuras.IsCLEUSubevent(subevent) then
                return "|cFFFF0000"..L["%s is not a valid SubEvent for COMBAT_LOG_EVENT_UNFILTERED"]:format(subevent)
              end
            elseif trueEvent:match("^UNIT_") then
              local unit = string.lower(i)
              if not WeakAuras.baseUnitId[unit] and not WeakAuras.multiUnitId[unit] then
                return "|cFFFF0000"..L["Unit %s is not a valid unit for RegisterUnitEvent"]:format(unit)
              end
            end
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
        for index, event in pairs(WeakAuras.split(events)) do
          local trueEvent
          for i in event:gmatch("[^:]+") do
            if not trueEvent then
              trueEvent = string.upper(i)
            elseif trueEvent == "CLEU" or trueEvent == "COMBAT_LOG_EVENT_UNFILTERED" then
              if not WeakAuras.IsCLEUSubevent(string.upper(i)) then
                return false
              end
            elseif trueEvent:match("^UNIT_") then
              local unit = string.lower(i)
              if not WeakAuras.baseUnitId[unit] then
                return false
              end
            end
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
      values = eventend_types,
      get = function() trigger.custom_hide = trigger.custom_hide or "timed"; return trigger.custom_hide end,
      set = function(info, v)
        trigger.custom_hide = v;
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_hide2 = {
      type = "select",
      name = L["Hide"],
      order = 12,
      width = WeakAuras.doubleWidth,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide == "custom") end,
      values = eventend_types,
      get = function() return trigger.custom_hide end,
      set = function(info, v)
        trigger.custom_hide = v;
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    dynamicDuration = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Dynamic Duration"],
      order = 12.5,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom") end,
      set = function(info, v)
        trigger.dynamicDuration = v;
        WeakAuras.Add(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.ReloadOptions(data.id);
      end
    },
    duration = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Duration (s)"],
      order = 13,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom" and not trigger.dynamicDuration) end,
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
        if (data.controlledChildren) then
          for index, childId in ipairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            for i = 1, 7 do
              if (childData.trigger["customOverlay" .. i] == nil) then
                childData.trigger["customOverlay" .. i] = "";
                break;
              end
            end
          end
        else
          for i = 1, 7 do
            if (trigger["customOverlay" .. i] == nil) then
              trigger["customOverlay" .. i] = "";
              break;
            end
          end
        end
        WeakAuras.Add(data);
      end
    }
  };

  local function extraSetFunction()
    WeakAuras.SetIconNames(data);
    WeakAuras.UpdateDisplayButton(data);
  end

  local function extraSetFunctionReload()
    extraSetFunction();
    WeakAuras.ReloadOptions(data.id);
  end

  local function hideCustomTrigger()
    return not (trigger.type == "custom")
  end
  WeakAuras.AddCodeOption(customOptions, data, L["Custom Trigger"], "custom_trigger", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers",
                          10, hideCustomTrigger, appendToTriggerPath("custom"), false, true, extraSetFunction, nil, true);

  local function hideCustomVariables()
    return not (trigger.type == "custom" and trigger.custom_type == "stateupdate");
  end

  WeakAuras.AddCodeOption(customOptions, data, L["Custom Variables"], "custom_variables", "https://github.com/WeakAuras/WeakAuras2/wiki/Trigger-State-Updater-(TSU)#custom-variables",
                          11, hideCustomVariables, appendToTriggerPath("customVariables"), false, true, extraSetFunctionReload, nil, true);

  local function hideCustomUntrigger()
    return not (trigger.type == "custom"
      and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom")))
  end
  WeakAuras.AddCodeOption(customOptions, data, L["Custom Untrigger"], "custom_untrigger", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers",
                          14, hideCustomUntrigger, appendToUntriggerPath("custom"), false, true, extraSetFunction);

  local function hideCustomDuration()
    return not (trigger.type == "custom"
      and (trigger.custom_type == "status"
           or (trigger.custom_type == "event" and (trigger.custom_hide ~= "timed" or trigger.dynamicDuration))))
  end
  WeakAuras.AddCodeOption(customOptions, data, L["Duration Info"], "custom_duration", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers",
                          16, hideCustomDuration, appendToTriggerPath("customDuration"), false, true, extraSetFunctionReload);

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
      if (data.controlledChildren) then
        for index, childId in ipairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          for j = i, 7 do
            childData.trigger["customOverlay" .. j] = childData.trigger["customOverlay" .. (j +1)];
          end
          WeakAuras.ScheduleReloadOptions(childData);
        end
        WeakAuras.Add(data);
        WeakAuras.ScheduleReloadOptions(data);
      else
        for j = i, 7 do
          trigger["customOverlay" .. j] = trigger["customOverlay" .. (j +1)];
        end
        WeakAuras.Add(data);
        WeakAuras.ScheduleReloadOptions(data);
      end
    end

    local extraFunctions = {
      {
        buttonLabel = L["Remove"],
        func = removeOverlay
      }
    }

    WeakAuras.AddCodeOption(customOptions, data, string.format(L["Overlay %s Info"], i), "custom_overlay" .. i, "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers",
                            17 + i / 10, hideOverlay, appendToTriggerPath("customOverlay" .. i), false, true, extraSetFunctionReload, extraFunctions);
  end

  WeakAuras.AddCodeOption(customOptions, data, L["Name Info"], "custom_name", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers",
                          18, hideIfTriggerStateUpdate, appendToTriggerPath("customName"), false, true, extraSetFunctionReload);
  WeakAuras.AddCodeOption(customOptions, data, L["Icon Info"], "custom_icon", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers",
                          20, hideIfTriggerStateUpdate, appendToTriggerPath("customIcon"), false, true, extraSetFunction);
  WeakAuras.AddCodeOption(customOptions, data, L["Texture Info"], "custom_texture", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers",
                          22, hideIfTriggerStateUpdate, appendToTriggerPath("customTexture"), false, true, extraSetFunction);
  WeakAuras.AddCodeOption(customOptions, data, L["Stack Info"], "custom_stacks", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers",
                          23, hideIfTriggerStateUpdate, appendToTriggerPath("customStacks"), false, true, extraSetFunctionReload);

  return customOptions;
end

local function GetGenericTriggerOptions(data, optionTriggerChoices)
  local id = data.id;

  local trigger;
  local triggerType;
  if (data.controlledChildren) then
    triggerType = WeakAuras.getAll(data, {"trigger", "type"});
  else
    local triggernum = optionTriggerChoices[id];
    trigger = data.triggers[triggernum].trigger;
    triggerType = trigger.type;
  end

  local options = {
    event = {
      type = "select",
      name = function()
        if(trigger.type == "event") then
          return L["Event"];
        elseif(trigger.type == "status") then
          return L["Status"];
        end
      end,
      order = 7,
      width = WeakAuras.doubleWidth,
      values = function()
        local type;
        if (data.controlledChildren) then
          type = WeakAuras.getAll(data, {"trigger", "type"});
        else
          type = trigger.type;
        end
        if(type == "event") then
          return event_types;
        elseif(type == "status") then
          return status_types;
        end
      end,
      control = "WeakAurasSortedDropdown",
      hidden = function() return not (trigger.type == "event" or trigger.type == "status"); end
    },
  }

  local combatLogOptions =
  {
    subeventPrefix = {
      type = "select",
      name = L["Message Prefix"],
      width = WeakAuras.normalWidth,
      order = 8,
      values = subevent_prefix_types,
      control = "WeakAurasSortedDropdown",
      hidden = function() return not (trigger.type == "event" and trigger.event == "Combat Log"); end
    },
    subeventSuffix = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Message Suffix"],
      order = 9,
      values = subevent_suffix_types,
      control = "WeakAurasSortedDropdown",
      hidden = function() return not (trigger.type == "event" and trigger.event == "Combat Log" and subevent_actual_prefix_types[trigger.subeventPrefix]); end
    },
    spacer_suffix = {
      type = "description",
      name = "",
      order = 9.1,
      hidden = function() return not (trigger.type == "event" and trigger.event == "Combat Log"); end
    },
  }

  if (triggerType == "custom") then
    Mixin(options, GetCustomTriggerOptions(data, optionTriggerChoices, trigger));
  elseif (triggerType == "status" or triggerType == "event") then
    local prototypeOptions;
    if (data.controlledChildren) then
      local event = WeakAuras.getAll(data, {"trigger", "event"});
      local unevent = WeakAuras.getAll(data, {"trigger", "unevent"});
      if(event and WeakAuras.event_prototypes[event]) then
        prototypeOptions = WeakAuras.ConstructOptions(WeakAuras.event_prototypes[event], data, 10, optionTriggerChoices[id], nil, unevent);
        if (event == "Combat Log") then
          Mixin(prototypeOptions, combatLogOptions);
        end
      end
    else
      local triggerNum = optionTriggerChoices[id];
      local trigger, untrigger = data.triggers[triggerNum].trigger, data.triggers[triggerNum].untrigger;
      if(WeakAuras.event_prototypes[trigger.event]) then
        prototypeOptions = WeakAuras.ConstructOptions(WeakAuras.event_prototypes[trigger.event], data, 10, optionTriggerChoices[id]);
        if (trigger.event == "Combat Log") then
          Mixin(prototypeOptions, combatLogOptions);
        end
      else
        print("|cFF8800FFWeakAuras|r: No prototype for", trigger.event);
      end
    end
    if (prototypeOptions) then
      Mixin(options, prototypeOptions);
    end
  end

  return options;
end

WeakAuras.RegisterTriggerSystemOptions({"event", "status", "custom"}, GetGenericTriggerOptions);
