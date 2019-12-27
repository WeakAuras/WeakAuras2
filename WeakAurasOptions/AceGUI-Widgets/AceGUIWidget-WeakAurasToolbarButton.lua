--[[-----------------------------------------------------------------------------
ToolbarButton Widget, based on AceGUI Button
Graphical Button.
-------------------------------------------------------------------------------]]
local Type, Version = "WeakAurasToolbarButton", 3
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

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
		self:SetHeight(16)
		self:SetWidth(32)
		self:SetDisabled(false)
		self:SetText()
		self.htex:SetVertexColor(1, 1, 1, 0.1)
	end,

	-- ["OnRelease"] = nil,

	["SetText"] = function(self, text)
		self.text:SetText(text)
		self:SetWidth(self.text:GetStringWidth() + 24)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end,

	["SetTexture"] = function(self, path)
		self.icon:SetTexture(path)
	end,
	["LockHighlight"] = function(self)
		self.frame:LockHighlight()
	end,
	["UnlockHighlight"] = function(self)
		self.frame:UnlockHighlight()
	end,
	["SetStrongHighlight"] = function(self, enable)
		if enable then
			self.htex:SetVertexColor(1, 1, 1, 0.3)
		else
			self.htex:SetVertexColor(1, 1, 1, 0.1)
		end
	end

}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local name = "AceGUI30Button" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Button", name, UIParent)
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetScript("OnClick", Button_OnClick)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)


	local icon = frame:CreateTexture()
	icon:SetTexture("aaa")
	icon:SetPoint("TOPLEFT", frame, "TOPLEFT")
	icon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	icon:SetWidth(16)

	local text = frame:CreateFontString()
	text:SetFontObject("GameFontNormal")
	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", 20, -1)
	text:SetPoint("BOTTOMRIGHT", -4, 1)
	text:SetJustifyV("MIDDLE")

	--local ntex = frame:CreateTexture()
	--ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	--ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	--ntex:SetAllPoints()
	--frame:SetNormalTexture(ntex)

	local htex = frame:CreateTexture()
	htex:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite")
	htex:SetVertexColor(1, 1, 1, 0.1)

	htex:SetAllPoints()
	frame:SetHighlightTexture(htex)

	local ptex = frame:CreateTexture()
	ptex:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite")
	ptex:SetVertexColor(1, 1, 1, 0.2)
	ptex:SetAllPoints()
	frame:SetPushedTexture(ptex)


	local widget = {
		text  = text,
		icon = icon,
		frame = frame,
		type  = Type,
		htex = htex
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
