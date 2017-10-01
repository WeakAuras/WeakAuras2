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
      hidden = function() return not (trigger.type == "event" and trigger.event == "Combat Log"); end
    },
    subeventSuffix = {
      type = "select",
      name = L["Message Suffix"],
      order = 9,
      values = subevent_suffix_types,
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
      hidden = function() return not (trigger.type == "custom") end
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
      order = 8,
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
      order = 9,
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
      order = 9,
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
    custom_trigger = {
      type = "input",
      name = L["Custom Trigger"],
      order = 10,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom") end,
      get = function() return trigger.custom end,
      set = function(info, v)
        trigger.custom = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      control = "WeakAurasMultiLineEditBox"
    },
    custom_trigger_expand = {
      type = "execute",
      order = 10.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("custom"), nil, true)
      end,
      hidden = function() return not (trigger.type == "custom") end,
    },
    custom_trigger_error = {
      type = "description",
      name = function()
        if not(trigger.custom) then
          return "";
        end
        local _, errorString = loadstring("return "..trigger.custom);
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 11,
      hidden = function()
        if not(trigger.type == "custom" and trigger.custom) then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..trigger.custom);
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
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
    duration = {
      type = "input",
      name = L["Duration (s)"],
      order = 13,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type == "event" and trigger.custom_hide ~= "custom") end,
    },
    custom_untrigger = {
      type = "input",
      name = L["Custom Untrigger"],
      order = 14,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom"))) end,
      get = function() return untrigger and untrigger.custom end,
      set = function(info, v)
        if(untrigger) then
          untrigger.custom = v;
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      control = "WeakAurasMultiLineEditBox"
    },
    custom_untrigger_expand = {
      type = "execute",
      order = 14.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToUntriggerPath("custom"), nil, true)
      end,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom"))) end,
    },
    custom_untrigger_error = {
      type = "description",
      name = function()
        if not(untrigger and untrigger.custom) then
          return "";
        end
        local _, errorString = loadstring("return "..(untrigger and untrigger.custom or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 15,
      hidden = function()
        if not(trigger.type == "custom" and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide == "custom")) and untrigger and untrigger.custom) then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(untrigger and untrigger.custom or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_duration = {
      type = "input",
      name = L["Duration Info"],
      order = 16,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide ~= "timed")))
      end,
      get = function() return trigger.customDuration end,
      set = function(info, v)
        trigger.customDuration = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      control = "WeakAurasMultiLineEditBox"
    },
    custom_duration_expand = {
      type = "execute",
      order = 16.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customDuration"), nil, true)
      end,
      hidden = function() return not (trigger.type == "custom"
        and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide ~= "timed")))
      end,
    },
    custom_duration_error = {
      type = "description",
      name = function()
        if not(trigger.type == "custom"
          and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide ~= "timed"))
          and trigger.customDuration and trigger.customDuration ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customDuration or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 17,
      hidden = function()
        if not(trigger.type == "custom"
          and (trigger.custom_type == "status" or (trigger.custom_type == "event" and trigger.custom_hide ~= "timed"))
          and trigger.customDuration and trigger.customDuration ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customDuration or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_name = {
      type = "input",
      name = L["Name Info"],
      order = 18,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
      get = function() return trigger.customName end,
      set = function(info, v)
        trigger.customName = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      control = "WeakAurasMultiLineEditBox"
    },
    custom_name_expand = {
      type = "execute",
      order = 18.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customName"), nil, true)
      end,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
    },
    custom_name_error = {
      type = "description",
      name = function()
        if not(trigger.customName and trigger.customName ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customName or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 19,
      hidden = function()
        if not(trigger.type == "custom" and trigger.custom_type ~= "stateupdate" and trigger.customName and trigger.customName ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customName or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_icon = {
      type = "input",
      name = L["Icon Info"],
      order = 20,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
      get = function() return trigger.customIcon end,
      set = function(info, v)
        trigger.customIcon = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      control = "WeakAurasMultiLineEditBox"
    },
    custom_icon_expand = {
      type = "execute",
      order = 20.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customIcon"), nil, true)
      end,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
    },
    custom_icon_error = {
      type = "description",
      name = function()
        if not(trigger.customIcon and trigger.customIcon ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customIcon or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 21,
      hidden = function()
        if not(trigger.type == "custom" and trigger.custom_type ~= "stateupdate" and trigger.customIcon and trigger.customIcon ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customIcon or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_texture = {
      type = "input",
      name = L["Texture Info"],
      order = 21.5,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
      get = function() return trigger.customTexture end,
      set = function(info, v)
        trigger.customTexture = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      control = "WeakAurasMultiLineEditBox"
    },
    custom_texture_expand = {
      type = "execute",
      order = 22,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customTexture"), nil, true)
      end,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
    },
    custom_texture_error = {
      type = "description",
      name = function()
        if not(trigger.customTexture and trigger.custom_type ~= "stateupdate" and trigger.customTexture ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customTexture or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 22.5,
      hidden = function()
        if not(trigger.type == "custom" and trigger.custom_type ~= "stateupdate" and trigger.customTexture and trigger.customTexture ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customTexture or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    },
    custom_stacks = {
      type = "input",
      name = L["Stack Info"],
      order = 23,
      multiline = true,
      width = "normal",
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
      get = function() return trigger.customStacks end,
      set = function(info, v)
        trigger.customStacks = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.UpdateDisplayButton(data);
      end,
      control = "WeakAurasMultiLineEditBox"
    },
    custom_stacks_expand = {
      type = "execute",
      order = 23.5,
      name = L["Expand Text Editor"],
      func = function()
        WeakAuras.OpenTextEditor(data, appendToTriggerPath("customStacks"), nil, true)
      end,
      hidden = function() return not (trigger.type == "custom" and trigger.custom_type ~= "stateupdate") end,
    },
    custom_stacks_error = {
      type = "description",
      name = function()
        if not(trigger.customStacks and trigger.custom_type ~= "stateupdate" and trigger.customStacks ~= "") then
          return "";
        end
        local _, errorString = loadstring("return "..(trigger.customStacks or ""));
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = "double",
      order = 24,
      hidden = function()
        if not(trigger.type == "custom" and trigger.customStacks and trigger.customStacks ~= "") then
          return true;
        else
          local loadedFunction, errorString = loadstring("return "..(trigger.customStacks or ""));
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      end
    }
  };
  return options;
end
