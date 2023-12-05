-- Item: Toggle
-- Some sort of checkbox for dropdown menus.
-- Does not close the pullout on click.
-- Based on the AceGUI Toggle Item. Extracts the icon from the text

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local ItemBase = LibStub("AceGUI-3.0-DropDown-ItemBase"):GetItemBase()

local widgetType = "Dropdown-Currency"
local widgetVersion = 1

local function UpdateToggle(self)
  if self.value and not self.isHeader then
    self.check:Show()
  else
    self.check:Hide()
  end
end

local function OnRelease(self)
  ItemBase.OnRelease(self)
  self:SetValue(nil)
end

local function Frame_OnClick(this, button)
  local self = this.obj
  if self.disabled then return end
  self.value = not self.value
  if self.value then
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  else
    PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
  end
  UpdateToggle(self)
  self:Fire("OnValueChanged", self.value)
end

local function Frame_OnShow(self)
  local userdata = self.obj.userdata
  local key = userdata and userdata.value
  local dropDownUserData = userdata and userdata.obj and userdata.obj.userdata
  local headers = dropDownUserData and dropDownUserData.option and dropDownUserData.option.headers
  if type(headers) == "function" then
    headers = headers()
  end

  local isHeader = headers and key and headers[key]
  self.obj.isHeader = isHeader

  if isHeader then
    self:SetScript("OnClick", nil)
    self.obj.text:SetTextColor(1, 1, 0)
    self.obj.useHighlight = false

    self.obj.text:ClearAllPoints()
    self.obj.text:SetPoint("TOPLEFT", self, "TOPLEFT", 7, 0)
    self.obj.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 0)
    self.obj.icon:Hide()
  else
    self:SetScript("OnClick", Frame_OnClick)
    self.obj.text:SetTextColor(1, 1, 1)
    self.obj.useHighlight = true

    if self.obj.hasIcon then
      self.obj.icon:Show()
      self.obj.text:ClearAllPoints()
      self.obj.text:SetPoint("TOPLEFT", self, "TOPLEFT", 34, 0)
      self.obj.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 0)
    else
      self.obj.icon:Hide()
      self.obj.text:ClearAllPoints()
      self.obj.text:SetPoint("TOPLEFT", self, "TOPLEFT", 18, 0)
      self.obj.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 0)
    end

  end
  UpdateToggle(self.obj)
end

-- exported
local function SetValue(self, value)
  self.value = value
  UpdateToggle(self)
end

-- exported
local function GetValue(self)
  return self.value
end

local function SetText(self, text)
  text = text or ""
  local pos = text:find("|t", 1, true)

  if pos then
    ItemBase.SetText(self, text:sub(pos + 2))

    local firstColon = text:find(":", 1, true)
    local icon = text:sub(3, firstColon - 1)
    self.icon:SetTexture(icon)
    self.hasIcon = true
  else
    ItemBase.SetText(self, text)
    self.hasIcon = false
  end
  self.fullText = text
end


local function Constructor()
  local self = ItemBase.Create(widgetType)

  self.text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 34, 0)

  self.icon = self.frame:CreateTexture(nil, "OVERLAY")
  self.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 18, -2)
  self.icon:SetWidth(12)
  self.icon:SetHeight(12)

  self.frame:SetScript("OnClick", Frame_OnClick)
  self.frame:SetScript("OnShow", Frame_OnShow)

  self.SetValue = SetValue
  self.GetValue = GetValue
  self.OnRelease = OnRelease
  self.SetText = SetText

  AceGUI:RegisterAsWidget(self)
  return self
end

AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + ItemBase.version)
