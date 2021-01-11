if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

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
  CreateMacro = true,
  SetBindingMacro = true,
  GuildDisband = true,
  GuildUninvite = true,
  securecall = true,
}

local blockedTables = {
  SlashCmdList = true,
  SendMailMailButton = true,
  SendMailMoneyGold = true,
  MailFrameTab2 = true,
}



local regionsProxyCache = {}


local aura_environments = {}
-- nil == Not initiliazed
-- 1 == config initialized
-- 2 == fully initialized
local environment_initialized = {}

function Private.IsEnvironmentInitialized(id)
  return environment_initialized[id] == 2
end

function Private.DeleteAuraEnvironment(id)
  aura_environments[id] = nil
  environment_initialized[id] = nil

  Private.RemoveFunctionCache(id)
end

function Private.RenameAuraEnvironment(oldid, newid)
  aura_environments[oldid], aura_environments[newid] = nil, aura_environments[oldid]
  environment_initialized[oldid], environment_initialized[newid] = nil, environment_initialized[oldid]

  Private.RemoveFunctionCache(oldid)
  Private.RemoveFunctionCache(newid)
end

local current_uid = nil
local current_aura_env = nil
-- Stack of of aura environments/uids, allows use of recursive aura activations through calls to WeakAuras.ScanEvents().
local aura_env_stack = {}

function Private.ClearAuraEnvironment(id)
  environment_initialized[id] = nil;
end

function Private.ActivateAuraEnvironmentForRegion(region, onlyConfig)
  Private.ActivateAuraEnvironment(region.id, region.cloneId, region.state, region.states, onlyConfig)
end

function Private.ActivateAuraEnvironment(id, cloneId, state, states, onlyConfig)
  local data = WeakAuras.GetData(id)
  local region = WeakAuras.GetRegion(id, cloneId)
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
      -- Point the current environment to the correct table
      current_uid = data.uid
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      current_aura_env.region = region and Private.GetFrameHandle(region) or region
      -- Push the new environment onto the stack
      tinsert(aura_env_stack, {current_aura_env, data.uid})
    elseif onlyConfig then
      environment_initialized[id] = 1
      aura_environments[id] = {}
      current_uid = data.uid
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      current_aura_env.region = region and Private.GetFrameHandle(region) or region
      tinsert(aura_env_stack, {current_aura_env, data.uid})

      if not data.controlledChildren then
        current_aura_env.config = CopyTable(data.config)
      end
    else
      -- Either this aura environment has not yet been initialized, or it was reset via an edit in WeakaurasOptions
      environment_initialized[id] = 2
      aura_environments[id] = aura_environments[id] or {}
      current_uid = data.uid
      current_aura_env = aura_environments[id]
      current_aura_env.id = id
      current_aura_env.cloneId = cloneId
      current_aura_env.state = state
      current_aura_env.states = states
      current_aura_env.region = region and Private.GetFrameHandle(region) or region
      -- push new environment onto the stack
      tinsert(aura_env_stack, {current_aura_env, data.uid})

      if data.controlledChildren then
        current_aura_env.child_envs = {}
        for dataIndex, childID in ipairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childID)
          if childData then
            if not environment_initialized[childID] then
              Private.ActivateAuraEnvironment(childID)
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
          xpcall(func, geterrorhandler())
        end
      end
    end
  end
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

