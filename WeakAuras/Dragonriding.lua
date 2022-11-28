if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local isDragonriding = nil

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMPANION_LEARNED")
frame:RegisterEvent("COMPANION_UNLEARNED")
frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
  local dragonridingSpellIds = C_MountJournal.GetCollectedDragonridingMounts()
  if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
    local oldIsDragonriding = isDragonriding
    if not IsMounted() then
      isDragonriding = false
    else
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
  end
end)

Private.IsDragonriding = function ()
  return isDragonriding
end
