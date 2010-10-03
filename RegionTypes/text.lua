local SharedMedia = LibStub("LibSharedMedia-3.0");
  
local default = {
  displayText = "New",
  outline = true,
  color = {1, 1, 1, 1},
  justify = "CENTER",
  selfPoint = "BOTTOM",
  anchorPoint = "CENTER",
  xOffset = 0,
  yOffset = 0,
  font = "Friz Quadrata TT",
  fontSize = 12
};

local function create(parent)
  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  
  local text = region:CreateFontString(nil, "OVERLAY");
  region.text = text;
  text:SetNonSpaceWrap(true);
  
  return region;
end

local function modify(parent, region, data)
  local text = region.text;
  
  local fontPath = SharedMedia:Fetch("font", data.font);
  text:SetFont(fontPath, data.fontSize, data.outline and "OUTLINE" or nil);
  text:SetTextHeight(data.fontSize);
  text:SetText(data.displayText);
  text:SetTextColor(data.color[1], data.color[2], data.color[3], data.color[4]);
  text:SetJustifyH(data.justify);
  
  text:ClearAllPoints();
  text:SetPoint("CENTER", UIParent, "CENTER");
  data.width = text:GetWidth() + 16;
  data.height = text:GetHeight() + 16;
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  text:ClearAllPoints();
  text:SetPoint("CENTER", region, "CENTER");
  
  region:ClearAllPoints();
  region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
  
  function region:SetDurationInfo()
  end
end

WeakAuras.RegisterRegionType("text", create, modify, default);