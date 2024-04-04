if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L

local commonOptionsCache = {}
OptionsPrivate.commonOptionsCache = commonOptionsCache
commonOptionsCache.data = {}

commonOptionsCache.GetOrCreateData = function(self, info)
  local base = self.data
  for i, key in ipairs(info) do
    base[key] = base[key] or {}
    base = base[key]
  end
  return base
end

commonOptionsCache.GetData = function(self, info)
  local base = self.data
  for i, key in ipairs(info) do
    if base[key] and type(base[key]) == "table" then
      base = base[key]
    else
      return nil
    end
  end
  return base
end

commonOptionsCache.SetSameAll = function(self, info, value)
  local base = self:GetOrCreateData(info)
  base.sameAll = value
end

commonOptionsCache.GetSameAll = function(self, info)
  local base = self:GetData(info)
  if base then
    return base.sameAll
  end
end

commonOptionsCache.SetNameAll = function(self, info, value)
  local base = self:GetOrCreateData(info)
  base.nameAll = value
end

commonOptionsCache.GetNameAll = function(self, info)
  local base = self:GetData(info)
  if base then
    return base.nameAll
  end
end

commonOptionsCache.Clear = function(self)
  self.data = {}
end


local parsePrefix = function(input, data, create)
  local subRegionIndex, property = string.match(input, "^sub%.(%d+)%..-%.(.+)")
  subRegionIndex = tonumber(subRegionIndex)
  if subRegionIndex then
    if create then
      data.subRegions = data.subRegions or {}
      data.subRegions[subRegionIndex] = data.subRegions[subRegionIndex] or {}
    else
      if not data.subRegions or not data.subRegions[subRegionIndex] then
        return nil
      end
    end
    return data.subRegions[subRegionIndex], property
  end
  local index = string.find(input, ".", 1, true);
  if (index) then
    return data, string.sub(input, index + 1);
  end
  return data, input
end

local function setFuncs(option, input)
  if type(input) == "function" then
    option.func = input
  else
    option.func = input.func
    option.disabled = input.disabled
  end
end

local function addCollapsibleHeader(options, key, input, order, isGroupTab)
  if input.__noHeader then
    return
  end
  local title = input.__title
  local hasAdd = input.__add
  local hasDelete = input.__delete
  local hasUp = input.__up
  local hasDown = input.__down
  local hasDuplicate = input.__duplicate
  local hasApplyTemplate = input.__applyTemplate
  local defaultCollapsed = input.__collapsed
  local hiddenFunc = input.__hidden
  local notcollapsable = input.__notcollapsable
  local marginTop = input.__topLine
  local withoutheader = input.__withoutheader
  local isCollapsed = input.__isCollapsed
  local setCollapsed = input.__setCollapsed

  if not isCollapsed then
    isCollapsed = function()
      return OptionsPrivate.IsCollapsed("collapse", "region", key, defaultCollapsed)
    end
  end

  if not setCollapsed then
    setCollapsed = function(info, button, secondCall)
      if not notcollapsable and not secondCall then
        local isCollapsed = OptionsPrivate.IsCollapsed("collapse", "region", key, defaultCollapsed)
        OptionsPrivate.SetCollapsed("collapse", "region", key, not isCollapsed)
      end
    end
  end

  local titleWidth = WeakAuras.doubleWidth - (hasAdd and 0.15 or 0) - (hasDelete and 0.15 or 0)  - (hasUp and 0.15 or 0)
                     - (hasDown and 0.15 or 0) - (hasDuplicate and 0.15 or 0) - (hasApplyTemplate and 0.15 or 0)

  options[key .. "collapseSpacer"] = {
    type = marginTop and "header" or "description",
    name = "",
    order = order,
    width = "full",
    hidden = hiddenFunc,
  }

  if not withoutheader then
    options[key .. "collapseButton"] = {
      type = "execute",
      name = title,
      order = order + 0.1,
      width = titleWidth,
      func = setCollapsed,
      image = function()
        if notcollapsable then
          return "Interface\\AddOns\\WeakAuras\\Media\\Textures\\bullet1", 18, 18
        else
          return isCollapsed() and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand"
                                    or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse",
                                    18, 18
        end
      end,
      control = "WeakAurasExpand",
      hidden = hiddenFunc
    }

    if hasAdd then
      options[key .. "addButton"] = {
        type = "execute",
        name = L["Add"],
        order = order + 0.2,
        width = 0.15,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\add",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon",
        hidden = hiddenFunc
      }
      setFuncs(options[key .. "addButton"], input.__add)
    end

    if hasUp then
      options[key .. "upButton"] = {
        type = "execute",
        name = L["Move Up"],
        order = order + 0.3,
        width = 0.15,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon",
        hidden = hiddenFunc
      }
      setFuncs(options[key .. "upButton"], input.__up)
    end

    if hasDown then
      options[key .. "downButton"] = {
        type = "execute",
        name = L["Move Down"],
        order = order + 0.4,
        width = 0.15,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon",
        hidden = hiddenFunc
      }
      setFuncs(options[key .. "downButton"], input.__down)
    end

    if hasDuplicate then
      options[key .. "duplicateButton"] = {
        type = "execute",
        name = L["Duplicate"],
        order = order + 0.5,
        width = 0.15,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\duplicate",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon",
        hidden = hiddenFunc
      }
      setFuncs(options[key .. "duplicateButton"], input.__duplicate)
    end

    if hasDelete then
      options[key .. "deleteButton"] = {
        type = "execute",
        name = L["Delete"],
        order = order + 0.6,
        width = 0.15,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon",
        hidden = hiddenFunc
      }
      setFuncs(options[key .. "deleteButton"], input.__delete)
    end

    if hasApplyTemplate then
      options[key .. "applyTemplate"] = {
        type = "execute",
        name = L["Apply Template"],
        order = order + 0.7,
        width = 0.15,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\template",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon",
        hidden = hiddenFunc
      }
      setFuncs(options[key .. "applyTemplate"], input.__applyTemplate)
    end
  end

  if hiddenFunc then
    return function()
      return hiddenFunc() or isCollapsed()
    end
  else
    return isCollapsed
  end
