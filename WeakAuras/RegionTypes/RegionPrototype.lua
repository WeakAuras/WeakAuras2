if not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...

local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local GetAtlasInfo = WeakAuras.IsClassic() and GetAtlasInfo or C_Texture.GetAtlasInfo

WeakAuras.regionPrototype = {};


local SubRegionEventSystem =
{
  ClearSubscribers = function(self)
    self.events = {}
  end,

  AddSubscriber = function(self, event, subRegion)
    if not subRegion[event] then
      print("Can't register subregion for ", event, " ", subRegion.type)
      return
    end

    self.events[event] = self.events[event] or {}
    tinsert(self.events[event], subRegion)
  end,

  RemoveSubscriber = function(self, event, subRegion)
    tremove(self.events[event], tIndexOf(self.events[event], subRegion))
  end,

  Notify = function(self, event, ...)
    if self.events[event] then
      for _, subRegion in ipairs(self.events[event]) do
        subRegion[event](subRegion, ...)
      end
    end
  end
}

local function CreateSubRegionEventSystem()
  local system = {}
  for f, func in pairs(SubRegionEventSystem) do
    system[f] = func
    system.events = {}
  end
  return system
end

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
    type = "input",
    validate = WeakAuras.ValidateNumericOrPercent,
    width = WeakAuras.normalWidth,
    order = order + 0.01,
    name = L["Minimum"],
    hidden = function() return not data.useAdjustededMin end,
    desc = L["Enter static or relative values with %"]
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
    type = "input",
    width = WeakAuras.normalWidth,
    validate = WeakAuras.ValidateNumericOrPercent,
    order = order + 0.04,
    name = L["Maximum"],
    hidden = function() return not data.useAdjustededMax end,
    desc = L["Enter static or relative values with %"]
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

