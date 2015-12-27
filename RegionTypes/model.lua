-- Import SM for statusbar-textures, font-styles and border-types
local SharedMedia = LibStub("LibSharedMedia-3.0");

-- Default settings
local default = {
    model_path             = "Creature/Arthaslichking/arthaslichking.m2",
    modelIsUnit         = false,
    model_x             = 0,
    model_y             = 0,
    model_z             = 0,
    width                 = 200,
    height                 = 200,
    sequence             = 1,
    advance             = false,
    rotation             = 0,
    scale                 = 1,
    selfPoint             = "CENTER",
    anchorPoint         = "CENTER",
    xOffset             = 0,
    yOffset             = 0,
    frameStrata         = 1,
    border                = false,
    borderColor         = {1.0, 1.0, 1.0, 0.5},
    backdropColor        = {1.0, 1.0, 1.0, 0.5},
    borderEdge            = "None",
    borderOffset         = 5,
    borderInset            = 11,
    borderSize            = 16,
    borderBackdrop        = "Blizzard Tooltip",
};

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
    region.model = model;

    -- Return complete region
    return region;
end

-- Modify a given region/display
local function modify(parent, region, data)
    -- Localize
    local model, border = region.model, region.border;

    -- Adjust framestrata
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

    -- Reset position and size
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
    region:SetWidth(data.width);
    region:SetHeight(data.height);

    -- Adjust model
    local register = false;
    if tonumber(data.model_path) then
        model:SetDisplayInfo(tonumber(data.model_path))
    else
        if (data.modelIsUnit) then
            model:SetUnit(data.model_path)
            register = true;
            model:SetPortraitZoom(data.portraitZoom and 1 or 0);
        else
            pcall(function() model:SetModel(data.model_path) end);
        end
    end
    model:SetPosition(data.model_z, data.model_x, data.model_y);

    if (register) then
        model:RegisterEvent("UNIT_MODEL_CHANGED");
        if (data.model_path == "target") then
          model:RegisterEvent("PLAYER_TARGET_CHANGED");
        elseif (data.model_path == "focus") then
          model:RegisterEvent("PLAYER_FOCUS_CHANGED");
        end
        model:SetScript("OnEvent", function(self, event, unitId)
          if (event ~= "UNIT_MODEL_CHANGED" or UnitIsUnit(unitId, data.model_path)) then
            model:SetUnit(data.model_path);
          end
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
            elapsed = elapsed + (elaps * 1000);
            model:SetSequenceTime(data.sequence, elapsed);
        end);
    else
        model:SetScript("OnUpdate", nil);
    end

    -- Rescale model display
    function region:Scale(scalex, scaley)
        if(scalex < 0) then
            region.mirror_h = true;
            scalex = scalex * -1;
        else
            region.mirror_h = nil;
        end
        region:SetWidth(data.width * scalex);
        if(scaley < 0) then
            scaley = scaley * -1;
            region.mirror_v = true;
        else
            region.mirror_v = nil;
        end
        region:SetHeight(data.height * scaley);
    end

    -- Roate model
    function region:Rotate(degrees)
        region.rotation = degrees;
        model:SetFacing(rad(region.rotation));
    end
    region:Rotate(data.rotation);

    -- Get model rotation
    function region:GetRotation()
        return region.rotation;
    end

    -- Ensure using correct model
    function region:PreShow()
--        if(type(model:GetModel()) ~= "string") then
            if tonumber(data.model_path) then
                model:SetDisplayInfo(tonumber(data.model_path))
            else
                if (data.modelIsUnit) then
                    model:SetUnit(data.model_path)
                else
                    pcall(function() model:SetModel(data.model_path) end);
                end
            end
--        end
    end
end

-- Register new region type with WeakAuras
WeakAuras.RegisterRegionType("model", create, modify, default);

-- Work around for movies and world map hiding all models
do
  local function preShowModels()
    for id, isLoaded in pairs(WeakAuras.loaded) do
      if (isLoaded) then
        local data = WeakAuras.regions[id];
        if (data.regionType == "model") then
          data.region:PreShow();
        end
      end
    end
  end

  local movieWatchFrame;
  movieWatchFrame = CreateFrame("frame");
  movieWatchFrame:RegisterEvent("PLAY_MOVIE");

  movieWatchFrame:SetScript("OnEvent", preShowModels);
  WeakAuras.frames["Movie Watch Frame"] = movieWatchFrame;

  hooksecurefunc(WorldMapFrame, "Hide", preShowModels);
end