end

local function copyOptionTable(input, orderAdjustment, collapsedFunc)
  local resultOption = CopyTable(input);
  resultOption.order = orderAdjustment + resultOption.order;
  if collapsedFunc then
    local oldHidden = resultOption.hidden;
    if oldHidden ~= nil then
      local oldFunc
      if type(oldHidden) ~= "function" then
        oldFunc = function(...) return oldHidden end
      else
        oldFunc = oldHidden
      end
      resultOption.hidden = function(...)
        if collapsedFunc() then
          return true
        else
          return oldFunc(...)
        end
      end
    else
      resultOption.hidden = collapsedFunc;
    end
  end
  return resultOption;
end

local flattenRegionOptions = function(allOptions, isGroupTab)
  local result = {};
  local base = 1000;

  for optionGroup, options in pairs(allOptions) do
    local groupBase = base * options.__order

    local collapsedFunc = addCollapsibleHeader(result, optionGroup, options, groupBase, isGroupTab)

    for optionName, option in pairs(options) do
      if not optionName:find("^__") then
        result[optionGroup .. "." .. optionName] = copyOptionTable(option, groupBase, collapsedFunc);
      end
    end
  end

  return result;
end

local function fixMetaOrders(allOptions)
  -- assumes that the results from create methods are contiguous in __order fields
  -- shifts __order fields such that each optionGroup is ordered correctly relative
  -- to its peers, but has a unique __order number in the combined option table.
  local groupOrders = {}
  local maxGroupOrder = 0
  for optionGroup, options in pairs(allOptions) do
    local metaOrder = options.__order
    groupOrders[metaOrder] = groupOrders[metaOrder] or {}
    maxGroupOrder = max(maxGroupOrder, metaOrder)
    tinsert(groupOrders[metaOrder], optionGroup)
  end

  local index = 0
  local newOrder = 1
  while index <= maxGroupOrder do
    index = index + 1
    if groupOrders[index] then
      table.sort(groupOrders[index])
      for _, optionGroup in ipairs(groupOrders[index]) do
        allOptions[optionGroup].__order = newOrder
        newOrder = newOrder + 1
      end
    end
  end
end

local function removeFuncs(intable, removeFunc)
  for i,v in pairs(intable) do
    if(i == "get" or i == "set" or i == "hidden" or i == "disabled") then
      intable[i] = nil;
    elseif (i == "func" and removeFunc) then
      intable[i] = nil
    elseif(type(v) == "table" and i ~= "values" and i ~= "extraFunctions") then
      removeFuncs(v, removeFunc)
    end
  end
end

local function getChildOption(options, info)
  for i=1,#info do
    options = options.args[info[i]];
    if not(options) then
      return nil;
    end

    if (options.hidden) then
      local type = type(options.hidden);
      if (type == "bool") then
        if (options.hidden) then
          return nil;
        end
      elseif (type == "function") then
        if (options.hidden(info)) then
          return nil;
        end
      end
    end
  end
  return options
end

local function hiddenChild(childOptionTable, info)
  for i=#childOptionTable,0,-1 do
    if(childOptionTable[i].hidden ~= nil) then
      if(type(childOptionTable[i].hidden) == "boolean") then
        return childOptionTable[i].hidden;
      elseif(type(childOptionTable[i].hidden) == "function") then
        return childOptionTable[i].hidden(info);
      end
    end
  end
  return false;
end

