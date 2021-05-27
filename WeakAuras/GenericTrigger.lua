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

CanHaveDuration(data, triggernum)
Returns whether the trigger can have a duration.

GetOverlayInfo(data, triggernum)
Returns a table containing the names of all overlays

CanHaveClones(data)
Returns whether the trigger can have clones.

CanHaveTooltip(data, triggernum)
Returns the type of tooltip to show for the trigger.

GetNameAndIcon(data, triggernum)
Returns the name and icon to show in the options.

GetAdditionalProperties(data, triggernum)
Returns the a tooltip for the additional properties.

GetTriggerConditions(data, triggernum)
Returns potential conditions that this trigger provides.
]]--
if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

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

local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local GenericTrigger = {};
local LCSA
if WeakAuras.IsClassic() then
  LCSA = LibStub("LibClassicSpellActionCount-1.0")
end

local event_prototypes = Private.event_prototypes;

local timer = WeakAuras.timer;

local events = {}
local loaded_events = {}
local loaded_unit_events = {};
local loaded_auras = {}; -- id to bool map
local timers = WeakAuras.timers;

-- Local functions
local LoadEvent, HandleEvent, HandleUnitEvent, TestForTriState, TestForToggle, TestForLongString, TestForMultiSelect
local ConstructTest, ConstructFunction


local nameplateExists = {}

function WeakAuras.UnitExistsFixed(unit, smart)
  if #unit > 9 and unit:sub(1, 9) == "nameplate" then
    return nameplateExists[unit]
  end
  if smart and IsInRaid() then
    if unit:sub(1, 5) == "party" or unit == "player" then
      return false
    end
  end
  return UnitExists(unit) or UnitGUID(unit)
end

function WeakAuras.split(input)
  input = input or "";
  local ret = {};
  local split, element = true;
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
  if(trigger[name.."_operator"] == "==") then
    test = ("(%s == %s)"):format(name, Private.QuotedString(needle))
  elseif(trigger[name.."_operator"] == "find('%s')") then
    test = "(" .. name .. " and " .. name .. string.format(":find(%s, 1, true)", Private.QuotedString(needle)) .. ")"
  elseif(trigger[name.."_operator"] == "match('%s')") then
    test = "(" .. name .. " and " .. name .. string.format(":match(%s)", Private.QuotedString(needle)) .. ")"
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
          test = test..name.."=="..(tonumber(value) or "[["..value.."]]").." or ";
        else
          test = test..arg.test:format(tonumber(value) or "[["..value.."]]").." or ";
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
      test = trigger[name].single and "("..name.."=="..(tonumber(value) or "[["..value.."]]")..")";
    else
      test = trigger[name].single and "("..arg.test:format(tonumber(value) or "[["..value.."]]")..")";
    end
  end
  return test;
end

function ConstructTest(trigger, arg)
  local test
  local preamble
  local name = arg.name;
  if(arg.hidden or arg.type == "tristate" or arg.type == "toggle" or (arg.type == "multiselect" and trigger["use_"..name] ~= nil) or ((trigger["use_"..name] or arg.required) and trigger[name])) then
    local number = tonumber(trigger[name]);
    if(arg.type == "tristate") then
      test = TestForTriState(trigger, arg);
    elseif(arg.type == "multiselect") then
      test = TestForMultiSelect(trigger, arg);
    elseif(arg.type == "toggle") then
      test = TestForToggle(trigger, arg);
    elseif (arg.type == "spell") then
      if arg.test then
        if arg.showExactOption then
          test = "("..arg.test:format(trigger[name], tostring(trigger["use_exact_" .. name]) or "false") ..")";
        else
          test = "("..arg.test:format(trigger[name])..")";
        end
      else
        test = "(".. name .." and "..name.."==" ..(number or "\""..(trigger[name] or "").."\"")..")";
      end
    elseif(arg.test) then
      test = "("..arg.test:format(tostring(trigger[name]) or "")..")";
    elseif(arg.type == "longstring" and trigger[name.."_operator"]) then
      test = TestForLongString(trigger, arg);
    elseif (arg.type == "string" or arg.type == "select" or arg.type == "item") then
      test = "(".. name .." and "..name.."==" ..(number or "\""..(trigger[name] or "").."\"")..")";
    else
      if(type(trigger[name]) == "table") then
        trigger[name] = "error";
      end
      -- number
      test = "(".. name .." and "..name..(trigger[name.."_operator"] or "==")..(number or "\""..(trigger[name] or "").."\"")..")";
    end
  end

  if arg.preamble then
    preamble = arg.preamble:format(trigger[name] or "")
  end

  if (test == "(true)") then
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
    input = {"state", "event"};
  else
    input = {"event"};
  end

  local required = {};
  local tests = {};
  local debug = {};
  local store = {};
  local init;
  local preambles = "\n"
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
        local test, preamble = ConstructTest(trigger, arg);
        if (test) then
          if(arg.required) then
            tinsert(required, test);
          else
            tinsert(tests, test);
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

  for _, v in ipairs(store) do
    ret = ret .. "    if (state." .. v .. " ~= " .. v .. ") then\n"
    ret = ret .. "      state." .. v .. " = " .. v .. "\n"
    ret = ret .. "      state.changed = true\n"
    ret = ret .. "    end\n"
  end
  ret = ret.."return true else return false end end";

  return ret;
end

function Private.EndEvent(id, triggernum, force, state)
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

local function RunOverlayFuncs(event, state)
  state.additionalProgress = state.additionalProgress or {};
  local changed = false;
  for i, overlayFunc in ipairs(event.overlayFuncs) do
    state.additionalProgress[i] = state.additionalProgress[i] or {};
    local additionalProgress = state.additionalProgress[i];
    local ok, a, b, c = xpcall(overlayFunc, geterrorhandler(), event.trigger, state);
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

local function callFunctionForActivateEvent(func, trigger, fallback, errorHandler)
  if not func then
    return fallback
  end
  local ok, value = xpcall(func, errorHandler, trigger)
  return ok and value or fallback
end

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
    local ok, arg1, arg2, arg3, inverse = xpcall(data.durationFunc, errorHandler, data.trigger);
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

  local name = callFunctionForActivateEvent(data.nameFunc, data.trigger, state.name, errorHandler)
  local icon = callFunctionForActivateEvent(data.iconFunc, data.trigger, state.icon, errorHandler)
  local texture = callFunctionForActivateEvent(data.textureFunc, data.trigger, state.texture, errorHandler)
  local stacks = callFunctionForActivateEvent(data.stacksFunc, data.trigger, state.stacks, errorHandler)

  if (state.name ~= name) then
    state.name = name;
    changed = true;
  end
  if (state.icon ~= icon) then
    state.icon = icon;
    changed = true;
  end
  if (state.texture ~= texture) then
    state.texture = texture;
    changed = true;
  end
  if (state.stacks ~= stacks) then
    state.stacks = stacks;
    changed = true;
  end

  if (data.overlayFuncs) then
    RunOverlayFuncs(data, state);
  else
    state.additionalProgress = nil;
  end

  state.changed = state.changed or changed;

  return state.changed;
end

local function ignoreErrorHandler()

end

local function RunTriggerFunc(allStates, data, id, triggernum, event, arg1, arg2, ...)
  local optionsEvent = event == "OPTIONS";
  local errorHandler = (optionsEvent and data.ignoreOptionsEventErrors) and ignoreErrorHandler or geterrorhandler()
  local updateTriggerState = false;

  local unitForUnitTrigger
  local cloneIdForUnitTrigger

  if(data.triggerFunc) then
    local untriggerCheck = false;
    if (data.statesParameter == "full") then
      local ok, returnValue = xpcall(data.triggerFunc, errorHandler, allStates, event, arg1, arg2, ...);
      if (ok and returnValue) then
        updateTriggerState = true;
      end
    elseif (data.statesParameter == "all") then
      local ok, returnValue = xpcall(data.triggerFunc, errorHandler, allStates, event, arg1, arg2, ...);
      if( (ok and returnValue) or optionsEvent) then
        for id, state in pairs(allStates) do
          if (state.changed) then
            if (Private.ActivateEvent(id, triggernum, data, state, errorHandler)) then
              updateTriggerState = true;
            end
          end
        end
      else
        untriggerCheck = true;
      end
    elseif (data.statesParameter == "unit") then
      if optionsEvent then
        if Private.multiUnitUnits[data.trigger.unit] then
          arg1 = next(Private.multiUnitUnits[data.trigger.unit])
        else
          arg1 = data.trigger.unit
        end
      end
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
        local ok, returnValue = xpcall(data.triggerFunc, errorHandler, state, event, unitForUnitTrigger, arg1, arg2, ...);
        if (ok and returnValue) or optionsEvent then
          if(Private.ActivateEvent(id, triggernum, data, state, errorHandler)) then
            updateTriggerState = true;
          end
        else
          untriggerCheck = true;
        end
      end
    elseif (data.statesParameter == "one") then
      allStates[""] = allStates[""] or {};
      local state = allStates[""];
      local ok, returnValue = xpcall(data.triggerFunc, errorHandler, state, event, arg1, arg2, ...);
      if (ok and returnValue) or optionsEvent then
        if(Private.ActivateEvent(id, triggernum, data, state, errorHandler)) then
          updateTriggerState = true;
        end
      else
        untriggerCheck = true;
      end
    else
      local ok, returnValue = xpcall(data.triggerFunc, errorHandler, event, arg1, arg2, ...);
      if (ok and returnValue) or optionsEvent then
        allStates[""] = allStates[""] or {};
        local state = allStates[""];
        if(Private.ActivateEvent(id, triggernum, data, state, errorHandler)) then
          updateTriggerState = true;
        end
      else
        untriggerCheck = true;
      end
    end
    if (untriggerCheck and not optionsEvent) then
      if (data.statesParameter == "all") then
        if data.untriggerFunc then
          local ok, returnValue = xpcall(data.untriggerFunc, errorHandler, allStates, event, arg1, arg2, ...);
          if ok and returnValue then
            for id, state in pairs(allStates) do
              if (state.changed) then
                if (Private.EndEvent(id, triggernum, nil, state)) then
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
              local ok, returnValue =  xpcall(data.untriggerFunc, errorHandler, state, event, unitForUnitTrigger, arg2, ...);
              if ok and returnValue then
                if (Private.EndEvent(id, triggernum, nil, state)) then
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
            if (Private.EndEvent(id, triggernum, nil, state)) then
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
            if(Private.EndEvent(id, triggernum, nil, state)) then
              updateTriggerState = true;
            end
          end
        end
      end
    end
  end
  return updateTriggerState;
