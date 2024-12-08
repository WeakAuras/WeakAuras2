if not WeakAuras.IsLibsOK() then return end

---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L


Private.TextureCoords = {}

local defaultTexCoord = {
  ULx = 0,
  ULy = 0,
  LLx = 0,
  LLy = 1,
  URx = 1,
  URy = 0,
  LRx = 1,
  LRy = 1,
}

local exactAngles = {
  {0.5, 0},  -- 0°
  {1, 0},    -- 45°
  {1, 0.5},  -- 90°
  {1, 1},    -- 135°
  {0.5, 1},  -- 180°
  {0, 1},    -- 225°
  {0, 0.5},  -- 270°
  {0, 0}     -- 315°
}

--- @type fun(angle: number): number, number
local function angleToCoord(angle)
  angle = angle % 360

  if (angle % 45 == 0) then
    local index = floor (angle / 45) + 1
    return exactAngles[index][1], exactAngles[index][2]
  end

  if (angle < 45) then
    return 0.5 + tan(angle) / 2, 0
  elseif (angle < 135) then
    return 1, 0.5 + tan(angle - 90) / 2
  elseif (angle < 225) then
    return 0.5 - tan(angle) / 2, 1
  elseif (angle < 315) then
    return 0, 0.5 - tan(angle - 90) / 2
  elseif (angle < 360) then
    return 0.5 + tan(angle) / 2, 0
  end
end

--- @alias TextureCoordsCorner "UL"|"LL"|"UR"|"LR"

--- @type TextureCoordsCorner[]
local pointOrder = { "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR" }

--- @type fun(x: number, y:number, scalex: number, scaley: number, texRotation: number, mirror_h: number, mirror_v: number, user_x: number?, user_y: number?)
local function TransformPoint(x, y, scalex, scaley, texRotation, mirror_h, mirror_v, user_x, user_y)
  -- 1) Translate texture-coords to user-defined center
  x = x - 0.5
  y = y - 0.5

  -- 2) Shrink texture by 1/sqrt(2)
  x = x * 1.4142
  y = y * 1.4142

  -- Not yet supported for circular progress
  -- 3) Scale texture by user-defined amount
  x = x / scalex
  y = y / scaley

  -- 4) Apply mirroring if defined
  if mirror_h then
    x = -x
  end
  if mirror_v then
    y = -y
  end

  local cos_rotation = cos(texRotation)
  local sin_rotation = sin(texRotation)

  -- 5) Rotate texture by user-defined value
  x, y = cos_rotation * x - sin_rotation * y, sin_rotation * x + cos_rotation * y

  -- 6) Translate texture-coords back to (0,0)
  x = x + 0.5
  y = y + 0.5

  x = x + (user_x or 0)
  y = y + (user_y or 0)

  return x, y
end



--- @class TextureCoords
--- @field ULx number
--- @field ULy number
--- @field LLx number
--- @field LLy number
--- @field URx number
--- @field URy number
--- @field LRx number
--- @field LRy number
--- @field ULvx number
--- @field ULvy number
--- @field LLvx number
--- @field LLvy number
--- @field URvx number
--- @field URvy number
--- @field LRvx number
--- @field LRvy number
--- @field texture Texture

