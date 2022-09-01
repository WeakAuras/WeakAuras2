if not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...

local WeakAuras = WeakAuras
local L = WeakAuras.L
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
  local controlPoint = CreateFrame("Frame", nil, self.parent)
  Mixin(controlPoint, controlPointFunctions)

  controlPoint:SetWidth(16)
  controlPoint:SetHeight(16)
  controlPoint:Show()
  controlPoint:SetAnchorPoint(self.parent.selfPoint)
  return controlPoint
end

local function releaseControlPoint(self, controlPoint)
  controlPoint:Hide()
  controlPoint:SetAnchorPoint(self.parent.selfPoint)
  local regionData = controlPoint.regionData
  if regionData then
    if self.parent.anchorPerUnit == "UNITFRAME" then
      Private.dyngroup_unitframe_monitor[regionData] = nil
    end
    controlPoint.regionData = nil
    regionData.controlPoint = nil
  end
end

local function create(parent)
  local region = CreateFrame("Frame", nil, parent)
  region.regionType = "dynamicgroup"
  region:SetSize(16, 16)
  region:SetMovable(true)
  region.sortedChildren = {}
  region.controlledChildren = {}
  region.updatedChildren = {}
  local background = CreateFrame("Frame", nil, region, "BackdropTemplate")
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

local function noop() end

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
    local sortFunc = WeakAuras.LoadFunction("return " .. sortStr) or noop
    return function(a, b)
      Private.ActivateAuraEnvironment(data.id)
      local ok, result = xpcall(sortFunc, Private.GetErrorHandlerId(data.id, L["Custom Sort"]), a, b)
      Private.ActivateAuraEnvironment()
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
        local found
        if unit then
          local frame = WeakAuras.GetUnitNameplate(unit)
          if frame then
            frames[frame] = frames[frame] or {}
            tinsert(frames[frame], regionData)
            found = true
          end
        end
        if not found and WeakAuras.IsOptionsOpen() then
          Private.ensurePRDFrame()
          Private.personalRessourceDisplayFrame:anchorFrame(regionData.region.state.id, "NAMEPLATE")
          frames[Private.personalRessourceDisplayFrame] = frames[Private.personalRessourceDisplayFrame] or {}
          tinsert(frames[Private.personalRessourceDisplayFrame], regionData)
        end
      end
    end
  end,
  ["UNITFRAME"] = function(data)
    return function(frames, activeRegions)
      for _, regionData in ipairs(activeRegions) do
        local unit = regionData.region.state and regionData.region.state.unit
        if unit then
          local frame = WeakAuras.GetUnitFrame(unit) or WeakAuras.HiddenFrames
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
    local anchorFunc = WeakAuras.LoadFunction("return " .. anchorStr) or noop
    return function(frames, activeRegions)
      Private.ActivateAuraEnvironment(data.id)
      xpcall(anchorFunc, Private.GetErrorHandlerUid(data.uid, L["Custom Anchor"]), frames, activeRegions)
      Private.ActivateAuraEnvironment()
    end
  end
}