end

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
          local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
          if (RunTriggerFunc(allStates, data, id, triggernum, event, unit, ...)) then
            updateTriggerState = true;
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

function WeakAuras.ScanEventsInternal(event_list, event, arg1, arg2, ... )
  for id, triggers in pairs(event_list) do
    Private.StartProfileAura(id);
    Private.ActivateAuraEnvironment(id);
    local updateTriggerState = false;
    for triggernum, data in pairs(triggers) do
      local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
      if (RunTriggerFunc(allStates, data, id, triggernum, event, arg1, arg2, ...)) then
        updateTriggerState = true;
      end
    end
    if (updateTriggerState) then
      Private.UpdatedTriggerState(id);
    end
    Private.StopProfileAura(id);
    Private.ActivateAuraEnvironment(nil);
  end
end

local function AddFakeTime(state)
  if state.progressType == "timed" then
    if state.expirationTime and state.expirationTime ~= math.huge and state.expirationTime > GetTime() then
      return
    end
    state.progressType = "timed"
    state.expirationTime = GetTime() + 7
    state.duration = 7
  end
end

function GenericTrigger.CreateFakeStates(id, triggernum)
  local data = WeakAuras.GetData(id)

  Private.ActivateAuraEnvironment(id);
  local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
  RunTriggerFunc(allStates, events[id][triggernum], id, triggernum, "OPTIONS")

  local canHaveDuration = events[id][triggernum].prototype and events[id][triggernum].prototype.canHaveDuration == "timed"

  local shown = 0
  for id, state in pairs(allStates) do
    if state.show then
      shown = shown + 1
    end
    state.autoHide = false
    if canHaveDuration and state.expirationTime == nil then
      state.progressType = "timed"
    end
    AddFakeTime(state)
  end

  if shown == 0 then
    local state = {}
    GenericTrigger.CreateFallbackState(data, triggernum, state)
    allStates[""] = state
    state.autoHide = false
    if canHaveDuration and state.expirationTime == nil then
      state.progressType = "timed"
    end
    AddFakeTime(state)
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
      HandleEvent(frame, "WA_DELAYED_PLAYER_ENTERING_WORLD");
      Private.CheckCooldownReady();
      Private.StopProfileSystem("generictrigger WA_DELAYED_PLAYER_ENTERING_WORLD");
      Private.PreShowModels()
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
    Private.UnregisterEveryFrameUpdate(id);
  end
end

local genericTriggerRegisteredEvents = {};
local genericTriggerRegisteredUnitEvents = {};
local frame = CreateFrame("FRAME");
frame.unitFrames = {};
WeakAuras.frames["WeakAuras Generic Trigger Frame"] = frame;
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

  Private.EveryFrameUpdateRename(oldid, newid)
end

local function MultiUnitLoop(Func, unit, ...)
  unit = string.lower(unit)
  if unit == "boss" or unit == "arena" then
    for i = 1, MAX_BOSS_FRAMES do
      Func(unit..i, ...)
    end
  elseif unit == "nameplate" then
    for i = 1, 40 do
      Func(unit..i, ...)
    end
  elseif unit == "group" then
    Func("player", ...)
    for i = 1, 4 do
      Func("party"..i, ...)
    end
    for i = 1, 40 do
      Func("raid"..i, ...)
    end
  elseif unit == "party" then
    Func("player", ...)
    for i = 1, 4 do
      Func("party"..i, ...)
    end
  elseif unit == "raid" then
    for i = 1, 40 do
      Func("raid"..i, ...)
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
    for unit, events in pairs(data.unit_events) do
      unit = string.lower(unit)
      for index, event in pairs(events) do
        MultiUnitLoop(
          function(unit)
            loaded_unit_events[unit] = loaded_unit_events[unit] or {};
            loaded_unit_events[unit][event] = loaded_unit_events[unit][event] or {};
            loaded_unit_events[unit][event][id] = loaded_unit_events[unit][event][id] or {}
            loaded_unit_events[unit][event][id][triggernum] = data;
          end, unit
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
          for unit, events in pairs(data.unit_events) do
            for index, event in pairs(events) do
              MultiUnitLoop(
                function (unit)
                  if not (genericTriggerRegisteredUnitEvents[unit] and genericTriggerRegisteredUnitEvents[unit][event]) then
                    unitEventsToRegister[unit] = unitEventsToRegister[unit] or {}
                    unitEventsToRegister[unit][event] = true
                  end
                end, unit
              )
            end
          end
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
        frame.unitFrames[unit] = CreateFrame("FRAME")
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

--- Adds a display, creating all internal data structures for all triggers.
-- @param data
-- @param region
function GenericTrigger.Add(data, region)
  local id = data.id;
  events[id] = nil;

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
        local trigger_subevents = {};
        local force_events = false;
        local durationFunc, overlayFuncs, nameFunc, iconFunc, textureFunc, stacksFunc, loadFunc;
        local tsuConditionVariables;
        local prototype = nil
        local automaticAutoHide
        local duration
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
            triggerFunc = WeakAuras.LoadFunction(triggerFuncStr, id);

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
                if (v.enable(trigger)) then
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
            end
          end
        else -- CUSTOM
          triggerFunc = WeakAuras.LoadFunction("return "..(trigger.custom or ""), id);
          if (trigger.custom_type == "stateupdate") then
            tsuConditionVariables = WeakAuras.LoadFunction("return function() return \n" .. (trigger.customVariables or "") .. "\n end");
            if not tsuConditionVariables then
              tsuConditionVariables = function() return end
            end
          end

          if(trigger.custom_type == "status" or trigger.custom_type == "event" and trigger.custom_hide == "custom") then
            untriggerFunc = WeakAuras.LoadFunction("return "..(untrigger.custom or ""), id);
            if (not untriggerFunc) then
              untriggerFunc = trueFunction;
            end
          end

          if(trigger.custom_type ~= "stateupdate" and trigger.customDuration and trigger.customDuration ~= "") then
            durationFunc = WeakAuras.LoadFunction("return "..trigger.customDuration, id);
          end
          if(trigger.custom_type ~= "stateupdate") then
            overlayFuncs = {};
            for i = 1, 7 do
              local property = "customOverlay" .. i;
              if (trigger[property] and trigger[property] ~= "") then
                overlayFuncs[i] = WeakAuras.LoadFunction("return ".. trigger[property], id);
              end
            end
          end
          if(trigger.custom_type ~= "stateupdate" and trigger.customName and trigger.customName ~= "") then
            nameFunc = WeakAuras.LoadFunction("return "..trigger.customName, id);
          end
          if(trigger.custom_type ~= "stateupdate" and trigger.customIcon and trigger.customIcon ~= "") then
            iconFunc = WeakAuras.LoadFunction("return "..trigger.customIcon, id);
          end
          if(trigger.custom_type ~= "stateupdate" and trigger.customTexture and trigger.customTexture ~= "") then
            textureFunc = WeakAuras.LoadFunction("return "..trigger.customTexture, id);
          end
          if(trigger.custom_type ~= "stateupdate" and trigger.customStacks and trigger.customStacks ~= "") then
            stacksFunc = WeakAuras.LoadFunction("return "..trigger.customStacks, id);
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
              local isUnitEvent = false
              for i in event:gmatch("[^:]+") do
                if not trueEvent then
                  trueEvent = string.upper(i)
                  isCLEU = trueEvent == "CLEU" or trueEvent == "COMBAT_LOG_EVENT_UNFILTERED"
                elseif isCLEU then
                  local subevent = string.upper(i)
                  if Private.IsCLEUSubevent(subevent) then
                    tinsert(trigger_subevents, subevent)
                    hasParam = true
                  end
                elseif trueEvent:match("^UNIT_") then
                  MultiUnitLoop(
                    function(unit)
                      trigger_unit_events[unit] = trigger_unit_events[unit] or {}
                      tinsert(trigger_unit_events[unit], trueEvent)
                      isUnitEvent = true
                    end, i
                  )
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
              else
                tinsert(trigger_events, event)
              end
              force_events = trigger.custom_type == "status" or trigger.custom_type == "stateupdate";
            end
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
          ignoreOptionsEventErrors = data.information.ignoreOptionsEventErrors
        };
      end
    end
  end


end

