WowApiWrapper = {}
WowApiWrapper.__index = WowApiWrapper

function WowApiWrapper:create()
    local wrapper = {}
    setmetatable(wrapper, WowApiWrapper)
    return wrapper
end

function WowApiWrapper:GetTalentInfo()
    return GetTalentInfo()
end