if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local timer = WeakAuras.timer;
local L = WeakAuras.L

Private.ExecEnv.BossMods = {}

-- DBM
Private.ExecEnv.BossMods.DBM = {
  registeredEvents = {},
  bars = {},
  nextExpire = nil,
  recheckTimer = nil,

  CopyBarToState = function(self, bar, states, timerId, extendTimer)
    extendTimer = extendTimer or 0
    states[timerId] = states[timerId] or {}
    local state = states[timerId]
    state.show = true
    state.changed = true
    state.icon = bar.icon
    state.message = bar.message
    state.text = bar.message
    state.name = bar.message
    state.expirationTime = bar.expirationTime + extendTimer
    state.progressType = 'timed'
    state.duration = bar.duration + extendTimer
    state.timerType = bar.timerType
    state.spellId = bar.spellId
    state.count = bar.count
    state.dbmType = bar.dbmType
    state.dbmColor = bar.dbmColor
    state.extend = extendTimer
    if extendTimer ~= 0 then
      state.autoHide = true
    end
    state.paused = bar.paused
    state.remaining = bar.remaining
  end,

  TimerMatches = function(self, timerId, message, operator, spellId, counter, triggerId, dbmType, noCastBar)
    if not self.bars[timerId] then
      return false
    end

    local v = self.bars[timerId]
    if triggerId and triggerId ~= "" and triggerId ~= timerId then
      return false
    end
    if spellId and spellId ~= "" and spellId ~= v.spellId then
      return false
    end
    if message and message ~= "" and operator then
      if operator == "==" then
        if v.message ~= message then
          return false
        end
      elseif operator == "find('%s')" then
        if v.message == nil or not v.message:find(message, 1, true) then
          return false
        end
      elseif operator == "match('%s')" then
        if v.message == nil or not v.message:match(message) then
          return false
        end
      end
    end
    if counter then
      counter:SetCount(tonumber(v.count) or 0)
      if not counter:Match() then
        return false
      end
    end

    if noCastBar and v.timerType:find("^cast") then
      return false
    end

    if dbmType and dbmType ~= v.dbmType then
      return false
    end
    return true
  end,

  TimerMatchesGeneric = function(self, timerId, message, operator, spellId, counter)
    return self:TimerMatches(timerId, message, operator, spellId, counter, nil, nil, true)
  end,

  GetStage = function()
    if DBM then
      return DBM:GetStage()
    end
    return 0, 0
  end,

  GetAllTimers = function(self)
    return self.bars
  end,

  GetTimerById = function(self, timerId)
    return self.bars[timerId]
  end,

  GetTimer = function(self, message, operator, spellId, extendTimer, count, triggerId, dbmType, noCastBar)
    local bestMatch
    for timerId, bar in pairs(self.bars) do
      if self:TimerMatches(timerId, message, operator, spellId, count, triggerId, dbmType, noCastBar)
      and (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime)
      and bar.expirationTime + extendTimer > GetTime()
      then
        bestMatch = bar
      end
    end
    return bestMatch
  end,

  GetTimerGeneric = function(self, message, operator, spellId, extendTimer, count)
    return self:GetTimer(message, operator, spellId, extendTimer, count, nil, nil, true)
  end,

  RecheckTimers = function(self)
    local now = GetTime()
    self.nextExpire = nil
    for timerId, bar in pairs(self.bars) do
      if not bar.paused then
        if bar.expirationTime < now then
          if bar.scheduledScanExpireAt == nil or bar.scheduledScanExpireAt <= GetTime() then
            self.bars[timerId] = nil
          else
            if self.nextExpire == nil then
              self.nextExpire = bar.scheduledScanExpireAt
            elseif bar.scheduledScanExpireAt < self.nextExpire then
              self.nextExpire = bar.scheduledScanExpireAt
            end
          end
          if not bar.expired then
            bar.expired = true
            WeakAuras.ScanEvents("DBM_TimerStop", timerId)
            if self.isGeneric then
              WeakAuras.ScanEvents("BossMod_TimerStop", timerId)
            end
          end
        elseif self.nextExpire == nil then
          self.nextExpire = bar.expirationTime
        elseif bar.expirationTime < self.nextExpire then
          self.nextExpire = bar.expirationTime
        end
      end
    end
    if self.nextExpire then
      self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, self.nextExpire - now, self)
    end
  end,

  EventCallback = function(self, event, ...)
    if event == "DBM_Announce" then
      local message, icon, _, spellId, _, count = ...
      WeakAuras.ScanEvents("DBM_Announce", spellId, message, icon)
      if self.isGeneric then
        count = count and tostring(count) or "0"
        WeakAuras.ScanEvents("BossMod_Announce", spellId, message, icon, count)
      end
    elseif event == "DBM_TimerStart" then
      local timerId, msg, duration, icon, timerType, spellId, dbmType, _, _, _, _, _, timerCount = ...
      local now = GetTime()
      local expirationTime = now + duration
      self.bars[timerId] = self.bars[timerId] or {}
      local bar = self.bars[timerId]
      bar.message = msg
      bar.expirationTime = expirationTime
      bar.duration = duration
      bar.icon = icon
      bar.timerType = timerType
      bar.spellId = tostring(spellId)
      bar.count = timerCount and tostring(timerCount) or "0"
      bar.dbmType = dbmType
      bar.expired = nil

      local r, g, b = 0, 0, 0
      if DBT.GetColorForType then
        r, g, b = DBT:GetColorForType(dbmType)
        r, g, b = r or 0, g or 0, b or 0
      else
        -- Compability code for DBM versions from around Aberrus
        -- Can be removed once we can assume newer versions
        local barOptions = DBT.Options

        if dbmType == 1 then
          r, g, b = barOptions.StartColorAR, barOptions.StartColorAG, barOptions.StartColorAB
        elseif dbmType == 2 then
          r, g, b = barOptions.StartColorAER, barOptions.StartColorAEG, barOptions.StartColorAEB
        elseif dbmType == 3 then
          r, g, b = barOptions.StartColorDR, barOptions.StartColorDG, barOptions.StartColorDB
        elseif dbmType == 4 then
          r, g, b = barOptions.StartColorIR, barOptions.StartColorIG, barOptions.StartColorIB
        elseif dbmType == 5 then
          r, g, b = barOptions.StartColorRR, barOptions.StartColorRG, barOptions.StartColorRB
        elseif dbmType == 6 then
          r, g, b = barOptions.StartColorPR, barOptions.StartColorPG, barOptions.StartColorPB
        elseif dbmType == 7 then
          r, g, b = barOptions.StartColorUIR, barOptions.StartColorUIG, barOptions.StartColorUIB
        elseif dbmType == 8 then
          r, g, b = barOptions.StartColorI2R, barOptions.StartColorI2G, barOptions.StartColorI2B
        else
          r, g, b = barOptions.StartColorR, barOptions.StartColorG, barOptions.StartColorB
        end
      end
      bar.dbmColor = {r, g, b}

      WeakAuras.ScanEvents("DBM_TimerStart", timerId)
      if self.isGeneric then
        WeakAuras.ScanEvents("BossMod_TimerStart", timerId)
      end
      if self.nextExpire == nil then
        self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, expirationTime - now, self)
        self.nextExpire = expirationTime
      elseif expirationTime < self.nextExpire then
        timer:CancelTimer(self.recheckTimer)
        self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, expirationTime - now, self)
        self.nextExpire = expirationTime
      end
    elseif event == "DBM_TimerStop" then
      local timerId = ...
      local bar = self.bars[timerId]
      if bar then
        if bar.scheduledScanExpireAt == nil or bar.scheduledScanExpireAt <= GetTime() then
          self.bars[timerId] = nil
        end
        bar.expired = true
        WeakAuras.ScanEvents("DBM_TimerStop", timerId)
        if self.isGeneric then
          WeakAuras.ScanEvents("BossMod_TimerStop", timerId)
        end
      end
    elseif event == "DBM_TimerPause" then
      local timerId = ...
      local bar = self.bars[timerId]
      if bar then
        bar.paused = true
        bar.remaining = bar.expirationTime - GetTime()
        WeakAuras.ScanEvents("DBM_TimerPause", timerId)
        if self.isGeneric then
          WeakAuras.ScanEvents("BossMod_TimerPause", timerId)
        end
        if self.recheckTimer then
          timer:CancelTimer(self.recheckTimer)
        end
        self:RecheckTimers()
      end
    elseif event == "DBM_TimerResume" then
      local timerId = ...
      local bar = self.bars[timerId]
      if bar then
        bar.paused = nil
        bar.expirationTime = GetTime() + (bar.remaining or 0)
        bar.remaining = nil
        WeakAuras.ScanEvents("DBM_TimerResume", timerId)
        if self.isGeneric then
          WeakAuras.ScanEvents("BossMod_TimerResume", timerId)
        end
        if self.nextExpire == nil then
          self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, bar.expirationTime - GetTime(), self)
          self.nextExpire = bar.expirationTime
        elseif bar.expirationTime < self.nextExpire then
          timer:CancelTimer(self.recheckTimer)
          self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, bar.expirationTime - GetTime(), self)
          self.nextExpire = bar.expirationTime
        end
      end
    elseif event == "DBM_TimerUpdate" then
      local timerId, elapsed, duration = ...
      local now = GetTime()
      local expirationTime = now + duration - elapsed
      local bar = self.bars[timerId]
      if bar then
        bar.duration = duration
        bar.expirationTime = expirationTime
        if self.nextExpire == nil then
          self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, bar.expirationTime - now, self)
          self.nextExpire = expirationTime
        elseif self.nextExpire == nil or expirationTime < self.nextExpire then
          timer:CancelTimer(self.recheckTimer)
          self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, bar.expirationTime - now, self)
          self.nextExpire = expirationTime
        end
      end
      WeakAuras.ScanEvents("DBM_TimerUpdate", timerId)
      if self.isGeneric then
        WeakAuras.ScanEvents("BossMod_TimerUpdate", timerId)
      end
    elseif event == "DBM_TimerUpdateIcon" then
      local timerId, icon = ...
      local bar = self.bars[timerId]
      if bar then
        bar.icon = icon
      end
      WeakAuras.ScanEvents("DBM_TimerUpdateIcon", timerId)
      if self.isGeneric then
        WeakAuras.ScanEvents("BossMod_TimerUpdateIcon", timerId)
      end
    elseif event == "DBM_SetStage" or event == "DBM_Pull" or event == "DBM_Wipe" or event == "DBM_Kill" then
      WeakAuras.ScanEvents("DBM_SetStage")
      if self.isGeneric then
        WeakAuras.ScanEvents("BossMod_SetStage")
      end
    end
  end,

  RegisterCallback = function(self, event)
    if self.registeredEvents[event] then
      return
    end
    if DBM then
      DBM:RegisterCallback(event, function(...) self:EventCallback(...) end)
      self.registeredEvents[event] = true
    end
  end,

  RegisterTimer = function(self)
    self:RegisterCallback("DBM_TimerStart")
    self:RegisterCallback("DBM_TimerStop")
    self:RegisterCallback("DBM_TimerPause")
    self:RegisterCallback("DBM_TimerResume")
    self:RegisterCallback("DBM_TimerUpdate")
    self:RegisterCallback("DBM_TimerUpdateIcon")
  end,

  RegisterMessage = function(self)
    self:RegisterCallback("DBM_Announce")
  end,

  RegisterStage = function(self)
    self:RegisterCallback("DBM_SetStage")
    self:RegisterCallback("DBM_Pull")
    self:RegisterCallback("DBM_Kill")
  end,

  scheduled_scans = {},

  DoScan = function(self, fireTime)
    self.scheduled_scans[fireTime] = nil
    WeakAuras.ScanEvents("DBM_TimerUpdate")
    if self.isGeneric then
      WeakAuras.ScanEvents("BossMod_TimerUpdate")
    end
  end,

  ScheduleCheck = function(self, fireTime)
    if not self.scheduled_scans[fireTime] then
      self.scheduled_scans[fireTime] = timer:ScheduleTimerFixed(self.DoScan, fireTime - GetTime(), self, fireTime)
    end
  end
}

