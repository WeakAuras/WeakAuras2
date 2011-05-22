local SharedMedia = LibStub("LibSharedMedia-3.0");
    
local default = {
    icon = true,
    auto = true,
    timer = true,
    text = true,
    displayTextRight = "%p",
    displayTextLeft = "%n",
    texture = "Blizzard",
    width = 200,
    height = 15,
    orientation = "HORIZONTAL",
    inverse = false,
    alpha = 1.0,
    border = "None",
    borderOffset = 16,
    barColor = {1, 0, 0, 1},
    backgroundColor = {0, 0, 0, 0.5},
    textColor = {1, 1, 1, 1},
    selfPoint = "CENTER",
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0,
    font = "Friz Quadrata TT",
    fontSize = 12,
    stickyDuration = false,
    icon_side = "RIGHT",
    stacks = true,
    rotateText = "NONE",
    frameStrata = 1,
    customTextUpdate = "update"
};

local function create(parent)
    local font = "GameFontHighlight";
    
    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    region:SetResizable(true);
    region:SetMinResize(1, 1);
    
    local bar = CreateFrame("statusbar", nil, region);
    bar:SetMinMaxValues(0, 1);
    region.bar = bar;
    
    local background = bar:CreateTexture(nil, "BACKGROUND");
    region.background = background;
    
    local border = CreateFrame("frame", nil, region);
    region.border = border;
    
    local timer = bar:CreateFontString(nil, "OVERLAY", font);
    region.timer = timer;
    timer:SetText("0.0");
    timer:SetNonSpaceWrap(true);
    timer:SetPoint("center");
    
    local text = bar:CreateFontString(nil, "OVERLAY", font);
    region.text = text;
    text:SetText("Error");
    text:SetNonSpaceWrap(true);
    text:SetPoint("center");
    
    local icon = region:CreateTexture(nil, "OVERLAY");
    region.icon = icon;
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    
    local stacks = bar:CreateFontString(nil, "OVERLAY", font);
    region.stacks = stacks;
    stacks:SetText(1);
    stacks:ClearAllPoints();
    stacks:SetPoint("CENTER", icon, "CENTER");
    
    region.values = {};
    region.duration = 0;
    region.expirationTime = math.huge;
    
    return region;
end

local function stoprotation(self)
    self:Pause();
end

local function animRotate(object, degrees)
    if(object.animationGroup or degrees ~= 0) then
        object.animationGroup = object.animationGroup or object:CreateAnimationGroup();
        local ag = object.animationGroup;
        ag.rotate = ag.rotate or ag:CreateAnimation("rotation");
        local r = ag.rotate;
        
        ag:Stop();
        r:Stop();
        
        if(degrees ~= 0) then
            r:SetOrigin(point or "center", xo or 0, yo or 0);
            r:SetDegrees(degrees);
            r:SetDuration(0);
            r:SetEndDelay(0.1);
            r:SetScript("OnUpdate", stoprotation);
            r:Play();
            ag:Play();
        end
    end
end
WeakAuras.animRotate = animRotate;

