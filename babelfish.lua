#!/usr/bin/lua

-- Prefix to all files if this script is run from a subdir, for example
local filePrefix = ""

-- luacheck: globals io

-- find . -name "*.lua" | grep -v Locales
local fileList = {
    WeakAuras_Main = {
        "WeakAuras/RegionTypes/AuraBar.lua",
        "WeakAuras/RegionTypes/DynamicGroup.lua",
        "WeakAuras/RegionTypes/Group.lua",
        "WeakAuras/RegionTypes/Icon.lua",
        "WeakAuras/RegionTypes/Model.lua",
        "WeakAuras/RegionTypes/ProgressTexture.lua",
        "WeakAuras/RegionTypes/RegionPrototype.lua",
        "WeakAuras/RegionTypes/Text.lua",
        "WeakAuras/RegionTypes/Texture.lua",
        "WeakAuras/AuraEnvironment.lua",
        "WeakAuras/BuffTrigger.lua",
        "WeakAuras/GenericTrigger.lua",
        "WeakAuras/Init.lua",
        "WeakAuras/Profiling.lua",
        "WeakAuras/Prototypes.lua",
        "WeakAuras/Transmission.lua",
        "WeakAuras/Types.lua",
        "WeakAuras/WeakAuras.lua",
    },
    WeakAuras_Options = {
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasDisplayButton.lua",
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasIconButton.lua",
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasImportButton.lua",
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasLoadedHeaderButton.lua",
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasMultiLineEditBox.lua",
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasNewButton.lua",
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasNewHeaderButton.lua",
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasSortedDropDown.lua",
        "WeakAurasOptions/AceGUI-Widgets/AceGUIWidget-WeakAurasTextureButton.lua",
        "WeakAurasOptions/OptionsFrames/CodeReview.lua",
        "WeakAurasOptions/OptionsFrames/FrameChooser.lua",
        "WeakAurasOptions/OptionsFrames/IconPicker.lua",
        "WeakAurasOptions/OptionsFrames/ImportExport.lua",
        "WeakAurasOptions/OptionsFrames/ModelPicker.lua",
        "WeakAurasOptions/OptionsFrames/MoverSizer.lua",
        "WeakAurasOptions/OptionsFrames/OptionsFrame.lua",
        "WeakAurasOptions/OptionsFrames/TextEditor.lua",
        "WeakAurasOptions/OptionsFrames/TexturePicker.lua",
        "WeakAurasOptions/RegionOptions/AuraBar.lua",
        "WeakAurasOptions/RegionOptions/DynamicGroup.lua",
        "WeakAurasOptions/RegionOptions/Group.lua",
        "WeakAurasOptions/RegionOptions/Icon.lua",
        "WeakAurasOptions/RegionOptions/Model.lua",
        "WeakAurasOptions/RegionOptions/ProgressTexture.lua",
        "WeakAurasOptions/RegionOptions/Text.lua",
        "WeakAurasOptions/RegionOptions/Texture.lua",
        "WeakAurasOptions/ActionOptions.lua",
        "WeakAurasOptions/AnimationOptions.lua",
        "WeakAurasOptions/BuffTrigger.lua",
        "WeakAurasOptions/Cache.lua",
        "WeakAurasOptions/ConditionOptions.lua",
        "WeakAurasOptions/ExternalAddons.lua",
        "WeakAurasOptions/GenericTrigger.lua",
        "WeakAurasOptions/WeakAurasOptions.lua",
    },
    WeakAuras_Templates = {
        "WeakAurasTemplates/TriggerTemplates.lua",
        "WeakAurasTemplates/TriggerTemplatesData.lua",
    },
}

local ordered = {
    "WeakAuras_Main",
    "WeakAuras_Options",
    "WeakAuras_Templates",
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
for _, namespace in ipairs(ordered) do
    print(namespace)
    local ns_file = assert(io.open(namespace .. ".lua", "w"), "Error opening file")
    for _, file in ipairs(fileList[namespace]) do
        local strings = parseFile(file)

        local sorted = {}
        for k in next, strings do
            table.insert(sorted, k)
        end
        table.sort(sorted)
        if #sorted > 0 then
            for _, v in ipairs(sorted) do
                ns_file:write(string.format("L[\"%s\"] = true\n", v))
            end
        end
        print("  (" .. #sorted .. ") " .. file)
    end
    ns_file:close()
end
