local Masque = LibStub("Masque", true)
local L = WeakAuras.L

local function createOptions(id, data)
  local options = {
    __title = L["Icon Settings"],
    __order = 1,
    color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      hasAlpha = true,
      order = 1
    },
    auto = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Automatic Icon"],
      order = 2,
      disabled = function() return not WeakAuras.CanHaveAuto(data); end,
      get = function() return WeakAuras.CanHaveAuto(data) and data.auto; end
    },
    displayIcon = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Display Icon"],
      hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
      order = 3,
      get = function()
        return data.displayIcon and tostring(data.displayIcon) or "";
      end,
      set = function(info, v)
        data.displayIcon = v;
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
      end
    },
    chooseIcon = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Choose"],
      hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
      order = 4,
      func = function() WeakAuras.OpenIconPicker(data, "displayIcon"); end
    },
    desaturate = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Desaturate"],
      order = 5,
    },
    cooldownHeader = {
      type = "header",
      order = 6,
      name = L["Cooldown Settings"],
    },
    cooldown = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Cooldown"],
      order = 6.1,
      disabled = function() return not WeakAuras.CanHaveDuration(data); end,
      get = function() return WeakAuras.CanHaveDuration(data) and data.cooldown; end
    },
    inverse = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Inverse"],
      order = 6.2,
      disabled = function() return not (WeakAuras.CanHaveDuration(data) and data.cooldown); end,
      get = function() return data.inverse and WeakAuras.CanHaveDuration(data) and data.cooldown; end,
      hidden = function() return not data.cooldown end
    },
    cooldownSwipe = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Cooldown Swipe"],
      order = 6.3,
      disabled = function() return not WeakAuras.CanHaveDuration(data) end,
      hidden = function() return not data.cooldown end,
    },
    cooldownEdge = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Cooldown Edge"],
      order = 6.4,
      disabled = function() return not WeakAuras.CanHaveDuration(data) end,
      hidden = function() return not data.cooldown end,
    },
    cooldownTextDisabled = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Hide Cooldown Text"],
      order = 6.5,
      disabled = function() return not WeakAuras.CanHaveDuration(data); end,
      hidden = function() return not data.cooldown end,
    },
    textHeader1 = {
      type = "header",
      order = 39,
      name = L["1. Text Settings"]
    },
    text1Enabled = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      order = 39.1,
      name = L["1. Text"],
    },
    text1 = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Text"],
      desc = function()
        local ret = L["Dynamic text tooltip"];
        ret = ret .. WeakAuras.GetAdditionalProperties(data);
        return ret
      end,
      order = 39.2,
      hidden = function() return not data.text1Enabled end,
    },
    text1Color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      hasAlpha = true,
      order = 39.3,
      hidden = function() return not data.text1Enabled end,
    },
    text1Point = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Text Position"],
      order = 39.4,
      values = WeakAuras.point_types,
      hidden = function() return not data.text1Enabled end,
    },
    text1Containment = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = " ",
      order = 39.5,
      values = WeakAuras.containment_types,
      hidden = function() return not data.text1Enabled end,
    },
    text1Font = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Font",
      name = L["Font"],
      order = 39.6,
      values = AceGUIWidgetLSMlists.font,
      hidden = function() return not data.text1Enabled end,
    },
    text1FontSize = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Size"],
      order = 39.7,
      min = 6,
      softMax = 72,
      step = 1,
      hidden = function() return not data.text1Enabled end,
    },
    text1FontFlags = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Outline"],
      order = 39.8,
      values = WeakAuras.font_flags,
      hidden = function() return not data.text1Enabled end,
    },

    textHeader2 = {
      type = "header",
      order = 40,
      name = L["2. Text Settings"]
    },
    text2Enabled = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      order = 40.1,
      name = L["2. Text"],
    },
    text2 = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Text"],
      desc = function()
        local ret = L["Dynamic text tooltip"];
        ret = ret .. WeakAuras.GetAdditionalProperties(data);
        return ret
      end,
      order = 40.2,
      hidden = function() return not data.text2Enabled end,
    },
    text2Color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      hasAlpha = true,
      order = 40.3,
      hidden = function() return not data.text2Enabled end,
    },
    text2Point = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Text Position"],
      order = 40.4,
      values = WeakAuras.point_types,
      hidden = function() return not data.text2Enabled end,
    },
    text2Containment = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = " ",
      order = 40.5,
      values = WeakAuras.containment_types,
      hidden = function() return not data.text2Enabled end,
    },
    text2Font = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Font",
      name = L["Font"],
      order = 40.6,
      values = AceGUIWidgetLSMlists.font,
      hidden = function() return not data.text2Enabled end,
    },
    text2FontSize = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Size"],
      order = 40.7,
      min = 6,
      softMax = 72,
      step = 1,
      hidden = function() return not data.text2Enabled end,
    },
    text2FontFlags = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Outline"],
      order = 40.8,
      values = WeakAuras.font_flags,
      hidden = function() return not data.text2Enabled end,
    },

    generalHeader = {
      type = "header",
      order = 43,
      name = L["General Text Settings"],
      hidden = function()
        return not ((data.text1Enabled and (WeakAuras.ContainsPlaceHolders(data.text1, "pt") or WeakAuras.ContainsCustomPlaceHolder(data.text1)))
          or (data.text2Enabled and (WeakAuras.ContainsPlaceHolders(data.text2, "pt") or WeakAuras.ContainsCustomPlaceHolder(data.text2))))
      end,
    },
    customTextUpdate = {
      type = "select",
      width = WeakAuras.doubleWidth,
      hidden = function()
        return not ((data.text1Enabled and WeakAuras.ContainsCustomPlaceHolder(data.text1))
          or (data.text2Enabled and WeakAuras.ContainsCustomPlaceHolder(data.text2)))
      end,
      name = L["Update Custom Text On..."],
      values = WeakAuras.text_check_types,
      order = 43.1
    },
    -- Code Editor added below
    progressPrecision = {
      type = "select",
      width = WeakAuras.normalWidth,
      order = 44,
      name = L["Remaining Time Precision"],
      values = WeakAuras.precision_types,
      get = function() return data.progressPrecision or 1 end,
      hidden = function()
        return not ((data.text1Enabled and WeakAuras.ContainsPlaceHolders(data.text1, "pt"))
          or (data.text2Enabled and WeakAuras.ContainsPlaceHolders(data.text2, "pt")))
      end,
      disabled = function()
        return not (data.text1Enabled and WeakAuras.ContainsPlaceHolders(data.text1, "p") or data.text2Enabled and WeakAuras.ContainsPlaceHolders(data.text2, "p"));
      end
    },
    totalPrecision = {
      type = "select",
      width = WeakAuras.normalWidth,
      order = 44.5,
      name = L["Total Time Precision"],
      values = WeakAuras.precision_types,
      get = function() return data.totalPrecision or 1 end,
      hidden = function()
        return not ((data.text1Enabled and WeakAuras.ContainsPlaceHolders(data.text1, "pt"))
          or (data.text2Enabled and WeakAuras.ContainsPlaceHolders(data.text2, "pt")))
      end,
      disabled = function()
        return not (data.text1Enabled and WeakAuras.ContainsPlaceHolders(data.text1, "t") or data.text2Enabled and WeakAuras.ContainsPlaceHolders(data.text2, "t"));
      end
    },
    otherHeader = {
      type = "header",
      order = 48,
      name = "",
    },
    zoom = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Zoom"],
      order = 49,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    },
    iconInset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Icon Inset"],
      order = 49.1,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true,
      hidden = function()
        return not Masque;
      end
    },
    keepAspectRatio = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Keep Aspect Ratio"],
      order = 49.1
    },
    stickyDuration = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Sticky Duration"],
      desc = L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."],
      order = 49.4
    },
    useTooltip = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip on Mouseover"],
      hidden = function() return not WeakAuras.CanHaveTooltip(data) end,
      order = 49.5
    },
    alpha = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Icon Alpha"],
      order = 49.6,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    },
  };

  local function hideCustomTextEditor()
    return not ((data.text1Enabled and WeakAuras.ContainsCustomPlaceHolder(data.text1))
             or (data.text2Enabled and WeakAuras.ContainsCustomPlaceHolder(data.text2)))
  end

  WeakAuras.AddCodeOption(options, data, L["Custom Function"], "customText", 43.2,  hideCustomTextEditor, {"customText"}, false);

  for k, v in pairs(WeakAuras.GlowOptions(id, data, 10)) do
    options[k] = v
  end

  return {
    icon = options,
    position = WeakAuras.PositionOptions(id, data),
  };
