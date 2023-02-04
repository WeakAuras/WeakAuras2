if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local debug = 2

local function Init(frame)
  frame.burstBlock = CreateFrame("Frame")
  frame.burstBlock.parent = frame
  frame.burstBlock.lastEvent = {}
  frame.burstBlock:SetScript("OnEvent", function(self, event, ...)
    local now = GetTime()
    -- check if event is part of a group of events
    local groupIndex
    if self.groups then
      for i, group in ipairs(self.groups) do
        if group[event] then
          groupIndex = i
          break
        end
      end
    end
    if groupIndex and self.groups[groupIndex].lastEvent ~= now then
      self.groups[groupIndex].lastEvent = now
      self.parent:GetScript("OnEvent")(self.parent, event, ...)
      if debug > 1 then
        print("BurstBlock RUN", frame:GetName() or nil, now, true, event, ...)
      end
    elseif groupIndex == nil and self.lastEvent[event] ~= now then
      self.lastEvent[event] = now
      self.parent:GetScript("OnEvent")(self.parent, event, ...)
      if debug > 1 then
        print("BurstBlock RUN", frame:GetName() or nil, now, false, event, ...)
      end
    elseif debug > 0 then
      print("BurstBlock BLOCK", frame:GetName() or nil, now, groupIndex and true or false, event, ...)
    end
  end)
end

-- OnEvent script is run only once per frame per event, or once per frame per group of events if multiple events are registered at once
local BurstBlockRegisterEvent = function(self, ...)
  if self.burstBlock == nil then
    Init(self)
  end
  local num_events = select("#", ...)
  if num_events > 1 then
    self.burstBlock.groups = self.burstBlock.groups or {}
    tinsert(self.burstBlock.groups, { lastEvent = 0 })
  end
  for i = 1, num_events do
    local event = select(i, ...)
    self.burstBlock:RegisterEvent(event)
    if num_events > 1 then
      self.burstBlock.groups[#self.burstBlock.groups][event] = true
    end
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

Private.EventBurstBlock = {
  BurstBlockRegisterEvent = BurstBlockRegisterEvent,
  --BurstBlockUnregisterEvent = BurstBlockUnregisterEvent
  --UnregisterUnitEvent = function() end,
  --RegisterUnitEvent = function() end,
}
