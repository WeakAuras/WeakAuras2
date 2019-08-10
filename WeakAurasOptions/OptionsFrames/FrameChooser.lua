if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, IsMouseButtonDown, SetCursor, GetMouseFocus, MouseIsOver, ResetCursor
  = CreateFrame, IsMouseButtonDown, SetCursor, GetMouseFocus, MouseIsOver, ResetCursor

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L

local valueFromPath = WeakAuras.ValueFromPath
local valueToPath = WeakAuras.ValueToPath

local frameChooserFrame
local frameChooserBox

local oldFocus
local oldFocusName
function WeakAuras.StartFrameChooser(data, path)
  local frame = WeakAuras.OptionsFrame();
  if not(frameChooserFrame) then
    frameChooserFrame = CreateFrame("frame");
    frameChooserBox = CreateFrame("frame", nil, frameChooserFrame);
    frameChooserBox:SetFrameStrata("TOOLTIP");
    frameChooserBox:SetBackdrop({
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12,
      insets = {left = 0, right = 0, top = 0, bottom = 0}
    });
    frameChooserBox:SetBackdropBorderColor(0, 1, 0);
    frameChooserBox:Hide();
  end
  local givenValue = valueFromPath(data, path);

  frameChooserFrame:SetScript("OnUpdate", function()
    if(IsMouseButtonDown("RightButton")) then
      valueToPath(data, path, givenValue);
      AceConfigDialog:Open("WeakAuras", frame.container);
      WeakAuras.StopFrameChooser(data);
    elseif(IsMouseButtonDown("LeftButton") and oldFocusName) then
      WeakAuras.StopFrameChooser(data);
    else
      SetCursor("CAST_CURSOR");

      local focus = GetMouseFocus();
      local focusName;

      if(focus) then
        focusName = focus:GetName();
        if(focusName == "WorldFrame" or not focusName) then
          focusName = nil;
          local focusIsGroup = false;
          for id, regionData in pairs(WeakAuras.regions) do
            if(regionData.region:IsVisible() and MouseIsOver(regionData.region)) then
              local isGroup = regionData.regionType == "group" or regionData.regionType == "dynamicgroup";
              if (not focusName or (not isGroup and focusIsGroup)) then
                focus = regionData.region;
                focusName = "WeakAuras:"..id;
                focusIsGroup = focusIsGroup;
              end
            end
          end
        end

        if(focus ~= oldFocus) then
          if(focusName) then
            frameChooserBox:SetPoint("bottomleft", focus, "bottomleft", -4, -4);
            frameChooserBox:SetPoint("topright", focus, "topright", 4, 4);
            frameChooserBox:Show();
          end

          if(focusName ~= oldFocusName) then
            valueToPath(data, path, focusName);
            oldFocusName = focusName;
            AceConfigDialog:Open("WeakAuras", frame.container);
          end
          oldFocus = focus;
        end
      end

      if not(focusName) then
        frameChooserBox:Hide();
      end
    end
  end);
end

function WeakAuras.StopFrameChooser(data)
  if(frameChooserFrame) then
    frameChooserFrame:SetScript("OnUpdate", nil);
    frameChooserBox:Hide();
  end
  ResetCursor();
  WeakAuras.Add(data);
end
