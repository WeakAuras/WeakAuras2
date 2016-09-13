
--- Stubs out a mocked method.
-- Prepares the API Wrapper simulate a scenario you want to test.
-- @param mockInstance The WowApiMock instance that you want to configure.
--[[-- @param propertyName The name of the property you want to mock. 
For instance, if you want to mock the method GetRealmName, set this to "RealmName".]]
--[[-- @param getMethodName The name of the method you want to use for actually calling the function.
This should be the same name that the WoW API uses.]]
--[[-- @param setMethodName The name of the method you want to use to set the value for the mock.]]
--[[-- @param defaultValue The value you want the method to return. 
If you specify a literal (like "Bonechewer") GetRealmName would always return Bonechewer. 
If you specify a function, then the function will be called whenever someone calls that function on the API. 
Your function will be passed all of the values that the WoW API would have been passed.]]
function MockMethodFull(mockInstance, propertyName, getMethodName, setMethodName, defaultValue)
    mockInstance[getMethodName] = function(...)
        local realParameters = select(2, ...)
        -- The method being mocked may or may not have parameters
        -- so ... to grab them all.

        -- Grab the value we applied to this method on the mock.
        local returnValue = mockInstance[propertyName] or defaultValue; 

        -- If that value is a function, call it with whatever parameters
        -- we were given.
        if type(returnValue) == 'function' then
            return returnValue(realParameters)
        end

        -- Otherwise it must be a constant, just send it back as-is.
        return returnValue
    end

    mockInstance[setMethodName] = function(instance, value)
        instance[propertyName] = value
    end
end

--- Stubs out a mocked method.
-- Prepares the API Wrapper simulate a scenario you want to test.
-- @param mockInstance The WowApiMock instance that you want to configure.
--[[-- @param methodName The name of the method you want to mock. 
For instance, if you want to mock the method GetRealmName, set this to "GetRealmName".]]
--[[-- @param defaultValue The value you want the method to return. 
If you specify a literal (like "Bonechewer") GetRealmName would always return Bonechewer. 
If you specify a function, then the function will be called whenever someone calls that function on the API. 
Your function will be passed all of the values that the WoW API would have been passed.]]
function MockMethodPartial(mockInstance, methodName, defaultValue)
    local setMethodName = "Mock"..methodName
    local propertyName = methodName.."BackingProperty"

    MockMethodFull(mockInstance, propertyName, methodName, setMethodName, defaultValue)
end

--- Stubs out a mocked method.
-- Prepares the API Wrapper simulate a scenario you want to test.
-- @param type The WowApiMock instance that you want to configure.
--[[-- @param propertyName The name of the property you want to mock. 
For instance, if you want to mock the method GetRealmName, set this to "RealmName".]]
--[[-- @param defaultValue The value you want the method to return. 
If you specify a literal (like "Bonechewer") GetRealmName would always return Bonechewer. 
If you specify a function, then the function will be called whenever someone calls that function on the API. 
Your function will be passed all of the values that the WoW API would have been passed.]]
function MockMethod(type, propertyName, defaultValue)
    local getMethodName = "Get"..propertyName
    local setMethodName = "Mock"..getMethodName

    MockMethodFull(type, propertyName, getMethodName, setMethodName, defaultValue)
end

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