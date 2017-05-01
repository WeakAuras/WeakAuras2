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
  
  local function killTicker()
    if (region.ticker) then
      region.ticker:Cancel();
      region.ticker = nil;
      region.tickerCallback = nil;
    end
  end
  
  killTicker();
  
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
  
  local function OnShow()
    if (region.toShow) then
      -- immediately play the sound
      playSound();
      
      -- setup a callback every 'repeatTime' seconds if repeating
      if (data.shouldRepeat) then
        region.tickerCallback = function()
          stopSound();
          playSound();
        end
        
        region.ticker = C_Timer.NewTicker(data.repeatTime, region.tickerCallback);
      end
    end
  end
  
  region:SetScript("OnShow", OnShow);
  
  local function OnHide()
    -- immediately stop playing sound
    stopSound();
    
    -- kill our ticker if it exists
    killTicker();
  end
  
  region:SetScript("OnHide", OnHide);
end

WeakAuras.RegisterRegionType("sound", create, modify, default);
