if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local L = WeakAuras.L
local timer = WeakAuras.timer

-- Dynamic Condition functions to run. keyed on event and uid
local dynamicConditions = {};

-- Global Dynamic Condition Funcs, keyed on the event
local globalDynamicConditionFuncs = {};

-- Check Conditions Functions, keyed on uid
local checkConditions = {};

local conditionChecksTimers = {};
conditionChecksTimers.recheckTime = {};
conditionChecksTimers.recheckHandle = {};

local function OnDelete(_, uid)
  checkConditions[uid] = nil
  conditionChecksTimers.recheckTime[uid] = nil
  if (conditionChecksTimers.recheckHandle[uid]) then
    for cloneId, v in pairs(conditionChecksTimers.recheckHandle[uid]) do
      timer:CancelTimer(v)
    end
  end
  conditionChecksTimers.recheckHandle[uid] = nil

  for _, funcs in pairs(dynamicConditions) do
    funcs[uid] = nil
  end
end

Private.callbacks:RegisterCallback("Delete", OnDelete)

local function formatValueForAssignment(vType, value, pathToCustomFunction, pathToFormatters)
  if (value == nil) then
    value = false;
  end
  if (vType == "bool") then
    return value and tostring(value) or "false";
  elseif(vType == "number") then
    return value and tostring(value) or "0";
  elseif (vType == "list") then
    if type(value) == "string" then
      return string.format("%s", Private.QuotedString(value))
    elseif type(value) == "number" then
      return tostring(value)
    end
    return "nil"
  elseif (vType == "icon") then
    if type(value) == "string" then
      return string.format("%s", Private.QuotedString(value))
    elseif type(value) == "number" then
      return tostring(value)
    end
    return "nil"
  elseif(vType == "color") then
    if (value and type(value) == "table") then
      return string.format("{%s, %s, %s, %s}", tostring(value[1]), tostring(value[2]), tostring(value[3]), tostring(value[4]));
    end
    return "{1, 1, 1, 1}";
  elseif(vType == "chat") then
    if (value and type(value) == "table") then
      local serialized = string.format("{message_type = %s, message = %s, message_dest = %s, message_dest_isunit = %s, r = %s, g = %s, b = %s, message_custom = %s, message_formaters = %s, message_voice = %s}",
        Private.QuotedString(tostring(value.message_type)), Private.QuotedString(tostring(value.message or "")),
        Private.QuotedString(tostring(value.message_dest)),
        tostring(value.message_dest_isunit),
        type(value.message_color) == "table" and tostring(value.message_color[1] or "1") or "1",
        type(value.message_color) == "table" and tostring(value.message_color[2] or "1") or "1",
        type(value.message_color) == "table" and tostring(value.message_color[3] or "1") or "1",
        pathToCustomFunction,
        pathToFormatters,
        tostring(value.message_voice))
      return serialized
    end
  elseif(vType == "sound") then
    if (value and type(value) == "table") then
      return string.format("{ sound = %s, sound_channel = %s, sound_path = %s, sound_kit_id = %s, sound_type = %s, %s}",
        Private.QuotedString(tostring(value.sound or "")), Private.QuotedString(tostring(value.sound_channel or "")),
        Private.QuotedString(tostring(value.sound_path or "")), Private.QuotedString(tostring(value.sound_kit_id or "")),
        Private.QuotedString(tostring(value.sound_type or "")),
        value.sound_repeat and "sound_repeat = " .. tostring(value.sound_repeat) or "nil");
    end
  elseif(vType == "customcode") then
    return string.format("%s", pathToCustomFunction);
  elseif vType == "glowexternal" then
    if (value and type(value) == "table") then
      return ([[{ glow_action = %q, glow_frame_type = %q, glow_type = %q,
      glow_frame = %q, use_glow_color = %s, glow_color = {%s, %s, %s, %s},
      glow_lines = %d, glow_frequency = %f, glow_length = %f, glow_thickness = %f, glow_XOffset = %f, glow_YOffset = %f,
      glow_scale = %f, glow_border = %s }]]):format(
        value.glow_action or "",
        value.glow_frame_type or "",
        value.glow_type or "",
        value.glow_frame or "",
        value.use_glow_color and "true" or "false",
        type(value.glow_color) == "table" and tostring(value.glow_color[1]) or "1",
        type(value.glow_color) == "table" and tostring(value.glow_color[2]) or "1",
        type(value.glow_color) == "table" and tostring(value.glow_color[3]) or "1",
        type(value.glow_color) == "table" and tostring(value.glow_color[4]) or "1",
        value.glow_lines or 8,
        value.glow_frequency or 0.25,
        value.glow_length or 10,
        value.glow_thickness or 1,
        value.glow_XOffset or 0,
        value.glow_YOffset or 0,
        value.glow_scale or 1,
        value.glow_border and "true" or "false"
      )
    end
  end
  return "nil";
end

