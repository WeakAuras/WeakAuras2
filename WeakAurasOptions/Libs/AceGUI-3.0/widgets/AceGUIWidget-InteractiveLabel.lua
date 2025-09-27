--[[-----------------------------------------------------------------------------
InteractiveLabel Widget
-------------------------------------------------------------------------------]]
local Type, Version = "InteractiveLabel", 21
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs = select, pairs

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function Label_OnClick(frame, button)
	frame.obj:Fire("OnClick", button)
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:LabelOnAcquire()
		self:SetHighlight()
		self:SetHighlightTexCoord()
		self:SetDisabled(false)
	end,

	-- ["OnRelease"] = nil,

	["SetHighlight"] = function(self, ...)
		self.highlight:SetTexture(...)
	end,

	["SetHighlightTexCoord"] = function(self, ...)
		local c = select("#", ...)
		if c == 4 or c == 8 then
			self.highlight:SetTexCoord(...)
		else
			self.highlight:SetTexCoord(0, 1, 0, 1)
		end
	end,

	["SetDisabled"] = function(self,disabled)
		self.disabled = disabled
		if disabled then
			self.frame:EnableMouse(false)
			self.label:SetTextColor(0.5, 0.5, 0.5)
		else
			self.frame:EnableMouse(true)
			self.label:SetTextColor(1, 1, 1)
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	-- create a Label type that we will hijack
	local label = AceGUI:Create("Label")

	local frame = label.frame
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)
	frame:SetScript("OnMouseDown", Label_OnClick)

	local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetTexture(nil)
	highlight:SetAllPoints()
	highlight:SetBlendMode("ADD")

	label.highlight = highlight
	label.type = Type
	label.LabelOnAcquire = label.OnAcquire
	for method, func in pairs(methods) do
		label[method] = func
	end

	return label
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)