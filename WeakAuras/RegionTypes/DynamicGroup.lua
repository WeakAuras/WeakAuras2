if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

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
  distribute = "self",
  animate = false,
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  radius = 200,
  rotation = 0,
  fullCircle = true,
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
    self:ClearAllPoints();
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
  end,
  ["ReAnchor"] = function(self, frame)
    self:ClearAllPoints()
    self.relativeFrame = frame
    if self.relativeFrame and self.relativePoint then
      self:SetPoint(self.point, self.relativeFrame, self.relativePoint, self.totalOffsetX, self.totalOffsetY)
    else
      self:SetPoint(self.point, self.totalOffsetX, self.totalOffsetY)
    end
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

  -- 2-dimensional table of children, indexed by id, cloneId
  region.controlledChildren = {}
  -- regionData -> boolean map. Entries in this table will be checked to see if their position needs modifying
  region.updatedChildren = {}
  -- Set of sorted lists. Entries in this set are added by RedistributeChildren when an updated child is assigned to a sortedList,
  -- or when a sortedList loses a child
  -- Repositioning happens only on lists which are flagged as having any updates to their children.
  region.updatedGroups = {}
  -- types of frames to attach a child's control point to
  -- 3-dimensional table, indexed by type, groupId, sort index
  -- DistributeChildren assigns type & groupId, sort assigns sort index
  region.groups = {}
  local background = CreateFrame("frame", nil, region, BackdropTemplateMixin and "BackdropTemplate")
  region.background = background
  region.selfPoint = "TOPLEFT"
  region.controlPoints = CreateObjectPool(createControlPoint, releaseControlPoint)
  region.controlPoints.parent = region
  WeakAuras.regionPrototype.create(region)
  region.suspended = 0

  local oldSetFrameLevel = region.SetFrameLevel
  region.SetFrameLevel = function(self, level)
    oldSetFrameLevel(self, level)
    self.background:SetFrameLevel(level)
  end

  return region
end

local function noop() end

local anchorers = {
  self = function(self, anchorLocation) return self end,
  nameplate = function(self, anchorLocation) return WeakAuras.GetUnitNameplate(anchorLocation) end,
  unit = function(self, anchorLocation) return WeakAuras.GetUnitFrame(anchorLocation) end,
  frame = function(self, anchorLocation) return Private.GetSanitizedGlobal(anchorLocation) end,
  aura = function(self, anchorLocation) return WeakAuras.GetRegion(anchorLocation) end, --? do we actually want this?
}

local distributors = {
  self = function(data)
    return function(regionData) return { type = "self" } end
  end,
  nameplate = function(data)
    return function(regionData)
      return {
        type = "nameplate",
        location = regionData.region.state and regionData.region.state.unit
      }
    end
  end,
  unit = function(data)
    return function(regionData)
      return {
        type = "unit",
        location = regionData.region.state and regionData.region.state.unit
      }
    end
  end,
  custom = function(data)
    local distributeStr = data.customDistribute or ""
    local distributeFunc = WeakAuras.LoadFunction("return " .. distributeStr, data.id, "custom distribute") or noop
    return function(regionData)
      Private.ActivateAuraEnvironment(data.id)
      local ok, result = xpcall(distributeFunc, geterrorhandler(), regionData)
      Private.ActivateAuraEnvironment()
      if ok then
        return result
      end
    end
  end
}

local function createDistributeFunc(data)
  local distributor = distributors[data.distribute] or distributors["self"]
  return distributor(data)
end

function WeakAuras.GetPolarCoordinates(x, y, originX, originY)
  local dX, dY = x - originX, y - originY;

  local r = math.sqrt(dX * dX + dY * dY);
  local theta = atan2(dY, dX);

  return r, theta;
end

function WeakAuras.InvertSort(sortFunc)
  -- takes a comparator and returns the "inverse"
  -- i.e. when sortFunc returns true/false, inverseSortFunc returns false/true
  -- nils are preserved to ensure that inverseSortFunc composes well
  if type(sortFunc) ~= "function" then
    error("InvertSort requires a function to invert.")
  else
    return function(...)
      local result = sortFunc(...)
      if result == nil then return nil end
      return not result
    end
  end
