
-- A bit of terminology
-- Templates:
--   The potential conditions that are offered by the triggers
-- The data structure returned by GetTriggerConditions(data) is
-- [] Trigger number
--   [] Condition name
--      - display: Display Name
--      - type: Type, e.g. "select", "number", "timer", "unit"
--      - values: (only for "select" and "unit")
--      - test: a test function template

-- Conditions + Changes: Actually active settings on a aura
-- Datastructure:
-- [] Index
--    - check
--      - trigger: Trigger number. Negative values indicate a special check:
--          -1: Global conditions
--          -2: Combinator
--      - variable: Variable inside the trigger state to check
--      - op: Operator to use for check
--      - value: Value to check
--      - checks: Sub Checks for Combinations, each containing trigger, variable, op, value or checks
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
--   - setter: The setter function, called both on activating and deactivating a property change
---  - action: The action function, called on activating a condition
--   - type: The type
if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local function addSpace(args, order)
  args["space" .. order] = {
    type = "description",
    name = "",
    image = function() return "", 0, 0 end,
    order = order,
    width = WeakAuras.normalWidth
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
      local r, g, b, alpha = floor((a[1] or 0) * 255), floor((a[2] or 0) * 255), floor((a[3] or 0) * 255), floor((a[4] or 0) * 255)
      return string.format("|c%02X%02X%02X%02X", alpha, r, g, b) .. L["color"];
    else
      return "";
    end
  elseif (propertytype == "chat" or propertytype == "sound" or propertytype == "customcode"
          or propertytype == "glowexternal" or propertytype == "customcheck") then
    return tostring(a);
  elseif (propertytype == "alwaystrue") then
    return ""
  elseif (propertytype == "bool") then
    return (a == 1 or a == true) and L["True"] or L["False"];
  end
  return tostring(a);
end

local function isSubset(data, reference, totalAuraCount)
  if (data.controlledChildren) then
    if (totalAuraCount > reference.referenceCount) then
      return true;
    end
  end
  return false;
end

local function blueIfSubset(data, reference, totalAuraCount)
  if (isSubset(data, reference, totalAuraCount)) then
    return "|cFF4080FF";
  end
  return "";
end

local function blueIfNoValue(data, object, variable, blueString, normalString)
  if (data.controlledChildren) then
    if (object["same" .. variable] == false) then
      return "|cFF4080FF" .. blueString;
    end
  end
  return normalString or "";
end

local function blueIfNoValue2(data, object, variable, subvariable, blueString, normalString)
  if (data.controlledChildren) then
    if (not object["same" .. variable] or not object["same" .. variable][subvariable]) then
      return "|cFF4080FF" .. blueString;
    end
  end
  return normalString or "";
end

local function descIfSubset(data, reference, totalAuraCount)
  if (isSubset(data, reference, totalAuraCount)) then
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

local function descIfNoValue2(data, object, variable, subvariable, type, values)
  if (data.controlledChildren) then
    if (object["same" .. variable] and object["same" .. variable][subvariable] == false) then
      local desc = "";
      for id, reference in pairs(object.references) do
        if (values) then
          desc = desc .."|cFFE0E000".. id .. ": |r" .. (values[reference[variable][subvariable]] or "") .. "\n";
        else
          desc = desc .."|cFFE0E000".. id .. ": |r" .. valueToString(reference[variable][subvariable], type or "") .. "\n";
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

local function wrapWithPlaySound(func, kit)
  return function(info, v)
    func(info, v);
    if (tonumber(v)) then
      pcall(PlaySound, tonumber(v), "Master");
    else
      pcall(PlaySoundFile, v, "Master");
    end
  end
end

local function addControlsForChange(args, order, data, conditionVariable, totalAuraCount, conditions, i, j, allProperties, usedProperties)
  local thenText = (j == 1) and L["Then "] or L["And "];
  local display = isSubset(data, conditions[i].changes[j], totalAuraCount) and allProperties.displayWithCopy or allProperties.display;
  local valuesForProperty = filterUsedProperties(allProperties.indexToProperty, display, usedProperties, conditions[i].changes[j].property);
  args["condition" .. i .. "property" .. j] = {
    type = "select",
    width = WeakAuras.normalWidth,
    name = blueIfSubset(data, conditions[i].changes[j], totalAuraCount) .. thenText,
    desc = descIfSubset(data, conditions[i].changes[j], totalAuraCount),
    order = order,
    values = valuesForProperty,
    control = "WeakAurasTwoColumnDropdown",
    get = function()
      local property = conditions[i].changes[j].property;
      return property and allProperties.propertyToIndex[property];
    end,
    set = function(info, index)
      local property = allProperties.indexToProperty[index];
      if (property == "COPY") then
        for child in OptionsPrivate.Private.TraverseLeafs(data) do
          if (conditions[i].changes[j].references[child.id]) then
          -- Already exist
          else
            local insertPoint = 1;
            for index = j, 1, -1 do
              if (conditions[i].changes[index].references[child.id]) then
                insertPoint = index + 1;
                break;
              end
            end

            local change = {};
            change.property = conditions[i].changes[j].property;
            if (type(conditions[i].changes[j].value) == "table") then
              change.value = CopyTable(conditions[i].changes[j].value)
            else
              change.value = conditions[i].changes[j].value;
            end

            local reference = conditions[i].check.references[child.id]
            if reference then
              local conditionIndex = reference.conditionIndex;
              tinsert(child[conditionVariable][conditionIndex].changes, insertPoint, change);
              WeakAuras.Add(child);
              OptionsPrivate.ClearOptions(child.id)
            end
          end
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
        return;
      elseif (property == "DELETE") then
        if (data.controlledChildren) then
          for id, reference in pairs(conditions[i].changes[j].references) do
            local auraData = WeakAuras.GetData(id);
            local conditionIndex = conditions[i].check.references[id].conditionIndex;
            tremove(auraData[conditionVariable][conditionIndex].changes, reference.changeIndex);
            WeakAuras.Add(auraData);
            OptionsPrivate.ClearOptions(auraData.id)
          end
          WeakAuras.ClearAndUpdateOptions(data.id)
        else
          tremove(conditions[i].changes, j);
          WeakAuras.Add(data);
          WeakAuras.ClearAndUpdateOptions(data.id)
        end
        return;
      end

      local default = allProperties.propertyMap[property].default;
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].changes[j].references) do
          local auraData = WeakAuras.GetData(id);
          local conditionIndex = conditions[i].check.references[id].conditionIndex;
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].property = property;
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value = default;
          WeakAuras.Add(auraData);
          OptionsPrivate.ClearOptions(auraData.id)
        end
        conditions[i].changes[j].property = property;
        WeakAuras.ClearAndUpdateOptions(data.id)
      else
        conditions[i].changes[j].property = property;
        conditions[i].changes[j].value = default;
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    end
  }
  order = order + 1;

  local setValue;
  local setValueColor;
  local setValueComplex;
  local setValueColorComplex;
  if (data.controlledChildren) then
    setValue = function(info, v)
      for id, reference in pairs(conditions[i].changes[j].references) do
        local auraData = WeakAuras.GetData(id);
        local conditionIndex = conditions[i].check.references[id].conditionIndex;
        auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value = v;
        WeakAuras.Add(auraData);
        OptionsPrivate.ClearOptions(auraData.id)
      end
      conditions[i].changes[j].value = v;
      WeakAuras.ClearAndUpdateOptions(data.id)
    end
    setValueColor = function(info, r, g, b, a)
      for id, reference in pairs(conditions[i].changes[j].references) do
        local auraData = WeakAuras.GetData(id);
        local conditionIndex = conditions[i].check.references[id].conditionIndex;
        auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value = auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value or {};
        auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[1] = r;
        auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[2] = g;
        auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[3] = b;
        auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[4] = a;
        WeakAuras.Add(auraData);
        OptionsPrivate.ClearOptions(auraData.id)
      end
      conditions[i].changes[j].value = conditions[i].changes[j].value or {};
      conditions[i].changes[j].value[1] = r;
      conditions[i].changes[j].value[2] = g;
      conditions[i].changes[j].value[3] = b;
      conditions[i].changes[j].value[4] = a;
      WeakAuras.ClearAndUpdateOptions(data.id)
    end

    setValueComplex = function(property)
      return function(info, v)
        for id, reference in pairs(conditions[i].changes[j].references) do
          local auraData = WeakAuras.GetData(id);
          local conditionIndex = conditions[i].check.references[id].conditionIndex;
          if (type(auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value) ~= "table") then
            auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value = {};
          end
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[property] = v;
          WeakAuras.Add(auraData);
          OptionsPrivate.ClearOptions(auraData.id)
        end
        if (type(conditions[i].changes[j].value) ~= "table") then
          conditions[i].changes[j].value = {};
        end
        conditions[i].changes[j].value[property] = v;

        WeakAuras.Add(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    end

    setValueColorComplex = function(property)
      return function(info, r, g, b, a)
        for id, reference in pairs(conditions[i].changes[j].references) do
          local auraData = WeakAuras.GetData(id);
          local conditionIndex = conditions[i].check.references[id].conditionIndex;
          if (type(auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value) ~= "table") then
            auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value = {};
          end
          if (type(auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[property]) ~= "table") then
            auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[property] = {};
          end
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[property][1] = r;
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[property][2] = g;
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[property][3] = b;
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value[property][4] = a;
          WeakAuras.Add(auraData);
          OptionsPrivate.ClearOptions(auraData.id)
        end
        if (type(conditions[i].changes[j].value) ~= "table") then
          conditions[i].changes[j].value = {};
        end
        if (type(conditions[i].changes[j].value[property]) ~= "table") then
          conditions[i].changes[j].value[property] = {};
        end
        conditions[i].changes[j].value[property][1] = r;
        conditions[i].changes[j].value[property][2] = g;
        conditions[i].changes[j].value[property][3] = b;
        conditions[i].changes[j].value[property][4] = a;
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    end
  else
    setValue = function(info, v)
      conditions[i].changes[j].value = v;
      WeakAuras.Add(data);
      WeakAuras.ClearAndUpdateOptions(data.id)
    end
    setValueColor = function(info, r, g, b, a)
      conditions[i].changes[j].value = conditions[i].changes[j].value or {};
      conditions[i].changes[j].value[1] = r;
      conditions[i].changes[j].value[2] = g;
      conditions[i].changes[j].value[3] = b;
      conditions[i].changes[j].value[4] = a;
      WeakAuras.Add(data);
      WeakAuras.ClearAndUpdateOptions(data.id)
    end

    setValueComplex = function(property)
      return function(info, v)
        if (type (conditions[i].changes[j].value) ~= "table") then
          conditions[i].changes[j].value = {};
        end
        conditions[i].changes[j].value[property] = v;
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    end

    setValueColorComplex = function(property)
      return function(info, r, g, b, a)
        if (type (conditions[i].changes[j].value) ~= "table") then
          conditions[i].changes[j].value = {};
        end
        if (type (conditions[i].changes[j].value[property]) ~= "table") then
          conditions[i].changes[j].value[property] = {};
        end
        conditions[i].changes[j].value[property][1] = r;
        conditions[i].changes[j].value[property][2] = g;
        conditions[i].changes[j].value[property][3] = b;
        conditions[i].changes[j].value[property][4] = a;
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
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
      width = WeakAuras.normalWidth,
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
        args["condition" .. i .. "value" .. j].isPercent = properties.isPercent;
      else
        args["condition" .. i .. "value" .. j].type = "input";
        args["condition" .. i .. "value" .. j].validate = WeakAuras.ValidateNumeric;
      end
    end
  elseif (propertyType == "icon") then
    args["condition" .. i .. "value" .. j] = {
      type = "input",
      width = WeakAuras.normalWidth - 0.15,
      name = blueIfNoValue(data, conditions[i].changes[j], "value", L["Differences"]),
      desc = descIfNoValue(data, conditions[i].changes[j], "value", propertyType),
      order = order,
      get = function()
        local v = conditions[i].changes[j].value
        return v and tostring(v)
      end,
      set = setValue
    }
    order = order + 1
    args["condition" .. i .. "value_browse" .. j] = {
      type = "execute",
      width = 0.15,
      name = "",
      order = order,
      func = function()
        if data.controlledChildren then
          local paths = {}
          for id, reference in pairs(conditions[i].changes[j].references) do
            paths[id] = {"conditions", conditions[i].check.references[id].conditionIndex, "changes", reference.changeIndex, "value"}
          end
          OptionsPrivate.OpenIconPicker(data, paths)
        else
          OptionsPrivate.OpenIconPicker(data, {[data.id] = { "conditions", i, "changes", j, "value" } })
        end
      end,
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon",
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
    }
  elseif (propertyType == "color") then
    args["condition" .. i .. "value" .. j] = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue(data, conditions[i].changes[j], "value", L["Differences"]),
      desc = descIfNoValue(data, conditions[i].changes[j], "value", propertyType),
      order = order,
      hasAlpha = true,
      get = function()
        if (conditions[i].changes[j].value and type(conditions[i].changes[j].value) == "table") then
          return conditions[i].changes[j].value[1], conditions[i].changes[j].value[2], conditions[i].changes[j].value[3], conditions[i].changes[j].value[4];
        end
        return 1, 1, 1, 1;
      end,
      set = setValueColor
    }
    order = order + 1;
  elseif (propertyType == "list") then
    local values = property and allProperties.propertyMap[property] and allProperties.propertyMap[property].values;
    args["condition" .. i .. "value" .. j] = {
      type = "select",
      width = WeakAuras.normalWidth,
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
  elseif (propertyType == "sound") then
    args["condition" .. i .. "value" .. j .. "sound_type"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      values = OptionsPrivate.Private.sound_condition_types,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound_type", L["Differences"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound_type", propertyType, OptionsPrivate.Private.sound_condition_types),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound_type;
      end,
      set = setValueComplex("sound_type"),
    }
    order = order + 1;

    local function anySoundType(needle)
      local sound_type = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound_type;
      if (sound_type) then
        return sound_type == needle;
      end
      if (conditions[i].changes[j].references) then
        for id, reference in pairs(conditions[i].changes[j].references) do
          if (type(reference.value) == "table" and reference.value.sound_type == needle) then
            return true;
          end
        end
      end
      return false;
    end

    args["condition" .. i .. "value" .. j .. "sound"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      values = OptionsPrivate.Private.sound_types,
      sorting = OptionsPrivate.Private.SortOrderForValues(OptionsPrivate.Private.sound_types),
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound", L["Differences"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound", propertyType, OptionsPrivate.Private.sound_types),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound;
      end,
      set = wrapWithPlaySound(setValueComplex("sound")),
      hidden = function() return not (anySoundType("Play") or anySoundType("Loop")) end
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j .. "sound_channel"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      values = OptionsPrivate.Private.sound_channel_types,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound_channel", L["Sound Channel"], L["Sound Channel"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound_channel", propertyType, OptionsPrivate.Private.sound_channel_types),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound_channel;
      end,
      set = setValueComplex("sound_channel"),
      hidden = function() return not (anySoundType("Loop") or anySoundType("Play")) end
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j .. "sound_repeat"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      min = 0,
      softMax = 60,
      bigStep = 1,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound_repeat", L["Repeat every"], L["Repeat every"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound_repeat", propertyType),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound_repeat;
      end,
      set = setValueComplex("sound_repeat"),
      disabled = function() return not anySoundType("Loop") end,
      hidden = function() return not (anySoundType("Loop")) end
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j .. "sound_repeat_space"] = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = order,
      hidden = function() return not (anySoundType("Loop")) end
    }
    order = order + 1;

    local function anySoundValue(needle)
      local sound_type = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound;
      if (sound_type) then
        return sound_type == needle;
      end
      if (conditions[i].changes[j].references) then
        for id, reference in pairs(conditions[i].changes[j].references) do
          if (type(reference.value) == "table" and reference.value.sound == needle) then
            return true;
          end
        end
      end
      return false;
    end

    args["condition" .. i .. "value" .. j .. "sound_path"] = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound_path", L["Sound File Path"], L["Sound File Path"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound_path", propertyType),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound_path;
      end,
      set = wrapWithPlaySound(setValueComplex("sound_path")),
      hidden = function() return not (anySoundValue(" custom") and (anySoundType("Loop") or anySoundType("Play"))) end
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j .. "sound_kit_id"] = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound_kit_id", L["Sound Kit ID"], L["Sound Kit ID"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound_kit_id", propertyType),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound_kit_id;
      end,
      set = wrapWithPlaySound(setValueComplex("sound_kit_id")),
      hidden = function() return not (anySoundValue(" KitID")  and (anySoundType("Loop") or anySoundType("Play"))) end
    }
    order = order + 1;


  elseif (propertyType == "chat") then
    args["condition" .. i .. "value" .. j .. "message type"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      values = OptionsPrivate.Private.send_chat_message_types,
      sorting = OptionsPrivate.Private.SortOrderForValues(OptionsPrivate.Private.send_chat_message_types),
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_type", L["Differences"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "message_type", propertyType, OptionsPrivate.Private.send_chat_message_types),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message_type;
      end,
      set = setValueComplex("message_type"),
    }
    order = order + 1;

    local function anyMessageType(needle)
      local message_type = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message_type;
      if (message_type) then
        return message_type == needle;
      end
      if (conditions[i].changes[j].references) then
        for id, reference in pairs(conditions[i].changes[j].references) do
          if (type(reference.value) == "table" and reference.value.message_type == needle) then
            return true;
          end
        end
      end
      return false;
    end

    if WeakAuras.IsRetail() then
      args["condition" .. i .. "value" .. j .. "message type warning"] = {
        type = "description",
        width = WeakAuras.doubleWidth,
        name = L["Note: Automated Messages to SAY and YELL are blocked outside of Instances."],
        order = order,
        hidden = function()
          return not (anyMessageType("SAY") or anyMessageType("YELL") or anyMessageType("SMARTRAID"));
        end
      }
      order = order + 1;
    end

    args["condition" .. i .. "value" .. j .. "_indent"] = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = order,
      hidden = function()
        return anyMessageType("WHISPER");
      end
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j .. "message color"] = {
      type = "color",
      width = WeakAuras.normalWidth,
      hasAlpha = false,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_color", L["Color"], L["Color"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "message_color", propertyType),
      order = order,
      get = function()
        if (conditions[i].changes[j].value and type(conditions[i].changes[j].value) == "table") and type(conditions[i].changes[j].value.message_color) == "table" then
          return conditions[i].changes[j].value.message_color[1], conditions[i].changes[j].value.message_color[2], conditions[i].changes[j].value.message_color[3];
        end
        return 1, 1, 1, 1;
      end,
      set = setValueColorComplex("message_color"),
      hidden = function()
        return not (anyMessageType("COMBAT") or anyMessageType("PRINT") or anyMessageType("ERROR"));
      end
    }
    order = order + 1;

    local descMessage = descIfNoValue2(data, conditions[i].changes[j], "value", "message", propertyType);
    if (not descMessage and data ~= OptionsPrivate.tempGroup) then
      descMessage = L["Dynamic text tooltip"] .. OptionsPrivate.Private.GetAdditionalProperties(data)
    end

    args["condition" .. i .. "value" .. j .. "message dest"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_dest", L["Send To"], L["Send To"]),
      desc = descMessage,
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message_dest;
      end,
      set = setValueComplex("message_dest"),
      hidden = function()
        return not anyMessageType("WHISPER");
      end
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue(data, conditions[i].changes[j], "value", "message_dest_isunit", L["Is Unit"]),
      desc = descIfNoValue(data, conditions[i].changes[j], "value", "message_dest_isunit", propertyType),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message_dest_isunit;
      end,
      set = setValueComplex("message_dest_isunit"),
      hidden = function()
        return not anyMessageType("WHISPER");
      end
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j .. "message voice"] = {
      type = "select",
      width = WeakAuras.doubleWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_voice", L["Voice"], L["Voice"]),
      desc = (descIfNoValue2(data, conditions[i].changes[j], "value", "message_voice", propertyType, OptionsPrivate.Private.tts_voices) or "") .. "\n" .. L["Available Voices are system specific"],
      values = OptionsPrivate.Private.tts_voices,
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message_voice;
      end,
      set = setValueComplex("message_voice"),
      hidden = function()
        return not anyMessageType("TTS");
      end,
    }
    order = order + 1;

    local message_getter = function()
      return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message;
    end

    args["condition" .. i .. "value" .. j .. "message"] = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message", L["Message"], L["Message"]),
      desc = descMessage,
      order = order,
      get = message_getter,
      set = setValueComplex("message")
    }
    order = order + 1;


    local formatGet = function(key)
      return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value["message_format_" .. key]
    end

    local usedKeys = {}
    local function addOption(key, option)
      if usedKeys[key] then
        return
      end
      usedKeys[key] = true
      option.order = order
      order = order + 0.01
      local fullKey = "condition" .. i .. "value" .. j .. "message_format_" .. key
      option.get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value["message_format_" .. key];
      end
      local originalName = option.name
      if option.type ~= "header" then
        option.name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_format_" .. key, originalName, originalName)
        option.desc = descIfNoValue2(data, conditions[i].changes[j], "value", "message_format_" .. key, nil, option.values)
      end

      option.set = setValueComplex("message_format_" .. key)

      args[fullKey] = option
    end

    local hasTextFormatOption

    local hidden = function()
      return OptionsPrivate.IsCollapsed("format_option", "conditions", i .. "#" .. j , true)
    end

    local setHidden = function(hidden)
      OptionsPrivate.SetCollapsed("format_option", "conditions", i .. "#" .. j, hidden)
    end

    if data.controlledChildren then
      local ordered = {}
      for _, reference in pairs(conditions[i].changes[j].references) do
        tinsert(ordered, reference)
      end
      for index, reference in ipairs(ordered) do
        local input = reference.value and reference.value.message
        hasTextFormatOption = OptionsPrivate.AddTextFormatOption(input, true, formatGet, addOption, hidden, setHidden, true, index, #ordered)
      end
    else
      local input = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value["message"]
      hasTextFormatOption = OptionsPrivate.AddTextFormatOption(input, true, formatGet, addOption, hidden, setHidden, true)
    end

    if hasTextFormatOption then
      local footerOption = {
        type = "header",
        name = "",
        width = WeakAuras.doubleWidth
      }
      addOption("footer", footerOption)
    end

    local function customHidden()
      local message = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message;
      local message_dest = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message_type == "WHISPER" and conditions[i].changes[j].value.message_dest
      if (not message and not message_dest) then return true; end
      return not OptionsPrivate.Private.ContainsCustomPlaceHolder(message) and not OptionsPrivate.Private.ContainsCustomPlaceHolder(message_dest);
    end

    args["condition" .. i .. "value" .. j .. "custom"] = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "custom", L["Custom Code"], L["Custom Code"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "custom", propertyType),
      order = order,
      multiline = true,
      hidden = customHidden,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.custom;
      end,
      control = "WeakAurasMultiLineEditBox",
      set = setValueComplex("custom"),
      arg = {
        extraFunctions = {
          {
            buttonLabel = L["Expand"],
            func = function()
              if (data.controlledChildren) then
                -- Collect multi paths
                local multipath = {};
                for id, reference in pairs(conditions[i].changes[j].references) do
                  local conditionIndex = conditions[i].check.references[id].conditionIndex;
                  local changeIndex = reference.changeIndex;
                  multipath[id] = {"conditions", conditionIndex, "changes", changeIndex, "value", "custom"};
                end
                OptionsPrivate.OpenTextEditor(data, multipath, nil, true, nil, nil, "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#chat-message---custom-code-1");
              else
                OptionsPrivate.OpenTextEditor(data, {"conditions", i, "changes", j, "value", "custom"}, nil, nil, nil, nil, "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#chat-message---custom-code-1");
              end
            end
          }
        }
      }
    }

    order = order + 1;

    args["condition" .. i .. "value" .. j .. "custom_error"] = {
      type = "description",
      name = function()
        local custom = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.custom;
        if not custom then
          return "";
        end
        local _, errorString = loadstring("return  " .. custom);
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = WeakAuras.doubleWidth,
      order = order,
      hidden = function()
        local message = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message;
        if (not message) then
          return true;
        end
        if (not OptionsPrivate.Private.ContainsCustomPlaceHolder(message)) then
          return true;
        end

        local custom = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.custom;

        if (not custom) then
          return true;
        end

        local loadedFunction, errorString = loadstring("return " .. custom);
        if(errorString and not loadedFunction) then
          return false;
        else
          return true;
        end
      end
    }
    order = order + 1;

  elseif(propertyType == "customcode") then
    order = addSpace(args, order);

    args["condition" .. i .. "value" .. j .. "custom"] = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_custom", L["Custom Code"], L["Custom Code"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "message_custom", propertyType),
      order = order,
      multiline = true,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.custom;
      end,
      control = "WeakAurasMultiLineEditBox",
      set = setValueComplex("custom"),
      arg = {
        extraFunctions = {
          {
            buttonLabel = L["Expand"],
            func = function()
              if (data.controlledChildren) then
                -- Collect multi paths
                local multipath = {};
                for id, reference in pairs(conditions[i].changes[j].references) do
                  local conditionIndex = conditions[i].check.references[id].conditionIndex;
                  local changeIndex = reference.changeIndex;
                  local childData = WeakAuras.GetData(id);
                  childData.conditions[conditionIndex].changes[changeIndex].value = childData.conditions[conditionIndex].changes[changeIndex].value or {};
                  multipath[id] = {"conditions", conditionIndex, "changes", changeIndex, "value", "custom"};
                end
                OptionsPrivate.OpenTextEditor(data, multipath, true, true, nil, nil, "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#run-custom-code");
              else
                data.conditions[i].changes[j].value = data.conditions[i].changes[j].value or {};
                OptionsPrivate.OpenTextEditor(data, {"conditions", i, "changes", j, "value", "custom"}, true, nil, nil, nil, "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#run-custom-code");
              end
            end
          }
        }
      }
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j .. "custom_error"] = {
      type = "description",
      name = function()
        local custom = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.custom;
        if not custom then
          return "";
        end
        local _, errorString = loadstring("return function() " .. custom .. "\n end");
        return errorString and "|cFFFF0000"..errorString or "";
      end,
      width = WeakAuras.doubleWidth,
      order = order,
      hidden = function()
        local custom = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.custom;

        if (not custom) then
          return true;
        end
        local loadedFunction, errorString = loadstring("return function() " .. custom .. "\n end");
        if(errorString and not loadedFunction) then
          return false;
        else
          return true;
        end
      end
    }
    order = order + 1;
  elseif (propertyType == "glowexternal") then
    local function anyGlowExternal(property, needle)
      local ref = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value[property]
      if ref then
        if type(needle) == "table" then
          return needle[ref]
        else
          return ref == needle
        end
      end
      if conditions[i].changes[j].references then
        for id, reference in pairs(conditions[i].changes[j].references) do
          if type(reference.value) == "table" then
            if type(needle) == "table" then
              if needle[reference.value[property]] then
                return true
              end
            else
              if reference.value[property] == needle then
                return true
              end
            end
          end
        end
      end
      return false
    end

    local glowTypesExcepButtonOverlay = CopyTable(OptionsPrivate.Private.glow_types)
    glowTypesExcepButtonOverlay["buttonOverlay"] = nil

    args["condition" .. i .. "value" .. j .. "glow_action"] = {
      type = "select",
      values = OptionsPrivate.Private.glow_action_types,
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_action", L["Glow Action"], L["Glow Action"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_action", propertyType, OptionsPrivate.Private.glow_action_types),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_action;
      end,
      set = setValueComplex("glow_action")
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_frame_type"] = {
      type = "select",
      values = OptionsPrivate.Private.glow_frame_types,
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_frame_type", L["Glow Frame Type"], L["Glow Frame Type"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_frame_type", propertyType, {
        UNITFRAME = L["Unit Frame"],
        NAMEPLATE = L["Nameplate"],
        FRAMESELECTOR = L["Frame Selector"]
      }),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_frame_type;
      end,
      hidden = function() return not anyGlowExternal("glow_action", OptionsPrivate.Private.glow_action_types) end,
      set = setValueComplex("glow_frame_type")
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_type"] = {
      type = "select",
      values = OptionsPrivate.Private.glow_types,
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_type", L["Glow Type"], L["Glow Type"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_type", propertyType, OptionsPrivate.Private.glow_types),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_type;
      end,
      set = setValueComplex("glow_type"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_frame_type", OptionsPrivate.Private.glow_frame_types))
      end
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_frame"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_frame", L["Frame"], L["Frame"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_frame", propertyType),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_frame;
      end,
      set = setValueComplex("glow_frame"),
      hidden = function()
        return not anyGlowExternal("glow_frame_type", "FRAMESELECTOR")
      end
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "choose_glow_frame"] = {
      type = "execute",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_frame", L["Choose"], L["Choose"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_frame", propertyType),
      order = order,
      func = function()
        OptionsPrivate.StartFrameChooser(data, {"conditions", i, "changes", j, "value", "glow_frame"});
      end,
      hidden = function()
        return not anyGlowExternal("glow_frame_type", "FRAMESELECTOR")
      end
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "use_glow_color"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "use_glow_color", L["Glow Color"], L["Glow Color"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "use_glow_color", propertyType),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.use_glow_color;
      end,
      set = setValueComplex("use_glow_color"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", OptionsPrivate.Private.glow_types))
      end
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_color"] = {
      type = "color",
      hasAlpha = true,
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_color", L["Glow Color"], L["Glow Color"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_color", "color"),
      order = order,
      get = function()
        if (conditions[i].changes[j].value and type(conditions[i].changes[j].value) == "table") and type(conditions[i].changes[j].value.glow_color) == "table" then
          return conditions[i].changes[j].value.glow_color[1], conditions[i].changes[j].value.glow_color[2], conditions[i].changes[j].value.glow_color[3], conditions[i].changes[j].value.glow_color[4];
        end
        return 1, 1, 1, 1;
      end,
      set = setValueColorComplex("glow_color"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show")
                    and anyGlowExternal("glow_frame_type", OptionsPrivate.Private.glow_frame_types)
                    and anyGlowExternal("glow_type", OptionsPrivate.Private.glow_types))
      end,
      disabled = function() return not anyGlowExternal("use_glow_color", true) end
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_lines"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_lines", L["Lines & Particles"], L["Lines & Particles"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_lines", propertyType),
      order = order,
      min = 1,
      softMax = 30,
      step = 1,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_lines or 8;
      end,
      set = setValueComplex("glow_lines"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", glowTypesExcepButtonOverlay))
      end,
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_frequency"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_frequency", L["Frequency"], L["Frequency"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_frequency", propertyType),
      order = order,
      softMin = -2,
      softMax = 2,
      step = 0.05,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_frequency or 0.25;
      end,
      set = setValueComplex("glow_frequency"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", glowTypesExcepButtonOverlay))
      end,
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_length"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_length", L["Length"], L["Length"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_length", propertyType),
      order = order,
      min = 0.05,
      softMax = 20,
      step = 0.05,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_length or 10;
      end,
      set = setValueComplex("glow_length"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", "Pixel"))
      end,
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_thickness"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_thickness", L["Thickness"], L["Thickness"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_thickness", propertyType),
      order = order,
      min = 0.05,
      softMax = 20,
      step = 0.05,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_thickness or 1;
      end,
      set = setValueComplex("glow_thickness"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", "Pixel"))
      end,
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_XOffset"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_XOffset", L["X-Offset"], L["X-Offset"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_XOffset", propertyType),
      order = order,
      softMin = -100,
      softMax = 100,
      step = 0.5,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_XOffset or 0;
      end,
      set = setValueComplex("glow_XOffset"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", glowTypesExcepButtonOverlay))
      end,
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_YOffset"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_YOffset", L["Y-Offset"], L["Y-Offset"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_YOffset", propertyType),
      order = order,
      softMin = -100,
      softMax = 100,
      step = 0.5,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_YOffset or 0;
      end,
      set = setValueComplex("glow_YOffset"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", "Pixel"))
      end,
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_scale"] = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_scale", L["Scale"], L["Scale"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_scale", propertyType),
      order = order,
      min = 0.05,
      softMax = 10,
      step = 0.05,
      isPercent = true,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_scale or 1;
      end,
      set = setValueComplex("glow_scale"),
      hidden = function()
        return not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", "ACShine"))
      end,
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_border"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "glow_border", L["Border"], L["Border"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "glow_border", propertyType),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.glow_border;
      end,
      set = setValueComplex("glow_border"),
      hidden = function() return
        not (anyGlowExternal("glow_action", "show") and anyGlowExternal("glow_type", "Pixel"))
      end,
    }
    order = order + 1
    args["condition" .. i .. "value" .. j .. "glow_spacer"] = {
      type = "description",
      width = WeakAuras.doubleWidth,
      name = "",
      order = order,
      hidden = false,
    }
    order = order + 1
  else -- Unknown property type
    order = addSpace(args, order);
  end
  return order;
end


local function checkSameValue(samevalue, propertyType)
  if (propertyType == "chat") then
    return samevalue.message_type and samevalue.message;
  elseif (propertyType == "sound") then
    return samevalue.sound and samevalue.sound_type;
  elseif (propertyType == "customcode") then
    return samevalue.custom;
  else
    return samevalue;
  end
end

local function getOrCreateSubCheck(base, path)
  for _, i in ipairs(path) do
    base.checks = base.checks or {};
    base.checks[i] = base.checks[i] or {};
    base = base.checks[i];
  end
  return base;
end


local function getSubCheck(base, path)
  for _, i in ipairs(path) do
    if (not base.checks or not base.checks[i]) then
      return nil;
    end
    base = base.checks[i];
  end
  return base;
end

local function removeSubCheck(base, path)
  -- Ensures that the parents exists
  getOrCreateSubCheck(base, path);

  local choppedPath = CopyTable(path);
  tremove(choppedPath, #path);

  local parent = getSubCheck(base, choppedPath);
  tremove(parent.checks, path[#path]);
end

local function addControlsForIfLine(args, order, data, conditionVariable, totalAuraCount, conditions, i, path, conditionTemplates, conditionTemplateWithoutCombinations, allProperties, parentType)
  local check = getSubCheck(conditions[i].check, path);

  local indentDepth = min(#path, 3); -- Be reasonable
  local indentWidth = (indentDepth > 0 and 0.02 or 0) + indentDepth * 0.03;
  local normalWidth = WeakAuras.normalWidth - indentWidth;

  local conditionTemplatesToUse = indentDepth < 3 and conditionTemplates or conditionTemplateWithoutCombinations;

  local optionsName = blueIfSubset(data, conditions[i].check, totalAuraCount);
  local needsTriggerName = check and check.trigger and check.trigger ~= -1 and check.trigger ~= -2;
  if (parentType) then
    local isFirst = path[#path] == 1;
    if (isFirst) then
      if (needsTriggerName) then
        optionsName = optionsName .. string.format(L["Trigger %s"], check.trigger);
      end
    else
      if (needsTriggerName) then
        if (parentType == "AND") then
          optionsName = optionsName .. string.format(L["and Trigger %s"], check.trigger);
        else
          optionsName = optionsName .. string.format(L["or Trigger %s"], check.trigger);
        end
      end
    end
  else
    local isLinked = conditions[i].linked and i > 1
    if (needsTriggerName) then
      if isLinked then
        optionsName = optionsName .. string.format(L["Else If Trigger %s"], check.trigger);
      else
        optionsName = optionsName .. string.format(L["If Trigger %s"], check.trigger);
      end
    else
        optionsName = optionsName .. (isLinked and L["Else If"] or L["If"])
    end
  end

  if (indentWidth > 0) then
    -- Our container frame is not exactly at width = 2, due to some legacy
    -- Typically that works fine because the next widget doesn't fit into
    -- previous line. But the bullets are so small that we need to ensure
    -- that the previous line is full
    args["space" .. order] = {
      type = "description",
      name = "",
      image = function() return "", 0, 0 end,
      order = order,
      width = WeakAuras.doubleWidth * 1.5,
    }
    order = order + 1;

    if (indentWidth > 0.05) then
      args["condition" .. i .. tostring(path) .. "indent"] = {
        type = "description",
        width = indentWidth - 0.05,
        name = "",
        order = order
      }
      order = order + 1;
    end

    args["condition" .. i .. tostring(path) .. "bullet"] = {
      type = "description",
      width = 0.05,
      name = "",
      order = order,
      image = "Interface\\Addons\\WeakAuras\\Media\\Textures\\bullet" .. indentDepth,
      imageWidth = 10,
      imageHeight = 10,
    }
    order = order + 1;
  end

  local valuesForIf;
  if (indentDepth > 0) then
    valuesForIf = conditionTemplatesToUse.displayWithRemove;
  else
    valuesForIf = isSubset(data, conditions[i].check, totalAuraCount) and conditionTemplatesToUse.displayWithCopy or conditionTemplatesToUse.display;
  end

  args["condition" .. i .. tostring(path) .. "if"] = {
    type = "select",
    name = optionsName,
    desc = descIfSubset(data, conditions[i].check, totalAuraCount),
    order = order,
    values = valuesForIf,
    width = normalWidth;
    set = function(info, v)
      if (conditionTemplatesToUse.indexToTrigger[v] == "COPY") then
        for child in OptionsPrivate.Private.TraverseLeafs(data) do
          if (conditions[i].check.references[child.id]) then
          -- Already exists
          else
            -- find a good insertion point, if any other condition has a reference to this
            -- insert directly after that
            local insertPoint = 1;
            for index = i, 1, -1 do
              if (conditions[index].check.references[child.id]) then
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
            if (conditions[i].check.checks) then
              condition.check.checks = CopyTable(conditions[i].check.checks);
            end

            condition.changes = {};
            for changeIndex, change in ipairs(conditions[i].changes) do
              local propertyType = change.property and allProperties.propertyMap[change.property] and allProperties.propertyMap[change.property].type
              if (checkSameValue(change.samevalue, propertyType)) then
                local copy = {};
                copy.property = change.property;
                if (type(change.value) == "table") then
                  copy.value = CopyTable(change.value);
                else
                  copy.value = change.value;
                end
                tinsert(condition.changes, copy);
              end
            end

            tinsert(child[conditionVariable], insertPoint, condition);
            WeakAuras.Add(child);
            OptionsPrivate.ClearOptions(child.id)
          end
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
        return;
      end

      if (conditionTemplatesToUse.indexToTrigger[v] == "REMOVE") then
        if (data.controlledChildren) then
          for id, reference in pairs(conditions[i].check.references) do
            local auraData = WeakAuras.GetData(id);
            removeSubCheck(auraData[conditionVariable][reference.conditionIndex].check, path);
            WeakAuras.Add(auraData)
            WeakAuras.ClearAndUpdateOptions(auraData.id)
          end
        else
          removeSubCheck(conditions[i].check, path);
          WeakAuras.Add(data)
          WeakAuras.ClearAndUpdateOptions(data.id)
        end
        return;
      end

      local trigger = conditionTemplatesToUse.indexToTrigger[v];
      local variable = conditionTemplatesToUse.indexToVariable[v];
      if (not trigger or not variable) then
        return;
      end

      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          local childCheck = getOrCreateSubCheck(auraData[conditionVariable][reference.conditionIndex].check, path);
          childCheck.variable = variable;
          childCheck.trigger = trigger;
          childCheck.value = nil;
          WeakAuras.Add(auraData);
          OptionsPrivate.ClearOptions(auraData.id)
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
      else
        local oldType;
        check = getOrCreateSubCheck(conditions[i].check, path);
        if (check.trigger and check.variable) then
          local templatesForTrigger = conditionTemplatesToUse.all[check.trigger];
          local templatesForTriggerAndCondition = templatesForTrigger and templatesForTrigger[check.variable];
          oldType = templatesForTriggerAndCondition and templatesForTriggerAndCondition.type;
        end
        check.variable = variable;
        check.trigger = trigger;
        local newType = conditionTemplatesToUse.all[trigger][variable].type;
        if (newType ~= oldType) then
          check.value = nil;
        end
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    end,
    get = function()
      local trigger = check and check.trigger;
      local variable = check and check.variable;
      if ( trigger and variable ) then
        return conditionTemplatesToUse.conditionToIndex[trigger .. "-" .. variable];
      end
      return "";
    end
  };

  order = order + 1;

  if (check and (check.variable == "AND" or check.variable == "OR")) then
    order = addSpace(args, order);

    local subCheckCount = check.checks and #check.checks or 0;
    -- We always want one more control than there are existing checks
    subCheckCount = subCheckCount + 1;

    for subCheck = 1, subCheckCount do
      local subPath = CopyTable(path);
      tinsert(subPath, subCheck);
      order = addControlsForIfLine(args, order, data, conditionVariable, totalAuraCount, conditions, i, subPath, conditionTemplates, conditionTemplateWithoutCombinations, allProperties, check.variable);
    end
  end

  local currentConditionTemplate = nil;
  local trigger = check and check.trigger;
  local variable = check and check.variable;
  if (trigger and variable) then
    if (conditionTemplatesToUse.all[trigger]) then
      currentConditionTemplate = conditionTemplatesToUse.all[trigger][variable];
    end
  end

  if (currentConditionTemplate and currentConditionTemplate.type and type(currentConditionTemplate.type) == "string") then
    local function makeSetter(field)
      if (data.controlledChildren) then
        return function(info, v)
          check = getOrCreateSubCheck(conditions[i].check, path);
          for id, reference in pairs(conditions[i].check.references) do
            local auraData = WeakAuras.GetData(id);
            local childCheck = getOrCreateSubCheck(auraData[conditionVariable][reference.conditionIndex].check, path);
            childCheck[field] = v;
            WeakAuras.Add(auraData);
            OptionsPrivate.ClearOptions(auraData.id)
          end
          check[field] = v;
          WeakAuras.ClearAndUpdateOptions(data.id)
        end
      else
        return function(info, v)
          check = getOrCreateSubCheck(conditions[i].check, path);
          check[field] = v;
          WeakAuras.Add(data);
          WeakAuras.ClearAndUpdateOptions(data.id)
        end
      end
    end

    local setOp = makeSetter("op")
    local setValue = makeSetter("value")

    if (currentConditionTemplate.type == "number" or currentConditionTemplate.type == "timer" or currentConditionTemplate.type == "elapsedTimer") then
      local opTypes = OptionsPrivate.Private.operator_types
      if currentConditionTemplate.operator_types == "without_equal" then
        opTypes = OptionsPrivate.Private.operator_types_without_equal
      elseif currentConditionTemplate.operator_types == "only_equal" then
        opTypes = OptionsPrivate.Private.equality_operator_types
      end

      args["condition" .. i .. tostring(path) .. "_op"] = {
        name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
        type = "select",
        order = order,
        values = opTypes,
        width = WeakAuras.halfWidth,
        get = function()
          return check.op;
        end,
        set = setOp,
      }
      order = order + 1;

      args["condition" .. i .. tostring(path) .. "_value"] = {
        type = "input",
        name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
        width = WeakAuras.halfWidth,
        order = order,
        validate = WeakAuras.ValidateNumeric,
        get = function()
          return check.value;
        end,
        set = setValue
      }
      order = order + 1;
    elseif (currentConditionTemplate.type == "select") or (currentConditionTemplate.type == "unit") then
      if (type(currentConditionTemplate.values) == "table") then
        args["condition" .. i .. tostring(path) .. "_op"] = {
          name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
          desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
          type = "select",
          width = WeakAuras.normalWidth,
          order = order,
          values = OptionsPrivate.Private.equality_operator_types,
          get = function()
            return check.op;
          end,
          set = setOp,
        }
        order = order + 1;

        order = addSpace(args, order);

        if (currentConditionTemplate.type == "unit") then
          args["condition" .. i .. tostring(path) .. "_value"] = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
            desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
            order = order,
            values = currentConditionTemplate.values,
            get = function()
              return currentConditionTemplate.values[check.value] and check.value or (check.value and "member")
            end,
            set = setValue
          }
          order = order + 1;

          args["condition" .. i .. tostring(path) .. "_member"] = {
            type = "input",
            width = WeakAuras.doubleWidth,
            name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
            desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
            order = order,
            get = function()
              return check and check.value
            end,
            set = setValue,
            hidden = function()
              return not conditions[i].check.value or currentConditionTemplate.values[conditions[i].check.value] and conditions[i].check.value ~= "member"
            end
          }
          order = order + 1;
        else
          args["condition" .. i .. tostring(path) .. "_value"] = {
            type = "select",
            width = WeakAuras.normalWidth,
            name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
            desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
            order = order,
            values = currentConditionTemplate.values,
            get = function()
              return check.value
            end,
            set = setValue
          }
          order = order + 1;
        end
      end
    elseif (currentConditionTemplate.type == "bool") then
      args["condition" .. i .. tostring(path) .. "_value"] = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
        order = order,
        values = OptionsPrivate.Private.bool_types,
        get = function()
          return check and check.value;
        end,
        set = setValue
      }
      order = order + 1;
    elseif (currentConditionTemplate.type == "string") then
      if currentConditionTemplate.operator_types ~= "none" then
        args["condition" .. i .. tostring(path) .. "_op"] = {
          name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
          desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
          type = "select",
          width = WeakAuras.normalWidth,
          order = order,
          values = OptionsPrivate.Private.string_operator_types,
          get = function()
            return check and check.op;
          end,
          set = setOp
        }
        order = order + 1;
        order = addSpace(args, order);
      end

      args["condition" .. i .. tostring(path) .. "_value"] = {
        type = "input",
        width = WeakAuras.normalWidth,
        name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
        order = order,
        get = function()
          return check and check.value;
        end,
        set = setValue
      }
      order = order + 1;
    elseif currentConditionTemplate.type == "alwaystrue" then
      order = addSpace(args, order)
    elseif (currentConditionTemplate.type == "range") then
      args["condition" .. i .. tostring(path) .. "_op_range"] = {
        name = blueIfNoValue(data, conditions[i].check, "op_range", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "op_range", currentConditionTemplate.type),
        type = "select",
        order = order,
        values = OptionsPrivate.Private.operator_types_without_equal,
        width = WeakAuras.halfWidth,
        get = function()
          return check.op_range;
        end,
        set = makeSetter("op_range"),
      }
      order = order + 1;

      args["condition" .. i .. tostring(path) .. "_range"] = {
        type = "input",
        name = L["Range in yards"],
        desc = descIfNoValue(data, conditions[i].check, "range", currentConditionTemplate.type),
        width = WeakAuras.halfWidth,
        order = order,
        validate = WeakAuras.ValidateNumeric,
        get = function()
          return check.range;
        end,
        set = makeSetter("range")
      }
      order = order + 1;

      if (indentWidth > 0) then
        args["condition" .. i .. tostring(path) .. "_space"] = {
          type = "description",
          name = "",
          order = order,
          width = WeakAuras.doubleWidth * 1.5,
        }
        order = order + 1;
        args["condition" .. i .. tostring(path) .. "_indent"] = {
          type = "description",
          width = indentWidth,
          name = "",
          order = order
        }
        order = order + 1;
      end

      args["condition" .. i .. tostring(path) .. "_type"] = {
        type = "select",
        width = normalWidth,
        name = blueIfNoValue(data, conditions[i].check, "type", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "type", currentConditionTemplate.type),
        order = order,
        values = {
          group = L["Group player(s) found"],
          enemies = L["Enemy nameplate(s) found"]
        },
        get = function()
          return check.type
        end,
        set = makeSetter("type"),
      }
      order = order + 1;

      args["condition" .. i .. tostring(path) .. "_op"] = {
        name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
        type = "select",
        order = order,
        values = OptionsPrivate.Private.operator_types,
        width = WeakAuras.halfWidth,
        get = function()
          return check.op;
        end,
        set = setOp,
      }
      order = order + 1;

      args["condition" .. i .. tostring(path) .. "_value"] = {
        type = "input",
        name = blueIfNoValue(data, conditions[i].check, "value", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type),
        width = WeakAuras.halfWidth,
        order = order,
        validate = WeakAuras.ValidateNumeric,
        get = function()
          return check.value;
        end,
        set = setValue
      }
      order = order + 1;
    elseif currentConditionTemplate.type == "customcheck" then
      args["condition" .. i .. tostring(path) .. "_op"] = {
        name = blueIfNoValue(data, conditions[i].check, "op", L["Additional Events"], L["Additional Events"]),
        desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type) or "",
        type = "input",
        width = WeakAuras.doubleWidth,
        order = order,
        get = function()
          return check and check.op;
        end,
        set = setOp
      }
      order = order + 1;

      args["condition" .. i .. tostring(path) .. "_value"] = {
        type = "input",
        width = WeakAuras.doubleWidth,
        name = blueIfNoValue(data, conditions[i].check, "value", L["Custom Check"], L["Custom Check"]),
        desc = descIfNoValue(data, conditions[i].check, "value", currentConditionTemplate.type) or "",
        order = order,
        get = function()
          return check and check.value;
        end,
        set = setValue,
        multiline = true,
        control = "WeakAurasMultiLineEditBox",
        arg = {
          extraFunctions = {
            {
              buttonLabel = L["Expand"],
              func = function()
                if (data.controlledChildren) then
                  -- Collect multi paths
                  local multipath = {};
                  for id in pairs(conditions[i].check.references) do
                    local conditionIndex = conditions[i].check.references[id].conditionIndex;
                    multipath[id] ={ "conditions", conditionIndex, "check" }
                    for _, v in ipairs(path) do
                      tinsert(multipath[id], "checks")
                      tinsert(multipath[id], v)
                    end
                    tinsert(multipath[id], "value")
                  end
                  OptionsPrivate.OpenTextEditor(data, multipath, nil, true, nil, nil, "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-check");
                else
                  local fullPath = { "conditions", i, "check" }
                  for _, v in ipairs(path) do
                    tinsert(fullPath, "checks")
                    tinsert(fullPath, v)
                  end
                  tinsert(fullPath, "value")

                  OptionsPrivate.OpenTextEditor(data, fullPath, nil, nil, nil, nil, "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-check");
                end
              end
            }
          }
        }
      }
      order = order + 1

      args["condition" .. i .. tostring(path) .. "_value_error"] = {
        type = "description",
        name = function()
          if (not check.value) then
            return ""
          end
          local _, errorString = loadstring("return " .. check.value);
          return errorString and "|cFFFF0000"..errorString or "";
        end,
        width = WeakAuras.doubleWidth,
        order = order,
        hidden = function()
          if (not check.value) then
            return true;
          end

          local loadedFunction, errorString = loadstring("return " .. check.value);
          if(errorString and not loadedFunction) then
            return false;
          else
            return true;
          end
        end
      }
      order = order + 1
    elseif (currentConditionTemplate.type == "combination") then
      -- Do nothing
    else
      order = addSpace(args, order);
    end
  else
    order = addSpace(args, order);
  end
  return order;
end

local function fixUpLinkedInFirstCondition(conditions)
  if conditions[1] and conditions[1].linked then
    conditions[1].linked = false
  end
end

local function addControlsForCondition(args, order, data, conditionVariable, totalAuraCount, conditions, i, conditionTemplates, conditionTemplateWithoutCombinations, allProperties)
  if (not conditions[i].check) then
    return order;
  end

  local defaultCollapsed = #conditions > 2
  local collapsed = false;
  if data.controlledChildren then
    for id, reference in pairs(conditions[i].check.references) do
      local index = reference.conditionIndex;
      if OptionsPrivate.IsCollapsed(id, "condition", index, defaultCollapsed) then
        collapsed = true;
        break;
      end
    end
  else
    collapsed = OptionsPrivate.IsCollapsed(data.id, "condition", i, defaultCollapsed);
  end

  args["condition" .. i .. "header"] = {
    type = "execute",
    name = L["Condition %i"]:format(i),
    order = order,
    width = WeakAuras.doubleWidth - 0.6,
    func = function()
      if data.controlledChildren then
        for id, reference in pairs(conditions[i].check.references) do
          local index = reference.conditionIndex
          OptionsPrivate.SetCollapsed(id, "condition", index, not collapsed);
          OptionsPrivate.ClearOptions(id)
        end
      else
        OptionsPrivate.SetCollapsed(data.id, "condition", i, not collapsed);
      end
      WeakAuras.ClearAndUpdateOptions(data.id)
    end,
    image = collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\expand" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\collapse" ,
    imageWidth = 18,
    imageHeight = 18,
    control = "WeakAurasExpand"
  };
  order = order + 1;

  args["condition" .. i .. "up"] = {
    type = "execute",
    name = L["Move Up"],
    order = order,
    disabled = function()
      if (data.controlledChildren) then
        for _, reference in pairs(conditions[i].check.references) do
          local index = reference.conditionIndex;
          if (index > 1) then
            return false;
          end
        end
        return true;
      else
        return i == 1;
      end
    end,
    func = function()
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          local index = reference.conditionIndex;
          if (index > 1) then
            local tmp = auraData[conditionVariable][reference.conditionIndex];
            tremove(auraData[conditionVariable], reference.conditionIndex);
            tinsert(auraData[conditionVariable], reference.conditionIndex - 1, tmp);
            fixUpLinkedInFirstCondition(auraData[conditionVariable])
            WeakAuras.Add(auraData);
            OptionsPrivate.MoveCollapseDataUp(auraData.id, "condition", {reference.conditionIndex})
            OptionsPrivate.ClearOptions(auraData.id)
          end
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
      else
        if (i > 1) then
          local tmp = conditions[i];
          tremove(conditions, i);
          tinsert(conditions, i - 1, tmp);
          fixUpLinkedInFirstCondition(conditions)
          WeakAuras.Add(data);
          OptionsPrivate.MoveCollapseDataUp(data.id, "condition", {i})
          WeakAuras.ClearAndUpdateOptions(data.id)
        end
      end
    end,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  };
  order = order + 1;

  args["condition" .. i .. "down"] = {
    type = "execute",
    name = L["Move Down"],
    order = order,
    disabled = function()
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local index = reference.conditionIndex;
          local auraData = WeakAuras.GetData(id);
          if (index < #auraData[conditionVariable]) then
            return false;
          end
        end
        return true;
      else
        return i == #conditions;
      end
    end,
    func = function()
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          local index = reference.conditionIndex;
          if (index < #auraData[conditionVariable]) then
            local tmp = auraData[conditionVariable][reference.conditionIndex];
            tremove(auraData[conditionVariable], reference.conditionIndex);
            tinsert(auraData[conditionVariable], reference.conditionIndex + 1, tmp);
            fixUpLinkedInFirstCondition(auraData[conditionVariable])
            WeakAuras.Add(auraData);
            OptionsPrivate.MoveCollapseDataDown(auraData.id, "condition", {reference.conditionIndex})
            OptionsPrivate.ClearOptions(auraData.id)
          end
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
        return;
      else
        if (i < #conditions) then
          local tmp = conditions[i];
          tremove(conditions, i);
          tinsert(conditions, i + 1, tmp);
          fixUpLinkedInFirstCondition(conditions)
          WeakAuras.Add(data);
          OptionsPrivate.MoveCollapseDataDown(data.id, "condition", {i})
          WeakAuras.ClearAndUpdateOptions(data.id)
          return;
        end
      end
    end,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  };
  order = order + 1;

  args["condition" .. i .. "duplicate"] = {
    type = "execute",
    name = L["Duplicate"],
    order = order,
    func = function()
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          local clone = CopyTable(auraData[conditionVariable][reference.conditionIndex])
          tinsert(auraData[conditionVariable], reference.conditionIndex + 1, clone);
          WeakAuras.Add(auraData);
          OptionsPrivate.DuplicateCollapseData(auraData.id, "condition", {reference.conditionIndex})
          OptionsPrivate.ClearOptions(auraData.id)
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
        return;
      else
        local clone = CopyTable(conditions[i])
        tinsert(conditions, i + 1, clone);
        WeakAuras.Add(data);
        OptionsPrivate.DuplicateCollapseData(data.id, "condition", {i})
        WeakAuras.ClearAndUpdateOptions(data.id)
        return;
      end
    end,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\duplicate",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  };
  order = order + 1;

  args["condition" .. i .. "delete"] = {
    type = "execute",
    name = L["Delete"],
    order = order,
    func = function()
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          tremove(auraData[conditionVariable], reference.conditionIndex);
          fixUpLinkedInFirstCondition(auraData[conditionVariable])
          WeakAuras.Add(auraData);
          OptionsPrivate.RemoveCollapsed(auraData.id, "condition", {reference.conditionIndex})
          OptionsPrivate.ClearOptions(auraData.id)
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
        return;
      else
        tremove(conditions, i);
        fixUpLinkedInFirstCondition(conditions)
        WeakAuras.Add(data);
        OptionsPrivate.RemoveCollapsed(data.id, "condition", {i})
        WeakAuras.ClearAndUpdateOptions(data.id)
        return;
      end
    end,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
    imageWidth = 24,
    imageHeight = 24,
    control = "WeakAurasIcon"
  };
  order = order + 1;

  if collapsed then
    return order;
  end

  order = addControlsForIfLine(args, order, data, conditionVariable, totalAuraCount, conditions, i, {}, conditionTemplates, conditionTemplateWithoutCombinations, allProperties);

  -- Add Property changes

  local usedProperties = {};
  for j = 1, conditions[i].changes and #conditions[i].changes or 0 do
    local property = conditions[i].changes[j].property;
    if (property) then
      usedProperties[property] = true;
    end
  end

  for j = 1, conditions[i].changes and #conditions[i].changes or 0 do
    order = addControlsForChange(args, order, data, conditionVariable, totalAuraCount, conditions, i, j, allProperties, usedProperties);
  end

  args["condition" .. i .. "_addChange"] = {
    type = "execute",
    width = WeakAuras.normalWidth,
    name = L["Add Property Change"],
    order = order,
    func = function()
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local auradata = WeakAuras.GetData(id);
          auradata[conditionVariable][reference.conditionIndex].changes = auradata[conditionVariable][reference.conditionIndex].changes or {}
          tinsert(auradata[conditionVariable][reference.conditionIndex].changes, {})
          WeakAuras.Add(auradata);
          OptionsPrivate.ClearOptions(auradata.id)
        end
        WeakAuras.ClearAndUpdateOptions(data.id)
      else
        conditions[i].changes = conditions[i].changes or {};
        conditions[i].changes[#conditions[i].changes + 1] = {};
        WeakAuras.Add(data);
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    end
  }
  order = order + 1;

  local showElseIf = false
  local isLinked = false

  if (data.controlledChildren) then
    for id, reference in pairs(conditions[i].check.references) do
      if reference.conditionIndex > 1 then
        local auradata = WeakAuras.GetData(id);
        isLinked = auradata[conditionVariable][reference.conditionIndex].linked
        showElseIf = true
        break;
      end
    end
  else
    if i > 1 then
      showElseIf = true
      isLinked = conditions[i].linked
    end
  end

  if showElseIf then
    args["condition" .. i .. "_else"] = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Else If"],
      order = order,
      get = function()
        return isLinked
      end,
      set = function()
        if (data.controlledChildren) then
          for id, reference in pairs(conditions[i].check.references) do
            local auradata = WeakAuras.GetData(id);
            if reference.conditionIndex > 1 then
              auradata[conditionVariable][reference.conditionIndex].linked = not isLinked
              WeakAuras.Add(auradata);
              OptionsPrivate.ClearOptions(auradata.id)
            end
          end
          WeakAuras.ClearAndUpdateOptions(data.id)
        else
          conditions[i].linked = not isLinked
          WeakAuras.Add(data);
          WeakAuras.ClearAndUpdateOptions(data.id)
        end
      end
    }
    order = order + 1;
  else
    order = addSpace(args, order)
  end

  return order;
end

local function mergeConditionTemplates(allConditionTemplates, auraConditionsTemplate, numTriggers)
  for triggernum = 1, numTriggers do
    local auraTemplatesForTrigger = auraConditionsTemplate[triggernum];
    if (auraTemplatesForTrigger) then
      allConditionTemplates[triggernum] = allConditionTemplates[triggernum] or {};
      for conditionName in pairs(auraTemplatesForTrigger) do
        if not allConditionTemplates[triggernum][conditionName] then
          allConditionTemplates[triggernum][conditionName] = CopyTable(auraTemplatesForTrigger[conditionName]);
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

local function createConditionTemplatesValueList(allConditionTemplates, numTriggers, excludeCombinations)
  local conditionTemplates = {};
  conditionTemplates.all = allConditionTemplates;
  conditionTemplates.indexToTrigger = {};
  conditionTemplates.indexToVariable = {};
  conditionTemplates.conditionToIndex = {};
  conditionTemplates.display = {};

  local index = 1;
  local startTriggernum = excludeCombinations and -1 or -2;
  for triggernum = startTriggernum, numTriggers do
    local templatesForTrigger = allConditionTemplates[triggernum];
    if triggernum ~= 0 then
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
          if (triggernum == -2) then
            -- Do Nothing
            conditionTemplates.display[index]  = string.format(L["Combinations"]);
          elseif (triggernum == -1) then
            conditionTemplates.display[index]  = string.format(L["Global Conditions"]);
          else
            conditionTemplates.display[index]  = string.format(L["Trigger %d"], triggernum);
          end
          index = index + 1;

          for _, conditionName in ipairs(sorted) do
            conditionTemplates.display[index] = "    " .. templatesForTrigger[conditionName].display;
            conditionTemplates.indexToTrigger[index] = triggernum;
            conditionTemplates.indexToVariable[index] = conditionName;
            conditionTemplates.conditionToIndex[triggernum .. "-" .. conditionName] = index;
            index = index + 1;
          end
        end
      end
    end
  end

  conditionTemplates.displayWithRemove = CopyTable(conditionTemplates.display);
  conditionTemplates.displayWithRemove[9997] = "•" .. L["Remove"] .. "•";
  conditionTemplates.indexToTrigger[9997] = "REMOVE";
  conditionTemplates.indexToVariable[9997] = "REMOVE";

  return conditionTemplates;
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
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      numTriggers = max(numTriggers, #child.triggers);

      local auraConditionsTemplate = OptionsPrivate.Private.GetTriggerConditions(child);
      mergeConditionTemplates(allConditionTemplates, auraConditionsTemplate, numTriggers)
    end
  else
    allConditionTemplates = OptionsPrivate.Private.GetTriggerConditions(data);
    numTriggers = #data.triggers;
  end

  allConditionTemplates[-2] = {
    ["AND"] = {
      display = L["All of"],
      type = "combination"
    },
    ["OR"] = {
      display = L["Any of"],
      type = "combination"
    }
  }
  allConditionTemplates[-1] = OptionsPrivate.Private.GetGlobalConditions();

  local conditionTemplates = createConditionTemplatesValueList(allConditionTemplates, numTriggers);

  if (data.controlledChildren) then
    conditionTemplates.displayWithCopy = CopyTable(conditionTemplates.display);

    conditionTemplates.displayWithCopy[9998] = "•" .. L["Copy to all auras"] .. "•";
    conditionTemplates.indexToTrigger[9998] = "COPY";
    conditionTemplates.indexToVariable[9998] = "COPY";
  end

  local conditionTemplateWithoutCombinations = createConditionTemplatesValueList(allConditionTemplates, numTriggers, true);

  return conditionTemplates, conditionTemplateWithoutCombinations;
end

local function buildAllPotentialProperties(data, category)
  local allProperties = {};
  allProperties.propertyMap = {};
  for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
    local regionProperties = OptionsPrivate.Private.GetProperties(child);

    if (regionProperties) then
      for k, v in pairs(regionProperties) do
        if (v.category == category) then
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
            allProperties.propertyMap[k] = CopyTable(v)
          end
        end
      end
    end
  end

  allProperties.indexToProperty = {};
  for k in pairs(allProperties.propertyMap) do
    tinsert(allProperties.indexToProperty, k);
  end
  table.sort(allProperties.indexToProperty, function(a, b)
    local av = allProperties.propertyMap[a].display
    av = type(av) == "table" and av[1] or av

    local bv = allProperties.propertyMap[b].display
    bv = type(bv) == "table" and bv[1] or bv
    return av < bv
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
    allProperties.displayWithCopy = CopyTable(allProperties.display);

    allProperties.displayWithCopy[9998] = "•" .. L["Copy to all auras"] .. "•";
    allProperties.indexToProperty[9998] = "COPY";
  end

  return allProperties;
end

local function compareSubChecks(a, b, allConditionTemplates)
  if (a == nil and b == nil) then
    return true;
  end
  if (a == nil or b == nil) then
    return false;
  end

  if (#a ~= #b) then
    return false;
  end

  local count = #a;

  for i = 1, count do
    if (a[i].trigger ~= b[i].trigger or a[i].variable ~= b[i].variable) then
      return false;
    end

    if (a[i].trigger == -2) then
      if (not compareSubChecks(a[i].checks, b[i].checks, allConditionTemplates)) then
        return false;
      end
    else
      local currentConditionTemplate = allConditionTemplates[a[i].trigger] and allConditionTemplates[a[i].trigger][a[i].variable];
      if (not currentConditionTemplate) then
        return true;
      end

      local type = currentConditionTemplate.type;
      if (type == "number" or type == "timer" or type == "elapsedTimer" or type == "select" or type == "string" or type == "customcheck") then
        if (a[i].op ~= b[i].op or a[i].value ~= b[i].value) then
          return false;
        end
      elseif (type == "bool") then
        if (a[i].value ~= b[i].value) then
          return false;
        end
      elseif (type == "alwaystrue") then
        return true
      end
    end
  end
  return true;
end

local function findMatchingCondition(all, needle, start, allConditionTemplates)
  while (true) do
    local condition = all[start];
    if (not condition) then
      return nil;
    end

    if (condition.check.trigger == needle.check.trigger and condition.check.variable == needle.check.variable
        and condition.linked == needle.linked) then
      if condition.check.variable == "customcheck" then
        -- Be a bit more strict for custom checks, there's little benefit in merging them
        if condition.check.op == needle.check.op and condition.check.value == needle.check.value then
          return start
        end
      elseif (condition.check.trigger == -2) then
        if (compareSubChecks(condition.check.checks, needle.check.checks, allConditionTemplates)) then
          return start;
        end
      else
        return start;
      end
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

local function SubPropertiesForChange(change)
  if change.property == "sound" then
    return { "sound", "sound_channel", "sound_path", "sound_kit_id", "sound_repeat", "sound_type"}
  elseif change.property == "customcode" then
    return { "custom" }
  elseif change.property == "glowexternal" then
    return {
      "glow_action", "glow_frame_type", "glow_type",
      "glow_frame", "choose_glow_frame",
      "use_glow_color", "glow_color",
      "glow_lines", "glow_frequency", "glow_length", "glow_thickness", "glow_XOffset", "glow_YOffset",
      "glow_scale", "glow_border"
    }
  elseif change.property == "chat" then
    local result = { "message_type", "message_dest", "message_channel", "message_color", "message", "custom", "message_voice" }
    local input = change.value and change.value.message
    if input then
      local getter = function(key)
        return change.value["message_format_" .. key]
      end
      OptionsPrivate.AddTextFormatOption(input, false, getter, function(key)
        tinsert(result, "message_format_" .. key)
      end, nil, nil, true)
    end
    return result
  end
end

local subPropertyToType = {
  glow_color = "color",
  message_color = "color"
}

local function mergeConditionChange(all, change, id, changeIndex, allProperties)
  local propertyType = all.property and allProperties.propertyMap[all.property] and allProperties.propertyMap[all.property].type
  if (propertyType == "chat" or propertyType == "sound" or propertyType == "customcode" or propertyType == "glowexternal") then
    if (type(all.value) ~= type(change.value)) then
      all.value = nil;
      all.samevalue = nil;
    else
      if (type(change.value) ~= "table") then
        if not compareValues(all.value, change.value, propertyType) then
          all.value = nil;
          all.samevalue = false;
        end
      else
        for _, propertyName in ipairs(SubPropertiesForChange(change)) do
          if all.samevalue[propertyName] == nil then
            -- NEW not yet seen property
            all.value[propertyName] = change.value[propertyName]
            all.samevalue[propertyName] = true
          elseif not compareValues(all.value[propertyName], change.value[propertyName], subPropertyToType[propertyName]) then
            all.value[propertyName] = nil;
            if all.samevalue then
              all.samevalue[propertyName] = false;
            end
          end
        end
      end
    end
  else
    if not compareValues(all.value, change.value, propertyType) then
      all.value = nil;
      all.samevalue = false;
    end
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
      local copy = CopyTable(change);

      local propertyType = change.property and allProperties.propertyMap[change.property] and allProperties.propertyMap[change.property].type;
      if (propertyType == "chat" or propertyType == "sound" or propertyType == "customcode" or propertyType == "glowexternal") then
        copy.samevalue = {};
        for _, propertyName in ipairs(SubPropertiesForChange(change)) do
          copy.samevalue[propertyName] = true;
        end
      else
        copy.samevalue = true;
      end
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

local function mergeConditions(all, aura, id, allConditionTemplates, propertyTypes)
  if (not aura) then
    return;
  end

  local currentInsertPoint = 1;
  for conditionIndex, condition in ipairs(aura) do
    local match = findMatchingCondition(all, condition, currentInsertPoint, allConditionTemplates);
    if (not match) then
      local copy = CopyTable(condition);
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
          local propertyType = change.property and propertyTypes.propertyMap[change.property] and propertyTypes.propertyMap[change.property].type;
          if (propertyType == "chat" or propertyType == "sound" or propertyType == "customcode" or propertyType == "glowexternal") then
            change.samevalue = {};
            for _, propertyName in ipairs(SubPropertiesForChange(change)) do
              change.samevalue[propertyName] = true;
            end
          else
            change.samevalue = true;
          end
          change.references = {};
          change.references[id] = {
            ["changeIndex"] = changeIndex,
            ["value"] = condition.changes[changeIndex].value
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

local fixupConditions = function(conditions)
  for _, condition in ipairs(conditions) do
    condition.check = condition.check or {}
    condition.changes = condition.changes or {}
  end
end

function OptionsPrivate.GetConditionOptions(data)
  local  options = {
    type = "group",
    name = L["Conditions"],
    order = 25,
    args = {}
  }

  local args = options.args

  local conditionVariable = "conditions"
  local startorder = 0
  local category = nil
  -- Build potential Conditions Templates structure
  local conditionTemplates, conditionTemplateWithoutCombinations = createConditionTemplates(data);

  -- Build potential properties structure
  local allProperties = buildAllPotentialProperties(data, category);

  -- Build currently selected conditions
  local conditions;
  local totalAuraCount

  if (data.controlledChildren) then
    local allChildren = {}
    for child in OptionsPrivate.Private.TraverseLeafs(data) do
      tinsert(allChildren, child)
    end
    totalAuraCount = #allChildren

    conditions = {};
    for index = totalAuraCount, 1, -1 do
      local child = allChildren[index]
      fixupConditions(child[conditionVariable])
      mergeConditions(conditions, child[conditionVariable], child.id, conditionTemplates.all, allProperties);
    end
  else
    totalAuraCount = 1
    data[conditionVariable] = data[conditionVariable] or {};
    conditions = data[conditionVariable];
    fixupConditions(data[conditionVariable])
  end

  local order = startorder;
  for i = 1, #conditions do
    order = addControlsForCondition(args, order, data, conditionVariable, totalAuraCount, conditions, i, conditionTemplates, conditionTemplateWithoutCombinations, allProperties);
  end

  args["addConditionHeader"] = {
    type = "header",
    width = WeakAuras.doubleWidth,
    name = "",
    order = order
  }
  order = order + 1

  args["addCondition"] = {
    type = "execute",
    width = WeakAuras.normalWidth,
    name = L["Add Condition"],
    order = order,
    func = function()
      for child in OptionsPrivate.Private.TraverseLeafsOrAura(data) do
        child[conditionVariable][#child[conditionVariable] + 1] = {};
        child[conditionVariable][#child[conditionVariable]].check = {};
        child[conditionVariable][#child[conditionVariable]].changes = {};
        child[conditionVariable][#child[conditionVariable]].changes[1] = {}
        child[conditionVariable][#child[conditionVariable]].category = category;
        OptionsPrivate.SetCollapsed(child.id, "condition", #child[conditionVariable], false);
        WeakAuras.Add(child);
        OptionsPrivate.ClearOptions(child.id)
      end
      WeakAuras.ClearAndUpdateOptions(data.id)
    end
  }
  order = order + 1;

  return options;
end
