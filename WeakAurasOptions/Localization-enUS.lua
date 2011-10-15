local L = WeakAuras.L

-- Options translation
--@localization(locale="enUS", format="lua_additive_table", namespace="WeakAuras / Options")@


--@do-not-package@

-- Options translation
L["% of Progress"] = "% of Progress"
L["%i Matches"] = "%i Matches"
L["1 Match"] = "1 Match"
L["A group that dynamically controls the positioning of its children"] = "A group that dynamically controls the positioning of its children"
L["Actions"] = "Actions"
L["Activate when the given aura(s) |cFFFF0000can't|r be found"] = "Activate when the given aura(s) |cFFFF0000can't|r be found"
L["Add Dynamic Text"] = "Add Dynamic Text"
L["Add Trigger"] = "Add Trigger"
L["Add a new display"] = "Add a new display"
L["Add to group %s"] = "Add to group %s"
L["Add to new Dynamic Group"] = "Add to new Dynamic Group"
L["Add to new Group"] = "Add to new Group"
L["Addon"] = "Addon"
L["Addons"] = "Addons"
L["Align"] = "Align"
L["Allow Full Rotation"] = "Allow Full Rotation"
L["Alpha"] = "Alpha"
L["Anchor"] = "Anchor"
L["Anchor Point"] = "Anchor Point"
L["Angle"] = "Angle"
L["Animate"] = "Animate"
L["Animated Expand and Collapse"] = "Animated Expand and Collapse"
L["Animation Sequence"] = "Animation Sequence"
L["Animation relative duration description"] = [=[
The duration of the animation relative to the duration of the display, expressed as a fraction (1/2), percentage (50%), or decimal (0.5).
|cFFFF0000Note:|r if a display does not have progress (it has a non-timed event trigger, is an aura with no duration, etc.), the animation will not play.

|cFF4444FFFor Example:|r
If the animation's duration is set to |cFF00CC0010%|r, and the display's trigger is a buff that lasts 20 seconds, the start animation will play for 2 seconds.
If the animation's duration is set to |cFF00CC0010%|r, and the display's trigger is a buff that has no set duration, no start animation will play (although it would if you specified a duration in seconds)."
]=]
L["Animations"] = "Animations"
L["Aquatic"] = "Aquatic"
L["Aura (Paladin)"] = "Aura"
L["Aura(s)"] = "Aura(s)"
L["Auto"] = "Auto"
L["Auto-cloning enabled"] = "Auto-cloning enabled"
L["Automatic Icon"] = "Automatic Icon"
L["Background"] = "Background"
L["Background Color"] = "Background Color"
L["Background Inset"] = "Background Inset"
L["Background Offset"] = "Background Offset"
L["Background Texture"] = "Background Texture"
L["Bar Alpha"] = "Bar Alpha"
L["Bar Color"] = "Bar Color"
L["Bar Texture"] = "Bar Texture"
L["Battle"] = "Battle"
L["Bear"] = "Bear"
L["Berserker"] = "Berserker"
L["Blend Mode"] = "Blend Mode"
L["Blood"] = "Blood"
L["Border"] = "Border"
L["Border Offset"] = "Border Offset"
L["Bottom Text"] = "Bottom Text"
L["Button Glow"] = "Button Glow"
L["Can be a name or a UID (e.g., party1). Only works on friendly players in your group."] = "Can be a name or a UID (e.g., party1). Only works on friendly players in your group."
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
L["Copy settings from %s"] = "Copy settings from %s"
L["Copy settings from another display"] = "Copy settings from another display"
L["Copy settings from..."] = "Copy settings from..."
L["Count"] = "Count"
L["Creating buttons: "] = "Creating buttons: "
L["Creating options: "] = "Creating options: "
L["Crop X"] = "Crop X"
L["Crop Y"] = "Crop Y"
L["Crusader"] = "Crusader"
L["Custom Code"] = "Custom Code"
L["Custom Trigger"] = "Custom Trigger"
L["Custom Untrigger"] = "Custom Untrigger"
L["Custom trigger event tooltip"] = [=[
Choose which events cause the custom trigger to be checked.
Multiple events can be specified using commas or spaces.

|cFF4444FFFor example:|r
UNIT_POWER, UNIT_AURA PLAYER_TARGET_CHANGED
]=]
L["Custom trigger status tooltip"] = [=[
Choose which events cause the custom trigger to be checked.
Since this is a status-type trigger, the specified events may be called by WeakAuras without the expected arguments.
Multiple events can be specified using commas or spaces.

|cFF4444FFFor example:|r
UNIT_POWER, UNIT_AURA PLAYER_TARGET_CHANGED
]=]
L["Custom untrigger event tooltip"] = [=[
Choose which events cause the custom un-trigger to be checked.
This can be different than the events defined for the trigger.
Multiple events can be specified using commas or spaces.

|cFF4444FFFor example:|r
UNIT_POWER, UNIT_AURA PLAYER_TARGET_CHANGED
]=]
L["Death"] = "Death"
L["Death Rune"] = "Death Rune"
L["Debuff Type"] = "Debuff Type"
L["Defensive"] = "Defensive"
L["Delete"] = "Delete"
L["Delete Trigger"] = "Delete Trigger"
L["Delete all"] = "Delete all"
L["Delete children and group"] = "Delete children and group"
L["Deletes this display - |cFF8080FFShift|r must be held down while clicking"] = "Deletes this display - |cFF8080FFShift|r must be held down while clicking"
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
L["Duration (s)"] = "Duration (s)"
L["Duration Info"] = "Duration Info"
L["Dynamic Group"] = "Dynamic Group"
L["Dynamic text tooltip"] = [=[
There are several special codes available to make this text dynamic:

|cFFFF0000%p|r - Progress - The remaining time of a timer, or a non-timer value
|cFFFF0000%t|r - Total - The maximum duration of a timer, or a maximum non-timer value
|cFFFF0000%n|r - Name - The name of the display (usually an aura name), or the display's ID if there is no dynamic name
|cFFFF0000%i|r - Icon - The icon associated with the display
|cFFFF0000%s|r - Stacks - The number of stacks of an aura (usually)
|cFFFF0000%c|r - Custom - Allows you to define a custom Lua function that returns a string value to be displayed]=]
L["Enabled"] = "Enabled"
L["Enter an aura name, partial aura name, or spell id"] = "Enter an aura name, partial aura name, or spell id"
L["Event Type"] = "Event Type"
L["Expand"] = "Expand"
L["Expand Text Editor"] = "Expand Text Editor"
L["Expand all loaded displays"] = "Expand all loaded displays"
L["Expand all non-loaded displays"] = "Expand all non-loaded displays"
L["Expansion is disabled because this group has no children"] = "Expansion is disabled because this group has no children"
L["Export"] = "Export"
L["Export to Lua table..."] = "Export to Lua table..."
L["Export to string..."] = "Export to string..."
L["Fade"] = "Fade"
L["Finish"] = "Finish"
L["Fire Resistance"] = "Fire Resistance"
L["Flight(Non-Feral)"] = "Flight(Non-Feral)"
L["Font"] = "Font"
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
L["Group (verb)"] = "Group"
L["Group Member Count"] = "Group Member Count"
L["Group aura count description"] = [=[
The amount of %s members which must be affected by one or more of the given auras for the display to trigger.
If the entered number is a whole number (e.g. 5), the number of affected raid members will be compared with the entered number.
If the entered number is a decimal (e.g. 0.5), fraction (e.g. 1/2), or percentage (e.g. 50%%), then that fraction of the %s must be affected.

|cFF4444FFFor example:|r
|cFF00CC00> 0|r will trigger when anyone in the %s is affected
|cFF00CC00= 100%%|r will trigger when everyone in the %s is affected
|cFF00CC00!= 2|r will trigger when the number of %s members affected is not exactly 2
|cFF00CC00<= 0.8|r will trigger when less than 80%% of the %s is affected (4 of 5 party members, 8 of 10 or 20 of 25 raid members)
|cFF00CC00> 1/2|r will trigger when more than half of the %s is affected
|cFF00CC00>= 0|r will always trigger, no matter what
]=]
L["Height"] = "Height"
L["Hide When Not In Group"] = "Hide When Not In Group"
L["Hide this group's children"] = "Hide this group's children"
L["Horizontal Align"] = "Horizontal Align"
L["Icon Info"] = "Icon Info"
L["Ignore GCD"] = "Ignore GCD"
L["Ignored"] = "Ignored"
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
L["Move Up"] = "Move Up"
L["Move this display down in its group's order"] = "Move this display down in its group's order"
L["Move this display up in its group's order"] = "Move this display up in its group's order"
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
L["No tooltip text"] = "No tooltip text"
L["Not Loaded"] = "Not Loaded"
L["Not all children have the same value for this option"] = "Not all children have the same value for this option"
L["Okay"] = "Okay"
L["On Hide"] = "On Hide"
L["On Show"] = "On Show"
L["Only match auras cast by people other than the player"] = "Only match auras cast by people other than the player"
L["Only match auras cast by the player"] = "Only match auras cast by the player"
L["Operator"] = "Operator"
L["Orientation"] = "Orientation"
L["Other"] = "Other"
L["Outline"] = "Outline"
L["Own Only"] = "Own Only"
L["Play Sound"] = "Play Sound"
L["Player Character"] = "Player Character"
L["Presence (DK)"] = "Presence"
L["Presence (Rogue)"] = "Presence"
L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."] = "Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."
L["Primary"] = "Primary"
L["Progress Bar"] = "Progress Bar"
L["Progress Texture"] = "Progress Texture"
L["Put this display in a group"] = "Put this display in a group"
L["Re-center X"] = "Re-center X"
L["Re-center Y"] = "Re-center Y"
L["Ready For Use"] = "Ready For Use"
L["Remaining Time Precision"] = "Remaining Time Precision"
L["Remove this display from its group"] = "Remove this display from its group"
L["Rename"] = "Rename"
L["Requesting display information"] = "Requesting display information from %s..."
L["Required For Activation"] = "Required For Activation"
L["Retribution"] = "Retribution"
L["Right Text"] = "Right Text"
L["Right-click for more options"] = "Right-click for more options"
L["Rotate"] = "Rotate"
L["Rotate In"] = "Rotate In"
L["Rotate Out"] = "Rotate Out"
L["Rotate Text"] = "Rotate Text"
L["Rotation"] = "Rotation"
L["Same"] = "Same"
L["Search"] = "Search"
L["Secondary"] = "Secondary"
L["Send To"] = "Send To"
L["Set tooltip description"] = "Set tooltip description"
L["Shadow Dance"] = "Shadow Dance"
L["Shadow Resistance"] = "Shadow Resistance"
L["Shadowform"] = "Shadowform"
L["Shift-click to create chat link"] = "Shift-click to create a |cFF8800FF[Chat Link]"
L["Show all matches (Auto-clone)"] = "Show all matches (Auto-clone)"
L["Show players that are |cFFFF0000not affected"] = "Show players that are |cFFFF0000not affected"
L["Show this group's children"] = "Show this group's children"
L["Shows a 3D model from the game files"] = "Shows a 3D model from the game files"
L["Shows a custom texture"] = "Shows a custom texture"
L["Shows a progress bar with name, timer, and icon"] = "Shows a progress bar with name, timer, and icon"
L["Shows a spell icon with an optional a cooldown overlay"] = "Shows a spell icon with an optional a cooldown overlay"
L["Shows a texture that changes based on duration"] = "Shows a texture that changes based on duration"
L["Shows one or more lines of text, which can include dynamic information such as progress or stacks"] = "Shows one or more lines of text, which can include dynamic information such as progress or stacks"
L["Shows the remaining or expended time for an aura or timed event"] = "Shows the remaining or expended time for an aura or timed event"
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
L["Stagger"] = "Stagger"
L["Stance (Warrior)"] = "Stance"
L["Start"] = "Start"
L["Stealable"] = "Stealable"
L["Stealthed"] = "Stealthed"
L["Sticky Duration"] = "Sticky Duration"
L["Temporary Group"] = "Temporary Group"
L["Text"] = "Text"
L["Text Color"] = "Text Color"
L["Text Position"] = "Text Position"
L["Texture"] = "Texture"
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
L["Toggle the visibility of all loaded displays"] = "Toggle the visibility of all loaded displays"
L["Toggle the visibility of all non-loaded displays"] = "Toggle the visibility of all non-loaded displays"
L["Toggle the visibility of this display"] = "Toggle the visibility of this display"
L["Tooltip"] = "Tooltip"
L["Tooltip on Mouseover"] = "Tooltip on Mouseover"
L["Top Text"] = "Top Text"
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
L["Y Offset"] = "Y Offset"
L["Y Scale"] = "Y Scale"
L["Yes"] = "Yes"
L["Z Offset"] = "Z Offset"
L["Zoom"] = "Zoom"
L["Zoom In"] = "Zoom In"
L["Zoom Out"] = "Zoom Out"
L["or"] = "or"
L["to group's"] = "to group's"
L["to screen's"] = "to screen's"

