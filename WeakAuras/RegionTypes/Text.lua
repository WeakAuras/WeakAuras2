if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local defaultFont = WeakAuras.defaultFont
local defaultFontSize = WeakAuras.defaultFontSize

local default = {
  displayText = "%p",
  outline = "OUTLINE",
  color = {1, 1, 1, 1},
  justify = "LEFT",
  selfPoint = "BOTTOM",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  font = defaultFont,
  fontSize = defaultFontSize,
  frameStrata = 1,
  customTextUpdate = "event",
  automaticWidth = "Auto",
  fixedWidth = 200,
  wordWrap = "WordWrap",

  shadowColor = { 0, 0, 0, 1},
  shadowXOffset = 1,
  shadowYOffset = -1
};

local properties = {
  color = {
    display = L["Color"],
    setter = "Color",
    type = "color",
  },
  fontSize = {
    display = L["Font Size"],
    setter = "SetTextHeight",
    type = "number",
    min = 6,
    softMax = 72,
    step = 1,
    default = 12
  },
  displayText = {
    display = L["Text"],
    setter = "ChangeText",
    type = "string"
  },
}

Private.regionPrototype.AddProperties(properties, default);

local function create(parent)
  local region = CreateFrame("Frame", nil, parent);
  region.regionType = "text"
  region:SetMovable(true);

  local text = region:CreateFontString(nil, "OVERLAY");
  region.text = text;
  text:SetWordWrap(true);
  text:SetNonSpaceWrap(true);

  Private.regionPrototype.create(region);

  return region;
end

