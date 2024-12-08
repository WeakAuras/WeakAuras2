if not WeakAuras.IsLibsOK() then return end

---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L

--- @class CircularProgressTextureBase
Private.CircularProgressTextureBase = {}

--- @class CircularProgressTextureInstance
--- @field crop_x number
--- @field crop_y number
--- @field mirror boolean
--- @field mirror_h boolean
--- @field mirror_v boolean
--- @field texRotation number
--- @field visible boolean
--- @field textures Texture[]
--- @field angle1 number
--- @field angle2 number
--- @field offset number
--- @field width number
--- @field height number
--- @field coords TextureCoords[]

--- @class CircularProgressTextureOptions
--- @field crop_x number
--- @field crop_y number
--- @field mirror boolean
--- @field texRotation number
--- @field texture number|string
--- @field desaturated boolean
--- @field blendMode BlendMode
--- @field auraRotation number
--- @field width number
--- @field height number
--- @field offset number

--- @class CircularProgressTextureInstance
local funcs = {
  --- @type fun(self: CircularProgressTextureInstance, radians: number)
  SetAuraRotation = function (self, radians)
    for i = 1, 3 do
      self.textures[i]:SetRotation(radians)
    end
  end,
  --- @type fun(self: CircularProgressTextureInstance, texture: number|string)
  SetTextureOrAtlas = function(self, texture)
    for i = 1, 3 do
      Private.SetTextureOrAtlas(self.textures[i], texture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    end
  end,
  --- @type fun(self: CircularProgressTextureInstance, desaturated: boolean)
  SetDesaturated = function(self, desaturate)
    for i = 1, 3 do
      self.textures[i]:SetDesaturated(desaturate)
    end
  end,
  --- @type fun(self: CircularProgressTextureInstance, blendMode: BlendMode)
  SetBlendMode = function(self, blendMode)
    for i = 1, 3 do
      self.textures[i]:SetBlendMode(blendMode)
    end
  end,
  --- @type fun(self: CircularProgressTextureInstance)
  Show = function(self)
    self.visible = true
    for i = 1, 3 do
      self.textures[i]:Show()
    end
  end,
  --- @type fun(self: CircularProgressTextureInstance)
  Hide = function(self)
    self.visible = false
    for i = 1, 3 do
      self.textures[i]:Hide()
    end
  end,
  --- @type fun(self: CircularProgressTextureInstance, r: number, g: number, b: number, a: number)
  SetColor = function (self, r, g, b, a)
    for i = 1, 3 do
      self.textures[i]:SetVertexColor(r, g, b, a)
    end
  end,
  --- @type fun(self: CircularProgressTextureInstance, crop_x: number)
  SetCropX = function(self, crop_x)
    self.crop_x = crop_x
    self:UpdateTextures()
  end,
  --- @type fun(self: CircularProgressTextureInstance, crop_y: number)
  SetCropY = function(self, crop_y)
    self.crop_y = crop_y
    self:UpdateTextures()
  end,
  --- @type fun(self: CircularProgressTextureInstance, texRotation: number)
  SetTexRotation = function(self, texRotation)
    self.texRotation = texRotation
    self:UpdateTextures()
  end,
  --- @type fun(self: CircularProgressTextureInstance, mirror_h: boolean, mirror_v: boolean)
  SetMirrorHV = function(self, mirror_h, mirror_v)
    self.mirror_h = mirror_h
    self.mirror_v = mirror_v
  end,
  --- @type fun(self: CircularProgressTextureInstance, mirror: boolean)
  SetMirror = function(self, mirror)
    self.mirror = mirror
    self:UpdateTextures()
  end,
  SetWidth = function(self, width)
    self.width = width
  end,
  SetHeight = function(self, height)
    self.height = height
  end,
  SetScale = function(self, scalex, scaley)
    self.scalex, self.scaley = scalex, scaley
  end,
  --- @type fun(self: CircularProgressTextureInstance)
  UpdateTextures = function(self)
    if not self.visible then
      return
    end
    local crop_x = self.crop_x or 1
    local crop_y = self.crop_y or 1
    local texRotation = self.texRotation or 0
    local mirror_h = self.mirror_h or false
    if self.mirror then
      mirror_h = not mirror_h
    end
    local mirror_v = self.mirror_v or false

    local width = self.width * (self.scalex or 1) + 2 * self.offset
    local height = self.height * (self.scaley or 1) + 2 * self.offset

    if width == 0 or height == 0 then
      return
    end

    local angle1 = self.angle1
    local angle2 = self.angle2

    if angle1 == nil or angle2 == nil then
      return
    end

    if (angle2 - angle1 >= 360) then
      -- SHOW everything
      self.coords[1]:SetFull()
      self.coords[1]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
      self.coords[1]:Show()

      self.coords[2]:Hide()
      self.coords[3]:Hide()
      return
    end
    if (angle1 == angle2) then
      self.coords[1]:Hide()
      self.coords[2]:Hide()
      self.coords[3]:Hide()
      return
    end

    local index1 = floor((angle1 + 45) / 90)
    local index2 = floor((angle2 + 45) / 90)

    if (index1 + 1 >= index2) then
      self.coords[1]:SetAngle(width, height, angle1, angle2)
      self.coords[1]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
      self.coords[1]:Show()
      self.coords[2]:Hide()
      self.coords[3]:Hide()
    elseif(index1 + 3 >= index2) then
      local firstEndAngle = (index1 + 1) * 90 + 45
      self.coords[1]:SetAngle(width, height, angle1, firstEndAngle)
      self.coords[1]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
      self.coords[1]:Show()

      self.coords[2]:SetAngle(width, height, firstEndAngle, angle2)
      self.coords[2]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
      self.coords[2]:Show()

      self.coords[3]:Hide()
    else
      local firstEndAngle = (index1 + 1) * 90 + 45
      local secondEndAngle = firstEndAngle + 180

      self.coords[1]:SetAngle(width, height, angle1, firstEndAngle)
      self.coords[1]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
      self.coords[1]:Show()

      self.coords[2]:SetAngle(width, height, firstEndAngle, secondEndAngle)
      self.coords[2]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
      self.coords[2]:Show()

      self.coords[3]:SetAngle(width, height, secondEndAngle, angle2)
      self.coords[3]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
      self.coords[3]:Show()
    end
  end,
  --- @type fun(self: CircularProgressTextureInstance, angle1: number, angle2: number)
  SetProgress = function (self, angle1, angle2)
    self.angle1 = angle1
    self.angle2 = angle2
    self:UpdateTextures()
  end,
}

--- @type fun(frame:Frame) : CircularProgressTextureInstance
function Private.CircularProgressTextureBase.create(frame, layer, drawLayer)
  local circularTexture = {}

  circularTexture.textures = {}
  circularTexture.coords = {}
  circularTexture.offset = 0
  circularTexture.visible = true

  for i = 1, 3 do
    local texture = frame:CreateTexture(nil, layer)
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
    texture:SetDrawLayer(layer, drawLayer)
    texture:SetAllPoints(frame)
    circularTexture.textures[i] = texture

    circularTexture.coords[i] = Private.TextureCoords.create(texture)
  end

  for funcName, func in pairs(funcs) do
    circularTexture[funcName] = func
  end

  circularTexture.parentFrame = frame

  --- @cast circularTexture CircularProgressTextureInstance
  return circularTexture
end

--- @type fun(circularTexture: CircularProgressTextureInstance, options: CircularProgressTextureOptions)
function Private.CircularProgressTextureBase.modify(circularTexture, options)
  circularTexture:SetTextureOrAtlas(options.texture)
  circularTexture:SetDesaturated(options.desaturated)
  circularTexture:SetBlendMode(options.blendMode)
  circularTexture:SetAuraRotation(options.auraRotation)
  circularTexture.crop_x = options.crop_x
  circularTexture.crop_y = options.crop_y
  circularTexture.mirror = options.mirror
  circularTexture.texRotation = options.texRotation
  circularTexture.width = options.width
  circularTexture.height = options.height
  circularTexture.offset = options.offset
  local offset = options.offset
  local frame = circularTexture.parentFrame
  if offset > 0 then
    for i = 1, 3 do
      circularTexture.textures[i]:ClearAllPoints()
      circularTexture.textures[i]:SetPoint('TOPRIGHT', frame, offset, offset)
      circularTexture.textures[i]:SetPoint('BOTTOMRIGHT', frame, offset, -offset)
      circularTexture.textures[i]:SetPoint('BOTTOMLEFT', frame, -offset, -offset)
      circularTexture.textures[i]:SetPoint('TOPLEFT', frame, -offset, offset)
    end
  else
    for i = 1, 3 do
      circularTexture.textures[i]:ClearAllPoints()
      circularTexture.textures[i]:SetAllPoints(frame)
    end
  end

  circularTexture:UpdateTextures()
end
