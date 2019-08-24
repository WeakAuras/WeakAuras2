if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local default = function(parentType)
  return {
    bar_model_visible = true,
    bar_model_alpha = 1,
    api = false,
    model = "235338",
    bar_model_clip = true
  }
end

local properties = {
  bar_model_visible = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool"
  },
  bar_model_alpha = {
    display = L["Alpha"],
    setter = "SetAlpha",
    type = "number",
    min = 0,
    max = 1,
    bigStep = 0.1
  }
}

local function create()
  local subRegion = CreateFrame("FRAME", nil, UIParent)
  subRegion:SetClipsChildren(true)

  local model = CreateFrame("PlayerModel", nil, subRegion)
  subRegion.model = model

  return subRegion
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion:Hide()
end

local noop = function() end

local funcs = {
  SetVisible = function(self, visible)
    if visible then
      self:Show()
    else
      self:Hide()
    end
  end,
  SetAlpha = function(self, alpha)
    self.model:SetModelAlpha(alpha)
  end,
  UpdateAnchor = noop,
  Update = noop
}

local function modify(parent, region, parentData, data, first)
  region:SetParent(parent)
  if data.bar_model_clip then
    region:SetAllPoints(parent.bar.fg)
  else
    region:SetAllPoints(parent.bar)
  end
  region.model:SetAllPoints(parent.bar)

  region.model:SetModel(tonumber(data.model))

  region.PreShow = function(self)
    if not self.model:GetKeepModelOnHide() then
      C_Timer.After(0, function()
          self.model:SetModel(tonumber(data.model))
          self.model:SetKeepModelOnHide(true)
        end)
    end
  end

  for k, v in pairs(funcs) do
    region[k] = v
  end

  region:SetVisible(data.bar_model_visible)
  region:SetAlpha(data.bar_model_alpha)
end

local function supports(regionType)
  return regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subbarmodel", L["Model"], supports, create, modify, onAcquire, onRelease, default, nil, properties);
