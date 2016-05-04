--[[ GenericTrigger.lua
This file contains the generic trigger system. That is every trigger except the aura triggers

It registers the GenericTrigger table for the trigger types "status", "event" and "custom".
The GenericTrigger has the following API:

Add(data)
  Adds a display, creating all internal data structures for all triggers

Delete(id)
  Deletes all triggers for display id

Rename(oldid, newid)
  Updates all trigger information from oldid to newid

LoadDisplay(id)
  Loads all triggers of display id

UnloadAll
  Unloads all triggers

UnloadDisplay(id)
  Unloads all triggers of the display id

ScanAll
  Resets the trigger state for all triggers

Modernize(data)
  Modernizes all generic triggers in data

#####################################################
# Helper functions mainly for the WeakAuras Options #
#####################################################

CanGroupShowWithZero(data)
  Returns whether the first trigger could be shown without any affected group members.
  If that is the case no automatic icon can be determined. Only used by the Options dialog.
  (If I understood the code correctly)

CanHaveDuration(data)
  Returns whether the trigger can have a duration

CanHaveAuto(data)
  Returns whether the icon can be automatically selected

CanHaveClones(data)
  Returns whether the trigger can have clones

CanHaveTooltip(data)
  Returns the type of tooltip to show for the trigger

GetNameAndIcon(data)
    Returns the name and icon to show in the options

]]--


-- Lua APIs
local tinsert, tconcat, wipe = table.insert, table.concat, wipe
local tostring, select, pairs, type = tostring, select, pairs, type
local error, setmetatable = error, setmetatable

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
local timers = WeakAuras.timers;
local regions = WeakAuras.regions;
local clones = WeakAuras.clones;
local specificBosses = WeakAuras.specificBosses;

-- local function
local LoadEvent, HandleEvent, TestForTriState, TestForToggle, TestForLongString, TestForMultiSelect
local ConstructTest, ConstructFunction

-- GLOBALS: WeakAurasAceEvents GameTooltip GTFO DBM BigWigsLoader

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
  if(trigger["use_"..name] == false) then -- Multiselection
    test = "(";
    local any = false;
    for value, _ in pairs(trigger[name].multi) do
      if not arg.test then
        test = test..name.."=="..(tonumber(value) or "\""..value.."\"").." or ";
      else
        test = test..arg.test:format(tonumber(value) or "\""..value.."\"").." or ";
      end
      any = true;
    end
    if(any) then
      test = test:sub(0, -5);
    else
      test = "(false";
    end
    test = test..")";
  elseif(trigger["use_"..name]) then -- Singleselection
    local value = trigger[name].single;
    if not arg.test then
      test = trigger[name].single and "("..name.."=="..(tonumber(value) or "\""..value.."\"")..")";
    else
      test = trigger[name].single and "("..arg.test:format(tonumber(value) or "\""..value.."\"")..")";
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
    else
      if(type(trigger[name]) == "table") then
        trigger[name] = "error";
      end
      -- if arg.type == "number" and (trigger[name]) and not number then trigger[name] = 0 number = 0 end -- fix corrupt data, ticket #366
      test = "(".. name .." and "..name..(trigger[name.."_operator"] or "==")..(number or "\""..(trigger[name] or "").."\"")..")";
    end
  end
  return test;
end

function ConstructFunction(prototype, trigger, inverse)
  local input = {"event"};
  local required = {};
  local tests = {};
  local debug = {};
  local init;
  if(prototype.init) then
    init = prototype.init(trigger);
  else
    init = "";
  end
  for index, arg in pairs(prototype.args) do
    local enable = true;
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
  ret = ret.."return true else return false end end";

  -- print(ret);

  return ret;
end

function WeakAuras.EndEvent(id, triggernum, force)
  local data = events[id] and events[id][triggernum];
  if(data) then
    data.region:DisableTrigger(triggernum);
    if(timers[id] and timers[id][triggernum]) then
      timer:CancelTimer(timers[id][triggernum].handle, true);
      timers[id][triggernum] = nil;
    end
  end
  if not(force) then
    WeakAuras.SetEventDynamics(id, triggernum, data, true);
  end
end

function WeakAuras.ActivateEvent(id, triggernum, data)
  WeakAuras.SetEventDynamics(id, triggernum, data);
  data.region:EnableTrigger(triggernum);
end

function WeakAuras.ScanEvents(event, arg1, arg2, ...)
  local event_list = loaded_events[event];
  if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
    event_list = event_list and event_list[arg2];
  end
  if(event_list) then
  -- This reverts the COMBAT_LOG_EVENT_UNFILTERED_CUSTOM workaround so that custom triggers that check the event argument will work as expected
    if(event == "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM") then
      event = "COMBAT_LOG_EVENT_UNFILTERED";
    end
    for id, triggers in pairs(event_list) do
      WeakAuras.ActivateAuraEnvironment(id);
      for triggernum, data in pairs(triggers) do
        if(data.triggerFunc) then
          if(data.triggerFunc(event, arg1, arg2, ...)) then
            WeakAuras.ActivateEvent(id, triggernum, data);
          else
            if(data.untriggerFunc and data.untriggerFunc(event, arg1, arg2, ...)) then
              WeakAuras.EndEvent(id, triggernum);
            end
          end
        end
      end
      WeakAuras.ActivateAuraEnvironment(nil);
    end
  end
end

function GenericTrigger.ScanAll()
  for event, v in pairs(WeakAuras.forceable_events) do
    if(type(v) == "table") then
      for index, arg1 in pairs(v) do
      WeakAuras.ScanEvents(event, arg1);
      end
    elseif(event == "SPELL_COOLDOWN_FORCE") then
      WeakAuras.SpellCooldownForce();
    elseif(event == "ITEM_COOLDOWN_FORCE") then
      WeakAuras.ItemCooldownForce();
    elseif(event == "RUNE_COOLDOWN_FORCE") then
      WeakAuras.RuneCooldownForce();
    else
      WeakAuras.ScanEvents(event);
    end
  end
