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

local WeakAuras = WeakAuras
local L = WeakAuras.L
local timer = WeakAuras.timer
local BuffTrigger = {}
local triggerInfos = {}

-- keyed on unit, debuffType, spellname, with a scan object value
-- scan object: id, triggernum, scanFunc
local scanFuncName = {}
local scanFuncSpellId = {}
local scanFuncGeneral = {}

local scanFuncNameGroup = {}
local scanFuncSpellIdGroup = {}
local scanFuncGeneralGroup = {}

local unitExistScanFunc = {}
local existingUnits = {}
local groupScanFuncs = {}
local groupCountScanFunc = {}

local groupCount = {}
local playerRole = {}

-- Mutli Target tracking
local scanFuncNameMulti = {}
local scanFuncSpellIdMulti = {}
local cleanupTimerMulti = {}

-- Auras that matched, unit, index
local matchData = {}
local matchDataUpToDate = {}

local matchDataMulti = {}
-- Auras that matched, keyed on id, triggernum, kept in sync with matchData
local matchDataByTrigger = {}

local matchDataChanged = {}

local function GetOrCreateSubTable(base, next, ...)
  if not next then
    return base
  end

  base[next] = base[next] or {}
  return GetOrCreateSubTable(base[next], ...)
end

local function IsGroupTrigger(trigger)
  return trigger.unit == "group" or trigger.unit == "boss" or trigger.unit == "nameplate" or trigger.unit == "arena" or trigger.unit == "multi"
end

local function IsSingleMissing(trigger)
  return not IsGroupTrigger(trigger) and trigger.matchesShowOn == "showOnMissing"
end

local function HasMatchCount(trigger)
  if IsGroupTrigger(trigger) then
    return trigger.useMatch_count
  else
    return trigger.matchesShowOn == "showOnMatches"
  end
end

local function ReferenceMatchData(id, triggernum, unit, filter, index)
  local match = matchData[unit][filter][index]
  local base = GetOrCreateSubTable(matchDataByTrigger, id, triggernum, unit)

  base[index] = match

  match.auras[id] = match.auras[id] or {}
  match.auras[id][triggernum] = true
end

local function ReferenceMatchDataMulti(matchData, id, triggernum, destGUID)
  local needToInsert = false

  matchData.auras[id] = matchData.auras[id] or {}
  needToInsert = not matchData.auras[id][triggernum]
  matchData.auras[id][triggernum] = true

  if needToInsert then
    local matchDataByTriggerBase = GetOrCreateSubTable(matchDataByTrigger, id, triggernum, destGUID)
    tinsert(matchDataByTriggerBase, matchData)
  end

  matchDataChanged[id] = matchDataChanged[id] or {}
  matchDataChanged[id][triggernum] = true
end

local function MatchesTriggerInfoMulti(triggerInfo, sourceGUID)
  if triggerInfo.ownOnly then
    return sourceGUID == UnitGUID("player")
  elseif triggerInfo.ownOnly == false then
    return sourceGUID ~= UnitGUID("player")
  else
    return true
  end
end

local function UpdateToolTipDataInMatchData(matchData, time)
  if matchData.tooltipUpdated == time then
    return
  end
  local changed = false

  if matchData.unit and matchData.index and matchData.filter then
    local tooltip, _, tooltip1, tooltip2, tooltip3 = WeakAuras.GetAuraTooltipInfo(matchData.unit, matchData.index, matchData.filter)

    changed = matchData.tooltip ~= tooltip or matchData.tooltip1 ~= tooltip1
      or matchData.tooltip2 ~= tooltip2 or matchData.tooltip3 ~= tooltip3
    matchData.tooltip, matchData.tooltip1, matchData.tooltip2, matchData.tooltip3 = tooltip, tooltip1, tooltip2, tooltip3
  end

  matchData.tooltipUpdated = time
  return changed
end

