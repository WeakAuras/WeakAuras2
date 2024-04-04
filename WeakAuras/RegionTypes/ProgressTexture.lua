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

local spinnerFunctions = {};

function spinnerFunctions.SetAuraRotation(self, radians)
  for i = 1, 3 do
    self.textures[i]:SetRotation(radians)
  end
end

function spinnerFunctions.SetTextureOrAtlas(self, texture)
  for i = 1, 3 do
    Private.SetTextureOrAtlas(self.textures[i], texture)
  end
end

function spinnerFunctions.SetDesaturated(self, desaturate)
  for i = 1, 3 do
    self.textures[i]:SetDesaturated(desaturate);
  end
end

function spinnerFunctions.SetBlendMode(self, blendMode)
  for i = 1, 3 do
    self.textures[i]:SetBlendMode(blendMode);
  end
end

function spinnerFunctions.Show(self)
  for i = 1, 3 do
    self.textures[i]:Show();
  end
end

function spinnerFunctions.Hide(self)
  for i = 1, 3 do
    self.textures[i]:Hide();
  end
end

function spinnerFunctions.Color(self, r, g, b, a)
  for i = 1, 3 do
    self.textures[i]:SetVertexColor(r, g, b, a);
  end
end

function spinnerFunctions.UpdateSize(self)
  if (self.region) then
    self:SetProgress(self.region, self.angle1, self.angle2);
  end
end

function spinnerFunctions.SetProgress(self, region, angle1, angle2)
  self.region = region;
  self.angle1 = angle1;
  self.angle2 = angle2;

  local crop_x = region.crop_x or 1;
  local crop_y = region.crop_y or 1;
  local texRotation = region.effectiveTexRotation or 0
  local mirror_h = region.mirror_h or false;
  if region.mirror then
    mirror_h = not mirror_h
  end
  local mirror_v = region.mirror_v or false;

  local width = region.width * (region.scalex or 1) + 2 * self.offset;
  local height = region.height * (region.scaley or 1) + 2 * self.offset;

  if (angle2 - angle1 >= 360) then
    -- SHOW everything
    self.coords[1]:SetFull();
    self.coords[1]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
    self.coords[1]:Show();

    self.coords[2]:Hide();
    self.coords[3]:Hide();
    return;
  end
  if (angle1 == angle2) then
    self.coords[1]:Hide();
    self.coords[2]:Hide();
    self.coords[3]:Hide();
    return;
  end

  local index1 = floor((angle1 + 45) / 90);
  local index2 = floor((angle2 + 45) / 90);

  if (index1 + 1 >= index2) then
    self.coords[1]:SetAngle(width, height, angle1, angle2);
    self.coords[1]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
    self.coords[1]:Show();
    self.coords[2]:Hide();
    self.coords[3]:Hide();
  elseif(index1 + 3 >= index2) then
    local firstEndAngle = (index1 + 1) * 90 + 45;
    self.coords[1]:SetAngle(width, height, angle1, firstEndAngle);
    self.coords[1]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
    self.coords[1]:Show();

    self.coords[2]:SetAngle(width, height, firstEndAngle, angle2);
    self.coords[2]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
    self.coords[2]:Show();

    self.coords[3]:Hide();
  else
    local firstEndAngle = (index1 + 1) * 90 + 45;
    local secondEndAngle = firstEndAngle + 180;

    self.coords[1]:SetAngle(width, height, angle1, firstEndAngle);
    self.coords[1]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
    self.coords[1]:Show();

    self.coords[2]:SetAngle(width, height, firstEndAngle, secondEndAngle);
    self.coords[2]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
    self.coords[2]:Show();

    self.coords[3]:SetAngle(width, height, secondEndAngle, angle2);
    self.coords[3]:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
    self.coords[3]:Show();
  end
end

function spinnerFunctions.SetBackgroundOffset(self, region, offset)
  self.offset = offset;
  for i = 1, 3 do
    self.textures[i]:SetPoint('TOPRIGHT', region, offset, offset)
    self.textures[i]:SetPoint('BOTTOMRIGHT', region, offset, -offset)
    self.textures[i]:SetPoint('BOTTOMLEFT', region, -offset, -offset)
    self.textures[i]:SetPoint('TOPLEFT', region, -offset, offset)
  end
  self:UpdateSize();
end

function spinnerFunctions:SetHeight(height)
  for i = 1, 3 do
    self.textures[i]:SetHeight(height);
  end
end

function spinnerFunctions:SetWidth(width)
  for i = 1, 3 do
    self.textures[i]:SetWidth(width);
  end
