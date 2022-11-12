if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

local L = WeakAuras.L;

-- Calculate bounding box
local function getRect(data)
  -- Temp variables
  local blx, bly, trx, try;
  blx, bly = data.xOffset or 0, data.yOffset or 0;

  if (data.width == nil or data.height == nil or data.regionType == "text") then
    return blx, bly, blx, bly;
  end

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

local function getHeight(data, region)
  if data.regionType == "text" then
    return region.height
  else
    return data.height
  end
end


local function getWidth(data, region)
  if data.regionType == "text" then
    return region.width
  else
    return data.width
  end
end

local function createDistributeAlignOptions(id, data)
  return {
    align_h = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Horizontal Align"],
      order = 10,
      values = OptionsPrivate.Private.align_types,
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
          local childRegion = WeakAuras.GetRegion(childId)
          if(childData and childRegion) then
            if(v == "CENTER") then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = 0 - (getWidth(childData, childRegion) / 2);
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = 0 + (getWidth(childData, childRegion) / 2);
              else
                childData.xOffset = 0;
              end
            elseif(v == "LEFT") then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = 0;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = 0 + getWidth(childData, childRegion);
              else
                childData.xOffset = 0 + (getWidth(childData, childRegion) / 2);
              end
            elseif(v == "RIGHT") then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = 0 - getWidth(childData, childRegion);
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = 0;
              else
                childData.xOffset = 0 - (getWidth(childData, childRegion) / 2);
              end
            end
            WeakAuras.Add(childData);
          end
        end
        WeakAuras.Add(data);
        OptionsPrivate.ResetMoverSizer();
      end
    },
    align_v = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Vertical Align"],
      order = 15,
      values = OptionsPrivate.Private.rotated_align_types,
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
          local childRegion = WeakAuras.GetRegion(childId)
          if(childData and childRegion) then
            if(v == "CENTER") then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = 0 - (getHeight(childData, childRegion) / 2);
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = 0 + (getHeight(childData, childRegion) / 2);
              else
                childData.yOffset = 0;
              end
            elseif(v == "RIGHT") then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = 0;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = 0 + getHeight(childData, childRegion);
              else
                childData.yOffset = 0 + (getHeight(childData, childRegion) / 2);
              end
            elseif(v == "LEFT") then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = 0 - ( childData.height or childRegion.height);
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = 0;
              else
                childData.yOffset = 0 - (getHeight(childData, childRegion) / 2);
              end
            end
            WeakAuras.Add(childData);
          end
        end
        WeakAuras.Add(data);
        OptionsPrivate.ResetMoverSizer();
      end
    },
    distribute_h = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
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
          local childRegion = WeakAuras.GetRegion(childId)
          if(childData and childRegion) then
            if(v > 0) then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = xOffset;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = xOffset + getWidth(childData, childRegion);
              else
                childData.xOffset = xOffset + (getWidth(childData, childRegion) / 2);
              end
              xOffset = xOffset + v;
            elseif(v < 0) then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = xOffset - getWidth(childData, childRegion);
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = xOffset;
              else
                childData.xOffset = xOffset - (getWidth(childData, childRegion) / 2);
              end
              xOffset = xOffset + v;
            end
            WeakAuras.Add(childData);
          end
        end

        WeakAuras.Add(data);
        OptionsPrivate.ResetMoverSizer();
      end
    },
    distribute_v = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
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
          local childRegion = WeakAuras.GetRegion(childId)
          if(childData and childRegion) then
            if(v > 0) then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = yOffset;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = yOffset + getHeight(childData, childRegion);
              else
                childData.yOffset = yOffset + (getHeight(childData, childRegion) / 2);
              end
              yOffset = yOffset + v;
            elseif(v < 0) then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = yOffset - getHeight(childData, childRegion);
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = yOffset;
              else
                childData.yOffset = yOffset - (getHeight(childData, childRegion) / 2);
              end
              yOffset = yOffset + v;
            end
            WeakAuras.Add(childData);
          end
        end

        WeakAuras.Add(data);
        OptionsPrivate.ResetMoverSizer();
      end
    },
    space_h = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
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
          local childRegion = WeakAuras.GetRegion(childId)
          if(childData and childRegion) then
            if(v >= 0) then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = xOffset;
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = xOffset + getWidth(childData, childRegion);
              else
                childData.xOffset = xOffset + (getWidth(childData, childRegion) / 2);
              end
              xOffset = xOffset + v + getWidth(childData, childRegion);
            elseif(v < 0) then
              if(childData.selfPoint:find("LEFT")) then
                childData.xOffset = xOffset - getWidth(childData, childRegion);
              elseif(childData.selfPoint:find("RIGHT")) then
                childData.xOffset = xOffset;
              else
                childData.xOffset = xOffset - (getWidth(childData, childRegion) / 2);
              end
              xOffset = xOffset + v - getWidth(childData, childRegion);
            end
            WeakAuras.Add(childData);
          end
        end

        WeakAuras.Add(data);
        OptionsPrivate.ResetMoverSizer();
      end
    },
    space_v = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
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
        for _, childId in pairs(data.controlledChildren) do
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
          local childRegion = WeakAuras.GetRegion(childId)
          if(childData and childRegion) then
            if(v >= 0) then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = yOffset;
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = yOffset + getHeight(childData, childRegion);
              else
                childData.yOffset = yOffset + (getHeight(childData, childRegion) / 2);
              end
              yOffset = yOffset + v + getHeight(childData, childRegion);
            elseif(v < 0) then
              if(childData.selfPoint:find("BOTTOM")) then
                childData.yOffset = yOffset - getHeight(childData, childRegion);
              elseif(childData.selfPoint:find("TOP")) then
                childData.yOffset = yOffset;
              else
                childData.yOffset = yOffset - (getHeight(childData, childRegion) / 2);
              end
              yOffset = yOffset + v - getHeight(childData, childRegion);
            end
            WeakAuras.Add(childData);
          end
        end

        WeakAuras.Add(data);
        OptionsPrivate.ResetMoverSizer();
      end
    }
  }
