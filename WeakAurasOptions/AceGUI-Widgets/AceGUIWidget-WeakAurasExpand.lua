--[[-----------------------------------------------------------------------------
Button Widget for our Expand button
-------------------------------------------------------------------------------]]
if not WeakAuras.IsCorrectVersion() then return end

local Type, Version = "WeakAurasExpand", 2

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs, print = select, pairs, print

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function Button_OnClick(frame, button)
	frame.obj:Fire("OnClick", button)
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetHeight(110)
		self:SetWidth(110)
		self:SetLabel()
		self:SetImage(nil)
		self:SetImageSize(64, 64)
		self:SetDisabled(false)
	end,

	-- ["OnRelease"] = nil,

	["SetLabel"] = function(self, text)
		if text and text ~= "" then
			self.label:Show()
			self.label:SetText(text)
			self:SetHeight(max(self.label:GetStringHeight(), self.image:GetHeight()))
		else
			self.label:Hide()
			self:SetHeight(self.image:GetHeight())
		end
	end,

	["SetImage"] = function(self, path, ...)
		local image = self.image
		image:SetTexture(path)

		if image:GetTexture() then
			local n = select("#", ...)
			if n == 4 or n == 8 then
				image:SetTexCoord(...)
			else
				image:SetTexCoord(0, 1, 0, 1)
			end
		end
	end,

	["SetImageSize"] = function(self, width, height)
		self.image:SetWidth(width)
		self.image:SetHeight(height)
		--self.frame:SetWidth(width + 30)
		if self.label:IsShown() then
			self:SetHeight(max(self.label:GetStringHeight(), self.image:GetHeight()))
		else
			self:SetHeight(self.image:GetHeight())
		end
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
			self.label:SetTextColor(0.5, 0.5, 0.5)
			self.image:SetVertexColor(0.5, 0.5, 0.5, 0.5)
		else
			self.frame:Enable()
			self.label:SetTextColor(1, 1, 1)
			self.image:SetVertexColor(1, 1, 1, 1)
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Button", nil, UIParent)
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)
	frame:SetScript("OnClick", Button_OnClick)

	local image = frame:CreateTexture(nil, "BACKGROUND")
	image:SetWidth(64)
	image:SetHeight(64)
	image:SetPoint("LEFT", 0, 0)

	local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightLarge")
	label:SetJustifyH("LEFT")
	label:SetJustifyV("TOP")
	label:SetPoint("LEFT", image, "RIGHT", 5, 0)
	label:SetPoint("TOP")
	label:SetPoint("BOTTOM")
	label:SetPoint("RIGHT")

	local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints(frame)
	highlight:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White")
	highlight:SetVertexColor(0.2, 0.4, 0.8, 0.2)
	highlight:SetBlendMode("ADD")

	local widget = {
		label = label,
		image = image,
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