end

function HandleEvent(frame, event, arg1, arg2, ...)
  if not(WeakAuras.IsPaused()) then
    if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
      if(loaded_events[event] and loaded_events[event][arg2]) then
        WeakAuras.ScanEvents(event, arg1, arg2, ...);
      end
      -- This is triggers the scanning of "hacked" COMBAT_LOG_EVENT_UNFILTERED events that were renamed in order to circumvent
      -- the "proper" COMBAT_LOG_EVENT_UNFILTERED checks
      if(loaded_events["COMBAT_LOG_EVENT_UNFILTERED_CUSTOM"]) then
        WeakAuras.ScanEvents("COMBAT_LOG_EVENT_UNFILTERED_CUSTOM", arg1, arg2, ...);
      end
    else
      if(loaded_events[event]) then
        WeakAuras.ScanEvents(event, arg1, arg2, ...);
      end
    end
  end
  if (event == "PLAYER_ENTERING_WORLD") then
    timer:ScheduleTimer(function()
         HandleEvent(frame, "WA_DELAYED_PLAYER_ENTERING_WORLD");
         WeakAuras.CheckCooldownReady();
       end,
       0.5);  -- Data not available
  end
end

function GenericTrigger.UnloadAll()
  wipe(loaded_events);
end

function GenericTrigger.UnloadDisplay(id)
  for eventname, events in pairs(loaded_events) do
    if(eventname == "COMBAT_LOG_EVENT_UNFILTERED") then
      for subeventname, subevents in pairs(events) do
        subevents[id] = nil;
      end
    else
      events[id] = nil;
    end
  end
end

local frame = CreateFrame("FRAME");
WeakAuras.frames["WeakAuras Generic Trigger Frame"] = frame;
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:SetScript("OnEvent", HandleEvent);

function GenericTrigger.Delete(id)
  WeakAuras.EndEvent(id, 0, true);
  GenericTrigger.UnloadDisplay(id);
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
end

function GenericTrigger.LoadDisplay(id)
  if(events[id]) then
    for triggernum, data in pairs(events[id]) do
      if(events[id] and events[id][triggernum]) then
        LoadEvent(id, triggernum, data);
      end
    end
  end
end

function GenericTrigger.Add(data, region)
  local id = data.id;
  events[id] = nil;

  local register_for_frame_updates = false;

  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
      data.untrigger = data.untrigger or {};
      untrigger = data.untrigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
      data.additional_triggers[triggernum].untrigger = data.additional_triggers[triggernum].untrigger or {};
      untrigger = data.additional_triggers[triggernum].untrigger;
    end
    local triggerType;
    if(trigger and type(trigger) == "table") then
      triggerType = trigger.type;
      if(triggerType == "status" or triggerType == "event" or triggerType == "custom") then
        local triggerFuncStr, triggerFunc, untriggerFuncStr, untriggerFunc;
        local trigger_events = {};
        local durationFunc, nameFunc, iconFunc, textureFunc, stacksFunc;
        if(triggerType == "status" or triggerType == "event") then
          if not(trigger.event) then
            error("Improper arguments to WeakAuras.Add - trigger type is \"event\" but event is not defined");
          elseif not(event_prototypes[trigger.event]) then
            if(event_prototypes["Health"]) then
              trigger.event = "Health";
            else
              error("Improper arguments to WeakAuras.Add - no event prototype can be found for event type \""..trigger.event.."\" and default prototype reset failed.");
            end
          elseif(trigger.event == "Combat Log" and not (trigger.subeventPrefix..trigger.subeventSuffix)) then
            error("Improper arguments to WeakAuras.Add - event type is \"Combat Log\" but subevent is not defined");
          else
            triggerFuncStr = ConstructFunction(event_prototypes[trigger.event], trigger);
            WeakAuras.debug(id.." - "..triggernum.." - Trigger", 1);
            WeakAuras.debug(triggerFuncStr);
            triggerFunc = WeakAuras.LoadFunction(triggerFuncStr);

            durationFunc = event_prototypes[trigger.event].durationFunc;
            nameFunc = event_prototypes[trigger.event].nameFunc;
            iconFunc = event_prototypes[trigger.event].iconFunc;
            textureFunc = event_prototypes[trigger.event].textureFunc;
            stacksFunc = event_prototypes[trigger.event].stacksFunc;

            trigger.unevent = trigger.unevent or "auto";

            if(trigger.unevent == "custom") then
              untriggerFuncStr = ConstructFunction(event_prototypes[trigger.event], untrigger);
            elseif(trigger.unevent == "auto") then
              untriggerFuncStr = ConstructFunction(event_prototypes[trigger.event], trigger, true);
            end

            if(untriggerFuncStr) then
              WeakAuras.debug(id.." - "..triggernum.." - Untrigger", 1)
              WeakAuras.debug(untriggerFuncStr);
              untriggerFunc = WeakAuras.LoadFunction(untriggerFuncStr);
            end

            local prototype = event_prototypes[trigger.event];
            if(prototype) then
              trigger_events = prototype.events;
              for index, event in ipairs(trigger_events) do
                frame:RegisterEvent(event);
                -- WeakAuras.cbh.RegisterCallback(WeakAuras.cbh.events, event)
                aceEvents:RegisterMessage(event, HandleEvent, frame)
                if(type(prototype.force_events) == "boolean" or type(prototype.force_events) == "table") then
                  WeakAuras.forceable_events[event] = prototype.force_events;
                end
              end
              if(type(prototype.force_events) == "string") then
                WeakAuras.forceable_events[prototype.force_events] = true;
              end
            end
          end
        else
          triggerFunc = WeakAuras.LoadFunction("return "..(trigger.custom or ""));
          if(trigger.custom_type == "status" or trigger.custom_hide == "custom") then
            untriggerFunc = WeakAuras.LoadFunction("return "..(untrigger.custom or ""));
          end

          if(trigger.customDuration and trigger.customDuration ~= "") then
            durationFunc = WeakAuras.LoadFunction("return "..trigger.customDuration);
          end
          if(trigger.customName and trigger.customName ~= "") then
            nameFunc = WeakAuras.LoadFunction("return "..trigger.customName);
          end
          if(trigger.customIcon and trigger.customIcon ~= "") then
            iconFunc = WeakAuras.LoadFunction("return "..trigger.customIcon);
          end
          if(trigger.customTexture and trigger.customTexture ~= "") then
            textureFunc = WeakAuras.LoadFunction("return "..trigger.customTexture);
          end
          if(trigger.customStacks and trigger.customStacks ~= "") then
            stacksFunc = WeakAuras.LoadFunction("return "..trigger.customStacks);
          end

          if(trigger.custom_type == "status" and trigger.check == "update") then
            register_for_frame_updates = true;
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
                frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
              else
                frame:RegisterEvent(event);
                -- WeakAuras.cbh.RegisterCallback(WeakAuras.cbh.events, event)
                aceEvents:RegisterMessage(event, HandleEvent, frame)
              end
              if(trigger.custom_type == "status") then
                WeakAuras.forceable_events[event] = true;
              end
            end
          end
        end

        events[id] = events[id] or {};
        events[id][triggernum] = {
          trigger = trigger,
          triggerFunc = triggerFunc,
          untriggerFunc = untriggerFunc,
          event = trigger.event,
          events = trigger_events,
          inverse = trigger.use_inverse,
          subevent = trigger.event == "Combat Log" and trigger.subeventPrefix and trigger.subeventSuffix and (trigger.subeventPrefix..trigger.subeventSuffix);
          unevent = trigger.unevent,
          durationFunc = durationFunc,
          nameFunc = nameFunc,
          iconFunc = iconFunc,
          textureFunc = textureFunc,
          stacksFunc = stacksFunc,
          region = region,
          numAdditionalTriggers = data.additional_triggers and #data.additional_triggers or 0
        };

        if(
        (
          (
          triggerType == "status"
          or triggerType == "event"
          )
          and trigger.unevent == "timed"
        )
        or (
          triggerType == "custom"
          and trigger.custom_type == "event"
          and trigger.custom_hide == "timed"
        )
        ) then
          events[id][triggernum].duration = tonumber(trigger.duration);
        end
      end
    end
  end

  if(register_for_frame_updates) then
    WeakAuras.RegisterEveryFrameUpdate(id);
  else
    WeakAuras.UnregisterEveryFrameUpdate(id);
  end
