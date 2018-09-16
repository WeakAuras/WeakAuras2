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

local auras = {};

-- keyed on unit, debuffType, spellname, id, triggernum with value = a scanFunc that checks if the trigger settings match the data
-- TODO These could be merged
local ownOnlyAurasName = {};
local allAurasName = {};

local timer = WeakAuras.timer;

-- Auras that matched, keyed on id, triggernum, unit, index
local matchData = {};
-- Auras that matched, keyed on id, triggernum, kept in sync with matchData
local matchDataByTrigger = {};

local function UpdateMatchData(time, unit, index, filter, id, triggernum, name, icon, count, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
  if (not matchData[unit]) then
    matchData[unit] = {};
  end
  if (not matchData[unit][filter]) then
    matchData[unit][filter] = {};
  end
  if (not matchData[unit][filter][id]) then
    matchData[unit][filter][id] = {};
  end
  if (not matchData[unit][filter][id][triggernum]) then
    matchData[unit][filter][id][triggernum] = {};
  end
  if (not matchData[unit][filter][id][triggernum][index]) then
    matchData[unit][filter][id][triggernum][index] = {
      name = name,
      icon = icon,
      count = count,
      duration = duration,
      expirationTime = expirationTime,
      unitCaster = unitCaster,
      spellId = spellId,
      time = time
    };

    matchDataByTrigger[id] = matchDataByTrigger[id] or {};
    matchDataByTrigger[id][triggernum] = matchDataByTrigger[id][triggernum] or {};
    matchDataByTrigger[id][triggernum][unit] = matchDataByTrigger[id][triggernum][unit] or {};
    matchDataByTrigger[id][triggernum][unit][index] = matchData[unit][filter][id][triggernum][index];
    return true;
  end

  local data = matchData[unit][filter][id][triggernum][index];

  local changed = false;
  if (data.name ~= name) then
    data.name = name;
    changed = true;
  end

  if (data.icon ~= icon) then
    data.icon = icon;
    changed = true;
  end

  if (data.count ~= count) then
    data.count = count;
    changed = true;
  end

  if (data.duration ~= duration) then
    data.duration = duration;
    changed = true;
  end

  if (data.expirationTime ~= expirationTime) then
    data.expirationTime = name;
    changed = true;
  end

  if (data.unitCaster ~= unitCaster) then
    data.unitCaster = unitCaster;
    changed = true;
  end

  if (data.spellId ~= spellId) then
    data.spellId = name;
    changed = true;
  end

  data.index = index;

  data.time = time;

  return changed;
end

local function UpdateTriggerState(id, triggernum)
  -- Find best match
  local bestExpirationTime;
  local bestMatch = nil;

  for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
    for index, auraData in pairs(unitData) do
      if (not bestExpirationTime or bestExpirationTime > auraData.expirationTime) then
        bestExpirationTime = auraData.expirationTime;
        bestMatch = auraData;
      end
    end
  end

  local triggerStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
  local cloneId = "";
  if (bestMatch) then
    if (not triggerStates[cloneId]) then
      triggerStates[cloneId] = {
        show = true,
        changed = true,
        name = bestMatch.name,
        icon = bestMatch.icon,
        count = bestMatch.count,
        progressType = "timed",
        duration = bestMatch.duration,
        expirationTime = bestMatch.expirationTime,
        unitCaster = bestMatch.unitCaster,
        spellId = bestMatch.spellId,
        index = bestMatch.index,
      }
      WeakAuras.UpdatedTriggerState(id);
    else
      local state = triggerStates[cloneId];

      local changed = false;
      if (state.show ~= true) then
        state.show = true;
        changed = true;
      end
      if (state.name ~= bestMatch.name) then
        state.name = bestMatch.name;
        changed = true;
      end

      if (state.icon ~= bestMatch.icon) then
        state.icon = bestMatch.icon;
        changed = true;
      end

      -- TODO add GUID (?)
      -- TODO Rename to stacks
      if (state.count ~= bestMatch.count) then
        state.count = bestMatch.count;
        changed = true;
      end

      if (state.duration ~= bestMatch.duration) then
        state.duration = bestMatch.duration;
        changed = true;
      end

      if (state.expirationTime ~= bestMatch.expirationTime) then
        state.expirationTime = bestMatch.expirationTime;
        changed = true;
      end

      if (state.progressType ~= "timed") then
        state.progressType = "timed";
        changed = true;
      end

      if (state.unitCaster ~= bestMatch.unitCaster) then
        state.unitCaster = bestMatch.unitCaster;
        changed = true;
      end

      if (state.spellId ~= bestMatch.spellId) then
        state.spellId = bestMatch.spellId;
        changed = true;
      end

      if (state.index ~= bestMatch.index) then
        state.index = bestMatch.index;
        changed = true;
      end

      if (changed) then
        state.changed = true;
        WeakAuras.UpdatedTriggerState(id);
      end
    end
  else -- No best match
    local state = triggerStates[cloneId];
    if (state) then
      local changed = false;
      if (state.show) then
        state.show = false;
        changed = true;
      end
      if (changed) then
        state.changed = true;
        WeakAuras.UpdatedTriggerState(id);
      end
    end
  end
end

local function ScanAurasWithFilter(time, unit, filter, triggerInfo)
  if (not triggerInfo) then
    return;
  end

  print("ScanAurasWithFilter ", unit, filter, triggerInfo);

  local matchDataChanged = {};

  local index = 1;
  while(true) do
    -- TODO figure out a way to break out of this loop early,
    -- if there's no cloning aura for this unit, and we have found a match for every aura
    -- Is that worth it? Any NOT debuffed check has to run the whole way
    -- Any always check if the buff is not present has to check all auras too
    local name, icon, count, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, index, filter);
    index = index + 1;
    if (not name) then
      break;
    end

    local auras = triggerInfo[name];
    if (auras) then
      for id, triggerData in pairs(auras) do
        for triggernum, scanFunc in pairs(triggerData) do
          if (scanFunc(name, icon, count)) then
            print("FOUND MATCH");
            if (UpdateMatchData(time, unit, index, filter, id, triggernum,  name, icon, count, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)) then
              matchDataChanged[id] = matchDataChanged[id] or {};
              matchDataChanged[id][triggernum] = true;
            end
          end
        end
      end
    end
  end

  -- Figure out if any matchData is outdated
  if (matchData[unit] and matchData[unit][filter]) then
    for id, auraData in pairs(matchData[unit][filter]) do
      for triggernum, triggerData in pairs(auraData) do
        for index, data in pairs(triggerData) do
          if (data.time < time) then
            print("OUTDATE aura removed");
            triggerData[index] = nil;
            matchDataByTrigger[id][triggernum][unit][index] = nil;

            matchDataChanged[id] = matchDataChanged[id] or {};
            matchDataChanged[id][triggernum] = true;
          end
        end
      end
    end
  end

  for id, auraData in pairs(matchDataChanged) do
    for triggernum in pairs(auraData) do
      UpdateTriggerState(id, triggernum);
    end
  end
