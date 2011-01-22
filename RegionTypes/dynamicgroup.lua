local SharedMedia = LibStub("LibSharedMedia-3.0");
    
local default = {
    controlledChildren = {},
    grow = "DOWN",
    align = "CENTER",
    space = 2,
    stagger = 0,
    animate = false,
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0
};

local function create(parent)
    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    
    region.trays = {};
    
    return region;
end

local function modify(parent, region, data)
    region.toHide = region.toHide or {};
    region.groupHiding = region.groupHiding or {};
    region.toShow = region.toShow or {};
    
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
    
    for index, childId in ipairs(data.controlledChildren) do
        if not(region.trays[index]) then
            region.trays[index] = CreateFrame("Frame", nil, region);
        end
        local childData = WeakAuras.GetData(childId);
        local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
        if(childData and childRegion) then
            local width = childRegion:GetWidth();
            local height = childRegion:GetHeight();
            if not(width and height) then
                error("No width and height!");
            end
            region.trays[index]:SetWidth(childData.width);
            region.trays[index]:SetHeight(childData.height);
            childRegion:ClearAllPoints();
            childRegion:SetPoint(selfPoint, region.trays[index], selfPoint);
        end
    end
    
    function region:PositionChildren()
        local xOffset, yOffset = 0, 0;
        if(data.grow == "RIGHT" or data.grow == "LEFT" or data.grow == "HORIZONTAL") then
            if(data.align == "LEFT" and data.stagger > 0) then
                yOffset = yOffset - (data.stagger * (#data.controlledChildren - 1));
            elseif(data.align == "RIGHT" and data.stagger < 0) then
                yOffset = yOffset - (data.stagger * (#data.controlledChildren - 1));
            elseif(data.align == "CENTER") then
                if(data.stagger < 0) then
                    yOffset = yOffset - (data.stagger * (#data.controlledChildren - 1) / 2);
                else
                    yOffset = yOffset - (data.stagger * (#data.controlledChildren - 1) / 2);
                end
            end
        else
            if(data.align == "LEFT" and data.stagger < 0) then
                xOffset = xOffset - (data.stagger * (#data.controlledChildren - 1));
            elseif(data.align == "RIGHT" and data.stagger > 0) then
                xOffset = xOffset - (data.stagger * (#data.controlledChildren - 1));
            elseif(data.align == "CENTER") then
                if(data.stagger < 0) then
                    xOffset = xOffset - (data.stagger * (#data.controlledChildren - 1) / 2);
                else
                    xOffset = xOffset - (data.stagger * (#data.controlledChildren - 1) / 2);
                end
            end
        end
        
        local centerXOffset, centerYOffset = 0, 0;
        if(data.grow == "HORIZONTAL" or data.grow == "VERTICAL") then
            local currentWidth, currentHeight = 0, 0;
            local num = 0;
            for index, childId in pairs(data.controlledChildren) do
                local childData = WeakAuras.GetData(childId);
                local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
                if(childData and childRegion) then
                    if(((childRegion:IsVisible() and not (region.toHide[childId] or region.groupHiding[childId])) or region.toShow[childId]) and not (WeakAuras.IsAnimating("display", childId) == "finish")) then
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
        
        for index, childId in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
            if(childData and childRegion) then
                if(region.toShow[childId]) then
                    region.toHide[childId] = nil;
                    region.groupHiding[childId] = nil;
                end
                
                if((childRegion:IsVisible() or region.toShow[childId]) and not (region.toHide[childId] or region.groupHiding[childId] or WeakAuras.IsAnimating("display", childId) == "finish")) then
                    if not(region.trays[index]) then
                        print(data.id, index, childId);
                    end
                    region.trays[index]:ClearAllPoints();
                    region.trays[index]:SetPoint(selfPoint, region, selfPoint, xOffset, yOffset);
                    childRegion:ClearAllPoints();
                    childRegion:SetPoint(selfPoint, region.trays[index], selfPoint);
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
                    
                    region.trays[index]:ClearAllPoints();
                    region.trays[index]:SetPoint(selfPoint, region, selfPoint, hiddenXOffset, hiddenYOffset);
                    childRegion:ClearAllPoints();
                    childRegion:SetPoint(selfPoint, region.trays[index], selfPoint);
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
        for index, childId in ipairs(data.controlledChildren) do
            local _, _, _, previousX, previousY = region.trays[index]:GetPoint(1);
            previousX = previousX or 0;
            previousY = previousY or 0;
            previous[childId] = {x = previousX, y = previousY};
        end
        
        region:PositionChildren();
        
        for index, childId in pairs(data.controlledChildren) do
            local childData = WeakAuras.GetData(childId);
            local childRegion = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
            if(childData and childRegion) then
                if(region.toShow[childId]) then
                    childRegion:Show();
                    region.toShow[childId] = nil;
                end
                
                local _, _, _, xOffset, yOffset = region.trays[index]:GetPoint(1);
                local previousX, previousY = previous[childId].x, previous[childId].y;
                if(childRegion:IsVisible() and data.animate) then
                    local anim = {
                        type = "custom",
                        duration = 0.2,
                        use_translate = true,
                        x = previousX - xOffset,
                        y = previousY - yOffset
                    };
                    if(region.toHide[childId]) then
                        region.toHide[childId] = nil;
                        if(WeakAuras.IsAnimating("display", childId) == "finish") then
                            --childRegion will be hidden by its own animation, so the tray animation does not need to hide it
                        else
                            region.groupHiding[childId] = true;
                        end
                    end
                    WeakAuras.CancelAnimation(index.."tray", data.id);
                    WeakAuras.Animate(index.."tray", data.id, "tray", anim, region.trays[index], true, function()
                        if(region.groupHiding[childId]) then
                            region.groupHiding[childId] = nil;
                            childRegion:Hide();
                        end
                    end);
                elseif(region.toHide[childId]) then
                    region.toHide[childId] = nil;
                    if(WeakAuras.IsAnimating("display", childId) == "finish") then
                        --childRegion will be hidden by its own animation, so it does not need to be hidden immediately
                    else
                        childRegion:Hide();
                    end
                end
            end
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
        for i=#data.controlledChildren-1,1,-1 do
            local childRegion = WeakAuras.regions[data.controlledChildren[i]] and WeakAuras.regions[data.controlledChildren[i]].region;
            if(childRegion) then
                frameLevel = frameLevel + 1;
                childRegion:SetFrameLevel(frameLevel);
            end
        end
    end
    
    local maxWidth, maxHeight = 0, 0;
    for index, childId in ipairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
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