if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

---@class WeakAuras
local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local GetAtlasInfo = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo

Private.regionPrototype = {};

-- Alpha
function Private.regionPrototype.AddAlphaToDefault(default)
  default.alpha = 1.0;
end

-- Progress Sources
function Private.regionPrototype.AddProgressSourceToDefault(default)
  default.progressSource = {-1, ""}
  default.useAdjustededMax = false
  default.useAdjustededMin = false
end

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

function Private.GetAnchorsForData(parentData, type)
  local result
  if not parentData.controlledChildren then
    if not Private.regionOptions[parentData.regionType] then
      return
    end

    local anchors
    if Private.regionOptions[parentData.regionType].getAnchors then
      anchors = Private.regionOptions[parentData.regionType].getAnchors(parentData)
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
function Private.regionPrototype.AddProperties(properties, defaultsForRegion)
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

  if defaultsForRegion and defaultsForRegion.progressSource then
    properties["progressSource"] = {
      display = L["Progress Source"],
      setter = "SetProgressSource",
      type = "progressSource",
      values = {},
    }

    properties["adjustedMin"] = {
      display = L["Minimum Progress"],
      setter = "SetAdjustedMin",
      type = "string",
      validate = WeakAuras.ValidateNumericOrPercent,
    }

    properties["adjustedMax"] = {
      display = L["Maximum Progress"],
      setter = "SetAdjustedMax",
      type = "string",
      validate = WeakAuras.ValidateNumericOrPercent,
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

local function SoundStop(self, fadeoutTime)
  Private.StartProfileSystem("sound");
  if (self.soundHandle) then
    StopSound(self.soundHandle, fadeoutTime);
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
    local ok, _, handle = pcall(PlaySoundFile, options.sound_path, options.sound_channel or "Master")
    if ok then
      self.soundHandle = handle
    end
  elseif (options.sound == " KitID") then
    local ok, _, handle = pcall(PlaySound,options.sound_kit_id, options.sound_channel or "Master")
    if ok then
      self.soundHandle = handle
    end
  else
    local ok, _, handle = pcall(PlaySoundFile, options.sound, options.sound_channel or "Master")
    if ok then
      self.soundHandle = handle
    end
  end
  Private.StopProfileSystem("sound");
end

local function hasSound(options)
  if options.sound_type == "Stop" then
    return true
  end
  if (options.sound == " custom") then
    if (options.sound_path and options.sound_path ~= "") then
      return true
    end
  elseif (options.sound == " KitID") then
    if (options.sound_kit_id and options.sound_kit_id ~= "") then
      return true
    end
  else
    if options.sound and options.sound ~= "" then
      return true
    end
  end
  return false
end

local function SoundPlay(self, options)
  if (not options or WeakAuras.IsOptionsOpen()) then
    return
  end
  Private.StartProfileSystem("sound");
  if not hasSound(options) then
    Private.StopProfileSystem("sound")
    return
  end

  local fadeoutTime = options.sound_type == "Stop" and options.sound_fade and options.sound_fade * 1000 or 0
  self:SoundStop(fadeoutTime);
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

local function SetProgressSource(self, progressSource)
  self.progressSource = progressSource
  self:UpdateProgress()
end

local function SetAdjustedMin(self, adjustedMin)
  local percent = string.match(adjustedMin, "(%d+)%%")
  if percent then
    self.adjustedMinRelPercent = tonumber(percent) / 100
    self.adjustedMin = nil
  else
    self.adjustedMin = tonumber(adjustedMin)
    self.adjustedMinRelPercent = nil
  end
  self:UpdateProgress()
end

local function SetAdjustedMax(self, adjustedMax)
  local percent = string.match(adjustedMax, "(%d+)%%")
  if percent then
    self.adjustedMaxRelPercent = tonumber(percent) / 100
  else
    self.adjustedMax = tonumber(adjustedMax)
  end
  self:UpdateProgress()
end

local function GetProgressSource(self)
  return self.progressSource
end

local function GetMinMaxProgress(self)
  return self.minProgress or 0, self.maxProgress or 0
end

local function UpdateProgressFromState(self, minMaxConfig, state, progressSource)
  local progressType = progressSource[2]
  local property = progressSource[3]
  local totalProperty = progressSource[4]
  local modRateProperty = progressSource[5]
  local inverseProperty = progressSource[6]
  local pausedProperty = progressSource[7]
  local remainingProperty = progressSource[8]

  if progressType == "number" then
    local value = state[property]
    if type(value) ~= "number" then value = 0 end
    local total = totalProperty and state[totalProperty]
    if type(total) ~= "number" then total = 0 end
    -- We don't care about inverse, modRate or paused
    local adjustMin
    if minMaxConfig.adjustedMin then
      adjustMin = minMaxConfig.adjustedMin
    elseif minMaxConfig.adjustedMinRelPercent then
      adjustMin = minMaxConfig.adjustedMinRelPercent * total
    else
      adjustMin = 0
    end
    local max
    if minMaxConfig.adjustedMax then
      max = minMaxConfig.adjustedMax
    elseif minMaxConfig.adjustedMaxRelPercent then
      max = minMaxConfig.adjustedMaxRelPercent * total
    else
      max = total
    end
    -- The output of UpdateProgress is setting various values on self
    -- and calling UpdateTime/UpdateValue. Not an ideal interface, but
    -- the animation code/sub elements needs those values in some convenient place
    self.minProgress, self.maxProgress = adjustMin, max
    self.progressType = "static"
    self.value = value - adjustMin
    self.total = max - adjustMin
    if self.UpdateValue then
      self:UpdateValue()
    end
    if self.SetAdditionalProgress then
      self:SetAdditionalProgress(state.additionalProgress, adjustMin, max, false)
    end
  elseif progressType == "timer" then
    local expirationTime
    local paused = pausedProperty and state[pausedProperty]
    local inverse = inverseProperty and state[inverseProperty]
    local remaining
    if paused then
      remaining = remainingProperty and state[remainingProperty]
      expirationTime = GetTime() + (type(remaining) == "number" and remaining or 0)
    else
      expirationTime = state[property]
      if type(expirationTime) ~= "number" then
        expirationTime = math.huge
      end
    end

    local duration = totalProperty and state[totalProperty] or 0
    local modRate = modRateProperty and state[modRateProperty] or nil
    local adjustMin
    if minMaxConfig.adjustedMin then
      adjustMin = minMaxConfig.adjustedMin
    elseif minMaxConfig.adjustedMinRelPercent then
      adjustMin = minMaxConfig.adjustedMinRelPercent * duration
    else
      adjustMin = 0
    end

    local max
    if duration == 0 then
      max = 0
    elseif minMaxConfig.adjustedMax then
      max = minMaxConfig.adjustedMax
    elseif minMaxConfig.adjustedMaxRelPercent then
      max = minMaxConfig.adjustedMaxRelPercent * duration
    else
      max = duration
    end
    self.minProgress, self.maxProgress = adjustMin, max
    self.progressType = "timed"
    self.duration = max - adjustMin
    self.expirationTime = expirationTime - adjustMin
    self.remaining = remaining
    self.modRate = modRate
    self.inverse = inverse
    self.paused = paused
    if self.UpdateTime then
      self:UpdateTime()
    end
    if self.SetAdditionalProgress then
      self:SetAdditionalProgress(state.additionalProgress, adjustMin, max, inverse)
    end
  elseif progressType == "elapsedTimer" then
    local startTime = state[property] or math.huge
    local duration = totalProperty and state[totalProperty] or 0
    local adjustMin
    if minMaxConfig.adjustedMin then
      adjustMin = minMaxConfig.adjustedMin
    elseif minMaxConfig.adjustedMinRelPercent then
      adjustMin = minMaxConfig.adjustedMinRelPercent * duration
    else
      adjustMin = 0
    end

    local max
    if minMaxConfig.adjustedMax then
      max = minMaxConfig.adjustedMax
    elseif minMaxConfig.adjustedMaxRelPercent then
      max = minMaxConfig.adjustedMaxRelPercent * duration
    else
      max = duration
    end
    self.minProgress, self.maxProgress = adjustMin, max
    self.progressType = "timed"
    self.duration = max - adjustMin
    self.expirationTime = startTime + adjustMin + self.duration
    self.modRate = nil
    self.inverse = true
    self.paused = false
    self.remaining = nil
    if self.UpdateTime then
      self:UpdateTime()
    end
    if self.SetAdditionalProgress then
      self:SetAdditionalProgress(state.additionalProgress, adjustMin, max, false)
    end
  end
end

local autoTimedProgressSource = {-1, "timer", "expirationTime", "duration", "modRate", "inverse", "paused", "remaining"}
local autoStaticProgressSource = {-1, "number", "value", "total", nil, nil, nil, nil}
local function UpdateProgressFromAuto(self, minMaxConfig, state)
  if state.progressType == "timed"  then
    UpdateProgressFromState(self, minMaxConfig, state, autoTimedProgressSource)
  elseif state.progressType == "static"then
    UpdateProgressFromState(self, minMaxConfig, state, autoStaticProgressSource)
  else
    self.minProgress, self.maxProgress = nil, nil
    self.progressType = "timed"
    self.duration = 0
    self.expirationTime = math.huge
    self.modRate = nil
    self.inverse = false
    self.paused = true
    self.remaining = math.huge
    if self.UpdateTime then
      self:UpdateTime()
    end
    if self.SetAdditionalProgress then
      self:SetAdditionalProgress(nil)
    end
  end
end

local function UpdateProgressFromManual(self, minMaxConfig, state, value, total)
  value = type(value) == "number" and value or 0
  total = type(total) == "number" and total or 0
  local adjustMin
  if minMaxConfig.adjustedMin then
    adjustMin = minMaxConfig.adjustedMin
  elseif minMaxConfig.adjustedMinRelPercent then
    adjustMin = minMaxConfig.adjustedMinRelPercent * total
  else
    adjustMin = 0
  end
  local max
  if minMaxConfig.adjustedMax then
    max = minMaxConfig.adjustedMax
  elseif minMaxConfig.adjustedMaxRelPercent then
    max = minMaxConfig.adjustedMaxRelPercent * total
  else
    max = total
  end
  self.minProgress, self.maxProgress = adjustMin, max
  self.progressType = "static"
  self.value = value - adjustMin
  self.total = max - adjustMin
  if self.UpdateValue then
    self:UpdateValue()
  end
  if self.SetAdditionalProgress then
    self:SetAdditionalProgress(state.additionalProgress, adjustMin, max)
  end
end

local function UpdateProgressFrom(self, progressSource, minMaxConfig, state, states, parent)
  local trigger = progressSource and progressSource[1] or -1

  if trigger == -2 then
    -- sub element'a auto uses the whatever progress the main region has
    UpdateProgressFromAuto(self, minMaxConfig, parent)
  elseif trigger == -1 then
    -- auto for regions uses the state
    UpdateProgressFromAuto(self, minMaxConfig, state)
  elseif trigger == 0 then
    UpdateProgressFromManual(self, minMaxConfig, state, progressSource[3], progressSource[4])
  else
    UpdateProgressFromState(self, minMaxConfig, states[trigger] or {}, progressSource)
  end
end

-- For regions
local function UpdateProgress(self)
  UpdateProgressFrom(self, self.progressSource, self, self.state, self.states)
end

Private.UpdateProgressFrom = UpdateProgressFrom

local function SetAnimAlpha(self, alpha)
  if alpha then
    if alpha > 1 then
      alpha = 1
    elseif alpha < 0 then
      alpha = 0
    end
  end
  if (self.animAlpha == alpha) then
    return;
  end
  self.animAlpha = alpha;
  local errorHandler = Private.GetErrorHandlerId(self.id, L["Custom Fade Animation"])
  if (WeakAuras.IsOptionsOpen()) then
    xpcall(self.SetAlpha, errorHandler, self, max(self.animAlpha or self.alpha or 1, 0.5))
  else
    xpcall(self.SetAlpha, errorHandler, self, self.animAlpha or self.alpha or 1)
  end
  self.subRegionEvents:Notify("AlphaChanged")
end

local function UpdateTick(self)
  if self.subRegionEvents:HasSubscribers("FrameTick") and self.toShow then
    Private.FrameTick:AddSubscriber("Tick", self)
  else
    Private.FrameTick:RemoveSubscriber("Tick", self)
  end
end

local function Tick(self)
  Private.StartProfileAura(self.id)
  self.values.lastCustomTextUpdate = nil
  self.subRegionEvents:Notify("FrameTick")
  Private.StopProfileAura(self.id)
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

Private.regionPrototype.AnchorSubRegion = AnchorSubRegion

function Private.regionPrototype.create(region)
  local defaultsForRegion = Private.regionTypes[region.regionType] and Private.regionTypes[region.regionType].default;
  region.SoundPlay = SoundPlay;
  region.SoundStop = SoundStop;
  region.SoundRepeatStop = SoundRepeatStop;
  region.SendChat = SendChat;
  region.RunCode = RunCode;
  region.GlowExternal = GlowExternal;

  region.ReAnchor = UpdatePosition;
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
  if defaultsForRegion and defaultsForRegion.progressSource then
    region.SetProgressSource = SetProgressSource
    region.GetProgressSource = GetProgressSource
    region.SetAdjustedMin = SetAdjustedMin
    region.SetAdjustedMax = SetAdjustedMax
  end
  region.UpdateProgress = UpdateProgress
  region.GetMinMaxProgress = GetMinMaxProgress
  region.SetAnimAlpha = SetAnimAlpha;

  region.UpdateTick = UpdateTick
  region.Tick = Tick

  region.subRegionEvents = Private.CreateSubscribableObject()
  region.AnchorSubRegion = AnchorSubRegion
  region.values = {} -- For SubText

  region:SetPoint("CENTER", UIParent, "CENTER")
end

function Private.regionPrototype.modify(parent, region, data)
  region.state = nil
  region.states = nil
  region.subRegionEvents:ClearSubscribers()
  region.subRegionEvents:ClearCallbacks()
  Private.FrameTick:RemoveSubscriber("Tick", region)

  local defaultsForRegion = Private.regionTypes[data.regionType] and Private.regionTypes[data.regionType].default;

  if region.SetRegionAlpha then
    region:SetRegionAlpha(data.alpha)
  end

  local hasProgressSource = defaultsForRegion and defaultsForRegion.progressSource
  local hasAdjustedMin = hasProgressSource and data.useAdjustededMin and data.adjustedMin
  local hasAdjustedMax = hasProgressSource and data.useAdjustededMax and data.adjustedMax

  region.progressSource = nil
  region.adjustedMin = nil
  region.adjustedMinRelPercent = nil
  region.adjustedMax = nil
  region.adjustedMaxRelPercent = nil

  if hasProgressSource then
    region.progressSource = Private.AddProgressSourceMetaData(data, data.progressSource)
  end

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
  end, true, data)

  region.finishFormatters = Private.CreateFormatters(data.actions.finish.message, function(key, default)
    local fullKey = "message_format_" .. key
    if data.actions.finish[fullKey] == nil then
      data.actions.finish[fullKey] = default
    end
    return data.actions.finish[fullKey]
  end, true, data)
