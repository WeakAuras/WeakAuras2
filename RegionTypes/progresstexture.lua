local SharedMedia = LibStub("LibSharedMedia-3.0");

-- Credit to CommanderSirow for taking the time to properly craft the ApplyTransform function
-- to the enhance the abilities of Progress Textures.

-- NOTES:
--  Most SetValue() changes are quite equal (among compress/non-compress)
--  (There is no GUI button for mirror_v, but mirror_h)
--  New/Used variables
--   region.user_x (0) - User defined center x-shift [-1, 1]
--   region.user_y (0) - User defined center y-shift [-1, 1]
--   region.mirror_v (false) - Mirroring along x-axis [bool]
--   region.mirror_h (false) - Mirroring along y-axis [bool]
--   region.cos_rotation (1) - cos(ANGLE), precalculated cos-function for given ANGLE [-1, 1]
--   region.sin_rotation (0) - sin(ANGLE), precalculated cos-function for given ANGLE [-1, 1]
--   region.scale (1.0) - user defined scaling [1, INF]
--   region.full_rotation (false) - Allow full rotation [bool]


local function ApplyTransform(x, y, region)
  -- 1) Translate texture-coords to user-defined center
  x = x - 0.5
  y = y - 0.5

  -- 2) Shrink texture by 1/sqrt(2)
  x = x * 1.4142
  y = y * 1.4142

  -- 3) Scale texture by user-defined amount
  x = x / region.scale_x
  y = y / region.scale_y

  -- 4) Apply mirroring if defined
  if region.mirror_h then
    x = -x
  end
  if region.mirror_v then
    y = -y
  end

  -- 5) Rotate texture by user-defined value
  --[[local x_tmp = region.cos_rotation * x - region.sin_rotation * y
  local y_tmp = region.sin_rotation * x + region.cos_rotation * y
  x = x_tmp
  y = y_tmp]]
  x, y = region.cos_rotation * x - region.sin_rotation * y, region.sin_rotation * x + region.cos_rotation * y

  -- 6) Translate texture-coords back to (0,0)
  x = x + 0.5 + region.user_x
  y = y + 0.5 + region.user_y

  -- Return results
  return x, y
end


local default = {
    foregroundTexture = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
    backgroundTexture = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
    desaturateBackground = false,
    desaturateForeground = false,
    sameTexture = true,
    compress = false,
    blendMode = "BLEND",
    backgroundOffset = 2,
    width = 200,
    height = 200,
    orientation = "VERTICAL",
    inverse = false,
    alpha = 1.0,
    foregroundColor = {1, 1, 1, 1},
    backgroundColor = {0.5, 0.5, 0.5, 0.5},
    user_x = 0,
    user_y = 0,
    crop_x = 0.41,
    crop_y = 0.41,
    rotation = 0,
    selfPoint = "CENTER",
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0,
    font = "Friz Quadrata TT",
    fontSize = 12,
    stickyDuration = false,
    mirror = false,
    frameStrata = 1
};

local function create(parent)
    local font = "GameFontHighlight";

    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    region:SetResizable(true);
    region:SetMinResize(1, 1);

    local background = region:CreateTexture(nil, "BACKGROUND");
    region.background = background;

    local foreground = region:CreateTexture(nil, "ART");
    region.foreground = foreground;

    region.duration = 0;
    region.expirationTime = math.huge;

    return region;
end

