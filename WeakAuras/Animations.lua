if not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...
local L = WeakAuras.L

-- Animations
local animations = {}
local pending_controls = {}
local anim_function_strings = Private.anim_function_strings;

local function noopErrorHandler() end

local frame = WeakAuras.frames["WeakAuras Main Frame"]

local updatingAnimations;
local last_update = GetTime();
local function UpdateAnimations()
  Private.StartProfileSystem("animations");

  for groupUid, groupRegion in pairs(pending_controls) do
    pending_controls[groupUid] = nil;
    groupRegion:DoPositionChildren();
  end

  local time = GetTime();
  local elapsed = time - last_update;
  last_update = time;
  local num = 0;
  for key, anim in pairs(animations) do
    Private.StartProfileUID(anim.auraUID);
    num = num + 1;
    local finished = false;
    if(anim.duration_type == "seconds") then
      if anim.duration > 0 then
        anim.progress = anim.progress + (elapsed / anim.duration);
      else
        anim.progress = anim.progress + (elapsed / 1);
      end
      if(anim.progress >= 1) then
        anim.progress = 1;
        finished = true;
      end
    elseif(anim.duration_type == "relative") then
      local state = anim.region.state;
      if (not state
        or (state.progressType == "timed" and state.duration < 0.01)
        or (state.progressType == "static" and state.value < 0.01)) then
        anim.progress = 0;
        if(anim.type == "start" or anim.type == "finish") then
          finished = true;
        end
      else
        local relativeProgress = 0;
        if(state.progressType == "static") then
          relativeProgress = state.value / state.total;
        elseif (state.progressType == "timed") then
          relativeProgress = 1 - ((state.expirationTime - time) / state.duration);
        end
        relativeProgress = state.inverse and (1 - relativeProgress) or relativeProgress;
        anim.progress = anim.duration > 0 and  relativeProgress / anim.duration or 0
        local iteration = math.floor(anim.progress);
        --anim.progress = anim.progress - iteration;
        if not(anim.iteration) then
          anim.iteration = iteration;
        elseif(anim.iteration ~= iteration) then
          anim.iteration = nil;
          finished = true;
        end
      end
    else
      anim.progress = 1;
    end
    local progress = anim.inverse and (1 - anim.progress) or anim.progress;
    progress = anim.easeFunc(progress, anim.easeStrength or 3)
    Private.ActivateAuraEnvironmentForRegion(anim.region)
    if(anim.translateFunc) then
      local errorHandler = WeakAuras.IsOptionsOpen() and noopErrorHandler or Private.GetErrorHandlerUid(anim.auraUID, L["Slide Animation"])
      if (anim.region.SetOffsetAnim) then
        local ok, x, y = xpcall(anim.translateFunc, errorHandler, progress, 0, 0, anim.dX, anim.dY);
        anim.region:SetOffsetAnim(x, y);
      else
        anim.region:ClearAllPoints();
        local ok, x, y = xpcall(anim.translateFunc, errorHandler, progress, anim.startX, anim.startY, anim.dX, anim.dY);
        if (ok) then
          anim.region:SetPoint(anim.selfPoint, anim.anchor, anim.anchorPoint, x, y);
        end
      end
    end
    if(anim.alphaFunc) then
      local errorHandler = WeakAuras.IsOptionsOpen() and noopErrorHandler or Private.GetErrorHandlerUid(anim.auraUID, L["Fade Animation"])
      local ok, alpha = xpcall(anim.alphaFunc, errorHandler, progress, anim.startAlpha, anim.dAlpha);
      if (ok) then
        if (anim.region.SetAnimAlpha) then
          anim.region:SetAnimAlpha(alpha);
        else
          anim.region:SetAlpha(alpha);
        end
      end
    end
    if(anim.scaleFunc) then
      local errorHandler = WeakAuras.IsOptionsOpen() and noopErrorHandler or Private.GetErrorHandlerUid(anim.auraUID, L["Zoom Animation"])
      local ok, scaleX, scaleY = xpcall(anim.scaleFunc, errorHandler, progress, 1, 1, anim.scaleX, anim.scaleY);
      if (ok) then
        if(anim.region.Scale) then
          anim.region:Scale(scaleX, scaleY);
        else
          anim.region:SetWidth(anim.startWidth * scaleX);
          anim.region:SetHeight(anim.startHeight * scaleY);
        end
      end
    end
    if(anim.rotateFunc and anim.region.Rotate) then
      local errorHandler = WeakAuras.IsOptionsOpen() and noopErrorHandler or Private.GetErrorHandlerUid(anim.auraUID, L["Rotate Animation"])
      local ok, rotate = xpcall(anim.rotateFunc, errorHandler, progress, anim.startRotation, anim.rotate);
      if (ok) then
        anim.region:Rotate(rotate);
      end
    end
    if(anim.colorFunc and anim.region.ColorAnim) then
      local errorHandler = WeakAuras.IsOptionsOpen() and noopErrorHandler or Private.GetErrorHandlerUid(anim.auraUID, L["Color Animation"])
      local startR, startG, startB, startA = anim.region:GetColor();
      startR, startG, startB, startA = startR or 1, startG or 1, startB or 1, startA or 1;
      local ok, r, g, b, a = xpcall(anim.colorFunc, errorHandler, progress, startR, startG, startB, startA, anim.colorR, anim.colorG, anim.colorB, anim.colorA);
      if (ok) then
        anim.region:ColorAnim(r, g, b, a);
      end
    end
    Private.ActivateAuraEnvironment(nil);
    if(finished) then
      if not(anim.loop) then
        if (anim.region.SetOffsetAnim) then
          anim.region:SetOffsetAnim(0, 0);
        else
          if(anim.startX) then
            anim.region:SetPoint(anim.selfPoint, anim.anchor, anim.anchorPoint, anim.startX, anim.startY);
          end
        end
        if (anim.region.SetAnimAlpha) then
          anim.region:SetAnimAlpha(nil);
        elseif(anim.startAlpha) then
          anim.region:SetAlpha(anim.startAlpha);
        end
        if(anim.startWidth) then
          if(anim.region.Scale) then
            anim.region:Scale(1, 1);
          else
            anim.region:SetWidth(anim.startWidth);
            anim.region:SetHeight(anim.startHeight);
          end
        end
        if(anim.startRotation) then
          if(anim.region.Rotate) then
            anim.region:Rotate(anim.startRotation);
          end
        end
        if(anim.region.ColorAnim) then
          anim.region:ColorAnim(nil);
        end
        animations[key] = nil;
      end

      if(anim.loop) then
        Private.Animate(anim.namespace, anim.auraUID, anim.type, anim.anim, anim.region, anim.inverse, anim.onFinished, anim.loop, anim.region.cloneId);
      elseif(anim.onFinished) then
        anim.onFinished();
      end
    end
    Private.StopProfileUID(anim.auraUID);
  end

  Private.StopProfileSystem("animations");
