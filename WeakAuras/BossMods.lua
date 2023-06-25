if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local timer = WeakAuras.timer;

Private.ExecEnv.BossMods = {}

-- DBM
do
  Private.ExecEnv.BossMods.DBM = {}
  local registeredDBMEvents = {}
  local bars = {}
  local nextExpire -- time of next expiring timer
  local recheckTimer -- handle of timer
  local currentStage = 0 -- can do 1>2>1>2>1>...
  local currentStageTotal = 0 -- always 1>2>3>4>...
  local function dbmRecheckTimers()
    local now = GetTime()
    nextExpire = nil
    for id, bar in pairs(bars) do
      if not bar.paused then
        if bar.expirationTime < now then
          bars[id] = nil
          WeakAuras.ScanEvents("DBM_TimerStop", id)
        elseif nextExpire == nil then
          nextExpire = bar.expirationTime
        elseif bar.expirationTime < nextExpire then
          nextExpire = bar.expirationTime
        end
      end
    end

    if nextExpire then
      recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, nextExpire - now)
    end
  end

  local function dbmEventCallback(event, ...)
    if event == "DBM_TimerStart" then
      local id, msg, duration, icon, timerType, spellId, dbmType, _, _, _, _, _, timerCount = ...
      local now = GetTime()
      local expirationTime = now + duration
      bars[id] = bars[id] or {}
      local bar = bars[id]
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
      if nextExpire == nil then
        recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, expirationTime - now)
        nextExpire = expirationTime
      elseif expirationTime < nextExpire then
        timer:CancelTimer(recheckTimer)
        recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, expirationTime - now)
        nextExpire = expirationTime
      end
    elseif event == "DBM_TimerStop" then
      local id = ...
      bars[id] = nil
      WeakAuras.ScanEvents("DBM_TimerStop", id)
    elseif event == "kill" or event == "wipe" then -- Wipe or kill, removing all timers
      local id = ...
      wipe(bars)
      WeakAuras.ScanEvents("DBM_TimerStopAll", id)
    elseif event == "DBM_TimerPause" then
      local id = ...
      local bar = bars[id]
      if bar then
        bar.paused = true
        bar.remaining = bar.expirationTime - GetTime()
        WeakAuras.ScanEvents("DBM_TimerPause", id)
        if recheckTimer then
          timer:CancelTimer(recheckTimer)
        end
        dbmRecheckTimers()
      end
    elseif event == "DBM_TimerResume" then
      local id = ...
      local bar = bars[id]
      if bar then
        bar.paused = nil
        bar.expirationTime = GetTime() + (bar.remaining or 0)
        bar.remaining = nil
        WeakAuras.ScanEvents("DBM_TimerResume", id)
        if nextExpire == nil then
          recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, bar.expirationTime - GetTime())
          nextExpire = bar.expirationTime
        elseif bar.expirationTime < nextExpire then
          timer:CancelTimer(recheckTimer)
          recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, bar.expirationTime - GetTime())
          nextExpire = bar.expirationTime
        end
      end
    elseif event == "DBM_TimerUpdate" then
      local id, elapsed, duration = ...
      local now = GetTime()
      local expirationTime = now + duration - elapsed
      local bar = bars[id]
      if bar then
        bar.duration = duration
        bar.expirationTime = expirationTime
        if nextExpire == nil then
          recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, bar.expirationTime - GetTime())
          nextExpire = expirationTime
        elseif nextExpire == nil or expirationTime < nextExpire then
          timer:CancelTimer(recheckTimer)
          recheckTimer = timer:ScheduleTimerFixed(dbmRecheckTimers, duration - elapsed)
          nextExpire = expirationTime
        end
      end
      WeakAuras.ScanEvents("DBM_TimerUpdate", id)
    elseif event == "DBM_SetStage" or event == "DBM_Pull" or event == "DBM_Wipe" or event == "DBM_Kill" then
      WeakAuras.ScanEvents("DBM_SetStage")
    else -- DBM_Announce
      WeakAuras.ScanEvents(event, ...)
    end
  end

  function Private.ExecEnv.BossMods.DBM.TimerMatches(timerId, id, message, operator, spellId, dbmType, counter)
    if not bars[timerId] then
      return false
    end

    local v = bars[timerId]
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
  end

  function Private.ExecEnv.BossMods.DBM.GetStage()
    if DBM then
      return DBM:GetStage()
    end
    return 0, 0
  end

  function Private.ExecEnv.BossMods.DBM.GetTimerById(id)
    return bars[id]
  end

  function Private.ExecEnv.BossMods.DBM.GetAllTimers()
    return bars
  end

  function Private.ExecEnv.BossMods.DBM.GetTimer(id, message, operator, spellId, extendTimer, dbmType, count)
    local bestMatch
    for timerId, bar in pairs(bars) do
      if Private.ExecEnv.BossMods.DBM.TimerMatches(timerId, id, message, operator, spellId, dbmType, count)
      and (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime)
      and bar.expirationTime + extendTimer > GetTime()
      then
        bestMatch = bar
      end
    end
    return bestMatch
  end

  function Private.ExecEnv.BossMods.DBM.CopyBarToState(bar, states, id, extendTimer)
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
  end

  function Private.ExecEnv.BossMods.DBM.RegisterCallback(event)
    if registeredDBMEvents[event] then
      return
    end
    if DBM then
      DBM:RegisterCallback(event, dbmEventCallback)
      registeredDBMEvents[event] = true
    end
  end

  function Private.ExecEnv.BossMods.DBM.RegisterTimer()
    Private.ExecEnv.BossMods.DBM.RegisterCallback("DBM_TimerStart")
    Private.ExecEnv.BossMods.DBM.RegisterCallback("DBM_TimerStop")
    Private.ExecEnv.BossMods.DBM.RegisterCallback("DBM_TimerPause")
    Private.ExecEnv.BossMods.DBM.RegisterCallback("DBM_TimerResume")
    Private.ExecEnv.BossMods.DBM.RegisterCallback("DBM_TimerUpdate")
    Private.ExecEnv.BossMods.DBM.RegisterCallback("wipe")
    Private.ExecEnv.BossMods.DBM.RegisterCallback("kill")
  end

  function Private.ExecEnv.BossMods.DBM.GetDBMTimers()
    return bars
  end

  local scheduled_scans = {}

  local function doDbmScan(fireTime)
    scheduled_scans[fireTime] = nil
    WeakAuras.ScanEvents("DBM_TimerUpdate")
  end
  function Private.ExecEnv.BossMods.DBM.ScheduleCheck(fireTime)
    if not scheduled_scans[fireTime] then
      scheduled_scans[fireTime] = timer:ScheduleTimerFixed(doDbmScan, fireTime - GetTime() + 0.1, fireTime)
    end
  end
