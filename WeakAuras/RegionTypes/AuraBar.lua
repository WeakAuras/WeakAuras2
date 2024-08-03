if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

-- Default settings
local default = {
  icon = false,
  desaturate = false,
  iconSource = -1,
  progressSource = {-1, "" },
  adjustedMax = "",
  adjustedMin = "",
  texture = "Blizzard",
  textureSource = "LSM",
  width = 200,
  height = 15,
  orientation = "HORIZONTAL",
  inverse = false,
  barColor = {1.0, 0.0, 0.0, 1.0},
  barColor2 = {1.0, 1.0, 0.0, 1.0},
  enableGradient = false,
  gradientOrientation = "HORIZONTAL",
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
  zoom = 0
};

Private.regionPrototype.AddProgressSourceToDefault(default)
Private.regionPrototype.AddAlphaToDefault(default);

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  textureSource = {
    display = {L["Bar Texture"], L["Selection Mode"]},
    setter = "SetStatusBarTextureMode",
    type = "list",
    values = {
      LSM = L["LibSharedMedia"],
      Picker = L["Texture Picker"]
    }
  },
  textureInput = {
    display = {L["Bar Texture"], L["Texture Picker"]},
    setter = "SetStatusBarTextureInput",
    type = "texture",
  },
  texture = {
    display = {L["Bar Texture"], L["LibSharedMedia"]},
    setter = "SetStatusBarTextureLSM",
    type = "textureLSM",
  },
  barColor = {
    display = L["Bar Color/Gradient Start"],
    setter = "Color",
    type = "color",
  },
  barColor2 = {
    display = L["Gradient End"],
    setter = "SetBarColor2",
    type = "color",
  },
  gradientOrientation = {
    display = L["Gradient Orientation"],
    setter = "SetGradientOrientation",
    type = "list",
    values = Private.gradient_orientations
  },
  enableGradient = {
    display = L["Gradient Enabled"],
    setter = "SetGradientEnabled",
    type = "bool",
  },
  icon_visible = {
    display = {L["Icon"], L["Visibility"]},
    setter = "SetIconVisible",
    type = "bool"
  },
  icon_color = {
    display = {L["Icon"], L["Color"]},
    setter = "SetIconColor",
    type = "color"
  },
  iconSource = {
    display = {L["Icon"], L["Source"]},
    setter = "SetIconSource",
    type = "list",
    values = {}
  },
  displayIcon = {
    display = {L["Icon"], L["Manual"]},
    setter = "SetIcon",
    type = "icon",
  },
  desaturate = {
    display = {L["Icon"], L["Desaturate"]},
    setter = "SetIconDesaturated",
    type = "bool",
  },
  backgroundColor = {
    display = L["Background Color"],
    setter = "SetBackgroundColor",
    type = "color"
  },
  sparkColor = {
    display = {L["Spark"], L["Color"]},
    setter = "SetSparkColor",
    type = "color"
  },
  sparkHeight = {
    display = {L["Spark"], L["Height"]},
    setter = "SetSparkHeight",
    type = "number",
    min = 1,
    softMax = screenHeight,
    bigStep = 1
  },
  sparkWidth = {
    display = {L["Spark"], L["Width"]},
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
    default = 32,
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
    values = Private.orientation_types
  },
  inverse = {
    display = L["Inverse"],
    setter = "SetInverse",
    type = "bool"
  },
};

Private.regionPrototype.AddProperties(properties, default);