end

local defaultTexCoord = {
  ULx = 0,
  ULy = 0,
  LLx = 0,
  LLy = 1,
  URx = 1,
  URy = 0,
  LRx = 1,
  LRy = 1,
};

local function createTexCoord(texture)
  local coord = {
    ULx = 0,
    ULy = 0,
    LLx = 0,
    LLy = 1,
    URx = 1,
    URy = 0,
    LRx = 1,
    LRy = 1,

    ULvx = 0,
    ULvy = 0,
    LLvx = 0,
    LLvy = 0,
    URvx = 0,
    URvy = 0,
    LRvx = 0,
    LRvy = 0,

    texture = texture;
  };

  function coord:MoveCorner(width, height, corner, x, y)
    local rx = defaultTexCoord[corner .. "x"] - x;
    local ry = defaultTexCoord[corner .. "y"] - y;
    coord[corner .. "vx"] = -rx * width;
    coord[corner .. "vy"] = ry * height;

    coord[corner .. "x"] = x;
    coord[corner .. "y"] = y;
  end

  function coord:Hide()
    coord.texture:Hide();
  end

  function coord:Show()
    coord:Apply();
    coord.texture:Show();
  end

  function coord:SetFull()
    coord.ULx = 0;
    coord.ULy = 0;
    coord.LLx = 0;
    coord.LLy = 1;
    coord.URx = 1;
    coord.URy = 0;
    coord.LRx = 1;
    coord.LRy = 1;

    coord.ULvx = 0;
    coord.ULvy = 0;
    coord.LLvx = 0;
    coord.LLvy = 0;
    coord.URvx = 0;
    coord.URvy = 0;
    coord.LRvx = 0;
    coord.LRvy = 0;
  end

  function coord:Apply()
    coord.texture:SetVertexOffset(UPPER_RIGHT_VERTEX, coord.URvx, coord.URvy);
    coord.texture:SetVertexOffset(UPPER_LEFT_VERTEX, coord.ULvx, coord.ULvy);
    coord.texture:SetVertexOffset(LOWER_RIGHT_VERTEX, coord.LRvx, coord.LRvy);
    coord.texture:SetVertexOffset(LOWER_LEFT_VERTEX, coord.LLvx, coord.LLvy);

    coord.texture:SetTexCoord(coord.ULx, coord.ULy, coord.LLx, coord.LLy, coord.URx, coord.URy, coord.LRx, coord.LRy);
  end

  local exactAngles = {
    {0.5, 0},  -- 0°
    {1, 0},    -- 45°
    {1, 0.5},  -- 90°
    {1, 1},    -- 135°
    {0.5, 1},  -- 180°
    {0, 1},    -- 225°
    {0, 0.5},  -- 270°
    {0, 0}     -- 315°
  }

  local function angleToCoord(angle)
    angle = angle % 360;

    if (angle % 45 == 0) then
      local index = floor (angle / 45) + 1;
      return exactAngles[index][1], exactAngles[index][2];
    end

    if (angle < 45) then
      return 0.5 + tan(angle) / 2, 0;
    elseif (angle < 135) then
      return 1, 0.5 + tan(angle - 90) / 2 ;
    elseif (angle < 225) then
      return 0.5 - tan(angle) / 2, 1;
    elseif (angle < 315) then
      return 0, 0.5 - tan(angle - 90) / 2;
    elseif (angle < 360) then
      return 0.5 + tan(angle) / 2, 0;
    end
  end

  local pointOrder = { "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR" }

  function coord:SetAngle(width, height, angle1, angle2)
    local index = floor((angle1 + 45) / 90);

    local middleCorner = pointOrder[index + 1];
    local startCorner = pointOrder[index + 2];
    local endCorner1 = pointOrder[index + 3];
    local endCorner2 = pointOrder[index + 4];

    -- LL => 32, 32
    -- UL => 32, -32
    self:MoveCorner(width, height, middleCorner, 0.5, 0.5)
    self:MoveCorner(width, height, startCorner, angleToCoord(angle1));

    local edge1 = floor((angle1 - 45) / 90);
    local edge2 = floor((angle2 -45) / 90);

    if (edge1 == edge2) then
      self:MoveCorner(width, height, endCorner1, angleToCoord(angle2));
    else
      self:MoveCorner(width, height, endCorner1, defaultTexCoord[endCorner1 .. "x"], defaultTexCoord[endCorner1 .. "y"])
    end

    self:MoveCorner(width, height, endCorner2, angleToCoord(angle2));
  end

  local function TransformPoint(x, y, scalex, scaley, texRotation, mirror_h, mirror_v, user_x, user_y)
    -- 1) Translate texture-coords to user-defined center
    x = x - 0.5
    y = y - 0.5

    -- 2) Shrink texture by 1/sqrt(2)
    x = x * 1.4142
    y = y * 1.4142

    -- Not yet supported for circular progress
    -- 3) Scale texture by user-defined amount
    x = x / scalex
    y = y / scaley

    -- 4) Apply mirroring if defined
    if mirror_h then
      x = -x
    end
    if mirror_v then
      y = -y
    end

    local cos_rotation = cos(texRotation)
    local sin_rotation = sin(texRotation)

    -- 5) Rotate texture by user-defined value
    x, y = cos_rotation * x - sin_rotation * y, sin_rotation * x + cos_rotation * y

    -- 6) Translate texture-coords back to (0,0)
    x = x + 0.5
    y = y + 0.5

    x = x + (user_x or 0);
    y = y + (user_y or 0);

    return x, y
  end

  function coord:Transform(scalex, scaley, texRotation, mirror_h, mirror_v, user_x, user_y)
      coord.ULx, coord.ULy = TransformPoint(coord.ULx, coord.ULy, scalex, scaley,
                                            texRotation, mirror_h, mirror_v, user_x, user_y)
      coord.LLx, coord.LLy = TransformPoint(coord.LLx, coord.LLy, scalex, scaley,
                                            texRotation, mirror_h, mirror_v, user_x, user_y)
      coord.URx, coord.URy = TransformPoint(coord.URx, coord.URy, scalex, scaley,
                                            texRotation, mirror_h, mirror_v, user_x, user_y)
      coord.LRx, coord.LRy = TransformPoint(coord.LRx, coord.LRy, scalex, scaley,
                                            texRotation, mirror_h, mirror_v, user_x, user_y)
  end

  return coord;
