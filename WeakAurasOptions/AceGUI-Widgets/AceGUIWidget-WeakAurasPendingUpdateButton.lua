if not WeakAuras.IsCorrectVersion() then
  return
end

local AddonName, OptionsPrivate = ...
local L = WeakAuras.L

local pairs, next, type, unpack = pairs, next, type, unpack

local Type, Version = "WeakAurasPendingUpdateButton", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
  return
end

local function Hide_Tooltip()
  GameTooltip:Hide()
end

local function Show_Tooltip(owner, line1, line2)
  GameTooltip:SetOwner(owner, "ANCHOR_NONE")
  GameTooltip:SetPoint("LEFT", owner, "RIGHT")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(line1)
  GameTooltip:AddLine(line2, 1, 1, 1, 1)
  GameTooltip:Show()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(1000)
    self:SetHeight(32)
    self.hasThumbnail = false
  end,
  ["Initialize"] = function(self, id, companionData)
    self.callbacks = {}
    self.id = id
    self.companionData = companionData

    function self.callbacks.OnUpdateClick()
      WeakAuras.Import(self.companionData.encoded)
    end

    self:SetTitle(self.companionData.name)
    self.update:SetScript("OnClick", self.callbacks.OnUpdateClick)
    local data = OptionsPrivate.Private.StringToTable(self.companionData.encoded, true)
    self.data = data.d
    self.frame:EnableKeyboard(false)
    self:Enable()
    self.frame:Hide()
  end,
  ["SetLogo"] = function(self, path)
    self.frame.updateLogo.tex:SetTexture(path)
  end,
  ["SetRefreshLogo"] = function(self, path)
    self.frame.update:SetNormalTexture(path)
  end,
  ["Disable"] = function(self)
    self.background:Hide()
    self.frame:Disable()
  end,
  ["Enable"] = function(self)
    self.background:Show()
    self.frame:Enable()
    self.update:Show()
    self.update:Enable()
    self.updateLogo:Show()
    self:UpdateThumbnail()
  end,
  ["OnRelease"] = function(self)
    self:ReleaseThumbnail()
    self:Enable()
    self.title:Show()
    self.frame:SetScript("OnEnter", nil)
    self.frame:SetScript("OnLeave", nil)
    self.frame:SetScript("OnClick", nil)
    self.frame:ClearAllPoints()
    self.frame:Hide()
    self.frame = nil
    self.data = nil
  end,
  ["SetTitle"] = function(self, title)
    self.titletext = title
    self.title:SetText(title)
  end,
  ["SetClick"] = function(self, func)
    self.frame:SetScript("OnClick", func)
  end,
  ["UpdateThumbnail"] = function(self)
    if not self.hasThumbnail then
      return
    end

    if self.data.regionType ~= self.thumbnailType then
      self:ReleaseThumbnail()
      self:AcquireThumbnail()
    else
      local option = WeakAuras.regionOptions[self.thumbnailType]
      if option and option.modifyThumbnail then
        option.modifyThumbnail(self.frame, self.thumbnail, self.data)
      end
    end
  end,
  ["ReleaseThumbnail"] = function(self)
    if not self.hasThumbnail then
      return
    end
    self.hasThumbnail = false

    if self.thumbnail then
      local regionType = self.thumbnailType
      local option = WeakAuras.regionOptions[regionType]
      option.releaseThumbnail(self.thumbnail)
      self.thumbnail = nil
    end
  end,
  ["AcquireThumbnail"] = function(self)
    if self.hasThumbnail then
      return
    end

    if not self.data then
      return
    end

    self.hasThumbnail = true

    local button = self.frame
    local regionType = self.data.regionType
    self.thumbnailType = regionType

    local option = WeakAuras.regionOptions[regionType]
    if option and option.acquireThumbnail then
      self.thumbnail = option.acquireThumbnail(button, self.data)
      self:SetIcon(self.thumbnail)
    else
      self:SetIcon("Interface\\Icons\\INV_Misc_QuestionMark")
    end
  end,
  ["SetIcon"] = function(self, icon)
    self.orgIcon = icon
    if (type(icon) == "string" or type(icon) == "number") then
      self.icon:SetTexture(icon)
      self.icon:Show()
      if (self.iconRegion and self.iconRegion.Hide) then
        self.iconRegion:Hide()
      end
    else
      self.iconRegion = icon
      icon:SetAllPoints(self.icon)
      icon:SetParent(self.frame)
      icon:Show()
      self.iconRegion:Show()
      self.icon:Hide()
    end
    self.thumbnail.icon:SetDesaturated(true)
  end,
  ["OverrideIcon"] = function(self)
    self.icon:SetTexture("Interface\\Addons\\WeakAuras\\Media\\Textures\\icon.blp")
    self.icon:Show()
    if (self.iconRegion and self.iconRegion.Hide) then
      self.iconRegion:Hide()
    end
  end,
  ["RestoreIcon"] = function(self)
    self:SetIcon(self.orgIcon)
  end,
  ["Expand"] = function(self, reloadTooltip)
    self.expand:Enable()
    OptionsPrivate.SetCollapsed(self.data.id, "displayButton", "", false)
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-MinusButton-Up.blp")
    self.expand:SetPushedTexture("Interface\\BUTTONS\\UI-MinusButton-Down.blp")
    self.expand.title = L["Collapse"]
    self.expand.desc = L["Hide this group's children"]
    self.expand:SetScript("OnClick", function()
      self:Collapse(true)
    end)
    self.expand.func()
    if reloadTooltip then
      Hide_Tooltip()
      Show_Tooltip(self.frame, self.expand.title, self.expand.desc)
    end
  end,
  ["Collapse"] = function(self, reloadTooltip)
    self.expand:Enable()
    OptionsPrivate.SetCollapsed(self.data.id, "displayButton", "", true)
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Up.blp")
    self.expand:SetPushedTexture("Interface\\BUTTONS\\UI-PlusButton-Down.blp")
    self.expand.title = L["Expand"]
    self.expand.desc = L["Show this group's children"]
    self.expand:SetScript("OnClick", function()
      self:Expand(true)
    end)
    self.expand.func()
  end,
  ["SetOnExpandCollapse"] = function(self, func)
    self.expand.func = func
  end,
  ["GetExpanded"] = function(self)
    return not OptionsPrivate.IsCollapsed(self.id, "displayButton", "", true)
  end,
  ["DisableExpand"] = function(self)
    self.expand:Disable()
    self.expand.disabled = true
    self.expand.expanded = false
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Disabled.blp")
  end,
  ["EnableExpand"] = function(self)
    self.expand.disabled = false
    if (self:GetExpanded()) then
      self:Expand()
    else
      self:Collapse()
    end
  end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
  local name = "WeakAurasPendingUpdateButton" .. AceGUI:GetNextWidgetNum(Type)
  local button = CreateFrame("BUTTON", name, UIParent)
  button:SetHeight(32)
  button:SetWidth(1000)
  button.data = {}

  local background = button:CreateTexture(nil, "BACKGROUND")
  button.background = background
  background:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
  background:SetBlendMode("ADD")
  background:SetVertexColor(0.5, 1, 0.5, 0.3)
  background:SetPoint("TOP", button, "TOP")
  background:SetPoint("BOTTOM", button, "BOTTOM")
  background:SetPoint("LEFT", button, "LEFT")
  background:SetPoint("RIGHT", button, "RIGHT")

  local icon = button:CreateTexture(nil, "OVERLAY")
  button.icon = icon
  icon:SetWidth(32)
  icon:SetHeight(32)
  icon:SetPoint("LEFT", button, "LEFT")

  local title = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.title = title
  title:SetHeight(14)
  title:SetJustifyH("LEFT")
  title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0)
  title:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT")
  title:SetVertexColor(0.6, 0.6, 0.6)

  button.description = {}

  local update = CreateFrame("BUTTON", nil, button)
  button.update = update
  update.disabled = true
  update.func = function()
  end
  update:SetNormalTexture([[Interface\AddOns\WeakAuras\Media\Textures\wagoupdate_refresh.tga]])
  update:Disable()
  update:SetWidth(24)
  update:SetHeight(24)
  update:SetPoint("RIGHT", button, "RIGHT", -2, 0)

  -- Add logo
  local updateLogo = CreateFrame("Frame", nil, button)
  button.updateLogo = updateLogo
  local tex = updateLogo:CreateTexture(nil, "OVERLAY")
  tex:SetTexture([[Interface\AddOns\WeakAuras\Media\Textures\wagoupdate_logo.tga]])
  tex:SetAllPoints()
  updateLogo.tex = tex
  updateLogo:SetSize(24, 24)
  updateLogo:SetPoint("CENTER", update)

  -- Animation On Hover
  local animGroup = update:CreateAnimationGroup()
  update.animGroup = animGroup

  local animRotate = animGroup:CreateAnimation("rotation")
  animRotate:SetDegrees(-360)
  animRotate:SetDuration(1)
  animRotate:SetSmoothing("OUT")
  animGroup:SetScript("OnFinished", function()
    if (MouseIsOver(update)) then
      animGroup:Play()
    end
  end)
  update:SetScript("OnEnter", function()
    animGroup:Play()
  end)
  update:Hide()
  updateLogo:Hide()

  local widget = {
    frame = button,
    title = title,
    icon = icon,
    background = background,
    update = update,
    updateLogo = updateLogo,
    type = Type,
  }

  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
