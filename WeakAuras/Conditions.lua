if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

local L = WeakAuras.L
local timer = WeakAuras.timer

-- Dynamic Condition functions to run. keyed on event and id
local dynamicConditions = {};

-- Global Dynamic Condition Funcs, keyed on the event
local globalDynamicConditionFuncs = {};

-- Check Conditions Functions, keyed on id
local checkConditions = {};

local clones = WeakAuras.clones;

local function formatValueForAssignment(vType, value, pathToCustomFunction, pathToFormatters)
  if (value == nil) then
    value = false;
  end
  if (vType == "bool") then
    return value and tostring(value) or "false";
  elseif(vType == "number") then
    return value and tostring(value) or "0";
  elseif (vType == "list") then
    return type(value) == "string" and string.format("%q", value) or "nil";
  elseif(vType == "color") then
    if (value and type(value) == "table") then
      return string.format("{%s, %s, %s, %s}", tostring(value[1]), tostring(value[2]), tostring(value[3]), tostring(value[4]));
    end
    return "{1, 1, 1, 1}";
  elseif(vType == "chat") then
    if (value and type(value) == "table") then
      local serialized = string.format("{message_type = %q, message = %q, message_dest = %q, message_channel = %q, message_custom = %s, message_formaters = %s}",
        tostring(value.message_type), tostring(value.message or ""),
        tostring(value.message_dest), tostring(value.message_channel),
        pathToCustomFunction,
        pathToFormatters)
      return serialized
    end
  elseif(vType == "sound") then
    if (value and type(value) == "table") then
      return string.format("{ sound = %q, sound_channel = %q, sound_path = %q, sound_kit_id = %q, sound_type = %q, %s}",
        tostring(value.sound or ""), tostring(value.sound_channel or ""), tostring(value.sound_path or ""),
        tostring(value.sound_kit_id or ""), tostring(value.sound_type or ""),
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
  if (type == "bool" or type == "number" or type == "list") then
    return "propertyChanges['" .. property .. "']";
  elseif (type == "color") then
    local pcp = "propertyChanges['" .. property .. "']";
    return pcp  .. "[1], " .. pcp .. "[2], " .. pcp  .. "[3], " .. pcp  .. "[4]";
  end
  return "nil";
end

local conditionChecksTimers = {};
conditionChecksTimers.recheckTime = {};
conditionChecksTimers.recheckHandle = {};

function WeakAuras.scheduleConditionCheck(time, id, cloneId)
  conditionChecksTimers.recheckTime[id] = conditionChecksTimers.recheckTime[id] or {}
  conditionChecksTimers.recheckHandle[id] = conditionChecksTimers.recheckHandle[id] or {};

  if (conditionChecksTimers.recheckTime[id][cloneId] and conditionChecksTimers.recheckTime[id][cloneId] > time) then
    timer:CancelTimer(conditionChecksTimers.recheckHandle[id][cloneId]);
    conditionChecksTimers.recheckHandle[id][cloneId] = nil;
  end

  if (conditionChecksTimers.recheckHandle[id][cloneId] == nil) then
    conditionChecksTimers.recheckHandle[id][cloneId] = timer:ScheduleTimerFixed(function()
      conditionChecksTimers.recheckHandle[id][cloneId] = nil;
      local region;
      if(cloneId and cloneId ~= "") then
        region = clones[id] and clones[id][cloneId];
      else
        region = WeakAuras.regions[id].region;
      end
      if (region and region.toShow) then
        checkConditions[id](region);
      end
    end, time - GetTime())
    conditionChecksTimers.recheckTime[id][cloneId] = time;
  end
end

function WeakAuras.CallCustomConditionTest(uid, testFunctionNumber, ...)
  local ok, result = xpcall(WeakAuras.conditionHelpers[uid].customTestFunctions[testFunctionNumber], geterrorhandler(), ...)
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
    local test = conditionTemplate and conditionTemplate.test;
    local preamble = conditionTemplate and conditionTemplate.preamble;

    local stateCheck = "state[" .. trigger .. "] and state[" .. trigger .. "].show and ";
    local stateVariableCheck = "state[" .. trigger .. "]." .. variable .. "~= nil and ";

    local preambleString

    if preamble then
      WeakAuras.conditionHelpers[uid] = WeakAuras.conditionHelpers[uid] or {}
      WeakAuras.conditionHelpers[uid].preambles = WeakAuras.conditionHelpers[uid].preambles or {}
      tinsert(WeakAuras.conditionHelpers[uid].preambles, preamble(value));
      local preambleNumber = #WeakAuras.conditionHelpers[uid].preambles
      preambleString = string.format("WeakAuras.conditionHelpers[%q].preambles[%s]", uid, preambleNumber)
    end

    if (test) then
      if (value) then
        WeakAuras.conditionHelpers[uid] = WeakAuras.conditionHelpers[uid] or {}
        WeakAuras.conditionHelpers[uid].customTestFunctions = WeakAuras.conditionHelpers[uid].customTestFunctions or {}
        tinsert(WeakAuras.conditionHelpers[uid].customTestFunctions, test);
        local testFunctionNumber = #(WeakAuras.conditionHelpers[uid].customTestFunctions);
        local valueString = type(value) == "string" and string.format("%q", value) or value;
        local opString = type(op) == "string" and string.format("%q", op) or op;
        check = string.format("state and WeakAuras.CallCustomConditionTest(%q, %s, state[%s], %s, %s, %s)",
                              uid, testFunctionNumber, trigger, valueString, (opString or "nil"), preambleString or "nil");
      end
    elseif (cType == "customcheck") then
      if value then
        local customCheck = WeakAuras.LoadFunction("return " .. value, "custom check")
        if customCheck then
          WeakAuras.conditionHelpers[uid] = WeakAuras.conditionHelpers[uid] or {}
          WeakAuras.conditionHelpers[uid].customTestFunctions = WeakAuras.conditionHelpers[uid].customTestFunctions or {}
          tinsert(WeakAuras.conditionHelpers[uid].customTestFunctions, customCheck);
          local testFunctionNumber = #(WeakAuras.conditionHelpers[uid].customTestFunctions);

          check = string.format("state and WeakAuras.CallCustomConditionTest(%q, %s, state)",
                                uid, testFunctionNumber, trigger);
        end
      end
    elseif cType == "alwaystrue" then
      check = "true"
    elseif (cType == "number" and value and op) then
      local v = tonumber(value)
      if (v) then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]." .. variable .. op .. v;
      end
    elseif (cType == "timer" and value and op) then
      if (op == "==") then
        check = stateCheck .. stateVariableCheck .. "abs(state[" .. trigger .. "]." ..variable .. "- now -" .. value .. ") < 0.05";
      else
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]." .. variable .. "- now" .. op .. value;
      end
    elseif (cType == "select" and value and op) then
      if (tonumber(value)) then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]." .. variable .. op .. tonumber(value);
      else
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]." .. variable .. op .. "'" .. value .. "'";
      end
    elseif (cType == "bool" and value) then
      local rightSide = value == 0 and "false" or "true";
      check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]." .. variable .. "==" .. rightSide
    elseif (cType == "string" and value) then
      if(op == "==") then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]." .. variable .. " == [[" .. value .. "]]";
      elseif (op  == "find('%s')") then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]." .. variable .. ":find([[" .. value .. "]], 1, true)";
      elseif (op == "match('%s')") then
        check = stateCheck .. stateVariableCheck .. "state[" .. trigger .. "]." ..  variable .. ":match([[" .. value .. "]], 1, true)";
      end
    end

    if (cType == "timer" and value) then
      recheckCode = "  nextTime = state[" .. trigger .. "] and state[" .. trigger .. "]." .. variable .. " and (state[" .. trigger .. "]." .. variable .. " -" .. value .. ")\n";
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

  if (recheckCode) then
    ret = ret .. recheckCode;
  end
  if (check or recheckCode) then
    ret = ret .. "\n";
  end
  return ret;
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
            if (WeakAuras.customConditionsFunctions[id]
              and WeakAuras.customConditionsFunctions[id][conditionNumber]
              and  WeakAuras.customConditionsFunctions[id][conditionNumber].changes
              and WeakAuras.customConditionsFunctions[id][conditionNumber].changes[changeNum]) then
              pathToCustomFunction = string.format("WeakAuras.customConditionsFunctions[%q][%s].changes[%s]", id, conditionNumber, changeNum);
            end
            if WeakAuras.conditionTextFormatters[id]
              and WeakAuras.conditionTextFormatters[id][conditionNumber]
              and WeakAuras.conditionTextFormatters[id][conditionNumber].changes
              and WeakAuras.conditionTextFormatters[id][conditionNumber].changes[changeNum] then
              pathToFormatter = string.format("WeakAuras.conditionTextFormatters[%q][%s].changes[%s]", id, conditionNumber, changeNum);
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

