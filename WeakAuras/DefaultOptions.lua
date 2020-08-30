--[[ Manual override for the default font and font size until proper options are built ]]

WeakAuras.defaultFont = "Friz Quadrata TT"
WeakAuras.defaultFontSize = 12

local function AddMissingTableEntries(data, DEFAULT)
  if not data or not DEFAULT then return data end
  local rv = data
  for k, v in pairs(DEFAULT) do
      if rv[k] == nil then
          rv[k] = v
      elseif type(v) == "table" then
          if type(rv[k]) == "table" then
              rv[k] = AddMissingTableEntries(rv[k], v)
          else
              rv[k] = AddMissingTableEntries({}, v)
          end
      end
  end
  return rv
end

local function GetDefaults(key)
  if WeakAurasSaved and WeakAurasSaved.defaults[key] then
    local defaults = {}
    WeakAuras.DeepCopy(WeakAurasSaved.defaults[key], defaults)
    return defaults
  end
end

function WeakAuras.InitialDefaultsValues(values)
  return AddMissingTableEntries(values or {}, {
    global = {
      font = "Friz Quadrata TT",
      fontSize = 12,
      fontType = "None",
      outline = "Outline"
    }
  })
end


function WeakAuras.GetDefaultsForRegion(region)
  local defaults = GetDefaults('global')
  if region then
    local regionDefault = GetDefaults(region)
    if regionDefault then
      for k,v in pairs(regionDefault) do
        defaults[k] = v
      end
    end
  end

  return defaults
end

function WeakAuras.SetDefault(region, param, value)
  if WeakAurasSaved then
    local defaults = WeakAurasSaved.defaults
    defaults[region] = defaults[region] or {}
    defaults[region][param] = value
  end
end

function WeakAuras.GetDefault(region, param, useFallback)
  if WeakAurasSaved then
    local defaults = WeakAurasSaved.defaults
    local value = defaults[region] and defaults[region][param]
    if not value and useFallback then
      value = defaults.global[param]
    end
    return value
  end
end

function WeakAuras.MergeDefaultsForRegion(region, defaults)
  defaults = defaults or {}
  return function()
    local dbDefaults = WeakAuras.GetDefaultsForRegion(region)
    if dbDefaults then
      for k,v in pairs(dbDefaults) do
        if (v ~= nil) then
          defaults[k] = v
        end
      end
    end

    return defaults
  end
end

function WeakAuras.MergeDefaultsForSubregion(subregion, defaults)
  defaults = defaults or {}
  return function(regionType)
    if (type(defaults) == 'function') then
      defaults = defaults(regionType)
    end
    local dbDefaults = WeakAuras.GetDefaultsForRegion(subregion)
    if dbDefaults then
      local prefix = ""
      if subregion == "subtext" then
        prefix = "text_"
      end
      for k,v in pairs(dbDefaults) do
        if (v ~= nil) then
          defaults[(prefix or "") .. k] = v
        end
      end
    end
    return defaults
  end
end