local function CreateHiddenAll(subOption)
  return function(data, info)
    local mainOptions = OptionsPrivate.EnsureOptions(data, subOption)
    for i=1,#info do
      mainOptions = mainOptions.args[info[i]];
    end

    if(#data.controlledChildren == 0) then
      if mainOptions.hiddenAllIfAnyHidden then
        return false
      else
        return true
      end
    end

    for child in  OptionsPrivate.Private.TraverseLeafs(data) do
      local childOptions = OptionsPrivate.EnsureOptions(child, subOption)
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end
      if (childOption) then
        local childHidden = hiddenChild(childOptionTable, info)
        if mainOptions.hiddenAllIfAnyHidden then
          if childHidden then
            return true
          end
        else
          if not childHidden then
            return false
          end
        end
      end
    end

    if mainOptions.hiddenAllIfAnyHidden then
      return false
    else
      return true
    end
  end
end

local function disabledChild(childOptionTable, info)
  for i=#childOptionTable,0,-1 do
    if(childOptionTable[i].disabled ~= nil) then
      if(type(childOptionTable[i].disabled) == "boolean") then
        return childOptionTable[i].disabled;
      elseif(type(childOptionTable[i].disabled) == "function") then
        return childOptionTable[i].disabled(info);
      end
    end
  end
  return false;
end

local function CreateDisabledAll(subOption)
  return function(data, info)
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      local childOptions = OptionsPrivate.EnsureOptions(child, subOption);
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end
      if (childOption) then
        if (not disabledChild(childOptionTable, info)) then
          return false;
        end
      end
    end

    return true;
  end
end

local function disabledOrHiddenChild(childOptionTable, info)
  return hiddenChild(childOptionTable, info) or disabledChild(childOptionTable, info);
end


local function replaceNameDescFuncs(intable, data, subOption)
  local function compareTables(tableA, tableB)
    if(#tableA == #tableB) then
      for j=1,#tableA do
        if(type(tableA[j]) == "number" and type(tableB[j]) == "number") then
          if((math.floor(tableA[j] * 100) / 100) ~= (math.floor(tableB[j] * 100) / 100)) then
            return false;
          end
        else
          if(tableA[j] ~= tableB[j]) then
            return false;
          end
        end
      end
    else
      return false;
    end
    return true;
  end

  local function getValueFor(options, info, key)
    local childOptionTable = {[0] = options};
    for i=1,#info do
      options = options.args[info[i]];
      if (not options) then
        return nil;
      end
      childOptionTable[i] = options;
    end

    if (disabledOrHiddenChild(childOptionTable, info)) then
      return nil;
    end

    for i=#childOptionTable,0,-1 do
      if(childOptionTable[i][key]) then
        return childOptionTable[i][key];
      end
    end
    return nil;
  end

  local function combineKeys(info)
    local combinedKeys = nil;
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      local values = getValueFor(OptionsPrivate.EnsureOptions(child, subOption), info, "values");
      if (values) then
        if (type(values) == "function") then
          values = values(info);
        end
        if (type(values) == "table") then
          combinedKeys = combinedKeys or {};
          for k, v in pairs(values) do
            combinedKeys[k] = v;
          end
        end
      end
    end
    return combinedKeys;
  end

  local function regionPrefix(input)
    local index = string.find(input, ".", 1, true);
    if (index) then
      local regionType = string.sub(input, 1, index - 1);
      return OptionsPrivate.Private.regionOptions[regionType] and regionType;
    end
    return nil;
  end

  local function sameAll(info)
    local cached = commonOptionsCache:GetSameAll(info)
    if (cached ~= nil) then
      return cached
    end

    local combinedValues = {};
    local first = true;
    local combinedKeys = combineKeys(info);

    local isToggle = nil

    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      if isToggle == nil then
        local childOption = getChildOption(OptionsPrivate.EnsureOptions(child, subOption), info)
        isToggle = childOption and childOption.type == "toggle"
      end

      local regionType = regionPrefix(info[#info]);
      if(child and (not regionType or child.regionType == regionType or regionType == "sub")) then
        local childOptions = OptionsPrivate.EnsureOptions(child, subOption)
        local get = getValueFor(childOptions, info, "get");
        if (combinedKeys) then
          for key, _ in pairs(combinedKeys) do
            local values = {};
            if (get) then
              values = { get(info, key) };
            end
            if (combinedValues[key] == nil) then
              combinedValues[key] = values;
            else
              if (not compareTables(combinedValues[key], values)) then
                commonOptionsCache:SetSameAll(info, false)
                return nil;
              end
            end
          end
        else
          local values = {};
          if (get) then
            values = { get(info) };
            if isToggle and values[1] == nil then
              values[1] = false
            end
          end
          if(first) then
            combinedValues = values;
            first = false;
          else
            if (not compareTables(combinedValues, values)) then
              commonOptionsCache:SetSameAll(info, false)
              return nil;
            end
          end
        end
      end
    end

    commonOptionsCache:SetSameAll(info, true)
    return true;
  end

  local function nameAll(info)
    local cached = commonOptionsCache:GetNameAll(info)
    if (cached ~= nil) then
      return cached
    end

    local combinedName;
    local first = true;
    local foundNames = {};
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      local childOption = getChildOption(OptionsPrivate.EnsureOptions(child, subOption), info);
      if (childOption) then
        local name;
        if(type(childOption.name) == "function") then
          name = childOption.name(info);
        else
          name = childOption.name;
          commonOptionsCache:SetNameAll(info, name)
          return name
        end
        if (not name) then
        -- Do nothing
        elseif(first) then
          if (name ~= "") then
            combinedName = name;
            first = false;
          end
          foundNames[name] = true;
        elseif not(foundNames[name]) then
          if (name ~= "") then
            if (childOption.type == "description") then
              combinedName = combinedName .. "\n\n" .. name;
            else
              combinedName = combinedName .. " / " .. name;
            end
          end
          foundNames[name] = true;
        end
      end
    end
    if combinedName then
      commonOptionsCache:SetNameAll(info, combinedName)
    end

    return combinedName or ""
  end

  local function descAll(info)
    local combinedDesc;
    local first = true;
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      local childOption = getChildOption(OptionsPrivate.EnsureOptions(child, subOption), info);
      if (childOption) then
        local desc;
        if(type(childOption.desc) == "function") then
          desc = childOption.desc(info);
        else
          desc = childOption.desc;
        end
        if(first) then
          combinedDesc = desc;
          first = false;
        elseif not(combinedDesc == desc) then
          return L["Not all children have the same value for this option"];
        end
      end
    end
    return combinedDesc;
  end

  local function recurse(intable)
    for i,v in pairs(intable) do
      if(i == "name" and type(v) ~= "table") then
        intable.name = function(info)
          local name = nameAll(info);
          if(sameAll(info)) then
            return name;
          else
            if(name == "") then
              return name;
            else
              return "|cFF4080FF"..(name or "error").."|r";
            end
          end
        end
        intable.desc = function(info)
          if(sameAll(info)) then
            return descAll(info);
          else
            local combinedKeys = nil;
            if (intable.type == "multiselect") then
              combinedKeys = combineKeys(info)
            end

            local values = {};
            for child in OptionsPrivate.Private.TraverseLeafs(data) do
              local childOptions = OptionsPrivate.EnsureOptions(child, subOption)
              local childOption = childOptions;
              local childOptionTable = {[0] = childOption};
              for i=1,#info do
                childOption = childOption.args[info[i]];
                childOptionTable[i] = childOption;
              end
              if (childOption and not hiddenChild(childOptionTable, info)) then
                for i=#childOptionTable,0,-1 do
                  if(childOptionTable[i].get) then
                    if(intable.type == "toggle") then
                      local name, tri;
                      if(type(childOption.name) == "function") then
                        name = childOption.name(info);
                        tri = true;
                      else
                        name = childOption.name;
                      end
                      if(tri and childOptionTable[i].get(info)) then
                        tinsert(values, "|cFFE0E000"..child.id..": |r"..name);
                      elseif(tri) then
                        tinsert(values, "|cFFE0E000"..child.id..": |r"..L["Ignored"]);
                      elseif(childOptionTable[i].get(info)) then
                        tinsert(values, "|cFFE0E000"..child.id..": |r|cFF00FF00"..L["Enabled"].."|r");
                      else
                        tinsert(values, "|cFFE0E000"..child.id..": |r|cFFFF0000"..L["Disabled"].."|r");
                      end
                    elseif(intable.type == "color") then
                      local r, g, b = childOptionTable[i].get(info);
                      r, g, b = r or 1, g or 1, b or 1;
                      tinsert(values, ("|cFF%2x%2x%2x%s|r"):format(r * 220 + 35, g * 220 + 35, b * 220 + 35, child.id));
                    elseif(intable.type == "select") then
                      local selectValues = type(intable.values) == "table" and intable.values or intable.values(info);
                      local key = childOptionTable[i].get(info);
                      local display = key and selectValues[key] or L["None"];
                      if intable.dialogControl == "LSM30_Font" then
                        tinsert(values, "|cFFE0E000"..child.id..": |r" .. key);
                      else
                        if type(display) == "string" then
                          tinsert(values, "|cFFE0E000"..child.id..": |r"..display);
                        elseif type(display) == "table" then
                          tinsert(values, "|cFFE0E000"..child.id..": |r"..display[1].."/"..display[2] );
                        end
                      end
                    elseif(intable.type == "multiselect") then
                      local selectedValues = {};
                      for k, v in pairs(combinedKeys) do
                        if (childOptionTable[i].get(info, k)) then
                          tinsert(selectedValues, tostring(v))
                        end
                      end
                      tinsert(values, "|cFFE0E000"..child.id..": |r"..table.concat(selectedValues, ","));
                    else
                      local display = childOptionTable[i].get(info) or L["None"];
                      if(type(display) == "number") then
                        display = math.floor(display * 100) / 100;
                      else
                        local nullBytePos = display:find("\0", nil, true)
                        if nullBytePos then
                          display = display:sub(1, nullBytePos - 1)
                        end

                        if #display > 50 then
                          display = display:sub(1, 50) .. "..."
                        end
                      end
                      tinsert(values, "|cFFE0E000"..child.id..": |r"..display);
                    end
                    break;
                  end
                end
              end
            end
            return table.concat(values, "\n");
          end
        end
      elseif(type(v) == "table" and i ~= "values") then
        recurse(v);
      end
    end
  end
  recurse(intable);
end

local function replaceImageFuncs(intable, data, subOption)
  local function imageAll(info)
    local combinedImage = {};
    local first = true;
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      local childOption = OptionsPrivate.EnsureOptions(child, subOption)
      if not(childOption) then
        return "error"
      end
      childOption = getChildOption(childOption, info);
      if childOption and childOption.image then
        local image = {childOption.image(info)};
        if(first) then
          combinedImage = image;
          first = false;
        else
          if not(combinedImage[1] == image[1]) then
            return "", 0, 0;
          end
        end
      end
    end

    return unpack(combinedImage);
  end

  local function recurse(intable)
    for i,v in pairs(intable) do
      if(i == "image" and type(v) == "function") then
        intable[i] = imageAll;
      elseif(type(v) == "table" and i ~= "values") then
        recurse(v);
      end
    end
  end
  recurse(intable);
end

local concatenableTypes = {
  string = true,
  number = true
}
local function isConcatenableValue(value)
  return value and concatenableTypes[type(value)]
end
local function replaceValuesFuncs(intable, data, subOption)
  local function valuesAll(info)
    local combinedValues = {};
    local handledValues = {};
    local first = true;
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      local childOption = OptionsPrivate.EnsureOptions(child, subOption)
      if not(childOption) then
        return "error"
      end

      childOption = getChildOption(childOption, info);
      if (childOption) then
        local values = childOption.values;
        if (type(values) == "function") then
          values = values(info);
        end
        if(first) then
          for k, v in pairs(values) do
            handledValues[k] = handledValues[k] or {};
            handledValues[k][v] = true;
            combinedValues[k] = v;
          end
          first = false;
        else
          for k, v in pairs(values) do
            if (handledValues[k] and handledValues[k][v]) then
            -- Already known key/value pair
            else
              if (combinedValues[k]) then
                if isConcatenableValue(k) and isConcatenableValue(v) then
                  combinedValues[k] = combinedValues[k] .. "/" .. v;
                end
              else
                combinedValues[k] = v;
              end
              handledValues[k] = handledValues[k] or {};
              handledValues[k][v] = true;
            end
          end
        end
      end
    end

    return combinedValues;
  end

  local function recurse(intable)
    for i,v in pairs(intable) do
      if(i == "values" and type(v) == "function") then
        intable[i] = valuesAll;
      elseif(type(v) == "table" and i ~= "values") then
        recurse(v);
      end
    end
  end
  recurse(intable);
end

local getHelper = {
  first = true,
  combinedValues = {},
  same = true,
  Set = function(self, values)
    if self.same == false then
      return false
    end
    if(self.first) then
      self.combinedValues = values;
      self.first = false;
      return true
    else
      if(#self.combinedValues == #values) then
        for j=1,#self.combinedValues do
          if(type(self.combinedValues[j]) == "number" and type(values[j]) == "number") then
            if((math.floor(self.combinedValues[j] * 100) / 100) ~= (math.floor(values[j] * 100) / 100)) then
              self.same = false;
              break;
            end
          else
            if(self.combinedValues[j] ~= values[j]) then
              self.same = false;
              break;
            end
          end
        end
      else
        self.same = false;
      end
      return self.same
    end
  end,
  Get = function(self)
    return self.combinedValues
  end,
  GetSame = function(self)
    return self.same
  end,
  HasValue = function(self)
    return not self.first
  end
}


local function CreateGetAll(subOption)
  return function(data, info, ...)
    local isToggle = nil
    local isColor = nil

    local allChildren = CopyTable(getHelper)
    local enabledChildren = CopyTable(getHelper)
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      if isToggle == nil or isColor == nil then
        local childOptions = getChildOption(OptionsPrivate.EnsureOptions(child, subOption), info)
        isToggle = childOptions and childOptions.type == "toggle"
        isColor = childOptions and childOptions.type == "color"
      end


      local childOptions = OptionsPrivate.EnsureOptions(child, subOption)
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end
      if (childOption) then
        for i=#childOptionTable,0,-1 do
          if(childOptionTable[i].get) then
            local values = {childOptionTable[i].get(info, ...)};
            if isToggle and values[1] == nil then
              values[1] = false
            end

            allChildren:Set(values)
            if not disabledOrHiddenChild(childOptionTable, info) then
                enabledChildren:Set(values)
            end

            if not allChildren:GetSame() and not enabledChildren:GetSame() then
              if isColor then
                return 0, 0, 0, 1
              end
              return nil;
            end
            break;
          end
        end
      end
    end

    if enabledChildren:HasValue() then
      return unpack(enabledChildren:Get())
    else
      -- This can happen if all children are disabled
      return unpack(allChildren:Get())
    end
  end
end

local function CreateSetAll(subOption, getAll)
  return function(data, info, ...)
    OptionsPrivate.Private.pauseOptionsProcessing(true);
    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    local before = getAll(data, info, ...)
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      local childOptions = OptionsPrivate.EnsureOptions(child, subOption)
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end

      if (childOption and not disabledOrHiddenChild(childOptionTable, info)) then
        for i=#childOptionTable,0,-1 do
          local optionTable = childOptionTable[i]
          if(optionTable.set) then
            if (optionTable.type == "multiselect") then
              local newValue
              if optionTable.multiTristate then
                if before == true then
                  newValue = false
                elseif before == false then
                  newValue = nil
                elseif before == nil then
                  newValue = true
                end
              else
                newValue = not before
              end
              optionTable.set(info, ..., newValue)
            else
              optionTable.set(info, ...);
            end
            break;
          end
        end
      end
    end

    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
    OptionsPrivate.Private.pauseOptionsProcessing(false);
    OptionsPrivate.Private.ScanForLoads();
    OptionsPrivate.SortDisplayButtons(nil, true);
    OptionsPrivate.UpdateOptions()
  end
end

local function CreateExecuteAll(subOption)
  return function(data, info, button)
    local secondCall = nil
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      local childOptions = OptionsPrivate.EnsureOptions(child, subOption)
      local childOption = childOptions;
      local childOptionTable = {[0] = childOption};
      for i=1,#info do
        childOption = childOption.args[info[i]];
        childOptionTable[i] = childOption;
      end

      if (childOption and not disabledOrHiddenChild(childOptionTable, info)) then
        -- Some functions, that is the expand/collapse functions need to be
        -- effectively called only once. Passing in the secondCall parameter allows
        -- them to distinguish between the first and every other call
        childOption.func(info, button, secondCall)
        secondCall = true
      end
    end
    WeakAuras.ClearAndUpdateOptions(data.id)
  end
end

local function ProgressOptions(data)
  local order = 1
  local options = {
    __title = L["Progress Settings"],
    __order = 98,
  }

  options.progressSource = {
    type = "select",
    width = WeakAuras.doubleWidth,
    name = L["Progress Source"],
    order = order,
    control = "WeakAurasTwoColumnDropdown",
    values = OptionsPrivate.Private.GetProgressSourcesForUi(data),
    get = function(info)
      return OptionsPrivate.Private.GetProgressValueConstant(data.progressSource)
    end,
    set = function(info, value)
      if value then
        data.progressSource = data.progressSource or {}
        -- Copy only trigger + property
        data.progressSource[1] = value[1]
        data.progressSource[2] = value[2]
      else
        data.progressSource = nil
      end
      WeakAuras.Add(data)
    end
  }

  options.progressSourceWarning = {
    type = "description",
    width = WeakAuras.doubleWidth,
    name = L["Note: This progress source does not provide a total value/duration. A total value/duration must be set via \"Set Maximum Progress\""],
    order = order + 0.5,
    hidden = function()
      local progressSource = OptionsPrivate.Private.AddProgressSourceMetaData(data, data.progressSource)
      -- Auto progress, Manual Progress or the progress source has a total property
      if not progressSource or progressSource[2] == "auto" or progressSource[1] == 0 or progressSource[4] ~= nil then
        return true
      end
      return false
    end
  }

  local function hiddenManual()
    if data.progressSource and data.progressSource[1] == 0 then
      return false
    end
    return true
  end

  options.progressSourceManualValue = {
    type = "range",
    control = "WeakAurasSpinBox",
    width = WeakAuras.normalWidth,
    name = L["Value"],
    order = order + 0.7,
    min = 0,
    softMax = 100,
    bigStep = 1,
    hidden = hiddenManual,
    get = function(info)
      return data.progressSource and data.progressSource[3] or 0
    end,
    set = function(info, value)
      data.progressSource = data.progressSource or {}
      data.progressSource[3] = value
      WeakAuras.Add(data)
    end
  }

  options.progressSourceManualTotal = {
    type = "range",
    control = "WeakAurasSpinBox",
    width = WeakAuras.normalWidth,
    name = L["Total"],
    order = order + 0.8,
    min = 0,
    softMax = 100,
    bigStep = 1,
    hidden = hiddenManual,
    get = function(info)
      return data.progressSource and data.progressSource[4] or 100
    end,
    set = function(info, value)
      data.progressSource = data.progressSource or {}
      data.progressSource[4] = value
      WeakAuras.Add(data)
    end
  }

  options.useAdjustededMin = {
    type = "toggle",
    width = WeakAuras.normalWidth,
    name = L["Set Minimum Progress"],
    desc = L["Values/Remaining Time below this value are displayed as zero progress."],
    order = order + 1
  };

  options.adjustedMin = {
    type = "input",
    validate = WeakAuras.ValidateNumericOrPercent,
    width = WeakAuras.normalWidth,
    order = order + 2,
    name = L["Minimum"],
    hidden = function() return not data.useAdjustededMin end,
    desc = L["Enter static or relative values with %"]
  };

  options.useAdjustedMinSpacer = {
    type = "description",
    width = WeakAuras.normalWidth,
    name = "",
    order = order + 3,
    hidden = function() return not (not data.useAdjustededMin and data.useAdjustededMax) end,
  }

  options.useAdjustededMax = {
    type = "toggle",
    width = WeakAuras.normalWidth,
    name = L["Set Maximum Progress"],
    desc = L["Values/Remaining Time above this value are displayed as full progress."],
    order = order + 4
  }

  options.adjustedMax = {
    type = "input",
    width = WeakAuras.normalWidth,
    validate = WeakAuras.ValidateNumericOrPercent,
    order = order + 5,
    name = L["Maximum"],
    hidden = function() return not data.useAdjustededMax end,
    desc = L["Enter static or relative values with %"]
  }

  options.useAdjustedMaxSpacer = {
    type = "description",
    width = WeakAuras.normalWidth,
    name = "",
    order = order + 6,
    hidden = function() return not (data.useAdjustededMin and not data.useAdjustededMax) end,
  }

  return options
end

local function PositionOptions(id, data, _, hideWidthHeight, disableSelfPoint, group)
  local metaOrder = 99
  local function IsParentDynamicGroup()
    if data.parent then
      local parentData = WeakAuras.GetData(data.parent)
      return parentData and parentData.regionType == "dynamicgroup"
    end
  end

  local function IsGroupByFrame()
    return data.regionType == "dynamicgroup" and data.useAnchorPerUnit
  end

  local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;
  local positionOptions = {
    __title = L["Position Settings"],
    __order = metaOrder,
    width = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Width"],
      order = 60,
      min = 1,
      softMax = screenWidth,
      max = 4 * screenWidth,
      bigStep = 1,
      hidden = hideWidthHeight,
    },
    height = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Height"],
      order = 61,
      min = 1,
      softMax = screenHeight,
      max = 4 * screenHeight,
      bigStep = 1,
      hidden = hideWidthHeight,
    },
    anchorFrameType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Anchored To"],
      order = 70,
      hidden = function()
        return IsParentDynamicGroup() or IsGroupByFrame()
      end,
      values = (data.regionType == "group" or data.regionType == "dynamicgroup")
                and OptionsPrivate.Private.anchor_frame_types_group
                or OptionsPrivate.Private.anchor_frame_types,
      sorting = OptionsPrivate.Private.SortOrderForValues(
                (data.regionType == "group" or data.regionType == "dynamicgroup")
                and OptionsPrivate.Private.anchor_frame_types_group
                or OptionsPrivate.Private.anchor_frame_types),
    },
    anchorFrameParent = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Set Parent to Anchor"],
      desc = L["Sets the anchored frame as the aura's parent, causing the aura to inherit attributes such as visibility and scale."],
      order = 71,
      get = function()
        return data.anchorFrameParent or data.anchorFrameParent == nil;
      end,
      hidden = function()
        return not IsGroupByFrame() and (data.anchorFrameType == "SCREEN" or data.anchorFrameType == "UIPARENT" or data.anchorFrameType == "MOUSE" or IsParentDynamicGroup());
      end,
    },
    anchorFrameSpaceOne = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = "",
      order = 72,
      image = function() return "", 0, 0 end,
      hidden = function()
        return IsParentDynamicGroup() or not (data.anchorFrameType == "SCREEN" or data.anchorFrameType == "UIPARENT" or data.anchorFrameType == "MOUSE" or IsGroupByFrame())
      end,
    },
    -- Input field to select frame to anchor on
    anchorFrameFrame = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Frame"],
      order = 73,
      hidden = function()
        if (IsParentDynamicGroup() or IsGroupByFrame()) then
          return true;
        end
        return not (data.anchorFrameType == "SELECTFRAME")
      end
    },
    -- Button to select frame to anchor on
    chooseAnchorFrameFrame = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = L["Choose"],
      order = 74,
      hidden = function()
        if (IsParentDynamicGroup() or IsGroupByFrame()) then
          return true;
        end
        return not (data.anchorFrameType == "SELECTFRAME")
      end,
      func = function()
        OptionsPrivate.StartFrameChooser(data, {"anchorFrameFrame"});
      end
    },
    selfPoint = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Anchor"],
      order = 75,
      hidden = IsParentDynamicGroup,
      values = OptionsPrivate.Private.point_types,
      disabled = disableSelfPoint,
      control = "WeakAurasAnchorButtons",
    },
    anchorPoint = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = function()
        if (data.anchorFrameType == "SCREEN" or data.anchorFrameType == "UIPARENT") then
          return L["To Screen's"]
        elseif (data.anchorFrameType == "PRD") then
          return L["To Personal Ressource Display's"];
        else
          return L["To Frame's"];
        end
      end,
      order = 76,
      hidden = function()
        if (data.parent) then
          if IsGroupByFrame() then
            return false
          end
          if IsParentDynamicGroup() then
            return true
          end
          return data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE";
        else
          return data.anchorFrameType == "MOUSE";
        end
      end,
      values = OptionsPrivate.Private.point_types,
      control = "WeakAurasAnchorButtons",
    },
    anchorPointGroup = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["To Group's"],
      order = 77,
      hidden = function()
        if IsGroupByFrame() then
          return true
        end
        if (data.anchorFrameType ~= "SCREEN") then
          return true;
        end
        if (data.parent) then
          return IsParentDynamicGroup();
        end
        return true;
      end,
      disabled = true,
      values = {["CENTER"] = L["Anchor Point"]},
      get = function() return "CENTER"; end,
      control = "WeakAurasAnchorButtons",
    },
    anchorFramePoints = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = "",
      order = 78,
      image = function() return "", 0, 0 end,
      hidden = function()
        return not (data.anchorFrameType == "MOUSE") or IsParentDynamicGroup();
      end
    },
    xOffset = {
      type = "range",
      control = "WeakAurasSpinBox",
      name = L["X Offset"],
      order = 79,
      width = WeakAuras.normalWidth,
      softMin = (-1 * screenWidth),
      min = (-4 * screenWidth),
      softMax = screenWidth,
      max = 4 * screenWidth,
      bigStep = 10,
      get = function() return data.xOffset end,
      set = function(info, v)
        data.xOffset = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        OptionsPrivate.ResetMoverSizer();
        OptionsPrivate.Private.AddParents(data)
      end
    },
    yOffset = {
      type = "range",
      control = "WeakAurasSpinBox",
      name = L["Y Offset"],
      order = 80,
      width = WeakAuras.normalWidth,
      softMin = (-1 * screenHeight),
      min = (-4 * screenHeight),
      softMax = screenHeight,
      max = 4 * screenHeight,
      bigStep = 10,
      get = function() return data.yOffset end,
      set = function(info, v)
        data.yOffset = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        OptionsPrivate.ResetMoverSizer();
        OptionsPrivate.Private.AddParents(data)
      end
    },
    frameStrata = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Frame Strata"],
      order = 81,
      values = OptionsPrivate.Private.frame_strata_types
    },
    anchorFrameSpace = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = "",
      order = 82,
      image = function() return "", 0, 0 end,
      hidden = function()
        return not (data.anchorFrameType ~= "SCREEN" or data.anchorFrameType ~= "UIPARENT" or IsParentDynamicGroup());
      end
    },
  };

  OptionsPrivate.commonOptions.AddCodeOption(positionOptions, data, L["Custom Anchor"], "custom_anchor",
                      "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-anchor-function",
                      71.5, function() return not(data.anchorFrameType == "CUSTOM" and not IsParentDynamicGroup() and not IsGroupByFrame()) end,
                      {"customAnchor"}, false, { setOnParent = group })
  return positionOptions;
