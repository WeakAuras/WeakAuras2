if not WeakAuras.IsCorrectVersion() then return end

local WeakAuras = WeakAuras
local SharedMedia = LibStub("LibSharedMedia-3.0")

local default = {
  controlledChildren = {},
  border = false,
  borderColor = {0, 0, 0, 1},
  backdropColor = {1, 1, 1, 0.5},
  borderEdge = "Square Full White",
  borderOffset = 4,
  borderInset = 1,
  borderSize = 2,
  borderBackdrop = "Blizzard Tooltip",
  grow = "DOWN",
  selfPoint = "TOP",
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
  arcLength = 360,
  constantFactor = "RADIUS",
  frameStrata = 1,
  scale = 1,
  useLimit = false,
  limit = 5,
  gridType = "RD",
  gridWidth = 5,
  rowSpace = 1,
  columnSpace = 1
}

local controlPointFunctions = {
  ["SetAnchorPoint"] = function(self, point, relativeFrame, relativePoint, offsetX, offsetY)
    self.point, self.relativeFrame, self.relativePoint, self.offsetX, self.offsetY = point, relativeFrame, relativePoint, offsetX, offsetY
    self.totalOffsetX = (self.animOffsetX or 0) + (self.offsetX or 0)
    self.totalOffsetY = (self.animOffsetY or 0) + (self.offsetY or 0)
    if self.relativeFrame and self.relativePoint then
      self:SetPoint(self.point, self.relativeFrame, self.relativePoint, self.totalOffsetX, self.totalOffsetY)
    else
      self:SetPoint(self.point, self.totalOffsetX, self.totalOffsetY)
    end
  end,
  ["ClearAnchorPoint"] = function(self)
    self.point, self.relativeFrame, self.relativePoint, self.offsetX, self.offsetY = nil, nil, nil, nil, nil
    self:ClearAllPoints();
  end,
  ["SetOffsetAnim"] = function(self, x, y)
    self.animOffsetX, self.animOffsetY = x, y
    self.totalOffsetX = (self.animOffsetX or 0) + (self.offsetX or 0)
    self.totalOffsetY = (self.animOffsetY or 0) + (self.offsetY or 0)
    if not self.point then
      -- Nothing to do
    elseif self.relativeFrame and self.relativePoint then
      self:SetPoint(self.point, self.relativeFrame, self.relativePoint, self.totalOffsetX, self.totalOffsetY)
    else
      self:SetPoint(self.point, self.totalOffsetX, self.totalOffsetY)
    end
  end
}

local function createControlPoint(self)
  local controlPoint = CreateFrame("FRAME", nil, self.parent)
  Mixin(controlPoint, controlPointFunctions)

  controlPoint:SetWidth(16)
  controlPoint:SetHeight(16)
  controlPoint:Show()
  controlPoint:SetAnchorPoint(self.parent.selfPoint)
  return controlPoint
end

local function releaseControlPoint(self, controlPoint)
  controlPoint:Hide()
  controlPoint:ClearAnchorPoint()
  local regionData = controlPoint.regionData
  if regionData then
    controlPoint.regionData = nil
    regionData.controlPoint = nil
  end
end

local function create(parent)
  local region = CreateFrame("FRAME", nil, parent)
  region:SetSize(16, 16)
  region:SetMovable(true)
  region.sortedChildren = {}
  region.controlledChildren = {}
  region.updatedChildren = {}
  local background = CreateFrame("frame", nil, region)
  region.background = background
  region.selfPoint = "TOPLEFT"
  region.controlPoints = CreateObjectPool(createControlPoint, releaseControlPoint)
  region.controlPoints.parent = region
  WeakAuras.regionPrototype.create(region)
  region.suspended = 0
  return region
end

function WeakAuras.GetPolarCoordinates(x, y, originX, originY)
  local dX, dY = x - originX, y - originY;

  local r = math.sqrt(dX * dX + dY * dY);
  local theta = atan2(dY, dX);

  return r, theta;
end

