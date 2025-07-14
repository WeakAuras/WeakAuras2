---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

Private.Features:Register({
  id = "undo",
  autoEnable = {"dev", "pr", "alpha"},
  enabled = true,
  persist = true,
})

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
  ---@type table<string, {idempotent: boolean, func: function}>
  effects = {},
  index = 0,
  sub = Private.CreateSubscribableObject(),
}

Private.TimeMachine = TimeMachine

---@alias keyPath key | (key)[]
---@alias Actor fun(data: table, path: keyPath, payload: any)
---@alias Inverter fun(data: table, path: keyPath, payload?: any): actionType, keyPath, any
---@alias actionType string
---@alias effectType string

---@class Action
---@field actor Actor
---@field inverter Inverter
---@field autoEffects? effectType[]

---@class actionRecord
---@field uid uid
---@field actionType actionType
---@field path keyPath
---@field payload any
---@field effects? effectType[]
---@field suppressAutoEffects? table<effectType, boolean>

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
    if tbl[path[i]] == nil then
      tbl[path[i]] = {}
    elseif type(tbl[path[i]]) ~= 'table' then
      error("Path is not valid: " .. table.concat(path, '.') .. " at " .. path[i])
    end
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

---@type fun(self: self, tag: effectType, func: fun(uid:uid, data: auraData), idempotent?: boolean)
function TimeMachine:RegisterEffect(tag, func, idempotent)
  if self.effects[tag] then
    error("Effect already registered: " .. tag)
  end
  self.effects[tag] = {
    idempotent = idempotent,
    func = func
  }
end

TimeMachine:RegisterEffect("add", function(uid, data)
  Private.Add(data)
end, true)

TimeMachine:RegisterEffect("options_cu", function(uid, data)
  if WeakAuras.IsOptionsOpen() then
    WeakAuras.ClearAndUpdateOptions(data.id, true)
  end
end, true)

---@type fun(self: self, actionType: actionType, action: Actor<any>, inverter: Inverter<any, any>, autoEffects?: effectType[])
function TimeMachine:RegisterAction(actionType, actor, inverter, autoEffects)
  if self.actions[actionType] then
    error("Action already registered: " .. actionType)
  end
  self.actions[actionType] = {
    actor = actor,
    inverter = inverter,
    autoEffects = autoEffects,
  }
end
TimeMachine:RegisterAction("none",
  function(_data, _path)
  end,
  function(_data, path)
    return 'none', path, nil
  end
)

TimeMachine:RegisterAction("set",
  function(data, path, value)
    local tbl, key = resolveKey(data, path)
    tbl[key] = value
  end,
  function(data, path)
    local tbl, key = resolveKey(data, path)
    return 'set', path, copy(tbl, key)
  end,
  {"add", "options_cu"}
)

TimeMachine:RegisterAction("setmany",
  function(data, path, values)
    local tbl, key = resolveKey(data, path)
    for k, v in pairs(values) do
      tbl[key][k] = v
    end
  end,
  function(data, path, values)
    local tbl, key = resolveKey(data, path)
    local inverse = {}
    for k, v in pairs(values) do
      inverse[k] = copy(tbl[key], k)
    end
    return 'setmany', path, inverse
  end,
  {"add", "options_cu"}
)

TimeMachine:RegisterAction("insert",
  function(data, path, payload)
    local tbl, key = resolveKey(data, path)
    if payload.index == nil then
      table.insert(tbl[key], payload.value)
    else
      table.insert(tbl[key], payload.index, payload.value)
    end
  end,
  function(data, path, payload)
    return 'remove', path, payload.index
  end,
  {"add", "options_cu"}
)

