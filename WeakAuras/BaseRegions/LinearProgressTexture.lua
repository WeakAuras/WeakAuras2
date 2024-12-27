if not WeakAuras.IsLibsOK() then return end

---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L

--- @class LinearProgressTextureBase
Private.LinearProgressTextureBase = {}

--- @alias SlantMode "INSIDE"|"EXTEND"
--- @alias LinearProgressTextureOrientation "HORIZONTAL"|"HORIZONTAL_INVERSE"|"VERTICAL"|"VERTICAL_INVERSE"

--- @class LinearProgressTextureInstance
--- @field crop_x number
--- @field crop_y number
--- @field user_x number
--- @field user_y number
--- @field mirror boolean
--- @field mirror_h boolean
--- @field mirror_v boolean
--- @field texRotation number
--- @field visible boolean
--- @field offset number
--- @field width number
--- @field height number
--- @field compress boolean
--- @field slanted boolean
--- @field slant number
--- @field slantMode SlantMode
--- @field slantFirst boolean
--- @field horizontal boolean?
--- @field ApplyProgressToCoord fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
--- @field startProgress number
--- @field endProgress number
--- @field coord TextureCoords

--- @class LinearProgressTextureOptions
--- @field texture number|string
--- @field desaturated boolean
--- @field blendMode BlendMode
--- @field auraRotation number
--- @field textureWrapMode WrapMode
--- @field offset number
--- @field crop_x number
--- @field crop_y number
--- @field user_x number
--- @field user_y number
--- @field mirror boolean
--- @field texRotation number
--- @field width number
--- @field height number


--- @type table<LinearProgressTextureOrientation, "LEFT"|"RIGHT"|"TOP"|"BOTTOM">
local orientationToAnchorPoint = {
  ["HORIZONTAL"] = "LEFT",
  ["HORIZONTAL_INVERSE"] = "RIGHT",
  ["VERTICAL"] = "BOTTOM",
  ["VERTICAL_INVERSE"] = "TOP"
}


