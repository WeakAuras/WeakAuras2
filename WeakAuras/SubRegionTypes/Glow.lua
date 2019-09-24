if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local LCG = LibStub("LibCustomGlow-1.0")
local MSQ, MSQ_Version = LibStub("Masque", true);
local L = WeakAuras.L;

local default = function(parentType)
  local options = {
    glow = false,
    useglowColor = false,
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
    options["glowAnchor"] = "bar"
  end
  return options
end

local properties = {
  glow = {
    display = L["Visibility"],
    setter = "SetGlow",
    type = "bool",
    defaultProperty = true
  },
  glowType = {
    display = L["Type"],
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
    display = L["Color"],
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


local function create()
  return CreateFrame("FRAME", nil, UIParent)
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion:Hide()
end

local function modify(parent, region, parentData, data, first)
  region:SetParent(parent)

  if data.glow then
    local anchor = parent
    if parentData.regionType == "aurabar" then
      if data.glowAnchor == "bar" then
        anchor = parent
      elseif data.glowAnchor == "icon" then
        anchor = parent.icon
      elseif data.glowAnchor == "fg" then
        anchor = parent.bar.fg
      elseif data.glowAnchor == "bg" then
        anchor = parent.bar.bg
      end
    end
    region:ClearAllPoints()
    region:SetPoint("bottomleft", anchor, "bottomleft", -data.glowXOffset, -data.glowYOffset)
    region:SetPoint("topright",   anchor, "topright",    data.glowXOffset,  data.glowYOffset)
    region:Show()
  else
    region:Hide()
  end
  function region:SetGlowType(newType)
    local isGlowing = region.glow
    if isGlowing then
      region:SetGlow(false)
    end
    if newType == "buttonOverlay" then
      region.glowStart = LCG.ButtonGlow_Start
      region.glowStop = LCG.ButtonGlow_Stop
    elseif newType == "ACShine" then
      region.glowStart = LCG.AutoCastGlow_Start
      region.glowStop = LCG.AutoCastGlow_Stop
    elseif newType == "Pixel" then
      region.glowStart = LCG.PixelGlow_Start
      region.glowStop = LCG.PixelGlow_Stop
    end
    region.glowType = newType
    if isGlowing then
      region:SetGlow(true)
    end
  end

  function region:SetUseGlowColor(useGlowColor)
    region.useGlowColor = useGlowColor
    if region.glow then
      region:SetGlow(true)
    end
  end

  function region:SetGlowColor(r, g, b, a)
    region.glowColor = {r, g, b, a}
    if region.glow then
      region:SetGlow(true)
    end
  end

  function region:SetGlowLines(lines)
    region.glowLines = lines
    if region.glow then
      if region.glowType == "ACShine" then -- workaround ACShine not updating numbers of dots
        region:SetGlow(false)
      end
      region:SetGlow(true)
    end
  end
  function region:SetGlowFrequency(frequency)
    region.glowFrequency = frequency
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowLength(length)
    region.glowLength = length
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowThickness(thickness)
    region.glowThickness = thickness
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowScale(scale)
    region.glowScale = scale
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowBorder(border)
    region.glowBorder = border
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowXOffset(xoffset)
    region.glowXOffset = xoffset
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowYOffset(yoffset)
    region.glowYOffset = yoffset
    if region.glow then
      region:SetGlow(true)
    end
  end

  function region:SetGlow(showGlow)
    local color
    local function glowStart(frame)
      if region.glowType == "buttonOverlay" then
        region.glowStart(frame, color, region.glowFrequency)
      elseif region.glowType == "Pixel" then
        region.glowStart(
          frame,
          color,
          region.glowLines,
          region.glowFrequency,
          region.glowLength,
          region.glowThickness,
          region.glowXOffset,
          region.glowYOffset,
          region.glowBorder
        )
      elseif region.glowType == "ACShine" then
        region.glowStart(
          frame,
          color,
          region.glowLines,
          region.glowFrequency,
          region.glowScale,
          region.glowXOffset,
          region.glowYOffset
        )
      end
    end
    region.glow = showGlow
    if region.useGlowColor then
      color = region.glowColor
    end
    if MSQ then
      if showGlow then
        glowStart(region)
      else
        region.glowStop(region)
      end
    elseif showGlow then
      --region.__WAGlowFrame:SetSize(region.width * math.abs(region.scalex), region.height * math.abs(region.scaley))
      glowStart(region)
    else
      region.glowStop(region)
    end
  end

  function region:PreShowGlow()
    if region.glow then
      region:SetGlow(false)
      region:SetGlow(true)
    end
  end

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
  region:SetGlow(data.glow)

  region.PreShow = region.PreShowGlow -- is it correct ?

  region.UpdateAnchor = function() end
  region.Update = function() end
end

local function supports(regionType)
  return regionType == "texture"
         or regionType == "progresstexture"
         or regionType == "icon"
         or regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subglow", L["Glow"], supports, create, modify, onAcquire, onRelease, default, nil, properties);
