#!/usr/bin/lua

-- Prefix to all files if this script is run from a subdir, for example
local filePrefix = "../"

-- find . -name "*.lua" | grep -v Localization-
local fileList = {
	WeakAuras = {
		"WeakAuras/BuffTrigger.lua",
		"WeakAuras/GenericTrigger.lua",
		"WeakAuras/Init.lua",
		"WeakAuras/Prototypes.lua",
		"WeakAuras/RegionTypes/aurabar.lua",
		"WeakAuras/RegionTypes/dynamicgroup.lua",
		"WeakAuras/RegionTypes/group.lua",
		"WeakAuras/RegionTypes/icon.lua",
		"WeakAuras/RegionTypes/model.lua",
		"WeakAuras/RegionTypes/progresstexture.lua",
		"WeakAuras/RegionTypes/text.lua",
		"WeakAuras/RegionTypes/texture.lua",
		"WeakAuras/Transmission.lua",
		"WeakAuras/Types.lua",
		"WeakAuras/WeakAuras.lua",
	},
	WeakAuras_Options = {
		"WeakAurasOptions/RegionOptions/aurabar.lua",
		"WeakAurasOptions/RegionOptions/dynamicgroup.lua",
		"WeakAurasOptions/RegionOptions/group.lua",
		"WeakAurasOptions/RegionOptions/icon.lua",
		"WeakAurasOptions/RegionOptions/model.lua",
		"WeakAurasOptions/RegionOptions/progresstexture.lua",
		"WeakAurasOptions/RegionOptions/text.lua",
		"WeakAurasOptions/RegionOptions/texture.lua",
		"WeakAurasOptions/WeakAurasOptions.lua",
	},	
	WeakAuras_Templates = {
		"WeakAurasTemplates/TriggerTemplates.lua",
		"WeakAurasTemplates/TriggerTemplatesData.lua",
	},
}

local ordered = {
	"WeakAuras",
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