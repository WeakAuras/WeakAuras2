if not WeakAuras.IsLibsOK() then
  return
end
local AddonName, OptionsPrivate = ...

-- WoW APIs
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")
local LDBIconcon = LibStub("LibDBIcon-1.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local fonts = {
  displayText = "%p",
  outline = "OUTLINE",
  color = { 1, 1, 1, 1 },
  justify = "LEFT",
  selfPoint = "BOTTOM",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  font = defaultFont,
  fontSize = defaultFontSize,
  frameStrata = 1,
  customTextUpdate = "event",
  automaticWidth = "Auto",
  fixedWidth = 200,
  wordWrap = "WordWrap",
  shadowColor = { 0, 0, 0, 1 },
  shadowXOffset = 1,
  shadowYOffset = -1,
}

local font_properties = {
  color = {
    display = L["Color"],
    setter = "Color",
    type = "color",
  },
  fontSize = {
    display = L["Font Size"],
    setter = "SetTextHeight",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1,
    default = 12,
  },
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
  dropdown:SetGroupList(dropdown.list)

  local Options = {
    Icon = {
      type = "select",
      name = L["Menu Icon"],
      desc = L["Select where WeakAuras' menu icon is displayed."],
      values = {
        [0] = L["None"],
        [1] = L["Minimap"],
        [2] = L["Add-On Compartment"],
      },
      get = function()
        return WeakAurasSaved.db.LDB.position or 0
      end,
      set = function(i, v)
        local LDBIcon = WeakAurasSaved.LDBIcon
        if v == 1 then
          LDBIcon:Show(AddonName)
          LDBIcon:RemoveButtonFromCompartment(AddonName)
        elseif v == 2 then
          LDBIcon:Hide(AddonName)
          LDBIcon:AddButtonToCompartment(AddonName)
        else
          LDBIcon:Hide(AddonName)
          LDBIcon:RemoveButtonFromCompartment(AddonName)
        end
        WeakAurasSaved.db.LDB.position = v
      end,
      order = 5,
      disabled = function()
        return not WeakAurasSaved.LDBIcon
      end,
    },
  }

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
