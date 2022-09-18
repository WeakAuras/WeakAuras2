--[[ $Id: AceGUIWidget-DropDown.lua 1257 2022-01-10 16:25:37Z nevcairiel $ ]]--
local AceGUI = LibStub("AceGUI-3.0")

-- Lua APIs
local min, max, floor = math.min, math.max, math.floor
local select, pairs, ipairs, type, tostring = select, pairs, ipairs, type, tostring
local tsort = table.sort

-- WoW APIs
local PlaySound = PlaySound
local UIParent, CreateFrame = UIParent, CreateFrame
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: CLOSE

local function fixlevels(parent,...)
	local i = 1
	local child = select(i, ...)
	while child do
		child:SetFrameLevel(parent:GetFrameLevel()+1)
		fixlevels(child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

local function fixstrata(strata, parent, ...)
	local i = 1
	local child = select(i, ...)
	parent:SetFrameStrata(strata)
	while child do
		fixstrata(strata, child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

do
	local widgetType = "WeakAurasDropdown-Pullout"
	local widgetVersion = 5

	--[[ Static data ]]--

	local backdrop = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 32,
		tileSize = 32,
		tile = true,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	}
	local sliderBackdrop  = {
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	local defaultWidth = 200
	local defaultMaxHeight = 600

	--[[ UI Event Handlers ]]--

	-- HACK: This should be no part of the pullout, but there
	--       is no other 'clean' way to response to any item-OnEnter
	--       Used to close Submenus when an other item is entered
	local function OnEnter(item)
		local self = item.pullout
		for k, v in ipairs(self.items) do
			if v.CloseMenu and v ~= item then
				v:CloseMenu()
			end
		end
	end

	-- See the note in Constructor() for each scroll related function
	local function OnMouseWheel(this, value)
		this.obj:MoveScroll(value)
	end

	local function OnScrollValueChanged(this, value)
		this.obj:SetScroll(value)
	end

	local function OnSizeChanged(this)
		this.obj:FixScroll()
	end

	--[[ Exported methods ]]--

	-- exported
	local function SetScroll(self, value)
		local status = self.scrollStatus
		local frame, child = self.scrollFrame, self.itemFrame
		local height, viewheight = frame:GetHeight(), child:GetHeight()

		local offset
		if height > viewheight then
			offset = 0
		else
			offset = floor((viewheight - height) / 1000 * value)
		end
		child:ClearAllPoints()
		child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, offset)
		child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", self.slider:IsShown() and -12 or 0, offset)
		status.offset = offset
		status.scrollvalue = value
	end

	-- exported
	local function MoveScroll(self, value)
		local status = self.scrollStatus
		local frame, child = self.scrollFrame, self.itemFrame
		local height, viewheight = frame:GetHeight(), child:GetHeight()

		if height > viewheight then
			self.slider:Hide()
		else
			self.slider:Show()
			local diff = height - viewheight
			local delta = 1
			if value < 0 then
				delta = -1
			end
			self.slider:SetValue(min(max(status.scrollvalue + delta*(1000/(diff/45)),0), 1000))
		end
	end

	-- exported
	local function FixScroll(self)
		local status = self.scrollStatus
		local frame, child = self.scrollFrame, self.itemFrame
		local height, viewheight = frame:GetHeight(), child:GetHeight()
		local offset = status.offset or 0

		if viewheight < height then
			self.slider:Hide()
			child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, offset)
			self.slider:SetValue(0)
		else
			self.slider:Show()
			local value = (offset / (viewheight - height) * 1000)
			if value > 1000 then value = 1000 end
			self.slider:SetValue(value)
			self:SetScroll(value)
			if value < 1000 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, offset)
				child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, offset)
				status.offset = offset
			end
		end
	end

	-- exported, AceGUI callback
	local function OnAcquire(self)
		self.frame:SetParent(UIParent)
		--self.itemFrame:SetToplevel(true)
	end

	-- exported, AceGUI callback
	local function OnRelease(self)
		self:Clear()
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end

	-- exported
	local function AddItem(self, item)
		self.items[#self.items + 1] = item

		local h = #self.items * 16
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h + 34, self.maxHeight)) -- +34: 20 for scrollFrame placement (10 offset) and +14 for item placement

		item.frame:SetPoint("LEFT", self.itemFrame, "LEFT")
		item.frame:SetPoint("RIGHT", self.itemFrame, "RIGHT")

		item:SetPullout(self)
		item:SetOnEnter(OnEnter)
	end

	-- exported
	local function Open(self, point, relFrame, relPoint, x, y)
		local items = self.items
		local frame = self.frame
		local itemFrame = self.itemFrame

		frame:SetPoint(point, relFrame, relPoint, x, y)


		local height = 8
		for i, item in pairs(items) do
			item:SetPoint("TOP", itemFrame, "TOP", 0, -2 + (i - 1) * -16)
			item:Show()

			height = height + 16
		end
		itemFrame:SetHeight(height)
		fixstrata("TOOLTIP", frame, frame:GetChildren())
		frame:Show()
		self:Fire("OnOpen")
	end

	-- exported
	local function Close(self)
		self.frame:Hide()
		self:Fire("OnClose")
	end

	-- exported
	local function Clear(self)
		local items = self.items
		for i, item in pairs(items) do
			AceGUI:Release(item)
			items[i] = nil
		end
	end

	-- exported
	local function IterateItems(self)
		return ipairs(self.items)
	end

	-- exported
	local function SetHideOnLeave(self, val)
		self.hideOnLeave = val
	end

	-- exported
	local function SetMaxHeight(self, height)
		self.maxHeight = height or defaultMaxHeight
		if self.frame:GetHeight() > height then
			self.frame:SetHeight(height)
		elseif (self.itemFrame:GetHeight() + 34) < height then
			self.frame:SetHeight(self.itemFrame:GetHeight() + 34) -- see :AddItem
		end
	end

	-- exported
	local function GetRightBorderWidth(self)
		return 6 + (self.slider:IsShown() and 12 or 0)
	end

	-- exported
	local function GetLeftBorderWidth(self)
		return 6
	end

	--[[ Constructor ]]--

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(widgetType)
		local frame = CreateFrame("Frame", "AceGUI30Pullout"..count, UIParent, "BackdropTemplate")
		local self = {}
		self.count = count
		self.type = widgetType
		self.frame = frame
		frame.obj = self

		self.OnAcquire = OnAcquire
		self.OnRelease = OnRelease

		self.AddItem = AddItem
		self.Open    = Open
		self.Close   = Close
		self.Clear   = Clear
		self.IterateItems = IterateItems
		self.SetHideOnLeave = SetHideOnLeave

		self.SetScroll  = SetScroll
		self.MoveScroll = MoveScroll
		self.FixScroll  = FixScroll

		self.SetMaxHeight = SetMaxHeight
		self.GetRightBorderWidth = GetRightBorderWidth
		self.GetLeftBorderWidth = GetLeftBorderWidth

		self.items = {}

		self.scrollStatus = {
			scrollvalue = 0,
		}

		self.maxHeight = defaultMaxHeight

		frame:SetBackdrop(backdrop)
		frame:SetBackdropColor(0, 0, 0)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetWidth(defaultWidth)
		frame:SetHeight(self.maxHeight)
		--frame:SetToplevel(true)

		-- NOTE: The whole scroll frame code is copied from the AceGUI-3.0 widget ScrollFrame
		local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
		local itemFrame = CreateFrame("Frame", nil, scrollFrame)

		self.scrollFrame = scrollFrame
		self.itemFrame = itemFrame

		scrollFrame.obj = self
		itemFrame.obj = self

		local slider = CreateFrame("Slider", "AceGUI30PulloutScrollbar"..count, scrollFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
		slider:SetOrientation("VERTICAL")
		slider:SetHitRectInsets(0, 0, -10, 0)
		slider:SetBackdrop(sliderBackdrop)
		slider:SetWidth(8)
		slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
		slider:SetFrameStrata("FULLSCREEN_DIALOG")
		self.slider = slider
		slider.obj = self

		scrollFrame:SetScrollChild(itemFrame)
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -12)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 12)
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetScript("OnMouseWheel", OnMouseWheel)
		scrollFrame:SetScript("OnSizeChanged", OnSizeChanged)
		scrollFrame:SetToplevel(true)
		scrollFrame:SetFrameStrata("FULLSCREEN_DIALOG")

		itemFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
		itemFrame:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -12, 0)
		itemFrame:SetHeight(400)
		itemFrame:SetToplevel(true)
		itemFrame:SetFrameStrata("FULLSCREEN_DIALOG")

		slider:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -16, 0)
		slider:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -16, 0)
		slider:SetScript("OnValueChanged", OnScrollValueChanged)
		slider:SetMinMaxValues(0, 1000)
		slider:SetValueStep(1)
		slider:SetValue(0)

		scrollFrame:Show()
		itemFrame:Show()
		slider:Hide()

		self:FixScroll()

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end

