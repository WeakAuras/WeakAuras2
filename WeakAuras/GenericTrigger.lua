--[[ GenericTrigger.lua
This file contains the generic trigger system. That is every trigger except the aura triggers.

It registers the GenericTrigger table for the generic trigger types and "custom" and has the following API:

Add(data)
Adds a display, creating all internal data structures for all triggers.

Delete(id)
Deletes all triggers for display id.

Rename(oldid, newid)
Updates all trigger information from oldid to newid.

LoadDisplay(id)
Loads all triggers of display id.

UnloadAll
Unloads all triggers.

UnloadDisplays(id)
Unloads all triggers of the display ids.

Modernize(data)
Modernizes all generic triggers in data.

#####################################################
# Helper functions mainly for the WeakAuras Options #
#####################################################
GetOverlayInfo(data, triggernum)
Returns a table containing the names of all overlays

CanHaveTooltip(data, triggernum)
Returns the type of tooltip to show for the trigger.

GetNameAndIcon(data, triggernum)
Returns the name and icon to show in the options.

GetAdditionalProperties(data, triggernum)
Returns the a tooltip for the additional properties.

GetProgressSources(data, triggernum, outValues)
  Fills outValues with the potential progress sources

GetTriggerConditions(data, triggernum)
Returns potential conditions that this trigger provides.
]]--
if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

-- Lua APIs
local tinsert, tconcat, wipe = table.insert, table.concat, wipe
local tostring, pairs, type = tostring, pairs, type
local error, setmetatable = error, setmetatable
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo;

-- WoW APIs
local IsPlayerMoving = IsPlayerMoving

WeakAurasAceEvents = setmetatable({}, {__tostring=function() return "WeakAuras" end});
LibStub("AceEvent-3.0"):Embed(WeakAurasAceEvents);
local aceEvents = WeakAurasAceEvents

---@class WeakAuras
local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local GenericTrigger = {};

local event_prototypes = Private.event_prototypes;

local timer = WeakAuras.timer;

local events = {}
local loaded_events = {}
local loaded_unit_events = {};
local watched_trigger_events = Private.watched_trigger_events
local delayTimerEvents = {}
local loaded_auras = {}; -- id to bool map

-- Local functions
local LoadEvent, HandleEvent, HandleUnitEvent, TestForTriState, TestForToggle, TestForLongString, TestForMultiSelect
local ConstructTest, ConstructFunction


local nameplateExists = {}

---@param unit UnitToken
---@param smart? boolean
---@return boolean unitExists
function WeakAuras.UnitExistsFixed(unit, smart)
  if #unit > 9 and unit:sub(1, 9) == "nameplate" then
    return nameplateExists[unit]
  end
  if smart and IsInRaid() then
    if unit:sub(1, 5) == "party" or unit == "player" or unit == "pet" then
      return false
    end
  end
  return UnitExists(unit) or UnitGUID(unit)
end

---@param input string
---@return string[] subStrings
function WeakAuras.split(input)
  input = input or "";
  local ret = {};
  local split, element = true, nil
  split = input:find("[,%s]");
  while(split) do
    element, input = input:sub(1, split-1), input:sub(split+1);
    if(element ~= "") then
      tinsert(ret, element);
    end
    split = input:find("[,%s]");
  end
  if(input ~= "") then
    tinsert(ret, input);
  end
  return ret;
end

function TestForTriState(trigger, arg)
  local name = arg.name;
  local test;
  if(trigger["use_"..name] == false) then
    test = "(not "..name..")";
  elseif(trigger["use_"..name]) then
    if(arg.test) then
      test = "("..arg.test:format(trigger[name])..")";
    else
      test = name;
    end
  end
  return test;
end

function TestForToggle(trigger, arg)
  local name = arg.name;
  local test;
  if(trigger["use_"..name]) then
    if(arg.test) then
      test = "("..arg.test:format(trigger[name])..")";
    else
      test = name;
    end
  end
  return test;
end

function TestForLongString(trigger, arg)
  local name = arg.name;
  local test;
  local needle = trigger[name]
  local caseInsensitive = arg.canBeCaseInsensitive and trigger[name .. "_caseInsensitive"]
  if(trigger[name.."_operator"] == "==") then
    if caseInsensitive then
      test = ("(%s and (%s):lower() == (%s):lower())"):format(name, name, Private.QuotedString(needle))
    else
      test = ("(%s == %s)"):format(name, Private.QuotedString(needle))
    end
  elseif(trigger[name.."_operator"] == "find('%s')") then
    if caseInsensitive then
      test = ("(%s and %s:lower():find((%s):lower(), 1, true))"):format(name, name, Private.QuotedString(needle))
    else
      test = ("(%s and %s:find(%s, 1, true))"):format(name, name, Private.QuotedString(needle))
    end
  elseif(trigger[name.."_operator"] == "match('%s')") then
    if caseInsensitive then
      test = ("(%s and %s:lower():match((%s):lower()))"):format(name, name, Private.QuotedString(needle))
    else
      test = ("(%s and %s:match(%s))"):format(name, name, Private.QuotedString(needle))
    end
  end
  return test;
end

function TestForMultiSelect(trigger, arg)
  local name = arg.name;
  local test;
  if(trigger["use_"..name] == false) then -- multi selection
    test = "(";
    local any = false;
    if trigger[name] and trigger[name].multi then
      for value, _ in pairs(trigger[name].multi) do
        if not arg.test then
          test = test..name.."=="..(tonumber(value) or ("[["..value.."]]")).." or ";
        else
          test = test..arg.test:format(tonumber(value) or ("[["..value.."]]")).." or ";
        end
        any = true;
      end
    end
    if(any) then
      test = test:sub(1, -5);
    else
      test = "(false";
    end
    test = test..")";
  elseif(trigger["use_"..name]) then -- single selection
    local value = trigger[name] and trigger[name].single;
    if (not value) then
      test = "false";
      return test;
    end
    if not arg.test then
      test = trigger[name].single and "("..name.."=="..(tonumber(value) or ("[["..value.."]]"))..")";
    else
      test = trigger[name].single and "("..arg.test:format(tonumber(value) or ("[["..value.."]]"))..")";
    end
  end
  return test;
end

local function singleTest(arg, trigger, name, value, operator, use_exact)
  local number = tonumber(value)
  if(arg.type == "tristate") then
    return TestForTriState(trigger, arg);
  elseif(arg.type == "multiselect") then
    return TestForMultiSelect(trigger, arg);
  elseif(arg.type == "toggle") then
    return TestForToggle(trigger, arg);
  elseif (arg.type == "spell" or arg.type == "item") then
    if arg.test then
      if arg.showExactOption then
        return "("..arg.test:format(value, tostring(use_exact) or "false") ..")";
      else
        return "("..arg.test:format(value)..")";
      end
    else
      return "(".. name .." and "..name.."==" ..(number or ("\""..(tostring(value) or "").."\""))..")";
    end
  elseif(arg.test) then
    return "("..arg.test:format(tostring(value) or "")..")";
  elseif(arg.type == "longstring" and operator) then
    return TestForLongString(trigger, arg);
  elseif (arg.type == "string" or arg.type == "select") then
    return "(".. name .." and "..name.."==" ..(number or ("\""..(tostring(value) or "").."\""))..")";
  elseif (arg.type == "number") then
    return "(".. name .." and "..name..(operator or "==")..(number or 0) ..")";
  else
    -- Should be unused
    return "(".. name .." and "..name..(operator or "==")..(number or ("\""..(tostring(value) or 0).."\""))..")";
  end
end

function ConstructTest(trigger, arg, testGroups, preambleGroups)
  local test
  local preamble
  local name = arg.name;

  if arg.preamble then
    if not arg.preambleGroup or not preambleGroups[arg.preambleGroup] then
      preamble = arg.preamble:format(trigger[name] or "")
    end
    if arg.preambleGroup then
      preambleGroups[arg.preambleGroup] = true
    end
  end

  if arg.hidden
    or arg.type == "tristate"
    or arg.type == "toggle"
    or (arg.type == "multiselect" and trigger["use_"..name] ~= nil)
    or ((trigger["use_"..name] or arg.required) and trigger[name])
  then
    if arg.multiEntry then
      if type(trigger[name]) == "table" and #trigger[name] > 0 then
        test = ""
        for i, value in ipairs(trigger[name]) do
          local operator = name and type(trigger[name.."_operator"]) == "table" and trigger[name.."_operator"][i]
          local use_exact = name and type(trigger["use_exact_" .. name]) == "table" and trigger["use_exact_" .. name][i]

          if arg.multiEntry.operator == "preamble" then
            preamble = preamble and (preamble .. "\n") or ""
            preamble = preamble .. arg.multiEntry.preambleAdd:format(value)
          else
            local single = singleTest(arg, trigger, name, value, operator, use_exact)
            if single then
              if test ~= "" then
                test = test .. arg.multiEntry.operator
              end
              test = test .. single
            end
          end
        end

        if arg.multiEntry.operator == "preamble" then
          test = arg.test
        end

        if test == "" then
          test = nil
        else
          test = "(" .. test .. ")"
        end
      end
    else
      local value = trigger[name]
      local operator = name and trigger[name.."_operator"]
      local use_exact = name and trigger["use_exact_" .. name]
      test = singleTest(arg, trigger, name, value, operator, use_exact)
    end
  end

  if not test or test == "(true)" or arg.testGroup and testGroups[arg.testGroup] then
    return nil, preamble
  end

  return test, preamble
end