-- Media names translation
--Sound names - low priority for localization
L.sounds = {
  [" custom"] = "Custom",
  [WeakAuras.PowerAurasSoundPath.."aggro.ogg"] = "Aggro",
  [WeakAuras.PowerAurasSoundPath.."Arrow_swoosh.ogg"] = "Arrow Swoosh",
  [WeakAuras.PowerAurasSoundPath.."bam.ogg"] = "Bam",
  [WeakAuras.PowerAurasSoundPath.."bear_polar.ogg"] = "Polar Bear",
  [WeakAuras.PowerAurasSoundPath.."bigkiss.ogg"] = "Big Kiss",
  [WeakAuras.PowerAurasSoundPath.."BITE.ogg"] = "Bite",
  [WeakAuras.PowerAurasSoundPath.."brainfreeze.ogg"] = "Brain Freeze",
  [WeakAuras.PowerAurasSoundPath.."burp4.ogg"] = "Burp",
  [WeakAuras.PowerAurasSoundPath.."cat2.ogg"] = "Cat",
  [WeakAuras.PowerAurasSoundPath.."chant2.ogg"] = "Chant Major 2nd",
  [WeakAuras.PowerAurasSoundPath.."chant4.ogg"] = "Chant Minor 3rd",
  [WeakAuras.PowerAurasSoundPath.."chimes.ogg"] = "Chimes",
  [WeakAuras.PowerAurasSoundPath.."cookie.ogg"] = "Cookie Monster",
  [WeakAuras.PowerAurasSoundPath.."ESPARK1.ogg"] = "Electrical Spark",
  [WeakAuras.PowerAurasSoundPath.."fingeroffrost.ogg"] = "Finger of Frost",
  [WeakAuras.PowerAurasSoundPath.."Fireball.ogg"] = "Fireball",
  [WeakAuras.PowerAurasSoundPath.."Gasp.ogg"] = "Gasp",
  [WeakAuras.PowerAurasSoundPath.."heartbeat.ogg"] = "Heartbeat",
  [WeakAuras.PowerAurasSoundPath.."hic3.ogg"] = "Hiccup",
  [WeakAuras.PowerAurasSoundPath.."hotstreak.ogg"] = "Hot Streak",
  [WeakAuras.PowerAurasSoundPath.."huh_1.ogg"] = "Huh?",
  [WeakAuras.PowerAurasSoundPath.."hurricane.ogg"] = "Hurricane",
  [WeakAuras.PowerAurasSoundPath.."hyena.ogg"] = "Hyena",
  [WeakAuras.PowerAurasSoundPath.."kaching.ogg"] = "Kaching",
  [WeakAuras.PowerAurasSoundPath.."missilebarrage.ogg"] = "Missile Barrage",
  [WeakAuras.PowerAurasSoundPath.."moan.ogg"] = "Moan",
  [WeakAuras.PowerAurasSoundPath.."panther1.ogg"] = "Panther",
  [WeakAuras.PowerAurasSoundPath.."phone.ogg"] = "Phone",
  [WeakAuras.PowerAurasSoundPath.."PUNCH.ogg"] = "Punch",
  [WeakAuras.PowerAurasSoundPath.."rainroof.ogg"] = "Rain",
  [WeakAuras.PowerAurasSoundPath.."rocket.ogg"] = "Rocket",
  [WeakAuras.PowerAurasSoundPath.."shipswhistle.ogg"] = "Ship's Whistle",
  [WeakAuras.PowerAurasSoundPath.."shot.ogg"] = "Gunshot",
  [WeakAuras.PowerAurasSoundPath.."snakeatt.ogg"] = "Snake Attack",
  [WeakAuras.PowerAurasSoundPath.."sneeze.ogg"] = "Sneeze",
  [WeakAuras.PowerAurasSoundPath.."sonar.ogg"] = "Sonar",
  [WeakAuras.PowerAurasSoundPath.."splash.ogg"] = "Splash",
  [WeakAuras.PowerAurasSoundPath.."Squeakypig.ogg"] = "Squeaky Toy",
  [WeakAuras.PowerAurasSoundPath.."swordecho.ogg"] = "Sword Ring",
  [WeakAuras.PowerAurasSoundPath.."throwknife.ogg"] = "Throwing Knife",
  [WeakAuras.PowerAurasSoundPath.."thunder.ogg"] = "Thunder",
  [WeakAuras.PowerAurasSoundPath.."wickedmalelaugh1.ogg"] = "Wicked Male Laugh",
  [WeakAuras.PowerAurasSoundPath.."wilhelm.ogg"] = "Wilhelm Scream",
  [WeakAuras.PowerAurasSoundPath.."wlaugh.ogg"] = "Wicked Female Laugh",
  [WeakAuras.PowerAurasSoundPath.."wolf5.ogg"] = "Wolf Howl",
  [WeakAuras.PowerAurasSoundPath.."yeehaw.ogg"] = "Yeehaw"
}

