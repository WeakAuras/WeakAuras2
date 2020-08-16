--[[-----------------------------------------------------------------------------
Button Widget for our Expand button
-------------------------------------------------------------------------------]]
if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

local Type, Version = "WeakAurasExpandSmall", 2

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs, print = select, pairs, print

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
  frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
  frame.obj:Fire("OnLeave")
end

local function Button_OnClick(frame, button)
  frame.obj:Fire("OnClick", button)
  AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self:SetHeight(20)
    self:SetWidth(110)
    self:SetLabel()
    self:SetImage(nil)
    self:SetImageSize(24, 24)
    self:SetDisabled(false)
  end,

  -- ["OnRelease"] = nil,

  ["SetLabel"] = function(self, text)
    if text and text ~= "" then
      self.label:Show()
      self.label:SetText(text)
      self:SetHeight(max(self.label:GetStringHeight(), self.image:GetHeight()))
    else
      self.label:Hide()
      self:SetHeight(self.image:GetHeight())
    end
  end,

  ["SetImage"] = function(self, path, ...)
    local image = self.image
    if path == "collapsed" then
      self:SetExpandedState(false)
      path = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\gear"
    elseif path == "expanded" then
      self:SetExpandedState(true)
      path = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\geardown"
    else
      self:SetExpandedState(false)
    end
    image:SetTexture(path)

    if image:GetTexture() then
      local n = select("#", ...)
      if n == 4 or n == 8 then
        image:SetTexCoord(...)
      else
        image:SetTexCoord(0, 1, 0, 1)
      end
    end
  end,

  ["SetExpandedState"] = function(self, state)
    self.expanded = state
    if state then
      self.expandedBackground:Show()
      self.expandedHighlight:Show()
    else
      self.expandedBackground:Hide()
      self.expandedHighlight:Hide()
    end
  end,

  ["GetExpandedState"] = function(self)
    return self.expanded
  end,

  ["SetImageSize"] = function(self, width, height)
    self.image:SetWidth(width)
    self.image:SetHeight(height)
    self:UpdateWidth()
    if self.label:IsShown() then
      self:SetHeight(max(self.label:GetStringHeight(), self.image:GetHeight()))
    else
      self:SetHeight(self.image:GetHeight())
    end
  end,

  ["SetDisabled"] = function(self, disabled)
    self.disabled = disabled
    if disabled then
      self.frame:Disable()
      self.label:SetTextColor(0.5, 0.5, 0.5)
      self.image:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    else
      self.frame:Enable()
      self.label:SetTextColor(1, 1, 1)
      self.image:SetVertexColor(1, 1, 1, 1)
    end
  end,

  ["OnWidthSet"] = function(self, width)
    self:UpdateWidth()
  end,

  ["UpdateWidth"] = function(self)
    self.label:SetWidth(self.frame:GetWidth() - self.image:GetWidth())
    if self.label:IsShown() then
      self:SetHeight(max(self.label:GetStringHeight(), self.image:GetHeight(), 20))
    else
      self:SetHeight(self.image:GetHeight())
    end
    self.expandedBackground:SetHeight(self.frame:GetHeight()*2)
  end,

  ["SetAnchor"] = function(self, otherWidget)
    local expandedBackground = self.expandedBackground
    if otherWidget then
      expandedBackground:SetPoint("BOTTOMLEFT", otherWidget.frame, "TOPLEFT", -4, -2)
    end
  end
}

local function OnFrameShow(frame)
  local self = frame.obj
  local option = self.userdata.option
  if option and option.arg and option.arg.expanderName then
    OptionsPrivate.expanderButtons[option.arg.expanderName] = self

    local otherWidget = OptionsPrivate.expanderAnchors[option.arg.expanderName]
    if otherWidget then
      self:SetAnchor(otherWidget)
    end
  end
end

local function OnFrameHide(frame)
  local self = frame.obj
  local option = self.userdata.option
  if option and option.arg and option.arg.expanderName then
    OptionsPrivate.expanderButtons[option.arg.expanderName] = nil

    local otherWidget = OptionsPrivate.expanderAnchors[option.arg.expanderName]
    if otherWidget then
      self:SetAnchor(nil)
    end
  end
end




--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local frame = CreateFrame("Button", nil, UIParent)
  frame:Hide()

  frame:EnableMouse(true)
  frame:SetScript("OnEnter", Control_OnEnter)
  frame:SetScript("OnLeave", Control_OnLeave)
  frame:SetScript("OnClick", Button_OnClick)
  frame:SetScript("OnShow", OnFrameShow)
  frame:SetScript("OnHide", OnFrameHide)

  local image = frame:CreateTexture(nil, "BACKGROUND")
  image:SetWidth(64)
  image:SetHeight(64)
  image:SetPoint("LEFT", 2, 0)

  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
  label:SetJustifyH("LEFT")
  label:SetJustifyV("CENTER")
  label:SetPoint("RIGHT")
  label:SetPoint("TOP")
  label:SetPoint("BOTTOM")
  label:SetPoint("LEFT", image, "RIGHT", 5, 0)

  local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints(frame)
  highlight:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White")
  highlight:SetVertexColor(0.2, 0.4, 0.8, 0.2)
  highlight:SetBlendMode("ADD")

  local expandedHighlight = frame:CreateTexture(nil, "BACKGROUND")
  expandedHighlight:SetPoint("TOPLEFT", frame, -2, 0)
  expandedHighlight:SetPoint("BOTTOMRIGHT", frame, 0, 0)
  expandedHighlight:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White")
  expandedHighlight:SetVertexColor(1, 0.8, 0, 0.1)
  expandedHighlight:SetBlendMode("ADD")

  local expandedBackground = frame:CreateTexture(nil, "BACKGROUND")
  expandedBackground:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -1, -1)
  expandedBackground:SetWidth(128)
  expandedBackground:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_AlphaGradient")
  expandedBackground:SetVertexColor(1, 0.8, 0, 0.15)
  expandedBackground:SetBlendMode("ADD")

  local widget = {
    label = label,
    image = image,
    frame = frame,
    type  = Type,
    expanded = false,
    expandedBackground = expandedBackground,
    expandedHighlight = expandedHighlight,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
