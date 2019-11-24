if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local function createOptions(id, data)
  local options = {
    __title = L["Text Settings"],
    __order = 1,
    displayText = {
      type = "input",
      width = WeakAuras.doubleWidth,
      desc = function()
        return L["Dynamic text tooltip"] .. WeakAuras.GetAdditionalProperties(data)
      end,
      multiline = true,
      name = L["Display Text"],
      order = 10,
      get = function()
        return data.displayText;
      end,
      set = function(info, v)
        data.displayText = WeakAuras.ReplaceLocalizedRaidMarkers(v);
        WeakAuras.Add(data);
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.SetIconNames(data);
        WeakAuras.ResetMoverSizer();
      end
    },
    customTextUpdate = {
      type = "select",
      width = WeakAuras.doubleWidth,
      hidden = function() return not WeakAuras.ContainsCustomPlaceHolder(data.displayText); end,
      name = L["Update Custom Text On..."],
      values = WeakAuras.text_check_types,
      order = 36
    },
    -- code editor added below
    progressPrecision = {
      type = "select",
      width = WeakAuras.normalWidth,
      order = 39,
      name = L["Remaining Time Precision"],
      values = WeakAuras.precision_types,
      get = function() return data.progressPrecision or 1 end,
      hidden = function() return not (WeakAuras.ContainsPlaceHolders(data.displayText, "pt"));
      end,
      disabled = function()
        return not WeakAuras.ContainsPlaceHolders(data.displayText, "p");
      end
    },
    totalPrecision = {
      type = "select",
      width = WeakAuras.normalWidth,
      order = 39.5,
      name = L["Total Time Precision"],
      values = WeakAuras.precision_types,
      get = function() return data.totalPrecision or 1 end,
      hidden = function()
        return not (WeakAuras.ContainsPlaceHolders(data.displayText, "pt"));
      end,
      disabled = function()
        return not WeakAuras.ContainsPlaceHolders(data.displayText, "t");
      end
    },
    color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Text Color"],
      hasAlpha = true,
      order = 40
    },
    justify = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Justify"],
      order = 43,
      values = WeakAuras.justify_types
    },
    font = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Font",
      name = L["Font"],
      order = 45,
      values = AceGUIWidgetLSMlists.font
    },
    fontSize = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Size"],
      order = 47,
      min = 6,
      softMax = 72,
      step = 1
    },
    automaticWidth = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Width"],
      order = 47.1,
      values = WeakAuras.text_automatic_width
    },
    fixedWidth = {
      name = L["Width"],
      width = WeakAuras.normalWidth,
      order = 47.2,
      type = "range",
      min = 1,
      softMax = screenWidth,
      bigStep = 1,
      hidden = function() return data.automaticWidth  ~= "Fixed" end
    },
    wordWrap = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Overflow"],
      order = 47.2,
      values = WeakAuras.text_word_wrap,
      hidden = function() return data.automaticWidth  ~= "Fixed" end
    },
    outline = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Outline"],
      order = 48,
      values = WeakAuras.font_flags
    },
    endHeader = {
      type = "header",
      order = 100,
      name = "",
    },
  };

  WeakAuras.AddCodeOption(options, data, L["Custom Function"], "customText", "https://github.com/WeakAuras/WeakAuras2/wiki/Text-Replacements",
                          37, function() return not WeakAuras.ContainsCustomPlaceHolder(data.displayText) end, {"customText"}, false);

  return {
    text = options;
    position = WeakAuras.PositionOptions(id, data, nil, true);
  };
end

local function createThumbnail()
  local borderframe = CreateFrame("FRAME", nil, UIParent);
  borderframe:SetWidth(32);
  borderframe:SetHeight(32);

  local border = borderframe:CreateTexture(nil, "OVERLAY");
  border:SetAllPoints(borderframe);
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

  local mask = CreateFrame("ScrollFrame", nil, borderframe);
  borderframe.mask = mask;
  mask:SetPoint("BOTTOMLEFT", borderframe, "BOTTOMLEFT", 2, 2);
  mask:SetPoint("TOPRIGHT", borderframe, "TOPRIGHT", -2, -2);

  local content = CreateFrame("Frame", nil, mask);
  borderframe.content = content;
  content:SetPoint("CENTER", mask, "CENTER");
  mask:SetScrollChild(content);

  local text = content:CreateFontString(nil, "OVERLAY");
  borderframe.text = text;
  text:SetNonSpaceWrap(true);

  borderframe.values = {};

  return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, size)
  local mask, content, text = borderframe.mask, borderframe.content, borderframe.text;

  size = size or 28;

  local fontPath = SharedMedia:Fetch("font", data.font) or data.font;
  text:SetFont(fontPath, data.fontSize, data.outline and "OUTLINE" or nil);
  text:SetTextHeight(data.fontSize);
  text:SetText(data.displayText);
  text:SetTextColor(data.color[1], data.color[2], data.color[3], data.color[4]);
  text:SetJustifyH(data.justify);

  text:ClearAllPoints();
  text:SetPoint("CENTER", UIParent, "CENTER");
  content:SetWidth(math.max(text:GetStringWidth(), size));
  content:SetHeight(math.max(text:GetStringHeight(), size));
  text:ClearAllPoints();
  text:SetPoint("CENTER", content, "CENTER");

  local function rescroll()
    content:SetWidth(math.max(text:GetStringWidth(), size));
    content:SetHeight(math.max(text:GetStringHeight(), size));
    local xo = 0;
    if(data.justify == "CENTER") then
      xo = mask:GetHorizontalScrollRange() / 2;
    elseif(data.justify == "RIGHT") then
      xo = mask:GetHorizontalScrollRange();
    end
    mask:SetHorizontalScroll(xo);
    mask:SetVerticalScroll(mask:GetVerticalScrollRange() / 2);
  end

  rescroll();
  mask:SetScript("OnScrollRangeChanged", rescroll);

  local function UpdateText()
    local textStr = data.displayText;
    textStr = WeakAuras.ReplacePlaceHolders(textStr, borderframe);
    text:SetText(textStr);
    rescroll();
  end

  function borderframe:SetIcon(path)
    UpdateText();
  end

  function borderframe:SetName(name)
    UpdateText();
  end

  UpdateText();
end

local function createIcon()
  local data = {
    outline = true,
    color = {1, 1, 0, 1},
    justify = "CENTER",
    font = "Friz Quadrata TT",
    fontSize = 12,
    displayText = "World\nof\nWarcraft";
  };

  local thumbnail = createThumbnail(UIParent);
  modifyThumbnail(UIParent, thumbnail, data);
  thumbnail.mask:SetPoint("BOTTOMLEFT", thumbnail, "BOTTOMLEFT", 3, 3);
  thumbnail.mask:SetPoint("TOPRIGHT", thumbnail, "TOPRIGHT", -3, -3);

  return thumbnail;
end

local templates = {
  {
    title = L["Default"],
    description = L["Displays a text, works best in combination with other displays"],
    data = {
    };
  }
}

WeakAuras.RegisterRegionOptions("text", createOptions, createIcon, L["Text"], createThumbnail, modifyThumbnail, L["Shows one or more lines of text, which can include dynamic information such as progress or stacks"], templates);
