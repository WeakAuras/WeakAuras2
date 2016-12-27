local L = WeakAuras.L;

-- GLOBALS: WeakAuras UIParent AceGUIWidgetLSMlists

local function createOptions(id, data)
    local options = {
        foregroundTexture = {
            type = "input",
            name = L["Foreground Texture"],
            order = 0
        },
        backgroundTexture = {
            type = "input",
            name = L["Background Texture"],
            order = 5,
            disabled = function() return data.sameTexture; end,
            get = function() return data.sameTexture and data.foregroundTexture or data.backgroundTexture; end
        },
        mirror = {
            type = "toggle",
            width = "half",
            name = L["Mirror"],
            order = 10,
            disabled = function() return data.orientation == "CLOCKWISE" or data.orientation == "ANTICLOCKWISE"; end
        },
        chooseForegroundTexture = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            order = 12,
            func = function()
                WeakAuras.OpenTexturePick(data, "foregroundTexture", WeakAuras.texture_types);
            end
        },
        sameTexture = {
            type = "toggle",
            name = L["Same"],
            width = "half",
            order = 15
        },
        chooseBackgroundTexture = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            order = 17,
            func = function()
                WeakAuras.OpenTexturePick(data, "backgroundTexture", WeakAuras.texture_types);
            end,
            disabled = function() return data.sameTexture; end
        },
		desaturateForeground = {
            type = "toggle",
            name = L["Desaturate"],
            order = 17.5,
        },
		desaturateBackground = {
            type = "toggle",
            name = L["Desaturate"],
            order = 17.6,
        },
        blendMode = {
            type = "select",
            name = L["Blend Mode"],
            order = 20,
            values = WeakAuras.blend_types
        },
        backgroundOffset = {
            type = "range",
            name = L["Background Offset"],
            min = 0,
            softMax = 25,
            bigStep = 1,
            order = 25
        },
        orientation = {
            type = "select",
            name = L["Orientation"],
            order = 35,
            values = WeakAuras.orientation_with_circle_types
        },
        compress = {
            type = "toggle",
            width = "half",
            name = L["Compress"],
            order = 40,
            disabled = function() return data.orientation == "CLOCKWISE" or data.orientation == "ANTICLOCKWISE"; end
        },
        inverse = {
            type = "toggle",
            width = "half",
            name = L["Inverse"],
            order = 41
        },
        foregroundColor = {
            type = "color",
            name = L["Foreground Color"],
            hasAlpha = true,
            order = 30
        },
        backgroundColor = {
            type = "color",
            name = L["Background Color"],
            hasAlpha = true,
            order = 37
        },
        user_x = {
            type = "range",
            order = 42,
            name = L["Re-center X"],
            min = -0.5,
            max = 0.5,
            bigStep = 0.01,
            hidden = function() return data.orientation == "CLOCKWISE" or data.orientation == "ANTICLOCKWISE"; end
        },
        user_y = {
            type = "range",
            order = 44,
            name = L["Re-center Y"],
            min = -0.5,
            max = 0.5,
            bigStep = 0.01,
            hidden = function() return data.orientation == "CLOCKWISE" or data.orientation == "ANTICLOCKWISE"; end
        },
        startAngle = {
            type = "range",
            order = 42,
            name = function() if (data.inverse) then return L["End Angle"] else return L["Start Angle"] end end,
            min = 0,
            max = 360,
            step = 90,
            hidden = function() return data.orientation ~= "CLOCKWISE" and data.orientation ~= "ANTICLOCKWISE"; end
        },
        endAngle = {
            type = "range",
            order = 44,
            name = function() if (data.inverse) then return L["Start Angle"] else return L["End Angle"] end end,
            min = 0,
            max = 360,
            bigStep = 1,
            hidden = function() return data.orientation ~= "CLOCKWISE" and data.orientation ~= "ANTICLOCKWISE"; end
        },
        crop_x = {
            type = "range",
            name = L["Crop X"],
            order = 46,
            min = 0,
            softMax = 2,
            bigStep = 0.01,
            isPercent = true,
            set = function(info, v)
                data.width = data.width * ((1 + data.crop_x) / (1 + v));
                data.crop_x = v;
                WeakAuras.Add(data);
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
                if(data.parent) then
                    local parentData = WeakAuras.GetData(data.parent);
                    if(parentData) then
                        WeakAuras.Add(parentData);
                        WeakAuras.SetThumbnail(parentData);
                    end
                end
                WeakAuras.ResetMoverSizer();
            end,
            hidden = function() return data.orientation == "CLOCKWISE" or data.orientation == "ANTICLOCKWISE"; end
        },
        crop_y = {
            type = "range",
            name = L["Crop Y"],
            order = 47,
            min = 0,
            softMax = 2,
            bigStep = 0.01,
            isPercent = true,
            set = function(info, v)
                data.height = data.height * ((1 + data.crop_y) / (1 + v));
                data.crop_y = v;
                WeakAuras.Add(data);
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
                if(data.parent) then
                    local parentData = WeakAuras.GetData(data.parent);
                    if(parentData) then
                        WeakAuras.Add(parentData);
                        WeakAuras.SetThumbnail(parentData);
                    end
                end
                WeakAuras.ResetMoverSizer();
            end,
            hidden = function() return data.orientation == "CLOCKWISE" or data.orientation == "ANTICLOCKWISE"; end
        },
        crop = {
            type = "range",
            name = L["Crop"],
            order = 47,
            min = 0,
            softMax = 2,
            bigStep = 0.01,
            isPercent = true,
            set = function(info, v)
                data.height = data.height * ((1 + data.crop or 0) / (1 + v));
                data.width = data.width * ((1 + data.crop or 0) / (1 + v));
                data.crop = v;
                WeakAuras.Add(data);
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
                if(data.parent) then
                    local parentData = WeakAuras.GetData(data.parent);
                    if(parentData) then
                        WeakAuras.Add(parentData);
                        WeakAuras.SetThumbnail(parentData);
                    end
                end
                WeakAuras.ResetMoverSizer();
            end,
            hidden = function() return data.orientation ~= "CLOCKWISE" and data.orientation ~= "ANTICLOCKWISE"; end
        },
        rotation = {
            type = "range",
            name = L["Rotation"],
            order = 52,
            min = 0,
            max = 360,
            bigStep = 1
        },
        alpha = {
            type = "range",
            name = L["Alpha"],
            order = 48,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true
        },
        stickyDuration = {
            type = "toggle",
            name = L["Sticky Duration"],
            desc = L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."],
            order = 55
        },
        spacer = {
            type = "header",
            name = "",
            order = 60
        }
    };
    options = WeakAuras.AddPositionOptions(options, id, data);

    return options;
