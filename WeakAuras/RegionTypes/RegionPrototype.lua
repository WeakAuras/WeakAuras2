local WeakAuras = WeakAuras;
local L = WeakAuras.L;

WeakAuras.regionPrototype = {};

-- Alpha

function WeakAuras.regionPrototype.AddAlphaToDefault(default)
  default.alpha = 1.0;
end

-- Adjusted Duration

function WeakAuras.regionPrototype.AddAdjustedDurationToDefault(default)
  default.useAdjustededMax = false;
  default.useAdjustededMin = false;
end

function WeakAuras.regionPrototype.AddAdjustedDurationOptions(options, data, order)
  options.useAdjustededMin = {
    type = "toggle",
    width = WeakAuras.normalWidth,
    name = L["Set Minimum Progress"],
    desc = L["Values/Remaining Time below this value are displayed as no progress."],
    order = order
  };

  options.adjustedMin = {
    type = "range",
    width = WeakAuras.normalWidth,
    min = 0,
    softMax = 200,
    bigStep = 1,
    order = order + 0.01,
    name = L["Minimum"],
    hidden = function() return not data.useAdjustededMin end,
  };

  options.useAdjustedMinSpacer = {
    type = "description",
    width = WeakAuras.normalWidth,
    name = "",
    order = order + 0.02,
    hidden = function() return not (not data.useAdjustededMin and data.useAdjustededMax) end,
  };

  options.useAdjustededMax = {
    type = "toggle",
    width = WeakAuras.normalWidth,
    name = L["Set Maximum Progress"],
    desc = L["Values/Remaining Time above this value are displayed as full progress."],
    order = order + 0.03
  };

  options.adjustedMax = {
    type = "range",
    width = WeakAuras.normalWidth,
    min = 0,
    softMax = 200,
    bigStep = 1,
    order = order + 0.04,
    name = L["Maximum"],
    hidden = function() return not data.useAdjustededMax end,
  };

  options.useAdjustedMaxSpacer = {
    type = "description",
    width = WeakAuras.normalWidth,
    name = "",
    order = order + 0.05,
    hidden = function() return not (data.useAdjustededMin and not data.useAdjustededMax) end,
  };

  return options;
end

-- Sound / Chat Message / Custom Code
local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

function WeakAuras.regionPrototype.AddProperties(properties, defaultsForRegion)
  properties["sound"] = {
    display = L["Sound"],
    action = "SoundPlay",
    type = "sound",
  };
  properties["chat"] = {
    display = L["Chat Message"],
    action = "SendChat",
    type = "chat",
  };
  properties["customcode"] = {
    display = L["Run Custom Code"],
    action = "RunCode",
    type = "customcode"
  }
  properties["xOffset"] = {
    display = L["X-Offset"],
    setter = "SetXOffset",
    type = "number",
    softMin = -screenWidth,
    softMax = screenWidth,
    bigStep = 1
  }
  properties["yOffset"] = {
    display = L["Y-Offset"],
    setter = "SetYOffset",
    type = "number",
    softMin = -screenHeight,
    softMax = screenHeight,
    bigStep = 1
  }

  if (defaultsForRegion and defaultsForRegion.alpha) then
    properties["alpha"] = {
      display = L["Alpha"],
      setter = "SetRegionAlpha",
      type = "number",
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    }
  end
end

local function SoundRepeatStop(self)
  WeakAuras.StartProfileSystem("sound");
  if (self.soundRepeatTimer) then
    WeakAuras.timer:CancelTimer(self.soundRepeatTimer);
    self.soundRepeatTimer = nil;
  end
  WeakAuras.StopProfileSystem("sound");
end

local function SoundStop(self)
  WeakAuras.StartProfileSystem("sound");
  if (self.soundHandle) then
    StopSound(self.soundHandle);
  end
  WeakAuras.StopProfileSystem("sound");
end

