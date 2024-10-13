if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L

local default = function(parentType)
  local defaults = {
    textureVisible = true,

    textureTexture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura3",
    textureDesaturate = false,
    textureColor = {1, 1, 1, 1},
    textureBlendMode = "BLEND",
    textureMirror = false,
    textureRotate = false,
    textureRotation = 0,

    anchor_mode = "area",
    self_point = "CENTER",
    anchor_point = "CENTER",
    width = 32,
    height = 32,
    scale = 1,
    mirror = false,
    rotate = false,
  }

  if parentType == "aurabar" then
    defaults.anchor_area = "bar"
  else
    defaults.anchor_area = "ALL"
  end

  return defaults
end

local properties = {
  textureVisible = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
  },
  textureDesaturate = {
    display = L["Desaturate"],
    setter = "SetDesaturated",
    type = "bool",
  },
  textureColor = {
    display = L["Color"],
    setter = "SetColor",
    type = "color"
  },
  textureMirror = {
    display = L["Mirror"],
    setter = "SetMirror",
    type = "bool"
  },
  textureRotation = {
    display = L["Rotation"],
    setter = "SetRotation",
    type = "number",
    min = 0,
    max = 360,
    bigStep = 1,
    default = 0
  }
}

local funcs = {
  SetDesaturated = function(self, b)
    self.texture:SetDesaturated(b)
  end,
  SetColor = function(self, ...)
    self.texture:SetVertexColor(...)
  end,
  SetMirror = function(self, b)
    self.texture:SetMirror(b)
  end,
  SetRotation = function(self, rotation)
    self.texture:SetRotation(rotation)
  end,
  SetVisible = function(self, visible)
    self.visible = visible
    if visible then
      self:Show()
    else
      self:Hide()
    end
  end
}

local function create()
  local region = CreateFrame("Frame", nil, UIParent)
  region:SetFlattensRenderLayers(true)

  for k, v in pairs(funcs) do
    region[k] = v
  end

  region.texture = Private.TextureBase.create(region)
  region.texture:ClearAllPoints()
  region.texture:SetAllPoints(region)

  return region
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion:Hide()
end

local function modify(parent, region, parentData, data, first)
  region.parent = parent
  region:SetParent(parent)
  region.scale = data.scale or 1

  local arg1 = data.anchor_mode == "point" and data.anchor_point or data.anchor_area
  local arg2 = data.anchor_mode == "point" and data.self_point or nil

  if data.anchor_mode == "point" then
    region:SetSize(data.width or 0, data.height or 0)
  end

  region.Anchor = function()
    region:ClearAllPoints()
    parent:AnchorSubRegion(region, data.anchor_mode, arg1, arg2, data.xOffset, data.yOffset)
  end

  Private.TextureBase.modify(region.texture, {
    canRotate = data.textureRotate,
    desaturate = data.textureDesaturate,
    blendMode = data.textureBlendMode,
    mirror = data.textureMirror,
    rotation = data.textureRotation,
    textureWrapMode = "CLAMPTOBLACKADDITIVE"
  })

  region:SetVisible(data.textureVisible)
  region:SetDesaturated(data.textureDesaturate)
  region:SetColor(data.textureColor[1], data.textureColor[2], data.textureColor[3], data.textureColor[4])
  region.texture:SetTexture(data.textureTexture)
end

local function supports(regionType)
  return regionType == "texture"
         or regionType == "progresstexture"
         or regionType == "icon"
         or regionType == "aurabar"
         or regionType == "text"
         or regionType == "empty"
end

WeakAuras.RegisterSubRegionType("subtexture", L["Texture"], supports, create, modify, onAcquire, onRelease, default, nil, properties)
