if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub:GetLibrary("LibDeflate")

local UnitAura = UnitAura
if UnitAura == nil then
  --- Deprecated in 10.2.5
  UnitAura = function(unitToken, index, filter)
		local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
		if not auraData then
			return nil;
		end

		return AuraUtil.UnpackAuraData(auraData)
	end
end

-- Unit Aura functions that return info about the first Aura matching the spellName or spellID given on the unit.
local WA_GetUnitAura = function(unit, spell, filter)
  if filter and not filter:upper():find("FUL") then
      filter = filter.."|HELPFUL"
  end
  for i = 1, 255 do
    local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
    if not name then return end
    if spell == spellId or spell == name then
      return UnitAura(unit, i, filter)
    end
  end
end

local WA_GetUnitBuff = function(unit, spell, filter)
  filter = filter and filter.."|HELPFUL" or "HELPFUL"
  return WA_GetUnitAura(unit, spell, filter)
end

local WA_GetUnitDebuff = function(unit, spell, filter)
  filter = filter and filter.."|HARMFUL" or "HARMFUL"
  return WA_GetUnitAura(unit, spell, filter)
end

-- Function to assist iterating group members whether in a party or raid.
local WA_IterateGroupMembers = function(reversed, forceParty)
  local unit = (not forceParty and IsInRaid()) and 'raid' or 'party'
  local numGroupMembers = unit == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
  local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
  return function()
    local ret
    if i == 0 and unit == 'party' then
      ret = 'player'
    elseif i <= numGroupMembers and i > 0 then
      ret = unit .. i
    end
    i = i + (reversed and -1 or 1)
    return ret
  end
end

-- Wrapping a unit's name in its class colour is very common in custom Auras
local WA_ClassColorName = function(unit)
  if unit and UnitExists(unit) then
    local name = WeakAuras.UnitName(unit)
    local _, class = UnitClass(unit)
    if not class then
      return name
    else
      local classData = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
      local coloredName = ("|c%s%s|r"):format(classData.colorStr, name)
      return coloredName
    end
  else
    return "" -- ¯\_(ツ)_/¯
  end
end

WeakAuras.WA_ClassColorName = WA_ClassColorName

-- UTF-8 Sub is pretty commonly needed
local WA_Utf8Sub = function(input, size)
  local output = ""
  if type(input) ~= "string" then
    return output
  end
  local i = 1
  while (size > 0) do
    local byte = input:byte(i)
    if not byte then
      return output
    end
    if byte < 128 then
      -- ASCII byte
      output = output .. input:sub(i, i)
      size = size - 1
    elseif byte < 192 then
      -- Continuation bytes
      output = output .. input:sub(i, i)
    elseif byte < 244 then
      -- Start bytes
      output = output .. input:sub(i, i)
      size = size - 1
    end
    i = i + 1
  end

  -- Add any bytes that are part of the sequence
  while (true) do
    local byte = input:byte(i)
    if byte and byte >= 128 and byte < 192 then
      output = output .. input:sub(i, i)
    else
      break
    end
    i = i + 1
  end

  return output
end

WeakAuras.WA_Utf8Sub = WA_Utf8Sub

local LCG = LibStub("LibCustomGlow-1.0")
WeakAuras.ShowOverlayGlow = LCG.ButtonGlow_Start
WeakAuras.HideOverlayGlow = LCG.ButtonGlow_Stop

local LGF = LibStub("LibGetFrame-1.0")
WeakAuras.GetUnitFrame = LGF.GetUnitFrame
WeakAuras.GetUnitNameplate =  function(unit)
  if Private.multiUnitUnits.nameplate[unit] then
    return LGF.GetUnitNameplate(unit)
  end
end

local blockedFunctions = {
  -- Lua functions that may allow breaking out of the environment
  getfenv = true,
  setfenv = true,
  loadstring = true,
  pcall = true,
  xpcall = true,
  -- blocked WoW API
  SendMail = true,
  SetTradeMoney = true,
  AddTradeMoney = true,
  PickupTradeMoney = true,
  PickupPlayerMoney = true,
  TradeFrame = true,
  MailFrame = true,
  EnumerateFrames = true,
  RunScript = true,
  AcceptTrade = true,
  SetSendMailMoney = true,
  EditMacro = true,
  DevTools_DumpCommand = true,
  hash_SlashCmdList = true,
  RegisterNewSlashCommand = true,
  CreateMacro = true,
  SetBindingMacro = true,
  GuildDisband = true,
  GuildUninvite = true,
  securecall = true,
  DeleteCursorItem = true,
  ChatEdit_SendText = true,
  ChatEdit_ActivateChat = true,
  ChatEdit_ParseText = true,
  ChatEdit_OnEnterPressed = true,
  GetButtonMetatable = true,
  GetEditBoxMetatable = true,
  GetFontStringMetatable = true,
  GetFrameMetatable = true,
}

