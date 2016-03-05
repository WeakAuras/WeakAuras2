local SharedMedia = LibStub("LibSharedMedia-3.0");

-- GLOBALS: WeakAuras

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
    radius = 200,
    rotation = 0,
    constantFactor = "RADIUS",
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

function WeakAuras.GetPolarCoordinates(x, y, originX, originY)
    local dX, dY = x - originX, y - originY;

    local r = math.sqrt(dX * dX + dY * dY);
    local theta = atan2(dY, dX);

    return r, theta;
end

local function modify(parent, region, data)
    local background = region.background;

    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

    local bgFile = data.background ~= "None" and SharedMedia:Fetch("background", data.background or "") or "";
    local edgeFile = data.border ~= "None" and SharedMedia:Fetch("border", data.border or "") or "";
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
    if(data.grow == "RIGHT") then
        selfPoint = "LEFT";
        if(data.align == "LEFT") then
            selfPoint = "TOP"..selfPoint;
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM"..selfPoint;
        end
    elseif(data.grow == "LEFT") then
        selfPoint = "RIGHT";
        if(data.align == "LEFT") then
            selfPoint = "TOP"..selfPoint;
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM"..selfPoint;
        end
    elseif(data.grow == "UP") then
        selfPoint = "BOTTOM";
        if(data.align == "LEFT") then
            selfPoint = selfPoint.."LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = selfPoint.."RIGHT";
        end
    elseif(data.grow == "DOWN" ) then
        selfPoint = "TOP";
        if(data.align == "LEFT") then
            selfPoint = selfPoint.."LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = selfPoint.."RIGHT";
        end
    elseif(data.grow == "HORIZONTAL") then
        selfPoint = "CENTER";
        if(data.align == "LEFT") then
            selfPoint = "TOP";
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM";
        end
    elseif(data.grow == "VERTICAL") then
        selfPoint = "CENTER";
        if(data.align == "LEFT") then
            selfPoint = "LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = "RIGHT";
        end
    elseif(data.grow == "CIRCLE") then
        selfPoint = "CENTER";
    end
    data.selfPoint = selfPoint;

    region:ClearAllPoints();
    region:SetPoint(selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);

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
        elseif(data.sort == "hybrid") then
            table.sort(region.controlledRegions, function(a, b)
                local aTime;
                local bTime;
                if (data.sortHybridTable and data.sortHybridTable[a.dataIndex]) then
                    aTime = a.dataIndex - 1000;
                else
                    aTime = a.region and a.region.expirationTime and a.region.expirationTime > 0
                        and a.region.expirationTime or math.huge
                end;

                if (data.sortHybridTable and data.sortHybridTable[b.dataIndex]) then
                    bTime = b.dataIndex - 1000;
                else
                    bTime = b.region and b.region.expirationTime and b.region.expirationTime > 0
                        and b.region.expirationTime or math.huge
                end
                return (
                    (aTime) > (bTime)
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
                        a.dataIndex == b.dataIndex
                        and (a.region.index or 0) < (b.region.index or 0)
                    )
                    or (a.dataIndex or 0) < (b.dataIndex or 0)
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

    function region:DoResize()
        local numVisible = 0;
        local minX, maxX, minY, maxY;
        for index, regionData in pairs(region.controlledRegions) do
            local childId = regionData.id;
            local childData = regionData.data;
            local childRegion = regionData.region;
            if(childData and childRegion) then
                if(childRegion.toShow or  WeakAuras.IsAnimating(childRegion) == "finish") then
                    numVisible = numVisible + 1;
                    local regionLeft, regionRight, regionTop, regionBottom = childRegion:GetLeft(), childRegion:GetRight(), childRegion:GetTop(), childRegion:GetBottom();
                    if(regionLeft and regionRight and regionTop and regionBottom) then
                        minX = minX and min(regionLeft, minX) or regionLeft;
                        maxX = maxX and max(regionRight, maxX) or regionRight;
                        minY = minY and min(regionBottom, minY) or regionBottom;
                        maxY = maxY and max(regionTop, maxY) or regionTop;
                    end
                end
            end
        end
        if(numVisible > 0) then
            minX, maxX, minY, maxY = minX or 0, maxX or 0, minY or 0, maxY or 0;
            if(data.grow == "CIRCLE") then
                local originX, originY = region:GetCenter();
                originX = originX or 0;
                originY = originY or 0;
                if(originX - minX > maxX - originX) then
                    maxX = originX + (originX - minX);
                elseif(originX - minX < maxX - originX) then
                    minX = originX - (maxX - originX);
                end
                if(originY - minY > maxY - originY) then
                    maxY = originY + (originY - minY);
                elseif(originY - minY < maxY - originY) then
                    minY = originY - (maxY - originY);
                end
            end
            region:Show();
            local newWidth, newHeight = maxX - minX, maxY - minY;
            newWidth = newWidth > 0 and newWidth or 16;
            newHeight = newHeight > 0 and newHeight or 16;
            region:SetWidth(newWidth);
            region.currentWidth = newWidth;
            region:SetHeight(newHeight);
            region.currentHeight = newHeight;
            if(data.animate and region.previousWidth and region.previousHeight) then
                local anim = {
                    type = "custom",
                    duration = 0.2,
                    use_scale = true,
                    scalex = region.previousWidth / newWidth,
                    scaley = region.previousHeight / newHeight
                };

                WeakAuras.Animate("group", data.id, "start", anim, region, true);
            end
            region.previousWidth = newWidth;
            region.previousHeight = newHeight;
        else
            if(data.animate) then
                local anim = {
                    type = "custom",
                    duration = 0.2,
                    use_scale = true,
                    scalex = 0.1,
                    scaley = 0.1
                };

                WeakAuras.Animate("group", data.id, "finish", anim, region, nil, function()
                    region:Hide();
                end)
            else
                region:Hide();
            end
            region.previousWidth = 1;
            region.previousHeight = 1;
        end

        if(WeakAuras.IsOptionsOpen()) then
            WeakAuras.OptionsFrame().moversizer:ReAnchor();
        end
    end

    function region:PositionChildren()
        region:EnsureTrays();
        local childId, childData, childRegion;
        local xOffset, yOffset = 0, 0;
        local currentWidth, currentHeight = 0, 0;
        local numVisible = 0;

        for index, regionData in pairs(region.controlledRegions) do
            childId = regionData.id;
            childData = regionData.data;
            childRegion = regionData.region;
            if(childData and childRegion) then
                if(childRegion.toShow or  WeakAuras.IsAnimating(childRegion) == "finish") then
                    numVisible = numVisible + 1;
                    if(data.grow == "HORIZONTAL") then
                        currentWidth = currentWidth + childData.width;
                    elseif(data.grow == "VERTICAL") then
                        currentHeight = currentHeight + childData.height;
                    end
                end
            end
        end

        if not(data.grow == "CIRCLE") then
            if(data.grow == "RIGHT" or data.grow == "LEFT" or data.grow == "HORIZONTAL") then
                if(data.align == "LEFT" and data.stagger > 0) then
                    yOffset = yOffset - (data.stagger * (numVisible - 1));
                elseif(data.align == "RIGHT" and data.stagger < 0) then
                    yOffset = yOffset - (data.stagger * (numVisible - 1));
                elseif(data.align == "CENTER") then
                    if(data.stagger < 0) then
                        yOffset = yOffset - (data.stagger * (numVisible - 1) / 2);
                    else
                        yOffset = yOffset - (data.stagger * (numVisible - 1) / 2);
                    end
                end
            else
                if(data.align == "LEFT" and data.stagger < 0) then
                    xOffset = xOffset - (data.stagger * (numVisible - 1));
                elseif(data.align == "RIGHT" and data.stagger > 0) then
                    xOffset = xOffset - (data.stagger * (numVisible - 1));
                elseif(data.align == "CENTER") then
                    if(data.stagger < 0) then
                        xOffset = xOffset - (data.stagger * (numVisible - 1) / 2);
                    else
                        xOffset = xOffset - (data.stagger * (numVisible - 1) / 2);
                    end
                end
            end
        end

        if(data.grow == "HORIZONTAL") then
            currentWidth = currentWidth + (data.space * max(numVisible - 1, 0));
            region:SetWidth(currentWidth > 0 and currentWidth or 1);
            xOffset = -currentWidth/2;
        elseif(data.grow == "VERTICAL") then
            currentHeight = currentHeight + (data.space * max(numVisible - 1, 0));
            region:SetHeight(currentHeight > 0 and currentHeight or 1);
            yOffset = currentHeight/2;
        end

        local angle = data.rotation or 0;
        local angleInc = 360 / (numVisible ~= 0 and numVisible or 1);
        local radius = 0;
        if(data.grow == "CIRCLE") then
            if(data.constantFactor == "RADIUS") then
                radius = data.radius;
            else
                if(numVisible <= 1) then
                    radius = 0;
                else
                    radius = (numVisible * data.space) / (2 * math.pi);
                end
            end
        end
        for index, regionData in pairs(region.controlledRegions) do
            childId = regionData.id;
            childData = regionData.data;
            childRegion = regionData.region;
            if(childData and childRegion) then
                if(childRegion.toShow or  WeakAuras.IsAnimating(childRegion) == "finish") then
                    if(data.grow == "CIRCLE") then
                        yOffset = cos(angle) * radius * -1;
                        xOffset = sin(angle) * radius;
                        angle = angle + angleInc;
                    end
                    if(data.grow == "HORIZONTAL") then
                        xOffset = xOffset + childData.width/2;
                    end
                    if(data.grow == "VERTICAL") then
                        yOffset = yOffset - childData.height / 2;
                    end
                    region.trays[regionData.key]:ClearAllPoints();
                    region.trays[regionData.key]:SetPoint(selfPoint, region, selfPoint, xOffset, yOffset);
                    childRegion:ClearAllPoints();
                    childRegion:SetPoint(selfPoint, region.trays[regionData.key], selfPoint);
                    if(data.grow == "RIGHT") then
                        xOffset = xOffset + (childData.width + data.space);
                        yOffset = yOffset + data.stagger;
                    elseif(data.grow == "HORIZONTAL") then
                        xOffset = xOffset + (childData.width) / 2 + data.space;
                        yOffset = yOffset + data.stagger;
                    elseif(data.grow == "LEFT") then
                        xOffset = xOffset - (childData.width + data.space);
                        yOffset = yOffset + data.stagger;
                    elseif(data.grow == "UP") then
                        yOffset = yOffset + (childData.height + data.space);
                        xOffset = xOffset + data.stagger;
                    elseif(data.grow == "DOWN" ) then
                        yOffset = yOffset - (childData.height + data.space);
                        xOffset = xOffset + data.stagger;
                    elseif(data.grow == "VERTICAL") then
                        yOffset = yOffset - childData.height / 2 - data.space;
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
                    elseif(data.grow == "CIRCLE") then
                        hiddenYOffset = cos(angle - angleInc) * radius * -1;
                        hiddenXOffset = sin(angle - angleInc) * radius;
                    end

                    region.trays[regionData.key]:ClearAllPoints();
                    region.trays[regionData.key]:SetPoint(selfPoint, region, selfPoint, hiddenXOffset, hiddenYOffset);
                    childRegion:ClearAllPoints();
                    childRegion:SetPoint(selfPoint, region.trays[regionData.key], selfPoint);
                end
            end
        end

        region:DoResize();
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
            local previousX, previousY = region.trays[regionData.key]:GetCenter();
            previousX = previousX or 0;
            previousY = previousY or 0;
            previous[regionData.key] = {x = previousX, y = previousY};
        end

        region:PositionChildren();

        local previousPreviousX, previousPreviousY;
        for index, regionData in pairs(region.controlledRegions) do
            local childId = regionData.id;
            local childData = regionData.data;
            local childRegion = regionData.region;
            if(childData and childRegion) then
                if (childRegion.toShow or WeakAuras.IsAnimating(childRegion) == "finish") then
                  childRegion:Show();
                end
                local xOffset, yOffset = region.trays[regionData.key]:GetCenter();
                xOffset = xOffset or 0;
                yOffset = yOffset or 0;
                local previousX, previousY = previous[regionData.key] and previous[regionData.key].x or previousPreviousX or 0, previous[regionData.key] and previous[regionData.key].y or previousPreviousY or 0;
                local xDelta, yDelta = previousX - xOffset, previousY - yOffset;
                previousPreviousX, previousPreviousY = previousX, previousY;
                if((childRegion.toShow or  WeakAuras.IsAnimating(childRegion) == "finish") and data.animate and not(abs(xDelta) < 0.1 and abs(yDelta) == 0.1)) then
                    local anim;
                    if(data.grow == "CIRCLE") then
                        local originX, originY = region:GetCenter();
                        local radius1, previousAngle = WeakAuras.GetPolarCoordinates(previousX, previousY, originX, originY);
                        local radius2, newAngle = WeakAuras.GetPolarCoordinates(xOffset, yOffset, originX, originY);
                        local dAngle = newAngle - previousAngle;
                        dAngle = (
                            (dAngle > 180 and dAngle - 360)
                            or (dAngle < -180 and dAngle + 360)
                            or dAngle
                        );
                        if(math.abs(radius1 - radius2) > 0.1) then
                            local translateFunc = [[
                                return function(progress, _, _, previousAngle, dAngle)
                                    local previousRadius, dRadius = %f, %f;
                                    local radius = previousRadius + (1 - progress) * dRadius;
                                    local angle = previousAngle + (1 - progress) * dAngle;
                                    return cos(angle) * radius, sin(angle) * radius;
                                end
                            ]]
                            anim = {
                                type = "custom",
                                duration = 0.2,
                                use_translate = true,
                                translateType = "custom",
                                translateFunc = translateFunc:format(radius1, radius2 - radius1),
                                x = previousAngle,
                                y = dAngle
                            };
                        else
                            local translateFunc = [[
                                return function(progress, _, _, previousAngle, dAngle)
                                    local radius = %f;
                                    local angle = previousAngle + (1 - progress) * dAngle;
                                    return cos(angle) * radius, sin(angle) * radius;
                                end
                            ]]
                            anim = {
                                type = "custom",
                                duration = 0.2,
                                use_translate = true,
                                translateType = "custom",
                                translateFunc = translateFunc:format(radius1),
                                x = previousAngle,
                                y = dAngle
                            };
                        end
                    end
                    if not(anim) then
                        anim = {
                            type = "custom",
                            duration = 0.2,
                            use_translate = true,
                            x = xDelta,
                            y = yDelta
                        };
                    end

                    WeakAuras.CancelAnimation(region.trays[regionData.key], nil, nil, nil, nil, nil, true);
                    WeakAuras.Animate("tray"..regionData.key, data.id, "tray", anim, region.trays[regionData.key], true, function() end);
                elseif (not childRegion.toShow) then
                    if(WeakAuras.IsAnimating(childRegion) == "finish") then
                        -- childRegion will be hidden by its own animation, so it does not need to be hidden immediately
                    else
                        childRegion:Hide();
                    end
                end
            end
        end
    end

    region:PositionChildren();

    -- Adjust frame-level sorting
    local lowestRegion = WeakAuras.regions[data.controlledChildren[#data.controlledChildren]] and WeakAuras.regions[data.controlledChildren[#data.controlledChildren]].region
    if(lowestRegion) then
        local frameLevel = lowestRegion:GetFrameLevel()
        for i=1,#region.controlledRegions do
            local childRegion = region.controlledRegions[i].region
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

    data.width = region.currentWidth;
    data.height = region.currentHeight;

    function region:Scale(scalex, scaley)
        region:SetWidth((region.currentWidth or 16) * scalex);
        region:SetHeight((region.currentHeight or 16) * scaley);
    end
end

WeakAuras.RegisterRegionType("dynamicgroup", create, modify, default);
