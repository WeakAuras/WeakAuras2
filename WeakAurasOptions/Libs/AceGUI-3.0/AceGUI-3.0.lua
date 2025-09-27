--- **AceGUI-3.0** provides access to numerous widgets which can be used to create GUIs.
-- AceGUI is used by AceConfigDialog to create the option GUIs, but you can use it by itself
-- to create any custom GUI. There are more extensive examples in the test suite in the Ace3
-- stand-alone distribution.
--
-- **Note**: When using AceGUI-3.0 directly, please do not modify the frames of the widgets directly,
-- as any "unknown" change to the widgets will cause addons that get your widget out of the widget pool
-- to misbehave. If you think some part of a widget should be modifiable, please open a ticket, and we"ll
-- implement a proper API to modify it.
-- @usage
-- local AceGUI = LibStub("AceGUI-3.0")
-- -- Create a container frame
-- local f = AceGUI:Create("Frame")
-- f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
-- f:SetTitle("AceGUI-3.0 Example")
-- f:SetStatusText("Status Bar")
-- f:SetLayout("Flow")
-- -- Create a button
-- local btn = AceGUI:Create("Button")
-- btn:SetWidth(170)
-- btn:SetText("Button !")
-- btn:SetCallback("OnClick", function() print("Click!") end)
-- -- Add the button to the container
-- f:AddChild(btn)
-- @class file
-- @name AceGUI-3.0
-- @release $Id: AceGUI-3.0.lua 1288 2022-09-25 14:19:00Z funkehdude $
local ACEGUI_MAJOR, ACEGUI_MINOR = "AceGUI-3.0", 41
local AceGUI, oldminor = LibStub:NewLibrary(ACEGUI_MAJOR, ACEGUI_MINOR)

if not AceGUI then return end -- No upgrade needed

-- Lua APIs
local tinsert, wipe = table.insert, table.wipe
local select, pairs, next, type = select, pairs, next, type
local error, assert = error, assert
local setmetatable, rawget = setmetatable, rawget
local math_max, math_min, math_ceil = math.max, math.min, math.ceil

-- WoW APIs
local UIParent = UIParent

AceGUI.WidgetRegistry = AceGUI.WidgetRegistry or {}
AceGUI.LayoutRegistry = AceGUI.LayoutRegistry or {}
AceGUI.WidgetBase = AceGUI.WidgetBase or {}
AceGUI.WidgetContainerBase = AceGUI.WidgetContainerBase or {}
AceGUI.WidgetVersions = AceGUI.WidgetVersions or {}
AceGUI.tooltip = AceGUI.tooltip or CreateFrame("GameTooltip", "AceGUITooltip", UIParent, "GameTooltipTemplate")

-- local upvalues
local WidgetRegistry = AceGUI.WidgetRegistry
local LayoutRegistry = AceGUI.LayoutRegistry
local WidgetVersions = AceGUI.WidgetVersions

--[[
	 xpcall safecall implementation
]]
local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function safecall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

-- Recycling functions
local newWidget, delWidget
do
	-- Version Upgrade in Minor 29
	-- Internal Storage of the objects changed, from an array table
	-- to a hash table, and additionally we introduced versioning on
	-- the widgets which would discard all widgets from a pre-29 version
	-- anyway, so we just clear the storage now, and don't try to
	-- convert the storage tables to the new format.
	-- This should generally not cause *many* widgets to end up in trash,
	-- since once dialogs are opened, all addons should be loaded already
	-- and AceGUI should be on the latest version available on the users
	-- setup.
	-- -- nevcairiel - Nov 2nd, 2009
	if oldminor and oldminor < 29 and AceGUI.objPools then
		AceGUI.objPools = nil
	end

	AceGUI.objPools = AceGUI.objPools or {}
	local objPools = AceGUI.objPools
	--Returns a new instance, if none are available either returns a new table or calls the given contructor
	function newWidget(widgetType)
		if not WidgetRegistry[widgetType] then
			error("Attempt to instantiate unknown widget type", 2)
		end

		if not objPools[widgetType] then
			objPools[widgetType] = {}
		end

		local newObj = next(objPools[widgetType])
		if not newObj then
			newObj = WidgetRegistry[widgetType]()
			newObj.AceGUIWidgetVersion = WidgetVersions[widgetType]
		else
			objPools[widgetType][newObj] = nil
			-- if the widget is older then the latest, don't even try to reuse it
			-- just forget about it, and grab a new one.
			if not newObj.AceGUIWidgetVersion or newObj.AceGUIWidgetVersion < WidgetVersions[widgetType] then
				return newWidget(widgetType)
			end
		end
		return newObj
	end
	-- Releases an instance to the Pool
	function delWidget(obj,widgetType)
		if not objPools[widgetType] then
			objPools[widgetType] = {}
		end
		if objPools[widgetType][obj] then
			error("Attempt to Release Widget that is already released", 2)
		end
		objPools[widgetType][obj] = true
	end
