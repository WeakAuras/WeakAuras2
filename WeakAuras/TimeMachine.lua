---@type string, Private
local _, Private = ...


local TimeMachine = {
  ---@type change[]
  changes = {},
  ---@type table<actionType, Action>
  actions = {},
  ---@type table<actionType, Inverter>
  inverters = {},
  index = 0
}
Private.TimeMachine = TimeMachine

---@alias key string | number
---@alias keyPath key | (key)[]
---@alias Action<T> fun(data: table, path: keyPath, payload: T)
---@alias Inverter<T, S> fun(data: table, path: keyPath, payload?: T): actionType, keyPath, S?
---@alias actionType string
---@alias delta table<actionType, table<keyPath, any>>
---@class change
---@field forward table<uid, delta>
---@field backward table<uid, delta>

---@param data table
---@param path keyPath
---@return table, key
local function resolveKey(data, path)
  if type(path) ~= 'table' then
    return data, path
  end
  local tbl = data
  local i = 1
  while i < #path do
    tbl = tbl[path[i]]
    i = i + 1
  end
  return tbl, path[#path]
end

---@type Action<any>
function TimeMachine.actions.set(data, path, value)
  local tbl, key = resolveKey(data, path)
  tbl[key] = value
end

---@type Inverter<any, any>
function TimeMachine.inverters.set(data, path)
  local tbl, key = resolveKey(data, path)
  if tbl[key] == nil then
    return 'unset', path, nil
  else
    return 'set', path, tbl[key]
  end
end

---@type Action<nil> 'sugar' for set(nil), since tables can't have nil as a value
function TimeMachine.actions.unset(data, path)
  return TimeMachine.actions.set(data, path, nil)
end

---@type Inverter<nil, any>
function TimeMachine.inverters.unset(data, path)
  return TimeMachine.inverters.set(data, path)
end

---@type Action<{index: number, value: any}>
function TimeMachine.actions.insert(data, path, payload)
  local tbl, key = resolveKey(data, path)
  table.insert(tbl[key], payload.index, payload.value)
end

---@type Inverter<{index: number, value: any}, number>
function TimeMachine.inverters.insert(data, path, payload)
  return 'remove', path, payload.index
end

---@type Action<number>
function TimeMachine.actions.remove(data, path, payload)
  local tbl, key = resolveKey(data, path)
  table.remove(tbl[key], payload)
end

---@type Inverter<number, {index: number, value: any}>
function TimeMachine.inverters.remove(data, path, payload)
  local tbl, key = resolveKey(data, path)
  return 'insert', path, {index = payload, value = tbl[key][payload]}
end

---@type Action<{[1]: number, [2]: number}>
function TimeMachine.actions.swap(data, path, payload)
  local tbl, key = resolveKey(data, path)
  tbl[key][payload[1]], tbl[key][payload[2]] = tbl[key][payload[2]], tbl[key][payload[1]]
end

---@type Inverter<{[1]: number, [2]: number}, {[1]: number, [2]: number}>
function TimeMachine.inverters.swap(data, path, payload)
  return 'swap', path, {payload[2], payload[1]}
end

---@type Action<{[1]: number, [2]: number}>
function TimeMachine.actions.move(data, path, payload)
  local tbl, key = resolveKey(data, path)
  local value = table.remove(tbl, payload[1])
  table.insert(tbl[key], payload[2], value)
end

---@type Inverter<{[1]: number, [2]: number}, {[1]: number, [2]: number}>
function TimeMachine.inverters.move(data, path, payload)
  return 'move', path, {payload[2], payload[1]}
end

local function keyPathToString(path)
  if type(path) == 'table' then
    return table.concat(path, '.')
  else
    return path
  end
end

---@param forwardDeltas table<uid, delta>
function TimeMachine:Commit(forwardDeltas)
  ---@type change
  local change = {
    forward = forwardDeltas,
    backward = {}
  }
  for uid, delta in pairs(forwardDeltas) do
    change.backward[uid] = change.backward[uid] or {}
    for action, changes in pairs(delta) do
      if not self.actions[action] then
        error("Invalid action: " .. action)
      end
      for k, v in pairs(changes) do
        Private.DebugPrint('forward change is:', action, keyPathToString(k), v)
        local actionType, path, payload = self.inverters[action](Private.GetDataByUID(uid), k, v)
        Private.DebugPrint('backwards change is:', actionType, keyPathToString(path), payload)
        change.backward[uid][actionType] = change.backward[uid][actionType] or {}
        change.backward[uid][actionType][path] = payload
      end
    end
  end
  for i = self.index, #self.changes do
    self.changes[i] = nil
  end
  table.insert(self.changes, change)
  return self:StepForward()
end

---@param delta delta
---@param doAdds boolean
function TimeMachine:Apply(delta, doAdds)
  for uid, changes in pairs(delta) do
    local data = Private.GetDataByUID(uid)
    for action, changes in pairs(changes) do
      if not self.actions[action] then
        error("Invalid action: " .. action)
      end
      for k, v in pairs(changes) do
        self.actions[action](data, k, v)
      end
    end
    if doAdds then
      WeakAuras.Add(data)
    end
  end
end

function TimeMachine:StepForward()
  if self.index < #self.changes then
    self.index = self.index + 1
    self:Apply(self.changes[self.index].forward, true)
  end
end

function TimeMachine:StepBackward()
  if self.index > 0 then
    self:Apply(self.changes[self.index].backward, true)
    self.index = self.index - 1
  end
end

function TimeMachine:TravelTo(index)
  if index < 0 or index > #self.changes then
    error("Invalid index: " .. index)
  end
  local direction = index > self.index and "forward" or "backward"
  for i = self.index, index, direction == "forward" and 1 or -1 do
    self:Apply(self.changes[i][direction], i == index)
  end
  self.index = index
end


