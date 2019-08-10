if not WeakAuras.IsCorrectVersion() then return end

local L = WeakAuras.L;

local root2 = math.sqrt(2);
local halfroot2 = root2/2;

local default = {
  texture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura3",
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
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  frameStrata = 1
};

WeakAuras.regionPrototype.AddAlphaToDefault(default);

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  color = {
    display = L["Color"],
    setter = "Color",
    type = "color",
  },
  desaturate = {
    display = L["Desaturate"],
    setter = "SetDesaturated",
    type = "bool"
  },
  width = {
    display = L["Width"],
    setter = "SetRegionWidth",
    type = "number",
    min = 1,
    softMax = screenWidth,
    bigStep = 1,
    default = 32
  },
  height = {
    display = L["Height"],
    setter = "SetRegionHeight",
    type = "number",
    min = 1,
    softMax = screenHeight,
    bigStep = 1,
    default = 32
  },
  mirror = {
    display = L["Mirror"],
    setter = "SetMirror",
    type = "bool"
  }
}

WeakAuras.regionPrototype.AddProperties(properties, default);

local function create(parent)
  local region = CreateFrame("FRAME", nil, UIParent);
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetMinResize(1, 1);

  local texture = region:CreateTexture();
  texture:SetSnapToPixelGrid(false)
  texture:SetTexelSnappingBias(0)
  region.texture = texture;
  texture:SetAllPoints(region);

  WeakAuras.regionPrototype.create(region);
  region.values = {};

  region.AnchorSubRegion = WeakAuras.regionPrototype.AnchorSubRegion

  return region;
end

local function modify(parent, region, data)
  WeakAuras.regionPrototype.modify(parent, region, data);
  WeakAuras.SetTextureOrAtlas(region.texture, data.texture);
  region.texture:SetDesaturated(data.desaturate)
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;
  region.texture:SetBlendMode(data.blendMode);
  --region.texture:SetRotation((data.rotation / 180) * math.pi);

  local function GetRotatedPoints(degrees)
    local angle = rad(135 - degrees);
    local vx = math.cos(angle);
    local vy = math.sin(angle);

    return 0.5+vx,0.5-vy , 0.5-vy,0.5-vx , 0.5+vy,0.5+vx , 0.5-vx,0.5+vy
  end

  region.mirror = data.mirror

  local function DoTexCoord()
    local mirror_h, mirror_v = region.mirror_h, region.mirror_v;
    if(region.mirror) then
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
    region.scalex = scalex;
    region.scaley = scaley;
    if(scalex < 0) then
      region.mirror_h = true;
      scalex = scalex * -1;
    else
      region.mirror_h = nil;
    end
    region:SetWidth(region.width * scalex);
    if(scaley < 0) then
      scaley = scaley * -1;
      region.mirror_v = true;
    else
      region.mirror_v = nil;
    end
    region:SetHeight(region.height * scaley);

    DoTexCoord();
  end

  function region:SetRegionWidth(width)
    region.width = width;
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetRegionHeight(height)
    region.height = height;
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetMirror(mirror)
    region.mirror = mirror
    DoTexCoord()
  end

  function region:Update()
    if region.state.texture then
      WeakAuras.SetTextureOrAtlas(region.texture, region.state.texture);
    end
  end

  function region:Color(r, g, b, a)
    region.color_r = r;
    region.color_g = g;
    region.color_b = b;
    region.color_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    region.texture:SetVertexColor(region.color_anim_r or r, region.color_anim_g or g, region.color_anim_b or b, region.color_anim_a or a);
  end

  function region:ColorAnim(r, g, b, a)
    region.color_anim_r = r;
    region.color_anim_g = g;
    region.color_anim_b = b;
    region.color_anim_a = a;
    if (r or g or b) then
      a = a or 1;
    end
    region.texture:SetVertexColor(r or region.color_r, g or region.color_g, b or region.color_b, a or region.color_a);
  end

  function region:GetColor()
    return region.color_r or data.color[1], region.color_g or data.color[2],
      region.color_b or data.color[3], region.color_a or data.color[4];
  end

  region:Color(data.color[1], data.color[2], data.color[3], data.color[4]);

  function region:SetDesaturated(b)
    region.texture:SetDesaturated(b);
  end

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

  WeakAuras.regionPrototype.modifyFinish(parent, region, data);
end

WeakAuras.RegisterRegionType("texture", create, modify, default, properties);
