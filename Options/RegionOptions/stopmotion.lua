local L = WeakAuras.L

local function createOptions(id, data)
    local options = {
        foregroundTexture = {
            type = "input",
            name = L["Texture"],
            order = 0
        },
        backgroundTexture = {
            type = "input",
            name = L["Background Texture"],
            order = 5,
            disabled = function() return data.sameTexture; end,
            get = function() return data.sameTexture and data.foregroundTexture or data.backgroundTexture; end
        },
        mirror = {
            type = "toggle",
            width = "half",
            name = L["Mirror"],
            order = 10
        },
        chooseForegroundTexture = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            order = 12,
            func = function()
                WeakAuras.OpenTexturePick(data, "foregroundTexture", WeakAuras.texture_types_stop_motion, true);
            end
        },
        sameTexture = {
            type = "toggle",
            name = L["Same"],
            width = "half",
            order = 15
        },
        chooseBackgroundTexture = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            order = 17,
            func = function()
                WeakAuras.OpenTexturePick(data, "backgroundTexture", WeakAuras.texture_types_stop_motion, true);
            end,
            disabled = function() return data.sameTexture; end
        },
        desaturateForeground = {
            type = "toggle",
            name = L["Desaturate"],
            order = 17.5,
        },
        desaturateBackground = {
            type = "toggle",
            name = L["Desaturate"],
            order = 17.6,
        },
        blendMode = {
            type = "select",
            name = L["Blend Mode"],
            order = 20,
            values = WeakAuras.blend_types
        },
        animationType = {
            type = "select",
            name = L["Animation Mode"],
            order = 21,
            values = WeakAuras.stopmotion_animation_types
        },
        startFrame = {
            type = "range",
            name = L["Start Frame"],
            min = 1,
            max = 100,
            step = 1,
            bigStep = 1,
            order = 22,
        },
        endFrame = {
            type = "range",
            name = L["End Frame"],
            min = 1,
            max = 512,
            step = 1,
            bigStep = 1,
            order = 23,
        },
        frameRate = {
           type = "range",
           name = L["Frame Rate"],
           min = 5,
           max = 60,
           step = 1,
           bigStep = 3,
           order = 24,
        },
        backgroundFrame = {
            type = "range",
            name = L["Background Frame"],
            min = 1,
            max = 512,
            step = 1,
            bigStep = 1,
            order = 25,
        },
        foregroundColor = {
            type = "color",
            name = L["Foreground Color"],
            hasAlpha = true,
            order = 30
        },
        backgroundColor = {
            type = "color",
            name = L["Background Color"],
            hasAlpha = true,
            order = 32
        },
        inverse = {
            type = "toggle",
            name = L["Inverse"],
            order = 33
        },
        space3 = {
            type = "execute",
            name = "",
            order = 36,
            image = function() return "", 0, 0 end,
        },
        rotate = {
            type = "toggle",
            name = L["Allow Full Rotation"],
            order = 37
        },
        rotation = {
            type = "range",
            name = L["Rotation"],
            min = 0,
            max = 360,
            step = 1,
            bigStep = 3,
            order = 41,
            hidden = function() return not data.rotate end
        },
        discrete_rotation = {
            type = "range",
            name = L["Discrete Rotation"],
            min = 0,
            max = 360,
            step = 90,
            order = 42,
            hidden = function() return data.rotate end
        },
        spacer = {
            type = "header",
            name = "",
            order = 43
        }
        -- TODO backgroundOffset, user_x, user_y, corp_x, crop_y
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

    local texture = borderframe:CreateTexture();
    borderframe.texture = texture;
    texture:SetPoint("CENTER", borderframe, "CENTER");

    return borderframe;
end

local function modifyThumbnail(parent, region, data, fullModify, size)
    size = size or 30;
    local scale;
    if(data.height > data.width) then
        scale = size/data.height;
        region.texture:SetWidth(scale * data.width);
        region.texture:SetHeight(size);
    else
        scale = size/data.width;
        region.texture:SetWidth(size);
        region.texture:SetHeight(scale * data.height);
    end

    local frame = 1;
	if (data.startFrame and data.endFrame) then
	  frame = floor(data.startFrame + data.endFrame / 2);
	end
    region.texture:SetTexture((data.foregroundTexture or "Interface\\AddOns\\WeakAuras\\Media\\StopMotion\\circle") .. format("%03d", frame));
    region.texture:SetVertexColor(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);
    region.texture:SetBlendMode(data.blendMode);

    local ulx,uly , llx,lly , urx,ury , lrx,lry;
    if(data.rotate) then
        local angle = rad(135 - data.rotation);
        local vx = math.cos(angle);
        local vy = math.sin(angle);

        ulx,uly , llx,lly , urx,ury , lrx,lry = 0.5+vx,0.5-vy , 0.5-vy,0.5-vx , 0.5+vy,0.5+vx , 0.5-vx,0.5+vy;
    else
        if(data.discrete_rotation == 0 or data.discrete_rotation == 360) then
            ulx,uly , llx,lly , urx,ury , lrx,lry = 0,0 , 0,1 , 1,0 , 1,1;
        elseif(data.discrete_rotation == 90) then
            ulx,uly , llx,lly , urx,ury , lrx,lry = 1,0 , 0,0 , 1,1 , 0,1;
        elseif(data.discrete_rotation == 180) then
            ulx,uly , llx,lly , urx,ury , lrx,lry = 1,1 , 1,0 , 0,1 , 0,0;
        elseif(data.discrete_rotation == 270) then
            ulx,uly , llx,lly , urx,ury , lrx,lry = 0,1 , 1,1 , 0,0 , 1,0;
        end
    end
    if(data.mirror) then
        region.texture:SetTexCoord(urx,ury , lrx,lry , ulx,uly , llx,lly);
    else
        region.texture:SetTexCoord(ulx,uly , llx,lly , urx,ury , lrx,lry);
    end
    
    region.SetValue = function(self, percent) 
      local frame = percent * (data.endFrame - data.startFrame) + data.startFrame;
      self.texture:SetTexture((data.foregroundTexture) .. format("%03d", frame));
    end
    
end

local function createIcon()
    local data = {
        height = 40,
        width = 40,
        foregroundTexture = "Interface\\AddOns\\WeakAuras\\Media\\StopMotion\\circle",
        foregroundColor = {1, 1, 1, 1},
        blendMode = "ADD",
        rotate = true,
        rotation = 0,
        startFrame = 1,
        endFrame = 101,
        animationType = "progress"
    };

    local thumbnail = createThumbnail(UIParent);
    modifyThumbnail(UIParent, thumbnail, data, nil, 50);
    
    thumbnail.elapsed = 0;
    thumbnail:SetScript("OnUpdate", function(self, elapsed)
        thumbnail.elapsed = thumbnail.elapsed + elapsed;
        if(thumbnail.elapsed > 4) then
            thumbnail.elapsed = thumbnail.elapsed - 4;
        end
        thumbnail:SetValue(thumbnail.elapsed / 4);
    end);

    return thumbnail;
end

WeakAuras.RegisterRegionOptions("stopmotion", createOptions, createIcon, L["Stop Motion"], createThumbnail, modifyThumbnail, L["Shows a stop motion textures"]);