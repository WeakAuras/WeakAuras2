local L = WeakAuras.L

-- GLOBALS: WeakAuras UIParent AceGUIWidgetLSMlists

local function createOptions(id, data)
    local options = {
        texture = {
            type = "input",
            width = "double",
            name = L["Texture"],
            order = 0
        },
		desaturate = {
            type = "toggle",
            name = L["Desaturate"],
            order = 2,
        },
        space2 = {
            type = "execute",
            name = "",
            width = "half",
            order = 5,
            image = function() return "", 0, 0 end,
        },
        chooseTexture = {
            type = "execute",
            name = L["Choose"],
            width = "half",
            order = 7,
            func = function()
                WeakAuras.OpenTexturePick(data, "texture", WeakAuras.texture_types);
            end
        },
        color = {
            type = "color",
            name = L["Color"],
            hasAlpha = true,
            order = 10
        },
        blendMode = {
            type = "select",
            name = L["Blend Mode"],
            order = 12,
            values = WeakAuras.blend_types
        },
        mirror = {
            type = "toggle",
            name = L["Mirror"],
            order = 20
        },
        rotate = {
            type = "toggle",
            name = L["Allow Full Rotation"],
            order = 25
        },
        space3 = {
            type = "execute",
            name = "",
            order = 30,
            image = function() return "", 0, 0 end,
        },
        rotation = {
            type = "range",
            name = L["Rotation"],
            min = 0,
            max = 360,
            step = 1,
            bigStep = 3,
            order = 35,
            hidden = function() return not data.rotate end
        },
        discrete_rotation = {
            type = "range",
            name = L["Discrete Rotation"],
            min = 0,
            max = 360,
            step = 90,
            order = 35,
            hidden = function() return data.rotate end
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

    region.texture:SetTexture(data.texture);
    region.texture:SetVertexColor(data.color[1], data.color[2], data.color[3], data.color[4]);
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
end

local function createIcon()
    local data = {
        height = 40,
        width = 40,
        texture = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
        color = {1, 1, 1, 1},
        blendMode = "ADD",
        rotate = true;
        rotation = 0;
    };

    local thumbnail = createThumbnail(UIParent);
    modifyThumbnail(UIParent, thumbnail, data, nil, 50);

    return thumbnail;
end

local templates = {
  {
    title = L["Default"],
    data = {
    };
  },
  {
    title = L["Star"],
    data = {
      texture = "Spells\\T_Star3",
      blendMode = "ADD",
      width = 200,
      height = 200,
      discrete_rotation = 0,
    }
  },
  {
    title = L["Leaf"],
    data = {
      texture = "Spells\\Nature_Rune_128",
      blendMode = "ADD",
      width = 200,
      height = 200,
      discrete_rotation = 0,
    }
  },
  {
    title = L["Hawk"],
    data = {
      texture = "Spells\\Aspect_Hawk",
      blendMode = "ADD",
      width = 200,
      height = 200,
      discrete_rotation = 0,
    }
  },
  {
    title = L["Low Mana"],
    data = {
      texture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura70",
      blendMode = "ADD",
      width = 200,
      height = 200,
      discrete_rotation = 0,
    }
  },
}

WeakAuras.RegisterRegionOptions("texture", createOptions, createIcon, L["Texture"], createThumbnail, modifyThumbnail, L["Shows a custom texture"], templates);