local function GetProperties(data)
  local overlayInfo = Private.GetOverlayInfo(data);
  local auraProperties = CopyTable(properties)
  if (overlayInfo and next(overlayInfo)) then
    for id, display in ipairs(overlayInfo) do
      auraProperties["overlays." .. id] = {
        display = string.format(L["%s Overlay Color"], display),
        setter = "SetOverlayColor",
        arg1 = id,
        type = "color",
      }
    end
  end

  auraProperties.iconSource.values = Private.IconSources(data)
  auraProperties.progressSource.values = Private.GetProgressSourcesForUi(data)
  return auraProperties;
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
    self.bg:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
    self.fg:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)

    -- Set alignment
    self.fgMask:ClearAllPoints()
    self.fgMask:SetPoint(self.align1, self, self.align1)
    self.fgMask:SetPoint(self.align2, self, self.align2)

    self.spark:SetPoint("CENTER", self.fgMask, self.alignSpark, self.spark.sparkOffsetX or 0, self.spark.sparkOffsetY or 0);

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
      local show = xProgress > 0.0001
      self.fgMask:SetWidth(show and (xProgress + 0.1) or 0.1);
      if show then
        self.fg:Show()
      else
        self.fg:Hide()
      end
    else
      local yProgress = select(2, self:GetRealSize()) * progress;
      local show = yProgress > 0.0001
      self.fgMask:SetHeight(show and (yProgress + 0.1) or 0.1);
      if show then
        self.fg:Show()
      else
        self.fg:Hide()
      end
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

  ["UpdateAdditionalBars"] = function(self)
    if (type(self.additionalBars) == "table") then
      for index, additionalBar in ipairs(self.additionalBars) do
        if (not self.extraTextures[index]) then
          local extraTexture = self:CreateTexture(nil, "ARTWORK");
          extraTexture:SetTexelSnappingBias(0)
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
            startProgress = (additionalBar.min - valueStart) / valueWidth;
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

          if (width ~= 0 and valueWidth ~= 0) then
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
        else
          startProgress = max(-10, min(11, startProgress));
          endProgress = max(-10, min(11, endProgress));
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

          local texture = self.additionalBarsTextures and self.additionalBarsTextures[index];
          if texture then
            local texturePath = SharedMedia:Fetch("statusbar_atlas", texture, true) or SharedMedia:Fetch("statusbar", texture) or ""
            Private.SetTextureOrAtlas(extraTexture, texturePath, extraTextureWrapMode, extraTextureWrapMode)
          else
            Private.SetTextureOrAtlas(extraTexture, self:GetStatusBarTexture(), extraTextureWrapMode, extraTextureWrapMode)
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
    self:GetParent().subRegionEvents:Notify("OnRegionSizeChanged")
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

  ["SetAdditionalBars"] = function(self, additionalBars, colors, textures, min, max, inverse, overlayclip)
    self.additionalBars = additionalBars;
    self.additionalBarsColors = colors;
    self.additionalBarsTextures = textures;
    self.additionalBarsMin = min or 0;
    self.additionalBarsMax = max or 0;
    self.additionalBarsInverse = inverse;
    self.additionalBarsClip = overlayclip;
    self:UpdateAdditionalBars();
  end,

  ["GetAdditionalBarsInverse"] = function(self)
    return self.additionalBarsInverse
  end,

  ["SetAdditionalBarsInverse"] = function(self, value)
    self.additionalBarsInverse = value;
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
    Private.SetTextureOrAtlas(self.fg, texture)
    Private.SetTextureOrAtlas(self.bg, texture)
    for index, extraTexture in ipairs(self.extraTextures) do
      Private.SetTextureOrAtlas(extraTexture, texture, extraTextureWrapMode, extraTextureWrapMode)
    end
  end,

  ["GetStatusBarTexture"] = function(self)
    return self.fg:GetAtlas() or self.fg:GetTexture()
  end,

  -- Set bar color
  ["SetForegroundColor"] = function(self, r, g, b, a)
    self.fg:SetVertexColor(r, g, b, a);
  end,

  ["SetForegroundGradient"] = function(self, orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    if self.fg.SetGradientAlpha then
      self.fg:SetGradientAlpha(orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    else
      self.fg:SetGradient(orientation, CreateColor(r1, g1, b1, a1),
                                       CreateColor(r2, g2, b2, a2))
    end
  end,

  -- Set background color
  ["SetBackgroundColor"] = function(self, r, g, b, a)
    self.bg:SetVertexColor(r, g, b, a);
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
      return self.totalWidth, self.totalHeight - self.iconHeight
    end,
    [false] = function(self)
      return self.totalWidth, self.totalHeight
    end
  },
}

-- Orientation helper methods
local function orientHorizontalInverse(region)
  -- Localize
  local bar, icon = region.bar, region.icon;

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  bar.GetRealSize = GetRealSize["HORIZONTAL"][region.iconVisible or false]

  -- Align icon and bar
  if region.iconVisible then
    if region.icon_side == "LEFT" then
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
  bar:SetOrientation(region.effectiveOrientation);
end

local function orientHorizontal(region)
  -- Localize
  local bar, icon = region.bar, region.icon;

  bar.GetRealSize = GetRealSize["HORIZONTAL"][region.iconVisible or false]

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  -- Align icon and bar
  if region.iconVisible then
    if region.icon_side == "LEFT" then
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
  bar:SetOrientation(region.effectiveOrientation);
end