if not WeakAuras.IsTWW() then
  Private.event_prototypes["DBM Stage"] = {
    type = "addons",
    events = {},
    internal_events = {
      "DBM_SetStage"
    },
    force_events = "DBM_SetStage",
    name = L["DBM Stage"],
    init = function(trigger)
      Private.ExecEnv.BossMods.DBM:RegisterStage()
      return ""
    end,
    args = {
      {
        name = "stage",
        init = "Private.ExecEnv.BossMods.DBM:GetStage()",
        display = L["Journal Stage"],
        desc = L["Matches stage number of encounter journal.\nIntermissions are .5\nE.g. 1;2;1;2;2.5;3"],
        type = "number",
        conditionType = "number",
        store = true,
      },
      {
        name = "stageTotal",
        init = "select(2, Private.ExecEnv.BossMods.DBM:GetStage())",
        display = L["Stage Counter"],
        desc = L["Increases by one per stage or intermission."],
        type = "number",
        conditionType = "number",
        store = true,
      },
    },
    automaticrequired = true,
    statesParameter = "one",
    progressType = "none"
  }
  Private.category_event_prototype.addons["DBM Stage"] = L["DBM Stage"]

  Private.event_prototypes["DBM Announce"] = {
    type = "addons",
    events = {},
    internal_events = {
      "DBM_Announce"
    },
    name = L["DBM Announce"],
    init = function(trigger)
      Private.ExecEnv.BossMods.DBM:RegisterMessage();
      local ret = "local use_cloneId = %s;"
      return ret:format(trigger.use_cloneId and "true" or "false");
    end,
    statesParameter = "all",
    args = {
      {
        name = "spellId",
        init = "arg",
        display = L["Spell Id"],
        type = "spell",
        noValidation = true,
        showExactOption = false,
        negativeIsEJ = true
      },
      {
        name = "message",
        init = "arg",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "name",
        init = "message",
        hidden = true,
        test = "true",
        store = true,
      },
      {
        name = "icon",
        init = "arg",
        store = true,
        hidden = true,
        test = "true"
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''"
      },
    },
    timedrequired = true,
    progressType = "timed"
  }
  Private.category_event_prototype.addons["DBM Announce"] = L["DBM Announce"]

  Private.event_prototypes["DBM Timer"] = {
    type = "addons",
    events = {},
    internal_events = {
      "DBM_TimerStart", "DBM_TimerStop", "DBM_TimerUpdate", "DBM_TimerForce", "DBM_TimerResume", "DBM_TimerPause",
      "DBM_TimerUpdateIcon"
    },
    force_events = "DBM_TimerForce",
    name = L["DBM Timer"],
    progressType = "timed",
    triggerFunction = function(trigger)
      Private.ExecEnv.BossMods.DBM:RegisterTimer()
      local ret = [=[
        local triggerCounter = %q
        local counter
        if triggerCounter and triggerCounter ~= "" then
          counter = Private.ExecEnv.CreateTriggerCounter(triggerCounter)
        else
          counter = Private.ExecEnv.CreateTriggerCounter()
        end
        return function (states, event, timerId)
          local triggerId = %q
          local triggerSpellId = %q
          local triggerText = %q
          local triggerTextOperator = %q
          local useClone = %s
          local extendTimer = %s
          local triggerUseRemaining = %s
          local triggerRemaining = %s
          local triggerDbmType = %s
          local cloneId = useClone and timerId or ""
          local state = states[cloneId]
          local counter = counter

          function copyOrSchedule(bar, cloneId)
            local remainingTime
            local changed
            if bar.paused then
              remainingTime = bar.remaining + extendTimer
            else
              remainingTime = bar.expirationTime - GetTime() + extendTimer
            end
            if triggerUseRemaining then
              if remainingTime > 0 and remainingTime %s triggerRemaining then
                Private.ExecEnv.BossMods.DBM:CopyBarToState(bar, states, cloneId, extendTimer)
                changed = true
              else
                local state = states[cloneId]
                if state and state.show then
                  state.show = false
                  state.changed = true
                  changed = true
                end
              end
              if not bar.paused then
                if extendTimer > 0 then
                  bar.scheduledScanExpireAt = math.max(bar.scheduledScanExpireAt or 0, bar.expirationTime + extendTimer)
                end
                if remainingTime >= triggerRemaining  then
                  Private.ExecEnv.BossMods.DBM:ScheduleCheck(bar.expirationTime - triggerRemaining + extendTimer)
                end
              end
            else
              if not bar.paused and extendTimer > 0 then
                bar.scheduledScanExpireAt = math.max(bar.scheduledScanExpireAt or 0, bar.expirationTime + extendTimer)
              end
              if remainingTime > 0 then
                Private.ExecEnv.BossMods.DBM:CopyBarToState(bar, states, cloneId, extendTimer)
                changed = true
              end
            end
            return changed
          end

          if useClone then
            if event == "DBM_TimerStart"
            or event == "DBM_TimerPause"
            or event == "DBM_TimerResume"
            then
              if Private.ExecEnv.BossMods.DBM:TimerMatches(timerId, triggerText, triggerTextOperator, triggerSpellId, counter, triggerId, triggerDbmType) then
                local bar = Private.ExecEnv.BossMods.DBM:GetTimerById(timerId)
                if bar then
                  return copyOrSchedule(bar, cloneId)
                end
              end
            elseif event == "DBM_TimerStop" and state then
              local bar_remainingTime = state.expirationTime - GetTime() + (state.extend or 0)
              if state.extend == 0 or bar_remainingTime <= 0 then
                state.show = false
                state.changed = true
                return true
              end
            elseif event == "DBM_TimerUpdate" or event == "DBM_TimerUpdateIcon" then
              local changed
              for timerId, bar in pairs(Private.ExecEnv.BossMods.DBM:GetAllTimers()) do
                if Private.ExecEnv.BossMods.DBM:TimerMatches(timerId, triggerText, triggerTextOperator, triggerSpellId, counter, triggerId, triggerDbmType) then
                  changed = copyOrSchedule(bar, timerId) or changed
                else
                  local state = states[timerId]
                  if state then
                    local bar_remainingTime = state.expirationTime - GetTime() + (state.extend or 0)
                    if state.extend == 0 or bar_remainingTime <= 0 then
                      state.show = false
                      state.changed = true
                      changed = true
                    end
                  end
                end
              end
              return changed
            elseif event == "DBM_TimerForce" then
              local changed
              for _, state in pairs(states) do
                state.show = false
                state.changed = true
                changed = true
              end
              for timerId, bar in pairs(Private.ExecEnv.BossMods.DBM:GetAllTimers()) do
                if Private.ExecEnv.BossMods.DBM:TimerMatches(timerId, triggerText, triggerTextOperator, triggerSpellId, counter, triggerId, triggerDbmType) then
                  changed = copyOrSchedule(bar, timerId) or changed
                end
              end
              return changed
            end
          else
            if event == "DBM_TimerStart" or event == "DBM_TimerUpdate" then
              if extendTimer ~= 0 then
                if Private.ExecEnv.BossMods.DBM:TimerMatches(timerId, triggerText, triggerTextOperator, triggerSpellId, counter, triggerId, triggerDbmType) then
                  local bar = Private.ExecEnv.BossMods.DBM:GetTimerById(timerId)
                  Private.ExecEnv.BossMods.DBM:ScheduleCheck(bar.expirationTime + extendTimer)
                end
              end
            end
            local bar = Private.ExecEnv.BossMods.DBM:GetTimer(triggerText, triggerTextOperator, triggerSpellId, extendTimer, counter, triggerId, triggerDbmType)
            if bar then
              if extendTimer == 0
                or not (state and state.show)
                or (state and state.show and state.expirationTime > (bar.expirationTime + extendTimer))
              then
                return copyOrSchedule(bar, cloneId)
              end
            else
              if state and state.show then
                local bar_remainingTime = state.expirationTime - GetTime() + (state.extend or 0)
                if state.extend == 0 or bar_remainingTime <= 0 then
                  state.show = false
                  state.changed = true
                  return true
                end
              end
            end
          end
        end
        ]=]

      return ret:format(
        trigger.use_count and trigger.count or "",
        trigger.use_id and trigger.id or "",
        trigger.use_spellId and tostring(trigger.spellId) or "",
        trigger.use_message and trigger.message or "",
        trigger.use_message and trigger.message_operator or "",
        trigger.use_cloneId and "true" or "false",
        trigger.use_extend and tonumber(trigger.extend or 0) or 0,
        trigger.use_remaining and "true" or "false",
        trigger.remaining and tonumber(trigger.remaining or 0) or 0,
        trigger.use_dbmType and trigger.dbmType or "nil",
        trigger.remaining_operator or "<"
      )
    end,
    statesParameter = "full",
    args = {
      {
        name = "id",
        display = L["Timer Id"],
        type = "string",
      },
      {
        name = "spellId",
        display = L["Spell Id"],
        store = true,
        type = "spell",
        conditionType = "string",
        noValidation = true,
        showExactOption = false,
        negativeIsEJ = true
      },
      {
        name = "message",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
      },
      {
        name = "extend",
        display = L["Offset Timer"],
        type = "string",
      },
      {
        name = "count",
        display = L["Count"],
        desc = L["Occurrence of the event, reset when aura is unloaded\nCan be a range of values\nCan have multiple values separated by a comma or a space\n\nExamples:\n2nd 5th and 6th events: 2, 5, 6\n2nd to 6th: 2-6\nevery 2 events: /2\nevery 3 events starting from 2nd: 2/3\nevery 3 events starting from 2nd and ending at 11th: 2-11/3\n\nOnly if DBM shows it on it's bar"],
        type = "string",
        conditionType = "string",
      },
      {
        name = "dbmType",
        display = L["Type"],
        type = "select",
        values = "dbm_types",
        conditionType = "select",
        test = "true"
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle"
      }
    },
    automaticrequired = true,
  }
  Private.category_event_prototype.addons["DBM Timer"] = L["DBM Timer"]
