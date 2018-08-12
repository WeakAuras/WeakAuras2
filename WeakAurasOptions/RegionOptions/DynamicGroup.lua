local L = WeakAuras.L

local function createOptions(id, data)
  local options = {
    grow = {
      type = "select",
      name = L["Grow"],
      order = 5,
      values = WeakAuras.grow_types
    },
    align = {
      type = "select",
      name = L["Align"],
      order = 10,
      values = WeakAuras.align_types,
      hidden = function() return (data.grow == "LEFT" or data.grow == "RIGHT" or data.grow == "HORIZONTAL" or data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") end,
      disabled = function() return data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE" end
    },
    rotated_align = {
      type = "select",
      name = L["Align"],
      order = 10,
      values = WeakAuras.rotated_align_types,
      hidden = function() return (data.grow == "UP" or data.grow == "DOWN" or data.grow == "VERTICAL" or data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") end,
      get = function() return data.align; end,
      set = function(info, v) data.align = v; WeakAuras.Add(data); end
    },
    constantFactor = {
      type = "select",
      name = L["Constant Factor"],
      order = 10,
      values = WeakAuras.circular_group_constant_factor_types,
      hidden = function() return data.grow ~= "CIRCLE" and data.grow ~= "COUNTERCIRCLE" end
    },
    space = {
      type = "range",
      name = L["Space"],
      order = 15,
      softMin = 0,
      softMax = 300,
      bigStep = 1,
      hidden = function() return (data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") and data.constantFactor == "RADIUS" end
    },
    rotation = {
      type = "range",
      name = L["Rotation"],
      order = 15,
      min = 0,
      max = 360,
      bigStep = 3,
      hidden = function() return data.grow ~= "CIRCLE" and data.grow ~= "COUNTERCIRCLE" end
    },
    stagger = {
      type = "range",
      name = L["Stagger"],
      order = 20,
      min = -50,
      max = 50,
      step = 0.1,
      bigStep = 1,
      hidden = function() return data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE" end
    },
    radius = {
      type = "range",
      name = L["Radius"],
      order = 20,
      softMin = 0,
      softMax = 500,
      bigStep = 1,
      hidden = function() return not((data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") and data.constantFactor == "RADIUS") end
    },
    animate = {
      type = "toggle",
      width = "double",
      name = L["Animated Expand and Collapse"],
      order = 30
    },
    border = {
      type = "select",
      dialogControl = "LSM30_Border",
      name = L["Border"],
      order = 35,
      values = AceGUIWidgetLSMlists.border
    },
    background = {
      type = "select",
      dialogControl = "LSM30_Background",
      name = L["Background"],
      order = 40,
      values = function()
        local list = {};
        for i,v in pairs(AceGUIWidgetLSMlists.background) do
          list[i] = v;
        end
        list["None"] = L["None"];

        return list;
      end
    },
    borderOffset = {
      type = "range",
      name = L["Border Offset"],
      order = 45,
      softMin = 0,
      softMax = 32,
      bigStep = 1
    },
    backgroundInset = {
      type = "range",
      name = L["Background Inset"],
      order = 47,
      softMin = 0,
      softMax = 32,
      bigStep = 1
    },
    sort = {
      type = "select",
      name = L["Sort"],
      order = 48,
      values = WeakAuras.group_sort_types
    },
    hybridPosition = {
      type = "select",
      name = L["Hybrid Position"],
      order = 48.1,
      values = WeakAuras.group_hybrid_position_types,
      hidden = function() return not(data.sort == "hybrid") end,
    },
    hybridSortMode = {
      type = "select",
      name = L["Hybrid Sort Mode"],
      order = 48.2,
      values = WeakAuras.group_hybrid_sort_types,
      hidden = function() return not(data.sort == "hybrid") end,
    },
    sortHybrid = {
      type = "multiselect",
      name = L["Select the auras you always want to be listed first"],
      order = 49,
      hidden = function() return not(data.sort == "hybrid") end,
      values = function()
        return data.controlledChildren
      end,
      get = function(info, index)
        local id = data.controlledChildren[index]
        return data.sortHybridTable and data.sortHybridTable[id] or false;
      end,
      set = function(info, index)
        if not data.sortHybridTable then data.sortHybridTable = {}; end
        local id = data.controlledChildren[index]
        local cur = data.sortHybridTable and data.sortHybridTable[id] or false;
        data.sortHybridTable[id] = not(cur);
      end,
    },
    scale = {
      type = "range",
      name = L["Group Scale"],
      order = 50,
      min = 0.05,
      softMax = 2,
      bigStep = 0.05,
      get = function()
        return data.scale or 1
      end,
      set = function(info, v)
        data.scale = data.scale or 1
        local change = 1 - (v/data.scale)
        data.xOffset = data.xOffset/(1-change)
        data.yOffset = data.yOffset/(1-change)
        data.scale = v
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    },
    spacer = {
      type = "header",
      name = "",
      order = 51
    }
  };

  return {
    dynamicgroup = options,
    position = WeakAuras.PositionOptions(id, data, true, true),
  };
end

local function createThumbnail(parent)
  local borderframe = CreateFrame("FRAME", nil, parent);
  borderframe:SetWidth(32);
  borderframe:SetHeight(32);

  local border = borderframe:CreateTexture(nil, "OVERLAY");
  border:SetAllPoints(borderframe);
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

  local region = CreateFrame("FRAME", nil, borderframe);
  borderframe.region = region;

  region.children = {};

  return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, size)
  local region = borderframe.region;
  size = size or 24;

  for _, child in pairs(region.children) do
    child:Hide()
  end
  local selfPoint;
  if(data.grow == "RIGHT" or data.grow == "HORIZONTAL") then
    selfPoint = "LEFT";
    if(data.align == "LEFT") then
      selfPoint = "TOP"..selfPoint;
    elseif(data.align == "RIGHT") then
      selfPoint = "BOTTOM"..selfPoint;
    end
  elseif(data.grow == "LEFT") then
    selfPoint = "RIGHT";
    if(data.align == "LEFT") then
      selfPoint = "TOP"..selfPoint;
    elseif(data.align == "RIGHT") then
      selfPoint = "BOTTOM"..selfPoint;
    end
  elseif(data.grow == "UP") then
    selfPoint = "BOTTOM";
    if(data.align == "LEFT") then
      selfPoint = selfPoint.."LEFT";
    elseif(data.align == "RIGHT") then
      selfPoint = selfPoint.."RIGHT";
    end
  elseif(data.grow == "DOWN" or data.grow == "VERTICAL") then
    selfPoint = "TOP";
    if(data.align == "LEFT") then
      selfPoint = selfPoint.."LEFT";
    elseif(data.align == "RIGHT") then
      selfPoint = selfPoint.."RIGHT";
    end
  elseif(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
    selfPoint = "CENTER";
  end
  data.selfPoint = selfPoint;

  local maxWidth, maxHeight = 0, 0;
  local radius = 0;
  if(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
    if(data.constantFactor == "RADIUS") then
      radius = data.radius;
    else
      if(#data.controlledChildren == 1) then
        radius = 0;
      else
        radius = (#data.controlledChildren * data.space) / (2 * math.pi)
      end
    end
  end
  for index, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    local childRegion = WeakAuras.GetRegion(childId)
    if(childData and childRegion) then
      if(data.grow == "LEFT" or data.grow == "RIGHT" or data.grow == "HORIZONTAL") then
        maxWidth = maxWidth + (childData.width or childRegion.width);
        maxWidth = maxWidth + (index > 1 and data.space or 0);
        maxHeight = math.max(maxHeight, (childData.height or childRegion.height));
      elseif(data.grow == "UP" or data.grow == "DOWN" or data.grow == "VERTICAL") then
        maxHeight = maxHeight + (childData.height or childRegion.height);
        maxHeight = maxHeight + (index > 1 and data.space or 0);
        maxWidth = math.max(maxWidth, (childData.width or childRegion.width));
      elseif(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
        maxWidth = math.max(maxWidth, (childData.width or childRegion.width));
        maxHeight = math.max(maxHeight, (childData.height or childRegion.height));
      end
    end
  end
  if(data.grow == "LEFT" or data.grow == "RIGHT" or data.grow == "HORIZONTAL") then
    maxHeight = maxHeight + (math.abs(data.stagger) * (#data.controlledChildren - 1));
  elseif(data.grow == "UP" or data.grow == "DOWN" or data.grow == "VERTICAL") then
    maxWidth = maxWidth + (math.abs(data.stagger) * (#data.controlledChildren - 1));
  elseif(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
    maxWidth = maxWidth + (2 * radius);
    maxHeight = maxHeight + (2 * radius);
  end

  local scale=1;
  if maxHeight > 0 and (maxHeight > maxWidth) then
    scale = size / maxHeight;
  elseif maxWidth > 0 and (maxWidth >= maxHeight) then
    scale = size / maxWidth;
  end

  region:SetPoint("CENTER", borderframe, "CENTER");
  region:SetWidth(maxWidth * scale);
  region:SetHeight(maxHeight * scale);

  local xOffset, yOffset = 0, 0;
  if(math.abs(data.stagger) > 0.1 and not (data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE")) then
    if(data.grow == "RIGHT" or data.grow == "LEFT" or data.grow == "HORIZONTAL") then
      if(data.align == "LEFT" and data.stagger > 0) then
        yOffset = yOffset - (data.stagger * (#data.controlledChildren - 1));
      elseif(data.align == "RIGHT" and data.stagger < 0) then
        yOffset = yOffset - (data.stagger * (#data.controlledChildren - 1));
      elseif(data.align == "CENTER") then
        if(data.stagger < 0) then
          yOffset = yOffset - (data.stagger * (#data.controlledChildren - 1) / 2);
        else
          yOffset = yOffset - (data.stagger * (#data.controlledChildren - 1) / 2);
        end
      end
    else
      if(data.align == "LEFT" and data.stagger < 0) then
        xOffset = xOffset - (data.stagger * (#data.controlledChildren - 1));
      elseif(data.align == "RIGHT" and data.stagger > 0) then
        xOffset = xOffset - (data.stagger * (#data.controlledChildren - 1));
      elseif(data.align == "CENTER") then
        if(data.stagger < 0) then
          xOffset = xOffset - (data.stagger * (#data.controlledChildren - 1) / 2);
        else
          xOffset = xOffset - (data.stagger * (#data.controlledChildren - 1) / 2);
        end
      end
    end
  end

  local angle = data.rotation or 0;
  local angleInc = 360 / (#data.controlledChildren ~= 0 and #data.controlledChildren or 1);
  if (data.grow == "COUNTERCIRCLE") then
    angleInc = -angleInc;
  end
  radius = 0;
  if(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
    if(data.constantFactor == "RADIUS") then
      radius = data.radius;
    else
      if(#data.controlledChildren <= 1) then
        radius = 0;
      else
        radius = (#data.controlledChildren * data.space) / (2 * math.pi);
      end
    end
  end
  for index, childId in pairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if(childData) then
      if(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
        yOffset = cos(angle) * radius * -1;
        xOffset = sin(angle) * radius;
        angle = angle + angleInc;
      end
      if not(region.children[index]) then
        region.children[index] = CreateFrame("FRAME", nil, region);
        region.children[index].texture = region.children[index]:CreateTexture(nil, "OVERLAY");
        region.children[index].texture:SetAllPoints(region.children[index]);
      end
      local childRegion = region.children[index]
      childRegion:Show()
      local r, g, b;
      if(childData.color) then
        r, g, b = childData.color[1], childData.color[2], childData.color[3];
      elseif(childData.barColor) then
        r, g, b = childData.barColor[1], childData.barColor[2], childData.barColor[3];
      elseif(childData.foregroundColor) then
        r, g, b = childData.foregroundColor[1], childData.foregroundColor[2], childData.foregroundColor[3];
      end
      r, g, b = r or 0.2, g or 0.8, b or 0.2;

      childRegion.texture:SetColorTexture(r, g, b);

      childRegion:ClearAllPoints();
      childRegion:SetPoint(selfPoint, region, selfPoint, xOffset * scale, yOffset * scale);
      childRegion:SetWidth((childData.width or childRegion.width or 0) * scale);
      childRegion:SetHeight((childData.height or childRegion.height or 0) * scale);
      if(data.grow == "RIGHT" or data.grow == "HORIZONTAL") then
        xOffset = xOffset + ((childData.width or childRegion.width or 0) + data.space);
        yOffset = yOffset + data.stagger;
      elseif(data.grow == "LEFT") then
        xOffset = xOffset - ((childData.width or childRegion.width or 0) + data.space);
        yOffset = yOffset + data.stagger;
      elseif(data.grow == "UP") then
        yOffset = yOffset + ((childData.height or childRegion.height or 0) + data.space);
        xOffset = xOffset + data.stagger;
      elseif(data.grow == "DOWN" or data.grow == "VERTICAL") then
        yOffset = yOffset - ((childData.height or childRegion.height or 0) + data.space);
        xOffset = xOffset + data.stagger;
      end
    end
  end

  local index = #data.controlledChildren + 1;
  if not(region.children[index]) then
    region.children[index] = CreateFrame("FRAME", nil, region);
    region.children[index].texture = region.children[index]:CreateTexture(nil, "OVERLAY");
    region.children[index].texture:SetAllPoints(region.children[index]);
  end
  region.children[index].texture:SetColorTexture(1, 1, 1);
  region.children[index]:ClearAllPoints();
  region.children[index]:Show()
  if(data.grow == "RIGHT" or data.grow == "LEFT" or data.grow == "HORIZONTAL") then
    region.children[index]:SetWidth(size);
    region.children[index]:SetHeight(1);
    if(data.align == "LEFT") then
      region.children[index]:SetPoint("CENTER", region, "TOP");
    elseif(data.align == "RIGHT") then
      region.children[index]:SetPoint("CENTER", region, "BOTTOM");
    else
      region.children[index]:SetPoint("CENTER", region, "CENTER");
    end
  elseif(data.grow == "UP" or data.grow == "DOWN" or data.grow == "VERTICAL") then
    region.children[index]:SetWidth(1);
    region.children[index]:SetHeight(size);
    if(data.align == "LEFT") then
      region.children[index]:SetPoint("CENTER", region, "LEFT");
    elseif(data.align == "RIGHT") then
      region.children[index]:SetPoint("CENTER", region, "RIGHT");
    else
      region.children[index]:SetPoint("CENTER", region, "CENTER");
    end
  elseif(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
    region.children[index]:SetWidth(1);
    region.children[index]:SetHeight(1);
    region.children[index]:SetPoint("CENTER", region, "CENTER");
  end
end

local function createIcon()
  local thumbnail = createThumbnail(UIParent);
  local t1 = thumbnail:CreateTexture(nil, "ARTWORK");
  t1:SetWidth(24);
  t1:SetHeight(6);
  t1:SetColorTexture(0.8, 0, 0);
  t1:SetPoint("TOP", thumbnail, "TOP", 0, -6);
  local t2 = thumbnail:CreateTexture(nil, "ARTWORK");
  t2:SetWidth(12);
  t2:SetHeight(12);
  t2:SetColorTexture(0.2, 0.8, 0.2);
  t2:SetPoint("TOP", t1, "BOTTOM", 0, -2);
  local t3 = thumbnail:CreateTexture(nil, "ARTWORK");
  t3:SetWidth(30);
  t3:SetHeight(4);
  t3:SetColorTexture(0.1, 0.25, 1);
  t3:SetPoint("TOP", t2, "BOTTOM", 0, -2);
  local t4 = thumbnail:CreateTexture(nil, "OVERLAY");
  t4:SetWidth(1);
  t4:SetHeight(36);
  t4:SetColorTexture(1, 1, 1);
  t4:SetPoint("CENTER", thumbnail, "CENTER");

  thumbnail.elapsed = 0;
  thumbnail:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed;
    if(self.elapsed < 0.5) then
      t2:SetPoint("TOP", t1, "BOTTOM", 0, -2 + (28 * self.elapsed));
      t2:SetAlpha(1 - (2 * self.elapsed));
    elseif(self.elapsed < 1.5) then
    -- do nothing
    elseif(self.elapsed < 2) then
      t2:SetPoint("TOP", t1, "BOTTOM", 0, -2 + (28 * (2 - self.elapsed)));
      t2:SetAlpha((2 * self.elapsed) - 3);
    elseif(self.elapsed < 3) then
    -- do nothing
    else
      self.elapsed = self.elapsed - 3;
    end
  end);
  return thumbnail;
end

WeakAuras.RegisterRegionOptions("dynamicgroup", createOptions, createIcon, L["Dynamic Group"], createThumbnail, modifyThumbnail, L["A group that dynamically controls the positioning of its children"]);