end

function WeakAuras.SortNilLast(a, b)
  -- sorts nil values to the end
  -- only returns nil if both values are non-nil
  -- Useful as a high priority sorter in a composition,
  -- to ensure that children with missing data
  -- don't ever sit in the middle of a row
  -- and interrupt the sorting algorithm
  if a == nil and b == nil then
    -- guarantee stability in the nil region
    return false
  elseif a == nil then
    return false
  elseif b == nil then
    return true
  else
    return nil
  end
end

local sortNilFirst = WeakAuras.InvertSort(WeakAuras.SortNilLast)
function WeakAuras.SortNilFirst(a, b)
  if a == nil and b == nil then
    -- we want SortNil to always prevent nils from propagating
    -- as well as to sort nils onto one side
    -- to maintain stability, we need SortNil(nil, nil) to always be false
    -- hence this special case
    return false
  else
    return sortNilFirst(a,b)
  end
end

function WeakAuras.SortGreaterLast(a, b)
  -- sorts values in ascending order
  -- values of disparate types are sorted according to the value of type(value)
  -- which is a bit weird but at least guarantees a stable sort
  -- can only sort comparable values (i.e. numbers and strings)
  -- no support currently for tables with __lt metamethods
  if a == b then
    return nil
  end
  if type(a) ~= type(b) then
    return type(a) > type(b)
  end
  if type(a) == "number" then
    if abs(b - a) < 0.001 then
      return nil
    else
      return a < b
    end
  elseif type(a) == "string" then
    return a < b
  else
    return nil
  end
end

WeakAuras.SortGreaterFirst = WeakAuras.InvertSort(WeakAuras.SortGreaterLast)

function WeakAuras.SortRegionData(path, sortFunc)
  -- takes an array-like table, and a function that takes 2 values and returns true/false/nil
  -- creates function that accesses the value indicated by path, and compares using sortFunc
  if type(path) ~= "table" then
    path = {}
  end
  if type(sortFunc) ~= "function" then
    -- if sortFunc not provided, compare by default as "<"
    sortFunc = WeakAuras.SortGreaterLast
  end
  return function(a, b)
    local aValue, bValue = a, b
    for _, key in ipairs(path) do
      if type(aValue) ~= "table" then return nil end
      if type(bValue) ~= "table" then return nil end
      aValue, bValue = aValue[key], bValue[key]
    end
    return sortFunc(aValue, bValue)
  end
end

function WeakAuras.SortAscending(path)
  return WeakAuras.SortRegionData(path, WeakAuras.ComposeSorts(WeakAuras.SortNilFirst, WeakAuras.SortGreaterLast))
end

function WeakAuras.SortDescending(path)
  return WeakAuras.InvertSort(WeakAuras.SortAscending(path))
end

function WeakAuras.ComposeSorts(...)
  -- accepts vararg of sort funcs
  -- returns new sort func that combines the functions passed in
  -- order of functions passed in determines their priority in new sort
  -- returns nil if all functions return nil,
  -- so that it can be composed or inverted without trouble
  local sorts = {}
  for i = 1, select("#", ...) do
    local sortFunc = select(i, ...)
    if type(sortFunc) == "function" then
      tinsert(sorts, sortFunc)
    end
  end
  return function(a, b)
    for _, sortFunc in ipairs(sorts) do
      local result = sortFunc(a, b)
      if result ~= nil then
        return result
      end
    end
    return nil
  end
end

