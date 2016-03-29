local SharedMedia = LibStub("LibSharedMedia-3.0");

-- Credit to CommanderSirow for taking the time to properly craft the ApplyTransform function
-- to the enhance the abilities of Progress Textures.
-- Also Credit to Semlar for explaining how circular progress can be shown

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

  if (region.orientation ~= "CLOCKWISE" and region.orientation ~= "ANTICLOCKWISE") then
    -- Not yet supported for circular progress
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
  else
    x = x / region.scale
    y = y / region.scale
  end

  -- 5) Rotate texture by user-defined value
  --[[local x_tmp = region.cos_rotation * x - region.sin_rotation * y
  local y_tmp = region.sin_rotation * x + region.cos_rotation * y
  x = x_tmp
  y = y_tmp]]
  x, y = region.cos_rotation * x - region.sin_rotation * y, region.sin_rotation * x + region.cos_rotation * y

  -- 6) Translate texture-coords back to (0,0)
  x = x + 0.5
  y = y + 0.5

  if (region.orientation ~= "CLOCKWISE" and region.orientation ~= "ANTICLOCKWISE") then
    x = x + region.user_x
    y = y + region.user_y
  end

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
    startAngle = 0,
    endAngle = 360,
    user_x = 0,
    user_y = 0,
    crop_x = 0.41,
    crop_y = 0.41,
    crop = 0.41,
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

local spinnerFunctions = {};

function spinnerFunctions.SetWidth(self, width)
  self.wedge:SetWidth(width);
end

function spinnerFunctions.SetHeight(self, height)
  self.wedge:SetHeight(height);
end

function spinnerFunctions.SetTexture(self, texture)
  for i = 1, 4 do
    self.circularTextures[i]:SetTexture(texture);
  end
  self.wedge:SetTexture(texture);
end

function spinnerFunctions.SetDesaturated(self, desaturate)
  for i = 1, 4 do
    self.circularTextures[i]:SetDesaturated(desaturate);
  end
  self.wedge:SetDesaturated(desaturate);
end

function spinnerFunctions.SetBlendMode(self, blendMode)
  for i = 1, 4 do
    self.circularTextures[i]:SetBlendMode(blendMode);
  end
  self.wedge:SetBlendMode(blendMode);
end

function spinnerFunctions.Show(self)
  self.wedge:Show();
end

function spinnerFunctions.Hide(self)
  for i = 1, 4 do
    self.circularTextures[i]:Hide();
  end
  self.wedge:Hide();
end

function spinnerFunctions.Color(self, r, g, b, a)
  for i = 1, 4 do
    self.circularTextures[i]:SetVertexColor(r, g, b, a);
  end
  self.wedge:SetVertexColor(r, g, b, a);
end

local function betweenAngles(low, high, needle1, needle2)
  if (low <= needle1 and needle1 <= high
          and low <= needle2 and needle2 <= high) then
      return true;
  end

  needle1 = needle1 + 360;
  needle2 = needle2 + 360;
  if (low <= needle1 and needle1 <= high
          and low <= needle2 and needle2 <= high) then
      return true;
  end
  return false;
end

