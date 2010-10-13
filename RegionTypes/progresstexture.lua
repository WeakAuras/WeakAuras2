local SharedMedia = LibStub("LibSharedMedia-3.0");
  
local default = {
  foregroundTexture = "Interface\\PVPFrame\\PVP-Banner-Emblem-3",
  backgroundTexture = "Interface\\PVPFrame\\PVP-Banner-Emblem-3",
  sameTexture = true,
  compress = false,
  blendMode = "BLEND",
  backgroundOffset = 2,
  width = 200,
  height = 200,
  orientation = "VERTICAL",
  inverse = false,
  alpha = 1.0,
  foregroundColor = {1, 1, 1, 1},
  backgroundColor = {0, 0, 0, 0.5},
  textColor = {1, 1, 1, 1},
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  xOffset = 0,
  yOffset = 0,
  font = "Friz Quadrata TT",
  fontSize = 12,
  stickyDuration = false
};

local function create(parent)
  local font = "GameFontHighlight";
  
  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetMinResize(1, 1);
  
  local background = region:CreateTexture(nil, "BACKGROUND");
  region.background = background;
  
  local foreground = region:CreateTexture(nil, "ART");
  region.foreground = foreground;
  
  region.duration = 0;
  region.expirationTime = math.huge;
  
  return region;
end