function ConstructFunction(prototype, trigger)
  if (prototype.triggerFunction) then
    return prototype.triggerFunction(trigger);
  end

  local input;
  if (prototype.statesParameter) then
    if prototype.countEvents then
      input = {"state", "counter", "event"};
    else
      input = {"state", "event"};
    end
  else
    if prototype.countEvents then
      input = {"counter", "event"};
    else
      input = {"event"};
    end
  end

  local required = {};
  local tests = {};
  local debug = {};
  local store = {};
  local init;
  local preambles = "\n"
  local orConjunctionGroups = {}
  local preambleGroups = {}
  local testGroups = {}
  if(prototype.init) then
    init = prototype.init(trigger);
  else
    init = "";
  end
  for index, arg in pairs(prototype.args) do
    local enable = arg.type ~= "description";
    if(type(arg.enable) == "function") then
      enable = arg.enable(trigger);
    elseif type(arg.enable) == "boolean" then
      enable = arg.enable
    end
    if(enable) then
      local name = arg.name;
      if not(arg.name or arg.hidden) then
        tinsert(input, "_");
      else
        if(arg.init == "arg") then
          tinsert(input, name);
        elseif(arg.init) then
          init = init.."local "..name.." = "..arg.init.."\n";
        end
        if (arg.store) then
          tinsert(store, name);
        end
        local test, preamble = ConstructTest(trigger, arg, testGroups, preambleGroups);
        if (test) then
          if(arg.required) then
            tinsert(required, test);
          else
            if arg.orConjunctionGroup then
              orConjunctionGroups[arg.orConjunctionGroup] = orConjunctionGroups[arg.orConjunctionGroup] or {}
              tinsert(orConjunctionGroups[arg.orConjunctionGroup], test)
            else
              tinsert(tests, test);
            end
          end
          if(arg.debug) then
            tinsert(debug, arg.debug:format(trigger[name]));
          end
        end
        if (preamble) then
          preambles = preambles .. preamble .. "\n"
        end
      end
    end
  end

  for _, orConjunctionGroup in pairs(orConjunctionGroups) do
    tinsert(tests, "("..table.concat(orConjunctionGroup, " or ")..")")
  end

  local ret = preambles .. "return function("..tconcat(input, ", ")..")\n";
  ret = ret..(init or "");

  ret = ret..(#debug > 0 and tconcat(debug, "\n") or "");

  ret = ret.."if(";
  ret = ret..((#required > 0) and tconcat(required, " and ").." and " or "");
  ret = ret..(#tests > 0 and tconcat(tests, " and ") or "true");
  ret = ret..") then\n";
  if(#debug > 0) then
    ret = ret.."print('ret: true');\n";
  end

  if (prototype.statesParameter == "all") then
    ret = ret .. "  state[cloneId] = state[cloneId] or {}\n"
    ret = ret .. "  state = state[cloneId]\n"
    ret = ret .. "  state.changed = true\n"
  end

  if prototype.countEvents then
    ret = ret .. "  local count = counter:GetNext()\n"
    if trigger.use_count and type(trigger.count) == "string" and trigger.count ~= "" then
      ret = ret .. "  local match = counter:Match()"
      ret = ret .. "  if not match then return false end\n"
    end
    ret = ret .. "  state.count = count\n"
    ret = ret .. "  state.changed = true\n"
  end

  for _, v in ipairs(store) do
    ret = ret .. "    if (state." .. v .. " ~= " .. v .. ") then\n"
    ret = ret .. "      state." .. v .. " = " .. v .. "\n"
    ret = ret .. "      state.changed = true\n"
    ret = ret .. "    end\n"
  end
  ret = ret.."return true else return false end end";

  return ret;
end

function Private.EndEvent(state)
  if state then
    if (state.show ~= false and state.show ~= nil) then
      state.show = false;
      state.changed = true;
    end
    return state.changed;
  else
    return false
  end
end

local function RunOverlayFuncs(event, state, id, errorHandler)
  state.additionalProgress = state.additionalProgress or {};
  local changed = false;
  for i, overlayFunc in ipairs(event.overlayFuncs) do
    state.additionalProgress[i] = state.additionalProgress[i] or {};
    local additionalProgress = state.additionalProgress[i];
    local ok, a, b, c = xpcall(overlayFunc, errorHandler or Private.GetErrorHandlerId(id, L["Overlay %s"]:format(i)), event.trigger, state);
    if (not ok) then
      additionalProgress.min = nil;
      additionalProgress.max = nil;
      additionalProgress.direction = nil;
      additionalProgress.width = nil;
      additionalProgress.offset = nil;
    elseif (type(a) == "string") then
      if (additionalProgress.direction ~= a) then
        additionalProgress.direction = a;
        changed = true;
      end
      if (additionalProgress.width ~= b) then
        additionalProgress.width = b;
        changed = true;
      end
      if (additionalProgress.offset ~= c) then
        additionalProgress.offset = c;
        changed = true;
      end
      additionalProgress.min = nil;
      additionalProgress.max = nil;
    else
      if (additionalProgress.min ~= a) then
        additionalProgress.min = a;
        changed = true;
      end
      if (additionalProgress.max ~= b) then
        additionalProgress.max = b;
        changed = true;
      end
      if additionalProgress.direction then
        changed = true
      end
      additionalProgress.direction = nil;
      additionalProgress.width = nil;
      additionalProgress.offset = nil;
    end

  end
  state.changed = changed or state.changed;
end

local function callFunctionForActivateEvent(func, trigger, state, property, errorHandler)
  if not func then
    return
  end
  local ok, value = xpcall(func, errorHandler, trigger)
  if ok then
    if state[property] ~= value then
      state[property] = value
      state.changed = true
    end
  end
end

---@type fun(id, triggernum, data, state, errorHandler)
---@return state
function Private.ActivateEvent(id, triggernum, data, state, errorHandler)
  local changed = state.changed or false;
  if (state.show ~= true) then
    state.show = true;
    changed = true;
  end
  if (data.duration) then
    local expirationTime = GetTime() + data.duration;
    if (state.expirationTime ~= expirationTime) then
      state.expirationTime = expirationTime;
      changed = true;
    end
    if (state.duration ~= data.duration) then
      state.duration = data.duration;
      changed = true;
    end
    if (state.progressType ~= "timed") then
      state.progressType = "timed";
      changed = true;
    end
    local autoHide = data.automaticAutoHide;
    if (state.value or state.total or state.inverse or state.autoHide ~= autoHide) then
      changed = true;
    end
    state.value = nil;
    state.total = nil;
    state.inverse = nil;
    state.autoHide = autoHide;
  elseif (data.durationFunc) then
    local ok, arg1, arg2, arg3, inverse = xpcall(data.durationFunc, errorHandler or Private.GetErrorHandlerId(id, L["Duration Function"]), data.trigger);
    arg1 = ok and type(arg1) == "number" and arg1 or 0;
    arg2 = ok and type(arg2) == "number" and arg2 or 0;


    if (state.inverse ~= inverse) then
      state.inverse = inverse;
      changed = true;
    end

    if (arg3) then
      if (state.progressType ~= "static") then
        state.progressType = "static";
        changed = true;
      end
      if (state.duration) then
        state.duration = nil;
        changed = true;
      end
      if (state.expirationTime) then
        state.expirationTime = nil;
        changed = true;
      end

      local autoHide = nil;
      if (state.autoHide ~= autoHide) then
        changed = true;
        state.autoHide = autoHide;
      end

      if (state.value ~= arg1) then
        state.value = arg1;
        changed = true;
      end
      if (state.total ~= arg2) then
        state.total = arg2;
        changed = true;
      end
    else
      if (state.progressType ~= "timed") then
        state.progressType = "timed";
        changed = true;
      end
      if (state.duration ~= arg1) then
        state.duration = arg1;
      end
      -- The Icon's SetCooldown requires that the **startTime** is positive, so ensure that
      -- the expirationTime is bigger than the duration
      if arg2 <= arg1 then
        arg2 = arg1
      end
      if (state.expirationTime ~= arg2) then
        state.expirationTime = arg2;
        changed = true;
      end
      local autoHide = data.automaticAutoHide and arg1 > 0.01;
      if (state.autoHide ~= autoHide) then
        changed = true;
        state.autoHide = autoHide;
      end
      if (state.value or state.total) then
        changed = true;
      end
      state.value = nil;
      state.total = nil;
    end
  end

  callFunctionForActivateEvent(data.nameFunc, data.trigger, state, "name", errorHandler or Private.GetErrorHandlerId(id, L["Name Function"]))
  callFunctionForActivateEvent(data.iconFunc, data.trigger, state, "icon", errorHandler or Private.GetErrorHandlerId(id, L["Icon Function"]))
  callFunctionForActivateEvent(data.textureFunc, data.trigger, state, "texture", errorHandler or Private.GetErrorHandlerId(id, L["Texture Function"]))
  callFunctionForActivateEvent(data.stacksFunc, data.trigger, state, "stacks", errorHandler or Private.GetErrorHandlerId(id, L["Stacks Function"]))

  if (data.overlayFuncs) then
    RunOverlayFuncs(data, state, id, errorHandler);
  end

  state.changed = state.changed or changed;

  return state.changed;
end

local function ignoreErrorHandler()

end

local function RunTriggerFunc(allStates, data, id, triggernum, event, arg1, arg2, ...)
  local optionsEvent = event == "OPTIONS";
  local errorHandler = (optionsEvent and data.ignoreOptionsEventErrors) and ignoreErrorHandler or Private.GetErrorHandlerId(id, L["Trigger %s"]:format(triggernum))
  local updateTriggerState = false;

  local unitForUnitTrigger
  local cloneIdForUnitTrigger

  if(data.triggerFunc) then
    local untriggerCheck = false;
    if (data.statesParameter == "full") then
      local ok, returnValue
      if data.counter then
        ok, returnValue = xpcall(data.triggerFunc, errorHandler, allStates, data.counter, event, arg1, arg2, ...);
      else
        ok, returnValue = xpcall(data.triggerFunc, errorHandler, allStates, event, arg1, arg2, ...);
      end
      if (ok and returnValue) then
        updateTriggerState = true;
      end
      for key, state in pairs(allStates) do
        if (type(state) ~= "table") then
          errorHandler(string.format(L["All States table contains a non table at key: '%s'."], key))
          wipe(allStates)
          return
        end
      end
    elseif (data.statesParameter == "all") then
      local ok, returnValue
      if data.counter then
        ok, returnValue = xpcall(data.triggerFunc, errorHandler, allStates, data.counter, event, arg1, arg2, ...);
      else
        ok, returnValue = xpcall(data.triggerFunc, errorHandler, allStates, event, arg1, arg2, ...);
      end
      if( (ok and returnValue) or optionsEvent) then
        for id, state in pairs(allStates) do
          if (state.changed) then
            if (Private.ActivateEvent(id, triggernum, data, state)) then
              updateTriggerState = true;
            end
          end
        end
      else
        untriggerCheck = true;
      end
    elseif (data.statesParameter == "unit") then
      if arg1 then
        if Private.multiUnitUnits[data.trigger.unit] then
          unitForUnitTrigger = arg1
          cloneIdForUnitTrigger = arg1
        else
          unitForUnitTrigger = data.trigger.unit
          cloneIdForUnitTrigger = ""
        end
        allStates[cloneIdForUnitTrigger] = allStates[cloneIdForUnitTrigger] or {};
        local state = allStates[cloneIdForUnitTrigger];
        local ok, returnValue
        if data.counter then
          ok, returnValue = xpcall(data.triggerFunc, errorHandler, state, data.counter, event, unitForUnitTrigger, arg1, arg2, ...);
        else
          ok, returnValue = xpcall(data.triggerFunc, errorHandler, state, event, unitForUnitTrigger, arg1, arg2, ...);
        end
        if (ok and returnValue) or optionsEvent then
          if(Private.ActivateEvent(id, triggernum, data, state)) then
            updateTriggerState = true;
          end
        else
          untriggerCheck = true;
        end
      end
    elseif (data.statesParameter == "one") then
      allStates[""] = allStates[""] or {};
      local state = allStates[""];
      local ok, returnValue
      if data.counter then
        ok, returnValue = xpcall(data.triggerFunc, errorHandler, state, data.counter, event, arg1, arg2, ...);
      else
        ok, returnValue = xpcall(data.triggerFunc, errorHandler, state, event, arg1, arg2, ...);
      end
      if (ok and returnValue) or optionsEvent then
        if(Private.ActivateEvent(id, triggernum, data, state, (optionsEvent and data.ignoreOptionsEventErrors) and ignoreErrorHandler or nil)) then
          updateTriggerState = true;
        end
      else
        untriggerCheck = true;
      end
    else
      local ok, returnValue
      if data.counter then
        ok, returnValue = xpcall(data.triggerFunc, errorHandler, data.counter, event, arg1, arg2, ...);
      else
        ok, returnValue = xpcall(data.triggerFunc, errorHandler, event, arg1, arg2, ...);
      end
      if (ok and returnValue) or optionsEvent then
        allStates[""] = allStates[""] or {};
        local state = allStates[""];
        if(Private.ActivateEvent(id, triggernum, data, state, (optionsEvent and data.ignoreOptionsEventErrors) and ignoreErrorHandler or nil)) then
          updateTriggerState = true;
        end
      else
        untriggerCheck = true;
      end
    end
    if (untriggerCheck and not optionsEvent) then
      errorHandler = (optionsEvent and data.ignoreOptionsEventErrors) and ignoreErrorHandler or Private.GetErrorHandlerId(id, L["Untrigger %s"]:format(triggernum))
      if (data.statesParameter == "all") then
        if data.untriggerFunc then
          local ok, returnValue = xpcall(data.untriggerFunc, errorHandler, allStates, event, arg1, arg2, ...);
          if ok and returnValue then
            for id, state in pairs(allStates) do
              if (state.changed) then
                if (Private.EndEvent(state)) then
                  updateTriggerState = true;
                end
              end
            end
          end
        end
      elseif data.statesParameter == "unit" then
        if data.untriggerFunc then
          if arg1 then
            local state = allStates[cloneIdForUnitTrigger]
            if state then
              local ok, returnValue =  xpcall(data.untriggerFunc, errorHandler, state, event, unitForUnitTrigger, arg1, arg2, ...);
              if ok and returnValue then
                if (Private.EndEvent(state)) then
                  updateTriggerState = true;
                end
              end
            end
          end
        end
        if not updateTriggerState and not allStates[cloneIdForUnitTrigger].show then
          -- We added this state automatically, but the trigger didn't end up using it,
          -- so remove it again
          allStates[cloneIdForUnitTrigger] = nil
        end
      elseif (data.statesParameter == "one") then
        allStates[""] = allStates[""] or {};
        local state = allStates[""];
        if data.untriggerFunc then
          local ok, returnValue = xpcall(data.untriggerFunc, errorHandler, state, event, arg1, arg2, ...);
          if (ok and returnValue) then
            if (Private.EndEvent(state)) then
              updateTriggerState = true;
            end
          end
        end
      else
        if data.untriggerFunc then
          local ok, returnValue = xpcall(data.untriggerFunc, errorHandler, event, arg1, arg2, ...);
          if ok and returnValue then
            allStates[""] = allStates[""] or {};
            local state = allStates[""];
            if(Private.EndEvent(state)) then
              updateTriggerState = true;
            end
          end
        end
      end
    end
  end
  if updateTriggerState and watched_trigger_events[id] and watched_trigger_events[id][triggernum] then
    -- if this trigger's updates are requested to be sent into one of the Aura's custom triggers
    Private.AddToWatchedTriggerDelay(id, triggernum)
  end
  return updateTriggerState;
end

---@param event string
---@param arg1? any
---@param arg2? any
---@param ... any
function WeakAuras.ScanEvents(event, arg1, arg2, ...)
  local orgEvent = event;
  Private.StartProfileSystem("generictrigger " .. orgEvent )
  local event_list = loaded_events[event];
  if (not event_list) then
    Private.StopProfileSystem("generictrigger " .. orgEvent )
    return
  end
  if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
    local arg1, arg2 = CombatLogGetCurrentEventInfo();

    event_list = event_list[arg2];
    if (not event_list) then
      Private.StopProfileSystem("generictrigger " .. orgEvent )
      return;
    end
    WeakAuras.ScanEventsInternal(event_list, event, CombatLogGetCurrentEventInfo());

  elseif (event == "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM") then
    -- This reverts the COMBAT_LOG_EVENT_UNFILTERED_CUSTOM workaround so that custom triggers that check the event argument will work as expected
    if(event == "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM") then
      event = "COMBAT_LOG_EVENT_UNFILTERED";
    end
    WeakAuras.ScanEventsInternal(event_list, event, CombatLogGetCurrentEventInfo());
  else
    WeakAuras.ScanEventsInternal(event_list, event, arg1, arg2, ...);
  end
  Private.StopProfileSystem("generictrigger " .. orgEvent )
end

---@param event string
---@param unit UnitToken
---@param ... any
function WeakAuras.ScanUnitEvents(event, unit, ...)
  Private.StartProfileSystem("generictrigger " .. event .. " " .. unit)
  local unit_list = loaded_unit_events[unit]
  if unit_list then
    local event_list = unit_list[event]
    if event_list then
      for id, triggers in pairs(event_list) do
        Private.StartProfileAura(id);
        Private.ActivateAuraEnvironment(id);
        local updateTriggerState = false;
        for triggernum, data in pairs(triggers) do
          local delay = GenericTrigger.GetDelay(data)
          if delay == 0 then
            local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
            if (RunTriggerFunc(allStates, data, id, triggernum, event, unit, ...)) then
              updateTriggerState = true;
            end
          else
            Private.RunTriggerFuncWithDelay(delay, id, triggernum, data, event, unit, ...)
          end
        end
        if (updateTriggerState) then
          Private.UpdatedTriggerState(id);
        end
        Private.StopProfileAura(id);
        Private.ActivateAuraEnvironment(nil);
      end
    end
  end
  Private.StopProfileSystem("generictrigger " .. event .. " " .. unit)
end

---@private
---@param event_list table<string>
---@param event string
---@param arg1? any
---@param arg2? any
---@param ... any
function WeakAuras.ScanEventsInternal(event_list, event, arg1, arg2, ... )
  for id, triggers in pairs(event_list) do
    Private.StartProfileAura(id);
    Private.ActivateAuraEnvironment(id);
    local updateTriggerState = false;
    for triggernum, data in pairs(triggers) do
      local delay = GenericTrigger.GetDelay(data)
      if delay == 0 then
        local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
        if (RunTriggerFunc(allStates, data, id, triggernum, event, arg1, arg2, ...)) then
          updateTriggerState = true
        end
      else
        Private.RunTriggerFuncWithDelay(delay, id, triggernum, data, event, arg1, arg2, ...)
      end
    end
    if (updateTriggerState) then
      Private.UpdatedTriggerState(id);
    end
    Private.StopProfileAura(id);
    Private.ActivateAuraEnvironment(nil);
  end
end

do
  local function RunTriggerFuncForDelay(id, triggernum, data, event, ...)
    Private.StartProfileAura(id)
    Private.ActivateAuraEnvironment(id)
    local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum)
    if (RunTriggerFunc(allStates, data, id, triggernum, event, ...)) then
      Private.UpdatedTriggerState(id)
    end
    Private.StopProfileAura(id)
    Private.ActivateAuraEnvironment(nil)
    -- clear expired timers
    for i, t in ipairs_reverse(delayTimerEvents[id][triggernum]) do
      if t.ends <= GetTime() then
        table.remove(delayTimerEvents[id][triggernum], i)
      end
    end
  end

  ---@type fun(delay, id, triggernum, data, event, ...)
  function Private.RunTriggerFuncWithDelay(delay, id, triggernum, data, event, ...)
    delayTimerEvents[id] = delayTimerEvents[id] or {}
    delayTimerEvents[id][triggernum] = delayTimerEvents[id][triggernum] or {}
    local timerId = timer:ScheduleTimer(RunTriggerFuncForDelay, delay, id, triggernum, data, event, ...)
    tinsert(delayTimerEvents[id][triggernum], timerId)
  end
end

---@type fun(id)
function Private.CancelDelayedTrigger(id)
  if delayTimerEvents[id] then
    for triggernum, timers in pairs(delayTimerEvents[id]) do
      for _, timerId in ipairs(timers) do
        timer:CancelTimer(timerId)
      end
    end
    delayTimerEvents[id] = nil
  end
end

---@type fun()
function Private.CancelAllDelayedTriggers()
  for id in pairs(delayTimerEvents) do
    Private.CancelDelayedTrigger(id)
  end
end

---@type fun(id, watchedTriggernums)
function Private.ScanEventsWatchedTrigger(id, watchedTriggernums)
  if #watchedTriggernums == 0 then return end
  Private.StartProfileAura(id);
  Private.ActivateAuraEnvironment(id);
  local updateTriggerState = false

  for _, watchedTrigger in ipairs(watchedTriggernums) do
    if watched_trigger_events[id] and watched_trigger_events[id][watchedTrigger] then
      local updatedTriggerStates = WeakAuras.GetTriggerStateForTrigger(id, watchedTrigger)
      for observerTrigger in pairs(watched_trigger_events[id][watchedTrigger]) do
        local data = events and events[id] and events[id][observerTrigger]
        local allstates = WeakAuras.GetTriggerStateForTrigger(id, observerTrigger)
        if data and allstates and updatedTriggerStates then
          if RunTriggerFunc(allstates, data, id, observerTrigger, "TRIGGER", watchedTrigger, updatedTriggerStates) then
            updateTriggerState = true
          end
        end
      end
    end
  end
  if (updateTriggerState) then
    Private.UpdatedTriggerState(id)
  end
  Private.StopProfileAura(id)
  Private.ActivateAuraEnvironment(nil)
end

---@type fun(data: auraData, triggernum: number) : "timed"|boolean, boolean?
local function ProgressType(data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  local prototype = GenericTrigger.GetPrototype(trigger)
  if prototype then
    if prototype.progressType then
      local progressType = prototype.progressType
      if type(progressType) == "function" then
        progressType = progressType(trigger)
      end
      return progressType, prototype.useModRate
    elseif prototype.timedrequired then
      return "timed"
    end
  elseif (trigger.type == "custom") then
    if trigger.custom_type == "event" and trigger.custom_hide == "timed" and trigger.duration then
      return "timed";
    elseif (trigger.customDuration and trigger.customDuration ~= "") then
      return "timed";
    elseif (trigger.custom_type == "stateupdate") then
      return false
    end
  end
  return false
end

---@type fun(data: auraData, triggernum: integer, state: state, eventData: table)
local function AddFakeInformation(data, triggernum, state, eventData)
  state.autoHide = false
  if ProgressType(data, triggernum) == "timed" and state.expirationTime == nil then
    state.progressType = "timed"
  end
  if state.progressType == "timed" then
    if state.expirationTime and state.expirationTime ~= math.huge and state.expirationTime > GetTime() then
      return
    end
    state.progressType = "timed"
    state.expirationTime = GetTime() + 7
    state.duration = 7
  end
  if eventData.prototype and eventData.prototype.GetNameAndIcon then
    local name, icon = eventData.prototype.GetNameAndIcon(eventData.trigger)
    if state.name == nil then
      state.name = name
    end
    if state.icon == nil then
      state.icon = icon
    end
  end
end

---@type fun(id: auraId, triggernum: integer)
function GenericTrigger.CreateFakeStates(id, triggernum)
  local data = WeakAuras.GetData(id)
  local eventData = events[id][triggernum]

  Private.ActivateAuraEnvironment(id);
  local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);

  local arg1
  if eventData.statesParameter == "unit" then
    local unit = eventData.trigger.unit
    if Private.multiUnitUnits[unit] then
      arg1 = next(Private.multiUnitUnits[unit])
    else
      arg1 = unit
    end
  end

  RunTriggerFunc(allStates, eventData, id, triggernum, "OPTIONS", arg1)

  local shown = 0
  for id, state in pairs(allStates) do
    if state.show then
      shown = shown + 1
    end

    AddFakeInformation(data, triggernum, state, eventData)
  end

  if shown == 0 then
    local state = {}
    GenericTrigger.CreateFallbackState(data, triggernum, state)
    allStates[""] = state

    AddFakeInformation(data, triggernum, state, eventData)
  end

  Private.ActivateAuraEnvironment(nil);
end

function GenericTrigger.ScanWithFakeEvent(id, fake)
  local updateTriggerState = false;
  Private.ActivateAuraEnvironment(id);
  for triggernum, event in pairs(events[id] or {}) do
    local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
    if (event.force_events) then
      if (type(event.force_events) == "string") then
        updateTriggerState = RunTriggerFunc(allStates, events[id][triggernum], id, triggernum, event.force_events) or updateTriggerState;
      elseif (type(event.force_events) == "table") then
        for index, event_args in pairs(event.force_events) do
          updateTriggerState = RunTriggerFunc(allStates, events[id][triggernum], id, triggernum, unpack(event_args)) or updateTriggerState;
        end
      elseif (type(event.force_events) == "boolean" and event.force_events) then
        for i, eventName in pairs(event.events) do
          if eventName == "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM" then
            eventName = "COMBAT_LOG_EVENT_UNFILTERED"
          end
          updateTriggerState = RunTriggerFunc(allStates, events[id][triggernum], id, triggernum, eventName) or updateTriggerState;
        end
        for unit, unitData in pairs(event.unit_events) do
          for _, event in ipairs(unitData) do
            updateTriggerState = RunTriggerFunc(allStates, events[id][triggernum], id, triggernum, event, unit) or updateTriggerState
          end
        end
      end
    end
  end

  if (updateTriggerState) then
    Private.UpdatedTriggerState(id);
  end
  Private.ActivateAuraEnvironment(nil);
end

function HandleEvent(frame, event, arg1, arg2, ...)
  Private.StartProfileSystem("generictrigger " .. event);
  if event == "NAME_PLATE_UNIT_ADDED" then
    nameplateExists[arg1] = true
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    nameplateExists[arg1] = false
  end

  if not(WeakAuras.IsPaused()) then
    if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
      WeakAuras.ScanEvents(event);
      -- This triggers the scanning of "hacked" COMBAT_LOG_EVENT_UNFILTERED events that were renamed in order to circumvent
      -- the "proper" COMBAT_LOG_EVENT_UNFILTERED checks
      WeakAuras.ScanEvents("COMBAT_LOG_EVENT_UNFILTERED_CUSTOM");
    else
      WeakAuras.ScanEvents(event, arg1, arg2, ...);
    end
  end
  if (event == "PLAYER_ENTERING_WORLD") then
    timer:ScheduleTimer(function()
      Private.StartProfileSystem("generictrigger WA_DELAYED_PLAYER_ENTERING_WORLD");
      HandleEvent(frame, "WA_DELAYED_PLAYER_ENTERING_WORLD", arg1, arg2)
      Private.CheckCooldownReady();
      Private.StopProfileSystem("generictrigger WA_DELAYED_PLAYER_ENTERING_WORLD");
      Private.PreShowModels()
      if WeakAuras.IsRetail() then
        Private.CheckTalentsForLoad("WA_DELAYED_PLAYER_ENTERING_WORLD")
      end
    end,
    0.8);  -- Data not available

    timer:ScheduleTimer(function()
      Private.PreShowModels()
    end,
    4);  -- Data not available
  end
  Private.StopProfileSystem("generictrigger " .. event);
end

function HandleUnitEvent(frame, event, unit, ...)
  Private.StartProfileSystem("generictrigger " .. event .. " " .. unit);
  if not(WeakAuras.IsPaused()) then
    if (UnitIsUnit(unit, frame.unit)) then
      WeakAuras.ScanUnitEvents(event, frame.unit, ...);
    end
  end
  Private.StopProfileSystem("generictrigger " .. event .. " " .. unit);
end

function GenericTrigger.UnloadAll()
  wipe(loaded_auras);
  wipe(loaded_events);
  wipe(loaded_unit_events);
  Private.CancelAllDelayedTriggers();
  Private.UnregisterAllEveryFrameUpdate();
end

function GenericTrigger.UnloadDisplays(toUnload)
  for id in pairs(toUnload) do
    loaded_auras[id] = false;
    for eventname, events in pairs(loaded_events) do
      if(eventname == "COMBAT_LOG_EVENT_UNFILTERED") then
        for subeventname, subevents in pairs(events) do
          subevents[id] = nil;
        end
      else
        events[id] = nil;
      end
    end
    for unit, events in pairs(loaded_unit_events) do
      for eventname, auras in pairs(events) do
        auras[id] = nil;
      end
    end

    Private.CancelDelayedTrigger(id);
    Private.UnregisterEveryFrameUpdate(id);
  end
end

local genericTriggerRegisteredEvents = {};
local genericTriggerRegisteredUnitEvents = {};

---@class WeakAurasGenericTriggerFrame: FrameScriptObject
local frame = CreateFrame("Frame");
frame.unitFrames = {};
Private.frames["WeakAuras Generic Trigger Frame"] = frame;
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
genericTriggerRegisteredEvents["PLAYER_ENTERING_WORLD"] = true;
genericTriggerRegisteredEvents["NAME_PLATE_UNIT_ADDED"] = true;
genericTriggerRegisteredEvents["NAME_PLATE_UNIT_REMOVED"] = true;
frame:SetScript("OnEvent", HandleEvent);

function GenericTrigger.Delete(id)
  GenericTrigger.UnloadDisplays({[id] = true});
end

function GenericTrigger.Rename(oldid, newid)
  events[newid] = events[oldid];
  events[oldid] = nil;

  for eventname, events in pairs(loaded_events) do
    if(eventname == "COMBAT_LOG_EVENT_UNFILTERED") then
      for subeventname, subevents in pairs(events) do
        subevents[oldid] = subevents[newid];
        subevents[oldid] = nil;
      end
    else
      events[newid] = events[oldid];
      events[oldid] = nil;
    end
  end

  for unit, events in pairs(loaded_unit_events) do
    for eventname, auras in pairs(events) do
      auras[newid] = auras[oldid]
      auras[oldid] = nil
    end
  end

  watched_trigger_events[newid] = watched_trigger_events[oldid]
  watched_trigger_events[oldid] = nil

  Private.EveryFrameUpdateRename(oldid, newid)
end

local function MultiUnitLoop(Func, unit, includePets, ...)
  unit = string.lower(unit)
  if unit == "boss" then
    for i = 1, 10 do
      Func(unit..i, ...)
    end
  elseif unit == "arena" then
    for i = 1, 5 do
      Func(unit..i, ...)
    end
  elseif unit == "nameplate" then
    for i = 1, 40 do
      Func(unit..i, ...)
    end
  elseif unit == "group" then
    if includePets ~= "PetsOnly" then
      Func("player", ...)
    end
    if includePets ~= nil then
      Func("pet", ...)
    end
    for i = 1, 4 do
      if includePets ~= "PetsOnly" then
        Func("party"..i, ...)
      end
      if includePets ~= nil then
        Func("partypet"..i, ...)
      end
    end
    for i = 1, 40 do
      if includePets ~= "PetsOnly" then
        Func("raid"..i, ...)
      end
      if includePets ~= nil then
        Func("raidpet"..i, ...)
      end
    end
  elseif unit == "party" then
    if includePets ~= "PetsOnly" then
      Func("player", ...)
    end
    if includePets ~= nil then
      Func("pet", ...)
    end
    for i = 1, 4 do
      if includePets ~= "PetsOnly" then
        Func("party"..i, ...)
      end
      if includePets ~= nil then
        Func("partypet"..i, ...)
      end
    end
  elseif unit == "raid" then
    for i = 1, 40 do
      if includePets ~= "PetsOnly" then
        Func("raid"..i, ...)
      end
      if includePets ~= nil then
        Func("raidpet"..i, ...)
      end
    end
  else
    Func(unit, ...)
  end
end

function LoadEvent(id, triggernum, data)
  if data.events then
    for index, event in pairs(data.events) do
      loaded_events[event] = loaded_events[event] or {};
      if(event == "COMBAT_LOG_EVENT_UNFILTERED" and data.subevents) then
        for i, subevent in pairs(data.subevents) do
          loaded_events[event][subevent] = loaded_events[event][subevent] or {};
          loaded_events[event][subevent][id] = loaded_events[event][subevent][id] or {}
          loaded_events[event][subevent][id][triggernum] = data;
        end
      else
        loaded_events[event][id] = loaded_events[event][id] or {};
        loaded_events[event][id][triggernum] = data;
      end
    end
  end
  if (data.internal_events) then
    for index, event in pairs(data.internal_events) do
      loaded_events[event] = loaded_events[event] or {};
      loaded_events[event][id] = loaded_events[event][id] or {};
      loaded_events[event][id][triggernum] = data;
    end
  end
  if data.unit_events then
    local includePets = data.includePets
    for unit, events in pairs(data.unit_events) do
      unit = string.lower(unit)
      for index, event in pairs(events) do
        MultiUnitLoop(
          function(u)
            loaded_unit_events[u] = loaded_unit_events[u] or {};
            loaded_unit_events[u][event] = loaded_unit_events[u][event] or {};
            loaded_unit_events[u][event][id] = loaded_unit_events[u][event][id] or {}
            loaded_unit_events[u][event][id][triggernum] = data;
          end, unit, includePets
        )
      end
    end
  end

  if (data.loadFunc) then
    data.loadFunc(data.trigger);
  end
end

local function trueFunction()
  return true;
end

local eventsToRegister = {};
local unitEventsToRegister = {};
function GenericTrigger.LoadDisplays(toLoad, loadEvent, ...)
  for id in pairs(toLoad) do
    local register_for_frame_updates = false;
    if(events[id]) then
      loaded_auras[id] = true;
      for triggernum, data in pairs(events[id]) do
        if data.events then
          for index, event in pairs(data.events) do
            if (event == "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM") then
              if not genericTriggerRegisteredEvents["COMBAT_LOG_EVENT_UNFILTERED"] then
                eventsToRegister["COMBAT_LOG_EVENT_UNFILTERED"] = true;
              end
            elseif (event == "FRAME_UPDATE") then
              register_for_frame_updates = true;
            else
              if (genericTriggerRegisteredEvents[event]) then
                -- Already registered event
              else
                eventsToRegister[event] = true;
              end
            end
          end
        end
        if data.unit_events then
          local includePets = data.includePets
          for unit, events in pairs(data.unit_events) do
            for index, event in pairs(events) do
              MultiUnitLoop(
                function (u)
                  if not (genericTriggerRegisteredUnitEvents[u] and genericTriggerRegisteredUnitEvents[u][event]) then
                    unitEventsToRegister[u] = unitEventsToRegister[u] or {}
                    unitEventsToRegister[u][event] = true
                  end
                end, unit, includePets
              )
            end
          end
        end

        if data.counter then
          data.counter:Reset()
        end

        LoadEvent(id, triggernum, data);
      end
    end

    if(register_for_frame_updates) then
      Private.RegisterEveryFrameUpdate(id);
    else
      Private.UnregisterEveryFrameUpdate(id);
    end
  end

  for event in pairs(eventsToRegister) do
    xpcall(frame.RegisterEvent, trueFunction, frame, event)
    genericTriggerRegisteredEvents[event] = true;
  end

  for unit, events in pairs(unitEventsToRegister) do
    for event in pairs(events) do
      if not frame.unitFrames[unit] then
        frame.unitFrames[unit] = CreateFrame("Frame")
        frame.unitFrames[unit].unit = unit
        frame.unitFrames[unit]:SetScript("OnEvent", HandleUnitEvent);
      end
      xpcall(frame.unitFrames[unit].RegisterUnitEvent, trueFunction, frame.unitFrames[unit], event, unit)
      genericTriggerRegisteredUnitEvents[unit] = genericTriggerRegisteredUnitEvents[unit] or {};
      genericTriggerRegisteredUnitEvents[unit][event] = true;
    end
  end

  for id in pairs(toLoad) do
    GenericTrigger.ScanWithFakeEvent(id);
  end

  -- Replay events that lead to loading, if we weren't already registered for them
  if (eventsToRegister[loadEvent]) then
    WeakAuras.ScanEvents(loadEvent, ...);
  end
  local loadUnit = ...
  if loadUnit and unitEventsToRegister[loadUnit] and unitEventsToRegister[loadUnit][loadEvent] then
    WeakAuras.ScanUnitEvents(loadEvent, ...);
  end

  wipe(eventsToRegister);
  wipe(unitEventsToRegister);
end

function GenericTrigger.FinishLoadUnload()
end

do
  local function ParseCron(pattern)
    local tests = {}
    for test in pattern:gmatch("[^ ,]+") do
      local startString, endString, intervalString = test:match("(%d*)-?(%d*)/?(%d*)")
      local intervalNumber = tonumber(intervalString)
      local startNumber = startString == "" and 0 or tonumber(startString) or 0
      local endNumber = tonumber(endString)
      if not endNumber then
        endNumber = intervalNumber and math.huge or startNumber
      end
      intervalNumber = intervalNumber or 1

      tinsert(tests, {
        startNumber = startNumber,
        endNumber = endNumber,
        intervalNumber = intervalNumber,
        Match = function(self, count)
          return (count >= self.startNumber and count <= self.endNumber and (count - self.startNumber) % self.intervalNumber == 0)
        end
      })
    end
    return tests
  end

  function Private.ExecEnv.CreateTriggerCounter(pattern)
    local counter = {
      count = 0,
      tests = {

      },
      fastMatches = {
      },
      Reset = function(self)
        self.count = 0
      end,
      GetNext = function(self)
        self.count = self.count + 1
        return self.count
      end,
      SetCount = function(self, count)
        self.count = count
      end,
    }
    if pattern then
      counter.tests = ParseCron(pattern)
      counter.RunTests = function(self, count)
        for _, test in ipairs(self.tests) do
          if test:Match(count) then
            return true
          end
        end
        return false
      end

      for i = 1, 20 do
        counter.fastMatches[i] = counter.RunTests(counter, i)
      end

      counter.Match = function(self)
        if self.count <= 20 then
          return counter.fastMatches[self.count]
        end
        return self:RunTests(self.count)
      end

    else
      counter.Match = function(self)
        return true
      end
    end

    return counter
  end
end

--- Adds a display, creating all internal data structures for all triggers.
---@param data auraData
---@param region table
function GenericTrigger.Add(data, region)
  local id = data.id;
  events[id] = nil;
  watched_trigger_events[id] = nil

  local warnAboutCLEUEvents = false

  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger
    local triggerType;
    if(trigger and type(trigger) == "table") then
      triggerType = trigger.type;
      if(Private.category_event_prototype[triggerType] or triggerType == "custom") then
        local triggerFuncStr, triggerFunc, untriggerFunc, statesParameter;
        local trigger_events = {};
        local internal_events = {};
        local trigger_unit_events = {};
        local includePets
        local trigger_subevents = {};
        ---@type boolean|string|table
        local force_events = false;
        local durationFunc, overlayFuncs, nameFunc, iconFunc, textureFunc, stacksFunc, loadFunc;
        local tsuConditionVariables;
        local prototype = nil
        local automaticAutoHide
        local duration
        local counter
        if(Private.category_event_prototype[triggerType]) then
          if not(trigger.event) then
            error("Improper arguments to WeakAuras.Add - trigger type is \"event\" but event is not defined");
          elseif not(event_prototypes[trigger.event]) then
            if(event_prototypes["Health"]) then
              trigger.event = "Health";
            else
              error("Improper arguments to WeakAuras.Add - no event prototype can be found for event type \""..trigger.event.."\" and default prototype reset failed.");
            end
          else
            if (trigger.event == "Combat Log") then
              if (not trigger.subeventPrefix) then
                trigger.subeventPrefix = ""
              end
              if (not trigger.subeventSuffix) then
                trigger.subeventSuffix = "";
              end
              if not(Private.subevent_actual_prefix_types[trigger.subeventPrefix]) then
                trigger.subeventSuffix = "";
              end
            end

            prototype = event_prototypes[trigger.event]
            triggerFuncStr = ConstructFunction(prototype, trigger);

            statesParameter = prototype.statesParameter;
            triggerFunc = Private.LoadFunction(triggerFuncStr);

            durationFunc = prototype.durationFunc;
            nameFunc = prototype.nameFunc;
            iconFunc = prototype.iconFunc;
            textureFunc = prototype.textureFunc;
            stacksFunc = prototype.stacksFunc;
            loadFunc = prototype.loadFunc;

            if (prototype.overlayFuncs) then
              overlayFuncs = {};
              local dest = 1;
              for i, v in ipairs(prototype.overlayFuncs) do
                local enable = true
                if type(v.enable) == "function" then
                  enable = v.enable(trigger)
                elseif type(v.enable) == "boolean" then
                  enable = v.enable
                end
                if enable then
                  overlayFuncs[dest] = v.func;
                  dest = dest + 1;
                end
              end
            end

            if (prototype.automaticrequired) then
              untriggerFunc = trueFunction
            elseif prototype.timedrequired then
              automaticAutoHide = true
              duration = tonumber(trigger.duration or "1")
            else
              WeakAuras.prettyPrint("Invalid Prototype found: " .. prototype.name)
            end

            if prototype.countEvents then
              if trigger.use_count and type(trigger.count) == "string" and trigger.count ~= "" then
                counter = Private.ExecEnv.CreateTriggerCounter(trigger.count)
              else
                counter = Private.ExecEnv.CreateTriggerCounter()
              end
            end

            if(prototype) then
              local trigger_all_events = prototype.events;
              internal_events = prototype.internal_events;
              force_events = prototype.force_events;
              if prototype.subevents then
                trigger_subevents = prototype.subevents
                if trigger_subevents and type(trigger_subevents) == "function" then
                  trigger_subevents = trigger_subevents(trigger, untrigger)
                end
              end

              if trigger.event == "Combat Log" and trigger.subeventPrefix and trigger.subeventSuffix then
                tinsert(trigger_subevents, trigger.subeventPrefix .. trigger.subeventSuffix)
              end

              if (type(trigger_all_events) == "function") then
                trigger_all_events = trigger_all_events(trigger, untrigger);
              end
              trigger_events = trigger_all_events.events
              trigger_unit_events = trigger_all_events.unit_events
              if (type(internal_events) == "function") then
                internal_events = internal_events(trigger, untrigger);
              end
              if (type(force_events) == "function") then
                force_events = force_events(trigger, untrigger)
              end

              if prototype.includePets then
                includePets = trigger.use_includePets == true and trigger.includePets or nil
              end
            end
          end
        else -- CUSTOM
          triggerFunc = WeakAuras.LoadFunction("return "..(trigger.custom or ""));
          if (trigger.custom_type == "stateupdate") then
            tsuConditionVariables = WeakAuras.LoadFunction("return function() return \n" .. (trigger.customVariables or "") .. "\n end");
            if not tsuConditionVariables then
              tsuConditionVariables = function() end
            end
          end

          if(trigger.custom_type == "status" or trigger.custom_type == "event" and trigger.custom_hide == "custom") then
            untriggerFunc = WeakAuras.LoadFunction("return "..(untrigger.custom or ""));
            if (not untriggerFunc) then
              untriggerFunc = trueFunction;
            end
          end

          if(trigger.custom_type ~= "stateupdate" and trigger.customDuration and trigger.customDuration ~= "") then
            durationFunc = WeakAuras.LoadFunction("return "..trigger.customDuration);
          end
          if(trigger.custom_type ~= "stateupdate") then
            overlayFuncs = {};
            for i = 1, 7 do
              local property = "customOverlay" .. i;
              if (trigger[property] and trigger[property] ~= "") then
                overlayFuncs[i] = WeakAuras.LoadFunction("return ".. trigger[property]);
              end
            end
          end
          if(trigger.custom_type ~= "stateupdate" and trigger.customName and trigger.customName ~= "") then
            nameFunc = WeakAuras.LoadFunction("return "..trigger.customName);
          end
          if(trigger.custom_type ~= "stateupdate" and trigger.customIcon and trigger.customIcon ~= "") then
            iconFunc = WeakAuras.LoadFunction("return "..trigger.customIcon);
          end
          if(trigger.custom_type ~= "stateupdate" and trigger.customTexture and trigger.customTexture ~= "") then
            textureFunc = WeakAuras.LoadFunction("return "..trigger.customTexture);
          end
          if(trigger.custom_type ~= "stateupdate" and trigger.customStacks and trigger.customStacks ~= "") then
            stacksFunc = WeakAuras.LoadFunction("return "..trigger.customStacks);
          end

          if((trigger.custom_type == "status" or trigger.custom_type == "stateupdate") and trigger.check == "update") then
            trigger_events = {"FRAME_UPDATE"};
          else
            local rawEvents = WeakAuras.split(trigger.events);
            for index, event in pairs(rawEvents) do
              -- custom events in the form of event:unit1:unit2:unitX are registered with RegisterUnitEvent
              local trueEvent
              local hasParam = false
              local isCLEU = false
              local isTrigger = false
              local isUnitEvent = false
              if event == "CLEU" or event == "COMBAT_LOG_EVENT_UNFILTERED" then
                warnAboutCLEUEvents = true
              end
              for i in event:gmatch("[^:]+") do
                if not trueEvent then
                  trueEvent = string.upper(i)
                  isCLEU = trueEvent == "CLEU" or trueEvent == "COMBAT_LOG_EVENT_UNFILTERED"
                  isTrigger = trueEvent == "TRIGGER"
                elseif isCLEU then
                  local subevent = string.upper(i)
                  if Private.IsCLEUSubevent(subevent) then
                    tinsert(trigger_subevents, subevent)
                    hasParam = true
                  end
                elseif trueEvent:match("^UNIT_") or Private.UnitEventList[trueEvent] then
                  isUnitEvent = true

                  if string.lower(strsub(i, #i - 3)) == "pets" then
                    i = strsub(i, 1, #i-4)
                    includePets = "PlayersAndPets"
                  elseif string.lower(strsub(i, #i - 7)) == "petsonly" then
                    includePets = "PetsOnly"
                    i = strsub(i, 1, #i - 8)
                  end

                  trigger_unit_events[i] = trigger_unit_events[i] or {}
                  tinsert(trigger_unit_events[i], trueEvent)
                elseif isTrigger then
                  local requestedTriggernum = tonumber(i)
                  if requestedTriggernum then
                    if watched_trigger_events[id] and watched_trigger_events[id][triggernum] and watched_trigger_events[id][triggernum][requestedTriggernum] then
                      -- if the request is reciprocal (2 custom triggers request each other which would cause a stack overflow) then prevent the reciprocal one being added.
                    elseif requestedTriggernum and requestedTriggernum ~= triggernum then
                      watched_trigger_events[id] = watched_trigger_events[id] or {}
                      watched_trigger_events[id][requestedTriggernum] = watched_trigger_events[id][requestedTriggernum] or {}
                      watched_trigger_events[id][requestedTriggernum][triggernum] = true
                    end
                  end
                end
              end
              if isCLEU then
                if hasParam then
                  tinsert(trigger_events, "COMBAT_LOG_EVENT_UNFILTERED")
                else
                  -- This is a dirty, lazy, dirty hack. "Proper" COMBAT_LOG_EVENT_UNFILTERED events are indexed by their sub-event types (e.g. SPELL_PERIODIC_DAMAGE),
                  -- but custom COMBAT_LOG_EVENT_UNFILTERED events are not guaranteed to have sub-event types. Thus, if the user specifies that they want to use
                  -- COMBAT_LOG_EVENT_UNFILTERED, this hack renames the event to COMBAT_LOG_EVENT_UNFILTERED_CUSTOM to circumvent the COMBAT_LOG_EVENT_UNFILTERED checks
                  -- that are already in place. Replacing all those checks would be a pain in the ass.
                  tinsert(trigger_events, "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM")
                end
              elseif isUnitEvent then
                -- not added to trigger_events
              elseif isTrigger then
                -- not added to trigger_events
              else
                tinsert(trigger_events, event)
              end
            end
          end
          if trigger.custom_type == "status" or trigger.custom_type == "stateupdate" then
            force_events = data.information.forceEvents or "STATUS"
          end
          if (trigger.custom_type == "stateupdate") then
            statesParameter = "full";
          end

          if(trigger.custom_type == "event" and trigger.custom_hide == "timed") then
            automaticAutoHide = true;
            if (not trigger.dynamicDuration) then
              duration = tonumber(trigger.duration);
            end
          end
        end

        events[id] = events[id] or {};
        events[id][triggernum] = {
          trigger = trigger,
          triggerFunc = triggerFunc,
          untriggerFunc = untriggerFunc,
          statesParameter = statesParameter,
          event = trigger.event,
          events = trigger_events,
          internal_events = internal_events,
          force_events = force_events,
          unit_events = trigger_unit_events,
          includePets = includePets,
          inverse = trigger.use_inverse,
          subevents = trigger_subevents,
          durationFunc = durationFunc,
          overlayFuncs = overlayFuncs,
          nameFunc = nameFunc,
          iconFunc = iconFunc,
          textureFunc = textureFunc,
          stacksFunc = stacksFunc,
          loadFunc = loadFunc,
          duration = duration,
          automaticAutoHide = automaticAutoHide,
          tsuConditionVariables = tsuConditionVariables,
          prototype = prototype,
          ignoreOptionsEventErrors = data.information.ignoreOptionsEventErrors,
          counter = counter
        };
      end
    end
  end

  if warnAboutCLEUEvents then
    Private.AuraWarnings.UpdateWarning(data.uid, "spammy_event_warning", "warning",
                L["COMBAT_LOG_EVENT_UNFILTERED without a filter is generally advised against as it’s very performance costly.\nFind more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers#events"])
  else
    Private.AuraWarnings.UpdateWarning(data.uid, "spammy_event_warning")
  end
end

do
  local update_clients = {};
  local update_clients_num = 0;
  local update_frame = nil
  Private.frames["Custom Trigger Every Frame Updater"] = update_frame;
  local updating = false;

  ---@type fun(id)
  function Private.RegisterEveryFrameUpdate(id)
    if not(update_clients[id]) then
      update_clients[id] = true;
      update_clients_num = update_clients_num + 1;
    end
    if not(update_frame) then
      update_frame = CreateFrame("Frame");
    end
    if not(updating) then
      update_frame:SetScript("OnUpdate", function(self, elapsed)
        if not(WeakAuras.IsPaused()) then
          WeakAuras.ScanEvents("FRAME_UPDATE", elapsed);
        end
      end);
      updating = true;
    end
  end

  ---@type fun(oldid, newid)
  function Private.EveryFrameUpdateRename(oldid, newid)
    update_clients[newid] = update_clients[oldid];
    update_clients[oldid] = nil;
  end

  ---@type fun(id)
  function Private.UnregisterEveryFrameUpdate(id)
    if(update_clients[id]) then
      update_clients[id] = nil;
      update_clients_num = update_clients_num - 1;
    end
    if(update_clients_num == 0 and update_frame and updating) then
      update_frame:SetScript("OnUpdate", nil);
      updating = false;
    end
  end

  ---@type fun()
  function Private.UnregisterAllEveryFrameUpdate()
    if (not update_frame) then
      return;
    end
    wipe(update_clients);
    update_clients_num = 0;
    update_frame:SetScript("OnUpdate", nil);
    updating = false;
  end
end

local combatLogUpgrade = {
  ["sourceunit"] = "sourceUnit",
  ["source"] = "sourceName",
  ["destunit"] = "destUnit",
  ["dest"] = "destName"
}

local oldPowerTriggers = {
  ["Combo Points"] = 4,
  ["Holy Power"] = 9,
  ["Insanity"] = 13,
  ["Chi Power"] = 12,
  ["Astral Power"] = 8,
  ["Maelstrom"] =  11,
  ["Arcane Charges"] = 16,
  ["Fury"] = 17,
  ["Pain"] = 18,
  ["Shards"] = 7,
}

--#############################
--# Support code for triggers #
--#############################

-- Swing timer support code
do
  local mh = GetInventorySlotInfo("MainHandSlot")
  local oh = GetInventorySlotInfo("SecondaryHandSlot")
  local ranged = WeakAuras.IsClassicEra() and GetInventorySlotInfo("RangedSlot")

  local swingTimerFrame;
  local lastSwingMain, lastSwingOff, lastSwingRange;
  local swingDurationMain, swingDurationOff, swingDurationRange, mainSwingOffset;
  local mainTimer, offTimer, rangeTimer;
  local selfGUID;
  local mainSpeed, offSpeed = UnitAttackSpeed("player")
  local casting = false
  local skipNextAttack, skipNextAttackCount
  local isAttacking

  ---@param hand string
  ---@return number duration
  ---@return number expirationTime
  ---@return string? weaponName
  ---@return number? icon
  function WeakAuras.GetSwingTimerInfo(hand)
    if(hand == "main") then
      local itemId = GetInventoryItemID("player", mh);
      local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemId or 0);
      if(lastSwingMain) then
        return swingDurationMain, lastSwingMain + swingDurationMain - mainSwingOffset, name, icon;
      elseif WeakAuras.IsRetail() and lastSwingRange then
        return swingDurationRange, lastSwingRange + swingDurationRange, name, icon;
      else
        return 0, math.huge, name, icon;
      end
    elseif(hand == "off") then
      local itemId = GetInventoryItemID("player", oh);
      local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemId or 0);
      if(lastSwingOff) then
        return swingDurationOff, lastSwingOff + swingDurationOff, name, icon;
      else
        return 0, math.huge, name, icon;
      end
    elseif(hand == "ranged") then
      local itemId = GetInventoryItemID("player", ranged);
      local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemId or 0);
      if (lastSwingRange) then
        return swingDurationRange, lastSwingRange + swingDurationRange, name, icon;
      else
        return 0, math.huge, name, icon;
      end
    end

    return 0, math.huge;
  end

  local function swingTriggerUpdate()
    WeakAuras.ScanEvents("SWING_TIMER_UPDATE")
  end

  local function swingEnd(hand)
    if(hand == "main") then
      lastSwingMain, swingDurationMain, mainSwingOffset = nil, nil, nil;
    elseif(hand == "off") then
      lastSwingOff, swingDurationOff = nil, nil;
    elseif(hand == "ranged") then
      lastSwingRange, swingDurationRange = nil, nil;
    end
    swingTriggerUpdate()
  end

  local function swingStart(hand)
    mainSpeed, offSpeed = UnitAttackSpeed("player")
    offSpeed = offSpeed or 0
    local currentTime = GetTime()
    if hand == "main" then
      lastSwingMain = currentTime
      swingDurationMain = mainSpeed
      mainSwingOffset = 0
      if mainTimer then
        timer:CancelTimer(mainTimer)
      end
      if mainSpeed and mainSpeed > 0 then
        mainTimer = timer:ScheduleTimerFixed(swingEnd, mainSpeed, hand)
      else
        swingEnd(hand)
      end
    elseif hand == "off" then
      lastSwingOff = currentTime
      swingDurationOff = offSpeed
      if offTimer then
        timer:CancelTimer(offTimer)
      end
      if offSpeed and offSpeed > 0 then
        offTimer = timer:ScheduleTimerFixed(swingEnd, offSpeed, hand)
      else
        swingEnd(hand)
      end
    elseif hand == "ranged" then
      local rangeSpeed = UnitRangedDamage("player")
      lastSwingRange = currentTime
      swingDurationRange = rangeSpeed
      if rangeTimer then
        timer:CancelTimer(rangeTimer)
      end
      if rangeSpeed and rangeSpeed > 0 then
        rangeTimer = timer:ScheduleTimerFixed(swingEnd, rangeSpeed, hand)
      else
        swingEnd(hand)
      end
    end
  end

  local function swingTimerCLEUCheck(ts, event, _, sourceGUID, _, _, _, destGUID, _, _, _, ...)
    Private.StartProfileSystem("generictrigger swing");
    if(sourceGUID == selfGUID) then
      if event == "SPELL_EXTRA_ATTACKS" then
        skipNextAttack = ts
        skipNextAttackCount = select(4, ...)
      elseif(event == "SWING_DAMAGE" or event == "SWING_MISSED") then
        if tonumber(skipNextAttack) and (ts - skipNextAttack) < 0.04 and tonumber(skipNextAttackCount) then
          if skipNextAttackCount > 0 then
            skipNextAttackCount = skipNextAttackCount - 1
            return
          end
        end
        local isOffHand = select(event == "SWING_DAMAGE" and 10 or 2, ...);
        if not isOffHand then
          swingStart("main")
        elseif(isOffHand) then
          swingStart("off")
        end
        swingTriggerUpdate()
      end
    elseif (destGUID == selfGUID and (... == "PARRY" or select(4, ...) == "PARRY")) then
      if (lastSwingMain) then
        local timeLeft = lastSwingMain + swingDurationMain - GetTime() - (mainSwingOffset or 0);
        if (timeLeft > 0.2 * swingDurationMain) then
          local offset = 0.4 * swingDurationMain
          if (timeLeft - offset < 0.2 * swingDurationMain) then
            offset = timeLeft - 0.2 * swingDurationMain
          end
          timer:CancelTimer(mainTimer);
          mainTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft - offset, "main");
          mainSwingOffset = (mainSwingOffset or 0) + offset
          swingTriggerUpdate()
        end
      end
    end
    Private.StopProfileSystem("generictrigger swing");
  end

  local function swingTimerCheck(event, unit, guid, spell)
    if event ~= "PLAYER_EQUIPMENT_CHANGED" and unit and unit ~= "player" then return end
    Private.StartProfileSystem("generictrigger swing");
    local now = GetTime()
    if event == "UNIT_ATTACK_SPEED" then
      local mainSpeedNew, offSpeedNew = UnitAttackSpeed("player")
      offSpeedNew = offSpeedNew or 0
      if lastSwingMain then
        if mainSpeedNew ~= mainSpeed then
          timer:CancelTimer(mainTimer)
          local multiplier = mainSpeedNew / mainSpeed
          local timeLeft = (lastSwingMain + swingDurationMain - now) * multiplier
          swingDurationMain = mainSpeedNew
          mainSwingOffset = (lastSwingMain + swingDurationMain) - (now + timeLeft)
          mainTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft, "main")
        end
      end
      if lastSwingOff then
        if offSpeedNew ~= offSpeed then
          timer:CancelTimer(offTimer)
          local multiplier = offSpeedNew / mainSpeed
          local timeLeft = (lastSwingOff + swingDurationOff - now) * multiplier
          swingDurationOff = offSpeedNew
          offTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft, "off")
        end
      end
      mainSpeed, offSpeed = mainSpeedNew, offSpeedNew
      swingTriggerUpdate()
    elseif casting and (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED") then
      casting = false
    elseif event == "PLAYER_EQUIPMENT_CHANGED" and isAttacking then
      swingStart("main")
      swingStart("off")
      swingStart("ranged")
      swingTriggerUpdate()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
      if Private.reset_swing_spells[spell] or casting then
        if casting then
          casting = false
        end
        -- check next frame
        swingTimerFrame:SetScript("OnUpdate", function(self)
          if isAttacking then
            swingStart("main")
            swingTriggerUpdate()
          end
          self:SetScript("OnUpdate", nil)
        end)
      end
      if Private.reset_ranged_swing_spells[spell] then
        if WeakAuras.IsClassicEra() then
          swingStart("ranged")
        else
          swingStart("main")
        end
        swingTriggerUpdate()
      end
    elseif event == "UNIT_SPELLCAST_START" then
      if not Private.noreset_swing_spells[spell] then
        -- pause swing timer
        casting = true
        lastSwingMain, swingDurationMain, mainSwingOffset = nil, nil, nil
        lastSwingOff, swingDurationOff = nil, nil
        swingTriggerUpdate()
      end
    elseif event == "PLAYER_ENTER_COMBAT" then
      isAttacking = true
    elseif event == "PLAYER_LEAVE_COMBAT" then
      isAttacking = nil
    end
    Private.StopProfileSystem("generictrigger swing");
  end

  ---@private
  function WeakAuras.InitSwingTimer()
    if not(swingTimerFrame) then
      swingTimerFrame = CreateFrame("Frame");
      swingTimerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
      swingTimerFrame:RegisterEvent("PLAYER_ENTER_COMBAT");
      swingTimerFrame:RegisterEvent("PLAYER_LEAVE_COMBAT");
      swingTimerFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
      swingTimerFrame:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player");
      swingTimerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
      if WeakAuras.IsClassicEra() then
        swingTimerFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
        swingTimerFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
        swingTimerFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
      end
      swingTimerFrame:SetScript("OnEvent",
        function(_, event, ...)
          if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            swingTimerCLEUCheck(CombatLogGetCurrentEventInfo())
          else
            swingTimerCheck(event, ...)
          end
        end);
      selfGUID = UnitGUID("player");
    end
  end
end

-- CD/Rune/GCD support code
do
  local cdReadyFrame;

  ---@type table<number|string, boolean> Tracks which spells we want to fetch information on,
  local spells = {};
  ---@type table<number, boolean>
  local checkOverrideSpell = {}
  ---@type table<number, boolean>
  local spellKnown = {};

  local spellCharges = {};
  local spellChargesMax = {};
  local spellCounts = {}
  local spellChargeGainTime = {}
  local spellChargeLostTime = {}

  local items = {};
  local itemCdDurs = {};
  local itemCdExps = {};
  local itemCdHandles = {};
  local itemCdEnabled = {};

  local itemSlots = {};
  local itemSlotsCdDurs = {};
  local itemSlotsCdExps = {};
  local itemSlotsCdHandles = {};
  local itemSlotsEnable = {};

  local runes = {};
  local runeCdDurs = {};
  local runeCdExps = {};
  local runeCdHandles = {};

  local gcdStart;
  local gcdDuration;
  local gcdSpellName;
  local gcdSpellIcon;
  local gcdEndCheck;
  local gcdModrate

  local shootStart
  local shootDuration

  local function GetRuneDuration()
    local runeDuration = -100;
    for id, _ in pairs(runes) do
      local _, duration = GetRuneCooldown(id);
      duration = duration or 0;
      runeDuration = duration > 0 and duration or runeDuration
    end
    return runeDuration
  end

  local function CheckGCD()
    local event;
    local startTime, duration, _, modRate
    if WeakAuras.IsClassicEra() then
      startTime, duration = GetSpellCooldown(29515);
      shootStart, shootDuration = GetSpellCooldown(5019)
    elseif GetSpellCooldown then
      startTime, duration, _, modRate = GetSpellCooldown(61304);
    else
      local spellCooldownInfo = C_Spell.GetSpellCooldown(61304);
      if spellCooldownInfo then
        startTime = spellCooldownInfo.startTime
        duration = spellCooldownInfo.duration
        modRate = spellCooldownInfo.modRate
      end
    end
    if(duration and duration > 0) then
      if not(gcdStart) then
        event = "GCD_START";
      elseif(gcdStart ~= startTime or gcdDuration ~= duration or gcdModrate ~= modRate) then
        event = "GCD_CHANGE";
      end
      gcdStart, gcdDuration, gcdModrate = startTime, duration, modRate
      local endCheck = startTime + duration + 0.1;
      if(gcdEndCheck ~= endCheck) then
        gcdEndCheck = endCheck;
        timer:ScheduleTimerFixed(CheckGCD, duration + 0.1);
      end
    else
      if(gcdStart) then
        event = "GCD_END"
      end
      gcdStart, gcdDuration, gcdModrate = nil, nil, nil;
      gcdSpellName, gcdSpellIcon = nil, nil;
      gcdEndCheck = 0;
    end
    if(event and not WeakAuras.IsPaused()) then
      WeakAuras.ScanEvents(event);
    end
  end

  local RecheckHandles = {
    expirationTime = {},
    handles = {},
    Recheck = function(self, id)
      self.handles[id] = nil
      self.expirationTime[id] = nil
      CheckGCD();
      Private.CheckSpellCooldown(id, GetRuneDuration())
    end,
    Schedule = function(self, expirationTime, id)
      if (not self.expirationTime[id] or expirationTime < self.expirationTime[id]) and expirationTime > 0 then
        if self.handles[id] then
          timer:CancelTimer(self.handles[id])
          self.handles[id] = nil
          self.expirationTime[id] = nil
        end

        local duration = expirationTime - GetTime()
        if duration > 0 then
          self.handles[id] = timer:ScheduleTimerFixed(self.Recheck, duration, self, id)
          self.expirationTime[id] = expirationTime
        end
      end
    end
  }

  local function FetchSpellCooldown(self, id)
    if self.duration[id] and self.expirationTime[id] then
      return self.expirationTime[id] - self.duration[id], self.duration[id], false, self.readyTime[id], self.modRate[id] or 1.0
    elseif self.remainingTime[id] then
      return self.remainingTime[id], self.duration[id], true, self.readyTime[id], self.modRate[id] or 1.0
    end
    return 0, 0, nil, nil, 1.0
  end

  local function HandleSpell(self, id, startTime, duration, modRate, paused)
    local changed = false
    local nowReady = false
    local time = GetTime()
    if self.expirationTime[id] and self.expirationTime[id] <= time and self.expirationTime[id] ~= 0 then
      self.duration[id] = 0
      self.expirationTime[id] = 0
      changed = true
      nowReady = true
    end
    local endTime = startTime + duration;
    if endTime <= time then
      startTime = 0
      duration = 0
      endTime = 0
    end

    if paused then
      if self.duration[id] ~= duration then
        self.duration[id] = duration
        changed = true
      end
      if self.expirationTime[id] then
        self.expirationTime[id] = nil
        changed = true
      end

      if self.modRate[id] ~= modRate then
        self.modRate[id] = modRate
        changed = true
      end

      local remaining = startTime + duration - GetTime()
      if self.remainingTime[id] ~= remaining then
        self.remainingTime[id] = remaining
        changed = true
      end

      return changed, false
    end

    if duration > 0 then
      if (startTime == gcdStart and duration == gcdDuration)
          or (WeakAuras.IsClassicEra() and duration == shootDuration and startTime == shootStart)
      then
        -- GCD cooldown, this could mean that the spell reset!
        if self.expirationTime[id] and self.expirationTime[id] > endTime and self.expirationTime[id] ~= 0 then
          self.duration[id] = 0
          self.expirationTime[id] = 0
          if not self.readyTime[id] then
            self.readyTime[id] = time
          end
          changed = true
          nowReady = true
        end
        RecheckHandles:Schedule(endTime, id)
        return changed, nowReady
      end
    end

    if self.remainingTime[id] then
      self.remainingTime[id] = nil
      changed = true
    end

    if self.duration[id] ~= duration then
      self.duration[id] = duration
      changed = true
    end

    if self.expirationTime[id] ~= endTime then
      self.expirationTime[id] = endTime
      changed = true
      nowReady = endTime == 0
    end

    if duration == 0 then
      if not self.readyTime[id] then
        self.readyTime[id] = time
      end
    else
      self.readyTime[id] = nil
    end

    if self.modRate[id] ~= modRate then
      self.modRate[id] = modRate
      changed = true
    end

    RecheckHandles:Schedule(endTime, id)
    return changed, nowReady
  end

  local function CreateSpellCDHandler()
    local cd = {
      duration = {},
      expirationTime = {},
      remainingTime = {},
      readyTime = {},
      modRate = {},
      handles = {}, -- Share handles, and use lowest time to schedule
      HandleSpell = HandleSpell,
      FetchSpellCooldown = FetchSpellCooldown
    }
    return cd
  end

  local spellCds = CreateSpellCDHandler();
  local spellCdsRune = CreateSpellCDHandler();
  local spellCdsOnlyCooldown = CreateSpellCDHandler();
  local spellCdsOnlyCooldownRune = CreateSpellCDHandler();
  local spellCdsCharges = CreateSpellCDHandler();

  local spellDetails = {}
  local mark_ACTIONBAR_UPDATE_COOLDOWN, mark_PLAYER_ENTERING_WORLD

  ---@type fun()
  function Private.InitCooldownReady()
    ---@class CooldownReadyFrame : FrameScriptObject
    cdReadyFrame = CreateFrame("Frame");
    cdReadyFrame.inWorld = 0
    Private.frames["Cooldown Trigger Handler"] = cdReadyFrame
    if WeakAuras.IsRetail() then
      cdReadyFrame:RegisterEvent("RUNE_POWER_UPDATE");
      cdReadyFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
      cdReadyFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
    else
      cdReadyFrame:RegisterEvent("CHARACTER_POINTS_CHANGED");
    end
    cdReadyFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    cdReadyFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    cdReadyFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
    cdReadyFrame:RegisterEvent("BAG_UPDATE_DELAYED");
    cdReadyFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    cdReadyFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    cdReadyFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
    cdReadyFrame:RegisterEvent("SPELLS_CHANGED");
    cdReadyFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    cdReadyFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    if WeakAuras.IsCataClassic() then
      cdReadyFrame:RegisterEvent("RUNE_POWER_UPDATE");
      cdReadyFrame:RegisterEvent("RUNE_TYPE_UPDATE");
    end
    cdReadyFrame.HandleEvent = function(self, event, ...)
      if (event == "PLAYER_ENTERING_WORLD") then
        cdReadyFrame.inWorld = GetTime()
      end
      if (event == "PLAYER_LEAVING_WORLD") then
        cdReadyFrame.inWorld = nil
      end
      if not cdReadyFrame.inWorld then
        return
      end

      if GetTime() - cdReadyFrame.inWorld < 2 then
        mark_PLAYER_ENTERING_WORLD = true
        cdReadyFrame:Show()
        return
      end
      if (event == "ACTIONBAR_UPDATE_COOLDOWN") then
        mark_ACTIONBAR_UPDATE_COOLDOWN = true
        cdReadyFrame:Show()
        return
      end

      Private.StartProfileSystem("generictrigger cd tracking");
      if type(event) == "number" then-- Called from OnUpdate!
        if mark_PLAYER_ENTERING_WORLD then
          Private.CheckSpellKnown()
          Private.CheckCooldownReady()
          Private.CheckItemSlotCooldowns()
          mark_PLAYER_ENTERING_WORLD = nil
          mark_ACTIONBAR_UPDATE_COOLDOWN = nil
        elseif mark_ACTIONBAR_UPDATE_COOLDOWN then
          Private.CheckCooldownReady()
          mark_ACTIONBAR_UPDATE_COOLDOWN = nil
        end
      elseif(event == "SPELL_UPDATE_COOLDOWN" or event == "RUNE_POWER_UPDATE"
        or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_PVP_TALENT_UPDATE"
        or event == "CHARACTER_POINTS_CHANGED" or event == "RUNE_TYPE_UPDATE")
        or event == "SPELL_UPDATE_USABLE"
      then
        if event == "SPELL_UPDATE_COOLDOWN" then
          mark_ACTIONBAR_UPDATE_COOLDOWN = nil
        end
        Private.CheckCooldownReady();
      elseif(event == "SPELLS_CHANGED") then
        Private.CheckSpellKnown()
        Private.CheckCooldownReady()
      elseif(event == "UNIT_SPELLCAST_SENT") then
        local unit, guid, castGUID, name = ...;
        if(unit == "player") then
          name = Private.ExecEnv.GetSpellName(name);
          if(gcdSpellName ~= name) then
            local icon = Private.ExecEnv.GetSpellIcon(name);
            gcdSpellName = name;
            gcdSpellIcon = icon;
            if not WeakAuras.IsPaused() then
              WeakAuras.ScanEvents("GCD_UPDATE")
            end
          end
        end
      elseif(event == "UNIT_INVENTORY_CHANGED" or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED") then
        Private.CheckItemSlotCooldowns();
      end
      Private.StopProfileSystem("generictrigger cd tracking");
      if mark_PLAYER_ENTERING_WORLD == nil and mark_ACTIONBAR_UPDATE_COOLDOWN == nil then
        cdReadyFrame:Hide()
      else
        cdReadyFrame:Show()
      end
    end
    cdReadyFrame:Hide()
    cdReadyFrame:SetScript("OnEvent", cdReadyFrame.HandleEvent)
    cdReadyFrame:SetScript("OnUpdate", cdReadyFrame.HandleEvent)
  end

  ---@param id number
  ---@return number cooldownStart
  ---@return number cooldownDuration
  function WeakAuras.GetRuneCooldown(id)
    if(runes[id] and runeCdExps[id] and runeCdDurs[id]) then
      return runeCdExps[id] - runeCdDurs[id], runeCdDurs[id];
    else
      return 0, 0;
    end
  end

  local initEssenceCooldown = false
  local essenceCache = {{},{},{},{},{},{}}
  ---@private
  function WeakAuras.InitEssenceCooldown()
    if initEssenceCooldown then
      return true
    end
    local EssenceEnum = Enum.PowerType.Essence
    local lastFullValue = 0
    local lastTime = 0
    local essenceEventFrame = CreateFrame("Frame")
    essenceEventFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    essenceEventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    essenceEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    essenceEventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    local essenceEventHandler = function(self, event, unitTarget, powerType)
      if powerType and powerType ~= "ESSENCE" then
        return
      end
      local now = GetTime()
      if lastTime == now then
        return
      end
      Private.StartProfileSystem("generictrigger essence")
      local power = UnitPower("player", EssenceEnum)
      local total = UnitPowerMax("player", EssenceEnum)
      local peace = GetPowerRegenForPowerType(EssenceEnum)
      if peace == nil or peace == 0 then
        peace = 0.2
      end
      local duration = 1 / peace
      local partial = UnitPartialPower("player", EssenceEnum) / 1000

      if (partial == 0) then
        lastFullValue = now
      elseif power ~= total then
        -- UnitPartialPower is a rather poor api, which returns incorrect values
        -- This almost mirrors what the default ui does, in that the default ui
        -- starts an animation and only uses UnitPartialPower when that animation's
        -- progress differs from UnitPartialPower by 0.1
        -- This here uses a similar logic. We sync whenever partial is 0
        -- and then estimate based on that. And as long as that
        -- estimate is within 0.1 of UnitPartialPower we prefer the estimate
        local estimatedPartial = (now - lastFullValue) / duration
        estimatedPartial = estimatedPartial - floor(estimatedPartial)
        if abs(estimatedPartial - partial) < 0.1 then
          partial = estimatedPartial
        end
      end
      for i = 1, 6 do
        local essence = essenceCache[i]
        if i > total then
          essence.duration = nil
          essence.expirationTime = nil
          essence.remaining = nil
          essence.paused = nil
        elseif power >= i then
          essence.duration = duration
          essence.expirationTime = math.huge
          essence.remaining = 0
          essence.paused = true
        elseif power + 1 == i then
          essence.duration = duration
          essence.expirationTime = GetTime() + (1 - partial) * duration
          essence.paused = false
        else
          essence.duration = duration
          essence.expirationTime = GetTime() + (1 - partial) * duration + (i - 1 - power) * duration
          essence.remaining = duration
          essence.paused = false
        end
      end
      lastTime = now
      Private.StopProfileSystem("generictrigger essence")
      WeakAuras.ScanEvents("ESSENCE_UPDATE")
    end
    essenceEventFrame:SetScript("OnEvent", essenceEventHandler)
    essenceEventFrame:Show()

    essenceEventHandler()
    initEssenceCooldown = true
  end

  ---@param essence? number
  ---@return number|nil duration
  ---@return number|nil expirationTime
  ---@return number|nil remaining
  ---@return boolean|nil paused
  ---@return number|nil power
  ---@return number|nil total
  function WeakAuras.GetEssenceCooldown(essence)
    local power = UnitPower("player", Enum.PowerType.Essence)
    local total = UnitPowerMax("player", Enum.PowerType.Essence)
    if essence then
      local cache = essenceCache[essence]
      if cache and essence <= total then
        return cache.duration, cache.expirationTime, cache.remaining, cache.paused, power, total
      else
        return nil, nil, nil, nil, essence, total
      end
    else
      local cache = essenceCache[total]
      if cache and cache.duration then
        return total * cache.duration, cache.expirationTime, cache.remaining, cache.paused, power, total
      else
        return nil, nil, nil, nil, power, total
      end
    end
  end

  ---@param id string
  ---@param ignoreRuneCD boolean
  ---@param showgcd boolean
  ---@param ignoreSpellKnown boolean
  ---@param track boolean
  ---@param followOverride boolean
  ---@return number? startTime
  ---@return number? duration
  ---@return number? gcdCooldown
  ---@return number? readyTime
  ---@return number? modRate
  ---@return boolean? paused
  function WeakAuras.GetSpellCooldown(id, ignoreRuneCD, showgcd, ignoreSpellKnown, track, followOverride)
    if followOverride then
      if spellDetails[id] then
        id = spellDetails[id].override or id
      end
    end

    if (not spellKnown[id] and not ignoreSpellKnown) then
      return;
    end
    local startTime, duration, paused, gcdCooldown, readyTime, modRate
    if track == "charges" then
      startTime, duration, paused, readyTime, modRate = spellCdsCharges:FetchSpellCooldown(id)
    elseif track == "cooldown" then
      if ignoreRuneCD then
        startTime, duration, paused, readyTime, modRate = spellCdsOnlyCooldownRune:FetchSpellCooldown(id)
      else
        startTime, duration, paused, readyTime, modRate = spellCdsOnlyCooldown:FetchSpellCooldown(id)
      end
    elseif (ignoreRuneCD) then
      startTime, duration, paused, readyTime, modRate = spellCdsRune:FetchSpellCooldown(id)
    else
      startTime, duration, paused, readyTime, modRate = spellCds:FetchSpellCooldown(id)
    end

    if paused then
      return startTime, duration, false, readyTime, modRate, true
    end

    if (showgcd) then
      if ((gcdStart or 0) + (gcdDuration or 0) > startTime + duration) then
        if startTime == 0 then
          gcdCooldown = true
        end
        startTime = gcdStart;
        duration = gcdDuration;
        modRate = gcdModrate
      end
    end

    return startTime, duration, gcdCooldown, readyTime, modRate, false
  end

  ---@param id string
  ---@param ignoreSpellKnown? boolean
  ---@param followoverride? boolean
  ---@return integer? charges
  ---@return integer? chargesMax
  ---@return integer? count
  ---@return number? chargeGainTime
  ---@return number? chargeLostTime
  function WeakAuras.GetSpellCharges(id, ignoreSpellKnown, followoverride)
    if followoverride then
      if spellDetails[id] then
        id = spellDetails[id].override or id
      end
    end

    if (not spellKnown[id] and not ignoreSpellKnown) then
      return;
    end
    return spellCharges[id], spellChargesMax[id], spellCounts[id], spellChargeGainTime[id], spellChargeLostTime[id]
  end

  ---@param id string
  ---@param showgcd boolean
  ---@return number startTime
  ---@return number duration
  ---@return boolean enabled
  ---@return number gcdCooldown
  function WeakAuras.GetItemCooldown(id, showgcd)
    local startTime, duration, enabled, gcdCooldown;
    if(items[id] and itemCdExps[id] and itemCdDurs[id]) then
      startTime, duration, enabled = itemCdExps[id] - itemCdDurs[id], itemCdDurs[id], itemCdEnabled[id];
    else
      startTime, duration, enabled = 0, 0, itemCdEnabled[id] or 1;
    end
    if (showgcd) then
      if ((gcdStart or 0) + (gcdDuration or 0) > startTime + duration) then
        if startTime == 0 then
          gcdCooldown = true
        end
        startTime = gcdStart;
        duration = gcdDuration;
      end
    end
    return startTime, duration, enabled, gcdCooldown;
  end

  ---@return number duration
  ---@return number expirationTime
  ---@return string name
  ---@return number|string icon
  ---@return number modrate
  function WeakAuras.GetGCDInfo()
    if(gcdStart) then
      return gcdDuration, gcdStart + gcdDuration, gcdSpellName or "Invalid", gcdSpellIcon or "Interface\\Icons\\INV_Misc_QuestionMark", gcdModrate;
    else
      return 0, math.huge, gcdSpellName or "Invalid", gcdSpellIcon or "Interface\\Icons\\INV_Misc_QuestionMark", 1.0;
    end
  end

  ---@return number duration
  function WeakAuras.gcdDuration()
    return gcdDuration or 0;
  end

  ---@return string name
  function WeakAuras.GcdSpellName()
    return gcdSpellName;
  end

  ---@param id string
  ---@param showgcd boolean
  ---@return number startTime
  ---@return number duration
  ---@return boolean enabled
  ---@return number gcdCooldown
  function WeakAuras.GetItemSlotCooldown(id, showgcd)
    local startTime, duration, enabled, gcdCooldown;
    if(itemSlots[id] and itemSlotsCdExps[id] and itemSlotsCdDurs[id]) then
      startTime, duration, enabled = itemSlotsCdExps[id] - itemSlotsCdDurs[id], itemSlotsCdDurs[id], itemSlotsEnable[id];
    else
      startTime, duration, enabled = 0, 0, itemSlotsEnable[id];
    end

    if (showgcd) then
      if ((gcdStart or 0) + (gcdDuration or 0) > startTime + duration) then
        if startTime == 0 then
          gcdCooldown = true
        end
        startTime = gcdStart;
        duration = gcdDuration;
      end
    end
    return startTime, duration, enabled, gcdCooldown;
  end

  local function RuneCooldownFinished(id)
    runeCdHandles[id] = nil;
    runeCdDurs[id] = nil;
    runeCdExps[id] = nil;
    WeakAuras.ScanEvents("RUNE_COOLDOWN_READY", id);
  end

  local function ItemCooldownFinished(id)
    itemCdHandles[id] = nil;
    itemCdDurs[id] = nil;
    itemCdExps[id] = nil;
    itemCdEnabled[id] = 1;
    WeakAuras.ScanEvents("ITEM_COOLDOWN_READY", id);
  end

  local function ItemSlotCooldownFinished(id)
    itemSlotsCdHandles[id] = nil;
    itemSlotsCdDurs[id] = nil;
    itemSlotsCdExps[id] = nil;
    WeakAuras.ScanEvents("ITEM_SLOT_COOLDOWN_READY", id);
  end

  ---@type fun()
  ---@return number
  function Private.CheckRuneCooldown()
    local runeDuration = -100;
    for id, _ in pairs(runes) do
      local startTime, duration = GetRuneCooldown(id);
      startTime = startTime or 0;
      duration = duration or 0;
      runeDuration = duration > 0 and duration or runeDuration
      local time = GetTime();

      if(not startTime or startTime == 0) then
        startTime = 0
        duration = 0
      end

      if(duration > 0 and duration ~= WeakAuras.gcdDuration()) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(runeCdExps[id]) then
          -- New cooldown
          runeCdDurs[id] = duration;
          runeCdExps[id] = endTime;
          runeCdHandles[id] = timer:ScheduleTimerFixed(RuneCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("RUNE_COOLDOWN_STARTED", id);
        elseif(runeCdExps[id] ~= endTime) then
          -- Cooldown is now different
          if(runeCdHandles[id]) then
            timer:CancelTimer(runeCdHandles[id]);
          end
          runeCdDurs[id] = duration;
          runeCdExps[id] = endTime;
          runeCdHandles[id] = timer:ScheduleTimerFixed(RuneCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("RUNE_COOLDOWN_CHANGED", id);
        end
      elseif(duration > 0) then
      -- GCD, do nothing
      else
        if(runeCdExps[id]) then
          -- Somehow CheckCooldownReady caught the rune cooldown before the timer callback
          -- This shouldn't happen, but if it does, no problem
          if(runeCdHandles[id]) then
            timer:CancelTimer(runeCdHandles[id]);
          end
          RuneCooldownFinished(id);
        end
      end
    end
    return runeDuration;
  end

  ---@param id string
  ---@param runeDuration? number
  function WeakAuras.GetSpellCooldownUnified(id, runeDuration)
    local startTimeCooldown, durationCooldown, enabled, modRate
    if GetSpellCooldown then
      startTimeCooldown, durationCooldown, enabled, modRate = GetSpellCooldown(id)
    else
      local spellCooldownInfo = C_Spell.GetSpellCooldown(id);
      if spellCooldownInfo then
        startTimeCooldown = spellCooldownInfo.startTime
        durationCooldown = spellCooldownInfo.duration
        enabled = spellCooldownInfo.isEnabled
        modRate = spellCooldownInfo.modRate
      end
    end

    local charges, maxCharges, startTimeCharges, durationCharges, modRateCharges = GetSpellCharges(id);

    startTimeCooldown = startTimeCooldown or 0;
    durationCooldown = durationCooldown or 0;

    startTimeCharges = startTimeCharges or 0;
    durationCharges = durationCharges or 0;

    modRate = modRate or 1.0;
    modRateCharges = modRateCharges or 1.0;

    -- WORKAROUND: Sometimes the API returns very high bogus numbers causing client freezes, discard them here. CurseForge issue #1008
    if (durationCooldown > 604800) then
      durationCooldown = 0;
      startTimeCooldown = 0;
    end

    if (startTimeCooldown > GetTime() + 2^31 / 1000) then
      -- WORKAROUND: WoW wraps around negative values with 2^32/1000
      -- So if we find a cooldown in the far future, then undo the wrapping
      startTimeCooldown = startTimeCooldown - 2^32 / 1000
    end

    -- Default to
    ---@type boolean?
    local unifiedCooldownBecauseRune = false
    ---@type boolean?
    local cooldownBecauseRune = false
    -- Paused cooldowns are:
    -- Spells like Presence of Mind/Nature's Swiftness that start their cooldown after the effect is consumed
    -- But also oddly some Evoker spells
    -- Presence of Might is on 0.0001 enabled == 0 cooldown while prepared
    -- For Evoker, using an empowered spell puts spells on pause. Some spells are put on an entirely bogus 0.5 paused cd
    -- Others the real cd (that continues ticking) is paused.
    -- We treat anything with less than 0.5 as not on cd, and hope for the best.
    if enabled == 0 and durationCooldown <= 0.5 then
      startTimeCooldown, durationCooldown, enabled = 0, 0, 1
    end

    local onNonGCDCD = durationCooldown and startTimeCooldown and durationCooldown > 0 and (durationCooldown ~= gcdDuration or startTimeCooldown ~= gcdStart);
    if (onNonGCDCD) then
      cooldownBecauseRune = runeDuration and durationCooldown and abs(durationCooldown - runeDuration) < 0.001;
      unifiedCooldownBecauseRune = cooldownBecauseRune
    end

    local startTime, duration, unifiedModRate = startTimeCooldown, durationCooldown, modRate
    if (charges == nil) then
      -- charges is nil if the spell has no charges.
      -- Nothing to do in that case
    elseif (charges == maxCharges) then
      -- At max charges,
      startTime, duration = 0, 0;
      startTimeCharges, durationCharges = 0, 0
    else
      -- Spells can return both information via GetSpellCooldown and GetSpellCharges
      -- E.g. Rune of Power see Github-Issue: #1060
      -- So if GetSpellCooldown returned a cooldown, use that one, if it's a "significant" cooldown
      --  Otherwise check GetSpellCharges
      -- A few abilities have a minor cooldown just to prevent the user from triggering it multiple times,
      -- ignore them since practically no one wants to see them
      if duration and duration <= 1.5 or (duration == gcdDuration and startTime == gcdStart) then
        startTime, duration, unifiedModRate = startTimeCharges, durationCharges, modRateCharges
        unifiedCooldownBecauseRune = false
      end
    end

    local count = GetSpellCount(id)

    return charges, maxCharges, startTime, duration, unifiedCooldownBecauseRune,
           startTimeCooldown, durationCooldown, cooldownBecauseRune, startTimeCharges, durationCharges,
           count, unifiedModRate, modRate, modRateCharges, enabled == 0
  end

  ---@type fun()
  function Private.CheckSpellKnown()
    local overrides = {}
    -- First check for overrides, if we don't yet track a specific override, add it
    for id, _ in pairs(checkOverrideSpell) do
      local override
      if type(id) == "number" then
        override = FindSpellOverrideByID(id)
      else
        local spellId = select(7, Private.ExecEnv.GetSpellInfo(id))
        if spellId then
          override = FindSpellOverrideByID(spellId)
        end
      end
      if id ~= override and override and not spells[override] then
        WeakAuras.WatchSpellCooldown(override, false, false)
      end
      overrides[id] = override
    end

    for id, _ in pairs(spells) do
      local known = WeakAuras.IsSpellKnownIncludingPet(id);
      local changed = false
      if (known ~= spellKnown[id]) then
        spellKnown[id] = known
        changed = true
      end

      local name, _, icon, _, _, _, spellId = Private.ExecEnv.GetSpellInfo(id)
      if spellDetails[id].name ~= name then
        spellDetails[id].name = name
        changed = true
      end
      if spellDetails[id].icon ~= icon then
        spellDetails[id].icon = icon
        changed = true
      end
      if spellDetails[id].id ~= spellId then
        spellDetails[id].id = spellId
        changed = true
      end

      if checkOverrideSpell[id] then
        local override = overrides[id]
        if spellDetails[id].override ~= override then
          spellDetails[id].override = override
          changed = true
        end
      end

      if changed and not WeakAuras.IsPaused() then
        WeakAuras.ScanEvents("SPELL_COOLDOWN_CHANGED", id)
      end
    end
  end

  ---@type fun(id, runeDuration)
  function Private.CheckSpellCooldown(id, runeDuration)
    local charges, maxCharges, startTime, duration, unifiedCooldownBecauseRune,
          startTimeCooldown, durationCooldown, cooldownBecauseRune, startTimeCharges, durationCharges,
          spellCount, unifiedModRate, modRate, modRateCharges, paused
          = WeakAuras.GetSpellCooldownUnified(id, runeDuration);

    local time = GetTime();

    local chargesChanged = spellCharges[id] ~= charges or spellCounts[id] ~= spellCount
                           or spellChargesMax[id] ~= maxCharges
    local chargesDifference = (charges or spellCount or 0) - (spellCharges[id] or spellCounts[id] or 0)
    spellCharges[id] = charges;
    spellChargesMax[id] = maxCharges;
    spellCounts[id] = spellCount
    if chargesDifference ~= 0 then
      if chargesDifference > 0 then
        spellChargeGainTime[id] = time
        spellChargeLostTime[id] = nil
      else
        spellChargeGainTime[id] = nil
        spellChargeLostTime[id] = time
      end
    end

    local changed = false
    changed = spellCds:HandleSpell(id, startTime, duration, unifiedModRate, paused) or changed
    if not unifiedCooldownBecauseRune then
      changed = spellCdsRune:HandleSpell(id, startTime, duration, unifiedModRate, paused) or changed
    end
    local cdChanged, nowReady = spellCdsOnlyCooldown:HandleSpell(id, startTimeCooldown, durationCooldown, modRate, paused)
    changed = cdChanged or changed
    if not cooldownBecauseRune then
      changed = spellCdsOnlyCooldownRune:HandleSpell(id, startTimeCooldown, durationCooldown, modRate, paused) or changed
    end
    local chargeChanged, chargeNowReady = spellCdsCharges:HandleSpell(id, startTimeCharges, durationCharges, modRateCharges)
    changed = chargeChanged or changed
    nowReady = chargeNowReady or nowReady

    if not WeakAuras.IsPaused() then
      if nowReady then
        WeakAuras.ScanEvents("SPELL_COOLDOWN_READY", id);
      end

      if changed or chargesChanged then
        WeakAuras.ScanEvents("SPELL_COOLDOWN_CHANGED", id);
      end

      if (chargesDifference ~= 0 ) then
        WeakAuras.ScanEvents("SPELL_CHARGES_CHANGED", id, chargesDifference, charges or spellCount or 0);
      end
    end
  end

  ---@type fun(runeDuration)
  function Private.CheckSpellCooldows(runeDuration)
    for id, _ in pairs(spells) do
      Private.CheckSpellCooldown(id, runeDuration)
    end
  end

  ---@type fun()
  function Private.CheckItemCooldowns()
    for id, _ in pairs(items) do
      local startTime, duration, enabled = C_Container.GetItemCooldown(id);
      -- TODO: In 10.2.6 the apis return values changed from 1,0 for enabled to true, false
      -- We should adjust once its on all versions
      if enabled == false then
        enabled = 0
      elseif enabled == true then
        enabled = 1
      end
      if (duration == 0) then
        enabled = 1;
      end
      if (enabled == 0) then
        startTime, duration = 0, 0
      end

      local itemCdEnabledChanged = (itemCdEnabled[id] ~= enabled);
      itemCdEnabled[id] = enabled;
      startTime = startTime or 0;
      duration = duration or 0;
      local time = GetTime();

      -- We check against 1.5 and gcdDuration, as apparently the durations might not match exactly.
      -- But there shouldn't be any trinket with a actual cd of less than 1.5 anyway
      if(duration > 0 and duration > 1.5 and duration ~= WeakAuras.gcdDuration()) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(itemCdExps[id]) then
          -- New cooldown
          itemCdDurs[id] = duration;
          itemCdExps[id] = endTime;
          itemCdHandles[id] = timer:ScheduleTimerFixed(ItemCooldownFinished, endTime - time, id);
          if not WeakAuras.IsPaused() then
            WeakAuras.ScanEvents("ITEM_COOLDOWN_STARTED", id)
          end
          itemCdEnabledChanged = false;
        elseif(itemCdExps[id] ~= endTime) then
          -- Cooldown is now different
          if(itemCdHandles[id]) then
            timer:CancelTimer(itemCdHandles[id]);
          end
          itemCdDurs[id] = duration;
          itemCdExps[id] = endTime;
          itemCdHandles[id] = timer:ScheduleTimerFixed(ItemCooldownFinished, endTime - time, id);
          if not WeakAuras.IsPaused() then
            WeakAuras.ScanEvents("ITEM_COOLDOWN_CHANGED", id)
          end
          itemCdEnabledChanged = false;
        end
      elseif(duration > 0) then
      -- GCD, do nothing
      else
        if(itemCdExps[id]) then
          -- Somehow CheckCooldownReady caught the item cooldown before the timer callback
          -- This shouldn't happen, but if it does, no problem
          if(itemCdHandles[id]) then
            timer:CancelTimer(itemCdHandles[id]);
          end
          ItemCooldownFinished(id);
          itemCdEnabledChanged = false;
        end
      end
      if (itemCdEnabledChanged and not WeakAuras.IsPaused()) then
        WeakAuras.ScanEvents("ITEM_COOLDOWN_CHANGED", id);
      end
    end
  end

  ---@type fun()
  function Private.CheckItemSlotCooldowns()
    for id, itemId in pairs(itemSlots) do
      local startTime, duration, enable = GetInventoryItemCooldown("player", id);
      itemSlotsEnable[id] = enable;
      startTime = startTime or 0;
      duration = duration or 0;
      local time = GetTime();

      -- We check against 1.5 and gcdDuration, as apparently the durations might not match exactly.
      -- But there shouldn't be any trinket with a actual cd of less than 1.5 anyway
      if(duration > 0 and duration > 1.5 and duration ~= WeakAuras.gcdDuration()) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(itemSlotsCdExps[id]) then
          -- New cooldown
          itemSlotsCdDurs[id] = duration;
          itemSlotsCdExps[id] = endTime;
          itemSlotsCdHandles[id] = timer:ScheduleTimerFixed(ItemSlotCooldownFinished, endTime - time, id);
          if not WeakAuras.IsPaused() then
            WeakAuras.ScanEvents("ITEM_SLOT_COOLDOWN_STARTED", id)
          end
        elseif(itemSlotsCdExps[id] ~= endTime) then
          -- Cooldown is now different
          if(itemSlotsCdHandles[id]) then
            timer:CancelTimer(itemSlotsCdHandles[id]);
          end
          itemSlotsCdDurs[id] = duration;
          itemSlotsCdExps[id] = endTime;
          itemSlotsCdHandles[id] = timer:ScheduleTimerFixed(ItemSlotCooldownFinished, endTime - time, id);
          if not WeakAuras.IsPaused() then
            WeakAuras.ScanEvents("ITEM_SLOT_COOLDOWN_CHANGED", id)
          end
        end
      elseif(duration > 0) then
      -- GCD, do nothing
      else
        if(itemSlotsCdExps[id]) then
          -- Somehow CheckCooldownReady caught the item cooldown before the timer callback
          -- This shouldn't happen, but if it does, no problem
          if(itemSlotsCdHandles[id]) then
            timer:CancelTimer(itemSlotsCdHandles[id]);
          end
          ItemSlotCooldownFinished(id);
        end
      end

      local newItemId = GetInventoryItemID("player", id);
      if (itemId ~= newItemId) then
        if not WeakAuras.IsPaused() then
          WeakAuras.ScanEvents("ITEM_SLOT_COOLDOWN_ITEM_CHANGED")
        end
        itemSlots[id] = newItemId or 0;
      end
    end
  end

  ---@type fun()
  function Private.CheckCooldownReady()
    CheckGCD();
    local runeDuration = Private.CheckRuneCooldown();
    Private.CheckSpellCooldows(runeDuration);
    Private.CheckItemCooldowns();
    Private.CheckItemSlotCooldowns();
  end

  ---@private
  function WeakAuras.WatchGCD()
    if not(cdReadyFrame) then
      Private.InitCooldownReady();
    end
  end

  ---@private
  function WeakAuras.WatchRuneCooldown(id)
    if not(cdReadyFrame) then
      Private.InitCooldownReady();
    end

    if not id or id == 0 then return end

    if not(runes[id]) then
      runes[id] = true;
      local startTime, duration = GetRuneCooldown(id);

      if(not startTime or startTime == 0) then
        startTime = 0
        duration = 0
      end

      if(duration > 0 and duration ~= WeakAuras.gcdDuration()) then
        local time = GetTime();
        local endTime = startTime + duration;
        runeCdDurs[id] = duration;
        runeCdExps[id] = endTime;
        if not(runeCdHandles[id]) then
          runeCdHandles[id] = timer:ScheduleTimerFixed(RuneCooldownFinished, endTime - time, id);
        end
      end
    end
  end

  ---@private
  function WeakAuras.WatchSpellCooldown(id, ignoreRunes, followoverride)
    if not(cdReadyFrame) then
      Private.InitCooldownReady();
    end

    if not id or id == 0 then return end

    if ignoreRunes and WeakAuras.IsCataOrRetail() then
      for i = 1, 6 do
        WeakAuras.WatchRuneCooldown(i);
      end
    end

    if (spells[id] and not followoverride or checkOverrideSpell[id]) then
      return;
    end
    spells[id] = true;
    checkOverrideSpell[id] = followoverride
    local name, _, icon, _, _, _, spellId = Private.ExecEnv.GetSpellInfo(id)
    spellDetails[id] = {
      name = name,
      icon = icon,
      id = spellId
    }

    if followoverride then
      if type(id) == "number" then
        spellDetails[id].override = FindSpellOverrideByID(id)
      else
        spellDetails[id].override = spellId and FindSpellOverrideByID(spellId) or nil
      end
    end

    spellKnown[id] = WeakAuras.IsSpellKnownIncludingPet(id);

    local charges, maxCharges, startTime, duration, unifiedCooldownBecauseRune,
          startTimeCooldown, durationCooldown, cooldownBecauseRune, startTimeCharges, durationCharges,
          spellCount, unifiedModRate, modRate, modRateCharges, paused
          = WeakAuras.GetSpellCooldownUnified(id, GetRuneDuration());

    spellCharges[id] = charges;
    spellChargesMax[id] = maxCharges;
    spellCounts[id] = spellCount
    spellCds:HandleSpell(id, startTime, duration, unifiedModRate, paused)
    if not unifiedCooldownBecauseRune then
      spellCdsRune:HandleSpell(id, startTime, duration, unifiedModRate, paused)
    end
    spellCdsOnlyCooldown:HandleSpell(id, startTimeCooldown, durationCooldown, modRate, paused)
    if not cooldownBecauseRune then
      spellCdsOnlyCooldownRune:HandleSpell(id, startTimeCooldown, durationCooldown, modRate, paused)
    end
    spellCdsCharges:HandleSpell(id, startTimeCharges, durationCharges, modRateCharges, paused)

    if spellDetails[id].override then
      -- If this spell is overridden and the option is on, track the overridden spell too
      if spellDetails[id].override ~= id then
        WeakAuras.WatchSpellCooldown(spellDetails[id].override, false, false)
      end
    end
  end

  ---@private
  function WeakAuras.WatchItemCooldown(id)
    if not(cdReadyFrame) then
      Private.InitCooldownReady();
    end

    if not id or id == 0 then return end

    if not(items[id]) then
      items[id] = true;
      -- TODO: In 10.2.6 the apis return values changed from 1,0 for enabled to true, false
      -- We should adjust once its on all versions
      local startTime, duration, enabled = C_Container.GetItemCooldown(id);
      if (duration == 0) then
        enabled = 1;
      end
      if (enabled == 0) then
        startTime, duration = 0, 0
      end
      itemCdEnabled[id] = enabled;
      if(duration > 0 and duration > 1.5 and duration ~= WeakAuras.gcdDuration()) then
        local time = GetTime();
        local endTime = startTime + duration;
        itemCdDurs[id] = duration;
        itemCdExps[id] = endTime;
        if not(itemCdHandles[id]) then
          itemCdHandles[id] = timer:ScheduleTimerFixed(ItemCooldownFinished, endTime - time, id);
        end
      end
    end
  end

  ---@private
  function WeakAuras.WatchItemSlotCooldown(id)
    if not(cdReadyFrame) then
      Private.InitCooldownReady();
    end

    if not id or id == 0 then return end

    if not(itemSlots[id]) then
      itemSlots[id] = GetInventoryItemID("player", id);
      local startTime, duration, enable = GetInventoryItemCooldown("player", id);
      itemSlotsEnable[id] = enable;
      if(duration > 0 and duration > 1.5 and duration ~= WeakAuras.gcdDuration()) then
        local time = GetTime();
        local endTime = startTime + duration;
        itemSlotsCdDurs[id] = duration;
        itemSlotsCdExps[id] = endTime;
        if not(itemSlotsCdHandles[id]) then
          itemSlotsCdHandles[id] = timer:ScheduleTimerFixed(ItemSlotCooldownFinished, endTime - time, id);
        end
      end
    end
  end
end

do
  local spellActivationSpells = {};
  local spellActivationSpellsCurrent = {};
  local spellActivationFrame;
  local function InitSpellActivation()
    spellActivationFrame = CreateFrame("Frame");
    Private.frames["Spell Activation"] = spellActivationFrame;
    spellActivationFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW");
    spellActivationFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE");
    spellActivationFrame:SetScript("OnEvent", function(self, event, spell)
      Private.StartProfileSystem("generictrigger");
      local spellName = Private.ExecEnv.GetSpellName(spell)
      if (spellActivationSpells[spell] or spellActivationSpells[spellName]) then
        local active = (event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
        spellActivationSpellsCurrent[spell] = active
        spellActivationSpellsCurrent[spellName] = active
        if not WeakAuras.IsPaused() then
          WeakAuras.ScanEvents("WA_UPDATE_OVERLAY_GLOW", spell)
        end
      end

      Private.StopProfileSystem("generictrigger");
    end);
  end

  ---@private
  function WeakAuras.WatchSpellActivation(id)
    if (not id) then
      return;
    end
    if (not spellActivationFrame) then
      InitSpellActivation();
    end
    spellActivationSpells[id] = true;
  end

  ---@param id string
  ---@return boolean overlayGlowActive
  function WeakAuras.SpellActivationActive(id)
    return spellActivationSpellsCurrent[id];
  end
end

local watchUnitChange

-- Nameplates only distinguish between friends and everyone else
---@param unit UnitToken
---@return string? reaction
function WeakAuras.GetPlayerReaction(unit)
  local r = UnitReaction("player", unit)
  if r then
    return r < 5 and "hostile" or "friendly"
  end
end

---@param unit UnitToken
function WeakAuras.WatchUnitChange(unit)
  unit = string.lower(unit)
  if not watchUnitChange then
    ---@class UnitChangeFrame: FrameScriptObject
    watchUnitChange = CreateFrame("Frame");
    watchUnitChange.unitChangeGUIDS = {}
    watchUnitChange.unitRoles = {}
    watchUnitChange.unitRaidRole = {}
    watchUnitChange.inRaid = IsInRaid()
    watchUnitChange.nameplateFaction = {}
    watchUnitChange.raidmark = {}

    Private.frames["Unit Change Frame"] = watchUnitChange;
    watchUnitChange:RegisterEvent("PLAYER_TARGET_CHANGED")
    if not WeakAuras.IsClassicEra() then
      watchUnitChange:RegisterEvent("PLAYER_FOCUS_CHANGED")
    else
      watchUnitChange:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    end
    watchUnitChange:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
    watchUnitChange:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
    watchUnitChange:RegisterEvent("UNIT_TARGET");
    watchUnitChange:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT");
    watchUnitChange:RegisterEvent("GROUP_ROSTER_UPDATE");
    watchUnitChange:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    watchUnitChange:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    watchUnitChange:RegisterEvent("UNIT_FACTION")
    watchUnitChange:RegisterEvent("PLAYER_ENTERING_WORLD")
    watchUnitChange:RegisterEvent("UNIT_PET")
    watchUnitChange:RegisterEvent("RAID_TARGET_UPDATE")

    watchUnitChange:SetScript("OnEvent", function(self, event, unit)
      Private.StartProfileSystem("generictrigger unit change");
      if event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        local newGuid = WeakAuras.UnitExistsFixed(unit) and UnitGUID(unit) or ""
        local newMarker = GetRaidTargetIndex(unit) or 0
        if newGuid ~= watchUnitChange.unitChangeGUIDS[unit] then
          WeakAuras.ScanEvents("UNIT_CHANGED_" .. unit, unit)
          watchUnitChange.unitChangeGUIDS[unit] = newGuid
          watchUnitChange.raidmark[unit] = newMarker
        end
        if event == "NAME_PLATE_UNIT_ADDED" then
          watchUnitChange.nameplateFaction[unit] = WeakAuras.GetPlayerReaction(unit)
        end
      elseif event == "UNIT_FACTION" then
        if unit:sub(1, 9) == "nameplate" then
          local reaction = WeakAuras.GetPlayerReaction(unit)
          if reaction ~= watchUnitChange.nameplateFaction[unit] then
            watchUnitChange.nameplateFaction[unit] = reaction
            WeakAuras.ScanEvents("UNIT_CHANGED_" .. unit, unit)
          end
        end
      elseif event == "UNIT_PET" then
        local pet = WeakAuras.unitToPetUnit[unit]
        if pet then
          WeakAuras.ScanEvents("UNIT_CHANGED_" .. pet, pet)
        end
      elseif event == "RAID_TARGET_UPDATE" then
        for unit, marker in pairs(watchUnitChange.raidmark) do
          local newMarker = GetRaidTargetIndex(unit) or 0
          if marker ~= newMarker then
            watchUnitChange.raidmark[unit] = newMarker
            WeakAuras.ScanEvents("UNIT_CHANGED_" .. unit, unit)
          end
        end
      else
        local inRaid = IsInRaid()
        local inRaidChanged = inRaid ~= watchUnitChange.inRaid

        for unit, guid in pairs(watchUnitChange.unitChangeGUIDS) do
          local newGuid = WeakAuras.UnitExistsFixed(unit) and UnitGUID(unit) or ""
          local newMarker = GetRaidTargetIndex(unit) or 0
          if guid ~= newGuid
          or newMarker ~= watchUnitChange.raidmark[unit]
          or event == "PLAYER_ENTERING_WORLD"
          then
            WeakAuras.ScanEvents("UNIT_CHANGED_" .. unit, unit)
            watchUnitChange.unitChangeGUIDS[unit] = newGuid
            watchUnitChange.raidmark[unit] = newMarker
          elseif Private.multiUnitUnits.group[unit] then
            -- If in raid changed we send a UNIT_CHANGED for the group units
            if inRaidChanged then
              WeakAuras.ScanEvents("UNIT_CHANGED_" .. unit, unit)
            else
              if WeakAuras.IsClassicEra() then
                local newRaidRole = WeakAuras.UnitRaidRole(unit)
                if watchUnitChange.unitRaidRole[unit] ~= newRaidRole then
                  watchUnitChange.unitRaidRole[unit] = newRaidRole
                  WeakAuras.ScanEvents("UNIT_ROLE_CHANGED_" .. unit, unit)
                end
              end
              if WeakAuras.IsCataOrRetail() then
                local newRole = UnitGroupRolesAssigned(unit)
                if watchUnitChange.unitRoles[unit] ~= newRole then
                  watchUnitChange.unitRoles[unit] = newRole
                  WeakAuras.ScanEvents("UNIT_ROLE_CHANGED_" .. unit, unit)
                end
              end
            end
          end
        end
        watchUnitChange.inRaid = inRaid
      end
      Private.StopProfileSystem("generictrigger unit change");
    end)
  end
  watchUnitChange.unitChangeGUIDS = watchUnitChange.unitChangeGUIDS or {}
  watchUnitChange.unitChangeGUIDS[unit] = UnitGUID(unit) or ""
  watchUnitChange.raidmark = watchUnitChange.raidmark or {}
  watchUnitChange.raidmark[unit] = GetRaidTargetIndex(unit) or 0
end

function WeakAuras.GetEquipmentSetInfo(itemSetName, partial)
  local bestMatchNumItems = 0;
  local bestMatchNumEquipped = 0;
  local bestMatchName = nil;
  local bestMatchIcon = nil;

  local equipmentSetIds = C_EquipmentSet.GetEquipmentSetIDs();
  for index, id in pairs(equipmentSetIds) do
    local name, icon, _, _, numItems, numEquipped = C_EquipmentSet.GetEquipmentSetInfo(id);
    if (itemSetName == nil or (name and itemSetName == name)) then
      if (name ~= nil) then
        local match = (not partial and numItems == numEquipped)
          or (partial and (numEquipped or 0) > bestMatchNumEquipped);
        if (match) then
          bestMatchNumEquipped = numEquipped;
          bestMatchNumItems = numItems;
          bestMatchName = name;
          bestMatchIcon = icon;
        end
      end
    end
  end
  return bestMatchName, bestMatchIcon, bestMatchNumEquipped, bestMatchNumItems;
end

function Private.ExecEnv.CheckTotemName(totemName, triggerTotemName, triggerTotemPattern, triggerTotemOperator)
  if not totemName or totemName == "" then
    return false
  end

  if triggerTotemName and #triggerTotemName > 0 and triggerTotemName ~= totemName then
    return false
  end

  if triggerTotemPattern and #triggerTotemPattern > 0 then
    if triggerTotemOperator == "==" then
      if totemName ~= triggerTotemPattern then
        return false
      end
    elseif triggerTotemOperator == "find('%s')" then
      if not totemName:find(triggerTotemPattern, 1, true) then
        return false
      end
    elseif triggerTotemOperator == "match('%s')" then
      if not totemName:match(triggerTotemPattern) then
        return false
      end
    end
  end

  return true
end

-- Queueable Spells
if WeakAuras.IsClassicEra() then
  local queueableSpells
  local classQueueableSpells = {
    ["WARRIOR"] = {
      78,    -- Heroic Strike
      845,   -- Cleave
    },
    ["HUNTER"] = {
      2973,  -- Raptor Strike
    },
    ["DRUID"] = {
      6807,  -- Maul
    },
    ["DEATHKNIGHT"] = {
      56815, -- Rune Strike
    },
  }
  local class = select(2, UnitClass("player"))
  queueableSpells = classQueueableSpells[class]

  local queuedSpellFrame
  function WeakAuras.WatchForQueuedSpell()
    if not queuedSpellFrame then
      queuedSpellFrame = CreateFrame("Frame")
      Private.frames["Queued Spell Handler"] = queuedSpellFrame
      queuedSpellFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")

      queuedSpellFrame:SetScript("OnEvent", function(self, event)
        local newQueuedSpell
        if queueableSpells then
          for _, spellID in ipairs(queueableSpells) do
            -- Check the highest known rank
            local maxRank = select(7, Private.ExecEnv.GetSpellInfo(Private.ExecEnv.GetSpellName(spellID)))
            if IsCurrentSpell(maxRank) then
              newQueuedSpell = maxRank
              break
            end
          end
        end
        if newQueuedSpell ~= self.queuedSpell then
          self.queuedSpell = newQueuedSpell
          WeakAuras.ScanEvents("WA_UNIT_QUEUED_SPELL_CHANGED", "player")
        end
      end)
    end
  end

  ---@return integer? spellID
  function WeakAuras.GetQueuedSpell()
    return queuedSpellFrame and queuedSpellFrame.queuedSpell
  end
end

---@param powerTypeToCheck integer
---@return number? cost
function WeakAuras.GetSpellCost(powerTypeToCheck)
  local spellID = select(9, WeakAuras.UnitCastingInfo("player"))
  if WeakAuras.IsClassicEra() and not spellID then
    spellID = WeakAuras.GetQueuedSpell()
  end
  if spellID then
    local costTable = GetSpellPowerCost(spellID);
    for _, costInfo in pairs(costTable) do
      -- When there is no required aura for a power cost, the API returns an aura ID of 0 and false for hasRequiredAura despite being valid.
      if costInfo.type == powerTypeToCheck and (costInfo.requiredAuraID == 0 or costInfo.hasRequiredAura) then
        return costInfo.cost;
      end
    end
  end
end

-- Weapon Enchants
do
  local isCata = WeakAuras.IsCataClassic()

  local mh = GetInventorySlotInfo("MainHandSlot")
  local oh = GetInventorySlotInfo("SecondaryHandSlot")

  local mh_name, mh_shortenedName, mh_exp, mh_dur, mh_charges, mh_EnchantID;
  ---@type string?
  local mh_icon = GetInventoryItemTexture("player", mh) or "Interface\\Icons\\INV_Misc_QuestionMark"

  local oh_name, oh_shortenedName, oh_exp, oh_dur, oh_charges, oh_EnchantID;
  ---@type string?
  local oh_icon = GetInventoryItemTexture("player", oh) or "Interface\\Icons\\INV_Misc_QuestionMark"

  local rw, rw_icon, rw_exp, rw_dur, rw_name, rw_shortenedName, rw_charges, rw_EnchantID;
  ---@type string?
  if isCata then
    rw = GetInventorySlotInfo("RANGEDSLOT")
    rw_icon = GetInventoryItemTexture("player", rw) or "Interface\\Icons\\INV_Misc_QuestionMark"
  end

  local tenchFrame = nil
  Private.frames["Temporary Enchant Handler"] = tenchFrame;
  local tenchTip;

  ---@private
  function WeakAuras.TenchInit()
    if not(tenchFrame) then
      tenchFrame = CreateFrame("Frame");
      tenchFrame:RegisterEvent("UNIT_INVENTORY_CHANGED");
      tenchFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
      if WeakAuras.IsClassicEra() then
        tenchFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
      end

      local getTenchName
      if WeakAuras.IsRetail() then
        getTenchName = function(id)
          local tooltipData = C_TooltipInfo.GetInventoryItem("player", id)
          if tooltipData and tooltipData.lines then
            for _, line in ipairs(tooltipData.lines) do
              if line.leftText then
                -- Format based on ITEM_ENCHANT_TIME_LEFT_MIN, ITEM_ENCHANT_TIME_LEFT_SEC
                local _, _, name, shortenedName = line.leftText:find("^((.-) ?+?[VI%d]*) ?%(%d+%D.+%)$");
                if(name and name ~= "") then
                  return name, shortenedName;
                end
                _, _, name, shortenedName = line.leftText:find("^((.-) ?+?[VI%d]*)%（%d+%D.+%）$");
                if(name and name ~= "") then
                  return name, shortenedName;
                end
              end
            end
          end
        end
      else
        getTenchName = function(id)
          tenchTip = WeakAuras.GetHiddenTooltip();
          tenchTip:SetInventoryItem("player", id);
          local lines = { tenchTip:GetRegions() };
          for i,v in ipairs(lines) do
            if(v:GetObjectType() == "FontString") then
              local text = v:GetText();
              if(text) then
                local _, _, name, shortenedName = text:find("^((.-) ?+?[VI%d]*) ?%(%d+%D+%)$");
                if(name and name ~= "") then
                  return name, shortenedName;
                end
                _, _, name, shortenedName = text:find("^((.-) ?+?[VI%d]*)%（%d+.%D%）$");
                if(name and name ~= "") then
                  return name, shortenedName;
                end
              end
            end
          end

          return "Unknown", "Unknown";
        end
      end

      local function tenchUpdate()
        Private.StartProfileSystem("generictrigger");
        local _, mh_rem, oh_rem, rw_rem
        _, mh_rem, mh_charges, mh_EnchantID, _, oh_rem, oh_charges, oh_EnchantID, _, rw_rem, rw_charges, rw_EnchantID = GetWeaponEnchantInfo();
        local time = GetTime();
        local mh_exp_new = mh_rem and (time + (mh_rem / 1000));
        local oh_exp_new = oh_rem and (time + (oh_rem / 1000));
        local rw_exp_new = rw_rem and (time + (rw_rem / 1000));
        if(math.abs((mh_exp or 0) - (mh_exp_new or 0)) > 1) then
          mh_exp = mh_exp_new;
          mh_dur = mh_rem and mh_rem / 1000;
          if mh_exp then
            mh_name, mh_shortenedName = getTenchName(mh)
          else
            mh_name, mh_shortenedName = "None", "None"
          end
          mh_icon = GetInventoryItemTexture("player", mh)
        end
        if(math.abs((oh_exp or 0) - (oh_exp_new or 0)) > 1) then
          oh_exp = oh_exp_new;
          oh_dur = oh_rem and oh_rem / 1000;
          if oh_exp then
            oh_name, oh_shortenedName = getTenchName(oh)
          else
            oh_name, oh_shortenedName = "None", "None"
          end
          oh_icon = GetInventoryItemTexture("player", oh)
        end
        if isCata then
          if(math.abs((rw_exp or 0) - (rw_exp_new or 0)) > 1) then
            rw_exp = rw_exp_new;
            rw_dur = rw_rem and rw_rem / 1000;
            if rw_exp then
              rw_name, rw_shortenedName = getTenchName(rw)
            else
              rw_name, rw_shortenedName = "None", "None"
            end
            rw_icon = GetInventoryItemTexture("player", rw)
          end
        end
        WeakAuras.ScanEvents("TENCH_UPDATE");
        Private.StopProfileSystem("generictrigger");
      end

      tenchFrame:SetScript("OnEvent", function()
        Private.StartProfileSystem("generictrigger");
        timer:ScheduleTimer(tenchUpdate, 0.1);
        Private.StopProfileSystem("generictrigger");
      end);

      tenchUpdate();
    end
  end

  function WeakAuras.GetMHTenchInfo()
    return mh_exp, mh_dur, mh_name, mh_shortenedName, mh_icon, mh_charges, mh_EnchantID;
  end

  function WeakAuras.GetOHTenchInfo()
    return oh_exp, oh_dur, oh_name, oh_shortenedName, oh_icon, oh_charges, oh_EnchantID;
  end

  function WeakAuras.GetRangeTenchInfo()
    return rw_exp, rw_dur, rw_name, rw_shortenedName, rw_icon, rw_charges, rw_EnchantID;
  end
end

-- Pets
do
  local petFrame = nil
  Private.frames["Pet Use Handler"] = petFrame;
  ---@private
  function WeakAuras.WatchForPetDeath()
    if not(petFrame) then
      petFrame = CreateFrame("Frame");
      petFrame:RegisterUnitEvent("UNIT_PET", "player")
      petFrame:SetScript("OnEvent", function(event, unit)
        Private.StartProfileSystem("generictrigger")
        WeakAuras.ScanEvents("PET_UPDATE", "pet")
        Private.StopProfileSystem("generictrigger")
      end)
    end
  end
end

-- Cast Latency
do
  local castLatencyFrame

  ---@private
  function WeakAuras.WatchForCastLatency()
    if not castLatencyFrame then
      ---@class CastLatencyFrame: FrameScriptObject
      castLatencyFrame = CreateFrame("Frame")
      Private.frames["Cast Latency Handler"] = castLatencyFrame
      castLatencyFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
      castLatencyFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
      castLatencyFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
      castLatencyFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
      castLatencyFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
      castLatencyFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
      castLatencyFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

      -- on dragonflight UNIT_SPELLCAST_EMPOWER_START and UNIT_SPELLCAST_EMPOWER_STOP OnEvent are
      -- triggered from cacheEmpoweredFrame after updating cache use by WeakAuras.UnitChannelInfo

      castLatencyFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "CURRENT_SPELL_CAST_CHANGED" then
          castLatencyFrame.sendTime = GetTime()
          return
        end
        if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
          castLatencyFrame.sendTime = nil
          return
        end

        if castLatencyFrame.sendTime then
          castLatencyFrame.timeDiff = (GetTime() - castLatencyFrame.sendTime)
        else
          castLatencyFrame.timeDiff = nil
        end
      end)
    end
  end

  ---@return number castLatencyF
  function WeakAuras.GetCastLatency()
    return castLatencyFrame and castLatencyFrame.timeDiff or 0
  end

end

do
  local nameplateTargetFrame = nil
  local nameplateTargets = {}

  local function nameplateTargetOnEvent(self, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
      nameplateTargets[unit] = UnitGUID(unit.."-target") or true
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
      nameplateTargets[unit] = nil
    end
  end

  local tick_throttle = 0.2
  local throttle_update = tick_throttle
  local function nameplateTargetOnUpdate(self, delta)
    throttle_update = throttle_update - delta
    if throttle_update < 0 then
      for unit, targetGUID in pairs(nameplateTargets) do
        local newTargetGUID = UnitGUID(unit.."-target")
        if (newTargetGUID == nil and targetGUID ~= true)
        or (newTargetGUID ~= nil and targetGUID ~= newTargetGUID)
        then
          nameplateTargets[unit] = newTargetGUID or true
          WeakAuras.ScanEvents("WA_UNIT_TARGET_NAME_PLATE", unit)
        end
      end
      throttle_update = tick_throttle
    end
  end

  Private.frames["Nameplate Target Handler"] = nameplateTargetFrame
  ---@private
  function WeakAuras.WatchForNameplateTargetChange()
    if not nameplateTargetFrame then
      nameplateTargetFrame = CreateFrame("Frame")
      nameplateTargetFrame:SetScript("OnUpdate", nameplateTargetOnUpdate)
      nameplateTargetFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
      nameplateTargetFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
      nameplateTargetFrame:SetScript("OnEvent", nameplateTargetOnEvent)
    end
  end
end

-- Player Moving
do
  --- @class PlayerMovingFrame
  --- @field moving integer|nil
  --- @field speed integer|nil

  ---@type PlayerMovingFrame|Frame|nil
  local playerMovingFrame = nil

  local function PlayerMoveUpdate()
    Private.StartProfileSystem("generictrigger");
    local moving = IsPlayerMoving()
    if (playerMovingFrame.moving ~= moving or playerMovingFrame.moving == nil) then
      playerMovingFrame.moving = moving
      WeakAuras.ScanEvents("PLAYER_MOVING_UPDATE")
    end

    local speed = GetUnitSpeed("player")
    if playerMovingFrame.speed ~= speed then
      playerMovingFrame.speed = speed
      WeakAuras.ScanEvents("PLAYER_MOVE_SPEED_UPDATE")
    end
    Private.StopProfileSystem("generictrigger");
  end

  ---@private
  function WeakAuras.WatchForPlayerMoving()
    if not(playerMovingFrame) then
      playerMovingFrame = CreateFrame("Frame");
      --- @cast playerMovingFrame PlayerMovingFrame
      Private.frames["Player Moving Frame"] =  playerMovingFrame;
      playerMovingFrame.speed = GetUnitSpeed("player")
    end
    playerMovingFrame:SetScript("OnUpdate", PlayerMoveUpdate)
  end
end

-- Item Count
local itemCountWatchFrame
---@private
function WeakAuras.RegisterItemCountWatch()
  if not itemCountWatchFrame then
    itemCountWatchFrame = CreateFrame("Frame")
    itemCountWatchFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    itemCountWatchFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    local batchUpdateCount = function()
      itemCountWatchFrame:SetScript("OnUpdate", nil)
      Private.StartProfileSystem("generictrigger ITEM_COUNT_UPDATE")
      WeakAuras.ScanEvents("ITEM_COUNT_UPDATE")
      Private.StopProfileSystem("generictrigger ITEM_COUNT_UPDATE")
    end
    itemCountWatchFrame:SetScript("OnEvent", function(self, event)
      Private.StartProfileSystem("generictrigger itemCountFrame")
      if event == "ACTIONBAR_UPDATE_COOLDOWN" then
        -- WORKAROUND: Blizzard bug: refreshing healthstones from soulwell don't trigger BAG_UPDATE_DELAYED
        -- so, we fake it by listening to A_U_C and checking on next frame
        itemCountWatchFrame:SetScript("OnUpdate", batchUpdateCount)
      else
        -- if we *do* get a B_U_D, then cancel our fake one
        -- item count prototype already subscribes to this event so no need to also send an internal event
        itemCountWatchFrame:SetScript("OnUpdate", nil)
      end
      Private.StopProfileSystem("generictrigger itemCountFrame")
    end)
  end
end

-- LibSpecWrapper
-- We always register, because it's probably not that often called, and ScanEvents checks
-- early if anyone wants the event
if WeakAuras.IsCataOrRetail() then
  Private.LibSpecWrapper.Register(function(unit)
    WeakAuras.ScanEvents("UNIT_SPEC_CHANGED_" .. unit, unit)
  end)
end

do
  local scheduled_scans = {};

  local function doScan(fireTime, event)
    scheduled_scans[event][fireTime] = nil;
    WeakAuras.ScanEvents(event);
  end
  function Private.ExecEnv.ScheduleScan(fireTime, event)
    event = event or "COOLDOWN_REMAINING_CHECK"
    scheduled_scans[event] = scheduled_scans[event] or {}
    if not(scheduled_scans[event][fireTime]) then
      scheduled_scans[event][fireTime] = timer:ScheduleTimerFixed(doScan, fireTime - GetTime() + 0.1, fireTime, event);
    end
  end
end

do
  local scheduled_scans = {};

  local function doCastScan(firetime, unit)
    scheduled_scans[unit][firetime] = nil;
    WeakAuras.ScanEvents("CAST_REMAINING_CHECK_" .. string.lower(unit), unit);
  end
  function Private.ExecEnv.ScheduleCastCheck(fireTime, unit)
    scheduled_scans[unit] = scheduled_scans[unit] or {}
    if not(scheduled_scans[unit][fireTime]) then
      scheduled_scans[unit][fireTime] = timer:ScheduleTimerFixed(doCastScan, fireTime - GetTime() + 0.1, fireTime, unit);
    end
  end
end

local uniqueId = 0;
---@return integer cloneId
function WeakAuras.GetUniqueCloneId()
  uniqueId = (uniqueId + 1) % 1000000;
  return uniqueId;
end

---@type fun(trigger: triggerData) : prototypeData?
function GenericTrigger.GetPrototype(trigger)
  if trigger.type and trigger.event then
    if Private.category_event_prototype[trigger.type] then
      return Private.event_prototypes[trigger.event]
    end
  end
end

---@type fun(data: auraData): number?
function GenericTrigger.GetDelay(data)
  if data.event then
    local prototype = GenericTrigger.GetPrototype(data.trigger)
    if prototype and prototype.delayEvents then
      local trigger = data.trigger
      if trigger.use_delay and type(trigger.delay) == "number" and trigger.delay > 0 then
        return trigger.delay
      end
    end
  end
  return 0
end

function GenericTrigger.GetTsuConditionVariables(id, triggernum)
  local ok, variables = xpcall(events[id][triggernum].tsuConditionVariables, Private.GetErrorHandlerId(id, L["Custom Variables"]));
  if ok then
    return variables
  end
end

---Returns a table containing the names of all overlays
---@param data auraData
---@param triggernum number
function GenericTrigger.GetOverlayInfo(data, triggernum)
  local result;

  local trigger = data.triggers[triggernum].trigger

  local prototype = GenericTrigger.GetPrototype(trigger)
  if (prototype and prototype.overlayFuncs) then
    result = {};
    local dest = 1;
    for i, v in ipairs(prototype.overlayFuncs) do
      local enable = true
      if type(v.enable) == "function" then
        enable = v.enable(trigger)
      elseif type(v.enable) == "boolean" then
        enable = v.enable
      end
      if enable then
        result[dest] = v.name;
        dest = dest + 1;
      end
    end
  end

  if (trigger.type == "custom") then
    if (trigger.custom_type == "stateupdate") then
      local count = 0;
      local variables = GenericTrigger.GetTsuConditionVariables(data.id, triggernum)
      if (type(variables) == "table") then
        if (type(variables.additionalProgress) == "table") then
          count = #variables.additionalProgress;
        elseif (type(variables.additionalProgress) == "number") then
          count = variables.additionalProgress;
        end
      else
        local allStates = {};
        Private.ActivateAuraEnvironment(data.id);
        RunTriggerFunc(allStates, events[data.id][triggernum], data.id, triggernum, "OPTIONS");
        Private.ActivateAuraEnvironment(nil);
        local count = 0;
        for id, state in pairs(allStates) do
          if (type(state.additionalProgress) == "table") then
            count = max(count, #state.additionalProgress);
          end
        end
      end

      count = min(count, 7);
      for i = 1, count do
        result = result or {};
        result[i] = string.format(L["Overlay %s"], i);
      end
    else
      for i = 1, 7 do
        local property = "customOverlay" .. i;
        if (trigger[property] and trigger[property] ~= "") then
          result = result or {};
          result[i] = string.format(L["Overlay %s"], i);
        end
      end
    end
  end

  return result;
end

---@type fun(data: auraData, triggernum: number): string?, string?
function GenericTrigger.GetNameAndIcon(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local icon, name
  local prototype = GenericTrigger.GetPrototype(trigger)
  if prototype then
    if prototype.GetNameAndIcon then
      return prototype.GetNameAndIcon(trigger)
    else
      if prototype.iconFunc then
        icon = prototype.iconFunc(trigger)
      end
      if prototype.nameFunc then
        name = prototype.nameFunc(trigger)
      end
    end
  end

  return name, icon
end

---Returns the type of tooltip to show for the trigger.
---@param data auraData
---@param triggernum number
---@return boolean|string
function GenericTrigger.CanHaveTooltip(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local prototype = GenericTrigger.GetPrototype(trigger)
  if prototype then
    if prototype.hasSpellID then
      return "spell";
    elseif prototype.hasItemID then
      return "item";
    end
  end

  if (trigger.type == "custom") then
    if (trigger.custom_type == "stateupdate") then
      return true;
    end
  end

  return false;
end

function GenericTrigger.SetToolTip(trigger, state)
  if (trigger.type == "custom" and trigger.custom_type == "stateupdate") then
    if (state.tooltip) then
      local lines = { strsplit("\n", state.tooltip) };
      GameTooltip:ClearLines();
      for i, line in ipairs(lines) do
        GameTooltip:AddLine(line, nil, nil, nil, state.tooltipWrap);
      end
      return true
    elseif (state.spellId) then
      GameTooltip:SetSpellByID(state.spellId);
      return true
    elseif (state.link) then
      GameTooltip:SetHyperlink(state.link);
      return true
    elseif (state.itemId) then
      GameTooltip:SetHyperlink("item:"..state.itemId..":0:0:0:0:0:0:0");
      return true
    elseif (state.unit and state.unitBuffIndex) then
      GameTooltip:SetUnitBuff(state.unit, state.unitBuffIndex, state.unitBuffFilter);
      return true
    elseif (state.unit and state.unitDebuffIndex) then
      GameTooltip:SetUnitDebuff(state.unit, state.unitDebuffIndex, state.unitDebuffFilter);
      return true
    elseif (state.unit and state.unitAuraIndex) then
      GameTooltip:SetUnitAura(state.unit, state.unitAuraIndex, state.unitAuraFilter)
      return true
    end
  end

  local prototype = GenericTrigger.GetPrototype(trigger)
  if prototype then
    if prototype.hasSpellID then
      GameTooltip:SetSpellByID(trigger.spellName);
      return true
    elseif prototype.hasItemID then
      GameTooltip:SetHyperlink("item:"..trigger.itemName..":0:0:0:0:0:0:0")
      return true
    end
  end
  return false
end

---@type fun(data: auraData, triggernum: number): string
function GenericTrigger.GetAdditionalProperties(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local ret = "";
  local prototype = GenericTrigger.GetPrototype(trigger)
  if prototype then
    local found = false;
    local additional = ""
    for _, v in pairs(prototype.args) do
      local enable = true
      if(type(v.enable) == "function") then
        enable = v.enable(trigger)
      elseif type(v.enable) == "boolean" then
        enable = v.enable
      end
      if (enable and v.store and v.name and v.display and v.conditionType ~= "bool") then
        found = true;
        additional = additional .. "|cFFFFCC00%".. triggernum .. "." .. v.name .. "|r - " .. v.display .. "\n";
      end
    end
    if prototype.countEvents then
      found = true;
      additional = additional .. "|cFFFFCC00%".. triggernum .. ".count|r - " .. L["Count"] .. "\n";
    end

    if (found) then
      ret = ret .. additional;
    end
  else
    if (trigger.custom_type == "stateupdate") then
      local variables = GenericTrigger.GetTsuConditionVariables(data.id, triggernum)
      if (type(variables) == "table") then
        for var, varData in pairs(variables) do
          if (type(varData) == "table") then
            if varData.display then
              ret = ret .. "|cFFFFCC00%".. triggernum .. "." .. var .. "|r - " .. varData.display .. "\n"
            end
          end
        end
      end
    end
  end

  return ret;
end

function GenericTrigger.GetProgressSources(data, triggernum, values)
  local variables = GenericTrigger.GetTriggerConditions(data, triggernum)
  if (type(variables) == "table") then
    for var, varData in pairs(variables) do
      if (type(varData) == "table") then
        if (varData.type == "number" or varData.type == "timer" or varData.type == "elapsedTimer")
           and not varData.noProgressSource
        then
          local modRateProperty = varData.modRate
          if not modRateProperty and varData.useModRate then
            modRateProperty = "modRate"
          end

          tinsert(values, {
            trigger = triggernum,
            property = var,
            type = varData.type,
            display = varData.display,
            total = varData.total,
            modRate = varData.modRate,
            inverse = varData.inverse,
            paused = varData.paused,
            remaining = varData.remaining
          })
        end
      end
    end
  end
end

local commonConditions = {
  expirationTime = {
    display = L["Remaining Duration"],
    type = "timer",
    total = "duration",
    inverse = "inverse",
    paused = "paused",
    remaining = "remaining",
  },
  expirationTimeModRate = {
    display = L["Remaining Duration"],
    type = "timer",
    total = "duration",
    modRate = "modRate",
    inverse = "inverse",
    paused = "paused",
    remaining = "remaining",
    useModRate = true
  },
  duration = {
    display = L["Total Duration"],
    type = "number",
  },
  durationModRate = {
    display = L["Total Duration"],
    type = "number",
    useModRate = true
  },
  paused = {
    display =L["Is Paused"],
    type = "bool",
    test = function(state, needle)
      return (state.paused and 1 or 0) == needle
    end
  },
  value = {
    display = L["Progress Value"],
    type = "number",
    total = "total"
  },
  total = {
    display = L["Progress Total"],
    type = "number",
  },
  stacks = {
    display = L["Stacks"],
    type = "number"
  },
  name = {
    display = L["Name"],
    type = "string"
  }
}

---@type fun(variables: table)
function Private.ExpandCustomVariables(variables)
  -- Make the life of tsu authors easier, by automatically filling in the details for
  -- expirationTime, duration, value, total, stacks, if those exists but aren't a table value
  -- By allowing a short-hand notation of just variable = type
  -- In addition to the long form of variable = { type = xyz, display = "desc"}
  for k, v in pairs(commonConditions) do
    if (variables[k] and type(variables[k]) ~= "table") then
      variables[k] = v;
    end
  end

  for k, v in pairs(variables) do
    if (type(v) == "string") then
      variables[k] = {
        display = k,
        type = v,
      };
    end
  end
end

function Private.GetTsuConditionVariablesExpanded(id, triggernum)
  if events[id][triggernum] and events[id][triggernum].tsuConditionVariables then
    Private.ActivateAuraEnvironment(id, nil, nil, nil, true)
    local result = GenericTrigger.GetTsuConditionVariables(id, triggernum)
    Private.ActivateAuraEnvironment(nil)
    if type(result) ~= "table" then
      return nil
    end
    Private.ExpandCustomVariables(result)
    -- Clean up, remove non table entries and check for a valid display name
    for k, v in pairs(result) do
      if type(v) ~= "table" then
        result[k] = nil
      elseif (v.display == nil or type(v.display) ~= "string") then
        if type(k) == "string" then
          v.display = k
        else
          result[k] = nil
        end
      end
    end

    return result
  end
end

function GenericTrigger.GetTriggerConditions(data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  local prototype = GenericTrigger.GetPrototype(trigger)
  if prototype then
    local result = {};

    local progressType, modRated = ProgressType(data, triggernum);
    if progressType == "timed" then
      if modRated then
        result.expirationTime = commonConditions.expirationTimeModRate;
        result.duration = commonConditions.durationModRate;
      else
        result.expirationTime = commonConditions.expirationTime;
        result.duration = commonConditions.duration;
      end
      result.paused = commonConditions.paused
    end

    if progressType == "static" then
      result.value = commonConditions.value;
      result.total = commonConditions.total;
    end

    if prototype.stacksFunc then
      result.stacks = commonConditions.stacks;
    end

    if prototype.nameFunc then
      result.name = commonConditions.name;
    end

    for _, v in pairs(prototype.args) do
      if (v.conditionType and v.name and v.display) then
        local enable = true;
        if (v.enable ~= nil) then
          if type(v.enable) == "function" then
            enable = v.enable(trigger);
          elseif type(v.enable) == "boolean" then
            enable = v.enable
          end
        end

        if (enable) then
          result[v.name] = {
            display = v.display,
            type = v.conditionType
          }
          if (result[v.name].type == "select" or result[v.name].type == "unit") then
            if (v.conditionValues) then
              result[v.name].values = Private[v.conditionValues] or WeakAuras[v.conditionValues];
            else
              if type(v.values) == "function" then
                result[v.name].values = v.values()
              else
                result[v.name].values = Private[v.values] or WeakAuras[v.values];
              end
            end
          end
          if (v.conditionPreamble) then
            result[v.name].preamble = v.conditionPreamble;
          end
          if (v.conditionTest) then
            result[v.name].test = v.conditionTest;
          end
          if (v.conditionEvents) then
            result[v.name].events = v.conditionEvents;
          end
          if (v.operator_types) then
            result[v.name].operator_types = v.operator_types;
          end
          -- for ProgressSource
          if v.noProgressSource then
            result[v.name].noProgressSource = true
          end
          if v.progressTotal then
            result[v.name].total = v.progressTotal
          end
          if v.progressModRate then
            result[v.name].modRate = v.progressModRate
          end
          if v.progressInverse then
            result[v.name].inverse = v.progressInverse
          end
          if v.progressPaused then
            result[v.name].paused = v.progressPaused
          end
          if v.progressRemaining then
            result[v.name].remaining = v.progressRemaining
          end
        end
      end
    end

    if prototype.countEvents then
      result.count = {
        display = L["Count"],
        type = "number"
      }
    end

    return result;
  elseif(trigger.type == "custom") then
    if (trigger.custom_type == "status" or trigger.custom_type == "event") then
      local result = {};

      local canHaveDurationFunc = trigger.custom_type == "status" or (trigger.custom_type == "event" and (trigger.custom_hide ~= "timed" or trigger.dynamicDuration));

      if (canHaveDurationFunc and trigger.customDuration and trigger.customDuration ~= "") then
        result.expirationTime = commonConditions.expirationTime;
        result.duration = commonConditions.duration;
        result.value = commonConditions.value;
        result.total = commonConditions.total;
      end

      if (trigger.custom_type == "event" and trigger.custom_hide ~= "custom" and trigger.dynamicDuration ~= true) then
        -- This is the static duration of a event/timed trigger
        result.expirationTime = commonConditions.expirationTime;
        result.duration = commonConditions.duration;
      end

      if (trigger.customStacks and trigger.customStacks ~= "") then
        result.stacks = commonConditions.stacks;
      end

      if (trigger.customName and trigger.customName ~= "") then
        result.name = commonConditions.name;
      end

      return result;
    elseif (trigger.custom_type == "stateupdate") then
      return Private.GetTsuConditionVariablesExpanded(data.id, triggernum)
    end
  end

  return nil;
end

function GenericTrigger.CreateFallbackState(data, triggernum, state)
  state.show = true;
  state.changed = true;
  local event = events[data.id][triggernum];

  Private.ActivateAuraEnvironment(data.id, "", state);
  local trigger = data.triggers[triggernum].trigger

  if event.GetNameAndIcon then
    local ok, name, icon = xpcall(event.GetNameAndIcon, Private.GetErrorHandlerUid(data.uid, L["GetNameAndIcon Function (fallback state)"]), trigger);
    state.name = ok and name or nil;
    state.icon = ok and icon or nil;
  else
    if (event.nameFunc) then
      local ok, name = xpcall(event.nameFunc, Private.GetErrorHandlerUid(data.uid, L["Name Function (fallback state)"]), trigger);
      state.name = ok and name or nil;
    end
    if (event.iconFunc) then
      local ok, icon = xpcall(event.iconFunc, Private.GetErrorHandlerUid(data.uid, L["Icon Function (fallback state)"]), trigger);
      state.icon = ok and icon or nil;
    end
  end

  if (event.textureFunc ) then
    local ok, texture = xpcall(event.textureFunc, Private.GetErrorHandlerUid(data.uid, L["Texture Function (fallback state)"]), trigger);
    state.texture = ok and texture or nil;
  end

  if (event.stacksFunc) then
    local ok, stacks = xpcall(event.stacksFunc, Private.GetErrorHandlerUid(data.uid, L["Stacks Function (fallback state)"]), trigger);
    state.stacks = ok and stacks or nil;
  end

  if (event.durationFunc) then
    local ok, arg1, arg2, arg3, inverse = xpcall(event.durationFunc, Private.GetErrorHandlerUid(data.uid, L["Duration Function (fallback state)"]), trigger);
    if (not ok) then
      state.progressType = "timed";
      state.duration = 0;
      state.expirationTime = math.huge;
      state.value = nil;
      state.total = nil;
      Private.ActivateAuraEnvironment(nil)
      return;
    end
    arg1 = type(arg1) == "number" and arg1 or 0;
    arg2 = type(arg2) == "number" and arg2 or 0;

    if(type(arg3) == "string") then
      state.durationFunc = event.durationFunc;
    elseif (type(arg3) == "function") then
      state.durationFunc = arg3;
    else
      state.durationFunc = nil;
    end

    if (arg3) then
      state.progressType = "static";
      state.duration = nil;
      state.expirationTime = nil;
      state.value = arg1;
      state.total = arg2;
      state.inverse = inverse;
    else
      state.progressType = "timed";
      state.duration = arg1;
      state.expirationTime = arg2;
      state.autoHide = nil;
      state.value = nil;
      state.total = nil;
      state.inverse = inverse;
    end
  else
    state.progressType = "timed";
    state.duration = 0;
    state.expirationTime = math.huge;
    state.value = nil;
    state.total = nil;
  end
  if (event.overlayFuncs) then
    RunOverlayFuncs(event, state, data.id);
  end
  Private.ActivateAuraEnvironment(nil);
end

function GenericTrigger.GetName(triggerType)
  return Private.event_categories[triggerType].name
end

function GenericTrigger.GetTriggerDescription(data, triggernum, namestable)
  local trigger = data.triggers[triggernum].trigger
  local prototype = GenericTrigger.GetPrototype(trigger)
  if prototype then
    tinsert(namestable, {L["Trigger:"], (prototype.name or L["Undefined"])});
    if(trigger.event == "Combat Log" and trigger.subeventPrefix and trigger.subeventSuffix) then
      tinsert(namestable, {L["Message type:"], (Private.subevent_prefix_types[trigger.subeventPrefix] or L["Undefined"]).." "..(Private.subevent_suffix_types[trigger.subeventSuffix] or L["Undefined"])});
    end
  else
    tinsert(namestable, {L["Trigger:"], L["Custom"]});
  end
end

do
  -- Based on Code by DejaCharacterStats. Ugly code to figure out the GCD
  local class = select(2, UnitClass("player"))
  if class == "DEMONHUNTER"
    or class == "HUNTER" or class == "SHAMAN"
    or class == "MAGE" or class == "PRIEST" or class == "WARLOCK"
    or class == "DEATHKNIGHT" or class == "PALADIN" or class == "WARRIOR"
    or class == "EVOKER"
  then
    function WeakAuras.CalculatedGcdDuration()
      local haste = GetHaste()
      return max(0.75, 1.5 * 100 / (100+haste))
    end
  elseif class == "DRUID" then
    function WeakAuras.CalculatedGcdDuration()
      local id = GetShapeshiftFormID()
      local haste = GetHaste()
      return id == 1 and 1 or max(0.75, 1.5 * 100 / (100+haste))
    end
  elseif class == "MONK" then
    function WeakAuras.CalculatedGcdDuration()
      local spec = GetSpecialization()
      local primaryStat = select(6, GetSpecializationInfo(spec))
      if primaryStat == LE_UNIT_STAT_AGILITY then
        return 1
      end
      local haste = GetHaste()
      return max(0.75, 1.5 * 100 / (100+haste))
    end
  elseif class == "ROGUE" then
    function WeakAuras.CalculatedGcdDuration()
      return 1
    end
  end
end

local findIdInLink = function(id, itemLink, startPos)
  local findID = ":" .. tostring(id:trim())
  return itemLink:find(findID .. ":", startPos, true) or itemLink:find(findID .. "|", startPos, true)
end

---@param ids string
---@return boolean isItemBonusId
WeakAuras.CheckForItemBonusId = function(ids)
  for id in tostring(ids):gmatch('([^,]+)') do
    for slot in pairs(Private.item_slot_types) do
      local itemLink = GetInventoryItemLink('player', slot)
      if itemLink then
        local startPos = itemLink:find(":", 1, true)
        startPos = itemLink:find(":", startPos + 1 , true)
        if findIdInLink(id, itemLink, startPos) then
          return true
        end
      end
    end
  end
  return false
end

---@param ids string
---@param specificSlot? number
---@return string|nil id
---@return string|nil itemID
---@return string|nil itemName
---@return number|nil icon
---@return number|nil slot
---@return number|nil itemSlot
WeakAuras.GetBonusIdInfo = function(ids, specificSlot)
  local checkSlots = specificSlot and {[specificSlot] = true} or Private.item_slot_types
  for id in tostring(ids):gmatch('([^,]+)') do
    for slot in pairs(checkSlots) do
      local itemLink = GetInventoryItemLink('player', slot)
      if itemLink and findIdInLink(id, itemLink, 1) then
        local itemID, _, _, _, icon = C_Item.GetItemInfoInstant(itemLink)
        local itemName = itemLink:match("%[(.*)%]")
        return id, itemID, itemName, icon, slot, Private.item_slot_types[slot]
      end
    end
  end
end

---@param itemName string
---@param specificSlot? number
---@return boolean|nil isItemEquipped
WeakAuras.CheckForItemEquipped = function(itemName, specificSlot)
  if not specificSlot then
    return C_Item.IsEquippedItem(itemName or '')
  else
    local item = Item:CreateFromEquipmentSlot(specificSlot)
    if item and not item:IsItemEmpty() then
      return itemName == item:GetItemName()
    end
  end
end

Private.ExecEnv.GetItemSubClassInfo = function(i)
  local subClassId = i % 256
  local classId = (i - subClassId) / 256
  return C_Item.GetItemSubClassInfo(classId, subClassId)
end

Private.ExecEnv.IsEquippedItemType = function(itemType, itemSlot)
  if itemSlot then
    local itemId = GetInventoryItemID("player", itemSlot)
    if itemId then
      local triggerSubClassId = itemType % 256
      local triggerClassId = (itemType - triggerSubClassId) / 256
      local _, _, _, _, _, classId, subclassId = C_Item.GetItemInfoInstant(itemId)
      return classId == triggerClassId and subclassId == triggerSubClassId
    end
  else
    return C_Item.IsEquippedItemType(Private.ExecEnv.GetItemSubClassInfo(itemType) or '')
  end
end

---@return integer critChance
WeakAuras.GetCritChance = function()
  -- Based on what the wow paper doll does
  local spellCrit = 0
  for i = 2, MAX_SPELL_SCHOOLS or 7 do -- WORKAROUND: MAX_SPELL_SCHOOLS is nil on classic_era
    spellCrit = max(spellCrit, GetSpellCritChance(i))
  end
  return max(spellCrit, GetRangedCritChance(), GetCritChance())
end

---@return number hitChance
WeakAuras.GetHitChance = function()
  local melee = (GetCombatRatingBonus(CR_HIT_MELEE) or 0) + (GetHitModifier() or 0)
  local ranged = (GetCombatRatingBonus(CR_HIT_RANGED) or 0) + (GetHitModifier() or 0)
  local spell = (GetCombatRatingBonus(CR_HIT_SPELL) or 0) + (GetSpellHitModifier() or 0)
  return max(melee, ranged, spell)
end

Private.ExecEnv.GetCurrencyInfo = function(id)
  if WeakAuras.IsRetail() then
    return C_CurrencyInfo.GetCurrencyInfo(id)
  elseif WeakAuras.IsCataClassic() then
    local name, currentAmount, texture, earnedThisWeek, weeklyMax, totalMax, isDiscovered, rarity = GetCurrencyInfo(id)
    local currencyInfo = {
      name = name,
      description = "",
      isHeader = false,
      isHeaderExpanded = false,
      isTypeUnused = false,
      isShowInBackpack = false,
      quantity = currentAmount,
      trackedQuantity = 0,
      iconFileID = texture,
      maxQuantity = totalMax,
      canEarnPerWeek = weeklyMax > 0,
      quantityEarnedThisWeek = earnedThisWeek,
      isTradeable = false,
      quality = rarity,
      maxWeeklyQuantity = weeklyMax,
      totalEarned = 0,
      discovered = isDiscovered,
      useTotalEarnedForMaxQty = false,
    }
    return currencyInfo
  end
end

---@type fun(trigger: triggerData)
---@return CurrencyInfo|nil
Private.GetCurrencyInfoForTrigger = function(trigger)
  if trigger.currencyId then
    local currencyId = tonumber(trigger.currencyId)
    if currencyId then
      return Private.ExecEnv.GetCurrencyInfo(currencyId)
    end
  end
end


local types = {}
tinsert(types, "custom")
for type in pairs(Private.category_event_prototype) do
  tinsert(types, type)
end

-- The Options/GenericTrigger.lua needs this table, since at the time
-- of registering the types the options code doesn't yet have access
-- to the Private table.

-- So for now make it simply a member of WeakAuras
WeakAuras.genericTriggerTypes = types

WeakAuras.RegisterTriggerSystem(types, GenericTrigger);
