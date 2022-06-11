if not WeakAuras.IsLibsOK() then return end
if not WeakAuras.IsRetail() then return end
local AddonName, Private = ...

local LibSpec = LibStub("LibSpecialization")

local nameToSpecMap = {}
local nameToUnitMap = {
  [GetUnitName("player", true)] = "player"
}

local subscribers = {}

Private.LibSpecWrapper = {}
if LibSpec then
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:RegisterEvent("GROUP_ROSTER_UPDATE")
  frame:SetScript("OnEvent", function()
    local ownName = GetUnitName("player", true)

    nameToUnitMap = {}
    nameToUnitMap[ownName] = "player"

    if IsInRaid() then
      local max = GetNumGroupMembers()
      for i = 1, max do
        local name = GetUnitName(WeakAuras.raidUnits[i], true)
        nameToUnitMap[name] = WeakAuras.raidUnits[i]
      end
    else
      local max = GetNumSubgroupMembers()
      for i = 1, max do
        local name = GetUnitName(WeakAuras.partyUnits[i], true)
        nameToUnitMap[name] = WeakAuras.partyUnits[i]
      end
    end

    for name in pairs(nameToSpecMap) do
      if not nameToUnitMap[name] then
        nameToSpecMap[name] = nil
      end
    end
  end)

  local function LibSpecCallback(specId, role, position, sender, channel)
    if nameToSpecMap[sender] == specId then
      return
    end

    if not nameToUnitMap[sender] then
      return
    end

    nameToSpecMap[sender] = specId
    for _, f in ipairs(subscribers) do
      f(nameToUnitMap[sender])
    end
  end

  LibSpec:Register("WeakAuras", LibSpecCallback)

  function Private.LibSpecWrapper.Register(f)
    tinsert(subscribers, f)
  end

  function Private.LibSpecWrapper.SpecForUnit(unit)
    if UnitIsUnit(unit, "player") then
      return LibSpec:MySpecialization()
    end

    return nameToSpecMap[GetUnitName(unit, true)]
  end
else -- non retail
  function Private.LibSpecWrapper.Register(f)

  end

  function Private.LibSpecWrapper.SpecForUnit(unit)
    return nil
  end
end

-- Export for GenericTrigger
WeakAuras.SpecForUnit = Private.LibSpecWrapper.SpecForUnit
