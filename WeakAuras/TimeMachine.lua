---@type string, Private
local _, Private = ...

---@class TimeMachine
local TimeMachine = {
  ---@type change
  next = {
    forward = {},
    backward = {}
  },
  transaction = false,
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
---@class actionRecord
---@field uid uid
---@field actionType actionType
---@field path keyPath
---@field payload any

---@class change
---@field forward actionRecord[]
---@field backward actionRecord[]

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

local function copy(tbl, key)
  if type(tbl[key]) == "table" then
    return CopyTable(tbl[key])
  else
    return tbl[key]
  end
end

---@type Action<any>
function TimeMachine.actions.set(data, path, value)
  local tbl, key = resolveKey(data, path)
  tbl[key] = value
end

---@type Inverter<any, any>
function TimeMachine.inverters.set(data, path)
  local tbl, key = resolveKey(data, path)
  return 'set', path, copy(tbl, key)
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
  return 'insert', path, {index = payload, value = copy(tbl[key], payload)}
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

---@param path keyPath
local function keyPathToString(path)
  if type(path) == 'table' then
    return table.concat(path, '.')
  else
    return path
  end
end

function TimeMachine:StartTransaction()
  self:Reject()
  self.transaction = true
end

---@param record actionRecord
function TimeMachine:Append(record)
  local action = self.actions[record.actionType]
  Private.DebugPrint("Forward action", record.actionType, "for", record.uid, "at", keyPathToString(record.path), "with", record.payload)
  if not action then
    error("No action for actionType: " .. record.actionType)
  end
  local inverter = self.inverters[record.actionType]
  if not inverter then
    error("No inverter for action: " .. record.actionType)
  end
  local actionType, path, payload = inverter(Private.GetDataByUID(record.uid), record.path, record.payload)
  local inverseRecord = {
    uid = record.uid,
    actionType = actionType,
    path = path,
    payload = payload
  }
  Private.DebugPrint("Backward action", actionType, "for", record.uid, "at", keyPathToString(path), "with", payload)
  table.insert(self.next.forward, record)
  table.insert(self.next.backward, inverseRecord)
  if not self.transaction then
    self:Commit()
  end
end

---@param records actionRecord[]
function TimeMachine:AppendMany(records)
  local commit = false
  if not self.transaction then
    self:StartTransaction()
    commit = true
  end
  for _, record in ipairs(records) do
    self:Append(record)
  end
  if commit then
    self:Commit()
  end
end

function TimeMachine:Reject()
  self.next = {
    forward = {},
    backward = {}
  }
end

function TimeMachine:Commit()
  while self.index < #self.changes do
    table.remove(self.changes)
  end
  table.insert(self.changes, self.next)
  self.next = {
    forward = {},
    backward = {}
  }
  self.transaction = false
  return self:StepForward()
end

---@param records actionRecord[]
---@param doAdds boolean
function TimeMachine:Apply(records, doAdds)
  local changedData = {}
  for _, record in ipairs(records) do
    local action = self.actions[record.actionType]
    if not action then
      error("No action for actionType: " .. record.actionType)
    end
    local data = Private.GetDataByUID(record.uid)
    action(data, record.path, record.payload)
    changedData[record.uid] = true
  end
  if doAdds then
    for uid in pairs(changedData) do
      local data = Private.GetDataByUID(uid)
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
