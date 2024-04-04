if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local createCenterLines = true --- Creates only the middle lines
local showNormalLines = false -- Show all alignment lines all the time
local highlightColor = { 1, 1, 0 } -- The color of lines that are we are currently aligned too
local gridHighlightColor = { 0.3, 1, 0.3}
local normalColor = { 0.3, 0.3, 0.6, } -- The color of lines if they aren't matched if showNormalLines is enabled
local gridColor = { 0.3, 0.6, 0.3 } -- The color of grid lines, if they aren't matched and enabled

-- Lua APIs
local pairs = pairs

-- WoW APIs
local IsShiftKeyDown, CreateFrame =  IsShiftKeyDown, CreateFrame

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L

local moversizer
local mover

local MAGNETIC_ALIGNMENT = 10
local function distance(num1, num2)
  return abs(num2 - num1)
end

local function EnsureTexture(self, texture)
  if texture then
    return texture
  else
    local ret = self:CreateTexture()
    ret:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp")
    ret:SetWidth(16)
    ret:SetHeight(16)
    ret:SetTexCoord(0, 0.25, 0, 1)
    ret:SetVertexColor(1, 1, 1, 0.25)
    return ret
  end
end

local function moveOnePxl(direction)
  if mover and mover.moving then
    local data = mover.moving.data
    local physicalWidth, physicalHeight = GetPhysicalScreenSize();
    local oneX = GetScreenWidth() / physicalWidth
    local oneY = GetScreenHeight() / physicalHeight
    if data then
      if direction == "top" then
        data.yOffset = data.yOffset + oneY
      elseif direction == "bottom" then
        data.yOffset = data.yOffset - oneY
      elseif direction == "left" then
        data.xOffset = data.xOffset - oneX
      elseif direction == "right" then
        data.xOffset = data.xOffset + oneX
      end
      WeakAuras.Add(data, true)
      WeakAuras.UpdateThumbnail(data)
      OptionsPrivate.ResetMoverSizer()
      OptionsPrivate.Private.AddParents(data)
      WeakAuras.FillOptions()
    end
  end
end

local function ConstructMover(frame)
  local topAndBottom = CreateFrame("Frame", nil, frame)
  topAndBottom:SetClampedToScreen(true)
  topAndBottom:SetSize(25, 45)
  topAndBottom:SetPoint("LEFT", frame, "RIGHT", 1, 0)
  local top = CreateFrame("Button", nil, topAndBottom)
  top:SetSize(25, 25)
  top:SetPoint("TOP", topAndBottom)
  top:SetFrameStrata("BACKGROUND")
  local bottom = CreateFrame("Button", nil, topAndBottom)
  bottom:SetSize(25, 25)
  bottom:SetPoint("BOTTOM", topAndBottom)
  bottom:SetFrameStrata("BACKGROUND")

  local leftAndRight = CreateFrame("Frame", nil, frame)
  leftAndRight:SetClampedToScreen(true)
  leftAndRight:SetSize(45, 25)
  leftAndRight:SetPoint("TOP", frame, "BOTTOM", 0, 1)
  local left = CreateFrame("Button", nil, leftAndRight)
  left:SetSize(25, 25)
  left:SetPoint("LEFT", leftAndRight)
  left:SetFrameStrata("BACKGROUND")
  local right = CreateFrame("Button", nil, leftAndRight)
  right:SetSize(25, 25)
  right:SetPoint("RIGHT", leftAndRight)
  right:SetFrameStrata("BACKGROUND")

  top:SetNormalTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-up.blp")
  top:SetHighlightTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-highlight.blp")
  top:SetPushedTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-down.blp")
  top:SetScript("OnClick", function() moveOnePxl("top") end)

  bottom:SetNormalTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-up.blp")
  bottom:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
  bottom:SetHighlightTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-highlight.blp")
  bottom:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
  bottom:SetPushedTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-down.blp")
  bottom:GetPushedTexture():SetTexCoord(0, 1, 1, 0)
  bottom:SetScript("OnClick", function() moveOnePxl("bottom") end)

  left:SetNormalTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-up.blp")
  left:GetNormalTexture():SetRotation(math.pi/2)
  left:SetHighlightTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-highlight.blp")
  left:GetHighlightTexture():SetRotation(math.pi/2)
  left:SetPushedTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-down.blp")
  left:GetPushedTexture():SetRotation(math.pi/2)
  left:SetScript("OnClick", function() moveOnePxl("left") end)

  right:SetNormalTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-up.blp")
  right:GetNormalTexture():SetRotation(-math.pi/2)
  right:SetHighlightTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-highlight.blp")
  right:GetHighlightTexture():SetRotation(-math.pi/2)
  right:SetPushedTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-down.blp")
  right:GetPushedTexture():SetRotation(-math.pi/2)
  right:SetScript("OnClick", function() moveOnePxl("right") end)

  local arrow = CreateFrame("Frame", nil, frame)
  arrow:SetClampedToScreen(true)
  arrow:SetSize(196, 196)
  arrow:SetPoint("CENTER", frame, "CENTER")
  arrow:SetFrameStrata("HIGH")
  local arrowTexture = arrow:CreateTexture()
  arrowTexture:SetTexture("Interface\\Addons\\WeakAuras\\Media\\Textures\\offscreen.tga")
  arrowTexture:SetSize(128, 128)
  arrowTexture:SetPoint("CENTER", arrow, "CENTER")
  arrowTexture:SetVertexColor(0.8, 0.8, 0.2)
  arrowTexture:Hide()
  local offscreenText = arrow:CreateFontString(nil, "OVERLAY")
  offscreenText:SetFont(STANDARD_TEXT_FONT, 14, "THICKOUTLINE");
  offscreenText:SetText(L["Aura is\nOff Screen"])
  offscreenText:Hide()
  offscreenText:SetPoint("CENTER", arrow, "CENTER")

  return arrowTexture, offscreenText
end

