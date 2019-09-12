if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;
if WeakAuras.IsClassic() then return end -- Models disabled for classic

-- Default settings
local default = {
  model_path = "Creature/Arthaslichking/arthaslichking.m2",
  model_fileId = "122968", -- Creature/Arthaslichking/arthaslichking.m2
  modelIsUnit = false,
  api = false, -- false ==> SetPosition + SetFacing; true ==> SetTransform
  model_x = 0,
  model_y = 0,
  model_z = 0,
  -- SetTransform
  model_st_tx = 0,
  model_st_ty = 0,
  model_st_tz = 0,
  model_st_rx = 270,
  model_st_ry = 0,
  model_st_rz = 0,
  model_st_us = 40,
  width = 200,
  height = 200,
  sequence = 1,
  advance = false,
  rotation = 0,
  scale = 1,
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  frameStrata = 1,
  border = false,
  borderColor = {1.0, 1.0, 1.0, 0.5},
  backdropColor = {1.0, 1.0, 1.0, 0.5},
  borderEdge = "None",
  borderOffset = 5,
  borderInset = 11,
  borderSize = 16,
  borderBackdrop = "Blizzard Tooltip",
};

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  width = {
    display = L["Width"],
    setter = "SetRegionWidth",
    type = "number",
    min = 1,
    softMax = screenWidth,
    bigStep = 1,
    default = 32
  },
  height = {
    display = L["Height"],
    setter = "SetRegionHeight",
    type = "number",
    min = 1,
    softMax = screenHeight,
    bigStep = 1,
    default = 32
  },
}

WeakAuras.regionPrototype.AddProperties(properties, default);

local function GetProperties(data)
  return properties;
end

local regionFunctions = {
  Update = function() end
}

-- Called when first creating a new region/display
local function create(parent)
  -- Main region
  local region = CreateFrame("FRAME", nil, UIParent);
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetMinResize(1, 1);

  -- Border region
  local border = CreateFrame("frame", nil, region);
  region.border = border;

  -- Model display
  local model = CreateFrame("PlayerModel", nil, region);
  model:SetAllPoints(region);
  model:SetCamera(1);

  region.model = model;

  WeakAuras.regionPrototype.create(region);

  for k, v in pairs (regionFunctions) do
    region[k] = v
  end

  -- Return complete region
  return region;
end

