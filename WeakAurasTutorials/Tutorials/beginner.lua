--Localization
local L = WeakAuras.L;


--Tutorial
local _, class = UnitClass("player");
local aura, spell;
if(class == "MAGE") then
    aura = select(1, GetSpellInfo("Arcane Brilliance"));
    spell = select(1, GetSpellInfo("Frost Nova"));
elseif(class == "PRIEST") then
    aura = select(1, GetSpellInfo("Power Word: Fortitude"));
    spell = select(1, GetSpellInfo("Mind Blast"));
elseif(class == "WARLOCK") then
    aura = select(1, GetSpellInfo("Demon Armor"));
    spell = select(1, GetSpellInfo("Soul Harvest"));
elseif(class == "ROGUE") then
    aura = select(1, GetSpellInfo("Sprint"));
    spell = select(1, GetSpellInfo("Kick"));
elseif(class == "DRUID") then
    aura = select(1, GetSpellInfo("Mark of the Wild"));
    spell = select(1, GetSpellInfo("Thorns"));
elseif(class == "SHAMAN") then
    aura = select(1, GetSpellInfo("Lightning Shield"));
    spell = select(1, GetSpellInfo("Earth Shock"));
elseif(class == "HUNTER") then
    aura = select(1, GetSpellInfo("Aspect of the Hawk"));
    spell = select(1, GetSpellInfo("Disengage"));
elseif(class == "PALADIN") then
    aura = select(1, GetSpellInfo("Blessing of Kings"));
    spell = select(1, GetSpellInfo("Judgement"));
elseif(class == "WARRIOR") then
    aura = select(1, GetSpellInfo("Battle Shout"));
    spell = select(1, GetSpellInfo("Charge"));
elseif(class == "DEATHKNIGHT") then
    aura = select(1, GetSpellInfo("Horn of Winter"));
    spell = select(1, GetSpellInfo("Death and Decay"));
end
local className = WeakAuras.class_types[class];
aura = "|cFFFFFFFF"..aura.."|r";
spell = "|cFFFFFFFF"..aura.."|r";

local steps = {
    {
        title = L["Welcome"],
        text = L["Welcome Text"],
        texture = {
            width = 100,
            height = 100,
            path = "Interface\\AddOns\\WeakAuras\\icon.tga",
            color = {0.8333, 0, 1}
        },
        path = {function() return WeakAuras.OptionsFrame() end}
    },
    {
        title = L["Create a Display: 1/5"],
        text = L["Create a Display Text"],
        path = {"new"}
    },
    {
        title = L["Create a Display: 2/5"],
        text = L["Create a Display Text"],
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
        title = L["Create a Display: 3/5"],
        text = L["Create a Display Text"]:format(aura, aura),
        path = {"display", "", "button", "renamebox"},
        autoadvance = {
            test = function()
                local id = WeakAuras.OptionsFrame().pickedDisplay;
                if(type(id) == "string") then
                    if("|cFFFFFFFF"..(id or "none").."|r" == aura) then
                        return true
                    end
                end
            end
        }
    },
    {
        title = L["Create a Display: 4/5"],
        text = L["Create a Display Text"],
        path = {"display", "", "options", "region"}
    },
    {
        title = L["Create a Display: 5/5"],
        text = L["Create a Display Text"],
        path = {function() return WeakAuras.OptionsFrame().moversizer end}
    },
    {
        title = L["Activation Settings: 1/5"],
        text = L["Activation Settings Text"],
        path = {"display", "", "options", "trigger", {WeakAuras.L["Type"], 2}}
    },
    {
        title = L["Activation Settings: 2/5"],
        text = L["Activation Settings Text"]:format(aura, aura),
        path = {"display", "", "options", "trigger", WeakAuras.L["Aura Name"]},
        autoadvance = {
            path = {"trigger", "names"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and (
                    data.trigger.type == "aura"
                    and data.trigger.unit ~= "multi"
                    and "|cFFFFFFFF"..(data.trigger.names[1] or "none").."|r" == aura
                )) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Activation Settings: 3/5"],
        text = L["Activation Settings Text"],
        path = {"display", "", "options", "trigger"}
    },
    {
        title = L["Activation Settings: 4/5"],
        text = L["Activation Settings Text"],
        path = {"display", "", "options", "load"}
    },
    {
        title = L["Activation Settings: 5/5"],
        text = L["Activation Settings Text"]:format(className, className),
        path = {"display", "", "options", "load", {WeakAuras.L["Player Class"], 2}},
        autoadvance = {
            path = {"load", "class", "single"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and data.load.use_class == true and data.load.class.single == class) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Actions and Animations: 1/7"],
        text = L["Actions and Animations Text"],
        path = {"display", "", "options", "action"}
    },
    {
        title = L["Actions and Animations: 2/7"],
        text = L["Actions and Animations Text"],
        path = {"display", "", "options", "action", WeakAuras.L["Play Sound"]},
        autoadvance = {
            path = {"load", "class", "single"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and data.actions.start.do_sound) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Actions and Animations: 3/7"],
        text = L["Actions and Animations Text"],
        path = {"display", "", "options", "action", WeakAuras.L["Sound"]},
        autoadvance = {
            path = {"load", "class", "single"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and data.actions.start.sound) then
                    return true;
                end
            end
        }
    },
    {
        title = L["Actions and Animations: 4/7"],
        text = L["Actions and Animations Text"],
        path = {"display", "", "options", "animation"}
    },
    {
        title = L["Actions and Animations: 5/7"],
        text = L["Actions and Animations Text"],
        path = {"display", "", "options", "animation", WeakAuras.L["Type"]},
        autoadvance = {
            path = {"animation", "start", "type"},
            test = function(previousValue, currentValue, previousPicked, currentPicked)
                local data = type(currentPicked) == "string" and WeakAuras.GetData(currentPicked);
                if(data and currentValue == "preset") then
                    return true;
                end
            end
        }
    },
    {
        title = L["Actions and Animations: 6/7"],
        text = L["Actions and Animations Text"],
        path = {"display", "", "options", "animation", WeakAuras.L["Preset"]}
    },
    {
        title = L["Actions and Animations: 7/7"],
        text = L["Actions and Animations Text"],
        path = {"display", "", "button", "view"}
    },
    {
        title = L["Finished"],
        text = L["Beginners Finished Text"],
        texture = {
            width = 100,
            height = 100,
            path = "Interface\\AddOns\\WeakAuras\\icon.tga",
            color = {1, 0, 0}
        },
        path = {function() return WeakAuras.TutorialsFrame().stepFrame.home end}
    }
}

local function icon()
    local region = CreateFrame("frame");
    local texture = region:CreateTexture(nil, "overlay");
    texture:SetTexture("Interface\\AddOns\\WeakAuras\\icon.tga");
    texture:SetVertexColor(0, 1, 0);
    texture:SetAllPoints(region);
    
    return region;
end

WeakAuras.RegisterTutorial("beginner", L["Beginners Guide Desc"], L["Beginners Guide Desc Text"], icon, steps, 1);