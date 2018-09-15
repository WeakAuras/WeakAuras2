--[[ BuffTrigger2.lua
This file contains the "aura2" trigger for buffs and debuffs. It is intended to replace
the buff trigger old BuffTrigger at some future point

It registers the BuffTrigger table for the trigger type "aura2" and has the following API:

Add(data)
Adds an aura, setting up internal data structures for all buff triggers.

LoadDisplay(id)
Loads the aura id, enabling all buff triggers in the aura.

UnloadDisplay(id)
Unloads the aura id, disabling all buff triggers in the aura.

UnloadAll()
Unloads all auras, disabling all buff triggers.

ScanAll()
Updates all triggers by checking all triggers.

Delete(id)
Removes all data for aura id.

Rename(oldid, newid)
Updates all data for aura oldid to use newid.

Modernize(data)
Updates all buff triggers in data.

#####################################################
# Helper functions mainly for the WeakAuras Options #
#####################################################

CanHaveDuration(data, triggernum)
Returns whether the trigger can have a duration.

GetOverlayInfo(data, triggernum)
Returns a table containing all overlays. Currently there aren't any

CanHaveAuto(data, triggernum)
Returns whether the icon can be automatically selected.

CanHaveClones(data, triggernum)
Returns whether the trigger can have clones.

CanHaveTooltip(data, triggernum)
Returns the type of tooltip to show for the trigger.

GetNameAndIcon(data, triggernum)
Returns the name and icon to show in the options.

GetAdditionalProperties(data, triggernum)
Returns the tooltip text for additional properties.

GetTriggerConditions(data, triggernum)
Returns the potential conditions for a trigger
]]--

-- luacheck: globals CombatLogGetCurrentEventInfo

-- Lua APIs
local tinsert, wipe = table.insert, wipe
local pairs, next, type = pairs, next, type

local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local BuffTrigger = {};

-- TODO which of these is still needed?
local timer = WeakAuras.timer;

function BuffTrigger.ScanAll()
  -- TODO
  print("BuffTrigger.ScanAll")
end

function BuffTrigger.UnloadAll()
  print("BuffTrigger.UnloadAll")
end

function BuffTrigger.LoadDisplay(id)
  print("BuffTrigger.LoadDisplay ", id)
end

function BuffTrigger.UnloadDisplay(id)
  print("BuffTrigger.UnloadDisplay ", id)
end

--- Removes all data for an aura id
-- @param id
function BuffTrigger.Delete(id)
  print("BuffTrigger.Delete ", id)
end

--- Updates all data for aura oldid to use newid
-- @param oldid
-- @param newid
function BuffTrigger.Rename(oldid, newid)
  print("BuffTrigger.Rename ", oldid, newid)
end

--- Adds an aura, setting up internal data structures for all buff triggers.
-- @param data
function BuffTrigger.Add(data)
  print("BuffTrigger.Add ", data.id);
end

--- Updates old data to the new format.
-- @param data
function BuffTrigger.Modernize(data)
  -- Nothing yet!
end


--- Returns whether the trigger can have a duration.
-- @param data
-- @param triggernum
function BuffTrigger.CanHaveDuration(data, triggernum)
  return "timed";
end

--- Returns a table containing the names of all overlays
-- @param data
-- @param triggernum
function BuffTrigger.GetOverlayInfo(data, triggernum)
  return {};
end

--- Returns whether the icon can be automatically selected.
-- @param data
-- @param triggernum
-- @return boolean
function BuffTrigger.CanHaveAuto(data, triggernum)
  return true;
end

--- Returns whether the trigger can have clones.
-- @param data
-- @param triggernum
-- @return
function BuffTrigger.CanHaveClones(data, triggernum)
  return false;
end

---Returns the type of tooltip to show for the trigger.
-- @param data
-- @param triggernum
-- @return string
function BuffTrigger.CanHaveTooltip(data, triggernum)
  print("BuffTrigger.CanHaveTooltip");
end

function BuffTrigger.SetToolTip(trigger, state)
  print("BuffTrigger.SetToolTip");
end

--- Returns the name and icon to show in the options.
-- @param data
-- @param triggernum
-- @return name and icon
function BuffTrigger.GetNameAndIcon(data, triggernum)
  print("BuffTrigger.GetNameAndIcon ", data.id, triggernum);
end

--- Returns the tooltip text for additional properties.
-- @param data
-- @param triggernum
-- @return string of additional properties
function BuffTrigger.GetAdditionalProperties(data, triggernum)
  print("BuffTrigger.GetAdditionalProperties");
end

function BuffTrigger.GetTriggerConditions(data, triggernum)
  local result = {};
  print("BuffTrigger.GetTriggerConditions");
  return result;
end

function BuffTrigger.CreateFallbackState(data, triggernum, state)
  print("BuffTrigger.CreateFallbackState");
  state.show = true;
  state.changed = true;
  state.progressType = "timed";
  state.duration = 0;
  state.expirationTime = math.huge;
end

function BuffTrigger.GetName(triggerType)
  if (triggerType == "aura2") then
    return L["Aura"];
  end
end

WeakAuras.RegisterTriggerSystem({"aura2"}, BuffTrigger);