end

function Private.RegisterGroupForPositioning(uid, region)
  pending_controls[uid] = region
  updatingAnimations = true
  frame:SetScript("OnUpdate", UpdateAnimations)
end

function Private.Animate(namespace, uid, type, anim, region, inverse, onFinished, loop, cloneId)
  local auraDisplayName = Private.UIDtoID(uid)
  local key = tostring(region);
  local valid;
  if(anim and anim.type == "custom" and (anim.use_translate or anim.use_alpha or (anim.use_scale and region.Scale) or (anim.use_rotate and region.Rotate) or (anim.use_color and region.Color))) then
    valid = true;
  elseif(anim and anim.type == "preset" and anim.preset and Private.anim_presets[anim.preset]) then
    anim = Private.anim_presets[anim.preset];
    valid = true;
  end
  if(valid) then
    local progress, duration, selfPoint, anchor, anchorPoint, startX, startY, startAlpha, startWidth, startHeight, startRotation, easeType, easeStrength;
    local translateFunc, alphaFunc, scaleFunc, rotateFunc, colorFunc, easeFunc;
    if(animations[key]) then
      if(animations[key].type == type and not loop) then
        return "no replace";
      end
      anim.x = anim.x or 0;
      anim.y = anim.y or 0;
      selfPoint, anchor, anchorPoint, startX, startY = animations[key].selfPoint, animations[key].anchor, animations[key].anchorPoint, animations[key].startX, animations[key].startY;
      anim.alpha = anim.alpha or 0;
      startAlpha = animations[key].startAlpha;
      anim.scalex = anim.scalex or 1;
      anim.scaley = anim.scaley or 1;
      startWidth, startHeight = animations[key].startWidth, animations[key].startHeight;
      anim.rotate = anim.rotate or 0;
      startRotation = animations[key].startRotation;
      anim.colorR = anim.colorR or 1;
      anim.colorG = anim.colorG or 1;
      anim.colorB = anim.colorB or 1;
      anim.colorA = anim.colorA or 1;
    else
      anim.x = anim.x or 0;
      anim.y = anim.y or 0;
      if not region.SetOffsetAnim then
        selfPoint, anchor, anchorPoint, startX, startY = region:GetPoint(1);
      end
      anim.alpha = anim.alpha or 0;
      startAlpha = region:GetAlpha();
      anim.scalex = anim.scalex or 1;
      anim.scaley = anim.scaley or 1;
      startWidth, startHeight = region:GetWidth(), region:GetHeight();
      anim.rotate = anim.rotate or 0;
      startRotation = region.GetRotation and region:GetRotation() or 0;
      anim.colorR = anim.colorR or 1;
      anim.colorG = anim.colorG or 1;
      anim.colorB = anim.colorB or 1;
      anim.colorA = anim.colorA or 1;
    end

    if(anim.use_translate) then
      if not(anim.translateType == "custom" and anim.translateFunc) then
        anim.translateType = anim.translateType or "straightTranslate";
        anim.translateFunc = anim_function_strings[anim.translateType]
      end
      if (anim.translateFunc) then
        translateFunc = WeakAuras.LoadFunction("return " .. anim.translateFunc);
      else
        if (region.SetOffsetAnim) then
          region:SetOffsetAnim(0, 0);
        else
          region:SetPoint(selfPoint, anchor, anchorPoint, startX, startY);
        end
      end
    else
      if (region.SetOffsetAnim) then
        region:SetOffsetAnim(0, 0);
      else
        region:SetPoint(selfPoint, anchor, anchorPoint, startX, startY);
      end
    end
    if(anim.use_alpha) then
      if not(anim.alphaType == "custom" and anim.alphaFunc) then
        anim.alphaType = anim.alphaType or "straight";
        anim.alphaFunc = anim_function_strings[anim.alphaType]
      end
      if (anim.alphaFunc) then
        alphaFunc = WeakAuras.LoadFunction("return " .. anim.alphaFunc);
      else
        if (region.SetAnimAlpha) then
          region:SetAnimAlpha(nil);
        else
          region:SetAlpha(startAlpha);
        end
      end
    else
      if (region.SetAnimAlpha) then
        region:SetAnimAlpha(nil);
      else
        region:SetAlpha(startAlpha);
      end
    end
    if(anim.use_scale) then
      if not(anim.scaleType == "custom" and anim.scaleFunc) then
        anim.scaleType = anim.scaleType or "straightScale";
        anim.scaleFunc = anim_function_strings[anim.scaleType]
      end
      if (anim.scaleFunc) then
        scaleFunc = WeakAuras.LoadFunction("return " .. anim.scaleFunc);
      else
        region:Scale(1, 1);
      end
    elseif(region.Scale) then
      region:Scale(1, 1);
    end
    if(anim.use_rotate) then
      if not(anim.rotateType == "custom" and anim.rotateFunc) then
        anim.rotateType = anim.rotateType or "straight";
        anim.rotateFunc = anim_function_strings[anim.rotateType]
      end
      if (anim.rotateFunc) then
        rotateFunc = WeakAuras.LoadFunction("return " .. anim.rotateFunc);
      else
        region:Rotate(startRotation);
      end
    elseif(region.Rotate) then
      region:Rotate(startRotation);
    end
    if(anim.use_color) then
      if not(anim.colorType == "custom" and anim.colorFunc) then
        anim.colorType = anim.colorType or "straightColor";
        anim.colorFunc = anim_function_strings[anim.colorType]
      end
      if (anim.colorFunc) then
        colorFunc = WeakAuras.LoadFunction("return " .. anim.colorFunc);
      else
        region:ColorAnim(nil);
      end
    elseif(region.ColorAnim) then
      region:ColorAnim(nil);
    end
    easeFunc = Private.anim_ease_functions[anim.easeType or "none"]

    duration = Private.ParseNumber(anim.duration) or 0;
    progress = 0;
    if(namespace == "display" and type == "main" and not onFinished and not anim.duration_type == "relative") then
      local data = Private.GetDataByUID(uid);
      if(data and data.parent) then
        local parentRegion = WeakAuras.regions[data.parent].region;
        if(parentRegion and parentRegion.controlledRegions) then
          for index, regionData in pairs(parentRegion.controlledRegions) do
            local childRegion = regionData.region;
            local childKey = regionData.key;
            if(childKey and childKey ~= tostring(region) and animations[childKey] and animations[childKey].type == "main" and duration == animations[childKey].duration) then
              progress = animations[childKey].progress;
              break;
            end
          end
        end
      end
    end

    local animation = animations[key] or {}
    animations[key] = animation

    animation.progress = progress
    animation.startX = startX
    animation.startY = startY
    animation.startAlpha = startAlpha
    animation.startWidth = startWidth
    animation.startHeight = startHeight
    animation.startRotation = startRotation
    animation.dX = (anim.use_translate and anim.x)
    animation.dY = (anim.use_translate and anim.y)
    animation.dAlpha = (anim.use_alpha and (anim.alpha - startAlpha))
    animation.scaleX = (anim.use_scale and anim.scalex)
    animation.scaleY = (anim.use_scale and anim.scaley)
    animation.rotate = anim.rotate
    animation.colorR = (anim.use_color and anim.colorR)
    animation.colorG = (anim.use_color and anim.colorG)
    animation.colorB = (anim.use_color and anim.colorB)
    animation.colorA = (anim.use_color and anim.colorA)
    animation.translateFunc = translateFunc
    animation.alphaFunc = alphaFunc
    animation.scaleFunc = scaleFunc
    animation.rotateFunc = rotateFunc
    animation.colorFunc = colorFunc
    animation.region = region
    animation.selfPoint = selfPoint
    animation.anchor = anchor
    animation.anchorPoint = anchorPoint
    animation.duration = duration
    animation.duration_type = anim.duration_type or "seconds"
    animation.inverse = inverse
    animation.easeType = anim.easeType
    animation.easeFunc = easeFunc
    animation.easeStrength = anim.easeStrength
    animation.type = type
    animation.loop = loop
    animation.onFinished = onFinished
    animation.namespace = namespace;
    animation.anim = anim;
    animation.auraUID = uid

    if not(updatingAnimations) then
      frame:SetScript("OnUpdate", UpdateAnimations);
      updatingAnimations = true;
    end
    return true;
  else
    if(animations[key]) then
      if(animations[key].type ~= type or loop) then
        Private.CancelAnimation(region, true, true, true, true, true);
      end
    end
    return false;
  end
