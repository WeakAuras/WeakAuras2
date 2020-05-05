--[[-----------------------------------------------------------------------------
SnippetButton Widget, based on AceGUI Button (and WA ToolbarButton)
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
	--frame.tooltip:Show()
	local tooltip = GameTooltip;
	tooltip:SetOwner(frame, "ANCHOR_RIGHT")
  	tooltip:ClearLines();
	tooltip:AddLine(frame.titleText)
	tooltip:AddLine("   ")
	tooltip:AddLine(frame.descriptionText, 0.8, 0.8, 0.8)
	tooltip:Show()
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	--frame.tooltip:Hide()
	GameTooltip:Hide()
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
		--self:SetWidth(200)
		self:SetDisabled(false)
        self:SetTitle()
        self:SetEditable(false)
	end,

	-- ["OnRelease"] = nil,

	["SetTitle"] = function(self, text)
		self.frame.titleText = text
		self.title:SetText(text)
    end,
    
	["SetDescription"] = function(self, text)
		self.frame.descriptionText = text
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

    ["SetEditable"] = function(self, bool)
        if bool then
            self.frame.editable = true
			self.deleteButton:Show()
			self.title:SetPoint("LEFT", self.deleteButton, "RIGHT")
        else
            self.frame.editable = false
			self.deleteButton:Hide()
			self.title:SetPoint("LEFT", self.deleteButton, "LEFT")
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
    
    button:SetHeight(24)
    button:SetWidth(170)
    --button:SetClipsChildren(true)

    local deleteButton = CreateFrame("BUTTON", nil, button)
    deleteButton:SetNormalTexture([[Interface\Buttons\CancelButton-Up]])
    deleteButton:SetPoint("LEFT", button, "LEFT")
    deleteButton:SetSize(24, 24)
    deleteButton:Hide()
	button.deleteButton = deleteButton


	local title = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
    --frame.title = title;
    title:SetHeight(14);
    title:SetJustifyH("LEFT");
    title:SetPoint("LEFT", deleteButton, "RIGHT");
    title:SetPoint("RIGHT", button, "RIGHT");
	title:SetTextColor(1,1,1,1)
	button.title = title

	local ntex = button:CreateTexture()
	ntex:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
	--ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	ntex:SetVertexColor(0.8,0.8,1,0.3)
	ntex:SetPoint("TOPLEFT", 1,-1)
	ntex:SetPoint("BOTTOMRIGHT", -1, 1)
	button:SetNormalTexture(ntex)

    local htex = button:CreateTexture()
    --htex:SetColorTexture(1,1,1,0.2)
	htex:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
	htex:SetVertexColor(0.2, 0.2, 1, 0.3)
	htex:SetBlendMode("ADD")
	htex:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	htex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	button:SetHighlightTexture(htex)
	button.htex = htex

    local ptex = button:CreateTexture()
    ptex:SetColorTexture(1,1,1,0.2)
	--ptex:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite")
	--ptex:SetVertexColor(1, 1, 1, 0.2)
	ptex:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -1)
	ptex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button:SetPushedTexture(ptex)
	button.ptext = ptext
	
    delHighlight = deleteButton:CreateTexture()
    delHighlight:SetTexture([[Interface\Buttons\CancelButton-Highlight]])
    delHighlight:SetAllPoints()
    deleteButton:SetHighlightTexture(delHighlight)
    delPushed = deleteButton:CreateTexture()
    delPushed:SetTexture([[Interface\Buttons\CancelButton-Down]])
    delPushed:SetAllPoints()
	deleteButton:SetPushedTexture(delPushed)
	button.deleteHighlight = deleteHighlight

	renameEditBox = CreateFrame("EditBox", nil, button, "InputBoxTemplate")
	renameEditBox:SetHeight(14)
    renameEditBox:SetPoint("TOPLEFT", title, "TOPLEFT")
	renameEditBox:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT")
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

	local widget = {
        title  = title,
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