end

do
  local update_clients = {};
  local update_clients_num = 0;
  local update_frame;
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
end

function GenericTrigger.Modernize(data)
  -- Convert any references to "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM" to "COMBAT_LOG_EVENT_UNFILTERED"
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end
    if(trigger and trigger.custom) then
      trigger.custom = trigger.custom:gsub("COMBAT_LOG_EVENT_UNFILTERED_CUSTOM", "COMBAT_LOG_EVENT_UNFILTERED");
    end
    if(untrigger and untrigger.custom) then
      untrigger.custom = untrigger.custom:gsub("COMBAT_LOG_EVENT_UNFILTERED_CUSTOM", "COMBAT_LOG_EVENT_UNFILTERED");
    end
  end

  -- Rename ["event"] = "Cooldown (Spell)" to ["event"] = "Cooldown Progress (Spell)"
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;

    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end

    if trigger and trigger["event"] and trigger["event"] == "Cooldown (Spell)" then
      trigger["event"] = "Cooldown Progress (Spell)";
    end

    if trigger and trigger["event"] and trigger["event"] == "DBM Timer" then
      if (type(trigger.spellId) == "number") then
        trigger.spellId = tostring(trigger.spellId);
      end
    end
  end

  -- Add status/event information to triggers
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
      untrigger = data.untrigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
      untrigger = data.additional_triggers[triggernum].untrigger;
    end
    -- Add status/event information to triggers
    if(trigger and trigger.event and (trigger.type == "status" or trigger.type == "event")) then
      local prototype = event_prototypes[trigger.event];
      if(prototype) then
        trigger.type = prototype.type;
      end
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
              or trigger.event == "Cooldown Progress (Item)")) then
        if (not trigger.showOn) then
            if (trigger.use_inverse) then
                trigger.showOn = "showOnReady"
            else
                trigger.showOn = "showOnCooldown"
            end
            trigger.use_inverse = nil
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

  if (DBM and DBM.Revision >= 14433) then
    -- Revisions before 14433 had a different callback api
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