local function modify(parent, region, data)
    local bar, background, foreground, timer = region.bar, region.background, region.foreground, region.timer;

    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

    region:SetWidth(data.width);
    region:SetHeight(data.height);
    foreground:SetWidth(data.width);
    foreground:SetHeight(data.height);

    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
    region:SetAlpha(data.alpha);

    local fontPath = SharedMedia:Fetch("font", data.font);

    background:SetTexture(data.sameTexture and data.foregroundTexture or data.backgroundTexture);
    background:SetDesaturated(data.desaturateBackground)
    background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
    background:SetBlendMode(data.blendMode);

    foreground:SetTexture(data.foregroundTexture);
    foreground:SetDesaturated(data.desaturateForeground)
    foreground:SetBlendMode(data.blendMode);

    background:ClearAllPoints();
    foreground:ClearAllPoints();
    background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", -1 * data.backgroundOffset, -1 * data.backgroundOffset);
    background:SetPoint("TOPRIGHT", region, "TOPRIGHT", data.backgroundOffset, data.backgroundOffset);

    region.mirror_h = data.mirror;
    region.scale_x = 1 + (data.crop_x or 0.41);
    region.scale_y = 1 + (data.crop_y or 0.41);
    region.rotation = data.rotation or 0;
    region.cos_rotation = cos(region.rotation);
    region.sin_rotation = sin(region.rotation);
    region.user_x = -1 * (data.user_x or 0);
    region.user_y = data.user_y or 0;

    local function orientHorizontal()
        foreground:ClearAllPoints();
        foreground:SetPoint("LEFT", region, "LEFT");
        region.orientation = "HORIZONTAL_INVERSE";
        if(data.compress) then
            function region:SetValue(progress)
                region.progress = progress;

                local ULx, ULy = ApplyTransform(0, 0, region)
                local LLx, LLy = ApplyTransform(0, 1, region)
                local URx, URy = ApplyTransform(1, 0, region)
                local LRx, LRy = ApplyTransform(1, 1, region)

                foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
                foreground:SetWidth(region:GetWidth() * progress);
                background:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
            end
        else
            function region:SetValue(progress)
                region.progress = progress;

                local ULx , ULy  = ApplyTransform(0, 0, region)
                local LLx , LLy  = ApplyTransform(0, 1, region)
                local URx , URy  = ApplyTransform(progress, 0, region)
                local URx_, URy_ = ApplyTransform(1, 0, region)
                local LRx , LRy  = ApplyTransform(progress, 1, region)
                local LRx_, LRy_ = ApplyTransform(1, 1, region)

                foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx , URy , LRx , LRy );
                foreground:SetWidth(region:GetWidth() * progress);
                background:SetTexCoord(ULx, ULy, LLx, LLy, URx_, URy_, LRx_, LRy_);
            end
        end
    end
    local function orientHorizontalInverse()
        foreground:ClearAllPoints();
        foreground:SetPoint("RIGHT", region, "RIGHT");
        region.orientation = "HORIZONTAL";
        if(data.compress) then
            function region:SetValue(progress)
                region.progress = progress;

                local ULx, ULy = ApplyTransform(0, 0, region)
                local LLx, LLy = ApplyTransform(0, 1, region)
                local URx, URy = ApplyTransform(1, 0, region)
                local LRx, LRy = ApplyTransform(1, 1, region)

                foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
                foreground:SetWidth(region:GetWidth() * progress);
                background:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
            end
        else
            function region:SetValue(progress)
                region.progress = progress;

                local ULx , ULy  = ApplyTransform(1-progress, 0, region)
                local ULx_, ULy_ = ApplyTransform(0, 0, region)
                local LLx , LLy  = ApplyTransform(1-progress, 1, region)
                local LLx_, LLy_ = ApplyTransform(0, 1, region)
                local URx , URy  = ApplyTransform(1, 0, region)
                local LRx , LRy  = ApplyTransform(1, 1, region)

                foreground:SetTexCoord(ULx , ULy , LLx , LLy , URx, URy, LRx, LRy);
                foreground:SetWidth(region:GetWidth() * progress);
                background:SetTexCoord(ULx_, ULy_, LLx_, LLy_, URx, URy, LRx, LRy);
            end
        end
    end
    local function orientVertical()
        foreground:ClearAllPoints();
        foreground:SetPoint("BOTTOM", region, "BOTTOM");
        region.orientation = "VERTICAL_INVERSE";
        if(data.compress) then
            function region:SetValue(progress)
                region.progress = progress;


                local ULx, ULy = ApplyTransform(0, 0, region)
                local LLx, LLy = ApplyTransform(0, 1, region)
                local URx, URy = ApplyTransform(1, 0, region)
                local LRx, LRy = ApplyTransform(1, 1, region)

                foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
                foreground:SetHeight(region:GetHeight() * progress);
                background:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
            end
        else
            function region:SetValue(progress)
                region.progress = progress;

                local ULx , ULy  = ApplyTransform(0, 1-progress, region)
                local ULx_, ULy_ = ApplyTransform(0, 0, region)
                local LLx , LLy  = ApplyTransform(0, 1, region)
                local URx , URy  = ApplyTransform(1, 1-progress, region)
                local URx_, URy_ = ApplyTransform(1, 0, region)
                local LRx , LRy  = ApplyTransform(1, 1, region)

                foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
                foreground:SetHeight(region:GetHeight() * progress);
                background:SetTexCoord(ULx_, ULy_, LLx, LLy, URx_, URy_, LRx, LRy);
            end
        end
    end
    local function orientVerticalInverse()
        foreground:ClearAllPoints();
        foreground:SetPoint("TOP", region, "TOP");
        region.orientation = "VERTICAL";
        if(data.compress) then
            function region:SetValue(progress)
                region.progress = progress;


                local ULx, ULy = ApplyTransform(0, 0, region)
                local LLx, LLy = ApplyTransform(0, 1, region)
                local URx, URy = ApplyTransform(1, 0, region)
                local LRx, LRy = ApplyTransform(1, 1, region)

                foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
                foreground:SetHeight(region:GetHeight() * progress);
                background:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
            end
        else
            function region:SetValue(progress)
                region.progress = progress;

                local ULx , ULy  = ApplyTransform(0, 0, region)
                local LLx , LLy  = ApplyTransform(0, progress, region)
                local LLx_, LLy_ = ApplyTransform(0, 1, region)
                local URx , URy  = ApplyTransform(1, 0, region)
                local LRx , LRy  = ApplyTransform(1, progress, region)
                local LRx_, LRy_ = ApplyTransform(1, 1, region)

                foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
                foreground:SetHeight(region:GetHeight() * progress);
                background:SetTexCoord(ULx, ULy, LLx_, LLy_, URx, URy, LRx_, LRy_);
            end
        end
    end

    if(data.orientation == "HORIZONTAL_INVERSE") then
        orientHorizontalInverse();
    elseif(data.orientation == "HORIZONTAL") then
        orientHorizontal();
    elseif(data.orientation == "VERTICAL_INVERSE") then
        orientVerticalInverse();
    elseif(data.orientation == "VERTICAL") then
        orientVertical();
    end

    region:SetValue(0.667);

    function region:Scale(scalex, scaley)
        foreground:ClearAllPoints();
        if(scalex < 0) then
            region.mirror_h = not data.mirror;
            scalex = scalex * -1;
        else
            region.mirror_h = data.mirror;
        end
        if(region.mirror_h) then
            if(data.orientation == "HORIZONTAL_INVERSE") then
                foreground:SetPoint("RIGHT", region, "RIGHT");
            elseif(data.orientation == "HORIZONTAL") then
                foreground:SetPoint("LEFT", region, "LEFT");
            end
        else
            if(data.orientation == "HORIZONTAL") then
                foreground:SetPoint("LEFT", region, "LEFT");
            elseif(data.orientation == "HORIZONTAL_INVERSE") then
                foreground:SetPoint("RIGHT", region, "RIGHT");
            end
        end
        if(scaley < 0) then
            region.mirror_v = true;
            scaley = scaley * -1;
            if(data.orientation == "VERTICAL_INVERSE") then
                foreground:SetPoint("TOP", region, "TOP");
            elseif(data.orientation == "VERTICAL") then
                foreground:SetPoint("BOTTOM", region, "BOTTOM");
            end
        else
            region.mirror_v = nil;
            if(data.orientation == "VERTICAL") then
                foreground:SetPoint("BOTTOM", region, "BOTTOM");
            elseif(data.orientation == "VERTICAL_INVERSE") then
                foreground:SetPoint("TOP", region, "TOP");
            end
        end

        region:SetWidth(data.width * scalex);
        region:SetHeight(data.height * scaley);
        if(data.orientation == "HORIZONTAL_INVERSE" or data.orientation == "HORIZONTAL") then
            foreground:SetWidth(data.width * scalex * (region.progress or 1));
            foreground:SetHeight(data.height * scaley);
        else
            foreground:SetWidth(data.width * scalex);
            foreground:SetHeight(data.height * scaley * (region.progress or 1));
        end
        background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", -1 * scalex * data.backgroundOffset, -1 * scaley * data.backgroundOffset);
        background:SetPoint("TOPRIGHT", region, "TOPRIGHT", scalex * data.backgroundOffset, scaley * data.backgroundOffset);
    end

    function region:Rotate(angle)
        region.rotation = angle or 0;
        region.cos_rotation = cos(region.rotation);
        region.sin_rotation = sin(region.rotation);
        region:SetValue(region.progress);
    end

    function region:GetRotation()
        return region.rotation;
    end

    function region:Color(r, g, b, a)
        region.color_r = r;
        region.color_g = g;
        region.color_b = b;
        region.color_a = a;
        foreground:SetVertexColor(r, g, b, a);
    end

    function region:GetColor()
        return region.color_r or data.foregroundColor[1], region.color_g or data.foregroundColor[2],
               region.color_b or data.foregroundColor[3], region.color_a or data.foregroundColor[4];
    end

    region:Color(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);

    local function UpdateTime(self, elaps, inverse)
        local remaining = region.expirationTime - GetTime();
        local progress = remaining / region.duration;

        if((data.inverse and not inverse) or (inverse and not data.inverse)) then
            progress = 1 - progress;
        end
        progress = progress > 0.0001 and progress or 0.0001;
        region:SetValue(progress);
    end

    local function UpdateTimeInverse(self, elaps)
        UpdateTime(self, elaps, true);
    end

    local function UpdateValue(value, total)
        local progress = 1
        if(total > 0) then
            progress = value / total;
        end
        if(data.inverse) then
            progress = 1 - progress;
        end
        progress = progress > 0.0001 and progress or 0.0001;
        region:SetValue(progress);
    end

    local function UpdateCustom()
        UpdateValue(region.customValueFunc(data.trigger));
    end

    function region:SetDurationInfo(duration, expirationTime, customValue, inverse)
        if(duration <= 0.01 or duration > region.duration or not data.stickyDuration) then
            region.duration = duration;
        end
        region.expirationTime = expirationTime;

        if(customValue) then
            if(type(customValue) == "function") then
                local value, total = customValue(data.trigger);
                if(total > 0 and value < total) then
                    region.customValueFunc = customValue;
                    region:SetScript("OnUpdate", UpdateCustom);
                else
                    UpdateValue(duration, expirationTime);
                    region:SetScript("OnUpdate", nil);
                end
            else
                UpdateValue(duration, expirationTime);
                region:SetScript("OnUpdate", nil);
            end
        else
            if(duration > 0.01) then
                if(inverse) then
                    region:SetScript("OnUpdate", UpdateTimeInverse);
                else
                    region:SetScript("OnUpdate", UpdateTime);
                end
            else
                region:SetValue(1);
                region:SetScript("OnUpdate", nil);
            end
        end
    end
end

WeakAuras.RegisterRegionType("progresstexture", create, modify, default);
