if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local texture_data = WeakAuras.StopMotion.texture_data;
local L = WeakAuras.L;

local default = {
    foregroundTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion",
    backgroundTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\stopmotion",
    desaturateBackground = false,
    desaturateForeground = false,
    sameTexture = true,
    width = 128,
    height = 128,
    foregroundColor = {1, 1, 1, 1},
    backgroundColor = {0.5, 0.5, 0.5, 0.5},
    blendMode = "BLEND",
    rotation = 0,
    discrete_rotation = 0,
    mirror = false,
    rotate = true,
    selfPoint = "CENTER",
    anchorPoint = "CENTER",
    anchorFrameType = "SCREEN",
    xOffset = 0,
    yOffset = 0,
    frameStrata = 1,
    startPercent = 0,
    endPercent = 1,
    backgroundPercent = 1,
    frameRate = 15,
    animationType = "loop",
    inverse = false,
    customForegroundFrames = 0,
    customForegroundRows = 16,
    customForegroundColumns = 16,
    customBackgroundFrames = 0,
    customForegroundFileWidth = 0,
    customForegroundFileHeight = 0,
    customForegroundFrameWidth = 0,
    customForegroundFrameHeight = 0,
    customBackgroundRows = 16,
    customBackgroundColumns = 16,
    hideBackground = true
};

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  desaturateForeground = {
    display = L["Desaturate Foreground"],
    setter = "SetForegroundDesaturated",
    type = "bool",
  },
  desaturateBackground = {
    display = L["Desaturate Background"],
    setter = "SetBackgroundDesaturated",
    type = "bool",
  },
  foregroundColor = {
    display = L["Foreground Color"],
    setter = "Color",
    type = "color"
  },
  backgroundColor = {
    display = L["Background Color"],
    setter = "SetBackgroundColor",
    type = "color"
  },
  width = {
    display = L["Width"],
    setter = "SetRegionWidth",
    type = "number",
    min = 1,
    softMax = screenWidth,
    bigStep = 1,
  },
  height = {
    display = L["Height"],
    setter = "SetRegionHeight",
    type = "number",
    min = 1,
    softMax = screenHeight,
    bigStep = 1
  },
}

WeakAuras.regionPrototype.AddProperties(properties, default);

local function create(parent)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame.regionType = "stopmotion"
    frame:SetMovable(true);
    frame:SetResizable(true);
    if frame.SetResizeBounds then
      frame:SetResizeBounds(1, 1)
    else
      frame:SetMinResize(1, 1)
    end

    local background = frame:CreateTexture(nil, "BACKGROUND");
    frame.background = background;
    background:SetAllPoints(frame);

    local foreground = frame:CreateTexture(nil, "ARTWORK");
    frame.foreground = foreground;
    foreground:SetAllPoints(frame);

    WeakAuras.regionPrototype.create(frame);

    return frame;
end

local function SetTextureViaAtlas(self, texture)
  self:SetTexture(texture);
end

local function setTile(texture, frame, rows, columns, frameScaleW, frameScaleH)
  frame = frame - 1;
  local row = floor(frame / columns);
  local column = frame % columns;

  local deltaX = frameScaleW / columns
  local deltaY = frameScaleH / rows

  local left = deltaX * column;
  local right = left + deltaX;

  local top = deltaY * row;
  local bottom = top + deltaY;
  pcall(function() texture:SetTexCoord(left, right, top, bottom) end)
end

WeakAuras.setTile = setTile;

local function SetFrameViaAtlas(self, texture, frame)
  local frameScaleW = 1
  local frameScaleH = 1
  if self.fileWidth and self.frameWidth and self.fileWidth > 0 and self.frameWidth > 0 then
    frameScaleW = (self.frameWidth * self.columns) / self.fileWidth
  end
  if self.fileHeight and self.frameHeight and self.fileHeight > 0 and self.frameHeight > 0 then
    frameScaleH = (self.frameHeight * self.rows) / self.fileHeight
  end
  setTile(self, frame, self.rows, self.columns, frameScaleW, frameScaleH);