do
	local widgetType = "Dropdown"
	local widgetVersion = 36

	--[[ Static data ]]--

	--[[ UI event handler ]]--

	local function Control_OnEnter(this)
		this.obj.button:LockHighlight()
		this.obj:Fire("OnEnter")
	end

	local function Control_OnLeave(this)
		this.obj.button:UnlockHighlight()
		this.obj:Fire("OnLeave")
	end

	local function Dropdown_OnHide(this)
		local self = this.obj
		if self.open then
			self.pullout:Close()
		end
	end

	local function Dropdown_TogglePullout(this)
		local self = this.obj
		if self.open then
			self.open = nil
			self.pullout:Close()
			AceGUI:ClearFocus()
		else
			self.open = true
			self.pullout:SetWidth(self.pulloutWidth or self.frame:GetWidth())
			self.pullout:Open("TOPLEFT", self.frame, "BOTTOMLEFT", 0, self.label:IsShown() and -2 or 0)
			AceGUI:SetFocus(self)
		end
	end

	local function OnPulloutOpen(this)
		local self = this.userdata.obj
		local value = self.value

		if not self.multiselect then
			for i, item in this:IterateItems() do
				item:SetValue(item.userdata.value == value)
			end
		end

		self.open = true
		self:Fire("OnOpened")
	end

	local function OnPulloutClose(this)
		local self = this.userdata.obj
		self.open = nil
		self:Fire("OnClosed")
	end

	local function ShowMultiText(self)
		local text
		for i, widget in self.pullout:IterateItems() do
			if widget.type == "Dropdown-Item-Toggle" then
				if widget:GetValue() then
					if text then
						text = text..", "..widget:GetText()
					else
						text = widget:GetText()
					end
				end
			end
		end
		self:SetText(text)
	end

	local function OnItemValueChanged(this, event, checked)
		local self = this.userdata.obj

		if self.multiselect then
			self:Fire("OnValueChanged", this.userdata.value, checked)
			ShowMultiText(self)
		else
			if checked then
				self:SetValue(this.userdata.value)
				self:Fire("OnValueChanged", this.userdata.value)
			else
				this:SetValue(true)
			end
			if self.open then
				self.pullout:Close()
			end
		end
	end

	--[[ Exported methods ]]--

	-- exported, AceGUI callback
	local function OnAcquire(self)
		local pullout = AceGUI:Create("Dropdown-Pullout")
		self.pullout = pullout
		pullout.userdata.obj = self
		pullout:SetCallback("OnClose", OnPulloutClose)
		pullout:SetCallback("OnOpen", OnPulloutOpen)
		self.pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		fixlevels(self.pullout.frame, self.pullout.frame:GetChildren())

		self:SetHeight(44)
		self:SetWidth(200)
		self:SetLabel()
		self:SetPulloutWidth(nil)
		self.list = {}
	end

	-- exported, AceGUI callback
	local function OnRelease(self)
		if self.open then
			self.pullout:Close()
		end
		AceGUI:Release(self.pullout)
		self.pullout = nil

		self:SetText("")
		self:SetDisabled(false)
		self:SetMultiselect(false)

		self.value = nil
		self.list = nil
		self.open = nil
		self.hasClose = nil

		self.frame:ClearAllPoints()
		self.frame:Hide()
	end

	-- exported
	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
			self.text:SetTextColor(0.5,0.5,0.5)
			self.button:Disable()
			self.button_cover:Disable()
			self.label:SetTextColor(0.5,0.5,0.5)
		else
			self.button:Enable()
			self.button_cover:Enable()
			self.label:SetTextColor(1,.82,0)
			self.text:SetTextColor(1,1,1)
		end
	end

	-- exported
	local function ClearFocus(self)
		if self.open then
			self.pullout:Close()
		end
	end

	-- exported
	local function SetText(self, text)
		self.text:SetText(text or "")
	end

	-- exported
	local function SetLabel(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,-14)
			self:SetHeight(40)
			self.alignoffset = 26
		else
			self.label:SetText("")
			self.label:Hide()
			self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,0)
			self:SetHeight(26)
			self.alignoffset = 12
		end
	end

	-- exported
	local function SetValue(self, value)
		self:SetText(self.list[value] or "")
		self.value = value
	end

	-- exported
	local function GetValue(self)
		return self.value
	end

	-- exported
	local function SetItemValue(self, item, value)
		if not self.multiselect then return end
		for i, widget in self.pullout:IterateItems() do
			if widget.userdata.value == item then
				if widget.SetValue then
					widget:SetValue(value)
				end
			end
		end
		ShowMultiText(self)
	end

	-- exported
	local function SetItemDisabled(self, item, disabled)
		for i, widget in self.pullout:IterateItems() do
			if widget.userdata.value == item then
				widget:SetDisabled(disabled)
			end
		end
	end

	local function AddListItem(self, value, text, itemType)
		if not itemType then itemType = "Dropdown-Item-Toggle" end
		local exists = AceGUI:GetWidgetVersion(itemType)
		if not exists then error(("The given item type, %q, does not exist within AceGUI-3.0"):format(tostring(itemType)), 2) end

		local item = AceGUI:Create(itemType)
		item:SetText(text)
		item.userdata.obj = self
		item.userdata.value = value
		item:SetCallback("OnValueChanged", OnItemValueChanged)
		self.pullout:AddItem(item)
	end

	local function AddCloseButton(self)
		if not self.hasClose then
			local close = AceGUI:Create("Dropdown-Item-Execute")
			close:SetText(CLOSE)
			self.pullout:AddItem(close)
			self.hasClose = true
		end
	end

	-- exported
	local sortlist = {}
	local function sortTbl(x,y)
		local num1, num2 = tonumber(x), tonumber(y)
		if num1 and num2 then -- numeric comparison, either two numbers or numeric strings
			return num1 < num2
		else -- compare everything else tostring'ed
			return tostring(x) < tostring(y)
		end
	end
	local function SetList(self, list, order, itemType)
		self.list = list or {}
		self.pullout:Clear()
		self.hasClose = nil
		if not list then return end

		if type(order) ~= "table" then
			for v in pairs(list) do
				sortlist[#sortlist + 1] = v
			end
			tsort(sortlist, sortTbl)

			for i, key in ipairs(sortlist) do
				AddListItem(self, key, list[key], itemType)
				sortlist[i] = nil
			end
		else
			for i, key in ipairs(order) do
				AddListItem(self, key, list[key], itemType)
			end
		end
		if self.multiselect then
			ShowMultiText(self)
			AddCloseButton(self)
		end
	end

	-- exported
	local function AddItem(self, value, text, itemType)
		self.list[value] = text
		AddListItem(self, value, text, itemType)
	end

	-- exported
	local function SetMultiselect(self, multi)
		self.multiselect = multi
		if multi then
			ShowMultiText(self)
			AddCloseButton(self)
		end
	end

	-- exported
	local function GetMultiselect(self)
		return self.multiselect
	end

	local function SetPulloutWidth(self, width)
		self.pulloutWidth = width
	end

	--[[ Constructor ]]--

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(widgetType)
		local frame = CreateFrame("Frame", nil, UIParent)
		local dropdown = CreateFrame("Frame", "AceGUI30DropDown"..count, frame, "UIDropDownMenuTemplate")

		local self = {}
		self.type = widgetType
		self.frame = frame
		self.dropdown = dropdown
		self.count = count
		frame.obj = self
		dropdown.obj = self

		self.OnRelease   = OnRelease
		self.OnAcquire   = OnAcquire

		self.ClearFocus  = ClearFocus

		self.SetText     = SetText
		self.SetValue    = SetValue
		self.GetValue    = GetValue
		self.SetList     = SetList
		self.SetLabel    = SetLabel
		self.SetDisabled = SetDisabled
		self.AddItem     = AddItem
		self.SetMultiselect = SetMultiselect
		self.GetMultiselect = GetMultiselect
		self.SetItemValue = SetItemValue
		self.SetItemDisabled = SetItemDisabled
		self.SetPulloutWidth = SetPulloutWidth

		self.alignoffset = 26

		frame:SetScript("OnHide",Dropdown_OnHide)

		dropdown:ClearAllPoints()
		dropdown:SetPoint("TOPLEFT",frame,"TOPLEFT",-15,0)
		dropdown:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",17,0)
		dropdown:SetScript("OnHide", nil)

		local left = _G[dropdown:GetName() .. "Left"]
		local middle = _G[dropdown:GetName() .. "Middle"]
		local right = _G[dropdown:GetName() .. "Right"]

		middle:ClearAllPoints()
		right:ClearAllPoints()

		middle:SetPoint("LEFT", left, "RIGHT", 0, 0)
		middle:SetPoint("RIGHT", right, "LEFT", 0, 0)
		right:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", 0, 17)

		local button = _G[dropdown:GetName() .. "Button"]
		self.button = button
		button.obj = self
		button:SetScript("OnEnter",Control_OnEnter)
		button:SetScript("OnLeave",Control_OnLeave)
		button:SetScript("OnClick",Dropdown_TogglePullout)

		local button_cover = CreateFrame("BUTTON",nil,self.frame)
		self.button_cover = button_cover
		button_cover.obj = self
		button_cover:SetPoint("TOPLEFT",self.frame,"BOTTOMLEFT",0,25)
		button_cover:SetPoint("BOTTOMRIGHT",self.frame,"BOTTOMRIGHT")
		button_cover:SetScript("OnEnter",Control_OnEnter)
		button_cover:SetScript("OnLeave",Control_OnLeave)
		button_cover:SetScript("OnClick",Dropdown_TogglePullout)

		local text = _G[dropdown:GetName() .. "Text"]
		self.text = text
		text.obj = self
		text:ClearAllPoints()
		text:SetPoint("RIGHT", right, "RIGHT" ,-43, 2)
		text:SetPoint("LEFT", left, "LEFT", 25, 2)

		local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
		label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		label:SetJustifyH("LEFT")
		label:SetHeight(18)
		label:Hide()
		self.label = label

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end
