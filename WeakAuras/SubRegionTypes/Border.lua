if not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local default = function(parentType)
  local options = {
    border_visible = true,
    border_color = {1, 1, 1, 1},
    border_edge = "Square Full White",
    border_offset = 0,
    border_size = 2,
  }
  if parentType == "aurabar" then
    options["border_anchor"] = "bar"
  end
  return options
end

local properties = {
  border_visible = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
  },
  border_color = {
    display = L["Color"],
    setter = "SetBorderColor",
    type = "color"
  },
}


local function create()
  local region = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  return region
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion:Hide()
end

local function modify(parent, region, parentData, data, first)
  region:SetParent(parent)

  parent:AnchorSubRegion(region, "area", parentData.regionType == "aurabar" and data.border_anchor, nil, data.border_offset, data.border_offset)

  local edgeFile = SharedMedia:Fetch("border", data.border_edge)
  if edgeFile and edgeFile ~= "" then
    region:SetBackdrop({
      edgeFile = edgeFile,
      edgeSize = data.border_size,
      bgFile = nil,
    })
    region:SetBackdropBorderColor(data.border_color[1], data.border_color[2], data.border_color[3], data.border_color[4])
    region:SetBackdropColor(0, 0, 0, 0)
  end

  function region:SetBorderColor(r, g, b, a)
    self:SetBackdropBorderColor(r, g, b, a or 1)
  end

  region:SetBorderColor(data.border_color[1], data.border_color[2], data.border_color[3], data.border_color[4]);

  function region:SetVisible(visible)
    if visible then
      self:Show()
    else
      self:Hide()
    end
  end

  region:SetVisible(data.border_visible)
end

local function supports(regionType)
  return regionType == "texture"
         or regionType == "progresstexture"
         or regionType == "icon"
         or regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subborder", L["Border"], supports, create, modify, onAcquire, onRelease, default, nil, properties);
