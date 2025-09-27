--@curseforge-project-slug: libdbicon-1-0@
-----------------------------------------------------------------------
-- LibDBIcon-1.0
--
-- Allows addons to easily create a lightweight minimap icon as an alternative to heavier LDB displays.
--

local DBICON10 = "LibDBIcon-1.0"
local DBICON10_MINOR = 55 -- Bump on changes
if not LibStub then error(DBICON10 .. " requires LibStub.") end
local ldb = LibStub("LibDataBroker-1.1", true)
if not ldb then error(DBICON10 .. " requires LibDataBroker-1.1.") end
local lib = LibStub:NewLibrary(DBICON10, DBICON10_MINOR)
if not lib then return end

lib.objects = lib.objects or {}
lib.callbackRegistered = lib.callbackRegistered or nil
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.radius = lib.radius or 5
local next, Minimap, CreateFrame, AddonCompartmentFrame = next, Minimap, CreateFrame, AddonCompartmentFrame
lib.tooltip = lib.tooltip or CreateFrame("GameTooltip", "LibDBIconTooltip", UIParent, "GameTooltipTemplate")
local isDraggingButton = false

function lib:IconCallback(event, name, key, value)
	if lib.objects[name] then
		if key == "icon" then
			lib.objects[name].icon:SetTexture(value)
			if lib:IsButtonInCompartment(name) and lib:IsButtonCompartmentAvailable() then
				local addonList = AddonCompartmentFrame.registeredAddons
				for i =1, #addonList do
					if addonList[i].text == name then
						addonList[i].icon = value
						return
					end
				end
			end
		elseif key == "iconCoords" then
			lib.objects[name].icon:UpdateCoord()
		elseif key == "iconR" then
			local _, g, b = lib.objects[name].icon:GetVertexColor()
			lib.objects[name].icon:SetVertexColor(value, g, b)
		elseif key == "iconG" then
			local r, _, b = lib.objects[name].icon:GetVertexColor()
			lib.objects[name].icon:SetVertexColor(r, value, b)
		elseif key == "iconB" then
			local r, g = lib.objects[name].icon:GetVertexColor()
			lib.objects[name].icon:SetVertexColor(r, g, value)
		end
	end
end
if not lib.callbackRegistered then
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__icon", "IconCallback")
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconCoords", "IconCallback")
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconR", "IconCallback")
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconG", "IconCallback")
	ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconB", "IconCallback")
	lib.callbackRegistered = true
end