local function formatValueForCall(type, property)
  if (type == "bool" or type == "number" or type == "list" or type == "icon") then
    return "propertyChanges['" .. property .. "']";
  elseif (type == "color") then
    local pcp = "propertyChanges['" .. property .. "']";
    return pcp  .. "[1], " .. pcp .. "[2], " .. pcp  .. "[3], " .. pcp  .. "[4]";
  end
  return "nil";
end



function Private.ExecEnv.ScheduleConditionCheck(time, uid, cloneId)
  conditionChecksTimers.recheckTime[uid] = conditionChecksTimers.recheckTime[uid] or {}
  conditionChecksTimers.recheckHandle[uid] = conditionChecksTimers.recheckHandle[uid] or {};

  if (conditionChecksTimers.recheckTime[uid][cloneId] and conditionChecksTimers.recheckTime[uid][cloneId] > time) then
    timer:CancelTimer(conditionChecksTimers.recheckHandle[uid][cloneId]);
    conditionChecksTimers.recheckHandle[uid][cloneId] = nil;
  end

  if (conditionChecksTimers.recheckHandle[uid][cloneId] == nil) then
    conditionChecksTimers.recheckHandle[uid][cloneId] = timer:ScheduleTimerFixed(function()
      conditionChecksTimers.recheckHandle[uid][cloneId] = nil;
      local region = Private.GetRegionByUID(uid, cloneId)
      if (region and region.toShow) then
        Private.ActivateAuraEnvironmentForRegion(region)
        checkConditions[uid](region);
        Private.ActivateAuraEnvironment()
      end
    end, time - GetTime())
    conditionChecksTimers.recheckTime[uid][cloneId] = time;
  end
end

function Private.ExecEnv.CallCustomConditionTest(uid, testFunctionNumber, ...)
  local ok, result = xpcall(Private.ExecEnv.conditionHelpers[uid].customTestFunctions[testFunctionNumber],
                            Private.GetErrorHandlerUid(uid, L["Condition Custom Text"]), ...)
  if (ok) then
    return result
  end
end