end


local function createSpinner(parent, layer, drawlayer)
  local spinner = {};
  spinner.textures = {};
  spinner.coords = {};
  spinner.offset = 0;

  for i = 1, 3 do
    local texture = parent:CreateTexture(nil, layer);
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
    texture:SetDrawLayer(layer, drawlayer);
    texture:SetAllPoints(parent);
    spinner.textures[i] = texture;

    spinner.coords[i] = createTexCoord(texture);
  end

  for k, v in pairs(spinnerFunctions) do
    spinner[k] = v;
  end

  return spinner;
end

-- Make available for the thumbnail display
WeakAuras.createSpinner = createSpinner;

local orientationToAnchorPoint = {
  ["HORIZONTAL"] = "LEFT",
  ["HORIZONTAL_INVERSE"] = "RIGHT",
  ["VERTICAL"] = "BOTTOM",
  ["VERTICAL_INVERSE"] = "TOP"
}

local textureFunctions = {
  SetValueFunctions = {
    ["HORIZONTAL"] = function(self, startProgress, endProgress)
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UL", startProgress, 0 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LL", startProgress, 1 );

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UR", endProgress, 0 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LR", endProgress, 1 );
    end,
    ["HORIZONTAL_INVERSE"] = function(self, startProgress, endProgress)
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UL", 1 - endProgress, 0 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LL", 1 - endProgress, 1 );

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UR", 1 - startProgress, 0 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LR", 1 - startProgress, 1 );
    end,
    ["VERTICAL"] = function(self, startProgress, endProgress)
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UL", 0, 1 - endProgress );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UR", 1, 1 - endProgress );

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LL", 0, 1 - startProgress );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LR", 1, 1 - startProgress );
    end,
    ["VERTICAL_INVERSE"] = function(self, startProgress, endProgress)
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UL", 0, startProgress );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UR", 1, startProgress );

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LL", 0, endProgress );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LR", 1, endProgress );
    end,
  },

  SetValueFunctionsSlanted = {
    ["HORIZONTAL"] = function(self, startProgress, endProgress)
      local slant = self.slant or 0;
      if (self.slantMode == "EXTEND") then
        startProgress = startProgress * (1 + slant) - slant;
        endProgress = endProgress * (1 + slant) - slant;
      else
        startProgress = startProgress * (1 - slant);
        endProgress = endProgress * (1 -  slant);
      end

      local slant1 = self.slantFirst and 0 or slant;
      local slant2 = self.slantFirst and slant or 0;

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UL", startProgress + slant1, 0 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LL", startProgress + slant2, 1 );

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UR", endProgress + slant1, 0 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LR", endProgress + slant2, 1 );
    end,
    ["HORIZONTAL_INVERSE"] = function(self, startProgress, endProgress)
      local slant = self.slant or 0;
      if (self.slantMode == "EXTEND") then
        startProgress = startProgress * (1 + slant) - slant;
        endProgress = endProgress * (1 + slant) - slant;
      else
        startProgress = startProgress * (1 - slant);
        endProgress = endProgress * (1 -  slant);
      end

      local slant1 = self.slantFirst and slant or 0;
      local slant2 = self.slantFirst and 0 or slant;

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UL", 1 - endProgress - slant1, 0 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LL", 1 - endProgress - slant2, 1 );

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UR", 1 - startProgress - slant1, 0 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LR", 1 - startProgress - slant2, 1 );
    end,
    ["VERTICAL"] = function(self, startProgress, endProgress)
      local slant = self.slant or 0;
      if (self.slantMode == "EXTEND") then
        startProgress = startProgress * (1 + slant) - slant;
        endProgress = endProgress * (1 + slant) - slant;
      else
        startProgress = startProgress * (1 - slant);
        endProgress = endProgress * (1 -  slant);
      end

      local slant1 = self.slantFirst and slant or 0;
      local slant2 = self.slantFirst and 0 or slant;

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UL", 0, 1 - endProgress - slant1 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UR", 1, 1 - endProgress - slant2 );

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LL", 0, 1 - startProgress - slant1 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LR", 1, 1 - startProgress - slant2 );
    end,
    ["VERTICAL_INVERSE"] = function(self, startProgress, endProgress)
      local slant = self.slant or 0;
      if (self.slantMode == "EXTEND") then
        startProgress = startProgress * (1 + slant) - slant;
        endProgress = endProgress * (1 + slant) - slant;
      else
        startProgress = startProgress * (1 - slant);
        endProgress = endProgress * (1 -  slant);
      end

      local slant1 = self.slantFirst and 0 or slant;
      local slant2 = self.slantFirst and slant or 0;

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UL", 0, startProgress + slant1 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "UR", 1, startProgress + slant2 );

      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LL", 0, endProgress + slant1 );
      self.coord:MoveCorner(self:GetWidth(), self:GetHeight(), "LR", 1, endProgress + slant2 );
    end,
  },

  SetBackgroundOffset = function(self, backgroundOffset)
    self.backgroundOffset = backgroundOffset;
  end,

  SetOrientation = function(self, orientation, compress, slanted, slant, slantFirst, slantMode)
    self.SetValueFunction = slanted and self.SetValueFunctionsSlanted[orientation]
                            or self.SetValueFunctions[orientation]
    self.compress = compress;
    self.slanted = slanted;
    self.slant = slant;
    self.slantFirst = slantFirst;
    self.slantMode = slantMode;
    if (self.compress) then
      self:ClearAllPoints();
      local anchor = orientationToAnchorPoint[orientation];
      self:SetPoint(anchor, self.region, anchor);
      self.horizontal = orientation == "HORIZONTAL" or orientation == "HORIZONTAL_INVERSE";
    else
      local offset = self.backgroundOffset or 0;
      self:ClearAllPoints();
      self:SetPoint("BOTTOMLEFT", self.region, "BOTTOMLEFT", -1 * offset, -1 * offset);
      self:SetPoint("TOPRIGHT", self.region, "TOPRIGHT", offset, offset);
    end
    self:Update();
  end,

  SetValue = function(self, startProgress, endProgress)
    self.startProgress = startProgress;
    self.endProgress = endProgress;

    if (self.compress) then
      local progress = self.region.progress or 1;
      local horScale = self.horizontal and progress or 1;
      local verScale = self.horizontal and 1 or progress;
      self:SetWidth(self.region:GetWidth() * horScale);
      self:SetHeight(self.region:GetHeight() * verScale);

      if (progress > 0.1) then
        startProgress = startProgress / progress;
        endProgress = endProgress / progress;
      else
        startProgress, endProgress = 0, 0;
      end
    end

    self.coord:SetFull();
    self:SetValueFunction(startProgress, endProgress);

    local region = self.region;
    local crop_x = region.crop_x or 1;
    local crop_y = region.crop_y or 1;
    local texRotation = region.effectiveTexRotation or 0
    local mirror_h = region.mirror_h or false;
    if region.mirror then
      mirror_h = not mirror_h
    end
    local mirror_v = region.mirror_v or false;
    local user_x = region.user_x;
    local user_y = region.user_y;

    self.coord:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v, user_x, user_y);
    self.coord:Apply();
  end,

  Update = function(self)
    self:SetValue(self.startProgress, self.endProgress);
  end,
}