local sorters = {
  none = function(data)
    return WeakAuras.ComposeSorts(
      WeakAuras.SortAscending({"dataIndex"}),
      WeakAuras.SortAscending({"region", "state", "index"})
    )
  end,
  hybrid = function(data)
    local sortHybridTable = data.sortHybridTable or {}
    local hybridSortAscending = data.hybridSortMode == "ascending"
    local hybridFirst = data.hybridPosition == "hybridFirst"
    local function sortHybridStatus(a, b)
      if not b then return true end
      if not a then return false end

      local aIsHybrid = sortHybridTable[a.id]
      local bIsHybrid = sortHybridTable[b.id]

      if aIsHybrid and not bIsHybrid then
        return hybridFirst
      elseif bIsHybrid and not aIsHybrid then
        return not hybridFirst
      else
        return nil
      end
    end
    local sortExpirationTime
    if hybridSortAscending then
      sortExpirationTime = WeakAuras.SortAscending({"region", "state", "expirationTime"})
    else
      sortExpirationTime = WeakAuras.SortDescending({"region", "state", "expirationTime"})
    end
    return WeakAuras.ComposeSorts(
      sortHybridStatus,
      sortExpirationTime,
      WeakAuras.SortAscending({"dataIndex"})
    )
  end,
  ascending = function(data)
    return WeakAuras.ComposeSorts(
      WeakAuras.SortAscending({"region", "state", "expirationTime"}),
      WeakAuras.SortAscending({"dataIndex"})
    )
  end,
  descending = function(data)
    return WeakAuras.ComposeSorts(
      WeakAuras.SortDescending({"region", "state", "expirationTime"}),
      WeakAuras.SortAscending({"dataIndex"})
    )
  end,
  custom = function(data)
    local sortStr = data.customSort or ""
    local sortFunc = WeakAuras.LoadFunction("return " .. sortStr, data.id, "custom sort") or noop
    return function(a, b)
      Private.ActivateAuraEnvironment(data.id)
      local ok, result = xpcall(sortFunc, geterrorhandler(), a, b)
      Private.ActivateAuraEnvironment()
      if ok then
        return result
      end
    end
  end
}

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

local function getDimension(regionData, dim)
  return regionData.dimensions[dim]
end

local growers = {
  LEFT = function(data)
    local stagger = -(data.stagger or 0)
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local startX, startY = 0, 0
    local coeff = staggerCoefficient(data.align, data.stagger)
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX, startY + (numVisible - 1) * stagger * coeff
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          newPositions[i] = { x = x, y = y, show = true }
          x = x - regionData.dimensions.width - space
          y = y - stagger
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
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX, startY - (numVisible - 1) * stagger * coeff
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          newPositions[i] = { x = x, y = y, show = true }
          x = x + (regionData.dimensions.width) + space
          y = y + stagger
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
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX - (numVisible - 1) * stagger * coeff, startY
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          newPositions[i] = { x = x, y = y, show = true }
          x = x + stagger
          y = y + (regionData.dimensions.height) + space
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
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local x, y = startX - (numVisible - 1) * stagger * coeff, startY
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          newPositions[i] = { x = x, y = y, show = true }
          x = x + stagger
          y = y - (regionData.dimensions.height) - space
        end
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
      local totalWidth = (numVisible - 1) * space
      for i = 1, numVisible do
        local regionData = activeRegions[i]
        totalWidth = totalWidth + (regionData.dimensions.width)
      end
      local x, y = midX - totalWidth/2, midY - (stagger * (numVisible - 1)/2)
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          x = x + (regionData.dimensions.width) / 2
          newPositions[i] = { x = x, y = y, show = true }
          x = x + (regionData.dimensions.width) / 2 + space
          y = y + stagger
        end
      end
    end
  end,
  VERTICAL = function(data)
    local stagger = -(data.stagger or 0)
    local space = data.space or 0
    local limit = data.useLimit and data.limit or math.huge
    local midX, midY = 0, 0
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      local totalHeight = (numVisible - 1) * space
      for i = 1, numVisible do
        local regionData = activeRegions[i]
        totalHeight = totalHeight + (regionData.dimensions.height)
      end
      local x, y = midX - (stagger * (numVisible - 1)/2), midY - totalHeight/2
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          y = y + (regionData.dimensions.height) / 2
          newPositions[i] = { x = x, y = y, show = true }
          x = x + stagger
          y = y + (regionData.dimensions.height) / 2 + space
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
    local arc = (data.fullCircle and 360 or data.arcLength or 0) * math.pi / 180
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
      local theta = sAngle
      local dAngle
      if numVisible == 1 then
        dAngle = 0
      elseif not data.fullCircle then
        dAngle = arc / (numVisible - 1)
      else
        dAngle = arc / numVisible
      end
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          local x, y = polarToRect(r, theta)
          newPositions[i] = { x = x, y = y, show = true }
          theta = theta + dAngle
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
    local arc = (data.fullCircle and 360 or data.arcLength or 0) * math.pi / 180
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
      local theta = sAngle
      local dAngle
      if numVisible == 1 then
        dAngle = 0
      elseif not data.fullCircle then
        dAngle = arc / (numVisible - 1)
      else
        dAngle = arc / numVisible
      end
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          local x, y = polarToRect(r, theta)
          newPositions[i] = { x = x, y = y, show = true }
          theta = theta - dAngle
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
      coord = "x",
      mul = colMul,
      space = colSpace,
      current = 0
    }
    local secondary = {
      -- y direction
      dim = "height",
      coord = "y",
      mul = rowMul,
      space = rowSpace,
      current = 0
    }
    if not rowFirst then
      primary, secondary = secondary, primary
    end
    return function(newPositions, activeRegions)
      local numVisible = min(limit, #activeRegions)
      primary.current = 0
      secondary.current = 0
      secondary.max = 0
      for i, regionData in ipairs(activeRegions) do
        if i <= numVisible then
          newPositions[i] = { [primary.coord] = primary.current, [secondary.coord] = secondary.current, show = true }
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
  end,
  CUSTOM = function(data)
    local growStr = data.customGrow or ""
    local growFunc = WeakAuras.LoadFunction("return " .. growStr, data.id, "custom grow") or noop
    return function(newPositions, activeRegions)
      Private.ActivateAuraEnvironment(data.id)
      local ok = xpcall(growFunc, geterrorhandler(), newPositions, activeRegions)
      Private.ActivateAuraEnvironment()
      if not ok then
        wipe(newPositions)
      end
    end
  end
}

