if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;


local indentWidth = WeakAuras.normalWidth * 0.06


local function createOptions(parentData, data, index, subIndex)

  local order = 9
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
      order = order + 0.01,
    },
    tick_color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      order = order + 0.02,
      hasAlpha = true,
    },
    tick_placement_mode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Tick Mode"],
      order = order + 0.10,
      values = WeakAuras.tick_placement_modes,
      desc = L["Automatic mode moves the tick as the bar progresses"],
    },
    tick_placement = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Tick Placement"],
      order = order + 0.11,
      validate = WeakAuras.ValidateNumeric,
      desc = L["Enter in a value for the tick's placement."],
    },
    tick_space1 = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = order + 0.20,
    },
    automatic_length = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Automatic length"],
      order = order + 0.21,
      desc = L["Matches the height setting of a horizontal bar or width for a vertical bar."],
    },
    tick_thickness = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Thickness"],
      order = order + 0.30,
      min = 0,
      softMax = 20,
      step = 1,
    },
    tick_length = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Length"],
      order = order + 0.31,
      min = 0,
      softMax = 50,
      step = 1,
      disabled = function() return data.automatic_length end,
    },
  }
  return options
end

WeakAuras.RegisterSubRegionOptions("subtick", createOptions, L["Places a tick on the bar"]);
