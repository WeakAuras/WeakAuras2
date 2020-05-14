--[[-----------------------------------------------------------------------------
SnippetButton Widget, based on AceGUI Button (and WA ToolbarButton)
Graphical Button.
-------------------------------------------------------------------------------]]
local Type, Version = "WeakAurasSnippetButton", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
  return
end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local _G = _G
local PlaySound, CreateFrame, UIParent = PlaySound, CreateFrame, UIParent

local L = WeakAuras.L

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Button_OnClick(frame, ...)
  if ... == "RightButton" and frame.editable then
    AceGUI:ClearFocus()
    PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
    frame.title:Hide()
    frame.renameEditBox:Show()
    frame.renameEditBox:Enable()
    frame.renameEditBox:SetText(frame.title:GetText())
    frame.renameEditBox:HighlightText()
    frame.renameEditBox:SetFocus()
  elseif ... == "LeftButton" then
    AceGUI:ClearFocus()
    PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
    frame.obj:Fire("OnClick", ...)
  end
end

local function Control_OnEnter(frame)
  local tooltip = GameTooltip
  tooltip:SetOwner(frame, "ANCHOR_RIGHT")
  tooltip:ClearLines()
  if frame.editable then
    tooltip:AddDoubleLine(frame.titleText, L["(Right click to rename)"], nil, nil, nil, 0.6, 0.6, 0.6)
  else
    tooltip:AddLine(frame.titleText)
  end
  tooltip:AddLine("   ")
  tooltip:AddLine(frame.descriptionText, 0.8, 0.8, 0.8)
  tooltip:Show()
  frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
  GameTooltip:Hide()
  frame.obj:Fire("OnLeave")
end

local function rename_complete(self, ...)
  self:ClearFocus()
  AceGUI:ClearFocus()
  self:Disable()
  self:Hide()
  self:GetParent().obj:Fire("OnEnterPressed", ...)
end
--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    -- restore default values
    self:SetDisabled(false)
    self:SetTitle()
    self:SetEditable(false)
  end,
  -- ["OnRelease"] = nil,

  ["SetTitle"] = function(self, text)
    self.frame.titleText = text
    self.title:SetText(text)
  end,
  ["SetDescription"] = function(self, text)
    self.frame.descriptionText = text
  end,
  ["SetDisabled"] = function(self, disabled)
    self.disabled = disabled
    if disabled then
      self.frame:Disable()
    else
      self.frame:Enable()
    end
  end,
  ["LockHighlight"] = function(self)
    self.frame:LockHighlight()
  end,
  ["UnlockHighlight"] = function(self)
    self.frame:UnlockHighlight()
  end,
  ["SetEditable"] = function(self, editable)
    if editable then
      self.frame.editable = true
      self.deleteButton:Show()
      self.title:SetPoint("RIGHT", self.deleteButton, "LEFT")
    else
      self.frame.editable = false
      self.deleteButton:Hide()
      self.title:SetPoint("RIGHT", self.deleteButton, "RIGHT", 4, 0)
    end
  end,
  ["SetNew"] = function(self, new)
    if new then
      AceGUI:ClearFocus()
      self.title:Hide()
      self.renameEditBox:Show()
      self.renameEditBox:Enable()
      self.renameEditBox:SetText(self.title:GetText())
      self.renameEditBox:HighlightText()
      self.renameEditBox:SetFocus()
    end
  end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local name = "WeakAurasSnippetButton" .. AceGUI:GetNextWidgetNum(Type)
  local button = CreateFrame("Button", name, UIParent, "OptionsListButtonTemplate")
  button:Hide()

  button:EnableMouse(true)
  button:SetScript("OnClick", Button_OnClick)
  button:SetScript("OnEnter", Control_OnEnter)
  button:SetScript("OnLeave", Control_OnLeave)

  button:SetHeight(24)
  button:SetWidth(170)

  local deleteButton = CreateFrame("BUTTON", nil, button)
  deleteButton:SetPoint("RIGHT", button, "RIGHT", -3, 0)
  deleteButton:SetSize(20, 20)
  local deleteTex = deleteButton:CreateTexture()
  deleteTex:SetAllPoints()
  deleteTex:SetTexture([[Interface\Buttons\CancelButton-Up]])
  deleteTex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  deleteButton:SetNormalTexture(deleteTex)
  deleteButton:Hide()
  button.deleteButton = deleteButton

  local title = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetHeight(14)
  title:SetJustifyH("LEFT")
  title:SetPoint("LEFT", button, "LEFT", 3, 0)
  title:SetPoint("RIGHT", deleteButton, "LEFT")
  title:SetTextColor(1, 1, 1, 1)
  button.title = title

  local ntex = button:CreateTexture()
  ntex:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
  ntex:SetVertexColor(0.8, 0.8, 0.8, 0.25)
  ntex:SetPoint("TOPLEFT", 0, -1)
  ntex:SetPoint("BOTTOMRIGHT", 0, 1)
  button:SetNormalTexture(ntex)

  local htex = button:CreateTexture()
  htex:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
  htex:SetVertexColor(0.3, 0.5, 1, 0.5)
  htex:SetBlendMode("ADD")
  htex:SetAllPoints(ntex)
  button:SetHighlightTexture(htex)
  button.htex = htex

  local ptex = button:CreateTexture()
  ptex:SetColorTexture(1, 1, 1, 0.2)
  htex:SetAllPoints(ntex)
  button:SetPushedTexture(ptex)
  button.ptext = ptex

  local delHighlight = deleteButton:CreateTexture()
  delHighlight:SetTexture([[Interface\Buttons\CancelButton-Highlight]])
  delHighlight:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  delHighlight:SetAllPoints()
  deleteButton:SetHighlightTexture(delHighlight)
  local delPushed = deleteButton:CreateTexture()
  delPushed:SetTexture([[Interface\Buttons\CancelButton-Down]])
  delPushed:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  delPushed:SetAllPoints()
  deleteButton:SetPushedTexture(delPushed)
  button.deleteHighlight = delHighlight

  local renameEditBox = CreateFrame("EditBox", nil, button, "InputBoxTemplate")
  renameEditBox:SetHeight(14)
  renameEditBox:SetPoint("TOPLEFT", title, "TOPLEFT")
  renameEditBox:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT")
  renameEditBox:Disable()
  renameEditBox:Hide()
  renameEditBox:SetScript(
    "OnEscapePressed",
    function(self)
      self:ClearFocus()
      AceGUI:ClearFocus()
      self:Disable()
      self:Hide()
      title:Show()
    end
  )
  renameEditBox:SetScript(
    "OnEditFocusLost",
    function(self)
      self:ClearFocus()
      AceGUI:ClearFocus()
      self:Disable()
      self:Hide()
      title:Show()
    end
  )
  renameEditBox:SetScript("OnEnterPressed", rename_complete)
  button.renameEditBox = renameEditBox

  local widget = {
    title = title,
    frame = button,
    type = Type,
    htex = htex,
    ptex = ptex,
    deleteButton = deleteButton,
    renameEditBox = renameEditBox
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
