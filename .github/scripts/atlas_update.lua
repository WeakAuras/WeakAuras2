local version = ...

print("Creating atlas file for", version)

local versionMap = {
  wow = "_Retail",
  wow_classic = "_Wrath",
  wow_classic_beta = "_Cata",
  wow_classic_era = "_Vanilla"
}

if not versionMap[version] then
  print("Unknown version", version)
  return 1
end

local outputFileName = "Atlas" .. versionMap[version] .. ".lua"

local ftcsv = require('ftcsv')

local validAtlasIds = {}
local validAtlasElementIds = {}
local validNames = {}

for lineNr, atlas in ftcsv.parseLine("UiTextureAtlas.csv", ",") do
  validAtlasIds[atlas.ID] = true
end

for lineNr, member in ftcsv.parseLine("UiTextureAtlasMember.csv", ",") do
  local uiTextureAtlasID = member.UiTextureAtlasID
  local uiTextureAtlasElementId = member.UiTextureAtlasElementID

  if validAtlasIds[uiTextureAtlasID] and not validAtlasElementIds[uiTextureAtlasElementId] then
    validAtlasElementIds[uiTextureAtlasElementId] = true
  end
end

for lineNr, element in ftcsv.parseLine("UiTextureAtlasElement.csv", ",") do
  local name = element.Name
  local id = element.ID
  if validAtlasElementIds[id] and name:lower():sub(1, 5) ~= "cguy_" then
    validNames[name] = true
  end
end

--for name in pairs(validNames) do
--  print("Found +", name)
--end

local sortedNames = {}
for name in pairs(validNames) do
  table.insert(sortedNames, name)
end

table.sort(sortedNames)

local output = io.open(outputFileName, "w+")
output:write("if not WeakAuras.IsLibsOK() then return end\n")
output:write("--- @type string, Private\n")
output:write("local AddonName, Private = ...\n")
output:write("Private.AtlasList = {\n")
for i, name in ipairs(sortedNames) do
  output:write('"')
  output:write(name)
  output:write('",\n')
end
output:write("}\n")
io.close(output)

print("Created output file", outputFileName)
return 0