local function CreateTestForCondition(uid, input, allConditionsTemplate, usedStates)
  local trigger = input and input.trigger;
  local variable = input and input.variable;
  local op = input and input.op;
  local value = input and input.value;

  local check = nil;
  local recheckCode = nil;

  if (variable == "AND" or variable == "OR") then
    local test = {};
    if (input.checks) then
      for i, subcheck in ipairs(input.checks) do
        local subtest, subrecheckCode = CreateTestForCondition(uid, subcheck, allConditionsTemplate, usedStates);
        if (subtest) then
          tinsert(test, "(" .. subtest .. ")");
        end
        if (subrecheckCode) then
          recheckCode = recheckCode or "";
          recheckCode = recheckCode .. subrecheckCode;
        end
      end
    end
    if (next(test)) then
      if (variable == "AND") then
        check = table.concat(test, " and ");
      else
        check = table.concat(test, " or ");
      end
    end
  end

  if (trigger and variable) then
    usedStates[trigger] = true;

    local conditionTemplate = allConditionsTemplate[trigger] and allConditionsTemplate[trigger][variable];
    local cType = conditionTemplate and conditionTemplate.type;
    local useModRate = conditionTemplate and conditionTemplate.useModRate
    local test = conditionTemplate and conditionTemplate.test;
    local preamble = conditionTemplate and conditionTemplate.preamble;

    local stateCheck = "state[" .. trigger .. "] and state[" .. trigger .. "].show and ";
    local stateVariableCheck = string.format("state[" .. trigger .. "][%q]", variable) .. "~= nil and ";

    local preambleString

    if preamble then
      Private.ExecEnv.conditionHelpers[uid] = Private.ExecEnv.conditionHelpers[uid] or {}
      Private.ExecEnv.conditionHelpers[uid].preambles = Private.ExecEnv.conditionHelpers[uid].preambles or {}
      tinsert(Private.ExecEnv.conditionHelpers[uid].preambles, preamble(value) or "");
      local preambleNumber = #Private.ExecEnv.conditionHelpers[uid].preambles
      preambleString = string.format("Private.ExecEnv.conditionHelpers[%q].preambles[%s]", uid, preambleNumber)
    end

    if (test) then
      if (value) then
        Private.ExecEnv.conditionHelpers[uid] = Private.ExecEnv.conditionHelpers[uid] or {}
        Private.ExecEnv.conditionHelpers[uid].customTestFunctions = Private.ExecEnv.conditionHelpers[uid].customTestFunctions or {}
        tinsert(Private.ExecEnv.conditionHelpers[uid].customTestFunctions, test);
        local testFunctionNumber = #(Private.ExecEnv.conditionHelpers[uid].customTestFunctions);
        local valueString = type(value) == "string" and string.format("%q", value) or value;
        local opString = type(op) == "string" and string.format("%q", op) or op;
        check = string.format("state and Private.ExecEnv.CallCustomConditionTest(%q, %s, state[%s], %s, %s, %s)",
                              uid, testFunctionNumber, trigger, valueString, (opString or "nil"), preambleString or "nil");
      end
    elseif (cType == "customcheck") then
      if value then
        local customCheck = WeakAuras.LoadFunction("return " .. value)
        if customCheck then
          Private.ExecEnv.conditionHelpers[uid] = Private.ExecEnv.conditionHelpers[uid] or {}
          Private.ExecEnv.conditionHelpers[uid].customTestFunctions = Private.ExecEnv.conditionHelpers[uid].customTestFunctions or {}
          tinsert(Private.ExecEnv.conditionHelpers[uid].customTestFunctions, customCheck);
          local testFunctionNumber = #(Private.ExecEnv.conditionHelpers[uid].customTestFunctions);

          check = string.format("state and Private.ExecEnv.CallCustomConditionTest(%q, %s, state)",
                                uid, testFunctionNumber, trigger);
        end
      end
    elseif cType == "alwaystrue" then
      check = "true"
    elseif (cType == "number" and value and op) then
      local v = tonumber(value)

      if (v) then
        if useModRate then
          check = stateCheck .. stateVariableCheck .. "(state[" .. trigger .. "]" .. string.format("[%q]", variable)
                  .. "/ (state[" .. trigger .. "].modRate or 1.0))" .. op .. v;
        else
          check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]" .. string.format("[%q]", variable) .. op .. v;
        end
      end
    elseif (cType == "timer" and value and op) then
      if useModRate then
        if (op == "==") then
          check = stateCheck .. stateVariableCheck .. "abs(((state[" .. trigger .. "]" .. string.format("[%q]", variable) .. "- now) "
                 .. "/ (state[" .. trigger .. "].modRate or 1.0))" .. " -" .. value .. ") < 0.05";
        else
          check = stateCheck .. stateVariableCheck .. "((state[" .. trigger .. "]" .. string.format("[%q]", variable)
                  .. "- now) / (state[" .. trigger .. "].modRate or 1.0))" .. op .. value;
        end
      else
        if (op == "==") then
          check = stateCheck .. stateVariableCheck .. "abs(state[" .. trigger .. "]" .. string.format("[%q]", variable) .. "- now -" .. value .. ") < 0.05";
        else
          check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]" .. string.format("[%q]", variable) .. "- now" .. op .. value;
        end
      end
    elseif (cType == "elapsedTimer" and value and op) then
      if (op == "==") then
        check = stateCheck .. stateVariableCheck .. "abs(state[" .. trigger .. "]" .. string.format("[%q]", variable) .. "- now +" .. value .. ") < 0.05";
      else
        check = stateCheck .. stateVariableCheck .. "now - state[" .. trigger .. "]" .. string.format("[%q]", variable) .. op .. value;
      end
    elseif (cType == "select" and value and op) then
      if (tonumber(value)) then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]" .. string.format("[%q]", variable) .. op .. tonumber(value);
      else
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]".. string.format("[%q]", variable) .. op .. "'" .. value .. "'";
      end
    elseif (cType == "range" and value and op and input.type and input.op_range and input.range) then
      local fn
      if input.type == "group" then
        fn = [[
          return function()
            local found = 0
            local op = %q
            local range = %s
            for unit in WA_IterateGroupMembers() do
              if not UnitIsUnit(unit, "player") and WeakAuras.CheckRange(unit, range, op) then
                found = found + 1
              end
            end
            return found %s %d
          end
        ]]
        fn = fn:format(input.op_range, input.range, op, value)
      elseif input.type == "enemies" then
        fn = [[
          return function()
            local found = 0
            local op = %q
            local range = %s
            for i = 1, 40 do
              local unit = "nameplate" .. i
              if UnitExists(unit) and UnitCanAttack("player", unit) and WeakAuras.CheckRange(unit, range, op) then
                found = found + 1
              end
            end
            return found %s %d
          end
        ]]
        fn = fn:format(input.op_range, input.range, op, value)
      end
      if fn then
        local customCheck = WeakAuras.LoadFunction(fn)
        if customCheck then
          Private.ExecEnv.conditionHelpers[uid] = Private.ExecEnv.conditionHelpers[uid] or {}
          Private.ExecEnv.conditionHelpers[uid].customTestFunctions = Private.ExecEnv.conditionHelpers[uid].customTestFunctions or {}
          tinsert(Private.ExecEnv.conditionHelpers[uid].customTestFunctions, customCheck);
          local testFunctionNumber = #(Private.ExecEnv.conditionHelpers[uid].customTestFunctions);

          check = string.format("state and Private.ExecEnv.CallCustomConditionTest(%q, %s, state)",
                                uid, testFunctionNumber, trigger);
        end
      end
    elseif (cType == "bool" and value) then
      local rightSide = value == 0 and "false" or "true";
      check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]" .. string.format("[%q]", variable) .. "==" .. rightSide
    elseif (cType == "string" and value) then
      if(op == "==") then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]" .. string.format("[%q]", variable) .. " == [[" .. value .. "]]";
      elseif (op  == "find('%s')") then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]" .. string.format("[%q]", variable) .. ":find([[" .. value .. "]], 1, true)";
      elseif (op == "match('%s')") then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]" .. string.format("[%q]",  variable) .. ":match([[" .. value .. "]], 1, true)";
      end
    end
    -- If adding a new condition type, don't forget to adjust the validator in the options code

    if (cType == "timer" and value) then
      recheckCode = "  nextTime = state[" .. trigger .. "] and state[" .. trigger .. "]" .. string.format("[%q]",  variable) .. " and (state[" .. trigger .. "]" .. string.format("[%q]",  variable) .. " - " .. value .. ")\n";
      recheckCode = recheckCode .. "  if (nextTime and (not recheckTime or nextTime < recheckTime) and nextTime >= now) then\n"
      recheckCode = recheckCode .. "    recheckTime = nextTime\n";
      recheckCode = recheckCode .. "  end\n"
    elseif (cType == "elapsedTimer" and value) then
      recheckCode = "  nextTime = state[" .. trigger .. "] and state[" .. trigger .. "]" .. string.format("[%q]",  variable) .. " and (state[" .. trigger .. "]" .. string.format("[%q]",  variable) .. " +" .. value .. ")\n";
      recheckCode = recheckCode .. "  if (nextTime and (not recheckTime or nextTime < recheckTime) and nextTime >= now) then\n"
      recheckCode = recheckCode .. "    recheckTime = nextTime\n";
      recheckCode = recheckCode .. "  end\n"
    end
  end

  return check, recheckCode;