function WeakAuras.GetProperties(data)
  local properties;
  local propertiesFunction = WeakAuras.regionTypes[data.regionType] and WeakAuras.regionTypes[data.regionType].properties;
  if (type(propertiesFunction) == "function") then
    properties = propertiesFunction(data);
  elseif propertiesFunction then
    properties = CopyTable(propertiesFunction);
  else
    properties = {}
  end

  if data.subRegions then
    local subIndex = {}
    for index, subRegion in ipairs(data.subRegions) do
      local subRegionTypeData = WeakAuras.subRegionTypes[subRegion.type];
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

  return properties;
end

function Private.LoadConditionPropertyFunctions(data)
  local id = data.id;
  if (data.conditions) then
    WeakAuras.customConditionsFunctions[id] = {};
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
            local customFunc = WeakAuras.LoadFunction(prefix .. custom .. suffix, id, "condition");
            if (customFunc) then
              WeakAuras.customConditionsFunctions[id][conditionNumber] = WeakAuras.customConditionsFunctions[id][conditionNumber] or {};
              WeakAuras.customConditionsFunctions[id][conditionNumber].changes = WeakAuras.customConditionsFunctions[id][conditionNumber].changes or {};
              WeakAuras.customConditionsFunctions[id][conditionNumber].changes[changeIndex] = customFunc;
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
            local formatters = change.value and WeakAuras.CreateFormatters(change.value.message, getter)
            WeakAuras.conditionTextFormatters[id] = WeakAuras.conditionTextFormatters[id] or {}
            WeakAuras.conditionTextFormatters[id][conditionNumber] = WeakAuras.conditionTextFormatters[id][conditionNumber] or {};
            WeakAuras.conditionTextFormatters[id][conditionNumber].changes = WeakAuras.conditionTextFormatters[id][conditionNumber].changes or {};
            WeakAuras.conditionTextFormatters[id][conditionNumber].changes[changeIndex] = formatters;
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

