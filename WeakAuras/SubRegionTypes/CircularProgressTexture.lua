if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L

local default = function(parentType)
  local defaults = {
    circularTextureVisible = true,

    circularTextureTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\square_border_5px.tga",
    circularTextureDesaturate = false,
    circularTextureColor = {1, 1, 1, 1},
    circularTextureBlendMode = "BLEND",
    circularTextureStartAngle = 0,
    circularTextureEndAngle = 360,
    circularTextureClockwise = true,

    circularTextureCrop_x = 0.41,
    circularTextureCrop_y = 0.41,
    circularTextureRotation = 0, -- Uses tex coord rotation, called "legacy rotation" in the ui and texRotation in code everywhere else
    circularTextureAuraRotation = 0, -- Uses texture:SetRotation
    circularTextureMirror = false,

    anchor_mode = "area",
    self_point = "CENTER",
    anchor_point = "CENTER",
    width = 32,
    height = 32,
    scale = 1,

    progressSource = {-2, ""},
  }

  if parentType == "aurabar" then
    defaults.anchor_area = "bar"
  else
    defaults.anchor_area = "ALL"
  end

  return defaults
end

local properties = {
  circularTextureVisible = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
  },
  circularTextureDesaturate = {
    display = L["Desaturate"],
    setter = "SetDesaturated",
    type = "bool",
  },
  circularTextureInverse = {
    display = L["Inverse"],
    setter = "SetInverse",
    type = "bool",
  },
  circularTextureColor = {
    display = L["Color"],
    setter = "SetColor",
    type = "color"
  },
  circularTextureClockwise = {
    display = L["Clockwise"],
    setter = "SetClockwise",
    type = "bool",
  },
  circularTextureAuraRotation = {
    display = L["Rotation"],
    setter = "SetAuraRotation",
    type = "number",
    min = 0,
    max = 360,
    bigStep = 10,
    default = 0
  },
  circularTextureMirror = {
    display = L["Mirror"],
    setter = "SetMirror",
    type = "bool",
  },
  circularTextureCrop_x = {
    display = L["Crop X"],
    setter = "SetCropX",
    type = "number",
    min = 0,
    softMax = 2,
    bigStep = 0.01,
    isPercent = true,
  },
  circularTextureCrop_y = {
    display = L["Crop Y"],
    setter = "SetCropY",
    type = "number",
    min = 0,
    softMax = 2,
    bigStep = 0.01,
    isPercent = true,
  },
}

--- @class CircularProgressSubElement
--- @field circularTexture CircularProgressTextureInstance
--- @field startAngle number
--- @field endAngle number
--- @field visible boolean
--- @field ProgressToAngles fun(self: CircularProgressSubElement, progress: number): number, number
--- @field FrameTick fun(self: CircularProgressSubElement)?

