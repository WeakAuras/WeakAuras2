local SharedMedia = LibStub("LibSharedMedia-3.0");
  
local default = {
  icon = true,
  auto = true,
  timer = true,
  text = true,
  texture = "Blizzard",
  width = 200,
  height = 15,
  orientation = "HORIZONTAL",
  inverse = false,
  alpha = 1.0,
  barColor = {1, 0, 0, 1},
  backgroundColor = {0, 0, 0, 0.5},
  textColor = {1, 1, 1, 1},
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  xOffset = 0,
  yOffset = 0,
  font = "Friz Quadrata TT",
  fontSize = 12,
  stickyDuration = false,
  icon_side = "RIGHT",
  stacks = true
};

local function create(parent)
  local font = "GameFontHighlight";
  
  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetMinResize(1, 1);
  
  local bar = CreateFrame("FRAME", nil, region);
  region.bar = bar;
  
  local background = bar:CreateTexture(nil, "BACKGROUND");
  region.background = background;
  
  local texture = bar:CreateTexture(nil, "OVERLAY");
  region.texture = texture;
  texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT");
  texture:SetPoint("TOPLEFT", bar, "TOPLEFT");
  
  local timer = bar:CreateFontString(nil, "OVERLAY", font);
  region.timer = timer;
  timer:SetText("00:00");
  timer:SetNonSpaceWrap(true);
  
  local text = bar:CreateFontString(nil, "OVERLAY");
  region.text = text;
  text:SetNonSpaceWrap(true);
  
  local icon = region:CreateTexture();
  region.icon = icon;
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
  
  local stacks = bar:CreateFontString(nil, "OVERLAY");
  region.stacks = stacks;
  stacks:ClearAllPoints();
  stacks:SetPoint("CENTER", icon, "CENTER");
  
  region.duration = 0;
  region.expirationTime = math.huge;
  
  return region;
end

