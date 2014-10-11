-- Import SM for statusbar-textures, font-styles and border-types
local SharedMedia = LibStub("LibSharedMedia-3.0");

-- Import translation
local L = WeakAuras.L;

-- Calculate bounding box
local function getRect(data)
  -- Temp variables
  local blx, bly, trx, try;
  blx, bly = data.xOffset, data.yOffset;
  
  -- Calc bounding box
  if(data.selfPoint:find("LEFT")) then
    trx = blx + data.width;
  elseif(data.selfPoint:find("RIGHT")) then
    trx = blx;
    blx = blx - data.width;
  else
    blx = blx - (data.width/2);
    trx = blx + data.width;
  end
  if(data.selfPoint:find("BOTTOM")) then
    try = bly + data.height;
  elseif(data.selfPoint:find("TOP")) then
    try = bly;
    bly = bly - data.height;
  else
    bly = bly - (data.height/2);
    try = bly + data.height;
  end
  
  -- Return data
  return blx, bly, trx, try;
end

-- Create region options table
local function createOptions(id, data)
  -- Region options
  local options = {
    align_h = {
      type = "select",
      name = L["Horizontal Align"],
      order = 10,
      values = WeakAuras.align_types,
      get = function()
        if(#data.controlledChildren < 1) then
          return nil;
        end
        local alignedCenter, alignedRight, alignedLeft = "CENTER", "RIGHT", "LEFT";
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            local left, _, right = getRect(childData);
            local center = (left + right) / 2;
            if(math.abs(right) >= 0.01) then
              alignedRight = nil;
            end
            if(math.abs(left) >= 0.01) then
              alignedLeft = nil;
            end
            if(math.abs(center) >= 0.01) then
              alignedCenter = nil;
            end
          end
        end
        return (alignedCenter or alignedRight or alignedLeft);
      end,
      set = function(info, v)
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            if(v == "CENTER") then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = 0 - (childData.width / 2);
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = 0 + (childData.width / 2);
              else
                childData.xOffset = 0;
              end
            elseif(v == "LEFT") then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = 0;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = 0 + childData.width;
              else
                childData.xOffset = 0 + (childData.width / 2);
              end
            elseif(v == "RIGHT") then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = 0 - childData.width;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = 0;
              else
                childData.xOffset = 0 - (childData.width / 2);
              end
            end
            WeakAuras.Add(childData);
          end
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    },
    align_v = {
      type = "select",
      name = L["Vertical Align"],
      order = 15,
      values = WeakAuras.rotated_align_types,
      get = function()
        if(#data.controlledChildren < 1) then
          return nil;
        end
        local alignedCenter, alignedBottom, alignedTop = "CENTER", "RIGHT", "LEFT";
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            local _, bottom, _, top = getRect(childData);
            local center = (bottom + top) / 2;
            if(math.abs(bottom) >= 0.01) then
              alignedBottom = nil;
            end
            if(math.abs(top) >= 0.01) then
              alignedTop = nil;
            end
            if(math.abs(center) >= 0.01) then
              alignedCenter = nil;
            end
          end
        end
        return alignedCenter or alignedBottom or alignedTop;
      end,
      set = function(info, v)
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            if(v == "CENTER") then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = 0 - (childData.height / 2);
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = 0 + (childData.height / 2);
              else
                childData.yOffset = 0;
              end
            elseif(v == "RIGHT") then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = 0;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = 0 + childData.height;
              else
                childData.yOffset = 0 + (childData.height / 2);
              end
            elseif(v == "LEFT") then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = 0 - childData.height;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = 0;
              else
                childData.yOffset = 0 - (childData.height / 2);
              end
            end
            WeakAuras.Add(childData);
          end
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    },
    distribute_h = {
      type = "range",
      name = L["Distribute Horizontally"],
      order = 20,
      softMin = -100,
      softMax = 100,
      bigStep = 1,
      get = function()
        if(#data.controlledChildren < 2) then
          return nil;
        end
        local spaced;
        local previousData;
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            local left, _, right = getRect(childData);
            if not(previousData) then
              if not(math.abs(left) < 0.01 or math.abs(right) < 0.01) then
                return nil;
              end
              previousData = childData;
            else
              local pleft, _, pright = getRect(previousData);
              if(left - pleft > 0) then
                if not(spaced) then
                  spaced = left - pleft;
                else
                  if(math.abs(spaced - (left - pleft)) > 0.01) then
                    return nil;
                  end
                end
              elseif(right - pright < 0) then
                if not(spaced) then
                  spaced = right - pright;
                else
                  if(math.abs(spaced - (right - pright)) > 0.01) then
                    return nil;
                  end
                end
              else
                return nil;
              end
            end
            previousData = childData;
          end
        end
        return spaced;
      end,
      set = function(info, v)
        local xOffset = 0;
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            if(v > 0) then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = xOffset;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = xOffset + childData.width;
              else
                childData.xOffset = xOffset + (childData.width / 2);
              end
              xOffset = xOffset + v;
            elseif(v < 0) then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = xOffset - childData.width;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = xOffset;
              else
                childData.xOffset = xOffset - (childData.width / 2);
              end
              xOffset = xOffset + v;
            end
            WeakAuras.Add(childData);
          end
        end
        
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    },
    distribute_v = {
      type = "range",
      name = L["Distribute Vertically"],
      order = 25,
      softMin = -100,
      softMax = 100,
      bigStep = 1,
      get = function()
        if(#data.controlledChildren < 2) then
          return nil;
        end
        local spaced;
        local previousData;
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            local _, bottom, _, top = getRect(childData);
            if not(previousData) then
              if not(math.abs(bottom) < 0.01 or math.abs(top) < 0.01) then
                return nil;
              end
              previousData = childData;
            else
              local _, pbottom, _, ptop = getRect(previousData);
              if(bottom - pbottom > 0) then
                if not(spaced) then
                  spaced = bottom - pbottom;
                else
                  if(math.abs(spaced - (bottom - pbottom)) > 0.01) then
                    return nil;
                  end
                end
              elseif(top - ptop < 0) then
                if not(spaced) then
                  spaced = top - ptop;
                else
                  if(math.abs(spaced - (top - ptop)) > 0.01) then
                    return nil;
                  end
                end
              else
                return nil;
              end
            end
            previousData = childData;
          end
        end
        return spaced;
      end,
      set = function(info, v)
        local yOffset = 0;
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            if(v > 0) then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = yOffset;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = yOffset + childData.height;
              else
                childData.yOffset = yOffset + (childData.height / 2);
              end
              yOffset = yOffset + v;
            elseif(v < 0) then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = yOffset - childData.height;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = yOffset;
              else
                childData.yOffset = yOffset - (childData.height / 2);
              end
              yOffset = yOffset + v;
            end
            WeakAuras.Add(childData);
          end
        end
        
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    },
    space_h = {
      type = "range",
      name = L["Space Horizontally"],
      order = 30,
      softMin = -100,
      softMax = 100,
      bigStep = 1,
      get = function()
        if(#data.controlledChildren < 2) then
          return nil;
        end
        local spaced;
        local previousData;
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            local left, _, right = getRect(childData);
            if not(previousData) then
              if not(math.abs(left) < 0.01 or math.abs(right) < 0.01) then
                return nil;
              end
              previousData = childData;
            else
              local pleft, _, pright = getRect(previousData);
              if(left - pright > 0) then
                if not(spaced) then
                  spaced = left - pright;
                else
                  if(math.abs(spaced - (left - pright)) > 0.01) then
                    return nil;
                  end
                end
              elseif(right - pleft < 0) then
                if not(spaced) then
                  spaced = right - pleft;
                else
                  if(math.abs(spaced - (right - pleft)) > 0.01) then
                    return nil;
                  end
                end
              else
                return nil;
              end
            end
            previousData = childData;
          end
        end
        return spaced;
      end,
      set = function(info, v)
        local xOffset = 0;
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            if(v > 0) then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = xOffset;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = xOffset + childData.width;
              else
                childData.xOffset = xOffset + (childData.width / 2);
              end
              xOffset = xOffset + v + childData.width;
            elseif(v < 0) then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = xOffset - childData.width;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = xOffset;
              else
                childData.xOffset = xOffset - (childData.width / 2);
              end
              xOffset = xOffset + v - childData.width;
            end
            WeakAuras.Add(childData);
          end
        end
        
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    },
    space_v = {
      type = "range",
      name = L["Space Vertically"],
      order = 35,
      softMin = -100,
      softMax = 100,
      bigStep = 1,
      get = function()
        if(#data.controlledChildren < 2) then
          return nil;
        end
        local spaced;
        local previousData;
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            local _, bottom, _, top = getRect(childData);
            if not(previousData) then
              if not(math.abs(bottom) < 0.01 or math.abs(top) < 0.01) then
                return nil;
              end
              previousData = childData;
            else
              local _, pbottom, _, ptop = getRect(previousData);
              if(bottom - ptop > 0) then
                if not(spaced) then
                  spaced = bottom - ptop;
                else
                  if(math.abs(spaced - (bottom - ptop)) > 0.01) then
                    return nil;
                  end
                end
              elseif(top - pbottom < 0) then
                if not(spaced) then
                  spaced = top - pbottom;
                else
                  if(math.abs(spaced - (top - pbottom)) > 0.01) then
                    return nil;
                  end
                end
              else
                return nil;
              end
            end
            previousData = childData;
          end
        end
        return spaced;
      end,
      set = function(info, v)
        local yOffset = 0;
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          if(childData) then
            if(v > 0) then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = yOffset;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = yOffset + childData.height;
              else
                childData.yOffset = yOffset + (childData.height / 2);
              end
              yOffset = yOffset + v + childData.height;
            elseif(v < 0) then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = yOffset - childData.height;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = yOffset;
              else
                childData.yOffset = yOffset - (childData.height / 2);
              end
              yOffset = yOffset + v - childData.height;
            end
            WeakAuras.Add(childData);
          end
        end
        
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.ResetMoverSizer();
      end
    },
  border_header = {
    type = "header",
    name = L["Border Settings"],
    order = 46.0
  },
    spacer = {
      type = "header",
      name = "",
      order = 50
    }
  };
  
  -- Positioning options
  options = WeakAuras.AddPositionOptions(options, id, data);
  
  -- Border options
  options = WeakAuras.AddBorderOptions(options, id, data);
  
  -- Remove some poition options
  options.width = nil;
  options.height = nil;
  options.selfPoint.disabled = true;
  options.selfPoint.values = {["BOTTOMLEFT"] = "Anchor Point"};
  
  -- Return options
  return options;
end

-- Create preview thumbnail
local function createThumbnail(parent, fullCreate)
  -- Preview frame
  local borderframe = CreateFrame("FRAME", nil, parent);
  borderframe:SetWidth(32);
  borderframe:SetHeight(32);
  
  -- Preview border
  local border = borderframe:CreateTexture(nil, "OVERLAY");
  border:SetAllPoints(borderframe);
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8);
  
  -- Main region
  local region = CreateFrame("FRAME", nil, borderframe);
  borderframe.region = region;
  
  -- Preview children
  region.children = {};
  
  -- Return preview
  return borderframe;
end

-- Modify preview thumbnail
local function modifyThumbnail(parent, borderframe, data, fullModify, size)
  local region = borderframe.region;
  size = size or 24;
  
  local leftest, rightest, lowest, highest = 0, 0, 0, 0;
  for index, childId in ipairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if(childData) then
      local blx, bly, trx, try = getRect(childData);
      leftest = math.min(leftest, blx);
      rightest = math.max(rightest, trx);
      lowest = math.min(lowest, bly);
      highest = math.max(highest, try);
    end
  end
  
  local maxWidth, maxHeight = rightest - leftest, highest - lowest;
  
  local scale=1;
  if maxHeight > 0 and (maxHeight > maxWidth) then
    scale = size / maxHeight;
  elseif maxWidth > 0 and (maxWidth >= maxHeight) then
    scale = size / maxWidth;
  end
  
  region:SetPoint("CENTER", borderframe, "CENTER");
  region:SetWidth(maxWidth * scale);
  region:SetHeight(maxHeight * scale);
  
  for index, childId in pairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if(childData) then
      if not(region.children[index]) then
        region.children[index] = CreateFrame("FRAME", nil, region);
        region.children[index].texture = region.children[index]:CreateTexture(nil, "ARTWORK");
        region.children[index].texture:SetAllPoints(region.children[index]);
      end
      region.children[index]:Show();
      local r, g, b;
      if(childData.color) then
        r, g, b = childData.color[1], childData.color[2], childData.color[3];
      end
      if(childData.barColor and not(r and g and b)) then
        r, g, b = childData.barColor[1], childData.barColor[2], childData.barColor[3];
      end
      if(childData.foregroundColor and not(r and g and b)) then
        r, g, b = childData.foregroundColor[1], childData.foregroundColor[2], childData.foregroundColor[3];
      end
      if not(r and g and b) then
        r, g, b = 0.2, 0.8, 0.2;
      end
      region.children[index].texture:SetTexture(r, g, b, 0.5);
      
      local blx, bly, trx, try = getRect(childData);
      
      region.children[index]:ClearAllPoints();
      region.children[index]:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", (blx - leftest) * scale, (bly - lowest) * scale);
      region.children[index]:SetWidth(childData.width * scale);
      region.children[index]:SetHeight(childData.height * scale);
    end
  end
  for i=#data.controlledChildren+1,#region.children do
    region.children[i]:Hide();
  end
end

-- Create "new region" preview
local function createIcon()
  local thumbnail = createThumbnail(UIParent);
  local t1 = thumbnail:CreateTexture(nil, "ARTWORK");
  t1:SetWidth(24);
  t1:SetHeight(8);
  t1:SetTexture(0.8, 0, 0, 0.5);
  t1:SetPoint("TOP", thumbnail, "TOP", 0, -6);
  local t2 = thumbnail:CreateTexture(nil, "ARTWORK");
  t2:SetWidth(20);
  t2:SetHeight(20);
  t2:SetTexture(0.2, 0.8, 0.2, 0.5);
  t2:SetPoint("TOP", t1, "BOTTOM", 0, 5);
  local t3 = thumbnail:CreateTexture(nil, "ARTWORK");
  t3:SetWidth(20);
  t3:SetHeight(12);
  t3:SetTexture(0.1, 0.25, 1, 0.5);
  t3:SetPoint("TOP", t2, "BOTTOM", -5, 8);
  
  return thumbnail;
end

-- Register new region type options with WeakAuras
WeakAuras.RegisterRegionOptions("group", createOptions, createIcon, L["Group"], createThumbnail, modifyThumbnail, L["Controls the positioning and configuration of multiple displays at the same time"]);