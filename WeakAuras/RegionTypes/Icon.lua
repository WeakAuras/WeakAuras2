if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local L = WeakAuras.L
local MSQ = LibStub("Masque", true);
if MSQ then
  MSQ:AddType("WA_Aura", {"Icon", "Cooldown"})
end

-- WoW API
local _G = _G

local default = {
  icon = true,
  desaturate = false,
  iconSource = -1,
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
  cooldown = true,
  cooldownTextDisabled = false,
  cooldownSwipe = true,
  cooldownEdge = false,
  useCooldownModRate = true
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
  cooldownText = {
    display = { L["Cooldown"], L["Hide Timer Text"]},
    setter = "SetHideCountdownNumbers",
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
  iconSource = {
    display = {L["Icon"], L["Source"]},
    setter = "SetIconSource",
    type = "list",
    values = {}
  },
  displayIcon = {
    display = {L["Icon"], L["Fallback"]},
    setter = "SetIcon",
    type = "icon",
  }
};

WeakAuras.regionPrototype.AddProperties(properties, default);

local function GetProperties(data)
  local result = CopyTable(properties)
  result.iconSource.values = Private.IconSources(data)
  return result
end

local function GetTexCoord(region, texWidth, aspectRatio)
  region.currentCoord = region.currentCoord or {}
  local usesMasque = false
  if region.MSQGroup then
    local db = region.MSQGroup.db
    if db and not db.Disabled then
      usesMasque = true
      region.currentCoord[1], region.currentCoord[2], region.currentCoord[3], region.currentCoord[4],
        region.currentCoord[5], region.currentCoord[6], region.currentCoord[7], region.currentCoord[8]
        = region.icon:GetTexCoord()
    end
  end
  if (not usesMasque) then
    region.currentCoord[1], region.currentCoord[2], region.currentCoord[3], region.currentCoord[4],
      region.currentCoord[5], region.currentCoord[6], region.currentCoord[7], region.currentCoord[8]
      = 0, 0, 0, 1, 1, 0, 1, 1;
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
  if anchorType == "area" then
    WeakAuras.regionPrototype.AnchorSubRegion(selfPoint == "region" and self or self.icon,
                    subRegion, anchorType, selfPoint, anchorPoint, anchorXOffset, anchorYOffset)
  else
    subRegion:ClearAllPoints()
    anchorPoint = anchorPoint or "CENTER"
    local anchorRegion = self.icon
    if anchorPoint:sub(1, 6) == "INNER_" then
      if not self.inner then
        self.inner = CreateFrame("Frame", nil, self)
        self.inner:SetPoint("CENTER")
        self.UpdateInnerOuterSize()
      end
      anchorRegion = self.inner
      anchorPoint = anchorPoint:sub(7)
    elseif anchorPoint:sub(1, 6) == "OUTER_" then
      if not self.outer then
        self.outer = CreateFrame("Frame", nil, self)
        self.outer:SetPoint("CENTER")
        self.UpdateInnerOuterSize()
      end
      anchorRegion = self.outer
      anchorPoint = anchorPoint:sub(7)
    end
    anchorXOffset = anchorXOffset or 0
    anchorYOffset = anchorYOffset or 0

    if not Private.point_types[selfPoint] then
      selfPoint = "CENTER"
    end

    if not Private.point_types[anchorPoint] then
      anchorPoint = "CENTER"
    end

    subRegion:SetPoint(selfPoint, anchorRegion, anchorPoint, anchorXOffset, anchorYOffset)
  end
end

local function create(parent, data)
  local font = "GameFontHighlight";

  local region = CreateFrame("Frame", nil, parent);
  region.regionType = "icon"
  region:SetMovable(true);
  region:SetResizable(true);
  if region.SetResizeBounds then
    region:SetResizeBounds(1, 1)
  else
    region:SetMinResize(1, 1)
  end

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
  --The reason is so that WeakAuras cooldown frames can interact properly with OmniCC
  -- (i.e., put on its ignore list for timer overlays)
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

  local cooldown = CreateFrame("Cooldown", "WeakAurasCooldown"..frameId, region, "CooldownFrameTemplate");
  region.cooldown = cooldown;
  cooldown:SetAllPoints(icon);
  cooldown:SetDrawBling(false)
  cooldown.SetDrawSwipeOrg = cooldown.SetDrawSwipe
  cooldown.SetDrawSwipe = function() end

  if not OmniCC and ElvUI and ElvUI[1] and ElvUI[1].CooldownEnabled
     and ElvUI[1].RegisterCooldown and ElvUI[1]:CooldownEnabled()
  then
    ElvUI[1]:RegisterCooldown(cooldown, "WeakAuras");
  end

  local SetFrameLevel = region.SetFrameLevel;

  function region.SetFrameLevel(self, level)
    SetFrameLevel(region, level);
    cooldown:SetFrameLevel(level);
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

  region.iconSource = data.iconSource
  region.displayIcon = data.displayIcon

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

    if region.MSQGroup then
      region.MSQGroup:ReSkin(button)
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

  local tooltipType = Private.CanHaveTooltip(data);
  if(tooltipType and data.useTooltip) then
    if not region.tooltipFrame then
      region.tooltipFrame = CreateFrame("Frame", nil, region);
      region.tooltipFrame:SetAllPoints(region);
      region.tooltipFrame:SetScript("OnEnter", function()
        Private.ShowMouseoverTooltip(region, region);
      end);
      region.tooltipFrame:SetScript("OnLeave", Private.HideTooltip);
    end
    region.tooltipFrame:EnableMouse(true);
  elseif region.tooltipFrame then
    region.tooltipFrame:EnableMouse(false);
  end

  cooldown:SetReverse(not data.inverse);

  function region:SetHideCountdownNumbers(cooldownTextDisabled)
    cooldown:SetHideCountdownNumbers(cooldownTextDisabled);
    if OmniCC and OmniCC.Cooldown and OmniCC.Cooldown.SetNoCooldownCount then
      OmniCC.Cooldown.SetNoCooldownCount(cooldown, cooldownTextDisabled)
    elseif ElvUI and ElvUI[1] and ElvUI[1].CooldownEnabled
           and ElvUI[1].ToggleCooldown and ElvUI[1]:CooldownEnabled()
    then
      ElvUI[1]:ToggleCooldown(cooldown, not cooldownTextDisabled);
    end
  end
  region:SetHideCountdownNumbers(data.cooldownTextDisabled)

  function region:Color(r, g, b, a)
    region.color_r = r;
    region.color_g = g;
    region.color_b = b;
    region.color_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    icon:SetVertexColor(region.color_anim_r or r, region.color_anim_g or g,
                        region.color_anim_b or b, region.color_anim_a or a)
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

  function region:SetIcon(iconPath)
    if self.displayIcon == iconPath then
      return
    end
    self.displayIcon = iconPath
    self:UpdateIcon()
  end

  function region:SetIconSource(source)
    if self.iconSource == source then
      return
    end

    self.iconSource = source
    self:UpdateIcon()
  end

  function region:UpdateIcon()
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
    WeakAuras.SetTextureOrAtlas(self.icon, iconPath)
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
      cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration,
                           cooldown.duration,
                           cooldown.useCooldownModRate and cooldown.modRate or nil);
    end
  end

  function region:SetCooldownSwipe(cooldownSwipe)
    region.cooldownSwipe = cooldownSwipe;
    cooldown:SetDrawSwipeOrg(cooldownSwipe);
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

  cooldown.expirationTime = nil;
  cooldown.duration = nil;
  cooldown.modRate = nil
  cooldown.useCooldownModRate = data.useCooldownModRate
  cooldown:Hide()
  if(data.cooldown) then
    function region:SetValue(value, total)
      cooldown.value = value
      cooldown.total = total
      cooldown.modRate = nil
      if (value >= 0 and value <= total) then
        cooldown:Show()
        cooldown:SetCooldown(GetTime() - (total - value), total)
      else
        cooldown:Hide();
      end
    end

    function region:SetTime(duration, expirationTime, modRate)
      if (duration > 0 and expirationTime > GetTime()) then
        cooldown:Show();
        cooldown.expirationTime = expirationTime;
        cooldown.duration = duration;
        cooldown.modRate = modRate;
        cooldown:SetCooldown(expirationTime - duration, duration, cooldown.useCooldownModRate and modRate or nil);
      else
        cooldown.expirationTime = expirationTime;
        cooldown.duration = duration;
        cooldown.modRate = modRate;
        cooldown:Hide();
      end
    end

    function region:PreShow()
      if (cooldown.duration and cooldown.duration > 0.01) then
        cooldown:Show();
        cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration,
                             cooldown.duration,
                             cooldown.useCooldownModRate and cooldown.modRate or nil);
        cooldown:Resume()
      end
    end

    function region:Update()
      local state = region.state
      if state.progressType == "timed" then
        local expirationTime
        if state.paused == true then
          if not region.paused then
            region:Pause()
          end
          cooldown:Pause()
          expirationTime = GetTime() + (state.remaining or 0)
        else
          if region.paused then
            region:Resume()
          end
          cooldown:Resume()
          expirationTime = state.expirationTime and state.expirationTime > 0 and state.expirationTime or math.huge;
        end

        local duration = state.duration or 0
        if region.adjustedMinRelPercent then
          region.adjustedMinRel = region.adjustedMinRelPercent * duration
        end
        local adjustMin = region.adjustedMin or region.adjustedMinRel or 0;

        local max
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

        region:SetTime(max - adjustMin, expirationTime - adjustMin, state.modRate);
      elseif state.progressType == "static" then
        local value = state.value or 0;
        local total = state.total or 0;
        if region.adjustedMinRelPercent then
          region.adjustedMinRel = region.adjustedMinRelPercent * total
        end
        local adjustMin = region.adjustedMin or region.adjustedMinRel or 0;
        local max = region.adjustedMax or region.adjustedMaxRel or total;
        region:SetValue(value - adjustMin, max - adjustMin);
        cooldown:Pause()
      else
        region:SetTime(0, math.huge)
      end

      region:UpdateIcon()
    end
  else
    region.SetValue = nil
    region.SetTime = nil

    function region:Update()
      local state = region.state
      region:UpdateIcon()
    end
  end

  -- Backwards compability function
  function region:SetGlow(glow)
    for index, subRegion in ipairs(self.subRegions) do
      if subRegion.type == "subglow" then
        subRegion:SetVisible(glow)
      end
    end
  end

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);

  --- WORKAROUND
  -- This fixes a issue with barmodels not appearing on icons if the
  -- icon is shown delayed
  region:SetWidth(region:GetWidth())
  region:SetHeight(region:GetHeight())
end

local function validate(data)
  Private.EnforceSubregionExists(data, "subbackground")
end

WeakAuras.RegisterRegionType("icon", create, modify, default, GetProperties, validate)
