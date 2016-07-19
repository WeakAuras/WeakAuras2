-- GLOBALS: WeakAuras

local AceGUI = LibStub("AceGUI-3.0");
local L = WeakAuras.L;

local tutFrame;
local tutorials = WeakAuras.tutorials
local optionsFrame;
if(WeakAuras.OptionsFrame) then
  optionsFrame = WeakAuras.OptionsFrame()
end

function WeakAuras.ToggleTutorials()
  if(tutFrame and tutFrame:IsVisible()) then
    WeakAuras.HideTutorials();
  else
    WeakAuras.ShowTutorials();
  end
end

function WeakAuras.ShowTutorials()
  if not(tutFrame) then
    WeakAuras.CreateTutorialsFrame()
  end
  tutFrame:Show();
  WeakAuras.ShowTutorialHome();
end

function WeakAuras.HideTutorials()
  if(tutFrame) then
    WeakAuras.ContinuouslyPointTutorialToPath(nil);
    tutFrame:Hide();
  end
end

function WeakAuras.TutorialsFrame()
  return tutFrame;
end

local autoAdvanceData = {};
do
  local elapsed = 0;
  local anchorDelay = 0.1;
  local anchorPath;

  local pointingFrame;

  local function ContinuousPointUpdate(frame, elaps)
    elapsed = elapsed + elaps;
    if(elapsed > anchorDelay) then
      elapsed = elapsed - anchorDelay;

      WeakAuras.CheckAutoAdvance();
      WeakAuras.PointTutorialToPath(anchorPath);
    end
  end

  function WeakAuras.ContinuouslyPointTutorialToPath(path)
    if(path) then
      anchorPath = path;
      tutFrame.stepFrame:SetScript("OnUpdate", ContinuousPointUpdate);
    else
      tutFrame.stepFrame:SetScript("OnUpdate", nil);
    end
  end

  function WeakAuras.CheckAutoAdvance()
    if(autoAdvanceData.path) then
      if(type(optionsFrame.pickedDisplay) == "string") then
        local doAutoAdvance = false;
        local currentValue = WeakAuras.ValueFromPath(WeakAuras.GetData(optionsFrame.pickedDisplay), autoAdvanceData.path);
        if(autoAdvanceData.func(autoAdvanceData.previousValue, currentValue, autoAdvanceData.previousPicked, optionsFrame.pickedDisplay)) then
          doAutoAdvance = true;
        end
        autoAdvanceData.previousValue = currentValue;
        autoAdvanceData.previousPicked = optionsFrame.pickedDisplay;

        if(doAutoAdvance) then
          tutFrame.stepFrame.next:Click();
        end
      end
    elseif(autoAdvanceData.func) then
      if(autoAdvanceData.func()) then
        tutFrame.stepFrame.next:Click();
      end
    end
  end

  function WeakAuras.PointTutorialToPath(path)
    if(optionsFrame and optionsFrame:IsVisible()) then
      if(path[1] == "new") then
        if(optionsFrame.pickedOption == "New") then
          if(path[2]) then
            for index, child in pairs(optionsFrame.container.content.obj.children[1].children) do
              if(child:GetTitle() == path[2]) then
                WeakAuras.PointTutorialToFrame(child);
              end
            end
          else
            WeakAuras.PointTutorialToFrame(optionsFrame.container);
          end
        else
          local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(optionsFrame.newButton);
          if(sidebarVisible == true) then
            WeakAuras.PointTutorialToFrame(optionsFrame.newButton);
          elseif(sidebarVisible == "above" or sidebarVisible == "below") then
            WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
          elseif(sidebarVisible == "hidden") then
            WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll);
          end
        end
      elseif(path[1] == "addons") then
        if(optionsFrame.pickedOption == "Addons") then
          WeakAuras.PointTutorialToFrame(optionsFrame.container);
        else
          local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(optionsFrame.addonsButton);
          if(sidebarVisible == true) then
            WeakAuras.PointTutorialToFrame(optionsFrame.addonsButton);
          elseif(sidebarVisible == "above" or sidebarVisible == "below") then
            WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
          elseif(sidebarVisible == "hidden") then
            WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll);
          end
        end
      elseif(path[1] == "loaded") then
        local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(optionsFrame.loadedButton);
        if(sidebarVisible == true) then
          WeakAuras.PointTutorialToFrame(optionsFrame.loadedButton);
        elseif(sidebarVisible == "above" or sidebarVisible == "below") then
          WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
        elseif(sidebarVisible == "hidden") then
          WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll);
        end
      elseif(path[1] == "unloaded") then
        local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(optionsFrame.unloadedButton);
        if(sidebarVisible == true) then
          WeakAuras.PointTutorialToFrame(optionsFrame.unloadedButton);
        elseif(sidebarVisible == "above" or sidebarVisible == "below") then
          WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
        elseif(sidebarVisible == "hidden") then
          WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll);
        end
      elseif(path[1] == "display") then
        local id;
        if(path[2] and path[2] ~= "") then
          if(type(path[2]) == "function") then
            id = path[2]();
          else
            id = path[2];
          end
        elseif(optionsFrame.pickedDisplay) then
          if(type(optionsFrame.pickedDisplay) == "table") then
            id = optionsFrame.pickedDisplay.controlledChildren[1];
          else
            id = optionsFrame.pickedDisplay;
          end
        end

        local picked = type(optionsFrame.pickedDisplay) == "string" and optionsFrame.pickedDisplay;

        local button = WeakAuras.displayButtons[id];
        local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(button);

        if(button and sidebarVisible) then
          if(path[3] == "button") then
            if(sidebarVisible == true) then
              if(path[4]) then
                local buttonPiece = button[path[4]];
                WeakAuras.PointTutorialToFrame(buttonPiece);
              else
                WeakAuras.PointTutorialToFrame(button);
              end
            elseif(sidebarVisible == "above" or sidebarVisible == "below") then
              WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
            elseif(sidebarVisible == "hidden") then
              WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll);
            end
          elseif(path[3] == "options") then
            if(id == picked) then
              local optionsTable = WeakAuras.displayOptions[id];
              local tabName = optionsTable and optionsTable.args[path[4]] and optionsTable.args[path[4]].name
              local tabFrame;
              local tabSelected = false;
              if (WeakAuras.OptionsFrame().container.children) and next(WeakAuras.OptionsFrame().container.children) then
	              for i,v in pairs(WeakAuras.OptionsFrame().container.children[1].tabs) do
	                if(v:GetText() == tabName) then
	                  tabFrame = v;
	                  if(v.selected) then
	                    tabSelected = true;
	                  end
	                end
	              end
              end

              if(tabFrame) then
                if not(tabSelected) then
                  WeakAuras.PointTutorialToFrame(tabFrame);
                elseif(WeakAuras.OptionsFrame().container.children[1].children[1].children and path[5]) then
                  local optionIndex;
                  local optionName;
                  local optionOccurrence;
                  local optionOccurrenceCount = 0;
                  if(type(path[5]) == "table") then
                    optionName = path[5][1];
                    optionOccurrence = path[5][2];
                  else
                    optionName = path[5];
                  end

                  for index, child in ipairs(WeakAuras.OptionsFrame().container.children[1].children[1].children) do
                    local name = (child.label and child.label:GetText()) or (child.text and child.text:GetText());
                    if(name == (L[optionName] or optionName)) then
                      optionOccurrenceCount = optionOccurrenceCount + 1;
                      if(optionOccurrence) then
                        if(optionOccurrence == optionOccurrenceCount) then
                          optionIndex = index;
                          break;
                        end
                      else
                        optionIndex = index;
                        break;
                      end
                    end
                  end

                  if(optionIndex and WeakAuras.OptionsFrame().container.children[1].children[1].children[optionIndex]) then
                    WeakAuras.PointTutorialToFrame(WeakAuras.OptionsFrame().container.children[1].children[1].children[optionIndex]);
                  else
                    WeakAuras.PointTutorialToFrame(optionsFrame.container);
                  end
                else
                  WeakAuras.PointTutorialToFrame(optionsFrame.container);
                end
              else
                WeakAuras.PointTutorialToFrame(optionsFrame.container);
              end
            else
              if(sidebarVisible == true) then
                WeakAuras.PointTutorialToFrame(button);
              elseif(sidebarVisible == "above" or sidebarVisible == "below") then
                WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
              elseif(sidebarVisible == "hidden") then
                WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll);
              end
            end
          else
            if(sidebarVisible == true) then
              WeakAuras.PointTutorialToFrame(button);
            elseif(sidebarVisible == "above" or sidebarVisible == "below") then
              WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
            elseif(sidebarVisible == "hidden") then
              WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll);
            end
          end
        else
          WeakAuras.PointTutorialToFrame(optionsFrame.buttonsScroll);
        end
      elseif(path[1] == "none") then
        WeakAuras.PointTutorialToFrame({});
      elseif(type(path[1]) == "table") then
        WeakAuras.PointTutorialToFrame(path[1]);
      elseif(type(path[1]) == "function") then
        WeakAuras.PointTutorialToFrame(path[1]());
      end
    end
  end

  local pl, pb, pw, ph;
  function WeakAuras.PointTutorialToFrame(frame)
    if not(pl and pb and pw and ph) then
      pl, pb, pw, ph = tutFrame.frame:GetRect();
    end
    if not(pointingFrame) then
      pointingFrame = CreateFrame("frame", nil, tutFrame.stepFrame);
      pointingFrame:SetFrameStrata("TOOLTIP");
      pointingFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
      });
      pointingFrame:SetBackdropBorderColor(0.7, 0.7, 1);
      function pointingFrame:Scale(scalex, scaley)
        pointingFrame:SetWidth(pw * scalex);
        pointingFrame:SetHeight(ph * scaley);
      end
    end

    local width, height;
    if not(frame.GetRect) then
      frame = frame.frame;
    end
    if(frame.GetRect and frame:GetRect()) then
      local l, b, w, h = frame:GetRect();
      l = l - 8;
      b = b - 8
      w = w + 16;
      h = h + 16;

      if(l~=pl or b~=pb or w~=pw or h~=ph) then
        WeakAuras.CancelAnimation(pointingFrame, true, true, true, true, true);

        pointingFrame:SetSize(w, h);
        pointingFrame:SetPoint("center", frame, "center");
        pointingFrame:Show();

        local anim = {
          duration = 0.25,
          type = "custom",
          use_scale = true,
          scalex = pw/w,
          scaley = ph/h,
          use_translate = true,
          x = (pl+pw/2) - (l+w/2),
          y = (pb+ph/2) - (b+h/2)
        };
        WeakAuras.Animate("frame", "tutorial-pointingFrame", "start", anim, pointingFrame, true, function()
          WeakAuras.Animate("frame", "tutorial-pointingFrame", "main", {type="preset",preset="pulse"}, pointingFrame, false, nil, true);
        end);
        pl, pb, pw, ph = l, b, w, h;
        WeakAuras.UpdateAnimations();
      end
    else
      WeakAuras.CancelAnimation(pointingFrame, true, true, true, true, true);
      pointingFrame:Hide();
    end
  end
