if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...
local L = WeakAuras.L;

local function subSupports(regionType)
    return regionType == "texture"
    or regionType == "progresstexture"
    or regionType == "icon"
    or regionType == "aurabar"
    or regionType == "text"
end

local function noop()
end

local function subCreate()
    local result = {}
    result.Update = noop
    result.SetFrameLevel = noop
    return result
end

local function subModify(parent, region)
    region.parent = parent
end

WeakAuras.RegisterSubRegionType("subforeground", L["Foreground"], subSupports, subCreate, subModify, noop, noop, {}, nil, {}, false);