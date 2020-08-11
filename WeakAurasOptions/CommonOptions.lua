-- Nothing here

local L = WeakAuras.L
local regionOptions = WeakAuras.regionOptions
local point_types = WeakAuras.point_types;

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
  local hiddenFunc = input.__hidden
  local nooptions = input.__nooptions
  local marginTop = input.__topLine

  local titleWidth = WeakAuras.doubleWidth - (hasAdd and 0.15 or 0) - (hasDelete and 0.15 or 0)  - (hasUp and 0.15 or 0)
                     - (hasDown and 0.15 or 0) - (hasDuplicate and 0.15 or 0) - (hasApplyTemplate and 0.15 or 0)

  options[key .. "collapseSpacer"] = {
    type = marginTop and "header" or "description",
    name = "",
    order = order,
    width = "full",
    hidden = hiddenFunc,
  }
  options[key .. "collapseButton"] = {
    type = "execute",
    name = title,
    order = order + 0.1,
    width = titleWidth,
    func = function(info, button, secondCall)
      if not nooptions and not secondCall then
        local isCollapsed = WeakAuras.IsCollapsed("collapse", "region", key, false)
        WeakAuras.SetCollapsed("collapse", "region", key, not isCollapsed)
      end
    end,
    image = function()
      if nooptions then
        return "Interface\\AddOns\\WeakAuras\\Media\\Textures\\bullet1", 18, 18
      else
        local isCollapsed = WeakAuras.IsCollapsed("collapse", "region", key, false)
        return isCollapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse", 18, 18
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

  if hiddenFunc then
    return function()
      return hiddenFunc() or WeakAuras.IsCollapsed("collapse", "region", key, false)
    end
  else
    return function()
      return WeakAuras.IsCollapsed("collapse", "region", key, false)
    end
  end
end

local function copyOptionTable(input, orderAdjustment, collapsedFunc)
  local resultOption = {};
  WeakAuras.DeepCopy(input, resultOption);
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
    if(#data.controlledChildren == 0) then
      return true;
    end

    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local childOptions = WeakAuras.EnsureOptions(childData, subOption)
        local childOption = childOptions;
        local childOptionTable = {[0] = childOption};
        for i=1,#info do
          childOption = childOption.args[info[i]];
          childOptionTable[i] = childOption;
        end
        if (childOption) then
          if (not hiddenChild(childOptionTable, info)) then
            return false;
          end
        end
      end
    end

    return true;
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
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local childOptions = WeakAuras.EnsureOptions(childData, subOption);
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
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local values = getValueFor(WeakAuras.EnsureOptions(childData, subOption), info, "values");
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
    end
    return combinedKeys;
  end

  local function regionPrefix(input)
    local index = string.find(input, ".", 1, true);
    if (index) then
      local regionType = string.sub(input, 1, index - 1);
      return regionOptions[regionType] and regionType;
    end
    return nil;
  end

  local function sameAll(info)
    local combinedValues = {};
    local first = true;
    local combinedKeys = combineKeys(info);

    local isToggle = nil

    for index, childId in ipairs(data.controlledChildren) do
      if isToggle == nil then
        local childData = WeakAuras.GetData(childId)
        local childOption = getChildOption(WeakAuras.EnsureOptions(childData, subOption), info)
        isToggle = childOption and childOption.type == "toggle"
      end

      local childData = WeakAuras.GetData(childId);

      local regionType = regionPrefix(info[#info]);
      if(childData and (not regionType or childData.regionType == regionType or regionType == "sub")) then
        local childOptions = WeakAuras.EnsureOptions(childData, subOption)
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
                return nil;
              end
            end
          end
        else
          local values = {};
          if (get) then
            values = { get(info) };
            local childOption = getChildOption(childOptions, info)
            if isToggle and values[1] == nil then
              values[1] = false
            end
          end
          if(first) then
            combinedValues = values;
            first = false;
          else
            if (not compareTables(combinedValues, values)) then
              return nil;
            end
          end
        end
      end
    end

    return true;
  end

  local function nameAll(info)
    local combinedName;
    local first = true;
    local foundNames = {};
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local childOption = getChildOption(WeakAuras.EnsureOptions(childData, subOption), info);
        if (childOption) then
          local name;
          if(type(childOption.name) == "function") then
            name = childOption.name(info);
          else
            name = childOption.name;
          end
          if (not name) then
          -- Do nothing
          elseif(first) then
            if (combinedName ~= "") then
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
    end

    return combinedName;
  end

  local function descAll(info)
    local combinedDesc;
    local first = true;
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local childOption = getChildOption(WeakAuras.EnsureOptions(childData, subOption), info);
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
              return "|cFF4080FF"..(name or "error");
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
            for index, childId in ipairs(data.controlledChildren) do
              local childData = WeakAuras.GetData(childId);
              if(childData) then
                local childOptions = WeakAuras.EnsureOptions(childData, subOption)
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
                          tinsert(values, "|cFFE0E000"..childId..": |r"..name);
                        elseif(tri) then
                          tinsert(values, "|cFFE0E000"..childId..": |r"..L["Ignored"]);
                        elseif(childOptionTable[i].get(info)) then
                          tinsert(values, "|cFFE0E000"..childId..": |r|cFF00FF00"..L["Enabled"]);
                        else
                          tinsert(values, "|cFFE0E000"..childId..": |r|cFFFF0000"..L["Disabled"]);
                        end
                      elseif(intable.type == "color") then
                        local r, g, b = childOptionTable[i].get(info);
                        r, g, b = r or 1, g or 1, b or 1;
                        tinsert(values, ("|cFF%2x%2x%2x%s"):format(r * 220 + 35, g * 220 + 35, b * 220 + 35, childId));
                      elseif(intable.type == "select") then
                        local selectValues = type(intable.values) == "table" and intable.values or intable.values(info);
                        local key = childOptionTable[i].get(info);
                        local display = key and selectValues[key] or L["None"];
                        if intable.dialogControl == "LSM30_Font" then
                          tinsert(values, "|cFFE0E000"..childId..": |r" .. key);
                        else
                          tinsert(values, "|cFFE0E000"..childId..": |r"..display);
                        end
                      elseif(intable.type == "multiselect") then
                        local selectedValues = {};
                        for k, v in pairs(combinedKeys) do
                          if (childOptionTable[i].get(info, k)) then
                            tinsert(selectedValues, tostring(v))
                          end
                        end
                        tinsert(values, "|cFFE0E000"..childId..": |r"..table.concat(selectedValues, ","));
                      else
                        local display = childOptionTable[i].get(info) or L["None"];
                        if(type(display) == "number") then
                          display = math.floor(display * 100) / 100;
                        else
                          if #display > 50 then
                            display = display:sub(1, 50) .. "..."
                          end
                        end
                        tinsert(values, "|cFFE0E000"..childId..": |r"..display);
                      end
                      break;
                    end
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
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local childOption = WeakAuras.EnsureOptions(childData, subOption)
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

local function replaceValuesFuncs(intable, data, subOption)
  local function valuesAll(info)
    local combinedValues = {};
    local handledValues = {};
    local first = true;
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local childOption = WeakAuras.EnsureOptions(childData, subOption)
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
                  combinedValues[k] = combinedValues[k] .. "/" .. v;
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
  HasValue = function(self)
    return not self.first
  end
}

local function CreateGetAll(subOption)
  return function(data, info, ...)
    local isToggle = nil

    local allChildren = CopyTable(getHelper)
    local enabledChildren = CopyTable(getHelper)

    for index, childId in ipairs(data.controlledChildren) do
      if isToggle == nil then
        local childData = WeakAuras.GetData(childId)
        local childOptions = getChildOption(WeakAuras.EnsureOptions(childData, subOption), info)
        isToggle = childOptions and childOptions.type == "toggle"
      end

      local childData = WeakAuras.GetData(childId);

      if(childData) then
        local childOptions = WeakAuras.EnsureOptions(childData, subOption)
        local childOption = childOptions;
        local childOptionTable = {[0] = childOption};
        for i=1,#info do
          childOption = childOption.args[info[i]];
          childOptionTable[i] = childOption;
        end

        if (childOption and not disabledOrHiddenChild(childOptionTable, info)) then
          for i=#childOptionTable,0,-1 do
            if(childOptionTable[i].get) then
              local values = {childOptionTable[i].get(info, ...)};
              if isToggle and values[1] == nil then
                values[1] = false
              end

              local sameAllChildren = allChildren:Set(values)
              local sameEnabledChildren = enabledChildren:Set(values)

              if not sameAllChildren and not sameEnabledChildren then
                return nil;
              end
              break;
            end
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
    WeakAuras.pauseOptionsProcessing(true);
    WeakAuras.PauseAllDynamicGroups()
    local before = getAll(data, info, ...)
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local childOptions = WeakAuras.EnsureOptions(childData, subOption)
        local childOption = childOptions;
        local childOptionTable = {[0] = childOption};
        for i=1,#info do
          childOption = childOption.args[info[i]];
          childOptionTable[i] = childOption;
        end

        if (childOption and not disabledOrHiddenChild(childOptionTable, info)) then
          for i=#childOptionTable,0,-1 do
            if(childOptionTable[i].set) then
              if (childOptionTable[i].type == "multiselect") then
                childOptionTable[i].set(info, ..., not before);
              else
                childOptionTable[i].set(info, ...);
              end
              break;
            end
          end
        end
      end
    end

    WeakAuras.ResumeAllDynamicGroups()
    WeakAuras.pauseOptionsProcessing(false);
    WeakAuras.ScanForLoads();
    WeakAuras.SortDisplayButtons();
    WeakAuras.UpdateOptions()
  end
end

local function CreateExecuteAll(subOption)
  return function(data, info, button)
    local secondCall = nil
    for index, childId in ipairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      if(childData) then
        local childOptions = WeakAuras.EnsureOptions(childData, subOption)
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
    end
    WeakAuras.ClearAndUpdateOptions(data.id)
  end
end

local function PositionOptions(id, data, _, hideWidthHeight, disableSelfPoint)
  local metaOrder = 99
  local function IsParentDynamicGroup()
    if data.parent then
      local parentData = WeakAuras.GetData(data.parent)
      return parentData and parentData.regionType == "dynamicgroup"
    end
  end

  local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;
  local positionOptions = {
    __title = L["Position Settings"],
    __order = metaOrder,
    width = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Width"],
      order = 60,
      min = 1,
      softMax = screenWidth,
      bigStep = 1,
      hidden = hideWidthHeight,
    },
    height = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Height"],
      order = 61,
      min = 1,
      softMax = screenHeight,
      bigStep = 1,
      hidden = hideWidthHeight,
    },
    xOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["X Offset"],
      order = 62,
      softMin = (-1 * screenWidth),
      softMax = screenWidth,
      bigStep = 10,
      get = function() return data.xOffset end,
      set = function(info, v)
        data.xOffset = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.ResetMoverSizer();
        if(data.parent) then
          local parentData = WeakAuras.GetData(data.parent);
          if(parentData) then
            WeakAuras.Add(parentData);
          end
        end
      end
    },
    yOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Y Offset"],
      order = 63,
      softMin = (-1 * screenHeight),
      softMax = screenHeight,
      bigStep = 10,
      get = function() return data.yOffset end,
      set = function(info, v)
        data.yOffset = v;
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.ResetMoverSizer();
        if(data.parent) then
          local parentData = WeakAuras.GetData(data.parent);
          if(parentData) then
            WeakAuras.Add(parentData);
          end
        end
      end
    },
    selfPoint = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Anchor"],
      order = 70,
      hidden = IsParentDynamicGroup,
      values = point_types,
      disabled = disableSelfPoint,
    },
    anchorFrameType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Anchored To"],
      order = 72,
      hidden = IsParentDynamicGroup,
      values = (data.regionType == "group" or data.regionType == "dynamicgroup") and WeakAuras.anchor_frame_types_group or WeakAuras.anchor_frame_types,
    },
    -- Input field to select frame to anchor on
    anchorFrameFrame = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Frame"],
      order = 72.2,
      hidden = function()
        if (IsParentDynamicGroup()) then
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
      order = 72.4,
      hidden = function()
        if (IsParentDynamicGroup()) then
          return true;
        end
        return not (data.anchorFrameType == "SELECTFRAME")
      end,
      func = function()
        WeakAuras.StartFrameChooser(data, {"anchorFrameFrame"});
      end
    },
    anchorPoint = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = function()
        if (data.anchorFrameType == "SCREEN") then
          return L["To Screen's"]
        elseif (data.anchorFrameType == "PRD") then
          return L["To Personal Ressource Display's"];
        else
          return L["To Frame's"];
        end
      end,
      order = 75,
      hidden = function()
        if (data.parent) then
          --if (IsParentDynamicGroup()) then
          --  return true;
          --end
          return data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE";
        else
          return data.anchorFrameType == "MOUSE";
        end
      end,
      values = point_types
    },
    anchorPointGroup = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["To Group's"],
      order = 76,
      hidden = function()
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
      get = function() return "CENTER"; end
    },
    anchorFrameParent = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Set Parent to Anchor"],
      desc = L["Sets the anchored frame as the aura's parent, causing the aura to inherit attributes such as visibility and scale."],
      order = 77,
      get = function()
        return data.anchorFrameParent or data.anchorFrameParent == nil;
      end,
      hidden = function()
        return (data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE" or IsParentDynamicGroup());
      end,
    },
    frameStrata = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Frame Strata"],
      order = 78,
      values = WeakAuras.frame_strata_types
    },
    anchorFrameSpace = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = "",
      order = 79,
      image = function() return "", 0, 0 end,
      hidden = function()
        return not (data.anchorFrameType ~= "SCREEN" or IsParentDynamicGroup());
      end
    },
  };
  WeakAuras.commonOptions.AddCodeOption(positionOptions, data, L["Custom Anchor"], "custom_anchor", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-anchor-function",
                          72.1, function() return not(data.anchorFrameType == "CUSTOM" and not IsParentDynamicGroup()) end, {"customAnchor"}, nil, nil, nil, nil, nil, true)
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
      width = WeakAuras.normalWidth,
      name = L["Border Size"],
      order = order + 0.4,
      softMin = 1,
      softMax = 64,
      bigStep = 1,
      hidden = function() return hiddenFunc and hiddenFunc() or not data.border end,
    },
    borderInset = {
      type = "range",
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

local function GetCustomCode(data, path)
  for _, key in ipairs(path) do
    if (not data or not data[key]) then
      return nil;
    end
    data = data[key];
  end
  return data;
end

-- TODO: find a paradigm which doesn't have five million flags for AddCodeOption so that calls to it don't always go off the screen
-- a table of settings is the obvious option to pack the flags.
-- alternatively, we could create a "code" type option which then gets processed before sending to AceConfig
local function AddCodeOption(args, data, name, prefix, url, order, hiddenFunc, path, encloseInFunction, multipath, extraSetFunction, extraFunctions, reloadOptions, setOnParent)
  extraFunctions = extraFunctions or {};
  tinsert(extraFunctions, 1, {
    buttonLabel = L["Expand"],
    func = function(info)
      WeakAuras.OpenTextEditor(WeakAuras.GetPickedDisplay(), path, encloseInFunction, multipath, reloadOptions, setOnParent, url)
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
      extraFunctions = extraFunctions,
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
      if (extraSetFunction) then
        extraSetFunction();
      end
      if (reloadOptions) then
        WeakAuras.ClearOptions(data.id)
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

      if (not code) then
        return ""
      end

      if (encloseInFunction) then
        code = "function() "..code.."\n end";
      end

      code = "return " .. code;

      local _, errorString = loadstring(code);
      return errorString and "|cFFFF0000"..errorString or "";
    end,
    width = WeakAuras.doubleWidth,
    order = order + 0.002,
    hidden = function()
      if (hiddenFunc()) then
        return true;
      end

      local code = GetCustomCode(data, path);
      if (not code) then
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
        return true;
      end
    end
  };
end

local function AddCommonTriggerOptions(options, data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  local trigger_types = {};
  for type, triggerSystem in pairs(WeakAuras.triggerTypes) do
    trigger_types[type] = triggerSystem.GetName(type);
  end

  options.typedesc = {
    type = "description",
    width = WeakAuras.normalWidth,
    name = L["Type"],
    order = 1,
    disabled = true,
    get = function() return true end
  }
  options.type = {
    type = "select",
    width = WeakAuras.normalWidth,
    name = L["Type"],
    desc = L["The type of trigger"],
    order = 1.1,
    values = trigger_types,
    get = function(info)
      return trigger.type
    end,
    set = function(info, v)
      trigger.type = v;
      local prototype = trigger.event and WeakAuras.event_prototypes[trigger.event];
      if v == "status" and (not prototype or prototype.type == "event") then
        trigger.event = "Cooldown Progress (Spell)"
      elseif v == "event" and (not prototype or prototype.type == "status") then
        trigger.event = "Combat Log"
      end
      WeakAuras.Add(data);
      WeakAuras.UpdateThumbnail(data);
      WeakAuras.UpdateDisplayButton(data);
      WeakAuras.ClearAndUpdateOptions(data.id);
    end
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


WeakAuras.commonOptions = {}
WeakAuras.commonOptions.parsePrefix = parsePrefix
WeakAuras.commonOptions.flattenRegionOptions = flattenRegionOptions
WeakAuras.commonOptions.fixMetaOrders = fixMetaOrders
WeakAuras.commonOptions.removeFuncs = removeFuncs
WeakAuras.commonOptions.CreateHiddenAll = CreateHiddenAll
WeakAuras.commonOptions.CreateDisabledAll = CreateDisabledAll
WeakAuras.commonOptions.replaceNameDescFuncs = replaceNameDescFuncs
WeakAuras.commonOptions.replaceImageFuncs = replaceImageFuncs
WeakAuras.commonOptions.replaceValuesFuncs = replaceValuesFuncs
WeakAuras.commonOptions.CreateGetAll = CreateGetAll
WeakAuras.commonOptions.CreateSetAll = CreateSetAll
WeakAuras.commonOptions.CreateExecuteAll = CreateExecuteAll

WeakAuras.commonOptions.PositionOptions = PositionOptions
WeakAuras.commonOptions.BorderOptions = BorderOptions
WeakAuras.commonOptions.AddCodeOption = AddCodeOption

WeakAuras.commonOptions.AddCommonTriggerOptions = AddCommonTriggerOptions
WeakAuras.commonOptions.AddTriggerGetterSetter = AddTriggerGetterSetter