local function orientVerticalInverse(region)
  -- Localize
  local bar, icon = region.bar, region.icon;

  bar.GetRealSize = GetRealSize["VERTICAL"][region.iconVisible or false]

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  -- Align icon and bar
  if region.iconVisible then
    if region.icon_side == "LEFT" then
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

local function orientVertical(region)
  -- Localize
  local bar, icon = region.bar, region.icon;

  bar.GetRealSize = GetRealSize["VERTICAL"][region.iconVisible or false]

  -- Reset
  icon:ClearAllPoints();
  bar:ClearAllPoints();

  -- Align icon and bar
  if region.iconVisible then
    if region.icon_side == "LEFT" then
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

local function GetTexCoordZoom(texWidth)
  local texCoord = {texWidth, texWidth, texWidth, 1 - texWidth, 1 - texWidth, texWidth, 1 - texWidth, 1 - texWidth}
  return unpack(texCoord)
end

local function FrameTick(self)
  local expirationTime = self.expirationTime
  local remaining = expirationTime - GetTime()
  local duration = self.duration
  local progress = duration ~= 0 and remaining / duration or 0;
  if self.inverse then
    progress = 1 - progress;
  end
  self:SetProgress(progress)
end

local funcs = {
  AnchorSubRegion = function(self, subRegion, anchorType, selfPoint, anchorPoint, anchorXOffset, anchorYOffset)
    if anchorType == "area" then
      local anchor = self
      if selfPoint == "bar" then
        anchor = self
      elseif selfPoint == "icon" then
        anchor = self.icon
      elseif selfPoint == "fg" then
        anchor = self.bar.fgMask
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

      if not Private.point_types[selfPoint] then
        selfPoint = "CENTER"
      end

      if not Private.point_types[anchorPoint] then
        anchorPoint = "CENTER"
      end

      subRegion:SetPoint(selfPoint, anchorRegion, anchorPoint, anchorXOffset, anchorYOffset)
    end
  end,
  SetIconColor = function(self, r, g, b, a)
    self.icon_color = {r, g, b, a}
    self.icon:SetVertexColor(r, g, b, a);
  end,
  SetIconDesaturated = function(self, b)
    self.desaturateIcon = b
    self.icon:SetDesaturated(b);
  end,
  SetBackgroundColor = function (self, r, g, b, a)
    self.bar:SetBackgroundColor(r, g, b, a);
  end,
  SetSparkColor = function(self, r, g, b, a)
    self.bar.spark:SetVertexColor(r, g, b, a);
  end,
  SetSparkHeight = function(self, height)
    self.bar.spark:SetHeight(height);
  end,
  SetSparkWidth = function(self, width)
    self.bar.spark:SetWidth(width);
  end,
  SetRegionWidth = function(self, width)
    self.width = width;
    self:Scale(self.scalex, self.scaley);
  end,
  SetRegionHeight = function(self, height)
    self.height = height;
    self:Scale(self.scalex, self.scaley);
  end,
  SetProgress = function(self, progress)
    if self.inverseDirection then
      progress = 1 - progress;
    end

    if (self.smoothProgress) then
      self.bar.targetValue = progress
      self.bar:SetSmoothedValue(progress);
    else
      self.bar:SetValue(progress);
    end
  end,
  UpdateValue = function(self)
    local progress = 0;
    if (self.total ~= 0) then
      progress = self.value / self.total;
    end

    self:SetProgress(progress)

    if self.FrameTick then
      self.FrameTick = nil
      self.subRegionEvents:RemoveSubscriber("FrameTick", self)
    end
  end,
  UpdateTime = function(self)
    local remaining = self.expirationTime - GetTime();
    local progress = self.duration ~= 0 and remaining / self.duration or 0;
    if self.inverse then
      progress = 1 - progress;
    end
    self:SetProgress(progress)

    if self.paused and self.FrameTick then
      self.FrameTick = nil
      self.subRegionEvents:RemoveSubscriber("FrameTick", self)
    end
    if not self.paused and not self.FrameTick then
      self.FrameTick = FrameTick
      self.subRegionEvents:AddSubscriber("FrameTick", self)
    end
  end,
  SetInverse = function(self, inverse)
    if (self.inverseDirection == inverse) then
      return;
    end
    self.inverseDirection = inverse;
    if (self.smoothProgress) then
      if (self.bar.targetValue) then
        self.bar.targetValue = 1 - self.bar.targetValue
        self.bar:SetSmoothedValue(self.bar.targetValue);
      end
    else
      self.bar:SetValue(1 - self.bar:GetValue());
    end
    self.bar:SetAdditionalBarsInverse(not self.bar:GetAdditionalBarsInverse())
    self.subRegionEvents:Notify("InverseChanged")
  end,
  SetOrientation = function(self, orientation)
    self.orientation = orientation
    self:UpdateEffectiveOrientation()
    if (self.smoothProgress) then
      if self.bar.targetValue then
        self.bar:SetSmoothedValue(self.bar.targetValue);
      end
    else
      self.bar:SetValue(self.bar:GetValue());
    end
  end,

  SetStatusBarTextureMode = function(self, mode)
    if self.textureSource == mode then
      return
    end
    self.textureSource = mode
    self:UpdateStatusBarTexture()
  end,

  SetStatusBarTextureInput = function(self, texture)
    if self.textureInput == texture then
      return
    end
    self.textureInput = texture
    self:UpdateStatusBarTexture()
  end,

  SetStatusBarTextureLSM = function(self, texture)
    if self.texture == texture then
      return
    end
    self.texture = texture
    self:UpdateStatusBarTexture()
  end,

  UpdateStatusBarTexture = function(self)
    local texturePath
    if self.textureSource == "Picker" then
      texturePath = self.textureInput or ""
    else
      texturePath = SharedMedia:Fetch("statusbar_atlas", self.texture, true) or SharedMedia:Fetch("statusbar", self.texture) or ""
    end
    self.bar:SetStatusBarTexture(texturePath)
  end,

  SetIconVisible = function(self, iconVisible)
    if (self.iconVisible == iconVisible) then
      return
    end

    self.iconVisible = iconVisible

    local icon = self.icon
    if self.iconVisible then
      -- Update icon
      local iconsize = math.min(self.height, self.width);
      icon:SetWidth(iconsize);
      icon:SetHeight(iconsize);
      self.bar.iconWidth = iconsize
      self.bar.iconHeight = iconsize
      local texWidth = 0.25 * self.zoom;
      icon:SetTexCoord(GetTexCoordZoom(texWidth))
      icon:SetDesaturated(self.desaturateIcon);
      icon:SetVertexColor(self.icon_color[1], self.icon_color[2], self.icon_color[3], self.icon_color[4]);

      -- Update icon visibility
      icon:Show();
    else
      self.bar.iconWidth = 0
      self.bar.iconHeight = 0
      icon:Hide();
    end

    self:ReOrient()
    self.subRegionEvents:Notify("OrientationChanged")
  end,
  SetIcon = function(self, iconPath)
    if self.displayIcon == iconPath then
      return
    end
    self.displayIcon = iconPath
    self:UpdateIcon()
  end,
  SetIconSource = function(self, source)
    if self.iconSource == source then
      return
    end

    self.iconSource = source
    self:UpdateIcon()
  end,
  UpdateIcon = function(self)
    local iconPath
    if self.iconSource == -1 then
      iconPath = self.state.icon
    elseif self.iconSource == 0 then
      iconPath = self.displayIcon
    else
      local triggernumber = self.iconSource
      if triggernumber and self.states[triggernumber] then
        iconPath = self.states[triggernumber].icon
      end
    end

    iconPath = iconPath or self.displayIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    Private.SetTextureOrAtlas(self.icon, iconPath)
  end,
  SetOverlayColor = function(self, id, r, g, b, a)
    self.bar:SetAdditionalBarColor(id, { r, g, b, a});
  end,
  GetEffectiveOrientation = function(self)
    return self.effectiveOrientation
  end,
  GetInverse = function(self)
    return self.inverseDirection
  end,
  ReOrient = function(self)
    if self.effectiveOrientation == "HORIZONTAL_INVERSE" then
      orientHorizontalInverse(self);
    elseif self.effectiveOrientation == "HORIZONTAL" then
      orientHorizontal(self);
    elseif self.effectiveOrientation == "VERTICAL_INVERSE" then
      orientVerticalInverse(self);
    elseif self.effectiveOrientation == "VERTICAL" then
      orientVertical(self);
    end
  end,
  UpdateEffectiveOrientation = function(self, force)
    local orientation = self.orientation

    if self.flipX then
      if self.orientation == "HORIZONTAL" then
        orientation = "HORIZONTAL_INVERSE"
      elseif self.orientation == "HORIZONTAL_INVERSE" then
        orientation = "HORIZONTAL"
      end
    end
    if self.flipY then
      if self.orientation == "VERTICAL" then
        orientation = "VERTICAL_INVERSE"
      elseif self.orientation == "VERTICAL_INVERSE" then
        orientation = "VERTICAL"
      end
    end

    if orientation ~= self.effectiveOrientation or force then
      self.effectiveOrientation = orientation
      self:ReOrient()
    end

    self.subRegionEvents:Notify("OrientationChanged")
  end,
  UpdateForegroundColor = function(self)
    if self.enableGradient then
      self.bar:SetForegroundGradient(self.gradientOrientation,
                                     self.color_anim_r or self.color_r,
                                     self.color_anim_g or self.color_g,
                                     self.color_anim_b or self.color_b,
                                     self.color_anim_a or self.color_a,
                                     self.barColor2[1],
                                     self.barColor2[2],
                                     self.barColor2[3],
                                     self.barColor2[4])
    else
      self.bar:SetForegroundColor(self.color_anim_r or self.color_r,
                                  self.color_anim_g or self.color_g,
                                  self.color_anim_b or self.color_b,
                                  self.color_anim_a or self.color_a);
    end
  end,
  SetBarColor2 = function(self, r, g, b, a)
    self.barColor2 = { r, g, b, a}
    self:UpdateForegroundColor()
  end,
  SetGradientOrientation = function(self, orientation)
    self.gradientOrientation = orientation
    self:UpdateForegroundColor()
  end,
  SetGradientEnabled = function(self, enable)
    self.enableGradient = enable
    self:UpdateForegroundColor()
  end,
  Color = function(self, r, g, b, a)
    self.color_r = r;
    self.color_g = g;
    self.color_b = b;
    self.color_a = a;
    self:UpdateForegroundColor()
  end,
  ColorAnim = function(self, r, g, b, a)
    self.color_anim_r = r;
    self.color_anim_g = g;
    self.color_anim_b = b;
    self.color_anim_a = a;
    self:UpdateForegroundColor()
  end,
  GetColor = function(self)
    return self.color_r, self.color_g, self.color_b, self.color_a
  end
}