end

local function CreateCheckCondition(uid, ret, condition, conditionNumber, allConditionsTemplate, nextIsLinked, debug)
  local usedStates = {};
  local check, recheckCode = CreateTestForCondition(uid, condition.check, allConditionsTemplate, usedStates);
  if not check then
    check = "false"
  end
  if condition.linked and conditionNumber > 1 then
    ret = ret .. "      elseif (" .. check .. ") then\n";
  else
    ret = ret .. "      if (" .. check .. ") then\n";
  end
  ret = ret .. "        newActiveConditions[" .. conditionNumber .. "] = true;\n";
  if not nextIsLinked then
    ret = ret .. "      end\n";
  end

  if (check) then
    ret = ret .. "\n";
  end
  return ret, recheckCode;
end

local function ParseProperty(property)
  local subIndex, prop = string.match(property, "^sub%.(%d*).(.*)")
  if subIndex then
    return tonumber(subIndex), prop
  else
    return nil, property
  end
end

local function GetBaseProperty(data, property, start)
  if (not data) then
    return nil;
  end

  local subIndex, prop = ParseProperty(property)
  if subIndex then
    return GetBaseProperty(data.subRegions[subIndex], prop, start)
  end

  start = start or 1;
  local next = string.find(property, ".", start, true);
  if (next) then
    return GetBaseProperty(data[string.sub(property, start, next - 1)], property, next + 1);
  end

  local key = string.sub(property, start);
  return data[key] or data[tonumber(key)];
end

local function CreateDeactivateCondition(ret, condition, conditionNumber, data, properties, usedProperties, debug)
  if (condition.changes) then
    ret = ret .. "  if (activatedConditions[".. conditionNumber .. "] and not newActiveConditions[" .. conditionNumber .. "]) then\n"
    if (debug) then ret = ret .. "    print('Deactivating condition " .. conditionNumber .. "' )\n"; end
    for changeNum, change in ipairs(condition.changes) do
      if (change.property) then
        local propertyData = properties and properties[change.property]
        if (propertyData and propertyData.type and propertyData.setter) then
          usedProperties[change.property] = true;
          ret = ret .. "    propertyChanges['" .. change.property .. "'] = " .. formatValueForAssignment(propertyData.type, GetBaseProperty(data, change.property)) .. "\n";
          if (debug) then ret = ret .. "    print('- " .. change.property .. " " ..formatValueForAssignment(propertyData.type,  GetBaseProperty(data, change.property)) .. "')\n"; end
        end
      end
    end
    ret = ret .. "  end\n"
  end

  return ret;
end

