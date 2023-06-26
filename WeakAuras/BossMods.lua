if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local timer = WeakAuras.timer;

Private.ExecEnv.BossMods = {}

-- DBM
Private.ExecEnv.BossMods.DBM = {
  registeredEvents = {},
  bars = {},
  nextExpire = nil,
  recheckTimer = nil,

  CopyBarToState = function(self, bar, states, id, extendTimer)
    extendTimer = extendTimer or 0
    if extendTimer + bar.duration < 0 then return end
    states[id] = states[id] or {}
    local state = states[id]
    state.show = true
    state.changed = true
    state.icon = bar.icon
    state.message = bar.message
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

  TimerMatches = function(self, id, message, operator, spellId, counter, timerId, dbmType)
    if not self.bars[timerId] then
      return false
    end

    local v = self.bars[timerId]
    if id and id ~= "" and id ~= timerId then
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
    if dbmType and dbmType ~= v.dbmType then
      return false
    end
    return true
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

  GetTimerById = function(self, id)
    return self.bars[id]
  end,

  GetTimer = function(self, id, message, operator, spellId, extendTimer, count, dbmType)
    local bestMatch
    for timerId, bar in pairs(self.bars) do
      if self:TimerMatches(id, message, operator, spellId, count, timerId, dbmType)
      and (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime)
      and bar.expirationTime + extendTimer > GetTime()
      then
        bestMatch = bar
      end
    end
    return bestMatch
  end,

  RecheckTimers = function(self)
    local now = GetTime()
    self.nextExpire = nil
    for id, bar in pairs(self.bars) do
      if not bar.paused then
        if bar.expirationTime < now then
          self.bars[id] = nil
          WeakAuras.ScanEvents("DBM_TimerStop", id)
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
    if event == "DBM_TimerStart" then
      local id, msg, duration, icon, timerType, spellId, dbmType, _, _, _, _, _, timerCount = ...
      local now = GetTime()
      local expirationTime = now + duration
      self.bars[id] = self.bars[id] or {}
      local bar = self.bars[id]
      bar.message = msg
      bar.expirationTime = expirationTime
      bar.duration = duration
      bar.icon = icon
      bar.timerType = timerType
      bar.spellId = tostring(spellId)
      bar.count = timerCount and tostring(timerCount) or "0"
      bar.dbmType = dbmType

      local barOptions = DBT.Options or DBM.Bars.options
      local r, g, b = 0, 0, 0
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
      else
        r, g, b = barOptions.StartColorR, barOptions.StartColorG, barOptions.StartColorB
      end
      bar.dbmColor = {r, g, b}

      WeakAuras.ScanEvents("DBM_TimerStart", id)
      if self.nextExpire == nil then
        self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, expirationTime - now, self)
        self.nextExpire = expirationTime
      elseif expirationTime < self.nextExpire then
        timer:CancelTimer(self.recheckTimer)
        self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, expirationTime - now, self)
        self.nextExpire = expirationTime
      end
    elseif event == "DBM_TimerStop" then
      local id = ...
      self.bars[id] = nil
      WeakAuras.ScanEvents("DBM_TimerStop", id)
    elseif event == "kill" or event == "wipe" then -- Wipe or kill, removing all timers
      local id = ...
      wipe(self.bars)
      WeakAuras.ScanEvents("DBM_TimerStopAll", id)
    elseif event == "DBM_TimerPause" then
      local id = ...
      local bar = self.bars[id]
      if bar then
        bar.paused = true
        bar.remaining = bar.expirationTime - GetTime()
        WeakAuras.ScanEvents("DBM_TimerPause", id)
        if self.recheckTimer then
          timer:CancelTimer(self.recheckTimer)
        end
        self:RecheckTimers()
      end
    elseif event == "DBM_TimerResume" then
      local id = ...
      local bar = self.bars[id]
      if bar then
        bar.paused = nil
        bar.expirationTime = GetTime() + (bar.remaining or 0)
        bar.remaining = nil
        WeakAuras.ScanEvents("DBM_TimerResume", id)
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
      local id, elapsed, duration = ...
      local now = GetTime()
      local expirationTime = now + duration - elapsed
      local bar = self.bars[id]
      if bar then
        bar.duration = duration
        bar.expirationTime = expirationTime
        if self.nextExpire == nil then
          self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, bar.expirationTime - GetTime(), self)
          self.nextExpire = expirationTime
        elseif self.nextExpire == nil or expirationTime < self.nextExpire then
          timer:CancelTimer(self.recheckTimer)
          self.recheckTimer = timer:ScheduleTimerFixed(self.RecheckTimers, duration - elapsed, self)
          self.nextExpire = expirationTime
        end
      end
      WeakAuras.ScanEvents("DBM_TimerUpdate", id)
    elseif event == "DBM_SetStage" or event == "DBM_Pull" or event == "DBM_Wipe" or event == "DBM_Kill" then
      WeakAuras.ScanEvents("DBM_SetStage")
    else -- DBM_Announce
      WeakAuras.ScanEvents(event, ...)
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
    self:RegisterCallback("wipe")
    self:RegisterCallback("kill")
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
  end,

  ScheduleCheck = function(self, fireTime)
    if not self.scheduled_scans[fireTime] then
      self.scheduled_scans[fireTime] = timer:ScheduleTimerFixed(self.DoScan, fireTime - GetTime() + 0.1, self, fireTime)
    end
  end
}

