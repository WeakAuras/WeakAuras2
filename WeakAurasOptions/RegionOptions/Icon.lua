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
    display = { L["Outter"], L["Bottom Left"] },
    type = "point"
  },
  OUTER_BOTTOM = {
    display = { L["Outter"], L["Bottom"] },
    type = "point"
  },
  OUTER_BOTTOMRIGHT = {
    display = { L["Outter"], L["Bottom Right"] },
    type = "point"
  },
  OUTER_RIGHT = {
    display = { L["Outter"], L["Right"] },
    type = "point"
  },
  OUTER_TOPRIGHT = {
    display = { L["Outter"], L["Top Right"] },
    type = "point"
  },
  OUTER_TOP = {
    display = { L["Outter"], L["Top"] },
    type = "point"
  },
  OUTER_TOPLEFT = {
    display = { L["Outter"], L["Top Left"] },
    type = "point"
  },
  OUTER_LEFT = {
    display = { L["Outter"], L["Left"] },
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
