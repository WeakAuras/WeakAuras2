local SharedMedia = LibStub("LibSharedMedia-3.0");
local MSQ = LibStub("Masque", true);
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
  textColor = {1, 1, 1, 1},
  displayStacks = "%s",
  stacksPoint = "BOTTOMRIGHT",
  stacksContainment = "INSIDE",
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  font = "Friz Quadrata TT",
  fontFlags = "OUTLINE",
  fontSize = 12,
  stickyDuration = false,
  zoom = 0,
  frameStrata = 1,
  customTextUpdate = "update",
  glow = false
};

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
  },
  height = {
    display = L["Height"],
    setter = "SetRegionHeight",
    type = "number",
    min = 1,
    softMax = screenHeight,
    bigStep = 1
  },
  glow = {
    display = L["Glow"],
    setter = "SetGlow",
    type = "bool"
  },
  textColor = {
    display = L["Text Color"],
    setter = "SetTextColor",
    type = "color"
  },
  fontSize = {
    display = L["Text Size"],
    setter = "SetTextHeight",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1
  },
  color = {
    display = L["Color"],
    setter = "Color",
    type = "color"
  }
};

local function GetTexCoord(region, texWidth)
  local texCoord

  if region.MSQGroup then
    region.MSQGroup:ReSkin();

    local db = region.MSQGroup.db
    if db and not db.Disabled then
      local currentCoord = {region.icon:GetTexCoord()}

      texCoord = {}
      for i, coord in pairs(currentCoord) do
        if coord > 0.5 then
          texCoord[i] = coord - coord * texWidth
        else
          texCoord[i] = coord + (1 - coord) * texWidth
        end
      end
    end
  end

  if not texCoord then
    texCoord = {texWidth, texWidth, texWidth, 1 - texWidth, 1 - texWidth, texWidth, 1 - texWidth, 1 - texWidth}
  end

  return unpack(texCoord)
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
  stacksFrame:SetFrameLevel(cooldownFrameLevel)
  region.stacks = stacks;
  region.values = {};
  region.duration = 0;
  region.expirationTime = math.huge;

  local SetFrameLevel = region.SetFrameLevel;

  function region.SetFrameLevel(self, level)
    SetFrameLevel(region, level);
    cooldown:SetFrameLevel(level);
    stacksFrame:SetFrameLevel(level + 1);
    if (self.__WAGlowFrame) then
      self.__WAGlowFrame:SetFrameLevel(level + 1);
    end
    if button then
      button:SetFrameLevel(level);
    end
  end

  return region;
end