function spinnerFunctions.SetProgress(self, region, startAngle, endAngle, progress, clockwise)
  local pAngle = progress * (endAngle - startAngle) + startAngle;

  -- Show/hide necessary textures if we need to
  local showing = {};
  for i = 1, 4 do
     local quadrantAngle1;
     local quadrantAngle2;

     if (clockwise) then
        quadrantAngle2 = i * 90;
        quadrantAngle1 = quadrantAngle2 - 90;
     else
        quadrantAngle2 = (5 - i) * 90;
        quadrantAngle1 = quadrantAngle2 - 90;
     end

     if clockwise then
       self.circularTextures[i]:SetShown(betweenAngles(startAngle, pAngle, quadrantAngle1, quadrantAngle2));
       showing[i] = betweenAngles(startAngle, pAngle, quadrantAngle1, quadrantAngle2);
     else
       self.circularTextures[i]:SetShown(betweenAngles(startAngle, pAngle, quadrantAngle1, quadrantAngle2));
       showing[i] = betweenAngles(startAngle, pAngle, quadrantAngle1, quadrantAngle2);
     end
  end

  -- Move scrollframe/wedge to the proper quadrant
  local quadrant = floor(pAngle % 360 / 90) + 1;
  if (not clockwise) then
    quadrant = 5 - quadrant;
  end
  self.scrollframe:SetAllPoints(self.circularTextures[quadrant])

  local ULx, ULy = ApplyTransform(0, 0, region)
  local LLx, LLy = ApplyTransform(0, 1, region)
  local URx, URy = ApplyTransform(1, 0, region)
  local LRx, LRy = ApplyTransform(1, 1, region)

  local Lx, Ly = ApplyTransform(0, 0.5, region)
  local Tx, Ty = ApplyTransform(0.5, 0, region)
  local Bx, By = ApplyTransform(0.5, 1, region)
  local Rx, Ry = ApplyTransform(1, 0.5, region)
  local Cx, Cy = ApplyTransform(0.5, 0.5, region)

  self.circularTextures[1]:SetTexCoord(Tx, Ty, Cx, Cy, URx, URy, Rx, Ry);
  self.circularTextures[2]:SetTexCoord(Cx, Cy, Bx, By, Rx, Ry, LRx, LRy);
  self.circularTextures[3]:SetTexCoord(Lx, Ly, LLx, LLy, Cx, Cy, Bx, By);
  self.circularTextures[4]:SetTexCoord(ULx, ULy, Lx, Ly, Tx, Ty, Cx, Cy);

  local degree = pAngle;
  if not clockwise then degree = -degree + 90 end
  Transform(self.wedge, -0.5, -0.5, degree + region.rotation, region.aspect)
  WeakAuras.animRotate(self.wedge, -degree, "BOTTOMRIGHT");
end

function spinnerFunctions.SetBackgroundOffset(self, region, offset)
    self.circularTextures[1]:SetPoint('TOPRIGHT', region, offset, offset)
    self.circularTextures[2]:SetPoint('BOTTOMRIGHT', region, offset, -offset)
    self.circularTextures[3]:SetPoint('BOTTOMLEFT', region, -offset, -offset)
    self.circularTextures[4]:SetPoint('TOPLEFT', region, -offset, offset)
end

local function createSpinner(parent, layer, frameLevel)
    -- For circular progress
    local scrollframe = CreateFrame('ScrollFrame', nil, parent)
    scrollframe:SetPoint('BOTTOMLEFT', parent, 'CENTER')
    scrollframe:SetPoint('TOPRIGHT')
    scrollframe:SetFrameLevel(frameLevel);

    local scrollchild = CreateFrame('frame', nil, scrollframe)
    scrollframe:SetScrollChild(scrollchild)
    scrollchild:SetAllPoints(scrollframe)
    scrollchild:SetFrameLevel(frameLevel);

    -- Wedge thing
    local wedge = scrollchild:CreateTexture(nil, layer)
    wedge:SetPoint('BOTTOMRIGHT', parent, 'CENTER')

    -- Top Right
    local trTexture = parent:CreateTexture(nil, layer)
    trTexture:SetPoint('BOTTOMLEFT', parent, 'CENTER')
    trTexture:SetPoint('TOPRIGHT')
    trTexture:SetTexCoord(0.5, 1, 0, 0.5)

    -- Bottom Right
    local brTexture = parent:CreateTexture(nil, layer)
    brTexture:SetPoint('TOPLEFT', parent, 'CENTER')
    brTexture:SetPoint('BOTTOMRIGHT')
    brTexture:SetTexCoord(0.5, 1, 0.5, 1)

    -- Bottom Left
    local blTexture = parent:CreateTexture(nil, layer)
    blTexture:SetPoint('TOPRIGHT', parent, 'CENTER')
    blTexture:SetPoint('BOTTOMLEFT')
    blTexture:SetTexCoord(0, 0.5, 0.5, 1)

    -- Top Left
    local tlTexture = parent:CreateTexture(nil, layer)
    tlTexture:SetPoint('BOTTOMRIGHT', parent, 'CENTER')
    tlTexture:SetPoint('TOPLEFT')
    tlTexture:SetTexCoord(0, 0.5, 0, 0.5)

    -- /4|1\ -- Clockwise texture arrangement
    -- \3|2/ --

    local spinner = {};

    spinner.scrollframe = scrollframe
    spinner.wedge = wedge
    spinner.circularTextures = {trTexture, brTexture, blTexture, tlTexture}

    for k, v in pairs(spinnerFunctions) do
      spinner[k] = v;
    end

    return spinner;
