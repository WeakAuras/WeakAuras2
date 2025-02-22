if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L
local prefixToPath = OptionsPrivate.commonOptions.prefixToPath
local pathToDataKey = OptionsPrivate.commonOptions.pathToDataKey
local flattenRegionOptions = OptionsPrivate.commonOptions.flattenRegionOptions

function OptionsPrivate.GetGroupOptions(data)
  local regionOption;
  local id = data.id
  if (OptionsPrivate.Private.regionOptions[data.regionType]) then
    regionOption = OptionsPrivate.Private.regionOptions[data.regionType].create(id, data);
  else
    regionOption = {
      [data.regionType] = {
        __title = "|cFFFFFF00" .. data.regionType,
        __order = 1,
        unsupported = {
          type = "description",
          name = L["This region of type \"%s\" is not supported."]:format(data.regionType)
        }
      };
    };
  end

  local  groupOptions = {
    type = "group",
    name = L["Group Options"],
    order = 0,
    get = function(info)
      local path = prefixToPath(info[#info])
      local base, property = pathToDataKey(data, path)
      if not base then
        return nil
      end
      if(info.type == "color") then
        base[property] = base[property] or {}
        local c = base[property]
        return c[1], c[2], c[3], c[4]
      else
        return base[property]
      end
    end,
    set = function(info, v, g, b, a)
      local path = prefixToPath(info[#info], data, true)
      local payload
      if info.type == "color" then
        payload = {v, g, b, a}
      elseif info.type == "toggle" then
        payload = v
      else
        payload = v ~= "" and v or nil
      end
      OptionsPrivate.Private.TimeMachine:Append({
        uid = data.uid,
        actionType = "set",
        path = path,
        payload = payload,
      })
      WeakAuras.UpdateThumbnail(data);
      OptionsPrivate.ResetMoverSizer();
    end,
    hidden = function() return false end,
    disabled = function() return false end,
    args = flattenRegionOptions(regionOption, true);
  }

  return groupOptions
end