-- BigWigs
Private.ExecEnv.BossMods.BigWigs = {
  registeredEvents = {},
  bars = {},
  nextExpire = nil,
  recheckTimer = nil,
  currentStage = 0,

  CopyBarToState = function(self, bar, states, id, extendTimer)
    extendTimer = extendTimer or 0
    if extendTimer + bar.duration < 0 then return end
    states[id] = states[id] or {}
    local state = states[id]
    state.show = true
    state.changed = true
    state.addon = bar.addon
    state.spellId = bar.spellId
    state.text = bar.text
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

  TimerMatches = function(self, id, message, operator, spellId, counter, cast, cooldown)
    if not self.bars[id] then
      return false
    end

    local v = self.bars[id]
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

  GetStage = function(self)
    return self.currentStage
  end,

  GetAllTimers = function(self)
    return self.bars
  end,

  GetTimerById = function(self, id)
    return self.bars[id]
  end,

  GetTimer = function(self, text, operator, spellId, extendTimer, counter, cast)
    local bestMatch
    for id, bar in pairs(self.bars) do
      if self:TimerMatches(id, text, operator, spellId, counter, cast)
      and (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime)
      and bar.expirationTime + extendTimer > GetTime()
      then
        bestMatch = bar
      end
    end
    return bestMatch
  end,

  RecheckTimers = function(self)
    local now = GetTime()
    self.nextExpire = nil
    for id, bar in pairs(self.bars) do
      if not bar.paused then
        if bar.expirationTime < now then
          self.bars[id] = nil
          WeakAuras.ScanEvents("BigWigs_StopBar", id)
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
    elseif event == "BigWigs_StartBar" then
      local addon, spellId, text, duration, icon, isCD = ...
      local now = GetTime()
      local expirationTime = now + duration

      self.bars[text] = self.bars[text] or {}
      local bar = self.bars[text]
      bar.addon = addon
      bar.spellId = tostring(spellId)
      bar.text = text
      bar.duration = duration
      bar.expirationTime = expirationTime
      bar.icon = icon
      bar.isCooldown = isCD or false
      local BWColorModule = BigWigs:GetPlugin("Colors")
      bar.bwBarColor = BWColorModule:GetColorTable("barColor", addon, spellId)
      bar.bwTextColor = BWColorModule:GetColorTable("barText", addon, spellId)
      bar.bwBackgroundColor = BWColorModule:GetColorTable("barBackground", addon, spellId)
      bar.count = text:match("%((%d+)%)") or text:match("（(%d+)）") or "0"
      bar.cast = not(text:match("^[^<]") and true)

      WeakAuras.ScanEvents("BigWigs_StartBar", text)
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
      if self.bars[text] then
        self.bars[text] = nil
        WeakAuras.ScanEvents("BigWigs_StopBar", text)
      end
    elseif event == "BigWigs_PauseBar" then
      local addon, text = ...
      local bar = self.bars[text]
      if bar and not bar.paused then
        bar.paused = true
        bar.remaining = bar.expirationTime - GetTime()
        WeakAuras.ScanEvents("BigWigs_PauseBar", text)
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
      for id, bar in pairs(self.bars) do
        if bar.addon == addon then
          self.bars[id] = nil
          WeakAuras.ScanEvents("BigWigs_StopBar", id)
        end
      end
    elseif event == "BigWigs_SetStage" then
      local addon, stage = ...
      self.currentStage = stage
      WeakAuras.ScanEvents("BigWigs_SetStage", ...)
    elseif event == "BigWigs_OnBossWipe" or event == "BigWigs_OnBossWin" then
      self.currentStage = 0
      WeakAuras.ScanEvents("BigWigs_SetStage", ...)
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
  end,

  ScheduleCheck = function(self, fireTime)
    if not self.scheduled_scans[fireTime] then
      self.scheduled_scans[fireTime] = timer:ScheduleTimerFixed(self.DoScan, fireTime - GetTime() + 0.1, self, fireTime)
    end
  end
}

if BigWigsLoader then
  Private.ExecEnv.BossMods.Generic = Private.ExecEnv.BossMods.BigWigs
elseif DBM then
  Private.ExecEnv.BossMods.Generic = Private.ExecEnv.BossMods.DBM
end