local blockedTables = {
  SlashCmdList = true,
  SendMailMailButton = true,
  SendMailMoneyGold = true,
  MailFrameTab2 = true,
  DEFAULT_CHAT_FRAME = true,
  ChatFrame1 = true,
  WeakAurasSaved = true,
  WeakAurasOptions = true,
  WeakAurasOptionsSaved = true
}

local aura_environments = {}
-- nil == Not initiliazed
-- 1 == config initialized
-- 2 == fully initialized
local environment_initialized = {}
local getDataCallCounts = {}

function Private.IsEnvironmentInitialized(id)
  return environment_initialized[id] == 2
end

function Private.DeleteAuraEnvironment(id)
  aura_environments[id] = nil
  environment_initialized[id] = nil
  getDataCallCounts[id] = nil
end

function Private.RenameAuraEnvironment(oldid, newid)
  aura_environments[oldid], aura_environments[newid] = nil, aura_environments[oldid]
  environment_initialized[oldid], environment_initialized[newid] = nil, environment_initialized[oldid]
  getDataCallCounts[oldid], getDataCallCounts[newid] = nil, getDataCallCounts[oldid]
end

local current_uid = nil
local current_aura_env = nil
-- Stack of of aura environments/uids, allows use of recursive aura activations through calls to WeakAuras.ScanEvents().
local aura_env_stack = {}


local function UpdateSavedDataWarning(uid, size)
  local savedDataWarning = 16 * 1024 * 1024 -- 16 KB, but it's only a warning
  if size > savedDataWarning then
    Private.AuraWarnings.UpdateWarning(uid, "CustomSavedData", "warning",
                                       L["This aura is saving %s KB of data"]:format(ceil(size / 1024)))
  else
    Private.AuraWarnings.UpdateWarning(uid, "CustomSavedData")
  end
end

