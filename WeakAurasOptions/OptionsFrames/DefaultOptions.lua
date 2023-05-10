if not WeakAuras.IsLibsOK() then
  return
end
local AddonName, OptionsPrivate = ...

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

print("yo")

local function ConstructDefaultOptions(frame)
  local group = AceGUI:Create("WeakAurasInlineGroup")
  group.frame:SetParent(frame)
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -63)
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 46)
  group.frame:Hide()
  group:SetLayout("flow")

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate")
  close:SetScript("OnClick", function()
    group:Close()
  end)
  close:SetPoint("BOTTOMRIGHT", -20, -24)
  close:SetFrameLevel(close:GetFrameLevel() + 1)
  close:SetHeight(20)
  close:SetWidth(100)
  close:SetText(L["Close"])

  function group.Open(self, text)
    frame.window = "defaultOptions"
    frame:UpdateFrameVisible()

    group:DoLayout()
  end

  function group.Close(self)
    frame.window = "default"
    frame:UpdateFrameVisible()
  end

  return group
end

function OptionsPrivate.DefaultOptions(frame)
  defaultOptions = defaultOptions or ConstructDefaultOptions(frame)
  return defaultOptions
end
