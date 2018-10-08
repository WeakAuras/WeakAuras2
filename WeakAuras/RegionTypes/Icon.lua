local SharedMedia = LibStub("LibSharedMedia-3.0");
local MSQ = LibStub("Masque", true);
local LCG = LibStub("LibCustomGlow-1.0")
local L = WeakAuras.L

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
  text1Enabled = true,
  text1Color = {1, 1, 1, 1},
  text1 = "%s",
  text1Point = "BOTTOMRIGHT",
  text1Containment = "INSIDE",
  text2Enabled = false,
  text2Color = {1, 1, 1, 1},
  text2 = "%p",
  text2Point = "CENTER",
  text2Containment = "INSIDE",
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  text1Font = "Friz Quadrata TT",
  text1FontFlags = "OUTLINE",
  text1FontSize = 12,
  text2Font = "Friz Quadrata TT",
  text2FontFlags = "OUTLINE",
  text2FontSize = 24,
  stickyDuration = false,
  zoom = 0,
  keepAspectRatio = false,
  frameStrata = 1,
  customTextUpdate = "update",
  glow = false,
  useglowColor = false,
  glowType = "buttonOverlay",
  cooldownTextEnabled = true,
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
    display = L["Glow"],
    setter = "SetGlow",
    type = "bool"
  },
  glowType = {
    display = WeakAuras.newFeatureString .. L["Glow Type"],
    setter = "SetGlowType",
    type = "list",
    values = WeakAuras.glow_types,
  },
  glowColor = {
    display = WeakAuras.newFeatureString .. L["Glow Color"],
    setter = "SetGlowColor",
    type = "color"
  },
  text1Color = {
    display = L["1. Text Color"],
    setter = "SetText1Color",
    type = "color"
  },
  text1FontSize = {
    display = L["1. Text Size"],
    setter = "SetText1Height",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1,
    default = 12
  },
  text2Color = {
    display = L["2. Text Color"],
    setter = "SetText2Color",
    type = "color"
  },
  text2FontSize = {
    display = L["2. Text Size"],
    setter = "SetText2Height",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1,
    default = 12
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

local function GetProperties(data)
  return properties;
end


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

local function create(parent, data)
  local font = "GameFontHighlight";

  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetMinResize(1, 1);

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
  if MSQ then
    icon:SetAllPoints(button);
  else
    icon:SetAllPoints(region);
  end
  region.icon = icon;
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");

  --This section creates a unique frame id for the cooldown frame so that it can be created with a global reference
  --The reason is so that WeakAuras cooldown frames can interact properly with OmniCC (i.e., put on its blacklist for timer overlays)
  local id = data.id;
  local frameId = id:lower():gsub(" ", "_");
  if(_G[frameId]) then
    local baseFrameId = frameId;
    local num = 2;
    while(_G[frameId]) do
      frameId = baseFrameId..num;
      num = num + 1;
    end
  end
  region.frameId = frameId;

  local cooldown = CreateFrame("COOLDOWN", "WeakAurasCooldown"..frameId, region, "CooldownFrameTemplate");
  region.cooldown = cooldown;
  cooldown:SetAllPoints(icon);
  cooldown:SetDrawEdge(false);

  local stacksFrame = CreateFrame("frame", nil, region);
  local stacks = stacksFrame:CreateFontString(nil, "OVERLAY");
  local cooldownFrameLevel = cooldown:GetFrameLevel() + 1
  stacksFrame:SetFrameLevel(cooldownFrameLevel)
  region.stacks = stacks;

  local text2Frame = CreateFrame("frame", nil, region);
  local text2 = text2Frame:CreateFontString(nil, "OVERLAY");
  text2Frame:SetFrameLevel(cooldownFrameLevel)
  region.text2 = text2;

  region.values = {};
  region.duration = 0;
  region.expirationTime = math.huge;

  local SetFrameLevel = region.SetFrameLevel;

  function region.SetFrameLevel(self, level)
    SetFrameLevel(region, level);
    cooldown:SetFrameLevel(level);
    stacksFrame:SetFrameLevel(level + 1);
    text2Frame:SetFrameLevel(level + 1);
    if (self.__WAGlowFrame) then
      self.__WAGlowFrame:SetFrameLevel(level + 1);
    end
    if button then
      button:SetFrameLevel(level);
    end
  end

  WeakAuras.regionPrototype.create(region);

  return region;
end

local function configureText(fontString, icon, enabled, point, width, height, containment, font, fontSize, fontFlags, textColor)
  if (enabled) then
    fontString:Show();
  else
    fontString:Hide();
    return;
  end

  local sxo, syo, h, v = 0, 0, "CENTER", "MIDDLE";
  if(point:find("LEFT")) then
    sxo = width / 10;
    h = containment == "INSIDE" and "LEFT" or "RIGHT";
  elseif(point:find("RIGHT")) then
    sxo = width / -10;
    h = containment == "INSIDE" and "RIGHT" or "LEFT";
  end
  if(point:find("BOTTOM")) then
    syo = height / 10;
    v = containment == "INSIDE" and "BOTTOM" or "TOP";
  elseif(point:find("TOP")) then
    syo = height / -10;
    v = containment == "INSIDE" and "TOP" or "BOTTOM";
  end
  fontString:ClearAllPoints();
  if(containment == "INSIDE") then
    fontString:SetPoint(point, icon, point, sxo, syo);
  else
    local selfPoint = WeakAuras.inverse_point_types[point];
    fontString:SetPoint(selfPoint, icon, point, -0.5 * sxo, -0.5 * syo);
  end
  -- WORKAROUND even more Blizzard stupidity. SetJustifyH doesn't seem to work with the hack from SetTextOnText
  -- So reset here to automatic width
  local fontPath = SharedMedia:Fetch("font", font);
  fontString:SetFont(fontPath, fontSize, fontFlags == "MONOCHROME" and "OUTLINE, MONOCHROME" or fontFlags);
  local t = fontString:GetText();
  fontString:SetText("WORKAROUND Blizzard Bugs");
  fontString:SetText(t);

  fontString:SetTextHeight(fontSize);
  fontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4]);

  fontString:SetJustifyH(h);
  fontString:SetJustifyV(v);

  fontString:SetWidth(0);
  local tw = fontString:GetWidth();
  local w = fontString:GetStringWidth();
  w = w + max(15, w / 20);
  fontString:SetWidth(w); -- But that internal text size calculation is wrong, see ticket 1014
