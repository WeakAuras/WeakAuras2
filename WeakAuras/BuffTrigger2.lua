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

local triggerInfos = {};

-- keyed on unit, debuffType, spellname, with a scan object value
-- scan object: id, triggernum, scanFunc
-- TODO are we going to have multiple maps from e.g. roles to scanFuncs ?
local scanFuncName = {};
local scanFuncSpellId = {};
local scanFuncGeneral = {};

local timer = WeakAuras.timer;

-- Auras that matched, keyed on id, triggernum, unit, index
local matchData = {};
-- Auras that matched, keyed on id, triggernum, kept in sync with matchData
local matchDataByTrigger = {};

local function UpdateMatchData(time, unit, index, filter, id, triggernum, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
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
      stacks = stacks,
      duration = duration,
      expirationTime = expirationTime,
      unitCaster = unitCaster,
      spellId = spellId,
      unit = unit,
      time = time,
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

  if (data.stacks ~= stacks) then
    data.stacks = stacks;
    changed = true;
  end

  if (data.duration ~= duration) then
    data.duration = duration;
    changed = true;
  end

  if (data.expirationTime ~= expirationTime) then
    data.expirationTime = expirationTime;
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
  data.unit = unit;

  return changed;
end

local function calculateNextCheck(triggerInfoRemaing, auraDataRemaing, auraDataExpirationTime,  nextCheck)
  if (auraDataRemaing > 0 and auraDataRemaing >= triggerInfoRemaing) then
    if (not nextCheck) then
      return auraDataExpirationTime - triggerInfoRemaing;
    else
      return min(auraDataExpirationTime - triggerInfoRemaing, nextCheck);
    end
  end
  return nextCheck;
end

local function FindBestMatchData(time, id, triggernum, triggerInfo)
  -- Find best match
  local bestExpirationTime;
  local bestMatch = nil;

  local totalCount = 0;
  local nextCheck

  if (not matchDataByTrigger[id] or not matchDataByTrigger[id][triggernum]) then
    return nil, 0;
  end

  for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
    for index, auraData in pairs(unitData) do
      local remCheck = true;
      if (triggerInfo.remainingFunc and auraData.expirationTime) then
        local remaining = auraData.expirationTime - time;
        remCheck = triggerInfo.remainingFunc(remaining);
        nextCheck = calculateNextCheck(triggerInfo.remainingCheck, remaining, auraData.expirationTime, nextCheck)
      end

      if (remCheck) then
        totalCount = totalCount + 1;
        if (not bestExpirationTime or bestExpirationTime > auraData.expirationTime) then
          bestExpirationTime = auraData.expirationTime;
          bestMatch = auraData;
        end
      end
    end
  end
  return bestMatch, totalCount, nextCheck;
end

local function UpdateStateWithMatch(time, bestMatch, triggerStates, cloneId, totalCount)
  if (not triggerStates[cloneId]) then
    triggerStates[cloneId] = {
      show = true,
      changed = true,
      name = bestMatch.name,
      icon = bestMatch.icon,
      stacks = bestMatch.stacks,
      progressType = "timed",
      duration = bestMatch.duration,
      expirationTime = bestMatch.expirationTime,
      unitCaster = bestMatch.unitCaster,
      spellId = bestMatch.spellId,
      index = bestMatch.index,
      unit = bestMatch.unit,
      GUID = UnitGUID(bestMatch.unit),
      totalCount = totalCount,
      time = time
    }
    return true;
  else
    local state = triggerStates[cloneId];

    state.time = time;

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

    if (state.stacks ~= bestMatch.stacks) then
      state.stacks = bestMatch.stacks;
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

    if (state.totalCount ~= totalCount) then
      state.totalCount = totalCount;
      changed = true;
    end

    if (changed) then
      state.changed = true;
      return true;
    end
  end
end

local function UpdateStateWithNoMatch(time, triggerStates, cloneId)
  if (not triggerStates[cloneId]) then
    triggerStates[cloneId] = {
      show = true,
      changed = true,
      totalCount = 0,
      time = time
    }
    return true;
  else
    local state = triggerStates[cloneId];
    state.time = time;
    local changed = false;
    if (state.show ~= true) then
      state.show = true;
      changed = true;
    end
    if (state.name) then
      state.name = nil;
      changed = true;
    end

    if (state.icon) then
      state.icon = nil;
      changed = true;
    end

    if (state.stacks) then
      state.stacks = nil;
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

    if (state.progressType) then
      state.progressType = nil;
      changed = true;
    end

    if (state.unitCaster) then
      state.unitCaster = nil;
      changed = true;
    end

    if (state.spellId) then
      state.spellId = nil;
      changed = true;
    end

    if (state.index) then
      state.index = nil;
      changed = true;
    end

    if (state.totalCount ~= 0) then
      state.totalCount = 0;
      changed = true;
    end

    if (changed) then
      state.changed = true;
      return true;
    end
  end
end

local function RemoveState(triggerStates, cloneId)
  local state = triggerStates[cloneId];
  if (state) then
    if (state.show) then
      state.show = false;
      state.changed = true;
      return true;
    end
  end
end

local recheckTriggerInfo;

local function UpdateTriggerState(time, id, triggernum)
  -- TODO cloneId: for group triggers, this needs to be the playerName
  -- allowing multiple buff triggers to refer to their matching clones

  print("  UpdatedTriggerState for ", id);
  local triggerStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);

  local triggerInfo = triggerInfos[id][triggernum];
  local updated;
  local nextCheck;
  if (triggerInfo.showClones) then
    for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
      for index, auraData in pairs(unitData) do
        local cloneId = tostring(auraData);
        local remCheck = true;
        if (triggerInfo.remainingFunc and auraData.expirationTime) then
          local remaining = auraData.expirationTime - time;
          remCheck = triggerInfo.remainingFunc(remaining);
          nextCheck = calculateNextCheck(triggerInfo.remainingCheck, remaining, auraData.expirationTime, nextCheck)
        end

        if (remCheck) then
          updated = UpdateStateWithMatch(time, auraData, triggerStates, cloneId) or updated;
        end
      end
    end

    for cloneId, state in pairs(triggerStates) do
      if (state.time < time) then
        updated = RemoveState(triggerStates, cloneId) or updated;
      end
    end

    if (updated) then
      WeakAuras.UpdatedTriggerState(id);
    end
  else -- No clones
    local bestMatch, totalCount
    bestMatch, totalCount, nextCheck = FindBestMatchData(time, id, triggernum, triggerInfo);
    local cloneId = "";
    local updated = false;

    if (bestMatch) then
      if (triggerInfo.matchesShowOn == "showOnMissing") then
        updated = RemoveState(triggerStates, cloneId);
      else
        updated = UpdateStateWithMatch(time, bestMatch, triggerStates, cloneId, totalCount);
      end
    else -- No best match
      if (triggerInfo.matchesShowOn == "showOnActive") then
        updated = RemoveState(triggerStates, cloneId);
      else
        updated = UpdateStateWithNoMatch(time, triggerStates, cloneId);
      end
    end

    if (updated) then
      print("  states were updated for ", id);
      WeakAuras.UpdatedTriggerState(id);
    end
  end

  if (nextCheck) then
    if (triggerInfo.nextScheduledCheck ~= nextCheck) then
      if (triggerInfo.nextScheduledCheckHandle) then
        timer:CancelTimer(triggerInfo.nextScheduledCheckHandle);
      end
      triggerInfo.nextScheduledCheckHandle = timer:ScheduleTimerFixed(recheckTriggerInfo, nextCheck - time, triggerInfo);
      triggerInfo.nextScheduledCheck = nextCheck;
    end
  elseif (triggerInfo.nextScheduledCheckHandle) then
    timer:CancelTimer(triggerInfo.nextScheduledCheckHandle);
    triggerInfo.nextScheduledCheckHandle = nil;
    triggerInfo.nextScheduledCheck = nil;
  end
