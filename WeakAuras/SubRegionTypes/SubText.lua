if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20

local defaultFont = WeakAuras.defaultFont
local defaultFontSize = WeakAuras.defaultFontSize

local default = function(parentType)
  if parentType == "icon" then
    -- No Shadow, but Outline
    return {
      text_text = "%p",
      text_color = {1, 1, 1, 1},
      text_font = defaultFont,
      text_fontSize = defaultFontSize,
      text_fontType = "OUTLINE",
      text_visible = true,
      text_justify = "CENTER",

      text_selfPoint = "AUTO",
      text_anchorPoint = "CENTER",
      anchorXOffset = 0,
      anchorYOffset = 0,

      text_shadowColor = { 0, 0, 0, 1},
      text_shadowXOffset = 0,
      text_shadowYOffset = 0,
      rotateText = "NONE",

      text_automaticWidth = "Auto",
      text_fixedWidth = 64,
      text_wordWrap = "WordWrap",
    }
  else
    -- With Shadow, without Outline
    return {
      text_text = "%n",
      text_color = {1, 1, 1, 1},
      text_font = defaultFont,
      text_fontSize = defaultFontSize,
      text_fontType = "None",
      text_visible = true,
      text_justify = "CENTER",

      text_selfPoint = "AUTO",
      text_anchorPoint = parentType == "aurabar" and "INNER_RIGHT" or "BOTTOMLEFT",
      anchorXOffset = 0,
      anchorYOffset = 0,

      text_shadowColor = { 0, 0, 0, 1},
      text_shadowXOffset = 1,
      text_shadowYOffset = -1,
      rotateText = "NONE",

      text_automaticWidth = "Auto",
      text_fixedWidth = 64,
      text_wordWrap = "WordWrap",
    }
  end
end

local properties = {
  text_visible = {
    display = L["Visibility"],
    setter = "SetVisible",
    type = "bool",
    defaultProperty = true
  },
  text_text = {
    display = L["Text"],
    setter = "ChangeText",
    type = "string"
  },
  text_color = {
    display = L["Color"],
    setter = "Color",
    type = "color",
  },
  text_fontSize = {
    display = L["Font Size"],
    setter = "SetTextHeight",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1,
    default = 12
  },
  text_anchorXOffset = {
    display = L["X-Offset"],
    setter = "SetXOffset",
    type = "number",
    softMin = (-1 * screenWidth),
    softMax = screenWidth,
    bigStep = 10,
  },
  text_anchorYOffset = {
    display = L["Y-Offset"],
    setter = "SetYOffset",
    type = "number",
    softMin = (-1 * screenHeight),
    softMax = screenHeight,
    bigStep = 10,
  },
}


