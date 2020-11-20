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
  local function recurse(settings, level, prefix, parent)
     for k, v in pairs(settings) do
        if ( type(v) == "table" ) then
           recurse(
              v,
              level + 1,
              (level > 2 and prefix or "")..(v.args and k.."_" or ""),
              k
           )
        end
        if settings.type ~= "group" and k == "default" then
          options[prefix..parent] = v
        end
     end
  end
  recurse(glows, 1)
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

local funcs = {}

local function getProperties()
  local options = {}
  for glowType, glowData in pairs(glows) do
    for property, propertyData in pairs(glowData.args) do
      if propertyData.type ~= "gradient" -- not supported by ace3
      and propertyData.type ~= "group" -- no recurse (for now)
      then
        options[property] = {}
        for k, v in pairs(propertyData) do
          if k == "name" then
            options[property].display = v
          elseif k == "type" and v == "range" then
            options[property][k] = "number"
          elseif k == "type" and v == "select" then
            options[property][k] = "list"
          elseif k == "type" and v == "toggle" then
            options[property][k] = "bool"
          elseif k ~= "desc"
          and k ~= "order"
          then
            options[property][k] = v
          end
        end
        local setterKey = ("Set"..property):gsub("%s+", "_")
        options[property].setter = setterKey
        funcs[setterKey] = function(self, a, b, c, d)
          if d then -- multi args
            self.glowOptions[property] = { a, b, c, d }
          else
            self.glowOptions[property] = a
          end
          if self.glow then
            self:SetVisible(true)
          end
        end
      end
    end
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
    display = L["Type"],
    setter = "SetGlowType",
    type = "list",
    values = Private.glow_types,
  },
}

for k, v in pairs(getProperties()) do
  properties[k] = v
end

local function glowStart(self, frame)
  if frame:GetWidth() < 1 or frame:GetHeight() < 1 then
    self.glowStop(frame)
    return
  end

  local options = {}
  for k, v in pairs(self.glowOptions) do
    if type(k) == "string" then
      local key1, key2, key3, key4, more
      key1, more = k:match("^([^_]+)(.*)")
      if more then
        key2, more = more:match("_([^_]+)(.*)")
        if more then
            key3, more = more:match("_([^_]+)(.*)")
            if more then
              key4 = more:match("_([^_]+)(.*)")
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

funcs["SetVisible"] = function(self, visible)
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
end

funcs["SetGlowType"] = function(self, newType)
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
end

funcs["UpdateSize"] = function(self, ...)
  if self.glow then
    self:SetVisible(true)
  end
end

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
  region.glowOptions = region.glowOptions or {}
  for k in pairs(getDefaults()) do
    region.glowOptions[k] = data[k]
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
