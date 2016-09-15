package.path = package.path .. ";../?.lua;?.lua;Tests/?.lua"

require("TestHelper")
require("WeakAurasTalents")
require("WowApiMockWrapper")

TalentTests = {}

function TalentTests.GetPvxTalentConfiguration_ForPve_ReturnsCorrectData()
    local maxTiers, maxColumns, talentInfoFunc = WeakAuras.GetPvxTalentConfiguration("PVE")
    assert(maxTiers == MAX_TALENT_TIERS, "The PVE talent configuration returned the wrong number of talent tiers.")
    assert(maxColumns == MAX_TALENT_COLUMNS, "The PVE talent configuration returned the wrong number of talent columns.")
    assert(talentInfoFunc == GetTalentInfo, "The PVE talent configuration returned the wrong 'GetTalentInfo' function.")
end

function TalentTests.GetPvxTalentConfiguration_ForPvp_ReturnsCorrectData()
    local maxTiers, maxColumns, talentInfoFunc = WeakAuras.GetPvxTalentConfiguration("PVP")
    assert(maxTiers == MAX_PVP_TALENT_TIERS, "The PVE talent configuration returned the wrong number of talent tiers.")
    assert(maxColumns == MAX_PVP_TALENT_COLUMNS, "The PVE talent configuration returned the wrong number of talent columns.")
    assert(talentInfoFunc == GetPvpTalentInfo, "The PVE talent configuration returned the wrong 'GetTalentInfo' function.")
end

function TalentTests.TalentCacheIsNotCreatedIfAlreadyExists()
    local talentCache = WeakAuras.GetTalentCacheForClassAndSpec("PVE")
    assert(talentCache ~= nil, "The returned talent cache was nil.")

    local secondTalentCache = WeakAuras.GetTalentCacheForClassAndSpec("PVE")
    assert(talentCache == secondTalentCache, "A talent cache that already existed was recreated.")
end

function TalentTests.TalentCacheMaintainsSeparationBetweenPveAndPvp()
    local pveTalentCache = WeakAuras.GetTalentCacheForClassAndSpec("PVE")
    assert(pveTalentCache ~= nil, "The returned PVE talent cache was nil.")

    local pvpTalentCache = WeakAuras.GetTalentCacheForClassAndSpec("PVP")
    assert(pvpTalentCache ~= nil, "The returned PVE talent cache was nil.")

    assert(pveTalentCache ~= pvpTalentCache, "The same talent cache was returned for both PVE and PVP")
end

function TalentTests.X_TestTalentCaching(tierCount, columnCount)
    -- We have to reset the state so that the tests don't affect each other.
    -- This is a symptom that WeakAuras should potentially be encapsulated
    -- so that we can make one any time we want and changes to it
    -- dont affect other tests.
    WeakAuras.ClearTalentSpecTalentCache("PVE")

    MockGetTalentInfo({"TalentID", "TalentName", "TalentIcon"})
    MockMAX_TALENT_TIERS(tierCount)
    MockMAX_TALENT_COLUMNS(columnCount)
    WeakAuras.FillPvxTalentCache("PVE")

    local talentCache = WeakAuras.GetTalentCacheForClassAndSpec("PVE")
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