local function ConstructSizer(frame)
  -- topright, bottomright, bottomleft, topleft

  local topright = CreateFrame("Frame", nil, frame)
  topright:EnableMouse()
  topright:SetWidth(16)
  topright:SetHeight(16)
  topright:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

  local texTR1 = topright:CreateTexture(nil, "OVERLAY")
  texTR1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texTR1:SetBlendMode("ADD")
  texTR1:SetTexCoord(0.5, 0, 0, 0, 0.5, 1, 0, 1)
  texTR1:SetPoint("TOPRIGHT", topright, "TOPRIGHT", -3, -3)
  texTR1:SetPoint("BOTTOMLEFT", topright, "BOTTOM")

  local texTR2 = topright:CreateTexture(nil, "OVERLAY")
  texTR2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texTR2:SetBlendMode("ADD")
  texTR2:SetTexCoord(0, 0, 0, 1, 0.5, 0, 0.5, 1)
  texTR2:SetPoint("TOPRIGHT", texTR1, "TOPLEFT")
  texTR2:SetPoint("BOTTOMLEFT", topright, "LEFT")

  topright.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texTR1:Show()
    texTR2:Show()
  end
  topright.Clear = function()
    texTR1:Hide()
    texTR2:Hide()
  end

  local bottomright = CreateFrame("Frame", nil, frame)
  bottomright:EnableMouse()
  bottomright:SetWidth(16)
  bottomright:SetHeight(16)
  bottomright:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local texBR1 = bottomright:CreateTexture(nil, "OVERLAY")
  texBR1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texBR1:SetBlendMode("ADD")
  texBR1:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1)
  texBR1:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMRIGHT", -3, 3)
  texBR1:SetPoint("TOPLEFT", bottomright, "TOP")

  local texBR2 = bottomright:CreateTexture(nil, "OVERLAY")
  texBR2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texBR2:SetBlendMode("ADD")
  texBR2:SetTexCoord(0, 0, 0, 1, 0.5, 0, 0.5, 1)
  texBR2:SetPoint("BOTTOMRIGHT", texBR1, "BOTTOMLEFT")
  texBR2:SetPoint("TOPLEFT", bottomright, "LEFT")

  bottomright.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texBR1:Show()
    texBR2:Show()
  end
  bottomright.Clear = function()
    texBR1:Hide()
    texBR2:Hide()
  end

  local bottomleft = CreateFrame("Frame", nil, frame)
  bottomleft:EnableMouse()
  bottomleft:SetSize(16, 16)
  bottomleft:SetHeight(16)
  bottomleft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")

  local texBL1 = bottomleft:CreateTexture(nil, "OVERLAY")
  texBL1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texBL1:SetBlendMode("ADD")
  texBL1:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1)
  texBL1:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3)
  texBL1:SetPoint("TOPRIGHT", bottomleft, "TOP")

  local texBL2 = bottomleft:CreateTexture(nil, "OVERLAY")
  texBL2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texBL2:SetBlendMode("ADD")
  texBL2:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1)
  texBL2:SetPoint("BOTTOMLEFT", texBL1, "BOTTOMRIGHT")
  texBL2:SetPoint("TOPRIGHT", bottomleft, "RIGHT")

  bottomleft.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texBL1:Show()
    texBL2:Show()
  end
  bottomleft.Clear = function()
    texBL1:Hide()
    texBL2:Hide()
  end

  local topleft = CreateFrame("Frame", nil, frame)
  topleft:EnableMouse()
  topleft:SetWidth(16)
  topleft:SetHeight(16)
  topleft:SetPoint("TOPLEFT", frame, "TOPLEFT")

  local texTL1 = topleft:CreateTexture(nil, "OVERLAY")
  texTL1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texTL1:SetBlendMode("ADD")
  texTL1:SetTexCoord(0.5, 0, 0, 0, 0.5, 1, 0, 1)
  texTL1:SetPoint("TOPLEFT", topleft, "TOPLEFT", 3, -3)
  texTL1:SetPoint("BOTTOMRIGHT", topleft, "BOTTOM")

  local texTL2 = topleft:CreateTexture(nil, "OVERLAY")
  texTL2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texTL2:SetBlendMode("ADD")
  texTL2:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1)
  texTL2:SetPoint("TOPLEFT", texTL1, "TOPRIGHT")
  texTL2:SetPoint("BOTTOMRIGHT", topleft, "RIGHT")

  topleft.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texTL1:Show()
    texTL2:Show()
  end
  topleft.Clear = function()
    texTL1:Hide()
    texTL2:Hide()
  end

  -- top, right, bottom, left

  local top = CreateFrame("Frame", nil, frame)
  top:EnableMouse()
  top:SetHeight(8)
  top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
  top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")

  local texT = top:CreateTexture(nil, "OVERLAY")
  texT:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texT:SetBlendMode("ADD")
  texT:SetPoint("TOPRIGHT", topright, "TOPRIGHT", -3, -3)
  texT:SetPoint("BOTTOMLEFT", topleft, "LEFT", 3, 0)

  top.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texT:Show()
  end
  top.Clear = function()
    texT:Hide()
  end

  local right = CreateFrame("Frame", nil, frame)
  right:EnableMouse()
  right:SetWidth(8)
  right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
  right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")

  local texR = right:CreateTexture(nil, "OVERLAY")
  texR:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texR:SetBlendMode("ADD")
  texR:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMRIGHT", -3, 3)
  texR:SetPoint("TOPLEFT", topright, "TOP", 0, -3)

  right.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texR:Show()
  end
  right.Clear = function()
    texR:Hide()
  end

  local bottom = CreateFrame("Frame", nil, frame)
  bottom:EnableMouse()
  bottom:SetHeight(8)
  bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
  bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")

  local texB = bottom:CreateTexture(nil, "OVERLAY")
  texB:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texB:SetBlendMode("ADD")
  texB:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
  texB:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3)
  texB:SetPoint("TOPRIGHT", bottomright, "RIGHT", -3, 0)

  bottom.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texB:Show()
  end
  bottom.Clear = function()
    texB:Hide()
  end

  local left = CreateFrame("Frame", nil, frame)
  left:EnableMouse()
  left:SetWidth(8)
  left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
  left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")

  local texL = left:CreateTexture(nil, "OVERLAY")
  texL:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texL:SetBlendMode("ADD")
  texL:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
  texL:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3)
  texL:SetPoint("TOPRIGHT", topleft, "TOP", 0, -3)

  left.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texL:Show()
  end
  left.Clear = function()
    texL:Hide()
  end

  -- return in cw order
  return top, topright, right, bottomright, bottom, bottomleft, left, topleft
end

--- @class AlignmentLineReference
--- @field id auraId
--- @field side "LEFT"|"RIGHT"|"TOP"|"BOTTOM"|"CENTERX"|"CENTERY" The side the reference
--- @field pos1 number The bottom position for vertical or the left position for horizontal lines
--- @field pos2 number The top position for vertical or the right position for horizontal lines

--- @class AlignmentLine
--- @field SetStartPoint fun(self: AlignmentLine, relativePoint: AnchorPoint, relativeTo: Region, offsetX: number?, offsetY: number?)
--- @field SetEndPoint fun(self: AlignmentLine, relativePoint: AnchorPoint, relativeTo: Region, offsetX: number?, offsetY: number?)
--- @field SetThickness fun(self: AlignmentLine, thickness: number)
--- @field SetHighlighted fun(self: AlignmentLine, highlight: boolean)

--- @class LineObjectPool
--- @field Acquire fun(self: LineObjectPool): AlignmentLine
--- @field Release fun(self: LineObjectPool, line: AlignmentLine)

--- @class LineInformation
--- @field position number
--- @field delta number
--- @field gridLine boolean
--- @field references AlignmentLineReference[]
--- @field highlightTextures Texture[]
--- @field line AlignmentLine?
--- @field SetStartPoint fun(self: LineInformation, relativePoint: AnchorPoint, relativeTo: Region, offsetX: number?, offsetY: number?)
--- @field SetEndPoint fun(self: LineInformation, relativePoint: AnchorPoint, relativeTo: Region, offsetX: number?, offsetY: number?)
--- @field SetThickness fun(self: LineInformation, thickness: number)
--- @field SetHighlighted fun(self: LineInformation, highlight: boolean)
--- @field Hide fun(self: LineInformation)
--- @field Show fun(self: LineInformation)
--- @field UpdateColor fun(self: LineInformation)
--- @field UpdateHighlight fun(self: LineInformation)
--- @field AcquireLine fun(self: LineInformation)
--- @field ReleaseLine fun(self: LineInformation)
--- @field Release fun(self: LineInformation)
--- @field Score fun(self: LineInformation, positions: table<"LEFT"|"RIGHT"|"TOP"|"BOTTOM"|"CENTERX"|"CENTERY", number>): number

--- @class AlignmentLines
local AlignmentLines = CreateFrame("Frame", nil, UIParent) --[[@as AlignmentLines]]
AlignmentLines:SetAllPoints(UIParent)
AlignmentLines:SetFrameStrata("BACKGROUND")

