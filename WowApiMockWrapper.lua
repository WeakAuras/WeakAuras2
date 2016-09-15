
require("Utility/Mocks")

WowApiMock = {}
WowApiMock.__index = WowApiMock

function WowApiMock:initialize()
    WowApiMock:CreateMockedMethods()
end

WowApiMock.MockedMethods = {}
WowApiMock.BackingProperties = {}
WowApiMock.BackingProperties.Values = {}
WowApiMock.MockedConstants = {}
WowApiMock.ConstantDefaults = {}

function ResetMocks()
    for index, property in ipairs(WowApiMock.BackingProperties.Values) do
        WowApiMock.BackingProperties.Values[property] = nil
    end

    for key, value in pairs(WowApiMock.ConstantDefaults) do
        _G[key] = value
    end
end

function WowApiMock:CreateMockedMethods()
    MockMethodPartial("GetTalentInfo", "TODO: Mock TalentInfo")
    MockMethodPartial("GetPvpTalentInfo", "TODO: Mock PvpTalentInfo")
    
    -- Commented lines here indicate that there's something different about these
    -- that needs more attention.
    MockMethodPartial("IsAddOnLoaded", 1)
    MockMethodPartial("InCombatLockdown", nil)
    MockMethodPartial("LoadAddOn", {1, nil})
    MockMethodPartial("setfenv", "TODO: Mock setfenv")
    MockMethodPartial("UnitName", "EvilBoss")
    MockMethodPartial("GetRealmName", "Bonechewer")
    MockMethodPartial("GetRealZoneText", "Azshara")
    MockMethodPartial("GetCurrentMapAreaID", 1234)
    MockMethodPartial("UnitGroupRoleAssigned", "DAMAGE")
    MockMethodPartial("UnitRace", "Gnome")
    MockMethodPartial("UnitFactionGroup", "Alliance")
    MockMethodPartial("IsInRaid", true)
    MockMethodPartial("UnitClass", {"Mage", "MAGE", 8})
    MockMethodPartial("UnitExists", 1)
    MockMethodPartial("UnitGUID", "0xF530007EAC083004")
    MockMethodPartial("UnitAffectingCombat", 1)
    MockMethodPartial("GetSpecialization", 1234)
    MockMethodPartial("GetActiveSpecGroup", 1234)
    MockMethodPartial("GetInstanceInfo", {"The Emerald Nightmare", "raid", 10, "10-30 Player Heroic", 10, 0, true, 1234, 11})
    MockMethodPartial("IsInInstance", {true, "raid"})
    MockMethodPartial("GetNumGroupMembers", 11)
    MockMethodPartial("UnitIsUnit", true)
    MockMethodPartial("GetRaidRosterInfo", {"Guildmate", 2, 1, 110, "Mage", "MAGE", "The Emerald Nightmare", 1, nil, "MAINTANK", 1})
    MockMethodPartial("GetSpecialization", 1)
    MockMethodPartial("GetSpecializationRole", "TODO: Mock GetSpecializationRole")
    MockMethodPartial("UnitInVehicle", nil)
    MockMethodPartial("UnitHasVehicleUI", false)
    MockMethodPartial("GetSpellInfo", {"Fireball", "Rank 5", "SOME_ICON_PATH", 1500, 0, 40, 1234})
    MockMethodPartial("SendChatMessage", nil)
    MockMethodPartial("GetChannelName", {1234, "The Emerald Nightmare - General", 0})
    MockMethodPartial("UnitInBattleground", 13)
    MockMethodPartial("UnitInRaid", 1)
    MockMethodPartial("UnitInParty", 1)
    MockMethodPartial("PlaySoundFile", nil)
    --MockMethodPartial("PlaySoundKitID", "TODO: Mock PlaySoundKitID")
    MockMethodPartial("GetTime", 123456789)
    --MockMethodPartial("GetSpellLink", "TODO: Mock GetSpellLink")
    --MockMethodPartial("GetItemInfo", "TODO: Mock GetItemInfo")
    --MockMethodPartial("CreateFrame", "TODO: Mock CreateFrame")
    MockMethodPartial("IsShiftKeyDown", nil)
    MockMethodPartial("GetScreenWidth", 1024)
    MockMethodPartial("GetScreenHeight", 768)
    MockMethodPartial("GetCursorPosition", {600, 600})
    --MockMethodPartial("random", "TODO: Mock random")
    MockMethodPartial("UpdateAddOnCPUUsage", nil)
    MockMethodPartial("GetFrameCPUUsage", {100, 20})
    MockMethodPartial("debugprofilestop", 100)
    MockMethodPartial("debugstack", "FAKE_DEBUG_STACK")
    MockMethodPartial("IsSpellKnown", true)
    MockMethodPartial("GetAddOnEnableState", 2)
    --MockMethodPartial("IsPlayerMoving", "TODO: Mock IsPlayerMoving")
    MockMethodPartial("UnitIsDead", nil)

    MockConstant("MAX_TALENT_TIERS", 6)
    MockConstant("MAX_TALENT_COLUMNS", 3)

    MockConstant("MAX_PVP_TALENT_TIERS", 6)
    MockConstant("MAX_PVP_TALENT_COLUMNS", 3)
end

local mock1 = WowApiMock:initialize()
--TESTING When the mocked value is a function, its called appropriately.
local func = function(input) 
    if input == "IsMatch" then 
        return "Success"
    else 
        return "Failure"
    end
end

local talentInfoTemp = "TODO: Mock TalentInfo"
assert(GetTalentInfo("IsMatch") == talentInfoTemp, "FAIL")
assert(GetTalentInfo("IsNotMatch") == talentInfoTemp, "FAIL")


MockGetTalentInfo(func)
assert(GetTalentInfo("IsMatch") == "Success", "FAIL")
assert(GetTalentInfo("IsNotMatch") == "Failure", "FAIL")

--TESTING When the mock has multiple return values, we get them all.
MockLoadAddOn({1,"Successful Load"})
local success, reason = LoadAddOn("WeakAuras2")
assert(success == 1, "FAIL")
assert(reason == "Successful Load")

--TESTING When the mock return nil as one of its multiple return values, we get them all.
MockLoadAddOn({nil,"Failed Load"})
local success, reason = LoadAddOn("WeakAuras2")
assert(success == nil, "FAIL")
assert(reason == "Failed Load")

--TESTING Assigning functions on the wrapper to local variables.
local wrapperFunction = IsShiftKeyDown
MockIsShiftKeyDown(true)
local shiftIsDown = wrapperFunction()
assert(shiftIsDown == true, "FAIL")

--TESTING Reset functionality.
MockIsShiftKeyDown(true)
shiftIsDown = IsShiftKeyDown()
assert(shiftIsDown == true, "FAIL")
ResetMocks()
shiftIsDown = IsShiftKeyDown()
assert(shiftIsDown == nil, "FAIL")

--TESTING Mocking constants works.
local maxTiersOriginal = MAX_TALENT_TIERS
assert(maxTiersOriginal == 6, "FAIL")

MockMAX_TALENT_TIERS(100)
local maxTiersMocked = MAX_TALENT_TIERS
assert(maxTiersMocked == 100, "FAIL")
assert(maxTiersMocked ~= maxTiersOriginal, "FAIL")

ResetMocks()

local resetMaxTiers = MAX_TALENT_TIERS
assert(resetMaxTiers == maxTiersOriginal, "FAIL")