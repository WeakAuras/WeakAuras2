if not WeakAuras.IsCorrectVersion() then return end

local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint

local LCD
if WeakAuras.IsClassic() then
  LCD = LibStub("LibClassicDurations")
  LCD:RegisterFrame("WeakAuras")
end

local UnitAura = UnitAura
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

if WeakAuras.IsClassic() then
  local WA_GetUnitAuraBase = WA_GetUnitAura
  WA_GetUnitAura = function(unit, spell, filter)
    local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = WA_GetUnitAuraBase(unit, spell, filter)
    if spellId then
      local durationNew, expirationTimeNew = LCD:GetAuraDurationByUnit(unit, spellId, source, name)
      if duration == 0 and durationNew then
          duration = durationNew
          expirationTime = expirationTimeNew
      end
    end
    return name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod
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
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    if not class then
      return name
    else
      local classData = RAID_CLASS_COLORS[class]
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
  if not input then
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

local helperFunctions = {
  WA_GetUnitAura = WA_GetUnitAura,
  WA_GetUnitBuff = WA_GetUnitBuff,
  WA_GetUnitDebuff = WA_GetUnitDebuff,
  WA_IterateGroupMembers = WA_IterateGroupMembers,
  WA_ClassColorName = WA_ClassColorName,
  WA_Utf8Sub = WA_Utf8Sub,
}

local LCG = LibStub("LibCustomGlow-1.0")
WeakAuras.ShowOverlayGlow = LCG.ButtonGlow_Start
WeakAuras.HideOverlayGlow = LCG.ButtonGlow_Stop

local LGF = LibStub("LibGetFrame-1.0")
WeakAuras.GetUnitFrame = LGF.GetUnitFrame
WeakAuras.GetUnitNameplate =  function(unit)
  if WeakAuras.multiUnitUnits.nameplate[unit] then
    return LGF.GetUnitNameplate(unit)
  end
end

local function forbidden()
  prettyPrint(L["A WeakAura just tried to use a forbidden function but has been blocked from doing so. Please check your auras!"])
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
  SlashCmdList = true,
  DevTools_DumpCommand = true,
  hash_SlashCmdList = true,
  CreateMacro = true,
  SetBindingMacro = true,
  GuildDisband = true,
  GuildUninvite = true,
  securecall = true,
}

local overrideFunctions = {
  ActionButton_ShowOverlayGlow = WeakAuras.ShowOverlayGlow,
  ActionButton_HideOverlayGlow = WeakAuras.HideOverlayGlow,
}

local aura_environments = {}
-- nil == Not initiliazed
-- 1 == config initialized
-- 2 == fully initialized
local environment_initialized = {}

function WeakAuras.IsEnvironmentInitialized(id)
  return environment_initialized[id] == 2
end

function WeakAuras.DeleteAuraEnvironment(id)
  aura_environments[id] = nil
  environment_initialized[id] = nil
end

function WeakAuras.RenameAuraEnvironment(oldid, newid)
  aura_environments[oldid], aura_environments[newid] = nil, aura_environments[oldid]
  environment_initialized[oldid], environment_initialized[newid] = nil, environment_initialized[oldid]
end

local current_aura_env = nil
local aura_env_stack = {} -- Stack of of aura environments, allows use of recursive aura activations through calls to WeakAuras.ScanEvents().

function WeakAuras.ClearAuraEnvironment(id)
  environment_initialized[id] = nil;
end

function WeakAuras.ActivateAuraEnvironment(id, cloneId, state, states, onlyConfig)
  local data = WeakAuras.GetData(id)
  local region = WeakAuras.GetRegion(id, cloneId)
  if not data then
    -- Pop the last aura_env from the stack, and update current_aura_env appropriately.
    tremove(aura_env_stack)
    current_aura_env = aura_env_stack[#aura_env_stack] or nil
  else
    -- Existing config is initialized to a high enough value
    if environment_initialized[id] == 2 or (onlyConfig and environment_initialized[id] == 1) then
      -- Point the current environment to the correct table
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      current_aura_env.region = region
      -- Push the new environment onto the stack
      tinsert(aura_env_stack, current_aura_env)
    elseif onlyConfig then
      environment_initialized[id] = 1
      aura_environments[id] = {}
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      current_aura_env.region = region
      tinsert(aura_env_stack, current_aura_env)

      if not data.controlledChildren then
        current_aura_env.config = CopyTable(data.config)
      end
    else
      -- Either this aura environment has not yet been initialized, or it was reset via an edit in WeakaurasOptions
      environment_initialized[id] = 2
      aura_environments[id] = aura_environments[id] or {}
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      current_aura_env.region = region
      -- push new environment onto the stack
      tinsert(aura_env_stack, current_aura_env)

      if data.controlledChildren then
        current_aura_env.child_envs = {}
        for dataIndex, childID in ipairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childID)
          if childData then
            if not environment_initialized[childID] then
              WeakAuras.ActivateAuraEnvironment(childID)
              WeakAuras.ActivateAuraEnvironment()
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
        local func = WeakAuras.customActionsFunctions[id]["init"]
        if func then
          xpcall(func, geterrorhandler())
        end
      end
    end
  end
end

local env_getglobal
local exec_env = setmetatable({}, { __index =
  function(t, k)
    if k == "_G" then
      return t
    elseif k == "getglobal" then
      return env_getglobal
    elseif k == "aura_env" then
      return current_aura_env
    elseif blockedFunctions[k] then
      return forbidden
    elseif overrideFunctions[k] then
      return overrideFunctions[k]
    elseif helperFunctions[k] then
      return helperFunctions[k]
    else
      return _G[k]
    end
  end
})

function env_getglobal(k)
  return exec_env[k]
end

local function_cache = {}
function WeakAuras.LoadFunction(string, id, inTrigger)
  if function_cache[string] then
    return function_cache[string]
  else
    local loadedFunction, errorString = loadstring("--[==[ Error in '" .. (id or "Unknown") .. (inTrigger and ("':'".. inTrigger) or "") .."' ]==] " .. string)
    if errorString then
      print(errorString)
    else
      setfenv(loadedFunction, exec_env)
      local success, func = pcall(assert(loadedFunction))
      if success then
        function_cache[string] = func
        return func
      end
    end
  end
end

function WeakAuras.GetSanitizedGlobal(key)
  return exec_env[key]
end
