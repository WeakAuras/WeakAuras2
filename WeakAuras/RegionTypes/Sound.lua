local SharedMedia = LibStub("LibSharedMedia-3.0");

local default = {
  selfPoint = "BOTTOM",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  frameStrata = 1,
  
  sound = "",
  sound_channel = "Master",
  sound_path = "",
  sound_kit_id = "",
  
  shouldRepeat = false,
  repeatTime = 1,
  
  shouldDelay = false,
  delayTime = 1,
}

local function create(parent)
  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  
  return region;
end

local function modify(parent, region, data)
  data.width = 16;
  data.height = 16;
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  
  WeakAuras.AnchorFrame(data, region, parent);
  
  local function killTimer()
    if (region.timer) then
      region.timer:Cancel();
      region.timer = nil;
    end
  end
  
  killTimer();
  
  local function playSound()
    if (not WeakAuras.IsOptionsOpen()) then
      if(data.sound == " custom") then
        if(data.sound_path) then
          local _, soundHandle = PlaySoundFile(data.sound_path, data.sound_channel or "Master");
          region.soundHandle = soundHandle;
        end
      elseif(data.sound == " KitID") then
        if(data.sound_kit_id) then
          local _, soundHandle = PlaySoundKitID(data.sound_kit_id, data.sound_channel or "Master");
          region.soundHandle = soundHandle;
        end
      else
        local _, soundHandle = PlaySoundFile(data.sound, data.sound_channel or "Master");
        region.soundHandle = soundHandle;
      end
    end
  end

  local function stopSound()
    if (region.soundHandle) then
      StopSound(region.soundHandle);
      region.soundHandle = nil;
    end
  end
  
  local function startPlaying()
    -- immediately play the sound
    playSound();
    
    -- setup a callback every 'repeatTime' seconds if repeating
    if (data.shouldRepeat) then
      local function callback()
        stopSound();
        playSound();
      end
      
      region.timer = C_Timer.NewTicker(data.repeatTime, callback);
    end
  end
  
  local function OnShow()
    if (region.toShow) then
      if (not data.shouldDelay) then
        startPlaying();
      else
        -- wait for the timer to fire, then start
        region.timer = C_Timer.NewTimer(data.delayTime, startPlaying);
      end
    end
  end
  
  region:SetScript("OnShow", OnShow);
  
  local function OnHide()
    -- immediately stop playing sound if we're playing one
    stopSound();
    
    -- kill our ticker or timer if they exist
    killTimer();
  end
  
  region:SetScript("OnHide", OnHide);
end

WeakAuras.RegisterRegionType("sound", create, modify, default);