local function createTexture(region, layer, drawlayer)
  local texture = region:CreateTexture(nil, layer);
  texture:SetSnapToPixelGrid(false)
  texture:SetTexelSnappingBias(0)
  texture:SetDrawLayer(layer, drawlayer);

  for k, v in pairs(textureFunctions) do
    texture[k] = v;
  end

  texture.SetAuraRotation = texture.SetRotation

  texture.coord  = createTexCoord(texture);
  texture.region = region;
  texture.startProgress = 0;
  texture.endProgress = 1;

  texture:SetAllPoints(region);

  return texture;
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
    self.foregroundSpinner:SetProgress(self, startAngle, pAngle);
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
    self.foregroundSpinner:SetProgress(self, pAngle, endAngle);
  end
}

local function hideExtraTextures(extraTextures, from)
  for i = from, #extraTextures do
    extraTextures[i]:Hide();
  end
end

local function ensureExtraTextures(region, count)
  for i = #region.extraTextures + 1, count do
    local extraTexture = createTexture(region, "ARTWORK", min(i, 7));
    Private.SetTextureOrAtlas(extraTexture, region.currentTexture, region.textureWrapMode, region.textureWrapMode)
    extraTexture:SetBlendMode(region.foreground:GetBlendMode());
    extraTexture:SetOrientation(region.orientation, region.compress, region.slanted, region.slant, region.slantFirst, region.slantMode);
    extraTexture:SetAuraRotation(region.auraRotation / 180 * math.pi)
    region.extraTextures[i] = extraTexture;
  end
