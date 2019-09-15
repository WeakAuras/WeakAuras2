if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

if WeakAuras.IsClassic() then return end -- Models disabled for classic

local default = function(parentType)
  return {
    bar_model_visible = true,
    bar_model_alpha = 1,
    api = false,
    model_x = 0,
    model_y = 0,
    model_z = 0,
    rotation = 0,
    -- SetTransform
    model_st_tx = 0,
    model_st_ty = 0,
    model_st_tz = 0,
    model_st_rx = 270,
    model_st_ry = 0,
    model_st_rz = 0,
    model_st_us = 40,

    model_fileId = "235338",
    bar_model_clip = true
  }
end

local properties = {
  bar_model_visible = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
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

  local model = tonumber(data.model_fileId)
  if model then
    region.model:SetModel(model)
  end

  if (data.api) then
    region.model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
      rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz), data.model_st_us / 1000);
  else
    region.model:ClearTransform();
    region.model:SetPosition(data.model_z, data.model_x, data.model_y);
  end

  region.PreShow = function(self)
    if not self.model:GetKeepModelOnHide() and model then
      C_Timer.After(0, function()
          self.model:SetModel(model)
          self.model:SetKeepModelOnHide(true)

          if (data.api) then
            region.model:ClearTransform();
            region.model:SetPosition(0, 0, 0);
            region.model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
              rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz),
              data.model_st_us / 1000);
          else
            region.model:ClearTransform();
            region.model:SetPosition(data.model_z, data.model_x, data.model_y);
          end
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
