--Localization
local L = WeakAuras.L;

local steps = {
    {
        title = L["New in 1.4:"],
        text = L["New in 1.4 Text1"],
        texture = {
            width = 100,
            height = 100,
            path = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon.blp",
            color = {0.8333, 0, 1}
        },
        path = {function() return WeakAuras.OptionsFrame() end}
    },
    {
        title = L["New in 1.4:"],
        text = L["New in 1.4 Text2"],
        path = {"new", L["Progress Bar"]},
        autoadvance = {
            test = function()
                local id = WeakAuras.OptionsFrame().pickedDisplay;
                if(type(id) == "string") then
                    if(WeakAuras.GetData(id).regionType == "aurabar") then
                        return true
                    end
                end
            end
        }
    },
    {
        title = L["Auto-cloning: 1/10"],
        text = L["Auto-cloning 1/10 Text"],
        path = {"display", "", "options", "trigger"}
    },
    {
        title = L["Full-scan Auras: 2/10"],
        text = L["Full-scan Auras 2/10 Text"],
        path = {"display", "", "options", "trigger", L["Use Full Scan (High CPU)"]},
        autoadvance = {
            path = {"trigger", "fullscan"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and (
                    data.trigger.type == "aura"
                    and data.trigger.unit ~= "group"
                    and data.trigger.fullscan
                )) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Full-scan Auras: 3/10"],
        text = L["Full-scan Auras 3/10 Text"]:format(L["Show all matches (Auto-clone)"]),
        path = {"display", "", "options", "trigger", {L["Show all matches (Auto-clone)"], 1}},
        autoadvance = {
            path = {"trigger", "autoclone"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and (
                    data.trigger.type == "aura"
                    and data.trigger.unit ~= "group"
                    and data.trigger.autoclone
                )) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Full-scan Auras: 4/10"],
        text = L["Full-scan Auras 4/10 Text"],
        path = {function() return StaticPopup1 end},
        autoadvance = {
            test = function()
                return not(StaticPopup1 and StaticPopup1:IsVisible())
            end
        }
    },
    {
        title = L["Full-scan Auras: 5/10"],
        text = L["Full-scan Auras 5/10 Text"],
        path = {"display", "", "options", "trigger", L["Use Full Scan (High CPU)"]},
        autoadvance = {
            path = {"trigger", "autoclone"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and not data.trigger.fullscan) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Group Auras: 6/10"],
        text = L["Group Auras 6/10 Text"],
        path = {"display", "", "options", "trigger", {L["Unit"], 2}},
        autoadvance = {
            path = {"trigger", "unit"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and (
                    data.trigger.type == "aura"
                    and data.trigger.unit == "group"
                )) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Group Auras: 7/10"],
        text = L["Group Auras 7/10 Text"]:format(L["Show all matches (Auto-clone)"]),
        path = {"display", "", "options", "trigger", {L["Show all matches (Auto-clone)"], 1}},
        autoadvance = {
            path = {"trigger", "groupclone"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and (
                    data.trigger.type == "aura"
                    and data.trigger.unit == "group"
                    and data.trigger.groupclone
                )) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Group Auras: 8/10"],
        text = L["Group Auras 8/10 Text"]:format(L["Inverse"]),
        path = {"display", "", "options", "trigger", L["Inverse"]}
    },
    {
        title = L["Multi-target Auras: 9/10"],
        text = L["Multi-target Auras 9/10 Text"],
        path = {"display", "", "options", "trigger", {L["Unit"], 2}},
        autoadvance = {
            path = {"trigger", "unit"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and (
                    data.trigger.type == "aura"
                    and data.trigger.unit == "multi"
                )) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Multi-target Auras: 10/10"],
        text = L["Multi-target Auras 10/10 Text"],
        path = {"display", "", "options", "trigger"}
    },
    {
        title = L["Trigger Options: 1/4"],
        text = L["Trigger Options 1/4 Text"],
        path = {"display", "", "options", "trigger", {L["Unit"], 2}},
        autoadvance = {
            path = {"trigger", "unit"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and (
                    data.trigger.type == "aura"
                    and data.trigger.unit == "member"
                )) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Trigger Options: 2/4"],
        text = L["Trigger Options 2/4 Text"],
        path = {"display", "", "options", "trigger", {L["Specific Unit"], 2}}
    },
    {
        title = L["Trigger Options: 3/4"],
        text = L["Trigger Options 3/4 Text"],
        path = {"display", "", "options", "trigger", {L["Type"], 2}},
        autoadvance = {
            path = {"trigger", "type"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                return currentValue == "status";
            end
        }
    },
    {
        title = L["Trigger Options: 4/4"],
        text = L["Trigger Options 4/4 Text"],
        path = {"display", "", "options", "trigger", L["Status"]}
    },
    {
        title = L["Dynamic Group Options: 1/4"],
        text = L["Dynamic Group Options 1/4 Text"],
        path = {WeakAuras.OptionsFrame().buttonsScroll},
        autoadvance = {
            test = function()
                local id = WeakAuras.OptionsFrame().pickedDisplay;
                if(type(id) == "string") then
                    if(WeakAuras.GetData(id).regionType == "dynamicgroup") then
                        return true
                    end
                end
            end
        }
    },
    {
        title = L["Dynamic Group Options: 2/4"],
        text = L["Dynamic Group Options 2/4 Text"],
        path = {"display", "", "options", "group", L["Grow"]},
        autoadvance = {
            path = {"grow"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                return currentValue == "CIRCLE";
            end
        }
    },
    {
        title = L["Dynamic Group Options: 3/4"],
        text = L["Dynamic Group Options 3/4 Text"],
        path = {"display", "", "options", "group", L["Constant Factor"]}
    },
    {
        title = L["Dynamic Group Options: 4/4"],
        text = L["Dynamic Group Options 4/4 Text"],
        path = {"display", "", "options", "group", L["Sort"]}
    },
    {
        title = L["Display Options: 1/4"],
        text = L["Display Options 1/4 Text"],
        path = {WeakAuras.OptionsFrame().buttonsScroll},
        autoadvance = {
            test = function()
                local id = WeakAuras.OptionsFrame().pickedDisplay;
                if(type(id) == "string") then
                    if(WeakAuras.GetData(id).regionType == "aurabar") then
                        return true
                    end
                end
            end
        }
    },
    {
        title = L["Display Options: 2/4"],
        text = L["Display Options 2/4 Text"],
        path = {"display", "", "options", "region", L["Left Text"]}
    },
    {
        title = L["Display Options: 2/4"],
        text = L["Display Options 2/4 Text"],
        path = {"display", "", "options", "region", L["Tooltip on Mouseover"]}
    },
    {
        title = L["Display Options: 4/4"],
        text = L["Display Options 4/4 Text"],
        path = {"new", L["Model"]}
    },
    {
        title = L["Finished"],
        text = L["New in 1.4 Finished Text"],
        texture = {
            width = 100,
            height = 100,
            path = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon.blp",
            color = {0.8333, 0, 1}
        },
        path = {function() return WeakAuras.OptionsFrame() end}
    },
}

local function icon()
    local region = CreateFrame("frame");
    local texture = region:CreateTexture(nil, "overlay");
    texture:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\icon.blp");
    texture:SetVertexColor(1, 1, 0);
    texture:SetAllPoints(region);
    
    return region;
end

WeakAuras.RegisterTutorial("newfeatures", L["New in 1.4 Desc:"], L["New in 1.4 Desc Text"], icon, steps, 1);