end

recheckTriggerInfo = function(triggerInfo)
  UpdateTriggerState(GetTime(), triggerInfo.id, triggerInfo.triggernum);
  triggerInfo.nextScheduledCheckHandle = nil;
  triggerInfo.nextScheduledCheck = nil;
end

local function ScanUnitWithFilter(matchDataChanged, time, unit, filter, scanFuncName, scanFuncSpellId, scanFuncGeneral)
  if (not scanFuncName and not scanFuncSpellId and not scanFuncGeneral) then
    return;
  end

  local index = 1;
  while(true) do
    local name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, index, filter);
    print("  Aura ", index, " ", name, " ", stacks, " ", duration, " ", expirationTime);
    if (debuffClass == nil) then
      debuffClass = "none";
    elseif (debuffClass == "") then
      debuffClass = "enrage"
    else
      debuffClass = string.lower(debuffClass);
    end
    index = index + 1;
    if (not name) then
      break;
    end

    local auras = scanFuncName and scanFuncName[name];
    if (auras) then
      for _, triggerInfo in pairs(auras) do
        if ((not triggerInfo.scanFunc) or triggerInfo.scanFunc(name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable)) then
          print("  matched by ", triggerInfo.id);
          local id = triggerInfo.id;
          local triggernum = triggerInfo.triggernum
          if (UpdateMatchData(time, unit, index, filter, id, triggernum,  name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)) then
            print("  updated match data");
            matchDataChanged[id] = matchDataChanged[id] or {};
            matchDataChanged[id][triggernum] = true;
          end
        end
      end
    end

    auras = scanFuncSpellId and scanFuncSpellId[spellId];
    if (auras) then
      for _, triggerInfo in pairs(auras) do
        if ((not triggerInfo.scanFunc) or triggerInfo.scanFunc(name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable)) then
          print("  matched by ", triggerInfos.id);
          local id = triggerInfo.id;
          local triggernum = triggerInfo.triggernum
          if (UpdateMatchData(time, unit, index, filter, id, triggernum,  name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)) then
            print("  updated match data");
            matchDataChanged[id] = matchDataChanged[id] or {};
            matchDataChanged[id][triggernum] = true;
          end
        end
      end
    end

    if (scanFuncGeneral) then
      for _, triggerInfo in pairs(scanFuncGeneral) do
        if ((not triggerInfo.scanFunc) or triggerInfo.scanFunc(name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable)) then
          local id = triggerInfo.id;
          local triggernum = triggerInfo.triggernum
          if (UpdateMatchData(time, unit, index, filter, id, triggernum,  name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)) then
            matchDataChanged[id] = matchDataChanged[id] or {};
            matchDataChanged[id][triggernum] = true;
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
            triggerData[index] = nil;
            matchDataByTrigger[id][triggernum][unit][index] = nil;

            matchDataChanged[id] = matchDataChanged[id] or {};
            matchDataChanged[id][triggernum] = true;
          end
        end
      end
    end
  end

