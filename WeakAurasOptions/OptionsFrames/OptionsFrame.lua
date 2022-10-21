if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

-- Lua APIs
local tinsert, tremove, wipe = table.insert, table.remove, wipe
local pairs, type, error = pairs, type, error
local _G = _G

-- WoW APIs
local GetScreenWidth, GetScreenHeight, CreateFrame, UnitName
  = GetScreenWidth, GetScreenHeight, CreateFrame, UnitName

local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local displayButtons = OptionsPrivate.displayButtons
local tempGroup = OptionsPrivate.tempGroup
local aceOptions = {}

local function CreateDecoration(frame)
  local deco = CreateFrame("Frame", nil, frame)
  deco:SetSize(17, 40)

  local bg1 = deco:CreateTexture(nil, "BACKGROUND")
  bg1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg1:SetTexCoord(0.31, 0.67, 0, 0.63)
  bg1:SetAllPoints(deco)

  local bg2 = deco:CreateTexture(nil, "BACKGROUND")
  bg2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg2:SetTexCoord(0.235, 0.275, 0, 0.63)
  bg2:SetPoint("RIGHT", bg1, "LEFT")
  bg2:SetSize(10, 40)

  local bg3 = deco:CreateTexture(nil, "BACKGROUND")
  bg3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg3:SetTexCoord(0.72, 0.76, 0, 0.63)
  bg3:SetPoint("LEFT", bg1, "RIGHT")
  bg3:SetSize(10, 40)

  return deco
end

local function CreateDecorationWide(frame, width)
  local deco1 = frame:CreateTexture(nil, "OVERLAY")
  deco1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  deco1:SetTexCoord(0.31, 0.67, 0, 0.63)
  deco1:SetSize(width, 40)

  local deco2 = frame:CreateTexture(nil, "OVERLAY")
  deco2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  deco2:SetTexCoord(0.21, 0.31, 0, 0.63)
  deco2:SetPoint("RIGHT", deco1, "LEFT")
  deco2:SetSize(30, 40)

  local deco3 = frame:CreateTexture(nil, "OVERLAY")
  deco3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  deco3:SetTexCoord(0.67, 0.77, 0, 0.63)
  deco3:SetPoint("LEFT", deco1, "RIGHT")
  deco3:SetSize(30, 40)

  return deco1
end

local function CreateFrameSizer(frame, callback, position)
  callback = callback or (function() end)

  local left, right, top, bottom, xOffset1, yOffset1, xOffset2, yOffset2
  if position == "BOTTOMLEFT" then
    left, right, top, bottom = 1, 0, 0, 1
    xOffset1, yOffset1 = 6, 6
    xOffset2, yOffset2 = 0, 0
  elseif position == "BOTTOMRIGHT" then
    left, right, top, bottom = 0, 1, 0, 1
    xOffset1, yOffset1 = 0, 6
    xOffset2, yOffset2 = -6, 0
  elseif position == "TOPLEFT" then
    left, right, top, bottom = 1, 0, 1, 0
    xOffset1, yOffset1 = 6, 0
    xOffset2, yOffset2 = 0, -6
  elseif position == "TOPRIGHT" then
    left, right, top, bottom = 0, 1, 1, 0
    xOffset1, yOffset1 = 0, 0
    xOffset2, yOffset2 = -6, -6
  end

  local handle = CreateFrame("Button", nil, frame)
  handle:SetPoint(position, frame)
  handle:SetSize(25, 25)
  handle:EnableMouse()

  handle:SetScript("OnMouseDown", function()
    frame:StartSizing(position)
  end)

  handle:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    callback()
  end)

  local normal = handle:CreateTexture(nil, "OVERLAY")
  normal:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  normal:SetTexCoord(left, right, top, bottom)
  normal:SetPoint("BOTTOMLEFT", handle, xOffset1, yOffset1)
  normal:SetPoint("TOPRIGHT", handle, xOffset2, yOffset2)
  handle:SetNormalTexture(normal)

  local pushed = handle:CreateTexture(nil, "OVERLAY")
  pushed:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  pushed:SetTexCoord(left, right, top, bottom)
  pushed:SetPoint("BOTTOMLEFT", handle, xOffset1, yOffset1)
  pushed:SetPoint("TOPRIGHT", handle, xOffset2, yOffset2)
  handle:SetPushedTexture(pushed)

  local highlight = handle:CreateTexture(nil, "OVERLAY")
  highlight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  highlight:SetTexCoord(left, right, top, bottom)
  highlight:SetPoint("BOTTOMLEFT", handle, xOffset1, yOffset1)
  highlight:SetPoint("TOPRIGHT", handle, xOffset2, yOffset2)
  handle:SetHighlightTexture(highlight)

  return handle
end

local defaultWidth = 830
local defaultHeight = 665
local minWidth = 750
local minHeight = 240

