if not WeakAuras.IsCorrectVersion() then return end

local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local GetAtlasInfo = WeakAuras.IsClassic() and GetAtlasInfo or C_Texture.GetAtlasInfo

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

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

function WeakAuras.GetAnchorsForData(parentData, type)
  local result
  if not parentData.controlledChildren then
    if not WeakAuras.regionOptions[parentData.regionType].getAnchors then
      return
    end

    local anchors = WeakAuras.regionOptions[parentData.regionType].getAnchors(parentData)
    for anchorId, anchorData in pairs(anchors) do
      if anchorData.type == type then
        result = result or {}
        result[anchorId] = anchorData.display
      end
    end
  end
  return result
end

function WeakAuras.regionPrototype:AnchorSubRegion(subRegion, anchorType, selfPoint, anchorPoint, anchorXOffset, anchorYOffset)
  subRegion:ClearAllPoints()

  if anchorType == "point" then
    local xOffset = anchorXOffset or 0
    local yOffset = anchorYOffset or 0
    subRegion:SetPoint(WeakAuras.point_types[selfPoint] and selfPoint or "CENTER",
                       self, WeakAuras.point_types[anchorPoint] and anchorPoint or "CENTER",
                       xOffset, yOffset)
  else
    subRegion:SetAllPoints(self)
  end
end

-- Sound / Chat Message / Custom Code
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
      local ok, _, handle = pcall(PlaySoundFile, options.sound_path, options.sound_channel or "Master");
      if ok then
        self.soundHandle = handle;
      end
    end
  elseif (options.sound == " KitID") then
    if (options.sound_kit_id) then
      local ok, _, handle = pcall(PlaySound,options.sound_kit_id, options.sound_channel or "Master");
      if ok then
        self.soundHandle = handle;
      end
    end
  else
    local ok, _, handle = pcall(PlaySoundFile, options.sound, options.sound_channel or "Master");
    if ok then
      self.soundHandle = handle;
    end
  end
  WeakAuras.StopProfileSystem("sound");
end

local function SoundPlay(self, options)
  if (not options or WeakAuras.IsOptionsOpen()) then
    return
  end
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
  if (not options or WeakAuras.IsOptionsOpen()) then
    return
  end
  WeakAuras.HandleChatAction(options.message_type, options.message, options.message_dest, options.message_channel, options.r, options.g, options.b, self, options.message_custom);
end

local function RunCode(self, func)
  if func and not WeakAuras.IsOptionsOpen() then
    WeakAuras.ActivateAuraEnvironment(self.id, self.cloneId, self.state, self.states);
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
  self:RealClearAllPoints();

  xpcall(self.SetPoint, geterrorhandler(), self, self.anchorPoint, self.relativeTo, self.relativePoint, xOffset, yOffset);
end

local function ResetPosition(self)
  self.anchorPoint = nil;
  self.relativeTo = nil;
  self.relativePoint = nil;
end

local function SetAnchor(self, anchorPoint, relativeTo, relativePoint)
  if self.anchorPoint == anchorPoint and self.relativeTo == relativeTo and self.relativePoint == relativePoint then
    return
  end

  self.anchorPoint = anchorPoint;
  self.relativeTo = relativeTo;
  self.relativePoint = relativePoint;

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

local function SetTriggerProvidesTimer(self, timerTick)
  self.triggerProvidesTimer = timerTick
  self:UpdateTimerTick()
end

local function UpdateRegionHasTimerTick(self)
  local hasTimerTick = false
  if self.TimerTick then
    hasTimerTick = true
  elseif (self.subRegions) then
    for index, subRegion in pairs(self.subRegions) do
      if subRegion.TimerTick then
        hasTimerTick = true
        break;
      end
    end
  end

  self.regionHasTimer = hasTimerTick
  self:UpdateTimerTick()
end

