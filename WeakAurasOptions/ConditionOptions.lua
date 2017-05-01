
-- A bit of terminology
-- Templates:
--   The potential conditions that are offered by the triggers
-- The data structure returned by GetTriggerConditions(data) is
-- [] Trigger number
--   [] Condition name
--      - display: Display Name
--      - type: Type, e.g. "select", "number", "timer"
--      - values: (only for "select")
--      - test: a test function template

-- Conditions + Changes: Actually active settings on a aura
-- Datastructure:
-- [] Index
--    - check
--      - trigger: Trigger number
--      - variable: Variable inside the trigger state to check
--      - op: Operator to use for check
--      - value: Value to check
--      - (for merged) references
--          - id => conditionIndex
--               => op
--               => value
--      - (for merged) referenceCount
--      - (for merged) samevalue
--      - (for merged) sameop
--    - changes
--      [] Index
--         - property: Property that is changed
--         - value: New value
--         - (for merged) references
--              => id => changeIndex
--                    => value
--         - (for merged) referenceCount
--         - (for merged) samevalue
--  Properties: The parts of the region than can be changed via
--             the condition system
-- [] Property Name
--   - display: A display Name
--   - setter: The setter Function
--   - type: The type


local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local debug = false;

local function addSpace(args, order)
  args["space" .. order] = {
    type = "description",
    name = "",
    image = function() return "", 0, 0 end,
    order = order,
  }
  order = order + 1;
  return order;
end

local function addHalfSpace(args, order)
  args["space" .. order] = {
    type = "description",
    name = "",
    image = function() return "", 0, 0 end,
    order = order,
    width = "half"
  }
  order = order + 1;
  return order;
end

local function compareValues(a, b, propertytype)
  if (propertytype == "color") then
    if (type(a) ~= "table" or type(b) ~= "table") then
      return a == b;
    end
    return a[1] == b[1]
      and a[2] == b[2]
      and a[3] == b[3]
      and a[4] == b[4];
  end
  return a == b;
end

local function valueToString(a, propertytype)
  if (propertytype == "color") then
    if (type(a) == "table") then
      local r, g, b, a = floor((a[1] or 0) * 255), floor((a[2] or 0) * 255), floor((a[3] or 0) * 255), floor((a[4] or 0) * 255)
      return string.format("|c%02X%02X%02X%02X", a, r, g, b) .. L["color"];
    else
      return "";
    end
  elseif (propertytype == "bool") then
    return (a == 1 or a == true) and L["True"] or L["False"];
  end
  return tostring(a);
end

local function isSubset(data, reference)
  if (data.controlledChildren) then
    local auraCount = #data.controlledChildren;
    if (auraCount > reference.referenceCount) then
      return true;
    end
  end
  return false;
end

local function blueIfSubset(data, reference)
  if (isSubset(data, reference)) then
    return "|cFF4080FF";
  end
  return "";
end

local function blueIfNoValue(data, object, variable, string)
  if (data.controlledChildren) then
    if (object["same" .. variable] == false) then
      return "|cFF4080FF" .. string;
    end
  end
  return "";
end

local function descIfSubset(data, reference)
  if (isSubset(data, reference)) then
    local desc = L["Used in auras:"];
    for id in pairs(reference.references) do
      desc = desc .. "\n" .. id;
    end
    return desc;
  end
  return "";
end

local function descIfNoValue(data, object, variable, type, values)
  if (data.controlledChildren) then
    local auraCount = #data.controlledChildren;
    if (object["same" .. variable] == false) then
      local desc = "";
      for id, reference in pairs(object.references) do
        if (type == "list" and values) then
          desc = desc .."|cFFE0E000".. id .. ": |r" .. (values[reference[variable]] or "") .. "\n";
        else
          desc = desc .."|cFFE0E000".. id .. ": |r" .. (valueToString(reference[variable], type) or "") .. "\n";
        end
      end
      return desc;
    end
  end
  return nil;
end

local function filterUsedProperties(indexToProperty, allDisplays, usedProperties, ownProperty)
  local filtered = {};
  for index, value in pairs(allDisplays) do
    local property = indexToProperty[index];
    local isUsed = property and usedProperties[property];
    local isOwn = ownProperty and property == ownProperty;
    if ( not isUsed or isOwn) then
      filtered[index] = value;
    end
  end

  return filtered;
