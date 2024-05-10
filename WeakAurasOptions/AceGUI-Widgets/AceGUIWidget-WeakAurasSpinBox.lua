--[[-----------------------------------------------------------------------------
Spin Box Widget
-------------------------------------------------------------------------------]]
local Type, Version = "WeakAurasSpinBox", 5
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

local progressLeftOffset = WeakAuras.IsClassicOrCata() and -2 or -3
local progressExtraWidth = WeakAuras.IsClassicOrCata() and -2 or 0
local progressTopOffset = WeakAuras.IsClassicOrCata() and -3 or -2
local progressBottomOffset = WeakAuras.IsClassicOrCata() and 3 or 2

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

local function UpdateProgressBar(self)
  local value = self:GetValue() or 0
  local p = 0
  if self.min and self.max then
    if self.min < self.max then
      p = (value - self.min) / (self.max - self.min)
    end
  end
  p = Clamp(p, 0, 1)
  local w = p * (self.frame:GetWidth() - 45 + progressExtraWidth)
  self.progressBar:SetWidth(max(w, 1))
  self.progressBar:SetTexCoord(0, p , 0, 1)
end

local function UpdateHandleColor(self)
  if self.progressBarHandle.mouseDown then
    self.progressBarHandleTexture:SetColorTexture(0.6, 0.6, 0, 1)
  elseif MouseIsOver(self.progressBarHandle) then
    self.progressBarHandleTexture:SetColorTexture(0.8, 0.8, 0, 1)
  else
    self.progressBarHandleTexture:SetColorTexture(0.4, 0.4, 0, 1)
  end
end

local function UpdateHandleVisibility(self)
  if MouseIsOver(self.frame) then
    self.progressBarHandle:Show()
    UpdateHandleColor(self)
  else
    self.progressBarHandle:Hide()
  end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function SpinBox_OnValueDown(frame)
  local self = frame.obj
  --self.editbox:SetFocus()
  local value = self.value or 0
  local step = self.step or 1
  value = math_max(self.min, value - step)
  PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  self:SetValue(value, true)
end

local function SpinBox_OnValueUp(frame)
  local self = frame.obj
  --self.editbox:SetFocus()
  local value = self.value or 0
  local step = self.step or 1
  value = math_min(self.max, value + step)
  PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  self:SetValue(value, true)
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
    self:SetValue(value, true)
  end
  frame:ClearFocus()
end

local function EditBox_OnEnter(frame)
  frame.onEntered = true
  if not frame.obj.progressBarHandle.mouseDown then
    frame.obj:Fire("OnEnter")
  end
end

local function EditBox_OnLeave(frame)
  if frame.onEntered then
    frame.obj:Fire("OnLeave")
  end
  frame.onEntered = false
end

local function Frame_OnEnter(frame)
  UpdateHandleVisibility(frame.obj)
end

local function ProgressBarHandle_OnUpdate(frame, elapsed)
  UpdateHandleColor(frame.obj)
  if not IsMouseButtonDown("LeftButton") then
    if frame.mouseDown then
      frame.obj:SetValue(frame.obj:GetValue(), true)
      frame.mouseDown = false
    end
  end
  if frame.mouseDown then
    frame.timeElapsed = frame.timeElapsed + elapsed
    if frame.timeElapsed > 0.1 then
      local currentX = GetCursorPosition()
      local deltaX = currentX - frame.startX
      deltaX = deltaX / frame.obj.editbox:GetEffectiveScale()

      local p = deltaX / (frame.obj.frame:GetWidth() - 45 + progressExtraWidth)
      local delta =  p * (frame.obj.max - frame.obj.min)
      local step = frame.obj.step
      local v = frame.originalValue + delta
      v = v - v % step
      v = Clamp(v, frame.obj.min, frame.obj.max)
      frame.obj:SetValue(v, false)
      frame.timeElapsed = 0
    end
  else
    UpdateHandleVisibility(frame.obj)
  end
end

