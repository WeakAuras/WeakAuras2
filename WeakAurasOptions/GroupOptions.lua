if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

local L = WeakAuras.L
local regionOptions = WeakAuras.regionOptions;
local parsePrefix = OptionsPrivate.commonOptions.parsePrefix
local flattenRegionOptions = OptionsPrivate.commonOptions.flattenRegionOptions

function OptionsPrivate.GetGroupOptions(data)
  local regionOption;
  local id = data.id
  if (regionOptions[data.regionType]) then
    regionOption = regionOptions[data.regionType].create(id, data);
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
      local base, property = parsePrefix(info[#info], data);
      if not base then
        return nil
      end
      if(info.type == "color") then
        base[property] = base[property] or {};
        local c = base[property];
        return c[1], c[2], c[3], c[4];
      else
        return base[property];
      end
    end,
    set = function(info, v, g, b, a)
      local base, property = parsePrefix(info[#info], data, true);
      if(info.type == "color") then
        base[property] = base[property] or {};
        local c = base[property];
        c[1], c[2], c[3], c[4] = v, g, b, a;
      elseif(info.type == "toggle") then
        base[property] = v;
      else
        base[property] = (v ~= "" and v) or nil;
      end
      WeakAuras.Add(data);
      WeakAuras.UpdateThumbnail(data);
      OptionsPrivate.ResetMoverSizer();
    end,
    hidden = function() return false end,
    disabled = function() return false end,
    args = flattenRegionOptions(regionOption, true);
  }

  return groupOptions
end
