local SharedMedia = LibStub("LibSharedMedia-3.0");

-- GLOBALS: WeakAuras

-- Default settings
local default = {
  icon = true,
  desaturate = false,
  auto = true,
  barInFront = true,
  border = false,
  timer = true,
  text = true,
  stacks = true,
  textColor = {1.0, 1.0, 1.0, 1.0},
  timerColor = {1.0, 1.0, 1.0, 1.0},
  stacksColor = {1.0, 1.0, 1.0, 1.0},
  textFont = "Friz Quadrata TT",
  timerFont = "Friz Quadrata TT",
  stacksFont = "Friz Quadrata TT",
  textSize = 12,
  timerSize = 12,
  stacksSize = 12,
  textFlags = "None",
  timerFlags = "None",
  stacksFlags = "None",
  displayTextRight = "%p",
  displayTextLeft = "%n",
  texture = "Blizzard",
  width = 200,
  height = 15,
  orientation = "HORIZONTAL",
  inverse = false,
  alpha = 1.0,
  barColor = {1.0, 0.0, 0.0, 1.0},
  backgroundColor = {0.0, 0.0, 0.0, 0.5},
  spark = false,
  sparkWidth = 10,
  sparkHeight = 30,
  sparkColor = {1.0, 1.0, 1.0, 1.0},
  sparkTexture = "Interface\\CastingBar\\UI-CastingBar-Spark",
  sparkBlendMode = "ADD",
  sparkDesature = false,
  sparkOffsetX = 0,
  sparkOffsetY = 0,
  sparkRotationMode = "AUTO",
  sparkRotation = 0,
  sparkHidden = "NEVER",
  borderColor = {1.0, 1.0, 1.0, 0.5},
  backdropColor = {1.0, 1.0, 1.0, 0.5},
  borderEdge = "None",
  borderOffset = 5,
  borderInset = 11,
  borderSize = 16,
  borderBackdrop = "Blizzard Tooltip",
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  xOffset = 0,
  yOffset = 0,
  stickyDuration = false,
  icon_side = "RIGHT",
  icon_color = {1.0, 1.0, 1.0, 1.0},
  rotateText = "NONE",
  frameStrata = 1,
  customTextUpdate = "update",
  zoom = 0,
};

-- Returns tex Coord for 90° rotations + x or y flip

local texCoords = { 0, 0, 1, 1,
                    0, 0, 1, 1,
                    0, 0, 1, 1 };

-- only supports multipliers of 90° degree
-- returns in order: TLx, TLy, TRx, TRy, BLx, BLy, BRx, BRy
local GetTexCoord = function(degree, mirror)
    local offset = (degree or 0)/ 90
    local TLx,  TLy = texCoords[2 + offset], texCoords[1 + offset]
    local TRx,  TRy = texCoords[3 + offset], texCoords[2 + offset]
    local BLx,  BLy = texCoords[1 + offset], texCoords[4 + offset]
    local BRx,  BRy = texCoords[4 + offset], texCoords[3 + offset]

    if (mirror) then
        TLx, TRx = TRx, TLx
        TLy, TRy = TRy, TLy
        BLx, BRx = BRx, BLx
        BLy, BRy = BRy, BLy
    end

    return TLx, TLy, TRx, TRy, BLx, BLy, BRx, BRy
end

