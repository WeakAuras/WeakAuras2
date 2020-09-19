if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...
local L = WeakAuras.L
local regionOptions = WeakAuras.regionOptions

local flattenRegionOptions = OptionsPrivate.commonOptions.flattenRegionOptions
local fixMetaOrders = OptionsPrivate.commonOptions.fixMetaOrders
local parsePrefix = OptionsPrivate.commonOptions.parsePrefix
local removeFuncs = OptionsPrivate.commonOptions.removeFuncs
local replaceNameDescFuncs = OptionsPrivate.commonOptions.replaceNameDescFuncs
local replaceImageFuncs = OptionsPrivate.commonOptions.replaceImageFuncs
local replaceValuesFuncs = OptionsPrivate.commonOptions.replaceValuesFuncs
local disabledAll = OptionsPrivate.commonOptions.CreateDisabledAll("region")
local hiddenAll = OptionsPrivate.commonOptions.CreateHiddenAll("region")
local getAll = OptionsPrivate.commonOptions.CreateGetAll("region")
local setAll = OptionsPrivate.commonOptions.CreateSetAll("region", getAll)

local function AddSubRegionImpl(data, subRegionName)
  data.subRegions = data.subRegions or {}
  if OptionsPrivate.Private.subRegionTypes[subRegionName] and OptionsPrivate.Private.subRegionTypes[subRegionName] then
    if OptionsPrivate.Private.subRegionTypes[subRegionName].supports(data.regionType) then
      local default = OptionsPrivate.Private.subRegionTypes[subRegionName].default
      local subRegionData = type(default) == "function" and default(data.regionType) or CopyTable(default)
      subRegionData.type = subRegionName
      tinsert(data.subRegions, subRegionData)
      WeakAuras.Add(data)
      WeakAuras.ClearAndUpdateOptions(data.id)
    end
  end
end

local function AddSubRegion(data, subRegionName)
  if (OptionsPrivate.Private.ApplyToDataOrChildData(data, AddSubRegionImpl, subRegionName)) then
    WeakAuras.ClearAndUpdateOptions(data.id)
  end
end

local function AddOptionsForSupportedSubRegion(regionOption, data, supported)
  if not next(supported) then
    return
  end
  local hasSubRegions = false

  local result = {}
  local order = 1
  result.__order = 300
  result.__title = L["Add Extra Elements"]
  result.__topLine = true
  result.__withoutheader = true
  result["subregiontypespace"] = {
    type = "description",
    width = WeakAuras.doubleWidth,
    name = "",
    order = order,
  }
  order = order + 1
  for subRegionType in pairs(supported) do
    if OptionsPrivate.Private.subRegionTypes[subRegionType].supportsAdd then
      hasSubRegions = true
      result[subRegionType] = {
        type = "execute",
        width = WeakAuras.normalWidth,
        name = string.format(L["Add %s"], OptionsPrivate.Private.subRegionTypes[subRegionType].displayName),
        order = order,
        func = function()
          AddSubRegion(data, subRegionType)
        end,
      }
      order = order + 1
    end
  end
  regionOption["sub"] = result;
  return hasSubRegions
end

local function union(table1, table2)
  local meta = {};
  for i,v in pairs(table1) do
    meta[i] = v;
  end
  for i,v in pairs(table2) do
    meta[i] = v;
  end
  return meta;
end