local function UpdateMatchData(time, matchDataChanged, resetMatchDataByTrigger, unit, index, filter, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
  if not matchData[unit] then
    matchData[unit] = {}
  end
  if not matchData[unit][filter] then
    matchData[unit][filter] = {}
  end
  if not matchData[unit][filter][index] then
    matchData[unit][filter][index] = {
      name = name,
      icon = icon,
      stacks = stacks,
      debuffClass = debuffClass,
      duration = duration,
      expirationTime = expirationTime,
      unitCaster = unitCaster,
      casterName = unitCaster and GetUnitName(unitCaster, false) or "",
      spellId = spellId,
      unit = unit,
      unitName = GetUnitName(unit, false) or "",
      isStealable = isStealable,
      time = time,
      lastChanged = time,
      filter = filter,
      index = index,
      UpdateTooltip = UpdateToolTipDataInMatchData,
      auras = {}
    }
    return true
  end

  local data = matchData[unit][filter][index]
  local changed = false

  if data.name ~= name then
    data.name = name
    changed = true
  end

  if data.icon ~= icon then
    data.icon = icon
    changed = true
  end

  if data.stacks ~= stacks then
    data.stacks = stacks
    changed = true
  end

  if data.duration ~= duration then
    data.duration = duration
    changed = true
  end

  if data.expirationTime ~= expirationTime then
    data.expirationTime = expirationTime
    changed = true
  end

  if data.unitCaster ~= unitCaster then
    data.unitCaster = unitCaster
    changed = true
  end

  local casterName = unitCaster and GetUnitName(unitCaster, false) or ""
  if data.casterName ~= casterName then
    data.casterName = casterName
    changed = true
  end

  if data.spellId ~= spellId then
    data.spellId = spellId
    changed = true
  end

  if data.isStealable ~= isStealable then
    data.isStealable = name
    changed = true
  end

  local unitName = GetUnitName(unit, false) or ""
  if data.unitName ~= unitName then
    data.unitName = unitName
    changed = true
  end

  if data.tooltipUpdated and data.tooltipUpdated < time then
    changed = data:UpdateTooltip(time) or changed
  end

  if changed then
    data.lastChanged = time
  end

  if changed or resetMatchDataByTrigger then
    -- Tell old auras that used this match data
    for id, triggerData in pairs(data.auras) do
      for triggernum in pairs(triggerData) do
        if matchDataByTrigger[id] and matchDataByTrigger[id][triggernum] and matchDataByTrigger[id][triggernum][unit] and matchDataByTrigger[id][triggernum][unit][index] then
          matchDataByTrigger[id][triggernum][unit][index] = nil
          matchDataChanged[id] = matchDataChanged[id] or {}
          matchDataChanged[id][triggernum] = true
        end
      end
    end
    wipe(data.auras)
  end

  data.index = index
  data.time = time
  data.unit = unit

  return changed or data.lastChanged == time or resetMatchDataByTrigger
end

local function calculateNextCheck(triggerInfoRemaing, auraDataRemaing, auraDataExpirationTime,  nextCheck)
  if auraDataRemaing > 0 and auraDataRemaing >= triggerInfoRemaing then
    if not nextCheck then
      return auraDataExpirationTime - triggerInfoRemaing
    else
      return min(auraDataExpirationTime - triggerInfoRemaing, nextCheck)
    end
  end
  return nextCheck
end

local function FindBestMatchData(time, id, triggernum, triggerInfo, matchedUnits)
  -- Find best match
  local bestMatch = nil
  local matchCount = 0
  local unitCount = 0
  local nextCheck

  if not matchDataByTrigger[id] or not matchDataByTrigger[id][triggernum] then
    return nil, 0, 0
  end

  for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
    local unitCounted = false
    for index, auraData in pairs(unitData) do
      local remCheck = true
      if triggerInfo.remainingFunc and auraData.expirationTime then
        local remaining = auraData.expirationTime - time
        remCheck = triggerInfo.remainingFunc(remaining)
        nextCheck = calculateNextCheck(triggerInfo.remainingCheck, remaining, auraData.expirationTime, nextCheck)
      end

      if remCheck then
        matchCount = matchCount + 1
        matchedUnits[unit] = true
        if not unitCounted then
          unitCount = unitCount + 1
          unitCounted = true
        end
        if not bestMatch or triggerInfo.compareFunc(bestMatch, auraData) then
          bestMatch = auraData
        end
      end
    end
  end
  return bestMatch, matchCount, unitCount, nextCheck
end

local function FindBestMatchDataForUnit(time, id, triggernum, triggerInfo, unit)
  -- Find best match
  local bestMatch = nil
  local matchCount = 0
  local nextCheck

  if not matchDataByTrigger[id] or not matchDataByTrigger[id][triggernum] or not matchDataByTrigger[id][triggernum][unit] then
    return nil, 0
  end

  for index, auraData in pairs(matchDataByTrigger[id][triggernum][unit]) do
    local remCheck = true
    if triggerInfo.remainingFunc and auraData.expirationTime then
      local remaining = auraData.expirationTime - time
      remCheck = triggerInfo.remainingFunc(remaining)
      nextCheck = calculateNextCheck(triggerInfo.remainingCheck, remaining, auraData.expirationTime, nextCheck)
    end

    if remCheck then
      matchCount = matchCount + 1
      if not bestMatch or triggerInfo.compareFunc(bestMatch, auraData) then
        bestMatch = auraData
      end
    end
  end
  return bestMatch, matchCount, nextCheck
end

local function UpdateStateWithMatch(time, bestMatch, triggerStates, cloneId, matchCount, unitCount, maxUnitCount, affected, unaffected)
  if not triggerStates[cloneId] then
    triggerStates[cloneId] = {
      show = true,
      changed = true,
      name = bestMatch.name,
      icon = bestMatch.icon,
      stacks = bestMatch.stacks,
      debuffClass = bestMatch.debuffClass,
      progressType = "timed",
      duration = bestMatch.duration,
      expirationTime = bestMatch.expirationTime,
      unitCaster = bestMatch.unitCaster,
      casterName = bestMatch.casterName,
      spellId = bestMatch.spellId,
      index = bestMatch.index,
      unit = bestMatch.unit,
      unitName = bestMatch.unitName,
      GUID = bestMatch.unit and UnitGUID(bestMatch.unit) or bestMatch.GUID,
      matchCount = matchCount,
      unitCount = unitCount,
      maxUnitCount = maxUnitCount,
      tooltip = bestMatch.tooltip,
      tooltip1 = bestMatch.tooltip1,
      tooltip2 = bestMatch.tooltip2,
      tooltip3 = bestMatch.tooltip3,
      affected = affected,
      unaffected = unaffected,
      active = true,
      time = time,
    }
    return true
  else
    local state = triggerStates[cloneId]
    local changed = false
    state.time = time

    if state.unit ~= bestMatch.unit then
      state.unit = bestMatch.unit
      changed = true
    end

    if state.unitName ~= bestMatch.unitName then
      state.unitName = bestMatch.unitName
      changed = true
    end

    if state.show ~= true then
      state.show = true
      changed = true
    end

    if state.name ~= bestMatch.name then
      state.name = bestMatch.name
      changed = true
    end

    if state.icon ~= bestMatch.icon then
      state.icon = bestMatch.icon
      changed = true
    end

    if state.stacks ~= bestMatch.stacks then
      state.stacks = bestMatch.stacks
      changed = true
    end

    if state.debuffClass ~= bestMatch.debuffClass then
      state.debuffClass = bestMatch.debuffClass
      changed = true
    end

    if state.duration ~= bestMatch.duration then
      state.duration = bestMatch.duration
      changed = true
    end

    if state.expirationTime ~= bestMatch.expirationTime then
      state.expirationTime = bestMatch.expirationTime
      state.resort = true
      changed = true
    end

    if state.progressType ~= "timed" then
      state.progressType = "timed"
      changed = true
    end

    if state.unitCaster ~= bestMatch.unitCaster then
      state.unitCaster = bestMatch.unitCaster
      state.casterName = bestMatch.casterName
      changed = true
    end

    if state.spellId ~= bestMatch.spellId then
      state.spellId = bestMatch.spellId
      changed = true
    end

    if state.index ~= bestMatch.index then
      state.index = bestMatch.index
      changed = true
    end

    if state.tooltip ~= bestMatch.tooltip then
      state.tooltip = bestMatch.tooltip
      changed = true
    end

    if state.tooltip1 ~= bestMatch.tooltip1 then
      state.tooltip1 = bestMatch.tooltip1
      changed = true
    end

    if state.tooltip2 ~= bestMatch.tooltip2 then
      state.tooltip2 = bestMatch.tooltip2
      changed = true
    end

    if state.tooltip3 ~= bestMatch.tooltip3 then
      state.tooltip3 = bestMatch.tooltip3
      changed = true
    end

    if state.matchCount ~= matchCount then
      state.matchCount = matchCount
      changed = true
    end

    if state.unitCount ~= unitCount then
      state.unitCount = unitCount
      changed = true
    end

    if state.maxUnitCount ~= maxUnitCount then
      state.maxUnitCount = maxUnitCount
      changed = true
    end

    if state.affected ~= affected then
      state.affected = affected
      changed = true
    end

    if state.unaffected ~= unaffected then
      state.unaffected = unaffected
      changed = true
    end

    if state.active ~= true then
      state.active = true
      changed = true
    end

    if changed then
      state.changed = true
      return true
    end
  end
end

local function UpdateStateWithNoMatch(time, triggerStates, triggerInfo, cloneId, unit, matchCount, unitCount, maxUnitCount, affected, unaffected)
  if not triggerStates[cloneId] then
    triggerStates[cloneId] = {
      show = true,
      changed = true,
      matchCount = 0,
      progressType = 'timed',
      duration = 0,
      expirationTime = math.huge,
      matchCount = matchCount,
      unitCount = unitCount,
      maxUnitCount = maxUnitCount,
      active = false,
      time = time,
      affected = affected,
      unaffected = unaffected,
      unit = unit,
      unitName = unit and GetUnitName(unit, false) or "",
      destName = "",
      name = triggerInfo.fallbackName,
      icon = triggerInfo.fallbackIcon
    }
    return true
  else
    local state = triggerStates[cloneId]
    state.time = time
    local changed = false

    if state.show ~= true then
      state.show = true
      changed = true
    end

    if state.name ~= triggerInfo.fallbackName then
      state.name = triggerInfo.fallbackName
      changed = true
    end

    if state.icon ~= triggerInfo.fallbackIcon then
      state.icon = triggerInfo.fallbackIcon
      changed = true
    end

    if state.stacks then
      state.stacks = nil
      changed = true
    end

    if state.duration then
      state.duration = nil
      changed = true
    end

    if state.expirationTime then
      state.expirationTime = nil
      state.resort = true
      changed = true
    end

    if state.progressType then
      state.progressType = nil
      changed = true
    end

    if state.unit ~= unit then
      state.unit = unit
      changed = true
    end

    local unitName = unit and GetUnitName(unit, false) or ""
    if state.unitName ~= unitName then
      state.unitName = unitName
      changed = true
    end

    if state.unitCaster then
      state.unitCaster = nil
      changed = true
    end

    if state.casterName ~= "" then
      state.casterName = ""
      changed = true
    end

    if state.spellId then
      state.spellId = nil
      changed = true
    end

    if state.index then
      state.index = nil
      changed = true
    end

    if state.matchCount ~= matchCount then
      state.matchCount = matchCount
      changed = true
    end

    if state.unitCount ~= unitCount then
      state.unitCount = unitCount
      changed = true
    end

    if state.maxUnitCount ~= maxUnitCount then
      state.maxUnitCount = maxUnitCount
      changed = true
    end

    if state.active then
      state.active = false
      changed = true
    end

    if state.affected ~= affected then
      state.affected = affected
      changed = true
    end

    if state.unaffected ~= unaffected then
      state.unaffected = unaffected
      changed = true
    end

    if changed then
      state.changed = true
      return true
    end
  end
end

local function RemoveState(triggerStates, cloneId)
  local state = triggerStates[cloneId]
  if state then
    if state.show then
      state.show = false
      state.changed = true
      return true
    end
  end
end

local function GetAllUnits(unit)
  if unit == "group" then
    if IsInRaid() then
      local i = 1
      local max = GetNumGroupMembers()
      return function()
        if i <= max then
          local ret = WeakAuras.raidUnits[i]
          i = i + 1
          return ret
        end
        i = 1
      end
    else
      local i = 0
      local max = GetNumSubgroupMembers()
      return function()
        if i == 0 then
          i = 1
          return "player"
        else
          if i <= max then
            local ret =  WeakAuras.partyUnits[i]
            i = i + 1
            return ret
          end
        end
        i = 0
      end
    end
  elseif unit == "boss" or unit == "arena" or "nameplate" then
    local i = 1
    local max
    if unit == "boss" then
      max = 4
    elseif unit == "arena" then
      max = 5
    elseif unit == "nameplate" then
      max = 40
    else
      return function() end
    end
    return function()
      local ret = unit .. i
      while not UnitExists(ret) do
        i = i + 1
        if i > max then
          i = 1
          return nil
        end
        ret = unit .. i
      end
      i = i + 1
      return ret
    end
  else
    local toggle = false
    return function()
      toggle = not toggle
      if toggle then
        return unit
      end
    end
  end
end

local function UpdateGroupCountFor(unit, event)
  if unit == "boss" then
    local count = 0
    for i = 1, 4 do
      if UnitExists("boss" .. i) then
        count = count + 1
      end
    end
    groupCount["boss"] = 4
  end

  if unit == "nameplate" then
    if event == "NAME_PLATE_UNIT_ADDED" then
      groupCount["nameplate"] = (groupCount["nameplate"] or 0) + 1
    else
      groupCount["nameplate"] = (groupCount["nameplate"] or 0) - 1
    end
  end

  if unit == "group" then
    groupCount["HEALER"] = 0
    groupCount["DAMAGER"] = 0
    groupCount["TANK"] = 0

    playerRole = UnitGroupRolesAssigned("player")
    if IsInRaid() then
      groupCount["group"] = GetNumGroupMembers()
      for i = 1, GetNumGroupMembers() do
        local role = UnitGroupRolesAssigned(WeakAuras.raidUnits[i])
        if role and role ~= "NONE" then
          groupCount[role] = groupCount[role] + 1
        end
      end
    else
      groupCount["group"] = GetNumSubgroupMembers() + 1
      for i = 1, GetNumSubgroupMembers() do
        local role = UnitGroupRolesAssigned(WeakAuras.partyUnits[i])
        if role and role ~= "NONE" then
          groupCount[role] = groupCount[role] + 1
        end
      end
      if playerRole and playerRole ~= "NONE" then
        groupCount[playerRole] = groupCount[playerRole] + 1
      end
    end
  end

  for index, triggerInfo in ipairs(groupCountScanFunc) do
    if triggerInfo.unit == unit then
      matchDataChanged[triggerInfo.id] = matchDataChanged[triggerInfo.id] or {}
      matchDataChanged[triggerInfo.id][triggerInfo.triggernum] = true
    end
  end
end

local function MaxUnitCount(triggerInfo)
  if triggerInfo.unit == "group" then
    if not groupCount["group"] then
      UpdateGroupCountFor("group")
    end
    local count
    if triggerInfo.groupRole then
      count = groupCount[triggerInfo.groupRole] or 0
    else
      count = groupCount["group"] or 1
    end
    if triggerInfo.ignoreSelf and (not triggerInfo.groupRole or triggerInfo.groupRole == playerRole) then
      count = count - 1
    end
    return count
  else
    if triggerInfo.unit == "boss" and not groupCount["boss"] then
      UpdateGroupCountFor("boss")
    end

    return groupCount[triggerInfo.unit] or UnitExists(triggerInfo.unit) and 1 or 0
  end
end

local function FormatAffectedUnaffected(triggerInfo, matchedUnits)
  local affected = ""
  local unaffected = ""
  for unit in GetAllUnits(triggerInfo.unit) do
    if matchedUnits[unit] then
      affected = affected .. (GetUnitName(unit, false) or unit) .. ", "
    else
      unaffected = unaffected .. (GetUnitName(unit, false) or unit) .. ", "
    end
  end
  unaffected = unaffected == "" and L["None"] or unaffected:sub(0, -3)
  affected = affected == "" and L["None"] or affected:sub(0, -3)

  return affected, unaffected
end

local recheckTriggerInfo

local function SatisfiesGroupMatchCount(triggerInfo, unitCount, maxUnitCount, matchCount)
  if triggerInfo.groupCountFunc and not triggerInfo.groupCountFunc(unitCount, maxUnitCount) then
    return false
  end

  if triggerInfo.matchCountFunc and not triggerInfo.matchCountFunc(matchCount) then
    return false
  end
  return true
end

local function TriggerInfoApplies(triggerInfo, isSelf, role)
  if triggerInfo.ignoreSelf and isSelf then
    return false
  end
  if triggerInfo.groupRole and triggerInfo.groupRole ~= role then
    return false
  end
  return true
end

local function SortMatchDataByUnitIndex(a, b)
  if a.unit and b.unit and a.unit ~= b.unit then
    return a.unit < b.unit
  end
  if a.index and b.index and a.index ~= b.index then
    return a.index < b.index
  end
  return a.expirationTime < b.expirationTime
end

local function UpdateTriggerState(time, id, triggernum)
  local triggerStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum)
  local triggerInfo = triggerInfos[id][triggernum]
  local updated
  local nextCheck
  local matchCount = 0
  local unitCount = 0
  local auraDatas = {}
  local maxUnitCount = MaxUnitCount(triggerInfo)
  local matchedUnits = {}

  if triggerInfo.combineMode == "showOne" then
    local bestMatch, matchCount, unitCount
    bestMatch, matchCount, unitCount, nextCheck = FindBestMatchData(time, id, triggernum, triggerInfo, matchedUnits)
    local cloneId = ""

    local useMatch = true
    if triggerInfo.unitExists ~= nil and not existingUnits[triggerInfo.unit] then
      useMatch = triggerInfo.unitExists
    else
      useMatch = SatisfiesGroupMatchCount(triggerInfo, unitCount, maxUnitCount, matchCount)
    end

    if useMatch then
      local affected, unaffected
      if triggerInfo.useAffected then
        affected, unaffected = FormatAffectedUnaffected(triggerInfo, matchedUnits)
      end

      if bestMatch then
        updated = UpdateStateWithMatch(time, bestMatch, triggerStates, cloneId, matchCount, unitCount, maxUnitCount, affected, unaffected)
      else
        updated = UpdateStateWithNoMatch(time, triggerStates, triggerInfo, cloneId, nil, 0, 0, 0, affected, unaffected)
      end
    else
      updated = RemoveState(triggerStates, cloneId)
    end
  elseif triggerInfo.combineMode == "showClones" then
    if matchDataByTrigger[id] and matchDataByTrigger[id][triggernum] then
      for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
        local unitCounted = false
        for index, auraData in pairs(unitData) do
          local remCheck = true
          if triggerInfo.remainingFunc and auraData.expirationTime then
            local remaining = auraData.expirationTime - time
            remCheck = triggerInfo.remainingFunc(remaining)
            nextCheck = calculateNextCheck(triggerInfo.remainingCheck, remaining, auraData.expirationTime, nextCheck)
          end

          if remCheck then
            tinsert(auraDatas, auraData)
            matchCount = matchCount + 1
            matchedUnits[unit] = true
            if not unitCounted then
              unitCount = unitCount + 1
              unitCounted = true
            end
          end
        end
      end
    end

    local useMatches = true
    if triggerInfo.unitExists ~= nil and not existingUnits[triggerInfo.unit] then
      useMatches = triggerInfo.unitExists
    else
      useMatches = SatisfiesGroupMatchCount(triggerInfo, unitCount, maxUnitCount, matchCount)
    end

    if useMatches then

      table.sort(auraDatas, SortMatchDataByUnitIndex)

      local affected, unaffected
      if triggerInfo.useAffected then
        affected, unaffected = FormatAffectedUnaffected(triggerInfo, matchedUnits)
      end

      local usedCloneIds = {};

      for index, auraData in ipairs(auraDatas) do
        local cloneId = (auraData.GUID or auraData.unit or "unknown") .. " " .. auraData.spellId
        if usedCloneIds[cloneId] then
          usedCloneIds[cloneId] = usedCloneIds[cloneId] + 1
          cloneId = cloneId .. usedCloneIds[cloneId]
        else
          usedCloneIds[cloneId] = 1
        end

        updated = UpdateStateWithMatch(time, auraData, triggerStates, cloneId, matchCount, unitCount, maxUnitCount, affected, unaffected) or updated
      end

      if matchCount == 0 then
        updated = UpdateStateWithNoMatch(time, triggerStates, triggerInfo, "", nil, 0, 0, 0, affected, unaffected) or updated
      end
    end

    for cloneId, state in pairs(triggerStates) do
      if state.show and state.time < time then
        updated = RemoveState(triggerStates, cloneId) or updated
      end
    end
  elseif triggerInfo.combineMode == "showPerUnit" then
    local matches = {}
    if matchDataByTrigger[id] and matchDataByTrigger[id][triggernum] then
      for unit, unitData in pairs(matchDataByTrigger[id][triggernum]) do
        local bestMatch, matchCountPerUnit, nextCheckForMatch = FindBestMatchDataForUnit(time, id, triggernum, triggerInfo, unit)
        matchCount = matchCount + matchCountPerUnit
        if bestMatch then
          unitCount = unitCount + 1
          matchedUnits[unit] = true
        end

        if not nextCheck then
          nextCheck = nextCheckForMatch
        elseif nextCheckForMatch then
          nextCheck = min(nextCheck, nextCheckForMatch)
        end
        matches[unit] = bestMatch
      end
    end

    local useMatches = SatisfiesGroupMatchCount(triggerInfo, unitCount, maxUnitCount, matchCount)

    if useMatches then
      local affected, unaffected
      if triggerInfo.useAffected then
        affected, unaffected = FormatAffectedUnaffected(triggerInfo, matchedUnits)
      end

      if triggerInfo.perUnitMode == "affected" then
        for unit, bestMatch in pairs(matches) do
          if bestMatch then
            updated = UpdateStateWithMatch(time, bestMatch, triggerStates, unit, matchCount, unitCount, maxUnitCount, affected, unaffected) or updated
          end
        end
      else
        for unit in GetAllUnits(triggerInfo.unit) do
          if TriggerInfoApplies(triggerInfo, UnitIsUnit("player", unit), UnitGroupRolesAssigned(unit)) then
            local bestMatch = matches[unit]
            if bestMatch then
              if triggerInfo.perUnitMode == "all" then
                updated = UpdateStateWithMatch(time, bestMatch, triggerStates, unit, matchCount, unitCount, maxUnitCount, affected, unaffected) or updated
              end
            else
              updated = UpdateStateWithNoMatch(time, triggerStates, triggerInfo, unit, unit, matchCount, unitCount, maxUnitCount, affected, unaffected) or updated
            end
          end
        end
      end
    end

    for cloneId, state in pairs(triggerStates) do
      if state.show and state.time < time then
        updated = RemoveState(triggerStates, cloneId) or updated
      end
    end
  end

  if updated then
    WeakAuras.UpdatedTriggerState(id)
  end

  if nextCheck then
    if triggerInfo.nextScheduledCheck ~= nextCheck then
      if triggerInfo.nextScheduledCheckHandle then
        timer:CancelTimer(triggerInfo.nextScheduledCheckHandle)
      end
      triggerInfo.nextScheduledCheckHandle = timer:ScheduleTimerFixed(recheckTriggerInfo, nextCheck - time, triggerInfo)
      triggerInfo.nextScheduledCheck = nextCheck
    end
  elseif triggerInfo.nextScheduledCheckHandle then
    timer:CancelTimer(triggerInfo.nextScheduledCheckHandle)
    triggerInfo.nextScheduledCheckHandle = nil
    triggerInfo.nextScheduledCheck = nil
  end