-- Swing Timer Support code
do
  local mh = GetInventorySlotInfo("MainHandSlot")
  local oh = GetInventorySlotInfo("SecondaryHandSlot")

  local swingTimerFrame;
  local lastSwingMain, lastSwingOff, lastSwingRange;
  local swingDurationMain, swingDurationOff, swingDurationRange;
  local mainTimer, offTimer, rangeTimer;

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

  local function swingTimerCheck(frame, event, _, message, _, _, source)
    if(UnitIsUnit(source or "", "player")) then
      if(message == "SWING_DAMAGE" or message == "SWING_MISSED") then
        local event;
        local currentTime = GetTime();
        local mainSpeed, offSpeed = UnitAttackSpeed("player");
        offSpeed = offSpeed or 0;
        if not(lastSwingMain) then
          lastSwingMain = currentTime;
          swingDurationMain = mainSpeed;
          event = "SWING_TIMER_START";
          mainTimer = timer:ScheduleTimer(swingEnd, mainSpeed, "main");
        elseif(OffhandHasWeapon() and not lastSwingOff) then
          lastSwingOff = currentTime;
          swingDurationOff = offSpeed;
          event = "SWING_TIMER_START";
          offTimer = timer:ScheduleTimer(swingEnd, offSpeed, "off");
        else
          -- A swing occurred while both weapons are supposed to be on cooldown
          -- Simply refresh the timer of the weapon swing which would have ended sooner
          local mainRem, offRem = (lastSwingMain or math.huge) + mainSpeed - currentTime, (lastSwingOff or math.huge) + offSpeed - currentTime;
          if(mainRem < offRem or not OffhandHasWeapon()) then
            timer:CancelTimer(mainTimer, true);
            lastSwingMain = currentTime;
            swingDurationMain = mainSpeed;
            event = "SWING_TIMER_CHANGE";
            mainTimer = timer:ScheduleTimer(swingEnd, mainSpeed, "main");
          else
            timer:CancelTimer(mainTimer, true);
            lastSwingOff = currentTime;
            swingDurationOff = offSpeed;
            event = "SWING_TIMER_CHANGE";
            offTimer = timer:ScheduleTimer(swingEnd, offSpeed, "off");
          end
        end

        WeakAuras.ScanEvents(event);
      elseif(message == "RANGE_DAMAGE" or message == "RANGE_MISSED") then
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
        rangeTimer = timer:ScheduleTimer(swingEnd, speed, "range");

        WeakAuras.ScanEvents(event);
      end
    end
  end

  function WeakAuras.InitSwingTimer()
    if not(swingTimerFrame) then
      swingTimerFrame = CreateFrame("frame");
      swingTimerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
      swingTimerFrame:SetScript("OnEvent", swingTimerCheck);
    end
  end
end