end

local function BorderOptions(id, data, showBackDropOptions, hiddenFunc, order)
  local borderOptions = {
    borderHeader = {
      type = "header",
      order = order,
      name = L["Border Settings"],
      hidden = hiddenFunc,
    },
    border = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Show Border"],
      order = order + 0.1,
      hidden = hiddenFunc,
    },
    borderEdge = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Border",
      name = L["Border Style"],
      order = order + 0.2,
      values = AceGUIWidgetLSMlists.border,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderBackdrop = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Background",
      name = L["Backdrop Style"],
      order = order + 0.3,
      values = AceGUIWidgetLSMlists.background,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderOffset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Border Offset"],
      order = order + 0.3,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderSize = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Border Size"],
      order = order + 0.4,
      min = 1,
      softMax = 64,
      bigStep = 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderInset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Border Inset"],
      order = order + 0.5,
      softMin = 1,
      softMax = 32,
      bigStep = 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    border_spacer = {
      type = "description",
      name = "",
      width = WeakAuras.normalWidth,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
      order = order + 0.6
    },
    borderColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Border Color"],
      hasAlpha = true,
      order = order + 0.7,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderInFront  = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Border in Front"],
      order = order + 0.8,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border or not showBackDropOptions end,
    },
    backdropColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Backdrop Color"],
      hasAlpha = true,
      order = order + 0.9,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    backdropInFront  = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Backdrop in Front"],
      order = order + 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border or not showBackDropOptions end,
    },
  }

  return borderOptions;
