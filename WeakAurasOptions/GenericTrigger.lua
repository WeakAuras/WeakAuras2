local L = WeakAuras.L;

local event_types = WeakAuras.event_types;
local status_types = WeakAuras.status_types;
local check_types = WeakAuras.check_types;
local subevent_prefix_types = WeakAuras.subevent_prefix_types;
local subevent_actual_prefix_types = WeakAuras.subevent_actual_prefix_types;
local subevent_suffix_types = WeakAuras.subevent_suffix_types;
local custom_trigger_types = WeakAuras.custom_trigger_types;
local eventend_types = WeakAuras.eventend_types;

function WeakAuras.GetGenericTriggerOptions(data, trigger, untrigger)
  if (not trigger) then
    return {};
  end
  local id = data.id;
  local optionTriggerChoices =  WeakAuras.optionTriggerChoices;
  local appendToTriggerPath, appendToUntriggerPath;

  if (data.controlledChildren) then
    function appendToTriggerPath(...)
      local baseRet = {...};
      local result = {};

      for index, childId in pairs(data.controlledChildren) do
        local ret = {};
        WeakAuras.DeepCopy(baseRet, ret);
        local optionTriggerChoice = optionTriggerChoices[childId];
        if (optionTriggerChoice == 0) then
          tinsert(ret, 1, "trigger");
        elseif (optionTriggerChoice > 0) then
          tinsert(ret, 1, "trigger");
          tinsert(ret, 1, optionTriggerChoice);
          tinsert(ret, 1, "additional_triggers");
        end
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
        if (optionTriggerChoice == 0) then
          tinsert(ret, 1, "untrigger");
        elseif (optionTriggerChoice > 0) then
          tinsert(ret, 1, "untrigger");
          tinsert(ret, 1, optionTriggerChoice);
          tinsert(ret, 1, "additional_triggers");
        end
        result[childId] = ret;
      end
      return result;
    end
  elseif(optionTriggerChoices[id] == 0) then
    function appendToTriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "trigger");
      return ret;
    end

    function appendToUntriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "untrigger");
      return ret;
    end
  elseif (optionTriggerChoices[id] > 0) then
    function appendToTriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "trigger");
      tinsert(ret, 1, optionTriggerChoices[id]);
      tinsert(ret, 1, "additional_triggers");
      return ret;
    end

    function appendToUntriggerPath(...)
      local ret = {...};
      tinsert(ret, 1, "untrigger");
      tinsert(ret, 1, optionTriggerChoices[id]);
      tinsert(ret, 1, "additional_triggers");
      return ret;
    end
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
      width = "double",
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
    subeventPrefix = {
      type = "select",
      name = L["Message Prefix"],
      order = 8,
      values = subevent_prefix_types,
      control = "WeakAurasSortedDropdown",
      hidden = function() return not (trigger.type == "event" and trigger.event == "Combat Log"); end
    },
    subeventSuffix = {
      type = "select",
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
    custom_type = {
      type = "select",
      name = L["Event Type"],
      order = 7,
      width = "double",
      values = custom_trigger_types,
      hidden = function() return not (trigger.type == "custom") end,
      set = function(info, v)
        trigger.custom_type = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.ReloadOptions(data.id);
      end
    },
    check = {
      type = "select",
      name = L["Check On..."],
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
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    check2 = {
      type = "select",
      name = L["Check On..."],
      order = 9,
      width = "double",
      values = check_types,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or trigger.custom_type == "stateupdate")
        and trigger.check == "update")
      end,
      get = function() return trigger.check end,
      set = function(info, v)
        trigger.check = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    events = {
      type = "input",
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
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    events2 = {
      type = "input",
      name = L["Event(s)"],
      desc = L["Custom trigger event tooltip"],
      width = "double",
      order = 9.1,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event") end,
      get = function() return trigger.events end,
      set = function(info, v)
        trigger.events = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    -- texteditor below
    custom_hide = {
      type = "select",
      name = L["Hide"],
      order = 12,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom") end,
      values = eventend_types,
      get = function() trigger.custom_hide = trigger.custom_hide or "timed"; return trigger.custom_hide end,
      set = function(info, v)
        trigger.custom_hide = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    custom_hide2 = {
      type = "select",
      name = L["Hide"],
      order = 12,
      width = "double",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide == "custom") end,
      values = eventend_types,
      get = function() return trigger.custom_hide end,
      set = function(info, v)
        trigger.custom_hide = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end
    },
    dynamicDuration = {
      type = "toggle",
      name = L["Dynamic Duration"],
      order = 12.5,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom") end,
      set = function(info, v)
        trigger.dynamicDuration = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.ReloadOptions(data.id);
      end
    },
    duration = {
      type = "input",
      name = L["Duration (s)"],
      order = 13,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom" and not trigger.dynamicDuration) end,
    },
    addOverlayFunction = {
      type = "execute",
      name = L["Add Overlay"],
      order = 17.9,
      width = "double",
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
    WeakAuras.SetThumbnail(data);
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
  WeakAuras.AddCodeOption(options, data, L["Custom Trigger"], "custom_trigger", 10, hideCustomTrigger, appendToTriggerPath("custom"), false, true, extraSetFunction, nil, true);

  local function hideCustomVariables()
    return not (trigger.type == "custom" and trigger.custom_type == "stateupdate");
  end

  WeakAuras.AddCodeOption(options, data, '|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t' .. L["Custom Variables"], "custom_variables", 11, hideCustomVariables, appendToTriggerPath("customVariables"), false, true, extraSetFunctionReload, nil, true);

  local function hideCustomUntrigger()
    return not (trigger.type == "custom"
      and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom")))
  end
  WeakAuras.AddCodeOption(options, data, L["Custom Untrigger"], "custom_untrigger", 14, hideCustomUntrigger, appendToUntriggerPath("custom"), false, true, extraSetFunction);

  local function hideCustomDuration()
    return not (trigger.type == "custom"
      and (trigger.custom_type == "status"
           or (trigger.custom_type == "event" and (trigger.custom_hide ~= "timed" or trigger.dynamicDuration))))
  end
  WeakAuras.AddCodeOption(options, data, L["Duration Info"], "custom_duration", 16, hideCustomDuration, appendToTriggerPath("customDuration"), false, true, extraSetFunctionReload);

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

    WeakAuras.AddCodeOption(options, data, string.format(L["Overlay %s Info"], i), "custom_overlay" .. i, 17 + i / 10, hideOverlay, appendToTriggerPath("customOverlay" .. i), false, true, extraSetFunctionReload, extraFunctions);
  end

  WeakAuras.AddCodeOption(options, data, L["Name Info"], "custom_name", 18, hideIfTriggerStateUpdate, appendToTriggerPath("customName"), false, true, extraSetFunction);
  WeakAuras.AddCodeOption(options, data, L["Icon Info"], "custom_icon", 20, hideIfTriggerStateUpdate, appendToTriggerPath("customIcon"), false, true, extraSetFunction);
  WeakAuras.AddCodeOption(options, data, L["Texture Info"], "custom_texture", 22, hideIfTriggerStateUpdate, appendToTriggerPath("customTexture"), false, true, extraSetFunction);
  WeakAuras.AddCodeOption(options, data, L["Stack Info"], "custom_stacks", 23, hideIfTriggerStateUpdate, appendToTriggerPath("customStacks"), false, true, extraSetFunction);

  return options;
end
