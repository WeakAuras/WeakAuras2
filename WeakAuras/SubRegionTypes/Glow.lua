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

local glows = LCG:GetGlows()

local function getDefaults()
  local options = {}
  local function recurse(settings, prefix, parent)
     for k, v in pairs(settings) do
        if ( type(v) == "table" ) then
           recurse(
              v,
              (prefix or "")..(v.args and k.."_" or ""),
              k
           )
        end
        if settings.type ~= "group" and k == "default" then
          options[prefix..parent] = v
        end
     end
  end
  recurse(glows)
  return options
end

local default = function(parentType)
  local options = getDefaults()
  options.glow = false
  if parentType == "aurabar" then
    options["glowType"] = "Pixel Glow"
    options["glow_anchor"] = "bar"
  else
    options.glowType = "Button Glow"
  end
  return options
end

local properties = {
  glow = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
  },
  glowType = {
    display =L["Type"],
    setter = "SetGlowType",
    type = "list",
    values = Private.glow_types,
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

local function glowStart(self, frame)

  if frame:GetWidth() < 1 or frame:GetHeight() < 1 then
    self.glowStop(frame)
    return
  end

  local options = {}
  for k, v in pairs(self) do
    if type(k) == "string" then
      local key1, key2, key3, key4, more
      key1, more = k:match("^"..self.glowType.."_(%w+)(.*)")
      if more then
        key2, more = more:match("_(%w+)(.*)")
        if more then
            key3, more = more:match("_(%w+)(.*)")
            if more then
              key4 = more:match("_(%w+)(.*)")
          end
        end
      end
      if key1 then
        if key2 then
          if key3 then
            if key4 then
              options[key1] = options[key1] or {}
              options[key1][key2] = options[key1][key2] or {}
              options[key1][key2][key3] = options[key1][key2][key3] or {}
              options[key1][key2][key4] = v
            else
              options[key1] = options[key1] or {}
              options[key1][key2] = options[key1][key2] or {}
              options[key1][key2][key3] = v
            end
          else
            options[key1] = options[key1] or {}
            options[key1][key2] = v
          end
        else
          options[key1] = v
        end
      end
    end
  end

  self.glowStart(frame, options)
end

local funcs = {
  SetVisible = function(self, visible)
    --ViragDevTool_AddData(self, "SetVisible")
    self.glow = visible

    if MSQ and self.parentType == "icon" then
      if (visible) then
        self.__MSQ_Shape = self:GetParent().button.__MSQ_Shape
        glowStart(self, self);
      else
        self.glowStop(self);
      end
    elseif (visible) then
      glowStart(self, self);
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
    newType = glows[newType] and newType or "Button Glow"
    local glowSettings = glows[newType]
    if newType == self.glowType then
      return
    end

    local isGlowing = self.glow
    if isGlowing then
      self:SetVisible(false)
    end

    self.glowStart = glowSettings.start
    self.glowStop = glowSettings.stop
    if newType == "Button Glow" then
      if self.parentRegionType ~= "aurabar" then
        self.parent:AnchorSubRegion(self, "area", "region")
      end
    else
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
      if self.glowType == "AutoCast Glow" then -- workaround ACShine not updating numbers of dots
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
    parent:AnchorSubRegion(region, "area", data.glowType == "Button Glow" and "region")
  end

  region.parent = parent

  region.parentType = parentData.regionType
  for k in pairs(getDefaults()) do
    region[k] = data[k]
  end

  region:SetGlowType(data.glowType)
  region:SetVisible(data.glow)

  region:SetScript("OnSizeChanged", region.UpdateSize)
end

-- This is used by the templates to add glow
function WeakAuras.getDefaultGlow(regionType)
  local options = getDefaults(regionType)
  options.type = "subglow"
  options.glow = false
  if regionType == "aurabar" then
    options.glow_anchor = "bar"
  end
  return options
end

local function supports(regionType)
  return regionType == "icon"
         or regionType == "aurabar"
end

local function addDefaultsForNewAura(data)
  if data.regionType == "icon" then
    local options = getDefaults(data.regionType)
    options.type = "subglow"
    options.glow = false
    tinsert(data.subRegions, options)
  end
end

WeakAuras.RegisterSubRegionType("subglow", L["Glow"], supports, create, modify, onAcquire, onRelease, default, addDefaultsForNewAura, properties);
