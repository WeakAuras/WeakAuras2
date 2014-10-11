local Type, Version = "WeakAurasNewHeaderButton", 20
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local L = WeakAuras.L;

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
        self:SetWidth(1000);
        self:SetHeight(20);
    end,
    ["SetText"] = function(self, text)
        self.frame:SetText(" "..text);
    end,
    ["SetDescription"] = function(self, description)
        self.frame.description = description;
    end,
    ["SetClick"] = function(self, func)
        self.frame:SetScript("OnClick", func);
    end,
    ["Disable"] = function(self)
        self.frame:Disable();
    end,
    ["Enable"] = function(self)
        self.frame:Enable();
    end,
    ["Pick"] = function(self)
        self.frame:LockHighlight();
    end,
    ["ClearPick"] = function(self)
        self.frame:UnlockHighlight();
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
    local name = Type..AceGUI:GetNextWidgetNum(Type)
    local button = CreateFrame("BUTTON", name, UIParent, "OptionsListButtonTemplate");
    button:SetHeight(20);
    button:SetWidth(1000);
    button:SetDisabledFontObject("GameFontNormal");
    
    local background = button:CreateTexture(nil, "BACKGROUND");
    button.background = background;
    background:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
    background:SetBlendMode("ADD");
    background:SetVertexColor(0.5, 0.5, 0.5, 0.25);
    background:SetAllPoints(button);
    
    button:SetScript("OnEnter", function() Show_Tooltip(button, button:GetText():sub(2), button.description or L["Add a new display"]) end);
    button:SetScript("OnLeave", Hide_Tooltip);
    
    local widget = {
        frame = button,
        type = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