end

local function createThumbnail(parent)
  local icon = parent:CreateTexture();
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");

  return icon;
end

local function modifyThumbnail(parent, icon, data, fullModify)
  local texWidth = 0.25 * data.zoom;
  icon:SetTexCoord(texWidth, 1 - texWidth, texWidth, 1 - texWidth);

  function icon:SetIcon(path)
    local success = icon:SetTexture(data.auto and path or data.displayIcon) and (data.auto and path or data.displayIcon);
    if not(success) then
      icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    end
  end
end

local templates = {
  {
    title = L["Default"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      cooldown = true,
      inverse = true,
    };
  },
  {
    title = L["Tiny Icon"],
    description = L["A 20x20 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 20,
      height = 20,
      cooldown = true,
      inverse = true,
    };
  },
  {
    title = L["Small Icon"],
    description = L["A 32x32 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 32,
      height = 32,
      cooldown = true,
      inverse = true,
    };
  },
  {
    title = L["Medium Icon"],
    description = L["A 40x40 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 40,
      height = 40,
      cooldown = true,
      inverse = true,
    };
  },
  {
    title = L["Big Icon"],
    description = L["A 48x48 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 48,
      height = 48,
      cooldown = true,
      inverse = true,
    };
  },
  {
    title = L["Huge Icon"],
    description = L["A 64x64 pixels icon"],
    icon = "Interface\\ICONS\\Temp.blp",
    data = {
      width = 64,
      height = 64,
      cooldown = true,
      inverse = true,
    };
  }
}

WeakAuras.RegisterRegionOptions("icon", createOptions, "Interface\\ICONS\\Temp.blp", L["Icon"], createThumbnail, modifyThumbnail, L["Shows a spell icon with an optional cooldown overlay"], templates);