local HighlightFrame = CreateFrame("Frame", nil, UIParent)
HighlightFrame:SetAllPoints(UIParent)
HighlightFrame:SetFrameStrata("TOOLTIP")

--- @type LineObjectPool
AlignmentLines.linePool = CreateObjectPool(
  function(self)
    return AlignmentLines:CreateLine()
  end,
  function(self, line)
    line:Hide()
  end)

HighlightFrame.texturePool = CreateObjectPool(
  function(self)
    local tex = HighlightFrame:CreateTexture()
    tex:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
    tex:SetVertexColor(1, 1, 1, 0.3)
    return tex
  end,
  function(self, texture)
    texture:Hide()
    texture:ClearAllPoints()
  end)

--- @type fun(side: "LEFT"|"RIGHT"|"BOTTOM"|"TOP"|"CENTERX"|"CENTERY"): "LEFT"|"RIGHT"|"BOTTOM"|"TOP"|"CENTERX"|"CENTERY"
local function MirrorSide(side)
  if side == "LEFT" then
    return "RIGHT"
  elseif side == "RIGHT" then
    return "LEFT"
  elseif side == "TOP" then
    return "BOTTOM"
  elseif side == "BOTTOM" then
    return "TOP"
  else -- "CENTERX" or "CENTERY"
    return side
  end
end

--- @type fun(side: "LEFT"|"RIGHT"|"BOTTOM"|"TOP"|"CENTERX"|"CENTERY"): "LEFT"|"RIGHT"|"BOTTOM"|"TOP"|"CENTERX"|"CENTERY"|nil
local function Pos1Side(side)
  if side == "LEFT" or side == "RIGHT" or side == "CENTERX" then
    return "BOTTOM"
  elseif side == "TOP" or side == "BOTTOM" or side == "CENTERY" then
    return "LEFT"
  end
end

--- @type fun(side: "LEFT"|"RIGHT"|"BOTTOM"|"TOP"|"CENTERX"|"CENTERY"): "LEFT"|"RIGHT"|"BOTTOM"|"TOP"|"CENTERX"|"CENTERY"|nil
local function Pos2Side(side)
  if side == "LEFT" or side == "RIGHT" or side == "CENTERX" then
    return "TOP"
  elseif side == "TOP" or side == "BOTTOM" or side == "CENTERY" then
    return "RIGHT"
  end
end

--- @class LineInformation
local LineInformationFuncs = {
  SetStartPoint = function(self, relativePoint, relativeTo, offsetX, offsetY)
    self.startPoint = {relativePoint, relativeTo, offsetX, offsetY}
    if self.line then
      self.line:SetStartPoint(relativePoint, relativeTo, offsetX, offsetY)
    end
  end,
  SetEndPoint = function(self, relativePoint, relativeTo, offsetX, offsetY)
    self.endPoint = {relativePoint, relativeTo, offsetX, offsetY}
    if self.line then
      self.line:SetEndPoint(relativePoint, relativeTo, offsetX, offsetY)
    end
  end,
  SetThickness = function(self, thickness)
    self.thickness = thickness
    if self.line then
      self.line:SetThickness(thickness)
    end
  end,
  Show = function(self)
    if not self.line then
      self:AcquireLine()
    end
    self:UpdateColor()
    self.line:SetStartPoint(unpack(self.startPoint))
    self.line:SetEndPoint(unpack(self.endPoint))
    self.line:SetThickness(self.thickness)
    self.line:Show()
  end,
  SetHighlighted = function(self, highlight)
    if self.highlight == highlight then
      return
    end

    local needLine = highlight or showNormalLines
    self.highlight = highlight

    if needLine and not self.line then
      self:Show()
    elseif not needLine and self.line then
      self:ReleaseLine()
    end
    self:UpdateColor()
    self:UpdateHighlight()
  end,
  UpdateColor = function(self)
    if not self.line then
      return
    end

    if self.highlight then
      if self.gridLine then
        self.line:SetColorTexture(unpack(gridHighlightColor))
      else
        self.line:SetColorTexture(unpack(highlightColor))
      end
    else
      if self.gridLine then
        self.line:SetColorTexture(unpack(gridColor))
      else
        self.line:SetColorTexture(unpack(normalColor))
      end
    end
  end,
  UpdateHighlight = function(self)
    if self.highlight then
      for _, data in ipairs(self.references) do
        local region = WeakAuras.GetRegion(data.id)
        local texture = HighlightFrame.texturePool:Acquire()
        texture:SetAllPoints(region)
        texture:SetDrawLayer("ARTWORK", 7)
        texture:Show()
        tinsert(self.highlightTextures, texture)
      end
    else
      for _, texture in ipairs(self.highlightTextures) do
        HighlightFrame.texturePool:Release(texture)
      end
      wipe(self.highlightTextures)
    end
  end,
  AcquireLine = function(self)
    if not self.line then
      self.line = AlignmentLines.linePool:Acquire()
    end
  end,
  ReleaseLine = function(self)
    if self.line then
      AlignmentLines.linePool:Release(self.line)
      self.line = nil
    end
  end,
  Release = function(self)
    -- Clears any aura highlights
    self:SetHighlighted(false)
    self:ReleaseLine()
  end,
  AddReference = function(self, id, side, pos1, pos2)
    tinsert(self.references, {id = id, side = side, pos1 = pos1, pos2 = pos2})
  end,
  --- @type fun(self: LineInformation, positions: table<"LEFT"|"RIGHT"|"BOTTOM"|"TOP"|"CENTERX"|"CENTERY", number>) : number
  Score = function(self, positions)
    if self.gridLine then
      return 0 -- Prefer aura lines
    else
      local score = -1

      for _, ref in ipairs(self.references) do
        -- The line is within MAGNETIC_ALIGNMENT, otherwise we wouldn't be asked to score it
        -- This compares whether the line is for the same "side",
        -- by checking the distance to that side
        local auraPos = positions[ref.side]
        local mirrorPos = positions[MirrorSide(ref.side)]
        if auraPos then
          local dist = distance(auraPos, self.position)
          if dist < MAGNETIC_ALIGNMENT then
            -- Same side: 100 as a base, meaning these lines are heavily preferred to lines
            -- for other sides
            score = max(score, 100 + (MAGNETIC_ALIGNMENT - dist))
          elseif mirrorPos then
            dist = distance(mirrorPos, self.position)
            score = max(score, 10 + (MAGNETIC_ALIGNMENT - dist))
          end

          -- Now check how far away the reference is on the orthogonal direction
          -- Add up to 80 points for being near a reference
          local auraPos1 = positions[Pos1Side(ref.side)]
          local auraPos2 = positions[Pos2Side(ref.side)]
          if auraPos1 and auraPos2 then
            local minDistanceOrth = min(distance(auraPos1, ref.pos1), distance(auraPos2, ref.pos2))
            if minDistanceOrth < 10 * MAGNETIC_ALIGNMENT then
              score = score + 8 * (10 * MAGNETIC_ALIGNMENT - minDistanceOrth)
            end
          end
        end
      end
      return score
    end
  end,

}

--- @type fun(position: number, gridLine: boolean): LineInformation
local function CreateLineInformation(position, gridLine)
  local line = {}
  for k, f in pairs(LineInformationFuncs) do
    line[k] = f
  end
  line.position = position
  line.gridLine = gridLine
  line.references = {}
  line.highlightTextures = {}
  line.highlight = nil
  return line
