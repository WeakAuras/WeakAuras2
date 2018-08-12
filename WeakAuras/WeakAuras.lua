local internalVersion = 6;

-- Lua APIs
local tinsert, tconcat, tremove, tContains, wipe = table.insert, table.concat, table.remove, tContains, wipe
local fmt, tostring, select, pairs, next, type = string.format, tostring, select, pairs, next, type
local loadstring, assert, error = loadstring, assert, error
local setmetatable = setmetatable
local coroutine =  coroutine
local _G = _G

-- WoW APIs
local GetTalentInfo, IsAddOnLoaded, InCombatLockdown = GetTalentInfo, IsAddOnLoaded, InCombatLockdown
local LoadAddOn, setfenv, UnitName, GetRealmName, UnitRace, UnitFactionGroup, IsInRaid
  = LoadAddOn, setfenv, UnitName, GetRealmName, UnitRace, UnitFactionGroup, IsInRaid
local UnitClass, UnitExists, UnitGUID, UnitAffectingCombat, GetInstanceInfo, IsInInstance
  = UnitClass, UnitExists, UnitGUID, UnitAffectingCombat, GetInstanceInfo, IsInInstance
local UnitIsUnit, GetRaidRosterInfo, GetSpecialization, UnitInVehicle, UnitHasVehicleUI, GetSpellInfo
  = UnitIsUnit, GetRaidRosterInfo, GetSpecialization, UnitInVehicle, UnitHasVehicleUI, GetSpellInfo
local SendChatMessage, GetChannelName, UnitInBattleground, UnitInRaid, UnitInParty, GetTime, GetSpellLink, GetItemInfo
  = SendChatMessage, GetChannelName, UnitInBattleground, UnitInRaid, UnitInParty, GetTime, GetSpellLink, GetItemInfo
local CreateFrame, IsShiftKeyDown, GetScreenWidth, GetScreenHeight, GetCursorPosition, random, UpdateAddOnCPUUsage, GetFrameCPUUsage, debugprofilestop
  = CreateFrame, IsShiftKeyDown, GetScreenWidth, GetScreenHeight, GetCursorPosition, random, UpdateAddOnCPUUsage, GetFrameCPUUsage, debugprofilestop
local debugstack, IsSpellKnown = debugstack, IsSpellKnown

local ADDON_NAME = "WeakAuras"
local WeakAuras = WeakAuras
local versionString = WeakAuras.versionString
local prettyPrint = WeakAuras.prettyPrint

WeakAurasTimers = setmetatable({}, {__tostring=function() return "WeakAuras" end})
LibStub("AceTimer-3.0"):Embed(WeakAurasTimers)

WeakAuras.maxTimerDuration = 60 * 60 * 24 * 7; -- A week
function WeakAurasTimers:ScheduleTimerFixed(func, delay, ...)
  if (delay < WeakAuras.maxTimerDuration) then
    return self:ScheduleTimer(func, delay, ...);
  end
end

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local timer = WeakAurasTimers
WeakAuras.timer = timer

local L = WeakAuras.L

-- luacheck: globals NamePlateDriverFrame CombatText_AddMessage COMBAT_TEXT_SCROLL_FUNCTION C_Map
-- luacheck: globals Lerp Saturate KuiNameplatesPlayerAnchor KuiNameplatesCore ElvUIPlayerNamePlateAnchor GTFO C_SpecializationInfo

local queueshowooc;

function WeakAuras.InternalVersion()
  return internalVersion;
end

function WeakAuras.LoadOptions(msg)
  if not(IsAddOnLoaded("WeakAurasOptions")) then
    if InCombatLockdown() then
      -- inform the user and queue ooc
      prettyPrint(L["Options will finish loading after combat ends."])
      queueshowooc = msg or "";
      WeakAuras.frames["Addon Initialization Handler"]:RegisterEvent("PLAYER_REGEN_ENABLED")
      return false;
    else
      local loaded, reason = LoadAddOn("WeakAurasOptions");
      if not(loaded) then
        reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
        print(WeakAuras.printPrefix .. "Options could not be loaded, the addon is " .. reason);
        return false;
      end
    end
  end
  return true;
end

function WeakAuras.OpenOptions(msg)
  if (WeakAuras.LoadOptions(msg)) then
    WeakAuras.ToggleOptions(msg);
  end
end

SLASH_WEAKAURAS1, SLASH_WEAKAURAS2 = "/weakauras", "/wa";
function SlashCmdList.WEAKAURAS(msg)
  if (msg) then
    if (msg == "pstart") then
      WeakAuras.StartProfile();
      return;
    elseif (msg == "pstop") then
      WeakAuras.StopProfile();
      return;
    elseif(msg == "pprint") then
      WeakAuras.PrintProfile();
      return;
    end
  end
  WeakAuras.OpenOptions(msg);
end

BINDING_HEADER_WEAKAURAS = ADDON_NAME
BINDING_NAME_WEAKAURASTOGGLE = L["Toggle Options Window"]
BINDING_NAME_WEAKAURASSTARTPROFILING = L["Start Profiling"]
BINDING_NAME_WEAKAURASSTOPPROFILING = L["Stop Profiling"]
BINDING_NAME_WEAKAURASPRINTPROFILING = L["Print Profiling Results"]

-- An alias for WeakAurasSaved, the SavedVariables
-- Noteable properties:
--  debug: If set to true, WeakAura.debug() outputs messages to the chat frame
--  displays: All aura settings, keyed on their id
local db;

local registeredFromAddons;
-- List of addons that registered displays
WeakAuras.addons = {};
local addons = WeakAuras.addons;

-- A list of tutorials, filled in by the WeakAuras_Tutorials addon by calling RegisterTutorial
WeakAuras.tutorials = {};
local tutorials = WeakAuras.tutorials;

-- used if an addon tries to register a display under an id that the user already has a display with that id
WeakAuras.collisions = {};
local collisions = WeakAuras.collisions;

-- While true no events are handled. E.g. WeakAuras is paused while the Options dialog is open
local paused = true;
local importing = false;

-- squelches actions and sounds from auras. is used e.g. to prevent lots of actions/sounds from triggering
-- on login or after closing the options dialog
local squelch_actions = true;
local in_loading_screen = false;

-- Load functions, keyed on id
local loadFuncs = {};
-- Load functions for the Options window that ignore various load options
local loadFuncsForOptions = {};

-- Check Conditions Functions, keyed on id
local checkConditions = {};

-- Dynamic Condition functions to run. keyed on event and id
local dynamicConditions = {};

-- Global Dynamic Condition Funcs, keyed on the event
local globalDynamicConditionFuncs = {};

-- All regions keyed on id, has properties: region, regionType, also see clones
WeakAuras.regions = {};
local regions = WeakAuras.regions;
WeakAuras.auras = {};
local auras = WeakAuras.auras;
WeakAuras.events = {};
local events = WeakAuras.events;

-- keyed on id, contains bool indicating whether the aura is loaded
WeakAuras.loaded = {};
local loaded = WeakAuras.loaded;

WeakAuras.specificBosses = {};
local specificBosses = WeakAuras.specificBosses;
WeakAuras.specificUnits = {};
local specificUnits = WeakAuras.specificUnits;

-- contains regions for clones
WeakAuras.clones = {};
local clones = WeakAuras.clones;

-- Unused regions that are kept around for clones
WeakAuras.clonePool = {};
local clonePool = WeakAuras.clonePool;

-- One table per regionType, see RegisterRegionType, notable properties: create, modify and default
WeakAuras.regionTypes = {};
local regionTypes = WeakAuras.regionTypes;

-- One table per regionType, see RegisterRegionOptions
WeakAuras.regionOptions = {};
local regionOptions = WeakAuras.regionOptions;

-- Maps from trigger type to trigger system
WeakAuras.triggerTypes = {};
local triggerTypes = WeakAuras.triggerTypes;

-- Trigger State, updated by trigger systems, then applied to regions by UpdatedTriggerState
-- keyed on id, triggernum, cloneid
-- cloneid can be a empty string

-- Noteable properties:
--  changed: Whether this trigger state was recently changed and its properties
--           need to be applied to a region. The glue code resets this
--           after syncing the region to the trigger state
--  show: Whether the region for this trigger state should be shown
--  progressType: Either "timed", "static"
--    duration: The duration if the progressType is timed
--    expirationTime: The expirationTime if the progressType is timed
--    resort: Should be set to true by the trigger system the parent needs
--            to be resorted. The glue code resets this.
--    autoHide: If the aura should be hidden on expiring
--    value: The value if the progressType is static
--    total: The total if the progressType is static
--    inverse: The static values should be interpreted inversely
--  name: The name information
--  icon: The icon information
--  texture: The texture information
--  stacks: The stacks information
--  index: The index of the buff/debuff for the buff trigger system, used to set the tooltip
--  spellId: spellId of the buff/debuff, used to set the tooltip

WeakAuras.triggerState = {}
local triggerState = WeakAuras.triggerState;

-- Fallback states
local fallbacksStates = {};

-- List of all trigger systems, contains each system once
WeakAuras.triggerSystems = {}
local triggerSystems = WeakAuras.triggerSystems;

WeakAuras.forceable_events = {};

local from_files = {};

local timers = {}; -- Timers for autohiding, keyed on id, triggernum, cloneid
WeakAuras.timers = timers;

local loaded_events = {};
WeakAuras.loaded_events = loaded_events;
local loaded_auras = {};
WeakAuras.loaded_auras = loaded_auras;

-- Animations
WeakAuras.animations = {};
local animations = WeakAuras.animations;
WeakAuras.pending_controls = {};
local pending_controls = WeakAuras.pending_controls;

WeakAuras.frames = {};

WeakAuras.raidUnits = {};
WeakAuras.partyUnits = {};
do
  for i=1,40 do
    WeakAuras.raidUnits[i] = "raid"..i
  end
  for i=1,4 do
    WeakAuras.partyUnits[i] = "party"..i
  end
end
local playerLevel = UnitLevel("player");

WeakAuras.currentInstanceType = "none"

-- Custom Action Functions, keyed on id, "init" / "start" / "finish"
WeakAuras.customActionsFunctions = {};

-- Custom Functions used in conditions, keyed on id, condition number, "changes", property number
WeakAuras.customConditionsFunctions = {};

local anim_function_strings = WeakAuras.anim_function_strings;
local anim_presets = WeakAuras.anim_presets;
local load_prototype = WeakAuras.load_prototype;

local levelColors = {
  [0] = "|cFFFFFFFF",
  [1] = "|cFF40FF40",
  [2] = "|cFF6060FF",
  [3] = "|cFFFF4040"
};

function WeakAuras.debug(msg, level)
  if(db.debug) then
    level = (level and levelColors[level] and level) or 2;
    msg = (type(msg) == "string" and msg) or (msg and "Invalid debug message of type "..type(msg)) or "Debug message not specified";
    DEFAULT_CHAT_FRAME:AddMessage(levelColors[level]..msg);
  end
end
local debug = WeakAuras.debug;

function WeakAuras.validate(input, default)
  for field, defaultValue in pairs(default) do
    if(type(defaultValue) == "table" and type(input[field]) ~= "table") then
      input[field] = {};
    elseif(input[field] == nil) then
      input[field] = defaultValue;
    elseif(type(input[field]) ~= type(defaultValue)) then
      input[field] = defaultValue;
    end
    if(type(input[field]) == "table") then
      WeakAuras.validate(input[field], defaultValue);
    end
  end
end