local function modify(parent, region, data)
  local bar, background, foreground, timer = region.bar, region.background, region.foreground, region.timer;
  
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  foreground:SetWidth(data.width);
  foreground:SetHeight(data.height);
  
  region:ClearAllPoints();
  region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
  region:SetAlpha(data.alpha);
  
  local fontPath = SharedMedia:Fetch("font", data.font);
  
  background:SetTexture(data.sameTexture and data.foregroundTexture or data.backgroundTexture);
  background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  background:SetBlendMode(data.blendMode);
  
  foreground:SetTexture(data.foregroundTexture);
  foreground:SetVertexColor(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);
  foreground:SetBlendMode(data.blendMode);
  
  background:ClearAllPoints();
  foreground:ClearAllPoints();
  background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", -1 * data.backgroundOffset, -1 * data.backgroundOffset);
  background:SetPoint("TOPRIGHT", region, "TOPRIGHT", data.backgroundOffset, data.backgroundOffset);
  
  local function orientHorizontalInverse()
    foreground:ClearAllPoints();
    foreground:SetPoint("RIGHT", region, "RIGHT");
    region.orientation = "HORIZONTAL_INVERSE";
    if(data.compress) then
      function region:SetValue(progress)
        if(region.mirror_v) then
          foreground:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          foreground:SetWidth(region:GetWidth() * progress);
          background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
        else
          foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
          foreground:SetWidth(region:GetWidth() * progress);
          background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        end
      end
    else
      function region:SetValue(progress)
        if(region.mirror_v) then
          foreground:SetTexCoord(1-progress,1 , 1-progress,0 , 1,1 , 1,0);
          foreground:SetWidth(region:GetWidth() * progress);
          background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
        else
          foreground:SetTexCoord(1-progress,0 , 1-progress,1 , 1,0 , 1,1);
          foreground:SetWidth(region:GetWidth() * progress);
          background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        end
      end
    end
  end
  local function orientHorizontal()
    foreground:ClearAllPoints();
    foreground:SetPoint("LEFT", region, "LEFT");
    region.orientation = "HORIZONTAL";
    if(data.compress) then
      function region:SetValue(progress)
        if(region.mirror_v) then
          foreground:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          foreground:SetWidth(region:GetWidth() * progress);
          background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
        else
          foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
          foreground:SetWidth(region:GetWidth() * progress);
          background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        end
      end
    else
      function region:SetValue(progress)
        if(region.mirror_v) then
          foreground:SetTexCoord(0,1 , 0,0 , progress,1 , progress,0);
          foreground:SetWidth(region:GetWidth() * progress);
          background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
        else
          foreground:SetTexCoord(0,0 , 0,1 , progress,0 , progress,1);
          foreground:SetWidth(region:GetWidth() * progress);
          background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        end
      end
    end
  end
  local function orientVerticalInverse()
    foreground:ClearAllPoints();
    foreground:SetPoint("TOP", region, "TOP");
    region.orientation = "VERTICAL_INVERSE";
    if(data.compress) then
      function region:SetValue(progress)
        if(region.mirror_h) then
          foreground:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
          foreground:SetHeight(region:GetHeight() * progress);
          background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
        else
          foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
          foreground:SetHeight(region:GetHeight() * progress);
          background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        end
      end
    else
      function region:SetValue(progress)
        if(region.mirror_h) then
          foreground:SetTexCoord(1,0 , 1,progress , 0,0 , 0,progress);
          foreground:SetHeight(region:GetHeight() * progress);
          background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
        else
          foreground:SetTexCoord(0,0 , 0,progress , 1,0 , 1,progress);
          foreground:SetHeight(region:GetHeight() * progress);
          background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        end
      end
    end
  end
  local function orientVertical()
    foreground:ClearAllPoints();
    foreground:SetPoint("BOTTOM", region, "BOTTOM");
    region.orientation = "VERTICAL";
    if(data.compress) then
      function region:SetValue(progress)
        if(region.mirror_h) then
          foreground:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
          foreground:SetHeight(region:GetHeight() * progress);
          background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
        else
          foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
          foreground:SetHeight(region:GetHeight() * progress);
          background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        end
      end
    else
      function region:SetValue(progress)
        if(region.mirror_h) then
          foreground:SetTexCoord(1,1-progress , 1,1 , 0,1-progress , 0,1);
          foreground:SetHeight(region:GetHeight() * progress);
          background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
        else
          foreground:SetTexCoord(0,1-progress , 0,1 , 1,1-progress , 1,1);
          foreground:SetHeight(region:GetHeight() * progress);
          background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        end
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
  
  function region:Scale(scalex, scaley)
    if(scalex < 0) then
      region.mirror_h = true;
      scalex = scalex * -1;
      if(data.orientation == "HORIZONTAL") then
        if(region.orientation ~= "HORIZONTAL_INVERSE") then
          orientHorizontalInverse();
        end
      elseif(data.orientation == "HORIZONTAL_INVERSE") then
        if(region.orientation ~= "HORIZONTAL") then
          orientHorizontal();
        end
      end
    else
      region.mirror_h = nil;
      if(data.orientation == "HORIZONTAL") then
        if(region.orientation ~= "HORIZONTAL") then
          orientHorizontal();
        end
      elseif(data.orientation == "HORIZONTAL_INVERSE") then
        if(region.orientation ~= "HORIZONTAL_INVERSE") then
          orientHorizontalInverse();
        end
      end
    end
    if(scaley < 0) then
      region.mirror_v = true;
      scaley = scaley * -1;
      if(data.orientation == "VERTICAL") then
        if(region.orientation ~= "VERTICAL_INVERSE") then
          orientVerticalInverse();
        end
      elseif(data.orientation == "VERTICAL_INVERSE") then
        if(region.orientation ~= "VERTICAL") then
          orientVertical();
        end
      end
    else
      region.mirror_v = nil;
      if(data.orientation == "VERTICAL") then
        if(region.orientation ~= "VERTICAL") then
          orientVertical();
        end
      elseif(data.orientation == "VERTICAL_INVERSE") then
        if(region.orientation ~= "VERTICAL_INVERSE") then
          orientVerticalInverse();
        end
      end
    end
    
    region:SetWidth(data.width * scalex);
    region:SetHeight(data.height * scaley);
    foreground:SetWidth(data.width * scalex);
    foreground:SetHeight(data.height * scaley);
    background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", -1 * scalex * data.backgroundOffset, -1 * scaley * data.backgroundOffset);
    background:SetPoint("TOPRIGHT", region, "TOPRIGHT", scalex * data.backgroundOffset, scaley * data.backgroundOffset);
  end
  
  local function UpdateTime()
    local remaining = region.expirationTime - GetTime();
    local progress = remaining / region.duration;
    
    if(data.inverse) then
      progress = 1 - progress;
    end
    progress = progress > 0.0001 and progress or 0.0001;
    region:SetValue(progress);
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
    region:SetValue(progress);
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
        region:SetValue(1);
        region:SetScript("OnUpdate", nil);
      end
    end
  end
end

WeakAuras.RegisterRegionType("progresstexture", create, modify, default);