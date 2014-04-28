local SharedMedia = LibStub("LibSharedMedia-3.0");
local LBF = nil --LibStub("LibButtonFacade",true);

local borderOffset = 0.06

local default = {
    icon = true,
--	iconInset = 0.0,
--	BFskin = "Blizzard",
--	BFgloss = 0.0,
--	BFbackdrop = false,
	desaturate = false,
    auto = true,
    inverse = false,
    width = 64,
    height = 64,
    color = {1, 1, 1, 1},
    textColor = {1, 1, 1, 1},
    displayStacks = "%s",
    stacksPoint = "BOTTOMRIGHT",
    stacksContainment = "INSIDE",
    selfPoint = "CENTER",
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0,
    font = "Friz Quadrata TT",
    fontFlags = "OUTLINE",
    fontSize = 12,
    stickyDuration = false,
    zoom = 0,
    frameStrata = 1,
    customTextUpdate = "update"
};

local function SkinChanged(skinID, gloss, backdrop, colors, button)

end

local function create(parent, data)
    local font = "GameFontHighlight";
    
    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    region:SetResizable(true);
    region:SetMinResize(1, 1);
    
	local button
	if LBF then
		button = CreateFrame("Button", nil, region, "UIPanelButtonTemplate")
		button.data = data
		region.button = button;
		button:EnableMouse(false);
		button:Disable();
		button:SetAllPoints();
		
		LBF:RegisterSkinCallback("WeakAuras", SkinChanged)
	end
	
	local icon = region:CreateTexture(nil, "BACKGROUND");
	if LBF then
		icon:SetAllPoints(button);
	else
		icon:SetAllPoints(region);
	end
    region.icon = icon;
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    
    --This section creates a unique frame id for the cooldown frame so that it can be created with a global reference
    --The reason is so that WeakAuras cooldown frames can interact properly with OmniCC (i.e., put on its blacklist for timer overlays)
    local id = data.id;
    local frameId = id:lower():gsub(" ", "_");
    if(_G[frameId]) then
        local baseFrameId = frameId;
        local num = 2;
        while(_G[frameId]) do
            frameId = baseFrameId..num;
            num = num + 1;
        end
    end
	region.frameId = frameId;
	
    local cooldown = CreateFrame("COOLDOWN", "WeakAurasCooldown"..frameId, region);
    region.cooldown = cooldown;
    cooldown:SetAllPoints(icon);
    
    local stacksFrame = CreateFrame("frame", nil, region);
    stacksFrame:SetFrameLevel(cooldown:GetFrameLevel() + 1);
    local stacks = stacksFrame:CreateFontString(nil, "OVERLAY");
    region.stacks = stacks;
    
    region.values = {};
    region.duration = 0;
    region.expirationTime = math.huge;

    return region;
end

