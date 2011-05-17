--Localization

local L = {};

L["Beginners Guide"] = "Beginners Guide"
L["A guide through WeakAuras' basic configuration options"] = "A guide through WeakAuras' basic configuration options"

--Tutorial
local _, class = UnitClass("player");
local aura, spell;
if(class == "MAGE") then
    aura = "Arcane Brilliance";
    spell = "Frost Nova";
elseif(class == "PRIEST") then
    aura = "Power Word: Fortitude";
    spell = "Mind Blast";
elseif(class == "WARLOCK") then
    aura = "Demon Armor";
    spell = "Soul Harvest";
elseif(class == "ROGUE") then
    aura = "Sprint";
    spell = "Kick";
elseif(class == "DRUID") then
    aura = "Mark of the Wild";
    spell = "Thorns";
elseif(class == "SHAMAN") then
    aura = "Lightning Shield";
    spell = "Earth Shock";
elseif(class == "HUNTER") then
    aura = "Aspect of the Hawk";
    spell = "Disengage";
elseif(class == "PALADIN") then
    aura = "Blessing of Kings";
    spell = "Judgement";
elseif(class == "WARRIOR") then
    aura = "Battle Shout";
    spell = "Charge";
elseif(class == "DEATHKNIGHT") then
    aura = "Horn of Winter";
    spell = "Death and Decay";
end
local className = WeakAuras.class_types[class];
aura = "|cFFFFFFFF"..aura.."|r";
spell = "|cFFFFFFFF"..aura.."|r";

local steps = {
    {
        title = "Welcome",
        text = "Welcome to the |cFF8800FFWeakAuras|r Beginners Guide.\n\nThis guide will show how to use WeakAuras, and explain the basic configuration options.",
        texture = {
            width = 100,
            height = 100,
            path = "Interface\\AddOns\\WeakAuras\\icon.tga",
            color = {0.8333, 0, 1}
        },
        path = {function() return WeakAuras.OptionsFrame() end}
    },
    {
        title = "Create a Display: 1/5",
        text = "|cFF8800FFWeakAuras|r is based on \"displays\". Each display represents a graphical object on your screen, and its associated settings.\n\nThe New screen allows you to pick a display type.",
        path = {"new"}
    },
    {
        title = "Create a Display: 2/5",
        text = "There are several different display types that have different appearances and different capabilities. Some are more abstract than others.\n\nFor the purposes of this tutorial, choose to create a Progress Bar.",
        path = {"new", WeakAuras.L["Progress Bar"]}
    },
    {
        title = "Create a Display: 3/5",
        text = ("Each display has a unique name. A display's name does affect it's behavior; it is only for your organization.\n\nSince you are going to create a dipslay for %s, name your display %s."):format(aura, aura),
        path = {"display", "", "button", "renamebox"}
    },
    {
        title = "Create a Display: 4/5",
        text = "Configuration options are split into five sections. The first section, Display, controls appearance and positioning.\n\nMost of these settings have results that are immediately visible. You can try them out and move on when you're satisfied.",
        path = {"display", "", "options", "region"}
    },
    {
        title = "Create a Display: 5/5",
        text = "Although the Display tab has sliders to control Width, Height, and X and Y positioning, there is an easier way to move and size your display.\n\nYou can simply click and drag your display to anywhere on your screen, and click and drag the corners to change the size.\n\nYou can also press Shift to hide the mover/sizer frame, for more accurate placement.",
        path = {function() return WeakAuras.OptionsFrame().moversizer end}
    },
    {
        title = "Activation Settings: 1/5",
        text = "The second section, Trigger, controls when your display will be visible, and what information is passed to it.\n\nThere are many types of triggers, but right now you just need an Aura trigger, which is the default type.",
        path = {"display", "", "options", "trigger", WeakAuras.L["Type"]}
    },
    {
        title = "Activation Settings: 2/5",
        text = "You're going to make your display only appear when you have %s, so type %s into the Aura Name text box.\n\nBy default, |cFF8800FFWeakAuras|r matches auras by name, and it should tell you how many unique spells match the name you've entered.",
        path = {"display", "", "options", "trigger", WeakAuras.L["Aura Name"]}
    },
    {
        title = "Activation Settings: 3/5",
        text = "Other settings on this tab allow further control over various aspects of the aura.\n\nThis display will work the default settings, but as you continue to create Aura triggers, make sure the \"Unit\" and \"Aura Type\" options are always set correctly; if they're not, your display will not work how you want it to.",
        path = {"display", "", "options", "trigger"}
    },
    {
        title = "Activation Settings: 4/5",
        text = "The Load tab also affects the visibility of your display, but in a much more permanent sense. These settings are based on values that do not change often, or at all.\n\nA display whose Load settings are not satisfied will basically not exist to WeakAuras; it will never be visible, and its Trigger will never even be tested.\n\nUsing the Load tab will help you organize displays between different characters and talent specializations. It also helps keep WeakAuras efficient; the less displays that are Loaded when they do not need to be, the less work WeakAuras has to do figuring out whether or not they should be visible.",
        path = {"display", "", "options", "load"}
    },
    {
        title = "Activation Settings: 5/5",
        text = ("Since you are a %s, you can enable the Player Class options and select %s."):format(className, className),
        path = {"display", "", "options", "load", WeakAuras.L["Player Class"]}
    },
    {
        title = "Actions and Animations: 1/7",
        text = "The Actions tab lets you specify side-effects for when your display shows or hides. This includes chat messages, sounds, and custom Lua code.",
        path = {"display", "", "options", "action"}
    },
    {
        title = "Actions and Animations: 2/7",
        text = "For the purpose of demonstration, you'll make your display play a sound when it appears.\n\nEnable the Play Sound option.",
        path = {"display", "", "options", "action", WeakAuras.L["Play Sound"]}
    },
    {
        title = "Actions and Animations: 3/7",
        text = "Pick a sound file from the list.",
        path = {"display", "", "options", "action", WeakAuras.L["Sound"]}
    },
    {
        title = "Actions and Animations: 4/7",
        text = "The final tab, Animations, is exactly what you'd think; it controls animations that alter the appearance of your display.",
        path = {"display", "", "options", "animation"}
    },
    {
        title = "Actions and Animations: 5/7",
        text = "There are three times an animation can play: when your display appears (Start), all the time while your display is visible (Main), or as your display is hiding (Finish).\n\nChange the Start Type from \"None\" to \"Preset\" to enable the Start animation.",
        path = {"display", "", "options", "animation", WeakAuras.L["Type"]}
    },
    {
        title = "Actions and Animations: 6/7",
        text = "The resulting Preset menu allows you to choose a preset Start animation. However, picking an animation type doesn't make anything happen on your screen!\n\nThat's because the animation only plays when your display appears.",
        path = {"display", "", "options", "animation", WeakAuras.L["Preset"]}
    },
    {
        title = "Actions and Animations: 7/7",
        text = "To test your animation, you'll have to hide your display and make it appear again. This can be done using the display's View button on the sidebar.\n\nClick it a few times to see your Start animation.",
        path = {"display", "", "button", "view"}
    },
    {
        title = "Finished",
        text = "That's it for the Beginners Guide. However, you've hardly scratched the surface of |cFF8800FFWeakAuras|r' power.\n\nSee the |cFFFFFF00More|r |cFFFF7F00Advanced|r |cFFFF0000Tutorials|r to dive deeper into |cFF8800FFWeakAuras|r' endless possibilities.",
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

WeakAuras.RegisterTutorial("beginner", L["Beginners Guide"], L["A guide through WeakAuras' basic configuration options"], icon, steps, 1);