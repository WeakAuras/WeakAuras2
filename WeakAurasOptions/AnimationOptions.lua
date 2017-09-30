
local L = WeakAuras.L

local anim_types = WeakAuras.anim_types;
local anim_translate_types = WeakAuras.anim_translate_types;
local anim_scale_types = WeakAuras.anim_scale_types;
local anim_alpha_types = WeakAuras.anim_alpha_types;
local anim_rotate_types = WeakAuras.anim_rotate_types;
local anim_color_types = WeakAuras.anim_color_types;
local anim_start_preset_types = WeakAuras.anim_start_preset_types;
local anim_main_preset_types = WeakAuras.anim_main_preset_types;
local anim_finish_preset_types = WeakAuras.anim_finish_preset_types;
local duration_types = WeakAuras.duration_types;
local duration_types_no_choice = WeakAuras.duration_types_no_choice;

local function filterAnimPresetTypes(intable, id)
  local ret = {};
  local region = WeakAuras.regions[id] and WeakAuras.regions[id].region;
  local regionType = WeakAuras.regions[id] and WeakAuras.regions[id].regionType;
  local data = WeakAuras.GetData(id);
  if(region and regionType and data) then
    for key, value in pairs(intable) do
      local preset = WeakAuras.anim_presets[key];
      if(preset) then
        if(regionType == "group" or regionType == "dynamicgroup") then
          local valid = true;
          for index, childId in pairs(data.controlledChildren) do
            local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region
            if(childRegion and ((preset.use_scale and not childRegion.Scale) or (preset.use_rotate and not childRegion.Rotate))) then
              valid = false;
            end
          end
          if(valid) then
            ret[key] = value;
          end
        else
          if not((preset.use_scale and not region.Scale) or (preset.use_rotate and not region.Rotate)) then
            ret[key] = value;
          end
        end
      end
    end
  end
  return ret;
end



