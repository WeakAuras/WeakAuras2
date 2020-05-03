--[[-----------------------------------------------------------------------------
ToolbarButton Widget, based on AceGUI Button
Graphical Button.
-------------------------------------------------------------------------------]]
local Type, Version = "WeakAurasSnippetButton", 3
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local SharedMedia = LibStub("LibSharedMedia-3.0")

-- Lua APIs
local pairs = pairs

-- WoW APIs
local _G = _G
local PlaySound, CreateFrame, UIParent = PlaySound, CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Button_OnClick(frame, ...)
	AceGUI:ClearFocus()
	PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
	frame.obj:Fire("OnClick", ...)
end

local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		--self:SetHeight(16)
		self:SetWidth(200)
		self:SetDisabled(false)
        self:SetTitle()
        self:SetDescription()
        self:SetDeletable(false)
		--self.htex:SetVertexColor(1, 1, 1, 0.1)
	end,

	-- ["OnRelease"] = nil,

	["SetTitle"] = function(self, text)
		self.title:SetText(text)
		--self:SetWidth(self.name:GetStringWidth() + 24)
    end,
    
    ["SetDescription"] = function(self, text)
		self.description:SetText(text)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end,

	["LockHighlight"] = function(self)
		self.frame:LockHighlight()
	end,
	["UnlockHighlight"] = function(self)
		self.frame:UnlockHighlight()
	end,
	--["SetStrongHighlight"] = function(self, enable)
	--	if enable then
	--		self.htex:SetVertexColor(1, 1, 1, 0.3)
	--	else
	--		self.htex:SetVertexColor(1, 1, 1, 0.1)
	--	end
	--end

    ["SetDeletable"] = function(self, bool)
        if bool then
            self.delteable = true
            self.deleteButton:Show()
        else
            self.delteable = false
            self.deleteButton:Hide()
        end
    end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local name = "WeakAurasSnippetButton" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Button", name, UIParent, "OptionsListButtonTemplate")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetScript("OnClick", Button_OnClick)
	frame:SetScript("OnEnter", Control_OnEnter)
    frame:SetScript("OnLeave", Control_OnLeave)
    
    frame:SetHeight(45)
    frame:SetWidth(170)
    frame:SetClipsChildren(true)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
    --frame.title = title;
    title:SetHeight(14);
    title:SetJustifyH("LEFT");
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4);
    title:SetPoint("RIGHT", frame, "RIGHT", -4, 0);
    title:SetTextColor(1,1,1,1)

    local description = frame:CreateFontString(nil, "OVERLAY")
    description:SetJustifyH("LEFT")
    description:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    --description:SetHeight(14)
    description:SetTextColor(0.5,0.5,0.5,1)
    local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium");
    if(fontPath) then
        description:SetFont(fontPath, 8);
    end
    description:SetWordWrap(true)
    description:SetJustifyV("TOP")

	--local ntex = frame:CreateTexture()
	--ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	--ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	--ntex:SetAllPoints()
	--frame:SetNormalTexture(ntex)

    local htex = frame:CreateTexture()
    htex:SetColorTexture(1,1,1,0.2)
	--htex:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite")
	--htex:SetVertexColor(1, 1, 1, 0.1)
	htex:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, 0)
	htex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, 0)
	frame:SetHighlightTexture(htex)

    local ptex = frame:CreateTexture()
    ptex:SetColorTexture(1,1,1,0.2)
	--ptex:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite")
	--ptex:SetVertexColor(1, 1, 1, 0.2)
	ptex:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, 0)
	ptex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, 0)
    frame:SetPushedTexture(ptex)
    
    local deleteButton = CreateFrame("BUTTON", nil, frame)
    deleteButton:SetNormalTexture([[Interface\Buttons\CancelButton-Up]])
    deleteButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    deleteButton:SetSize(20, 20)
    deleteButton:Hide()

    delHighlight = deleteButton:CreateTexture()
    delHighlight:SetColorTexture(1,1,1,0.2)
    delHighlight:SetAllPoints()
    deleteButton:SetHighlightTexture(delHighlight)
    delPushed = deleteButton:CreateTexture()
    delPushed:SetColorTexture(1,1,1,0.2)
    delPushed:SetAllPoints()
    deleteButton:SetPushedTexture(delPushed)

	local widget = {
        title  = title,
        description = description,
		frame = frame,
		type  = Type,
        htex = htex,
        ptex = ptex,
        deleteButton = deleteButton
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
