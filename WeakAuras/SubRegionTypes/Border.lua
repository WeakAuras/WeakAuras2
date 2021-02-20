if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local baseDefaults = {
  icon = {
    ["type"] = "subborder",
    border_visible = true,
    border_color = {1, 1, 1, 1},
    border_edge = "Square Full White",
    border_offset = 0,
    border_size = 2,
  },
  aurabar = {
    ["type"] = "subborder",
    border_visible = true,
    border_color = {1, 1, 1, 1},
    border_edge = "Square Full White",
    border_offset = 0,
    border_size = 2,
    border_anchor = "bar"
  },
  other = {
    ["type"] = "subborder",
    border_visible = true,
    border_color = {1, 1, 1, 1},
    border_edge = "Square Full White",
    border_offset = 0,
    border_size = 2,
  },
}

local mappings = {
  icon = {
    base = baseDefaults.icon,
    map = {
      [{'subRegion', 'border', 'icon_border_color'}] = "border_color",
      [{'subRegion', 'border', 'icon_border_edge'}] = "border_edge",
      [{'subRegion', 'border', 'icon_border_offset'}] = "border_offset",
      [{'subRegion', 'border', 'icon_border_size'}] = "border_size",
    }
  },
  aurabar = {
    base = baseDefaults.aurabar,
    map = {
      [{'subRegion', 'border', 'aurabar_border_color'}] = "border_color",
      [{'subRegion', 'border', 'aurabar_border_edge'}] = "border_edge",
      [{'subRegion', 'border', 'aurabar_border_offset'}] = "border_offset",
      [{'subRegion', 'border', 'aurabar_border_size'}] = "border_size",
    }
  },
  other = {
    base = baseDefaults.other,
    map = {
      [{'subRegion', 'border', 'other_border_color'}] = "border_color",
      [{'subRegion', 'border', 'other_border_edge'}] = "border_edge",
      [{'subRegion', 'border', 'other_border_offset'}] = "border_offset",
      [{'subRegion', 'border', 'other_border_size'}] = "border_size",
    }
  }
}

local defaultsCache = Private.CreateDefaultsCache(mappings)

local default = function(parentType, action)
  if parentType == "icon" or parentType == "aurabar" then
    return defaultsCache:GetDefault(action, parentType)
  else
    return defaultsCache:GetDefault(action, "other")
  end
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

  parent:AnchorSubRegion(region, "area", parentData.regionType == "aurabar" and data.border_anchor,
                         nil, data.border_offset, data.border_offset)

  local edgeFile = SharedMedia:Fetch("border", data.border_edge)
  if edgeFile and edgeFile ~= "" then
    region:SetBackdrop({
      edgeFile = edgeFile,
      edgeSize = data.border_size,
      bgFile = nil,
    })
    region:SetBackdropBorderColor(data.border_color[1], data.border_color[2],
                                  data.border_color[3], data.border_color[4])
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

local function addDefaultsForNewAura(data)
  local add = false
  if data.regionType == "aurabar" then
    add = select(2, Private.GetDefault('subRegion', 'border', 'aurabar_add'))
  elseif data.regionType == "icon" then
    add = select(2, Private.GetDefault('subRegion', 'border', 'icon_add'))
  else
    add = select(2, Private.GetDefault('subRegion', 'border', 'other_add'))
  end
  if add then
    local border = CopyTable(default(data.regionType, "new"))
    tinsert(data.subRegions, border)
  end
end

local function supports(regionType)
  return regionType == "texture"
         or regionType == "progresstexture"
         or regionType == "icon"
         or regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subborder", L["Border"], supports, create, modify, onAcquire, onRelease,
                                default, addDefaultsForNewAura, properties);
