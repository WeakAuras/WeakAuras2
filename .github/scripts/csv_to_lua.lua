
-- usage:
-- # lua.exe ./list_to_table.lua <release>

local releases = {
  classic = {
    input = "classic_list.csv", -- get it from https://wow.tools/casc/listfile/download/csv/build?buildConfig=9ad6ad5306deb8eed364b64cc628ac98
    output = "ModelPathsClassic.lua",
    generate = true
  },
  retail = {
    input = "retail_list.csv", -- get it from https://wow.tools/casc/listfile/download/csv/build?buildConfig=26291f284f42494375d511d1fc120216 (last retail build when i write that)
    output = "ModelPaths.lua",
    generate = true
  }
}

require "table"

if not arg[1] or not releases[arg[1]] then
  print(arg[0], "<classic|retail>")
  return
end

local function recurseSet(var, key, value)
  local subkey, _, todo = key:match("^([^/]*)(/(.*))")
  if subkey == nil then
    -- var[key] = value
    local idx = 1
    for k, v in pairs(var) do
      if key > v.value then
        idx = idx + 1
      else
        break
      end
    end
    table.insert(var, idx, {
          value = key,
          text = key,
          fileId = tostring(value),
    })
  elseif todo == nil then
    local idx = 1
    for k, v in pairs(var) do
      if subkey > v.value then
        idx = idx + 1
      else
        break
      end
    end
    table.insert(var, idx, {
           value = subkey,
           text = subkey,
           fileId = tostring(value),
     })
  else
     local tab
     for k, v in pairs(var) do
        if v.value == subkey then
           tab = var[k].children
           break
        end
     end
     if tab == nil then
      local idx = 1
      for k, v in pairs(var) do
        if subkey > v.value then
          idx = idx + 1
        else
          break
        end
      end
        tab = {
           value = subkey,
           text = subkey,
           children = {},
        }
        table.insert(var, idx, tab)
        tab = tab.children
     end
     recurseSet(tab, todo, value)
  end
end

local function serializeTable(val, name, skipnewlines, depth)
  skipnewlines = skipnewlines or false
  depth = depth or 0

  local tmp = string.rep(" ", depth)

  if name and type(name) ~= "number" then
    tmp = tmp .. name .. " = "
  end

  if type(val) == "table" then
      tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

      for k, v in pairs(val) do
          tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
      end

      tmp = tmp .. string.rep(" ", depth) .. "}"
  elseif type(val) == "number" then
      tmp = tmp .. tostring(val)
  elseif type(val) == "string" then
      tmp = tmp .. string.format("%q", val)
  elseif type(val) == "boolean" then
      tmp = tmp .. (val and "true" or "false")
  else
      tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
  end

  return tmp
end

local info = releases[arg[1]]
if info and info.generate then
  local models = {}
  for line in io.lines(info.input) do
    local fileid, file = line:match("(%d*);(.*)")
    if file and file:match("%.m2$") then
      recurseSet(models, file, fileid)
    end
  end

  local outputFile = io.open(info.output, "w")
  outputFile:write("WeakAuras.ModelPaths = " .. serializeTable(models))
  io.close(outputFile)
  print(info.output, "built")
else
  print("don't build")
end