function WeakAuras.GetGlobalConditions()
  return globalConditions;
end

local function ConstructConditionFunction(data)
  local debug = false;
  if (not data.conditions or #data.conditions == 0) then
    return nil;
  end

  local usedProperties = {};

  local allConditionsTemplate = WeakAuras.GetTriggerConditions(data);
  allConditionsTemplate[-1] = WeakAuras.GetGlobalConditions();

  local ret = "";
  ret = ret .. "local newActiveConditions = {};\n"
  ret = ret .. "local propertyChanges = {};\n"
  ret = ret .. "local nextTime;\n"
  ret = ret .. "return function(region, hideRegion)\n";
  if (debug) then ret = ret .. "  print('check conditions for:', region.id, region.cloneId)\n"; end
  ret = ret .. "  local id = region.id\n";
  ret = ret .. "  local cloneId = region.cloneId or ''\n";
  ret = ret .. "  local state = region.states\n"
  ret = ret .. "  local activatedConditions = WeakAuras.GetActiveConditions(id, cloneId)\n";
  ret = ret .. "  wipe(newActiveConditions)\n";
  ret = ret .. "  local recheckTime;\n"
  ret = ret .. "  local now = GetTime();\n"

  local normalConditionCount = data.conditions and #data.conditions;
  -- First Loop gather which conditions are active
  ret = ret .. "  if (not hideRegion) then\n"
  if (data.conditions) then
    WeakAuras.conditionHelpers[data.uid] = nil
    for conditionNumber, condition in ipairs(data.conditions) do
      local nextIsLinked = data.conditions[conditionNumber + 1] and data.conditions[conditionNumber + 1].linked
      ret = CreateCheckCondition(data.uid, ret, condition, conditionNumber, allConditionsTemplate, nextIsLinked, debug)
    end
  end
  ret = ret .. "  end\n";

  ret = ret .. "  if (recheckTime) then\n"
  ret = ret .. "    WeakAuras.scheduleConditionCheck(recheckTime, id, cloneId);\n"
  ret = ret .. "  end\n"

  local properties = WeakAuras.GetProperties(data);

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

function Private.LoadConditionFunction(data)
  local checkConditionsFuncStr = ConstructConditionFunction(data);
  local checkCondtionsFunc = checkConditionsFuncStr and WeakAuras.LoadFunction(checkConditionsFuncStr, data.id, "condition checks");

  checkConditions[data.id] = checkCondtionsFunc;
end

function Private.RunConditions(region, id, hideRegion)
  if (checkConditions[id]) then
    checkConditions[id](region, hideRegion);
  end
end


local dynamicConditionsFrame = nil;

local globalConditionAllState = {
  [""] = {
    show = true;
  }
};

local globalConditionState = globalConditionAllState[""];

function WeakAuras.GetGlobalConditionState()
  return globalConditionAllState;
end

local function runDynamicConditionFunctions(funcs)
  for id in pairs(funcs) do
    if (Private.IsAuraActive(id) and checkConditions[id]) then
      local activeTriggerState = WeakAuras.GetTriggerStateForTrigger(id, Private.ActiveTrigger(id));
      for cloneId, state in pairs(activeTriggerState) do
        local region = WeakAuras.GetRegion(id, cloneId);
        checkConditions[id](region, false);
      end
    end
  end
end

local function handleDynamicConditions(self, event)
  if (globalDynamicConditionFuncs[event]) then
    for i, func in ipairs(globalDynamicConditionFuncs[event]) do
      func(globalConditionState);
    end
  end
  if (dynamicConditions[event]) then
    runDynamicConditionFunctions(dynamicConditions[event]);
  end
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

local function EvaluateCheckForRegisterForGlobalConditions(id, check, allConditionsTemplate, register)
  local trigger = check and check.trigger;
  local variable = check and check.variable;

  if (trigger == -2) then
    if (check.checks) then
      for _, subcheck in ipairs(check.checks) do
        EvaluateCheckForRegisterForGlobalConditions(id, subcheck, allConditionsTemplate, register);
      end
    end
  elseif trigger == -1 and variable == "customcheck" then
    if check.op then
      for event in string.gmatch(check.op, "[%w_]+") do
        if (not dynamicConditions[event]) then
          register[event] = true;
          dynamicConditions[event] = {};
        end
        dynamicConditions[event][id] = true;
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
        dynamicConditions[event][id] = true;
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

function Private.RegisterForGlobalConditions(id)
  local data = WeakAuras.GetData(id);
  for event, conditionFunctions in pairs(dynamicConditions) do
    conditionFunctions.id = nil;
  end

  local register = {};
  if (data.conditions) then
    local allConditionsTemplate = WeakAuras.GetTriggerConditions(data);
    allConditionsTemplate[-1] = WeakAuras.GetGlobalConditions();

    for conditionNumber, condition in ipairs(data.conditions) do
      EvaluateCheckForRegisterForGlobalConditions(id, condition.check, allConditionsTemplate, register);
    end
  end

  if (next(register) and not dynamicConditionsFrame) then
    dynamicConditionsFrame = CreateFrame("FRAME");
    dynamicConditionsFrame:SetScript("OnEvent", handleDynamicConditions);
    WeakAuras.frames["Rerun Conditions Frame"] = dynamicConditionsFrame
  end

  for event in pairs(register) do
    if (event == "FRAME_UPDATE" or event == "WA_SPELL_RANGECHECK") then
      if (not dynamicConditionsFrame.onUpdate) then
        dynamicConditionsFrame:SetScript("OnUpdate", handleDynamicConditionsOnUpdate);
        dynamicConditionsFrame.onUpdate = true;
      end
    else
      pcall(dynamicConditionsFrame.RegisterEvent, dynamicConditionsFrame, event);
    end
  end
end

function Private.UnregisterForGlobalConditions(id)
  for event, condFuncs in pairs(dynamicConditions) do
    condFuncs[id] = nil;
  end
end


function Private.UnloadAllConditions()
  for id in pairs(conditionChecksTimers.recheckTime) do
    if (conditionChecksTimers.recheckHandle[id]) then
      for _, v in pairs(conditionChecksTimers.recheckHandle[id]) do
        timer:CancelTimer(v)
      end
    end
  end
  wipe(conditionChecksTimers.recheckTime)
  wipe(conditionChecksTimers.recheckHandle)

  dynamicConditions = {}
end

function Private.UnloadConditions(id)
  conditionChecksTimers.recheckTime[id] = nil;
  if (conditionChecksTimers.recheckHandle[id]) then
    for _, v in pairs(conditionChecksTimers.recheckHandle[id]) do
      timer:CancelTimer(v);
    end
  end
  conditionChecksTimers.recheckHandle[id] = nil;
  Private.UnregisterForGlobalConditions(id);
end

function Private.DeleteConditions(id)
  checkConditions[id] = nil
  conditionChecksTimers.recheckTime[id] = nil
  if (conditionChecksTimers.recheckHandle[id]) then
    for cloneId, v in pairs(conditionChecksTimers.recheckHandle[id]) do
      timer:CancelTimer(v)
    end
  end
  conditionChecksTimers.recheckHandle[id] = nil

  for event, funcs in pairs(dynamicConditions) do
    funcs[id] = nil
  end
end

function Private.RenameConditions(oldid, newid)
  checkConditions[newid] = checkConditions[oldid];
  checkConditions[oldid] = nil;

  conditionChecksTimers.recheckTime[newid] = conditionChecksTimers.recheckTime[oldid];
  conditionChecksTimers.recheckTime[oldid] = nil;

  conditionChecksTimers.recheckHandle[newid] = conditionChecksTimers.recheckHandle[oldid];
  conditionChecksTimers.recheckHandle[oldid] = nil;

  for event, funcs in pairs(dynamicConditions) do
    funcs[newid] = funcs[oldid]
    funcs[oldid] = nil;
  end
end
