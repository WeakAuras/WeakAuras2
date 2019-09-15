if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local LCG = LibStub("LibCustomGlow-1.0")
local L = WeakAuras.L
local MSQ, MSQ_Version = LibStub("Masque", true);
if MSQ then
  if MSQ_Version <= 80100 then
    MSQ = nil
    print(print(WeakAuras.printPrefix .. L["Please upgrade your Masque version"]))
  else
    MSQ:AddType("WA_Aura", {"Icon", "Cooldown"})
  end
end

-- WoW API
local _G = _G

local default = {
  icon = true,
  desaturate = false,
  auto = true,
  inverse = false,
  width = 64,
  height = 64,
  color = {1, 1, 1, 1},
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  zoom = 0,
  keepAspectRatio = false,
  frameStrata = 1,
  glow = false,
  useglowColor = false,
  glowColor = {1, 1, 1, 1},
  glowType = "buttonOverlay",
  glowLines = 8,
  glowFrequency = 0.25,
  glowLength = 10,
  glowThickness = 1,
  glowScale = 1,
  glowBorder = false,
  glowXOffset = 0,
  glowYOffset = 0,
  cooldownTextDisabled = false,
  cooldownSwipe = true,
  cooldownEdge = false,
  subRegions = {}
};

WeakAuras.regionPrototype.AddAlphaToDefault(default);

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  desaturate = {
    display = L["Desaturate"],
    setter = "SetDesaturated",
    type = "bool",
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
  glow = {
    display = { L["Glow"], L["Show Glow"], true },
    setter = "SetGlow",
    type = "bool"
  },
  glowType = {
    display = { L["Glow"], L["Type"] },
    setter = "SetGlowType",
    type = "list",
    values = WeakAuras.glow_types,
  },
  useGlowColor = {
    display = { L["Glow"], L["Use Custom Color"] },
    setter = "SetUseGlowColor",
    type = "bool"
  },
  glowColor = {
    display = { L["Glow"], L["Color"]},
    setter = "SetGlowColor",
    type = "color"
  },
  glowLines = {
    display = { L["Glow"], WeakAuras.newFeatureString .. L["Lines & Particles"]},
    setter = "SetGlowLines",
    type = "number",
    min = 1,
    softMax = 30,
    bigStep = 1,
    default = 4
  },
  glowFrequency = {
    display = { L["Glow"], WeakAuras.newFeatureString .. L["Frequency"]},
    setter = "SetGlowFrequency",
    type = "number",
    softMin = -2,
    softMax = 2,
    bigStep = 0.1,
    default = 0.25
  },
  glowLength = {
    display = { L["Glow"], WeakAuras.newFeatureString .. L["Length"]},
    setter = "SetGlowLength",
    type = "number",
    min = 1,
    softMax = 20,
    bigStep = 1,
    default = 10
  },
  glowThickness = {
    display = { L["Glow"], WeakAuras.newFeatureString .. L["Thickness"]},
    setter = "SetGlowThickness",
    type = "number",
    min = 1,
    softMax = 20,
    bigStep = 1,
    default = 1
  },
  glowScale = {
    display = { L["Glow"], WeakAuras.newFeatureString .. L["Scale"]},
    setter = "SetGlowScale",
    type = "number",
    min = 0.05,
    softMax = 10,
    bigStep = 0.05,
    default = 1,
    isPercent = true
  },
  glowBorder = {
    display = { L["Glow"], WeakAuras.newFeatureString .. L["Border"]},
    setter = "SetGlowBorder",
    type = "bool"
  },
  glowXOffset = {
    display = { L["Glow"], WeakAuras.newFeatureString .. L["X-Offset"]},
    setter = "SetGlowXOffset",
    type = "number",
    softMin = -100,
    softMax = 100,
    bigStep = 1,
    default = 0
  },
  glowYOffset = {
    display = { L["Glow"], WeakAuras.newFeatureString .. L["Y-Offset"]},
    setter = "SetGlowYOffset",
    type = "number",
    softMin = -100,
    softMax = 100,
    bigStep = 1,
    default = 0
  },
  color = {
    display = L["Color"],
    setter = "Color",
    type = "color"
  },
  inverse = {
    display = L["Inverse"],
    setter = "SetInverse",
    type = "bool"
  },
  cooldownSwipe = {
    display = { L["Cooldown"], L["Swipe"], true},
    setter = "SetCooldownSwipe",
    type = "bool",
  },
  cooldownEdge = {
    display = { L["Cooldown"], L["Edge"]},
    setter = "SetCooldownEdge",
    type = "bool",
  },
  zoom = {
    display = L["Zoom"],
    setter = "SetZoom",
    type = "number",
    min = 0,
    max = 1,
    step = 0.01,
    default = 0,
    isPercent = true
  },
};