function WeakAuras.RegisterRegionType(name, createFunction, modifyFunction, default, properties)
  if not(name) then
    error("Improper arguments to WeakAuras.RegisterRegionType - name is not defined");
  elseif(type(name) ~= "string") then
    error("Improper arguments to WeakAuras.RegisterRegionType - name is not a string");
  elseif not(createFunction) then
    error("Improper arguments to WeakAuras.RegisterRegionType - creation function is not defined");
  elseif(type(createFunction) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterRegionType - creation function is not a function");
  elseif not(modifyFunction) then
    error("Improper arguments to WeakAuras.RegisterRegionType - modification function is not defined");
  elseif(type(modifyFunction) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterRegionType - modification function is not a function")
  elseif not(default) then
    error("Improper arguments to WeakAuras.RegisterRegionType - default options are not defined");
  elseif(type(default) ~= "table") then
    error("Improper arguments to WeakAuras.RegisterRegionType - default options are not a table");
  elseif(type(default) ~= "table" and type(default) ~= "nil") then
    error("Improper arguments to WeakAuras.RegisterRegionType - properties options are not a table");
  elseif(regionTypes[name]) then
    error("Improper arguments to WeakAuras.RegisterRegionType - region type \""..name.."\" already defined");
  else
    regionTypes[name] = {
      create = createFunction,
      modify = modifyFunction,
      default = default,
      properties = properties
    };
  end
end

function WeakAuras.RegisterRegionOptions(name, createFunction, icon, displayName, createThumbnail, modifyThumbnail, description, templates)
  if not(name) then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - name is not defined");
  elseif(type(name) ~= "string") then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - name is not a string");
  elseif not(createFunction) then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - creation function is not defined");
  elseif(type(createFunction) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - creation function is not a function");
  elseif not(icon) then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - icon is not defined");
  elseif not(type(icon) == "string" or type(icon) == "function") then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - icon is not a string or a function")
  elseif not(displayName) then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - display name is not defined".." "..name);
  elseif(type(displayName) ~= "string") then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - display name is not a string");
  elseif(regionOptions[name]) then
    error("Improper arguments to WeakAuras.RegisterRegionOptions - region type \""..name.."\" already defined");
  else
    regionOptions[name] = {
      create = createFunction,
      icon = icon,
      displayName = displayName,
      createThumbnail = createThumbnail,
      modifyThumbnail = modifyThumbnail,
      description = description,
      templates = templates
    };
  end
end

-- This function is replaced in WeakAurasOptions.lua
function WeakAuras.IsOptionsOpen()
  return false;
end

local LBG = LibStub("LibButtonGlow-1.0")
local function WeakAuras_ShowOverlayGlow(frame)
  LBG.ShowOverlayGlow(frame)
end

local function WeakAuras_HideOverlayGlow(frame)
  LBG.HideOverlayGlow(frame)
end

WeakAuras.ShowOverlayGlow = WeakAuras_ShowOverlayGlow;
WeakAuras.HideOverlayGlow = WeakAuras_HideOverlayGlow;

local function forbidden()
  print("|cffffff00A WeakAura just tried to use a forbidden function but has been blocked from doing so. Please check your auras!|r")
end

local blockedFunctions = {
  -- Lua functions that may allow breaking out of the environment
  getfenv = true,
  setfenv = true,
  loadstring = true,
  pcall = true,
  -- blocked WoW API
  SendMail = true,
  SetTradeMoney = true,
  AddTradeMoney = true,
  PickupTradeMoney = true,
  PickupPlayerMoney = true,
  TradeFrame = true,
  MailFrame = true,
  EnumerateFrames = true,
  RunScript = true,
  AcceptTrade = true,
  SetSendMailMoney = true,
  EditMacro = true,
  SlashCmdList = true,
  DevTools_DumpCommand = true,
  hash_SlashCmdList = true,
  CreateMacro = true,
  SetBindingMacro = true,
  GuildDisband = true,
  GuildUninvite = true,
  securecall = true,
}

local overrideFunctions = {
  ActionButton_ShowOverlayGlow = WeakAuras_ShowOverlayGlow,
  ActionButton_HideOverlayGlow = WeakAuras_HideOverlayGlow,
}

local aura_environments = {};
local current_aura_env = nil;
local aura_env_stack = {}; -- Stack of of aura environments, allows use of recursive aura activations through calls to WeakAuras.ScanEvents().
function WeakAuras.ActivateAuraEnvironment(id, cloneId, state)
  if(not id or not db.displays[id]) then
    -- Pop the last aura_env from the stack, and update current_aura_env appropriately.
    tremove(aura_env_stack);
    current_aura_env = aura_env_stack[#aura_env_stack] or nil;
  else
    local data = db.displays[id];
    if data.init_started then
      -- Point the current environment to the correct table
      aura_environments[id] = aura_environments[id] or {};
      current_aura_env = aura_environments[id];
      current_aura_env.cloneId = cloneId;
      current_aura_env.state = state;
      current_aura_env.region = WeakAuras.GetRegion(id, cloneId);
      -- Push the new environment onto the stack
      tinsert(aura_env_stack, current_aura_env);
    else
      -- Reset the environment if we haven't completed init, i.e. if we add/update/replace a WeakAura
      aura_environments[id] = {};
      current_aura_env = aura_environments[id];
      current_aura_env.cloneId = cloneId;
      current_aura_env.state = state;
      current_aura_env.region = WeakAuras.GetRegion(id, cloneId);
      -- Push the new environment onto the stack
      tinsert(aura_env_stack, current_aura_env);
      -- Run the init function if supplied
      local actions = data.actions.init;
      data.init_started = 1;
      if(actions and actions.do_custom and actions.custom) then
        local func = WeakAuras.customActionsFunctions[id]["init"];
        if func then
          current_aura_env.id = id;
          xpcall(func, geterrorhandler());
        end
      end
    end
    current_aura_env.id = id;
  end
end

local env_getglobal
local exec_env = setmetatable({}, { __index =
  function(t, k)
    if k == "_G" then
      return t
    elseif k == "getglobal" then
      return env_getglobal
    elseif k == "aura_env" then
      return current_aura_env;
    elseif blockedFunctions[k] then
      return forbidden
    elseif overrideFunctions[k] then
      return overrideFunctions[k]
    elseif WeakAuras.helperFunctions[k] then
      return WeakAuras.helperFunctions[k]
    else
      return _G[k]
    end
  end
})

function env_getglobal(k)
  return exec_env[k]
end

local function_cache = {};
function WeakAuras.LoadFunction(string, id, inTrigger)
  if function_cache[string] then
    return function_cache[string]
  else
    local loadedFunction, errorString = loadstring("--[[ Error in ' ".. (id or "Unknown") .. (inTrigger and ("':'".. inTrigger) or "") .."' ]]" .. string)
    if errorString then
      print(errorString)
    else
      setfenv(loadedFunction, exec_env)
      local success, func = pcall(assert(loadedFunction))
      if success then
        function_cache[string] = func
        return func
      end
    end
  end
end

function WeakAuras.ParseNumber(numString)
  if not(numString and type(numString) == "string") then
    if(type(numString) == "number") then
      return numString, "notastring";
    else
      return nil;
    end
  elseif(numString:sub(-1) == "%") then
    local percent = tonumber(numString:sub(0, -2));
    if(percent) then
      return percent / 100, "percent";
    else
      return nil;
    end
  else
    -- Matches any string with two integers separated by a forward slash
    -- Captures the two integers
    local _, _, numerator, denominator = numString:find("(%d+)%s*/%s*(%d+)");
    numerator, denominator = tonumber(numerator), tonumber(denominator);
    if(numerator and denominator) then
      if(denominator == 0) then
        return nil;
      else
        return numerator / denominator, "fraction";
      end
    else
      local num = tonumber(numString)
      if(num) then
        if(math.floor(num) ~= num) then
          return num, "decimal";
        else
          return num, "whole";
        end
      else
        return nil;
      end
    end
  end
end

-- Used for the load function, could be simplified a bit
-- It used to be also used for the generic trigger system
function WeakAuras.ConstructFunction(prototype, trigger, skipOptional)
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
        end
        if (arg.optional and skipOptional) then
        -- Do nothing
        elseif(arg.hidden or arg.type == "tristate" or arg.type == "toggle" or (arg.type == "multiselect" and trigger["use_"..name] ~= nil) or ((trigger["use_"..name] or arg.required) and trigger[name])) then
          if(arg.init and arg.init ~= "arg") then
            init = init.."local "..name.." = "..arg.init.."\n";
          end
          local number = trigger[name] and tonumber(trigger[name]);
          local test;
          if(arg.type == "tristate") then
            if(trigger["use_"..name] == false) then
              test = "(not "..name..")";
            elseif(trigger["use_"..name]) then
              if(arg.test) then
                test = "("..arg.test:format(trigger[name])..")";
              else
                test = name;
              end
            end
          elseif(arg.type == "multiselect") then
            if(trigger["use_"..name] == false) then -- multi selection
              local any = false;
              if (trigger[name] and trigger[name].multi) then
                test = "(";
                for value, _ in pairs(trigger[name].multi) do
                  if not arg.test then
                    test = test..name.."=="..(tonumber(value) or "[["..value.."]]").." or ";
                  else
                    test = test..arg.test:format(tonumber(value) or "[["..value.."]]").." or ";
                  end
                  any = true;
                end
                if(any) then
                  test = test:sub(0, -5);
                else
                  test = "(false";
                end
                test = test..")";
              end
            elseif(trigger["use_"..name]) then -- single selection
              local value = trigger[name] and trigger[name].single;
              if not arg.test then
                test = trigger[name] and trigger[name].single and "("..name.."=="..(tonumber(value) or "[["..value.."]]")..")";
              else
                test = trigger[name] and trigger[name].single and "("..arg.test:format(tonumber(value) or "[["..value.."]]")..")";
              end
            end
          elseif(arg.type == "toggle") then
            if(trigger["use_"..name]) then
              if(arg.test) then
                test = "("..arg.test:format(trigger[name])..")";
              else
                test = name;
              end
            end
          elseif(arg.test) then
            test = "("..arg.test:format(trigger[name])..")";
          elseif(arg.type == "longstring" and trigger[name.."_operator"]) then
            if(trigger[name.."_operator"] == "==") then
              test = "("..name.."==[["..trigger[name].."]])";
            else
              test = "("..name..":"..trigger[name.."_operator"]:format(trigger[name])..")";
            end
          else
            if(type(trigger[name]) == "table") then
              trigger[name] = "error";
            end
            test = "("..name..(trigger[name.."_operator"] or "==")..(number or "[["..(trigger[name] or "").."]]")..")";
          end
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
  ret = ret..(#tests > 0 and tconcat(tests, " and ") or "true");
  ret = ret..") then\n";
  if(#debug > 0) then
    ret = ret.."print('ret: true');\n";
  end
  ret = ret.."return true else return false end end";

  return ret;
end

function WeakAuras.GetActiveConditions(id, cloneId)
  triggerState[id].activatedConditions[cloneId] = triggerState[id].activatedConditions[cloneId] or {};
  return triggerState[id].activatedConditions[cloneId];
end

local function formatValueForAssignment(vtype, value, pathToCustomFunction)
  if (value == nil) then
    value = false;
  end
  if (vtype == "bool") then
    return value and tostring(value) or "false";
  elseif(vtype == "number") then
    return value and tostring(value) or "0";
  elseif (vtype == "list") then
    return type(value) == "string" and string.format("%q", value) or "nil";
  elseif(vtype == "color") then
    if (value and type(value) == "table") then
      return string.format("{%s, %s, %s, %s}", tostring(value[1]), tostring(value[2]), tostring(value[3]), tostring(value[4]));
    end
    return "{1, 1, 1, 1}";
  elseif(vtype == "chat") then
    if (value and type(value) == "table") then
      return string.format("{message_type = %q, message = %q, message_dest = %q, message_channel = %q, message_custom = %s}",
        tostring(value.message_type), tostring(value.message or ""),
        tostring(value.message_dest), tostring(value.message_channel),
        pathToCustomFunction);
    end
  elseif(vtype == "sound") then
    if (value and type(value) == "table") then
      return string.format("{ sound = %q, sound_channel = %q, sound_path = %q, sound_kit_id = %q, sound_type = %q, %s}",
        tostring(value.sound or ""), tostring(value.sound_channel or ""), tostring(value.sound_path or ""),
        tostring(value.sound_kit_id or ""), tostring(value.sound_type or ""),
        value.sound_repeat and "sound_repeat = " .. tostring(value.sound_repeat) or "nil");
    end
  elseif(vtype == "customcode") then
    return string.format("%s", pathToCustomFunction);
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

local function CreateCheckCondition(ret, condition, conditionNumber, allConditionsTemplate, debug)
  local trigger = condition.check and condition.check.trigger;
  local variable = condition.check and condition.check.variable;
  local op = condition.check and condition.check.op;
  local value = condition.check and condition.check.value;
  if (trigger and variable and value) then
    local conditionTemplate = allConditionsTemplate[trigger] and allConditionsTemplate[trigger][variable];
    local type = conditionTemplate and conditionTemplate.type;
    local test = conditionTemplate and conditionTemplate.test;

    local check = nil;
    local stateCheck = "state and state.show and ";
    local stateVariableCheck = "state." .. variable .. "~= nil and ";
    if (test) then
      if (value) then
        check = string.format(test, value, op or "");
      end
    elseif (type == "number" and op) then
      check = stateCheck .. stateVariableCheck .. "state." .. variable .. op .. value;
    elseif (type == "timer" and op) then
      if (op == "==") then
        check = stateCheck .. stateVariableCheck .. "abs(state." ..variable .. "- now -" .. value .. ") < 0.05";
      else
        check = stateCheck .. stateVariableCheck .. "state." .. variable .. "- now" .. op .. value;
      end
    elseif (type == "select" and op) then
      if (tonumber(value)) then
        check = stateCheck .. stateVariableCheck .. "state." .. variable .. op .. tonumber(value);
      else
        check = stateCheck .. stateVariableCheck .. "state." .. variable .. op .. "'" .. value .. "'";
      end
    elseif (type == "bool") then
      local rightSide = value == 0 and "false" or "true";
      check = stateCheck .. stateVariableCheck .. "state." .. variable .. "==" .. rightSide
    elseif (type == "string") then
      if(op == "==") then
        check = stateCheck .. stateVariableCheck .. "state." .. variable .. " == [[" .. value .. "]]";
      elseif (op  == "find('%s')") then
        check = stateCheck .. stateVariableCheck .. "state." .. variable .. ":find([[" .. value .. "]], 1, true)";
      elseif (op == "match('%s')") then
        check = stateCheck .. stateVariableCheck .. "state." ..  variable .. ":match([[" .. value .. "]], 1, true)";
      end
    end

    if (check) then
      ret = ret .. "  allStates = WeakAuras.GetTriggerStateForTrigger(id, " .. trigger .. ")\n";
      ret = ret .. "  state = allStates[cloneId] or allStates['']\n";
      ret = ret .. "  if (" .. check .. ") then\n";
      ret = ret .. "    newActiveConditions[" .. conditionNumber .. "] = true;\n";
      ret = ret .. "  end\n";
    end

    if (type == "timer" and value) then
      ret = ret .. "  local nextTime = state and state." .. variable .. " and (state." .. variable .. " -" .. value .. ")\n";
      ret = ret .. "  if (nextTime and (not recheckTime or nextTime < recheckTime) and nextTime >= now) then\n"
      ret = ret .. "    recheckTime = nextTime\n";
      ret = ret .. "  end\n"
    end
    ret = ret .. "\n";
  end
  return ret;
end

local function GetBaseProperty(data, property, start)
  if (not data) then
    return nil;
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
            if (WeakAuras.customConditionsFunctions[id]
              and WeakAuras.customConditionsFunctions[id][conditionNumber]
              and  WeakAuras.customConditionsFunctions[id][conditionNumber].changes
              and WeakAuras.customConditionsFunctions[id][conditionNumber].changes[changeNum]) then
              pathToCustomFunction = string.format("WeakAuras.customConditionsFunctions[%q][%s].changes[%s]", id, conditionNumber, changeNum);
            end
            ret = ret .. "     if (not skipActions) then\n";
            ret = ret .. "       region:" .. propertyData.action .. "(" .. formatValueForAssignment(propertyData.type, change.value, pathToCustomFunction) .. ")" .. "\n";
            if (debug) then ret = ret .. "       print('# " .. propertyData.action .. "(" .. formatValueForAssignment(propertyData.type, change.value, pathToCustomFunction) .. "')\n"; end
            ret = ret .. "     end\n"
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

function WeakAuras.LoadCustomActionFunctions(data)
  local id = data.id;
  WeakAuras.customActionsFunctions[id] = {};

  if (data.actions) then
    if (data.actions.init and data.actions.init.do_custom and data.actions.init.custom) then
      local func = WeakAuras.LoadFunction("return function() "..(data.actions.init.custom).."\n end", id);
      WeakAuras.customActionsFunctions[id]["init"] = func;
    end

    if (data.actions.start) then
      if (data.actions.start.do_custom and data.actions.start.custom) then
        local func = WeakAuras.LoadFunction("return function() "..(data.actions.start.custom).."\n end", id);
        WeakAuras.customActionsFunctions[id]["start"] = func;
      end

      if (data.actions.start.do_message and data.actions.start.message_custom) then
        local func = WeakAuras.LoadFunction("return "..(data.actions.start.message_custom), id);
        WeakAuras.customActionsFunctions[id]["start_message"] = func;
      end
    end

    if (data.actions.finish) then
      if (data.actions.finish.do_custom and data.actions.finish.custom) then
        local func = WeakAuras.LoadFunction("return function() "..(data.actions.finish.custom).."\n end", id);
        WeakAuras.customActionsFunctions[id]["finish"] = func;
      end

      if (data.actions.finish.do_message and data.actions.finish.message_custom) then
        local func = WeakAuras.LoadFunction("return "..(data.actions.finish.message_custom), id);
        WeakAuras.customActionsFunctions[id]["finish_message"] = func;
      end
    end
  end
end

function WeakAuras.GetProperties(data)
  local properties;
  local propertiesFunction = WeakAuras.regionTypes[data.regionType] and WeakAuras.regionTypes[data.regionType].properties;
  if (type(propertiesFunction) == "function") then
    properties = propertiesFunction(data);
  else
    properties = propertiesFunction;
  end
  return properties;
end

function WeakAuras.LoadConditionPropertyFunctions(data)
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
    events = {"PLAYER_TARGET_CHANGED"},
    globalStateUpdate = function(state)
      state.hastarget = UnitExists("target");
    end
  },
}

function WeakAuras.GetGlobalConditions()
  return globalConditions;
end

function WeakAuras.ConstructConditionFunction(data)
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
  ret = ret .. "return function(region, skipActions)\n";
  if (debug) then ret = ret .. "  print('check conditions for:', region.id, region.cloneId)\n"; end
  ret = ret .. "  local id = region.id\n";
  ret = ret .. "  local cloneId = region.cloneId or ''\n";
  ret = ret .. "  local activatedConditions = WeakAuras.GetActiveConditions(id, cloneId)\n";
  ret = ret .. "  wipe(newActiveConditions)\n";
  ret = ret .. "  local allStates\n";
  ret = ret .. "  local state\n";
  ret = ret .. "  local recheckTime;\n"
  ret = ret .. "  local now = GetTime();\n"

  local normalConditionCount = data.conditions and #data.conditions;
  -- First Loop gather which conditions are active
  if (data.conditions) then
    for conditionNumber, condition in ipairs(data.conditions) do
      ret = CreateCheckCondition(ret, condition, conditionNumber, allConditionsTemplate, debug)
    end
  end

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

    ret = ret .. "    region:" .. properties[property].setter .. "(" .. arg1 .. formatValueForCall(properties[property].type, property)  .. ")\n";
    if (debug) then ret = ret .. "    print('Calling "  .. properties[property].setter ..  " with', " .. arg1 ..  formatValueForCall(properties[property].type, property) .. ")\n"; end
    ret = ret .. "  end\n";
  end
  ret = ret .. "end\n";

  return ret;
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
    if (triggerState[id] and triggerState[id].show and checkConditions[id]) then
      local activeTriggerState = WeakAuras.GetTriggerStateForTrigger(id, triggerState[id].activeTrigger);
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
function WeakAuras.RegisterForGlobalConditions(id)
  local data = WeakAuras.GetData(id);
  for event, conditonFunctions in pairs(dynamicConditions) do
    conditonFunctions.id = nil;
  end

  local register = {};
  if (data.conditions) then
    local allConditionsTemplate = WeakAuras.GetTriggerConditions(data);
    allConditionsTemplate[-1] = WeakAuras.GetGlobalConditions();

    for conditionNumber, condition in ipairs(data.conditions) do
      local trigger = condition.check and condition.check.trigger;
      local variable = condition.check and condition.check.variable;

      if (trigger and variable) then
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
      dynamicConditionsFrame:RegisterEvent(event);
    end
  end
end

function WeakAuras.UnregisterForGlobalConditions(id)
  for event, condFuncs in pairs(dynamicConditions) do
    condFuncs[id] = nil;
  end
end

WeakAuras.talent_types_specific = {}
WeakAuras.pvp_talent_types_specific = {}
function WeakAuras.CreateTalentCache()
  local _, player_class = UnitClass("player")

  WeakAuras.talent_types_specific[player_class] = WeakAuras.talent_types_specific[player_class] or {};
  local spec = GetSpecialization()
  WeakAuras.talent_types_specific[player_class][spec] = WeakAuras.talent_types_specific[player_class][spec] or {};

  for tier = 1, MAX_TALENT_TIERS do
    for column = 1, NUM_TALENT_COLUMNS do
      -- Get name and icon info for the current talent of the current class and save it
      local _, talentName, talentIcon = GetTalentInfo(tier, column, 1)
      local talentId = (tier-1)*3+column
      -- Get the icon and name from the talent cache and record it in the table that will be used by WeakAurasOptions
      if (talentName and talentIcon) then
        WeakAuras.talent_types_specific[player_class][spec][talentId] = "|T"..talentIcon..":0|t "..talentName
      end
    end
  end
end

local pvpTalentsInitialized = false;
function WeakAuras.CreatePvPTalentCache()
  if (pvpTalentsInitialized) then return end;
  local _, player_class = UnitClass("player")
  local spec = GetSpecialization()

  if (not player_class or not spec) then
    return;
  end

  WeakAuras.pvp_talent_types_specific[player_class] = WeakAuras.pvp_talent_types_specific[player_class] or {};
  WeakAuras.pvp_talent_types_specific[player_class][spec] = WeakAuras.pvp_talent_types_specific[player_class][spec] or {};

  local function formatTalent(talentId)
    local _, name, icon = GetPvpTalentInfoByID(talentId);
    return "|T"..icon..":0|t "..name
  end

  local slotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(2);
  if (slotInfo) then

    WeakAuras.pvp_talent_types_specific[player_class][spec] = {
      formatTalent(3589),
      formatTalent(3588),
      formatTalent(3587),
      nil
    };

    local pvpSpecTalents = slotInfo.availableTalentIDs;
    for i, talentId in ipairs(pvpSpecTalents) do
      WeakAuras.pvp_talent_types_specific[player_class][spec][i + 3] = formatTalent(talentId);
    end

    pvpTalentsInitialized = true;
  end
end

local frame = CreateFrame("FRAME", "WeakAurasFrame", UIParent);
WeakAuras.frames["WeakAuras Main Frame"] = frame;
frame:SetAllPoints(UIParent);
local loadedFrame = CreateFrame("FRAME");
WeakAuras.frames["Addon Initialization Handler"] = loadedFrame;
loadedFrame:RegisterEvent("ADDON_LOADED");
loadedFrame:RegisterEvent("PLAYER_LOGIN");
loadedFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
loadedFrame:RegisterEvent("LOADING_SCREEN_ENABLED");
loadedFrame:RegisterEvent("LOADING_SCREEN_DISABLED");
loadedFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
loadedFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
loadedFrame:SetScript("OnEvent", function(self, event, addon)
  if(event == "ADDON_LOADED") then
    if(addon == ADDON_NAME) then
      WeakAurasSaved = WeakAurasSaved or {};
      db = WeakAurasSaved;

      -- Defines the action squelch period after login
      -- Stored in SavedVariables so it can be changed by the user if they find it necessary
      db.login_squelch_time = db.login_squelch_time or 10;

      -- Deprecated fields with *lots* of data, clear them out
      db.iconCache = nil;
      db.iconHash = nil;
      db.tempIconCache = nil;
      db.dynamicIconCache = db.dynamicIconCache or {};

      db.displays = db.displays or {};
      db.registered = db.registered or {};

      WeakAuras.UpdateCurrentInstanceType();
      WeakAuras.SyncParentChildRelationships();
    end
  elseif(event == "PLAYER_LOGIN") then
    local toAdd = {};
    for id, data in pairs(db.displays) do
      if(id ~= data.id) then
        print("|cFF8800FFWeakAuras|r detected a corrupt entry in WeakAuras saved displays - '"..tostring(id).."' vs '"..tostring(data.id).."'" );
        data.id = id;
      end
      tinsert(toAdd, data);
    end
    WeakAuras.AddMany(toAdd);
    WeakAuras.AddManyFromAddons(from_files);
    WeakAuras.RegisterDisplay = WeakAuras.AddFromAddon;

    WeakAuras.ResolveCollisions(function() registeredFromAddons = true; end);

    for _, triggerSystem in pairs(triggerSystems) do
      if (triggerSystem.AllAdded) then
        triggerSystem.AllAdded();
      end
    end
    -- check in case of a disconnect during an encounter.
    if (db.CurrentEncounter) then
      WeakAuras.CheckForPreviousEncounter()
    end

    WeakAuras.RegisterLoadEvents();
    WeakAuras.Resume();
  elseif(event == "PLAYER_ENTERING_WORLD") then
    -- Schedule events that need to be handled some time after login
    timer:ScheduleTimer(function() squelch_actions = false; end, db.login_squelch_time);      -- No sounds while loading
    WeakAuras.CreateTalentCache() -- It seems that GetTalentInfo might give info about whatever class was previously being played, until PLAYER_ENTERING_WORLD
    WeakAuras.UpdateCurrentInstanceType();
  elseif(event == "PLAYER_PVP_TALENT_UPDATE") then
    WeakAuras.CreatePvPTalentCache();
  elseif(event == "LOADING_SCREEN_ENABLED") then
    in_loading_screen = true;
  elseif(event == "LOADING_SCREEN_DISABLED") then
    in_loading_screen = false;
  elseif(event == "ACTIVE_TALENT_GROUP_CHANGED") then
    WeakAuras.CreateTalentCache();
  elseif(event == "PLAYER_REGEN_ENABLED") then
    if (queueshowooc) then
      WeakAuras.OpenOptions(queueshowooc)
      queueshowooc = nil
      WeakAuras.frames["Addon Initialization Handler"]:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
  end
end);

function WeakAuras.SetImporting(b)
  importing = b;
  WeakAuras.RefreshTooltipButtons()
end

function WeakAuras.IsImporting()
  return importing;
end

function WeakAuras.IsPaused()
  return paused;
end

function WeakAuras.Pause()
  paused = true;
  -- Forcibly hide all displays, and clear all trigger information (it will be restored on .Resume() due to forced events)
  for id, region in pairs(regions) do
    region.region:Collapse(); -- ticket 366
  end

  for id, cloneList in pairs(clones) do
    for cloneId, clone in pairs(cloneList) do
      clone:Collapse();
    end
  end
end

function WeakAuras.Resume()
  paused = false;
  squelch_actions = true;
  WeakAuras.ScanAll();
  squelch_actions = false;
end

function WeakAuras.Toggle()
  if(paused) then
    WeakAuras.Resume();
  else
    WeakAuras.Pause();
  end
end

function WeakAuras.SquelchingActions()
  return squelch_actions;
end

function WeakAuras.InLoadingScreen()
  return in_loading_screen;
end

function WeakAuras.PauseAllDynamicGroups()
  for id, region in pairs(regions) do
    if (region.region.ControlChildren) then
      region.region:Suspend();
    end
  end
end

function WeakAuras.ResumeAllDynamicGroups()
  for id, region in pairs(regions) do
    if (region.region.ControlChildren) then
      region.region:Resume();
    end
  end
end

function WeakAuras.ScanAll()
  WeakAuras.PauseAllDynamicGroups();

  for id, region in pairs(regions) do
    region.region:Collapse();
  end

  for id, cloneList in pairs(clones) do
    for cloneId, clone in pairs(cloneList) do
      clone:Collapse();
    end
  end

  WeakAuras.ResumeAllDynamicGroups();
  WeakAuras.ReloadAll();
end

-- encounter stuff
function WeakAuras.StoreBossGUIDs()
  WeakAuras.StartProfileSystem("boss_guids")
  if (WeakAuras.CurrentEncounter and WeakAuras.CurrentEncounter.boss_guids) then
    for i = 1, 5 do
      if (UnitExists ("boss" .. i)) then
        local guid = UnitGUID ("boss" .. i)
        if (guid) then
          WeakAuras.CurrentEncounter.boss_guids [guid] = true
        end
      end
    end
    db.CurrentEncounter = WeakAuras.CurrentEncounter
  end
  WeakAuras.StopProfileSystem("boss_guids")
end

function WeakAuras.CheckForPreviousEncounter()
  if (UnitAffectingCombat ("player") or InCombatLockdown()) then
    for i = 1, 5 do
      if (UnitExists ("boss" .. i)) then
        local guid = UnitGUID ("boss" .. i)
        if (guid and db.CurrentEncounter.boss_guids [guid]) then
          -- we are in the same encounter
          WeakAuras.CurrentEncounter = db.CurrentEncounter
          return true
        end
      end
    end
    db.CurrentEncounter = nil
  else
    db.CurrentEncounter = nil
  end
end

function WeakAuras.DestroyEncounterTable()
  if (WeakAuras.CurrentEncounter) then
    wipe(WeakAuras.CurrentEncounter)
  end
  WeakAuras.CurrentEncounter = nil
  db.CurrentEncounter = nil
end

function WeakAuras.CreateEncounterTable(encounter_id)
  local _, _, _, _, _, _, _, ZoneMapID = GetInstanceInfo()
  WeakAuras.CurrentEncounter = {
    id = encounter_id,
    zone_id = ZoneMapID,
    boss_guids = {},
  }
  timer:ScheduleTimer(WeakAuras.StoreBossGUIDs, 2)

  return WeakAuras.CurrentEncounter
end

function WeakAuras.LoadEncounterInitScripts(id)
  if (WeakAuras.currentInstanceType ~= "raid") then
    return
  end
  if (id) then
    local data = db.displays[id]
    if (data and data.load.use_encounterid and not data.init_started and data.actions.init and data.actions.init.do_custom) then
      WeakAuras.ActivateAuraEnvironment(id)
      WeakAuras.ActivateAuraEnvironment(nil)
    end
  else
    for id, data in pairs(db.displays) do
      if (data.load.use_encounterid and not data.init_started and data.actions.init and data.actions.init.do_custom) then
        WeakAuras.ActivateAuraEnvironment(id)
        WeakAuras.ActivateAuraEnvironment(nil)
      end
    end
  end
end

function WeakAuras.UpdateCurrentInstanceType(instanceType)
  if (not IsInInstance()) then
    WeakAuras.currentInstanceType = "none"
  else
    WeakAuras.currentInstanceType = instanceType or select (2, GetInstanceInfo())
  end
end

local pausedOptionsProcessing = false;
function WeakAuras.pauseOptionsProcessing(enable)
  pausedOptionsProcessing = enable;
end

function WeakAuras.IsOptionsProcessingPaused()
  return pausedOptionsProcessing;
end

local recentlyLoaded = {}
function WeakAuras.ScanForLoads(self, event, arg1)
  if (WeakAuras.IsOptionsProcessingPaused()) then
    return;
  end
  -- PET_BATTLE_CLOSE fires twice at the end of a pet battle. IsInBattle evaluates to TRUE during the
  -- first firing, and FALSE during the second. I am not sure if this check is necessary, but the
  -- following IF statement limits the impact of the PET_BATTLE_CLOSE event to the second one.
  if (event == "PET_BATTLE_CLOSE" and C_PetBattles.IsInBattle()) then return end

  if(event == "PLAYER_LEVEL_UP") then
    playerLevel = arg1;
  end

  -- encounter id stuff, we are holding the current combat id to further load checks.
  -- there is three ways to unload: encounter_end / zone changed (hearthstone used) / reload or disconnect
  -- regen_enabled isn't good due to combat drop abilities such invisibility, vanish, fake death, etc.
  local encounter_id = WeakAuras.CurrentEncounter and WeakAuras.CurrentEncounter.id or 0

  if (event == "ENCOUNTER_START") then
    encounter_id = tonumber (arg1)
    WeakAuras.CreateEncounterTable (encounter_id)
  elseif (event == "ENCOUNTER_END") then
    encounter_id = 0
    WeakAuras.DestroyEncounterTable()
  end

  local player, realm, spec, zone = UnitName("player"), GetRealmName(), GetSpecialization(), GetRealZoneText();
  local zoneId = C_Map.GetBestMapForUnit("player")
  local zonegroupId = zoneId and C_Map.GetMapGroupID(zoneId)
  local _, race = UnitRace("player")
  local faction = UnitFactionGroup("player")

  local role = select(5, GetSpecializationInfo(spec));

  local _, class = UnitClass("player");
  -- 0:none 1:5N 2:5H 3:10N 4:25N 5:10H 6:25H 7:LFR 8:5CH 9:40N
  local inInstance, Type = IsInInstance()
  local size, difficulty
  local incombat = UnitAffectingCombat("player") -- or UnitAffectingCombat("pet");
  local inencounter = encounter_id ~= 0;
  local inpetbattle = C_PetBattles.IsInBattle()
  local vehicle = UnitInVehicle('player')
  local vehicleUi = UnitHasVehicleUI('player') or HasOverrideActionBar()

  local _, instanceType, difficultyIndex, _, _, _, _, ZoneMapID = GetInstanceInfo()
  if (inInstance) then
    WeakAuras.UpdateCurrentInstanceType(instanceType)
    size = Type
    if difficultyIndex == 1 then
      size = "party"
      difficulty = "normal"
    elseif difficultyIndex == 2 then
      size = "party"
      difficulty = "heroic"
    elseif difficultyIndex == 3 then
      size = "ten"
      difficulty = "normal"
    elseif difficultyIndex == 4 then
      size = "twentyfive"
      difficulty = "normal"
    elseif difficultyIndex == 5 then
      size = "ten"
      difficulty = "heroic"
    elseif difficultyIndex == 6 then
      size = "twentyfive"
      difficulty = "heroic"
    elseif difficultyIndex == 7 then
      size = "twentyfive"
      difficulty = "lfr"
    elseif difficultyIndex == 8 then
      size = "party"
      difficulty = "challenge"
    elseif difficultyIndex == 9 then
      size = "fortyman"
      difficulty = "normal"
    elseif difficultyIndex == 11 then
      size = "scenario"
      difficulty = "heroic"
    elseif difficultyIndex == 12 then
      size = "scenario"
      difficulty = "normal"
    elseif difficultyIndex == 14 then
      size = "flexible"
      difficulty = "normal"
    elseif difficultyIndex == 15 then
      size = "flexible"
      difficulty = "heroic"
    elseif difficultyIndex == 16 then
      size = "twenty"
      difficulty = "mythic"
    elseif difficultyIndex == 17 then
      size = "flexible"
      difficulty = "lfr"
    elseif difficultyIndex == 23 then
      size = "party"
      difficulty = "mythic"
    elseif difficultyIndex == 24 then
      size = "party"
      difficulty = "timewalking"
    elseif difficultyIndex == 33 then
      size = "flexible"
      difficulty = "timewalking"
    end
  else
    WeakAuras.UpdateCurrentInstanceType();
    size = "none"
    difficulty = "none"
  end

  if (WeakAuras.CurrentEncounter) then
    if (ZoneMapID ~= WeakAuras.CurrentEncounter.zone_id and not incombat) then
      encounter_id = 0
      WeakAuras.DestroyEncounterTable()
    end
  end

  if (event == "ZONE_CHANGED_NEW_AREA") then
    WeakAuras.LoadEncounterInitScripts();
  end

  local group = nil;
  if (IsInRaid()) then
    group = "raid";
  elseif (IsInGroup()) then
    group = "group";
  else
    group = "solo";
  end

  local affixes = C_ChallengeMode.IsChallengeModeActive() and select(2, C_ChallengeMode.GetActiveKeystoneInfo())
  local warmodeActive = C_PvP.IsWarModeDesired();

  local changed = 0;
  local shouldBeLoaded, couldBeLoaded;
  wipe(recentlyLoaded);
  for id, data in pairs(db.displays) do
    if (data and not data.controlledChildren) then
      local loadFunc = loadFuncs[id];
      local loadOpt = loadFuncsForOptions[id];
      shouldBeLoaded = loadFunc and loadFunc("ScanForLoads_Auras", incombat, inencounter, warmodeActive, inpetbattle, vehicle, vehicleUi, group, player, realm, class, spec, race, faction, playerLevel, zone, zoneId, zonegroupId, encounter_id, size, difficulty, role, affixes);
      couldBeLoaded =  loadOpt and loadOpt("ScanForLoads_Auras",   incombat, inencounter, warmodeActive, inpetbattle, vehicle, vehicleUi, group, player, realm, class, spec, race, faction, playerLevel, zone, zoneId, zonegroupId, encounter_id, size, difficulty, role, affixes);

      if(shouldBeLoaded and not loaded[id]) then
        WeakAuras.LoadDisplay(id);
        changed = changed + 1;
        recentlyLoaded[id] = true;
      end

      if(loaded[id] and not shouldBeLoaded) then
        WeakAuras.UnloadDisplay(id);
        local region = WeakAuras.regions[id].region;
        if not(paused) then
          region:Collapse();
          WeakAuras.CollapseAllClones(id);
        end
      end
      if(shouldBeLoaded) then
        loaded[id] = true;
      elseif(couldBeLoaded) then
        loaded[id] = false;
      else
        loaded[id] = nil;
      end
    end
  end
  for id, data in pairs(db.displays) do
    if(data.controlledChildren) then
      if(#data.controlledChildren > 0) then
        local any_loaded;
        for index, childId in pairs(data.controlledChildren) do
          if(loaded[childId] ~= nil) then
            any_loaded = true;
            break;
          end
        end
        loaded[id] = any_loaded;
      else
        loaded[id] = true;
      end
    end
  end
  if(changed > 0 and not paused) then
    for _, triggerSystem in pairs(triggerSystems) do
      triggerSystem.ScanAll(recentlyLoaded);
    end
  end

  if (WeakAuras.afterScanForLoads) then -- Hook for Options
    WeakAuras.afterScanForLoads();
  end
  wipe(recentlyLoaded);
end

local loadFrame = CreateFrame("FRAME");
WeakAuras.loadFrame = loadFrame;
WeakAuras.frames["Display Load Handling"] = loadFrame;

loadFrame:RegisterEvent("ENCOUNTER_START");
loadFrame:RegisterEvent("ENCOUNTER_END");

loadFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
loadFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
loadFrame:RegisterEvent("ZONE_CHANGED");
loadFrame:RegisterEvent("ZONE_CHANGED_INDOORS");
loadFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
loadFrame:RegisterEvent("PLAYER_LEVEL_UP");
loadFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
loadFrame:RegisterEvent("PLAYER_REGEN_ENABLED");

loadFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED");
loadFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED");
loadFrame:RegisterEvent("PET_BATTLE_OPENING_START");
loadFrame:RegisterEvent("PET_BATTLE_CLOSE");
loadFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
loadFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
loadFrame:RegisterEvent("SPELLS_CHANGED");
loadFrame:RegisterEvent("GROUP_JOINED");
loadFrame:RegisterEvent("GROUP_LEFT");
loadFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")

loadFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
loadFrame:RegisterEvent("CHALLENGE_MODE_START")

function WeakAuras.RegisterLoadEvents()
  loadFrame:SetScript("OnEvent", function(...)
    WeakAuras.StartProfileSystem("load");
    WeakAuras.ScanForLoads(...)
    WeakAuras.StopProfileSystem("load");
  end);
end

function WeakAuras.ReloadAll()
  WeakAuras.UnloadAll();
  WeakAuras.ScanForLoads();
end

function WeakAuras.UnloadAll()
  for _, v in pairs(triggerState) do
    for i = 0, v.numTriggers - 1 do
      if (v[i]) then
        wipe(v[i]);
      end
    end
  end

  for _, aura in pairs(timers) do
    for _, trigger in pairs(aura) do
      for _, record in pairs(trigger) do
        if (record.handle) then
          timer:CancelTimer(record.handle);
        end
      end
    end
  end
  wipe(timers);

  for id in pairs(conditionChecksTimers.recheckTime) do
    if (conditionChecksTimers.recheckHandle[id]) then
      for _, v in pairs(conditionChecksTimers.recheckHandle[id]) do
        timer:CancelTimer(v);
      end
    end
  end
  wipe(conditionChecksTimers.recheckTime);
  wipe(conditionChecksTimers.recheckHandle);

  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.UnloadAll();
  end
  wipe(loaded);
end

do
  function WeakAuras.LoadDisplay(id)
    WeakAuras.RegisterForGlobalConditions(id);
    triggerState[id].triggers = {};
    triggerState[id].triggerCount = 0;
    triggerState[id].show = false;
    triggerState[id].activeTrigger = nil;
    for _, triggerSystem in pairs(triggerSystems) do
      triggerSystem.LoadDisplay(id);
    end
  end

  function WeakAuras.UnloadDisplay(id)
    for i = 0, triggerState[id].numTriggers - 1 do
      if (triggerState[id][i]) then
        wipe(triggerState[id][i]);
      end
    end
    triggerState[id].show = nil;
    triggerState[id].activeTrigger = nil;

    if (timers[id]) then
      for _, trigger in pairs(timers[id]) do
        for _, record in pairs(trigger) do
          if (record.handle) then
            timer:CancelTimer(record.handle);
          end
        end
      end
      timers[id] = nil;
    end

    conditionChecksTimers.recheckTime[id] = nil;
    if (conditionChecksTimers.recheckHandle[id]) then
      for _, v in pairs(conditionChecksTimers.recheckHandle[id]) do
        timer:CancelTimer(v);
      end
    end
    conditionChecksTimers.recheckHandle[id] = nil;
    WeakAuras.UnregisterForGlobalConditions(id);

    for _, triggerSystem in pairs(triggerSystems) do
      triggerSystem.UnloadDisplay(id);
    end
  end
end

function WeakAuras.Delete(data)
  local id = data.id;
  if(data.parent) then
    local parentData = db.displays[data.parent];
    if(parentData and parentData.controlledChildren) then
      for index, childId in pairs(parentData.controlledChildren) do
        if(childId == id) then
          tremove(parentData.controlledChildren, index);
        end
      end
      if parentData.sortHybridTable then
        parentData.sortHybridTable[id] = nil
      end
    end
  end

  if(data.controlledChildren) then
    for index, childId in pairs(data.controlledChildren) do
      local childData = db.displays[childId];
      if(childData) then
        childData.parent = nil;
        WeakAuras.Add(childData);
      end
    end
  end

  animations[tostring(regions[id].region)] = nil

  WeakAuras.UnregisterCustomTextUpdates(regions[id].region)
  regions[id].region:SetScript("OnUpdate", nil);
  regions[id].region:SetScript("OnShow", nil);
  regions[id].region:SetScript("OnHide", nil);
  regions[id].region:Hide();

  WeakAuras.CollapseAllClones(id);
  db.registered[id] = nil;
  if(WeakAuras.importDisplayButtons and WeakAuras.importDisplayButtons[id]) then
    local button = WeakAuras.importDisplayButtons[id];
    button.checkbox:SetChecked(false);
    if(button.updateChecked) then
      button.updateChecked();
    end
  end

  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.Delete(id);
  end

  regions[id].region = nil;
  regions[id] = nil;
  loaded[id] = nil;
  loadFuncs[id] = nil;
  loadFuncsForOptions[id] = nil;
  checkConditions[id] = nil;
  conditionChecksTimers.recheckTime[id] = nil;
  if (conditionChecksTimers.recheckHandle[id]) then
    for cloneId, v in pairs(conditionChecksTimers.recheckHandle[id]) do
      timer:CancelTimer(v);
    end
  end
  conditionChecksTimers.recheckHandle[id] = nil;

  db.displays[id] = nil;

  aura_environments[id] = nil;
  triggerState[id] = nil;

  if (WeakAuras.personalRessourceDisplayFrame) then
    WeakAuras.personalRessourceDisplayFrame:delete(id);
  end

  if (WeakAuras.mouseFrame) then
    WeakAuras.mouseFrame:delete(id);
  end

  WeakAuras.customActionsFunctions[id] = nil;
  WeakAuras.customConditionsFunctions[id] = nil;

  for event, funcs in pairs(dynamicConditions) do
    funcs[id] = nil;
  end

  WeakAuras.frameLevels[id] = nil;
end

function WeakAuras.Rename(data, newid)
  local oldid = data.id;
  if(data.parent) then
    local parentData = db.displays[data.parent];
    if(parentData.controlledChildren) then
      for index, childId in pairs(parentData.controlledChildren) do
        if(childId == data.id) then
          parentData.controlledChildren[index] = newid;
        end
      end
      if parentData.sortHybridTable and parentData.sortHybridTable[oldid] then
        parentData.sortHybridTable[newid] = true
        parentData.sortHybridTable[oldid] = nil
      end
    end
  end

  regions[newid] = regions[oldid];
  regions[oldid] = nil;
  regions[newid].region.id = newid;

  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.Rename(oldid, newid);
  end

  loaded[newid] = loaded[oldid];
  loaded[oldid] = nil;
  loadFuncs[newid] = loadFuncs[oldid];
  loadFuncs[oldid] = nil;

  loadFuncsForOptions[newid] = loadFuncsForOptions[oldid]
  loadFuncsForOptions[oldid] = nil;

  checkConditions[newid] = checkConditions[oldid];
  checkConditions[oldid] = nil;

  conditionChecksTimers.recheckTime[newid] = conditionChecksTimers.recheckTime[oldid];
  conditionChecksTimers.recheckTime[oldid] = nil;

  conditionChecksTimers.recheckHandle[newid] = conditionChecksTimers.recheckHandle[oldid];
  conditionChecksTimers.recheckHandle[oldid] = nil;

  timers[newid] = timers[oldid];
  timers[oldid] = nil;

  triggerState[newid] = triggerState[oldid];
  triggerState[oldid] = nil;

  db.displays[newid] = db.displays[oldid];
  db.displays[oldid] = nil;

  if(clones[oldid]) then
    clones[newid] = clones[oldid];
    clones[oldid] = nil;
    for cloneid, clone in pairs(clones[newid]) do
      clone.id = newid;
    end
  end

  db.displays[newid].id = newid;

  if(data.controlledChildren) then
    for index, childId in pairs(data.controlledChildren) do
      local childData = db.displays[childId];
      if(childData) then
        childData.parent = data.id;
      end
    end
  end

  for key, animation in pairs(animations) do
    if animation.name == oldid then
      animation.name = newid;
    end
  end

  aura_environments[newid] = aura_environments[oldid] or {};
  aura_environments[newid].id = newid;
  aura_environments[oldid] = nil;

  if (WeakAuras.personalRessourceDisplayFrame) then
    WeakAuras.personalRessourceDisplayFrame:rename(oldid, newid);
  end

  if (WeakAuras.mouseFrame) then
    WeakAuras.mouseFrame:rename(oldid, newid);
  end

  WeakAuras.customActionsFunctions[newid] = WeakAuras.customActionsFunctions[oldid];
  WeakAuras.customActionsFunctions[oldid] = nil;

  WeakAuras.customConditionsFunctions[newid] = WeakAuras.customConditionsFunctions[oldid];
  WeakAuras.customConditionsFunctions[oldid] = nil;

  for event, funcs in pairs(dynamicConditions) do
    funcs[newid] = funcs[oldid]
    funcs[oldid] = nil;
  end

  WeakAuras.frameLevels[newid] = WeakAuras.frameLevels[oldid];
  WeakAuras.frameLevels[oldid] = nil;

  WeakAuras.ProfileRenameAura(oldid, newid);
end

function WeakAuras.Convert(data, newType)
  local id = data.id;
  regions[id].region:SetScript("OnUpdate", nil);
  regions[id].region:Hide();
  WeakAuras.EndEvent(id, 0, true);

  regions[id].region = nil;
  regions[id] = nil;

  data.regionType = newType;
  WeakAuras.Add(data);
end

function WeakAuras.DeepCopy(source, dest)
  local function recurse(source, dest)
    for i,v in pairs(source) do
      if(type(v) == "table") then
        dest[i] = type(dest[i]) == "table" and dest[i] or {};
        recurse(v, dest[i]);
      else
        dest[i] = v;
      end
    end
  end
  recurse(source, dest);
end

function WeakAuras.Copy(sourceid, destid)
  local sourcedata = db.displays[sourceid];
  local destdata = db.displays[destid];
  if(sourcedata and destdata) then
    local oldParent = destdata.parent;
    local oldChildren = destdata.controlledChildren;
    wipe(destdata);
    WeakAuras.DeepCopy(sourcedata, destdata);
    destdata.id = destid;
    destdata.parent = oldParent;
    destdata.controlledChildren = oldChildren;
    WeakAuras.Add(destdata);
  end
end

function WeakAuras.RegisterAddon(addon, displayName, description, icon)
  if(addons[addon]) then
    addons[addon].displayName = displayName;
    addons[addon].description = description;
    addons[addon].icon = icon;
    addons[addon].displays = addons[addon].displays or {};
  else
    addons[addon] = {
      displayName = displayName,
      description = description,
      icon = icon,
      displays = {}
    };
  end
end

function WeakAuras.RegisterDisplay(addon, data, force)
  tinsert(from_files, {addon, data, force});
end

function WeakAuras.AddManyFromAddons(table)
  for _, addData in ipairs(table) do
    WeakAuras.AddFromAddon(addData[1], addData[2], addData[3]);
  end
end

function WeakAuras.AddFromAddon(addon, data, force)
  local id = data.id;
  if(id and addons[addon]) then
    addons[addon].displays[id] = data;
    if(db.registered[id]) then
    -- This display was already registered
    -- It is unnecessary to add it again
    elseif(force and not db.registered[id] == false) then
      if(db.displays[id]) then
        -- ID collision
        collisions[id] = {addon, data};
      else
        db.registered[id] = addon;
        WeakAuras.Add(data);
      end
    end
  end
end

function WeakAuras.CollisionResolved(addon, data, force)
  WeakAuras.AddFromAddon(addon, data, force);
end

function WeakAuras.IsDefinedByAddon(id)
  return db.registered[id];
end

function WeakAuras.ResolveCollisions(onFinished)
  local num = 0;
  for id, _ in pairs(collisions) do
    num = num + 1;
  end

  if(num > 0) then
    local baseText;
    local buttonText;
    if(registeredFromAddons) then
      if(num == 1) then
        baseText = L["Resolve collisions dialog singular"];
        buttonText = L["Done"];
      else
        baseText = L["Resolve collisions dialog"];
        buttonText = L["Next"];
      end
    else
      if(num == 1) then
        baseText = L["Resolve collisions dialog startup singular"];
        buttonText = L["Done"];
      else
        baseText = L["Resolve collisions dialog startup"];
        buttonText = L["Next"];
      end
    end

    local numResolved = 0;
    local currentId = next(collisions);

    local function UpdateText(popup)
      popup.text:SetText(baseText..(numResolved or "error").."/"..(num or "error"));
    end

    StaticPopupDialogs["WEAKAURAS_RESOLVE_COLLISIONS"] = {
      text = baseText,
      button1 = buttonText,
      OnAccept = function(self)
        -- Do the collision resolution
        local newId = self.editBox:GetText();
        if(WeakAuras.OptionsFrame and WeakAuras.OptionsFrame() and WeakAuras.displayButtons and WeakAuras.displayButtons[currentId]) then
          WeakAuras.displayButtons[currentId].callbacks.OnRenameAction(newId)
        else
          local data = WeakAuras.GetData(currentId);
          if(data) then
            WeakAuras.Rename(data, newId);
          else
            print("|cFF8800FFWeakAuras|r: Data not found");
          end
        end

        WeakAuras.CollisionResolved(collisions[currentId][1], collisions[currentId][2], true);
        numResolved = numResolved + 1;

        -- Get the next id to resolve
        currentId = next(collisions, currentId);
        if(currentId) then
          -- There is another conflict to resolve - hook OnHide to reshow the dialog as soon as it hides
          self:SetScript("OnHide", function(self)
            self:Show();
            UpdateText(self);
            self.editBox:SetText(currentId);
            self:SetScript("OnHide", nil);
            if not(next(collisions, currentId)) then
              self.button1:SetText(L["Done"]);
            end
          end);
        else
          self.editBox:SetScript("OnTextChanged", nil);
          wipe(collisions);
          if(onFinished) then
            onFinished();
          end
        end
      end,
      hasEditBox = true,
      hasWideEditBox = true,
      hideOnEscape = true,
      whileDead = true,
      showAlert = true,
      timeout = 0,
      preferredindex = STATICPOPUP_NUMDIALOGS
    };

    local popup = StaticPopup_Show("WEAKAURAS_RESOLVE_COLLISIONS");
    popup.editBox:SetScript("OnTextChanged", function(self)
      local newid = self:GetText();
      if(collisions[newid] or db.displays[newid]) then
        popup.button1:Disable();
      else
        popup.button1:Enable();
      end
    end);
    popup.editBox:SetText(currentId);
    popup.text:SetJustifyH("left");
    popup.icon:SetTexture("Interface\\Addons\\WeakAuras\\Media\\Textures\\icon.blp");
    popup.icon:SetVertexColor(0.833, 0, 1);

    UpdateText(popup);
  elseif(onFinished) then
    onFinished();
  end
end

local function ModernizeAnimation(animation)
  if (type(animation) ~= "string") then
    return nil;
  end
  return animation:gsub("^%s*return%s*", "");
end

local function ModernizeAnimations(animations)
  if (not animations) then
    return;
  end
  animations.alphaFunc     = ModernizeAnimation(animations.alphaFunc);
  animations.translateFunc = ModernizeAnimation(animations.translateFunc);
  animations.scaleFunc     = ModernizeAnimation(animations.scaleFunc);
  animations.rotateFunc    = ModernizeAnimation(animations.rotateFunc);
  animations.colorFunc     = ModernizeAnimation(animations.colorFunc);
end

-- Takes as input a table of display data and attempts to update it to be compatible with the current version
function WeakAuras.Modernize(data)
  if (not data.internalVersion) then
    data.internalVersion = 1;
  end

  -- Version 2 was introduced April 2018 in Legion
  if (data.internalVersion < 2) then
    -- Add trigger count
    if not data.numTriggers then
      data.numTriggers = 1 + (data.additional_triggers and #data.additional_triggers or 0)
    end

    local load = data.load;

    if (not load.ingroup) then
      load.ingroup = {};
      if (load.use_ingroup == true) then
        load.ingroup.single = nil;
        load.ingroup.multi = {
          ["group"] = true,
          ["raid"] = true
        };
        load.use_ingroup = false;
      elseif (load.use_ingroup == false) then
        load.ingroup.single = "solo";
        load.ingroup.multi = {};
        load.use_ingroup = true;
      end
    end


    -- Convert load options into single/multi format
    for index, prototype in pairs(WeakAuras.load_prototype.args) do
      local protoname = prototype.name;
      if(prototype.type == "multiselect") then
        if(not load[protoname] or type(load[protoname]) ~= "table") then
          local value = load[protoname];
          load[protoname] = {};
          if(value) then
            load[protoname].single = value;
          end
        end
        load[protoname].multi = load[protoname].multi or {};
      elseif(load[protoname] and type(load[protoname]) == "table") then
        load[protoname] = nil;
      end
    end

    -- upgrade from singleselecting talents to multi select, see ticket 52
    if (type(load.talent) == "number") then
      local talent = load.talent;
      load.talent = {};
      load.talent.single = talent;
      load.talent.multi = {}
    end


    --upgrade to support custom trigger combination logic
    if (data.disjunctive == true) then
      data.disjunctive = "any";
    end
    if(data.disjunctive == false) then
      data.disjunctive = "all";
    end

    -- Change English-language class tokens to locale-agnostic versions
    local class_agnosticize = {
      ["Death Knight"] = "DEATHKNIGHT",
      ["Druid"] = "DRUID",
      ["Hunter"] = "HUNTER",
      ["Mage"] = "MAGE",
      ["Monk"] = "MONK",
      ["Paladin"] = "PALADIN",
      ["Priest"] = "PRIEST",
      ["Rogue"] = "ROGUE",
      ["Shaman"] = "SHAMAN",
      ["Warlock"] = "WARLOCK",
      ["Warrior"] = "WARRIOR"
    };

    if(load.class.single) then
      load.class.single = class_agnosticize[load.class.single] or load.class.single;
    end

    if(load.class.multi) then
      for i,v in pairs(load.class.multi) do
        if(class_agnosticize[i]) then
          load.class.multi[class_agnosticize[i]] = true;
          load.class.multi[i] = nil;
        end
      end
    end

    -- Add dynamic text info to Progress Bars
    -- Also convert custom displayText to new displayText
    if(data.regionType == "aurabar") then
      data.displayTextLeft = data.displayTextLeft or (not data.auto and data.displayText) or "%n";
      data.displayTextRight = data.displayTextRight or "%p";

      if (data.barInFront ~= nil) then
        data.borderInFront = not data.barInFront;
        data.backdropInFront = not data.barInFront;
        data.barInFront = nil;
      end
    end

    if(data.regionType == "icon") then
      if (data.cooldownTextEnabled == nil) then
        data.cooldownTextEnabled = true;
      end
      if (data.displayStacks) then
        data.text1Enabled = true;
        data.text1 = data.displayStacks;
        data.displayStacks = nil;
        data.text1Color = data.textColor;
        data.textColor = nil;
        data.text1Point = data.stacksPoint;
        data.stacksPoint = nil;
        data.text1Containment = data.stacksContainment;
        data.stacksContainment = nil;
        data.text1Font = data.font;
        data.font = nil;
        data.text1FontSize = data.fontSize;
        data.fontSize = nil;
        data.text1FontFlags = data.fontFlags;
        data.fontFlags = nil;

        data.text2Enabled = false;
        data.text2 = "%p";
        data.text2Color = {1, 1, 1, 1};
        data.text2Point = "CENTER";
        data.text2Containment = "INSIDE";
        data.text2Font = "Friz Quadrata TT";
        data.text2FontSize = 24;
        data.text2FontFlags = "OUTLINE";
      end
    end

    -- Upgrade some old variables
    if data.regionType == "aurabar" then
      -- "border" changed to "borderEdge"
      if data.border and type(data.border) ~= "boolean" then
        data.borderEdge = data.border;
        data.border = data.borderEdge ~= "None";
      end
      -- Multiple text settings
      if data.textColor then
        if not data.timerColor then
          data.timerColor = {};
          data.timerColor[1] = data.textColor[1];
          data.timerColor[2] = data.textColor[2];
          data.timerColor[3] = data.textColor[3];
          data.timerColor[4] = data.textColor[4];
        end
        if not data.stacksColor then
          data.stacksColor = {};
          data.stacksColor[1] = data.textColor[1];
          data.stacksColor[2] = data.textColor[2];
          data.stacksColor[3] = data.textColor[3];
          data.stacksColor[4] = data.textColor[4];
        end
      end
      -- Multiple text settings
      if data.font then
        if not data.textFont then
          data.textFont = data.font;
        end
        if not data.timerFont then
          data.timerFont = data.font;
        end
        if not data.stacksFont then
          data.stacksFont = data.font;
        end

        data.font = nil;
      end
      -- Multiple text settings
      if data.fontSize then
        if not data.textSize then
          data.textSize = data.fontSize;
        end
        if not data.timerSize then
          data.timerSize = data.fontSize;
        end
        if not data.stacksSize then
          data.stacksSize = data.fontSize;
        end

        data.fontSize = nil;
      end

      -- fontFlags (outline)
      if not data.fontFlags then
        data.fontFlags = "OUTLINE";
      end
    end

    if data.regionType == "text" then
      if (type(data.outline) == "boolean") then
        data.outline = data.outline and "OUTLINE" or "None";
      end
    end

    if data.regionType == "model" then
      if (data.api == nil) then
        data.api = false;
      end
    end

    if (data.regionType == "progresstexture") then
      if (not data.version or data.version < 2) then
        if (data.orientation == "CLOCKWISE") then
          if (data.inverse) then
            data.startAngle, data.endAngle = 360 - data.endAngle, 360 - data.startAngle;
            data.orientation = (data.orientation == "CLOCKWISE") and "ANTICLOCKWISE" or "CLOCKWISE";
          end
        elseif (data.orientation == "ANTICLOCKWISE") then
          data.startAngle, data.endAngle = 360 - data.endAngle, 360 - data.startAngle;
          if (data.inverse) then
            data.orientation = (data.orientation == "CLOCKWISE") and "ANTICLOCKWISE" or "CLOCKWISE";
          end
        end
        data.version = 2;
      end
    end

    if (not data.activeTriggerMode) then
      data.activeTriggerMode = 0;
    end

    if (data.sort == "hybrid") then
      if (not data.hybridPosition) then
        data.hybridPosition = "hybridLast";
      end
      if (not data.hybridSortMode) then
        data.hybridSortMode = "descending";
      end
    end

    if (data.conditions) then
      for conditionIndex, condition in ipairs(data.conditions) do
        if (not condition.check) then
          condition.check = {
            ["trigger"] = condition.trigger,
            ["variable"] = condition.condition,
            ["op"] = condition.op,
            ["value"] = condition.value
          };
          condition.trigger = nil;
          condition.condition = nil;
          condition.op = nil;
          condition.value = nil;
        end
      end
    end
    ModernizeAnimations(data.animation and data.animation.start);
    ModernizeAnimations(data.animation and data.animation.main);
    ModernizeAnimations(data.animation and data.animation.finish);
  end -- ENd of V1 => V2

  -- Version 3 was introduced April 2018 in Legion
  if (data.internalVersion < 3) then
    if (data.parent) then
      local parentData = WeakAuras.GetData(data.parent);
      if(parentData and parentData.regionType == "dynamicgroup") then
        -- Version 3 allowed for offsets for dynamic groups, before that they were ignored
        -- Thus reset them in the V2 to V3 upgrade
        data.xOffset = 0;
        data.yOffset = 0;
      end
    end
  end

  -- Version 4 was introduced July 2018 in BfA
  if (data.internalVersion < 4) then
    if (data.conditions) then
      for conditionIndex, condition in ipairs(data.conditions) do
        if (condition.check) then
          local triggernum = condition.check.trigger;
          if (triggernum) then
            local trigger;
            if (triggernum == 0) then
              trigger = data.trigger;
            elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
              trigger = data.additional_triggers[triggernum].trigger;
            end
            if (trigger and trigger.event == "Cooldown Progress (Spell)") then
              if (condition.check.variable == "stacks") then
                condition.check.variable = "charges";
              end
            end
          end
        end
      end
    end
  end

  -- Version 5 was introduced July 2018 in BFA
  if data.internalVersion < 5 then
    -- this is to fix hybrid sorting
    if data.sortHybridTable then
      if data.controlledChildren then
        local newSortTable = {}
        for index, isHybrid in pairs(data.sortHybridTable) do
          local childID = data.controlledChildren[index]
          if childID then
            newSortTable[childID] = isHybrid
          end
        end
        data.sortHybridTable = newSortTable
      end
    end
  end

  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.Modernize(data);
  end

  data.internalVersion = internalVersion;
end

function WeakAuras.SyncParentChildRelationships(silent)
  local childToParent = {};
  local parentToChild = {};
  for id, data in pairs(db.displays) do
    if(data.parent) then
      if(data.controlledChildren) then
        if not(silent) then
          print("|cFF8800FFWeakAuras|r detected desynchronization in saved variables:", id, "has both child and parent");
        end
        -- A display cannot have both children and a parent
        data.parent = nil;
      elseif(db.displays[data.parent] and db.displays[data.parent].controlledChildren) then
        childToParent[id] = data.parent;
        parentToChild[data.parent] = parentToChild[data.parent] or {};
        parentToChild[data.parent][id] = true;
      else
        if not(silent) then
          print("|cFF8800FFWeakAuras|r detected desynchronization in saved variables:", id, "has a nonexistent parent");
        end
        data.parent = nil;
      end
    end
  end

  for id, data in pairs(db.displays) do
    if(data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        if not(childToParent[childId] and childToParent[childId] == id) then
          if not(silent) then
            print("|cFF8800FFWeakAuras|r detected desynchronization in saved variables:", id, "thinks it controls", childId, "but does not");
          end
          tremove(data.controlledChildren, index);
        end
      end

      if(parentToChild[id]) then
        for childId, _ in pairs(parentToChild[id]) do
          if not(tContains(data.controlledChildren, childId)) then
            if not(silent) then
              print("|cFF8800FFWeakAuras|r detected desynchronization in saved variables:", id, "does not control", childId, "but should");
            end
            tinsert(data.controlledChildren, childId);
          end
        end
      end
    end
  end
end

function WeakAuras.AddMany(table)
  local idtable = {};
  for _, data in ipairs(table) do
    idtable[data.id] = data;
  end
  local loaded = {};
  local function load(id, depends)
    local data = idtable[id];
    if(data.parent) then
      if(idtable[data.parent]) then
        if(tContains(depends, data.parent)) then
          error("Circular dependency in WeakAuras.AddMany between "..tconcat(depends, ", "));
        else
          if not(loaded[data.parent]) then
            local dependsOut = {};
            for i,v in pairs(depends) do
              dependsOut[i] = v;
            end
            tinsert(dependsOut, data.parent);
            load(data.parent, dependsOut);
          end
        end
      else
        data.parent = nil;
      end
    end
    if not(loaded[id]) then
      WeakAuras.Add(data);
      loaded[id] = true;
    end
  end
  local groups = {}
  for id, data in pairs(idtable) do
    load(id, {});
    if data.regionType == "dynamicgroup" or data.regionType == "group" then
      groups[data] = true
    end
  end
  for data in pairs(groups) do
    if data.type == "dynamicgroup" then
      regions[data.id].region:ControlChildren()
    else
      WeakAuras.Add(data)
    end
  end
end

local function removeSpellNames(data)
  local trigger
  for triggernum=0,(data.numTriggers or 9) do
    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end
    if type(trigger.spellName) == "number" then
      trigger.realSpellName = GetSpellInfo(trigger.spellName) or trigger.realSpellName
    end
    if (trigger.spellId) then
      trigger.name = GetSpellInfo(trigger.spellId) or trigger.name;
    end
    if (trigger.spellIds) then
      for i = 1, 10 do
        if (trigger.spellIds[i]) then
          trigger.names = trigger.names or {};
          trigger.names[i] = GetSpellInfo(trigger.spellIds[i]) or trigger.names[i];
        end
      end
    end
  end
end

function WeakAuras.PreAdd(data)
  WeakAuras.validate(data, WeakAuras.data_stub)
  local default = data.regionType and WeakAuras.regionTypes[data.regionType].default
  if not default then error('no default regionType') end
  WeakAuras.validate(data, default)
  WeakAuras.Modernize(data);
  removeSpellNames(data)
end

local function pAdd(data)
  local id = data.id;
  if not(id) then
    error("Improper arguments to WeakAuras.Add - id not defined");
  elseif (data.controlledChildren) then
    WeakAuras.SetRegion(data);
  else
    if (not data.activeTriggerMode or data.activeTriggerMode >= data.numTriggers) then
      data.activeTriggerMode = WeakAuras.trigger_modes.first_active;
    end

    for _, triggerSystem in pairs(triggerSystems) do
      triggerSystem.Add(data);
    end


    data.init_started = nil;
    data.load = data.load or {};
    data.actions = data.actions or {};
    data.actions.init = data.actions.init or {};
    data.actions.start = data.actions.start or {};
    data.actions.finish = data.actions.finish or {};
    local loadFuncStr = WeakAuras.ConstructFunction(load_prototype, data.load);
    local loadForOptionsFuncStr = WeakAuras.ConstructFunction(load_prototype, data.load, true);
    local loadFunc = WeakAuras.LoadFunction(loadFuncStr);
    local loadForOptionsFunc = WeakAuras.LoadFunction(loadForOptionsFuncStr);
    local triggerLogicFunc = WeakAuras.LoadFunction("return "..(data.customTriggerLogic or ""), id);
    WeakAuras.LoadCustomActionFunctions(data);
    WeakAuras.LoadConditionPropertyFunctions(data);
    local checkConditionsFuncStr = WeakAuras.ConstructConditionFunction(data);
    local checkCondtionsFunc = checkConditionsFuncStr and WeakAuras.LoadFunction(checkConditionsFuncStr, id);
    debug(id.." - Load", 1);
    debug(loadFuncStr);

    loadFuncs[id] = loadFunc;
    loadFuncsForOptions[id] = loadForOptionsFunc;
    checkConditions[id] = checkCondtionsFunc;
    clones[id] = clones[id] or {};

    if (timers[id]) then
      for _, trigger in pairs(timers[id]) do
        for _, record in pairs(trigger) do
          if (record.handle) then
            timer:CancelTimer(record.handle);
          end
        end
      end
      timers[id] = nil;
    end

    triggerState[id] = {
      disjunctive = data.disjunctive or "all",
      numTriggers = data.numTriggers,
      activeTriggerMode = data.activeTriggerMode or 0,
      triggerLogicFunc = triggerLogicFunc,
      triggers = {},
      triggerCount = 0,
      activatedConditions = {},
    };

    local region = WeakAuras.SetRegion(data);
    if (WeakAuras.clones[id]) then
      for cloneId, _ in pairs(WeakAuras.clones[id]) do
        WeakAuras.SetRegion(data, cloneId);
      end
    end

    WeakAuras.LoadEncounterInitScripts(id);

    if not(paused) then
      region:Collapse();
      WeakAuras.ScanForLoads();
    end
  end

  removeSpellNames(data);
  db.displays[id] = data;
end

-- Dummy add function to protect errors from propagating out of the real add function
function WeakAuras.Add(data)
  WeakAuras.PreAdd(data)
  pAdd(data);
end

function WeakAuras.SetRegion(data, cloneId)
  local regionType = data.regionType;
  if not(regionType) then
    error("Improper arguments to WeakAuras.SetRegion - regionType not defined");
  else
    if(not regionTypes[regionType]) then
      regionType = "fallback";
      print("Improper arguments to WeakAuras.CreateRegion - regionType \""..data.regionType.."\" is not supported");
    end

    local id = data.id;
    if not(id) then
      error("Improper arguments to WeakAuras.SetRegion - id not defined");
    else
      local region;
      if(cloneId) then
        region = clones[id][cloneId];
        if (not region or region.regionType ~= data.regionType) then
          if (region) then
            clonePool[region.regionType] = clonePool[region.regionType] or {};
            tinsert(clonePool[region.regionType], region);
            region:Hide();
          end
          if(clonePool[data.regionType] and clonePool[data.regionType][1]) then
            clones[id][cloneId] = tremove(clonePool[data.regionType]);
          else
            local clone = regionTypes[data.regionType].create(frame, data);
            clone.regionType = data.regionType;
            clone:Hide();
            clones[id][cloneId] = clone;
          end
          region = clones[id][cloneId];
        end
      else
        if((not regions[id]) or (not regions[id].region) or regions[id].regionType ~= regionType) then
          region = regionTypes[regionType].create(frame, data);
          region.regionType = regionType;
          region.toShow = true;
          regions[id] = {
            regionType = regionType,
            region = region
          };
        else
          region = regions[id].region;
        end
      end
      region.id = id;
      region.cloneId = cloneId or "";
      WeakAuras.validate(data, regionTypes[regionType].default);

      local parent = frame;
      if(data.parent) then
        if(regions[data.parent]) then
          parent = regions[data.parent].region;
        else
          data.parent = nil;
        end
      end

      local anim_cancelled = WeakAuras.CancelAnimation(region, true, true, true, true, true);

      regionTypes[regionType].modify(parent, region, data);
      WeakAuras.regionPrototype.AddSetDurationInfo(region);
      local parentRegionType = data.parent and db.displays[data.parent] and db.displays[data.parent].regionType;
      WeakAuras.regionPrototype.AddExpandFunction(data, region, id, cloneId, parent, parentRegionType)


      data.animation = data.animation or {};
      data.animation.start = data.animation.start or {type = "none"};
      data.animation.main = data.animation.main or {type = "none"};
      data.animation.finish = data.animation.finish or {type = "none"};
      if(WeakAuras.CanHaveDuration(data)) then
        data.animation.start.duration_type = data.animation.start.duration_type or "seconds";
        data.animation.main.duration_type = data.animation.main.duration_type or "seconds";
        data.animation.finish.duration_type = data.animation.finish.duration_type or "seconds";
      else
        data.animation.start.duration_type = "seconds";
        data.animation.main.duration_type = "seconds";
        data.animation.finish.duration_type = "seconds";
      end

      if(cloneId) then
        clonePool[regionType] = clonePool[regionType] or {};
      end

      if(anim_cancelled) then
        WeakAuras.Animate("display", data, "main", data.animation.main, region, false, nil, true, cloneId);
      end
      return region;
    end
  end
end

function WeakAuras.EnsureClone(id, cloneId)
  clones[id] = clones[id] or {};
  if not(clones[id][cloneId]) then
    local data = WeakAuras.GetData(id);
    WeakAuras.SetRegion(data, cloneId);
    clones[id][cloneId].justCreated = true;
  end
  return clones[id][cloneId];
end

function WeakAuras.GetRegion(id, cloneId)
  if(cloneId and cloneId ~= "") then
    return WeakAuras.EnsureClone(id, cloneId);
  end
  return WeakAuras.regions[id] and WeakAuras.regions[id].region;
end

function WeakAuras.CollapseAllClones(id, triggernum)
  if(clones[id]) then
    for i,v in pairs(clones[id]) do
      v:Collapse();
    end
  end
end

function WeakAuras.SetAllStatesHidden(id, triggernum)
  local triggerState = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
  for id, state in pairs(triggerState) do
    state.show = false;
    state.changed = true;
  end
end

function WeakAuras.SetAllStatesHiddenExcept(id, triggernum, list)
  local triggerState = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
  for cloneId, state in  pairs(triggerState) do
    if (not (list[cloneId])) then
      state.show = false;
      state.changed = true;
    end
  end
end

function WeakAuras.ReleaseClone(id, cloneId, regionType)
  if (not clones[id]) then
    return;
  end
  local region = clones[id][cloneId];
  clones[id][cloneId] = nil;
  clonePool[regionType][#clonePool[regionType] + 1] = region;
end

function WeakAuras.HandleChatAction(message_type, message, message_dest, message_channel, r, g, b, region, customFunc)
  if (message:find('%%')) then
    message = WeakAuras.ReplacePlaceHolders(message, region, customFunc);
  end
  if(message_type == "PRINT") then
    DEFAULT_CHAT_FRAME:AddMessage(message, r or 1, g or 1, b or 1);
  elseif(message_type == "COMBAT") then
    if(CombatText_AddMessage) then
      CombatText_AddMessage(message, COMBAT_TEXT_SCROLL_FUNCTION, r or 1, g or 1, b or 1);
    end
  elseif(message_type == "WHISPER") then
    if(message_dest) then
      if(message_dest == "target" or message_dest == "'target'" or message_dest == "\"target\"" or message_dest == "%t" or message_dest == "'%t'" or message_dest == "\"%t\"") then
        pcall(function() SendChatMessage(message, "WHISPER", nil, UnitName("target")) end);
      else
        pcall(function() SendChatMessage(message, "WHISPER", nil, message_dest) end);
      end
    end
  elseif(message_type == "CHANNEL") then
    local channel = message_channel and tonumber(message_channel);
    if(GetChannelName(channel)) then
      pcall(function() SendChatMessage(message, "CHANNEL", nil, channel) end);
    end
  elseif(message_type == "SMARTRAID") then
    local isInstanceGroup = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
    if UnitInBattleground("player") then
      pcall(function() SendChatMessage(message, "INSTANCE_CHAT") end)
    elseif UnitInRaid("player") then
      pcall(function() SendChatMessage(message, "RAID") end)
    elseif UnitInParty("player") then
      if isInstanceGroup then
        pcall(function() SendChatMessage(message, "INSTANCE_CHAT") end)
      else
        pcall(function() SendChatMessage(message, "PARTY") end)
      end
    else
      pcall(function() SendChatMessage(message, "SAY") end)
    end
  else
    pcall(function() SendChatMessage(message, message_type, nil, nil) end);
  end
end

function WeakAuras.PerformActions(data, type, region)
  if (paused) then
    return;
  end;
  local actions;
  if(type == "start") then
    actions = data.actions.start;
  elseif(type == "finish") then
    actions = data.actions.finish;
  else
    return;
  end

  if(actions.do_message and actions.message_type and actions.message and not squelch_actions) then
    local customFunc = WeakAuras.customActionsFunctions[data.id][type .. "_message"];
    WeakAuras.HandleChatAction(actions.message_type, actions.message, actions.message_dest, actions.message_channel, actions.r, actions.g, actions.b, region, customFunc);
  end

  if (actions.stop_sound) then
    if (region.SoundStop) then
      region:SoundStop();
    end
  end

  if(actions.do_sound and actions.sound) then
    if (region.SoundPlay) then
      region:SoundPlay(actions);
    end
  end

  if(actions.do_custom and actions.custom and not squelch_actions) then
    local func = WeakAuras.customActionsFunctions[data.id][type]
    if func then
      WeakAuras.ActivateAuraEnvironment(region.id, region.cloneId, region.state);
      xpcall(func, geterrorhandler());
      WeakAuras.ActivateAuraEnvironment(nil);
    end
  end

  -- Apply start glow actions even if squelch_actions is true, but don't apply finish glow actions
  local squelch_glow = squelch_actions and (type == "finish");
  if(actions.do_glow and actions.glow_action and actions.glow_frame and not squelch_glow) then
    local glow_frame
    local original_glow_frame
    if(actions.glow_frame:sub(1, 10) == "WeakAuras:") then
      local frame_name = actions.glow_frame:sub(11);
      if(regions[frame_name]) then
        glow_frame = regions[frame_name].region;
      end
    else
      glow_frame = exec_env[actions.glow_frame];
      original_glow_frame = glow_frame
    end

    if (glow_frame) then
      if (not glow_frame.__WAGlowFrame) then
        glow_frame.__WAGlowFrame = CreateFrame("Frame", nil, glow_frame);
        glow_frame.__WAGlowFrame:SetAllPoints(glow_frame);
        glow_frame.__WAGlowFrame:SetSize(glow_frame:GetSize());
      end
      glow_frame = glow_frame.__WAGlowFrame;
    end

    if(glow_frame) then
      if(actions.glow_action == "show") then
        WeakAuras_ShowOverlayGlow(glow_frame);
      elseif(actions.glow_action == "hide") then
        WeakAuras_HideOverlayGlow(glow_frame);
        if original_glow_frame then
          WeakAuras_HideOverlayGlow(original_glow_frame);
        end
      end
    end
  end
end

local updatingAnimations;
local last_update = GetTime();
function WeakAuras.UpdateAnimations()
  WeakAuras.StartProfileSystem("animations");
  for groupId, groupRegion in pairs(pending_controls) do
    pending_controls[groupId] = nil;
    groupRegion:DoControlChildren();
  end
  local time = GetTime();
  local elapsed = time - last_update;
  last_update = time;
  local num = 0;
  for id, anim in pairs(animations) do
    WeakAuras.StartProfileAura(anim.name);
    num = num + 1;
    local finished = false;
    if(anim.duration_type == "seconds") then
      if anim.duration > 0 then
        anim.progress = anim.progress + (elapsed / anim.duration);
      else
        anim.progress = anim.progress + (elapsed / 1);
      end
      if(anim.progress >= 1) then
        anim.progress = 1;
        finished = true;
      end
    elseif(anim.duration_type == "relative") then
      local state = anim.region.state;
      if (not state
        or (state.progressType == "timed" and state.duration < 0.01)
        or (state.progressType == "static" and state.value < 0.01)) then
        anim.progress = 0;
        if(anim.type == "start" or anim.type == "finish") then
          finished = true;
        end
      else
        local relativeProgress = 0;
        if(state.progressType == "static") then
          relativeProgress = state.value / state.total;
        elseif (state.progressType == "timed") then
          relativeProgress = 1 - ((state.expirationTime - time) / state.duration);
        end
        relativeProgress = state.inverse and (1 - relativeProgress) or relativeProgress;
        anim.progress = relativeProgress / anim.duration
        local iteration = math.floor(anim.progress);
        --anim.progress = anim.progress - iteration;
        if not(anim.iteration) then
          anim.iteration = iteration;
        elseif(anim.iteration ~= iteration) then
          anim.iteration = nil;
          finished = true;
        end
      end
    else
      anim.progress = 1;
    end
    local progress = anim.inverse and (1 - anim.progress) or anim.progress;
    WeakAuras.ActivateAuraEnvironment(anim.name, anim.cloneId, anim.region.state);
    if(anim.translateFunc) then
      if (anim.region.SetOffsetAnim) then
        local ok, x, y = xpcall(anim.translateFunc, geterrorhandler(), progress, 0, 0, anim.dX, anim.dY);
        anim.region:SetOffsetAnim(x, y);
      else
        anim.region:ClearAllPoints();
        local ok, x, y = xpcall(anim.translateFunc, geterrorhandler(), progress, anim.startX, anim.startY, anim.dX, anim.dY);
        if (ok) then
          anim.region:SetPoint(anim.selfPoint, anim.anchor, anim.anchorPoint, x, y);
        end
      end
    end
    if(anim.alphaFunc) then
      local ok, alpha = xpcall(anim.alphaFunc, geterrorhandler(), progress, anim.startAlpha, anim.dAlpha);
      if (ok) then
        if (anim.region.SetAnimAlpha) then
          anim.region:SetAnimAlpha(alpha);
        else
          anim.region:SetAlpha(alpha);
        end
      end
    end
    if(anim.scaleFunc) then
      local ok, scaleX, scaleY = xpcall(anim.scaleFunc, geterrorhandler(), progress, 1, 1, anim.scaleX, anim.scaleY);
      if (ok) then
        if(anim.region.Scale) then
          anim.region:Scale(scaleX, scaleY);
        else
          anim.region:SetWidth(anim.startWidth * scaleX);
          anim.region:SetHeight(anim.startHeight * scaleY);
        end
      end
    end
    if(anim.rotateFunc and anim.region.Rotate) then
      local ok, rotate = xpcall(anim.rotateFunc, geterrorhandler(), progress, anim.startRotation, anim.rotate);
      if (ok) then
        anim.region:Rotate(rotate);
      end
    end
    if(anim.colorFunc and anim.region.ColorAnim) then
      local startR, startG, startB, startA = anim.region:GetColor();
      startR, startG, startB, startA = startR or 1, startG or 1, startB or 1, startA or 1;
      local ok, r, g, b, a = xpcall(anim.colorFunc, geterrorhandler(), progress, startR, startG, startB, startA, anim.colorR, anim.colorG, anim.colorB, anim.colorA);
      if (ok) then
        anim.region:ColorAnim(r, g, b, a);
      end
    end
    WeakAuras.ActivateAuraEnvironment(nil);
    if(finished) then
      if not(anim.loop) then
        if (anim.region.SetOffsetAnim) then
          anim.region:SetOffsetAnim(0, 0);
        else
          if(anim.startX) then
            anim.region:SetPoint(anim.selfPoint, anim.anchor, anim.anchorPoint, anim.startX, anim.startY);
          end
        end
        if (anim.region.SetAnimAlpha) then
          anim.region:SetAnimAlpha(nil);
        elseif(anim.startAlpha) then
          anim.region:SetAlpha(anim.startAlpha);
        end
        if(anim.startWidth) then
          if(anim.region.Scale) then
            anim.region:Scale(1, 1);
          else
            anim.region:SetWidth(anim.startWidth);
            anim.region:SetHeight(anim.startHeight);
          end
        end
        if(anim.startRotation) then
          if(anim.region.Rotate) then
            anim.region:Rotate(anim.startRotation);
          end
        end
        if(anim.region.ColorAnim) then
          anim.region:ColorAnim(nil);
        end
        animations[id] = nil;
      end

      if(anim.loop) then
        WeakAuras.Animate(anim.namespace, anim.data, anim.type, anim.anim, anim.region, anim.inverse, anim.onFinished, anim.loop, anim.cloneId);
      elseif(anim.onFinished) then
        anim.onFinished();
      end
    end
    WeakAuras.StopProfileAura(anim.name);
  end
  -- XXX: I tried to have animations only update if there are actually animation data to animate upon.
  -- This caused all start animations to break, and I couldn't figure out why.
  -- May revisit at a later time.
  --[[
  if(num == 0) then
  WeakAuras.debug("Animation stopped", 3);
  frame:SetScript("OnUpdate", nil);
  updatingAnimations = nil;
  updatingAnimations = nil;
  end
  ]]--

  WeakAuras.StopProfileSystem("animations");
end

function WeakAuras.Animate(namespace, data, type, anim, region, inverse, onFinished, loop, cloneId)
  local id = data.id;
  local key = tostring(region);
  local valid;
  if(anim and anim.type == "custom" and (anim.use_translate or anim.use_alpha or (anim.use_scale and region.Scale) or (anim.use_rotate and region.Rotate) or (anim.use_color and region.Color))) then
    valid = true;
  elseif(anim and anim.type == "preset" and anim.preset and anim_presets[anim.preset]) then
    anim = anim_presets[anim.preset];
    valid = true;
  end
  if(valid) then
    local progress, duration, selfPoint, anchor, anchorPoint, startX, startY, startAlpha, startWidth, startHeight, startRotation;
    local translateFunc, alphaFunc, scaleFunc, rotateFunc, colorFunc;
    if(animations[key]) then
      if(animations[key].type == type and not loop) then
        return "no replace";
      end
      anim.x = anim.x or 0;
      anim.y = anim.y or 0;
      selfPoint, anchor, anchorPoint, startX, startY = animations[key].selfPoint, animations[key].anchor, animations[key].anchorPoint, animations[key].startX, animations[key].startY;
      anim.alpha = anim.alpha or 0;
      startAlpha = animations[key].startAlpha;
      anim.scalex = anim.scalex or 1;
      anim.scaley = anim.scaley or 1;
      startWidth, startHeight = animations[key].startWidth, animations[key].startHeight;
      anim.rotate = anim.rotate or 0;
      startRotation = animations[key].startRotation;
      anim.colorR = anim.colorR or 1;
      anim.colorG = anim.colorG or 1;
      anim.colorB = anim.colorB or 1;
      anim.colorA = anim.colorA or 1;
    else
      anim.x = anim.x or 0;
      anim.y = anim.y or 0;
      selfPoint, anchor, anchorPoint, startX, startY = region:GetPoint(1);
      anim.alpha = anim.alpha or 0;
      startAlpha = region:GetAlpha();
      anim.scalex = anim.scalex or 1;
      anim.scaley = anim.scaley or 1;
      startWidth, startHeight = region:GetWidth(), region:GetHeight();
      anim.rotate = anim.rotate or 0;
      startRotation = region.GetRotation and region:GetRotation() or 0;
      anim.colorR = anim.colorR or 1;
      anim.colorG = anim.colorG or 1;
      anim.colorB = anim.colorB or 1;
      anim.colorA = anim.colorA or 1;
    end

    if(anim.use_translate) then
      if not(anim.translateType == "custom" and anim.translateFunc) then
        anim.translateType = anim.translateType or "straightTranslate";
        anim.translateFunc = anim_function_strings[anim.translateType]
      end
      if (anim.translateFunc) then
        translateFunc = WeakAuras.LoadFunction("return " .. anim.translateFunc, id);
      else
        if (region.SetOffsetAnim) then
          region:SetOffsetAnim(0, 0);
        else
          region:SetPoint(selfPoint, anchor, anchorPoint, startX, startY);
        end
      end
    else
      if (region.SetOffsetAnim) then
        region:SetOffsetAnim(0, 0);
      else
        region:SetPoint(selfPoint, anchor, anchorPoint, startX, startY);
      end
    end
    if(anim.use_alpha) then
      if not(anim.alphaType == "custom" and anim.alphaFunc) then
        anim.alphaType = anim.alphaType or "straight";
        anim.alphaFunc = anim_function_strings[anim.alphaType]
      end
      if (anim.alphaFunc) then
        alphaFunc = WeakAuras.LoadFunction("return " .. anim.alphaFunc, id);
      else
        if (region.SetAnimAlpha) then
          region:SetAnimAlpha(nil);
        else
          region:SetAlpha(startAlpha);
        end
      end
    else
      if (region.SetAnimAlpha) then
        region:SetAnimAlpha(nil);
      else
        region:SetAlpha(startAlpha);
      end
    end
    if(anim.use_scale) then
      if not(anim.scaleType == "custom" and anim.scaleFunc) then
        anim.scaleType = anim.scaleType or "straightScale";
        anim.scaleFunc = anim_function_strings[anim.scaleType]
      end
      if (anim.scaleFunc) then
        scaleFunc = WeakAuras.LoadFunction("return " .. anim.scaleFunc, id);
      else
        region:Scale(1, 1);
      end
    elseif(region.Scale) then
      region:Scale(1, 1);
    end
    if(anim.use_rotate) then
      if not(anim.rotateType == "custom" and anim.rotateFunc) then
        anim.rotateType = anim.rotateType or "straight";
        anim.rotateFunc = anim_function_strings[anim.rotateType]
      end
      if (anim.rotateFunc) then
        rotateFunc = WeakAuras.LoadFunction("return " .. anim.rotateFunc, id);
      else
        region:Rotate(startRotation);
      end
    elseif(region.Rotate) then
      region:Rotate(startRotation);
    end
    if(anim.use_color) then
      if not(anim.colorType == "custom" and anim.colorFunc) then
        anim.colorType = anim.colorType or "straightColor";
        anim.colorFunc = anim_function_strings[anim.colorType]
      end
      if (anim.colorFunc) then
        colorFunc = WeakAuras.LoadFunction("return " .. anim.colorFunc, id);
      else
        region:ColorAnim(nil);
      end
    elseif(region.ColorAnim) then
      region:ColorAnim(nil);
    end

    duration = WeakAuras.ParseNumber(anim.duration) or 0;
    progress = 0;
    if(namespace == "display" and type == "main" and not onFinished and not anim.duration_type == "relative") then
      local data = WeakAuras.GetData(id);
      if(data and data.parent) then
        local parentRegion = regions[data.parent].region;
        if(parentRegion and parentRegion.controlledRegions) then
          for index, regionData in pairs(parentRegion.controlledRegions) do
            local childRegion = regionData.region;
            local childKey = regionData.key;
            if(childKey and childKey ~= tostring(region) and animations[childKey] and animations[childKey].type == "main" and duration == animations[childKey].duration) then
              progress = animations[childKey].progress;
              break;
            end
          end
        end
      end
    end

    local animation = animations[key] or {}
    animations[key] = animation

    animation.progress = progress
    animation.startX = startX
    animation.startY = startY
    animation.startAlpha = startAlpha
    animation.startWidth = startWidth
    animation.startHeight = startHeight
    animation.startRotation = startRotation
    animation.dX = (anim.use_translate and anim.x)
    animation.dY = (anim.use_translate and anim.y)
    animation.dAlpha = (anim.use_alpha and (anim.alpha - startAlpha))
    animation.scaleX = (anim.use_scale and anim.scalex)
    animation.scaleY = (anim.use_scale and anim.scaley)
    animation.rotate = anim.rotate
    animation.colorR = (anim.use_color and anim.colorR)
    animation.colorG = (anim.use_color and anim.colorG)
    animation.colorB = (anim.use_color and anim.colorB)
    animation.colorA = (anim.use_color and anim.colorA)
    animation.translateFunc = translateFunc
    animation.alphaFunc = alphaFunc
    animation.scaleFunc = scaleFunc
    animation.rotateFunc = rotateFunc
    animation.colorFunc = colorFunc
    animation.region = region
    animation.selfPoint = selfPoint
    animation.anchor = anchor
    animation.anchorPoint = anchorPoint
    animation.duration = duration
    animation.duration_type = anim.duration_type or "seconds"
    animation.inverse = inverse
    animation.type = type
    animation.loop = loop
    animation.onFinished = onFinished
    animation.name = id
    animation.cloneId = cloneId or ""
    animation.namespace = namespace;
    animation.data = data;
    animation.anim = anim;

    if not(updatingAnimations) then
      frame:SetScript("OnUpdate", WeakAuras.UpdateAnimations);
      updatingAnimations = true;
    end
    return true;
  else
    if(animations[key]) then
      if(animations[key].type ~= type or loop) then
        WeakAuras.CancelAnimation(region, true, true, true, true, true);
      end
    end
    return false;
  end
end

function WeakAuras.IsAnimating(region)
  local key = tostring(region);
  local anim = animations[key];
  if(anim) then
    return anim.type;
  else
    return nil;
  end
end

function WeakAuras.CancelAnimation(region, resetPos, resetAlpha, resetScale, resetRotation, resetColor, doOnFinished)
  local key = tostring(region);
  local anim = animations[key];

  if(anim) then
    if(resetPos) then
      if (anim.region.SetOffsetAnim) then
        anim.region:SetOffsetAnim(0, 0);
      else
        anim.region:ClearAllPoints();
        anim.region:SetPoint(anim.selfPoint, anim.anchor, anim.anchorPoint, anim.startX, anim.startY);
      end
    end
    if(resetAlpha) then
      if (anim.region.SetAnimAlpha) then
        anim.region:SetAnimAlpha(nil);
      else
        anim.region:SetAlpha(anim.startAlpha);
      end
    end
    if(resetScale) then
      if(anim.region.Scale) then
        anim.region:Scale(1, 1);
      else
        anim.region:SetWidth(anim.startWidth);
        anim.region:SetHeight(anim.startHeight);
      end
    end
    if(resetRotation and anim.region.Rotate) then
      anim.region:Rotate(anim.startRotation);
    end
    if(resetColor and anim.region.ColorAnim) then
      anim.region:ColorAnim(nil);
    end

    animations[key] = nil;
    if(doOnFinished and anim.onFinished) then
      anim.onFinished();
    end
    return true;
  else
    return false;
  end
end

function WeakAuras.GetData(id)
  return id and db.displays[id];
end

function WeakAuras.GetTriggerSystem(data, triggernum)
  if (triggernum == 0) then
    return triggerTypes[data.trigger.type];
  elseif (data.additional_triggers and data.additional_triggers[triggernum]) then
    return triggerTypes[data.additional_triggers[triggernum].trigger.type];
  end
  return nil;
end

local function wrapTriggerSystemFunction(functionName, mode)
  local func;
  func = function(data, triggernum)
    if (not triggernum) then
      return func(data, data.activeTriggerMode or -1);
    elseif (triggernum < 0) then
      local result;
      if (mode == "or") then
        result = false;
        for i = 0, data.numTriggers - 1 do
          result = result or func(data, i);
        end
      elseif (mode == "and") then
        result = true;
        for i = 0, data.numTriggers - 1 do
          result = result and func(data, i);
        end
      elseif (mode == "table") then
        result = {};
        for i = 0, data.numTriggers - 1 do
          local tmp = func(data, i);
          if (tmp) then
            for k, v in pairs(tmp) do
              result[k] = v;
            end
          end
        end
      elseif (mode == "firstValue") then
        result = false;
        for i = 0, data.numTriggers - 1 do
          local tmp = func(data, i);
          if (tmp) then
            result = tmp;
            break;
          end
        end
      elseif (mode == "nameAndIcon") then
        for i = 0, data.numTriggers - 1 do
          local tmp1, tmp2 = func(data, i);
          if (tmp1) then
            return tmp1, tmp2;
          end
        end
      end
      return result;
    else -- triggernum >= 0
      local triggerSystem = WeakAuras.GetTriggerSystem(data, triggernum);
      if (not triggerSystem) then
        return false;
      end
      return triggerSystem[functionName](data, triggernum);
    end
  end
  return func;
end

WeakAuras.CanHaveDuration = wrapTriggerSystemFunction("CanHaveDuration", "firstValue");
WeakAuras.CanHaveAuto = wrapTriggerSystemFunction("CanHaveAuto", "or");
WeakAuras.CanGroupShowWithZero = wrapTriggerSystemFunction("CanGroupShowWithZero", "or");
WeakAuras.CanHaveClones = wrapTriggerSystemFunction("CanHaveClones", "or");
WeakAuras.CanHaveTooltip = wrapTriggerSystemFunction("CanHaveTooltip", "or");
WeakAuras.GetNameAndIcon = wrapTriggerSystemFunction("GetNameAndIcon", "nameAndIcon");
WeakAuras.GetAdditionalProperties = wrapTriggerSystemFunction("GetAdditionalProperties", "firstValue");
local wrappedGetOverlayInfo = wrapTriggerSystemFunction("GetOverlayInfo", "table");

function WeakAuras.GetOverlayInfo(data, triggernum)
  local overlayInfo;
  if (data.controlledChildren) then
    overlayInfo = {};
    for index, childId in pairs(data.controlledChildren) do
      local childData = WeakAuras.GetData(childId);
      local tmp = wrappedGetOverlayInfo(childData, triggernum);
      if (tmp) then
        for k, v in pairs(tmp) do
          overlayInfo[k] = v;
        end
      end
    end
  else
    overlayInfo = wrappedGetOverlayInfo(data, triggernum);
  end
  return overlayInfo;
end

function WeakAuras.GetTriggerConditions(data)
  local conditions = {};
  for i = 0, data.numTriggers - 1 do
    local triggerSystem = WeakAuras.GetTriggerSystem(data, i);
    if (triggerSystem) then
      conditions[i] = triggerSystem.GetTriggerConditions(data, i);
      conditions[i] = conditions[i] or {};
      conditions[i].show = {
        display = L["Active"],
        type = "bool",
        test = "(state and state.show or false) == (%s == 1)"
      }
    end
  end
  return conditions;
end

function WeakAuras.CreateFallbackState(id, triggernum, state)
  local data = db.displays[id];
  local triggerSystem = WeakAuras.GetTriggerSystem(data, triggernum);
  if (not triggerSystem) then
    return false;
  end

  triggerSystem.CreateFallbackState(data, triggernum, state);
  if (triggernum == 0) then
    state.trigger = data.trigger;
    state.triggernum = 0;
    state.id = id;
  else
    state.trigger = data.additional_triggers[triggernum].trigger;
    state.triggernum = triggernum;
    state.id = id;
  end
end

function WeakAuras.CanShowNameInfo(data)
  if(data.regionType == "aurabar" or data.regionType == "icon" or data.regionType == "text") then
    return true;
  else
    return false;
  end
end

function WeakAuras.CanShowStackInfo(data)
  if(data.regionType == "aurabar" or data.regionType == "icon" or data.regionType == "text") then
    return true;
  else
    return false;
  end
end

function WeakAuras.CorrectSpellName(input)
  local inputId = tonumber(input);
  if(inputId) then
    local name = GetSpellInfo(inputId);
    if(name) then
      return inputId;
    else
      return nil;
    end
  elseif(input) then
    local link;
    if(input:sub(1,1) == "\124") then
      link = input;
    else
      link = GetSpellLink(input);
    end
    if(link) then
      local itemId = link:match("spell:(%d+)");
      return tonumber(itemId);
    else
      return nil;
    end
  end
end

function WeakAuras.CorrectItemName(input)
  local inputId = tonumber(input);
  if(inputId) then
    local name = GetItemInfo(inputId);
    if(name) then
      return inputId;
    else
      return nil;
    end
  elseif(input) then
    local _, link = GetItemInfo(input);
    if(link) then
      local itemId = link:match("item:(%d+)");
      return tonumber(itemId);
    else
      return nil;
    end
  end
end

local currentTooltipRegion;
local currentTooltipOwner;
function WeakAuras.UpdateMouseoverTooltip(region)
  if(region == currentTooltipRegion) then
    WeakAuras.ShowMouseoverTooltip(currentTooltipRegion, currentTooltipOwner);
  end
end

function WeakAuras.ShowMouseoverTooltip(region, owner)
  currentTooltipRegion = region;
  currentTooltipOwner = owner;

  GameTooltip:SetOwner(owner, "ANCHOR_NONE");
  GameTooltip:SetPoint("LEFT", owner, "RIGHT");
  GameTooltip:ClearLines();

  local triggerType;
  if (region.state) then
    triggerType = region.state.trigger.type;
  end

  local triggerSystem = triggerType and triggerTypes[triggerType];
  if (not triggerSystem) then
    GameTooltip:Hide();
    return;
  end

  triggerSystem.SetToolTip(region.state.trigger, region.state);
  GameTooltip:Show();
end

function WeakAuras.HideTooltip()
  currentTooltipRegion = nil;
  currentTooltipOwner = nil;
  GameTooltip:Hide();
end

do
  local hiddenTooltip;
  function WeakAuras.GetHiddenTooltip()
    if not(hiddenTooltip) then
      hiddenTooltip = CreateFrame("GameTooltip", "WeakAurasTooltip", nil, "GameTooltipTemplate");
      hiddenTooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
      hiddenTooltip:AddFontStrings(
        hiddenTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
        hiddenTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
      );
    end
    return hiddenTooltip;
  end
end

function WeakAuras.GetAuraTooltipInfo(unit, index, filter)
  local tooltip = WeakAuras.GetHiddenTooltip();
  tooltip:SetUnitAura(unit, index, filter);
  local tooltipTextLine = select(5, tooltip:GetRegions())

  local tooltipText = tooltipTextLine and tooltipTextLine:GetObjectType() == "FontString" and tooltipTextLine:GetText() or "";
  local debuffType = "none";
  local found = false;
  local tooltipSize = {};
  if(tooltipText) then
    for t in tooltipText:gmatch("(%d[%d%.,]*)") do
      t = t:gsub(",", "");
      t = t:gsub("%.", "");
      tinsert(tooltipSize, tonumber(t));
    end
  end

  if (#tooltipSize) then
    return tooltipText, debuffType, unpack(tooltipSize);
  else
    return tooltipText, debuffType, 0;
  end
end

local function tooltip_draw()
  GameTooltip:ClearLines();
  GameTooltip:AddDoubleLine("WeakAuras", versionString, 0.5333, 0, 1, 1, 1, 1);
  GameTooltip:AddLine(" ");
  if(WeakAuras.IsOptionsOpen()) then
    GameTooltip:AddLine(L["Click to close configuration"], 0, 1, 1);
  else
    GameTooltip:AddLine(L["Click to open configuration"], 0, 1, 1);
    if(paused) then
      GameTooltip:AddLine("|cFFFF0000"..L["Paused"].." - |cFF00FFFF"..L["Shift-Click to resume"], 0, 1, 1);
    else
      GameTooltip:AddLine(L["Shift-Click to pause"], 0, 1, 1);
    end
  end
  GameTooltip:Show();
end

local colorFrame = CreateFrame("frame");
WeakAuras.frames["LDB Icon Recoloring"] = colorFrame;
local colorElapsed = 0;
local colorDelay = 2;
local r, g, b = 0.8, 0, 1;
local r2, g2, b2 = random(2)-1, random(2)-1, random(2)-1;
local tooltip_update_frame = CreateFrame("FRAME");
WeakAuras.frames["LDB Tooltip Updater"] = tooltip_update_frame;
local Broker_WeakAuras;
Broker_WeakAuras = LDB:NewDataObject("WeakAuras", {
  type = "data source",
  text = "WeakAuras",
  icon = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon.blp",
  OnClick = function(self, button)
    if(IsShiftKeyDown()) then
      if not(WeakAuras.IsOptionsOpen()) then
        WeakAuras.Toggle();
      end
    else
      WeakAuras.OpenOptions();
    end
  end,
  OnEnter = function(self)
    colorFrame:SetScript("OnUpdate", function(self, elaps)
      colorElapsed = colorElapsed + elaps;
      if(colorElapsed > colorDelay) then
        colorElapsed = colorElapsed - colorDelay;
        r, g, b = r2, g2, b2;
        r2, g2, b2 = random(2)-1, random(2)-1, random(2)-1;
      end
      Broker_WeakAuras.iconR = r + (r2 - r) * colorElapsed / colorDelay;
      Broker_WeakAuras.iconG = g + (g2 - g) * colorElapsed / colorDelay;
      Broker_WeakAuras.iconB = b + (b2 - b) * colorElapsed / colorDelay;
    end);
    local elapsed = 0;
    local delay = 1;
    tooltip_update_frame:SetScript("OnUpdate", function(self, elap)
      elapsed = elapsed + elap;
      if(elapsed > delay) then
        elapsed = 0;
        tooltip_draw();
      end
    end);
    -- Section the screen into 6 sextants and define the tooltip anchor position based on which sextant the cursor is in
    local max_x = GetScreenWidth();
    local max_y = GetScreenHeight();
    local x, y = GetCursorPosition();
    local horizontal = (x < (max_x/3) and "LEFT") or ((x >= (max_x/3) and x < ((max_x/3)*2)) and "") or "RIGHT";
    local tooltip_vertical = (y < (max_y/2) and "BOTTOM") or "TOP";
    local anchor_vertical = (y < (max_y/2) and "TOP") or "BOTTOM";
    GameTooltip:SetOwner(self, "ANCHOR_NONE");
    GameTooltip:SetPoint(tooltip_vertical..horizontal, self, anchor_vertical..horizontal);
    tooltip_draw();
  end,
  OnLeave = function(self)
    colorFrame:SetScript("OnUpdate", nil);
    tooltip_update_frame:SetScript("OnUpdate", nil);
    GameTooltip:Hide();
  end,
  iconR = 0.6,
  iconG = 0,
  iconB = 1
});

local FrameTimes = {};
function WeakAuras.ProfileFrames(all)
  UpdateAddOnCPUUsage();
  for name, frame in pairs(WeakAuras.frames) do
    local FrameTime = GetFrameCPUUsage(frame);
    FrameTimes[name] = FrameTimes[name] or 0;
    if(all or FrameTime > FrameTimes[name]) then
      print("|cFFFF0000"..name.."|r -", FrameTime, "-", FrameTime - FrameTimes[name]);
    end
    FrameTimes[name] = FrameTime;
  end
end

local DisplayTimes = {};
function WeakAuras.ProfileDisplays(all)
  UpdateAddOnCPUUsage();
  for id, regionData in pairs(WeakAuras.regions) do
    local DisplayTime = GetFrameCPUUsage(regionData.region, true);
    DisplayTimes[id] = DisplayTimes[id] or 0;
    if(all or DisplayTime > DisplayTimes[id]) then
      print("|cFFFF0000"..id.."|r -", DisplayTime, "-", DisplayTime - DisplayTimes[id]);
    end
    DisplayTimes[id] = DisplayTime;
  end
end

function WeakAuras.RegisterTutorial(name, displayName, description, icon, steps, order)
  tutorials[name] = {
    name = name,
    displayName = displayName,
    description = description,
    icon = icon,
    steps = steps,
    order = order
  };
end

do
  local customTextUpdateFrame;
  local updateRegions = {};

  local function DoCustomTextUpdates()
    WeakAuras.StartProfileSystem("custom text - every frame update");
    for region, _ in pairs(updateRegions) do
      if(region.UpdateCustomText) then
        if(region:IsVisible()) then
          WeakAuras.StartProfileAura(region.id);
          region.UpdateCustomText();
          WeakAuras.StopProfileAura(region.id);
        end
      else
        updateRegions[region] = nil;
      end
    end
    WeakAuras.StopProfileSystem("custom text - every frame update");
  end

  function WeakAuras.InitCustomTextUpdates()
    if not(customTextUpdateFrame) then
      customTextUpdateFrame = CreateFrame("frame");
      customTextUpdateFrame:SetScript("OnUpdate", DoCustomTextUpdates);
    end
  end

  function WeakAuras.RegisterCustomTextUpdates(region)
    WeakAuras.InitCustomTextUpdates();
    updateRegions[region] = true;
  end

  function WeakAuras.UnregisterCustomTextUpdates(region)
    updateRegions[region] = nil;
  end

  function WeakAuras.IsRegisteredForCustomTextUpdates(region)
    return updateRegions[region];
  end
end

function WeakAuras.ValueFromPath(data, path)
  if(#path == 1) then
    return data[path[1]];
  else
    local reducedPath = {};
    for i=2,#path do
      reducedPath[i-1] = path[i];
    end
    return WeakAuras.ValueFromPath(data[path[1]], reducedPath);
  end
end

function WeakAuras.ValueToPath(data, path, value)
  if(#path == 1) then
    data[path[1]] = value;
  else
    local reducedPath = {};
    for i=2,#path do
      reducedPath[i-1] = path[i];
    end
    WeakAuras.ValueToPath(data[path[1]], reducedPath, value);
  end
end

function WeakAuras.FixGroupChildrenOrderForGroup(data)
  local frameLevel = 1;
  for i=1, #data.controlledChildren do
    WeakAuras.SetFrameLevel(data.controlledChildren[i], frameLevel);
    frameLevel = frameLevel + 4;
  end
end

WeakAuras.frameLevels = {};
function WeakAuras.SetFrameLevel(id, frameLevel)
  if (WeakAuras.frameLevels[id] == frameLevel) then
    return;
  end
  if (WeakAuras.regions[id] and WeakAuras.regions[id].region) then
    WeakAuras.regions[id].region:SetFrameLevel(frameLevel);
  end
  if (clones[id]) then
    for i,v in pairs(clones[id]) do
      v:SetFrameLevel(frameLevel);
    end
  end
  WeakAuras.frameLevels[id] = frameLevel;
end

function WeakAuras.GetFrameLevelFor(id)
  return WeakAuras.frameLevels[id] or 0;
end

function WeakAuras.EnsureString(input)
  if (input == nil) then
    return "";
  end
  return tostring(input);
end

-- Handle coroutines
local dynFrame = {};
do
  -- Internal data
  dynFrame.frame = CreateFrame("frame");
  dynFrame.update = {};
  dynFrame.size = 0;

  -- Add an action to be resumed via OnUpdate
  function dynFrame.AddAction(self, name, func)
    if not name then
      name = fmt("NIL", dynFrame.size+1);
    end

    if not dynFrame.update[name] then
      dynFrame.update[name] = func;
      dynFrame.size = dynFrame.size + 1
      dynFrame.frame:Show();
    end
  end

  -- Remove an action from OnUpdate
  function dynFrame.RemoveAction(self, name)
    if dynFrame.update[name] then
      dynFrame.update[name] = nil;
      dynFrame.size = dynFrame.size - 1
      if dynFrame.size == 0 then
        dynFrame.frame:Hide();
      end
    end
  end

  -- Setup frame
  dynFrame.frame:Hide();
  dynFrame.frame:SetScript("OnUpdate", function(self, elapsed)
    -- Start timing
    local start = debugprofilestop();
    local hasData = true;

    -- Resume as often as possible (Limit to 16ms per frame -> 60 FPS)
    while (debugprofilestop() - start < 16 and hasData) do
      -- Stop loop without data
      hasData = false;

      -- Resume all coroutines
      for name, func in pairs(dynFrame.update) do
        -- Loop has data
        hasData = true;

        -- Resume or remove
        if coroutine.status(func) ~= "dead" then
          local err,ret1,ret2 = assert(coroutine.resume(func))
          if err then
            debug(debugstack(func))
          end
        else
          dynFrame:RemoveAction(name);
        end
      end
    end
  end);
end

WeakAuras.dynFrame = dynFrame;

function WeakAuras.ControlChildren(childid)
  local parent = db.displays[childid].parent;
  if (parent and db.displays[parent] and db.displays[parent].regionType == "dynamicgroup") then
    regions[parent].region:ControlChildren();
  end
end

function WeakAuras.SetDynamicIconCache(name, spellId, icon)
  db.dynamicIconCache[name] = db.dynamicIconCache[name] or {};
  db.dynamicIconCache[name][spellId] = icon;
end

function WeakAuras.GetDynamicIconCache(name)
  if (db.dynamicIconCache[name]) then
    local fallback = nil;
    for spellId, icon in pairs(db.dynamicIconCache[name]) do
      fallback = icon;
      if (type(spellId) == "number" and IsSpellKnown(spellId)) then -- TODO save this information?
        return db.dynamicIconCache[name][spellId];
      end
    end
    return fallback;
  end

  if WeakAuras.spellCache then
    return WeakAuras.spellCache.GetIcon(name);
  end
  return nil;
end

function WeakAuras.RegisterTriggerSystem(types, triggerSystem)
  for _, v in ipairs(types) do
    triggerTypes[v] = triggerSystem;
  end
  tinsert(triggerSystems, triggerSystem);
end

function WeakAuras.GetTriggerStateForTrigger(id, triggernum)
  if (triggernum == -1) then
    return WeakAuras.GetGlobalConditionState();
  end
  triggerState[id][triggernum] = triggerState[id][triggernum] or {}
  return triggerState[id][triggernum];
end

local function startStopTimers(id, cloneId, triggernum, state)
  if (state.show) then
    if (state.autoHide and state.duration and state.duration > 0) then -- autohide, update timer
      timers[id] = timers[id] or {};
      timers[id][triggernum] = timers[id][triggernum] or {};
      timers[id][triggernum][cloneId] = timers[id][triggernum][cloneId] or {};
      local record = timers[id][triggernum][cloneId];
      if (state.expirationTime == nil) then
        state.expirationTime = GetTime() + state.duration;
        state.resort = true;
      end
      if (record.expirationTime ~= state.expirationTime) then
        if (record.handle ~= nil) then
          timer:CancelTimer(record.handle);
        end

        record.handle = timer:ScheduleTimerFixed(
          function()
            if (state.show ~= false and state.show ~= nil) then
              state.show = false;
              state.changed = true;
              WeakAuras.UpdatedTriggerState(id);
            end
          end,
          state.expirationTime - GetTime());
        record.expirationTime = state.expirationTime;
      end
    else -- no auto hide, delete timer
      if (timers[id] and timers[id][triggernum] and timers[id][triggernum][cloneId]) then
        local record = timers[id][triggernum][cloneId];
        if (record.handle) then
          timer:CancelTimer(record.handle);
        end
        record.handle = nil;
        record.expirationTime = nil;
    end
    end
  else -- not shown
    if(timers[id] and timers[id][triggernum] and timers[id][triggernum][cloneId]) then
      local record = timers[id][triggernum][cloneId];
      if (record.handle) then
        timer:CancelTimer(record.handle);
      end
      record.handle = nil;
      record.expirationTime = nil;
  end
  end
end

local function ApplyStateToRegion(id, region, state)
  region.state = state;
  if(region.SetDurationInfo) then
    if (state.progressType == "timed") then
      local now = GetTime();
      local value = math.huge - now;
      if (state.expirationTime and state.expirationTime > 0) then
        value = state.expirationTime - now;
      end
      local total = state.duration or 0
      local func = nil;

      region:SetDurationInfo(total, now + value, func, state.inverse);
    elseif (state.progressType == "static") then
      local value = state.value or 0;
      local total = state.total or 0;
      local durationFunc = state.durationFunc or true;

      region:SetDurationInfo(value, total, durationFunc or true, state.inverse);
    else
      region:SetDurationInfo(0, math.huge);
    end
  end
  if (region.SetAdditionalProgress) then
    region:SetAdditionalProgress(state.additionalProgress, region.adjustMin or 0, region.adjustedMax or state.total or state.duration or 0, state.inverse);
  end
  local controlChidren = state.resort;
  if (state.resort) then
    state.resort = false;
  end
  if(region.SetName) then
    region:SetName(state.name);
  end
  if(region.SetIcon) then
    region:SetIcon(state.icon or "Interface\\Icons\\INV_Misc_QuestionMark");
  end
  if(region.SetStacks) then
    region:SetStacks(state.stacks);
  end
  if(region.UpdateCustomText and not WeakAuras.IsRegisteredForCustomTextUpdates(region)) then
    region.UpdateCustomText();
  end

  if(state.texture and region.SetTexture) then
    region:SetTexture(state.texture);
  end

  WeakAuras.UpdateMouseoverTooltip(region);

  region:Expand();
  if (controlChidren) then
    WeakAuras.ControlChildren(region.id);
  end
end

-- Fallbacks if the states are empty
local emptyState = {};
emptyState[""] = {};

local function applyToTriggerStateTriggers(stateShown, id, triggernum)
  if (stateShown and not triggerState[id].triggers[triggernum + 1]) then
    triggerState[id].triggers[triggernum + 1] = true;
    triggerState[id].triggerCount = triggerState[id].triggerCount + 1;
    return true;
  elseif (not stateShown and triggerState[id].triggers[triggernum + 1]) then
    -- Check if any other clone is shown
    local anyCloneShown = false;
    for _, state in pairs(triggerState[id][triggernum]) do
      if (state.show) then
        anyCloneShown = true;
        break;
      end
    end
    if (not anyCloneShown) then
      triggerState[id].triggers[triggernum + 1] = false;
      triggerState[id].triggerCount = triggerState[id].triggerCount - 1;
      return true;
    end
  end
  return false;
end

local function evaluateTriggerStateTriggers(id)
  local result = false;
  WeakAuras.ActivateAuraEnvironment(id);

  if (triggerState[id].disjunctive == "any" and triggerState[id].triggerCount > 0) then
    result = true;
  elseif(triggerState[id].disjunctive == "all" and triggerState[id].triggerCount == triggerState[id].numTriggers) then
    result = true;
  else
    if (triggerState[id].disjunctive == "custom" and triggerState[id].triggerLogicFunc) then
      local ok, returnValue = xpcall(triggerState[id].triggerLogicFunc, geterrorhandler(), triggerState[id].triggers);
      result = ok and returnValue;
    end
  end

  WeakAuras.ActivateAuraEnvironment(nil);
  return result;
end

local function ApplyStatesToRegions(id, triggernum, states)
  -- Show new clones
  local visibleRegion = false;
  for cloneId, state in pairs(states) do
    local region = WeakAuras.GetRegion(id, cloneId);
    if (state.show) then
      visibleRegion = true;
      if (not region.toShow or state.changed or region.state ~= state) then
        ApplyStateToRegion(id, region, state);
      end
    end
    if (checkConditions[id]) then -- Even if this state has not changed
      checkConditions[id](region);
    end
  end

  if (visibleRegion) then
    if (not states[""] or not states[""].show) then
      WeakAuras.regions[id].region:Collapse();
    end
  else
    -- no visible region, fallback to a fallback state
    fallbacksStates[id] = fallbacksStates[id] or {};
    fallbacksStates[id][triggernum] =  fallbacksStates[id][triggernum] or {};
    WeakAuras.CreateFallbackState(id, triggernum, fallbacksStates[id][triggernum])
    ApplyStateToRegion(id, WeakAuras.regions[id].region, fallbacksStates[id][triggernum]);
    if (checkConditions[id]) then
      checkConditions[id](WeakAuras.regions[id].region);
    end
  end
end

local toRemove = {};
function WeakAuras.UpdatedTriggerState(id)
  if (not triggerState[id]) then
    return;
  end

  local changed = false;
  for triggernum = 0, triggerState[id].numTriggers - 1 do
    triggerState[id][triggernum] = triggerState[id][triggernum] or {};
    for cloneId, state in pairs(triggerState[id][triggernum]) do
      if (triggernum == 0) then
        state.trigger = db.displays[id].trigger;
        state.triggernum = 0;
        state.id = id;
      else
        state.trigger = db.displays[id].additional_triggers[triggernum].trigger;
        state.triggernum = triggernum;
        state.id = id;
      end

      if (state.changed) then
        startStopTimers(id, cloneId, triggernum, state);
        local stateShown = triggerState[id][triggernum][cloneId] and triggerState[id][triggernum][cloneId].show;
        -- Update triggerState.triggers
        changed = applyToTriggerStateTriggers(stateShown, id, triggernum) or changed;
      end
    end
  end

  -- Figure out whether we should be shown or not
  local show = triggerState[id].show;
  if (changed or show == nil) then
    show = evaluateTriggerStateTriggers(id);
  end

  -- Figure out which subtrigger is active, and if it changed
  local newActiveTrigger = triggerState[id].activeTriggerMode;
  if (newActiveTrigger == WeakAuras.trigger_modes.first_active) then
    -- Mode is first active trigger, so find a active trigger
    for i = 0, triggerState[id].numTriggers - 1 do
      if (triggerState[id].triggers[i + 1]) then
        newActiveTrigger = i;
        break;
      end
    end
  end

  local oldShow = triggerState[id].show;
  triggerState[id].activeTrigger = newActiveTrigger;
  triggerState[id].show = show;

  local activeTriggerState = WeakAuras.GetTriggerStateForTrigger(id, newActiveTrigger);
  if (not next(activeTriggerState)) then
    activeTriggerState = emptyState;
  end

  local region;
  -- Now apply
  if (show and not oldShow) then -- Hide => Show
    ApplyStatesToRegions(id, newActiveTrigger, activeTriggerState);
  elseif (not show and oldShow) then -- Show => Hide
    WeakAuras.CollapseAllClones(id);
    WeakAuras.regions[id].region:Collapse();
  elseif (show and oldShow) then -- Already shown, update regions
    -- Hide old clones
    for cloneId, clone in pairs(clones[id]) do
      if (not activeTriggerState[cloneId] or not activeTriggerState[cloneId].show) then
        clone:Collapse();
      end
  end
  -- Show new states
  ApplyStatesToRegions(id, newActiveTrigger, activeTriggerState);
  end

  for cloneId, state in pairs(activeTriggerState) do
    local region = WeakAuras.GetRegion(id, cloneId);
    if (checkConditions[id]) then
      checkConditions[id](region, not show or not state.show);
    end
  end

  for triggernum = 0, triggerState[id].numTriggers - 1 do
    triggerState[id][triggernum] = triggerState[id][triggernum] or {};
    for cloneId, state in pairs(triggerState[id][triggernum]) do
      if (not state.show) then
        if (cloneId ~= "") then -- Keep "" state around, it's likely to be reused
          tinsert(toRemove, cloneId)
        else
          for k, v in pairs(state) do
            if (k ~= "trigger" and k ~= "triggernum" and k ~= "id") then
              state[k] = nil;
            end
          end
        end
      end
      state.changed = false;
    end
    for _, cloneId in ipairs(toRemove) do
      triggerState[id][triggernum][cloneId] = nil;
    end
    wipe(toRemove);
  end
end

local replaceStringCache = {};
function WeakAuras.ContainsPlaceHolders(textStr, toCheck)
  if (textStr == nil or toCheck == nil) then
    return false;
  end
  for i = 1, #toCheck do
    if (textStr:find("%%" .. toCheck:sub(i, i))) then
      return true;
    end
  end
  return false;
end

local function ReplaceValuePlaceHolders(textStr, region, customFunc)
  local regionValues = region.values;
  local value;
  if textStr:find("%%?c") then
    if customFunc then
      WeakAuras.ActivateAuraEnvironment(region.id, region.cloneId, region.state);
      regionValues.custom = {select(2, xpcall(customFunc, geterrorhandler(), region.expirationTime, region.duration,
            regionValues.progress, regionValues.duration, regionValues.name, regionValues.icon, regionValues.stacks))}
      WeakAuras.ActivateAuraEnvironment(nil)
    end
    if not regionValues.custom then
      return ""
    end
    local index = tonumber(textStr:match("%d+") or 1)
    value = WeakAuras.EnsureString(regionValues.custom[index])
  else
    local variable = WeakAuras.dynamic_texts[textStr];
    if (not variable) then
      return nil;
    end
    variable = variable and variable.value;
    value = variable and regionValues[variable] or "";
  end
  return value;
end

function WeakAuras.ReplacePlaceHolders(textStr, region, customFunc)
  local regionValues = region.values;
  local regionState = region.state;
  if (not regionState and not regionValues) then
    return;
  end
  -- We look backwards through the string
  -- Invariant currentPos - endPos is a ascii "alphabetic" string
  -- So on finding a "%" we extract  currentPos - endPos and depending
  -- on how long the string is look it up in regionState or in regionValues
  -- textStr is in UTF-8 encoding. We assume all state variables are pure alphanumeric strings
  local endPos = textStr:len();
  if (endPos < 2) then
    textStr = textStr:gsub("\\n", "\n");
    return textStr;
  end

  if (endPos == 2) then
    local value = ReplaceValuePlaceHolders(textStr, region, customFunc);
    if (value) then
      textStr = tostring(value);
    end
    textStr = textStr:gsub("\\n", "\n");
    return textStr;
  end

  local currentPos = endPos;
  -- Look backwards
  while (currentPos > 0) do
    local char = string.byte(textStr, currentPos);
    if (char == 37) then   --%
      if (endPos - currentPos == 1 and regionValues) then
        local symbol = string.sub(textStr, currentPos, endPos)
        local value = ReplaceValuePlaceHolders(symbol, region, customFunc);
        if (value) then
          textStr = string.sub(textStr, 1, currentPos - 1) .. value .. string.sub(textStr, endPos + 1);
        end
      elseif (endPos > currentPos) then
        local symbol = string.sub(textStr, currentPos + 1, endPos);
        local value
        if symbol:find("^c%d*$") and regionValues then -- custom value
          value = ReplaceValuePlaceHolders(symbol, region, customFunc)
          if value then
            textStr = string.sub(textStr, 1, currentPos - 1) .. value .. string.sub(textStr, endPos + 1);
          end
        elseif regionState then -- state value
          value = regionState[symbol] and tostring(regionState[symbol]);
          if (value) then
            textStr = string.sub(textStr, 1, currentPos - 1) .. value .. string.sub(textStr, endPos + 1);
          else
            value = ReplaceValuePlaceHolders(string.sub(textStr, currentPos, currentPos + 1), region, customFunc);
            value = value or "";
            textStr = string.sub(textStr, 1, currentPos - 1) .. value .. string.sub(textStr, currentPos + 2);
          end
        end
      end
      endPos = currentPos - 1;
    elseif (char >= 48 and char <= 57) or (char >= 65 and char <= 90) or (char >= 97 and char <= 122) then
      -- 0-9a-zA-Z character
    else
      endPos = currentPos - 1;
    end
    currentPos = currentPos - 1;
  end

  textStr = textStr:gsub("\\n", "\n");
  return textStr;
end

function WeakAuras.IsTriggerActive(id)
  local active = triggerState[id];
  return active and active.show;
end

-- Attach to Cursor/Frames code
-- Very simple function to convert a hsv angle to a color with
-- value hardcoded to 1 and saturation hardcoded to 0.75
local function colorWheel(angle)
  local hh = angle / 60;
  local i = floor(hh);
  local ff = hh - i;
  local p = 0;
  local q = 0.75 * (1.0 - ff);
  local t = 0.75 * ff;
  if (i == 0) then
    return 0.75, t, p;
  elseif (i == 1) then
    return q, 0.75, p;
  elseif (i == 2) then
    return p, 0.75, t;
  elseif (i == 3) then
    return p, q, 0.75;
  elseif (i == 4) then
    return t, p, 0.75;
  else
    return 0.75, p, q;
  end
end

local function xPositionNextToOptions()
  local xOffset;
  local optionsFrame = WeakAuras.OptionsFrame();
  local centerX = (optionsFrame:GetLeft() + optionsFrame:GetRight()) / 2;
  if (centerX > GetScreenWidth() / 2) then
    if (optionsFrame:GetLeft() > 400) then
      xOffset = optionsFrame:GetLeft() - 200;
    else
      xOffset = optionsFrame:GetLeft() / 2;
    end
  else
    if (GetScreenWidth() - optionsFrame:GetRight() > 400 ) then
      xOffset = optionsFrame:GetRight() + 200;
    else
      xOffset = (GetScreenWidth() + optionsFrame:GetRight()) / 2;
    end
  end
  return xOffset;
end

local mouseFrame;
local function ensureMouseFrame()
  if (mouseFrame) then
    return;
  end
  mouseFrame = CreateFrame("FRAME", "WeakAurasAttachToMouseFrame", UIParent);
  mouseFrame.attachedVisibleFrames = {};
  mouseFrame:SetWidth(1);
  mouseFrame:SetHeight(1);

  local moverFrame = CreateFrame("FRAME", "WeakAurasMousePointerFrame", mouseFrame);
  mouseFrame.moverFrame = moverFrame;
  moverFrame:SetPoint("TOPLEFT", mouseFrame, "CENTER");
  moverFrame:SetWidth(32);
  moverFrame:SetHeight(32);
  moverFrame:SetFrameStrata("FULLSCREEN"); -- above settings dialog

  moverFrame:EnableMouse(true)
  moverFrame:SetScript("OnMouseDown", function()
    mouseFrame:SetMovable(true);
    mouseFrame:StartMoving()
  end);
  moverFrame:SetScript("OnMouseUp", function()
    mouseFrame:StopMovingOrSizing();
    mouseFrame:SetMovable(false);
    local xOffset = mouseFrame:GetRight() - GetScreenWidth();
    local yOffset = mouseFrame:GetTop() - GetScreenHeight();
    db.mousePointerFrame = db.mousePointerFrame or {};
    db.mousePointerFrame.xOffset = xOffset;
    db.mousePointerFrame.yOffset = yOffset;
  end);
  moverFrame.colorWheelAnimation = function()
    local angle = ((GetTime() - moverFrame.startTime) % 5) / 5 * 360;
    moverFrame.texture:SetVertexColor(colorWheel(angle));
  end;
  local texture = moverFrame:CreateTexture(nil, "BACKGROUND");
  moverFrame.texture = texture;
  texture:SetAllPoints(moverFrame);
  texture:SetTexture("Interface\\Cursor\\Point");

  local label = moverFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  label:SetJustifyH("LEFT")
  label:SetJustifyV("TOP")
  label:SetPoint("TOPLEFT", moverFrame, "BOTTOMLEFT");
  label:SetText("WeakAuras Anchor");

  moverFrame:Hide();

  mouseFrame.OptionsOpened = function()
    if (db.mousePointerFrame) then
      -- Restore from settings
      mouseFrame:ClearAllPoints();
      mouseFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.mousePointerFrame.xOffset, db.mousePointerFrame.yOffset);
    else
      -- Fnd a suitable position
      local optionsFrame = WeakAuras.OptionsFrame();
      local yOffset = (optionsFrame:GetTop() + optionsFrame:GetBottom()) / 2;
      local xOffset = xPositionNextToOptions();
      -- We use the top right, because the main frame usees the top right as the reference too
      mouseFrame:ClearAllPoints();
      mouseFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xOffset - GetScreenWidth(), yOffset - GetScreenHeight());
    end
    -- Change the color of the mouse cursor
    moverFrame.startTime = GetTime();
    moverFrame:SetScript("OnUpdate", moverFrame.colorWheelAnimation);
    mouseFrame:SetScript("OnUpdate", nil);
  end

  mouseFrame.moveWithMouse = function()
    local scale = 1 / UIParent:GetEffectiveScale();
    local x, y =  GetCursorPosition();
    mouseFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * scale, y * scale);
  end

  mouseFrame.OptionsClosed = function()
    moverFrame:Hide();
    mouseFrame:ClearAllPoints();
    mouseFrame:SetScript("OnUpdate", mouseFrame.moveWithMouse);
    moverFrame:SetScript("OnUpdate", nil);
    wipe(mouseFrame.attachedVisibleFrames);
  end

  mouseFrame.expand = function(self, id)
    local data = WeakAuras.GetData(id);
    if (data.anchorFrameType == "MOUSE") then
      self.attachedVisibleFrames[id] = true;
      self:updateVisible();
    end
  end

  mouseFrame.collapse = function(self, id)
    self.attachedVisibleFrames[id] = nil;
    self:updateVisible();
  end

  mouseFrame.rename = function(self, oldid, newid)
    self.attachedVisibleFrames[newid] = self.attachedVisibleFrames[oldid];
    self.attachedVisibleFrames[oldid] = nil;
    self:updateVisible();
  end

  mouseFrame.delete = function(self, id)
    self.attachedVisibleFrames[id] = nil;
    self:updateVisible();
  end

  mouseFrame.anchorFrame = function(self, id, anchorFrameType)
    if (anchorFrameType == "MOUSE") then
      self.attachedVisibleFrames[id] = true;
    else
      self.attachedVisibleFrames[id] = nil;
    end
    self:updateVisible();
  end

  mouseFrame.updateVisible = function(self)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end

    if (next(self.attachedVisibleFrames)) then
      mouseFrame.moverFrame:Show();
    else
      mouseFrame.moverFrame:Hide();
    end
  end

  if (WeakAuras.IsOptionsOpen()) then
    mouseFrame:OptionsOpened();
  else
    mouseFrame:OptionsClosed();
  end

  WeakAuras.mouseFrame = mouseFrame;
end

local personalRessourceDisplayFrame;
local function ensurePRDFrame()
  if (personalRessourceDisplayFrame) then
    return;
  end
  personalRessourceDisplayFrame = CreateFrame("FRAME", "WeakAurasAttachToPRD", UIParent);
  personalRessourceDisplayFrame:Hide();
  personalRessourceDisplayFrame.attachedVisibleFrames = {};
  WeakAuras.personalRessourceDisplayFrame = personalRessourceDisplayFrame;

  local moverFrame = CreateFrame("FRAME", "WeakAurasPRDMoverFrame", personalRessourceDisplayFrame);
  personalRessourceDisplayFrame.moverFrame = moverFrame;
  moverFrame:SetPoint("TOPLEFT", personalRessourceDisplayFrame, "TOPLEFT", -2, 2);
  moverFrame:SetPoint("BOTTOMRIGHT", personalRessourceDisplayFrame, "BOTTOMRIGHT", 2, -2);
  moverFrame:SetFrameStrata("FULLSCREEN"); -- above settings dialog

  moverFrame:EnableMouse(true)
  moverFrame:SetScript("OnMouseDown", function()
    personalRessourceDisplayFrame:SetMovable(true);
    personalRessourceDisplayFrame:StartMoving()
  end);
  moverFrame:SetScript("OnMouseUp", function()
    personalRessourceDisplayFrame:StopMovingOrSizing();
    personalRessourceDisplayFrame:SetMovable(false);
    local xOffset = personalRessourceDisplayFrame:GetRight();
    local yOffset = personalRessourceDisplayFrame:GetTop();

    db.personalRessourceDisplayFrame = db.personalRessourceDisplayFrame or {};
    local scale = UIParent:GetEffectiveScale() / personalRessourceDisplayFrame:GetEffectiveScale();
    db.personalRessourceDisplayFrame.xOffset = xOffset / scale - GetScreenWidth();
    db.personalRessourceDisplayFrame.yOffset = yOffset / scale - GetScreenHeight();
  end);
  moverFrame:Hide();

  local texture = moverFrame:CreateTexture(nil, "BACKGROUND");
  personalRessourceDisplayFrame.texture = texture;
  texture:SetAllPoints(moverFrame);
  texture:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\PRDFrame");

  local label = moverFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
  label:SetPoint("CENTER", moverFrame, "CENTER");
  label:SetText("WeakAuras Anchor");

  personalRessourceDisplayFrame:RegisterEvent('NAME_PLATE_UNIT_ADDED');
  personalRessourceDisplayFrame:RegisterEvent('NAME_PLATE_UNIT_REMOVED');

  personalRessourceDisplayFrame.Attach = function(self, frame, frameTL, frameBR)
    self:SetParent(frame);
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", frameTL, "TOPLEFT");
    self:SetPoint("BOTTOMRIGHT", frameBR, "BOTTOMRIGHT");
  end

  personalRessourceDisplayFrame.Detach = function(self, frame)
    self:ClearAllPoints();
    self:SetParent(UIParent);
  end

  personalRessourceDisplayFrame.OptionsOpened = function()
    personalRessourceDisplayFrame:Detach();
    personalRessourceDisplayFrame:SetScript("OnEvent", nil);
    personalRessourceDisplayFrame:ClearAllPoints();
    local xOffset, yOffset;
    if (db.personalRessourceDisplayFrame) then
      xOffset = db.personalRessourceDisplayFrame.xOffset;
      yOffset = db.personalRessourceDisplayFrame.yOffset;
    end

    -- Calculate size of self nameplate
    local prdWidth;
    local prdHeight;

    if (KuiNameplatesCore and KuiNameplatesCore.profile) then
      prdWidth = KuiNameplatesCore.profile.frame_width_personal;
      prdHeight = KuiNameplatesCore.profile.frame_height_personal;
      if (KuiNameplatesCore.profile.ignore_uiscale) then
        local _, screenWidth = GetPhysicalScreenSize();
        local uiScale = 1;
        if (screenWidth) then
          uiScale = 768 / screenWidth;
        end
        personalRessourceDisplayFrame:SetScale(uiScale / UIParent:GetEffectiveScale());
      else
        personalRessourceDisplayFrame:SetScale(1);
      end
      personalRessourceDisplayFrame.texture:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\PRDFrameKui");
    else
      local namePlateVerticalScale = tonumber(GetCVar("NamePlateVerticalScale"));
      local zeroBasedScale = namePlateVerticalScale - 1.0;
      local clampedZeroBasedScale = Saturate(zeroBasedScale);
      local horizontalScale = tonumber(GetCVar("NamePlateHorizontalScale"));
      local baseNamePlateWidth = NamePlateDriverFrame.baseNamePlateWidth;
      prdWidth = baseNamePlateWidth * horizontalScale * Lerp(1.1, 1.0, clampedZeroBasedScale) - 24;
      prdHeight = 4 * namePlateVerticalScale * Lerp(1.2, 1.0, clampedZeroBasedScale) * 2  + 1;
      personalRessourceDisplayFrame:SetScale(1 / UIParent:GetEffectiveScale());
      personalRessourceDisplayFrame.texture:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\PRDFrame");
    end

    local scale = UIParent:GetEffectiveScale() / personalRessourceDisplayFrame:GetEffectiveScale();
    if (not xOffset or not yOffset) then
      local optionsFrame = WeakAuras.OptionsFrame();
      yOffset = optionsFrame:GetBottom() + prdHeight / scale - GetScreenHeight();
      xOffset = xPositionNextToOptions() + prdWidth / 2 / scale - GetScreenWidth();
    end

    xOffset = xOffset * scale;
    yOffset = yOffset * scale;

    personalRessourceDisplayFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xOffset, yOffset);
    personalRessourceDisplayFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPRIGHT", xOffset - prdWidth, yOffset - prdHeight);
  end

  personalRessourceDisplayFrame.OptionsClosed = function()
    personalRessourceDisplayFrame:SetScale(1);
    local frame = C_NamePlate.GetNamePlateForUnit("player");
    if (frame) then
      if (frame.kui and frame.kui.bg and frame.kui:IsShown()) then
        personalRessourceDisplayFrame:Attach(frame.kui, frame.kui.bg, frame.kui.bg);
      elseif (ElvUIPlayerNamePlateAnchor) then
        personalRessourceDisplayFrame:Attach(ElvUIPlayerNamePlateAnchor, ElvUIPlayerNamePlateAnchor, ElvUIPlayerNamePlateAnchor);
      else
        personalRessourceDisplayFrame:Attach(frame, frame.UnitFrame.healthBar, NamePlateDriverFrame.nameplateManaBar);
      end
    else
      personalRessourceDisplayFrame:Detach();
      personalRessourceDisplayFrame:Hide();
    end

    personalRessourceDisplayFrame:SetScript("OnEvent", personalRessourceDisplayFrame.eventHandler);
    personalRessourceDisplayFrame.texture:Hide();
    personalRessourceDisplayFrame.moverFrame:Hide();
    wipe(personalRessourceDisplayFrame.attachedVisibleFrames);
  end

  personalRessourceDisplayFrame.eventHandler = function(self, event, nameplate)
    WeakAuras.StartProfileSystem("prd");
    if (event == "NAME_PLATE_UNIT_ADDED") then
      if (UnitIsUnit(nameplate, "player")) then
        local frame = C_NamePlate.GetNamePlateForUnit("player");
        if (frame) then
          if (frame.kui and frame.kui.bg and frame.kui:IsShown()) then
            personalRessourceDisplayFrame:Attach(frame.kui, frame.kui.bg, frame.kui.bg);
          elseif (ElvUIPlayerNamePlateAnchor) then
            personalRessourceDisplayFrame:Attach(ElvUIPlayerNamePlateAnchor, ElvUIPlayerNamePlateAnchor, ElvUIPlayerNamePlateAnchor);
          else
            personalRessourceDisplayFrame:Attach(frame, frame.UnitFrame.healthBar, NamePlateDriverFrame.nameplateManaBar);
          end
          personalRessourceDisplayFrame:Show();
          db.personalRessourceDisplayFrame = db.personalRessourceDisplayFrame or {};
        else
          personalRessourceDisplayFrame:Detach();
          personalRessourceDisplayFrame:Hide();
        end
      end
    elseif (event == "NAME_PLATE_UNIT_REMOVED") then
      if (UnitIsUnit(nameplate, "player")) then
        personalRessourceDisplayFrame:Detach();
        personalRessourceDisplayFrame:Hide();
      end
    end
    WeakAuras.StopProfileSystem("prd");
  end

  personalRessourceDisplayFrame.expand = function(self, id)
    local data = WeakAuras.GetData(id);
    if (data.anchorFrameType == "PRD") then
      self.attachedVisibleFrames[id] = true;
      self:updateVisible();
    end
  end

  personalRessourceDisplayFrame.collapse = function(self, id)
    self.attachedVisibleFrames[id] = nil;
    self:updateVisible();
  end

  personalRessourceDisplayFrame.rename = function(self, oldid, newid)
    self.attachedVisibleFrames[newid] = self.attachedVisibleFrames[oldid];
    self.attachedVisibleFrames[oldid] = nil;
    self:updateVisible();
  end

  personalRessourceDisplayFrame.delete = function(self, id)
    self.attachedVisibleFrames[id] = nil;
    self:updateVisible();
  end

  personalRessourceDisplayFrame.anchorFrame = function(self, id, anchorFrameType)
    if (anchorFrameType == "PRD") then
      self.attachedVisibleFrames[id] = true;
    else
      self.attachedVisibleFrames[id] = nil;
    end
    self:updateVisible();
  end

  personalRessourceDisplayFrame.updateVisible = function(self)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end

    if (next(self.attachedVisibleFrames)) then
      personalRessourceDisplayFrame.texture:Show();
      personalRessourceDisplayFrame.moverFrame:Show();
      personalRessourceDisplayFrame:Show();
    else
      personalRessourceDisplayFrame.texture:Hide();
      personalRessourceDisplayFrame.moverFrame:Hide();
      personalRessourceDisplayFrame:Hide();
    end
  end

  if (WeakAuras.IsOptionsOpen()) then
    personalRessourceDisplayFrame.OptionsOpened();
  else
    personalRessourceDisplayFrame.OptionsClosed();
  end
end

local postPonedAnchors = {};
local anchorTimer

local function tryAnchorAgain()
  local delayed = postPonedAnchors;
  postPonedAnchors = {};
  anchorTimer = nil;

  for id, _ in pairs(delayed) do
    local data = WeakAuras.GetData(id);
    local region = WeakAuras.GetRegion(id);
    if (data and region) then
      local parent = frame;
      if (data.parent and regions[data.parent]) then
        parent = regions[data.parent].region;
      end
      WeakAuras.AnchorFrame(data, region, parent);
    end
  end
end

local function postponeAnchor(id)
  postPonedAnchors[id] = true;
  if (not anchorTimer) then
    anchorTimer = timer:ScheduleTimer(tryAnchorAgain, 1);
  end
end

local function GetAnchorFrame(id, anchorFrameType, parent, anchorFrameFrame)
  if (personalRessourceDisplayFrame) then
    personalRessourceDisplayFrame:anchorFrame(id, anchorFrameType);
  end

  if (mouseFrame) then
    mouseFrame:anchorFrame(id, anchorFrameType);
  end

  if (anchorFrameType == "SCREEN") then
    return parent;
  end

  if (anchorFrameType == "PRD") then
    ensurePRDFrame();
    personalRessourceDisplayFrame:anchorFrame(id, anchorFrameType);
    return personalRessourceDisplayFrame;
  end

  if (anchorFrameType == "MOUSE") then
    ensureMouseFrame();
    mouseFrame:anchorFrame(id, anchorFrameType);
    return mouseFrame;
  end

  if (anchorFrameType == "SELECTFRAME" and anchorFrameFrame) then
    if(anchorFrameFrame:sub(1, 10) == "WeakAuras:") then
      local frame_name = anchorFrameFrame:sub(11);
      if (frame_name == id) then
        return parent;
      end
      if(regions[frame_name]) then
        return regions[frame_name].region;
      end
      postponeAnchor(id);
    else
      if (exec_env[anchorFrameFrame]) then
        return exec_env[anchorFrameFrame];
      end
      postponeAnchor(id);
      return  parent;
    end
  end
  -- Fallback
  return parent;
end

function WeakAuras.AnchorFrame(data, region, parent)
  local anchorParent = GetAnchorFrame(data.id, data.anchorFrameType, parent,  data.anchorFrameFrame);
  if (data.anchorFrameParent or data.anchorFrameParent == nil
      or data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE") then
    region:SetParent(anchorParent);
  else
    region:SetParent(frame);
  end

  region:SetAnchor(data.selfPoint, anchorParent, data.anchorPoint);

  if(data.frameStrata == 1) then
    region:SetFrameStrata(region:GetParent():GetFrameStrata());
  else
    region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
  end
end

local profileData = {};
profileData.systems = {};
profileData.auras = {};

local function StartProfile(map, id)
  if (not map[id]) then
    map[id] = {};
    map[id].count = 1;
    map[id].start = debugprofilestop();
    map[id].elapsed = 0;
    return;
  end

  if (map[id].count == 0) then
    map[id].count = 1;
    map[id].start = debugprofilestop();
  else
    map[id].count = map[id].count + 1;
  end
end

local function StopProfile(map, id)
  map[id].count = map[id].count - 1;
  if (map[id].count == 0) then
    map[id].elapsed = map[id].elapsed + debugprofilestop() - map[id].start;
  end
end

local function StartProfileSystem(system)
  StartProfile(profileData.systems, "wa");
  StartProfile(profileData.systems, system);
end

local function StartProfileAura(id)
  StartProfile(profileData.auras, id);
end

local function StopProfileSystem(system)
  StopProfile(profileData.systems, "wa");
  StopProfile(profileData.systems, system);
end

local function StopProfileAura(id)
  StopProfile(profileData.auras, id);
end

function WeakAuras.ProfileRenameAura(oldid, id)
  profileData.auras[id] = profileData.auras[id];
  profileData.auras[oldid] = nil;
end

function WeakAuras.StartProfile()
  if (profileData.systems.time and profileData.systems.time.count == 1) then
    prettyPrint(L["Profiling already started."]);
    return;
  end

  prettyPrint(L["Profiling started."])

  profileData.systems = {};
  profileData.auras = {};
  profileData.systems.time = {};
  profileData.systems.time.start = debugprofilestop();
  profileData.systems.time.count = 1;

  WeakAuras.StartProfileSystem = StartProfileSystem;
  WeakAuras.StartProfileAura = StartProfileAura;
  WeakAuras.StopProfileSystem = StopProfileSystem;
  WeakAuras.StopProfileAura = StopProfileAura;
end

local function doNothing()
end

function WeakAuras.StopProfile()
  if (not profileData.systems.time or profileData.systems.time.count ~= 1) then
    prettyPrint(L["Profiling not running."]);
    return;
  end

  prettyPrint(L["Profiling stopped."])

  profileData.systems.time.elapsed = debugprofilestop() - profileData.systems.time.start;
  profileData.systems.time.count = 0;

  WeakAuras.StartProfileSystem = doNothing;
  WeakAuras.StartProfileAura = doNothing;
  WeakAuras.StopProfileSystem = doNothing;
  WeakAuras.StopProfileAura = doNothing;
end

local function PrintOneProfile(name, map, total)
  if (map.count ~= 0) then
    print(name, " ERROR: count is not zero:", map.count);
  end
  local percent = "";
  if (total) then
    percent = ", " .. string.format("%.2f", 100 * map.elapsed / total) .. "%";
  end
  print(name, " ", string.format("%.2f", map.elapsed), " ms", percent);
end

local function SortProfileMap(map)
  local result = {};
  for k, v in pairs(map) do
    tinsert(result, k);
  end

  sort(result, function(a, b)
    return map[a].elapsed > map[b].elapsed;
  end);

  return result;
end

local function TotalProfileTime(map)
  local total = 0;
  for k, v in pairs(map) do
    total = total + v.elapsed;
  end
  return total;
end

function WeakAuras.PrintProfile()
  if (not profileData.systems.time) then
    prettyPrint(L["No Profiling information saved."]);
    return;
  end

  if (profileData.systems.time.count == 1) then
    prettyPrint(L["Profiling still running, stop before trying to print."]);
    return;
  end

  print("--------------------------------");
  prettyPrint(L["EXPERIMENTAL Profiling Data:"]);
  PrintOneProfile("Total Time:    ", profileData.systems.time);
  PrintOneProfile("Time inside WA:", profileData.systems.wa);
  print("% Time spent inside WA:", string.format("%.2f", 100 * profileData.systems.wa.elapsed / profileData.systems.time.elapsed));
  print("");
  print("Systems:");

  for i, k in ipairs(SortProfileMap(profileData.systems)) do
    if (k ~= "time" and k~= "wa") then
      PrintOneProfile(k, profileData.systems[k], profileData.systems.wa.elapsed);
    end
  end

  print("");
  print("Auras:");
  local total = TotalProfileTime(profileData.auras);
  print("Total Time attributed to auras: ", total);
  for i, k in ipairs(SortProfileMap(profileData.auras)) do
    PrintOneProfile(k, profileData.auras[k], total);
  end
  print("--------------------------------");
end

function WeakAuras.FindUnusedId(prefix)
  prefix = prefix or "New"
  local num = 2;
  local id = prefix
  while(db.displays[id]) do
    id = prefix .. " " .. num;
    num = num + 1;
  end
  return id
end
