local default = {
    foregroundTexture = "Interface\\AddOns\\WeakAuras\\Media\\StopMotion\\circle",
    backgroundTexture = "Interface\\AddOns\\WeakAuras\\Media\\StopMotion\\circle",
    backgroundFrame = 101,
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
    xOffset = 0,
    yOffset = 0,
    frameStrata = 1,
    startFrame = 1,
    endFrame = 9,
    frameRate = 15,
    animationType = "progress",
    inverse = false
};

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

    frame.duration = 0;
    frame.expirationTime = math.huge;
    return frame;
end

local function modify(parent, region, data)
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

    region.background:SetTexture((data.sameTexture
                             and data.foregroundTexture
                             or data.backgroundTexture) .. format("%03d", data.backgroundFrame or 0));
    region.background:SetDesaturated(data.desaturateBackground)
    region.background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
    region.background:SetBlendMode(data.blendMode);

    region.foreground:SetDesaturated(data.desaturateForeground);
    region.foreground:SetBlendMode(data.blendMode);

    region:SetWidth(data.width);
    region:SetHeight(data.height);
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);

    local function GetRotatedPoints(degrees)
        local angle = rad(135 - degrees);
        local vx = math.cos(angle);
        local vy = math.sin(angle);

        return 0.5+vx,0.5-vy , 0.5-vy,0.5-vx , 0.5+vy,0.5+vx , 0.5-vx,0.5+vy
    end

    local function DoTexCoord()
        local mirror_h, mirror_v = region.mirror_h, region.mirror_v;
        if(data.mirror) then
            mirror_h = not mirror_h;
        end
        local ulx,uly , llx,lly , urx,ury , lrx,lry;
        if(data.rotate) then
            ulx,uly , llx,lly , urx,ury , lrx,lry = GetRotatedPoints(region.rotation);
        else
            if(data.discrete_rotation == 0 or data.discrete_rotation == 360) then
                ulx,uly , llx,lly , urx,ury , lrx,lry = 0,0 , 0,1 , 1,0 , 1,1;
            elseif(data.discrete_rotation == 90) then
                ulx,uly , llx,lly , urx,ury , lrx,lry = 1,0 , 0,0 , 1,1 , 0,1;
            elseif(data.discrete_rotation == 180) then
                ulx,uly , llx,lly , urx,ury , lrx,lry = 1,1 , 1,0 , 0,1 , 0,0;
            elseif(data.discrete_rotation == 270) then
                ulx,uly , llx,lly , urx,ury , lrx,lry = 0,1 , 1,1 , 0,0 , 1,0;
            end
        end
        if(mirror_h) then
            if(mirror_v) then
                region.foreground:SetTexCoord(lrx,lry , urx,ury , llx,lly , ulx,uly);
                region.background:SetTexCoord(lrx,lry , urx,ury , llx,lly , ulx,uly);
            else
                region.foreground:SetTexCoord(urx,ury , lrx,lry , ulx,uly , llx,lly);
                region.background:SetTexCoord(urx,ury , lrx,lry , ulx,uly , llx,lly);
            end
        else
            if(mirror_v) then
                region.foreground:SetTexCoord(llx,lly , ulx,uly , lrx,lry , urx,ury);
                region.background:SetTexCoord(llx,lly , ulx,uly , lrx,lry , urx,ury);
            else
                region.foreground:SetTexCoord(ulx,uly , llx,lly , urx,ury , lrx,lry);
                region.background:SetTexCoord(ulx,uly , llx,lly , urx,ury , lrx,lry);
            end
        end
    end

    region.rotation = data.rotation;
    DoTexCoord();

    function region:Scale(scalex, scaley)
        if(scalex < 0) then
            region.mirror_h = true;
            scalex = scalex * -1;
        else
            region.mirror_h = nil;
        end
        region:SetWidth(data.width * scalex);
        if(scaley < 0) then
            scaley = scaley * -1;
            region.mirror_v = true;
        else
            region.mirror_v = nil;
        end
        region:SetHeight(data.height * scaley);

        DoTexCoord();
    end

    function region:Color(r, g, b, a)
        region.foregroundColor_r = r;
        region.foregroundColor_g = g;
        region.foregroundColor_b = b;
        region.foregroundColor_a = a;
        region.foreground:SetVertexColor(r, g, b, a);
    end

    function region:GetColor()
        return region.foregroundColor_r or data.foregroundColor[1], region.foregroundColor_g or data.foregroundColor[2],
               region.foregroundColor_b or data.foregroundColor[3], region.foregroundColor_a or data.foregroundColor[4];
    end

    region:Color(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);

    if(data.rotate) then
        function region:Rotate(degrees)
            region.rotation = degrees;
            DoTexCoord();
        end

        function region:GetRotation()
            return region.rotation;
        end
    else
        region.Rotate = nil;
        region.GetRotation = nil;
    end
    local function UpdateValue(value, total)
        region.progress = value;
        region.duration = total;
    end

    function region:PreShow()
      region.startTime = GetTime();
    end

    local function onUpdate()
      if (not region.startTime) then return end
      local timeSinceStart = (GetTime() - region.startTime);
      local newCurrentFrame = floor(timeSinceStart * (data.frameRate or 15));
      if (newCurrentFrame == region.currentFrame) then
          return;
      end

      region.currentFrame = newCurrentFrame;

      local frames;
      local startFrame = data.startFrame;
      local endFrame = data.endFrame;
      local inverse = data.inverse;
      if (data.endFrame >= data.startFrame) then
        frames = data.endFrame - data.startFrame + 1;
      else
        frames = data.startFrame - data.endFrame + 1;
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
        if (region.customValueFunc) then
          UpdateValue(region.customValueFunc(data.trigger));
        end
        if (region.mode == "progress") then
          local progress = region.progress or 0
          local duration = region.duration ~= 0 and region.duration or 1
          frame = floor((frames - 1) * progress / duration) + startFrame;
        else
          local remaining = region.expirationTime - GetTime();
          local progress = 1 - (remaining / region.duration);
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
      local path = data.foregroundTexture .. format("%03d", frame);
      region.foreground:SetTexture(path)
    end;
    region:SetScript("OnUpdate", onUpdate);

    function region:SetDurationInfo(duration, expirationTime, customValue)
        if (not duration or not expirationTime) then return end
        if(duration <= 0.01 or duration > region.duration or not data.stickyDuration) then
            region.duration = duration;
        end
        region.expirationTime = expirationTime;
        region.customValueFunc = nil;

        if(customValue) then
            region.mode = "progress";
            if(type(customValue) == "function") then
                local value, total = customValue(data.trigger);
                if(total > 0 and value <= total) then
                    region.customValueFunc = customValue;
                else
                    UpdateValue(duration, expirationTime);
                end
                onUpdate();
            else
                UpdateValue(duration, expirationTime);
                onUpdate();
            end
        else
            region.mode = "time";
            onUpdate();
        end
    end
end

WeakAuras.RegisterRegionType("stopmotion", create, modify, default);
