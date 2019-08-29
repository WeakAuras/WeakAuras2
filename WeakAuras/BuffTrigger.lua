--[[ BuffTrigger.lua
This file contains the "aura" trigger for buffs and debuffs.

It registers the BuffTrigger table for the trigger type "aura" and has the following API:

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

if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local tinsert, wipe = table.insert, wipe
local pairs, next, type = pairs, next, type
local BUFF_MAX_DISPLAY = 255 -- Do tell when you find the real value.
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGroupRolesAssigned = not WeakAuras.IsClassic() and UnitGroupRolesAssigned or function() return "DAMAGER" end

local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local BuffTrigger = {};

local timer = WeakAuras.timer;
local function_strings = WeakAuras.function_strings;
local auras = WeakAuras.auras;
local specificBosses = WeakAuras.specificBosses;
local specificUnits = WeakAuras.specificUnits;
local loaded_auras = WeakAuras.loaded_auras;

WeakAuras.me = GetUnitName("player", true)
WeakAuras.myGUID = nil

local aura_cache = {};
do
  aura_cache.max = 0;
  aura_cache.watched = {};
  aura_cache.players = {};
  aura_cache.TANK = 0;
  aura_cache.HEALER = 0;
  aura_cache.DAMAGER = 0;
  aura_cache.playerRole = "NONE";

  --- Tests if aura_cache data is consistent with trigger settings, eg. OwnOnly, RemainingTime, StackCount.
  -- Extra check needed because aura_cache can potentially contain data of two different triggers with different settings!
  -- @param acEntry
  -- @param data
  -- @return boolean
  local function TestNonUniformSettings(acEntry, data)
    if(data.remFunc) then
      if not(data.remFunc(acEntry.expirationTime - GetTime())) then
        return false
      end
    end

    -- Test OwnOnly
    if (
      data.ownOnly == true  and WeakAuras.myGUID ~= acEntry.casterGUID or
      data.ownOnly == false and WeakAuras.myGUID == acEntry.casterGUID
      ) then
      return false;
    end

    -- Test StackCount
    if (data.count and not data.count(acEntry.count)) then
      return false;
    end

    -- Success
    return true;
  end

  function aura_cache.ForceUpdate()
    if not(WeakAuras.IsPaused()) then
      WeakAuras.ScanAurasGroup()
    end
  end

  function aura_cache.Watch(self, id, triggernum)
    self.watched[id] = self.watched[id] or {};
    self.watched[id][triggernum] = self.watched[id][triggernum] or {};
    self.watched[id][triggernum].players = self.watched[id][triggernum].players or {};
    self:ForceUpdate()
  end

  function aura_cache.Rename(self, oldid, newid)
    self.watched[newid] = self.watched[oldid];
    self.watched[oldid] = nil;
  end

  function aura_cache.Unwatch(self, id, triggernum)
    self.watched[id][triggernum] = nil;
  end

  function aura_cache.GetMaxNumber(self)
    return self.max;
  end

  function aura_cache.GetNumber(self, id, triggernum, data)
    local num = 0;
    for guid, _ in pairs(self.players) do
      -- Need to check if cached data conforms to trigger
      if(self.watched[id][triggernum].players[guid] and TestNonUniformSettings(self.watched[id][triggernum].players[guid], data)) then
        num = num + 1;
      end
    end
    return num;
  end

  function aura_cache.GetDynamicInfo(self, id, triggernum, data)
    local bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestSpellId, bestUnitCaster = 0, math.huge, "", "", 0, 0, "";
    if(self.watched[id] and self.watched[id][triggernum]) then
      for guid, durationInfo in pairs(self.watched[id][triggernum].players) do
        -- Need to check if cached data conforms to trigger
        if(durationInfo.expirationTime < bestExpirationTime and TestNonUniformSettings(durationInfo, data)) then
          bestDuration = durationInfo.duration;
          bestExpirationTime = durationInfo.expirationTime;
          bestName = durationInfo.name;
          bestIcon = durationInfo.icon;
          bestCount = durationInfo.count;
          bestSpellId = durationInfo.spellId;
          bestUnitCaster = durationInfo.unitCaster;
        end
      end
    end
    return bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestSpellId, bestUnitCaster;
  end

  function aura_cache.GetPlayerDynamicInfo(self, id, triggernum, guid, data)
    local bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestSpellId, bestUnitCaster = 0, math.huge, "", "", 0, 0, "";
    if(self.watched[id] and self.watched[id][triggernum]) then
      local durationInfo = self.watched[id][triggernum].players[guid]
      if(durationInfo) then
        -- Need to check if cached data conforms to trigger
        if(durationInfo.expirationTime < bestExpirationTime and TestNonUniformSettings(durationInfo, data)) then
          bestDuration = durationInfo.duration;
          bestExpirationTime = durationInfo.expirationTime;
          bestName = durationInfo.name;
          bestIcon = durationInfo.icon;
          bestCount = durationInfo.count;
          bestSpellId = durationInfo.spellId;
          bestUnitCaster = durationInfo.unitCaster;
        end
      end
    end
    return bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestSpellId, bestUnitCaster;
  end

  function aura_cache.GetAffected(self, id, triggernum, data)
    local affected = {};
    if(self.watched[id] and self.watched[id][triggernum]) then
      for guid, acEntry in pairs(self.watched[id][triggernum].players) do
        -- Need to check if cached data conforms to trigger
        if (TestNonUniformSettings(acEntry, data)) then
          affected[self.players[guid]] = true;
        end
      end
    end
    return affected;
  end

  function aura_cache.GetUnaffected(self, id, triggernum, data)
    local affected = self:GetAffected(id, triggernum, data);
    local ret = {};
    for guid, name in pairs(self.players) do
      if not(affected[name]) then
        ret[name] = true;
      end
    end
    return ret;
  end

  function aura_cache.AssertAura(self, id, triggernum, guid, duration, expirationTime, name, icon, count, casterGUID, spellId, unitCaster)
    -- Don't watch aura on non watched players
    if not self.players[guid] then return end

    if not(self.watched[id][triggernum].players[guid]) then
      self.watched[id][triggernum].players[guid] = {
        duration = duration,
        expirationTime = expirationTime,
        name = name,
        icon = icon,
        count = count,
        unitCaster = unitCaster,
        spellId = spellId,
        casterGUID = casterGUID
      };
    else
      local auradata = self.watched[id][triggernum].players[guid];
      if(expirationTime ~= auradata.expirationTime) then
        auradata.duration = duration;
        auradata.expirationTime = expirationTime;
        auradata.name = name;
        auradata.icon = icon;
        auradata.count = count;
        auradata.unitCaster = unitCaster;
        auradata.spellId = spellId;
        auradata.casterGUID = casterGUID;
      end
    end
  end

  function aura_cache.DeassertAura(self, id, triggernum, guid)
    if(self.watched[id] and self.watched[id][triggernum] and self.watched[id][triggernum].players[guid]) then
      self.watched[id][triggernum].players[guid] = nil;
    end
  end

  function aura_cache.AssertMember(self, guid, name)
    if not(self.players[guid]) then
      self.max = self.max + 1;
    end
    self.players[guid] = name;
  end

  function aura_cache.DeassertMember(self, guid)
    if(self.players[guid]) then
      self.players[guid] = nil;
      for id, v in pairs(self.watched) do
        for triggernum, _ in pairs(v) do
          self:DeassertAura(id, triggernum, guid);
        end
      end
      self.max = self.max - 1;
    end
  end

  function aura_cache.AssertMemberList(self, guids)
    local toDelete = {};

    for guid, _ in pairs(self.players) do
      if not(guids[guid]) then
        toDelete[guid] = true;
      end
    end

    for guid, _ in pairs(toDelete) do
      self:DeassertMember(guid);
    end
    for guid, name in pairs(guids) do
      self:AssertMember(guid, name);
    end
    self:ForceUpdate();
  end
end
WeakAuras.aura_cache = aura_cache;

function WeakAuras.SetAuraVisibility(id, triggernum, cloneId, buffShowOn, unitExists, active, unit, duration, expirationTime, name, icon, count, index, spellId, unitCaster)
  local triggerState = WeakAuras.GetTriggerStateForTrigger(id, triggernum);

  local show;
  if (not UnitExists(unit)) then
    show = unitExists;
  elseif (buffShowOn == "showAlways") then
    show = true;
  elseif(buffShowOn == "showOnMissing") then
    show = not active;
  else
    show = active;
  end

  cloneId = cloneId or "";

  if (not show and not triggerState[cloneId]) then
    return false;
  end

  triggerState[cloneId] = triggerState[cloneId] or {};
  local state = triggerState[cloneId];
  if (state.show ~= show) then
    state.show = show;
    state.changed = true;
  end

  if (state.show) then
    if (state.active ~= active) then
      state.active = active;
      state.changed = true;
    end
    if (state.index ~= index) then
      state.index = index;
      state.changed = true;
    end

    if (state.spellId ~= spellId) then
      state.spellId = spellId;
      state.changed = true;
    end

    if (state.progressType ~= "timed") then
      state.progressType = "timed";
      state.changed = true;
    end

    if (state.expirationTime ~= expirationTime) then
      state.expirationTime = expirationTime;
      state.changed = true;
    end

    if (state.duration ~= duration) then
      state.duration = duration;
      state.changed = true;
    end

    local autoHide = false;
    if (state.autoHide ~= autoHide) then
      state.autoHide = autoHide;
      state.changed = true;
    end

    if (state.name ~= name) then
      state.name = name;
      state.changed = true;
    end

    if (state.icon ~= icon) then
      state.icon = icon;
      state.changed = true;
    end

    if (state.stacks ~= count) then
      state.stacks = count;
      state.changed = true;
    end

    unitCaster = unitCaster and UnitName(unitCaster);
    if (state.unitCaster ~= unitCaster) then
      state.unitCaster = unitCaster;
      state.changed = true;
    end

    if (state.GUID ~= UnitGUID(unit)) then
      state.GUID = UnitGUID(unit);
      state.changed = true;
    end
  end

  if (state.changed) then
    return true;
  end
  return false;
end

--- Calls GetSpellInfo on trigger data to return aura name and icon.
-- @param trigger
-- @return name and icon
local function GetNameAndIconFromTrigger(trigger)
  if (trigger.fullscan) then
    if (trigger.spellId) then
      local name, _, icon = GetSpellInfo(trigger.spellId);
      return name, icon;
    end
    if (trigger.name) then
      return trigger.name, WeakAuras.GetDynamicIconCache(trigger.name);
    end
  else
    if (trigger.spellIds and trigger.spellIds[1]) then
      local name, _, icon = GetSpellInfo(trigger.spellIds[1]);
      return name, icon;
    end
    if (trigger.names and trigger.names[1]) then
      return trigger.names[1], WeakAuras.GetDynamicIconCache(trigger.names[1]);
    end
  end
end

local aura_scan_cache = {};
local aura_lists = {};
function WeakAuras.ScanAuras(unit)
  local time = GetTime();

  -- Reset scan cache for this unit
  aura_scan_cache[unit] = aura_scan_cache[unit] or {};
  for i,v in pairs(aura_scan_cache[unit]) do
    v.up_to_date = 0;
  end

  -- Make unit available outside
  local old_unit = WeakAuras.CurrentUnit;
  WeakAuras.CurrentUnit = unit;

  local fixedUnit = unit == "party0" and "player" or unit
  local uGUID = UnitGUID(fixedUnit) or fixedUnit;

  -- Link corresponding display (and aura cache)
  local aura_object;
  wipe(aura_lists);
  if(unit:sub(1, 4) == "raid") then
    if(aura_cache.players[uGUID]) then
      aura_lists[1] = loaded_auras["group"];
      aura_object = aura_cache;
    end
  elseif(unit:sub(1, 5) == "party") then
    aura_lists[1] = loaded_auras["group"];
    aura_object = aura_cache;
  elseif(specificBosses[unit]) then
    aura_lists[1] = loaded_auras["boss"];
  elseif(unit:sub(1,5) == "arena") then
    aura_lists[1] = loaded_auras["arena"];
  else
    if(unit == "player" and loaded_auras["group"]) then
      WeakAuras.ScanAuras("party0");
    end
    aura_lists[1] = loaded_auras[unit];
  end

  -- Add group auras for specific units -- XXX: why?
  if(specificUnits[unit] and not aura_object) then
    tinsert(aura_lists, loaded_auras["group"]);
  end

  -- Locals
  local cloneIdList;
  local groupcloneToUpdate;

  -- Units GUID
  unit = fixedUnit;

  -- Iterate over all displays (list of display lists)
  for _, aura_list in pairs(aura_lists) do
    -- Locals
    local name, icon, count, duration, expirationTime, unitCaster, isStealable, spellId = true;
    local tooltip, debuffClass, tooltipSize;
    local remaining, checkPassed;

    -- Iterate over all displays (display lists)
    for id,triggers in pairs(aura_list) do
      WeakAuras.StartProfileAura(id);
      -- Iterate over all triggers
      local updateTriggerState = false;
      for triggernum, data in pairs(triggers) do
        if(not data.specificUnit or UnitIsUnit(data.unit, unit)) then
          -- Filters
          local filter = data.debuffType..(data.ownOnly and "|PLAYER" or "");
          local active = false;

          -- Full aura scan works differently
          if(data.fullscan) then
            -- Make sure scan cache exists
            aura_scan_cache[unit][filter] = aura_scan_cache[unit][filter] or {up_to_date = 0};

            -- Reset clone list
            if cloneIdList then wipe(cloneIdList); end
            if(data.autoclone and not cloneIdList) then
              cloneIdList = {};
            end

            -- Iterate over all units auras
            local index = 0; name = true;
            while(name) do
              -- Get nexted!
              index = index + 1;

              -- Update scan cache
              if(aura_scan_cache[unit][filter].up_to_date < index) then
                -- Query aura data
                name, icon, count, debuffClass, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, index, filter);
                if (debuffClass == nil) then
                  debuffClass = "none";
                elseif (debuffClass == "") then
                  debuffClass = "enrage"
                else
                  debuffClass = string.lower(debuffClass);
                end
                local tooltipSize1, tooltipSize2, tooltipSize3;
                tooltip, _, tooltipSize1, tooltipSize2, tooltipSize3 = WeakAuras.GetAuraTooltipInfo(unit, index, filter);
                tooltipSize = {tooltipSize1, tooltipSize2, tooltipSize3}
                aura_scan_cache[unit][filter][index] = aura_scan_cache[unit][filter][index] or {};

                -- Save aura data to cache
                local current_aura = aura_scan_cache[unit][filter][index];
                current_aura.name = name;
                current_aura.icon = icon;
                current_aura.count = count;
                current_aura.duration = duration;
                current_aura.expirationTime = expirationTime;
                current_aura.isStealable = isStealable;
                current_aura.spellId = spellId;
                current_aura.tooltip = tooltip;
                current_aura.debuffClass = debuffClass;
                current_aura.tooltipSize = tooltipSize;
                current_aura.unitCaster = unitCaster;

                -- Updated
                aura_scan_cache[unit][filter].up_to_date = index;

              -- Use cached data instead
              else
                -- Fetch cached aura data
                local current_aura = aura_scan_cache[unit][filter][index];
                name = current_aura.name;
                icon = current_aura.icon;
                count = current_aura.count;
                duration = current_aura.duration;
                expirationTime = current_aura.expirationTime;
                isStealable = current_aura.isStealable;
                spellId = current_aura.spellId;
                tooltip = current_aura.tooltip;
                debuffClass = current_aura.debuffClass;
                tooltipSize = current_aura.tooltipSize;
                if unitCaster ~= nil then
                  unitCaster = current_aura.unitCaster
                else
                  unitCaster = "Unknown"
                end
              end

              local casGUID = unitCaster and UnitGUID(unitCaster);

              -- Aura conforms to trigger options?
              if(data.subcount) then
                local index = data.subcountCount or 1;
                count = tooltipSize[index];
              end
              if(name and ((not data.count) or count and data.count(count)) and (data.ownOnly ~= false or not UnitIsUnit("player", unitCaster or "")) and data.scanFunc(name, tooltip, isStealable, spellId, debuffClass)) then
                remaining = expirationTime - time;
                checkPassed = true;
                if(data.remFunc) then
                  if not(data.remFunc(remaining)) then
                    checkPassed = false;
                  end

                  -- Schedule remaining time, re-scan later
                  if(remaining > data.rem) then
                    WeakAuras.ScheduleAuraScan(unit, time + (remaining - data.rem));
                  end
                end

                if checkPassed then
                  -- Show display and handle clones
                  WeakAuras.SetDynamicIconCache(name, spellId, icon);
                  if(data.autoclone) then
                    local cloneId = name .. spellId .."-"..(casGUID or "unknown");
                    if (WeakAuras.SetAuraVisibility(id, triggernum, cloneId, data.buffShowOn, data.unitExists, true, unit, duration, expirationTime, name, icon, count, index, spellId, unitCaster)) then
                      updateTriggerState = true;
                    end
                    active = true;
                    cloneIdList[cloneId] = true;
                  -- Simply show display (show)
                  else
                    if (WeakAuras.SetAuraVisibility(id, triggernum, nil, data.buffShowOn, data.unitExists, true, unit, duration, expirationTime, name, icon, count, index, spellId, unitCaster)) then
                      updateTriggerState = true;
                    end
                    active = true;
                    break;
                  end
                end
              end
            end

            -- Update display visibility and clones visibility (hide)
            if not(active) then
              local nameFromTrigger, iconFromTrigger;
              nameFromTrigger, iconFromTrigger = GetNameAndIconFromTrigger(data);
              if (WeakAuras.SetAuraVisibility(id, triggernum, nil, data.buffShowOn, data.unitExists, nil, unit, 0, math.huge, nameFromTrigger, iconFromTrigger)) then
                updateTriggerState = true;
              end
            end
            if(data.autoclone) then
              WeakAuras.SetAllStatesHiddenExcept(id, triggernum, cloneIdList);
              updateTriggerState = true;
            end

            -- Not using full aura scan
          else
            -- Reset clone list
            if groupcloneToUpdate then wipe(groupcloneToUpdate); end
            if(aura_object and data.groupclone and not data.specificUnit and not groupcloneToUpdate) then
              groupcloneToUpdate = {};
            end

            -- Check all selected auras (for one trigger)

            local bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestCasGUID, bestSpellId, bestUnitCaster;

            for index, checkname in pairs(data.names) do
              -- Fetch aura data
              local detected
              for i = 1, BUFF_MAX_DISPLAY do
                name, icon, count, _, duration, expirationTime, unitCaster, isStealable, _, spellId = UnitAura(unit, i, filter);
                if not name then break end
                if name == checkname then
                  detected = true
                  break
                end
              end

              if (detected) then
                WeakAuras.SetDynamicIconCache(name, spellId, icon);
              end
              checkPassed = false;

              -- Aura conforms to trigger options?
              if(name and ((not data.count) or data.count(count)) and (data.ownOnly ~= false or not UnitIsUnit("player", unitCaster or ""))) then
                remaining = expirationTime - time;
                checkPassed = true;
                if(data.remFunc) then
                  if not(data.remFunc(remaining)) then
                    checkPassed = false;
                  end

                  -- Schedule remaining time, re-scan later
                  if(remaining > data.rem) then
                    WeakAuras.ScheduleAuraScan(unit, time + (remaining - data.rem));
                  end
                end
              end

              local casGUID = unitCaster and UnitGUID(unitCaster);

              -- Aura conforms to trigger
              if(checkPassed) then
                active = true;

                if (not bestExpirationTime or expirationTime > bestExpirationTime) then
                  bestDuration = duration;
                  bestExpirationTime = expirationTime;
                  bestName = name;
                  bestIcon = icon;
                  bestCount = count;
                  bestCasGUID = casGUID;
                  bestSpellId = spellId;
                  bestUnitCaster = unitCaster;
                end
              end
            end

            local satisfies_role = true
            if data.group_role then
              satisfies_role = data.group_role == "ANY" or UnitGroupRolesAssigned(unit) == data.group_role
            end
            local satisfies_ignoreSelf = not data.ignoreSelf or not UnitIsUnit(unit, "player")
            if not satisfies_role or not satisfies_ignoreSelf then
              active = false
            end

            -- Update aura cache (and clones)
            if (active) then
              if(aura_object and not data.specificUnit) then
                aura_object:AssertAura(id, triggernum, uGUID, bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestCasGUID, bestSpellId, bestUnitCaster);
                if(data.groupclone) then
                  groupcloneToUpdate[uGUID] = GetUnitName(unit, true);
                end
              else
                if (WeakAuras.SetAuraVisibility(id, triggernum, nil, data.buffShowOn, data.unitExists, true, unit, bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, nil, bestSpellId, bestUnitCaster)) then
                  updateTriggerState = true;
                end
              end
            else
              if(aura_object and not data.specificUnit) then
                -- Update aura cache (and clones)
                aura_object:DeassertAura(id, triggernum, uGUID);
                if(data.groupclone) then
                  groupcloneToUpdate[uGUID] = GetUnitName(unit, true);
                end
              else
                local nameFromTrigger, iconFromTrigger;
                nameFromTrigger, iconFromTrigger = GetNameAndIconFromTrigger(data);
                if (WeakAuras.SetAuraVisibility(id, triggernum, nil, data.buffShowOn, data.unitExists, nil, unit, 0, math.huge, nameFromTrigger, iconFromTrigger)) then
                  updateTriggerState = true;
                end
              end
            end

            -- Processing a unit=group related unit
            if(aura_object and not data.specificUnit) then
              -- unit=group require valid count function
              if(data.group_count) then
                -- Query count from aura cache
                local aura_count = aura_object:GetNumber(id, triggernum, data)
                local max
                if (data.group_role) then
                  max = aura_cache[data.group_role]
                  if (data.ignoreSelf and aura_cache.playerRole == data.group_role) then
                    max = max - 1;
                  end
                else
                  max = aura_object:GetMaxNumber();
                  if (data.ignoreSelf) then
                    max = max - 1;
                  end
                end
                local satisfies_count = data.group_count(aura_count, max);

                if(data.hideAlone and not IsInGroup()) then
                  satisfies_count = false;
                end

                -- Satisfying count condition
                if(satisfies_count) then
                  -- Update clones (show)
                  if(data.groupclone) then
                    for guid, playerName in pairs(aura_cache.players) do
                      local duration, expirationTime, name, icon, count, spellId, unitCaster = aura_object:GetPlayerDynamicInfo(id, triggernum, guid, data);
                      if(name ~= "") then
                        if (WeakAuras.SetAuraVisibility(id, triggernum, playerName, data.buffShowOn, data.unitExists, true, unit, duration, expirationTime, playerName, icon, count, nil, spellId, unitCaster)) then
                          updateTriggerState = true;
                        end
                      else
                        if (WeakAuras.SetAuraVisibility(id, triggernum, playerName, data.buffShowOn, data.unitExists, nil, unit, duration, expirationTime, playerName, icon, count, nil, spellId, unitCaster)) then
                          updateTriggerState = true;
                        end
                      end
                    end

                    -- Update display information
                  else
                    -- Get display related information
                    local duration, expirationTime, name, icon, count, spellId, unitCaster = aura_object:GetDynamicInfo(id, triggernum, data);

                    -- Process affected players
                    if(data.name_info == "players") then
                      local affected = aura_object:GetAffected(id, triggernum, data);
                      local num = 0;
                      name = "";
                      for affected_name, _ in pairs(affected) do
                        local space = affected_name:find(" ");
                        name = name..(space and affected_name:sub(1, space - 1).."*" or affected_name)..", ";
                        num = num + 1;
                      end
                      if(num == 0) then
                        name = WeakAuras.L["None"];
                      else
                        name = name:sub(1, -3);
                      end
                      -- Process unaffected players
                    elseif(data.name_info == "nonplayers") then
                      local unaffected = aura_object:GetUnaffected(id, triggernum, data);
                      local num = 0;
                      name = "";
                      for unaffected_name, _ in pairs(unaffected) do
                        local space = unaffected_name:find(" ");
                        name = name..(space and unaffected_name:sub(1, space - 1).."*" or unaffected_name)..", ";
                        num = num + 1;
                      end
                      if(num == 0) then
                        name = WeakAuras.L["None"];
                      else
                        name = name:sub(1, -3);
                      end
                    end

                    -- Process stacks/aura count
                    if(data.stack_info == "count") then
                      count = aura_count;
                    end

                    -- Update display visibility (show)
                    if (WeakAuras.SetAuraVisibility(id, triggernum, nil, data.buffShowOn, data.unitExists, true, unit, duration, expirationTime, name, icon, count, nil, spellId, unitCaster)) then
                      updateTriggerState = true;
                    end
                  end

                  -- Not satisfying count
                else
                  -- Update clones
                  if(data.groupclone) then
                    WeakAuras.SetAllStatesHidden(id, triggernum);
                    updateTriggerState = true;
                  -- Update display visibility (hide)
                  else
                    local nameFromTrigger, iconFromTrigger;
                    nameFromTrigger, iconFromTrigger = GetNameAndIconFromTrigger(data);
                    if (WeakAuras.SetAuraVisibility(id, triggernum, nil, data.buffShowOn, data.unitExists, nil, unit, 0, math.huge, nameFromTrigger, iconFromTrigger)) then
                      updateTriggerState = true;
                    end
                  end
                end
              end
            end
          end
        end
      end
      if (updateTriggerState) then
        WeakAuras.UpdatedTriggerState(id);
      end
      WeakAuras.StopProfileAura(id);
    end
  end

  -- Update current unit once again
  WeakAuras.CurrentUnit = old_unit;
end

function WeakAuras.ScanAurasGroup()
  if IsInRaid() then
    for i=1, GetNumGroupMembers() do
      WeakAuras.ScanAuras(WeakAuras.raidUnits[i])
    end
  elseif IsInGroup() then
    for i=1, GetNumSubgroupMembers() do
      WeakAuras.ScanAuras(WeakAuras.partyUnits[i])
    end
    WeakAuras.ScanAuras("player")
  else
    WeakAuras.ScanAuras("player")
  end
end

local function GroupRosterUpdate(event)
  WeakAuras.StartProfileSystem("bufftrigger");
  aura_cache.TANK = 0;
  aura_cache.HEALER = 0;
  aura_cache.DAMAGER = 0;
  aura_cache.playerRole = "NONE";
  local recheck = false;
  local groupMembers,playerName,uid,guid, role = {};
  if IsInRaid() then
    for i=1, GetNumGroupMembers() do
      uid = WeakAuras.raidUnits[i];
      role = UnitGroupRolesAssigned(uid)
      if aura_cache[role] then
        aura_cache[role] = aura_cache[role] + 1;
      end
      playerName = GetUnitName(uid,true);
      playerName = playerName:gsub("-", " - ");
      if (playerName == UNKNOWNOBJECT) then
        recheck = true;
      end
      guid = UnitGUID(uid);
      if (guid) then
        groupMembers[guid] = playerName;
      end
    end
    role = UnitGroupRolesAssigned("player")
    aura_cache.playerRole = role;
  elseif IsInGroup() then
    for i=1, GetNumSubgroupMembers() do
      uid = WeakAuras.partyUnits[i];
      role = UnitGroupRolesAssigned(uid)
      if (aura_cache[role]) then
        aura_cache[role] = aura_cache[role] + 1;
      end
      guid = UnitGUID(uid);
      local playerName = GetUnitName(uid,true);
      if (playerName == UNKNOWNOBJECT) then
        recheck = true;
      end
      if (guid) then
        groupMembers[guid] = playerName;
      end
    end
    role = UnitGroupRolesAssigned("player")
    if (aura_cache[role]) then
      aura_cache[role] = aura_cache[role] + 1;
      aura_cache.playerRole = role;
    end
  end

  if (not WeakAuras.myGUID) then
    WeakAuras.myGUID = UnitGUID("player")
  end
  groupMembers[WeakAuras.myGUID] = WeakAuras.me;
  aura_cache:AssertMemberList(groupMembers);
  if (recheck) then
    timer:ScheduleTimer(GroupRosterUpdate, 0.5);
  end
  WeakAuras.StopProfileSystem("bufftrigger");
end

local groupFrame = CreateFrame("FRAME");
WeakAuras.frames["Group Makeup Handler"] = groupFrame;
groupFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
groupFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
groupFrame:SetScript("OnEvent", function(self, event)
  GroupRosterUpdate();
end);

do
  local pendingTracks = {};
  local UIDsfromGUID = {};
  local GUIDfromUID = {};

  function WeakAuras.ReleaseUID(UID)
    if(GUIDfromUID[UID]) then
      if(UIDsfromGUID[GUIDfromUID[UID]] and UIDsfromGUID[GUIDfromUID[UID]][UID]) then
        UIDsfromGUID[GUIDfromUID[UID]][UID] = nil;
      else
        -- If this code is reached, it means there was some kind of coordination error between the two lists
        -- This shouldn't ever happen, but it is recoverable
        -- Search through the whole UIDsfromGUID table and remove all instances of UID
        for GUID,UIDs in pairs(UIDsfromGUID) do
          for iUID,v in pairs(UIDs) do
            if(iUID == UID or iUID == UID) then
              UIDs[iUID] = nil;
            end
          end
        end
      end
    end
    GUIDfromUID[UID] = nil;
  end

  function WeakAuras.SetUID(GUID, UID)
    WeakAuras.ReleaseUID(UID);
    if not(UIDsfromGUID[GUID]) then
      UIDsfromGUID[GUID] = {};
    end
    UIDsfromGUID[GUID][UID] = true;
    GUIDfromUID[UID] = GUID;
  end

  function WeakAuras.GetUID(GUID)
    if not(UIDsfromGUID[GUID]) then
      return nil;
    end
    -- iterate through key/value pairs from the table of UIDs that are registered for this GUID, until a *confirmed* match is found
    -- confirming is necessary in case UIDs are not always released correctly (which may actually be close to impossible)
    for returnUID,v in pairs(UIDsfromGUID[GUID]) do
      -- check the validity of this entry
      if(UnitGUID(returnUID) == GUID) then
        return returnUID;
      else
        WeakAuras.ReleaseUID(returnUID);
      end
    end
    return nil;
  end

  --- Updates region data to see if states changed.
  -- @param id
  -- @param data
  -- @param triggernum
  -- @param GUID
  -- @return boolean
  local function updateRegion(id, data, triggernum, GUID)
    local auradata = data.GUIDs[GUID];
    local triggerState = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
    triggerState[GUID] = triggerState[GUID] or {};
    local state = triggerState[GUID];
    if (state.progressType ~= "timed") then
      state.progressType = "timed";
      state.changed = true;
    end

    if(auradata and auradata.unitName) then
      if (state.show ~= true) then
        state.show = true;
        state.changed = true;
      end

      if (state.expirationTime ~= auradata.expirationTime) then
        state.expirationTime = auradata.expirationTime;
        state.changed = true;
      end

      if (state.duration ~= auradata.duration) then
        state.duration = auradata.duration;
        state.changed = true;
      end

      if (state.autoHide ~= true) then
        state.autoHide = true;
        state.changed = true;
      end

      if (state.name ~= auradata.unitName) then
        state.name = auradata.unitName;
        state.changed = true;
      end

      local icon = auradata.icon or WeakAuras.GetDynamicIconCache(auradata.name) or "Interface\\Icons\\INV_Misc_QuestionMark";
      if (state.icon ~= icon) then
        state.icon = icon;
        state.changed = true;
      end

      if (state.stacks ~= auradata.count) then
        state.stacks = auradata.count;
        state.changed  = true;
      end

      if (state.unitCaster ~= auradata.unitCaster) then
        state.unitCaster = auradata.unitCaster;
        state.changed = true;
      end

      if (state.GUID ~= GUID) then
        state.GUID = GUID;
        state.changed = true;
      end
    else
      if (state.show ~= false) then
        state.show = false;
        state.changed = true;
      end
    end

    if (state.changed) then
      return true;
    end
    return false;
  end

  local function updateSpell(spellName, unit, destGUID)
    if (not loaded_auras[spellName]) then return end;
    for id, triggers in pairs(loaded_auras[spellName]) do
      WeakAuras.StartProfileAura(id);
      local updateTriggerState = false;
      for triggernum, data in pairs(triggers) do
        local filter = data.debuffType..(data.ownOnly and "|PLAYER" or "");
        local detected
        local name, icon, count, duration, expirationTime, unitCaster, spellId, _
        for i = 1, BUFF_MAX_DISPLAY do
          name, icon, count, _, duration, expirationTime, unitCaster, _, _, spellId = UnitAura(unit, i, filter);
          if not name then break end
          if name == spellName then
            detected = true
            break
          end
        end

        if(detected and (data.spellId == nil or data.spellId == spellId)) then
          data.GUIDs = data.GUIDs or {};
          data.GUIDs[destGUID] = data.GUIDs[destGUID] or {};
          data.GUIDs[destGUID].name = spellName;
          data.GUIDs[destGUID].unitName = GetUnitName(unit, true);
          data.GUIDs[destGUID].duration = duration;
          data.GUIDs[destGUID].expirationTime = expirationTime;
          data.GUIDs[destGUID].icon = icon;
          data.GUIDs[destGUID].count = count;
          data.GUIDs[destGUID].unitCaster = unitCaster and UnitName(unitCaster);
          data.GUIDs[destGUID].spellId = spellId;
          updateTriggerState = updateRegion(id, data, triggernum, destGUID) or updateTriggerState;
        end
      end
      if (updateTriggerState) then
        WeakAuras.UpdatedTriggerState(id);
      end
      WeakAuras.StopProfileAura(id);
    end
  end

  local function combatLog(_, message, _, _, sourceName, _, _, destGUID, destName, _, _, spellId, spellName, _, auraType, amount)
    if(loaded_auras[spellName]) then
      if(message == "SPELL_AURA_APPLIED" or message == "SPELL_AURA_REFRESH" or message == "SPELL_AURA_APPLIED_DOSE" or message == "SPELL_AURA_REMOVED_DOSE") then
        local unit = WeakAuras.GetUID(destGUID);
        if(unit) then
          updateSpell(spellName, unit, destGUID);
        else
          for id, triggers in pairs(loaded_auras[spellName]) do
            WeakAuras.StartProfileAura(id);
            local updateTriggerState = false;
            for triggernum, data in pairs(triggers) do
              if((not data.ownOnly) or UnitIsUnit(sourceName or "", "player")) then
                pendingTracks[destGUID] = pendingTracks[destGUID] or {};
                pendingTracks[destGUID][spellName] = true;

                data.GUIDs = data.GUIDs or {};
                data.GUIDs[destGUID] = data.GUIDs[destGUID] or {};
                data.GUIDs[destGUID].name = spellName;
                data.GUIDs[destGUID].unitName = destName;
                local icon = spellId and select(3, GetSpellInfo(spellId));
                if (message == "SPELL_AURA_APPLIED_DOSE" or message == "SPELL_AURA_REMOVED_DOSE") then
                  -- Shouldn't affect duration/expirationTime nor icon
                  data.GUIDs[destGUID].duration = data.GUIDs[destGUID].duration or 0;
                  data.GUIDs[destGUID].expirationTime = data.GUIDs[destGUID].expirationTime or math.huge;
                  data.GUIDs[destGUID].icon = data.GUIDs[destGUID].icon or icon;
                else
                  data.GUIDs[destGUID].duration = 0;
                  data.GUIDs[destGUID].expirationTime = math.huge;
                  data.GUIDs[destGUID].icon = icon;
                end
                data.GUIDs[destGUID].count = amount or 0;
                data.GUIDs[destGUID].spellId = spellId;
                data.GUIDs[destGUID].unitCaster = sourceName and UnitName(sourceName);

                updateTriggerState = updateRegion(id, data, triggernum, destGUID) or updateTriggerState;
              end
            end
            if (updateTriggerState) then
              WeakAuras.UpdatedTriggerState(id);
            end
            WeakAuras.StopProfileAura(id);
          end
        end
      elseif(message == "SPELL_AURA_REMOVED") then
        for id, triggers in pairs(loaded_auras[spellName]) do
          local updateTriggerState = false;
          for triggernum, data in pairs(triggers) do
            if((not data.ownOnly) or UnitIsUnit(sourceName or "", "player")) then
              -- WeakAuras.debug("Removed "..spellName.." from "..destGUID.." ("..(data.GUIDs and data.GUIDs[destGUID] and data.GUIDs[destGUID].unitName or "error")..") - "..(data.ownOnly and "own only" or "not own only")..", "..sourceName, 3);
              data.GUIDs = data.GUIDs or {};
              data.GUIDs[destGUID] = nil;

              updateTriggerState = updateRegion(id, data, triggernum, destGUID) or updateTriggerState;
            end
          end
          if (updateTriggerState) then
            WeakAuras.UpdatedTriggerState(id);
          end
        end
      end
    end
  end

  local function uidTrack(unit)
    local GUID = UnitGUID(unit);
    if(GUID) then
      WeakAuras.SetUID(GUID, unit);
      if(pendingTracks[GUID]) then
        for spellName,_ in pairs(pendingTracks[GUID]) do
          updateSpell(spellName, unit, GUID);
          pendingTracks[GUID][spellName] = nil;
        end
      end
    else
      WeakAuras.ReleaseUID(unit);
    end
    unit = unit.."target";
    GUID = UnitGUID(unit);
    if(GUID) then
      WeakAuras.SetUID(GUID, unit);
      if(pendingTracks[GUID]) then
        for spellName,_ in pairs(pendingTracks[GUID]) do
          updateSpell(spellName, unit, GUID);
          pendingTracks[GUID][spellName] = nil;
        end
      end
    else
      WeakAuras.ReleaseUID(unit);
    end
  end

  local function checkExists()
    WeakAuras.StartProfileSystem("bufftrigger - multi");
    for unit, auras in pairs(loaded_auras) do
      if not(WeakAuras.unit_types[unit]) then
        for id, triggers in pairs(auras) do
          WeakAuras.StartProfileAura(id);
          local updateTriggerState = false;
          for triggernum, data in pairs(triggers) do
            if(data.GUIDs) then
              for GUID, GUIDData in pairs(data.GUIDs) do
                if(GUIDData.expirationTime and GUIDData.expirationTime + 2 < GetTime()) then
                  data.GUIDs[GUID] = nil;
                  updateTriggerState = updateRegion(id, data, triggernum, GUID) or updateTriggerState;
                end
              end
            end
          end
          if (updateTriggerState) then
            WeakAuras.UpdatedTriggerState(id);
          end
          WeakAuras.StopProfileAura(id);
        end
      end
    end
    WeakAuras.StopProfileSystem("bufftrigger - multi");
  end

  local function handleEvent(frame, event, ...)
    WeakAuras.StartProfileSystem("bufftrigger - multi");
    if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
      combatLog(CombatLogGetCurrentEventInfo());
    elseif(event == "UNIT_TARGET") then
      uidTrack(...);
    elseif(event == "PLAYER_FOCUS_CHANGED") then
      uidTrack("focus");
    elseif(event == "NAME_PLATE_UNIT_ADDED") then
      uidTrack(...);
    elseif(event == "NAME_PLATE_UNIT_REMOVED") then
      local unit = ...
      WeakAuras.ReleaseUID(unit);
      unit = unit.."target";
      WeakAuras.ReleaseUID(unit);
    elseif(event == "UNIT_AURA") then
      -- Note: Using UNIT_AURA in addition to COMBAT_LOG_EVENT_UNFILTERED,
      -- because the combat log event does not contain duration information
      local uid = ...;
      local guid = UnitGUID(uid);

      for spellName, auras in pairs(loaded_auras) do
        if not(WeakAuras.unit_types[spellName]) then
          for id, triggers in pairs(auras) do
            WeakAuras.StartProfileAura(id);
            local updateTriggerState = false;
            for triggernum, data in pairs(triggers) do
              local filter = data.debuffType..(data.ownOnly and "|PLAYER" or "");

              local detected
              local name, icon, count, duration, expirationTime, unitCaster, _
              for i = 1, BUFF_MAX_DISPLAY do
                name, icon, count, _, duration, expirationTime, unitCaster = UnitAura(uid, i, filter);
                if not name then break end
                if name == spellName then
                  detected = true
                  break
                end
              end

              if(detected) then
                data.GUIDs = data.GUIDs or {};
                data.GUIDs[guid] = data.GUIDs[guid] or {};
                data.GUIDs[guid].name = spellName;
                data.GUIDs[guid].unitName = GetUnitName(uid, true);
                data.GUIDs[guid].duration = duration;
                data.GUIDs[guid].expirationTime = expirationTime;
                data.GUIDs[guid].icon = icon;
                data.GUIDs[guid].count = count;
                data.GUIDs[guid].unitCaster = unitCaster and UnitName(unitCaster);
                updateTriggerState = updateRegion(id, data, triggernum, guid) or updateTriggerState;
              end
            end
            if (updateTriggerState) then
              WeakAuras.UpdatedTriggerState(id);
            end
            WeakAuras.StopProfileAura(id);
          end
        end
      end
    end
    WeakAuras.StopProfileSystem("bufftrigger - multi");
  end

  local combatAuraFrame;
  function WeakAuras.InitMultiAura()
    if not(combatAuraFrame) then
      combatAuraFrame = CreateFrame("frame");
      combatAuraFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
      combatAuraFrame:RegisterEvent("UNIT_TARGET");
      combatAuraFrame:RegisterEvent("UNIT_AURA");
      if not WeakAuras.IsClassic() then
        combatAuraFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
      end
      combatAuraFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
      combatAuraFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
      combatAuraFrame:RegisterEvent("PLAYER_LEAVING_WORLD");
      combatAuraFrame:SetScript("OnEvent", handleEvent);
      WeakAuras.frames["Multi-target Aura Trigger Handler"] = combatAuraFrame;
      timer:ScheduleRepeatingTimer(checkExists, 10)
    end
  end
end

do
  local scheduled_scans = {};

  function WeakAuras.ScheduleAuraScan(unit, fireTime)
    scheduled_scans[unit] = scheduled_scans[unit] or {};
    if not(scheduled_scans[unit][fireTime]) then
      WeakAuras.debug("Scheduled aura scan for "..unit.." at "..fireTime);
      local doScan = function()
        WeakAuras.debug("Performing aura scan for "..unit.." at "..fireTime.." ("..GetTime()..")");
        scheduled_scans[unit][fireTime] = nil;
        WeakAuras.ScanAuras(unit);
      end
      scheduled_scans[unit][fireTime] = timer:ScheduleTimerFixed(doScan, fireTime - GetTime() + 0.1);
    end
  end
end

--- Adds auras to the loaded_auras table
-- @param id
-- @param triggernum
-- @param data
local function LoadAura(id, triggernum, data)
  local unit;
  if(data.specificUnit) then
    if(data.unit:lower():sub(1,4) == "boss") then
      specificBosses[data.unit] = true;
      unit = "boss";
    elseif(data.unit:lower():sub(1,5) == "arena") then
      unit = "arena";
    else
      specificUnits[data.unit] = true;
      unit = "group";
    end
  elseif(data.unit == "multi") then
    unit = data.name
  else
    unit = data.unit;
  end
  if(unit) then
    loaded_auras[unit] = loaded_auras[unit] or {};
    loaded_auras[unit][id] = loaded_auras[unit][id] or {};
    loaded_auras[unit][id][triggernum] = data;
  end
end

function BuffTrigger.ScanAll()
  local unitIdstoScan = {};
  local groupScan = false;
  for unit, auras in pairs(loaded_auras) do
    if(unit == "group") then
      groupScan = true;
    elseif(WeakAuras.unit_types[unit]) then
      unitIdstoScan[unit] = true;
    end
  end

  if (groupScan) then
    WeakAuras.ScanAurasGroup();
  end

  for unit, _ in pairs(unitIdstoScan) do
    WeakAuras.ScanAuras(unit);
  end
end

local aura_scan_cooldowns = {};
local checkingScanCooldowns;
local scanCooldownFrame = CreateFrame("frame");
WeakAuras.frames["Aura Scan Cooldown"] = scanCooldownFrame;

local checkScanCooldownsFunc = function()
  WeakAuras.StartProfileSystem("bufftrigger")
  for unit,_ in pairs(aura_scan_cooldowns) do
    aura_scan_cooldowns[unit] = nil;
    WeakAuras.ScanAuras(unit);
  end
  checkingScanCooldowns = nil;
  scanCooldownFrame:SetScript("OnUpdate", nil);
  WeakAuras.StopProfileSystem("bufftrigger")
end

local frame = CreateFrame("FRAME");
WeakAuras.frames["WeakAuras Buff Frame"] = frame;
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
if not WeakAuras.IsClassic() then
  frame:RegisterEvent("PLAYER_FOCUS_CHANGED");
end
frame:RegisterEvent("PLAYER_TARGET_CHANGED");
frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT");
frame:RegisterEvent("UNIT_AURA");
frame:RegisterUnitEvent("UNIT_PET", "player")
frame:SetScript("OnEvent", function (frame, event, arg1, arg2, ...)
  if (WeakAuras.IsPaused()) then return end;
  WeakAuras.StartProfileSystem("bufftrigger");
  if (event == "PLAYER_ENTERING_WORLD") then
    BuffTrigger.ScanAll();
  elseif(event == "PLAYER_TARGET_CHANGED") then
    WeakAuras.ScanAuras("target");
  elseif(event == "PLAYER_FOCUS_CHANGED") then
    WeakAuras.ScanAuras("focus");
  elseif(event == "UNIT_PET") then
    WeakAuras.ScanAuras("pet");
  elseif(event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT") then
    for unit,_ in pairs(specificBosses) do
      WeakAuras.ScanAuras(unit);
    end
  elseif(event == "UNIT_AURA") then
    if(
      loaded_auras[arg1]
      or (
      loaded_auras["group"]
      and (
      arg1:sub(1, 4) == "raid"
      or arg1:sub(1, 5) == "party"
      or arg1 == "player"
      )
      )
      or (
      loaded_auras["boss"]
      and arg1:sub(1,4) == "boss"
      )
      or (
      loaded_auras["arena"]
      and arg1:sub(1,5) == "arena"
      )
      ) then
      -- This throttles aura scans to only happen at most once per frame per unit
      if not(aura_scan_cooldowns[arg1]) then
        aura_scan_cooldowns[arg1] = true;
        if not(checkingScanCooldowns) then
          checkingScanCooldowns = true;
          scanCooldownFrame:SetScript("OnUpdate", checkScanCooldownsFunc);
        end
      end
    end
  end
  WeakAuras.StopProfileSystem("bufftrigger");
end);

function BuffTrigger.UnloadAll()
  wipe(loaded_auras);
end

function BuffTrigger.LoadDisplays(toLoad)
  for id in pairs(toLoad) do
    if(auras[id]) then
      for triggernum, data in pairs(auras[id]) do
        if(auras[id] and auras[id][triggernum]) then
          LoadAura(id, triggernum, data);
        end
      end
    end
  end
end

function BuffTrigger.UnloadDisplays(toUnload)
  for id in pairs(toUnload) do
    for unitname, auras in pairs(loaded_auras) do
      auras[id] = nil;
    end
  end
end

function BuffTrigger.FinishLoadUnload()
  BuffTrigger.ScanAll();
end

--- Removes all data for an aura id
-- @param id
function BuffTrigger.Delete(id)
  auras[id] = nil;
  for i,v in pairs(loaded_auras) do
    v[id] = nil;
  end
end

--- Updates all data for aura oldid to use newid
-- @param oldid
-- @param newid
function BuffTrigger.Rename(oldid, newid)
  auras[newid] = auras[oldid];
  auras[oldid] = nil;

  aura_cache:Rename(oldid, newid);

  for i,v in pairs(loaded_auras) do
    v[newid] = v[oldid];
    v[newid] = nil;
  end
end

--- Adds an aura, setting up internal data structures for all buff triggers.
-- @param data
function BuffTrigger.Add(data)
  local id = data.id;
  auras[id] = nil;

  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger
    local triggerType;
    if(type(trigger) == "table") then
      triggerType = trigger.type;
      if(triggerType == "aura") then
        trigger.names = trigger.names or {};
        trigger.spellIds = trigger.spellIds or {}
        trigger.unit = trigger.unit or "player";
        trigger.debuffType = trigger.debuffType or "HELPFUL";

        local countFunc, countFuncStr;
        if(trigger.useCount) then
          countFuncStr = function_strings.count:format(trigger.countOperator or ">=", tonumber(trigger.count) or 0);
          countFunc = WeakAuras.LoadFunction(countFuncStr);
        end

        local remFunc, remFuncStr;
        if(trigger.useRem) then
          remFuncStr = function_strings.count:format(trigger.remOperator or ">=", tonumber(trigger.rem) or 0);
          remFunc = WeakAuras.LoadFunction(remFuncStr);
        end

        local group_countFunc, group_countFuncStr;
        if(trigger.unit == "group") then
          local count, countType = WeakAuras.ParseNumber(trigger.group_count);
          if(trigger.group_countOperator and count and countType) then
            if(countType == "whole") then
              group_countFuncStr = function_strings.count:format(trigger.group_countOperator, count);
            else
              group_countFuncStr = function_strings.count_fraction:format(trigger.group_countOperator, count);
            end
          else
            group_countFuncStr = function_strings.count:format(">", 0);
          end
          group_countFunc = WeakAuras.LoadFunction(group_countFuncStr);
          WeakAuras.aura_cache:Watch(id, triggernum);
        end

        local scanFunc;
        if(trigger.fullscan) then
          scanFunc = function(name, tooltip, isStealable, spellId, debuffClass)
            if (
              (
              (not trigger.use_name) or (
              trigger.name and trigger.name ~= "" and (
              trigger.name_operator == "==" and name == trigger.name
              or trigger.name_operator == "find('%s')" and name:find(trigger.name)
              or trigger.name_operator == "match('%s')" and name:match(trigger.name)
              )
              )
              )
              and (
              (not trigger.use_tooltip) or (
              trigger.tooltip and trigger.tooltip ~= "" and (
              trigger.tooltip_operator == "==" and tooltip == trigger.tooltip
              or trigger.tooltip_operator == "find('%s')" and tooltip:find(trigger.tooltip)
              or trigger.tooltip_operator == "match('%s')" and tooltip:match(trigger.tooltip)
              )
              )
              )
              and ((not trigger.use_stealable) or isStealable)
              and ((not trigger.use_spellId) or spellId == tonumber(trigger.spellId))
              and ((not trigger.use_debuffClass) or debuffClass == trigger.debuffClass)
              ) then
              return true;
            else
              return false;
            end
          end -- end scanFunc
        end

        if(trigger.unit == "multi") then
          WeakAuras.InitMultiAura();
        end

        if (trigger.buffShowOn == nil) then
          trigger.buffShowOn = "showOnActive";
        end

        local buffShowOn = "showOnActive";
        local unitExists = true;

        if (not(trigger.unit ~= "group" and trigger.autoclone) and trigger.unit ~= "multi" and trigger.unit ~= "group" and trigger.unit ~= "player") then
          unitExists = trigger.unitExists;
        end

        if (trigger.type == "aura" and not(trigger.unit ~= "group" and trigger.autoclone)
          and trigger.unit ~= "multi" and not(trigger.unit == "group" and not trigger.groupclone)) then
          buffShowOn = trigger.buffShowOn;
        end

        auras[id] = auras[id] or {};
        auras[id][triggernum] = {
          count = countFunc,
          remFunc = remFunc,
          rem = tonumber(trigger.rem) or 0,
          group_count = group_countFunc,
          fullscan = trigger.fullscan,
          autoclone = trigger.autoclone,
          groupclone = trigger.groupclone,
          subcount = trigger.subcount,
          subcountCount = trigger.subcountCount,
          scanFunc = scanFunc,
          debuffType = trigger.debuffType,
          names = trigger.names,
          spellIds = trigger.spellIds,
          name = trigger.name,
          spellId = trigger.spellId,
          unit = trigger.unit == "member" and trigger.specificUnit or trigger.unit,
          specificUnit = trigger.unit == "member",
          useCount = trigger.useCount,
          ownOnly = trigger.ownOnly,
          buffShowOn = buffShowOn,
          unitExists = unitExists,
          numAdditionalTriggers = max(#data.triggers - 1, 0),
          hideAlone = trigger.hideAlone,
          stack_info = trigger.stack_info,
          name_info = trigger.name_info,
          group_role =  trigger.useGroupRole and trigger.group_role,
          ignoreSelf = trigger.ignoreSelf
        };
      end
    end
  end
end

--- Updates old data to the new format.
-- @param data
function BuffTrigger.Modernize(data)
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger = triggerData.trigger;

    if (data.internalVersion < 2) then
      if (trigger and trigger.type == "aura") then
        if (trigger.showOn == nil or trigger.showOn == "showOnCooldown" or trigger.showOn == "showOnReady" or trigger.showOn == "showAlways") then
          trigger.showOn = trigger.inverse and "showOnMissing" or "showOnActive";
          trigger.inverse = nil;
        end
      end
    end

    if data.internalVersion < 6 then
      if trigger and trigger.type == "aura" then
        if trigger.showOn == "showOnMissing" then
          trigger.buffShowOn = "showOnMissing"
        elseif trigger.showOn == "showActiveOrMissing" then
          trigger.buffShowOn = "showAlways"
        else
          trigger.buffShowOn = "showOnActive"
        end
        trigger.showOn = nil
      end
    end
  end
end

--- Returns whether the first trigger could be shown without any affected group members.
-- @param data
-- @param triggernum
-- @return boolean
local function CanGroupShowWithZero(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  local group_countFunc, group_countFuncStr;
  if(trigger.unit == "group") then
    local count, countType = WeakAuras.ParseNumber(trigger.group_count);
    if(trigger.group_countOperator and count and countType) then
      if(countType == "whole") then
        group_countFuncStr = function_strings.count:format(trigger.group_countOperator, count);
      else
        group_countFuncStr = function_strings.count_fraction:format(trigger.group_countOperator, count);
      end
    else
      group_countFuncStr = function_strings.count:format(">", 0);
    end
    group_countFunc = WeakAuras.LoadFunction(group_countFuncStr);
    return group_countFunc(0, 1);
  else
    return false;
  end
end

--- Returns whether the trigger can have a duration.
-- @param data
-- @param triggernum
function BuffTrigger.CanHaveDuration(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  if (trigger.type == "aura" and not(trigger.unit ~= "group" and trigger.autoclone) and trigger.unit ~= "multi" and not(trigger.unit == "group" and not trigger.groupclone)) then
    if (trigger.buffShowOn ~= "showOnMissing") then
      return "timed";
    else
      return false;
    end
  end
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
  local trigger = data.triggers[triggernum].trigger
  return (trigger.fullscan and trigger.autoclone)
    or (trigger.unit == "group" and trigger.groupclone)
    or (trigger.unit == "multi");
end

---Returns the type of tooltip to show for the trigger.
-- @param data
-- @param triggernum
-- @return string
function BuffTrigger.CanHaveTooltip(data, triggernum)
  local trigger = data.triggers[triggernum].trigger
  if(trigger.unit == "group" and trigger.name_info ~= "aura" and not trigger.groupclone) then
    return "playerlist";
  elseif(trigger.fullscan and trigger.unit ~= "group") then
    return "auraindex";
  else
    return "aura";
  end
end

function BuffTrigger.SetToolTip(trigger, state)
  local data = auras[state.id][state.triggernum];
  if(trigger.unit == "group" and trigger.name_info ~= "aura" and not trigger.groupclone) then
    local name = "";
    local playerList;
    if(trigger.name_info == "players") then
      playerList = WeakAuras.aura_cache:GetAffected(state.id, state.triggernum, data);
      name = L["Affected"]..":";
    elseif(trigger.name_info == "nonplayers") then
      playerList = WeakAuras.aura_cache:GetUnaffected(state.id, state.triggernum, data);
      name = L["Missing"]..":";
    else
      playerList = {};
    end

    local numPlayers = 0;
    for playerName, _ in pairs(playerList) do
      numPlayers = numPlayers + 1;
    end

    if(numPlayers > 0) then
      GameTooltip:AddLine(name);
      local numRaid = IsInRaid() and GetNumGroupMembers() or 0;
      local groupMembers,playersString = {};

      if(numRaid > 0) then
        local playerName, _, subgroup
        for i = 1,numRaid do
          -- Battleground-name, given by GetRaidRosterInfo (name-server) to GetUnitName(...) (name - server) transition
          playerName, _, subgroup = GetRaidRosterInfo(i);

          if(playerName) then
            playerName = playerName:gsub("-", " - ")
            if (playerList[playerName]) then
              groupMembers[subgroup] = groupMembers[subgroup] or {};
              groupMembers[subgroup][playerName] = true
            end
          end
        end
        for subgroup, players in pairs(groupMembers) do
          playersString = L["Group %s"]:format(subgroup)..": ";
          local _,space,class,classColor;
          for playerName, _ in pairs(players) do
            space = playerName:find(" ");
            _, class = UnitClass((space and playerName:sub(1, space - 1) or playerName));
            classColor = WeakAuras.class_color_types[class];
            playersString = playersString..(classColor or "")..(space and playerName:sub(1, space - 1).."*" or playerName)..(classColor and "|r" or "")..(next(players, playerName) and ", " or "");
          end
          GameTooltip:AddLine(playersString);
        end
      else
        local num = 0;
        playersString = "";
        local _,space,class,classColor;
        for playerName, _ in pairs(playerList) do
          space = playerName:find(" ");
          _, class = UnitClass((space and playerName:sub(1, space - 1) or playerName));
          classColor = WeakAuras.class_color_types[class];
          playersString = playersString..(classColor or "")..(space and playerName:sub(1, space - 1).."*" or playerName)..(classColor and "|r" or "")..(next(playerList, playerName) and (", "..(num % 5 == 4 and "\n" or "")) or "");
          num = num + 1;
        end
        GameTooltip:AddLine(playersString);
      end
    else
      GameTooltip:AddLine(name.." "..L["None"]);
    end
    return true
  elseif(trigger.fullscan and trigger.unit ~= "group" and state.index) then
    local unit = trigger.unit == "member" and trigger.specificUnit or trigger.unit;
    if(trigger.debuffType == "HELPFUL") then
      GameTooltip:SetUnitBuff(unit, state.index);
    elseif(trigger.debuffType == "HARMFUL") then
      GameTooltip:SetUnitDebuff(unit, state.index);
    end
    return true
  else
    if (state.spellId) then
      GameTooltip:SetSpellByID(state.spellId);
      return true
    end
  end
  return false
end

--- Returns the name and icon to show in the options.
-- @param data
-- @param triggernum
-- @return name and icon
function BuffTrigger.GetNameAndIcon(data, triggernum)
  local _, name, icon
  local trigger = data.triggers[triggernum].trigger
  if (trigger.fullscan) then
    if (trigger.spellId) then
      name, _, icon = GetSpellInfo(trigger.spellId);
    else
      name = trigger.name;
      icon = WeakAuras.spellCache.GetIcon(trigger.name);
    end
  else
    if (trigger.spellIds and trigger.spellIds[1]) then
      name, _, icon = GetSpellInfo(trigger.spellIds[1])
    elseif(not (trigger.buffShowOn == "showOnMissing" or CanGroupShowWithZero(data, triggernum)) and trigger.names) then
      -- Try to get an icon from the icon cache
      for index, checkname in pairs(trigger.names) do
        local iconFromSpellCache = WeakAuras.spellCache.GetIcon(checkname);
        if(iconFromSpellCache) then
          name, icon = checkname, iconFromSpellCache;
          break;
        end
      end
    end
  end

  return name, icon;
end

--- Returns the tooltip text for additional properties.
-- @param data
-- @param triggernum
-- @return string of additional properties
function BuffTrigger.GetAdditionalProperties(data, triggernum)
  local ret =  "|cFFFF0000%".. triggernum .. ".spellId|r -" .. L["Spell ID"] .. "\n";
  ret = ret .. "|cFFFF0000%".. triggernum .. ".unitCaster|r -" .. L["Caster"] .. "\n";

  return ret;
end

function BuffTrigger.GetTriggerConditions(data, triggernum)
  local result = {};
  local trigger = data.triggers[triggernum].trigger

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

  if (trigger.type == "aura" and not(trigger.unit ~= "group" and trigger.fullscan and trigger.autoclone) and trigger.unit ~= "multi" and not(trigger.unit == "group" and not trigger.groupclone)) then
    if (trigger.buffShowOn == "showAlways") then
      result["buffed"] = {
        display = L["Buffed/Debuffed"],
        type = "bool",
        test = function(state, needle)
          return state and state.show and ((state.active and true or false) == (needle == 1));
        end
      }
    end
  end

  return result;
end

function BuffTrigger.CreateFallbackState(data, triggernum, state)
  state.show = true;
  state.changed = true;
  state.progressType = "timed";
  state.duration = 0;
  state.expirationTime = math.huge;
  local name, icon = GetNameAndIconFromTrigger(data, triggernum)
  state.name = name
  state.icon = icon
end

function BuffTrigger.GetName(triggerType)
  if (triggerType == "aura") then
    return L["Legacy Aura"];
  end
end

function BuffTrigger.GetTriggerDescription(data, triggernum, namestable)
  local trigger = data.triggers[triggernum].trigger;
  if(trigger.fullscan) then
    tinsert(namestable, {L["Aura:"], L["Full Scan"]});
  else
    for index, name in pairs(trigger.names) do
      local left = " ";
      if(index == 1) then
        if(#trigger.names > 0) then
          if(#trigger.names > 1) then
            left = L["Auras:"];
          else
            left = L["Aura:"];
          end
        end
      end
      local icon = WeakAuras.spellCache.GetIcon(name) or "Interface\\Icons\\INV_Misc_QuestionMark";
      tinsert(namestable, {left, name, icon});
    end
  end
end

function BuffTrigger.CreateFakeStates(id, triggernum)
  local allStates = WeakAuras.GetTriggerStateForTrigger(id, triggernum);
  local data = WeakAuras.GetData(id)
  local state = {}
  BuffTrigger.CreateFallbackState(data, triggernum, state)
  state.expirationTime = GetTime() + 60
  state.duration = 65
  state.progressType = "timed"
  allStates[""] = state
  if BuffTrigger.CanHaveClones(data, triggernum) then
    for i = 1, 2 do
      local state = {}
      BuffTrigger.CreateFallbackState(data, triggernum, state)
      state.expirationTime = GetTime() + 60 + i * 20
      state.duration = 100
      state.progressType = "timed"
      allStates[i] = state
    end
  end
end

WeakAuras.RegisterTriggerSystem({"aura"}, BuffTrigger);
