---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local internalVersion = 85

-- Lua APIs
local insert = table.insert

-- WoW APIs
local GetTalentInfo, InCombatLockdown = GetTalentInfo, InCombatLockdown
local UnitName, GetRealmName, UnitRace, UnitFactionGroup, IsInRaid
  = UnitName, GetRealmName, UnitRace, UnitFactionGroup, IsInRaid
local UnitClass, UnitExists, UnitGUID, UnitAffectingCombat, GetInstanceInfo, IsInInstance
  = UnitClass, UnitExists, UnitGUID, UnitAffectingCombat, GetInstanceInfo, IsInInstance
local UnitIsUnit, GetRaidRosterInfo, GetSpecialization, UnitInVehicle, UnitHasVehicleUI
  = UnitIsUnit, GetRaidRosterInfo, GetSpecialization, UnitInVehicle, UnitHasVehicleUI
local SendChatMessage, UnitInBattleground, UnitInRaid, UnitInParty, GetTime
  = SendChatMessage, UnitInBattleground, UnitInRaid, UnitInParty, GetTime
local CreateFrame, IsShiftKeyDown, GetScreenWidth, GetScreenHeight, GetCursorPosition, UpdateAddOnCPUUsage, GetFrameCPUUsage, debugprofilestop
  = CreateFrame, IsShiftKeyDown, GetScreenWidth, GetScreenHeight, GetCursorPosition, UpdateAddOnCPUUsage, GetFrameCPUUsage, debugprofilestop
local debugstack = debugstack
local GetNumTalentTabs, GetNumTalents = GetNumTalentTabs, GetNumTalents
local MAX_NUM_TALENTS = MAX_NUM_TALENTS or 20

local ADDON_NAME = "WeakAuras"
---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L
local versionString = WeakAuras.versionString
local prettyPrint = WeakAuras.prettyPrint

WeakAurasTimers = setmetatable({}, {__tostring=function() return "WeakAuras" end})
LibStub("AceTimer-3.0"):Embed(WeakAurasTimers)

Private.maxTimerDuration = 604800; -- A week, in seconds
local maxUpTime = 4294967; -- 2^32 / 1000

Private.watched_trigger_events = {}

-- The worlds simplest callback system.
-- That supports 1:N, but no de-registration and breaks if registering in a callback
--- @class callbacks
--- @field events table
--- @field RegisterCallback fun(self: callbacks, event: string, handler: function)
--- @field Fire fun(self: callbacks, event: string, ... : any)
Private.callbacks = {}
Private.callbacks.events = {}

function Private.callbacks:RegisterCallback(event, handler)
  self.events[event] = self.events[event] or {}
  tinsert(self.events[event], handler)
end

function Private.callbacks:Fire(event, ...)
  if self.events[event] then
    for index, f in ipairs(self.events[event]) do
      f(event, ...)
    end
  end
end

function WeakAurasTimers:ScheduleTimerFixed(func, delay, ...)
  if (delay < Private.maxTimerDuration) then
    if delay + GetTime() > maxUpTime then
      WeakAuras.prettyPrint(WeakAuras.L["Can't schedule timer with %i, due to a World of Warcraft bug with high computer uptime. (Uptime: %i). Please restart your computer."]:format(delay, GetTime()))
      return
    end
    return self:ScheduleTimer(func, delay, ...)
  end
end

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local LCG = LibStub("LibCustomGlow-1.0")
local LGF = LibStub("LibGetFrame-1.0")

local CustomNames = C_AddOns.IsAddOnLoaded("CustomNames") and LibStub("CustomNames") -- optional addon
if CustomNames then
  WeakAuras.GetName = CustomNames.Get
  WeakAuras.UnitName = CustomNames.UnitName
  WeakAuras.GetUnitName = CustomNames.GetUnitName
  WeakAuras.UnitFullName = CustomNames.UnitFullName
else
  WeakAuras.GetName = function(name) return name end
  WeakAuras.UnitName = UnitName
  WeakAuras.GetUnitName = GetUnitName
  WeakAuras.UnitFullName = UnitFullName
end

local timer = WeakAurasTimers
WeakAuras.timer = timer

local loginQueue = {}
local queueshowooc

function WeakAuras.InternalVersion()
  return internalVersion;
end

do
  local currentErrorHandlerId
  local currentErrorHandlerUid
  local currentErrorHandlerContext
  local function waErrorHandler(errorMessage)
    local juicedMessage = {}
    local data
    if currentErrorHandlerId then
      data = WeakAuras.GetData(currentErrorHandlerId)
    elseif currentErrorHandlerUid then
      data = Private.GetDataByUID(currentErrorHandlerUid)
    end
    if data then
      Private.AuraWarnings.UpdateWarning(data.uid, "LuaError", "error",
        L["This aura has caused a Lua error."] .. "\n" .. L["Install the addons BugSack and BugGrabber for detailed error logs."], true)
      table.insert(juicedMessage, L["Lua error in aura '%s': %s"]:format(data.id, currentErrorHandlerContext or L["unknown location"]))
    else
      table.insert(juicedMessage, L["Lua error"])
    end
    table.insert(juicedMessage, L["WeakAuras Version: %s"]:format(WeakAuras.versionString))
    local version = data and (data.semver or data.version)
    if version then
      table.insert(juicedMessage, L["Aura Version: %s"]:format(version))
    end
    table.insert(juicedMessage, L["Stack trace:"])
    table.insert(juicedMessage, errorMessage)
    geterrorhandler()(table.concat(juicedMessage, "\n"))
  end

  function Private.GetErrorHandlerId(id, context)
    currentErrorHandlerUid = nil
    currentErrorHandlerId = id
    currentErrorHandlerContext = context
    return waErrorHandler
  end
  function Private.GetErrorHandlerUid(uid, context)
    currentErrorHandlerUid = uid
    currentErrorHandlerId = nil
    currentErrorHandlerContext = context
    return waErrorHandler
  end
end

