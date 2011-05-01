local SharedMedia = LibStub("LibSharedMedia-3.0");
    
local default = {
    controlledChildren = {},
    border = "None",
    borderOffset = 16,
    background = "None",
    backgroundInset = 0,
    grow = "DOWN",
    align = "CENTER",
    space = 2,
    stagger = 0,
    sort = "none",
    animate = false,
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0,
    frameStrata = 1
};

local function create(parent)
    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    
    local background = CreateFrame("frame", nil, region);
    region.background = background;
    
    region.trays = {};
    
    return region;
end

local function modify(parent, region, data)
    local background = region.background;
    
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end
    
    local bgFile = SharedMedia:Fetch("background", data.background or "");
    local edgeFile = SharedMedia:Fetch("border", data.border or "");
    background:SetBackdrop({
        bgFile = bgFile,
        edgeFile = edgeFile,
        tile = false,
        tileSize = 0,
        edgeSize = 16,
        insets = {
            left = data.backgroundInset,
            right = data.backgroundInset,
            top = data.backgroundInset,
            bottom = data.backgroundInset
        }
    });
    background:SetPoint("bottomleft", region, "bottomleft", -1 * data.borderOffset, -1 * data.borderOffset);
    background:SetPoint("topright", region, "topright", data.borderOffset, data.borderOffset);
    
    local selfPoint;
    local actualSelfPoint;
    if(data.grow == "RIGHT") then
        selfPoint = "LEFT";
        if(data.align == "LEFT") then
            selfPoint = "TOP"..selfPoint;
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM"..selfPoint;
        end
        actualSelfPoint = selfPoint;
    elseif(data.grow == "LEFT") then
        selfPoint = "RIGHT";
        if(data.align == "LEFT") then
            selfPoint = "TOP"..selfPoint;
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM"..selfPoint;
        end
        actualSelfPoint = selfPoint;
    elseif(data.grow == "UP") then
        selfPoint = "BOTTOM";
        if(data.align == "LEFT") then
            selfPoint = selfPoint.."LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = selfPoint.."RIGHT";
        end
        actualSelfPoint = selfPoint;
    elseif(data.grow == "DOWN" ) then
        selfPoint = "TOP";
        if(data.align == "LEFT") then
            selfPoint = selfPoint.."LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = selfPoint.."RIGHT";
        end
        actualSelfPoint = selfPoint;
    elseif(data.grow == "HORIZONTAL") then
        selfPoint = "LEFT";
        actualSelfPoint = "CENTER";
        if(data.align == "LEFT") then
            selfPoint = "TOP"..selfPoint;
            actualSelfPoint = "TOP";
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM"..selfPoint;
            actualSelfPoint = "BOTTOM";
        end
    elseif(data.grow == "VERTICAL") then
        selfPoint = "TOP";
        actualSelfPoint = "CENTER";
        if(data.align == "LEFT") then
            selfPoint = selfPoint.."LEFT";
            actualSelfPoint = "LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = selfPoint.."RIGHT";
            actualSelfPoint = "RIGHT";
        end
    end
    data.selfPoint = actualSelfPoint;
        
    region:ClearAllPoints();
    region:SetPoint(actualSelfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
    
    region.controlledRegions = {};
    
    function region:EnsureControlledRegions()
        local anyIndexInfo = false;
        local dataIndex = 1;
        local regionIndex = 1;
        while(dataIndex <= #data.controlledChildren) do
            local childId = data.controlledChildren[dataIndex];
            local childData = WeakAuras.GetData(childId);
            local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
            if(childRegion) then
                if not(region.controlledRegions[regionIndex]) then
                    region.controlledRegions[regionIndex] = {};
                end
                region.controlledRegions[regionIndex].id = childId;
                region.controlledRegions[regionIndex].data = childData;
                region.controlledRegions[regionIndex].region = childRegion;
                region.controlledRegions[regionIndex].key = tostring(region.controlledRegions[regionIndex].region);
                anyIndexInfo = anyIndexInfo or childRegion.index;
                region.controlledRegions[regionIndex].dataIndex = dataIndex;
                dataIndex = dataIndex + 1;
                regionIndex = regionIndex + 1;
                if(childData and WeakAuras.clones[childId]) then
                    for cloneId, cloneRegion in pairs(WeakAuras.clones[childId]) do
                        if not(region.controlledRegions[regionIndex]) then
                            region.controlledRegions[regionIndex] = {};
                        end
                        region.controlledRegions[regionIndex].id = childId;
                        region.controlledRegions[regionIndex].data = childData;
                        region.controlledRegions[regionIndex].cloneId = cloneId;
                        region.controlledRegions[regionIndex].region = cloneRegion;
                        region.controlledRegions[regionIndex].key = tostring(region.controlledRegions[regionIndex].region);
                        anyIndexInfo = anyIndexInfo or cloneRegion.index;
                        region.controlledRegions[regionIndex].dataIndex = dataIndex;
                        regionIndex = regionIndex + 1;
                    end
                end
            else
                dataIndex = dataIndex + 1;
            end
        end
        while(region.controlledRegions[regionIndex]) do
            region.controlledRegions[regionIndex] = nil;
            regionIndex = regionIndex + 1;
        end
        
        if(data.sort == "ascending") then
            table.sort(region.controlledRegions, function(a, b)
                return (
                    a.region
                    and a.region.expirationTime
                    and a.region.expirationTime > 0
                    and a.region.expirationTime
                    or math.huge
                ) < (
                    b.region
                    and b.region.expirationTime
                    and b.region.expirationTime > 0
                    and b.region.expirationTime
                    or math.huge
                )
            end);
        elseif(data.sort == "descending") then
            table.sort(region.controlledRegions, function(a, b) 
                return (
                    a.region
                    and a.region.expirationTime
                    and a.region.expirationTime > 0
                    and a.region.expirationTime
                    or math.huge
                ) > (
                    b.region
                    and b.region.expirationTime
                    and b.region.expirationTime > 0
                    and b.region.expirationTime
                    or math.huge
                )
            end);
        elseif(anyIndexInfo) then
            table.sort(region.controlledRegions, function(a, b)
                if not(a) then
                    return 1 < 2;
                elseif not(b) then
                    return 2 < 1;
                end
                return (
                    (
                        a.region.dataIndex == b.region.dataIndex
                        and (a.region.index or 0) < (b.region.index or 0)
                    )
                    or (a.region.dataIndex or 0) < (b.region.dataIndex or 0)
                )
            end)
        end
    end
    
    function region:EnsureTrays()
        region:EnsureControlledRegions();
        for index, regionData in ipairs(region.controlledRegions) do
            if not(region.trays[regionData.key]) then
                region.trays[regionData.key] = CreateFrame("Frame", nil, region);
            end
            if(regionData.data and regionData.region) then
                region.trays[regionData.key]:SetWidth(regionData.data.width);
                region.trays[regionData.key]:SetHeight(regionData.data.height);
                regionData.region:ClearAllPoints();
                regionData.region:SetPoint(selfPoint, region.trays[regionData.key], selfPoint);
            end
        end
    end
    
    region:EnsureTrays();
    
    function region:PositionChildren()
        region:EnsureTrays();
        local childId, childData, childRegion;
        local xOffset, yOffset = 0, 0;
        if(data.grow == "RIGHT" or data.grow == "LEFT" or data.grow == "HORIZONTAL") then
            if(data.align == "LEFT" and data.stagger > 0) then
                yOffset = yOffset - (data.stagger * (#region.controlledRegions - 1));
            elseif(data.align == "RIGHT" and data.stagger < 0) then
                yOffset = yOffset - (data.stagger * (#region.controlledRegions - 1));
            elseif(data.align == "CENTER") then
                if(data.stagger < 0) then
                    yOffset = yOffset - (data.stagger * (#region.controlledRegions - 1) / 2);
                else
                    yOffset = yOffset - (data.stagger * (#region.controlledRegions - 1) / 2);
                end
            end
        else
            if(data.align == "LEFT" and data.stagger < 0) then
                xOffset = xOffset - (data.stagger * (#region.controlledRegions - 1));
            elseif(data.align == "RIGHT" and data.stagger > 0) then
                xOffset = xOffset - (data.stagger * (#region.controlledRegions - 1));
            elseif(data.align == "CENTER") then
                if(data.stagger < 0) then
                    xOffset = xOffset - (data.stagger * (#region.controlledRegions - 1) / 2);
                else
                    xOffset = xOffset - (data.stagger * (#region.controlledRegions - 1) / 2);
                end
            end
        end
        
        local centerXOffset, centerYOffset = 0, 0;
        if(data.grow == "HORIZONTAL" or data.grow == "VERTICAL") then
            local currentWidth, currentHeight = 0, 0;
            local num = 0;
            for index, regionData in pairs(region.controlledRegions) do
                childId = regionData.id;
                childData = regionData.data;
                childRegion = regionData.region;
                if(childData and childRegion) then
                    if(((childRegion:IsVisible() and not (childRegion.toHide or childRegion.groupHiding)) or childRegion.toShow) and not (WeakAuras.IsAnimating(childRegion) == "finish")) then
                        if(data.grow == "HORIZONTAL") then
                            currentWidth = currentWidth + childData.width;
                            num = num + 1;
                        elseif(data.grow == "VERTICAL") then
                            currentHeight = currentHeight + childData.height;
                            num = num + 1;
                        end
                    end
                end
            end
            
            if(data.grow == "HORIZONTAL") then
                currentWidth = currentWidth + (data.space * max(num - 1, 0));
                centerXOffset = ((data.width - currentWidth) / 2);
                centerYOffset = 0;
            elseif(data.grow == "VERTICAL") then
                currentHeight = currentHeight + (data.space * max(num - 1, 0));
                centerYOffset = ((data.height - currentHeight) / 2);
                centerXOffset = 0;
            end
        end
        xOffset = xOffset + centerXOffset;
        yOffset = yOffset - centerYOffset;
        
        for index, regionData in pairs(region.controlledRegions) do
            childId = regionData.id;
            childData = regionData.data;
            childRegion = regionData.region;
            if(childData and childRegion) then
                if(childRegion.toShow) then
                    childRegion.toHide = nil;
                    childRegion.groupHiding = nil;
                end
                
                if((childRegion:IsVisible() or childRegion.toShow) and not (childRegion.toHide or childRegion.groupHiding or WeakAuras.IsAnimating(childRegion) == "finish")) then
                    region.trays[regionData.key]:ClearAllPoints();
                    region.trays[regionData.key]:SetPoint(selfPoint, region, selfPoint, xOffset, yOffset);
                    childRegion:ClearAllPoints();
                    childRegion:SetPoint(selfPoint, region.trays[regionData.key], selfPoint);
                    if(data.grow == "RIGHT" or data.grow == "HORIZONTAL") then
                        xOffset = xOffset + (childData.width + data.space);
                        yOffset = yOffset + data.stagger;
                    elseif(data.grow == "LEFT") then
                        xOffset = xOffset - (childData.width + data.space);
                        yOffset = yOffset + data.stagger;
                    elseif(data.grow == "UP") then
                        yOffset = yOffset + (childData.height + data.space);
                        xOffset = xOffset + data.stagger;
                    elseif(data.grow == "DOWN" or data.grow == "VERTICAL") then
                        yOffset = yOffset - (childData.height + data.space);
                        xOffset = xOffset + data.stagger;
                    end
                else
                    local hiddenXOffset, hiddenYOffset;
                    if(data.grow == "RIGHT") then
                        hiddenXOffset = xOffset - (childData.width + data.space);
                        hiddenYOffset = yOffset - data.stagger;
                    elseif(data.grow == "LEFT") then
                        hiddenXOffset = xOffset + (childData.width + data.space);
                        hiddenYOffset = yOffset - data.stagger;
                    elseif(data.grow == "UP") then
                        hiddenYOffset = yOffset - (childData.height + data.space);
                        hiddenXOffset = xOffset - data.stagger;
                    elseif(data.grow == "DOWN") then
                        hiddenYOffset = yOffset + (childData.height + data.space);
                        hiddenXOffset = xOffset - data.stagger;
                    elseif(data.grow == "HORIZONTAL") then
                        hiddenXOffset = xOffset - ((childData.width + data.space) * (xOffset / data.width));
                        hiddenYOffset = yOffset - data.stagger;
                    elseif(data.grow == "VERTICAL") then
                        hiddenYOffset = yOffset - ((childData.height + data.space) * (yOffset / data.height));
                        hiddenXOffset = xOffset - data.stagger;
                    end
                    
                    region.trays[regionData.key]:ClearAllPoints();
                    region.trays[regionData.key]:SetPoint(selfPoint, region, selfPoint, hiddenXOffset, hiddenYOffset);
                    childRegion:ClearAllPoints();
                    childRegion:SetPoint(selfPoint, region.trays[regionData.key], selfPoint);
                end
            end
        end
    end
    
    function region:ControlChildren()
        if(data.animate) then
            WeakAuras.pending_controls[data.id] = region;
        else
            region:DoControlChildren();
        end
    end
    
    function region:DoControlChildren()
        local previous = {};
        for index, regionData in pairs(region.controlledRegions) do
            local _, _, _, previousX, previousY = region.trays[regionData.key]:GetPoint(1);
            previousX = previousX or 0;
            previousY = previousY or 0;
            previous[regionData.key] = {x = previousX, y = previousY};
        end
        
        region:PositionChildren();
        
        local anyVisible = false;
        local minX, maxX, minY, maxY;
        local previousPreviousX, previousPreviousY;
        for index, regionData in pairs(region.controlledRegions) do
            local childId = regionData.id;
            local childData = regionData.data;
            local childRegion = regionData.region;
            if(childData and childRegion) then
                if(childRegion.toShow) then
                    childRegion:Show();
                    childRegion.toShow = nil;
                end
                
                local _, _, _, xOffset, yOffset = region.trays[regionData.key]:GetPoint(1);
                local previousX, previousY = previous[regionData.key] and previous[regionData.key].x or previousPreviousX or 0, previous[regionData.key] and previous[regionData.key].y or previousPreviousY or 0;
                local xDelta, yDelta = previousX - xOffset, previousY - yOffset;
                previousPreviousX, previousPreviousY = previousX, previousY;
                if(childRegion:IsVisible() and data.animate and not(abs(xDelta) < 0.1 and abs(yDelta) == 0.1)) then
                    local anim = {
                        type = "custom",
                        duration = 0.2,
                        use_translate = true,
                        x = xDelta,
                        y = yDelta
                    };
                    if(childRegion.toHide) then
                        childRegion.toHide = nil;
                        if(WeakAuras.IsAnimating(childRegion) == "finish") then
                            --childRegion will be hidden by its own animation, so the tray animation does not need to hide it
                        else
                            childRegion.groupHiding = true;
                        end
                    end
                    WeakAuras.CancelAnimation(region.trays[regionData.key], nil, nil, nil, nil, nil, true);
                    WeakAuras.Animate("tray"..regionData.key, data.id, "tray", anim, region.trays[regionData.key], true, function()
                        if(childRegion.groupHiding) then
                            childRegion.groupHiding = nil;
                            childRegion:Hide();
                        end
                    end);
                elseif(childRegion.toHide) then
                    childRegion.toHide = nil;
                    if(WeakAuras.IsAnimating(childRegion) == "finish") then
                        --childRegion will be hidden by its own animation, so it does not need to be hidden immediately
                    else
                        childRegion:Hide();
                    end
                end
                
                if(childRegion:IsVisible()) then
                    anyVisible = true;
                    local regionLeft, regionRight, regionTop, regionBottom = childRegion:GetLeft(), childRegion:GetRight(), childRegion:GetTop(), childRegion:GetBottom();
                    minX = minX and min(regionLeft, minX) or regionLeft;
                    maxX = maxX and max(regionRight, maxX) or regionRight;
                    minY = minY and min(regionBottom, minY) or regionBottom;
                    maxY = maxY and max(regionTop, maxY) or regionTop;
                end
            end
        end
        if(anyVisible) then
            region:SetWidth((maxX or 0) - (minX or 0));
            region:SetHeight((maxY or 0) - (minY or 0));
            region:Show();
        else
            region:Hide();
        end
    end    
    
    for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
            WeakAuras.Add(childData);
        end
    end
    
    region:PositionChildren();
    
    local lowestRegion = WeakAuras.regions[data.controlledChildren[#data.controlledChildren]] and WeakAuras.regions[data.controlledChildren[#data.controlledChildren]].region;
    if(lowestRegion) then    
        local frameLevel = lowestRegion:GetFrameLevel();
        for i=#region.controlledRegions-1,1,-1 do
            local childRegion = region.controlledRegions[i].region;
            if(childRegion) then
                frameLevel = frameLevel + 1;
                childRegion:SetFrameLevel(frameLevel);
            end
        end
    end
    
    local maxWidth, maxHeight = 0, 0;
    for index, regionData in pairs(region.controlledRegions) do
        childId = regionData.id;
        childData = regionData.data;
        if(childData) then
            if(data.grow == "LEFT" or data.grow == "RIGHT" or data.grow == "HORIZONTAL") then
                maxWidth = maxWidth + childData.width;
                maxWidth = maxWidth + (index > 1 and data.space or 0);
                maxHeight = math.max(maxHeight, childData.height);
            else
                maxHeight = maxHeight + childData.height;
                maxHeight = maxHeight + (index > 1 and data.space or 0);
                maxWidth = math.max(maxWidth, childData.width);
            end
        end
    end
    if(data.grow == "LEFT" or data.grow == "RIGHT") then
        maxHeight = maxHeight + (math.abs(data.stagger) * (#data.controlledChildren - 1));
    else
        maxWidth = maxWidth + (math.abs(data.stagger) * (#data.controlledChildren - 1));
    end
    
    maxWidth = (maxWidth and maxWidth > 16 and maxWidth) or 16;
    maxHeight = (maxHeight and maxHeight > 16 and maxHeight) or 16;
    
    data.width, data.height = maxWidth, maxHeight;
    region:SetWidth(data.width);
    region:SetHeight(data.height);
end

WeakAuras.RegisterRegionType("dynamicgroup", create, modify, default);