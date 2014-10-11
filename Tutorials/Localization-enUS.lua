local L = WeakAuras.L

-- Options translation
--@localization(locale="enUS", format="lua_additive_table", namespace="WeakAuras / Tutorials")@

-- Make missing translations available
setmetatable(WeakAuras.L, {__index = function(self, key)
	self[key] = (key or "")
	return key
end})


--@do-not-package@

-- Main translation
L["WeakAuras Tutorials"] = "WeakAuras Tutorials"
L["Home"] = "Home"
L["Previous"] = "Previous"
L["Finished"] = "Finished"

-- Beginner
L["Beginners Guide Desc"] = "Beginners Guide"
L["Beginners Guide Desc Text"] = "A guide through WeakAuras' basic configuration options"
L["Welcome"] = "Welcome"
L["Welcome Text"] = [=[Welcome to the |cFF8800FFWeakAuras|r Beginners Guide.

This guide will show how to use WeakAuras, and explain the basic configuration options.]=]
L["Create a Display: 1/5"] = "Create a Display: 1/5"
L["Create a Display Text"] = [=[|cFF8800FFWeakAuras|r is based on \"displays\". Each display represents a graphical object on your screen, and its associated settings.

The New screen allows you to pick a display type.]=]
L["Create a Display: 2/5"] = "Create a Display: 2/5"
L["Create a Display Text"] = [=[There are several different display types that have different appearances and different capabilities. Some are more abstract than others.

For the purposes of this tutorial, choose to create a Progress Bar.]=]
L["Create a Display: 3/5"] = "Create a Display: 3/5"
L["Create a Display Text"] = [=[Each display has a unique name. A display's name does affect it's behavior; it is only for your organization.

Since you are going to create a dipslay for %s, name your display %s.]=]
L["Create a Display: 4/5"] = "Create a Display: 4/5"
L["Create a Display Text"] = [=[Configuration options are split into five sections. The first section, Display, controls appearance and positioning.

Most of these settings have results that are immediately visible. You can try them out and move on when you're satisfied.]=]
L["Create a Display: 5/5"] = "Create a Display: 5/5"
L["Create a Display Text"] = [=[Although the Display tab has sliders to control Width, Height, and X and Y positioning, there is an easier way to move and size your display.

You can simply click and drag your display to anywhere on your screen, and click and drag the corners to change the size.

You can also press Shift to hide the mover/sizer frame, for more accurate placement.]=]
L["Activation Settings: 1/5"] = "Activation Settings: 1/5"
L["Activation Settings Text"] = [=[The second section, Trigger, controls when your display will be visible, and what information is passed to it.

There are many types of triggers, but right now you just need an Aura trigger, which is the default type.]=]
L["Activation Settings: 2/5"] = "Activation Settings: 2/5"
L["Activation Settings Text"] = [=[You're going to make your display only appear when you have %s, so type %s into the Aura Name text box.

By default, |cFF8800FFWeakAuras|r matches auras by name, and it should tell you how many unique spells match the name you've entered.]=]
L["Activation Settings: 3/5"] = "Activation Settings: 3/5"
L["Activation Settings Text"] = [=[Other settings on this tab allow further control over various aspects of the aura.

This display will work the default settings, but as you continue to create Aura triggers, make sure the \"Unit\" and \"Aura Type\" options are always set correctly; if they're not, your display will not work how you want it to.]=]
L["Activation Settings: 4/5"] = "Activation Settings: 4/5"
L["Activation Settings Text"] = [=[The Load tab also affects the visibility of your display, but in a much more permanent sense. These settings are based on values that do not change often, or at all.

A display whose Load settings are not satisfied will basically not exist to WeakAuras; it will never be visible, and its Trigger will never even be tested.

Using the Load tab will help you organize displays between different characters and talent specializations. It also helps keep WeakAuras efficient; the less displays that are Loaded when they do not need to be, the less work WeakAuras has to do figuring out whether or not they should be visible.]=]
L["Activation Settings: 5/5"] = "Activation Settings: 5/5"
L["Activation Settings Text"] = "Since you are a %s, you can enable the Player Class options and select %s."
L["Actions and Animations: 1/7"] = "Actions and Animations: 1/7"
L["Actions and Animations Text"] = "The Actions tab lets you specify side-effects for when your display shows or hides. This includes chat messages, sounds, and custom Lua code."
L["Actions and Animations: 2/7"] = "Actions and Animations: 2/7"
L["Actions and Animations Text"] = [=[For the purpose of demonstration, you'll make your display play a sound when it appears.

Enable the Play Sound option.]=]
L["Actions and Animations: 3/7"] = "Actions and Animations: 3/7"
L["Actions and Animations Text"] = "Pick a sound file from the list."
L["Actions and Animations: 4/7"] = "Actions and Animations: 4/7"
L["Actions and Animations Text"] = "The final tab, Animations, is exactly what you'd think; it controls animations that alter the appearance of your display."
L["Actions and Animations: 5/7"] = "Actions and Animations: 5/7"
L["Actions and Animations Text"] = [=[There are three times an animation can play: when your display appears (Start), all the time while your display is visible (Main), or as your display is hiding (Finish).

Change the Start Type from \"None\" to \"Preset\" to enable the Start animation.]=]
L["Actions and Animations: 6/7"] = "Actions and Animations: 6/7"
L["Actions and Animations Text"] = [=[The resulting Preset menu allows you to choose a preset Start animation. However, picking an animation type doesn't make anything happen on your screen!

That's because the animation only plays when your display appears.]=]
L["Actions and Animations: 7/7"] = "Actions and Animations: 7/7"
L["Actions and Animations Text"] = [=[To test your animation, you'll have to hide your display and make it appear again. This can be done using the display's View button on the sidebar.

Click it a few times to see your Start animation.]=]
L["Beginners Finished Text"] = [=[That's it for the Beginners Guide. However, you've hardly scratched the surface of |cFF8800FFWeakAuras|r' power.

In the future, |cFFFFFF00More|r |cFFFF7F00Advanced|r |cFFFF0000Tutorials|r will be released to guide you deeper into |cFF8800FFWeakAuras|r' endless possibilities.]=]

-- New features
L["New in 1.4 Desc:"] = "New in 1.4"
L["New in 1.4 Desc Text"] = "See the new features of WeakAuras 1.4"

L["New in 1.4:"] = "New in 1.4:"
L["New in 1.4 Text1"] = [=[Version 1.4 of |cFF8800FFWeakAuras|r introduces several powerful new features.

This tutorial provides an overview of the most impotant new capabilities, and how to use them.]=]
L["New in 1.4 Text2"] = "First, create a new display for demonstration purposes."
L["Auto-cloning: 1/10"] = "Auto-cloning: 1/10"
L["Auto-cloning 1/10 Text"] = [=[The biggest featured added in |cFF8800FF1.4|r is |cFFFF0000auto-cloning|r. |cFFFF0000Auto-cloning|r allows your displays to automatically duplicate themselves to show multiple sources of information. When placed in a Dynamic Group, this allows you to create extensive dynamic sets of information.

There are three trigger types that support |cFFFF0000auto-cloning|r: Full Scan Auras, Group Auras, and Multi-target Auras.]=]
L["Full-scan Auras: 2/10"] = "Full-scan Auras: 2/10"
L["Full-scan Auras 2/10 Text"] = "First, enable the Full Scan option."
L["Full-scan Auras: 3/10"] = "Full-scan Auras: 3/10"
L["Full-scan Auras 3/10 Text"] = [=[|cFFFF0000Auto-cloning|r can now be enabled using the \"%s\" option.

This causes a new display to be created for every aura that matches the given parameters.]=]
L["Full-scan Auras: 4/10"] = "Full-scan Auras: 4/10"
L["Full-scan Auras 4/10 Text"] = [=[A popup should appear, informing you that |cFFFF0000auto-cloned|r displays should generally be used in Dynamic Groups.

Press \"Yes\" to allow |cFF8800FFWeakAuras|r to automatically put your display in a Dynamic Group.]=]
L["Full-scan Auras: 5/10"] = "Full-scan Auras: 5/10"
L["Full-scan Auras 5/10 Text"] = "Disable the Full Scan option to re-enable other Unit option selections."
L["Group Auras 6/10"] = "Group Auras: 6/10"
L["Group Auras 6/10 Text"] = "Now, select \"Group\" for the Unit option."
L["Group Auras: 7/10"] = "Group Auras: 7/10"
L["Group Auras 7/10 Text"] = [=[|cFFFF0000Auto-cloning|r is, again, enabled using the \"%s\" option.

A new display will be created for every member of your group that is affected by the specified aura(s).]=]
L["Group Auras: 8/10"] = "Group Auras: 8/10"
L["Group Auras 8/10 Text"] = "Enabling the %s option for a Group Aura with |cFFFF0000auto-cloning|r enabled will cause a new display for each member of your group that is |cFFFFFFFFnot|r affected by the specified aura(s)."
L["Multi-target Auras: 9/10"] = "Multi-target Auras: 9/10"
L["Multi-target Auras 9/10 Text"] = "Finally, select \"Multi-target\" for the Unit option."
L["Multi-target Auras: 10/10"] = "Multi-target Auras: 10/10"
L["Multi-target Auras 10/10 Text"] = [=[Multi-target auras have |cFFFF0000auto-cloning|r by default.

Multi-target Auras triggers are different from normal Aura triggers because they are based on Combat Log events, which means they will track auras on mobs that nobody is targeting (although some dynamic information is not available without someone in your group targeting the unit).

This makes Multi-target auras a good choice for tracking DoTs on multiple enemies.]=]
L["Trigger Options: 1/4"] = "Trigger Options: 1/4"
L["Trigger Options 1/4 Text"] = [=[In addition to \"Multi-target\" there is another new setting for the Unit option: Specific Unit.

Select it to be able to create a new text field.]=]
L["Trigger Options: 2/4"] = "Trigger Options: 2/4"
L["Trigger Options 2/4 Text"] = [=[In this field, you can specify the name of any player in your group, or a custom Unit ID. Unit IDs such as \"boss1\" \"boss2\" etc. are especially useful for raid encounters.

All triggers that allow you to specify a unit (not just Aura triggers) now support the Specific Unit option.]=]
L["Trigger Options: 3/4"] = "Trigger Options: 3/4"
L["Trigger Options 3/4 Text"] = [=[|cFF8800FFWeakAuras 1.4|r also adds some new Trigger types.

Select the Status category to take a look at them.]=]
L["Trigger Options: 4/4"] = "Trigger Options: 4/4"
L["Trigger Options 4/4 Text"] = [=[The |cFFFFFFFFUnit Characteristics|r trigger allows you test a unit's name, class, hostility, and whether it is a player or non-player character.

|cFFFFFFFFGlobal Cooldown|r and |cFFFFFFFFSwing Timer|r triggers complement the Cast trigger.]=]
L["Dynamic Group Options: 2/4"] = "Dynamic Group Options: 2/4"
L["Dynamic Group Options 2/4 Text"] = [=[The biggest improvement to |cFFFFFFFFDynamic Group|rs is a new selection for the Grow option.

Select \"Circular\" to see it in action.]=]
L["Dynamic Group Options: 3/4"] = "Dynamic Group Options: 3/4"
L["Dynamic Group Options 3/4 Text"] = [=[The Constant Factor options allows you to control how your circular group grows.

A circular group with a constant spacing grows in radius as more displays are added, whereas a constant radius causes displays to simply get closer together as more are added.]=]
L["Dynamic Group Options: 4/4"] = "Dynamic Group Options: 4/4"
L["Dynamic Group Options 4/4 Text"] = [=[Dynamic Groups now can now automatically sort their children by Remaining Time.

Displays that don't have Remaining Time are placed at the top or bottom, depending on if you choose \"Ascending\" or \"Descending\".]=]
L["Display Options: 1/4"] = "Display Options: 1/4"
L["Display Options 1/4 Text"] = "Now, select a Progress Bar display (or create a new one)."
L["Display Options: 2/4"] = "Display Options: 2/4"
L["Display Options 2/4 Text"] = [=[|cFFFFFFFFProgress Bar|r displays now support Dynamic Text options, just like Text displays. See the tooltip for more information on Dynamic Text codes.

|cFFFFFFFFIcon|r displays also have a Dynamic Text field.]=]
L["Display Options: 2/4"] = "Display Options: 2/4"
L["Display Options 2/4 Text"] = [=[|cFFFFFFFFProgress Bar|r and |cFFFFFFFFIcon|r displays now have an option to show tooltips when you mouse over them.

This option is only available if your display uses a trigger based on an aura, item, or spell.]=]
L["Display Options: 4/4"] = "Display Options: 4/4"
L["Display Options 4/4 Text"] = "Finally, a new display type, |cFFFFFFFFModel|r, allows you to harness any 3D model from the game files."
L["New in 1.4 Finnished Text"] = [=[Of course, there are more new features in |cFF8800FFWeakAuras 1.4|r than can be covered all at once, not to mention countless bug fixes and efficiency improvements.

Hopefully, this Tutorial has at least guided you towards the major new capabilities that are available to you.

Thank you for using |cFF8800FFWeakAuras|r!]=]

--@end-do-not-package@