local function CreateActivateCondition(ret, id, condition, conditionNumber, properties, debug)
  if (condition.changes) then
    ret = ret .. "  if (newActiveConditions[" .. conditionNumber .. "]) then\n"
    ret = ret .. "    if (not activatedConditions[".. conditionNumber .. "]) then\n"
    if (debug) then ret = ret .. "      print('Activating condition " .. conditionNumber .. "' )\n"; end
    -- non active => active
    for changeNum, change in ipairs(condition.changes) do
      if (change.property) then
        local propertyData = properties and properties[change.property]
        if (propertyData and propertyData.type) then
          if (propertyData.setter) then
            ret = ret .. "      propertyChanges['" .. change.property .. "'] = " .. formatValueForAssignment(propertyData.type, change.value) .. "\n";
            if (debug) then ret = ret .. "      print('- " .. change.property .. " " .. formatValueForAssignment(propertyData.type, change.value) .. "')\n"; end
          elseif (propertyData.action) then
            local pathToCustomFunction = "nil";
            local pathToFormatter = "nil"
            if (Private.ExecEnv.customConditionsFunctions[id]
              and Private.ExecEnv.customConditionsFunctions[id][conditionNumber]
              and  Private.ExecEnv.customConditionsFunctions[id][conditionNumber].changes
              and Private.ExecEnv.customConditionsFunctions[id][conditionNumber].changes[changeNum]) then
              pathToCustomFunction = string.format("Private.ExecEnv.customConditionsFunctions[%q][%s].changes[%s]", id, conditionNumber, changeNum);
            end
            if Private.ExecEnv.conditionTextFormatters[id]
              and Private.ExecEnv.conditionTextFormatters[id][conditionNumber]
              and Private.ExecEnv.conditionTextFormatters[id][conditionNumber].changes
              and Private.ExecEnv.conditionTextFormatters[id][conditionNumber].changes[changeNum] then
              pathToFormatter = string.format("Private.ExecEnv.conditionTextFormatters[%q][%s].changes[%s]", id, conditionNumber, changeNum);
            end
            ret = ret .. "     region:" .. propertyData.action .. "(" .. formatValueForAssignment(propertyData.type, change.value, pathToCustomFunction, pathToFormatter) .. ")" .. "\n";
            if (debug) then ret = ret .. "     print('# " .. propertyData.action .. "(" .. formatValueForAssignment(propertyData.type, change.value, pathToCustomFunction, pathToFormatter) .. "')\n"; end
          end
        end
      end
    end
    ret = ret .. "    else\n"
    -- active => active, only override properties
    for changeNum, change in ipairs(condition.changes) do
      if (change.property) then
        local propertyData = properties and properties[change.property]
        if (propertyData and propertyData.type and propertyData.setter) then
          ret = ret .. "      if(propertyChanges['" .. change.property .. "'] ~= nil) then\n"
          ret = ret .. "        propertyChanges['" .. change.property .. "'] = " .. formatValueForAssignment(propertyData.type, change.value) .. "\n";
          if (debug) then ret = ret .. "        print('- " .. change.property .. " " .. formatValueForAssignment(propertyData.type,  change.value) .. "')\n"; end
          ret = ret .. "      end\n"
        end
      end
    end
    ret = ret .. "    end\n"
    ret = ret .. "  end\n"
    ret = ret .. "\n";
    ret = ret .. "  activatedConditions[".. conditionNumber .. "] = newActiveConditions[" .. conditionNumber .. "]\n";
  end

  return ret;
end

function Private.GetSubRegionProperties(data, properties)
  if data.subRegions then
    local subIndex = {}
    for index, subRegion in ipairs(data.subRegions) do
      local subRegionTypeData = Private.subRegionTypes[subRegion.type];
      local propertiesFunction = subRegionTypeData and subRegionTypeData.properties
      local subProperties;
      if (type(propertiesFunction) == "function") then
        subProperties = propertiesFunction(data, subRegion);
      elseif propertiesFunction then
        subProperties = CopyTable(propertiesFunction)
      end

      if subProperties then
        for key, property in pairs(subProperties) do
          subIndex[key] = subIndex[key] and subIndex[key] + 1 or 1
          property.display = { subIndex[key] .. ". " .. subRegionTypeData.displayName, property.display, property.defaultProperty }
          properties["sub." .. index .. "." .. key ] = property;
        end
      end
    end
  end
end

function Private.GetProperties(data)
  local properties;
  local propertiesFunction = Private.regionTypes[data.regionType] and Private.regionTypes[data.regionType].properties;
  if (type(propertiesFunction) == "function") then
    properties = propertiesFunction(data);
  elseif propertiesFunction then
    properties = CopyTable(propertiesFunction);
  else
    properties = {}
  end

  Private.GetSubRegionProperties(data, properties)
  return properties;
end

function Private.LoadConditionPropertyFunctions(data)
  local id = data.id;
  if (data.conditions) then
    Private.ExecEnv.customConditionsFunctions[id] = {};
    for conditionNumber, condition in ipairs(data.conditions) do
      if (condition.changes) then
        for changeIndex, change in ipairs(condition.changes) do
          if ( (change.property == "chat" or change.property == "customcode") and type(change.value) == "table" and change.value.custom) then
            local custom = change.value.custom;
            local prefix, suffix;
            if (change.property == "chat") then
              prefix, suffix = "return ", "";
            else
              prefix, suffix = "return function()", "\nend";
            end
            local customFunc = WeakAuras.LoadFunction(prefix .. custom .. suffix);
            if (customFunc) then
              Private.ExecEnv.customConditionsFunctions[id][conditionNumber] = Private.ExecEnv.customConditionsFunctions[id][conditionNumber] or {};
              Private.ExecEnv.customConditionsFunctions[id][conditionNumber].changes = Private.ExecEnv.customConditionsFunctions[id][conditionNumber].changes or {};
              Private.ExecEnv.customConditionsFunctions[id][conditionNumber].changes[changeIndex] = customFunc;
            end
          end
          if change.property == "chat" then
            local getter = function(key, default)
              local fullKey = "message_format_" .. key
              if change.value[fullKey] == nil then
                change.value[fullKey] = default
              end
              return change.value[fullKey]
            end
            local formatters = change.value and Private.CreateFormatters(change.value.message, getter, true)
            Private.ExecEnv.conditionTextFormatters[id] = Private.ExecEnv.conditionTextFormatters[id] or {}
            Private.ExecEnv.conditionTextFormatters[id][conditionNumber] = Private.ExecEnv.conditionTextFormatters[id][conditionNumber] or {};
            Private.ExecEnv.conditionTextFormatters[id][conditionNumber].changes = Private.ExecEnv.conditionTextFormatters[id][conditionNumber].changes or {};
            Private.ExecEnv.conditionTextFormatters[id][conditionNumber].changes[changeIndex] = formatters;
          end
        end
      end
    end
  end