end

recheckTriggerInfo = function(triggerInfo)
  matchDataChanged[triggerInfo.id] = matchDataChanged[triggerInfo.id] or {}
  matchDataChanged[triggerInfo.id][triggerInfo.triggernum] = true
  triggerInfo.nextScheduledCheckHandle = nil
  triggerInfo.nextScheduledCheck = nil
end

local function PrepareMatchData(unit, filter)
  if not matchDataUpToDate[unit] or not matchDataUpToDate[unit][filter] then
    local time = GetTime()
    local index = 1
    while true do
      local name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, index, filter)
      if not name then
        break
      end

      if debuffClass == nil then
        debuffClass = "none"
      elseif debuffClass == "" then
        debuffClass = "enrage"
      else
        debuffClass = string.lower(debuffClass)
      end

      local updatedMatchData = UpdateMatchData(time, matchDataChanged, false, unit, index, filter, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
      index = index + 1
    end

    matchDataUpToDate[unit] = matchDataUpToDate[unit] or {}
    matchDataUpToDate[unit][filter] = true
  end
end

local function CleanUpOutdatedMatchData(time, unit, filter)
  -- Figure out if any matchData is outdated
  if matchData[unit] and matchData[unit][filter] then
    for index, data in pairs(matchData[unit][filter]) do
      if data.time < time then
         matchData[unit][filter][index] = nil
         for id, triggerData in pairs(data.auras) do
           for triggernum in pairs(triggerData) do
             matchDataByTrigger[id][triggernum][unit][index] = nil
             matchDataChanged[id] = matchDataChanged[id] or {}
             matchDataChanged[id][triggernum] = true
           end
         end
      end
    end
  end
end

local function CleanUpMatchDataGroupTriggers(unit)
  if matchData[unit] then
    for filter, filterData in pairs(matchData[unit]) do
      for index, data in pairs(filterData) do
        for id, triggerData in pairs(data.auras) do
         for triggernum in pairs(triggerData) do
           local triggerInfo = triggerInfos[id][triggernum]
           if triggerInfo.unit == "group" then
             triggerData[triggernum] = nil
             matchDataByTrigger[id][triggernum][unit][index] = nil
             matchDataChanged[id] = matchDataChanged[id] or {}
             matchDataChanged[id][triggernum] = true
           end
         end
        end
      end
    end
  end
end

local function CheckScanFuncs(scanFuncs, unit, filter, index)
  if scanFuncs then
    for _, triggerInfo in pairs(scanFuncs) do
      if triggerInfo.fetchTooltip then
        matchData[unit][filter][index]:UpdateTooltip(GetTime())
      end
      if not triggerInfo.scanFunc or triggerInfo.scanFunc(time, matchData[unit][filter][index]) then
        local id = triggerInfo.id
        local triggernum = triggerInfo.triggernum
        ReferenceMatchData(id, triggernum, unit, filter, index)
        matchDataChanged[id] = matchDataChanged[id] or {}
        matchDataChanged[id][triggernum] = true
      end
    end
  end
end

local function ScanUnitWithFilter(matchDataChanged, time, unit, filter,
  scanFuncNameGroup, scanFuncSpellIdGroup, scanFuncGeneralGroup,
  scanFuncName, scanFuncSpellId, scanFuncGeneral,
  resetMatchDataByTrigger, invalidUnit)
  if not scanFuncName and not scanFuncSpellId and not scanFuncGeneral and not scanFuncNameGroup and not scanFuncSpellIdGroup and not scanFuncGeneralGroup then
    if matchDataUpToDate[unit] then
      matchDataUpToDate[unit][filter] = nil
    end
    CleanUpOutdatedMatchData(time, unit, filter)
    return
  end

  local index = 1
  while not invalidUnit do
    local name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, index, filter)
    if not name then
      break
    end

    if debuffClass == nil then
      debuffClass = "none"
    elseif debuffClass == "" then
      debuffClass = "enrage"
    else
      debuffClass = string.lower(debuffClass)
    end

    local updatedMatchData = UpdateMatchData(time, matchDataChanged, resetMatchDataByTrigger, unit, index, filter, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)

    if updatedMatchData then -- Aura data changed, check against triggerInfos
      CheckScanFuncs(scanFuncName and scanFuncName[name], unit, filter, index)
      CheckScanFuncs(scanFuncNameGroup and scanFuncNameGroup[name], unit, filter, index)
      CheckScanFuncs(scanFuncSpellId and scanFuncSpellId[spellId], unit, filter, index)
      CheckScanFuncs(scanFuncSpellIdGroup and scanFuncSpellIdGroup[spellId], unit, filter, index)
      CheckScanFuncs(scanFuncGeneral, unit, filter, index)
      CheckScanFuncs(scanFuncGeneralGroup, unit, filter, index)
    end
    index = index + 1
  end

  CleanUpOutdatedMatchData(time, unit, filter)

  matchDataUpToDate[unit] = matchDataUpToDate[unit] or {}
  matchDataUpToDate[unit][filter] = true
end

local function UpdateStates(matchDataChanged, time)
  for id, auraData in pairs(matchDataChanged) do
    WeakAuras.StartProfileAura(id)
    for triggernum in pairs(auraData) do
      UpdateTriggerState(time, id, triggernum)
    end
    WeakAuras.StopProfileAura(id)
  end
end

local function FilterScanFuncsHelper(input, isSelf, role)
  if not input then
    return nil
  end
  local result = {}
  for name, nameData in pairs(input) do
    result[name] = {}
    for index, triggerInfo in ipairs(nameData) do
      if TriggerInfoApplies(triggerInfo, isSelf, role) then
        tinsert(result[name], triggerInfo)
      end
    end
  end
  return result
end

local function FilterGeneralScanFuncsHelper(input, isSelf, role)
  if not input then
    return nil
  end
  local result = {}
  for index, triggerInfo in ipairs(input) do
    if TriggerInfoApplies(triggerInfo, isSelf, role) then
      tinsert(result, triggerInfo)
    end
  end
  return result
end

local function FilterScanFuncs(input, unit, isSelf, role)
  local result = {}
  result["HELPFUL"] = FilterScanFuncsHelper(input["group"] and input["group"]["HELPFUL"], isSelf, role)
  result["HARMFUL"] = FilterScanFuncsHelper(input["group"] and input["group"]["HARMFUL"], isSelf, role)
  return result
end

local function FilterGeneralScanFuncs(input, unit, isSelf, role)
  local result = {}
  result["HELPFUL"] = FilterGeneralScanFuncsHelper(input["group"] and input["group"]["HELPFUL"], isSelf, role)
  result["HARMFUL"] = FilterGeneralScanFuncsHelper(input["group"] and input["group"]["HARMFUL"], isSelf, role)
  return result
end

