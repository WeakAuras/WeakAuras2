if not WeakAuras.IsLibsOK() then return end
--[[-----------------------------------------------------------------------------
Progress Bar Widget
A simple progress bar
-------------------------------------------------------------------------------]]
local Type, Version = "WeakAurasProgressBar", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local methods = {
	["OnAcquire"] = function(self)
		self:SetFullWidth(true)
    self:SetHeight(10)
    self.value = 0
    self.total = 1
	end,
  ["SetProgress"] = function(self, value, total)
    self.value = value
    self.total = total
    local p = value / total
    if p > 1 then
      p = 1
    end
    self.foreground:SetPoint("RIGHT", self.background, "LEFT", p * self.background:GetWidth(), 0)
  end,
  ["OnWidthSet"] = function(self)
    self:SetProgress(self.value, self.total)
  end
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
  local foreground = frame:CreateTexture(nil, "ARTWORK")
  local background = frame:CreateTexture(nil, "ARTWORK")
  foreground:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White")
  background:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White")
  background:SetVertexColor(0.5, 0.5, 0.5)
  foreground:SetDrawLayer("ARTWORK", 0);
  background:SetDrawLayer("ARTWORK", -1);

  background:SetAllPoints()
  foreground:SetPoint("TOPLEFT")
  foreground:SetPoint("BOTTOMLEFT")
  foreground:SetPoint("RIGHT", background, "LEFT", 0, 0)

	frame:Hide()

	local widget = {
		frame = frame,
    foreground = foreground,
    background = background,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
