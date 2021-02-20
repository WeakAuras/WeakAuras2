if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

local L = WeakAuras.L;

local function createOptions(parentData, data, index, subIndex)
  local options = {
    __title = L["Border %s"]:format(subIndex),
    __order = 1,
    border_visible = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Show Border"],
      order = 2,
    },
    border_edge = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Border",
      name = L["Border Style"],
      order = 3,
      values = AceGUIWidgetLSMlists.border,
    },
    border_color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Border Color"],
      hasAlpha = true,
      order = 4,
    },
    border_offset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Border Offset"],
      order = 5,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
    },
    border_size = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Border Size"],
      order = 6,
      min = 1,
      softMax = 64,
      bigStep = 1,
    },
    border_anchor = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Border Anchor"],
      order = 7,
      values = OptionsPrivate.Private.aurabar_anchor_areas,
      hidden = function() return parentData.regionType ~= "aurabar" end
    }
  }

  OptionsPrivate.AddUpDownDeleteDuplicate(options, parentData, index, "subborder")

  return options
end

local function createDefaultOptions(width)
  local options = {
    __title = L["Border Sub Element Default Options"],
    -- Icon
    subborder_icon_header = {
      type = "description",
      name = L["Icon"],
      order = 1,
      fontSize = "large"
    },

    subborder_icon_default = {
      name = L["Automatically add to new Icons"],
      type = "toggle",
      path = {'subRegion', 'border', 'icon_add'},
      applyType = "none",
      default = false,
      order = 2,
      width = width * 2
    },

    subborder_icon_size = {
      name = L["Size"],
      type = "range",
      path = {'subRegion', 'border', 'icon_border_size'},
      applyType = "newsubregion",
      default = 2,
      order = 3,
      width = width,
      min = 1,
      softMax = 64,
      bigStep = 1,
    },

    subborder_icon_edge = {
      name = L["Style"],
      type = "select",
      path = {'subRegion', 'border', 'icon_border_edge'},
      applyType = "newsubregion",
      default = "Square Full White",
      width = width,
      dialogControl = "LSM30_Border",
      order = 4,
      values = AceGUIWidgetLSMlists.border,
    },

    subborder_icon_color = {
      name = L["Color"],
      type = "color",
      path = {'subRegion', 'border', 'icon_border_color'},
      applyType = "newsubregion",
      default = {1, 1, 1, 1},
      width = width,
      hasAlpha = true,
      order = 5,
    },

    subborder_icon_offset = {
      name = L["Border Offset"],
      type = "range",
      path = {'subRegion', 'border', 'icon_border_offset'},
      applyType = "newsubregion",
      default = 0,
      order = 6,
      width = width,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
    },

    -- Aurabar
    subborder_aurabar_header = {
      name = L["Progress Bar"],
      type = "description",
      order = 20,
      fontSize = "large"
    },

    subborder_aurabar_default = {
      name = L["Add to new Progress Bars"],
      type = "toggle",
      path = {'subRegion', 'border', 'aurabar_add'},
      applyType = "none",
      default = false,
      order = 21,
      width = width * 2
    },

    subborder_aurabar_size = {
      name = L["Size"],
      type = "range",
      path = {'subRegion', 'border', 'aurabar_border_size'},
      applyType = "newsubregion",
      default = 2,
      order = 23,
      width = width,
      min = 1,
      softMax = 64,
      bigStep = 1,
    },

    subborder_aurabar_edge = {
      name = L["Style"],
      type = "select",
      path = {'subRegion', 'border', 'aurabar_border_edge'},
      applyType = "newsubregion",
      default = "Square Full White",
      width = width,
      dialogControl = "LSM30_Border",
      order = 24,
      values = AceGUIWidgetLSMlists.border,
    },

    subborder_aurabar_color = {
      name = L["Color"],
      type = "color",
      path = {'subRegion', 'border', 'aurabar_border_color'},
      applyType = "newsubregion",
      default = {1, 1, 1, 1},
      width = width,
      hasAlpha = true,
      order = 25,
    },

    subborder_aurabar_offset = {
      name = L["Border Offset"],
      type = "range",
      path = {'subRegion', 'border', 'aurabar_border_offset'},
      applyType = "newsubregion",
      default = 0,
      order = 26,
      width = width,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
    },
    --- Other
    subborder_other_header = {
      name = L["Other"],
      type = "description",
      order = 30,
      fontSize = "large"
    },

    subborder_other_default = {
      name = L["Add to new Progress Bars"],
      type = "toggle",
      path = {'subRegion', 'border', 'other_add'},
      applyType = "none",
      default = false,
      order = 31,
      width = width * 2
    },

    subborder_other_size = {
      name = L["Size"],
      type = "range",
      path = {'subRegion', 'border', 'other_border_size'},
      applyType = "newsubregion",
      default = 2,
      order = 33,
      width = width,
      min = 1,
      softMax = 64,
      bigStep = 1,
    },

    subborder_other_edge = {
      name = L["Style"],
      type = "select",
      path = {'subRegion', 'border', 'other_border_edge'},
      applyType = "newsubregion",
      default = "Square Full White",
      width = width,
      dialogControl = "LSM30_Border",
      order = 34,
      values = AceGUIWidgetLSMlists.border,
    },

    subborder_other_color = {
      name = L["Color"],
      type = "color",
      path = {'subRegion', 'border', 'other_border_color'},
      applyType = "newsubregion",
      default = {1, 1, 1, 1},
      width = width,
      hasAlpha = true,
      order = 35,
    },

    subborder_other_offset = {
      name = L["Border Offset"],
      type = "range",
      path = {'subRegion', 'border', 'other_border_offset'},
      applyType = "newsubregion",
      default = 0,
      order = 36,
      width = width,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
    }
  }
  return options
end

WeakAuras.RegisterDefaultsOptions(createDefaultOptions)

WeakAuras.RegisterSubRegionOptions("subborder", createOptions, L["Shows a border"]);