local function expirationTime(regionData)
  if (regionData.region and regionData.region.state) then
    local expires = regionData.region.state.expirationTime
    if (expires and expires > 0 and expires > GetTime()) then
      return expires
    end
  end
  return nil
end
WeakAuras.ExpirationTime = expirationTime

local function compareExpirationTimes(regionDataA, regionDataB)
  local aExpires = expirationTime(regionDataA)
  local bExpires = expirationTime(regionDataB)

  if (aExpires and bExpires) then
    if abs(aExpires - bExpires) < 0.001 then
      return nil
    end
    return aExpires < bExpires
  elseif (aExpires) then
    return false
  elseif (bExpires) then
    return true
  else
    return nil
  end

end
WeakAuras.CompareExpirationTimes = compareExpirationTimes

local function noop() end

local sorters = {
  none = function(data)
    return function(a, b)
      if a.dataIndex == b.dataIndex then
        local aIndex = a.region.state and a.region.state.index
        local bIndex = b.region.state and b.region.state.index
        if bIndex and aIndex then
          if type(aIndex) ~= type(bIndex) then
            -- state.index can be any value from custom code,
            -- so guard against disparate types which can't be compared
            return type(aIndex) < type(bIndex)
          elseif aIndex == bIndex then
            return nil
          else
            return aIndex < bIndex
          end
        elseif aIndex then
          return false
        elseif bIndex then
          return true
        else
          return nil
        end
      else
        return a.dataIndex < b.dataIndex
      end
    end
  end,
  hybrid = function(data)
    local sortHybridTable = data.sortHybridTable or {}
    local hybridSortAscending = data.hybridSortMode == "ascending"
    local hybridFirst = data.hybridPosition == "hybridFirst"
    return function(a, b)
      if not b then return true end
      if not a then return false end

      local aIsHybrid = sortHybridTable[a.id]
      local bIsHybrid = sortHybridTable[b.id]

      if aIsHybrid and not bIsHybrid then
        return hybridFirst
      elseif bIsHybrid and not aIsHybrid then
        return not hybridFirst
      else
        local aLTb = compareExpirationTimes(a, b)
        if aLTb == nil then
          if a.dataIndex == b.dataIndex then
            return nil
          else
            return a.dataIndex < b.dataIndex
          end
        else
          return aLTb == hybridSortAscending
        end
      end
    end
  end,
  ascending = function(data)
    return function(a, b)
      local result = compareExpirationTimes(a, b)
      if result == nil then
        if a.dataIndex == b.dataIndex then
          return nil
        else
          return a.dataIndex < b.dataIndex
        end
      end
      return result
    end
  end,
  descending = function(data)
    return function(a, b)
      local result = compareExpirationTimes(a, b)
      if result == nil then
        if a.dataIndex == b.dataIndex then
          return nil
        else
          return a.dataIndex < b.dataIndex
        end
      end
      return not result
    end
  end,
  custom = function(data)
    local sortStr = data.customSort or ""
    local sortFunc = WeakAuras.LoadFunction("return " .. sortStr, data.id, "custom sort") or noop
    return function(a, b)
      WeakAuras.ActivateAuraEnvironment(data.id)
      local ok, result = xpcall(sortFunc, geterrorhandler(), a, b)
      WeakAuras.ActivateAuraEnvironment()
      if ok then
        return result
      end
    end
  end
}
WeakAuras.SortFunctions = sorters

local function createSortFunc(data)
  local sorter = sorters[data.sort] or sorters.none
  return sorter(data)
end

local function polarToRect(r, theta)
  return r * math.cos(theta), r * math.sin(theta)
end

local function staggerCoefficient(alignment, stagger)
  if alignment == "LEFT" then
    if stagger < 0 then
      return 1
    else
      return 0
    end
  elseif alignment == "RIGHT" then
    if stagger > 0 then
      return 1
    else
      return 0
    end
  else
    return 0.5
  end
end

