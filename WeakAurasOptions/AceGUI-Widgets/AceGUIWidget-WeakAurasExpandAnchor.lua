--[[-----------------------------------------------------------------------------
Anchor for a Expandable section
-------------------------------------------------------------------------------]]
if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...
local Type, Version = "WeakAurasExpandAnchor", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local methods = {
  ["OnAcquire"] = function(self)
    self:SetHeight(1)
    self:SetWidth(1)
  end,

  -- ["OnRelease"] = nil,

  ["OnWidthSet"] = function(self, width)
  end,

  ["SetText"] = function(self, text)
  end,

  ["SetFontObject"] = function(self, font)
  end,
}

local function OnFrameShow(frame)
  local self = frame.obj
  local option = self.userdata.option
  if option and option.arg and option.arg.expanderName then
    OptionsPrivate.expanderAnchors[option.arg.expanderName] = self
    local otherWidget = OptionsPrivate.expanderButtons[option.arg.expanderName]
    if otherWidget then
      otherWidget:SetAnchor(self)
    end
  end
end

local function OnFrameHide(frame)
  local self = frame.obj
  local option = self.userdata.option
  if option and option.arg and option.arg.expanderName then
    OptionsPrivate.expanderAnchors[option.arg.expanderName] = nil

    local otherWidget = OptionsPrivate.expanderButtons[option.arg.expanderName]
    if otherWidget then
      otherWidget:SetAnchor(nil)
    end
  end
end


local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:Hide()

  frame:SetScript("OnShow", OnFrameShow)
  frame:SetScript("OnHide", OnFrameHide)

  -- create widget
  local widget = {
    frame = frame,
    type  = Type
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