do
  local update_clients = {};
  local update_clients_num = 0;
  local update_frame = nil
  WeakAuras.frames["Custom Trigger Every Frame Updater"] = update_frame;
  local updating = false;

  function Private.RegisterEveryFrameUpdate(id)
    if not(update_clients[id]) then
      update_clients[id] = true;
      update_clients_num = update_clients_num + 1;
    end
    if not(update_frame) then
      update_frame = CreateFrame("FRAME");
    end
    if not(updating) then
      update_frame:SetScript("OnUpdate", function()
        if not(WeakAuras.IsPaused()) then
          WeakAuras.ScanEvents("FRAME_UPDATE");
        end
      end);
      updating = true;
    end
  end

  function Private.EveryFrameUpdateRename(oldid, newid)
    update_clients[newid] = update_clients[oldid];
    update_clients[oldid] = nil;
  end

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
  local ranged = (WeakAuras.IsClassic() or WeakAuras.IsBCC()) and GetInventorySlotInfo("RangedSlot")

  local swingTimerFrame;
  local lastSwingMain, lastSwingOff, lastSwingRange;
  local swingDurationMain, swingDurationOff, swingDurationRange, mainSwingOffset;
  local mainTimer, offTimer, rangeTimer;
  local selfGUID;
  local mainSpeed, offSpeed = UnitAttackSpeed("player")
  local casting = false
  local skipNextAttack, skipNextAttackCount

  function WeakAuras.GetSwingTimerInfo(hand)
    if(hand == "main") then
      local itemId = GetInventoryItemID("player", mh);
      local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemId or 0);
      if(lastSwingMain) then
        return swingDurationMain, lastSwingMain + swingDurationMain - mainSwingOffset, name, icon;
      elseif WeakAuras.IsRetail() and lastSwingRange then
        return swingDurationRange, lastSwingRange + swingDurationRange, name, icon;
      else
        return 0, math.huge, name, icon;
      end
    elseif(hand == "off") then
      local itemId = GetInventoryItemID("player", oh);
      local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemId or 0);
      if(lastSwingOff) then
        return swingDurationOff, lastSwingOff + swingDurationOff, name, icon;
      else
        return 0, math.huge, name, icon;
      end
    elseif(hand == "ranged") then
      local itemId = GetInventoryItemID("player", ranged);
      local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemId or 0);
      if (lastSwingRange) then
        return swingDurationRange, lastSwingRange + swingDurationRange, name, icon;
      else
        return 0, math.huge, name, icon;
      end
    end

    return 0, math.huge;
  end

  local function swingEnd(hand)
    if(hand == "main") then
      lastSwingMain, swingDurationMain, mainSwingOffset = nil, nil, nil;
    elseif(hand == "off") then
      lastSwingOff, swingDurationOff = nil, nil;
    elseif(hand == "ranged") then
      lastSwingRange, swingDurationRange = nil, nil;
    end
    WeakAuras.ScanEvents("SWING_TIMER_END");
  end

  local function swingTimerCLEUCheck(ts, event, _, sourceGUID, _, _, _, destGUID, _, _, _, ...)
    Private.StartProfileSystem("generictrigger swing");
    if(sourceGUID == selfGUID) then
      if event == "SPELL_EXTRA_ATTACKS" then
        skipNextAttack = ts
        skipNextAttackCount = select(4, ...)
      elseif(event == "SWING_DAMAGE" or event == "SWING_MISSED") then
        if skipNextAttack == ts and tonumber(skipNextAttackCount) then
          if skipNextAttackCount > 0 then
            skipNextAttackCount = skipNextAttackCount - 1
            return
          end
        end
        local isOffHand = select(event == "SWING_DAMAGE" and 10 or 2, ...);

        local event;
        local currentTime = GetTime();
        mainSpeed, offSpeed = UnitAttackSpeed("player");
        offSpeed = offSpeed or 0;
        if not(isOffHand) then
          lastSwingMain = currentTime;
          swingDurationMain = mainSpeed;
          mainSwingOffset = 0;
          event = "SWING_TIMER_START";
          timer:CancelTimer(mainTimer);
          mainTimer = timer:ScheduleTimerFixed(swingEnd, mainSpeed, "main");
        elseif(isOffHand) then
          lastSwingOff = currentTime;
          swingDurationOff = offSpeed;
          event = "SWING_TIMER_START";
          timer:CancelTimer(offTimer);
          offTimer = timer:ScheduleTimerFixed(swingEnd, offSpeed, "off");
        end
        WeakAuras.ScanEvents(event);
      end
    elseif (destGUID == selfGUID and (select(1, ...) == "PARRY" or select(4, ...) == "PARRY")) then
      if (lastSwingMain) then
        local timeLeft = lastSwingMain + swingDurationMain - GetTime();
        if (timeLeft > 0.6 * swingDurationMain) then
          timer:CancelTimer(mainTimer);
          mainTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft - 0.4 * swingDurationMain, "main");
          mainSwingOffset = 0.4 * swingDurationMain
          WeakAuras.ScanEvents("SWING_TIMER_CHANGE");
        elseif (timeLeft > 0.2 * swingDurationMain) then
          timer:CancelTimer(mainTimer);
          mainTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft - 0.2 * swingDurationMain, "main");
          mainSwingOffset = 0.2 * swingDurationMain
          WeakAuras.ScanEvents("SWING_TIMER_CHANGE");
        end
      end
    end
    Private.StopProfileSystem("generictrigger swing");
  end

  local function swingTimerCheck(event, unit, guid, spell)
    if unit ~= "player" then return end
    Private.StartProfileSystem("generictrigger swing");
    if event == "UNIT_ATTACK_SPEED" then
      local mainSpeedNew, offSpeedNew = UnitAttackSpeed("player")
      offSpeedNew = offSpeedNew or 0
      if lastSwingMain then
        if mainSpeedNew ~= mainSpeed then
          timer:CancelTimer(mainTimer)
          local multiplier = mainSpeedNew / mainSpeed
          local timeLeft = (lastSwingMain + swingDurationMain - GetTime()) * multiplier
          swingDurationMain = mainSpeedNew
          mainTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft, "main")
          WeakAuras.ScanEvents("SWING_TIMER_CHANGE")
        end
      end
      if lastSwingOff then
        if offSpeedNew ~= offSpeed then
          timer:CancelTimer(offTimer)
          local multiplier = offSpeedNew / mainSpeed
          local timeLeft = (lastSwingOff + swingDurationOff - GetTime()) * multiplier
          swingDurationOff = offSpeedNew
          offTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft, "off")
          WeakAuras.ScanEvents("SWING_TIMER_CHANGE")
        end
      end
      mainSpeed, offSpeed = mainSpeedNew, offSpeedNew
    elseif casting and (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED") then
      casting = false
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
      if Private.reset_swing_spells[spell] or casting then
        if casting then
          casting = false
        end
        local event;
        mainSpeed, offSpeed = UnitAttackSpeed("player");
        lastSwingMain = GetTime();
        swingDurationMain = mainSpeed;
        mainSwingOffset = 0;
        if (lastSwingMain) then
          timer:CancelTimer(mainTimer);
          event = "SWING_TIMER_CHANGE";
        else
          event = "SWING_TIMER_START";
        end
        mainTimer = timer:ScheduleTimerFixed(swingEnd, mainSpeed, "main");
        WeakAuras.ScanEvents(event);
      end
      if Private.reset_ranged_swing_spells[spell] then
        local event;
        local currentTime = GetTime();
        local speed = UnitRangedDamage("player");
        if(lastSwingRange) then
          if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
            timer:CancelTimer(rangeTimer, true)
          else
            timer:CancelTimer(mainTimer, true)
          end
          event = "SWING_TIMER_CHANGE";
        else
          event = "SWING_TIMER_START";
        end
        lastSwingRange = currentTime;
        swingDurationRange = speed;
        if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
          rangeTimer = timer:ScheduleTimerFixed(swingEnd, speed, "ranged");
        else
          mainTimer = timer:ScheduleTimerFixed(swingEnd, speed, "main");
        end
        WeakAuras.ScanEvents(event);
      end
    elseif event == "UNIT_SPELLCAST_START" then
      if not Private.noreset_swing_spells[spell] then
        -- pause swing timer
        casting = true
        lastSwingMain, swingDurationMain, mainSwingOffset = nil, nil, nil
        lastSwingOff, swingDurationOff = nil, nil
        WeakAuras.ScanEvents("SWING_TIMER_END")
      end
    end
    Private.StopProfileSystem("generictrigger swing");
  end

  function WeakAuras.InitSwingTimer()
    if not(swingTimerFrame) then
      swingTimerFrame = CreateFrame("frame");
      swingTimerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
      swingTimerFrame:RegisterEvent("PLAYER_ENTER_COMBAT");
      swingTimerFrame:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player");
      swingTimerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
      if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
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

  local spells = {};
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

  local shootStart
  local shootDuration

  local function GetRuneDuration()
    local runeDuration = -100;
    for id, _ in pairs(runes) do
      local startTime, duration = GetRuneCooldown(id);
      duration = duration or 0;
      runeDuration = duration > 0 and duration or runeDuration
    end
    return runeDuration
  end

  local function CheckGCD()
    local event;
    local startTime, duration
    if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
      startTime, duration = GetSpellCooldown(29515);
      shootStart, shootDuration = GetSpellCooldown(5019)
    else
      startTime, duration = GetSpellCooldown(61304);
    end
    if(duration and duration > 0) then
      if not(gcdStart) then
        event = "GCD_START";
      elseif(gcdStart ~= startTime or gcdDuration ~= duration) then
        event = "GCD_CHANGE";
      end
      gcdStart, gcdDuration = startTime, duration;
      local endCheck = startTime + duration + 0.1;
      if(gcdEndCheck ~= endCheck) then
        gcdEndCheck = endCheck;
        timer:ScheduleTimerFixed(CheckGCD, duration + 0.1);
      end
    else
      if(gcdStart) then
        event = "GCD_END"
      end
      gcdStart, gcdDuration = nil, nil;
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
      return self.expirationTime[id] - self.duration[id], self.duration[id], self.readyTime[id]
    end
    return 0, 0, nil
  end

  local function HandleSpell(self, id, startTime, duration)
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

    if duration > 0 then
      if (startTime == gcdStart and duration == gcdDuration)
          or ((WeakAuras.IsClassic() or WeakAuras.IsBCC()) and duration == shootDuration and startTime == shootStart)
      then
        -- GCD cooldown, this could mean that the spell reset!
        if self.expirationTime[id] and self.expirationTime[id] > endTime and self.expirationTime[id] ~= 0 then
          self.duration[id] = 0
          self.expirationTime[id] = 0
          self.readyTime[id] = time
          changed = true
          nowReady = true
        end
        RecheckHandles:Schedule(endTime, id)
        return changed, nowReady
      end
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
      self.readyTime[id] = time
    else
      self.readyTime[id] = nil
    end

    RecheckHandles:Schedule(endTime, id)
    return changed, nowReady
  end

  local function CreateSpellCDHandler()
    local cd = {
      duration = {},
      expirationTime = {},
      readyTime = {},
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

  local spellIds = {}

  function WeakAuras.InitCooldownReady()
    cdReadyFrame = CreateFrame("FRAME");
    WeakAuras.frames["Cooldown Trigger Handler"] = cdReadyFrame
    if WeakAuras.IsRetail() then
      cdReadyFrame:RegisterEvent("RUNE_POWER_UPDATE");
      cdReadyFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
      cdReadyFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
    else
      cdReadyFrame:RegisterEvent("CHARACTER_POINTS_CHANGED");
    end
    cdReadyFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    cdReadyFrame:RegisterEvent("SPELL_UPDATE_CHARGES");
    cdReadyFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
    cdReadyFrame:RegisterEvent("BAG_UPDATE_COOLDOWN");
    cdReadyFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    cdReadyFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    cdReadyFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
    cdReadyFrame:RegisterEvent("SPELLS_CHANGED");
    cdReadyFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    cdReadyFrame:SetScript("OnEvent", function(self, event, ...)
      Private.StartProfileSystem("generictrigger cd tracking");
      if(event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES"
        or event == "RUNE_POWER_UPDATE" or event == "ACTIONBAR_UPDATE_COOLDOWN"
        or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_PVP_TALENT_UPDATE"
        or event == "CHARACTER_POINTS_CHANGED") then
        Private.CheckCooldownReady();
      elseif(event == "SPELLS_CHANGED") then
        Private.CheckSpellKnown();
        Private.CheckCooldownReady();
      elseif(event == "UNIT_SPELLCAST_SENT") then
        local unit, guid, castGUID, name = ...;
        if(unit == "player") then
          name = GetSpellInfo(name);
          if(gcdSpellName ~= name) then
            local icon = GetSpellTexture(name);
            gcdSpellName = name;
            gcdSpellIcon = icon;
            if not WeakAuras.IsPaused() then
              WeakAuras.ScanEvents("GCD_UPDATE")
            end
          end
        end
      elseif(event == "UNIT_INVENTORY_CHANGED" or event == "BAG_UPDATE_COOLDOWN" or event == "PLAYER_EQUIPMENT_CHANGED") then
        Private.CheckItemSlotCooldowns();
      end
      Private.StopProfileSystem("generictrigger cd tracking");
    end);
  end

  function WeakAuras.GetRuneCooldown(id)
    if(runes[id] and runeCdExps[id] and runeCdDurs[id]) then
      return runeCdExps[id] - runeCdDurs[id], runeCdDurs[id];
    else
      return 0, 0;
    end
  end

  function WeakAuras.GetSpellCooldown(id, ignoreRuneCD, showgcd, ignoreSpellKnown, track)
    if (not spellKnown[id] and not ignoreSpellKnown) then
      return;
    end
    local startTime, duration, gcdCooldown, readyTime
    if track == "charges" then
      startTime, duration, readyTime = spellCdsCharges:FetchSpellCooldown(id)
    elseif track == "cooldown" then
      if ignoreRuneCD then
        startTime, duration, readyTime = spellCdsOnlyCooldownRune:FetchSpellCooldown(id)
      else
        startTime, duration, readyTime = spellCdsOnlyCooldown:FetchSpellCooldown(id)
      end
    elseif (ignoreRuneCD) then
      startTime, duration, readyTime = spellCdsRune:FetchSpellCooldown(id)
    else
      startTime, duration, readyTime = spellCds:FetchSpellCooldown(id)
    end

    if (showgcd) then
      if ((gcdStart or 0) + (gcdDuration or 0) > startTime + duration) then
        startTime = gcdStart;
        duration = gcdDuration;
        gcdCooldown = true;
      end
    end

    return startTime, duration, gcdCooldown, readyTime
  end

  function WeakAuras.GetSpellCharges(id, ignoreSpellKnown)
    if (not spellKnown[id] and not ignoreSpellKnown) then
      return;
    end
    return spellCharges[id], spellChargesMax[id], spellCounts[id], spellChargeGainTime[id], spellChargeLostTime[id]
  end

  function WeakAuras.GetItemCooldown(id, showgcd)
    local startTime, duration, enabled, gcdCooldown;
    if(items[id] and itemCdExps[id] and itemCdDurs[id]) then
      startTime, duration, enabled = itemCdExps[id] - itemCdDurs[id], itemCdDurs[id], itemCdEnabled[id];
    else
      startTime, duration, enabled = 0, 0, itemCdEnabled[id] or 1;
    end
    if (showgcd) then
      if ((gcdStart or 0) + (gcdDuration or 0) > startTime + duration) then
        startTime = gcdStart;
        duration = gcdDuration;
        gcdCooldown = true;
      end
    end
    return startTime, duration, enabled, gcdCooldown;
  end

  function WeakAuras.GetGCDInfo()
    if(gcdStart) then
      return gcdDuration, gcdStart + gcdDuration, gcdSpellName or "Invalid", gcdSpellIcon or "Interface\\Icons\\INV_Misc_QuestionMark";
    else
      return 0, math.huge, gcdSpellName or "Invalid", gcdSpellIcon or "Interface\\Icons\\INV_Misc_QuestionMark";
    end
  end

  function WeakAuras.gcdDuration()
    return gcdDuration or 0;
  end

  function WeakAuras.GcdSpellName()
    return gcdSpellName;
  end

  function WeakAuras.GetItemSlotCooldown(id, showgcd)
    local startTime, duration, enabled, gcdCooldown;
    if(itemSlots[id] and itemSlotsCdExps[id] and itemSlotsCdDurs[id]) then
      startTime, duration, enabled = itemSlotsCdExps[id] - itemSlotsCdDurs[id], itemSlotsCdDurs[id], itemSlotsEnable[id];
    else
      startTime, duration, enabled = 0, 0, itemSlotsEnable[id];
    end

    if (showgcd) then
      if ((gcdStart or 0) + (gcdDuration or 0) > startTime + duration) then
        startTime = gcdStart;
        duration = gcdDuration;
        gcdCooldown = true;
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

  function WeakAuras.GetSpellCooldownUnified(id, runeDuration)
    local startTimeCooldown, durationCooldown, enabled = GetSpellCooldown(id)
    local charges, maxCharges, startTimeCharges, durationCharges = GetSpellCharges(id);

    startTimeCooldown = startTimeCooldown or 0;
    durationCooldown = durationCooldown or 0;

    startTimeCharges = startTimeCharges or 0;
    durationCharges = durationCharges or 0;

    -- WORKAROUND Sometimes the API returns very high bogus numbers causing client freezes, discard them here. CurseForge issue #1008
    if (durationCooldown > 604800) then
      durationCooldown = 0;
      startTimeCooldown = 0;
    end

    if (startTimeCooldown > GetTime() + 2^31 / 1000) then
      -- WORKAROUND WoW wraps around negative values with 2^32/1000
      -- So if we find a cooldown in the far future, then undo the wrapping
      startTimeCooldown = startTimeCooldown - 2^32 / 1000
    end

    -- Default to GetSpellCharges
    local unifiedCooldownBecauseRune, cooldownBecauseRune = false, false;
    if (enabled == 0) then
      startTimeCooldown, durationCooldown = 0, 0
    end

    local onNonGCDCD = durationCooldown and startTimeCooldown and durationCooldown > 0 and (durationCooldown ~= gcdDuration or startTimeCooldown ~= gcdStart);
    if (onNonGCDCD) then
      cooldownBecauseRune = runeDuration and durationCooldown and abs(durationCooldown - runeDuration) < 0.001;
      unifiedCooldownBecauseRune = cooldownBecauseRune
    end

    local startTime, duration = startTimeCooldown, durationCooldown
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
        startTime, duration = startTimeCharges, durationCharges
        unifiedCooldownBecauseRune = false
      end
    end

    local count
    if WeakAuras.IsClassic() then
      count = LCSA:GetSpellReagentCount(id)
    else
      count = GetSpellCount(id)
    end

    return charges, maxCharges, startTime, duration, unifiedCooldownBecauseRune,
           startTimeCooldown, durationCooldown, cooldownBecauseRune, startTimeCharges, durationCharges,
           count;
  end

  function Private.CheckSpellKnown()
    for id, _ in pairs(spells) do
      local known = WeakAuras.IsSpellKnownIncludingPet(id);
      if (known ~= spellKnown[id]) then
        spellKnown[id] = known
        if not WeakAuras.IsPaused() then
          WeakAuras.ScanEvents("SPELL_COOLDOWN_CHANGED", id)
        end
      end
    end
  end

  function Private.CheckSpellCooldown(id, runeDuration)
    local charges, maxCharges, startTime, duration, unifiedCooldownBecauseRune,
          startTimeCooldown, durationCooldown, cooldownBecauseRune, startTimeCharges, durationCharges,
          spellCount
          = WeakAuras.GetSpellCooldownUnified(id, runeDuration);

    local time = GetTime();
    local remaining = startTime + duration - time;

    local chargesChanged = spellCharges[id] ~= charges or spellCounts[id] ~= spellCount;
    local chargesDifference = (charges or spellCount or 0) - (spellCharges[id] or spellCount or 0)
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
    local spellId = select(7, GetSpellInfo(id))
    if spellIds[id] ~= spellId then
      spellIds[id] = spellId
      changed = true
      chargesChanged = true
    end

    changed = spellCds:HandleSpell(id, startTime, duration) or changed
    if not unifiedCooldownBecauseRune then
      changed = spellCdsRune:HandleSpell(id, startTime, duration) or changed
    end
    local cdChanged, nowReady = spellCdsOnlyCooldown:HandleSpell(id, startTimeCooldown, durationCooldown)
    changed = cdChanged or changed
    if not cooldownBecauseRune then
      changed = spellCdsOnlyCooldownRune:HandleSpell(id, startTimeCooldown, durationCooldown) or changed
    end
    local chargeChanged, chargeNowReady = spellCdsCharges:HandleSpell(id, startTimeCharges, durationCharges)
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

  function Private.CheckSpellCooldows(runeDuration)
    for id, _ in pairs(spells) do
      Private.CheckSpellCooldown(id, runeDuration)
    end
  end

  function Private.CheckItemCooldowns()
    for id, _ in pairs(items) do
      local startTime, duration, enabled = GetItemCooldown(id);
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

  function Private.CheckCooldownReady()
    CheckGCD();
    local runeDuration = Private.CheckRuneCooldown();
    Private.CheckSpellCooldows(runeDuration);
    Private.CheckItemCooldowns();
    Private.CheckItemSlotCooldowns();
  end

  function WeakAuras.WatchGCD()
    if not(cdReadyFrame) then
      WeakAuras.InitCooldownReady();
    end
  end

  function WeakAuras.WatchRuneCooldown(id)
    if not(cdReadyFrame) then
      WeakAuras.InitCooldownReady();
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

  function WeakAuras.WatchSpellCooldown(id, ignoreRunes)
    if not(cdReadyFrame) then
      WeakAuras.InitCooldownReady();
    end

    if not id or id == 0 then return end

    if ignoreRunes and WeakAuras.IsRetail() then
      for i = 1, 6 do
        WeakAuras.WatchRuneCooldown(i);
      end
    end

    if (spells[id]) then
      return;
    end
    spells[id] = true;
    spellIds[id] = select(7, GetSpellInfo(id))
    spellKnown[id] = WeakAuras.IsSpellKnownIncludingPet(id);

    local charges, maxCharges, startTime, duration, unifiedCooldownBecauseRune,
          startTimeCooldown, durationCooldown, cooldownBecauseRune, startTimeCharges, durationCharges,
          spellCount
          = WeakAuras.GetSpellCooldownUnified(id, GetRuneDuration());

    spellCharges[id] = charges;
    spellChargesMax[id] = maxCharges;
    spellCounts[id] = spellCount
    spellCds:HandleSpell(id, startTime, duration)
    if not unifiedCooldownBecauseRune then
      spellCdsRune:HandleSpell(id, startTime, duration)
    end
    spellCdsOnlyCooldown:HandleSpell(id, startTimeCooldown, durationCooldown)
    if not cooldownBecauseRune then
      spellCdsOnlyCooldownRune:HandleSpell(id, startTimeCooldown, durationCooldown)
    end
    spellCdsCharges:HandleSpell(id, startTimeCharges, durationCharges)
  end

  function WeakAuras.WatchItemCooldown(id)
    if not(cdReadyFrame) then
      WeakAuras.InitCooldownReady();
    end

    if not id or id == 0 then return end

    if not(items[id]) then
      items[id] = true;
      local startTime, duration, enabled = GetItemCooldown(id);
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

  function WeakAuras.WatchItemSlotCooldown(id)
    if not(cdReadyFrame) then
      WeakAuras.InitCooldownReady();
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
    spellActivationFrame = CreateFrame("FRAME");
    WeakAuras.frames["Spell Activation"] = spellActivationFrame;
    spellActivationFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW");
    spellActivationFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE");
    spellActivationFrame:SetScript("OnEvent", function(self, event, spell)
      Private.StartProfileSystem("generictrigger");
      local spellName = GetSpellInfo(spell)
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

  function WeakAuras.WatchSpellActivation(id)
    if (not id) then
      return;
    end
    if (not spellActivationFrame) then
      InitSpellActivation();
    end
    spellActivationSpells[id] = true;
  end

  function WeakAuras.SpellActivationActive(id)
    return spellActivationSpellsCurrent[id];
  end
end

local watchUnitChange

-- Nameplates only distinguish between friends and everyone else
function WeakAuras.GetPlayerReaction(unit)
  local r = UnitReaction("player", unit)
  if r then
    return r < 5 and "hostile" or "friendly"
  end
end

function WeakAuras.WatchUnitChange(unit)
  unit = string.lower(unit)
  if not watchUnitChange then
    watchUnitChange = CreateFrame("FRAME");
    watchUnitChange.unitChangeGUIDS = {}
    watchUnitChange.unitRoles = {}
    watchUnitChange.unitRaidRole = {}
    watchUnitChange.inRaid = IsInRaid()
    watchUnitChange.nameplateFaction = {}

    WeakAuras.frames["Unit Change Frame"] = watchUnitChange;
    watchUnitChange:RegisterEvent("PLAYER_TARGET_CHANGED")
    if not WeakAuras.IsClassic() then
      watchUnitChange:RegisterEvent("PLAYER_FOCUS_CHANGED");
    else
      watchUnitChange:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    end
    watchUnitChange:RegisterEvent("UNIT_TARGET");
    watchUnitChange:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT");
    watchUnitChange:RegisterEvent("GROUP_ROSTER_UPDATE");
    watchUnitChange:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    watchUnitChange:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    watchUnitChange:RegisterEvent("UNIT_FACTION")
    watchUnitChange:RegisterEvent("PLAYER_ENTERING_WORLD")

    watchUnitChange:SetScript("OnEvent", function(self, event, unit)
      Private.StartProfileSystem("generictrigger unit change");
      if event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        local newGuid = WeakAuras.UnitExistsFixed(unit) and UnitGUID(unit) or ""
        if newGuid ~= watchUnitChange.unitChangeGUIDS[unit] then
          WeakAuras.ScanEvents("UNIT_CHANGED_" .. unit, unit)
          watchUnitChange.unitChangeGUIDS[unit] = newGuid
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
      else
        local inRaid = IsInRaid()
        local inRaidChanged = inRaid ~= watchUnitChange.inRaid

        for unit, guid in pairs(watchUnitChange.unitChangeGUIDS) do
          local newGuid = WeakAuras.UnitExistsFixed(unit) and UnitGUID(unit) or ""
          if guid ~= newGuid or event == "PLAYER_ENTERING_WORLD" then
            WeakAuras.ScanEvents("UNIT_CHANGED_" .. unit, unit)
            watchUnitChange.unitChangeGUIDS[unit] = newGuid
          elseif Private.multiUnitUnits.group[unit] then
            -- If in raid changed we send a UNIT_CHANGED for the group units
            if inRaidChanged then
              WeakAuras.ScanEvents("UNIT_CHANGED_" .. unit, unit)
            else
              if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
                local newRaidRole = WeakAuras.UnitRaidRole(unit)
                if watchUnitChange.unitRaidRole[unit] ~= newRaidRole then
                  watchUnitChange.unitRaidRole[unit] = newRaidRole
                  WeakAuras.ScanEvents("UNIT_ROLE_CHANGED_" .. unit, unit)
                end
              else
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

-- DBM
do
  local registeredDBMEvents = {}
  local bars = {}
  local nextExpire -- time of next expiring timer
  local recheckTimer -- handle of timer

  local function dbmRecheckTimers()
    local now = GetTime()
    nextExpire = nil
    for id, bar in pairs(bars) do
      if not bar.paused then
        if bar.expirationTime < now then
          bars[id] = nil
          WeakAuras.ScanEvents("DBM_TimerStop", id)
        elseif nextExpire == nil then
          nextExpire = bar.expirationTime
        elseif bar.expirationTime < nextExpire then
          nextExpire = bar.expirationTime
        end
      end
    end

    if nextExpire then
      recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, nextExpire - now)
    end
  end

  local function dbmEventCallback(event, ...)
    if event == "DBM_TimerStart" then
      local id, msg, duration, icon, timerType, spellId, dbmType = ...
      local now = GetTime()
      local expirationTime = now + duration
      bars[id] = bars[id] or {}
      local bar = bars[id]
      bar.message = msg
      bar.expirationTime = expirationTime
      bar.duration = duration
      bar.icon = icon
      bar.timerType = timerType
      bar.spellId = tostring(spellId)
      bar.count = msg:match("(%d+)") or "0"
      bar.dbmType = dbmType

      local barOptions = DBT.Options or DBM.Bars.options
      local r, g, b = 0, 0, 0
      if dbmType == 1 then
        r, g, b = barOptions.StartColorAR, barOptions.StartColorAG, barOptions.StartColorAB
      elseif dbmType == 2 then
        r, g, b = barOptions.StartColorAER, barOptions.StartColorAEG, barOptions.StartColorAEB
      elseif dbmType == 3 then
        r, g, b = barOptions.StartColorDR, barOptions.StartColorDG, barOptions.StartColorDB
      elseif dbmType == 4 then
        r, g, b = barOptions.StartColorIR, barOptions.StartColorIG, barOptions.StartColorIB
      elseif dbmType == 5 then
        r, g, b = barOptions.StartColorRR, barOptions.StartColorRG, barOptions.StartColorRB
      elseif dbmType == 6 then
        r, g, b = barOptions.StartColorPR, barOptions.StartColorPG, barOptions.StartColorPB
      elseif dbmType == 7 then
        r, g, b = barOptions.StartColorUIR, barOptions.StartColorUIG, barOptions.StartColorUIB
      else
        r, g, b = barOptions.StartColorR, barOptions.StartColorG, barOptions.StartColorB
      end
      bar.dbmColor = {r, g, b}

      WeakAuras.ScanEvents("DBM_TimerStart", id)
      if nextExpire == nil then
        recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, expirationTime - now)
        nextExpire = expirationTime
      elseif expirationTime < nextExpire then
        timer:CancelTimer(recheckTimer)
        recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, expirationTime - now)
        nextExpire = expirationTime
      end
    elseif event == "DBM_TimerStop" then
      local id = ...
      bars[id] = nil
      WeakAuras.ScanEvents("DBM_TimerStop", id)
    elseif event == "kill" or event == "wipe" then -- Wipe or kill, removing all timers
      local id = ...
      wipe(bars)
      WeakAuras.ScanEvents("DBM_TimerStopAll", id)
    elseif event == "DBM_TimerPause" then
      local id = ...
      local bar = bars[id]
      if bar then
        bar.paused = true
        bar.remaining = bar.expirationTime - GetTime()
        WeakAuras.ScanEvents("DBM_TimerPause", id)
        if recheckTimer then
          timer:CancelTimer(recheckTimer)
        end
        dbmRecheckTimers()
      end
    elseif event == "DBM_TimerResume" then
      local id = ...
      local bar = bars[id]
      if bar then
        bar.paused = nil
        bar.expirationTime = GetTime() + (bar.remaining or 0)
        bar.remaining = nil
        WeakAuras.ScanEvents("DBM_TimerResume", id)
        if nextExpire == nil then
          recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, bar.expirationTime - GetTime())
        elseif bar.expirationTime < nextExpire then
          timer:CancelTimer(recheckTimer)
          recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, bar.expirationTime - GetTime())
          nextExpire = bar.expirationTime
        end
      end
    elseif event == "DBM_TimerUpdate" then
      local id, elapsed, duration = ...
      local now = GetTime()
      local expirationTime = now + duration - elapsed
      local bar = bars[id]
      if bar then
        bar.duration = duration
        bar.expirationTime = expirationTime
        if expirationTime < nextExpire then
          timer:CancelTimer(recheckTimer)
          recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, duration - elapsed)
          nextExpire = expirationTime
        end
      end
      WeakAuras.ScanEvents("DBM_TimerUpdate", id)
    else -- DBM_Announce
      WeakAuras.ScanEvents(event, ...)
    end
  end

  function WeakAuras.DBMTimerMatches(timerId, id, message, operator, spellId, dbmType, count)
    if not bars[timerId] then
      return false
    end

    local v = bars[timerId]
    if id and id ~= "" and id ~= timerId then
      return false
    end
    if spellId and spellId ~= "" and spellId ~= v.spellId then
      return false
    end
    if message and message ~= "" and operator then
      if operator == "==" then
        if v.message ~= message then
          return false
        end
      elseif operator == "find('%s')" then
        if v.message == nil or not v.message:find(message, 1, true) then
          return false
        end
      elseif operator == "match('%s')" then
        if v.message == nil or not v.message:match(message) then
          return false
        end
      end
    end
    if count and count ~= "" and count ~= v.count then
      return false
    end
    if dbmType and dbmType ~= v.dbmType then
      return false
    end
    return true
  end

  function WeakAuras.GetDBMTimerById(id)
    return bars[id]
  end

  function WeakAuras.GetAllDBMTimers()
    return bars
  end

  function WeakAuras.GetDBMTimer(id, message, operator, spellId, extendTimer, dbmType, count)
    local bestMatch
    for timerId, bar in pairs(bars) do
      if WeakAuras.DBMTimerMatches(timerId, id, message, operator, spellId, dbmType, count)
      and (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime)
      and bar.expirationTime + extendTimer > GetTime()
      then
        bestMatch = bar
      end
    end
    return bestMatch
  end

  function WeakAuras.CopyBarToState(bar, states, id, extendTimer)
    extendTimer = extendTimer or 0
    if extendTimer + bar.duration < 0 then return end
    states[id] = states[id] or {}
    local state = states[id]
    state.show = true
    state.changed = true
    state.icon = bar.icon
    state.message = bar.message
    state.name = bar.message
    state.expirationTime = bar.expirationTime + extendTimer
    state.progressType = 'timed'
    state.duration = bar.duration + extendTimer
    state.timerType = bar.timerType
    state.spellId = bar.spellId
    state.count = bar.count
    state.dbmType = bar.dbmType
    state.dbmColor = bar.dbmColor
    state.extend = extendTimer
    if extendTimer ~= 0 then
      state.autoHide = true
    end
    state.paused = bar.paused
    state.remaining = bar.remaining
  end

  function WeakAuras.RegisterDBMCallback(event)
    if registeredDBMEvents[event] then
      return
    end
    if DBM then
      DBM:RegisterCallback(event, dbmEventCallback)
      registeredDBMEvents[event] = true
    end
  end

  function WeakAuras.GetDBMTimers()
    return bars
  end

  local scheduled_scans = {}

  local function doDbmScan(fireTime)
    scheduled_scans[fireTime] = nil
    WeakAuras.ScanEvents("DBM_TimerUpdate")
  end
  function WeakAuras.ScheduleDbmCheck(fireTime)
    if not scheduled_scans[fireTime] then
      scheduled_scans[fireTime] = timer:ScheduleTimerFixed(doDbmScan, fireTime - GetTime() + 0.1, fireTime)
    end
  end