end

-- BigWigs
Private.ExecEnv.BossMods.BigWigs = {
  registeredEvents = {},
  bars = {},
  nextExpire = nil,
  recheckTimer = nil,
  currentStage = 0,

  CopyBarToState = function(self, bar, states, timerId, extendTimer)
    extendTimer = extendTimer or 0
    states[timerId] = states[timerId] or {}
    local state = states[timerId]
    state.show = true
    state.changed = true
    state.addon = bar.addon
    state.spellId = bar.spellId
    state.text = bar.text
    state.message = bar.text
    state.name = bar.text
    state.duration = bar.duration + extendTimer
    state.expirationTime = bar.expirationTime + extendTimer
    state.bwBarColor = bar.bwBarColor
    state.bwTextColor = bar.bwTextColor
    state.bwBackgroundColor = bar.bwBackgroundColor
    state.count = bar.count
    state.cast = bar.cast
    state.progressType = "timed"
    state.icon = bar.icon
    state.extend = extendTimer
    if extendTimer ~= 0 then
      state.autoHide = true
    end
    state.paused = bar.paused
    state.remaining = bar.remaining
    state.isCooldown = bar.isCooldown
  end,

  TimerMatches = function(self, timerId, message, operator, spellId, counter, cast, cooldown)
    if not self.bars[timerId] then
      return false
    end

    local v = self.bars[timerId]
    if spellId and spellId ~= "" and spellId ~= v.spellId then
      return false
    end
    if message and message ~= "" and operator then
      if operator == "==" then
        if v.text ~= message then
          return false
        end
      elseif operator == "find('%s')" then
        if v.text == nil or not v.text:find(message, 1, true) then
          return false
        end
      elseif operator == "match('%s')" then
        if v.text == nil or not v.text:match(message) then
          return false
        end
      end
    end
    if counter then
      counter:SetCount(tonumber(v.count) or 0)
      if not counter:Match() then
        return false
      end
    end
    if cast ~= nil and v.cast ~= cast then
      return false
    end
    if cooldown ~= nil and v.isCooldown ~= cooldown then
      return false
    end
    return true
  end,

  TimerMatchesGeneric = function(self, timerId, message, operator, spellId, counter)
    return self:TimerMatches(timerId, message, operator, spellId, counter, false, nil)
  end,

  GetStage = function(self)
    return self.currentStage
  end,

  GetAllTimers = function(self)
    return self.bars
  end,

  GetTimerById = function(self, timerId)
    return self.bars[timerId]
  end,

  GetTimer = function(self, text, operator, spellId, extendTimer, counter, cast, cooldown)
    local bestMatch
    for timerId, bar in pairs(self.bars) do
      if self:TimerMatches(timerId, text, operator, spellId, counter, cast, cooldown)
      and (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime)
      and bar.expirationTime + extendTimer > GetTime()
      then
        bestMatch = bar
      end
    end
    return bestMatch
  end,

  GetTimerGeneric = function(self, text, operator, spellId, extendTimer, counter)
    return self:GetTimer(text, operator, spellId, extendTimer, counter, false, nil)
  end,

  RecheckTimers = function(self)
    local now = GetTime()
    self.nextExpire = nil
    for timerId, bar in pairs(self.bars) do
      if not bar.paused then
        if bar.expirationTime < now then
          if bar.scheduledScanExpireAt == nil or bar.scheduledScanExpireAt <= GetTime() then
            self.bars[timerId] = nil
          else
            if self.nextExpire == nil then
              self.nextExpire = bar.scheduledScanExpireAt
            elseif bar.scheduledScanExpireAt < self.nextExpire then
              self.nextExpire = bar.scheduledScanExpireAt
            end
          end
          if not bar.expired then
            bar.expired = true
            WeakAuras.ScanEvents("BigWigs_StopBar", timerId)
            if self.isGeneric then
              WeakAuras.ScanEvents("BossMod_TimerStop", timerId)
            end
          end
        elseif self.nextExpire == nil then
          self.nextExpire = bar.expirationTime
        elseif bar.expirationTime < self.nextExpire then
          self.nextExpire = bar.expirationTime
        end
      end
    end

    if self.nextExpire then
      self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, self.nextExpire - now, self)
    end
  end,

  EventCallback = function(self, event, ...)
    if event == "BigWigs_Message" then
      WeakAuras.ScanEvents("BigWigs_Message", ...)
      if self.isGeneric then
        local _, spellId, text, _, icon = ...
        local count = text and text:match("%((%d+)%)") or text:match("（(%d+)）") or "0"
        WeakAuras.ScanEvents("BossMod_Announce", spellId, text, icon, count)
      end
    elseif event == "BigWigs_StartBar" then
      local addon, spellId, text, duration, icon, isCD = ...
      local now = GetTime()
      local expirationTime = now + duration

      self.bars[text] = self.bars[text] or {}
      local bar = self.bars[text]
      bar.addon = addon
      bar.spellId = tostring(spellId)
      bar.name = text
      bar.text = text
      bar.duration = duration
      bar.expirationTime = expirationTime
      bar.icon = icon
      bar.isCooldown = isCD or false
      bar.expired = nil
      local BWColorModule = BigWigs:GetPlugin("Colors")
      bar.bwBarColor = BWColorModule:GetColorTable("barColor", addon, spellId)
      bar.bwTextColor = BWColorModule:GetColorTable("barText", addon, spellId)
      bar.bwBackgroundColor = BWColorModule:GetColorTable("barBackground", addon, spellId)
      bar.count = text:match("%((%d+)%)") or text:match("（(%d+)）") or "0"
      bar.cast = not(text:match("^[^<]") and true)

      WeakAuras.ScanEvents("BigWigs_StartBar", text)
      if self.isGeneric then
        WeakAuras.ScanEvents("BossMod_TimerStart", text)
      end
      if self.nextExpire == nil then
        self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, expirationTime - now, self)
        self.nextExpire = expirationTime
      elseif expirationTime < self.nextExpire then
        timer:CancelTimer(self.recheckTimer)
        self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, expirationTime - now, self)
        self.nextExpire = expirationTime
      end
    elseif event == "BigWigs_StopBar" then
      local addon, text = ...
      local bar = self.bars[text]
      if bar then
        if bar.scheduledScanExpireAt == nil or bar.scheduledScanExpireAt <= GetTime() then
          self.bars[text] = nil
        end
        WeakAuras.ScanEvents("BigWigs_StopBar", text)
        if self.isGeneric then
          WeakAuras.ScanEvents("BossMod_TimerStop", text)
        end
      end
    elseif event == "BigWigs_PauseBar" then
      local addon, text = ...
      local bar = self.bars[text]
      if bar and not bar.paused then
        bar.paused = true
        bar.remaining = bar.expirationTime - GetTime()
        WeakAuras.ScanEvents("BigWigs_PauseBar", text)
        if self.isGeneric then
          WeakAuras.ScanEvents("BossMod_TimerPause", text)
        end
        if self.recheckTimer then
          timer:CancelTimer(self.recheckTimer)
        end
        self:RecheckTimers()
      end
    elseif event == "BigWigs_ResumeBar" then
      local addon, text = ...
      local bar = self.bars[text]
      if bar and bar.paused then
        bar.paused = nil
        bar.expirationTime = GetTime() + (bar.remaining or 0)
        bar.remaining = nil
        WeakAuras.ScanEvents("BigWigs_ResumeBar", text)
        if self.isGeneric then
          WeakAuras.ScanEvents("BossMod_TimerResume", text)
        end
        if self.nextExpire == nil then
          self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, bar.expirationTime - GetTime(), self)
        elseif bar.expirationTime < self.nextExpire then
          timer:CancelTimer(self.recheckTimer)
          self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, bar.expirationTime - GetTime(), self)
          self.nextExpire = bar.expirationTime
        end
      end
    elseif event == "BigWigs_StopBars"
    or event == "BigWigs_OnBossDisable"
    or event == "BigWigs_OnPluginDisable"
    then
      local addon = ...
      for timerId, bar in pairs(self.bars) do
        if bar.addon == addon then
          self.bars[timerId] = nil
          WeakAuras.ScanEvents("BigWigs_StopBar", timerId)
          if self.isGeneric then
            WeakAuras.ScanEvents("BossMod_TimerStop", timerId)
          end
        end
      end
    elseif event == "BigWigs_SetStage" then
      local addon, stage = ...
      self.currentStage = stage
      WeakAuras.ScanEvents("BigWigs_SetStage")
      if self.isGeneric then
        WeakAuras.ScanEvents("BossMod_SetStage")
      end
    elseif event == "BigWigs_OnBossWipe" or event == "BigWigs_OnBossWin" then
      self.currentStage = 0
      WeakAuras.ScanEvents("BigWigs_SetStage")
      if self.isGeneric then
        WeakAuras.ScanEvents("BossMod_SetStage")
      end
    end
  end,

  RegisterCallback = function(self, event)
    if self.registeredEvents[event] then
      return
    end
    if BigWigsLoader then
      BigWigsLoader.RegisterMessage(WeakAuras, event, function(...) self:EventCallback(...) end)
      self.registeredEvents[event] = true
      if event == "BigWigs_SetStage" then
        -- on init of BigWigs_SetStage callback, we want to fetch currentStage in case we are already in an encounter when this is run
        if BigWigs and BigWigs.IterateBossModules then
          local stage = 0
          for _, module in BigWigs:IterateBossModules() do
            if module:IsEngaged() then
              stage = math.max(stage, module:GetStage() or 1)
            end
          end
          self.currentStage = stage
        end
      end
    end
  end,

  RegisterTimer = function(self)
    self:RegisterCallback("BigWigs_StartBar")
    self:RegisterCallback("BigWigs_StopBar")
    self:RegisterCallback("BigWigs_StopBars")
    self:RegisterCallback("BigWigs_OnBossDisable")
    self:RegisterCallback("BigWigs_PauseBar")
    self:RegisterCallback("BigWigs_ResumeBar")
  end,

  RegisterMessage = function(self)
    self:RegisterCallback("BigWigs_Message")
  end,

  RegisterStage = function(self)
    self:RegisterCallback("BigWigs_SetStage")
    self:RegisterCallback("BigWigs_OnBossWipe")
    self:RegisterCallback("BigWigs_OnBossWin")
  end,

  scheduled_scans = {},

  DoScan = function(self, fireTime)
    self.scheduled_scans[fireTime] = nil
    WeakAuras.ScanEvents("BigWigs_Timer_Update")
    if self.isGeneric then
      WeakAuras.ScanEvents("BossMod_TimerUpdate")
    end
  end,

  ScheduleCheck = function(self, fireTime)
    if not self.scheduled_scans[fireTime] then
      self.scheduled_scans[fireTime] = timer:ScheduleTimerFixed(self.DoScan, fireTime - GetTime(), self, fireTime)
    end
  end
}