--Texture names - low priority for localization
L.textures = {};
L["Cataclysm Alerts"] = "Cataclysm Alerts"
L.textures["Cataclysm Alerts"] = {
  ["Textures\\SpellActivationOverlays\\Arcane_Missiles"] = "Arcane Missiles",
  ["Textures\\SpellActivationOverlays\\Art_of_War"] = "Art of War",
  ["Textures\\SpellActivationOverlays\\Blood_Surge"] = "Blood Surge",
  ["Textures\\SpellActivationOverlays\\Brain_Freeze"] = "Brain Freeze",
  ["Textures\\SpellActivationOverlays\\Eclipse_Moon"] = "Eclipse Moon",
  ["Textures\\SpellActivationOverlays\\Eclipse_Sun"] = "Eclipse Sun",
  ["Textures\\SpellActivationOverlays\\Focus_Fire"] = "Focus Fire",
  ["Textures\\SpellActivationOverlays\\Frozen_Fingers"] = "Frozen Fingers",
  ["Textures\\SpellActivationOverlays\\GenericArc_01"] = "Generic Arc 1",
  ["Textures\\SpellActivationOverlays\\GenericArc_02"] = "Generic Arc 2",
  ["Textures\\SpellActivationOverlays\\GenericArc_03"] = "Generic Arc 3",
  ["Textures\\SpellActivationOverlays\\GenericArc_04"] = "Generic Arc 4",
  ["Textures\\SpellActivationOverlays\\GenericArc_05"] = "Generic Arc 5",
  ["Textures\\SpellActivationOverlays\\GenericArc_06"] = "Generic Arc 6",
  ["Textures\\SpellActivationOverlays\\GenericTop_01"] = "Generic Top 1",
  ["Textures\\SpellActivationOverlays\\GenericTop_02"] = "Generic Top 2",
  ["Textures\\SpellActivationOverlays\\Grand_Crusader"] = "Grand Crusader",
  ["Textures\\SpellActivationOverlays\\Hot_Streak"] = "Hot Streak",
  ["Textures\\SpellActivationOverlays\\Imp_Empowerment"] = "Imp Empowerment",
  ["Textures\\SpellActivationOverlays\\Impact"] = "Impact",
  ["Textures\\SpellActivationOverlays\\Lock_and_Load"] = "Lock and Load",
  ["Textures\\SpellActivationOverlays\\Maelstrom_Weapon"] = "Maelstrom Weapon",
  ["Textures\\SpellActivationOverlays\\Master_Marksman"] = "Master Marksman",
  ["Textures\\SpellActivationOverlays\\Natures_Grace"] = "Nature's Grace",
  ["Textures\\SpellActivationOverlays\\Nightfall"] = "Nightfall",
  ["Textures\\SpellActivationOverlays\\Rime"] = "Rime",
  ["Textures\\SpellActivationOverlays\\Slice_and_Dice"] = "Slice and Dice",
  ["Textures\\SpellActivationOverlays\\Sudden_Death"] = "Sudden Death",
  ["Textures\\SpellActivationOverlays\\Sudden_Doom"] = "Sudden Doom",
  ["Textures\\SpellActivationOverlays\\Surge_of_Light"] = "Surge of Light",
  ["Textures\\SpellActivationOverlays\\Sword_and_Board"] = "Sword and Board",
  ["Textures\\SpellActivationOverlays\\Backlash"] = "Backslash",
  ["Textures\\SpellActivationOverlays\\Berserk"] = "Berserk",
  ["Textures\\SpellActivationOverlays\\Blood_Boil"] = "Blood Boil",
  ["Textures\\SpellActivationOverlays\\Dark_Transformation"] = "Dark Transformation",
  ["Textures\\SpellActivationOverlays\\Denounce"] = "Denounce",
  ["Textures\\SpellActivationOverlays\\Feral_OmenOfClarity"] = "Omen of Clarity (Feral)",
  ["Textures\\SpellActivationOverlays\\Fulmination"] = "Fulmination",
  ["Textures\\SpellActivationOverlays\\Fury_of_Stormrage"] = "Fury of Stormrage",
  ["Textures\\SpellActivationOverlays\\Hand_of_Light"] = "Hand of Light",
  ["Textures\\SpellActivationOverlays\\Killing_Machine"] = "Killing Machine",
  ["Textures\\SpellActivationOverlays\\Molten_Core"] = "Molten Core",
  ["Textures\\SpellActivationOverlays\\Necropolis"] = "Necropolis",
  ["Textures\\SpellActivationOverlays\\Serendipity"] = "Serendipity",
  ["Textures\\SpellActivationOverlays\\Shooting_Stars"] = "Shooting Stars"
};
L["Icons"] = "Icons"
L.textures["Icons"] = {
    ["Spells\\Agility_128"] = "Paw",
    ["Spells\\ArrowFeather01"] = "Feathers",
    ["Spells\\Aspect_Beast"] = "Lion",
    ["Spells\\Aspect_Cheetah"] = "Cheetah",
    ["Spells\\Aspect_Hawk"] = "Hawk",
    ["Spells\\Aspect_Monkey"] = "Monkey",
    ["Spells\\Aspect_Snake"] = "Snake",
    ["Spells\\Aspect_Wolf"] = "Wolf",
    ["Spells\\EndlessRage"] = "Rage",
    ["Spells\\Eye"] = "Eye",
    ["Spells\\Eyes"] = "Eyes",
    ["Spells\\Fire_Rune_128"] = "Fire",
    ["Spells\\HolyRuinProtect"] = "Holy Ruin",
    ["Spells\\Intellect_128"] = "Intellect",
    ["Spells\\MoonCrescentGlow2"] = "Crescent",
    ["Spells\\Nature_Rune_128"] = "Leaf",
    ["Spells\\PROTECT_128"] = "Shield",
    ["Spells\\Ice_Rune_128"] = "Snowflake",
    ["Spells\\PoisonSkull1"] = "Poison Skull",
    ["Spells\\InnerFire_Rune_128"] = "Inner Fire",
    ["Spells\\RapidFire_Rune_128"] = "Rapid Fire",
    ["Spells\\Rampage"] = "Rampage",
    ["Spells\\Reticle_128"] = "Reticle",
    ["Spells\\Stamina_128"] = "Bull",
    ["Spells\\Strength_128"] = "Crossed Swords",
    ["Spells\\StunWhirl_reverse"] = "Stun Whirl",
    ["Spells\\T_Star3"] = "Star",
    ["Spells\\Spirit1"] = "Spirit"
}
L["Runes"] = "Runes"
L.textures["Runes"] = {
    ["Spells\\starrune"] = "Star Rune",
    ["Spells\\RUNEBC1"] = "Heavy BC Rune",
    ["Spells\\RuneBC2"] = "Light BC Rune",
    ["Spells\\RUNEFROST"] = "Circular Frost Rune",
    ["Spells\\Rune1d_White"] = "Dense Circular Rune",
    ["Spells\\RUNE1D_GLOWLESS"] = "Sparse Circular Rune",
    ["Spells\\Rune1d"] = "Ringed Circular Rune",
    ["Spells\\Rune1c"] = "Filled Circular Rune",
    ["Spells\\RogueRune1"] = "Dual Blades",
    ["Spells\\RogueRune2"] = "Octagonal Skulls",
    ["Spells\\HOLY_RUNE1"] = "Holy Rune",
    ["Spells\\Holy_Rune_128"] = "Holy Cross Rune",
    ["Spells\\DemonRune5backup"] = "Demon Rune",
    ["Spells\\DemonRune6"] = "Demon Rune",
    ["Spells\\DemonRune7"] = "Demon Rune",
    ["Spells\\DemonicRuneSummon01"] = "Demonic Summon",
    ["Spells\\Death_Rune"] = "Death Rune",
    ["Spells\\DarkSummon"] = "Dark Summon",
    ["Spells\\AuraRune256b"] = "Square Aura Rune",
    ["Spells\\AURARUNE256"] = "Ringed Aura Rune",
    ["Spells\\AURARUNE8"] = "Spike-Ringed Aura Rune",
    ["Spells\\AuraRune7"] = "Tri-Circle Ringed Aura Rune",
    ["Spells\\AuraRune5Green"] = "Tri-Circle Aura Rune",
    ["Spells\\AURARUNE_C"] = "Oblong Aura Rune",
    ["Spells\\AURARUNE_B"] = "Sliced Aura Rune",
    ["Spells\\AURARUNE_A"] = "Small Tri-Circle Aura Rune"
}
L["PvP Emblems"] = "PvP Emblems"
L.textures["PvP Emblems"] = {
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-1"] = "Wheelchair",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-2"] = "Recycle",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-3"] = "Biohazard",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-4"] = "Heart",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-5"] = "Lightning Bolt",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-6"] = "Bone",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-7"] = "Glove",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-2"] = "Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-3"] = "Bird Claw",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-4"] = "Canary",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-5"] = "Mushroom",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-6"] = "Cherries",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-7"] = "Ninja",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-8"] = "Dog Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-9"] = "Circled Drop",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-10"] = "Circled Glove",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-11"] = "Winged Blade",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-12"] = "Circled Cross",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-13"] = "Dynamite",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-14"] = "Intellect",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-15"] = "Feather",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-16"] = "Present",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-17"] = "Giant Jaws",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-18"] = "Drums",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-19"] = "Panda",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-20"] = "Crossed Clubs",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-21"] = "Skeleton Key",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-22"] = "Heart Potion",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-23"] = "Trophy",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-24"] = "Crossed Mallets",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-25"] = "Circled Cheetah",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-26"] = "Mutated Chicken",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-27"] = "Anvil",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-28"] = "Dwarf Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-29"] = "Brooch",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-30"] = "Spider",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-31"] = "Dual Hawks",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-32"] = "Cleaver",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-33"] = "Spiked Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-34"] = "Fist of Thunder",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-35"] = "Lean Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-36"] = "Mug",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-37"] = "Sliced Circle",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-38"] = "Totem",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-39"] = "Skull and Crossbones",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-40"] = "Voodoo Doll",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-41"] = "Dual Wolves",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-42"] = "Wolf",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-43"] = "Crossed Wrenches",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-44"] = "Saber-toothed Tiger",
    --["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-45"] = "Targeting Eye", --Duplicate of 53
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-46"] = "Artifact Disc",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-47"] = "Dice",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-48"] = "Fish Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-49"] = "Crossed Axes",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-50"] = "Doughnut",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-51"] = "Human Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-52"] = "Eyeball",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-53"] = "Targeting Eye",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-54"] = "Monkey Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-55"] = "Circle Skull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-56"] = "Tipped Glass",
    --["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-57"] = "Saber-toothed Tiger", --Duplicate of 44
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-58"] = "Pile of Weapons",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-59"] = "Mushrooms",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-60"] = "Pounding Mallet",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-61"] = "Winged Mask",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-62"] = "Axe",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-63"] = "Spiked Shield",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-64"] = "The Horns",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-65"] = "Ice Cream Cone",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-66"] = "Ornate Lockbox",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-67"] = "Roasting Marshmallow",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-68"] = "Smiley Bomb",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-69"] = "Fist",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-70"] = "Spirit Wings",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-71"] = "Ornate Pipe",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-72"] = "Scarab",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-73"] = "Glowing Ball",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-74"] = "Circular Rune",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-75"] = "Tree",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-76"] = "Flower Pot",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-77"] = "Night Elf Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-78"] = "Nested Egg",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-79"] = "Helmed Chicken",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-80"] = "Winged Boot",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-81"] = "Skull and Cross-Wrenches",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-82"] = "Cracked Skull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-83"] = "Rocket",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-84"] = "Wooden Whistle",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-85"] = "Cogwheel",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-86"] = "Lizard Eye",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-87"] = "Baited Hook",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-88"] = "Beast Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-89"] = "Talons",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-90"] = "Rabbit",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-91"] = "4-Toed Pawprint",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-92"] = "Paw",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-93"] = "Mask",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-94"] = "Spiked Helm",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-95"] = "Dog Treat",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-96"] = "Targeted Orc",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-97"] = "Bird Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-98"] = "Lollipop",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-99"] = "5-Toed Pawprint",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-100"] = "Frightened Cat",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-101"] = "Eagle Face"
}
L["Beams"] = "Beams"
L.textures["Beams"] = {
    ["Textures\\SPELLCHAINEFFECTS\\Beam_Purple"] = "Purple Beam",
    ["Textures\\SPELLCHAINEFFECTS\\Beam_Red"] = "Red Beam",
    ["Textures\\SPELLCHAINEFFECTS\\Beam_RedDrops"] = "Red Drops Beam",
    ["Textures\\SPELLCHAINEFFECTS\\DrainManaLightning"] = "Drain Mana Lightning",
    ["Textures\\SPELLCHAINEFFECTS\\Ethereal_Ribbon_Spell"] = "Ethereal Ribbon",
    ["Textures\\SPELLCHAINEFFECTS\\Ghost1_Chain"] = "Ghost Chain",
    ["Textures\\SPELLCHAINEFFECTS\\Ghost2purple_Chain"] = "Purple Ghost Chain",
    ["Textures\\SPELLCHAINEFFECTS\\HealBeam"] = "Heal Beam",
    ["Textures\\SPELLCHAINEFFECTS\\Lightning"] = "Lightning",
    ["Textures\\SPELLCHAINEFFECTS\\LightningRed"] = "Red Lightning",
    ["Textures\\SPELLCHAINEFFECTS\\ManaBeam"] = "Mana Beam",
    ["Textures\\SPELLCHAINEFFECTS\\ManaBurnBeam"] = "Mana Burn Beam",
    ["Textures\\SPELLCHAINEFFECTS\\RopeBeam"] = "Rope",
    ["Textures\\SPELLCHAINEFFECTS\\ShockLightning"] = "Shock Lightning",
    ["Textures\\SPELLCHAINEFFECTS\\SoulBeam"] = "Soul Beam",
    ["Spells\\TEXTURES\\Beam_ChainGold"] = "Gold Chain",
    ["Spells\\TEXTURES\\Beam_ChainIron"] = "Iron Chain",
    ["Spells\\TEXTURES\\Beam_FireGreen"] = "Green Fire Beam",
    ["Spells\\TEXTURES\\Beam_FireRed"] = "Red Fire Beam",
    ["Spells\\TEXTURES\\Beam_Purple_02"] = "Straight Purple Beam",
    ["Spells\\TEXTURES\\Beam_Shadow_01"] = "Shadow Beam",
    ["Spells\\TEXTURES\\Beam_SmokeBrown"] = "Brown Smoke Beam",
    ["Spells\\TEXTURES\\Beam_SmokeGrey"] = "Grey Smoke Beam",
    ["Spells\\TEXTURES\\Beam_SpiritLink"] = "Spirit Link Beam",
    ["Spells\\TEXTURES\\Beam_SummonGargoyle"] = "Summon Gargoyle Beam",
    ["Spells\\TEXTURES\\Beam_VineGreen"] = "Green Vine",
    ["Spells\\TEXTURES\\Beam_VineRed"] = "Red Vine",
    ["Spells\\TEXTURES\\Beam_WaterBlue"] = "Blue Water Beam",
    ["Spells\\TEXTURES\\Beam_WaterGreen"] = "Green Water Beam"
}
L["PowerAuras Heads-Up"] = "PowerAuras Heads-Up"
L.textures["PowerAuras Heads-Up"] = {
    [WeakAuras.PowerAurasPath.."Aura1"] = "Runed Text",
    [WeakAuras.PowerAurasPath.."Aura2"] = "Runed Text On Ring",
    [WeakAuras.PowerAurasPath.."Aura3"] = "Power Waves",
    [WeakAuras.PowerAurasPath.."Aura4"] = "Majesty",
    [WeakAuras.PowerAurasPath.."Aura5"] = "Runed Ends",
    [WeakAuras.PowerAurasPath.."Aura6"] = "Extra Majesty",
    [WeakAuras.PowerAurasPath.."Aura7"] = "Triangular Highlights",
    [WeakAuras.PowerAurasPath.."Aura11"] = "Oblong Highlights",
    [WeakAuras.PowerAurasPath.."Aura16"] = "Thin Crescents",
    [WeakAuras.PowerAurasPath.."Aura17"] = "Crescent Highlights",
    [WeakAuras.PowerAurasPath.."Aura18"] = "Dense Runed Text",
    [WeakAuras.PowerAurasPath.."Aura23"] = "Runed Spiked Ring",
    [WeakAuras.PowerAurasPath.."Aura24"] = "Smoke",
    [WeakAuras.PowerAurasPath.."Aura28"] = "Flourished Text",
    [WeakAuras.PowerAurasPath.."Aura33"] = "Droplet Highlights"
}
L["PowerAuras Icons"] = "PowerAuras Icons"
L.textures["PowerAuras Icons"] = {
    [WeakAuras.PowerAurasPath.."Aura8"] = "Rune",
    [WeakAuras.PowerAurasPath.."Aura9"] = "Stylized Ghost",
    [WeakAuras.PowerAurasPath.."Aura10"] = "Skull and Crossbones",
    [WeakAuras.PowerAurasPath.."Aura12"] = "Snowflake",
    [WeakAuras.PowerAurasPath.."Aura13"] = "Flame",
    [WeakAuras.PowerAurasPath.."Aura14"] = "Holy Rune",
    [WeakAuras.PowerAurasPath.."Aura15"] = "Zig-Zag Exclamation Point",
    [WeakAuras.PowerAurasPath.."Aura19"] = "Crossed Swords",
    [WeakAuras.PowerAurasPath.."Aura21"] = "Shield",
    [WeakAuras.PowerAurasPath.."Aura22"] = "Glow",
    [WeakAuras.PowerAurasPath.."Aura25"] = "Cross",
    [WeakAuras.PowerAurasPath.."Aura26"] = "Droplet",
    [WeakAuras.PowerAurasPath.."Aura27"] = "Alert",
    [WeakAuras.PowerAurasPath.."Aura29"] = "Paw",
    [WeakAuras.PowerAurasPath.."Aura30"] = "Bull",
    [WeakAuras.PowerAurasPath.."Aura32"] = "Heiroglyphics",
    [WeakAuras.PowerAurasPath.."Aura34"] = "Circled Arrow",
    [WeakAuras.PowerAurasPath.."Aura35"] = "Short Sword",
    [WeakAuras.PowerAurasPath.."Aura45"] = "Circular Glow",
    [WeakAuras.PowerAurasPath.."Aura48"] = "Totem",
    [WeakAuras.PowerAurasPath.."Aura49"] = "Dragon Blade",
    [WeakAuras.PowerAurasPath.."Aura50"] = "Ornate Design",
    [WeakAuras.PowerAurasPath.."Aura52"] = "Stylized Skull",
    [WeakAuras.PowerAurasPath.."Aura53"] = "Exclamation Point",
    [WeakAuras.PowerAurasPath.."Aura54"] = "Nonagon",
    [WeakAuras.PowerAurasPath.."Aura68"] = "Wings",
    [WeakAuras.PowerAurasPath.."Aura69"] = "Rectangle",
    [WeakAuras.PowerAurasPath.."Aura70"] = "Low Mana",
    [WeakAuras.PowerAurasPath.."Aura71"] = "Ghostly Eye",
    [WeakAuras.PowerAurasPath.."Aura72"] = "Circle",
    [WeakAuras.PowerAurasPath.."Aura73"] = "Ring",
    [WeakAuras.PowerAurasPath.."Aura74"] = "Square",
    [WeakAuras.PowerAurasPath.."Aura75"] = "Square Brackets",
    [WeakAuras.PowerAurasPath.."Aura76"] = "Bob-omb",
    [WeakAuras.PowerAurasPath.."Aura77"] = "Goldfish",
    [WeakAuras.PowerAurasPath.."Aura78"] = "Check",
    [WeakAuras.PowerAurasPath.."Aura79"] = "Ghostly Face",
    [WeakAuras.PowerAurasPath.."Aura84"] = "Overlapping Boxes",
    [WeakAuras.PowerAurasPath.."Aura87"] = "Fairy",
    [WeakAuras.PowerAurasPath.."Aura88"] = "Comet",
    [WeakAuras.PowerAurasPath.."Aura95"] = "Dual Spiral",
    [WeakAuras.PowerAurasPath.."Aura96"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura97"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura98"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura99"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura100"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura101"] = "Ball of Flame",
    [WeakAuras.PowerAurasPath.."Aura102"] = "Zig-Zag",
    [WeakAuras.PowerAurasPath.."Aura103"] = "Thorny Ring",
    [WeakAuras.PowerAurasPath.."Aura110"] = "Hunter's Mark",
    [WeakAuras.PowerAurasPath.."Aura112"] = "Kaleidoscope",
    [WeakAuras.PowerAurasPath.."Aura113"] = "Jesus Face",
    [WeakAuras.PowerAurasPath.."Aura114"] = "Green Mushrrom",
    [WeakAuras.PowerAurasPath.."Aura115"] = "Red Mushroom",
    [WeakAuras.PowerAurasPath.."Aura116"] = "Fire Flower",
    [WeakAuras.PowerAurasPath.."Aura117"] = "Radioactive",
    [WeakAuras.PowerAurasPath.."Aura118"] = "X",
    [WeakAuras.PowerAurasPath.."Aura119"] = "Flower",
    [WeakAuras.PowerAurasPath.."Aura120"] = "Petal",
    [WeakAuras.PowerAurasPath.."Aura130"] = "Shoop Da Woop",
    [WeakAuras.PowerAurasPath.."Aura132"] = "Cartoon Skull",
    [WeakAuras.PowerAurasPath.."Aura138"] = "Stop",
    [WeakAuras.PowerAurasPath.."Aura139"] = "Thumbs Up",
    [WeakAuras.PowerAurasPath.."Aura140"] = "Palette",
    [WeakAuras.PowerAurasPath.."Aura141"] = "Blue Ring",
    [WeakAuras.PowerAurasPath.."Aura142"] = "Ornate Ring",
    [WeakAuras.PowerAurasPath.."Aura143"] = "Ghostly Skull"
}
L["PowerAuras Separated"] = "PowerAuras Separated"
L.textures["PowerAuras Separated"] = {
    [WeakAuras.PowerAurasPath.."Aura55"] = "Skull on Gear 1",
    [WeakAuras.PowerAurasPath.."Aura56"] = "Skull on Gear 2",
    [WeakAuras.PowerAurasPath.."Aura57"] = "Skull on Gear 3",
    [WeakAuras.PowerAurasPath.."Aura58"] = "Skull on Gear 4",
    [WeakAuras.PowerAurasPath.."Aura59"] = "Rune Ring Full",
    [WeakAuras.PowerAurasPath.."Aura60"] = "Rune Ring Empty",
    [WeakAuras.PowerAurasPath.."Aura61"] = "Rune Ring Left",
    [WeakAuras.PowerAurasPath.."Aura62"] = "Rune Ring Right",
    [WeakAuras.PowerAurasPath.."Aura63"] = "Spiked Rune Ring Full",
    [WeakAuras.PowerAurasPath.."Aura64"] = "Spiked Rune Ring Empty",
    [WeakAuras.PowerAurasPath.."Aura65"] = "Spiked Rune Ring Left",
    [WeakAuras.PowerAurasPath.."Aura66"] = "Spiked Rune Ring Bottom",
    [WeakAuras.PowerAurasPath.."Aura67"] = "Spiked Rune Ring Right",
    [WeakAuras.PowerAurasPath.."Aura80"] = "Spiked Helm Background",
    [WeakAuras.PowerAurasPath.."Aura81"] = "Spiked Helm Full",
    [WeakAuras.PowerAurasPath.."Aura82"] = "Spiked Helm Bottom",
    [WeakAuras.PowerAurasPath.."Aura83"] = "Spiked Helm Top",
    [WeakAuras.PowerAurasPath.."Aura89"] = "5-Part Ring 1",
    [WeakAuras.PowerAurasPath.."Aura90"] = "5-Part Ring 2",
    [WeakAuras.PowerAurasPath.."Aura91"] = "5-Part Ring 3",
    [WeakAuras.PowerAurasPath.."Aura92"] = "5-Part Ring 4",
    [WeakAuras.PowerAurasPath.."Aura93"] = "5-Part Ring 5",
    [WeakAuras.PowerAurasPath.."Aura94"] = "5-Part Ring Full",
    [WeakAuras.PowerAurasPath.."Aura104"] = "Shield Center",
    [WeakAuras.PowerAurasPath.."Aura105"] = "Shield Full",
    [WeakAuras.PowerAurasPath.."Aura106"] = "Shield Top Right",
    [WeakAuras.PowerAurasPath.."Aura107"] = "Shiled Top Left",
    [WeakAuras.PowerAurasPath.."Aura108"] = "Shield Bottom Right",
    [WeakAuras.PowerAurasPath.."Aura109"] = "Shield Bottom Left",
    [WeakAuras.PowerAurasPath.."Aura121"] = "Vine Top Right Leaf",
    [WeakAuras.PowerAurasPath.."Aura122"] = "Vine Left Leaf",
    [WeakAuras.PowerAurasPath.."Aura123"] = "Vine Bottom Right Leaf",
    [WeakAuras.PowerAurasPath.."Aura124"] = "Vine Stem",
    [WeakAuras.PowerAurasPath.."Aura125"] = "Vine Thorns",
    [WeakAuras.PowerAurasPath.."Aura126"] = "3-Part Circle 1",
    [WeakAuras.PowerAurasPath.."Aura127"] = "3-Part Circle 2",
    [WeakAuras.PowerAurasPath.."Aura128"] = "3-Part Circle 3",
    [WeakAuras.PowerAurasPath.."Aura129"] = "3-Part Circle Full",
    [WeakAuras.PowerAurasPath.."Aura133"] = "Sliced Orb 1",
    [WeakAuras.PowerAurasPath.."Aura134"] = "Sliced Orb 2",
    [WeakAuras.PowerAurasPath.."Aura135"] = "Sliced Orb 3",
    [WeakAuras.PowerAurasPath.."Aura136"] = "Sliced Orb 4",
    [WeakAuras.PowerAurasPath.."Aura137"] = "Sliced Orb 5",
    [WeakAuras.PowerAurasPath.."Aura144"] = "Taijitu Bottom",
    [WeakAuras.PowerAurasPath.."Aura145"] = "Taijitu Top"
}
L["PowerAuras Words"] = "PowerAuras Words"
L.textures["PowerAuras Words"] = {
    [WeakAuras.PowerAurasPath.."Aura20"] = "Power",
    [WeakAuras.PowerAurasPath.."Aura37"] = "Slow",
    [WeakAuras.PowerAurasPath.."Aura38"] = "Stun",
    [WeakAuras.PowerAurasPath.."Aura39"] = "Silence",
    [WeakAuras.PowerAurasPath.."Aura40"] = "Root",
    [WeakAuras.PowerAurasPath.."Aura41"] = "Disorient",
    [WeakAuras.PowerAurasPath.."Aura42"] = "Dispell",
    [WeakAuras.PowerAurasPath.."Aura43"] = "Danger",
    [WeakAuras.PowerAurasPath.."Aura44"] = "Buff"
}
L["Shapes"] = "Shapes"
L.textures["Shapes"] = {
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth"] = "Smooth Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth_Border"] = "Smooth Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Squirrel"] = "Spiralled Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Squirrel_Border"] = "Spiralled Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_White"] = "Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_White_Border"] = "Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth"] = "Smooth Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border"] = "Smooth Square with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border2"] = "Smooth Square with Border 2",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Squirrel"] = "Spiralled Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Squirrel_Border"] = "Spiralled Square with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White"] = "Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White_Border"] = "Square with Border"
}

--@end-do-not-package@