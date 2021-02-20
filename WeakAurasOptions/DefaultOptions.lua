if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...
local flattenRegionOptions = OptionsPrivate.commonOptions.flattenRegionOptions

local L = WeakAuras.L

local function GlobalOptions(width)
  return {
    __title = L["Global"],
    __order = 1,
    empty = {
      type = "description",
      name = L["No Global Options, yet!"],
      order = 1
    }
  }
end

local function convertOptions(options, width)
  width = width / 3
  local result = {}
  for id, data in pairs(options) do
    if id:sub(1, 2) == "__" then
      result[id] = data
    elseif data.type == "description" or data.type == "header" then
      result[id] = data
    else
      local namespace, key, property
      namespace = data.path[1]
      key = data.path[2]
      property = data.path[3]

      -- Add label
      local order = data.order
      local path = data.path
      local default = data.default
      result[id .. "label"] = {
        type = "description",
        name = data.name,
        order = order + 0.1,
        width = width,
        fontSize = "medium"
      }

      local applyType = data.applyType or "region"

      if applyType ~= "none" then
        result[id .. "enabled"] = {
          type = "select",
          name = L["Apply To"],
          order = order + 0.2,
          values = OptionsPrivate.Private.DefaultsApplyTypes[applyType],
          get = function()
            local type = OptionsPrivate.Private.GetDefault(namespace, key, property)
            return type or 0
          end,
          set = function(info, type)
            OptionsPrivate.Private.SetDefault(namespace, key, property, type, nil)
          end,
          width = width
        }
      end

      data.applyType = nil
      data.path = nil
      data.default = nil
      data.name = ""
      if data.type == "color" then
        data.get = function()
          local _, value = OptionsPrivate.Private.GetDefault(namespace, key, property)
          if value ~= nil and type(value) == "table" then
            return unpack(value)
          end
          return 1, 1, 1, 1
          -- TODO This appears to not work ?
          --return type(default) == "table" and unpack(default)
        end
        data.set = function(info, r, g, b, a)
          OptionsPrivate.Private.SetDefault(namespace, key, property, nil, {r, g, b, a})
        end
      else
        data.get = function()
          local type, value = OptionsPrivate.Private.GetDefault(namespace, key, property)
          if value ~= nil then
            return value
          end
          return default
        end
        data.set = function(info, value, ...)
          OptionsPrivate.Private.SetDefault(namespace, key, property, nil, value)
        end
      end
      if applyType ~= "none" then
        data.disabled = function()
          local type = OptionsPrivate.Private.GetDefault(namespace, key, property)
          return not type or type == 0
        end
      end
      data.order = order + 0.3
      result[id] = data
    end
  end

  return result
end

local function GetExtraOptions(width)
  local extraOptions = {}
  local order = 2
  for index, createOptions in ipairs(OptionsPrivate.Private.extraDefaultsOptions) do
    extraOptions[index] = convertOptions(createOptions(width / 3), width)
    extraOptions[index].__order = order
    order = order + 1
  end
  return extraOptions
end

function OptionsPrivate.GetDefaultsOptions(width)
  local extraOptions = GetExtraOptions(width)
  extraOptions.global = GlobalOptions(width)

  local options = {
    type = "group",
    name = L["Settings"],
    order = 1,
    args = flattenRegionOptions(extraOptions, nil, width)
  }

  return options
end