local anchorers = {
  ["NAMEPLATE"] = function(data)
    return function(frames, activeRegions)
      for _, regionData in ipairs(activeRegions) do
        local unit = regionData.region.state and regionData.region.state.unit
        if unit then
          local frame = C_NamePlate.GetNamePlateForUnit(unit)
          if frame then
            frames[frame] = frames[frame] or {}
            tinsert(frames[frame], regionData)
          end
        end
      end
    end
  end,
  ["UNITFRAME"] = function(data)
    return function(frames, activeRegions)
      for _, regionData in ipairs(activeRegions) do
        local unit = regionData.region.state and regionData.region.state.unit
        if unit then
          local frame = WeakAuras.GetUnitFrame(unit)
          if frame then
            frames[frame] = frames[frame] or {}
            tinsert(frames[frame], regionData)
          end
        end
      end
    end
  end,
  ["CUSTOM"] = function(data)
    local anchorStr = data.customAnchorPerUnit or ""
    local anchorFunc = WeakAuras.LoadFunction("return " .. anchorStr, data.id, "custom frame anchor") or noop
    return function(frames, activeRegions)
      WeakAuras.ActivateAuraEnvironment(data.id)
      xpcall(anchorFunc, geterrorhandler(), frames, activeRegions)
      WeakAuras.ActivateAuraEnvironment()
    end
  end
}

local function createAnchorPerUnitFunc(data)
  local anchorer = anchorers[data.anchorPerUnit] or anchorers.NAMEPLATE
  return anchorer(data)
end

local function getDimension(regionData, dim)
  return regionData.data[dim] or regionData.region[dim]
end