local function SoundPlayHelper(self)
  WeakAuras.StartProfileSystem("sound");
  local options = self.soundOptions;
  self.soundHandle = nil;
  if (not options or options.sound_type == "Stop") then
    WeakAuras.StopProfileSystem("sound");
    return;
  end

  if (WeakAuras.IsOptionsOpen() or WeakAuras.SquelchingActions() or WeakAuras.InLoadingScreen()) then
    WeakAuras.StopProfileSystem("sound");
    return;
  end

  if (options.sound == " custom") then
    if (options.sound_path) then
      local _, handle = PlaySoundFile(options.sound_path, options.sound_channel or "Master");
      self.soundHandle = handle;
    end
  elseif (options.sound == " KitID") then
    if (options.sound_kit_id) then
      local _, handle = PlaySound(options.sound_kit_id, options.sound_channel or "Master");
      self.soundHandle = handle;
    end
  else
    local _, handle = PlaySoundFile(options.sound, options.sound_channel or "Master");
    self.soundHandle = handle;
  end
  WeakAuras.StopProfileSystem("sound");
end

local function SoundPlay(self, options)
  WeakAuras.StartProfileSystem("sound");
  self:SoundStop();
  self:SoundRepeatStop();

  self.soundOptions = options;
  SoundPlayHelper(self);

  local loop = options.do_loop or options.sound_type == "Loop";
  if (loop and options.sound_repeat and options.sound_repeat < WeakAuras.maxTimerDuration) then
    self.soundRepeatTimer = WeakAuras.timer:ScheduleRepeatingTimer(SoundPlayHelper, options.sound_repeat, self);
  end
  WeakAuras.StopProfileSystem("sound");
end

local function SendChat(self, options)
  if (not options) then
    return
  end
  WeakAuras.HandleChatAction(options.message_type, options.message, options.message_dest, options.message_channel, options.r, options.g, options.b, self, options.message_custom);
end

local function RunCode(self, func)
  if func then
    WeakAuras.ActivateAuraEnvironment(self.id, self.cloneId, self.state);
    xpcall(func, geterrorhandler());
    WeakAuras.ActivateAuraEnvironment(nil);
  end
end

local function UpdatePosition(self)
  if (not self.anchorPoint or not self.relativeTo or not self.relativePoint) then
    return;
  end

  local xOffset = self.xOffset + (self.xOffsetAnim or 0);
  local yOffset = self.yOffset + (self.yOffsetAnim or 0);

  xpcall(self.SetPoint, geterrorhandler(), self, self.anchorPoint, self.relativeTo, self.relativePoint, xOffset, yOffset);
end

local function ResetPosition(self)
  self.anchorPoint = nil;
  self.relativeTo = nil;
  self.relativePoint = nil;
end

local function SetAnchor(self, anchorPoint, relativeTo, relativePoint)
  local needsClearPoint = self.anchorPoint ~= anchorPoint or self.relativeTo ~= relativeTo or self.relativePoint ~= relativePoint;
  self.anchorPoint = anchorPoint;
  self.relativeTo = relativeTo;
  self.relativePoint = relativePoint;

  if (needsClearPoint) then
    self:ClearAllPoints();
  end

  UpdatePosition(self);
end

local function SetOffset(self, xOffset, yOffset)
  if (self.xOffset == xOffset and self.yOffset == yOffset) then
    return;
  end
  self.xOffset = xOffset;
  self.yOffset = yOffset;
  UpdatePosition(self);
end

local function SetXOffset(self, xOffset)
  self:SetOffset(xOffset, self:GetYOffset());
end

local function SetYOffset(self, yOffset)
  self:SetOffset(self:GetXOffset(), yOffset);
end

local function GetXOffset(self)
  return self.xOffset;
end

local function GetYOffset(self)
  return self.yOffset;
end

local function SetOffsetAnim(self, xOffset, yOffset)
  if (self.xOffsetAnim == xOffset and self.yOffsetAnim == yOffset) then
    return;
  end
  self.xOffsetAnim = xOffset;
  self.yOffsetAnim = yOffset;
  UpdatePosition(self);
end

local function SetRegionAlpha(self, alpha)
  if (self.alpha == alpha) then
    return;
  end

  self.alpha = alpha;
  self:SetAlpha(self.animAlpha or self.alpha or 1);
