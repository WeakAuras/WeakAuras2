#!/usr/bin/lua

-- Prefix to all files if this script is run from a subdir, for example
local filePrefix = ""

-- luacheck: globals io

local function generateFileList(dir)
    local fileTable = {}
    local p = io.popen('find "'.. dir ..'" -name "*.lua" -not -path "*/Locales/*" -not -path "*/Libs/*"')
    for file in p:lines() do
        table.insert(fileTable, file)
    end

    return fileTable
end

local fileList = {
    WeakAuras_Main = generateFileList("WeakAuras"),
    WeakAuras_Options = generateFileList("WeakAurasOptions"),
    WeakAuras_Templates = generateFileList("WeakAurasTemplates"),
}

local ordered = {
    "WeakAuras_Main",
    "WeakAuras_Options",
    "WeakAuras_Templates",
}

local overrides = {
    ["Negator"] = "Not",
    ["Group (verb)"] = "Group",
    ["Custom trigger event tooltip"] = [=[
Choose which events cause the custom trigger to be checked. Multiple events can be specified using commas or spaces.
• "UNIT" events can use colons to define which unitIDs will be registered. In addition to UnitIDs Unit types can be used, they include "nameplate", "group", "raid", "party", "arena", "boss".
• "CLEU" can be used instead of COMBAT_LOG_EVENT_UNFILTERED and colons can be used to separate specific "subEvents" you want to receive.
• The keyword "TRIGGER" can be used, with colons separating trigger numbers, to have the custom trigger get updated when the specified trigger(s) update.

|cFF4444FFFor example:|r
UNIT_POWER_UPDATE:player, UNIT_AURA:nameplate:group PLAYER_TARGET_CHANGED CLEU:SPELL_CAST_SUCCESS TRIGGER:3:1
]=],
    ["Custom trigger status tooltip"] = [=[
Choose which events cause the custom trigger to be checked. Multiple events can be specified using commas or spaces.

• "UNIT" events can use colons to define which unitIDs will be registered. In addition to UnitIDs Unit types can be used, they include "nameplate", "group", "raid", "party", "arena", "boss".
• "CLEU" can be used instead of COMBAT_LOG_EVENT_UNFILTERED and colons can be used to separate specific "subEvents" you want to receive.
• The keyword "TRIGGER" can be used, with colons separating trigger numbers, to have the custom trigger get updated when the specified trigger(s) update.

Since this is a status-type trigger, the specified events may be called by WeakAuras without the expected arguments.

|cFF4444FFFor example:|r
UNIT_POWER_UPDATE:player, UNIT_AURA:nameplate:group PLAYER_TARGET_CHANGED CLEU:SPELL_CAST_SUCCESS TRIGGER:3:1
]=],
    ["Multiselect ignored tooltip"] = [=[
|cFFFF0000Ignored|r - |cFF777777Single|r - |cFF777777Multiple|r
This option will not be used to determine when this display should load]=],
    ["Multiselect multiple tooltip"] = [=[
|cFF777777Ignored|r - |cFF777777Single|r - |cFF00FF00Multiple|r
Any number of matching values can be picked]=],
    ["Multiselect single tooltip"] = [=[
|cFF777777Ignored|r - |cFF00FF00Single|r - |cFF777777Multiple|r
Only a single matching value can be picked]=],
    ["Animation relative duration description"] = [=[
The duration of the animation relative to the duration of the display, expressed as a fraction (1/2), percentage (50%), or decimal (0.5).
|cFFFF0000Note:|r if a display does not have progress (it has a non-timed event trigger, is an aura with no duration, etc.), the animation will not play.

|cFF4444FFFor Example:|r
If the animation's duration is set to |cFF00CC0010%|r, and the display's trigger is a buff that lasts 20 seconds, the start animation will play for 2 seconds.
If the animation's duration is set to |cFF00CC0010%|r, and the display's trigger is a buff that has no set duration, no start animation will play (although it would if you specified a duration in seconds)."
]=],
    ["Shift-click to create chat link"] = "Shift-click to create a |cFF8800FF[Chat Link]",
    ["Group aura count description"] = [=[
The amount of units of type '%s' which must be affected by one or more of the given auras for the display to trigger.
If the entered number is a whole number (e.g. 5), the number of affected units will be compared with the entered number.
If the entered number is a decimal (e.g. 0.5), fraction (e.g. 1/2), or percentage (e.g. 50%%), then that fraction of the %s must be affected.

|cFF4444FFFor example:|r
|cFF00CC00> 0|r will trigger when any unit of type '%s' is affected
|cFF00CC00= 100%%|r will trigger when every unit of type '%s' is affected
|cFF00CC00!= 2|r will trigger when the number of units of type '%s' affected is not exactly 2
|cFF00CC00<= 0.8|r will trigger when less than 80%% of the units of type '%s' is affected (4 of 5 party members, 8 of 10 or 20 of 25 raid members)
|cFF00CC00> 1/2|r will trigger when more than half of the units of type '%s' is affected
]=]
}

local function parseFile(filename)
    local strings = {}
    local file = assert(io.open(string.format("%s%s", filePrefix or "", filename), "r"), "Could not open " .. filename)
    local text = file:read("*all")
    file:close()

    for match in string.gmatch(text, "L%[\"(.-)\"%]") do
        strings[match] = true
    end

    return strings
end

-- extract data from specified lua files
local dedupe = {}
for _, namespace in ipairs(ordered) do
    print(namespace)
    local ns_file = assert(io.open(namespace .. ".lua", "w"), "Error opening file")
    local sorted = {}
    for _, file in ipairs(fileList[namespace]) do
        local count = 0
        local strings = parseFile(file)

        for k in next, strings do
            if not dedupe[k] then
                if overrides[k] then
                    table.insert(sorted, string.format("L[\"%s\"] = [=[%s]=]", k, overrides[k]))
                else
                    table.insert(sorted, string.format("L[\"%s\"] = true", k))
                end
                dedupe[k] = true
                count = count + 1
            end
        end
        print("  (" .. count .. ") " .. file)
    end
    table.sort(sorted)
    if #sorted > 0 then
        ns_file:write(table.concat(sorted, "\n"))
    end
    ns_file:close()
end
