local SharedMedia = LibStub("LibSharedMedia-3.0");

local default = {
  controlledChildren = {},
  border = "None",
  borderOffset = 16,
  background = "None",
  backgroundInset = 0,
  grow = "DOWN",
  align = "CENTER",
  space = 2,
  stagger = 0,
  sort = "none",
  animate = false,
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  radius = 200,
  rotation = 0,
  constantFactor = "RADIUS",
  frameStrata = 1,
  scale = 1,
};

local function create(parent)
  local region = CreateFrame("FRAME", nil, parent);
  region:SetHeight(16);
  region:SetWidth(16);
  region:SetMovable(true);

  local background = CreateFrame("frame", nil, region);
  region.background = background;

  region.trays = {};
  region.suspended = 0

  WeakAuras.regionPrototype.create(region);

  return region;
end

function WeakAuras.GetPolarCoordinates(x, y, originX, originY)
  local dX, dY = x - originX, y - originY;

  local r = math.sqrt(dX * dX + dY * dY);
  local theta = atan2(dY, dX);

  return r, theta;
end

local selfPoints = {
  default = "CENTER",
  RIGHT = function(data)
    if data.align  == "LEFT" then
      return "TOPLEFT"
    elseif data.align == "RIGHT" then
      return "BOTTOMLEFT"
    else
      return "LEFT"
    end
  end,
  LEFT = function(data)
    if data.align  == "LEFT" then
      return "TOPRIGHT"
    elseif data.align == "RIGHT" then
      return "BOTTOMRIGHT"
    else
      return "RIGHT"
    end
  end,
  UP = function(data)
    if data.align == "LEFT" then
      return "BOTTOMLEFT"
    elseif data.align == "RIGHT" then
      return "BOTTOMRIGHT"
    else
      return "BOTTOM"
    end
  end,
  DOWN = function(data)
    if data.align == "LEFT" then
      return "TOPLEFT"
    elseif data.align == "RIGHT" then
      return "TOPRIGHT"
    else
      return "TOP"
    end
  end,
  HORIZONTAL = function(data)
    if data.align == "LEFT" then
      return "TOP"
    elseif data.align == "RIGHT" then
      return "BOTTOM"
    else
      return "CENTER"
    end
  end,
  VERTICAL = function(data)
    if data.align == "LEFT" then
      return "LEFT"
    elseif data.align == "RIGHT" then
      return "RIGHT"
    else
      return "CENTER"
    end
  end,
  CIRCLE = "CENTER",
  COUNTERCIRCLE = "CENTER",
}

local function noop() end

local function polarToRect(r, theta)
  return r * math.cos(theta), r * math.sin(theta)
end