-- Emulate blizzard statusbar with advanced features (more grow directions)
local barPrototype = {
  -- Apply settings to bar (re-align textures)
  ["Update"] = function(self, OnSizeChanged)
    -- Limit values
    self.value   = math.max(self.min, self.value);
    self.value   = math.min(self.max, self.value);

    -- Alignment variables
    local progress = (self.value - self.min) / (self.max - self.min);
    local align1, align2, alignSpark;
    local xProgress, yProgress, sparkOffset;
    local TLx,  TLy,  BLx,  BLy,  TRx,  TRy,  BRx,  BRy;
    local TLx_, TLy_, BLx_, BLy_, TRx_, TRy_, BRx_, BRy_;
    local sTLx, sTLy, sBLx, sBLy, sTRx, sTRy, sBRx, sBRy; -- spark rotation

    -- Do not flip/rotate textures
    local orientation = self.orientation;
    if not self.rotate then
      if orientation == "HORIZONTAL_INVERSE" then
        orientation = "HORIZONTAL";
      elseif orientation == "VERTICAL_INVERSE" then
        orientation = "VERTICAL";
      end
    end

    -- HORIZONTAL (Grow: L -> R, Deplete: R -> L)
    if orientation == "HORIZONTAL" then
      TLx, TLy, TRx, TRy, BLx, BLy, BRx, BRy = GetTexCoord(0, false)

      TLx_, TLy_ = TLx      , TLy    ; TRx_, TRy_ = TRx*progress    , TRy      ;
      BLx_, BLy_ = BLx      , BLy    ; BRx_, BRy_ = BRx*progress    , BRy      ;

    -- HORIZONTAL_INVERSE (Grow: R -> L, Deplete: L -> R)
    elseif orientation == "HORIZONTAL_INVERSE" then
      TLx, TLy, TRx, TRy, BLx, BLy, BRx, BRy = GetTexCoord(0, true)

      TLx_, TLy_ = TLx*progress  , TLy      ; TRx_, TRy_ = TRx      , TRy      ;
      BLx_, BLy_ = BLx*progress  , BLy      ; BRx_, BRy_ = BRx      , BRy      ;

    -- VERTICAL (Grow: T -> B, Deplete: B -> T)
    elseif orientation == "VERTICAL" then
      TLx, TLy, TRx, TRy, BLx, BLy, BRx, BRy = GetTexCoord(270, false)

      TLx_, TLy_ = TLx           , TLy ; TRx_, TRy_ = TRx           , TRy;
      BLx_, BLy_ = BLx * progress, BLy ; BRx_, BRy_ = BRx * progress, BRy;

    -- VERTICAL_INVERSE (Grow: B -> T, Deplete: T -> B)
    elseif orientation == "VERTICAL_INVERSE" then
      TLx, TLy, TRx, TRy, BLx, BLy, BRx, BRy = GetTexCoord(90, false)

      TLx_, TLy_ = TLx * progress, TLy ; TRx_, TRy_ = TRx * progress, TRy;
      BLx_, BLy_ = BLx           , BLy ; BRx_, BRy_ = BRx           , BRy;
    end

    -- HORIZONTAL (Grow: L -> R, Deplete: R -> L)
    if self.orientation == "HORIZONTAL" then
      align1, align2   = "TOPLEFT", "BOTTOMLEFT";
      alignSpark       = "LEFT";
      xProgress    = self:GetWidth() * progress;
      sparkOffset   = xProgress;

    -- HORIZONTAL_INVERSE (Grow: R -> L, Deplete: L -> R)
    elseif self.orientation == "HORIZONTAL_INVERSE" then
      align1, align2   = "TOPRIGHT", "BOTTOMRIGHT";
      alignSpark       = "RIGHT";
      xProgress    = self:GetWidth() * progress;
      sparkOffset   = -xProgress;

    -- VERTICAL (Grow: T -> B, Deplete: B -> T)
    elseif self.orientation == "VERTICAL" then
      align1, align2   = "TOPLEFT", "TOPRIGHT";
      alignSpark       = "TOP";
      yProgress    = self:GetHeight() * progress;
      sparkOffset   = -yProgress;

    -- VERTICAL_INVERSE (Grow: B -> T, Deplete: T -> B)
    elseif self.orientation == "VERTICAL_INVERSE" then
      align1, align2   = "BOTTOMLEFT", "BOTTOMRIGHT";
      alignSpark       = "BOTTOM";
      yProgress    = self:GetHeight() * progress;
      sparkOffset   = yProgress;
    end

    local sparkMirror = self.spark.sparkMirror;
    local sparkRotationMode = self.spark.sparkRotationMode;
    if (sparkRotationMode == "AUTO") then
        sTLx, sTLy, sBLx, sBLy, sTRx, sTRy, sBRx, sBRy = TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy;
    else
        local sparkRotation = tonumber(self.spark.sparkRotation);
        sTLx, sTLy, sTRx, sTRy, sBLx, sBLy, sBRx, sBRy = GetTexCoord(sparkRotation, sparkMirror)
    end

    -- Only width/height of parent changed
    if not OnSizeChanged then
      -- Stretch bg accross complete frame
      self.bg:ClearAllPoints();
      self.bg:SetAllPoints();
      self.bg:SetTexCoord(TLx , TLy , BLx , BLy , TRx , TRy , BRx , BRy );
      self.spark:SetTexCoord(sTLx , sTLy , sBLx , sBLy , sTRx , sTRy , sBRx , sBRy);

      -- Set alignment
      self.fg:ClearAllPoints();
      self.fg:SetPoint(align1);
      self.fg:SetPoint(align2);

      -- Stretch texture
      self.fg:SetTexCoord(TLx_, TLy_, BLx_, BLy_, TRx_, TRy_, BRx_, BRy_);
     end

    -- Create statusbar illusion
    if xProgress then
      self.fg:SetWidth(xProgress > 0 and xProgress or 0.0001);
      self.spark:ClearAllPoints();
      self.spark:SetPoint("CENTER", self, alignSpark, sparkOffset + (self.spark.sparkOffsetX or 0), self.spark.sparkOffsetY or 0);
    end
    if yProgress then
      self.fg:SetHeight(yProgress > 0 and yProgress or 0.0001);
      self.spark:ClearAllPoints();
      self.spark:SetPoint("CENTER", self, alignSpark, (self.spark.sparkOffsetX or 0), sparkOffset + (self.spark.sparkOffsetY or 0));
    end

    local sparkHidden = self.spark.sparkHidden;
    local sparkVisible = sparkHidden == "NEVER"
                         or (sparkHidden == "FULL" and progress < 1)
                         or (sparkHidden == "EMPTY" and progress > 0)
                         or (sparkHidden == "BOTH" and progress < 1 and progress > 0);
    if (sparkVisible) then
      self.spark:Show();
    else
      self.spark:Hide();
    end
  end,

  -- Need to update progress!
  ["OnSizeChanged"] = function(self, width, height)
    self:Update(true);
  end,

  -- Blizzard like SetMinMaxValues
  ["SetMinMaxValues"] = function(self, minVal, maxVal)
    local update = false;
    if minVal and type(minVal) == "number" then
      self.min   = minVal;
      update    = true;
    end
    if maxVal and type(maxVal) == "number" then
      self.max   = maxVal;
      update    = true;
    end

    if update then
      self:Update();
    end
  end,
  ["GetMinMaxValues"] = function(self)
    return self.min, self.max
  end,

  -- Blizzard like SetValue
  ["SetValue"] = function(self, value)
    if value and type(value) == "number" then
      self.value = value;

      self:Update();
    end
  end,
  ["GetValue"] = function(self)
    return self.value;
  end,

  -- Blizzard like SetOrientation (added: HORIZONTAL_INVERSE, VERTICAL_INVERSE)
  ["SetOrientation"] = function(self, orientation)
    if orientation == "HORIZONTAL"
    or orientation == "HORIZONTAL_INVERSE"
    or orientation == "VERTICAL"
    or orientation == "VERTICAL_INVERSE"
    then
      self.orientation = orientation;

      self:Update();
    end
  end,
  ["GetOrientation"] = function(self)
    return self.orientation;
  end,

  -- Blizzard like SetRotatesTexture (added: flip texture for right->left, bottom->top)
  ["SetRotatesTexture"] = function(self, rotate)
    if rotate and type(rotate) == "boolean" then
      self.rotate = rotate;

      self:Update();
    end
  end,
  ["GetRotatesTexture"] = function(self)
    return self.rotate;
  end,

  -- Blizzard like SetStatusBarTexture
  ["SetStatusBarTexture"] = function(self, texture)
    self.fg:SetTexture(texture);
    self.bg:SetTexture(texture);
  end,
  ["GetStatusBarTexture"] = function(self)
    return self.fg:GetTexture();
  end,

  -- Set bar color
  ["SetForegroundColor"] = function(self, r, g, b, a)
    self.fg:SetVertexColor(r, g, b, a);
  end,
  ["GetForegroundColor"] = function(self)
    return self.fg:GetVertexColor();
  end,

  -- Set background color
  ["SetBackgroundColor"] = function(self, r, g, b, a)
    self.bg:SetVertexColor(r, g, b, a);
  end,
  ["GetBackgroundColor"] = function(self)
    return self.bg:GetVertexColor();
  end,

  -- Convenience methods
  ["SetTexture"] = function(self, texture)
    self:SetStatusBarTexture(texture);
  end,
  ["GetTexture"] = function(self)
    return self:GetStatusBarTexture();
  end,
  ["SetVertexColor"] = function(self, r, g, b, a)
    self:SetForegroundColor(r, g, b, a);
  end,
  ["GetVertexColor"] = function(self)
    return self.fg:GetVertexColor();
  end,

  -- Internal variables
  ["min"]     = 0,
  ["max"]     = 1,
  ["value"]     = 0.5,
  ["rotate"]     = true,
  ["orientation"]  = "HORIZONTAL",
}