end

local globalConditions =
{
  ["incombat"] = {
    display = L["In Combat"],
    type = "bool",
    events = {"PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED"},
    globalStateUpdate = function(state)
      state.incombat = UnitAffectingCombat("player");
    end
  },
  ["hastarget"] = {
    display = L["Has Target"],
    type = "bool",
    events = {"PLAYER_TARGET_CHANGED", "PLAYER_ENTERING_WORLD"},
    globalStateUpdate = function(state)
      state.hastarget = UnitExists("target");
    end
  },
  ["rangecheck"] = {
    display = WeakAuras.newFeatureString .. L["Range Check"],
    type = "range",
    events = {"WA_SPELL_RANGECHECK"}
  },
  ["attackabletarget"] = {
    display = L["Attackable Target"],
    type = "bool",
    events = {"PLAYER_TARGET_CHANGED", "UNIT_FACTION"},
    globalStateUpdate = function(state)
      state.attackabletarget = UnitCanAttack("player", "target");
    end
  },
  ["customcheck"] = {
    display = L["Custom Check"],
    type = "customcheck"
  },
  ["alwaystrue"] = {
    display = L["Always True"],
    type = "alwaystrue"
  }
}

function Private.GetGlobalConditions()
  return globalConditions;
end

local function ConstructConditionFunction(data)
  local debug = false;
  if (not data.conditions or #data.conditions == 0) then
    return nil;
  end

  local usedProperties = {};

  local allConditionsTemplate = Private.GetTriggerConditions(data);
  allConditionsTemplate[-1] = Private.GetGlobalConditions();

  local ret = "";
  ret = ret .. "local newActiveConditions = {};\n"
  ret = ret .. "local propertyChanges = {};\n"
  ret = ret .. "local nextTime;\n"
  ret = ret .. string.format("local uid = %q\n", data.uid)
  ret = ret .. "return function(region, hideRegion)\n";
  if (debug) then ret = ret .. "  print('check conditions for:', region.id, region.cloneId)\n"; end
  ret = ret .. "  local id = region.id\n";
  ret = ret .. "  local cloneId = region.cloneId or ''\n";
  ret = ret .. "  local state = region.states\n"
  ret = ret .. "  local activatedConditions = WeakAuras.GetActiveConditions(id, cloneId)\n";
  ret = ret .. "  wipe(newActiveConditions)\n";
  ret = ret .. "  local recheckTime;\n"
  ret = ret .. "  local now = GetTime();\n"

  -- First Loop gather which conditions are active
  ret = ret .. "  if (not hideRegion) then\n"
  local recheckCode = ""
  if (data.conditions) then
    Private.ExecEnv.conditionHelpers[data.uid] = nil
    for conditionNumber, condition in ipairs(data.conditions) do
      local nextIsLinked = data.conditions[conditionNumber + 1] and data.conditions[conditionNumber + 1].linked
      local additionalRecheckCode
      ret, additionalRecheckCode = CreateCheckCondition(data.uid, ret, condition, conditionNumber, allConditionsTemplate, nextIsLinked, debug)
      if additionalRecheckCode then
        recheckCode = recheckCode .. "\n" .. additionalRecheckCode
      end
    end
  end
  ret = ret .. recheckCode
  ret = ret .. "  end\n";

  ret = ret .. "  if (recheckTime) then\n"
  ret = ret .. "    Private.ExecEnv.ScheduleConditionCheck(recheckTime, uid, cloneId);\n"
  ret = ret .. "  end\n"

  local properties = Private.GetProperties(data);

  -- Now build a property + change list
  -- Second Loop deals with conditions that are no longer active
  ret = ret .. "  wipe(propertyChanges)\n"
  if (data.conditions) then
    for conditionNumber, condition in ipairs(data.conditions) do
      ret = CreateDeactivateCondition(ret, condition, conditionNumber, data, properties, usedProperties, debug)
    end
  end
  ret = ret .. "\n";

  -- Third Loop deals with conditions that are newly active
  if (data.conditions) then
    for conditionNumber, condition in ipairs(data.conditions) do
      ret = CreateActivateCondition(ret, data.id, condition, conditionNumber, properties, debug)
    end
  end

  -- Last apply changes to region
  for property, _  in pairs(usedProperties) do
    ret = ret .. "  if(propertyChanges['" .. property .. "'] ~= nil) then\n"
    local arg1 = "";
    if (properties[property].arg1) then
      if (type(properties[property].arg1) == "number") then
        arg1 = tostring(properties[property].arg1) .. ", ";
      else
        arg1 = "'" .. properties[property].arg1 .. "', ";
      end
    end

    local base = "region:"
    local subIndex = ParseProperty(property)
    if subIndex then
      base = "region.subRegions[" .. subIndex .. "]:"
    end

    ret = ret .. "    " .. base .. properties[property].setter .. "(" .. arg1 .. formatValueForCall(properties[property].type, property)  .. ")\n";
    if (debug) then ret = ret .. "    print('Calling "  .. properties[property].setter ..  " with', " .. arg1 ..  formatValueForCall(properties[property].type, property) .. ")\n"; end
    ret = ret .. "  end\n";
  end
  ret = ret .. "end\n";

  return ret;
end

local function CancelTimers(uid)
  conditionChecksTimers.recheckTime[uid] = nil;
  if (conditionChecksTimers.recheckHandle[uid]) then
    for _, v in pairs(conditionChecksTimers.recheckHandle[uid]) do
      timer:CancelTimer(v);
    end
  end
  conditionChecksTimers.recheckHandle[uid] = nil;
end

function Private.LoadConditionFunction(data)
  CancelTimers(data.uid)

  local checkConditionsFuncStr = ConstructConditionFunction(data);
  local checkConditionsFunc = checkConditionsFuncStr and Private.LoadFunction(checkConditionsFuncStr)

  checkConditions[data.uid] = checkConditionsFunc;
end

function Private.RunConditions(region, uid, hideRegion)
  if (checkConditions[uid]) then
    Private.ActivateAuraEnvironmentForRegion(region)
    checkConditions[uid](region, hideRegion);
    Private.ActivateAuraEnvironment()
  end
end


local dynamicConditionsFrame = nil;

local globalConditionAllState = {
  [""] = {
    show = true;
  }
};

local globalConditionState = globalConditionAllState[""];

function Private.GetGlobalConditionState()
  return globalConditionAllState;
end

local function runDynamicConditionFunctions(funcs)
  for uid in pairs(funcs) do
    local id = Private.UIDtoID(uid)
    Private.StartProfileAura(id)
    if (Private.IsAuraActive(uid) and checkConditions[uid]) then
      local activeStates = WeakAuras.GetActiveStates(id)
      for cloneId, state in pairs(activeStates) do
        local region = WeakAuras.GetRegion(id, cloneId)
        Private.ActivateAuraEnvironmentForRegion(region)
        checkConditions[uid](region, false)
        Private.ActivateAuraEnvironment()
      end
    end
    Private.StopProfileAura(id)
  end
end

local function handleDynamicConditions(self, event)
  Private.StartProfileSystem("dynamic conditions")
  if (globalDynamicConditionFuncs[event]) then
    for i, func in ipairs(globalDynamicConditionFuncs[event]) do
      func(globalConditionState);
    end
  end
  if (dynamicConditions[event]) then
    runDynamicConditionFunctions(dynamicConditions[event]);
  end
  Private.StopProfileSystem("dynamic conditions")
end

local function handleDynamicConditionsPerUnit(self, event, unit)
  Private.StartProfileSystem("dynamic conditions")
  if unit then
    local unitEvent = event..":"..unit
    if globalDynamicConditionFuncs[unitEvent] then
      for i, func in ipairs(globalDynamicConditionFuncs[unitEvent]) do
        func(globalConditionState);
      end
    end
    if (dynamicConditions[unitEvent]) then
      runDynamicConditionFunctions(dynamicConditions[unitEvent]);
    end
  end
  Private.StopProfileSystem("dynamic conditions")
end

local lastDynamicConditionsUpdateCheck;
local function handleDynamicConditionsOnUpdate(self)
  handleDynamicConditions(self, "FRAME_UPDATE");
  if (not lastDynamicConditionsUpdateCheck or GetTime() - lastDynamicConditionsUpdateCheck > 0.2) then
    lastDynamicConditionsUpdateCheck = GetTime();
    handleDynamicConditions(self, "WA_SPELL_RANGECHECK");
  end
end

local registeredGlobalFunctions = {};

local function EvaluateCheckForRegisterForGlobalConditions(uid, check, allConditionsTemplate, register)
  local trigger = check and check.trigger;
  local variable = check and check.variable;

  if (trigger == -2) then
    if (check.checks) then
      for _, subcheck in ipairs(check.checks) do
        EvaluateCheckForRegisterForGlobalConditions(uid, subcheck, allConditionsTemplate, register);
      end
    end
  elseif trigger == -1 and variable == "customcheck" then
    if check.op then
      for event in string.gmatch(check.op, "[%w_:]+") do
        if (not dynamicConditions[event]) then
          register[event] = true;
          dynamicConditions[event] = {};
        end
        dynamicConditions[event][uid] = true;
      end
    end
  elseif (trigger and variable) then
    local conditionTemplate = allConditionsTemplate[trigger] and allConditionsTemplate[trigger][variable];
    if (conditionTemplate and conditionTemplate.events) then
      for _, event in ipairs(conditionTemplate.events) do
        if (not dynamicConditions[event]) then
          register[event] = true;
          dynamicConditions[event] = {};
        end
        dynamicConditions[event][uid] = true;
      end

      if (conditionTemplate.globalStateUpdate and not registeredGlobalFunctions[variable]) then
        registeredGlobalFunctions[variable] = true;
        for _, event in ipairs(conditionTemplate.events) do
          globalDynamicConditionFuncs[event] = globalDynamicConditionFuncs[event] or {};
          tinsert(globalDynamicConditionFuncs[event], conditionTemplate.globalStateUpdate);
        end
        conditionTemplate.globalStateUpdate(globalConditionState);
      end
    end
  end
end

function Private.RegisterForGlobalConditions(uid)
  local data = Private.GetDataByUID(uid);
  for event, conditionFunctions in pairs(dynamicConditions) do
    conditionFunctions[uid] = nil;
  end

  local register = {};
  if (data.conditions) then
    local allConditionsTemplate = Private.GetTriggerConditions(data);
    allConditionsTemplate[-1] = Private.GetGlobalConditions();

    for conditionNumber, condition in ipairs(data.conditions) do
      EvaluateCheckForRegisterForGlobalConditions(uid, condition.check, allConditionsTemplate, register);
    end
  end

  if (next(register) and not dynamicConditionsFrame) then
    dynamicConditionsFrame = CreateFrame("Frame");
    dynamicConditionsFrame:SetScript("OnEvent", handleDynamicConditions);
    dynamicConditionsFrame.units = {}
    Private.frames["Rerun Conditions Frame"] = dynamicConditionsFrame
  end

  for event in pairs(register) do
    if (event == "FRAME_UPDATE" or event == "WA_SPELL_RANGECHECK") then
      if (not dynamicConditionsFrame.onUpdate) then
        dynamicConditionsFrame:SetScript("OnUpdate", handleDynamicConditionsOnUpdate);
        dynamicConditionsFrame.onUpdate = true;
      end
    else
      local unitEvent, unit = event:match("([^:]+):([^:]+)")
      if unitEvent and unit then
        unit = unit:lower()
        if not dynamicConditionsFrame.units[unit] then
          dynamicConditionsFrame.units[unit] = CreateFrame("Frame");
          dynamicConditionsFrame.units[unit]:SetScript("OnEvent", handleDynamicConditionsPerUnit);
        end
        pcall(dynamicConditionsFrame.units[unit].RegisterUnitEvent, dynamicConditionsFrame.units[unit], unitEvent, unit);
      else
        pcall(dynamicConditionsFrame.RegisterEvent, dynamicConditionsFrame, event);
      end
    end
  end
end

function Private.UnregisterForGlobalConditions(uid)
  for event, condFuncs in pairs(dynamicConditions) do
    condFuncs[uid] = nil;
    if next(condFuncs) == nil then
      local unitEvent, unit = event:match("([^:]+):([^:]+)")
      if unitEvent and unit then
        unit = unit:lower()
        pcall(dynamicConditionsFrame.units[unit].UnregisterEvent, dynamicConditionsFrame.units[unit], unitEvent);
      elseif (event == "FRAME_UPDATE" or event == "WA_SPELL_RANGECHECK") then
        if (event == "FRAME_UPDATE" and dynamicConditions["WA_SPELL_RANGECHECK"] == nil)
        or (event == "WA_SPELL_RANGECHECK" and dynamicConditions["FRAME_UPDATE"] == nil)
        then
          dynamicConditionsFrame:SetScript("OnUpdate", nil)
          dynamicConditionsFrame.onUpdate = false
        end
      else
        pcall(dynamicConditionsFrame.UnregisterEvent, dynamicConditionsFrame, event);
      end
      dynamicConditions[event] = nil
    end
  end
end

function Private.UnloadAllConditions()
  for uid in pairs(conditionChecksTimers.recheckTime) do
    if (conditionChecksTimers.recheckHandle[uid]) then
      for _, v in pairs(conditionChecksTimers.recheckHandle[uid]) do
        timer:CancelTimer(v)
      end
    end
  end
  wipe(conditionChecksTimers.recheckTime)
  wipe(conditionChecksTimers.recheckHandle)

  dynamicConditions = {}
  if dynamicConditionsFrame then
    dynamicConditionsFrame:UnregisterAllEvents()
    for _, frame in pairs(dynamicConditionsFrame.units) do
      frame:UnregisterAllEvents()
    end
    dynamicConditionsFrame:SetScript("OnUpdate", nil)
    dynamicConditionsFrame.onUpdate = false
  end
end

function Private.UnloadConditions(uid)
  CancelTimers(uid)
  Private.UnregisterForGlobalConditions(uid);
end