end

local function GetRegionAlpha(self)
  return self.animAlpha or self.alpha or 1;
end

local function SetAnimAlpha(self, alpha)
  if (self.animAlpha == alpha) then
    return;
  end
  self.animAlpha = alpha;
  self:SetAlpha(self.animAlpha or self.alpha or 1);
end

function WeakAuras.regionPrototype.create(region)
  region.SoundPlay = SoundPlay;
  region.SoundStop = SoundStop;
  region.SoundRepeatStop = SoundRepeatStop;
  region.SendChat = SendChat;
  region.RunCode = RunCode;

  region.SetAnchor = SetAnchor;
  region.SetOffset = SetOffset;
  region.SetXOffset = SetXOffset;
  region.SetYOffset = SetYOffset;
  region.SetOffsetAnim = SetOffsetAnim;
  region.GetXOffset = GetXOffset;
  region.GetYOffset = GetYOffset;
  region.ResetPosition = ResetPosition;
  region.SetRegionAlpha = SetRegionAlpha;
  region.GetRegionAlpha = GetRegionAlpha;
  region.SetAnimAlpha = SetAnimAlpha;
end

-- SetDurationInfo

function WeakAuras.regionPrototype.modify(parent, region, data)

  local defaultsForRegion = WeakAuras.regionTypes[data.regionType] and WeakAuras.regionTypes[data.regionType].default;
  if (defaultsForRegion and defaultsForRegion.alpha) then
    region:SetRegionAlpha(data.alpha);
  end
  local hasAdjustedMin = defaultsForRegion and defaultsForRegion.useAdjustededMin ~= nil and data.useAdjustededMin;
  local hasAdjustedMax = defaultsForRegion and defaultsForRegion.useAdjustededMax ~= nil and data.useAdjustededMax;

  if (hasAdjustedMin) then
    region.adjustedMin = data.adjustedMin and data.adjustedMin >= 0 and data.adjustedMin;
  else
    region.adjustedMin = nil;
  end
  if (hasAdjustedMax) then
    region.adjustedMax = data.adjustedMax and data.adjustedMax >= 0 and data.adjustedMax;
  else
    region.adjustedMax = nil;
  end
  region.inverse = false;

  region:SetOffset(data.xOffset or 0, data.yOffset or 0);
  region:SetOffsetAnim(0, 0);
  if not parent or parent.regionType ~= "dynamicgroup" then
    WeakAuras.AnchorFrame(data, region, parent);
  end
end

local function SetProgressValue(region, value, total)
  region.values.progress = value;
  region.values.duration = total;

  local adjustMin = region.adjustedMin or 0;
  local max = region.adjustedMax or total;

  region:SetValue(value - adjustMin, max - adjustMin);
end

local function UpateRegionValues(region)
  local remaining  = region.expirationTime - GetTime();
  local duration  = region.duration;
  local progressPrecision = region.progressPrecision and math.abs(region.progressPrecision) or 1

  local remainingStr     = "";
  if remaining == math.huge then
    remainingStr     = " ";
  elseif remaining > 60 then
    remainingStr     = string.format("%i:", math.floor(remaining / 60));
    remaining       = remaining % 60;
    remainingStr     = remainingStr..string.format("%02i", remaining);
  elseif remaining > 0 then
    if progressPrecision == 4 and remaining <= 3 then
      remainingStr = remainingStr..string.format("%.1f", remaining);
    elseif progressPrecision == 5 and remaining <= 3 then
      remainingStr = remainingStr..string.format("%.2f", remaining);
    elseif (progressPrecision == 4 or progressPrecision == 5) and remaining > 3 then
      remainingStr = remainingStr..string.format("%d", remaining);
    else
      remainingStr = remainingStr..string.format("%."..progressPrecision.."f", remaining);
    end
  else
    remainingStr     = " ";
  end
  region.values.progress   = remainingStr;

  -- Format a duration time string
  local durationStr     = "";
  if duration > 60 then
    durationStr     = string.format("%i:", math.floor(duration / 60));
    duration       = duration % 60;
    durationStr     = durationStr..string.format("%02i", duration);
  elseif duration > 0 then
    local totalPrecision = region.totalPrecision and math.abs(region.totalPrecision) or 1
    -- durationStr = durationStr..string.format("%."..(data.totalPrecision or 1).."f", duration);
    if region.totalPrecision == 4 and duration <= 3 then
      durationStr = durationStr..string.format("%.1f", duration);
    elseif region.totalPrecision == 5 and duration <= 3 then
      durationStr = durationStr..string.format("%.2f", duration);
    elseif (region.totalPrecision == 4 or region.totalPrecision == 5) and duration > 3 then
      durationStr = durationStr..string.format("%d", duration);
    else
      durationStr = durationStr..string.format("%."..(totalPrecision).."f", duration);
    end
  else
    durationStr     = " ";
  end
  region.values.duration   = durationStr;