local function ScanGroupUnit(time, matchDataChanged, unitType, unit, resetMatchDataByTrigger, invalidUnit)
  local unitExists = UnitExists(unit)
  if existingUnits[unit] ~= unitExists then
    existingUnits[unit] = unitExists

    if unitExistScanFunc[unit] then
      for id, idData in pairs(unitExistScanFunc[unit]) do
        matchDataChanged[id] = matchDataChanged[id] or {}
        for _, triggerInfo in ipairs(idData) do
          matchDataChanged[id][triggerInfo.triggernum] = true
        end
      end
    end
  end

  scanFuncName[unit] = scanFuncName[unit] or {}
  scanFuncSpellId[unit] = scanFuncSpellId[unit] or {}
  scanFuncGeneral[unit] = scanFuncGeneral[unit] or {}

  if unitType then
    scanFuncName[unitType] = scanFuncName[unitType] or {}
    scanFuncSpellId[unitType] = scanFuncSpellId[unitType] or {}
    scanFuncGeneral[unitType] = scanFuncGeneral[unitType] or {}
  end

  if unitType ~= "group" then
    ScanUnitWithFilter(matchDataChanged, time, unit, "HELPFUL",
      unitType and scanFuncName[unitType]["HELPFUL"],
      unitType and scanFuncSpellId[unitType]["HELPFUL"],
      unitType and scanFuncGeneral[unitType]["HELPFUL"],
      scanFuncName[unit]["HELPFUL"],
      scanFuncSpellId[unit]["HELPFUL"],
      scanFuncGeneral[unit]["HELPFUL"],
      resetMatchDataByTrigger,
      invalidUnit)

    ScanUnitWithFilter(matchDataChanged, time, unit, "HARMFUL",
      unitType and scanFuncName[unitType]["HARMFUL"],
      unitType and scanFuncSpellId[unitType]["HARMFUL"],
      unitType and scanFuncGeneral[unitType]["HARMFUL"],
      scanFuncName[unit]["HARMFUL"],
      scanFuncSpellId[unit]["HARMFUL"],
      scanFuncGeneral[unit]["HARMFUL"],
      resetMatchDataByTrigger,
      invalidUnit)
  else
    scanFuncNameGroup[unit] = scanFuncNameGroup[unit] or {}
    scanFuncSpellIdGroup[unit] = scanFuncSpellIdGroup[unit] or {}
    scanFuncGeneralGroup[unit] = scanFuncGeneralGroup[unit] or {}

    ScanUnitWithFilter(matchDataChanged, time, unit, "HELPFUL",
      scanFuncNameGroup[unit]["HELPFUL"],
      scanFuncSpellIdGroup[unit]["HELPFUL"],
      scanFuncGeneralGroup[unit]["HELPFUL"],
      scanFuncName[unit]["HELPFUL"],
      scanFuncSpellId[unit]["HELPFUL"],
      scanFuncGeneral[unit]["HELPFUL"],
      resetMatchDataByTrigger,
      invalidUnit)

    ScanUnitWithFilter(matchDataChanged, time, unit, "HARMFUL",
      scanFuncNameGroup[unit]["HARMFUL"],
      scanFuncSpellIdGroup[unit]["HARMFUL"],
      scanFuncGeneralGroup[unit]["HARMFUL"],
      scanFuncName[unit]["HARMFUL"],
      scanFuncSpellId[unit]["HARMFUL"],
      scanFuncGeneral[unit]["HARMFUL"],
      resetMatchDataByTrigger,
      invalidUnit)
  end
end

local function UpdatePerGroupUnitScanFuncs()
  if IsInRaid() then
    for i = 1, 40 do
      local unit = WeakAuras.raidUnits[i]
      if not UnitExists(unit) then
        scanFuncNameGroup[unit] = nil
        scanFuncSpellIdGroup[unit] = nil
        scanFuncGeneralGroup[unit] = nil
      else
        local isSelf = UnitIsUnit("player", unit)
        local role = UnitGroupRolesAssigned(unit)
        scanFuncNameGroup[unit] = FilterScanFuncs(scanFuncName, unit, isSelf, role)
        scanFuncSpellIdGroup[unit] = FilterScanFuncs(scanFuncSpellId, unit)
        scanFuncGeneralGroup[unit] = FilterGeneralScanFuncs(scanFuncGeneral, unit)
      end
    end
  else
    local unit = "player"
    local role = UnitGroupRolesAssigned(unit)
    scanFuncNameGroup[unit] = FilterScanFuncs(scanFuncName, unit, true, role)
    scanFuncSpellIdGroup[unit] = FilterScanFuncs(scanFuncSpellId, unit, true, role)
    scanFuncGeneralGroup[unit] = FilterGeneralScanFuncs(scanFuncGeneral, unit, true, role)
    for i = 1, 4 do
      unit = WeakAuras.partyUnits[i]
      if not UnitExists(unit) then
        scanFuncNameGroup[unit] = nil
        scanFuncSpellIdGroup[unit] = nil
        scanFuncGeneralGroup[unit] = nil
      else
        local isSelf = UnitIsUnit("player", unit)
        local role = UnitGroupRolesAssigned(unit)
        scanFuncNameGroup[unit] = FilterScanFuncs(scanFuncName, unit, isSelf, role)
        scanFuncSpellIdGroup[unit] = FilterScanFuncs(scanFuncSpellId, unit, isSelf, role)
        scanFuncGeneralGroup[unit] = FilterGeneralScanFuncs(scanFuncGeneral, unit, isSelf, role)
      end
    end
  end
end

local lastGroupType
local function ScanAllGroup(time, matchDataChanged, resetMatchDataByTrigger)
  -- We iterate over all raid/player unit ids here because ScanGroupUnit also
  -- handles the cases where a unit existance changes.

  if IsInRaid() then
    if lastGroupType ~= true then
      -- We are now in a raid, but we might have matchDatas for the units player, party1..party4,
      -- which needs to be removed
      CleanUpMatchDataGroupTriggers("player")
      for i = 1, 4 do
        CleanUpMatchDataGroupTriggers(WeakAuras.partyUnits[i])
      end
    end
    lastGroupType = true
    for i = 1, 40 do
      ScanGroupUnit(time, matchDataChanged, "group", WeakAuras.raidUnits[i], resetMatchDataByTrigger)
    end
  else
    if lastGroupType ~= false then
      for i = 1, 40 do
        CleanUpMatchDataGroupTriggers(WeakAuras.raidUnits[i])
      end
    end
    lastGroupType = false
    ScanGroupUnit(time, matchDataChanged, "group", "player", resetMatchDataByTrigger)
    for i = 1, 4 do
      ScanGroupUnit(time, matchDataChanged, "group", WeakAuras.partyUnits[i], resetMatchDataByTrigger)
    end
  end
end

local function ScanAllBoss(time, matchDataChanged)
  for i = 1,4 do
    ScanGroupUnit(time, matchDataChanged, "boss", "boss" .. i)
  end
end

local frame = CreateFrame("FRAME")
WeakAuras.frames["WeakAuras Buff2 Frame"] = frame
frame:RegisterEvent("UNIT_AURA")
frame:RegisterUnitEvent("UNIT_PET", "player")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:RegisterEvent("ARENA_OPPONENT_UPDATE")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_ENTERED_VEHICLE")
frame:RegisterEvent("UNIT_EXITED_VEHICLE")
frame:SetScript("OnEvent", function (frame, event, arg1, arg2, ...)
  WeakAuras.StartProfileSystem("bufftrigger2")
  local time = GetTime()
  if event == "PLAYER_TARGET_CHANGED" then
    ScanGroupUnit(time, matchDataChanged, nil, "target")
  elseif event == "PLAYER_FOCUS_CHANGED" then
    ScanGroupUnit(time, matchDataChanged, nil, "focus")
  elseif event == "UNIT_PET" then
    ScanGroupUnit(time, matchDataChanged, nil, "pet")
  elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
    UpdateGroupCountFor("nameplate", event)
    ScanGroupUnit(time, matchDataChanged, "nameplate", arg1, nil, event == "NAME_PLATE_UNIT_REMOVED")
  elseif event == "ENCOUNTER_START" or event == "ENCOUNTER_END" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
    UpdateGroupCountFor("boss")
    ScanAllBoss(time, matchDataChanged)
  elseif event =="ARENA_OPPONENT_UPDATE" then
    UpdateGroupCountFor("arena")
    ScanGroupUnit(time, matchDataChanged, "arena", arg1)
  elseif event == "GROUP_ROSTER_UPDATE" then
    UpdatePerGroupUnitScanFuncs()
    UpdateGroupCountFor("group")
    -- We reset matchDataByTrigger here, because of role changes. Tracking
    -- those accurately is possible but feel like it is too much effort for the gain
    -- it brings.
    ScanAllGroup(time, matchDataChanged, true)

    for index, triggerInfo in ipairs(groupScanFuncs) do
      matchDataChanged[triggerInfo.id] = matchDataChanged[triggerInfo.id] or {}
      matchDataChanged[triggerInfo.id][triggerInfo.triggernum] = true
    end
  elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
    if arg1 == "player" then
      ScanGroupUnit(time, matchDataChanged, nil, "vehicle")
    end
  elseif event == "UNIT_AURA" then
    if (arg1:sub(1,4) == "raid" and IsInRaid()) then
      ScanGroupUnit(time, matchDataChanged, "group", arg1)
    elseif ((arg1:sub(1,5) == "party" or arg1 == "player") and not IsInRaid()) then
      ScanGroupUnit(time, matchDataChanged, "group", arg1)
    elseif arg1:sub(1,4) == "boss" then
      ScanGroupUnit(time, matchDataChanged, "boss", arg1)
    elseif arg1:sub(1,5) == "arena" then
      ScanGroupUnit(time, matchDataChanged, "arena", arg1)
    elseif arg1:sub(1, 9) == "nameplate" then
      ScanGroupUnit(time, matchDataChanged, "nameplate", arg1)
    else
      ScanGroupUnit(time, matchDataChanged, nil, arg1)
    end
  end
  WeakAuras.StopProfileSystem("bufftrigger2")
end)

frame:SetScript("OnUpdate", function()
  if WeakAuras.IsPaused() then
    return
  end
  WeakAuras.StartProfileSystem("bufftrigger2")
  if next(matchDataChanged) then
    local time = GetTime()
    UpdateStates(matchDataChanged, time)
    wipe(matchDataChanged)
  end
  WeakAuras.StopProfileSystem("bufftrigger2")
end)

function BuffTrigger.ScanAll()
  local units = {}
  local time = GetTime()

  for unit in pairs(scanFuncName) do
    units[unit] = true
  end

  for unit in pairs(scanFuncSpellId) do
    units[unit] = true
  end

  for unit in pairs(scanFuncGeneral) do
    units[unit] = true
  end

  for unit in pairs(units) do
    if unit == "group" then
      ScanAllGroup(time, matchDataChanged)
    elseif unit == "boss" then
      ScanAllBoss(time, matchDataChanged)
    elseif unit == "nameplate" then
      local time = GetTime()
      for i = 1, 40 do
        ScanGroupUnit(time, matchDataChanged, "nameplate", "nameplate" .. i)
      end
    else
      ScanGroupUnit(time, matchDataChanged, nil, unit)
    end
  end
end

local function UnloadAura(scanFuncName, id)
  for unit, unitData in pairs(scanFuncName) do
    for debuffType, debuffData in pairs(unitData) do
      for name, nameData in pairs(debuffData) do
        for i = #nameData, 1, -1 do
          if nameData[i].id == id or not id then
            if nameData[i].nextScheduledCheckHandle then
              timer:CancelTimer(nameData[i].nextScheduledCheckHandle)
            end
            tremove(nameData, i)
          end
        end
        if #nameData == 0 then
          debuffData[name] = nil
        end
      end

      if not next(debuffData) then
        unitData[debuffType] = nil
      end
    end
    if not next(unitData) then
      scanFuncName[unit] = nil
    end
  end
end

local function UnloadGeneral(scanFuncGeneral, id)
  for unit, unitData in pairs(scanFuncGeneral) do
    for debuffType, debuffData in pairs(unitData) do
      for i = #debuffData, 1, -1 do
        if debuffData[i].id == id or not id then
          if debuffData[i].nextScheduledCheckHandle then
            timer:CancelTimer(debuffData[i].nextScheduledCheckHandle)
          end
          tremove(debuffData, i)
        end
      end
      if #debuffData == 0 then
        unitData[debuffType] = nil
      end
    end
    if not next(unitData) then
      scanFuncGeneral[unit] = nil
    end
  end
