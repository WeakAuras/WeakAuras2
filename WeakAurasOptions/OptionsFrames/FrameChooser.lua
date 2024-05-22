if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, IsMouseButtonDown, SetCursor, GetMouseFocus, MouseIsOver, ResetCursor
  = CreateFrame, IsMouseButtonDown, SetCursor, GetMouseFocus, MouseIsOver, ResetCursor

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L

local frameChooserFrame
local frameChooserBox

local oldFocus
local oldFocusName
function OptionsPrivate.StartFrameChooser(data, path)
  local frame = OptionsPrivate.Private.OptionsFrame();
  if not(frameChooserFrame) then
    frameChooserFrame = CreateFrame("Frame");
    frameChooserBox = CreateFrame("Frame", nil, frameChooserFrame, "BackdropTemplate");
    frameChooserBox:SetFrameStrata("TOOLTIP");
    frameChooserBox:SetBackdrop({
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12,
      insets = {left = 0, right = 0, top = 0, bottom = 0}
    });
    frameChooserBox:SetBackdropBorderColor(0, 1, 0);
    frameChooserBox:Hide();
  end
  local givenValue = OptionsPrivate.Private.ValueFromPath(data, path);

  frameChooserFrame:SetScript("OnUpdate", function()
    if(IsMouseButtonDown("RightButton")) then
      OptionsPrivate.Private.ValueToPath(data, path, givenValue);
      OptionsPrivate.StopFrameChooser(data);
      WeakAuras.FillOptions()
    elseif(IsMouseButtonDown("LeftButton") and oldFocusName) then
      OptionsPrivate.StopFrameChooser(data);
    else
      SetCursor("CAST_CURSOR");

      local focus
      if GetMouseFocus then
        focus = GetMouseFocus()
      elseif GetMouseFoci then
        local foci = GetMouseFoci()
        focus = foci[1] or nil
      end
      local focusName;

      if(focus) then
        focusName = focus:GetName();
        if(focusName == "WorldFrame" or not focusName) then
          focusName = nil;
          local focusIsGroup = false;
          for id, regionData in pairs(OptionsPrivate.Private.regions) do
            if(regionData.region and regionData.region:IsVisible() and MouseIsOver(regionData.region)) then
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
            frameChooserBox:ClearAllPoints();
            frameChooserBox:SetPoint("bottomleft", focus, "bottomleft", -4, -4);
            frameChooserBox:SetPoint("topright", focus, "topright", 4, 4);
            frameChooserBox:Show();
          end

          if(focusName ~= oldFocusName) then
            OptionsPrivate.Private.ValueToPath(data, path, focusName);
            oldFocusName = focusName;
            WeakAuras.FillOptions()
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

function OptionsPrivate.StopFrameChooser(data)
  if(frameChooserFrame) then
    frameChooserFrame:SetScript("OnUpdate", nil);
    frameChooserBox:Hide();
  end
  ResetCursor();
  WeakAuras.Add(data);
end