local FakeWeakAurasMixin = {
  blockedFunctions = {
    -- Other addons might use these, so before moving them to the Private space, we need
    -- to discuss these. But Auras have no purpose for calling these
    Add = true,
    AddMany = true,
    AddManyFromAddons = true,
    Delete = true,
    HideOptions = true,
    Rename = true,
    NewAura = true,
    OptionsFrame = true,
    RegisterAddon = true,
    RegisterDisplay = true,
    RegisterRegionOptions = true,
    RegisterSubRegionOptions = true,
    RegisterSubRegionType = true,
    RegisterRegionType = true,
    RegisterTriggerSystem = true,
    RegisterTriggerSystemOptions = true,
    ShowOptions = true,
    -- Note these shouldn't exist in the WeakAuras namespace, but moving them takes a bit of effort,
    -- so for now just block them and clean them up later
    CollisionResolved = true,
    ClearAndUpdateOptions = true,
    CloseCodeReview = true,
    CloseImportExport = true,
    CreateTemplateView = true,
    DisplayToString = true,
    FillOptions = true,
    FindUnusedId = true,
    GetMoverSizerId = true,
    GetDisplayButton = true,
    Import = true,
    NewDisplayButton = true,
    NewAura = true,
    OpenTriggerTemplate = true,
    OpenCodeReview = true,
    PickDisplay = true,
    SetMoverSizer = true,
    SetImporting = true,
    SortDisplayButtons = true,
    ShowOptions = true,
    ToggleOptions = true,
    UpdateDisplayButton = true,
    UpdateGroupOrders = true,
    UpdateThumbnail = true,
    validate = true,
    getDefaultGlow = true,
  },
  blockedTables = {
    AuraWarnings = true,
    ModelPaths = true,
    regionPrototype = true,
    -- Note these shouldn't exist in the WeakAuras namespace, but moving them takes a bit of effort,
    -- so for now just block them and clean them up later
    data_stub = true,
    displayButtons = true,
    regionTypes = true,
    regionOptions = true,
    spellCache = true,
    triggerTemplates = true,
    frames = true,
    loadFrame = true,
    unitLoadFrame = true,
    importDisplayButtons = true,
    loaded = true

  },
  override = {
    me = GetUnitName("player", true),
    myGUID = UnitGUID("player"),
    regions = setmetatable({},{
      __index = function(t,k)
        if (WeakAuras.regions[k]) then
          if not regionsProxyCache[WeakAuras.regions[k]] then
            regionsProxyCache[WeakAuras.regions[k]] = setmetatable({}, {
              __index = function(tbl, key)
                if key == 'region' then
                  if ( WeakAuras.regions[k].region ) then
                    return Private.GetFrameHandle(WeakAuras.regions[k].region)
                  end
                  return nil
                else
                  return WeakAuras.regions[k][key]
                end
              end,
              __newindex = function()end,
              __metatable = false,
            })
          end
          return regionsProxyCache[WeakAuras.regions[k]]
        end
        return nil
      end,
      __newindex = function()end,
      __metatable = false
    }),
    GetRegion = function(id, cloneId)
      local region = WeakAuras.GetRegion(id, cloneId)
      if ( region ) then
        return Private.GetFrameHandle(region)
      end
      return nil
    end
  },
  blocked = blocked,
  setBlocked = function()
    Private.AuraWarnings.UpdateWarning(current_uid, "FakeWeakAurasSet", "error",
                  L["Writing to the WeakAuras table is not allowed."], true)
  end
}

local FakeWeakAuras = MakeReadOnly(WeakAuras, FakeWeakAurasMixin)

local FakeCreateFrame = function(frameType, name, parent, ...)

  if type(frameType) ~= 'string' then error('Usage: CreateFrame("frameType" [, "name"] [, parent] [, "template"] [, id])') end

  local CreateFramePayload = { ... }

  if ( parent ) then
    if ( type(parent) == 'userdata' ) then
      parent = Private.GetFrameHandleFrame(parent)
    else
      error('Error: CreateFrame - Unknown parent')
    end
  end

  local frame = CreateFrame(frameType, name, parent, ...);
  return Private.GetFrameHandle(frame)
end

local overridden
local Fakehooksecurefunc = function(...)
  local numArgs = select('#', ...)
  local _table, _funcName, _hook

  if numArgs == 3 then
    _table, _funcName, _hook = ...
  else
    _funcName, _hook = ...
  end

  if (blockedFunctions[_funcName]) then
    error('Attept to use forbidden value ', _funcName)
  end

  if ( _table ) then
    if ( type(_table) == 'userdata' ) then
      local frame = Private.GetFrameHandleFrame(_table)

      if ( not _table[_funcName] ) then
        error('Unknown funcName "'.._funcName..'"')
      end

      hooksecurefunc(frame, _funcName, function(self, ...)
        local handle = Private.GetFrameHandle(self)
        _hook(handle, ...)
      end)
    else
      hooksecurefunc(_table, _funcName, function(self, ...)
        _hook(self, ...)
      end)
    end
  else
    hooksecurefunc(_funcName, function(self, ...)
      _hook(self, ...)
    end)
  end
end

overridden = {
  WA_GetUnitAura = WA_GetUnitAura,
  WA_GetUnitBuff = WA_GetUnitBuff,
  WA_GetUnitDebuff = WA_GetUnitDebuff,
  WA_IterateGroupMembers = WA_IterateGroupMembers,
  WA_ClassColorName = WA_ClassColorName,
  WA_Utf8Sub = WA_Utf8Sub,
  ActionButton_ShowOverlayGlow = WeakAuras.ShowOverlayGlow,
  ActionButton_HideOverlayGlow = WeakAuras.HideOverlayGlow,
  WeakAuras = FakeWeakAuras,
  CreateFrame = FakeCreateFrame,
  hooksecurefunc = Fakehooksecurefunc, -- is it realy needed?
}


