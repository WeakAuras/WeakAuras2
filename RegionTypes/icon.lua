local SharedMedia = LibStub("LibSharedMedia-3.0");
  
local default = {
  icon = true,
  auto = true,
  inverse = false,
  width = 64,
  height = 64,
  alpha = 1.0,
  textColor = {1, 1, 1, 1},
  stacksPoint = "BOTTOMRIGHT",
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
  
  local icon = region:CreateTexture(nil, "BACKGROUND");
  region.icon = icon;
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
  icon:SetAllPoints(region);
  
  local cooldown = CreateFrame("COOLDOWN", nil, region);
  region.cooldown = cooldown;
  cooldown:SetAllPoints(icon);
  
  local stacks = region:CreateFontString(nil, "OVERLAY");
  region.stacks = stacks;
  
  region.duration = 0;
  region.expirationTime = math.huge;
  
  return region;
end

local function modify(parent, region, data)
  local icon, cooldown, stacks = region.icon, region.cooldown, region.stacks;
  
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  
  region:ClearAllPoints();
  region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
  region:SetAlpha(data.alpha);
  
  local fontPath = SharedMedia:Fetch("font", data.font);
  local sxo, syo = 0, 0;
  if(data.stacksPoint:find("LEFT")) then
    sxo = data.width / 10;
  elseif(data.stacksPoint:find("RIGHT")) then
    sxo = data.width / -10;
  end
  if(data.stacksPoint:find("BOTTOM")) then
    syo = data.height / 10;
  elseif(data.stacksPoint:find("TOP")) then
    syo = data.height / -10;
  end
  stacks:ClearAllPoints();
  stacks:SetPoint(data.stacksPoint, icon, data.stacksPoint, sxo, syo);
  stacks:SetFont(fontPath, data.fontSize, "OUTLINE");
  stacks:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);
  
  cooldown:SetReverse(not data.inverse);
  
  function region:SetStacks(count)
    if(count and count > 0) then
      stacks:SetText(count);
    else
      stacks:SetText("");
    end
  end
  
  function region:SetIcon(path)
    local success = icon:SetTexture(data.auto and path or data.displayIcon) and (data.auto and path or data.displayIcon);
    if not(success) then
      icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    end
  end
  
  function region:Scale(scalex, scaley)
    local mirror_h, mirror_v;
    if(scalex < 0) then
      mirror_h = true;
      scalex = scalex * -1;
    end
    region:SetWidth(data.width * scalex);
    if(scaley < 0) then
      mirror_v = true;
      scaley = scaley * -1;
    end
    region:SetHeight(data.height * scaley);
    
    if(mirror_h) then
      if(mirror_v) then
        icon:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
      else
        icon:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
      end
    else
      if(mirror_v) then
        icon:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
      else
        icon:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
      end
    end
  end
  
  if(data.cooldown and WeakAuras.CanHaveDuration(data)) then
    cooldown:Show();
    function region:SetDurationInfo(duration, expirationTime, customValue)
      if(duration <= 0.01 or duration > region.duration or not data.stickyDuration) then
        region.duration = duration;
      end
      if(customValue) then
        cooldown:Show();
        cooldown:SetCooldown(expirationTime - region.duration, region.duration);
      else
        cooldown:Hide();
      end
    end
  else
    cooldown:Hide();
    function region:SetDurationInfo()
      --do nothing
    end
  end
end

WeakAuras.RegisterRegionType("icon", create, modify, default);