local function ProgressBarHandle_OnMouseDown(frame, button)
  if button ~= "LeftButton" then
    return
  end
  frame.startX = GetCursorPosition()
  frame.originalValue = frame.obj:GetValue()
  frame.timeElapsed = 0
  frame.mouseDown = true
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
    self.progressOpacity = 0
  end,

  ["OnRelease"] = function(self)
    self:ClearFocus()
  end,

  ["OnWidthSet"] = function(self, width)
    UpdateProgressBar(self)
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

  ["SetValue"] = function(self, value, reload)
    self.value = value
    UpdateText(self)
    UpdateButtons(self)
    UpdateProgressBar(self)
    -- In AceOptions the range is treated differently from other widget types
    -- Whereas for other widgets OnValueChanged leads to a reload, this is done only
    -- on OnMouseUp for ranges. (Probably to not reload the options while dragging)
    if reload then
      self:Fire("OnMouseUp", value)
    else
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
    UpdateProgressBar(self)
  end,

  ["SetIsPercent"] = function(self, value)
    self.ispercent = value
    UpdateText(self)
  end,

  ["ClearFocus"] = function(self)
    self.editbox:ClearFocus()
  end,

  ["SetFocus"] = function(self)
    self.editbox:SetFocus()
    self.progressBarHandle:Hide()
  end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetScript("OnEnter", Frame_OnEnter)

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT")
  label:SetPoint("TOPRIGHT")
  label:SetJustifyH("LEFT")
  label:SetHeight(18)

  local leftbutton = CreateFrame("Button", nil, frame)
  leftbutton:SetSize(16, 16)
	leftbutton:SetNormalTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxleft")
  leftbutton:SetHighlightTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxlefth")
	leftbutton:SetPushedTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxleftp")
	leftbutton:SetDisabledTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxleftp")
  leftbutton:SetScript("OnClick", SpinBox_OnValueDown)

  local rightbutton = CreateFrame("Button", nil, frame)
  rightbutton:SetSize(16, 16)
	rightbutton:SetNormalTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxright")
  rightbutton:SetHighlightTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxrighth")
	rightbutton:SetPushedTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxrightp")
	rightbutton:SetDisabledTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxrightp")
  rightbutton:SetScript("OnClick", SpinBox_OnValueUp)

  local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  editbox:SetAutoFocus(false)
  editbox:SetFontObject(ChatFontNormal)
  editbox:SetHeight(19)
  editbox:SetJustifyH("CENTER")
  editbox:EnableMouse(true)
  editbox:EnableMouseWheel(false)
  editbox:SetTextInsets(0, 0, 3, 3)
  editbox:SetScript("OnEnter", EditBox_OnEnter)
  editbox:SetScript("OnLeave", EditBox_OnLeave)
  editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
  editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
  editbox:SetScript("OnEditFocusGained", function(frame)
    AceGUI:SetFocus(frame.obj)
    UpdateHandleVisibility(frame.obj)
  end)
  editbox:SetScript("OnEditFocusLost", function(frame)
    UpdateHandleVisibility(frame.obj)
  end)

  leftbutton:SetPoint("TOPLEFT", 2, -18)
  rightbutton:SetPoint("TOPRIGHT", -2, -18)
  editbox:SetPoint("LEFT", leftbutton, "RIGHT", 8, 0)
  editbox:SetPoint("RIGHT", rightbutton, "LEFT", -2, 0)

  local progressBar = editbox:CreateTexture(nil, "ARTWORK", nil)
  progressBar:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\spinboxoverlay")
  progressBar:SetVertexColor(0.50, 0.50, 0.50, 1)
  progressBar:SetPoint("TOPLEFT", editbox, "TOPLEFT", progressLeftOffset, progressTopOffset)
  progressBar:SetPoint("BOTTOMLEFT", editbox, "BOTTOMLEFT", progressLeftOffset, progressBottomOffset)
  progressBar:SetWidth(0)

  local progressBarHandle = CreateFrame("Frame", nil, editbox)
  progressBarHandle:SetPoint("TOP", progressBar, "TOP", 0, 2)
  progressBarHandle:SetPoint("BOTTOM", progressBar, "BOTTOM", 0, -2)
  progressBarHandle:SetPoint("LEFT", progressBar, "RIGHT", -4, 0)
  progressBarHandle:SetPoint("RIGHT", progressBar, "RIGHT", 4, 0)
  progressBarHandle:EnableMouse(true)
  progressBarHandle:Hide()
  progressBarHandle:SetScript("OnMouseDown", ProgressBarHandle_OnMouseDown)
  progressBarHandle:SetScript("OnUpdate", ProgressBarHandle_OnUpdate)

  local progressBarHandleTexture = progressBarHandle:CreateTexture(nil, "ARTWORK")
  progressBarHandleTexture:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White")
  progressBarHandleTexture:SetColorTexture(0.8, 0.8, 0, 0.8)
  progressBarHandleTexture:SetPoint("TOPLEFT", progressBarHandle, "TOPLEFT", 2, -2)
  progressBarHandleTexture:SetPoint("BOTTOMRIGHT", progressBarHandle, "BOTTOMRIGHT", -2, 2)

  local widget = {
    label = label,
    editbox = editbox,
    leftbutton = leftbutton,
    rightbutton = rightbutton,
    progressBar = progressBar,
    progressBarHandle = progressBarHandle,
    progressBarHandleTexture = progressBarHandleTexture,
    frame = frame,
    type = Type,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  editbox.obj, leftbutton.obj, rightbutton.obj, frame.obj, progressBarHandle.obj = widget, widget, widget, widget, widget

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
