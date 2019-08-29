if not WeakAuras.IsCorrectVersion() then return end

local L = WeakAuras.L

-- Options translation
L["1 Match"] = "1 Match"
L["Actions"] = "Actions"
L["Activate when the given aura(s) |cFFFF0000can't|r be found"] = "Activate when the given aura(s) |cFFFF0000can't|r be found"
L["Add a new display"] = "Add a new display"
L["Add Dynamic Text"] = "Add Dynamic Text"
L["Addon"] = "Addon"
L["Addons"] = "Addons"
L["Add to group %s"] = "Add to group %s"
L["Add to new Dynamic Group"] = "Add to new Dynamic Group"
L["Add to new Group"] = "Add to new Group"
L["Add Trigger"] = "Add Trigger"
L["A group that dynamically controls the positioning of its children"] = "A group that dynamically controls the positioning of its children"
L["Align"] = "Align"
L["Allow Full Rotation"] = "Allow Full Rotation"
L["Alpha"] = "Alpha"
L["Anchor"] = "Anchor"
L["Anchor Point"] = "Anchor Point"
L["Angle"] = "Angle"
L["Animate"] = "Animate"
L["Animated Expand and Collapse"] = "Animated Expand and Collapse"
L["Animation relative duration description"] = [=[
The duration of the animation relative to the duration of the display, expressed as a fraction (1/2), percentage (50%), or decimal (0.5).
|cFFFF0000Note:|r if a display does not have progress (it has a non-timed event trigger, is an aura with no duration, etc.), the animation will not play.

|cFF4444FFFor Example:|r
If the animation's duration is set to |cFF00CC0010%|r, and the display's trigger is a buff that lasts 20 seconds, the start animation will play for 2 seconds.
If the animation's duration is set to |cFF00CC0010%|r, and the display's trigger is a buff that has no set duration, no start animation will play (although it would if you specified a duration in seconds)."
]=]
L["Animations"] = "Animations"
L["Animation Sequence"] = "Animation Sequence"
L["Aquatic"] = "Aquatic"
L["Aura (Paladin)"] = "Aura"
L["Aura(s)"] = "Aura(s)"
L["Auto"] = "Auto"
L["Auto-cloning enabled"] = "Auto-cloning enabled"
L["Automatic Icon"] = "Automatic Icon"
L["Backdrop Color"] = "Backdrop Color"
L["Backdrop Style"] = "Backdrop Style"
L["Background"] = "Background"
L["Background Color"] = "Background Color"
L["Background Inset"] = "Background Inset"
L["Background Offset"] = "Background Offset"
L["Background Texture"] = "Background Texture"
L["Bar Alpha"] = "Bar Alpha"
L["Bar Color"] = "Bar Color"
L["Bar Color Settings"] = "Bar Color Settings"
L["Bar in Front"] = "Bar in Front"
L["Bar Texture"] = "Bar Texture"
L["Battle"] = "Battle"
L["Bear"] = "Bear"
L["Berserker"] = "Berserker"
L["Blend Mode"] = "Blend Mode"
L["Blood"] = "Blood"
L["Border"] = "Border"
L["Border Color"] = "Border Color"
L["Border Inset"] = "Border Inset"
L["Border Offset"] = "Border Offset"
L["Border Settings"] = "Border Settings"
L["Border Size"] = "Border Size"
L["Border Style"] = "Border Style"
L["Bottom Text"] = "Bottom Text"
L["Button Glow"] = "Button Glow"
L["Can be a name or a UID (e.g., party1). A name only works on friendly players in your group."] = "Can be a name or a UID (e.g., party1). A name only works on friendly players in your group."
L["Cancel"] = "Cancel"
L["Cat"] = "Cat"
L["Change the name of this display"] = "Change the name of this display"
L["Channel Number"] = "Channel Number"
L["Check On..."] = "Check On..."
L["Choose"] = "Choose"
L["Choose Trigger"] = "Choose Trigger"
L["Choose whether the displayed icon is automatic or defined manually"] = "Choose whether the displayed icon is automatic or defined manually"
L["Clone option enabled dialog"] = [=[
You have enabled an option that uses |cFFFF0000Auto-cloning|r.

|cFFFF0000Auto-cloning|r causes a display to be automatically duplicated to display multiple sources of information.
Unless you put this display in a |cFF22AA22Dynamic Group|r, all the clones will be displayed on top of each other in a big heap.

Would you like this display to be placed in a new |cFF22AA22Dynamic Group|r?]=]
L["Close"] = "Close"
L["Collapse"] = "Collapse"
L["Collapse all loaded displays"] = "Collapse all loaded displays"
L["Collapse all non-loaded displays"] = "Collapse all non-loaded displays"
L["Color"] = "Color"
L["Compress"] = "Compress"
L["Concentration"] = "Concentration"
L["Constant Factor"] = "Constant Factor"
L["Control-click to select multiple displays"] = "Control-click to select multiple displays"
L["Controls the positioning and configuration of multiple displays at the same time"] = "Controls the positioning and configuration of multiple displays at the same time"
L["Convert to..."] = "Convert to..."
L["Cooldown"] = "Cooldown"
L["Copy"] = "Copy"
L["Copy settings from..."] = "Copy settings from..."
L["Copy settings from another display"] = "Copy settings from another display"
L["Copy settings from %s"] = "Copy settings from %s"
L["Count"] = "Count"
L["Creating buttons: "] = "Creating buttons: "
L["Creating options: "] = "Creating options: "
L["Crop X"] = "Crop X"
L["Crop Y"] = "Crop Y"
L["Crusader"] = "Crusader"
L["Custom Code"] = "Custom Code"
L["Custom Trigger"] = "Custom Trigger"
L["Custom trigger event tooltip"] = [=[
Choose which events cause the custom trigger to be checked.
Multiple events can be specified using commas or spaces.

|cFF4444FFFor example:|r
UNIT_POWER_UPDATE, UNIT_AURA PLAYER_TARGET_CHANGED
]=]
L["Custom trigger status tooltip"] = [=[
Choose which events cause the custom trigger to be checked.
Since this is a status-type trigger, the specified events may be called by WeakAuras without the expected arguments.
Multiple events can be specified using commas or spaces.

|cFF4444FFFor example:|r
UNIT_POWER_UPDATE, UNIT_AURA PLAYER_TARGET_CHANGED
]=]
L["Custom Untrigger"] = "Custom Untrigger"
L["Custom untrigger event tooltip"] = [=[
Choose which events cause the custom un-trigger to be checked.
This can be different than the events defined for the trigger.
Multiple events can be specified using commas or spaces.

|cFF4444FFFor example:|r
UNIT_POWER_UPDATE, UNIT_AURA PLAYER_TARGET_CHANGED
]=]
L["Death"] = "Death"
L["Death Rune"] = "Death Rune"
L["Debuff Type"] = "Debuff Type"
L["Defensive"] = "Defensive"
L["Delete"] = "Delete"
L["Delete all"] = "Delete all"
L["Delete children and group"] = "Delete children and group"
L["Deletes this display - |cFF8080FFShift|r must be held down while clicking"] = "Deletes this display - |cFF8080FFShift|r must be held down while clicking"
L["Delete Trigger"] = "Delete Trigger"
L["Desaturate"] = "Desaturate"
L["Devotion"] = "Devotion"
L["Disabled"] = "Disabled"
L["Discrete Rotation"] = "Discrete Rotation"
L["Display"] = "Display"
L["Display Icon"] = "Display Icon"
L["Display Text"] = "Display Text"
L["Distribute Horizontally"] = "Distribute Horizontally"
L["Distribute Vertically"] = "Distribute Vertically"
L["Do not copy any settings"] = "Do not copy any settings"
L["Do not group this display"] = "Do not group this display"
L["Duplicate"] = "Duplicate"
L["Duration Info"] = "Duration Info"
L["Duration (s)"] = "Duration (s)"
L["Dynamic Group"] = "Dynamic Group"
L["Dynamic text tooltip"] = [=[
There are several special codes available to make this text dynamic:

|cFFFF0000%p|r - Progress - The remaining time of a timer, or a non-timer value
|cFFFF0000%t|r - Total - The maximum duration of a timer, or a maximum non-timer value
|cFFFF0000%n|r - Name - The name of the display (usually an aura name), or the display's ID if there is no dynamic name
|cFFFF0000%i|r - Icon - The icon associated with the display
|cFFFF0000%s|r - Stacks - The number of stacks of an aura (usually)
|cFFFF0000%c|r - Custom - Allows you to define a custom Lua function that returns a list of string values. %c1 will be replaced by the first value returned, %c2 by the second, etc.
|cFFFF0000%%|r - % - To show a percent sign

By default these show the information from the trigger selected via dynamic information. The information from a specific trigger can be shown via e.g. %2.p.
]=]
L["Enabled"] = "Enabled"
L["Enter an aura name, partial aura name, or spell id"] = "Enter an aura name, partial aura name, or spell id"
L["Event Type"] = "Event Type"
L["Expand"] = "Expand"
L["Expand all loaded displays"] = "Expand all loaded displays"
L["Expand all non-loaded displays"] = "Expand all non-loaded displays"
L["Expand Text Editor"] = "Expand Text Editor"
L["Expansion is disabled because this group has no children"] = "Expansion is disabled because this group has no children"
L["Export"] = "Export"
L["Export to Lua table..."] = "Export to Lua table..."
L["Export to string..."] = "Export to string..."
L["Fade"] = "Fade"
L["Finish"] = "Finish"
L["Fire Resistance"] = "Fire Resistance"
L["Flight(Non-Feral)"] = "Flight(Non-Feral)"
L["Font"] = "Font"
L["Font Flags"] = "Font Flags"
L["Font Size"] = "Font Size"
L["Font Type"] = "Font Type"
L["Foreground Color"] = "Foreground Color"
L["Foreground Texture"] = "Foreground Texture"
L["Form (Druid)"] = "Form"
L["Form (Priest)"] = "Form"
L["Form (Shaman)"] = "Form"
L["Form (Warlock)"] = "Form"
L["Frame"] = "Frame"
L["Frame Strata"] = "Frame Strata"
L["Frost"] = "Frost"
L["Frost Resistance"] = "Frost Resistance"
L["Full Scan"] = "Full Scan"
L["Ghost Wolf"] = "Ghost Wolf"
L["Glow Action"] = "Glow Action"
L["Group aura count description"] = [=[
The amount of units of type '%s' which must be affected by one or more of the given auras for the display to trigger.
If the entered number is a whole number (e.g. 5), the number of affected units will be compared with the entered number.
If the entered number is a decimal (e.g. 0.5), fraction (e.g. 1/2), or percentage (e.g. 50%%), then that fraction of the %s must be affected.

|cFF4444FFFor example:|r
|cFF00CC00> 0|r will trigger when any unit of type '%s' is is affected
|cFF00CC00= 100%%|r will trigger when ever unit of type '%s' is affected
|cFF00CC00!= 2|r will trigger when the number of units of type '%s' affected is not exactly 2
|cFF00CC00<= 0.8|r will trigger when less than 80%% of the units of type '%s' is affected (4 of 5 party members, 8 of 10 or 20 of 25 raid members)
|cFF00CC00> 1/2|r will trigger when more than half of the units of type '%s' is affected
|cFF00CC00>= 0|r will always trigger, no matter what
]=]
L["Group Member Count"] = "Group Member Count"
L["Group (verb)"] = "Group"
L["Height"] = "Height"
L["Hide this group's children"] = "Hide this group's children"
L["Hide When Not In Group"] = "Hide When Not In Group"
L["Horizontal Align"] = "Horizontal Align"
L["Icon Info"] = "Icon Info"
L["Icon Inset"] = "Icon Inset"
L["Ignored"] = "Ignored"
L["Ignore GCD"] = "Ignore GCD"
L["%i Matches"] = "%i Matches"
L["Import"] = "Import"
L["Import a display from an encoded string"] = "Import a display from an encoded string"
L["Justify"] = "Justify"
L["Left Text"] = "Left Text"
L["Load"] = "Load"
L["Loaded"] = "Loaded"
L["Main"] = "Main"
L["Main Trigger"] = "Main Trigger"
L["Mana (%)"] = "Mana (%)"
L["Manage displays defined by Addons"] = "Manage displays defined by Addons"
L["Message Prefix"] = "Message Prefix"
L["Message Suffix"] = "Message Suffix"
L["Metamorphosis"] = "Metamorphosis"
L["Mirror"] = "Mirror"
L["Model"] = "Model"
L["Moonkin/Tree/Flight(Feral)"] = "Moonkin/Tree/Flight(Feral)"
L["Move Down"] = "Move Down"
L["Move this display down in its group's order"] = "Move this display down in its group's order"
L["Move this display up in its group's order"] = "Move this display up in its group's order"
L["Move Up"] = "Move Up"
L["Multiple Displays"] = "Multiple Displays"
L["Multiple Triggers"] = "Multiple Triggers"
L["Multiselect ignored tooltip"] = [=[
|cFFFF0000Ignored|r - |cFF777777Single|r - |cFF777777Multiple|r
This option will not be used to determine when this display should load]=]
L["Multiselect multiple tooltip"] = [=[
|cFF777777Ignored|r - |cFF777777Single|r - |cFF00FF00Multiple|r
Any number of matching values can be picked]=]
L["Multiselect single tooltip"] = [=[
|cFF777777Ignored|r - |cFF00FF00Single|r - |cFF777777Multiple|r
Only a single matching value can be picked]=]
L["Must be spelled correctly!"] = "Must be spelled correctly!"
L["Name Info"] = "Name Info"
L["Negator"] = "Not"
L["New"] = "New"
L["Next"] = "Next"
L["No"] = "No"
L["No Children"] = "No Children"
L["Not all children have the same value for this option"] = "Not all children have the same value for this option"
L["Not Loaded"] = "Not Loaded"
L["No tooltip text"] = "No tooltip text"
L["% of Progress"] = "% of Progress"
L["Okay"] = "Okay"
L["On Hide"] = "On Hide"
L["On Init"] = "On Init"
L["Only match auras cast by people other than the player"] = "Only match auras cast by people other than the player"
L["Only match auras cast by the player"] = "Only match auras cast by the player"
L["On Show"] = "On Show"
L["Operator"] = "Operator"
L["or"] = "or"
L["Orientation"] = "Orientation"
L["Other"] = "Other"
L["Outline"] = "Outline"
L["Own Only"] = "Own Only"
L["Player Character"] = "Player Character"
L["Play Sound"] = "Play Sound"
L["Presence (DK)"] = "Presence"
L["Presence (Rogue)"] = "Presence"
L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."] = "Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."
L["Primary"] = "Primary"
L["Progress Bar"] = "Progress Bar"
L["Progress Texture"] = "Progress Texture"
L["Put this display in a group"] = "Put this display in a group"
L["Ready For Use"] = "Ready For Use"
L["Re-center X"] = "Re-center X"
L["Re-center Y"] = "Re-center Y"
L["Remaining Time Precision"] = "Remaining Time Precision"
L["Remove this display from its group"] = "Remove this display from its group"
L["Rename"] = "Rename"
L["Requesting display information"] = "Requesting display information from %s..."
L["Required for Activation"] = "Required for Activation"
L["Retribution"] = "Retribution"
L["Right-click for more options"] = "Right-click for more options"
L["Right Text"] = "Right Text"
L["Rotate"] = "Rotate"
L["Rotate In"] = "Rotate In"
L["Rotate Out"] = "Rotate Out"
L["Rotate Text"] = "Rotate Text"
L["Rotation"] = "Rotation"
L["Same"] = "Same"
L["Search"] = "Search"
L["Secondary"] = "Secondary"
L["Select the auras you always want to be listed first"] = "Select the auras you always want to be listed first"
L["Send To"] = "Send To"
L["Set tooltip description"] = "Set tooltip description"
L["Shadow Dance"] = "Shadow Dance"
L["Shadowform"] = "Shadowform"
L["Shadow Resistance"] = "Shadow Resistance"
L["Shift-click to create chat link"] = "Shift-click to create a |cFF8800FF[Chat Link]"
L["Show all matches (Auto-clone)"] = "Show all matches (Auto-clone)"
L["Show players that are |cFFFF0000not affected"] = "Show players that are |cFFFF0000not affected"
L["Shows a 3D model from the game files"] = "Shows a 3D model from the game files"
L["Shows a custom texture"] = "Shows a custom texture"
L["Shows a progress bar with name, timer, and icon"] = "Shows a progress bar with name, timer, and icon"
L["Shows a spell icon with an optional cooldown overlay"] = "Shows a spell icon with an optional cooldown overlay"
L["Shows a texture that changes based on duration"] = "Shows a texture that changes based on duration"
L["Shows one or more lines of text, which can include dynamic information such as progress or stacks"] = "Shows one or more lines of text, which can include dynamic information such as progress or stacks"
L["Shows the remaining or expended time for an aura or timed event"] = "Shows the remaining or expended time for an aura or timed event"
L["Show this group's children"] = "Show this group's children"
L["Size"] = "Size"
L["Slide"] = "Slide"
L["Slide In"] = "Slide In"
L["Slide Out"] = "Slide Out"
L["Sort"] = "Sort"
L["Sound"] = "Sound"
L["Sound Channel"] = "Sound Channel"
L["Sound File Path"] = "Sound File Path"
L["Space"] = "Space"
L["Space Horizontally"] = "Space Horizontally"
L["Space Vertically"] = "Space Vertically"
L["Spell ID"] = "Spell ID"
L["Spell ID dialog"] = [=[
You have specified an aura by |cFFFF0000spell ID|r.

By default, |cFF8800FFWeakAuras|r cannot distinguish between auras with the same name but different |cFFFF0000spell ID|r.
However, if the Use Full Scan option is enabled, |cFF8800FFWeakAuras|r can search for specific |cFFFF0000spell ID|rs.

Would you like to enable Use Full Scan to match this |cFFFF0000spell ID|r?]=]
L["Stack Count"] = "Stack Count"
L["Stack Count Position"] = "Stack Count Position"
L["Stack Info"] = "Stack Info"
L["Stacks Settings"] = "Stacks Settings"
L["Stagger"] = "Stagger"
L["Stance (Warrior)"] = "Stance"
L["Start"] = "Start"
L["Stealable"] = "Stealable"
L["Stealthed"] = "Stealthed"
L["Temporary Group"] = "Temporary Group"
L["Text"] = "Text"
L["Text Color"] = "Text Color"
L["Text Position"] = "Text Position"
L["Text Settings"] = "Text Settings"
L["Texture"] = "Texture"
L["Texture Info"] = "Texture Info"
L["The children of this group have different display types, so their display options cannot be set as a group."] = "The children of this group have different display types, so their display options cannot be set as a group."
L["The duration of the animation in seconds."] = "The duration of the animation in seconds."
L["The type of trigger"] = "The type of trigger"
L["This condition will not be tested"] = "This condition will not be tested"
L["This display is currently loaded"] = "This display is currently loaded"
L["This display is not currently loaded"] = "This display is not currently loaded"
L["This display will only show when |cFF00FF00%s"] = "This display will only show when |cFF00FF00%s"
L["This display will only show when |cFFFF0000 Not %s"] = "This display will only show when |cFFFF0000 Not %s"
L["This region of type \"%s\" has no configuration options."] = "This region of type \"%s\" has no configuration options."
L["Time in"] = "Time in"
L["Timer"] = "Timer"
L["Timer Settings"] = "Timer Settings"
L["Toggle the visibility of all loaded displays"] = "Toggle the visibility of all loaded displays"
L["Toggle the visibility of all non-loaded displays"] = "Toggle the visibility of all non-loaded displays"
L["Toggle the visibility of this display"] = "Toggle the visibility of this display"
L["to group's"] = "to group's"
L["Tooltip"] = "Tooltip"
L["Tooltip on Mouseover"] = "Tooltip on Mouseover"
L["Top Text"] = "Top Text"
L["To Screen's"] = "To Screen's"
L["Total Time Precision"] = "Total Time Precision"
L["Tracking"] = "Tracking"
L["Travel"] = "Travel"
L["Trigger"] = "Trigger"
L["Trigger %d"] = "Trigger %d"
L["Triggers"] = "Triggers"
L["Type"] = "Type"
L["Ungroup"] = "Ungroup"
L["Unholy"] = "Unholy"
L["Unit Exists"] = "Unit Exists"
L["Unlike the start or finish animations, the main animation will loop over and over until the display is hidden."] = "Unlike the start or finish animations, the main animation will loop over and over until the display is hidden."
L["Unstealthed"] = "Unstealthed"
L["Update Custom Text On..."] = "Update Custom Text On..."
L["Use Full Scan (High CPU)"] = "Use Full Scan (High CPU)"
L["Use tooltip \"size\" instead of stacks"] = "Use tooltip \"size\" instead of stacks"
L["Vertical Align"] = "Vertical Align"
L["View"] = "View"
L["Width"] = "Width"
L["X Offset"] = "X Offset"
L["X Scale"] = "X Scale"
L["Yes"] = "Yes"
L["Y Offset"] = "Y Offset"
L["Y Scale"] = "Y Scale"
L["Z Offset"] = "Z Offset"
L["Zoom"] = "Zoom"
L["Zoom In"] = "Zoom In"
L["Zoom Out"] = "Zoom Out"
