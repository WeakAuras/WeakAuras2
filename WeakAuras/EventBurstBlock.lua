if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local debug = 0

local function Init(frame)
  frame.burstBlock = CreateFrame("Frame")
  frame.burstBlock.parent = frame
  frame.burstBlock.events = {}
  frame.burstBlock.eventsIndexedOnArg1 = {}
  frame.burstBlock.lastEvent = {}
  frame.burstBlock.event_groups_count = 0
  frame.burstBlock:SetScript("OnEvent", function(self, event, ...)
    local now = GetTime()
    local arg1 = ...
    local groupIndex = self.events[event]
    local groupIndexOnArg1 = self.eventsIndexedOnArg1[event]
    if groupIndex and self.lastEvent[groupIndex] ~= now then
      self.lastEvent[groupIndex] = now
      local script = self.parent:GetScript("OnEvent")
      if type(script) == "function" then
        script(self.parent, event, ...)
      end
      if debug > 1 then
        print("BurstBlock RUN", frame:GetName() or nil, now, event, ...)
      end
    elseif groupIndexOnArg1 and (
      not self.lastEvent[groupIndexOnArg1]
      or self.lastEvent[groupIndexOnArg1][arg1] ~= now
    ) then
      self.lastEvent[groupIndexOnArg1] = self.lastEvent[groupIndexOnArg1] or {}
      self.lastEvent[groupIndexOnArg1][arg1] = now
      self.parent:GetScript("OnEvent")(self.parent, event, ...)
      if debug > 1 then
        print("BurstBlock RUN", frame:GetName() or nil, now, event, ...)
      end
    elseif debug > 0 then
      print("BurstBlock BLOCK", frame:GetName() or nil, now, event, ...)
    end
  end)
end

-- OnEvent script is run only once per frame per group of events registered at once
local BurstBlockRegisterEvent = function(self, events, indexedOnArg1)
  if self.burstBlock == nil then
    Init(self)
  end
  self.burstBlock.event_groups_count = self.burstBlock.event_groups_count + 1
  for _, event in ipairs(events) do
    if indexedOnArg1 then
      self.burstBlock.eventsIndexedOnArg1[event] = self.burstBlock.event_groups_count
    else
      self.burstBlock.events[event] = self.burstBlock.event_groups_count
    end
    self.burstBlock:RegisterEvent(event)
  end
end

--[[
local BurstBlockUnregisterEvent = function(self, event)
  if self.burstBlock == nil then
    error("BurstBlockRegisterEvent needs be called before BurstBlockUnregisterEvent")
  end
  self.burstBlock:UnregisterEvent(event)
  if self.burstBlock.groups then
    for i, group in ipairs(self.burstBlock.groups) do
      if group[event] then
        group[event] = nil
        break
      end
    end
  end
end
]]

local BurstBlockGenericTriggerEvent
do
  local ids = {}
  BurstBlockGenericTriggerEvent = function(id, triggernum, event)
    local now = GetTime()
    ids[id] = ids[id] or {}
    if ids[id][triggernum] ~= now then
      ids[id][triggernum] = now
      return true
    else
      if debug > 0 then
        print("BurstBlock BLOCK generictrigger", id, triggernum, event)
      end
      return false
    end
  end
end

local BurstBlockGenericTriggerUnitEvent
do
  local ids = {}
  BurstBlockGenericTriggerUnitEvent = function(id, triggernum, event, unit)
    local now = GetTime()
    ids[id] = ids[id] or {}
    ids[id][triggernum] = ids[id][triggernum] or {}
    if ids[id][triggernum][unit] ~= now then
      ids[id][triggernum][unit] = now
      return true
    else
      if debug > 0 then
        print("BurstBlock BLOCK generictrigger", id, triggernum, event, unit)
      end
      return false
    end
  end
end

Private.EventBurstBlock = {
  BurstBlockRegisterEvent = BurstBlockRegisterEvent,
  BurstBlockGenericTriggerEvent = BurstBlockGenericTriggerEvent,
  BurstBlockGenericTriggerUnitEvent = BurstBlockGenericTriggerUnitEvent
  --BurstBlockUnregisterEvent = BurstBlockUnregisterEvent
  --UnregisterUnitEvent = function() end,
  --RegisterUnitEvent = function() end,
}
