--[[ BuffTrigger.lua
This file contains the "aura" trigger for buffs and debuffs.

It registters the BuffTrigger table for the trigger type "aura".
It has the following API:

LoadDisplay(id)
  Loads the aura id, enabling all buff triggers in the aura

Modernize(data)
  Updates all buff triggers in data

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
]]
-- Lua APIs
local tinsert, tconcat, tremove, wipe = table.insert, table.concat, table.remove, wipe
local tostring, select, pairs, next, type, unpack = tostring, select, pairs, next, type, unpack
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable = setmetatable, getmetatable

local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local BuffTrigger = {};

local timer = WeakAuras.timer;
local function_strings = WeakAuras.function_strings;
local auras = WeakAuras.auras;
local specificBosses = WeakAuras.specificBosses;
local specificUnits = WeakAuras.specificUnits;
local loaded_auras = WeakAuras.loaded_auras;
local duration_cache = WeakAuras.duration_cache;

local aura_cache = {};
do
  aura_cache.max = 0;
  aura_cache.watched = {};
  aura_cache.players = {};

  -- Test if aura_cache data is consistent with trigger settings, eg. OwnOnly, RemainingTime, StackCount, ect.
  -- Extra check needed, because aura_cache can potentially contain data of two different triggers with different settings!
  local function TestNonUniformSettings(acEntry, data)
    if(data.remFunc) then
      if not(data.remFunc(acEntry.expirationTime - GetTime())) then
        return false
      end
    end

    -- Test OwnOnly
    if (
      data.ownOnly == true  and WeakAuras.myGUID ~= acEntry.unitCaster or
      data.ownOnly == false and WeakAuras.myGUID == acEntry.unitCaster
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

  function aura_cache.Reloading()
    aura_cache.reloading = true;
  end

  function aura_cache:DoneReloading()
    aura_cache.reloading = nil;
  end

  function aura_cache.ForceUpdate()
    if not(WeakAuras.IsPaused()) then
      WeakAuras.ScanAurasGroup()
    end
  end

  function aura_cache.Watch(self, id)
    self.watched[id] = self.watched[id] or {};
    self.watched[id].players = self.watched[id].players or {};
    self.watched[id].recentChanges = self.watched[id].recentChanges or {};
    self:ForceUpdate()
  end

  function aura_cache.Unwatch(self, id)
    self.watched[id] = nil;
  end

  function aura_cache.GetMaxNumber(self)
    return self.max;
  end

  function aura_cache.GetNumber(self, id, data)
    local num = 0;
    local active;
    for guid, _ in pairs(self.players) do
      -- Need to check if cached  data conforms to trigger
      if(self.watched[id].players[guid] and TestNonUniformSettings(self.watched[id].players[guid], data)) then
        num = num + 1;
      end
    end
    return num;
  end

  function aura_cache.GetDynamicInfo(self, id, data)
    local bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestSpellId = 0, math.huge, "", "", 0, 0;
    if(self.watched[id]) then
      for guid, durationInfo in pairs(self.watched[id].players) do
        -- Need to check if cached  data conforms to trigger
        if(durationInfo.expirationTime < bestExpirationTime and TestNonUniformSettings(durationInfo, data)) then
          bestDuration = durationInfo.duration;
          bestExpirationTime = durationInfo.expirationTime;
          bestName = durationInfo.name;
          bestIcon = durationInfo.icon;
          bestCount = durationInfo.count;
          bestSpellId = durationInfo.spellId;
        end
      end
    end
    return bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestSpellId;
  end

  function aura_cache.GetPlayerDynamicInfo(self, id, guid, data)
    local bestDuration, bestExpirationTime, bestName, bestIcon, bestCount, bestSpellId = 0, math.huge, "", "", 0, 0;
    if(self.watched[id]) then
      local durationInfo = self.watched[id].players[guid]
      if(durationInfo) then
        -- Need to check if cached  data conforms to trigger
        if(durationInfo.expirationTime < bestExpirationTime and TestNonUniformSettings(durationInfo, data)) then
          bestDuration = durationInfo.duration;
          bestExpirationTime = durationInfo.expirationTime;
          bestName = durationInfo.name;
          bestIcon = durationInfo.icon;
          bestCount = durationInfo.count;
          bestSpellId = durationInfo.spellId;
        end
      end
    end
    return bestDuration, bestExpirationTime, bestName, bestIcon, bestCount;
  end

  function aura_cache.GetAffected(self, id, data)
    local affected = {};
    if(self.watched[id]) then
      for guid, acEntry in pairs(self.watched[id].players) do
        -- Need to check if cached  data conforms to trigger
        if (TestNonUniformSettings(acEntry, data)) then
          if (self.players[guid] == UNKNOWNOBJECT) then
            self.players[guid] = GetUnitName(guid, true);
          end
          affected[self.players[guid]] = true;
        end
      end
    end
    return affected;
  end

  function aura_cache.GetUnaffected(self, id, data)
    local affected = self:GetAffected(id, data);
    local ret = {};
    for guid, name in pairs(self.players) do
      if not(affected[name]) then
        ret[name] = true;
      end
    end
    return ret;
  end

  function aura_cache.AssertAura(self, id, guid, duration, expirationTime, name, icon, count, unitCaster, spellId)
    -- Don't watch aura on non watching players
    if not self.players[guid] then return end

    if not(self.watched[id].players[guid]) then
      self.watched[id].players[guid] = {
        duration = duration,
        expirationTime = expirationTime,
        name = name,
        icon = icon,
        count = count,
        unitCaster = unitCaster,
        spellId = spellId
      };
      self.watched[id].recentChanges[guid] = true;
      return true;
    else
      local auradata = self.watched[id].players[guid];
      if(expirationTime ~= auradata.expirationTime) then
        auradata.duration = duration;
        auradata.expirationTime = expirationTime;
        auradata.name = name;
        auradata.icon = icon;
        auradata.count = count;
        auradata.unitCaster = unitCaster;
        auradata.spellId = spellId;
        self.watched[id].recentChanges[guid] = true;
        return true;
      else
        return self.reloading or self.watched[id].recentChanges[guid];
      end
    end
  end

  function aura_cache.DeassertAura(self, id, guid)
    if(self.watched[id] and self.watched[id].players[guid]) then
      self.watched[id].players[guid] = nil;
      self.watched[id].recentChanges[guid] = true;
      return true;
    else
      return self.reloading and self.watched[id].recentChanges[guid];
    end
  end

  function aura_cache.ClearRecentChanges(self)
    for id, t in pairs(self.watched) do
      wipe(t.recentChanges);
    end
  end

  function aura_cache.AssertMember(self, guid, name, forceupdate)
    if not(self.players[guid]) then
      self.players[guid] = name;
      self.max = self.max + 1;
    end

    if(forceupdate) then
      self:ForceUpdate();
    end
  end

  function aura_cache.DeassertMember(self, guid)
    if(self.players[guid]) then
      self.players[guid] = nil;
      for id, _ in pairs(self.watched) do
        self:DeassertAura(id, guid);
      end
      self.max = self.max - 1;
    end
  end

  function aura_cache.AssertMemberList(self, guids)
    local toAdd = {};
    local toDelete = {};
    for guid, name in pairs(guids) do
      if not(self.players[guid]) then
        toAdd[guid] = name;
      end
    end
    for guid, _ in pairs(self.players) do
      if not(guids[guid]) then
        toDelete[guid] = true;
      end
    end

    for guid, _ in pairs(toDelete) do
      self:DeassertMember(guid);
    end
    for guid, name in pairs(toAdd) do
      self:AssertMember(guid, name);
    end
    self:ForceUpdate();
  end
end
WeakAuras.aura_cache = aura_cache;

function WeakAuras.SetAuraVisibility(id, triggernum, data, active, unit, duration, expirationTime, name, icon, count, cloneId, index, spellId)
  local region;
  local showClones;

  if(cloneId) then
    if(data.numAdditionalTriggers > 0) then
      showClones = data.region:IsVisible() and true or false;
    else
      showClones = true;
    end
    region = WeakAuras.EnsureClone(id, cloneId);
  else
    region = data.region;
  end

  region.index = index;
  region.spellId = spellId;

  local show;
  if(active ~= nil) then
    if not(data.inverse and UnitExists(unit)) then
      show = true;
    end
  elseif(data.inverse and UnitExists(unit)) then
    show = true;
  end

  if(show) then
    if(triggernum == 0) then
      if(region.SetDurationInfo) then
        region:SetDurationInfo(duration, expirationTime > 0 and expirationTime or math.huge);
      end

      WeakAuras.ControlChildren(id);

      duration_cache:SetDurationInfo(id, duration, expirationTime, nil, nil, cloneId);
      if(region.SetName) then
        region:SetName(name);
      end
      if(region.SetIcon) then
        region:SetIcon(icon or "Interface\\Icons\\INV_Misc_QuestionMark");
      end
      if(region.SetStacks) then
        region:SetStacks(count);
      end
      if(region.UpdateCustomText and not WeakAuras.IsRegisteredForCustomTextUpdates(region)) then
        region.UpdateCustomText();
      end
      WeakAuras.UpdateMouseoverTooltip(region);
    end

    if(data.numAdditionalTriggers > 0 and showClones == nil) then
      region:EnableTrigger(triggernum);
    elseif(showClones ~= false) then
      region:Expand();
    end
  else
    if(data.numAdditionalTriggers > 0 and showClones == nil) then
      region:DisableTrigger(triggernum)
    elseif(showClones ~= false) then
      region:Collapse();
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
  if(unit:sub(0, 4) == "raid") then
    if(aura_cache.players[uGUID]) then
      aura_lists[1] = loaded_auras["group"];
      aura_object = aura_cache;
    end
  elseif(unit:sub(0, 5) == "party") then
    aura_lists[1] = loaded_auras["group"];
    aura_object = aura_cache;
  elseif(specificBosses[unit]) then
    aura_lists[1] = loaded_auras["boss"];
  else
    if(unit == "player" and loaded_auras["group"]) then
      WeakAuras.ScanAuras("party0");
    end
    aura_lists[1] = loaded_auras[unit];
  end

  -- Add group auras for specific units (?why?)
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
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = true;
    local tooltip, debuffClass, tooltipSize;
    local remaining, checkPassed;

    -- Iterate over all displays (display lists)
    for id,triggers in pairs(aura_list) do
      -- Iterate over all triggers
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
                name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(unit, index, filter);
--              unitCaster = unitCaster or "unknown";
                tooltip, debuffClass, tooltipSize = WeakAuras.GetAuraTooltipInfo(unit, index, filter);
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

                -- Use cache data instead
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
                count = tooltipSize;
              end
              if(name and ((not data.count) or data.count(count)) and (data.ownOnly ~= false or not UnitIsUnit("player", unitCaster or "")) and data.scanFunc(name, tooltip, isStealable, spellId, debuffClass)) then
                -- Show display and handle clones
                WeakAuras.SetTempIconCache(name, icon);
                if(data.autoclone) then
                  local cloneId = name.."-"..(casGUID or "unknown");
                  if(not clones[id][cloneId] or clones[id][cloneId].expirationTime ~= expirationTime) then
                    WeakAuras.SetAuraVisibility(id, triggernum, data, true, unit, duration, expirationTime, name, icon, count, cloneId, index, spellId);
                    clones[id][cloneId].expirationTime = expirationTime;
                  end
                  active = true;
                  cloneIdList[cloneId] = true;
                  -- Simply show display (show)
                else
                  WeakAuras.SetAuraVisibility(id, triggernum, data, true, unit, duration, expirationTime, name, icon, count, nil, index, spellId);
                  active = true;
                  break;
                end
              end
            end

            -- Update display visibility and clones visibility (hide)
            if not(active) then
              WeakAuras.SetAuraVisibility(id, triggernum, data, nil, unit, 0, math.huge);
            end
            if(data.autoclone) then
              WeakAuras.HideAllClonesExcept(id, cloneIdList);
            end

          -- Not using full aura scan
          else
            -- Reset clone list
            if groupcloneToUpdate then wipe(groupcloneToUpdate); end
            if(aura_object and data.groupclone and not data.specificUnit and not groupcloneToUpdate) then
              groupcloneToUpdate = {};
            end

            -- Check all selected auras (for one trigger)
            for index, checkname in pairs(data.names) do
              -- Fetch aura data
              name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(unit, checkname, nil, filter);
              if (data.spellIds[index] and data.spellIds[index] ~= spellId) then
                name = nil
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

                  -- Schedule remaining time re-scan later
                  if(remaining > data.rem) then
                    WeakAuras.ScheduleAuraScan(unit, time + (remaining - data.rem));
                  end
                end
              end

              local casGUID = unitCaster and UnitGUID(unitCaster);

              -- Aura conforms to trigger
              if(checkPassed) then
                active = true;
                WeakAuras.SetTempIconCache(name, icon);

                -- Update aura cache (and clones)
                if(aura_object and not data.specificUnit) then
                  local changed = aura_object:AssertAura(id, uGUID, duration, expirationTime, name, icon, count, casGUID, spellId);
                  if(data.groupclone and changed) then
                    groupcloneToUpdate[uGUID] = GetUnitName(unit, true);
                  end
                -- Simply update visibility (show)
                else
                  WeakAuras.SetAuraVisibility(id, triggernum, data, true, unit, duration, expirationTime, name, icon, count, nil, nil, spellId);
                  break;
                end

              -- Aura does not conforms to trigger
              elseif(aura_object and not data.specificUnit) then
                -- Update aura cache (and clones)
                local changed = aura_object:DeassertAura(id, uGUID);
                if(data.groupclone and changed) then
                  groupcloneToUpdate[uGUID] = GetUnitName(unit, true);
                end
              end
            end

            -- Proccecing a unit=group related unit
            if(aura_object and not data.specificUnit) then
              -- unit=group require valid count function
              if(data.group_count) then
                -- Query count from aura cache
                local aura_count, max = aura_object:GetNumber(id, data), aura_object:GetMaxNumber();
                local satisfies_count = data.group_count(aura_count, max);

                if(data.hideAlone and not IsInGroup()) then
                  satisfies_count = false;
                end

                -- Satisfying count condition
                if(satisfies_count) then
                  -- Update clones (show)
                  if(data.groupclone) then
                    for guid, playerName in pairs(groupcloneToUpdate) do
                      local duration, expirationTime, name, icon, count, spellId = aura_object:GetPlayerDynamicInfo(id, guid, data);
                      if(name ~= "") then
                        WeakAuras.SetAuraVisibility(id, triggernum, data, true, unit, duration, expirationTime, playerName, icon, count, playerName, nil, spellId);
                      else
                        WeakAuras.SetAuraVisibility(id, triggernum, data, nil, unit, duration, expirationTime, playerName, icon, count, playerName, nil, spellId);
                      end
                    end

                    -- Update display information
                  else
                    -- Get display related information
                    local duration, expirationTime, name, icon, count, spellId = aura_object:GetDynamicInfo(id, data);

                    -- Process affected players
                    if(data.name_info == "players") then
                      local affected = aura_object:GetAffected(id, data);
                      local num = 0;
                      name = "";
                      for affected_name, _ in pairs(affected) do
                        local space = affected_name:find(" ");
                        name = name..(space and affected_name:sub(0, space - 1).."*" or affected_name)..", ";
                        num = num + 1;
                      end
                      if(num == 0) then
                        name = WeakAuras.L["None"];
                      else
                        name = name:sub(0, -3);
                      end
                    -- Process unaffected players
                    elseif(data.name_info == "nonplayers") then
                      local unaffected = aura_object:GetUnaffected(id, data);
                      local num = 0;
                      name = "";
                      for unaffected_name, _ in pairs(unaffected) do
                        local space = unaffected_name:find(" ");
                        name = name..(space and unaffected_name:sub(0, space - 1).."*" or unaffected_name)..", ";
                        num = num + 1;
                      end
                      if(num == 0) then
                        name = WeakAuras.L["None"];
                      else
                        name = name:sub(0, -3);
                      end
                    end

                    -- Process stacks/aura count
                    if(data.stack_info == "count") then
                      count = aura_count;
                    end

                    -- Update display visibility (show)
                    WeakAuras.SetAuraVisibility(id, triggernum, data, true, unit, duration, expirationTime, name, icon, count, nil, nil, spellId);
                  end

                -- Not satisfying count
                else
                  -- Update clones
                  if(data.groupclone) then
                    WeakAuras.HideAllClones(id);
                    -- Update display visibility (hide)
                  else
                    WeakAuras.SetAuraVisibility(id, triggernum, data, nil, unit, 0, math.huge);
                  end
                end
              end

            -- Update display visibility (hide)
            elseif not(active) then
              WeakAuras.SetAuraVisibility(id, triggernum, data, nil, unit, 0, math.huge);
            end
          end
        end
      end
    end
  end

  -- Reset aura cache notes
  aura_cache:ClearRecentChanges();

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
  end
end

local groupFrame = CreateFrame("FRAME");
WeakAuras.frames["Group Makeup Handler"] = groupFrame;
groupFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
groupFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
groupFrame:SetScript("OnEvent", function(self, event)

  local groupMembers,playerName,uid,guid = {};
  if IsInRaid() then
    for i=1, GetNumGroupMembers() do
      uid = WeakAuras.raidUnits[i];
      playerName = GetUnitName(uid,true);
      playerName = playerName:gsub("-", " - ");
      guid = UnitGUID(uid);
      if (guid) then
        groupMembers[guid] = playerName;
      end
    end
  elseif IsInGroup() then
    for i=1, GetNumSubgroupMembers() do
      uid = WeakAuras.partyUnits[i];
      guid = UnitGUID(uid);
      if (guid) then
        groupMembers[guid] = GetUnitName(uid,true);
      end
    end
    if (not WeakAuras.myGUID) then
      WeakAuras.myGUID = UnitGUID("player")
    end
    groupMembers[WeakAuras.myGUID] = WeakAuras.me;
  end
  aura_cache:AssertMemberList(groupMembers);
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

  local function updateRegion(id, data, triggernum, GUID)
    local auradata,showClones = data.GUIDs[GUID];
    if(data.numAdditionalTriggers > 0) then
      showClones = data.region:IsVisible() and true or false;
    else
      showClones = true;
    end
    local region = WeakAuras.EnsureClone(id, GUID);
    if(auradata.unitName) then
      if(triggernum == 0) then
      if(region.SetDurationInfo) then
        local resort = region.expirationTime ~= auradata.expirationTime;
        region:SetDurationInfo(auradata.duration, auradata.expirationTime);

        if (resort) then
          WeakAuras.ControlChildren(id);
        end
      end

      duration_cache:SetDurationInfo(id, auradata.duration, auradata.expirationTime, nil, nil, GUID);
      if(region.SetName) then
        region:SetName(auradata.unitName);
      end
      if(region.SetIcon) then
        region:SetIcon(auradata.icon or WeakAuras.GetTempIconCache(auradata.name) or "Interface\\Icons\\INV_Misc_QuestionMark");
      end
      if(region.SetStacks) then
        region:SetStacks(auradata.count);
      end
      if(region.UpdateCustomText and not WeakAuras.IsRegisteredForCustomTextUpdates(region)) then
        region.UpdateCustomText();
      end
      WeakAuras.UpdateMouseoverTooltip(region);
      end

      if(data.numAdditionalTriggers > 0 and showClones == nil) then
      region:EnableTrigger(triggernum);
      elseif(showClones ~= false) then
      region:Expand();
      end
    else
      if(data.numAdditionalTriggers > 0 and showClones == nil) then
      region:DisableTrigger(triggernum)
      elseif(showClones ~= false) then
      region:Collapse();
      end
    end
  end

  local function updateSpell(spellName, unit, destGUID)
   for id, triggers in pairs(loaded_auras[spellName]) do
    for triggernum, data in pairs(triggers) do
      local filter = data.debuffType..(data.ownOnly and "|PLAYER" or "");
      local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(unit, spellName, nil, filter);
      if(name and (data.spellId == nil or data.spellId == spellId)) then
        data.GUIDs = data.GUIDs or {};
        data.GUIDs[destGUID] = data.GUIDs[destGUID] or {};
        data.GUIDs[destGUID].name = spellName;
        data.GUIDs[destGUID].unitName = GetUnitName(unit, true);
        data.GUIDs[destGUID].duration = duration;
        data.GUIDs[destGUID].expirationTime = expirationTime;
        data.GUIDs[destGUID].icon = icon;
        data.GUIDs[destGUID].count = count;
        updateRegion(id, data, triggernum, destGUID);
      end
    end
   end
  end

  local function combatLog(_, message, _, _, sourceName, _, _, destGUID, destName, _, _, _, spellName, _, auraType, amount)
    if(loaded_auras[spellName]) then
      if(message == "SPELL_AURA_APPLIED" or message == "SPELL_AURA_REFRESH" or message == "SPELL_AURA_APPLIED_DOSE" or message == "SPELL_AURA_REMOVED_DOSE") then
      local unit = WeakAuras.GetUID(destGUID);
      if(unit) then
        updateSpell(spellName, unit, destGUID);
      else
        for id, triggers in pairs(loaded_auras[spellName]) do
        for triggernum, data in pairs(triggers) do
          if((not data.ownOnly) or UnitIsUnit(sourceName or "", "player")) then
          pendingTracks[destGUID] = pendingTracks[destGUID] or {};
          pendingTracks[destGUID][spellName] = true;

          data.GUIDs = data.GUIDs or {};
          data.GUIDs[destGUID] = data.GUIDs[destGUID] or {};
          data.GUIDs[destGUID].name = spellName;
          data.GUIDs[destGUID].unitName = destName;
          data.GUIDs[destGUID].duration = 0;
          data.GUIDs[destGUID].expirationTime = math.huge;
          data.GUIDs[destGUID].icon = nil;
          data.GUIDs[destGUID].count = amount or 0;

          updateRegion(id, data, triggernum, destGUID);
          end
        end
        end
      end
      elseif(message == "SPELL_AURA_REMOVED") then
      for id, triggers in pairs(loaded_auras[spellName]) do
        for triggernum, data in pairs(triggers) do
        if((not data.ownOnly) or UnitIsUnit(sourceName or "", "player")) then
          -- WeakAuras.debug("Removed "..spellName.." from "..destGUID.." ("..(data.GUIDs and data.GUIDs[destGUID] and data.GUIDs[destGUID].unitName or "error")..") - "..(data.ownOnly and "own only" or "not own only")..", "..sourceName, 3);
          data.GUIDs = data.GUIDs or {};
          data.GUIDs[destGUID] = nil;

          if(clones[id] and clones[id][destGUID]) then
          clones[id][destGUID]:Collapse();
          end
        end
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
    end
  end

  local function checkExists()
    for unit, auras in pairs(loaded_auras) do
      if not(WeakAuras.unit_types[unit]) then
        for id, triggers in pairs(auras) do
          for triggernum, data in pairs(triggers) do
            if(data.GUIDs) then
              for GUID, GUIDData in pairs(data.GUIDs) do
                if(GUIDData.expirationTime and GUIDData.expirationTime + 2 < GetTime()) then
                  data.GUIDs[GUID] = nil;
                  clones[id][GUID]:Collapse();
                end
              end
            end
          end
        end
      end
    end
  end

  local function handleEvent(frame, event, ...)
    if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
      combatLog(...);
    elseif(event == "UNIT_TARGET") then
      uidTrack(...);

    -- Note: Now using UNIT_AURA in addition to COMBAT_LOG_EVENT_UNFILTERED
    --  * UNIT_AURA because there is no combat log event when an aura gets refrshed by a spell (bug?).
    --  For example Shadow Word: Pain by Mindflay, Serpent Sting by Chimera Shot/Cobra Shot
    --  * COMBAT_LOG_EVENT_UNFILTERED (I guess) because UNIT_AURA does not fire for units not in the players group/raid or he has not targeted anymore.
    elseif(event == "UNIT_AURA") then
      local uid = ...;
      local guid = UnitGUID(uid);

      for spellName, auras in pairs(loaded_auras) do
        if not(WeakAuras.unit_types[spellName]) then
          for id, triggers in pairs(auras) do
            for triggernum, data in pairs(triggers) do
              local filter = data.debuffType..(data.ownOnly and "|PLAYER" or "");
              local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(uid, spellName, nil, filter);
              if(name) then
                data.GUIDs = data.GUIDs or {};
                data.GUIDs[guid] = data.GUIDs[guid] or {};
                data.GUIDs[guid].name = spellName;
                data.GUIDs[guid].unitName = GetUnitName(uid, true);
                data.GUIDs[guid].duration = duration;
                data.GUIDs[guid].expirationTime = expirationTime;
                data.GUIDs[guid].icon = icon;
                data.GUIDs[guid].count = count;

                updateRegion(id, data, triggernum, guid);
              end
            end
          end
        end
      end
    end
  end

  local combatAuraFrame;
  function WeakAuras.InitMultiAura()
    if not(combatAuraFrame) then
      combatAuraFrame = CreateFrame("frame");
      combatAuraFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
      combatAuraFrame:RegisterEvent("UNIT_TARGET");
      combatAuraFrame:RegisterEvent("UNIT_AURA");
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
      scheduled_scans[unit][fireTime] = timer:ScheduleTimer(doScan, fireTime - GetTime() + 0.1);
    end
  end
end

local function LoadAura(id, triggernum, data)
  local unit;
  if(data.specificUnit) then
    if(data.unit:lower():sub(0,4) == "boss") then
    specificBosses[data.unit] = true;
    unit = "boss";
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


function BuffTrigger.LoadDisplay(id)
  if(auras[id]) then
    for triggernum, data in pairs(auras[id]) do
      if(auras[id] and auras[id][triggernum]) then
        LoadAura(id, triggernum, data);
      end
    end
  end
end

function BuffTrigger.Reloading()
  aura_cache:Reloading();
end

function BuffTrigger.DoneReloading()
  aura_cache:DoneReloading();
end

function BuffTrigger.Modernize(data)
  -- Give Name Info and Stack Info options to group auras
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end
    if(trigger and trigger.type == "aura" and trigger.unit and trigger.unit == "group") then
      trigger.name_info = trigger.name_info or "aura";
      trigger.stack_info = trigger.stack_info or "count";
    end
  end

  -- Fix corrupted data to time remaining and stacks (ticket #366, mod allowed users to input non numeric values)
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end
    if(trigger and (trigger.count) and not tonumber(trigger.count)) then trigger.count = 0 end
    if(trigger and (trigger.remaining) and not tonumber(trigger.remaining)) then trigger.remaining = 0 end
  end
end

function BuffTrigger.CanGroupShowWithZero(data)
  local trigger = data.trigger;
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

function BuffTrigger.CanHaveDuration(data)
  if(
    data.trigger.type == "aura"
    and not data.trigger.inverse
  ) then
    return "timed";
  else
    return false;
  end
end

function BuffTrigger.CanHaveAuto(data)
  if(
    data.trigger.type == "aura"
    and (
    not data.trigger.inverse
    or data.trigger.unit == "group"
    )
  ) then
    return true;
  else
    return false;
  end
end

function BuffTrigger.CanHaveClones(data)
  local trigger = data.trigger;
  return (trigger.fullscan and trigger.autoclone)
          or (trigger.unit == "group" and trigger.groupclone)
          or (trigger.unit == "multi");
end

WeakAuras.RegisterTriggerSystem({"aura"}, BuffTrigger);