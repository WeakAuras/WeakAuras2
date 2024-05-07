if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local Masque = LibStub("Masque", true)
local L = WeakAuras.L

local function createOptions(id, data)
  local hiddenIconExtra = function()
    return OptionsPrivate.IsCollapsed("icon", "icon", "iconextra", true);
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
    desaturate = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Desaturate"],
      order = 2,
    },
    iconSource = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Icon Source"],
      order = 3,
      values = OptionsPrivate.Private.IconSources(data)
    },
    displayIcon = {
      type = "input",
      width = WeakAuras.normalWidth - 0.15,
      name = L["Manual Icon"],
      order = 4,
      get = function()
        return data.displayIcon and tostring(data.displayIcon) or "";
      end,
      set = function(info, v)
        data.displayIcon = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
      end
    },
    chooseIcon = {
      type = "execute",
      width = 0.15,
      name = L["Choose"],
      order = 5,
      func = function()
        local path = {"displayIcon"}
        local paths = {}
        for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
          paths[child.id] = path
        end
        OptionsPrivate.OpenIconPicker(data, paths)
      end,
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon",
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
    },
    useTooltip = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Tooltip on Mouseover"],
      hidden = function() return not OptionsPrivate.Private.CanHaveTooltip(data) end,
      order = 6
    },
    iconExtraDescription = {
      type = "execute",
      control = "WeakAurasExpandSmall",
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
        if data.texXOffset and data.texXOffset ~= 0 then
          line = L["%s X offset by %d"]:format(line, data.texXOffset)
        end
        if data.texYOffset and data.texYOffset ~= 0 then
          line = L["%s Y offset by %d"]:format(line, data.texYOffset)
        end
        if not changed then
          line = L["%s Default Alpha, Zoom, Icon Inset, Aspect Ratio"]:format(line)
        end
        return line
      end,
      width = WeakAuras.doubleWidth,
      order = 7,
      image = function()
        local collapsed = OptionsPrivate.IsCollapsed("icon", "icon", "iconextra", true);
        return collapsed and "collapsed" or "expanded"
      end,
      imageWidth = 15,
      imageHeight = 15,
      func = function(info, button)
        local collapsed = OptionsPrivate.IsCollapsed("icon", "icon", "iconextra", true);
        OptionsPrivate.SetCollapsed("icon", "icon", "iconextra", not collapsed);
      end,
      arg = {
        expanderName = "icon"
      }
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
      control = "WeakAurasSpinBox",
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
      control = "WeakAurasSpinBox",
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
    texXOffset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Texture X Offset"],
      order = 7.06,
      min = -1,
      max = 1,
      bigStep = 0.1,
      hidden = hiddenIconExtra,
    },
    texYOffset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Texture Y Offset"],
      order = 7.07,
      min = -1,
      max = 1,
      bigStep = 0.1,
      hidden = hiddenIconExtra,
    },
    iconExtra_space3 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = 7.08,
      hidden = hiddenIconExtra,
    },
    iconInset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Icon Inset"],
      order = 7.09,
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
      order = 7.10,
      hidden = hiddenIconExtra,
    },
    iconExtraAnchor = {
      type = "description",
      name = "",
      order = 8,
      hidden = hiddenIconExtra,
      control = "WeakAurasExpandAnchor",
      arg = {
        expanderName = "icon"
      }
    },
    cooldownHeader = {
      type = "header",
      order = 11,
      name = L["Swipe Overlay Settings"],
    },
    cooldown = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Enable Swipe"],
      order = 11.1,
      desc = L["Enable the \"Swipe\" radial overlay"],
      get = function() return data.cooldown; end
    },
    inverse = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Inverse"],
      order = 11.2,
      desc = L["Invert the direction of progress"],
      get = function() return data.inverse and data.cooldown; end,
      hidden = function() return not data.cooldown end
    },
    cooldownSwipe = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show \"Swipe\""],
      order = 11.3,
      desc = "|TInterface\\AddOns\\WeakAuras\\Media\\Textures\\swipe-example:30|t\n"..L["Enable \"swipe\" part of the overlay"],
      hidden = function() return not data.cooldown end,
    },
    cooldownEdge = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show \"Edge\""],
      order = 11.4,
      desc = "|TInterface\\AddOns\\WeakAuras\\Media\\Textures\\edge-example:30|t\n"..L["Enable \"Edge\" part of the overlay"],
      hidden = function() return not data.cooldown end,
    },
    cooldownTextDisabled = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Hide Timer Text"],
      order = 11.5,
      desc = L["A timer will automatically be displayed according to default Interface Settings (overridden by some addons).\nEnable this setting if you want this timer to be hidden, or when using a WeakAuras text to display the timer"],
      hidden = function() return not data.cooldown end,
    },
    useCooldownModRate = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Blizzard Cooldown Reduction"],
      order = 11.6,
      desc = L["Cooldown Reduction changes the duration of seconds instead of showing the real time seconds."],
      hidden = function() return not data.cooldown end,
    },
    ccWarning = {
      type = "description",
      width = WeakAuras.doubleWidth,
      name = function()
        if OmniCC then
          return L["The addon OmniCC is enabled. It might add cooldown numbers to the swipe. You can configure these in the OmniCC settings"]
        elseif ElvUI then
          return L["The addon ElvUI is enabled. It might add cooldown numbers to the swipe. You can configure these in the ElvUI settings"]
        else
          return L["Cooldown Numbers might be added by WoW. You can configure these in the game settings."]
        end
      end,
      order = 11.7,
      hidden = function() return data.cooldownTextDisabled end
    },
    endHeader = {
      type = "header",
      order = 100,
      name = "",
    },
  };

  return {
    icon = options,
    progressOptions = OptionsPrivate.commonOptions.ProgressOptions(data),
    position = OptionsPrivate.commonOptions.PositionOptions(id, data),
  };
end

local function createThumbnail()
  ---@class frame: FrameScriptObject
  local frame = CreateFrame("Frame", nil, UIParent)
  local icon = frame:CreateTexture();
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
  icon:SetAllPoints(frame)
  frame.icon = icon
  return frame;
end

local function modifyThumbnail(parent, frame, data)
  local texWidth = 0.25 * data.zoom;
  frame.icon:SetTexCoord(texWidth, 1 - texWidth, texWidth, 1 - texWidth);
  frame:SetParent(parent)

  function frame:SetIcon(path)
    local iconPath
    if data.iconSource == 0 then
      iconPath = data.displayIcon
    else
      iconPath = path or data.displayIcon
    end
    if iconPath and iconPath ~= "" then
      OptionsPrivate.Private.SetTextureOrAtlas(self.icon, iconPath)
    else
      OptionsPrivate.Private.SetTextureOrAtlas(self.icon, "Interface\\Icons\\INV_Misc_QuestionMark")
    end
  end

  if data then
    local name, icon = WeakAuras.GetNameAndIcon(data);
    frame:SetIcon(icon)
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

OptionsPrivate.registerRegions = OptionsPrivate.registerRegions or {}
table.insert(OptionsPrivate.registerRegions, function()
  OptionsPrivate.Private.RegisterRegionOptions("icon", createOptions, "interface\\icons\\spell_holy_sealofsalvation.blp", L["Icon"],
                                  createThumbnail, modifyThumbnail,
                                  L["Shows a spell icon with an optional cooldown overlay"],
                                  templates, GetAnchors);
end)