end

-- BigWigs
do
  local registeredBigWigsEvents = {}
  local bars = {}
  local nextExpire -- time of next expiring timer
  local recheckTimer -- handle of timer

  local function recheckTimers()
    local now = GetTime()
    nextExpire = nil
    for id, bar in pairs(bars) do
      if not bar.paused then
        if bar.expirationTime < now then
          bars[id] = nil
          WeakAuras.ScanEvents("BigWigs_StopBar", id)
        elseif nextExpire == nil then
          nextExpire = bar.expirationTime
        elseif bar.expirationTime < nextExpire then
          nextExpire = bar.expirationTime
        end
      end
    end

    if nextExpire then
      recheckTimer = timer:ScheduleTimerFixed(recheckTimers, nextExpire - now)
    end
  end

  local function bigWigsEventCallback(event, ...)
    if event == "BigWigs_Message" then
      WeakAuras.ScanEvents("BigWigs_Message", ...)
    elseif event == "BigWigs_StartBar" then
      local addon, spellId, text, duration, icon = ...
      local now = GetTime()
      local expirationTime = now + duration

      local newBar
      bars[text] = bars[text] or {}
      local bar = bars[text]
      bar.addon = addon
      bar.spellId = tostring(spellId)
      bar.text = text
      bar.duration = duration
      bar.expirationTime = expirationTime
      bar.icon = icon
      local BWColorModule = BigWigs:GetPlugin("Colors")
      bar.bwBarColor = BWColorModule:GetColorTable("barColor", addon, spellId)
      bar.bwTextColor = BWColorModule:GetColorTable("barText", addon, spellId)
      bar.bwBackgroundColor = BWColorModule:GetColorTable("barBackground", addon, spellId)
      bar.count = text:match("(%d+)") or "0"
      bar.cast = not(text:match("^[^<]") and true)

      WeakAuras.ScanEvents("BigWigs_StartBar", text)
      if nextExpire == nil then
        recheckTimer = timer:ScheduleTimerFixed(recheckTimers, expirationTime - now)
        nextExpire = expirationTime
      elseif expirationTime < nextExpire then
        timer:CancelTimer(recheckTimer)
        recheckTimer = timer:ScheduleTimerFixed(recheckTimers, expirationTime - now)
        nextExpire = expirationTime
      end
    elseif event == "BigWigs_StopBar" then
      local addon, text = ...
      if bars[text] then
        bars[text] = nil
        WeakAuras.ScanEvents("BigWigs_StopBar", text)
      end
    elseif event == "BigWigs_PauseBar" then
      local addon, text = ...
      local bar = bars[text]
      if bar then
        bar.paused = true
        bar.remaining = bar.expirationTime - GetTime()
        WeakAuras.ScanEvents("BigWigs_PauseBar", text)
        if recheckTimer then
          timer:CancelTimer(recheckTimer)
        end
        recheckTimers()
      end
    elseif event == "BigWigs_ResumeBar" then
      local addon, text = ...
      local bar = bars[text]
      if bar then
        bar.paused = nil
        bar.expirationTime = GetTime() + (bar.remaining or 0)
        bar.remaining = nil
        WeakAuras.ScanEvents("BigWigs_ResumeBar", text)
        if nextExpire == nil then
          recheckTimer = timer:ScheduleTimerFixed(recheckTimers, bar.expirationTime - GetTime())
        elseif bar.expirationTime < nextExpire then
          timer:CancelTimer(recheckTimer)
          recheckTimer = timer:ScheduleTimerFixed(recheckTimers, bar.expirationTime - GetTime())
          nextExpire = bar.expirationTime
        end
      end
    elseif event == "BigWigs_StopBars"
    or event == "BigWigs_OnBossDisable"
    or event == "BigWigs_OnPluginDisable"
    then
      local addon = ...
      for id, bar in pairs(bars) do
        if bar.addon == addon then
          bars[id] = nil
          WeakAuras.ScanEvents("BigWigs_StopBar", id)
        end
      end
    end
  end

  function WeakAuras.RegisterBigWigsCallback(event)
    if registeredBigWigsEvents[event] then
      return
    end
    if BigWigsLoader then
      BigWigsLoader.RegisterMessage(WeakAuras, event, bigWigsEventCallback)
      registeredBigWigsEvents[event] = true
    end
  end

  function WeakAuras.RegisterBigWigsTimer()
    WeakAuras.RegisterBigWigsCallback("BigWigs_StartBar")
    WeakAuras.RegisterBigWigsCallback("BigWigs_StopBar")
    WeakAuras.RegisterBigWigsCallback("BigWigs_StopBars")
    WeakAuras.RegisterBigWigsCallback("BigWigs_OnBossDisable")
    WeakAuras.RegisterBigWigsCallback("BigWigs_PauseBar")
    WeakAuras.RegisterBigWigsCallback("BigWigs_ResumeBar")
  end

  function WeakAuras.CopyBigWigsTimerToState(bar, states, id, extendTimer)
    extendTimer = extendTimer or 0
    if extendTimer + bar.duration < 0 then return end
    states[id] = states[id] or {}
    local state = states[id]
    state.show = true
    state.changed = true
    state.addon = bar.addon
    state.spellId = bar.spellId
    state.text = bar.text
    state.name = bar.text
    state.duration = bar.duration + extendTimer
    state.expirationTime = bar.expirationTime + extendTimer
    state.bwBarColor = bar.bwBarColor
    state.bwTextColor = bar.bwTextColor
    state.bwBackgroundColor = bar.bwBackgroundColor
    state.count = bar.count
    state.cast = bar.cast
    state.progressType = "timed"
    state.icon = bar.icon
    state.extend = extendTimer
    if extendTimer ~= 0 then
      state.autoHide = true
    end
    state.paused = bar.paused
    state.remaining = bar.remaining
  end

  function WeakAuras.BigWigsTimerMatches(id, message, operator, spellId, count, cast)
    if not bars[id] then
      return false
    end

    local v = bars[id]
    local bestMatch
    if spellId and spellId ~= "" and spellId ~= v.spellId then
      return false
    end
    if message and message ~= "" and operator then
      if operator == "==" then
        if v.text ~= message then
          return false
        end
      elseif operator == "find('%s')" then
        if v.text == nil or not v.text:find(message, 1, true) then
          return false
        end
      elseif operator == "match('%s')" then
        if v.text == nil or not v.text:match(message) then
          return false
        end
      end
    end
    if count and count ~= "" and count ~= v.count then
      return false
    end
    if cast ~= nil and v.cast ~= cast then
      return false
    end
    return true
  end

  function WeakAuras.GetAllBigWigsTimers()
    return bars
  end

  function WeakAuras.GetBigWigsTimerById(id)
    return bars[id]
  end

  function WeakAuras.GetBigWigsTimer(text, operator, spellId, extendTimer, count, cast)
    local bestMatch
    for id, bar in pairs(bars) do
      if WeakAuras.BigWigsTimerMatches(id, text, operator, spellId, count, cast)
      and (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime)
      and bar.expirationTime + extendTimer > GetTime()
      then
        bestMatch = bar
      end
    end
    return bestMatch
  end

  local scheduled_scans = {}

  local function doBigWigsScan(fireTime)
    scheduled_scans[fireTime] = nil
    WeakAuras.ScanEvents("BigWigs_Timer_Update")
  end

  function WeakAuras.ScheduleBigWigsCheck(fireTime)
    if not scheduled_scans[fireTime] then
      scheduled_scans[fireTime] = timer:ScheduleTimerFixed(doBigWigsScan, fireTime - GetTime() + 0.1, fireTime)
    end
  end