-- Called when first creating a new region/display
local function create(parent)
  -- Create overall region (containing everything else)
  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetMinResize(1, 1);

  -- Create statusbar (inherit prototype)
  local bar = CreateFrame("FRAME", nil, region);
  local fg = bar:CreateTexture(nil, "ARTWORK");
  local bg = bar:CreateTexture(nil, "ARTWORK");
  local spark = bar:CreateTexture(nil, "ARTWORK");
  fg:SetDrawLayer("ARTWORK", 2);
  bg:SetDrawLayer("ARTWORK", 1);
  spark:SetDrawLayer("ARTWORK", 3);
  bar.fg = fg;
  bar.bg = bg;
  bar.spark = spark;
  for key, value in pairs(barPrototype) do
    bar[key] = value;
  end
  bar:SetRotatesTexture(true);
  bar:HookScript("OnSizeChanged", bar.OnSizeChanged);
  region.bar = bar;

-- Create border
  local border = CreateFrame("frame", nil, region);
  region.border = border;

-- Create timer text
  local timer = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  region.timer = timer;
  timer:SetText("0.0");
  timer:SetNonSpaceWrap(true);
  timer:SetPoint("center");

-- Create (name) text
  local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  region.text = text;
  text:SetText("Error");
  text:SetNonSpaceWrap(true);
  text:SetPoint("center");

  -- Create icon
  local iconFrame = CreateFrame("FRAME", nil, region);
  region.iconFrame = iconFrame;
  local icon = iconFrame:CreateTexture(nil, "OVERLAY");
  region.icon = icon;
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");

-- Create stack text
  local stacks = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  region.stacks = stacks;
  stacks:SetText(1);
  stacks:ClearAllPoints();
  stacks:SetPoint("CENTER", icon, "CENTER");

-- Region variables
  region.values = {};
  region.duration = 0;
  region.expirationTime = math.huge;

