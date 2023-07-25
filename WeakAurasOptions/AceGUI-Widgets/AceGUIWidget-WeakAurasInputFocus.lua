--[[-----------------------------------------------------------------------------
Input Widget that allows to show an alternative text when it does not have focus
-------------------------------------------------------------------------------]]
if not WeakAuras.IsLibsOK() then return end

local Type, Version = "WeakAurasInputFocus", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local OnEditFocusGained = function(self)
	local getWithFocus = self:GetParent().obj.userdata.option.getWithFocus
	if getWithFocus then
		self:SetText(getWithFocus() or "")
	end
end


local function Constructor()
	local button = AceGUI:Create("EditBox")
	button.type = Type
	button.editbox:SetScript("OnEditFocusGained", OnEditFocusGained)
	return button
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
