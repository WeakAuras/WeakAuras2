if not WeakAuras.IsCorrectVersion() then return end

local Masque = LibStub("Masque", true)
local L = WeakAuras.L

local function createOptions(id, data)
  local hiddenIconExtra = function()
    return WeakAuras.IsCollapsed("icon", "icon", "iconextra", true);
  end
  local indentWidth = 0.15

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
    useTooltip = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip on Mouseover"],
      hidden = function() return not WeakAuras.CanHaveTooltip(data) end,
      order = 6
    },
    iconExtraDescription = {
      type = "description",
      name = function()
        local line = L["|cFFffcc00Extra Options:|r"]
        local changed = false
        if data.alpha ~= 1 then
          line = L["%s Alpha: %d%%"]:format(line, data.alpha*100)
          changed = true
        end
        if data.zoom ~= 0 then
          line = L["%s Zoom: %d%%"]:format(line, data.zoom*100)
          changed = true
        end
        if data.iconInset and data.iconInset ~= 0 then
          line = L["%s Inset: %d%%"]:format(line, data.iconInset*100)
          changed = true
        end
        if data.keepAspectRatio then
          line = L["%s Keep Aspect Ratio"]:format(line)
          changed = true
        end
        if not changed then
          line = L["%s Default Alpha, Zoom, Icon Inset, Aspect Ratio"]:format(line)
        end
        return line
      end,
      width = WeakAuras.doubleWidth - 0.15,
      order = 7,
      fontSize = "medium"
    },
    iconExtraExpand = {
      type = "execute",
      name = function()
        local collapsed = WeakAuras.IsCollapsed("icon", "icon", "iconextra", true)
        return collapsed and L["Show Extra Options"] or L["Hide Extra Options"]
      end,
      order = 7.01,
      width = 0.15,
      image = function()
        local collapsed = WeakAuras.IsCollapsed("icon", "icon", "iconextra", true);
        return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
      end,
      imageWidth = 24,
      imageHeight = 24,
      func = function()
        local collapsed = WeakAuras.IsCollapsed("icon", "icon", "iconextra", true);
        WeakAuras.SetCollapsed("icon", "icon", "iconextra", not collapsed);
      end,
      control = "WeakAurasIcon"
    },
    iconExtra_space1 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = 7.02,
      hidden = hiddenIconExtra,
    },
    alpha = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Alpha"],
      order = 7.03,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true,
      hidden = hiddenIconExtra,
    },
    zoom = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Zoom"],
      order = 7.04,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true,
      hidden = hiddenIconExtra,
    },
    iconExtra_space2 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = 7.05,
      hidden = hiddenIconExtra,
    },
    iconInset = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Icon Inset"],
      order = 7.06,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true,
      hidden = function()
        return not Masque or hiddenIconExtra();
      end
    },
    keepAspectRatio = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Keep Aspect Ratio"],
      order = 7.07,
      hidden = hiddenIconExtra,
    },
    cooldownHeader = {
      type = "header",
      order = 11,
      name = L["Cooldown Settings"],
    },
    cooldown = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Cooldown"],
      order = 11.1,
      disabled = function() return not WeakAuras.CanHaveDuration(data); end,
      get = function() return WeakAuras.CanHaveDuration(data) and data.cooldown; end
    },
    inverse = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Inverse"],
      order = 11.2,
      disabled = function() return not (WeakAuras.CanHaveDuration(data) and data.cooldown); end,
      get = function() return data.inverse and WeakAuras.CanHaveDuration(data) and data.cooldown; end,
      hidden = function() return not data.cooldown end
    },
    cooldownSwipe = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Cooldown Swipe"],
      order = 11.3,
      disabled = function() return not WeakAuras.CanHaveDuration(data) end,
      hidden = function() return not data.cooldown end,
    },
    cooldownEdge = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Cooldown Edge"],
      order = 11.4,
      disabled = function() return not WeakAuras.CanHaveDuration(data) end,
      hidden = function() return not data.cooldown end,
    },
    cooldownTextDisabled = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Hide Cooldown Text"],
      order = 11.5,
      disabled = function() return not WeakAuras.CanHaveDuration(data); end,
      hidden = function() return not data.cooldown end,
    },
    endHeader = {
      type = "header",
      order = 100,
      name = "",
    },
  };

  for k, v in pairs(WeakAuras.GlowOptions(id, data, 12)) do
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

local anchorPoints = {
  BOTTOMLEFT = {
    display = { L["Edge"], L["Bottom Left"] },
    type = "point"
  },
  BOTTOM = {
    display = { L["Edge"], L["Bottom"] },
    type = "point"
  },
  BOTTOMRIGHT = {
    display = { L["Edge"], L["Bottom Right"] },
    type = "point"
  },
  RIGHT = {
    display = { L["Edge"], L["Right"] },
    type = "point"
  },
  TOPRIGHT = {
    display = { L["Edge"], L["Top Right"] },
    type = "point"
  },
  TOP = {
    display = { L["Edge"], L["Top"] },
    type = "point"
  },
  TOPLEFT = {
    display = { L["Edge"], L["Top Left"] },
    type = "point"
  },
  LEFT = {
    display = { L["Edge"], L["Left"] },
    type = "point"
  },
  CENTER = {
    display = L["Center"],
    type = "point"
  },
  INNER_BOTTOMLEFT = {
    display = { L["Inner"], L["Bottom Left"] },
    type = "point"
  },
  INNER_BOTTOM = {
    display = { L["Inner"], L["Bottom"] },
    type = "point"
  },
  INNER_BOTTOMRIGHT = {
    display = { L["Inner"], L["Bottom Right"] },
    type = "point"
  },
  INNER_RIGHT = {
    display = { L["Inner"], L["Right"] },
    type = "point"
  },
  INNER_TOPRIGHT = {
    display = { L["Inner"], L["Top Right"] },
    type = "point"
  },
  INNER_TOP = {
    display = { L["Inner"], L["Top"] },
    type = "point"
  },
  INNER_TOPLEFT = {
    display = { L["Inner"], L["Top Left"] },
    type = "point"
  },
  INNER_LEFT = {
    display = { L["Inner"], L["Left"] },
    type = "point"
  },
  OUTER_BOTTOMLEFT = {
    display = { L["Outer"], L["Bottom Left"] },
    type = "point"
  },
  OUTER_BOTTOM = {
    display = { L["Outer"], L["Bottom"] },
    type = "point"
  },
  OUTER_BOTTOMRIGHT = {
    display = { L["Outer"], L["Bottom Right"] },
    type = "point"
  },
  OUTER_RIGHT = {
    display = { L["Outer"], L["Right"] },
    type = "point"
  },
  OUTER_TOPRIGHT = {
    display = { L["Outer"], L["Top Right"] },
    type = "point"
  },
  OUTER_TOP = {
    display = { L["Outer"], L["Top"] },
    type = "point"
  },
  OUTER_TOPLEFT = {
    display = { L["Outer"], L["Top Left"] },
    type = "point"
  },
  OUTER_LEFT = {
    display = { L["Outer"], L["Left"] },
    type = "point"
  },
  ALL = {
    display = L["Whole Area"],
    type = "area"
  }
}

local function GetAnchors(data)
  return anchorPoints;
end

WeakAuras.RegisterRegionOptions("icon", createOptions, "interface\\icons\\spell_holy_sealofsalvation.blp", L["Icon"], createThumbnail, modifyThumbnail, L["Shows a spell icon with an optional cooldown overlay"], templates, GetAnchors);
