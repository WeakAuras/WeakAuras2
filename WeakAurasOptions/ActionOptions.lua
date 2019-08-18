if not WeakAuras.IsCorrectVersion() then return end

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
          if (info.type == "color") then
            if type(data.actions[field][value]) == "table" then
              local c = data.actions[field][value]
              return c[1], c[2], c[3], c[4];
            else
              return 1, 1, 1, 1
            end
          else
            return data.actions[field][value];
          end
        else
          return nil;
        end
      end
    end,
    set = function(info, v, g, b, a)
      local split = info[#info]:find("_");
      local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
      data.actions = data.actions or {};
      data.actions[field] = data.actions[field] or {};
      if (info.type == "color") then
        if not data.actions[field][value] or type(data.actions[field][value]) ~= "table" then
          data.actions[field][value] = {}
        end
        local c = data.actions[field][value]
        c[1], c[2], c[3], c[4] = v, g, b, a;
      else
        data.actions[field][value] = v;
      end
      if(value == "sound" or value == "sound_path") then
        pcall(PlaySoundFile, v, "Master");
      elseif(value == "sound_kit_id") then
        pcall(PlaySound, v, "Master");
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
        width = WeakAuras.doubleWidth
      },
      -- texteditor added here by AddCodeOption
      start_header = {
        type = "header",
        name = L["On Show"],
        order = 0.5
      },
      start_do_message = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Chat Message"],
        order = 1
      },
      start_message_type = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Message Type"],
        order = 2,
        values = send_chat_message_types,
        disabled = function() return not data.actions.start.do_message end,
        control = "WeakAurasSortedDropdown"
      },
      start_message_space = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = "",
        order = 3,
        image = function() return "", 0, 0 end,
        hidden = function() return not(data.actions.start.message_type == "WHISPER" or data.actions.start.message_type == "CHANNEL" or data.actions.start.message_type == "COMBAT" or data.actions.start.message_type == "PRINT") end
      },
      start_message_color = {
        type = "color",
        width = WeakAuras.normalWidth,
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
        width = WeakAuras.normalWidth,
        name = L["Send To"],
        order = 4,
        disabled = function() return not data.actions.start.do_message end,
        hidden = function() return data.actions.start.message_type ~= "WHISPER" end
      },
      start_message_channel = {
        type = "input",
        width = WeakAuras.normalWidth,
        name = L["Channel Number"],
        order = 4,
        disabled = function() return not data.actions.start.do_message end,
        hidden = function() return data.actions.start.message_type ~= "CHANNEL" end
      },
      start_message = {
        type = "input",
        width = WeakAuras.doubleWidth,
        name = L["Message"],
        order = 5,
        disabled = function() return not data.actions.start.do_message end,
        desc = function()
          return L["Dynamic text tooltip"] .. WeakAuras.GetAdditionalProperties(data)
        end,
      },
      -- texteditor added later
      start_do_sound = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Play Sound"],
        order = 7
      },
      start_do_loop = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Loop"],
        order = 7.1,
        disabled = function() return not data.actions.start.do_sound end,
      },
      start_sound_repeat = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["Repeat After"],
        order = 7.2,
        hidden = function() return not data.actions.start.do_loop end,
        disabled = function() return not data.actions.start.do_sound end,
      },
      start_sound_repeat_space = {
        type = "description",
        width = WeakAuras.normalWidth,
        order = 7.3,
        name = "",
        hidden = function() return not data.actions.start.do_loop end,
      },
      start_sound = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Sound"],
        order = 8,
        values = sound_types,
        disabled = function() return not data.actions.start.do_sound end,
        control = "WeakAurasSortedDropdown"
      },
      start_sound_channel = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Sound Channel"],
        order = 8.5,
        values = WeakAuras.sound_channel_types,
        disabled = function() return not data.actions.start.do_sound end,
        get = function() return data.actions.start.sound_channel or "Master" end
      },
      start_sound_path = {
        type = "input",
        width = WeakAuras.doubleWidth,
        name = L["Sound File Path"],
        order = 9,
        hidden = function() return data.actions.start.sound ~= " custom" end,
        disabled = function() return not data.actions.start.do_sound end
      },
      start_sound_kit_id = {
        type = "input",
        width = WeakAuras.doubleWidth,
        name = L["Sound Kit ID"],
        order = 9,
        hidden = function() return data.actions.start.sound ~= " KitID" end,
        disabled = function() return not data.actions.start.do_sound end
      },
      start_do_glow = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Button Glow"],
        order = 10.1
      },
      start_glow_action = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Glow Action"],
        order = 10.2,
        values = WeakAuras.glow_action_types,
        disabled = function() return not data.actions.start.do_glow end
      },
      start_glow_frame = {
        type = "input",
        width = WeakAuras.normalWidth,
        name = L["Frame"],
        order = 10.3,
        hidden = function() return not data.actions.start.do_glow end
      },
      start_choose_glow_frame = {
        type = "execute",
        width = WeakAuras.normalWidth,
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
      start_glow_type = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Glow Type"],
        order = 10.5,
        values = WeakAuras.glow_types,
        hidden = function() return not data.actions.start.do_glow end,
      },
      start_glow_type_spacer = {
        type = "description",
        width = WeakAuras.doubleWidth,
        name = "",
        order = 10.6,
        hidden = function() return not data.actions.start.do_glow end,
      },
      start_use_glow_color = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Glow Color"],
        order = 10.7,
        hidden = function() return not data.actions.start.do_glow end,
      },
      start_glow_color = {
        type = "color",
        width = WeakAuras.normalWidth,
        name = L["Glow Color"],
        order = 10.8,
        hidden = function() return not data.actions.start.do_glow end,
        disabled = function() return not data.actions.start.use_glow_color end,
      },
      start_do_custom = {
        type = "toggle",
        width = WeakAuras.doubleWidth,
        name = L["Custom"],
        order = 11,
      },
      -- texteditor added laters
      finish_header = {
        type = "header",
        name = L["On Hide"],
        order = 20.5
      },
      finish_do_message = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Chat Message"],
        order = 21
      },
      finish_message_type = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Message Type"],
        order = 22,
        values = send_chat_message_types,
        disabled = function() return not data.actions.finish.do_message end,
        control = "WeakAurasSortedDropdown"
      },
      finish_message_space = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = "",
        order = 23,
        image = function() return "", 0, 0 end,
        hidden = function() return not(data.actions.finish.message_type == "WHISPER" or data.actions.finish.message_type == "CHANNEL") end
      },
      finish_message_color = {
        type = "color",
        width = WeakAuras.normalWidth,
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
        width = WeakAuras.normalWidth,
        name = L["Send To"],
        order = 24,
        disabled = function() return not data.actions.finish.do_message end,
        hidden = function() return data.actions.finish.message_type ~= "WHISPER" end
      },
      finish_message_channel = {
        type = "input",
        width = WeakAuras.normalWidth,
        name = L["Channel Number"],
        order = 24,
        disabled = function() return not data.actions.finish.do_message end,
        hidden = function() return data.actions.finish.message_type ~= "CHANNEL" end
      },
      finish_message = {
        type = "input",
        width = WeakAuras.doubleWidth,
        name = L["Message"],
        order = 25,
        disabled = function() return not data.actions.finish.do_message end,
        desc = function()
          return L["Dynamic text tooltip"] .. WeakAuras.GetAdditionalProperties(data)
        end,
      },
      -- texteditor added below
      finish_do_sound = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Play Sound"],
        order = 27
      },
      finish_sound = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Sound"],
        order = 28,
        values = sound_types,
        disabled = function() return not data.actions.finish.do_sound end,
        control = "WeakAurasSortedDropdown"
      },
      finish_sound_channel = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Sound Channel"],
        order = 28.5,
        values = WeakAuras.sound_channel_types,
        disabled = function() return not data.actions.finish.do_sound end,
        get = function() return data.actions.finish.sound_channel or "Master" end
      },
      finish_sound_path = {
        type = "input",
        width = WeakAuras.doubleWidth,
        name = L["Sound File Path"],
        order = 29,
        hidden = function() return data.actions.finish.sound ~= " custom" end,
        disabled = function() return not data.actions.finish.do_sound end
      },
      finish_sound_kit_id = {
        type = "input",
        width = WeakAuras.doubleWidth,
        name = L["Sound Kit ID"],
        order = 29,
        hidden = function() return data.actions.finish.sound ~= " KitID" end,
        disabled = function() return not data.actions.finish.do_sound end
      },
      finish_stop_sound = {
        type = "toggle",
        width = WeakAuras.doubleWidth,
        name = L["Stop Sound"],
        order = 29.1,
      },
      finish_do_glow = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Button Glow"],
        order = 30.1
      },
      finish_glow_action = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Glow Action"],
        order = 30.2,
        values = WeakAuras.glow_action_types,
        disabled = function() return not data.actions.finish.do_glow end
      },
      finish_glow_frame = {
        type = "input",
        width = WeakAuras.normalWidth,
        name = L["Frame"],
        order = 30.3,
        hidden = function() return not data.actions.finish.do_glow end
      },
      finish_choose_glow_frame = {
        type = "execute",
        width = WeakAuras.normalWidth,
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
      finish_glow_type = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Glow Type"],
        order = 30.5,
        values = WeakAuras.glow_types,
        hidden = function() return not data.actions.finish.do_glow end,
      },
      finish_glow_type_spacer = {
        type = "description",
        width = WeakAuras.doubleWidth,
        name = "",
        order = 30.6,
        hidden = function() return not data.actions.finish.do_glow end,
      },
      finish_use_glow_color = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Glow Color"],
        order = 30.7,
        hidden = function() return not data.actions.finish.do_glow end,
      },
      finish_glow_color = {
        type = "color",
        width = WeakAuras.normalWidth,
        name = L["Glow Color"],
        order = 30.8,
        hidden = function() return not data.actions.finish.do_glow end,
        disabled = function() return not data.actions.finish.use_glow_color end,
      },
      finish_do_custom = {
        type = "toggle",
        width = WeakAuras.doubleWidth,
        name = L["Custom"],
        order = 31,
      },
    -- Text editor added below
    },
  }

  WeakAuras.AddCodeOption(action.args, data, L["Custom Code"], "init", 0.011, function() return not data.actions.init.do_custom end, {"actions", "init", "custom"}, true);

  WeakAuras.AddCodeOption(action.args, data, L["Custom Code"], "start_message", 5.1, function() return not (data.actions.start.do_message and WeakAuras.ContainsCustomPlaceHolder(data.actions.start.message)) end, {"actions", "start", "message_custom"}, false);
  WeakAuras.AddCodeOption(action.args, data, L["Custom Code"], "start", 13, function() return not data.actions.start.do_custom end, {"actions", "start", "custom"}, true);

  WeakAuras.AddCodeOption(action.args, data, L["Custom Code"], "finish_message", 26, function() return not (data.actions.finish.do_message and WeakAuras.ContainsCustomPlaceHolder(data.actions.finish.message)) end, {"actions", "finish", "message_custom"}, false);
  WeakAuras.AddCodeOption(action.args, data, L["Custom Code"], "finish", 32, function() return not data.actions.finish.do_custom end, {"actions", "finish", "custom"}, true);

  return action;
end
