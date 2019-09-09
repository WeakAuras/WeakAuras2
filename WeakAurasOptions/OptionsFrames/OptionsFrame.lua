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
local displayOptions = WeakAuras.displayOptions
local loaded = WeakAuras.loaded
local regionOptions = WeakAuras.regionOptions
local savedVars = WeakAuras.savedVars
local tempGroup = WeakAuras.tempGroup
local prettyPrint = WeakAuras.prettyPrint

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

local function CreateDecorationWide(frame)
  local deco1 = frame:CreateTexture(nil, "OVERLAY")
  deco1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  deco1:SetTexCoord(0.31, 0.67, 0, 0.63)
  deco1:SetSize(120, 40)

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

  local import = CreateDecoration(frame)
  import:SetPoint("TOPRIGHT", -100, 12)

  local importbutton = CreateFrame("CheckButton", nil, import, "OptionsCheckButtonTemplate")
  importbutton:SetWidth(30)
  importbutton:SetHeight(30)
  importbutton:SetPoint("CENTER", import, "CENTER", 1, -1)
  importbutton:SetHitRectInsets(0, 0, 0, 0)
  importbutton:SetChecked(db.import_disabled)
  importbutton.SetValue = function(importbutton)
    if importbutton:GetChecked() then
      PlaySound(856)
      db.import_disabled = true
    else
      PlaySound(857)
      db.import_disabled = nil
    end
    WeakAuras.RefreshTooltipButtons()
  end
  importbutton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText(L["Disable Import"])
    GameTooltip:AddLine(L["If this option is enabled, you are no longer able to import auras."], 1, 1, 1)
    GameTooltip:Show()
  end)
  importbutton:SetScript("OnLeave", GameTooltip_Hide)

  local titlebg = CreateDecorationWide(frame)
  titlebg:SetPoint("TOP", 0, 12)

  local title = CreateFrame("Frame", nil, frame)

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
  title:SetPoint("BOTTOMLEFT", titlebg, "BOTTOMLEFT", -25, 0)
  title:SetPoint("TOPRIGHT", titlebg, "TOPRIGHT", 25, 0)

  local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titletext:SetPoint("TOP", titlebg, "TOP", 0, -14)
  titletext:SetText("WeakAuras " .. WeakAuras.versionString)

  CreateFrameSizer(frame, commitWindowChanges, "BOTTOMLEFT")
  CreateFrameSizer(frame, commitWindowChanges, "BOTTOMRIGHT")

  local minimize = CreateDecoration(frame)
  minimize:SetPoint("TOPRIGHT", -65, 12)

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
      if frame.window == "default" then
        frame.buttonsContainer.frame:Show()
        frame.container.frame:Show()
      elseif frame.window == "texture" then
        frame.texturePicker.frame:Show()
      elseif frame.window == "icon" then
        frame.iconPicker.frame:Show()
      elseif frame.window == "model" and not WeakAuras.IsClassic() then
        frame.modelPicker.frame:Show()
      elseif frame.window == "importexport" then
        frame.importexport.frame:Show()
      elseif frame.window == "texteditor" then
        frame.texteditor.frame:Show()
      elseif frame.window == "codereview" then
        frame.codereview.frame:Show()
      elseif frame.window == "newView" then
        frame.newView.frame:Show()
      end
      minimizebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Up.blp")
      minimizebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-CollapseButton-Down.blp")
    else
      frame.minimized = true
      frame:SetHeight(40)
      frame.buttonsContainer.frame:Hide()
      frame.texturePicker.frame:Hide()
      frame.iconPicker.frame:Hide()
      if not WeakAuras.IsClassic() then
      frame.modelPicker.frame:Hide()
      end
      frame.importexport.frame:Hide()
      frame.texteditor.frame:Hide()
      frame.codereview.frame:Hide()
      if frame.newView then
        frame.newView.frame:Hide()
      end
      frame.container.frame:Hide()
      minimizebutton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Up.blp")
      minimizebutton:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Down.blp")
    end
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
  if not WeakAuras.IsClassic() then
    frame.modelPicker = WeakAuras.ModelPicker(frame)
  end
  frame.importexport = WeakAuras.ImportExport(frame)
  frame.texteditor = WeakAuras.TextEditor(frame)
  frame.codereview = WeakAuras.CodeReview(frame)

  frame.moversizer, frame.mover = WeakAuras.MoverSizer(frame)

  local buttonsContainer = AceGUI:Create("InlineGroup")
  buttonsContainer:SetWidth(170)
  buttonsContainer.frame:SetParent(frame)
  buttonsContainer.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17, 12)
  buttonsContainer.frame:SetPoint("TOP", frame, "TOP", 0, -14)
  buttonsContainer.frame:SetPoint("right", container.frame, "left", -17)
  buttonsContainer.frame:Show()
  frame.buttonsContainer = buttonsContainer

  local loadProgress = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  loadProgress:SetPoint("TOP", buttonsContainer.frame, "TOP", 0, -4)
  loadProgress:SetText(L["Creating options: "].."0/0")
  frame.loadProgress = loadProgress

  local filterInput = CreateFrame("editbox", "WeakAurasFilterInput", buttonsContainer.frame, "InputBoxTemplate")

  filterInput:SetAutoFocus(false)
  filterInput:SetScript("OnTextChanged", function(...) WeakAuras.SortDisplayButtons(filterInput:GetText()) end)
  filterInput:SetScript("OnEnterPressed", function(...) filterInput:ClearFocus() end)
  filterInput:SetScript("OnEscapePressed", function(...) filterInput:SetText("") filterInput:ClearFocus() end)
  filterInput:SetWidth(150)
  filterInput:SetPoint("BOTTOMLEFT", buttonsContainer.frame, "TOPLEFT", 6, -14)
  filterInput:SetPoint("TOPLEFT", buttonsContainer.frame, "TOPLEFT", 6, -2)
  filterInput:SetTextInsets(16, 0, 0, 0)

  local searchIcon = filterInput:CreateTexture(nil, "overlay")
  searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
  searchIcon:SetVertexColor(0.6, 0.6, 0.6)
  searchIcon:SetWidth(14)
  searchIcon:SetHeight(14)
  searchIcon:SetPoint("left", filterInput, "left", 2, -2)
  filterInput:SetFont(STANDARD_TEXT_FONT, 10)
  frame.filterInput = filterInput
  filterInput:Hide()

  local filterInputClear = CreateFrame("BUTTON", nil, buttonsContainer.frame)
  frame.filterInputClear = filterInputClear
  filterInputClear:SetWidth(12)
  filterInputClear:SetHeight(12)
  filterInputClear:SetPoint("left", filterInput, "right", 4, -1)
  filterInputClear:SetNormalTexture("Interface\\Common\\VoiceChat-Muted")
  filterInputClear:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp")
  filterInputClear:SetScript("OnClick", function() filterInput:SetText("") filterInput:ClearFocus() end)
  filterInputClear:Hide()

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

  -- override SetScroll to make childrens visible as needed
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

  local newButton = AceGUI:Create("WeakAurasNewHeaderButton")
  newButton:SetText(L["New"])
  newButton:SetClick(function()
    frame:PickOption("New")
  end)
  frame.newButton = newButton

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

  frame.FillOptions = function(self, optionTable, selected)
    AceConfig:RegisterOptionsTable("WeakAuras", optionTable)
    AceConfigDialog:Open("WeakAuras", container)
    -- TODO: remove this once legacy aura trigger is removed
    if selected then
      container.content.obj.children[1]:SelectTab(selected)
    end
    container:SetTitle("")
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

    WeakAuras.ReloadTriggerOptions(tempGroup)
    self:FillOptions(displayOptions[tempGroup.id])
  end

  frame.ClearPicks = function(self, noHide)
    WeakAuras.PauseAllDynamicGroups()

    frame.pickedDisplay = nil
    frame.pickedOption = nil
    wipe(tempGroup.controlledChildren)
    for id, button in pairs(displayButtons) do
      button:ClearPick(noHide)
    end
    newButton:ClearPick(noHide)
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
    if option == "New" then
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

      for regionType, regionData in pairs(regionOptions) do
        if (not (fromGroup and (regionType == "group" or regionType == "dynamicgroup"))) then
          local button = AceGUI:Create("WeakAurasNewButton")
          button:SetTitle(regionData.displayName)
          if(type(regionData.icon) == "string") then
            button:SetIcon(regionData.icon)
          elseif(type(regionData.icon) == "function") then
            button:SetIcon(regionData.icon())
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

      local thumbnail = regionOptions["text"].createThumbnail(UIParent)
      regionOptions["text"].modifyThumbnail(UIParent, thumbnail, data)
      thumbnail.mask:SetPoint("BOTTOMLEFT", thumbnail, "BOTTOMLEFT", 3, 3)
      thumbnail.mask:SetPoint("TOPRIGHT", thumbnail, "TOPRIGHT", -3, -3)

      importButton:SetIcon(thumbnail)
      importButton:SetDescription(L["Import a display from an encoded string"])
      importButton:SetClick(WeakAuras.ImportFromString)
      containerScroll:AddChild(importButton)
    elseif option == "Addons" then
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

  frame.PickDisplay = function(self, id, tab, noHide) -- TODO: remove tab parametter once legacy aura trigger is removed
    self:ClearPicks(noHide)
    local data = WeakAuras.GetData(id)

    local function finishPicking()
      displayButtons[id]:Pick()
      self.pickedDisplay = id
      local data = db.displays[id]
      -- Expand parent + loaded/unloaded if needed
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

      WeakAuras.ReloadTriggerOptions(data)
      self:FillOptions(displayOptions[id], tab) -- TODO: remove tab parametter once legacy aura trigger is removed
      WeakAuras.regions[id].region:Collapse()
      WeakAuras.regions[id].region:Expand()
      self.moversizer:SetToRegion(WeakAuras.regions[id].region, db.displays[id])
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
      WeakAuras.ResumeAllDynamicGroups()
    end

    local list = {}
    local num = 0
    if data.controlledChildren then
      for index, childId in pairs(data.controlledChildren) do
        if not displayOptions[childId] then
          list[childId] = WeakAuras.GetData(childId)
          num = num + 1
        end
      end
    end
    WeakAuras.EnsureOptions(id)
    if num > 1 then
      WeakAuras.PauseAllDynamicGroups()
      WeakAuras.BuildOptions(list, finishPicking)
    else
      WeakAuras.PauseAllDynamicGroups()
      finishPicking()
      if data.controlledChildren and #data.controlledChildren == 0 then
        WeakAurasOptions.pickedDisplay = data.id
        WeakAurasOptions:PickOption("New", true)
        WeakAurasOptions.pickedDisplay = data.id
      end
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
        WeakAuras.EnsureOptions(id)
        displayButtons[id]:Pick()
        tinsert(tempGroup.controlledChildren, id)
        WeakAuras.ReloadTriggerOptions(tempGroup)
        self:FillOptions(displayOptions[tempGroup.id])
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
        WeakAuras.EnsureOptions(id)
        displayButtons[id]:Pick()
        tinsert(tempGroup.controlledChildren, id)
      end
    end
    WeakAuras.ReloadTriggerOptions(tempGroup)
    self:FillOptions(displayOptions[tempGroup.id])
    self.pickedDisplay = tempGroup
  end

  frame.RefreshPick = function(self)
    if type(self.pickedDisplay) == "string" then
      WeakAuras.EnsureOptions(self.pickedDisplay)
      self:FillOptions(displayOptions[self.pickedDisplay])
    else
      WeakAuras.EnsureOptions(tempGroup.id)
      self:FillOptions(displayOptions[tempGroup.id])
    end
  end

  frame.RefillOptions = function(self)
    if type(self.pickedDisplay) == "string" then
      self:FillOptions(displayOptions[frame.pickedDisplay])
    elseif self.pickedDisplay then
      self:FillOptions(displayOptions[frame.pickedDisplay.id])
    end
  end

  frame:SetClampedToScreen(true)
  local w, h = frame:GetSize()
  local left, right, top, bottom = w/2,-w/2, 0, h-25
  frame:SetClampRectInsets(left, right, top, bottom)

  return frame
end
