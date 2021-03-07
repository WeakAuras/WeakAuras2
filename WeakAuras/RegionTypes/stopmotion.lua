if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

local texture_types = WeakAuras.StopMotion.texture_types;
local texture_data = WeakAuras.StopMotion.texture_data;
local animation_types = WeakAuras.StopMotion.animation_types;
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
    local frame = CreateFrame("FRAME", nil, UIParent);
    frame:SetMovable(true);
    frame:SetResizable(true);
    frame:SetMinResize(1, 1);

    local background = frame:CreateTexture(nil, "BACKGROUND");
    frame.background = background;
    background:SetAllPoints(frame);

    local foreground = frame:CreateTexture(nil, "ART");
    frame.foreground = foreground;
    foreground:SetAllPoints(frame);

    WeakAuras.regionPrototype.create(frame);

    return frame;
end

local function SetTextureViaAtlas(self, texture)
  self:SetTexture(texture);
end

local function setTile(texture, frame, rows, columns )
  frame = frame - 1;
  local row = floor(frame / columns);
  local column = frame % columns;

  local deltaX = 1 / columns;
  local deltaY = 1 / rows;

  local left = deltaX * column;
  local right = left + deltaX;

  local top = deltaY * row;
  local bottom = top + deltaY;

  texture:SetTexCoord(left, right, top, bottom);
end

WeakAuras.setTile = setTile;

local function SetFrameViaAtlas(self, texture, frame)
  setTile(self, frame, self.rows, self.columns);
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

    local pattern = "%.x(%d+)y(%d+)f(%d+)%.[tb][gl][ap]"
    local tdata = texture_data[data.foregroundTexture];
    if (tdata) then
      local lastFrame = tdata.count - 1;
      region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
      region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
      region.foreground.rows = tdata.rows;
      region.foreground.columns = tdata.columns;
    else
      local rows, columns, frames = data.foregroundTexture:lower():match(pattern)
      if rows and columns and frames then
        local lastFrame = frames - 1;
        region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
        region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
        region.foreground.rows = rows;
        region.foreground.columns = columns;
      else
        local lastFrame = (data.customForegroundFrames or 256) - 1;
        region.startFrame = floor( (data.startPercent or 0) * lastFrame) + 1;
        region.endFrame = floor( (data.endPercent or 1) * lastFrame) + 1;
        region.foreground.rows = data.customForegroundRows;
        region.foreground.columns = data.customForegroundColumns;
      end
    end

    local backgroundTexture = data.sameTexture
                             and data.foregroundTexture
                             or data.backgroundTexture;

    local tbdata = texture_data[backgroundTexture];
    if (tbdata) then
      local lastFrame = tbdata.count - 1;
      region.backgroundFrame = floor( (data.backgroundPercent or 1) * lastFrame + 1);
      region.background.rows = tbdata.rows;
      region.background.columns = tbdata.columns;
    else
      local rows, columns, frames = backgroundTexture:lower():match(pattern)
      if rows and columns and frames then
        local lastFrame = frames - 1;
        region.backgroundFrame = floor( (data.backgroundPercent or 1) * lastFrame + 1);
        region.background.rows = rows;
        region.background.columns = columns;
      else
        local lastFrame = (data.sameTexture and data.customForegroundFrames
                                            or data.customBackgroundFrames or 256) - 1;
        region.backgroundFrame = floor( (data.backgroundPercent or 1) * lastFrame + 1);
        region.background.rows = data.sameTexture and data.customForegroundRows
                                                  or data.customBackgroundRows;
        region.background.columns = data.sameTexture and data.customForegroundColumns
                                                    or data.customBackgroundColumns;
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

WeakAuras.RegisterRegionType("stopmotion", create, modify, default, properties);