end

local function noop()
end

local function GetCustomCode(data, path)
  for _, key in ipairs(path) do
    if (not data or not data[key]) then
      return nil;
    end
    data = data[key];
  end
  return data;
end

local function AddCodeOption(args, data, name, prefix, url, order, hiddenFunc, path, encloseInFunction, options)
  options = options and CopyTable(options) or {}
  options.extraFunctions = options.extraFunctions or {};
  tinsert(options.extraFunctions, 1, {
    buttonLabel = L["Expand"],
    func = function()
      OptionsPrivate.OpenTextEditor(OptionsPrivate.GetPickedDisplay(), path, encloseInFunction, options.multipath,
                                    options.reloadOptions, options.setOnParent, url, options.validator)
    end
  });

  args[prefix .. "_custom"] = {
    type = "input",
    width = WeakAuras.doubleWidth,
    name = name,
    order = order,
    multiline = true,
    hidden = hiddenFunc,
    control = "WeakAurasMultiLineEditBox",
    arg = {
      extraFunctions = options.extraFunctions,
    },
    set = function(info, v)
      local subdata = data;
      for i = 1, #path -1 do
        local key = path[i];
        subdata[key] = subdata[key] or {};
        subdata = subdata[key];
      end

      subdata[path[#path]] = v;
      WeakAuras.Add(data);
      if (options.extraSetFunction) then
        options.extraSetFunction();
      end
      if (options.reloadOptions) then
        OptionsPrivate.ClearOptions(data.id)
      end
    end,
    get = function(info)
      return GetCustomCode(data, path);
    end
  };

  args[prefix .. "_customError"] = {
    type = "description",
    name = function()
      if hiddenFunc() then
        return "";
      end

      local code = GetCustomCode(data, path);

      if (not code or code:trim() == "") then
        return ""
      end

      if (encloseInFunction) then
        code = "function() "..code.."\n end";
      end

      code = "return " .. code;

      local loadedFunction, errorString = loadstring(code);

      if not errorString then
        if options.validator then
          local ok, validate = xpcall(loadedFunction, function(err) errorString = err end)
          if ok then
            errorString = options.validator(validate)
          end
        end
      end
      return errorString and "|cFFFF0000"..errorString or "";
    end,
    width = WeakAuras.doubleWidth,
    order = order + 0.002,
    hidden = function()
      if (hiddenFunc()) then
        return true;
      end

      local code = GetCustomCode(data, path);
      if (not code or code:trim() == "") then
        return true;
      end

      if (encloseInFunction) then
        code = "function() "..code.."\n end";
      end

      code = "return " .. code;

      local loadedFunction, errorString = loadstring(code);
      if(errorString and not loadedFunction) then
        return false;
      else
        if options.validator then
          local ok, validate = xpcall(loadedFunction, noop)
          if ok then
            return options.validator(validate)
          end
          return false
        end
        return true;
      end
    end
  };
end

local function AddCommonTriggerOptions(options, data, triggernum, doubleWidth)
  local trigger = data.triggers[triggernum].trigger

  local trigger_types = {};
  for type, triggerSystem in pairs(OptionsPrivate.Private.triggerTypes) do
    trigger_types[type] = triggerSystem.GetName(type);
  end

  options.type = {
    type = "select",
    width = doubleWidth and WeakAuras.doubleWidth or WeakAuras.normalWidth,
    name = L["Type"],
    desc = L["The type of trigger"],
    order = 1.1,
    values = trigger_types,
    sorting = OptionsPrivate.Private.SortOrderForValues(trigger_types),
    get = function()
      return trigger.type
    end,
    set = function(info, v)
      trigger.type = v;
      local prototype = trigger.event and OptionsPrivate.Private.event_prototypes[trigger.event];
      if OptionsPrivate.Private.event_categories[v] and OptionsPrivate.Private.event_categories[v].default then
        if not prototype or prototype.type ~= v then
          trigger.event = OptionsPrivate.Private.event_categories[v].default
        end
      end
      WeakAuras.Add(data);
      WeakAuras.UpdateThumbnail(data);
      WeakAuras.ClearAndUpdateOptions(data.id);
    end,
  }
end

-- Adds setters/getters to trigger options
-- This is used by both aura triggers
local function AddTriggerGetterSetter(options, data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  for key, option in pairs(options) do
    if type(option) == "table" and not option.get then
      if option.type == "multiselect" then
        option.get = function(info, index)
          return trigger[key] and trigger[key][index]
        end
      else
        option.get = function(info)
          return trigger[key]
        end
      end
    end
    if type(option) == "table" and not option.set then
      if option.type == "multiselect" then
        option.set = function(info, index, value)
          if type(trigger[key]) ~= "table" then
            trigger[key] = {}
          end
          if value ~= nil then
            if value then
              trigger[key][index] = true
            else
              trigger[key][index] = nil
            end
          else
            if trigger[key][index] then
              trigger[key][index] = nil
            else
              trigger[key][index] = true
            end
          end
          if next(trigger[key]) == nil then
            trigger[key] = nil
          end

          WeakAuras.Add(data)
          WeakAuras.ClearAndUpdateOptions(data.id)
        end
      else
        option.set = function(info, v)
          trigger[key] = v
          WeakAuras.Add(data)
          WeakAuras.ClearAndUpdateOptions(data.id)
        end
      end
    end
  end
end


OptionsPrivate.commonOptions = {}
OptionsPrivate.commonOptions.parsePrefix = parsePrefix
OptionsPrivate.commonOptions.flattenRegionOptions = flattenRegionOptions
OptionsPrivate.commonOptions.fixMetaOrders = fixMetaOrders
OptionsPrivate.commonOptions.removeFuncs = removeFuncs
OptionsPrivate.commonOptions.CreateHiddenAll = CreateHiddenAll
OptionsPrivate.commonOptions.CreateDisabledAll = CreateDisabledAll
OptionsPrivate.commonOptions.replaceNameDescFuncs = replaceNameDescFuncs
OptionsPrivate.commonOptions.replaceImageFuncs = replaceImageFuncs
OptionsPrivate.commonOptions.replaceValuesFuncs = replaceValuesFuncs
OptionsPrivate.commonOptions.CreateGetAll = CreateGetAll
OptionsPrivate.commonOptions.CreateSetAll = CreateSetAll
OptionsPrivate.commonOptions.CreateExecuteAll = CreateExecuteAll

OptionsPrivate.commonOptions.PositionOptions = PositionOptions
OptionsPrivate.commonOptions.ProgressOptions = ProgressOptions
OptionsPrivate.commonOptions.BorderOptions = BorderOptions
OptionsPrivate.commonOptions.AddCodeOption = AddCodeOption

OptionsPrivate.commonOptions.AddCommonTriggerOptions = AddCommonTriggerOptions
OptionsPrivate.commonOptions.AddTriggerGetterSetter = AddTriggerGetterSetter

