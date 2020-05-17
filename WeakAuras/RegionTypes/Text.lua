if not WeakAuras.IsCorrectVersion() then return end

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
  shadowYOffset = -1,
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
  }
}

WeakAuras.regionPrototype.AddProperties(properties, default);

local function GetProperties(data)
  return properties;
end

local function create(parent)
  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);

  local text = region:CreateFontString(nil, "OVERLAY");
  region.text = text;
  text:SetWordWrap(true);
  text:SetNonSpaceWrap(true);

  region.values = {};
  region.duration = 0;
  region.expirationTime = math.huge;

  WeakAuras.regionPrototype.create(region);

  return region;
end

local function modify(parent, region, data)
  WeakAuras.regionPrototype.modify(parent, region, data);
  local text = region.text;

  region.useAuto = WeakAuras.CanHaveAuto(data);

  local fontPath = SharedMedia:Fetch("font", data.font);
  text:SetFont(fontPath, data.fontSize, data.outline);
  if not text:GetFont() then -- Font invalid, set the font but keep the setting
    text:SetFont(STANDARD_TEXT_FONT, data.fontSize, data.outline);
  end
  if text:GetFont() then
    text:SetText("")
    text:SetText(WeakAuras.ReplaceRaidMarkerSymbols(data.displayText));
  end
  text.displayText = data.displayText;
  text:SetJustifyH(data.justify);

  text:ClearAllPoints();
  text:SetPoint("CENTER", UIParent, "CENTER");

  region.width = text:GetWidth();
  region.height = text:GetStringHeight();
  region:SetWidth(region.width);
  region:SetHeight(region.height);

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
        region.height = text:GetStringHeight();
        region:SetHeight(region.height);
        if(data.parent and WeakAuras.regions[data.parent].region.PositionChildren) then
          WeakAuras.regions[data.parent].region:PositionChildren();
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
      end
      local width = text:GetWidth();
      local height = text:GetStringHeight();
      if(width ~= region.width or height ~= region.height ) then
        region.width = width;
        region.height = height;
        region:SetWidth(region.width);
        region:SetHeight(region.height);
        if(data.parent and WeakAuras.regions[data.parent].region.PositionChildren) then
          WeakAuras.regions[data.parent].region:PositionChildren();
        end
      end
    end
  end

  local UpdateText
  if WeakAuras.ContainsAnyPlaceHolders(data.displayText) then
    local getter = function(key, default)
      local fullKey = "displayText_format_" .. key
      if (data[fullKey] == nil) then
        data[fullKey] = default
      end
      return data[fullKey]
    end
    local formatters = WeakAuras.CreateFormatters(data.displayText, getter)
    UpdateText = function()
      local textStr = data.displayText;
      textStr = WeakAuras.ReplacePlaceHolders(textStr, region, nil, false, formatters);
      if (textStr == nil or textStr == "") then
        textStr = " ";
      end

      SetText(textStr)
    end
  end

  local customTextFunc = nil
  if(WeakAuras.ContainsCustomPlaceHolder(data.displayText) and data.customText) then
    customTextFunc = WeakAuras.LoadFunction("return "..data.customText, region.id, "custom text")
  end

  local Update
  if customTextFunc then
    if UpdateText then
      Update = function()
        region.values.custom = WeakAuras.RunCustomTextFunc(region, customTextFunc)
        UpdateText()
      end
    end
  else
    Update = UpdateText or function() end
  end

  local TimerTick
  if WeakAuras.ContainsPlaceHolders(data.displayText, "p") then
    TimerTick = UpdateText
  end

  local FrameTick
  if customTextFunc and data.customTextUpdate == "update" then
    FrameTick = function()
      region.values.custom = WeakAuras.RunCustomTextFunc(region, customTextFunc)
      UpdateText()
    end
  end

  region.Update = Update
  region.FrameTick = FrameTick
  region.TimerTick = TimerTick

  if not UpdateText then
    SetText(data.displayText);
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

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);
end

WeakAuras.RegisterRegionType("text", create, modify, default, GetProperties);

-- Fallback region type

local function fallbackmodify(parent, region, data)
  WeakAuras.regionPrototype.modify(parent, region, data);
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

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);
end

WeakAuras.RegisterRegionType("fallback", create, fallbackmodify, default);
