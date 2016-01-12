-- Import SM for statusbar-textures, font-styles and border-types
local SharedMedia = LibStub("LibSharedMedia-3.0");

-- GLOBALS: WeakAuras

-- Default settings
local default = {
    controlledChildren     = {},
    anchorPoint         = "CENTER",
    xOffset             = 0,
    yOffset             = 0,
    frameStrata         = 1,
    border                = false,
    borderColor         = {1.0, 1.0, 1.0, 0.5},
    backdropColor        = {1.0, 1.0, 1.0, 0.5},
    borderEdge            = "None",
    borderOffset         = 5,
    borderInset            = 11,
    borderSize            = 16,
    borderBackdrop        = "Blizzard Tooltip",
};

-- Called when first creating a new region/display
local function create(parent)
    -- Main region
    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    region:SetWidth(1.0);
    region:SetHeight(1.0);

    -- Border region
    local border = CreateFrame("frame", nil, region);
    region.border = border;

    -- Return new region
    return region;
end

-- Calculate bounding box
local function getRect(data)
    -- Temp variables
    local blx, bly, trx, try;
    blx, bly = data.xOffset, data.yOffset;

    -- Calc bounding box
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

    -- Return data
    return blx, bly, trx, try;
end

-- Modify a given region/display
local function modify(parent, region, data)
    -- Localize
    local border = region.border;

    -- Adjust framestrata
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

    -- Get overall bounding box
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

    -- Reset position and size
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);

    -- Adjust frame-level sorting
    local lowestRegion = WeakAuras.regions[data.controlledChildren[1]] and WeakAuras.regions[data.controlledChildren[1]].region
    if(lowestRegion) then
        local frameLevel = lowestRegion:GetFrameLevel()
        for i=1,#data.controlledChildren do
            local childRegion = WeakAuras.regions[data.controlledChildren[i]] and WeakAuras.regions[data.controlledChildren[i]].region
            if(childRegion) then
                if frameLevel >= 100 then
                    frameLevel = 100
                else
                    frameLevel = frameLevel + 1
                end
                -- Try to fix #358 with info from http://wow.curseforge.com/addons/droodfocus/tickets/14
                -- by setting SetFrameLevel() twice.
                childRegion:SetFrameLevel(frameLevel)
                childRegion:SetFrameLevel(frameLevel)
            end
        end
    end

    -- Control children (does not happen with "group")
    function region:UpdateBorder(childRegion)
        local border = region.border;
        -- Apply border settings
        if data.border then
            -- Initial visibility (of child that originated UpdateBorder(...))
            local childVisible = childRegion and childRegion.toShow or false;

            -- Scan children for visibility
            if not childVisible then
                for index, childId in ipairs(data.controlledChildren) do
                    local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
                    if childRegion and childRegion.toShow then
                        childVisible = true;
                        break;
                    end
                end
            end

            -- Show border if child is visible
            if childVisible then
                border:SetBackdrop({
                    edgeFile = data.borderEdge ~= "None" and SharedMedia:Fetch("border", data.borderEdge) or "",
                    edgeSize = data.borderSize,
                    bgFile = data.borderBackdrop ~= "None" and SharedMedia:Fetch("background", data.borderBackdrop) or "",
                    insets = {
                        left     = data.borderInset,
                        right     = data.borderInset,
                        top     = data.borderInset,
                        bottom     = data.borderInset,
                    },
                });
                border:SetBackdropBorderColor(data.borderColor[1], data.borderColor[2], data.borderColor[3], data.borderColor[4]);
                border:SetBackdropColor(data.backdropColor[1], data.backdropColor[2], data.backdropColor[3], data.backdropColor[4]);

                border:ClearAllPoints();
                border:SetPoint("bottomleft", region, "bottomleft", leftest-data.borderOffset, lowest-data.borderOffset);
                border:SetPoint("topright",   region, "topright",   rightest+data.borderOffset, highest+data.borderOffset);

                border:Show();
            else
                border:Hide();
            end
        else
            border:Hide();
        end
    end
    region:UpdateBorder()
end

-- Register new region type with WeakAuras
WeakAuras.RegisterRegionType("group", create, modify, default);