end

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

local function Transform(tx, x, y, angle, aspect) -- Translates texture to x, y and rotates about its center
    local c, s = cos(angle), sin(angle)
    local y, oy = y / aspect, 0.5 / aspect
    local ULx, ULy = 0.5 + (x - 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x - 0.5) * s) * aspect
    local LLx, LLy = 0.5 + (x - 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x - 0.5) * s) * aspect
    local URx, URy = 0.5 + (x + 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x + 0.5) * s) * aspect
    local LRx, LRy = 0.5 + (x + 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x + 0.5) * s) * aspect
    tx:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end

local function createThumbnail(parent, fullCreate)
    local borderframe = CreateFrame("FRAME", nil, parent);
    borderframe:SetWidth(32);
    borderframe:SetHeight(32);

    local border = borderframe:CreateTexture(nil, "OVERLAY");
    border:SetAllPoints(borderframe);
    border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
    border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

    local region = CreateFrame("FRAME", nil, borderframe);
    borderframe.region = region;
    region:SetWidth(32);
    region:SetHeight(32);

    local background = region:CreateTexture(nil, "BACKGROUND");
    borderframe.background = background;

    local foreground = region:CreateTexture(nil, "ART");
    borderframe.foreground = foreground;

    borderframe.foregroundSpinner = WeakAuras.createSpinner(borderframe, "ARTWORK", parent:GetFrameLevel() + 2);
    borderframe.backgroundSpinner = WeakAuras.createSpinner(borderframe, "BACKGROUND", parent:GetFrameLevel() + 1);

    return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, size)
    local region, background, foreground = borderframe.region, borderframe.background, borderframe.foreground;
    local foregroundSpinner, backgroundSpinner = borderframe.foregroundSpinner, borderframe.backgroundSpinner;

    size = size or 30;
    local scale;
    if(data.height > data.width) then
        scale = size/data.height;
        region:SetWidth(scale * data.width);
        region:SetHeight(size);
        foreground:SetWidth(scale * data.width);
        foreground:SetHeight(size);
        foregroundSpinner:SetWidth(scale * data.width);
        foregroundSpinner:SetHeight(size);
        backgroundSpinner:SetWidth(scale * data.width)
        backgroundSpinner:SetHeight(size);
    else
        scale = size/data.width;
        region:SetWidth(size);
        region:SetHeight(scale * data.height);
        foreground:SetWidth(size);
        foreground:SetHeight(scale * data.height);
        foregroundSpinner:SetWidth(size);
        foregroundSpinner:SetHeight(scale * data.height);
        backgroundSpinner:SetWidth(size)
        backgroundSpinner:SetHeight(scale * data.height);
    end

    region:ClearAllPoints();
    region:SetPoint("CENTER", borderframe, "CENTER");
    region:SetAlpha(data.alpha);

    background:SetTexture(data.sameTexture and data.foregroundTexture or data.backgroundTexture);
    background:SetDesaturated(data.desaturateBackground)
    background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
    background:SetBlendMode(data.blendMode);

    backgroundSpinner:SetTexture(data.sameTexture and data.foregroundTexture or data.backgroundTexture);
    backgroundSpinner:SetDesaturated(data.desaturateBackground)
    backgroundSpinner:Color(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
    backgroundSpinner:SetBlendMode(data.blendMode);

    foreground:SetTexture(data.foregroundTexture);
    foreground:SetVertexColor(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);
    foreground:SetBlendMode(data.blendMode);

    foregroundSpinner:SetTexture(data.foregroundTexture);
    foregroundSpinner:SetDesaturated(data.desaturateForeground);
    foregroundSpinner:SetBlendMode(data.blendMode);
    foregroundSpinner:Color(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4])

    background:ClearAllPoints();
    foreground:ClearAllPoints();
    background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
    background:SetPoint("TOPRIGHT", region, "TOPRIGHT");
    backgroundSpinner:SetBackgroundOffset(region, 0);

    region.mirror_h = data.mirror;
    region.scale_x = 1 + (data.crop_x or 0.41);
    region.scale_y = 1 + (data.crop_y or 0.41);
    region.rotation = data.rotation or 0;
    region.cos_rotation = cos(region.rotation);
    region.sin_rotation = sin(region.rotation);
    region.user_x = -1 * (data.user_x or 0);
    region.user_y = data.user_y or 0;
    region.aspect = 1;

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

    local function orientCircular(clockwise)
      local startAngle = data.startAngle % 360;
      local endAngle = data.endAngle % 360;

      if (data.inverse) then
        startAngle, endAngle = endAngle, startAngle
        startAngle = 360 - startAngle;
        endAngle = 360 - endAngle;
        clockwise = not clockwise;
      end
      if (endAngle <= startAngle) then
        endAngle = endAngle + 360;
      end

      backgroundSpinner:SetProgress(region, startAngle, endAngle, 0, clockwise);

      function region:SetValue(progress)
        progress = progress or 0;
        region.progress = progress;

        foregroundSpinner:SetProgress(region, startAngle, endAngle, progress, clockwise);
      end
    end

    local function showCircularProgress()
      foreground:Hide();
      background:Hide();
      foregroundSpinner:Show();
      backgroundSpinner:Show();
    end

    local function hideCircularProgress()
      foreground:Show();
      background:Show();
      foregroundSpinner:Hide();
      backgroundSpinner:Hide();
    end

    if(data.orientation == "HORIZONTAL_INVERSE") then
        hideCircularProgress();
        orientHorizontalInverse();
    elseif(data.orientation == "HORIZONTAL") then
        hideCircularProgress();
        orientHorizontal();
    elseif(data.orientation == "VERTICAL_INVERSE") then
        hideCircularProgress();
        orientVerticalInverse();
    elseif(data.orientation == "VERTICAL") then
        hideCircularProgress();
        orientVertical();
    elseif(data.orientation == "CLOCKWISE") then
        showCircularProgress();
        orientCircular(true);
    elseif(data.orientation == "ANTICLOCKWISE") then
        showCircularProgress();
        orientCircular(false);
    end

    if (region.SetValue) then
      region:SetValue(3/5);
    end