-- Return new display/region
  return region;
end

-- Rotate object around its origin
local function animRotate(object, degrees, anchor)
    if (not anchor) then
        anchor = "CENTER";
    end
  -- Something to rotate
    if object.animationGroup or degrees ~= 0 then
    -- Create AnimatioGroup and rotation animation
        object.animationGroup = object.animationGroup or object:CreateAnimationGroup();
        local group = object.animationGroup;
        group.rotate = group.rotate or group:CreateAnimation("rotation");
        local rotate = group.rotate;

        rotate:SetOrigin(anchor, 0, 0);
        rotate:SetDegrees(degrees);
        rotate:SetDuration(0.000001);
        rotate:SetEndDelay(2147483647);
        group:Play();
    end
end
WeakAuras.animRotate = animRotate;

-- Calculate offset after rotation
local function getRotateOffset(object, degrees, point)
  -- Any rotation at all?
    if degrees ~= 0 then
        -- Basic offset
    local xo, yo;
        local originoffset = object:GetStringHeight() / 2;
        xo = -1 * originoffset * sin(degrees);
        yo = originoffset * (cos(degrees) - 1);

    -- Alignment dependant offset
        if point == "BOTTOM" then
            yo = yo + (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
        elseif point == "TOP" then
            yo = yo - (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
        elseif point == "RIGHT" then
            xo = xo + (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
        elseif point == "LEFT" then
            xo = xo - (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
        end

    -- Done
        return xo, yo;

  -- No rotation
    else
        return 0, 0;
    end
end

-- Orientation helper methods
local function orientHorizontalInverse(region, data)
  -- Localize
  local bar, timer, text, icon = region.bar, region.timer, region.text, region.icon;
  local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  -- Align icon and bar
  if data.icon then
    if data.icon_side == "LEFT" then
      icon:SetPoint("LEFT", region, "LEFT");
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      bar:SetPoint("TOPLEFT", icon, "TOPRIGHT");
    else
      icon:SetPoint("RIGHT", region, "RIGHT");
      bar:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
      bar:SetPoint("TOPRIGHT", icon, "TOPLEFT");
    end
  else
    bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
    bar:SetPoint("TOPLEFT", region, "TOPLEFT");
  end

    -- Save orientation
  region.orientation = "HORIZONTAL_INVERSE";
  bar:SetOrientation(region.orientation);

  -- Temp variable
  local xo, yo;

  -- Align timer text
  xo, yo = getRotateOffset(timer, textDegrees, "LEFT");
  timer:ClearAllPoints();
  timer:SetPoint("LEFT", bar, "LEFT", 2 + xo, 0 + yo);

  -- Align name text
  xo, yo = getRotateOffset(text, textDegrees, "RIGHT");
  text:ClearAllPoints();
  text:SetPoint("RIGHT", bar, "RIGHT", -2 + xo, 0 + yo);

  -- Text internal alignment
  if textDegrees == 0 then
    local usedSpace = timer.visible and (timer:GetWidth() + (data.textSize/2)) or 0;
    text:SetWidth(data.width - usedSpace);
    text:SetJustifyH("RIGHT");
  else
    text:SetWidth(0);
    text:SetJustifyH("CENTER");
  end
end
local function orientHorizontal(region, data)
  -- Localize
  local bar, timer, text, icon = region.bar, region.timer, region.text, region.icon;
  local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  -- Align icon and bar
  if data.icon then
    if data.icon_side == "LEFT" then
      icon:SetPoint("LEFT", region, "LEFT");
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      bar:SetPoint("TOPLEFT", icon, "TOPRIGHT");
    else
      icon:SetPoint("RIGHT", region, "RIGHT");
      bar:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
      bar:SetPoint("TOPRIGHT", icon, "TOPLEFT");
    end
  else
    bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
    bar:SetPoint("TOPLEFT", region, "TOPLEFT");
  end

    -- Save orientation
  region.orientation = "HORIZONTAL";
  bar:SetOrientation(region.orientation);

  -- Temp variable
  local xo, yo;

  -- Align timer text
  xo, yo = getRotateOffset(timer, textDegrees, "RIGHT");
  timer:ClearAllPoints();
  timer:SetPoint("RIGHT", bar, "RIGHT", -2 + xo, 0 + yo);

  -- Align name text
  xo, yo = getRotateOffset(text, textDegrees, "LEFT");
  text:ClearAllPoints();
  text:SetPoint("LEFT", bar, "LEFT", 2 + xo, 0 + yo);

  -- Text internal alignment
  if textDegrees == 0 then
    local usedSpace = timer.visible and (timer:GetWidth() + (data.textSize/2)) or 0;
    text:SetWidth(data.width - usedSpace);
    text:SetJustifyH("LEFT");
  else
    text:SetWidth(0);
    text:SetJustifyH("CENTER");
  end
end
local function orientVerticalInverse(region, data)
  -- Localize
  local bar, timer, text, icon = region.bar, region.timer, region.text, region.icon;
  local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  -- Align icon and bar
  if data.icon then
    if data.icon_side == "LEFT" then
      icon:SetPoint("TOP", region, "TOP");
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
    else
      icon:SetPoint("BOTTOM", region, "BOTTOM");
      bar:SetPoint("TOPRIGHT", region, "TOPRIGHT");
      bar:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
    end
  else
    bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
    bar:SetPoint("TOPLEFT", region, "TOPLEFT");
  end

    -- Save orientation
  region.orientation = "VERTICAL_INVERSE";
  bar:SetOrientation("VERTICAL_INVERSE");

  -- Temp variable
  local xo, yo;

  -- Align timer text
  xo, yo = getRotateOffset(timer, textDegrees, "BOTTOM");
  timer:ClearAllPoints();
  timer:SetPoint("BOTTOM", bar, "BOTTOM", 0 + xo, 2 + yo);

  -- Align name text
  xo, yo = getRotateOffset(text, textDegrees, "TOP");
  text:ClearAllPoints();
  text:SetPoint("TOP", bar, "TOP", 0 + xo, -2 + yo);

  -- Text internal alignment
  text:SetWidth(0);
  text:SetJustifyH("CENTER");
end
local function orientVertical(region, data)
  -- Localize
  local bar, timer, text, icon = region.bar, region.timer, region.text, region.icon;
  local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  -- Align icon and bar
  if data.icon then
    if data.icon_side == "LEFT" then
      icon:SetPoint("TOP", region, "TOP");
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
    else
      icon:SetPoint("BOTTOM", region, "BOTTOM");
      bar:SetPoint("TOPRIGHT", region, "TOPRIGHT");
      bar:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
    end
  else
    bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
    bar:SetPoint("TOPLEFT", region, "TOPLEFT");
  end

  -- Save orientation
  region.orientation = "VERTICAL";
  bar:SetOrientation("VERTICAL");

  -- Temp variable
  local xo, yo;

  -- Align timer text
  xo, yo = getRotateOffset(timer, textDegrees, "TOP");
  timer:ClearAllPoints();
  timer:SetPoint("TOP", bar, "TOP", 0 + xo, -2 + yo);

  -- Align name text
  xo, yo = getRotateOffset(text, textDegrees, "BOTTOM");
  text:ClearAllPoints();
  text:SetPoint("BOTTOM", bar, "BOTTOM", 0 + xo, 2 + yo);

  -- Text internal alignment
  text:SetWidth(0);
  text:SetJustifyH("CENTER");
end
local function orient(region, data)
  -- Apply correct orientation
  if data.orientation == "HORIZONTAL_INVERSE" then
    orientHorizontalInverse(region, data);
  elseif data.orientation == "HORIZONTAL" then
    orientHorizontal(region, data);
  elseif data.orientation == "VERTICAL_INVERSE" then
    orientVerticalInverse(region, data);
  elseif data.orientation == "VERTICAL" then
    orientVertical(region, data);
  end
end

-- Update custom text
local function UpdateText(region, data)
  -- Localize
  local text, timer = region.text, region.timer;
  local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;

  -- Needs re-orientation?
  local shouldOrient = false;
  local textStr

  -- Replace %-marks
  textStr = data.displayTextLeft or "";
  textStr = WeakAuras.ReplacePlaceHolders(textStr, region.values, region.state);

  -- Update left text
  if not text.displayTextLeft or #text.displayTextLeft ~= #textStr then
    shouldOrient = true;
  end
  if text.displayTextLeft ~= textStr then
    text:SetText(textStr);
    text.displayTextLeft = textStr;
  end

  -- Replace %-marks
  textStr = data.displayTextRight or "";
  textStr = WeakAuras.ReplacePlaceHolders(textStr, region.values, region.state);

  -- Update right text
  if not timer.displayTextRight or #timer.displayTextRight ~= #textStr then
    shouldOrient = true;
  end
  if timer.displayTextRight ~= textStr then
    timer:SetText(textStr);
    timer.displayTextRight = textStr;
  end

  -- Re-orientate
  if shouldOrient then
    orient(region, data);
  end
end

-- Update time (status-bar and text)
local function UpdateTime(region, data, inverse)
  -- Timing variables
  local remaining  = region.expirationTime - GetTime();
  local duration  = region.duration;
  local progress  = duration ~= 0 and remaining / duration or 0;

  -- Need to invert?
  if (
      (data.inverse and not inverse)
      or (inverse and not data.inverse)
    )
  then
    progress = 1 - progress;
  end
  region.bar:SetValue(progress);

  -- Format a remaining time string
  local remainingStr     = "";
  if remaining == math.huge then
    remainingStr     = " ";
  elseif remaining > 60 then
    remainingStr     = string.format("%i:", math.floor(remaining / 60));
    remaining       = remaining % 60;
    remainingStr     = remainingStr..string.format("%02i", remaining);
  elseif remaining > 0 then
    -- remainingStr = remainingStr..string.format("%."..(data.progressPrecision or 1).."f", remaining);
    if data.progressPrecision == 4 and remaining <= 3 then
        remainingStr = remainingStr..string.format("%.1f", remaining);
    elseif data.progressPrecision == 5 and remaining <= 3 then
        remainingStr = remainingStr..string.format("%.2f", remaining);
    elseif (data.progressPrecision == 4 or data.progressPrecision == 5) and remaining > 3 then
        remainingStr = remainingStr..string.format("%d", remaining);
    else
        remainingStr = remainingStr..string.format("%."..(data.progressPrecision or 1).."f", remaining);
    end
  else
    remainingStr     = " ";
  end
  region.values.progress   = remainingStr;

  -- Format a duration time string
  local durationStr     = "";
  if duration > 60 then
    durationStr     = string.format("%i:", math.floor(duration / 60));
    duration       = duration % 60;
    durationStr     = durationStr..string.format("%02i", duration);
  elseif duration > 0 then
    -- durationStr = durationStr..string.format("%."..(data.totalPrecision or 1).."f", duration);
    if data.totalPrecision == 4 and duration <= 3 then
        durationStr = durationStr..string.format("%.1f", duration);
    elseif data.totalPrecision == 5 and duration <= 3 then
        durationStr = durationStr..string.format("%.2f", duration);
    elseif (data.totalPrecision == 4 or data.totalPrecision == 5) and duration > 3 then
        durationStr = durationStr..string.format("%d", duration);
    else
        durationStr = durationStr..string.format("%."..(data.totalPrecision or 1).."f", duration);
    end
  else
    durationStr     = " ";
  end
  region.values.duration   = durationStr;

  -- Update text
  UpdateText(region, data);
end
local function UpdateTimeInverse(region, data)
  -- Relay
  UpdateTime(region, data, true);
end

-- Update current state (progress)
local function UpdateValue(region, data, value, total)
  -- Calc progress (percent)
  local progress = 1
  if total > 0 then
    progress = value / total;
  else
        progress = 0;
    end
  if data.inverse then
    progress = 1 - progress;
  end

  -- Save values
  region.values.progress = value;
  region.values.duration = total;
  region.bar:SetValue(progress);

  -- Update text
  UpdateText(region, data);
end

local function GetTexCoordZoom(texWidth)
     local texCoord = {texWidth, texWidth, texWidth, 1 - texWidth, 1 - texWidth, texWidth, 1 - texWidth, 1 - texWidth}
    return unpack(texCoord)
end

-- Modify a given region/display
local function modify(parent, region, data)
  -- Localize
  local bar, border, timer, text, iconFrame, icon, stacks = region.bar, region.border, region.timer, region.text, region.iconFrame, region.icon, region.stacks;

  region.useAuto = data.auto and WeakAuras.CanHaveAuto(data);

  -- Adjust framestrata
    if data.frameStrata == 1 then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

  -- Adjust region size
    region:SetWidth(data.width);
    region:SetHeight(data.height);

  -- Reset anchors
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);

  -- Set overall alpha
    region:SetAlpha(data.alpha);

    -- Update border
  if data.border then
    border:SetBackdrop({
      edgeFile = SharedMedia:Fetch("border", data.borderEdge) or "",
      edgeSize = data.borderSize,
      bgFile = SharedMedia:Fetch("background", data.borderBackdrop) or "",
      insets = {
        left   = data.borderInset,
        right   = data.borderInset,
        top   = data.borderInset,
        bottom   = data.borderInset,
      },
    });
    border:SetPoint("bottomleft", region, "bottomleft", -data.borderOffset, -data.borderOffset);
    border:SetPoint("topright",   region, "topright",    data.borderOffset,  data.borderOffset);
    border:SetBackdropBorderColor(data.borderColor[1], data.borderColor[2], data.borderColor[3], data.borderColor[4]);
    border:SetBackdropColor(data.backdropColor[1], data.backdropColor[2], data.backdropColor[3], data.backdropColor[4]);
    border:Show();
    else
    border:Hide();
  end

  -- Update texture settings
  local texturePath = SharedMedia:Fetch("statusbar", data.texture) or "";
  bar:SetStatusBarTexture(texturePath);
  bar:SetBackgroundColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  -- Update spark settings
  bar.spark:SetTexture(data.sparkTexture);
  bar.spark:SetVertexColor(data.sparkColor[1], data.sparkColor[2], data.sparkColor[3], data.sparkColor[4]); -- TODO introduce function?
  bar.spark:SetWidth(data.sparkWidth);
  bar.spark:SetHeight(data.sparkHeight);
  bar.spark.sparkHidden = data.spark and data.sparkHidden or "ALWAYS";
  bar.spark:SetBlendMode(data.sparkBlendMode);
  bar.spark:SetDesaturated(data.sparkDesaturate);
  bar.spark.sparkOffsetX = data.sparkOffsetX;
  bar.spark.sparkOffsetY = data.sparkOffsetY;
  bar.spark.sparkRotationMode = data.sparkRotationMode;
  bar.spark.sparkRotation = data.sparkRotation;
  bar.spark.sparkMirror = data.sparkMirror;

  -- Bar or Border (+Backdrop) in front
  if data.barInFront then
    iconFrame:SetFrameLevel(5);
    iconFrame:SetFrameLevel(5);
    bar:SetFrameLevel(5);
    border:SetFrameLevel(2);
  else
    iconFrame:SetFrameLevel(2);
    iconFrame:SetFrameLevel(2);
    bar:SetFrameLevel(2);
    border:SetFrameLevel(5);
  end

  -- Color update function
    region.Color = region.Color or function(self, r, g, b, a)
        self.color_r = r;
        self.color_g = g;
        self.color_b = b;
        self.color_a = a;
    self.bar:SetForegroundColor(r, g, b, a);
    end
  region.GetColor = region.GetColor or function(self)
        return   self.color_r,
        self.color_g,
        self.color_b,
        self.color_a;
    end
  region:Color(data.barColor[1], data.barColor[2], data.barColor[3], data.barColor[4]);

  -- Rotate text
    local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;

  -- Update text visibility
  if data.text then
    -- Update text font
    text:SetFont(SharedMedia:Fetch("font", data.textFont), data.textSize, data.textFlags and data.textFlags ~= "None" and data.textFlags);
    text:SetTextHeight(data.textSize);
    text:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);
    text:SetWordWrap(false);
    animRotate(text, textDegrees);
    text:Show();
    text.visible = true;
  else
    text:Hide();
    text.visible = false;
  end

  -- Update timer visibility
  if data.timer then
    -- Update timer font
    timer:SetFont(SharedMedia:Fetch("font", data.timerFont), data.timerSize, data.timerFlags and data.timerFlags ~= "None" and data.timerFlags);
    timer:SetTextHeight(data.timerSize);
    timer:SetTextColor(data.timerColor[1], data.timerColor[2], data.timerColor[3], data.timerColor[4]);
    animRotate(timer, textDegrees);
    timer:Show();
    timer.visible = true;
  else
    timer:Hide();
    timer.visible = false;
  end

  -- Update icon visibility
    if data.icon then
    -- Update icon
    local iconsize = math.min(data.height, data.width);
    icon:SetWidth(iconsize);
    icon:SetHeight(iconsize);
    local texWidth = 0.25 * data.zoom;
    icon:SetTexCoord(GetTexCoordZoom(texWidth))

    -- Icon update function
        function region:SetIcon(path)
      -- Set icon options
            local iconPath = (
                region.useAuto
                and path ~= ""
                and path
                or data.displayIcon
                or "Interface\\Icons\\INV_Misc_QuestionMark"
            );
            self.icon:SetTexture(iconPath);
            self.icon:SetDesaturated(data.desaturate);
            self.icon:SetVertexColor(data.icon_color[1], data.icon_color[2], data.icon_color[3], data.icon_color[4]);
            region.values.icon = "|T"..iconPath..":12:12:0:0:64:64:4:60:4:60|t";

      -- Update text
            UpdateText(self, data);
        end
--    region:SetIcon("");

    -- Update icon visibility
        icon:Show();

    -- Update stack text visibility
    if data.icon and data.stacks then
      -- Update stack font
      stacks:SetFont(SharedMedia:Fetch("font", data.stacksFont), data.stacksSize, data.stacksFlags and data.stacksFlags ~= "None" and data.stacksFlags);
      stacks:SetTextHeight(data.stacksSize);
      stacks:SetTextColor(data.stacksColor[1], data.stacksColor[2], data.stacksColor[3], data.stacksColor[4]);
      animRotate(stacks, textDegrees);

      -- Align text after rotation
      local xo, yo;
      xo, yo = getRotateOffset(stacks, textDegrees, "CENTER");
      stacks:SetPoint("CENTER", icon, "CENTER", xo, yo);

      stacks:Show();
    else
      stacks:Hide();
    end
  --
    else
        stacks:Hide();
        icon:Hide();
    end

  -- Apply orientation alignment
    orient(region, data);

  -- Update tooltip availability
    local tooltipType = WeakAuras.CanHaveTooltip(data);
    if tooltipType and data.useTooltip then
    -- Create and enable tooltip-hover frame
        region.tooltipFrame = region.tooltipFrame or CreateFrame("frame");
        region.tooltipFrame:SetAllPoints(icon);
        region.tooltipFrame:EnableMouse(true);
        region.tooltipFrame:SetScript("OnEnter", function()
            WeakAuras.ShowMouseoverTooltip(region, region.tooltipFrame);
        end);
        region.tooltipFrame:SetScript("OnLeave", WeakAuras.HideTooltip);

  -- Disable tooltip
    elseif region.tooltipFrame then
        region.tooltipFrame:EnableMouse(false);
    end

  -- Look for need to use custom text update
    local customTextFunc = nil
    if (data.displayTextLeft:find("%%c") or data.displayTextRight:find("%%c")) and data.customText then
    -- Load custom code function
        customTextFunc = WeakAuras.LoadFunction("return "..data.customText)
    end
    if (customTextFunc) then
        local values = region.values;

    -- Save custom text function
        region.UpdateCustomText = function()
      -- Evaluate and update text
            WeakAuras.ActivateAuraEnvironment(region.id, region.cloneId, region.state);
            local custom = customTextFunc(region.expirationTime, region.duration,
              values.progress, values.duration, values.name, values.icon, values.stacks);
            WeakAuras.ActivateAuraEnvironment(nil);
            custom = WeakAuras.EnsureString(custom);
            if custom ~= values.custom then
                values.custom = custom;
                UpdateText(region, data);
            end
        end

    -- Add/Remove custom text update
        if data.customTextUpdate == "update" then
            WeakAuras.RegisterCustomTextUpdates(region);
        else
            WeakAuras.UnregisterCustomTextUpdates(region);
        end

  -- Remove custom text update
    else
        region.UpdateCustomText = nil;
        WeakAuras.UnregisterCustomTextUpdates(region);
    end

  -- Stack update function
    function region:SetStacks(count)
    -- Update text content
        if count and count > 0 then
            self.values.stacks = count;
            self.stacks:SetText(count);
        else
            self.values.stacks = 0;
           self.stacks:SetText("");
        end
        UpdateText(self, data);
    end
--  region:SetStacks();

  -- Scale update function
    function region:Scale(scalex, scaley)
    -- Icon size
    local iconsize = math.min(data.height, data.width);

    -- Re-orientate region
        if scalex < 0 then
            scalex = -scalex;
            if data.orientation == "HORIZONTAL" then
                if self.orientation ~= "HORIZONTAL_INVERSE" then
                    orientHorizontalInverse(self, data);
                end
            elseif data.orientation == "HORIZONTAL_INVERSE" then
                if self.orientation ~= "HORIZONTAL" then
                    orientHorizontal(self, data);
                end
            end
        else
            if data.orientation == "HORIZONTAL" then
                if self.orientation ~= "HORIZONTAL" then
                    orientHorizontal(self, data);
                end
            elseif data.orientation == "HORIZONTAL_INVERSE" then
                if self.orientation ~= "HORIZONTAL_INVERSE" then
                    orientHorizontalInverse(self, data);
                end
            end
        end

    -- Update width
        self:SetWidth(data.width * scalex);
        icon:SetWidth(iconsize * scalex);

    -- Re-orientate region
        if scaley < 0 then
            scaley = -scaley;
            if data.orientation == "VERTICAL" then
                if self.orientation ~= "VERTICAL_INVERSE" then
                    orientVerticalInverse(self, data);
                end
            elseif data.orientation == "VERTICAL_INVERSE" then
                if self.orientation ~= "VERTICAL" then
                    orientVertical(self, data);
                end
            end
        else
            if data.orientation == "VERTICAL" then
                if self.orientation ~= "VERTICAL" then
                    orientVertical(self, data);
                end
            elseif data.orientation == "VERTICAL_INVERSE" then
                if self.orientation ~= "VERTICAL_INVERSE" then
                    orientVerticalInverse(self, data);
                end
            end
        end

    -- Update height
        self:SetHeight(data.height * scaley);
        icon:SetHeight(iconsize * scaley);
    end
--  region:Scale(1.0, 1.0);

  -- Name update function
    function region:SetName(name)
        region.values.name = name or data.id;
        UpdateText(self, data);
    end
--  region:SetName("");

    function region:OnUpdateHandler()
        local value, total = self.customValueFunc(self.state.trigger);
        value = type(value) == "number" and value or 0
        total = type(value) == "number" and total or 0
        UpdateValue(self, data, value, total);
    end

  -- Duration update function
    function region:SetDurationInfo(duration, expirationTime, customValue, inverse)
    -- Update duration/expiration values
        if duration <= 0 or duration > self.duration or not data.stickyDuration then
            self.duration = duration;
        end
        self.expirationTime = expirationTime;

    -- Use custom OnUpdate handler
        if customValue then
      -- Update via custom OnUpdate handler
            if type(customValue) == "function" then
                local value, total = customValue(region.state.trigger);
                value = type(value) == "number" and value or 0
                total = type(value) == "number" and total or 0
                if total > 0 and value < total then
                  self.customValueFunc = customValue;
                  self:SetScript("OnUpdate", region.OnUpdateHandler);
                else
                  UpdateValue(self, data, duration, expirationTime);
                  self:SetScript("OnUpdate", nil);
                end
      -- Remove OnUpdate handler, call update once
            else
                UpdateValue(self, data, duration, expirationTime);
                self:SetScript("OnUpdate", nil);
            end
    -- Use default OnUpdate handler
        else
      -- Enable OnUpdate script
            if duration > 0 then
                if inverse then
                    self:SetScript("OnUpdate", function() UpdateTimeInverse(self, data) end);
                else
                    self:SetScript("OnUpdate", function() UpdateTime(self, data, inverse) end);
                end
      -- Reset to full
            else
                bar:SetValue(1);
                self:SetScript("OnUpdate", nil);
                UpdateTime(self, data, inverse);
            end
        end
    end
--  region:SetDurationInfo(1, 0, nil, nil);

  -- Update internal bar alignment
  region.bar:Update();
end

-- Register new region type with WeakAuras
WeakAuras.RegisterRegionType("aurabar", create, modify, default);
