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
    table.insert(WowApiMock.BackingProperties, propertyName)
    table.insert(WowApiMock.MockedMethods, getMethodName)

    _G[getMethodName] = function(...)
        local realParameters = select(1, ...)
        -- The method being mocked may or may not have parameters
        -- so ... to grab them all.

        -- Grab the value we applied to this method on the mock.
        local returnValue = WowApiMock[propertyName] or defaultValue; 

        -- If that value is a function, call it with whatever parameters
        -- we were given.
        if type(returnValue) == 'function' then
            return returnValue(realParameters)
        elseif type(returnValue) == 'table' then
            return table.unpack(returnValue)
        end

        -- Otherwise it must be a constant, just send it back as-is.
        return returnValue
    end

    _G[setMethodName] = function(value)
        WowApiMock[propertyName] = value
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