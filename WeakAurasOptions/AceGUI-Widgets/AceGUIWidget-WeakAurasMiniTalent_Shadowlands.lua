if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

local widgetType, widgetVersion = "WeakAurasMiniTalent", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(widgetType) or 0) >= widgetVersion then return end


local function CreateTalentButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button.obj = parent
    button:SetSize(190, 42)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", button, "LEFT", 10, 0)
    icon:Show()
    button.icon = icon

    local slot = button:CreateTexture(nil, "ARTWORK")
    slot:SetSize(37, 36)
    slot:SetTexture([[Interface\TalentFrame\TalentFrame-Parts]])
    slot:SetTexCoord(0.40625000, 0.52734375, 0.90625000, 0.96484375)
    slot:SetPoint("CENTER", icon, -1, 0)
    slot:Show()
    button.slot = slot

    local name = button:CreateFontString(nil, "ARTWORK")
    name:SetFontObject("GameFontNormalSmall")
    name:SetJustifyH("LEFT")
    name:SetTextColor(1,1,1,1)
    name:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    name:Show()
    button.name = name

    local cover = button:CreateTexture(nil, "OVERLAY")
    cover:SetColorTexture(0,0,0,0.4)
    cover:SetAllPoints(button)
    cover:Hide()
    button.cover = cover

    button:SetHighlightAtlas("Talent-Highlight", "ADD")

    function button:Green()
        self.cover:Show()
        self.cover:SetColorTexture(0,1,0,0.2)
        self.icon:SetDesaturated(false)
    end
    function button:Red()
        self.cover:Show()
        self.cover:SetColorTexture(1,0,0,0.2)
        self.icon:SetDesaturated(false)
    end
    function button:Clear()
        self.cover:Hide()
        self.icon:SetDesaturated(true)
    end
    function button:UpdateTexture()
        if self.state == nil then
            self:Clear()
        elseif self.state == true then
            self:Green()
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
            self:SetValue()
        else
            self:SetValue(true)
        end
        self.obj.obj:Fire("OnValueChanged", self.index, self.state)
    end)
    button:Show()
    return button
end

local function TalentFrame_Update(self)
    for _, button in ipairs(self.buttons) do
        local spellId = self.list[button.index]
        local name, _, icon = GetSpellInfo(spellId)
        button.icon:SetTexture(icon)
        button:UpdateTexture()
        button.name:SetText(name or "")
    end
end

local methods = {
    OnAcquire = function (self)
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
            self.frame:SetSize(1, 1)
            self.frame:Hide()
            for _, button in pairs(self.buttons) do
                button:Hide()
            end
        else
            self.frame:SetSize(self.saveSize.width, self.saveSize.height)
            self.frame:Show()
            for _, button in pairs(self.buttons) do
                button:Show()
            end
        end
    end,

    SetItemValue = function(self, item, value)
        self.buttons[item]:SetValue(value)
    end,

    SetValue = function(self, value) end,
    SetLabel = function(self, text) end,
    SetMultiselect = function (self, multi) end,
}

local function Constructor()
    local name = widgetType .. AceGUI:GetNextWidgetNum(widgetType)

    local talentFrame = CreateFrame("Frame", name, UIParent)
    talentFrame:SetFrameStrata("FULLSCREEN_DIALOG")

    local buttons = {}
    for tier = 1, MAX_TALENT_TIERS do
        for column = 1, NUM_TALENT_COLUMNS do
            local button = CreateTalentButton(talentFrame)
            if column == 1 and tier == 1 then
                button:SetPoint("TOPLEFT", talentFrame, "TOPLEFT")
            elseif column == 1 then
                button:SetPoint("TOP", buttons[(tier-2)*NUM_TALENT_COLUMNS+1], "BOTTOM")
            else
                button:SetPoint("LEFT", buttons[#buttons], "RIGHT")
            end
            button.tier = tier
            button.column = column
            button.index = column + (tier - 1) * NUM_TALENT_COLUMNS
            table.insert(buttons, button)
        end
    end

    -- rescale buttons and resize frame to fit in weakauras options
    local width = NUM_TALENT_COLUMNS * buttons[1]:GetWidth()
    local height = MAX_TALENT_TIERS * buttons[1]:GetHeight()
    local finalWidth = 440
    local scale = (finalWidth / width)
    local finalHeiht = height * scale
    for _, button in ipairs(buttons) do
        button:SetScale(scale)
    end
    talentFrame:SetSize(finalWidth, finalHeiht)

    local widget = {
        frame = talentFrame,
        type = widgetType,
        buttons = buttons,
        saveSize = { width = finalWidth, height = finalHeiht}
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    talentFrame.obj = widget

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
