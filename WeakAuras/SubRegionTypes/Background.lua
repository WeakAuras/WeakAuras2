if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...
local L = WeakAuras.L;

do
    local function subSupports(regionType)
        return regionType ~= "group" and regionType ~= "dynamicgroup"
    end

    local function noop()
    end

    local function subSetFrameLevel(self, level)
        self.parent:SetFrameLevel(level)
    end

    local function subCreate()
        return { Update = noop, SetFrameLevel = subSetFrameLevel}
    end

    local function subModify(parent, region)
        region.parent = parent
    end

    WeakAuras.RegisterSubRegionType("subbackground", L["Background"], subSupports, subCreate, subModify, noop, noop, {}, nil, {}, false);
end

-- Foreground for aurabar

do
    local function subSupports(regionType)
        return regionType == "aurabar"
    end

    local function noop()
    end

    local function subSetFrameLevel(self, level)
        if self.parent.bar then
            self.parent.bar:SetFrameLevel(level)
        end
        if self.parent.iconFrame then
            self.parent.iconFrame:SetFrameLevel(level)
        end
    end

    local function subCreate()
        return { Update = noop, SetFrameLevel = subSetFrameLevel}
    end

    local function subModify(parent, region)
        region.parent = parent
    end

    WeakAuras.RegisterSubRegionType("subforeground", L["Foreground"], subSupports, subCreate, subModify, noop, noop, {}, nil, {}, false);
end