function OptionsPrivate.GetDisplayOptions(data)
  local id = data.id

  if not data.controlledChildren then
    local regionOption;
    local commonOption = {};

    local hasSubElements = false

    if(regionOptions[data.regionType]) then
      regionOption = regionOptions[data.regionType].create(id, data);

      if data.subRegions then
        local subIndex = {}
        for index, subRegionData in ipairs(data.subRegions) do
          local subRegionType = subRegionData.type
          if OptionsPrivate.Private.subRegionOptions[subRegionType] then
            hasSubElements = true
            subIndex[subRegionType] = subIndex[subRegionType] and subIndex[subRegionType] + 1 or 1
            local options, common = OptionsPrivate.Private.subRegionOptions[subRegionType].create(data, subRegionData, index, subIndex[subRegionType])
            options.__order = 200 + index
            regionOption["sub." .. index .. "." .. subRegionType] = options
            commonOption[subRegionType] = common
          end
        end
      end

      local commonOptionIndex = 0
      for option, optionData in pairs(commonOption) do
        commonOptionIndex = commonOptionIndex + 1
        optionData.__order = 100 + commonOptionIndex
        regionOption[option] = optionData
      end

      local supported = {}
      for subRegionName, subRegionType in pairs(OptionsPrivate.Private.subRegionTypes) do
        if subRegionType.supports(data.regionType) then
          supported[subRegionName] = true
        end
      end
      hasSubElements = AddOptionsForSupportedSubRegion(regionOption, data, supported) or hasSubElements
    else
      regionOption = {
        [data.regionType] = {
          __title = "|cFFFFFF00" .. data.regionType,
          __order = 1,
          unsupported = {
            type = "description",
            name = L["This region of type \"%s\" is not supported."]:format(data.regionType),
            order = 2,
          }
        }
      };
    end

    if hasSubElements then
      regionOption["SubElementsHeader"] = {
        __order = 100,
        __noHeader = true,
        header = {
          type = "header",
          name = L["Sub Elements"],
          order = 1
        }
      }
    end

    local options = flattenRegionOptions(regionOption, true)

    local region = {
      type = "group",
      name = L["Display"],
      order = 10,
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
        if(data.parent) then
          local parentData = WeakAuras.GetData(data.parent);
          if(parentData) then
            WeakAuras.Add(parentData);
          end
        end
        OptionsPrivate.ResetMoverSizer();
      end,
      args = options
    };
    return region
  else
    -- Multiple Auras
    -- We call the create functions of the relevant region types with
    -- the parentData once per region type
    -- For sub regions, the relevant create function is called with the parentData
    -- once per index/sub region type
    local handledRegionTypes = {}
    local handledSubRegionTypes = {}

    local allOptions = {};
    local commonOption = {};
    local unsupportedCount = 0
    local supportedSubRegions = {}
    local hasSubElements = false

    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if childData and not handledRegionTypes[childData.regionType] then
        handledRegionTypes[childData.regionType] = true;
        if regionOptions[childData.regionType] then
          allOptions = union(allOptions, regionOptions[childData.regionType].create(id, data));
        else
          unsupportedCount = unsupportedCount + 1
          allOptions["__unsupported" .. unsupportedCount] =  {
            __title = "|cFFFFFF00" .. childData.regionType,
            __order = 1,
            warning = {
              type = "description",
              name = L["Regions of type \"%s\" are not supported."]:format(childData.regionType),
              order = 1
            },
          }
        end
        for subRegionName, subRegionType in pairs(OptionsPrivate.Private.subRegionTypes) do
          if subRegionType.supports(childData.regionType) then
            supportedSubRegions[subRegionName] = true
          end
        end
      end
      if childData.subRegions then
        local subIndex = {}
        for index, subRegionData in ipairs(childData.subRegions) do
          local subRegionType = subRegionData.type
          local alreadyHandled = handledSubRegionTypes[index] and handledSubRegionTypes[index][subRegionType]
          if OptionsPrivate.Private.subRegionOptions[subRegionType] and not alreadyHandled then
            handledSubRegionTypes[index] = handledSubRegionTypes[index] or {}
            handledSubRegionTypes[index][subRegionType] = true
            hasSubElements = true
            subIndex[subRegionType] = subIndex[subRegionType] and subIndex[subRegionType] + 1 or 1

            local options, common = OptionsPrivate.Private.subRegionOptions[subRegionType].create(data, nil, index, subIndex[subRegionType])
            options.__order = 200 + index

            allOptions["sub." .. index .. "." .. subRegionType] = options
            commonOption[subRegionType] = common
          end
        end
      end
    end

    local commonOptionIndex = 0
    for option, optionData in pairs(commonOption) do
      commonOptionIndex = commonOptionIndex + 1
      optionData.__order = 100 + commonOptionIndex
      allOptions[option] = optionData
    end

    hasSubElements = AddOptionsForSupportedSubRegion(allOptions, data, supportedSubRegions) or hasSubElements

    if hasSubElements then
      allOptions["SubElementsHeader"] = {
        __order = 100,
        __noHeader = true,
        header = {
          order = 1,
          type = "header",
          name = L["Sub Elements"],
        }
      }
    end

    fixMetaOrders(allOptions);

    local region = {
      type = "group",
      name = L["Display"],
      order = 10,
      args = flattenRegionOptions(allOptions, false);
    };

    removeFuncs(region);
    replaceNameDescFuncs(region, data, "region");
    replaceImageFuncs(region, data, "region");
    replaceValuesFuncs(region, data, "region");

    region.get = function(info, ...) return getAll(data, info, ...); end;
    region.set = function(info, ...)
      setAll(data, info, ...);
      if(type(data.id) == "string") then
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        OptionsPrivate.ResetMoverSizer();
      end
    end
    region.hidden = function(info, ...) return hiddenAll(data, info, ...); end;
    region.disabled = function(info, ...) return disabledAll(data, info, ...); end;
    return region
  end

end