end

function WeakAuras.TimerTick(region)
  WeakAuras.StartProfileSystem("text")
  WeakAuras.StartProfileAura(region.id);
  UpateRegionValues(region);
  region:TimerTick();
  WeakAuras.StopProfileAura(region.id);
  WeakAuras.StopProfileSystem("text")
end

function WeakAuras.regionPrototype.AddSetDurationInfo(region)
  if (region.SetValue and region.SetTime and region.TimerTick) then
    region.generatedSetDurationInfo = true;

    region.SetValueFromCustomValueFunc = function()
      WeakAuras.StartProfileSystem("text")
      WeakAuras.StartProfileAura(region.id);
      local value, total, _ = region.customValueFunc(region.state.trigger);
      value = type(value) == "number" and value or 0
      total = type(total) == "number" and total or 0
      SetProgressValue(region, value, total);
      WeakAuras.StopProfileAura(region.id);
      WeakAuras.StopProfileSystem("text")
    end

    region.SetDurationInfo = function(self, duration, expirationTime, customValue, inverse)
      if duration <= 0 or duration > self.duration or not region.stickyDuration then
        self.duration = duration;
      end
      self.expirationTime = expirationTime;
      self.inverse = inverse;

      if customValue then
        if type(customValue) == "function" then
          local value, total = customValue(region.state.trigger);
          value = type(value) == "number" and value or 0
          total = type(total) == "number" and total or 0
          if total > 0 and value < total then
            self.customValueFunc = customValue;
            self:SetScript("OnUpdate", region.SetValueFromCustomValueFunc);
          else
            SetProgressValue(region, duration, expirationTime);
            self:SetScript("OnUpdate", nil);
          end
        else
          SetProgressValue(region, duration, expirationTime);
          self:SetScript("OnUpdate", nil);
        end
      else
        UpateRegionValues(region);
        local adjustMin = region.adjustedMin or 0;
        region:SetTime((duration ~= 0 and region.adjustedMax or duration) - adjustMin, expirationTime - adjustMin, inverse);
        if duration > 0 then
          self:SetScript("OnUpdate", function() WeakAuras.TimerTick(region) end);
        else
          self:SetScript("OnUpdate", nil);
        end
      end
    end
  elseif (region.generatedSetDurationInfo) then
    region.generatedSetDurationInfo = nil;
    region.SetDurationInfo = nil;
    region.SetValueFromCustomValueFunc = nil;
    region:SetScript("OnUpdate", nil);
  end
end

-- Expand/Collapse function