local growers = {
  LEFT = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX, startY
      local i = 1
      while i <= numVisible do
        local pos = {x, y}
        local regionData = activeRegions[i]
        newPositions[i] = pos
        x = x + (regionData.data.width or regionData.region.width) + space
        y = y + stagger
        i = i + 1
      end
    end
  end,
  RIGHT = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX, startY
      local i = 1
      while i <= numVisible do
        local pos = {x, y}
        local regionData = activeRegions[i]
        newPositions[i] = pos
        x = x - (regionData.data.width or regionData.region.width) - space
        y = y + data.stagger
        i = i + 1
      end
    end
  end,
  UP = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX, startY
      local i = 1
      while i <= numVisible do
        local pos = {x, y}
        local regionData = activeRegions[i]
        newPositions[i] = pos
        x = x + stagger
        y = y + (regionData.data.height or regionData.region.height) + space
        i = i + 1
      end
    end
  end,
  DOWN = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX, startY
      local i = 1
      while i <= numVisible do
        local pos = {x, y}
        local regionData = activeRegions[i]
        newPositions[i] = pos
        x = x + stagger
        y = y - (regionData.data.height or regionData.region.height) - space
        i = i + 1
      end
    end
  end,
  HORIZONTAL = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local midX, midY = 0, 0
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local totalWidth = 0
      for i = 1, numVisible do
        local regionData = activeRegions[i]
        totalWidth = totalWidth + (regionData.data.width or regionData.region.width) + space
      end
      local x, y = midX - totalWidth/2, midY - (stagger * (numVisible - 1)/2)
      local i = 1
      while i <= numVisible do
        local pos = {x, y}
        local regionData = activeRegions[i]
        newPositions[i] = pos
        x = x + (regionData.data.width or regionData.region.width) + space
        y = y + stagger
        i = i + 1
      end
    end
  end,
  VERTICAL = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local midX, midY = 0, 0
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local totalHeight = 0
      for i = 1, numVisible do
        local regionData = activeRegions[i]
        totalHeight = totalHeight + (regionData.data.height or regionData.region.height) + space
      end
      local x, y = midX - (stagger * (numVisible - 1)/2), midY - totalHeight/2
      local i = 1
      while i <= numVisible do
        local pos = {x, y}
        local regionData = activeRegions[i]
        newPositions[i] = pos
        x = x + stagger
        y = y + (regionData.data.height or regionData.region.height) + space
        i = i + 1
      end
    end
  end,
  CIRCLE = function(data)
    local oX, oY = 0, 0
    local constantFactor = data.constantFactor
    local space = data.space or 0
    local radius = data.radius or 0
    local limit = data.useLimit and data.limit or math.huge
    local sAngle = (data.rotation or 0) * math.pi/180
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local r
      if constantFactor == "RADIUS" then
        r = radius
      else
        if numVisible <= 1 then
          r = 0
        else
          r = (numVisible * space) / (2 * math.pi)
        end
      end
      local dAngle = 2 * math.pi/numVisible
      local theta = sAngle
      local i = 1
      while i <= numVisible do
        local pos = {polarToRect(r, theta)}
        newPositions[i] = pos
        theta = theta + dAngle
        i = i + 1
      end
    end
  end,
  COUNTERCIRCLE = function(data)
    local oX, oY = 0, 0
    local constantFactor = data.constantFactor
    local space = data.space or 0
    local radius = data.radius or 0
    local limit = data.useLimit and data.limit or math.huge
    local sAngle = (data.rotation or 0) * math.pi/180
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local r
      if constantFactor == "RADIUS" then
        r = radius
      else
        if numVisible <= 1 then
          r = 0
        else
          r = (numVisible * space) / (2 * math.pi)
        end
      end
      local dAngle = -2 * math.pi/numVisible
      local theta = sAngle
      local i = 1
      while i <= numVisible do
        local pos = {polarToRect(r, theta)}
        newPositions[i] = pos
        theta = theta + dAngle
        i = i + 1
      end
    end
  end,
  GRID = function(data)
    local startX, startY = 0, 0
    local gridType = data.gridType
    -- in a grid context, space is the space between items on the same row/column
    -- and stagger is the distance between columns
    local space = data.space
    local stagger = data.stagger
    local columnLimit = data.columnLimit or math.huge
    local rowIsHorizontal
    if gridType:find("^RIGHT") or gridType:find("^LEFT") then
      rowIsHorizontal = true
    end
    local xmul = gridType:find("RIGHT") and 1 or -1
    local ymul = gridType:find("UP") and 1 or -1
    local limit = data.useLimit and data.limit or math.huge
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX, startY
      local i = 1
      while i <= numVisible do
        local pos = {x, y}
        if i % columnLimit == 0 then
          if rowIsHorizontal then
            x = startX
            y = y + stagger * ymul
          else
            x = x + stagger * xmul
          end
        else
          if rowIsHorizontal then
            x = x + space * xmul
          else
            y = y + space + ymul
          end
        end
        i = i + 1
      end
    end
  end
}
growers.default = growers.DOWN

