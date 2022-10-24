
-- csv file downloaded from https://wow.tools/dbc/?dbc=uitextureatlasmember&build=10.0.2.46157#page=1
-- this page will no longer exist for long time...

local atlas_csv = "uitextureatlasmember.csv"
local atlas_list = {}
for line in io.lines(atlas_csv) do
  local atlas = line:match("^[^,]+")
  if atlas  then
    table.insert(atlas_list, atlas)
  end
end

local atlas_lua = io.open("atlas.lua", "w")
atlas_lua:write("WeakAuras.AtlasList = {'" .. table.concat(atlas_list, "','").."'}")
io.close(atlas_lua)