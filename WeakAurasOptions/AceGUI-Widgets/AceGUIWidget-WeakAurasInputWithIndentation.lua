if not WeakAuras.IsLibsOK() then return end

local Type, Version = "WeakAurasInputWithIndentation", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local tostring, pairs = tostring, pairs

-- WoW APIs
local PlaySound = PlaySound
local GetCursorInfo, ClearCursor = GetCursorInfo, ClearCursor
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G

if not AceGUIWeakAurasInputWithIndentationInsertLink then
  -- upgradeable hook
  hooksecurefunc("ChatEdit_InsertLink", function(...) return _G.AceGUIWeakAurasInputWithIndentationInsertLink(...) end)
end

function _G.AceGUIWeakAurasInputWithIndentationInsertLink(text)
  for i = 1, AceGUI:GetWidgetCount(Type) do
    local editbox = _G[("WeakAurasInputWithIndentation%uEdit"):format(i)]
    if editbox and editbox:IsVisible() and editbox:HasFocus() then
      text = text:gsub("|", "||")
      editbox:Insert(text)
      return true
    end
  end
end

local function ShowButton(self)
  if not self.disablebutton then
    self.button:Show()
    self.editbox:SetTextInsets(0, 20, 3, 3)
  end
end

local function HideButton(self)
  self.button:Hide()
  self.editbox:SetTextInsets(0, 0, 3, 3)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
  frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
  frame.obj:Fire("OnLeave")
end

local function Frame_OnShowFocus(frame)
  frame.obj.editbox:SetFocus()
  frame:SetScript("OnShow", nil)
end

local function EditBox_OnEscapePressed(frame)
  AceGUI:ClearFocus()
end

local function EditBox_OnEnterPressed(frame)
  local self = frame.obj
  local value = frame:GetText()
  local cancel = self:Fire("OnEnterPressed", value)
  if not cancel then
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    HideButton(self)
  end
end

local function EditBox_OnReceiveDrag(frame)
  local self = frame.obj
  local type, id, info, extra = GetCursorInfo()
  local name
  if type == "item" then
    name = info
  elseif type == "spell" then
    if C_Spell and C_Spell.GetSpellName then
      name = C_Spell.GetSpellName(extra)
    else
      name = GetSpellInfo(id, info)
    end
  elseif type == "macro" then
    name = GetMacroInfo(id)
  end
  if name then
    self:SetText(name)
    self:Fire("OnEnterPressed", name)
    ClearCursor()
    HideButton(self)
    AceGUI:ClearFocus()
  end
end

local function EditBox_OnTextChanged(frame)
  local self = frame.obj
  local value = frame:GetText()
  if tostring(value) ~= tostring(self.lasttext) then
    self:Fire("OnTextChanged", value)
    self.lasttext = value
    ShowButton(self)
  end
end

local function EditBox_OnFocusGained(frame)
  AceGUI:SetFocus(frame.obj)
end

