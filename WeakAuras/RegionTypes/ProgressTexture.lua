if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L;

local defaultFont = WeakAuras.defaultFont
local defaultFontSize = WeakAuras.defaultFontSize

-- Credit to CommanderSirow for taking the time to properly craft the TransformPoint function
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
--   region.scale (1.0) - user defined scaling [1, INF]
--   region.full_rotation (false) - Allow full rotation [bool]

local default = {
  progressSource = {-1, "" },
  adjustedMax = "",
  adjustedMin = "",
  foregroundTexture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura3",
  backgroundTexture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura3",
  desaturateBackground = false,
  desaturateForeground = false,
  sameTexture = true,
  compress = false,
  blendMode = "BLEND",
  textureWrapMode = "CLAMPTOBLACKADDITIVE",
  backgroundOffset = 2,
  width = 200,
  height = 200,
  orientation = "VERTICAL",
  inverse = false,
  foregroundColor = {1, 1, 1, 1},
  backgroundColor = {0.5, 0.5, 0.5, 0.5},
  startAngle = 0,
  endAngle = 360,
  user_x = 0,
  user_y = 0,
  crop_x = 0.41,
  crop_y = 0.41,
  rotation = 0, -- Uses tex coord rotation, called "legacy rotation" in the ui and texRotation in code everywhere else
  auraRotation = 0, -- Uses texture:SetRotation
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  font = defaultFont,
  fontSize = defaultFontSize,
  mirror = false,
  frameStrata = 1,
  slantMode = "INSIDE"
};

Private.regionPrototype.AddAlphaToDefault(default);

Private.regionPrototype.AddProgressSourceToDefault(default)

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  desaturateForeground = {
    display = L["Desaturate Foreground"],
    setter = "SetForegroundDesaturated",
    type = "bool",
  },
  desaturateBackground = {
    display = L["Desaturate Background"],
    setter = "SetBackgroundDesaturated",
    type = "bool",
  },
  foregroundColor = {
    display = L["Foreground Color"],
    setter = "Color",
    type = "color"
  },
  backgroundColor = {
    display = L["Background Color"],
    setter = "SetBackgroundColor",
    type = "color"
  },
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
  orientation = {
    display = L["Orientation"],
    setter = "SetOrientation",
    type = "list",
    values = Private.orientation_with_circle_types
  },
  auraRotation = {
    display = L["Rotation"],
    setter = "SetAuraRotation",
    type = "number",
    min = 0,
    max = 360,
    bigStep = 10,
    default = 0
  },
  inverse = {
    display = L["Inverse"],
    setter = "SetInverse",
    type = "bool"
  },
  mirror = {
    display = L["Mirror"],
    setter = "SetMirror",
    type = "bool",
  },
  rotation = {
    display = L["Texture Rotation"],
    setter = "SetTexRotation",
    type = "number",
    min = 0,
    max = 360,
    bigStep = 1,
    default = 0
  },
  crop_x = {
    display = L["Crop X"],
    setter = "SetCropX",
    type = "number",
    min = 0,
    softMax = 2,
    bigStep = 0.01,
    isPercent = true,
  },
  crop_y = {
    display = L["Crop Y"],
    setter = "SetCropY",
    type = "number",
    min = 0,
    softMax = 2,
    bigStep = 0.01,
    isPercent = true,
  },
}

Private.regionPrototype.AddProperties(properties, default);

local function GetProperties(data)
  local overlayInfo = Private.GetOverlayInfo(data);
  local auraProperties = CopyTable(properties)
  auraProperties.progressSource.values = Private.GetProgressSourcesForUi(data)
  if (overlayInfo and next(overlayInfo)) then
    for id, display in ipairs(overlayInfo) do
      auraProperties["overlays." .. id] = {
        display = string.format(L["%s Overlay Color"], display),
        setter = "SetOverlayColor",
        arg1 = id,
        type = "color",
      }
    end
    return auraProperties
  else
    return auraProperties
  end
end


local TextureSetValueFunction = function(self, progress)
  self.progress = progress;
  progress = max(0, progress);
  progress = min(1, progress);
  self.foreground:SetValue(0, progress);
end