local function modify(parent, region, data)
    local button, icon, cooldown, stacks = region.button, region.icon, region.cooldown, region.stacks;
	
	if LBF and not region.LBFGroup then
		region.LBFGroup = LBF:Group("WeakAuras", region.frameId);
		region.LBFGroup:Skin(data.BFskin, data.BFgloss, data.BFbackdrop);
		region.LBFGroup:AddButton(button, {Icon = icon, Cooldown = cooldown});
		
		button.data = data
	end

    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end
    
    region:SetWidth(data.width);
    region:SetHeight(data.height);
	if LBF then
		button:SetAllPoints();
	end
	icon:SetAllPoints();
	
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
    
    local fontPath = SharedMedia:Fetch("font", data.font);
    local sxo, syo = 0, 0;
    if(data.stacksPoint:find("LEFT")) then
        sxo = data.width / 10;
    elseif(data.stacksPoint:find("RIGHT")) then
        sxo = data.width / -10;
    end
    if(data.stacksPoint:find("BOTTOM")) then
        syo = data.height / 10;
    elseif(data.stacksPoint:find("TOP")) then
        syo = data.height / -10;
    end
    stacks:ClearAllPoints();
    if(data.stacksContainment == "INSIDE") then
        stacks:SetPoint(data.stacksPoint, icon, data.stacksPoint, sxo, syo);
    else
        local selfPoint = WeakAuras.inverse_point_types[data.stacksPoint];
        stacks:SetPoint(selfPoint, icon, data.stacksPoint, -0.5 * sxo, -0.5 * syo);
    end
    stacks:SetFont(fontPath, data.fontSize, data.fontFlags == "MONOCHROME" and "OUTLINE, MONOCHROME" or data.fontFlags);
    stacks:SetTextColor(data.textColor[1], data.textColor[2], data.textColor[3], data.textColor[4]);

    local texWidth = 0.25 * data.zoom;
	
	local bo
	if region.LBFGroup then
		region.LBFGroup:ReSkin();
		bo = borderOffset
		
		icon:SetWidth(icon:GetWidth()   - bo * icon:GetWidth()  * UIParent:GetScale() * data.iconInset*10)
		icon:SetHeight(icon:GetHeight() - bo * icon:GetHeight() * UIParent:GetScale() * data.iconInset*10)
	else
		bo = 0.0
	end
	icon:SetTexCoord(texWidth + bo, 1 - bo - texWidth, texWidth + bo, 1 - bo - texWidth);
    
    local tooltipType = WeakAuras.CanHaveTooltip(data);
    if(tooltipType and data.useTooltip) then
        region:EnableMouse(true);
        region:SetScript("OnEnter", function()
            WeakAuras.ShowMouseoverTooltip(data, region, region, tooltipType);
        end);
        region:SetScript("OnLeave", WeakAuras.HideTooltip);
    else
        region:EnableMouse(false);
    end
    
    cooldown:SetReverse(not data.inverse);
    
    function region:Color(r, g, b, a)
        region.color_r = r;
        region.color_g = g;
        region.color_b = b;
        region.color_a = a;
        icon:SetVertexColor(r, g, b, a);
		if LBF then
			button:SetAlpha(a);
		end
    end
    
    function region:GetColor()
        return region.color_r or data.color[1], region.color_g or data.color[2],
               region.color_b or data.color[3], region.color_a or data.color[4];
    end
    
    region:Color(data.color[1], data.color[2], data.color[3], data.color[4]);
    
    local textStr;
    local function UpdateText()
        textStr = data.displayStacks or "";
        for symbol, v in pairs(WeakAuras.dynamic_texts) do
            textStr = textStr:gsub(symbol, region.values[v.value] or "");
        end
        
        if(stacks.displayStacks ~= textStr) then
            if stacks:GetFont() then
                stacks:SetText(textStr);
                stacks.displayStacks = textStr;
            else end
        end
    end
    
    if(data.displayStacks:find("%%c") and data.customText) then
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
        else
            region.values.stacks = " ";
        end
        UpdateText();
    end
    
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
		icon:SetDesaturated(data.desaturate);
        region.values.icon = "|T"..iconPath..":12:12:0:0:64:64:4:60:4:60|t";
        UpdateText();
    end
	region:SetIcon()
	
    function region:SetName(name)
        region.values.name = WeakAuras.CanHaveAuto(data) and name or data.id;
        UpdateText();
    end
    
    local function UpdateTime()
        local remaining = region.expirationTime - GetTime();
        local progress = remaining / region.duration;
        
        if(data.inverse) then
            progress = 1 - progress;
        end
        progress = progress > 0.0001 and progress or 0.0001;
        
        local remainingStr = "";
        if(remaining == math.huge) then
            remainingStr = " ";
        elseif(remaining > 60) then
            remainingStr = string.format("%i:", math.floor(remaining / 60));
            remaining = remaining % 60;
            remainingStr = remainingStr..string.format("%02i", remaining);
        elseif(remaining > 0) then
            -- remainingStr = remainingStr..string.format("%."..(data.progressPrecision or 1).."f", remaining);
            if data.progressPrecision == 4 and remaining <= 3 then
                remainingStr = remainingStr..string.format("%.1f", remaining);
            elseif data.progressPrecision == 5 and remaining <= 3 then
                remainingStr = remainingStr..string.format("%.2f", remaining);
            elseif (data.progressPrecision == 4 or data.progressPrecision == 5) and remaining > 3 then
                remainingStr = remainingStr..string.format("%d", remaining);
            else 
                remainingStr = remainingStr..string.format("%."..(data.progressPrecision or 1).."f", remaining);
            end
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
            -- durationStr = durationStr..string.format("%."..(data.totalPrecision or 1).."f", duration);
            if data.totalPrecision == 4 and duration <= 3 then
                durationStr = durationStr..string.format("%.1f", duration);
            elseif data.totalPrecision == 5 and duration <= 3 then
                durationStr = durationStr..string.format("%.2f", duration);
            elseif (data.totalPrecision == 4 or data.totalPrecision == 5) and duration > 3 then
                durationStr = durationStr..string.format("%d", duration);
            else 
                durationStr = durationStr..string.format("%."..(data.totalPrecision or 1).."f", duration);
            end
        else
            durationStr = " ";
        end
        region.values.duration = durationStr;
        UpdateText();
    end
    
    local function UpdateValue(value, total)
        region.values.progress = value;
        region.values.duration = total;
        UpdateText();
    end
    
    local function UpdateCustom()
        UpdateValue(region.customValueFunc(data.trigger));
    end
    
    local function UpdateDurationInfo(duration, expirationTime, customValue)
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
                    UpdateText();
                end
            else
                UpdateValue(duration, expirationTime);
                region:SetScript("OnUpdate", nil);
            end
        else
            if(duration > 0.01) then
                region:SetScript("OnUpdate", UpdateTime);
            else
                region:SetScript("OnUpdate", nil);
                UpdateText();
            end
        end
    end
    
    function region:Scale(scalex, scaley)
        local mirror_h, mirror_v;
        if(scalex < 0) then
            mirror_h = true;
			scalex = scalex * -1;
        end
        region:SetWidth(data.width * scalex);
        if(scaley < 0) then
            mirror_v = true;
            scaley = scaley * -1;
        end
        region:SetHeight(data.height * scaley);
		if LBF then
			button:SetAllPoints();
		end
		icon:SetAllPoints();
		
		local texWidth = 0.25 * data.zoom;
		local bo
		if region.LBFGroup then
			region.LBFGroup:ReSkin();
			bo = borderOffset;
			
			icon:SetWidth(icon:GetWidth()   - bo * icon:GetWidth()  * UIParent:GetScale() * data.iconInset*10)
			icon:SetHeight(icon:GetHeight() - bo * icon:GetHeight() * UIParent:GetScale() * data.iconInset*10)
		else
			bo = 0.0;
		end
		
        if(mirror_h) then
            if(mirror_v) then
                icon:SetTexCoord(1-bo-texWidth, 1-bo-texWidth , 1-bo-texWidth, texWidth+bo,    texWidth+bo, 1-bo-texWidth, texWidth+bo, texWidth+bo);
            else
                icon:SetTexCoord(1-bo-texWidth, texWidth+bo,    1-bo-texWidth, 1-bo-texWidth , texWidth+bo, texWidth+bo,   texWidth+bo, 1-bo-texWidth);
            end
        else
            if(mirror_v) then
                icon:SetTexCoord(texWidth+bo, 1-bo-texWidth, texWidth+bo, texWidth+bo,    1-bo-texWidth, 1-bo-texWidth, 1-bo-texWidth, texWidth+bo);
            else
                icon:SetTexCoord(texWidth+bo, bo+texWidth,   texWidth+bo, 1-bo-texWidth , 1-bo-texWidth, texWidth+bo,   1-bo-texWidth, 1-bo-texWidth);
            end
        end
    end
    
    if(data.cooldown and WeakAuras.CanHaveDuration(data) == "timed") then
        function region:SetDurationInfo(duration, expirationTime, customValue)
            if(duration <= 0.01 or duration > region.duration or not data.stickyDuration) then
                region.duration = duration;
            end
            if(customValue or duration <= 0.01) then
                cooldown:Hide();
            else
                cooldown:Show();
                cooldown:SetCooldown(expirationTime - region.duration, region.duration);
            end
            UpdateDurationInfo(duration, expirationTime, customValue)
        end
    else
        cooldown:Hide();
        function region:SetDurationInfo(duration, expirationTime, customValue)
            UpdateDurationInfo(duration, expirationTime, customValue)
        end
    end
end

WeakAuras.RegisterRegionType("icon", create, modify, default);