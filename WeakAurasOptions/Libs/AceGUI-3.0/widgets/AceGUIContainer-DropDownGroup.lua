--[[-----------------------------------------------------------------------------
DropdownGroup Container
Container controlled by a dropdown on the top.
-------------------------------------------------------------------------------]]
local Type, Version = "DropdownGroup", 22
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local assert, pairs, type = assert, pairs, type

-- WoW APIs
local CreateFrame = CreateFrame

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function SelectedGroup(self, event, value)
	local group = self.parentgroup
	local status = group.status or group.localstatus
	status.selected = value
	self.parentgroup:Fire("OnGroupSelected", value)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self.dropdown:SetText("")
		self:SetDropdownWidth(200)
		self:SetTitle("")
	end,

	["OnRelease"] = function(self)
		self.dropdown.list = nil
		self.status = nil
		for k in pairs(self.localstatus) do
			self.localstatus[k] = nil
		end
	end,

	["SetTitle"] = function(self, title)
		self.titletext:SetText(title)
		self.dropdown.frame:ClearAllPoints()
		if title and title ~= "" then
			self.dropdown.frame:SetPoint("TOPRIGHT", -2, 0)
		else
			self.dropdown.frame:SetPoint("TOPLEFT", -1, 0)
		end
	end,

	["SetGroupList"] = function(self,list,order)
		self.dropdown:SetList(list,order)
	end,

	["SetStatusTable"] = function(self, status)
		assert(type(status) == "table")
		self.status = status
	end,

	["SetGroup"] = function(self,group)
		self.dropdown:SetValue(group)
		local status = self.status or self.localstatus
		status.selected = group
		self:Fire("OnGroupSelected", group)
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.content
		local contentwidth = width - 26
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		local contentheight = height - 63
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	["LayoutFinished"] = function(self, width, height)
		self:SetHeight((height or 0) + 63)
	end,

	["SetDropdownWidth"] = function(self, width)
		self.dropdown:SetWidth(width)
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local PaneBackdrop  = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

local function Constructor()
	local frame = CreateFrame("Frame")
	frame:SetHeight(100)
	frame:SetWidth(100)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")

	local titletext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titletext:SetPoint("TOPLEFT", 4, -5)
	titletext:SetPoint("TOPRIGHT", -4, -5)
	titletext:SetJustifyH("LEFT")
	titletext:SetHeight(18)

	local dropdown = AceGUI:Create("Dropdown")
	dropdown.frame:SetParent(frame)
	dropdown.frame:SetFrameLevel(dropdown.frame:GetFrameLevel() + 2)
	dropdown:SetCallback("OnValueChanged", SelectedGroup)
	dropdown.frame:SetPoint("TOPLEFT", -1, 0)
	dropdown.frame:Show()
	dropdown:SetLabel("")

	local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	border:SetPoint("TOPLEFT", 0, -26)
	border:SetPoint("BOTTOMRIGHT", 0, 3)
	border:SetBackdrop(PaneBackdrop)
	border:SetBackdropColor(0.1,0.1,0.1,0.5)
	border:SetBackdropBorderColor(0.4,0.4,0.4)

	--Container Support
	local content = CreateFrame("Frame", nil, border)
	content:SetPoint("TOPLEFT", 10, -10)
	content:SetPoint("BOTTOMRIGHT", -10, 10)

	local widget = {
		frame       = frame,
		localstatus = {},
		titletext   = titletext,
		dropdown    = dropdown,
		border      = border,
		content     = content,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	dropdown.parentgroup = widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)