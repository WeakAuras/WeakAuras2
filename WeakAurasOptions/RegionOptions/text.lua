local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L
  
local function createOptions(id, data)
  local options = {
    displayText = {
      type = "input",
      multiline = true,
      name = L["Display Text"],
      order = 10
    },
    justify = {
      type = "select",
      name = L["Justify"],
      order = 35,
      values = WeakAuras.justify_types
    },
    color = {
      type = "color",
      name = L["Text Color"],
      hasAlpha = true,
      order = 40
    },
    outline = {
      type = "toggle",
      name = L["Outline"],
      order = 42
    },
    font = {
      type = "select",
      dialogControl = "LSM30_Font",
      name = L["Font"],
      order = 45,
      values = AceGUIWidgetLSMlists.font
    },
    fontSize = {
      type = "range",
      name = L["Size"],
      order = 47,
      min = 6,
      max = 25,
      step = 1
    },
    spacer = {
      type = "header",
      name = "",
      order = 50
    }
  };
  options = WeakAuras.AddPositionOptions(options, id, data);
  
  options.width = nil;
  options.height = nil;
  
  return options;
end

local function createThumbnail(parent, fullCreate)
  local borderframe = CreateFrame("FRAME", nil, parent);
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
  
  return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, size)
  local mask, content, text = borderframe.mask, borderframe.content, borderframe.text;
  
  size = size or 28;
  
  local fontPath = SharedMedia:Fetch("font", data.font) or data.font;
  text:SetFont(fontPath, data.fontSize, data.outline and "OUTLINE" or nil);
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

WeakAuras.RegisterRegionOptions("text", createOptions, createIcon, L["Text"], createThumbnail, modifyThumbnail, L["Shows one or more lines of text"]);