end

-- Create region options table
local function createOptions(id, data)
  -- Region options
  local options = {
    __title = L["Group Settings"],
    __order = 1,
    groupIcon = {
      type = "input",
      width = WeakAuras.doubleWidth - 0.15,
      name = L["Group Icon"],
      desc = L["Set Thumbnail Icon"],
      order = 0.50,
      get = function()
        return data.groupIcon and tostring(data.groupIcon) or ""
      end,
      set = function(info, v)
        data.groupIcon = v
        WeakAuras.Add(data)
        WeakAuras.UpdateThumbnail(data)
      end
    },
    chooseIcon = {
      type = "execute",
      width = 0.15,
      name = L["Choose"],
      order = 0.51,
      func = function()
         OptionsPrivate.OpenIconPicker(data, { [data.id] = {"groupIcon"} }, true)
       end,
       imageWidth = 24,
       imageHeight = 24,
       control = "WeakAurasIcon",
       image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
    },
    -- Alignment/Distribute options are added below
    scale = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Group Scale"],
      order = 45,
      min = 0.05,
      softMax = 2,
      max = 10,
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
        OptionsPrivate.ResetMoverSizer();
      end
    },
    endHeader = {
      type = "header",
      order = 100,
      name = "",
    },
  };

  local hasSubGroups = false
  local hasDynamicSubGroup = false
  for index, childId in pairs(data.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    if childData.controlledChildren then
      hasSubGroups = true
    end
    if childData.regionType == "dynamicgroup" then
      hasDynamicSubGroup = true
    end

    if hasSubGroups and hasDynamicSubGroup then
      break
    end
  end


  if not hasSubGroups then
    for k, v in pairs(createDistributeAlignOptions(id, data)) do
      options[k] = v
    end
  end

  if not hasDynamicSubGroup then
    for k, v in pairs(OptionsPrivate.commonOptions.BorderOptions(id, data, nil, nil, 70)) do
      options[k] = v
    end
  end

  return {
    group = options,
    position = OptionsPrivate.commonOptions.PositionOptions(id, data, nil, true, true, true),
  };
end

local function createThumbnail()
  -- frame
  local thumbnail = CreateFrame("Frame", nil, UIParent);
  thumbnail:SetWidth(32);
  thumbnail:SetHeight(32);

  -- border
  local border = thumbnail:CreateTexture(nil, "OVERLAY");
  border:SetAllPoints(thumbnail);
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

  local icon = thumbnail:CreateTexture(nil, "OVERLAY")
  icon:SetAllPoints(thumbnail)
  thumbnail.icon = icon

  return thumbnail
end

local function createDefaultIcon(parent)
  -- default Icon
  local defaultIcon = CreateFrame("Frame", nil, parent);
  parent.defaultIcon = defaultIcon;

  local t1 = defaultIcon:CreateTexture(nil, "ARTWORK");
  t1:SetWidth(24);
  t1:SetHeight(8);
  t1:SetColorTexture(0.8, 0, 0, 0.5);
  t1:SetPoint("TOP", parent, "TOP", 0, -6);
  local t2 = defaultIcon:CreateTexture(nil, "ARTWORK");
  t2:SetWidth(20);
  t2:SetHeight(20);
  t2:SetColorTexture(0.2, 0.8, 0.2, 0.5);
  t2:SetPoint("TOP", t1, "BOTTOM", 0, 5);
  local t3 = defaultIcon:CreateTexture(nil, "ARTWORK");
  t3:SetWidth(20);
  t3:SetHeight(12);
  t3:SetColorTexture(0.1, 0.25, 1, 0.5);
  t3:SetPoint("TOP", t2, "BOTTOM", -5, 8);

  return defaultIcon
end

-- Modify preview thumbnail
local function modifyThumbnail(parent, frame, data)
  function frame:SetIcon()
    if data.groupIcon then
      local success = WeakAuras.SetTextureOrAtlas(frame.icon, data.groupIcon)
      if success then
        if frame.defaultIcon then
          frame.defaultIcon:Hide()
        end
        frame.icon:Show()
        return
      end
    end

    if frame.icon then
      frame.icon:Hide()
    end
    if not frame.defaultIcon then
      frame.defaultIcon = createDefaultIcon(frame)
    end
    frame.defaultIcon:Show()
  end

  frame:SetIcon()
end

-- Create "new region" preview
local function createIcon()
  local thumbnail = createThumbnail()
  thumbnail.defaultIcon = createDefaultIcon(thumbnail)
  return thumbnail
end

-- Register new region type options with WeakAuras
WeakAuras.RegisterRegionOptions("group", createOptions, createIcon, L["Group"], createThumbnail, modifyThumbnail, L["Controls the positioning and configuration of multiple displays at the same time"]);