local CircularSetValueFunctions = {
  ["CLOCKWISE"] = function(self, progress)
    local startAngle = self.startAngle;
    local endAngle = self.endAngle;
    progress = progress or 0;
    self.progress = progress;

    if (progress < 0) then
      progress = 0;
    end

    if (progress > 1) then
      progress = 1;
    end

    local pAngle = (endAngle - startAngle) * progress + startAngle;
    self.foregroundSpinner:SetProgress(startAngle, pAngle);
  end,
  ["ANTICLOCKWISE"] = function(self, progress)
    local startAngle = self.startAngle;
    local endAngle = self.endAngle;
    progress = progress or 0;
    self.progress = progress;

    if (progress < 0) then
      progress = 0;
    end

    if (progress > 1) then
      progress = 1;
    end
    progress = 1 - progress;

    local pAngle = (endAngle - startAngle) * progress + startAngle;
    self.foregroundSpinner:SetProgress(pAngle, endAngle);
  end
}

local function hideExtraTextures(extraTextures, from)
  for i = from, #extraTextures do
    extraTextures[i]:Hide();
  end
end

local function ensureExtraTextures(region, count)
  local auraRotationRadians = region.auraRotation / 180 * math.pi
  for i = #region.extraTextures + 1, count do
    local extraTexture = Private.LinearProgressTextureBase.create(region, "ARTWORK", min(i, 7));
    Private.LinearProgressTextureBase.modify(extraTexture, {
      offset = 0,
      blendMode = region.foreground:GetBlendMode(),
      desaturated = false,
      auraRotation = auraRotationRadians,
      texture = region.currentTexture,
      textureWrapMode = region.textureWrapMode,
      crop_x = region.crop_x,
      crop_y = region.crop_y,
      user_x = region.user_x,
      user_y = region.user_y,
      mirror = region.mirror,
      texRotation = region.effectiveTexRotation,
      width = region.width,
      height = region.height
    })
    extraTexture:SetOrientation(region.orientation, region.compress, region.slanted, region.slant,
                                region.slantFirst, region.slantMode)
    region.extraTextures[i] = extraTexture;
  end
end

local function ensureExtraSpinners(region, count)
  local auraRotationRadians = region.auraRotation / 180 * math.pi
  for i = #region.extraSpinners + 1, count do
    local extraSpinner = Private.CircularProgressTextureBase.create(region, "OVERLAY", min(i, 7))
    Private.CircularProgressTextureBase.modify(extraSpinner, {
      crop_x = region.crop_x,
      crop_y = region.crop_y,
      mirror = region.mirror,
      texRotation = region.effectiveTexRotation,
      texture = region.currentTexture,
      blendMode = region.foreground:GetBlendMode(),
      desaturated = false,
      auraRotation = auraRotationRadians,
      width = region.width,
      height = region.height,
      offset = 0
    })

    extraSpinner:SetScale(region.scalex, region.scaley)

    region.extraSpinners[i] = extraSpinner
  end
end

local function convertToProgress(rprogress, additionalProgress, adjustMin, totalWidth, inverse, clamp)
  local startProgress = 0;
  local endProgress = 0;

  if (additionalProgress.min and additionalProgress.max) then
    if (totalWidth ~= 0) then
      startProgress = (additionalProgress.min - adjustMin) / totalWidth;
      endProgress = (additionalProgress.max - adjustMin) / totalWidth;

      if (inverse) then
        startProgress = 1 - startProgress;
        endProgress = 1 - endProgress;
      end
    end
  elseif (additionalProgress.direction) then
    local forwardDirection = (additionalProgress.direction or "forward") == "forward";
    if (inverse) then
      forwardDirection = not forwardDirection;
    end
    local width = additionalProgress.width or 0;
    local offset = additionalProgress.offset or 0;
    if (width ~= 0) then
      if (forwardDirection) then
        startProgress = rprogress + offset / totalWidth ;
        endProgress = rprogress + (offset + width) / totalWidth;
      else
        startProgress = rprogress - (width + offset) / totalWidth;
        endProgress = rprogress - offset / totalWidth;
      end
    end
  end

  if (clamp) then
    startProgress = max(0, min(1, startProgress));
    endProgress = max(0, min(1, endProgress));
  end

  return startProgress, endProgress;
end

