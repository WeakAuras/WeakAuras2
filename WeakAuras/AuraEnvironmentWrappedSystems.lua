if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

--- @class AuraEnvironmentWrappedSystem
--- @field Get fun(systemName: string, id: auraId, cloneId: string?): any

--- @type AuraEnvironmentWrappedSystem
Private.AuraEnvironmentWrappedSystem = {}

--- @type table<auraId, table<string, table<string, any>>> Table of id, cloneId, systemName to wrapped system
local wrappers = {}

--- @type fun(_: any, uid: uid, id: auraId)
local function OnDelete(_, uid, id)
  wrappers[id] = nil
end

--- @type fun(_: any, uid: uid, oldId: auraId, newId: auraId)
local function OnRename(_, uid, oldId, newId)
  wrappers[newId] = wrappers[oldId]
  wrappers[oldId] = nil
end

Private.callbacks:RegisterCallback("Delete", OnDelete)
Private.callbacks:RegisterCallback("Rename", OnRename)

local WrapData = {
  C_Timer = {
    { name = "After", arg = 2},
    { name = "NewTimer", arg = 2},
    { name = "NewTicker", arg = 2}
  }
}

--- @type fun(id: auraId, cloneId: string, system: any, funcs: {name: string, arg: number}[])
local function Wrap(id, cloneId, system, funcs)
  local wrappedSystem = {}
  for _, data in ipairs(funcs) do
    wrappedSystem[data.name] = function(...)
      local packed = SafePack(...)
      local oldArg = select(data.arg, ...)
      if type(oldArg) == "function" then
        packed[data.arg] = function(...)
          local region = WeakAuras.GetRegion(id, cloneId)
          if region then
            Private.ActivateAuraEnvironmentForRegion(region)
            oldArg(...)
            Private.ActivateAuraEnvironment()
          else
            oldArg(...)
          end
        end
      end
      return system[data.name](SafeUnpack(packed))
    end
  end
  setmetatable(wrappedSystem, { __index = system, __metatable = false })
  return wrappedSystem
end

Private.AuraEnvironmentWrappedSystem.Get = function(systemName, id, cloneId)
  local cloneIdKey = cloneId or ""
  wrappers[id] = wrappers[id] or {}
  wrappers[id][cloneIdKey] = wrappers[id][cloneIdKey] or {}
  wrappers[id][cloneIdKey][systemName] = wrappers[id][cloneIdKey][systemName]
    or Wrap(id, cloneId, _G[systemName], WrapData[systemName])
  return wrappers[id][cloneIdKey][systemName]
end

