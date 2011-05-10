local tutFrame;
local tutorials = WeakAuras.tutorials
local optionsFrame;
if(WeakAuras.OptionsFrame) then
    optionsFrame = WeakAuras.OptionsFrame()
end

do
    local elapsed = 0;
    local anchorDelay = 1;
    local anchorPath;
    
    local function ContinuosAnchorUpdate(frame, elaps)
        elapsed = elapsed + elaps;
        if(elapsed > anchorDelay) then
            elapsed = elapsed - anchorDelay;
            
            WeakAuras.AnchorTutorialToPath(anchorPath);
        end
    end

    function WeakAuras.ContinuouslyAnchorTutorialToPath(path);
        if(path) then
            anchorPath = path;
        else
            tutFrame:SetScript("OnUpdate", nil);
        end
    end
    
    local toSort = {};
    function WeakAuras.AnchorTutorialToPath(path)
        if(optionsFrame and optionsFrame:IsVisible()) then
            if(path[1] == "new") then
                if(optionsFrame.pickedOption == "New") then
                    if(path[2]) then
                        for index, child in pairs(optionsFrame.container.children) do
                            if(child:GetName() == path[2]) then
                                WeakAuras.AnchorTutorialToFrame(child);
                            end
                        end
                    else
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.container);
                    end
                else
                    local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(optionsFrame.newButton);
                    if(sidebarVisible == true) then
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.newButton);
                    elseif(sidebarVisible == "above" or sidebarVisible == "below") then
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
                    elseif(sidebarVisible == "hidden") then
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll);
                    end
                end
            elseif(path[1] == "addons") then
                if(optionsFrame.pickedOption == "Addons") then
                    WeakAuras.AnchorTutorialToFrame(optionsFrame.container);
                else
                    local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(optionsFrame.addonsButton);
                    if(sidebarVisible == true) then
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.addonsButton);
                    elseif(sidebarVisible == "above" or sidebarVisible == "below") then
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
                    elseif(sidebarVisible == "hidden") then
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll);
                    end
                end
            elseif(path[1] == "loaded") then
                local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(optionsFrame.loadedButton);
                if(sidebarVisible == true) then
                    WeakAuras.AnchorTutorialToFrame(optionsFrame.loadedButton);
                elseif(sidebarVisible == "above" or sidebarVisible == "below") then
                    WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
                elseif(sidebarVisible == "hidden") then
                    WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll);
                end
            elseif(path[1] == "unloaded") then
                local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(optionsFrameunloadedButton);
                if(sidebarVisible == true) then
                    WeakAuras.AnchorTutorialToFrame(optionsFrame.unloadedButton);
                elseif(sidebarVisible == "above" or sidebarVisible == "below") then
                    WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
                elseif(sidebarVisible == "hidden") then
                    WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll);
                end
            elseif(path[1] == "display") then
                local id;
                if(path[2] ~= "") then
                    id = path[2];
                elseif(optionsFrame.pickedDisplay) then
                    if(type(optionsFrame.pickedDisplay) == "table") then
                        id = optionsFrame.pickedDisplay.controlledChildren[1];
                    else
                        id = optionsFrame.pickedDisplay;
                    end
                end
                
                if(id) then
                    local button = WeakAuras.displayButtons[id];
                    local sidebarVisible = optionsFrame.buttonsScroll:IsChildInView(button);
                    if(sidebarVisible == true) then
                        if(step[3] == "button") then
                            if(step[4]) then
                                local buttonPiece = button[step[4]];
                                WeakAuras.AnchorTutorialToFrame(buttonPiece);
                            else
                                WeakAuras.AnchorTutorialToFrame(button);
                            end
                        elseif(step[3] == "options") then
                            if(step[4]) then
                                local optionsTable = WeakAuras.displayOptions[id];
                                local tabName = optionsTable and optionsTable.args[step[4]] and optionsTable.args[step[4]].name
                                local tabFrame;
                                local tabSelected = false;
                                for i,v in pairs(WeakAuras.OptionsFrame().container.children[1].tabs) do
                                    if(v:GetText() == tabName) then
                                        tabFrame = v;
                                        if(v.selected) then
                                            tabSelected = true;
                                        end
                                    end
                                end
                                
                                if(tabFrame and step[5]) then
                                    if not(tabSelected) then
                                        WeakAuras.AnchorTutorialToFrame(tabFrame);
                                    elseif(WeakAuras.OptionsFrame().container.children[1].children[1].children) then
                                        wipe(toSort);
                                        
                                        for optionName, optionTable in pairs(optionsTable.args[step[4]].args) do
                                            tinsert(toSort, {name = optionName, table = optionTable});
                                        end
                                        table.sort(toSort, function(a,b) return a.table.order < b.table.order end);
                                        
                                        local optionIndex;
                                        for index, optionData in pairs(toSort) do
                                            if(optionData.name == step[5]) then
                                                optionIndex = index;
                                                break;
                                            end
                                        end
                                        
                                        if(optionIndex and WeakAuras.OptionsFrame().container.children[1].children[1].children[optionIndex]) then
                                            WeakAuras.AnchorTutorialToFrame(WeakAuras.OptionsFrame().container.children[1].children[1].children[optionIndex]);
                                        else
                                            WeakAuras.AnchorTutorialToFrame(optionsFrame.container);
                                        end
                                    else
                                        WeakAuras.AnchorTutorialToFrame(optionsFrame.container);
                                    end
                                else
                                    WeakAuras.AnchorTutorialToFrame(optionsFrame.container);
                                end
                            else
                                WeakAuras.AnchorTutorialToFrame(optionsFrame.container);
                            end
                        end
                    elseif(sidebarVisible == "above" or sidebarVisible == "below") then
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll.scrollbar);
                    elseif(sidebarVisible == "hidden") then
                        WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll);
                    end
                else
                    WeakAuras.AnchorTutorialToFrame(optionsFrame.buttonsScroll);
                end
            end
        end
    end
    
    function WeakAuras.AnchorTutorialToFrame(frame)
        --get edges of options frame and moversizer, determine how tutorial frame best fits in between the two
        --position tutorial frame accordingly
        
        WeakAuras.PointTutorialToFrame(frame);
    end
    
    function WeakAuras.PointTutorialToFrame(frame)
        --calculate angle between closest edge of tutorial frame and anchor frame
        
        --appropriately remove border of tutorial frame and required angle
        --add a border (a glow animation, posssibly?) around the anchor frame
        --draw the "arrow" from the edge of the tutorial frame to the anchor frame
    end