end


-------------------
-- API Functions --
-------------------

-- Gets a widget Object

--- Create a new Widget of the given type.
-- This function will instantiate a new widget (or use one from the widget pool), and call the
-- OnAcquire function on it, before returning.
-- @param type The type of the widget.
-- @return The newly created widget.
function AceGUI:Create(widgetType)
	if WidgetRegistry[widgetType] then
		local widget = newWidget(widgetType)

		if rawget(widget, "Acquire") then
			widget.OnAcquire = widget.Acquire
			widget.Acquire = nil
		elseif rawget(widget, "Aquire") then
			widget.OnAcquire = widget.Aquire
			widget.Aquire = nil
		end

		if rawget(widget, "Release") then
			widget.OnRelease = rawget(widget, "Release")
			widget.Release = nil
		end

		if widget.OnAcquire then
			widget:OnAcquire()
		else
			error(("Widget type %s doesn't supply an OnAcquire Function"):format(widgetType))
		end
		-- Set the default Layout ("List")
		safecall(widget.SetLayout, widget, "List")
		safecall(widget.ResumeLayout, widget)
		return widget
	end
end

--- Releases a widget Object.
-- This function calls OnRelease on the widget and places it back in the widget pool.
-- Any data on the widget is being erased, and the widget will be hidden.\\
-- If this widget is a Container-Widget, all of its Child-Widgets will be releases as well.
-- @param widget The widget to release
function AceGUI:Release(widget)
	if widget.isQueuedForRelease then return end
	widget.isQueuedForRelease = true
	safecall(widget.PauseLayout, widget)
	widget.frame:Hide()
	widget:Fire("OnRelease")
	safecall(widget.ReleaseChildren, widget)

	if widget.OnRelease then
		widget:OnRelease()
--	else
--		error(("Widget type %s doesn't supply an OnRelease Function"):format(widget.type))
	end
	for k in pairs(widget.userdata) do
		widget.userdata[k] = nil
	end
	for k in pairs(widget.events) do
		widget.events[k] = nil
	end
	widget.width = nil
	widget.relWidth = nil
	widget.height = nil
	widget.relHeight = nil
	widget.noAutoHeight = nil
	widget.frame:ClearAllPoints()
	widget.frame:Hide()
	widget.frame:SetParent(UIParent)
	widget.frame.width = nil
	widget.frame.height = nil
	if widget.content then
		widget.content.width = nil
		widget.content.height = nil
	end
	widget.isQueuedForRelease = nil
	delWidget(widget, widget.type)
end

