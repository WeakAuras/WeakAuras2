--[[ GenericTrigger.lua
This file contains the generic trigger system. That is every trigger except the aura triggers.

It registers the GenericTrigger table for the trigger types "status", "event" and "custom" and has the following API:

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

ScanAll
Resets the trigger state for all triggers.

Modernize(data)
Modernizes all generic triggers in data.

#####################################################
# Helper functions mainly for the WeakAuras Options #
#####################################################

CanHaveDuration(data, triggernum)
Returns whether the trigger can have a duration.

GetOverlayInfo(data, triggernum)
Returns a table containing the names of all overlays

CanHaveAuto(data, triggernum)
Returns whether the icon can be automatically selected.

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

-- luacheck: globals GTFO DBM BigWigsLoader CombatLogGetCurrentEventInfo

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

local event_prototypes = WeakAuras.event_prototypes;

local timer = WeakAuras.timer;
local debug = WeakAuras.debug;

local events = WeakAuras.events;
local loaded_events = WeakAuras.loaded_events;
local loaded_auras = {}; -- id to bool map
local timers = WeakAuras.timers;
local specificBosses = WeakAuras.specificBosses;

-- Local functions
local LoadEvent, HandleEvent, TestForTriState, TestForToggle, TestForLongString, TestForMultiSelect
local ConstructTest, ConstructFunction

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
  if(trigger[name.."_operator"] == "==") then
    test = "("..name.."==\""..trigger[name].."\")";
  else
    test = "("..name.." and "..name..":"..trigger[name.."_operator"]:format(trigger[name])..")";
  end
  return test;
end

function TestForMultiSelect(trigger, arg)
  local name = arg.name;
  local test;
  if(trigger["use_"..name] == false) then -- multi selection
    test = "(";
    local any = false;
    if trigger[name].multi then
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
      test = test:sub(0, -5);
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
  local test;
  local name = arg.name;
  if(arg.hidden or arg.type == "tristate" or arg.type == "toggle" or (arg.type == "multiselect" and trigger["use_"..name] ~= nil) or ((trigger["use_"..name] or arg.required) and trigger[name])) then
    local number = tonumber(trigger[name]);
    if(arg.type == "tristate") then
      test = TestForTriState(trigger, arg);
    elseif(arg.type == "multiselect") then
      test = TestForMultiSelect(trigger, arg);
    elseif(arg.type == "toggle") then
      test = TestForToggle(trigger, arg);
    elseif(arg.test) then
      test = "("..arg.test:format(trigger[name])..")";
    elseif(arg.type == "longstring" and trigger[name.."_operator"]) then
      test = TestForLongString(trigger, arg);
    elseif (arg.type == "string" or type == "select" or type == "spell" or type == "item") then
      test = "(".. name .." and "..name.."==" ..(number or "\""..(trigger[name] or "").."\"")..")";
    else
      if(type(trigger[name]) == "table") then
        trigger[name] = "error";
      end
      -- number
      test = "(".. name .." and "..name..(trigger[name.."_operator"] or "==")..(number or "\""..(trigger[name] or "").."\"")..")";
    end
  end

  if (test == "(true)") then
    return nil;
  end

  return test;
end

function ConstructFunction(prototype, trigger, inverse)
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
  if(prototype.init) then
    init = prototype.init(trigger);
  else
    init = "";
  end
  for index, arg in pairs(prototype.args) do
    local enable = arg.type ~= "description";
    if(type(arg.enable) == "function") then
      enable = arg.enable(trigger);
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
        local test = ConstructTest(trigger, arg);
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
      end
    end
  end
  local ret = "return function("..tconcat(input, ", ")..")\n";

  ret = ret..(init or "");

  ret = ret..(#debug > 0 and tconcat(debug, "\n") or "");

  ret = ret.."if(";
  ret = ret..((#required > 0) and tconcat(required, " and ").." and " or "");
  if(inverse) then
    ret = ret.."not ("..(#tests > 0 and tconcat(tests, " and ") or "true")..")";
  else
    ret = ret..(#tests > 0 and tconcat(tests, " and ") or "true");
  end
  ret = ret..") then\n";
  if(#debug > 0) then
    ret = ret.."print('ret: true');\n";
  end
  if (not inverse) then
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
  end
  ret = ret.."return true else return false end end";

  return ret;
end

function WeakAuras.EndEvent(id, triggernum, force, state)
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
      additionalProgress.direction = nil;
      additionalProgress.width = nil;
      additionalProgress.offset = nil;
    end

  end
  state.changed = changed or state.changed;
end


function WeakAuras.ActivateEvent(id, triggernum, data, state)
  local changed = state.changed or false;
  if (state.show ~= true) then
    state.show = true;
    changed = true;
  end
  if (data.duration) then
    local expirationTime = GetTime() + data.duration;
    if (state.expirationTime ~= expirationTime) then
      state.resort = state.expirationTime ~= expirationTime;
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
    local arg1, arg2, arg3, inverse = data.durationFunc(data.trigger);
    arg1 = type(arg1) == "number" and arg1 or 0;
    arg2 = type(arg2) == "number" and arg2 or 0;

    if(type(arg3) == "string") then
      if (state.durationFunc ~= data.durationFunc) then
        state.durationFunc = data.durationFunc;
        changed = true;
      end
    elseif (type(arg3) == "function") then
      if (state.durationFunc ~= arg3) then
        state.durationFunc = arg3;
        changed = true;
      end
    else
      if (state.durationFunc ~= nil) then
        state.durationFunc = nil;
        changed = true;
      end
    end

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
        state.resort = state.expirationTime ~= nil;
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
        state.resort = state.expirationTime ~= arg2;
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
  local name = data.nameFunc and data.nameFunc(data.trigger) or state.name;
  local icon = data.iconFunc and data.iconFunc(data.trigger) or state.icon;
  local texture = data.textureFunc and data.textureFunc(data.trigger) or state.texture;
  local stacks = data.stacksFunc and data.stacksFunc(data.trigger) or state.stacks;
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

local function RunTriggerFunc(allStates, data, id, triggernum, event, arg1, arg2, ...)
  local updateTriggerState = false;
  local optionsEvent = event == "OPTIONS";
  if(data.triggerFunc) then
    local untriggerCheck = false;
    if (data.statesParameter == "full") then
      local ok, returnValue = xpcall(data.triggerFunc, geterrorhandler(), allStates, event, arg1, arg2, ...);
      if (ok and returnValue) then
        updateTriggerState = true;
      end
    elseif (data.statesParameter == "all") then
      local ok, returnValue = xpcall(data.triggerFunc, geterrorhandler(), allStates, event, arg1, arg2, ...);
      if( (ok and returnValue) or optionsEvent) then
        for id, state in pairs(allStates) do
          if (state.changed) then
            if (WeakAuras.ActivateEvent(id, triggernum, data, state)) then
              updateTriggerState = true;
            end
          end
        end
      else
        untriggerCheck = true;
      end
    elseif (data.statesParameter == "one") then
      allStates[""] = allStates[""] or {};
      local state = allStates[""];
      local ok, returnValue = xpcall(data.triggerFunc, geterrorhandler(), state, event, arg1, arg2, ...);
      if( (ok and returnValue) or optionsEvent) then
        if(WeakAuras.ActivateEvent(id, triggernum, data, state)) then
          updateTriggerState = true;
        end
      else
        untriggerCheck = true;
      end
    else
      local ok, returnValue = xpcall(data.triggerFunc, geterrorhandler(), event, arg1, arg2, ...);
      if( (ok and returnValue) or optionsEvent) then
        allStates[""] = allStates[""] or {};
        local state = allStates[""];
        if(WeakAuras.ActivateEvent(id, triggernum, data, state)) then
          updateTriggerState = true;
        end
      else
        untriggerCheck = true;
      end
    end
    if (untriggerCheck and not optionsEvent) then
      if (data.statesParameter == "all") then
        if(data.untriggerFunc) then
          local ok, returnValue = xpcall(data.untriggerFunc, geterrorhandler(), allStates, event, arg1, arg2, ...);
          if(ok and returnValue) then
            for id, state in pairs(allStates) do
              if (state.changed) then
                if (WeakAuras.EndEvent(id, triggernum, nil, state)) then
                  updateTriggerState = true;
                end
              end
            end
          end
        end
      elseif (data.statesParameter == "one") then
        allStates[""] = allStates[""] or {};
        local state = allStates[""];
        if(data.untriggerFunc) then
          local ok, returnValue = xpcall(data.untriggerFunc, geterrorhandler(), state, event, arg1, arg2, ...);
          if (ok and returnValue) then
            if (WeakAuras.EndEvent(id, triggernum, nil, state)) then
              updateTriggerState = true;
            end
          end
        end
      else
        if(data.untriggerFunc) then
          local ok, returnValue = xpcall(data.untriggerFunc, geterrorhandler(), event, arg1, arg2, ...);
          if(ok and returnValue) then
            allStates[""] = allStates[""] or {};
            local state = allStates[""];
            if(WeakAuras.EndEvent(id, triggernum, nil, state)) then
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
  WeakAuras.StartProfileSystem("generictrigger " .. orgEvent )
  local event_list = loaded_events[event];
  if (not event_list) then
    WeakAuras.StopProfileSystem("generictrigger " .. orgEvent )
    return
  end
  if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
    local arg1, arg2 = CombatLogGetCurrentEventInfo();

    event_list = event_list[arg2];
    if (not event_list) then
      WeakAuras.StopProfileSystem("generictrigger " .. orgEvent )
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
  WeakAuras.StopProfileSystem("generictrigger " .. orgEvent )
end

function WeakAuras.ScanEventsInternal(event_list, event, arg1, arg2, ... )
  local orgEvent = event;
  for id, triggers in pairs(event_list) do
    WeakAuras.StartProfileAura(id);
    WeakAuras.ActivateAuraEnvironment(id);
    local updateTriggerState = false;
    for triggernum, data in pairs(triggers) do
      local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
      if (RunTriggerFunc(allStates, data, id, triggernum, event, arg1, arg2, ...)) then
        updateTriggerState = true;
      end
    end
    if (updateTriggerState) then
      WeakAuras.UpdatedTriggerState(id);
    end
    WeakAuras.StopProfileAura(id);
    WeakAuras.ActivateAuraEnvironment(nil);
  end
end

function GenericTrigger.ScanWithFakeEvent(id)
  local updateTriggerState = false;
  WeakAuras.ActivateAuraEnvironment(id);
  for triggernum, event in pairs(events[id] or {}) do
    local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
    if (event.force_events) then
      if (type(event.force_events) == "string") then
        updateTriggerState = RunTriggerFunc(allStates, events[id][triggernum], id, triggernum, event.force_events) or updateTriggerState;
      elseif (type(event.force_events) == "boolean" and event.force_events) then
        for i, eventName in pairs(event.events) do
          updateTriggerState = RunTriggerFunc(allStates, events[id][triggernum], id, triggernum, eventName) or updateTriggerState;
        end
      end
    end
  end

  if (updateTriggerState) then
    WeakAuras.UpdatedTriggerState(id);
  end
  WeakAuras.ActivateAuraEnvironment(nil);
end

function GenericTrigger.ScanAll()
  for id, _ in pairs(loaded_auras) do
    GenericTrigger.ScanWithFakeEvent(id);
  end
end

function HandleEvent(frame, event, arg1, arg2, ...)
  WeakAuras.StartProfileSystem("generictrigger " .. event);
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
      WeakAuras.StartProfileSystem("generictrigger WA_DELAYED_PLAYER_ENTERING_WORLD");
      HandleEvent(frame, "WA_DELAYED_PLAYER_ENTERING_WORLD");
      WeakAuras.CheckCooldownReady();
      WeakAuras.StopProfileSystem("generictrigger WA_DELAYED_PLAYER_ENTERING_WORLD");
    end,
    0.8);  -- Data not available
  end
  WeakAuras.StopProfileSystem("generictrigger " .. event);
end

function GenericTrigger.UnloadAll()
  wipe(loaded_auras);
  wipe(loaded_events);
  WeakAuras.UnregisterAllEveryFrameUpdate();
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
    WeakAuras.UnregisterEveryFrameUpdate(id);
  end
end

local genericTriggerRegisteredEvents = {};
local frame = CreateFrame("FRAME");
WeakAuras.frames["WeakAuras Generic Trigger Frame"] = frame;
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
genericTriggerRegisteredEvents["PLAYER_ENTERING_WORLD"] = true;
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

  WeakAuras.EveryFrameUpdateRename(oldid, newid)
end

function LoadEvent(id, triggernum, data)
  local events = data.events or {};
  for index, event in pairs(events) do
    loaded_events[event] = loaded_events[event] or {};
    if(event == "COMBAT_LOG_EVENT_UNFILTERED" and data.subevent) then
      loaded_events[event][data.subevent] = loaded_events[event][data.subevent] or {};
      loaded_events[event][data.subevent][id] = loaded_events[event][data.subevent][id] or {}
      loaded_events[event][data.subevent][id][triggernum] = data;
    else
      loaded_events[event][id] = loaded_events[event][id] or {};
      loaded_events[event][id][triggernum] = data;
    end
  end
  if (data.internal_events) then
    for index, event in pairs(data.internal_events) do
      loaded_events[event] = loaded_events[event] or {};
      loaded_events[event][id] = loaded_events[event][id] or {};
      loaded_events[event][id][triggernum] = data;
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
function GenericTrigger.LoadDisplays(toLoad, loadEvent, ...)
  for id in pairs(toLoad) do
    local register_for_frame_updates = false;
    if(events[id]) then
      loaded_auras[id] = true;
      for triggernum, data in pairs(events[id]) do
        for index, event in pairs(data.events) do
          if (event == "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM") then
            eventsToRegister["COMBAT_LOG_EVENT_UNFILTERED"] = true;
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

        LoadEvent(id, triggernum, data);
      end
    end

    if(register_for_frame_updates) then
      WeakAuras.RegisterEveryFrameUpdate(id);
    else
      WeakAuras.UnregisterEveryFrameUpdate(id);
    end
  end

  for event in pairs(eventsToRegister) do
    xpcall(frame.RegisterEvent, trueFunction, frame, event)
    genericTriggerRegisteredEvents[event] = true;
  end

  for id in pairs(toLoad) do
    GenericTrigger.ScanWithFakeEvent(id);
  end

  if (eventsToRegister[loadEvent]) then
    WeakAuras.ScanEvents(loadEvent, ...);
  end

  wipe(eventsToRegister);
end

function GenericTrigger.FinishLoadUnload()
end

--- Adds a display, creating all internal data structures for all triggers.
-- @param data
-- @param region
function GenericTrigger.Add(data, region)
  local id = data.id;
  events[id] = nil;
  WeakAuras.forceable_events[id] = {};

  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger
    local triggerType;
    if(trigger and type(trigger) == "table") then
      triggerType = trigger.type;
      if(triggerType == "status" or triggerType == "event" or triggerType == "custom") then
        local triggerFuncStr, triggerFunc, untriggerFuncStr, untriggerFunc, statesParameter;
        local trigger_events = {};
        local internal_events = {};
        local force_events = false;
        local durationFunc, overlayFuncs, nameFunc, iconFunc, textureFunc, stacksFunc, loadFunc;
        local tsuConditionVariables;
        if(triggerType == "status" or triggerType == "event") then
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
              if not(WeakAuras.subevent_actual_prefix_types[trigger.subeventPrefix]) then
                trigger.subeventSuffix = "";
              end
            end



            triggerFuncStr = ConstructFunction(event_prototypes[trigger.event], trigger);

            statesParameter = event_prototypes[trigger.event].statesParameter;
            WeakAuras.debug(id.." - "..triggernum.." - Trigger", 1);
            WeakAuras.debug(triggerFuncStr);
            triggerFunc = WeakAuras.LoadFunction(triggerFuncStr, id);

            durationFunc = event_prototypes[trigger.event].durationFunc;
            nameFunc = event_prototypes[trigger.event].nameFunc;
            iconFunc = event_prototypes[trigger.event].iconFunc;
            textureFunc = event_prototypes[trigger.event].textureFunc;
            stacksFunc = event_prototypes[trigger.event].stacksFunc;
            loadFunc = event_prototypes[trigger.event].loadFunc;

            if (event_prototypes[trigger.event].overlayFuncs) then
              overlayFuncs = {};
              local dest = 1;
              for i, v in ipairs(event_prototypes[trigger.event].overlayFuncs) do
                if (v.enable(trigger)) then
                  overlayFuncs[dest] = v.func;
                  dest = dest + 1;
                end
              end
            end

            if (event_prototypes[trigger.event].automaticrequired) then
              trigger.unevent = "auto";
            elseif event_prototypes[trigger.event].automatic then
              if not(WeakAuras.autoeventend_types[trigger.unevent]) then
                trigger.unevent = "auto"
              end
            else
              if not(WeakAuras.eventend_types[trigger.unevent]) then
                trigger.unevent = "timed"
              end
            end
            trigger.duration = trigger.duration or "1"

            if(trigger.unevent == "custom") then
              untriggerFuncStr = ConstructFunction(event_prototypes[trigger.event], untrigger);
            elseif(trigger.unevent == "auto") then
              untriggerFuncStr = ConstructFunction(event_prototypes[trigger.event], trigger, true);
            end

            if(untriggerFuncStr) then
              WeakAuras.debug(id.." - "..triggernum.." - Untrigger", 1)
              WeakAuras.debug(untriggerFuncStr);
              untriggerFunc = WeakAuras.LoadFunction(untriggerFuncStr, id);
            end

            local prototype = event_prototypes[trigger.event];
            if(prototype) then
              trigger_events = prototype.events;
              internal_events = prototype.internal_events;
              force_events = prototype.force_events;
              if (type(trigger_events) == "function") then
                trigger_events = trigger_events(trigger, untrigger);
              end
              if (type(internal_events) == "function") then
                internal_events = internal_events(trigger, untrigger);
              end
            end
          end
        else
          triggerFunc = WeakAuras.LoadFunction("return "..(trigger.custom or ""), id);
          if (trigger.custom_type == "stateupdate") then
            tsuConditionVariables = WeakAuras.LoadFunction("return \n" .. (trigger.customVariables or ""));
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
            trigger_events = WeakAuras.split(trigger.events);
            for index, event in pairs(trigger_events) do
              if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
                -- This is a dirty, lazy, dirty hack. "Proper" COMBAT_LOG_EVENT_UNFILTERED events are indexed by their sub-event types (e.g. SPELL_PERIODIC_DAMAGE),
                -- but custom COMBAT_LOG_EVENT_UNFILTERED events are not guaranteed to have sub-event types. Thus, if the user specifies that they want to use
                -- COMBAT_LOG_EVENT_UNFILTERED, this hack renames the event to COMBAT_LOG_EVENT_UNFILTERED_CUSTOM to circumvent the COMBAT_LOG_EVENT_UNFILTERED checks
                -- that are already in place. Replacing all those checks would be a pain in the ass.
                trigger_events[index] = "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM";
              end
              force_events = trigger.custom_type == "status" or trigger.custom_type == "stateupdate";
            end
          end
          if (trigger.custom_type == "stateupdate") then
            statesParameter = "full";
          end
        end

        local automaticAutoHide;
        local duration;
        if(triggerType == "custom"
          and trigger.custom_type == "event"
          and trigger.custom_hide == "timed") then
            automaticAutoHide = true;
            if (not trigger.dynamicDuration) then
              duration = tonumber(trigger.duration);
            end
        end

        if (triggerType == "event" and trigger.unevent == "timed") then
          duration = tonumber(trigger.duration);
          automaticAutoHide = true;
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
          inverse = trigger.use_inverse,
          subevent = trigger.event == "Combat Log" and trigger.subeventPrefix and trigger.subeventSuffix and (trigger.subeventPrefix..trigger.subeventSuffix);
          unevent = trigger.unevent,
          durationFunc = durationFunc,
          overlayFuncs = overlayFuncs,
          nameFunc = nameFunc,
          iconFunc = iconFunc,
          textureFunc = textureFunc,
          stacksFunc = stacksFunc,
          loadFunc = loadFunc,
          duration = duration,
          automaticAutoHide = automaticAutoHide,
          tsuConditionVariables = tsuConditionVariables
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

  function WeakAuras.RegisterEveryFrameUpdate(id)
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

  function WeakAuras.EveryFrameUpdateRename(oldid, newid)
    update_clients[newid] = update_clients[oldid];
    update_clients[oldid] = nil;
  end

  function WeakAuras.UnregisterEveryFrameUpdate(id)
    if(update_clients[id]) then
      update_clients[id] = nil;
      update_clients_num = update_clients_num - 1;
    end
    if(update_clients_num == 0 and update_frame and updating) then
      update_frame:SetScript("OnUpdate", nil);
      updating = false;
    end
  end

  function WeakAuras.UnregisterAllEveryFrameUpdate()
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

function GenericTrigger.Modernize(data)
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger

    if (data.internalVersion < 2) then
      -- Convert any references to "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM" to "COMBAT_LOG_EVENT_UNFILTERED"
      if(trigger and trigger.custom) then
        trigger.custom = trigger.custom:gsub("COMBAT_LOG_EVENT_UNFILTERED_CUSTOM", "COMBAT_LOG_EVENT_UNFILTERED");
      end

      if(untrigger and untrigger.custom) then
        untrigger.custom = untrigger.custom:gsub("COMBAT_LOG_EVENT_UNFILTERED_CUSTOM", "COMBAT_LOG_EVENT_UNFILTERED");
      end

      if trigger and trigger["event"] and trigger["event"] == "DBM Timer" then
        if (type(trigger.spellId) == "number") then
          trigger.spellId = tostring(trigger.spellId);
        end
      end

      if trigger and trigger["event"] and trigger["event"] == "Item Set Equipped" then
        trigger.event = "Equipment Set";
      end

      -- Convert ember trigger
      local fixEmberTrigger = function(trigger)
        if (trigger.power and not trigger.ember) then
          trigger.ember = tostring(tonumber(trigger.power) * 10);
          trigger.use_ember = trigger.use_power
          trigger.ember_operator = trigger.power_operator;
          trigger.power = nil;
          trigger.use_power = nil;
          trigger.power_operator = nil;
        end
      end

      if (trigger and trigger.type and trigger.event and trigger.type == "status" and trigger.event == "Burning Embers") then
        fixEmberTrigger(trigger);
        fixEmberTrigger(untrigger);
      end

      if (trigger and trigger.type and trigger.event and trigger.type == "status"
        and (trigger.event == "Cooldown Progress (Spell)"
        or trigger.event == "Cooldown Progress (Item)"
        or trigger.event == "Death Knight Rune")) then

        if (not trigger.showOn) then
          if (trigger.use_inverse) then
            trigger.showOn = "showOnReady"
          else
            trigger.showOn = "showOnCooldown"
          end

          if (trigger.event == "Death Knight Rune") then
            trigger.use_genericShowOn = true;
          end
          trigger.use_inverse = nil
        end
      end

      for old, new in pairs(combatLogUpgrade) do
        if (trigger and trigger[old]) then
          local useOld = "use_" .. old;
          local useNew = "use_" .. new;
          trigger[useNew] = trigger[useOld];
          trigger[new] = trigger[old];

          trigger[old] = nil;
          trigger[useOld] = nil;
        end
      end

      -- Convert separated Power Triggers to sub options of the Power trigger
      if (trigger and trigger.type and trigger.event and trigger.type == "status" and oldPowerTriggers[trigger.event]) then
        trigger.powertype = oldPowerTriggers[trigger.event]
        trigger.use_powertype = true;
        trigger.use_percentpower = false;
        if (trigger.event == "Combo Points") then
          trigger.power = trigger.combopoints;
          trigger.power_operator = trigger.combopoints_operator
          trigger.use_power = trigger.use_combopoints;
        end
        trigger.event = "Power";
        trigger.unit = "player";
      end
    end

    if data.internalVersion < 6 then
      if trigger and trigger.type ~= "aura" then
        trigger.genericShowOn = trigger.showOn or "showOnActive"
        trigger.showOn = nil
        trigger.use_genericShowOn = trigger.use_showOn
      end
    end
  end
end

function GenericTrigger.AllAdded()
  -- Remove GTFO options if GTFO isn't enabled and there are no saved GTFO auras
  local hideGTFO = true;
  local hideDBM = true;

  if (GTFO) then
    hideGTFO = false;
  end

  if (DBM) then
    hideDBM = false;
  end

  for id, event in pairs(events) do
    for triggernum, data in pairs(event) do
      if (data.trigger.event == "GTFO") then
        hideGTFO = false;
      end
      if (data.trigger.event == "DBM Announce" or data.trigger.event == "DBM Timer") then
        hideDBM = false;
      end
    end
  end
  if (hideGTFO) then
    WeakAuras.event_types["GTFO"] = nil;
  end
  if (hideDBM) then
    WeakAuras.event_types["DBM Announce"] = nil;
    WeakAuras.status_types["DBM Timer"] = nil;
  end
end

--#############################
--# Support code for triggers #
--#############################

-- Swing timer support code
do
  local mh = GetInventorySlotInfo("MainHandSlot")
  local oh = GetInventorySlotInfo("SecondaryHandSlot")

  local swingTimerFrame;
  local lastSwingMain, lastSwingOff, lastSwingRange;
  local swingDurationMain, swingDurationOff, swingDurationRange;
  local mainTimer, offTimer, rangeTimer;
  local selfGUID;

  function WeakAuras.GetSwingTimerInfo(hand)
    if(hand == "main") then
      local itemId = GetInventoryItemID("player", mh);
      local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemId or 0);
      if(lastSwingMain) then
        return swingDurationMain, lastSwingMain + swingDurationMain, name, icon;
      elseif (lastSwingRange) then
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
    end

    return 0, math.huge;
  end

  local function swingEnd(hand)
    if(hand == "main") then
      lastSwingMain, swingDurationMain = nil, nil;
    elseif(hand == "off") then
      lastSwingOff, swingDurationOff = nil, nil;
    elseif(hand == "range") then
      lastSwingRange, swingDurationRange = nil, nil;
    end
    WeakAuras.ScanEvents("SWING_TIMER_END");
  end

  local function swingTimerCheck(ts, event, _, sourceGUID, _, _, _, destGUID, _, _, _, ...)
    WeakAuras.StartProfileSystem("generictrigger swing");
    if(sourceGUID == selfGUID) then
      if(event == "SWING_DAMAGE" or event == "SWING_MISSED") then
        local isOffHand = select(event == "SWING_DAMAGE" and 10 or 2, ...);

        local event;
        local currentTime = GetTime();
        local mainSpeed, offSpeed = UnitAttackSpeed("player");
        offSpeed = offSpeed or 0;
        if not(isOffHand) then
          lastSwingMain = currentTime;
          swingDurationMain = mainSpeed;
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
      elseif(event == "RANGE_DAMAGE" or event == "RANGE_MISSED") then
        local event;
        local currentTime = GetTime();
        local speed = UnitRangedDamage("player");
        if(lastSwingRange) then
          timer:CancelTimer(rangeTimer, true);
          event = "SWING_TIMER_CHANGE";
        else
          event = "SWING_TIMER_START";
        end
        lastSwingRange = currentTime;
        swingDurationRange = speed;
        rangeTimer = timer:ScheduleTimerFixed(swingEnd, speed, "range");

        WeakAuras.ScanEvents(event);
      end
    elseif (destGUID == selfGUID and (select(1, ...) == "PARRY" or select(4, ...) == "PARRY")) then
      if (lastSwingMain) then
        local timeLeft = lastSwingMain + swingDurationMain - GetTime();
        if (timeLeft > 0.6 * swingDurationMain) then
          timer:CancelTimer(mainTimer);
          mainTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft - 0.4 * swingDurationMain, "main");
          WeakAuras.ScanEvents("SWING_TIMER_CHANGE");
        elseif (timeLeft > 0.2 * swingDurationMain) then
          timer:CancelTimer(mainTimer);
          mainTimer = timer:ScheduleTimerFixed(swingEnd, timeLeft - 0.2 * swingDurationMain, "main");
          WeakAuras.ScanEvents("SWING_TIMER_CHANGE");
        end
      end
    end
    WeakAuras.StopProfileSystem("generictrigger swing");
  end

  function WeakAuras.InitSwingTimer()
    if not(swingTimerFrame) then
      swingTimerFrame = CreateFrame("frame");
      swingTimerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
      swingTimerFrame:SetScript("OnEvent",
        function()
          swingTimerCheck(CombatLogGetCurrentEventInfo())
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
  local spellsRune = {}
  local spellCdDurs = {};
  local spellCdExps = {};
  local spellCdDursRune = {};
  local spellCdExpsRune = {};
  local spellCharges = {};
  local spellChargesMax = {};
  local spellCdHandles = {};
  local spellCdRuneHandles = {};

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

  local gcdReference;
  local gcdStart;
  local gcdDuration;
  local gcdSpellName;
  local gcdSpellIcon;
  local gcdEndCheck;

  function WeakAuras.InitCooldownReady()
    cdReadyFrame = CreateFrame("FRAME");
    WeakAuras.frames["Cooldown Trigger Handler"] = cdReadyFrame
    cdReadyFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    cdReadyFrame:RegisterEvent("SPELL_UPDATE_CHARGES");
    cdReadyFrame:RegisterEvent("RUNE_POWER_UPDATE");
    cdReadyFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
    cdReadyFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
    cdReadyFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
    cdReadyFrame:RegisterEvent("BAG_UPDATE_COOLDOWN");
    cdReadyFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    cdReadyFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    cdReadyFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
    cdReadyFrame:RegisterEvent("SPELLS_CHANGED");
    cdReadyFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    cdReadyFrame:SetScript("OnEvent", function(self, event, ...)
      WeakAuras.StartProfileSystem("generictrigger cd tracking");
      if(event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES"
        or event == "RUNE_POWER_UPDATE" or event == "ACTIONBAR_UPDATE_COOLDOWN"
        or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_PVP_TALENT_UPDATE") then
        WeakAuras.CheckCooldownReady();
      elseif(event == "SPELLS_CHANGED") then
        WeakAuras.CheckSpellKnown();
      elseif(event == "UNIT_SPELLCAST_SENT") then
        local unit, guid, castGUID, name = ...;
        if(unit == "player") then
          name = GetSpellInfo(name);
          if(gcdSpellName ~= name) then
            local icon = GetSpellTexture(name);
            gcdSpellName = name;
            gcdSpellIcon = icon;
            WeakAuras.ScanEvents("GCD_UPDATE");
          end
        end
      elseif(event == "UNIT_INVENTORY_CHANGED" or event == "BAG_UPDATE_COOLDOWN" or event == "PLAYER_EQUIPMENT_CHANGED") then
        WeakAuras.CheckItemSlotCooldowns();
      end
      WeakAuras.StopProfileSystem("generictrigger cd tracking");
    end);
  end

  function WeakAuras.GetRuneCooldown(id)
    if(runes[id] and runeCdExps[id] and runeCdDurs[id]) then
      return runeCdExps[id] - runeCdDurs[id], runeCdDurs[id];
    else
      return 0, 0;
    end
  end

  function WeakAuras.GetSpellCooldown(id, ignoreRuneCD, showgcd)
    if (not spellKnown[id]) then
      return;
    end
    local startTime, duration, gcdCooldown;
    if (ignoreRuneCD) then
      if (spellsRune[id] and spellCdExpsRune[id] and spellCdDursRune[id]) then
        startTime = spellCdExpsRune[id] - spellCdDursRune[id]
        duration = spellCdDursRune[id];
      else
        startTime = 0;
        duration = 0;
      end
    else
      if(spells[id] and spellCdExps[id] and spellCdDurs[id]) then
        startTime = spellCdExps[id] - spellCdDurs[id];
        duration = spellCdDurs[id];
      else
        startTime = 0;
        duration = 0;
      end
    end

    if (showgcd) then
      if ((gcdStart or 0) + (gcdDuration or 0) > startTime + duration) then
        startTime = gcdStart;
        duration = gcdDuration;
        gcdCooldown = true;
      end
    end

    return startTime, duration, gcdCooldown;
  end

  function WeakAuras.GetSpellCharges(id)
    if (not spellKnown[id]) then
      return;
    end
    return spellCharges[id], spellChargesMax[id];
  end

  function WeakAuras.GetItemCooldown(id)
    if(items[id] and itemCdExps[id] and itemCdDurs[id]) then
      return itemCdExps[id] - itemCdDurs[id], itemCdDurs[id], itemCdEnabled[id];
    else
      return 0, 0, itemCdEnabled[id] or 1;
    end
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

  function WeakAuras.GetItemSlotCooldown(id)
    if(itemSlots[id] and itemSlotsCdExps[id] and itemSlotsCdDurs[id]) then
      return itemSlotsCdExps[id] - itemSlotsCdDurs[id], itemSlotsCdDurs[id], itemSlotsEnable[id];
    else
      return 0, 0, itemSlotsEnable[id];
    end
  end

  local function RuneCooldownFinished(id)
    runeCdHandles[id] = nil;
    runeCdDurs[id] = nil;
    runeCdExps[id] = nil;
    WeakAuras.ScanEvents("RUNE_COOLDOWN_READY", id);
  end

  local function SpellCooldownRuneFinished(id)
    spellCdRuneHandles[id] = nil;
    spellCdDursRune[id] = nil;
    spellCdExpsRune[id] = nil;

    local charges, maxCharges = WeakAuras.GetSpellCooldownUnified(id);
    local chargesDifference = (charges or 0) - (spellCharges[id] or 0)
    if (chargesDifference ~= 0 ) then
      WeakAuras.ScanEvents("SPELL_CHARGES_CHANGED", id, chargesDifference, charges or 0);
    end
    spellCharges[id] = charges
    spellChargesMax[id] = maxCharges;
    WeakAuras.ScanEvents("SPELL_COOLDOWN_READY", id, nil);
  end

  local function SpellCooldownFinished(id)
    spellCdHandles[id] = nil;
    spellCdDurs[id] = nil;
    spellCdExps[id] = nil;
    local charges, maxCharges = WeakAuras.GetSpellCooldownUnified(id);
    local chargesDifference =  (charges or 0) - (spellCharges[id] or 0)
    if (chargesDifference ~= 0 ) then
      WeakAuras.ScanEvents("SPELL_CHARGES_CHANGED", id, chargesDifference, charges or 0);
    end
    spellCharges[id] = charges
    spellChargesMax[id] = maxCharges;
    WeakAuras.ScanEvents("SPELL_COOLDOWN_READY", id, nil);
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

  local function CheckGCD()
    local event;
    local startTime, duration = GetSpellCooldown(61304);
    if(duration and duration > 0) then
      if not(gcdStart) then
        event = "GCD_START";
      elseif(gcdStart ~= startTime) then
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
    if(event) then
      WeakAuras.ScanEvents(event);
    end
  end

  function WeakAuras.CheckRuneCooldown()
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
    local charges, maxCharges, startTime, duration = GetSpellCharges(id);
    local cooldownBecauseRune = false;
    if (charges == nil) then -- charges is nil if the spell has no charges. Or in other words GetSpellCharges is the wrong api
      local basecd = GetSpellBaseCooldown(id);
      local enabled;
      startTime, duration, enabled = GetSpellCooldown(id);
      if (enabled == 0) then
        startTime, duration = 0, 0
      end

      local spellcount = GetSpellCount(id);
      -- GetSpellCount returns 0 for all spells that have no spell counts, so we only use that information if
      -- either the spell count is greater than 0
      -- or we have a ability without a base cooldown
      -- Checking the base cooldown is not enough though, since some abilities have no base cooldown, but can still be on cooldown
      -- e.g. Raging Blow that gains a cooldown with a talent
      if (spellcount > 0) then
        charges = spellcount;
      end

      local onNonGCDCD = duration and startTime and duration > 0 and (duration ~= gcdDuration or startTime ~= gcdStart);

      if ((basecd and basecd > 0) or onNonGCDCD) then
        cooldownBecauseRune = runeDuration and duration and abs(duration - runeDuration) < 0.001;
      else
        charges = spellcount;
        startTime = 0;
        duration = 0;
      end
    elseif (charges == maxCharges) then
      startTime, duration = 0, 0;
    elseif (charges == 0 and duration == 0) then -- Lavaburst while under Ascendance can return 0 charges even if the spell is useable
      charges = 1;
    end

    startTime = startTime or 0;
    duration = duration or 0;
    -- WORKAROUND Sometimes the API returns very high bogus numbers causing client freeezes, discard them here. WowAce issue #1008
    if (duration > 604800) then
      duration = 0;
      startTime = 0;
    end

    return charges, maxCharges, startTime, duration, cooldownBecauseRune;
  end

  function WeakAuras.CheckSpellKnown()
    for id, _ in pairs(spells) do
      local known = WeakAuras.IsSpellKnownIncludingPet(id);
      if (known ~= spellKnown[id]) then
        spellKnown[id] = known;
        WeakAuras.ScanEvents("SPELL_COOLDOWN_CHANGED", id);
      end
    end
  end

  function WeakAuras.CheckSpellCooldows(runeDuration)
    for id, _ in pairs(spells) do
      local charges, maxCharges, startTime, duration, cooldownBecauseRune = WeakAuras.GetSpellCooldownUnified(id, runeDuration);

      local time = GetTime();
      local remaining = startTime + duration - time;

      local chargesChanged = spellCharges[id] ~= charges;
      local chargesDifference =  (charges or 0) - (spellCharges[id] or 0)
      if (chargesDifference ~= 0 ) then
        WeakAuras.ScanEvents("SPELL_CHARGES_CHANGED", id, chargesDifference, charges or 0);
      end
      spellCharges[id] = charges;
      spellChargesMax[id] = maxCharges;

      if(duration > 0 and (duration ~= gcdDuration or startTime ~= gcdStart)) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(spellCdExps[id]) then
          -- New cooldown
          spellCdDurs[id] = duration;
          spellCdExps[id] = endTime;
          spellCdHandles[id] = timer:ScheduleTimerFixed(SpellCooldownFinished, endTime - time, id);
          if (spellsRune[id] and not cooldownBecauseRune ) then
            spellCdDursRune[id] = duration;
            spellCdExpsRune[id] = endTime;
            spellCdRuneHandles[id] = timer:ScheduleTimerFixed(SpellCooldownRuneFinished, endTime - time, id);
          end
          WeakAuras.ScanEvents("SPELL_COOLDOWN_STARTED", id);
        elseif(spellCdExps[id] ~= endTime or chargesChanged) then
          -- Cooldown is now different
          if(spellCdHandles[id]) then
            timer:CancelTimer(spellCdHandles[id]);
          end

          spellCdDurs[id] = duration;
          spellCdExps[id] = endTime;
          if (maxCharges == nil or charges + 1 == maxCharges) then
            spellCdHandles[id] = timer:ScheduleTimerFixed(SpellCooldownFinished, endTime - time, id);
          end
          if (spellsRune[id] and not cooldownBecauseRune ) then
            spellCdDursRune[id] = duration;
            spellCdExpsRune[id] = endTime;

            if(spellCdRuneHandles[id]) then
              timer:CancelTimer(spellCdRuneHandles[id]);
            end
            spellCdRuneHandles[id] = timer:ScheduleTimerFixed(SpellCooldownRuneFinished, endTime - time, id);
          end
          WeakAuras.ScanEvents("SPELL_COOLDOWN_CHANGED", id);
        end
      else
        if(spellCdExps[id]) then
          local endTime = startTime + duration;
          if (duration == WeakAuras.gcdDuration() and startTime == gcdStart and spellCdExps[id] > endTime or duration == 0) then
            -- CheckCooldownReady caught the spell cooldown before the timer callback
            -- This happens if a proc resets the cooldown
            if(spellCdHandles[id]) then
              timer:CancelTimer(spellCdHandles[id]);
            end
            SpellCooldownFinished(id);

            if(spellCdRuneHandles[id]) then
              timer:CancelTimer(spellCdRuneHandles[id]);
            end
            SpellCooldownRuneFinished(id);
          end
        end
        if (chargesChanged) then
          WeakAuras.ScanEvents("SPELL_COOLDOWN_CHANGED", id);
        end
      end
    end
  end

  function WeakAuras.CheckItemCooldowns()
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

      if(duration > 0 and duration ~= WeakAuras.gcdDuration()) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(itemCdExps[id]) then
          -- New cooldown
          itemCdDurs[id] = duration;
          itemCdExps[id] = endTime;
          itemCdHandles[id] = timer:ScheduleTimerFixed(ItemCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("ITEM_COOLDOWN_STARTED", id);
          itemCdEnabledChanged = false;
        elseif(itemCdExps[id] ~= endTime) then
          -- Cooldown is now different
          if(itemCdHandles[id]) then
            timer:CancelTimer(itemCdHandles[id]);
          end
          itemCdDurs[id] = duration;
          itemCdExps[id] = endTime;
          itemCdHandles[id] = timer:ScheduleTimerFixed(ItemCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("ITEM_COOLDOWN_CHANGED", id);
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
      if (itemCdEnabledChanged) then
        WeakAuras.ScanEvents("ITEM_COOLDOWN_CHANGED", id);
      end
    end
  end

  function WeakAuras.CheckItemSlotCooldowns()
    for id, itemId in pairs(itemSlots) do
      local startTime, duration, enable = GetInventoryItemCooldown("player", id);
      itemSlotsEnable[id] = enable;
      startTime = startTime or 0;
      duration = duration or 0;
      local time = GetTime();

      if(duration > 0 and duration ~= WeakAuras.gcdDuration()) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(itemSlotsCdExps[id]) then
          -- New cooldown
          itemSlotsCdDurs[id] = duration;
          itemSlotsCdExps[id] = endTime;
          itemSlotsCdHandles[id] = timer:ScheduleTimerFixed(ItemSlotCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("ITEM_SLOT_COOLDOWN_STARTED", id);
        elseif(itemSlotsCdExps[id] ~= endTime) then
          -- Cooldown is now different
          if(itemSlotsCdHandles[id]) then
            timer:CancelTimer(itemSlotsCdHandles[id]);
          end
          itemSlotsCdDurs[id] = duration;
          itemSlotsCdExps[id] = endTime;
          itemSlotsCdHandles[id] = timer:ScheduleTimerFixed(ItemSlotCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("ITEM_SLOT_COOLDOWN_CHANGED", id);
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
        WeakAuras.ScanEvents("ITEM_SLOT_COOLDOWN_ITEM_CHANGED");
        itemSlots[id] = newItemId or 0;
      end
    end
  end

  function WeakAuras.CheckCooldownReady()
    CheckGCD();
    local runeDuration = WeakAuras.CheckRuneCooldown();
    WeakAuras.CheckSpellCooldows(runeDuration);
    WeakAuras.CheckItemCooldowns();
    WeakAuras.CheckItemSlotCooldowns();
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

    if (ignoreRunes) then
      spellsRune[id] = true;
      for i = 1, 6 do
        WeakAuras.WatchRuneCooldown(i);
      end
    end

    if (spells[id]) then
      return;
    end
    spells[id] = true;
    spellKnown[id] = WeakAuras.IsSpellKnownIncludingPet(id);

    local charges, maxCharges, startTime, duration = WeakAuras.GetSpellCooldownUnified(id);
    spellCharges[id] = charges;
    spellChargesMax[id] = maxCharges;

    if(duration > 0 and (duration ~= gcdDuration or startTime ~= gcdStart)) then
      local time = GetTime();
      local endTime = startTime + duration;
      spellCdDurs[id] = duration;
      spellCdExps[id] = endTime;
      local runeDuration = -100;
      for id, _ in pairs(runes) do
        local startTime, duration = GetRuneCooldown(id);
        startTime = startTime or 0;
        duration = duration or 0;
        runeDuration = duration > 0 and duration or runeDuration
      end
      if (duration ~= runeDuration and ignoreRunes) then
        spellCdDursRune[id] = duration;
        spellCdExpsRune[id] = endTime;
        if not(spellCdRuneHandles[id]) then
          spellCdRuneHandles[id] = timer:ScheduleTimerFixed(SpellCooldownRuneFinished, endTime - time, id);
        end
      end
      if not(spellCdHandles[id]) then
        spellCdHandles[id] = timer:ScheduleTimerFixed(SpellCooldownFinished, endTime - time, id);
      end
    end
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
      if(duration > 0 and duration ~= WeakAuras.gcdDuration()) then
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
      if(duration > 0 and duration ~= WeakAuras.gcdDuration()) then
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
      WeakAuras.StartProfileSystem("generictrigger");
      if (spellActivationSpells[spell]) then
        spellActivationSpellsCurrent[spell] = (event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW");
        WeakAuras.ScanEvents("WA_UPDATE_OVERLAY_GLOW", spell);
      end
      WeakAuras.StopProfileSystem("generictrigger");
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
  local bars = {};
  local nextExpire; -- time of next expiring timer
  local recheckTimer; -- handle of timer

  local function dbmRecheckTimers()
    local now = GetTime();
    nextExpire = nil;
    for k, v in pairs(bars) do
      if (v.expirationTime < now) then
        bars[k] = nil;
        WeakAuras.ScanEvents("DBM_TimerStop", k);
      elseif (nextExpire == nil) then
        nextExpire = v.expirationTime;
      elseif (v.expirationTime < nextExpire) then
        nextExpire = v.expirationTime;
      end
    end

    if (nextExpire) then
      recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, nextExpire - now);
    end
  end

  local function dbmEventCallback(event, ...)
    if (event == "DBM_TimerStart") then
      local id, msg, duration, icon, timerType, spellId, colorId = ...;
      local now = GetTime();
      local expiring = now + duration;
      bars[id] = bars[id] or {}
      -- Store everything, event though we are only using some of those
      bars[id]["message"] = msg;
      bars[id]["expirationTime"] = expiring;
      bars[id]["duration"] = duration;
      bars[id]["icon"] = icon;
      bars[id]["timerType"] = timerType;
      bars[id]["spellId"] = tostring(spellId);
      bars[id]["colorId"] = colorId;

      if (nextExpire == nil) then
        nextExpire = expiring;
        recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, expiring - now);
      elseif (expiring < nextExpire) then
        nextExpire = expiring;
        timer:CancelTimer(recheckTimer);
        recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, expiring - now, msg);
      end
      WeakAuras.ScanEvents("DBM_TimerStart", id);
    elseif (event == "DBM_TimerStop") then
      local id = ...;
      bars[id] = nil;
      WeakAuras.ScanEvents("DBM_TimerStop", id);
    elseif (event == "kill" or event == "wipe") then -- Wipe or kill, removing all timers
      local id = ...;
      bars = {};
      WeakAuras.ScanEvents("DBM_TimerStopAll", id);
    else -- DBM_Announce
      WeakAuras.ScanEvents(event, ...);
    end
  end

  function WeakAuras.DBMTimerMatches(timerId, id, message, operator, spellId)
    if (not bars[timerId]) then
      return false;
    end

    local v = bars[timerId];

    if (id and id ~= timerId) then
      return false;
    end
    if (spellId and spellId ~= v.spellId) then
      return false;
    end
    if (message and operator) then
      if(operator == "==") then
        if (v.message ~= message) then
          return false;
        end
      elseif (operator == "find('%s')") then
        if (v.message == nil or not v.message:find(message, 1, true)) then
          return false;
        end
      elseif (operator == "match('%s')") then
        if (v.message == nil or not v.message:match(message)) then
          return false;
        end
      end
    end
    return true;
  end

  function WeakAuras.GetDBMTimerById(id)
    return bars[id];
  end

  function WeakAuras.GetAllDBMTimers()
    return bars;
  end

  function WeakAuras.GetDBMTimer(id, message, operator, spellId, extendTimer)
    local bar;
    for k, v in pairs(bars) do
      if (WeakAuras.DBMTimerMatches(k, id, message, operator, spellId)
        and (bar == nil or bars[k].expirationTime < bar.expirationTime)
        and (bars[k].expirationTime + extendTimer > GetTime() )) then
        bar = bars[k];
      end
    end
    return bar;
  end

  function WeakAuras.CopyBarToState(bar, states, id, extendTimer)
    extendTimer = extendTimer or 0;
    if extendTimer + bar.duration < 0 then return end
    states[id] = states[id] or {};
    local state = states[id];
    state.show = true;
    state.changed = true;
    state.icon = bar.icon;
    state.message = bar.message;
    state.name = bar.message;
    state.expirationTime = bar.expirationTime + extendTimer;
    state.progressType = 'timed';
    state.resort = true;
    state.duration = bar.duration + extendTimer;
    state.timerType = bar.timerType;
    state.spellId = bar.spellId;
    state.colorId = bar.colorId;
    state.extend = extendTimer;
    if extendTimer ~= 0 then
        state.autoHide = true
    end
  end

  function WeakAuras.RegisterDBMCallback(event)
    if (registeredDBMEvents[event]) then
      return
    end
    if (DBM) then
      DBM:RegisterCallback(event, dbmEventCallback);
      registeredDBMEvents[event] = true;
    end
  end

  function WeakAuras.GetDBMTimers()
    return bars;
  end

  local scheduled_scans = {};

  local function doDbmScan(fireTime)
    WeakAuras.debug("Performing dbm scan at "..fireTime.." ("..GetTime()..")");
    scheduled_scans[fireTime] = nil;
    WeakAuras.ScanEvents("DBM_TimerUpdate");
  end
  function WeakAuras.ScheduleDbmCheck(fireTime)
    if not(scheduled_scans[fireTime]) then
      scheduled_scans[fireTime] = timer:ScheduleTimerFixed(doDbmScan, fireTime - GetTime() + 0.1, fireTime);
      WeakAuras.debug("Scheduled dbm scan at "..fireTime);
    end
  end
end

-- BigWigs
do
  local registeredBigWigsEvents = {}
  local bars = {};
  local nextExpire; -- time of next expiring timer
  local recheckTimer; -- handle of timer

  local function recheckTimers()
    local now = GetTime();
    nextExpire = nil;
    for id, bar in pairs(bars) do
      if (bar.expirationTime < now) then
        bars[id] = nil;
        WeakAuras.ScanEvents("BigWigs_StopBar", id);
      elseif (nextExpire == nil) then
        nextExpire = bar.expirationTime;
      elseif (bar.expirationTime < nextExpire) then
        nextExpire = bar.expirationTime;
      end
    end

    if (nextExpire) then
      recheckTimer = timer:ScheduleTimerFixed(recheckTimers, nextExpire - now);
    end
  end

  local function bigWigsEventCallback(event, ...)
    if (event == "BigWigs_Message") then
      WeakAuras.ScanEvents("BigWigs_Message", ...);
    elseif (event == "BigWigs_StartBar") then
      local addon, spellId, text, duration, icon = ...
      local now = GetTime();
      local expirationTime = now + duration;

      local newBar;
      bars[text] = bars[text] or {};
      local bar = bars[text];
      bar.addon = addon;
      bar.spellId = tostring(spellId);
      bar.text = text;
      bar.duration = duration;
      bar.expirationTime = expirationTime;
      bar.icon = icon;
      WeakAuras.ScanEvents("BigWigs_StartBar", text);
      if (nextExpire == nil) then
        recheckTimer = timer:ScheduleTimerFixed(recheckTimers, expirationTime - now);
        nextExpire = expirationTime;
      elseif (expirationTime < nextExpire) then
        timer:CancelTimer(recheckTimer);
        recheckTimer = timer:ScheduleTimerFixed(recheckTimers, expirationTime - now);
        nextExpire = expirationTime;
      end
    elseif (event == "BigWigs_StopBar") then
      local addon, text = ...
      if(bars[text]) then
        bars[text] = nil;
        WeakAuras.ScanEvents("BigWigs_StopBar", text);
      end
    elseif (event == "BigWigs_StopBars"
      or event == "BigWigs_OnBossDisable"
      or event == "BigWigs_OnPluginDisable") then
      local addon = ...
      for key, bar in pairs(bars) do
        if (bar.addon == addon) then
          bars[key] = nil;
          WeakAuras.ScanEvents("BigWigs_StopBar", key);
        end
      end
    end
  end

  function WeakAuras.RegisterBigWigsCallback(event)
    if (registeredBigWigsEvents [event]) then
      return
    end
    if (BigWigsLoader) then
      BigWigsLoader.RegisterMessage(WeakAuras, event, bigWigsEventCallback);
      registeredBigWigsEvents [event] = true;
    end
  end

  function WeakAuras.RegisterBigWigsTimer()
    WeakAuras.RegisterBigWigsCallback("BigWigs_StartBar");
    WeakAuras.RegisterBigWigsCallback("BigWigs_StopBar");
    WeakAuras.RegisterBigWigsCallback("BigWigs_StopBars");
    WeakAuras.RegisterBigWigsCallback("BigWigs_OnBossDisable");
  end

  function WeakAuras.CopyBigWigsTimerToState(bar, states, id, extendTimer)
    extendTimer = extendTimer or 0;
    if extendTimer + bar.duration < 0 then return end
    states[id] = states[id] or {};
    local state = states[id];
    state.show = true;
    state.changed = true;
    state.addon = bar.addon;
    state.spellId = bar.spellId;
    state.text = bar.text;
    state.name = bar.text;
    state.duration = bar.duration + extendTimer;
    state.expirationTime = bar.expirationTime + extendTimer;
    state.resort = true;
    state.progressType = "timed";
    state.icon = bar.icon;
    state.extend = extendTimer;
    if extendTimer ~= 0 then
      state.autoHide = true
    end
  end

  function WeakAuras.BigWigsTimerMatches(id, addon, spellId, textOperator, text)
    if(not bars[id]) then
      return false;
    end

    local v = bars[id];
    local bestMatch;
    if (addon and addon ~= v.addon) then
      return false;
    end
    if (spellId ~= "" and spellId ~= v.spellId) then
      return false;
    end
    if (text) then
      if(textOperator == "==") then
        if (v.text ~= text) then
          return false;
        end
      elseif (textOperator == "find('%s')") then
        if (v.text == nil or not v.text:find(text, 1, true)) then
          return false;
        end
      elseif (textOperator == "match('%s')") then
        if (v.text == nil or not v.text:match(text)) then
          return false;
        end
      end
    end
    return true;
  end

  function WeakAuras.GetAllBigWigsTimers()
    return bars;
  end

  function WeakAuras.GetBigWigsTimerById(id)
    return bars[id];
  end

  function WeakAuras.GetBigWigsTimer(addon, spellId, operator, text, extendTimer)
    local bestMatch
    for id, bar in pairs(bars) do
      if (WeakAuras.BigWigsTimerMatches(id, addon, spellId, operator, text)) then
        if (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime) then
          if (bar.expirationTime + extendTimer > GetTime()) then
            bestMatch = bar;
          end
        end
      end
    end
    return bestMatch;
  end

  local scheduled_scans = {};

  local function doBigWigsScan(fireTime)
    WeakAuras.debug("Performing BigWigs scan at "..fireTime.." ("..GetTime()..")");
    scheduled_scans[fireTime] = nil;
    WeakAuras.ScanEvents("BigWigs_Timer_Update");
  end

  function WeakAuras.ScheduleBigWigsCheck(fireTime)
    if not(scheduled_scans[fireTime]) then
      scheduled_scans[fireTime] = timer:ScheduleTimerFixed(doBigWigsScan, fireTime - GetTime() + 0.1, fireTime);
      WeakAuras.debug("Scheduled BigWigs scan at "..fireTime);
    end
  end
end

-- Weapon Enchants
do
  local mh = GetInventorySlotInfo("MainHandSlot")
  local oh = GetInventorySlotInfo("SecondaryHandSlot")

  local mh_name, mh_exp, mh_dur;
  local mh_icon = GetInventoryItemTexture("player", mh);

  local oh_name, oh_exp, oh_dur;
  local oh_icon = GetInventoryItemTexture("player", oh);

  local tenchFrame = nil
  WeakAuras.frames["Temporary Enchant Handler"] = tenchFrame;
  local tenchTip;

  function WeakAuras.TenchInit()
    if not(tenchFrame) then
      tenchFrame = CreateFrame("Frame");
      tenchFrame:RegisterEvent("UNIT_INVENTORY_CHANGED");

      tenchTip = WeakAuras.GetHiddenTooltip();

      local function getTenchName(id)
        tenchTip:SetInventoryItem("player", id);
        local lines = { tenchTip:GetRegions() };
        for i,v in ipairs(lines) do
          if(v:GetObjectType() == "FontString") then
            local text = v:GetText();
            if(text) then
              local _, _, name = text:find("^(.+) %(%d+ [^%)]+%)$");
              if(name) then
                return name;
              end
            end
          end
        end

        return "Unknown";
      end

      local function tenchUpdate()
        WeakAuras.StartProfileSystem("generictrigger");
        local _, mh_rem, _, _, oh_rem = GetWeaponEnchantInfo();
        local time = GetTime();
        local mh_exp_new = mh_rem and (time + (mh_rem / 1000));
        local oh_exp_new = oh_rem and (time + (oh_rem / 1000));
        if(math.abs((mh_exp or 0) - (mh_exp_new or 0)) > 1) then
          mh_exp = mh_exp_new;
          mh_dur = mh_rem and mh_rem / 1000;
          mh_name = mh_exp and getTenchName(mh) or "None";
          mh_icon = GetInventoryItemTexture("player", mh)
          WeakAuras.ScanEvents("MAINHAND_TENCH_UPDATE");
        end
        if(math.abs((oh_exp or 0) - (oh_exp_new or 0)) > 1) then
          oh_exp = oh_exp_new;
          oh_dur = oh_rem and oh_rem / 1000;
          oh_name = oh_exp and getTenchName(oh) or "None";
          oh_icon = GetInventoryItemTexture("player", oh)
          WeakAuras.ScanEvents("OFFHAND_TENCH_UPDATE");
        end
        WeakAuras.StopProfileSystem("generictrigger");
      end

      tenchFrame:SetScript("OnEvent", function(self, event, arg1)
        WeakAuras.StartProfileSystem("generictrigger");
        if(arg1 == "player") then
          timer:ScheduleTimer(tenchUpdate, 0.1);
        end
        WeakAuras.StopProfileSystem("generictrigger");
      end);
      tenchUpdate();
    end
  end

  function WeakAuras.GetMHTenchInfo()
    return mh_exp, mh_dur, mh_name, mh_icon;
  end

  function WeakAuras.GetOHTenchInfo()
    return oh_exp, oh_dur, oh_name, oh_icon;
  end
end

-- Mounts
do
  local mountedFrame = nil
  WeakAuras.frames["Mount Use Handler"] = mountedFrame;
  function WeakAuras.WatchForMounts()
    if not(mountedFrame) then
      mountedFrame = CreateFrame("frame");
      mountedFrame:RegisterEvent("COMPANION_UPDATE");
      local elapsed = 0;
      local delay = 0.5;
      local isMounted = IsMounted();
      local function checkForMounted(self, elaps)
        WeakAuras.StartProfileSystem("generictrigger");
        elapsed = elapsed + elaps
        if(isMounted ~= IsMounted()) then
          isMounted = IsMounted();
          WeakAuras.ScanEvents("MOUNTED_UPDATE");
          mountedFrame:SetScript("OnUpdate", nil);
        end
        if(elapsed > delay) then
          mountedFrame:SetScript("OnUpdate", nil);
        end
        WeakAuras.StopProfileSystem("generictrigger");
      end
      mountedFrame:SetScript("OnEvent", function()
        WeakAuras.StartProfileSystem("generictrigger");
        elapsed = 0;
        mountedFrame:SetScript("OnUpdate", checkForMounted);
        WeakAuras.StopProfileSystem("generictrigger");
      end)
    end
  end
end

-- Pets
do
  local petFrame = nil
  WeakAuras.frames["Pet Use Handler"] = petFrame;
  function WeakAuras.WatchForPetDeath()
    if not(petFrame) then
      petFrame = CreateFrame("frame");
      petFrame:RegisterUnitEvent("UNIT_HEALTH", "pet");
      petFrame:SetScript("OnEvent", function()
        WeakAuras.StartProfileSystem("generictrigger")
        WeakAuras.ScanEvents("PET_UPDATE");
        WeakAuras.StopProfileSystem("generictrigger")
      end)
    end
  end
end

-- Player Moving
do
  local playerMovingFrame = nil
  WeakAuras.frames["Player Moving Frame"] =  playerMovingFrame;
  local moving;
  function WeakAuras.WatchForPlayerMoving()
    if not(playerMovingFrame) then
      playerMovingFrame = CreateFrame("frame");
      playerMovingFrame:RegisterEvent("PLAYER_STARTED_MOVING");
      playerMovingFrame:RegisterEvent("PLAYER_STOPPED_MOVING");
      playerMovingFrame:SetScript("OnEvent", function(self, event)
        WeakAuras.StartProfileSystem("generictrigger");
        -- channeling e.g. Mind Flay results in lots of PLAYER_STARTED_MOVING, PLAYER_STOPPED_MOVING
        -- for each frame
        -- So check after 0.01 s if IsPlayerMoving() actually returns something different.
        timer:ScheduleTimer(function()
          WeakAuras.StartProfileSystem("generictrigger");
          if (moving ~= IsPlayerMoving() or moving == nil) then
            moving = IsPlayerMoving();
            WeakAuras.ScanEvents("PLAYER_MOVING_UPDATE");
          end
          WeakAuras.StopProfileSystem("generictrigger");
        end, 0.01);
        WeakAuras.StopProfileSystem("generictrigger");
      end)
    end
  end
end

-- Item Count
local itemCountWatchFrame;
function WeakAuras.RegisterItemCountWatch()
  if not(itemCountWatchFrame) then
    itemCountWatchFrame = CreateFrame("frame");
    itemCountWatchFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    itemCountWatchFrame:SetScript("OnEvent", function()
      WeakAuras.StartProfileSystem("generictrigger");
      timer:ScheduleTimer(WeakAuras.ScanEvents, 0.2, "ITEM_COUNT_UPDATE");
      timer:ScheduleTimer(WeakAuras.ScanEvents, 0.5, "ITEM_COUNT_UPDATE");
      WeakAuras.StopProfileSystem("generictrigger");
    end);
  end
end

do
  local scheduled_scans = {};

  local function doCooldownScan(fireTime)
    WeakAuras.debug("Performing cooldown scan at "..fireTime.." ("..GetTime()..")");
    scheduled_scans[fireTime] = nil;
    WeakAuras.ScanEvents("COOLDOWN_REMAINING_CHECK");
  end
  function WeakAuras.ScheduleCooldownScan(fireTime)
    if not(scheduled_scans[fireTime]) then
      WeakAuras.debug("Scheduled cooldown scan at "..fireTime);
      scheduled_scans[fireTime] = timer:ScheduleTimerFixed(doCooldownScan, fireTime - GetTime() + 0.1, fireTime);
    end
  end
end

do
  local scheduled_scans = {};

  local function doCastScan(firetime, unit)
    WeakAuras.debug("Performing cast scan at "..firetime.." ("..GetTime()..")");
    scheduled_scans[firetime] = nil;
    WeakAuras.ScanEvents("CAST_REMAINING_CHECK", unit);
  end
  function WeakAuras.ScheduleCastCheck(fireTime, unit)
    if not(scheduled_scans[fireTime]) then
      WeakAuras.debug("Scheduled cast scan at "..fireTime);
      scheduled_scans[fireTime] = timer:ScheduleTimerFixed(doCastScan, fireTime - GetTime() + 0.1, fireTime, unit);
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

  if(
    (
    (
    trigger.type == "event"
    or trigger.type == "status"
    )
    and (
    (
    trigger.event
    and WeakAuras.event_prototypes[trigger.event]
    and (WeakAuras.event_prototypes[trigger.event].durationFunc
    or WeakAuras.event_prototypes[trigger.event].canHaveDuration)
    )
    or (
    trigger.unevent == "timed"
    and trigger.duration
    )
    )
    and not trigger.use_inverse
    )
    or (
    trigger.type == "custom"
    and (
    (
    trigger.custom_type == "event"
    and trigger.custom_hide == "timed"
    and trigger.duration
    )
    or (
    trigger.customDuration
    and trigger.customDuration ~= ""
    )
    or trigger.custom_type == "stateupdate"
    )
    )
    ) then
    if(
      (
      trigger.type == "event"
      or trigger.type == "status"
      )
      and trigger.event
      and WeakAuras.event_prototypes[trigger.event]
      and WeakAuras.event_prototypes[trigger.event].durationFunc
      ) then
      if(type(WeakAuras.event_prototypes[trigger.event].init) == "function") then
        WeakAuras.event_prototypes[trigger.event].init(trigger);
      end
      local current, maximum, custom = WeakAuras.event_prototypes[trigger.event].durationFunc(trigger);
      current = type(current) ~= "number" and current or 0
      maximum = type(maximum) ~= "number" and maximum or 0
      if(custom) then
        return {current = current, maximum = maximum};
      else
        return "timed";
      end
    elseif trigger.event
      and WeakAuras.event_prototypes[trigger.event]
      and WeakAuras.event_prototypes[trigger.event].canHaveDuration then
      return WeakAuras.event_prototypes[trigger.event].canHaveDuration
    else
      return "timed";
    end
  else
    return false;
  end
end

--- Returns a table containing the names of all overlays
-- @param data
-- @param triggernum
function GenericTrigger.GetOverlayInfo(data, triggernum)
  local result;

  local trigger = data.triggers[triggernum].trigger

  if (trigger.type ~= "custom" and trigger.event and WeakAuras.event_prototypes[trigger.event] and WeakAuras.event_prototypes[trigger.event].overlayFuncs) then
    result = {};
    local dest = 1;
    for i, v in ipairs(WeakAuras.event_prototypes[trigger.event].overlayFuncs) do
      if (v.enable(trigger)) then
        result[dest] = v.name;
        dest = dest + 1;
      end
    end
  end

  if (trigger.type == "custom") then
    if (trigger.custom_type == "stateupdate") then
      local count = 0;
      local variables = events[data.id][triggernum].tsuConditionVariables;
      if (variables) then
        if (type(variables.additionalProgress) == "table") then
          count = #variables.additionalProgress;
        elseif (type(variables.additionalProgress) == "number") then
          count = variables.additionalProgress;
        end
      else
        local allStates = {};
        WeakAuras.ActivateAuraEnvironment(data.id);
        RunTriggerFunc(allStates, events[data.id][triggernum], data.id, triggernum, "OPTIONS");
        WeakAuras.ActivateAuraEnvironment(nil);
        local count = 0;
        for id, state in pairs(allStates) do
          if (state.additionalProgress) then
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

function GenericTrigger.CanHaveAuto(data, triggernum)
  -- Is also called on importing before conversion, so do a few checks
  local trigger = data.triggers[triggernum].trigger

  if (not trigger) then
    return false;
  end
  if(
    (
    (
    trigger.type == "event"
    or trigger.type == "status"
    )
    and trigger.event
    and WeakAuras.event_prototypes[trigger.event]
    and (
    WeakAuras.event_prototypes[trigger.event].iconFunc
    or WeakAuras.event_prototypes[trigger.event].canHaveAuto
    )
    )
    or (
    trigger.type == "custom"
    and ((
    trigger.customIcon
    and trigger.customIcon ~= ""
    ) or trigger.custom_type == "stateupdate")
    )
    ) then
    return true;
  else
    return false;
  end
end

function GenericTrigger.CanHaveClones(data)
  return false;
end

function GenericTrigger.GetNameAndIcon(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local icon, name
  if (trigger.type == "event" or trigger.type == "status") then
    if(trigger.event and WeakAuras.event_prototypes[trigger.event]) then
      if(WeakAuras.event_prototypes[trigger.event].iconFunc) then
        icon = WeakAuras.event_prototypes[trigger.event].iconFunc(trigger);
      end
      if(WeakAuras.event_prototypes[trigger.event].nameFunc) then
        name = WeakAuras.event_prototypes[trigger.event].nameFunc(trigger);
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
  if (trigger.type == "event" or trigger.type == "status") then
    if (trigger.event and WeakAuras.event_prototypes[trigger.event]) then
      if(WeakAuras.event_prototypes[trigger.event].hasSpellID) then
        return "spell";
      elseif(WeakAuras.event_prototypes[trigger.event].hasItemID) then
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
    if (state.spellId) then
      GameTooltip:SetSpellByID(state.spellId);
    elseif (state.itemId) then
      GameTooltip:SetHyperlink("item:"..state.itemId..":0:0:0:0:0:0:0");
    elseif (state.unit and state.unitBuffIndex) then
      GameTooltip:SetUnitBuff(state.unit, state.unitBuffIndex);
    elseif (state.unit and state.unitDebuffIndex) then
      GameTooltip:SetUnitDebuff(state.unit, state.unitDebuffIndex);
    end
  end

  if (trigger.type == "event" or trigger.type == "status") then
    if (trigger.event and WeakAuras.event_prototypes[trigger.event]) then
      if(WeakAuras.event_prototypes[trigger.event].hasSpellID) then
        GameTooltip:SetSpellByID(trigger.spellName);
      elseif(WeakAuras.event_prototypes[trigger.event].hasItemID) then
        GameTooltip:SetHyperlink("item:"..trigger.itemName..":0:0:0:0:0:0:0")
      end
    end
  end
end

function GenericTrigger.GetAdditionalProperties(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local ret = "";
  if (trigger.type == "event" or trigger.type == "status") then
    if (trigger.event and WeakAuras.event_prototypes[trigger.event]) then
      local found = false;
      local additional = "\n\n" .. L["Additional Trigger Replacements"] .. "\n";
      for _, v in pairs(WeakAuras.event_prototypes[trigger.event].args) do
        if (v.store and v.name and v.display) then
          found = true;
          additional = additional .. "|cFFFF0000%" .. v.name .. "|r - " .. v.display .. "\n";
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
  }
}

function GenericTrigger.GetTriggerConditions(data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  if (trigger.type == "event" or trigger.type == "status") then
    if (trigger.event and WeakAuras.event_prototypes[trigger.event]) then
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

      if (WeakAuras.event_prototypes[trigger.event].stacksFunc) then
        result.stacks = commonConditions.stacks;
      end

      for _, v in pairs(WeakAuras.event_prototypes[trigger.event].args) do
        if (v.conditionType and v.name and v.display) then
          local enable = true;
          if (v.enable) then
            enable = v.enable(trigger);
          end

          if (enable) then
            result[v.name] = {
              display = v.display,
              type = v.conditionType
            }
            if (result[v.name].type == "select" or result[v.name].type == "unit") then
              if (v.conditionValues) then
                result[v.name].values = WeakAuras[v.conditionValues];
              else
                result[v.name].values = WeakAuras[v.values];
              end
            end
            if (v.conditionTest) then
              result[v.name].test = v.conditionTest;
            end
            if (v.conditionEvents) then
              result[v.name].events = v.conditionEvents;
            end
            if (v.operator_types_without_equal) then
              result[v.name].operator_types_without_equal = true;
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

      return result;
    elseif (trigger.custom_type == "stateupdate") then
      if (events[data.id][triggernum] and events[data.id][triggernum].tsuConditionVariables) then
        if (type(events[data.id][triggernum].tsuConditionVariables)) ~= "table" then
          return nil;
        end
        local result = CopyTable(events[data.id][triggernum].tsuConditionVariables);
        -- Make the life of tsu authors easier, by automatically filling in the details for
        -- expirationTime, duration, value, total, stacks, if those exists but aren't a table value
        -- By allowing a short-hand notation of just variable = type
        -- In addition to the long form of variable = { type = xyz, display = "desc"}
        if (not result) then
          return nil;
        end

        for k, v in pairs(commonConditions) do
          if (result[k] and type(result[k]) ~= "table") then
            result[k] = v;
          end
        end

        for k, v in pairs(events[data.id][triggernum].tsuConditionVariables) do
          if (type(v) == "string") then
            result[k] = {
              display = k,
              type = v,
            };
          end
        end

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

  WeakAuras.ActivateAuraEnvironment(data.id, "", state);
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
    local ok, stacks = event.stacksFunc(firstTrigger);
    state.stacks = ok and stacks or nil;
  end

  if (event.durationFunc) then
    local ok, arg1, arg2, arg3, inverse = xpcall(event.durationFunc, geterrorhandler(), firstTrigger);
    if (not ok) then
      state.progressType = "timed";
      state.duration = 0;
      state.expirationTime = math.huge;
      state.resort = nil;
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
      state.resort = state.expirationTime ~= nil;
      state.expirationTime = nil;
      state.value = arg1;
      state.total = arg2;
      state.inverse = inverse;
    else
      state.progressType = "timed";
      state.duration = arg1;
      state.resort = state.expirationTime ~= arg2;
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
    state.resort = nil;
    state.value = nil;
    state.total = nil;
  end
  if (event.overlayFuncs) then
    RunOverlayFuncs(event, state);
  end
  WeakAuras.ActivateAuraEnvironment(nil);
end

function GenericTrigger.GetName(triggerType)
  if (triggerType == "status") then
    return L["Status"];
  end
  if (triggerType == "event") then
    return L["Event"];
  end
  if (triggerType == "custom") then
    return L["Custom"];
  end
end

function GenericTrigger.GetTriggerDescription(data, triggernum, namestable)
  local trigger = data.triggers[triggernum].trigger
  if(trigger.type == "event" or trigger.type == "status") then
    if(trigger.type == "event") then
      tinsert(namestable, {L["Trigger:"], (WeakAuras.event_types[trigger.event] or L["Undefined"])});
    else
      tinsert(namestable, {L["Trigger:"], (WeakAuras.status_types[trigger.event] or L["Undefined"])});
    end
    if(trigger.event == "Combat Log" and trigger.subeventPrefix and trigger.subeventSuffix) then
      tinsert(namestable, {L["Message type:"], (WeakAuras.subevent_prefix_types[trigger.subeventPrefix] or L["Undefined"]).." "..(WeakAuras.subevent_suffix_types[trigger.subeventSuffix] or L["Undefined"])});
    end
  else
    tinsert(namestable, {L["Trigger:"], L["Custom"]});
  end
end

WeakAuras.RegisterTriggerSystem({"event", "status", "custom"}, GenericTrigger);
