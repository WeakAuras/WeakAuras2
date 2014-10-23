local SharedMedia = LibStub("LibSharedMedia-3.0");

local default = {
  outline = true,
  color = {1, 1, 1, 1},
  selfPoint = "BOTTOM",
  anchorPoint = "CENTER",
  xOffset = 0,
  yOffset = 0,
  font = "Fonts\\FRIZQT__.ttf",
  fontSize = 12
};

local function create(parent)
  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);

  local text = region:CreateFontString(nil, "OVERLAY");
  region.text = text;
  text:SetNonSpaceWrap(true);

  region.duration = 0;
  region.expirationTime = math.huge;

  return region;
end

local function modify(parent, region, data)
  local text = region.text;

  local fontPath = SharedMedia:Fetch("font", data.font);
  text:SetFont(fontPath, data.fontSize, data.outline and "OUTLINE" or nil);
  text:SetTextHeight(data.fontSize);
  text:SetTextColor(data.color[1], data.color[2], data.color[3], data.color[4]);

  local previousText = text:GetText();
  text:SetText("59:99");
  text:ClearAllPoints();
  text:SetPoint("CENTER", UIParent, "CENTER");
  data.width = text:GetWidth() + 16;
  data.height = text:GetHeight() + 16;
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  text:ClearAllPoints();
  text:SetPoint("CENTER", region, "CENTER");
  text:SetText(previousText or "59:99");

  region:ClearAllPoints();
  region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);

  local function UpdateTime()
    local remaining = region.expirationTime - GetTime();

    local remainingStr = "";
    if(remaining > 60) then
      remainingStr = string.format("%i:", math.floor(remaining / 60));
      remaining = remaining % 60;
      remainingStr = remainingStr..string.format("%02i", remaining);
    elseif(remaining > 0) then
        remainingStr = remainingStr..string.format("%.1f", remaining);
    else
      remainingStr = " ";
    end
    text:SetText(remainingStr);
  end

  local function UpdateValue(value, total)
    text:SetText(string.format("%i", value));
  end

  local function UpdateCustom()
    UpdateValue(region.customValueFunc());
  end

  function region:SetDurationInfo(duration, expirationTime, customValue)
    region.duration = duration;
    region.expirationTime = expirationTime;

    if(customValue) then
      if(type(customValue) == "function") then
        local value, total = customValue();
        if(total > 0 and value < total) then
          region.customValueFunc = customValue;
          region:SetScript("OnUpdate", UpdateCustom);
        else
          UpdateValue(duration, expirationTime);
          region:SetScript("OnUpdate", nil);
        end
      else
        UpdateValue(duration, expirationTime);
        region:SetScript("OnUpdate", nil);
      end
    else
      if(duration > 0.01) then
        region:SetScript("OnUpdate", UpdateTime);
      else
        text:SetText(" ");
        region:SetScript("OnUpdate", nil);
      end
    end
  end
end

--Timers are deprecated! Use Texts instead!
--WeakAuras.RegisterRegionType("timer", create, modify, default);
