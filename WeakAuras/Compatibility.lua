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
