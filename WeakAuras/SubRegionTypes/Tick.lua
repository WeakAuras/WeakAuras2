if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local default = function(parentType)
  return {
    tick_visible = true,
    tick_color = {1, 1, 1, 1},
    tick_placement_mode = "AtValue",
    tick_placement = "50",
    automatic_length = true,
    tick_thickness = 2,
    tick_length = 30,
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
    values = WeakAuras.tick_placement_modes,
  },
  tick_placement = {
    display = L["Placement"],
    setter = "SetTickPlacement",
    type = "number",
    validate = WeakAuras.ValidateNumeric,
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
}

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
  local subRegion = CreateFrame("FRAME", nil, UIParent)
  subRegion.texture = subRegion:CreateTexture()
  subRegion.texture:SetDrawLayer("ARTWORK", 3)
  subRegion.texture:SetAllPoints(subRegion)
  return subRegion
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion:Hide()
end

local funcs = {
  Update = function(self, state)
    self.trigger_inverse = state.inverse
    self.state = state
    if state.progressType == "timed" then
      self.trigger_total = state.duration
    elseif state.progressType == "static" then
      self.trigger_total = state.total
    else
      self.trigger_total = nil
    end
    self:UpdateVisible()
    self:UpdateTickPlacement();
    self:UpdateTimerTick()
  end,
  OrientationChanged = function(self)
    self.orientation = self.parent:GetEffectiveOrientation()
    self.vertical = (self.orientation == "VERTICAL") or (self.orientation == "VERTICAL_INVERSE")

    self:UpdateTickPlacement()
    self:UpdateTickSize()
  end,
  OnSizeChanged = function(self)
    if self.vertical then
      self.parentMinorSize, self.parentMajorSize = self.parent.bar:GetRealSize()
    else
      self.parentMajorSize, self.parentMinorSize = self.parent.bar:GetRealSize()
    end

    self:UpdateTickPlacement()
    self:UpdateTickSize()
  end,
  InverseChanged = function(self)
    self.inverse = self.parent:GetInverse()
    self:UpdateTickPlacement()
  end,
  SetVisible = function(self, visible)
    if self.tick_visible ~= visible then
      self.tick_visible = visible
      self:UpdateVisible()
    end
  end,
  UpdateVisible = function(self)
    local missingProgress = self.tick_placement_mode ~= "AtPercent" and not self.trigger_total
    if self.tick_visible and not missingProgress then
      self:Show()
    else
      self:Hide()
    end
  end,
  SetTickColor = function(self, r, g, b, a)
    self.tick_color[1], self.tick_color[2], self.tick_color[3], self.tick_color[4] = r, g, b, a or 1
    self.texture:SetColorTexture(r, g, b, a or 1)
  end,
  SetTickPlacementMode = function(self, placement_mode)
    if self.tick_placement_mode ~= placement_mode then
      self.tick_placement_mode = placement_mode
      self:UpdateTickPlacement()
      self:UpdateVisible()
      self:UpdateTimerTick()
    end
  end,
  UpdateTimerTick = function(self)
    if self.tick_placement_mode == "ValueOffset" and self.state and self.state.progressType == "timed" then
      if not self.TimerTick then
        self.TimerTick = self.UpdateTickPlacement
        self.parent:UpdateRegionHasTimerTick()
        self.parent.subRegionEvents:AddSubscriber("TimerTick", self)
      end
    else
      if self.TimerTick then
        self.TimerTick = nil
        self.parent:UpdateRegionHasTimerTick()
        self.parent.subRegionEvents:RemoveSubscriber("TimerTick", self)
      end
    end
  end,
  SetTickPlacement = function(self, placement)
    placement = tonumber(placement)
    if self.tick_placement ~= placement then
      self.tick_placement = placement
      self:UpdateTickPlacement()
    end
  end,
  UpdateTickPlacement = function(self)
    local offset, offsetx, offsety = self.tick_placement, 0, 0
    local width = self.parentMajorSize

    local minValue, maxValue = self.parent:GetMinMax()
    local valueRange = maxValue - minValue

    local tick_placement
    if self.tick_placement_mode == "AtValue" then
      tick_placement = self.tick_placement
    elseif self.tick_placement_mode == "AtMissingValue" then
      tick_placement = self.trigger_total and self.trigger_total - self.tick_placement
    elseif self.tick_placement_mode == "AtPercent" then
      if self.tick_placement >= 0 and self.tick_placement <= 100 and self.trigger_total then
        tick_placement = self.tick_placement * self.trigger_total / 100
      end
    elseif self.tick_placement_mode == "ValueOffset" then
      if self.trigger_total and self.trigger_total ~= 0 then
        if self.state.progressType == "timed" then
          tick_placement = self.state.expirationTime - GetTime() + self.tick_placement
        else
          tick_placement = self.state.value + self.tick_placement
        end
      end
    end

    local percent = valueRange ~= 0 and tick_placement and (tick_placement - minValue) / valueRange
    if not percent or (percent and percent < 0 or percent > 1) then
      self.texture:Hide()
      offset = 0
    else
      self.texture:Show()
      offset = percent * width
    end

    local inverse = self.inverse
    if self.trigger_inverse then
      inverse = not inverse
    end

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
    self:ClearAllPoints()
    self:SetPoint("CENTER", self.parent.bar, side[self.orientation], offsetx, offsety)
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
      self:SetHeight(self.tick_thickness)
    else
      self:SetWidth(self.tick_thickness)
    end

    local length = self.automatic_length and self.parentMinorSize or self.tick_length
    if self.vertical then
      self:SetWidth(length)
    else
      self:SetHeight(length)
    end
  end
}

local function modify(parent, region, parentData, data, first)

  region:SetParent(parent)
  region.orientation = parent.effectiveOrientation
  region.inverse = parentData.inverse
  region.trigger_inverse = false
  region.vertical = region.orientation == "VERTICAL" or region.orientation == "VERTICAL_INVERSE"
  if (region.vertical) then
    region.parentMinorSize, region.parentMajorSize = parent.bar:GetRealSize()
  else
    region.parentMajorSize, region.parentMinorSize = parent.bar:GetRealSize()
  end

  region.parent = parent
  region.parentData = parentData
  region.tick_visible = data.tick_visible
  region.tick_color = data.tick_color
  region.tick_placement_mode = data.tick_placement_mode
  region.tick_placement = tonumber(data.tick_placement)
  region.automatic_length = data.automatic_length
  region.tick_thickness = data.tick_thickness
  region.tick_length = data.tick_length

  for k, v in pairs(funcs) do
    region[k] = v
  end

  region:SetVisible(data.tick_visible)
  region:SetTickColor(unpack(data.tick_color))

  region:UpdateTickSize()

  parent.subRegionEvents:AddSubscriber("Update", region)
  parent.subRegionEvents:AddSubscriber("OrientationChanged", region)
  parent.subRegionEvents:AddSubscriber("InverseChanged", region)
  parent:SetScript("OnSizeChanged", function() region:OnSizeChanged() end)

  region.TimerTick = nil
end

local function supports(regionType)
  return regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subtick", L["Tick"], supports, create, modify, onAcquire, onRelease, default, nil, properties);
