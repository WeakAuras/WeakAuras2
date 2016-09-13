
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
    MockMethod(wrapper, "PvpTalentInfo", "TODO: Mock PvpTalentInfo")
    
    -- Commented lines here indicate that there's something different about these
    -- that needs more attention.
    -- IsAddOnLoaded
    -- InCombatLockdown
    -- LoadAddOn
    -- setfenv
    -- UnitName
    MockMethod(wrapper, "RealmName", "TODO: Mock RealmName")
    MockMethod(wrapper, "RealZoneText", "TODO: Mock RealZoneText")
    MockMethod(wrapper, "CurrentMapAreaID", "TODO: Mock CurrentMapAreaID")
    -- UnitGroupRoleAssigned
    -- UnitRace
    -- UnitFactionGroup
    -- IsInRaid
    -- UnitClass
    -- UnitExists
    -- UnitGUID
    -- UnitAffectingCombat
    MockMethod(wrapper, "Specialization", "TODO: Mock Specialization")
    MockMethod(wrapper, "ActiveSpecGroup", "TODO: Mock ActiveSpecGroup")
    MockMethod(wrapper, "InstanceInfo", "TODO: Mock InstanceInfo")
    -- IsInInstance
    MockMethod(wrapper, "NumGroupMembers", "TODO: Mock NumGroupMembers")
    -- UnitIsUnit
end

local mock1 = WowApiMock.create()
local mock2 = WowApiMock.create()
print(mock1:GetTalentInfo())
print(mock2:GetTalentInfo())
mock1:MockGetTalentInfo("New talent info")
print(mock1:GetTalentInfo())
print(mock2:GetTalentInfo())

print("------")

print(mock1:GetRealmName())
print(mock2:GetRealmName())
mock1:MockGetRealmName("Proudmoore", "blah", "blah")
print(mock1:GetRealmName())
print(mock2:GetRealmName())


print("------")

local func = function(input) 
    if input == "win" then 
        print("winner") 
    else 
        print("loser")
    end
end

mock1:MockGetTalentInfo(func)

print(mock2:GetTalentInfo())
mock1:GetTalentInfo("win")
mock1:GetTalentInfo("lose")