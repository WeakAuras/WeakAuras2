if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

---@alias key string | integer
---@alias states table<key, state>

---@type fun(state: state)
local function fixMissingFields(state)
  if type(state) ~= "table" then return end
  -- set show
  if state.show == nil then
    state.show = true
  end
end

---@type fun(states: states, key: key): boolean
local remove = function(states, key)
  local changed = false
  local state = states[key]
  if state then
    state.show = false
    state.changed = true
    changed = true
  end
  return changed
end

---@type fun(states: states): boolean
local removeAll = function(states)
  local changed = false
  for _, state in pairs(states) do
    state.show = false
    state.changed = true
    changed = true
  end
  return changed
end

---@type fun(states: states, newState: state, key: key): boolean
local update = function(states, newState, key)
  local changed = false
  local state = states[key]
  if state then
    fixMissingFields(newState)
    for k, v in pairs(newState) do
      if state[k] ~= v then
        state[k] = v
        changed = true
      end
    end
    if changed then
      state.changed = true
    end
  end
  return changed
end

---@type fun(states: states, newState: state, key: key): boolean
local create = function(states, newState, key)
  states[key] = newState
  states[key].changed = true
  fixMissingFields(states[key])
  return true
end

---@type fun(states: states, newState: state, key: key?): boolean
local createOrUpdate = function(states, newState, key)
  key = key or ""
  if states[key] then
    return update(states, newState, key)
  else
    return create(states, newState, key)
  end
end

Private.allstatesMetatable = {
  __index = {
    Update = createOrUpdate,
    Remove = remove,
    RemoveAll = removeAll
  }
}
