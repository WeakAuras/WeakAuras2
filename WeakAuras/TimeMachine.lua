---@type string, Private
local _, Private = ...



local TimeMachine = {
  ---@type change[]
  changes = {},
  index = 0
}
Private.TimeMachine = TimeMachine


---@class delta
---@field set? table<string, any>
---@field unset? table<string, true>

---@alias change table<uid, {forward: delta, backward: delta}>

---@param auras auraData[]
---@param forwardDeltas delta[]
function TimeMachine:Commit(auras, forwardDeltas)
  assert(#auras == #forwardDeltas, "Invalid number of changes")
  Private.DebugPrint(#auras, 'total changes')
  ---@type change
  local change = {}
  for i, aura in ipairs(auras) do
    Private.DebugPrint(aura.uid)
    local forwardChange = forwardDeltas[i]
    ---@type delta
    local backwardDelta = {}
    local changed = false
    for k, v in pairs(forwardChange.set or {}) do
      if aura[k] then
        if aura[k] == v then
          -- null change, so drop the set
          forwardChange.set[k] = nil
        else
          Private.DebugPrint('change detected on ', k, ':', aura[k], '=>', v)
          changed = true
          backwardDelta.set = backwardDelta.set or {}
          backwardDelta.set[k] = aura[k]
        end
      else
        Private.DebugPrint('change detected on ', k, ':', 'nil', '=>', v)
        changed = true
        backwardDelta.unset = backwardDelta.unset or {}
        backwardDelta.unset[k] = true
      end
    end
    for k in pairs(forwardChange.unset or {}) do
      if aura[k] then
        Private.DebugPrint('change detected on ', k, ':', aura[k], '=>', 'nil')
        changed = true
        backwardDelta.set = backwardDelta.set or {}
        backwardDelta.set[k] = aura[k]
      else
        -- null change, so drop the unset
        forwardChange.unset[k] = nil
      end
      if changed then
        Private.DebugPrint('adding uid to list')
        table.insert(uids, aura.uid)
      end
    end
    if changed then
      Private.DebugPrint('adding change to list')
      change[aura.uid] = {
        forward = forwardChange,
        backward = backwardDelta
      }
    end
  end
  if next(change) then
    Private.DebugPrint('committing change')
    table.insert(self.changes, change)
    return self:StepForward()
  end
end

function TimeMachine:StepForward()
  if self.index < #self.changes then
    self.index = self.index + 1
    for uid, delta in pairs(self.changes[self.index]) do
      local data = Private.GetDataByUID(uid)
      for k, v in pairs(delta.forward.set or {}) do
        data[k] = v
      end
      for k in pairs(delta.forward.unset or {}) do
        data[k] = nil
      end
      WeakAuras.Add(data)
    end
  end
end

function TimeMachine:StepBackward()
  if self.index > 0 then
    for uid, delta in pairs(self.changes[self.index]) do
      local data = Private.GetDataByUID(uid)
      for k, v in pairs(delta.backward.set or {}) do
        data[k] = v
      end
      for k in pairs(delta.backward.unset or {}) do
        data[k] = nil
      end
      WeakAuras.Add(data)
    end
    self.index = self.index - 1
  end
end
