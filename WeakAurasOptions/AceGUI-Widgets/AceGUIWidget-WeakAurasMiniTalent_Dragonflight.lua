---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

if not WeakAuras.IsLibsOK() then
  return
end

local keepOpenForReload = {}

local widgetType, widgetVersion = "WeakAurasMiniTalent", 3
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(widgetType) or 0) >= widgetVersion then
  return
end
local L = WeakAuras.L

local buttonSize = 32
local buttonSizePadded = 45

local function Button_ShowToolTip(self)
  if self.spellId then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellId, false, false, true)
  end
end
local function Button_HideToolTip()
  GameTooltip:Hide()
end

local function CreateTalentButton()
  local button = CreateFrame("Button")
  button:SetSize(buttonSize, buttonSize)

  local cover = button:CreateTexture(nil, "OVERLAY")
  cover:SetTexture("interface/buttons/checkbuttonglow")
  cover:SetIgnoreParentScale(true)
  cover:SetPoint("TOPLEFT", button, "TOPLEFT", -10, 10)
  cover:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 10, -10)
  cover:SetBlendMode("ADD")
  cover:Hide()
  button.cover = cover
  button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")
  function button:Yellow()
    self.cover:Show()
    self.cover:SetVertexColor(1, 1, 0, 1)
    local normalTexture = self:GetNormalTexture()
    if normalTexture then
      normalTexture:SetVertexColor(1, 1, 1, 1)
    end
    if self.line1 then
      self.line1:Hide()
      self.line2:Hide()
    end
  end
  function button:Red()
    self.cover:Show()
    self.cover:SetVertexColor(1, 0, 0, 1)
    local normalTexture = self:GetNormalTexture()
    if normalTexture then
      normalTexture:SetVertexColor(1, 0, 0, 1)
    end
    if not self.line1 then
      local line1 = button:CreateLine()
      line1:SetColorTexture(1, 0, 0, 1)
      line1:SetStartPoint("TOPLEFT", 3, -3)
      line1:SetEndPoint("BOTTOMRIGHT", -3, 3)
      line1:SetBlendMode("ADD")
      line1:SetThickness(2)
      local line2 = button:CreateLine()
      line2:SetColorTexture(1, 0, 0, 1)
      line2:SetStartPoint("TOPRIGHT", -3, -3)
      line2:SetEndPoint("BOTTOMLEFT", 3, 3)
      line2:SetBlendMode("ADD")
      line2:SetThickness(2)
      self.line1 = line1
      self.line2 = line2
    end
    self.line1:Show()
    self.line2:Show()
  end
  function button:Clear()
    self.cover:Hide()
    local normalTexture = self:GetNormalTexture()
    if normalTexture then
      normalTexture:SetVertexColor(0.3, 0.3, 0.3, 1)
    end
    if self.line1 then
      self.line1:Hide()
      self.line2:Hide()
    end
  end
  function button:UpdateTexture()
    if self.state == nil then
      self:Clear()
    elseif self.state == true then
      self:Yellow()
    elseif self.state == false then
      self:Red()
    end
  end
  function button:SetValue(value)
    self.state = value
    self:UpdateTexture()
  end
  function button:LineGetPoint()
    if self.offset == nil then
      return "CENTER"
    elseif self.offset == "left" then
      return "RIGHT"
    elseif self.offset == "right" then
      return "LEFT"
    end
  end
  button:SetScript("OnClick", function(self)
    if self.state == true then
      self:SetValue(false)
    elseif self.state == false then
      self:SetValue(nil)
    else
      self:SetValue(true)
    end
    self.obj.obj:Fire("OnValueChanged", self.index, self.state)
  end)
  button:Clear()
  button:SetScript("OnEnter", Button_ShowToolTip)
  button:SetScript("OnLeave", Button_HideToolTip)
  button:SetMotionScriptsWhileDisabled(true)

  return button
end

local function resetLine(pool, line)
  line:Hide()
  line:ClearAllPoints()
end

