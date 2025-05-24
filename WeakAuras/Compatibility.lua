-- This file is only for base functions that work differently or are deprecated in some versions of wow

if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

if GetSpellInfo then
  Private.ExecEnv.GetSpellInfo = GetSpellInfo
  Private.ExecEnv.GetSpellName = GetSpellInfo
else
  Private.ExecEnv.GetSpellInfo = function(spellID)
    if not spellID then
      return nil
    end
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
      return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
    end
  end
  Private.ExecEnv.GetSpellName = C_Spell.GetSpellName
end

if GetSpellTexture then
  Private.ExecEnv.GetSpellIcon = GetSpellTexture
else
  Private.ExecEnv.GetSpellIcon = C_Spell.GetSpellTexture
end

if IsUsableSpell then
  Private.ExecEnv.IsUsableSpell = IsUsableSpell
else
  Private.ExecEnv.IsUsableSpell = C_Spell.IsSpellUsable
end

if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
  Private.ExecEnv.GetSpecialization = C_SpecializationInfo.GetSpecialization
else
  Private.ExecEnv.GetSpecialization = GetSpecialization
end
if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
  Private.ExecEnv.GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
else
  Private.ExecEnv.GetSpecializationInfo = GetSpecializationInfo
end
if C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID then
  Private.ExecEnv.GetNumSpecializationsForClassID = C_SpecializationInfo.GetNumSpecializationsForClassID
else
  Private.ExecEnv.GetNumSpecializationsForClassID = GetNumSpecializationsForClassID
end
if WeakAuras.IsMists() then
  local specsByClassID = {
    [0] = { 74, 81, 79 },
    [1] = { 71, 72, 73, 1446 },
    [2] = { 65, 66, 70, 1451 },
    [3] = { 253, 254, 255, 1448 },
    [4] = { 259, 260, 261, 1453 },
    [5] = { 256, 257, 258, 1452 },
    [6] = { 250, 251, 252, 1455 },
    [7] = { 262, 263, 264, 1444 },
    [8] = { 62, 63, 64, 1449 },
    [9] = { 265, 266, 267, 1454 },
    [10] = { 268, 270, 269, 1450 },
    [11] = { 102, 103, 104, 105, 1447 },
  }
  Private.ExecEnv.GetSpecializationInfoForClassID = function (classID, specIndex)
    local specID = specsByClassID[classID][specIndex]
    if not specID then
      return nil
    end
    return GetSpecializationInfoByID(specID)
  end
else
  Private.ExecEnv.GetSpecializationInfoForClassID = GetSpecializationInfoForClassID
end

if C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo then
  -- copy pasta from Interface/AddOns/Blizzard_DeprecatedSpecialization/Deprecated_Specialization_Mists.lua
  Private.ExecEnv.GetTalentInfo = function(tabIndex, talentIndex, isInspect, isPet, groupIndex)
		-- Note: tabIndex, talentIndex, and isPet are not supported parameters in 5.5.x and onward.
		local numColumns = 3
		local talentInfoQuery = {}
		talentInfoQuery.tier = math.ceil(talentIndex / numColumns)
		talentInfoQuery.column = talentIndex % numColumns
		talentInfoQuery.groupIndex = groupIndex
		talentInfoQuery.isInspect = isInspect
		talentInfoQuery.target = nil
		local talentInfo = C_SpecializationInfo.GetTalentInfo(talentInfoQuery)
		if not talentInfo then
			return nil
		end

		-- Note: rank, maxRank, meetsPrereq, previewRank, meetsPreviewPrereq, isExceptional, and hasGoldBorder are not supported outputs in 5.5.x and onward.
		-- They have default values not reflective of actual system state.
		-- selected, available, spellID, isPVPTalentUnlocked, known, and grantedByAura are new supported outputs in 5.5.x and onward.
		return talentInfo.name, talentInfo.icon, talentInfo.tier, talentInfo.column, talentInfo.selected and talentInfo.rank or 0,
			talentInfo.maxRank, talentInfo.meetsPrereq, talentInfo.previewRank,
			talentInfo.meetsPreviewPrereq, talentInfo.isExceptional, talentInfo.hasGoldBorder,
			talentInfo.talentID
	end
else
  Private.ExecEnv.GetTalentInfo = GetTalentInfo
end

Private.ExecEnv.GetNumFactions = C_Reputation.GetNumFactions or GetNumFactions

Private.ExecEnv.GetFactionDataByIndex = C_Reputation.GetFactionDataByIndex or function(index)
  local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canSetInactive = GetFactionInfo(index)
  return {
    factionID = factionID,
    name = name,
    description = description,
    reaction = standingID,
    currentReactionThreshold = barMin,
    nextReactionThreshold = barMax,
    currentStanding = barValue,
    atWarWith = atWarWith,
    canToggleAtWar = canToggleAtWar,
    isChild = isChild,
    isHeader = isHeader,
    isHeaderWithRep = hasRep,
    isCollapsed = isCollapsed,
    isWatched = isWatched,
    hasBonusRepGain = hasBonusRepGain,
    canSetInactive = canSetInactive,
    isAccountWide = nil
  }
end

Private.ExecEnv.GetFactionDataByID = C_Reputation.GetFactionDataByID or function(ID)
  local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canSetInactive = GetFactionInfoByID(ID)
  return {
    factionID = factionID,
    name = name,
    description = description,
    reaction = standingID,
    currentReactionThreshold = barMin,
    nextReactionThreshold = barMax,
    currentStanding = barValue,
    atWarWith = atWarWith,
    canToggleAtWar = canToggleAtWar,
    isChild = isChild,
    isHeader = isHeader,
    isHeaderWithRep = hasRep,
    isCollapsed = isCollapsed,
    isWatched = isWatched,
    hasBonusRepGain = hasBonusRepGain,
    canSetInactive = canSetInactive,
    isAccountWide = nil
  }
end

-- GetWatchedFactionData behaves differentlly, but we only need the Id, so do a trival wrapper
if C_Reputation.GetWatchedFactionData then
  Private.ExecEnv.GetWatchedFactionId = function()
    local data = C_Reputation.GetWatchedFactionData()
    return data and data.factionID or nil
  end
else
  Private.ExecEnv.GetWatchedFactionId = function()
    return select(6, GetWatchedFactionInfo())
  end
end

Private.ExecEnv.ExpandFactionHeader = C_Reputation.ExpandFactionHeader or ExpandFactionHeader
Private.ExecEnv.CollapseFactionHeader = C_Reputation.CollapseFactionHeader or CollapseFactionHeader
Private.ExecEnv.AreLegacyReputationsShown = C_Reputation.AreLegacyReputationsShown or function() return true end
Private.ExecEnv.GetReputationSortType = C_Reputation.GetReputationSortType or function() return 0 end;
