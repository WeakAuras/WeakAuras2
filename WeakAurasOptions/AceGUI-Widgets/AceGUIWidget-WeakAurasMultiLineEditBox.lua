if not WeakAuras.IsLibsOK() then return end

---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local Type, Version = "WeakAurasMultiLineEditBox", 37
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local GetCursorInfo, ClearCursor = GetCursorInfo, ClearCursor
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

if not AceGUIWeakAurasMultiLineEditBoxInsertLink then
  -- upgradeable hook
  hooksecurefunc("ChatEdit_InsertLink", function(...) return _G.AceGUIWeakAurasMultiLineEditBoxInsertLink(...) end)
end

function _G.AceGUIWeakAurasMultiLineEditBoxInsertLink(text)
  for i = 1, AceGUI:GetWidgetCount(Type) do
    local editbox = _G[("WeakAurasMultiLineEditBox%uEdit"):format(i)]
    if editbox and editbox:IsVisible() and editbox:HasFocus() then
      editbox:Insert(text)
      return true
    end
  end
end


local function Layout(self)
  self:SetHeight(self.numlines * 14 + (self.disablebutton and 19 or 41) + self.labelHeight)

  if self.labelHeight == 0 then
    self.scrollBar:SetPoint("TOP", self.frame, "TOP", 0, -23)
  else
    self.scrollBar:SetPoint("TOP", self.label, "BOTTOM", 0, -19)
  end

  if self.disablebutton then
    self.scrollBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 21)
    self.scrollBG:SetPoint("BOTTOMLEFT", 0, 4)
  else
    self.scrollBar:SetPoint("BOTTOM", self.button, "TOP", 0, 18)
    self.scrollBG:SetPoint("BOTTOMLEFT", self.button, "TOPLEFT")
  end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function OnClick(self)                                                     -- Button
  self = self.obj
  self.editBox:ClearFocus()
  if not self:Fire("OnEnterPressed", IndentationLib.decode(self.editBox:GetText())) then
    self.button:Disable()
  end
end

local function OnCursorChanged(self, _, y, _, cursorHeight)                      -- EditBox
  self, y = self.obj.scrollFrame, -y
  local offset = self:GetVerticalScroll()
  if y < offset then
    self:SetVerticalScroll(y)
  else
    y = y + cursorHeight - self:GetHeight()
    if y > offset then
      self:SetVerticalScroll(y)
    end
  end
end

local function OnEditFocusLost(self)                                             -- EditBox
  self:HighlightText(0, 0)
  self.obj:Fire("OnEditFocusLost")
  self.obj.scrollFrame:EnableMouseWheel(false);
end

local function OnEnter(self)                                                     -- EditBox / ScrollFrame
  self = self.obj
  if not self.entered then
    self.entered = true
    self:Fire("OnEnter")
  end
end

local function OnLeave(self)                                                     -- EditBox / ScrollFrame
  self = self.obj
  if self.entered then
    self.entered = nil
    self:Fire("OnLeave")
  end
end

local function OnMouseUp(self)                                                   -- ScrollFrame
  self = self.obj.editBox
  self:SetFocus()
  self:SetCursorPosition(self:GetNumLetters())
end

local function OnReceiveDrag(self)                                               -- EditBox / ScrollFrame
  local infoType, spellIndex, bookType, info = GetCursorInfo()
  if infoType == "spell" then
    info = OptionsPrivate.Private.ExecEnv.GetSpellName(info)
  elseif infoType ~= "item" then
    return
  end
  ClearCursor()
  self = self.obj
  local editBox = self.editBox
  if not editBox:HasFocus() then
    editBox:SetFocus()
    editBox:SetCursorPosition(editBox:GetNumLetters())
  end
  editBox:Insert(info)
  self.button:Enable()
end

local function OnSizeChanged(self, width, height)                                -- ScrollFrame
  self.obj.editBox:SetWidth(width)
end

local function OnTextChanged(self, userInput)                                    -- EditBox
  if userInput then
    self = self.obj
    self:Fire("OnTextChanged", IndentationLib.decode(self.editBox:GetText()))
    self.button:Enable()
