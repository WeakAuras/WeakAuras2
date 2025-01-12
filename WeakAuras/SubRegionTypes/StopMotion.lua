if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L

local default = function(parentType)
  local defaults = {
    stopmotionVisible = true,
    barModelClip = true,

    stopmotionTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion",
    stopmotionDesaturate = false,
    stopmotionColor = {1, 1, 1, 1},
    stopmotionBlendMode = "BLEND",
    startPercent = 0,
    endPercent = 1,

    frameRate = 15,
    animationType = "loop",
    inverse = false,
    customFrames = 0,
    customRows = 16,
    customColumns = 16,
    customFileWidth = 0,
    customFileHeight = 0,
    customFrameWidth = 0,
    customFrameHeight = 0,

    anchor_mode = "area",
    self_point = "CENTER",
    anchor_point = "CENTER",
    width = 32,
    height = 32,
    scale = 1,

    progressSource = {-2, ""},
  }

  if C_AddOns.IsAddOnLoaded("WeakAurasStopMotion") then
    defaults.stopmotionTexture = "Interface\\AddOns\\WeakAurasStopMotion\\Textures\\IconOverlays\\ArcReactor"
    defaults.frameRate = 30
    defaults.scale = 3
  end

  if parentType == "aurabar" then
    defaults.anchor_area = "bar"
  else
    defaults.anchor_area = "ALL"
  end

  return defaults
end


local properties = {
  stopmotionVisible = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
  },
  stopmotionDesaturate = {
    display = L["Desaturate"],
    setter = "SetDesaturated",
    type = "bool",
  },
  stopmotionColor = {
    display = L["Color"],
    setter = "SetColor",
    type = "color"
  },
}

local funcs = {
  OnSizeChanged = function(self)
    local w, h = self:GetSize()
    self.stopMotion:SetSize(w * self.scale, h * self.scale)
  end,
  SetDesaturated = function(self, b)
    self.stopMotion:SetDesaturated(b)
  end,
  SetColor = function(self, ...)
    self.stopMotion:SetColor(...)
  end,

}

local TimedFuncs = {
  SetVisible = function(self, visible)
    self.visible = visible
    if visible then
      self:Show()
      self.stopMotion:SetStartTime(GetTime())
      self.FrameTick = function()
        self.stopMotion:TimedUpdate()
      end
      self.parent.subRegionEvents:AddSubscriber("FrameTick", self)
    else
      self:Hide()
      self.FrameTick = nil
      self.parent.subRegionEvents:RemoveSubscriber("FrameTick", self)
    end
  end,
  Update = function(self) end,
}

local ProgressFuncs = {
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
  SetVisible = function(self, visible)
    self.visible = visible
    if visible then
      self:Show()
    else
      self:Hide()
    end
    self:UpdateFrame()
    self:UpdateFrameTick()
  end,
  UpdateFrame = function(self)
    if self.visible then
      local progressData = self.progressData
      if progressData.progressType == "static" then
        local progress = 0
        if progressData.total ~= 0 then
          progress = progressData.value / progressData.total
        end
        self.stopMotion:SetProgress(progress)
      elseif progressData.progressType == "timed" then
        if progressData.paused then
          local remaining = self.progressData.remaining
          local progress = 1 - (remaining / self.progressData.duration)
          self.stopMotion:SetProgress(progress)
        else
          local remaining = self.progressData.expirationTime - GetTime()
          local progress = 1 - (remaining / self.progressData.duration)
          self.stopMotion:SetProgress(progress)
        end
      end
    end
  end,
  Update = function(self, state, states)
    Private.UpdateProgressFrom(self.progressData, self.progressSource, self, state, states, self.parent)
    self:UpdateFrame()
    self:UpdateFrameTick()
  end,
}

local function create()
  local region = CreateFrame("Frame", nil, UIParent)
  region:SetFlattensRenderLayers(true)

  for k, v in pairs(funcs) do
    region[k] = v
  end

  region.stopMotion = Private.StopMotionBase.create(region, "ARTWORK")
  region.progressData = {}

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

  if parentData.regionType == "aurabar"
    and data.anchor_mode == "area"
    and data.anchor_area == "fg"
    and data.barModelClip
  then
    -- Special anchoring for clipping !
    region:SetClipsChildren(true)
    region:SetScript("OnSizeChanged", nil)
    region:ClearAllPoints()
    region:SetAllPoints(parent.bar.fgMask)
    region.stopMotion:ClearAllPoints()
    region.stopMotion:SetAllPoints(region.parent.bar)
  else
    region:SetClipsChildren(false)
    local arg1 = data.anchor_mode == "point" and data.anchor_point or data.anchor_area
    local arg2 = data.anchor_mode == "point" and data.self_point or nil

    if data.anchor_mode == "area" and data.scale ~= 1 then
      -- Extra Scale mode
      region.stopMotion:ClearAllPoints()
      region.stopMotion:SetPoint("CENTER", region, "CENTER")
      region:SetScript("OnSizeChanged", region.OnSizeChanged)
      region:OnSizeChanged()
    else
      if data.anchor_mode == "point" then
        region:SetSize(data.width or 0, data.height or 0)
      end
      region.stopMotion:ClearAllPoints()
      region.stopMotion:SetAllPoints(region)
      region:SetScript("OnSizeChanged", nil)
    end

    region.Anchor = function()
      region:ClearAllPoints()
      parent:AnchorSubRegion(region, data.anchor_mode, arg1, arg2, data.xOffset, data.yOffset)
      if data.anchor_mode == "area" and data.scale ~= 1 then
        region:OnSizeChanged()
      end
    end
  end

  Private.StopMotionBase.modify(region.stopMotion, {
    blendMode = data.stopmotionBlendMode,
    frameRate = data.frameRate,
    inverseDirection = data.inverse,
    animationType = data.animationType,
    texture = data.stopmotionTexture,
    startPercent = data.startPercent,
    endPercent = data.endPercent,
    customFrames = data.customFrames,
    customRows = data.customRows,
    customColumns = data.customColumns,
    customFileWidth = data.customFileWidth,
    customFileHeight = data.customFileHeight,
    customFrameWidth = data.customFrameWidth,
    customFrameHeight = data.customFrameHeight,
  })

  region.stopMotion:SetColor(unpack(data.stopmotionColor))

  Private.regionPrototype.AddMinMaxProgressSource(true, region, parentData, data)

  region.FrameTick = nil
  if data.animationType == "loop" or data.animationType == "bounce" or data.animationType == "once" then
    region.Update = TimedFuncs.Update
    region.SetVisible = TimedFuncs.SetVisible
    region.UpdateFrameTick = nil
    region.UpdateFrame = nil

    parent.subRegionEvents:RemoveSubscriber("Update", region)
  else
    region.Update = ProgressFuncs.Update
    region.SetVisible = ProgressFuncs.SetVisible
    region.UpdateFrameTick = ProgressFuncs.UpdateFrameTick
    region.UpdateFrame = ProgressFuncs.UpdateFrame

    parent.subRegionEvents:AddSubscriber("Update", region)
  end

  region:SetVisible(data.stopmotionVisible)
  region:SetDesaturated(data.stopmotionDesaturate)
end

local function supports(regionType)
  return regionType == "texture"
         or regionType == "progresstexture"
         or regionType == "icon"
         or regionType == "aurabar"
         or regionType == "text"
         or regionType == "empty"
end

WeakAuras.RegisterSubRegionType("substopmotion", L["Stop Motion"], supports, create, modify, onAcquire, onRelease, default, nil, properties)