WeakAuras.regionPrototype.AddProperties(properties, default);

local function GetTexCoord(region, texWidth, aspectRatio)
  region.currentCoord = region.currentCoord or {}
  local usesMasque = false
  if region.MSQGroup then
    region.MSQGroup:ReSkin();

    local db = region.MSQGroup.db
    if db and not db.Disabled then
      usesMasque = true
      region.currentCoord[1], region.currentCoord[2], region.currentCoord[3], region.currentCoord[4], region.currentCoord[5], region.currentCoord[6], region.currentCoord[7], region.currentCoord[8] = region.icon:GetTexCoord()
    end
  end
  if (not usesMasque) then
    region.currentCoord[1], region.currentCoord[2], region.currentCoord[3], region.currentCoord[4], region.currentCoord[5], region.currentCoord[6], region.currentCoord[7], region.currentCoord[8] = 0, 0, 0, 1, 1, 0, 1, 1;
  end

  local xRatio = aspectRatio < 1 and aspectRatio or 1;
  local yRatio = aspectRatio > 1 and 1 / aspectRatio or 1;
  for i, coord in ipairs(region.currentCoord) do
    local aspectRatio = (i % 2 == 1) and xRatio or yRatio;
    region.currentCoord[i] = (coord - 0.5) * texWidth * aspectRatio + 0.5;
  end

  return unpack(region.currentCoord)
end

local function AnchorSubRegion(self, subRegion, anchorType, selfPoint, anchorPoint, anchorXOffset, anchorYOffset)
  if type == "area" then
    WeakAuras.regionPrototype.AnchorSubRegion(self, subRegion, anchorType, selfPoint, anchorPoint, anchorXOffset, anchorYOffset)
  else
    subRegion:ClearAllPoints()
    anchorPoint = anchorPoint or "CENTER"
    local anchorRegion = self.icon
    if anchorPoint:sub(1, 6) == "INNER_" then
      if not self.inner then
        self.inner = CreateFrame("FRAME", nil, self)
        self.inner:SetPoint("CENTER")
        self.UpdateInnerOuterSize()
      end
      anchorRegion = self.inner
      anchorPoint = anchorPoint:sub(7)
    elseif anchorPoint:sub(1, 6) == "OUTER_" then
      if not self.outer then
        self.outer = CreateFrame("FRAME", nil, self)
        self.outer:SetPoint("CENTER")
        self.UpdateInnerOuterSize()
      end
      anchorRegion = self.outer
      anchorPoint = anchorPoint:sub(7)
    end
    anchorXOffset = anchorXOffset or 0
    anchorYOffset = anchorYOffset or 0

    if not WeakAuras.point_types[selfPoint] then
      selfPoint = "CENTER"
    end

    if not WeakAuras.point_types[anchorPoint] then
      anchorPoint = "CENTER"
    end

    subRegion:SetPoint(selfPoint, anchorRegion, anchorPoint, anchorXOffset, anchorYOffset)
  end
end