local function createAnchorPerUnitFunc(data)
  local anchorer = anchorers[data.anchorPerUnit] or anchorers.NAMEPLATE
  return anchorer(data)
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
            x = x - regionData.dimensions.width - space
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
            x = x + (regionData.dimensions.width) + space
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
            y = y + (regionData.dimensions.height) + space
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
            y = y - (regionData.dimensions.height) - space
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
          totalWidth = totalWidth + (regionData.dimensions.width)
        end
        local x, y = midX - totalWidth/2, midY - (stagger * (numVisible - 1)/2)
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            x = x + (regionData.dimensions.width) / 2
            newPositions[frame][regionData] = { x, y, true }
            x = x + (regionData.dimensions.width) / 2 + space
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
          totalHeight = totalHeight + (regionData.dimensions.height)
        end
        local x, y = midX - (stagger * (numVisible - 1)/2), midY - totalHeight/2
        newPositions[frame] = {}
        for i, regionData in ipairs(regionDatas) do
          if i <= numVisible then
            y = y + (regionData.dimensions.height) / 2
            newPositions[frame][regionData] = { x, y, true }
            x = x + stagger
            y = y + (regionData.dimensions.height) / 2 + space
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
    local arc = (data.fullCircle and 360 or data.arcLength or 0) * math.pi / 180
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
        local dAngle
        if numVisible == 1 then
          dAngle = 0
        elseif not data.fullCircle then
          dAngle = arc / (numVisible - 1)
        else
          dAngle = arc / numVisible
        end
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
    local arc = (data.fullCircle and 360 or data.arcLength or 0) * math.pi / 180
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
        local dAngle
        if numVisible == 1 then
          dAngle = 0
        elseif not data.fullCircle then
          dAngle = arc / (1 - numVisible)
        else
          dAngle = arc / -numVisible
        end
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
    local growFunc = WeakAuras.LoadFunction("return " .. growStr) or noop
    return function(newPositions, activeRegions)
      Private.ActivateAuraEnvironment(data.id)
      local ok = xpcall(growFunc, Private.GetErrorHandlerId(data.id, L["Custom Grow"]), newPositions, activeRegions)
      Private.ActivateAuraEnvironment()
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
  Private.FixGroupChildrenOrderForGroup(data)
  region:SetScale(data.scale and data.scale > 0 and data.scale <= 10 and data.scale or 1)
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
    -- Stops group from repositioning and re-indexing children
    -- Calls to Activate, Deactivate, and Re-index will cache the relevant children
    -- Similarly, Sort, Position, and Resize will be stopped
    -- to be called on the next Resume
    -- for when the group is resumed
    self.suspended = self.suspended + 1
  end

  function region:Resume()
    -- Allows group to re-index and reposition.
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
    Private.ApplyFrameLevel(childRegion)
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
      Private.StartProfileSystem("dynamicgroup")
      Private.StartProfileAura(data.id)
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
      Private.StopProfileSystem("dynamicgroup")
      Private.StopProfileAura(data.id)
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
      Private.StartProfileSystem("dynamicgroup")
      Private.StartProfileAura(data.id)
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
      Private.StopProfileSystem("dynamicgroup")
      Private.StopProfileAura(data.id)
      self:PositionChildren()
    else
      self.needToSort = true
    end
  end

  region.growFunc = createGrowFunc(data)
  region.anchorPerUnit = data.useAnchorPerUnit and data.anchorPerUnit

  local animate = data.animate
  function region:PositionChildren()
    -- Repositions active children according to their index
    -- Positioning is based on grow information from the data
    if not self:IsSuspended() then
      self.needToPosition = false
      if #self.sortedChildren > 0 then
        if animate then
          Private.RegisterGroupForPositioning(data.uid, self)
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

  function region:DoPositionChildrenPerFrame(frame, positions, handledRegionData)
    for regionData, pos in pairs(positions) do
      if type(regionData) ~= "table" then
        break;
      end
      handledRegionData[regionData] = true
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
      controlPoint:SetShown(show and frame ~= WeakAuras.HiddenFrames)
      controlPoint:SetWidth(regionData.dimensions.width)
      controlPoint:SetHeight(regionData.dimensions.height)
      if data.anchorFrameParent then
        controlPoint:SetParent(frame == "" and self.relativeTo or frame)
      else
        controlPoint:SetParent(self)
      end
      if self.anchorPerUnit == "UNITFRAME" then
        Private.dyngroup_unitframe_monitor[regionData] = frame
      end
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
      regionData.xOffset = x
      regionData.yOffset = y
      regionData.shown = show
    end
  end

  function region:DoPositionChildren()
    Private.StartProfileSystem("dynamicgroup")
    Private.StartProfileAura(data.id)

    local handledRegionData = {}

    local newPositions = {}
    self.growFunc(newPositions, self.sortedChildren)
    if #newPositions > 0 then
      for index = 1, #newPositions do
        if type(newPositions[index]) == "table" then
          local data = self.sortedChildren[index]
          if data then
            newPositions[data] = newPositions[index]
          else
            geterrorhandler()(("Error in '%s', Grow function return position for an invalid region"):format(region.id))
          end
          newPositions[index] = nil
        end
      end
      region:DoPositionChildrenPerFrame("", newPositions, handledRegionData)
    else
      for frame, positions in pairs(newPositions) do
        region:DoPositionChildrenPerFrame(frame, positions, handledRegionData)
      end
    end

    for index, child in ipairs(self.sortedChildren) do
      if not handledRegionData[child] then
        child.controlPoint:SetShown(false)
      end
    end

    Private.StopProfileSystem("dynamicgroup")
    Private.StopProfileAura(data.id)
    self:Resize()
  end


  function region:Resize()
    -- Resizes the dynamic group, for background and border purposes
    if not self:IsSuspended() then
      self.needToResize = false
      -- if self.dynamicAnchor then self:UpdateBorder(); return end
      Private.StartProfileSystem("dynamicgroup")
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
      Private.StopProfileSystem("dynamicgroup")
      Private.StopProfileAura(data.id)
    else
      self.needToResize = true
    end
  end

  region:ReloadControlledChildren()

  WeakAuras.regionPrototype.modifyFinish(parent, region, data)
end

WeakAuras.RegisterRegionType("dynamicgroup", create, modify, default)