function WeakAuras.AddAnimationOption(id, data)
  local animation = {
    type = "group",
    name = L["Animations"],
    order = 60,
    get = function(info)
      local split = info[#info]:find("_");
      if(split) then
        local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);

        if(data.animation and data.animation[field]) then
          return data.animation[field][value];
        else
          if(value == "scalex" or value == "scaley") then
            return 1;
          else
            return nil;
          end
        end
      end
    end,
    set = function(info, v)
      local split = info[#info]:find("_");
      local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
      data.animation = data.animation or {};
      data.animation[field] = data.animation[field] or {};
      data.animation[field][value] = v;
      if(field == "main" and not WeakAuras.IsAnimating("display", id)) then
        WeakAuras.Animate("display", data, "main", data.animation.main, WeakAuras.regions[id].region, false, nil, true);
        if(WeakAuras.clones[id]) then
          for cloneId, cloneRegion in pairs(WeakAuras.clones[id]) do
            WeakAuras.Animate("display", data, "main", data.animation.main, cloneRegion, false, nil, true, cloneId);
          end
        end
      end
      WeakAuras.Add(data);
    end,
    disabled = function(info, v)
      local split = info[#info]:find("_");
      local valueToType = {
        alphaType = "use_alpha",
        alpha = "use_alpha",
        translateType = "use_translate",
        x = "use_translate",
        y = "use_translate",
        scaleType = "use_scale",
        scalex = "use_scale",
        scaley = "use_scale",
        rotateType = "use_rotate",
        rotate = "use_rotate",
        colorType = "use_color",
        color = "use_color"
      }
      if(split) then
        local field, value = info[#info]:sub(1, split-1), info[#info]:sub(split+1);
        if(data.animation and data.animation[field]) then
          if(valueToType[value]) then
            return not data.animation[field][valueToType[value]];
          else
            return false;
          end
        else
          return true;
        end
      else
        return false;
      end
    end,
    args = {
      start_header = {
        type = "header",
        name = L["Start"],
        order = 30
      },
      start_type = {
        type = "select",
        name = L["Type"],
        order = 32,
        values = anim_types,
        disabled = false
      },
      start_preset = {
        type = "select",
        name = L["Preset"],
        order = 33,
        values = function() return filterAnimPresetTypes(anim_start_preset_types, id) end,
        hidden = function() return data.animation.start.type ~= "preset" end
      },
      start_duration_type_no_choice = {
        type = "select",
        name = L["Time in"],
        order = 33,
        width = "half",
        values = duration_types_no_choice,
        disabled = true,
        hidden = function() return data.animation.start.type ~= "custom" or WeakAuras.CanHaveDuration(data) end,
        get = function() return "seconds" end
      },
      start_duration_type = {
        type = "select",
        name = L["Time in"],
        order = 33,
        width = "half",
        values = duration_types,
        hidden = function() return data.animation.start.type ~= "custom" or not WeakAuras.CanHaveDuration(data) end
      },
      start_duration = {
        type = "input",
        name = function()
          if(data.animation.start.duration_type == "relative") then
            return L["% of Progress"];
          else
            return L["Duration (s)"];
          end
        end,
        desc = function()
          if(data.animation.start.duration_type == "relative") then
            return L["Animation relative duration description"];
          else
            return L["The duration of the animation in seconds."];
          end
        end,
        order = 33.5,
        width = "half",
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_use_alpha = {
        type = "toggle",
        name = L["Fade In"],
        order = 34,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_alphaType = {
        type = "select",
        name = L["Type"],
        order = 35,
        values = anim_alpha_types,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_alphaFunc = {
        type = "input",
        width = "normal",
        multiline = true,
        name = L["Custom Function"],
        order = 35.3,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.alphaType ~= "custom" or not data.animation.start.use_alpha end,
        get = function() return data.animation.start.alphaFunc; end,
        set = function(info, v) data.animation.start.alphaFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      start_alphaFunc_expand = {
        type = "execute",
        order = 35.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "start", "alphaFunc"})
        end,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.alphaType ~= "custom" or not data.animation.start.use_alpha end
      },
      start_alphaFuncError = {
        type = "description",
        name = function()
          if not(data.animation.start.alphaFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.start.alphaFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 35.6,
        hidden = function()
          if(data.animation.start.type ~= "custom" or data.animation.start.alphaType ~= "custom" or not data.animation.start.use_alpha) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.start.alphaFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      start_alpha = {
        type = "range",
        name = L["Alpha"],
        width = "double",
        order = 36,
        min = 0,
        max = 1,
        bigStep = 0.01,
        isPercent = true,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_use_translate = {
        type = "toggle",
        name = L["Slide In"],
        order = 38,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_translateType = {
        type = "select",
        name = L["Type"],
        order = 39,
        values = anim_translate_types,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_translateFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 39.3,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.translateType ~= "custom" or not data.animation.start.use_translate end,
        get = function() return data.animation.start.translateFunc; end,
        set = function(info, v) data.animation.start.translateFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      start_translateFunc_expand = {
        type = "execute",
        order = 39.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "start", "translateFunc"})
        end,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.translateType ~= "custom" or not data.animation.start.use_translate end,
      },
      start_translateFuncError = {
        type = "description",
        name = function()
          if not(data.animation.start.translateFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.start.translateFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 39.6,
        hidden = function()
          if(data.animation.start.type ~= "custom" or data.animation.start.translateType ~= "custom" or not data.animation.start.use_translate) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.start.translateFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      start_x = {
        type = "range",
        name = L["X Offset"],
        order = 40,
        softMin = -200,
        softMax = 200,
        step = 1,
        bigStep = 5,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_y = {
        type = "range",
        name = L["Y Offset"],
        order = 41,
        softMin = -200,
        softMax = 200,
        step = 1,
        bigStep = 5,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_use_scale = {
        type = "toggle",
        name = L["Zoom In"],
        order = 42,
        hidden = function()
          return (
            data.animation.start.type ~= "custom"
            or not WeakAuras.regions[id].region.Scale
            ) end
      },
      start_scaleType = {
        type = "select",
        name = L["Type"],
        order = 43,
        values = anim_scale_types,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      start_scaleFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 43.3,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.scaleType ~= "custom" or not (data.animation.start.use_scale and WeakAuras.regions[id].region.Scale) end,
        get = function() return data.animation.start.scaleFunc; end,
        set = function(info, v) data.animation.start.scaleFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      start_scaleFunc_expand = {
        type = "execute",
        order = 43.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "start", "scaleFunc"})
        end,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.scaleType ~= "custom" or not (data.animation.start.use_scale and WeakAuras.regions[id].region.Scale) end,
      },
      start_scaleFuncError = {
        type = "description",
        name = function()
          if not(data.animation.start.scaleFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.start.scaleFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 43.6,
        hidden = function()
          if(data.animation.start.type ~= "custom" or data.animation.start.scaleType ~= "custom" or not (data.animation.start.use_scale and WeakAuras.regions[id].region.Scale)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.start.scaleFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      start_scalex = {
        type = "range",
        name = L["X Scale"],
        order = 44,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      start_scaley = {
        type = "range",
        name = L["Y Scale"],
        order = 45,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      start_use_rotate = {
        type = "toggle",
        name = L["Rotate In"],
        order = 46,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      start_rotateType = {
        type = "select",
        name = L["Type"],
        order = 47,
        values = anim_rotate_types,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      start_rotateFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 47.3,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.rotateType ~= "custom" or not (data.animation.start.use_rotate and WeakAuras.regions[id].region.Rotate) end,
        get = function() return data.animation.start.rotateFunc; end,
        set = function(info, v) data.animation.start.rotateFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      start_rotateFunc_expand = {
        type = "execute",
        order = 47.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "start", "rotateFunc"})
        end,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.rotateType ~= "custom" or not (data.animation.start.use_rotate and WeakAuras.regions[id].region.Rotate) end,
      },
      start_rotateFuncError = {
        type = "description",
        name = function()
          if not(data.animation.start.rotateFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.start.rotateFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 47.6,
        hidden = function()
          if(data.animation.start.type ~= "custom" or data.animation.start.rotateType ~= "custom" or not (data.animation.start.use_rotate and WeakAuras.regions[id].region.Rotate)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.start.rotateFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      start_rotate = {
        type = "range",
        name = L["Angle"],
        width = "double",
        order = 48,
        softMin = 0,
        softMax = 360,
        bigStep = 3,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      start_use_color = {
        type = "toggle",
        name = L["Color"],
        order = 48.2,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
      },
      start_colorType = {
        type = "select",
        name = L["Type"],
        order = 48.5,
        values = anim_color_types,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
      },
      start_colorFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 48.7,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.colorType ~= "custom" or not (data.animation.start.use_color and WeakAuras.regions[id].region.Color) end,
        get = function() return data.animation.start.colorFunc; end,
        set = function(info, v) data.animation.start.colorFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      start_colorFunc_expand = {
        type = "execute",
        order = 48.8,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "start", "colorFunc"})
        end,
        hidden = function() return data.animation.start.type ~= "custom" or data.animation.start.colorType ~= "custom" or not (data.animation.start.use_color and WeakAuras.regions[id].region.Color) end,
      },
      start_colorFuncError = {
        type = "description",
        name = function()
          if not(data.animation.start.colorFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.start.colorFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 49,
        hidden = function()
          if(data.animation.start.type ~= "custom" or data.animation.start.colorType ~= "custom" or not (data.animation.start.use_color and WeakAuras.regions[id].region.Color)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.start.colorFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      start_color = {
        type = "color",
        name = L["Color"],
        width = "double",
        order = 49.5,
        hidden = function() return (data.animation.start.type ~= "custom" or not WeakAuras.regions[id].region.Color) end,
        get = function()
          return data.animation.start.colorR,
            data.animation.start.colorG,
            data.animation.start.colorB,
            data.animation.start.colorA;
        end,
        set = function(info, r, g, b, a)
          data.animation.start.colorR = r;
          data.animation.start.colorG = g;
          data.animation.start.colorB = b;
          data.animation.start.colorA = a;
        end
      },
      main_header = {
        type = "header",
        name = L["Main"],
        order = 50
      },
      main_type = {
        type = "select",
        name = L["Type"],
        order = 52,
        values = anim_types,
        disabled = false
      },
      main_preset = {
        type = "select",
        name = L["Preset"],
        order = 53,
        values = function() return filterAnimPresetTypes(anim_main_preset_types, id) end,
        hidden = function() return data.animation.main.type ~= "preset" end
      },
      main_duration_type_no_choice = {
        type = "select",
        name = L["Time in"],
        order = 53,
        width = "half",
        values = duration_types_no_choice,
        disabled = true,
        hidden = function() return data.animation.main.type ~= "custom" or WeakAuras.CanHaveDuration(data) end,
        get = function() return "seconds" end
      },
      main_duration_type = {
        type = "select",
        name = L["Time in"],
        order = 53,
        width = "half",
        values = duration_types,
        hidden = function() return data.animation.main.type ~= "custom" or not WeakAuras.CanHaveDuration(data) end
      },
      main_duration = {
        type = "input",
        name = function()
          if(data.animation.main.duration_type == "relative") then
            return L["% of Progress"];
          else
            return L["Duration (s)"];
          end
        end,
        desc = function()
          if(data.animation.main.duration_type == "relative") then
            return L["Animation relative duration description"];
          else
            local ret = "";
            ret = ret..L["The duration of the animation in seconds."].."\n";
            ret = ret..L["Unlike the start or finish animations, the main animation will loop over and over until the display is hidden."]
            return ret;
          end
        end,
        order = 53.5,
        width = "half",
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_use_alpha = {
        type = "toggle",
        name = L["Fade"],
        order = 54,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_alphaType = {
        type = "select",
        name = L["Type"],
        order = 55,
        values = anim_alpha_types,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_alphaFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 55.3,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.alphaType ~= "custom" or not data.animation.main.use_alpha end,
        get = function() return data.animation.main.alphaFunc; end,
        set = function(info, v) data.animation.main.alphaFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      main_alphaFunc_expand = {
        type = "execute",
        order = 55.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "main", "alphaFunc"})
        end,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.alphaType ~= "custom" or not data.animation.main.use_alpha end,
      },
      main_alphaFuncError = {
        type = "description",
        name = function()
          if not(data.animation.main.alphaFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.main.alphaFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 55.6,
        hidden = function()
          if(data.animation.main.type ~= "custom" or data.animation.main.alphaType ~= "custom" or not data.animation.main.use_alpha) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.main.alphaFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      main_alpha = {
      type = "range",
      name = L["Alpha"],
      width = "double",
      order = 56,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true,
      hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_use_translate = {
        type = "toggle",
        name = L["Slide"],
        order = 58,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_translateType = {
        type = "select",
        name = L["Type"],
        order = 59,
        values = anim_translate_types,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_translateFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 59.3,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.translateType ~= "custom" or not data.animation.main.use_translate end,
        get = function() return data.animation.main.translateFunc; end,
        set = function(info, v) data.animation.main.translateFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      main_translateFunc_expand = {
        type = "execute",
        order = 59.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "main", "translateFunc"})
        end,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.translateType ~= "custom" or not data.animation.main.use_translate end,
      },
      main_translateFuncError = {
        type = "description",
        name = function()
          if not(data.animation.main.translateFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.main.translateFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 59.6,
        hidden = function()
          if(data.animation.main.type ~= "custom" or data.animation.main.translateType ~= "custom" or not data.animation.main.use_translate) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.main.translateFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      main_x = {
        type = "range",
        name = L["X Offset"],
        order = 60,
        softMin = -200,
        softMax = 200,
        step = 1,
        bigStep = 5,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_y = {
        type = "range",
        name = L["Y Offset"],
        order = 61,
        softMin = -200,
        softMax = 200,
        step = 1,
        bigStep = 5,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_use_scale = {
        type = "toggle",
        name = L["Zoom"],
        order = 62,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      main_scaleType = {
        type = "select",
        name = L["Type"],
        order = 63,
        values = anim_scale_types,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      main_scaleFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 63.3,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.scaleType ~= "custom" or not (data.animation.main.use_scale and WeakAuras.regions[id].region.Scale) end,
        get = function() return data.animation.main.scaleFunc end,
        set = function(info, v) data.animation.main.scaleFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      main_scaleFunc_expand = {
        type = "execute",
        order = 63.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "main", "scaleFunc"})
        end,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.scaleType ~= "custom" or not (data.animation.main.use_scale and WeakAuras.regions[id].region.Scale) end,
      },
      main_scaleFuncError = {
        type = "description",
        name = function()
          if not(data.animation.main.scaleFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.main.scaleFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 63.6,
        hidden = function()
          if(data.animation.main.type ~= "custom" or data.animation.main.scaleType ~= "custom" or not (data.animation.main.use_scale and WeakAuras.regions[id].region.Scale)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.main.scaleFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      main_scalex = {
        type = "range",
        name = L["X Scale"],
        order = 64,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      main_scaley = {
        type = "range",
        name = L["Y Scale"],
        order = 65,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      main_use_rotate = {
        type = "toggle",
        name = L["Rotate"],
        order = 66,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      main_rotateType = {
        type = "select",
        name = L["Type"],
        order = 67,
        values = anim_rotate_types,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      main_rotateFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 67.3,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.rotateType ~= "custom" or not (data.animation.main.use_rotate and WeakAuras.regions[id].region.Rotate) end,
        get = function() return data.animation.main.rotateFunc end,
        set = function(info, v) data.animation.main.rotateFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      main_rotateFunc_expand = {
        type = "execute",
        order = 67.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "main", "rotateFunc"})
        end,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.rotateType ~= "custom" or not (data.animation.main.use_rotate and WeakAuras.regions[id].region.Rotate) end,
      },
      main_rotateFuncError = {
        type = "description",
        name = function()
          if not(data.animation.main.rotateFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.main.rotateFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 67.6,
        hidden = function()
          if(data.animation.main.type ~= "custom" or data.animation.main.rotateType ~= "custom" or not (data.animation.main.use_rotate and WeakAuras.regions[id].region.Rotate)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.main.rotateFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      main_rotate = {
        type = "range",
        name = L["Angle"],
        width = "double",
        order = 68,
        softMin = 0,
        softMax = 360,
        bigStep = 3,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      main_use_color = {
        type = "toggle",
        name = L["Color"],
        order = 68.2,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
      },
      main_colorType = {
        type = "select",
        name = L["Type"],
        order = 68.5,
        values = anim_color_types,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
      },
      main_colorFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 68.7,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.colorType ~= "custom" or not (data.animation.main.use_color and WeakAuras.regions[id].region.Color) end,
        get = function() return data.animation.main.colorFunc; end,
        set = function(info, v) data.animation.main.colorFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      main_colorFunc_expand = {
        type = "execute",
        order = 68.8,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "main", "colorFunc"})
        end,
        hidden = function() return data.animation.main.type ~= "custom" or data.animation.main.colorType ~= "custom" or not (data.animation.main.use_color and WeakAuras.regions[id].region.Color) end,
      },
      main_colorFuncError = {
        type = "description",
        name = function()
          if not(data.animation.main.colorFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.main.colorFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 69,
        hidden = function()
          if(data.animation.main.type ~= "custom" or data.animation.main.colorType ~= "custom" or not (data.animation.main.use_color and WeakAuras.regions[id].region.Color)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.main.colorFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      main_color = {
        type = "color",
        name = L["Color"],
        width = "double",
        order = 69.5,
        hidden = function() return (data.animation.main.type ~= "custom" or not WeakAuras.regions[id].region.Color) end,
        get = function()
          return data.animation.main.colorR,
            data.animation.main.colorG,
            data.animation.main.colorB,
            data.animation.main.colorA;
        end,
        set = function(info, r, g, b, a)
          data.animation.main.colorR = r;
          data.animation.main.colorG = g;
          data.animation.main.colorB = b;
          data.animation.main.colorA = a;
        end
      },
      finish_header = {
        type = "header",
        name = L["Finish"],
        order = 70
      },
      finish_type = {
        type = "select",
        name = L["Type"],
        order = 72,
        values = anim_types,
        disabled = false
      },
      finish_preset = {
        type = "select",
        name = L["Preset"],
        order = 73,
        values = function() return filterAnimPresetTypes(anim_finish_preset_types, id) end,
        hidden = function() return data.animation.finish.type ~= "preset" end
      },
      finish_duration_type_no_choice = {
        type = "select",
        name = L["Time in"],
        order = 73,
        width = "half",
        values = duration_types_no_choice,
        disabled = true,
        hidden = function() return data.animation.finish.type ~= "custom" end,
        get = function() return "seconds" end
      },
      finish_duration = {
        type = "input",
        name = L["Duration (s)"],
        desc = "The duration of the animation in seconds.\n\nThe finish animation does not start playing until after the display would normally be hidden.",
        order = 73.5,
        width = "half",
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_use_alpha = {
        type = "toggle",
        name = L["Fade Out"],
        order = 74,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_alphaType = {
        type = "select",
        name = L["Type"],
        order = 75,
        values = anim_alpha_types,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_alphaFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 75.3,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.alphaType ~= "custom" or not data.animation.finish.use_alpha end,
        get = function() return data.animation.finish.alphaFunc end,
        set = function(info, v) data.animation.finish.alphaFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      finish_alphaFunc_expand = {
        type = "execute",
        order = 75.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "finish", "alphaFunc"})
        end,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.alphaType ~= "custom" or not data.animation.finish.use_alpha end,
      },
      finish_alphaFuncError = {
        type = "description",
        name = function()
          if not(data.animation.finish.alphaFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.finish.alphaFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 75.6,
        hidden = function()
          if(data.animation.finish.type ~= "custom" or data.animation.finish.alphaType ~= "custom" or not data.animation.finish.use_alpha) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.finish.alphaFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      finish_alpha = {
        type = "range",
        name = L["Alpha"],
        width = "double",
        order = 76,
        min = 0,
        max = 1,
        bigStep = 0.01,
        isPercent = true,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_use_translate = {
        type = "toggle",
        name = L["Slide Out"],
        order = 78,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_translateType = {
        type = "select",
        name = L["Type"],
        order = 79,
        values = anim_translate_types,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_translateFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 79.3,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.translateType ~= "custom" or not data.animation.finish.use_translate end,
        get = function() return data.animation.finish.translateFunc; end,
        set = function(info, v) data.animation.finish.translateFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      finish_translateFunc_expand = {
        type = "execute",
        order = 79.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "finish", "translateFunc"})
        end,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.translateType ~= "custom" or not data.animation.finish.use_translate end,
      },
      finish_translateFuncError = {
        type = "description",
        name = function()
          if not(data.animation.finish.translateFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.finish.translateFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 79.6,
        hidden = function()
          if(data.animation.finish.type ~= "custom" or data.animation.finish.translateType ~= "custom" or not data.animation.finish.use_translate) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.finish.translateFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      finish_x = {
        type = "range",
        name = L["X Offset"],
        order = 80,
        softMin = -200,
        softMax = 200,
        step = 1,
        bigStep = 5,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_y = {
        type = "range",
        name = L["Y Offset"],
        order = 81,
        softMin = -200,
        softMax = 200,
        step = 1,
        bigStep = 5,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_use_scale = {
        type = "toggle",
        name = L["Zoom Out"],
        order = 82,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      finish_scaleType = {
        type = "select",
        name = L["Type"],
        order = 83,
        values = anim_scale_types,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      finish_scaleFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 83.3,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.scaleType ~= "custom" or not (data.animation.finish.use_scale and WeakAuras.regions[id].region.Scale) end,
        get = function() return data.animation.finish.scaleFunc; end,
        set = function(info, v) data.animation.finish.scaleFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      finish_scaleFunc_expand = {
        type = "execute",
        order = 83.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "finish", "scaleFunc"})
        end,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.scaleType ~= "custom" or not (data.animation.finish.use_scale and WeakAuras.regions[id].region.Scale) end,
      },
      finish_scaleFuncError = {
        type = "description",
        name = function()
          if not(data.animation.finish.scaleFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.finish.scaleFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 83.6,
        hidden = function()
          if(data.animation.finish.type ~= "custom" or data.animation.finish.scaleType ~= "custom" or not (data.animation.finish.use_scale and WeakAuras.regions[id].region.Scale)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " ..  (data.animation.finish.scaleFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      finish_scalex = {
        type = "range",
        name = L["X Scale"],
        order = 84,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      finish_scaley = {
        type = "range",
        name = L["Y Scale"],
        order = 85,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Scale) end
      },
      finish_use_rotate = {
        type = "toggle",
        name = L["Rotate Out"],
        order = 86,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      finish_rotateType = {
        type = "select",
        name = L["Type"],
        order = 87,
        values = anim_rotate_types,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      finish_rotateFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 87.3,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.rotateType ~= "custom" or not (data.animation.finish.use_rotate and WeakAuras.regions[id].region.Rotate) end,
        get = function() return data.animation.finish.rotateFunc; end,
        set = function(info, v) data.animation.finish.rotateFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      finish_rotateFunc_expand = {
        type = "execute",
        order = 87.4,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "finish", "rotateFunc"})
        end,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.rotateType ~= "custom" or not (data.animation.finish.use_rotate and WeakAuras.regions[id].region.Rotate) end,
      },
      finish_rotateFuncError = {
        type = "description",
        name = function()
          if not(data.animation.finish.rotateFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.finish.rotateFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 87.6,
        hidden = function()
          if(data.animation.finish.type ~= "custom" or data.animation.finish.rotateType ~= "custom" or not (data.animation.finish.use_rotate and WeakAuras.regions[id].region.Rotate)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.finish.rotateFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      finish_rotate = {
        type = "range",
        name = L["Angle"],
        width = "double",
        order = 88,
        softMin = 0,
        softMax = 360,
        bigStep = 3,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Rotate) end
      },
      finish_use_color = {
        type = "toggle",
        name = L["Color"],
        order = 88.2,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
      },
      finish_colorType = {
        type = "select",
        name = L["Type"],
        order = 88.5,
        values = anim_color_types,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Color) end
      },
      finish_colorFunc = {
        type = "input",
        multiline = true,
        name = L["Custom Function"],
        width = "normal",
        order = 88.7,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.colorType ~= "custom" or not (data.animation.finish.use_color and WeakAuras.regions[id].region.Color) end,
        get = function() return data.animation.finish.colorFunc; end,
        set = function(info, v) data.animation.finish.colorFunc = v; WeakAuras.Add(data); end,
        control = "WeakAurasMultiLineEditBox"
      },
      finish_colorFunc_expand = {
        type = "execute",
        order = 88.8,
        name = L["Expand Text Editor"],
        func = function()
          WeakAuras.OpenTextEditor(data, {"animation", "finish", "colorFunc"})
        end,
        hidden = function() return data.animation.finish.type ~= "custom" or data.animation.finish.colorType ~= "custom" or not (data.animation.finish.use_color and WeakAuras.regions[id].region.Color) end,
      },
      finish_colorFuncError = {
        type = "description",
        name = function()
          if not(data.animation.finish.colorFunc) then
            return "";
          end
          local _, errorString = loadstring("return " .. (data.animation.finish.colorFunc or ""));
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = "double",
        order = 89,
        hidden = function()
          if(data.animation.finish.type ~= "custom" or data.animation.finish.colorType ~= "custom" or not (data.animation.finish.use_color and WeakAuras.regions[id].region.Color)) then
            return true;
          else
            local loadedFunction, errorString = loadstring("return " .. (data.animation.finish.colorFunc or ""));
            if(errorString and not loadedFunction) then
              return false;
            else
              return true;
            end
          end
        end
      },
      finish_color = {
        type = "color",
        name = L["Color"],
        width = "double",
        order = 89.5,
        hidden = function() return (data.animation.finish.type ~= "custom" or not WeakAuras.regions[id].region.Color) end,
        get = function()
          return data.animation.finish.colorR,
            data.animation.finish.colorG,
            data.animation.finish.colorB,
            data.animation.finish.colorA;
        end,
        set = function(info, r, g, b, a)
          data.animation.finish.colorR = r;
          data.animation.finish.colorG = g;
          data.animation.finish.colorB = b;
          data.animation.finish.colorA = a;
        end
      }
    }
  }
  return animation;
end
