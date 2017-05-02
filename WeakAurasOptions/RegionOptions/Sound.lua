local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local function createOptions(id, data)
  local options = {
      sound = {
        type = "select",
        name = L["Sound"],
        order = 1,
        values = WeakAuras.sound_types,
        control = "WeakAurasSortedDropdown",
        set = function(_, val)
          data.sound = val;
          if (value ~= "" and val ~= " custom" and val ~= " KitID") then
            -- play the sound immediately if we've selected one
            PlaySoundFile(val, data.sound_channel or "Master");
          end
        end,
      },
      sound_channel = {
        type = "select",
        name = L["Sound Channel"],
        order = 1.5,
        values = WeakAuras.sound_channel_types,
      },
      sound_path = {
        type = "input",
        name = L["Sound File Path"],
        order = 2,
        width = "double",
        hidden = function() return data.sound ~= " custom" end,
      },
      sound_kit_id = {
        type = "input",
        name = L["Sound Kit ID"],
        order = 2,
        width = "double",
        hidden = function() return data.sound ~= " KitID" end,
      },
      
      shouldDelay = {
        type = "toggle",
        order = 3,
        name = "Delay",
      },
      delayTime = {
        type = "range",
        name = "Delay Time",
        order = 3.5,
        min = 0,
        softMax = 5,
        step = .05,
        disabled = function() return not data.shouldDelay end,
      },
      
      shouldRepeat = {
        type = "toggle",
        order = 4,
        name = "Repeat/Loop",
      },
      repeatTime = {
        type = "range",
        name = "Repeat Time",
        order = 4.5,
        min = 0.1,
        softMax = 20,
        step = .25,
        disabled = function() return not data.shouldRepeat end,
      },
  };
  
  return options;
end

local function createThumbnail(parent)
  local borderframe = CreateFrame("FRAME", nil, parent);
  borderframe:SetWidth(32);
  borderframe:SetHeight(32);

  local border = borderframe:CreateTexture(nil, "OVERLAY");
  border:SetAllPoints(borderframe);
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

  local speakerTexture = borderframe:CreateTexture();
  borderframe.speakerTexture = speakerTexture;
  speakerTexture:SetPoint("CENTER", borderframe, "CENTER");
  speakerTexture:SetTexture("Interface\\Common\\VoiceChat-Speaker");
  
  local soundTexture = borderframe:CreateTexture();
  borderframe.soundTexture = soundTexture;
  soundTexture:SetPoint("CENTER", borderframe, "CENTER");
  soundTexture:SetTexture("Interface\\Common\\VoiceChat-On");

  return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, size)
end

local function createIcon()
  local thumbnail = createThumbnail(UIParent);
  modifyThumbnail(UIParent, thumbnail);

  return thumbnail;
end

WeakAuras.RegisterRegionOptions("sound", createOptions, createIcon, "Sound", createThumbnail, modifyThumbnail, "Plays sounds with optional repeating");