-- Modify a given region/display
local function modify(parent, region, data)
  WeakAuras.regionPrototype.modify(parent, region, data);
  -- Localize
  local model, border = region.model, region.border;

  -- Reset position and size
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;

  -- Adjust model
  WeakAuras.SetModel(model, data.model_path, data.model_fileId, data.modelIsUnit, data.modelDisplayInfo)
  model:SetPortraitZoom(data.portraitZoom and 1 or 0);
  if (data.api) then
    model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
      rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz), data.model_st_us / 1000);
  else
    model:ClearTransform();
    model:SetPosition(data.model_z, data.model_x, data.model_y);
  end

  if data.modelIsUnit then
    model:RegisterEvent("UNIT_MODEL_CHANGED");
    if (data.model_fileId == "target") then
      model:RegisterEvent("PLAYER_TARGET_CHANGED");
    elseif (data.model_fileId == "focus") then
      model:RegisterEvent("PLAYER_FOCUS_CHANGED");
    end
    model:SetScript("OnEvent", function(self, event, unitId)
      WeakAuras.StartProfileSystem("model");
      if (event ~= "UNIT_MODEL_CHANGED" or UnitIsUnit(unitId, data.model_fileId)) then
        WeakAuras.SetModel(model, data.model_path, data.model_fileId, data.modelIsUnit, data.modelDisplayInfo)
      end
      WeakAuras.StopProfileSystem("model");
    end
    );
  else
    model:UnregisterEvent("UNIT_MODEL_CHANGED");
    model:UnregisterEvent("PLAYER_TARGET_CHANGED");
    model:UnregisterEvent("PLAYER_FOCUS_CHANGED");
    model:SetScript("OnEvent", nil);
  end

  -- Update border
  if data.border then
    border:SetBackdrop({
      edgeFile = SharedMedia:Fetch("border", data.borderEdge),
      edgeSize = data.borderSize,
      bgFile = SharedMedia:Fetch("background", data.borderBackdrop),
      insets = {
        left     = data.borderInset,
        right     = data.borderInset,
        top     = data.borderInset,
        bottom     = data.borderInset,
      },
    });
    border:SetBackdropBorderColor(data.borderColor[1], data.borderColor[2], data.borderColor[3], data.borderColor[4]);
    border:SetBackdropColor(data.backdropColor[1], data.backdropColor[2], data.backdropColor[3], data.backdropColor[4]);

    border:SetPoint("bottomleft", region, "bottomleft", -data.borderOffset, -data.borderOffset);
    border:SetPoint("topright",   region, "topright",    data.borderOffset,  data.borderOffset);

    border:Show();
  else
    border:Hide();
  end

  -- Enable model animation
  if(data.advance) then
    local elapsed = 0;
    model:SetScript("OnUpdate", function(self, elaps)
      WeakAuras.StartProfileSystem("model");
      elapsed = elapsed + (elaps * 1000);
      model:SetSequenceTime(data.sequence, elapsed);
      WeakAuras.StopProfileSystem("model");
    end)
  else
    model:SetScript("OnUpdate", nil)
  end

  -- Rescale model display
  function region:Scale(scalex, scaley)
    if(scalex < 0) then
      region.mirror_h = true;
      scalex = scalex * -1;
    else
      region.mirror_h = nil;
    end
    region:SetWidth(region.width * scalex);
    if(scaley < 0) then
      scaley = scaley * -1;
      region.mirror_v = true;
    else
      region.mirror_v = nil;
    end
    region:SetHeight(region.height * scaley);
  end

  function region:SetRegionWidth(width)
    region.width = width;
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetRegionHeight(height)
    region.height = height;
    region:Scale(region.scalex, region.scaley);
  end

  -- Roate model
  function region:Rotate(degrees)
    region.rotation = degrees;
    if (data.api) then
      model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
        rad(data.model_st_rx), rad(data.model_st_ry), rad(degrees),
        data.model_st_us / 1000);
    else
      model:SetFacing(rad(region.rotation));
    end
  end
  if (data.api) then
    region:Rotate(data.model_st_rz);
  else
    region:Rotate(data.rotation);
  end

  -- Get model rotation
  function region:GetRotation()
    return region.rotation;
  end

  function region:PreShow()
    model:SetKeepModelOnHide(true)
    model:ClearTransform();

    WeakAuras.SetModel(model, data.model_path, data.model_fileId, data.modelIsUnit, data.modelDisplayInfo)
    model:SetPortraitZoom(data.portraitZoom and 1 or 0);
    if (data.api) then
      model:ClearTransform();
      model:SetPosition(0, 0, 0);
      model:SetTransform(data.model_st_tx / 1000, data.model_st_ty / 1000, data.model_st_tz / 1000,
        rad(data.model_st_rx), rad(data.model_st_ry), rad(data.model_st_rz),
        data.model_st_us / 1000);
    else
      model:ClearTransform();
      model:SetPosition(data.model_z, data.model_x, data.model_y);
    end
  end

  function region:PreHide()
    model:SetKeepModelOnHide(false)
  end

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);
end

-- Work around for movies and world map hiding all models
do
  function WeakAuras.PreShowModels(self, event)
    WeakAuras.StartProfileSystem("model");
    for id, data in pairs(WeakAuras.regions) do
      WeakAuras.StartProfileAura(id);
      if data.region.toShow then
        if (data.regionType == "model") then
          data.region:PreShow();
        end
      end
      WeakAuras.StopProfileAura(id);
    end
    WeakAuras.StopProfileSystem("model");
  end
 end


-- Register new region type with WeakAuras
WeakAuras.RegisterRegionType("model", create, modify, default, GetProperties);