end

function WeakAuras.CheckTotemName(totemName, triggerTotemName, triggerTotemPattern, triggerTotemOperator)
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

function WeakAuras.GetSpellCost(powerTypeToCheck)
  local spellID = select(9, WeakAuras.UnitCastingInfo("player"))
  if spellID then
    local costTable = GetSpellPowerCost(spellID);
    for _, costInfo in pairs(costTable) do
      if costInfo.type == powerTypeToCheck then
        return costInfo.cost;
      end
    end
  end
end

-- Weapon Enchants
do
  local mh = GetInventorySlotInfo("MainHandSlot")
  local oh = GetInventorySlotInfo("SecondaryHandSlot")

  local mh_name, mh_shortenedName, mh_exp, mh_dur, mh_charges, mh_EnchantID;
  local mh_icon = GetInventoryItemTexture("player", mh) or "Interface\\Icons\\INV_Misc_QuestionMark"

  local oh_name, oh_shortenedName, oh_exp, oh_dur, oh_charges, oh_EnchantID;
  local oh_icon = GetInventoryItemTexture("player", oh) or "Interface\\Icons\\INV_Misc_QuestionMark"

  local tenchFrame = nil
  WeakAuras.frames["Temporary Enchant Handler"] = tenchFrame;
  local tenchTip;

  function WeakAuras.TenchInit()
    if not(tenchFrame) then
      tenchFrame = CreateFrame("Frame");
      tenchFrame:RegisterEvent("UNIT_INVENTORY_CHANGED");
      if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
        tenchFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
      end

      tenchTip = WeakAuras.GetHiddenTooltip();

      local function getTenchName(id)
        tenchTip:SetInventoryItem("player", id);
        local lines = { tenchTip:GetRegions() };
        for i,v in ipairs(lines) do
          if(v:GetObjectType() == "FontString") then
            local text = v:GetText();
            if(text) then
              local _, _, name, shortenedName = text:find("^((.-) ?+?[VI%d]*) %(%d+ .+%)$");
              if(name) then
                return name, shortenedName;
              end
            end
          end
        end

        return "Unknown", "Unknown";
      end

      local function tenchUpdate()
        Private.StartProfileSystem("generictrigger");
        local _, mh_rem, oh_rem
        _, mh_rem, mh_charges, mh_EnchantID, _, oh_rem, oh_charges, oh_EnchantID = GetWeaponEnchantInfo();
        local time = GetTime();
        local mh_exp_new = mh_rem and (time + (mh_rem / 1000));
        local oh_exp_new = oh_rem and (time + (oh_rem / 1000));
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
        WeakAuras.ScanEvents("TENCH_UPDATE");
        Private.StopProfileSystem("generictrigger");
      end

      tenchFrame:SetScript("OnEvent", function(self, event, arg1)
        Private.StartProfileSystem("generictrigger");
        if (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") or event == "UNIT_INVENTORY_CHANGED" then
          timer:ScheduleTimer(tenchUpdate, 0.1);
        end
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
end

-- Pets
do
  local petFrame = nil
  WeakAuras.frames["Pet Use Handler"] = petFrame;
  function WeakAuras.WatchForPetDeath()
    if not(petFrame) then
      petFrame = CreateFrame("frame");
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
  local castLatencyFrame = nil
  WeakAuras.frames["Cast Latency Handler"] = castLatencyFrame
  function WeakAuras.WatchForCastLatency()
    if not castLatencyFrame then
      castLatencyFrame = CreateFrame("Frame")
      castLatencyFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
      castLatencyFrame:SetScript("OnEvent", function(event)
        Private.StartProfileSystem("generictrigger")
        WeakAuras.ScanEvents("CAST_LATENCY_UPDATE", "player")
        Private.StopProfileSystem("generictrigger")
      end)
    end
  end
end

-- Player Moving
do
  local playerMovingFrame = nil
  local moving;

  local function PlayerMoveUpdate(self, event)
    Private.StartProfileSystem("generictrigger");
    -- channeling e.g. Mind Flay results in lots of PLAYER_STARTED_MOVING, PLAYER_STOPPED_MOVING
    -- for each frame
    -- So check after 0.01 s if IsPlayerMoving() actually returns something different.
    timer:ScheduleTimer(function()
      Private.StartProfileSystem("generictrigger");
      if (moving ~= IsPlayerMoving() or moving == nil) then
        moving = IsPlayerMoving();
        WeakAuras.ScanEvents("PLAYER_MOVING_UPDATE")
      end
      Private.StopProfileSystem("generictrigger");
    end, 0.01);
    Private.StopProfileSystem("generictrigger");
  end

  local function PlayerMoveSpeedUpdate()
    Private.StartProfileSystem("generictrigger");
    local speed = GetUnitSpeed("player")
    if speed ~= playerMovingFrame.speed then
      playerMovingFrame.speed = speed
      WeakAuras.ScanEvents("PLAYER_MOVE_SPEED_UPDATE")
    end
    Private.StopProfileSystem("generictrigger");
  end

  function WeakAuras.WatchForPlayerMoving()
    if not(playerMovingFrame) then
      playerMovingFrame = CreateFrame("frame");
      WeakAuras.frames["Player Moving Frame"] =  playerMovingFrame;
    end
    playerMovingFrame:RegisterEvent("PLAYER_STARTED_MOVING");
    playerMovingFrame:RegisterEvent("PLAYER_STOPPED_MOVING");
    playerMovingFrame:SetScript("OnEvent", PlayerMoveUpdate)
  end

  function WeakAuras.WatchPlayerMoveSpeed()
    if not(playerMovingFrame) then
      playerMovingFrame = CreateFrame("frame");
      WeakAuras.frames["Player Moving Frame"] =  playerMovingFrame;
    end
    playerMovingFrame.speed = GetUnitSpeed("player")
    playerMovingFrame:SetScript("OnUpdate", PlayerMoveSpeedUpdate)
  end
end

-- Item Count
local itemCountWatchFrame;
function WeakAuras.RegisterItemCountWatch()
  if not(itemCountWatchFrame) then
    itemCountWatchFrame = CreateFrame("frame");
    itemCountWatchFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
    itemCountWatchFrame:SetScript("OnEvent", function()
      Private.StartProfileSystem("generictrigger");
      timer:ScheduleTimer(WeakAuras.ScanEvents, 0.2, "ITEM_COUNT_UPDATE");
      timer:ScheduleTimer(WeakAuras.ScanEvents, 0.5, "ITEM_COUNT_UPDATE");
      Private.StopProfileSystem("generictrigger");
    end);
  end
end

do
  local scheduled_scans = {};

  local function doScan(fireTime, event)
    scheduled_scans[event][fireTime] = nil;
    WeakAuras.ScanEvents(event);
  end
  function WeakAuras.ScheduleScan(fireTime, event)
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
  function WeakAuras.ScheduleCastCheck(fireTime, unit)
    scheduled_scans[unit] = scheduled_scans[unit] or {}
    if not(scheduled_scans[unit][fireTime]) then
      scheduled_scans[unit][fireTime] = timer:ScheduleTimerFixed(doCastScan, fireTime - GetTime() + 0.1, fireTime, unit);
    end
  end
end

local uniqueId = 0;
function WeakAuras.GetUniqueCloneId()
  uniqueId = (uniqueId + 1) % 1000000;
  return uniqueId;
end

function GenericTrigger.CanHaveDuration(data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  if (Private.category_event_prototype[trigger.type]) then
    if trigger.event and Private.event_prototypes[trigger.event] then
      if Private.event_prototypes[trigger.event].durationFunc then
        if(type(Private.event_prototypes[trigger.event].init) == "function") then
          Private.event_prototypes[trigger.event].init(trigger);
        end
        local current, maximum, custom = Private.event_prototypes[trigger.event].durationFunc(trigger);
        current = type(current) ~= "number" and current or 0
        maximum = type(maximum) ~= "number" and maximum or 0
        if(custom) then
          return {current = current, maximum = maximum};
        else
          return "timed";
        end
      elseif Private.event_prototypes[trigger.event].canHaveDuration then
        return Private.event_prototypes[trigger.event].canHaveDuration
      elseif Private.event_prototypes[trigger.event].timedrequired then
        return "timed"
      end
    end
  elseif (trigger.type == "custom") then
    if trigger.custom_type == "event" and trigger.custom_hide == "timed" and trigger.duration then
      return "timed";
    elseif (trigger.customDuration and trigger.customDuration ~= "") then
      return "timed";
    elseif (trigger.custom_type == "stateupdate") then
      return "timed";
    end
  end
  return false
end

--- Returns a table containing the names of all overlays
-- @param data
-- @param triggernum
function GenericTrigger.GetOverlayInfo(data, triggernum)
  local result;

  local trigger = data.triggers[triggernum].trigger

  if (trigger.type ~= "custom" and trigger.event and Private.event_prototypes[trigger.event] and Private.event_prototypes[trigger.event].overlayFuncs) then
    result = {};
    local dest = 1;
    for i, v in ipairs(Private.event_prototypes[trigger.event].overlayFuncs) do
      if (v.enable(trigger)) then
        result[dest] = v.name;
        dest = dest + 1;
      end
    end
  end

  if (trigger.type == "custom") then
    if (trigger.custom_type == "stateupdate") then
      local count = 0;
      local variables = events[data.id][triggernum].tsuConditionVariables();
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

function GenericTrigger.CanHaveClones(data)
  return false;
end

function GenericTrigger.GetNameAndIcon(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local icon, name
  if (Private.category_event_prototype[trigger.type]) then
    if(trigger.event and Private.event_prototypes[trigger.event]) then
      if(Private.event_prototypes[trigger.event].iconFunc) then
        icon = Private.event_prototypes[trigger.event].iconFunc(trigger);
      end
      if(Private.event_prototypes[trigger.event].nameFunc) then
        name = Private.event_prototypes[trigger.event].nameFunc(trigger);
      end
    end
  end

  return name, icon
end

---Returns the type of tooltip to show for the trigger.
-- @param data
-- @param triggernum
-- @return string
function GenericTrigger.CanHaveTooltip(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  if (Private.category_event_prototype[trigger.type]) then
    if (trigger.event and Private.event_prototypes[trigger.event]) then
      if(Private.event_prototypes[trigger.event].hasSpellID) then
        return "spell";
      elseif(Private.event_prototypes[trigger.event].hasItemID) then
        return "item";
      end
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

  if (Private.category_event_prototype[trigger.type]) then
    if (trigger.event and Private.event_prototypes[trigger.event]) then
      if(Private.event_prototypes[trigger.event].hasSpellID) then
        GameTooltip:SetSpellByID(trigger.spellName);
        return true
      elseif(Private.event_prototypes[trigger.event].hasItemID) then
        GameTooltip:SetHyperlink("item:"..trigger.itemName..":0:0:0:0:0:0:0")
        return true
      end
    end
  end
  return false
end

function GenericTrigger.GetAdditionalProperties(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local ret = "";
  if (Private.category_event_prototype[trigger.type]) then
    if (trigger.event and Private.event_prototypes[trigger.event]) then
      local found = false;
      local additional = ""
      for _, v in pairs(Private.event_prototypes[trigger.event].args) do
        local enable = true
        if(type(v.enable) == "function") then
          enable = v.enable(trigger)
        elseif type(v.enable) == "boolean" then
          enable = v.enable
        end
        if (enable and v.store and v.name and v.display) then
          found = true;
          additional = additional .. "|cFFFF0000%".. triggernum .. "." .. v.name .. "|r - " .. v.display .. "\n";
        end
      end

      if (found) then
        ret = ret .. additional;
      end
    end
  end

  return ret;
end

local commonConditions = {
  expirationTime = {
    display = L["Remaining Duration"],
    type = "timer",
  },
  duration = {
    display = L["Total Duration"],
    type = "number",
  },
  value = {
    display = L["Progress Value"],
    type = "number",
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

function GenericTrigger.GetTriggerConditions(data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  if (Private.category_event_prototype[trigger.type]) then
    if (trigger.event and Private.event_prototypes[trigger.event]) then
      local result = {};

      local canHaveDuration = GenericTrigger.CanHaveDuration(data, triggernum);
      local timedDuration = canHaveDuration;
      local valueDuration = canHaveDuration;
      if (canHaveDuration == "timed") then
        valueDuration = false;
      elseif (type(canHaveDuration) == "table") then
        timedDuration = false;
      end

      if (timedDuration) then
        result.expirationTime = commonConditions.expirationTime;
        result.duration = commonConditions.duration;
      end

      if (valueDuration) then
        result.value = commonConditions.value;
        result.total = commonConditions.total;
      end

      if (Private.event_prototypes[trigger.event].stacksFunc) then
        result.stacks = commonConditions.stacks;
      end

      if (Private.event_prototypes[trigger.event].nameFunc) then
        result.name = commonConditions.name;
      end

      for _, v in pairs(Private.event_prototypes[trigger.event].args) do
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
          end
        end
      end

      return result;
    end
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
      if (events[data.id][triggernum] and events[data.id][triggernum].tsuConditionVariables) then
        Private.ActivateAuraEnvironment(data.id, nil, nil, nil, true)
        local result = events[data.id][triggernum].tsuConditionVariables()
        Private.ActivateAuraEnvironment(nil)
        if (type(result)) ~= "table" then
          return nil;
        end
        Private.ExpandCustomVariables(result)
        for k, v in pairs(result) do
          if (type(v) ~= "table") then
            result[k] = nil;
          elseif (v.display == nil or type(v.display) ~= "string") then
            if (type(k) == "string") then
              v.display = k;
            else
              result[k] = nil;
            end
          end
        end

        return result;
      end
    end
  end

  return nil;
end

function GenericTrigger.CreateFallbackState(data, triggernum, state)
  state.show = true;
  state.changed = true;
  local event = events[data.id][triggernum];

  Private.ActivateAuraEnvironment(data.id, "", state);
  local firstTrigger = data.triggers[1].trigger
  if (event.nameFunc) then
    local ok, name = xpcall(event.nameFunc, geterrorhandler(), firstTrigger);
    state.name = ok and name or nil;
  end
  if (event.iconFunc) then
    local ok, icon = xpcall(event.iconFunc, geterrorhandler(), firstTrigger);
    state.icon = ok and icon or nil;
  end

  if (event.textureFunc ) then
    local ok, texture = xpcall(event.textureFunc, geterrorhandler(), firstTrigger);
    state.texture = ok and texture or nil;
  end

  if (event.stacksFunc) then
    local ok, stacks = xpcall(event.stacksFunc, geterrorhandler(), firstTrigger);
    state.stacks = ok and stacks or nil;
  end

  if (event.durationFunc) then
    local ok, arg1, arg2, arg3, inverse = xpcall(event.durationFunc, geterrorhandler(), firstTrigger);
    if (not ok) then
      state.progressType = "timed";
      state.duration = 0;
      state.expirationTime = math.huge;
      state.value = nil;
      state.total = nil;
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
    RunOverlayFuncs(event, state);
  end
  Private.ActivateAuraEnvironment(nil);
end

function GenericTrigger.GetName(triggerType)
  return Private.event_categories[triggerType].name
end

function GenericTrigger.GetTriggerDescription(data, triggernum, namestable)
  local trigger = data.triggers[triggernum].trigger
  if (Private.category_event_prototype[trigger.type]) then
    tinsert(namestable, {L["Trigger:"], (Private.event_prototypes[trigger.event].name or L["Undefined"])});
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

WeakAuras.CheckForItemBonusId = function(ids)
  for id in tostring(ids):gmatch('([^,]+)') do
    id = ":" .. tostring(id:trim()) .. ":"
    for slot in pairs(Private.item_slot_types) do
      local itemLink = GetInventoryItemLink('player', slot)
      if itemLink and itemLink:find(id, 1, true) then
        return true
      end
    end
  end
  return false
end


WeakAuras.GetBonusIdInfo = function(ids, specificSlot)
  local checkSlots = specificSlot and {[specificSlot] = true} or Private.item_slot_types
  for id in tostring(ids):gmatch('([^,]+)') do
    local findID = ":" .. tostring(id:trim()) .. ":"
    for slot in pairs(checkSlots) do
      local itemLink = GetInventoryItemLink('player', slot)
      if itemLink and itemLink:find(findID, 1, true) then
        local itemID, _, _, _, icon = GetItemInfoInstant(itemLink)
        local itemName = itemLink:match("%[(.*)%]")
        return id, itemID, itemName, icon, slot, Private.item_slot_types[slot]
      end
    end
  end
end

WeakAuras.GetItemSubClassInfo = function(i)
  local subClassId = i % 256
  local classId = (i - subClassId) / 256
  return GetItemSubClassInfo(classId, subClassId)
end

if WeakAuras.IsClassic() or WeakAuras.IsBCC() then
  WeakAuras.GetCritChance = function()
    return max(GetRangedCritChance(), GetCritChance())
  end
else
  WeakAuras.GetCritChance = function()
    -- Based on what the wow paper doll does
    local spellCrit = GetSpellCritChance(2)
    for i = 3, MAX_SPELL_SCHOOLS do
      spellCrit = min(spellCrit, GetSpellCritChance(i))
    end
    return max(spellCrit, GetRangedCritChance(), GetCritChance())
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