local function createGrowFunc(data)
  local grower = growers[data.grow] or growers.DOWN
  return grower(data)
end

local function SafeGetPos(region, func)
  local ok, value1, value2 = xpcall(func, noop, region)
  if ok then
    return value1, value2
  end
end

local function resolvePath(tbl, ...)
  for i = 1, select("#", ...) do
    local index = select(i, ...)
    tbl[index] = tbl[index] or {}
    tbl = tbl[index]
  end
  return tbl
end

local function modify(parent, region, data)
  Private.FixGroupChildrenOrderForGroup(data)
  region:SetScale(data.scale and data.scale > 0 and data.scale <= 10 and data.scale or 1)
  WeakAuras.regionPrototype.modify(parent, region, data)

  if data.border then
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
    -- Stops group from repositioning and re-indexing children
    -- Calls to Activate, Deactivate, and Re-index will cache the relevant children
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
      if self.needToDistribute then
        self:RedistributeChildren()
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
      parent = region
    }

    if childData.regionType == "text" then
      regionData.dimensions = childRegion
    else
      regionData.dimensions = childData
    end

    controlPoint.regionData = regionData
    childRegion:SetParent(controlPoint)
    region.controlledChildren[childID] = region.controlledChildren[childID] or {}
    region.controlledChildren[childID][cloneID] = controlPoint
    childRegion:SetAnchor(data.selfPoint, controlPoint, data.selfPoint)
    if(childData.frameStrata == 1) then
      childRegion:SetFrameStrata(region:GetFrameStrata());
    else
      childRegion:SetFrameStrata(Private.frame_strata_types[childData.frameStrata]);
    end
    return regionData
  end

  local function getRegionData(childID, cloneID)
    cloneID = cloneID or ""
    local controlPoint = region.controlledChildren[childID] and region.controlledChildren[childID][cloneID]
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
      Private.StartProfileSystem("dynamicgroup2")
      Private.StartProfileAura(data.id)
      self.needToReload = false
      self.controlledChildren = {}
      self.updatedChildren = {}
      self.groups = {}
      self.updatedGroups = {}
      self.controlPoints:ReleaseAll()
      for dataIndex, childID in ipairs(data.controlledChildren) do
        local childRegion, childData = WeakAuras.GetRegion(childID), WeakAuras.GetData(childID)
        if childRegion and childData then
          local regionData = createRegionData(childData, childRegion, childID, nil, dataIndex)
          if childRegion.toShow then
            self.updatedChildren[regionData] = true
          end
        end
        if childData and WeakAuras.clones[childID] then
          for cloneID, cloneRegion in pairs(WeakAuras.clones[childID]) do
            local regionData = createRegionData(childData, cloneRegion, childID, cloneID, dataIndex)
            if cloneRegion.toShow then
              self.updatedChildren[regionData] = true
            end
          end
        end
      end
      Private.StopProfileSystem("dynamicgroup2")
      Private.StopProfileAura(data.id)
      self:RedistributeChildren()
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
      self.updatedChildren[regionData] = true
    end
    self:RedistributeChildren()
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
    self.updatedChildren[regionData] = true
    self:RedistributeChildren()
  end

  function region:RemoveChild(childID, cloneID)
    -- removes something from the store. Mostly useful when a clone gets released
    -- so that we don't step on our own feet.
    local regionData = getRegionData(childID, cloneID)
    if not regionData then return end
    releaseRegionData(regionData)
    self.updatedChildren[regionData] = false
    self:RedistributeChildren()
  end

  function region:DeactivateChild(childID, cloneID)
    -- Causes the group to stop controlling its order and position
    -- Called in the child's Collapse() method
    local regionData = getRegionData(childID, cloneID)
    if regionData and not regionData.region.toShow then
      self.updatedChildren[regionData] = false
    end
    self:RedistributeChildren()
  end

  local function getOrCreateGroup(anchor)
    local tbl = resolvePath(region.groups, anchor.type, anchor.location, anchor.point)
    if not tbl[anchor.id] then
      tbl[anchor.id] = {
        type = anchor.type,
        location = anchor.location,
        id = anchor.id,
        point = anchor.point,
        children = {}
      }
    end
    return tbl[anchor.id]
  end


  local function validateAnchor(anchor)
    if type(anchor) ~= "table" then
      anchor = {}
    end
    if not anchorers[anchor.type] then
      anchor.type = "self"
    end
    if anchor.type == "self" or type(anchor.location) ~= "string" then
      anchor.location = ""
    end
    if type(anchor.id) ~= "string" then
      anchor.id = ""
    end
    if not Private.point_types[anchor.point] then
      anchor.point = "CENTER"
    end
    return anchor
  end


  region.distributeFunc = createDistributeFunc(data)
  function region:RedistributeChildren()
    -- redistributes updated children to the correct groups
    if not self:IsSuspended() then
      Private.StartProfileSystem("dynamicgroup2")
      Private.StartProfileAura(data.id)
      self.needToDistribute = false
      for regionData, active in pairs(self.updatedChildren) do
        if active then
          -- child wants to be visible, find an appropriate group
          local anchor = validateAnchor(region.distributeFunc(regionData))
          local group = getOrCreateGroup(anchor)
          self.updatedGroups[group] = true
          if regionData.group ~= group then
            -- either this child wasn't previously assigned to a group, or its group has changed
            -- either way, we need to insert it into the new group
            if regionData.group then
              self.updatedGroups[regionData.group] = true
            end
            tinsert(group.children, regionData)
          end
          regionData.group = group
        elseif regionData.group then
          -- child wants to hide, find the group it was in and flag as updated
          self.updatedGroups[regionData.group] = true
          -- set to nil, so that Sort knows to remove the child from group.children
          regionData.group = nil
        end
      end
      Private.StopProfileAura(data.id)
      Private.StopProfileSystem("dynamicgroup2")
      self:SortUpdatedChildren()
    else
      self.needToDistribute = true
    end
  end

  region.sortFunc = createSortFunc(data)

  function region:SortUpdatedChildren()
    -- iterates through cache to insert all updated children in the right spot
    -- Called when the Group is Resume()d
    -- uses sort data to determine the correct spot
    if not self:IsSuspended() then
      Private.StartProfileSystem("dynamicgroup2")
      Private.StartProfileAura(data.id)
      self.needToSort = false
      for group in pairs(self.updatedGroups) do
        local i = 1
        while group.children[i] do
          local regionData = group.children[i]
          local active = self.updatedChildren[regionData]
          if active ~= nil then
            regionData.active = active
          end
          if active == false or regionData.group ~= group then
            -- i now refers to what was i + 1, so don't increment
            tremove(group.children, i)
          else
            local j = i
            while j > 1 do
              local otherRegionData = group.children[j - 1]
              if not (active or group.children[otherRegionData])
              or not self.sortFunc(regionData, otherRegionData) then
                break
              else
                group.children[j] = otherRegionData
                j = j - 1
                group.children[j] = regionData
              end
            end
            i = i + 1
          end
        end
      end
      -- all children are in their correct places now, we can wipe updatedChildren
      self.updatedChildren = {}
      Private.StopProfileSystem("dynamicgroup2")
      Private.StopProfileAura(data.id)
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
      if animate then
        Private.RegisterGroupForPositioning(data.uid, self)
      else
        self:DoPositionChildren()
      end
    else
      self.needToPosition = true
    end
  end

  function region:DoPositionChildren()
    Private.StartProfileSystem("dynamicgroup2")
    Private.StartProfileAura(data.id)
    for group in pairs(self.updatedGroups) do
      local frame = anchorers[group.type](self, group.location)
      local newPositions = {}
      self.growFunc(newPositions, group.children)
      if #newPositions > 0 then
        for index, pos in ipairs(newPositions) do
          local regionData = group.children[index]
          local x, y, relativePoint, show =
              type(pos.x) == "number" and pos.x or 0,
              type(pos.y) == "number" and pos.y or 0,
              Private.point_types[pos.relativePoint] and pos.relativePoint or data.anchorPoint,
              type(pos.show) ~= "boolean" and true or pos.show
          local controlPoint = regionData.controlPoint
          controlPoint:ClearAnchorPoint()
          controlPoint:SetAnchorPoint(
            relativePoint,
            frame,
            group.point,
            x,
            y
          )
          controlPoint:SetShown(show)
          controlPoint:SetWidth(regionData.dimensions.width)
          controlPoint:SetHeight(regionData.dimensions.height)
          if animate then
            Private.CancelAnimation(regionData.controlPoint, true)
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
              Private.Animate("controlPoint", data.uid, "controlPoint", anim, regionData.controlPoint, true)
            end
          end
          regionData.xOffset = xq
          regionData.yOffset = y
          regionData.shown = show
        end
      end
    end

    Private.StopProfileSystem("dynamicgroup2")
    Private.StopProfileAura(data.id)
    self:Resize()
  end

  function region:ApplyUpdates()
  end

  function region:Resize()
    -- Resizes the dynamic group, for background and border purposes
    if not self:IsSuspended() and false then
      -- TODO: fix this - but how? create borders on every subgroup? On just the "default" one?
      self.needToResize = false
      Private.StartProfileSystem("dynamicgroup2")
      Private.StartProfileAura(data.id)
      local numVisible, minX, maxX, maxY, minY = 0
      for active, regionData in ipairs(self.sortedChildren) do
        if regionData.shown then
          numVisible = numVisible + 1
          local childRegion = regionData.region
          local regionLeft, regionRight, regionTop, regionBottom
             = SafeGetPos(childRegion, childRegion.GetLeft), SafeGetPos(childRegion, childRegion.GetRight),
               SafeGetPos(childRegion, childRegion.GetTop), SafeGetPos(childRegion, childRegion.GetBottom)

          if(regionLeft and regionRight and regionTop and regionBottom) then
            minX = minX and min(regionLeft, minX) or regionLeft
            maxX = maxX and max(regionRight, maxX) or regionRight
            minY = minY and min(regionBottom, minY) or regionBottom
            maxY = maxY and max(regionTop, maxY) or regionTop
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
      else
        self:Hide()
      end
      if WeakAuras.IsOptionsOpen() then
        WeakAuras.OptionsFrame().moversizer:ReAnchor()
      end
      Private.StopProfileSystem("dynamicgroup2")
      Private.StopProfileAura(data.id)
    else
      self.needToResize = true
    end
  end

  region:ReloadControlledChildren()

  WeakAuras.regionPrototype.modifyFinish(parent, region, data)
end

WeakAuras.RegisterRegionType("dynamicgroup2", create, modify, default)
