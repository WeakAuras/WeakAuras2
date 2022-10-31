if not WeakAuras.IsLibsOK() then return end

local Type, Version = "WeakAurasAnchorButtons", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local directions = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local buttonSize = 10
local frameWidth = 100
local frameHeight = 50
local titleHeight = 15

local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(frameWidth + buttonSize)
    self:SetHeight(frameHeight + buttonSize + titleHeight + 2)
    self:SetDisabled(false)
  end,

  ["SetValue"] = function(self, text)
    if not tContains(directions, text) then return end
    for direction, button in pairs(self.buttons) do
      if direction == text then
        button.tex:SetVertexColor(0.9, 0.9, 0, 1)
      else
        button.tex:SetVertexColor(0.3, 0.3, 0.3, 1)
      end
      button:SetNormalTexture(button.tex)
    end
    self.value = text
  end,

  ["GetValue"] = function(self)
    return self.value
  end,

  ["SetLabel"] = function(self, text)
    if text and text ~= "" then
      self.label:SetText(text);
      self.label:Show()
    else
      self.label:SetText("")
      self.label:Hide()
    end
  end,

  ["SetList"] = function() end,

  ["SetDisabled"] = function(self, disabled)
    self.disabled = disabled
    if disabled then
      self.label:SetTextColor(0.5,0.5,0.5)
      for _, button in pairs(self.buttons) do
        button:EnableMouse(false)
      end
    else
      self.label:SetTextColor(1,.82,0)
      for _, button in pairs(self.buttons) do
        button:EnableMouse(true)
      end
    end
  end,
}

local function buttonClicked(self)
  AceGUI:ClearFocus()
  local frame = self:GetParent()
  local widget = frame.obj
  widget:SetValue(self.value)
  widget:Fire("OnValueChanged", self.value)
end

local function Constructor()
  local name = "WeakAurasAnchorButtons" .. AceGUI:GetNextWidgetNum(Type)
  local frame = CreateFrame("Frame", name, UIParent)
  frame:SetSize(frameWidth, frameHeight)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
  label:SetHeight(titleHeight);
  label:SetJustifyH("CENTER");
  label:SetPoint("TOP", frame, "TOP");

  local background = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  background:SetSize(frameWidth, frameHeight)
  background:SetPoint("TOP", frame, "TOP", 0, -(titleHeight + 4))
  background:SetBackdrop({
     bgFile = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite.tga",
     edgeFile = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite.tga",
     tile = true,
     tileEdge = true,
     --tileSize = 8,
     edgeSize = 2
     --insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  background:SetBackdropColor(0.2,0.2,0.2,0.5)
  background:SetBackdropBorderColor(1,1,1,0.6)

  local buttons = {}
  for _, direction in ipairs(directions) do
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(buttonSize, buttonSize)
    button:SetPoint(
      "CENTER",
      background,
      direction
    )

    local buttonTex = button:CreateTexture()
    buttonTex:SetAllPoints()
    buttonTex:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite.tga")
    buttonTex:SetVertexColor(0.3, 0.3, 0.3, 1)
    button:SetNormalTexture(buttonTex)
    button.tex = buttonTex
    button.value = direction

    button:SetScript("OnClick", buttonClicked)
    buttons[direction] = button
  end

  --- @type table<string, any>
  local widget = {
    frame = frame,
    type = Type,
    buttons = buttons,
    label = label
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