--- Check if a widget is currently in the process of being released
-- This function check if this widget, or any of its parents (in which case it'll be released shortly as well)
-- are currently being released. This allows addon to handle any callbacks accordingly.
-- @param widget The widget to check
function AceGUI:IsReleasing(widget)
	if widget.isQueuedForRelease then
		return true
	end

	if widget.parent and widget.parent.AceGUIWidgetVersion then
		return AceGUI:IsReleasing(widget.parent)
	end

	return false
end

-----------
-- Focus --
-----------


--- Called when a widget has taken focus.
-- e.g. Dropdowns opening, Editboxes gaining kb focus
-- @param widget The widget that should be focused
function AceGUI:SetFocus(widget)
	if self.FocusedWidget and self.FocusedWidget ~= widget then
		safecall(self.FocusedWidget.ClearFocus, self.FocusedWidget)
	end
	self.FocusedWidget = widget
end


--- Called when something has happened that could cause widgets with focus to drop it
-- e.g. titlebar of a frame being clicked
function AceGUI:ClearFocus()
	if self.FocusedWidget then
		safecall(self.FocusedWidget.ClearFocus, self.FocusedWidget)
		self.FocusedWidget = nil
	end
end

-------------
-- Widgets --
-------------
--[[
	Widgets must provide the following functions
		OnAcquire() - Called when the object is acquired, should set everything to a default hidden state

	And the following members
		frame - the frame or derivitive object that will be treated as the widget for size and anchoring purposes
		type - the type of the object, same as the name given to :RegisterWidget()

	Widgets contain a table called userdata, this is a safe place to store data associated with the wigdet
	It will be cleared automatically when a widget is released
	Placing values directly into a widget object should be avoided

	If the Widget can act as a container for other Widgets the following
		content - frame or derivitive that children will be anchored to

	The Widget can supply the following Optional Members
		:OnRelease() - Called when the object is Released, should remove any additional anchors and clear any data
		:OnWidthSet(width) - Called when the width of the widget is changed
		:OnHeightSet(height) - Called when the height of the widget is changed
			Widgets should not use the OnSizeChanged events of thier frame or content members, use these methods instead
			AceGUI already sets a handler to the event
		:LayoutFinished(width, height) - called after a layout has finished, the width and height will be the width and height of the
			area used for controls. These can be nil if the layout used the existing size to layout the controls.

]]

--------------------------
-- Widget Base Template --
--------------------------
do
	local WidgetBase = AceGUI.WidgetBase

	WidgetBase.SetParent = function(self, parent)
		local frame = self.frame
		frame:SetParent(nil)
		frame:SetParent(parent.content)
		self.parent = parent
	end

	WidgetBase.SetCallback = function(self, name, func)
		if type(func) == "function" then
			self.events[name] = func
		end
	end

	WidgetBase.Fire = function(self, name, ...)
		if self.events[name] then
			local success, ret = safecall(self.events[name], self, name, ...)
			if success then
				return ret
			end
		end
	end

	WidgetBase.SetWidth = function(self, width)
		self.frame:SetWidth(width)
		self.frame.width = width
		if self.OnWidthSet then
			self:OnWidthSet(width)
		end
	end

	WidgetBase.SetRelativeWidth = function(self, width)
		if width <= 0 or width > 1 then
			error(":SetRelativeWidth(width): Invalid relative width.", 2)
		end
		self.relWidth = width
		self.width = "relative"
	end

	WidgetBase.SetHeight = function(self, height)
		self.frame:SetHeight(height)
		self.frame.height = height
		if self.OnHeightSet then
			self:OnHeightSet(height)
		end
	end

	--[[ WidgetBase.SetRelativeHeight = function(self, height)
		if height <= 0 or height > 1 then
			error(":SetRelativeHeight(height): Invalid relative height.", 2)
		end
		self.relHeight = height
		self.height = "relative"
	end ]]

	WidgetBase.IsVisible = function(self)
		return self.frame:IsVisible()
	end

	WidgetBase.IsShown= function(self)
		return self.frame:IsShown()
	end

	WidgetBase.Release = function(self)
		AceGUI:Release(self)
	end

	WidgetBase.IsReleasing = function(self)
		return AceGUI:IsReleasing(self)
	end

	WidgetBase.SetPoint = function(self, ...)
		return self.frame:SetPoint(...)
	end

	WidgetBase.ClearAllPoints = function(self)
		return self.frame:ClearAllPoints()
	end

	WidgetBase.GetNumPoints = function(self)
		return self.frame:GetNumPoints()
	end

	WidgetBase.GetPoint = function(self, ...)
		return self.frame:GetPoint(...)
	end

	WidgetBase.GetUserDataTable = function(self)
		return self.userdata
	end

	WidgetBase.SetUserData = function(self, key, value)
		self.userdata[key] = value
	end

	WidgetBase.GetUserData = function(self, key)
		return self.userdata[key]
	end

	WidgetBase.IsFullHeight = function(self)
		return self.height == "fill"
	end

	WidgetBase.SetFullHeight = function(self, isFull)
		if isFull then
			self.height = "fill"
		else
			self.height = nil
		end
	end

	WidgetBase.IsFullWidth = function(self)
		return self.width == "fill"
	end

	WidgetBase.SetFullWidth = function(self, isFull)
		if isFull then
			self.width = "fill"
		else
			self.width = nil
		end
	end

--	local function LayoutOnUpdate(this)
--		this:SetScript("OnUpdate",nil)
--		this.obj:PerformLayout()
--	end

	local WidgetContainerBase = AceGUI.WidgetContainerBase

	WidgetContainerBase.PauseLayout = function(self)
		self.LayoutPaused = true
	end

	WidgetContainerBase.ResumeLayout = function(self)
		self.LayoutPaused = nil
	end

	WidgetContainerBase.PerformLayout = function(self)
		if self.LayoutPaused then
			return
		end
		safecall(self.LayoutFunc, self.content, self.children)
	end

	--call this function to layout, makes sure layed out objects get a frame to get sizes etc
	WidgetContainerBase.DoLayout = function(self)
		self:PerformLayout()
--		if not self.parent then
--			self.frame:SetScript("OnUpdate", LayoutOnUpdate)
--		end
	end

	WidgetContainerBase.AddChild = function(self, child, beforeWidget)
		if beforeWidget then
			local siblingIndex = 1
			for _, widget in pairs(self.children) do
				if widget == beforeWidget then
					break
				end
				siblingIndex = siblingIndex + 1
			end
			tinsert(self.children, siblingIndex, child)
		else
			tinsert(self.children, child)
		end
		child:SetParent(self)
		child.frame:Show()
		self:DoLayout()
	end

	WidgetContainerBase.AddChildren = function(self, ...)
		for i = 1, select("#", ...) do
			local child = select(i, ...)
			tinsert(self.children, child)
			child:SetParent(self)
			child.frame:Show()
		end
		self:DoLayout()
	end

	WidgetContainerBase.ReleaseChildren = function(self)
		local children = self.children
		for i = 1,#children do
			AceGUI:Release(children[i])
			children[i] = nil
		end
	end

	WidgetContainerBase.SetLayout = function(self, Layout)
		self.LayoutFunc = AceGUI:GetLayout(Layout)
	end

	WidgetContainerBase.SetAutoAdjustHeight = function(self, adjust)
		if adjust then
			self.noAutoHeight = nil
		else
			self.noAutoHeight = true
		end
	end

	local function FrameResize(this)
		local self = this.obj
		if this:GetWidth() and this:GetHeight() then
			if self.OnWidthSet then
				self:OnWidthSet(this:GetWidth())
			end
			if self.OnHeightSet then
				self:OnHeightSet(this:GetHeight())
			end
		end
	end

	local function ContentResize(this)
		if this:GetWidth() and this:GetHeight() then
			this.width = this:GetWidth()
			this.height = this:GetHeight()
			this.obj:DoLayout()
		end
	end

	setmetatable(WidgetContainerBase, {__index=WidgetBase})

	--One of these function should be called on each Widget Instance as part of its creation process

	--- Register a widget-class as a container for newly created widgets.
	-- @param widget The widget class
	function AceGUI:RegisterAsContainer(widget)
		widget.children = {}
		widget.userdata = {}
		widget.events = {}
		widget.base = WidgetContainerBase
		widget.content.obj = widget
		widget.frame.obj = widget
		widget.content:SetScript("OnSizeChanged", ContentResize)
		widget.frame:SetScript("OnSizeChanged", FrameResize)
		setmetatable(widget, {__index = WidgetContainerBase})
		widget:SetLayout("List")
		return widget
	end

	--- Register a widget-class as a widget.
	-- @param widget The widget class
	function AceGUI:RegisterAsWidget(widget)
		widget.userdata = {}
		widget.events = {}
		widget.base = WidgetBase
		widget.frame.obj = widget
		widget.frame:SetScript("OnSizeChanged", FrameResize)
		setmetatable(widget, {__index = WidgetBase})
		return widget
	end
end




------------------
-- Widget API   --
------------------

--- Registers a widget Constructor, this function returns a new instance of the Widget
-- @param Name The name of the widget
-- @param Constructor The widget constructor function
-- @param Version The version of the widget
function AceGUI:RegisterWidgetType(Name, Constructor, Version)
	assert(type(Constructor) == "function")
	assert(type(Version) == "number")

	local oldVersion = WidgetVersions[Name]
	if oldVersion and oldVersion >= Version then return end

	WidgetVersions[Name] = Version
	WidgetRegistry[Name] = Constructor
end

--- Registers a Layout Function
-- @param Name The name of the layout
-- @param LayoutFunc Reference to the layout function
function AceGUI:RegisterLayout(Name, LayoutFunc)
	assert(type(LayoutFunc) == "function")
	if type(Name) == "string" then
		Name = Name:upper()
	end
	LayoutRegistry[Name] = LayoutFunc
end

--- Get a Layout Function from the registry
-- @param Name The name of the layout
function AceGUI:GetLayout(Name)
	if type(Name) == "string" then
		Name = Name:upper()
	end
	return LayoutRegistry[Name]
end

AceGUI.counts = AceGUI.counts or {}

--- A type-based counter to count the number of widgets created.
-- This is used by widgets that require a named frame, e.g. when a Blizzard
-- Template requires it.
-- @param type The widget type
function AceGUI:GetNextWidgetNum(widgetType)
	if not self.counts[widgetType] then
		self.counts[widgetType] = 0
	end
	self.counts[widgetType] = self.counts[widgetType] + 1
	return self.counts[widgetType]
end

--- Return the number of created widgets for this type.
-- In contrast to GetNextWidgetNum, the number is not incremented.
-- @param widgetType The widget type
function AceGUI:GetWidgetCount(widgetType)
	return self.counts[widgetType] or 0
end

--- Return the version of the currently registered widget type.
-- @param widgetType The widget type
function AceGUI:GetWidgetVersion(widgetType)
	return WidgetVersions[widgetType]
end

-------------
-- Layouts --
-------------

--[[
	A Layout is a func that takes 2 parameters
		content - the frame that widgets will be placed inside
		children - a table containing the widgets to layout
]]

-- Very simple Layout, Children are stacked on top of each other down the left side
AceGUI:RegisterLayout("List",
	function(content, children)
		local height = 0
		local width = content.width or content:GetWidth() or 0
		for i = 1, #children do
			local child = children[i]

			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()
			if i == 1 then
				frame:SetPoint("TOPLEFT", content)
			else
				frame:SetPoint("TOPLEFT", children[i-1].frame, "BOTTOMLEFT")
			end

			if child.width == "fill" then
				child:SetWidth(width)
				frame:SetPoint("RIGHT", content)

				if child.DoLayout then
					child:DoLayout()
				end
			elseif child.width == "relative" then
				child:SetWidth(width * child.relWidth)

				if child.DoLayout then
					child:DoLayout()
				end
			end

			height = height + (frame.height or frame:GetHeight() or 0)
		end
		safecall(content.obj.LayoutFinished, content.obj, nil, height)
	end)

-- A single control fills the whole content area
AceGUI:RegisterLayout("Fill",
	function(content, children)
		if children[1] then
			children[1]:SetWidth(content:GetWidth() or 0)
			children[1]:SetHeight(content:GetHeight() or 0)
			children[1].frame:ClearAllPoints()
			children[1].frame:SetAllPoints(content)
			children[1].frame:Show()
			safecall(content.obj.LayoutFinished, content.obj, nil, children[1].frame:GetHeight())
		end
	end)

local layoutrecursionblock = nil
local function safelayoutcall(object, func, ...)
	layoutrecursionblock = true
	object[func](object, ...)
	layoutrecursionblock = nil
end

AceGUI:RegisterLayout("Flow",
	function(content, children)
		if layoutrecursionblock then return end
		--used height so far
		local height = 0
		--width used in the current row
		local usedwidth = 0
		--height of the current row
		local rowheight = 0
		local rowoffset = 0

		local width = content.width or content:GetWidth() or 0

		--control at the start of the row
		local rowstart
		local rowstartoffset
		local isfullheight

		local frameoffset
		local lastframeoffset
		local oversize
		for i = 1, #children do
			local child = children[i]
			oversize = nil
			local frame = child.frame
			local frameheight = frame.height or frame:GetHeight() or 0
			local framewidth = frame.width or frame:GetWidth() or 0
			lastframeoffset = frameoffset
			-- HACK: Why did we set a frameoffset of (frameheight / 2) ?
			-- That was moving all widgets half the widgets size down, is that intended?
			-- Actually, it seems to be neccessary for many cases, we'll leave it in for now.
			-- If widgets seem to anchor weirdly with this, provide a valid alignoffset for them.
			-- TODO: Investigate moar!
			frameoffset = child.alignoffset or (frameheight / 2)

			if child.width == "relative" then
				framewidth = width * child.relWidth
			end

			frame:Show()
			frame:ClearAllPoints()
			if i == 1 then
				-- anchor the first control to the top left
				frame:SetPoint("TOPLEFT", content)
				rowheight = frameheight
				rowoffset = frameoffset
				rowstart = frame
				rowstartoffset = frameoffset
				usedwidth = framewidth
				if usedwidth > width then
					oversize = true
				end
			else
				-- if there isn't available width for the control start a new row
				-- if a control is "fill" it will be on a row of its own full width
				if usedwidth == 0 or ((framewidth) + usedwidth > width) or child.width == "fill" then
					if isfullheight then
						-- a previous row has already filled the entire height, there's nothing we can usefully do anymore
						-- (maybe error/warn about this?)
						break
					end
					--anchor the previous row, we will now know its height and offset
					rowstart:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(height + (rowoffset - rowstartoffset) + 3))
					height = height + rowheight + 3
					--save this as the rowstart so we can anchor it after the row is complete and we have the max height and offset of controls in it
					rowstart = frame
					rowstartoffset = frameoffset
					rowheight = frameheight
					rowoffset = frameoffset
					usedwidth = framewidth
					if usedwidth > width then
						oversize = true
					end
				-- put the control on the current row, adding it to the width and checking if the height needs to be increased
				else
					--handles cases where the new height is higher than either control because of the offsets
					--math.max(rowheight-rowoffset+frameoffset, frameheight-frameoffset+rowoffset)

					--offset is always the larger of the two offsets
					rowoffset = math_max(rowoffset, frameoffset)
					rowheight = math_max(rowheight, rowoffset + (frameheight / 2))

					frame:SetPoint("TOPLEFT", children[i-1].frame, "TOPRIGHT", 0, frameoffset - lastframeoffset)
					usedwidth = framewidth + usedwidth
				end
			end

			if child.width == "fill" then
				safelayoutcall(child, "SetWidth", width)
				frame:SetPoint("RIGHT", content)

				usedwidth = 0
				rowstart = frame

				if child.DoLayout then
					child:DoLayout()
				end
				rowheight = frame.height or frame:GetHeight() or 0
				rowoffset = child.alignoffset or (rowheight / 2)
				rowstartoffset = rowoffset
			elseif child.width == "relative" then
				safelayoutcall(child, "SetWidth", width * child.relWidth)

				if child.DoLayout then
					child:DoLayout()
				end
			elseif oversize then
				if width > 1 then
					frame:SetPoint("RIGHT", content)
				end
			end

			if child.height == "fill" then
				frame:SetPoint("BOTTOM", content)
				isfullheight = true
			end
		end

		--anchor the last row, if its full height needs a special case since  its height has just been changed by the anchor
		if isfullheight then
			rowstart:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
		elseif rowstart then
			rowstart:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(height + (rowoffset - rowstartoffset) + 3))
		end

		height = height + rowheight + 3
		safecall(content.obj.LayoutFinished, content.obj, nil, height)
	end)