end

local function SetTextureViaFrames(self, texture)
    self:SetTexture(texture .. format("%03d", 0));
    self:SetTexCoord(0, 1, 0, 1);
end

local function SetFrameViaFrames(self, texture, frame)
    self:SetTexture(texture .. format("%03d", frame));
end

local function modify(parent, region, data)
    WeakAuras.regionPrototype.modify(parent, region, data);
    region.foreground = region.foreground or {}
    region.background = region.background or {}
    local pattern = "%.x(%d+)y(%d+)f(%d+)%.[tb][gl][ap]"
    local pattern2 = "%.x(%d+)y(%d+)f(%d+)w(%d+)h(%d+)W(%d+)H(%d+)%.[tb][gl][ap]"

    do
      local tdata = texture_data[data.foregroundTexture];
      if (tdata) then
        local lastFrame = tdata.count - 1;
        region.foreground.lastFrame = lastFrame
        region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
        region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
        region.foreground.rows = tdata.rows;
        region.foreground.columns = tdata.columns;
        region.foreground.fileWidth = 0
        region.foreground.fileHeight = 0
        region.foreground.frameWidth = 0
        region.foreground.frameHeight = 0
      else
        local rows, columns, frames = data.foregroundTexture:lower():match(pattern)
        if rows then
          local lastFrame = tonumber(frames) - 1;
          region.foreground.lastFrame = lastFrame
          region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
          region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
          region.foreground.rows = tonumber(rows)
          region.foreground.columns = tonumber(columns)
          region.foreground.fileWidth = 0
          region.foreground.fileHeight = 0
          region.foreground.frameWidth = 0
          region.foreground.frameHeight = 0
        else
          local rows, columns, frames, frameWidth, frameHeight, fileWidth, fileHeight = data.foregroundTexture:match(pattern2)
          if rows then
            local lastFrame = tonumber(frames) - 1;
            region.foreground.lastFrame = lastFrame
            region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
            region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
            region.foreground.rows = tonumber(rows)
            region.foreground.columns = tonumber(columns)
            region.foreground.fileWidth = tonumber(fileWidth)
            region.foreground.fileHeight = tonumber(fileHeight)
            region.foreground.frameWidth = tonumber(frameWidth)
            region.foreground.frameHeight = tonumber(frameHeight)
          else
            local lastFrame = (data.customForegroundFrames or 256) - 1;
            region.foreground.lastFrame = lastFrame
            region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
            region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
            region.foreground.rows = data.customForegroundRows;
            region.foreground.columns = data.customForegroundColumns;
            region.foreground.fileWidth = data.customForegroundFileWidth
            region.foreground.fileHeight = data.customForegroundFileHeight
            region.foreground.frameWidth = data.customForegroundFrameWidth
            region.foreground.frameHeight = data.customForegroundFrameHeight
          end
        end
      end
    end

    local backgroundTexture = data.sameTexture
                             and data.foregroundTexture
                             or data.backgroundTexture;

    do
      if data.sameTexture then
        region.backgroundFrame = floor( (data.backgroundPercent or 1) * region.foreground.lastFrame + 1);
        region.background.rows = region.foreground.rows
        region.background.columns = region.foreground.columns
        region.background.fileWidth = region.foreground.fileWidth
        region.background.fileHeight = region.foreground.fileHeight
        region.background.frameWidth = region.foreground.frameWidth
        region.background.frameHeight = region.foreground.frameHeight
      else
        local tdata = texture_data[data.backgroundTexture];
        if (tdata) then
          local lastFrame = tdata.count - 1;
          region.backgroundFrame = floor( (data.backgroundPercent or 1) * lastFrame + 1);
          region.background.rows = tdata.rows;
          region.background.columns = tdata.columns;
          region.background.fileWidth = 0
          region.background.fileHeight = 0
          region.background.frameWidth = 0
          region.background.frameHeight = 0
        else
          local rows, columns, frames = data.backgroundTexture:lower():match(pattern)
          if rows then
            local lastFrame = frames - 1;
            region.backgroundFrame = floor( (data.backgroundPercent or 1) * lastFrame + 1);
            region.background.rows = tonumber(rows)
            region.background.columns = tonumber(columns)
            region.background.fileWidth = 0
            region.background.fileHeight = 0
            region.background.frameWidth = 0
            region.background.frameHeight = 0
          else
            local rows, columns, frames, frameWidth, frameHeight, fileWidth, fileHeight = data.backgroundTexture:match(pattern2)
            if rows then
              local lastFrame = frames - 1;
              region.backgroundFrame = floor( (data.backgroundPercent or 1) * lastFrame + 1);
              region.background.rows = tonumber(rows)
              region.background.columns = tonumber(columns)
              region.background.fileWidth = tonumber(fileWidth)
              region.background.fileHeight = tonumber(fileHeight)
              region.background.frameWidth = tonumber(frameWidth)
              region.background.frameHeight = tonumber(frameHeight)
            else
              local lastFrame = (data.customBackgroundFrames or 256) - 1;
              region.backgroundFrame = floor( (data.backgroundPercent or 1) * lastFrame + 1);
              region.background.rows = data.customBackgroundRows;
              region.background.columns = data.customBackgroundColumns;
              region.background.fileWidth = data.customBackgroundFileWidth
              region.background.fileHeight = data.customBackgroundFileHeight
              region.background.frameWidth = data.customBackgroundFrameWidth
              region.background.frameHeight = data.customBackgroundFrameHeight
            end
          end
        end
      end
    end

    if (region.foreground.rows and region.foreground.columns) then
      region.foreground.SetBaseTexture = SetTextureViaAtlas;
      region.foreground.SetFrame = SetFrameViaAtlas;
    else
      region.foreground.SetBaseTexture = SetTextureViaFrames;
      region.foreground.SetFrame = SetFrameViaFrames;
    end

    if (region.background.rows and region.background.columns) then
      region.background.SetBaseTexture = SetTextureViaAtlas;
      region.background.SetFrame = SetFrameViaAtlas;
    else
      region.background.SetBaseTexture = SetTextureViaFrames;
      region.background.SetFrame = SetFrameViaFrames;
    end


    region.background:SetBaseTexture(backgroundTexture);
    region.background:SetFrame(backgroundTexture, region.backgroundFrame or 1);
    region.background:SetDesaturated(data.desaturateBackground)
    region.background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
    region.background:SetBlendMode(data.blendMode);

    if (data.hideBackground) then
      region.background:Hide();
    else
      region.background:Show();
    end

    region.foreground:SetBaseTexture(data.foregroundTexture);
    region.foreground:SetFrame(data.foregroundTexture, 1);
    region.foreground:SetDesaturated(data.desaturateForeground);
    region.foreground:SetBlendMode(data.blendMode);

    region:SetWidth(data.width);
    region:SetHeight(data.height);
    region.width = data.width;
    region.height = data.height;
    region.scalex = 1;
    region.scaley = 1;

    function region:Scale(scalex, scaley)
        region.scalex = scalex;
        region.scaley = scaley;
        if(scalex < 0) then
            region.mirror_h = true;
            scalex = scalex * -1;
        else
            region.mirror_h = nil;
        end
        region:SetWidth(region.width * scalex);
        if(scaley < 0) then
            scaley = scaley * -1;
            region.mirror_v = true;
        else
            region.mirror_v = nil;
        end
        region:SetHeight(region.height * scaley);
    end

    function region:Color(r, g, b, a)
      region.color_r = r;
      region.color_g = g;
      region.color_b = b;
      region.color_a = a;
      if (r or g or b) then
        a = a or 1;
      end
      region.foreground:SetVertexColor(region.color_anim_r or r, region.color_anim_g or g, region.color_anim_b or b, region.color_anim_a or a);
    end

    function region:ColorAnim(r, g, b, a)
      region.color_anim_r = r;
      region.color_anim_g = g;
      region.color_anim_b = b;
      region.color_anim_a = a;
      if (r or g or b) then
        a = a or 1;
      end
      region.foreground:SetVertexColor(r or region.color_r, g or region.color_g, b or region.color_b, a or region.color_a);
    end

    function region:GetColor()
      return region.color_r or data.color[1], region.color_g or data.color[2],
        region.color_b or data.color[3], region.color_a or data.color[4];
    end

    region:Color(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);

    function region:PreShow()
      region.startTime = GetTime();
    end

    local function onUpdate()
      if (not region.startTime) then return end

      Private.StartProfileAura(region.id);
      Private.StartProfileSystem("stopmotion")
      local timeSinceStart = (GetTime() - region.startTime);
      local newCurrentFrame = floor(timeSinceStart * (data.frameRate or 15));
      if (newCurrentFrame == region.currentFrame) then
        Private.StopProfileAura(region.id);
        Private.StopProfileSystem("stopmotion")
        return;
      end

      region.currentFrame = newCurrentFrame;

      local frames;
      local startFrame = region.startFrame;
      local endFrame = region.endFrame;
      local inverse = data.inverse;
      if (endFrame >= startFrame) then
        frames = endFrame - startFrame + 1;
      else
        frames = startFrame - endFrame + 1;
        startFrame, endFrame = endFrame, startFrame;
        inverse = not inverse;
      end

      local frame = 0;
      if (data.animationType == "loop") then
          frame = (newCurrentFrame % frames) + startFrame;
      elseif (data.animationType == "bounce") then
          local direction = floor(newCurrentFrame / frames) % 2;
          if (direction == 0) then
              frame = (newCurrentFrame % frames) + startFrame;
          else
              frame = endFrame - (newCurrentFrame % frames);
          end
      elseif (data.animationType == "once") then
          frame = newCurrentFrame + startFrame
          if (frame > endFrame) then
            frame = endFrame;
          end
      elseif (data.animationType == "progress") then
        if (not region.state) then
          -- Do nothing
        elseif (region.state.progressType == "static") then
          local value = region.state.value or 0
          local total = region.state.total ~= 0 and region.state.total or 1
          frame = floor((frames - 1) * value / total) + startFrame;
        else
          local remaining
          if region.state.paused then
            remaining = region.state.remaining or 0;
          else
            remaining = region.state.expirationTime and (region.state.expirationTime - GetTime()) or 0;
          end
          local progress = region.state.duration and region.state.duration > 0 and (1 - (remaining / region.state.duration)) or 0;
          frame = floor( (frames - 1) * progress) + startFrame;
        end
      end

      if (inverse) then
        frame = endFrame - frame + startFrame;
      end

      if (frame > endFrame) then
        frame = endFrame
         end
      if (frame < startFrame) then
        frame = startFrame
      end
      region.foreground:SetFrame(data.foregroundTexture, frame);

      Private.StopProfileAura(region.id);
      Private.StopProfileSystem("stopmotion")
    end;

    region.FrameTick = onUpdate;

    function region:Update()
      if region.state.paused then
        if not region.paused then
          region:Pause()
        end
      else
        if region.paused then
          region:Resume()
        end
      end
      onUpdate();
    end

    function region:SetForegroundDesaturated(b)
      region.foreground:SetDesaturated(b);
    end

    function region:SetBackgroundDesaturated(b)
      region.background:SetDesaturated(b);
    end

    function region:SetBackgroundColor(r, g, b, a)
      region.background:SetVertexColor(r, g, b, a);
    end

    function region:SetRegionWidth(width)
      region.width = width;
      region:Scale(region.scalex, region.scaley);
    end

    function region:SetRegionHeight(height)
      region.height = height;
      region:Scale(region.scalex, region.scaley);
    end
end

local function validate(data)
  Private.EnforceSubregionExists(data, "subbackground")
end

WeakAuras.RegisterRegionType("stopmotion", create, modify, default, properties, validate);