function WeakAuras.regionPrototype.AddExpandFunction(data, region, cloneId, parent, parentRegionType)
  local id = data.id
  local indynamicgroup = parentRegionType == "dynamicgroup";
  local ingroup = parentRegionType == "group";

  local startMainAnimation = function()
    WeakAuras.Animate("display", data, "main", data.animation.main, region, false, nil, true, cloneId);
  end

  function region:OptionsClosed()
    region:EnableMouse(false)
    region:SetScript("OnMouseDown", nil)
  end

  function region:ClickToPick()
    region:EnableMouse(true)
    region:SetScript("OnMouseDown", function()
      WeakAuras.PickDisplay(region.id, nil, true)
    end)
    if region.GetFrameStrata and region:GetFrameStrata() == "TOOLTIP" then
      region:SetFrameStrata("HIGH")
    end
  end

  local hideRegion;
  if(indynamicgroup) then
    hideRegion = function()
      if region.PreHide then
        region:PreHide()
      end
      if WeakAuras.checkConditions[id] then
        WeakAuras.checkConditions[id](region, true);
      end
      region:Hide();
      if (cloneId) then
        WeakAuras.ReleaseClone(region.id, cloneId, data.regionType);
        parent:RemoveChild(id, cloneId)
      else
        parent:DeactivateChild(id, cloneId);
      end
    end
  else
    hideRegion = function()
      if region.PreHide then
        region:PreHide()
      end
      if WeakAuras.checkConditions[id] then
        WeakAuras.checkConditions[id](region, true);
      end
      region:Hide();
      if (cloneId) then
        WeakAuras.ReleaseClone(region.id, cloneId, data.regionType);
      end
    end
  end

  if(indynamicgroup) then
    function region:Collapse()
      if (not region.toShow) then
        return;
      end
      region.toShow = false;

      WeakAuras.PerformActions(data, "finish", region);
      if (not WeakAuras.Animate("display", data, "finish", data.animation.finish, region, false, hideRegion, nil, cloneId)) then
        hideRegion();
      end

      if (region.SoundRepeatStop) then
        region:SoundRepeatStop();
      end
    end
    function region:Expand()
      if (region.toShow) then
        return;
      end
      region.toShow = true;
      if(region.PreShow) then
        region:PreShow();
      end
      region.justCreated = nil;
      region:SetFrameLevel(WeakAuras.GetFrameLevelFor(region.id));
      region:Show();

      WeakAuras.PerformActions(data, "start", region);
      if not(WeakAuras.Animate("display", data, "start", data.animation.start, region, true, startMainAnimation, nil, cloneId)) then
        startMainAnimation();
      end
      parent:ActivateChild(data.id, cloneId);
    end
  elseif not(data.controlledChildren) then
    function region:Collapse()
      if (not region.toShow) then
        return;
      end
      region.toShow = false;

      WeakAuras.PerformActions(data, "finish", region);
      if (not WeakAuras.Animate("display", data, "finish", data.animation.finish, region, false, hideRegion, nil, cloneId)) then
        hideRegion();
      end

      if ingroup then
        parent:UpdateBorder(region);
      end

      if (region.SoundRepeatStop) then
        region:SoundRepeatStop();
      end
    end
    function region:Expand()
      if (region.toShow) then
        return;
      end
      region.toShow = true;

      if (data.anchorFrameType == "SELECTFRAME") then
        WeakAuras.AnchorFrame(data, region, parent);
      end

      region.justCreated = nil;
      if(region.PreShow) then
        region:PreShow();
      end
      region:SetFrameLevel(WeakAuras.GetFrameLevelFor(region.id));
      region:Show();
      WeakAuras.PerformActions(data, "start", region);
      if not(WeakAuras.Animate("display", data, "start", data.animation.start, region, true, startMainAnimation, nil, cloneId)) then
        startMainAnimation();
      end

      if ingroup then
        parent:UpdateBorder(region);
      end
    end
  end
  -- Stubs that allow for polymorphism
  if not region.Collapse then
    function region:Collapse() end
  end
  if not region.Expand then
    function region:Expand() end
  end
end

-- WORKAROUND Texts don't get the right size by default in WoW 7.3
function WeakAuras.regionPrototype.SetTextOnText(text, str)
  if (text:GetText() == str) then
    return
  end

  text:SetText(str);
end

function WeakAuras.SetTextureOrAtlas(texture, path, wrapModeH, wrapModeV)
  if type(path) == "string" and C_Texture.GetAtlasInfo(path) then
    texture:SetAtlas(path);
  else
    texture:SetTexture(path, wrapModeH, wrapModeV);
  end
end