local function modify(parent, region, data)
  local button, icon, cooldown, stacks = region.button, region.icon, region.cooldown, region.stacks;

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
  icon:SetAllPoints();

  region:ClearAllPoints();

  WeakAuras.AnchorFrame(data, region, parent);

  local sxo, syo = 0, 0;
  if(data.stacksPoint:find("LEFT")) then
    sxo = data.width / 10;
  elseif(data.stacksPoint:find("RIGHT")) then
    sxo = data.width / -10;
  end
  if(data.stacksPoint:find("BOTTOM")) then
    syo = data.height / 10;
  elseif(data.stacksPoint:find("TOP")) then
    syo = data.height / -10;
  end
  stacks:ClearAllPoints();
  if(data.stacksContainment == "INSIDE") then
    stacks:SetPoint(data.stacksPoint, icon, data.stacksPoint, sxo, syo);
  else
    local selfPoint = WeakAuras.inverse_point_types[data.stacksPoint];
    stacks:SetPoint(selfPoint, icon, data.stacksPoint, -0.5 * sxo, -0.5 * syo);
  end
  local fontPath = SharedMedia:Fetch("font", data.font);
  stacks:SetFont(fontPath, data.fontSize, data.fontFlags == "MONOCHROME" and "OUTLINE, MONOCHROME" or data.fontFlags);
  stacks:SetTextHeight(data.fontSize);
  stacks:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);

  local texWidth = 0.25 * data.zoom;

  icon:SetTexCoord(GetTexCoord(region, texWidth))
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

  function region:Color(r, g, b, a)
    region.color_r = r;
    region.color_g = g;
    region.color_b = b;
    region.color_a = a;
    icon:SetVertexColor(r, g, b, a);
    if MSQ then
      button:SetAlpha(a or 1);
    end
  end

  function region:GetColor()
    return region.color_r or data.color[1], region.color_g or data.color[2],
      region.color_b or data.color[3], region.color_a or data.color[4];
  end

  region:Color(data.color[1], data.color[2], data.color[3], data.color[4]);

  local UpdateText;
  if (data.displayStacks:find('%%')) then
    UpdateText = function()
      local textStr = data.displayStacks or "";
      textStr = WeakAuras.ReplacePlaceHolders(textStr, region.values, region.state);

      if(stacks.displayStacks ~= textStr) then
        if stacks:GetFont() then
          stacks:SetText(textStr);
          stacks.displayStacks = textStr;
        end
      end
    end
  else
    stacks:SetText(data.displayStacks);
    stacks.displayStacks = data.displayStacks;
    UpdateText = function() end
  end

  local customTextFunc = nil
  if(data.displayStacks:find("%%c") and data.customText) then
    customTextFunc = WeakAuras.LoadFunction("return "..data.customText, region.id)
  end
  if (customTextFunc) then
    local values = region.values;
    region.UpdateCustomText = function()
      WeakAuras.ActivateAuraEnvironment(region.id, region.cloneId, region.state);
      local custom = customTextFunc(region.expirationTime, region.duration,
        values.progress, values.duration, values.name, values.icon, values.stacks);
      WeakAuras.ActivateAuraEnvironment(nil);
      custom = WeakAuras.EnsureString(custom);
      if(custom ~= values.custom) then
        values.custom = custom;
        UpdateText();
      end
    end
    if(data.customTextUpdate == "update") then
      WeakAuras.RegisterCustomTextUpdates(region);
    else
      WeakAuras.UnregisterCustomTextUpdates(region);
    end
  else
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

  function region:Scale(scalex, scaley)
    region.scalex = scalex;
    region.scaley = scaley;
    local mirror_h, mirror_v, width, height;
    if(scalex < 0) then
      mirror_h = true;
      scalex = scalex * -1;
    end
    width = region.width * scalex;
    region:SetWidth(width);
    if(scaley < 0) then
      mirror_v = true;
      scaley = scaley * -1;
    end
    height = region.height * scaley;
    region:SetHeight(height);
    if MSQ then
      button:SetWidth(width);
      button:SetHeight(height);
      button:SetAllPoints();
    end
    icon:SetAllPoints();

    local texWidth = 0.25 * data.zoom;

    local ulx, uly, llx, lly, urx, ury, lrx, lry = GetTexCoord(region, texWidth)

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

  function region:SetDesaturated(b)
    icon:SetDesaturated(b);
  end

  function region:SetRegionWidth(width)
    region.width = width
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetRegionHeight(height)
    region.height = height
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetTextColor(r, g, b, a)
    region.stacks:SetTextColor(r, g, b, a);
  end

  function region:SetTextHeight(height)
    local fontPath = SharedMedia:Fetch("font", data.font);
    region.stacks:SetFont(fontPath, height, data.fontFlags == "MONOCHROME" and "OUTLINE, MONOCHROME" or data.fontFlags);
    region.stacks:SetTextHeight(height);
  end

  function region:SetGlow(showGlow)
    if (showGlow) then
      if (not region.__WAGlowFrame) then
        region.__WAGlowFrame = CreateFrame("Frame", nil, region);
        region.__WAGlowFrame:SetAllPoints();
      end
      WeakAuras.ShowOverlayGlow(region.__WAGlowFrame);
    else
      if (region.__WAGlowFrame) then
        WeakAuras.HideOverlayGlow(region.__WAGlowFrame);
      end
    end
  end

  region:SetGlow(data.glow);

  if(data.cooldown) then
    function region:SetValue(value, total)
      cooldown:Hide();
      UpdateText();
    end

    function region:SetTime(duration, expirationTime)
      cooldown:Show();
      cooldown:SetCooldown(expirationTime - duration, duration);
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

WeakAuras.RegisterRegionType("icon", create, modify, default, properties);