end

local function ensureExtraSpinners(region, count)
  for i = #region.extraSpinners + 1, count do
    local extraSpinner = createSpinner(region, "OVERLAY", min(i, 7));
    extraSpinner:SetTextureOrAtlas(region.currentTexture);
    extraSpinner:SetBlendMode(region.foreground:GetBlendMode());
    extraSpinner:SetAuraRotation(region.auraRotation / 180 * math.pi)
    region.extraSpinners[i] = extraSpinner;
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

local function ReapplyAdditionalProgress(self)
  self:ApplyAdditionalProgress(self.additionalProgress, self.additionalProgressMin,
                               self.additionalProgressMax, self.additionalProgressInverse)
end

local function ApplyAdditionalProgress(self, additionalProgress, min, max, inverse)
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
          extraTexture:SetVertexColor(unpack(color));
        else
          extraTexture:SetVertexColor(1, 1, 1, 1);
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

      local startProgress, endProgress = convertToProgress(self.progress, additionalProgress, min, totalWidth, effectiveInverse, self.overlayclip);
      if (endProgress < startProgress) then
        startProgress, endProgress = endProgress, startProgress;
      end

      if (self.orientation == "ANTICLOCKWISE") then
        startProgress, endProgress = 1 - endProgress, 1 - startProgress;
      end

      if ((endProgress - startProgress) == 0) then
        extraSpinner:SetProgress(self, 0, 0);
      else
        local color = self.overlays[index];
        if (color) then
          extraSpinner:Color(unpack(color));
        else
          extraSpinner:Color(1, 1, 1, 1);
        end

        local startAngle = self.startAngle;
        local diffAngle = self.endAngle - startAngle;
        local pAngleStart = diffAngle * startProgress + startAngle;
        local pAngleEnd = diffAngle * endProgress + startAngle;

        if (pAngleStart < 0) then
          pAngleStart = pAngleStart + 360;
          pAngleEnd = pAngleEnd + 360;
        end

        extraSpinner:SetProgress(self, pAngleStart, pAngleEnd);
      end
    end

  else
    hideExtraTextures(self.extraSpinners, 1);
  end
end

local function showCircularProgress(region)
  region.foreground:Hide();
  region.background:Hide();
  region.foregroundSpinner:Show();
  region.backgroundSpinner:Show();

  for i = 1, #region.extraTextures do
    region.extraTextures[i]:Hide();
  end
end

local function hideCircularProgress(region)
  region.foreground:Show();
  region.background:Show();
  region.foregroundSpinner:Hide();
  region.backgroundSpinner:Hide();

  for i = 1, #region.extraSpinners do
    region.extraSpinners[i]:Hide();
  end
end