local function modify(parent, region, data)
  local bar, background, texture, timer, text, icon, stacks = region.bar, region.background, region.texture, region.timer, region.text, region.icon, region.stacks;
  
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  
  region:ClearAllPoints();
  region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
  region:SetAlpha(data.alpha);
  
  local texturePath = SharedMedia:Fetch("statusbar", data.texture);
  local fontPath = SharedMedia:Fetch("font", data.font);
  
  background:SetTexture(texturePath);
  background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  
  texture:SetTexture(texturePath);
  texture:SetVertexColor(data.barColor[1], data.barColor[2], data.barColor[3], data.barColor[4]);
  
  text:SetFont(fontPath, data.fontSize);
  text:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);
  
  timer:SetFont(fontPath, data.fontSize);
  timer:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);
  
  local iconsize = math.min(data.height, data.width);
  icon:SetWidth(iconsize);
  icon:SetHeight(iconsize);
  
  stacks:SetFont(fontPath, data.fontSize, "OUTLINE");
  stacks:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);
  
  local function orientHorizontalInverse()
    icon:ClearAllPoints();
    texture:ClearAllPoints();
    background:ClearAllPoints();
    bar:ClearAllPoints();
    text:ClearAllPoints();
    timer:ClearAllPoints();
    region.orientation = "HORIZONTAL_INVERSE";
    timer:SetWidth(0);
    text:SetWidth(0);
    if(data.icon) then
      if(data.icon_side == "LEFT") then
        icon:SetPoint("LEFT", region, "LEFT");
        background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        background:SetPoint("TOPLEFT", icon, "TOPRIGHT");
        bar:SetPoint("TOPLEFT", icon, "TOPRIGHT");
      else
        icon:SetPoint("RIGHT", region, "RIGHT");
        background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
        bar:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
        background:SetPoint("TOPRIGHT", icon, "TOPLEFT");
        bar:SetPoint("TOPRIGHT", icon, "TOPLEFT");
      end
    else
      background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      background:SetPoint("TOPLEFT", region, "TOPLEFT");
      bar:SetPoint("TOPLEFT", region, "TOPLEFT");
    end
    text:SetPoint("RIGHT", bar, "RIGHT", -2, 0);
    timer:SetPoint("LEFT", bar, "LEFT", 2, 0);
    texture:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT");
    texture:SetPoint("TOPRIGHT", bar, "TOPRIGHT");
    function bar:SetValue(progress)
      if(region.mirror_v) then
        texture:SetTexCoord(progress,1 , progress,0 , 0,1 , 0,0);
        texture:SetWidth(bar:GetWidth() * progress);
        background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
      else
        texture:SetTexCoord(progress,0 , progress,1 , 0,0 , 0,1);
        texture:SetWidth(bar:GetWidth() * progress);
        background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
      end
    end
  end
  local function orientHorizontal()
    icon:ClearAllPoints();
    texture:ClearAllPoints();
    background:ClearAllPoints();
    bar:ClearAllPoints();
    text:ClearAllPoints();
    timer:ClearAllPoints();
    region.orientation = "HORIZONTAL";
    timer:SetWidth(0);
    text:SetWidth(0);
    if(data.icon) then
      if(data.icon_side == "LEFT") then
        icon:SetPoint("LEFT", region, "LEFT");
        background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        background:SetPoint("TOPLEFT", icon, "TOPRIGHT");
        bar:SetPoint("TOPLEFT", icon, "TOPRIGHT");
      else
        icon:SetPoint("RIGHT", region, "RIGHT");
        background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
        bar:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
        background:SetPoint("TOPRIGHT", icon, "TOPLEFT");
        bar:SetPoint("TOPRIGHT", icon, "TOPLEFT");
      end
    else
      background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      background:SetPoint("TOPLEFT", region, "TOPLEFT");
      bar:SetPoint("TOPLEFT", region, "TOPLEFT");
    end
    text:SetPoint("LEFT", bar, "LEFT", 2, 0);
    timer:SetPoint("RIGHT", bar, "RIGHT", -2, 0);
    texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT");
    texture:SetPoint("TOPLEFT", bar, "TOPLEFT");
    function bar:SetValue(progress)
      if(region.mirror_v) then
        texture:SetTexCoord(0,1 , 0,0 , progress,1 , progress,0);
        texture:SetWidth(bar:GetWidth() * progress);
        background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
      else
        texture:SetTexCoord(0,0 , 0,1 , progress,0 , progress,1);
        texture:SetWidth(bar:GetWidth() * progress);
        background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
      end
    end
  end
  local function orientVerticalInverse()
    icon:ClearAllPoints();
    texture:ClearAllPoints();
    background:ClearAllPoints();
    bar:ClearAllPoints();
    text:ClearAllPoints();
    timer:ClearAllPoints();
    region.orientation = "VERTICAL_INVERSE";
    timer:SetWidth(data.height);
    text:SetWidth(data.height);
    if(data.icon) then
      if(data.icon_side == "LEFT") then
        icon:SetPoint("TOP", region, "TOP");
        background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        background:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
        bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
      else
        icon:SetPoint("BOTTOM", region, "BOTTOM");
        background:SetPoint("TOPRIGHT", region, "TOPRIGHT");
        bar:SetPoint("TOPRIGHT", region, "TOPRIGHT");
        background:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
        bar:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
      end
    else
      background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      background:SetPoint("TOPLEFT", region, "TOPLEFT");
      bar:SetPoint("TOPLEFT", region, "TOPLEFT");
    end
    text:SetPoint("TOP", bar, "TOP", 0, -2);
    timer:SetPoint("BOTTOM", bar, "BOTTOM", 0, 2);
    texture:SetPoint("TOPLEFT", bar, "TOPLEFT");
    texture:SetPoint("TOPRIGHT", bar, "TOPRIGHT");
    function bar:SetValue(progress)
      if(region.mirror_h) then
        texture:SetTexCoord(0,1 , progress,1 , 0,0 , progress,0);
        texture:SetHeight(bar:GetHeight() * progress);
        background:SetTexCoord(0,1 , 1,1 , 0,0 , 1,0);
      else
        texture:SetTexCoord(0,0 , progress,0 , 0,1 , progress,1);
        texture:SetHeight(bar:GetHeight() * progress);
        background:SetTexCoord(0,0 , 1,0 , 0,1 , 1,1);
      end
    end
  end
  local function orientVertical()
    icon:ClearAllPoints();
    texture:ClearAllPoints();
    background:ClearAllPoints();
    bar:ClearAllPoints();
    text:ClearAllPoints();
    timer:ClearAllPoints();
    region.orientation = "VERTICAL";
    timer:SetWidth(data.height);
    text:SetWidth(data.height);
    if(data.icon) then
      if(data.icon_side == "LEFT") then
        icon:SetPoint("TOP", region, "TOP");
        background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        background:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
        bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
      else
        icon:SetPoint("BOTTOM", region, "BOTTOM");
        background:SetPoint("TOPRIGHT", region, "TOPRIGHT");
        bar:SetPoint("TOPRIGHT", region, "TOPRIGHT");
        background:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
        bar:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
      end
    else
      background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
      background:SetPoint("TOPLEFT", region, "TOPLEFT");
      bar:SetPoint("TOPLEFT", region, "TOPLEFT");
    end
    text:SetPoint("BOTTOM", bar, "BOTTOM", 0, 2);
    timer:SetPoint("TOP", bar, "TOP", 0, -2);
    texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT");
    texture:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT");
    function bar:SetValue(progress)
      if(region.mirror_h) then
        texture:SetTexCoord(progress,1 , 0,1 , progress,0 , 0,0);
        texture:SetHeight(bar:GetHeight() * progress);
        background:SetTexCoord(1,1 , 0,1 , 1,0 , 0,0);
      else
        texture:SetTexCoord(progress,0 , 0,0 , progress,1 , 0,1);
        texture:SetHeight(bar:GetHeight() * progress);
        background:SetTexCoord(1,0 , 0,0 , 1,1 , 0,1);
      end
    end
  end
  
  if(data.orientation == "HORIZONTAL_INVERSE") then
    orientHorizontalInverse();
  elseif(data.orientation == "HORIZONTAL") then
    orientHorizontal();
  elseif(data.orientation == "VERTICAL_INVERSE") then
    orientVerticalInverse();
  elseif(data.orientation == "VERTICAL") then
    orientVertical();
  end
  
  function region:SetStacks(count)
    if(count and count > 0) then
      stacks:SetText(count);
    else
      stacks:SetText("");
    end
  end
  
  function region:Scale(scalex, scaley)
    local icon_mirror_h, icon_mirror_v;
    if(scalex < 0) then
      icon_mirror_h = true;
      scalex = scalex * -1;
      if(data.orientation == "HORIZONTAL") then
        if(region.orientation ~= "HORIZONTAL_INVERSE") then
          orientHorizontalInverse();
        end
      elseif(data.orientation == "HORIZONTAL_INVERSE") then
        if(region.orientation ~= "HORIZONTAL") then
          orientHorizontal();
        end
      else
        region.mirror_h = true;
      end
    else
      if(data.orientation == "HORIZONTAL") then
        if(region.orientation ~= "HORIZONTAL") then
          orientHorizontal();
        end
      elseif(data.orientation == "HORIZONTAL_INVERSE") then
        if(region.orientation ~= "HORIZONTAL_INVERSE") then
          orientHorizontalInverse();
        end
      else
        region.mirror_h = false;
      end
    end
    region:SetWidth(data.width * scalex);
    icon:SetWidth(iconsize * scalex);
    if(scaley < 0) then
      icon_mirror_v = true;
      scaley = scaley * -1;
      if(data.orientation == "VERTICAL") then
        if(region.orientation ~= "VERTICAL_INVERSE") then
          orientVerticalInverse();
        end
      elseif(data.orientation == "VERTICAL_INVERSE") then
        if(region.orientation ~= "VERTICAL") then
          orientVertical();
        end
      else
        region.mirror_v = true;
      end
    else
      if(data.orientation == "VERTICAL") then
        if(region.orientation ~= "VERTICAL") then
          orientVertical();
        end
      elseif(data.orientation == "VERTICAL_INVERSE") then
        if(region.orientation ~= "VERTICAL_INVERSE") then
          orientVerticalInverse();
        end
      else
        region.mirror_v = false;
      end
    end
    region:SetHeight(data.height * scaley);
    icon:SetHeight(iconsize * scaley);
  end
  
  if(data.timer) then
    timer:Show();
  else
    timer:Hide();
  end
  if(data.icon) then
    function region:SetIcon(path)
      icon:SetTexture(
        WeakAuras.CanHaveAuto(data)
        and data.auto
        and path ~= ""
        and path
        or data.displayIcon
        or "Interface\\Icons\\INV_Misc_QuestionMark"
      )
    end
    if(data.stacks) then
      stacks:Show();
    else
      stacks:Hide();
    end
    icon:Show();
  else
    stacks:Hide();
    icon:Hide();
  end
  if(data.text) then
    text:Show();
  else
    text:Hide();
  end
  
  function region:SetName(name)
    text:SetText((WeakAuras.CanHaveAuto(data) and data.auto and name or data.displayText) or data.id);
  end
  
  local function UpdateTime()
    local remaining = region.expirationTime - GetTime();
    local progress = remaining / region.duration;
    
    if(data.inverse) then
      progress = 1 - progress;
    end
    progress = progress > 0.0001 and progress or 0.0001;
    bar:SetValue(progress);
    
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
    timer:SetText(remainingStr);
  end
  
  local function UpdateValue(value, total)
    local progress = 1
    if(total > 0) then
      progress = value / total;
    end
    if(data.inverse) then
      progress = 1 - progress;
    end
    progress = progress > 0.0001 and progress or 0.0001;
    timer:SetText(string.format("%i", value));
    bar:SetValue(progress);
  end
  
  local function UpdateCustom()
    UpdateValue(region.customValueFunc());
  end
  
  function region:SetDurationInfo(duration, expirationTime, customValue)
    if(duration <= 0.01 or duration > region.duration or not data.stickyDuration) then
      region.duration = duration;
    end
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
        bar:SetValue(1);
        timer:SetText(" ");
        region:SetScript("OnUpdate", nil);
      end
    end
  end
end

WeakAuras.RegisterRegionType("aurabar", create, modify, default);