end

local function modify(parent, region, data)
  WeakAuras.regionPrototype.modify(parent, region, data);
  local button, icon, cooldown, stacks, text2 = region.button, region.icon, region.cooldown, region.stacks, region.text2;

  region.useAuto = data.auto and WeakAuras.CanHaveAuto(data);

  region.stickyDuration = data.stickyDuration;
  region.progressPrecision = data.progressPrecision;
  region.totalPrecision = data.totalPrecision;

  if MSQ and not region.MSQGroup then
    region.MSQGroup = MSQ:Group("WeakAuras", region.frameId);
    region.MSQGroup:AddButton(button, {Icon = icon, Cooldown = cooldown});

    button.data = data
  end

  region:SetWidth(data.width);
  region:SetHeight(data.height);
  if MSQ then
    button:SetWidth(data.width);
    button:SetHeight(data.height);
    button:SetAllPoints();
  end
  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;
  region.keepAspectRatio = data.keepAspectRatio;
  region.zoom = data.zoom;
  icon:SetAllPoints();

  configureText(stacks, icon, data.text1Enabled, data.text1Point, data.width, data.height, data.text1Containment, data.text1Font, data.text1FontSize, data.text1FontFlags, data.text1Color);
  configureText(text2, icon, data.text2Enabled, data.text2Point, data.width, data.height, data.text2Containment, data.text2Font, data.text2FontSize, data.text2FontFlags, data.text2Color);

  local texWidth = 1 - region.zoom * 0.5;
  local aspectRatio = region.keepAspectRatio and region.width / region.height or 1;

  icon:SetTexCoord(GetTexCoord(region, texWidth, aspectRatio))
  icon:SetDesaturated(data.desaturate);

  local tooltipType = WeakAuras.CanHaveTooltip(data);
  if(tooltipType and data.useTooltip) then
    region:EnableMouse(true);
    region:SetScript("OnEnter", function()
      WeakAuras.ShowMouseoverTooltip(region, region);
    end);
    region:SetScript("OnLeave", WeakAuras.HideTooltip);
  else
    region:EnableMouse(false);
  end

  cooldown:SetReverse(not data.inverse);
  cooldown:SetHideCountdownNumbers(not data.cooldownTextEnabled or IsAddOnLoaded("OmniCC") or false);

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

  local UpdateText;
  if (data.text1Enabled and data.text1:find('%%')) or (data.text2Enabled and data.text2:find('%%')) then
    UpdateText = function()
      if (data.text1Enabled) then
        local textStr = data.text1 or "";
        textStr = WeakAuras.ReplacePlaceHolders(textStr, region);

        if(stacks.text ~= textStr) then
          if stacks:GetFont() then
            WeakAuras.regionPrototype.SetTextOnText(stacks, textStr);
            stacks.text = textStr;
          end
        end
      end

      if (data.text2Enabled) then
        local textStr = data.text2 or "";
        textStr = WeakAuras.ReplacePlaceHolders(textStr, region);

        if(text2.text ~= textStr) then
          if text2:GetFont() then
            WeakAuras.regionPrototype.SetTextOnText(text2, textStr);
            text2.text = textStr;
          end
        end
      end
    end
  else
    if (data.text1Enabled) then
      WeakAuras.regionPrototype.SetTextOnText(stacks, data.text1);
      stacks.text = data.text1;
    end

    if (data.text2Enabled) then
      WeakAuras.regionPrototype.SetTextOnText(text2, data.text2);
      text2.text = data.text2;
    end

    UpdateText = function() end
  end

  local customTextFunc = nil
  local data1Custom = data.text1Enabled and data.text1:find("%%c");
  local data2Custom = data.text2Enabled and data.text2:find("%%c")
  if (data.customText and (data1Custom or data2Custom)) then
    customTextFunc = WeakAuras.LoadFunction("return "..data.customText, region.id)
  end
  if (customTextFunc) then
    local values = region.values;
    region.UpdateCustomText = function()
      WeakAuras.ActivateAuraEnvironment(region.id, region.cloneId, region.state);
      values.custom = {select(2, xpcall(customTextFunc, geterrorhandler(), region.expirationTime, region.duration,
        values.progress, values.duration, values.name, values.icon, values.stacks))}
      WeakAuras.ActivateAuraEnvironment(nil);
      UpdateText();
    end
    if(data.customTextUpdate == "update") then
      WeakAuras.RegisterCustomTextUpdates(region);
    else
      WeakAuras.UnregisterCustomTextUpdates(region);
    end
  else
    region.values.custom = nil;
    region.UpdateCustomText = nil;
    WeakAuras.UnregisterCustomTextUpdates(region);
  end

  function region:SetStacks(count)
    if(count and count > 0) then
      region.values.stacks = count;
    else
      region.values.stacks = " ";
    end
    UpdateText();
  end

  function region:SetIcon(path)
    local iconPath = (
      region.useAuto
      and path ~= ""
      and path
      or data.displayIcon
      or "Interface\\Icons\\INV_Misc_QuestionMark"
      );
    icon:SetTexture(iconPath);
    region.values.icon = "|T"..iconPath..":12:12:0:0:64:64:4:60:4:60|t";
    UpdateText();
  end

  function region:SetName(name)
    region.values.name = name or data.id;
    UpdateText();
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
    icon:SetAllPoints();

    region:UpdateTexCoords();
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

  function region:SetText1Color(r, g, b, a)
    region.stacks:SetTextColor(r, g, b, a);
  end

  function region:SetText2Color(r, g, b, a)
    region.text2:SetTextColor(r, g, b, a);
  end

  function region:SetText1Height(height)
    local fontPath = SharedMedia:Fetch("font", data.text1Font);
    region.stacks:SetFont(fontPath, height, data.text1FontFlags == "MONOCHROME" and "OUTLINE, MONOCHROME" or data.text1FontFlags);
    region.stacks:SetTextHeight(height);
  end

  function region:SetText2Height(height)
    local fontPath = SharedMedia:Fetch("font", data.text2Font);
    region.text2:SetFont(fontPath, height, data.text2FontFlags == "MONOCHROME" and "OUTLINE, MONOCHROME" or data.text2FontFlags);
    region.text2:SetTextHeight(height);
  end

  function region:SetInverse(inverse)
    cooldown:SetReverse(not inverse);
    if (cooldown.expirationTime and cooldown.duration) then
      -- WORKAROUND SetReverse not applying until next frame
      cooldown:SetCooldown(0, 0);
      cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration, cooldown.duration);
    end
  end

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

  function region:SetUseGlowcolor(useGlowColor)
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

  function region:SetGlow(showGlow)
    region.glow = showGlow
    if MSQ then
      if (showGlow) then
        region.glowStart(region.button, region.glowColor);
      else
        region.glowStop(region.button);
      end
    elseif (showGlow) then
      if (not region.__WAGlowFrame) then
        region.__WAGlowFrame = CreateFrame("Frame", nil, region);
        region.__WAGlowFrame:SetAllPoints();
        region.__WAGlowFrame:SetSize(region.width, region.height);
      end
      local color
      if region.useGlowColor then
        color = region.glowColor
      end
      region.glowStart(region.__WAGlowFrame, color);
    else
      if (region.__WAGlowFrame) then
        region.glowStop(region.__WAGlowFrame);
      end
    end
  end

  region.useGlowColor = data.useGlowColor
  region.glowColor = data.glowColor
  region:SetGlowType(data.glowType)
  region:SetGlow(data.glow)

  if(data.cooldown) then
    function region:SetValue(value, total)
      cooldown:Hide();
      UpdateText();
    end

    function region:SetTime(duration, expirationTime)
      if (duration > 0) then
        cooldown:Show();
        cooldown.expirationTime = expirationTime;
        cooldown.duration = duration;
        cooldown:SetCooldown(expirationTime - duration, duration);
      else
        cooldown:Hide();
      end
      UpdateText();
    end

    function region:TimerTick()
      UpdateText();
    end

    function region:PreShow()
      if (region.duration > 0.01) then
        cooldown:Show();
        cooldown:SetCooldown(region.expirationTime - region.duration, region.duration);
      end
    end
  else
    cooldown:Hide();
    function region:SetValue(value, total)
      UpdateText();
    end

    function region:SetTime(duration, expirationTime)
      UpdateText();
    end

    function region:TimerTick()
      UpdateText();
    end

    function region:PreShow()
    end
  end
end

WeakAuras.RegisterRegionType("icon", create, modify, default, GetProperties);
