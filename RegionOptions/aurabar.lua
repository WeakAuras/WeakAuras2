local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L
    
local function createOptions(id, data)
    local options = {
        texture = {
            type = "select",
            dialogControl = "LSM30_Statusbar",
            order = 0,
            width = "double",
            name = L["Bar Texture"],
            values = AceGUIWidgetLSMlists.statusbar
        },
        text = {
            type = "toggle",
            name = L["Text"],
            desc = "Set the visibility of the aura name",
            width = "half",
            order = 4
        },
        timer = {
            type = "toggle",
            name = L["Timer"],
            desc = "Set the visibility of the timer",
            width = "half",
            order = 2,
            disabled = function() return not WeakAuras.CanHaveDuration(data); end,
            get = function() return WeakAuras.CanHaveDuration(data) and data.timer; end
        },
        icon = {
            type = "toggle",
            name = L["Icon"],
            desc = "Set the visibility of the aura icon",
            width = "half",
            order = 6
        },
        auto = {
            type = "toggle",
            name = L["Auto"],
            desc = "Choose whether the displayed text and icon are automatic or pre-defined",
            width = "half",
            order = 8,
            disabled = function() return not WeakAuras.CanHaveAuto(data); end,
            get = function() return WeakAuras.CanHaveAuto(data) and data.auto end
        },
        displayText = {
            type = "input",
            name = L["Display Text"],
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
            disabled = function() return not data.text end,
            order = 10
        },
        displayIcon = {
            type = "input",
            name = L["Display Icon"],
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
            disabled = function() return not data.icon end,
            order = 12,
            get = function()
                if(data.displayIcon) then
                    return data.displayIcon:sub(17);
                else
                    return nil;
                end
            end,
            set = function(info, v)
                data.displayIcon = "Interface\\Icons\\"..v;
                WeakAuras.Add(data);
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
            end
        },
        displaySpace1 = {
            type = "execute",
            name = "",
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
            image = function() return "", 0, 0 end,
            order = 14
        },
        displaySpace2 = {
            type = "execute",
            name = "",
            width = "half",
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
            image = function() return data.displayIcon or "", 18, 18 end,
            order = 16
        },
        chooseIcon = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto; end,
            disabled = function() return not data.icon end,
            order = 18,
            func = function() WeakAuras.OpenIconPick(data, "displayIcon"); end
        },
        orientation = {
            type = "select",
            name = L["Orientation"],
            order = 25,
            values = WeakAuras.orientation_types,
            set = function(info, v)
                if(
                    (
                        data.orientation:find("INVERSE")
                        and not v:find("INVERSE")
                    ) 
                    or (
                        v:find("INVERSE")
                        and not data.orientation:find("INVERSE")
                    )
                ) then
                    data.icon_side = data.icon_side == "LEFT" and "RIGHT" or "LEFT";
                end
                
                if(
                    (
                        data.orientation:find("HORIZONTAL")
                        and v:find("VERTICAL")
                    )
                    or (
                        data.orientation:find("VERTICAL")
                        and v:find("HORIZONTAL")
                    )
                ) then
                    local temp = data.width;
                    data.width = data.height;
                    data.height = temp;
                    data.icon_side = data.icon_side == "LEFT" and "RIGHT" or "LEFT";
                end
                data.orientation = v;
                WeakAuras.Add(data);
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
                WeakAuras.ResetMoverSizer();
            end
        },
        inverse = {
            type = "toggle",
            name = L["Inverse"],
            width = "half",
            order = 35
        },
        icon_side = {
            type = "select",
            name = L["Icon"],
            width = "half",
            values = WeakAuras.icon_side_types,
            hidden = function() return not data.orientation:find("HORIZONTAL") end,
            order = 37
        },
        icon_side2 = {
            type = "select",
            name = L["Icon"],
            width = "half",
            values = WeakAuras.rotated_icon_side_types,
            hidden = function() return data.orientation:find("HORIZONTAL") end,
            order = 37,
            get = function()
                return data.icon_side;
            end,
            set = function(info, v)
                data.icon_side = v;
                WeakAuras.Add(data);
                WeakAuras.SetThumbnail(data);
                WeakAuras.SetIconNames(data);
            end
        },
        barColor = {
            type = "color",
            name = L["Bar Color"],
            hasAlpha = true,
            order = 20
        },
        backgroundColor = {
            type = "color",
            name = L["Background Color"],
            hasAlpha = true,
            order = 30
        },
        textColor = {
            type = "color",
            name = L["Text Color"],
            hasAlpha = true,
            order = 40
        },
        alpha = {
            type = "range",
            name = L["Bar Alpha"],
            order = 42,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true
        },
        font = {
            type = "select",
            dialogControl = "LSM30_Font",
            name = L["Font"],
            order = 45,
            values = AceGUIWidgetLSMlists.font
        },
        fontSize = {
            type = "range",
            name = L["Size"],
            order = 47,
            min = 6,
            max = 25,
            step = 1
        },
        stacks = {
            type = "toggle",
            name = L["Stacks"],
            order = 48
        },
        stickyDuration = {
            type = "toggle",
            name = L["Sticky Duration"],
            desc = L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."],
            order = 49
        },
        spacer = {
            type = "header",
            name = "",
            order = 50
        }
    };
    options = WeakAuras.AddPositionOptions(options, id, data);
    
    return options;
end

