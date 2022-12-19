if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local isDragonriding = nil

local function HandleEvent(self, event, arg1)
  local dragonridingSpellIds = C_MountJournal.GetCollectedDragonridingMounts()
  local oldIsDragonriding = isDragonriding
  isDragonriding = false
  if IsMounted() then
    for _, mountId in ipairs(dragonridingSpellIds) do
      local spellId = select(2, C_MountJournal.GetMountInfoByID(mountId))
      if C_UnitAuras.GetPlayerAuraBySpellID(spellId) then
        isDragonriding = true
      end
    end
  end
  if oldIsDragonriding ~= isDragonriding then
    Private.callbacks:Fire("WA_DRAGONRIDING_UPDATE")
  end
  if event == "PLAYER_ENTERING_WORLD" and arg1 == true then
    C_Timer.After(2, HandleEvent)
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", HandleEvent)

Private.IsDragonriding = function ()
  return isDragonriding
end