local function TalentFrame_Update(self)
  local buttonShownCount = 0
  self.linePool:ReleaseAll()
  if self.list then
    for _, button in ipairs(self.buttons) do
      if self.open then
        local posX = button.posX
        local posY = - button.posY
        local point = "CENTER"
        if button.offset then
          if button.offset == "left" then
            point = "RIGHT"
          elseif button.offset == "right" then
            point = "LEFT"
          end
        else
          point = "CENTER"
        end
        button:ClearAllPoints()

        button:SetPoint(point, button.obj, "TOPLEFT", posX, posY)
        button:SetEnabled(true)
        button:SetMouseClickEnabled(true)
        button:SetSize((buttonSize/self.scale) * .5, (buttonSize/self.scale) * .5)
        button:SetScale(self.scale)
        button.cover:ClearAllPoints()
        button.cover:SetPoint("TOPLEFT", button, "TOPLEFT", -5, 5)
        button.cover:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 5, -5)
        button:Show()
        for _, target in pairs(button.targets) do
          if self.talentIdToButton[target] == nil then
            -- print("Talent connect to unknown talent", button.talentId, target)
          elseif button.offset == "right" then
            -- don't trace line for right buttons
          else
            local line = self.linePool:Acquire()
            line:SetStartPoint(button:LineGetPoint(), button)
            local targetButton = self.talentIdToButton[target]
            line:SetEndPoint(targetButton:LineGetPoint(), targetButton)
            line:SetColorTexture(1,1,1,0.2)
            line:SetThickness(1)
            line:Show()
          end
        end
      else
        if button.state ~= nil then
          buttonShownCount = buttonShownCount + 1
          button:ClearAllPoints()
          button:SetPoint(
            "TOPLEFT",
            button.obj,
            "TOPLEFT",
            7 + ((buttonShownCount - 1) % 9) * (buttonSizePadded + 4),
            -7 + -1 * (ceil(buttonShownCount / 9) - 1) * (buttonSizePadded + 4)
          )
          button:SetEnabled(false)
          button:SetMouseClickEnabled(false)
          button:SetSize(buttonSize, buttonSize)
          button:SetScale(1)
          button.cover:ClearAllPoints()
          button.cover:SetPoint("TOPLEFT", button, "TOPLEFT", -10, 10)
          button.cover:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 10, -10)
          button:Show()
        else
          button:Hide()
        end
      end
    end
  end
  if self.open then
    self.frame:SetHeight(self.saveSize.fullHeight)
    self.background:Show()
  else
    local rows = ceil(buttonShownCount / 11)
    if rows > 0 then
      self.frame:SetHeight(self.saveSize.collapsedRowHeight * rows)
    else
      self.frame:SetHeight(1)
    end
    self.background:Hide()
  end
end

local methods = {
  OnAcquire = function(self)
    self:SetDisabled(false)
    self.acquired = true
  end,

  OnRelease = function(self)
    self:SetDisabled(true)
    self:SetMultiselect(false)
    self.buttonPool:ReleaseAll()
    self.linePool:ReleaseAll()
    self.value = nil
    self.list = nil
    self.acquired = false
  end,

  SetList = function(self, list)
    self.list = list or {}
    self.buttonPool:ReleaseAll()
    self.linePool:ReleaseAll()
    self.buttons = {}
    self.talentIdToButton = {}
    local extraOffset = self.list[1000]
    for index, data in pairs(self.list) do
      if index < 999 then -- background index & extraOffset
        local button = self.buttonPool:Acquire()
        button.index = index
        button:SetParent(self.frame)
        button.obj = self.frame
        local talentId = data[1]
        button.talentId = talentId
        self.talentIdToButton[talentId] = button
        local spellId = data[2]
        button.spellId = spellId
        local icon = select(8, OptionsPrivate.Private.ExecEnv.GetSpellInfo(spellId))
        if icon then
          button:SetNormalTexture(icon)
        end
        local multiTalent, multiTalentTotal, subTreePosition = 0, 0, nil
        button.posX, button.posY, multiTalent, multiTalentTotal, subTreePosition = unpack(data[3])
        button.posX = button.posX / 10 - (extraOffset and extraOffset.offsetX or 0)
        button.posY = button.posY / 10 - (extraOffset and extraOffset.offsetY or 0)
        if multiTalentTotal > 1 then
          if multiTalent == 1 then
            button.offset = "left"
          else
            button.offset = "right"
          end
        else
          button.offset = nil
        end
        if subTreePosition then
          button.side = subTreePosition == 1 and "left" or "right"
        end
        button.targets = data[4]
        button:UpdateTexture()
        button:ClearAllPoints()
        tinsert(self.buttons, button)
      end
    end

    -- zoom both panel in their center
    local isSubTree = self.list[1001]
    local talentWidth
    local talentHeight
    local talentIconSize = 36
    local scale
    if not isSubTree then
      talentWidth = 1612
      talentHeight = 856
      local cutmid = 120
      local LeftPanelCenter = { x = (talentWidth / 2 - cutmid) / 2, y = talentHeight / 2 }
      local RightPanelCenter = { x = ((talentWidth / 2 + cutmid) + talentWidth) / 2 , y = talentHeight / 2 }
      scale = 1.3
      for _, b in pairs(self.buttons) do
        if b.posX < talentWidth / 2 then -- left panel
          b.posX = b.posX - LeftPanelCenter.x
          b.posX = b.posX * scale
          b.posX = b.posX + LeftPanelCenter.x - talentIconSize / 2
          b.posY = b.posY - LeftPanelCenter.y
          b.posY = b.posY * scale
          b.posY = b.posY + LeftPanelCenter.y * scale
        else                     -- right panel
          b.posX = b.posX - RightPanelCenter.x
          b.posX = b.posX * scale
          b.posX = b.posX + RightPanelCenter.x + talentIconSize / 2
          b.posY = b.posY - RightPanelCenter.y
          b.posY = b.posY * scale
          b.posY = b.posY + RightPanelCenter.y * scale
        end
      end
    else
      talentWidth = 200
      talentHeight = 300
      local midLeft, midRight = talentWidth / 4, (talentWidth / 4) * 3
      scale = 0.3
      for _, b in pairs(self.buttons) do
        b.posX = b.posX * scale
        b.posY = b.posY * scale
        b.posY = b.posY + 10
        if b.side == "left" then
          b.posX = b.posX + midLeft
        else
          b.posX = b.posX + midRight
        end
      end
    end
    self.scale = self.saveSize.fullWidth / talentWidth
    self.saveSize.fullHeight = talentHeight * self.scale * scale
    if self.list[999] then
      self.background:SetAtlas(self.list[999])
      self.background:SetBlendMode("ADD")
    end
    TalentFrame_Update(self)
  end,

  SetDisabled = function(self, disabled)
    if disabled then
      for _, button in pairs(self.buttons) do
        button:Hide()
      end
      self.background:Hide()
      self.open = nil
      self.toggle.frame:Hide()
      self.frame:Hide()
    else
      self.open = nil
      TalentFrame_Update(self)
      self.toggle.frame:Show()
      self.frame:Show()
    end
  end,

  SetItemValue = function(self, item, value)
    if self.buttons[item] then
      self.buttons[item]:SetValue(value)
      TalentFrame_Update(self)
    end
  end,

  SetValue = function(self, value) end,
  SetLabel = function(self, text) end,
  SetMultiselect = function(self, multi) end,

  ToggleView = function(self, force)
    if force ~= nil then
      self.open = force
    else
      if not self.open then
        self.open = true
      else
        self.open = nil
      end
    end
    TalentFrame_Update(self)
    self.parent:DoLayout()
  end,
}

