-- usage:
-- # lua.exe ./list_to_table.lua <release>

local releases = {
  wow_classic_era = {
    input = "wow_classic_era.csv",
    output = "ModelPathsClassic.lua",
    generate = true,
  },
  wow_classic = {
    input = "wow_classic.csv",
    output = "ModelPathsWrath.lua",
    generate = true,
  },
  wow_classic_beta = {
    input = "wow_classic_beta.csv",
    output = "ModelPathsCata.lua",
    generate = true,
  },
  wow = {
    input = "wow.csv",
    output = "ModelPaths.lua",
    generate = true,
  },
}

require("table")

if not arg[1] or not releases[arg[1]] then
  print(arg[0], "<wow|wow_classic|wow_classic_beta|wow_classic_era>")
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

    -- Get the keys
    local keys = {}
    for k in pairs(val) do
      table.insert(keys, k)
    end

    -- Sort the keys
    table.sort(keys)

    -- Iterate over the sorted keys
    for _, k in ipairs(keys) do
      local v = val[k]
      tmp = tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
    end

    tmp = tmp .. string.rep(" ", depth) .. "}"
  elseif type(val) == "number" then
    tmp = tmp .. tostring(val)
  elseif type(val) == "string" then
    tmp = tmp .. string.format("%q", val)
  elseif type(val) == "boolean" then
    tmp = tmp .. (val and "true" or "false")
  else
    tmp = tmp .. '"[unserializable datatype:' .. type(val) .. ']"'
  end

  return tmp
end

local info = releases[arg[1]]
if info and info.generate then
  local models = {}
  for line in io.lines(info.input) do
    local fileId, file = line:match("(%d*);(.*)")
    if file and file:match("%.m2$") then
      recurseSet(models, file, fileId)
    end
  end

  local outputFile = io.open(info.output, "w")
  outputFile:write("WeakAuras.ModelPaths = " .. serializeTable(models))
  io.close(outputFile)
  print(info.output, "built")
else
  print("don't build")
end