local function getRotateOffset(object, degrees, point)
    if(degrees ~= 0) then
        local xo, yo;
        local originoffset = object:GetStringHeight() / 2;
        xo = -1 * originoffset * sin(degrees);
        yo = originoffset * (cos(degrees) - 1);
        if(point == "BOTTOM") then
            yo = yo + (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
        elseif(point == "TOP") then
            yo = yo - (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
        elseif(point == "RIGHT") then
            xo = xo + (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
        elseif(point == "LEFT") then
            xo = xo - (1 - cos(degrees)) * (object:GetStringWidth() / 2 - originoffset);
        end
        
        return xo, yo;
    else
        return 0, 0;
    end
end

local function Hide_Tooltip()
    GameTooltip:Hide();
end

local function modify(parent, region, data)
    local bar, background, border, timer, text, icon, stacks = region.bar, region.background, region.border, region.timer, region.text, region.icon, region.stacks;
    
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end
    
    region:SetWidth(data.width);
    region:SetHeight(data.height);
    
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
    region:SetAlpha(data.alpha);
    
    local texturePath = SharedMedia:Fetch("statusbar", data.texture);
    local fontPath = SharedMedia:Fetch("font", data.font);
    
    background:SetTexture(texturePath);
    background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
    
    local border = region.border;
    local edgeFile = SharedMedia:Fetch("border", data.border or "");
    border:SetBackdrop({
        edgeFile = edgeFile,
        edgeSize = 16
    });
    border:SetPoint("bottomleft", region, "bottomleft", -1 * data.borderOffset, -1 * data.borderOffset);
    border:SetPoint("topright", region, "topright", data.borderOffset, data.borderOffset);
    
    bar:SetStatusBarTexture(texturePath);
    local texture = bar:GetStatusBarTexture();
    
    function region:Color(r, g, b, a)
        region.color_r = r;
        region.color_g = g;
        region.color_b = b;
        region.color_a = a;
        texture:SetVertexColor(r, g, b, a);
    end
    
    function region:GetColor()
        return region.color_r or data.barColor[1], region.color_g or data.barColor[2],
               region.color_b or data.barColor[3], region.color_a or data.barColor[4];
    end
    
    region:Color(data.barColor[1], data.barColor[2], data.barColor[3], data.barColor[4]);
    
    text:SetFont(fontPath, data.fontSize);
    text:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);
    text:SetWordWrap(false);
    
    timer:SetFont(fontPath, data.fontSize);
    timer:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);
    
    local iconsize = math.min(data.height, data.width);
    icon:SetWidth(iconsize);
    icon:SetHeight(iconsize);
    local tooltipType = WeakAuras.CanHaveTooltip(data);
    if(tooltipType and data.useTooltip) then
        region.tooltipFrame = region.tooltipFrame or CreateFrame("frame");
        region.tooltipFrame:SetAllPoints(icon);
        region.tooltipFrame:EnableMouse(true);
        region.tooltipFrame:SetScript("OnEnter", function()
            WeakAuras.ShowMouseoverTooltip(data, region, region.tooltipFrame, tooltipType);
        end);
        region.tooltipFrame:SetScript("OnLeave", WeakAuras.HideTooltip);
    elseif(region.tooltipFrame) then
        region.tooltipFrame:EnableMouse(false);
    end
    
    stacks:SetFont(fontPath, data.fontSize, "OUTLINE");
    stacks:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);
    
    local textDegrees = data.rotateText == "LEFT" and 90 or data.rotateText == "RIGHT" and -90 or 0;
    animRotate(text, textDegrees);
    animRotate(timer, textDegrees);
    animRotate(stacks, textDegrees);
    
    local orientationInverse;
    local xo, yo;
    
    xo, yo = getRotateOffset(stacks, textDegrees, "CENTER");
    stacks:SetPoint("CENTER", icon, "CENTER", xo, yo);
    
    local function orientHorizontalInverse()
        icon:ClearAllPoints();
        background:ClearAllPoints();
        bar:ClearAllPoints();
        region.orientation = "HORIZONTAL_INVERSE";
        bar:SetOrientation("HORIZONTAL");
        background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        orientationInverse = true;
        bar:SetRotatesTexture(false);
        if(data.icon) then
            if(data.icon_side == "LEFT") then
                icon:SetPoint("LEFT", region, "LEFT");
                background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
                bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
                background:SetPoint("TOPLEFT", icon, "TOPRIGHT");
                bar:SetPoint("TOPLEFT", icon, "TOPRIGHT");
            else
                icon:SetPoint("RIGHT", region, "RIGHT");
                background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
                bar:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
                background:SetPoint("TOPRIGHT", icon, "TOPLEFT");
                bar:SetPoint("TOPRIGHT", icon, "TOPLEFT");
            end
        else
            background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
            bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
            background:SetPoint("TOPLEFT", region, "TOPLEFT");
            bar:SetPoint("TOPLEFT", region, "TOPLEFT");
        end
        xo, yo = getRotateOffset(timer, textDegrees, "LEFT");
        timer:ClearAllPoints();
        timer:SetPoint("LEFT", bar, "LEFT", 2 + xo, 0 + yo);
        xo, yo = getRotateOffset(text, textDegrees, "RIGHT");
        text:ClearAllPoints();
        text:SetPoint("RIGHT", bar, "RIGHT", -2 + xo, 0 + yo);
        if(textDegrees == 0) then
            text:SetWidth(bar:GetWidth() - (timer:GetWidth() + (data.fontSize/2)));
            text:SetJustifyH("RIGHT");
        else
            text:SetWidth(0);
            text:SetJustifyH("CENTER");
        end
    end
    local function orientHorizontal()
        icon:ClearAllPoints();
        background:ClearAllPoints();
        bar:ClearAllPoints();
        region.orientation = "HORIZONTAL";
        bar:SetOrientation("HORIZONTAL");
        background:SetTexCoord(0,0 , 0,1 , 1,0 , 1,1);
        bar:SetRotatesTexture(false);
        if(data.icon) then
            if(data.icon_side == "LEFT") then
                icon:SetPoint("LEFT", region, "LEFT");
                background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
                bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
                background:SetPoint("TOPLEFT", icon, "TOPRIGHT");
                bar:SetPoint("TOPLEFT", icon, "TOPRIGHT");
            else
                icon:SetPoint("RIGHT", region, "RIGHT");
                background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
                bar:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
                background:SetPoint("TOPRIGHT", icon, "TOPLEFT");
                bar:SetPoint("TOPRIGHT", icon, "TOPLEFT");
            end
        else
            background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
            bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
            background:SetPoint("TOPLEFT", region, "TOPLEFT");
            bar:SetPoint("TOPLEFT", region, "TOPLEFT");
        end
        xo, yo = getRotateOffset(timer, textDegrees, "RIGHT");
        timer:ClearAllPoints();
        timer:SetPoint("RIGHT", bar, "RIGHT", -2 + xo, 0 + yo);
        xo, yo = getRotateOffset(text, textDegrees, "LEFT");
        text:ClearAllPoints();
        text:SetPoint("LEFT", bar, "LEFT", 2 + xo, 0 + yo);
        if(textDegrees == 0) then
            text:SetWidth(bar:GetWidth() - (timer:GetWidth() + (data.fontSize/2)));
            text:SetJustifyH("LEFT");
        else
            text:SetWidth(0);
            text:SetJustifyH("CENTER");
        end
    end
    local function orientVerticalInverse()
        icon:ClearAllPoints();
        background:ClearAllPoints();
        bar:ClearAllPoints();
        region.orientation = "VERTICAL_INVERSE";
        bar:SetOrientation("VERTICAL");
        background:SetTexCoord(1,0 , 0,0 , 1,1 , 0,1);
        orientationInverse = true;
        bar:SetRotatesTexture(true);
        if(data.icon) then
            if(data.icon_side == "LEFT") then
                icon:SetPoint("TOP", region, "TOP");
                background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
                bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
                background:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
                bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
            else
                icon:SetPoint("BOTTOM", region, "BOTTOM");
                background:SetPoint("TOPRIGHT", region, "TOPRIGHT");
                bar:SetPoint("TOPRIGHT", region, "TOPRIGHT");
                background:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
                bar:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
            end
        else
            background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
            bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
            background:SetPoint("TOPLEFT", region, "TOPLEFT");
            bar:SetPoint("TOPLEFT", region, "TOPLEFT");
        end
        xo, yo = getRotateOffset(timer, textDegrees, "BOTTOM");
        timer:ClearAllPoints();
        timer:SetPoint("BOTTOM", bar, "BOTTOM", 0 + xo, 2 + yo);
        xo, yo = getRotateOffset(text, textDegrees, "TOP");
        text:ClearAllPoints();
        text:SetPoint("TOP", bar, "TOP", 0 + xo, -2 + yo);
        text:SetWidth(0);
        text:SetJustifyH("CENTER");
    end
    local function orientVertical()
        icon:ClearAllPoints();
        background:ClearAllPoints();
        bar:ClearAllPoints();
        region.orientation = "VERTICAL";
        bar:SetOrientation("VERTICAL");
        background:SetTexCoord(1,0 , 0,0 , 1,1 , 0,1);
        bar:SetRotatesTexture(true);
        if(data.icon) then
            if(data.icon_side == "LEFT") then
                icon:SetPoint("TOP", region, "TOP");
                background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
                bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
                background:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
                bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
            else
                icon:SetPoint("BOTTOM", region, "BOTTOM");
                background:SetPoint("TOPRIGHT", region, "TOPRIGHT");
                bar:SetPoint("TOPRIGHT", region, "TOPRIGHT");
                background:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
                bar:SetPoint("BOTTOMLEFT", icon, "TOPLEFT");
            end
        else
            background:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
            bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
            background:SetPoint("TOPLEFT", region, "TOPLEFT");
            bar:SetPoint("TOPLEFT", region, "TOPLEFT");
        end
        xo, yo = getRotateOffset(timer, textDegrees, "TOP");
        timer:ClearAllPoints();
        timer:SetPoint("TOP", bar, "TOP", 0 + xo, -2 + yo);
        xo, yo = getRotateOffset(text, textDegrees, "BOTTOM");
        text:ClearAllPoints();
        text:SetPoint("BOTTOM", bar, "BOTTOM", 0 + xo, 2 + yo);
        text:SetWidth(0);
        text:SetJustifyH("CENTER");
    end
    
    local function orient()
        if(data.orientation == "HORIZONTAL_INVERSE") then
            orientHorizontalInverse();
        elseif(data.orientation == "HORIZONTAL") then
            orientHorizontal();
        elseif(data.orientation == "VERTICAL_INVERSE") then
            orientVerticalInverse();
        elseif(data.orientation == "VERTICAL") then
            orientVertical();
        end
    end
    orient();
    
    local textStr, shouldOrient;
    local function UpdateText()
        shouldOrient = false;
        
        textStr = data.displayTextLeft or "";
        for symbol, v in pairs(WeakAuras.dynamic_texts) do
            textStr = textStr:gsub(symbol, region.values[v.value] or "");
        end
        
        if(not text.displayTextLeft or #text.displayTextLeft ~= #textStr) then
            shouldOrient = true;
        end
        if(text.displayTextLeft ~= textStr) then
            text:SetText(textStr);
            text.displayTextLeft = textStr;
        end
        
        textStr = data.displayTextRight or "";
        for symbol, v in pairs(WeakAuras.dynamic_texts) do
            textStr = textStr:gsub(symbol, region.values[v.value] or "");
        end
        
        if(not timer.displayTextRight or #timer.displayTextRight ~= #textStr) then
            shouldOrient = true;
        end
        if(timer.displayTextLeft ~= textStr) then
            timer:SetText(textStr);
            timer.displayTextLeft = textStr;
        end
        
        if(shouldOrient) then
            orient();
        end
    end
    
    if((data.displayTextLeft:find("%%c") or data.displayTextRight:find("%%c")) and data.customText) then
        local customTextFunc = WeakAuras.LoadFunction("return "..data.customText)
        local values = region.values;
        region.UpdateCustomText = function()
            local custom = customTextFunc(region.expirationTime, region.duration, values.progress, values.duration, values.name, values.icon, values.stacks);
            if(custom ~= values.custom) then
                values.custom = custom;
                UpdateText();
            end
        end
        if(data.customTextUpdate == "update") then
            WeakAuras.RegisterCustomTextUpdates(region);
        else
            WeakAuras.UnregisterCustomTextUpdates(region);
        end
    else
        region.UpdateCustomText = nil;
        WeakAuras.UnregisterCustomTextUpdates(region);
    end
    
    function region:SetStacks(count)
        if(count and count > 0) then
            region.values.stacks = count;
            stacks:SetText(count);
        else
            region.values.stacks = 0;
            stacks:SetText("");
        end
        UpdateText();
    end
    
    function region:Scale(scalex, scaley)
        local icon_mirror_h, icon_mirror_v;
        if(scalex < 0) then
            icon_mirror_h = true;
            scalex = scalex * -1;
            if(data.orientation == "HORIZONTAL") then
                if(region.orientation ~= "HORIZONTAL_INVERSE") then
                    orientHorizontalInverse();
                end
            elseif(data.orientation == "HORIZONTAL_INVERSE") then
                if(region.orientation ~= "HORIZONTAL") then
                    orientHorizontal();
                end
            else
                region.mirror_h = true;
            end
        else
            if(data.orientation == "HORIZONTAL") then
                if(region.orientation ~= "HORIZONTAL") then
                    orientHorizontal();
                end
            elseif(data.orientation == "HORIZONTAL_INVERSE") then
                if(region.orientation ~= "HORIZONTAL_INVERSE") then
                    orientHorizontalInverse();
                end
            else
                region.mirror_h = false;
            end
        end
        region:SetWidth(data.width * scalex);
        icon:SetWidth(iconsize * scalex);
        if(scaley < 0) then
            icon_mirror_v = true;
            scaley = scaley * -1;
            if(data.orientation == "VERTICAL") then
                if(region.orientation ~= "VERTICAL_INVERSE") then
                    orientVerticalInverse();
                end
            elseif(data.orientation == "VERTICAL_INVERSE") then
                if(region.orientation ~= "VERTICAL") then
                    orientVertical();
                end
            else
                region.mirror_v = true;
            end
        else
            if(data.orientation == "VERTICAL") then
                if(region.orientation ~= "VERTICAL") then
                    orientVertical();
                end
            elseif(data.orientation == "VERTICAL_INVERSE") then
                if(region.orientation ~= "VERTICAL_INVERSE") then
                    orientVerticalInverse();
                end
            else
                region.mirror_v = false;
            end
        end
        region:SetHeight(data.height * scaley);
        icon:SetHeight(iconsize * scaley);
    end
    
    if(data.timer) then
        timer:Show();
    else
        timer:Hide();
    end
    if(data.icon) then
        function region:SetIcon(path)
            local iconPath = (
                WeakAuras.CanHaveAuto(data)
                and data.auto
                and path ~= ""
                and path
                or data.displayIcon
                or "Interface\\Icons\\INV_Misc_QuestionMark"
            );
            icon:SetTexture(iconPath);
            region.values.icon = "|T"..iconPath..":12:12:0:0:64:64:4:60:4:60|t";
            UpdateText();
        end
        if(data.stacks) then
            stacks:Show();
        else
            stacks:Hide();
        end
        icon:Show();
    else
        stacks:Hide();
        icon:Hide();
    end
    if(data.text) then
        text:Show();
    else
        text:Hide();
    end
    
    function region:SetName(name)
        region.values.name = WeakAuras.CanHaveAuto(data) and name or data.id;
        UpdateText();
    end
    
    local displayValue, remaining, progress, remainingStr, shouldOrient;
    --local CPUUsage = 0;
    local function UpdateTime(self, elaps, inverse)
        --debugprofilestart();
        remaining = region.expirationTime - GetTime();
        progress = remaining / region.duration;
        
        if(
            (
                not orientationInverse and (
                    (data.inverse and not inverse) 
                    or (inverse and not data.inverse)
                )
            )
            or (
                orientationInverse and not (
                    (data.inverse and not inverse) 
                    or (inverse and not data.inverse)
                )
            )
        ) then
            progress = 1 - progress;
        end
        progress = progress > 0.0001 and progress or 0.0001;
        bar:SetValue(progress);
        
        remainingStr = "";
        if(remaining == math.huge) then
            remainingStr = " ";
        elseif(remaining > 60) then
            remainingStr = string.format("%i:", math.floor(remaining / 60));
            remaining = remaining % 60;
            remainingStr = remainingStr..string.format("%02i", remaining);
        elseif(remaining > 0) then
            remainingStr = remainingStr..string.format("%."..(data.progressPrecision or 1).."f", remaining);
        else
            remainingStr = " ";
        end
        region.values.progress = remainingStr;
        
        local duration = region.duration;
        local durationStr = "";
        if(duration > 60) then
            durationStr = string.format("%i:", math.floor(duration / 60));
            duration = duration % 60;
            durationStr = durationStr..string.format("%02i", duration);
        elseif(duration > 0) then
            durationStr = durationStr..string.format("%."..(data.totalPrecision or 1).."f", duration);
        else
            durationStr = " ";
        end
        region.values.duration = durationStr;
        UpdateText();
        --CPUUsage = CPUUsage + debugprofilestop();
    end
    
    local function UpdateTimeInverse(self, elaps)
        --debugprofilestart();
        UpdateTime(self, elaps, true);
        --CPUUsage = CPUUsage + debugprofilestop();
    end
    
    local function UpdateValue(value, total)
        debugprofilestart();
        progress = 1
        if(total > 0) then
            progress = value / total;
        end
        if((not orientationInverse and data.inverse) or (orientationInverse and not data.inverse)) then
            progress = 1 - progress;
        end
        progress = progress > 0.0001 and progress or 0.0001;
        region.values.progress = value;
        region.values.duration = total;
        UpdateText();
        bar:SetValue(progress);
        --CPUUsage = CPUUsage + debugprofilestop();
    end
    
    local function UpdateCustom()
        debugprofilestart();
        UpdateValue(region.customValueFunc(data.trigger));
        --CPUUsage = CPUUsage + debugprofilestop();
    end
    
    function region:SetDurationInfo(duration, expirationTime, customValue, inverse)
        if(duration <= 0.01 or duration > region.duration or not data.stickyDuration) then
            region.duration = duration;
        end
        region.expirationTime = expirationTime;
        
        if(customValue) then
            if(type(customValue) == "function") then
                local value, total = customValue(data.trigger);
                if(total > 0 and value < total) then
                    region.customValueFunc = customValue;
                    region:SetScript("OnUpdate", UpdateCustom);
                else
                    UpdateValue(duration, expirationTime);
                    region:SetScript("OnUpdate", nil);
                end
            else
                UpdateValue(duration, expirationTime);
                region:SetScript("OnUpdate", nil);
            end
        else
            if(duration > 0.01) then
                if(inverse) then
                    region:SetScript("OnUpdate", UpdateTimeInverse);
                else
                    region:SetScript("OnUpdate", UpdateTime);
                end
            else
                bar:SetValue(1);
                region:SetScript("OnUpdate", nil);
                UpdateTime();
            end
        end
    end
    
    --function region:GetCPUUsage()
    --    return CPUUsage;
    --end
end

WeakAuras.RegisterRegionType("aurabar", create, modify, default);