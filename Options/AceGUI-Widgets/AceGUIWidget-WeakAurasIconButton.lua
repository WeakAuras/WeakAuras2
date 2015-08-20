local Type, Version = "WeakAurasIconButton", 20
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- GLOBALS: GameTooltip UIParent WeakAuras WeakAurasOptionsSaved

local function Hide_Tooltip()
  GameTooltip:Hide();
end

local function Show_Tooltip(owner, line1, line2)
  GameTooltip:SetOwner(owner, "ANCHOR_NONE");
  GameTooltip:SetPoint("BOTTOM", owner, "TOP");
  GameTooltip:ClearLines();
  GameTooltip:AddLine(line1);
  GameTooltip:AddLine(line2, 1, 1, 1, 1);
  GameTooltip:Show();
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(52);
		self:SetHeight(52);
	end,
  ["OnRelease"] = function(self)
    self:ClearPick();
    self.texture:SetTexture();
  end,
  ["SetName"] = function(self, name)
    self.texture.name = name;
  end,
  ["GetName"] = function(self)
    return self.texture.name;
  end,
  ["SetTexture"] = function(self, texturePath)
    self.texture.path = texturePath;
    local success = self.texture:SetTexture(texturePath);
    if not(success) then
      self.texture:SetTexture("Interface\\BUTTONS\\UI-Quickslot-Depress.blp");
    end
    return success;
  end,
  ["GetTexturePath"] = function(self)
    return self.texture.path;
  end,
  ["SetClick"] = function(self, func)
    self.frame:SetScript("OnClick", func);
  end,
  ["Pick"] = function(self)
    self.frame:LockHighlight();
  end,
  ["ClearPick"] = function(self)
    self.frame:UnlockHighlight();
  end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
	local button = CreateFrame("BUTTON", nil, UIParent);
  button:SetHeight(52);
  button:SetWidth(52);

  local highlighttexture = button:CreateTexture(nil, "OVERLAY");
  --highlighttexture:SetTexture("Interface\\BUTTONS\\ButtonHilight-SquareQuickslot.blp");
  --highlighttexture:SetTexCoord(0.175, 0.875, 0.125, 0.825);
  highlighttexture:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  highlighttexture:SetVertexColor(0.25, 0.5, 1);
  highlighttexture:SetPoint("BOTTOMLEFT", button, 4, 4);
  highlighttexture:SetPoint("TOPRIGHT", button, -4, -4);
  button:SetHighlightTexture(highlighttexture);

  local texture = button:CreateTexture(nil, "OVERLAY");
  texture:SetAllPoints(button);
  texture.name = "Undefined";

  button:SetScript("OnEnter", function() Show_Tooltip(button, texture.name, texture.path:sub(17)) end);
	button:SetScript("OnLeave", Hide_Tooltip);

	local widget = {
		frame = button,
    texture = texture,
		type = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