end

function WeakAuras.ShowTutorialHome()
  WeakAuras.ContinuouslyPointTutorialToPath(nil);
  tutFrame.stepFrame:Hide();
  tutFrame.homeFrame:Show();
  tutFrame:SetTitle(L["WeakAuras Tutorials"]);
end

function WeakAuras.PlayTutorial(tutData, step, fromPrevious)
  tutFrame.homeFrame:Hide();
  tutFrame.stepFrame:Show();
  local stepFrame = tutFrame.stepFrame;

  if(tutData.displayName) then
    tutFrame:SetTitle(tutData.displayName);
  end

  step = step or 1;
  local stepData = tutData.steps[step];

  if(stepData.autoadvance and not fromPrevious) then
    autoAdvanceData.path = stepData.autoadvance.path;
    autoAdvanceData.func = stepData.autoadvance.test;
    if(type(optionsFrame.pickedDisplay) == "string") then
      autoAdvanceData.previousPicked = optionsFrame.pickedDisplay;
      autoAdvanceData.previousValue = autoAdvanceData.path and WeakAuras.GetData(optionsFrame.pickedDisplay) and WeakAuras.ValueFromPath(WeakAuras.GetData(optionsFrame.pickedDisplay), autoAdvanceData.path);
    else
      autoAdvanceData.previousPickedDisplay = nil;
      autoAdvanceData.previousValue = nil;
    end
  else
    autoAdvanceData.path = nil;
    autoAdvanceData.func = nil;
    autoAdvanceData.previousValue = nil;
    autoAdvanceData.previousPicked = nil;
  end

  stepFrame.title:SetText(stepData.title or "");
  if(stepData.texture) then
    stepFrame.texture:SetSize(stepData.texture.width, stepData.texture.height);
    stepFrame.texture:SetTexture(stepData.texture.path);
    stepFrame.texture:Show();
    if(stepData.texture.color) then
      stepFrame.texture:SetVertexColor(stepData.texture.color[1], stepData.texture.color[2], stepData.texture.color[3]);
    else
      stepFrame.texture:SetVertexColor(1, 1, 1);
    end
  else
    stepFrame.texture:SetSize(100, 1);
    stepFrame.texture:Hide();
  end
  stepFrame.text:SetText(stepData.text or "");
  stepFrame.scroll:RecalculateHeight()

  WeakAuras.ContinuouslyPointTutorialToPath(stepData.path);

  if(tutData.steps[step - 1]) then
    stepFrame.previous:Enable();
    stepFrame.previous:SetScript("OnClick", function()
      WeakAuras.PlayTutorial(tutData, step - 1, true);
    end);
  else
    stepFrame.previous:Disable();
  end

  if(tutData.steps[step + 1]) then
    stepFrame.next:Enable();
    stepFrame.next:SetScript("OnClick", function()
      WeakAuras.PlayTutorial(tutData, step + 1);
    end);
  else
    stepFrame.next:Disable();
  end
