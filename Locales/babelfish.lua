#!/usr/bin/lua

-- Prefix to all files if this script is run from a subdir, for example
local filePrefix = "../"

-- find . -name "*.lua" | grep -v Localization-
local fileList = {
	WeakAuras = {
		"BuffTrigger.lua",
		"GenericTrigger.lua",
		"Init.lua",
		"Prototypes.lua",
		"RegionTypes/aurabar.lua",
		"RegionTypes/dynamicgroup.lua",
		"RegionTypes/group.lua",
		"RegionTypes/icon.lua",
		"RegionTypes/model.lua",
		"RegionTypes/progresstexture.lua",
		"RegionTypes/text.lua",
		"RegionTypes/texture.lua",
		"Transmission.lua",
		"Types.lua",
		"WeakAuras.lua",
	},
	WeakAuras_Options = {
		"Options/RegionOptions/aurabar.lua",
		"Options/RegionOptions/dynamicgroup.lua",
		"Options/RegionOptions/group.lua",
		"Options/RegionOptions/icon.lua",
		"Options/RegionOptions/model.lua",
		"Options/RegionOptions/progresstexture.lua",
		"Options/RegionOptions/text.lua",
		"Options/RegionOptions/texture.lua",
		"Options/WeakAurasOptions.lua",
	},
	WeakAuras_Tutorials = {
		"Tutorials/TutorialCore.lua",
		"Tutorials/Tutorials/beginner.lua",
		"Tutorials/Tutorials/newfeatures.lua",
	},
}
local ordered = {
	"WeakAuras",
	"WeakAuras_Options",
	"WeakAuras_Tutorials",
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