if not WeakAuras.IsTWW() then
  Private.event_prototypes["BigWigs Stage"] = {
    type = "addons",
    events = {},
    internal_events = {
      "BigWigs_SetStage"
    },
    name = L["BigWigs Stage"],
    init = function(trigger)
      Private.ExecEnv.BossMods.BigWigs:RegisterStage()
      return ""
    end,
    args = {
      {
        name = "stage",
        init = "Private.ExecEnv.BossMods.BigWigs:GetStage()",
        display = L["Stage"],
        type = "number",
        conditionType = "number",
        store = true,
      }
    },
    automaticrequired = true,
    statesParameter = "one",
    progressType = "none"
  }
  Private.category_event_prototype.addons["BigWigs Stage"] = L["BigWigs Stage"]

  Private.event_prototypes["BigWigs Message"] = {
    type = "addons",
    events = {},
    internal_events = {
      "BigWigs_Message"
    },
    name = L["BigWigs Message"],
    init = function(trigger)
      Private.ExecEnv.BossMods.BigWigs:RegisterMessage();
      local ret = "local use_cloneId = %s;"
      return ret:format(trigger.use_cloneId and "true" or "false");
    end,
    statesParameter = "all",
    args = {
      {
        name = "addon",
        init = "arg",
        display = L["BigWigs Addon"],
        type = "string"
      },
      {
        name = "spellId",
        init = "arg",
        display = L["ID"],
        desc = L["The 'ID' value can be found in the BigWigs options of a specific spell"],
        type = "spell",
        conditionType = "string",
        noValidation = true,
        showExactOption = false,
        negativeIsEJ = true
      },
      {
        name = "text",
        init = "arg",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "name",
        init = "text",
        hidden = true,
        test = "true",
        store = true
      },
      {}, -- Importance, might be useful
      {
        name = "icon",
        init = "arg",
        hidden = true,
        test = "true",
        store = true
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''"
      },
    },
    timedrequired = true,
    progressType = "timed"
  }
  Private.category_event_prototype.addons["BigWigs Message"] = L["BigWigs Message"]

  Private.event_prototypes["BigWigs Timer"] = {
    type = "addons",
    events = {},
    internal_events = {
      "BigWigs_StartBar", "BigWigs_StopBar", "BigWigs_Timer_Update", "BigWigs_PauseBar", "BigWigs_ResumeBar"
    },
    force_events = "BigWigs_Timer_Force",
    name = L["BigWigs Timer"],
    progressType = "timed",
    triggerFunction = function(trigger)
      Private.ExecEnv.BossMods.BigWigs:RegisterTimer()
      local ret = [=[
        local triggerCounter = %q
        local counter
        if triggerCounter and triggerCounter ~= "" then
          counter = Private.ExecEnv.CreateTriggerCounter(triggerCounter)
        else
          counter = Private.ExecEnv.CreateTriggerCounter()
        end
        return function(states, event, timerId)
          local triggerSpellId = %q
          local triggerText = %q
          local triggerTextOperator = %q
          local useClone = %s
          local extendTimer = %s
          local triggerUseRemaining = %s
          local triggerRemaining = %s
          local triggerCast = %s
          local triggerIsCooldown = %s
          local cloneId = useClone and timerId or ""
          local state = states[cloneId]
          local counter = counter

          function copyOrSchedule(bar, cloneId)
            local remainingTime
            local changed
            if bar.paused then
              remainingTime = bar.remaining + extendTimer
            else
              remainingTime = bar.expirationTime - GetTime() + extendTimer
            end
            if triggerUseRemaining then
              if remainingTime > 0 and remainingTime %s triggerRemaining then
                Private.ExecEnv.BossMods.BigWigs:CopyBarToState(bar, states, cloneId, extendTimer)
                changed = true
              else
                local state = states[cloneId]
                if state and state.show then
                  state.show = false
                  state.changed = true
                  changed = true
                end
              end
              if not bar.paused then
                if extendTimer > 0 then
                  bar.scheduledScanExpireAt = math.max(bar.scheduledScanExpireAt or 0, bar.expirationTime + extendTimer)
                end
                if remainingTime >= triggerRemaining then
                  Private.ExecEnv.BossMods.BigWigs:ScheduleCheck(bar.expirationTime - triggerRemaining + extendTimer)
                end
              end
            else
              if not bar.paused and extendTimer > 0 then
                bar.scheduledScanExpireAt = math.max(bar.scheduledScanExpireAt or 0, bar.expirationTime + extendTimer)
              end
              if remainingTime > 0 then
                Private.ExecEnv.BossMods.BigWigs:CopyBarToState(bar, states, cloneId, extendTimer)
                changed = true
              end
            end
            return changed
          end

          if useClone then
            if event == "BigWigs_StartBar"
            or event == "BigWigs_PauseBar"
            or event == "BigWigs_ResumeBar"
            then
              if Private.ExecEnv.BossMods.BigWigs:TimerMatches(timerId, triggerText, triggerTextOperator, triggerSpellId, counter, triggerCast, triggerIsCooldown) then
                local bar = Private.ExecEnv.BossMods.BigWigs:GetTimerById(timerId)
                if bar then
                  return copyOrSchedule(bar, cloneId)
                end
              end
            elseif event == "BigWigs_StopBar" and state then
              local bar_remainingTime = state.expirationTime - GetTime() + (state.extend or 0)
              if state.extend == 0 or bar_remainingTime <= 0 then
                state.show = false
                state.changed = true
                return true
              end
            elseif event == "BigWigs_Timer_Update" then
              local changed
              for timerId, bar in pairs(Private.ExecEnv.BossMods.BigWigs:GetAllTimers()) do
                if Private.ExecEnv.BossMods.BigWigs:TimerMatches(timerId, triggerText, triggerTextOperator, triggerSpellId, counter, triggerCast, triggerIsCooldown) then
                  changed = copyOrSchedule(bar, timerId) or changed
                end
              end
              return changed
            elseif event == "BigWigs_Timer_Force" then
              local changed
              for _, state in pairs(states) do
                state.show = false
                state.changed = true
                changed = true
              end
              for timerId, bar in pairs(Private.ExecEnv.BossMods.BigWigs:GetAllTimers()) do
                if Private.ExecEnv.BossMods.BigWigs:TimerMatches(timerId, triggerText, triggerTextOperator, triggerSpellId, counter, triggerCast, triggerIsCooldown) then
                  changed = copyOrSchedule(bar, timerId) or changed
                end
              end
              return changed
            end
          else
            if event == "BigWigs_StartBar" then
              if extendTimer ~= 0 then
                if Private.ExecEnv.BossMods.BigWigs:TimerMatches(timerId, triggerText, triggerTextOperator, triggerSpellId, counter, triggerCast, triggerIsCooldown) then
                  local bar = Private.ExecEnv.BossMods.BigWigs:GetTimerById(timerId)
                  Private.ExecEnv.BossMods.BigWigs:ScheduleCheck(bar.expirationTime + extendTimer)
                end
              end
            end
            local bar = Private.ExecEnv.BossMods.BigWigs:GetTimer(triggerText, triggerTextOperator, triggerSpellId, extendTimer, counter, triggerCast, triggerIsCooldown)
            if bar then
              if extendTimer == 0
                or not (state and state.show)
                or (state and state.show and state.expirationTime > (bar.expirationTime + extendTimer))
              then
                return copyOrSchedule(bar, cloneId)
              end
            else
              if state and state.show then
                local bar_remainingTime = state.expirationTime - GetTime() + (state.extend or 0)
                if state.extend == 0 or bar_remainingTime <= 0 then
                  state.show = false
                  state.changed = true
                  return true
                end
              end
            end
          end
        end
      ]=]
      return ret:format(
        trigger.use_count and trigger.count or "",
        trigger.use_spellId and tostring(trigger.spellId) or "",
        trigger.use_text and trigger.text or "",
        trigger.use_text and trigger.text_operator or "",
        trigger.use_cloneId and "true" or "false",
        trigger.use_extend and tonumber(trigger.extend or 0) or 0,
        trigger.use_remaining and "true" or "false",
        trigger.remaining and tonumber(trigger.remaining or 0) or 0,
        trigger.use_cast == nil and "nil" or trigger.use_cast and "true" or "false",
        trigger.use_isCooldown == nil and "nil" or trigger.use_isCooldown and "true" or "false",
        trigger.remaining_operator or "<"
      )
    end,
    statesParameter = "full",
    args = {
      {
        name = "spellId",
        display = L["ID"],
        desc = L["The 'ID' value can be found in the BigWigs options of a specific spell"],
        type = "spell",
        conditionType = "string",
        noValidation = true,
        showExactOption = false,
        negativeIsEJ = true
      },
      {
        name = "text",
        display = L["Message"],
        type = "longstring",
        store = true,
        conditionType = "string"
      },
      {
        name = "remaining",
        display = L["Remaining Time"],
        type = "number",
      },
      {
        name = "extend",
        display = L["Offset Timer"],
        type = "string",
      },
      {
        name = "count",
        display = L["Count"],
        desc = L["Occurrence of the event, reset when aura is unloaded\nCan be a range of values\nCan have multiple values separated by a comma or a space\n\nExamples:\n2nd 5th and 6th events: 2, 5, 6\n2nd to 6th: 2-6\nevery 2 events: /2\nevery 3 events starting from 2nd: 2/3\nevery 3 events starting from 2nd and ending at 11th: 2-11/3\n\nOnly if BigWigs shows it on it's bar"],
        type = "string",
        store = true,
        conditionType = "string",
      },
      {
        name = "cast",
        display = L["Cast Bar"],
        desc = L["Filter messages with format <message>"],
        type = "tristate",
        test = "true",
        init = "false",
        conditionType = "bool"
      },
      {
        name = "isCooldown",
        display = L["Cooldown"],
        desc = L["Cooldown bars show time before an ability is ready to be use, BigWigs prefix them with '~'"],
        type = "tristate",
        test = "true",
        init = "false",
        conditionType = "bool"
      },
      {
        name = "cloneId",
        display = L["Clone per Event"],
        type = "toggle",
        test = "true",
        init = "false"
      },
    },
    automaticrequired = true,
  }
  Private.category_event_prototype.addons["BigWigs Timer"] = L["BigWigs Timer"]
