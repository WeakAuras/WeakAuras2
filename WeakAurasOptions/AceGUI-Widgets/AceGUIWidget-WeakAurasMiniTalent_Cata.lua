if not WeakAuras.IsLibsOK() then
  return
end

local widgetType, widgetVersion = "WeakAurasMiniTalent", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(widgetType) or 0) >= widgetVersion then
  return
end
local L = WeakAuras.L

local buttonSize = 32
local buttonSizePadded = 45

local function CreateTalentButton(parent)
  local button = CreateFrame("Button", nil, parent)
  button.obj = parent
  button:SetSize(buttonSize, buttonSize)

  local cover = button:CreateTexture(nil, "OVERLAY")
  cover:SetTexture("interface/buttons/checkbuttonglow")
  cover:SetPoint("CENTER")
  cover:SetSize(buttonSize + 20, buttonSize + 20)
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
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetTalent(self.tab, self.index - (self.tab - 1) * MAX_NUM_TALENTS, false, false, false, false)
  end)
  button:Clear()
  return button
end

local function Button_ShowToolTip(self)
  if self.spellId then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellId)
  end
end
local function Button_HideToolTip(self)
  GameTooltip:Hide()
end

local function TalentFrame_Update(self)
  local buttonShownCount = 0
  if self.list then
    for _, button in ipairs(self.buttons) do
      local data = self.list[button.index]
      if not data then
        button:Hide()
      else
        local icon, tier, column, spellId = unpack(data)
        if spellId == nil then
          local talentId = button.index - (button.tab - 1) * MAX_NUM_TALENTS
          local name = GetTalentInfo(button.tab, talentId)
          print("Please report on WeakAuras Discord:\nspell missing", button.tab, tier, column, name)
        end
        button.tier = tier
        button.column = column
        button:SetNormalTexture(icon)
        button.spellId = spellId
        button:UpdateTexture()
        button:ClearAllPoints()
        button:SetScript("OnEnter", Button_ShowToolTip)
        button:SetScript("OnLeave", Button_HideToolTip)
        button:SetMotionScriptsWhileDisabled(true)
        if self.open then
          button:SetPoint("TOPLEFT", button.obj, "TOPLEFT", buttonSizePadded * (column - 1) + (button.tab - 1) * buttonSizePadded * 4 + 5, -buttonSizePadded * (tier - 1) - 5)
          button:SetEnabled(true)
          button:SetMouseClickEnabled(true)
          button:Show()
        else
          if button.state ~= nil then
            buttonShownCount = buttonShownCount + 1
            button:SetPoint(
              "TOPLEFT",
              button.obj,
              "TOPLEFT",
              7 + ((buttonShownCount - 1) % 7) * (buttonSizePadded + 4),
              -7 + -1 * (ceil(buttonShownCount / 7) - 1) * (buttonSizePadded + 4)
            )
            button:SetEnabled(false)
            button:SetMouseClickEnabled(false)
            button:Show()
          else
            button:Hide()
          end
        end
      end
    end
  end
  if self.open then
    self.frame:SetHeight(self.saveSize.fullHeight)
  else
    local rows = ceil(buttonShownCount / 7)
    if rows > 0 then
      self.frame:SetHeight(self.saveSize.collapsedRowHeight * rows)
    else
      self.frame:SetHeight(1)
    end
  end
  if self.list then
    local backgroundIndex = MAX_NUM_TALENTS * GetNumTalentTabs() + 1
    for tab = 1, GetNumTalentTabs() do
      local background = self.backgrounds[tab]
      local texture = self.list[backgroundIndex][tab]
      local base = "Interface\\TalentFrame\\" .. texture .. "-"
      background:SetTexture(base .. "TopLeft")
      if self.open then
        background:Show()
      else
        background:Hide()
      end
    end
  end
end

local methods = {
  OnAcquire = function(self)
    self:SetDisabled(false)
  end,

  OnRelease = function(self)
    self:SetDisabled(true)
    self:SetMultiselect(false)
    self.value = nil
    self.list = nil
  end,

  SetList = function(self, list)
    self.list = list or {}
    TalentFrame_Update(self)
  end,

  SetDisabled = function(self, disabled)
    if disabled then
      for _, button in pairs(self.buttons) do
        button:Hide()
      end
      for _, background in pairs(self.backgrounds) do
        background:Hide()
      end
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

  ToggleView = function(self)
    if not self.open then
      self.open = true
    else
      self.open = nil
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
  for i = 1, MAX_NUM_TALENTS * GetNumTalentTabs() do
    local button = CreateTalentButton(talentFrame)
    button.index = i
    button.tab = ceil(i / MAX_NUM_TALENTS)
    table.insert(buttons, button)
  end
  local backgrounds = {}
  for tab = 1, GetNumTalentTabs() do
    local background = talentFrame:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", talentFrame, "TOPLEFT", (tab - 1) * buttonSizePadded * 4, 0)
    background:SetPoint("BOTTOMRIGHT", talentFrame, "BOTTOMLEFT", tab * buttonSizePadded * 4, 0)
    background:SetTexCoord(0, 1, 0, 1)
    background:Show()
    table.insert(backgrounds, background)
  end
  -- rescale buttons and resize frame to fit in weakauras options
  local width = buttonSizePadded * 4 * 3 + 10
  local height = buttonSizePadded * 7 + 10
  local finalWidth = 440
  local scale = (finalWidth / width)
  local finalHeight = height * scale
  for _, button in ipairs(buttons) do
    button:SetScale(scale)
  end
  for _, background in ipairs(backgrounds) do
    background:SetScale(scale)
  end
  talentFrame:SetSize(finalWidth, finalHeight)
  talentFrame:SetScript("OnClick", function(self)
    self.obj:ToggleView()
  end)

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
    backgrounds = backgrounds,
    saveSize = {
      fullWidth = finalWidth,
      fullHeight = finalHeight,
      collapsedRowHeight = (buttonSizePadded + 5) * scale,
    },
  }

  for method, func in pairs(methods) do
    widget[method] = func
  end
  talentFrame.obj = widget

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