function OptionsPrivate.CreateFrame()
  CreateFrame("Frame", "WeakAuras_DropDownMenu", nil, "UIDropDownMenuTemplate")
  local frame
  local db = OptionsPrivate.savedVars.db
  local odb = OptionsPrivate.savedVars.odb
  -------- Mostly Copied from AceGUIContainer-Frame--------
  frame = CreateFrame("Frame", "WeakAurasOptions", UIParent, "BackdropTemplate")

  tinsert(UISpecialFrames, frame:GetName())
  frame:SetBackdrop({
    bgFile = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:SetResizable(true)
  if frame.SetResizeBounds then
    frame:SetResizeBounds(minWidth, minHeight)
  else
    frame:SetMinResize(minWidth, minHeight)
  end
  frame:SetFrameStrata("DIALOG")
  frame.window = "default"

  local xOffset, yOffset
  if db.frame then
    xOffset, yOffset = db.frame.xOffset, db.frame.yOffset
  end

  if not (xOffset and yOffset) then
    xOffset = (defaultWidth - GetScreenWidth()) / 2
    yOffset = (defaultHeight - GetScreenHeight()) / 2
  end

  frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xOffset, yOffset)
  frame:Hide()

  frame:SetScript("OnHide", function()
    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()

    OptionsPrivate.Private.ClearFakeStates()


    for id, data in pairs(OptionsPrivate.Private.regions) do
      data.region:Collapse()
      data.region:OptionsClosed()
      if OptionsPrivate.Private.clones[id] then
        for _, cloneRegion in pairs(OptionsPrivate.Private.clones[id]) do
          cloneRegion:Collapse()
          cloneRegion:OptionsClosed()
        end
      end
    end

    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
    OptionsPrivate.Private.Resume()

    if OptionsPrivate.Private.mouseFrame then
      OptionsPrivate.Private.mouseFrame:OptionsClosed()
    end

    if OptionsPrivate.Private.personalRessourceDisplayFrame then
      OptionsPrivate.Private.personalRessourceDisplayFrame:OptionsClosed()
    end
  end)

  local width, height

  if db.frame then
    width, height = db.frame.width, db.frame.height
  end

  if not (width and height) then
    width, height = defaultWidth, defaultHeight
  end

  width = max(width, minWidth)
  height = max(height, minHeight)
  frame:SetWidth(width)
  frame:SetHeight(height)

  local close = CreateDecoration(frame)
  close:SetPoint("TOPRIGHT", -30, 12)

  local closebutton = CreateFrame("Button", nil, close, "UIPanelCloseButton")
  closebutton:SetPoint("CENTER", close, "CENTER", 1, -1)
  closebutton:SetScript("OnClick", WeakAuras.HideOptions)

  local title = CreateFrame("Frame", nil, frame)

  local titleText = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")

  titleText:SetText("WeakAuras " .. WeakAuras.versionString)

  local titleBG = CreateDecorationWide(frame, max(120, titleText:GetWidth()))
  titleBG:SetPoint("TOP", 0, 24)
  titleText:SetPoint("TOP", titleBG, "TOP", 0, -14)


  local function commitWindowChanges()
    local xOffset = frame:GetRight() - GetScreenWidth()
    local yOffset = frame:GetTop() - GetScreenHeight()
    if title:GetRight() > GetScreenWidth() then
      xOffset = xOffset + (GetScreenWidth() - title:GetRight())
    elseif title:GetLeft() < 0 then
      xOffset = xOffset + (0 - title:GetLeft())
    end
    if title:GetTop() > GetScreenHeight() then
      yOffset = yOffset + (GetScreenHeight() - title:GetTop())
    elseif title:GetBottom() < 0 then
      yOffset = yOffset + (0 - title:GetBottom())
    end
    db.frame = db.frame or {}
    db.frame.xOffset = xOffset
    db.frame.yOffset = yOffset
    if not frame.minimized then
      db.frame.width = frame:GetWidth()
      db.frame.height = frame:GetHeight()
    end
    frame:ClearAllPoints()
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xOffset, yOffset)
  end

  title:EnableMouse(true)
  title:SetScript("OnMouseDown", function() frame:StartMoving() end)
  title:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    commitWindowChanges()
  end)
  title:SetPoint("BOTTOMLEFT", titleBG, "BOTTOMLEFT", -25, 0)
  title:SetPoint("TOPRIGHT", titleBG, "TOPRIGHT", 25, 0)

  frame.bottomLeftResizer = CreateFrameSizer(frame, commitWindowChanges, "BOTTOMLEFT")
  frame.bottomRightResizer = CreateFrameSizer(frame, commitWindowChanges, "BOTTOMRIGHT")

  local minimize = CreateDecoration(frame)
  minimize:SetPoint("TOPRIGHT", -65, 12)

  frame.UpdateFrameVisible = function(self)
    if self.minimized then
      self.buttonsContainer.frame:Hide()
      self.texturePicker.frame:Hide()
      self.iconPicker.frame:Hide()
      self.modelPicker.frame:Hide()
      self.importexport.frame:Hide()
      self.update.frame:Hide()
      self.texteditor.frame:Hide()
      self.codereview.frame:Hide()
      self.debugLog.frame:Hide()
      if self.newView then
        self.newView.frame:Hide()
      end
      self.container.frame:Hide()

      self.loadProgress:Hide()
      self.toolbarContainer.frame:Hide()
      self.filterInput:Hide();
      self.tipFrame.frame:Hide()
      self.bottomLeftResizer:Hide()
      self.bottomRightResizer:Hide()
    else
      self.bottomLeftResizer:Show()
      self.bottomRightResizer:Show()
      if self.window == "default" then
        self.buttonsContainer.frame:Show()
        self.container.frame:Show()
        if self.tipFrameIsVisible then
          self.tipFrame.frame:Show()
        else
          self.tipFrame.frame:Hide()
        end
      else
        self.buttonsContainer.frame:Hide()
        self.container.frame:Hide()
        self.tipFrame.frame:Hide()
      end

      if self.window == "texture" then
        self.texturePicker.frame:Show()
      else
        self.texturePicker.frame:Hide()
      end

      if self.window == "icon" then
        self.iconPicker.frame:Show()
      else
        self.iconPicker.frame:Hide()
      end

      if self.window == "model" then
        self.modelPicker.frame:Show()
      else
        self.modelPicker.frame:Hide()
      end

      if self.window == "importexport" then
        self.importexport.frame:Show()
      else
        self.importexport.frame:Hide()
      end

      if self.window == "texteditor" then
        self.texteditor.frame:Show()
      else
        self.texteditor.frame:Hide()
      end

      if self.window == "codereview" then
        self.codereview.frame:Show()
      else
        self.codereview.frame:Hide()
      end
      if self.window == "newView" then
        self.newView.frame:Show()
      else
        if self.newView then
          self.newView.frame:Hide()
        end
      end
      if self.window == "update" then
        self.update.frame:Show()
      else
        self.update.frame:Hide()
      end
      if self.window == "debuglog" then
        self.debugLog.frame:Show()
      else
        self.debugLog.frame:Hide()
      end
      if self.window == "default" then
        if self.loadProgessVisible then
          self.loadProgress:Show()
          self.toolbarContainer.frame:Hide()
          self.filterInput:Hide();
        else
          self.loadProgress:Hide()
          self.toolbarContainer.frame:Show()
          self.filterInput:Show();
          --self.filterInputClear:Show();
        end
      else
        self.loadProgress:Hide()
        self.toolbarContainer.frame:Hide()
        self.filterInput:Hide();
      end
    end
  end

  local minimizebutton = CreateFrame("Button", nil, minimize)
  minimizebutton:SetWidth(30)
  minimizebutton:SetHeight(30)
  minimizebutton:SetPoint("CENTER", minimize, "CENTER", 1, -1)
  minimizebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Up.blp")
  minimizebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Down.blp")
  minimizebutton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp")
  minimizebutton:SetScript("OnClick", function()
    if frame.minimized then
      frame.minimized = nil
      if db.frame then
        if not db.frame.height or db.frame.height < 240 then
          db.frame.height = 500
        end
      end
      frame:SetHeight(db.frame and db.frame.height or 500)
      minimizebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Up.blp")
      minimizebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Down.blp")

      frame.buttonsScroll:DoLayout()
    else
      frame.minimized = true
      frame:SetHeight(40)
      minimizebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Up.blp")
      minimizebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Down.blp")
    end
    frame:UpdateFrameVisible()
  end)

  local tipFrame = AceGUI:Create("SimpleGroup")
  tipFrame.frame:SetParent(frame)
  tipFrame:SetLayout("Flow")
  tipFrame.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 15)
  tipFrame.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 15)
  tipFrame.frame:Hide()
  frame.tipFrame = tipFrame

  local tipPopup = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  tipPopup:SetFrameStrata("FULLSCREEN")
  tipPopup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  tipPopup:SetBackdropColor(0, 0, 0, 0.8)
  --tipPopup:SetHeight(100)
  tipPopup:Hide()

  local tipPopupTitle = tipPopup:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
  tipPopupTitle:SetPoint("TOPLEFT", tipPopup, "TOPLEFT", 10, -10)
  tipPopupTitle:SetPoint("TOPRIGHT", tipPopup, "TOPRIGHT", -10, -10)
  tipPopupTitle:SetJustifyH("LEFT")
  tipPopupTitle:SetJustifyV("TOP")

  local tipPopupLabel = tipPopup:CreateFontString(nil, "BACKGROUND", "GameFontWhite")
  tipPopupLabel:SetPoint("TOPLEFT", tipPopupTitle, "BOTTOMLEFT", 0, -6)
  tipPopupLabel:SetPoint("TOPRIGHT", tipPopupTitle, "BOTTOMRIGHT", 0, -6)
  tipPopupLabel:SetJustifyH("LEFT")
  tipPopupLabel:SetJustifyV("TOP")

  local urlWidget = CreateFrame("EditBox", nil, tipPopup, "InputBoxTemplate")
  urlWidget:SetFont(STANDARD_TEXT_FONT, 12, "")
  urlWidget:SetPoint("TOPLEFT", tipPopupLabel, "BOTTOMLEFT", 6, 0)
  urlWidget:SetPoint("TOPRIGHT", tipPopupLabel, "BOTTOMRIGHT", 0, 0)
  urlWidget:SetScript("OnChar", function() urlWidget:SetText(urlWidget.text); urlWidget:HighlightText(); end);
  urlWidget:SetScript("OnMouseUp", function() urlWidget:HighlightText(); end);
  urlWidget:SetScript("OnEscapePressed", function() tipPopup:Hide() end)
  urlWidget:SetHeight(34)

  local tipPopupCtrlC = tipPopup:CreateFontString(nil, "BACKGROUND", "GameFontWhite")
  tipPopupCtrlC:SetPoint("TOPLEFT", urlWidget, "BOTTOMLEFT", -6, 0)
  tipPopupCtrlC:SetPoint("TOPRIGHT", urlWidget, "BOTTOMRIGHT", 0, 0)
  tipPopupCtrlC:SetJustifyH("LEFT")
  tipPopupCtrlC:SetJustifyV("TOP")
  tipPopupCtrlC:SetText(L["Press Ctrl+C to copy the URL"])

  local function ToggleTip(referenceWidget, url, title, description)
    if tipPopup:IsVisible() and urlWidget.text == url then
      tipPopup:Hide()
      return
    end
    urlWidget.text = url
    urlWidget:SetText(url)
    tipPopupTitle:SetText(title)
    tipPopupLabel:SetText(description)
    urlWidget:HighlightText()

    tipPopup:SetWidth(400)
    tipPopup:SetHeight(26 + tipPopupTitle:GetHeight() + tipPopupLabel:GetHeight() + urlWidget:GetHeight() + tipPopupCtrlC:GetHeight())

    tipPopup:SetPoint("BOTTOMLEFT", referenceWidget.frame, "TOPLEFT", -6, 4)
    tipPopup:Show()
  end

  local addFooter = function(title, texture, url, description)
    local button = AceGUI:Create("WeakAurasToolbarButton")
    button:SetText(title)
    button:SetTexture(texture)
    button:SetCallback("OnClick", function()
      ToggleTip(button, url, title, description)
    end)
    tipFrame:AddChild(button)
  end

  addFooter(L["Get Help"], [[Interface\AddOns\WeakAuras\Media\Textures\discord.tga]], "https://discord.gg/weakauras",
            L["Chat with WeakAuras experts on our Discord server."])

  addFooter(L["Documentation"], [[Interface\AddOns\WeakAuras\Media\Textures\GitHub.tga]], "https://github.com/WeakAuras/WeakAuras2/wiki",
            L["Check out our wiki for a large collection of examples and snippets."])

  addFooter(L["Find Auras"], [[Interface\AddOns\WeakAuras\Media\Textures\wagoupdate_logo.tga]], "https://wago.io",
            L["Browse Wago, the largest collection of auras."])

  if not OptionsPrivate.Private.CompanionData.slugs then
    addFooter(L["Update Auras"], [[Interface\AddOns\WeakAuras\Media\Textures\wagoupdate_refresh.tga]], "https://weakauras.wtf",
            L["Keep your Wago imports up to date with the Companion App."])
  end

  addFooter(L["Found a Bug?"], [[Interface\AddOns\WeakAuras\Media\Textures\bug_report.tga]], "https://github.com/WeakAuras/WeakAuras2/issues/new?assignees=&labels=%F0%9F%90%9B+Bug&template=bug_report.md&title=",
            L["Report bugs on our issue tracker."])

  -- Disable for now
  --local closeTipButton = CreateFrame("Button", nil, tipFrame.frame, "UIPanelCloseButton")
  --closeTipButton:SetScript("OnClick", function()
  --  frame:HideTip()
  --end)
  --closeTipButton:SetPoint("TOPRIGHT", tipFrame.frame, "TOPRIGHT", 0, 6)
  --closeTipButton:Show()

  frame.ShowTip = function(self)
    self.tipFrameIsVisible = true
    self.tipFrame.frame:Show()
    self.buttonsContainer.frame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 17, 30)
    self.container.frame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -17, 28)
  end

  frame.HideTip = function(self)
    self.tipFrameIsVisible = false
    self.tipFrame.frame:Hide()
    self.buttonsContainer.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17, 12)
    self.container.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 10)
  end

  -- Right Side Container
  local container = AceGUI:Create("InlineGroup")
  container.frame:SetParent(frame)
  container.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 10)
  container.frame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -63 - WeakAuras.normalWidth * 340, -14)
  container.frame:Show()
  container.frame:SetClipsChildren(true)
  container.titletext:Hide()
  -- Hide the border
  container.content:GetParent():SetBackdrop(nil)
  container.content:SetPoint("TOPLEFT", 0, 0)
  container.content:SetPoint("BOTTOMRIGHT", 0, 0)
  frame.container = container

  frame.texturePicker = OptionsPrivate.TexturePicker(frame)
  frame.iconPicker = OptionsPrivate.IconPicker(frame)
  frame.modelPicker = OptionsPrivate.ModelPicker(frame)
  frame.importexport = OptionsPrivate.ImportExport(frame)
  frame.texteditor = OptionsPrivate.TextEditor(frame)
  frame.codereview = OptionsPrivate.CodeReview(frame)
  frame.update = OptionsPrivate.UpdateFrame(frame)
  frame.debugLog = OptionsPrivate.DebugLog(frame)

  frame.moversizer, frame.mover = OptionsPrivate.MoverSizer(frame)

  -- filter line
  local filterInput = CreateFrame("EditBox", "WeakAurasFilterInput", frame, "SearchBoxTemplate")
  filterInput:SetScript("OnTextChanged", function(self)
    SearchBoxTemplate_OnTextChanged(self)
    OptionsPrivate.SortDisplayButtons(filterInput:GetText())
  end)
  filterInput:SetHeight(15)
  filterInput:SetPoint("TOP", frame, "TOP", 0, -44)
  filterInput:SetPoint("LEFT", frame, "LEFT", 24, 0)
  filterInput:SetPoint("RIGHT", container.frame, "LEFT", -5, 0)
  filterInput:SetFont(STANDARD_TEXT_FONT, 10, "")
  frame.filterInput = filterInput
  filterInput:Hide()

  -- Left Side Container
  local buttonsContainer = AceGUI:Create("InlineGroup")
  buttonsContainer:SetWidth(170)
  buttonsContainer.frame:SetParent(frame)
  buttonsContainer.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17, 12)
  buttonsContainer.frame:SetPoint("TOP", frame, "TOP", 0, -46)
  buttonsContainer.frame:SetPoint("RIGHT", container.frame, "LEFT", -17)
  buttonsContainer.frame:Show()
  frame.buttonsContainer = buttonsContainer

  -- Toolbar
  local toolbarContainer = AceGUI:Create("SimpleGroup")
  toolbarContainer.frame:SetParent(buttonsContainer.frame)
  toolbarContainer.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -16)
  toolbarContainer.frame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -17, -16)
  toolbarContainer.frame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 20, -38)
  toolbarContainer:SetLayout("Flow")

  local newButton = AceGUI:Create("WeakAurasToolbarButton")
  newButton:SetText(L["New Aura"])
  newButton:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\newaura")
  toolbarContainer:AddChild(newButton)
  frame.toolbarContainer = toolbarContainer

  newButton:SetCallback("OnClick", function()
    frame:NewAura()
  end)

  local importButton = AceGUI:Create("WeakAurasToolbarButton")
  importButton:SetText(L["Import"])
  importButton:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\importsmall")
  importButton:SetCallback("OnClick", OptionsPrivate.ImportFromString)
  toolbarContainer:AddChild(importButton)

  local lockButton = AceGUI:Create("WeakAurasToolbarButton")
  lockButton:SetText(L["Lock Positions"])
  lockButton:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\lockPosition")
  lockButton:SetCallback("OnClick", function(self)
    if WeakAurasOptionsSaved.lockPositions then
      lockButton:SetStrongHighlight(false)
      lockButton:UnlockHighlight()
      WeakAurasOptionsSaved.lockPositions = false
    else
      lockButton:SetStrongHighlight(true)
      lockButton:LockHighlight()
      WeakAurasOptionsSaved.lockPositions = true
    end
  end)
  if WeakAurasOptionsSaved.lockPositions then
    lockButton:LockHighlight()
  end
  toolbarContainer:AddChild(lockButton)

  local magnetButton = AceGUI:Create("WeakAurasToolbarButton")
  magnetButton:SetText(L["Magnetically Align"])
  magnetButton:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\magnetic")
  magnetButton:SetCallback("OnClick", function(self)
    if WeakAurasOptionsSaved.magnetAlign then
      magnetButton:SetStrongHighlight(false)
      magnetButton:UnlockHighlight()
      WeakAurasOptionsSaved.magnetAlign = false
    else
      magnetButton:SetStrongHighlight(true)
      magnetButton:LockHighlight()
      WeakAurasOptionsSaved.magnetAlign = true
    end
  end)

  if WeakAurasOptionsSaved.magnetAlign then
    magnetButton:LockHighlight()
  end
  toolbarContainer:AddChild(magnetButton)

  local loadProgress = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  loadProgress:SetPoint("TOP", buttonsContainer.frame, "TOP", 0, -4)
  loadProgress:SetText(L["Creating options: "].."0/0")
  frame.loadProgress = loadProgress

  frame.SetLoadProgressVisible = function(self, visible)
    self.loadProgessVisible = visible
    self:UpdateFrameVisible()
  end


  local buttonsScroll = AceGUI:Create("ScrollFrame")
  buttonsScroll:SetLayout("ButtonsScrollLayout")
  buttonsScroll.width = "fill"
  buttonsScroll.height = "fill"
  buttonsContainer:SetLayout("fill")
  buttonsContainer:AddChild(buttonsScroll)
  buttonsScroll.DeleteChild = function(self, delete)
    for index, widget in ipairs(buttonsScroll.children) do
      if widget == delete then
        tremove(buttonsScroll.children, index)
      end
    end
    delete:OnRelease()
    buttonsScroll:DoLayout()
  end
  frame.buttonsScroll = buttonsScroll

  function buttonsScroll:GetScrollPos()
    local status = self.status or self.localstatus
    return status.offset, status.offset + self.scrollframe:GetHeight()
  end

  -- override SetScroll to make children visible as needed
  local oldSetScroll = buttonsScroll.SetScroll
  buttonsScroll.SetScroll = function(self, value)
    oldSetScroll(self, value)
    self.LayoutFunc(self.content, self.children, true)
  end

  function buttonsScroll:SetScrollPos(top, bottom)
    local status = self.status or self.localstatus
    local viewheight = self.scrollframe:GetHeight()
    local height = self.content:GetHeight()
    local move

    local viewtop = -1 * status.offset
    local viewbottom = -1 * (status.offset + viewheight)
    if top > viewtop then
      move = top - viewtop
    elseif bottom < viewbottom then
      move = bottom - viewbottom
    else
      move = 0
    end

    status.offset = status.offset - move

    self.content:ClearAllPoints()
    self.content:SetPoint("TOPLEFT", 0, status.offset)
    self.content:SetPoint("TOPRIGHT", 0, status.offset)

    status.scrollvalue = status.offset / ((height - viewheight) / 1000.0)
  end

  -- Ready to Install section
  local pendingInstallButton = AceGUI:Create("WeakAurasLoadedHeaderButton")
  pendingInstallButton:SetText(L["Ready for Install"])
  pendingInstallButton:Disable()
  pendingInstallButton:EnableExpand()
  pendingInstallButton.frame.view:Hide()
  if odb.pendingImportCollapse then
    pendingInstallButton:Collapse()
  else
    pendingInstallButton:Expand()
  end
  pendingInstallButton:SetOnExpandCollapse(function()
    if pendingInstallButton:GetExpanded() then
      odb.pendingImportCollapse = nil
    else
      odb.pendingImportCollapse = true
    end
    OptionsPrivate.SortDisplayButtons()
  end)
  pendingInstallButton:SetExpandDescription(L["Expand all pending Import"])
  pendingInstallButton:SetCollapseDescription(L["Collapse all pending Import"])
  frame.pendingInstallButton = pendingInstallButton

  -- Ready for update section
  local pendingUpdateButton = AceGUI:Create("WeakAurasLoadedHeaderButton")
  pendingUpdateButton:SetText(L["Ready for Update"])
  pendingUpdateButton:Disable()
  pendingUpdateButton:EnableExpand()
  pendingUpdateButton.frame.view:Hide()
  if odb.pendingUpdateCollapse then
    pendingUpdateButton:Collapse()
  else
    pendingUpdateButton:Expand()
  end
  pendingUpdateButton:SetOnExpandCollapse(function()
    if pendingUpdateButton:GetExpanded() then
      odb.pendingUpdateCollapse = nil
    else
      odb.pendingUpdateCollapse = true
    end
    OptionsPrivate.SortDisplayButtons()
  end)
  pendingUpdateButton:SetExpandDescription(L["Expand all pending Import"])
  pendingUpdateButton:SetCollapseDescription(L["Collapse all pending Import"])
  frame.pendingUpdateButton = pendingUpdateButton

  -- Loaded section
  local loadedButton = AceGUI:Create("WeakAurasLoadedHeaderButton")
  loadedButton:SetText(L["Loaded"])
  loadedButton:Disable()
  loadedButton:EnableExpand()
  if odb.loadedCollapse then
    loadedButton:Collapse()
  else
    loadedButton:Expand()
  end
  loadedButton:SetOnExpandCollapse(function()
    if loadedButton:GetExpanded() then
      odb.loadedCollapse = nil
    else
      odb.loadedCollapse = true
    end
    OptionsPrivate.SortDisplayButtons()
  end)
  loadedButton:SetExpandDescription(L["Expand all loaded displays"])
  loadedButton:SetCollapseDescription(L["Collapse all loaded displays"])
  loadedButton:SetViewClick(function()
    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    if loadedButton.view.visibility == 2 then
      for id, child in pairs(displayButtons) do
        if OptionsPrivate.Private.loaded[id] ~= nil then
          child:PriorityHide(2)
        end
      end
      loadedButton:PriorityHide(2)
    else
      for id, child in pairs(displayButtons) do
        if OptionsPrivate.Private.loaded[id] ~= nil then
          child:PriorityShow(2)
        end
      end
      loadedButton:PriorityShow(2)
    end
    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
  end)
  loadedButton.RecheckVisibility = function(self)
    local none, all = true, true
    for id, child in pairs(displayButtons) do
      if OptionsPrivate.Private.loaded[id] ~= nil then
        if child:GetVisibility() ~= 2 then
          all = false
        end
        if child:GetVisibility() ~= 0 then
          none = false
        end
      end
    end
    local newVisibility
    if all then
      newVisibility = 2
    elseif none then
      newVisibility = 0
    else
      newVisibility = 1
    end
    if newVisibility ~= self.view.visibility then
      self.view.visibility = newVisibility
      self:UpdateViewTexture()
    end
  end
  loadedButton:SetViewDescription(L["Toggle the visibility of all loaded displays"])
  frame.loadedButton = loadedButton

  -- Not Loaded section
  local unloadedButton = AceGUI:Create("WeakAurasLoadedHeaderButton")
  unloadedButton:SetText(L["Not Loaded"])
  unloadedButton:Disable()
  unloadedButton:EnableExpand()
  if odb.unloadedCollapse then
    unloadedButton:Collapse()
  else
    unloadedButton:Expand()
  end
  unloadedButton:SetOnExpandCollapse(function()
    if unloadedButton:GetExpanded() then
      odb.unloadedCollapse = nil
    else
      odb.unloadedCollapse = true
    end
    OptionsPrivate.SortDisplayButtons()
  end)
  unloadedButton:SetExpandDescription(L["Expand all non-loaded displays"])
  unloadedButton:SetCollapseDescription(L["Collapse all non-loaded displays"])
  unloadedButton:SetViewClick(function()
    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    if unloadedButton.view.visibility == 2 then
      for id, child in pairs(displayButtons) do
        if OptionsPrivate.Private.loaded[id] == nil then
          child:PriorityHide(2)
        end
      end
      unloadedButton:PriorityHide(2)
    else
      for id, child in pairs(displayButtons) do
        if OptionsPrivate.Private.loaded[id] == nil then
          child:PriorityShow(2)
        end
      end
      unloadedButton:PriorityShow(2)
    end
    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
  end)
  unloadedButton.RecheckVisibility = function(self)
    local none, all = true, true
    for id, child in pairs(displayButtons) do
      if OptionsPrivate.Private.loaded[id] == nil then
        if child:GetVisibility() ~= 2 then
          all = false
        end
        if child:GetVisibility() ~= 0 then
          none = false
        end
      end
    end
    local newVisibility
    if all then
      newVisibility = 2
    elseif none then
      newVisibility = 0
    else
      newVisibility = 1
    end
    if newVisibility ~= self.view.visibility then
      self.view.visibility = newVisibility
      self:UpdateViewTexture()
    end
  end
  unloadedButton:SetViewDescription(L["Toggle the visibility of all non-loaded displays"])
  frame.unloadedButton = unloadedButton


  frame.ClearOptions = function(self, id)
    aceOptions[id] = nil
    OptionsPrivate.commonOptionsCache:Clear()
    if type(id) == "string" then
      local data = WeakAuras.GetData(id)
      if data and data.parent then
        frame:ClearOptions(data.parent)
      end
      for child in OptionsPrivate.Private.TraverseAllChildren(tempGroup) do
        if (id == child.id) then
          frame:ClearOptions(tempGroup.id)
        end
      end
    end
  end

  frame.ClearAndUpdateOptions = function(self, id, clearChildren)
    frame:ClearOptions(id)

    if clearChildren then
      local data
      if type(id) == "string" then
        data = WeakAuras.GetData(id)
      elseif self.pickedDisplay then
        data = tempGroup
      end

      for child in OptionsPrivate.Private.TraverseAllChildren(data) do
        frame:ClearOptions(child.id)
      end
    end
    if (type(self.pickedDisplay) == "string" and self.pickedDisplay == id)
       or (type(self.pickedDisplay) == "table" and id == tempGroup.id)
    then
      frame:UpdateOptions()
    end
  end

  frame.UpdateOptions = function(self)
    if not self.pickedDisplay then
      return
    end
    OptionsPrivate.commonOptionsCache:Clear()
    self.selectedTab = self.selectedTab or "region"
    local data
    if type(self.pickedDisplay) == "string" then
      data = WeakAuras.GetData(frame.pickedDisplay)
    elseif self.pickedDisplay then
      data = tempGroup
    end

    if not data.controlledChildren or data == tempGroup then
      if self.selectedTab == "group" then
        self.selectedTab = "region"
      end
    end

    local optionTable = self:EnsureOptions(data, self.selectedTab)
    if optionTable then
      AceConfig:RegisterOptionsTable("WeakAuras", optionTable)
    end
  end

  frame.EnsureOptions = function(self, data, tab)
    local id = data.id
    aceOptions[id] = aceOptions[id] or {}
    if not aceOptions[id][tab] then
      local optionsGenerator =
      {
        group = OptionsPrivate.GetGroupOptions,
        region =  OptionsPrivate.GetDisplayOptions,
        trigger = OptionsPrivate.GetTriggerOptions,
        conditions = OptionsPrivate.GetConditionOptions,
        load = OptionsPrivate.GetLoadOptions,
        action = OptionsPrivate.GetActionOptions,
        animation = OptionsPrivate.GetAnimationOptions,
        authorOptions = OptionsPrivate.GetAuthorOptions,
        information = OptionsPrivate.GetInformationOptions,
      }
      if optionsGenerator[tab] then
        aceOptions[id][tab] = optionsGenerator[tab](data)
      end
    end
    return aceOptions[id][tab]
  end

  -- This function refills the options pane
  -- This is ONLY necessary if AceOptions doesn't know that it should do
  -- that automatically. That is any change that goes through the AceOptions
  -- doesn't need to call this
  -- Any changes to the options that go around that, e.g. drag/drop, group,
  -- texture pick, etc should call this
  frame.FillOptions = function(self)
    if not self.pickedDisplay then
      return
    end

    OptionsPrivate.commonOptionsCache:Clear()

    frame:UpdateOptions()

    local data
    if type(self.pickedDisplay) == "string" then
      data = WeakAuras.GetData(frame.pickedDisplay)
    elseif self.pickedDisplay then
      data = tempGroup
    end

    local tabsWidget

    container.frame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -63 - WeakAuras.normalWidth * 340, -14)
    container:ReleaseChildren()
    container:SetLayout("Fill")
    tabsWidget = AceGUI:Create("TabGroup")

    local tabs = {
      { value = "region", text = L["Display"]},
      { value = "trigger", text = L["Trigger"]},
      { value = "conditions", text = L["Conditions"]},
      { value = "action", text = L["Actions"]},
      { value = "animation", text = L["Animations"]},
      { value = "load", text = L["Load"]},
      { value = "authorOptions", text = L["Custom Options"]},
      { value = "information", text = L["Information"]},
    }
    -- Check if group and not the temp group
    if data.controlledChildren and type(data.id) == "string" then
      tinsert(tabs, 1, { value = "group", text = L["Group"]})
    end

    tabsWidget:SetTabs(tabs)
    tabsWidget:SelectTab(self.selectedTab)
    tabsWidget:SetLayout("Fill")
    container:AddChild(tabsWidget)

    local group = AceGUI:Create("WeakAurasInlineGroup")
    tabsWidget:AddChild(group)

    tabsWidget:SetCallback("OnGroupSelected", function(self, event, tab)
        frame.selectedTab = tab
        frame:FillOptions()
      end)

    AceConfigDialog:Open("WeakAuras", group)
    tabsWidget:SetTitle("")

    if data.controlledChildren and #data.controlledChildren == 0 then
      WeakAurasOptions:NewAura()
    end
  end

  frame.ClearPick = function(self, id)
    local index = nil
    for i, childId in pairs(tempGroup.controlledChildren) do
      if childId == id then
        index = i
        break
      end
    end

    tremove(tempGroup.controlledChildren, index)
    displayButtons[id]:ClearPick()

    -- Clear trigger expand state
    OptionsPrivate.ClearTriggerExpandState()

    self:ClearOptions(tempGroup.id)
    self:FillOptions()
  end

  frame.OnRename = function(self, uid, oldid, newid)
    if type(frame.pickedDisplay) == "string" and frame.pickedDisplay == oldid then
      frame.pickedDisplay = newid
    else
      for i, childId in pairs(tempGroup.controlledChildren) do
        if (childId == newid) then
          tempGroup.controlledChildren[i] = newid
        end
      end
    end
  end

  frame.ClearPicks = function(self, noHide)
    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    for id, button in pairs(displayButtons) do
      button:ClearPick(true)
      if not noHide then
        button:PriorityHide(1)
      end
    end
    if not noHide then
      for id, button in pairs(displayButtons) do
        if button.data.controlledChildren then
          button:RecheckVisibility()
        end
      end
    end

    frame.pickedDisplay = nil
    frame.pickedOption = nil
    wipe(tempGroup.controlledChildren)
    loadedButton:ClearPick(noHide)
    unloadedButton:ClearPick(noHide)
    container:ReleaseChildren()
    self.moversizer:Hide()

    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)

    -- Clear trigger expand state
    OptionsPrivate.ClearTriggerExpandState()
  end

  frame.GetTargetAura = function(self)
    if self.pickedDisplay then
      if type(self.pickedDisplay) == "table" and tempGroup.controlledChildren and tempGroup.controlledChildren[1] then
        return tempGroup.controlledChildren[1]
      elseif type(self.pickedDisplay) == "string" then
        return self.pickedDisplay
      end
    end
    return nil
  end

  frame.NewAura = function(self)
    local targetId
    local targetIsDynamicGroup

    if self.pickedDisplay then
      if type(self.pickedDisplay) == "table" and tempGroup.controlledChildren and tempGroup.controlledChildren[1] then
        targetId = tempGroup.controlledChildren[1]
        WeakAuras.PickDisplay(targetId)
      elseif type(self.pickedDisplay) == "string" then
        targetId = self.pickedDisplay
      else
        self:ClearPicks()
      end
    end

    if targetId then
      local pickedButton = OptionsPrivate.GetDisplayButton(targetId)
      if pickedButton.data.controlledChildren then
        targetIsDynamicGroup = pickedButton.data.regionType == "dynamicgroup"
      else
        local parent = pickedButton.data.parent
        local parentData = parent and WeakAuras.GetData(parent)
        targetIsDynamicGroup = parentData and parentData.regionType == "dynamicgroup"
      end
    end
    self.moversizer:Hide()
    self.pickedOption = "New"

    container:ReleaseChildren()
    container.frame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -63 - WeakAuras.normalWidth * 340, -8)
    container:SetLayout("fill")
    local border = AceGUI:Create("InlineGroup")
    border:SetLayout("Fill")
    container:AddChild(border)

    local containerScroll = AceGUI:Create("ScrollFrame")
    containerScroll:SetLayout("flow")
    border:AddChild(containerScroll)

    if GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") ~= 0 then
      local simpleLabel = AceGUI:Create("Label")
      simpleLabel:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
      simpleLabel:SetColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
      simpleLabel:SetText(L["Simple"])
      simpleLabel:SetFullWidth(true)
      containerScroll:AddChild(simpleLabel)

      local button = AceGUI:Create("WeakAurasNewButton")
      button:SetTitle(L["Premade Auras"])
      button:SetDescription(L["Offer a guided way to create auras for your character"])
      button:SetIcon("Interface\\Icons\\Inv_misc_book_09")
      button:SetClick(function()
        OptionsPrivate.OpenTriggerTemplate(nil, self:GetTargetAura())
      end)
      containerScroll:AddChild(button)

      local spacer1Label = AceGUI:Create("Label")
      spacer1Label:SetText("")
      containerScroll:AddChild(spacer1Label)

      local advancedLabel = AceGUI:Create("Label")
      advancedLabel:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
      advancedLabel:SetColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
      advancedLabel:SetText(L["Advanced"])
      advancedLabel:SetFullWidth(true)
      containerScroll:AddChild(advancedLabel)
    end

    local regionTypesSorted = {}
    for regionType, regionData in pairs(OptionsPrivate.Private.regionOptions) do
      tinsert(regionTypesSorted, regionType)
    end

    -- Sort group + dynamic group first, then the others alphabetically
    table.sort(regionTypesSorted, function(a, b)
      if (a == "group") then
        return true
      end

      if (b == "group") then
        return false
      end

      if (a == "dynamicgroup") then
        return true
      end
      if (b == "dynamicgroup") then
        return false
      end

      return OptionsPrivate.Private.regionOptions[a].displayName < OptionsPrivate.Private.regionOptions[b].displayName
    end)

    for index, regionType in ipairs(regionTypesSorted) do
      if (targetIsDynamicGroup and (regionType == "group" or regionType == "dynamicgroup")) then
        -- Dynamic groups can't contain group/dynamic groups
      else
        local regionData = OptionsPrivate.Private.regionOptions[regionType]
        local button = AceGUI:Create("WeakAurasNewButton")
        button:SetTitle(regionData.displayName)
        if(type(regionData.icon) == "string" or type(regionData.icon) == "table") then
          button:SetIcon(regionData.icon)
        end
        button:SetDescription(regionData.description)
        button:SetClick(function()
          WeakAuras.NewAura(nil, regionType, self:GetTargetAura())
        end)
        containerScroll:AddChild(button)
      end
    end

    local spacer2Label = AceGUI:Create("Label")
    spacer2Label:SetText("")
    containerScroll:AddChild(spacer2Label)

    local externalLabel = AceGUI:Create("Label")
    externalLabel:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
    externalLabel:SetColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
    externalLabel:SetText(L["External"])
    externalLabel:SetFullWidth(true)
    containerScroll:AddChild(externalLabel)

    local spacer3Label = AceGUI:Create("Label")
    spacer3Label:SetText("")
    containerScroll:AddChild(spacer3Label)

    -- Import
    local importButton = AceGUI:Create("WeakAurasNewButton")
    importButton:SetTitle(L["Import"])

    local data = {
      outline = false,
      color = {1, 1, 1, 1},
      justify = "CENTER",
      font = "Friz Quadrata TT",
      fontSize = 8,
      displayText = [[
        b4vmErLxtfM
        xu5fDEn1CEn
        vmUmJyZ4hyY
        DtnEnvBEnfz
        EnfzErLxtjx
        zNL2BUrvEWv
        MxtfwDYfMyH
        jNxtLgzEnLt
        LDNx051u25L
        tXmdmY4fDE5
      ]]
    }

    if not frame.importThumbnail then
      local thumbnail = OptionsPrivate.Private.regionOptions["text"].createThumbnail(UIParent)
      OptionsPrivate.Private.regionOptions["text"].modifyThumbnail(UIParent, thumbnail, data)
      thumbnail.mask:SetPoint("BOTTOMLEFT", thumbnail, "BOTTOMLEFT", 3, 3)
      thumbnail.mask:SetPoint("TOPRIGHT", thumbnail, "TOPRIGHT", -3, -3)
      frame.importThumbnail = thumbnail
    end

    importButton:SetIcon(frame.importThumbnail)
    importButton:SetDescription(L["Import a display from an encoded string"])
    importButton:SetClick(OptionsPrivate.ImportFromString)
    containerScroll:AddChild(importButton)
  end

  local function ExpandParents(data)
    if data.parent then
      if not displayButtons[data.parent]:GetExpanded() then
        displayButtons[data.parent]:Expand()
      end
      local parentData = WeakAuras.GetData(data.parent)
      ExpandParents(parentData)
    end
  end

  frame.PickDisplay = function(self, id, tab, noHide)
    local data = WeakAuras.GetData(id)

    -- Always expand even if already picked
    ExpandParents(data)

    if OptionsPrivate.Private.loaded[id] ~= nil then
      -- Under loaded
      if not loadedButton:GetExpanded() then
        loadedButton:Expand()
      end
    else
      -- Under Unloaded
      if not unloadedButton:GetExpanded() then
        unloadedButton:Expand()
      end
    end

    if self.pickedDisplay == id then
      return
    end

    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()

    self:ClearPicks(noHide)

    displayButtons[id]:Pick()
    self.pickedDisplay = id


    if tab then
      self.selectedTab = tab
    end
    self:FillOptions()
    WeakAuras.SetMoverSizer(id)

    local _, _, _, _, yOffset = displayButtons[id].frame:GetPoint(1)
    if not yOffset then
      yOffset = displayButtons[id].frame.yOffset
    end
    if yOffset then
      self.buttonsScroll:SetScrollPos(yOffset, yOffset - 32)
    end

    for child in OptionsPrivate.Private.TraverseAllChildren(data) do
      displayButtons[child.id]:PriorityShow(1)
    end
    displayButtons[data.id]:RecheckParentVisibility()

    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
  end

  frame.CenterOnPicked = function(self)
    if self.pickedDisplay then
      local centerId = type(self.pickedDisplay) == "string" and self.pickedDisplay or self.pickedDisplay.controlledChildren[1]

      if displayButtons[centerId] then
        local _, _, _, _, yOffset = displayButtons[centerId].frame:GetPoint(1)
        if not yOffset then
          yOffset = displayButtons[centerId].frame.yOffset
        end
        if yOffset then
          self.buttonsScroll:SetScrollPos(yOffset, yOffset - 32)
        end
      end
    end
  end

  frame.PickDisplayMultiple = function(self, id)
    if not self.pickedDisplay then
      self:PickDisplay(id)
    else
      local wasGroup = false
      if type(self.pickedDisplay) == "string" then
        if WeakAuras.GetData(self.pickedDisplay).controlledChildren or WeakAuras.GetData(id).controlledChildren then
          wasGroup = true
        elseif not OptionsPrivate.IsDisplayPicked(id) then
          tinsert(tempGroup.controlledChildren, self.pickedDisplay)
        end
      end
      if wasGroup then
        self:PickDisplay(id)
      elseif not OptionsPrivate.IsDisplayPicked(id) then
        self.pickedDisplay = tempGroup
        displayButtons[id]:Pick()
        tinsert(tempGroup.controlledChildren, id)
        OptionsPrivate.ClearOptions(tempGroup.id)
        self:FillOptions()
      end
    end
  end

  frame.PickDisplayBatch = function(self, batchSelection)
    local alreadySelected = {}
    for child in OptionsPrivate.Private.TraverseAllChildren(tempGroup) do
      alreadySelected[child.id] = true
    end

    for _, id in ipairs(batchSelection) do
      if not alreadySelected[id] then
        displayButtons[id]:Pick()
        tinsert(tempGroup.controlledChildren, id)
      end
    end
    frame:ClearOptions(tempGroup.id)
    self.pickedDisplay = tempGroup
    self:FillOptions()
  end

  frame.GetPickedDisplay = function(self)
    if type(self.pickedDisplay) == "string" then
      return WeakAuras.GetData(self.pickedDisplay)
    end
    return self.pickedDisplay
  end

  frame:SetClampedToScreen(true)
  local w, h = frame:GetSize()
  local left, right, top, bottom = w/2,-w/2, 0, h-25
  frame:SetClampRectInsets(left, right, top, bottom)

  return frame
end