local env_getglobal
local proxifier
do
  local pairs, ipairs, next, unpack = pairs, ipairs, next, unpack
  local pcall = pcall

  local proxifierCache = {}

  local ignoreProxy = {
    [ipairs] = true,
    [pairs] = true,
    [next] = true,
    [unpack] = true,
  }

  local function MakeTableReference(from)
    local t = {}

    for k,v in pairs(from) do
      if ( _G[k]) then
        t[ _G[k] ] = k
      else
        print('Unable to find reference for', k)
      end
    end

    return t
  end

  local blockedFunctionsReference = MakeTableReference(blockedFunctions)
  local blockedTablesReference = MakeTableReference(blockedTables)

  local doOutput = false
  local output = function(...)
    if doOutput then print(...) end
  end

  local function nextArgs(arg, ...)
    local numPayload = select('#', ...)
    if numPayload == 0 and not arg then return end
    return proxifier(arg), nextArgs(...)
  end

  local function captureReturn(success, result, ...)
    if not success then
      error(result)
    end

    return proxifier(result), nextArgs(...)
  end

  local function proxifier_proxy_table(var)
    if not proxifierCache[var] then
      proxifierCache[var] = setmetatable({}, {
        __index = function(t, k)
          return proxifier(var[k])
        end,
        __call = function(t, ...) -- this for LibStud() __call
          return captureReturn(pcall(var, ...))
        end,
      })
    end

    return proxifierCache[var]
  end

  local function proxifier_proxy_function(var)
    if not proxifierCache[var] then
      proxifierCache[var] = function(t, ...)
        return captureReturn(pcall(var, t, ...))
      end
    end
    return proxifierCache[var]
  end

  function proxifier(var)
    if ( not var ) then
      return;
    end

    if ( type(var) == 'table' ) then
      if ( var == WeakAuras ) then
        return FakeWeakAuras
      elseif ( var == _G ) then
        return env_getglobal('_G')
      elseif ( blockedTablesReference[var] ) then
        blocked( blockedTablesReference[var] )
        return {}
      end

      if ( type(var[0]) == 'userdata' ) then
        return Private.GetFrameHandle(var)
      else
        return proxifier_proxy_table(var)
      end
    elseif ( type(var) == 'function' ) then

      if ( blockedFunctionsReference[var] ) then
        blocked( blockedFunctionsReference[var] )
        return function() end
      elseif ( ignoreProxy[var] ) then -- ipairs, pairs doesnt work without it
        return var
      end

      return proxifier_proxy_function(var)
    else
      return var
    end
  end
end

local exec_env = setmetatable({},
{
  __index = function(t, k)
    if k == "_G" then
      return t
    elseif k == "getglobal" then
      return env_getglobal
    elseif blockedFunctions[k] then
      blocked(k)
      return function() end
    elseif blockedTables[k] then
      blocked(k)
      return {}
    elseif overridden[k] then
      return overridden[k]
    else
      return proxifier(_G[k])
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

function env_getglobal(k)
  return exec_env[k]
end

local function_env_cache = {}

local function env_createnew(id)
  if ( function_env_cache[id] ) then
    return function_env_cache[id]
  end

  local __LoadFunction = function(code)
    return WeakAuras.LoadFunction(code, id)
  end

  function_env_cache[id] = setmetatable({},{
    __index = function(t, k)
      if k == "aura_env" then
        return aura_environments[id]
      elseif k == 'WeakAuras' then
        return setmetatable({}, {
          __index = function(t1, k1)
            if ( k1 == 'LoadFunction' ) then
              return __LoadFunction
            else
              return exec_env[k][k1]
            end
          end
        })
      else
        return exec_env[k]
      end
    end,
    __metatable = false
  })

  return function_env_cache[id]
end

local function_cache = {}
function WeakAuras.LoadFunction(string, id, inTrigger)

  if not id then
    error('Unable to find id in WeakAuras.LoadFunction')
  end

  if function_cache[id] and function_cache[id][string] then
    return function_cache[id][string]
  else
    local loadedFunction, errorString = loadstring("--[==[ Error in '" .. (id or "Unknown") .. (inTrigger and ("':'".. inTrigger) or "") .."' ]==] " .. string)
    if errorString then
      print(errorString)
    else
      setfenv(loadedFunction, env_createnew(id))
      local success, func = pcall(assert(loadedFunction))
      if success then
        if not function_cache[id] then
          function_cache[id] = {}
        end
        function_cache[id][string] = func
        return func
      end
    end
  end
end

function Private.RemoveFunctionCache(id)
  function_cache[id] = nil
  function_env_cache[id] = nil
end

function Private.GetSanitizedGlobal(key)
  return exec_env[key]
end
