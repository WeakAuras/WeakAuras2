
require("Utility/Mocks")

WowApiMock = {}
WowApiMock.__index = WowApiMock

function WowApiMock:create()
    local wrapper = {}
    setmetatable(wrapper, WowApiMock)

    WowApiMock:CreateMockedMethods(wrapper)

    return wrapper
end

function WowApiMock:CreateMockedMethods(wrapper)
    MockMethodPartial(wrapper, "GetTalentInfo", "TODO: Mock TalentInfo")
    MockMethodPartial(wrapper, "GetPvpTalentInfo", "TODO: Mock PvpTalentInfo")
    
    -- Commented lines here indicate that there's something different about these
    -- that needs more attention.
    MockMethodPartial(wrapper, "IsAddOnLoaded", 1)
    MockMethodPartial(wrapper, "InCombatLockdown", nil)
    MockMethodPartial(wrapper, "LoadAddOn", {1, nil})
    MockMethodPartial(wrapper, "setfenv", "TODO: Mock setfenv")
    MockMethodPartial(wrapper, "UnitName", "EvilBoss")
    MockMethodPartial(wrapper, "GetRealmName", "Bonechewer")
    MockMethodPartial(wrapper, "GetRealZoneText", "Azshara")
    MockMethodPartial(wrapper, "GetCurrentMapAreaID", 1234)
    MockMethodPartial(wrapper, "UnitGroupRoleAssigned", "DAMAGE")
    MockMethodPartial(wrapper, "UnitRace", "Gnome")
    MockMethodPartial(wrapper, "UnitFactionGroup", "Alliance")
    MockMethodPartial(wrapper, "IsInRaid", true)
    MockMethodPartial(wrapper, "UnitClass", {"Mage", "MAGE", 8})
    MockMethodPartial(wrapper, "UnitExists", 1)
    MockMethodPartial(wrapper, "UnitGUID", "0xF530007EAC083004")
    MockMethodPartial(wrapper, "UnitAffectingCombat", 1)
    MockMethodPartial(wrapper, "GetSpecialization", 1234)
    MockMethodPartial(wrapper, "GetActiveSpecGroup", 1234)
    MockMethodPartial(wrapper, "GetInstanceInfo", {"The Emerald Nightmare", "raid", 10, "10-30 Player Heroic", 10, 0, true, 1234, 11})
    MockMethodPartial(wrapper, "IsInInstance", {true, "raid"})
    MockMethodPartial(wrapper, "GetNumGroupMembers", 11)
    MockMethodPartial(wrapper, "UnitIsUnit", true)
    MockMethodPartial(wrapper, "GetRaidRosterInfo", {"Guildmate", 2, 1, 110, "Mage", "MAGE", "The Emerald Nightmare", 1, nil, "MAINTANK", 1})
    MockMethodPartial(wrapper, "GetSpecialization", 1)
    MockMethodPartial(wrapper, "GetSpecializationRole", "TODO: Mock GetSpecializationRole")
    MockMethodPartial(wrapper, "UnitInVehicle", nil)
    MockMethodPartial(wrapper, "UnitHasVehicleUI", false)
    MockMethodPartial(wrapper, "GetSpellInfo", {"Fireball", "Rank 5", "SOME_ICON_PATH", 1500, 0, 40, 1234})
    MockMethodPartial(wrapper, "SendChatMessage", nil)
    MockMethodPartial(wrapper, "GetChannelName", {1234, "The Emerald Nightmare - General", 0})
    MockMethodPartial(wrapper, "UnitInBattleground", 13)
    MockMethodPartial(wrapper, "UnitInRaid", 1)
    MockMethodPartial(wrapper, "UnitInParty", 1)
    MockMethodPartial(wrapper, "PlaySoundFile", nil)
    --MockMethodPartial(wrapper, "PlaySoundKitID", "TODO: Mock PlaySoundKitID")
    MockMethodPartial(wrapper, "GetTime", 123456789)
    --MockMethodPartial(wrapper, "GetSpellLink", "TODO: Mock GetSpellLink")
    --MockMethodPartial(wrapper, "GetItemInfo", "TODO: Mock GetItemInfo")
    --MockMethodPartial(wrapper, "CreateFrame", "TODO: Mock CreateFrame")
    MockMethodPartial(wrapper, "IsShiftKeyDown", nil)
    MockMethodPartial(wrapper, "GetScreenWidth", 1024)
    MockMethodPartial(wrapper, "GetScreenHeight", 768)
    MockMethodPartial(wrapper, "GetCursorPosition", {600, 600})
    --MockMethodPartial(wrapper, "random", "TODO: Mock random")
    MockMethodPartial(wrapper, "UpdateAddOnCPUUsage", nil)
    MockMethodPartial(wrapper, "GetFrameCPUUsage", {100, 20})
    MockMethodPartial(wrapper, "debugprofilestop", 100)
    MockMethodPartial(wrapper, "debugstack", "FAKE_DEBUG_STACK")
    MockMethodPartial(wrapper, "IsSpellKnown", true)
end

-- TESTING When we change the mock on one instance it doesn't affect others.
local mock1 = WowApiMock.create()
local mock2 = WowApiMock.create()
local talentInfoTemp = "TODO: Mock TalentInfo"
assert(mock1.GetTalentInfo() == talentInfoTemp, "FAIL")
assert(mock2.GetTalentInfo() == talentInfoTemp, "FAIL")

local talentInfoMocked = "New Talent Info"
mock1.MockGetTalentInfo(talentInfoMocked)
assert(mock1.GetTalentInfo() == talentInfoMocked, "FAIL")
assert(mock2.GetTalentInfo() == talentInfoTemp, "FAIL")

--TESTING When the mocked value is a function, its called appropriately.
local func = function(input) 
    if input == "IsMatch" then 
        return "Success"
    else 
        return "Failure"
    end
end

local mock3 = WowApiMock.create()
assert(mock3.GetTalentInfo("IsMatch") == talentInfoTemp, "FAIL")
assert(mock3.GetTalentInfo("IsNotMatch") == talentInfoTemp, "FAIL")

mock3.MockGetTalentInfo(func)

assert(mock3.GetTalentInfo("IsMatch") == "Success", "FAIL")
assert(mock3.GetTalentInfo("IsNotMatch") == "Failure", "FAIL")

--TESTING When the mock has multiple return values, we get them all.
mock1.MockLoadAddOn({1,"Successful Load"})
local success, reason = mock1.LoadAddOn("WeakAuras2")
assert(success == 1, "FAIL")
assert(reason == "Successful Load")

--TESTING When the mock return nil as one of its multiple return values, we get them all.
mock1.MockLoadAddOn({nil,"Failed Load"})
local success, reason = mock1.LoadAddOn("WeakAuras2")
assert(success == nil, "FAIL")
assert(reason == "Failed Load")

--TESTING Assigning functions on the wrapper to local variables.
local wrapperFunction = mock1.IsShiftKeyDown
mock1.MockIsShiftKeyDown(true)
local shiftIsDown = wrapperFunction()
assert(shiftIsDown == true, "FAIL")