end

local function ScanAuras(unit)
  local time = GetTime();
  if (ownOnlyAurasName[unit]) then
    ScanAurasWithFilter(time, unit, "HELPFUL|PLAYER", ownOnlyAurasName[unit]["HELPFUL"])
    ScanAurasWithFilter(time, unit, "HARMFUL|PLAYER", ownOnlyAurasName[unit]["HARMFUL"])
  end
  if (allAurasName[unit]) then
    ScanAurasWithFilter(time, unit, "HELPFUL", allAurasName[unit]["HELPFUL"])
    ScanAurasWithFilter(time, unit, "HARMFUL", allAurasName[unit]["HARMFUL"])
  end
end

local frame = CreateFrame("FRAME");
WeakAuras.frames["WeakAuras Buff2 Frame"] = frame;
frame:RegisterEvent("UNIT_AURA");
frame:SetScript("OnEvent", function (frame, event, arg1, arg2, ...)
  WeakAuras.StartProfileSystem("bufftrigger2");
  if(event == "PLAYER_TARGET_CHANGED") then
    ScanAuras("target");
  elseif(event == "PLAYER_FOCUS_CHANGED") then
    ScanAuras("focus");
  elseif(event == "UNIT_AURA") then
    ScanAuras(arg1);
  end
  WeakAuras.StopProfileSystem("bufftrigger2");
end);


function BuffTrigger.ScanAll()
  -- TODO
  print("BuffTrigger.ScanAll")
end

function BuffTrigger.UnloadAll()
  wipe(allAurasName);
  wipe(ownOnlyAurasName);
  wipe(matchData);
  wipe(matchDataByTrigger);
end

local function LoadAura(id, triggernum, triggerInfo)
  if (triggerInfo.name) then
    local base = allAurasName;
    if (triggerInfo.ownOnly) then
      base = ownOnlyAurasName;
    end
    base[triggerInfo.unit]                                                           = base[triggerInfo.unit] or {};
    base[triggerInfo.unit][triggerInfo.debuffType]                                   = base[triggerInfo.unit][triggerInfo.debuffType] or {};
    base[triggerInfo.unit][triggerInfo.debuffType][triggerInfo.name]                 = base[triggerInfo.unit][triggerInfo.debuffType][triggerInfo.name] or {};
    base[triggerInfo.unit][triggerInfo.debuffType][triggerInfo.name][id]             = base[triggerInfo.unit][triggerInfo.debuffType][triggerInfo.name][id] or {};
    base[triggerInfo.unit][triggerInfo.debuffType][triggerInfo.name][id][triggernum] = triggerInfo.scanFunc;
  end
end