-- CD/Rune/GCD Support Code
do
  local cdReadyFrame;
  WeakAuras.frames["Cooldown Trigger Handler"] = cdReadyFrame

  local spells = {};
  local spellsRune = {}
  local spellCdDurs = {};
  local spellCdExps = {};
  local spellCdDursRune = {};
  local spellCdExpsRune = {};
  local spellCharges = {};
  local spellCdHandles = {};

  local items = {};
  local itemCdDurs = {};
  local itemCdExps = {};
  local itemCdHandles = {};

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
  cdReadyFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
  cdReadyFrame:RegisterEvent("RUNE_POWER_UPDATE");
  cdReadyFrame:RegisterEvent("RUNE_TYPE_UPDATE");
  cdReadyFrame:SetScript("OnEvent", function(self, event, ...)
    if(event == "SPELL_UPDATE_COOLDOWN" or event == "RUNE_POWER_UPDATE" or event == "RUNE_TYPE_UPDATE") then
    WeakAuras.CheckCooldownReady();
    elseif(event == "UNIT_SPELLCAST_SENT") then
      local unit, name = ...;
      if(unit == "player") then
        if(gcdSpellName ~= name) then
          local icon = GetSpellTexture(name);
          gcdSpellName = name;
          gcdSpellIcon = icon;
        end
      end
    end
  end);
  end

  function WeakAuras.GetRuneCooldown(id)
    if(runes[id] and runeCdExps[id] and runeCdDurs[id]) then
      return runeCdExps[id] - runeCdDurs[id], runeCdDurs[id];
    else
      return 0, 0;
    end
  end

  function WeakAuras.GetSpellCooldown(id, ignoreRuneCD)
    if (ignoreRuneCD) then
      if (spellsRune[id] and spellCdExpsRune[id] and spellCdDursRune[id]) then
        return spellCdExpsRune[id] - spellCdDursRune[id], spellCdDursRune[id];
      else
        return 0, 0
      end
    end

    if(spells[id] and spellCdExps[id] and spellCdDurs[id]) then
      return spellCdExps[id] - spellCdDurs[id], spellCdDurs[id];
    else
      return 0, 0;
    end
  end

  function WeakAuras.GetSpellCharges(id)
    return spellCharges[id];
  end

  function WeakAuras.GetItemCooldown(id)
    if(items[id] and itemCdExps[id] and itemCdDurs[id]) then
      return itemCdExps[id] - itemCdDurs[id], itemCdDurs[id];
    else
      return 0, 0;
    end
  end

  function WeakAuras.GetGCDInfo()
    if(gcdStart) then
      return gcdDuration, gcdStart + gcdDuration, gcdSpellName or "Invalid", gcdSpellIcon or "Interface\\Icons\\INV_Misc_QuestionMark";
    else
      return 0, math.huge, gcdSpellName or "Invalid", gcdSpellIcon or "Interface\\Icons\\INV_Misc_QuestionMark";
    end
  end

  local function RuneCooldownFinished(id)
    runeCdHandles[id] = nil;
    runeCdDurs[id] = nil;
    runeCdExps[id] = nil;
    WeakAuras.ScanEvents("RUNE_COOLDOWN_READY", id);
  end

  local function SpellCooldownFinished(id)
    spellCdHandles[id] = nil;
    spellCdDurs[id] = nil;
    spellCdExps[id] = nil;
    spellCdDursRune[id] = nil;
    spellCdExpsRune[id] = nil;
    spellCharges[id] = select(2, GetSpellCharges(id));
    WeakAuras.ScanEvents("SPELL_COOLDOWN_READY", id, nil);
  end

  local function ItemCooldownFinished(id)
    itemCdHandles[id] = nil;
    itemCdDurs[id] = nil;
    itemCdExps[id] = nil;
    WeakAuras.ScanEvents("ITEM_COOLDOWN_READY", id);
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
        timer:ScheduleTimer(CheckGCD, duration + 0.1);
      end
    else
      if(gcdStart) then
        event = "GCD_END"
      end
      gcdStart, gcdDuration = nil, nil;
      gcdEndCheck = 0;
    end
    if(event) then
      WeakAuras.ScanEvents(event);
    end
  end

  function WeakAuras.CheckCooldownReady()
    if(gcdReference) then
      CheckGCD();
    end

    for id, _ in pairs(runes) do
      local startTime, duration = GetRuneCooldown(id);
      startTime = startTime or 0;
      duration = duration or 0;
      local time = GetTime();

      if(not startTime or startTime == 0) then
        startTime = 0
        duration = 0
      end

      if(startTime > 0 and duration > 1.51) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(runeCdExps[id]) then
          -- New cooldown
          runeCdDurs[id] = duration;
          runeCdExps[id] = endTime;
          runeCdHandles[id] = timer:ScheduleTimer(RuneCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("RUNE_COOLDOWN_STARTED", id);
        elseif(runeCdExps[id] ~= endTime) then
          -- Cooldown is now different
          if(runeCdHandles[id]) then
            timer:CancelTimer(runeCdHandles[id]);
          end
          runeCdDurs[id] = duration;
          runeCdExps[id] = endTime;
          runeCdHandles[id] = timer:ScheduleTimer(RuneCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("RUNE_COOLDOWN_CHANGED", id);
        end
      elseif(startTime > 0 and duration > 0) then
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

    for id, _ in pairs(spells) do
      local charges, maxCharges, startTime, duration = GetSpellCharges(id);
      if (charges == nil) then -- charges is nil if the spell has no charges
        startTime, duration = GetSpellCooldown(id);
      elseif (charges == maxCharges) then
        startTime, duration = 0, 0;
      end
      startTime = startTime or 0;
      duration = duration or 0;
      local time = GetTime();
      local remaining = startTime + duration - time;

      local chargesChanged = spellCharges[id] ~= charges;
      spellCharges[id] = charges;

      if(duration > 1.51) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(spellCdExps[id]) then
          -- New cooldown
          spellCdDurs[id] = duration;
          spellCdExps[id] = endTime;
          spellCdHandles[id] = timer:ScheduleTimer(SpellCooldownFinished, endTime - time, id);
          if (spellsRune[id] and duration ~= 10) then
            spellCdDursRune[id] = duration;
            spellCdExpsRune[id] = endTime;
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
            spellCdHandles[id] = timer:ScheduleTimer(SpellCooldownFinished, endTime - time, id);
          end
          if (spellsRune[id] and duration ~= 10) then
            spellCdDursRune[id] = duration;
            spellCdExpsRune[id] = endTime;
          end
          WeakAuras.ScanEvents("SPELL_COOLDOWN_CHANGED", id);
        end
      elseif(duration > 0 and not (spellCdExps[id] and spellCdExps[id] - time > 1.51)) then
        -- GCD, do nothing
      else
        if(spellCdExps[id]) then
          -- Somehow CheckCooldownReady caught the spell cooldown before the timer callback
          -- This shouldn't happen, but if it does, no problem
          if(spellCdHandles[id]) then
            timer:CancelTimer(spellCdHandles[id]);
          end
          SpellCooldownFinished(id);
        end
      end
    end

    for id, _ in pairs(items) do
      local startTime, duration = GetItemCooldown(id);
      startTime = startTime or 0;
      duration = duration or 0;
      local time = GetTime();

      if(duration > 1.51) then
        -- On non-GCD cooldown
        local endTime = startTime + duration;

        if not(itemCdExps[id]) then
          -- New cooldown
          itemCdDurs[id] = duration;
          itemCdExps[id] = endTime;
          itemCdHandles[id] = timer:ScheduleTimer(ItemCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("ITEM_COOLDOWN_STARTED", id);
        elseif(itemCdExps[id] ~= endTime) then
          -- Cooldown is now different
          if(itemCdHandles[id]) then
            timer:CancelTimer(itemCdHandles[id]);
          end
          itemCdDurs[id] = duration;
          itemCdExps[id] = endTime;
          itemCdHandles[id] = timer:ScheduleTimer(ItemCooldownFinished, endTime - time, id);
          WeakAuras.ScanEvents("ITEM_COOLDOWN_CHANGED", id);
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
        end
      end
    end
  end

  function WeakAuras.WatchGCD()
    if not(cdReadyFrame) then
      WeakAuras.InitCooldownReady();
    end
    cdReadyFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    cdReadyFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
    gcdReference = true;
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

      if(startTime and duration and startTime > 0 and duration > 1.51) then
        local time = GetTime();
        local endTime = startTime + duration;
        runeCdDurs[id] = duration;
        runeCdExps[id] = endTime;
        if not(runeCdHandles[id]) then
          runeCdHandles[id] = timer:ScheduleTimer(RuneCooldownFinished, endTime - time, id);
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
    end

    if not(spells[id]) then
      spells[id] = true;
      local charges, maxCharges, startTime, duration = GetSpellCharges(id);
      if (charges == nil) then
          startTime, duration = GetSpellCooldown(id);
      elseif (charges == maxCharges) then
          startTime, duration = 0, 0;
      end
      startTime = startTime or 0;
      duration = duration or 0;

      spellCharges[id] = charges;

      if(duration > 1.51) then
        local time = GetTime();
        local endTime = startTime + duration;
        spellCdDurs[id] = duration;
        spellCdExps[id] = endTime;
        if (duration ~= 10 and ignoreRunes) then
          spellCdDursRune[id] = duration;
          spellCdExpsRune[id] = endTime;
        end
        if not(spellCdHandles[id]) then
          spellCdHandles[id] = timer:ScheduleTimer(SpellCooldownFinished, endTime - time, id);
        end
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
      local startTime, duration = GetItemCooldown(id);
      if(startTime and duration and duration > 1.51) then
        local time = GetTime();
        local endTime = startTime + duration;
        itemCdDurs[id] = duration;
        itemCdExps[id] = endTime;
        if not(itemCdHandles[id]) then
          itemCdHandles[id] = timer:ScheduleTimer(ItemCooldownFinished, endTime - time, id);
        end
      end
    end
  end

  function WeakAuras.RuneCooldownForce()
    WeakAuras.ScanEvents("COOLDOWN_REMAINING_CHECK");
  end

  function WeakAuras.SpellCooldownForce()
    WeakAuras.ScanEvents("COOLDOWN_REMAINING_CHECK");
  end

  function WeakAuras.ItemCooldownForce()
    WeakAuras.ScanEvents("COOLDOWN_REMAINING_CHECK");
  end
end

function WeakAuras.GetEquipmentSetInfo(itemSetName, partial)
  local bestMatchNumItems = 0;
  local bestMatchNumEquipped = 0;
  local bestMatchName = nil;
  local bestMatchIcon = nil;

  for i = 1, GetNumEquipmentSets() do
    local name, icon, _, _, numItems, numEquipped = GetEquipmentSetInfo(i);
    if (itemSetName == nil or (name and itemSetName == name)) then
      local match = (not partial and numItems == numEquipped)
                    or (partial and numEquipped > bestMatchNumEquipped);
      if (match) then
         bestMatchNumEquipped = numEquipped;
         bestMatchNumItems = numItems;
         bestMatchName = name;
         bestMatchIcon = icon;
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
    --print ("dbmRecheckTimers");
    local now = GetTime();
    local sendUpdate = false; -- Do we have a expired timer?
    nextExpire = nil;
    local nextMsg = nil;
    local toRemove = {}
    for k, v in pairs(bars) do
      if (v.expirationTime < now) then
        sendUpdate = true;
        --print ("  Removing:", k, v.message);
        bars[k] = nil;
      elseif (nextExpire == nil) then
        nextExpire = v.expirationTime;
        nextMsg = v.message;
      elseif (v.expirationTime < nextExpire) then
        nextExpire = v.expirationTime;
        nextMsg = v.message;
      end
    end

    --print ("  nextExpire", nextExpire and nextExpire - now, nextMsg, "  sendUpdate", sendUpdate);

    if (nextExpire) then
      recheckTimer = timer:ScheduleTimer(dbmRecheckTimers, nextExpire - now);
    end
    if (sendUpdate) then
      WeakAuras.ScanEvents("DBM_TimerUpdate");
    end
  end

  local function dbmEventCallback(event, ...)
    -- print ("dbmEventCallback", event, ...);
    if (event == "DBM_TimerStart") then
      local id, msg, duration, icon, timerType, spellId, colorId = ...;
      local now = GetTime();
      local expiring = now + duration;
      -- print ("  Adding timer, ID:", id, "MSG:", msg, "TimerStr", timerStr, duration)
      bars[id] = timers[id] or {}
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
        recheckTimer = timer:ScheduleTimer(dbmRecheckTimers, expiring - now);
        -- print ("  Scheduling timer for", expiring - now, msg);
      elseif (expiring < nextExpire) then
        nextExpire = expiring;
        timer:CancelTimer(recheckTimer);
        recheckTimer = timer:ScheduleTimer(dbmRecheckTimers, expiring - now, msg);
        -- print ("  Scheduling timer for", expiring - now);
      end
      WeakAuras.ScanEvents("DBM_TimerUpdate");
    elseif (event == "DBM_TimerStop") then
      local id = ...;
      -- print ("  Removing timer with ID:", id);
      bars[id] = nil;
      WeakAuras.ScanEvents("DBM_TimerUpdate");
    elseif (event == "kill" or event == "wipe") then
      -- print("  Wipe or kill, removing all timers")
      bars = {};
      WeakAuras.ScanEvents("DBM_TimerUpdate");
    else -- DBM_Announce
      WeakAuras.ScanEvents(event, ...);
    end
  end

  function WeakAuras.GetDBMTimer(id, message, operator, spellId)
    --print ("WeakAuras.GetDBMTimers", id, message, operator)
    local duration, expirationTime, icon;
    for k, v in pairs(bars) do
      local found = true;
      if (id and id ~= k) then
       found = false;
      end
      if (found and spellId and spellId ~= v.spellId) then
        found = false;
      end
      if (found and message and operator) then
        if(operator == "==") then
          if (v.message ~= message) then
            found = false;
          end
        elseif (operator == "find('%s')") then
          if (v.message == nil or not v.message:find(message)) then
            found = false;
         end
        elseif (operator == "match('%s')") then
          if (v.message == nil or not v.message:match(message)) then
            found = false;
          end
        end
      end
      if (found and (expirationTime == nil or v.expirationTime < expirationTime)) then
        -- print ("  using", v.message);
        expirationTime, duration, icon = v.expirationTime, v.duration, v.icon;
      end
    end
    return duration or 0, expirationTime or 0, icon;
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
      scheduled_scans[fireTime] = timer:ScheduleTimer(doDbmScan, fireTime - GetTime() + 0.1, fireTime);
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
    -- print (" bigWigs recheckTimers");
    local now = GetTime();
    local sendUpdate = false; -- Do we have a expired timer?
    nextExpire = nil;
    local nextMsg = nil;
    for i = #bars, 1, -1 do
      local v = bars[i]
      if (v.expirationTime < now) then
        sendUpdate = true;
        -- print ("  Removing:", v.text);
        tremove(bars, i);
      elseif (nextExpire == nil) then
        nextExpire = v.expirationTime;
        nextMsg = v.text;
      elseif (v.expirationTime < nextExpire) then
        nextExpire = v.expirationTime;
        nextMsg = v.text;
      end
    end

    -- print ("  nextExpire", nextExpire and nextExpire - now, nextMsg, "  sendUpdate", sendUpdate);

    if (nextExpire) then
      recheckTimer = timer:ScheduleTimer(recheckTimers, nextExpire - now);
    end
    if (sendUpdate) then
      WeakAuras.ScanEvents("BigWigs_Timer_Update");
    end
  end

  local function bigWigsEventCallback(event, ...)
    -- print (event, ...)
    if (event == "BigWigs_Message") then
      WeakAuras.ScanEvents("BigWigs_Message", ...);
    elseif (event == "BigWigs_StartBar") then
      local addon, spellId, text, duration, icon = ...
      local now = GetTime();
      local expirationTime = now + duration;

    local found = false;
    for k, bar in pairs(bars) do
        if (bar.addon == addon and bar.spellId == spellId and bar.text == text) then
        bar.duration = duration;
        bar.expirationTime = expirationTime;
        bar.icon = icon;
        found = true;
        break;
        end
    end

    if (not found) then
        tinsert(bars, {
                       addon = addon,
                       spellId = spellId,
                       text = text,
                       duration = duration,
                       expirationTime = expirationTime,
                       icon = icon
                      });
    end
      WeakAuras.ScanEvents("BigWigs_Timer_Update");
      if (nextExpire == nil) then
        recheckTimer = timer:ScheduleTimer(recheckTimers, expirationTime - now);
        nextExpire = expirationTime;
      elseif (expirationTime < nextExpire) then
        timer:CancelTimer(recheckTimer);
        recheckTimer = timer:ScheduleTimer(recheckTimers, expirationTime - now);
        nextExpire = expirationTime;
      end
    elseif (event == "BigWigs_StopBar") then
      local addon, text = ...
      for i = #bars, 1, -1 do
        if (bars[i].addon == addon and bars[i].text == text) then
          tremove(bars, i);
        end
      end
      WeakAuras.ScanEvents("BigWigs_Timer_Update");
    elseif (event == "BigWigs_StopBars"
            or event == "BigWigs_OnBossDisable"
            or event == "BigWigs_OnPluginDisable") then
      local addon = ...
      for i = #bars, 1, -1 do
        if (bars[i].addon == addon) then
          tremove(bars, i);
        end
      end
      WeakAuras.ScanEvents("BigWigs_Timer_Update");
    end
  end

  function WeakAuras.RegisterBigWigsCallback(event)
    if (registeredBigWigsEvents [event]) then
      return
    end
    if (BigWigsLoader) then
      BigWigsLoader:RegisterMessage(event, bigWigsEventCallback);
      registeredBigWigsEvents [event] = true;
    end
  end

  function WeakAuras.RegisterBigWigsTimer()
    WeakAuras.RegisterBigWigsCallback("BigWigs_StartBar");
    WeakAuras.RegisterBigWigsCallback("BigWigs_StopBar");
    WeakAuras.RegisterBigWigsCallback("BigWigs_StopBars");
    WeakAuras.RegisterBigWigsCallback("BigWigs_OnBossDisable");
  end

  function WeakAuras.GetBigWigsTimer(addon, spellId, text, operator)
    local expirationTime, duration, icon
    for i, v in ipairs(bars) do
      local found = true;
      if (addon and addon ~= v.addon) then
        found = false;
      end
      if (found and spellId and spellId ~= v.spellId) then
        found = false;
      end
      if (found and text) then
        if(operator == "==") then
          if (v.text ~= text) then
            found = false;
          end
        elseif (operator == "find('%s')") then
          if (v.text == nil or not v.text:find(text)) then
            found = false;
          end
        elseif (operator == "match('%s')") then
          if (v.text == nil or v.text:match(text)) then
            found = false;
          end
        end
      end
      if (found and (expirationTime == nil or v.expirationTime < expirationTime)) then
        expirationTime, duration, icon = v.expirationTime, v.duration, v.icon;
      end
    end
    return duration or 0, expirationTime or 0, icon;
  end

  local scheduled_scans = {};

  local function doBigWigsScan(fireTime)
    WeakAuras.debug("Performing BigWigs scan at "..fireTime.." ("..GetTime()..")");
    scheduled_scans[fireTime] = nil;
    WeakAuras.ScanEvents("BigWigs_Timer_Update");
  end
  function WeakAuras.ScheduleBigWigsCheck(fireTime)
    if not(scheduled_scans[fireTime]) then
      scheduled_scans[fireTime] = timer:ScheduleTimer(doBigWigsScan, fireTime - GetTime() + 0.1, fireTime);
      WeakAuras.debug("Scheduled BigWigs scan at "..fireTime);
    end
  end

end

-- Weapon Enchants
do
  local mh = GetInventorySlotInfo("MainHandSlot")
  local oh = GetInventorySlotInfo("SecondaryHandSlot")

  local mh_name;
  local mh_exp;
  local mh_dur;
  local mh_icon = GetInventoryItemTexture("player", mh);

  local oh_name;
  local oh_exp;
  local oh_dur;
  local oh_icon = GetInventoryItemTexture("player", oh);

  local tenchFrame;
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
      end

      tenchFrame:SetScript("OnEvent", function(self, event, arg1)
        if(arg1 == "player") then
          timer:ScheduleTimer(tenchUpdate, 0.1);
        end
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

-- Mount
do
  local mountedFrame;
  WeakAuras.frames["Mount Use Handler"] = mountedFrame;
  function WeakAuras.WatchForMounts()
    if not(mountedFrame) then
      mountedFrame = CreateFrame("frame");
      mountedFrame:RegisterEvent("COMPANION_UPDATE");
      local elapsed = 0;
      local delay = 0.5;
      local isMounted = IsMounted();
      local function checkForMounted(self, elaps)
        elapsed = elapsed + elaps
        if(isMounted ~= IsMounted()) then
          isMounted = IsMounted();
          WeakAuras.ScanEvents("MOUNTED_UPDATE");
          mountedFrame:SetScript("OnUpdate", nil);
        end
        if(elapsed > delay) then
          mountedFrame:SetScript("OnUpdate", nil);
        end
      end
      mountedFrame:SetScript("OnEvent", function()
      elapsed = 0;
      mountedFrame:SetScript("OnUpdate", checkForMounted);
      end)
    end
  end
end

-- Pet
do
  local petFrame;
  WeakAuras.frames["Pet Use Handler"] = petFrame;
  function WeakAuras.WatchForPetDeath()
    if not(petFrame) then
      petFrame = CreateFrame("frame");
      petFrame:RegisterUnitEvent("UNIT_HEALTH", "pet");
      petFrame:SetScript("OnEvent", function()
        WeakAuras.ScanEvents("PET_UPDATE");
      end)
    end
  end

  local unitPetFrame;
  WeakAuras.frames["Unit Pet Handler"] = unitPetFrame;
  function WeakAuras.WatchForUnitPet()
    if (not unitPetFrame) then
      unitPetFrame = CreateFrame("frame");
      unitPetFrame:RegisterEvent("UNIT_PET");
      unitPetFrame:SetScript("OnEvent", function()
        WeakAuras.ScanEvents("WA_UNIT_PET", "pet");
      end);
    end
  end
end

-- Player Moving
do
  local playerMovingFrame;
  WeakAuras.frames["Player Moving Frame"] =  playerMovingFrame;
  local moving;
  function WeakAuras.WatchForPlayerMoving()
    if not(playerMovingFrame) then
      playerMovingFrame = CreateFrame("frame");
      playerMovingFrame:RegisterEvent("PLAYER_STARTED_MOVING");
      playerMovingFrame:RegisterEvent("PLAYER_STOPPED_MOVING");
      playerMovingFrame:SetScript("OnEvent", function(self, event)
        -- channeling e.g. Mind Flay results in lots of PLAYER_STARTED_MOVING, PLAYER_STOPPED_MOVING
        -- for each frame
        -- So check after 0.01 s if IsPlayerMoving() actually returns something different.
        timer:ScheduleTimer(function()
          if (moving ~= IsPlayerMoving() or moving == nil) then
            moving = IsPlayerMoving();
            WeakAuras.ScanEvents("PLAYER_MOVING_UPDATE");
          end
        end, 0.01);
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
      timer:ScheduleTimer(WeakAuras.ScanEvents, 0.2, "ITEM_COUNT_UPDATE");
      timer:ScheduleTimer(WeakAuras.ScanEvents, 0.5, "ITEM_COUNT_UPDATE");
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
      scheduled_scans[fireTime] = timer:ScheduleTimer(doCooldownScan, fireTime - GetTime() + 0.1, fireTime);
    end
  end
 end

function GenericTrigger.CanGroupShowWithZero(data)
  return false;
end

function GenericTrigger.CanHaveDuration(data)
  if(
  (
    (
    data.trigger.type == "event"
    or data.trigger.type == "status"
    )
    and (
    (
      data.trigger.event
      and WeakAuras.event_prototypes[data.trigger.event]
      and WeakAuras.event_prototypes[data.trigger.event].durationFunc
    )
    or (
      data.trigger.unevent == "timed"
      and data.trigger.duration
    )
    )
    and not data.trigger.use_inverse
  )
  or (
    data.trigger.type == "custom"
    and (
    (
      data.trigger.custom_type == "event"
      and data.trigger.custom_hide == "timed"
      and data.trigger.duration
    )
    or (
      data.trigger.customDuration
      and data.trigger.customDuration ~= ""
    )
    )
  )
  ) then
    if(
      (
      data.trigger.type == "event"
      or data.trigger.type == "status"
      )
      and data.trigger.event
      and WeakAuras.event_prototypes[data.trigger.event]
      and WeakAuras.event_prototypes[data.trigger.event].durationFunc
    ) then
      if(type(WeakAuras.event_prototypes[data.trigger.event].init) == "function") then
        WeakAuras.event_prototypes[data.trigger.event].init(data.trigger);
      end
      local current, maximum, custom = WeakAuras.event_prototypes[data.trigger.event].durationFunc(data.trigger);
      current = type(current) ~= "number" and current or 0
      maximum = type(maximum) ~= "number" and maximum or 0
      if(custom) then
        return {current = current, maximum = maximum};
      else
        return "timed";
      end
    else
      return "timed";
    end
  else
    return false;
  end
end

function GenericTrigger.CanHaveAuto(data)
  if(
  (
    (
    data.trigger.type == "event"
    or data.trigger.type == "status"
    )
    and data.trigger.event
    and WeakAuras.event_prototypes[data.trigger.event]
    and (
    WeakAuras.event_prototypes[data.trigger.event].iconFunc
    )
  )
  or (
    data.trigger.type == "custom"
    and (
      data.trigger.customIcon
      and data.trigger.customIcon ~= ""
    )
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

function GenericTrigger.GetNameAndIcon(data)
  local trigger = data.trigger;
  local icon, name
  if(trigger.event and WeakAuras.event_prototypes[trigger.event]) then
    if(WeakAuras.event_prototypes[trigger.event].iconFunc) then
      icon = WeakAuras.event_prototypes[trigger.event].iconFunc(trigger);
    end
    if(WeakAuras.event_prototypes[trigger.event].nameFunc) then
      name = WeakAuras.event_prototypes[trigger.event].nameFunc(trigger);
    end
  end
  return name, icon
end

function GenericTrigger.CanHaveTooltip(data)
  local trigger = data.trigger;
  if (trigger.type == "event" or trigger.type == "status") then
    if (trigger.event and WeakAuras.event_prototypes[trigger.event]) then
      if(WeakAuras.event_prototypes[trigger.event].hasSpellID) then
        return "spell";
      elseif(WeakAuras.event_prototypes[trigger.event].hasItemID) then
        return "item";
      end
    end
  end
  return false;
end

function GenericTrigger.SetToolTip(data, region)
  local trigger = data.trigger;
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

WeakAuras.RegisterTriggerSystem({"event", "status", "custom"}, GenericTrigger);
