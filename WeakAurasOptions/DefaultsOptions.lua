if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...
local flattenRegionOptions = WeakAuras.commonOptions.flattenRegionOptions

local L = WeakAuras.L

local function GlobalOptions()
  local options = {
    __title = L["Global Settings"],
    __order = 1,
    font = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Font",
      get = function()
        return WeakAuras.GetDefault('global', 'font')
      end,
      set = function(_, value)
        WeakAuras.SetDefault('global', 'font', value)
      end,
      name = L["Font"],
      order = 1,
      values = AceGUIWidgetLSMlists.font,
    },
    fontSize = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Size"],
      get = function()
        return WeakAuras.GetDefault('global', 'fontSize')
      end,
      set = function(_, value)
        WeakAuras.SetDefault('global', 'fontSize', value)
      end,
      order = 2,
      min = 6,
      softMax = 72,
      step = 1,
    },
    fontType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Outline"],
      get = function()
        return WeakAuras.GetDefault('global', 'fontType')
      end,
      set = function(_, value)
        -- Need to figure out this
        WeakAuras.SetDefault('global', 'fontType', value)
        WeakAuras.SetDefault('global', 'outline', value)
      end,
      order = 3,
      values = WeakAuras.font_flags,
    },
  }
  return options
end

local function GetExtraOptions()
  local extraOptions = {}
  for name, createOptions in pairs(WeakAuras.extraDefaultsOptions) do
    extraOptions[name] = createOptions() -- function if we want to pass something to it later
  end
  return extraOptions
end

function WeakAuras.GetDefaultsOptions()
  local extraOptions = GetExtraOptions()
  extraOptions.global = GlobalOptions()
  local options = {type = "group", name = L["Settings"], order = 1, args = flattenRegionOptions(extraOptions)}

  return options
end
