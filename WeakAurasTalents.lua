WeakAuras = WeakAuras or {}
WeakAuras.talent_types_specific = {}
WeakAuras.pvp_talent_types_specific = {}

WeakAurasTalentCache = {}
WeakAurasTalentCache.__index = WeakAurasTalentCache

function WeakAurasTalentCache:create(cacheType)
    local cache = {}
    setmetatable(cache, WeakAurasTalentCache)

    if cacheType == "PVE" then
      cache.GetTalentInfo = GetTalentInfo
      cache.MaxColumns = MAX_TALENT_COLUMNS
      cache.MaxTiers = MAX_TALENT_TIERS
    elseif cacheType == "PVP" then
      cache.GetTalentInfo = GetPvpTalentInfo
      cache.MaxColumns = MAX_PVP_TALENT_COLUMNS
      cache.MaxTiers = MAX_PVP_TALENT_TIERS
    else
      error("Talent caches are only available for PVE or PVP talents.")
    end

    cache.Classes = {}

    return cache
end

function WeakAurasTalentCache:Initialize()
  self:GetTalentCacheForClassAndSpec()
  self:FillTalentCache()
  return self.Classes
end

function WeakAurasTalentCache:FillTalentCache()
  local talentCache = self:GetTalentCacheForClassAndSpec()
  local maxTiers = self.MaxTiers
  local maxColumns = self.MaxColumns
  local GetTalentInfo = self.GetTalentInfo

  local activeSpecGroup = GetActiveSpecGroup()
  for tier = 1, maxTiers do
    for column = 1, maxColumns do
      local _, talentName, talentIcon = GetTalentInfo(tier, column, activeSpecGroup);
      -- TODO: This code starts to break if the number of columns approaches 6.
      -- Instead of using 3, use maxColumns
      local talentId = (tier-1)*maxColumns+column
      if (talentName and talentIcon) then
        talentCache[talentId] = "|T"..talentIcon..":0|t "..talentName
      end
    end
  end
end

function WeakAurasTalentCache:GetTalentCacheForClassAndSpec()
  local _, player_class = UnitClass("player")
  local cache = self.Classes
  cache[player_class] = cache[player_class] or {};

  local spec = GetSpecialization()
  cache[player_class][spec] = cache[player_class][spec] or {};

  return cache[player_class][spec]
end

function WeakAurasTalentCache:Clear()
    for key, value in pairs(self.Classes) do
    self[key] = nil
  end
end