local function createThumbnail(parent, fullCreate)
    local borderframe = CreateFrame("FRAME", nil, parent);
    borderframe:SetWidth(32);
    borderframe:SetHeight(32);
    
    local border = borderframe:CreateTexture(nil, "OVERLAY");
    border:SetAllPoints(borderframe);
    border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
    border:SetTexCoord(0.2, 0.8, 0.2, 0.8);
    
    local region = CreateFrame("FRAME", nil, borderframe);
    borderframe.region = region;
    region:SetWidth(32);
    region:SetHeight(32);
    
    local bar = CreateFrame("FRAME", nil, region);
    borderframe.bar = bar;
    
    local texture = bar:CreateTexture(nil, "OVERLAY");
    borderframe.texture = texture;
    
    local icon = region:CreateTexture();
    borderframe.icon = icon;
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    
    return borderframe;
end

local function modifyThumbnail(parent, borderframe, data, fullModify, width, height)
    local region, bar, texture, icon = borderframe.region, borderframe.bar, borderframe.texture, borderframe.icon;
    
    width = width or 26;
    height = height or 15;
    
    if(data.orientation:find("HORIZONTAL")) then
        region:SetWidth(width);
        region:SetHeight(height);
        region:ClearAllPoints();
        if(data.orientation == "HORIZONTAL_INVERSE") then
            region:SetPoint("RIGHT", borderframe, "RIGHT", -2, 0);
        else
            region:SetPoint("LEFT", borderframe, "LEFT", 2, 0);
        end
    else
        region:SetWidth(height);
        region:SetHeight(width);
        region:ClearAllPoints();
        if(data.orientation == "VERTICAL_INVERSE") then
            region:SetPoint("TOP", borderframe, "TOP", 0, -2);
        else
            region:SetPoint("BOTTOM", borderframe, "BOTTOM", 0, 2);
        end
    end
    
    region:SetAlpha(data.alpha);
    
    local texturePath = SharedMedia:Fetch("statusbar", data.texture);
    texture:SetTexture(texturePath);
    
    texture:SetVertexColor(data.barColor[1], data.barColor[2], data.barColor[3], data.barColor[4]);
    
    local iconsize = height;
    icon:SetWidth(iconsize);
    icon:SetHeight(iconsize);
    
    local percent, length;
    if(data.icon) then
        length = width - height;
        percent = 1 - (width / 100);
    else
        length = width;
        percent = 1 - (width / 100);
    end
    icon:ClearAllPoints();
    bar:ClearAllPoints();
    texture:ClearAllPoints();
    if(data.orientation == "HORIZONTAL_INVERSE") then
        icon:SetPoint("LEFT", region, "LEFT");
        bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        if(data.icon) then
            bar:SetPoint("TOPLEFT", icon, "TOPRIGHT");
        else
            bar:SetPoint("TOPLEFT", region, "TOPLEFT");
        end
        texture:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT");
        texture:SetPoint("TOPRIGHT", bar, "TOPRIGHT");
        texture:SetTexCoord(1, 0, 1, 1, percent, 0, percent, 1);
        texture:SetWidth(length);
    elseif(data.orientation == "HORIZONTAL") then
        icon:SetPoint("RIGHT", region, "RIGHT");
        bar:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT");
        if(data.icon) then
            bar:SetPoint("TOPRIGHT", icon, "TOPLEFT");
        else
            bar:SetPoint("TOPRIGHT", region, "TOPRIGHT");
        end
        texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT");
        texture:SetPoint("TOPLEFT", bar, "TOPLEFT");
        texture:SetTexCoord(percent, 0, percent, 1, 1, 0, 1, 1);
        texture:SetWidth(length);
    elseif(data.orientation == "VERTICAL_INVERSE") then
        icon:SetPoint("BOTTOM", region, "BOTTOM");
        bar:SetPoint("TOPLEFT", region, "TOPLEFT");
        if(data.icon) then
            bar:SetPoint("BOTTOMRIGHT", icon, "TOPRIGHT");
        else
            bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        end
        texture:SetPoint("TOPLEFT", bar, "TOPLEFT");
        texture:SetPoint("TOPRIGHT", bar, "TOPRIGHT");
        texture:SetTexCoord(percent, 0, 1, 0, percent, 1, 1, 1);
        texture:SetHeight(length);
    elseif(data.orientation == "VERTICAL") then
        icon:SetPoint("TOP", region, "TOP");
        bar:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT");
        if(data.icon) then
            bar:SetPoint("TOPLEFT", icon, "BOTTOMLEFT");
        else
            bar:SetPoint("TOPLEFT", region, "TOPLEFT");
        end
        texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT");
        texture:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT");
        texture:SetTexCoord(1, 0, percent, 0, 1, 1, percent, 1);
        texture:SetHeight(length);
    end
    
    if(data.icon) then
        function borderframe:SetIcon(path)
            local success = icon:SetTexture(data.auto and path or data.displayIcon) and (data.auto and path or data.displayIcon);
            if not(success) then
                icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            end
        end
        icon:Show();
    else
        icon:Hide();
    end
end

local function createIcon()
    local data = {
        icon = true,
        auto = true,
        texture = "Runes",
        orientation = "HORIZONTAL",
        alpha = 1.0,
        barColor = {1, 0, 0, 1}
    };
    
    local thumbnail = createThumbnail(UIParent);
    modifyThumbnail(UIParent, thumbnail, data, nil, 32, 18);
    thumbnail:SetIcon("Interface\\Icons\\INV_Sword_122");
    
    return thumbnail;
end

WeakAuras.RegisterRegionOptions("aurabar", createOptions, createIcon, L["Progress Bar"], createThumbnail, modifyThumbnail, L["Shows a progress bar with name, timer, and icon"]);