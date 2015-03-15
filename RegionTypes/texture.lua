local root2 = math.sqrt(2);
local halfroot2 = root2/2;

local default = {
    texture = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
    desaturate = false,
    width = 200,
    height = 200,
    color = {1, 1, 1, 0.75},
    blendMode = "BLEND",
    rotation = 0,
    discrete_rotation = 0,
    mirror = false,
    rotate = true,
    selfPoint = "CENTER",
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0,
    frameStrata = 1
};

local function create(parent)
    local frame = CreateFrame("FRAME", nil, UIParent);
    frame:SetMovable(true);
    frame:SetResizable(true);
    frame:SetMinResize(1, 1);

    local texture = frame:CreateTexture();
    frame.texture = texture;
    texture:SetAllPoints(frame);
    return frame;
end

local function modify(parent, region, data)
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end

    region.texture:SetTexture(data.texture);
    region.texture:SetDesaturated(data.desaturate)
    region:SetWidth(data.width);
    region:SetHeight(data.height);
    region.texture:SetBlendMode(data.blendMode);
    --region.texture:SetRotation((data.rotation / 180) * math.pi);
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);

    local function GetRotatedPoints(degrees)
        local angle = rad(135 - degrees);
        local vx = math.cos(angle);
        local vy = math.sin(angle);

        return 0.5+vx,0.5-vy , 0.5-vy,0.5-vx , 0.5+vy,0.5+vx , 0.5-vx,0.5+vy
    end

    local function DoTexCoord()
        local mirror_h, mirror_v = region.mirror_h, region.mirror_v;
        if(data.mirror) then
            mirror_h = not mirror_h;
        end
        local ulx,uly , llx,lly , urx,ury , lrx,lry;
        if(data.rotate) then
            ulx,uly , llx,lly , urx,ury , lrx,lry = GetRotatedPoints(region.rotation);
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
        if(mirror_h) then
            if(mirror_v) then
                region.texture:SetTexCoord(lrx,lry , urx,ury , llx,lly , ulx,uly);
            else
                region.texture:SetTexCoord(urx,ury , lrx,lry , ulx,uly , llx,lly);
            end
        else
            if(mirror_v) then
                region.texture:SetTexCoord(llx,lly , ulx,uly , lrx,lry , urx,ury);
            else
                region.texture:SetTexCoord(ulx,uly , llx,lly , urx,ury , lrx,lry);
            end
        end
    end

    region.rotation = data.rotation;
    DoTexCoord();

    function region:Scale(scalex, scaley)
        if(scalex < 0) then
            region.mirror_h = true;
            scalex = scalex * -1;
        else
            region.mirror_h = nil;
        end
        region:SetWidth(data.width * scalex);
        if(scaley < 0) then
            scaley = scaley * -1;
            region.mirror_v = true;
        else
            region.mirror_v = nil;
        end
        region:SetHeight(data.height * scaley);

        DoTexCoord();
    end

    function region:SetTexture(path)
        local texturePath = path;
        region.texture:SetTexture(texturePath);
    end

    function region:Color(r, g, b, a)
        region.color_r = r;
        region.color_g = g;
        region.color_b = b;
        region.color_a = a;
        region.texture:SetVertexColor(r, g, b, a);
    end

    function region:GetColor()
        return region.color_r or data.color[1], region.color_g or data.color[2],
               region.color_b or data.color[3], region.color_a or data.color[4];
    end

    region:Color(data.color[1], data.color[2], data.color[3], data.color[4]);

    if(data.rotate) then
        function region:Rotate(degrees)
            region.rotation = degrees;
            DoTexCoord();
        end

        function region:GetRotation()
            return region.rotation;
        end
    else
        region.Rotate = nil;
        region.GetRotation = nil;
    end
end

WeakAuras.RegisterRegionType("texture", create, modify, default);