local growers = {
  LEFT = function(data)
    local stagger = -(data.stagger or 0)
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    local coeff = staggerCoefficient(data.align, data.stagger)
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
        local x, y = startX, startY + (numVisible - 1) * stagger * coeff
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            newPositions[frame][regionData] = { x, y, true }
            x = x - (regionData.data.width or regionData.region.width) - space
            y = y - stagger
          end
        end
      end
    end
  end,
  RIGHT = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    local coeff = 1 - staggerCoefficient(data.align, stagger)
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
        local x, y = startX, startY - (numVisible - 1) * stagger * coeff
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            newPositions[frame][regionData] = { x, y, true }
            x = x + (regionData.data.width or regionData.region.width) + space
            y = y + stagger
          end
        end
      end
    end
  end,
  UP = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    local coeff = 1 - staggerCoefficient(data.align, stagger)
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
        local x, y = startX - (numVisible - 1) * stagger * coeff, startY
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            newPositions[frame][regionData] = { x, y, true }
            x = x + stagger
            y = y + (regionData.data.height or regionData.region.height) + space
          end
        end
      end
    end
  end,
  DOWN = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    local coeff = staggerCoefficient(data.align, stagger)
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
        local x, y = startX - (numVisible - 1) * stagger * coeff, startY
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            newPositions[frame][regionData] = { x, y, true }
            x = x + stagger
            y = y - (regionData.data.height or regionData.region.height) - space
          end
        end
      end
    end
  end,
  HORIZONTAL = function(data)
    local stagger = data.stagger or 0
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local midX, midY = 0, 0
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
        local totalWidth = (numVisible - 1) * space
        for i = 1, numVisible do
          local regionData = regionDatas[i]
          totalWidth = totalWidth + (regionData.data.width or regionData.region.width)
        end
        local x, y = midX - totalWidth/2, midY - (stagger * (numVisible - 1)/2)
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            x = x + (regionData.data.width or regionData.region.width) / 2
            newPositions[frame][regionData] = { x, y, true }
            x = x + (regionData.data.width or regionData.region.width) / 2 + space
            y = y + stagger
          end
        end
      end
    end
  end,
  VERTICAL = function(data)
    local stagger = -(data.stagger or 0)
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local midX, midY = 0, 0
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
        local totalHeight = (numVisible - 1) * space
        for i = 1, numVisible do
          local regionData = regionDatas[i]
          totalHeight = totalHeight + (regionData.data.height or regionData.region.height)
        end
        local x, y = midX - (stagger * (numVisible - 1)/2), midY - totalHeight/2
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            y = y + (regionData.data.height or regionData.region.height) / 2
            newPositions[frame][regionData] = { x, y, true }
            x = x + stagger
            y = y + (regionData.data.height or regionData.region.height) / 2 + space
          end
        end
      end
    end
  end,
  CIRCLE = function(data)
    local oX, oY = 0, 0
    local constantFactor = data.constantFactor
    local space = data.space or 0
    local radius = data.radius or 0
    local limit = data.useLimit and data.limit or math.huge
    local sAngle = (data.rotation or 0) * math.pi / 180
    local arc = (data.arcLength or 0) * math.pi / 180
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
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
        local theta = sAngle
        local dAngle = arc / numVisible
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            local x, y = polarToRect(r, theta)
            newPositions[frame][regionData] = { x, y, true }
            theta = theta + dAngle
          end
        end
      end
    end
  end,
  COUNTERCIRCLE = function(data)
    local oX, oY = 0, 0
    local constantFactor = data.constantFactor
    local space = data.space or 0
    local radius = data.radius or 0
    local limit = data.useLimit and data.limit or math.huge
    local sAngle = (data.rotation or 0) * math.pi / 180
    local arc = (data.arcLength or 0) * math.pi / 180
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
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
        local theta = sAngle
        local dAngle = arc / -numVisible
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            local x, y = polarToRect(r, theta)
            newPositions[frame][regionData] = { x, y, true }
            theta = theta + dAngle
          end
        end
      end
    end
  end,
  GRID = function(data)
    local gridType = data.gridType
    local gridWidth = data.gridWidth
    local rowSpace = data.rowSpace
    local colSpace = data.columnSpace
    local rowFirst = (gridType:find("^[RL]")) ~= nil
    local limit = data.useLimit and data.limit or math.huge
    local rowMul, colMul
    if gridType:find("D") then
      rowMul = -1
    else
      rowMul = 1
    end
    if gridType:find("L") then
      colMul = -1
    else
      colMul = 1
    end
    local primary = {
      -- x direction
      dim = "width",
      coord = 1,
      mul = colMul,
      space = colSpace,
      current = 0
    }
    local secondary = {
      -- y direction
      dim = "height",
      coord = 2,
      mul = rowMul,
      space = rowSpace,
      current = 0
    }
    if not rowFirst then
      primary, secondary = secondary, primary
    end
    local anchorPerUnitFunc = data.useAnchorPerUnit and createAnchorPerUnitFunc(data)
    return function(newPositions, activeRegions)
      local frames = {}
      if anchorPerUnitFunc then
        anchorPerUnitFunc(frames, activeRegions)
      else
        frames[""] = activeRegions
      end
      for frame, regionDatas in pairs(frames) do
        local numVisible = min(limit, #regionDatas)
        primary.current = 0
        secondary.current = 0
        secondary.max = 0
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            newPositions[frame][regionData] = { [primary.coord] = primary.current, [secondary.coord] = secondary.current, [3] = true }
            secondary.max = max(secondary.max, getDimension(regionData, secondary.dim))
            if i % gridWidth == 0 then
              primary.current = 0
              secondary.current = secondary.current + (secondary.space + secondary.max) * secondary.mul
              secondary.max = 0
            else
              primary.current = primary.current + (primary.space + getDimension(regionData, primary.dim)) * primary.mul
            end
          end
        end
      end
    end
  end,
  CUSTOM = function(data)
    local growStr = data.customGrow or ""
    local growFunc = WeakAuras.LoadFunction("return " .. growStr, data.id, "custom grow") or noop
    return function(newPositions, activeRegions)
      WeakAuras.ActivateAuraEnvironment(data.id)
      local ok = xpcall(growFunc, geterrorhandler(), newPositions, activeRegions)
      WeakAuras.ActivateAuraEnvironment()
      if not ok then
        wipe(newPositions)
      end
    end
  end
}
WeakAuras.GrowFunctions = growers

local function createGrowFunc(data)
  local grower = growers[data.grow] or growers.DOWN
  return grower(data)
end

local nullErrorHandler = function()
end

local function SafeGetPos(region, func)
  local ok, value1, value2 = xpcall(func, nullErrorHandler, region)
  if ok then
    return value1, value2
  end
end

local function modify(parent, region, data)
  WeakAuras.FixGroupChildrenOrderForGroup(data)
  -- Scale
  region:SetScale(data.scale and data.scale > 0 and data.scale or 1)
  WeakAuras.regionPrototype.modify(parent, region, data)

  if data.border and (data.grow ~= "CUSTOM" and not data.useAnchorPerUnit) then
    local background = region.background
    background:SetBackdrop({
      edgeFile = data.borderEdge ~= "None" and SharedMedia:Fetch("border", data.borderEdge) or "",
      edgeSize = data.borderSize,
      bgFile = data.borderBackdrop ~= "None" and SharedMedia:Fetch("background", data.borderBackdrop) or "",
      insets = {
        left = data.borderInset,
        right = data.borderInset,
        top = data.borderInset,
        bottom  = data.borderInset,
      },
    });
    background:SetBackdropBorderColor(data.borderColor[1], data.borderColor[2], data.borderColor[3], data.borderColor[4]);
    background:SetBackdropColor(data.backdropColor[1], data.backdropColor[2], data.backdropColor[3], data.backdropColor[4]);

    background:ClearAllPoints();
    background:SetPoint("bottomleft", region, "bottomleft", -1 * data.borderOffset, -1 * data.borderOffset)
    background:SetPoint("topright", region, "topright", data.borderOffset, data.borderOffset)
    background:Show();
  else
    region.background:Hide();
  end

  function region:IsSuspended()
    return not WeakAuras.IsLoginFinished() or self.suspended > 0
  end

  function region:Suspend()
    -- Stops group from repositioning and reindexing children
    -- Calls to Activate, Deactivate, and Reindex will cache the relevant children
    -- Similarly, Sort, Position, and Resize will be stopped
    -- to be called on the next Resume
    -- for when the group is resumed
    self.suspended = self.suspended + 1
  end

  function region:Resume()
    -- Allows group to reindex and reposition.
    -- TriggersSortUpdatedChildren and PositionChildren to happen
    if self.suspended > 0 then
      self.suspended = self.suspended - 1
    end
    if not self:IsSuspended() then
      if self.needToReload then
        self:ReloadControlledChildren()
      end
      if self.needToSort then
        self:SortUpdatedChildren()
      end
      if self.needToPosition then
        self:PositionChildren()
      end
      if self.needToResize then
        self:Resize()
      end
    end
  end

  local function createRegionData(childData, childRegion, childID, cloneID, dataIndex)
    cloneID = cloneID or ""
    local controlPoint = region.controlPoints:Acquire()
    controlPoint:SetWidth(childRegion:GetWidth())
    controlPoint:SetHeight(childRegion:GetHeight())
    local regionData = {
      data = childData,
      region = childRegion,
      id = childID,
      cloneId = cloneID,
      dataIndex = dataIndex,
      controlPoint = controlPoint,
    }
    controlPoint.regionData = regionData
    childRegion:SetParent(controlPoint)
    region.controlledChildren[childID] = region.controlledChildren[childID] or {}
    region.controlledChildren[childID][cloneID] = controlPoint
    childRegion:SetAnchor(data.selfPoint, controlPoint, data.selfPoint)
    return regionData
  end

  local function getRegionData(childID, cloneID)
    cloneID = cloneID or ""
    local controlPoint
    controlPoint = region.controlledChildren[childID] and region.controlledChildren[childID][cloneID]
    if not controlPoint then return end
    return controlPoint.regionData
  end

  local function releaseRegionData(regionData)
    if region.controlledChildren[regionData.id] then
      region.controlledChildren[regionData.id][regionData.cloneId] = nil
    end
    region.controlPoints:Release(regionData.controlPoint)
  end

  function region:ReloadControlledChildren()
    -- 'forgets' about regions it controls and starts from scratch. Mostly useful when Add()ing the group
    if not self:IsSuspended() then
      WeakAuras.StartProfileSystem("dynamicgroup")
      WeakAuras.StartProfileAura(data.id)
      self.needToReload = false
      self.sortedChildren = {}
      self.controlledChildren = {}
      self.updatedChildren = {}
      self.controlPoints:ReleaseAll()
      for dataIndex, childID in ipairs(data.controlledChildren) do
        local childRegion, childData = WeakAuras.GetRegion(childID), WeakAuras.GetData(childID)
        if childRegion and childData then
          local regionData = createRegionData(childData, childRegion, childID, nil, dataIndex)
          if childRegion.toShow then
            tinsert(self.sortedChildren, regionData)
            self.updatedChildren[regionData] = true
          end
        end
        if childData and WeakAuras.clones[childID] then
          for cloneID, cloneRegion in pairs(WeakAuras.clones[childID]) do
            local regionData = createRegionData(childData, cloneRegion, childID, cloneID, dataIndex)
            if cloneRegion.toShow then
              tinsert(self.sortedChildren, regionData)
              self.updatedChildren[regionData] = true
            end
          end
        end
      end
      WeakAuras.StopProfileSystem("dynamicgroup")
      WeakAuras.StopProfileAura(data.id)
      self:SortUpdatedChildren()
    else
      self.needToReload = true
    end
  end

  function region:AddChild(childID, cloneID)
    -- adds regionData to the store.
    -- this is useful mostly for when clones are created which we didn't know about last time Reload was called
    cloneID = cloneID or ""
    if self.controlledChildren[childID] and self.controlledChildren[childID][cloneID] then
      return
    end
    local dataIndex = tIndexOf(data.controlledChildren, childID)
    if not dataIndex then return end
    local childData = WeakAuras.GetData(childID)
    local childRegion = WeakAuras.GetRegion(childID, cloneID)
    if not childData or not childRegion then return end
    local regionData = createRegionData(childData, childRegion, childID, cloneID, dataIndex)
    if childRegion.toShow then
      tinsert(self.sortedChildren, regionData)
      self.updatedChildren[regionData] = true
    end
    self:SortUpdatedChildren()
  end

  function region:ActivateChild(childID, cloneID)
    -- Causes the group to start controlling its order and position
    -- Called in the child's Expand() method
    local regionData = getRegionData(childID, cloneID)
    if not regionData then
      return self:AddChild(childID, cloneID)
    end
    if not regionData.region.toShow then return end
    -- it's possible that while paused, we might get Activate, Deactivate, Activate on the same child
    -- so we need to check if this child has been updated since the last Sort
    -- if it has been, then don't insert it again
    if not regionData.active and self.updatedChildren[regionData] == nil then
      tinsert(self.sortedChildren, regionData)
    end
    self.updatedChildren[regionData] = true
    self:SortUpdatedChildren()
  end

  function region:RemoveChild(childID, cloneID)
    -- removes something from the store. Mostly useful when a clone gets released
    -- so that we don't step on our own feet.
    local regionData = getRegionData(childID, cloneID)
    if not regionData then return end
    releaseRegionData(regionData)
    self.updatedChildren[regionData] = false
    self:SortUpdatedChildren()
  end

  function region:DeactivateChild(childID, cloneID)
    -- Causes the group to stop controlling its order and position
    -- Called in the child's Collapse() method
    local regionData = getRegionData(childID, cloneID)
    if regionData and not regionData.region.toShow then
      self.updatedChildren[regionData] = false
    end
    self:SortUpdatedChildren()
  end

  region.sortFunc = createSortFunc(data)

  function region:SortUpdatedChildren()
    -- iterates through cache to insert all updated children in the right spot
    -- Called when the Group is Resume()d
    -- uses sort data to determine the correct spot
    if not self:IsSuspended() then
      WeakAuras.StartProfileSystem("dynamicgroup")
      WeakAuras.StartProfileAura(data.id)
      self.needToSort = false
      local i = 1
      while self.sortedChildren[i] do
        local regionData = self.sortedChildren[i]
        local active = self.updatedChildren[regionData]
        if active ~= nil then
          regionData.active = active
        end
        if active == false then
          -- i now refers to what was i + 1, so don't increment
          tremove(self.sortedChildren, i)
        else
          local j = i
          while j > 1 do
            local otherRegionData = self.sortedChildren[j - 1]
            if not (active or self.updatedChildren[otherRegionData])
            or not self.sortFunc(regionData, otherRegionData) then
              break
            else
              self.sortedChildren[j] = otherRegionData
              j = j - 1
              self.sortedChildren[j] = regionData
            end
          end
          i = i + 1
        end
      end
      self.updatedChildren = {}
      WeakAuras.StopProfileSystem("dynamicgroup")
      WeakAuras.StopProfileAura(data.id)
      self:PositionChildren()
    else
      self.needToSort = true
    end
  end

  region.growFunc = createGrowFunc(data)

  local animate = data.animate
  function region:PositionChildren()
    -- Repositions active children according to their index
    -- Positioning is based on grow information from the data
    if not self:IsSuspended() then
      self.needToPosition = false
      if #self.sortedChildren > 0 then
        if animate then
          WeakAuras.RegisterGroupForPositioning(data.id, self)
        else
          self:DoPositionChildren()
        end
      else
        self:Resize()
      end
    else
      self.needToPosition = true
    end
  end

  function region:DoPositionChildrenPerFrame(frame, positions)
    for regionData, pos in pairs(positions) do
      local x, y, show =  type(pos[1]) == "number" and pos[1] or 0,
                          type(pos[2]) == "number" and pos[2] or 0,
                          type(pos[3]) ~= "boolean" and true or pos[3]

      local controlPoint = regionData.controlPoint
      controlPoint:ClearAnchorPoint()
      controlPoint:SetAnchorPoint(
        data.selfPoint,
        frame == "" and self.relativeTo or frame,
        data.anchorPoint,
        x + data.xOffset, y + data.yOffset
      )
      controlPoint:SetShown(show)
      controlPoint:SetWidth(regionData.data.width or regionData.region.width)
      controlPoint:SetHeight(regionData.data.height or regionData.region.height)
      if animate then
        WeakAuras.CancelAnimation(regionData.controlPoint, true)
        local xPrev = regionData.xOffset or x
        local yPrev = regionData.yOffset or y
        local xDelta = xPrev - x
        local yDelta = yPrev - y
        if show and (abs(xDelta) > 0.01 or abs(yDelta) > 0.01) then
          local anim
          if data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE" then
            local originX, originY = 0,0
            local radius1, previousAngle = WeakAuras.GetPolarCoordinates(xPrev, yPrev, originX, originY)
            local radius2, newAngle = WeakAuras.GetPolarCoordinates(x, y, originX, originY)
            local dAngle = newAngle - previousAngle
            dAngle = ((dAngle > 180 and dAngle - 360) or (dAngle < -180 and dAngle + 360) or dAngle)
            if(math.abs(radius1 - radius2) > 0.1) then
              local translateFunc = [[
                                function(progress, _, _, previousAngle, dAngle)
                                    local previousRadius, dRadius = %f, %f;
                                    local targetX, targetY = %f, %f
                                    local radius = previousRadius + (1 - progress) * dRadius;
                                    local angle = previousAngle + (1 - progress) * dAngle;
                                    return cos(angle) * radius - targetX, sin(angle) * radius - targetY;
                                end
                            ]]
              anim = {
                type = "custom",
                duration = 0.2,
                use_translate = true,
                translateType = "custom",
                translateFunc = translateFunc:format(radius1, radius2 - radius1, x, y),
                x = previousAngle,
                y = dAngle,
                selfPoint = data.selfPoint,
                anchor = self,
                anchorPoint = data.selfPoint,
              }
            else
              local translateFunc = [[
                                function(progress, _, _, previousAngle, dAngle)
                                    local radius = %f;
                                    local targetX, targetY = %f, %f
                                    local angle = previousAngle + (1 - progress) * dAngle;
                                    return cos(angle) * radius - targetX, sin(angle) * radius - targetY;
                                end
                            ]]
              anim = {
                type = "custom",
                duration = 0.2,
                use_translate = true,
                translateType = "custom",
                translateFunc = translateFunc:format(radius1, x, y),
                x = previousAngle,
                y = dAngle,
                selfPoint = data.selfPoint,
                anchor = self,
                anchorPoint = data.selfPoint,
              }
            end
          end
          if not(anim) then
            anim = {
              type = "custom",
              duration = 0.2,
              use_translate = true,
              x = xDelta,
              y = yDelta,
              selfPoint = data.selfPoint,
              anchor = self,
              anchorPoint = data.selfPoint,
            }
          end
          -- update animated expand & collapse for this child
          WeakAuras.Animate("controlPoint", data, "controlPoint", anim, regionData.controlPoint, true)
        end
      end
      regionData.xOffset = x
      regionData.yOffset = y
      regionData.shown = show
    end
  end

  function region:DoPositionChildren()
    WeakAuras.StartProfileSystem("dynamicgroup")
    WeakAuras.StartProfileAura(data.id)
    local newPositions = {}
    self.growFunc(newPositions, self.sortedChildren)
    if #newPositions > 0 then
      local max = #newPositions
      for index = 1, max do
        if newPositions[index] then
          local data = self.sortedChildren[index]
          if data then
            newPositions[data] = newPositions[index]
          else
            geterrorhandler()(("Error in '%s', Grow function return position for an invalid region"):format(region.id))
          end
          newPositions[index] = nil
        end
      end
      region:DoPositionChildrenPerFrame("", newPositions)
    else
      for frame, positions in pairs(newPositions) do
        region:DoPositionChildrenPerFrame(frame, positions)
      end
    end
    WeakAuras.StopProfileSystem("dynamicgroup")
    WeakAuras.StopProfileAura(data.id)
    self:Resize()
  end


  function region:Resize()
    -- Resizes the dynamic group, for background and border purposes
    if not self:IsSuspended() then
      self.needToResize = false
      -- if self.dynamicAnchor then self:UpdateBorder(); return end
      WeakAuras.StartProfileSystem("dynamicgroup")
      WeakAuras.StartProfileAura(data.id)
      local numVisible, minX, maxX, maxY, minY, minLevel = 0
      for active, regionData in ipairs(self.sortedChildren) do
        if regionData.shown then
          numVisible = numVisible + 1
          local childRegion = regionData.region
          local regionLeft, regionRight, regionTop, regionBottom
             = SafeGetPos(childRegion, childRegion.GetLeft), SafeGetPos(childRegion, childRegion.GetRight),
               SafeGetPos(childRegion, childRegion.GetTop), SafeGetPos(childRegion, childRegion.GetBottom)
          local frameLevel = childRegion:GetFrameLevel()

          if(regionLeft and regionRight and regionTop and regionBottom and frameLevel) then
            minX = minX and min(regionLeft, minX) or regionLeft
            maxX = maxX and max(regionRight, maxX) or regionRight
            minY = minY and min(regionBottom, minY) or regionBottom
            maxY = maxY and max(regionTop, maxY) or regionTop
            minLevel = minLevel and min(frameLevel, minLevel) or frameLevel
          end
        end
      end

      if numVisible > 0 then
        self:Show()
        minX, maxX, minY, maxY = (minX or 0), (maxX or 0), (minY or 0), (maxY or 0)

        local width, height = maxX - minX, maxY - minY
        width = width > 0 and width or 16
        height = height > 0 and height or 16

        self:SetWidth(width)
        self:SetHeight(height)
        self.currentWidth = width
        self.currentHeight = height
        self.background:SetFrameLevel(minLevel and minLevel - 1 or 0)
      else
        self:Hide()
      end
      if WeakAuras.IsOptionsOpen() then
        WeakAuras.OptionsFrame().moversizer:ReAnchor()
      end
      WeakAuras.StopProfileSystem("dynamicgroup")
      WeakAuras.StopProfileAura(data.id)
    else
      self.needToResize = true
    end
  end

  region:ReloadControlledChildren()

  WeakAuras.regionPrototype.modifyFinish(parent, region, data)
end

WeakAuras.RegisterRegionType("dynamicgroup", create, modify, default)
