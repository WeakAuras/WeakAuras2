local default = {
  texture = "Interface\\PVPFrame\\PVP-Banner-Emblem-3",
  width = 200,
  height = 200,
  color = {1, 0, 0, 0.75},
  blendMode = "BLEND",
  rotation = 0,
  mirror = false,
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  xOffset = 0,
  yOffset = 0
};

local function create(parent)
  local frame = CreateFrame("FRAME", nil, UIParent);
  frame:SetMovable(true);
  frame:SetResizable(true);
  
  local texture = frame:CreateTexture();
  frame.texture = texture;
  texture:SetAllPoints(frame);
  return frame;
end

local function modify(parent, region, data)
  region.texture:SetTexture(data.texture);
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  region.texture:SetVertexColor(data.color[1], data.color[2], data.color[3], data.color[4]);
  region.texture:SetBlendMode(data.blendMode);
  region.texture:SetRotation((data.rotation / 180) * math.pi);
  region:ClearAllPoints();
  region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
end

WeakAuras.RegisterRegionType("texture", create, modify, default);