end

function BuffTrigger.UnloadAll()
  UnloadAura(scanFuncName, nil)
  UnloadAura(scanFuncSpellId, nil)
  UnloadGeneral(scanFuncGeneral, nil)

  for unit, unitData in pairs(matchData) do
    for filter, filterData in pairs(unitData) do
      for index, indexData in pairs(filterData) do
        wipe(indexData.auras)
      end
    end
  end

  wipe(scanFuncName)
  wipe(scanFuncSpellId)
  wipe(scanFuncGeneral)
  wipe(scanFuncNameGroup)
  wipe(scanFuncSpellIdGroup)
  wipe(scanFuncGeneralGroup)
  wipe(scanFuncNameMulti)
  wipe(scanFuncSpellIdMulti)
  wipe(unitExistScanFunc)
  wipe(groupScanFuncs)
  wipe(groupCountScanFunc)
  wipe(matchDataByTrigger)
  wipe(matchDataMulti)
  wipe(matchDataChanged)
end

local function AddScanFuncs(triggerInfo, unit, scanFuncName, scanFuncSpellId, scanFuncGeneral)
  local filter = triggerInfo.debuffType
  if triggerInfo.auranames then
    for _, name in ipairs(triggerInfo.auranames) do
      if name ~= "" then
        local base = unit and GetOrCreateSubTable(scanFuncName, unit, filter, name) or GetOrCreateSubTable(scanFuncName, filter, name)
        tinsert(base, triggerInfo)
      end
    end
  end

  if triggerInfo.auraspellids then
    for _, spellId in ipairs(triggerInfo.auraspellids) do
      local base = unit and GetOrCreateSubTable(scanFuncSpellId, unit, filter, spellId) or GetOrCreateSubTable(scanFuncSpellId, filter, spellId)
      tinsert(base, triggerInfo)
    end
  end

  if not triggerInfo.auranames and not triggerInfo.auraspellids and scanFuncGeneral then
    local base = GetOrCreateSubTable(scanFuncGeneral, unit, filter)
    tinsert(base, triggerInfo)
  end
end

local function LoadAura(id, triggernum, triggerInfo)
  local filter = triggerInfo.debuffType
  local time = GetTime();

  if triggerInfo.unit == "multi" then
     AddScanFuncs(triggerInfo, nil, scanFuncNameMulti, scanFuncSpellIdMulti, nil)
  elseif triggerInfo.unit == "group" then
    -- Update per group scan funcs
    if IsInRaid() then
      for i = 1, 40 do
        local unit = WeakAuras.raidUnits[i]
        if UnitExists(unit) then
          local isSelf = UnitIsUnit("player", unit)
          local role = UnitGroupRolesAssigned(unit)
          if TriggerInfoApplies(triggerInfo, isSelf, role) then
            AddScanFuncs(triggerInfo, unit, scanFuncNameGroup, scanFuncSpellIdGroup, scanFuncGeneralGroup)
          end
        end
      end
    else
      local unit = "player"
      local role = UnitGroupRolesAssigned(unit)
      if TriggerInfoApplies(triggerInfo, true, role) then
        AddScanFuncs(triggerInfo, unit, scanFuncNameGroup, scanFuncSpellIdGroup, scanFuncGeneralGroup)
      end
      for i = 1, 4 do
        unit = WeakAuras.partyUnits[i]
        if UnitExists(unit) then
          local isSelf = UnitIsUnit("player", unit)
          local role = UnitGroupRolesAssigned(unit)
          if TriggerInfoApplies(triggerInfo, isSelf, role) then
            AddScanFuncs(triggerInfo, unit, scanFuncNameGroup, scanFuncSpellIdGroup, scanFuncGeneralGroup)
          end
        end
      end
    end
    -- Add then to the normal scan func maps too, because that's where FilterScanFuncs looks
    -- them up on GROUP_ROSTER_UPDATE
    AddScanFuncs(triggerInfo, triggerInfo.unit, scanFuncName, scanFuncSpellId, scanFuncGeneral)
  else
    AddScanFuncs(triggerInfo, triggerInfo.unit, scanFuncName, scanFuncSpellId, scanFuncGeneral)
  end

  if triggerInfo.unitExists ~= nil then
    unitExistScanFunc[triggerInfo.unit] = unitExistScanFunc[triggerInfo.unit] or {}
    unitExistScanFunc[triggerInfo.unit][id] = unitExistScanFunc[triggerInfo.unit][id] or {}
    tinsert(unitExistScanFunc[triggerInfo.unit][id], triggerInfo)

    if existingUnits[triggerInfo.unit] == nil then
      existingUnits[triggerInfo.unit] = UnitExists(triggerInfo.unit)
    end
  end
  if triggerInfo.groupCountFunc or triggerInfo.perUnitMode == "unaffected" or triggerInfo.perUnitMode == "all" then
    tinsert(groupCountScanFunc, triggerInfo)
  end

  if triggerInfo.unit == "group" then
    tinsert(groupScanFuncs, triggerInfo)
  end

  -- set up initial states
    -- Check against existing match data
  if triggerInfo.unit == "multi" then
    -- We don't check against existing data, as it would be rather random what it would pick up
    -- since that depends on what other auras are loaded at that time
  elseif triggerInfo.groupTrigger then
    for unit in GetAllUnits(triggerInfo.unit) do
      local isSelf = UnitIsUnit("player", unit)
      local role = UnitGroupRolesAssigned(unit)
      if TriggerInfoApplies(triggerInfo, isSelf, role) then
        PrepareMatchData(unit, filter)
        if matchData[unit] and matchData[unit][filter] then
          for index, match in pairs(matchData[unit][filter]) do
            if (not triggerInfo.auranames and not triggerInfo.auraspellids)
                or (triggerInfo.auranames and tContains(triggerInfo.auranames, match.name))
                or (triggerInfo.auraspellids and tContains(triggerInfo.auraspellids, match.spellId)) then
              if not triggerInfo.scanFunc or triggerInfo.scanFunc(time, matchData[unit][filter][index]) then
                if triggerInfo.fetchTooltip then
                  matchData[unit][filter][index]:UpdateTooltip(time)
                end
                ReferenceMatchData(id, triggernum, unit, filter, index)
              end
            end
          end
        end
      end
    end
  else
    PrepareMatchData(triggerInfo.unit, filter)
    if matchData[triggerInfo.unit] and matchData[triggerInfo.unit][filter] then
      for index, match in pairs(matchData[triggerInfo.unit][filter]) do
        if (not triggerInfo.auranames and not triggerInfo.auraspellids
            or (triggerInfo.auranames and tContains(triggerInfo.auranames, match.name))
            or (triggerInfo.auraspellids and tContains(triggerInfo.auraspellids, match.spellId))) then
          if not triggerInfo.scanFunc or triggerInfo.scanFunc(time, matchData[triggerInfo.unit][filter][index]) then
            if triggerInfo.fetchTooltip then
              matchData[triggerInfo.unit][filter][index]:UpdateTooltip(time)
            end
            ReferenceMatchData(id, triggernum, triggerInfo.unit, filter, index)
          end
        end
      end
    end
  end

  matchDataChanged[id] = matchDataChanged[id] or {}
  matchDataChanged[id][triggernum] = true
end

function BuffTrigger.LoadDisplays(toLoad)
  for id in pairs(toLoad) do
    if triggerInfos[id] then
      for triggernum, triggerInfo in pairs(triggerInfos[id]) do
        LoadAura(id, triggernum, triggerInfo)
      end
    end
  end
end

function BuffTrigger.UnloadDisplays(toUnload)
  local updateGroupScanFuncs = false
  for id in pairs(toUnload) do
    if triggerInfos[id] then
      for triggernum, triggerInfo in pairs(triggerInfos[id]) do
        updateGroupScanFuncs = triggerInfos.unit == "group" or updateGroupScanFuncs
      end
    end
    UnloadAura(scanFuncName, id)
    UnloadAura(scanFuncSpellId, id)
    UnloadGeneral(scanFuncGeneral, id)

    UnloadAura(scanFuncNameGroup, id)
    UnloadAura(scanFuncSpellIdGroup, id)
    UnloadGeneral(scanFuncGeneralGroup, id)

    UnloadGeneral(scanFuncNameMulti, id)
    UnloadGeneral(scanFuncSpellIdMulti, id)

    for unit, unitData in pairs(unitExistScanFunc) do
      unitData[id] = nil
    end

    for i = #groupCountScanFunc, 1, -1 do
      if groupCountScanFunc[i].id == id then
        tremove(groupCountScanFunc, i)
      end
    end

    for i = #groupScanFuncs, 1, -1 do
      if groupScanFuncs[i].id == id then
        tremove(groupScanFuncs, i)
      end
    end

    for unit, unitData in pairs(matchData) do
      for filter, filterData in pairs(unitData) do
        for index, indexData in pairs(filterData) do
          indexData.auras[id] = nil
        end
      end
    end
    matchDataByTrigger[id] = nil

    for guid, guidData in pairs(matchDataMulti) do
      for key, data in pairs(matchDataMulti[guid]) do
        for source, sourceData in pairs(data) do
          sourceData.auras[id] = nil
        end
      end
    end
    matchDataChanged[id] = nil
  end

  if updateGroupScanFuncs then
    UpdatePerGroupUnitScanFuncs()
  end
end

function BuffTrigger.FinishLoadUnload()
  -- Nothing!
end

--- Removes all data for an aura id
-- @param id
function BuffTrigger.Delete(id)
  BuffTrigger.UnloadDisplays({[id] = true})
  triggerInfos[id] = nil
end

--- Updates all data for aura oldid to use newid
-- @param oldid
-- @param newid
function BuffTrigger.Rename(oldid, newid)
  triggerInfos[newid] = triggerInfos[oldid]
  triggerInfos[oldid] = nil

  if triggerInfos[newid] then
    for triggernum, triggerData in pairs(triggerInfos[newid]) do
      triggerData.id = newid
    end
  end

  matchDataByTrigger[newid] = matchDataByTrigger[oldid]
  matchDataByTrigger[oldid] = nil

  for unit, unitData in pairs(matchData) do
    for filter, filterData in pairs(unitData) do
      for index, indexData in pairs(filterData) do
        indexData.auras[newid] = indexData.auras[oldid]
        indexData.auras[oldid] = nil
      end
    end
  end

  for unit, unitData in pairs(unitExistScanFunc) do
    unitData[newid] = unitData[oldid]
    unitData[oldid] = nil
  end
  matchDataChanged[newid] = matchDataChanged[oldid]
  matchDataChanged[oldid] = nil
end