TimeMachine:RegisterAction("remove",
  function(data, path, payload)
    local tbl, key = resolveKey(data, path)
    if payload == nil then
      table.remove(tbl[key])
    else
      table.remove(tbl[key], payload)
    end
  end,
  function(data, path, payload)
    local tbl, key = resolveKey(data, path)
    return 'insert', path, {index = payload, value = copy(tbl[key], payload or #tbl[key])}
  end,
  {"add", "options_cu"}
)

TimeMachine:RegisterAction("swap",
  function(data, path, payload)
    local tbl, key = resolveKey(data, path)
    tbl[key][payload[1]], tbl[key][payload[2]] = tbl[key][payload[2]], tbl[key][payload[1]]
  end,
  function(data, path, payload)
    return 'swap', path, {payload[2], payload[1]}
  end,
  {"add", "options_cu"}
)

TimeMachine:RegisterAction("move",
  function(data, path, payload)
    local tbl, key = resolveKey(data, path)
    local value = table.remove(tbl, payload[1])
    table.insert(tbl[key], payload[2], value)
  end,
  function(data, path, payload)
    return 'move', path, {payload[2], payload[1]}
  end,
  {"add", "options_cu"}
)

---@param path keyPath
local function keyPathToString(path)
  if type(path) == 'table' then
    return table.concat(path, '.')
  else
    return path
  end
end

---@param effects effectType[]
local function invertEffects(effects)
  local inverted = {}
  for i = #effects, 1, -1 do
    table.insert(inverted, effects[i])
  end
  return inverted
end

function TimeMachine:StartTransaction()
  if self.transaction then
    WeakAuras.prettyPrint("If you're reading this, a time machine transaction was started, but there was already one in  progress. That's not supposed to happen. Please report this to the WeakAuras developers, thanks!")
    self:Reject()
  end
  self.transaction = true
end

---@param record actionRecord
function TimeMachine:Append(record)
  local action = self.actions[record.actionType]
  Private.DebugPrint("Forward action", record.actionType, "for", record.uid, "at", keyPathToString(record.path), "with", record.payload)
  if not action then
    error("No action for actionType: " .. record.actionType)
  end
  local inverter = action.inverter
  if not inverter then
    error("No inverter for action: " .. record.actionType)
  end
  local actionType, path, payload = inverter(Private.GetDataByUID(record.uid), record.path, record.payload)
  ---@type actionRecord
  local inverseRecord = {
    uid = record.uid,
    actionType = actionType,
    path = path,
    payload = payload,
    suppressAutoEffects = record.suppressAutoEffects and CopyTable(record.suppressAutoEffects) or nil,
    effects = record.effects and invertEffects(record.effects) or nil,
  }
  Private.DebugPrint("Backward action", actionType, "for", record.uid, "at", keyPathToString(path), "with", payload)
  table.insert(self.next.forward, record)
  table.insert(self.next.backward, 1, inverseRecord)
  if not self.transaction then
    self:Commit(true)
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
  self.transaction = false
end

---@param instant? boolean
function TimeMachine:Commit(instant)
  if not self.transaction and not instant then
    WeakAuras.prettyPrint("If you're reading this, a time machine transaction was committed, but there was no transaction in progress. That's not supposed to happen. Please report this to the WeakAuras developers, thanks!")
    return
  end
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
---@param delayedEffects? table<uid, table<effectType, boolean>>
---@return {uid: uid, effect: effectType}[]?
function TimeMachine:Apply(records, delayedEffects)
  for _, record in ipairs(records) do
    local action = self.actions[record.actionType]
    if not action then
      error("No action for actionType: " .. record.actionType)
    end
    local data = Private.GetDataByUID(record.uid)
    action.actor(data, record.path, record.payload)
    if action.autoEffects or record.effects then
      ---@type effectType[]
      local effects = {}
      if action.autoEffects then
        for _, effect in ipairs(action.autoEffects) do
          if not record.suppressAutoEffects or not record.suppressAutoEffects[effect] then
            table.insert(effects, effect)
          end
        end
      end
      if record.effects then
        for _, effect in ipairs(record.effects) do
          table.insert(effects, effect)
        end
      end
      for _, effectType in ipairs(effects) do
        local effect = self.effects[effectType]
        if not effect then
          error("No effect for effectType: " .. effect)
        end
        if not delayedEffects or not effect.idempotent then
          if not record.effects or record.suppressAutoEffects then
            effect.func(record.uid, data)
          end
        else
          delayedEffects[record.uid] = delayedEffects[record.uid] or {}
          delayedEffects[record.uid][effectType] = true
        end
      end
    end
  end
  return delayedEffects
end

function TimeMachine:StepForward()
  if self.index < #self.changes then
    self.index = self.index + 1
    self:Apply(self.changes[self.index].forward)
    if self.sub:HasSubscribers("Step") then
      self.sub:Notify("Step", self.index)
    end
  end
end

function TimeMachine:StepBackward()
  if self.index > 0 then
    self:Apply(self.changes[self.index].backward)
    self.index = self.index - 1
    if self.sub:HasSubscribers("Step") then
      self.sub:Notify("Step", self.index)
    end
  end
end

--- much safer than the name suggests!
---@param id string
function TimeMachine:DestroyTheUniverse(id)
  if self.transaction then
    WeakAuras.prettyPrint("If you're reading this, a time machine transaction was destroyed, but there was one in progress. That's not supposed to happen. Please report this to the WeakAuras developers, thanks!")
    self:Reject()
  end
  if #self.changes > 0 then
    Private.DebugPrint(string.format("Destroying the universe where %i change(s) happpened, because an unexpected change happened to %q.", #self.changes, id))
  end
  self.changes = {}
  self.index = 0
  if self.sub:HasSubscribers("Step") then
    self.sub:Notify("Step", self.index)
  end
end

function TimeMachine:DescribeNext()
  return self.changes[self.index + 1] and self.changes[self.index + 1].forward
end

function TimeMachine:DescribePrevious()
  return self.changes[self.index] and self.changes[self.index].backward
end
