--Localization

local L = WeakAuras.L;

local steps = {
    {
        title = "New in 1.4",
        text = "Version 1.4 of |cFF8800FFWeakAuras|r introduces several powerful new features.\n\nThis tutorial provides an overview of the most impotant new capabilities, and how to use them.",
        texture = {
            width = 100,
            height = 100,
            path = "Interface\\AddOns\\WeakAuras\\icon.tga",
            color = {0.8333, 0, 1}
        },
        path = {function() return WeakAuras.OptionsFrame() end}
    },
    {
        title = "New in 1.4",
        text = "First, create a new display for demonstration purposes.",
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
        title = "Auto-cloning 1/10",
        text = "The biggest featured added in |cFF8800FF1.4|r is |cFFFF0000auto-cloning|r. |cFFFF0000Auto-cloning|r allows your displays to automatically duplicate themselves to show multiple sources of information. When placed in a Dynamic Group, this allows you to create extensive dynamic sets of information.\n\nThere are three trigger types that support |cFFFF0000auto-cloning|r: Full Scan Auras, Group Auras, and Multi-target Auras.",
        path = {"display", "", "options", "trigger"}
    },
    {
        title = "Full-scan Auras 2/10",
        text = "First, enable the Full Scan option.",
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
        title = "Full-scan Auras 3/10",
        text = "|cFFFF0000Auto-cloning|r can now be enabled using the "..L["Show all matches (Auto-clone)"].." option.\n\nThis causes a new display to be created for every aura that matches the given parameters.",
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
        title = "Full-scan Auras 4/10",
        text = "A popup should appear, informing you that |cFFFF0000auto-cloned|r displays should generally be used in Dynamic Groups.\n\nPress \"Yes\" to allow |cFF8800FFWeakAuras|r to automatically put your display in a Dynamic Group.",
        path = {function() return StaticPopup1 end},
        autoadvance = {
            test = function()
                return not(StaticPopup1 and StaticPopup1:IsVisible())
            end
        }
    },
    {
        title = "Full-scan Auras 5/10",
        text = "Disable the Full Scan option to re-enable other Unit option selections.",
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
        title = "Group Auras 6/10",
        text = "Now, select \"Group\" for the Unit option.",
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
        title = "Group Auras 7/10",
        text = "|cFFFF0000Auto-cloning|r is, again, enabled using the "..L["Show all matches (Auto-clone)"].." option.\n\nA new display will be created for every member of your group that is affected by the specified aura(s).",
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
        title = "Group Auras 8/10",
        text = "Enabling the "..L["Inverse"].." option for a Group Aura with |cFFFF0000auto-cloning|r enabled will cause a new display for each member of your group that is |cFFFFFFFFnot|r affected by the specified aura(s).",
        path = {"display", "", "options", "trigger", L["Inverse"]}
    },
    {
        title = "Multi-target Auras 9/10",
        text = "Finally, select \"Multi-target\" for the Unit option.",
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
        title = "Multi-target Auras 10/10",
        text = "Multi-target auras have |cFFFF0000auto-cloning|r by default.\n\nMulti-target Auras triggers are different from normal Aura triggers because they are based on Combat Log events, which means they will track auras on mobs that nobody is targeting (although some dynamic information is not available without someone in your group targeting the unit).\n\nThis makes Multi-target auras a good choice for tracking DoTs on multiple enemies.",
        path = {"display", "", "options", "trigger"}
    },
    {
        title = "Trigger Options 1/4",
        text = "In addition to \"Multi-target\", there is another new setting for the Unit option: Specific Unit.\n\nSelect it to be able to create a new text field.",
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
        title = "Trigger Options 2/4",
        text = "In this field, you can specify the name of any player in your group, or a custom Unit ID. Unit IDs such as \"boss1\", \"boss2\", etc. are especially useful for raid encounters.\n\nAll triggers that allow you to specify a unit (not just Aura triggers) now support the Specific Unit option.",
        path = {"display", "", "options", "trigger", {L["Specific Unit"], 2}}
    },
    {
        title = "Trigger Options 3/4",
        text = "|cFF8800FFWeakAuras 1.4|r also adds some new Trigger types.\n\nSelect the Status category to take a look at them.",
        path = {"display", "", "options", "trigger", {L["Type"], 2}},
        autoadvance = {
            path = {"trigger", "type"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                return currentValue == "status";
            end
        }
    },
    {
        title = "Trigger Options 4/4",
        text = "The |cFFFFFFFFUnit Characteristics|r trigger allows you test a unit's name, class, hostility, and whether it is a player or non-player character.\n\n|cFFFFFFFFGlobal Cooldown|r and |cFFFFFFFFSwing Timer|r triggers complement the Cast trigger.",
        path = {"display", "", "options", "trigger", L["Status"]}
    },
    {
        title = "Dynamic Group Options 1/4",
        text = "|cFFFFFFFFDynamic Groups|r have several new capabilities in |cFF8800FF1.4|r.\n\nFor this part of the Tutorial, it is best if you select a |cFFFFFFFFDynamic Group|r with more than two children, although any |cFFFFFFFFDynamic Group|r will do.",
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
        title = "Dynamic Group Options 2/4",
        text = "The biggest improvement to |cFFFFFFFFDynamic Group|rs is a new selection for the Grow option.\n\nSelect \"Circular\" to see it in action.",
        path = {"display", "", "options", "group", L["Grow"]},
        autoadvance = {
            path = {"grow"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                return currentValue == "CIRCLE";
            end
        }
    },
    {
        title = "Dynamic Group Options 3/4",
        text = "The Constant Factor options allows you to control how your circular group grows.\n\nA circular group with a constant spacing grows in radius as more displays are added, whereas a constant radius causes displays to simply get closer together as more are added.",
        path = {"display", "", "options", "group", L["Constant Factor"]}
    },
    {
        title = "Dynamic Group Options 4/4",
        text = "Dynamic Groups now can now automatically sort their children by Remaining Time.\n\nDisplays that don't have Remaining Time are placed at the top or bottom, depending on if you choose \"Ascending\" or \"Descending\".",
        path = {"display", "", "options", "group", L["Sort"]}
    },
    {
        title = "Display Options 1/4",
        text = "Now, select a Progress Bar display (or create a new one).",
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
        title = "Display Options 2/4",
        text = "|cFFFFFFFFProgress Bar|r displays now support Dynamic Text options, just like Text displays. See the tooltip for more information on Dynamic Text codes.\n\n|cFFFFFFFFIcon|r displays also have a Dynamic Text field.",
        path = {"display", "", "options", "region", L["Left Text"]}
    },
    {
        title = "Display Options 2/4",
        text = "|cFFFFFFFFProgress Bar|r and |cFFFFFFFFIcon|r displays now have an option to show tooltips when you mouse over them.\n\nThis option is only available if your display uses a trigger based on an aura, item, or spell.",
        path = {"display", "", "options", "region", L["Tooltip on Mouseover"]}
    },
    {
        title = "Display Options 4/4",
        text = "Finally, a new display type, |cFFFFFFFFModel|r, allows you to harness any 3D model from the game files.",
        path = {"new", L["Model"]}
    },
    {
        title = "Finished",
        text = "Of course, there are more new features in |cFF8800FFWeakAuras 1.4|r than can be covered all at once, not to mention countless bug fixes and efficiency improvements.\n\nHopefully, this Tutorial has at least guided you towards the major new capabilities that are available to you.\n\nThank you for using |cFF8800FFWeakAuras|r!",
        texture = {
            width = 100,
            height = 100,
            path = "Interface\\AddOns\\WeakAuras\\icon.tga",
            color = {0.8333, 0, 1}
        },
        path = {function() return WeakAuras.OptionsFrame() end}
    },
}

local function icon()
    local region = CreateFrame("frame");
    local texture = region:CreateTexture(nil, "overlay");
    texture:SetTexture("Interface\\AddOns\\WeakAuras\\icon.tga");
    texture:SetVertexColor(1, 1, 0);
    texture:SetAllPoints(region);
    
    return region;
end

WeakAuras.RegisterTutorial("newfeatures", "New in 1.4", "See the new features of WeakAuras 1.4", icon, steps, 1);