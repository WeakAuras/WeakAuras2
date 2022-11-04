--[[-----------------------------------------------------------------------------
Spin Box Widget
-------------------------------------------------------------------------------]]
local Type, Version = "WeakAurasSpinBox", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
  return
end

-- Lua APIs
local math_min, math_max, floor = math.min, math.max, math.floor
local tonumber, pairs = tonumber, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function UpdateText(self)
  local value = self:GetValue() or 0
  if self.ispercent then
    self.editbox:SetText(("%s%%"):format(floor(value * 1000 + 0.5) / 10))
  else
    self.editbox:SetText(floor(value * 100 + 0.5) / 100)
  end
end

local function UpdateButtons(self)
  local value = self:GetValue() or 0
  self.leftbutton:SetEnabled(value > self.min)
  self.rightbutton:SetEnabled(value < self.max)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Frame_OnMouseDown()
  AceGUI:ClearFocus()
end

local function SpinBox_OnValueDown(frame)
  local self = frame.obj
  --self.editbox:SetFocus()
  local value = self.value or 0
  local step = self.step or 1
  value = math_max(self.min, value - step)
  PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  self:SetValue(value)
end

local function SpinBox_OnValueUp(frame)
  local self = frame.obj
  --self.editbox:SetFocus()
  local value = self.value or 0
  local step = self.step or 1
  value = math_min(self.max, value + step)
  PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  self:SetValue(value)
end

local function EditBox_OnEscapePressed(frame)
  frame:ClearFocus()
end

local function EditBox_OnEnterPressed(frame)
  local self = frame.obj
  local value = frame:GetText()
  if self.ispercent then
    value = value:gsub("%%", "")
    value = tonumber(value) / 100
  else
    value = tonumber(value)
  end

  if value then
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    self:SetValue(value)
    --self:Fire("OnMouseUp", value)
  end
end

local function EditBox_OnEnter(frame)
  frame.obj:Fire("OnEnter")
end

local function EditBox_OnLeave(frame)
  frame.obj:Fire("OnLeave")
end

local function EditBox_OnMouseDown(frame, button)
  if button ~= "LeftButton" then
    return
  end
  local x = GetCursorPosition()
  local timeElapsed = 0
  if not frame.onupdate then
    frame.onupdate = CreateFrame("Frame")
  end
  frame.onupdate:SetScript("OnUpdate", function(_, elapsed)
    timeElapsed = timeElapsed + elapsed
    if timeElapsed > 0.1 then
      local new_x = GetCursorPosition()
      local value = frame:GetText()
      if frame.obj.ispercent then
        value = value:gsub("%%", "")
        value = tonumber(value) / 100 + (new_x > x and 1 or -1)
        value = math_max(frame.obj.min, value)
        value = math_min(frame.obj.max, value)
        frame:SetText(value .. "%%")
        EditBox_OnEnterPressed(frame)
      else
        value = tonumber(value) + (new_x > x and 1 or -1)
        value = math_max(frame.obj.min, value)
        value = math_min(frame.obj.max, value)
        frame:SetText(value, frame.obj.min, frame.obj.max)
        EditBox_OnEnterPressed(frame)
      end
      timeElapsed = 0
    end
  end)
  frame.onupdate:Show()
end

