local SharedMedia = LibStub("LibSharedMedia-3.0");
    
local default = {
    controlledChildren = {},
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0,
    frameStrata = 1
};

local function create(parent)
    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    region:SetWidth(0.01);
    region:SetHeight(0.01);
    
    local background = CreateFrame("frame", nil, region);
    region.background = background;
    
    return region;
end

local function getRect(data)
    local blx, bly, trx, try;
    blx, bly = data.xOffset, data.yOffset;
    if(data.selfPoint:find("LEFT")) then
        trx = blx + data.width;
    elseif(data.selfPoint:find("RIGHT")) then
        trx = blx;
        blx = blx - data.width;
    else
        blx = blx - (data.width/2);
        trx = blx + data.width;
    end
    if(data.selfPoint:find("BOTTOM")) then
        try = bly + data.height;
    elseif(data.selfPoint:find("TOP")) then
        try = bly;
        bly = bly - data.height;
    else
        bly = bly - (data.height/2);
        try = bly + data.height;
    end
    
    return blx, bly, trx, try;
end

local function modify(parent, region, data)
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end
    
    data.selfPoint = "BOTTOMLEFT";
    local leftest, rightest, lowest, highest = 0, 0, 0, 0;
    for index, childId in ipairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
            local blx, bly, trx, try = getRect(childData);
            leftest = math.min(leftest, blx);
            rightest = math.max(rightest, trx);
            lowest = math.min(lowest, bly);
            highest = math.max(highest, try);
        end
    end
    region.blx = leftest;
    region.bly = lowest;
    region.trx = rightest;
    region.try = highest;
    
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
    
    local lowestRegion = WeakAuras.regions[data.controlledChildren[1]] and WeakAuras.regions[data.controlledChildren[1]].region;
    if(lowestRegion) then    
        local frameLevel = lowestRegion:GetFrameLevel();
        for i=2,#data.controlledChildren do
            local childRegion = WeakAuras.regions[data.controlledChildren[i]] and WeakAuras.regions[data.controlledChildren[i]].region;
            if(childRegion) then
                frameLevel = frameLevel + 1;
                childRegion:SetFrameLevel(frameLevel);
            end
        end
    end
    
    function region:PositionChildren()
    end
    
    function region:ControlChildren()
    end
end

WeakAuras.RegisterRegionType("group", create, modify, default);