local function ApplyAdditionalProgressLinear(self, additionalProgress, min, max, inverse)
  self.additionalProgress = additionalProgress;
  self.additionalProgressMin = min;
  self.additionalProgressMax = max;
  self.additionalProgressInverse = inverse;

  local effectiveInverse = (inverse and not self.inverseDirection) or (not inverse and self.inverseDirection);

  if (additionalProgress) then
    ensureExtraTextures(self, #additionalProgress);
    local totalWidth = max - min;
    for index, additionalProgress in ipairs(additionalProgress) do
      local extraTexture = self.extraTextures[index];

      local startProgress, endProgress = convertToProgress(self.progress, additionalProgress, min,
                                                           totalWidth, effectiveInverse, self.overlayclip)
      if ((endProgress - startProgress) == 0) then
        extraTexture:Hide();
      else
        extraTexture:Show();
        local color = self.overlays[index];
        if (color) then
          extraTexture:SetColor(unpack(color));
        else
          extraTexture:SetColor(1, 1, 1, 1);
        end

        extraTexture:SetValue(startProgress, endProgress)
      end
    end

    hideExtraTextures(self.extraTextures, #additionalProgress + 1);
  else
    hideExtraTextures(self.extraTextures, 1);
  end
end

local function ApplyAdditionalProgressCircular(self, additionalProgress, min, max, inverse)
  self.additionalProgress = additionalProgress;
  self.additionalProgressMin = min;
  self.additionalProgressMax = max;
  self.additionalProgressInverse = inverse;

  local effectiveInverse = (inverse and not self.inverseDirection) or (not inverse and self.inverseDirection);

  if (additionalProgress) then
    ensureExtraSpinners(self, #additionalProgress);
    local totalWidth = max - min;
    for index, additionalProgress in ipairs(additionalProgress) do
      local extraSpinner = self.extraSpinners[index];

      local startProgress, endProgress = convertToProgress(self.progress, additionalProgress, min,
                                                           totalWidth, effectiveInverse, self.overlayclip)
      if (endProgress < startProgress) then
        startProgress, endProgress = endProgress, startProgress;
      end

      if (self.orientation == "ANTICLOCKWISE") then
        startProgress, endProgress = 1 - endProgress, 1 - startProgress;
      end

      if ((endProgress - startProgress) == 0) then
        extraSpinner:SetProgress(0, 0)
      else
        local color = self.overlays[index];
        if (color) then
          extraSpinner:SetColor(unpack(color));
        else
          extraSpinner:SetColor(1, 1, 1, 1);
        end

        local startAngle = self.startAngle;
        local diffAngle = self.endAngle - startAngle;
        local pAngleStart = diffAngle * startProgress + startAngle;
        local pAngleEnd = diffAngle * endProgress + startAngle;

        if (pAngleStart < 0) then
          pAngleStart = pAngleStart + 360;
          pAngleEnd = pAngleEnd + 360;
        end

        extraSpinner:SetProgress(pAngleStart, pAngleEnd)
      end
    end

  else
    hideExtraTextures(self.extraSpinners, 1);
  end
end

local function FrameTick(self)
  local duration = self.duration
  local expirationTime = self.expirationTime
  local inverse = self.inverse

  local progress = 1;
  if (duration ~= 0) then
    local remaining = expirationTime - GetTime();
    progress = remaining / duration;
    local inversed = not inverse ~= not self.inverseDirection
    if(inversed) then
      progress = 1 - progress;
    end
  end

  progress = progress > 0.0001 and progress or 0.0001;

  if (self.useSmoothProgress) then
    self.smoothProgress:SetSmoothedValue(progress);
  else
    self:SetValueOnTexture(progress);
    self:ReapplyAdditionalProgress()
  end
end

local funcs = {
  ForAllSpinners = function(self, f, ...)
    f(self.foregroundSpinner, ...)
    f(self.backgroundSpinner, ...)
    for i, extraSpinner in ipairs(self.extraSpinners) do
      f(extraSpinner, ...)
    end
  end,
  ForAllLinears = function(self, f, ...)
    f(self.foreground, ...)
    f(self.background, ...)
    for _, extraTexture in ipairs(self.extraTextures) do
      f(extraTexture, ...)
    end
  end,
  SetOrientation = function (self, orientation)
    self.orientation = orientation
    if(self.orientation == "CLOCKWISE" or self.orientation == "ANTICLOCKWISE") then
      self.circular = true
      self.foreground:Hide()
      self.background:Hide()
      self.foregroundSpinner:Show()
      self.backgroundSpinner:Show()

      for i = 1, #self.extraTextures do
        self.extraTextures[i]:Hide()
      end
      self.foregroundSpinner:UpdateTextures()
      self.backgroundSpinner:UpdateTextures()
      self.SetValueOnTexture = CircularSetValueFunctions[self.orientation]
      self.ApplyAdditionalProgress = ApplyAdditionalProgressCircular
    else
      self.circular = false
      self.foreground:Show()
      self.background:Show()
      self.foregroundSpinner:Hide()
      self.backgroundSpinner:Hide()

      for i = 1, #self.extraSpinners do
        self.extraSpinners[i]:Hide()
      end
      self.background:SetOrientation(orientation, nil, self.slanted, self.slant,
                                       self.slantFirst, self.slantMode)
      self.foreground:SetOrientation(orientation, self.compress, self.slanted, self.slant,
                                       self.slantFirst, self.slantMode)
      self.SetValueOnTexture = TextureSetValueFunction;
      self.ApplyAdditionalProgress = ApplyAdditionalProgressLinear

      for _, extraTexture in ipairs(self.extraTextures) do
        extraTexture:SetOrientation(orientation, self.compress, self.slanted, self.slant,
                                    self.slantFirst, self.slantMode)
      end
    end
    self:SetValueOnTexture(self.progress)
    self:ReapplyAdditionalProgress()
  end,
  SetAnimRotation = function(self, angle)
    self.texAnimationRotation = angle
    self:UpdateEffectiveRotation()
  end,
  SetTexRotation = function(self, angle)
    self.texRotation = angle
    self:UpdateEffectiveRotation()
  end,
  GetBaseRotation = function(self)
    return self.texRotation
  end,
  Color = function(self, r, g, b, a)
    self.color_r = r
    self.color_g = g
    self.color_b = b
    if (r or g or b) then
      a = a or 1
    end
    self.color_a = a
    self.foreground:SetColor(self.color_anim_r or r, self.color_anim_g or g,
                                   self.color_anim_b or b, self.color_anim_a or a)
    self.foregroundSpinner:SetColor(self.color_anim_r or r, self.color_anim_g or g,
                                    self.color_anim_b or b, self.color_anim_a or a)
  end,
  ColorAnim = function(self, r, g, b, a)
    self.color_anim_r = r
    self.color_anim_g = g
    self.color_anim_b = b
    self.color_anim_a = a
    if (r or g or b) then
      a = a or 1;
    end
    self.foreground:SetColor(r or self.color_r, g or self.color_g, b or self.color_b, a or self.color_a)
    self.foregroundSpinner:SetColor(r or self.color_r, g or self.color_g, b or self.color_b, a or self.color_a)
  end,
  GetColor = function(self)
    return self.color_r, self.color_g, self.color_b, self.color_a
  end,
  SetAuraRotation = function(self, auraRotation)
    self.auraRotation = auraRotation
    local auraRotationRadians = self.auraRotation / 180 * math.pi
    self:ForAllSpinners(self.foregroundSpinner.SetAuraRotation, auraRotationRadians)

    self.background:SetAuraRotation(auraRotationRadians)
    self.foreground:SetAuraRotation(auraRotationRadians)
    for _, extraTexture in ipairs(self.extraTextures) do
      extraTexture:SetAuraRotation(auraRotationRadians)
    end
  end,
  DoPosition = function(self)
    self:SetWidth(self.width * self.scalex);
    self:SetHeight(self.height * self.scaley);

    if self.orientation == "CLOCKWISE" or self.orientation == "ANTICLOCKWISE" then
      self:ForAllSpinners(self.foregroundSpinner.UpdateTextures)
    else
      self:ForAllLinears(self.foreground.Update)
    end
  end,
  SetMirror = function(self, mirror)
    self.mirror = mirror
    self:ForAllSpinners(self.foregroundSpinner.SetMirror, mirror)
    self:ForAllLinears(self.foreground.SetMirror, mirror)
  end,
  UpdateTextures = function(self)
    if self.circular then
      self:ForAllSpinners(self.foregroundSpinner.UpdateTextures)
    else
      self:ForAllLinears(self.foreground.UpdateTextures)
    end
  end,
  SetCropX = function(self, x)
    self.crop_x = 1 + x
    self:ForAllSpinners(self.foregroundSpinner.SetCropX, self.crop_x)
    self:ForAllLinears(self.foreground.SetCropX, self.crop_x)
  end,
  SetCropY = function(self, y)
    self.crop_y = 1 + y
    self:ForAllSpinners(self.foregroundSpinner.SetCropY, self.crop_y)
    self:ForAllLinears(self.foreground.SetCropX, self.crop_x)
  end,
  UpdateEffectiveRotation = function(self)
    self.effectiveTexRotation = self.texAnimationRotation or self.texRotation
    self:ForAllSpinners(self.foregroundSpinner.SetTexRotation, self.effectiveTexRotation)
    self:ForAllLinears(self.foreground.SetTexRotation, self.effectiveTexRotation)
  end,
  UpdateTime = function(self)
    local progress = 1
    if self.duration ~= 0 then
      local remaining = self.expirationTime - GetTime()
      progress = remaining / self.duration
      local inversed = not self.inverse ~= not self.inverseDirection
      if inversed then
        progress = 1 - progress
      end
    end

    progress = progress > 0.0001 and progress or 0.0001;
    if (self.useSmoothProgress) then
      self.smoothProgress:SetSmoothedValue(progress);
    else
      self:SetValueOnTexture(progress);
      self:ReapplyAdditionalProgress()
    end

    if self.paused and self.FrameTick then
      self.FrameTick = nil
      self.subRegionEvents:RemoveSubscriber("FrameTick", self)
    end
    if not self.paused and not self.FrameTick then
      self.FrameTick = FrameTick
      self.subRegionEvents:AddSubscriber("FrameTick", self)
    end
  end,
  UpdateValue = function(self)
    local progress = 1
    if(self.total > 0) then
      progress = self.value / self.total;
      if self.inverseDirection then
        progress = 1 - progress;
      end
    end
    progress = progress > 0.0001 and progress or 0.0001;
    if self.useSmoothProgress then
      self.smoothProgress:SetSmoothedValue(progress);
    else
      self:SetValueOnTexture(progress);
      self:ReapplyAdditionalProgress()
    end

    if self.FrameTick then
      self.FrameTick = nil
      self.subRegionEvents:RemoveSubscriber("FrameTick", self)
    end
  end,
  SetAdditionalProgress = function(self, additionalProgress, currentMin, currentMax, inverse)
    self:ApplyAdditionalProgress(additionalProgress, currentMin, currentMax, inverse)
  end,
  ReapplyAdditionalProgress = function(self)
    self:ApplyAdditionalProgress(self.additionalProgress, self.additionalProgressMin,
                                 self.additionalProgressMax, self.additionalProgressInverse)
  end,
  Update = function(self)
    self:UpdateProgress()
    local state = self.state

    if state.texture then
      self:SetTexture(state.texture)
    end
  end,
  SetTexture = function(self, texture)
    self.currentTexture = texture
    self.foreground:SetTextureOrAtlas(texture, self.textureWrapMode)
    self.foregroundSpinner:SetTextureOrAtlas(texture);
    if self.sameTexture then
      self.background:SetTextureOrAtlas(texture, self.textureWrapMode)
      self.backgroundSpinner:SetTextureOrAtlas(texture);
    end

    for _, extraTexture in ipairs(self.extraTextures) do
      extraTexture:SetTextureOrAtlas(texture, self.textureWrapMode)
    end

    for _, extraSpinner in ipairs(self.extraSpinners) do
      extraSpinner:SetTextureOrAtlas(texture);
    end
  end,
  SetForegroundDesaturated = function(self, b)
    self.foreground:SetDesaturated(b)
    self.foregroundSpinner:SetDesaturated(b)
  end,
  SetBackgroundDesaturated = function(self, b)
    self.background:SetDesaturated(b)
    self.backgroundSpinner:SetDesaturated(b)
  end,
  SetBackgroundColor = function(self, r, g, b, a)
    self.background:SetColor(r, g, b, a)
    self.backgroundSpinner:SetColor(r, g, b, a)
  end,
  SetRegionWidth = function(self, width)
    self.width = width;
    self:ForAllSpinners(self.foregroundSpinner.SetWidth, width)
    self:ForAllLinears(self.foreground.SetWidth, width)
    self:Scale(self.scalex, self.scaley)
  end,
  SetRegionHeight = function(self, height)
    self.height = height
    self:ForAllSpinners(self.foregroundSpinner.SetHeight, height)
    self:ForAllSpinners(self.foreground.SetHeight, height)
    self:Scale(self.scalex, self.scaley)
  end,
  Scale = function(self, scalex, scaley)
    if(scalex < 0) then
      self.mirror_h = true
      scalex = scalex * -1
    end

    if(scaley < 0) then
      self.mirror_v = true
      scaley = scaley * -1
    end

    self.scalex = scalex
    self.scaley = scaley

    self:ForAllSpinners(self.foregroundSpinner.SetScale, self.scalex, self.scaley)
    self:ForAllSpinners(self.foregroundSpinner.SetMirrorHV, self.mirror_h, self.mirror_v)
    self:ForAllLinears(self.foreground.SetMirrorHV, self.mirror_h, self.mirror_v)
    self:DoPosition()
  end,
  SetInverse = function(self, inverse)
    if self.inverseDirection == inverse then
      return
    end
    self.inverseDirection = inverse
    local progress = 1 - self.progress;
    progress = progress > 0.0001 and progress or 0.0001;
    self:SetValueOnTexture(progress)
    self:ReapplyAdditionalProgress()
  end,
  SetOverlayColor = function(self, id, r, g, b, a)
    self.overlays[id] = { r, g, b, a};
    if self.extraTextures[id] then
      self.extraTextures[id]:SetColor(r, g, b, a);
    end
    if self.extraSpinners[id] then
      self.extraSpinners[id]:SetColor(r, g, b, a);
    end
  end
}

local function create(parent)
  local region = CreateFrame("Frame", nil, parent);
  region.regionType = "progresstexture"
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetResizeBounds(1, 1)

  local background = Private.LinearProgressTextureBase.create(region, "BACKGROUND", 0);
  region.background = background;

  -- For horizontal/vertical progress
  local foreground = Private.LinearProgressTextureBase.create(region, "ARTWORK", 0);
  region.foreground = foreground;

  region.foregroundSpinner = Private.CircularProgressTextureBase.create(region, "ARTWORK", 1)
  region.backgroundSpinner = Private.CircularProgressTextureBase.create(region, "BACKGROUND", 1)

  region.extraTextures = {};
  region.extraSpinners = {};

  -- Use a dummy object for the SmoothStatusBarMixin, because our SetValue
  -- is used for a different purpose
  region.smoothProgress = {};
  Mixin(region.smoothProgress, Private.SmoothStatusBarMixin);
  region.smoothProgress.SetValue = function(self, progress)
    region:SetValueOnTexture(progress);
    region:ReapplyAdditionalProgress()
  end

  region.smoothProgress.GetValue = function(self)
    return region.progress;
  end

  region.smoothProgress.GetMinMaxValues = function(self)
    return 0, 1;
  end

  for k, func in pairs(funcs) do
    region[k] = func
  end

  Private.regionPrototype.create(region);

  return region;
end


local function modify(parent, region, data)
  Private.regionPrototype.modify(parent, region, data);

  local background, foreground = region.background, region.foreground;
  local foregroundSpinner, backgroundSpinner = region.foregroundSpinner, region.backgroundSpinner;

  background:Hide()
  foreground:Hide()
  foregroundSpinner:Hide()
  backgroundSpinner:Hide()

  region:SetWidth(data.width);
  region:SetHeight(data.height);
  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;
  region.aspect =  data.width / data.height;
  region.overlayclip = data.overlayclip;

  region.textureWrapMode = data.textureWrapMode;
  region.useSmoothProgress = data.smoothProgress
  region.sameTexture = data.sameTexture
  region.mirror = data.mirror
  region.crop_x = 1 + data.crop_x
  region.crop_y = 1 + data.crop_y
  region.texRotation = data.rotation or 0
  region.user_x = -1 * (data.user_x or 0);
  region.user_y = data.user_y or 0;
  region.startAngle = (data.startAngle or 0) % 360;
  region.endAngle = (data.endAngle or 360) % 360;
  if (region.endAngle <= region.startAngle) then
    region.endAngle = region.endAngle + 360;
  end
  region.compress = data.compress;
  region.inverseDirection = data.inverse;
  region.progress = 0.667;
  if (data.overlays) then
    region.overlays = CopyTable(data.overlays)
  else
    region.overlays = {}
  end
  region.slanted = data.slanted;
  region.slant = data.slant;
  region.slantFirst = data.slantFirst;
  region.slantMode = data.slantMode;
  region.auraRotation = data.auraRotation
  region.texRotation = data.rotation

  if region.useSmoothProgress then
    region.PreShow = function()
      region.smoothProgress:ResetSmoothedValue();
    end
  else
    region.PreShow = nil
  end

  region.FrameTick = nil

  local auraRotationRadians = region.auraRotation / 180 * math.pi

  region.currentTexture = data.foregroundTexture

  Private.LinearProgressTextureBase.modify(region.background, {
    offset = data.backgroundOffset,
    texture = data.sameTexture and data.foregroundTexture or data.backgroundTexture,
    textureWrapMode = region.textureWrapMode,
    desaturated = data.desaturateBackground,
    blendMode = data.blendMode,
    auraRotation = auraRotationRadians,
    crop_x = region.crop_x,
    crop_y = region.crop_y,
    user_x = region.user_x,
    user_y = region.user_y,
    mirror = region.mirror,
    texRotation = region.texRotation,
    width = data.width,
    height = data.height
  })

  background:SetColor(data.backgroundColor[1], data.backgroundColor[2],
                      data.backgroundColor[3], data.backgroundColor[4])

  Private.LinearProgressTextureBase.modify(region.foreground, {
    offset = 0,
    texture = data.foregroundTexture,
    textureWrapMode = region.textureWrapMode,
    desaturated = data.desaturateForeground,
    blendMode = data.blendMode,
    auraRotation = auraRotationRadians,
    crop_x = region.crop_x,
    crop_y = region.crop_y,
    user_x = region.user_x,
    user_y = region.user_y,
    mirror = region.mirror,
    texRotation = region.texRotation,
    width = data.width,
    height = data.height
  })

  --- @type LinearProgressTextureOptions
  local linearOptions = {
    offset = 0,
    texture = data.foregroundTexture,
    textureWrapMode = region.textureWrapMode,
    desaturated = false,
    blendMode = data.blendMode,
    auraRotation = auraRotationRadians,
    crop_x = region.crop_x,
    crop_y = region.crop_y,
    user_x = region.user_x,
    user_y = region.user_y,
    mirror = region.mirror,
    texRotation = region.texRotation,
    width = data.width,
    height = data.height
  }
  for _, extraTexture in ipairs(region.extraTextures) do
    Private.LinearProgressTextureBase.modify(extraTexture, linearOptions)
  end

  Private.CircularProgressTextureBase.modify(region.foregroundSpinner, {
    crop_x = region.crop_x,
    crop_y = region.crop_y,
    mirror = data.mirror,
    texRotation = region.texRotation,
    texture = data.foregroundTexture,
    blendMode = data.blendMode,
    desaturated = data.desaturateForeground,
    auraRotation = auraRotationRadians,
    width = data.width,
    height = data.height,
    offset = 0
  })

  Private.CircularProgressTextureBase.modify(region.backgroundSpinner, {
    crop_x = region.crop_x,
    crop_y = region.crop_y,
    mirror = data.mirror,
    texRotation = region.texRotation,
    texture = data.sameTexture and data.foregroundTexture or data.backgroundTexture,
    blendMode = data.blendMode,
    desaturated = data.desaturateBackground,
    auraRotation = auraRotationRadians,
    width = data.width,
    height = data.height,
    offset = data.backgroundOffset
  })

  backgroundSpinner:SetColor(data.backgroundColor[1], data.backgroundColor[2],
                          data.backgroundColor[3], data.backgroundColor[4])
  backgroundSpinner:SetProgress(region.startAngle, region.endAngle)

  --- @type CircularProgressTextureOptions
  local spinnerOptions = {
    crop_x = region.crop_x,
    crop_y = region.crop_y,
    mirror = data.mirror,
    texRotation = region.texRotation,
    texture = data.foregroundTexture,
    blendMode = data.blendMode,
    desaturated = false,
    auraRotation = auraRotationRadians,
    width = data.width,
    height = data.height,
    offset = 0
  }
  for _, extraSpinner in ipairs(region.extraSpinners) do
    Private.CircularProgressTextureBase.modify(extraSpinner, spinnerOptions)
  end

  region:SetOrientation(data.orientation);
  region:DoPosition(region)
  region:Color(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);

  Private.regionPrototype.modifyFinish(parent, region, data);
end

local function validate(data)
  Private.EnforceSubregionExists(data, "subbackground")
end

Private.RegisterRegionType("progresstexture", create, modify, default, GetProperties, validate);
