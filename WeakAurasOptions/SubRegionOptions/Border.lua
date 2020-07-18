if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local function createOptions(parentData, data, index, subIndex)
  local options = {
    __title = L["Border %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionUp, index, "subborder")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __down = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionDown, index, "subborder")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __duplicate = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DuplicateSubRegion, index, "subtext")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __delete = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DeleteSubRegion, index, "subborder")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
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
      width = WeakAuras.normalWidth,
      name = L["Border Offset"],
      order = 5,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
    },
    border_size = {
      type = "range",
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
      values = WeakAuras.aurabar_anchor_areas,
      hidden = function() return parentData.regionType ~= "aurabar" end
    }
  }

  return options
end

WeakAuras.RegisterSubRegionOptions("subborder", createOptions, L["Shows a border"]);
