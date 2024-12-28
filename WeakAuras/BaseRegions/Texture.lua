if not WeakAuras.IsLibsOK() then return end

---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L

--- @class TextureBase
Private.TextureBase = {}

--- @class TextureBaseInstance
--- @field texture Texture
--- @field mirror_h boolean
--- @field mirror_v boolean
--- @field mirror boolean
--- @field rotation number
--- @field effectiveRotation number
--- @field canRotate boolean
--- @field textureWrapMode WrapMode

--- @class TextureBaseOptions
--- @field canRotate boolean
--- @field mirror boolean
--- @field rotation number
--- @field textureWrapMode WrapMode

local SQRT2 = sqrt(2)
local function GetRotatedPoints(degrees, scaleForFullRotate)
  local angle = rad(135 - degrees)
  local factor = scaleForFullRotate and 1 or SQRT2
  local vx = math.cos(angle) / factor
  local vy = math.sin(angle) / factor

  return 0.5+vx,0.5-vy , 0.5-vy,0.5-vx , 0.5+vy,0.5+vx , 0.5-vx,0.5+vy
end

local GetAtlasInfo = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo

function Private.TextureBase:IsAtlas(input)
  return type(input) == "string" and GetAtlasInfo(input) ~= nil
end

local funcs = {
  --- @class TextureBaseInstance
  --- @field ClearAllPoints fun(self: TextureBaseInstance)
  ClearAllPoints = function(self)
    self.texture:ClearAllPoints()
  end,

  --- @class TextureBaseInstance
  --- @field SetAllPoints fun(self: TextureBaseInstance, ... : any)
  SetAllPoints = function(self, ...)
    self.texture:SetAllPoints(...)
  end,

  --- @class TextureBaseInstance
  --- @field DoTexCoord fun(self: TextureBaseInstance)
  DoTexCoord = function(self)
    local mirror_h, mirror_v = self.mirror_h, self.mirror_v
    if(self.mirror) then
      mirror_h = not mirror_h
    end
    local ulx,uly , llx,lly , urx,ury , lrx,lry
      = GetRotatedPoints(self.effectiveRotation, self.canRotate and not self.texture.IsAtlas)
    if(mirror_h) then
      if(mirror_v) then
        self.texture:SetTexCoord(lrx,lry , urx,ury , llx,lly , ulx,uly)
      else
        self.texture:SetTexCoord(urx,ury , lrx,lry , ulx,uly , llx,lly)
      end
    else
      if(mirror_v) then
        self.texture:SetTexCoord(llx,lly , ulx,uly , lrx,lry , urx,ury)
      else
        self.texture:SetTexCoord(ulx,uly , llx,lly , urx,ury , lrx,lry)
      end
    end
  end,

  --- @class TextureBaseInstance
  --- @field SetMirrorFromScale fun(self: TextureBaseInstance, h: boolean, v: boolean)
  SetMirrorFromScale = function(self, h, v)
    if self.mirror_h == h and self.mirror_v == v then
      return
    end
    self.mirror_h = h
    self.mirror_v = v
    self:DoTexCoord()
  end,

  --- @class TextureBaseInstance
  --- @field SetMirror fun(self: TextureBaseInstance, b: boolean)
  SetMirror = function(self, b)
    if self.mirror == b then
      return
    end
    self.mirror = b
    self:DoTexCoord()
  end,

  --- @class TextureBaseInstance
  --- @field SetTexture fun(self: TextureBaseInstance, file: number|string)
  SetTexture = function(self, file)
    self.textureName = file
    local oldIsAtlas = self.texture.IsAtlas
    Private.SetTextureOrAtlas(self.texture, self.textureName, self.textureWrapMode, self.textureWrapMode)
    if self.texture.IsAtlas ~= oldIsAtlas then
      self:DoTexCoord()
    end
  end,

  --- @class TextureBaseInstance
  --- @field SetColor fun(self: TextureBaseInstance, r: number, g: number, b: number, a: number)
  SetVertexColor = function(self, r, g, b, a)
    self.texture:SetVertexColor(r, g, b,a)
  end,

  --- @class TextureBaseInstance
  --- @field SetDesaturated fun(self: TextureBaseInstance, b: boolean)
  SetDesaturated = function(self, b)
    self.texture:SetDesaturated(b)
  end,

  --- @class TextureBaseInstance
  --- @field SetAnimRotation fun(self: TextureBaseInstance, degrees: number?)
  SetAnimRotation = function(self, degrees)
    self.animRotation = degrees
    self:UpdateEffectiveRotation()
  end,

  --- @class TextureBaseInstance
  --- @field SetRotation fun(self: TextureBaseInstance, degrees: number)
  SetRotation = function(self, degrees)
    self.rotation = degrees
    self:UpdateEffectiveRotation()
  end,

  --- @class TextureBaseInstance
  --- @field UpdateEffectiveRotation fun(self: TextureBaseInstance)
  UpdateEffectiveRotation = function(self)
    self.effectiveRotation = self.animRotation or self.rotation
    self:DoTexCoord()
  end,

  --- @class TextureBaseInstance
  --- @field GetBaseRotation fun(self: TextureBaseInstance): number
  GetBaseRotation = function(self)
    return self.rotation
  end
}

--- @type fun(frame: Frame) : TextureBaseInstance
function Private.TextureBase.create(frame)
    local base = {}

    for funcName, func in pairs(funcs) do
      base[funcName] = func
    end

    local texture = frame:CreateTexture()
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)

    base.texture = texture

    --- @cast base TextureBaseInstance
    return base
end

--- @type fun(base: TextureBaseInstance, options: TextureBaseOptions)
function Private.TextureBase.modify(base, options)
  base.canRotate = options.canRotate
  base.mirror = options.mirror
  base.rotation = options.rotation
  base.effectiveRotation = base.rotation
  base.textureWrapMode = options.textureWrapMode

  base.texture:SetDesaturated(options.desaturate)
  base.texture:SetBlendMode(options.blendMode)
  base:DoTexCoord()
end