--- @class TextureCoords
local funcs = {
  --- @type fun(self: TextureCoords, width: number, height: number, corner: TextureCoordsCorner, x: number, y: number)
  MoveCorner = function (self, width, height, corner, x, y)
    local rx = defaultTexCoord[corner .. "x"] - x
    local ry = defaultTexCoord[corner .. "y"] - y
    self[corner .. "vx"] = -rx * width
    self[corner .. "vy"] = ry * height

    self[corner .. "x"] = x
    self[corner .. "y"] = y
  end,

  --- @type fun(self: TextureCoords)
  Hide = function(self)
    self.texture:Hide()
  end,

  --- @type fun(self: TextureCoords)
  Show = function(self)
    self:Apply()
    self.texture:Show()
  end,

  --- @type fun(self: TextureCoords)
  SetFull = function(self)
    self.ULx = 0
    self.ULy = 0
    self.LLx = 0
    self.LLy = 1
    self.URx = 1
    self.URy = 0
    self.LRx = 1
    self.LRy = 1

    self.ULvx = 0
    self.ULvy = 0
    self.LLvx = 0
    self.LLvy = 0
    self.URvx = 0
    self.URvy = 0
    self.LRvx = 0
    self.LRvy = 0
  end,

  --- @type fun(self: TextureCoords)
  Apply = function(self)
    self.texture:SetVertexOffset(UPPER_RIGHT_VERTEX, self.URvx, self.URvy)
    self.texture:SetVertexOffset(UPPER_LEFT_VERTEX, self.ULvx, self.ULvy)
    self.texture:SetVertexOffset(LOWER_RIGHT_VERTEX, self.LRvx, self.LRvy)
    self.texture:SetVertexOffset(LOWER_LEFT_VERTEX, self.LLvx, self.LLvy)

    self.texture:SetTexCoord(self.ULx, self.ULy, self.LLx, self.LLy, self.URx, self.URy, self.LRx, self.LRy)
  end,
  --- @type fun(self: TextureCoords, width: number, height: number, angle1: number, angle2: number)
  SetAngle = function(self, width, height, angle1, angle2)
    local index = floor((angle1 + 45) / 90)

    local middleCorner = pointOrder[index + 1]
    local startCorner = pointOrder[index + 2]
    local endCorner1 = pointOrder[index + 3]
    local endCorner2 = pointOrder[index + 4]

    -- LL => 32, 32
    -- UL => 32, -32
    self:MoveCorner(width, height, middleCorner, 0.5, 0.5)
    self:MoveCorner(width, height, startCorner, angleToCoord(angle1))

    local edge1 = floor((angle1 - 45) / 90)
    local edge2 = floor((angle2 -45) / 90)

    if (edge1 == edge2) then
      self:MoveCorner(width, height, endCorner1, angleToCoord(angle2))
    else
      self:MoveCorner(width, height, endCorner1, defaultTexCoord[endCorner1 .. "x"], defaultTexCoord[endCorner1 .. "y"])
    end

    self:MoveCorner(width, height, endCorner2, angleToCoord(angle2))
  end,
  --- @type fun(self: TextureCoords, scalex: number, scaley: number, texRotation: number, mirror_h: boolean, mirror_v: boolean, user_x: number?, user_y: number?)
  Transform = function(self, scalex, scaley, texRotation, mirror_h, mirror_v, user_x, user_y)
      self.ULx, self.ULy = TransformPoint(self.ULx, self.ULy, scalex, scaley,
                                          texRotation, mirror_h, mirror_v, user_x, user_y)
      self.LLx, self.LLy = TransformPoint(self.LLx, self.LLy, scalex, scaley,
                                          texRotation, mirror_h, mirror_v, user_x, user_y)
      self.URx, self.URy = TransformPoint(self.URx, self.URy, scalex, scaley,
                                          texRotation, mirror_h, mirror_v, user_x, user_y)
      self.LRx, self.LRy = TransformPoint(self.LRx, self.LRy, scalex, scaley,
                                          texRotation, mirror_h, mirror_v, user_x, user_y)
  end
}

--- @type fun(texture: Texture): TextureCoords
function Private.TextureCoords.create(texture)
  local coord = {
    ULx = 0,
    ULy = 0,
    LLx = 0,
    LLy = 1,
    URx = 1,
    URy = 0,
    LRx = 1,
    LRy = 1,

    ULvx = 0,
    ULvy = 0,
    LLvx = 0,
    LLvy = 0,
    URvx = 0,
    URvy = 0,
    LRvx = 0,
    LRvy = 0,

    texture = texture
  }

  for k, f in pairs(funcs) do
    coord[k] = f
  end

  --- @class TextureCoords
  return coord
end