end

function Private.regionPrototype.modifyFinish(parent, region, data)
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

  region.subRegionEvents:SetOnSubscriptionStatusChanged("FrameTick", function()
    region:UpdateTick()
  end)
  region:UpdateTick()

  Private.ApplyFrameLevel(region)
end

local frameForFrameTick = CreateFrame("Frame");
Private.frames["Frame Tick Frame"] = frameForFrameTick

Private.FrameTick = Private.CreateSubscribableObject()
Private.FrameTick.OnUpdateHandler = function()
  Private.StartProfileSystem("frame tick")
  Private.FrameTick:Notify("Tick")
  Private.StopProfileSystem("frame tick")
end

Private.FrameTick:SetOnSubscriptionStatusChanged("Tick", function()
  if Private.FrameTick:HasSubscribers("Tick") then
    frameForFrameTick:SetScript("OnUpdate", Private.FrameTick.OnUpdateHandler);
  else
    frameForFrameTick:SetScript("OnUpdate", nil)
  end
end)

function Private.regionPrototype.AddSetDurationInfo(region, uid)
  if (region.UpdateValue and region.UpdateTime) then
    -- WeakAuras no longer calls SetDurationInfo, but some people do that
    region.SetDurationInfo = function(self, duration, expirationTime, customValue, inverse)
      -- For now don't warn against SetDurationInfo
      -- Private.AuraWarnings.UpdateWarning(uid, "SetDurationInfo", "warning", L["Aura is using deprecated SetDurationInfo"])
      if customValue then
        local adjustMin = region.adjustedMin or 0;
        local max = self.adjustedMax or expirationTime
        region.progressType = "static"
        region.value = duration - adjustMin
        region.total = max - adjustMin
        region:UpdateValue()
      else
        local adjustMin = self.adjustedMin or 0;
        self.progressType = "timed"
        self.duration = (duration ~= 0 and self.adjustedMax or duration) - adjustMin
        self.expirationTime = expirationTime - adjustMin
        self.modRate = nil
        self.inverse = inverse
        self.paused = false
        self.remaining = nil
        self:UpdateTime()
      end
    end
  end
end

-- Expand/Collapse function
function Private.regionPrototype.AddExpandFunction(data, region, cloneId, parent, parentRegionType)
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

      Private.PerformActions(data, "finish", region);
      if (not Private.Animate("display", data.uid, "finish", data.animation.finish, region, false, hideRegion, nil, cloneId)) then
        hideRegion();
      end

      if (region.SoundRepeatStop) then
        region:SoundRepeatStop();
      end

      region:UpdateTick()
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

      region:UpdateTick()
    end
  elseif not(data.controlledChildren) then
    function region:Collapse()
      if (not region.toShow) then
        return;
      end
      region.toShow = false;

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

      region:UpdateTick()
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

      region:UpdateTick()
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

function Private.SetTextureOrAtlas(texture, path, wrapModeH, wrapModeV)
  texture.IsAtlas = type(path) == "string" and GetAtlasInfo(path) ~= nil
  if texture.IsAtlas then
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
