if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local function HandleEvent(self, event, arg1)
  Private.callbacks:Fire("WA_DRAGONRIDING_UPDATE")
  if event == "PLAYER_ENTERING_WORLD" and arg1 == true then
    C_Timer.After(2, HandleEvent)
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_CAN_GLIDE_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", HandleEvent)

Private.IsDragonriding = function ()
  return select(2, C_PlayerInfo.GetGlidingInfo())
end

