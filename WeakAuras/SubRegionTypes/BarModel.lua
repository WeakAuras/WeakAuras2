if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

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
    model_path = "spells/arcanepower_state_chest.m2",
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

local function CreateModel()
  return CreateFrame("PlayerModel", nil, UIParent)
end

-- Keep the two model apis separate
local poolOldApi = CreateObjectPool(CreateModel)
local poolNewApi = CreateObjectPool(CreateModel)

local function AcquireModel(region, data)
  local pool = data.api and poolNewApi or poolOldApi
  local model = pool:Acquire()
  model.api = data.api

  model:ClearAllPoints()

  if region.parentType == "aurabar" then
    model:SetAllPoints(region.parent.bar)
  else
    model:SetAllPoints(region.parent)
  end
  model:SetParent(region)
  model:SetKeepModelOnHide(true)
  model:Show()

  -- Adjust model
  local modelId
  if WeakAuras.IsClassic() then
    modelId = data.model_path
  else
    modelId = tonumber(data.model_fileId)
  end
  if modelId then
    model:SetModel(modelId)
  end

  model:ClearTransform()
  if (data.api) then
    model:MakeCurrentCameraCustom()
    model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
      rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz),
      data.model_st_us / 1000);
  else
    model:SetPosition(data.model_z, data.model_x, data.model_y);
    model:SetFacing(0);
  end
  return model
end

local function ReleaseModel(model)
  model:SetKeepModelOnHide(false)
  model:Hide()
  local pool = model.api and poolNewApi or poolOldApi
  pool:Release(model)
end

local function create()
  local subRegion = CreateFrame("FRAME", nil, UIParent)
  subRegion:SetClipsChildren(true)

  return subRegion
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion:Hide()
end

local funcs = {
  SetVisible = function(self, visible)
    self.visible = visible
    if visible then
      if not self.model then
        self.model = AcquireModel(self, self.data)
        self.model:SetModelAlpha(self.alpha)
      end
      self:Show()
    else
      self:Hide()
      if self.model then
        ReleaseModel(self.model)
        self.model = nil
      end
    end
  end,
  SetAlpha = function(self, alpha)
    if self.model then
      self.model:SetModelAlpha(alpha)
    end
    self.alpha = alpha
  end,
  AlphaChanged = function(self)
    self:SetAlpha(self.alpha)
  end
}

local function modify(parent, region, parentData, data, first)
  if region.model then
    ReleaseModel(region.model)
    region.model = nil
  end

  region.data = data
  region.parentType = parentData.regionType
  region.parent = parent

  region:SetParent(parent)

  if parentData.regionType == "aurabar" then
    if data.bar_model_clip then
      region:SetAllPoints(parent.bar.fgFrame)
    else
      region:SetAllPoints(parent.bar)
    end
  else
    region:SetAllPoints(parent)
  end

  for k, v in pairs(funcs) do
    region[k] = v
  end

  region:SetAlpha(data.bar_model_alpha)
  region:SetVisible(data.bar_model_visible)

  parent.subRegionEvents:AddSubscriber("AlphaChanged", region)
end

local function supports(regionType)
  return regionType == "aurabar" or regionType == "icon"
end

WeakAuras.RegisterSubRegionType("subbarmodel", L["Model"], supports, create, modify, onAcquire, onRelease, default, nil, properties);