end

--- @type table<number, LineInformation>
AlignmentLines.horizontalLines = {}
--- @type table<number, LineInformation>
AlignmentLines.verticalLines = {}

--- @type fun(input: number): number
local function RoundSmallDifference(input)
  local r = Round(input)
  if (abs(r - input) < 0.1) then
    return r
  end
  return input
end

--- @type fun(input: number): number
local function AlignToPixelX(virX)
  local physicalWidth, physicalHeight = GetPhysicalScreenSize();
  local virtualWidth = GetScreenWidth()
  local phyX = virX * physicalWidth / virtualWidth
  return Round(10 * Round(phyX) * virtualWidth / physicalWidth) / 10
end

--- @type fun(input: number): number
local function AlignToPixelY(virY)
  local physicalWidth, physicalHeight = GetPhysicalScreenSize();
  local virtualHeight = GetScreenHeight()
  local phyY = virY * physicalHeight / virtualHeight
  return Round(10 * Round(phyY) * virtualHeight / physicalHeight) / 10
end

---@param self AlignmentLines
---@param sizerPoint AnchorPoint?
AlignmentLines.CreateMiddleLines = function(self, sizerPoint)
  if not createCenterLines then
    return
  end

  local midX, midY = UIParent:GetCenter()
  midX = RoundSmallDifference(midX)
  midY = RoundSmallDifference(midY)
  if not sizerPoint or sizerPoint:find("LEFT", 1) or sizerPoint:find("RIGHT", 1) then
    local line = CreateLineInformation(midX, true)
    line:SetStartPoint("TOPLEFT", UIParent, midX, 0)
    line:SetEndPoint("BOTTOMLEFT", UIParent, midX, 0)
    line:SetThickness(2)
    self.verticalLines[midX] = line
  end

  if not sizerPoint or sizerPoint:find("BOTTOM") or sizerPoint:find("TOP") then
    local line = CreateLineInformation(midY, true)
    line:SetStartPoint("BOTTOMLEFT", UIParent, 0, midY)
    line:SetEndPoint("BOTTOMRIGHT", UIParent, 0, midY)
    line:SetThickness(2)
    self.horizontalLines[midY] = line
  end
end

--- @type fun(self: AlignmentLines, data: auraData, sizerPoint: AnchorPoint?): LineInformation, LineInformation
AlignmentLines.CreateLineInformation = function(self, data, sizerPoint)
  local addVertical = not sizerPoint or sizerPoint:find("LEFT", 1) or sizerPoint:find("RIGHT", 1)
  local addHorizontal = not sizerPoint or sizerPoint:find("BOTTOM", 1) or sizerPoint:find("TOP", 1)

  --- @type LineInformation, LineInformation
  local horizontalLines, verticalLines = {}, {}
  --- @type table<auraId, boolean>
  local skipIds = {}
  for child in OptionsPrivate.Private.TraverseAll(data) do
    skipIds[child.id] = true
  end

  for id, v in pairs(OptionsPrivate.displayButtons) do
    local region = WeakAuras.GetRegion(v.data.id)
    if not skipIds[id]
       and v.view.visibility >= 1
       and region and not region:IsAnchoringRestricted()
       and v.data.regionType ~= "group"
       and v.data.regionType ~= "dynamicgroup"
    then
      local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
      local left = region:GetLeft()
      left = left and AlignToPixelX(left * scale) or nil
      local right = region:GetRight()
      right = right and AlignToPixelX(right * scale) or nil
      local top = region:GetTop()
      top = top and AlignToPixelY(top * scale) or nil
      local bottom = region:GetBottom()
      bottom = bottom and AlignToPixelY(bottom * scale) or nil
      local centerX, centerY = region:GetCenter()
      centerX = centerX and AlignToPixelX(centerX * scale) or nil
      centerY = centerY and AlignToPixelY(centerY * scale) or nil

      if v.data.regionType == "group" then
        -- This is the correct code for groups, but it is disabled above
        -- Imho it works better if it is disabled
        left = left + region.blx * scale
        right = right + region.trx * scale
        bottom = bottom + region.bly * scale
        top = top + region.try * scale
        centerX = (left + right) / 2
        centerY = (bottom + top) / 2
      end

      if not IsControlKeyDown() then
        if addVertical then
          if left and bottom and top then
            local leftLine = CreateLineInformation(left, false)
            leftLine:AddReference(id, "LEFT", bottom, top)
            tinsert(verticalLines, leftLine)
          end

          if right and bottom and top then
            local rightLine = CreateLineInformation(right, false)
            rightLine:AddReference(id, "RIGHT", bottom, top)
            tinsert(verticalLines, rightLine)
          end
        end
        if addHorizontal then
          if top and left and right then
            local topLine = CreateLineInformation(top, false)
            topLine:AddReference(id, "TOP", left, right)
            tinsert(horizontalLines, topLine)
          end

          if bottom and left and right then
            local bottomLine = CreateLineInformation(bottom, false)
            bottomLine:AddReference(id, "BOTTOM", left, right)
            tinsert(horizontalLines, bottomLine)
          end
        end
      else
        if addVertical then
          if centerX and bottom and top then
            local xLine = CreateLineInformation(centerX, false)
            xLine:AddReference(id, "CENTERX", bottom, top)
            tinsert(verticalLines, xLine)
          end
        end
        if addHorizontal then
          if centerY and left and right then
            local yLine = CreateLineInformation(centerY, false)
            yLine:AddReference(id, "CENTERY", left, right)
            tinsert(horizontalLines, yLine)
          end
        end
      end
    end
  end

  table.sort(verticalLines, function(a, b) return a.position < b.position end)
  table.sort(horizontalLines, function(a, b) return a.position < b.position end)

  return self:MergeLineInformation(verticalLines), self:MergeLineInformation(horizontalLines)
end

