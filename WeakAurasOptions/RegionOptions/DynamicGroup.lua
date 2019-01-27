local L = WeakAuras.L

local selfPoints = {
  default = "CENTER",
  RIGHT = function(data)
    if data.align  == "LEFT" then
      return "TOPLEFT"
    elseif data.align == "RIGHT" then
      return "BOTTOMLEFT"
    else
      return "LEFT"
    end
  end,
  LEFT = function(data)
    if data.align  == "LEFT" then
      return "TOPRIGHT"
    elseif data.align == "RIGHT" then
      return "BOTTOMRIGHT"
    else
      return "RIGHT"
    end
  end,
  UP = function(data)
    if data.align == "LEFT" then
      return "BOTTOMLEFT"
    elseif data.align == "RIGHT" then
      return "BOTTOMRIGHT"
    else
      return "BOTTOM"
    end
  end,
  DOWN = function(data)
    if data.align == "LEFT" then
      return "TOPLEFT"
    elseif data.align == "RIGHT" then
      return "TOPRIGHT"
    else
      return "TOP"
    end
  end,
  HORIZONTAL = function(data)
    if data.align == "LEFT" then
      return "TOP"
    elseif data.align == "RIGHT" then
      return "BOTTOM"
    else
      return "CENTER"
    end
  end,
  VERTICAL = function(data)
    if data.align == "LEFT" then
      return "LEFT"
    elseif data.align == "RIGHT" then
      return "RIGHT"
    else
      return "CENTER"
    end
  end,
  CIRCLE = "CENTER",
  COUNTERCIRCLE = "CENTER",
}

