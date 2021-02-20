if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local funcs = {
  Open = function(self)
    self:Refill()

    self.parentFrame.window = "settingsview"
    self.parentFrame:UpdateFrameVisible()
  end,
  Refill = function(self)
    -- TODO need to check width of margin
    -- TODO call refill not on each OnSizeChanged ?
    -- TODO work on the ui a lot more
    local width = (self.group.frame:GetWidth() - 30) / 170
    local optionTable = OptionsPrivate.GetDefaultsOptions(width)
    AceConfig:RegisterOptionsTable("WeakAurasSettings", optionTable)
    AceConfigDialog:Open("WeakAurasSettings", self.group)
  end,
  Close = function(self)
    self.parentFrame.window = "default"
    self.parentFrame:UpdateFrameVisible()
  end
}

local function ConstructSettings(frame)
  local settingsFrame = CreateFrame("Frame", nil, frame)
  for k, f in pairs(funcs) do
    settingsFrame[k] = f
  end
  settingsFrame.parentFrame = frame
  settingsFrame:SetAllPoints(frame)
  settingsFrame:Hide()

  local group = AceGUI:Create("WeakAurasInlineGroup")
  settingsFrame.group = group
  group.frame:SetParent(settingsFrame)
  group.frame:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -17, 35)
  group.frame:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 17, -10)
  group.frame:SetScript("OnSizeChanged", function() settingsFrame:Refill() end)

  local close = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
  close:SetScript("OnClick", function()
      settingsFrame:Close()
    end)
  close:SetPoint("BOTTOMRIGHT", -27, 13)
  close:SetFrameLevel(close:GetFrameLevel() + 1)
  close:SetHeight(20)
  close:SetWidth(100)
  close:SetText(L["Ok"])

  return settingsFrame
end

local settings
function OptionsPrivate.Settings(frame)
  settings = settings or ConstructSettings(frame)
  return settings
end