local function create(parent, data)
  local font = "GameFontHighlight";

  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetMinResize(1, 1);

  function region.UpdateInnerOuterSize()
    local width = region.width * math.abs(region.scalex);
    local height = region.height * math.abs(region.scaley);

    local iconWidth
    local iconHeight

    if MSQ then
      iconWidth = region.button:GetWidth()
      iconHeight = region.button:GetHeight()
    else
      iconWidth = region:GetWidth()
      iconHeight = region:GetHeight()
    end

    if region.inner then
      region.inner:SetSize(iconWidth - 0.2 * width, iconHeight - 0.2 * height)
    end
    if region.outer then
      region.outer:SetSize(iconWidth + 0.1 * width, iconHeight + 0.1 * height)
    end
  end

  local button
  if MSQ then
    button = CreateFrame("Button", nil, region)
    button.data = data
    region.button = button;
    button:EnableMouse(false);
    button:Disable();
    button:SetAllPoints();
  end

  local icon = region:CreateTexture(nil, "BACKGROUND");
  icon:SetSnapToPixelGrid(false)
  icon:SetTexelSnappingBias(0)
  if MSQ then
    icon:SetAllPoints(button);
    button:SetScript("OnSizeChanged", region.UpdateInnerOuterSize);
  else
    icon:SetAllPoints(region);
    region:SetScript("OnSizeChanged", region.UpdateInnerOuterSize);
  end
  region.icon = icon;
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");

  --This section creates a unique frame id for the cooldown frame so that it can be created with a global reference
  --The reason is so that WeakAuras cooldown frames can interact properly with OmniCC (i.e., put on its blacklist for timer overlays)
  local id = data.id;
  local frameId = id:lower():gsub(" ", "_");
  if(_G["WeakAurasCooldown"..frameId]) then
    local baseFrameId = frameId;
    local num = 2;
    while(_G["WeakAurasCooldown"..frameId]) do
      frameId = baseFrameId..num;
      num = num + 1;
    end
  end
  region.frameId = frameId;

  local cooldown = CreateFrame("COOLDOWN", "WeakAurasCooldown"..frameId, region, "CooldownFrameTemplate");
  region.cooldown = cooldown;
  cooldown:SetAllPoints(icon);

  region.values = {};


  local SetFrameLevel = region.SetFrameLevel;

  function region.SetFrameLevel(self, level)
    SetFrameLevel(region, level);
    cooldown:SetFrameLevel(level);
    if (self.__WAGlowFrame) then
      self.__WAGlowFrame:SetFrameLevel(level + 1);
    end
    if button then
      button:SetFrameLevel(level);
    end
  end

  WeakAuras.regionPrototype.create(region);

  region.AnchorSubRegion = AnchorSubRegion

  return region;
end