local function createScanFunc(trigger)
  local isSingleMissing = IsSingleMissing(trigger)
  local isMulti = trigger.unit == "multi"
  local useStacks = not isSingleMissing and not isMulti and trigger.useStacks
  local use_stealable = not isSingleMissing and not isMulti and trigger.use_stealable
  local use_debuffClass = not isSingleMissing and not isMulti and trigger.use_debuffClass
  local use_tooltip = not isSingleMissing and not isMulti and trigger.fetchTooltip and trigger.use_tooltip
  local use_tooltipValue = not isSingleMissing and not isMulti and trigger.fetchTooltip and trigger.use_tooltipValue

  if not useStacks and use_stealable == nil and not use_debuffClass and trigger.ownOnly == nil and not use_tooltip and not use_tooltipValue and not trigger.useNamePattern then
    return nil
  end

  local ret = [[
    return function(time, matchData)
  ]]

  if useStacks then
    local ret2 = [[
      if not(matchData.stacks %s %s) then
        return false
      end
    ]]
    ret = ret .. ret2:format(trigger.stacksOperator or ">=", tonumber(trigger.stacks) or 0)
  end

  if use_stealable then
    ret = ret .. [[
      if not matchData.isStealable then
        return false
      end
    ]]
  elseif use_stealable == false then
    ret = ret .. [[
      if matchData.isStealable then
        return false
      end
    ]]
  end

  if use_debuffClass and trigger.debuffClass then
    local ret2 = [[
      if matchData.debuffClass ~= %q then
        return false
      end
    ]]
    ret = ret .. ret2:format(trigger.debuffClass)
  end

  if trigger.ownOnly then
    ret = ret .. [[
      if matchData.unitCaster ~= 'player' then
        return false
      end
    ]]
  elseif trigger.ownOnly == false then
    ret = ret .. [[
      if matchData.unitCaster == 'player' then
        return false
      end
    ]]
  end

  if use_tooltip and trigger.tooltip_operator and trigger.tooltip then
    if trigger.tooltip_operator == "==" then
      local ret2 = [[
      if not matchData.tooltip or not matchData.tooltip == %q then
        return false
      end
      ]]
      ret = ret .. ret2:format(trigger.tooltip)
    elseif trigger.tooltip_operator == "find('%s')" then
      local ret2 = [[
      if not matchData.tooltip or not matchData.tooltip:find(%q) then
        return false
      end
      ]]
      ret = ret .. ret2:format(trigger.tooltip)
    elseif trigger.tooltip_operator == "match('%s')" then
      local ret2 = [[
      if not matchData.tooltip or not matchData.tooltip:match(%q) then
        return false
      end
      ]]
      ret = ret .. ret2:format(trigger.tooltip)
    end
  end

  if use_tooltipValue and trigger.tooltipValueNumber and trigger.tooltipValue_operator and trigger.tooltipValue then
    local property = "tooltip" .. tonumber(trigger.tooltipValueNumber)
    local ret2 = [[
      if not matchData.%s or not (matchData.%s %s %s) then
        return false
      end
    ]]
    ret = ret .. ret2:format(property, property, trigger.tooltipValue_operator, trigger.tooltipValue)
  end

  if trigger.useNamePattern and trigger.namePattern_operator and trigger.namePattern_name then
    if trigger.namePattern_operator == "==" then
      local ret2 = [[
      if not matchData.name == %q then
        return false
      end
      ]]
      ret = ret .. ret2:format(trigger.namePattern_name)
    elseif trigger.namePattern_operator == "find('%s')" then
      local ret2 = [[
      if not matchData.name:find(%q) then
        return false
      end
      ]]
      ret = ret .. ret2:format(trigger.namePattern_name)
    elseif trigger.namePattern_operator == "match('%s')" then
      local ret2 = [[
      if not matchData.name:match(%q) then
        return false
      end
      ]]
      ret = ret .. ret2:format(trigger.namePattern_name)
    end
  end

  ret = ret .. [[
      return true
    end
  ]]

  local func, err = loadstring(ret)

  if func then
    return func()
  end
end

local function highestExpirationTime(bestMatch, auraMatch)
  if bestMatch.expirationTime and auraMatch.expirationTime then
    return auraMatch.expirationTime > bestMatch.expirationTime
  end
  return true
end

local function lowestExpirationTime(bestMatch, auraMatch)
  if bestMatch.expirationTime and auraMatch.expirationTime then
    return auraMatch.expirationTime < bestMatch.expirationTime
  end
  return false
end

local function GreaterEqualOne(x)
  return x >= 1
end

local function EqualZero(x)
  return x == 0
end

--- Adds an aura, setting up internal data structures for all buff triggers.
-- @param data
function BuffTrigger.Add(data)
  local id = data.id

  triggerInfos[id] = nil
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger
    if trigger.type == "aura2" then

      trigger.unit = trigger.unit or "player"
      trigger.debuffType = trigger.debuffType or "HELPFUL"

      local combineMode = "showOne"
      local perUnitMode
      if not IsSingleMissing(trigger) and trigger.showClones then
        if IsGroupTrigger(trigger) and trigger.combinePerUnit then
          combineMode = "showPerUnit"
          if trigger.unit == "multi" then
            perUnitMode = "affected"
          else
            perUnitMode = trigger.perUnitMode or "affected"
          end
        else
          combineMode = "showClones"
        end
      end

      local scanFunc = createScanFunc(trigger)

      local remFunc
      if trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useRem then
        local remFuncStr = WeakAuras.function_strings.count:format(trigger.remOperator or ">=", tonumber(trigger.rem) or 0)
        remFunc = WeakAuras.LoadFunction(remFuncStr)
      end

      local names
      if trigger.useName and trigger.auranames then
        names = {}
        for index, spellName in ipairs(trigger.auranames) do
          local spellId = tonumber(spellName)
          names[index] = GetSpellInfo(spellId) or spellName
        end
      end

      local showIfInvalidUnit
      if trigger.unit ~= "player" and not IsGroupTrigger(trigger) then
        showIfInvalidUnit = trigger.unitExists or false
      end
      local effectiveUseGroupCount = IsGroupTrigger(trigger) and trigger.useGroup_count
      local groupCountFunc
      if effectiveUseGroupCount then
        local group_countFuncStr
        local count, countType = WeakAuras.ParseNumber(trigger.group_count)
        if trigger.group_countOperator and count and countType then
          if countType == "whole" then
            group_countFuncStr = WeakAuras.function_strings.count:format(trigger.group_countOperator, count)
          else
            group_countFuncStr = WeakAuras.function_strings.count_fraction:format(trigger.group_countOperator, count)
          end
        else
          group_countFuncStr = WeakAuras.function_strings.count:format(">", 0)
        end
        groupCountFunc = WeakAuras.LoadFunction(group_countFuncStr)
      end

      local matchCountFunc
      if HasMatchCount(trigger) and trigger.match_countOperator and trigger.match_count then
        local count = tonumber(trigger.match_count)
        local match_countFuncStr = WeakAuras.function_strings.count:format(trigger.match_countOperator, count)
        matchCountFunc = WeakAuras.LoadFunction(match_countFuncStr)
      elseif IsGroupTrigger(trigger) then
        if trigger.showClones and not trigger.combinePerUnit then
          matchCountFunc = GreaterEqualOne
        end
      elseif not IsGroupTrigger(trigger) then
        if trigger.matchesShowOn == "showOnMissing" then
          matchCountFunc = EqualZero
        elseif trigger.matchesShowOn == "showOnActive" or not trigger.matchesShowOn then
          matchCountFunc = GreaterEqualOne
        end
      end

      local effectiveIgnoreSelf = trigger.unit == "group" and trigger.ignoreSelf
      local effectiveGroupRole = trigger.unit == "group" and trigger.useGroupRole and trigger.group_role

      if trigger.unit == "multi" then
        BuffTrigger.InitMultiAura()
      end

      local fallbackName, fallbackIcon = BuffTrigger.GetNameAndIconSimple(data, triggernum)

      local auraspellids
      if trigger.useExactSpellId and trigger.auraspellids then
        auraspellids = {}
        for _, spellIdString in ipairs(trigger.auraspellids) do
          if spellIdString ~= "" then
            local spellId = tonumber(spellIdString)
            if spellId then
              tinsert(auraspellids, spellId)
            end
          end
        end
      end

      local triggerInformation = {
        auranames = names,
        auraspellids = auraspellids,
        unit = trigger.unit == "member" and trigger.specificUnit or trigger.unit,
        debuffType = trigger.debuffType,
        ownOnly = trigger.ownOnly,
        combineMode = combineMode,
        perUnitMode = perUnitMode,
        scanFunc = scanFunc,
        remainingFunc = remFunc,
        remainingCheck = trigger.unit ~= "multi" and not IsSingleMissing(trigger) and trigger.useRem and tonumber(trigger.rem) or 0,
        id = id,
        triggernum = triggernum,
        compareFunc = trigger.combineMode == "showHighest" and highestExpirationTime or lowestExpirationTime,
        unitExists = showIfInvalidUnit,
        fetchTooltip = not IsSingleMissing(trigger) and trigger.unit ~= "multi" and trigger.fetchTooltip,
        groupTrigger = IsGroupTrigger(trigger),
        ignoreSelf = effectiveIgnoreSelf,
        groupRole = effectiveGroupRole,
        groupCountFunc = groupCountFunc,
        matchCountFunc = matchCountFunc,
        useAffected = trigger.unit == "group" and trigger.useAffected,
        isMulti = trigger.unit == "multi",
        fallbackName = fallbackName,
        fallbackIcon = fallbackIcon,
      }
      triggerInfos[id] = triggerInfos[id] or {}
      triggerInfos[id][triggernum] = triggerInformation
    end
  end
end

--- Updates old data to the new format.
-- @param data
function BuffTrigger.Modernize(data)
  -- Does nothing yet!
end

--- Returns whether the trigger can have a duration.
-- @param data
-- @param triggernum
function BuffTrigger.CanHaveDuration(data, triggernum)
  return "timed"
end

--- Returns a table containing the names of all overlays
-- @param data
-- @param triggernum
function BuffTrigger.GetOverlayInfo(data, triggernum)
  return {}
end

--- Returns whether the icon can be automatically selected.
-- @param data
-- @param triggernum
-- @return boolean
function BuffTrigger.CanHaveAuto(data, triggernum)
  return true
end