end

local function addControlsForChange(args, order, data, conditions, i, j, allProperties, usedProperties)
  local thenText = (j == 1) and L["Then "] or L["And "];
  local display = isSubset(data, conditions[i].changes[j]) and allProperties.displayWithCopy or allProperties.display;
  local valuesForProperty = filterUsedProperties(allProperties.indexToProperty, display, usedProperties, conditions[i].changes[j].property);
  args["condition" .. i .. "property" .. j] = {
    type = "select",
    name = blueIfSubset(data, conditions[i].changes[j]) .. thenText,
    desc = descIfSubset(data, conditions[i].changes[j]),
    order = order,
    values = valuesForProperty,
    get = function()
      local property = conditions[i].changes[j].property;
      return property and allProperties.propertyToIndex[property];
    end,
    set = function(info, index)
      local property = allProperties.indexToProperty[index];
      if (property == "COPY") then
        for _, id in ipairs(data.controlledChildren) do
          if (conditions[i].changes[j].references[id]) then
          -- Already exist
          else
            local insertPoint = 1;
            for index = j, 1, -1 do
              if (conditions[i].changes[index].references[id]) then
                insertPoint = index + 1;
                break;
              end
            end

            local change = {};
            change.property = conditions[i].changes[j].property;
            if (type(conditions[i].changes[j].value) == "table") then
              change.value = {};
              WeakAuras.DeepCopy(conditions[i].changes[j].value, change.value)
            else
              change.value = conditions[i].changes[j].value;
            end

            local conditionIndex = conditions[i].check.references[id].conditionIndex;
            local auraData = WeakAuras.GetData(id);
            tinsert(auraData.conditions[conditionIndex].changes, insertPoint, change);
            WeakAuras.Add(auraData);
          end
        end
        WeakAuras.ReloadTriggerOptions(data);
        return;
      elseif (property == "DELETE") then
        if (data.controlledChildren) then
          for id, reference in pairs(conditions[i].changes[j].references) do
            local auraData = WeakAuras.GetData(id);
            local conditionIndex = conditions[i].check.references[id].conditionIndex;
            tremove(auraData.conditions[conditionIndex].changes, reference.changeIndex);
            WeakAuras.Add(auraData);
          end
          WeakAuras.ReloadTriggerOptions(data);
        else
          tremove(conditions[i].changes, j);
          WeakAuras.Add(data);
          WeakAuras.ReloadTriggerOptions(data);
        end
        return;
      end

      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].changes[j].references) do
          local auraData = WeakAuras.GetData(id);
          local conditionIndex = conditions[i].check.references[id].conditionIndex;
          auraData.conditions[conditionIndex].changes[reference.changeIndex].property = property;
          auraData.conditions[conditionIndex].changes[reference.changeIndex].value = nil;
          WeakAuras.Add(auraData);
        end
        conditions[i].changes[j].property = property;
        WeakAuras.ReloadTriggerOptions(data);
      else
        local oldType;
        if (conditions[i].changes[j].property) then
          oldType = allProperties.propertyMap[conditions[i].changes[j].property] and allProperties.propertyMap[conditions[i].changes[j].property].type;
        end
        conditions[i].changes[j].property = property;
        if (oldType ~= allProperties.propertyMap[property].type) then
          conditions[i].changes[j].value = nil;
        end
        WeakAuras.Add(data);
        WeakAuras.ReloadTriggerOptions(data);
      end
    end
  }
  order = order + 1;

  local setValue;
  local setValueColor;
  if (data.controlledChildren) then
    setValue = function(info, v)
      for id, reference in pairs(conditions[i].changes[j].references) do
        local auraData = WeakAuras.GetData(id);
        local conditionIndex = conditions[i].check.references[id].conditionIndex;
        auraData.conditions[conditionIndex].changes[reference.changeIndex].value = v;
        WeakAuras.Add(auraData);
      end
      conditions[i].changes[j].value = v;
      WeakAuras.ReloadTriggerOptions(data);
    end
    setValueColor = function(info, r, g, b, a)
      for id, reference in pairs(conditions[i].changes[j].references) do
        local auraData = WeakAuras.GetData(id);
        local conditionIndex = conditions[i].check.references[id].conditionIndex;
        auraData.conditions[conditionIndex].changes[reference.changeIndex].value = auraData.conditions[conditionIndex].changes[reference.changeIndex].value or {};
        auraData.conditions[conditionIndex].changes[reference.changeIndex].value[1] = r;
        auraData.conditions[conditionIndex].changes[reference.changeIndex].value[2] = g;
        auraData.conditions[conditionIndex].changes[reference.changeIndex].value[3] = b;
        auraData.conditions[conditionIndex].changes[reference.changeIndex].value[4] = a;
        WeakAuras.Add(auraData);
      end
      conditions[i].changes[j].value = conditions[i].changes[j].value or {};
      conditions[i].changes[j].value[1] = r;
      conditions[i].changes[j].value[2] = g;
      conditions[i].changes[j].value[3] = b;
      conditions[i].changes[j].value[4] = a;
      WeakAuras.ReloadTriggerOptions(data);
    end
  else
    setValue = function(info, v)
      conditions[i].changes[j].value = v;
      WeakAuras.Add(data);
    end
    setValueColor = function(info, r, g, b, a)
      conditions[i].changes[j].value = conditions[i].changes[j].value or {};
      conditions[i].changes[j].value[1] = r;
      conditions[i].changes[j].value[2] = g;
      conditions[i].changes[j].value[3] = b;
      conditions[i].changes[j].value[4] = a;
      WeakAuras.Add(data);
    end
  end

  local propertyType;
  local property = conditions[i].changes[j].property;
  if (property) then
    propertyType = allProperties.propertyMap[property] and allProperties.propertyMap[property].type;
  end
  if (propertyType == "bool" or propertyType == "number") then
    args["condition" .. i .. "value" .. j] = {
      type = "toggle",
      name = blueIfNoValue(data, conditions[i].changes[j], "value", L["Differences"]),
      desc = descIfNoValue(data, conditions[i].changes[j], "value", propertyType),
      order = order,
      get = function()
        return conditions[i].changes[j].value;
      end,
      set = setValue
    }
    order = order + 1;
    if (propertyType == "number") then
      local properties = allProperties.propertyMap[property];
      if (properties.min or properties.softMin) and (properties.max or properties.softMax) then
        args["condition" .. i .. "value" .. j].type = "range";
        args["condition" .. i .. "value" .. j].min = properties.min;
        args["condition" .. i .. "value" .. j].softMin = properties.softMin;
        args["condition" .. i .. "value" .. j].max = properties.max;
        args["condition" .. i .. "value" .. j].softMax = properties.softMax;
        args["condition" .. i .. "value" .. j].step = properties.step;
        args["condition" .. i .. "value" .. j].bigStep = properties.bigStep;
      else
        args["condition" .. i .. "value" .. j].type = "input";
        args["condition" .. i .. "value" .. j].validate = WeakAuras.ValidateNumeric;
      end
    end
  elseif (propertyType == "color") then
    args["condition" .. i .. "value" .. j] = {
      type = "color",
      name = blueIfNoValue(data, conditions[i].changes[j], "value", L["Differences"]),
      desc = descIfNoValue(data, conditions[i].changes[j], "value", propertyType),
      order = order,
      hasAlpha = true,
      get = function()
        if (conditions[i].changes[j].value and type(conditions[i].changes[j].value) == "table") then
          return conditions[i].changes[j].value[1], conditions[i].changes[j].value[2], conditions[i].changes[j].value[3], conditions[i].changes[j].value[4];
        end
        return nil;
      end,
      set = setValueColor
    }
    order = order + 1;
  elseif (propertyType == "list") then
    local values = property and allProperties.propertyMap[property] and allProperties.propertyMap[property].values;
    args["condition" .. i .. "value" .. j] = {
      type = "select",
      values = values,
      name = blueIfNoValue(data, conditions[i].changes[j], "value", L["Differences"]),
      desc = descIfNoValue(data, conditions[i].changes[j], "value", propertyType, values),
      order = order,
      get = function()
        return conditions[i].changes[j].value;
      end,
      set = setValue
    }
    order = order + 1;
  else
    order = addSpace(args, order);
  end
  return order;
