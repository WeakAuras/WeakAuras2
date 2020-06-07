if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local indentWidth = 0.15
local hiddenFontExtra = function()
  return WeakAuras.IsCollapsed("text", "text", "fontflags", true)
end

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
        WeakAuras.ClearAndUpdateOptions(data.id)
        WeakAuras.UpdateThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end,
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
      order = 46,
      min = 6,
      softMax = 72,
      step = 1
    },
    color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Text Color"],
      hasAlpha = true,
      order = 47
    },

    fontFlagsDescription = {
      order = 48,
      width = WeakAuras.doubleWidth,
      type = "execute",
      control = "WeakAurasExpandSmall",
      name = function()
        local textFlags = WeakAuras.font_flags[data.outline]
        local color = format("%02x%02x%02x%02x",
                             data.shadowColor[4] * 255, data.shadowColor[1] * 255,
                             data.shadowColor[2] * 255, data.shadowColor[3]*255)

        local textJustify = ""
        if data.justify == "CENTER" then

        elseif data.justify == "LEFT" then
          textJustify = " " .. L["and aligned left"]
        elseif data.justify == "RIGHT" then
          textJustify = " " ..  L["and aligned right"]
        end

        local textWidth = ""
        if data.automaticWidth == "Fixed" then
          local wordWarp = ""
          if data.wordWrap == "WordWrap" then
            wordWarp = L["wrapping"]
          else
            wordWarp = L["eliding"]
          end
          textWidth = " "..L["and with width |cFFFF0000%s|r and %s"]:format(data.fixedWidth, wordWarp)
        end

        local secondline = L["|cFFffcc00Font Flags:|r |cFFFF0000%s|r and shadow |c%sColor|r with offset |cFFFF0000%s/%s|r%s%s"]:format(textFlags, color, data.shadowXOffset, data.shadowYOffset, textJustify, textWidth)

        return secondline
      end,
      func = function(info, button)
        local collapsed = WeakAuras.IsCollapsed("text", "text", "fontflags", true)
        WeakAuras.SetCollapsed("text", "text", "fontflags", not collapsed)
      end,
      image = function()
        local collapsed = WeakAuras.IsCollapsed("text", "text", "fontflags", true)
        return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
      end,
      imageWidth = 24,
      imageHeight = 24
    },

    text_font_space = {
      type = "description",
      name = "",
      order = 48.1,
      hidden = hiddenFontExtra,
      width = indentWidth
    },
    outline = {
      type = "select",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Outline"],
      order = 48.2,
      values = WeakAuras.font_flags,
      hidden = hiddenFontExtra
    },
    shadowColor = {
      type = "color",
      hasAlpha = true,
      width = WeakAuras.normalWidth,
      name = L["Shadow Color"],
      order = 48.3,
      hidden = hiddenFontExtra
    },

    text_font_space3 = {
      type = "description",
      name = "",
      order = 48.4,
      hidden = hiddenFontExtra,
      width = indentWidth
    },
    shadowXOffset = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Shadow X Offset"],
      softMin = -15,
      softMax = 15,
      bigStep = 1,
      order = 48.5,
      hidden = hiddenFontExtra
    },
    shadowYOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Shadow Y Offset"],
      softMin = -15,
      softMax = 15,
      bigStep = 1,
      order = 48.6,
      hidden = hiddenFontExtra
    },

    text_font_space4 = {
      type = "description",
      name = "",
      order = 48.7,
      hidden = hiddenFontExtra,
      width = indentWidth
    },
    justify = {
      type = "select",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Justify"],
      order = 48.8,
      values = WeakAuras.justify_types,
      hidden = hiddenFontExtra,
    },
    text_font_space55 = {
      type = "description",
      name = "",
      order = 48.85,
      hidden = hiddenFontExtra,
      width = WeakAuras.normalWidth
    },

    text_font_space5 = {
      type = "description",
      name = "",
      order = 48.9,
      hidden = hiddenFontExtra,
      width = indentWidth
    },
    automaticWidth = {
      type = "select",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Width"],
      order = 49,
      values = WeakAuras.text_automatic_width,
      hidden = hiddenFontExtra,
    },
    fixedWidth = {
      name = L["Width"],
      width = WeakAuras.normalWidth,
      order = 49.1,
      type = "range",
      min = 1,
      softMax = screenWidth,
      bigStep = 1,
      hidden = function() return hiddenFontExtra() or data.automaticWidth ~= "Fixed" end
    },
    text_font_space7 = {
      type = "description",
      name = "",
      order = 49.3,
      width = indentWidth,
      hidden = function() return hiddenFontExtra() or data.automaticWidth ~= "Fixed" end
    },
    wordWrap = {
      type = "select",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Overflow"],
      order = 49.4,
      values = WeakAuras.text_word_wrap,
      hidden = function() return hiddenFontExtra() or data.automaticWidth ~= "Fixed" end
    },

    endHeader = {
      type = "header",
      order = 100,
      name = "",
    },
  };

  WeakAuras.commonOptions.AddCodeOption(options, data, L["Custom Function"], "customText", "https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Code-Blocks#custom-text",
                          37, function() return not WeakAuras.ContainsCustomPlaceHolder(data.displayText) end, {"customText"}, false);

  -- Add Text Format Options
  local input = data.displayText
  local hidden = function()
    return WeakAuras.IsCollapsed("format_option", "text", "displayText", true)
  end

  local setHidden = function(hidden)
    WeakAuras.SetCollapsed("format_option", "text", "displayText", hidden)
  end

  local get = function(key)
    return data["displayText_format_" .. key]
  end

  local order = 12
  local function addOption(key, option)
    option.order = order
    order = order + 0.01
    if option.reloadOptions then
      option.reloadOptions = nil
      option.set = function(info, v)
        data["displayText_format_" .. key] = v
        WeakAuras.Add(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
      end
    end
    options["displayText_format_" .. key] = option
  end

  WeakAuras.AddTextFormatOption(input, true, get, addOption, hidden, setHidden)
  addOption("footer", {
    type = "description",
    name = "",
    width = WeakAuras.doubleWidth,
    hidden = hidden
  })

  return {
    text = options;
    position = WeakAuras.commonOptions.PositionOptions(id, data, nil, true);
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
