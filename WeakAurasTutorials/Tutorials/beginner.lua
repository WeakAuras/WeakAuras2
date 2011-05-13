--Localization

local L = {};

L["Beginner's Guide to WeakAuras"] = "Beginner's Guide to WeakAuras"
L["Quickly learn the basics of WeakAuras' configuration"] = "Quickly learn the basics of WeakAuras' configuration"

--Tutorial
local steps = {
    {
        title = "Step 1",
        text = "This is the first step in this example tutorial. There's not really a whole lot to it, to be honest. It just points to the New button on the sidebar.",
        path = {
            "new"
        }
    },
    {
        title = "Step 2",
        text = "This is the second step in this example tutorial. There's a texture defined that shows the WeakAuras icon, but beyond that, not much. This step points to the Loaded header button.",
        texture = {
            width = 100,
            height = 100,
            path = "Interface\\AddOns\\WeakAuras\\icon.tga"
        },
        path = {
            "loaded"
        }
    },
    {
        title = "Step 3",
        text = "Now the tutorial is done. This step is a little more complicated because it tries to point to a specific display named \"Armor\", and if such a display exists, it also tries to point to a specific option in that display's configuration.\n\nThe part where it points to a specific option now works as expected!.",
        path = {
            "display",
            "Armor",
            "options",
            "trigger",
            "Aura Name"
        }
    }
}


WeakAuras.RegisterTutorial("beginner", L["Beginner's Guide to WeakAuras"], L["Quickly learn the basics of WeakAuras' configuration"], "Interface\\AddOns\\WeakAuras\\icon.tga", steps);