end

-- Make available for the Thumbmail display
WeakAuras.createSpinner = createSpinner;

local function create(parent)
    local font = "GameFontHighlight";

    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    region:SetResizable(true);
    region:SetMinResize(1, 1);

    local background = region:CreateTexture(nil, "BACKGROUND");
    region.background = background;

    -- For horizontal/vertical progress
    local foreground = region:CreateTexture(nil, "ARTWORK");
    region.foreground = foreground;

    region.foregroundSpinner = createSpinner(region, "ARTWORK", parent:GetFrameLevel() + 2);
    region.backgroundSpinner = createSpinner(region, "BACKGROUND", parent:GetFrameLevel() + 1);

    region.duration = 0;
    region.expirationTime = math.huge;

    return region;
end

local function modify(parent, region, data)
    local background, foreground = region.background, region.foreground;
    local foregroundSpinner, backgroundSpinner = region.foregroundSpinner, region.backgroundSpinner;

    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

    region:SetWidth(data.width);
    region:SetHeight(data.height);
    region.aspect =  data.width / data.height;
    foreground:SetWidth(data.width);
    foreground:SetHeight(data.height);
    local scaleWedge =  1 / 1.4142 * (1 + (data.crop or 0.41));
    foregroundSpinner:SetWidth(data.width * scaleWedge);
    foregroundSpinner:SetHeight(data.height * scaleWedge);
    backgroundSpinner:SetWidth((data.width + data.backgroundOffset * 2) * scaleWedge);
    backgroundSpinner:SetHeight((data.height + data.backgroundOffset * 2) * scaleWedge);

    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
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
    foreground:SetDesaturated(data.desaturateForeground)
    foreground:SetBlendMode(data.blendMode);

    foregroundSpinner:SetTexture(data.foregroundTexture);
    foregroundSpinner:SetDesaturated(data.desaturateForeground);
    foregroundSpinner:SetBlendMode(data.blendMode);

    background:ClearAllPoints();
    foreground:ClearAllPoints();
    background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", -1 * data.backgroundOffset, -1 * data.backgroundOffset);
    background:SetPoint("TOPRIGHT", region, "TOPRIGHT", data.backgroundOffset, data.backgroundOffset);
    backgroundSpinner:SetBackgroundOffset(region, data.backgroundOffset);

    region.mirror_h = data.mirror;
    region.scale_x = 1 + (data.crop_x or 0.41);
    region.scale_y = 1 + (data.crop_y or 0.41);
    region.scale = 1 + (data.crop or 0.41);
    region.rotation = data.rotation or 0;
    region.cos_rotation = cos(region.rotation);
    region.sin_rotation = sin(region.rotation);
    region.user_x = -1 * (data.user_x or 0);
    region.user_y = data.user_y or 0;

    region.startAngle = data.startAngle or 0;
    region.endAngle = data.endAngle or 360;

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
      local startAngle = region.startAngle % 360; -- Convert 360 to 0
      local endAngle = region.endAngle % 360;

      if (data.inverse) then
        clockwise = not clockwise;
        startAngle = 360 - startAngle;
        endAngle = 360 - endAngle;
      end
      if (endAngle <= startAngle) then
        endAngle = endAngle + 360;
      end

      -- start is now 0-359, end 1-719, but atmost 360 difference

      region.orientation = clockwise and "CLOCKWISE" or "ANTICLOCKWISE";

      backgroundSpinner:SetProgress(region, startAngle, endAngle, 1, clockwise);

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

        local scaleWedge =  1 / 1.4142 * (1 + (data.crop or 0.41));
        foregroundSpinner:SetWidth(data.width * scaleWedge * scalex);
        foregroundSpinner:SetHeight(data.height * scaleWedge * scaley);
        backgroundSpinner:SetWidth((data.width + data.backgroundOffset * 2) * scaleWedge * scalex);
        backgroundSpinner:SetHeight((data.height + data.backgroundOffset * 2) * scaleWedge * scaley);

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
        foregroundSpinner:Color(r, g, b, a);
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