--- @type fun(self: AlignmentLines, lines: LineInformation): LineInformation
AlignmentLines.MergeLineInformation = function(self, lines)
  local startIndex
  local startPos
  -- Add a line at infinity at the end, this makes the loop easier
  tinsert(lines, {position = math.huge})

  --- @type LineInformation
  local result = {}
  for index, line in ipairs(lines) do
    if not startPos then
      startPos = line.position
      startIndex = index
    else
      if (line.position - startPos) >= 1 then
        if startIndex then
          -- This line is too far away from the last lines to merge,
          -- So merge from startIndex to index - 1
          local lineToInsert = lines[startIndex]
          local positionSum = lineToInsert.position
          for i = startIndex + 1, index - 1 do
            local lineToMerge = lines[i]
            positionSum = positionSum + lineToMerge.position
            tinsert(lineToInsert.references, lineToMerge.references[1])
          end
          lineToInsert.position = positionSum / (index - startIndex)
          tinsert(result, lineToInsert)
          -- Now start a potential new merge from this line
          startPos = line.position
          startIndex = index
        end
      else
        -- Will be merged later
      end
    end
  end
  -- And remove the infinity line at the end
  lines[#lines] = nil

  return result
end

---@param self AlignmentLines
AlignmentLines.CleanUpLines = function(self)
  for _, line in pairs(self.horizontalLines) do
    line:Release()
  end

  for _, line in pairs(self.verticalLines) do
    line:Release()
  end

  wipe(self.horizontalLines)
  wipe(self.verticalLines)
end

---@param self AlignmentLines
---@param data auraData
---@param sizerPoint AnchorPoint?
AlignmentLines.CreateLines = function(self, data, sizerPoint)
  self:CleanUpLines()

  local align = (WeakAurasOptionsSaved.magnetAlign and not IsShiftKeyDown())
                    or (not WeakAurasOptionsSaved.magnetAlign and IsShiftKeyDown())
  if align then
    self:CreateMiddleLines()

    local auraVerticalLinesInfo, auraHorizontalLinesInfo = self:CreateLineInformation(data, sizerPoint)

    for _, lineInfo in ipairs(auraVerticalLinesInfo) do
      local x = lineInfo.position
      if self.verticalLines[floor(x)] or self.verticalLines[ceil(x)] then
        -- Grid lines are always on integer values
        -- Ignore a grid line that is close enough is already there
      else
        lineInfo:SetStartPoint("TOPLEFT", UIParent, x, 0)
        lineInfo:SetEndPoint("BOTTOMLEFT", UIParent, x, 0)
        lineInfo:SetThickness(2)
        self.verticalLines[x] = lineInfo
      end
    end

    for _, lineInfo in ipairs(auraHorizontalLinesInfo) do
      local y = lineInfo.position
      if self.horizontalLines[floor(y)] or self.horizontalLines[ceil(y)] then
        -- Grid lines are always on integer values
        -- Ignore a grid line that is close enough is already there
      else
        lineInfo:SetStartPoint("BOTTOMLEFT", UIParent, 0, y)
        lineInfo:SetEndPoint("BOTTOMRIGHT", UIParent, 0, y)
        lineInfo:SetThickness(2)
        self.horizontalLines[y] = lineInfo
      end
    end
  end
end

---@param lines AlignmentLine[]
---@param positions table<"LEFT"|"RIGHT"|"TOP"|"BOTTOM"|"CENTERX"|"CENTERY", number>
---       The positions of the aura, that are used to score lines
---@param auraSize number?
---       The size of the aura, this is used to highlight additional lines that exactly
---       auraSize away
---@return number? -- The delta
local function SelectLines(lines, positions, auraSize)
  if #lines == 0 then
    -- Nothing to do
  elseif #lines == 1 then
    lines[1]:SetHighlighted(true)
    return lines[1].delta
  else
    --- @type number
    local bestScore = -1
    --- @type AlignmentLine?
    local bestLine = nil
    for _, line in ipairs(lines) do
      local lineScore = line:Score(positions)
      if lineScore > bestScore then
        bestScore = lineScore
        bestLine = line
      end
    end

    for _, line in ipairs(lines) do
      if line == bestLine then
        line:SetHighlighted(true)
      elseif bestLine then
        local diffBetweenLines = distance(line.position, bestLine.position)
        if auraSize and distance(diffBetweenLines, auraSize) < 1 then
          -- Other line is the as far away as the aura is wide
          line:SetHighlighted(true)
        else
          line:SetHighlighted(false)
        end
      else
        line:SetHighlighted(false)
      end
    end
    return bestLine and bestLine.delta
  end
end

AlignmentLines.ShowLinesFor = function(self, ctrlKey, region, sizePoint)
  local align = (WeakAurasOptionsSaved.magnetAlign and not IsShiftKeyDown())
                    or (not WeakAurasOptionsSaved.magnetAlign and IsShiftKeyDown())
  if not align then
    return
  end

  local scale = region:GetEffectiveScale() / UIParent:GetScale()

  local centerX, centerY = region:GetCenter()
  centerX, centerY = centerX * scale, centerY * scale
  local left, right = region:GetLeft() * scale, region:GetRight() * scale
  local top, bottom = region:GetTop() * scale, region:GetBottom() * scale

  if region.regionType == "group" then
    left = left + region.blx * scale
    right = right + region.trx * scale
    bottom = bottom + region.bly * scale
    top = top + region.try * scale
    centerX = (left + right) / 2
    centerY = (bottom + top) / 2
  end

  local positions = {
    LEFT = left,
    RIGHT = right,
    TOP = top,
    BOTTOM = bottom,
    CENTERX = centerX,
    CENTERY = centerY
  }

  local verticalPotentials = {}
  local horizontalPotentials = {}
  if sizePoint then
    local sizeX = sizePoint:find("LEFT", 1) and left or right
    local sizeY = sizePoint:find("TOP", 1) and top or bottom

    for pos, line in pairs(self.verticalLines) do
      if distance(sizeX, pos) < MAGNETIC_ALIGNMENT then
        line.delta = pos - sizeX
        tinsert(verticalPotentials, line)
      else
        line:SetHighlighted(false)
      end
    end

    for pos, line in pairs(self.horizontalLines) do
      if distance(sizeY, pos) < MAGNETIC_ALIGNMENT then
        line.delta = pos - sizeY
        tinsert(horizontalPotentials, line)
      else
        line:SetHighlighted(false)
      end
    end

    mover.verticalDelta = SelectLines(verticalPotentials, positions)
    mover.horizontalDelta = SelectLines(horizontalPotentials, positions)
  else
    if ctrlKey then
      for pos, line in pairs(self.verticalLines) do
        if distance(centerX, pos) < MAGNETIC_ALIGNMENT then
          line.delta = pos - centerX
          tinsert(verticalPotentials, line)
        else
          line:SetHighlighted(false)
        end
      end

      for pos, line in pairs(self.horizontalLines) do
        if distance(centerY, pos) < MAGNETIC_ALIGNMENT then
          line.delta = pos - centerY
          tinsert(horizontalPotentials, line)
        else
          line:SetHighlighted(false)
        end
      end
      mover.verticalDelta = SelectLines(verticalPotentials, positions)
      mover.horizontalDelta = SelectLines(horizontalPotentials, positions)
    else
      for pos, line in pairs(self.verticalLines) do
        if distance(left, pos) < MAGNETIC_ALIGNMENT then
          line.delta = pos - left
          tinsert(verticalPotentials, line)
        elseif distance(right, pos) < MAGNETIC_ALIGNMENT then
          line.delta = pos - right
          tinsert(verticalPotentials, line)
        else
          line:SetHighlighted(false)
        end
      end

      for pos, line in pairs(self.horizontalLines) do
        if distance(bottom, pos) < MAGNETIC_ALIGNMENT then
          line.delta = pos - bottom
          tinsert(horizontalPotentials, line)
        elseif distance(top, pos) < MAGNETIC_ALIGNMENT then
          line.delta = pos - top
          tinsert(horizontalPotentials, line)
        else
          line:SetHighlighted(false)
        end
      end

      local auraWidth = right - left
      local auraHeight = top - bottom
      mover.verticalDelta = SelectLines(verticalPotentials, positions, auraWidth)
      mover.horizontalDelta = SelectLines(horizontalPotentials, positions, auraHeight)
    end
  end
end

local function ConstructMoverSizer(parent)
  local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  frame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
  })
  frame:EnableMouse()

  frame.top, frame.topright, frame.right, frame.bottomright, frame.bottom, frame.bottomleft, frame.left, frame.topleft
  = ConstructSizer(frame)

  frame.arrowTexture, frame.offscreenText = ConstructMover(frame)

  frame.top.Clear()
  frame.topright.Clear()
  frame.right.Clear()
  frame.bottomright.Clear()
  frame.bottom.Clear()
  frame.bottomleft.Clear()
  frame.left.Clear()
  frame.topleft.Clear()

  local mover = CreateFrame("Frame", nil, frame)
  mover:EnableMouse()
  mover.moving = {}
  mover.interims = {}
  mover.selfPointIcon = mover:CreateTexture()
  mover.selfPointIcon:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp")
  mover.selfPointIcon:SetWidth(16)
  mover.selfPointIcon:SetHeight(16)
  mover.selfPointIcon:SetTexCoord(0, 0.25, 0, 1)
  mover.anchorPointIcon = mover:CreateTexture()
  mover.anchorPointIcon:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp")
  mover.anchorPointIcon:SetWidth(16)
  mover.anchorPointIcon:SetHeight(16)
  mover.anchorPointIcon:SetTexCoord(0, 0.25, 0, 1)

  local moverText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  mover.text = moverText
  moverText:Hide()

  local sizerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.text = sizerText
  sizerText:Hide()

  frame.ScaleCorners = function(self, width, height)
    local limit = math.min(width, height) + 16
    local size = 16
    if limit <= 40 then
      size = limit * (2/5)
    end
    frame.bottomleft:SetWidth(size)
    frame.bottomleft:SetHeight(size)
    frame.bottomright:SetWidth(size)
    frame.bottomright:SetHeight(size)
    frame.topright:SetWidth(size)
    frame.topright:SetHeight(size)
    frame.topleft:SetWidth(size)
    frame.topleft:SetHeight(size)
  end

  frame.ReAnchor = function(self)
    if mover.moving.region then
      self:AnchorPoints(mover.moving.region, mover.moving.data)
    end
  end

  frame.AnchorPoints = function(self, region, data)
    local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if data.regionType == "group" then
      mover:SetWidth((region.trx - region.blx) * scale)
      mover:SetHeight((region.try - region.bly) * scale)
    else
      mover:SetWidth(region:GetWidth() * scale)
      mover:SetHeight(region:GetHeight() * scale)
    end
  end

  frame.GetCurrentId = function(self)
    return self.currentId
  end

  frame.SizingSetData = function(self, data, width, height, alignDeltaX, alignDeltaY, scale)
    alignDeltaX = alignDeltaX or 0
    alignDeltaY = alignDeltaY or 0

    local deltaWidth = width - data.width
    local deltaHeight = height - data.height

    local auraSelfPoint = data.selfPoint
    local moverSizePoint = mover.sizePoint

    local parent = data.parent
    if parent then
      local parentData = WeakAuras.GetData(parent)
      if parentData == "dynamicgroup" then
        -- If the aura is in a dynamic group then we don't want to set xOffset/yOffset at all.
        -- These settings ensure that
        auraSelfPoint = "TOPRIGHT"
        moverSizePoint = "BOTTOMLEFT"
      end
    end

    if auraSelfPoint:find("LEFT", 1) then
      if moverSizePoint:find("LEFT", 1) then
        data.xOffset = data.xOffset - deltaWidth + alignDeltaX / scale
        data.width = width - alignDeltaX / scale
      elseif moverSizePoint:find("RIGHT", 1) then
        data.width = width + alignDeltaX / scale
      end
    elseif auraSelfPoint:find("RIGHT", 1) then
      if moverSizePoint:find("LEFT", 1) then
        data.width = width - alignDeltaX / scale
      elseif moverSizePoint:find("RIGHT", 1) then
        data.xOffset = data.xOffset + deltaWidth + alignDeltaX / scale
        data.width = width + alignDeltaX / scale
      end
    else -- CENTER
      if moverSizePoint:find("LEFT", 1) then
        data.xOffset = data.xOffset - deltaWidth / 2 + alignDeltaX / 2 / scale
        data.width = width - alignDeltaX / scale
      else
        data.xOffset = data.xOffset + deltaWidth / 2 + alignDeltaX / 2 / scale
        data.width = width + alignDeltaX / scale
      end
    end

    if auraSelfPoint:find("BOTTOM", 1) then
      if moverSizePoint:find("BOTTOM", 1) then
        data.yOffset = data.yOffset - deltaHeight + alignDeltaY / scale
        data.height = height - alignDeltaY / scale
      elseif moverSizePoint:find("TOP", 1) then
        data.height = height + alignDeltaY / scale
      end
    elseif auraSelfPoint:find("TOP", 1) then
      if moverSizePoint:find("BOTTOM", 1) then
        data.height = height - alignDeltaY / scale
      elseif moverSizePoint:find("TOP", 1) then
        data.yOffset = data.yOffset + deltaHeight + alignDeltaY / scale
        data.height = height + alignDeltaY / scale
      end
    else -- CENTER
      if moverSizePoint:find("BOTTOM", 1) then
        data.yOffset = data.yOffset - deltaHeight / 2 + alignDeltaY / 2 / scale
        data.height = height - alignDeltaY / scale
      else
        data.yOffset = data.yOffset + deltaHeight / 2 + alignDeltaY / 2 / scale
        data.height = height + alignDeltaY / scale
      end
    end
  end

  frame.SetToRegion = function(self, region, data)
    frame.currentId = data.id
    local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
    mover.moving.region = region
    mover.moving.data = data
    mover.onUpdate(mover, 0)
    local ok, selfPoint, anchor, anchorPoint, xOff, yOff = pcall(region.GetPoint, region, 1)
    if not ok then
      return
    end
    self:Show()

    mover.selfPoint, mover.anchor, mover.anchorPoint = selfPoint, anchor, anchorPoint

    xOff = xOff or 0
    yOff = yOff or 0
    mover:ClearAllPoints()
    frame:ClearAllPoints()
    if data.regionType == "group" then
      mover:SetWidth((region.trx - region.blx) * scale)
      mover:SetHeight((region.try - region.bly) * scale)
      mover:SetPoint("BOTTOMLEFT", mover.anchor or UIParent, mover.anchorPoint or "CENTER",
                     (xOff + region.blx) * scale, (yOff + region.bly) * scale)
    else
      mover:SetWidth(region:GetWidth() * scale)
      mover:SetHeight(region:GetHeight() * scale)
      mover:SetPoint(mover.selfPoint or "CENTER", mover.anchor or UIParent, mover.anchorPoint or "CENTER",
                     xOff * scale, yOff * scale)
    end
    frame:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", -8, -8)
    frame:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 8, 8)
    frame:ScaleCorners(region:GetWidth(), region:GetHeight())
    local regionStrata = region:GetFrameStrata()
    if regionStrata then
      local strata = math.min(tIndexOf(OptionsPrivate.Private.frame_strata_types, regionStrata) + 1, 9)
      frame:SetFrameStrata(OptionsPrivate.Private.frame_strata_types[strata])
      mover:SetFrameStrata(OptionsPrivate.Private.frame_strata_types[strata])
      frame:SetFrameLevel(region:GetFrameLevel() + 1)
      mover:SetFrameLevel(region:GetFrameLevel() + 1)
    end

    local db = OptionsPrivate.savedVars.db
    mover.startMoving = function()
      if WeakAurasOptionsSaved.lockPositions then
        return
      end
      OptionsPrivate.Private.CancelAnimation(region, true, true, true, true, true)
      mover:ClearAllPoints()
      if data.regionType == "group" then
        mover:SetPoint("BOTTOMLEFT", region, mover.anchorPoint, region.blx * scale, region.bly * scale)
      else
        mover:SetPoint(mover.selfPoint, region, mover.selfPoint)
      end
      region:StartMoving()
      mover.isMoving = true
      mover.onUpdate(mover, 0)
      mover.text:Show()
      -- build list of alignment coordinates
      AlignmentLines:CreateLines(mover.moving.data)
      AlignmentLines:Show()
      HighlightFrame:Show()
    end

    mover.doneMoving = function(self, event, key)
      if event == "MODIFIER_STATE_CHANGED" then
        if key == "LCTRL" or key == "RCTRL" or key == "LSHIFT" or key == "RSHIFT" then
          AlignmentLines:CleanUpLines()
          AlignmentLines:CreateLines(mover.moving.data, mover.sizePoint)
          AlignmentLines:Show()
          HighlightFrame:Show()
        end
        return
      end

      if not mover.isMoving then
        return
      end
      region:StopMovingOrSizing()
      mover.isMoving = false
      mover.text:Hide()
      AlignmentLines:CleanUpLines()
      AlignmentLines:Hide()
      HighlightFrame:Hide()

      local align = (WeakAurasOptionsSaved.magnetAlign and not IsShiftKeyDown())
                    or (not WeakAurasOptionsSaved.magnetAlign and IsShiftKeyDown())

      local xDelta = 0
      local yDelta = 0
      if align then
        xDelta = mover.verticalDelta or 0
        yDelta = mover.horizontalDelta or 0
      end

      if data.xOffset and data.yOffset then
        local selfX, selfY = mover.selfPointIcon:GetCenter()
        local anchorX, anchorY = mover.anchorPointIcon:GetCenter()
        local dX = selfX - anchorX
        local dY = selfY - anchorY
        data.xOffset = dX / scale + xDelta / scale
        data.yOffset = dY / scale + yDelta / scale
      end
      region:ResetPosition()
      WeakAuras.Add(data)
      OptionsPrivate.Private.AddParents(data)
      WeakAuras.UpdateThumbnail(data)

      local xOff, yOff
      mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1)
      xOff = xOff or 0
      yOff = yOff or 0
      mover:ClearAllPoints()
      if data.regionType == "group" then
        mover:SetWidth((region.trx - region.blx) * scale)
        mover:SetHeight((region.try - region.bly) * scale)
        mover:SetPoint("BOTTOMLEFT", mover.anchor, mover.anchorPoint,
                       (xOff + region.blx) * scale, (yOff + region.bly) * scale)
      else
        mover:SetWidth(region:GetWidth() * scale)
        mover:SetHeight(region:GetHeight() * scale)
        mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale)
      end
      frame.text:Hide()
      frame:SetScript("OnUpdate", nil)

      WeakAuras.FillOptions()
      OptionsPrivate.Private.Animate("display", data.uid, "main", data.animation.main,
                                     OptionsPrivate.Private.EnsureRegion(data.id), false, nil, true)
    end

    if data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup" then
      mover:SetScript("OnMouseDown", nil)
      mover:SetScript("OnMouseUp", nil)
      mover:SetScript("OnEvent", nil)
      mover:SetScript("OnHide", nil)
    else
      mover:SetScript("OnMouseDown", mover.startMoving)
      mover:SetScript("OnMouseUp", mover.doneMoving)
      mover:SetScript("OnEvent", mover.doneMoving)
      mover:SetScript("OnHide", mover.doneMoving)
    end

    if region:IsResizable() then
      frame.startSizing = function(point)
        if WeakAurasOptionsSaved.lockPositions then
          return
        end
        mover.isMoving = true
        OptionsPrivate.Private.CancelAnimation(region, true, true, true, true, true)
        region:StartSizing(point)
        frame.text:ClearAllPoints()
        frame.text:SetPoint("CENTER", frame, "CENTER", 0, -15)
        frame.text:Show()
        mover:ClearAllPoints()
        mover:SetAllPoints(region)
        frame:SetScript("OnUpdate", function()
          frame.text:SetText(("(%.2f, %.2f)"):format(region:GetWidth(), region:GetHeight()))
          if data.width and data.height then
            frame:SizingSetData(data, region:GetWidth(), region:GetHeight(), 0, 0, scale)
          end
          region:ResetPosition()
          WeakAuras.Add(data, true)
          frame:ScaleCorners(region:GetWidth(), region:GetHeight())
          WeakAuras.FillOptions()
        end)

        AlignmentLines:CreateLines(mover.moving.data, point)
        AlignmentLines:Show()
        HighlightFrame:Show()
        mover.sizePoint = point
      end

      frame.doneSizing = function()
        if not mover.sizePoint then
          return
        end
        mover.isMoving = false
        region:StopMovingOrSizing()

        AlignmentLines:CleanUpLines()
        AlignmentLines:Hide()
        HighlightFrame:Hide()

        local width = region:GetWidth()
        local height = region:GetHeight()

        local align = (WeakAurasOptionsSaved.magnetAlign and not IsShiftKeyDown())
                      or (not WeakAurasOptionsSaved.magnetAlign and IsShiftKeyDown())

        local deltaX = 0
        local deltaY = 0
        if align then
          deltaX = mover.verticalDelta or 0
          deltaY = mover.horizontalDelta or 0
        end

        frame:SizingSetData(data, width, height, deltaX, deltaY, scale)

        region:ResetPosition()
        WeakAuras.Add(data, true)
        OptionsPrivate.Private.AddParents(data)
        WeakAuras.UpdateThumbnail(data)

        frame:ScaleCorners(region:GetWidth(), region:GetHeight())
        local xOff, yOff
        mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1)
        xOff = xOff or 0
        yOff = yOff or 0
        mover:ClearAllPoints()
        if data.regionType == "group" then
          mover:SetWidth((region.trx - region.blx) * scale)
          mover:SetHeight((region.try - region.bly) * scale)
          mover:SetPoint("BOTTOMLEFT", mover.anchor, mover.anchorPoint,
                         (xOff + region.blx) * scale,
                         (yOff + region.bly) * scale)
        else
          mover:SetWidth(region:GetWidth() * scale)
          mover:SetHeight(region:GetHeight() * scale)
          mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale)
        end
        frame.text:Hide()
        frame:SetScript("OnUpdate", nil)
        WeakAuras.FillOptions()
        OptionsPrivate.Private.Animate("display", data.uid, "main", data.animation.main,
                                       OptionsPrivate.Private.EnsureRegion(data.id), false, nil, true)
        mover.sizePoint = nil
      end

      frame.bottomleft:SetScript("OnMouseDown", function() frame.startSizing("BOTTOMLEFT") end)
      frame.bottomleft:SetScript("OnMouseUp", function() frame.doneSizing("BOTTOMLEFT") end)
      frame.bottomleft:SetScript("OnEnter", frame.bottomleft.Highlight)
      frame.bottomleft:SetScript("OnLeave", frame.bottomleft.Clear)
      frame.bottom:SetScript("OnMouseDown", function() frame.startSizing("BOTTOM") end)
      frame.bottom:SetScript("OnMouseUp", function() frame.doneSizing("BOTTOM") end)
      frame.bottom:SetScript("OnEnter", frame.bottom.Highlight)
      frame.bottom:SetScript("OnLeave", frame.bottom.Clear)
      frame.bottomright:SetScript("OnMouseDown", function() frame.startSizing("BOTTOMRIGHT") end)
      frame.bottomright:SetScript("OnMouseUp", function() frame.doneSizing("BOTTOMRIGHT") end)
      frame.bottomright:SetScript("OnEnter", frame.bottomright.Highlight)
      frame.bottomright:SetScript("OnLeave", frame.bottomright.Clear)
      frame.right:SetScript("OnMouseDown", function() frame.startSizing("RIGHT") end)
      frame.right:SetScript("OnMouseUp", function() frame.doneSizing("RIGHT") end)
      frame.right:SetScript("OnEnter", frame.right.Highlight)
      frame.right:SetScript("OnLeave", frame.right.Clear)
      frame.topright:SetScript("OnMouseDown", function() frame.startSizing("TOPRIGHT") end)
      frame.topright:SetScript("OnMouseUp", function() frame.doneSizing("TOPRIGHT") end)
      frame.topright:SetScript("OnEnter", frame.topright.Highlight)
      frame.topright:SetScript("OnLeave", frame.topright.Clear)
      frame.top:SetScript("OnMouseDown", function() frame.startSizing("TOP") end)
      frame.top:SetScript("OnMouseUp", function() frame.doneSizing("TOP") end)
      frame.top:SetScript("OnEnter", frame.top.Highlight)
      frame.top:SetScript("OnLeave", frame.top.Clear)
      frame.topleft:SetScript("OnMouseDown", function() frame.startSizing("TOPLEFT") end)
      frame.topleft:SetScript("OnMouseUp", function() frame.doneSizing("TOPLEFT") end)
      frame.topleft:SetScript("OnEnter", frame.topleft.Highlight)
      frame.topleft:SetScript("OnLeave", frame.topleft.Clear)
      frame.left:SetScript("OnMouseDown", function() frame.startSizing("LEFT") end)
      frame.left:SetScript("OnMouseUp", function() frame.doneSizing("LEFT") end)
      frame.left:SetScript("OnEnter", frame.left.Highlight)
      frame.left:SetScript("OnLeave", frame.left.Clear)

      frame.bottomleft:Show()
      frame.bottom:Show()
      frame.bottomright:Show()
      frame.right:Show()
      frame.topright:Show()
      frame.top:Show()
      frame.topleft:Show()
      frame.left:Show()
    else
      frame.bottomleft:Hide()
      frame.bottom:Hide()
      frame.bottomright:Hide()
      frame.right:Hide()
      frame.topright:Hide()
      frame.top:Hide()
      frame.topleft:Hide()
      frame.left:Hide()
    end
    frame:Show()
  end

  mover.onUpdate = function(self, elaps)
    if not IsShiftKeyDown() then
      self.goalAlpha = 1
    else
      self.goalAlpha = 0.1
    end

    if self.currentAlpha ~= self.goalAlpha then
      self.currentAlpha = self.currentAlpha or self:GetAlpha()
      local newAlpha = (self.currentAlpha < self.goalAlpha) and self.currentAlpha + (elaps * 4) or self.currentAlpha - (elaps * 4)
      newAlpha = (newAlpha > 1 and 1) or (newAlpha < 0.1 and 0.1) or newAlpha
      mover:SetAlpha(newAlpha)
      frame:SetAlpha(newAlpha)
      self.currentAlpha = newAlpha
    end

    local db = OptionsPrivate.savedVars.db
    local region = self.moving.region
    local data = self.moving.data
    if not self.isMoving then
      local ok, selfPoint, anchor, anchorPoint = pcall(region.GetPoint, region, 1)
      if not ok then
        self:Hide()
        return
      end
      self.selfPoint, self.anchor, self.anchorPoint = selfPoint, anchor, anchorPoint
    end
    self.selfPointIcon:ClearAllPoints()
    self.selfPointIcon:SetPoint("CENTER", region, self.selfPoint)
    local selfX, selfY = self.selfPointIcon:GetCenter()
    selfX, selfY = selfX or 0, selfY or 0
    self.anchorPointIcon:ClearAllPoints()
    self.anchorPointIcon:SetPoint("CENTER", self.anchor, self.anchorPoint)
    local anchorX, anchorY = self.anchorPointIcon:GetCenter()
    anchorX, anchorY = anchorX or 0, anchorY or 0
    if data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup" then
      self.selfPointIcon:Hide()
      self.anchorPointIcon:Hide()
    else
      self.selfPointIcon:Show()
      self.anchorPointIcon:Show()
    end

    local dX = selfX - anchorX
    local dY = selfY - anchorY
    local distance = sqrt(dX^2 + dY^2)
    local angle = atan2(dY, dX)

    local numInterim = floor(distance/40)

    for _, texture in pairs(self.interims) do
      texture:Hide()
    end
    for i = 1, numInterim  do
      local x = (distance - (i * 40)) * cos(angle)
      local y = (distance - (i * 40)) * sin(angle)
      self.interims[i] = EnsureTexture(self, self.interims[i])
      self.interims[i]:ClearAllPoints()
      self.interims[i]:SetPoint("CENTER", self.anchorPointIcon, "CENTER", x, y)
      self.interims[i]:Show()
    end

    frame.arrowTexture:Hide()
    frame.offscreenText:Hide()

    -- Check if the center is offscreen
    -- How many pixels of the aura need to be visible
    local margin = 30
    local x, y = mover:GetCenter()
    if x and y then
      if mover:GetRight() < margin or mover:GetLeft() + margin > GetScreenWidth() or mover:GetTop() < 20 or mover:GetBottom() + margin > GetScreenHeight() then
        local arrowX, arrowY = frame.arrowTexture:GetCenter()
        local arrowAngle = atan2(y - arrowY, x - arrowX)
        frame.offscreenText:Show()
        frame.arrowTexture:Show()
        frame.arrowTexture:SetRotation( (arrowAngle - 90) / 180 * math.pi)
      end
    end

    local regionScale = self.moving.region:GetScale()
    self.text:SetText(("(%.2f, %.2f)"):format(dX*1/regionScale, dY*1/regionScale))
    local midX = (distance / 2) * cos(angle)
    local midY = (distance / 2) * sin(angle)
    self.text:SetPoint("CENTER", self.anchorPointIcon, "CENTER", midX, midY)
    local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if (midX > 0 and (self.text:GetRight() or 0) > (left or 0))
    or (midX < 0 and (self.text:GetLeft() or 0) < (right or 0))
    then
      if midY > 0 and (self.text:GetTop() or 0) > (top or 0) then
        midY = midY - ((self.text:GetTop() or 0) - (bottom or 0))
      elseif midY < 0 and (self.text:GetBottom() or 0) < (top or 0) then
        midY = midY + ((top or 0) - (self.text:GetBottom() or 0))
      end
    end
    self.text:SetPoint("CENTER", self.anchorPointIcon, "CENTER", midX, midY)
    if self.isMoving then
      AlignmentLines:ShowLinesFor(IsControlKeyDown(), region, mover.sizePoint)
    end
  end

  frame.OptionsOpened = function()
    mover:Show()
    mover:RegisterEvent("MODIFIER_STATE_CHANGED")
    mover:SetScript("OnUpdate", mover.onUpdate)
    AlignmentLines:Show()
    HighlightFrame:Show()
  end

  frame.OptionsClosed = function()
    if frame.doneSizing then
      frame.doneSizing()
    end
    if mover.doneMoving then
      mover.doneMoving()
    end
    mover:UnregisterEvent("MODIFIER_STATE_CHANGED")
    mover:SetScript("OnUpdate", nil)
    mover:Hide()
    AlignmentLines:Hide()
    HighlightFrame:Hide()
  end

  return frame, mover
end

function OptionsPrivate.MoverSizer(parent)
  if not moversizer or not mover then
    moversizer, mover = ConstructMoverSizer(parent)
  end
  return moversizer, mover
end
