
local L = WeakAuras.L


local send_chat_message_types = WeakAuras.send_chat_message_types;
local sound_types = WeakAuras.sound_types;

function WeakAuras.AddActionOption(id, data)
  local action = {
    type = "group",
    name = L["Actions"],
    order = 50,
    get = function(info)
      local split = info[#info]:find("_");
      if(split) then
        local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
        if(data.actions and data.actions[field]) then
          return data.actions[field][value];
        else
          return nil;
        end
      end
    end,
    set = function(info, v)
      local split = info[#info]:find("_");
      local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
      data.actions = data.actions or {};
      data.actions[field] = data.actions[field] or {};
      data.actions[field][value] = v;
      if(value == "sound" or value == "sound_path") then
        PlaySoundFile(v, data.actions.start.sound_channel or "Master");
      elseif(value == "sound_kit_id") then
        PlaySound(v, data.actions.start.sound_channel or "Master");
      end
      WeakAuras.Add(data);
    end,
    args = {
      init_header = {
        type = "header",
        name = L["On Init"],
        order = 0.005
      },
      init_do_custom = {
        type = "toggle",
        name = L["Custom"],
        order = 0.011,
        width = "double"
      },
      init_custom = {
        type = "input",
        width = "normal",
        name = L["Custom Code"],
        order = 0.013,
        multiline = true,
        hidden = function() return not data.actions.init.do_custom end,
        control = "WeakAurasMultiLineEditBox"
      },
      init_expand = {
        type = "execute",
        order = 0.014,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"actions", "init", "custom"}, true)
        end,
        hidden = function() return not data.actions.init.do_custom end
      },
      init_customError = {
        type = "description",
        name = function()
          if not(data.actions.init.custom) then
            return "";
          end
          local _, errorString = loadstring("return function() "..data.actions.init.custom.."\n end");
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 0.015,
        hidden = function()
          if not(data.actions.init.do_custom and data.actions.init.custom) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return function() "..data.actions.init.custom.."\n end");
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      start_header = {
        type = "header",
        name = L["On Show"],
        order = 0.5
      },
      start_do_message = {
        type = "toggle",
        name = L["Chat Message"],
        order = 1
      },
      start_message_type = {
        type = "select",
        name = L["Message Type"],
        order = 2,
        values = send_chat_message_types,
        disabled = function() return not data.actions.start.do_message end,
        control = "WeakAurasSortedDropdown"
      },
      start_message_space = {
        type = "execute",
        name = "",
        order = 3,
        image = function() return "", 0, 0 end,
        hidden = function() return not(data.actions.start.message_type == "WHISPER" or data.actions.start.message_type == "CHANNEL" or data.actions.start.message_type == "COMBAT" or data.actions.start.message_type == "PRINT") end
      },
      start_message_color = {
        type = "color",
        name = L["Color"],
        order = 3,
        hasAlpha = false,
        hidden = function() return not(data.actions.start.message_type == "COMBAT" or data.actions.start.message_type == "PRINT") end,
        get = function() return data.actions.start.r or 1, data.actions.start.g or 1, data.actions.start.b or 1 end,
        set = function(info, r, g, b)
          data.actions.start.r = r;
          data.actions.start.g = g;
          data.actions.start.b = b;
          WeakAuras.Add(data);
        end
      },
      start_message_dest = {
        type = "input",
        name = L["Send To"],
        order = 4,
        disabled = function() return not data.actions.start.do_message end,
        hidden = function() return data.actions.start.message_type ~= "WHISPER" end
      },
      start_message_channel = {
        type = "input",
        name = L["Channel Number"],
        order = 4,
        disabled = function() return not data.actions.start.do_message end,
        hidden = function() return data.actions.start.message_type ~= "CHANNEL" end
      },
      start_message = {
        type = "input",
        name = L["Message"],
        width = "double",
        order = 5,
        disabled = function() return not data.actions.start.do_message end,
        desc = function()
          local ret = L["Dynamic text tooltip"];
          ret = ret .. WeakAuras.GetAdditionalProperties(data);
          return ret
        end,
      },
      start_message_custom = {
        type = "input",
        width = "normal",
        name = L["Custom Code"],
        order = 5.1,
        multiline = true,
        hidden = function()
          return not (data.actions.start.do_message and WeakAuras.ContainsPlaceHolders(data.actions.start.message, "c"))
        end,
        control = "WeakAurasMultiLineEditBox",
      },
      start_message_custom_expand = {
        type = "execute",
        order = 5.2,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"actions", "start", "message_custom"});
        end,
        hidden = function()
          return not (data.actions.start.do_message and WeakAuras.ContainsPlaceHolders(data.actions.start.message, "c"))
        end,
      },
      start_message_error = {
        type = "description",
        name = function()
          local custom = data.actions.start.message_custom;
          if not custom then
            return "";
          end
          local _, errorString = loadstring("return  " .. custom);
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 5.3,
        hidden = function()
          local message = data.actions.start.message;
          if (not message) then
            return true;
          end
          if (not WeakAuras.ContainsPlaceHolders(message, "c")) then
            return true;
          end

          local custom = data.actions.start.message_custom;

          if (not custom) then
            return true;
          end

          local loadedFunction, errorString = loadstring("return " .. custom);
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      },
      start_do_sound = {
        type = "toggle",
        name = L["Play Sound"],
        order = 7
      },
      start_do_loop = {
        type = "toggle",
        name = L["Loop"],
        order = 7.1,
        disabled = function() return not data.actions.start.do_sound end,
      },
      start_sound_repeat = {
        type = "range",
        name = L["Repeat After"],
        order = 7.2,
        hidden = function() return not data.actions.start.do_loop end,
        disabled = function() return not data.actions.start.do_sound end,
      },
      start_sound_repeat_space = {
        type = "description",
        order = 7.3,
        width = "normal",
        name = "",
        hidden = function() return not data.actions.start.do_loop end,
      },
      start_sound = {
        type = "select",
        name = L["Sound"],
        order = 8,
        values = sound_types,
        disabled = function() return not data.actions.start.do_sound end,
        control = "WeakAurasSortedDropdown"
      },
      start_sound_channel = {
        type = "select",
        name = L["Sound Channel"],
        order = 8.5,
        values = WeakAuras.sound_channel_types,
        disabled = function() return not data.actions.start.do_sound end,
        get = function() return data.actions.start.sound_channel or "Master" end
      },
      start_sound_path = {
        type = "input",
        name = L["Sound File Path"],
        order = 9,
        width = "double",
        hidden = function() return data.actions.start.sound ~= " custom" end,
        disabled = function() return not data.actions.start.do_sound end
      },
      start_sound_kit_id = {
        type = "input",
        name = L["Sound Kit ID"],
        order = 9,
        width = "double",
        hidden = function() return data.actions.start.sound ~= " KitID" end,
        disabled = function() return not data.actions.start.do_sound end
      },
      start_do_glow = {
        type = "toggle",
        name = L["Button Glow"],
        order = 10.1
      },
      start_glow_action = {
        type = "select",
        name = L["Glow Action"],
        order = 10.2,
        values = WeakAuras.glow_action_types,
        disabled = function() return not data.actions.start.do_glow end
      },
      start_glow_frame = {
        type = "input",
        name = L["Frame"],
        order = 10.3,
        hidden = function() return not data.actions.start.do_glow end
      },
      start_choose_glow_frame = {
        type = "execute",
        name = L["Choose"],
        order = 10.4,
        hidden = function() return not data.actions.start.do_glow end,
        func = function()
          if(data.controlledChildren and data.controlledChildren[1]) then
            WeakAuras.PickDisplay(data.controlledChildren[1]);
            WeakAuras.StartFrameChooser(WeakAuras.GetData(data.controlledChildren[1]), {"actions", "start", "glow_frame"});
          else
            WeakAuras.StartFrameChooser(data, {"actions", "start", "glow_frame"});
          end
        end
      },
      start_do_custom = {
        type = "toggle",
        name = L["Custom"],
        order = 11,
        width = "double"
      },
      start_custom = {
        type = "input",
        width = "normal",
        name = L["Custom Code"],
        order = 13,
        multiline = true,
        hidden = function() return not data.actions.start.do_custom end,
        control = "WeakAurasMultiLineEditBox"
      },
      start_expand = {
        type = "execute",
        order = 14,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"actions", "start", "custom"}, true)
        end,
        hidden = function() return not data.actions.start.do_custom end
      },
      start_customError = {
        type = "description",
        name = function()
          if not(data.actions.start.custom) then
            return "";
          end
          local _, errorString = loadstring("return function() "..data.actions.start.custom.."\n end");
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 15,
        hidden = function()
          if not(data.actions.start.do_custom and data.actions.start.custom) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return function() "..data.actions.start.custom.."\n end");
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      finish_header = {
        type = "header",
        name = L["On Hide"],
        order = 20.5
      },
      finish_do_message = {
        type = "toggle",
        name = L["Chat Message"],
        order = 21
      },
      finish_message_type = {
        type = "select",
        name = L["Message Type"],
        order = 22,
        values = send_chat_message_types,
        disabled = function() return not data.actions.finish.do_message end,
        control = "WeakAurasSortedDropdown"
      },
      finish_message_space = {
        type = "execute",
        name = "",
        order = 23,
        image = function() return "", 0, 0 end,
        hidden = function() return not(data.actions.finish.message_type == "WHISPER" or data.actions.finish.message_type == "CHANNEL") end
      },
      finish_message_color = {
        type = "color",
        name = L["Color"],
        order = 23,
        hasAlpha = false,
        hidden = function() return not(data.actions.finish.message_type == "COMBAT" or data.actions.finish.message_type == "PRINT") end,
        get = function() return data.actions.finish.r or 1, data.actions.finish.g or 1, data.actions.finish.b or 1 end,
        set = function(info, r, g, b)
          data.actions.finish.r = r;
          data.actions.finish.g = g;
          data.actions.finish.b = b;
          WeakAuras.Add(data);
        end
      },
      finish_message_dest = {
        type = "input",
        name = L["Send To"],
        order = 24,
        disabled = function() return not data.actions.finish.do_message end,
        hidden = function() return data.actions.finish.message_type ~= "WHISPER" end
      },
      finish_message_channel = {
        type = "input",
        name = L["Channel Number"],
        order = 24,
        disabled = function() return not data.actions.finish.do_message end,
        hidden = function() return data.actions.finish.message_type ~= "CHANNEL" end
      },
      finish_message = {
        type = "input",
        name = L["Message"],
        width = "double",
        order = 25,
        disabled = function() return not data.actions.finish.do_message end,
        desc = function()
          local ret = L["Dynamic text tooltip"];
          ret = ret .. WeakAuras.GetAdditionalProperties(data);
          return ret
        end,
      },
      finish_message_custom = {
        type = "input",
        width = "normal",
        name = L["Custom Code"],
        order = 25.1,
        multiline = true,
        hidden = function()
          return not (data.actions.finish.do_message and WeakAuras.ContainsPlaceHolders(data.actions.finish.message, "c"))
        end,
        control = "WeakAurasMultiLineEditBox",
      },
      finish_message_custom_expand = {
        type = "execute",
        order = 25.2,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"actions", "finish", "message_custom"});
        end,
        hidden = function()
          return not (data.actions.finish.do_message and WeakAuras.ContainsPlaceHolders(data.actions.finish.message, "c"))
        end,
      },
      finish_message_error = {
        type = "description",
        name = function()
          local custom = data.actions.finish.message_custom;
          if not custom then
            return "";
          end
          local _, errorString = loadstring("return  " .. custom);
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 25.3,
        hidden = function()
          local message = data.actions.finish.message;
          if (not message) then
            return true;
          end
          if (not WeakAuras.ContainsPlaceHolders(message, "c")) then
            return true;
          end

          local custom = data.actions.finish.message_custom;
          if (not custom) then
            return true;
          end

          local loadedFunction, errorString = loadstring("return " .. custom);
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      },
      finish_do_sound = {
        type = "toggle",
        name = L["Play Sound"],
        order = 27
      },
      finish_sound = {
        type = "select",
        name = L["Sound"],
        order = 28,
        values = sound_types,
        disabled = function() return not data.actions.finish.do_sound end,
        control = "WeakAurasSortedDropdown"
      },
      finish_sound_channel = {
        type = "select",
        name = L["Sound Channel"],
        order = 28.5,
        values = WeakAuras.sound_channel_types,
        disabled = function() return not data.actions.finish.do_sound end,
        get = function() return data.actions.finish.sound_channel or "Master" end
      },
      finish_sound_path = {
        type = "input",
        name = L["Sound File Path"],
        order = 29,
        width = "double",
        hidden = function() return data.actions.finish.sound ~= " custom" end,
        disabled = function() return not data.actions.finish.do_sound end
      },
      finish_sound_kit_id = {
        type = "input",
        name = L["Sound Kit ID"],
        order = 29,
        width = "double",
        hidden = function() return data.actions.finish.sound ~= " KitID" end,
        disabled = function() return not data.actions.finish.do_sound end
      },
    finish_stop_sound = {
      type = "toggle",
      name = L["Stop Sound"],
      order = 29.1,
      width = "double"
    },
    finish_do_glow = {
      type = "toggle",
      name = L["Button Glow"],
      order = 30.1
    },
    finish_glow_action = {
      type = "select",
      name = L["Glow Action"],
      order = 30.2,
      values = WeakAuras.glow_action_types,
      disabled = function() return not data.actions.finish.do_glow end
    },
    finish_glow_frame = {
      type = "input",
      name = L["Frame"],
      order = 30.3,
      hidden = function() return not data.actions.finish.do_glow end
    },
    finish_choose_glow_frame = {
      type = "execute",
      name = L["Choose"],
      order = 30.4,
      hidden = function() return not data.actions.finish.do_glow end,
      func = function()
        if(data.controlledChildren and data.controlledChildren[1]) then
          WeakAuras.PickDisplay(data.controlledChildren[1]);
          WeakAuras.StartFrameChooser(WeakAuras.GetData(data.controlledChildren[1]), {"actions", "finish", "glow_frame"});
        else
          WeakAuras.StartFrameChooser(data, {"actions", "finish", "glow_frame"});
        end
      end
      },
      finish_do_custom = {
        type = "toggle",
        name = L["Custom"],
        order = 31,
        width = "double"
      },
      finish_custom = {
        type = "input",
        name = L["Custom Code"],
        order = 33,
        multiline = true,
        width = "normal",
        hidden = function() return not data.actions.finish.do_custom end,
        control = "WeakAurasMultiLineEditBox"
      },
      finish_expand = {
        type = "execute",
        order = 34,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"actions", "finish", "custom"}, true)
        end,
        hidden = function() return not data.actions.finish.do_custom end
      },
      finish_customError = {
        type = "description",
        name = function()
          if not(data.actions.finish.custom) then
            return "";
          end
          local _, errorString = loadstring("return function() "..data.actions.finish.custom.."\n end");
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 35,
        hidden = function()
          if not(data.actions.finish.do_custom and data.actions.finish.custom) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return function() "..data.actions.finish.custom.."\n end");
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
    },
  }

  WeakAuras.AddCodeOption(action.args, data, "init", 0.011, function() return not data.actions.init.do_custom end, {"actions", "init", "custom"}, true);

  return action;
end
