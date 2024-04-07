if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L;

local default = function()
  return {
    tick_visible = true,
    tick_color = {1, 1, 1, 1},
    tick_placement_mode = "AtValue",
    tick_placements = {"50"},
    progressSources = {{-2, ""}},
    automatic_length = true,
    tick_thickness = 2,
    tick_length = 30,
    use_texture = false,
    tick_texture = [[Interface\CastingBar\UI-CastingBar-Spark]],
    tick_blend_mode = "ADD",
    tick_desaturate = false,
    tick_rotation = 0,
    tick_xOffset = 0,
    tick_yOffset = 0,
    tick_mirror = false,
  }
end

local properties = {
  tick_visible = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true,
  },
  tick_color = {
    display = L["Color"],
    setter = "SetTickColor",
    type = "color",
  },
  tick_placement_mode = {
    display = L["Placement Mode"],
    setter = "SetTickPlacementMode",
    type = "list",
    values = Private.tick_placement_modes,
  },
  automatic_length = {
    display = L["Automatic Length"],
    setter = "SetAutomaticLength",
    type = "bool",
    defaultProperty = true,
  },
  tick_thickness = {
    display = L["Thickness"],
    setter = "SetTickThickness",
    type = "number",
    min = 0,
    bigStep = 1,
    default = 2,
  },
  tick_length = {
    display = L["Length"],
    setter = "SetTickLength",
    type = "number",
    min = 0,
    bigStep = 1,
    default = 30,
  },
  tick_desaturate = {
    display = L["Desaturate"],
    setter = "SetTickDesaturated",
    type = "bool",
    default = true,
  },
  tick_rotation = {
    display = L["Rotation"],
    setter = "SetTickRotation",
    type = "number",
    min = 0,
    max = 360,
    default = 0,
  },
  tick_mirror = {
    display = L["Mirror"],
    setter = "SetTickMirror",
    type = "bool",
    default = true,
  },
  tick_use_texture = {
    display = L["Use Texture"],
    setter = "SetUseTexture",
    type = "bool",
    default = true,
  },
  tick_texture = {
    display = L["Texture"],
    setter = "SetTexture",
    type = "texture"
  }
}

local function GetProperties(parentData, data)
  local result = CopyTable(properties)
  for i in ipairs(data.tick_placements) do

    result["tick_placements." .. i] = {
      display = #data.tick_placements > 1 and L["Placement %i"]:format(i) or L["Placement"],
      setter = "SetTickPlacementAt",
      type = "number",
      arg1 = i,
      validate = WeakAuras.ValidateNumeric,
    }
  end

  return result
end

local auraBarAnchor = {
  ["HORIZONTAL"] = "LEFT",
  ["HORIZONTAL_INVERSE"] = "RIGHT",
  ["VERTICAL"] = "TOP",
  ["VERTICAL_INVERSE"] = "BOTTOM",
}

local auraBarAnchorInverse = {
  ["HORIZONTAL"] = "RIGHT",
  ["HORIZONTAL_INVERSE"] = "LEFT",
  ["VERTICAL"] = "BOTTOM",
  ["VERTICAL_INVERSE"] = "TOP",
}

local function create()
  local subRegion = CreateFrame("Frame", nil, UIParent)
  subRegion.ticks = {}
  return subRegion
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion:Hide()
end

