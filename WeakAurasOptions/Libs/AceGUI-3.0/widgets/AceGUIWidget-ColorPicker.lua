--[[-----------------------------------------------------------------------------
ColorPicker Widget
-------------------------------------------------------------------------------]]
local Type, Version = "ColorPicker", 28
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

-- Unfortunately we have no way to realistically detect if a client uses inverted alpha
-- as no API will tell you. Wrath uses the old colorpicker, era uses the new one, both are inverted
local INVERTED_ALPHA = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function ColorCallback(self, r, g, b, a, isAlpha)
	if INVERTED_ALPHA and a then
		a = 1 - a
	end
	if not self.HasAlpha then
		a = 1
	end
	-- no change, skip update
	if r == self.r and g == self.g and b == self.b and a == self.a then
		return
	end
	self:SetColor(r, g, b, a)
	if ColorPickerFrame:IsVisible() then
		--colorpicker is still open
		self:Fire("OnValueChanged", r, g, b, a)
	else
		--colorpicker is closed, color callback is first, ignore it,
		--alpha callback is the final call after it closes so confirm now
		if isAlpha then
			self:Fire("OnValueConfirmed", r, g, b, a)
		end
	end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function ColorSwatch_OnClick(frame)
	ColorPickerFrame:Hide()
	local self = frame.obj
	if not self.disabled then
		ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
		ColorPickerFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
		ColorPickerFrame:SetClampedToScreen(true)

		if ColorPickerFrame.SetupColorPickerAndShow then -- 10.2.5 color picker overhaul
			local r2, g2, b2, a2 = self.r, self.g, self.b, (self.a or 1)
			if INVERTED_ALPHA then
				a2 = 1 - a2
			end

			local info = {
				swatchFunc = function()
					local r, g, b = ColorPickerFrame:GetColorRGB()
					local a = ColorPickerFrame:GetColorAlpha()
					ColorCallback(self, r, g, b, a)
				end,

				hasOpacity = self.HasAlpha,
				opacityFunc = function()
					local r, g, b = ColorPickerFrame:GetColorRGB()
					local a = ColorPickerFrame:GetColorAlpha()
					ColorCallback(self, r, g, b, a, true)
				end,
				opacity = a2,

				cancelFunc = function()
					ColorCallback(self, r2, g2, b2, a2, true)
				end,

				r = r2,
				g = g2,
				b = b2,
			}

			ColorPickerFrame:SetupColorPickerAndShow(info)
		else
			ColorPickerFrame.func = function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = OpacitySliderFrame:GetValue()
				ColorCallback(self, r, g, b, a)
			end

			ColorPickerFrame.hasOpacity = self.HasAlpha
			ColorPickerFrame.opacityFunc = function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = OpacitySliderFrame:GetValue()
				ColorCallback(self, r, g, b, a, true)
			end

			local r, g, b, a = self.r, self.g, self.b, 1 - (self.a or 1)
			if self.HasAlpha then
				ColorPickerFrame.opacity = a
			end
			ColorPickerFrame:SetColorRGB(r, g, b)

			ColorPickerFrame.cancelFunc = function()
				ColorCallback(self, r, g, b, a, true)
			end

			ColorPickerFrame:Show()
		end
	end
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetHeight(24)
		self:SetWidth(200)
		self:SetHasAlpha(false)
		self:SetColor(0, 0, 0, 1)
		self:SetDisabled(nil)
		self:SetLabel(nil)
	end,

	-- ["OnRelease"] = nil,

	["SetLabel"] = function(self, text)
		self.text:SetText(text)
	end,

	["SetColor"] = function(self, r, g, b, a)
		self.r = r
		self.g = g
		self.b = b
		self.a = a or 1
		self.colorSwatch:SetVertexColor(r, g, b, a)
	end,

	["SetHasAlpha"] = function(self, HasAlpha)
		self.HasAlpha = HasAlpha
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if self.disabled then
			self.frame:Disable()
			self.text:SetTextColor(0.5, 0.5, 0.5)
		else
			self.frame:Enable()
			self.text:SetTextColor(1, 1, 1)
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
	frame:SetScript("OnClick", ColorSwatch_OnClick)

	local colorSwatch = frame:CreateTexture(nil, "OVERLAY")
	colorSwatch:SetWidth(19)
	colorSwatch:SetHeight(19)
	colorSwatch:SetTexture(130939) -- Interface\\ChatFrame\\ChatFrameColorSwatch
	colorSwatch:SetPoint("LEFT")

	local texture = frame:CreateTexture(nil, "BACKGROUND")
	colorSwatch.background = texture
	texture:SetWidth(16)
	texture:SetHeight(16)
	texture:SetColorTexture(1, 1, 1)
	texture:SetPoint("CENTER", colorSwatch)
	texture:Show()

	local checkers = frame:CreateTexture(nil, "BACKGROUND")
	colorSwatch.checkers = checkers
	checkers:SetWidth(14)
	checkers:SetHeight(14)
	checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
	checkers:SetTexCoord(.25, 0, 0.5, .25)
	checkers:SetDesaturated(true)
	checkers:SetVertexColor(1, 1, 1, 0.75)
	checkers:SetPoint("CENTER", colorSwatch)
	checkers:Show()

	local text = frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
	text:SetHeight(24)
	text:SetJustifyH("LEFT")
	text:SetTextColor(1, 1, 1)
	text:SetPoint("LEFT", colorSwatch, "RIGHT", 2, 0)
	text:SetPoint("RIGHT")

	--local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
	--highlight:SetTexture(136810) -- Interface\\QuestFrame\\UI-QuestTitleHighlight
	--highlight:SetBlendMode("ADD")
	--highlight:SetAllPoints(frame)

	local widget = {
		colorSwatch = colorSwatch,
		text        = text,
		frame       = frame,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)