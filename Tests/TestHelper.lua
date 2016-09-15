function RunAllTests(testSuite)
    local passingTests = {}
    local failingTests = {}
    local passingCount = 0
    local failingCount = 0

    for key, func in pairs(testSuite) do
        if(type(func) == "function" and string.sub(key, 1, 2) ~= "X_") then
            ResetMocks()
            local result, data = pcall(func)
            if(result) then
                table.insert(passingTests, key)
                passingCount = passingCount + 1
            else
                failingTests[key] = data
                failingCount = failingCount + 1
            end
        end
    end

    local totalTests = passingCount + failingCount

    print(totalTests .. " Tests Executed")
    print("")
    print(passingCount .. " Tests Passed")
    print(failingCount .. " Tests Failed")

    if failingCount > 0 then
        print("")
        print("FAILING TESTS:")
        for key, value in pairs(failingTests) do
            print(key .. ": " .. value)
        end
    end
end