local function UpdateTimerTick(self)
  if self.triggerProvidesTimer and self.regionHasTimer then
    if not self:GetScript("OnUpdate") then
      self:SetScript("OnUpdate", function()
        WeakAuras.TimerTick(self)
      end);
    end
  else
    if self:GetScript("OnUpdate") then
      self:SetScript("OnUpdate", nil);
    end
  end
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
  region.RealClearAllPoints = region.ClearAllPoints;
  region.ClearAllPoints = function()
    region:RealClearAllPoints();
    region:ResetPosition();
  end
  region.SetRegionAlpha = SetRegionAlpha;
  region.GetRegionAlpha = GetRegionAlpha;
  region.SetAnimAlpha = SetAnimAlpha;

  region.SetTriggerProvidesTimer = SetTriggerProvidesTimer
  region.UpdateRegionHasTimerTick = UpdateRegionHasTimerTick
  region.UpdateTimerTick = UpdateTimerTick
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

  region:SetOffset(data.xOffset or 0, data.yOffset or 0);
  region:SetOffsetAnim(0, 0);

  if data.anchorFrameType == "CUSTOM" and data.customAnchor then
    region.customAnchorFunc = WeakAuras.LoadFunction("return " .. data.customAnchor, data.id, "custom anchor")
  else
    region.customAnchorFunc = nil
  end

  if not parent or parent.regionType ~= "dynamicgroup" then
    WeakAuras.AnchorFrame(data, region, parent);
  end
end

function WeakAuras.regionPrototype.modifyFinish(parent, region, data)
  -- Sync subRegions
  if region.subRegions then
    for index, subRegion in pairs(region.subRegions) do
      WeakAuras.subRegionTypes[subRegion.type].release(subRegion)
    end

    wipe(region.subRegions)
  end

  if data.subRegions then
    region.subRegions = region.subRegions or {}
    local subRegionTypes = {}
    for index, subRegionData in pairs(data.subRegions) do
      if WeakAuras.subRegionTypes[subRegionData.type] then
        local subRegion = WeakAuras.subRegionTypes[subRegionData.type].acquire()
        subRegion.type = subRegionData.type

        if subRegion then
          WeakAuras.subRegionTypes[subRegionData.type].modify(region, subRegion, data, subRegionData, not subRegionTypes[subRegionData.type])
          subRegionTypes[subRegionData.type] = true
        end

        tinsert(region.subRegions, subRegion)
      end
    end
  end

  region:UpdateRegionHasTimerTick()

  WeakAuras.ApplyFrameLevel(region)
end

local function SetProgressValue(region, value, total)
  local adjustMin = region.adjustedMin or 0;
  local max = region.adjustedMax or total;

  region:SetValue(value - adjustMin, max - adjustMin);
end

function WeakAuras.TimerTick(region)
  WeakAuras.StartProfileSystem("timer tick")
  WeakAuras.StartProfileAura(region.id);
  if region.TimerTick then
    region:TimerTick();
  end
  if (region.subRegions) then
    for index, subRegion in pairs(region.subRegions) do
      if subRegion.TimerTick then
        subRegion:TimerTick()
      end
    end
  end
  WeakAuras.StopProfileAura(region.id);
  WeakAuras.StopProfileSystem("timer tick")
end

local regionsForFrameTick = {}

local frameForFrameTick = CreateFrame("FRAME");

WeakAuras.frames["Frame Tick Frame"] = frameForFrameTick

function WeakAuras.RegisterForFrameTick(region)
  -- Check for a Frame Tick function
  local hasFrameTick = region.FrameTick
  if not hasFrameTick then
    if (region.subRegions) then
      for index, subRegion in pairs(region.subRegions) do
        if subRegion.FrameTick then
          hasFrameTick = true
          break
        end
      end
    end
  end

  if not hasFrameTick then
    return
  end

  regionsForFrameTick[region] = true
  if not frameForFrameTick:GetScript("OnUpdate") then
    frameForFrameTick:SetScript("OnUpdate", WeakAuras.FrameTick);
  end
end

function WeakAuras.UnRegisterForFrameTick(region)
  regionsForFrameTick[region] = nil
  if not next(regionsForFrameTick) then
    frameForFrameTick:SetScript("OnUpdate", nil)
  end
end

function WeakAuras.FrameTick()
  if WeakAuras.IsOptionsOpen() then
    return
  end
  WeakAuras.StartProfileSystem("frame tick")
  for region in pairs(regionsForFrameTick) do
    WeakAuras.StartProfileAura(region.id);
    if region.FrameTick then
      region.FrameTick()
    end
    if (region.subRegions) then
      for index, subRegion in pairs(region.subRegions) do
        if subRegion.FrameTick then
          subRegion:FrameTick()
        end
      end
    end
    WeakAuras.StopProfileAura(region.id);
  end
  WeakAuras.StopProfileSystem("frame tick")
