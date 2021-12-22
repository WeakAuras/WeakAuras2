if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...
local L = WeakAuras.L;

do
  local function subCreateOptions(parentData, data, index, subIndex)
      local order = 9
      local options = {
        __title = L["Background"],
        __order = 1,
        __up = function()
          for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
            OptionsPrivate.MoveSubRegionUp(child, index, "subbackground")
          end
          WeakAuras.ClearAndUpdateOptions(parentData.id)
        end,
        __down = function()
          for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
            OptionsPrivate.MoveSubRegionDown(child, index, "subbackground")
          end
          WeakAuras.ClearAndUpdateOptions(parentData.id)
        end,
        __notcollapsable = true
      }
      return options
    end

  WeakAuras.RegisterSubRegionOptions("subbackground", subCreateOptions, L["Background"]);
end

-- Foreground for aurabar

do
  local function subCreateOptions(parentData, data, index, subIndex)
    local order = 9
    local options = {
      __title = L["Foreground"],
      __order = 1,
      __up = function()
        for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
          OptionsPrivate.MoveSubRegionUp(child, index, "subforeground")
        end
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end,
      __down = function()
        for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
          OptionsPrivate.MoveSubRegionDown(child, index, "subforeground")
        end
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end,
      __notcollapsable = true
    }
    return options
  end

  WeakAuras.RegisterSubRegionOptions("subforeground", subCreateOptions, L["Foreground"]);
end