function Private.GetAnchorsForData(parentData, type)
  local result
  if not parentData.controlledChildren then
    if not WeakAuras.regionOptions[parentData.regionType] then
      return
    end

    local anchors
    if WeakAuras.regionOptions[parentData.regionType].getAnchors then
      anchors = WeakAuras.regionOptions[parentData.regionType].getAnchors(parentData)
    else
      anchors = Private.default_types_for_anchor
    end
    for anchorId, anchorData in pairs(anchors) do
      if anchorData.type == type then
        result = result or {}
        result[anchorId] = anchorData.display
      end
    end
  end
  return result
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
  properties["xOffsetRelative"] = {
    display = L["Relative X-Offset"],
    setter = "SetXOffsetRelative",
    type = "number",
    softMin = -screenWidth,
    softMax = screenWidth,
    bigStep = 1
  }
  properties["yOffsetRelative"] = {
    display = L["Relative Y-Offset"],
    setter = "SetYOffsetRelative",
    type = "number",
    softMin = -screenHeight,
    softMax = screenHeight,
    bigStep = 1
  }
  properties["glowexternal"] = {
    display = L["Glow External Element"],
    action = "GlowExternal",
    type = "glowexternal"
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
  Private.StartProfileSystem("sound");
  if (self.soundRepeatTimer) then
    WeakAuras.timer:CancelTimer(self.soundRepeatTimer);
    self.soundRepeatTimer = nil;
  end
  Private.StopProfileSystem("sound");
end

local function SoundStop(self)
  Private.StartProfileSystem("sound");
  if (self.soundHandle) then
    StopSound(self.soundHandle);
  end
  Private.StopProfileSystem("sound");
end

local function SoundPlayHelper(self)
  Private.StartProfileSystem("sound");
  local options = self.soundOptions;
  self.soundHandle = nil;
  if (not options or options.sound_type == "Stop") then
    Private.StopProfileSystem("sound");
    return;
  end

  if (WeakAuras.IsOptionsOpen() or Private.SquelchingActions() or WeakAuras.InLoadingScreen()) then
    Private.StopProfileSystem("sound");
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
  Private.StopProfileSystem("sound");
end

local function SoundPlay(self, options)
  if (not options or WeakAuras.IsOptionsOpen()) then
    return
  end
  Private.StartProfileSystem("sound");
  self:SoundStop();
  self:SoundRepeatStop();

  self.soundOptions = options;
  SoundPlayHelper(self);

  local loop = options.do_loop or options.sound_type == "Loop";
  if (loop and options.sound_repeat and options.sound_repeat < Private.maxTimerDuration) then
    self.soundRepeatTimer = WeakAuras.timer:ScheduleRepeatingTimer(SoundPlayHelper, options.sound_repeat, self);
  end
  Private.StopProfileSystem("sound");
end

local function SendChat(self, options)
  if (not options or WeakAuras.IsOptionsOpen()) then
    return
  end
  Private.HandleChatAction(options.message_type, options.message, options.message_dest, options.message_dest_isunit, options.message_channel, options.r, options.g, options.b, self, options.message_custom, nil, options.message_formaters, options.message_voice);
end

local function RunCode(self, func)
  if func and not WeakAuras.IsOptionsOpen() then
    Private.ActivateAuraEnvironment(self.id, self.cloneId, self.state, self.states);
    xpcall(func, Private.GetErrorHandlerId(self.id, L["Custom Condition Code"]));
    Private.ActivateAuraEnvironment(nil);
  end
end

local function GlowExternal(self, options)
  if (not options or WeakAuras.IsOptionsOpen()) then
    return
  end
  Private.HandleGlowAction(options, self)
end

local function UpdatePosition(self)
  if (not self.anchorPoint or not self.relativeTo or not self.relativePoint) then
    return;
  end

  local xOffset = self.xOffset + (self.xOffsetAnim or 0) + (self.xOffsetRelative or 0)
  local yOffset = self.yOffset + (self.yOffsetAnim or 0) + (self.yOffsetRelative or 0)
  self:RealClearAllPoints();

  xpcall(self.SetPoint, Private.GetErrorHandlerId(self.id, L["Update Position"]), self, self.anchorPoint, self.relativeTo, self.relativePoint, xOffset, yOffset);
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

local function SetOffsetRelative(self, xOffsetRelative, yOffsetRelative)
  if (self.xOffsetRelative == xOffsetRelative and self.yOffsetRelative == yOffsetRelative) then
    return
  end
  self.xOffsetRelative = xOffsetRelative
  self.yOffsetRelative = yOffsetRelative
  UpdatePosition(self)
end

local function SetXOffsetRelative(self, xOffsetRelative)
  self:SetOffsetRelative(xOffsetRelative, self:GetYOffsetRelative())
end

local function SetYOffsetRelative(self, yOffsetRelative)
  self:SetOffsetRelative(self:GetXOffsetRelative(), yOffsetRelative)
end

local function GetXOffsetRelative(self)
  return self.xOffsetRelative
end

local function GetYOffsetRelative(self)
  return self.yOffsetRelative
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
  self.subRegionEvents:Notify("AlphaChanged")
end

local function GetRegionAlpha(self)
  return self.animAlpha or self.alpha or 1;
end

local function SetAnimAlpha(self, alpha)
  if (self.animAlpha == alpha) then
    return;
  end
  self.animAlpha = alpha;
  if (WeakAuras.IsOptionsOpen()) then
    self:SetAlpha(max(self.animAlpha or self.alpha or 1, 0.5));
  else
    self:SetAlpha(self.animAlpha or self.alpha or 1);
  end
  self.subRegionEvents:Notify("AlphaChanged")
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

local function TimerTickForRegion(region)
  Private.StartProfileSystem("timer tick")
  Private.StartProfileAura(region.id);
  if region.TimerTick then
    region:TimerTick();
  end

  region.subRegionEvents:Notify("TimerTick")
  Private.StopProfileAura(region.id);
  Private.StopProfileSystem("timer tick")
end

local function UpdateTimerTick(self)
  if self.triggerProvidesTimer and self.regionHasTimer and self.toShow then
    if not self:GetScript("OnUpdate") then
      self:SetScript("OnUpdate", function()
        TimerTickForRegion(self)
      end);
    end
  else
    if self:GetScript("OnUpdate") then
      self:SetScript("OnUpdate", nil);
    end
  end
end

local function AnchorSubRegion(self, subRegion, anchorType, selfPoint, anchorPoint, anchorXOffset, anchorYOffset)
  subRegion:ClearAllPoints()

  if anchorType == "point" then
    local xOffset = anchorXOffset or 0
    local yOffset = anchorYOffset or 0
    subRegion:SetPoint(Private.point_types[selfPoint] and selfPoint or "CENTER",
                       self, Private.point_types[anchorPoint] and anchorPoint or "CENTER",
                       xOffset, yOffset)
  else
    anchorXOffset = anchorXOffset or 0
    anchorYOffset = anchorYOffset or 0
    subRegion:SetPoint("bottomleft", self, "bottomleft", -anchorXOffset, -anchorYOffset)
    subRegion:SetPoint("topright", self, "topright", anchorXOffset,  anchorYOffset)
  end
end

WeakAuras.regionPrototype.AnchorSubRegion = AnchorSubRegion

function WeakAuras.regionPrototype.create(region)
  local defaultsForRegion = WeakAuras.regionTypes[region.regionType] and WeakAuras.regionTypes[region.regionType].default;
  region.SoundPlay = SoundPlay;
  region.SoundStop = SoundStop;
  region.SoundRepeatStop = SoundRepeatStop;
  region.SendChat = SendChat;
  region.RunCode = RunCode;
  region.GlowExternal = GlowExternal;

  region.SetAnchor = SetAnchor;
  region.SetOffset = SetOffset;
  region.SetXOffset = SetXOffset;
  region.SetYOffset = SetYOffset;
  region.GetXOffset = GetXOffset;
  region.GetYOffset = GetYOffset;
  region.SetOffsetRelative = SetOffsetRelative
  region.SetXOffsetRelative = SetXOffsetRelative
  region.SetYOffsetRelative = SetYOffsetRelative
  region.GetXOffsetRelative = GetXOffsetRelative
  region.GetYOffsetRelative = GetYOffsetRelative
  region.SetOffsetAnim = SetOffsetAnim;
  region.ResetPosition = ResetPosition;
  region.RealClearAllPoints = region.ClearAllPoints;
  region.ClearAllPoints = function()
    region:RealClearAllPoints();
    region:ResetPosition();
  end
  if (defaultsForRegion and defaultsForRegion.alpha) then
    region.SetRegionAlpha = SetRegionAlpha;
    region.GetRegionAlpha = GetRegionAlpha;
  end
  region.SetAnimAlpha = SetAnimAlpha;

  region.SetTriggerProvidesTimer = SetTriggerProvidesTimer
  region.UpdateRegionHasTimerTick = UpdateRegionHasTimerTick
  region.UpdateTimerTick = UpdateTimerTick

  region.subRegionEvents = CreateSubRegionEventSystem()
  region.AnchorSubRegion = AnchorSubRegion
  region.values = {} -- For SubText

  region:SetPoint("CENTER", UIParent, "CENTER")
end

-- SetDurationInfo

function WeakAuras.regionPrototype.modify(parent, region, data)
  region.state = nil
  region.states = nil
  region.subRegionEvents:ClearSubscribers()

  local defaultsForRegion = WeakAuras.regionTypes[data.regionType] and WeakAuras.regionTypes[data.regionType].default;

  if region.SetRegionAlpha then
    region:SetRegionAlpha(data.alpha)
  end

  local hasAdjustedMin = defaultsForRegion and defaultsForRegion.useAdjustededMin ~= nil and data.useAdjustededMin
        and data.adjustedMin;
  local hasAdjustedMax = defaultsForRegion and defaultsForRegion.useAdjustededMax ~= nil and data.useAdjustededMax
        and data.adjustedMax;

  region.adjustedMin = nil
  region.adjustedMinRel = nil
  region.adjustedMinRelPercent = nil
  region.adjustedMax = nil
  region.adjustedMaxRel = nil
  region.adjustedMaxRelPercent = nil

  if (hasAdjustedMin) then
    local percent = string.match(data.adjustedMin, "(%d+)%%")
    if percent then
      region.adjustedMinRelPercent = tonumber(percent) / 100
    else
      region.adjustedMin = tonumber(data.adjustedMin);
    end
  end
  if (hasAdjustedMax) then
    local percent = string.match(data.adjustedMax, "(%d+)%%")
    if percent then
      region.adjustedMaxRelPercent = tonumber(percent) / 100
    else
      region.adjustedMax = tonumber(data.adjustedMax)
    end
  end

  region:SetOffset(data.xOffset or 0, data.yOffset or 0);
  region:SetOffsetRelative(0, 0)
  region:SetOffsetAnim(0, 0);

  if data.anchorFrameType == "CUSTOM" and data.customAnchor then
    region.customAnchorFunc = WeakAuras.LoadFunction("return " .. data.customAnchor)
  else
    region.customAnchorFunc = nil
  end

  if not parent or parent.regionType ~= "dynamicgroup" then
    if
      -- Don't anchor single Auras that with custom anchoring,
      -- these will be anchored in expand
      not (
        data.anchorFrameType == "CUSTOM"
        or data.anchorFrameType == "UNITFRAME"
        or data.anchorFrameType == "NAMEPLATE"
      )
      -- Group Auras that will never be expanded, so those need
      -- to be always anchored here
      or data.regionType == "dynamicgroup"
      or data.regionType == "group"
    then
      Private.AnchorFrame(data, region, parent);
    end
  end

  region.startFormatters = Private.CreateFormatters(data.actions.start.message, function(key, default)
    local fullKey = "message_format_" .. key
    if data.actions.start[fullKey] == nil then
      data.actions.start[fullKey] = default
    end
    return data.actions.start[fullKey]
  end, true)

  region.finishFormatters = Private.CreateFormatters(data.actions.finish.message, function(key, default)
    local fullKey = "message_format_" .. key
    if data.actions.finish[fullKey] == nil then
      data.actions.finish[fullKey] = default
    end
    return data.actions.finish[fullKey]
  end, true)

end

function WeakAuras.regionPrototype.modifyFinish(parent, region, data)
  -- Sync subRegions
  if region.subRegions then
    for index, subRegion in pairs(region.subRegions) do
      Private.subRegionTypes[subRegion.type].release(subRegion)
    end

    wipe(region.subRegions)
  end

  if data.subRegions then
    region.subRegions = region.subRegions or {}
    local subRegionTypes = {}
    for index, subRegionData in pairs(data.subRegions) do
      if Private.subRegionTypes[subRegionData.type] then
        local subRegion = Private.subRegionTypes[subRegionData.type].acquire()
        subRegion.type = subRegionData.type

        if subRegion then
          Private.subRegionTypes[subRegionData.type].modify(region, subRegion, data, subRegionData, not subRegionTypes[subRegionData.type])
          subRegionTypes[subRegionData.type] = true
        end

        tinsert(region.subRegions, subRegion)
      end
    end
  end

  region:UpdateRegionHasTimerTick()

  Private.ApplyFrameLevel(region)
end

local function SetProgressValue(region, value, total)
  local adjustMin = region.adjustedMin or 0;
  local max = region.adjustedMax or total;

  region:SetValue(value - adjustMin, max - adjustMin);
end

local regionsForFrameTick = {}

local frameForFrameTick = CreateFrame("Frame");

WeakAuras.frames["Frame Tick Frame"] = frameForFrameTick

local function FrameTick()
  if WeakAuras.IsOptionsOpen() then
    return
  end
  Private.StartProfileSystem("frame tick")
  for region in pairs(regionsForFrameTick) do
    Private.StartProfileAura(region.id);
    if region.FrameTick then
      region.FrameTick()
    end
    region.subRegionEvents:Notify("FrameTick")
    Private.StopProfileAura(region.id);
  end
  Private.StopProfileSystem("frame tick")
end

local function RegisterForFrameTick(region)
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
    frameForFrameTick:SetScript("OnUpdate", FrameTick);
  end
end

local function UnRegisterForFrameTick(region)
  regionsForFrameTick[region] = nil
  if not next(regionsForFrameTick) then
    frameForFrameTick:SetScript("OnUpdate", nil)
  end
end

local function TimerTickForSetDuration(self)
  local duration = self.duration
  local adjustMin = self.adjustedMin or 0;

  local max
  if duration == 0 then
    max = 0
  elseif self.adjustedMax then
    max = self.adjustedMax
  else
    max = duration
  end

  self:SetTime(max - adjustMin, self.expirationTime - adjustMin, self.inverse);
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

        region.TimerTick = TimerTickForSetDuration
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
  local uid = data.uid
  local id = data.id
  local inDynamicGroup = parentRegionType == "dynamicgroup";
  local inGroup = parentRegionType == "group";

  local startMainAnimation = function()
    Private.Animate("display", uid, "main", data.animation.main, region, false, nil, true, cloneId);
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
  if(inDynamicGroup) then
    hideRegion = function()
      if region.PreHide then
        region:PreHide()
      end

      Private.RunConditions(region, uid, true)
      region.subRegionEvents:Notify("PreHide")
      if region:IsProtected() then
        if InCombatLockdown() then
          Private.AuraWarnings.UpdateWarning(uid, "protected_frame_error", "error",
          L["Cannot change secure frame in combat lockdown. Find more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"],
            true)
        else
          Private.AuraWarnings.UpdateWarning(uid, "protected_frame", "warning",
            L["Secure frame detected. Find more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"])
          region:Hide()
        end
      else
        Private.AuraWarnings.UpdateWarning(uid, "protected_frame")
        region:Hide()
      end
      region.states = nil
      region.state = nil
      if (cloneId) then
        Private.ReleaseClone(region.id, cloneId, data.regionType);
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
      Private.RunConditions(region, uid, true)
      region.subRegionEvents:Notify("PreHide")

      if region:IsProtected() then
        if InCombatLockdown() then
          Private.AuraWarnings.UpdateWarning(uid, "protected_frame_error", "error",
          L["Cannot change secure frame in combat lockdown. Find more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"],
            true)
        else
          Private.AuraWarnings.UpdateWarning(uid, "protected_frame", "warning",
            L["Secure frame detected. Find more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"])
          region:Hide()
        end
      else
        Private.AuraWarnings.UpdateWarning(uid, "protected_frame")
        region:Hide()
      end

      region.states = nil
      region.state = nil
      if (cloneId) then
        Private.ReleaseClone(region.id, cloneId, data.regionType);
      end
    end
  end

  if(inDynamicGroup) then
    function region:Collapse()
      if (not region.toShow) then
        return;
      end
      region.toShow = false;
      region:SetScript("OnUpdate", nil)

      Private.PerformActions(data, "finish", region);
      if (not Private.Animate("display", data.uid, "finish", data.animation.finish, region, false, hideRegion, nil, cloneId)) then
        hideRegion();
      end

      if (region.SoundRepeatStop) then
        region:SoundRepeatStop();
      end

      UnRegisterForFrameTick(region)
      region:UpdateTimerTick()
    end
    function region:Expand()
      if (region.toShow) then
        return;
      end
      region.toShow = true;
      if(region.PreShow) then
        region:PreShow();
      end

      region.subRegionEvents:Notify("PreShow")

      Private.ApplyFrameLevel(region)
      if region:IsProtected() then
        if InCombatLockdown() then
          Private.AuraWarnings.UpdateWarning(uid, "protected_frame_error", "error",
            L["Cannot change secure frame in combat lockdown. Find more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"],
            true)
        else
          Private.AuraWarnings.UpdateWarning(uid, "protected_frame", "warning",
            L["Secure frame detected. Find more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"])
          region:Show()
        end
      else
        Private.AuraWarnings.UpdateWarning(uid, "protected_frame")
        region:Show()
      end

      Private.PerformActions(data, "start", region);
      if not(Private.Animate("display", data.uid, "start", data.animation.start, region, true, startMainAnimation, nil, cloneId)) then
        startMainAnimation();
      end
      parent:ActivateChild(data.id, cloneId);

      RegisterForFrameTick(region)
      region:UpdateTimerTick()
    end
  elseif not(data.controlledChildren) then
    function region:Collapse()
      if (not region.toShow) then
        return;
      end
      region.toShow = false;
      region:SetScript("OnUpdate", nil)

      Private.PerformActions(data, "finish", region);
      if (not Private.Animate("display", data.uid, "finish", data.animation.finish, region, false, hideRegion, nil, cloneId)) then
        hideRegion();
      end

      if inGroup then
        parent:UpdateBorder(region);
      end

      if (region.SoundRepeatStop) then
        region:SoundRepeatStop();
      end

      UnRegisterForFrameTick(region)
      region:UpdateTimerTick()
    end
    function region:Expand()
      if data.anchorFrameType == "SELECTFRAME"
      or data.anchorFrameType == "CUSTOM"
      or data.anchorFrameType == "UNITFRAME"
      or data.anchorFrameType == "NAMEPLATE"
      then
        Private.AnchorFrame(data, region, parent);
      end

      if (region.toShow) then
        return;
      end
      region.toShow = true

      if(region.PreShow) then
        region:PreShow();
      end

      region.subRegionEvents:Notify("PreShow")
      Private.ApplyFrameLevel(region)

      if region:IsProtected() then
        if InCombatLockdown() then
          Private.AuraWarnings.UpdateWarning(uid, "protected_frame_error", "error",
            L["Cannot change secure frame in combat lockdown. Find more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"],
            true)
        else
          Private.AuraWarnings.UpdateWarning(uid, "protected_frame", "warning",
            L["Secure frame detected. Find more information:\nhttps://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"])
          region:Show()
        end
      else
        Private.AuraWarnings.UpdateWarning(uid, "protected_frame")
        region:Show()
      end

      Private.PerformActions(data, "start", region);
      if not(Private.Animate("display", data.uid, "start", data.animation.start, region, true, startMainAnimation, nil, cloneId)) then
        startMainAnimation();
      end

      if inGroup then
        parent:UpdateBorder(region);
      end

      RegisterForFrameTick(region)
      region:UpdateTimerTick()
    end
  end
  -- Stubs that allow for polymorphism
  if not region.Collapse then
    function region:Collapse() end
  end
  if not region.Expand then
    function region:Expand() end
  end
  if not region.Pause then
    function region:Pause()
      self.paused = true
    end
  end
  if not region.Resume then
    function region:Resume()
      self.paused = nil
    end
  end
end

function WeakAuras.SetTextureOrAtlas(texture, path, wrapModeH, wrapModeV)
  if type(path) == "string" and GetAtlasInfo(path) then
    return texture:SetAtlas(path);
  else
    if (texture.wrapModeH and texture.wrapModeH ~= wrapModeH) or (texture.wrapModeV and texture.wrapModeV ~= wrapModeV) then
      -- WORKAROUND https://github.com/Stanzilla/WoWUIBugs/issues/250
      texture:SetTexture(nil)
    end
    texture.wrapModeH = wrapModeH
    texture.wrapModeV = wrapModeV
    return texture:SetTexture(path, wrapModeH, wrapModeV);
  end
end

do
  local function move_condition_subregions(data, offset, afterPos)
    if data.conditions then
      for conditionIndex, condition in ipairs(data.conditions) do
        if type(condition.changes) == "table" then
          for changeIndex, change in ipairs(condition.changes) do
            if change.property then
              local subRegionIndex, property = change.property:match("^sub%.(%d+)%.(.*)")
              subRegionIndex = tonumber(subRegionIndex)
              if subRegionIndex and property then
                if (subRegionIndex >= afterPos) then
                  change.property = "sub." .. subRegionIndex + offset .. "." .. property
                end
              end
            end
          end
        end
      end
    end
  end

  function Private.EnforceSubregionExists(data, subregionType)
    data.subRegions = data.subRegions or {}
    -- search and save indexes of matching subregions
    local indexes = {}
    for index, subRegionData in ipairs(data.subRegions) do
      if subRegionData.type == subregionType then
        table.insert(indexes, index)
      end
    end
    -- add if missing
    if #indexes == 0 then
      tinsert(data.subRegions, 1, {
        ["type"] = subregionType
      })
      move_condition_subregions(data, 1, 1)
    -- delete duplicate
    elseif #indexes > 1 then
      for i = #indexes, 2, -1 do
        table.remove(data.subRegions, indexes[i])
        move_condition_subregions(data, -1, indexes[i])
      end
    end
  end
end