end


local function UpdateStates(matchDataChanged, time)
  for id, auraData in pairs(matchDataChanged) do
    for triggernum in pairs(auraData) do
      UpdateTriggerState(time, id, triggernum);
    end
  end
end

local function ScanUnit(unit)
  print("ScanUnit ", unit);
  local time = GetTime();
  local matchDataChanged = {};

  scanFuncName[unit] = scanFuncName[unit] or {};
  scanFuncSpellId[unit] = scanFuncSpellId[unit] or {};
  scanFuncGeneral[unit] = scanFuncGeneral[unit] or {};

  ScanUnitWithFilter(matchDataChanged, time, unit, "HELPFUL|PLAYER",
      scanFuncName[unit]["HELPFUL|PLAYER"],
      scanFuncSpellId[unit]["HELPFUL|PLAYER"],
      scanFuncGeneral[unit]["HELPFUL|PLAYER"])

  ScanUnitWithFilter(matchDataChanged, time, unit, "HARMFUL|PLAYER",
      scanFuncName[unit]["HARMFUL|PLAYER"],
      scanFuncSpellId[unit]["HARMFUL|PLAYER"],
      scanFuncGeneral[unit]["HARMFUL|PLAYER"])

  print(" --- ");
  for k, v in pairs(scanFuncName[unit]["HELPFUL"]) do
    print("___ ", k, v);
  end

  ScanUnitWithFilter(matchDataChanged, time, unit, "HELPFUL",
      scanFuncName[unit]["HELPFUL"],
      scanFuncSpellId[unit]["HELPFUL"],
      scanFuncGeneral[unit]["HELPFUL"])

  ScanUnitWithFilter(matchDataChanged, time, unit, "HARMFUL",
      scanFuncName[unit]["HARMFUL"],
      scanFuncSpellId[unit]["HARMFUL"],
      scanFuncGeneral[unit]["HARMFUL"]);

  UpdateStates(matchDataChanged, time);
end