end

function Private.CancelAnimation(region, resetPos, resetAlpha, resetScale, resetRotation, resetColor, doOnFinished)
  local key = tostring(region);
  local anim = animations[key];

  if(anim) then
    if(resetPos) then
      if (anim.region.SetOffsetAnim) then
        anim.region:SetOffsetAnim(0, 0);
      else
        anim.region:ClearAllPoints();
        anim.region:SetPoint(anim.selfPoint, anim.anchor, anim.anchorPoint, anim.startX, anim.startY);
      end
    end
    if(resetAlpha) then
      if (anim.region.SetAnimAlpha) then
        anim.region:SetAnimAlpha(nil);
      else
        anim.region:SetAlpha(anim.startAlpha);
      end
    end
    if(resetScale) then
      if(anim.region.Scale) then
        anim.region:Scale(1, 1);
      else
        anim.region:SetWidth(anim.startWidth);
        anim.region:SetHeight(anim.startHeight);
      end
    end
    if(resetRotation and anim.region.Rotate) then
      anim.region:Rotate(anim.startRotation);
    end
    if(resetColor and anim.region.ColorAnim) then
      anim.region:ColorAnim(nil);
    end

    animations[key] = nil;
    if(doOnFinished and anim.onFinished) then
      anim.onFinished();
    end
    return true;
  else
    return false;
  end
end