local function modify(parent, region, data)
  WeakAuras.FixGroupChildrenOrderForGroup(data);
  -- Scale
  region:SetScale(data.scale and data.scale > 0 and data.scale or 1)

  local selfPoint = selfPoints[data.grow] or selfPoints.default
  if type(selfPoint) == "function" then
    selfPoint = selfPoint(data)
  end
  data.selfPoint = selfPoint;

  WeakAuras.regionPrototype.modify(parent, region, data);

  local background = region.background;

  local bgFile = data.background ~= "None" and SharedMedia:Fetch("background", data.background or "") or "";
  local edgeFile = data.border ~= "None" and SharedMedia:Fetch("border", data.border or "") or "";
  background:SetBackdrop({
    bgFile = bgFile,
    edgeFile = edgeFile,
    tile = false,
    tileSize = 0,
    edgeSize = 16,
    insets = {
      left = data.backgroundInset,
      right = data.backgroundInset,
      top = data.backgroundInset,
      bottom = data.backgroundInset
    }
  });
  background:SetPoint("bottomleft", region, "bottomleft", -1 * data.borderOffset, -1 * data.borderOffset);
  background:SetPoint("topright", region, "topright", data.borderOffset, data.borderOffset);

  region.controlledRegions = {};

  function region:EnsureControlledRegions()
    local anyIndexInfo = false;
    local dataIndex = 1;
    local regionIndex = 1;
    while(dataIndex <= #data.controlledChildren) do
      local childId = data.controlledChildren[dataIndex];
      local childData = WeakAuras.GetData(childId);
      local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
      if(childRegion) then
        if not(region.controlledRegions[regionIndex]) then
          region.controlledRegions[regionIndex] = {};
        end
        region.controlledRegions[regionIndex].id = childId;
        region.controlledRegions[regionIndex].data = childData;
        region.controlledRegions[regionIndex].region = childRegion;
        region.controlledRegions[regionIndex].key = tostring(region.controlledRegions[regionIndex].region);
        anyIndexInfo = anyIndexInfo or childRegion.state and childRegion.state.index;
        region.controlledRegions[regionIndex].dataIndex = dataIndex;
        dataIndex = dataIndex + 1;
        regionIndex = regionIndex + 1;
        if(childData and WeakAuras.clones[childId]) then
          for cloneId, cloneRegion in pairs(WeakAuras.clones[childId]) do
            if not(region.controlledRegions[regionIndex]) then
              region.controlledRegions[regionIndex] = {};
            end
            region.controlledRegions[regionIndex].id = childId;
            region.controlledRegions[regionIndex].data = childData;
            region.controlledRegions[regionIndex].cloneId = cloneId;
            region.controlledRegions[regionIndex].region = cloneRegion;
            region.controlledRegions[regionIndex].key = tostring(region.controlledRegions[regionIndex].region);
            anyIndexInfo = anyIndexInfo or cloneRegion.state and cloneRegion.state.index;
            region.controlledRegions[regionIndex].dataIndex = dataIndex;
            regionIndex = regionIndex + 1;
          end
        end
      else
        dataIndex = dataIndex + 1;
      end
    end
    while(region.controlledRegions[regionIndex]) do
      region.controlledRegions[regionIndex] = nil;
      regionIndex = regionIndex + 1;
    end

    local function expirationTime(region)
      if (region.region and region.region.state) then
        local expires = region.region.state.expirationTime;
        if (expires and expires > 0 and expires > GetTime()) then
          return expires;
        end
      end
      return nil;
    end

    local function compareExpirationTimes(regionA, regionB)
      local aExpires = expirationTime(regionA);
      local bExpires = expirationTime(regionB);


      if (aExpires and bExpires) then
        if (aExpires == bExpires) then
          return nil;
        end
        return aExpires < bExpires;
      end

      if (aExpires) then
        return false;
      end

      if (bExpires) then
        return true;
      end

      return nil;
    end

    if(data.sort == "ascending") then
      table.sort(region.controlledRegions, function(a, b)
        local result = compareExpirationTimes(a, b);
        if (result == nil) then
          return a.dataIndex < b.dataIndex;
        end
        return result;
      end);
    elseif(data.sort == "descending") then
      table.sort(region.controlledRegions, function(a, b)
        local result = compareExpirationTimes(a, b);
        if (result == nil) then
          return a.dataIndex < b.dataIndex;
        end
        return not result;
      end);
    elseif(data.sort == "hybrid") then
      table.sort(region.controlledRegions, function(a, b)
        if (not b) then return true; end
        if (not a) then return false; end;
        local aIndex;
        local bIndex;
        if (data.sortHybridTable and data.sortHybridTable[a.id]) then
          aIndex = a.dataIndex;
        end

        if (data.sortHybridTable and data.sortHybridTable[b.id]) then
          bIndex = b.dataIndex;
        end

        if (aIndex == bIndex) then
          local result = compareExpirationTimes(a, b);
          if (result == nil) then
            return a.dataIndex < b.dataIndex;
          end
          if (data.hybridSortMode == "descending") then
            result = not result;
          end
          return result;
        end

        if (aIndex and bIndex) then
          return aIndex < bIndex;
        end

        if (aIndex) then
          return data.hybridPosition == "hybridFirst";
        end

        if (bIndex) then
          return data.hybridPosition ~= "hybridFirst";
        end

        -- Can't happen
      end);
    elseif(anyIndexInfo) then
      table.sort(region.controlledRegions, function(a, b)
        if (a.dataIndex ~= b.dataIndex) then
          return (a.dataIndex or 0) < (b.dataIndex or 0)
        end

        local aIndex = a.region.state and a.region.state.index;
        local bIndex = b.region.state and b.region.state.index;
        if (aIndex == nil) then
          return false;
        end
        if (bIndex == nil) then
          return true;
        end

        return aIndex < bIndex;
      end)
    end
  end

  function region:EnsureTrays()
    region:EnsureControlledRegions();
    for index, regionData in ipairs(region.controlledRegions) do
      if not(region.trays[regionData.key]) then
        region.trays[regionData.key] = CreateFrame("Frame", nil, region);
        regionData.region:SetParent(region.trays[regionData.key])
      else
        regionData.region:SetParent(region.trays[regionData.key]) -- removing and adding aura back doesnt delete tray, so need to reparent it
      end
      if(regionData.data and regionData.region) then
        local tray = region.trays[regionData.key];
        tray:SetWidth(regionData.data.width or regionData.region.width);
        tray:SetHeight(regionData.data.height or regionData.region.height);

        regionData.region:SetAnchor(selfPoint, tray, selfPoint);
      end
    end
  end

  function region:DoResize()
    local numVisible = 0;
    local minX, maxX, minY, maxY;
    for index, regionData in pairs(region.controlledRegions) do
      local childId = regionData.id;
      local childData = regionData.data;
      local childRegion = regionData.region;
      if(childData and childRegion) then
        if(childRegion.toShow or  WeakAuras.IsAnimating(childRegion) == "finish") then
          numVisible = numVisible + 1;
          local regionLeft, regionRight, regionTop, regionBottom = childRegion:GetLeft(), childRegion:GetRight(), childRegion:GetTop(), childRegion:GetBottom();
          if(regionLeft and regionRight and regionTop and regionBottom) then
            minX = minX and min(regionLeft, minX) or regionLeft;
            maxX = maxX and max(regionRight, maxX) or regionRight;
            minY = minY and min(regionBottom, minY) or regionBottom;
            maxY = maxY and max(regionTop, maxY) or regionTop;
          end
        end
      end
    end
    if(numVisible > 0) then
      minX, maxX, minY, maxY = minX or 0, maxX or 0, minY or 0, maxY or 0;
      if(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
        local originX, originY = region:GetCenter();
        originX = originX or 0;
        originY = originY or 0;
        if(originX - minX > maxX - originX) then
          maxX = originX + (originX - minX);
        elseif(originX - minX < maxX - originX) then
          minX = originX - (maxX - originX);
        end
        if(originY - minY > maxY - originY) then
          maxY = originY + (originY - minY);
        elseif(originY - minY < maxY - originY) then
          minY = originY - (maxY - originY);
        end
      end
      region:Show();
      local newWidth, newHeight = maxX - minX, maxY - minY;
      newWidth = newWidth > 0 and newWidth or 16;
      newHeight = newHeight > 0 and newHeight or 16;
      region:SetWidth(newWidth);
      region.currentWidth = newWidth;
      region:SetHeight(newHeight);
      region.currentHeight = newHeight;
      if(data.animate and region.previousWidth and region.previousHeight) then
        local anim = {
          type = "custom",
          duration = 0.2,
          use_scale = true,
          scalex = region.previousWidth / newWidth,
          scaley = region.previousHeight / newHeight
        };

        WeakAuras.Animate("group", data, "start", anim, region, true);
      end
      region.previousWidth = newWidth;
      region.previousHeight = newHeight;
    else
      if(data.animate) then
        local anim = {
          type = "custom",
          duration = 0.2,
          use_scale = true,
          scalex = 0.1,
          scaley = 0.1
        };

        WeakAuras.Animate("group", data, "finish", anim, region, nil, function()
          region:Hide();
        end)
      else
        region:Hide();
      end
      region.previousWidth = 1;
      region.previousHeight = 1;
    end

    if(WeakAuras.IsOptionsOpen()) then
      WeakAuras.OptionsFrame().moversizer:ReAnchor();
    end
  end

  local grower = growers[data.grow] or growers.default
  region.growFunc = grower(data)

  function region:PositionActiveRegions()
    region:EnsureTrays();
    local childData, childRegion;
    local activeRegions = {}
    for index, regionData in pairs(region.controlledRegions) do
      childData = regionData.data;
      childRegion = regionData.region;
      if(childData and childRegion) then
        if(childRegion.toShow or  WeakAuras.IsAnimating(childRegion) == "finish") then
          activeRegions[#activeRegions] = regionData
        end
      end
    end
    local newPositions = {}
    region.growFunc(newPositions, activeRegions)
    region.numVisible = 0
    for index, activeRegion in ipairs(activeRegions) do
      local pos = newPositions[index] or {0, 0, true}
      pos[1] = type(pos[1]) == "number" and pos[1] or 0
      pos[2] = type(pos[2]) == "number" and pos[2] or 0
      local tray = region.trays[activeRegion.key]
      tray:ClearAllPoints()
      tray:SetPoint(selfPoint, region, selfPoint, pos[1], pos[2])
      tray:SetShown(not pos[3])
      activeRegion.hidden = pos[3]
      self.numVisible = self.numVisible + (pos[3] and 0 or 1)
    end

    region:DoResize();
  end

  function region:Suspend()
    self.suspended = self.suspended + 1;
  end

  function region:Resume()
    self.suspended = self.suspended - 1;
    if (self.suspended < 0) then
      self.suspended = 0; -- Should never happen
    end
    if (self.suspended == 0 and self.needToControlChildren) then
      self:ControlChildren();
      self.needToControlChildren = false;
    end
  end

  function region:ControlChildren()
    if self.suspended > 0 then
      self.needToControlChildren = true;
      return;
    end

    if(data.animate) then
      WeakAuras.pending_controls[data.id] = region;
    else
      region:DoControlChildren();
    end
  end

  function region:DoControlChildren()
    WeakAuras.StartProfileSystem("dynamicgroup");
    WeakAuras.StartProfileAura(region.id);
    local previous = {};
    for index, regionData in pairs(region.controlledRegions) do
      local previousX, previousY = region.trays[regionData.key]:GetCenter();
      previousX = previousX or 0;
      previousY = previousY or 0;
      previous[regionData.key] = {x = previousX, y = previousY};
    end

    region:PositionChildren();

    local previousPreviousX, previousPreviousY;
    for index, regionData in pairs(region.controlledRegions) do
      local childId = regionData.id;
      local childData = regionData.data;
      local childRegion = regionData.region;
      if(childData and childRegion) then
        if (childRegion.toShow or WeakAuras.IsAnimating(childRegion) == "finish") then
          childRegion:Show();
        end
        local xOffset, yOffset = region.trays[regionData.key]:GetCenter();
        xOffset = xOffset or 0;
        yOffset = yOffset or 0;
        local previousX, previousY = previous[regionData.key] and previous[regionData.key].x or previousPreviousX or 0, previous[regionData.key] and previous[regionData.key].y or previousPreviousY or 0;
        local xDelta, yDelta = previousX - xOffset, previousY - yOffset;
        previousPreviousX, previousPreviousY = previousX, previousY;
        if((childRegion.toShow or  WeakAuras.IsAnimating(childRegion) == "finish") and data.animate and not(abs(xDelta) < 0.1 and abs(yDelta) == 0.1)) then
          local anim;
          if(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
            local originX, originY = region:GetCenter();
            local radius1, previousAngle = WeakAuras.GetPolarCoordinates(previousX, previousY, originX, originY);
            local radius2, newAngle = WeakAuras.GetPolarCoordinates(xOffset, yOffset, originX, originY);
            local dAngle = newAngle - previousAngle;
            dAngle = (
              (dAngle > 180 and dAngle - 360)
              or (dAngle < -180 and dAngle + 360)
              or dAngle
              );
            if(math.abs(radius1 - radius2) > 0.1) then
              local translateFunc = [[
                                function(progress, _, _, previousAngle, dAngle)
                                    local previousRadius, dRadius = %f, %f;
                                    local radius = previousRadius + (1 - progress) * dRadius;
                                    local angle = previousAngle + (1 - progress) * dAngle;
                                    return cos(angle) * radius, sin(angle) * radius;
                                end
                            ]]
              anim = {
                type = "custom",
                duration = 0.2,
                use_translate = true,
                translateType = "custom",
                translateFunc = translateFunc:format(radius1, radius2 - radius1),
                x = previousAngle,
                y = dAngle
              };
            else
              local translateFunc = [[
                                function(progress, _, _, previousAngle, dAngle)
                                    local radius = %f;
                                    local angle = previousAngle + (1 - progress) * dAngle;
                                    return cos(angle) * radius, sin(angle) * radius;
                                end
                            ]]
              anim = {
                type = "custom",
                duration = 0.2,
                use_translate = true,
                translateType = "custom",
                translateFunc = translateFunc:format(radius1),
                x = previousAngle,
                y = dAngle
              };
            end
          end
          if not(anim) then
            anim = {
              type = "custom",
              duration = 0.2,
              use_translate = true,
              x = xDelta,
              y = yDelta
            };
          end

          WeakAuras.CancelAnimation(region.trays[regionData.key], nil, nil, nil, nil, nil, true);
          WeakAuras.Animate("tray"..regionData.key, data, "tray", anim, region.trays[regionData.key], true, function() end);
        elseif (not childRegion.toShow) then
          if(WeakAuras.IsAnimating(childRegion) == "finish") then
          -- childRegion will be hidden by its own animation, so it does not need to be hidden immediately
          else
            childRegion:Hide();
          end
        end
      end
    end

    WeakAuras.StopProfileSystem("dynamicgroup");
    WeakAuras.StopProfileAura(region.id);
  end

  region:PositionActiveRegions();

  function region:Scale(scalex, scaley)
    region:SetWidth((region.currentWidth or 16) * scalex);
    region:SetHeight((region.currentHeight or 16) * scaley);
  end
end

WeakAuras.RegisterRegionType("dynamicgroup", create, modify, default);