local frame = CreateFrame("FRAME");
WeakAuras.frames["WeakAuras Buff2 Frame"] = frame;
frame:RegisterEvent("UNIT_AURA");
frame:RegisterUnitEvent("UNIT_PET", "player")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED");
frame:RegisterEvent("PLAYER_TARGET_CHANGED");
frame:SetScript("OnEvent", function (frame, event, arg1, arg2, ...)
  WeakAuras.StartProfileSystem("bufftrigger2");
  if(event == "PLAYER_TARGET_CHANGED") then
    ScanUnit("target");
  elseif(event == "PLAYER_FOCUS_CHANGED") then
    ScanUnit("focus");
  elseif(event == "UNIT_PET") then
    ScanUnit("pet")
  elseif(event == "UNIT_AURA") then
    ScanUnit(arg1);
  end
  WeakAuras.StopProfileSystem("bufftrigger2");
end);

function BuffTrigger.ScanAll(recentlyLoaded)
  -- TODO optimize based on recentlyLoaded ?

  local units = {};

  for unit in pairs(scanFuncName) do
    units[unit] = true;
  end
  for unit in pairs(scanFuncSpellId) do
    units[unit] = true;
  end

  for unit in pairs(scanFuncGeneral) do
    units[unit] = true;
  end

  for unit in pairs(units) do
    ScanUnit(unit);
  end
end

function BuffTrigger.UnloadAll()
  wipe(scanFuncName)
  wipe(scanFuncSpellId)
  wipe(scanFuncGeneral)
  wipe(matchData);
  wipe(matchDataByTrigger);
end

local function LoadAura(id, triggernum, triggerInfo)
  local added = false;
  local filter = triggerInfo.debuffType;
  if (triggerInfo.ownOnly) then
    filter = filter .. "|PLAYER";
  end

  print("LoadAura ", triggerInfo.id, " ", triggerInfo.unit, " ", filter,  " ", triggerInfo.auranames);

  if (triggerInfo.auranames) then
    for _, name in ipairs(triggerInfo.auranames) do
      print("  ## ", name);
      if (name ~= "") then
        scanFuncName[triggerInfo.unit]               = scanFuncName[triggerInfo.unit] or {};
        scanFuncName[triggerInfo.unit][filter]       = scanFuncName[triggerInfo.unit][filter] or {};
        scanFuncName[triggerInfo.unit][filter][name] = scanFuncName[triggerInfo.unit][filter][name] or {};
        tinsert(scanFuncName[triggerInfo.unit][filter][name], triggerInfo);

        added = true;
      end
    end
  end

  if (triggerInfo.auraspellids) then
    for _, spellIdString in ipairs(triggerInfo.auraspellids) do
      if (spellIdString ~= "") then
        local spellId = tonumber(spellIdString);
        if (spellId) then
          scanFuncSpellId[triggerInfo.unit]                  = scanFuncSpellId[triggerInfo.unit] or {};
          scanFuncSpellId[triggerInfo.unit][filter]          = scanFuncSpellId[triggerInfo.unit][filter] or {};
          scanFuncSpellId[triggerInfo.unit][filter][spellId] = scanFuncSpellId[triggerInfo.unit][filter][spellId] or {};
          tinsert(scanFuncSpellId[triggerInfo.unit][filter][spellId], triggerInfo);
        end
        added = true;
      end
    end
  end

  if (not added) then
    scanFuncGeneral[triggerInfo.unit]                  = scanFuncGeneral[triggerInfo.unit] or {};
    scanFuncGeneral[triggerInfo.unit][filter]          = scanFuncGeneral[triggerInfo.unit][filter] or {};
    tinsert(scanFuncGeneral[triggerInfo.unit][filter], triggerInfo);
  end

  -- sets initial states up
  if (triggerInfo.matchesShowOn ~= "showOnActive") then
    UpdateTriggerState(GetTime(), id, triggernum);
  end
end

function BuffTrigger.LoadDisplay(id)
  if (triggerInfos[id]) then
    for triggernum, triggerInfo in pairs(triggerInfos[id]) do
      LoadAura(id, triggernum, triggerInfo);
    end
  end
end

