local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

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
  font = "Friz Quadrata TT",
  fontSize = 12,
  frameStrata = 1,
  customTextUpdate = "update",
  automaticWidth = "Auto",
  fixedWidth = 200,
  wordWrap = "WordWrap"
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
  region.progressPrecision = data.progressPrecision;
  region.totalPrecision = data.totalPrecision;

  local fontPath = SharedMedia:Fetch("font", data.font);
  text:SetFont(fontPath, data.fontSize, data.outline);
  if not text:GetFont() then -- Font invalid, set the font but keep the setting
    text:SetFont(STANDARD_TEXT_FONT, data.fontSize, data.outline);
  end
  if text:GetFont() then
    WeakAuras.regionPrototype.SetTextOnText(text, data.displayText);
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
        text:SetText(textStr);
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
          WeakAuras.regionPrototype.SetTextOnText(text, textStr);
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

  local UpdateText;
  if (data.displayText:find('%%')) then
    UpdateText = function()
      local textStr = data.displayText;
      textStr = WeakAuras.ReplacePlaceHolders(textStr, region);
      if (textStr == nil or textStr == "") then
        textStr = " ";
      end

      SetText(textStr)
    end
  else
    UpdateText = function() end
  end

  local customTextFunc = nil
  if(WeakAuras.ContainsCustomPlaceHolder(data.displayText) and data.customText) then
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

  function region:SetValue()
    UpdateText();
  end

  function region:SetTime()
    UpdateText();
  end

  function region:TimerTick()
    UpdateText();
  end

  function region:SetStacks(count)
    if(count and count > 0) then
      region.values.stacks = count;
    else
      region.values.stacks = 0;
    end
    UpdateText();
  end

  function region:SetIcon(path)
    local icon = (
      region.useAuto
      and path
      and path ~= ""
      and path
      or data.displayIcon
      or "Interface\\Icons\\INV_Misc_QuestionMark"
      );
    region.values.icon = "|T"..icon..":12:12:0:0:64:64:4:60:4:60|t";
    UpdateText();
  end

  function region:SetTextHeight(size)
    local fontPath = SharedMedia:Fetch("font", data.font);
    region.text:SetFont(fontPath, size, data.outline);
    region.text:SetTextHeight(size)
  end

  function region:SetName(name)
    region.values.name = name or data.id;
    UpdateText();
  end
  if (data.displayText:find('%%')) then
    UpdateText();
  else
    SetText(data.displayText);
  end
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
end

WeakAuras.RegisterRegionType("fallback", create, fallbackmodify, default);
