if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local default = function(parentType)
  return {
    tick_visible = true,
    tick_color = {1, 1, 1, 1},
    tick_placement_mode = "STATIC",
    tick_placement = "50%",
    automatic_height = true,
    tick_thickness = 2,
    tick_length = 30,
    tick_hide_mode = "NEVER",
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
    type = "string",
    validate = WeakAuras.ValidateNumericOrPercent,
  },
  tick_thickness = {
    display = L["Thickness"],
    setter = "SetTickThickness",
    type = "number",
    min = 0,
    bigStep = 1,
    default = 2,
  },
  tick_height = {
    display = L["Height"],
    setter = "SetTickHeight",
    type = "number",
    min = 0,
    bigStep = 1,
    default = 30,
  },
  tick_hide_mode = {
    display = L["Placement Mode"],
    setter = "SetTickPlacementMode",
    type = "list",
    values = WeakAuras.tick_hide_modes,
  },
}

local auraBarTrueLeft = {
  ["HORIZONTAL"] = "LEFT",
  ["HORIZONTAL_INVERSE"] = "RIGHT",
  ["VERTICAL"] = "TOP",
  ["VERTICAL_INVERSE"] = "BOTTOM",
}

local auraBarTrueLeftInverse = {
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
  ["Update"] = function(self)
    self:SetTickPlacement(self.tick_placement)
  end,
  SetVisible = function(self, visible)
    if visible then
      self:Show()
    else
      self:Hide()
    end
  end,
  SetTickColor = function(self, r, g, b, a)
    self.texture:SetColorTexture(r, g, b, a or 1)
  end,
  SetTickPlacement = function(self, placement)
    local offset, offsetx, offsety = self.tick_placement, 0, 0
    local width = self.parentTrueWidth
    if self.tick_placement_mode == "NUMERIC" then
      local pixels = width / (self.parent.state.duration or self.parent.state.total or 1)
      offset = math.max((placement * pixels), width)
    elseif self.tick_placement_mode == "PERCENT" then
      offset = (placement / 100) * width
    end

    if self.parentInverse ~= ((self.parentOrientation == "HORIZONTAL_INVERSE") or (self.parentOrientation == "VERTICAL")) then
      offset = -offset
    end
    if (self.parentOrientation == "VERTICAL") or (self.parentOrientation == "VERTICAL_INVERSE") then
      offsety = offset
    else
      offsetx = offset
    end
    local side = self.parentInverse and auraBarTrueLeftInverse or auraBarTrueLeft

    self:ClearAllPoints()
    self:SetPoint("CENTER", self.parent.bar, side[self.parentOrientation], offsetx, offsety)
  end,
  SetTickThickness = function(self, thickness)
    if (self.parentOrientation == "VERTICAL") or (self.parentOrientation == "VERTICAL_INVERSE") then
      self:SetHeight(thickness)
    else
      self:SetWidth(thickness)
    end
  end,
  SetTickHeight = function(self, height)
    if self.automatic_height then height = self.parentTrueHeight end
    if (self.parentOrientation == "VERTICAL") or (self.parentOrientation == "VERTICAL_INVERSE") then
      self:SetWidth(height)
    else
      self:SetHeight(height)
    end
  end,
}

local function modify(parent, region, parentData, data, first)

  region:SetParent(parent)
  region.parentOrientation = parentData.orientation
  region.parentInverse = parentData.inverse
  if (region.parentOrientation == "VERTICAL") or (region.parentOrientation == "VERTICAL_INVERSE") then
    region.parentTrueHeight, region.parentTrueWidth = parent.bar:GetRealSize()
  else
    region.parentTrueWidth, region.parentTrueHeight = parent.bar:GetRealSize()
  end

  for k, v in pairs(funcs) do
    region[k] = v
  end

  --for k, v in pairs(parent.state) do print(k, v) end

  region.parent = parent
  region.tick_visible = data.tick_visible
  region.tick_color = data.tick_color
  region.tick_placement_mode = data.tick_placement_mode
  region.tick_placement = data.tick_placement
  region.automatic_height = data.automatic_height
  region.tick_thickness = data.tick_thickness
  region.tick_height = data.tick_height


  region:SetVisible(data.tick_visible)
  region:SetTickColor(unpack(data.tick_color))
  region:SetTickThickness(data.tick_thickness)
  region:SetTickHeight(data.tick_height)

  parent.subRegionEvents:AddSubscriber("Update", region)
  --parent.subRegionEvents:AddSubscriber("FrameTick", region)
end

local function supports(regionType)
  return regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subtick", L["Tick"], supports, create, modify, onAcquire, onRelease, default, nil, properties);