end

local function addControlsForCondition(args, order, data, conditions, i, conditionTemplates, allProperties)
  if (not conditions[i].check) then
    return;
  end
  args["condition" .. i .. "header"] = {
    type = "header",
    name = "",
    order = order
  };
  order = order + 1;

  local optionsName = blueIfSubset (data, conditions[i].check);
  if (conditions[i].check.trigger) then
    optionsName = optionsName .. string.format(L["If Trigger %s"], conditions[i].check.trigger + 1);
  else
    optionsName = optionsName .. L["If"];
  end

  args["condition" .. i .. "if"] = {
    type = "select",
    name = optionsName,
    desc = descIfSubset(data, conditions[i].check),
    order = order,
    values = isSubset(data, conditions[i].check) and conditionTemplates.displayWithCopy or conditionTemplates.display,
    set = function(info, v)
      if (conditionTemplates.indexToTrigger[v] == "COPY") then
        for _, id in ipairs(data.controlledChildren) do
          if (conditions[i].check.references[id]) then
          -- Already exists
          else
            -- find a good insertion point, if any other condition has a reference to this
            -- insert directly after that
            local insertPoint = 1;
            for index = i, 1, -1 do
              if (conditions[index].check.references[id]) then
                insertPoint = index + 1;
                break;
              end
            end

            local condition = {};
            condition.check = {};
            condition.check.trigger = conditions[i].check.trigger;
            condition.check.variable = conditions[i].check.variable;
            condition.check.op = conditions[i].check.op;
            condition.check.value = conditions[i].check.value;

            condition.changes = {};
            for changeIndex, change in ipairs(conditions[i].changes) do
              if (change.samevalue) then
                local copy = {};
                copy.property = change.property;
                if (type(change.value) == "table") then
                  copy.value = {};
                  WeakAuras.DeepCopy(change.value, copy.value);
                else
                  copy.value = change.value;
                end
                tinsert(condition.changes, copy);
              end
            end

            local auraData = WeakAuras.GetData(id);
            tinsert(auraData.conditions, insertPoint, condition);
            WeakAuras.Add(auraData);

          end
        end
        WeakAuras.ReloadTriggerOptions(data);
        return;
      elseif (conditionTemplates.indexToTrigger[v] == "DELETE") then
        if (data.controlledChildren) then
          for id, reference in pairs(conditions[i].check.references) do
            local auraData = WeakAuras.GetData(id);
            tremove(auraData.conditions, reference.conditionIndex);
            WeakAuras.Add(auraData);
          end
          WeakAuras.ReloadTriggerOptions(data);
          return;
        else
          tremove(conditions, i);
          WeakAuras.Add(data);
          WeakAuras.ReloadTriggerOptions(data);
          return;
        end
      end

      local trigger = conditionTemplates.indexToTrigger[v];
      local variable = conditionTemplates.indexToVariable[v];
      if (not trigger or not variable) then
        return;
      end

      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          auraData.conditions[reference.conditionIndex].check.variable = variable;
          auraData.conditions[reference.conditionIndex].check.trigger = trigger;
          auraData.conditions[reference.conditionIndex].check.value = nil;
          WeakAuras.Add(auraData);
        end
        WeakAuras.ReloadTriggerOptions(data);
      else
        local oldType;
        if (conditions[i].check.trigger and conditions[i].check.variable) then
          local templatesForTrigger = conditionTemplates.all[conditions[i].check.trigger];
          local templatesForTriggerAndCondition = templatesForTrigger and templatesForTrigger[conditions[i].check.variable];
          oldType = templatesForTriggerAndCondition and templatesForTriggerAndCondition.type;
        end
        conditions[i].check.variable = variable;
        conditions[i].check.trigger = trigger;
        local newType = conditionTemplates.all[trigger][variable].type;
        if (newType ~= oldType) then
          conditions[i].check.value = nil;
        end
        WeakAuras.Add(data);
        WeakAuras.ReloadTriggerOptions(data);
      end
    end,
    get = function()
      local trigger = conditions[i].check.trigger;
      local variable = conditions[i].check.variable;
      if ( trigger and variable ) then
        return conditionTemplates.conditionToIndex[trigger .. "-" .. variable];
      end
      return "";
    end
  };

  order = order + 1;

  local currentConditionTemplate = nil;
  local check = conditions[i] and conditions[i].check;
  local trigger = check and check.trigger;
  local variable = check and check.variable;
  if (trigger and variable) then
    if (conditionTemplates.all[trigger]) then
      currentConditionTemplate = conditionTemplates.all[trigger][variable];
    end
  end

  local setOp;
  local setValue;
  if (data.controlledChildren) then
    setOp = function(info, v)
      conditions[i].check.op = v;
      for id, reference in pairs(conditions[i].check.references) do
        local auraData = WeakAuras.GetData(id);
        auraData.conditions[reference.conditionIndex].check.op = v;
        WeakAuras.Add(auraData);
      end
      conditions[i].check.op = v;
      WeakAuras.ReloadTriggerOptions(data);
    end
    setValue = function(info, v)
      conditions[i].check.op = v;
      for id, reference in pairs(conditions[i].check.references) do
        local auraData = WeakAuras.GetData(id);
        auraData.conditions[reference.conditionIndex].check.value = v;
        WeakAuras.Add(auraData);
      end
      conditions[i].check.value = v;
      WeakAuras.ReloadTriggerOptions(data);
    end
  else
    setOp = function(info, v)
      conditions[i].check.op = v;
      WeakAuras.Add(data);
    end
    setValue = function(info, v)
      conditions[i].check.value = v;
      WeakAuras.Add(data);
    end
  end

  if (currentConditionTemplate) then
    if (currentConditionTemplate.type == "number" or currentConditionTemplate.type == "timer") then
      args["condition" .. i .. "_op"] = {
        name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
        type = "select",
        order = order,
        values = WeakAuras.operator_types,
        width = "half",
        get = function()
          return conditions[i].check.op;
        end,
        set = setOp,
      }
      order = order + 1;

      args["condition" .. i .. "_value"] = {
        type = "input",
        name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
        width = "half",
        order = order,
        validate = WeakAuras.ValidateNumeric,
        get = function()
          return conditions[i].check.value;
        end,
        set = setValue
      }
      order = order + 1;
    elseif (currentConditionTemplate.type == "select") then
      args["condition" .. i .. "_op"] = {
        name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
        type = "select",
        order = order,
        values = WeakAuras.equality_operator_types,
        get = function()
          return conditions[i].check.op;
        end,
        set = setOp,
      }
      order = order + 1;

      order = addSpace(args, order);

      args["condition" .. i .. "_value"] = {
        type = "select",
        name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
        order = order,
        values = currentConditionTemplate.values,
        get = function()
          return conditions[i].check.value;
        end,
        set = setValue
      }
      order = order + 1;
    elseif (currentConditionTemplate.type == "bool") then
      args["condition" .. i .. "_value"] = {
        type = "select",
        name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
        order = order,
        values = WeakAuras.bool_types,
        get = function()
          return conditions[i].check.value;
        end,
        set = setValue
      }
      order = order + 1;
    elseif (currentConditionTemplate.type == "string") then
      args["condition" .. i .. "_op"] = {
        name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
        type = "select",
        order = order,
        values = WeakAuras.string_operator_types,
        get = function()
          return conditions[i].check.op;
        end,
        set = setOp
      }
      order = order + 1;

      order = addSpace(args, order);

      args["condition" .. i .. "_value"] = {
        type = "input",
        name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
        order = order,
        get = function()
          return conditions[i].check.value;
        end,
        set = setValue
      }
      order = order + 1;
    else
      order = addSpace(args, order);
    end
  else
    order = addSpace(args, order);
  end

  -- Add Property changes

  local usedProperties = {};
  for j = 1, conditions[i].changes and #conditions[i].changes or 0 do
    local property = conditions[i].changes[j].property;
    if (property) then
      usedProperties[property] = true;
    end
  end

  for j = 1, conditions[i].changes and #conditions[i].changes or 0 do
    order = addControlsForChange(args, order, data, conditions, i, j, allProperties, usedProperties);
  end

  args["condition" .. i .. "_addChange"] = {
    type = "execute",
    name = L["Add Property Change"],
    order = order,
    func = function()
      if (data.controlledChildren) then
        for _, id in ipairs(data.controlledChildren) do
          local auradata = WeakAuras.GetData(id);
          auradata.conditions[i].changes = auradata.conditions[i].changes or {};
          auradata.conditions[i].changes[#auradata.conditions[i].changes + 1] = {};
          WeakAuras.Add(auradata);
        end
        WeakAuras.ReloadTriggerOptions(data);
      else
        conditions[i].changes = conditions[i].changes or {};
        conditions[i].changes[#conditions[i].changes + 1] = {};
        WeakAuras.Add(data);
        WeakAuras.ReloadTriggerOptions(data);
      end
    end
  }
  order = order + 1;
  order = addSpace(args, order);

  return order;
end

local function mergeConditionTemplates(allConditionTemplates, auraConditionsTemplate, numTriggers)
  for triggernum = 0, numTriggers -1 do
    local auraTemplatesForTrigger = auraConditionsTemplate[triggernum];
    if (auraTemplatesForTrigger) then
      allConditionTemplates[triggernum] = allConditionTemplates[triggernum] or {};
      for conditionName in pairs(auraTemplatesForTrigger) do
        if not allConditionTemplates[triggernum][conditionName] then
          allConditionTemplates[triggernum][conditionName] = {};
          WeakAuras.DeepCopy(auraTemplatesForTrigger[conditionName], allConditionTemplates[triggernum][conditionName]);
        else
          if (allConditionTemplates[triggernum][conditionName].type ~= auraTemplatesForTrigger[conditionName].type) then
            -- Two different trigger types have a condition of the same name, with incompatible types
            -- Setting the type to incompatible prevents the interface from showing options for it
            -- This can't currently happen
            allConditionTemplates[triggernum][conditionName].type = "incompatible";
          end
        end
      end
    end
  end
end

local function createConditionTemplates(data)
  -- The allConditionTemplates contains a table per trigger.
  -- Each table contains a entry per condition variable
  -- For the DropDown we need a flat and sorted list that maps
  -- from a index to a display name
  -- And two auxillary data structures which map to the index from triggernum/conditionvalue
  -- And from the index to triggernum/conditionvalue

  local allConditionTemplates;
  local numTriggers = 0;
  if (data.controlledChildren) then
    allConditionTemplates = {};
    for _, id in ipairs(data.controlledChildren) do
      local data = WeakAuras.GetData(id);
      numTriggers = max(numTriggers, data.numTriggers);

      local auraConditionsTemplate = WeakAuras.GetTriggerConditions(data);
      mergeConditionTemplates(allConditionTemplates, auraConditionsTemplate, numTriggers)
    end
  else
    allConditionTemplates = WeakAuras.GetTriggerConditions(data);
    numTriggers = data.numTriggers;
  end

  local conditionTemplates = {};
  conditionTemplates.all = allConditionTemplates;
  conditionTemplates.indexToTrigger = {};
  conditionTemplates.indexToVariable = {};
  conditionTemplates.conditionToIndex = {};
  conditionTemplates.display = {};

  local index = 1;
  for triggernum = 0, numTriggers - 1 do
    local templatesForTrigger = allConditionTemplates[triggernum];

    -- Sort Conditions for one trigger
    local sorted = {};
    if (templatesForTrigger) then
      for conditionName in pairs(templatesForTrigger) do
        tinsert(sorted, conditionName);
      end
      table.sort(sorted, function(a, b)
        return templatesForTrigger[a].display < templatesForTrigger[b].display;
      end);

      if (#sorted > 0) then
        conditionTemplates.display[index]  = string.format(L["Trigger %d"], triggernum + 1);
        index = index + 1;
      end

      for _, conditionName in ipairs(sorted) do
        conditionTemplates.display[index] = "    " .. templatesForTrigger[conditionName].display;
        conditionTemplates.indexToTrigger[index] = triggernum;
        conditionTemplates.indexToVariable[index] = conditionName;
        conditionTemplates.conditionToIndex[triggernum .. "-" .. conditionName] = index;
        index = index + 1;
      end
    end
  end

  conditionTemplates.display[9999] = "•" .. L["Remove this condition"] .. "•";
  conditionTemplates.indexToTrigger[9999] = "DELETE";
  conditionTemplates.indexToVariable[9999] = "DELETE";

  if (data.controlledChildren) then
    conditionTemplates.displayWithCopy = {};
    WeakAuras.DeepCopy(conditionTemplates.display, conditionTemplates.displayWithCopy);

    conditionTemplates.displayWithCopy[9998] = "•" .. L["Copy to all auras"] .. "•";
    conditionTemplates.indexToTrigger[9998] = "COPY";
    conditionTemplates.indexToVariable[9998] = "COPY";
  end

  return conditionTemplates;
end

local function buildAllPotentialProperies(data)
  local allProperties = {};
  allProperties.propertyMap = {};
  if (data.controlledChildren) then
    for _, id in ipairs(data.controlledChildren) do
      local auradata = WeakAuras.GetData(id);
      local regionProperties = WeakAuras.regionTypes[auradata.regionType] and WeakAuras.regionTypes[auradata.regionType].properties
      if (regionProperties) then
        for k, v in pairs(regionProperties) do
          if (allProperties.propertyMap[k]) then
            if (allProperties.propertyMap[k].type ~= v.type) then
              allProperties.propertyMap[k].type = "incompatible";
            end

            if (allProperties.propertyMap[k].type == "list") then
              -- Merge value lists
              for key, value in pairs(v.values) do
                if (allProperties.propertyMap[k].values[key] == nil) then
                  allProperties.propertyMap[k].values[key] = value;
                end
              end
            end
          else
            allProperties.propertyMap[k] = {};
            WeakAuras.DeepCopy(v, allProperties.propertyMap[k])
          end
        end
      end
    end
  else
    local regionProperties = WeakAuras.regionTypes[data.regionType] and WeakAuras.regionTypes[data.regionType].properties
    if (regionProperties) then
      for k, v in pairs(regionProperties) do
        allProperties.propertyMap[k] = v;
      end
    end
  end

  allProperties.indexToProperty = {};
  for k in pairs(allProperties.propertyMap) do
    tinsert(allProperties.indexToProperty, k);
  end
  table.sort(allProperties.indexToProperty, function(a, b)
    return allProperties.propertyMap[a].display <  allProperties.propertyMap[b].display
  end);

  allProperties.propertyToIndex = {};
  for index, property in ipairs(allProperties.indexToProperty) do
    allProperties.propertyToIndex[property] = index;
  end

  allProperties.display = {};
  for index, property in ipairs(allProperties.indexToProperty) do
    allProperties.display[index] = allProperties.propertyMap[property].display;
  end

  allProperties.display[9999] = "•" .. L["Remove this property"] .. "•";
  allProperties.indexToProperty[9999] = "DELETE";

  if (data.controlledChildren) then
    allProperties.displayWithCopy = {};
    WeakAuras.DeepCopy(allProperties.display, allProperties.displayWithCopy);

    allProperties.displayWithCopy[9998] = "•" .. L["Copy to all auras"] .. "•";
    allProperties.indexToProperty[9998] = "COPY";
  end

  return allProperties;
end

local function findMatchingCondition(all, needle, start)
  while (true) do
    local condition = all[start];
    if (not condition) then
      return nil;
    end

    if (condition.check.trigger == needle.check.trigger and condition.check.variable == needle.check.variable) then
      return start;
    end
    start = start + 1;
  end
end

local function findMatchingProperty(all, change, id)
  for index, allChange in ipairs(all) do
    if (allChange.property == change.property) then
      local alreadyReferenced = allChange.references and allChange.references[id];
      if (not alreadyReferenced) then
        return index;
      end
    end
  end
  return nil;
end

local function mergeConditionChange(all, change, id, changeIndex, allProperties)
  local propertyType = all.property and allProperties.propertyMap[all.property] and allProperties.propertyMap[all.property].type
  if not compareValues(all.value, change.value, propertyType) then
    all.value = nil;
    all.samevalue = false;
  end

  all.references = all.references or {};
  all.references[id] = {
    ["changeIndex"] = changeIndex,
    ["value"] = change.value
  };
  all.referenceCount = (all.referenceCount or 0) + 1;

end

local function mergeCondition(all, aura, id, conditionIndex, allProperties)
  if (all.check.op ~= aura.check.op) then
    all.check.op = nil;
    all.check.sameop = false;
  end

  if (all.check.value ~= aura.check.value) then
    all.check.value = nil;
    all.check.samevalue = false;
  end


  all.check.references = all.check.references or {};
  all.check.references[id] = {
    ["conditionIndex"] = conditionIndex,
    ["op"] = aura.check.op,
    ["value"] = aura.check.value
  };
  all.check.referenceCount = (all.check.referenceCount or 0) + 1;

  -- Merge properties
  local currentInsertPoint = 1;
  for changeIndex, change in ipairs(aura.changes) do
    local matchIndex = findMatchingProperty(all.changes, change, id);
    if (not matchIndex) then
      local copy = {};
      WeakAuras.DeepCopy(change, copy);
      copy.samevalue = true;
      copy.references = {};
      copy.references[id] = {
        ["changeIndex"] = changeIndex,
        ["value"] = copy.value
      }
      copy.referenceCount = 1;
      tinsert(all.changes, currentInsertPoint, copy);
      currentInsertPoint = currentInsertPoint + 1;
    else
      mergeConditionChange(all.changes[matchIndex], change, id, changeIndex, allProperties);
      currentInsertPoint = matchIndex + 1;
    end
  end
end

local function mergeConditions(all, aura, id, propertyTypes)
  if (not aura) then
    return;
  end

  local currentInsertPoint = 1;
  for conditionIndex, condition in ipairs(aura) do
    local match = findMatchingCondition(all, condition, currentInsertPoint);
    if (not match) then
      local copy = {};
      WeakAuras.DeepCopy(condition, copy);
      copy.check.samevalue = true;
      copy.check.sameop = true;
      copy.check.references = {};
      copy.check.references[id] = {
        ["conditionIndex"] = conditionIndex,
        ["op"] = condition.check.op,
        ["value"] = condition.check.value
      };
      copy.check.referenceCount = 1;

      if (copy.changes) then
        for changeIndex, change in pairs(copy.changes) do
          change.samevalue = true;
          change.references = {};
          change.references[id] = {
            ["changeIndex"] = changeIndex,
            ["value"] = change.value
          };
          change.referenceCount = 1;
        end
      end

      tinsert(all, currentInsertPoint, copy);
      currentInsertPoint = currentInsertPoint + 1;
    else
      mergeCondition(all[match], condition, id, conditionIndex, propertyTypes);
      currentInsertPoint = match + 1;
    end
  end
end

function WeakAuras.GetConditionOptions(data)
  -- Build potential Conditions Templates structure
  local conditionTemplates = createConditionTemplates(data);

  -- Build potential properties structure
  local allProperties = buildAllPotentialProperies(data);

  -- Build currently selected conditions
  local conditions;
  if (data.controlledChildren) then
    conditions = {};
    local last = #data.controlledChildren;
    for index = last, 1, -1 do
      local id = data.controlledChildren[index];
      local data = WeakAuras.GetData(id);
      mergeConditions(conditions, data.conditions, data.id, allProperties);
    end
  else
    data.conditions = data.conditions or {};
    conditions = data.conditions;
  end

  local args = {};
  local order = 0;
  for i = 1, #conditions do
    order = addControlsForCondition(args, order, data, conditions, i, conditionTemplates, allProperties);
  end
  args["addCondition"] = {
    type = "execute",
    name = L["Add Condition"],
    order = order,
    func = function()
      if (data.controlledChildren) then
        for _, id in ipairs(data.controlledChildren) do
          local aura = WeakAuras.GetData(id);
          aura.conditions[#aura.conditions + 1] = {};
          aura.conditions[#aura.conditions].check = {};
          aura.conditions[#aura.conditions].changes = {};
          aura.conditions[#aura.conditions].changes[1] = {}
          WeakAuras.Add(aura);
        end
        WeakAuras.ReloadTriggerOptions(data);
      else
        conditions[#conditions + 1] = {};
        conditions[#conditions].check = {};
        conditions[#conditions].changes = {};
        conditions[#conditions].changes[1] = {}
        WeakAuras.Add(data);
        WeakAuras.ReloadTriggerOptions(data);
      end
    end
  }
  order = order + 1;

  return args;
end