-- Get alignment method and value. Possible alignment methods are a callback, a number, "start", "middle", "end", "fill" or "TOPLEFT", "BOTTOMRIGHT" etc.
local GetCellAlign = function (dir, tableObj, colObj, cellObj, cell, child)
	local fn = cellObj and (cellObj["align" .. dir] or cellObj.align)
			or colObj and (colObj["align" .. dir] or colObj.align)
			or tableObj["align" .. dir] or tableObj.align
			or "CENTERLEFT"
	local val
	child, cell = child or 0, cell or 0

	if type(fn) == "string" then
		fn = fn:lower()
		fn = dir == "V" and (fn:sub(1, 3) == "top" and "start" or fn:sub(1, 6) == "bottom" and "end" or fn:sub(1, 6) == "center" and "middle")
		  or dir == "H" and (fn:sub(-4) == "left" and "start" or fn:sub(-5) == "right" and "end" or fn:sub(-6) == "center" and "middle")
		  or fn
		val = (fn == "start" or fn == "fill") and 0 or fn == "end" and cell - child or (cell - child) / 2
	elseif type(fn) == "function" then
		val = fn(child or 0, cell, dir)
	else
		val = fn
	end

	return fn, math_max(0, math_min(val, cell))
end

-- Get width or height for multiple cells combined
local GetCellDimension = function (dir, laneDim, from, to, space)
	local dim = 0
	for cell=from,to do
		dim = dim + (laneDim[cell] or 0)
	end
	return dim + math_max(0, to - from) * (space or 0)
