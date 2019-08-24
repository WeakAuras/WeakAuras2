if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local function createOptions(parentData, data, index, subIndex)
  local order = 9
  local options = {
    __title = L["Model %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionUp, index, "subbarmodel")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __down = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionDown, index, "subbarmodel")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __duplicate = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DuplicateSubRegion, index, "subbarmodel")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __delete = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DeleteSubRegion, index, "subbarmodel")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    bar_model_visible = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Show Model"],
      order = order + 0.1,
    },
    model = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Model"],
      order = order + 1
    },
    chooseModel = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Choose"],
      order = order + 2,
      func = function()
        WeakAuras.OpenModelPicker(data, "model", parentData);
      end,
    },
    bar_model_clip = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Clipped by Progress"],
      order = order + 3,
    },
    bar_model_alpha = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Alpha"],
      order = order + 4,
      min = 0,
      max = 1,
      bigStep = 0.1
    }
  }
  return options
end

WeakAuras.RegisterSubRegionOptions("subbarmodel", createOptions, L["Shows a model"]);