end

-- Unified
if BigWigsLoader or not DBM then
  Private.ExecEnv.BossMods.Generic = Private.ExecEnv.BossMods.BigWigs
  Private.ExecEnv.BossMods.BigWigs.isGeneric = true
  Private.ExecEnv.BossMods.BigWigs.isInstalled = BigWigsLoader ~= nil
elseif DBM then
  Private.ExecEnv.BossMods.Generic = Private.ExecEnv.BossMods.DBM
  Private.ExecEnv.BossMods.DBM.isGeneric = true
  Private.ExecEnv.BossMods.DBM.isInstalled = true
end

local ActiveBossModText
if Private.ExecEnv.BossMods.BigWigs.isInstalled then
  ActiveBossModText = L["Active boss mod addon: |cFFffcc00BigWigs|r\n\nNote: This trigger will use BigWigs or DBM, in that order if both are installed."]
elseif Private.ExecEnv.BossMods.DBM.isInstalled then
  ActiveBossModText = L["Active boss mod addon: |cFFffcc00DBM|r\n\nNote: This trigger will use BigWigs or DBM, in that order if both are installed."]
else
  ActiveBossModText = L["No active boss mod addon detected.\n\nNote: This trigger will use BigWigs or DBM, in that order if both are installed."]
end

Private.event_prototypes["Boss Mod Stage"] = {
  type = "addons",
  events = {},
  internal_events = {
    "BossMod_SetStage"
  },
  force_events = "BossMod_SetStage",
  name = L["Boss Mod Stage"],
  init = function(trigger)
    Private.ExecEnv.BossMods.Generic:RegisterStage()
    return ""
  end,
  args = {
    {
      name = "stage",
      init = "Private.ExecEnv.BossMods.Generic:GetStage()",
      display = L["Stage"],
      type = "number",
      conditionType = "number",
      store = true,
    },
    {
      name = "note",
      type = "description",
      display = "",
      text = ActiveBossModText
    },
  },
  automaticrequired = true,
  statesParameter = "one",
  progressType = "none"
}
Private.category_event_prototype.addons["Boss Mod Stage"] = L["Boss Mod Stage"]

