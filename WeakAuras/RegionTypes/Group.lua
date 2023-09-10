if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

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
  local region = CreateFrame("Frame", nil, parent);
  region.regionType = "group"
  region:SetMovable(true);
  region:SetWidth(2);
  region:SetHeight(2);

  -- Border region
  local border = CreateFrame("Frame", nil, region, "BackdropTemplate")
  region.border = border;

  WeakAuras.regionPrototype.create(region);

  local oldSetFrameLevel = region.SetFrameLevel
  region.SetFrameLevel = function(self, level)
    oldSetFrameLevel(self, level)
    self.border:SetFrameLevel(level)
  end

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
  if data.information.groupOffset then
    data.selfPoint = "BOTTOMLEFT";
  else
    data.selfPoint = "CENTER";
  end
  WeakAuras.regionPrototype.modify(parent, region, data);
  -- Localize
  local border = region.border;

  -- Scale
  region:SetScale(data.scale and data.scale > 0 and data.scale <= 10 and data.scale or 1)

  -- Get overall bounding box
  local leftest, rightest, lowest, highest = 0, 0, 0, 0;
  for child in Private.TraverseLeafs(data) do
    local childRegion = WeakAuras.GetRegion(child.id)
    if(child) then
      local blx, bly, trx, try = getRect(child, childRegion);
      leftest = math.min(leftest, blx);
      rightest = math.max(rightest, trx);
      lowest = math.min(lowest, bly);
      highest = math.max(highest, try);
    end
  end
  region.blx = leftest;
  region.bly = lowest;
  region.trx = rightest;
  region.try = highest;

  -- Adjust frame-level sorting
  Private.FixGroupChildrenOrderForGroup(data);

  local hasDynamicSubGroups = false
  for index, childId in pairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if childData.regionType == "dynamicgroup" then
      hasDynamicSubGroups = true
      break;
    end
  end

  if not hasDynamicSubGroups then
    -- Control children (does not happen with "group")
    function region:UpdateBorder(childRegion)
      local border = region.border;
      -- Apply border settings
      if data.border then
        -- Initial visibility (of child that originated UpdateBorder(...))
        local childVisible = childRegion and childRegion.toShow or false;

        -- Scan children for visibility
        if not childVisible then
          for child in Private.TraverseLeafs(data) do
            local childRegion = Private.regions[child.id] and Private.regions[child.id].region;
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
          border:Show();
        else
          border:Hide();
        end
      else
        border:Hide();
      end
    end
    region:UpdateBorder()
  else
    region.UpdateBorder = function() end
    region.border:Hide()
  end

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);
end

-- Register new region type with WeakAuras
WeakAuras.RegisterRegionType("group", create, modify, default);
