-- all this is is a frame that ensures that the SV is a table type
local addonName = ...
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, addon)
  if addon == addonName then
    if type(WeakAurasArchive) ~= "table" then
      WeakAurasArchive = {}
    end
    self:UnregisterEvent("ADDON_LOADED")
  end
end)
