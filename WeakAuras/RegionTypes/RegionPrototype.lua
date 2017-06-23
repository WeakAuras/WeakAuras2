local WeakAuras = WeakAuras;
local L = WeakAuras.L;

WeakAuras.regionPrototype = {};

function WeakAuras.regionPrototype.AddProperties(properties)
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
end

local function SoundRepeatStop(self)
  if (self.soundRepeatTimer) then
    WeakAuras.timer:CancelTimer(self.soundRepeatTimer);
    self.soundRepeatTimer = nil;
  end
end

local function SoundStop(self)
  if (self.soundHandle) then
    StopSound(self.soundHandle);
  end
end

local function SoundPlayHelper(self)
  local options = self.soundOptions;
  self.soundHandle = nil;
  if (options.sound_type == "Stop") then
    return;
  end

  if (WeakAuras.IsOptionsOpen()) then
    return;
  end

  if (options.sound == " custom") then
    if (options.sound_path) then
      local _, handle = PlaySoundFile(options.sound_path, options.sound_channel or "Master");
      self.soundHandle = handle;
    end
  elseif (options.sound == " KitID") then
    if (options.sound_kit_id) then
      local _, handle = PlaySoundKitID(options.sound_kit_id, options.sound_channel or "Master");
      self.soundHandle = handle;
    end
  else
    local _, handle = PlaySoundFile(options.sound, options.sound_channel or "Master");
    self.soundHandle = handle;
  end
end

local function SoundPlay(self, options)
  self:SoundStop();
  self:SoundRepeatStop();

  self.soundOptions = options;
  SoundPlayHelper(self);

  local loop = options.do_loop or options.sound_type == "Loop";
  if (loop and options.sound_repeat) then
    self.soundRepeatTimer = WeakAuras.timer:ScheduleRepeatingTimer(SoundPlayHelper, options.sound_repeat, self);
  end
end

local function SendChat(self, options)
  WeakAuras.HandleChatAction(options.message_type, options.message, options.message_dest, options.message_channel, options.r, options.g, options.b, self, options.message_custom);
end

local function RunCode(self, func)
  if func then
    WeakAuras.ActivateAuraEnvironment(self.id, self.cloneId, self.state);
    func();
    WeakAuras.ActivateAuraEnvironment(nil);
  end
end

function WeakAuras.regionPrototype.create(region)
  region.SoundPlay = SoundPlay;
  region.SoundStop = SoundStop;
  region.SoundRepeatStop = SoundRepeatStop;
  region.SendChat = SendChat;
  region.RunCode = RunCode;
end

function WeakAuras.regionPrototype.AddSetDurationInfo(region)
  if (region.SetValue and region.SetTime and region.TimerTick) then
    region.generatedSetDurationInfo = true;
    region.SetValueFromCustomValueFunc = function()
      local value, total = region.customValueFunc(region.state.trigger);
      value = type(value) == "number" and value or 0
      total = type(value) == "number" and total or 0
      WeakAuras.SetProgressValue(region, value, total);
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
          total = type(value) == "number" and total or 0
          if total > 0 and value < total then
            self.customValueFunc = customValue;
            self:SetScript("OnUpdate", region.SetValueFromCustomValueFunc);
          else
            WeakAuras.SetProgressValue(region, duration, expirationTime);
            self:SetScript("OnUpdate", nil);
          end
        else
          WeakAuras.SetProgressValue(region, duration, expirationTime);
          self:SetScript("OnUpdate", nil);
        end
      else
        WeakAuras.UpateRegionValues(region);
        region:SetTime(duration, expirationTime, inverse);
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

function WeakAuras.regionPrototype.AddExpandFunction(data, region, id, cloneId, parent, parentRegionType)
  local indynamicgroup = parentRegionType == "dynamicgroup";
  local ingroup = parentRegionType == "group";

  local startMainAnimation = function()
    WeakAuras.Animate("display", data, "main", data.animation.main, region, false, nil, true, cloneId);
  end

  local hideRegion;
  if(indynamicgroup) then
    hideRegion = function()
      region:Hide();
      if (cloneId) then
        WeakAuras.ReleaseClone(id, cloneId, data.regionType);
      end
      parent:ControlChildren();
    end
  else
    hideRegion = function()
      region:Hide();
      if (cloneId) then
        WeakAuras.ReleaseClone(id, cloneId, data.regionType);
      end
    end
  end

  if(indynamicgroup) then
    if not(cloneId) then
      parent:PositionChildren();
    end
    function region:Collapse()
      if (not region.toShow) then
        return;
      end
      region.toShow = false;

      WeakAuras.PerformActions(data, "finish", region);
      if (not WeakAuras.Animate("display", data, "finish", data.animation.finish, region, false, hideRegion, nil, cloneId)) then
        hideRegion();
      end
      parent:ControlChildren();

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

      parent:EnsureTrays();
      region.justCreated = nil;
      WeakAuras.PerformActions(data, "start", region);
      if not(WeakAuras.Animate("display", data, "start", data.animation.start, region, true, startMainAnimation, nil, cloneId)) then
        startMainAnimation();
      end
      parent:ControlChildren();
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