-- Called when first creating a new region/display
local function create(parent)
  -- Create overall region (containing everything else)
  local region = CreateFrame("Frame", nil, parent);
  --- @cast region table|Frame
  region.regionType = "aurabar"
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetResizeBounds(1, 1)

  local bar = CreateFrame("Frame", nil, region);
  --- @cast bar table|Frame
  Mixin(bar, Private.SmoothStatusBarMixin);

  -- Now create a bunch of textures
  local bg = region:CreateTexture(nil, "ARTWORK");
  bg:SetTexelSnappingBias(0)
  bg:SetSnapToPixelGrid(false)
  bg:SetAllPoints(bar);

  local fg = bar:CreateTexture(nil, "ARTWORK");
  fg:SetTexelSnappingBias(0)
  fg:SetSnapToPixelGrid(false)
  fg:SetAllPoints(bar)

  local fgMask = bar:CreateMaskTexture()
  fgMask:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite",
                    "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
  fgMask:SetTexelSnappingBias(0)
  fgMask:SetSnapToPixelGrid(false)
  fg:AddMaskTexture(fgMask)

  local spark = bar:CreateTexture(nil, "ARTWORK");
  spark:SetSnapToPixelGrid(false)
  spark:SetTexelSnappingBias(0)
  fg:SetDrawLayer("ARTWORK", 0);
  bg:SetDrawLayer("ARTWORK", -1);
  spark:SetDrawLayer("ARTWORK", 7);
  bar.fg = fg;
  bar.fgMask = fgMask
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
  local iconFrame = CreateFrame("Frame", nil, region);
  region.iconFrame = iconFrame;
  local icon = iconFrame:CreateTexture(nil, "OVERLAY");
  icon:SetSnapToPixelGrid(false)
  icon:SetTexelSnappingBias(0)
  region.icon = icon;
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");

  local oldSetFrameLevel = region.SetFrameLevel;
  function region.SetFrameLevel(self, frameLevel)
    oldSetFrameLevel(self, frameLevel);

    if (self.__WAGlowFrame) then
      self.__WAGlowFrame:SetFrameLevel(frameLevel + 5);
    end
  end

  Private.regionPrototype.create(region);

  for k, f in pairs(funcs) do
    region[k] = f
  end

  -- Return new display/region
  return region;