local function createOptions(id, data)
  local options = {
    __title = L["Dynamic Group Settings"],
    __order = 1,
    grow = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Grow"],
      order = 5,
      values = WeakAuras.grow_types,
      set = function(info, v)
        data.grow = v
        local selfPoint = selfPoints[data.grow] or selfPoints.default
        if type(selfPoint) == "function" then
          selfPoint = selfPoint(data)
        end
        data.selfPoint = selfPoint
        WeakAuras.Add(data)
        WeakAuras.ReloadTriggerOptions(data)
      end
    },
    align = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Align"],
      order = 10,
      values = WeakAuras.align_types,
      set = function(info, v)
        data.align = v
        local selfPoint = selfPoints[data.grow] or selfPoints.default
        if type(selfPoint) == "function" then
          selfPoint = selfPoint(data)
        end
        data.selfPoint = selfPoint
        WeakAuras.Add(data)
        WeakAuras.ReloadTriggerOptions(data)
      end,
      hidden = function() return (data.grow == "CUSTOM" or data.grow == "LEFT" or data.grow == "RIGHT" or data.grow == "HORIZONTAL" or data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") end,
      disabled = function() return data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE" end
    },
    rotated_align = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Align"],
      order = 10,
      values = WeakAuras.rotated_align_types,
      hidden = function() return (data.grow == "CUSTOM" or data.grow == "UP" or data.grow == "DOWN" or data.grow == "VERTICAL" or data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") end,
      get = function() return data.align; end,
      set = function(info, v)
        data.align = v
        local selfPoint = selfPoints[data.grow] or selfPoints.default
        if type(selfPoint) == "function" then
          selfPoint = selfPoint(data)
        end
        data.selfPoint = selfPoint
        WeakAuras.Add(data)
        WeakAuras.ReloadTriggerOptions(data)
      end,
    },
    constantFactor = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Constant Factor"],
      order = 10,
      values = WeakAuras.circular_group_constant_factor_types,
      hidden = function() return data.grow ~= "CIRCLE" and data.grow ~= "COUNTERCIRCLE" end
    },
    space = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Space"],
      order = 15,
      softMin = 0,
      softMax = 300,
      bigStep = 1,
      hidden = function() return data.grow == "CUSTOM" or ((data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") and data.constantFactor == "RADIUS") end
    },
    rotation = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Rotation"],
      order = 15,
      min = 0,
      max = 360,
      bigStep = 3,
      hidden = function() return data.grow ~= "CIRCLE" and data.grow ~= "COUNTERCIRCLE" end
    },
    stagger = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Stagger"],
      order = 20,
      min = -50,
      max = 50,
      step = 0.1,
      bigStep = 1,
      hidden = function() return data.grow == "CUSTOM" or data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE" end
    },
    radius = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Radius"],
      order = 20,
      softMin = 0,
      softMax = 500,
      bigStep = 1,
      hidden = function() return data.grow == "CUSTOM" or not((data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") and data.constantFactor == "RADIUS") end
    },
    animate = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Animated Expand and Collapse"],
      order = 30
    },
    border = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Border",
      name = L["Border"],
      order = 35,
      values = AceGUIWidgetLSMlists.border
    },
    background = {
      type = "select",
      width = WeakAuras.normalWidth,
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
      width = WeakAuras.normalWidth,
      name = L["Border Offset"],
      order = 45,
      softMin = 0,
      softMax = 32,
      bigStep = 1
    },
    backgroundInset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Background Inset"],
      order = 47,
      softMin = 0,
      softMax = 32,
      bigStep = 1
    },
    sort = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Sort"],
      order = 48,
      values = WeakAuras.group_sort_types
    },
    hybridPosition = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Hybrid Position"],
      order = 48.1,
      values = WeakAuras.group_hybrid_position_types,
      hidden = function() return not(data.sort == "hybrid") end,
    },
    hybridSortMode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Hybrid Sort Mode"],
      order = 48.2,
      values = WeakAuras.group_hybrid_sort_types,
      hidden = function() return not(data.sort == "hybrid") end,
    },
    sortHybrid = {
      type = "multiselect",
      width = "full",
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
      width = WeakAuras.normalWidth,
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
    position = WeakAuras.PositionOptions(id, data, nil, true, true),
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

  local region = WeakAuras.regionTypes["dynamicgroup"].create(borderframe);
  borderframe.region = region;
  return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, size)
  local region = borderframe.region
  borderframe:Hide()
  size = size or 24
  region.suspended = 1

  -- i don't much like this hack. But i also want to be able to use the same code
  -- for the thumbnail, without worrying about animations mucking it up.
  local animate = data.animate
  data.animate = nil
  WeakAuras.regionTypes["dynamicgroup"].modify(borderframe, region, data)
  data.animate = animate
  local sortedChildren = region.sortedChildren
  for _, regionData in ipairs(sortedChildren) do
    regionData.region:Hide()
  end
  region.sortedChildren = {}
  for index, childId in pairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if(childData) then
      local regionData = sortedChildren[index] or {}
      region.sortedChildren[index] = regionData
      regionData.data = childData
      regionData.controlPoint = regionData.controlPoint or region.controlPoints:Acquire()
      regionData.id = childId
      regionData.dataIndex = index
      regionData.region = regionData.region or CreateFrame("FRAME", nil, regionData.controlPoint)
      regionData.region:SetParent(regionData.controlPoint)
      local childRegion = regionData.region
      childRegion:SetPoint(data.selfPoint, regionData.controlPoint, data.selfPoint)
      childRegion.texture = childRegion.texture or childRegion:CreateTexture()
      childRegion.texture:SetAllPoints()
      childRegion.width = childData.width or 16
      childRegion.height = childData.height or 16
      local r, g, b
      if(childData.color) then
        r, g, b = childData.color[1], childData.color[2], childData.color[3]
      elseif(childData.barColor) then
        r, g, b = childData.barColor[1], childData.barColor[2], childData.barColor[3]
      elseif(childData.foregroundColor) then
        r, g, b = childData.foregroundColor[1], childData.foregroundColor[2], childData.foregroundColor[3]
      end
      r, g, b = r or 0.2, g or 0.8, b or 0.2

      childRegion.texture:SetColorTexture(r, g, b)
      childRegion:SetWidth((childData.width or childRegion.width or 16))
      childRegion:SetHeight((childData.height or childRegion.height or 16))
    end
  end
  region.background:Hide()
  region:ClearAllPoints()
  -- TODO: find a less hacky method of getting the right size for the thumbnail.
  -- This is another hack. This time, it's due to the fact that a thumbnail isn't actually attached to anything
  -- So, GetLeft and similar return nil in Resize. Workaround this by temporarily binding the region to UIParent
  region:SetPoint("CENTER", UIParent, "CENTER")
  region.needToReload = false
  region.needToPosition = true
  region:Resume()
  region:ClearAllPoints()
  region:SetPoint("CENTER", borderframe, "CENTER")
  local width = region:GetWidth()
  local height = region:GetHeight()
  if width > height then
    region:SetScale(size/width)
  else
    region:SetScale(size/height)
  end

  -- "guide" line
  if not(region.guide) then
    region.guide = CreateFrame("FRAME", nil, region)
    region.guide.texture = region.guide:CreateTexture(nil, "OVERLAY")
    region.guide.texture:SetAllPoints(region.guide)
  end
  region.guide.texture:SetColorTexture(1, 1, 1)
  region.guide:ClearAllPoints()
  region.guide:Show()
  if(data.grow == "RIGHT" or data.grow == "LEFT" or data.grow == "HORIZONTAL") then
    region.guide:SetWidth(region:GetWidth())
    region.guide:SetHeight(1)
    if(data.align == "LEFT") then
      region.guide:SetPoint("CENTER", region, "TOP")
    elseif(data.align == "RIGHT") then
      region.guide:SetPoint("CENTER", region, "BOTTOM")
    else
      region.guide:SetPoint("CENTER", region, "CENTER")
    end
  elseif(data.grow == "UP" or data.grow == "DOWN" or data.grow == "VERTICAL") then
    region.guide:SetWidth(1)
    region.guide:SetHeight(region:GetHeight())
    if(data.align == "LEFT") then
      region.guide:SetPoint("CENTER", region, "LEFT")
    elseif(data.align == "RIGHT") then
      region.guide:SetPoint("CENTER", region, "RIGHT")
    else
      region.guide:SetPoint("CENTER", region, "CENTER")
    end
  elseif(data.grow == "CIRCLE" or data.grow == "COUNTERCIRCLE") then
    region.guide:SetWidth(1)
    region.guide:SetHeight(1)
    region.guide:SetPoint("CENTER", region, "CENTER")
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
