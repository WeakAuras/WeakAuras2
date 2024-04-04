if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local pairs, next, type, unpack = pairs, next, type, unpack

local Type, Version = "WeakAurasPendingInstallButton", 3
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
  return
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
    WeakAuras.PreAdd(data.d)
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
      local option = OptionsPrivate.Private.regionOptions[self.thumbnailType]
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
      local option = OptionsPrivate.Private.regionOptions[regionType]
      if self.thumbnail.icon then
        self.thumbnail.icon:SetDesaturated(false)
      end
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

    local option = OptionsPrivate.Private.regionOptions[regionType]
    if option and option.acquireThumbnail then
      self.thumbnail = option.acquireThumbnail(button, self.data)
      if self.thumbnail.icon then
        self.thumbnail.icon:SetDesaturated(true)
      end
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
  end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
  local name = "WeakAurasPendingInstallButton" .. AceGUI:GetNextWidgetNum(Type)
  local button = CreateFrame("Button", name, UIParent)
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

  local update = CreateFrame("Button", nil, button)
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
  local tex = updateLogo:CreateTexture()
  tex:SetTexture([[Interface\AddOns\WeakAuras\Media\Textures\wagoupdate_logo.tga]])
  tex:SetAllPoints()
  updateLogo.tex = tex
  updateLogo:SetSize(24, 24)
  updateLogo:SetPoint("CENTER", update)
  updateLogo:SetFrameStrata(update:GetFrameStrata())
  updateLogo:SetFrameLevel(update:GetFrameLevel()-1)

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

  --- @type table<string, any>
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
