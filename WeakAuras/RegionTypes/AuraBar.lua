if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

-- Default settings
local default = {
  icon = true,
  desaturate = false,
  auto = true,
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
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  icon_side = "RIGHT",
  icon_color = {1.0, 1.0, 1.0, 1.0},
  frameStrata = 1,
  zoom = 0,
  subRegions = {
    [1] = {
      ["type"] = "aurabar_bar"
    }
  }
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
    return CopyTable(properties);
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

local function AnchorSubRegion(self, subRegion, anchorType, selfPoint, anchorPoint, anchorXOffset, anchorYOffset)
  if anchorType == "area" then
    local anchor = self
    if selfPoint == "bar" then
      anchor = self
    elseif selfPoint == "icon" then
      anchor = self.icon
    elseif selfPoint == "fg" then
      anchor = self.bar.fg
    elseif selfPoint == "bg" then
      anchor = self.bar.bg
    end

    anchorXOffset = anchorXOffset or 0
    anchorYOffset = anchorYOffset or 0
    subRegion:ClearAllPoints()
    subRegion:SetPoint("bottomleft", anchor, "bottomleft", -anchorXOffset, -anchorYOffset)
    subRegion:SetPoint("topright", anchor, "topright", anchorXOffset,  anchorYOffset)
  else
    subRegion:ClearAllPoints()
    anchorPoint = anchorPoint or "CENTER"

    local anchorRegion = self.bar

    anchorXOffset = anchorXOffset or 0
    anchorYOffset = anchorYOffset or 0

    if anchorPoint:sub(1, 5) == "ICON_" then
      anchorRegion = self.icon
      anchorPoint = anchorPoint:sub(6)
    elseif anchorPoint:sub(1, 6) == "INNER_" then
      anchorPoint = anchorPoint:sub(7)

      if anchorPoint:find("LEFT", 1, true) then
        anchorXOffset = anchorXOffset + 2
      elseif anchorPoint:find("RIGHT", 1, true) then
        anchorXOffset = anchorXOffset - 2
      end

      if anchorPoint:find("TOP", 1, true) then
        anchorYOffset = anchorYOffset - 2
      elseif anchorPoint:find("BOTTOM", 1, true) then
        anchorYOffset = anchorYOffset + 2
      end
    elseif anchorPoint == "SPARK" then
      anchorRegion = self.bar.spark
      anchorPoint = "CENTER"
    end

    selfPoint = selfPoint or "CENTER"

    if not WeakAuras.point_types[selfPoint] then
      selfPoint = "CENTER"
    end

    if not WeakAuras.point_types[anchorPoint] then
      anchorPoint = "CENTER"
    end

    subRegion:SetPoint(selfPoint, anchorRegion, anchorPoint, anchorXOffset, anchorYOffset)
  end
end

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

  -- Create icon
  local iconFrame = CreateFrame("FRAME", nil, region);
  region.iconFrame = iconFrame;
  local icon = iconFrame:CreateTexture(nil, "OVERLAY");
  icon:SetSnapToPixelGrid(false)
  icon:SetTexelSnappingBias(0)
  region.icon = icon;
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");

  -- Region variables
  region.values = {};

  local oldSetFrameLevel = region.SetFrameLevel;
  function region.SetFrameLevel(self, frameLevel)
    oldSetFrameLevel(self, frameLevel);

    if (self.__WAGlowFrame) then
      self.__WAGlowFrame:SetFrameLevel(frameLevel + 5);
    end
  end

  WeakAuras.regionPrototype.create(region);

  region.AnchorSubRegion = AnchorSubRegion

  -- Return new display/region
  return region;
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
  local bar, icon = region.bar, region.icon;

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
end

local function orientHorizontal(region, data)
  -- Localize
  local bar, icon = region.bar, region.icon;

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
end

local function orientVerticalInverse(region, data)
  -- Localize
  local bar, icon = region.bar, region.icon;

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
end

local function orientVertical(region, data)
  -- Localize
  local bar, icon = region.bar, region.icon;

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

local function GetTexCoordZoom(texWidth)
  local texCoord = {texWidth, texWidth, texWidth, 1 - texWidth, 1 - texWidth, texWidth, 1 - texWidth, 1 - texWidth}
  return unpack(texCoord)
end

local function TimerTick(self)
  local state = self.state
  local duration = state.duration or 0
  local adjustMin = self.adjustedMin or self.adjustedMinRel or 0;
  local expirationTime = state.expirationTime and state.expirationTime > 0 and state.expirationTime or math.huge;
  self:SetTime((duration ~= 0 and (self.adjustedMax or self.adjustedMaxRel) or duration) - adjustMin, expirationTime - adjustMin, state.inverse);
end

-- Modify a given region/display
local function modify(parent, region, data)
  region.timer = nil
  region.text = nil
  region.stacks = nil

  WeakAuras.regionPrototype.modify(parent, region, data);
  -- Localize
  local bar, iconFrame, icon = region.bar, region.iconFrame, region.icon;

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

  region.overlayclip = data.overlayclip;

  region.overlays = {};
  if (data.overlays) then
    WeakAuras.DeepCopy(data.overlays, region.overlays);
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

  else
    region.bar.iconWidth = 0
    region.bar.iconHeight = 0
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

  function region:Update()
    local state = region.state
    local max
    if state.progressType == "timed" then
      local expirationTime = state.expirationTime and state.expirationTime > 0 and state.expirationTime or math.huge;
      local duration = state.duration or 0

      if region.adjustedMinRelPercent then
        region.adjustedMinRel = region.adjustedMinRelPercent * duration
      end

      local adjustMin = region.adjustedMin or region.adjustedMinRel or 0;

      if duration == 0 then
        max = 0
      elseif region.adjustedMax then
        max = region.adjustedMax
      elseif region.adjustedMaxRelPercent then
        region.adjustedMaxRel = region.adjustedMaxRelPercent * duration
        max = region.adjustedMaxRel
      else
        max = duration
      end

      region:SetTime(max - adjustMin, expirationTime - adjustMin, state.inverse);
      if not region.TimerTick then
        region.TimerTick = TimerTick
        region:UpdateRegionHasTimerTick()
      end
    elseif state.progressType == "static" then
      local value = state.value or 0;
      local total = state.total or 0;

      if region.adjustedMinRelPercent then
        region.adjustedMinRel = region.adjustedMinRelPercent * total
      end
      local adjustMin = region.adjustedMin or region.adjustedMinRel or 0;
      if region.adjustedMax then
        max = region.adjustedMax
      elseif region.adjustedMaxRelPercent then
        region.adjustedMaxRel = region.adjustedMaxRelPercent * total
        max = region.adjustedMaxRel
      else
        max = total
      end
      region:SetValue(value - adjustMin, max - adjustMin);
      if region.TimerTick then
        region.TimerTick = nil
        region:UpdateRegionHasTimerTick()
      end
    else
      region:SetTime(0, math.huge)
      if region.TimerTick then
        region.TimerTick = nil
        region:UpdateRegionHasTimerTick()
      end
    end

    max = max or 0

    local path = state.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    local iconPath = (
      region.useAuto
      and path ~= ""
      and path
      or data.displayIcon
      or "Interface\\Icons\\INV_Misc_QuestionMark"
      );
    self.icon:SetTexture(iconPath);

    local duration = state.duration or 0
    local min = region.adjustMin or 0
    local effectiveInverse = (state.inverse and not region.inverseDirection) or (not state.inverse and region.inverseDirection);
    region.bar:SetAdditionalBars(state.additionalProgress, region.overlays, min, max, effectiveInverse, region.overlayclip);
  end

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

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);
end

local function ValidateRegion(data)
  data.subRegions = data.subRegions or {}
  for index, subRegionData in ipairs(data.subRegions) do
    if subRegionData.type == "aurabar_bar" then
      return
    end
  end
  tinsert(data.subRegions, 1, {
    ["type"] = "aurabar_bar"
  })
end

-- Register new region type with WeakAuras
WeakAuras.RegisterRegionType("aurabar", create, modify, default, GetProperties, ValidateRegion);

local function subSupports(regionType)
  return regionType == "aurabar"
end

local function noop()
end

local function SetFrameLevel(self, level)
  self.parent.bar:SetFrameLevel(level)
  self.parent.iconFrame:SetFrameLevel(level)
end

local function subCreate()
  local result = {}
  result.Update = noop
  result.SetFrameLevel = SetFrameLevel
  return result
end

local function subModify(parent, region)
  region.parent = parent
end

WeakAuras.RegisterSubRegionType("aurabar_bar", L["Foreground"], subSupports, subCreate, subModify, noop, noop, {}, nil, {}, false);
