if not WeakAuras.IsLibsOK() then return end
if not WeakAuras.IsCataOrRetail() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

--- @class LibSpecialization
--- @field Register fun(self: LibSpecialization, name: string, callback: function)
--- @field MySpecialization fun(): number, string, string
local LibSpec = LibStub("LibSpecialization")

--- @alias specData {[1]: number, [2]: string, [3]: string, [4]: string}

--- @type table<string, specData>
local nameToSpecMap = {}

local nameToTalents = {}

--- @type table<string, string>
local nameToUnitMap = {
  [GetUnitName("player", true)] = "player"
}

--- @type function[]
local subscribers = {}

--- @class LibSpecWrapper
--- @field Register fun(callback: fun(unit: string))
--- @field SpecForUnit fun(unit: string): number?
--- @field SpecRolePositionForUnit fun(unit: string): number?, string?, string?
--- @field CheckTalentForUnit fun(unit: string, talentId: number): boolean?

Private.LibSpecWrapper = {
  Register = function(callback) end,
  SpecForUnit = function(unit) end,
  SpecRolePositionForUnit = function(unit) end,
  CheckTalentForUnit = function(unit) end,
}
if LibSpec then
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:RegisterEvent("GROUP_ROSTER_UPDATE")
  frame:SetScript("OnEvent", function()
    --- @type string
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

  --- LibSpecialization callback
  ---@param specId number
  ---@param role string
  ---@param position string
  ---@param sender string
  ---@param talentString string
  local function LibSpecCallback(specId, role, position, sender, talentString)
    if nameToSpecMap[sender]
       and nameToSpecMap[sender][1] == specId
       and nameToSpecMap[sender][2] == role
       and nameToSpecMap[sender][3] == position
       and nameToSpecMap[sender][4] == talentString
    then
      return
    end

    if not nameToUnitMap[sender] then
      return
    end

    nameToSpecMap[sender] = {specId, role, position, talentString}
    nameToTalents[sender] = nil
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
      return (LibSpec:MySpecialization())
    end

    if nameToSpecMap[GetUnitName(unit, true)] then
      return nameToSpecMap[GetUnitName(unit, true)][1]
    end
  end

  function Private.LibSpecWrapper.SpecRolePositionForUnit(unit)
    if UnitIsUnit(unit, "player") then
      return LibSpec:MySpecialization()
    end
    local data = nameToSpecMap[GetUnitName(unit, true)]
    if data then
      return unpack(data)
    else
      return nil
    end
  end

  local function ReadLoadoutHeader(importStream)
    local bitWidthHeaderVersion = 8
    local bitWidthSpecID = 16
    local headerBitWidth = bitWidthHeaderVersion + bitWidthSpecID + 128;

    local importStreamTotalBits = importStream:GetNumberOfBits();
    if( importStreamTotalBits < headerBitWidth) then
      return false, 0, 0, 0;
    end
    local serializationVersion = importStream:ExtractValue(bitWidthHeaderVersion);
    local specID = importStream:ExtractValue(bitWidthSpecID);

    -- treeHash is a 128bit hash, passed as an array of 16, 8-bit values
    local treeHash = {};
    for i=1,16,1 do
      treeHash[i] = importStream:ExtractValue(8);
    end
    return true, serializationVersion, specID, treeHash;
  end

  local validSerializationVersions = {
    [1] = true,
    [2] = true
  }

  function Private.LibSpecWrapper.CheckTalentForUnit(unit, talentId)
    if UnitIsUnit(unit, "player") then
      return select(4, WeakAuras.GetTalentById(talentId))
    end
    local unitName = GetUnitName(unit, true)
    if not nameToTalents[unitName] then
      -- Parse Talent String once and store which talents are selected
      if not nameToSpecMap[unitName] then return nil end
      local talentString = nameToSpecMap[unitName][4]
      if not talentString then return nil end

      local importStream = CreateAndInitFromMixin(ImportDataStreamMixin, talentString)
      local headerValid, serializationVersion, specID, treeHash = ReadLoadoutHeader(importStream);
      local currentSerializationVersion = C_Traits.GetLoadoutSerializationVersion();
      if(not headerValid) then
        return nil
      end
      if(serializationVersion ~= currentSerializationVersion or not validSerializationVersions[serializationVersion]) then
        return nil
      end

      local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)

      local results = {};
      local bitWidthRanksPurchased = 6

      local _, _, talentsData = Private.GetTalentData(specID)
      local treeNodes = C_Traits.GetTreeNodes(treeID);
      for _, nodeId in ipairs(treeNodes) do
        local nodeSelectedValue = importStream:ExtractValue(1)
        local isNodeSelected = nodeSelectedValue == 1
        local isPartiallyRanked = false
        local partialRanksPurchased = 0
        local isChoiceNode = false
        local choiceNodeSelection = 1

        if(isNodeSelected) then
          if serializationVersion == 2 then
            local nodePurchasedValue = importStream:ExtractValue(1)
            local isNodePurchased = nodePurchasedValue == 1
            if(isNodePurchased) then
              local isPartiallyRankedValue = importStream:ExtractValue(1)
              isPartiallyRanked = isPartiallyRankedValue == 1
              if(isPartiallyRanked) then
                partialRanksPurchased = importStream:ExtractValue(bitWidthRanksPurchased)
              end
              local isChoiceNodeValue = importStream:ExtractValue(1)
              isChoiceNode = isChoiceNodeValue == 1
              if(isChoiceNode) then
                choiceNodeSelection = importStream:ExtractValue(2) + 1
              end
            end
          else
            local isPartiallyRankedValue = importStream:ExtractValue(1)
            isPartiallyRanked = isPartiallyRankedValue == 1
            if(isPartiallyRanked) then
              partialRanksPurchased = importStream:ExtractValue(bitWidthRanksPurchased)
            end
            local isChoiceNodeValue = importStream:ExtractValue(1)
            isChoiceNode = isChoiceNodeValue == 1
            if(isChoiceNode) then
              choiceNodeSelection = importStream:ExtractValue(2) + 1
            end
          end
        end

        local talentData = talentsData and talentsData[nodeId] and talentsData[nodeId][choiceNodeSelection]
        if talentData then
          if isPartiallyRanked then
            results[talentData[1]] = partialRanksPurchased
          else
            results[talentData[1]] = nodeSelectedValue == 1 and talentData[5] or 0
          end
        end
        if isChoiceNode then
          local unselectedChoiceNodeIdx = choiceNodeSelection == 1 and 2 or 1
          local unselectedTalentData = talentsData and talentsData[nodeId] and talentsData[nodeId][unselectedChoiceNodeIdx]
          if unselectedTalentData then
            results[unselectedTalentData[1]] = 0
          end
        end
      end
      nameToTalents[unitName] = results
    end

    if nameToTalents[unitName] then
      return nameToTalents[unitName][talentId]
    end
  end
else -- non retail
  function Private.LibSpecWrapper.Register(f)

  end

  function Private.LibSpecWrapper.SpecForUnit(unit)
    return nil
  end

  function Private.LibSpecWrapper.SpecRolePositionForUnit(unit)
    return nil
  end

  function Private.LibSpecWrapper.CheckTalentForUnit(unit)
    return nil
  end
end

-- Export for GenericTrigger
WeakAuras.SpecForUnit = Private.LibSpecWrapper.SpecForUnit
WeakAuras.SpecRolePositionForUnit = Private.LibSpecWrapper.SpecRolePositionForUnit
WeakAuras.CheckTalentForUnit = Private.LibSpecWrapper.CheckTalentForUnit