end

-- BigWigs
do
  Private.ExecEnv.BossMods.BigWigs = {}
  local registeredBigWigsEvents = {}
  local bars = {}
  local nextExpire -- time of next expiring timer
  local recheckTimer -- handle of timer
  local currentStage = 0

  local function recheckTimers()
    local now = GetTime()
    nextExpire = nil
    for id, bar in pairs(bars) do
      if not bar.paused then
        if bar.expirationTime < now then
          bars[id] = nil
          WeakAuras.ScanEvents("BigWigs_StopBar", id)
        elseif nextExpire == nil then
          nextExpire = bar.expirationTime
        elseif bar.expirationTime < nextExpire then
          nextExpire = bar.expirationTime
        end
      end
    end

    if nextExpire then
      recheckTimer = timer:ScheduleTimerFixed(recheckTimers, nextExpire - now)
    end
  end

  local function bigWigsEventCallback(event, ...)
    if event == "BigWigs_Message" then
      WeakAuras.ScanEvents("BigWigs_Message", ...)
    elseif event == "BigWigs_StartBar" then
      local addon, spellId, text, duration, icon, isCD = ...
      local now = GetTime()
      local expirationTime = now + duration

      local newBar
      bars[text] = bars[text] or {}
      local bar = bars[text]
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
      if nextExpire == nil then
        recheckTimer = timer:ScheduleTimerFixed(recheckTimers, expirationTime - now)
        nextExpire = expirationTime
      elseif expirationTime < nextExpire then
        timer:CancelTimer(recheckTimer)
        recheckTimer = timer:ScheduleTimerFixed(recheckTimers, expirationTime - now)
        nextExpire = expirationTime
      end
    elseif event == "BigWigs_StopBar" then
      local addon, text = ...
      if bars[text] then
        bars[text] = nil
        WeakAuras.ScanEvents("BigWigs_StopBar", text)
      end
    elseif event == "BigWigs_PauseBar" then
      local addon, text = ...
      local bar = bars[text]
      if bar and not bar.paused then
        bar.paused = true
        bar.remaining = bar.expirationTime - GetTime()
        WeakAuras.ScanEvents("BigWigs_PauseBar", text)
        if recheckTimer then
          timer:CancelTimer(recheckTimer)
        end
        recheckTimers()
      end
    elseif event == "BigWigs_ResumeBar" then
      local addon, text = ...
      local bar = bars[text]
      if bar and bar.paused then
        bar.paused = nil
        bar.expirationTime = GetTime() + (bar.remaining or 0)
        bar.remaining = nil
        WeakAuras.ScanEvents("BigWigs_ResumeBar", text)
        if nextExpire == nil then
          recheckTimer = timer:ScheduleTimerFixed(recheckTimers, bar.expirationTime - GetTime())
        elseif bar.expirationTime < nextExpire then
          timer:CancelTimer(recheckTimer)
          recheckTimer = timer:ScheduleTimerFixed(recheckTimers, bar.expirationTime - GetTime())
          nextExpire = bar.expirationTime
        end
      end
    elseif event == "BigWigs_StopBars"
    or event == "BigWigs_OnBossDisable"
    or event == "BigWigs_OnPluginDisable"
    then
      local addon = ...
      for id, bar in pairs(bars) do
        if bar.addon == addon then
          bars[id] = nil
          WeakAuras.ScanEvents("BigWigs_StopBar", id)
        end
      end
    elseif event == "BigWigs_SetStage" then
      local addon, stage = ...
      currentStage = stage
      WeakAuras.ScanEvents("BigWigs_SetStage", ...)
    elseif event == "BigWigs_OnBossWipe" or event == "BigWigs_OnBossWin" then
      currentStage = 0
      WeakAuras.ScanEvents("BigWigs_SetStage", ...)
    end
  end

  function Private.ExecEnv.BossMods.BigWigs.RegisterCallback(event)
    if registeredBigWigsEvents[event] then
      return
    end
    if BigWigsLoader then
      BigWigsLoader.RegisterMessage(WeakAuras, event, bigWigsEventCallback)
      registeredBigWigsEvents[event] = true
      if event == "BigWigs_SetStage" then
        -- on init of BigWigs_SetStage callback, we want to fetch currentStage in case we are already in an encounter when this is run
        if BigWigs and BigWigs.IterateBossModules then
          local stage = 0
          for _, module in BigWigs:IterateBossModules() do
            if module:IsEngaged() then
              stage = math.max(stage, module:GetStage() or 1)
            end
          end
          currentStage = stage
        end
      end
    end
  end

  function Private.ExecEnv.BossMods.BigWigs.RegisterTimer()
    Private.ExecEnv.BossMods.BigWigs.RegisterCallback("BigWigs_StartBar")
    Private.ExecEnv.BossMods.BigWigs.RegisterCallback("BigWigs_StopBar")
    Private.ExecEnv.BossMods.BigWigs.RegisterCallback("BigWigs_StopBars")
    Private.ExecEnv.BossMods.BigWigs.RegisterCallback("BigWigs_OnBossDisable")
    Private.ExecEnv.BossMods.BigWigs.RegisterCallback("BigWigs_PauseBar")
    Private.ExecEnv.BossMods.BigWigs.RegisterCallback("BigWigs_ResumeBar")
  end

  function Private.ExecEnv.BossMods.BigWigs.CopyBarToState(bar, states, id, extendTimer)
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
  end

  function Private.ExecEnv.BossMods.BigWigs.TimerMatches(id, message, operator, spellId, counter, cast, cooldown)
    if not bars[id] then
      return false
    end

    local v = bars[id]
    local bestMatch
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
  end

  function Private.ExecEnv.BossMods.BigWigs.GetStage()
    return currentStage
  end

  function Private.ExecEnv.BossMods.BigWigs.GetAllTimers()
    return bars
  end

  function Private.ExecEnv.BossMods.BigWigs.GetTimerById(id)
    return bars[id]
  end

  function Private.ExecEnv.BossMods.BigWigs.GetTimer(text, operator, spellId, extendTimer, counter, cast)
    local bestMatch
    for id, bar in pairs(bars) do
      if Private.ExecEnv.BossMods.BigWigs.TimerMatches(id, text, operator, spellId, counter, cast)
      and (bestMatch == nil or bar.expirationTime < bestMatch.expirationTime)
      and bar.expirationTime + extendTimer > GetTime()
      then
        bestMatch = bar
      end
    end
    return bestMatch
  end

  local scheduled_scans = {}

  local function doBigWigsScan(fireTime)
    scheduled_scans[fireTime] = nil
    WeakAuras.ScanEvents("BigWigs_Timer_Update")
  end

  function Private.ExecEnv.BossMods.BigWigs.ScheduleCheck(fireTime)
    if not scheduled_scans[fireTime] then
      scheduled_scans[fireTime] = timer:ScheduleTimerFixed(doBigWigsScan, fireTime - GetTime() + 0.1, fireTime)
    end
  end
end
