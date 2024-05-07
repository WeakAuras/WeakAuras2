-- Widget is based on the AceGUIWidget-DropDown.lua supplied with AceGUI-3.0
-- Original Widget created by Yssaril, modified by WeakAuras Team to handle Atlas

local AceGUI = LibStub("AceGUI-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local AGSMW = LibStub("AceGUISharedMediaWidgets-1.0")

do
	local widgetType = "WA_LSM30_StatusbarAtlas"
	local widgetVersion = 1

	local contentFrameCache = {}
	local function ReturnSelf(self)
		self:ClearAllPoints()
		self:Hide()
		self.check:Hide()
		table.insert(contentFrameCache, self)
	end

	local function ContentOnClick(this, button)
		local self = this.obj
		self:Fire("OnValueChanged", this.text:GetText())
		if self.dropdown then
			self.dropdown = AGSMW:ReturnDropDownFrame(self.dropdown)
		end
	end

	local function GetContentLine()
		local frame
		if next(contentFrameCache) then
			frame = table.remove(contentFrameCache)
		else
      ---@class Button
			frame = CreateFrame("Button", nil, UIParent)
				--frame:SetWidth(200)
				frame:SetHeight(18)
				frame:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD")
				frame:SetScript("OnClick", ContentOnClick)
			local check = frame:CreateTexture("OVERLAY")
				check:SetWidth(16)
				check:SetHeight(16)
				check:SetPoint("LEFT",frame,"LEFT",1,-1)
				check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
				check:Hide()
			frame.check = check
			local bar = frame:CreateTexture("ARTWORK")
				bar:SetHeight(16)
				bar:SetPoint("LEFT",check,"RIGHT",1,0)
				bar:SetPoint("RIGHT",frame,"RIGHT",-1,0)
			frame.bar = bar
			local text = frame:CreateFontString(nil,"OVERLAY","GameFontWhite")

				local font, size = text:GetFont()
				text:SetFont(font,size,"OUTLINE")

				text:SetPoint("TOPLEFT", check, "TOPRIGHT", 3, 0)
				text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 0)
				text:SetJustifyH("LEFT")
				text:SetText("Test Test Test Test Test Test Test")
			frame.text = text
			frame.ReturnSelf = ReturnSelf
		end
		frame:Show()
		return frame
	end

	local function OnAcquire(self)
		self:SetHeight(44)
		self:SetWidth(200)
	end

	local function OnRelease(self)
		self:SetText("")
		self:SetLabel("")
		self:SetDisabled(false)

		self.value = nil
		self.list = nil
		self.open = nil
		self.hasClose = nil

		self.frame:ClearAllPoints()
		self.frame:Hide()
	end

	local function SetValue(self, value) -- Set the value to an item in the List.
		if self.list then
			self:SetText(value or "")
		end
		self.value = value
	end

	local function GetValue(self)
		return self.value
	end

	local function SetList(self, list) -- Set the list of values for the dropdown (key => value pairs)
    self.list = list or Media:HashTable("statusbar")
	end


	local function SetText(self, text) -- Set the text displayed in the box.
		self.frame.text:SetText(text or "")
		local statusbar = self.list[text] ~= text and self.list[text] or Media:Fetch('statusbar', text)
		if type(statusbar) == "string" and C_Texture.GetAtlasInfo(statusbar) ~= nil then
			self.bar:SetAtlas(statusbar)
		else
			self.bar:SetTexture(statusbar)
		end
	end

	local function SetLabel(self, text) -- Set the text for the label.
		self.frame.label:SetText(text or "")
	end

	local function AddItem(self, key, value) -- Add an item to the list.
		self.list = self.list or {}
		self.list[key] = value
	end
	local SetItemValue = AddItem -- Set the value of a item in the list. <<same as adding a new item>>

	local function SetMultiselect(self, flag) end -- Toggle multi-selecting. <<Dummy function to stay inline with the dropdown API>>
	local function GetMultiselect() return false end-- Query the multi-select flag. <<Dummy function to stay inline with the dropdown API>>
	local function SetItemDisabled(self, key) end-- Disable one item in the list. <<Dummy function to stay inline with the dropdown API>>

	local function SetDisabled(self, disabled) -- Disable the widget.
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end

	local function textSort(a,b)
		return string.upper(a) < string.upper(b)
	end

	local sortedlist = {}
	local function ToggleDrop(this)
		local self = this.obj
		if self.dropdown then
			self.dropdown = AGSMW:ReturnDropDownFrame(self.dropdown)
			AceGUI:ClearFocus()
		else
			AceGUI:SetFocus(self)
			self.dropdown = AGSMW:GetDropDownFrame()
			local width = self.frame:GetWidth()
			self.dropdown:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT")
			self.dropdown:SetPoint("TOPRIGHT", self.frame, "BOTTOMRIGHT", width < 160 and (160 - width) or 0, 0)
			for k, v in pairs(self.list) do
				sortedlist[#sortedlist+1] = k
			end
			table.sort(sortedlist, textSort)
			for i, k in ipairs(sortedlist) do
				local f = GetContentLine()
				f.text:SetText(k)
				--print(k)
				if k == self.value then
					f.check:Show()
				end

				local statusbar = self.list[k] ~= k and self.list[k] or Media:Fetch('statusbar',k)
				if type(statusbar) == "string" and C_Texture.GetAtlasInfo(statusbar) ~= nil then
					f.bar:SetAtlas(statusbar)
				else
					f.bar:SetTexture(statusbar)
				end
				f.obj = self
				f.dropdown = self.dropdown
				self.dropdown:AddFrame(f)
			end
			wipe(sortedlist)
		end
	end

	local function ClearFocus(self)
		if self.dropdown then
			self.dropdown = AGSMW:ReturnDropDownFrame(self.dropdown)
		end
	end

	local function OnHide(this)
		local self = this.obj
		if self.dropdown then
			self.dropdown = AGSMW:ReturnDropDownFrame(self.dropdown)
		end
	end

	local function Drop_OnEnter(this)
		this.obj:Fire("OnEnter")
	end

	local function Drop_OnLeave(this)
		this.obj:Fire("OnLeave")
	end

	local function Constructor()
		local frame = AGSMW:GetBaseFrame()
		local self = {}

		self.type = widgetType
		self.frame = frame
		frame.obj = self
		frame.dropButton.obj = self
		frame.dropButton:SetScript("OnEnter", Drop_OnEnter)
		frame.dropButton:SetScript("OnLeave", Drop_OnLeave)
		frame.dropButton:SetScript("OnClick",ToggleDrop)
		frame:SetScript("OnHide", OnHide)

		local bar = frame:CreateTexture(nil, "OVERLAY")
			bar:SetPoint("TOPLEFT", frame,"TOPLEFT",6,-25)
			bar:SetPoint("BOTTOMRIGHT", frame,"BOTTOMRIGHT", -21, 5)
			bar:SetAlpha(0.5)
		self.bar = bar

		self.alignoffset = 31

		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.ClearFocus = ClearFocus
		self.SetText = SetText
		self.SetValue = SetValue
		self.GetValue = GetValue
		self.SetList = SetList
		self.SetLabel = SetLabel
		self.SetDisabled = SetDisabled
		self.AddItem = AddItem
		self.SetMultiselect = SetMultiselect
		self.GetMultiselect = GetMultiselect
		self.SetItemValue = SetItemValue
		self.SetItemDisabled = SetItemDisabled
		self.ToggleDrop = ToggleDrop

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)

end
