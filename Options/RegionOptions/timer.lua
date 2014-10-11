local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L
  
local function createOptions(id, data)
  local options = {
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
  content:SetPoint("LEFT", mask, "LEFT");
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
  text:SetText("12.0");
  text:SetTextColor(data.color[1], data.color[2], data.color[3], data.color[4]);
  
  text:ClearAllPoints();
  text:SetPoint("CENTER", UIParent, "CENTER");
  content:SetWidth(math.max(text:GetStringWidth(), size));
  content:SetHeight(math.max(text:GetStringHeight(), size));
  text:ClearAllPoints();
  text:SetPoint("CENTER", content, "CENTER");
  
  mask:SetScript("OnScrollRangeChanged", function()
    mask:SetHorizontalScroll(mask:GetHorizontalScrollRange() / 2);
    mask:SetVerticalScroll(mask:GetVerticalScrollRange() / 2);
  end);
end

local function createIcon()
  local data = {
    outline = true,
    color = {1, 0, 0, 1},
    justify = "CENTER",
    font = "Bazooka",
    fontSize = 24
  };
  
  local thumbnail = createThumbnail(UIParent);
  modifyThumbnail(UIParent, thumbnail, data, nil, 36);
  thumbnail.mask:SetPoint("BOTTOMLEFT", thumbnail, "BOTTOMLEFT", 3, 3);
  thumbnail.mask:SetPoint("TOPRIGHT", thumbnail, "TOPRIGHT", -3, -3);
  
  return thumbnail;
end

--Timers are deprecated! Use Texts instead!
--WeakAuras.RegisterRegionOptions("timer", createOptions, createIcon, L["Timer"], createThumbnail, modifyThumbnail, L["Shows the remaining or expended time for an aura or timed event"]);