--[[ BuffTrigger2.lua
This file contains the "aura2" trigger for buffs and debuffs. It is intended to replace
the buff trigger old BuffTrigger at some future point

It registers the BuffTrigger table for the trigger type "aura2" and has the following API:

Add(data)
Adds an aura, setting up internal data structures for all buff triggers.

LoadDisplays(id)
Loads the aura ids, enabling all buff triggers in the aura.

UnloadDisplays(id)
Unloads the aura ids, disabling all buff triggers in the aura.

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
local scanFuncName = {};
local scanFuncSpellId = {};
local scanFuncGeneral = {};

local scanFuncNameGroup = {};
local scanFuncSpellIdGroup = {};
local scanFuncGeneralGroup = {};

local unitExistScanFunc = {};
local existingUnits = {};

local timer = WeakAuras.timer;

-- Auras that matched, unit, index
local matchData = {};
-- Auras that matched, keyed on id, triggernum, kept in sync with matchData
local matchDataByTrigger = {};

local matchDataChanged = {};

local function ReferenceMatchData(id, triggernum, unit, filter, index)
  local match = matchData[unit][filter][index];

  matchDataByTrigger[id] = matchDataByTrigger[id] or {};
  matchDataByTrigger[id][triggernum] = matchDataByTrigger[id][triggernum] or {};
  matchDataByTrigger[id][triggernum][unit] = matchDataByTrigger[id][triggernum][unit] or {};
  matchDataByTrigger[id][triggernum][unit][index] = match;

  match.auras[id] = match.auras[id] or {}
  match.auras[id][triggernum] = true;
end

local function UpdateToolTipDataInMatchData(matchData, time)
  if (matchData.tooltipUpdated == time) then
    return;
  end

  if (matchData.unit and matchData.index and matchData.filter) then
    local _;
    matchData.tooltip, _, matchData.tooltip1, matchData.tooltip2, matchData.tooltip3 = WeakAuras.GetAuraTooltipInfo(matchData.unit, matchData.index, matchData.filter);
  end

  matchData.tooltipUpdated = time;
end

local function UpdateMatchData(time, matchDataChanged, resetMatchDataByTrigger, unit, index, filter, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
  if (not matchData[unit]) then
    matchData[unit] = {};
  end
  if (not matchData[unit][filter]) then
    matchData[unit][filter] = {};
  end
  if (not matchData[unit][filter][index]) then
    matchData[unit][filter][index] = {
      name = name,
      icon = icon,
      stacks = stacks,
      duration = duration,
      expirationTime = expirationTime,
      unitCaster = unitCaster,
      spellId = spellId,
      unit = unit,
      time = time,
      unit = unit,
      filter = filter,
      index = index,
      UpdateTooltip = UpdateToolTipDataInMatchData,
      auras = {};
    };
    return true;
  end

  local data = matchData[unit][filter][index];

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

  if (changed or resetMatchDataByTrigger) then
    -- Tell old auras that used this match data
    for id, triggerData in pairs(data.auras) do
      for triggernum in pairs(triggerData) do
        if (matchDataByTrigger[id] and matchDataByTrigger[id][triggernum] and matchDataByTrigger[id][triggernum][unit] and matchDataByTrigger[id][triggernum][unit][index]) then
          matchDataByTrigger[id][triggernum][unit][index] = nil;
          matchDataChanged[id] = matchDataChanged[id] or {};
          matchDataChanged[id][triggernum] = true;
        end
      end
    end
    wipe(data.auras);
  end

  data.index = index;
  data.time = time;
  data.unit = unit;

  return changed or resetMatchDataByTrigger;
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
  local bestMatch = nil;

  local totalCount = 0;
  local unitCount = 0;
  local nextCheck

  if (not matchDataByTrigger[id] or not matchDataByTrigger[id][triggernum]) then
    return nil, 0, 0;
  end

  for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
    local unitCounted = false;
    for index, auraData in pairs(unitData) do
      local remCheck = true;
      if (triggerInfo.remainingFunc and auraData.expirationTime) then
        local remaining = auraData.expirationTime - time;
        remCheck = triggerInfo.remainingFunc(remaining);
        nextCheck = calculateNextCheck(triggerInfo.remainingCheck, remaining, auraData.expirationTime, nextCheck)
      end

      if (remCheck) then
        totalCount = totalCount + 1;
        if (not unitCounted) then
          unitCount = unitCount + 1;
          unitCounted = true;
        end
        if (not bestMatch or triggerInfo.compareFunc(bestMatch, auraData)) then
          bestMatch = auraData;
        end
      end
    end
  end
  return bestMatch, totalCount, unitCount, nextCheck;
end

local function FindBestMatchDataForUnit(time, id, triggernum, triggerInfo, unit)
  -- Find best match
  local bestMatch = nil;

  local totalCount = 0;
  local nextCheck

  if (not matchDataByTrigger[id] or not matchDataByTrigger[id][triggernum] or not matchDataByTrigger[id][triggernum][unit]) then
    return nil, 0;
  end

  for index, auraData in pairs(matchDataByTrigger[id][triggernum][unit]) do
    local remCheck = true;
    if (triggerInfo.remainingFunc and auraData.expirationTime) then
      local remaining = auraData.expirationTime - time;
      remCheck = triggerInfo.remainingFunc(remaining);
      nextCheck = calculateNextCheck(triggerInfo.remainingCheck, remaining, auraData.expirationTime, nextCheck)
    end

    if (remCheck) then
      totalCount = totalCount + 1;
      if (not bestMatch or triggerInfo.compareFunc(bestMatch, auraData)) then
        bestMatch = auraData;
      end
    end
  end
  return bestMatch, totalCount, nextCheck;
end

local function UpdateStateWithMatch(time, bestMatch, triggerStates, cloneId, totalCount, unitCount)
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
      unitCount = unitCount,
      tooltip = bestMatch.tooltip,
      tooltip1 = bestMatch.tooltip1,
      tooltip2 = bestMatch.tooltip2,
      tooltip3 = bestMatch.tooltip3,
      active = true,
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

    --
    if (state.tooltip ~= bestMatch.tooltip) then
      state.tooltip = bestMatch.tooltip;
      changed = true;
    end
    if (state.tooltip1 ~= bestMatch.tooltip1) then
      state.tooltip1 = bestMatch.tooltip1;
      changed = true;
    end
    if (state.tooltip2 ~= bestMatch.tooltip2) then
      state.tooltip2 = bestMatch.tooltip2;
      changed = true;
    end
    if (state.tooltip3 ~= bestMatch.tooltip3) then
      state.tooltip3 = bestMatch.tooltip3;
      changed = true;
    end

    if (state.totalCount ~= totalCount) then
      state.totalCount = totalCount;
      changed = true;
    end

    if (state.unitCount ~= unitCount) then
      state.unitCount = unitCount;
      changed = true;
    end

    if (state.active ~= true) then
      state.active = true;
      changed = true;
    end

    if (changed) then
      state.changed = true;
      return true;
    end
  end
end

local function UpdateStateWithNoMatch(time, triggerStates, cloneId, totalCount, unitCount)
  if (not triggerStates[cloneId]) then
    triggerStates[cloneId] = {
      show = true,
      changed = true,
      totalCount = 0,
      progressType = 'timed',
      duration = 0,
      expirationTime = math.huge,
      totalCount = totalCount,
      unitCount = unitCount,
      active = false,
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

    if (state.totalCount ~= totalCount) then
      state.totalCount = totalCount;
      changed = true;
    end

    if (state.unitCount ~= unitCount) then
      state.unitCount = unitCount;
      changed = true;
    end

    if (state.active) then
      state.active = false;
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

local function allUnits(unit)
  if (unit == "group") then
    if (IsInRaid()) then
      local i = 1;
      local max = GetNumGroupMembers();
      return function()
        if (i <= max) then
          local ret = "raid" .. i;
          i = i + 1;
          return i;
        end
        i = 1;
      end
    else
      local i = 0;
      local max = GetNumSubgroupMembers();
      return function()
        if (i == 0) then
          i = 1;
          return "player";
        else
          if (i <= max) then
            local ret = "party" .. i;
            i = i + 1;
            return ret;
          end
        end
        i = 0;
      end
    end
  elseif (unit == "boss" or unit == "arena" or "nameplate") then
    local i = 1;
    local max;
    if (unit == "boss") then
      max = 4;
    elseif(unit == "arena") then
      max = 5;
    elseif(unit == "nameplate") then
      max = 40;
    end
    return function()
      local ret = unit .. i;
      while (not UnitExists(ret)) do
        i = i + 1;
        if (i > max) then
          i = 1;
          return nil;
        end
        ret = unit .. i;
      end
      i = i + 1;
      return ret;
    end
  end
end

local function UpdateTriggerState(time, id, triggernum)
  local triggerStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);

  local triggerInfo = triggerInfos[id][triggernum];
  local updated;
  local nextCheck;
  local totalCount = 0;
  local unitCount = 0;
  local auraDatas = {};
  if (triggerInfo.matchesShowOn == "showOnMissing") then
    local anyMatch = false;
    if (matchDataByTrigger[id] and matchDataByTrigger[id][triggernum]) then
      for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
        if (next(unitData)) then
          anyMatch = true;
          break;
        end
      end
    end
    if(anyMatch) then
      updated = RemoveState(triggerStates, "");
    else
      updated = UpdateStateWithNoMatch(time, triggerStates, "", 0, 0);
    end
  elseif (triggerInfo.combineMode == "showClones") then
    if (matchDataByTrigger[id] and matchDataByTrigger[id][triggernum]) then
      for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
        local unitCounted = false;
        for index, auraData in pairs(unitData) do
          local remCheck = true;
          if (triggerInfo.remainingFunc and auraData.expirationTime) then
            local remaining = auraData.expirationTime - time;
            remCheck = triggerInfo.remainingFunc(remaining);
            nextCheck = calculateNextCheck(triggerInfo.remainingCheck, remaining, auraData.expirationTime, nextCheck)
          end

          if (remCheck) then
            tinsert(auraDatas, auraData)
            totalCount = totalCount + 1;
            if (not unitCounted) then
              unitCount = unitCount + 1;
              unitCounted = true;
            end
          end
        end
      end
    end

    for _, auraData in ipairs(auraDatas) do
      local cloneId = tostring(auraData);
      updated = UpdateStateWithMatch(time, auraData, triggerStates, cloneId, totalCount, unitCount) or updated;
    end

    if(totalCount == 0 and (triggerInfo.matchesShowOn == "showAlways" and (existingUnits[triggerInfo.unit] or triggerInfo.groupTrigger)
                              or triggerInfo.unitExists and not existingUnits[triggerInfo.unit])) then
      updated = UpdateStateWithNoMatch(time, triggerStates, "", 0, 0) or updated;
    end

    for cloneId, state in pairs(triggerStates) do
      if (state.show and state.time < time) then
        updated = RemoveState(triggerStates, cloneId) or updated;
      end
    end
  elseif (triggerInfo.combineMode == "showLowest" or triggerInfo.combineMode == "showHighest") then -- ONE Aura
    local bestMatch, totalCount, unitCount
    bestMatch, totalCount, unitCount, nextCheck = FindBestMatchData(time, id, triggernum, triggerInfo);
    local cloneId = "";

    if (bestMatch) then
      updated = UpdateStateWithMatch(time, bestMatch, triggerStates, cloneId, totalCount, unitCount);
    elseif (triggerInfo.matchesShowOn == "showAlways" and triggerInfo.groupTrigger) then
      updated = UpdateStateWithNoMatch(time, triggerStates, cloneId, 0, 0);
    elseif (not existingUnits[triggerInfo.unit]) then -- Unit does not exist
      if (triggerInfo.unitExists) then
        updated = UpdateStateWithNoMatch(time, triggerStates, cloneId, 0, 0);
      else
        updated = RemoveState(triggerStates, cloneId);
      end
    else -- No best match, but unit exists
      if (triggerInfo.matchesShowOn == "showOnActive") then
        updated = RemoveState(triggerStates, cloneId);
      end
    end
  elseif (triggerInfo.combineMode == "showLowestPerUnit" or triggerInfo.combineMode == "showHighestPerUnit") then -- ONE AURA per unit
    if (matchDataByTrigger[id] and matchDataByTrigger[id][triggernum]) then
      local iterFunc, iterState;
      if (triggerInfo.matchesShowOn == "showOnActive") then
        iterFunc, iterState = pairs(matchDataByTrigger[id][triggernum]);
      else
        iterFunc = allUnits(triggerInfo.unit);
      end

      local matches = {};

      local totalCount = 0;
      local unitCount = 0;

      for unit, unitData in iterFunc, iterState do
        local bestMatch, totalCountPerUnit, nextCheckForMatch = FindBestMatchDataForUnit(time, id, triggernum, triggerInfo, unit);
        totalCount = totalCount + totalCountPerUnit;
        if (bestMatch) then
          unitCount = unitCount + 1;
        end
        if (not nextCheck) then
          nextCheck = nextCheckForMatch
        elseif (nextCheckForMatch) then
          nextCheck = min(nextCheck, nextCheckForMatch);
        end
        matches[unit] = bestMatch;
      end

      for unit, unitData in iterFunc, iterState do
        local cloneId = unit;
        local bestMatch = matches[unit];
        if (bestMatch) then
          updated = UpdateStateWithMatch(time, bestMatch, triggerStates, cloneId, totalCount, unitCount) or updated;
        elseif (triggerInfo.matchesShowOn == "showAlways") then
          updated = UpdateStateWithNoMatch(time, triggerStates, cloneId, totalCount, unitCount) or updated;
        end
      end
    else
      if (triggerInfo.matchesShowOn == "showAlways") then
        for unit, unitData in allUnits(triggerInfo.unit) do
          updated = UpdateStateWithNoMatch(time, triggerStates, unit, 0, 0) or updated;
        end
      end
    end

    for cloneId, state in pairs(triggerStates) do
      if (state.show and state.time < time) then
        updated = RemoveState(triggerStates, cloneId) or updated;
      end
    end
  end

  if (updated) then
    WeakAuras.UpdatedTriggerState(id);
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
  matchDataChanged[triggerInfo.id] = matchDataChanged[triggerInfo.id] or {};
  matchDataChanged[triggerInfo.id][triggerInfo.triggernum] = true;
  triggerInfo.nextScheduledCheckHandle = nil;
  triggerInfo.nextScheduledCheck = nil;
end

local function ScanUnitWithFilter(matchDataChanged, time, unit, filter, scanFuncName, scanFuncSpellId, scanFuncGeneral, resetMatchDataByTrigger)
  if (not scanFuncName) and (not scanFuncSpellId) and (not scanFuncGeneral) then
    return;
  end

  local index = 1;
  while(true) do
    local name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, index, filter);
    if (not name) then
      break;
    end

    if (debuffClass == nil) then
      debuffClass = "none";
    elseif (debuffClass == "") then
      debuffClass = "enrage"
    else
      debuffClass = string.lower(debuffClass);
    end

    local updatedMatchData = UpdateMatchData(time, matchDataChanged, resetMatchDataByTrigger, unit, index, filter, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId);

    if (updatedMatchData) then -- Aura data changed, check against triggerInfos
      local auras = scanFuncName and scanFuncName[name];
      if (auras) then
        for _, triggerInfo in pairs(auras) do
          if (triggerInfo.fetchTooltip) then
            matchData[unit][filter][index]:UpdateTooltip(time);
          end
          if ((not triggerInfo.scanFunc) or triggerInfo.scanFunc(time, matchData[unit][filter][index])) then
            local id = triggerInfo.id;
            local triggernum = triggerInfo.triggernum
            ReferenceMatchData(id, triggernum, unit, filter, index);
            matchDataChanged[id] = matchDataChanged[id] or {};
            matchDataChanged[id][triggernum] = true;
          end
        end
      end

      auras = scanFuncSpellId and scanFuncSpellId[spellId];
      if (auras) then
        for _, triggerInfo in pairs(auras) do
          if (triggerInfo.fetchTooltip) then
            matchData[unit][filter][index]:UpdateTooltip(time);
          end
          if ((not triggerInfo.scanFunc) or triggerInfo.scanFunc(time, matchData[unit][filter][index])) then
            local id = triggerInfo.id;
            local triggernum = triggerInfo.triggernum;
            ReferenceMatchData(id, triggernum, unit, filter, index);
            matchDataChanged[id] = matchDataChanged[id] or {};
            matchDataChanged[id][triggernum] = true;
          end
        end
      end

      if (scanFuncGeneral) then
        for _, triggerInfo in pairs(scanFuncGeneral) do
          if (triggerInfo.fetchTooltip) then
            matchData[unit][filter][index]:UpdateTooltip(time);
          end
          if ((not triggerInfo.scanFunc) or triggerInfo.scanFunc(time, matchData[unit][filter][index])) then
            local id = triggerInfo.id;
            local triggernum = triggerInfo.triggernum;
            ReferenceMatchData(id, triggernum, unit, filter, index);
            matchDataChanged[id] = matchDataChanged[id] or {};
            matchDataChanged[id][triggernum] = true;
          end
        end
      end
    end
    index = index + 1;
  end

  -- Figure out if any matchData is outdated
  if (matchData[unit] and matchData[unit][filter]) then
    for index, data in pairs(matchData[unit][filter]) do
      if (data.time < time) then
         matchData[unit][filter][index] = nil;
         for id, triggerData in pairs(data.auras) do
           for triggernum in pairs(triggerData) do
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

local function TriggerInfoApplies(triggerInfo, isSelf, role)
  if (triggerInfo.ignoreSelf and isSelf) then
    return false;
  end
  if (triggerInfo.groupRole and triggerInfo.groupRole ~= role) then
    return false;
  end
  return true;
end

local function FilterScanFuncsHelper(input, isSelf, role)
  if (not input) then
    return nil;
  end
  local result = {};
  for name, nameData in pairs(input) do
    result[name] = {};
    for index, triggerInfo in ipairs(nameData) do
      if (TriggerInfoApplies(triggerInfo, isSelf, role)) then
        tinsert(result[name], triggerInfo);
      end
    end
  end
  return result;
end

local function FilterGeneralScanFuncsHelper(input, isSelf, role)
  if (not input) then
    return nil;
  end
  local result = {};
  for index, triggerInfo in ipairs(input) do
    if (TriggerInfoApplies(triggerInfo, isSelf, role)) then
      tinsert(result, triggerInfo);
    end
  end
  return result;
end

local function FilterScanFuncs(input, unit, isSelf, role)
  local result = {};
  result["HELPFUL"] = FilterScanFuncsHelper(input["group"] and input["group"]["HELPFUL"], isSelf, role);
  result["HARMFUL"] = FilterScanFuncsHelper(input["group"] and input["group"]["HARMFUL"], isSelf, role);
  return result;
end

local function FilterGeneralScanFuncs(input, unit, isSelf, role)
  local result = {};
  result["HELPFUL"] = FilterGeneralScanFuncsHelper(input["group"] and input["group"]["HELPFUL"], isSelf, role);
  result["HARMFUL"] = FilterGeneralScanFuncsHelper(input["group"] and input["group"]["HARMFUL"], isSelf, role);
  return result;
end

local function ScanGroupUnit(time, matchDataChanged, unitType, unit, resetMatchDataByTrigger)
  if (WeakAuras.IsPaused()) then
    return;
  end
  local unitExists = UnitExists(unit);
  if (existingUnits[unit] ~= unitExists) then
    existingUnits[unit] = unitExists;

    if (unitExistScanFunc[unit]) then
      for id, idData in pairs(unitExistScanFunc[unit]) do
        matchDataChanged[id] = matchDataChanged[id] or {};
        for _, triggerInfo in ipairs(idData) do
          matchDataChanged[id][triggerInfo.triggernum] = true;
        end
      end
    end
  end

  if (unitType ~= "group") then
    scanFuncName[unitType] = scanFuncName[unitType] or {};
    scanFuncSpellId[unitType] = scanFuncSpellId[unitType] or {};
    scanFuncGeneral[unitType] = scanFuncGeneral[unitType] or {};

    ScanUnitWithFilter(matchDataChanged, time, unit, "HELPFUL",
        scanFuncName[unitType]["HELPFUL"],
        scanFuncSpellId[unitType]["HELPFUL"],
        scanFuncGeneral[unitType]["HELPFUL"],
        resetMatchDataByTrigger);

    ScanUnitWithFilter(matchDataChanged, time, unit, "HARMFUL",
        scanFuncName[unitType]["HARMFUL"],
        scanFuncSpellId[unitType]["HARMFUL"],
        scanFuncGeneral[unitType]["HARMFUL"],
        resetMatchDataByTrigger);
  else
    scanFuncNameGroup[unit] = scanFuncNameGroup[unit] or {};
    scanFuncSpellIdGroup[unit] = scanFuncSpellIdGroup[unit] or {};
    scanFuncGeneralGroup[unit] = scanFuncGeneralGroup[unit] or {};

    ScanUnitWithFilter(matchDataChanged, time, unit, "HELPFUL",
        scanFuncNameGroup[unit]["HELPFUL"],
        scanFuncSpellIdGroup[unit]["HELPFUL"],
        scanFuncGeneralGroup[unit]["HELPFUL"],
        resetMatchDataByTrigger);

    ScanUnitWithFilter(matchDataChanged, time, unit, "HARMFUL",
        scanFuncNameGroup[unit]["HARMFUL"],
        scanFuncSpellIdGroup[unit]["HARMFUL"],
        scanFuncGeneralGroup[unit]["HARMFUL"],
        resetMatchDataByTrigger);
  end
end

local function UpdatePerGroupUnitScanFuncs()
  if (IsInRaid()) then
    for i = 1, 40 do
      local unit = "raid" .. i;
      if (not UnitExists(unit)) then
        scanFuncNameGroup[unit] = nil;
      else
        local isSelf = UnitIsUnit("player", unit);
        local role = UnitGroupRolesAssigned(unit);
        scanFuncNameGroup[unit] = FilterScanFuncs(scanFuncName, unit, isSelf, role);
        scanFuncSpellIdGroup[unit] = FilterScanFuncs(scanFuncSpellId, unit);
        scanFuncGeneralGroup[unit] = FilterGeneralScanFuncs(scanFuncGeneral, unit);
      end
    end
  else
    local unit = "player";
    local role = UnitGroupRolesAssigned(unit);
    scanFuncNameGroup[unit] = FilterScanFuncs(scanFuncName, unit, true, role);
    scanFuncSpellIdGroup[unit] = FilterScanFuncs(scanFuncSpellId, unit, true, role);
    scanFuncGeneralGroup[unit] = FilterGeneralScanFuncs(scanFuncGeneral, unit, true, role);
    for i = 1, 4 do
      unit = "party" .. i;
      if (not UnitExists(unit)) then
        scanFuncNameGroup[unit] = nil;
      else
        local isSelf = UnitIsUnit("player", unit);
        local role = UnitGroupRolesAssigned(unit);
        scanFuncNameGroup[unit] = FilterScanFuncs(scanFuncName, unit, isSelf, role);
        scanFuncSpellIdGroup[unit] = FilterScanFuncs(scanFuncSpellId, unit, isSelf, role);
        scanFuncGeneralGroup[unit] = FilterGeneralScanFuncs(scanFuncGeneral, unit, isSelf, role);
      end
    end
  end
end

local function ScanAllGroup(time, matchDataChanged, resetMatchDataByTrigger)
  -- We iterate over all raid/player unit ids here because ScanGroupUnit also
  -- handles the cases where a unit existance changes. That could be optimized
  if (IsInRaid()) then
    for i = 1, 40 do
      ScanGroupUnit(time, matchDataChanged, "group", "raid" .. i, resetMatchDataByTrigger);
    end
  else
    ScanGroupUnit(time, matchDataChanged, "group", "player", resetMatchDataByTrigger)
    for i = 1, 4 do
      ScanGroupUnit(time, matchDataChanged, "group", "party" .. i, resetMatchDataByTrigger);
    end
  end
end

local function ScanAllBoss(time, matchDataChanged)
  for i = 1,4 do
    ScanGroupUnit(time, matchDataChanged, "boss", "boss" .. i);
  end
end

local frame = CreateFrame("FRAME");
WeakAuras.frames["WeakAuras Buff2 Frame"] = frame;
frame:RegisterEvent("UNIT_AURA");
frame:RegisterUnitEvent("UNIT_PET", "player")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED");
frame:RegisterEvent("PLAYER_TARGET_CHANGED");
frame:RegisterEvent("ENCOUNTER_START");
frame:RegisterEvent("ENCOUNTER_END");
frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT");
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
frame:RegisterEvent("ARENA_OPPONENT_UPDATE");
frame:RegisterEvent("GROUP_ROSTER_UPDATE");
frame:SetScript("OnEvent", function (frame, event, arg1, arg2, ...)
  WeakAuras.StartProfileSystem("bufftrigger2");
  local time = GetTime();
  if(event == "PLAYER_TARGET_CHANGED") then
    ScanGroupUnit(time, matchDataChanged, "target", "target");
  elseif(event == "PLAYER_FOCUS_CHANGED") then
    ScanGroupUnit(time, matchDataChanged, "focus", "focus");
  elseif(event == "UNIT_PET") then
    ScanGroupUnit(time, matchDataChanged, "pet", "pet")
  elseif(event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED") then
    ScanGroupUnit(time, matchDataChanged, "nameplate", arg1);
  elseif(event == "ENCOUNTER_START" or event == "ENCOUNTER_END" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT") then
    ScanAllBoss(time, matchDataChanged);
  elseif (event =="ARENA_OPPONENT_UPDATE") then
    ScanGroupUnit(time, matchDataChanged, "arena", arg1);
  elseif (event == "GROUP_ROSTER_UPDATE") then
    UpdatePerGroupUnitScanFuncs();
    -- We reset matchDataByTrigger here, because of role changes. Tracking
    -- those accurately is possible but feel like it is too much effort for the gain
    -- it brings.
    ScanAllGroup(time, matchDataChanged, true);
  elseif(event == "UNIT_AURA") then
    if (arg1:sub(1,4) == "raid" or arg1:sub(1,5) == "party" or arg1 == "player") then
      ScanGroupUnit(time, matchDataChanged, "group", arg1);
    elseif (arg1:sub(1,4) == "boss") then
      ScanGroupUnit(time, matchDataChanged, "boss", arg1);
    elseif (arg1:sub(1,5) == "arena") then
      ScanGroupUnit(time, matchDataChanged, "arena", arg1);
    elseif (arg1:sub(1, 9) == "nameplate") then
      ScanGroupUnit(time, matchDataChanged, "nameplate", arg1);
    end

    ScanGroupUnit(time, matchDataChanged, arg1, arg1);
  end
  WeakAuras.StopProfileSystem("bufftrigger2");
end);

frame:SetScript("OnUpdate", function()
  WeakAuras.StartProfileSystem("bufftrigger2");
  if (next(matchDataChanged)) then
    local time = GetTime();
    UpdateStates(matchDataChanged, time);
    wipe(matchDataChanged);
  end
  WeakAuras.StopProfileSystem("bufftrigger2");
end);

function BuffTrigger.ScanAll()
  local units = {};
  local time = GetTime();
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
    if (unit == "group") then
      ScanAllGroup(time, matchDataChanged);
    elseif (unit == "boss") then
      ScanAllBoss(time, matchDataChanged);
    elseif(unit == "nameplate") then
      local time = GetTime();
      for i = 1, 40 do
        ScanGroupUnit(time, matchDataChanged, "nameplate", "nameplate" .. i);
      end
    else
      ScanGroupUnit(time, matchDataChanged, unit, unit);
    end
  end
end

local function UnloadAura(scanFuncName, id)
  for unit, unitData in pairs(scanFuncName) do
    for debuffType, debuffData in pairs(unitData) do
      for name, nameData in pairs(debuffData) do
        for i = #nameData, 1, -1 do
          if nameData[i].id == id or not id then
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
  for unit, unitData in pairs(scanFuncGeneral) do
    for debuffType, debuffData in pairs(unitData) do
      for i = #debuffData, 1, -1 do
        if debuffData[i].id == id or not id then
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
      scanFuncGeneral[unit] = nil;
    end
  end
end

function BuffTrigger.UnloadAll()

  UnloadAura(scanFuncName, nil);
  UnloadAura(scanFuncSpellId, nil);
  UnloadGeneral(scanFuncGeneral, nil);

  wipe(scanFuncName);
  wipe(scanFuncSpellId);
  wipe(scanFuncGeneral);
  wipe(scanFuncNameGroup);
  wipe(scanFuncSpellIdGroup);
  wipe(scanFuncGeneralGroup);
  wipe(unitExistScanFunc);
  wipe(matchData);
  wipe(matchDataByTrigger);
end

local function AddScanFuncs(triggerInfo, unit, scanFuncName, scanFuncSpellId, scanFuncGeneral)
  local filter = triggerInfo.debuffType;
  local added = false;
  if (triggerInfo.auranames) then
    for _, name in ipairs(triggerInfo.auranames) do
      if (name ~= "") then
        scanFuncName[unit]               = scanFuncName[unit] or {};
        scanFuncName[unit][filter]       = scanFuncName[unit][filter] or {};
        scanFuncName[unit][filter][name] = scanFuncName[unit][filter][name] or {};
        tinsert(scanFuncName[unit][filter][name], triggerInfo);

        added = true;
      end
    end
  end

  if (triggerInfo.auraspellids) then
    for _, spellIdString in ipairs(triggerInfo.auraspellids) do
      if (spellIdString ~= "") then
        local spellId = tonumber(spellIdString);
        if (spellId) then
          scanFuncSpellId[unit]                  = scanFuncSpellId[unit] or {};
          scanFuncSpellId[unit][filter]          = scanFuncSpellId[unit][filter] or {};
          scanFuncSpellId[unit][filter][spellId] = scanFuncSpellId[unit][filter][spellId] or {};
          tinsert(scanFuncSpellId[unit][filter][spellId], triggerInfo);
        end
        added = true;
      end
    end
  end

  if (not added) then
    scanFuncGeneral[unit]                  = scanFuncGeneral[unit] or {};
    scanFuncGeneral[unit][filter]          = scanFuncGeneral[unit][filter] or {};
    tinsert(scanFuncGeneral[unit][filter], triggerInfo);
  end

  return not added;
end

local function LoadAura(id, triggernum, triggerInfo)
  local filter = triggerInfo.debuffType;

  local generalFunc = AddScanFuncs(triggerInfo, triggerInfo.unit, scanFuncName, scanFuncSpellId, scanFuncGeneral);

  if (triggerInfo.unitExists) then
    unitExistScanFunc[triggerInfo.unit] = unitExistScanFunc[triggerInfo.unit] or {};
    unitExistScanFunc[triggerInfo.unit][id] = unitExistScanFunc[triggerInfo.unit][id] or {}
    tinsert(unitExistScanFunc[triggerInfo.unit][id], triggerInfo);
  end

  -- Update in per group scan funcs
  if (triggerInfo.unit == "group") then
    if (IsInRaid()) then
      for i = 1, 40 do
        local unit = "raid" .. i;
        if (UnitExists(unit)) then
          local isSelf = UnitIsUnit("player", unit);
          local role = UnitGroupRolesAssigned(unit);
          if (TriggerInfoApplies(triggerInfo, isSelf, role)) then
            AddScanFuncs(triggerInfo, unit, scanFuncNameGroup, scanFuncSpellIdGroup, scanFuncGeneralGroup)
          end
        end
      end
    else
      local unit = "player";
      local role = UnitGroupRolesAssigned(unit);
      if (TriggerInfoApplies(triggerInfo, true, role)) then
        AddScanFuncs(triggerInfo, unit, scanFuncNameGroup, scanFuncSpellIdGroup, scanFuncGeneralGroup)
      end
      for i = 1, 4 do
        unit = "party" .. i;
        if (UnitExists(unit)) then
          local isSelf = UnitIsUnit("player", unit);
          local role = UnitGroupRolesAssigned(unit);
          if (TriggerInfoApplies(triggerInfo, isSelf, role)) then
            AddScanFuncs(triggerInfo, unit, scanFuncNameGroup, scanFuncSpellIdGroup, scanFuncGeneralGroup)
          end
        end
      end
    end
  end

  local updateTriggerState = false;
  -- sets initial states up
  if (triggerInfo.matchesShowOn ~= "showOnMissing") then
    -- Check against existing match data
    if (triggerInfo.groupTrigger) then
      for unit in allUnits(triggerInfo.unit) do
        if (matchData[unit] and matchData[unit][filter]) then
          for index, match in pairs(matchData[unit][filter]) do
            if (generalFunc
                or (triggerInfo.auranames and tContains(triggerInfo.auranames, match.name))
                or (triggerInfo.auraspellids and tContains(triggerInfo.auraspellids, match.spellId))) then
              if ((not triggerInfo.scanFunc) or triggerInfo.scanFunc(time, matchData[unit][filter][index])) then
                ReferenceMatchData(id, triggernum, unit, filter, index);
                updateTriggerState = true;
              end
            end
          end
        end
      end
    else
      if (matchData[triggerInfo.unit] and matchData[triggerInfo.unit][filter]) then
        for index, match in pairs(matchData[triggerInfo.unit][filter]) do
          if (generalFunc
              or (triggerInfo.auranames and tContains(triggerInfo.auranames, match.name))
              or (triggerInfo.auraspellids and tContains(triggerInfo.auraspellids, match.spellId))) then
            if ((not triggerInfo.scanFunc) or triggerInfo.scanFunc(time, matchData[triggerInfo.unit][filter][index])) then
              ReferenceMatchData(id, triggernum, triggerInfo.unit, filter, index);
              updateTriggerState = true;
            end
          end
        end
      end
    end
  end

  if (updateTriggerState or triggerInfo.matchesShowOn ~= "showOnActive" or triggerInfo.unitExists or triggerInfo.groupTrigger) then
    matchDataChanged[id] = matchDataChanged[id] or {};
    matchDataChanged[id][triggernum] = true;
  end
end

function BuffTrigger.LoadDisplays(toLoad)
  for id in pairs(toLoad) do
    if (triggerInfos[id]) then
      for triggernum, triggerInfo in pairs(triggerInfos[id]) do
        LoadAura(id, triggernum, triggerInfo);
      end
    end
  end
end

function BuffTrigger.UnloadDisplays(toUnload)
  for id in pairs(toUnload) do
    UnloadAura(scanFuncName, id);
    UnloadAura(scanFuncSpellId, id);
    UnloadGeneral(scanFuncGeneral, id);

    for unit, unitData in pairs(unitExistScanFunc) do
      unitData[id] = nil;
    end

    for unit, unitData in pairs(matchData) do
      for filter, filterData in pairs(unitData) do
        for index, indexData in pairs(filterData) do
          indexData.auras[id] = nil;
        end
      end
    end
    matchDataByTrigger[id] = nil;
  end
end

function BuffTrigger.FinishLoadUnload()
  BuffTrigger.ScanAll();
end

--- Removes all data for an aura id
-- @param id
function BuffTrigger.Delete(id)
  BuffTrigger.UnloadDisplays({[id] = true});
  triggerInfos[id] = nil;
end

--- Updates all data for aura oldid to use newid
-- @param oldid
-- @param newid

function BuffTrigger.Rename(oldid, newid)
  triggerInfos[newid] = triggerInfos[oldid];
  triggerInfos[oldid] = nil;

  if (triggerInfos[newid]) then
    for triggernum, triggerData in pairs(triggerInfos[newid]) do
      triggerData.id = newid;
    end
  end

  matchDataByTrigger[newid] = matchDataByTrigger[oldid];
  matchDataByTrigger[oldid] = nil;

  for unit, unitData in pairs(matchData) do
    for filter, filterData in pairs(unitData) do
      for index, indexData in pairs(filterData) do
        indexData.auras[newid] = indexData.auras[oldid];
        indexData.auras[oldid] = nil;
      end
    end
  end

  for unit, unitData in pairs(unitExistScanFunc) do
    unitData[newid] = unitData[oldid];
    unitData[oldid] = nil;
  end
end

local function effectiveShowOnIsShowOnActive(trigger)
  local effectiveShowOn = true;
  if (trigger.matchesShowOn) then
    effectiveShowOn = trigger.matchesShowOn == "showOnActive";
  end
  return effectiveShowOn;
end


local function createScanFunc(trigger)
  local useStacks = effectiveShowOnIsShowOnActive(trigger) and trigger.useStacks;
  local use_stealable = effectiveShowOnIsShowOnActive(trigger) and trigger.use_stealable;
  local use_debuffClass = effectiveShowOnIsShowOnActive(trigger) and trigger.use_debuffClass;
  local use_tooltip = effectiveShowOnIsShowOnActive(trigger) and trigger.fetchTooltip and trigger.use_tooltip;
  local use_tooltipValue = effectiveShowOnIsShowOnActive(trigger) and trigger.fetchTooltip and trigger.use_tooltipValue;

  if (not useStacks and use_stealable == nil and not use_debuffClass and trigger.ownOnly == nil and not use_tooltip and not use_tooltipValue and not trigger.useNamePattern) then
    return nil;
  end
  local ret = [[
    return function(time, matchData)
  ]];

  if (useStacks) then
    local ret2 = [[
      if not(matchData.stacks %s %s) then
        return false
      end
    ]]
    ret = ret .. ret2:format(trigger.stacksOperator or ">=", tonumber(trigger.stacks) or 0);
  end

  if (use_stealable) then
    ret = ret .. [[
      if (not matchData.isStealable) then
        return false
      end
    ]]
  elseif(use_stealable == false) then
    ret = ret .. [[
      if (matchData.isStealable) then
        return false
      end
    ]]
  end

  if (use_debuffClass and trigger.debuffClass) then
    local ret2 = [[
      if (matchData.debuffClass ~= %q) then
        return false;
      end
    ]]
    ret = ret .. ret2:format(trigger.debuffClass);
  end

  if (trigger.ownOnly) then
    ret = ret .. [[
      if (matchData.unitCaster ~= 'player') then
        return false
      end
    ]]
  elseif(trigger.ownOnly == false) then
    ret = ret .. [[
      if (matchData.unitCaster == 'player') then
        return false
      end
    ]]
  end

  if (use_tooltip and trigger.tooltip_operator and trigger.tooltip) then
    if (trigger.tooltip_operator == "==") then
      local ret2 = [[
      if not (matchData.tooltip == %q ) then
        return false;
      end
      ]]
      ret = ret .. ret2:format(trigger.tooltip);
    elseif (trigger.tooltip_operator == "find('%s')") then
      local ret2 = [[
      if not (matchData.tooltip:find(%q)) then
        return false;
      end
      ]]
      ret = ret .. ret2:format(trigger.tooltip);
    elseif(trigger.tooltip_operator == "match('%s')") then
      local ret2 = [[
      if not (matchData.tooltip:match(%q) ) then
        return false;
      end
      ]]
      ret = ret .. ret2:format(trigger.tooltip);
    end
  end

  if (use_tooltipValue and trigger.tooltipValueNr and trigger.tooltipValue_operator and trigger.tooltipValue) then
    local property = "tooltip" .. tonumber(trigger.tooltipValueNr);
    local ret2 = [[
      if not (matchData.%s %s %s) then
        return false;
      end
    ]]
    ret = ret .. ret2:format(property, trigger.tooltipValue_operator, trigger.tooltipValue);
  end

  if (trigger.useNamePattern and trigger.namePattern_operator and trigger.namePattern_name) then
    if (trigger.namePattern_operator == "==") then
      local ret2 = [[
      if not (matchData.name == %q ) then
        return false;
      end
      ]]
      ret = ret .. ret2:format(trigger.namePattern_name);
    elseif (trigger.namePattern_operator == "find('%s')") then
      local ret2 = [[
      if not (matchData.name:find(%q)) then
        return false;
      end
      ]]
      ret = ret .. ret2:format(trigger.namePattern_name);
    elseif(trigger.namePattern_operator == "match('%s')") then
      local ret2 = [[
      if not (matchData.name:match(%q) ) then
        return false;
      end
      ]]
      ret = ret .. ret2:format(trigger.namePattern_name);
    end
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

local function highestExpirationTime(bestMatch, auraMatch)
  if (bestMatch.expirationTime and auraMatch.expirationTime) then
    return auraMatch.expirationTime > bestMatch.expirationTime;
  end
  return true;
end

local function lowestExpirationTime(bestMatch, auraMatch)
  if (bestMatch.expirationTime and auraMatch.expirationTime) then
    return auraMatch.expirationTime < bestMatch.expirationTime;
  end
  return false;
end

local function IsGroupTrigger(trigger)
  return trigger.unit == "group" or trigger.unit == "boss" or trigger.unit == "nameplate" or trigger.unit == "arena";
end

--- Adds an aura, setting up internal data structures for all buff triggers.
-- @param data
function BuffTrigger.Add(data)
  local id = data.id;

  triggerInfos[id] = nil;
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger
    if (trigger.type == "aura2") then

      trigger.unit = trigger.unit or "player";
      trigger.debuffType = trigger.debuffType or "HELPFUL";

      local effectiveShowOn = trigger.matchesShowOn or "showOnActive";

      -- TODO remove before relese, a small upgrade path for people on my branch
      if (trigger.showClones) then
        trigger.showClones = nil;
        trigger.combineMatches = "showClones";
      end

      local effectiveShowClones = effectiveShowOn ~= "showOnMissing" and trigger.combineMatches == "showClones";

      local combineMode;
      if (IsGroupTrigger(trigger)) then
        combineMode = effectiveShowOn ~= "showOnMissing" and trigger.combineMatchesGroup or "showLowestPerUnit";
        if (combineMode == "showCombineAll") then
          combineMode = "showLowest";
        end
      else
        combineMode = effectiveShowOn ~= "showOnMissing" and trigger.combineMatches or "showLowest";
      end

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

      local showIfInvalidUnit = trigger.unit ~= "player" and trigger.unitExists or false
      local effectiveUseGroupCount = effectiveShowOn == "showOnActive" and IsGroupTrigger(trigger) and trigger.useGroup_count;
      local groupCountFunc;
      if (effectiveUseGroupCount) then
        -- TODO groupCountFunc
        -- group count + group role
      end
      local effectiveIgnoreSelf = trigger.unit == "group" and trigger.ignoreSelf;
      local effectiveGroupRole = trigger.unit == "group" and trigger.useGroupRole and trigger.group_role;

      local triggerInformation = {
        auranames = names,
        auraspellids = trigger.useExactSpellId and trigger.auraspellids,
        unit = trigger.unit == "member" and trigger.specificUnit or trigger.unit,
        debuffType = trigger.debuffType,
        ownOnly = trigger.ownOnly,
        combineMode = combineMode,
        matchesShowOn = effectiveShowOn,
        scanFunc = scanFunc,
        remainingFunc = remFunc,
        remainingCheck = effectiveShowOn == "showOnActive" and trigger.useRem and tonumber(trigger.rem) or 0,
        id = id,
        triggernum = triggernum,
        compareFunc = (combineMode == "showHighest" or combineMode == "showHighestPerUnit") and highestExpirationTime or lowestExpirationTime,
        unitExists = showIfInvalidUnit,
        fetchTooltip = trigger.matchesShowOn ~= "showOnMissing" and trigger.fetchTooltip,
        groupTrigger = IsGroupTrigger(trigger),
        ignoreSelf = effectiveIgnoreSelf,
        groupRole = effectiveGroupRole,
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
    GameTooltip:SetUnitBuff(state.unit, state.index);
  elseif(trigger.debuffType == "HARMFUL") then
    GameTooltip:SetUnitDebuff(state.unit, state.index);
  end
end

--- Returns the name and icon to show in the options.
-- @param data
-- @param triggernum
-- @return name and icon
function BuffTrigger.GetNameAndIcon(data, triggernum)
  local _, name, icon
  local trigger = data.triggers[triggernum].trigger

  if (trigger.useName and trigger.auranames) then
    for i = 1, 9 do
      local spellId = tonumber(trigger.auranames[i]);
      if (spellId) then
        name, _, icon = GetSpellInfo(trigger.auranames[i]);
        if (name and icon) then
          return name, icon
        end
      else
        local iconFromSpellCache = WeakAuras.spellCache.GetIcon(trigger.auranames[i]);
        if (iconFromSpellCache) then
          return trigger.auranames[i], iconFromSpellCache;
        end
      end
    end
  end

  if (trigger.useExactSpellId and trigger.auraspellids) then
    for i = 1, 9 do
      local spellId = trigger.auraspellids[i] ~= "" and tonumber(trigger.auraspellids[i])
      if (spellId) then
        name, _, icon = GetSpellInfo(trigger.auraspellids[i]);
        if (name and icon) then
          return name, icon;
        end
      end
    end
  end
end

--- Returns the tooltip text for additional properties.
-- @param data
-- @param triggernum
-- @return string of additional properties
function BuffTrigger.GetAdditionalProperties(data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  local effectiveShowOn = trigger.matchesShowOn or "showOnActive";
  local combineMode;
  if (effectiveShowOn ~= "showOnMissing") then
    if (IsGroupTrigger(trigger)) then
      combineMode = trigger.combineMatchesGroup or "showLowestPerUnit";
      if (combineMode == "showCombineAll") then
        combineMode = "showLowest";
      end
    else
      combineMode = trigger.combineMatches or "showLowest";
    end
  end

  local ret = "\n\n" .. L["Additional Trigger Replacements"] .. "\n";
  ret = ret .. "|cFFFF0000%spellId|r -" .. L["Spell ID"] .. "\n";
  ret = ret .. "|cFFFF0000%unitCaster|r -" .. L["Caster"] .. "\n";
  ret = ret .. "|cFFFF0000%totalCount|r -" .. L["Total Matches"] .. "\n";
  ret = ret .. "|cFFFF0000%unitCount|r -" .. L["Units affected"] .. "\n";
  if (effectiveShowOn ~= "showOnMissing" and trigger.fetchTooltip) then
    ret = ret .. "|cFFFF0000%tooltip|r -" .. L["Tooltip"] .. "\n";
    ret = ret .. "|cFFFF0000%tooltip1|r -" .. L["First value of Tooltip"] .. "\n";
    ret = ret .. "|cFFFF0000%tooltip2|r -" .. L["Second value of Tooltip"] .. "\n";
    ret = ret .. "|cFFFF0000%tooltip3|r -" .. L["Third value of Tooltip"] .. "\n";
  end

  return ret;
end

function BuffTrigger.GetTriggerConditions(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
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

  result["totalCount"] = {
    display = L["Total Match Count"],
    type = "number"
  }

  result["unitCount"] = {
    display = L["Affected Unit Count"],
    type = "number"
  }

  if (trigger.matchesShowOn == "showAlways") then
    result["buffed"] = {
      display = L["Buffed/Debuffed"],
      type = "bool",
      test = function(state, needle)
        return state and state.show and ((state.active and true or false) == (needle == 1));
      end
    }
  end

  if (trigger.matchesShowOn ~= "showOnMissing" and trigger.fetchTooltip) then
    result["tooltip1"] = {
      display = L["Tooltip Value 1"],
      type = "number"
    }
    result["tooltip2"] = {
      display = L["Tooltip Value 2"],
      type = "number"
    }
    result["tooltip3"] = {
      display = L["Tooltip Value 3"],
      type = "number"
    }
  end

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

  if (trigger.unit == "grop") then
    return false, L["Group triggers can't be converted yet."];
  end

  -- Specific unit
  if (trigger.fullscan) then
    if (trigger.subcount) then
      return true, L["Warning: Tooltip Values are now available via %tooltip1, %tooltip2, %tooltip3 instead of %s. This is not automatically adjusted."]
    end

    if (trigger.use_name and trigger.use_spellId) then
      return false, L["Fullscan auras checking for both name and spell id can't be converted."];
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
    trigger.combineMatches = "showClones";
  else
    trigger.combineMatches = "showLowest";
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

  if (trigger.fullscan and trigger.use_tooltip) then
    trigger.fetchTooltip = true;
  else
    trigger.use_tooltip = false;
  end

  if (trigger.fullscan and trigger.subcount) then
    trigger.fetchTooltip = true;
  end

  if (trigger.fullscan and trigger.use_name) then
    trigger.useNamePattern = true;
    trigger.namePattern_operator = trigger.name_operator;
    trigger.namePattern_name = trigger.name;
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
  -- unitExists is exactly the same

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