-- Rotate object around its origin
local function animRotate(object, degrees, anchor)
  if (not anchor) then
    anchor = "CENTER";
  end
  -- Something to rotate
  if object.animationGroup or degrees ~= 0 then
    -- Create AnimationGroup and rotation animation
    object.animationGroup = object.animationGroup or object:CreateAnimationGroup();
    local group = object.animationGroup;
    group.rotate = group.rotate or group:CreateAnimation("rotation");
    local rotate = group.rotate;

    if rotate:GetDegrees() == degrees and rotate:GetOrigin() == anchor then
      return
    end

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
    if point:find("BOTTOM", 1, true) then
      yo = yo + (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
    elseif point:find("TOP", 1, true) then
      yo = yo - (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
    end
    if point:find("RIGHT", 1, true) then
      xo = xo + (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
    elseif point:find("LEFT", 1, true) then
      xo = xo - (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
    end

    -- Done
    return xo, yo;

  -- No rotation
  else
    return 0, 0;
  end
end

local function create()
  local region = CreateFrame("Frame", nil, UIParent);

  local text = region:CreateFontString(nil, "OVERLAY");
  region.text = text;

  -- WOW's layout system works best if frames and all their parents are anchored
  -- In this case, it appears that a text doesn't get the right size on the initial
  -- load with a custom font. (Though it works if the font is non-custom or after
  -- a ReloadUI). Just moving the normal AnchorSubRegion to the start of modify was not enough
  -- But anchoring the text to UIParent before re-anchoring it correctly does seem to fix
  -- the issue. Also see #1778
  text:SetPoint("CENTER", UIParent, "CENTER")

  text:SetWordWrap(true)
  text:SetNonSpaceWrap(true)

  return region;
end

local function onAcquire(subRegion)
  subRegion:Show()
end

local function onRelease(subRegion)
  subRegion:Hide()
end

local function modify(parent, region, parentData, data, first)
  region:SetParent(parent)
  local text = region.text;

  local fontPath = SharedMedia:Fetch("font", data.text_font);
  text:SetFont(fontPath, data.text_fontSize, data.text_fontType);
  if not text:GetFont() and fontPath then -- workaround font not loading correctly
    local objectName = "WeakAuras-Font-" .. data.text_font
    local fontObject = _G[objectName] or CreateFont(objectName)
    fontObject:SetFont(fontPath, data.text_fontSize, data.text_fontType == "None" and "" or data.text_fontType)
    text:SetFontObject(fontObject)
  end
  if not text:GetFont() then -- Font invalid, set the font but keep the setting
    text:SetFont(STANDARD_TEXT_FONT, data.text_fontSize, data.text_fontType);
  end
  if text:GetFont() then
    text:SetText(WeakAuras.ReplaceRaidMarkerSymbols(data.text_text));
  end

  text:SetTextHeight(data.text_fontSize);

  text:SetShadowColor(unpack(data.text_shadowColor))
  text:SetShadowOffset(data.text_shadowXOffset, data.text_shadowYOffset)
  text:SetJustifyH(data.text_justify or "CENTER")

  if (data.text_automaticWidth == "Fixed") then
    if (data.text_wordWrap == "WordWrap") then
      text:SetWordWrap(true);
      text:SetNonSpaceWrap(true);
    else
      text:SetWordWrap(false);
      text:SetNonSpaceWrap(false);
    end

    text:SetWidth(data.text_fixedWidth);
    region:SetWidth(data.text_fixedWidth);
    region.width = data.text_fixedWidth;
  else
    text:SetWidth(0);
    text:SetWordWrap(true);
    text:SetNonSpaceWrap(true);
  end

  if first then
    local containsCustomText = false
    for index, subRegion in ipairs(parentData.subRegions) do
      if subRegion.type == "subtext" and Private.ContainsCustomPlaceHolder(subRegion.text_text) then
        containsCustomText = true
        break
      end
    end
    if not containsCustomText then
      if type(parentData.conditions) == "table" then
        for _, condition in ipairs(parentData.conditions) do
          if type(condition.changes) == "table" then
            for _, change in ipairs(condition.changes) do
              if type(change.property) == "string"
                and change.property:match("sub%.%d+%.text_text")
              then
                containsCustomText = true
                break
              end
            end
          end
        end
      end
    end
    if containsCustomText and parentData.customText and parentData.customText ~= "" then
      parent.customTextFunc = WeakAuras.LoadFunction("return "..parentData.customText)
    else
      parent.customTextFunc = nil
    end
    parent.values.custom = nil
    parent.values.lastCustomTextUpdate = nil
  end

  local texts = {}
  local textStr = data.text_text or ""
  if textStr ~= "" then
    tinsert(texts, textStr)
  end

  local subRegionIndex = 1
  for index, subRegion in ipairs(parentData.subRegions) do
    if subRegion == data then
      subRegionIndex = index
      break;
    end
  end
  if type(parentData.conditions) == "table" then
    local conditionName = "sub."..subRegionIndex..".text_text"
    for _, condition in ipairs(parentData.conditions) do
      if type(condition.changes) == "table" then
        for _, change in ipairs(condition.changes) do
          if type(change.property) == "string" and change.property == conditionName then
            if type(change.value ) == "string" and change.value ~= "" then
              tinsert(texts, change.value)
            end
          end
        end
      end
    end
  end

  local getter = function(key, default)
    local fullKey = "text_text_format_" .. key
    if (data[fullKey] == nil) then
      data[fullKey] = default
    end
    return data[fullKey]
  end
  region.subTextFormatters, region.everyFrameFormatters = Private.CreateFormatters(texts, getter, false, parentData)

  function region:ConfigureTextUpdate()
    local UpdateText
    if region.text_text and Private.ContainsAnyPlaceHolders(region.text_text) then
      UpdateText = function()
        local textStr = region.text_text or ""
        textStr = Private.ReplacePlaceHolders(textStr, parent, nil, false, self.subTextFormatters)

        if text:GetFont() then
          text:SetText(WeakAuras.ReplaceRaidMarkerSymbols(textStr))
        end
        region:UpdateAnchorOnTextChange()
      end
    end

    local Update
    if parent.customTextFunc and UpdateText then
      Update = function()
        if parent.values.lastCustomTextUpdate ~= GetTime() then
          parent.values.custom = Private.RunCustomTextFunc(parent, parent.customTextFunc)
          parent.values.lastCustomTextUpdate = GetTime()
        end
        UpdateText()
      end
    else
      Update = UpdateText
    end

    local FrameTick
    if Private.ContainsPlaceHolders(region.text_text, "p")
       or Private.AnyEveryFrameFormatters(region.text_text, region.everyFrameFormatters)
    then
      FrameTick = UpdateText
    end

    if parent.customTextFunc and parentData.customTextUpdate == "update" then
      if Private.ContainsCustomPlaceHolder(region.text_text) then
        FrameTick = function()
          if parent.values.lastCustomTextUpdate ~= GetTime() then
            parent.values.custom = Private.RunCustomTextFunc(parent, parent.customTextFunc)
            parent.values.lastCustomTextUpdate = GetTime()
          end
          UpdateText()
        end
      end
    end

    region.Update = Update
    region.FrameTick = FrameTick

    if not UpdateText then
      if text:GetFont() then
        local textStr = region.text_text
        textStr = textStr:gsub("\\n", "\n");
        text:SetText(WeakAuras.ReplaceRaidMarkerSymbols(textStr))
      end
    end
  end

  function region:ConfigureSubscribers()
    local visible = self:IsShown()
    if self.Update then
      if visible then
        parent.subRegionEvents:AddSubscriber("Update", region)
      end
    else
      parent.subRegionEvents:RemoveSubscriber("Update", region)
    end
    if self.FrameTick then
      if visible then
        parent.subRegionEvents:AddSubscriber("FrameTick", region)
      end
    else
      parent.subRegionEvents:RemoveSubscriber("FrameTick", region)
    end
    if self.Update and parent.state and visible then
      self:Update()
    end
  end

  function region:ChangeText(msg)
    region.text_text = msg
    region:ConfigureTextUpdate()
    region:ConfigureSubscribers()
  end

  region.text_text = data.text_text
  region:ConfigureTextUpdate()

  function region:SetTextHeight(size)
    local fontPath = SharedMedia:Fetch("font", data.text_font);
    if not text:GetFont() then -- Font invalid, set the font but keep the setting
      text:SetFont(STANDARD_TEXT_FONT, size, data.text_fontType);
    else
      region.text:SetFont(fontPath, size, data.text_fontType);
    end
    region.text:SetTextHeight(size)
    region:UpdateAnchorOnTextChange();
  end

  function region:SetVisible(visible)
    if visible then
      self:Show()
    else
      self:Hide()
    end
    region:ConfigureSubscribers()
  end

  function region:Color(r, g, b, a)
    region.color_r = r;
    region.color_g = g;
    region.color_b = b;
    region.color_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    text:SetTextColor(region.color_anim_r or r, region.color_anim_g or g,
                      region.color_anim_b or b, region.color_anim_a or a)
  end

  local selfPoint = data.text_selfPoint
  if selfPoint == "AUTO" then
    if parentData.regionType == "icon" then
      local anchorPoint = data.text_anchorPoint or "CENTER"
      if anchorPoint:sub(1, 6) == "INNER_" then
        selfPoint = anchorPoint:sub(7)
      elseif anchorPoint:sub(1, 6) == "OUTER_" then
        anchorPoint = anchorPoint:sub(7)
        selfPoint = Private.inverse_point_types[anchorPoint] or "CENTER"
      else
        selfPoint = "CENTER"
      end
    elseif parentData.regionType == "aurabar" then
      selfPoint = data.text_anchorPoint or "CENTER"
      if selfPoint:sub(1, 5) == "ICON_" then
        selfPoint = selfPoint:sub(6)
      elseif selfPoint:sub(1, 6) == "INNER_" then
        selfPoint = selfPoint:sub(7)
      end
      selfPoint = Private.point_types[selfPoint] and selfPoint or "CENTER"
    else
      selfPoint = Private.inverse_point_types[data.text_anchorPoint or "CENTER"] or "CENTER"
    end
  end

  region.text_anchorXOffset = data.text_anchorXOffset
  region.text_anchorYOffset = data.text_anchorYOffset

  local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;

  region.UpdateAnchor = function(self)
    local xo, yo = getRotateOffset(text, textDegrees, selfPoint)
    parent:AnchorSubRegion(text, "point", selfPoint, data.text_anchorPoint,
                           (self.text_anchorXOffset or 0) + xo, (self.text_anchorYOffset or 0) + yo)
  end

  if textDegrees == 0 then
    region.UpdateAnchorOnTextChange = function() end
  else
    region.UpdateAnchorOnTextChange = region.UpdateAnchor
  end

  region.SetXOffset = function(self, xOffset)
    if self.text_anchorXOffset == xOffset then
      return
    end
    self.text_anchorXOffset = xOffset
    self:UpdateAnchor()
  end

  region.SetYOffset = function(self, yOffset)
    if self.text_anchorYOffset == yOffset then
      return
    end
    self.text_anchorYOffset = yOffset
    self:UpdateAnchor()
  end

  region:Color(data.text_color[1], data.text_color[2], data.text_color[3], data.text_color[4]);
  region:SetVisible(data.text_visible)
  region:UpdateAnchor()
  animRotate(text, textDegrees, selfPoint)
end

local function addDefaultsForNewAura(data)
  if data.regionType == "aurabar" then
    tinsert(data.subRegions, {
      ["type"] = "subtext",
      text_text = "%p",
      text_color = {1, 1, 1, 1},
      text_font = defaultFont,
      text_fontSize = defaultFontSize,
      text_fontType = "None",
      text_justify = "CENTER",
      text_visible = true,

      text_selfPoint = "AUTO",
      text_anchorPoint = "INNER_LEFT",
      anchorXOffset = 0,
      anchorYOffset = 0,

      text_shadowColor = { 0, 0, 0, 1},
      text_shadowXOffset = 1,
      text_shadowYOffset = -1,

      rotateText = "NONE",
    });

    tinsert(data.subRegions, {
      ["type"] = "subtext",
      text_text = "%n",
      text_color = {1, 1, 1, 1},
      text_font = defaultFont,
      text_fontSize = defaultFontSize,
      text_fontType = "None",
      text_justify = "CENTER",
      text_visible = true,

      text_selfPoint = "AUTO",
      text_anchorPoint = "INNER_RIGHT",
      anchorXOffset = 0,
      anchorYOffset = 0,

      text_shadowColor = { 0, 0, 0, 1},
      text_shadowXOffset = 1,
      text_shadowYOffset = -1,

      rotateText = "NONE",
    });
  elseif data.regionType == "icon" then
    tinsert(data.subRegions, {
      ["type"] = "subtext",
      text_text = "%s",
      text_color = {1, 1, 1, 1},
      text_font = defaultFont,
      text_fontSize = defaultFontSize,
      text_fontType = "OUTLINE",
      text_justify = "CENTER",
      text_visible = true,

      text_selfPoint = "AUTO",
      text_anchorPoint = "INNER_BOTTOMRIGHT",
      anchorXOffset = 0,
      anchorYOffset = 0,

      text_shadowColor = { 0, 0, 0, 1},
      text_shadowXOffset = 0,
      text_shadowYOffset = 0,

      rotateText = "NONE",
    });
  end
end

local function supports(regionType)
  return regionType == "texture"
         or regionType == "progresstexture"
         or regionType == "icon"
         or regionType == "aurabar"
end

WeakAuras.RegisterSubRegionType("subtext", L["Text"], supports, create, modify, onAcquire, onRelease,
                                default, addDefaultsForNewAura, properties)
