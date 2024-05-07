--[[-----------------------------------------------------------------------------
ScrollArea Widget
Plain widget that scrolls a content widget and doesn't grow in height.
Heavily based on AceGUIContainer-ScrollFrame
-------------------------------------------------------------------------------]]
local Type, Version = "WeakAurasScrollArea", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, type = pairs, assert, type
local min, max, floor = math.min, math.max, math.floor

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function FixScrollOnUpdate(frame)
	frame:SetScript("OnUpdate", nil)
	frame.obj:FixScroll()
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function ScrollFrame_OnMouseWheel(frame, value)
	frame.obj:MoveScroll(value)
end

local function ScrollFrame_OnSizeChanged(frame)
	frame:SetScript("OnUpdate", FixScrollOnUpdate)
end

local function ScrollBar_OnScrollValueChanged(frame, value)
	frame.obj:SetScroll(value)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetScroll(0)
		self.scrollframe:SetScript("OnUpdate", FixScrollOnUpdate)
	end,

	["OnRelease"] = function(self)
		for k in pairs(self.localstatus) do
			self.localstatus[k] = nil
		end
		self.scrollframe:SetPoint("BOTTOMRIGHT")
		self.scrollbar:Hide()
		self.scrollBarShown = nil
	end,

	["SetScroll"] = function(self, value)
		local status = self.localstatus
		local viewheight = self.scrollframe:GetHeight()
		local height = self.content:GetHeight()
		local offset

		if viewheight > height then
			offset = 0
		else
			offset = floor((height - viewheight) / 10000.0 * value)
		end
		self.content:ClearAllPoints()
		self.content:SetPoint("TOPLEFT", 0, offset)
		self.content:SetPoint("TOPRIGHT", 0, offset)
		status.offset = offset
		status.scrollvalue = value
		self:Fire("ContentScrolled")
	end,

	["GetContentOffset"] = function(self)
		local status = self.localstatus
		return status.offset or 0
	end,

	["GetViewportSize"] = function(self)
		return self.scrollframe:GetSize()
	end,

	["MoveScroll"] = function(self, value)
		local status = self.localstatus
		local height, viewheight = self.scrollframe:GetHeight(), self.content:GetHeight()

		if self.scrollBarShown then
			local diff = height - viewheight
			local delta = 1
			if value < 0 then
				delta = -1
			end
			self.scrollbar:SetValue(min(max(status.scrollvalue + delta*(10000/(diff/45)),0), 10000))
		end
	end,

	["FixScroll"] = function(self)
		if self.updateLock then return end
		self.updateLock = true
		local status = self.localstatus
		local height, viewheight = self.scrollframe:GetHeight(), self.content:GetHeight()
		local offset = status.offset or 0
		-- Give us a margin of error of 2 pixels to stop some conditions that i would blame on floating point inaccuracies
		-- No-one is going to miss 2 pixels at the bottom of the frame, anyhow!
		if viewheight < height + 2 then
			if self.scrollBarShown then
				self.scrollBarShown = nil
				self.scrollbar:Hide()
				self.scrollbar:SetValue(0)
				self.scrollframe:SetPoint("BOTTOMRIGHT")
				if self.content.original_width then
					self.content.width = self.content.original_width
				end
			end
		else
			if not self.scrollBarShown then
				self.scrollBarShown = true
				self.scrollbar:Show()
				self.scrollframe:SetPoint("BOTTOMRIGHT", -20, 0)
				if self.content.original_width then
					self.content.width = self.content.original_width - 20
				end
			end
			local value = (offset / (viewheight - height) * 10000)
			if value > 10000 then value = 10000 end
			self.scrollbar:SetValue(value)
			self:SetScroll(value)
			if value < 10000 then
				self.content:ClearAllPoints()
				self.content:SetPoint("TOPLEFT", 0, offset)
				self.content:SetPoint("TOPRIGHT", 0, offset)
				status.offset = offset
			end
		end
		self.updateLock = nil
	end,

	["SetContentHeight"] = function(self, height)
		self.content:SetHeight(height)
		-- update the scrollframe
		self:FixScroll()

		-- schedule another update when everything has "settled"
		self.scrollframe:SetScript("OnUpdate", FixScrollOnUpdate)
	end,

	["OnWidthSet"] = function(self, width)
		self:Fire("ContentScrolled")
	end,

	["OnHeightSet"] = function(self, height)
		self:Fire("ContentScrolled")
	end
}
--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	local num = AceGUI:GetNextWidgetNum(Type)

	local scrollframe = CreateFrame("ScrollFrame", nil, frame)
	scrollframe:SetPoint("TOPLEFT")
	scrollframe:SetPoint("BOTTOMRIGHT")
	scrollframe:EnableMouseWheel(true)
	scrollframe:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
	scrollframe:SetScript("OnSizeChanged", ScrollFrame_OnSizeChanged)

	local scrollbar = CreateFrame("Slider", ("AceConfigDialogScrollFrame%dScrollBar"):format(num), scrollframe, "UIPanelScrollBarTemplate")
	scrollbar:SetPoint("TOPLEFT", scrollframe, "TOPRIGHT", 4, -16)
	scrollbar:SetPoint("BOTTOMLEFT", scrollframe, "BOTTOMRIGHT", 4, 16)
	scrollbar:SetMinMaxValues(0, 10000)
	scrollbar:SetValueStep(1)
	scrollbar:SetValue(0)
	scrollbar:SetWidth(16)
	scrollbar:Hide()
	-- set the script as the last step, so it doesn't fire yet
	scrollbar:SetScript("OnValueChanged", ScrollBar_OnScrollValueChanged)

	local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND")
	scrollbg:SetAllPoints(scrollbar)
	scrollbg:SetColorTexture(0, 0, 0, 0.4)

	--Container Support
	local content = CreateFrame("Frame", nil, scrollframe)
	content:SetPoint("TOPLEFT")
	content:SetPoint("TOPRIGHT")
	content:SetHeight(400)
	scrollframe:SetScrollChild(content)

	local widget = {
		localstatus = { scrollvalue = 0 },
		scrollframe = scrollframe,
		scrollbar   = scrollbar,
		content     = content,
		frame       = frame,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	scrollframe.obj, scrollbar.obj = widget, widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