local function Button_OnClick(frame)
  local editbox = frame.obj.editbox
  editbox:ClearFocus()
  EditBox_OnEnterPressed(editbox)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    -- height is controlled by SetLabel
    self:SetWidth(200)
    self:SetDisabled(false)
    self:SetLabel()
    self:SetText()
    self:DisableButton(false)
    self:SetMaxLetters(0)
  end,

  ["OnRelease"] = function(self)
    self:ClearFocus()
  end,

  ["SetDisabled"] = function(self, disabled)
    self.disabled = disabled
    if disabled then
      self.editbox:EnableMouse(false)
      self.editbox:ClearFocus()
      self.editbox:SetTextColor(0.5,0.5,0.5)
      self.label:SetTextColor(0.5,0.5,0.5)
    else
      self.editbox:EnableMouse(true)
      self.editbox:SetTextColor(1,1,1)
      self.label:SetTextColor(1,.82,0)
    end
  end,

  ["SetText"] = function(self, text)
    self.lasttext = text or ""
    self.editbox:SetText(text or "")
    self.editbox:SetCursorPosition(0)
    HideButton(self)
  end,

  ["GetText"] = function(self, text)
    return self.editbox:GetText()
  end,

  ["SetLabel"] = function(self, text)
    if text and text ~= "" then
      self.label:SetText(text)
      self.label:Show()
      self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",7,-18)
      self:SetHeight(44)
      self.alignoffset = 30
    else
      self.label:SetText("")
      self.label:Hide()
      self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",7,0)
      self:SetHeight(26)
      self.alignoffset = 12
    end
  end,

  ["DisableButton"] = function(self, disabled)
    self.disablebutton = disabled
    if disabled then
      HideButton(self)
    end
  end,

  ["SetMaxLetters"] = function (self, num)
    self.editbox:SetMaxLetters(num or 0)
  end,

  ["ClearFocus"] = function(self)
    self.editbox:ClearFocus()
    self.frame:SetScript("OnShow", nil)
  end,

  ["SetFocus"] = function(self)
    self.editbox:SetFocus()
    if not self.frame:IsShown() then
      self.frame:SetScript("OnShow", Frame_OnShowFocus)
    end
  end,

  ["HighlightText"] = function(self, from, to)
    self.editbox:HighlightText(from, to)
  end
}


local eventCallbacks = {
  OnEditFocusGained = "OnEditFocusGained",
  OnEditFocusLost = "OnEditFocusLost",
  OnEnterPressed = "OnEnterPressed",
  OnShow = "OnShow"
}

local function EventHandler(frame, event)
  local self = frame.obj
  local option = self.userdata.option
  if option and option.callbacks and option.callbacks[event] then
    option.callbacks[event](self)
  end
end

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local num  = AceGUI:GetNextWidgetNum(Type)
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:Hide()

  local editbox = CreateFrame("EditBox", string.format("WeakAurasInputWithIndentation%uEdit", format(num)), frame, "InputBoxTemplate")
  editbox:SetAutoFocus(false)
  editbox:SetFontObject(ChatFontNormal)
  editbox:SetScript("OnEnter", Control_OnEnter)
  editbox:SetScript("OnLeave", Control_OnLeave)
  editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
  editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
  editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)
  editbox:SetScript("OnReceiveDrag", EditBox_OnReceiveDrag)
  editbox:SetScript("OnMouseDown", EditBox_OnReceiveDrag)
  editbox:SetScript("OnEditFocusGained", EditBox_OnFocusGained)
  editbox:SetTextInsets(0, 0, 3, 3)
  editbox:SetMaxLetters(256)
  editbox:SetPoint("BOTTOMLEFT", 6, 0)
  editbox:SetPoint("BOTTOMRIGHT")
  editbox:SetHeight(19)

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", 0, -2)
  label:SetPoint("TOPRIGHT", 0, -2)
  label:SetJustifyH("LEFT")
  label:SetHeight(18)

  local button = CreateFrame("Button", nil, editbox, "UIPanelButtonTemplate")
  button:SetWidth(40)
  button:SetHeight(20)
  button:SetPoint("RIGHT", -2, 0)
  button:SetText(OKAY)
  button:SetScript("OnClick", Button_OnClick)
  button:Hide()

  local widget = {
    alignoffset = 30,
    editbox     = editbox,
    label       = label,
    button      = button,
    frame       = frame,
    type        = Type
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  editbox.obj, button.obj = widget, widget

  for event, callback in pairs(eventCallbacks) do
    widget.editbox:HookScript(event, function(frame) EventHandler(frame, callback) end)
  end

  local GetText = widget.editbox.GetText
  widget.editbox.GetText = function(self)
    return IndentationLib.decode(GetText(self))
  end

  local SetText = widget.editbox.SetText
  widget.editbox.SetText = function(self, text)
    SetText(self, IndentationLib.encode(text))
  end

  return AceGUI:RegisterAsWidget(widget)
end


AceGUI:RegisterWidgetType(Type, Constructor, Version)