Private.event_prototypes["Boss Mod Stage (Event)"] = {
  type = "event",
  events = {
    ["events"] = {
      "BossMod_SetStage",
    }
  },
  name = L["Boss Mod Stage (Event)"],
  init = function(trigger)
    Private.ExecEnv.BossMods.Generic:RegisterStage()
    return ""
  end,
  args = {
    {
      name = "stage",
      init = "Private.ExecEnv.BossMods.Generic:GetStage()",
      display = L["Stage"],
      type = "number",
      conditionType = "number",
      store = true,
    },
    {
      name = "note",
      type = "description",
      display = "",
      text = ActiveBossModText
    },
  },
  statesParameter = "one",
  progressType = "timed",
  delayEvents = true,
  timedrequired = true
}
Private.category_event_prototype.addons["Boss Mod Stage (Event)"] = L["Boss Mod Stage (Event)"]

Private.event_prototypes["Boss Mod Announce"] = {
  type = "addons",
  events = {},
  internal_events = {
    "BossMod_Announce"
  },
  name = L["Boss Mod Announce"],
  init = function(trigger)
    Private.ExecEnv.BossMods.Generic:RegisterMessage();
    local ret = "local use_cloneId = %s;"
    return ret:format(trigger.use_cloneId and "true" or "false");
  end,
  statesParameter = "all",
  args = {
    {
      name = "spellId",
      init = "arg",
      display = L["ID"],
      store = true,
      type = "spell",
      conditionType = "string",
      noValidation = true,
      showExactOption = false,
      negativeIsEJ = true
    },
    {
      name = "message",
      init = "arg",
      display = L["Message"],
      type = "longstring",
      store = true,
      conditionType = "string"
    },
    {
      name = "name",
      init = "message",
      hidden = true,
      test = "true",
      store = true,
    },
    {
      name = "icon",
      init = "arg",
      store = true,
      hidden = true,
      test = "true"
    },
    {
      name = "count",
      init = "arg",
      display = L["Count"],
      desc = L["Occurrence of the event\nCan be a range of values\nCan have multiple values separated by a comma or a space\n\nExamples:\n2nd 5th and 6th events: 2, 5, 6\n2nd to 6th: 2-6\nevery 2 events: /2\nevery 3 events starting from 2nd: 2/3\nevery 3 events starting from 2nd and ending at 11th: 2-11/3\n\nWorks only if Boss Mod addon show counter"],
      type = "string",
      preamble = "local counter = Private.ExecEnv.CreateTriggerCounter(%q)",
      test = "counter:SetCount(tonumber(count) or 0) == nil and counter:Match()",
      conditionTest = function(state, needle, op, preamble)
        return preamble:Check(state.count)
      end,
      store = true,
      conditionType = "string",
    },
    {
      name = "cloneId",
      display = L["Clone per Event"],
      type = "toggle",
      test = "true",
      init = "use_cloneId and WeakAuras.GetUniqueCloneId() or ''"
    },
    {
      name = "note",
      type = "description",
      display = "",
      text = ActiveBossModText
    },
  },
  timedrequired = true,
  progressType = "timed"
}
Private.category_event_prototype.addons["Boss Mod Announce"] = L["Boss Mod Announce"]