local function SetOrientation(region, orientation)
  region.orientation = orientation;
  if(region.orientation == "CLOCKWISE" or region.orientation == "ANTICLOCKWISE") then
    showCircularProgress(region);
    region.foregroundSpinner:UpdateSize();
    region.backgroundSpinner:UpdateSize();
    region.SetValueOnTexture = CircularSetValueFunctions[region.orientation];
    region.ApplyAdditionalProgress = ApplyAdditionalProgressCircular;
  else
    hideCircularProgress(region);
    region.background:SetOrientation(orientation, nil, region.slanted, region.slant, region.slantFirst, region.slantMode);
    region.foreground:SetOrientation(orientation, region.compress, region.slanted, region.slant, region.slantFirst, region.slantMode);
    region.SetValueOnTexture = TextureSetValueFunction;
    region.ApplyAdditionalProgress = ApplyAdditionalProgress;

    for _, extraTexture in ipairs(region.extraTextures) do
      extraTexture:SetOrientation(orientation, region.compress, region.slanted, region.slant, region.slantFirst, region.slantMode);
    end
  end
  region:SetValueOnTexture(region.progress);
  region:ReapplyAdditionalProgress()
end

local function create(parent)
  local region = CreateFrame("Frame", nil, parent);
  region.regionType = "progresstexture"
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetResizeBounds(1, 1)

  local background = createTexture(region, "BACKGROUND", 0);
  region.background = background;

  -- For horizontal/vertical progress
  local foreground = createTexture(region, "ARTWORK", 0);
  region.foreground = foreground;

  region.foregroundSpinner = createSpinner(region, "ARTWORK", 1);
  region.backgroundSpinner = createSpinner(region, "BACKGROUND", 1);

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

  region.SetOrientation = SetOrientation;

  Private.regionPrototype.create(region);

  return region;
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

