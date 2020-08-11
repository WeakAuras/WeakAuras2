if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local tinsert, tremove, wipe = table.insert, table.remove, wipe
local pairs, type, error = pairs, type, error
local _G = _G

-- WoW APIs
local GetScreenWidth, GetScreenHeight, CreateFrame, GetAddOnInfo, PlaySound, IsAddOnLoaded, LoadAddOn, UnitName
  = GetScreenWidth, GetScreenHeight, CreateFrame, GetAddOnInfo, PlaySound, IsAddOnLoaded, LoadAddOn, UnitName

local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local displayButtons = WeakAuras.displayButtons
local loaded = WeakAuras.loaded
local regionOptions = WeakAuras.regionOptions
local savedVars = WeakAuras.savedVars
local tempGroup = WeakAuras.tempGroup
local prettyPrint = WeakAuras.prettyPrint
local aceOptions = WeakAuras.aceOptions

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

  local handle = CreateFrame("BUTTON", nil, frame)
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

function WeakAuras.CreateFrame()
  local WeakAuras_DropDownMenu = CreateFrame("frame", "WeakAuras_DropDownMenu", nil, "UIDropDownMenuTemplate")
  local frame
  local db = savedVars.db
  local odb = savedVars.odb
  -------- Mostly Copied from AceGUIContainer-Frame--------
  frame = CreateFrame("FRAME", "WeakAurasOptions", UIParent)
  tinsert(UISpecialFrames, frame:GetName())
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  frame:SetBackdropColor(0, 0, 0, 1)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:SetResizable(true)
  frame:SetMinResize(minWidth, minHeight)
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
    WeakAuras.ClearFakeStates()
    WeakAuras.SetDragging()

    local tutFrame = WeakAuras.TutorialsFrame and WeakAuras.TutorialsFrame()
    if tutFrame and tutFrame:IsVisible() then
      tutFrame:Hide()
    end

    WeakAuras.PauseAllDynamicGroups()

    for id, data in pairs(WeakAuras.regions) do
      data.region:Collapse()
      data.region:OptionsClosed()
      if WeakAuras.clones[id] then
        for cloneId, cloneRegion in pairs(WeakAuras.clones[id]) do
          cloneRegion:Collapse()
          cloneRegion:OptionsClosed()
        end
      end
    end

    WeakAuras.ResumeAllDynamicGroups()
    WeakAuras.ReloadAll()
    WeakAuras.Resume()

    if WeakAuras.mouseFrame then
      WeakAuras.mouseFrame:OptionsClosed()
    end

    if WeakAuras.personalRessourceDisplayFrame then
      WeakAuras.personalRessourceDisplayFrame:OptionsClosed()
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

  local closebutton = CreateFrame("BUTTON", nil, close, "UIPanelCloseButton")
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

  CreateFrameSizer(frame, commitWindowChanges, "BOTTOMLEFT")
  CreateFrameSizer(frame, commitWindowChanges, "BOTTOMRIGHT")

  local minimize = CreateDecoration(frame)
  minimize:SetPoint("TOPRIGHT", -65, 12)

  frame.UpdateFrameVisible = function(self)
    if self.minimized then
      self.buttonsContainer.frame:Hide()
      self.texturePicker.frame:Hide()
      self.iconPicker.frame:Hide()
      self.modelPicker.frame:Hide()
      self.importexport.frame:Hide()
      self.texteditor.frame:Hide()
      self.codereview.frame:Hide()
      if self.newView then
        self.newView.frame:Hide()
      end
      self.container.frame:Hide()

      self.loadProgress:Hide()
      self.toolbarContainer.frame:Hide()
      self.filterInput:Hide();
      self.filterInputClear:Hide();
    else
      if self.window == "default" then
        self.buttonsContainer.frame:Show()
        self.container.frame:Show()
      else
        self.buttonsContainer.frame:Hide()
        self.container.frame:Hide()
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

      if self.window == "default" then
        if self.loadProgessVisible then
          self.loadProgress:Show()
          self.toolbarContainer.frame:Hide()
          self.filterInput:Hide();
          self.filterInputClear:Hide();
        else
          self.loadProgress:Hide()
          self.toolbarContainer.frame:Show()
          self.filterInput:Show();
          self.filterInputClear:Show();
        end
      else
        self.loadProgress:Hide()
        self.toolbarContainer.frame:Hide()
        self.filterInput:Hide();
        self.filterInputClear:Hide();
      end
    end
  end

  local minimizebutton = CreateFrame("BUTTON", nil, minimize)
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

  local _, _, _, enabled, loadable = GetAddOnInfo("WeakAurasTutorials")
  if enabled and loadable then
    local tutorial = CreateDecoration(frame)
    tutorial:SetPoint("TOPRIGHT", -140, 12)

    local tutorialbutton = CreateFrame("BUTTON", nil, tutorial)
    tutorialbutton:SetWidth(30)
    tutorialbutton:SetHeight(30)
    tutorialbutton:SetPoint("CENTER", tutorial, "CENTER", 1, -1)
    tutorialbutton:SetNormalTexture("Interface\\GossipFrame\\DailyActiveQuestIcon")
    tutorialbutton:GetNormalTexture():ClearAllPoints()
    tutorialbutton:GetNormalTexture():SetSize(16, 16)
    tutorialbutton:GetNormalTexture():SetPoint("center", -2, 0)
    tutorialbutton:SetPushedTexture("Interface\\GossipFrame\\DailyActiveQuestIcon")
    tutorialbutton:GetPushedTexture():ClearAllPoints()
    tutorialbutton:GetPushedTexture():SetSize(16, 16)
    tutorialbutton:GetPushedTexture():SetPoint("center", -2, -2)
    tutorialbutton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp")
    tutorialbutton:SetScript("OnClick", function()
      if not IsAddOnLoaded("WeakAurasTutorials") then
        local loaded, reason = LoadAddOn("WeakAurasTutorials")
        if not loaded then
          reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
          prettyPrint("Tutorials could not be loaded, the addon is " .. reason)
          return
        end
      end
      WeakAuras.ToggleTutorials()
    end)
  end

  -- Right Side Container
  local container = AceGUI:Create("InlineGroup")
  container.frame:SetParent(frame)
  container.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 12)
  container.frame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -83 - WeakAuras.normalWidth * 340, -14)
  container.frame:Show()
  container.frame:SetClipsChildren(true)
  container.titletext:Hide()
  frame.container = container

  frame.texturePicker = WeakAuras.TexturePicker(frame)
  frame.iconPicker = WeakAuras.IconPicker(frame)
  frame.modelPicker = WeakAuras.ModelPicker(frame)
  frame.importexport = WeakAuras.ImportExport(frame)
  frame.texteditor = WeakAuras.TextEditor(frame)
  frame.codereview = WeakAuras.CodeReview(frame)

  frame.moversizer, frame.mover = WeakAuras.MoverSizer(frame)

  -- filter line
  local filterInput = CreateFrame("editbox", "WeakAurasFilterInput", frame, "InputBoxTemplate")
  filterInput:SetAutoFocus(false)
  filterInput:SetScript("OnTextChanged", function(...) WeakAuras.SortDisplayButtons(filterInput:GetText()) end)
  filterInput:SetScript("OnEnterPressed", function(...) filterInput:ClearFocus() end)
  filterInput:SetScript("OnEscapePressed", function(...) filterInput:SetText("") filterInput:ClearFocus() end)
  filterInput:SetHeight(15)
  filterInput:SetPoint("TOP", frame, "TOP", 0, -34)
  filterInput:SetPoint("LEFT", frame, "LEFT", 24, 0)
  filterInput:SetPoint("RIGHT", container.frame, "LEFT", -5, 0)
  filterInput:SetTextInsets(16, 16, 0, 0)

  local searchIcon = filterInput:CreateTexture(nil, "overlay")
  searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
  searchIcon:SetVertexColor(0.6, 0.6, 0.6)
  searchIcon:SetWidth(14)
  searchIcon:SetHeight(14)
  searchIcon:SetPoint("left", filterInput, "left", 2, -2)
  filterInput:SetFont(STANDARD_TEXT_FONT, 10)
  frame.filterInput = filterInput
  filterInput:Hide()

  local filterInputClear = CreateFrame("BUTTON", nil, filterInput)
  frame.filterInputClear = filterInputClear
  filterInputClear:SetWidth(12)
  filterInputClear:SetHeight(12)
  filterInputClear:SetPoint("RIGHT", filterInput, "RIGHT", -4, -1)
  filterInputClear:SetNormalTexture("Interface\\Common\\VoiceChat-Muted")
  filterInputClear:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp")
  filterInputClear:SetScript("OnClick", function() filterInput:SetText("") filterInput:ClearFocus() end)
  filterInputClear:Hide()

  -- Left Side Container
  local buttonsContainer = AceGUI:Create("InlineGroup")
  buttonsContainer:SetWidth(170)
  buttonsContainer.frame:SetParent(frame)
  buttonsContainer.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17, 12)
  buttonsContainer.frame:SetPoint("TOP", frame, "TOP", 0, -34)
  buttonsContainer.frame:SetPoint("RIGHT", container.frame, "LEFT", -17)
  buttonsContainer.frame:Show()
  frame.buttonsContainer = buttonsContainer

  -- Toolbar
  local toolbarContainer = AceGUI:Create("SimpleGroup")
  toolbarContainer.frame:SetParent(buttonsContainer.frame)
  toolbarContainer.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -10)
  toolbarContainer.frame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -17, -10)
  toolbarContainer.frame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 20, -32)
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
  importButton:SetCallback("OnClick", WeakAuras.ImportFromString)
  toolbarContainer:AddChild(importButton)

  local magnetButton = AceGUI:Create("WeakAurasToolbarButton")
  magnetButton:SetText(L["Magnetically Align"])
  magnetButton:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\magnetic")
  magnetButton:SetStrongHighlight(true)
  magnetButton:SetCallback("OnClick", function(self)
    if WeakAurasOptionsSaved.magnetAlign then
      magnetButton:UnlockHighlight()
      WeakAurasOptionsSaved.magnetAlign = false
    else
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
    if self:GetScrollPos() ~= value then
      oldSetScroll(self, value)
      self.LayoutFunc(self.content, self.children, true)
    end
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

  local numAddons = 0

  for addon, addonData in pairs(WeakAuras.addons) do
    numAddons = numAddons + 1
  end

  if numAddons > 0 then
    local addonsButton = AceGUI:Create("WeakAurasNewHeaderButton")
    addonsButton:SetText(L["Addons"])
    addonsButton:SetDescription(L["Manage displays defined by Addons"])
    addonsButton:SetClick(function() frame:PickOption("Addons") end)
    frame.addonsButton = addonsButton
  end

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
    WeakAuras.SortDisplayButtons()
  end)
  loadedButton:SetExpandDescription(L["Expand all loaded displays"])
  loadedButton:SetCollapseDescription(L["Collapse all loaded displays"])
  loadedButton:SetViewClick(function()
    WeakAuras.PauseAllDynamicGroups()
    if loadedButton.view.func() == 2 then
      for id, child in pairs(displayButtons) do
        if loaded[id] ~= nil then
          child:PriorityHide(2)
        end
      end
    else
      for id, child in pairs(displayButtons) do
        if loaded[id] ~= nil then
          child:PriorityShow(2)
        end
      end
    end
    WeakAuras.ResumeAllDynamicGroups()
  end)
  loadedButton:SetViewTest(function()
    local none, all = true, true
    for id, child in pairs(displayButtons) do
      if loaded[id] ~= nil then
        if child:GetVisibility() ~= 2 then
          all = false
        end
        if child:GetVisibility() ~= 0 then
          none = false
        end
      end
    end
    if all then
      return 2
    elseif none then
      return 0
    else
      return 1
    end
  end)
  loadedButton:SetViewDescription(L["Toggle the visibility of all loaded displays"])
  frame.loadedButton = loadedButton

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
    WeakAuras.SortDisplayButtons()
  end)
  unloadedButton:SetExpandDescription(L["Expand all non-loaded displays"])
  unloadedButton:SetCollapseDescription(L["Collapse all non-loaded displays"])
  unloadedButton:SetViewClick(function()
    if unloadedButton.view.func() == 2 then
      for id, child in pairs(displayButtons) do
        if loaded[id] == nil then
          child:PriorityHide(2)
        end
      end
    else
      for id, child in pairs(displayButtons) do
        if loaded[id] == nil then
          child:PriorityShow(2)
        end
      end
    end
  end)
  unloadedButton:SetViewTest(function()
    local none, all = true, true
    for id, child in pairs(displayButtons) do
      if loaded[id] == nil then
        if child:GetVisibility() ~= 2 then
          all = false
        end
        if child:GetVisibility() ~= 0 then
          none = false
        end
      end
    end
    if all then
      return 2
    elseif none then
      return 0
    else
      return 1
    end
  end)
  unloadedButton:SetViewDescription(L["Toggle the visibility of all non-loaded displays"])
  frame.unloadedButton = unloadedButton


  frame.ClearOptions = function(self, id)
    aceOptions[id] = nil
    if type(id) == "string" then
      local data = WeakAuras.GetData(id)
      if data and data.parent then
        frame:ClearOptions(data.parent)
      end
      for _, tmpId in ipairs(tempGroup.controlledChildren) do
        if (id == tmpId) then
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

      if data.controlledChildren then
        for _, id in ipairs(data.controlledChildren) do
          frame:ClearOptions(id)
        end
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

  frame.GetSubOptions = function(self, id, tab)
    return aceOptions[id] and aceOptions[id][tab]
  end

  frame.EnsureOptions = function(self, data, tab)
    local id = data.id
    aceOptions[id] = aceOptions[id] or {}
    if not aceOptions[id][tab] then
      local optionsGenerator =
      {
        group = WeakAuras.GetGroupOptions,
        region =  WeakAuras.GetDisplayOptions,
        trigger = WeakAuras.GetTriggerOptions,
        conditions = WeakAuras.GetConditionOptions,
        load = WeakAuras.GetLoadOptions,
        action = WeakAuras.GetActionOptions,
        animation = WeakAuras.GetAnimationOptions,
        authorOptions = WeakAuras.GetAuthorOptions
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

    frame:UpdateOptions()

    local data
    if type(self.pickedDisplay) == "string" then
      data = WeakAuras.GetData(frame.pickedDisplay)
    elseif self.pickedDisplay then
      data = tempGroup
    end

    local tabsWidget

    container:ReleaseChildren()
    container:SetLayout("Fill")
    tabsWidget = AceGUI:Create("TabGroup")

    local tabs = {
      { value = "region", text = L["Display"]},
      { value = "trigger", text = L["Trigger"]},
      { value = "conditions", text = L["Conditions"]},
      { value = "load", text = L["Load"]},
      { value = "action", text = L["Actions"]},
      { value = "animation", text = L["Animations"]},
      { value = "authorOptions", text = L["Custom Options"]}
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

    self:ClearOptions(tempGroup.id)
    self:FillOptions()
  end

  frame.ClearPicks = function(self, noHide)
    WeakAuras.PauseAllDynamicGroups()

    frame.pickedDisplay = nil
    frame.pickedOption = nil
    wipe(tempGroup.controlledChildren)
    for id, button in pairs(displayButtons) do
      button:ClearPick(noHide)
    end
    --newButton:ClearPick(noHide)
    if frame.addonsButton then
      frame.addonsButton:ClearPick(noHide)
    end
    loadedButton:ClearPick(noHide)
    unloadedButton:ClearPick(noHide)
    container:ReleaseChildren()
    self.moversizer:Hide()

    WeakAuras.ResumeAllDynamicGroups()
  end

  local function GetTarget(pickedDisplay)
    local targetId
    if pickedDisplay then
      if type(pickedDisplay) == "table" and tempGroup.controlledChildren and tempGroup.controlledChildren[1] then
        targetId = tempGroup.controlledChildren[1]
      elseif type(pickedDisplay) == "string" then
        targetId = pickedDisplay
      end
    end
    return targetId
  end

  frame.NewAura = function(self, fromGroup)
    local targetId = GetTarget(self.pickedDisplay)
    self:ClearPicks()
    if targetId then
      local pickedButton = WeakAuras.GetDisplayButton(targetId)
      if pickedButton then
        pickedButton:Pick()
      end
    end
    self.moversizer:Hide()
    self.pickedOption = "New"

    local containerScroll = AceGUI:Create("ScrollFrame")
    containerScroll:SetLayout("flow")
    container:SetLayout("fill")
    container:AddChild(containerScroll)

    if GetAddOnEnableState(UnitName("player"), "WeakAurasTemplates") ~= 0 then
      local simpleLabel = AceGUI:Create("Label")
      simpleLabel:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
      simpleLabel:SetColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
      simpleLabel:SetText(L["Simple"])
      simpleLabel:SetFullWidth(true)
      containerScroll:AddChild(simpleLabel)

      local button = AceGUI:Create("WeakAurasNewButton")
      button:SetTitle(L["From Template"])
      button:SetDescription(L["Offer a guided way to create auras for your character"])
      button:SetIcon("Interface\\Icons\\INV_Misc_Book_06")
      button:SetClick(function()
        WeakAuras.OpenTriggerTemplate(nil, targetId)
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
    for regionType, regionData in pairs(regionOptions) do
      tinsert(regionTypesSorted, regionType)
    end

    table.sort(regionTypesSorted, function(a, b)
      return regionOptions[a].displayName < regionOptions[b].displayName
    end)

    for index, regionType in ipairs(regionTypesSorted) do
      local regionData = regionOptions[regionType]
      if (not (fromGroup and (regionType == "group" or regionType == "dynamicgroup"))) then
        local button = AceGUI:Create("WeakAurasNewButton")
        button:SetTitle(regionData.displayName)
        if(type(regionData.icon) == "string" or type(regionData.icon) == "table") then
          button:SetIcon(regionData.icon)
        end
        button:SetDescription(regionData.description)
        button:SetClick(function()
          WeakAuras.NewAura(nil, regionType, targetId)
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
      local thumbnail = regionOptions["text"].createThumbnail(UIParent)
      regionOptions["text"].modifyThumbnail(UIParent, thumbnail, data)
      thumbnail.mask:SetPoint("BOTTOMLEFT", thumbnail, "BOTTOMLEFT", 3, 3)
      thumbnail.mask:SetPoint("TOPRIGHT", thumbnail, "TOPRIGHT", -3, -3)
      frame.importThumbnail = thumbnail
    end

    importButton:SetIcon(frame.importThumbnail)
    importButton:SetDescription(L["Import a display from an encoded string"])
    importButton:SetClick(WeakAuras.ImportFromString)
    containerScroll:AddChild(importButton)
  end

  frame.PickOption = function(self, option, fromGroup)
    local targetId = GetTarget(self.pickedDisplay)
    self:ClearPicks()
    if targetId then
      local pickedButton = WeakAuras.GetDisplayButton(targetId)
      if pickedButton then
        pickedButton:Pick()
      end
    end
    self.moversizer:Hide()
    self.pickedOption = option
    if option == "Addons" then
      frame.addonsButton:Pick()

      local containerScroll = AceGUI:Create("ScrollFrame")
      containerScroll:SetLayout("AbsoluteList")
      container:SetLayout("fill")
      container:AddChild(containerScroll)

      WeakAuras.CreateImportButtons()
      WeakAuras.SortImportButtons(containerScroll)
    else
      error("An options button other than New or Addons was selected... but there are no other options buttons!")
    end
  end

  frame.PickDisplay = function(self, id, tab, noHide)
    if self.pickedDisplay == id then
      return
    end
    self:ClearPicks(noHide)
    local data = WeakAuras.GetData(id)

    displayButtons[id]:Pick()
    self.pickedDisplay = id

    if data.parent then
      if not displayButtons[data.parent]:GetExpanded() then
        displayButtons[data.parent]:Expand()
      end
    end
    if loaded[id] ~= nil then
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
    if data.controlledChildren then
      for index, childId in pairs(data.controlledChildren) do
        displayButtons[childId]:PriorityShow(1)
      end
    end

    if data.controlledChildren and #data.controlledChildren == 0 then
      WeakAurasOptions:NewAura(true)
    end
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
        if WeakAuras.GetData(self.pickedDisplay).controlledChildren then
          wasGroup = true
        elseif not WeakAuras.IsDisplayPicked(id) then
          tinsert(tempGroup.controlledChildren, self.pickedDisplay)
        end
      end
      if wasGroup then
        self:PickDisplay(id)
      elseif not WeakAuras.IsDisplayPicked(id) then
        self.pickedDisplay = tempGroup
        displayButtons[id]:Pick()
        tinsert(tempGroup.controlledChildren, id)
        WeakAuras.ClearOptions(tempGroup.id)
        self:FillOptions()
      end
    end
  end

  frame.PickDisplayBatch = function(self, batchSelection)
    for index, id in ipairs(batchSelection) do
      local alreadySelected = false
      for _, v in pairs(tempGroup.controlledChildren) do
        if v == id then
          alreadySelected = true
          break
        end
      end
      if not alreadySelected then
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