end
end

local function OnTextSet(self)                                                   -- EditBox
  self:HighlightText(0, 0)
  self:SetCursorPosition(self:GetNumLetters())
  self:SetCursorPosition(0)
  self.obj.button:Disable()
end

local function OnVerticalScroll(self, offset)                                    -- ScrollFrame
  local editBox = self.obj.editBox
  editBox:SetHitRectInsets(0, 0, offset, editBox:GetHeight() - offset - self:GetHeight())
end

local function OnFrameShow(frame)
  if (frame.focusOnShow) then
    frame.obj.editBox:SetFocus()
    frame.focusOnShow = nil;
  end
  local self = frame.obj;
  local option = self.userdata.option;
  local numExtraButtons = 0;
  if (option and option.arg and option.arg.extraFunctions) then
    numExtraButtons = #option.arg.extraFunctions;
    for index, data in ipairs(option.arg.extraFunctions) do
      if (not self.extraButtons[index]) then
        local extraButton = CreateFrame("Button", ("%s%dExpandButton%d"):format(Type, self.widgetNum, index), frame, "UIPanelButtonTemplate")
        extraButton:SetPoint("LEFT", self.extraButtons[index - 1], "RIGHT");
        extraButton:SetHeight(22)
        extraButton:SetWidth(100);
        self.extraButtons[index] = extraButton;
      end
      local extraButton = self.extraButtons[index];
      extraButton:SetText(data.buttonLabel);
      extraButton:SetScript("OnClick", data.func);
      extraButton:Show();
    end
  end

  for i = numExtraButtons + 1, #self.extraButtons do
    self.extraButtons[i]:Hide();
  end
end

local function OnEditFocusGained(frame)
  AceGUI:SetFocus(frame.obj)
  frame.obj:Fire("OnEditFocusGained")
  frame.obj.scrollFrame:EnableMouseWheel(true);
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self.editBox:SetText("")
    self:SetDisabled(false)
    self:SetWidth(200)
    self:DisableButton(false)
    self:SetNumLines()
    self.entered = nil
    self:SetMaxLetters(0)
  end,

  ["OnRelease"] = function(self)
    self:ClearFocus()
  end,

  ["SetDisabled"] = function(self, disabled)
    local editBox = self.editBox
    if disabled then
      editBox:ClearFocus()
      editBox:EnableMouse(false)
      editBox:SetTextColor(0.5, 0.5, 0.5)
      self.label:SetTextColor(0.5, 0.5, 0.5)
      self.scrollFrame:EnableMouse(false)
      self.button:Disable()
    else
      editBox:EnableMouse(true)
      editBox:SetTextColor(1, 1, 1)
      self.label:SetTextColor(1, 0.82, 0)
      self.scrollFrame:EnableMouse(true)
    end
  end,

  ["SetLabel"] = function(self, text)
    if text and text ~= "" then
      self.label:SetText(text)
      if self.labelHeight ~= 10 then
        self.labelHeight = 10
        self.label:Show()
      end
    elseif self.labelHeight ~= 0 then
      self.labelHeight = 0
      self.label:Hide()
    end
    Layout(self)
  end,

  ["SetNumLines"] = function(self, value)
    if not value or value < 4 then
      value = 4
    end
    self.numlines = value
    Layout(self)
  end,

  ["SetText"] = function(self, text)
    self.editBox:SetText(IndentationLib.encode(text))
  end,

  ["GetText"] = function(self)
    return IndentationLib.decode(self.editBox:GetText())
  end,

  ["SetMaxLetters"] = function (self, num)
    self.editBox:SetMaxLetters(num or 0)
  end,

  ["DisableButton"] = function(self, disabled)
    self.disablebutton = disabled
    if disabled then
      self.button:Hide()
    else
      self.button:Show()
    end
    Layout(self)
  end,

  ["ClearFocus"] = function(self)
    self.editBox:ClearFocus()
    self.frame.focusOnShow = nil;
  end,

  ["SetFocus"] = function(self)
    self.editBox:SetFocus()
    if not self.frame:IsShown() then
      self.frame.focusOnShow = true;
    end
  end,

  ["HighlightText"] = function(self, from, to)
    self.editBox:HighlightText(from, to)
  end,

  ["GetCursorPosition"] = function(self)
    return self.editBox:GetCursorPosition()
  end,

  ["SetCursorPosition"] = function(self, ...)
    return self.editBox:SetCursorPosition(...)
  end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local backdrop = {
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
  insets = { left = 4, right = 3, top = 4, bottom = 3 }
}