local function modify(parent, region, data)
  -- Legacy members stacks and text2
  region.stacks = nil
  region.text2 = nil

  WeakAuras.regionPrototype.modify(parent, region, data);

  local button, icon, cooldown = region.button, region.icon, region.cooldown;

  region.useAuto = data.auto and WeakAuras.CanHaveAuto(data);

  if MSQ then
    local masqueId = data.id:lower():gsub(" ", "_");
    if region.masqueId ~= masqueId then
      region.masqueId = masqueId
      region.MSQGroup = MSQ:Group("WeakAuras", region.masqueId, data.uid);
      region.MSQGroup:SetName(data.id)
      region.MSQGroup:AddButton(button, {Icon = icon, Cooldown = cooldown}, "WA_Aura", true);
      button.data = data
    end
  end

  function region:UpdateSize()
    local width = region.width * math.abs(region.scalex);
    local height = region.height * math.abs(region.scaley);
    region:SetWidth(width);
    region:SetHeight(height);
    if MSQ then
      button:SetWidth(width);
      button:SetHeight(height);
      button:SetAllPoints();
    end
    region:UpdateTexCoords();
    if region.glow then
      region:SetGlow(true);
    end
  end

  function region:UpdateTexCoords()
    local mirror_h = region.scalex < 0;
    local mirror_v = region.scaley < 0;

    local texWidth = 1 - 0.5 * region.zoom;
    local aspectRatio
    if not region.keepAspectRatio then
      aspectRatio = 1;
    else
      local width = region.width * math.abs(region.scalex);
      local height = region.height * math.abs(region.scaley);

      if width == 0 or height == 0 then
        aspectRatio = 1;
      else
        aspectRatio = width / height;
      end
    end

    local ulx, uly, llx, lly, urx, ury, lrx, lry = GetTexCoord(region, texWidth, aspectRatio)

    if(mirror_h) then
      if(mirror_v) then
        icon:SetTexCoord(lrx, lry, urx, ury, llx, lly, ulx, uly)
      else
        icon:SetTexCoord(urx, ury, lrx, lry, ulx, uly, llx, lly)
      end
    else
      if(mirror_v) then
        icon:SetTexCoord(llx, lly, ulx, uly, lrx, lry, urx, ury)
      else
        icon:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
      end
    end
  end

  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;
  region.keepAspectRatio = data.keepAspectRatio;
  region.zoom = data.zoom;
  region:UpdateSize()

  icon:SetDesaturated(data.desaturate);

  local tooltipType = WeakAuras.CanHaveTooltip(data);
  if(tooltipType and data.useTooltip) then
    if not region.tooltipFrame then
      region.tooltipFrame = CreateFrame("frame", nil, region);
      region.tooltipFrame:SetAllPoints(region);
      region.tooltipFrame:SetScript("OnEnter", function()
        WeakAuras.ShowMouseoverTooltip(region, region);
      end);
      region.tooltipFrame:SetScript("OnLeave", WeakAuras.HideTooltip);
    end
    region.tooltipFrame:EnableMouse(true);
  elseif region.tooltipFrame then
    region.tooltipFrame:EnableMouse(false);
  end

  cooldown:SetReverse(not data.inverse);
  cooldown:SetHideCountdownNumbers(data.cooldownTextDisabled);
  cooldown.noCooldownCount = data.cooldownTextDisabled;

  function region:Color(r, g, b, a)
    region.color_r = r;
    region.color_g = g;
    region.color_b = b;
    region.color_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    icon:SetVertexColor(region.color_anim_r or r, region.color_anim_g or g, region.color_anim_b or b, region.color_anim_a or a);
    if region.button then
      region.button:SetAlpha(region.color_anim_a or a or 1);
    end
  end

  function region:ColorAnim(r, g, b, a)
    region.color_anim_r = r;
    region.color_anim_g = g;
    region.color_anim_b = b;
    region.color_anim_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    icon:SetVertexColor(r or region.color_r, g or region.color_g, b or region.color_b, a or region.color_a);
    if MSQ then
      region.button:SetAlpha(a or region.color_a or 1);
    end
  end

  function region:GetColor()
    return region.color_r or data.color[1], region.color_g or data.color[2],
      region.color_b or data.color[3], region.color_a or data.color[4];
  end

  region:Color(data.color[1], data.color[2], data.color[3], data.color[4]);

  function region:SetIcon(path)
    local iconPath = (
      region.useAuto
      and path ~= ""
      and path
      or data.displayIcon
      or "Interface\\Icons\\INV_Misc_QuestionMark"
      );
    icon:SetTexture(iconPath);
  end

  function region:Scale(scalex, scaley)
    if region.scalex == scalex and region.scaley == scaley then
      return
    end
    region.scalex = scalex;
    region.scaley = scaley;
    region:UpdateSize();
  end

  function region:SetDesaturated(b)
    icon:SetDesaturated(b);
  end

  function region:SetRegionWidth(width)
    region.width = width
    region:UpdateSize();
  end

  function region:SetRegionHeight(height)
    region.height = height
    region:UpdateSize();
  end

  function region:SetInverse(inverse)
    cooldown:SetReverse(not inverse);
    if (cooldown.expirationTime and cooldown.duration and cooldown:IsShown()) then
      -- WORKAROUND SetReverse not applying until next frame
      cooldown:SetCooldown(0, 0);
      cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration, cooldown.duration);
    end
  end

  function region:SetCooldownSwipe(cooldownSwipe)
    region.cooldownSwipe = cooldownSwipe;
    cooldown:SetDrawSwipe(cooldownSwipe);
  end

  function region:SetCooldownEdge(cooldownEdge)
    region.cooldownEdge = cooldownEdge;
    cooldown:SetDrawEdge(cooldownEdge);
  end

  region:SetCooldownSwipe(data.cooldownSwipe)
  region:SetCooldownEdge(data.cooldownEdge)

  function region:SetZoom(zoom)
    region.zoom = zoom;
    region:UpdateTexCoords();
  end

  function region:SetGlowType(newType)
    local isGlowing = region.glow
    if isGlowing then
      region:SetGlow(false)
    end
    if newType == "buttonOverlay" then
      region.glowStart = LCG.ButtonGlow_Start
      region.glowStop = LCG.ButtonGlow_Stop
    elseif newType == "ACShine" then
      region.glowStart = LCG.AutoCastGlow_Start
      region.glowStop = LCG.AutoCastGlow_Stop
    elseif newType == "Pixel" then
      region.glowStart = LCG.PixelGlow_Start
      region.glowStop = LCG.PixelGlow_Stop
    end
    region.glowType = newType
    if isGlowing then
      region:SetGlow(true)
    end
  end

  function region:SetUseGlowColor(useGlowColor)
    region.useGlowColor = useGlowColor
    if region.glow then
      region:SetGlow(true)
    end
  end

  function region:SetGlowColor(r, g, b, a)
    region.glowColor = {r, g, b, a}
    if region.glow then
      region:SetGlow(true)
    end
  end

  function region:SetGlowLines(lines)
    region.glowLines = lines
    if region.glow then
      if region.glowType == "ACShine" then -- workaround ACShine not updating numbers of dots
        region:SetGlow(false)
      end
      region:SetGlow(true)
    end
  end
  function region:SetGlowFrequency(frequency)
    region.glowFrequency = frequency
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowLength(length)
    region.glowLength = length
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowThickness(thickness)
    region.glowThickness = thickness
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowScale(scale)
    region.glowScale = scale
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowBorder(border)
    region.glowBorder = border
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowXOffset(xoffset)
    region.glowXOffset = xoffset
    if region.glow then
      region:SetGlow(true)
    end
  end
  function region:SetGlowYOffset(yoffset)
    region.glowYOffset = yoffset
    if region.glow then
      region:SetGlow(true)
    end
  end

  function region:SetGlow(showGlow)
    local color
    local function glowStart(frame)
      if region.glowType == "buttonOverlay" then
        region.glowStart(frame, color, region.glowFrequency)
      elseif region.glowType == "Pixel" then
        region.glowStart(
          frame,
          color,
          region.glowLines,
          region.glowFrequency,
          region.glowLength,
          region.glowThickness,
          region.glowXOffset,
          region.glowYOffset,
          region.glowBorder
        )
      elseif region.glowType == "ACShine" then
        region.glowStart(
          frame,
          color,
          region.glowLines,
          region.glowFrequency,
          region.glowScale,
          region.glowXOffset,
          region.glowYOffset
        )
      end
    end
    region.glow = showGlow
    if region.useGlowColor then
      color = region.glowColor
    end
    if MSQ then
      if (showGlow) then
        glowStart(region.button);
      else
        region.glowStop(region.button);
      end
    elseif (showGlow) then
      if (not region.__WAGlowFrame) then
        region.__WAGlowFrame = CreateFrame("Frame", nil, region);
        region.__WAGlowFrame:SetAllPoints();
      end
      region.__WAGlowFrame:SetSize(region.width * math.abs(region.scalex), region.height * math.abs(region.scaley));
      glowStart(region.__WAGlowFrame);
    else
      if (region.__WAGlowFrame) then
        region.glowStop(region.__WAGlowFrame);
      end
    end
  end

  function region:PreShowGlow()
    if region.glow then
      region:SetGlow(false)
      region:SetGlow(true)
    end
  end

  region.useGlowColor = data.useGlowColor
  region.glowColor = data.glowColor
  region.glowLines = data.glowLines
  region.glowFrequency = data.glowFrequency
  region.glowLength = data.glowLength
  region.glowThickness = data.glowThickness
  region.glowScale = data.glowScale
  region.glowBorder = data.glowBorder
  region.glowXOffset = data.glowXOffset
  region.glowYOffset = data.glowYOffset
  region:SetGlowType(data.glowType)
  region:SetGlow(data.glow)

  if(data.cooldown) then
    function region:SetValue(value, total)
      cooldown.duration = 0
      cooldown.expirationTime = math.huge
      cooldown:Hide();
    end

    function region:SetTime(duration, expirationTime)
      if (duration > 0) then
        cooldown:Show();
        cooldown.expirationTime = expirationTime;
        cooldown.duration = duration;
        cooldown:SetCooldown(expirationTime - duration, duration);
      else
        cooldown.expirationTime = expirationTime;
        cooldown.duration = duration;
        cooldown:Hide();
      end
    end

    function region:PreShow()
      region:PreShowGlow()
      if (cooldown.duration and cooldown.duration > 0.01) then
        cooldown:Show();
        cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration, cooldown.duration);
      end
    end

    function region:Update()
      local state = region.state
      if state.progressType == "timed" then
        local expirationTime = state.expirationTime and state.expirationTime > 0 and state.expirationTime or math.huge;
        local duration = state.duration or 0
        local adjustMin = region.adjustedMin or 0;
        region:SetTime((duration ~= 0 and region.adjustedMax or duration) - adjustMin, expirationTime - adjustMin, state.inverse);
      elseif state.progressType == "static" then
        local value = state.value or 0;
        local total = state.total or 0;
        local adjustMin = region.adjustedMin or 0;
        local max = region.adjustedMax or total;
        region:SetValue(value - adjustMin, max - adjustMin);
      else
        region:SetTime(0, math.huge)
      end

      region:SetIcon(state.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
  else
    cooldown:Hide();
    region.SetValue = nil
    region.SetTime = nil

    region.PreShow = region.PreShowGlow

    function region:Update()
      local state = region.state
      region:SetIcon(state.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
  end

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);
end

WeakAuras.RegisterRegionType("icon", create, modify, default, properties);