local function UnloadAura(scanFuncName, id)
  for unit, unitData in pairs(scanFuncName) do
    for debuffType, debuffData in pairs(unitData) do
      for name, nameData in pairs(debuffData) do
        for i = #nameData, 1, -1 do
          if nameData[i].id == id then
            if (nameData[i].nextScheduledCheckHandle) then
              timer:CancelTimer(nameData[i].nextScheduledCheckHandle);
            end
            tremove(nameData, i);
          end
        end
        if (#nameData == 0) then
          debuffData[name] = nil;
        end
      end

      if (not next(debuffData)) then
        unitData[debuffType] = nil;
      end
    end
    if (not next(unitData)) then
      scanFuncName[unit] = nil;
    end
  end
end

local function UnloadGeneral(scanFuncGeneral, id)
  for unit, unitData in pairs(scanFuncName) do
    for debuffType, debuffData in pairs(unitData) do
      for i = #debuffData, 1, -1 do
        if debuffData[i].id == id then
          if (debuffData[i].nextScheduledCheckHandle) then
            timer:CancelTimer(debuffData[i].nextScheduledCheckHandle);
          end
          tremove(debuffData, i);
        end
      end
      if (#debuffData == 0) then
        unitData[debuffType] = nil;
      end
    end
    if (not next(unitData)) then
      scanFuncName[unit] = nil;
    end
  end
end

function BuffTrigger.UnloadDisplay(id)
  UnloadAura(scanFuncName, id);
  UnloadAura(scanFuncSpellId, id);
  UnloadGeneral(scanFuncGeneral, id);

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
  triggerInfos[id] = nil;
end

--- Updates all data for aura oldid to use newid
-- @param oldid
-- @param newid

function BuffTrigger.Rename(oldid, newid)
  triggerInfos[newid] = triggerInfos[oldid];
  triggerInfos[oldid] = nil;

  matchDataByTrigger[newid] = matchDataByTrigger[oldid];
  matchDataByTrigger[oldid] = nil;

  for unit, unitData in pairs(matchData) do
    for filter, filterData in pairs(unitData) do
      filterData[newid] = filterData[oldid];
      filterData[oldid] = nil;
    end
  end
end

local function createScanFunc(trigger)
  if (not trigger.useStacks and trigger.use_stealable == nil and not trigger.use_debuffClass) then
    return nil;
  end
  local ret = [[
    return function(name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable)
  ]];

  if (trigger.useStacks) then
    local ret2 = [[
      if not(stacks %s %s) then
        return false
      end
    ]]
    ret = ret .. ret2:format(trigger.stacksOperator or ">=", tonumber(trigger.stacks) or 0);
  end

  if (trigger.use_stealable) then
    ret = ret .. [[
      if (not isStealable) then
        return false
      end
    ]]
  elseif(trigger.use_stealable == false) then
    ret = ret .. [[
      if (isStealable) then
        return false
      end
    ]]
  end

  if (trigger.use_debuffClass and trigger.debuffClass) then
    local ret2 = [[
      if (debuffClass ~= %q) then
        return false;
      end
    ]]
    ret = ret .. ret2:format(trigger.debuffClass);
  end

  ret = ret .. [[
      return true
    end
  ]];

  local func, err = loadstring(ret);

  if (func) then
    return func();
  end
end

--- Adds an aura, setting up internal data structures for all buff triggers.
-- @param data
function BuffTrigger.Add(data)
  local id = data.id;

  triggerInfos[id] = nil;
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger
    if (trigger.type == "aura2") then

      local effectiveShowOn = trigger.matchesShowOn or  "showOnActive";
      local effectiveShowClones = effectiveShowOn == "showOnActive" and trigger.showClones;

      local scanFunc = effectiveShowOn == "showOnActive" and createScanFunc(trigger);

      local remFunc;
      if (effectiveShowOn == "showOnActive" and trigger.useRem) then
        local remFuncStr = WeakAuras.function_strings.count:format(trigger.remOperator or ">=", tonumber(trigger.rem) or 0);
        remFunc = WeakAuras.LoadFunction(remFuncStr);
      end

      local names;
      if (trigger.useName and trigger.auranames) then
        names = {};
        for i = 1, 9 do
          local spellId = tonumber(trigger.auranames[i]);
          names[i] = GetSpellInfo(spellId) or trigger.auranames[i];
        end
      end

      local triggerInformation = {
        auranames = names,
        auraspellids = trigger.useExactSpellId and trigger.auraspellids,
        unit = trigger.unit,
        debuffType = trigger.debuffType,
        ownOnly = trigger.ownOnly,
        showClones = effectiveShowClones,
        matchesShowOn = effectiveShowOn,
        scanFunc = scanFunc,
        remainingFunc = remFunc,
        remainingCheck = effectiveShowOn == "showOnActive" and trigger.useRem and tonumber(trigger.rem) or 0,
        id = id,
        triggernum = triggernum,
      };
      triggerInfos[id] = triggerInfos[id] or {};
      triggerInfos[id][triggernum] = triggerInformation;
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
  local trigger = data.triggers[triggernum].trigger

  local effectiveShowOn = trigger.matchesShowOn or  "showOnActive";
  local effectiveShoWClones = effectiveShowOn == "showOnActive" and trigger.showClones;

  if (not effectiveShoWClones) then
    ret = ret .. "|cFFFF0000%totalCount|r -" .. L["Total Matches"] .. "\n";
  end
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

  -- TODO add buffed condition

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


function WeakAuras.CanConvertBuffTrigger2(trigger)
  if (trigger.type ~= "aura") then
    return false;
  end

  if (trigger.unit == "multi") then
    return false, L["Multi triggers can't be converted yet."];
  end

  -- Specific unit
  if (trigger.unit == "member") then
    return false, L["Specific unit can't be converted yet."];
  end

  if (trigger.unit == "group") then
    return false, L["Group triggers can't be converted yet."];
  end

  if (trigger.fullscan) then
    if (trigger.use_name and trigger.name_operator ~= "==") then
      return false, L["Fullscan auras with pattern matching can't be converted yet."];
    end

    if (trigger.use_tooltip) then
      return false, L["Fullscan auras with tooltip scanning can't be converted yet."];
    end

    if (trigger.use_name and trigger.use_spellId) then
      return false, L["Fullscan auras checking for both name and spell id can't be converted."];
    end

    if (trigger.subcount) then
      return false, L["Fullscan auras scanning the tooltip can't be converted yet."];
    end
  end

  -- Unit Exists
  if (trigger.unit ~= "player") then
    if (trigger.buffShowOn == "showOnActive" and trigger.unitExists) then
      return false, L["Unit exists checks can't be converted yet"];
    end

    if (trigger.buffShowOn == "showOnMissing" and not trigger.unitExists) then
      return false, L["Unit exists checks can't be converted yet."];
    end

    if (trigger.buffShowOn == "showAlways" and not trigger.unitExists) then
      return false, L["Unit exists checks can't be converted yet."];
    end
  end
  return true;
end

function WeakAuras.ConvertBuffTrigger2(trigger)
  if (not WeakAuras.CanConvertBuffTrigger2(trigger)) then
    return;
  end
  trigger.type = "aura2";

  if (trigger.fullscan and trigger.autoclone) then
    trigger.showClones = true;
  else
    trigger.showClones = false;
  end

  if (trigger.fullscan and trigger.use_stealable) then
    trigger.use_stealable = true;
  else
    trigger.use_stealable = nil;
  end

  if (trigger.fullscan and trigger.use_debuffClass and trigger.debuffClass) then
  else
    trigger.use_debuffClass = false;
  end

  if (trigger.fullscan) then
    -- Use name from fullscan
    if (trigger.use_name) then
      if (trigger.name_operator == "==") then
        -- Convert to normal name check
        trigger.useName = true;
        trigger.auranames = {};
        trigger.auranames[1] = trigger.name;
      end
    end
    if (trigger.use_spellId) then
      trigger.useExactSpellId = true;
      trigger.auraspellids = {};
      trigger.auraspellids[1] = trigger.spellId;
    end
  else
    trigger.useName = true;
  end

  if (not trigger.fullscan and trigger.unit ~= "multi") then
    trigger.auranames = {}
    for i = 1, 9 do
      trigger.auranames[i] = trigger.spellIds[i] and tostring(trigger.spellIds[i]) or trigger.names[i]
    end
  end

  -- debuffType is exactly the same, no need to touch it
  -- remaining is exactly the same for now;
  --   needs to be cleared once multi conversion is possible
  -- ownOnly is exactly the same

  if (trigger.useCount) then
    trigger.useStacks = trigger.useCount;
    trigger.stacksOperator = trigger.countOperator;
    trigger.stacks = trigger.count;
  end

  if (trigger.fullscan and trigger.autoclone) then
    trigger.matchesShowOn = "showOnActive";
  else
    trigger.matchesShowOn = trigger.buffShowOn;
  end
end

WeakAuras.RegisterTriggerSystem({"aura2"}, BuffTrigger);