end

local function TimerTick(self)
  local duration = self.duration
  local adjustMin = self.adjustedMin or 0;
  self:SetTime((duration ~= 0 and self.adjustedMax or duration) - adjustMin, self.expirationTime - adjustMin, self.inverse);
end

function WeakAuras.regionPrototype.AddSetDurationInfo(region)
  if (region.SetValue and region.SetTime) then
    region.generatedSetDurationInfo = true;

    -- WeakAuras no longer calls SetDurationInfo, but some people do that,
    -- In that case we also need to overwrite TimerTick
    region.SetDurationInfo = function(self, duration, expirationTime, customValue, inverse)
      self.duration = duration or 0
      self.expirationTime = expirationTime;
      self.inverse = inverse;

      if customValue then
        SetProgressValue(region, duration, expirationTime);
        region.TimerTick = nil
        region:UpdateRegionHasTimerTick()
      else
        local adjustMin = region.adjustedMin or 0;
        region:SetTime((duration ~= 0 and region.adjustedMax or duration) - adjustMin, expirationTime - adjustMin, inverse);

        region.TimerTick = TimerTick
        region:UpdateRegionHasTimerTick()
      end
    end
  elseif (region.generatedSetDurationInfo) then
    region.generatedSetDurationInfo = nil;
    region.SetDurationInfo = nil;
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
      region:SetScript("OnUpdate", nil)

      WeakAuras.PerformActions(data, "finish", region);
      if (not WeakAuras.Animate("display", data, "finish", data.animation.finish, region, false, hideRegion, nil, cloneId)) then
        hideRegion();
      end

      if (region.SoundRepeatStop) then
        region:SoundRepeatStop();
      end

      WeakAuras.UnRegisterForFrameTick(region)
    end
    function region:Expand()
      if (region.toShow) then
        return;
      end
      region.toShow = true;
      if(region.PreShow) then
        region:PreShow();
      end

      if region.subRegions then
        for index, subRegion in pairs(region.subRegions) do
          if subRegion.PreShow then
            subRegion:PreShow()
          end
        end
      end

      region.justCreated = nil;
      WeakAuras.ApplyFrameLevel(region)
      region:Show();
      WeakAuras.PerformActions(data, "start", region);
      if not(WeakAuras.Animate("display", data, "start", data.animation.start, region, true, startMainAnimation, nil, cloneId)) then
        startMainAnimation();
      end
      parent:ActivateChild(data.id, cloneId);
      WeakAuras.RegisterForFrameTick(region)
    end
  elseif not(data.controlledChildren) then
    function region:Collapse()
      if (not region.toShow) then
        return;
      end
      region.toShow = false;
      region:SetScript("OnUpdate", nil)

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

      WeakAuras.UnRegisterForFrameTick(region)
    end
    function region:Expand()
      if (region.toShow) then
        return;
      end
      region.toShow = true;

      if (data.anchorFrameType == "SELECTFRAME" or data.anchorFrameType == "CUSTOM") then
        WeakAuras.AnchorFrame(data, region, parent);
      end

      region.justCreated = nil;
      if(region.PreShow) then
        region:PreShow();
      end

      if region.subRegions then
        for index, subRegion in pairs(region.subRegions) do
          if subRegion.PreShow then
            subRegion:PreShow()
          end
        end
      end

      WeakAuras.ApplyFrameLevel(region)
      region:Show();
      WeakAuras.PerformActions(data, "start", region);
      if not(WeakAuras.Animate("display", data, "start", data.animation.start, region, true, startMainAnimation, nil, cloneId)) then
        startMainAnimation();
      end

      if ingroup then
        parent:UpdateBorder(region);
      end

      WeakAuras.RegisterForFrameTick(region)
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
  if type(path) == "string" and GetAtlasInfo(path) then
    texture:SetAtlas(path);
  else
    texture:SetTexture(path, wrapModeH, wrapModeV);
  end
end
