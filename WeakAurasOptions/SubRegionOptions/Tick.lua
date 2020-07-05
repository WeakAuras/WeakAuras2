if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local indentWidth = WeakAuras.normalWidth * 0.06

local function createOptions(parentData, data, index, subIndex)
  local options = {
    __title = L["Tick %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionUp, index, "subtick")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __down = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionDown, index, "subtick")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __duplicate = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DuplicateSubRegion, index, "subtick")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __delete = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DeleteSubRegion, index, "subtick")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    tick_visible = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Tick"],
      order = 1,
    },
    tick_color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      order = 2,
      hasAlpha = true,
    },
    tick_placement_mode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Tick Mode"],
      order = 3,
      values = WeakAuras.tick_placement_modes,
    },
    tick_placement = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Tick Placement"],
      order = 4,
      validate = WeakAuras.ValidateNumeric,
      desc = L["Enter in a value for the tick's placement."],
    },
    tick_space1 = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 5,
    },
    automatic_length = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Automatic length"],
      order = 6,
      desc = L["Matches the height setting of a horizontal bar or width for a vertical bar."],
    },
    tick_thickness = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Thickness"],
      order = 7,
      min = 0,
      softMax = 20,
      step = 1,
    },
    tick_length = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Length"],
      order = 8,
      min = 0,
      softMax = 50,
      step = 1,
      disabled = function() return data.automatic_length end,
    },
  }
  return options
end

WeakAuras.RegisterSubRegionOptions("subtick", createOptions, L["Places a tick on the bar"]);