end

local function createIcon()
    local data = {
        foregroundTexture = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
        sameTexture = true,
        backgroundOffset = 2,
        blendMode = "BLEND",
        width = 200,
        height = 200,
        orientation = "VERTICAL",
        alpha = 1.0,
        foregroundColor = {1, 1, 1, 1},
        backgroundColor = {0.5, 0.5, 0.5, 0.5}
    };

    local thumbnail = createThumbnail(UIParent);
    modifyThumbnail(UIParent, thumbnail, data, nil, 32);

    thumbnail.elapsed = 0;
    thumbnail:SetScript("OnUpdate", function(self, elapsed)
        thumbnail.elapsed = thumbnail.elapsed + elapsed;
        if(thumbnail.elapsed > 4) then
            thumbnail.elapsed = thumbnail.elapsed - 4;
        end
        thumbnail.region:SetValue((4 - thumbnail.elapsed) / 4);
    end);

    return thumbnail;
end

local templates = {
  {
    title = L["Default"],
    data = {
    };
  },
  {
    title = L["Top HUD position"],
    description = L["At the same position as Blizzard's spell alert"],
    data = {
      width = 200,
      height = 100,
      xOffset = 0,
      yOffset = 150,
      mirror = true,
      foregroundTexture = "Textures\\SpellActivationOverlays\\Backlash",
      orientation = "HORIZONTAL",
    },
  },
  {
    title = L["Left HUD position"],
    description = L["At the same position as Blizzard's spell alert"],
    data = {
      width = 100,
      height = 200,
      xOffset = -150,
      yOffset = 0,
    },
  },
  {
    title = L["Left 2 HUD position"],
    description = L["At a position a bit left of Left HUD position."],
    data = {
      width = 100,
      height = 200,
      xOffset = -200,
      yOffset = 0,
    },
  },
  {
    title = L["Right HUD position"],
    description = L["At the same position as Blizzard's spell alert"],
    data = {
      width = 100,
      height = 200,
      xOffset = 150,
      yOffset = 0,
      mirror = true,
    },
  },
  {
    title = L["Right 2 HUD position"],
    description = L["At a position a bit left of Right HUD position"],
    data = {
      width = 100,
      height = 200,
      xOffset = 200,
      yOffset = 0,
      mirror = true,
    },
  },
}

WeakAuras.RegisterRegionOptions("progresstexture", createOptions, createIcon, L["Progress Texture"], createThumbnail, modifyThumbnail, L["Shows a texture that changes based on duration"], templates);
