if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

local SharedMedia = LibStub("LibSharedMedia-3.0");
local LCG = LibStub("LibCustomGlow-1.0")
local MSQ, MSQ_Version = LibStub("Masque", true);
if MSQ then
  if MSQ_Version <= 80100 then
    MSQ = nil
  end
end
local L = WeakAuras.L;

local default = function(parentType)
  local options = {
    glow = false,
    useGlowColor = false,
    glowColor = {1, 1, 1, 1},
    glowType = "buttonOverlay",
    glowLines = 8,
    glowFrequency = 0.25,
    glowLength = 10,
    glowThickness = 1,
    glowScale = 1,
    glowBorder = false,
    glowXOffset = 0,
    glowYOffset = 0,
  }
  if parentType == "aurabar" then
    options["glowType"] = "Pixel"
    options["glow_anchor"] = "bar"
  end
  return options
end

local properties = {
  glow = {
    display = L["Show Glow"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
  },
  glowType = {
    display =L["Type"],
    setter = "SetGlowType",
    type = "list",
    values = WeakAuras.glow_types,
  },
  useGlowColor = {
    display = L["Use Custom Color"],
    setter = "SetUseGlowColor",
    type = "bool"
  },
  glowColor = {
    display = L["Custom Color"],
    setter = "SetGlowColor",
    type = "color"
  },
  glowLines = {
    display = L["Lines & Particles"],
    setter = "SetGlowLines",
    type = "number",
    min = 1,
    softMax = 30,
    bigStep = 1,
    default = 4
  },
  glowFrequency = {
    display = L["Frequency"],
    setter = "SetGlowFrequency",
    type = "number",
    softMin = -2,
    softMax = 2,
    bigStep = 0.1,
    default = 0.25
  },
  glowLength = {
    display = L["Length"],
    setter = "SetGlowLength",
    type = "number",
    min = 1,
    softMax = 20,
    bigStep = 1,
    default = 10
  },
  glowThickness = {
    display = L["Thickness"],
    setter = "SetGlowThickness",
    type = "number",
    min = 1,
    softMax = 20,
    bigStep = 1,
    default = 1
  },
  glowScale = {
    display = L["Scale"],
    setter = "SetGlowScale",
    type = "number",
    min = 0.05,
    softMax = 10,
    bigStep = 0.05,
    default = 1,
    isPercent = true
  },
  glowBorder = {
    display = L["Border"],
    setter = "SetGlowBorder",
    type = "bool"
  },
  glowXOffset = {
    display = L["X-Offset"],
    setter = "SetGlowXOffset",
    type = "number",
    softMin = -100,
    softMax = 100,
    bigStep = 1,
    default = 0
  },
  glowYOffset = {
    display = L["Y-Offset"],
    setter = "SetGlowYOffset",
    type = "number",
    softMin = -100,
    softMax = 100,
    bigStep = 1,
    default = 0
  },
}

local function glowStart(self, frame, color)

  if frame:GetWidth() < 1 or frame:GetHeight() < 1 then
    self.glowStop(frame)
    return
  end

  if self.glowType == "buttonOverlay" then
    self.glowStart(frame, color, self.glowFrequency, 0)
  elseif self.glowType == "Pixel" then
    self.glowStart(
      frame,
      color,
      self.glowLines,
      self.glowFrequency,
      self.glowLength,
      self.glowThickness,
      self.glowXOffset,
      self.glowYOffset,
      self.glowBorder,
      nil,
      0
    )
  elseif self.glowType == "ACShine" then
    self.glowStart(
      frame,
      color,
      self.glowLines,
      self.glowFrequency,
      self.glowScale,
      self.glowXOffset,
      self.glowYOffset,
      nil,
      0
    )
  end
end

local funcs = {
  SetVisible = function(self, visible)
    local color
    self.glow = visible

    if self.useGlowColor then
      color = self.glowColor
    end

    if MSQ and self.parentType == "icon" then
      if (visible) then
        self.__MSQ_Shape = self:GetParent().button.__MSQ_Shape
        glowStart(self, self, color);
      else
        self.glowStop(self);
      end
    elseif (visible) then
      glowStart(self, self, color);
    else
      self.glowStop(self);
    end
    if visible then
      self:Show()
    else
      self:Hide()
    end
  end,
  SetGlowType = function(self, newType)
    newType = newType or "buttonOverlay"
    if newType == self.glowType then
      return
    end

    local isGlowing = self.glow
    if isGlowing then
      self:SetVisible(false)
    end

    if newType == "buttonOverlay" then
      self.glowStart = LCG.ButtonGlow_Start
      self.glowStop = LCG.ButtonGlow_Stop
      if self.parentRegionType ~= "aurabar" then
        self.parent:AnchorSubRegion(self, "area", "region")
      end
    elseif newType == "ACShine" then
      self.glowStart = LCG.AutoCastGlow_Start
      self.glowStop = LCG.AutoCastGlow_Stop
      if self.parentRegionType ~= "aurabar" then
        self.parent:AnchorSubRegion(self, "area")
      end
    elseif newType == "Pixel" then
      self.glowStart = LCG.PixelGlow_Start
      self.glowStop = LCG.PixelGlow_Stop
      if self.parentRegionType ~= "aurabar" then
        self.parent:AnchorSubRegion(self, "area")
      end
    end
    self.glowType = newType
    if isGlowing then
      self:SetVisible(true)
    end
  end,
  SetUseGlowColor = function(self, useGlowColor)
    self.useGlowColor = useGlowColor
    if self.glow then
      self:SetVisible(true)
    end
  end,
  SetGlowColor = function(self, r, g, b, a)
    self.glowColor = {r, g, b, a}
    if self.glow then
      self:SetVisible(true)
    end
  end,
  SetGlowLines = function(self, lines)
    self.glowLines = lines
    if self.glow then
      if self.glowType == "ACShine" then -- workaround ACShine not updating numbers of dots
        self:SetVisible(false)
      end
      self:SetVisible(true)
    end
  end,
  SetGlowFrequency = function(self, frequency)
    self.glowFrequency = frequency
    if self.glow then
      self:SetVisible(true)
    end
  end,
  SetGlowLength = function(self, length)
    self.glowLength = length
    if self.glow then
      self:SetVisible(true)
    end
  end,
  SetGlowThickness = function(self, thickness)
    self.glowThickness = thickness
    if self.glow then
      self:SetVisible(true)
    end
  end,
  SetGlowScale = function(self, scale)
    self.glowScale = scale
    if self.glow then
      self:SetVisible(true)
    end
  end,
  SetGlowBorder = function(self, border)
    self.glowBorder = border
    if self.glow then
      self:SetVisible(true)
    end
  end,
  SetGlowXOffset = function(self, xoffset)
    self.glowXOffset = xoffset
    if self.glow then
      self:SetVisible(true)
    end
  end,
  SetGlowYOffset = function(self, yoffset)
    self.glowYOffset = yoffset
    if self.glow then
      self:SetVisible(true)
    end
  end,
  UpdateSize = function(self, ...)
    if self.glow then
      self:SetVisible(true)
    end
  end
}

local function create()
  local region = CreateFrame("FRAME", nil, UIParent)

  for name, func  in pairs(funcs) do
    region[name] = func
  end

  return region
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion.glowType = nil
  subRegion:Hide()
  subRegion:ClearAllPoints()
  subRegion:SetParent(UIParent)
end

local function modify(parent, region, parentData, data, first)
  region:SetParent(parent)
  region.parentRegionType = parentData.regionType
  if parentData.regionType == "aurabar" then
    parent:AnchorSubRegion(region, "area", data.glow_anchor)
  else
    parent:AnchorSubRegion(region, "area", data.glowType == "buttonOverlay" and "region")
  end

  region.parent = parent

  region.parentType = parentData.regionType
  region.useGlowColor = data.useGlowColor
  region.glowColor = data.glowColor
  region.glowLines = data.glowLines
  region.glowFrequency = data.glowFrequency
  region.glowLength = data.glowLength
  region.glowThickness = data.glowThickness
  region.glowScale = data.glowScale
  region.glowBorder = data.glowBorder
  region.glowXOffset = data.glowXOffset
  region.glowYOffset = data.glowYOffset

  region:SetGlowType(data.glowType)
  region:SetVisible(data.glow)

  region:SetScript("OnSizeChanged", region.UpdateSize)
end

-- This is used by the templates to add glow
function WeakAuras.getDefaultGlow(regionType)
  if regionType == "aurabar" then
    return {
      ["type"] = "subglow",
      glow = false,
      useGlowColor = false,
      glowColor = {1, 1, 1, 1},
      glowType = "Pixel",
      glowLines = 8,
      glowFrequency = 0.25,
      glowLength = 10,
      glowThickness = 1,
      glowScale = 1,
      glowBorder = false,
      glowXOffset = 0,
      glowYOffset = 0,
      glow_anchor = "bar"
    }
  elseif regionType == "icon" then
    return {
      ["type"] = "subglow",
      glow = false,
      useGlowColor = false,
      glowColor = {1, 1, 1, 1},
      glowType = "buttonOverlay",
      glowLines = 8,
      glowFrequency = 0.25,
      glowLength = 10,
      glowThickness = 1,
      glowScale = 1,
      glowBorder = false,
      glowXOffset = 0,
      glowYOffset = 0,
    }
  end
end

local function supports(regionType)
  return regionType == "icon"
         or regionType == "aurabar"
end

local function addDefaultsForNewAura(data)
  if data.regionType == "icon" then
    tinsert(data.subRegions, {
      ["type"] = "subglow",
      glow = false,
      useGlowColor = false,
      glowColor = {1, 1, 1, 1},
      glowType = "buttonOverlay",
      glowLines = 8,
      glowFrequency = 0.25,
      glowLength = 10,
      glowThickness = 1,
      glowScale = 1,
      glowBorder = false,
      glowXOffset = 0,
      glowYOffset = 0,
    })
  end
end

WeakAuras.RegisterSubRegionType("subglow", L["Glow"], supports, create, modify, onAcquire, onRelease, default, addDefaultsForNewAura, properties);
