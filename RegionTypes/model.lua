local default = {
    model_path = "Creature/Arthaslichking/arthaslichking.m2",
    model_x = 0,
    model_y = 0,
    model_z = 0,
    width = 200,
    height = 200,
    sequence = 1,
    advance = false,
    rotation = 0,
    scale = 1,
    selfPoint = "CENTER",
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0,
    frameStrata = 1
};

local function create(parent)
    --local frame = CreateFrame("FRAME", nil, UIParent);
    --frame:SetMovable(true);
    --frame:SetResizable(true);
    
    local model = CreateFrame("PlayerModel", nil, UIParent);
    --frame.model = model;
    --model:SetAllPoints(frame);
    model:SetMovable(true);
    model:SetResizable(true);
    return model;
end

local function modify(parent, region, data)
    if(data.frameStrata == 1) then
        region:SetFrameStrata(region:GetParent():GetFrameStrata());
    else
        region:SetFrameStrata(WeakAuras.frame_strata_types[data.frameStrata]);
    end
    
    local model = region;
    region:SetWidth(data.width);
    region:SetHeight(data.height);
    region:ClearAllPoints();
    region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
    
    model:SetModel(data.model_path);
    model:SetPosition(data.model_z, data.model_x, data.model_y);
    
    if(data.advance) then
        local elapsed = 0;
        model:SetScript("OnUpdate", function(self, elaps)
            elapsed = elapsed + (elaps * 1000);
            model:SetSequenceTime(data.sequence, elapsed);
        end);
    else
        model:SetScript("OnUpdate", nil);
    end
    
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
    end
    
    function region:Rotate(degrees)
        region.rotation = degrees;
        model:SetFacing(rad(region.rotation));
    end
    
    function region:GetRotation()
        return region.rotation;
    end
    
    model:Rotate(data.rotation);
    
    function region:EnsureModel()
        if(type(region:GetModel()) ~= "string") then
            model:SetModel(data.model_path);
        end
    end
end

WeakAuras.RegisterRegionType("model", create, modify, default);