local function getAnchors(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return "CENTER" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function onEnter(self)
	if isDraggingButton then return end

	for _, button in next, lib.objects do
		if button.showOnMouseover then
			button.fadeOut:Stop()
			button:SetAlpha(1)
		end
	end

	local obj = self.dataObject
	if obj.OnTooltipShow then
		lib.tooltip:SetOwner(self, "ANCHOR_NONE")
		lib.tooltip:SetPoint(getAnchors(self))
		obj.OnTooltipShow(lib.tooltip)
		lib.tooltip:Show()
	elseif obj.OnEnter then
		obj.OnEnter(self)
	end
end

local function onLeave(self)
	lib.tooltip:Hide()

	if not isDraggingButton then
		for _, button in next, lib.objects do
			if button.showOnMouseover then
				button.fadeOut:Play()
			end
		end
	end

	local obj = self.dataObject
	if obj.OnLeave then
		obj.OnLeave(self)
	end
end

local function onEnterCompartment(self, menu)
	local buttonName = menu.text
	local object = lib.objects[buttonName]
	if object and object.dataObject then
		if object.dataObject.OnTooltipShow then
			lib.tooltip:SetOwner(self, "ANCHOR_NONE")
			lib.tooltip:SetPoint(getAnchors(self))
			object.dataObject.OnTooltipShow(lib.tooltip)
			lib.tooltip:Show()
		elseif object.dataObject.OnEnter then
			object.dataObject.OnEnter(self)
		end
	end
end

local function onLeaveCompartment(self, menu)
	lib.tooltip:Hide()

	local buttonName = menu.text
	local object = lib.objects[buttonName]
	if object and object.dataObject then
		if object.dataObject.OnLeave then
			object.dataObject.OnLeave(self)
		end
	end
end

--------------------------------------------------------------------------------

local onDragStart, updatePosition

do
	local minimapShapes = {
		["ROUND"] = {true, true, true, true},
		["SQUARE"] = {false, false, false, false},
		["CORNER-TOPLEFT"] = {false, false, false, true},
		["CORNER-TOPRIGHT"] = {false, false, true, false},
		["CORNER-BOTTOMLEFT"] = {false, true, false, false},
		["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
		["SIDE-LEFT"] = {false, true, false, true},
		["SIDE-RIGHT"] = {true, false, true, false},
		["SIDE-TOP"] = {false, false, true, true},
		["SIDE-BOTTOM"] = {true, true, false, false},
		["TRICORNER-TOPLEFT"] = {false, true, true, true},
		["TRICORNER-TOPRIGHT"] = {true, false, true, true},
		["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
		["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
	}

	local rad, cos, sin, sqrt, max, min = math.rad, math.cos, math.sin, math.sqrt, math.max, math.min
	function updatePosition(button, position)
		local angle = rad(position or 225)
		local x, y, q = cos(angle), sin(angle), 1
		if x < 0 then q = q + 1 end
		if y > 0 then q = q + 2 end
		local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
		local quadTable = minimapShapes[minimapShape]
		local w = (Minimap:GetWidth() / 2) + lib.radius
		local h = (Minimap:GetHeight() / 2) + lib.radius
		if quadTable[q] then
			x, y = x*w, y*h
		else
			local diagRadiusW = sqrt(2*(w)^2)-10
			local diagRadiusH = sqrt(2*(h)^2)-10
			x = max(-w, min(x*diagRadiusW, w))
			y = max(-h, min(y*diagRadiusH, h))
		end
		button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	end
end

local function onClick(self, b)
	if self.dataObject.OnClick then
		self.dataObject.OnClick(self, b)
	end
end

local function onMouseDown(self)
	self.isMouseDown = true
	self.icon:UpdateCoord()
end

local function onMouseUp(self)
	self.isMouseDown = false
	self.icon:UpdateCoord()
end

do
	local deg, atan2 = math.deg, math.atan2
	local function onUpdate(self)
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		local pos = 225
		if self.db then
			pos = deg(atan2(py - my, px - mx)) % 360
			self.db.minimapPos = pos
		else
			pos = deg(atan2(py - my, px - mx)) % 360
			self.minimapPos = pos
		end
		updatePosition(self, pos)
	end

	function onDragStart(self)
		self:LockHighlight()
		self.isMouseDown = true
		self.icon:UpdateCoord()
		self:SetScript("OnUpdate", onUpdate)
		isDraggingButton = true
		lib.tooltip:Hide()
		for _, button in next, lib.objects do
			if button.showOnMouseover then
				button.fadeOut:Stop()
				button:SetAlpha(1)
			end
		end
	end
end

local function onDragStop(self)
	self:SetScript("OnUpdate", nil)
	self.isMouseDown = false
	self.icon:UpdateCoord()
	self:UnlockHighlight()
	isDraggingButton = false
	for _, button in next, lib.objects do
		if button.showOnMouseover then
			button.fadeOut:Play()
		end
	end
end

local defaultCoords = {0, 1, 0, 1}
local function updateCoord(self)
	local coords = self:GetParent().dataObject.iconCoords or defaultCoords
	local deltaX, deltaY = 0, 0
	if not self:GetParent().isMouseDown then
		deltaX = (coords[2] - coords[1]) * 0.05
		deltaY = (coords[4] - coords[3]) * 0.05
	end
	self:SetTexCoord(coords[1] + deltaX, coords[2] - deltaX, coords[3] + deltaY, coords[4] - deltaY)
end

local function createButton(name, object, db, customCompartmentIcon)
	local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
	button.dataObject = object
	button.db = db
	button:SetFrameStrata("MEDIUM")
	button:SetFixedFrameStrata(true)
	button:SetFrameLevel(8)
	button:SetFixedFrameLevel(true)
	button:SetSize(31, 31)
	button:RegisterForClicks("anyUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture(136477) --"Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(50, 50)
		overlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
		overlay:SetPoint("TOPLEFT", button, "TOPLEFT")
		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetSize(24, 24)
		background:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
		background:SetPoint("CENTER", button, "CENTER")
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(18, 18)
		icon:SetTexture(object.icon)
		icon:SetPoint("CENTER", button, "CENTER")
		button.icon = icon
	else
		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53, 53)
		overlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
		overlay:SetPoint("TOPLEFT")
		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetSize(20, 20)
		background:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
		background:SetPoint("TOPLEFT", 7, -5)
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(17, 17)
		icon:SetTexture(object.icon)
		icon:SetPoint("TOPLEFT", 7, -6)
		button.icon = icon
	end

	button.isMouseDown = false
	local r, g, b = button.icon:GetVertexColor()
	button.icon:SetVertexColor(object.iconR or r, object.iconG or g, object.iconB or b)

	button.icon.UpdateCoord = updateCoord
	button.icon:UpdateCoord()

	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnClick", onClick)
	if not db or not db.lock then
		button:SetScript("OnDragStart", onDragStart)
		button:SetScript("OnDragStop", onDragStop)
	end
	button:SetScript("OnMouseDown", onMouseDown)
	button:SetScript("OnMouseUp", onMouseUp)

	button.fadeOut = button:CreateAnimationGroup()
	local animOut = button.fadeOut:CreateAnimation("Alpha")
	animOut:SetOrder(1)
	animOut:SetDuration(0.2)
	animOut:SetFromAlpha(1)
	animOut:SetToAlpha(0)
	animOut:SetStartDelay(1)
	button.fadeOut:SetToFinalAlpha(true)

	lib.objects[name] = button

	if lib.loggedIn then
		updatePosition(button, db and db.minimapPos)
		if not db or not db.hide then
			button:Show()
		else
			button:Hide()
		end
	end

	if db and db.showInCompartment then
		lib:AddButtonToCompartment(name, customCompartmentIcon)
	end
	lib.callbacks:Fire("LibDBIcon_IconCreated", button, name) -- Fire 'Icon Created' callback
end

-- Wait a bit with the initial positioning to let any GetMinimapShape addons
-- load up.
if not lib.loggedIn then
	local frame = CreateFrame("Frame")
	frame:SetScript("OnEvent", function(self)
		for _, button in next, lib.objects do
			updatePosition(button, button.db and button.db.minimapPos)
			if not button.db or not button.db.hide then
				button:Show()
			else
				button:Hide()
			end
		end
		lib.loggedIn = true
		self:SetScript("OnEvent", nil)
	end)
	frame:RegisterEvent("PLAYER_LOGIN")
end

do
	local function OnMinimapEnter()
		if isDraggingButton then return end
		for _, button in next, lib.objects do
			if button.showOnMouseover then
				button.fadeOut:Stop()
				button:SetAlpha(1)
			end
		end
	end
	local function OnMinimapLeave()
		if isDraggingButton then return end
		for _, button in next, lib.objects do
			if button.showOnMouseover then
				button.fadeOut:Play()
			end
		end
	end
	Minimap:HookScript("OnEnter", OnMinimapEnter)
	Minimap:HookScript("OnLeave", OnMinimapLeave)
end

--------------------------------------------------------------------------------
-- Button API
--

function lib:Register(name, object, db, customCompartmentIcon)
	if not object.icon then error("Can't register LDB objects without icons set!") end
	if lib:GetMinimapButton(name) then error(DBICON10.. ": Object '".. name .."' is already registered.") end
	createButton(name, object, db, customCompartmentIcon)
end

function lib:Lock(name)
	local button = lib:GetMinimapButton(name)
	if button then
		button:SetScript("OnDragStart", nil)
		button:SetScript("OnDragStop", nil)
		if button.db then
			button.db.lock = true
		end
	end
end

function lib:Unlock(name)
	local button = lib:GetMinimapButton(name)
	if button then
		button:SetScript("OnDragStart", onDragStart)
		button:SetScript("OnDragStop", onDragStop)
		if button.db then
			button.db.lock = nil
		end
	end
end

function lib:Hide(name)
	local button = lib:GetMinimapButton(name)
	if button then
		button:Hide()
	end
end

function lib:Show(name)
	local button = lib:GetMinimapButton(name)
	if button then
		button:Show()
		updatePosition(button, button.db and button.db.minimapPos or button.minimapPos)
	end
end

function lib:IsRegistered(name)
	return lib.objects[name] and true or false
end

function lib:Refresh(name, db)
	local button = lib:GetMinimapButton(name)
	if button then
		if db then
			button.db = db
		end
		updatePosition(button, button.db and button.db.minimapPos or button.minimapPos)
		if not button.db or not button.db.hide then
			button:Show()
		else
			button:Hide()
		end
		if not button.db or not button.db.lock then
			button:SetScript("OnDragStart", onDragStart)
			button:SetScript("OnDragStop", onDragStop)
		else
			button:SetScript("OnDragStart", nil)
			button:SetScript("OnDragStop", nil)
		end
	end
end

function lib:ShowOnEnter(name, value)
	local button = lib:GetMinimapButton(name)
	if button then
		if value then
			button.showOnMouseover = true
			button.fadeOut:Stop()
			button:SetAlpha(0)
		else
			button.showOnMouseover = false
			button.fadeOut:Stop()
			button:SetAlpha(1)
		end
	end
end

function lib:GetMinimapButton(name)
	return lib.objects[name]
end

function lib:GetButtonList()
	local t = {}
	for name in next, lib.objects do
		t[#t+1] = name
	end
	return t
end

function lib:SetButtonRadius(radius)
	if type(radius) == "number" then
		lib.radius = radius
		for _, button in next, lib.objects do
			updatePosition(button, button.db and button.db.minimapPos or button.minimapPos)
		end
	end
end

function lib:SetButtonToPosition(button, position)
	updatePosition(lib.objects[button] or button, position)
end

--------------------------------------------------------------------------------
-- Addon Compartment API
--

function lib:IsButtonCompartmentAvailable()
	if AddonCompartmentFrame then
		return true
	end
end

function lib:IsButtonInCompartment(buttonName)
	local object = lib.objects[buttonName]
	if object and object.db and object.db.showInCompartment then
		return true
	end
	return false
end

function lib:AddButtonToCompartment(buttonName, customIcon)
	if lib:IsButtonCompartmentAvailable() then
		local object = lib.objects[buttonName]
		if object and not object.compartmentData then
			if object.db then
				object.db.showInCompartment = true
			end
			object.compartmentData = {
				text = buttonName,
				icon = customIcon or object.dataObject.icon,
				notCheckable = true,
				registerForAnyClick = true,
				func = function(_, menuInputData, menu)
					object.dataObject.OnClick(menu, menuInputData.buttonName)
				end,
				funcOnEnter = onEnterCompartment,
				funcOnLeave = onLeaveCompartment,
			}
			AddonCompartmentFrame:RegisterAddon(object.compartmentData)
		end
	end
end

function lib:RemoveButtonFromCompartment(buttonName)
	if lib:IsButtonCompartmentAvailable() then
		local object = lib.objects[buttonName]
		if object and object.compartmentData then
			for i = 1, #AddonCompartmentFrame.registeredAddons do
				local entry = AddonCompartmentFrame.registeredAddons[i]
				if entry == object.compartmentData then
					object.compartmentData = nil
					if object.db then
						object.db.showInCompartment = nil
					end
					table.remove(AddonCompartmentFrame.registeredAddons, i)
					AddonCompartmentFrame:UpdateDisplay()
					return
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Upgrades
--

for name, button in next, lib.objects do
	local db = button.db
	if not db or not db.lock then
		button:SetScript("OnDragStart", onDragStart)
		button:SetScript("OnDragStop", onDragStop)
	end
	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnClick", onClick)
	button:SetScript("OnMouseDown", onMouseDown)
	button:SetScript("OnMouseUp", onMouseUp)

	if not button.fadeOut then -- Upgrade to 39
		button.fadeOut = button:CreateAnimationGroup()
		local animOut = button.fadeOut:CreateAnimation("Alpha")
		animOut:SetOrder(1)
		animOut:SetDuration(0.2)
		animOut:SetFromAlpha(1)
		animOut:SetToAlpha(0)
		animOut:SetStartDelay(1)
		button.fadeOut:SetToFinalAlpha(true)
	end
end
lib:SetButtonRadius(lib.radius) -- Upgrade to 40
if lib.notCreated then -- Upgrade to 50
	for name in next, lib.notCreated do
		createButton(name, lib.notCreated[name][1], lib.notCreated[name][2])
	end
	lib.notCreated = nil
end