function Private.SaveAuraEnvironment(id)
  local data = WeakAuras.GetData(id)
  if not data then
    return
  end

  local input = aura_environments[id] and aura_environments[id].saved
  if input then
    local serialized = LibSerialize:SerializeEx({errorOnUnserializableType = false}, input)
    -- We use minimal compression, since that already achieves a reasonable compression ratio,
    -- but takes significant less time
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 1})
    local encoded = LibDeflate:EncodeForPrint(compressed)
    UpdateSavedDataWarning(data.uid, #encoded)
    data.information.saved = encoded
  else
    data.information.saved = nil
  end
end

function Private.RestoreAuraEnvironment(id)
  local data = WeakAuras.GetData(id)
  if not data then
    return
  end

  local input = data.information.saved
  if input then
    local decoded = LibDeflate:DecodeForPrint(input)
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    local success, deserialized = LibSerialize:Deserialize(decompressed)
    if success then
      aura_environments[id].saved = deserialized
    else
      aura_environments[id].saved = nil
    end
    UpdateSavedDataWarning(data.uid, #input)
  else
    aura_environments[id].saved = nil
  end
end

function Private.ClearAuraEnvironmentSavedData(id)
  if environment_initialized[id] == 2 then
    aura_environments[id].saved = nil
  end
end

function Private.ClearAuraEnvironment(id)
  if environment_initialized[id] == 2 then
    Private.SaveAuraEnvironment(id)
    environment_initialized[id] = nil
    aura_environments[id] = nil
    getDataCallCounts[id] = nil
  end
end

function Private.ActivateAuraEnvironmentForRegion(region, onlyConfig)
  Private.ActivateAuraEnvironment(region.id, region.cloneId, region.state, region.states, onlyConfig)
end

function Private.ActivateAuraEnvironment(id, cloneId, state, states, onlyConfig)
  local data = id and WeakAuras.GetData(id)
  if not data then
    -- Pop the last aura_env from the stack, and update current_aura_env appropriately.
    tremove(aura_env_stack)
    if aura_env_stack[#aura_env_stack] then
      current_aura_env, current_uid = unpack(aura_env_stack[#aura_env_stack])
    else
      current_aura_env = nil
      current_uid = nil
    end
  else
    -- Existing config is initialized to a high enough value
    if environment_initialized[id] == 2 or (onlyConfig and environment_initialized[id] == 1) then
      local region = WeakAuras.GetRegion(id, cloneId)
      -- Point the current environment to the correct table
      current_uid = data.uid
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      current_aura_env.region = region
      -- Push the new environment onto the stack
      tinsert(aura_env_stack, {current_aura_env, data.uid})
    elseif onlyConfig then
      environment_initialized[id] = 1
      aura_environments[id] = {}
      getDataCallCounts[id] = 0
      current_uid = data.uid
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      tinsert(aura_env_stack, {current_aura_env, data.uid})

      if not data.controlledChildren then
        current_aura_env.config = CopyTable(data.config)
      end
    else
      -- Either this aura environment has not yet been initialized, or it was reset via an edit in WeakaurasOptions
      local region = id and Private.EnsureRegion(id, cloneId)
      environment_initialized[id] = 2
      aura_environments[id] = aura_environments[id] or {}
      getDataCallCounts[id] = getDataCallCounts[id] or 0
      current_uid = data.uid
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      current_aura_env.region = region
      Private.RestoreAuraEnvironment(id)
      -- push new environment onto the stack
      tinsert(aura_env_stack, {current_aura_env, data.uid})

      if data.controlledChildren then
        current_aura_env.child_envs = {}
        for dataIndex, childID in ipairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childID)
          if childData then
            if not environment_initialized[childID] then
              Private.ActivateAuraEnvironment(childID, nil, nil, nil, true)
              Private.ActivateAuraEnvironment()
            end
            current_aura_env.child_envs[dataIndex] = aura_environments[childID]
          end
        end
      else
        if environment_initialized[id] == 1 then
          -- Already done
        else
          current_aura_env.config = CopyTable(data.config)
        end
      end
      -- Finally, run the init function if supplied
      local actions = data.actions.init
      if(actions and actions.do_custom and actions.custom) then
        local func = Private.customActionsFunctions[id]["init"]
        if func then
          xpcall(func, Private.GetErrorHandlerId(id, "init"))
        end
      end
    end
  end
end

local function DebugPrint(...)
  Private.DebugLog.Print(current_uid, ...)
end

local function blocked(key)
  Private.AuraWarnings.UpdateWarning(current_uid, "SandboxForbidden", "error",
          string.format(L["Forbidden function or table: %s"], key))
end

local function MakeReadOnly(input, options)
  return setmetatable({},
  {
    __index = function(t, k)
       if options.blockedFunctions[k] then
         options.blocked(k)
         return function() end
       elseif options.blockedTables[k] then
         options.blocked(k)
         return {}
       elseif options.override[k] then
         return options.override[k]
       else
         return input[k]
       end
     end,
     __newindex = options.setBlocked,
     __metatable = false
  })
end

--- Wraps a table, so that accessing any key in it creates a deprecated warning
---@param input table
---@param name string
---@param warningMsg string
---@return table
local function MakeDeprecated(input, name, warningMsg)
  return setmetatable({},
  {
    __index = function(t, k)
      Private.AuraWarnings.UpdateWarning(current_uid, "Deprecated_" .. name, "warning", warningMsg)
      return input[k]
    end,
    __metatable = false
  })
end

local FakeWeakAurasMixin = {
  blockedFunctions = {
    -- Other addons might use these, so before moving them to the Private space, we need
    -- to discuss these. But Auras have no purpose for calling these
    Add = true,
    Delete = true,
    HideOptions = true,
    Rename = true,
    NewAura = true,
    Import = true,
    PreAdd = true,
    RegisterRegionOptions = true,
    RegisterSubRegionOptions = true,
    RegisterSubRegionType = true,
    RegisterRegionType = true,
    RegisterTriggerSystem = true,
    RegisterTriggerSystemOptions = true,
    ShowOptions = true,
    -- Note these shouldn't exist in the WeakAuras namespace, but moving them takes a bit of effort,
    -- so for now just block them and clean them up later
    createSpinner = true,
    ClearAndUpdateOptions = true,
    CreateTemplateView = true,
    FillOptions = true,
    GetMoverSizerId = true,
    GetNameAndIcon = true,
    GetTriggerCategoryFor = true,
    NewDisplayButton = true,
    OpenOptions = true,
    PickDisplay = true,
    setTile = true,
    SetMoverSizer = true,
    SetModel = true,
    Toggle = true,
    ToggleOptions = true,
    UpdateGroupOrders = true,
    UpdateThumbnail = true,
  },
  blockedTables = {
    ModelPaths = true,
    RealTimeProfilingWindow = true,
    -- Note these shouldn't exist in the WeakAuras namespace, but moving them takes a bit of effort,
    -- so for now just block them and clean them up later
    genericTriggerTypes = true,
    spellCache = true,
    StopMotion = true,
    -- We block the loaded table, even though it doesn't exist anymore,
    -- because some versions of ZT Tracker overwrote region:Collpase() and
    -- checked for WeakAuras.loaded in there
    loaded = true
  },
  override = {
    me = GetUnitName("player", true),
    myGUID = UnitGUID("player"),
    GetData = function(id)
      local currentId = Private.UIDtoID(current_uid)
      getDataCallCounts[currentId] = getDataCallCounts[currentId] + 1
      if getDataCallCounts[currentId] > 99 then
        Private.AuraWarnings.UpdateWarning(current_uid, "FakeWeakAurasGetData", "warning",
                  L["This aura calls GetData a lot, which is a slow function."])
      end
      local data = WeakAuras.GetData(id)
      return data and CopyTable(data) or nil
    end,
    clones = MakeDeprecated(Private.clones, "clones",
                L["Using WeakAuras.clones is deprecated. Use WeakAuras.GetRegion(id, cloneId) instead."]),
    regions = MakeDeprecated(Private.regions, "regions",
                L["Using WeakAuras.regions is deprecated. Use WeakAuras.GetRegion(id) instead."]),
    GetAllDBMTimers = function() return Private.ExecEnv.BossMods.DBM:GetAllTimers() end,
    GetDBMTimerById = function(...) return Private.ExecEnv.BossMods.DBM:GetTimerById(...) end,
    GetDBMTimer = function(...) return Private.ExecEnv.BossMods.DBM:GetTimer(...) end,
    GetBigWigsTimerById = function(...) return Private.ExecEnv.BossMods.BigWigs:GetTimerById(...) end,
    GetAllBigWigsTimers = function() return Private.ExecEnv.BossMods.BigWigs:GetAllTimers() end,
    GetBigWigsStage = function(...) return Private.ExecEnv.BossMods.BigWigs:GetStage(...) end,
    RegisterBigWigsTimer = function() Private.ExecEnv.BossMods.BigWigs:RegisterTimer() end,
    RegisterDBMCallback = function() Private.ExecEnv.BossMods.DBM:RegisterTimer() end,
    GetBossStage = function() return Private.ExecEnv.BossMods.Generic:GetStage() end
  },
  blocked = blocked,
  setBlocked = function()
    Private.AuraWarnings.UpdateWarning(current_uid, "FakeWeakAurasSet", "error",
                  L["Writing to the WeakAuras table is not allowed."], true)
  end
}

local FakeWeakAuras = MakeReadOnly(WeakAuras, FakeWeakAurasMixin)

local overridden = {
  WA_GetUnitAura = WA_GetUnitAura,
  WA_GetUnitBuff = WA_GetUnitBuff,
  WA_GetUnitDebuff = WA_GetUnitDebuff,
  WA_IterateGroupMembers = WA_IterateGroupMembers,
  WA_ClassColorName = WA_ClassColorName,
  WA_Utf8Sub = WA_Utf8Sub,
  ActionButton_ShowOverlayGlow = WeakAuras.ShowOverlayGlow,
  ActionButton_HideOverlayGlow = WeakAuras.HideOverlayGlow,
  WeakAuras = FakeWeakAuras
}

local env_getglobal_custom
-- WORKAROUND API which return Mixin'd values need those mixin "rawgettable" in caller's fenv #5071
local exec_env_custom = setmetatable({
  ColorMixin = ColorMixin,
  Vector2DMixin = Vector2DMixin,
  Vector3DMixin = Vector3DMixin,
  ItemLocationMixin = ItemLocationMixin,
  ItemTransmogInfoMixin = ItemTransmogInfoMixin,
  TransmogPendingInfoMixin = TransmogPendingInfoMixin,
  TransmogLocationMixin = TransmogLocationMixin,
  PlayerLocationMixin = PlayerLocationMixin,
},
{
  __index = function(t, k)
    if k == "_G" then
      return t
    elseif k == "getglobal" then
      return env_getglobal_custom
    elseif k == "aura_env" then
      return current_aura_env
    elseif k == "DebugPrint" then
      return DebugPrint
    elseif k == "C_Timer" then
      return current_aura_env and Private.AuraEnvironmentWrappedSystem.Get("C_Timer",
                                      current_aura_env.id, current_aura_env.cloneId)
                              or C_Timer
    elseif blockedFunctions[k] then
      blocked(k)
      return function(_) end
    elseif blockedTables[k] then
      blocked(k)
      return {}
    elseif overridden[k] then
      return overridden[k]
    elseif _G[k] then
      return _G[k]
    elseif k:find(".", 1, true) then
      local f
      for i, n in ipairs{strsplit(".", k)} do
        if i == 1 then
          f = _G[n]
        elseif f then
          f = f[n]
        else
          return
        end
      end
      return f
    end
  end,
  __newindex = function(table, key, value)
    if _G[key] then
      Private.AuraWarnings.UpdateWarning(current_uid, "OverridingGlobal", "warning",
         string.format(L["The aura has overwritten the global '%s', this might affect other auras."], key))
    end
    rawset(table, key, value)
  end,
  __metatable = false
})

function env_getglobal_custom(k)
  return exec_env_custom[k]
end

local PrivateForBuiltIn = {
  ExecEnv = Private.ExecEnv
}

local env_getglobal_builtin
local exec_env_builtin = setmetatable({},
{
  __index = function(t, k)
    if k == "_G" then
      return t
    elseif k == "getglobal" then
      return env_getglobal_builtin
    elseif k == "aura_env" then
      return current_aura_env
    elseif k == "DebugPrint" then
      return DebugPrint
    elseif k == "Private" then
      -- Built in code has access to Private.ExecEnv
      -- Which contains a bunch of internal helpers
      return PrivateForBuiltIn
    elseif blockedFunctions[k] then
      blocked(k)
      return function(_) end
    elseif blockedTables[k] then
      blocked(k)
      return {}
    elseif overridden[k] then
      return overridden[k]
    else
      return _G[k]
    end
  end,
  __newindex = function(table, key, value)
    if _G[key] then
      Private.AuraWarnings.UpdateWarning(current_uid, "OverridingGlobal", "warning",
         string.format(L["The aura has overwritten the global '%s', this might affect other auras."], key))
    end
    rawset(table, key, value)
  end,
  __metatable = false
})

function env_getglobal_builtin(k)
  return exec_env_builtin[k]
end

local function firstLine(string)
  local lineBreak = string:find('\n', 1, true)
  if lineBreak then
    return string:sub(1, lineBreak - 1)
  end
  return string
end

local function CreateFunctionCache(exec_env)
  local cache = {
    funcs = setmetatable({}, {__mode = "v"})
  }
  cache.Load = function(self, string, silent)
    if self.funcs[string] then
      return self.funcs[string]
    else
      local loadedFunction, errorString = loadstring(string, firstLine(string))
      if errorString then
        if not silent then
          print(errorString)
        end
        return nil, errorString
      elseif loadedFunction then
        --- @cast loadedFunction -nil
        setfenv(loadedFunction, exec_env)
        local success, func = pcall(assert(loadedFunction))
        if success then
          self.funcs[string] = func
          return func
        end
      end
    end
  end
  return cache
end

local function_cache_custom = CreateFunctionCache(exec_env_custom)
local function_cache_builtin = CreateFunctionCache(exec_env_builtin)

function WeakAuras.LoadFunction(string)
  return function_cache_custom:Load(string)
end

function Private.LoadFunction(string, silent)
  return function_cache_builtin:Load(string, silent)
end

function Private.GetSanitizedGlobal(key)
  return exec_env_custom[key]
end