--- @class LinearProgressTextureInstance
local funcs = {
  --- @type table<LinearProgressTextureOrientation, fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)>
  ApplyProgressToCoordFunctions = {
    --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
    ["HORIZONTAL"] = function(self, startProgress, endProgress)
      self.coord:MoveCorner(self.width, self.height, "UL", startProgress, 0 )
      self.coord:MoveCorner(self.width, self.height, "LL", startProgress, 1 )

      self.coord:MoveCorner(self.width, self.height, "UR", endProgress, 0 )
      self.coord:MoveCorner(self.width, self.height, "LR", endProgress, 1 )
    end,
    --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
    ["HORIZONTAL_INVERSE"] = function(self, startProgress, endProgress)
      self.coord:MoveCorner(self.width, self.height, "UL", 1 - endProgress, 0 )
      self.coord:MoveCorner(self.width, self.height, "LL", 1 - endProgress, 1 )

      self.coord:MoveCorner(self.width, self.height, "UR", 1 - startProgress, 0 )
      self.coord:MoveCorner(self.width, self.height, "LR", 1 - startProgress, 1 )
    end,
    --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
    ["VERTICAL"] = function(self, startProgress, endProgress)
      self.coord:MoveCorner(self.width, self.height, "UL", 0, 1 - endProgress )
      self.coord:MoveCorner(self.width, self.height, "UR", 1, 1 - endProgress )

      self.coord:MoveCorner(self.width, self.height, "LL", 0, 1 - startProgress )
      self.coord:MoveCorner(self.width, self.height, "LR", 1, 1 - startProgress )
    end,
    --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
    ["VERTICAL_INVERSE"] = function(self, startProgress, endProgress)
      self.coord:MoveCorner(self.width, self.height, "UL", 0, startProgress )
      self.coord:MoveCorner(self.width, self.height, "UR", 1, startProgress )

      self.coord:MoveCorner(self.width, self.height, "LL", 0, endProgress )
      self.coord:MoveCorner(self.width, self.height, "LR", 1, endProgress )
    end,
  },

  --- @type table<LinearProgressTextureOrientation, fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)>
  ApplyProgressToCoordFunctionsSlanted = {
    --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
    ["HORIZONTAL"] = function(self, startProgress, endProgress)
      local slant = self.slant or 0
      if (self.slantMode == "EXTEND") then
        startProgress = startProgress * (1 + slant) - slant
        endProgress = endProgress * (1 + slant) - slant
      else
        startProgress = startProgress * (1 - slant)
        endProgress = endProgress * (1 -  slant)
      end

      local slant1 = self.slantFirst and 0 or slant
      local slant2 = self.slantFirst and slant or 0

      self.coord:MoveCorner(self.width, self.height, "UL", startProgress + slant1, 0 )
      self.coord:MoveCorner(self.width, self.height, "LL", startProgress + slant2, 1 )

      self.coord:MoveCorner(self.width, self.height, "UR", endProgress + slant1, 0 )
      self.coord:MoveCorner(self.width, self.height, "LR", endProgress + slant2, 1 )
    end,
    --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
    ["HORIZONTAL_INVERSE"] = function(self, startProgress, endProgress)
      local slant = self.slant or 0
      if (self.slantMode == "EXTEND") then
        startProgress = startProgress * (1 + slant) - slant
        endProgress = endProgress * (1 + slant) - slant
      else
        startProgress = startProgress * (1 - slant)
        endProgress = endProgress * (1 -  slant)
      end

      local slant1 = self.slantFirst and slant or 0
      local slant2 = self.slantFirst and 0 or slant

      self.coord:MoveCorner(self.width, self.height, "UL", 1 - endProgress - slant1, 0 )
      self.coord:MoveCorner(self.width, self.height, "LL", 1 - endProgress - slant2, 1 )

      self.coord:MoveCorner(self.width, self.height, "UR", 1 - startProgress - slant1, 0 )
      self.coord:MoveCorner(self.width, self.height, "LR", 1 - startProgress - slant2, 1 )
    end,
    --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
    ["VERTICAL"] = function(self, startProgress, endProgress)
      local slant = self.slant or 0
      if (self.slantMode == "EXTEND") then
        startProgress = startProgress * (1 + slant) - slant
        endProgress = endProgress * (1 + slant) - slant
      else
        startProgress = startProgress * (1 - slant)
        endProgress = endProgress * (1 -  slant)
      end

      local slant1 = self.slantFirst and slant or 0
      local slant2 = self.slantFirst and 0 or slant

      self.coord:MoveCorner(self.width, self.height, "UL", 0, 1 - endProgress - slant1 )
      self.coord:MoveCorner(self.width, self.height, "UR", 1, 1 - endProgress - slant2 )

      self.coord:MoveCorner(self.width, self.height, "LL", 0, 1 - startProgress - slant1 )
      self.coord:MoveCorner(self.width, self.height, "LR", 1, 1 - startProgress - slant2 )
    end,
    --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)
    ["VERTICAL_INVERSE"] = function(self, startProgress, endProgress)
      local slant = self.slant or 0
      if (self.slantMode == "EXTEND") then
        startProgress = startProgress * (1 + slant) - slant
        endProgress = endProgress * (1 + slant) - slant
      else
        startProgress = startProgress * (1 - slant)
        endProgress = endProgress * (1 -  slant)
      end

      local slant1 = self.slantFirst and 0 or slant
      local slant2 = self.slantFirst and slant or 0

      self.coord:MoveCorner(self.width, self.height, "UL", 0, startProgress + slant1 )
      self.coord:MoveCorner(self.width, self.height, "UR", 1, startProgress + slant2 )

      self.coord:MoveCorner(self.width, self.height, "LL", 0, endProgress + slant1 )
      self.coord:MoveCorner(self.width, self.height, "LR", 1, endProgress + slant2 )
    end,
  },


  --- @type fun(self: LinearProgressTextureInstance, orientation: LinearProgressTextureOrientation, slanted: boolean, slant: number, slantFirst: number, slantMode: SlantMode)
  SetOrientation = function(self, orientation, compress, slanted, slant, slantFirst, slantMode)
    self.ApplyProgressToCoord = slanted and self.ApplyProgressToCoordFunctionsSlanted[orientation]
                                or self.ApplyProgressToCoordFunctions[orientation]
    self.compress = compress
    self.slanted = slanted
    self.slant = slant
    self.slantFirst = slantFirst
    self.slantMode = slantMode
    if (self.compress) then
      self.texture:ClearAllPoints()
      local anchor = orientationToAnchorPoint[orientation]
      self.texture:SetPoint(anchor, self.parentFrame, anchor)
      self.horizontal = orientation == "HORIZONTAL" or orientation == "HORIZONTAL_INVERSE"
    else
      local offset = self.offset or 0
      self.texture:ClearAllPoints()
      self.texture:SetPoint("BOTTOMLEFT", self.parentFrame, "BOTTOMLEFT", -1 * offset, -1 * offset)
      self.texture:SetPoint("TOPRIGHT", self.parentFrame, "TOPRIGHT", offset, offset)
    end
    self:Update()
  end,

  --- @type fun(self: LinearProgressTextureInstance, startProgress: number, endProgress: number)--- @
  SetValue = function(self, startProgress, endProgress)
    startProgress = Clamp(startProgress, 0, 1)
    endProgress = Clamp(endProgress, 0, 1)
    self.startProgress = startProgress
    self.endProgress = endProgress

    if (self.compress) then
      -- Somewhat questionable usage of parentFrame.progress
      local progress = self.parentFrame.progress or 1
      local horScale = self.horizontal and progress or 1
      local verScale = self.horizontal and 1 or progress
      self:SetWidth(self.width * horScale)
      self:SetHeight(self.height * verScale)

      if (progress > 0.1) then
        startProgress = startProgress / progress
        endProgress = endProgress / progress
      else
        startProgress, endProgress = 0, 0
      end
    end
    self:UpdateTextures()
  end,

  --- @type fun(self: LinearProgressTextureInstance, crop_x: number)
  SetCropX = function(self, crop_x)
    self.crop_x = crop_x
    self:UpdateTextures()
  end,
  --- @type fun(self: LinearProgressTextureInstance, crop_y: number)
  SetCropY = function(self, crop_y)
    self.crop_y = crop_y
    self:UpdateTextures()
  end,
  --- @type fun(self: LinearProgressTextureInstance, mirror: boolean)
  SetMirror = function(self, mirror)
    self.mirror = mirror
    self:UpdateTextures()
  end,

  --- @type fun(self: LinearProgressTextureInstance, mirror_h: boolean, mirror_v: boolean)
  SetMirrorHV = function(self, mirror_h, mirror_v)
    self.mirror_h = mirror_h
    self.mirror_v = mirror_v
  end,


  --- @type fun(self: LinearProgressTextureInstance, texRotation: number)
  SetTexRotation = function(self, texRotation)
    self.texRotation = texRotation
    self:UpdateTextures()
  end,

  --- @type fun(self: LinearProgressTextureInstance)
  UpdateTextures = function(self)
    if not self.visible or not self.ApplyProgressToCoord then
      return
    end
    self.coord:SetFull()
    self:ApplyProgressToCoord(self.startProgress, self.endProgress)
    local crop_x = self.crop_x or 1
    local crop_y = self.crop_y or 1
    local texRotation = self.texRotation or 0
    local mirror_h = self.mirror_h or false
    if self.mirror then
      mirror_h = not mirror_h
    end
    local mirror_v = self.mirror_v or false
    local user_x = self.user_x
    local user_y = self.user_y

    self.coord:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v, user_x, user_y)
    self.coord:Apply()
  end,

  Update = function(self)
    self:SetValue(self.startProgress, self.endProgress)
  end,

  --- @type fun(self: LinearProgressTextureInstance)
  Show = function(self)
    self.visible = true
    self.texture:Show()
  end,
  --- @type fun(self: LinearProgressTextureInstance)
  Hide = function(self)
    self.visible = false
    self.texture:Hide()
  end,

  --- @type fun(self: LinearProgressTextureInstance, r: number, g: number, b: number, a: number)
  SetColor = function (self, r, g, b, a)
    self.texture:SetVertexColor(r, g, b, a)
  end,

  --- @type fun(self: LinearProgressTextureInstance): BlendMode
  GetBlendMode = function(self)
    return self.texture:GetBlendMode()
  end,

  --- @type fun(self: LinearProgressTextureInstance, radians: number)
  SetAuraRotation = function (self, radians)
    self.texture:SetRotation(radians)
  end,

  --- @type fun(self: LinearProgressTextureInstance, texture: number|string, textureWrapMode: WrapMode)
  SetTextureOrAtlas = function(self, texture, textureWrapMode)
    Private.SetTextureOrAtlas(self.texture, texture, textureWrapMode, textureWrapMode)
  end,

  --- @type fun(self: LinearProgressTextureInstance, desaturated: boolean)
  SetDesaturated = function(self, desaturate)
    self.texture:SetDesaturated(desaturate)
  end,
  --- @type fun(self: LinearProgressTextureInstance, blendMode: BlendMode)
  SetBlendMode = function(self, blendMode)
    self.texture:SetBlendMode(blendMode)
  end,

  --- @type fun(self: LinearProgressTextureInstance, width: number)
  SetWidth = function(self, width)
    self.width = width
  end,

  --- @type fun(self: LinearProgressTextureInstance, height: number)
  SetHeight = function(self, height)
    self.height = height
  end,
}