local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:Hide()

  frame:SetScript("OnShow", OnFrameShow);
  local widgetNum = AceGUI:GetNextWidgetNum(Type)

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
  label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
  label:SetJustifyH("LEFT")
  label:SetText(ACCEPT)
  label:SetHeight(10)

  local button = CreateFrame("Button", ("%s%dButton"):format(Type, widgetNum), frame, "UIPanelButtonTemplate")
  button:SetPoint("BOTTOMLEFT", 0, 4)
  button:SetHeight(22)
  button:SetWidth(100)
  button:SetText(ACCEPT)
  button:SetScript("OnClick", OnClick)
  button:Disable()

  local extraButtons = {};
  extraButtons[0] = button;

  local scrollBG = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  scrollBG:SetBackdrop(backdrop)
  scrollBG:SetBackdropColor(0, 0, 0)
  scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4)

  local scrollFrame = CreateFrame("ScrollFrame", ("%s%dScrollFrame"):format(Type, widgetNum),
                                  frame, "UIPanelScrollFrameTemplate")
  scrollFrame:EnableMouseWheel(false);

  local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
  scrollBar:ClearAllPoints()
  scrollBar:SetPoint("TOP", label, "BOTTOM", 0, -19)
  scrollBar:SetPoint("BOTTOM", button, "TOP", 0, 18)
  scrollBar:SetPoint("RIGHT", frame, "RIGHT")

  scrollBG:SetPoint("TOPRIGHT", scrollBar, "TOPLEFT", 0, 19)
  scrollBG:SetPoint("BOTTOMLEFT", button, "TOPLEFT")

  scrollFrame:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", 5, -6)
  scrollFrame:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 4)
  scrollFrame:SetScript("OnEnter", OnEnter)
  scrollFrame:SetScript("OnLeave", OnLeave)
  scrollFrame:SetScript("OnMouseUp", OnMouseUp)
  scrollFrame:SetScript("OnReceiveDrag", OnReceiveDrag)
  scrollFrame:SetScript("OnSizeChanged", OnSizeChanged)
  scrollFrame:HookScript("OnVerticalScroll", OnVerticalScroll)

  local editBox = CreateFrame("EditBox", ("%s%dEdit"):format(Type, widgetNum), scrollFrame)
  editBox:SetAllPoints()
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetMultiLine(true)
  editBox:EnableMouse(true)
  editBox:SetAutoFocus(false)
  editBox:SetCountInvisibleLetters(false)
  editBox:SetScript("OnCursorChanged", OnCursorChanged)
  editBox:SetScript("OnEditFocusLost", OnEditFocusLost)
  editBox:SetScript("OnEnter", OnEnter)
  editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
  editBox:SetScript("OnLeave", OnLeave)
  editBox:SetScript("OnMouseDown", OnReceiveDrag)
  editBox:SetScript("OnReceiveDrag", OnReceiveDrag)
  editBox:SetScript("OnTextChanged", OnTextChanged)
  editBox:SetScript("OnTextSet", OnTextSet)
  editBox:SetScript("OnEditFocusGained", OnEditFocusGained)


  scrollFrame:SetScrollChild(editBox)

  local widget = {
    button      = button,
    extraButtons = extraButtons,
    editBox     = editBox,
    frame       = frame,
    label       = label,
    labelHeight = 10,
    numlines    = 4,
    scrollBar   = scrollBar,
    scrollBG    = scrollBG,
    scrollFrame = scrollFrame,
    type        = Type,
    widgetNum   = widgetNum,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  button.obj, editBox.obj, scrollFrame.obj = widget, widget, widget

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
