if not WeakAuras.IsCorrectVersion() then return end

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
    display = L["Show Border"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
  },
  border_color = {
    display = L["Border Color"],
    setter = "SetBorderColor",
    type = "color"
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

  if data.border_visible then
    local anchor = parent
    if parentData.regionType == "aurabar" then
      if data.border_anchor == "bar" then
        anchor = parent
      elseif data.border_anchor == "icon" then
        anchor = parent.icon
      elseif data.border_anchor == "fg" then
        anchor = parent.bar.fg
      elseif data.border_anchor == "bg" then
        anchor = parent.bar.bg
      end
    end
    region:SetBackdrop({
      edgeFile = SharedMedia:Fetch("border", data.border_edge) or "",
      edgeSize = data.border_size,
      bgFile = nil,
    });
    region:ClearAllPoints()
    region:SetPoint("bottomleft", anchor, "bottomleft", -data.border_offset, -data.border_offset)
    region:SetPoint("topright",   anchor, "topright",    data.border_offset,  data.border_offset)
    region:SetBackdropBorderColor(data.border_color[1], data.border_color[2], data.border_color[3], data.border_color[4])
    region:SetBackdropColor(0, 0, 0, 0)
    region:Show()
  else
    region:Hide()
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

  region.UpdateAnchor = function() end
  region.Update = function() end
end

local function supports(regionType)
  return regionType == "texture"
         or regionType == "progresstexture"
         or regionType == "icon"
         or regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subborder", L["Border"], supports, create, modify, onAcquire, onRelease, default, nil, properties);
