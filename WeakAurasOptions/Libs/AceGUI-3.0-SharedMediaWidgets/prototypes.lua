-- Widget created by Yssaril
local DataVersion = 9004
local AGSMW = LibStub:NewLibrary("AceGUISharedMediaWidgets-1.0", DataVersion)

if not AGSMW then
  return	-- already loaded and no upgrade necessary
end

local AceGUI = LibStub("AceGUI-3.0")
local Media = LibStub("LibSharedMedia-3.0")

AGSMW = AGSMW or {}

AceGUIWidgetLSMlists = {
	['font'] = Media:HashTable("font"),
	['sound'] = Media:HashTable("sound"),
	['statusbar'] = Media:HashTable("statusbar"),
	['border'] = Media:HashTable("border"),
	['background'] = Media:HashTable("background"),
}

do
	local function disable(frame)
		frame.label:SetTextColor(.5,.5,.5)
		frame.text:SetTextColor(.5,.5,.5)
		frame.dropButton:Disable()
		if frame.displayButtonFont then
			frame.displayButtonFont:SetTextColor(.5,.5,.5)
			frame.displayButton:Disable()
		end
	end

	local function enable(frame)
		frame.label:SetTextColor(1,.82,0)
		frame.text:SetTextColor(1,1,1)
		frame.dropButton:Enable()
		if frame.displayButtonFont then
			frame.displayButtonFont:SetTextColor(1,1,1)
			frame.displayButton:Enable()
		end
	end

	local displayButtonBackdrop = {
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	}

	-- create or retrieve BaseFrame
	function AGSMW:GetBaseFrame()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:SetHeight(44)
		frame:SetWidth(200)

		local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
			label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
			label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
			label:SetJustifyH("LEFT")
			label:SetHeight(18)
			label:SetText("")
		frame.label = label

		local DLeft = frame:CreateTexture(nil, "ARTWORK")
			DLeft:SetWidth(25)
			DLeft:SetHeight(64)
			DLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -17, -21)
			DLeft:SetTexture([[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]])
			DLeft:SetTexCoord(0, 0.1953125, 0, 1)
		frame.DLeft = DLeft

		local DRight = frame:CreateTexture(nil, "ARTWORK")
			DRight:SetWidth(25)
			DRight:SetHeight(64)
			DRight:SetPoint("TOP", DLeft, "TOP")
			DRight:SetPoint("RIGHT", frame, "RIGHT", 17, 0)
			DRight:SetTexture([[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]])
			DRight:SetTexCoord(0.8046875, 1, 0, 1)
		frame.DRight = DRight

		local DMiddle = frame:CreateTexture(nil, "ARTWORK")
			DMiddle:SetHeight(64)
			DMiddle:SetPoint("TOP", DLeft, "TOP")
			DMiddle:SetPoint("LEFT", DLeft, "RIGHT")
			DMiddle:SetPoint("RIGHT", DRight, "LEFT")
			DMiddle:SetTexture([[Interface\Glues\CharacterCreate\CharacterCreate-LabelFrame]])
			DMiddle:SetTexCoord(0.1953125, 0.8046875, 0, 1)
		frame.DMiddle = DMiddle

		local text = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
			text:SetPoint("RIGHT",DRight,"RIGHT",-43,1)
			text:SetPoint("LEFT",DLeft,"LEFT",26,1)
			text:SetJustifyH("RIGHT")
			text:SetHeight(18)
			text:SetText("")
		frame.text = text

		local dropButton = CreateFrame("Button", nil, frame)
			dropButton:SetWidth(24)
			dropButton:SetHeight(24)
			dropButton:SetPoint("TOPRIGHT", DRight, "TOPRIGHT", -16, -18)
			dropButton:SetNormalTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Up]])
			dropButton:SetPushedTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Down]])
			dropButton:SetDisabledTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Disabled]])
			dropButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]], "ADD")
		frame.dropButton = dropButton

		frame.Disable = disable
		frame.Enable = enable
		return frame
	end

	function AGSMW:GetBaseFrameWithWindow()
		local frame = self:GetBaseFrame()

		local displayButton = CreateFrame("Button", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
			displayButton:SetHeight(42)
			displayButton:SetWidth(42)
			displayButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -2)
			displayButton:SetBackdrop(displayButtonBackdrop)
			displayButton:SetBackdropBorderColor(.5, .5, .5)
		frame.displayButton = displayButton

		frame.label:SetPoint("TOPLEFT",displayButton,"TOPRIGHT",1,2)

		frame.DLeft:SetPoint("BOTTOMLEFT", displayButton, "BOTTOMRIGHT", -17, -20)

		return frame
	end

end

