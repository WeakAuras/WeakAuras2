local SharedMedia = LibStub("LibSharedMedia-3.0");

-- GLOBALS: WeakAuras UIParent

local default = {
    displayText = "%p",
    outline = "OUTLINE",
    color = {1, 1, 1, 1},
    justify = "LEFT",
    selfPoint = "BOTTOM",
    anchorPoint = "CENTER",
    anchorFrameType = "SCREEN",
    xOffset = 0,
    yOffset = 0,
    font = "Friz Quadrata TT",
    fontSize = 12,
    frameStrata = 1,
    customTextUpdate = "update"
};

local function create(parent)
    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);

    local text = region:CreateFontString(nil, "OVERLAY");
    region.text = text;
    text:SetNonSpaceWrap(true);

    region.values = {};
    region.duration = 0;
    region.expirationTime = math.huge;

    return region;
end

local function modify(parent, region, data)
    local text = region.text;

    region.useAuto = WeakAuras.CanHaveAuto(data);

    local fontPath = SharedMedia:Fetch("font", data.font);
    text:SetFont(fontPath, data.fontSize, data.outline);
    if not text:GetFont() then -- Font invalid, set the font but keep the setting
        text:SetFont("Fonts\\FRIZQT__.TTF", data.fontSize, data.outline);
    end
    if text:GetFont() then
        text:SetText(data.displayText);
    end
    text.displayText = data.displayText;
    text:SetJustifyH(data.justify);

    text:ClearAllPoints();
    text:SetPoint("CENTER", UIParent, "CENTER");

    data.width = text:GetWidth();
    data.height = text:GetHeight();
    region:SetWidth(data.width);
    region:SetHeight(data.height);

    text:SetTextHeight(data.fontSize);

    text:ClearAllPoints();
    text:SetPoint(data.justify, region, data.justify);

    region:ClearAllPoints();
    local anchorFrame = WeakAuras.GetAnchorFrame(data.id, data.anchorFrameType, parent, data.anchorFrameFrame);
    region:SetParent(anchorFrame);
    region:SetPoint(data.selfPoint, anchorFrame, data.anchorPoint, data.xOffset, data.yOffset);
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

    local function SetText(textStr)
      if(textStr ~= text.displayText) then
          if text:GetFont() then
            text:SetText(textStr);
          end
      end
      if(#textStr ~= #text.displayText) then
          data.width = text:GetWidth();
          data.height = text:GetHeight();
          region:SetWidth(data.width);
          region:SetHeight(data.height);
          if(data.parent and WeakAuras.regions[data.parent].region.ControlChildren) then
              WeakAuras.regions[data.parent].region:ControlChildren();
          else
              region:ClearAllPoints();
              local anchorFrame = WeakAuras.GetAnchorFrame(data.id, data.anchorFrameType, parent, data.anchorFrameFrame);
              region:SetParent(anchorFrame);
              region:SetPoint(data.selfPoint, anchorFrame, data.anchorPoint, data.xOffset, data.yOffset);
          end
      end
      text.displayText = textStr;
    end

    local UpdateText;
    if (data.displayText:find('%%')) then
        UpdateText = function()
            local textStr = data.displayText;
            textStr = WeakAuras.ReplacePlaceHolders(textStr, region.values, region.state);
            if (textStr == nil or textStr == "") then
              textStr = " ";
            end

            SetText(textStr)
        end
    else
      UpdateText = function() end
    end

    local customTextFunc = nil
    if(data.displayText:find("%%c") and data.customText) then
        customTextFunc = WeakAuras.LoadFunction("return "..data.customText)
    end
    if (customTextFunc) then
        local values = region.values;
        region.UpdateCustomText = function()
            WeakAuras.ActivateAuraEnvironment(region.id, region.cloneId, region.state);
            local custom = customTextFunc(region.expirationTime, region.duration,
              values.progress, values.duration, values.name, values.icon, values.stacks);
            WeakAuras.ActivateAuraEnvironment(nil);
            custom = WeakAuras.EnsureString(custom);
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

    function region:Color(r, g, b, a)
        region.color_r = r;
        region.color_g = g;
        region.color_b = b;
        region.color_a = a;
        text:SetTextColor(r, g, b, a);
    end

    function region:GetColor()
        return region.color_r or data.color[1], region.color_g or data.color[2],
               region.color_b or data.color[3], region.color_a or data.color[4];
    end

    region:Color(data.color[1], data.color[2], data.color[3], data.color[4]);

    local function UpdateTime()
        local remaining = region.expirationTime - GetTime();
        local progress
        if region.duration > 0 then
            progress = remaining / region.duration;
            if(data.inverse) then
                progress = 1 - progress;
            end
            progress = progress > 0.0001 and progress or 0.0001;
        end

        local remainingStr = "";
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
            durationStr = "INF";
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
        UpdateValue(region.customValueFunc(region.state.trigger));
    end

    function region:SetDurationInfo(duration, expirationTime, customValue)
        if(duration <= 0.01 or duration > region.duration or not data.stickyDuration) then
            region.duration = duration;
        end
        region.expirationTime = expirationTime;

        if(customValue) then
            if(type(customValue) == "function") then
                local value, total = customValue(region.state.trigger);
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
                UpdateTime();
            end
        end
    end

    function region:SetStacks(count)
        if(count and count > 0) then
            region.values.stacks = count;
        else
            region.values.stacks = 0;
        end
        UpdateText();
    end

    function region:SetIcon(path)
        local icon = (
            region.useAuto
            and path
            and path ~= ""
            and path
            or data.displayIcon
            or "Interface\\Icons\\INV_Misc_QuestionMark"
        );
        region.values.icon = "|T"..icon..":12:12:0:0:64:64:4:60:4:60|t";
        UpdateText();
    end

    function region:SetName(name)
        region.values.name = name or data.id;
        UpdateText();
    end
    if (data.displayText:find('%%')) then
      UpdateText();
    else
      SetText(data.displayText);
    end
end

WeakAuras.RegisterRegionType("text", create, modify, default);

-- Fallback region type

local function fallbackmodify(parent, region, data)
    local text = region.text;

    text:SetFont("Fonts\\FRIZQT__.TTF", data.fontSize, data.outline and "OUTLINE" or nil);
    if text:GetFont() then
        text:SetText(WeakAuras.L["Region type %s not supported"]:format(data.regionType));
    end

    text:ClearAllPoints();
    text:SetPoint("CENTER", region, "CENTER");

    region:SetWidth(text:GetWidth());
    region:SetHeight(text:GetHeight());

    region:ClearAllPoints();
    local anchorFrame = WeakAuras.GetAnchorFrame(data.id, data.anchorFrameType, parent, data.anchorFrameFrame);
    region:SetParent(anchorFrame);
    region:SetPoint(data.selfPoint, anchorFrame, data.anchorPoint, data.xOffset, data.yOffset);
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end
end

WeakAuras.RegisterRegionType("fallback", create, fallbackmodify, default);