local function Constructor()
  local name = widgetType .. AceGUI:GetNextWidgetNum(widgetType)

  local talentFrame = CreateFrame("Button", name, UIParent)
  talentFrame:SetFrameStrata("FULLSCREEN_DIALOG")

  local buttons = {}
  talentFrame:SetWidth(440)
  talentFrame:SetScript("OnClick", function(self)
    self.obj:ToggleView()
  end)
  local background = talentFrame:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(talentFrame)

  local toggle = AceGUI:Create("WeakAurasToolbarButton")
  toggle:SetText(L["Select Talent"])
  toggle:SetTexture("interface/buttons/ui-microbutton-talents-up")
  toggle.icon:ClearAllPoints()
  toggle.icon:SetPoint("LEFT", toggle.frame, "LEFT", 0, 10)
  toggle.icon:SetSize(28, 58)
  toggle.icon:SetScale(0.6)
  toggle.frame:SetPoint("BOTTOMRIGHT", talentFrame, "TOPRIGHT", 0, 2)
  toggle.frame:SetParent(talentFrame)
  toggle.frame.obj.text:SetVertexColor(1, 1, 1, 1)
  toggle.frame:Show()

  toggle:SetCallback("OnClick", function(self)
    local parent = self.frame:GetParent()
    parent.obj:ToggleView(parent.obj)
  end)

  local widget = {
    frame = talentFrame,
    type = widgetType,
    buttons = buttons,
    toggle = toggle,
    background = background,
    saveSize = {
      fullWidth = 440,
      fullHeight = 0,
      collapsedRowHeight = (buttonSizePadded + 5),
    },
    linePool = CreateObjectPool(
      function(pool)
        return talentFrame:CreateLine()
      end,
      resetLine
    ),
    buttonPool = CreateObjectPool(CreateTalentButton)
  }

  for method, func in pairs(methods) do
    widget[method] = func
  end
  talentFrame.obj = widget

  local function OnBeforeReload()
    if widget.acquired then
      local user = widget:GetUserDataTable()
      if user and user.path then
        keepOpenForReload[user.path[#user.path]] = widget.open
      end
    end
  end

  local function OnAfterReload()
    if widget.acquired then
      local user = widget:GetUserDataTable()
      if user and user.path then
        if keepOpenForReload[user.path[#user.path]] then
          widget:ToggleView(true)
          keepOpenForReload[user.path[#user.path]] = nil
        end
      end
    end
  end

  OptionsPrivate.Private.callbacks:RegisterCallback("BeforeReload", OnBeforeReload)
  OptionsPrivate.Private.callbacks:RegisterCallback("AfterReload", OnAfterReload)

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