local function modify(parent, region, data)
  Private.regionPrototype.modify(parent, region, data);
  local text = region.text;

  local fontPath = SharedMedia:Fetch("font", data.font);
  text:SetFont(fontPath, data.fontSize, data.outline);
  if not text:GetFont() and fontPath then -- workaround font not loading correctly
    local objectName = "WeakAuras-Font-" .. data.font
    local fontObject = _G[objectName] or CreateFont(objectName)
    fontObject:SetFont(fontPath, data.fontSize, data.outline == "None" and "" or data.outline)
    text:SetFontObject(fontObject)
  end
  if not text:GetFont() then -- Font invalid, set the font but keep the setting
    text:SetFont(STANDARD_TEXT_FONT, data.fontSize, data.outline);
  end
  text:SetJustifyH(data.justify);

  text:ClearAllPoints();
  text:SetPoint("CENTER", UIParent, "CENTER");

  region.width = text:GetWidth();
  region.height = text:GetStringHeight();
  region:SetWidth(region.width);
  region:SetHeight(region.height);

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

  text:SetTextHeight(data.fontSize);
  text:SetShadowColor(unpack(data.shadowColor))
  text:SetShadowOffset(data.shadowXOffset, data.shadowYOffset)

  text:ClearAllPoints();
  text:SetPoint(data.justify, region, data.justify);

  local SetText;

  if (data.automaticWidth == "Fixed") then
    if (data.wordWrap == "WordWrap") then
      text:SetWordWrap(true);
      text:SetNonSpaceWrap(true);
    else
      text:SetWordWrap(false);
      text:SetNonSpaceWrap(false);
    end

    text:SetWidth(data.fixedWidth);
    region:SetWidth(data.fixedWidth);
    region.width = data.fixedWidth;
    SetText = function(textStr)
      if text:GetFont() then
        text:SetText(WeakAuras.ReplaceRaidMarkerSymbols(textStr));
      end

      local height = text:GetStringHeight();

      if(region.height ~= height) then
        region.height = height
        region:SetHeight(height)
        if data.parent then
          Private.EnsureRegion(data.parent)
          if Private.regions[data.parent].region.PositionChildren then
            Private.regions[data.parent].region:PositionChildren()
          end
        end
      end
    end
  else
    text:SetWidth(0);
    text:SetWordWrap(true);
    text:SetNonSpaceWrap(true);
    SetText = function(textStr)
      if(textStr ~= text.displayText) then
        if text:GetFont() then
          text:SetText(WeakAuras.ReplaceRaidMarkerSymbols(textStr));
        end
        -- If the text changes we need to figure out the text size
        -- To unset scaling we need to temporarily detach the text from
        -- the region
        text:SetParent(UIParent)
        local width = text:GetWidth();
        local height = text:GetStringHeight();
        if(width ~= region.width or height ~= region.height ) then
          region.width = width
          region.height = height
          region:SetWidth(region.width);
          region:SetHeight(region.height);
          if(data.parent and Private.regions[data.parent].region.PositionChildren) then
            Private.regions[data.parent].region:PositionChildren();
          end
        end
        text:SetParent(region)
      end
    end
  end

  local containsCustomText = false
  if Private.ContainsCustomPlaceHolder(data.displayText) then
    containsCustomText = true
  end

  local formatters, everyFrameFormatters
  do
    local getter = function(key, default)
      local fullKey = "displayText_format_" .. key
      if (data[fullKey] == nil) then
        data[fullKey] = default
      end
      return data[fullKey]
    end

    local texts = {}
    tinsert(texts, data.displayText)

    if type(data.conditions) == "table" then
      for _, condition in ipairs(data.conditions) do
        if type(condition.changes) == "table" then
          for _, change in ipairs(condition.changes) do
            if type(change.property) == "string"
            and change.property == "displayText"
            and type(change.value) == "string"
            and Private.ContainsAnyPlaceHolders(change.value)
            then
              if not containsCustomText and Private.ContainsCustomPlaceHolder(change.value) then
                containsCustomText = true
              end
              tinsert(texts, change.value)
            end
          end
        end
      end
    end

    formatters, everyFrameFormatters = Private.CreateFormatters(texts, getter, false, data)
  end

  local customTextFunc = nil
  if containsCustomText and data.customText and data.customText ~= "" then
    customTextFunc = WeakAuras.LoadFunction("return "..data.customText)
  end

  function region:ConfigureTextUpdate()
    local UpdateText
    if self.displayText and Private.ContainsAnyPlaceHolders(self.displayText) then
      UpdateText = function()
        local textStr = self.displayText;
        textStr = Private.ReplacePlaceHolders(textStr, self, nil, false, formatters);
        if (textStr == nil or textStr == "") then
          textStr = " ";
        end

        SetText(textStr)
      end
    end

    local Update
    if customTextFunc and self.displayText and Private.ContainsCustomPlaceHolder(self.displayText) then
      Update = function()
        self.values.custom = Private.RunCustomTextFunc(self, customTextFunc)
        UpdateText()
      end
    else
      Update = UpdateText or function() end
    end

    local FrameTick
    if Private.ContainsPlaceHolders(self.displayText, "p")
      or Private.AnyEveryFrameFormatters(self.displayText, everyFrameFormatters)
    then
      FrameTick = UpdateText
    end

    if customTextFunc and data.customTextUpdate == "update" then
      if Private.ContainsCustomPlaceHolder(self.displayText) then
        FrameTick = function()
          self.values.custom = Private.RunCustomTextFunc(self, customTextFunc)
          UpdateText()
        end
      end
    end

    self.Update = Update
    self.FrameTick = FrameTick

    if not UpdateText then
      local textStr = self.displayText
      textStr = textStr:gsub("\\n", "\n");
      SetText(textStr)
    end
  end

  function region:ConfigureSubscribers()
    if self.FrameTick then
      self.subRegionEvents:AddSubscriber("FrameTick", self)
    else
      self.subRegionEvents:RemoveSubscriber("FrameTick", self)
    end

    if self.Update and self.state then
      self:Update()
    end
  end

  function region:Color(r, g, b, a)
    region.color_r = r;
    region.color_g = g;
    region.color_b = b;
    region.color_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    text:SetTextColor(region.color_anim_r or r, region.color_anim_g or g, region.color_anim_b or b, region.color_anim_a or a);
  end

  function region:ColorAnim(r, g, b, a)
    region.color_anim_r = r;
    region.color_anim_g = g;
    region.color_anim_b = b;
    region.color_anim_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    text:SetTextColor(r or region.color_r, g or region.color_g, b or region.color_b, a or region.color_a);
  end

  function region:GetColor()
    return region.color_r or data.color[1], region.color_g or data.color[2],
      region.color_b or data.color[3], region.color_a or data.color[4];
  end

  region:Color(data.color[1], data.color[2], data.color[3], data.color[4]);

  function region:SetTextHeight(size)
    local fontPath = SharedMedia:Fetch("font", data.font);
    region.text:SetFont(fontPath, size, data.outline);
    region.text:SetTextHeight(size)
  end

  function region:ChangeText(msg)
    self.displayText = msg
    self:ConfigureTextUpdate()
    self:ConfigureSubscribers()
  end

  region.displayText = data.displayText
  region:ConfigureTextUpdate()
  region:ConfigureSubscribers()
  Private.regionPrototype.modifyFinish(parent, region, data);
end

local function validate(data)
  Private.EnforceSubregionExists(data, "subbackground")
end

Private.RegisterRegionType("text", create, modify, default, properties, validate);

-- Fallback region type

local function fallbackmodify(parent, region, data)
  Private.regionPrototype.modify(parent, region, data);
  local text = region.text;

  text:SetFont(STANDARD_TEXT_FONT, data.fontSize, data.outline and "OUTLINE" or nil);
  if text:GetFont() then
    text:SetText(WeakAuras.L["Region type %s not supported"]:format(data.regionType));
  end

  text:ClearAllPoints();
  text:SetPoint("CENTER", region, "CENTER");

  region:SetWidth(text:GetWidth());
  region:SetHeight(text:GetStringHeight());

  region.Update = function() end

  Private.regionPrototype.modifyFinish(parent, region, data);
end

Private.RegisterRegionType("fallback", create, fallbackmodify, default);