function BuffTrigger.LoadDisplay(id)
  if (auras[id]) then
    for triggernum, triggerInfo in pairs(auras[id]) do
      LoadAura(id, triggernum, triggerInfo);
    end
  end
end

local function UnloadAura(base, id)
  for unit, unitData in pairs(base) do
    for debuffType, debuffData in pairs(unitData) do
      for needle, needleData in pairs(debuffData) do
        unitData[id] = nil;
      end
    end
  end
end

function BuffTrigger.UnloadDisplay(id)
  UnloadAura(allAurasName, id);
  UnloadAura(ownOnlyAurasName, id);

  for unit, unitData in pairs(matchData) do
    for filter, filterData in pairs(unitData) do
      filterData[id] = nil;
    end
  end
  matchDataByTrigger[id] = nil;
end

--- Removes all data for an aura id
-- @param id
function BuffTrigger.Delete(id)
  BuffTrigger.UnloadDisplay(id);
  auras[id] = nil;
end

--- Updates all data for aura oldid to use newid
-- @param oldid
-- @param newid

local function Rename(base, oldid, newid)
  for unit, unitData in pairs(base) do
    for debuffType, debuffData in pairs(unitData) do
      for needle, needleData in pairs(debuffData) do
        needleData[newid] = needleData[oldid];
        needleData[oldid] = nil;
      end
    end
  end
end

function BuffTrigger.Rename(oldid, newid)
  auras[newid] = auras[oldid];
  auras[oldid] = nil;

  matchDataByTrigger[newid] = matchDataByTrigger[oldid];
  matchDataByTrigger[oldid] = nil;


  for unit, unitData in pairs(matchData) do
    for filter, filterData in pairs(unitData) do
      filterData[newid] = filterData[oldid];
      filterData[oldid] = nil;
    end
  end

  Rename(allAurasName, oldid, newid);
  Rename(ownOnlyAurasName, oldid, newid);
end

local function trueFunc()
  return true;
end

local function createScanFunc(trigger)
  if (not trigger.useCount) then
    return trueFunc;
  end

  -- name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, ..
  local ret = [[
    function(name, icon, count)
  ]];

  if (trigger.useCount) then
    local ret2 = [[
      if not(count %s %s) then
        return false
      end
    ]]
    ret = ret2:format(trigger.countOperator or ">=", tonumber(trigger.count) or 0);
  end

  ret = ret .. [[
      return true
    end
  ]];

  return loadstring(ret);
end

--- Adds an aura, setting up internal data structures for all buff triggers.
-- @param data
function BuffTrigger.Add(data)
  local id = data.id;

  auras[id] = nil;
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger
    if (trigger.type == "aura2") then
      local auraName = trigger.name;
      if (trigger.spellId) then
        auraName = GetSpellInfo(trigger.spellId);
      end

      local scanFunc = createScanFunc(trigger);
      local triggerInformation = {
        name = auraName,
        unit = trigger.unit,
        debuffType = trigger.debuffType,
        ownOnly = trigger.ownOnly,
        scanFunc = scanFunc;
      };
      auras[id] = auras[id] or {};
      auras[id][triggernum] = triggerInformation;
    end
  end
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
  return "aura";
end

function BuffTrigger.SetToolTip(trigger, state)
  if(trigger.debuffType == "HELPFUL") then
    GameTooltip:SetUnitBuff(trigger.unit, state.index);
  elseif(trigger.debuffType == "HARMFUL") then
    GameTooltip:SetUnitDebuff(trigger.unit, state.index);
  end
end

--- Returns the name and icon to show in the options.
-- @param data
-- @param triggernum
-- @return name and icon
function BuffTrigger.GetNameAndIcon(data, triggernum)
  -- TODO BuffTrigger.GetNameAndIcon
  return nil, nil;
end

--- Returns the tooltip text for additional properties.
-- @param data
-- @param triggernum
-- @return string of additional properties
function BuffTrigger.GetAdditionalProperties(data, triggernum)
  local ret = "\n\n" .. L["Additional Trigger Replacements"] .. "\n";
  ret = ret .. "|cFFFF0000%spellId|r -" .. L["Spell ID"] .. "\n";
  ret = ret .. "|cFFFF0000%unitCaster|r -" .. L["Caster"] .. "\n";
  return ret;
end

function BuffTrigger.GetTriggerConditions(data, triggernum)
  local result = {};
  result["unitCaster"] = {
    display = L["Caster"],
    type = "string",
  }

  result["expirationTime"] = {
    display = L["Remaining Duration"],
    type = "timer",
  }
  result["duration"] = {
    display = L["Total Duration"],
    type = "number",
  }

  result["stacks"] = {
    display = L["Stacks"],
    type = "number"
  }

  result["name"] = {
    display = L["Name"],
    type = "string"
  }

  return result;
end

function BuffTrigger.CreateFallbackState(data, triggernum, state)
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