local funcs = {
  Update = function(self, state, states)
    for i, progressSource in ipairs(self.progressSources) do
      self.progressData[i] = {}
      Private.UpdateProgressFrom(self.progressData[i], progressSource, {}, state, states, self.parent)
    end
    self:UpdateVisible()
    self:UpdateTickPlacement();
    self:UpdateFrameTick()
  end,
  OrientationChanged = function(self)
    self.orientation = self.parent:GetEffectiveOrientation()
    self.vertical = (self.orientation == "VERTICAL") or (self.orientation == "VERTICAL_INVERSE")

    self:UpdateTickPlacement()
    self:UpdateTickSize()
  end,
  OnRegionSizeChanged = function(self)
    if self.vertical then
      self.parentMinorSize, self.parentMajorSize = self.parent.bar:GetRealSize()
    else
      self.parentMajorSize, self.parentMinorSize = self.parent.bar:GetRealSize()
    end

    self:UpdateTickPlacement()
    self:UpdateTickSize()
  end,
  InverseChanged = function(self)
    self.inverse_direction = self.parent:GetInverse()
    self:UpdateTickPlacement()
  end,
  SetVisible = function(self, visible)
    if self.tick_visible ~= visible then
      self.tick_visible = visible
      self:UpdateVisible()
    end
  end,
  UpdateVisibleOne = function(self, i)
    if self.tick_visible and self.hasProgress[i] then
      self.ticks[i]:Show()
    else
      self.ticks[i]:Hide()
    end
  end,
  UpdateVisible = function(self)
    for i in ipairs(self.ticks) do
      self:UpdateVisibleOne(i)
    end
  end,
  SetTickColor = function(self, r, g, b, a)
    self.tick_color[1], self.tick_color[2], self.tick_color[3], self.tick_color[4] = r, g, b, a or 1
    if self.use_texture then
      for _, tick in ipairs(self.ticks) do
        tick:SetVertexColor(r, g, b, a or 1)
      end
      self:UpdateTickDesaturated()
    else
      for _, tick in ipairs(self.ticks) do
        tick:SetColorTexture(r, g, b, a or 1)
      end
    end
  end,
  SetTickPlacementMode = function(self, placement_mode)
    if self.tick_placement_mode ~= placement_mode then
      self.tick_placement_mode = placement_mode
      self:UpdateTickPlacement()
      self:UpdateVisible()
      self:UpdateFrameTick()
    end
  end,
  UpdateFrameTick = function(self)
    local requiresFrameTick = false
    if self.tick_placement_mode == "ValueOffset" then
      for i, progress in ipairs(self.progressData) do
        if progress.progressType == "timed" and not progress.paused then
          requiresFrameTick = true
          break
        end
      end
    end

    if requiresFrameTick then
      if not self.FrameTick then
        self.FrameTick = self.UpdateTickPlacement
        self.parent.subRegionEvents:AddSubscriber("FrameTick", self)
      end
    else
      if self.FrameTick then
        self.FrameTick = nil
        self.parent.subRegionEvents:RemoveSubscriber("FrameTick", self)
      end
    end
  end,
  SetTickPlacementAt = function(self, tick, placement)
    placement = tonumber(placement)
    if self.tick_placements[tick] ~= placement then
      self.tick_placements[tick] = placement
      self:UpdateTickPlacementOne(tick)
    end
  end,
  -- For backwards compability
  SetTickPlacement = function(self, placement)
    self:SetTickPlacementAt(1, placement)
  end,
  UpdateTickPlacement = function(self)
    for i in ipairs(self.tick_placements) do
      self:UpdateTickPlacementOne(i)
    end
  end,
  UpdateTickPlacementOne = function(self, i)
    local offsetx, offsety = 0, 0
    local width = self.parentMajorSize

    local minValue, maxValue = self.parent:GetMinMaxProgress()
    local valueRange = maxValue - minValue
    local inverse = self.inverse_direction

    if self.parent.inverse then
      inverse = not inverse
    end

    local tick_placement
    if self.tick_placement_mode == "AtValue" then
      tick_placement = self.tick_placements[i]
    elseif self.tick_placement_mode == "AtMissingValue" then
      tick_placement = maxValue - self.tick_placements[i]
    elseif self.tick_placement_mode == "AtPercent" then
      if self.tick_placements[i] >= 0 and self.tick_placements[i] <= 100 and maxValue then
        tick_placement = minValue + self.tick_placements[i] * valueRange / 100
      end
    elseif self.tick_placement_mode == "ValueOffset" then
      if maxValue ~= 0 and self.progressData[i] then
        if self.progressData[i].progressType == "timed" then
          if self.progressData[i].paused then
            if self.progressData[i].remaining then
              tick_placement = self.progressData[i].remaining + self.tick_placements[i]
            end
          else
            tick_placement = self.progressData[i].expirationTime - GetTime() + self.tick_placements[i]
          end
        elseif self.progressData[i].progressType == "static" then
          tick_placement = self.progressData[i].value + self.tick_placements[i]
        end
      end
    end

    local offset
    local percent = valueRange ~= 0 and tick_placement and (tick_placement - minValue) / valueRange
    if not percent or (percent and percent < 0 or percent > 1) then
      offset = 0
      self.hasProgress[i] = false
    else
      offset = percent * width
      self.hasProgress[i] = true
    end
    self:UpdateVisible(i)

    if (self.orientation == "HORIZONTAL_INVERSE") or (self.orientation == "VERTICAL") then
      offset = -offset
    end

    if inverse then
      offset = -offset
    end

    if (self.vertical) then
      offsety = offset
    else
      offsetx = offset
    end
    local side = inverse and auraBarAnchorInverse or auraBarAnchor
    self.ticks[i]:ClearAllPoints()
    self.ticks[i]:SetPoint("CENTER", self.parent.bar, side[self.orientation],
                       offsetx + self.tick_xOffset,
                       offsety + self.tick_yOffset)
  end,
  SetAutomaticLength = function(self, automatic_length)
    if self.automatic_length ~= automatic_length then
      self.automatic_length = automatic_length
      self:UpdateTickSize()
    end
  end,
  SetTickThickness = function(self, thickness, forced)
    if self.tick_thickness ~= thickness then
      self.tick_thickness = thickness
      self:UpdateTickSize()
    end
  end,
  SetTickLength = function(self, length, forced)
    if self.length ~= length then
      self.tick_length = length
      self:UpdateTickSize()
    end
  end,
  UpdateTickSize = function(self)
    if self.vertical then
      for i, tick in ipairs(self.ticks) do
        tick:SetHeight(self.tick_thickness)
      end
    else
      for i, tick in ipairs(self.ticks) do
        tick:SetWidth(self.tick_thickness)
      end
    end

    local length = self.automatic_length and self.parentMinorSize or self.tick_length
    if self.vertical then
      for i, tick in ipairs(self.ticks) do
        tick:SetWidth(length)
      end
    else
      for i, tick in ipairs(self.ticks) do
        tick:SetHeight(length)
      end
    end
  end,
  SetTickDesaturated = function(self, desaturate)
    if self.use_texture and self.tick_desaturate ~= desaturate then
      self.tick_desaturate = desaturate
      self:UpdateTickDesaturated()
    end
  end,
  UpdateTickDesaturated = function(self)
    for i, tick in ipairs(self.ticks) do
      tick:SetDesaturated(self.tick_desaturate)
    end
  end,
  SetTickRotation = function(self, degrees)
    if self.tick_rotation ~= degrees then
      self.tick_rotation = degrees
      self:UpdateTickRotation()
    end
  end,
  UpdateTickRotation = function(self)
    local rad = math.rad(self.tick_rotation)
    for _, tick in ipairs(self.ticks) do
      tick:SetRotation(rad)
    end
  end,
  SetTickMirror = function(self, mirror)
    if self.mirror ~= mirror then
      self.mirror = mirror
      self:UpdateTickMirror()
    end
  end,
  UpdateTickMirror = function(self)
    if self.mirror then
      for _, tick in ipairs(self.ticks) do
        tick:SetTexCoord(0,  1,  1,  1,  0,  0,  1,  0)
      end
    else
      for _, tick in ipairs(self.ticks) do
        tick:SetTexCoord(0,  0,  1,  0,  0,  1,  1,  1)
      end
    end
  end,
  SetTickBlendMode = function(self, mode)
    if self.tick_blend_mode ~= mode then
      self.tick_blend_mode = mode
      self:UpdateTickBlendMode()
    end
  end,
  UpdateTickBlendMode = function(self)
    if self.use_texture then
      for _, tick in ipairs(self.ticks) do
        tick:SetBlendMode(self.tick_blend_mode)
      end
    else
      for _, tick in ipairs(self.ticks) do
        tick:SetBlendMode("BLEND")
      end
    end
  end,
  UpdateTexture = function(self)
    if self.use_texture then
      for _, tick in ipairs(self.ticks) do
        Private.SetTextureOrAtlas(tick, self.tick_texture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
      end
    else
      for _, tick in ipairs(self.ticks) do
        tick:SetColorTexture(self.tick_color[1], self.tick_color[2], self.tick_color[3], self.tick_color[4])
      end
    end
  end,
  SetTexture = function(self, texture)
    if self.tick_texture == texture then
      return
    end
    self.tick_texture = texture
    self:UpdateTexture()
  end,
  SetUseTexture = function(self, use)
    if self.use_texture == use then
      return
    end
    self.use_texture = use
    self:UpdateTexture()
  end
}

local function modify(parent, region, parentData, data, first)
  region:SetParent(parent)
  region.orientation = parent.effectiveOrientation
  region.inverse_direction = parentData.inverse
  region.inverse = false
  region.vertical = region.orientation == "VERTICAL" or region.orientation == "VERTICAL_INVERSE"
  if (region.vertical) then
    region.parentMinorSize, region.parentMajorSize = parent.bar:GetRealSize()
  else
    region.parentMajorSize, region.parentMinorSize = parent.bar:GetRealSize()
  end

  region.parent = parent
  region.parentData = parentData
  region.tick_visible = data.tick_visible
  region.tick_color = CopyTable(data.tick_color)
  region.tick_placement_mode = data.tick_placement_mode
  region.tick_placements = {}
  region.progressSources = {}
  region.progressData = {}
  for i, tick_placement in ipairs(data.tick_placements) do
    local value = tonumber(tick_placement)
    if region.tick_placement_mode == "ValueOffset" then
      local progressSource = Private.AddProgressSourceMetaData(parentData, data.progressSources[i] or {-2, ""})
      if value and progressSource then
        tinsert(region.tick_placements, value)
        tinsert(region.progressSources, progressSource or {})
      end
    else
      if value then
        tinsert(region.tick_placements, value)
      end
    end

    if region.ticks[i] == nil then
      local texture = region:CreateTexture()
      texture:SetSnapToPixelGrid(false)
      texture:SetTexelSnappingBias(0)
      texture:SetDrawLayer("ARTWORK", 3)
      texture:SetAllPoints(region)
      region.ticks[i] = texture
    end
  end

  for i = #data.tick_placements + 1, #region.ticks do
    region.ticks[i]:Hide()
  end

  region.automatic_length = data.automatic_length
  region.tick_thickness = data.tick_thickness
  region.tick_length = data.tick_length
  region.use_texture = data.use_texture
  region.tick_texture = data.tick_texture

  region.tick_xOffset = data.tick_xOffset
  region.tick_yOffset = data.tick_yOffset

  region.hasProgress = {}

  for k, v in pairs(funcs) do
    region[k] = v
  end

  if data.use_texture then
    for _, tick in ipairs(region.ticks) do
      Private.SetTextureOrAtlas(tick, data.tick_texture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    end
  end

  region:SetVisible(data.tick_visible)
  region:SetTickColor(unpack(data.tick_color))
  region:SetTickDesaturated(data.tick_desaturate)
  region:SetTickBlendMode(data.tick_blend_mode)
  region:SetTickRotation(data.tick_rotation)
  region:SetTickMirror(data.tick_mirror)

  region:UpdateTickSize()

  parent.subRegionEvents:AddSubscriber("Update", region)
  parent.subRegionEvents:AddSubscriber("OrientationChanged", region)
  parent.subRegionEvents:AddSubscriber("InverseChanged", region)
  parent.subRegionEvents:AddSubscriber("OnRegionSizeChanged", region)

  region.FrameTick = nil
  region:ClearAllPoints()
  region:SetAllPoints(parent.bar)
end

local function supports(regionType)
  return regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subtick", L["Tick"], supports, create, modify, onAcquire, onRelease,
                                default, nil, GetProperties);
