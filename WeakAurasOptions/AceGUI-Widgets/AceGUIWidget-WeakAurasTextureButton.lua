if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local Type, Version = "WeakAurasTextureButton", 26
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local GetAtlasInfo = C_Texture and  C_Texture.GetAtlasInfo or GetAtlasInfo

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
    self:SetWidth(128);
    self:SetHeight(128);
  end,
  ["OnRelease"] = function(self)
    self:ClearPick();
    self:SetOnUpdate(nil)
    self.texture:SetTexture();
  end,
  ["SetTexture"] = function(self, texturePath, name, IsStopMotion)
    self.texture:SetTexCoord(0, 1, 0, 1)
    local atlasInfo = GetAtlasInfo(texturePath)
    if atlasInfo then
      self.texture:SetAtlas(texturePath, false);
      self.texture.IsAtlas = true
      local width = atlasInfo.width
      local height = atlasInfo.height
      if IsStopMotion then
        local flipbookInfo = OptionsPrivate.GetFlipbookTileSize(texturePath)
        if flipbookInfo then
          width = flipbookInfo.tileWidth
          height = flipbookInfo.tileHeight
        end
      end
      if width > height then
        self.texture:SetSize(120, 120 * (height / width))
      elseif height > width then
        self.texture:SetSize(120 * (width / height), 120)
      else
        self.texture:SetSize(120, 120)
      end
    else
      self.texture:SetSize(120, 120)
      self.texture:SetTexture(texturePath, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
      self.texture.IsAtlas = nil
    end
    self.texture.path = texturePath;
    self.texture.name = name;
    self.texture.IsStopMotion = IsStopMotion
  end,
  ["ChangeTexture"] = function(self, r, g, b, a, texRotation, auraRotation, mirror, blendMode)
    if not self.texture.IsAtlas then
      local ulx,uly , llx,lly , urx,ury , lrx,lry;
      local angle = rad(135 - texRotation)
      local vx = math.cos(angle);
      local vy = math.sin(angle);
      ulx,uly , llx,lly , urx,ury , lrx,lry = 0.5+vx,0.5-vy , 0.5-vy,0.5-vx , 0.5+vy,0.5+vx , 0.5-vx,0.5+vy;
      if(mirror) then
        self.texture:SetTexCoord(urx,ury , lrx,lry , ulx,uly , llx,lly);
      else
        self.texture:SetTexCoord(ulx,uly , llx,lly , urx,ury , lrx,lry);
      end
    else
      self.texture:SetAtlas(self.texture.path)
    end
    self.texture:SetVertexColor(r, g, b, a);
    self.texture:SetBlendMode(blendMode);
    self.texture:SetRotation(auraRotation / 180 * math.pi)
  end,
  ["SetTexCoord"] = function(self, left, right, top, bottom)
    if self.texture.IsAtlas and not self.texture.IsStopMotion then
      self.texture:SetAtlas(self.texture.path)
    else
      self.texture:SetTexCoord(left, right, top, bottom);
    end
  end,
  ["SetOnUpdate"] = function(self, func)
    self.frame:SetScript("OnUpdate", func);
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
  local name = "WeakAurasTextureButton"..AceGUI:GetNextWidgetNum(Type);
  local button = CreateFrame("Button", name, UIParent, "OptionsListButtonTemplate");
  if BackdropTemplateMixin then
    Mixin(button, BackdropTemplateMixin)
  end
  button:SetHeight(128);
  button:SetWidth(128);
  button:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  });
  button:SetBackdropColor(0.1,0.1,0.1,0.2);
  button:SetBackdropBorderColor(0.4,0.4,0.4);

  local highlighttexture = button:CreateTexture(nil, "OVERLAY");
  highlighttexture:SetTexture("Interface\\BUTTONS\\ButtonHilight-SquareQuickslot.blp");
  highlighttexture:SetTexCoord(0.175, 0.875, 0.125, 0.825);
  highlighttexture:SetPoint("BOTTOMLEFT", button, 4, 4);
  highlighttexture:SetPoint("TOPRIGHT", button, -4, -4);
  button:SetHighlightTexture(highlighttexture);

  local texture = button:CreateTexture(nil, "OVERLAY");
  texture:SetPoint("CENTER")
  texture:SetSize(120, 120)

  button:SetScript("OnEnter", function() Show_Tooltip(button, texture.name, texture.path:gsub("\\", "\n")) end);
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