local function EditBox_OnMouseUp(frame, button)
  if button == "LeftButton" then
    if frame.onupdate then
      frame.onupdate:SetScript("OnUpdate", nil)
    end
    EditBox_OnEnterPressed(frame)
  end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(200)
    self:SetHeight(44)
    self:SetDisabled(false)
    self:SetIsPercent(nil)
    self:SetSpinBoxValues(0, 100, 1)
    self:SetValue(0)
  end,

  ["OnRelease"] = function(self)
    self:ClearFocus()
  end,

  ["SetDisabled"] = function(self, disabled)
    self.disabled = disabled
    if disabled then
      self.label:SetTextColor(0.5, 0.5, 0.5)
      self.editbox:SetTextColor(0.5, 0.5, 0.5)
      self.editbox:EnableMouse(false)
      self.editbox:ClearFocus()
      self.leftbutton:SetEnabled(false)
      self.rightbutton:SetEnabled(false)
    else
      self.label:SetTextColor(1, 0.82, 0)
      self.editbox:SetTextColor(1, 1, 1)
      self.editbox:EnableMouse(true)
    end
  end,

  ["SetValue"] = function(self, value)
    local changed = value ~= self.value
    self.value = value
    UpdateText(self)
    UpdateButtons(self)
    if changed then
      self:Fire("OnValueChanged", value)
    end
  end,

  ["GetValue"] = function(self)
    return self.value
  end,

  ["SetLabel"] = function(self, text)
    self.label:SetText(text)
  end,

  ["SetSliderValues"] = function(self, ...)
    self:SetSpinBoxValues(...)
  end,

  ["SetSpinBoxValues"] = function(self, min, max, step)
    self.min = min or 0
    self.max = max or 100
    self.step = step or 1
    UpdateButtons(self)
  end,

  ["SetIsPercent"] = function(self, value)
    self.ispercent = value
    UpdateText(self)
  end,

  ["ClearFocus"] = function(self)
    self.editbox:ClearFocus()
    self.frame:SetScript("OnShow", nil)
  end,

  ["SetFocus"] = function(self)
    self.editbox:SetFocus()
  end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)

  frame:EnableMouse(true)
  frame:SetScript("OnMouseDown", Frame_OnMouseDown)

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT")
  label:SetPoint("TOPRIGHT")
  label:SetJustifyH("LEFT")
  label:SetHeight(18)

  local leftbutton = CreateFrame("Button", nil, frame)
  leftbutton:SetSize(11, 14)
  leftbutton:SetNormalTexture("UI-ScrollBar-ScrollLeftButton-Up")
  leftbutton:SetPushedTexture("UI-ScrollBar-ScrollLeftButton-Down")
  leftbutton:SetDisabledTexture("UI-ScrollBar-ScrollLeftButton-Disabled")
  leftbutton:SetScript("OnClick", SpinBox_OnValueDown)

  local rightbutton = CreateFrame("Button", nil, frame)
  rightbutton:SetSize(11, 14)
  rightbutton:SetNormalTexture("UI-ScrollBar-ScrollRightButton-Up")
  rightbutton:SetPushedTexture("UI-ScrollBar-ScrollRightButton-Down")
  rightbutton:SetDisabledTexture("UI-ScrollBar-ScrollRightButton-Disabled")
  rightbutton:SetScript("OnClick", SpinBox_OnValueUp)

  local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  editbox:SetAutoFocus(false)
  editbox:SetFontObject(ChatFontNormal)
  editbox:SetHeight(19)
  editbox:SetJustifyH("CENTER")
  editbox:EnableMouse(true)
  editbox:SetTextInsets(0, 0, 3, 3)
  editbox:SetScript("OnEnter", EditBox_OnEnter)
  editbox:SetScript("OnLeave", EditBox_OnLeave)
  editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
  editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
  editbox:SetScript("OnEditFocusGained", function(frame)
    AceGUI:SetFocus(frame.obj)
  end)
  editbox:SetScript("OnMouseWheel", function(self, delta)
    if self:HasFocus() then
      if delta == 1 then
        SpinBox_OnValueUp(self)
      else
        SpinBox_OnValueDown(self)
      end
    end
  end)

  editbox:SetScript("OnMouseDown", EditBox_OnMouseDown)
  editbox:SetScript("OnMouseUp", EditBox_OnMouseUp)

  leftbutton:SetPoint("TOPLEFT", 2, -18)
  rightbutton:SetPoint("TOPRIGHT", -2, -18)
  editbox:SetPoint("LEFT", leftbutton, "RIGHT", 8, 0)
  editbox:SetPoint("RIGHT", rightbutton, "LEFT", -2, 0)

  local widget = {
    label = label,
    editbox = editbox,
    leftbutton = leftbutton,
    rightbutton = rightbutton,
    frame = frame,
    type = Type,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  editbox.obj, leftbutton.obj, rightbutton.obj = widget, widget, widget

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
