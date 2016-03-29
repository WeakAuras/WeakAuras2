-- Import SM for statusbar-textures, font-styles and border-types
local SharedMedia = LibStub("LibSharedMedia-3.0");

-- Import translation
local L = WeakAuras.L;
    
-- Create region options table
local function createOptions(id, data)
	-- Region options
    local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;
    local options = {
        texture = {
            type = "select",
            dialogControl = "LSM30_Statusbar",
            order = 0,
            width = "double",
            name = L["Bar Texture"],
            values = AceGUIWidgetLSMlists.statusbar
        },
        displayTextLeft = {
            type = "input",
            name = function()
                if(data.orientation == "HORIZONTAL") then
                    return L["Left Text"];
                elseif(data.orientation == "HORIZONTAL_INVERSE") then
                    return L["Right Text"];
                elseif(data.orientation == "VERTICAL") then
                    return L["Bottom Text"];
                else
                    return L["Top Text"];
                end
            end,
            desc = L["Dynamic text tooltip"],
            order = 9
        },
        displayTextRight = {
            type = "input",
            name = function()
                if(data.orientation == "HORIZONTAL") then
                    return L["Right Text"];
                elseif(data.orientation == "HORIZONTAL_INVERSE") then
                    return L["Left Text"];
                elseif(data.orientation == "VERTICAL") then
                    return L["Top Text"];
                else
                    return L["Bottom Text"];
                end
            end,
            desc = L["Dynamic text tooltip"],
            order = 10
        },
        customTextUpdate = {
            type = "select",
            width = "double",
            hidden = function()
                return not (
                    data.displayTextLeft:find("%%c")
                    or data.displayTextRight:find("%%c")
                );
            end,
            name = L["Update Custom Text On..."],
            values = WeakAuras.text_check_types,
            order = 10.1
        },
        customText = {
            type = "input",
            width = "normal",
            hidden = function()
                return not (
                    data.displayTextLeft:find("%%c")
                    or data.displayTextRight:find("%%c")
                );
            end,
            multiline = true,
            name = L["Custom Function"],
            order = 10.2
        },
        customText_expand = {
            type = "execute",
            order = 10.3,
            name = L["Expand Text Editor"],
            func = function()
                WeakAuras.TextEditor(data, {"customText"})
            end,
            hidden = function()
                return not (
                    data.displayTextLeft:find("%%c")
                    or data.displayTextRight:find("%%c")
                );
            end
        },
        progressPrecision = {
            type = "select",
            order = 11,
            name = L["Remaining Time Precision"],
            values = WeakAuras.precision_types,
            get = function() return data.progressPrecision or 1 end,
            hidden = function()
                return not (
                    data.displayTextLeft:find("%%p")
                    or data.displayTextLeft:find("%%t")
                    or data.displayTextRight:find("%%p")
                    or data.displayTextRight:find("%%t")
                );
            end,
            disabled = function()
                return not (
                    data.displayTextLeft:find("%%p")
                    or data.displayTextRight:find("%%p")
                );
            end,
        },
        totalPrecision = {
            type = "select",
            order = 11.5,
            name = L["Total Time Precision"],
            values = WeakAuras.precision_types,
            get = function() return data.totalPrecision or 1 end,
            hidden = function()
                return not (
                    data.displayTextLeft:find("%%p")
                    or data.displayTextLeft:find("%%t")
                    or data.displayTextRight:find("%%p")
                    or data.displayTextRight:find("%%t")
                );
            end,
            disabled = function()
                return not (
                    data.displayTextLeft:find("%%t")
                    or data.displayTextRight:find("%%t")
                );
            end,
        },
        rotateText = {
            type = "select",
            name = L["Rotate Text"],
            values = WeakAuras.text_rotate_types,
            order = 19.5
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
                    
                    if(data.rotateText == "LEFT" or data.rotateText == "RIGHT") then
                        data.rotateText = "NONE";
                    elseif(data.rotateText == "NONE") then
                        data.rotateText = "LEFT"
                    end
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
            order = 35
        },
        stickyDuration = {
            type = "toggle",
            name = L["Sticky Duration"],
            desc = L["Prevents duration information from decreasing when an aura refreshes. May cause problems if used with multiple auras with different durations."],
            order = 36
        },
        useTooltip = {
            type = "toggle",
            name = L["Tooltip on Mouseover"],
            hidden = function() return not WeakAuras.CanHaveTooltip(data) end,
            order = 37
        },
        symbol_header = {
            type = "header",
            name = L["Symbol Settings"],
            order = 38
        },
        icon = {
            type = "toggle",
            name = L["Icon"],
            order = 38.1
        },
        auto = {
            type = "toggle",
            name = L["Auto"],
            desc = L["Choose whether the displayed icon is automatic or defined manually"],
            order = 38.2,
            disabled = function() return not WeakAuras.CanHaveAuto(data); end,
            get = function() return WeakAuras.CanHaveAuto(data) and data.auto end,
            hidden = function() return not data.icon end,
        },
        displayIcon = {
            type = "input",
            name = L["Display Icon"],
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto or not data.icon; end,
            disabled = function() return not data.icon end,
            order = 38.3,
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
        displaySpace = {
            type = "execute",
            name = "",
            width = "half",
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto or not data.icon; end,
            image = function() return data.displayIcon or "", 18, 18 end,
            order = 38.4
        },
        chooseIcon = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            hidden = function() return WeakAuras.CanHaveAuto(data) and data.auto or not data.icon; end,
            disabled = function() return not data.icon end,
            order = 38.5,
            func = function() WeakAuras.OpenIconPick(data, "displayIcon"); end
        },
        icon_side = {
            type = "select",
            name = L["Icon"],
            values = WeakAuras.icon_side_types,
            hidden = function() return data.orientation:find("VERTICAL") or not data.icon end,
            order = 38.6,
        },
        icon_side2 = {
            type = "select",
            name = L["Icon"],
            values = WeakAuras.rotated_icon_side_types,
            hidden = function() return data.orientation:find("HORIZONTAL") or not data.icon end,
            order = 38.7,
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
        desaturate = {
            type = "toggle",
            name = L["Desaturate"],
            order = 38.8,
            hidden = function() return not data.icon end,
        },
        icon_color = {
            type = "color",
            name = L["Icon Color"],
            hasAlpha = true,
            order = 38.9,
            hidden = function() return not data.icon end,
        },
        zoom = {
            type = "range",
            name = L["Zoom"],
            order = 38.91,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true,
            hidden = function() return not data.icon end,
        },
		bar_header = {
			type = "header",
			name = L["Bar Color Settings"],
			order = 39
		},
        barColor = {
            type = "color",
            name = L["Bar Color"],
            hasAlpha = true,
            order = 39.5
        },
        backgroundColor = {
            type = "color",
            name = L["Background Color"],
            hasAlpha = true,
            order = 40
        },
        alpha = {
            type = "range",
            name = L["Bar Alpha"],
            order = 41,
            min = 0,
            max = 1,
            bigStep = 0.01,
            isPercent = true
        },
        spark_header = {
            type = "header",
            name = L["Spark Settings"],
            order = 42
        },
        spark = {
            type = "toggle",
            name = L["Spark"],
            order = 43
        },
        sparkTexture = {
            type = "input",
            name = L["Spark Texture"],
            order = 44,
            width = "double",
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkDesaturate = {
            type = "toggle",
            name = L["Desaturate"],
            order = 44.1,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        spaceSpark = {
            type = "execute",
            name = "",
            width = "half",
            order = 44.2,
            image = function() return "", 0, 0 end,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkChooseTexture = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            order = 44.3,
            func = function()
                WeakAuras.OpenTexturePick(data, "sparkTexture", WeakAuras.texture_types);
            end,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkColor = {
            type = "color",
            name = L["Color"],
            hasAlpha = true,
            order = 44.4,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkBlendMode = {
            type = "select",
            name = L["Blend Mode"],
            order = 44.5,
            values = WeakAuras.blend_types,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkWidth = {
            type = "range",
            name = L["Width"],
            order = 44.6,
            min = 1,
            softMax = screenWidth,
            bigStep = 1,
			disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkHeight = {
            type = "range",
            name = L["Height"],
            order = 44.7,
            min = 1,
            softMax = screenHeight,
            bigStep = 1,
			disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkOffsetX = {
            type = "range",
            name = L["X Offset"],
            order = 44.8,
            min = -screenWidth,
            max = screenWidth,
            bigStep = 1,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkOffsetY = {
            type = "range",
            name = L["Y Offset"],
            order = 44.9,
            min = -screenHeight,
            max = screenHeight,
            bigStep = 1,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkRotationMode = {
            type = "select",
            values = WeakAuras.spark_rotation_types,
            name = L["Rotation Mode"],
            order = 45,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkRotation = {
            type = "range",
            name = L["Rotation"],
            min = 0,
            max = 360,
            step = 90,
            order = 45.1,
            disabled = function() return not data.spark or data.sparkRotationMode == "AUTO" end,
            hidden = function() return not data.spark or data.sparkRotationMode == "AUTO" end,
        },
        sparkMirror = {
            type = "toggle",
            name = L["Mirror"],
            order = 45.2,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
        sparkHidden = {
            type = "select",
            values = WeakAuras.spark_hide_types,
            name = L["Hide on"],
            order = 45.3,
            disabled = function() return not data.spark end,
            hidden = function() return not data.spark end,
        },
		border_header = {
			type = "header",
			name = L["Border Settings"],
			order = 46.0
		},
		barInFront  = {
            type = "toggle",
            name = L["Bar in Front"],
            order = 46.7,
            disabled = function() return not data.border end,
            hidden = function() return not data.border end,
        },
		text_header = {
			type = "header",
            name = function()
                if(data.orientation == "HORIZONTAL") then
                    return L["Left Text"];
                elseif(data.orientation == "HORIZONTAL_INVERSE") then
                    return L["Right Text"];
                elseif(data.orientation == "VERTICAL") then
                    return L["Bottom Text"];
                else
                    return L["Top Text"];
                end
            end,
			order = 47
		},
        text = {
            type = "toggle",
            name = function()
                if(data.orientation == "HORIZONTAL") then
                    return L["Left Text"];
                elseif(data.orientation == "HORIZONTAL_INVERSE") then
                    return L["Right Text"];
                elseif(data.orientation == "VERTICAL") then
                    return L["Bottom Text"];
                else
                    return L["Top Text"];
                end
            end,
            order = 47.5
        },
        textColor = {
            type = "color",
            name = L["Text Color"],
            hasAlpha = true,
            order = 48,
            disabled = function() return not data.text end,
            hidden = function() return not data.text end,
        },
        textFont = {
            type = "select",
            dialogControl = "LSM30_Font",
            name = L["Font Type"],
            order = 49,
            values = AceGUIWidgetLSMlists.font,
            disabled = function() return not data.text end,
            hidden = function() return not data.text end,
        },
        textSize = {
            type = "range",
            name = L["Font Size"],
            order = 50,
            min = 6,
            softMax = 72,
            step = 1,
            disabled = function() return not data.text end,
            hidden = function() return not data.text end,
        },
        textFlags = {
            type = "select",
            name = L["Font Flags"],
            order = 51,
            values = WeakAuras.font_flags,
            disabled = function() return not data.text end,
            hidden = function() return not data.text end,
        },
		timer_header = {
			type = "header",
            name = function()
                if(data.orientation == "HORIZONTAL") then
                    return L["Right Text"];
                elseif(data.orientation == "HORIZONTAL_INVERSE") then
                    return L["Left Text"];
                elseif(data.orientation == "VERTICAL") then
                    return L["Top Text"];
                else
                    return L["Bottom Text"];
                end
            end,
			order = 52
		},
        timer = {
            type = "toggle",
            name = function()
                if(data.orientation == "HORIZONTAL") then
                    return L["Right Text"];
                elseif(data.orientation == "HORIZONTAL_INVERSE") then
                    return L["Left Text"];
                elseif(data.orientation == "VERTICAL") then
                    return L["Top Text"];
                else
                    return L["Bottom Text"];
                end
            end,
            order = 52.5
        },
        timerColor = {
            type = "color",
            name = L["Text Color"],
            hasAlpha = true,
            order = 53,
            disabled = function() return not data.timer end,
            hidden = function() return not data.timer end,
        },
        timerFont = {
            type = "select",
            dialogControl = "LSM30_Font",
            name = L["Font Type"],
            order = 54,
            values = AceGUIWidgetLSMlists.font,
            disabled = function() return not data.timer end,
            hidden = function() return not data.timer end,
        },
        timerSize = {
            type = "range",
            name = L["Font Size"],
            order = 55,
            min = 6,
            softMax = 72,
            step = 1,
            disabled = function() return not data.timer end,
            hidden = function() return not data.timer end,
        },
        timerFlags = {
            type = "select",
            name = L["Font Flags"],
            order = 56,
            values = WeakAuras.font_flags,
            disabled = function() return not data.timer end,
            hidden = function() return not data.timer end,
        },
		stacks_header = {
			type = "header",
			name = L["Stacks Settings"],
			order = 57.1
		},
        stacks = {
            type = "toggle",
            name = L["Stacks"],
            order = 57.2
        },
		stacksColor = {
            type = "color",
            name = L["Text Color"],
            hasAlpha = true,
            order = 57.3,
            disabled = function() return not data.stacks end,
            hidden = function() return not data.stacks end,
        },
        stacksFont = {
            type = "select",
            dialogControl = "LSM30_Font",
            name = L["Font Type"],
            order = 57.4,
            values = AceGUIWidgetLSMlists.font,
            disabled = function() return not data.stacks end,
            hidden = function() return not data.stacks end,
        },
        stacksSize = {
            type = "range",
            name = L["Font Size"],
            order = 57.5,
            min = 6,
            softMax = 72,
            step = 1,
            disabled = function() return not data.stacks end,
            hidden = function() return not data.stacks end,
        },
		stacksFlags = {
            type = "select",
            name = L["Font Flags"],
            order = 57.6,
            values = WeakAuras.font_flags,
            disabled = function() return not data.stacks end,
            hidden = function() return not data.stacks end,
        },
        spacer = {
            type = "header",
            name = "",
            order = 58
        },
    };
    
	-- Positioning options
	options = WeakAuras.AddPositionOptions(options, id, data);
	
	-- Border options
	options = WeakAuras.AddBorderOptions(options, id, data);
    
	-- Return options
    return options;
end

-- Create preview thumbnail
local function createThumbnail(parent, fullCreate)
	-- Preview frame
    local borderframe = CreateFrame("FRAME", nil, parent);
    borderframe:SetWidth(32);
    borderframe:SetHeight(32);
    
	-- Preview border
    local border = borderframe:CreateTexture(nil, "OVERLAY");
    border:SetAllPoints(borderframe);
    border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
    border:SetTexCoord(0.2, 0.8, 0.2, 0.8);
    
	-- Main region
    local region = CreateFrame("FRAME", nil, borderframe);
    borderframe.region = region;
    region:SetWidth(32);
    region:SetHeight(32);
    
	-- Status-bar frame
    local bar = CreateFrame("FRAME", nil, region);
    borderframe.bar = bar;
    
	-- Fake status-bar
    local texture = bar:CreateTexture(nil, "OVERLAY");
    borderframe.texture = texture;
    
	-- Fake icon
    local icon = region:CreateTexture();
    borderframe.icon = icon;
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    
	-- Return preview
    return borderframe;
end

-- Modify preview thumbnail
local function modifyThumbnail(parent, borderframe, data, fullModify, width, height)
	-- Localize
    local region, bar, texture, icon = borderframe.region, borderframe.bar, borderframe.texture, borderframe.icon;
    
	-- Defaut size
    width  = width or 26;
    height = height or 15;
    
	-- Fake orientation (main region)
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
    
	-- Fake bar alpha
    region:SetAlpha(data.alpha);
    
	-- Fake status-bar style
    texture:SetTexture(SharedMedia:Fetch("statusbar", data.texture));
    texture:SetVertexColor(data.barColor[1], data.barColor[2], data.barColor[3], data.barColor[4]);
    
	-- Fake icon size
    local iconsize = height;
    icon:SetWidth(iconsize);
    icon:SetHeight(iconsize);
    
	-- Fake layout variables
    local percent, length;
    if(data.icon) then
        length = width - height;
        percent = 1 - (width / 100);
    else
        length = width;
        percent = 1 - (width / 100);
    end
	
	-- Reset region members
    icon:ClearAllPoints();
    bar:ClearAllPoints();
    texture:ClearAllPoints();
	
	-- Fake orientation (region members)
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
    
	-- Fake icon (code)
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

-- Create "new region" preview
local function createIcon()
	-- Default data
    local data = {
        icon = true,
        auto = true,
        texture = "Runes",
        orientation = "HORIZONTAL",
        alpha = 1.0,
        barColor = {1, 0, 0, 1}
    };
    
	-- Create and configure thumbnail
    local thumbnail = createThumbnail(UIParent);
    modifyThumbnail(UIParent, thumbnail, data, nil, 32, 18);
    thumbnail:SetIcon("Interface\\Icons\\INV_Sword_122");
    
	-- Return thumbnail
    return thumbnail;
end

-- Register new region type options with WeakAuras
WeakAuras.RegisterRegionOptions("aurabar", createOptions, createIcon, L["Progress Bar"], createThumbnail, modifyThumbnail, L["Shows a progress bar with name, timer, and icon"]);