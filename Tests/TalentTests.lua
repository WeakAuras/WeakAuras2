package.path = package.path .. ";../?.lua;?.lua;Tests/?.lua"

require("TestHelper")
require("WeakAurasTalents")
require("WowApiMockWrapper")

TalentTests = {}

function TalentTests.GetPvxTalentConfiguration_ForPve_ReturnsCorrectData()
    local cache = WeakAurasTalentCache:create("PVE")
    assert(cache.MaxTiers == MAX_TALENT_TIERS, "The PVE talent configuration returned the wrong number of talent tiers.")
    assert(cache.MaxColumns == MAX_TALENT_COLUMNS, "The PVE talent configuration returned the wrong number of talent columns.")
    assert(cache.GetTalentInfo == GetTalentInfo, "The PVE talent configuration returned the wrong 'GetTalentInfo' function.")
end

function TalentTests.GetPvxTalentConfiguration_ForPvp_ReturnsCorrectData()
    local cache = WeakAurasTalentCache:create("PVP")
    assert(cache.MaxTiers == MAX_TALENT_TIERS, "The PVP talent configuration returned the wrong number of talent tiers.")
    assert(cache.MaxColumns == MAX_TALENT_COLUMNS, "The PVP talent configuration returned the wrong number of talent columns.")
    assert(cache.GetTalentInfo == GetPvpTalentInfo, "The PVP talent configuration returned the wrong 'GetTalentInfo' function.")
end

function TalentTests.TalentCacheIsNotCreatedIfAlreadyExists()
    local cache = WeakAurasTalentCache:create("PVE")
    cache:Initialize()
    local talentCache = cache:GetTalentCacheForClassAndSpec()
    assert(talentCache ~= nil, "The returned talent cache was nil.")

    local secondTalentCache = cache:GetTalentCacheForClassAndSpec()
    assert(talentCache == secondTalentCache, "A talent cache that already existed was recreated.")
end

function TalentTests.TalentCacheMaintainsSeparationBetweenPveAndPvp()
    local pveCache = WeakAurasTalentCache:create("PVE")
    pveCache:Initialize()
    local pveTalentCache = pveCache:GetTalentCacheForClassAndSpec()
    assert(pveTalentCache ~= nil, "The returned PVE talent cache was nil.")

    local pvpCache = WeakAurasTalentCache:create("PVP")
    pvpCache:Initialize()
    local pvpTalentCache = pvpCache:GetTalentCacheForClassAndSpec()
    assert(pvpTalentCache ~= nil, "The returned PVE talent cache was nil.")

    assert(pveTalentCache ~= pvpTalentCache, "The same talent cache was returned for both PVE and PVP")
end

function TalentTests.X_TestTalentCaching(tierCount, columnCount)
    -- Every talent will return the same information.
    -- We're just testing that we stored it all.
    MockGetTalentInfo({"TalentID", "TalentName", "TalentIcon"})
    MockMAX_TALENT_TIERS(tierCount)
    MockMAX_TALENT_COLUMNS(columnCount)

    local pveCache = WeakAurasTalentCache:create("PVE")
    pveCache:Initialize()

    local talentCache = pveCache:GetTalentCacheForClassAndSpec()
    local numTalents = #talentCache
    local expectedNumTalents = MAX_TALENT_TIERS * MAX_TALENT_COLUMNS
    
    assert(numTalents == expectedNumTalents, "The talent cache did not capture the correct number of talents when using " .. MAX_TALENT_TIERS .. " tiers and " .. MAX_TALENT_COLUMNS .. " columns. Got " .. numTalents .. " but expected " .. expectedNumTalents)
end

function TalentTests.WhenFillingTalentCacheGetsAllTalents_For6Tiers3Columns()
    TalentTests.X_TestTalentCaching(6,3)
end

function TalentTests.WhenFillingTalentCacheGetsAllTalents_For6Tiers4Columns()
    TalentTests.X_TestTalentCaching(6,4)
end

function TalentTests.WhenFillingTalentCacheGetsAllTalents_For6Tiers2Columns()
    TalentTests.X_TestTalentCaching(6,2)
end

RunAllTests(TalentTests)
