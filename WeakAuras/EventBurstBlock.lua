if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local debug = 2

local function Init(frame)
  frame.burstBlock = CreateFrame("Frame")
  frame.burstBlock.parent = frame
  frame.burstBlock.events = {}
  frame.burstBlock.lastEvent = {}
  frame.burstBlock.event_groups_count = 0
  frame.burstBlock:SetScript("OnEvent", function(self, event, ...)
    local now = GetTime()
    local groupIndex = self.events[event]
    if self.lastEvent[groupIndex] ~= now then
      self.lastEvent[groupIndex] = now
      self.parent:GetScript("OnEvent")(self.parent, event, ...)
      if debug > 1 then
        print("BurstBlock RUN", frame:GetName() or nil, now, event, ...)
      end
    elseif debug > 0 then
      print("BurstBlock BLOCK", frame:GetName() or nil, now, event, ...)
    end
  end)
end

-- OnEvent script is run only once per frame per event, or once per frame per group of events if multiple events are registered at once
local BurstBlockRegisterEvent = function(self, ...)
  if self.burstBlock == nil then
    Init(self)
  end
  local num_events = select("#", ...)
  self.burstBlock.event_groups_count = self.burstBlock.event_groups_count + 1
  for i = 1, num_events do
    local event = select(i, ...)
    self.burstBlock.events[event] = self.burstBlock.event_groups_count
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

Private.EventBurstBlock = {
  BurstBlockRegisterEvent = BurstBlockRegisterEvent,
  --BurstBlockUnregisterEvent = BurstBlockUnregisterEvent
  --UnregisterUnitEvent = function() end,
  --RegisterUnitEvent = function() end,
}
