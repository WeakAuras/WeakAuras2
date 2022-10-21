if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

local L = WeakAuras.L

local removeFuncs = OptionsPrivate.commonOptions.removeFuncs
local replaceNameDescFuncs = OptionsPrivate.commonOptions.replaceNameDescFuncs
local replaceImageFuncs = OptionsPrivate.commonOptions.replaceImageFuncs
local replaceValuesFuncs = OptionsPrivate.commonOptions.replaceValuesFuncs
local disabledAll = OptionsPrivate.commonOptions.CreateDisabledAll("animation")
local hiddenAll = OptionsPrivate.commonOptions.CreateHiddenAll("animation")
local getAll = OptionsPrivate.commonOptions.CreateGetAll("animation")
local setAll = OptionsPrivate.commonOptions.CreateSetAll("animation", getAll)



local function filterAnimPresetTypes(intable, id)
  local ret = {};
  OptionsPrivate.Private.EnsureRegion(id)
  local region = OptionsPrivate.Private.regions[id] and OptionsPrivate.Private.regions[id].region
  local regionType = OptionsPrivate.Private.regions[id] and OptionsPrivate.Private.regions[id].regionType
  local data = WeakAuras.GetData(id);

  if data.controlledChildren then
    return ret
  end

  if(region and regionType and data) then
    for key, value in pairs(intable) do
      local preset = OptionsPrivate.Private.anim_presets[key];
      if(preset) then
        if not((preset.use_scale and not region.Scale) or (preset.use_rotate and not region.Rotate)) then
          ret[key] = value;
        end
      end
    end
  end
  return ret;
end

