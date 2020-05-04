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
	if ... == "RightButton" and frame.editable then
		AceGUI:ClearFocus()
		PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
		frame.title:Hide()
		frame.renameEditBox:Show()
		frame.renameEditBox:Enable()
		frame.renameEditBox:SetText(frame.title:GetText())
		frame.renameEditBox:HighlightText()
		frame.renameEditBox:SetFocus()
	elseif ... == "LeftButton" then
		AceGUI:ClearFocus()
		PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
		frame.obj:Fire("OnClick", ...)
	end
end

local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function rename_complete(self, ...)
	self:ClearFocus()
	AceGUI:ClearFocus()
	self:Disable()
	self:Hide()
	--frame.title:Show()
	self:GetParent().obj:Fire("OnEnterPressed", ...)
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
        self:SetEditable(false)
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

    ["SetEditable"] = function(self, bool)
        if bool then
            self.frame.editable = true
			self.deleteButton:Show()
        else
            self.frame.editable = false
			self.deleteButton:Hide()
        end
    end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local name = "WeakAurasSnippetButton" .. AceGUI:GetNextWidgetNum(Type)
	local button = CreateFrame("Button", name, UIParent, "OptionsListButtonTemplate")
	button:Hide()

	button:EnableMouse(true)
	button:SetScript("OnClick", Button_OnClick)
	button:SetScript("OnEnter", Control_OnEnter)
    button:SetScript("OnLeave", Control_OnLeave)
    
    button:SetHeight(45)
    button:SetWidth(170)
    button:SetClipsChildren(true)

	local title = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
    --frame.title = title;
    title:SetHeight(14);
    title:SetJustifyH("LEFT");
    title:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4);
    title:SetPoint("RIGHT", button, "RIGHT", -20, 0);
	title:SetTextColor(1,1,1,1)
	button.title = title

    local description = button:CreateFontString(nil, "OVERLAY")
    description:SetJustifyH("LEFT")
    description:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 4, 4)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    --description:SetHeight(14)
	description:SetTextColor(0.65,0.65,0.65,1)
	description:SetSpacing(0)
    local fontPath = SharedMedia:Fetch("font", "Fira Mono Medium");
    if(fontPath) then
        description:SetFont(fontPath, 6);
    end
    description:SetWordWrap(true)
	description:SetJustifyV("TOP")
	button.description = description

	--local ntex = button:CreateTexture()
	--ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	--ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	--ntex:SetAllPoints()
	--button:SetNormalTexture(ntex)

    local htex = button:CreateTexture()
    htex:SetColorTexture(1,1,1,0.2)
	--htex:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite")
	--htex:SetVertexColor(1, 1, 1, 0.1)
	htex:SetPoint("TOPLEFT", button, "TOPLEFT", 2, 0)
	htex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, 0)
	button:SetHighlightTexture(htex)
	button.htex = htex

    local ptex = button:CreateTexture()
    ptex:SetColorTexture(1,1,1,0.2)
	--ptex:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite")
	--ptex:SetVertexColor(1, 1, 1, 0.2)
	ptex:SetPoint("TOPLEFT", button, "TOPLEFT", 2, 0)
	ptex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, 0)
    button:SetPushedTexture(ptex)
	button.ptext = ptext
	
    local deleteButton = CreateFrame("BUTTON", nil, button)
    deleteButton:SetNormalTexture([[Interface\Buttons\CancelButton-Up]])
    deleteButton:SetPoint("TOPRIGHT", button, "TOPRIGHT")
    deleteButton:SetSize(20, 20)
    deleteButton:Hide()
	button.deleteButton = deleteButton

    delHighlight = deleteButton:CreateTexture()
    delHighlight:SetColorTexture(1,1,1,0.2)
    delHighlight:SetAllPoints()
    deleteButton:SetHighlightTexture(delHighlight)
    delPushed = deleteButton:CreateTexture()
    delPushed:SetColorTexture(1,1,1,0.2)
    delPushed:SetAllPoints()
	deleteButton:SetPushedTexture(delPushed)
	button.deleteHighlight = deleteHighlight

	renameEditBox = CreateFrame("EditBox", nil, button, "InputBoxTemplate")
	renameEditBox:SetHeight(14)
    renameEditBox:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
	renameEditBox:SetPoint("RIGHT", button, "RIGHT", -20, 0)
	renameEditBox:Disable()
	renameEditBox:Hide()
	renameEditBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		AceGUI:ClearFocus()
		self:Disable()
		self:Hide()
		title:Show()
	end)
	renameEditBox:SetScript("OnEditFocusLost", function(self)
		self:ClearFocus()
		AceGUI:ClearFocus()
		self:Disable()
		self:Hide()
		title:Show()
	end)
	renameEditBox:SetScript("OnEnterPressed", rename_complete)
	button.renameEditBox = renameEditBox

	--local renameButton = CreateFrame("Frame", nil, button)
	--renameButton:SetHeight(14)
    --renameButton:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
	--renameButton:SetPoint("RIGHT", button, "RIGHT", -4, 0)
	--renameButton:Hide()
	--renameButton:SetScript("OnMouseUp", function(self, event, button)
	--	if button == "RightButton" then
	--		title:Hide()
	--		renameEditBox:Show()
	--	end
	--end)

	local widget = {
        title  = title,
        description = description,
		frame = button,
		type  = Type,
        htex = htex,
        ptex = ptex,
		deleteButton = deleteButton,
		renameEditBox = renameEditBox,
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
