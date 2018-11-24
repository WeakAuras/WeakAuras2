
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
--      - checks: Sub Checks for Combinations, each containg trigger, variable, op, value or checks
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


local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local debug = false;

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

local function addHalfSpace(args, order)
  args["space" .. order] = {
    type = "description",
    name = "",
    image = function() return "", 0, 0 end,
    order = order,
    width = WeakAuras.halfWidth
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

local function valueToString(a, propertytype, subtype)
  if (propertytype == "color") then
    if (type(a) == "table") then
      local r, g, b, a = floor((a[1] or 0) * 255), floor((a[2] or 0) * 255), floor((a[3] or 0) * 255), floor((a[4] or 0) * 255)
      return string.format("|c%02X%02X%02X%02X", a, r, g, b) .. L["color"];
    else
      return "";
    end
  elseif (propertytype == "chat" or propertytype == "sound" or propertytype == "customcode") then
    return tostring(a);
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

local function descIfNoValue2(data, object, variable, subvariable, type, values)
  if (data.controlledChildren) then
    local auraCount = #data.controlledChildren;
    if (object["same" .. variable] and object["same" .. variable][subvariable] == false) then
      local desc = "";
      for id, reference in pairs(object.references) do
        if (values) then
          desc = desc .."|cFFE0E000".. id .. ": |r" .. (values[reference[variable][subvariable]] or "") .. "\n";
        else
          desc = desc .."|cFFE0E000".. id .. ": |r" .. (valueToString(reference[variable][subvariable], type, subvariable) or "") .. "\n";
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
      PlaySound(tonumber(v), "Master");
    else
      PlaySoundFile(v, "Master");
    end
  end
end

local function addControlsForChange(args, order, data, conditionVariable, conditions, i, j, allProperties, usedProperties)
  local thenText = (j == 1) and L["Then "] or L["And "];
  local display = isSubset(data, conditions[i].changes[j]) and allProperties.displayWithCopy or allProperties.display;
  local valuesForProperty = filterUsedProperties(allProperties.indexToProperty, display, usedProperties, conditions[i].changes[j].property);
  args["condition" .. i .. "property" .. j] = {
    type = "select",
    width = WeakAuras.normalWidth,
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
            tinsert(auraData[conditionVariable][conditionIndex].changes, insertPoint, change);
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
            tremove(auraData[conditionVariable][conditionIndex].changes, reference.changeIndex);
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

      local default = allProperties.propertyMap[property].default;
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].changes[j].references) do
          local auraData = WeakAuras.GetData(id);
          local conditionIndex = conditions[i].check.references[id].conditionIndex;
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].property = property;
          auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value = default;
          WeakAuras.Add(auraData);
        end
        conditions[i].changes[j].property = property;
        WeakAuras.ReloadTriggerOptions(data);
      else
        conditions[i].changes[j].property = property;
        conditions[i].changes[j].value = default;
        WeakAuras.Add(data);
        WeakAuras.ReloadTriggerOptions(data);
      end
    end
  }
  order = order + 1;

  local setValue;
  local setValueColor;
  local setValueComplex;
  if (data.controlledChildren) then
    setValue = function(info, v)
      for id, reference in pairs(conditions[i].changes[j].references) do
        local auraData = WeakAuras.GetData(id);
        local conditionIndex = conditions[i].check.references[id].conditionIndex;
        auraData[conditionVariable][conditionIndex].changes[reference.changeIndex].value = v;
        WeakAuras.Add(auraData);
      end
      conditions[i].changes[j].value = v;
      WeakAuras.ReloadTriggerOptions(data);
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
      end
      conditions[i].changes[j].value = conditions[i].changes[j].value or {};
      conditions[i].changes[j].value[1] = r;
      conditions[i].changes[j].value[2] = g;
      conditions[i].changes[j].value[3] = b;
      conditions[i].changes[j].value[4] = a;
      WeakAuras.ReloadTriggerOptions(data);
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
        end
        if (type(conditions[i].changes[j].value) ~= "table") then
          conditions[i].changes[j].value = {};
        end
        conditions[i].changes[j].value[property] = v;
        WeakAuras.ReloadTriggerOptions(data);
      end
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

    setValueComplex = function(property)
      return function(info, v)
        if (type (conditions[i].changes[j].value) ~= "table") then
          conditions[i].changes[j].value = {};
        end
        conditions[i].changes[j].value[property] = v;
        WeakAuras.Add(data);
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
      values = WeakAuras.sound_condition_types,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound_type", L["Differences"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound_type", propertyType, WeakAuras.sound_condition_types),
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
      values = WeakAuras.sound_types,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound", L["Differences"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound", propertyType, WeakAuras.sound_types),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.sound;
      end,
      set = wrapWithPlaySound(setValueComplex("sound")),
      control = "WeakAurasSortedDropdown",
      hidden = function() return not (anySoundType("Play") or anySoundType("Loop")) end
    }
    order = order + 1;

    args["condition" .. i .. "value" .. j .. "sound_channel"] = {
      type = "select",
      width = WeakAuras.normalWidth,
      values = WeakAuras.sound_channel_types,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "sound_channel", L["Sound Channel"], L["Sound Channel"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "sound_channel", propertyType, WeakAuras.sound_channel_types),
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
      values = WeakAuras.send_chat_message_types,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_type", L["Differences"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "message_type", propertyType, WeakAuras.send_chat_message_types),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message_type;
      end,
      set = setValueComplex("message_type"),
      control = "WeakAurasSortedDropdown"
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

    args["condition" .. i .. "value" .. j .. "message dest"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_dest", L["Send To"], L["Send To"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "message_dest", propertyType),
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

    args["condition" .. i .. "value" .. j .. "message channel"] = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message_channel", L["Channel Number"], L["Channel Number"]),
      desc = descIfNoValue2(data, conditions[i].changes[j], "value", "message_channel", propertyType),
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message_channel;
      end,
      set = setValueComplex("message_channel"),
      hidden = function()
        return not anyMessageType("CHANNEL");
      end
    }
    order = order + 1;

    local descMessage = descIfNoValue2(data, conditions[i].changes[j], "value", "message", propertyType);
    if (not descMessage and data ~= WeakAuras.tempGroup) then
      local additionalProperties = WeakAuras.GetAdditionalProperties(data);
      if (additionalProperties) then
        descMessage = L["Dynamic text tooltip"] .. additionalProperties;
      end
    end

    args["condition" .. i .. "value" .. j .. "message"] = {
      type = "input",
      width = WeakAuras.doubleWidth,
      name = blueIfNoValue2(data, conditions[i].changes[j], "value", "message", L["Message"], L["Message"]),
      desc = descMessage,
      order = order,
      get = function()
        return type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message;
      end,
      set = setValueComplex("message")
    }
    order = order + 1;

    local function customHidden()
      local message = type(conditions[i].changes[j].value) == "table" and conditions[i].changes[j].value.message;
      if (not message) then return true; end
      return not WeakAuras.ContainsPlaceHolders(message, "c");
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
                WeakAuras.OpenTextEditor(data, multipath, nil, true);
              else
                WeakAuras.OpenTextEditor(data, {"conditions", i, "changes", j, "value", "custom"});
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
        if (not WeakAuras.ContainsPlaceHolders(message, "c")) then
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
                WeakAuras.OpenTextEditor(data, multipath, true, true);
              else
                data.conditions[i].changes[j].value = data.conditions[i].changes[j].value or {};
                WeakAuras.OpenTextEditor(data, {"conditions", i, "changes", j, "value", "custom"}, true);
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

local function addControlsForIfLine(args, order, data, conditionVariable, conditions, i, path, conditionTemplates, conditionTemplateWithoutCombinations, allProperties, parentType)
  local check = getSubCheck(conditions[i].check, path);

  local indentDepth = min(#path, 3); -- Be reasonable
  local indentWidth = (indentDepth > 0 and 0.02 or 0) + indentDepth * 0.03;
  local normalWidth = WeakAuras.normalWidth - indentWidth;

  local conditionTemplatesToUse = indentDepth < 3 and conditionTemplates or conditionTemplateWithoutCombinations;

  local optionsName = blueIfSubset(data, conditions[i].check);
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
    if (needsTriggerName) then
      optionsName = optionsName .. string.format(L["If Trigger %s"], check.trigger);
    else
      optionsName = optionsName .. L["If"];
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
    valuesForIf = isSubset(data, conditions[i].check) and conditionTemplatesToUse.displayWithCopy or conditionTemplatesToUse.display;
  end

  args["condition" .. i .. tostring(path) .. "if"] = {
    type = "select",
    name = optionsName,
    desc = descIfSubset(data, conditions[i].check),
    order = order,
    values = valuesForIf,
    width = normalWidth;
    set = function(info, v)
      if (conditionTemplatesToUse.indexToTrigger[v] == "COPY") then
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
                  copy.value = {};
                  WeakAuras.DeepCopy(change.value, copy.value);
                else
                  copy.value = change.value;
                end
                tinsert(condition.changes, copy);
              end
            end

            local auraData = WeakAuras.GetData(id);
            tinsert(auraData[conditionVariable], insertPoint, condition);
            WeakAuras.Add(auraData);
          end
        end
        WeakAuras.ReloadTriggerOptions(data);
        return;
      end

      if (conditionTemplatesToUse.indexToTrigger[v] == "REMOVE") then
        if (data.controlledChildren) then
          for id, reference in pairs(conditions[i].check.references) do
            local auraData = WeakAuras.GetData(id);
            removeSubCheck(auraData[conditionVariable][reference.conditionIndex].check, path);
          end
        else
          removeSubCheck(conditions[i].check, path);
        end
        WeakAuras.ReloadTriggerOptions(data);
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
        end
        WeakAuras.ReloadTriggerOptions(data);
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
        WeakAuras.ReloadTriggerOptions(data);
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
      order = addControlsForIfLine(args, order, data, conditionVariable, conditions, i, subPath, conditionTemplates, conditionTemplateWithoutCombinations, allProperties, check.variable);
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
    local setOp;
    local setValue;
    if (data.controlledChildren) then
      setOp = function(info, v)
        check = getOrCreateSubCheck(conditions[i].check, path);
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          local childCheck = getOrCreateSubCheck(auraData[conditionVariable][reference.conditionIndex].check, path);
          childCheck.op = v;
          WeakAuras.Add(auraData);
        end
        check.op = v;
        WeakAuras.ReloadTriggerOptions(data);
      end
      setValue = function(info, v)
        check = getOrCreateSubCheck(conditions[i].check, path);
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          local childCheck = getOrCreateSubCheck(auraData[conditionVariable][reference.conditionIndex].check, path);
          childCheck.value = v;
          WeakAuras.Add(auraData);
        end
        check.value = v;
        WeakAuras.ReloadTriggerOptions(data);
      end
    else
      setOp = function(info, v)
        check = getOrCreateSubCheck(conditions[i].check, path);
        check.op = v;
        WeakAuras.Add(data);
      end
      setValue = function(info, v)
        check = getOrCreateSubCheck(conditions[i].check, path);
        check.value = v;
        WeakAuras.Add(data);
      end
    end

    if (currentConditionTemplate.type == "number" or currentConditionTemplate.type == "timer") then
      args["condition" .. i .. tostring(path) .. "_op"] = {
        name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
        type = "select",
        order = order,
        values = currentConditionTemplate.operator_types_without_equal and WeakAuras.operator_types_without_equal or  WeakAuras.operator_types,
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
          values = WeakAuras.equality_operator_types,
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
              return not check.value and "player" or currentConditionTemplate.values[check.value] and check.value or "member"
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
        values = WeakAuras.bool_types,
        get = function()
          return check and check.value;
        end,
        set = setValue
      }
      order = order + 1;
    elseif (currentConditionTemplate.type == "string") then
      args["condition" .. i .. tostring(path) .. "_op"] = {
        name = blueIfNoValue(data, conditions[i].check, "op", L["Differences"]),
        desc = descIfNoValue(data, conditions[i].check, "op", currentConditionTemplate.type),
        type = "select",
        width = WeakAuras.normalWidth,
        order = order,
        values = WeakAuras.string_operator_types,
        get = function()
          return check and check.op;
        end,
        set = setOp
      }
      order = order + 1;

      order = addSpace(args, order);

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

local function addControlsForCondition(args, order, data, conditionVariable, conditions, i, conditionTemplates, conditionTemplateWithoutCombinations, allProperties)
  if (not conditions[i].check) then
    return;
  end

  args["condition" .. i .. "header"] = {
    type = "description",
    name = L["Condition %i"]:format(i),
    order = order,
    width = WeakAuras.doubleWidth - 0.45,
    fontSize = "large"
  };
  order = order + 1;

  args["condition" .. i .. "up"] = {
    type = "execute",
    name = "",
    order = order,
    disabled = function()
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
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
            WeakAuras.Add(auraData);
          end
        end
        WeakAuras.ReloadTriggerOptions(data);
      else
        if (i > 1) then
          local tmp = conditions[i];
          tremove(conditions, i);
          tinsert(conditions, i - 1, tmp);
          WeakAuras.Add(data);
          WeakAuras.ReloadTriggerOptions(data);
        end
      end
    end,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\moveup",
    imageWidth = 24,
    imageHeight = 24
  };
  order = order + 1;

  args["condition" .. i .. "down"] = {
    type = "execute",
    name = "",
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
            WeakAuras.Add(auraData);
          end
        end
        WeakAuras.ReloadTriggerOptions(data);
        return;
      else
        if (i < #conditions) then
          local tmp = conditions[i];
          tremove(conditions, i);
          tinsert(conditions, i + 1, tmp);
          WeakAuras.Add(data);
          WeakAuras.ReloadTriggerOptions(data);
          return;
        end
      end
    end,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\movedown",
    imageWidth = 24,
    imageHeight = 24
  };
  order = order + 1;

  args["condition" .. i .. "delete"] = {
    type = "execute",
    name = "",
    order = order,
    func = function()
      if (data.controlledChildren) then
        for id, reference in pairs(conditions[i].check.references) do
          local auraData = WeakAuras.GetData(id);
          tremove(auraData[conditionVariable], reference.conditionIndex);
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
    end,
    width = 0.15,
    image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
    imageWidth = 24,
    imageHeight = 24
  };
  order = order + 1;

  order = addControlsForIfLine(args, order, data, conditionVariable, conditions, i, {}, conditionTemplates, conditionTemplateWithoutCombinations, allProperties);

  -- Add Property changes

  local usedProperties = {};
  for j = 1, conditions[i].changes and #conditions[i].changes or 0 do
    local property = conditions[i].changes[j].property;
    if (property) then
      usedProperties[property] = true;
    end
  end

  for j = 1, conditions[i].changes and #conditions[i].changes or 0 do
    order = addControlsForChange(args, order, data, conditionVariable, conditions, i, j, allProperties, usedProperties);
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
  for triggernum = 1, numTriggers do
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
            conditionTemplates.display[index]  = WeakAuras.newFeatureString .. string.format(L["Combinations"]);
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
    for _, id in ipairs(data.controlledChildren) do
      local data = WeakAuras.GetData(id);
      numTriggers = max(numTriggers, #data.triggers);

      local auraConditionsTemplate = WeakAuras.GetTriggerConditions(data);
      mergeConditionTemplates(allConditionTemplates, auraConditionsTemplate, numTriggers)
    end
  else
    allConditionTemplates = WeakAuras.GetTriggerConditions(data);
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
  allConditionTemplates[-1] = WeakAuras.GetGlobalConditions();

  local conditionTemplates = createConditionTemplatesValueList(allConditionTemplates, numTriggers);

  if (data.controlledChildren) then
    conditionTemplates.displayWithCopy = {};
    WeakAuras.DeepCopy(conditionTemplates.display, conditionTemplates.displayWithCopy);

    conditionTemplates.displayWithCopy[9998] = "•" .. L["Copy to all auras"] .. "•";
    conditionTemplates.indexToTrigger[9998] = "COPY";
    conditionTemplates.indexToVariable[9998] = "COPY";
  end

  local conditionTemplateWithoutCombinations = createConditionTemplatesValueList(allConditionTemplates, numTriggers, true);

  return conditionTemplates, conditionTemplateWithoutCombinations;
end

local function buildAllPotentialProperies(data, category)
  local allProperties = {};
  allProperties.propertyMap = {};
  if (data.controlledChildren) then
    for _, id in ipairs(data.controlledChildren) do
      local auradata = WeakAuras.GetData(id);
      local regionProperties = WeakAuras.GetProperties(auradata);
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
              allProperties.propertyMap[k] = {};
              WeakAuras.DeepCopy(v, allProperties.propertyMap[k])
            end
          end
        end
      end
    end
  else
    local regionProperties = WeakAuras.GetProperties(data);
    if (regionProperties) then
      for k, v in pairs(regionProperties) do
        if (v.category == category) then
          allProperties.propertyMap[k] = v;
        end
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
      if (type == "number" or type == "timer" or type == "select" or type == "string") then
        if (a[i].op ~= b[i].op or a[i].value ~= b[i].value) then
          return false;
        end
      elseif (type == "bool") then
        if (a[i].value ~= b[i].value) then
          return false;
        end
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

    if (condition.check.trigger == needle.check.trigger and condition.check.variable == needle.check.variable) then
      if (condition.check.trigger == -2) then
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

local propertyTypeToSubProperty = {
  chat = { "message_type", "message_dest", "message_channel", "message", "custom" },
  sound = { "sound", "sound_channel", "sound_path", "sound_kit_id", "sound_repeat", "sound_type"},
  customcode = { "custom" }
};

local function mergeConditionChange(all, change, id, changeIndex, allProperties)
  local propertyType = all.property and allProperties.propertyMap[all.property] and allProperties.propertyMap[all.property].type
  if (propertyType == "chat" or propertyType == "sound" or propertyType == "customcode") then
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
        for _, propertyName in ipairs(propertyTypeToSubProperty[propertyType]) do
          if (all.value[propertyName] ~= change.value[propertyName]) then
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
      local copy = {};
      WeakAuras.DeepCopy(change, copy);

      local propertyType = change.property and allProperties.propertyMap[change.property] and allProperties.propertyMap[change.property].type;
      if (propertyType == "chat" or propertyType == "sound" or propertyType == "customcode") then
        copy.samevalue = {};
        for _, propertyName in ipairs(propertyTypeToSubProperty[propertyType]) do
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
          local propertyType = change.property and propertyTypes.propertyMap[change.property] and propertyTypes.propertyMap[change.property].type;
          if (propertyType == "chat" or propertyType == "sound" or propertyType == "customcode") then
            change.samevalue = {};
            for _, propertyName in ipairs(propertyTypeToSubProperty[propertyType]) do
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

function WeakAuras.GetConditionOptions(data, args, conditionVariable, startorder, category)
  -- Build potential Conditions Templates structure
  local conditionTemplates, conditionTemplateWithoutCombinations = createConditionTemplates(data);

  -- Build potential properties structure
  local allProperties = buildAllPotentialProperies(data, category);

  -- Build currently selected conditions
  local conditions;
  if (data.controlledChildren) then
    conditions = {};
    local last = #data.controlledChildren;
    for index = last, 1, -1 do
      local id = data.controlledChildren[index];
      local data = WeakAuras.GetData(id);
      mergeConditions(conditions, data[conditionVariable], data.id, conditionTemplates.all, allProperties);
    end
  else
    data[conditionVariable] = data[conditionVariable] or {};
    conditions = data[conditionVariable];
  end

  local order = startorder;
  for i = 1, #conditions do
    order = addControlsForCondition(args, order, data, conditionVariable, conditions, i, conditionTemplates, conditionTemplateWithoutCombinations, allProperties);
  end

  args["addCondition"] = {
    type = "execute",
    width = WeakAuras.normalWidth,
    name = L["Add Condition"],
    order = order,
    func = function()
      if (data.controlledChildren) then
        for _, id in ipairs(data.controlledChildren) do
          local aura = WeakAuras.GetData(id);
          aura[conditionVariable][#aura[conditionVariable] + 1] = {};
          aura[conditionVariable][#aura[conditionVariable]].check = {};
          aura[conditionVariable][#aura[conditionVariable]].changes = {};
          aura[conditionVariable][#aura[conditionVariable]].changes[1] = {}
          aura[conditionVariable][#aura[conditionVariable]].category = category;
          WeakAuras.Add(aura);
        end
        WeakAuras.ReloadTriggerOptions(data);
      else
        conditions[#conditions + 1] = {};
        conditions[#conditions].check = {};
        conditions[#conditions].changes = {};
        conditions[#conditions].changes[1] = {}
        conditions[#conditions].category = category;
        WeakAuras.Add(data);
        WeakAuras.ReloadTriggerOptions(data);
      end
    end
  }
  order = order + 1;

  return args;
end
