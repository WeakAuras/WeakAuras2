local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint

local UnitAura = UnitAura
-- Unit Aura functions that return info about the first Aura matching the spellName or spellID given on the unit.
local WA_GetUnitAura = function(unit, spell, filter)
  for i = 1, 255 do
    local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
    if not name then return end
    if spell == spellId or spell == name then
      return UnitAura(unit, i, filter)
    end
  end
end

local WA_GetUnitBuff = function(unit, spell, filter)
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
  local _, class = UnitClass(unit)
  if not class then return end
  return RAID_CLASS_COLORS[class]:WrapTextInColorCode(UnitName(unit))
end

local helperFunctions = {
  WA_GetUnitAura = WA_GetUnitAura,
  WA_GetUnitBuff = WA_GetUnitBuff,
  WA_GetUnitDebuff = WA_GetUnitDebuff,
  WA_IterateGroupMembers = WA_IterateGroupMembers,
  WA_ClassColorName = WA_ClassColorName,
}

local LCG = LibStub("LibCustomGlow-1.0")
WeakAuras.ShowOverlayGlow = LCG.ButtonGlow_Start
WeakAuras.HideOverlayGlow = LCG.ButtonGlow_Stop

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
local environment_initialized = {}

function WeakAuras.IsEnvironmentInitialized(id)
  return environment_initialized[id]
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
  environment_initialized[id] = false;
end

function WeakAuras.ActivateAuraEnvironment(id, cloneId, state)
  local data = WeakAuras.GetData(id)
  if not data then
    -- Pop the last aura_env from the stack, and update current_aura_env appropriately.
    tremove(aura_env_stack)
    current_aura_env = aura_env_stack[#aura_env_stack] or nil
  else
    if environment_initialized[id] then
      -- Point the current environment to the correct table
      current_aura_env = aura_environments[id]
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.region = WeakAuras.GetRegion(id, cloneId)
      -- Push the new environment onto the stack
      tinsert(aura_env_stack, current_aura_env)
    else
      -- Reset the environment if we haven't completed init, i.e. if we add/update/replace a WeakAura
      environment_initialized[id] = true
      aura_environments[id] = {}
      current_aura_env = aura_environments[id]
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.region = WeakAuras.GetRegion(id, cloneId)
      current_aura_env.config = CopyTable(data.config)
      -- Push the new environment onto the stack
      tinsert(aura_env_stack, current_aura_env)
      -- Run the init function if supplied
      local actions = data.actions.init
      if(actions and actions.do_custom and actions.custom) then
        local func = WeakAuras.customActionsFunctions[id]["init"]
        if func then
          current_aura_env.id = id
          xpcall(func, geterrorhandler())
        end
      end
    end
    current_aura_env.id = id
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
    local loadedFunction, errorString = loadstring("--[[ Error in '" .. (id or "Unknown") .. (inTrigger and ("':'".. inTrigger) or "") .."' ]] " .. string)
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
