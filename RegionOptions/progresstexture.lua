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
    mirror = {
      type = "toggle",
      width = "half",
      name = L["Mirror"],
      order = 10
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
      --[[set = function(info, v)
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
      end]]
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
  
  region.mirror_h = data.mirror;
  
  local function orientHorizontalInverse()
    foreground:ClearAllPoints();
    foreground:SetPoint("RIGHT", region, "RIGHT");
    region.orientation = "HORIZONTAL_INVERSE";
    if(data.compress) then
      function region:SetValue(progress)
        if(region.mirror_v) then
          if(region.mirror_h) then
            foreground:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
          else
            foreground:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          end
        else
          if(region.mirror_h) then
            foreground:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
          else
            foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
          end
        end
      end
    else
      function region:SetValue(progress)
        if(region.mirror_v) then
          if(region.mirror_h) then
            foreground:SetTexCoord(1,1 , 1,0 , 1-progress,1 , 1-progress,0);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
          else
            foreground:SetTexCoord(1-progress,1 , 1-progress,0 , 1,1 , 1,0);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          end
        else
          if(region.mirror_h) then
            foreground:SetTexCoord(1,0 , 1,1 , 1-progress,0 , 1-progress,1);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
          else
            foreground:SetTexCoord(1-progress,0 , 1-progress,1 , 1,0 , 1,1);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
          end
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
          if(region.mirror_h) then
            foreground:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
          else
            foreground:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          end
        else
          if(region.mirror_h) then
            foreground:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
          else
            foreground:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
          end
        end
      end
    else
      function region:SetValue(progress)
        if(region.mirror_v) then
          if(region.mirror_h) then
            foreground:SetTexCoord(progress,1 , progress,0 , 0,1 , 0,0);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
          else
            foreground:SetTexCoord(0,1 , 0,0 , progress,1 , progress,0);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          end
        else
          if(region.mirror_h) then
            foreground:SetTexCoord(progress,0 , progress,1 , 0,0 , 0,1);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(1,0 , 1,1 , 0,0 , 0,1);
          else
            foreground:SetTexCoord(0,0 , 0,1 , progress,0 , progress,1);
            foreground:SetWidth(region:GetWidth() * progress);
            background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
          end
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
        if(region.mirror_v) then
          if(region.mirror_h) then
            foreground:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
            foreground:SetHeight(region:GetHeight() * progress);
            background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
          else
            foreground:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
            foreground:SetHeight(region:GetHeight() * progress);
            background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          end
        else
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
      end
    else
      function region:SetValue(progress)
        if(region.mirror_v) then
          if(region.mirror_h) then
            foreground:SetTexCoord(1,progress , 1,0 , 0,progress , 0,0);
            foreground:SetHeight(region:GetHeight() * progress);
            background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
          else
            foreground:SetTexCoord(0,progress , 0,0 , 1,progress , 1,0);
            foreground:SetHeight(region:GetHeight() * progress);
            background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          end
        else
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
  end
  local function orientVertical()
    foreground:ClearAllPoints();
    foreground:SetPoint("BOTTOM", region, "BOTTOM");
    region.orientation = "VERTICAL";
    if(data.compress) then
      function region:SetValue(progress)
        if(region.mirror_v) then
          if(region.mirror_h) then
            foreground:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
            foreground:SetHeight(region:GetHeight() * progress);
            background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
          else
            foreground:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
            foreground:SetHeight(region:GetHeight() * progress);
            background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          end
        else
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
      end
    else
      function region:SetValue(progress)
        if(region.mirror_v) then
          if(region.mirror_h) then
            foreground:SetTexCoord(1,1 , 1,1-progress , 0,1 , 0,1-progress);
            foreground:SetHeight(region:GetHeight() * progress);
            background:SetTexCoord(1,1 , 1,0 , 0,1 , 0,0);
          else
            foreground:SetTexCoord(0,1 , 0,1-progress , 1,1 , 1,1-progress);
            foreground:SetHeight(region:GetHeight() * progress);
            background:SetTexCoord(0,1 , 0,0 , 1,1 , 1,0);
          end
        else
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
  
  region:SetValue(3/5);
end

local function createIcon()
  local data = {
    foregroundTexture = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
    sameTexture = true,
    backgroundOffset = 2,
    blendMode = "BLEND",
    width = 200,
    height = 200,
    orientation = "VERTICAL",
    alpha = 1.0,
    foregroundColor = {1, 1, 1, 1},
    backgroundColor = {0.5, 0.5, 0.5, 0.5}
  };
  
  local thumbnail = createThumbnail(UIParent);
  modifyThumbnail(UIParent, thumbnail, data, nil, 32);
  
  thumbnail.elapsed = 0;
  thumbnail:SetScript("OnUpdate", function(self, elapsed)
    thumbnail.elapsed = thumbnail.elapsed + elapsed;
    if(thumbnail.elapsed > 4) then
      thumbnail.elapsed = thumbnail.elapsed - 4;
    end
    thumbnail.region:SetValue((4 - thumbnail.elapsed) / 4);
  end);
  
  return thumbnail;
end

WeakAuras.RegisterRegionOptions("progresstexture", createOptions, createIcon, L["Progress Texture"], createThumbnail, modifyThumbnail, L["Shows a texture that changes based on duration"]);