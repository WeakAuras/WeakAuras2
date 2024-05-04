if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

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
  progressSource = {-1, "" },
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

Private.regionPrototype.AddProgressSourceToDefault(default)
Private.regionPrototype.AddAlphaToDefault(default);

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
    display = {L["Icon"], L["Manual"]},
    setter = "SetIcon",
    type = "icon",
  }
};

Private.regionPrototype.AddProperties(properties, default);

local function GetProperties(data)
  local result = CopyTable(properties)
  result.iconSource.values = Private.IconSources(data)
  result.progressSource.values = Private.GetProgressSourcesForUi(data)
  return result
end

local function GetTexCoord(region, texWidth, aspectRatio, xOffset, yOffset)
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
    if(i % 2 == 1) then
      region.currentCoord[i] = (coord - 0.5) * texWidth * xRatio + 0.5 - xOffset;
    else
      region.currentCoord[i] = (coord - 0.5) * texWidth * yRatio + 0.5 - yOffset;
    end
  end

  return unpack(region.currentCoord)
end

local function AnchorSubRegion(self, subRegion, anchorType, selfPoint, anchorPoint, anchorXOffset, anchorYOffset)
  if anchorType == "area" then
    Private.regionPrototype.AnchorSubRegion(selfPoint == "region" and self or self.icon,
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
  --- @cast region table|Frame
  region.regionType = "icon"
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetResizeBounds(1, 1)

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
    --- @cast button table|Button
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

  Private.regionPrototype.create(region);

  region.AnchorSubRegion = AnchorSubRegion

  return region;
end

local function modify(parent, region, data)
  -- Legacy members stacks and text2
  region.stacks = nil
  region.text2 = nil

  Private.regionPrototype.modify(parent, region, data);

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

    local ulx, uly, llx, lly, urx, ury, lrx, lry
      = GetTexCoord(region, texWidth, aspectRatio, region.texXOffset, -region.texYOffset)

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
  region.texXOffset = data.texXOffset or 0
  region.texYOffset = data.texYOffset or 0
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
    region.tooltipFrame:EnableMouseMotion(true);
    region.tooltipFrame:SetMouseClickEnabled(false);
  elseif region.tooltipFrame then
    region.tooltipFrame:EnableMouseMotion(false);
  end

  function region:SetInverse(inverse)
    if region.inverseDirection == inverse then
      return
    end

    region.inverseDirection = inverse
    region:UpdateEffectiveInverse()
  end

  function region:UpdateEffectiveInverse()
    -- If cooldown.inverse == false then effectiveReverse = not inverse
    -- If cooldown.inverse == true then effectiveReverse = inverse
    local effectiveReverse = not region.inverseDirection == not cooldown.inverse
    cooldown:SetReverse(effectiveReverse)
    if (cooldown.expirationTime and cooldown.duration and cooldown:IsShown()) then
      -- WORKAROUND SetReverse not applying until next frame
      cooldown:SetCooldown(0, 0)
      cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration,
                           cooldown.duration,
                           cooldown.useCooldownModRate and cooldown.modRate or nil)
    end
  end

  region:SetInverse(data.inverse)

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
    Private.SetTextureOrAtlas(self.icon, iconPath)
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
    function region:UpdateValue()
      cooldown.value = self.value
      cooldown.total = self.total
      cooldown.modRate = nil
      if (self.value >= 0 and self.value <= self.total) then
        cooldown:Show()
        cooldown:SetCooldown(GetTime() - (self.total - self.value), self.total)
        cooldown:Pause()
      else
        cooldown:Hide();
      end
    end

    function region:UpdateTime()
      if self.paused then
        cooldown:Pause()
      else
        cooldown:Resume()
      end
      if (self.duration > 0 and self.expirationTime > GetTime() and self.expirationTime ~= math.huge) then
        cooldown:Show();
        cooldown.expirationTime = self.expirationTime
        cooldown.duration = self.duration
        cooldown.modRate = self.modRate
        cooldown.inverse = self.inverse
        region:UpdateEffectiveInverse()
        cooldown:SetCooldown(self.expirationTime - self.duration, self.duration,
                             cooldown.useCooldownModRate and self.modRate or nil)
      else
        cooldown.expirationTime = self.expirationTime
        cooldown.duration = self.duration
        cooldown.modRate = self.modRate
        cooldown:Hide();
      end
    end

    function region:PreShow()
      if (cooldown.duration and cooldown.duration > 0.01 and cooldown.duration ~= math.huge and cooldown.expirationTime ~= math.huge) then
        cooldown:Show();
        cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration,
                             cooldown.duration,
                             cooldown.useCooldownModRate and cooldown.modRate or nil);
        cooldown:Resume()
      end
    end

    function region:Update()
      region:UpdateProgress()
      region:UpdateIcon()
    end
  else
    region.UpdateValue = nil
    region.UpdateTime = nil

    function region:Update()
      region:UpdateProgress()
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

  Private.regionPrototype.modifyFinish(parent, region, data);

  --- WORKAROUND
  -- This fixes a issue with barmodels not appearing on icons if the
  -- icon is shown delayed
  region:SetWidth(region:GetWidth())
  region:SetHeight(region:GetHeight())
end

local function validate(data)
  Private.EnforceSubregionExists(data, "subbackground")
end

Private.RegisterRegionType("icon", create, modify, default, GetProperties, validate)