--- @type fun(frame:Frame) : LinearProgressTextureInstance
function Private.LinearProgressTextureBase.create(frame, layer, drawLayer)
  local linearTexture = {}
  linearTexture.coords = {}
  linearTexture.visible = true
  linearTexture.parentFrame = frame
  linearTexture.startProgress = 0
  linearTexture.endProgress = 1

  local texture = frame:CreateTexture(nil, layer)
  texture:SetSnapToPixelGrid(false)
  texture:SetTexelSnappingBias(0)
  texture:SetDrawLayer(layer, drawLayer)
  linearTexture.texture = texture
  linearTexture.coord  = Private.TextureCoords.create(texture)

  for funcName, func in pairs(funcs) do
    linearTexture[funcName] = func
  end

  --- @cast linearTexture LinearProgressTextureInstance
  return linearTexture
end

--- @type fun(linearTexture: LinearProgressTextureInstance, options: LinearProgressTextureOptions)
function Private.LinearProgressTextureBase.modify(linearTexture, options)
  linearTexture:SetTextureOrAtlas(options.texture, options.textureWrapMode)
  linearTexture:SetDesaturated(options.desaturated)
  linearTexture:SetBlendMode(options.blendMode)
  linearTexture:SetAuraRotation(options.auraRotation)
  linearTexture.crop_x = options.crop_x
  linearTexture.crop_y = options.crop_y
  linearTexture.user_x = options.user_x
  linearTexture.user_y = options.user_y
  linearTexture.mirror = options.mirror
  linearTexture.texRotation = options.texRotation
  linearTexture.width = options.width
  linearTexture.height = options.height
  linearTexture.offset = options.offset
  linearTexture:UpdateTextures()
end