Private.event_prototypes["Boss Mod Timer"] = {
  type = "addons",
  events = {},
  internal_events = {
    "BossMod_TimerStart", "BossMod_TimerStop", "BossMod_TimerUpdate", "BossMod_TimerForce", "BossMod_TimerResume",
    "BossMod_TimerPause", "BossMod_TimerUpdateIcon"
  },
  force_events = "BossMod_TimerForce",
  name = L["Boss Mod Timer"],
  progressType = "timed",
  triggerFunction = function(trigger)
    Private.ExecEnv.BossMods.Generic:RegisterTimer()
    local ret = [=[
      local triggerCounter = %q
      local counter
      if triggerCounter and triggerCounter ~= "" then
        counter = Private.ExecEnv.CreateTriggerCounter(triggerCounter)
      else
        counter = Private.ExecEnv.CreateTriggerCounter()
      end
      local isBW = Private.ExecEnv.BossMods.Generic == Private.ExecEnv.BossMods.BigWigs
      local isDBM = Private.ExecEnv.BossMods.Generic == Private.ExecEnv.BossMods.DBM

      return function (states, event, timerId)
        local triggerSpellId = %q
        local triggerText = %q
        local triggerTextOperator = %q
        local useClone = %s
        local extendTimer = %s
        local triggerUseRemaining = %s
        local triggerRemaining = %s
        local cloneId = useClone and timerId or ""
        local state = states[cloneId]
        local counter = counter

        function copyOrSchedule(bar, cloneId)
          local remainingTime
          local changed
          if bar.paused then
            remainingTime = bar.remaining + extendTimer
          else
            remainingTime = bar.expirationTime - GetTime() + extendTimer
          end
          if triggerUseRemaining then
            if remainingTime > 0 and remainingTime %s triggerRemaining then
              Private.ExecEnv.BossMods.Generic:CopyBarToState(bar, states, cloneId, extendTimer)
              changed = true
            else
              local state = states[cloneId]
              if state and state.show then
                state.show = false
                state.changed = true
                changed = true
              end
            end
            if not bar.paused then
              if extendTimer > 0 then
                bar.scheduledScanExpireAt = math.max(bar.scheduledScanExpireAt or 0, bar.expirationTime + extendTimer)
              end
              if remainingTime >= triggerRemaining  then
                Private.ExecEnv.BossMods.Generic:ScheduleCheck(bar.expirationTime - triggerRemaining + extendTimer)
              end
            end
          else
            if not bar.paused and extendTimer > 0 then
              bar.scheduledScanExpireAt = math.max(bar.scheduledScanExpireAt or 0, bar.expirationTime + extendTimer)
            end
            if remainingTime > 0 then
              Private.ExecEnv.BossMods.Generic:CopyBarToState(bar, states, cloneId, extendTimer)
              changed = true
            end
          end
          return changed
        end

        if useClone then
          if event == "BossMod_TimerStart"
          or event == "BossMod_TimerPause"
          or event == "BossMod_TimerResume"
          then
            if Private.ExecEnv.BossMods.Generic:TimerMatchesGeneric(timerId, triggerText, triggerTextOperator, triggerSpellId, counter) then
              local bar = Private.ExecEnv.BossMods.Generic:GetTimerById(timerId)
              if bar then
                return copyOrSchedule(bar, cloneId)
              end
            end
          elseif event == "BossMod_TimerStop" and state then
            local bar_remainingTime = state.expirationTime - GetTime() + (state.extend or 0)
            if state.extend == 0 or bar_remainingTime <= 0 then
              state.show = false
              state.changed = true
              return true
            end
          elseif event == "BossMod_TimerUpdate" or event == "BossMod_TimerUpdateIcon" then
            local changed
            for timerId, bar in pairs(Private.ExecEnv.BossMods.Generic:GetAllTimers()) do
              if Private.ExecEnv.BossMods.Generic:TimerMatchesGeneric(timerId, triggerText, triggerTextOperator, triggerSpellId, counter) then
                changed = copyOrSchedule(bar, timerId) or changed
              else
                local state = states[timerId]
                if state then
                  local bar_remainingTime = state.expirationTime - GetTime() + (state.extend or 0)
                  if state.extend == 0 or bar_remainingTime <= 0 then
                    state.show = false
                    state.changed = true
                    changed = true
                  end
                end
              end
            end
            return changed
          elseif event == "BossMod_TimerForce" then
            local changed
            for _, state in pairs(states) do
              state.show = false
              state.changed = true
              changed = true
            end
            for timerId, bar in pairs(Private.ExecEnv.BossMods.Generic:GetAllTimers()) do
              if Private.ExecEnv.BossMods.Generic:TimerMatchesGeneric(timerId, triggerText, triggerTextOperator, triggerSpellId, counter) then
                changed = copyOrSchedule(bar, timerId) or changed
              end
            end
            return changed
          end
        else
          if event == "BossMod_TimerStart" or event == "BossMod_TimerUpdate" then
            if extendTimer ~= 0 then
              if Private.ExecEnv.BossMods.Generic:TimerMatchesGeneric(timerId, triggerText, triggerTextOperator, triggerSpellId, counter) then
                local bar = Private.ExecEnv.BossMods.Generic:GetTimerById(timerId)
                Private.ExecEnv.BossMods.Generic:ScheduleCheck(bar.expirationTime + extendTimer)
              end
            end
          end
          local bar = Private.ExecEnv.BossMods.Generic:GetTimerGeneric(triggerText, triggerTextOperator, triggerSpellId, extendTimer, counter)
          if bar then
            if extendTimer == 0
              or not (state and state.show)
              or (state and state.show and state.expirationTime > (bar.expirationTime + extendTimer))
            then
              return copyOrSchedule(bar, cloneId)
            end
          else
            if state and state.show then
              local bar_remainingTime = state.expirationTime - GetTime() + (state.extend or 0)
              if state.extend == 0 or bar_remainingTime <= 0 then
                state.show = false
                state.changed = true
                return true
              end
            end
          end
        end
      end
      ]=]

    return ret:format(
      trigger.use_count and trigger.count or "",
      trigger.use_spellId and tostring(trigger.spellId) or "",
      trigger.use_message and trigger.message or "",
      trigger.use_message and trigger.message_operator or "",
      trigger.use_cloneId and "true" or "false",
      trigger.use_extend and tonumber(trigger.extend or 0) or 0,
      trigger.use_remaining and "true" or "false",
      trigger.remaining and tonumber(trigger.remaining or 0) or 0,
      trigger.remaining_operator or "<"
    )
  end,
  statesParameter = "full",
  args = {
    {
      name = "spellId",
      display = L["ID"],
      store = true,
      type = "spell",
      conditionType = "string",
      noValidation = true,
      showExactOption = false,
      negativeIsEJ = true
    },
    {
      name = "message",
      display = L["Message"],
      type = "longstring",
      store = true,
      conditionType = "string"
    },
    {
      name = "remaining",
      display = L["Remaining Time"],
      type = "number",
    },
    {
      name = "extend",
      display = L["Offset Timer"],
      type = "string",
    },
    {
      name = "count",
      display = L["Count"],
      desc = L["Occurrence of the event, reset when aura is unloaded\nCan be a range of values\nCan have multiple values separated by a comma or a space\n\nExamples:\n2nd 5th and 6th events: 2, 5, 6\n2nd to 6th: 2-6\nevery 2 events: /2\nevery 3 events starting from 2nd: 2/3\nevery 3 events starting from 2nd and ending at 11th: 2-11/3\n\nOnly if DBM shows it on it's bar"],
      type = "string",
      conditionType = "string",
    },
    {
      name = "cloneId",
      display = L["Clone per Event"],
      type = "toggle"
    },
    {
      name = "note",
      type = "description",
      display = "",
      text = ActiveBossModText
    },
  },
  automaticrequired = true,
}
Private.category_event_prototype.addons["Boss Mod Timer"] = L["Boss Mod Timer"]


