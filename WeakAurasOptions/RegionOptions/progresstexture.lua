local L = WeakAuras.L
  
local function createOptions(id, data)
  local options = {
    foregroundTexture = {
      type = "input",
      name = L["Foreground Texture"],
      order = 0
    },
    backgroundTexture = {
      type = "input",
      name = L["Background Texture"],
      order = 5,
      disabled = function() return data.sameTexture; end,
      get = function() return data.sameTexture and data.foregroundTexture or data.backgroundTexture; end
    },
    space1 = {
      type = "execute",
      width = "half",
      name = "",
      order = 10,
      image = function() return "", 0, 0 end
    },
    chooseForegroundTexture = {
      type = "execute",
      name = L["Choose"],
      width = "half",
      order = 12,
      func = function()
        WeakAuras.OpenTexturePick(data, "foregroundTexture");
      end
    },
    sameTexture = {
      type = "toggle",
      name = L["Same"],
      width = "half",
      order = 15
    },
    chooseBackgroundTexture = {
      type = "execute",
      name = L["Choose"],
      width = "half",
      order = 17,
      func = function()
        WeakAuras.OpenTexturePick(data, "backgroundTexture");
      end,
      disabled = function() return data.sameTexture; end
    },
    blendMode = {
      type = "select",
      name = L["Blend Mode"],
      order = 20,
      values = WeakAuras.blend_types
    },
    backgroundOffset = {
      type = "range",
      name = L["Background Offset"],
      min = 0,
      softMax = 25,
      bigStep = 1,
      order = 25
    },
    orientation = {
      type = "select",
      name = L["Orientation"],
      order = 35,
      values = WeakAuras.orientation_types,
      set = function(info, v)
        local previous = data.orientation:find("HORIZONTAL") and "HORIZONTAL" or "VERTICAL";
        data.orientation = v;
        local new = data.orientation:find("HORIZONTAL") and "HORIZONTAL" or "VERTICAL";
        if(previous ~= new) then
          local temp = data.width;
          data.width = data.height;
          data.height = temp;
        end
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        WeakAuras.SetIconNames(data);
      end
    },
    compress = {
      type = "toggle",
      width = "half",
      name = L["Compress"],
      order = 42
    },
    inverse = {
      type = "toggle",
      width = "half",
      name = L["Inverse"],
      order = 45
    },
    foregroundColor = {
      type = "color",
      name = L["Foreground Color"],
      hasAlpha = true,
      order = 30
    },
    backgroundColor = {
      type = "color",
      name = L["Background Color"],
      hasAlpha = true,
      order = 40
    },
    alpha = {
      type = "range",
      name = L["Alpha"],
      order = 52,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    },
    stickyDuration = {
      type = "toggle",
      name = L["Sticky Duration"],
      desc = L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."],
      order = 55
    },
    spacer = {
      type = "header",
      name = "",
      order = 60
    }
  };
  options = WeakAuras.AddPositionOptions(options, id, data);
  
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
  
  local region = CreateFrame("FRAME", nil, borderframe);
  borderframe.region = region;
  region:SetWidth(32);
  region:SetHeight(32);
  
  local background = region:CreateTexture(nil, "BACKGROUND");
  borderframe.background = background;
  
  local foreground = region:CreateTexture(nil, "ART");
  borderframe.foreground = foreground;
  
  return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, size)
  local region, background, foreground = borderframe.region, borderframe.background, borderframe.foreground;
  
  size = size or 30;
  local scale;
  if(data.height > data.width) then
    scale = size/data.height;
    region:SetWidth(scale * data.width);
    region:SetHeight(size);
    foreground:SetWidth(scale * data.width);
    foreground:SetHeight(size);
  else
    scale = size/data.width;
    region:SetWidth(size);
    region:SetHeight(scale * data.height);
    foreground:SetWidth(size);
    foreground:SetHeight(scale * data.height);
  end
  
  region:ClearAllPoints();
  region:SetPoint("CENTER", borderframe, "CENTER");
  region:SetAlpha(data.alpha);
  
  background:SetTexture(data.sameTexture and data.foregroundTexture or data.backgroundTexture);
  background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  background:SetBlendMode(data.blendMode);
  
  foreground:SetTexture(data.foregroundTexture);
  foreground:SetVertexColor(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);
  foreground:SetBlendMode(data.blendMode);
  
  background:ClearAllPoints();
  foreground:ClearAllPoints();
  background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", -1 * scale * data.backgroundOffset, -1 * scale * data.backgroundOffset);
  background:SetPoint("TOPRIGHT", region, "TOPRIGHT", scale * data.backgroundOffset, scale * data.backgroundOffset);
  
  local progress = 3/5;
  if(data.orientation == "HORIZONTAL_INVERSE") then
    foreground:SetPoint("RIGHT", region, "RIGHT");
    if(data.compress) then
      foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
      foreground:SetWidth(region:GetWidth() * progress);
      background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
    else
      foreground:SetTexCoord(1-progress,0 , 1-progress,1 , 1,0 , 1,1);
      foreground:SetWidth(region:GetWidth() * progress);
      background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
    end
   elseif(data.orientation == "HORIZONTAL") then
    foreground:SetPoint("LEFT", region, "LEFT");
    if(data.compress) then
      foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
      foreground:SetWidth(region:GetWidth() * progress);
      background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
    else
      foreground:SetTexCoord(0,0 , 0,1 , progress,0 , progress,1);
      foreground:SetWidth(region:GetWidth() * progress);
      background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
    end
  elseif(data.orientation == "VERTICAL_INVERSE") then
    foreground:SetPoint("TOP", region, "TOP");
    if(data.compress) then
      foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
      foreground:SetHeight(region:GetWidth() * progress);
      background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
    else
      foreground:SetTexCoord(0,0 , 0,progress , 1,0 , 1,progress);
      foreground:SetHeight(region:GetWidth() * progress);
      background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
    end
  elseif(data.orientation == "VERTICAL") then
    foreground:SetPoint("BOTTOM", region, "BOTTOM");
    if(data.compress) then
      foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
      foreground:SetHeight(region:GetWidth() * progress);
      background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
    else
      foreground:SetTexCoord(0,1-progress , 0,1 , 1,1-progress , 1,1);
      foreground:SetHeight(region:GetWidth() * progress);
      background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
    end
  end
end

local function createIcon()
  local data = {
    foregroundTexture = "Interface\\PVPFrame\\PVP-Banner-Emblem-3",
    sameTexture = true,
    backgroundOffset = 2,
    blendMode = "BLEND",
    width = 200,
    height = 200,
    orientation = "VERTICAL",
    alpha = 1.0,
    foregroundColor = {1, 1, 1, 1},
    backgroundColor = {0, 0, 0, 0.5}
  };
  
  local thumbnail = createThumbnail(UIParent);
  modifyThumbnail(UIParent, thumbnail, data, nil, 32);
  
  return thumbnail;
end

WeakAuras.RegisterRegionOptions("progresstexture", createOptions, createIcon, L["Progress Texture"], createThumbnail, modifyThumbnail, L["Shows a texture that changes based on duration"]);