end

function WeakAuras.ShowTutorialPicker()
    tutFrame.stepFrame:Hide();
    tutFrame.homeFrame:Show();
end

function WeakAuras.PlayTutorial(tutData, step)
    tutFrame.homeFrame:Hide();
    tutFrame.stepFrame:Show();
    local stepFrame = tutFrame.stepFrame;
    
    step = step or 1;
    local stepData = tutData.steps[step];
    
    WeakAuras.ContinuouslyAnchorTutorialToPath(stepData.path);
    
    if(tutData.steps[step - 1]) then
        stepFrame.previous:Enable();
        stepFrame.previous:SetScript("OnClick", function()
            WeakAuras.PlayTutorial(tutData, step - 1);
        end);
    end
    
    if(tutData.steps[step + 1]) then
        stepFrame.next:Enable();
        stepFrame.next:SetScript("OnClick", function()
            WeakAuras.PlayTutorial(tutData, step + 1);
        end);
    end
end

function WeakAuras.CreateTutorialsFrame()
    tutFrame = CreateFrame("frame");
    --Init with yellow border stuff
    
    --Text area
    --Texture area?
    --Maybe just a configurable region?
    
    local stepFrame = CreateFrame("frame", nil, tutFrame);
    tutFrame.stepFrame = stepFrame;
    --Next button
    --Previous button
    --Home button
    stepFrame:Hide();
    
    local homeFrame = CreateFrame("frame", nil, tutFrame);
    tutFrame.homeFrame = homeFrame;
    for tutName, tutData in pairs(tutorials) do
        --make an entry for this tutorial
        --sections?
        --expand/collapse?
        --new AceGUI widget?
        
        --OnClick, WeakAuras.PlayTutorial(tutData)
    end
end