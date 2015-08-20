local Type, Version = "WeakAurasNewButton", 20
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- GLOBALS: GameTooltip UIParent WeakAuras WeakAurasOptionsSaved

local function Hide_Tooltip()
    GameTooltip:Hide();
end

local function Show_Tooltip(owner, line1, line2)
    GameTooltip:SetOwner(owner, "ANCHOR_NONE");
    GameTooltip:SetPoint("LEFT", owner, "RIGHT");
    GameTooltip:ClearLines();
    GameTooltip:AddLine(line1);
    GameTooltip:AddLine(line2, 1, 1, 1, 1);
    GameTooltip:Show();
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetWidth(380);
        self:SetHeight(40);
    end,
    ["SetTitle"] = function(self, title)
        self.title:SetText(title);
    end,
    ["GetTitle"] = function(self)
        return self.title:GetText();
    end,
    ["SetDescription"] = function(self, desc)
        self.frame.description = desc;
        self.description:SetText(desc);
    end,
    ["SetClick"] = function(self, func)
        self.frame:SetScript("OnClick", func);
    end,
    ["SetIcon"] = function(self, icon)
        if(type(icon) == "string") then
            self.icon:SetTexture(icon);
            self.icon:Show();
            if(self.iconRegion and self.iconRegion.Hide) then
                self.iconRegion:Hide();
            end
        else
            self.iconRegion = icon;
            icon:SetAllPoints(self.icon);
            icon:SetParent(self.frame);
            self.icon:Hide();
        end
    end,
    ["OnRelease"] = function(self)
        if(self.iconRegion and self.iconRegion.Hide) then
            self.iconRegion:Hide();
        end
        self.icon:Hide();
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
    local name = "WeakAurasDisplayButton"..AceGUI:GetNextWidgetNum(Type);
    local button = CreateFrame("BUTTON", name, UIParent, "OptionsListButtonTemplate");
    button:SetHeight(40);
    button:SetWidth(380);
    button.dgroup = nil;

    local background = button:CreateTexture(nil, "BACKGROUND");
    button.background = background;
    background:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
    background:SetBlendMode("ADD");
    background:SetVertexColor(0.5, 0.5, 0.5, 0.25);
    background:SetAllPoints(button);

    local icon = button:CreateTexture(nil, "OVERLAY");
    button.icon = icon;
    icon:SetWidth(40);
    icon:SetHeight(40);
    icon:SetPoint("LEFT", button, "LEFT");

    local title = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    button.title = title;
    title:SetHeight(14);
    title:SetJustifyH("LEFT");
    title:SetPoint("TOP", button, "TOP", 0, -5);
    title:SetPoint("LEFT", icon, "RIGHT", 2, 0);
    title:SetPoint("RIGHT", button, "RIGHT");

    local description = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    button.description = description;
    description:SetHeight(14);
    description:SetJustifyH("LEFT");
    description:SetPoint("BOTTOM", button, "BOTTOM", 0, 2);
    description:SetPoint("LEFT", icon, "RIGHT", 2, 0);
    description:SetPoint("RIGHT", button, "RIGHT");


    button.description = "";

    button:SetScript("OnEnter", function() Show_Tooltip(button, title:GetText(), button.description) end);
    button:SetScript("OnLeave", Hide_Tooltip);


    local widget = {
        frame = button,
        title = title,
        icon = icon,
        description = description,
        background = background,
        type = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