do

	local sliderBackdrop = {
		["bgFile"] = [[Interface\Buttons\UI-SliderBar-Background]],
		["edgeFile"] = [[Interface\Buttons\UI-SliderBar-Border]],
		["tile"] = true,
		["edgeSize"] = 8,
		["tileSize"] = 8,
		["insets"] = {
			["left"] = 3,
			["right"] = 3,
			["top"] = 3,
			["bottom"] = 3,
		},
	}
	local frameBackdrop = {
		bgFile=[[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
		edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 9 },
	}

	local function OnMouseWheel(self, dir)
		self.slider:SetValue(self.slider:GetValue()+(15*dir*-1))
	end

	local function AddFrame(self, frame)
		frame:SetParent(self.contentframe)
		frame:SetFrameStrata(self:GetFrameStrata())
		frame:SetFrameLevel(self:GetFrameLevel() + 100)

		if next(self.contentRepo) then
			frame:SetPoint("TOPLEFT", self.contentRepo[#self.contentRepo], "BOTTOMLEFT", 0, 0)
			frame:SetPoint("RIGHT", self.contentframe, "RIGHT", 0, 0)
			self.contentframe:SetHeight(self.contentframe:GetHeight() + frame:GetHeight())
			self.contentRepo[#self.contentRepo+1] = frame
		else
			self.contentframe:SetHeight(frame:GetHeight())
			frame:SetPoint("TOPLEFT", self.contentframe, "TOPLEFT", 0, 0)
			frame:SetPoint("RIGHT", self.contentframe, "RIGHT", 0, 0)
			self.contentRepo[1] = frame
		end

		if self.contentframe:GetHeight() > UIParent:GetHeight()*2/5 - 20 then
			self.scrollframe:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -28, 12)
			self:SetHeight(UIParent:GetHeight()*2/5)
			self.slider:Show()
			self:SetScript("OnMouseWheel", OnMouseWheel)
			self.slider:SetMinMaxValues(0, self.contentframe:GetHeight()-self.scrollframe:GetHeight())
		else
			self.scrollframe:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -14, 12)
			self:SetHeight(self.contentframe:GetHeight()+25)
			self.slider:Hide()
			self:SetScript("OnMouseWheel", nil)
			self.slider:SetMinMaxValues(0, 0)
		end
		self.contentframe:SetWidth(self.scrollframe:GetWidth())
	end

	local function ClearFrames(self)
		for i, frame in ipairs(self.contentRepo) do
			frame:ReturnSelf()
			self.contentRepo[i] = nil
		end
	end

	local function slider_OnValueChanged(self, value)
		self.frame.scrollframe:SetVerticalScroll(value)
	end

	local DropDownCache = {}
	function AGSMW:GetDropDownFrame()
		local frame
		if next(DropDownCache) then
			frame = table.remove(DropDownCache)
		else
			frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
				frame:SetClampedToScreen(true)
				frame:SetWidth(188)
				frame:SetBackdrop(frameBackdrop)
				frame:SetFrameStrata("TOOLTIP")
				frame:EnableMouseWheel(true)

			local contentframe = CreateFrame("Frame", nil, frame)
				contentframe:SetWidth(160)
				contentframe:SetHeight(0)
			frame.contentframe = contentframe

			local scrollframe = CreateFrame("ScrollFrame", nil, frame)
				scrollframe:SetWidth(160)
				scrollframe:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -13)
				scrollframe:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 12)
				scrollframe:SetScrollChild(contentframe)
			frame.scrollframe = scrollframe

			contentframe:SetPoint("TOPLEFT", scrollframe)
			contentframe:SetPoint("TOPRIGHT", scrollframe)

			local bgTex = frame:CreateTexture(nil, "ARTWORK")
				bgTex:SetAllPoints(scrollframe)
			frame.bgTex = bgTex

			frame.AddFrame = AddFrame
			frame.ClearFrames = ClearFrames
			frame.contentRepo = {} -- store all our frames in here so we can get rid of them later

			local slider = CreateFrame("Slider", nil, scrollframe, BackdropTemplateMixin and "BackdropTemplate")
				slider:SetOrientation("VERTICAL")
				slider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -10)
				slider:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 10)
				slider:SetBackdrop(sliderBackdrop)
				slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Vertical]])
				slider:SetMinMaxValues(0, 1)
				--slider:SetValueStep(1)
				slider:SetWidth(12)
				slider.frame = frame
				slider:SetScript("OnValueChanged", slider_OnValueChanged)
			frame.slider = slider
		end
		frame:SetHeight(UIParent:GetHeight()*2/5)
		frame.slider:SetValue(0)
		frame:Show()
		return frame
	end

	function AGSMW:ReturnDropDownFrame(frame)
		ClearFrames(frame)
		frame:ClearAllPoints()
		frame:Hide()
		frame:SetBackdrop(frameBackdrop)
		frame.bgTex:SetTexture(nil)
		table.insert(DropDownCache, frame)
		return nil
	end
end