local function modify(parent, region, data)
  Private.regionPrototype.modify(parent, region, data);

  local background, foreground = region.background, region.foreground;
  local foregroundSpinner, backgroundSpinner = region.foregroundSpinner, region.backgroundSpinner;

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

  background:SetBackgroundOffset(data.backgroundOffset);
  Private.SetTextureOrAtlas(background, data.sameTexture and data.foregroundTexture or data.backgroundTexture, region.textureWrapMode, region.textureWrapMode);
  background:SetDesaturated(data.desaturateBackground)
  background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  background:SetBlendMode(data.blendMode);

  backgroundSpinner:SetTextureOrAtlas(data.sameTexture and data.foregroundTexture or data.backgroundTexture);
  backgroundSpinner:SetDesaturated(data.desaturateBackground)
  backgroundSpinner:Color(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  backgroundSpinner:SetBlendMode(data.blendMode);

  region.currentTexture = data.foregroundTexture;
  Private.SetTextureOrAtlas(foreground, data.foregroundTexture, region.textureWrapMode, region.textureWrapMode);
  foreground:SetDesaturated(data.desaturateForeground)
  foreground:SetBlendMode(data.blendMode);

  foregroundSpinner:SetTextureOrAtlas(data.foregroundTexture);
  foregroundSpinner:SetDesaturated(data.desaturateForeground);
  foregroundSpinner:SetBlendMode(data.blendMode);

  for _, extraTexture in ipairs(region.extraTextures) do
    Private.SetTextureOrAtlas(extraTexture, data.foregroundTexture, region.textureWrapMode, region.textureWrapMode)
    extraTexture:SetBlendMode(data.blendMode);
  end

  for _, extraSpinner in ipairs(region.extraSpinners) do
    extraSpinner:SetTextureOrAtlas(data.foregroundTexture);
    extraSpinner:SetBlendMode(data.blendMode);
  end

  region.mirror = data.mirror
  region.crop_x = 1 + (data.crop_x or 0.41);
  region.crop_y = 1 + (data.crop_y or 0.41);
  region.texRotation = data.rotation or 0
  region.auraRotation = data.auraRotation or 0
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
  backgroundSpinner:SetProgress(region, region.startAngle, region.endAngle);
  backgroundSpinner:SetBackgroundOffset(region, data.backgroundOffset);

  if (data.overlays) then
    region.overlays = CopyTable(data.overlays)
  else
    region.overlays = {}
  end

  region.ReapplyAdditionalProgress = ReapplyAdditionalProgress

  region.slanted = data.slanted;
  region.slant = data.slant;
  region.slantFirst = data.slantFirst;
  region.slantMode = data.slantMode;
  region:SetOrientation(data.orientation);

  local function DoPosition(region)
    local mirror = region.mirror_h
    if region.mirror then
      mirror = not mirror
    end

    if(mirror) then
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

    if(region.mirror_v) then
      if(data.orientation == "VERTICAL_INVERSE") then
        foreground:SetPoint("TOP", region, "TOP");
      elseif(data.orientation == "VERTICAL") then
        foreground:SetPoint("BOTTOM", region, "BOTTOM");
      end
    else
      if(data.orientation == "VERTICAL") then
        foreground:SetPoint("BOTTOM", region, "BOTTOM");
      elseif(data.orientation == "VERTICAL_INVERSE") then
        foreground:SetPoint("TOP", region, "TOP");
      end
    end

    region:SetWidth(region.width * region.scalex);
    region:SetHeight(region.height * region.scaley);

    if (data.orientation == "CLOCKWISE" or data.orientation == "ANTICLOCKWISE") then
      region.foregroundSpinner:UpdateSize();
      region.backgroundSpinner:UpdateSize();
      for i = 1, #region.extraSpinners do
        region.extraSpinners[i]:UpdateSize();
      end
    else
      region.background:Update();
      region.foreground:Update();
      for _, extraTexture in ipairs(region.extraTextures) do
        extraTexture:Update();
      end
    end
  end

  DoPosition(region)

  function region:SetAuraRotation(auraRotation)
    region.auraRotation = auraRotation
    local auraRotationRadians = region.auraRotation / 180 * math.pi
    region.foregroundSpinner:SetAuraRotation(auraRotationRadians)
    region.backgroundSpinner:SetAuraRotation(auraRotationRadians)
    for i = 1, #region.extraSpinners do
      region.extraSpinners[i]:SetAuraRotation(auraRotationRadians)
    end

    region.background:SetAuraRotation(auraRotationRadians)
    region.foreground:SetAuraRotation(auraRotationRadians)
    for _, extraTexture in ipairs(region.extraTextures) do
      extraTexture:SetAuraRotation(auraRotationRadians)
    end
  end

  region:SetAuraRotation(data.auraRotation)

  function region:Scale(scalex, scaley)
    if(scalex < 0) then
      region.mirror_h = true;
      scalex = scalex * -1;
    end

    if(scaley < 0) then
      region.mirror_v = true;
      scaley = scaley * -1;
    end

    region.scalex = scalex;
    region.scaley = scaley;

    DoPosition(region)
  end

  function region:SetMirror(mirror)
    region.mirror = mirror
    DoPosition(region)
  end

  function region:UpdateEffectiveRotation()
    region.effectiveTexRotation = region.texAnimationRotation or region.texRotation
    if (data.orientation == "CLOCKWISE" or data.orientation == "ANTICLOCKWISE") then
      region.foregroundSpinner:UpdateSize();
      region.backgroundSpinner:UpdateSize();
      for i = 1, #region.extraSpinners do
        region.extraSpinners[i]:UpdateSize();
      end
    else
      region.background:Update();
      region.foreground:Update();
      for _, extraTexture in ipairs(region.extraTextures) do
        extraTexture:Update();
      end
    end
  end

  function region:SetAnimRotation(angle)
    region.texAnimationRotation = angle
    region:UpdateEffectiveRotation()
  end

  function region:SetTexRotation(angle)
    region.texRotation = angle
    region:UpdateEffectiveRotation()
  end

  region:SetTexRotation(data.rotation)

  function region:GetBaseRotation()
    return region.texRotation
  end

  function region:Color(r, g, b, a)
    region.color_r = r;
    region.color_g = g;
    region.color_b = b;
    if (r or g or b) then
      a = a or 1;
    end
    region.color_a = a;
    foreground:SetVertexColor(region.color_anim_r or r, region.color_anim_g or g, region.color_anim_b or b, region.color_anim_a or a);
    foregroundSpinner:Color(region.color_anim_r or r, region.color_anim_g or g, region.color_anim_b or b, region.color_anim_a or a);
  end

  function region:ColorAnim(r, g, b, a)
    region.color_anim_r = r;
    region.color_anim_g = g;
    region.color_anim_b = b;
    region.color_anim_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    foreground:SetVertexColor(r or region.color_r, g or region.color_g, b or region.color_b, a or region.color_a);
    foregroundSpinner:Color(r or region.color_r, g or region.color_g, b or region.color_b, a or region.color_a);
  end

  function region:GetColor()
    return region.color_r or data.foregroundColor[1], region.color_g or data.foregroundColor[2],
      region.color_b or data.foregroundColor[3], region.color_a or data.foregroundColor[4];
  end

  region:Color(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);


  function region:UpdateTime()
    local progress = 1;
    if (self.duration ~= 0) then
      local remaining = self.expirationTime - GetTime()
      progress = remaining / self.duration
      local inversed = not self.inverse ~= not region.inverseDirection
      if(inversed) then
        progress = 1 - progress;
      end
    end

    progress = progress > 0.0001 and progress or 0.0001;
    if (region.useSmoothProgress) then
      region.smoothProgress:SetSmoothedValue(progress);
    else
      region:SetValueOnTexture(progress);
      region:ReapplyAdditionalProgress()
    end

    if self.paused and self.FrameTick then
      self.FrameTick = nil
      self.subRegionEvents:RemoveSubscriber("FrameTick", region)
    end
    if not self.paused and not self.FrameTick then
      self.FrameTick = FrameTick
      self.subRegionEvents:AddSubscriber("FrameTick", region)
    end
  end

  function region:UpdateValue()
    local progress = 1
    if(self.total > 0) then
      progress = self.value / self.total;
      if(region.inverseDirection) then
        progress = 1 - progress;
      end
    end
    progress = progress > 0.0001 and progress or 0.0001;
    if (region.useSmoothProgress) then
      region.smoothProgress:SetSmoothedValue(progress);
    else
      region:SetValueOnTexture(progress);
      region:ReapplyAdditionalProgress()
    end

    if self.FrameTick then
      self.FrameTick = nil
      self.subRegionEvents:RemoveSubscriber("FrameTick", region)
    end
  end

  if region.useSmoothProgress then
    region.PreShow = function()
      region.smoothProgress:ResetSmoothedValue();
    end
  else
    region.PreShow = nil
  end

  function region:SetAdditionalProgress(additionalProgress, currentMin, currentMax, inverse)
    region:ApplyAdditionalProgress(additionalProgress, currentMin, currentMax, inverse)
  end

  region.FrameTick = nil
  function region:Update()
    region:UpdateProgress()
    local state = region.state

    if state.texture then
      region:SetTexture(state.texture)
    end
  end

  function region:SetTexture(texture)
    region.currentTexture = texture;
    Private.SetTextureOrAtlas(region.foreground, texture, region.textureWrapMode, region.textureWrapMode);
    foregroundSpinner:SetTextureOrAtlas(texture);
    if (data.sameTexture) then
      Private.SetTextureOrAtlas(background, texture, region.textureWrapMode, region.textureWrapMode);
      backgroundSpinner:SetTextureOrAtlas(texture);
    end

    for _, extraTexture in ipairs(region.extraTextures) do
      Private.SetTextureOrAtlas(extraTexture, texture, region.textureWrapMode, region.textureWrapMode)
    end

    for _, extraSpinner in ipairs(region.extraSpinners) do
      extraSpinner:SetTextureOrAtlas(texture);
    end
  end

  function region:SetForegroundDesaturated(b)
    region.foreground:SetDesaturated(b);
    region.foregroundSpinner:SetDesaturated(b);
  end

  function region:SetBackgroundDesaturated(b)
    region.background:SetDesaturated(b);
    region.backgroundSpinner:SetDesaturated(b);
  end

  function region:SetBackgroundColor(r, g, b, a)
    region.background:SetVertexColor(r, g, b, a);
    region.backgroundSpinner:Color(r, g, b, a);
  end

  function region:SetRegionWidth(width)
    region.width = width;
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetRegionHeight(height)
    region.height = height;
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetInverse(inverse)
    if (region.inverseDirection == inverse) then
      return;
    end
    region.inverseDirection = inverse;
    local progress = 1 - region.progress;
    progress = progress > 0.0001 and progress or 0.0001;
    region:SetValueOnTexture(progress);
    region:ReapplyAdditionalProgress()
  end

  function region:SetOverlayColor(id, r, g, b, a)
    self.overlays[id] = { r, g, b, a};
    if (self.extraTextures[id]) then
      self.extraTextures[id]:SetVertexColor(r, g, b, a);
    end
    if (self.extraSpinners[id]) then
      self.extraSpinners[id]:Color(r, g, b, a);
    end
  end

  Private.regionPrototype.modifyFinish(parent, region, data);
end

local function validate(data)
  Private.EnforceSubregionExists(data, "subbackground")
end

Private.RegisterRegionType("progresstexture", create, modify, default, GetProperties, validate);
