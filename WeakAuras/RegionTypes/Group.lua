if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");

-- Default settings
local default = {
  controlledChildren = {},
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  frameStrata = 1,
  border = false,
  borderColor = { 0, 0, 0, 1 },
  backdropColor = { 1, 1, 1, 0.5 },
  borderEdge = "Square Full White",
  borderOffset = 4,
  borderInset = 1,
  borderSize = 2,
  borderBackdrop = "Blizzard Tooltip",
  scale = 1,
};

-- Called when first creating a new region/display
local function create(parent)
  -- Main region
  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  region:SetWidth(2);
  region:SetHeight(2);

  -- Border region
  local border = CreateFrame("frame", nil, region);
  region.border = border;

  WeakAuras.regionPrototype.create(region);

  return region;
end

-- Calculate bounding box
local function getRect(data, region)
  -- Temp variables
  local blx, bly, trx, try;
  blx, bly = data.xOffset or 0, data.yOffset or 0;

  local width = data.width or (region and  region.width)
  local height = data.height or (region and  region.height)

  if width == nil or height == nil then
    return blx, bly, blx, bly;
  end

  -- Calc bounding box
  if(data.selfPoint:find("LEFT")) then
    trx = blx + width;
  elseif(data.selfPoint:find("RIGHT")) then
    trx = blx;
    blx = blx - width;
  else
    blx = blx - (width/2);
    trx = blx + width;
  end
  if(data.selfPoint:find("BOTTOM")) then
    try = bly + height;
  elseif(data.selfPoint:find("TOP")) then
    try = bly;
    bly = bly - height;
  else
    bly = bly - (height/2);
    try = bly + height;
  end

  -- Return data
  return blx, bly, trx, try;
end

-- Modify a given region/display
local function modify(parent, region, data)
  data.selfPoint = "BOTTOMLEFT";
  WeakAuras.regionPrototype.modify(parent, region, data);
  -- Localize
  local border = region.border;

  -- Scale
  region:SetScale(data.scale and data.scale > 0 and data.scale or 1)

  -- Get overall bounding box
  local leftest, rightest, lowest, highest = 0, 0, 0, 0;
  local minLevel
  for index, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    local childRegion = WeakAuras.GetRegion(childId)
    if(childData) then
      local blx, bly, trx, try = getRect(childData, childRegion);
      leftest = math.min(leftest, blx);
      rightest = math.max(rightest, trx);
      lowest = math.min(lowest, bly);
      highest = math.max(highest, try);
      local frameLevel = childRegion and childRegion:GetFrameLevel()
      if frameLevel then
        minLevel = minLevel and math.min(minLevel, frameLevel) or frameLevel
      end
    end
  end
  region.blx = leftest;
  region.bly = lowest;
  region.trx = rightest;
  region.try = highest;

  -- Adjust frame-level sorting
  WeakAuras.FixGroupChildrenOrderForGroup(data);

  -- Control children (does not happen with "group")
  function region:UpdateBorder(childRegion)
    local border = region.border;
    -- Apply border settings
    if data.border then
      -- Initial visibility (of child that originated UpdateBorder(...))
      local childVisible = childRegion and childRegion.toShow or false;

      -- Scan children for visibility
      if not childVisible then
        for index, childId in ipairs(data.controlledChildren) do
          local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
          if childRegion and childRegion.toShow then
            childVisible = true;
            break;
          end
        end
      end

      -- Show border if child is visible
      if childVisible then
        border:SetBackdrop({
          edgeFile = data.borderEdge ~= "None" and SharedMedia:Fetch("border", data.borderEdge) or "",
          edgeSize = data.borderSize,
          bgFile = data.borderBackdrop ~= "None" and SharedMedia:Fetch("background", data.borderBackdrop) or "",
          insets = {
            left     = data.borderInset,
            right     = data.borderInset,
            top     = data.borderInset,
            bottom     = data.borderInset,
          },
        });
        border:SetBackdropBorderColor(data.borderColor[1], data.borderColor[2], data.borderColor[3], data.borderColor[4]);
        border:SetBackdropColor(data.backdropColor[1], data.backdropColor[2], data.backdropColor[3], data.backdropColor[4]);

        border:ClearAllPoints();
        border:SetPoint("bottomleft", region, "bottomleft", leftest-data.borderOffset, lowest-data.borderOffset);
        border:SetPoint("topright",   region, "topright",   rightest+data.borderOffset, highest+data.borderOffset);
        if minLevel then
          border:SetFrameLevel(minLevel - 1)
        end
        border:Show();
      else
        border:Hide();
      end
    else
      border:Hide();
    end
  end
  region:UpdateBorder()

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);
end

-- Register new region type with WeakAuras
WeakAuras.RegisterRegionType("group", create, modify, default);
