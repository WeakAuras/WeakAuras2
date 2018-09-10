local WeakAuras = WeakAuras
local L = WeakAuras.L
local prettyPrint = WeakAuras.prettyPrint

local profileData = {}
profileData.systems = {}
profileData.auras = {}

local function StartProfiling(map, id)
  if (not map[id]) then
    map[id] = {}
    map[id].count = 1
    map[id].start = debugprofilestop()
    map[id].elapsed = 0
    return
  end

  if (map[id].count == 0) then
    map[id].count = 1
    map[id].start = debugprofilestop()
  else
    map[id].count = map[id].count + 1
  end
end

local function StopProfiling(map, id)
  map[id].count = map[id].count - 1
  if (map[id].count == 0) then
    map[id].elapsed = map[id].elapsed + debugprofilestop() - map[id].start
  end
end

local function StartProfileSystem(system)
  StartProfiling(profileData.systems, "wa")
  StartProfiling(profileData.systems, system)
end

local function StartProfileAura(id)
  StartProfiling(profileData.auras, id)
end

local function StopProfileSystem(system)
  StopProfiling(profileData.systems, "wa")
  StopProfiling(profileData.systems, system)
end

local function StopProfileAura(id)
  StopProfiling(profileData.auras, id)
end

function WeakAuras.ProfileRenameAura(oldid, id)
  profileData.auras[id] = profileData.auras[id]
  profileData.auras[oldid] = nil
end

function WeakAuras.StartProfile()
  if (profileData.systems.time and profileData.systems.time.count == 1) then
    prettyPrint(L["Profiling already started."])
    return
  end

  prettyPrint(L["Profiling started."])

  profileData.systems = {}
  profileData.auras = {}
  profileData.systems.time = {}
  profileData.systems.time.start = debugprofilestop()
  profileData.systems.time.count = 1

  WeakAuras.StartProfileSystem = StartProfileSystem
  WeakAuras.StartProfileAura = StartProfileAura
  WeakAuras.StopProfileSystem = StopProfileSystem
  WeakAuras.StopProfileAura = StopProfileAura
end

local function doNothing()
end

function WeakAuras.StopProfile()
  if (not profileData.systems.time or profileData.systems.time.count ~= 1) then
    prettyPrint(L["Profiling not running."])
    return
  end

  prettyPrint(L["Profiling stopped."])

  profileData.systems.time.elapsed = debugprofilestop() - profileData.systems.time.start
  profileData.systems.time.count = 0

  WeakAuras.StartProfileSystem = doNothing
  WeakAuras.StartProfileAura = doNothing
  WeakAuras.StopProfileSystem = doNothing
  WeakAuras.StopProfileAura = doNothing
end

local function PrintOneProfile(name, map, total)
  if (map.count ~= 0) then
    print(name, "ERROR: count is not zero:", map.count)
  end
  local percent = ""
  if (total) then
    percent = ", " .. string.format("%.2f", 100 * map.elapsed / total) .. "%"
  end
  print(name, string.format("%.2f", map.elapsed) .. "ms" .. percent)
end

local function SortProfileMap(map)
  local result = {}
  for k, v in pairs(map) do
    tinsert(result, k)
  end

  sort(result, function(a, b)
    return map[a].elapsed > map[b].elapsed
  end)

  return result
end

local function TotalProfileTime(map)
  local total = 0
  for k, v in pairs(map) do
    total = total + v.elapsed
  end
  return total
end

function WeakAuras.PrintProfile()
  if (not profileData.systems.time) then
    prettyPrint(L["No Profiling information saved."])
    return
  end

  if (profileData.systems.time.count == 1) then
    prettyPrint(L["Profiling still running, stop before trying to print."])
    return
  end

  print("--------------------------------")
  prettyPrint(L["EXPERIMENTAL Profiling Data:"])
  PrintOneProfile("|cff9900FFTotal Time:|r", profileData.systems.time)
  PrintOneProfile("|cff9900FFTime inside WA:|r", profileData.systems.wa)
  print("|cff9900FF% Time spent inside WA:|r", string.format("%.2f", 100 * profileData.systems.wa.elapsed / profileData.systems.time.elapsed))
  print("")
  print("|cff9900FFSystems:|r")

  for i, k in ipairs(SortProfileMap(profileData.systems)) do
    if (k ~= "time" and k~= "wa") then
      PrintOneProfile(k, profileData.systems[k], profileData.systems.wa.elapsed)
    end
  end

  print("")
  print("|cff9900FFAuras:|r")
  local total = TotalProfileTime(profileData.auras)
  print("Total Time attributed to auras: ", floor(total) .."ms")
  for i, k in ipairs(SortProfileMap(profileData.auras)) do
    PrintOneProfile(k, profileData.auras[k], total)
  end
  print("--------------------------------")
end
