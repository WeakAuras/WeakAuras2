--[[-----------------------------------------------------------------------------
BlizOptionsGroup Container
Simple container widget for the integration of AceGUI into the Blizzard Interface Options
-------------------------------------------------------------------------------]]
local Type, Version = "BlizOptionsGroup", 26
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame = CreateFrame

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]

local function OnShow(frame)
	frame.obj:Fire("OnShow")
end

local function OnHide(frame)
	frame.obj:Fire("OnHide")
end

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function okay(frame)
	frame.obj:Fire("okay")
end

local function cancel(frame)
	frame.obj:Fire("cancel")
end

local function default(frame)
	frame.obj:Fire("default")
end

local function refresh(frame)
	frame.obj:Fire("refresh")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

local methods = {
	["OnAcquire"] = function(self)
		self:SetName()
		self:SetTitle()
	end,

	-- ["OnRelease"] = nil,

	["OnWidthSet"] = function(self, width)
		local content = self.content
		local contentwidth = width - 63
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		local contentheight = height - 26
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	["SetName"] = function(self, name, parent)
		self.frame.name = name
		self.frame.parent = parent
	end,

	["SetTitle"] = function(self, title)
		local content = self.content
		content:ClearAllPoints()
		if not title or title == "" then
			content:SetPoint("TOPLEFT", 10, -10)
			self.label:SetText("")
		else
			content:SetPoint("TOPLEFT", 10, -40)
			self.label:SetText(title)
		end
		content:SetPoint("BOTTOMRIGHT", -10, 10)
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
	frame:Hide()

	-- support functions for the Blizzard Interface Options
	frame.okay = okay
	frame.cancel = cancel
	frame.default = default
	frame.refresh = refresh

	-- 10.0 support function aliases (cancel has been removed)
	frame.OnCommit = okay
	frame.OnDefault = default
	frame.OnRefresh = refresh

	frame:SetScript("OnHide", OnHide)
	frame:SetScript("OnShow", OnShow)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	label:SetPoint("TOPLEFT", 10, -15)
	label:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 10, -45)
	label:SetJustifyH("LEFT")
	label:SetJustifyV("TOP")

	--Container Support
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 10, -10)
	content:SetPoint("BOTTOMRIGHT", -10, 10)

	local widget = {
		label   = label,
		frame   = frame,
		content = content,
		type    = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)