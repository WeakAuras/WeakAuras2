
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
    MockMethodPartial(wrapper, "IsAddOnLoaded", true)
    MockMethodPartial(wrapper, "InCombatLockdown", nil)
    MockMethodPartial(wrapper, "LoadAddOn", "TODO: Mock LoadAddOn")
    MockMethodPartial(wrapper, "setfenv", "TODO: Mock setfenv")
    MockMethodPartial(wrapper, "UnitName", "Weaki")
    MockMethodPartial(wrapper, "GetRealmName", "TODO: Mock RealmName")
    MockMethodPartial(wrapper, "GetRealZoneText", "TODO: Mock RealZoneText")
    MockMethodPartial(wrapper, "GetCurrentMapAreaID", "TODO: Mock CurrentMapAreaID")
    MockMethodPartial(wrapper, "UnitGroupRoleAssigned", "TODO: Mock UnitGroupRoleAssigned")
    MockMethodPartial(wrapper, "UnitRace", "TODO: Mock UnitRace")
    MockMethodPartial(wrapper, "UnitFactionGroup", "TODO: Mock UnitFactionGroup")
    MockMethodPartial(wrapper, "IsInRaid", "TODO: Mock IsInRaid")
    MockMethodPartial(wrapper, "UnitClass", "TODO: Mock UnitClass")
    MockMethodPartial(wrapper, "UnitExists", "TODO: Mock UnitExists")
    MockMethodPartial(wrapper, "UnitGUID", "TODO: Mock UnitGUID")
    MockMethodPartial(wrapper, "UnitAffectingCombat", "TODO: Mock UnitAffectingCombat")
    MockMethodPartial(wrapper, "GetSpecialization", "TODO: Mock Specialization")
    MockMethodPartial(wrapper, "GetActiveSpecGroup", "TODO: Mock ActiveSpecGroup")
    MockMethodPartial(wrapper, "GetInstanceInfo", "TODO: Mock InstanceInfo")
    MockMethodPartial(wrapper, "IsInInstance", "TODO: Mock IsInInstance")
    MockMethodPartial(wrapper, "GetNumGroupMembers", "TODO: Mock NumGroupMembers")
    MockMethodPartial(wrapper, "UnitIsUnit", "TODO: Mock UnitIsUnit")
    MockMethodPartial(wrapper, "GetRaidRosterInfo", "TODO: Mock GetRaidRosterInfo")
    MockMethodPartial(wrapper, "GetSpecialization", "TODO: Mock GetSpecialization")
    MockMethodPartial(wrapper, "GetSpecializationRole", "TODO: Mock GetSpecializationRole")
    MockMethodPartial(wrapper, "UnitInVehicle", "TODO: Mock UnitInVehicle")
    MockMethodPartial(wrapper, "UnitHasVehicleUI", "TODO: Mock UnitHasVehicleUI")
    MockMethodPartial(wrapper, "GetSpellInfo", "TODO: Mock GetSpellInfo")
    MockMethodPartial(wrapper, "SendChatMessage", "TODO: Mock SendChatMessage")
    MockMethodPartial(wrapper, "GetChannelName", "TODO: Mock GetChannelName")
    MockMethodPartial(wrapper, "UnitInBattleground", "TODO: Mock UnitInBattleground")
    MockMethodPartial(wrapper, "UnitInRaid", "TODO: Mock UnitInRaid")
    MockMethodPartial(wrapper, "UnitInParty", "TODO: Mock UnitInParty")
    MockMethodPartial(wrapper, "PlaySoundFile", "TODO: Mock PlaySoundFile")
    MockMethodPartial(wrapper, "PlaySoundKitID", "TODO: Mock PlaySoundKitID")
    MockMethodPartial(wrapper, "GetTime", "TODO: Mock GetTime")
    MockMethodPartial(wrapper, "GetSpellLink", "TODO: Mock GetSpellLink")
    MockMethodPartial(wrapper, "GetItemInfo", "TODO: Mock GetItemInfo")
    MockMethodPartial(wrapper, "CreateFrame", "TODO: Mock CreateFrame")
    MockMethodPartial(wrapper, "IsShiftKeyDown", "TODO: Mock IsShiftKeyDown")
    MockMethodPartial(wrapper, "GetScreenWidth", "TODO: Mock GetScreenWidth")
    MockMethodPartial(wrapper, "GetScreenHeight", "TODO: Mock GetScreenHeight")
    MockMethodPartial(wrapper, "GetCursorPosition", "TODO: Mock GetCursorPosition")
    MockMethodPartial(wrapper, "random", "TODO: Mock random")
    MockMethodPartial(wrapper, "UpdateAddOnCPUUsage", "TODO: Mock UpdateAddOnCPUUsage")
    MockMethodPartial(wrapper, "GetFrameCPUUsage", "TODO: Mock GetFrameCPUUsage")
    MockMethodPartial(wrapper, "debugprofilestop", "TODO: Mock debugprofilestop")
    MockMethodPartial(wrapper, "debugstack", "TODO: Mock debugstack")
    MockMethodPartial(wrapper, "IsSpellKnown", "TODO: Mock IsSpellKnown")
end

-- TESTING When we change the mock on one instance it doesn't affect others.
local mock1 = WowApiMock.create()
local mock2 = WowApiMock.create()
local talentInfoTemp = "TODO: Mock TalentInfo"
assert(mock1:GetTalentInfo() == talentInfoTemp, "FAIL")
assert(mock2:GetTalentInfo() == talentInfoTemp, "FAIL")

local talentInfoMocked = "New Talent Info"
mock1:MockGetTalentInfo(talentInfoMocked)
assert(mock1:GetTalentInfo() == talentInfoMocked, "FAIL")
assert(mock2:GetTalentInfo() == talentInfoTemp, "FAIL")

--TESTING When the mocked value is a function, its called appropriately.
local func = function(input) 
    if input == "IsMatch" then 
        return "Success"
    else 
        return "Failure"
    end
end

local mock3 = WowApiMock.create()
assert(mock3:GetTalentInfo("IsMatch") == talentInfoTemp, "FAIL")
assert(mock3:GetTalentInfo("IsNotMatch") == talentInfoTemp, "FAIL")

mock3:MockGetTalentInfo(func)

assert(mock3:GetTalentInfo("IsMatch") == "Success", "FAIL")
assert(mock3:GetTalentInfo("IsNotMatch") == "Failure", "FAIL")

--TESTING When the mock has multiple return values, we get them all.
local loadAddOnMocked = "TODO: Mock LoadAddOn"
local loadAddOnResult = mock1:LoadAddOn("WeakAuras2")
assert(loadAddOnResult == loadAddOnMocked)

mock1:MockLoadAddOn({1,"Successful Load"})
local success, reason = mock1:LoadAddOn("WeakAuras2")
assert(success == 1, "FAIL")
assert(reason == "Successful Load")