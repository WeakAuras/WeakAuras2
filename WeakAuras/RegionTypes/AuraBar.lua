local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

-- Default settings
local default = {
  icon = true,
  desaturate = false,
  auto = true,
  borderInFront = true,
  backdropInFront = false,
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
  barColor = {1.0, 0.0, 0.0, 1.0},
  backgroundColor = {0.0, 0.0, 0.0, 0.5},
  spark = false,
  sparkWidth = 10,
  sparkHeight = 30,
  sparkColor = {1.0, 1.0, 1.0, 1.0},
  sparkTexture = "Interface\\CastingBar\\UI-CastingBar-Spark",
  sparkBlendMode = "ADD",
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
  anchorFrameType = "SCREEN",
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

WeakAuras.regionPrototype.AddAdjustedDurationToDefault(default);
WeakAuras.regionPrototype.AddAlphaToDefault(default);

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  barColor = {
    display = L["Bar Color"],
    setter = "Color",
    type = "color",
  },
  icon_color = {
    display = L["Icon Color"],
    setter = "SetIconColor",
    type = "color"
  },
  desaturate = {
    display = L["Icon Desaturate"],
    setter = "SetIconDesaturated",
    type = "bool",
  },
  backgroundColor = {
    display = L["Background Color"],
    setter = "SetBackgroundColor",
    type = "color"
  },
  sparkColor = {
    display = L["Spark Color"],
    setter = "SetSparkColor",
    type = "color"
  },
  sparkHeight = {
    display = L["Spark Height"],
    setter = "SetSparkHeight",
    type = "number",
    min = 1,
    softMax = screenHeight,
    bigStep = 1
  },
  sparkWidth = {
    display = L["Spark Width"],
    setter = "SetSparkWidth",
    type = "number",
    min = 1,
    softMax = screenWidth,
    bigStep = 1
  },
  borderColor = {
    display = L["Border Color"],
    setter = "SetBorderColor",
    type = "color"
  },
  backdropColor = {
    display = L["Backdrop Color"],
    setter = "SetBackdropColor",
    type = "color"
  },
  textColor = {
    display = L["First Text Color"],
    setter = "SetTextColor",
    type = "color"
  },
  timerColor = {
    display = L["Second Text Color"],
    setter = "SetTimerColor",
    type = "color"
  },
  stacksColor = {
    display = L["Stacks Text Color"],
    setter = "SetStacksColor",
    type = "color"
  },
  textSize = {
    display = L["First Text Size"],
    setter = "SetTextSize",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1,
    default = 12
  },
  timerSize = {
    display = L["Second Text Size"],
    setter = "SetTimerSize",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1,
    default = 12
  },
  stacksSize = {
    display = L["Stacks Text Size"],
    setter = "SetStacksSize",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1,
    default = 12
  },
  width = {
    display = L["Width"],
    setter = "SetRegionWidth",
    type = "number",
    min = 1,
    softMax = screenWidth,
    bigStep = 1,
    defautl = 32,
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
  orientation = {
    display = L["Orientation"],
    setter = "SetOrientation",
    type = "list",
    values = WeakAuras.orientation_types
  },
  inverse = {
    display = L["Inverse"],
    setter = "SetInverse",
    type = "bool"
  }
};

WeakAuras.regionPrototype.AddProperties(properties, default);

local function GetProperties(data)
  local overlayInfo = WeakAuras.GetOverlayInfo(data);
  if (overlayInfo and next(overlayInfo)) then
    local auraProperties = {};
    WeakAuras.DeepCopy(properties, auraProperties);

    for id, display in ipairs(overlayInfo) do
      auraProperties["overlays." .. id] = {
        display = string.format(L["%s Overlay Color"], display),
        setter = "SetOverlayColor",
        arg1 = id,
        type = "color",
      }
    end

    return auraProperties;
  else
    return properties;
  end
end

-- Returns tex Coord for 90° rotations + x or y flip

local texCoords = {
  0, 0, 1, 1,
  0, 0, 1, 1,
  0, 0, 1, 1
};

-- only supports multipliers of 90° degree
-- returns in order: TLx, TLy, TRx, TRy, BLx, BLy, BRx, BRy
local GetTexCoordSpark = function(degree, mirror)
  local offset = (degree or 0) / 90
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

local GetTexCoordFunctions =
  {
    ["HORIZONTAL"] = function(startProgress, endProgress)
      local TLx,  TLy = startProgress, 0;
      local TRx,  TRy = endProgress, 0;
      local BLx,  BLy = startProgress, 1;
      local BRx,  BRy = endProgress, 1;
      return TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy;
    end,
    ["HORIZONTAL_INVERSE"] = function(startProgress, endProgress)
      local TLx,  TLy = endProgress, 0;
      local TRx,  TRy = startProgress, 0;
      local BLx,  BLy = endProgress, 1;
      local BRx,  BRy = startProgress, 1;
      return TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy;
    end,
    ["VERTICAL"] = function(startProgress, endProgress)
      local TLx,  TLy = startProgress, 1;
      local TRx,  TRy = startProgress, 0;
      local BLx,  BLy = endProgress, 1;
      local BRx,  BRy = endProgress, 0;
      return TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy;
    end,
    ["VERTICAL_INVERSE"] = function(startProgress, endProgress)
      local TLx,  TLy = endProgress, 0;
      local TRx,  TRy = endProgress, 1;
      local BLx,  BLy = startProgress, 0;
      local BRx,  BRy = startProgress, 1;
      return TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy;
    end
  }

local anchorAlignment = {
  ["HORIZONTAL"] = { "TOPLEFT", "BOTTOMLEFT", "RIGHT" },
  ["HORIZONTAL_INVERSE"] = { "TOPRIGHT", "BOTTOMRIGHT", "LEFT" },
  ["VERTICAL"] = { "TOPLEFT", "TOPRIGHT", "BOTTOM" },
  ["VERTICAL_INVERSE"] = { "BOTTOMLEFT", "BOTTOMRIGHT", "TOP" }
}

local extraTextureWrapMode = "REPEAT";

-- Emulate blizzard statusbar with advanced features (more grow directions)
local barPrototype = {
  ["UpdateAnchors"] = function(self)
    -- Do not flip/rotate textures
    local orientation = self.orientation;
    if not self.rotate then
      if orientation == "HORIZONTAL_INVERSE" then
        orientation = "HORIZONTAL";
      elseif orientation == "VERTICAL_INVERSE" then
        orientation = "VERTICAL";
      end
    end

    self.GetTexCoord = GetTexCoordFunctions[orientation];
    local anchorAlignment = anchorAlignment[orientation];
    self.align1 = anchorAlignment[1];
    self.align2 = anchorAlignment[2];
    self.alignSpark = anchorAlignment[3];

    self.horizontal = (self.orientation == "HORIZONTAL_INVERSE") or (self.orientation == "HORIZONTAL")
    self.directionInverse = (self.orientation == "HORIZONTAL_INVERSE") or (self.orientation == "VERTICAL")

    local TLx,  TLy,  BLx,  BLy,  TRx,  TRy,  BRx,  BRy = self.GetTexCoord(0, 1);
    self.bg:SetTexCoord(TLx , TLy , BLx , BLy , TRx , TRy , BRx , BRy );

    -- Set alignment
    self.fg:ClearAllPoints();
    self.fg:SetPoint(self.align1);
    self.fg:SetPoint(self.align2);

    self.spark:SetPoint("CENTER", self.fg, self.alignSpark, self.spark.sparkOffsetX or 0, self.spark.sparkOffsetY or 0);

    local sparkMirror = self.spark.sparkMirror;
    local sparkRotationMode = self.spark.sparkRotationMode;
    local sTLx, sTLy, sBLx, sBLy, sTRx, sTRy, sBRx, sBRy; -- spark rotation
    if (sparkRotationMode == "AUTO") then
      sTLx, sTLy, sBLx, sBLy, sTRx, sTRy, sBRx, sBRy = TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy;
    else
      local sparkRotation = tonumber(self.spark.sparkRotation);
      sTLx, sTLy, sTRx, sTRy, sBLx, sBLy, sBRx, sBRy = GetTexCoordSpark(sparkRotation, sparkMirror)
    end
    self.spark:SetTexCoord(sTLx , sTLy , sBLx , sBLy , sTRx , sTRy , sBRx , sBRy);
  end,

  ["UpdateProgress"] = function(self)
    -- Limit values
    local value = self.value;
    value = math.max(self.min, value);
    value = math.min(self.max, value);

    -- Alignment variables
    local progress = (value - self.min) / (self.max - self.min);

    -- Create statusbar illusion
    if (self.horizontal) then
      local xProgress = self:GetRealSize() * progress;
      self.fg:SetWidth(xProgress > 0.0001 and xProgress or 0.0001);
    else
      local yProgress = select(2, self:GetRealSize()) * progress;
      self.fg:SetHeight(yProgress > 0.0001 and yProgress or 0.0001);
    end

    -- Stretch texture
    local TLx_, TLy_, BLx_, BLy_, TRx_, TRy_, BRx_, BRy_ = self.GetTexCoord(0, progress);
    self.fg:SetTexCoord(TLx_, TLy_, BLx_, BLy_, TRx_, TRy_, BRx_, BRy_);

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

  ["UpdateAdditionalBars"] = function(self)
    if (self.additionalBars) then
      for index, additionalBar in ipairs(self.additionalBars) do
        if (not self.extraTextures[index]) then
          local extraTexture = self:CreateTexture(nil, "ARTWORK");
          extraTexture:SetSnapToPixelGrid(false)
          extraTexture:SetTexelSnappingBias(0)
          extraTexture:SetTexture(self:GetStatusBarTexture(), extraTextureWrapMode, extraTextureWrapMode);
          extraTexture:SetDrawLayer("ARTWORK", min(index, 7));
          self.extraTextures[index] = extraTexture;
        end

        local extraTexture = self.extraTextures[index];

        local valueStart = self.additionalBarsMin
        local valueWidth = self.additionalBarsMax - valueStart;

        local startProgress = 0;
        local endProgress = 0;

        if (additionalBar.min and additionalBar.max) then
          if (valueWidth ~= 0) then
            startProgress = max( (additionalBar.min - valueStart) / valueWidth, 0);
            endProgress = (additionalBar.max - valueStart) / valueWidth;

            if (self.additionalBarsInverse) then
              startProgress = 1 - startProgress;
              endProgress = 1 - endProgress;
            end
          end
        elseif (additionalBar.direction) then
          local forwardDirection = (additionalBar.direction or "forward") == "forward";
          if (self.additionalBarsInverse) then
            forwardDirection = not forwardDirection;
          end

          local width = additionalBar.width or 0;
          local offset = additionalBar.offset or 0;

          if (width ~= 0) then
            if (forwardDirection) then
              startProgress = self.value + offset / valueWidth;
              endProgress = self.value + (width + offset) / valueWidth;
            else
              startProgress = self.value - (width + offset) / valueWidth;
              endProgress = self.value - offset / valueWidth;
            end
          end
        end

        if (self.additionalBarsClip) then
          startProgress = max(0, min(1, startProgress));
          endProgress = max(0, min(1, endProgress));
        end

        if ((endProgress - startProgress) == 0) then
          extraTexture:Hide();
        else
          extraTexture:Show();
          local TLx_, TLy_, BLx_, BLy_, TRx_, TRy_, BRx_, BRy_ = self.GetTexCoord(startProgress, endProgress);
          extraTexture:SetTexCoord(TLx_, TLy_, BLx_, BLy_, TRx_, TRy_, BRx_, BRy_);

          local color = self.additionalBarsColors and self.additionalBarsColors[index];
          if (color) then
            extraTexture:SetVertexColor(unpack(color));
          else
            extraTexture:SetVertexColor(1, 1, 1, 1);
          end

          local xOffset = 0;
          local yOffset = 0;
          local width, height = self:GetRealSize()
          if (self.horizontal) then
            xOffset = startProgress * width;
            local width = (endProgress - startProgress) * width;
            extraTexture:SetWidth( width  );
            extraTexture:SetHeight( height );
          else
            yOffset = startProgress * height;
            local height = (endProgress - startProgress) * height;
            extraTexture:SetWidth( width );
            extraTexture:SetHeight( height );
          end

          if (self.directionInverse) then
            xOffset = -xOffset;
            yOffset = -yOffset;
          end

          extraTexture:ClearAllPoints();
          extraTexture:SetPoint(self.align1, self, self.align1, xOffset, yOffset);
          extraTexture:SetPoint(self.align2, self, self.align2, xOffset, yOffset);
        end
      end

      if (#self.additionalBars < #self.extraTextures) then
        for i = #self.additionalBars + 1, #self.extraTextures do
          self.extraTextures[i]:Hide();
        end
      end
    else
      for i = 1, #self.extraTextures do
        self.extraTextures[i]:Hide();
      end
    end
  end,
  ["Update"] = function(self)
    self:UpdateAnchors();
    self:UpdateProgress();
    self:UpdateAdditionalBars();
  end,

  -- Need to update progress!
  ["OnSizeChanged"] = function(self, width, height)
    self:UpdateProgress();
    self:UpdateAdditionalBars();
  end,

  -- Blizzard like SetMinMaxValues
  ["SetMinMaxValues"] = function(self, minVal, maxVal)
    local update = false;
    if minVal and type(minVal) == "number" then
      self.min = minVal;
      update = true;
    end

    if maxVal and type(maxVal) == "number" then
      self.max = maxVal;
      update = true;
    end

    if update then
      self:UpdateProgress();
      self:UpdateAdditionalBars();
    end
  end,

  ["GetMinMaxValues"] = function(self)
    return self.min, self.max
  end,

  -- Blizzard like SetValue
  ["SetValue"] = function(self, value)
    if value and type(value) == "number" then
      self.value = value;
      self:UpdateProgress();
      self:UpdateAdditionalBars();
    end
  end,

  ["SetAdditionalBars"] = function(self, additionalBars, colors, min, max, inverse, overlayclip)
    self.additionalBars = additionalBars;
    self.additionalBarsColors = colors;
    self.additionalBarsMin = min;
    self.additionalBarsMax = max;
    self.additionalBarsInverse = inverse;
    self.additionalBarsClip = overlayclip;
    self:UpdateAdditionalBars();
  end,

  ["SetAdditionalBarColor"] = function(self, id, color)
    self.additionalBarsColors[id] = color;
    if self.extraTextures[id] then
      self.extraTextures[id]:SetVertexColor(unpack(color));
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
    for index, extraTexture in ipairs(self.extraTextures) do
      extraTexture:SetTexture(texture, extraTextureWrapMode, extraTextureWrapMode);
    end
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

  ["GetRealSize"] = function(self)
    return 0, 0
  end,

  -- Internal variables
  ["min"] = 0,
  ["max"] = 1,
  ["value"] = 0.5,
  ["rotate"] = true,
  ["orientation"] = "HORIZONTAL",
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
  Mixin(bar, SmoothStatusBarMixin);
  local fg = bar:CreateTexture(nil, "ARTWORK");
  fg:SetSnapToPixelGrid(false)
  fg:SetTexelSnappingBias(0)
  local bg = bar:CreateTexture(nil, "ARTWORK");
  bg:SetSnapToPixelGrid(false)
  bg:SetTexelSnappingBias(0)
  bg:SetAllPoints();
  local spark = bar:CreateTexture(nil, "ARTWORK");
  spark:SetSnapToPixelGrid(false)
  spark:SetTexelSnappingBias(0)
  fg:SetDrawLayer("ARTWORK", 0);
  bg:SetDrawLayer("ARTWORK", -1);
  spark:SetDrawLayer("ARTWORK", 7);
  bar.fg = fg;
  bar.bg = bg;
  bar.spark = spark;
  for key, value in pairs(barPrototype) do
    bar[key] = value;
  end
  bar.extraTextures = {};
  bar:SetRotatesTexture(true);
  bar:HookScript("OnSizeChanged", bar.OnSizeChanged);
  region.bar = bar;

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
  icon:SetSnapToPixelGrid(false)
  icon:SetTexelSnappingBias(0)
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

  local oldSetFrameLevel = region.SetFrameLevel;
  function region.SetFrameLevel(self, frameLevel)
    oldSetFrameLevel(self, frameLevel);

    iconFrame:SetFrameLevel(frameLevel + 2);
    bar:SetFrameLevel(frameLevel + 2);

    if (region.border) then
      if (region.borderInFront) then
        region.border:SetFrameLevel(frameLevel + 4);
      else
        region.border:SetFrameLevel(frameLevel + 1);
      end
    end

    if (region.backdrop) then
      if (region.backdropInFront) then
        region.backdrop:SetFrameLevel(frameLevel + 3);
      else
        region.backdrop:SetFrameLevel(frameLevel + 0);
      end
    end

    if (self.__WAGlowFrame) then
      self.__WAGlowFrame:SetFrameLevel(frameLevel + 5);
    end
  end

  WeakAuras.regionPrototype.create(region);

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
    rotate:SetDuration(0);
    rotate:SetEndDelay(2147483647);
    group:Play();
    rotate:SetSmoothProgress(1);
    group:Pause();
  end
end

-- Calculate offset after rotation
local function getRotateOffset(object, degrees, point)
  -- Any rotation at all?
  if degrees ~= 0 then
    -- Basic offset
    local originoffset = object:GetStringHeight() / 2;
    local xo = -1 * originoffset * sin(degrees);
    local yo = originoffset * (cos(degrees) - 1);

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

local GetRealSize = {
  ["HORIZONTAL"] = {
    [true] = function(self)
      return self.totalWidth - self.iconWidth, self.totalHeight
    end,
    [false] = function(self)
      return self.totalWidth, self.totalHeight
    end
  },
  ["VERTICAL"] = {
    [true] = function(self)
      return self.totalWidth, self.totalHeight - self.iconWidth
    end,
    [false] = function(self)
      return self.totalWidth, self.totalHeight
    end
  },
}

-- Orientation helper methods
local function orientHorizontalInverse(region, data)
  -- Localize
  local bar, timer, text, icon = region.bar, region.timer, region.text, region.icon;
  local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  bar.GetRealSize = GetRealSize["HORIZONTAL"][data.icon or false]

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
  bar:SetOrientation(region.orientation);

  -- Align timer text
  local xo, yo = getRotateOffset(timer, textDegrees, "LEFT");
  timer:ClearAllPoints();
  timer:SetPoint("LEFT", bar, "LEFT", 2 + xo, 0 + yo);

  -- Align name text
  xo, yo = getRotateOffset(text, textDegrees, "RIGHT");
  text:ClearAllPoints();
  text:SetPoint("RIGHT", bar, "RIGHT", -2 + xo, 0 + yo);

  -- Text internal alignment
  if textDegrees == 0 then
    local usedSpace = timer.visible and (timer:GetWidth() + (data.textSize/2)) or 0;
    if (data.icon) then
      usedSpace = usedSpace + math.min(region.height, region.width);
    end
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

  bar.GetRealSize = GetRealSize["HORIZONTAL"][data.icon or false]

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
  bar:SetOrientation(region.orientation);

  -- Align timer text
  local xo, yo = getRotateOffset(timer, textDegrees, "RIGHT");
  timer:ClearAllPoints();
  timer:SetPoint("RIGHT", bar, "RIGHT", -2 + xo, 0 + yo);

  -- Align name text
  xo, yo = getRotateOffset(text, textDegrees, "LEFT");
  text:ClearAllPoints();
  text:SetPoint("LEFT", bar, "LEFT", 2 + xo, 0 + yo);

  -- Text internal alignment
  if textDegrees == 0 then
    local usedSpace = timer.visible and (timer:GetWidth() + (data.textSize/2)) or 0;
    if (data.icon) then
      usedSpace = usedSpace + math.min(region.height, region.width);
    end
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

  bar.GetRealSize = GetRealSize["VERTICAL"][data.icon or false]

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
  bar:SetOrientation("VERTICAL_INVERSE");

  -- Align timer text
  local xo, yo = getRotateOffset(timer, textDegrees, "BOTTOM");
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

  bar.GetRealSize = GetRealSize["VERTICAL"][data.icon or false]

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
  bar:SetOrientation("VERTICAL");

  -- Align timer text
  local xo, yo = getRotateOffset(timer, textDegrees, "TOP");
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
local function orient(region, data, orientation)
  -- Apply correct orientation
  region.orientation = orientation;
  if orientation == "HORIZONTAL_INVERSE" then
    orientHorizontalInverse(region, data);
  elseif orientation == "HORIZONTAL" then
    orientHorizontal(region, data);
  elseif orientation == "VERTICAL_INVERSE" then
    orientVerticalInverse(region, data);
  elseif orientation == "VERTICAL" then
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
  if (textStr:find('%%')) then
    textStr = WeakAuras.ReplacePlaceHolders(textStr, region);
  end

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
  if (textStr:find('%%')) then
    textStr = WeakAuras.ReplacePlaceHolders(textStr, region);
  end

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
    orient(region, data, region.orientation);
  end
end

local function GetTexCoordZoom(texWidth)
  local texCoord = {texWidth, texWidth, texWidth, 1 - texWidth, 1 - texWidth, texWidth, 1 - texWidth, 1 - texWidth}
  return unpack(texCoord)
end

-- Modify a given region/display
local function modify(parent, region, data)

  WeakAuras.regionPrototype.modify(parent, region, data);
  -- Localize
  local bar, timer, text, iconFrame, icon, stacks = region.bar, region.timer, region.text, region.iconFrame, region.icon, region.stacks;

  region.useAuto = data.auto and WeakAuras.CanHaveAuto(data);

  -- Adjust region size
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  region.bar.totalWidth = data.width
  region.bar.totalHeight = data.height

  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;

  region.stickyDuration = data.stickyDuration;
  region.progressPrecision = data.progressPrecision;
  region.totalPrecision = data.totalPrecision;
  region.overlayclip = data.overlayclip;

  region.overlays = {};
  if (data.overlays) then
    WeakAuras.DeepCopy(data.overlays, region.overlays);
  end

  -- Update border
  if data.border then
    -- Create border
    if (not region.border) then
      local border = CreateFrame("frame", nil, region);
      region.border = border;
    end

    if (not region.backdrop) then
      local backdrop = CreateFrame("frame", nil, region);
      region.backdrop = backdrop;
    end

    local border = region.border;
    local backdrop = region.backdrop;
    border:SetBackdrop({
      edgeFile = SharedMedia:Fetch("border", data.borderEdge) or "",
      edgeSize = data.borderSize,
      bgFile = nil,
      insets = {
        left = data.borderInset,
        right = data.borderInset,
        top = data.borderInset,
        bottom = data.borderInset,
      },
    });
    border:SetPoint("bottomleft", region, "bottomleft", -data.borderOffset, -data.borderOffset);
    border:SetPoint("topright",   region, "topright",    data.borderOffset,  data.borderOffset);
    border:SetBackdropBorderColor(data.borderColor[1], data.borderColor[2], data.borderColor[3], data.borderColor[4]);
    border:SetBackdropColor(0, 0, 0, 0);

    backdrop:SetBackdrop({
      edgeFile = nil,
      edgeSize = data.borderSize,
      bgFile = SharedMedia:Fetch("background", data.borderBackdrop) or "",
      insets = {
        left = data.borderInset,
        right = data.borderInset,
        top = data.borderInset,
        bottom = data.borderInset,
      },
    });
    backdrop:SetPoint("bottomleft", region, "bottomleft", -data.borderOffset, -data.borderOffset);
    backdrop:SetPoint("topright",   region, "topright",    data.borderOffset,  data.borderOffset);
    backdrop:SetBackdropBorderColor(0, 0, 0, 0);
    backdrop:SetBackdropColor(data.backdropColor[1], data.backdropColor[2], data.backdropColor[3], data.backdropColor[4]);

    border:Show();
    backdrop:Show();
  else
    if (region.border) then
      region.border:Hide();
    end
    if (region.backdrop) then
      region.backdrop:Hide();
    end
  end

  -- Update texture settings
  local texturePath = SharedMedia:Fetch("statusbar", data.texture) or "";
  bar:SetStatusBarTexture(texturePath);
  bar:SetBackgroundColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  -- Update spark settings
  WeakAuras.SetTextureOrAtlas(bar.spark, data.sparkTexture);
  bar.spark:SetVertexColor(data.sparkColor[1], data.sparkColor[2], data.sparkColor[3], data.sparkColor[4]);
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
  local frameLevel = region:GetFrameLevel();

  iconFrame:SetFrameLevel(frameLevel + 2);
  bar:SetFrameLevel(frameLevel + 2);

  if (region.border) then
    if (data.borderInFront) then
      region.border:SetFrameLevel(frameLevel + 4);
    else
      region.border:SetFrameLevel(frameLevel + 1);
    end
  end

  if (region.backdrop) then
    if (data.backdropInFront) then
      region.backdrop:SetFrameLevel(frameLevel + 3);
    else
      region.backdrop:SetFrameLevel(frameLevel + 0);
    end
  end

  region.borderInFront = data.borderInFront;
  region.backdropInFront = data.backdropInFront;

  -- Color update function
  region.Color = region.Color or function(self, r, g, b, a)
    self.color_r = r;
    self.color_g = g;
    self.color_b = b;
    self.color_a = a;
    self.bar:SetForegroundColor(self.color_anim_r or r, self.color_anim_g or g, self.color_anim_b or b, self.color_anim_a or a);
  end

  region.ColorAnim = function(self, r, g, b, a)
    self.color_anim_r = r;
    self.color_anim_g = g;
    self.color_anim_b = b;
    self.color_anim_a = a;
    self.bar:SetForegroundColor(r or self.color_r, g or self.color_g, b or self.color_b, a or self.color_a);
  end

  region.GetColor = region.GetColor or function(self)
    return self.color_r, self.color_g, self.color_b, self.color_a
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
    region.values.icon = "|T"..iconPath..":12:12:0:0:64:64:4:60:4:60|t";

    -- Update text
    UpdateText(self, data);
  end

  -- Update icon visibility
  if data.icon then
    -- Update icon
    local iconsize = math.min(region.height, region.width);
    icon:SetWidth(iconsize);
    icon:SetHeight(iconsize);
    region.bar.iconWidth = iconsize
    region.bar.iconHeight = iconsize
    local texWidth = 0.25 * data.zoom;
    icon:SetTexCoord(GetTexCoordZoom(texWidth))
    icon:SetDesaturated(data.desaturate);
    icon:SetVertexColor(data.icon_color[1], data.icon_color[2], data.icon_color[3], data.icon_color[4]);

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
    region.bar.iconWidth = 0
    region.bar.iconHeight = 0
    stacks:Hide();
    icon:Hide();
  end

  region.inverseDirection = data.inverse;

  -- Apply orientation alignment
  orient(region, data, data.orientation);

  -- Update tooltip availability
  local tooltipType = WeakAuras.CanHaveTooltip(data);
  if tooltipType and data.useTooltip then
    -- Create and enable tooltip-hover frame
    if not region.tooltipFrame then
      region.tooltipFrame = CreateFrame("frame", nil, region);
      region.tooltipFrame:SetAllPoints(icon);
      region.tooltipFrame:SetScript("OnEnter", function()
        WeakAuras.ShowMouseoverTooltip(region, region.tooltipFrame);
      end);
      region.tooltipFrame:SetScript("OnLeave", WeakAuras.HideTooltip);
    end

    region.tooltipFrame:EnableMouse(true);
  elseif region.tooltipFrame then
    -- Disable tooltip
    region.tooltipFrame:EnableMouse(false);
  end

  -- Look for need to use custom text update
  local customTextFunc = nil
  if (WeakAuras.ContainsCustomPlaceHolder(data.displayTextLeft) or WeakAuras.ContainsCustomPlaceHolder(data.displayTextRight)) and data.customText then
    -- Load custom code function
    customTextFunc = WeakAuras.LoadFunction("return "..data.customText, region.id)
  end
  if (customTextFunc) then
    local values = region.values;

    -- Save custom text function
    region.UpdateCustomText = function()
      WeakAuras.ActivateAuraEnvironment(region.id, region.cloneId, region.state);
      values.custom = {select(2, xpcall(customTextFunc, geterrorhandler(), region.expirationTime, region.duration,
        values.progress, values.duration, values.name, values.icon, values.stacks))}
      WeakAuras.ActivateAuraEnvironment(nil);
      UpdateText(region, data);
    end

    -- Add/Remove custom text update
    if data.customTextUpdate == "update" then
      WeakAuras.RegisterCustomTextUpdates(region);
    else
      WeakAuras.UnregisterCustomTextUpdates(region);
    end

    -- Remove custom text update
  else
    region.values.custom = nil;
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
    region.scalex = scalex;
    region.scaley = scaley;
    -- Icon size
    local iconsize = math.min(region.height, region.width);

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
    self.bar.totalWidth = region.width * scalex
    self.bar.iconWidth = iconsize * scalex

    self:SetWidth(self.bar.totalWidth);
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
    self.bar.totalHeight = region.height * scaley
    self.bar.iconWidth = iconsize * scaley
    self:SetHeight(self.bar.totalHeight);
    icon:SetHeight(self.bar.iconWidth);
  end
  --  region:Scale(1.0, 1.0);

  -- Name update function
  function region:SetName(name)
    region.values.name = name or data.id;
    UpdateText(self, data);
  end
  --  region:SetName("");

  if data.smoothProgress then
    region.PreShow = function()
      region.bar:ResetSmoothedValue();
    end
  else
    region.PreShow = nil
  end

  function region:SetValue(value, total)
    local progress = 0;
    if (total ~= 0) then
      progress = value / total;
    end

    if region.inverseDirection then
      progress = 1 - progress;
    end

    if (data.smoothProgress) then
      region.bar.targetValue = progress
      region.bar:SetSmoothedValue(progress);
    else
      region.bar:SetValue(progress);
    end
    UpdateText(region, data);
  end

  function region:SetTime(duration, expirationTime, inverse)
    local remaining = expirationTime - GetTime();
    local progress = duration ~= 0 and remaining / duration or 0;
    -- Need to invert?
    if (
      (region.inverseDirection and not inverse)
      or (inverse and not region.inverseDirection)
      )
    then
      progress = 1 - progress;
    end
    if (data.smoothProgress) then
      region.bar.targetValue = progress
      region.bar:SetSmoothedValue(progress);
    else
      region.bar:SetValue(progress);
    end
    UpdateText(region, data);
  end

  function region:SetAdditionalProgress(additionalProgress, min, max, inverse)
    local effectiveInverse = (inverse and not region.inverseDirection) or (not inverse and region.inverseDirection);
    region.bar:SetAdditionalBars(additionalProgress, region.overlays, min, max, effectiveInverse, region.overlayclip);
  end

  function region:TimerTick()
    local adjustMin = region.adjustedMin or 0;
    self:SetTime( (region.duration ~= 0 and region.adjustedMax or region.duration) - adjustMin, region.expirationTime - adjustMin, region.inverse);
  end

  function region:SetIconColor(r, g, b, a)
    self.icon:SetVertexColor(r, g, b, a);
  end

  function region:SetIconDesaturated(b)
    self.icon:SetDesaturated(b);
  end

  function region:SetBackgroundColor(r, g, b, a)
    self.bar:SetBackgroundColor(r, g, b, a);
  end

  function region:SetSparkColor(r, g, b, a)
    self.bar.spark:SetVertexColor(r, g, b, a);
  end

  function region:SetSparkHeight(height)
    self.bar.spark:SetHeight(height);
  end

  function region:SetSparkWidth(width)
    self.bar.spark:SetWidth(width);
  end

  function region:SetBorderColor(r, g, b, a)
    if (self.border) then
      self.border:SetBackdropBorderColor(r, g, b, a);
    end
  end

  function region:SetBackdropColor(r, g, b, a)
    if (self.backdrop) then
      self.backdrop:SetBackdropColor(r, g, b, a);
    end
  end

  function region:SetTextColor(r, g, b, a)
    self.text:SetTextColor(r, g, b, a);
  end

  function region:SetTimerColor(r, g, b, a)
    self.timer:SetTextColor(r, g, b, a);
  end

  function region:SetStacksColor(r, g, b, a)
    self.stacks:SetTextColor(r, g, b, a);
  end

  function region:SetTextSize(size)
    self.text:SetFont(SharedMedia:Fetch("font", data.textFont), size, data.textFlags and data.textFlags ~= "None" and data.textFlags);
    self.text:SetTextHeight(size);
  end

  function region:SetTimerSize(size)
    self.timer:SetFont(SharedMedia:Fetch("font", data.timerFont), size, data.timerFlags and data.timerFlags ~= "None" and data.timerFlags);
    self.timer:SetTextHeight(size);
  end

  function region:SetStacksSize(size)
    self.stacks:SetFont(SharedMedia:Fetch("font", data.stacksFont), size, data.stacksFlags and data.stacksFlags ~= "None" and data.stacksFlags);
    self.stacks:SetTextHeight(size);
  end

  function region:SetRegionWidth(width)
    self.width = width;
    self:Scale(self.scalex, self.scaley);
  end

  function region:SetRegionHeight(height)
    self.height = height;
    self:Scale(self.scalex, self.scaley);
  end

  function region:SetInverse(inverse)
    if (region.inverseDirection == inverse) then
      return;
    end
    region.inverseDirection = inverse;
    if (data.smoothProgress) then
      if (region.bar.targetValue) then
        region.bar.targetValue = 1 - region.bar.targetValue
        region.bar:SetSmoothedValue(region.bar.targetValue);
      end
    else
      region.bar:SetValue(1 - region.bar:GetValue());
    end
  end

  function region:SetOrientation(orientation)
    orient(region, data, orientation);
    if (data.smoothProgress) then
      if region.bar.targetValue then
        region.bar:SetSmoothedValue(region.bar.targetValue);
      end
    else
      region.bar:SetValue(region.bar:GetValue());
    end
  end

  function region:SetOverlayColor(id, r, g, b, a)
    region.bar:SetAdditionalBarColor(id, { r, g, b, a});
  end

  -- Update internal bar alignment
  region.bar:Update();
end

-- Register new region type with WeakAuras
WeakAuras.RegisterRegionType("aurabar", create, modify, default, GetProperties);