end

--[[ Options
============
Container:
 - columns ({col, col, ...}): Column settings. "col" can be a number (<= 0: content width, <1: rel. width, <10: weight, >=10: abs. width) or a table with column setting.
 - space, spaceH, spaceV: Overall, horizontal and vertical spacing between cells.
 - align, alignH, alignV: Overall, horizontal and vertical cell alignment. See GetCellAlign() for possible values.
Columns:
 - width: Fixed column width (nil or <=0: content width, <1: rel. width, >=1: abs. width).
 - min or 1: Min width for content based width
 - max or 2: Max width for content based width
 - weight: Flexible column width. The leftover width after accounting for fixed-width columns is distributed to weighted columns according to their weights.
 - align, alignH, alignV: Overwrites the container setting for alignment.
Cell:
 - colspan: Makes a cell span multiple columns.
 - rowspan: Makes a cell span multiple rows.
 - align, alignH, alignV: Overwrites the container and column setting for alignment.
]]
AceGUI:RegisterLayout("Table",
	function (content, children)
		local obj = content.obj
		obj:PauseLayout()

		local tableObj = obj:GetUserData("table")
		local cols = tableObj.columns
		local spaceH = tableObj.spaceH or tableObj.space or 0
		local spaceV = tableObj.spaceV or tableObj.space or 0
		local totalH = (content:GetWidth() or content.width or 0) - spaceH * (#cols - 1)

		-- We need to reuse these because layout events can come in very frequently
		local layoutCache = obj:GetUserData("layoutCache")
		if not layoutCache then
			layoutCache = {{}, {}, {}, {}, {}, {}}
			obj:SetUserData("layoutCache", layoutCache)
		end
		local t, laneH, laneV, rowspans, rowStart, colStart = unpack(layoutCache)

		-- Create the grid
		local n, slotFound = 0
		for i,child in ipairs(children) do
			if child:IsShown() then
				repeat
					n = n + 1
					local col = (n - 1) % #cols + 1
					local row = math_ceil(n / #cols)
					local rowspan = rowspans[col]
					local cell = rowspan and rowspan.child or child
					local cellObj = cell:GetUserData("cell")
					slotFound = not rowspan

					-- Rowspan
					if not rowspan and cellObj and cellObj.rowspan then
						rowspan = {child = child, from = row, to = row + cellObj.rowspan - 1}
						rowspans[col] = rowspan
					end
					if rowspan and i == #children then
						rowspan.to = row
					end

					-- Colspan
					local colspan = math_max(0, math_min((cellObj and cellObj.colspan or 1) - 1, #cols - col))
					n = n + colspan

					-- Place the cell
					if not rowspan or rowspan.to == row then
						t[n] = cell
						rowStart[cell] = rowspan and rowspan.from or row
						colStart[cell] = col

						if rowspan then
							rowspans[col] = nil
						end
					end
				until slotFound
			end
		end

		local rows = math_ceil(n / #cols)

		-- Determine fixed size cols and collect weights
		local extantH, totalWeight = totalH, 0
		for col,colObj in ipairs(cols) do
			laneH[col] = 0

			if type(colObj) == "number" then
				colObj = {[colObj >= 1 and colObj < 10 and "weight" or "width"] = colObj}
				cols[col] = colObj
			end

			if colObj.weight then
				-- Weight
				totalWeight = totalWeight + (colObj.weight or 1)
			else
				if not colObj.width or colObj.width <= 0 then
					-- Content width
					for row=1,rows do
						local child = t[(row - 1) * #cols + col]
						if child then
							local f = child.frame
							f:ClearAllPoints()
							local childH = f:GetWidth() or 0

							laneH[col] = math_max(laneH[col], childH - GetCellDimension("H", laneH, colStart[child], col - 1, spaceH))
						end
					end

					laneH[col] = math_max(colObj.min or colObj[1] or 0, math_min(laneH[col], colObj.max or colObj[2] or laneH[col]))
				else
					-- Rel./Abs. width
					laneH[col] = colObj.width < 1 and colObj.width * totalH or colObj.width
				end
				extantH = math_max(0, extantH - laneH[col])
			end
		end

		-- Determine sizes based on weight
		local scale = totalWeight > 0 and extantH / totalWeight or 0
		for col,colObj in pairs(cols) do
			if colObj.weight then
				laneH[col] = scale * colObj.weight
			end
		end

		-- Arrange children
		for row=1,rows do
			local rowV = 0

			-- Horizontal placement and sizing
			for col=1,#cols do
				local child = t[(row - 1) * #cols + col]
				if child then
					local colObj = cols[colStart[child]]
					local cellObj = child:GetUserData("cell")
					local offsetH = GetCellDimension("H", laneH, 1, colStart[child] - 1, spaceH) + (colStart[child] == 1 and 0 or spaceH)
					local cellH = GetCellDimension("H", laneH, colStart[child], col, spaceH)

					local f = child.frame
					f:ClearAllPoints()
					local childH = f:GetWidth() or 0

					local alignFn, align = GetCellAlign("H", tableObj, colObj, cellObj, cellH, childH)
					f:SetPoint("LEFT", content, offsetH + align, 0)
					if child:IsFullWidth() or alignFn == "fill" or childH > cellH then
						f:SetPoint("RIGHT", content, "LEFT", offsetH + align + cellH, 0)
					end

					if child.DoLayout then
						child:DoLayout()
					end

					rowV = math_max(rowV, (f:GetHeight() or 0) - GetCellDimension("V", laneV, rowStart[child], row - 1, spaceV))
				end
			end

			laneV[row] = rowV

			-- Vertical placement and sizing
			for col=1,#cols do
				local child = t[(row - 1) * #cols + col]
				if child then
					local colObj = cols[colStart[child]]
					local cellObj = child:GetUserData("cell")
					local offsetV = GetCellDimension("V", laneV, 1, rowStart[child] - 1, spaceV) + (rowStart[child] == 1 and 0 or spaceV)
					local cellV = GetCellDimension("V", laneV, rowStart[child], row, spaceV)

					local f = child.frame
					local childV = f:GetHeight() or 0

					local alignFn, align = GetCellAlign("V", tableObj, colObj, cellObj, cellV, childV)
					if child:IsFullHeight() or alignFn == "fill" then
						f:SetHeight(cellV)
					end
					f:SetPoint("TOP", content, 0, -(offsetV + align))
				end
			end
		end

		-- Calculate total height
		local totalV = GetCellDimension("V", laneV, 1, #laneV, spaceV)

		-- Cleanup
		for _,v in pairs(layoutCache) do wipe(v) end

		safecall(obj.LayoutFinished, obj, nil, totalV)
		obj:ResumeLayout()
	end)