end

function WeakAuras.CreateTutorialsFrame()
  tutFrame = AceGUI:Create("Frame");
  tutFrame:SetTitle(L["WeakAuras Tutorials"]);
  tutFrame:SetWidth(400);
  tutFrame:SetHeight(400);

  local stepFrame = CreateFrame("frame", nil, tutFrame.frame);
  tutFrame.stepFrame = stepFrame;
  stepFrame:SetAllPoints(tutFrame.frame);

  local stepFrameContent = AceGUI:Create("InlineGroup");
  stepFrame.content = stepFrameContent;
  stepFrameContent.frame:SetParent(stepFrame);
  stepFrameContent.frame:SetPoint("top", stepFrame, "top", 0, -10);
  stepFrameContent.frame:SetPoint("left", stepFrame, "left", 17, 0);
  stepFrameContent.frame:SetPoint("right", stepFrame, "right", -17, 0);
  stepFrameContent.frame:SetPoint("bottom", stepFrame, "bottom", 0, 67);
  stepFrameContent:SetLayout("fill");

  local stepFrameScroll = AceGUI:Create("ScrollFrame");
  stepFrame.scroll = stepFrameScroll;
  stepFrameContent:AddChild(stepFrameScroll);
  stepFrameScroll:SetLayout("fill");

  local stepTitle = stepFrameScroll.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge");
  stepFrame.title = stepTitle;
  stepTitle:SetJustifyH("LEFT");
  stepTitle:SetPoint("TOPLEFT", stepFrameScroll.content, "TOPLEFT", 40, -5);

  local stepTexture = stepFrameScroll.content:CreateTexture(nil, "OVERLAY");
  stepFrame.texture = stepTexture;
  stepTexture:SetWidth(100);
  stepTexture:SetHeight(1);
  stepTexture:SetPoint("TOP", stepFrameScroll.content, "TOP", 0, -35);
  stepTexture:Hide();

  local stepText = stepFrameScroll.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  stepFrame.text = stepText;
  stepText:SetJustifyH("LEFT");
  stepText:SetJustifyV("TOP");
  stepText:SetWordWrap(true);
  stepText:SetPoint("left", stepFrameScroll.content, "left", 20, 0);
  stepText:SetPoint("top", stepTexture, "bottom", 0, -20);
  -- stepText:SetPoint("right", stepFrameScroll.content, "right", -30);
  stepText:SetWidth(250);
  stepFrameScroll.content:SetScript("OnUpdate", function()
    stepText:SetWidth(stepFrameScroll.content:GetWidth() - 40);
  end);

  function stepFrameScroll.RecalculateHeight()
    local height = 80 + stepTexture:GetHeight() + stepText:GetHeight();
    stepFrameScroll.content:SetHeight(height);
    stepFrameScroll:FixScroll();
  end

  local stepFrameNext = CreateFrame("Button", nil, stepFrame, "UIPanelButtonTemplate");
  stepFrame.next = stepFrameNext;
  stepFrameNext:SetPoint("BOTTOMRIGHT", -27, 44);
  stepFrameNext:SetHeight(20);
  stepFrameNext:SetWidth(100);
  stepFrameNext:SetText(L["Next"]);

  local stepFrameHome = CreateFrame("Button", nil, stepFrame, "UIPanelButtonTemplate");
  stepFrame.home = stepFrameHome;
  stepFrameHome:SetPoint("BOTTOM", 0, 44);
  stepFrameHome:SetHeight(20);
  stepFrameHome:SetWidth(100);
  stepFrameHome:SetText(L["Home"]);
  stepFrameHome:SetScript("OnClick", WeakAuras.ShowTutorialHome);

  local stepFramePrevious = CreateFrame("Button", nil, stepFrame, "UIPanelButtonTemplate");
  stepFrame.previous = stepFramePrevious;
  stepFramePrevious:SetPoint("BOTTOMLEFT", 27, 44);
  stepFramePrevious:SetHeight(20);
  stepFramePrevious:SetWidth(100);
  stepFramePrevious:SetText(L["Previous"]);

  stepFrame:Hide();

  local homeFrame = CreateFrame("frame", nil, tutFrame.frame);
  tutFrame.homeFrame = homeFrame;
  homeFrame:SetAllPoints(tutFrame.frame);

  local homeFrameContent = AceGUI:Create("InlineGroup");
  homeFrame.content = homeFrameContent;
  homeFrameContent.frame:SetParent(homeFrame);
  homeFrameContent.frame:SetPoint("top", homeFrame, "top", 0, -10);
  homeFrameContent.frame:SetPoint("left", homeFrame, "left", 17, 0);
  homeFrameContent.frame:SetPoint("right", homeFrame, "right", -17, 0);
  homeFrameContent.frame:SetPoint("bottom", homeFrame, "bottom", 0, 37);
  homeFrameContent:SetLayout("fill");

  local homeFrameScroll = AceGUI:Create("ScrollFrame");
  homeFrame.scroll = homeFrameScroll;
  homeFrameContent:AddChild(homeFrameScroll);
  homeFrameScroll:SetLayout("AbsoluteList");

  local toSort = {};
  for tutName, tutData in pairs(tutorials) do
    tinsert(toSort, tutData);
  end
  table.sort(toSort, function(a, b)
    local aOrder = a.order or 0;
    local bOrder = b.order or 0;
    if(aOrder == bOrder) then
      return a.displayName < b.displayName;
    else
      return aOrder < bOrder;
    end
  end);

  for index, tutData in pairs(toSort) do
    local tutButton = AceGUI:Create("WeakAurasNewButton");
    tutButton:SetTitle(tutData.displayName);
    tutButton:SetDescription(tutData.description);
    if(type(tutData.icon) == "string") then
      tutButton:SetIcon(tutData.icon);
    elseif(type(tutData.icon) == "function") then
      tutButton:SetIcon(tutData.icon());
    end

    tutButton:SetClick(function()
      WeakAuras.PlayTutorial(tutData);
    end);

    homeFrameScroll:AddChild(tutButton);
  end

  homeFrameScroll:DoLayout();
end