function Private.LoadOptions(msg)
  if not(C_AddOns.IsAddOnLoaded("WeakAurasOptions")) then
    if not WeakAuras.IsLoginFinished() then
      prettyPrint(Private.LoginMessage())
      loginQueue[#loginQueue + 1] = WeakAuras.OpenOptions
    elseif InCombatLockdown() then
      -- inform the user and queue ooc
      prettyPrint(L["Options will finish loading after combat ends."])
      queueshowooc = msg or "";
      Private.frames["Addon Initialization Handler"]:RegisterEvent("PLAYER_REGEN_ENABLED")
      return false;
    else
      local loaded, reason = C_AddOns.LoadAddOn("WeakAurasOptions");
      if not(loaded) then
        reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
        WeakAuras.prettyPrint(string.format(L["Options could not be loaded, the addon is %s"], reason));
        return false;
      end
    end
  end
  return true;
end

function WeakAuras.OpenOptions(msg)
  if Private.NeedToRepairDatabase() then
    StaticPopup_Show("WEAKAURAS_CONFIRM_REPAIR", nil, nil, {reason = "downgrade"})
  elseif (WeakAuras.IsLoginFinished() and Private.LoadOptions(msg)) then
    WeakAuras.ToggleOptions(msg, Private);
  end
end

function Private.PrintHelp()
  print(L["Usage:"])
  print(L["/wa help - Show this message"])
  print(L["/wa minimap - Toggle the minimap icon"])
  print(L["/wa pstart - Start profiling. Optionally include a duration in seconds after which profiling automatically stops. To profile the next combat/encounter, pass a \"combat\" or \"encounter\" argument."])
  print(L["/wa pstop - Finish profiling"])
  print(L["/wa pprint - Show the results from the most recent profiling"])
  print(L["/wa repair - Repair tool"])
  print(L["If you require additional assistance, please open a ticket on GitHub or visit our Discord at https://discord.gg/weakauras!"])
end

SLASH_WEAKAURAS1, SLASH_WEAKAURAS2 = "/weakauras", "/wa";
function SlashCmdList.WEAKAURAS(input)
  local args, msg = {}, nil

  for v in string.gmatch(input, "%S+") do
    if not msg then
      msg = v:lower()
    else
      insert(args, v:lower())
    end
  end

  if msg == "pstart" then
    WeakAuras.StartProfile(args[1]);
  elseif msg == "pstop" then
    WeakAuras.StopProfile();
  elseif msg == "pprint" then
    WeakAuras.PrintProfile();
  elseif msg == "pcancel" then
    WeakAuras.CancelScheduledProfile()
  elseif msg == "pshow" or msg == "profiling" then
    WeakAurasProfilingFrame:Toggle()
  elseif msg == "minimap" then
    WeakAuras.ToggleMinimap();
  elseif msg == "help" then
    Private.PrintHelp();
  elseif msg == "repair" then
    StaticPopup_Show("WEAKAURAS_CONFIRM_REPAIR", nil, nil, {reason = "user"})
  elseif msg == "ff" or msg == "feat" or msg == "feature" then
    if #args < 2 then
      local features = Private.Features:ListFeatures()
      local summary = {}
      for _, feature in ipairs(features) do
        table.insert(summary, ("|c%s%s|r"):format(feature.enabled and "ff00ff00" or "ffff0000", feature.id))
      end
      prettyPrint(L["Syntax /wa feature <toggle|on|enable|disable|off> <feature>"])
      prettyPrint(L["Available features: %s"]:format(table.concat(summary, ", ")))
    else
      local action = ({
        toggle = "toggle",
        on = "enable",
        enable = "enable",
        disable = "disable",
        off = "disable"
      })[args[1]]
      if not action then
        prettyPrint(L["Unknown action %q"]:format(args[1]))
      else
        local feature = args[2]
        if not Private.Features:Exists(feature) then
          prettyPrint(L["Unknown feature %q"]:format(feature))
        elseif not Private.Features:Enabled(feature) then
          if action ~= "disable" then
            Private.Features:Enable(feature)
            prettyPrint(L["Enabled feature %q"]:format(feature))
          else
            prettyPrint(L["Feature %q is already disabled"]:format(feature))
          end
        elseif Private.Features:Enabled(feature) then
          if action ~= "enable" then
            Private.Features:Disable(feature)
            prettyPrint(L["Disabled feature %q"]:format(feature))
          else
            prettyPrint(L["Feature %q is already enabled"]:format(feature))
          end
        end
      end
    end
  else
    WeakAuras.OpenOptions(msg);
  end
end

if not WeakAuras.IsLibsOK() then return end

function WeakAuras.ToggleMinimap()
  WeakAurasSaved.minimap.hide = not WeakAurasSaved.minimap.hide
  if WeakAurasSaved.minimap.hide then
    LDBIcon:Hide("WeakAuras");
    prettyPrint(L["Use /wa minimap to show the minimap icon again."])
  else
    LDBIcon:Show("WeakAuras");
  end
end

BINDING_HEADER_WEAKAURAS = ADDON_NAME
BINDING_NAME_WEAKAURASTOGGLE = L["Toggle Options Window"]
BINDING_NAME_WEAKAURASPROFILINGTOGGLE = L["Toggle Performance Profiling Window"]
BINDING_NAME_WEAKAURASPRINTPROFILING = L["Print Profiling Results"]

-- An alias for WeakAurasSaved, the SavedVariables
-- Noteable properties:
--  debug: If set to true, WeakAura.debug() outputs messages to the chat frame
--  displays: All aura settings, keyed on their id

---@class WeakAurasSaved
local db;

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
-- Mapping of events to ids, contains true if a aura should be checked for a certain event
local loadEvents = {}

-- All regions keyed on id, has properties: region, regionType, also see clones
Private.regions = {};

-- keyed on id, contains bool indicating whether the aura is loaded
Private.loaded = {};
local loaded = Private.loaded;

-- contains regions for clones
Private.clones = {};
local clones = Private.clones;

-- Unused regions that are kept around for clones
local clonePool = {}

-- One table per regionType, see RegisterRegionType, notable properties: create, modify and default
Private.regionTypes = {};
local regionTypes = Private.regionTypes;

Private.subRegionTypes = {}
local subRegionTypes = Private.subRegionTypes

-- One table per regionType, see RegisterRegionOptions
Private.regionOptions = {};
local regionOptions = Private.regionOptions;

Private.subRegionOptions = {}
local subRegionOptions = Private.subRegionOptions

-- Maps from trigger type to trigger system
Private.triggerTypes = {};
local triggerTypes = Private.triggerTypes;

-- Maps from trigger type to a function that can create options for the trigger
Private.triggerTypesOptions = {};

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

local triggerState = {}

-- Fallback states
local fallbacksStates = {};

-- List of all trigger systems, contains each system once
local triggerSystems = {}

local timers = {}; -- Timers for autohiding, keyed on id, triggernum, cloneid

WeakAuras.raidUnits = {};
WeakAuras.raidpetUnits = {};
WeakAuras.partyUnits = {};
WeakAuras.partypetUnits = {};
WeakAuras.petUnitToUnit = {
  pet = "player"
}
WeakAuras.unitToPetUnit = {
  player = "pet"
}
do
  for i=1,40 do
    WeakAuras.raidUnits[i] = "raid"..i
    WeakAuras.raidpetUnits[i] = "raidpet"..i
    WeakAuras.petUnitToUnit["raidpet"..i] = "raid"..i
    WeakAuras.unitToPetUnit["raid"..i] = "raidpet"..i
  end
  for i=1,4 do
    WeakAuras.partyUnits[i] = "party"..i
    WeakAuras.partypetUnits[i] = "partypet"..i
    WeakAuras.petUnitToUnit["partypet"..i] = "party"..i
    WeakAuras.unitToPetUnit["party"..i] = "partypet"..i
  end
end

---@param unit UnitToken
---@return boolean isPet
WeakAuras.UnitIsPet = function(unit)
  return WeakAuras.petUnitToUnit[unit] ~= nil
end

local playerLevel = UnitLevel("player");
local currentInstanceType = "none"

-- Custom Action Functions, keyed on id, "init" / "start" / "finish"
Private.customActionsFunctions = {};

-- Custom Functions used in conditions, keyed on id, condition number, "changes", property number
Private.ExecEnv.customConditionsFunctions = {};
-- Text format functions for chat messages, keyed on id, condition number, changes, property number
Private.ExecEnv.conditionTextFormatters = {}

-- Helpers for conditions, that is custom run functions and preamble objects for built in checks
-- keyed on UID not on id!
Private.ExecEnv.conditionHelpers = {}

local load_prototype = Private.load_prototype;

function Private.validate(input, default)
  for field, defaultValue in pairs(default) do
    if(type(defaultValue) == "table" and type(input[field]) ~= "table") then
      input[field] = {};
    elseif(input[field] == nil) or (type(input[field]) ~= type(defaultValue)) then
      input[field] = defaultValue;
    end
    if(type(input[field]) == "table") then
      Private.validate(input[field], defaultValue);
    end
  end
end

---@diagnostic disable-next-line: duplicate-set-field
function Private.RegisterRegionType(name, createFunction, modifyFunction, default, properties, validate)
  if not(name) then
    error("Improper arguments to Private.RegisterRegionType - name is not defined", 2);
  elseif(type(name) ~= "string") then
    error("Improper arguments to Private.RegisterRegionType - name is not a string", 2);
  elseif not(createFunction) then
    error("Improper arguments to Private.RegisterRegionType - creation function is not defined", 2);
  elseif(type(createFunction) ~= "function") then
    error("Improper arguments to Private.RegisterRegionType - creation function is not a function", 2);
  elseif not(modifyFunction) then
    error("Improper arguments to Private.RegisterRegionType - modification function is not defined", 2);
  elseif(type(modifyFunction) ~= "function") then
    error("Improper arguments to Private.RegisterRegionType - modification function is not a function", 2)
  elseif not(default) then
    error("Improper arguments to Private.RegisterRegionType - default options are not defined", 2);
  elseif(type(default) ~= "table") then
    error("Improper arguments to Private.RegisterRegionType - default options are not a table", 2);
  elseif(type(default) ~= "table" and type(default) ~= "nil") then
    error("Improper arguments to Private.RegisterRegionType - properties options are not a table", 2);
  elseif(regionTypes[name]) then
    error("Improper arguments to Private.RegisterRegionType - region type \""..name.."\" already defined", 2);
  else
    regionTypes[name] = {
      create = createFunction,
      modify = modifyFunction,
      default = default,
      validate = validate,
      properties = properties,
    };
  end
end

---@private
---@param name string
---@param displayName string
---@param supportFunction function
---@param createFunction function
---@param modifyFunction function
---@param onAcquire function
---@param onRelease function
---@param default table
---@param addDefaultsForNewAura function
---@param properties table
---@param supportsAdd? boolean
function WeakAuras.RegisterSubRegionType(name, displayName, supportFunction, createFunction, modifyFunction, onAcquire, onRelease, default, addDefaultsForNewAura, properties, supportsAdd)
  if not(name) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - name is not defined", 2);
  elseif(type(name) ~= "string") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - name is not a string", 2);
  elseif not(displayName) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - display name is not defined".." "..name, 2);
  elseif(type(displayName) ~= "string") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - display name is not a string", 2);
  elseif not(supportFunction) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - support function is not defined", 2);
  elseif(type(supportFunction) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - support function is not a function", 2);
  elseif not(createFunction) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - creation function is not defined", 2);
  elseif(type(createFunction) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - creation function is not a function", 2);
  elseif not(modifyFunction) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - modification function is not defined", 2);
  elseif(type(modifyFunction) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - modification function is not a function", 2)
  elseif not(onAcquire) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - onAcquire function is not defined", 2);
  elseif(type(onAcquire) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - onAcquire function is not a function", 2)
  elseif not(onRelease) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - onRelease function is not defined", 2);
  elseif(type(onRelease) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - onRelease function is not a function", 2)
  elseif not(default) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - default options are not defined", 2);
  elseif(type(default) ~= "table" and type(default) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - default options are not a table or a function", 2);
  elseif(addDefaultsForNewAura and type(addDefaultsForNewAura) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - addDefaultsForNewAura function is not nil or a function", 2)
  elseif(subRegionTypes[name]) then
    error("Improper arguments to WeakAuras.RegisterSubRegionType - region type \""..name.."\" already defined", 2);
  else
    local pool = CreateObjectPool(createFunction)

    subRegionTypes[name] = {
      displayName = displayName,
      supports = supportFunction,
      modify = modifyFunction,
      default = default,
      addDefaultsForNewAura = addDefaultsForNewAura,
      properties = properties,
      supportsAdd = supportsAdd == nil or supportsAdd,
      acquire = function()
        local subRegion = pool:Acquire()
        onAcquire(subRegion)
        subRegion.type = name
        return subRegion
      end,
      release = function(subRegion)
        onRelease(subRegion)
        pool:Release(subRegion)
      end
    };
  end
end

---@diagnostic disable-next-line: duplicate-set-field
function Private.RegisterRegionOptions(name, createFunction, icon, displayName, createThumbnail, modifyThumbnail, description, templates, getAnchors)
  if not(name) then
    error("Improper arguments to Private.RegisterRegionOptions - name is not defined", 2);
  elseif(type(name) ~= "string") then
    error("Improper arguments to Private.RegisterRegionOptions - name is not a string", 2);
  elseif not(createFunction) then
    error("Improper arguments to Private.RegisterRegionOptions - creation function is not defined", 2);
  elseif(type(createFunction) ~= "function") then
    error("Improper arguments to Private.RegisterRegionOptions - creation function is not a function", 2);
  elseif not(icon) then
    error("Improper arguments to Private.RegisterRegionOptions - icon is not defined", 2);
  elseif not(type(icon) == "string" or type(icon) == "function") then
    error("Improper arguments to Private.RegisterRegionOptions - icon is not a string or a function", 2)
  elseif not(displayName) then
    error("Improper arguments to Private.RegisterRegionOptions - display name is not defined".." "..name, 2);
  elseif(type(displayName) ~= "string") then
    error("Improper arguments to Private.RegisterRegionOptions - display name is not a string", 2);
  elseif (getAnchors and type(getAnchors) ~= "function") then
    error("Improper arguments to Private.RegisterRegionOptions - anchors is not a function", 2);
  elseif(regionOptions[name]) then
    error("Improper arguments to Private.RegisterRegionOptions - region type \""..name.."\" already defined", 2);
  else
    local templateIcon
    if (type(icon) == "function") then
      -- We only want to create two icons and reparent it as needed
      templateIcon = icon()
      templateIcon:Hide()
      icon = icon()
      icon:Hide()
    else
      templateIcon = icon
    end

    local acquireThumbnail, releaseThumbnail
    if createThumbnail and modifyThumbnail then
      local thumbnailPool = CreateObjectPool(createThumbnail)
      acquireThumbnail = function(parent, data)
        local thumbnail, newObject = thumbnailPool:Acquire()
        thumbnail:Show()
        modifyThumbnail(parent, thumbnail, data)
        return thumbnail
      end
      releaseThumbnail = function(thumbnail)
        thumbnail:Hide()
        thumbnailPool:Release(thumbnail)
      end
    end
    regionOptions[name] = {
      create = createFunction,
      icon = icon,
      templateIcon = templateIcon,
      displayName = displayName,
      createThumbnail = createThumbnail,
      modifyThumbnail = modifyThumbnail,
      acquireThumbnail = acquireThumbnail,
      releaseThumbnail = releaseThumbnail,
      description = description,
      templates = templates,
      getAnchors = getAnchors
    };
  end
end

---@private
---@param name string
---@param createFunction function
---@param description string
---@param getAnchors function?
function WeakAuras.RegisterSubRegionOptions(name, createFunction, description, getAnchors)
  if not(name) then
    error("Improper arguments to WeakAuras.RegisterSubRegionOptions - name is not defined", 2);
  elseif(type(name) ~= "string") then
    error("Improper arguments to WeakAuras.RegisterSubRegionOptions - name is not a string", 2);
  elseif not(createFunction) then
    error("Improper arguments to WeakAuras.RegisterSubRegionOptions - creation function is not defined", 2);
  elseif(type(createFunction) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionOptions - creation function is not a function", 2);
  elseif(getAnchors and type(getAnchors) ~= "function") then
    error("Improper arguments to WeakAuras.RegisterSubRegionOptions - getAnchors function is not a function", 2);
  elseif(subRegionOptions[name]) then
    error("Improper arguments to WeakAuras.RegisterSubRegionOptions - region type \""..name.."\" already defined", 2);
  else
    subRegionOptions[name] = {
      create = createFunction,
      getAnchors = getAnchors,
      description = description,
    };
  end
end

---@diagnostic disable-next-line: duplicate-set-field (it's replaced in WeakAurasOptions.lua)
function WeakAuras.IsOptionsOpen()
  return false;
end

function Private.ParseNumber(numString)
  if not(numString and type(numString) == "string") then
    if(type(numString) == "number") then
      return numString, "notastring";
    else
      return nil;
    end
  elseif(numString:sub(-1) == "%") then
    local percent = tonumber(numString:sub(1, -2));
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

local function EvalBooleanArg(arg, trigger, default)
  if(type(arg) == "function") then
    return arg(trigger);
  elseif type(arg) == "boolean" then
    return arg
  elseif type(arg) == "nil" then
    return default
  end
end

local function singleTest(arg, trigger, use, name, value, operator, use_exact, caseInsensitive)
  local number = value and tonumber(value) or nil
  if(arg.type == "tristate") then
    if(use == false) then
      return "(not "..name..")";
    elseif(use) then
      if(arg.test) then
        return "("..arg.test:format(value)..")";
      else
        return name;
      end
    end
  elseif(arg.type == "tristatestring") then
    if(use == false) then
      return "("..name.. "~=".. (number or string.format("%s", Private.QuotedString(value or ""))) .. ")"
    elseif(use) then
      return "("..name.. "==".. (number or string.format("%s", Private.QuotedString(value or ""))) .. ")"
    end
  elseif(arg.type == "multiselect") then
    if arg.multiNoSingle then
      -- convert single to multi
      -- this is a lazy migration because multiNoSingle is not set for all game versions
      if use == true then
        trigger["use_"..name] = false
        trigger[name] = trigger[name] or {}
        trigger[name].multi = {};
        if trigger[name].single ~= nil then
          trigger[name].multi[trigger[name].single] = true;
          trigger[name].single = nil
        end
      end
    end
    if(use == false) then -- multi selection
      local any = false;
      if (value and value.multi) then
        local test = "(";
        for value, positive in pairs(value.multi) do
          local arg1 = tonumber(value) or ("[["..value.."]]")
          local arg2
          if arg.extraOption then
            arg2 = trigger[name .. "_extraOption"] or 0
          elseif arg.multiTristate then
            arg2 = positive and 4 or 5
          end
          local testEnabled = true
          if type(arg.enableTest) == "function" then
            testEnabled = arg.enableTest(trigger, arg1, arg2)
          end
          if testEnabled then
            local check
            if not arg.test then
              check = name.."=="..arg1
            else
              check = arg.test:format(arg1, arg2)
            end
            if arg.multiAll then
              test = test..check.." and "
            else
              test = test..check.." or  "
            end
            any = true;
          end
        end
        if(any) then
          test = test:sub(1, -6);
        else
          test = "(false";
        end
        test = test..")"
        if arg.inverse then
          if type(arg.inverse) == "boolean" then
            test = "not " .. test
          elseif type(arg.inverse) == "function" then
            if arg.inverse(trigger) then
              test = "not " .. test
            end
          end
        end
        return test
      end
    elseif(use) then -- single selection
      local value = value and value.single or nil;
      if not arg.test then
        return value and "("..name.."=="..(tonumber(value) or ("[["..value.."]]"))..")";
      else
        return value and "("..arg.test:format(tonumber(value) or ("[["..value.."]]"))..")";
      end
    end
  elseif(arg.type == "toggle") then
    if(use) then
      if(arg.test) then
        return "("..arg.test:format(value)..")";
      else
        return name;
      end
    end
  elseif (arg.type == "spell") then
    if arg.showExactOption then
      return "("..arg.test:format(value, tostring(use_exact) or "false") ..")";
    else
      return "("..arg.test:format(value)..")";
    end
  elseif(arg.test) then
    return "("..arg.test:format(value)..")";
  elseif(arg.type == "longstring" and operator) then
    if(operator == "==") then
      if caseInsensitive then
        return ("(%s and %s:lower() == [[%s]]:lower())"):format(name, name, value)
      else
        return "("..name.."==[["..value.."]])";
      end
    else
      if caseInsensitive then
        local op = operator:format(value:lower())
        return ("(%s:lower():%s)"):format(name, op)
      else
        return "("..name..":"..operator:format(value)..")";
      end
    end
  elseif(arg.type == "number") then
    if number then
      return "("..name..(operator or "==").. number ..")";
    end
  else
    if(type(value) == "table") then
      value = "error";
    end
    return "("..name..(operator or "==")..(number or ("[["..(value or "").."]]"))..")";
  end
end

-- Used for the load function, could be simplified a bit
-- It used to be also used for the generic trigger system
local function ConstructFunction(prototype, trigger, skipOptional)
  local input = {"event"};
  local required = {};
  local tests = {};
  local debug = {};
  local events = {}
  local init;
  local preambles = ""
  local orConjunctionGroups = {}
  if(prototype.init) then
    init = prototype.init(trigger);
  else
    init = "";
  end
  for index, arg in pairs(prototype.args) do
    local enable = EvalBooleanArg(arg.enable, trigger, true)
    local init = arg.init
    local name = arg.name;
    if(arg.init == "arg") then
      tinsert(input, name);
    end

    if(enable) then
      if (arg.optional and skipOptional) then
      -- Do nothing
      elseif arg.type == "tristate"
        or arg.type == "toggle"
        or arg.type == "tristatestring"
        or (arg.type == "multiselect" and trigger["use_"..name] ~= nil)
        or ((trigger["use_"..name] or arg.required) and trigger[name])
      then
        local test;

        if arg.multiEntry then
          if type(trigger[name]) == "table" and #trigger[name] > 0 then
            test = ""
            for i, value in ipairs(trigger[name]) do
              local operator = name and type(trigger[name.."_operator"]) == "table" and trigger[name.."_operator"][i]
              local caseInsensitive = name and arg.canBeCaseInsensitive and type(trigger[name.."_caseInsensitive"]) == "table" and trigger[name.."_caseInsensitive"][i]
              local use_exact = name and type(trigger["use_exact_" .. name]) == "table" and trigger["use_exact_" .. name][i]
              local use = name and trigger["use_"..name]
              local single = singleTest(arg, trigger, use, name, value, operator, use_exact, caseInsensitive)
              if single then
                if test ~= "" then
                  test = test .. arg.multiEntry.operator
                end
                test = test .. single
              end
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
          local caseInsensitive = name and trigger[name.."_caseInsensitive"]
          local use_exact = name and trigger["use_exact_" .. name]
          local use = name and trigger["use_"..name]
          test = singleTest(arg, trigger, use, name, value, operator, use_exact, caseInsensitive)
        end

        if (arg.preamble) then
          preambles = preambles .. arg.preamble:format(trigger[name]) .. "\n"
        end

        if test ~= "(test)" then
          if(arg.required) then
            tinsert(required, test);
          elseif test ~= nil then
            if arg.orConjunctionGroup then
              orConjunctionGroups[arg.orConjunctionGroup ] = orConjunctionGroups[arg.orConjunctionGroup ] or {}
              tinsert(orConjunctionGroups[arg.orConjunctionGroup ], test)
            else
              tinsert(tests, test);
            end
          end
        end

        if test and arg.events then
          for index, event in ipairs(arg.events) do
            events[event] = true
          end
        end

        if(arg.debug) then
          tinsert(debug, arg.debug:format(trigger[name]));
        end
      end
    end
  end

  for _, orConjunctionGroup  in pairs(orConjunctionGroups) do
    tinsert(tests, "("..table.concat(orConjunctionGroup , " or ")..")")
  end
  local ret = {preambles .. "return function("..table.concat(input, ", ")..")\n"};
  table.insert(ret, (init or ""));
  table.insert(ret, (#debug > 0 and table.concat(debug, "\n") or ""));
  table.insert(ret, "if(");
  table.insert(ret, ((#required > 0) and table.concat(required, " and ").." and " or ""));
  table.insert(ret, (#tests > 0 and table.concat(tests, " and ") or "true"));
  table.insert(ret, ") then\n");
  if(#debug > 0) then
    table.insert(ret, "print('ret: true');\n");
  end
  table.insert(ret, "return true else return false end end");

  return table.concat(ret), events;
end

function WeakAuras.GetActiveConditions(id, cloneId)
  triggerState[id].activatedConditions[cloneId] = triggerState[id].activatedConditions[cloneId] or {};
  return triggerState[id].activatedConditions[cloneId];
end

local function LoadCustomActionFunctions(data)
  local id = data.id;
  Private.customActionsFunctions[id] = {};

  if (data.actions) then
    if data.actions.init then
      if data.actions.init.do_custom and data.actions.init.custom then
        local func = WeakAuras.LoadFunction("return function() "..(data.actions.init.custom).."\n end", data.id);
        Private.customActionsFunctions[id]["init"] = func
      end
      if data.actions.init.do_custom_load and data.actions.init.customOnLoad then
        local func = WeakAuras.LoadFunction("return function() "..(data.actions.init.customOnLoad).."\n end", data.id);
        Private.customActionsFunctions[id]["load"] = func
      end
      if data.actions.init.do_custom_unload and data.actions.init.customOnUnload then
        local func = WeakAuras.LoadFunction("return function() "..(data.actions.init.customOnUnload).."\n end", data.id);
        Private.customActionsFunctions[id]["unload"] = func
      end
    end

    if (data.actions.start) then
      if (data.actions.start.do_custom and data.actions.start.custom) then
        local func = WeakAuras.LoadFunction("return function() "..(data.actions.start.custom).."\n end", data.id);
        Private.customActionsFunctions[id]["start"] = func;
      end

      if (data.actions.start.do_message and data.actions.start.message_custom) then
        local func = WeakAuras.LoadFunction("return "..(data.actions.start.message_custom), data.id);
        Private.customActionsFunctions[id]["start_message"] = func;
      end
    end

    if (data.actions.finish) then
      if (data.actions.finish.do_custom and data.actions.finish.custom) then
        local func = WeakAuras.LoadFunction("return function() "..(data.actions.finish.custom).."\n end", data.id);
        Private.customActionsFunctions[id]["finish"] = func;
      end

      if (data.actions.finish.do_message and data.actions.finish.message_custom) then
        local func = WeakAuras.LoadFunction("return "..(data.actions.finish.message_custom), data.id);
        Private.customActionsFunctions[id]["finish_message"] = func;
      end
    end
  end
end

Private.talent_types_specific = {}
Private.pvp_talent_types_specific = {}
local function CreateTalentCache()
  local _, player_class = UnitClass("player")

  Private.talent_types_specific[player_class] = Private.talent_types_specific[player_class] or {};

  if WeakAuras.IsClassicOrCata() then
    for tab = 1, GetNumTalentTabs() do
      for num_talent = 1, GetNumTalents(tab) do
        local talentName, talentIcon = Private.ExecEnv.GetTalentInfo(tab, num_talent);
        local talentId = (tab - 1) * MAX_NUM_TALENTS + num_talent
        if (talentName and talentIcon) then
          Private.talent_types_specific[player_class][talentId] = "|T"..talentIcon..":0|t "..talentName
        end
      end
    end
  elseif WeakAuras.IsMists() then
    -- unused
  else
    local spec = GetSpecialization()
    Private.talent_types_specific[player_class][spec] = Private.talent_types_specific[player_class][spec] or {};

    for tier = 1, MAX_TALENT_TIERS do
      for column = 1, NUM_TALENT_COLUMNS do
        -- Get name and icon info for the current talent of the current class and save it
        local _, talentName, talentIcon = Private.ExecEnv.GetTalentInfo(tier, column, 1)
        local talentId = (tier-1)*3+column
        -- Get the icon and name from the talent cache and record it in the table that will be used by WeakAurasOptions
        if (talentName and talentIcon) then
          Private.talent_types_specific[player_class][spec][talentId] = "|T"..talentIcon..":0|t "..talentName
        end
      end
    end
  end
end

local function CreatePvPTalentCache()
  local _, player_class = UnitClass("player")
  local spec = GetSpecialization()

  if (not player_class or not spec) then
    return;
  end

  Private.pvp_talent_types_specific[player_class] = Private.pvp_talent_types_specific[player_class] or {};
  Private.pvp_talent_types_specific[player_class][spec] = Private.pvp_talent_types_specific[player_class][spec] or {};

  --- @type fun(talentId: number): number, string
  local function formatTalent(talentId)
    local _, name, icon, _, _, spellId = GetPvpTalentInfoByID(talentId);
    return spellId, "|T"..icon..":0|t "..name
  end

  local slotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(1);
  if (slotInfo) then
    Private.pvp_talent_types_specific[player_class][spec] = {};

    local pvpSpecTalents = slotInfo.availableTalentIDs;
    for _, talentId in ipairs(pvpSpecTalents) do
      local index, displayText = formatTalent(talentId)
      Private.pvp_talent_types_specific[player_class][spec][index] = displayText
    end
  end
end

Private.CompanionData = {}
-- use this function to not overwrite data from other companion compatible addons
-- when using this function, do not name your global data table "WeakAurasCompanion"
function WeakAuras.AddCompanionData(data)
  WeakAuras.DeepMixin(Private.CompanionData, data)
end

-- add data from versions of companion compatible addon that does not use WeakAuras.AddCompanionData yet
local function AddLegacyCompanionData()
  local CompanionData = WeakAurasCompanion and WeakAurasCompanion.WeakAuras or WeakAurasCompanion
  if CompanionData then
    WeakAuras.AddCompanionData(CompanionData)
  end
end

function Private.PostAddCompanion()
  -- add data from older version of companion addons
  AddLegacyCompanionData()
  -- nag if updates
  local count = Private.CountWagoUpdates()
  if count and count > 0 then
    WeakAuras.prettyPrint(L["There are %i updates to your auras ready to be installed!"]:format(count))
  end
  -- nag if new installs
  if Private.CompanionData.stash and next(Private.CompanionData.stash) then
    WeakAuras.prettyPrint(L["You have new auras ready to be installed!"])
  end
end

function Private.CountWagoUpdates()
  if not (Private.CompanionData.slugs) then
    return 0
  end
  local updatedSlugs, updatedSlugsCount = {}, 0
  for id, aura in pairs(db.displays) do
    if not aura.ignoreWagoUpdate and aura.url and aura.url ~= "" then
      local slug, version = aura.url:match("wago.io/([^/]+)/([0-9]+)")
      if not slug and not version then
        slug = aura.url:match("wago.io/([^/]+)$")
        version = 1
      end
      if slug and version then
        local wago = Private.CompanionData.slugs[slug]
        if wago and wago.wagoVersion and tonumber(wago.wagoVersion) > tonumber(version) then
          if not updatedSlugs[slug] then
            updatedSlugs[slug] = true
            updatedSlugsCount = updatedSlugsCount + 1
          end
        end
      end
    end
  end

  return updatedSlugsCount
end

local function tooltip_draw(isAddonCompartment, blizzardTooltip)
  local tooltip
  if isAddonCompartment then
    tooltip = blizzardTooltip
  else
    tooltip = GameTooltip
  end
  tooltip:ClearLines()
  tooltip:AddDoubleLine("WeakAuras", versionString)
  if Private.CompanionData.slugs then
    local count = Private.CountWagoUpdates()
    if count > 0 then
      tooltip:AddLine(" ");
      tooltip:AddLine((L["There are %i updates to your auras ready to be installed!"]):format(count));
    end
  end
  tooltip:AddLine(" ");
  tooltip:AddLine(L["|cffeda55fLeft-Click|r to toggle showing the main window."], 0.2, 1, 0.2);
  if not WeakAuras.IsOptionsOpen() then
    if paused then
      tooltip:AddLine("|cFFFF0000"..L["Paused"].." - "..L["Shift-Click to resume addon execution."], 0.2, 1, 0.2);
    else
      tooltip:AddLine(L["|cffeda55fShift-Click|r to pause addon execution."], 0.2, 1, 0.2);
    end
  end
  tooltip:AddLine(L["|cffeda55fRight-Click|r to toggle performance profiling window."], 0.2, 1, 0.2);
  if not isAddonCompartment then
    tooltip:AddLine(L["|cffeda55fMiddle-Click|r to toggle the minimap icon on or off."], 0.2, 1, 0.2);
  end
  tooltip:Show();
end

WeakAuras.GenerateTooltip = tooltip_draw;

local colorFrame = CreateFrame("Frame");
Private.frames["LDB Icon Recoloring"] = colorFrame;

local colorElapsed = 0;
local colorDelay = 2;
local r, g, b = 0.8, 0, 1;
local r2, g2, b2 = random(2)-1, random(2)-1, random(2)-1;

local tooltip_update_frame = CreateFrame("Frame");
Private.frames["LDB Tooltip Updater"] = tooltip_update_frame;

-- function copied from LibDBIcon-1.0.lua
local function getAnchors(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return "CENTER" end
	local hHalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vHalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vHalf..hHalf, frame, (vHalf == "TOP" and "BOTTOM" or "TOP")..hHalf
end

local Broker_WeakAuras;
Broker_WeakAuras = LDB:NewDataObject("WeakAuras", {
  type = "launcher",
  text = "WeakAuras",
  icon = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon.blp",
  OnClick = function(self, button)
    if button == 'LeftButton' then
      if(IsShiftKeyDown()) then
        if not(WeakAuras.IsOptionsOpen()) then
          WeakAuras.Toggle();
        end
      else
        WeakAuras.OpenOptions();
      end
    elseif(button == 'MiddleButton') then
      WeakAuras.ToggleMinimap();
    else
      WeakAurasProfilingFrame:Toggle()
    end
    tooltip_draw()
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
    GameTooltip:SetOwner(self, "ANCHOR_NONE");
    GameTooltip:SetPoint(getAnchors(self))
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

do -- Archive stuff
  local Archivist = select(2, ...).Archivist
  local function OpenArchive()
    if Archivist:IsInitialized() then
      return Archivist
    else
      if not C_AddOns.IsAddOnLoaded("WeakAurasArchive") then
        local ok, reason = C_AddOns.LoadAddOn("WeakAurasArchive")
        if not ok then
          reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
          error(string.format(L["Could not load WeakAuras Archive, the addon is %s"], reason))
        end
      end
      if type(WeakAurasArchive) ~= "table" then
        WeakAurasArchive = {}
      end
      Archivist:Initialize(WeakAurasArchive)
    end
    return Archivist
  end

  function WeakAuras.LoadFromArchive(storeType, storeID)
    local Archive = OpenArchive()
    return Archive:Load(storeType, storeID)
  end
end

local loginFinished, loginMessage = false, L["Options will open after the login process has completed."]

function WeakAuras.IsLoginFinished()
  return loginFinished
end

function Private.LoginMessage()
  return loginMessage
end

local function CheckForPreviousEncounter()
  if (UnitAffectingCombat ("player") or InCombatLockdown()) then
    for i = 1, 10 do
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

function Private.Login(takeNewSnapshots)
  local loginThread = coroutine.create(function()
    Private.Pause();
    coroutine.yield(100)
    if db.history then
      local histRepo = WeakAuras.LoadFromArchive("Repository", "history")
      local migrationRepo = WeakAuras.LoadFromArchive("Repository", "migration")
      for uid, hist in pairs(db.history) do
        local histStore = histRepo:Set(uid, hist.data)
        local migrationStore = migrationRepo:Set(uid, hist.migration)
        coroutine.yield(1000, "login move old history")
      end
      -- history is now in archive so we can shrink WeakAurasSaved
      db.history = nil
    end


    Private.Features:Hydrate()
    coroutine.yield(3000, "login check uid corruption")

    local toAdd = {};
    loginFinished = false
    loginMessage = L["Options will open after the login process has completed."]
    for id, data in pairs(db.displays) do
      if(id ~= data.id) then
        print("|cFF8800FFWeakAuras|r detected a corrupt entry in WeakAuras saved displays - '"..tostring(id).."' vs '"..tostring(data.id).."'" );
        data.id = id;
      end

      tinsert(toAdd, data);
    end
    coroutine.yield(8000);

    Private.AddMany(toAdd, takeNewSnapshots);
    coroutine.yield(1000);

    -- check in case of a disconnect during an encounter.
    if (db.CurrentEncounter) then
      CheckForPreviousEncounter()
    end
    coroutine.yield(1000);
    Private.RegisterLoadEvents();
    coroutine.yield(10000);
    Private.Resume();
    coroutine.yield(100);

    local nextCallback = loginQueue[1];
    while nextCallback do
      tremove(loginQueue, 1);
      if type(nextCallback) == 'table' then
        nextCallback[1](unpack(nextCallback[2]))
      else
        nextCallback()
      end
      coroutine.yield(1000, "login post login callbacks");
      nextCallback = loginQueue[1];
    end

    loginFinished = true
    -- Tell Dynamic Groups that we are done with login
    for _, region in pairs(Private.regions) do
      if (region.region and region.region.RunDelayedActions) then
        region.region:RunDelayedActions();
        coroutine.yield(500, "login delayed region actions");
      end
    end
  end)

  Private.Threads:Immediate('login', loginThread, 15000, 1000)
end

local WeakAurasFrame = CreateFrame("Frame", "WeakAurasFrame", UIParent);
Private.frames["WeakAuras Main Frame"] = WeakAurasFrame;
WeakAurasFrame:SetAllPoints(UIParent);

local loadedFrame = CreateFrame("Frame");
Private.frames["Addon Initialization Handler"] = loadedFrame;
loadedFrame:RegisterEvent("ADDON_LOADED");
loadedFrame:RegisterEvent("PLAYER_LOGIN");
loadedFrame:RegisterEvent("PLAYER_LOGOUT")
loadedFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
loadedFrame:RegisterEvent("LOADING_SCREEN_ENABLED");
loadedFrame:RegisterEvent("LOADING_SCREEN_DISABLED");
if WeakAuras.IsRetail() then
  loadedFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
  loadedFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
else
  loadedFrame:RegisterEvent("CHARACTER_POINTS_CHANGED");
  loadedFrame:RegisterEvent("SPELLS_CHANGED");
end
loadedFrame:SetScript("OnEvent", function(self, event, ...)
  if(event == "ADDON_LOADED") then
    if(... == ADDON_NAME) then
      ---@type WeakAurasSaved
      WeakAurasSaved = WeakAurasSaved or {};
      db = WeakAurasSaved;
      Private.db = db
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
      db.features = db.features or {}
      db.migrationCutoff = db.migrationCutoff or 730
      db.historyCutoff = db.historyCutoff or 730

      Private.SyncParentChildRelationships();
      local isFirstUIDValidation = db.dbVersion == nil or db.dbVersion < 26;
      Private.ValidateUniqueDataIds(isFirstUIDValidation);

      if db.lastArchiveClear == nil then
        db.lastArchiveClear = time();
      elseif db.lastArchiveClear < time() - 2505600 --[[29 days]] then
        db.lastArchiveClear = time();
        Private.CleanArchive(db.historyCutoff, db.migrationCutoff);
      end
      db.minimap = db.minimap or { hide = false };
      LDBIcon:Register("WeakAuras", Broker_WeakAuras, db.minimap);
    end
  elseif(event == "PLAYER_LOGIN") then
    local dbIsValid, takeNewSnapshots
    if not db.dbVersion or db.dbVersion < internalVersion then
      -- db is out of date, will run any necessary migrations in AddMany
      db.dbVersion = internalVersion
      db.lastUpgrade = time()
      dbIsValid = true
      takeNewSnapshots = true
    elseif db.dbVersion > internalVersion then
      -- user has downgraded past a forwards-incompatible migration
      dbIsValid = false
    else
      -- db has same version as code, can commit to login
      dbIsValid = true
    end
    if dbIsValid then
      Private.Login(takeNewSnapshots)
    else
      -- db isn't valid. Request permission to run repair tool before logging in
      StaticPopup_Show("WEAKAURAS_CONFIRM_REPAIR", nil, nil, {reason = "downgrade"})
    end
  elseif event == "PLAYER_LOGOUT" then
    for id in pairs(db.displays) do
      Private.ClearAuraEnvironment(id)
    end
  elseif(event == "LOADING_SCREEN_ENABLED") then
    in_loading_screen = true;
  elseif(event == "LOADING_SCREEN_DISABLED") then
    in_loading_screen = false;
  else
    local callback
    if(event == "PLAYER_ENTERING_WORLD") then
      local isInitialLogin, isReloadingUi = ...
      -- Schedule events that need to be handled some time after login
      local now = GetTime()
      callback = function()
        local elapsed = GetTime() - now
        local remainingSquelch = db.login_squelch_time - elapsed
        if remainingSquelch > 0 then
          timer:ScheduleTimer(function() squelch_actions = false; end, remainingSquelch); -- No sounds while loading
        end
        CreateTalentCache() -- It seems that GetTalentInfo might give info about whatever class was previously being played, until PLAYER_ENTERING_WORLD
        Private.InitializeEncounterAndZoneLists()
      end
      if isInitialLogin or isReloadingUi then
        Private.PostAddCompanion()
      end
    elseif(event == "PLAYER_PVP_TALENT_UPDATE") then
      callback = CreatePvPTalentCache;
    elseif(event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "CHARACTER_POINTS_CHANGED" or event == "SPELLS_CHANGED") then
      callback = CreateTalentCache;
    elseif(event == "PLAYER_REGEN_ENABLED") then
      callback = function()
        if (queueshowooc) then
          WeakAuras.OpenOptions(queueshowooc)
          queueshowooc = nil
          Private.frames["Addon Initialization Handler"]:UnregisterEvent("PLAYER_REGEN_ENABLED")
        end
      end
    end
    if WeakAuras.IsLoginFinished() then
      callback()
    else
      loginQueue[#loginQueue + 1] = callback
    end
  end
end)

function Private.SetImporting(b)
  importing = b;
end

function WeakAuras.IsImporting()
  return importing;
end

function WeakAuras.IsPaused()
  return paused;
end

function Private.Pause()
  for id, states in pairs(triggerState) do
    local changed
    for triggernum in ipairs(states) do
      changed = Private.SetAllStatesHidden(id, triggernum) or changed
    end
    if changed then
      Private.UpdatedTriggerState(id)
    end
  end

  paused = true;
end

function WeakAuras.Toggle()
  if(paused) then
    Private.Resume();
  else
    Private.Pause();
  end
end

function Private.SquelchingActions()
  return squelch_actions;
end

function WeakAuras.InLoadingScreen()
  return in_loading_screen;
end

function Private.PauseAllDynamicGroups()
  local suspended = {}
  for id, region in pairs(Private.regions) do
    if (region.region and region.region.Suspend) then
      region.region:Suspend();
      tinsert(suspended, id)
    end
  end
  return suspended
end

function Private.ResumeAllDynamicGroups(suspended)
  for _, id in ipairs(suspended) do
    local region = WeakAuras.GetRegion(id)
    if (region and region.Resume) then
      region:Resume();
    end
  end
end

-- Encounter stuff
local function StoreBossGUIDs()
  Private.StartProfileSystem("boss_guids")
  if (WeakAuras.CurrentEncounter and WeakAuras.CurrentEncounter.boss_guids) then
    for i = 1, 10 do
      if (UnitExists ("boss" .. i)) then
        local guid = UnitGUID ("boss" .. i)
        if (guid) then
          WeakAuras.CurrentEncounter.boss_guids [guid] = true
        end
      end
    end
    db.CurrentEncounter = WeakAuras.CurrentEncounter
  end
  Private.StopProfileSystem("boss_guids")
end

local function DestroyEncounterTable()
  if (WeakAuras.CurrentEncounter) then
    wipe(WeakAuras.CurrentEncounter)
  end
  WeakAuras.CurrentEncounter = nil
  db.CurrentEncounter = nil
end

local function CreateEncounterTable(encounter_id)
  local _, _, _, _, _, _, _, instanceId = GetInstanceInfo()
  ---@class CurrentEncounter
  ---@field encounterId number
  ---@field zone_id number
  ---@field boss_guids number[]
  WeakAuras.CurrentEncounter = {
    id = encounter_id,
    zone_id = instanceId,
    boss_guids = {},
  }
  timer:ScheduleTimer(StoreBossGUIDs, 2)

  return WeakAuras.CurrentEncounter
end

local pausedOptionsProcessing = false;
function Private.pauseOptionsProcessing(enable)
  pausedOptionsProcessing = enable;
end

function Private.IsOptionsProcessingPaused()
  return pausedOptionsProcessing;
end

function Private.ExecEnv.GroupType()
  if (IsInRaid()) then
    return "raid";
  end
  if (IsInGroup()) then
    return "group";
  end
  return "solo";
end

local function GetInstanceTypeAndSize()
  local size, difficulty
  local inInstance, Type = IsInInstance()
  local _, instanceType, difficultyIndex, _, _, _, _, instanceId = GetInstanceInfo()
  if inInstance or instanceType ~= "none" then
    size = Type
    local difficultyInfo = Private.difficulty_info[difficultyIndex]
    if difficultyInfo then
      size, difficulty = difficultyInfo.size, difficultyInfo.difficulty
    else
      if WeakAuras.IsRetail() then
        if size == "arena" then
          if C_PvP.IsRatedArena() and not IsArenaSkirmish() then
            size = "ratedarena"
          end
        elseif size == "pvp" then
          if C_PvP.IsRatedBattleground() then
            size = "ratedpvp"
          end
        end
      end
    end
    return size, difficulty, instanceType, instanceId, difficultyIndex
  end
  return "none", "none", nil, nil, 0
end

---@return string instanceType
function WeakAuras.InstanceType()
  return (GetInstanceTypeAndSize())
end

---@return string difficulty
function WeakAuras.InstanceDifficulty()
  return select(2, GetInstanceTypeAndSize())
end

---@return number? difficultyID
function WeakAuras.InstanceTypeRaw()
  return select(5, GetInstanceTypeAndSize())
end

local toLoad = {}
local toUnload = {};
local function scanForLoadsImpl(toCheck, event, arg1, ...)
  if (Private.IsOptionsProcessingPaused()) then
    return;
  end

  toCheck = toCheck or loadEvents[event or "SCAN_ALL"]

  -- PET_BATTLE_CLOSE fires twice at the end of a pet battle. IsInBattle evaluates to TRUE during the
  -- first firing, and FALSE during the second. I am not sure if this check is necessary, but the
  -- following IF statement limits the impact of the PET_BATTLE_CLOSE event to the second one.
  if (event == "PET_BATTLE_CLOSE" and C_PetBattles.IsInBattle()) then return end

  if (event == "PLAYER_LEVEL_UP") then
    playerLevel = arg1;
  end

  -- encounter id stuff, we are holding the current combat id to further load checks.
  -- there is three ways to unload: encounter_end / zone changed (hearthstone used) / reload or disconnect
  -- regen_enabled isn't good due to combat drop abilities such invisibility, vanish, fake death, etc.
  local encounter_id = WeakAuras.CurrentEncounter and WeakAuras.CurrentEncounter.id or 0

  if (event == "ENCOUNTER_START") then
    encounter_id = tonumber(arg1)
    CreateEncounterTable(encounter_id)
  elseif (event == "ENCOUNTER_END") then
    encounter_id = 0
    DestroyEncounterTable()
  end

  if toCheck == nil or next(toCheck) == nil then
    return
  end

  local player, realm, zone = UnitName("player"), GetRealmName(), GetRealZoneText()
  local guild = GetGuildInfo("player")
  --- @type boolean|number|nil, boolean|string|nil, boolean|string|nil, boolean|string
  local specId, role, position, raidRole = false, false, false, false
  --- @type boolean, boolean, boolean
  local inPetBattle, vehicle, vehicleUi = false, false, false
  --- @type boolean
  local dragonriding
  local zoneId = C_Map.GetBestMapForUnit("player")
  local zonegroupId = zoneId and C_Map.GetMapGroupID(zoneId)
  local minimapText = GetMinimapZoneText()
  local _, race = UnitRace("player")
  local faction = UnitFactionGroup("player")
  local _, class = UnitClass("player")
  local inCombat = UnitAffectingCombat("player")
  --- @type boolean
  local inEncounter = encounter_id ~= 0;
  local alive = not UnitIsDeadOrGhost('player')
  local raidMemberType = 0

  if UnitIsGroupLeader("player") then
    raidMemberType = 1
  end

  if UnitIsGroupAssistant("player") then
    raidMemberType = raidMemberType + 2
  end

  local mounted = IsMounted()
  if WeakAuras.IsClassicOrCataOrMists() then
    local raidID = UnitInRaid("player")
    if raidID then
      raidRole = select(10, GetRaidRosterInfo(raidID))
    end
    role = "none"
  end
  if WeakAuras.IsClassicEra() then
    vehicle = UnitOnTaxi('player')
  end
  if WeakAuras.IsCataOrMistsOrRetail() then
    vehicle = UnitInVehicle('player') or UnitOnTaxi('player') or false
    vehicleUi = UnitHasVehicleUI('player') or HasOverrideActionBar() or HasVehicleActionBar() or false
    specId, role, position = Private.LibSpecWrapper.SpecRolePositionForUnit("player")
  end
  if WeakAuras.IsMistsOrRetail() then
    inPetBattle = C_PetBattles.IsInBattle()
  end
  if WeakAuras.IsRetail() then
    dragonriding = Private.IsDragonriding()
  end

  local size, difficulty, instanceType, instanceId, difficultyIndex = GetInstanceTypeAndSize()

  if (WeakAuras.CurrentEncounter) then
    if (instanceId ~= WeakAuras.CurrentEncounter.zone_id and not inCombat) then
      encounter_id = 0
      DestroyEncounterTable()
    end
  end

  local group = Private.ExecEnv.GroupType()
  local groupSize = GetNumGroupMembers()

  local affixes, warmodeActive, effectiveLevel = 0, false, 0
  if WeakAuras.IsRetail() then
    effectiveLevel = UnitEffectiveLevel("player")
    affixes = C_ChallengeMode.IsChallengeModeActive() and select(2, C_ChallengeMode.GetActiveKeystoneInfo())
    warmodeActive = C_PvP.IsWarModeDesired();
  end

  local hardcore, runeEngraving = false, false
  if WeakAuras.IsClassicEra() then
    hardcore = C_GameRules.IsHardcoreActive()
    runeEngraving = C_Engraving.IsEngravingEnabled()
  end

  local changed = 0;
  local shouldBeLoaded, couldBeLoaded;
  local parentsToCheck = {}
  wipe(toLoad);
  wipe(toUnload);

  for id in pairs(toCheck) do
    local data = WeakAuras.GetData(id)
    if (data and not data.controlledChildren) then
      local loadFunc = loadFuncs[id];
      local loadOpt = loadFuncsForOptions[id];
      if WeakAuras.IsClassicEra() then
        shouldBeLoaded = loadFunc and loadFunc("ScanForLoads_Auras", inCombat, alive, inEncounter, vehicle, mounted, hardcore, runeEngraving, class, player, realm, guild, race, faction, playerLevel, raidRole, group, groupSize, raidMemberType, zone, zoneId, zonegroupId, instanceId, minimapText, encounter_id, size)
        couldBeLoaded =  loadOpt and loadOpt("ScanForLoads_Auras",   inCombat, alive, inEncounter, vehicle, mounted, hardcore, runeEngraving, class, player, realm, guild, race, faction, playerLevel, raidRole, group, groupSize, raidMemberType, zone, zoneId, zonegroupId, instanceId, minimapText, encounter_id, size)
      elseif WeakAuras.IsCataClassic() then
        shouldBeLoaded = loadFunc and loadFunc("ScanForLoads_Auras", inCombat, alive, inEncounter, vehicle, vehicleUi, mounted, class, specId, player, realm, guild, race, faction, playerLevel, role, position, raidRole, group, groupSize, raidMemberType, zone, zoneId, zonegroupId, instanceId, minimapText, encounter_id, size, difficulty, difficultyIndex)
        couldBeLoaded =  loadOpt and loadOpt("ScanForLoads_Auras",   inCombat, alive, inEncounter, vehicle, vehicleUi, mounted, class, specId, player, realm, guild, race, faction, playerLevel, role, position, raidRole, group, groupSize, raidMemberType, zone, zoneId, zonegroupId, instanceId, minimapText, encounter_id, size, difficulty, difficultyIndex)
      elseif WeakAuras.IsMists() then
        shouldBeLoaded = loadFunc and loadFunc("ScanForLoads_Auras", inCombat, alive, inEncounter, inPetBattle, vehicle, vehicleUi, mounted, class, specId, player, realm, guild, race, faction, playerLevel, role, position, raidRole, group, groupSize, raidMemberType, zone, zoneId, zonegroupId, instanceId, minimapText, encounter_id, size, difficulty, difficultyIndex)
        couldBeLoaded =  loadOpt and loadOpt("ScanForLoads_Auras",   inCombat, alive, inEncounter, inPetBattle, vehicle, vehicleUi, mounted, class, specId, player, realm, guild, race, faction, playerLevel, role, position, raidRole, group, groupSize, raidMemberType, zone, zoneId, zonegroupId, instanceId, minimapText, encounter_id, size, difficulty, difficultyIndex)
      elseif WeakAuras.IsRetail() then
        shouldBeLoaded = loadFunc and loadFunc("ScanForLoads_Auras", inCombat, alive, inEncounter, warmodeActive, inPetBattle, vehicle, vehicleUi, dragonriding, mounted, specId, player, realm, guild, race, faction, playerLevel, effectiveLevel, role, position, group, groupSize, raidMemberType, zone, zoneId, zonegroupId, instanceId, minimapText, encounter_id, size, difficulty, difficultyIndex, affixes)
        couldBeLoaded =  loadOpt and loadOpt("ScanForLoads_Auras",   inCombat, alive, inEncounter, warmodeActive, inPetBattle, vehicle, vehicleUi, dragonriding, mounted, specId, player, realm, guild, race, faction, playerLevel, effectiveLevel, role, position, group, groupSize, raidMemberType, zone, zoneId, zonegroupId, instanceId, minimapText, encounter_id, size, difficulty, difficultyIndex, affixes)
      end

      if(shouldBeLoaded and not loaded[id]) then
        changed = changed + 1;
        toLoad[id] = true;
        Private.EnsureRegion(id)
        for parent in Private.TraverseParents(data) do
          parentsToCheck[parent.id] = true
        end
      end

      if(loaded[id] and not shouldBeLoaded) then
        toUnload[id] = true;
        changed = changed + 1;
        for parent in Private.TraverseParents(data) do
          parentsToCheck[parent.id] = true
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

  if(changed > 0 and not paused) then
    Private.LoadDisplays(toLoad, event, arg1, ...);
    Private.UnloadDisplays(toUnload, event, arg1, ...);
    Private.FinishLoadUnload();
  end

  Private.ScanForLoadsGroup(parentsToCheck)
  Private.callbacks:Fire("ScanForLoads")

  wipe(toLoad);
  wipe(toUnload)
end

function Private.ScanForLoadsGroup(toCheck)
  for id in pairs(toCheck) do
    local data = WeakAuras.GetData(id)
    if(data.controlledChildren) then
      if(#data.controlledChildren > 0) then
        ---@type boolean?
        local any_loaded = false;
        for child in Private.TraverseLeafs(data) do
          if(loaded[child.id] ~= nil) then
            any_loaded = true;
            break;
          else
            any_loaded = nil
          end
        end
        if any_loaded then
          Private.EnsureRegion(id)
        end
        loaded[id] = any_loaded;
      else
        Private.EnsureRegion(id)
        loaded[id] = true;
      end
    end
  end
end

function Private.ScanForLoads(toCheck, event, arg1, ...)
  if not WeakAuras.IsLoginFinished() then
    return
  end
  scanForLoadsImpl(toCheck, event, arg1, ...)
end

local loadFrame = CreateFrame("Frame");
Private.frames["Display Load Handling"] = loadFrame;

loadFrame:RegisterEvent("ENCOUNTER_START");
loadFrame:RegisterEvent("ENCOUNTER_END");

if WeakAuras.IsRetail() then
  loadFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
  loadFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
  loadFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED");
  loadFrame:RegisterEvent("PET_BATTLE_OPENING_START");
  loadFrame:RegisterEvent("PET_BATTLE_CLOSE");
  loadFrame:RegisterEvent("VEHICLE_UPDATE");
  loadFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
  loadFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR");
  loadFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
  loadFrame:RegisterEvent("CHALLENGE_MODE_START")
  loadFrame:RegisterEvent("TRAIT_CONFIG_CREATED")
  loadFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
else
  loadFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
  loadFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
  loadFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
end

if WeakAuras.IsCataOrMists() then
  loadFrame:RegisterEvent("VEHICLE_UPDATE");
  loadFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
  loadFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR");
end

if WeakAuras.IsMists() then
  loadFrame:RegisterEvent("PET_BATTLE_OPENING_START");
  loadFrame:RegisterEvent("PET_BATTLE_CLOSE");
end
loadFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
loadFrame:RegisterEvent("ZONE_CHANGED");
loadFrame:RegisterEvent("ZONE_CHANGED_INDOORS");
loadFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
loadFrame:RegisterEvent("PLAYER_LEVEL_UP");
loadFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
loadFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
loadFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED");
loadFrame:RegisterEvent("SPELLS_CHANGED");
loadFrame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
loadFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
loadFrame:RegisterEvent("PLAYER_DEAD")
loadFrame:RegisterEvent("PLAYER_ALIVE")
loadFrame:RegisterEvent("PLAYER_UNGHOST")
loadFrame:RegisterEvent("PARTY_LEADER_CHANGED")
loadFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
loadFrame:RegisterEvent("PLAYER_GUILD_UPDATE")

if WeakAuras.IsRetail() then
  Private.callbacks:RegisterCallback("WA_DRAGONRIDING_UPDATE", function ()
    Private.StartProfileSystem("load");
    Private.ScanForLoads(nil, "WA_DRAGONRIDING_UPDATE")
    Private.StopProfileSystem("load");
  end)
end

local unitLoadFrame = CreateFrame("Frame");
Private.frames["Display Load Handling 2"] = unitLoadFrame;

unitLoadFrame:RegisterUnitEvent("UNIT_FLAGS", "player");
if WeakAuras.IsCataOrMistsOrRetail() then
  unitLoadFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player");
  unitLoadFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player");
  unitLoadFrame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "player");
end

function Private.RegisterLoadEvents()
  loadFrame:SetScript("OnEvent", function(frame, ...)
    Private.StartProfileSystem("load");
    Private.ScanForLoads(nil, ...)
    Private.StopProfileSystem("load");
  end);

  C_Timer.NewTicker(0.5, function()
    Private.StartProfileSystem("load");
    local zoneId = C_Map.GetBestMapForUnit("player");
    if loadFrame.zoneId ~= zoneId then
      Private.ScanForLoads(nil, "ZONE_CHANGED")
      loadFrame.zoneId = zoneId;
    end
    Private.StopProfileSystem("load");
  end)

  unitLoadFrame:SetScript("OnEvent", function(frame, e, arg1, ...)
    Private.StartProfileSystem("load");
    if (arg1 == "player") then
      Private.ScanForLoads(nil, e, arg1, ...)
    end
    Private.StopProfileSystem("load");
  end);
end

local function UnloadAll()
  -- Even though auras are collapsed, their finish animation can be running
  for id in pairs(loaded) do
    if Private.regions[id] and Private.regions[id].region then
      Private.CancelAnimation(Private.regions[id].region, true, true, true, true, true, true)
    end
    if clones[id] then
      for cloneId, region in pairs(clones[id]) do
        Private.CancelAnimation(region, true, true, true, true, true, true)
      end
    end
  end

  for _, v in pairs(triggerState) do
    for i = 1, v.numTriggers do
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

  Private.UnloadAllConditions()

  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.UnloadAll();
  end

  for id in pairs(loaded) do
    local func = Private.customActionsFunctions[id] and Private.customActionsFunctions[id]["unload"]
    if func then
      Private.ActivateAuraEnvironment(id)
      xpcall(func, Private.GetErrorHandlerId(id, "onUnload"))
      Private.ActivateAuraEnvironment(nil)
    end
  end
  wipe(loaded);
end

function Private.Resume()
  paused = false;

  local suspended = Private.PauseAllDynamicGroups()

  for id, region in pairs(Private.regions) do
    if region.region then
      region.region:Collapse();
    end
  end

  for id, cloneList in pairs(clones) do
    for cloneId, clone in pairs(cloneList) do
      clone:Collapse();
    end
  end


  UnloadAll();
  scanForLoadsImpl();
  if loadEvents["GROUP"] then
    Private.ScanForLoadsGroup(loadEvents["GROUP"])
  end

  Private.ResumeAllDynamicGroups(suspended)
end

function Private.LoadDisplays(toLoad, ...)
  for id in pairs(toLoad) do
    local uid = WeakAuras.GetData(id).uid
    Private.RegisterForGlobalConditions(uid);
    triggerState[id].triggers = {};
    triggerState[id].activationTime = {}
    triggerState[id].triggerCount = 0;
    triggerState[id].show = false;
    triggerState[id].activatedConditions = {};
    if Private.DebugLog.IsEnabled(uid) then
      WeakAuras.prettyPrint(L["Debug Logging enabled for '%s'"]:format(id))
      Private.DebugLog.Print(uid, L["Aura loaded"])
    end
  end
  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.LoadDisplays(toLoad, ...);
  end
  for id in pairs(toLoad) do
    local func = Private.customActionsFunctions[id] and Private.customActionsFunctions[id]["load"]
    if func then
      Private.ActivateAuraEnvironment(id)
      xpcall(func, Private.GetErrorHandlerId(id, "onLoad"))
      Private.ActivateAuraEnvironment(nil)
    end
  end
end

function Private.UnloadDisplays(toUnload, ...)
  for id in pairs(toUnload) do
    local func = Private.customActionsFunctions[id] and Private.customActionsFunctions[id]["unload"]
    if func then
      Private.ActivateAuraEnvironment(id)
      xpcall(func, Private.GetErrorHandlerId(id, "onUnload"))
      Private.ActivateAuraEnvironment(nil)
    end
  end
  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.UnloadDisplays(toUnload, ...);
  end

  for id in pairs(toUnload) do
    if triggerState[id] then
      for i = 1, triggerState[id].numTriggers do
        if (triggerState[id][i]) then
          wipe(triggerState[id][i])
        end
      end
      triggerState[id].show = nil
    end

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

    local uid = WeakAuras.GetData(id).uid
    Private.UnloadConditions(uid)

    Private.regions[id].region:Collapse();
    Private.CollapseAllClones(id);

    -- Even though auras are collapsed, their finish animation can be running
    Private.CancelAnimation(Private.regions[id].region, true, true, true, true, true, true)
    if clones[id] then
      for _, region in pairs(clones[id]) do
        Private.CancelAnimation(region, true, true, true, true, true, true)
      end
    end
  end
end

function Private.FinishLoadUnload()
  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.FinishLoadUnload();
  end
end

-- transient cache of uid => id
-- eventually, the database will be migrated to index by uid
-- and this mapping will become redundant
-- this cache is loaded lazily via pAdd()
local UIDtoID = {}

function Private.GetDataByUID(uid)
  return WeakAuras.GetData(UIDtoID[uid])
end

function Private.UIDtoID(uid)
  return UIDtoID[uid]
end

---@private
function WeakAuras.Delete(data)
  Private.TimeMachine:DestroyTheUniverse(data.id)
  local id = data.id;
  local uid = data.uid
  local parentId = data.parent
  local parentUid = data.parent and db.displays[data.parent].uid


  if loaded[id] then
    Private.UnloadDisplays({[id] = true})
  end

  Private.callbacks:Fire("AboutToDelete", uid, id, parentUid, parentId)

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
      for parent in Private.TraverseParents(data) do
        Private.ClearAuraEnvironment(parent.id);
      end
    end
  end

  UIDtoID[data.uid] = nil
  if(data.controlledChildren) then
    for _, childId in pairs(data.controlledChildren) do
      local childData = db.displays[childId];
      if(childData) then
        childData.parent = nil;
        WeakAuras.Add(childData);
      end
    end
  end

  if Private.regions[id] and Private.regions[id].region then
    Private.regions[id].region:Collapse()
    Private.CancelAnimation(Private.regions[id].region, true, true, true, true, true, true)

    -- Groups have a empty Collapse method so, we need to hide them here
    Private.regions[id].region:Hide();

    Private.regions[id].region = nil
    Private.regions[id] = nil
  end

  if clones[id] then
    for _, region in pairs(clones[id]) do
      region:Collapse();
      Private.CancelAnimation(region, true, true, true, true, true, true)
    end
    clones[id] = nil
  end

  db.registered[id] = nil;

  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.Delete(id);
  end


  loaded[id] = nil;
  loadFuncs[id] = nil;
  loadFuncsForOptions[id] = nil;
  for event, eventData in pairs(loadEvents) do
    eventData[id] = nil
  end

  db.displays[id] = nil;

  Private.DeleteAuraEnvironment(id)
  triggerState[id] = nil;

  if (Private.personalRessourceDisplayFrame) then
    Private.personalRessourceDisplayFrame:delete(id);
  end

  if (Private.mouseFrame) then
    Private.mouseFrame:delete(id);
  end

  Private.customActionsFunctions[id] = nil;
  Private.ExecEnv.customConditionsFunctions[id] = nil;
  Private.ExecEnv.conditionTextFormatters[id] = nil
  Private.frameLevels[id] = nil;
  Private.ExecEnv.conditionHelpers[data.uid] = nil

  Private.RemoveHistory(data.uid)

  Private.AddParents(data)
  Private.callbacks:Fire("Delete", uid, id, parentUid, parentId)
end

function WeakAuras.Rename(data, newid)
  -- since we Add() later in this function, we need to destroy the universe first
  local oldid = data.id
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
    local parentRegion = WeakAuras.GetRegion(data.parent)
    if parentRegion and parentRegion.ReloadControlledChildren then
      parentRegion:ReloadControlledChildren()
    end
  end

  UIDtoID[data.uid] = newid
  Private.regions[newid] = Private.regions[oldid];
  Private.regions[oldid] = nil;
  if Private.regions[newid] and Private.regions[newid].region then
    Private.regions[newid].region.id = newid
  end

  if(clones[oldid]) then
    clones[newid] = clones[oldid]
    clones[oldid] = nil
    for cloneid, clone in pairs(clones[newid]) do
      clone.id = newid
    end
  end

  for _, triggerSystem in pairs(triggerSystems) do
    triggerSystem.Rename(oldid, newid);
  end

  loaded[newid] = loaded[oldid];
  loaded[oldid] = nil;
  loadFuncs[newid] = loadFuncs[oldid];
  loadFuncs[oldid] = nil;

  loadFuncsForOptions[newid] = loadFuncsForOptions[oldid]
  loadFuncsForOptions[oldid] = nil;

  for event, eventData in pairs(loadEvents) do
    eventData[newid] = eventData[oldid]
    eventData[oldid] = nil
  end

  timers[newid] = timers[oldid];
  timers[oldid] = nil;

  triggerState[newid] = triggerState[oldid];
  triggerState[oldid] = nil;

  Private.RenameAuraEnvironment(oldid, newid)

  db.displays[newid] = db.displays[oldid];
  db.displays[oldid] = nil;
  db.displays[newid].id = newid;

  if(data.controlledChildren) then
    for index, childId in pairs(data.controlledChildren) do
      local childData = db.displays[childId];
      if(childData) then
        childData.parent = data.id;
      end
    end
  end

  if (Private.personalRessourceDisplayFrame) then
    Private.personalRessourceDisplayFrame:rename(oldid, newid);
  end

  if (Private.mouseFrame) then
    Private.mouseFrame:rename(oldid, newid);
  end

  Private.customActionsFunctions[newid] = Private.customActionsFunctions[oldid];
  Private.customActionsFunctions[oldid] = nil;

  Private.ExecEnv.customConditionsFunctions[newid] = Private.ExecEnv.customConditionsFunctions[oldid];
  Private.ExecEnv.customConditionsFunctions[oldid] = nil;

  Private.ExecEnv.conditionTextFormatters[newid] = Private.ExecEnv.conditionTextFormatters[oldid]
  Private.ExecEnv.conditionTextFormatters[oldid] = nil

  Private.frameLevels[newid] = Private.frameLevels[oldid];
  Private.frameLevels[oldid] = nil;

  Private.ProfileRenameAura(oldid, newid);

  -- TODO: This should not be necessary
  WeakAuras.Add(data)

  Private.callbacks:Fire("Rename", data.uid, oldid, newid)
end

function Private.Convert(data, newType)
  Private.TimeMachine:DestroyTheUniverse(data.id)
  local id = data.id;
  Private.FakeStatesFor(id, false)

  if Private.regions[id] then
    Private.regions[id].region = nil
    Private.regions[id] = nil
  end

  data.regionType = newType;

  -- Clean up sub regions
  if data.subRegions then
    for index, subRegionData in ipairs_reverse(data.subRegions) do
      local subType = subRegionData.type
      local removeSubRegion = true
      if subType and Private.subRegionTypes[subType] then
        if Private.subRegionTypes[subType].supports(data.regionType) then
          removeSubRegion = false
        end
      end
      if removeSubRegion then
        tremove(data.subRegions, index)
        -- Adjust conditions!
        if data.conditions then
          for _, condition in ipairs(data.conditions) do
            if type(condition.changes) == "table" then
              for _, change in ipairs(condition.changes) do
                if change.property then
                  local subRegionIndex, property = change.property:match("^sub%.(%d+)%.(.*)")
                  subRegionIndex = tonumber(subRegionIndex)
                  if subRegionIndex and property then
                    if subRegionIndex == index then
                      change.property = nil
                    elseif subRegionIndex > index then
                      change.property = "sub." .. subRegionIndex -1 .. "." .. property
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end


  WeakAuras.Add(data);

  Private.FakeStatesFor(id, true)

  local parentRegion = WeakAuras.GetRegion(data.parent)
  if parentRegion and parentRegion.ReloadControlledChildren then
    parentRegion:ReloadControlledChildren()
  end
end

-- The default mixin doesn't recurse, this does
function WeakAuras.DeepMixin(dest, source)
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

local function LastUpgrade()
  return db.lastUpgrade and date(nil, db.lastUpgrade) or "unknown"
end

function Private.NeedToRepairDatabase()
  return db.dbVersion and db.dbVersion > WeakAuras.InternalVersion()
end

local function RepairDatabase()
  local coro = coroutine.create(function()
    Private.SetImporting(true)
    -- set db version to current code version
    db.dbVersion = WeakAuras.InternalVersion()
    -- reinstall snapshots from history
    local newDB = Mixin({}, db.displays)
    coroutine.yield(1000)
    for id, data in pairs(db.displays) do
      local snapshot = Private.GetMigrationSnapshot(data.uid)
      if snapshot then
        newDB[id] = nil
        newDB[snapshot.id] = snapshot
        coroutine.yield(1000, "repair get snapshot")
      end
    end
    db.displays = newDB
    Private.SetImporting(false)
    -- finally, login
    Private.Login()
  end)
  Private.Threads:Add("repair", coro, 'urgent')
end

StaticPopupDialogs["WEAKAURAS_CONFIRM_REPAIR"] = {
  text = "",
  button1 = L["Repair"],
  button2 = L["Cancel"],
  OnAccept = function(self)
     RepairDatabase()
  end,
  OnShow = function(self)
    local AutomaticRepairText = L["WeakAuras has detected that it has been downgraded.\nYour saved auras may no longer work properly.\nWould you like to run the |cffff0000EXPERIMENTAL|r repair tool? This will overwrite any changes you have made since the last database upgrade.\nLast upgrade: %s\n\n|cffff0000You should BACKUP your WTF folder BEFORE pressing this button.|r"]
    local ManualRepairText = L["Are you sure you want to run the |cffff0000EXPERIMENTAL|r repair tool?\nThis will overwrite any changes you have made since the last database upgrade.\nLast upgrade: %s"]

    if self.data.reason == "user" then
      self.text:SetText(ManualRepairText:format(LastUpgrade()))
    else
      self.text:SetText(AutomaticRepairText:format(LastUpgrade()))
    end
  end,
  OnCancel = function(self)
    if self.data.reason ~= "user" then
      Private.Login()
    end
  end,
  whileDead = true,
  showAlert = true,
  timeout = 0,
  preferredindex = STATICPOPUP_NUMDIALOGS
}

function Private.ValidateUniqueDataIds(silent)
  -- ensure that there are no duplicated uids anywhere in the database
  local seenUIDs = {}
  for _, data in pairs(db.displays) do
    if type(data.uid) == "string" then
      if seenUIDs[data.uid] then
        if not silent then
          prettyPrint("Duplicate uid \""..data.uid.."\" detected in saved variables between \""..data.id.."\" and \""..seenUIDs[data.uid].id.."\".")
        end
        data.uid = WeakAuras.GenerateUniqueID()
        seenUIDs[data.uid] = data
      else
        seenUIDs[data.uid] = data
      end
    elseif data.uid ~= nil then
      if not silent then
        prettyPrint("Invalid uid detected in saved variables for \""..data.id.."\"")
      end
      data.uid = WeakAuras.GenerateUniqueID()
      seenUIDs[data.uid] = data
    end
  end
  for uid, data in pairs(seenUIDs) do
    UIDtoID[uid] = data.id
  end
end

function Private.SyncParentChildRelationships(silent)
  -- 1. Find all auras where data.parent ~= nil or data.controlledChildren ~= nil
  --    If an aura has data.parent which doesn't exist, then remove data.parent
  --    If an aura has data.parent which doesn't have data.controlledChildren, then remove data.parent
  -- 2. For each aura with data.controlledChildren, iterate through the list of children and remove entries where:
  --    The child doesn't exist in the database
  --    The child ID is duplicated in data.controlledChildren (only the first will be kept)
  --    The child's data.parent points to a different parent
  --    The parent is a dynamic group and the child is a group/dynamic group
  --    Otherwise, mark the child as having a valid parent relationship
  -- 3. For each aura with data.parent, remove data.parent if it was not marked to have a valid relationship in 2.
  local parents = {}
  local children = {}
  local childHasParent = {}
  for id, data in pairs(db.displays) do
    if data.parent then
      if not db.displays[data.parent] then
        if not(silent) then
          prettyPrint("Detected corruption in saved variables: "..id.." has a nonexistent parent.")
        end
        data.parent = nil
      elseif not db.displays[data.parent].controlledChildren then
        if not silent then
          prettyPrint("Detected corruption in saved variables: "..id.." thinks "..data.parent..
                      " controls it, but "..data.parent.." is not a group.")
        end
        data.parent = nil
      else
        children[id] = data
      end
    end
    if data.controlledChildren then
      parents[id] = data
    end
  end

  for id, data in pairs(parents) do
    local groupChildren = {}
    local childrenToRemove = {}
    local dynamicGroup = data.regionType == "dynamicgroup"
    for index, childID in ipairs(data.controlledChildren) do
      local child = children[childID]
      if not child then
        if not silent then
          prettyPrint("Detected corruption in saved variables: "..id.." thinks it controls "..childID.." which doesn't exist.")
        end
        childrenToRemove[index] = true
      elseif child.parent ~= id then
        if not silent then
          prettyPrint("Detected corruption in saved variables: "..id.." thinks it controls "..childID.." which it does not.")
        end
        childrenToRemove[index] = true
      elseif dynamicGroup and child.controlledChildren then
        if not silent then
          prettyPrint("Detected corruption in saved variables: "..id.." is a dynamic group and controls "..childID.." which is a group/dynamicgroup.")
        end
        child.parent = nil
        children[child.id] = nil
        childrenToRemove[index] = true
      elseif groupChildren[childID] then
        if not silent then
          prettyPrint("Detected corruption in saved variables: "..id.." has "..childID.." as a child in multiple positions.")
        end
        childrenToRemove[index] = true
      else
        groupChildren[childID] = index
        childHasParent[childID] = true
      end
    end
    if next(childrenToRemove) ~= nil then
      for i = #data.controlledChildren, 1, -1 do
        if childrenToRemove[i] then
          tremove(data.controlledChildren, i)
        end
      end
    end
  end

  for id, data in pairs(children) do
    if not childHasParent[id] then
      if not silent then
        prettyPrint("Detected corruption in saved variables: "..id.." should be controlled by "..data.parent.." but isn't.")
      end
      local parent = parents[data.parent]
      tinsert(parent.controlledChildren, id)
    end
  end
end

local function loadOrder(tbl, idtable)
  local order = {}

  local loaded = {};
  local function load(id, depends)
    local data = idtable[id];
    if(data.parent) then
      if(idtable[data.parent]) then
        if depends[data.parent] then
          error("Circular dependency in Private.AddMany between "..table.concat(depends, ", "));
        else
          if not(loaded[data.parent]) then
            local dependsOut = CopyTable(depends)
            dependsOut[data.parent] = true
            coroutine.yield(100, "sort deps")
            load(data.parent, dependsOut)
            coroutine.yield(100, "sort deps")
          end
        end
      else
        data.parent = nil;
      end
    end
    if not(loaded[id]) then
      coroutine.yield(100, "sort deps");
      loaded[id] = true;
      tinsert(order, idtable[id])
    end
  end

  for id in pairs(idtable) do
    load(id, {});
    coroutine.yield(100, "sort deps")
  end

  return order
end

---@type fun(data: auraData)
local pAdd

function Private.CheckForAnchorCycle(source)
  local cycle = {}
  while source do
    cycle[source] = true
    local data = WeakAuras.GetData(source)
    local target
    if data then
      if data.anchorFrameType == "SELECTFRAME" and data.anchorFrameFrame then
        if data.anchorFrameFrame:sub(1, 10) == "WeakAuras:" then
          target = data.anchorFrameFrame:sub(11)
        end
      else
        target = data.parent
      end
    end
    if target and cycle[target] then
      return true
    end
    source = target
  end
  return false
end

---@param tbl auraData[]
---@param takeSnapshots boolean
function Private.AddMany(tbl, takeSnapshots)
  --- @type table<auraId, auraData>
  local idtable = {};
  --- @type table<auraId, auraId> The anchoring targets of other auras, key is the anchor, value is the aura that is anchoring
  local anchorTargets = {}
  for _, data in ipairs(tbl) do
    -- There was an unfortunate bug in update.lua in 2022 that resulted
    -- in auras having a circular dependencies
    -- Fix one of the two known cases here
    if data.id == data.parent then
      data.parent = nil
      tDeleteItem(data.controlledChildren, data.id)
    end
    idtable[data.id] = data;
    if data.anchorFrameType == "SELECTFRAME" and data.anchorFrameFrame and data.anchorFrameFrame:sub(1, 10) == "WeakAuras:" then
      anchorTargets[data.anchorFrameFrame:sub(11)] = data.id
    end
  end

  -- Now fix up anchors, see #3971, where aura p was anchored to aura c and where c was a child of p, thus c was anchored to p
  -- And #5395, where aura a was anchored to aura b, which was anchored to aura a
  -- The game used to detect such anchoring circles. We can't detect all of them, but at least detect the one from the ticket.
  for _, source in pairs(anchorTargets) do
    -- We walk up the parent's of target, to check for source
    if Private.CheckForAnchorCycle(source) then
      WeakAuras.prettyPrint(L["Warning: Anchoring in aura '%s' is imposssible, due to an anchoring cycle"]:format(source))
      idtable[source].anchorFrameType = "UIPARENT"
      idtable[source].anchorFrameFrame = ""
    end
  end

  local order = loadOrder(tbl, idtable)
  coroutine.yield(5000)

  local oldSnapshots = {}
  local copies = {}
  if takeSnapshots then
    for _, data in ipairs(order) do
      if Private.ModernizeNeedsOldSnapshot(data) then
        oldSnapshots[data.uid] = Private.GetMigrationSnapshot(data.uid)
      end
      copies[data.uid] = CopyTable(data)
      coroutine.yield(200, "addmany prepare snapshot")
    end
    if #order > 0 then
      Private.Threads:Add("snapshot", coroutine.create(function()
        prettyPrint(L["WeakAuras is creating a rollback snapshot of your auras. This snapshot will allow you to revert to the current state of your auras if something goes wrong. This process may cause your framerate to drop until it is complete."])
        for uid, data in pairs(copies) do
          Private.SetMigrationSnapshot(uid, data)
          coroutine.yield(200, "snapshot")
        end
        prettyPrint(L["Rollback snapshot is complete. Thank you for your patience!"])
      end), 'normal')
    else
      if next(WeakAuras.LoadFromArchive("Repository", "migration").stores) ~= nil then
        C_Timer.After(1, function()
          prettyPrint(L["WeakAuras has detected empty settings. If this is unexpected, ask for assitance on https://discord.gg/weakauras."])
        end)
      end
    end
  end

  local groups = {}
  local bads = {}
  for _, data in ipairs(order) do
    if data.parent and bads[data.parent] then
      bads[data.id] = true
    else
      local oldSnapshot = oldSnapshots[data.uid] or nil
      local ok = xpcall(WeakAuras.PreAdd, Private.GetErrorHandlerUid(data.uid, "PreAdd"), data, oldSnapshot)
      if not ok then
        prettyPrint(L["Unable to modernize aura '%s'. This is probably due to corrupt data or a bad migration, please report this to the WeakAuras team."]:format(data.id))
        if data.regionType == "dynamicgroup" or data.regionType == "group" then
          prettyPrint(L["All children of this aura will also not be loaded, to minimize the chance of further corruption."])
        end
        bads[data.id] = true
      elseif data.regionType == "dynamicgroup" or data.regionType == "group" then
        groups[data] = true
      end
      coroutine.yield(1000, "addmany modernize")
    end
  end

  for _, data in ipairs(order) do
    if not bads[data.id] then
      if data.parent and bads[data.parent] then
        bads[data.id] = true
      else
        local ok = xpcall(pAdd, Private.GetErrorHandlerUid(data.uid, "pAdd"), data)
        if not ok then
          bads[data.id] = true
        end
      end
    end
    coroutine.yield(2000, "addmany add")
  end

  for id in pairs(anchorTargets) do
    local data = idtable[id]
    if data and not bads[data.id] and (data.parent == nil or idtable[data.parent].regionType ~= "dynamicgroup") then
      Private.EnsureRegion(id)
      coroutine.yield(100, "addmany ensure anchor")
    end
  end

  for data in pairs(groups) do
    if not bads[data.id] then
      if data.type == "dynamicgroup" then
        if Private.regions[data.id] and Private.regions[data.id].region then
          Private.regions[data.id].region:ReloadControlledChildren()
        end
      else
        Private.Add(data)
      end
    end
    coroutine.yield(1000, "addmany reload dynamic group");
  end
end

local function customOptionIsValid(option)
  if not option.type then
    return false
  elseif Private.author_option_classes[option.type] == "simple" then
    if not option.key
    or not option.name
    or not option.default == nil then
      return false
    end
  elseif Private.author_option_classes[option.type] == "group" then
    if not option.key
    or not option.name
    or not option.default == nil
    or not option.subOptions then
      return false
    end
  end
  return true
end

local function validateUserConfig(data, options, config)
  local authorOptionKeys, corruptOptions = {}, {}
  for index, option in ipairs(options) do
    if not customOptionIsValid(option) or authorOptionKeys[option.key] then
      prettyPrint(data.id .. " Custom Option #" .. index .. " in " .. data.id .. " has been detected as corrupt, and has been deleted.")
      corruptOptions[index] = true
    else
      local optionClass = Private.author_option_classes[option.type]
      if option.key then
        authorOptionKeys[option.key] = index
      end
      if optionClass == "simple" then
        if not option.key then
          option.key = WeakAuras.GenerateUniqueID()
        end
        if config[option.key] == nil then
          if type(option.default) ~= "table" then
            config[option.key] = option.default
          else
            config[option.key] = CopyTable(option.default)
          end
        end
      elseif optionClass == "group" then
        local subOptions = option.subOptions
        if type(config[option.key]) ~= "table" then
          config[option.key] = {}
        end
        local subConfig = config[option.key]
        if option.groupType == "array" then
          for k, v in pairs(subConfig) do
            if type(k) ~= "number" or type(v) ~= "table" then
              -- if k was not a number, then this was a simple group before
              -- if v is not a table, then this was likely a color option
              wipe(subConfig) -- second iteration will fill table with defaults
              break
            end
          end
          if option.limitType == "fixed" then
            for i = #subConfig + 1, option.size do
              -- add missing entries
              subConfig[i] = {}
            end
          end
          if option.limitType ~= "none" then
            for i = option.size + 1, #subConfig do
              -- remove excess entries
              subConfig[i] = nil
            end
          end
          for _, toValidate in pairs(subConfig) do
            validateUserConfig(data, subOptions, toValidate)
          end
        else
          if type(next(subConfig)) ~= "string" then
            -- either there are no sub options, in which case this is a noop
            -- or this group was previously an array, in which case we need to wipe
            wipe(subConfig)
          end
          validateUserConfig(data, subOptions, subConfig)
        end
      end
    end
  end
  for key, value in pairs(config) do
    if not authorOptionKeys[key] then
      config[key] = nil
    else
      local option = options[authorOptionKeys[key]]
      local optionClass = Private.author_option_classes[option.type]
      if optionClass ~= "group" then
        local option = options[authorOptionKeys[key]]
        if option.type == "media" then
          -- sounds can be number or string, other kinds of media can only be string
          if type(value) ~= "string" and (type(value) ~= "number" or option.mediaType ~= "sound") then
            config[key] = option.default
          end
        elseif type(value) ~= type(option.default) then
          -- if type mismatch then we know that it can't be right
          if type(option.default) ~= "table" then
            config[key] = option.default
          else
            config[key] = CopyTable(option.default)
          end
        elseif option.type == "input" and option.useLength then
          config[key] = config[key]:sub(1, option.length)
        elseif option.type == "number" or option.type == "range" then
          if (option.max and option.max < value) or (option.min and option.min > value) then
            config[key] = option.default
          else
            if option.type == "number" and option.step then
              local min = option.min or 0
              config[key] = option.step * Round((value - min)/option.step) + min
            end
          end
        elseif option.type == "select" then
          if value < 1 or value > #option.values then
            config[key] = option.default
          end
        elseif option.type == "multiselect" then
          local multiselect = config[key]
          for i, v in ipairs(multiselect) do
            if option.default[i] ~= nil then
              if type(v) ~= "boolean" then
                multiselect[i] = option.default[i]
              end
            else
              multiselect[i] = nil
            end
          end
          for i, v in ipairs(option.default) do
            if type(multiselect[i]) ~= "boolean" then
              multiselect[i] = v
            end
          end
        elseif option.type == "color" then
          for i = 1, 4 do
            local c = config[key][i]
            if type(c) ~= "number" or c < 0 or c > 1 then
              config[key] = option.default
              break
            end
          end
        end
      end
    end
  end
  for i = #options, 1, -1 do
    if corruptOptions[i] then
      tremove(options, i)
    end
  end
end


local oldDataStub = {
  -- note: this is the minimal data stub which prevents false positives in diff upon reimporting an aura.
  -- pending a refactor of other code which adds unnecessary fields, it is possible to shrink it
  trigger = {
    type = "aura",
    names = {},
    event = "Health",
    subeventPrefix = "SPELL",
    subeventSuffix = "_CAST_START",
    spellIds = {},
    unit = "player",
    debuffType = "HELPFUL",
  },
  numTriggers = 1,
  untrigger = {},
  load = {
    size = {
      multi = {},
    },
    spec = {
      multi = {},
    },
    class = {
      multi = {},
    },
  },
  actions = {
    init = {},
    start = {},
    finish = {},
  },
  animation = {
    start = {
      type = "none",
      duration_type = "seconds",
    },
    main = {
      type = "none",
      duration_type = "seconds",
    },
    finish = {
      type = "none",
      duration_type = "seconds",
    },
  },
  conditions = {},
}

local oldDataStub2 = {
  -- note: this is the minimal data stub which prevents false positives in diff upon reimporting an aura.
  -- pending a refactor of other code which adds unnecessary fields, it is possible to shrink it
  triggers = {
    {
      trigger = {
        type = "aura",
        names = {},
        event = "Health",
        subeventPrefix = "SPELL",
        subeventSuffix = "_CAST_START",
        spellIds = {},
        unit = "player",
        debuffType = "HELPFUL",
      },
      untrigger = {},
    },
  },
  load = {
    size = {
      multi = {},
    },
    spec = {
      multi = {},
    },
    class = {
      multi = {},
    },
  },
  actions = {
    init = {},
    start = {},
    finish = {},
  },
  animation = {
    start = {
      type = "none",
      duration_type = "seconds",
    },
    main = {
      type = "none",
      duration_type = "seconds",
    },
    finish = {
      type = "none",
      duration_type = "seconds",
    },
  },
  conditions = {},
}

--- @type fun(data: auraData)
function Private.UpdateSoundIcon(data)
  local function testConditions()
    local sound, tts
    if data.conditions then
      for _, condition in ipairs(data.conditions) do
        for changeIndex, change in ipairs(condition.changes) do
          if change.property == "sound" then
            sound = true
          end
          if change.property == "chat" and change.value and change.value.message_type == "TTS" then
            tts = true
          end
          if sound and tts then break end
        end
      end
    end
    return sound, tts
  end

  local soundCondition, ttsCondition = testConditions()

  -- sound
  if data.actions.start.do_sound or data.actions.finish.do_sound then
    Private.AuraWarnings.UpdateWarning(data.uid, "sound_action", "sound", L["This aura plays a sound via an action."])
  else
    Private.AuraWarnings.UpdateWarning(data.uid, "sound_action")
  end

  if soundCondition then
    Private.AuraWarnings.UpdateWarning(data.uid, "sound_condition", "sound", L["This aura plays a sound via a condition."])
  else
    Private.AuraWarnings.UpdateWarning(data.uid, "sound_condition")
  end

  -- tts
  if (data.actions.start.do_message and data.actions.start.message_type == "TTS")
  or (data.actions.finish.do_message and data.actions.finish.message_type == "TTS")
  then
    Private.AuraWarnings.UpdateWarning(data.uid, "tts_action", "tts", L["This aura plays a Text To Speech via an action."])
  else
    Private.AuraWarnings.UpdateWarning(data.uid, "tts_action")
  end

  if ttsCondition then
    Private.AuraWarnings.UpdateWarning(data.uid, "tts_condition", "tts", L["This aura plays a Text To Speech via a condition."])
  else
    Private.AuraWarnings.UpdateWarning(data.uid, "tts_condition")
  end
end

function Private.ClearSounds(uid, severity)
  local data = Private.GetDataByUID(uid)

  for child in Private.TraverseLeafsOrAura(data) do
    local changed = false
    if child.conditions then
      for _, condition in ipairs(child.conditions) do
        for changeIndex = #condition.changes, 1, -1 do
          local change = condition.changes[changeIndex]
          if change.property == "sound" and severity == "sound" then
            tremove(condition.changes, changeIndex)
            changed = true
          elseif change.property == "chat" and change.value and change.value.message_type == "TTS" and severity == "tts" then
            tremove(condition.changes, changeIndex)
            changed = true
          end
        end
      end
    end

    if severity == "sound" and (child.actions.start.do_sound or child.actions.finish.do_sound) then
      child.actions.start.do_sound = false
      child.actions.finish.do_sound = false
      changed = true
    elseif severity == "tts" then
      if child.actions.start.do_message and child.actions.start.message_type == "TTS" then
        child.actions.start.do_message = false
        changed = true
      end
      if child.actions.finish.do_message and child.actions.finish.message_type == "TTS" then
        child.actions.finish.do_message = false
        changed = true
      end
    end
    if changed then
      WeakAuras.Add(child)
    end
  end
  WeakAuras.ClearAndUpdateOptions(data.id, true)
  WeakAuras.FillOptions()
end

function WeakAuras.PreAdd(data, snapshot)
  if not data then return end
  -- Readd what Compress removed before version 8
  if (not data.internalVersion or data.internalVersion < 7) then
    Private.validate(data, oldDataStub)
  elseif (data.internalVersion < 8) then
    Private.validate(data, oldDataStub2)
  end

  xpcall(Private.Modernize, Private.GetErrorHandlerId(data.id, L["Modernize"]), data, snapshot)

  local default = data.regionType and Private.regionTypes[data.regionType] and Private.regionTypes[data.regionType].default
  if default then
    Private.validate(data, default)
  end

  local regionValidate = data.regionType and Private.regionTypes[data.regionType] and Private.regionTypes[data.regionType].validate
  if regionValidate then
    regionValidate(data)
  end

  Private.validate(data, Private.data_stub);
  if data.subRegions then
    for _, subRegionData in ipairs(data.subRegions) do
      local subType = subRegionData.type
      if subType and Private.subRegionTypes[subType] then
        if Private.subRegionTypes[subType].supports(data.regionType) then
          local default = Private.subRegionTypes[subType].default
          if type(default) == "function" then
            default = default(data.regionType)
          end
          if default then
            Private.validate(subRegionData, default)
          end
        else
          WeakAuras.prettyPrint(L["ERROR in '%s' unknown or incompatible sub element type '%s'"]:format(data.id, subType))
        end
      end
    end
  end
  validateUserConfig(data, data.authorOptions, data.config)
  data.init_started = nil
  data.init_completed = nil
  data.expanded = nil
end

local function cycleCheck(data)
  local id = data.id
  if data.anchorFrameType == "SELECTFRAME" and data.anchorFrameFrame and data.anchorFrameFrame:sub(1, 10) == "WeakAuras:" then
    if Private.CheckForAnchorCycle(id) then
      WeakAuras.prettyPrint(L["Warning: Anchoring in aura '%s' is imposssible, due to an anchoring cycle"]:format(id))
      db.displays[id].anchorFrameType = "UIPARENT"
      db.displays[id].anchorFrameFrame = ""
    end
  end
end

function pAdd(data, simpleChange)
  local id = data.id;
  if not(id) then
    error("Improper arguments to WeakAuras.Add - id not defined");
    return;
  end

  data.uid = data.uid or WeakAuras.GenerateUniqueID()
  if db.displays[id] and db.displays[id].uid ~= data.uid then
    print("Improper? arguments to WeakAuras.Add - id", id, "is assigned to a different uid.", data.uid, db.displays[id].uid)
  end
  if UIDtoID[data.uid] and UIDtoID[data.uid] ~= id then
    print("Improper? arguments to WeakAuras.Add - uid is assigned to a id. Uid:", data.uid, "assigned too:", UIDtoID[data.uid], "assigning now to", data.id)
  end

  local otherID = UIDtoID[data.uid]
  if not otherID then
    UIDtoID[data.uid] = id
  elseif otherID ~= id then
    -- duplicate uid
    data.uid = WeakAuras.GenerateUniqueID()
    UIDtoID[data.uid] = id
  end

  if simpleChange then
    db.displays[id] = data
    cycleCheck(data)
    if WeakAuras.GetRegion(data.id) then
      Private.SetRegion(data)
    end
    if clones[id] then
      for cloneId, region in pairs(clones[id]) do
        Private.SetRegion(data, cloneId)
      end
    end
    Private.UpdatedTriggerState(id)
    Private.callbacks:Fire("Add", data.uid, data.id, data, simpleChange)
  else
    Private.DebugLog.SetEnabled(data.uid, data.information.debugLog)

    if Private.IsGroupType(data) then
      Private.ClearAuraEnvironment(id);
      for parent in Private.TraverseParents(data) do
        Private.ClearAuraEnvironment(parent.id);
      end
      db.displays[id] = data;
      cycleCheck(data)

      if WeakAuras.GetRegion(data.id) then
        Private.SetRegion(data)
      end
      Private.ScanForLoadsGroup({[id] = true});
      loadEvents["GROUP"] = loadEvents["GROUP"] or {}
      loadEvents["GROUP"][id] = true
    else -- Non group aura
      -- Make sure that we don't have a controlledChildren member.
      data.controlledChildren = nil
      local visible
      if (WeakAuras.IsOptionsOpen()) then
        visible = Private.FakeStatesFor(id, false)
      else
        if (Private.regions[id] and Private.regions[id].region) then
          Private.regions[id].region:Collapse()
        else
          Private.CollapseAllClones(id)
        end
      end

      -- If the aura has a onHide animation we need to cancel it to ensure it's truly hidden now
      if Private.regions[id] then
        Private.CancelAnimation(Private.regions[id].region, true, true, true, true, true, true)
      end
      if clones[id] then
        for _, region in pairs(clones[id]) do
          Private.CancelAnimation(region, true, true, true, true, true, true)
        end
      end

      Private.ClearAuraEnvironment(id);
      for parent in Private.TraverseParents(data) do
        Private.ClearAuraEnvironment(parent.id);
      end

      db.displays[id] = data
      cycleCheck(data)

      if (not data.triggers.activeTriggerMode or data.triggers.activeTriggerMode > #data.triggers) then
        data.triggers.activeTriggerMode = Private.trigger_modes.first_active;
      end

      for _, triggerSystem in pairs(triggerSystems) do
        triggerSystem.Add(data);
      end

      local loadFuncStr, events = ConstructFunction(load_prototype, data.load);
      for event, eventData in pairs(loadEvents) do
        eventData[id] = nil
      end
      for event in pairs(events) do
        loadEvents[event] = loadEvents[event] or {}
        loadEvents[event][id] = true
      end
      loadEvents["SCAN_ALL"] = loadEvents["SCAN_ALL"] or {}
      loadEvents["SCAN_ALL"][id] = true

      local loadForOptionsFuncStr = ConstructFunction(load_prototype, data.load, true);
      local loadFunc = Private.LoadFunction(loadFuncStr, id);
      local loadForOptionsFunc = Private.LoadFunction(loadForOptionsFuncStr, id);
      local triggerLogicFunc;
      if data.triggers.disjunctive == "custom" then
        triggerLogicFunc = WeakAuras.LoadFunction("return "..(data.triggers.customTriggerLogic or ""), data.id);
      end

      LoadCustomActionFunctions(data);
      Private.LoadConditionPropertyFunctions(data);
      Private.LoadConditionFunction(data)

      loadFuncs[id] = loadFunc;
      loadFuncsForOptions[id] = loadForOptionsFunc;
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

      if WeakAuras.GetRegion(data.id) then
        Private.SetRegion(data)
      end

      triggerState[id] = {
        disjunctive = data.triggers.disjunctive or "all",
        numTriggers = #data.triggers,
        activeTriggerMode = data.triggers.activeTriggerMode or Private.trigger_modes.first_active,
        triggerLogicFunc = triggerLogicFunc,
        triggers = {},
        activationTime = {},
        triggerCount = 0,
        activatedConditions = {},
      };

      if (WeakAuras.IsOptionsOpen()) then
        Private.FakeStatesFor(id, visible)
      end

      if not(paused) then
        Private.ScanForLoads({[id] = true});
      end
    end

    Private.UpdateSoundIcon(data)
    Private.callbacks:Fire("Add", data.uid, data.id, data, simpleChange)
  end
end

function Private.Add(data, simpleChange)
  local oldSnapshot
  if Private.ModernizeNeedsOldSnapshot(data) then
    oldSnapshot = Private.GetMigrationSnapshot(data.uid)
  end
  if (data.internalVersion or 0) < internalVersion then
    Private.SetMigrationSnapshot(data.uid, data)
  end
  local ok = xpcall(WeakAuras.PreAdd, Private.GetErrorHandlerUid(data.uid, "PreAdd"), data, oldSnapshot)
  if ok then
    pAdd(data, simpleChange)
  end
end

function WeakAuras.Add(data, simpleChange)
  Private.TimeMachine:DestroyTheUniverse(data.id)
  Private.Add(data, simpleChange)
end

function Private.AddParents(data)
  local parent = data.parent
  if (parent) then
    local parentData = WeakAuras.GetData(parent)
    WeakAuras.Add(parentData)
    Private.AddParents(parentData)
  end
end

function Private.SetRegion(data, cloneId)
  local regionType = data.regionType;
  if not(regionType) then
    error("Improper arguments to Private.SetRegion - regionType not defined in ".. data.id)
  else
    if(not regionTypes[regionType]) then
      regionType = "fallback";
      print("Improper arguments to WeakAuras.CreateRegion - regionType \""..data.regionType.."\" is not supported in ".. data.id)
    end

    local id = data.id;
    if not(id) then
      error("Improper arguments to Private.SetRegion - id not defined");
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
            local clone = regionTypes[data.regionType].create(WeakAurasFrame, data);
            clone.regionType = data.regionType;
            clone:Hide();
            clones[id][cloneId] = clone;
          end
          region = clones[id][cloneId];
        end
      else
        if((not Private.regions[id]) or (not Private.regions[id].region) or Private.regions[id].regionType ~= regionType) then
          region = regionTypes[regionType].create(WeakAurasFrame, data);
          Private.regions[id] = {
            regionType = regionType,
            region = region
          };
          if regionType ~= "dynamicgroup" and regionType ~= "group" then
            region.toShow = false
            region:Hide()
          else
            region.toShow = true
          end
        else
          region = Private.regions[id].region
        end
      end
      region.id = id;
      region.cloneId = cloneId or "";
      Private.validate(data, regionTypes[regionType].default);

      local parent = WeakAurasFrame;
      if data.parent then
        local parentRegion = Private.EnsureRegion(data.parent)
        if parentRegion then
          parent = parentRegion
        else
          data.parent = nil;
        end
      end
      local loginFinished = WeakAuras.IsLoginFinished();
      local anim_cancelled = loginFinished and Private.CancelAnimation(region, true, true, true, true, true, true);

      regionTypes[regionType].modify(parent, region, data);
      Private.regionPrototype.AddSetDurationInfo(region, data.uid)
      Private.regionPrototype.AddExpandFunction(data, region, cloneId, parent, parent.regionType)

      data.animation = data.animation or {};
      data.animation.start = data.animation.start or {type = "none"};
      data.animation.main = data.animation.main or {type = "none"};
      data.animation.finish = data.animation.finish or {type = "none"};
      data.animation.start.duration_type = data.animation.start.duration_type or "seconds"
      data.animation.main.duration_type = data.animation.main.duration_type or "seconds"
      data.animation.finish.duration_type = data.animation.finish.duration_type or "seconds"

      if(cloneId) then
        clonePool[regionType] = clonePool[regionType] or {};
      end
      if(anim_cancelled) then
        Private.Animate("display", data.uid, "main", data.animation.main, region, false, nil, true, cloneId);
      end
      return region;
    end
  end
end

--- Ensures that a clone exists
---@param id auraId
---@param cloneId string
---@return table
local function EnsureClone(id, cloneId)
  clones[id] = clones[id] or {}
  if not(clones[id][cloneId]) then
    local data = WeakAuras.GetData(id)
    Private.SetRegion(data, cloneId)
  end
  return clones[id][cloneId]
end

local creatingRegions = false

function Private.CreatingRegions()
  return creatingRegions
end

--- Ensures that a region exists
---@param id auraId
---@return table
local function EnsureRegion(id)
  if not Private.regions[id] or not Private.regions[id].region then
    Private.regions[id] = Private.regions[id] or {}

    -- The region doesn't yet exist
    -- But we must also ensure that our parents exists

    -- So we go up the list of parents and collect auras that must be created
    -- If we find a parent already exists, we can stop
    --- @type auraId[]
    local aurasToCreate = {}

    while(id) do
      local data = WeakAuras.GetData(id)
      tinsert(aurasToCreate, data.id)
      id = data.parent

      if WeakAuras.GetRegion(id) then
        break
      end
    end

    for _, toCreateId in ipairs_reverse(aurasToCreate) do
      local data = WeakAuras.GetData(toCreateId)
      Private.SetRegion(data)
    end
  end
  return Private.regions[id] and Private.regions[id].region
end

--- Ensures that a region/clone exists and returns it
function Private.EnsureRegion(id, cloneId)
  -- Even if we are asked to only create a clone, we create the default region
  -- too.
  EnsureRegion(id)
  if(cloneId and cloneId ~= "") then
    return EnsureClone(id, cloneId);
  end
  return WeakAuras.GetRegion(id)
end

---returns the region, if it exists
---@param id auraId
---@param cloneId string|nil
---@return table|nil
function WeakAuras.GetRegion(id, cloneId)
  if(cloneId and cloneId ~= "") then
    return clones[id] and clones[id][cloneId]
  end
  return Private.regions[id] and Private.regions[id].region
end

-- Note, does not create a clone!
function Private.GetRegionByUID(uid, cloneId)
  local id = Private.UIDtoID(uid)
  if(cloneId and cloneId ~= "") then
    return id and clones[id] and clones[id][cloneId];
  end
  return id and Private.regions[id] and Private.regions[id].region
end

function Private.CollapseAllClones(id, triggernum)
  if(clones[id]) then
    for i,v in pairs(clones[id]) do
      v:Collapse();
    end
  end
end

function Private.SetAllStatesHidden(id, triggernum)
  local triggerState = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
  local changed = false
  for _, state in pairs(triggerState) do
    changed = changed or state.show
    state.show = false;
    state.changed = true;
  end
  return changed
end

function Private.SetAllStatesHiddenExcept(id, triggernum, list)
  local triggerState = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
  for cloneId, state in  pairs(triggerState) do
    if (not (list[cloneId])) then
      state.show = false;
      state.changed = true;
    end
  end
end

function Private.ReleaseClone(id, cloneId, regionType)
  if (not clones[id]) then
    return;
  end
  local region = clones[id][cloneId];
  clones[id][cloneId] = nil;
  if region:IsProtected() then
    WeakAuras.prettyPrint(L["Error '%s' created a secure clone. We advise deleting the aura. For more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"]:format(id))
  else
    clonePool[regionType][#clonePool[regionType] + 1] = region;
  end
end

function Private.HandleChatAction(message_type, message, message_dest, message_dest_isunit, message_channel, r, g, b, region, customFunc, when, formatters, voice)
  local useHiddenStates = when == "finish"
  if (message:find('%%')) then
    message = Private.ReplacePlaceHolders(message, region, customFunc, useHiddenStates, formatters);
  end
  if(message_type == "PRINT") then
    DEFAULT_CHAT_FRAME:AddMessage(message, r or 1, g or 1, b or 1);
  elseif message_type == "TTS" then
    local validVoice = voice and Private.tts_voices[voice]
    if not Private.SquelchingActions() then
      pcall(function()
        C_VoiceChat.SpeakText(
          validVoice and voice or next(Private.tts_voices) or 0,
          message,
          1,
          C_TTSSettings and C_TTSSettings.GetSpeechRate() or 0,
          C_TTSSettings and C_TTSSettings.GetSpeechVolume() or 100
        );
      end)
    end
  elseif message_type == "ERROR" then
    UIErrorsFrame:AddMessage(message, r or 1, g or 1, b or 1)
  elseif(message_type == "COMBAT") then
    if(CombatText_AddMessage) then
      CombatText_AddMessage(message, COMBAT_TEXT_SCROLL_FUNCTION, r or 1, g or 1, b or 1);
    end
  elseif(message_type == "WHISPER") then
    if(message_dest) then
      if (message_dest:find('%%')) then
        message_dest = Private.ReplacePlaceHolders(message_dest, region, customFunc, useHiddenStates, formatters);
      end
      if message_dest_isunit == true then
        message_dest = GetUnitName(message_dest, true)
      end
      pcall(function() SendChatMessage(message, "WHISPER", nil, message_dest) end);
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
      if IsInInstance() then
        pcall(function() SendChatMessage(message, "SAY") end)
      end
    end
  elseif(message_type == "SAY" or message_type == "YELL") then
    if IsInInstance() then
      pcall(function() SendChatMessage(message, message_type, nil, nil) end)
    end
  else
    pcall(function() SendChatMessage(message, message_type, nil, nil) end);
  end
end

local function actionGlowStop(actions, frame, id)
  if not frame.__WAGlowFrame then return end
  if actions.glow_type == "buttonOverlay" then
    LCG.ButtonGlow_Stop(frame.__WAGlowFrame)
  elseif actions.glow_type == "Pixel" then
    LCG.PixelGlow_Stop(frame.__WAGlowFrame, id)
  elseif actions.glow_type == "ACShine" then
    LCG.AutoCastGlow_Stop(frame.__WAGlowFrame, id)
  elseif actions.glow_type == "Proc" then
    LCG.ProcGlow_Stop(frame.__WAGlowFrame, id)
  end
end

local function actionGlowStart(actions, frame, id)
  if not frame.__WAGlowFrame then
    frame.__WAGlowFrame = CreateFrame("Frame", nil, frame)
    frame.__WAGlowFrame:SetAllPoints(frame)
    frame.__WAGlowFrame:SetSize(frame:GetSize())
  end
  local glow_frame = frame.__WAGlowFrame
  if glow_frame:GetWidth() < 1 or glow_frame:GetHeight() < 1 then
    actionGlowStop(actions, frame)
    return
  end
  local color = actions.use_glow_color and actions.glow_color or nil
  if actions.glow_type == "buttonOverlay" then
    LCG.ButtonGlow_Start(glow_frame, color)
  elseif actions.glow_type == "Pixel" then
    LCG.PixelGlow_Start(
      glow_frame,
      color,
      actions.glow_lines,
      actions.glow_frequency,
      actions.glow_length,
      actions.glow_thickness,
      actions.glow_XOffset,
      actions.glow_YOffset,
      actions.glow_border and true or false,
      id
    )
  elseif actions.glow_type == "ACShine" then
    LCG.AutoCastGlow_Start(
      glow_frame,
      color,
      actions.glow_lines,
      actions.glow_frequency,
      actions.glow_scale,
      actions.glow_XOffset,
      actions.glow_YOffset,
      id
    )
  elseif actions.glow_type == "Proc" then
    LCG.ProcGlow_Start(glow_frame, {
      color = color,
      startAnim = actions.glow_startAnim and true or false,
      xOffset = actions.glow_XOffset,
      yOffset = actions.glow_YOffset,
      duration = actions.glow_duration or 1,
      key = id
  })
  end
end

local glow_frame_monitor
local anchor_unitframe_monitor
Private.dyngroup_unitframe_monitor = {}
do
  local function frame_monitor_callback(event, frame, unit, previousUnit)
    local new_frame
    local FRAME_UNIT_UPDATE = event == "FRAME_UNIT_UPDATE"
    local FRAME_UNIT_ADDED = event == "FRAME_UNIT_ADDED"
    local FRAME_UNIT_REMOVED = event == "FRAME_UNIT_REMOVED"

    local dynamicGroupsToUpdate = {}

    if type(glow_frame_monitor) == "table" then
      for region, data in pairs(glow_frame_monitor) do
        if region.state and type(region.state.unit) == "string" and UnitIsUnit(region.state.unit, unit)
        and ((data.frame ~= frame) and (FRAME_UNIT_ADDED or FRAME_UNIT_UPDATE))
        or ((data.frame == frame) and FRAME_UNIT_REMOVED)
        then
          if not new_frame then
            new_frame = WeakAuras.GetUnitFrame(unit)
          end
          if new_frame ~= data.frame then
            local id = region.id .. (region.cloneId or "")
            -- remove previous glow
            if data.frame then
              actionGlowStop(data.actions, data.frame, id)
            end
            data.frame = new_frame
            if new_frame then
              -- apply the glow to new_frame
              actionGlowStart(data.actions, data.frame, id)
              -- update hidefunc
              local region = region
              region.active_glows_hidefunc = region.active_glows_hidefunc or {}
              region.active_glows_hidefunc[data.frame] = function()
                actionGlowStop(data.actions, data.frame, id)
                glow_frame_monitor[region] = nil
              end
            end
          end
        end
      end
    end
    if type(anchor_unitframe_monitor) == "table" then
      for region, data in pairs(anchor_unitframe_monitor) do
        if region.state and type(region.state.unit) == "string" and UnitIsUnit(region.state.unit, unit)
        and ((data.frame ~= frame) and (FRAME_UNIT_ADDED or FRAME_UNIT_UPDATE))
        or ((data.frame == frame) and FRAME_UNIT_REMOVED)
        then
          if not new_frame then
            new_frame = WeakAuras.GetUnitFrame(unit) or WeakAuras.HiddenFrames
          end
          if new_frame ~= data.frame then
            Private.AnchorFrame(data.data, region, data.parent)
          end
        end
      end
    end
    for regionData, data_frame in pairs(Private.dyngroup_unitframe_monitor) do
      if regionData.region.state and type(regionData.region.state.unit) == "string" and UnitIsUnit(regionData.region.state.unit, unit)
      and ((data_frame ~= frame) and (FRAME_UNIT_ADDED or FRAME_UNIT_UPDATE))
      or ((data_frame == frame) and FRAME_UNIT_REMOVED)
      then
        if not new_frame then
          new_frame = WeakAuras.GetUnitFrame(unit) or WeakAuras.HiddenFrames
        end
        if new_frame and new_frame ~= data_frame then
          dynamicGroupsToUpdate[regionData.parent] = true
        end
      end
    end

    for frame in pairs(dynamicGroupsToUpdate) do
      frame:DoPositionChildren()
    end
  end

  LGF.RegisterCallback("WeakAuras", "FRAME_UNIT_UPDATE", frame_monitor_callback)
  LGF.RegisterCallback("WeakAuras", "FRAME_UNIT_ADDED", frame_monitor_callback)
  LGF.RegisterCallback("WeakAuras", "FRAME_UNIT_REMOVED", frame_monitor_callback)
end

function Private.HandleGlowAction(actions, region)
  if actions.glow_action
  and (
    (
      (actions.glow_frame_type == "UNITFRAME" or actions.glow_frame_type == "NAMEPLATE")
      and region.state.unit
    )
    or (actions.glow_frame_type == "FRAMESELECTOR" and actions.glow_frame)
    or (actions.glow_frame_type == "PARENTFRAME" and region:GetParent())
  )
  then
    local glow_frame, should_glow_frame
    if actions.glow_frame_type == "FRAMESELECTOR" then
      if actions.glow_frame:sub(1, 10) == "WeakAuras:" then
        local frame_name = actions.glow_frame:sub(11)
        if WeakAuras.GetData(frame_name) then
          Private.EnsureRegion(frame_name)
        end
        if Private.regions[frame_name] and Private.regions[frame_name].region then
          glow_frame = Private.regions[frame_name].region
          should_glow_frame = true
        end
      else
        glow_frame = Private.GetSanitizedGlobal(actions.glow_frame)
        should_glow_frame = true
      end
    elseif actions.glow_frame_type == "UNITFRAME" and region.state.unit then
      glow_frame = WeakAuras.GetUnitFrame(region.state.unit)
      should_glow_frame = true
    elseif actions.glow_frame_type == "NAMEPLATE" and region.state.unit then
      glow_frame = WeakAuras.GetUnitNameplate(region.state.unit)
      should_glow_frame = true
    elseif actions.glow_frame_type == "PARENTFRAME" then
      glow_frame = region:GetParent()
      should_glow_frame = true
    end

    if should_glow_frame then
      local id = region.id .. (region.cloneId or "")
      if actions.glow_action == "show" then
        -- remove previous glow
        if glow_frame then
          if region.active_glows_hidefunc
          and region.active_glows_hidefunc[glow_frame]
          then
            region.active_glows_hidefunc[glow_frame]()
          end
          -- start glow
          actionGlowStart(actions, glow_frame, id)
          -- make unglow function & monitor unitframe changes
          region.active_glows_hidefunc = region.active_glows_hidefunc or {}
          if actions.glow_frame_type == "UNITFRAME" then
            region.active_glows_hidefunc[glow_frame] = function()
              actionGlowStop(actions, glow_frame, id)
              glow_frame_monitor[region] = nil
            end
          else
            region.active_glows_hidefunc[glow_frame] = function()
              actionGlowStop(actions, glow_frame, id)
            end
          end
        end
        if actions.glow_frame_type == "UNITFRAME" then
          glow_frame_monitor = glow_frame_monitor or {}
          glow_frame_monitor[region] = {
            actions = actions,
            frame = glow_frame
          }
        end
      elseif actions.glow_action == "hide"
      and glow_frame
      and region.active_glows_hidefunc
      and region.active_glows_hidefunc[glow_frame]
      then
        region.active_glows_hidefunc[glow_frame]()
        region.active_glows_hidefunc[glow_frame] = nil
      end
    end
  end
end

function Private.PerformActions(data, when, region)
  if (paused or WeakAuras.IsOptionsOpen()) then
    return;
  end;
  local actions;
  local formatters
  if(when == "start") then
    actions = data.actions.start;
    formatters = region.startFormatters
  elseif(when == "finish") then
    actions = data.actions.finish;
    formatters = region.finishFormatters
  else
    return;
  end

  if(actions.do_message and actions.message_type and actions.message) then
    local customFunc = Private.customActionsFunctions[data.id][when .. "_message"];
    Private.HandleChatAction(actions.message_type, actions.message, actions.message_dest, actions.message_dest_isunit, actions.message_channel, actions.r, actions.g, actions.b, region, customFunc, when, formatters, actions.message_tts_voice);
  end

  if (actions.stop_sound) then
    if (region.SoundStop) then
      local fadeoutTime = actions.do_sound_fade and actions.stop_sound_fade and actions.stop_sound_fade * 1000 or 0
      region:SoundStop(fadeoutTime);
    end
  end

  if(actions.do_sound and actions.sound) then
    if (region.SoundPlay) then
      region:SoundPlay(actions);
    end
  end

  if(actions.do_custom and actions.custom) then
    local func = Private.customActionsFunctions[data.id][when]
    if func then
      Private.ActivateAuraEnvironment(region.id, region.cloneId, region.state, region.states);
      xpcall(func, Private.GetErrorHandlerId(data.id, L["Custom Action"]));
      Private.ActivateAuraEnvironment(nil);
    end
  end

  -- Apply start glow actions even if squelch_actions is true, but don't apply finish glow actions
  if actions.do_glow then
    Private.HandleGlowAction(actions, region)
  end

  -- remove all glows on finish
  if when == "finish" and actions.hide_all_glows and region.active_glows_hidefunc then
    for _, hideFunc in pairs(region.active_glows_hidefunc) do
      hideFunc()
    end
    wipe(region.active_glows_hidefunc)
  end
  if when == "finish" and type(anchor_unitframe_monitor) == "table" then
    anchor_unitframe_monitor[region] = nil
  end
end

--- @type fun(id: auraId): auraData?
function WeakAuras.GetData(id)
  return id and db.displays[id];
end

local function GetTriggerSystem(data, triggernum)
  local triggerType = data.triggers[triggernum] and data.triggers[triggernum].trigger.type
  return triggerType and triggerTypes[triggerType]
end

local function wrapTriggerSystemFunction(functionName, mode)
  local func;
  func = function(data, triggernum, ...)
    if (not triggernum) then
      return func(data, data.triggers.activeTriggerMode or -1, ...);
    elseif (triggernum < 0) then
      local result;
      if (mode == "or") then
        result = false;
        for i = 1, #data.triggers do
          result = result or func(data, i);
        end
      elseif (mode == "and") then
        result = true;
        for i = 1, #data.triggers do
          result = result and func(data, i);
        end
      elseif (mode == "table") then
        result = {};
        for i = 1, #data.triggers do
          local tmp = func(data, i);
          if (tmp) then
            for k, v in pairs(tmp) do
              result[k] = v;
            end
          end
        end
      elseif (mode == "call") then
        for i = 1, #data.triggers do
          func(data, i, ...);
        end
      elseif (mode == "firstValue") then
        result = nil;
        for i = 1, #data.triggers do
          local tmp = func(data, i);
          if (tmp) then
            result = tmp;
            break;
          end
        end
      elseif (mode == "nameAndIcon") then
        for i = 1, #data.triggers do
          local tmp1, tmp2 = func(data, i);
          if (tmp1) then
            return tmp1, tmp2;
          end
        end
      end
      return result;
    else -- triggernum >= 1
      local triggerSystem = GetTriggerSystem(data, triggernum);
      if (not triggerSystem) then
        return false
      end
      return triggerSystem[functionName](data, triggernum, ...);
    end
  end
  return func;
end

Private.CanHaveTooltip = wrapTriggerSystemFunction("CanHaveTooltip", "or");
-- This has to be in WeakAuras for now, because GetNameAndIcon can be called from the options
-- before the Options has access to Private
WeakAuras.GetNameAndIcon = wrapTriggerSystemFunction("GetNameAndIcon", "nameAndIcon");
Private.GetTriggerDescription = wrapTriggerSystemFunction("GetTriggerDescription", "call");

local wrappedGetOverlayInfo = wrapTriggerSystemFunction("GetOverlayInfo", "table");

Private.GetAdditionalProperties = function(data)
  local props = {}
  for child in Private.TraverseLeafsOrAura(data) do
    for i, trigger in ipairs(child.triggers) do
      local triggerSystem = GetTriggerSystem(child, i)
      if triggerSystem then
        local triggerProps = triggerSystem.GetAdditionalProperties(child, i)
        if triggerProps and props[i] then
          MergeTable(props[i], triggerProps)
        elseif triggerProps then
          props[i] = triggerProps
        end
      end
    end
  end
  return props
end

Private.GetProgressSources = function(data)
  local values = {}
  if Private.IsGroupType(data) then
    return values
  end
  for i = 1, #data.triggers do
    local triggerSystem = GetTriggerSystem(data, i);
    if (triggerSystem) then
      triggerSystem.GetProgressSources(data, i, values)
    end
  end
  return values
end

Private.GetProgressSourceFor = function(data, trigger, property)
  local values = {}
  local triggerSystem = GetTriggerSystem(data, trigger);
  if (triggerSystem) then
    triggerSystem.GetProgressSources(data, trigger, values)
    for _, v in ipairs(values) do
      if v.property == property then
        return {trigger, v.type, v.property, v.total, v.modRate, v.inverse, v.paused, v.remaining}
      end
    end
  end
  return nil
end

-- In the aura data we only store trigger + property
-- But for the region we don't want to gather necessary meta data all the time
-- So we collect that in region:modify + on creation of the conditions function
Private.AddProgressSourceMetaData = function(data, progressSource)
  if not progressSource then
    return {}
  end
  local trigger = progressSource[1]
  local property = progressSource[2]
  if trigger == -2 then
    return {-2, "auto", ""}
  elseif trigger == -1 then
    return {-1, "auto", ""}
  elseif trigger == 0 then
    return {0, "manual", progressSource[3], progressSource[4]}
  else
    return Private.GetProgressSourceFor(data, trigger, property)
  end
end

-- ProgressSource values
-- For AceOptions to work correctly progress sources need to be comparable
-- via ==. We use a constants table so that identical tables use the same table
-- Additional while data.progressSource does contain additional data e.g. for manual progress
-- This is only for the progress source combobox, which only cares about the first or first two values
-- The greatness of the hacks knows no bounds
-- The constants table has weak keys
do
  local function CompareProgressValueTables(a, b)
    -- For auto/manual progress, only compare a[] with b[1]
    if a[1] == -1 or a[1] == 0 then
      return a[1] == b[1]
    end
    -- Only care about trigger + property
    return a[1] == b[1] and a[2] == b[2]
  end

  local progressValueConstants = {}
  setmetatable(progressValueConstants, {_mode = "v"})

  function Private.GetProgressValueConstant(v)
    if v == nil then
      return v
    end

    -- This uses pairs because there could be empty slots
    for _, constant in pairs(progressValueConstants) do
      if CompareProgressValueTables(v, constant) then
        return constant
      end
    end
    -- And this inserts into the first empty slot for the array
    tinsert(progressValueConstants, v)
    return v
  end
end

function Private.GetProgressSourcesForUi(data, subelement)
  local values

  if subelement then
    -- Sub elements Automatic means to use the main auras' progress
    values = {
      [{-2, ""}] = L["Automatic"]
    }
  else
    values = {
      [{-1, ""}] = L["Automatic"],
      [{0, ""}] = L["Manual"],
    }
  end

  local triggerValues = Private.GetProgressSources(data)
  for _, e in ipairs(triggerValues) do
    if e.trigger and e.property then
      values[{e.trigger, e.property}] = {L["Trigger %s"]:format(e.trigger), e.display}
    end
  end

  local result = {}
  for k, v in pairs(values) do
    result[Private.GetProgressValueConstant(k)] = v
  end

  return result
end


function Private.GetOverlayInfo(data, triggernum)
  local overlayInfo;
  if (data.controlledChildren) then
    overlayInfo = {};
    for child in Private.TraverseLeafs(data) do
      local tmp = wrappedGetOverlayInfo(child, triggernum);
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

function Private.GetTriggerConditions(data)
  local conditions = {};
  for i = 1, #data.triggers do
    local triggerSystem = GetTriggerSystem(data, i);
    if (triggerSystem) then
      conditions[i] = triggerSystem.GetTriggerConditions(data, i);
      conditions[i] = conditions[i] or {};
      conditions[i].show = {
        display = L["Active"],
        type = "bool",
        test = function(state, needle)
          return (state and state.id and triggerState[state.id].triggers[i] or false) == (needle == 1);
        end
      }
      conditions[i].activationTime = {
        display = L["Since Active"],
        type = "elapsedTimer",
        operator_types = "without_equal",

        test = function(state, needle, op)
          if state and state.id and triggerState[state.id] and triggerState[state.id].activationTime[i] then
            local activationTime = triggerState[state.id].activationTime[i]
            return (GetTime() <= activationTime + needle) == (op == "<=")
          end
        end,
        recheckTime = function(state, needle)
          if state and state.id and triggerState[state.id] and triggerState[state.id].activationTime[i] then
            return triggerState[state.id].activationTime[i] + needle
          end
        end,

      }
    end
  end
  return conditions;
end

local function CreateFallbackState(id, triggernum)
  fallbacksStates[id] = fallbacksStates[id] or {};
  fallbacksStates[id][triggernum] = fallbacksStates[id][triggernum] or {};

  local states = fallbacksStates[id][triggernum];
  states[""] = states[""] or {};
  local state = states[""];

  local data = db.displays[id];
  local triggerSystem = GetTriggerSystem(data, triggernum);
  if (triggerSystem) then
    triggerSystem.CreateFallbackState(data, triggernum, state)
    state.id = id
    state.trigger = data.triggers[triggernum].trigger
    state.triggernum = triggernum
  else
    state.show = true;
    state.changed = true;
    state.progressType = "timed";
    state.duration = 0;
    state.expirationTime = math.huge;
  end

  state.id = id

  return states;
end

local currentTooltipRegion;
local currentTooltipOwner;
local function UpdateMouseoverTooltip(region)
  if(region == currentTooltipRegion) then
    Private.ShowMouseoverTooltip(currentTooltipRegion, currentTooltipOwner);
  end
end

function Private.ShowMouseoverTooltip(region, owner)
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

  if (triggerSystem.SetToolTip(region.state.trigger, region.state)) then
    GameTooltip:Show();
  else
    GameTooltip:Hide();
  end
end

function Private.HideTooltip()
  currentTooltipRegion = nil;
  currentTooltipOwner = nil;
  -- If a tooltip was shown for a "restricted" frame, that is e.g. for a aura
  -- anchored to a nameplate, then that frame is no longer clamped to the screen,
  -- because restricted frames can't be clamped. So dance to make the tooltip
  -- unrestricted and then clamp it again.
  GameTooltip:ClearAllPoints()
  GameTooltip:SetPoint("RIGHT", UIParent, "LEFT");
  GameTooltip:SetClampedToScreen(true)

  GameTooltip:Hide()
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

function WeakAuras.GetAuraInstanceTooltipInfo(unit, auraInstanceId, filter)
  if WeakAuras.IsRetail() then
    local tooltipText = ""
    local tooltipData
    if filter == "HELPFUL" then
      tooltipData = C_TooltipInfo.GetUnitBuffByAuraInstanceID(unit, auraInstanceId, filter)
    else
      tooltipData = C_TooltipInfo.GetUnitDebuffByAuraInstanceID(unit, auraInstanceId, filter)
    end
    if not tooltipData then
      return nil, "", "none", 0
    end
    local secondLine = tooltipData.lines[2] -- This is the line we want
    if secondLine and secondLine.leftText then
      tooltipText = secondLine.leftText
    end
    return tooltipData.dataInstanceID, Private.ParseTooltipText(tooltipText)
  end
end

function Private.ParseTooltipText(tooltipText)
  local debuffType = "none";
  local tooltipSize = {};
  if(tooltipText) then
    for t in tooltipText:gmatch("(-?%d[%d%.,]*)") do
      if (LARGE_NUMBER_SEPERATOR == ",") then
        t = t:gsub(",", "");
      else
        t = t:gsub("%.", "");
        t = t:gsub(",", ".");
      end
      tinsert(tooltipSize, tonumber(t));
    end
  end

  if (#tooltipSize) then
    return tooltipText, debuffType, unpack(tooltipSize);
  else
    return tooltipText, debuffType, 0;
  end
end

function WeakAuras.GetAuraTooltipInfo(unit, index, filter)
  local tooltipText = ""
  if WeakAuras.IsRetail() then
    local tooltipData = C_TooltipInfo.GetUnitAura(unit, index, filter)
    local secondLine = tooltipData and tooltipData.lines[2] -- This is the line we want
    if secondLine and secondLine.leftText then
      tooltipText = secondLine.leftText
    end
  else
    local tooltip = WeakAuras.GetHiddenTooltip();
    tooltip:ClearLines();
    tooltip:SetUnitAura(unit, index, filter);
    local tooltipTextLine = select(5, tooltip:GetRegions())
    tooltipText = tooltipTextLine and tooltipTextLine:GetObjectType() == "FontString" and tooltipTextLine:GetText() or "";
  end

  return Private.ParseTooltipText(tooltipText)
end

local FrameTimes = {};
function WeakAuras.ProfileFrames(all)
  UpdateAddOnCPUUsage();
  for name, frame in pairs(Private.frames) do
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
  for id, regionData in pairs(Private.regions) do
    if regionData.region then
      local DisplayTime = GetFrameCPUUsage(regionData.region, true);
      DisplayTimes[id] = DisplayTimes[id] or 0;
      if(all or DisplayTime > DisplayTimes[id]) then
        print("|cFFFF0000"..id.."|r -", DisplayTime, "-", DisplayTime - DisplayTimes[id]);
      end
      DisplayTimes[id] = DisplayTime;
    end
  end
end

function Private.ValueFromPath(data, path)
  if not data then
    return nil
  end
  if (#path == 0) then
    return data
  elseif(#path == 1) then
    return data[path[1]];
  else
    local reducedPath = {};
    for i=2,#path do
      reducedPath[i-1] = path[i];
    end
    return Private.ValueFromPath(data[path[1]], reducedPath);
  end
end

function Private.ValueToPath(data, path, value)
  if not data then
    return
  end
  if(#path == 1) then
    data[path[1]] = value;
  else
    local reducedPath = {};
    for i=2,#path do
      reducedPath[i-1] = path[i];
    end
    Private.ValueToPath(data[path[1]], reducedPath, value);
  end
end

Private.frameLevels = {};
local function SetFrameLevel(id, frameLevel)
  if (Private.frameLevels[id] == frameLevel) then
    return;
  end
  if (Private.regions[id] and Private.regions[id].region) then
    Private.ApplyFrameLevel(Private.regions[id].region, frameLevel)
  end
  if (clones[id]) then
    for i,v in pairs(clones[id]) do
      Private.ApplyFrameLevel(v, frameLevel)
    end
  end
  Private.frameLevels[id] = frameLevel;
end

local function FixGroupChildrenOrderImpl(data, frameLevel)
  SetFrameLevel(data.id, frameLevel)
  local offset
  if data.sharedFrameLevel then
    offset = 0
  else
    offset = 4
  end
  for _, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId)
    if childData.regionType ~= "group" and childData.regionType ~= "dynamicgroup" then
      frameLevel = frameLevel + offset
      SetFrameLevel(childId, frameLevel)
    else
      frameLevel = frameLevel + offset
      local endFrameLevel = FixGroupChildrenOrderImpl(childData, frameLevel)
      if not data.sharedFrameLevel then
        frameLevel = endFrameLevel
      end
    end
  end
  return frameLevel
end

function Private.FixGroupChildrenOrderForGroup(data)
  if data.parent then
    return
  end
  FixGroupChildrenOrderImpl(data, 0)
end

local function GetFrameLevelFor(id)
  return Private.frameLevels[id] or 5;
end

function Private.ApplyFrameLevel(region, frameLevel)
  frameLevel = frameLevel or GetFrameLevelFor(region.id)

  local setBackgroundFrameLevel = false
  if region.subRegions then
    for index, subRegion in pairs(region.subRegions) do
      if subRegion.type == "subbackground" then
        subRegion:SetFrameLevel(frameLevel + index)
        setBackgroundFrameLevel = true
      end
    end

    if not setBackgroundFrameLevel then
      region:SetFrameLevel(frameLevel)
    end

    for index, subRegion in pairs(region.subRegions) do
      if subRegion.type ~= "subbackground" then
        subRegion:SetFrameLevel(frameLevel + index)
      end
    end
  else
    region:SetFrameLevel(frameLevel)
  end
end

function WeakAuras.EnsureString(input)
  if (input == nil) then
    return "";
  end
  return tostring(input);
end

-- Handle coroutines
---@alias threadPriority 'urgent' | 'normal' | 'background' | 'instant'
---@alias threadPool table<string, threadData>
---@class threadData
---@field thread thread
---@field sequence table<string, number> to help debug problems in threads
---@class Threads
---@field pools table<threadPriority, threadPool>
local threads = {
  frame = CreateFrame("Frame"),
  size = 0,
  ---@type table<string, threadPriority>
  prios = {},
  pools = {
    urgent = {},
    normal = {},
    background = {},
    instant = {},
  },
};
do

  ---@type table<threadPriority, true>
  local validPriorities = {
    urgent = true,
    normal = true,
    background = true,
    instant = true,
  }

  -- Add an action to be resumed via OnUpdate
  ---@param name string
  ---@param thread thread | function
  ---@param prio threadPriority?
  function threads:Add(name, thread, prio)
    if not prio or not validPriorities[prio] then
      prio = "normal"
    end
    if type(thread) == "function" then
      thread = coroutine.create(thread)
    end
    if not self.prios[name] then
      self.prios[name] = prio
      self.pools[prio][name] = {
        thread = thread,
        sequence = {}
      }
      self.size = self.size + 1
      self.frame:Show()
    end
  end

  ---@param name string
  ---@param prio threadPriority
  function threads:SetPriority(name, prio)
    local oldPrio = self.prios[name]
    if oldPrio and oldPrio ~= prio then
      self.pools[prio][name] = self.pools[oldPrio][name]
      self.pools[oldPrio][name] = nil
      self.prios[name] = prio
    end
  end

  -- Remove an action from OnUpdate
  ---@param name string
  function threads:Remove(name)
    local prio = self.prios[name]
    if prio then
      local pool = self.pools[prio]
      pool[name] = nil
      self.prios[name] = nil
      self.size = self.size - 1
      if self.size == 0 then
        self.frame:Hide()
      end
    end
  end


  ---@param pool threadPool
  ---@param finish number
  ---@param defaultEstimate number
  local function runThreadPool(pool, finish, defaultEstimate)
    local start = debugprofilestop()
    if finish <= start then return end
    local estimates = {}
    local ok, val1, val2
    local continue = false
    repeat
      continue = false
      for name, threadData in pairs(pool) do
        local estimate = estimates[name] or defaultEstimate
        if debugprofilestop() + estimate > finish then
          break
        else
          continue = true
          ok, val1, val2 = coroutine.resume(threadData.thread)
          if not ok then
            geterrorhandler()(val1 .. '\n' .. debugstack(threadData.thread))
          end
          if coroutine.status(threadData.thread) ~= "dead" then
            estimates[name] = type(val1) == "number" and val1 or defaultEstimate
            local sequence = val2 or "" --[[@as string]]
            threadData.sequence[sequence] = (threadData.sequence[sequence] or 0) + 1
          else
            threads:Remove(name)
          end
        end
      end
    until not continue
  end


  ---@param name string
  ---@param func thread
  ---@param limit number
  ---@param defaultEstimate number?
  function threads:Immediate(name, func, limit, defaultEstimate)
    self:Add(name, func, "instant")
    runThreadPool(self.pools.instant, debugprofilestop() + limit, defaultEstimate or 1000)
    if coroutine.status(func) ~= "dead" then
      self:SetPriority(name, "urgent")
    else
      self:Remove(name)
    end
  end

  -- Setup frame
  threads.frame:Hide();
  threads.frame:SetScript("OnUpdate", function()
    local start = debugprofilestop();
    runThreadPool(threads.pools.urgent, start + 15000, 1000)
    runThreadPool(threads.pools.normal, start + 20, 1)
    runThreadPool(threads.pools.background, start + 2, 0.5)
  end);
  threads.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  threads.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  threads.frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" and self:IsShown() then
      self:Hide()
    elseif event == "PLAYER_REGEN_DISABLED" and not self:IsShown() and threads.size > 0 then
      self:Show()
    end
  end)
end

Private.Threads = threads;

function WeakAuras.RegisterTriggerSystem(types, triggerSystem)
  for _, v in ipairs(types) do
    triggerTypes[v] = triggerSystem;
  end
  tinsert(triggerSystems, triggerSystem);
end

function WeakAuras.RegisterTriggerSystemOptions(types, func)
  for _, v in ipairs(types) do
    Private.triggerTypesOptions[v] = func;
  end
end

function WeakAuras.GetTriggerStateForTrigger(id, triggernum)
  if (triggernum == -1) then
    return Private.GetGlobalConditionState();
  end
  if triggerState[id][triggernum] == nil then
    triggerState[id][triggernum] = setmetatable({}, Private.allstatesMetatable)
  end
  return triggerState[id][triggernum];
end

function WeakAuras.GetActiveStates(id)
  return triggerState[id].activeStates
end

function WeakAuras.GetActiveTriggers(id)
  return triggerState[id].triggers
end

do
  --- @type table<auraId, boolean>
  local visibleFakeStates = {}

  --- @type fun(_: any, uid: uid, id: auraId)
  local function OnDelete(_, uid, id)
    visibleFakeStates[id] = nil
  end

  --- @type fun(_: any, uid: uid, oldId: auraId, newId: auraId)
  local function OnRename(_, uid, oldId, newId)
    visibleFakeStates[newId] = visibleFakeStates[oldId]
    visibleFakeStates[oldId] = nil
  end

  Private.callbacks:RegisterCallback("Delete", OnDelete)
  Private.callbacks:RegisterCallback("Rename", OnRename)

  local UpdateFakeTimesHandle

  local function UpdateFakeTimers()
    local suspended = Private.PauseAllDynamicGroups()
    local t = GetTime()
    for id, triggers in pairs(triggerState) do
      local changed = false
      for triggernum, triggerData in ipairs(triggers) do
        for id, state in pairs(triggerData) do
          if state.progressType == "timed" then
            local expirationTime = state.expirationTime
            local duration = state.duration
            if expirationTime and type(expirationTime) == "number" and expirationTime < t
               and duration and type(duration) == "number" and duration > 0
            then
              state.expirationTime = t + state.duration
              state.changed = true
              changed = true
            end
          end
        end
      end
      if changed then
        Private.UpdatedTriggerState(id)
      end
    end
    Private.ResumeAllDynamicGroups(suspended)
  end

  function Private.SetFakeStates()
    if UpdateFakeTimesHandle then
      return
    end

    for id, states in pairs(triggerState) do
      local changed
      for triggernum in ipairs(states) do
        changed = Private.SetAllStatesHidden(id, triggernum) or changed
      end
      if changed then
        Private.UpdatedTriggerState(id)
      end
    end
    UpdateFakeTimesHandle = timer:ScheduleRepeatingTimer(UpdateFakeTimers, 1)
  end

  function Private.ClearFakeStates()
    timer:CancelTimer(UpdateFakeTimesHandle)
    for id in pairs(triggerState) do
      Private.FakeStatesFor(id, false)
    end
  end

  function Private.FakeStatesFor(id, visible)
    if visibleFakeStates[id] == visible then
      return visibleFakeStates[id]
    end
    if visible then
      visibleFakeStates[id] = true
      Private.UpdateFakeStatesFor(id)
    else
      visibleFakeStates[id] = false
      if triggerState[id] then
        local changed = false
        for triggernum in ipairs(triggerState[id]) do
          changed = Private.SetAllStatesHidden(id, triggernum) or changed
        end
        if changed then
          Private.UpdatedTriggerState(id)
        end
      end
    end
    return not visibleFakeStates[id]
  end

  function Private.UpdateFakeStatesFor(id)
    if (WeakAuras.IsOptionsOpen() and visibleFakeStates[id]) then
      local data = WeakAuras.GetData(id)
      if (data) then
        for triggernum in ipairs(data.triggers) do
          Private.SetAllStatesHidden(id, triggernum)
          local triggerSystem = GetTriggerSystem(data, triggernum)
          if triggerSystem and triggerSystem.CreateFakeStates then
            triggerSystem.CreateFakeStates(id, triggernum)
          end
        end
        Private.UpdatedTriggerState(id)
        if WeakAuras.GetMoverSizerId() == id then
          WeakAuras.SetMoverSizer(id)
        end
      end
    end
  end
end

--- @type fun(id: auraId, triggernum: integer, cloneId: string)
local function stopAutoHideTimer(id, triggernum, cloneId)
  if(timers[id] and timers[id][triggernum] and timers[id][triggernum][cloneId]) then
    local record = timers[id][triggernum][cloneId];
    if (record.handle) then
      timer:CancelTimer(record.handle);
    end
    record.handle = nil;
    record.expirationTime = nil;
    record.state = nil
  end
end

--- @type fun(id: auraId, triggernum: integer, cloneId: string, state: state)
local function startStopTimers(id, cloneId, triggernum, state)
  if not state.show or not state.autoHide then
    stopAutoHideTimer(id, triggernum, cloneId)
    return
  end

  -- state.autoHide can be a timer, or a boolean
  -- if it's a bool, for backwards compability we look at paused
  local expirationTime
  if type(state.autoHide) == "boolean" then
    if state.paused then
      stopAutoHideTimer(id, triggernum, cloneId)
      return
    else
      if state.expirationTime == nil and type(state.duration) == "number" then
        -- Set the expiration time, because users rely on that, even though it's wrong to do
        state.expirationTime = GetTime() + state.duration
      end
      expirationTime = state.expirationTime
    end
  elseif type(state.autoHide) == "number" then
    expirationTime = state.autoHide
  end

  timers[id] = timers[id] or {};
  timers[id][triggernum] = timers[id][triggernum] or {};
  timers[id][triggernum][cloneId] = timers[id][triggernum][cloneId] or {};
  local record = timers[id][triggernum][cloneId];
  if (record.expirationTime ~= expirationTime or record.state ~= state) then
    if (record.handle ~= nil) then
      timer:CancelTimer(record.handle);
    end

    if expirationTime and type(expirationTime) == "number" then
      record.handle = timer:ScheduleTimerFixed(
        function()
          if (state.show ~= false and state.show ~= nil) then
            state.show = false;
            state.changed = true;

            -- if the trigger has updated then check to see if it is flagged for WatchedTrigger and send to queue if it is
            if Private.watched_trigger_events[id] and Private.watched_trigger_events[id][triggernum] then
              Private.AddToWatchedTriggerDelay(id, triggernum)
            end
            Private.UpdatedTriggerState(id);
          end
        end,
        expirationTime - GetTime());
      record.expirationTime = expirationTime;
      record.state = state
    end
  end
end

local function ApplyStateToRegion(id, cloneId, region, parent)
  -- Force custom text function to be run again
  region.values.customTextUpdated = false
  region:Update();

  region.subRegionEvents:Notify("Update", region.state, region.states)

  UpdateMouseoverTooltip(region);
  region:Expand();
  if parent and parent.ActivateChild then
    parent:ActivateChild(id, cloneId)
  end
end

-- Fallbacks if the states are empty
local emptyState = {};
emptyState[""] = {};

local function applyToTriggerStateTriggers(stateShown, id, triggernum)
  if (stateShown and not triggerState[id].triggers[triggernum]) then
    triggerState[id].triggers[triggernum] = true;
    triggerState[id].triggerCount = triggerState[id].triggerCount + 1;
    triggerState[id].activationTime[triggernum] = GetTime()
    return true;
  elseif (not stateShown and triggerState[id].triggers[triggernum]) then
    triggerState[id].triggers[triggernum] = false;
    triggerState[id].triggerCount = triggerState[id].triggerCount - 1;
    triggerState[id].activationTime[triggernum] = nil
    return true;
  end

  return false;
end

local function evaluateTriggerStateTriggers(id)
  local result = false;

  if WeakAuras.IsOptionsOpen() then
    -- While the options are open ignore the combination function
    return triggerState[id].triggerCount > 0
  end

  if (triggerState[id].disjunctive == "any" and triggerState[id].triggerCount > 0) then
    result = true;
  elseif(triggerState[id].disjunctive == "all" and triggerState[id].triggerCount == triggerState[id].numTriggers) then
    result = true;
  else
    if (triggerState[id].disjunctive == "custom" and triggerState[id].triggerLogicFunc) then
      Private.ActivateAuraEnvironment(id)
      local ok, returnValue = xpcall(triggerState[id].triggerLogicFunc, Private.GetErrorHandlerId(id, L["Custom Trigger Combination"]), triggerState[id].triggers);
      Private.ActivateAuraEnvironment()
      result = ok and returnValue;
    end
  end

  return result;
end

local function ApplyStatesToRegions(id, activeTrigger, states)
  -- Show new clones
  local data = WeakAuras.GetData(id)
  local parent
  if data and data.parent then
    parent = Private.EnsureRegion(data.parent)
  end
  if parent and parent.Suspend then
    parent:Suspend()
  end
  for cloneId, state in pairs(states) do
    if (state.show) then
      local region = Private.EnsureRegion(id, cloneId);
      local applyChanges = not region.toShow or state.changed or region.state ~= state
      region.state = state
      region.states = region.states or {}
      for triggernum = -1, triggerState[id].numTriggers do
        local triggerState
        if triggernum == activeTrigger then
          triggerState = state
        else
          local triggerStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum)
          triggerState = triggerStates[cloneId] or triggerStates[""] or {}
        end
        if triggernum > 0 then
          applyChanges = applyChanges or region.states[triggernum] ~= triggerState or (triggerState and triggerState.changed)
                       or region.states[triggernum] ~= triggerState
                       or (triggerState and triggerState.changed)
        end

        region.states[triggernum] = triggerState
      end

      if (applyChanges) then
        ApplyStateToRegion(id, cloneId, region, parent);
        Private.RunConditions(region, data.uid, not state.show)
      end
    end
  end
  if parent and parent.Resume then
    parent:Resume()
  end
end

-- handle trigger updates that have been requested to be sent into custom
-- we need the id and triggernum that's changing, but can't send the ScanEvents to the custom trigger until after UpdatedTriggerState has fired
local delayed_watched_trigger = {}
function Private.AddToWatchedTriggerDelay(id, triggernum)
  delayed_watched_trigger[id] = delayed_watched_trigger[id] or {}
  tinsert(delayed_watched_trigger[id], triggernum)
end

Private.callbacks:RegisterCallback("Delete", function(_, uid, id)
  delayed_watched_trigger[id] = nil
end)

Private.callbacks:RegisterCallback("Rename", function(_, uid, oldId, newId)
  delayed_watched_trigger[newId] = delayed_watched_trigger[oldId]
  delayed_watched_trigger[oldId] = nil
end)

function Private.SendDelayedWatchedTriggers()
  if WeakAuras.IsOptionsOpen() then
    return
  end
  for id in pairs(delayed_watched_trigger) do
    local watched = delayed_watched_trigger[id]
    -- Since the observers are themselves observable, we set the list of observers to
    -- empty here.
    delayed_watched_trigger[id] = {}
    Private.ScanEventsWatchedTrigger(id, watched)
  end
end

function Private.UpdatedTriggerState(id)
  if (not triggerState[id]) then
    return;
  end

  local changed = false;
  for triggernum = 1, triggerState[id].numTriggers do
    triggerState[id][triggernum] = triggerState[id][triggernum] or setmetatable({}, Private.allstatesMetatable)

    local anyStateShown = false;

    for cloneId, state in pairs(triggerState[id][triggernum]) do
      state.trigger = db.displays[id].triggers[triggernum] and db.displays[id].triggers[triggernum].trigger;
      state.triggernum = triggernum;
      state.id = id;

      if (state.changed) then
        startStopTimers(id, cloneId, triggernum, state);
      end
      anyStateShown = anyStateShown or state.show;
    end
    -- Update triggerState.triggers
    changed = applyToTriggerStateTriggers(anyStateShown, id, triggernum) or changed;
  end

  -- Figure out whether we should be shown or not
  local show = triggerState[id].show;

  if (changed or show == nil) then
    show = evaluateTriggerStateTriggers(id);
  end

  -- Figure out which subtrigger is active, and if it changed
  local newActiveTrigger = triggerState[id].activeTriggerMode;
  if (newActiveTrigger == Private.trigger_modes.first_active) then
    -- Mode is first active trigger, so find a active trigger
    for i = 1, triggerState[id].numTriggers do
      if (triggerState[id].triggers[i]) then
        newActiveTrigger = i;
        break;
      end
    end
  end

  local oldShow = triggerState[id].show;
  triggerState[id].show = show;
  triggerState[id].fallbackStates = nil

  local activeTriggerState = WeakAuras.GetTriggerStateForTrigger(id, newActiveTrigger);
  if (not next(activeTriggerState)) then
    if (show) then
      activeTriggerState = CreateFallbackState(id, newActiveTrigger)
    else
      activeTriggerState = emptyState;
    end
  elseif (show) then
    local needsFallback = true;
    for _, state in pairs(activeTriggerState) do
      if (state.show) then
        needsFallback = false;
        break;
      end
    end
    if (needsFallback) then
      activeTriggerState = CreateFallbackState(id, newActiveTrigger)
    end
  end
  triggerState[id].activeStates = activeTriggerState

  local region;
  -- Now apply
  if (show and not oldShow) then -- Hide => Show
    ApplyStatesToRegions(id, newActiveTrigger, activeTriggerState);
  elseif (not show and oldShow) then -- Show => Hide
    for _, clone in pairs(clones[id]) do
      clone:Collapse()
    end
    if Private.regions[id] and Private.regions[id].region then
      Private.regions[id].region:Collapse()
    end
  elseif (show and oldShow) then -- Already shown, update regions
    -- Hide old clones
    for cloneId, clone in pairs(clones[id]) do
      if (not activeTriggerState[cloneId] or not activeTriggerState[cloneId].show) then
        clone:Collapse()
      end
    end
    if (not activeTriggerState[""] or not activeTriggerState[""].show) then
      if Private.regions[id] and Private.regions[id].region then
        Private.regions[id].region:Collapse()
      end
    end
    -- Show new states
    ApplyStatesToRegions(id, newActiveTrigger, activeTriggerState);
  end

  for triggernum = 1, triggerState[id].numTriggers do
    for cloneId, state in pairs(triggerState[id][triggernum]) do
      if (not state.show) then
        triggerState[id][triggernum][cloneId] = nil;
      end
      state.changed = false;
    end
  end
  -- once updatedTriggerStates is complete, and empty states removed, etc., then check for queued watched triggers update
  Private.SendDelayedWatchedTriggers()
end

function Private.RunCustomTextFunc(region, customFunc)

  if not customFunc then
    return nil
  end

  local state = region.state

  Private.ActivateAuraEnvironment(region.id, region.cloneId, region.state, region.states);

  local progress = Private.dynamic_texts.p.func(Private.dynamic_texts.p.get(state), state, 1)
  local dur = Private.dynamic_texts.t.func(Private.dynamic_texts.t.get(state), state, 1)
  local name = Private.dynamic_texts.n.func(Private.dynamic_texts.n.get(state))
  local icon = Private.dynamic_texts.i.func(Private.dynamic_texts.i.get(state))
  local stacks = Private.dynamic_texts.s.func(Private.dynamic_texts.s.get(state))
  local expirationTime
  local duration

  if state then
    if state.progressType == "timed" then
      expirationTime = state.expirationTime
      duration = state.duration
    else
      expirationTime = state.total
      duration = state.value
    end
  end

  local custom = {select(2, xpcall(customFunc, Private.GetErrorHandlerId(region.id, L["Custom Text Function"]), expirationTime or math.huge, duration or 0, progress, dur, name, icon, stacks))}
  Private.ActivateAuraEnvironment(nil)

  return custom
end

local function ReplaceValuePlaceHolders(textStr, region, customFunc, state, formatter, trigger)
  local value;
  if string.sub(textStr, 1, 1) == "c" then
    local custom
    if customFunc then
      custom = Private.RunCustomTextFunc(region, customFunc)
    else
      custom = region.values.custom
    end

    local index = tonumber(textStr:match("^c(%d+)$") or 1)

    if custom then
      value = custom[index]
    end

    if value == nil then value = "" end

    if formatter then
      value = formatter(value, state)
    end

    if custom then
      value = WeakAuras.EnsureString(value)
    end
  else
    local variable = Private.dynamic_texts[textStr];
    if (not variable) then
      return nil;
    end
    value = variable.get(state)
    if formatter then
      value = formatter(value, state, trigger)
    elseif variable.func then
      value = variable.func(value)
    end
  end

  return type(value) ~= "table" and value or ""
end

-- States:
-- 0 Normal state, text is just appended to result. Can transition to percent start state 1 via %
-- 1 Percent start state, entered via %. Can transition to via { to braced, via % to normal, AZaz09 to percent rest state
-- 2 Percent rest state, stay in it via AZaz09, transition to normal on anything else
-- 3 Braced state, } transitions to normal, everything else stay in braced state
local function nextState(char, state)
  if state == 0 then -- Normal State
    if char == 37 then -- % sign
      return 1 -- Enter Percent state
    end
    return 0
  elseif state == 1 then -- Percent Start State
    if char == 37 then -- % sign
      return 0 -- Return to normal state
    elseif char == 123 then -- { sign
      return 3 -- Enter Braced state
    elseif (char >= 48 and char <= 57) or (char >= 65 and char <= 90) or (char >= 97 and char <= 122) or char == 46 then
        -- 0-9a-zA-Z or dot character
      return 2 -- Enter Percent rest state
    end
    return 0 -- % followed by non alpha-numeric. Back to normal state
  elseif state == 2 then
    if (char >= 48 and char <= 57) or (char >= 65 and char <= 90) or (char >= 97 and char <= 122) or char == 46 then
      return 2 -- Continue in same state
    end
    if char == 37 then
      return 1 -- End of %, but also start of new %
    end
    return 0 -- Back to normal
  elseif state == 3 then
    if char == 125 then -- } closing brace
      return 0 -- Back to normal
    end
    return 3
  end
  -- Shouldn't happen
  return state
end

local function ContainsPlaceHolders(textStr, symbolFunc, checkDoublePercent)
  if not textStr then
    return false
  end

  local endPos = textStr:len();
  local state = 0
  local currentPos = 1
  local start = 1
  local containsDoublePercent = false
  while currentPos <= endPos do
    local char = string.byte(textStr, currentPos);
    local nextState = nextState(char, state)

    if state == 1 then -- Last char was a %
      if char == 123 then -- {
        start = currentPos + 1
      elseif char == 37 then -- %
        containsDoublePercent = true
        start = currentPos
      else
        start = currentPos
      end
    elseif state == 2 or state == 3 then
      if nextState == 0 or nextState == 1 then
        local symbol = string.sub(textStr, start, currentPos - 1)
        if symbolFunc(symbol) then
          return true
        end
      end
    end

    state = nextState
    currentPos = currentPos + 1
  end

  if state == 2 then
    local symbol = string.sub(textStr, start, currentPos - 1)
    if symbolFunc(symbol) then
      return true
    end
  end

  if checkDoublePercent then
    return containsDoublePercent
  end
  return false
end

function Private.ContainsCustomPlaceHolder(textStr)
  return ContainsPlaceHolders(textStr, function(symbol)
    return string.match(symbol, "^c%d*$")
  end)
end

function Private.ContainsPlaceHolders(textStr, toCheck)
  return ContainsPlaceHolders(textStr, function(symbol)
    if symbol:len() == 1 and toCheck:find(symbol, 1, true) then
     return true
    end

   local _, last = symbol:find("^%d+%.")
   if not last then
     return false
   end

   symbol = symbol:sub(last + 1)
   if symbol:len() == 1 and toCheck:find(symbol, 1, true) then
     return true
   end
  end)
end

function Private.ContainsAnyPlaceHolders(textStr)
  return ContainsPlaceHolders(textStr, function(symbol) return true end, true)
end

Private.ContainsPlaceHoldersPredicate = ContainsPlaceHolders

local function ValueForSymbol(symbol, region, customFunc, regionState, regionStates, useHiddenStates, formatters)
  local triggerNum, sym = string.match(symbol, "(.+)%.(.+)")
  triggerNum = triggerNum and tonumber(triggerNum)
  if triggerNum and sym then
    if regionStates[triggerNum] then
      if (useHiddenStates or regionStates[triggerNum].show) then
        if regionStates[triggerNum][sym] then
          local value = regionStates[triggerNum][sym]
          if formatters[symbol] then
            return tostring(formatters[symbol](value, regionStates[triggerNum], triggerNum) or "") or ""
          else
            return tostring(value) or ""
          end
        else
          local value = ReplaceValuePlaceHolders(sym, region, customFunc, regionStates[triggerNum], formatters[symbol], triggerNum);
          return value or ""
        end
      end
    end
    return ""
  elseif regionState[symbol] then
    if(useHiddenStates or regionState.show) then
      local value = regionState[symbol]
      if formatters[symbol] then
        return tostring(formatters[symbol](value, regionState, regionState.triggernum) or "") or ""
      else
        return tostring(value) or ""
      end
    end
    return ""
  else
    local value = (useHiddenStates or regionState.show)
                  and ReplaceValuePlaceHolders(symbol, region, customFunc, regionState, formatters[symbol], regionState.triggernum)
    return value or ""
  end
end

function Private.ReplacePlaceHolders(textStr, region, customFunc, useHiddenStates, formatters)
  local regionValues = region.values;
  local regionState = region.state or {};
  local regionStates = region.states or {};
  if (not regionState and not regionValues) then
    return ""
  end
  local endPos = textStr:len();
  if (endPos < 2) then
    textStr = textStr:gsub("\\n", "\n");
    return textStr;
  end

  if (endPos == 2) then
    if string.byte(textStr, 1) == 37 then
      local symbol = string.sub(textStr, 2)
      if symbol == "%" then
        return "%" -- Double % input
      end
      local value = ValueForSymbol(symbol, region, customFunc, regionState, regionStates, useHiddenStates, formatters);
      if (value) then
        textStr = tostring(value);
      end
    end
    textStr = textStr:gsub("\\n", "\n");
    return textStr;
  end

  local result = ""
  local currentPos = 1 -- Position of the "cursor"
  local state = 0
  local start = 1 -- Start of whatever "word" we are currently considering, doesn't include % or {} symbols

  while currentPos <= endPos do
    local char = string.byte(textStr, currentPos);
    if state == 0 then -- Normal State
      if char == 37 then -- % sign
        if currentPos > start then
          result = result .. string.sub(textStr, start, currentPos - 1)
        end
      end
    elseif state == 1 then -- Percent Start State
      if char == 123 then -- { sign
        start = currentPos + 1
      else
        start = currentPos
      end
    elseif state == 2 then -- Percent Rest State
      if (char >= 48 and char <= 57) or (char >= 65 and char <= 90) or (char >= 97 and char <= 122) or char == 46 then
        -- 0-9a-zA-Z or dot character
      else -- End of variable
        local symbol = string.sub(textStr, start, currentPos - 1)
        result = result .. ValueForSymbol(symbol, region, customFunc, regionState, regionStates, useHiddenStates, formatters)

        if char == 37 then
          -- Do nothing
        else
          start = currentPos
        end
      end
    elseif state == 3 then
      if char == 125 then -- } closing brace
        local symbol = string.sub(textStr, start, currentPos - 1)
        result = result .. ValueForSymbol(symbol, region, customFunc, regionState, regionStates, useHiddenStates, formatters)
        start = currentPos + 1
      end
    end
    state = nextState(char, state)
    currentPos = currentPos + 1
  end

  if state == 0 and currentPos > start then
    result = result .. string.sub(textStr, start, currentPos - 1)
  elseif state == 2 and currentPos > start then
    local symbol = string.sub(textStr, start, currentPos - 1)
    result = result .. ValueForSymbol(symbol, region, customFunc, regionState, regionStates, useHiddenStates, formatters)
  elseif state == 1 then
    result = result .. "%"
  end

  textStr = result:gsub("\\n", "\n");
  return textStr;
end

function Private.ParseTextStr(textStr, symbolCallback)
  if not textStr then
    return
  end
  local endPos = textStr:len();
  local currentPos = 1 -- Position of the "cursor"
  local state = 0
  local start = 1 -- Start of whatever "word" we are currently considering, doesn't include % or {} symbols

  while currentPos <= endPos do
    local char = string.byte(textStr, currentPos);
    if state == 0 then -- Normal State
    elseif state == 1 then -- Percent Start State
      if char == 123 then
        start = currentPos + 1
      else
        start = currentPos
      end
    elseif state == 2 then -- Percent Rest State
      if (char >= 48 and char <= 57) or (char >= 65 and char <= 90) or (char >= 97 and char <= 122) or char == 46 then
        -- 0-9a-zA-Z or dot character
      else -- End of variable
        local symbol = string.sub(textStr, start, currentPos - 1)
        symbolCallback(symbol)
        if char == 37 then
          -- Do nothing
        else
          start = currentPos
        end
      end
    elseif state == 3 then
      if char == 125 then -- } closing brace
        local symbol = string.sub(textStr, start, currentPos - 1)
        symbolCallback(symbol)
        start = currentPos + 1
      end
    end
    state = nextState(char, state)
    currentPos = currentPos + 1
  end

  if state == 2 and currentPos > start then
    local symbol = string.sub(textStr, start, currentPos - 1)
    symbolCallback(symbol)
  end
end

function Private.SetDefaultFormatters(data, input, keyPrefix, metaData)
  local seenSymbols = {}
  local setDefaultFormatters = function(symbol)
    if not data[keyPrefix .. symbol .. "_format"] and not seenSymbols[symbol] then
      local trigger, sym = string.match(symbol, "(.+)%.(.+)")
      sym = sym or symbol

      local formatter, args = Private.DefaultFormatterFor(metaData, trigger, sym)
      data[keyPrefix .. symbol .. "_format"] = formatter
      for arg, value in pairs(args or {}) do
        data[keyPrefix .. symbol .. "_" .. arg] = value
      end
    end
    seenSymbols[symbol] = true
  end
  Private.ParseTextStr(input, setDefaultFormatters)
end

function Private.DefaultFormatterFor(stateMetaData, trigger, sym)
  local formatter
  local args = {}
  if sym == "p" or sym == "t" then
    return "timed", { time_dynamic_threshold = 3 }
  end

  trigger = tonumber(trigger)
  if trigger then
    local metaData = stateMetaData[trigger] and stateMetaData[trigger][sym]
    if metaData then
      formatter = metaData.formatter
      if metaData.formatterArgs then
        for arg, value in pairs(metaData.formatterArgs) do
          args[arg] = value
        end
      end
    end
  else
    for index, perTriggerData in pairs(stateMetaData) do
      if perTriggerData[sym] then
        if not formatter then
          formatter = perTriggerData[sym].formatter
        else
          if formatter ~= perTriggerData[sym].formatter then
            return "none"
          end
        end
      end
    end
  end

  return formatter or "none", args
end

function Private.CreateFormatters(input, getter, withoutColor, data)
  local seenSymbols = {}
  local formatters = {}
  local everyFrameFormatters = {}

  local parseFn = function(symbol)
    if not seenSymbols[symbol] then
      local _, sym = string.match(symbol, "(.+)%.(.+)")
      sym = sym or symbol
      if sym == "i" then
        -- Do nothing
      else
        local default = (sym == "p" or sym == "t") and "timed" or "none"
        local selectedFormat = getter(symbol ..  "_format", default)
        if (Private.format_types[selectedFormat]) then
          formatters[symbol], everyFrameFormatters[symbol] = Private.format_types[selectedFormat].CreateFormatter(symbol, getter, withoutColor, data)
        end
      end
    end
    seenSymbols[symbol] = true
  end

  if type(input) == "string" then
    Private.ParseTextStr(input, parseFn)
  elseif type(input) == "table" then
    for _, v in ipairs(input) do
      Private.ParseTextStr(v, parseFn)
    end
  end

  return formatters, everyFrameFormatters
end

function Private.AnyEveryFrameFormatters(textStr, everyFrameFormatters)
  if next(everyFrameFormatters) then
    local function predicate(symbol)
      if everyFrameFormatters[symbol] then
        return true
      end
    end
    return Private.ContainsPlaceHoldersPredicate(textStr, predicate)
  end
end

function Private.IsAuraActive(uid)
  local id = Private.UIDtoID(uid)
  local active = triggerState[id];

  return active and active.show;
end

function WeakAuras.IsAuraActive(id)
  local active = triggerState[id]

  return active and active.show
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
  local optionsFrame = Private.OptionsFrame();
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
  ---@class Frame
  mouseFrame = CreateFrame("Frame", "WeakAurasAttachToMouseFrame", UIParent);
  mouseFrame.attachedVisibleFrames = {};
  mouseFrame:SetWidth(1);
  mouseFrame:SetHeight(1);

  local moverFrame = CreateFrame("Frame", "WeakAurasMousePointerFrame", mouseFrame);
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
      local optionsFrame = Private.OptionsFrame();
      local yOffset = (optionsFrame:GetTop() + optionsFrame:GetBottom()) / 2;
      local xOffset = xPositionNextToOptions();
      -- We use the top right, because the main frame uses the top right as the reference too
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

  Private.mouseFrame = mouseFrame;
end

local personalRessourceDisplayFrame;
function Private.ensurePRDFrame()
  if (personalRessourceDisplayFrame) then
    return;
  end
  personalRessourceDisplayFrame = CreateFrame("Frame", "WeakAurasAttachToPRD", UIParent);
  personalRessourceDisplayFrame:Hide();
  personalRessourceDisplayFrame.attachedVisibleFrames = {};
  -- force an early frame draw; otherwise this frame won't be drawn until the next frame,
  -- and any attached auras won't have a valid rect
  personalRessourceDisplayFrame:SetPoint("CENTER", UIParent, "CENTER");
  personalRessourceDisplayFrame:SetSize(16, 16)
  personalRessourceDisplayFrame:GetSize()
  Private.personalRessourceDisplayFrame = personalRessourceDisplayFrame;

  local moverFrame = CreateFrame("Frame", "WeakAurasPRDMoverFrame", personalRessourceDisplayFrame);
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
    self:Show()
  end

  personalRessourceDisplayFrame.Detach = function(self, frame)
    self:ClearAllPoints();
    self:Hide()
    self:SetParent(UIParent)
  end

  personalRessourceDisplayFrame.OptionsOpened = function()
    personalRessourceDisplayFrame:Detach();
    personalRessourceDisplayFrame:SetScript("OnEvent", nil);
    personalRessourceDisplayFrame:ClearAllPoints();
    personalRessourceDisplayFrame:Show()
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
      local optionsFrame = Private.OptionsFrame();
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
      if (Plater and frame.unitFrame.PlaterOnScreen) then
        personalRessourceDisplayFrame:Attach(frame, frame.unitFrame.healthBar, frame.unitFrame.powerBar);
      elseif (frame.kui and frame.kui.bg and frame.kui:IsShown()) then
        personalRessourceDisplayFrame:Attach(frame.kui, frame.kui.bg, frame.kui.bg);
      elseif (ElvUIPlayerNamePlateAnchor) then
        personalRessourceDisplayFrame:Attach(ElvUIPlayerNamePlateAnchor, ElvUIPlayerNamePlateAnchor, ElvUIPlayerNamePlateAnchor);
      else
        personalRessourceDisplayFrame:Attach(frame, frame.UnitFrame.healthBar, NamePlateDriverFrame.classNamePlatePowerBar);
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
    Private.StartProfileSystem("prd");
    if (event == "NAME_PLATE_UNIT_ADDED") then
      if (UnitIsUnit(nameplate, "player")) then
        local frame = C_NamePlate.GetNamePlateForUnit("player");
        if (frame) then
          if (Plater and frame.unitFrame.PlaterOnScreen) then
            personalRessourceDisplayFrame:Attach(frame, frame.unitFrame.healthBar, frame.unitFrame.powerBar);
          elseif (frame.kui and frame.kui.bg and frame.kui:IsShown()) then
            personalRessourceDisplayFrame:Attach(frame.kui, KuiNameplatesPlayerAnchor, KuiNameplatesPlayerAnchor);
          elseif (ElvUIPlayerNamePlateAnchor) then
            personalRessourceDisplayFrame:Attach(ElvUIPlayerNamePlateAnchor, ElvUIPlayerNamePlateAnchor, ElvUIPlayerNamePlateAnchor);
          else
            personalRessourceDisplayFrame:Attach(frame, frame.UnitFrame.healthBar, NamePlateDriverFrame.classNamePlatePowerBar);
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
    Private.StopProfileSystem("prd");
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
    if (anchorFrameType == "PRD" or anchorFrameType == "NAMEPLATE") then
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
  Private.personalRessourceDisplayFrame = personalRessourceDisplayFrame
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
      local parent = WeakAurasFrame;
      local parentData
      if data.parent then
        parentData = WeakAuras.GetData(data.parent)
        if parentData and Private.EnsureRegion(data.parent) then
          parent = Private.regions[data.parent].region
        end
      end
      if not parentData or parentData.regionType ~= "dynamicgroup" then
        Private.AnchorFrame(data, region, parent)
      end
    end
  end
end

local function postponeAnchor(id)
  postPonedAnchors[id] = true;
  if (not anchorTimer) then
    anchorTimer = timer:ScheduleTimer(tryAnchorAgain, 1);
  end
end

local HiddenFrames = CreateFrame("Frame", "WeakAurasHiddenFrames")
HiddenFrames:Hide()
WeakAuras.HiddenFrames = HiddenFrames

local function GetAnchorFrame(data, region, parent)
  local id = region.id
  local anchorFrameType = data.anchorFrameType
  local anchorFrameFrame = data.anchorFrameFrame
  if not id then return end
  if (personalRessourceDisplayFrame) then
    personalRessourceDisplayFrame:anchorFrame(id, anchorFrameType);
  end

  if (mouseFrame) then
    mouseFrame:anchorFrame(id, anchorFrameType);
  end

  if (anchorFrameType == "SCREEN") then
    return parent;
  end

  if (anchorFrameType == "UIPARENT") then
    return UIParent;
  end

  if (anchorFrameType == "PRD") then
    Private.ensurePRDFrame();
    personalRessourceDisplayFrame:anchorFrame(id, anchorFrameType);
    return personalRessourceDisplayFrame;
  end

  if (anchorFrameType == "MOUSE") then
    ensureMouseFrame();
    mouseFrame:anchorFrame(id, anchorFrameType);
    return mouseFrame;
  end

  if (anchorFrameType == "NAMEPLATE") then
    local unit = region.state and region.state.unit
    if unit then
      local frame = unit and WeakAuras.GetUnitNameplate(unit)
      if frame then return frame end
    end
    if WeakAuras.IsOptionsOpen() then
      Private.ensurePRDFrame()
      personalRessourceDisplayFrame:anchorFrame(id, anchorFrameType)
      return personalRessourceDisplayFrame
    end
  end

  if (anchorFrameType == "UNITFRAME") then
    local unit = region.state and region.state.unit
    if unit then
      local frame = WeakAuras.GetUnitFrame(unit) or WeakAuras.HiddenFrames
      if frame then
        anchor_unitframe_monitor = anchor_unitframe_monitor or {}
        anchor_unitframe_monitor[region] = {
          data = data,
          parent = parent,
          frame = frame
        }
        return frame
      end
    end
  end

  if (anchorFrameType == "SELECTFRAME" and anchorFrameFrame) then
    if(anchorFrameFrame:sub(1, 10) == "WeakAuras:") then
      local frame_name = anchorFrameFrame:sub(11);
      if (frame_name == id) then
        return parent;
      end

      if Private.regions[frame_name] and Private.regions[frame_name].region then
        return Private.regions[frame_name].region;
      end
      postponeAnchor(id);
    else
      if (Private.GetSanitizedGlobal(anchorFrameFrame)) then
        return Private.GetSanitizedGlobal(anchorFrameFrame);
      end
      postponeAnchor(id);
      return parent;
    end
  end

  if (anchorFrameType == "CUSTOM" and region.customAnchorFunc) then
    Private.StartProfileSystem("custom region anchor")
    Private.StartProfileAura(region.id)
    Private.ActivateAuraEnvironment(region.id, region.cloneId, region.state)
    local ok, frame = xpcall(region.customAnchorFunc, Private.GetErrorHandlerId(region.id, L["Custom Anchor"]))
    Private.ActivateAuraEnvironment()
    Private.StopProfileSystem("custom region anchor")
    Private.StopProfileAura(region.id)
    if ok and frame then
      return frame
    elseif WeakAuras.IsOptionsOpen() then
      return parent
    else
      return HiddenFrames
    end
  end
  -- Fallback
  return parent;
end

local anchorFrameDeferred = {}

function Private.AnchorFrame(data, region, parent, force)
  if data.anchorFrameType == "CUSTOM"
  and (data.regionType == "group" or data.regionType == "dynamicgroup")
  and not WeakAuras.IsLoginFinished()
  and not force
  then
    if not anchorFrameDeferred[data.id] then
      loginQueue[#loginQueue + 1] = {Private.AnchorFrame, {data, region, parent, true}}
      anchorFrameDeferred[data.id] = true
    end
  else
    local anchorParent = GetAnchorFrame(data, region, parent);
    if not anchorParent then return end
    if (data.anchorFrameParent or data.anchorFrameParent == nil
        or data.anchorFrameType == "SCREEN" or data.anchorFrameType == "UIPARENT" or data.anchorFrameType == "MOUSE") then
      xpcall(region.SetParent, Private.GetErrorHandlerId(data.id, L["Anchoring"]), region, anchorParent);
    else
      region:SetParent(parent or WeakAurasFrame);
    end

    local anchorPoint = data.anchorPoint
    if data.parent then
      if data.anchorFrameType == "SCREEN" or data.anchorFrameType == "MOUSE" then
        anchorPoint = "CENTER"
      end
    else
      if data.anchorFrameType == "MOUSE" then
        anchorPoint = "CENTER"
      end
    end

    region:SetAnchor(data.selfPoint, anchorParent, anchorPoint);

    if(data.frameStrata == 1) then
      region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
      region:SetFrameStrata(Private.frame_strata_types[data.frameStrata]);
    end
    Private.ApplyFrameLevel(region)
    anchorFrameDeferred[data.id] = nil
  end
end

function Private.FindUnusedId(prefix)
  prefix = prefix or "New"
  local num = 2;
  local id = prefix
  while(db.displays[id]) do
    id = prefix .. " " .. num;
    num = num + 1;
  end
  return id
end

function WeakAuras.SetModel(frame, unused, model_fileId, isUnit, isDisplayInfo)
  if isDisplayInfo then
    pcall(frame.SetDisplayInfo, frame, tonumber(model_fileId))
  elseif isUnit then
    pcall(frame.SetUnit, frame, model_fileId)
  else
    pcall(frame.SetModel, frame, tonumber(model_fileId))
  end
end

function Private.IsCLEUSubevent(subevent)
  if Private.subevent_prefix_types[subevent] then
     return true
  else
    for prefix in pairs(Private.subevent_prefix_types) do
      if subevent:match(prefix) then
        local suffix = subevent:sub(#prefix + 1)
        if Private.subevent_suffix_types[suffix] then
          return true
        end
      end
    end
  end
  return false
end

--- SafeToNumber converts a string to number, but only if it fits into a unsigned 32bit integer
--- The C api often takes only 32bit values, and complains if passed a value outside
---@param input any
---@return number|nil number
function WeakAuras.SafeToNumber(input)
  local nr = tonumber(input)
  return nr and (nr < 2147483648 and nr > -2147483649) and nr or nil
end

local textSymbols = {
  ["{rt1}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
  ["{rt2}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
  ["{rt3}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
  ["{rt4}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
  ["{rt5}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
  ["{rt6}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
  ["{rt7}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
  ["{rt8}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t"
}

---@param txt string
---@return string result
function WeakAuras.ReplaceRaidMarkerSymbols(txt)
  local start = 1

  while true do
    local firstChar = txt:find("{", start, true)
    if not firstChar then
      return txt
    end
    local lastChar = txt:find("}", firstChar, true)
    if not lastChar then
      return txt
    end
    local replace = textSymbols[txt:sub(firstChar, lastChar)]
    if replace then
      txt = txt:sub(1, firstChar - 1) .. replace .. txt:sub(lastChar + 1)
      start = firstChar + #replace
    else
      start = lastChar
    end
  end
end

function Private.ReplaceLocalizedRaidMarkers(txt)
  local start = 1

  while true do
    local firstChar = txt:find("{", start, true)
    if not firstChar then
      return txt
    end
    local lastChar = txt:find("}", firstChar, true)
    if not lastChar then
      return txt
    end

    local symbol = strlower(txt:sub(firstChar + 1, lastChar - 1))
    if ICON_TAG_LIST[symbol] then
      local replace = "rt" .. ICON_TAG_LIST[symbol]
      if replace then
        txt = txt:sub(1, firstChar) .. replace .. txt:sub(lastChar)
        start = firstChar + #replace
      else
        start = lastChar
      end
    else
      start  = lastChar
    end
  end
end

-- WORKAROUND
-- UnitPlayerControlled doesn't work if the target is "too" far away
--- @return boolean?
function Private.UnitPlayerControlledFixed(unit)
  local guid = UnitGUID(unit)
  return guid and guid:sub(1, 6) == "Player"
end

do
  local trackableUnits = {}
  trackableUnits["player"] = true
  trackableUnits["target"] = true
  trackableUnits["focus"] = true
  trackableUnits["pet"] = true
  trackableUnits["vehicle"] = true
  trackableUnits["softenemy"] = true
  trackableUnits["softfriend"] = true
  for i = 1, 5 do
    trackableUnits["arena" .. i] = true
    trackableUnits["arenapet" .. i] = true
  end

  for i = 1, 4 do
    trackableUnits["party" .. i] = true
    trackableUnits["partypet" .. i] = true
  end

  for i = 1, 10 do
    trackableUnits["boss" .. i] = true
  end

  for i = 1, 40 do
    trackableUnits["raid" .. i] = true
    trackableUnits["raidpet" .. i] = true
    trackableUnits["nameplate" .. i] = true
  end

  ---@param unit UnitToken
  ---@return boolean? result
  function WeakAuras.IsUntrackableSoftTarget(unit)
    if not Private.soft_target_cvars[unit] then return end
    -- technically this is incorrect if user doesn't have KBM and sets CVar to "2" (KBM only)
    -- but, there doesn't seem to be a way to detect 'user lacks KBM'
    -- anyways, the intersection of people who know how to set cvars and also don't have KBM for WoW is probably nil
    -- that might change if WoW ever ends up on playstation & friends, but also hell might freeze over so who knows
    local threshold = C_GamePad.IsEnabled() and 1 or 2
    return (tonumber(C_CVar.GetCVar(Private.soft_target_cvars[unit])) or 0) < threshold
  end

  ---@param unit UnitToken
  ---@return boolean result
  function WeakAuras.UntrackableUnit(unit)
    return not trackableUnits[unit]
  end
end

do
  local ownRealm = select(2, UnitFullName("player"))
  ---@param unit UnitToken
  ---@return string name
  ---@return string realm
  function WeakAuras.UnitNameWithRealm(unit)
    ownRealm = ownRealm or select(2, UnitFullName("player"))
    local name, realm = UnitFullName(unit)
    return name or "", realm or ownRealm or ""
  end

  function WeakAuras.UnitNameWithRealmCustomName(unit)
    ownRealm = ownRealm or select(2, UnitFullName("player"))
    local name, realm =  WeakAuras.UnitFullName(unit)
    return name or "", realm or ownRealm or ""
  end
end

function Private.ExecEnv.ParseNameCheck(name)
  local matches = {
    name = {},
    realm = {},
    full = {},
    AddMatch = function(self, input, start, last)
      local match = strtrim(input:sub(start, last))

      -- state: 1: In name
      -- state: 2: In Realm
      -- state: -1: Escape Name
      -- state: -2: In Escape Realm
      local state = 1
      local name = ""
      local realm = ""


      for index = 1, #match do
        local c = match:sub(index, index)

        if state == -1 then
          name = name .. c
          state = 1
        elseif state == -2 then
          realm = realm .. c
          state = 2
        elseif state == 1 then
          if c == "\\" then
            state = -1
          elseif c == "-" then
            state = 2
          else
            name = name .. c
          end
        elseif state == 2 then
          if c == "\\" then
            state = -2
          else
            realm = realm .. c
          end
        end
      end

      if name == "" then
        if realm == "" then
          -- Do nothing
        else
          self.realm[realm] = true
        end
      else
        if realm == "" then
          self.name[name] = true
        else
          self.full[name .. "-" .. realm] = true
        end
      end
    end,
    Check = function(self, name, realm)
      if not name or not realm then
        return false
      end
      return self.name[name] or self.realm[realm] or self.full[name .. "-" .. realm]
    end
  }

  if not name then return end
  local start = 1
  local last = name:find(',', start, true)

  while (last) do
    matches:AddMatch(name, start, last - 1)
    start = last + 1
    last = name:find(',', start, true)
  end

  last = #name
  matches:AddMatch(name, start, last)

  return matches
end

function Private.ExecEnv.ParseZoneCheck(input)
  if not input then return end

  local matcher = {
    Check = function(self)
      return false
    end,
    CheckBoth = function(self, zoneId, zonegroupId, instanceId, minimapZoneText)
      return self:CheckPositive(zoneId, zonegroupId, instanceId, minimapZoneText)
             and self:CheckNegative(zoneId, zonegroupId, instanceId, minimapZoneText)
    end,
    CheckPositive = function(self, zoneId, zonegroupId, instanceId, minimapZoneText)
      return self.zoneIds[zoneId] or self.zoneGroupIds[zonegroupId] or (instanceId and self.instanceIds[instanceId]) or self.areaNames[minimapZoneText]
    end,
    CheckNegative = function(self, zoneId, zonegroupId, instanceId, minimapZoneText)
      return not (self.negZoneIds[zoneId]
                  or self.negZoneGroupIds[zonegroupId]
                  or (instanceId and self.negInstanceIds[instanceId])
                  or self.negAreaNames[minimapZoneText])
    end,
    AddId = function(self, input, start, last)
      local id = tonumber(strtrim(input:sub(start, last)))
      if id then
        local prevChar = input:sub(start - 1, start - 1)
        local prevPrevchar = input:sub(start - 2, start - 2)
        if prevChar == 'g' or prevChar == 'G' then
          if prevPrevchar == "-" then
            self.negZoneGroupIds[id] = true
          else
            self.zoneGroupIds[id] = true
          end
        elseif prevChar == 'c' or prevChar == 'C' then
          local addTo = self.zoneIds
          if prevPrevchar == "-" then
            addTo = self.negZoneIds
          end
          addTo[id] = true
          local info = C_Map.GetMapChildrenInfo(id, nil, true)
          if info then
            for _,childInfo in pairs(info) do
              addTo[childInfo.mapID] = true
            end
          end
        elseif prevChar == 'a' or prevChar == 'A' then
          local areaName = C_Map.GetAreaInfo(id)
          if areaName then
            if prevPrevchar == "-" then
              self.negAreaNames[areaName] = true
            else
              self.areaNames[areaName] = true
            end
          end
        elseif prevChar == 'i' or prevChar == 'I' then
          if prevPrevchar == "-" then
            self.negInstanceIds[id] = true
          else
            self.instanceIds[id] = true
          end
        else
          if prevChar == "-" then
            self.negZoneIds[id] = true
          else
            self.zoneIds[id] = true
          end
        end
      end
    end,
    zoneIds = {},
    zoneGroupIds = {},
    instanceIds = {},
    areaNames = {},
    negZoneIds = {},
    negZoneGroupIds = {},
    negInstanceIds = {},
    negAreaNames = {},
  }

  local start = input:find('%d', 1)
  if start then
    local last = input:find('%D', start)
    while (last) do
      matcher:AddId(input, start, last - 1)
      start = input:find('%d', last + 1) or #input + 1
      last = input:find('%D', start)
    end

    last = #input
    matcher:AddId(input, start, last)
  end
  local hasPositive = next(matcher.zoneIds) or next(matcher.zoneGroupIds) or next(matcher.instanceIds) or next(matcher.areaNames)
  local hasNegative = next(matcher.negZoneIds) or next(matcher.negZoneGroupIds) or next(matcher.negInstanceIds) or next(matcher.negAreaNames)
  if hasPositive and hasNegative then
    matcher.Check = matcher.CheckBoth
  elseif hasPositive then
    matcher.Check = matcher.CheckPositive
  elseif hasNegative then
    matcher.Check = matcher.CheckNegative
  end
  return matcher
end

function WeakAuras.IsAuraLoaded(id)
  return Private.loaded[id]
end

function Private.ExecEnv.CreateSpellChecker()
  local matcher = {
    names = {},
    spellIds = {},
    AddName = function(self, name)
      local spellId = tonumber(name)
      if spellId then
        name = Private.ExecEnv.GetSpellName(spellId)
        if name then
          self.names[name] = true
        end
      else
        self.names[name] = true
      end
    end,
    AddExact = function(self, spellId)
      spellId = tonumber(spellId)
      self.spellIds[spellId] = true
    end,
    Check = function(self, spellId)
      if spellId then
        return self.spellIds[spellId] or self.names[Private.ExecEnv.GetSpellName(spellId)]
      end
    end,
    CheckName = function(self, name)
      return self.names[name]
    end
  }
  return matcher
end

function Private.IconSources(data)
  local values = {
    [-1] = L["Automatic"],
    [0] = L["Manual Icon"],
  }

  for i = 1, #data.triggers do
    values[i] = string.format(L["Trigger %i"], i)
  end
  return values
end

-- This should be used instead of string.format("...%q...", input)
-- e.g. string.format("...%s...", Private.QuotedString(input))
-- If the string is passed to loadstring.
-- It escapes --, which loadstring would otherwise interpret as comment starts
function Private.QuotedString(input)
  local str = string.format("%q", input)
  return (str:gsub("%-%-", "-\\-"))
end

-- Helper function to make the templates not care, how the generic triggers
-- are categorized
---@private
function WeakAuras.GetTriggerCategoryFor(triggerType)
  local prototype = Private.event_prototypes[triggerType]
  return prototype and prototype.type
end

function Private.SortOrderForValues(values)
  local sortOrder = {}
  for key, value in pairs(values) do
    tinsert(sortOrder, key)
  end
  table.sort(sortOrder, function(aKey, bKey)
    local aValue = values[aKey]
    local bValue = values[bKey]

    if type(aValue) == "string" and aValue:sub(1, #WeakAuras.newFeatureString) == WeakAuras.newFeatureString then
      aValue = aValue:sub(#WeakAuras.newFeatureString + 1)
    end

    if type(bValue) == "string" and bValue:sub(1, #WeakAuras.newFeatureString) == WeakAuras.newFeatureString then
      bValue = bValue:sub(#WeakAuras.newFeatureString + 1)
    end

    return aValue < bValue
  end)
  return sortOrder
end

do
  local function shouldInclude(data, includeGroups, includeLeafs)
    if data.controlledChildren then
      return includeGroups
    else
      return includeLeafs
    end
  end

  local function Traverse(data, includeSelf, includeGroups, includeLeafs)
    if includeSelf and shouldInclude(data, includeGroups, includeLeafs) then
      coroutine.yield(data)
    end

    if data.controlledChildren then
      for _, child in ipairs(data.controlledChildren) do
        Traverse(WeakAuras.GetData(child), true, includeGroups, includeLeafs)
      end
    end
  end

  local function TraverseLeafs(data)
    return Traverse(data, false, false, true)
  end

  local function TraverseLeafsOrAura(data)
    return Traverse(data, true, false, true)
  end

  local function TraverseGroups(data)
    return Traverse(data, true, true, false)
  end

  local function TraverseSubGroups(data)
    return Traverse(data, false, true, false)
  end

  local function TraverseAllChildren(data)
    return Traverse(data, false, true, true)
  end

  local function TraverseAll(data)
    return Traverse(data, true, true, true)
  end

  local function TraverseParents(data)
    while data.parent do
      local parentData = WeakAuras.GetData(data.parent)
      coroutine.yield(parentData)
      data = parentData
    end
  end

  -- Only non-group auras, not include self
  function Private.TraverseLeafs(data)
    return coroutine.wrap(TraverseLeafs), data
  end

  -- The root if it is a non-group, otherwise non-group children
  function Private.TraverseLeafsOrAura(data)
    return coroutine.wrap(TraverseLeafsOrAura), data
  end

  -- All groups, includes self
  function Private.TraverseGroups(data)
    return coroutine.wrap(TraverseGroups), data
  end

  -- All groups, excludes self
  function Private.TraverseSubGroups(data)
    return coroutine.wrap(TraverseSubGroups), data
  end

  -- All Children, excludes self
  function Private.TraverseAllChildren(data)
    return coroutine.wrap(TraverseAllChildren), data
  end

  -- All Children and self
  function Private.TraverseAll(data)
    return coroutine.wrap(TraverseAll), data
  end

  function Private.TraverseParents(data)
    return coroutine.wrap(TraverseParents), data
  end

  --- Returns whether the data is a group or dynamicgroup
  ---@param data auraData
  ---@return boolean
  function Private.IsGroupType(data)
    return data.regionType == "group" or data.regionType == "dynamicgroup"
  end
end