end

-- Modify a given region/display
local function modify(parent, region, data)
  region.timer = nil
  region.text = nil
  region.stacks = nil

  Private.regionPrototype.modify(parent, region, data);
  -- Localize
  local bar, iconFrame, icon = region.bar, region.iconFrame, region.icon;

  region.iconSource = data.iconSource
  region.displayIcon = data.displayIcon

  -- Adjust region size
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  region.bar.totalWidth = data.width
  region.bar.totalHeight = data.height

  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;
  region.flipX = false
  region.flipY = false
  region.orientation = data.orientation
  region.effectiveOrientation = nil

  -- region.barColor is special because of animations
  region.barColor2 = CopyTable(data.barColor2)
  region.enableGradient = data.enableGradient
  region.gradientOrientation = data.gradientOrientation
  region.overlayclip = data.overlayclip;
  region.iconVisible = data.icon
  region.icon_side = data.icon_side
  region.icon_color = CopyTable(data.icon_color)
  region.desaturateIcon = data.desaturate
  region.zoom = data.zoom

  if (data.overlays) then
    region.overlays = CopyTable(data.overlays);
  else
    region.overlays = {}
  end
  if data.overlaysTexture then
    region.overlaysTexture = CopyTable(data.overlaysTexture)
  else
    region.overlaysTexture = {}
  end

  -- Update texture settings
  region.textureSource = data.textureSource
  region.texture = data.texture
  region.textureInput = data.textureInput

  region:UpdateStatusBarTexture();
  bar:SetBackgroundColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  -- Update spark settings
  Private.SetTextureOrAtlas(bar.spark, data.sparkTexture);
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

  region:Color(data.barColor[1], data.barColor[2], data.barColor[3], data.barColor[4]);

  -- Update icon visibility
  if region.iconVisible then
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
  region:UpdateEffectiveOrientation()

  -- Update tooltip availability
  local tooltipType = Private.CanHaveTooltip(data);
  if tooltipType and data.useTooltip then
    -- Create and enable tooltip-hover frame
    if not region.tooltipFrame then
      region.tooltipFrame = CreateFrame("Frame", nil, region);
      region.tooltipFrame:SetAllPoints(icon);
      region.tooltipFrame:SetScript("OnEnter", function()
        Private.ShowMouseoverTooltip(region, region.tooltipFrame);
      end);
      region.tooltipFrame:SetScript("OnLeave", Private.HideTooltip);
    end
    region.tooltipFrame:EnableMouseMotion(true);
    region.tooltipFrame:SetMouseClickEnabled(false);
  elseif region.tooltipFrame then
    -- Disable tooltip
    region.tooltipFrame:EnableMouseMotion(false);
  end

  region.FrameTick = nil
  function region:Update()
    region:UpdateProgress()
    region:UpdateIcon()
  end

  function region:SetAdditionalProgress(additionalProgress, currentMin, currentMax, inverse)
    local effectiveInverse = (inverse and not region.inverseDirection) or (not inverse and region.inverseDirection);
    region.bar:SetAdditionalBars(additionalProgress, region.overlays, region.overlaysTexture, currentMin, currentMax, effectiveInverse, region.overlayclip);
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
      region.flipX = true
    else
      region.flipX = false
    end

    -- Update width
    self.bar.totalWidth = region.width * scalex
    self.bar.iconWidth = iconsize * scalex

    self:SetWidth(self.bar.totalWidth);
    icon:SetWidth(self.bar.iconWidth);

    -- Re-orientate region
    if scaley < 0 then
      scaley = -scaley;
      region.flipY = true
    else
      region.flipY = false
    end

    -- Update height
    self.bar.totalHeight = region.height * scaley
    self.bar.iconHeight = iconsize * scaley
    self:SetHeight(self.bar.totalHeight);
    icon:SetHeight(self.bar.iconHeight);

    region:UpdateEffectiveOrientation(true)
  end
  --  region:Scale(1.0, 1.0);
  if data.smoothProgress then
    region.PreShow = function()
      region.bar:ResetSmoothedValue();
    end
  else
    region.PreShow = nil
  end

  region.smoothProgress = data.smoothProgress
  --- Update internal bar alignment
  region.bar:Update();

  Private.regionPrototype.modifyFinish(parent, region, data);
end

local function validate(data)
  -- pre-migration
  if data.subRegions then
    for _, subRegionData in ipairs(data.subRegions) do
      if subRegionData.type == "aurabar_bar" then
        subRegionData.type = "subforeground"
      end
    end
  end
  Private.EnforceSubregionExists(data, "subforeground")
  Private.EnforceSubregionExists(data, "subbackground")
end

-- Register new region type with WeakAuras
Private.RegisterRegionType("aurabar", create, modify, default, GetProperties, validate);