--- @class CircularProgressTextureInstance
local funcs = {
  --- @type fun(self: CircularProgressSubElement, b: boolean)
  SetDesaturated = function(self, b)
    self.circularTexture:SetDesaturated(b)
  end,
  --- @type fun(self: CircularProgressSubElement, ...: any)
  SetColor = function(self, ...)
    self.circularTexture:SetColor(...)
  end,
  --- @type fun(self: CircularProgressSubElement, b: boolean)
  SetVisible = function(self, b)
    self.visible = b
    if b then
      self.circularTexture:Show()
      self:UpdateFrame()
    else
      self.circularTexture:Hide()
    end
    self:UpdateFrameTick()
  end,
  --- @type fun(self: CircularProgressSubElement, radians: number)
  SetAuraRotation = function(self, degrees)
    self.circularTexture:SetAuraRotation(degrees / 180 * math.pi)
  end,
  --- @type fun(self: CircularProgressSubElement, b: boolean)
  SetMirror = function(self, b)
    self.circularTexture:SetMirror(b)
  end,
  --- @type fun(self: CircularProgressSubElement, cropX: number)
  SetCropX = function(self, cropX)
    self.circularTexture:SetCropX(1 + cropX)
  end,
  --- @type fun(self: CircularProgressSubElement, cropY: number)
  SetCropY = function(self, cropY)
    self.circularTexture:SetCropY(1 + cropY)
  end,
  --- @type fun(self: CircularProgressSubElement)
  UpdateFrameTick = function(self)
    if self.visible and self.progressData.progressType == "timed" and not self.progressData.paused then
      if not self.FrameTick then
        self.FrameTick = self.UpdateFrame

        self.parent.subRegionEvents:AddSubscriber("FrameTick", self)
      end
    else
      if self.FrameTick then
        self.FrameTick = nil
        self.parent.subRegionEvents:RemoveSubscriber("FrameTick", self)
      end
    end
  end,
  --- @type fun(self: CircularProgressSubElement, startAngle: number, endAngle: number)
  SetAngles = function(self, startAngle, endAngle)
    self.startAngle = startAngle
    self.endAngle = endAngle
  end,
  --- @type fun(self: CircularProgressSubElement, progress: number): number, number
  ProgressToAnglesClockwise = function(self, progress)
    progress = Clamp(progress, 0, 1)
    local pAngle = (self.endAngle - self.startAngle) * progress + self.startAngle
    return self.startAngle, pAngle
  end,
  --- @type fun(self: CircularProgressSubElement, progress: number): number, number
  ProgressToAnglesAntiClockwise = function(self, progress)
    progress = Clamp(progress, 0, 1)
    progress = 1 - progress
    local pAngle = (self.endAngle - self.startAngle) * progress + self.startAngle
    return pAngle, self.endAngle
  end,
  --- @type fun(self: CircularProgressSubElement, b: boolean)
  SetClockwise = function(self, b)
    if b then
      self.ProgressToAngles = self.ProgressToAnglesClockwise
    else
      self.ProgressToAngles = self.ProgressToAnglesAntiClockwise
    end
    self:UpdateFrame()
  end,
  --- @type fun(self: CircularProgressSubElement)
  UpdateFrame = function(self)
    if self.visible then
      local progressData = self.progressData
      if progressData.progressType == "static" then
        local progress = 0
        if progressData.total ~= 0 then
          progress = progressData.value / progressData.total
        end
        if self.inverse then
          progress = 1 - progress
        end
        self.circularTexture:SetProgress(self:ProgressToAngles(progress))
      elseif progressData.progressType == "timed" then
        if progressData.paused then
          local remaining = self.progressData.remaining
          local progress = remaining / self.progressData.duration
          if self.inverse then
            progress = 1 - progress
          end
          self.circularTexture:SetProgress(self:ProgressToAngles(progress))
        else
          local remaining = self.progressData.expirationTime - GetTime()
          local progress = remaining / self.progressData.duration
          if self.inverse then
            progress = 1 - progress
          end
          self.circularTexture:SetProgress(self:ProgressToAngles(progress))
        end
      end
    end
  end,
  Update = function(self, state, states)
    Private.UpdateProgressFrom(self.progressData, self.progressSource, self, state, states, self.parent)
    self:UpdateFrame()
    self:UpdateFrameTick()
  end,
  OnSizeChanged = function(self)
    local w, h = self:GetSize()
    self.circularTexture:SetWidth(w)
    self.circularTexture:SetHeight(h)
    self.circularTexture:UpdateTextures()
  end,
  SetInverse = function(self, inverse)
    self.inverse = inverse
    self:UpdateFrame()
  end
}

local function create()
  local region = CreateFrame("Frame", nil, UIParent)
  region:SetFlattensRenderLayers(true)

  for k, v in pairs(funcs) do
    region[k] = v
  end

  region.circularTexture = Private.CircularProgressTextureBase.create(region, "ARTWORK", 1)
  region.progressData = {}
  region:SetScript("OnSizeChanged", region.OnSizeChanged)

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
  region.Anchor = nil

  local arg1 = data.anchor_mode == "point" and data.anchor_point or data.anchor_area
  local arg2 = data.anchor_mode == "point" and data.self_point or nil

  if data.anchor_mode == "point" then
    region:SetSize(data.width or 0, data.height or 0)
  end


  region.Anchor = function()
    region:ClearAllPoints()
    parent:AnchorSubRegion(region, data.anchor_mode, arg1, arg2, data.xOffset, data.yOffset)
    region:OnSizeChanged()
  end

  region.inverse = data.circularTextureInverse

  Private.CircularProgressTextureBase.modify(region.circularTexture, {
    crop_x = 1 + data.circularTextureCrop_x,
    crop_y = 1 + data.circularTextureCrop_y,
    texRotation = data.circularTextureRotation,
    auraRotation = data.circularTextureAuraRotation / 180 * math.pi,
    mirror = data.circularTextureMirror,
    desaturated = data.circularTextureDesaturate,
    blendMode = data.circularTextureBlendMode,
    texture = data.circularTextureTexture,
    -- width and height will be set via the anchoring function
    width = 0,
    height = 0,
    offset = 0
  })

  Private.regionPrototype.AddMinMaxProgressSource(true, region, parentData, data)

  region.FrameTick = nil
  parent.subRegionEvents:AddSubscriber("Update", region)

  region:SetVisible(data.circularTextureVisible)
  region:SetAngles(data.circularTextureStartAngle, data.circularTextureEndAngle)
  region:SetClockwise(data.circularTextureClockwise)
  region:SetColor(data.circularTextureColor[1], data.circularTextureColor[2],
                  data.circularTextureColor[3], data.circularTextureColor[4])
end

local function supports(regionType)
  return regionType == "texture"
         or regionType == "progresstexture"
         or regionType == "icon"
         or regionType == "aurabar"
         or regionType == "text"
         or regionType == "empty"
end

WeakAuras.RegisterSubRegionType("subcirculartexture", L["Circular Texture"], supports, create, modify, onAcquire, onRelease,
                                default, nil, properties)
