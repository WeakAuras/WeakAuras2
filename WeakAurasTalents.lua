WeakAuras = WeakAuras or {}
WeakAuras.talent_types_specific = {}
WeakAuras.pvp_talent_types_specific = {}

function WeakAuras.CreateTalentCache()
  WeakAuras.FillPvxTalentCache("PVP")
  WeakAuras.FillPvxTalentCache("PVE")
end

function WeakAuras.FillPvxTalentCache(talentType)
  local talentCache = WeakAuras.GetTalentCacheForClassAndSpec(talentType)

  local maxTiers, maxColumns, talentInfoFunc = WeakAuras.GetPvxTalentConfiguration(talentType)
  local activeSpecGroup = GetActiveSpecGroup()
  for tier = 1, maxTiers do
    for column = 1, maxColumns do
      local _, talentName, talentIcon = talentInfoFunc(tier, column, activeSpecGroup);
      local talentId = (tier-1)*maxColumns+column
      if (talentName and talentIcon) then
        talentCache[talentId] = "|T"..talentIcon..":0|t "..talentName
      end
    end
  end
end

function WeakAuras.GetTalentCacheForClassAndSpec(pvx)
  local baseTable

  if pvx == "PVE" then
    baseTable = WeakAuras.talent_types_specific
  elseif pvx == "PVP" then
    baseTable = WeakAuras.pvp_talent_types_specific
  else
    error("WeakAuras.GetTalentCacheForClassAndSpec was called with an invalid value. Valid values are 'PVE' or 'PVP'")
  end

  local _, player_class = UnitClass("player")
  baseTable[player_class] = baseTable[player_class] or {};

  local spec = GetSpecialization()
  baseTable[player_class][spec] = baseTable[player_class][spec] or {};

  return baseTable[player_class][spec]
end

function WeakAuras.GetPvxTalentConfiguration(pvx)
  if pvx == "PVE" then
    return MAX_TALENT_TIERS, MAX_TALENT_COLUMNS, GetTalentInfo
  elseif pvx == "PVP" then
    return MAX_PVP_TALENT_TIERS, MAX_PVP_TALENT_COLUMNS, GetPvpTalentInfo
  else
    error("WeakAuras.GetPvxTalentConfiguration was called with an invalid value. Valid values are 'PVE' or 'PVP'")
  end
end

function WeakAuras.ClearTalentSpecTalentCache(pvx)
  local talentCache = WeakAuras.GetTalentCacheForClassAndSpec(pvx)

  for key, value in pairs(talentCache) do
    talentCache[key] = nil
  end
end