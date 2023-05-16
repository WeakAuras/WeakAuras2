if not WeakAuras.IsLibsOK() then
  return
end
local AddonName, OptionsPrivate = ...

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local LDBIcon = LibStub("LibDBIcon-1.0")
local LSM = LibStub("LibSharedMedia-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L
local defaultFont = WeakAuras.defaultFont
local defaultFontSize = WeakAuras.defaultFontSize

--[[
TODO:
For first release:
    - Add a "Reset" button to reset the default options to the old defaults
    - Make the Minimap button dropdown work
    - Make the font options work
    - Make the bar texture options work
    - Add the transparency slider
]]

local font = {
  type = "select",
  width = WeakAuras.normalWidth,
  dialogControl = "LSM30_Font",
  name = L["Font"],
  order = 45,
  values = AceGUIWidgetLSMlists.font,
}

local fontSize = {
  type = "range",
  control = "WeakAurasSpinBox",
  width = WeakAuras.normalWidth,
  name = L["Size"],
  order = 46,
  min = 6,
  softMax = 72,
  step = 1,
}

local color = {
  type = "color",
  width = WeakAuras.normalWidth,
  name = L["Text Color"],
  hasAlpha = true,
  order = 47,
}

local function ConstructDefaultOptions(frame)
  local group = AceGUI:Create("WeakAurasInlineGroup")
  group.frame:SetParent(frame)
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -63)
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 46)
  group.frame:Hide()
  group:SetLayout("flow")

  local fontHeading = AceGUI:Create("Heading")
  fontHeading:SetText(L["Default Font Settings"])
  fontHeading:SetRelativeWidth(0.7)
  group:AddChild(fontHeading)

  group:AddChild(AceGUI:Create("WeakAurasSpacer"))

  local buttonHeading = AceGUI:Create("Heading")
  buttonHeading:SetText(L["Minimap Button Settings"])
  buttonHeading:SetRelativeWidth(0.7)
  group:AddChild(buttonHeading)

  local buttonLabel = AceGUI:Create("Label")
  buttonLabel:SetFontObject(GameFontHighlight)
  buttonLabel:SetFullWidth(true)
  buttonLabel:SetText(L["Select where WeakAuras' menu icon is displayed."])
  group:AddChild(buttonLabel)

  local dropdown = AceGUI:Create("DropdownGroup")
  dropdown:SetLayout("fill")
  dropdown.width = "fill"
  dropdown:SetHeight(390)
  group:AddChild(dropdown)
  dropdown.list = {
    [0] = L["None"],
    [1] = L["Minimap"],
    [2] = L["Add-On Compartment"],
  }
  -- dropdown:SetValue(dropdown.list[WeakAurasSaved.minimap.position] or dropdown.list[1])
  if not LDBIcon:IsButtonCompartmentAvailable() then
    tremove(dropdown.list, 2)
  end
  dropdown:SetGroupList(dropdown.list)
  dropdown:SetCallback("OnGroupSelected", function(widget, event, uniquevalue)
    print("value", uniquevalue)
    if uniquevalue == 1 then
      LDBIcon:Show("WeakAuras")
      LDBIcon:RemoveButtonFromCompartment("WeakAuras")
    elseif uniquevalue == 2 then
      LDBIcon:Hide("WeakAuras")
      LDBIcon:AddButtonToCompartment("WeakAuras")
    else
      LDBIcon:Hide("WeakAuras")
      LDBIcon:RemoveButtonFromCompartment("WeakAuras")
    end
    WeakAurasSaved.minimap.position = uniquevalue
  end)

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