function OptionsPrivate.GetAnimationOptions(data)
  local anim_types = OptionsPrivate.Private.anim_types
  local anim_translate_types = OptionsPrivate.Private.anim_translate_types;
  local anim_scale_types = OptionsPrivate.Private.anim_scale_types;
  local anim_alpha_types = OptionsPrivate.Private.anim_alpha_types;
  local anim_rotate_types = OptionsPrivate.Private.anim_rotate_types;
  local anim_color_types = OptionsPrivate.Private.anim_color_types;
  local anim_start_preset_types = OptionsPrivate.Private.anim_start_preset_types;
  local anim_main_preset_types = OptionsPrivate.Private.anim_main_preset_types;
  local anim_finish_preset_types = OptionsPrivate.Private.anim_finish_preset_types;
  local duration_types = OptionsPrivate.Private.duration_types;
  local duration_types_no_choice = OptionsPrivate.Private.duration_types_no_choice;
  local anim_ease_types = OptionsPrivate.Private.anim_ease_types;

  local id = data.id
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
      if(field == "main") then
        local region = OptionsPrivate.Private.EnsureRegion(id)
        OptionsPrivate.Private.Animate("display", data.uid, "main", data.animation.main, region, false, nil, true);
        if(OptionsPrivate.Private.clones[id]) then
          for cloneId, cloneRegion in pairs(OptionsPrivate.Private.clones[id]) do
            OptionsPrivate.Private.Animate("display", data.uid, "main", data.animation.main,
                                           cloneRegion, false, nil, true, cloneId);
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
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 32,
        values = anim_types,
        disabled = false
      },
      start_preset = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Preset"],
        order = 33,
        values = function() return filterAnimPresetTypes(anim_start_preset_types, id) end,
        hidden = function() return data.animation.start.type ~= "preset" end
      },
      start_duration_type_no_choice = {
        type = "select",
        width = WeakAuras.halfWidth,
        name = L["Time in"],
        order = 33,
        values = duration_types_no_choice,
        disabled = true,
        hidden = function()
          return data.animation.start.type ~= "custom" or OptionsPrivate.Private.CanHaveDuration(data)
        end,
        get = function() return "seconds" end
      },
      start_duration_type = {
        type = "select",
        width = WeakAuras.halfWidth,
        name = L["Time in"],
        order = 33,
        values = duration_types,
        hidden = function()
          return data.animation.start.type ~= "custom" or not OptionsPrivate.Private.CanHaveDuration(data)
        end
      },
      start_duration = {
        type = "input",
        width = WeakAuras.halfWidth,
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
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_easeType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Ease type"],
        values = anim_ease_types,
        order = 33.7,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_easeStrength = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["Ease Strength"],
        order = 33.8,
        min = 1,
        max = 5,
        bigStep = 1,
        hidden = function() return data.animation.start.type ~= "custom" end,
        disabled = function() return data.animation.start.easeType == "none" end
      },
      start_use_alpha = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Fade In"],
        order = 34,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_alphaType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 35,
        values = anim_alpha_types,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      -- text editor added below
      start_alpha = {
        type = "range",
        width = WeakAuras.doubleWidth,
        name = L["Alpha"],
        order = 36,
        min = 0,
        max = 1,
        bigStep = 0.01,
        isPercent = true,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_use_translate = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Slide In"],
        order = 38,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      start_translateType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 39,
        values = anim_translate_types,
        hidden = function() return data.animation.start.type ~= "custom" end
      },
      -- texteditor added below
      start_x = {
        type = "range",
        width = WeakAuras.normalWidth,
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
        width = WeakAuras.normalWidth,
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
        width = WeakAuras.normalWidth,
        name = L["Zoom In"],
        order = 42,
        hidden = function()
          return (
            data.animation.start.type ~= "custom"
            or not OptionsPrivate.Private.EnsureRegion(id).Scale
            ) end
      },
      start_scaleType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 43,
        values = anim_scale_types,
        hidden = function()
          return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      -- texteditor added below
      start_scalex = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["X Scale"],
        order = 44,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function()
          return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      start_scaley = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["Y Scale"],
        order = 45,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function()
          return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      start_use_rotate = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Rotate In"],
        order = 46,
        hidden = function()
          return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
        end
      },
      start_rotateType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 47,
        values = anim_rotate_types,
        hidden = function()
          return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
        end
      },
      -- texteditor added below
      start_rotate = {
        type = "range",
        width = WeakAuras.doubleWidth,
        name = L["Angle"],
        order = 48,
        softMin = 0,
        softMax = 360,
        bigStep = 3,
        hidden = function()
          return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
        end
      },
      start_use_color = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Color"],
        order = 48.2,
        hidden = function()
           return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
        end
      },
      start_colorType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 48.5,
        values = anim_color_types,
        hidden = function()
          return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
        end
      },
      -- texteditor added below
      start_color = {
        type = "color",
        width = WeakAuras.doubleWidth,
        name = L["Color"],
        order = 49.5,
        hidden = function()
          return (data.animation.start.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
        end,
        get = function()
          return data.animation.start.colorR or 1,
            data.animation.start.colorG or 1,
            data.animation.start.colorB or 1,
            data.animation.start.colorA or 1;
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
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 52,
        values = anim_types,
        disabled = false
      },
      main_preset = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Preset"],
        order = 53,
        values = function() return filterAnimPresetTypes(anim_main_preset_types, id) end,
        hidden = function() return data.animation.main.type ~= "preset" end
      },
      main_duration_type_no_choice = {
        type = "select",
        width = WeakAuras.halfWidth,
        name = L["Time in"],
        order = 53,
        values = duration_types_no_choice,
        disabled = true,
        hidden = function()
          return data.animation.main.type ~= "custom" or OptionsPrivate.Private.CanHaveDuration(data)
        end,
        get = function() return "seconds" end
      },
      main_duration_type = {
        type = "select",
        width = WeakAuras.halfWidth,
        name = L["Time in"],
        order = 53,
        values = duration_types,
        hidden = function()
          return data.animation.main.type ~= "custom" or not OptionsPrivate.Private.CanHaveDuration(data)
        end
      },
      main_duration = {
        type = "input",
        width = WeakAuras.halfWidth,
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
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_easeType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Ease type"],
        values = anim_ease_types,
        order = 53.7,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_easeStrength = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["Ease Strength"],
        order = 53.8,
        min = 1,
        max = 5,
        bigStep = 1,
        hidden = function() return data.animation.main.type ~= "custom" end,
        disabled = function() return data.animation.main.easeType == "none" end
      },
      main_use_alpha = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Fade"],
        order = 54,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_alphaType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 55,
        values = anim_alpha_types,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      -- texteditor added below
      main_alpha = {
        type = "range",
        width = WeakAuras.doubleWidth,
        name = L["Alpha"],
        order = 56,
        min = 0,
        max = 1,
        bigStep = 0.01,
        isPercent = true,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_use_translate = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Slide"],
        order = 58,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      main_translateType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 59,
        values = anim_translate_types,
        hidden = function() return data.animation.main.type ~= "custom" end
      },
      -- texteditor added below
      main_x = {
        type = "range",
        width = WeakAuras.normalWidth,
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
        width = WeakAuras.normalWidth,
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
        width = WeakAuras.normalWidth,
        name = L["Zoom"],
        order = 62,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      main_scaleType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 63,
        values = anim_scale_types,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      -- texteditor added below
      main_scalex = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["X Scale"],
        order = 64,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      main_scaley = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["Y Scale"],
        order = 65,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      main_use_rotate = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Rotate"],
        order = 66,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
        end
      },
      main_rotateType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 67,
        values = anim_rotate_types,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
        end
      },
      -- text editor added below
      main_rotate = {
        type = "range",
        width = WeakAuras.doubleWidth,
        name = L["Angle"],
        order = 68,
        softMin = 0,
        softMax = 360,
        bigStep = 3,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
        end
      },
      main_use_color = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Color"],
        order = 68.2,
        hidden = function()
           return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
          end
      },
      main_colorType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 68.5,
        values = anim_color_types,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
        end
      },
      -- texteditor added below
      main_color = {
        type = "color",
        width = WeakAuras.doubleWidth,
        name = L["Color"],
        order = 69.5,
        hidden = function()
          return (data.animation.main.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
        end,
        get = function()
          return data.animation.main.colorR or 1,
            data.animation.main.colorG or 1,
            data.animation.main.colorB or 1,
            data.animation.main.colorA or 1;
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
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 72,
        values = anim_types,
        disabled = false
      },
      finish_preset = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Preset"],
        order = 73,
        values = function() return filterAnimPresetTypes(anim_finish_preset_types, id) end,
        hidden = function() return data.animation.finish.type ~= "preset" end
      },
      finish_duration_type_no_choice = {
        type = "select",
        width = WeakAuras.halfWidth,
        name = L["Time in"],
        order = 73,
        values = duration_types_no_choice,
        disabled = true,
        hidden = function() return data.animation.finish.type ~= "custom" end,
        get = function() return "seconds" end
      },
      finish_duration = {
        type = "input",
        width = WeakAuras.halfWidth,
        name = L["Duration (s)"],
        desc = L["The duration of the animation in seconds. The finish animation does not start playing until after the display would normally be hidden."],
        order = 73.5,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_easeType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Ease type"],
        values = anim_ease_types,
        order = 73.7,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_easeStrength = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["Ease Strength"],
        order = 73.8,
        min = 1,
        max = 5,
        bigStep = 1,
        hidden = function() return data.animation.finish.type ~= "custom" end,
        disabled = function() return data.animation.finish.easeType == "none" end
      },
      finish_use_alpha = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Fade Out"],
        order = 74,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_alphaType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 75,
        values = anim_alpha_types,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      -- texteditor added below
      finish_alpha = {
        type = "range",
        width = WeakAuras.doubleWidth,
        name = L["Alpha"],
        order = 76,
        min = 0,
        max = 1,
        bigStep = 0.01,
        isPercent = true,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_use_translate = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Slide Out"],
        order = 78,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      finish_translateType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 79,
        values = anim_translate_types,
        hidden = function() return data.animation.finish.type ~= "custom" end
      },
      -- texteditor added below
      finish_x = {
        type = "range",
        width = WeakAuras.normalWidth,
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
        width = WeakAuras.normalWidth,
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
        width = WeakAuras.normalWidth,
        name = L["Zoom Out"],
        order = 82,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      finish_scaleType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 83,
        values = anim_scale_types,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      -- texteditor added below
      finish_scalex = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["X Scale"],
        order = 84,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      finish_scaley = {
        type = "range",
        width = WeakAuras.normalWidth,
        name = L["Y Scale"],
        order = 85,
        softMin = 0,
        softMax = 5,
        step = 0.01,
        bigStep = 0.1,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Scale)
        end
      },
      finish_use_rotate = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Rotate Out"],
        order = 86,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
        end
      },
      finish_rotateType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 87,
        values = anim_rotate_types,
        hidden = function()
           return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
          end
      },
      -- texteditor added below
      finish_rotate = {
        type = "range",
        width = WeakAuras.doubleWidth,
        name = L["Angle"],
        order = 88,
        softMin = 0,
        softMax = 360,
        bigStep = 3,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Rotate)
        end
      },
      finish_use_color = {
        type = "toggle",
        width = WeakAuras.normalWidth,
        name = L["Color"],
        order = 88.2,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
        end
      },
      finish_colorType = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Type"],
        order = 88.5,
        values = anim_color_types,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
        end
      },
      -- texteditor added below
      finish_color = {
        type = "color",
        width = WeakAuras.doubleWidth,
        name = L["Color"],
        order = 89.5,
        hidden = function()
          return (data.animation.finish.type ~= "custom" or not OptionsPrivate.Private.EnsureRegion(id).Color)
        end,
        get = function()
          return data.animation.finish.colorR or 1,
            data.animation.finish.colorG or 1,
            data.animation.finish.colorB or 1,
            data.animation.finish.colorA or 1;
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

  local function extraSetFunction()
    OptionsPrivate.Private.Animate("display", data.uid, "main", data.animation.main,
                                   OptionsPrivate.Private.EnsureRegion(id), false, nil, true)
    if(OptionsPrivate.Private.clones[id]) then
      for cloneId, cloneRegion in pairs(OptionsPrivate.Private.clones[id]) do
        OptionsPrivate.Private.Animate("display", data.uid, "main", data.animation.main,
                                       cloneRegion, false, nil, true, cloneId)
      end
    end
  end

  -- Text Editors for "start"
  local function hideStartAlphaFunc()
    return data.animation.start.type ~= "custom"
           or data.animation.start.alphaType ~= "custom"
           or not data.animation.start.use_alpha
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "start_alphaFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#alpha-opacity",
                          35.3, hideStartAlphaFunc, {"animation", "start", "alphaFunc"}, false);

  local function hideStartTranslate()
    return data.animation.start.type ~= "custom"
           or data.animation.start.translateType ~= "custom"
           or not data.animation.start.use_translate
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "start_translateFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#translate-position",
                          39.3, hideStartTranslate, {"animation", "start", "translateFunc"}, false);

  local function hideStartScale()
    return data.animation.start.type ~= "custom"
           or data.animation.start.scaleType ~= "custom"
           or not (data.animation.start.use_scale and OptionsPrivate.Private.EnsureRegion(id).Scale)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "start_scaleFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#scale-size",
                          43.3, hideStartScale, {"animation", "start", "scaleFunc"}, false);

  local function hideStartRotateFunc()
    return data.animation.start.type ~= "custom"
           or data.animation.start.rotateType ~= "custom"
           or not (data.animation.start.use_rotate and OptionsPrivate.Private.EnsureRegion(id).Rotate)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "start_rotateFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#rotate",
                          47.3, hideStartRotateFunc, {"animation", "start", "rotateFunc"}, false);

  local function hideStartColorFunc()
    return data.animation.start.type ~= "custom"
           or data.animation.start.colorType ~= "custom"
           or not (data.animation.start.use_color and OptionsPrivate.Private.EnsureRegion(id).Color)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "start_colorFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#color",
                          48.7, hideStartColorFunc, {"animation", "start", "colorFunc"}, false);

  -- Text Editors for "main"
  local function hideMainAlphaFunc()
    return data.animation.main.type ~= "custom"
           or data.animation.main.alphaType ~= "custom"
           or not data.animation.main.use_alpha
  end
  local mainCodeOptions = { extraSetFunction = extraSetFunction }
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "main_alphaFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#alpha-opacity",
                          55.3, hideMainAlphaFunc, {"animation", "main", "alphaFunc"}, false, mainCodeOptions);

  local function hideMainTranslate()
    return data.animation.main.type ~= "custom"
           or data.animation.main.translateType ~= "custom"
           or not data.animation.main.use_translate
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "main_translateFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#translate-position",
                          59.3, hideMainTranslate, {"animation", "main", "translateFunc"}, false, mainCodeOptions);

  local function hideMainScale()
    return data.animation.main.type ~= "custom"
           or data.animation.main.scaleType ~= "custom"
           or not (data.animation.main.use_scale and OptionsPrivate.Private.EnsureRegion(id).Scale)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "main_scaleFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#scale-sizes",
                          63.3, hideMainScale, {"animation", "main", "scaleFunc"}, false, mainCodeOptions);

  local function hideMainRotateFunc()
    return data.animation.main.type ~= "custom"
           or data.animation.main.rotateType ~= "custom"
           or not (data.animation.main.use_rotate and OptionsPrivate.Private.EnsureRegion(id).Rotate)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "main_rotateFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#rotate",
                          67.3, hideMainRotateFunc, {"animation", "main", "rotateFunc"}, false, mainCodeOptions);

  local function hideMainColorFunc()
    return data.animation.main.type ~= "custom"
           or data.animation.main.colorType ~= "custom"
           or not (data.animation.main.use_color and OptionsPrivate.Private.EnsureRegion(id).Color)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "main_colorFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#color",
                          68.7, hideMainColorFunc, {"animation", "main", "colorFunc"}, false, mainCodeOptions);

  -- Text Editors for "finish"
  local function hideFinishAlphaFunc()
    return data.animation.finish.type ~= "custom"
           or data.animation.finish.alphaType ~= "custom"
           or not data.animation.finish.use_alpha
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "finish_alphaFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#alpha-opacity",
                          75.3, hideFinishAlphaFunc, {"animation", "finish", "alphaFunc"}, false);

  local function hideFinishTranslate()
    return data.animation.finish.type ~= "custom"
           or data.animation.finish.translateType ~= "custom"
           or not data.animation.finish.use_translate
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "finish_translateFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#translate-position",
                          79.3, hideFinishTranslate, {"animation", "finish", "translateFunc"}, false);

  local function hideFinishScale()
    return data.animation.finish.type ~= "custom"
           or data.animation.finish.scaleType ~= "custom"
           or not (data.animation.finish.use_scale and OptionsPrivate.Private.EnsureRegion(id).Scale)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "finish_scaleFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#scale-size",
                          83.3, hideFinishScale, {"animation", "finish", "scaleFunc"}, false);

  local function hideFinishRotateFunc()
    return data.animation.finish.type ~= "custom"
           or data.animation.finish.rotateType ~= "custom"
           or not (data.animation.finish.use_rotate and OptionsPrivate.Private.EnsureRegion(id).Rotate)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "finish_rotateFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#rotate",
                          87.3, hideFinishRotateFunc, {"animation", "finish", "rotateFunc"}, false);

  local function hideFinishColorFunc()
    return data.animation.finish.type ~= "custom"
           or data.animation.finish.colorType ~= "custom"
           or not (data.animation.finish.use_color and OptionsPrivate.Private.EnsureRegion(id).Color)
  end
  OptionsPrivate.commonOptions.AddCodeOption(animation.args, data, L["Custom Function"], "finish_colorFunc",
                          "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#color",
                          88.7, hideFinishColorFunc, {"animation", "finish", "colorFunc"}, false);

  if(data.controlledChildren) then
    removeFuncs(animation);
    replaceNameDescFuncs(animation, data, "animation");
    replaceImageFuncs(animation, data, "animation");
    replaceValuesFuncs(animation, data, "animation");

    animation.get = function(info, ...) return getAll(data, info, ...); end;
    animation.set = function(info, ...)
      setAll(data, info, ...);
      if(type(data.id) == "string") then
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        OptionsPrivate.ResetMoverSizer();
      end
    end
    animation.hidden = function(info, ...) return hiddenAll(data, info, ...); end;
    animation.disabled = function(info, ...) return disabledAll(data, info, ...); end;
  end

  return animation;
end