--- Returns whether the trigger can have clones.
-- @param data
-- @param triggernum
-- @return
function BuffTrigger.CanHaveClones(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  if not IsSingleMissing(trigger) and trigger.showClones then
    return true
  end
  return false
end

---Returns the type of tooltip to show for the trigger.
-- @param data
-- @param triggernum
-- @return string
function BuffTrigger.CanHaveTooltip(data, triggernum)
  return "aura"
end

function BuffTrigger.SetToolTip(trigger, state)
  if trigger.debuffType == "HELPFUL" then
    GameTooltip:SetUnitBuff(state.unit, state.index)
  elseif trigger.debuffType == "HARMFUL" then
    GameTooltip:SetUnitDebuff(state.unit, state.index)
  end
end


function BuffTrigger.GetNameAndIconSimple(data, triggernum)
  local _, name, icon
  local trigger = data.triggers[triggernum].trigger

  if trigger.useName and trigger.auranames then
    for index, spellName in ipairs(trigger.auranames) do
      local spellId = tonumber(spellName)
      if spellId then
        name, _, icon = GetSpellInfo(spellName)
        if name and icon then
          return name, icon
        end
      else
        name, _, icon = GetSpellInfo(spellName)
        if (name and icon) then
          return name, icon
        end
      end
    end
  end

  if trigger.useExactSpellId and trigger.auraspellids then
    for index, spellIdString in ipairs(trigger.auraspellids) do
      local spellId = spellIdString ~= "" and tonumber(spellIdString)
      if spellId then
        name, _, icon = GetSpellInfo(spellIdString)
        if name and icon then
          return name, icon
        end
      end
    end
  end
end

--- Returns the name and icon to show in the options.
-- @param data
-- @param triggernum
-- @return name and icon
function BuffTrigger.GetNameAndIcon(data, triggernum)
  local name, icon = BuffTrigger.GetNameAndIconSimple(data, triggernum)
  if (not name or not icon and WeakAuras.spellCache) then
    local trigger = data.triggers[triggernum].trigger
    if trigger.useName and trigger.auranames then
      for index, spellName in ipairs(trigger.auranames) do
        icon = WeakAuras.spellCache.GetIcon(spellName)
        if icon then
          return spellName, icon
        end
      end
    end
  end
  return name, icon
end

--- Returns the tooltip text for additional properties.
-- @param data
-- @param triggernum
-- @return string of additional properties
function BuffTrigger.GetAdditionalProperties(data, triggernum)
  local trigger = data.triggers[triggernum].trigger

  local ret = "\n\n" .. L["Additional Trigger Replacements"] .. "\n"
  ret = ret .. "|cFFFF0000%spellId|r - " .. L["Spell ID"] .. "\n"
  ret = ret .. "|cFFFF0000%unitCaster|r - " .. L["Caster Unit"] .. "\n"
  ret = ret .. "|cFFFF0000%casterName|r - " .. L["Caster Name"] .. "\n"
  ret = ret .. "|cFFFF0000%unitName|r - " .. L["Unit Name"] .. "\n"
  ret = ret .. "|cFFFF0000%matchCount|r - " .. L["Match Count"] .. "\n"
  ret = ret .. "|cFFFF0000%unitCount|r - " .. L["Units Affected"] .. "\n"

  if trigger.unit ~= "multi" then
    ret = ret .. "|cFFFF0000%maxUnitCount|r - " .. L["Total Units"] .. "\n"
  end

  if not IsSingleMissing(trigger) and trigger.unit ~= "multi" and trigger.fetchTooltip then
    ret = ret .. "|cFFFF0000%tooltip|r - " .. L["Tooltip"] .. "\n"
    ret = ret .. "|cFFFF0000%tooltip1|r - " .. L["First Value of Tooltip Text"] .. "\n"
    ret = ret .. "|cFFFF0000%tooltip2|r - " .. L["Second Value of Tooltip Text"] .. "\n"
    ret = ret .. "|cFFFF0000%tooltip3|r - " .. L["Third Value of Tooltip Text"] .. "\n"
  end

  if trigger.unit == "group" and trigger.useAffected then
    ret = ret .. "|cFFFF0000%affected|r - " .. L["Names of affected Players"] .. "\n"
    ret = ret .. "|cFFFF0000%unaffected|r - " .. L["Names of unaffected Players"] .. "\n"
  end

  return ret
end

function BuffTrigger.GetTriggerConditions(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local result = {}

  result["unitCaster"] = {
    display = L["Caster"],
    type = "string"
  }

  result["expirationTime"] = {
    display = L["Remaining Duration"],
    type = "timer"
  }

  result["duration"] = {
    display = L["Total Duration"],
    type = "number"
  }

  result["stacks"] = {
    display = L["Stacks"],
    type = "number"
  }

  result["name"] = {
    display = L["Name"],
    type = "string"
  }

  result["matchCount"] = {
    display = L["Total Match Count"],
    type = "number"
  }

  result["unitCount"] = {
    display = L["Affected Unit Count"],
    type = "number"
  }

  if trigger.unit ~= "multi" then
    result["maxUnitCount"] = {
      display = L["Total Unit Count"],
      type = "number"
    }
  end

  if not IsGroupTrigger(trigger) and trigger.matchesShowOn == "showAlways" then
    result["buffed"] = {
      display = L["Aura(s) Found"],
      type = "bool",
      test = function(state, needle)
        return state and state.show and ((state.active and true or false) == (needle == 1))
      end
    }
  end

  if not IsSingleMissing(trigger) and trigger.unit ~= "multi" and trigger.fetchTooltip then
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

  return result
end

function BuffTrigger.CreateFallbackState(data, triggernum, state)
  state.show = true
  state.changed = true
  state.progressType = "timed"
  state.duration = 0
  state.expirationTime = math.huge
end

function BuffTrigger.GetName(triggerType)
  if triggerType == "aura2" then
    return L["Aura"]
  end
end

function WeakAuras.CanConvertBuffTrigger2(trigger)
  if trigger.type ~= "aura" then
    return false
  end

  if trigger.unit == "multi" then
    return true, L["Note: The available text replacements for multi triggers match the normal triggers now."]
  end

  if trigger.unit and trigger.hideAlone then
    return false, L["Note: 'Hide Alone' is not available in the new aura tracking system. A load option can be used instead."]
  end

  if trigger.unit == "group" then
    return true, L["Warning: Name info is now available via %affected, %unaffected. Number of affected group members via %unitCount. Some options behave differently now. This is not automatically adjusted."]
  end

  if trigger.fullscan then
    if trigger.subcount then
      return true, L["Warning: Tooltip values are now available via %tooltip1, %tooltip2, %tooltip3 instead of %s. This is not automatically adjusted."]
    end

    if trigger.use_name and trigger.use_spellId then
      return false, L["Warning: Full Scan auras checking for both name and spell id can't be converted."]
    end
  end

  return true
end

function WeakAuras.ConvertBuffTrigger2(trigger)
  if not WeakAuras.CanConvertBuffTrigger2(trigger) then
    return
  end
  trigger.type = "aura2"

  if trigger.fullscan and trigger.autoclone then
    trigger.combineMatches = "showClones"
  else
    trigger.combineMatches = "showLowest"
  end

  if trigger.fullscan and trigger.use_stealable then
    trigger.use_stealable = true
  else
    trigger.use_stealable = nil
  end

  if trigger.fullscan and trigger.use_debuffClass and trigger.debuffClass then
  else
    trigger.use_debuffClass = false
  end

  if trigger.fullscan and trigger.use_tooltip then
    trigger.fetchTooltip = true
  else
    trigger.use_tooltip = false
  end

  if trigger.fullscan and trigger.subcount then
    trigger.fetchTooltip = true
  end

  if trigger.fullscan and trigger.use_name then
    trigger.useNamePattern = true
    trigger.namePattern_operator = trigger.name_operator
    trigger.namePattern_name = trigger.name
  end

  if trigger.fullscan then
    -- Use name from fullscan
    if trigger.use_name then
      if trigger.name_operator == "==" then
        -- Convert to normal name check
        trigger.useName = true
        trigger.auranames = {}
        trigger.auranames[1] = trigger.name
      end
    end
    if trigger.use_spellId then
      trigger.useExactSpellId = true
      trigger.auraspellids = {}
      trigger.auraspellids[1] = trigger.spellId
    end
  else
    trigger.useName = true
  end

  if not trigger.fullscan and trigger.unit ~= "multi" then
    trigger.auranames = {}
    for i = 1, 9 do
      trigger.auranames[i] = trigger.spellIds[i] and tostring(trigger.spellIds[i]) or trigger.names[i]
    end
  end

  if trigger.unit == "multi" then
    -- Closest to the old behavior
    trigger.showClones = true
    trigger.useName = true
    trigger.auranames = {}
    trigger.auranames[1] = tostring(trigger.spellId) or trigger.name
  end

  -- debuffType is exactly the same, no need to touch it
  -- remaining is exactly the same for now
  -- ownOnly is exactly the same
  -- unitExists is exactly the same

  if trigger.useCount then
    trigger.useStacks = trigger.useCount
    trigger.stacksOperator = trigger.countOperator
    trigger.stacks = trigger.count
  end

  if trigger.fullscan and trigger.autoclone then
    trigger.matchesShowOn = "showOnActive"
  else
    trigger.matchesShowOn = trigger.buffShowOn
  end

  if trigger.unit == "group" then
    trigger.matchesShowOn = nil
    trigger.showClones = trigger.groupclone
  end

  if trigger.unit == "group" and not trigger.groupclone then
    if trigger.name_info == "players" or trigger.name_info == "nonplayers" then
      trigger.useAffected = true
    end
  end

  if trigger.unit == "group" and trigger.group_countOperator and trigger.group_count then
    trigger.useGroup_count = true
  else
    trigger.useGroup_count = false
  end
end

-- Multi Target trigger code
local multiAuraFrame
local pendingTracks = {}

local unitToGuid = {}
local guidToUnit = {}

local function ReleaseUID(unit)
  local guid = unitToGuid[unit]
  if guid then
    guidToUnit[guid][unit] = nil
  end
end

local function SetUID(guid, unit)
  ReleaseUID(unit)

  unitToGuid[unit] = guid
  guidToUnit[guid] = guidToUnit[guid] or {}
  guidToUnit[guid][unit] = true
end

local function GetUnit(guid)
  if not guidToUnit[guid] then
    return nil
  end
  for unit in pairs(guidToUnit[guid]) do
    if UnitGUID(unit) == guid then
      return unit
    else
      guidToUnit[guid][unit] = nil
    end
  end
end

local function TrackUid(unit)
  local GUID = UnitGUID(unit)
  if GUID then
    SetUID(GUID, unit)
    BuffTrigger.HandlePendingTracks(unit, GUID)
  else
    ReleaseUID(unit)
  end
  unit = unit.."target"
  GUID = UnitGUID(unit)
  if GUID then
    WeakAuras.SetUID(GUID, unit)
    BuffTrigger.HandlePendingTracks(unit, GUID)
  else
    ReleaseUID(unit)
  end
end

local function RemoveMatchDataMulti(base, destGUID, key, sourceGUID)
  if base[key] and base[key][sourceGUID] then
    for id, idData in pairs(base[key][sourceGUID].auras) do
      for triggernum, triggerData in pairs(idData) do
        tDeleteItem(matchDataByTrigger[id][triggernum][destGUID], base[key][sourceGUID])
        if not next(matchDataByTrigger[id][triggernum][destGUID]) then
          matchDataByTrigger[id][triggernum][destGUID] = nil
        end
        matchDataChanged[id] = matchDataChanged[id] or {}
        matchDataChanged[id][triggernum] = true
      end
    end
  end
  base[key] = nil
end

local function CleanUpMulti(guid)
  cleanupTimerMulti[guid].handle = nil
  cleanupTimerMulti[guid].nextTime = nil
  local nextCheck
  if matchDataMulti[guid] then
    local time = GetTime()
    for key, data in pairs(matchDataMulti[guid]) do
      for source, sourceData in pairs(data) do
        local removeAt = sourceData.expirationTime or (sourceData.time + 60)
        if removeAt <= time then
          RemoveMatchDataMulti(matchDataMulti[guid], guid, key, source)
        else
          if not nextCheck then
            nextCheck = removeAt
          elseif (removeAt < nextCheck) then
            nextCheck = removeAt
          end
        end
      end
    end
  end

  if nextCheck then
    local timeUntilNext = nextCheck - GetTime()
    if timeUntilNext > 0 then
     cleanupTimerMulti[guid].handle = timer:ScheduleTimerFixed(CleanUpMulti, timeUntilNext, guid)
     cleanupTimerMulti[guid].nextTime = nextCheck
   end
  end
end

local function ScheduleMultiCleanUp(guid, time)
  cleanupTimerMulti[guid] = cleanupTimerMulti[guid] or {}
  if not cleanupTimerMulti[guid].nextTime or time < cleanupTimerMulti[guid].nextTime then
    if cleanupTimerMulti[guid].handle then
      timer:CancelTimer(cleanupTimerMulti[guid].handle)
    end
    cleanupTimerMulti[guid].handle = timer:ScheduleTimerFixed(CleanUpMulti, time - GetTime(), guid)
    cleanupTimerMulti[guid].nextTime = time
  end
end

local function UpdateMatchDataMulti(time, base, key, event, sourceGUID, sourceName, destGUID, destName, spellId, spellName, amount)
  local updated = false
  local icon = spellId and select(3, GetSpellInfo(spellId))
  ScheduleMultiCleanUp(destGUID, time + 60)
  if not base[key] or not base[key][sourceGUID] then
    updated = true
    base[key] = base[key] or {}
    base[key][sourceGUID] = {
      name = spellName,
      icon = icon,
      duration = 0,
      expirationTime = math.huge,
      spellId = spellId,
      GUID = destGUID,
      sourceGUID = sourceGUID,
      unitName = destName,
      casterName = sourceName,
      time = time,
      auras = {}
    }
  else
    base[key][sourceGUID] = base[key][sourceGUID] or {}
    local match = base[key][sourceGUID]
    match.time = time

    if match.name ~= spellName then
      match.name = spellName
      updated = true
    end

    if match.unitName ~= destName then
      match.unitName = destName
      updated = true
    end

    local duration, expirationTime
    if event == "SPELL_AURA_APPLIED_DOSE" or event == "SPELL_AURA_REMOVED_DOSE" then
      -- Shouldn't affect duration/expirationTime nor icon
      duration = match.duration or 0
      expirationTime = match.expirationTime or math.huge
      icon = match.icon or icon
    else
      duration = 0
      expirationTime = math.huge
    end

    if match.duration ~= duration then
      match.duration = duration
      updated = true
    end

    if match.expirationTime ~= expirationTime then
      match.expirationTime = expirationTime
      updated = true
    end

    if match.icon ~= icon then
      match.icon = icon
      updated = true
    end

    if match.count ~= amount then
      match.count = amount
      updated = true
    end

    if match.spellId ~= spellId then
      match.spellId = spellId
      updated = true
    end

    if match.casterName ~= sourceName then
      match.casterName = sourceName
      updated = true
    end
  end

  return updated
end

local function AugmentMatchDataMultiWith(matchData, unit, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
  ScheduleMultiCleanUp(matchData.GUID, expirationTime)
  local changed = false
  if matchData.name ~= name then
    matchData.name = name
    changed = true
  end

  if matchData.icon ~= icon then
    matchData.icon = icon
    changed = true
  end

  if matchData.stacks ~= stacks then
    matchData.stacks = stacks
    changed = true
  end

  if matchData.debuffClass ~= debuffClass then
    matchData.debuffClass = debuffClass
    changed = true
  end

  if matchData.duration ~= duration then
    matchData.duration = duration
    changed = true
  end

  if matchData.expirationTime ~= expirationTime then
    matchData.expirationTime = expirationTime
    changed = true
  end

  if matchData.unitCaster ~= unitCaster then
    matchData.unitCaster = unitCaster
    changed = true
  end

  local casterName = GetUnitName(unitCaster, false) or ""
  if matchData.casterName ~= casterName then
    matchData.casterName = casterName
    changed = true
  end

  if (matchData.unit ~= unit) then
    matchData.unit = unit
    changed = true
  end

  local unitName = GetUnitName(unit, false) or ""
  if matchData.unitName ~= unitName then
    matchData.unitName = unitName
    changed = true
  end


  if matchData.spellId ~= spellId then
    matchData.spellId = name
    changed = true
  end
  return changed
end

local function AugmentMatchDataMulti(matchData, unit, filter, sourceGUID, nameKey, spellKey)
  local index = 1
  while true do
    local name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, index, filter)
    if not name then
      return false
    end

    if debuffClass == nil then
      debuffClass = "none"
    elseif debuffClass == "" then
      debuffClass = "enrage"
    else
      debuffClass = string.lower(debuffClass)
    end
    local auraSourceGuid = unitCaster and UnitGUID(unitCaster)
    if (name == nameKey or spellId == spellKey) and sourceGUID == auraSourceGuid then
      local changed = AugmentMatchDataMultiWith(matchData, unit, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
      return changed
    end
    index = index + 1
  end
end

local function HandleCombatLog(scanFuncsName, scanFuncsSpellId, filter, event, sourceGUID, sourceName, destGUID, destName, spellId, spellName, amount)
  local time = GetTime()
  local unit = GetUnit(destGUID)
  if scanFuncsName and scanFuncsName[spellName] or scanFuncsSpellId and scanFuncsSpellId[spellId] then
    ScheduleMultiCleanUp(destGUID, time + 60)
    matchDataMulti[destGUID] = matchDataMulti[destGUID] or {}
    matchDataMulti[destGUID][sourceGUID] = matchDataMulti[destGUID][sourceGUID] or {}

    if scanFuncsSpellId and scanFuncsSpellId[spellId] then
      local updatedSpellId = UpdateMatchDataMulti(time, matchDataMulti[destGUID], spellId, event, sourceGUID, sourceName, destGUID, destName, spellId, spellName, amount)
      if unit then
        updatedSpellId = AugmentMatchDataMulti(matchDataMulti[destGUID][spellId][sourceGUID], unit, filter, sourceGUID, nil, spellId) or updatedSpellId
      else
        pendingTracks[destGUID] = true
      end
      if updatedSpellId then
        for index, triggerInfo in ipairs(scanFuncsSpellId[spellId]) do
          if MatchesTriggerInfoMulti(triggerInfo, sourceGUID) then
            ReferenceMatchDataMulti(matchDataMulti[destGUID][spellId][sourceGUID], triggerInfo.id, triggerInfo.triggernum, destGUID)
          end
        end
      end
    end

    if scanFuncsName and scanFuncsName[spellName] then
      local updatedName = UpdateMatchDataMulti(time, matchDataMulti[destGUID], spellName, event, sourceGUID, sourceName, destGUID, destName, spellId, spellName, amount)
      if unit then
        updatedName = AugmentMatchDataMulti(matchDataMulti[destGUID][spellName][sourceGUID], unit, filter, sourceGUID, spellName, nil) or updatedName
      else
        pendingTracks[destGUID] = true
      end
      if updatedName then
        for index, triggerInfo in ipairs(scanFuncsName[spellName]) do
          if MatchesTriggerInfoMulti(triggerInfo, sourceGUID) then
            ReferenceMatchDataMulti(matchDataMulti[destGUID][spellName][sourceGUID], triggerInfo.id, triggerInfo.triggernum, destGUID)
          end
        end
      end
    end
  end
end

local function HandleCombatLogRemove(scanFuncsName, scanFuncsSpellId, sourceGUID, destGUID, spellId, spellName)
  if scanFuncsName and scanFuncsName[spellName] or scanFuncsSpellId and scanFuncsSpellId[spellId] then
    if matchDataMulti[destGUID] then
      RemoveMatchDataMulti(matchDataMulti[destGUID], destGUID, spellId, sourceGUID)
      RemoveMatchDataMulti(matchDataMulti[destGUID], destGUID, spellName, sourceGUID)
    end
  end
end

local function CombatLog(_, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellId, spellName, _, auraType, amount)
  if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED_DOSE" or event == "SPELL_AURA_REMOVED_DOSE" then
    if auraType == "BUFF" then
      HandleCombatLog(scanFuncNameMulti["HELPFUL"], scanFuncSpellIdMulti["HELPFUL"], "HELPFUL", event, sourceGUID, sourceName, destGUID, destName, spellId, spellName, amount)
    elseif auraType == "DEBUFF" then
      HandleCombatLog(scanFuncNameMulti["HARMFUL"], scanFuncSpellIdMulti["HARMFUL"], "HARMFUL", event, sourceGUID, sourceName, destGUID, destName, spellId, spellName, amount)
    end
  elseif event == "SPELL_AURA_REMOVED" then
    if auraType == "BUFF" then
      HandleCombatLogRemove(scanFuncNameMulti["HELPFUL"], scanFuncSpellIdMulti["HELPFUL"], sourceGUID, destGUID, spellId, spellName)
    elseif auraType == "DEBUFF" then
      HandleCombatLogRemove(scanFuncNameMulti["HARMFUL"], scanFuncSpellIdMulti["HARMFUL"], sourceGUID, destGUID, spellId, spellName)
    end
  end
end

local function CheckAurasMulti(base, unit, filter)
  local index = 1
  while true do
    local name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, index, filter)
    if not name then
      return false
    end
    if debuffClass == nil then
      debuffClass = "none"
    elseif debuffClass == "" then
      debuffClass = "enrage"
    else
      debuffClass = string.lower(debuffClass)
    end
    local auraCasterGUID = unitCaster and UnitGUID(unitCaster)
    if base[name] and base[name][auraCasterGUID] then
      local changed = AugmentMatchDataMultiWith(base[name][auraCasterGUID], unit, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
      if changed then
        for id, idData in pairs(base[name][auraCasterGUID].auras) do
          for triggernum in pairs(idData) do
            matchDataChanged[id] = matchDataChanged[id] or {}
            matchDataChanged[id][triggernum] = true
          end
        end
      end
    end
    if base[spellId] and base[spellId][auraCasterGUID] then
      local changed = AugmentMatchDataMultiWith(base[spellId][auraCasterGUID], unit, name, icon, stacks, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId)
      if changed then
        for id, idData in pairs(base[spellId][auraCasterGUID].auras) do
          for triggernum in pairs(idData) do
            matchDataChanged[id] = matchDataChanged[id] or {}
            matchDataChanged[id][triggernum] = true
          end
        end
      end
    end
    index = index + 1
  end
end

function BuffTrigger.HandlePendingTracks(unit, GUID)
  if pendingTracks[GUID] then
    if matchDataMulti[GUID] then
      CheckAurasMulti(matchDataMulti[GUID], unit, "HELPFUL")
      CheckAurasMulti(matchDataMulti[GUID], unit, "HARMFUL")
    end
  end
end

function BuffTrigger.InitMultiAura()
  if not multiAuraFrame then
    multiAuraFrame = CreateFrame("frame")
    multiAuraFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    multiAuraFrame:RegisterEvent("UNIT_TARGET")
    multiAuraFrame:RegisterEvent("UNIT_AURA")
    multiAuraFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    multiAuraFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    multiAuraFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    multiAuraFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    multiAuraFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    multiAuraFrame:SetScript("OnEvent", BuffTrigger.HandleMultiEvent)
    WeakAuras.frames["Multi-target 2 Aura Trigger Handler"] = multiAuraFrame
  end
end

function BuffTrigger.HandleMultiEvent(frame, event, ...)
  WeakAuras.StartProfileSystem("bufftrigger2 - multi")
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    CombatLog(CombatLogGetCurrentEventInfo())
  elseif event == "UNIT_TARGET" then
    TrackUid(...)
  elseif event == "PLAYER_TARGET_CHANGED" then
    TrackUid("target")
  elseif event == "PLAYER_FOCUS_CHANGED" then
    TrackUid("focus")
  elseif event == "NAME_PLATE_UNIT_ADDED" then
    TrackUid(...)
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    local unit = ...
    ReleaseUID(unit)
    unit = unit.."target"
    ReleaseUID(unit)
  elseif event == "PLAYER_LEAVING_WORLD" then
    -- Remove everything..
    for GUID, GUIDData  in pairs(matchDataMulti) do
      for key in pairs(GUIDData) do
        RemoveMatchDataMulti(GUIDData, GUID, key)
      end
    end
    wipe(matchDataMulti)
  end
  WeakAuras.StopProfileSystem("bufftrigger2 - multi")
end

function BuffTrigger.GetTriggerDescription(data, triggernum, namestable)
  local trigger = data.triggers[triggernum].trigger
  if trigger.auranames then
    for index, name in pairs(trigger.auranames) do
      local left = " "
      if(index == 1) then
        if(#trigger.auranames > 0) then
          if(#trigger.auranames > 1) then
            left = L["Auras:"]
          else
            left = L["Aura:"]
          end
        end
      end
      local icon
      local spellId = tonumber(name)
      if spellId then
        icon = select(3, GetSpellInfo(spellId))
      else
        icon = WeakAuras.spellCache.GetIcon(name)
      end
      icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
      tinsert(namestable, {left, name, icon})
    end
  end

  if trigger.auraspellids then
    for index, spellId in pairs(trigger.auraspellids) do
      local left = " "
      if index == 1 then
        if #trigger.auraspellids > 0 then
          if #trigger.auraspellids > 1 then
            left = L["Spell IDs:"]
          else
            left = L["Spell ID:"]
          end
        end
      end

      local icon = select(3, GetSpellInfo(spellId)) or "Interface\\Icons\\INV_Misc_QuestionMark"
      tinsert(namestable, {left, spellId, icon})
    end
  end
end

WeakAuras.RegisterTriggerSystem({"aura2"}, BuffTrigger)
