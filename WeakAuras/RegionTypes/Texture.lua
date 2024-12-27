if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

local L = WeakAuras.L;

local default = {
  texture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura3",
  desaturate = false,
  width = 200,
  height = 200,
  color = {1, 1, 1, 1},
  blendMode = "BLEND",
  textureWrapMode = "CLAMPTOBLACKADDITIVE",
  rotation = 0,
  mirror = false,
  rotate = false,
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  frameStrata = 1
};

Private.regionPrototype.AddAlphaToDefault(default);

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  texture = {
    display = L["Texture"],
    setter = "SetTexture",
    type = "texture",
  },
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
  },
  rotation = {
    display = L["Rotation"],
    setter = "SetRotation",
    type = "number",
    min = 0,
    max = 360,
    bigStep = 1,
    default = 0
  }
}

Private.regionPrototype.AddProperties(properties, default);

local function create(parent)
  local region = CreateFrame("Frame", nil, UIParent);
  region.regionType = "texture"
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetResizeBounds(1, 1)

  local texture = Private.TextureBase.create(region)
  region.texture = texture;
  texture:SetAllPoints(region);

  Private.regionPrototype.create(region);

  return region;
end

local function modify(parent, region, data)
  Private.regionPrototype.modify(parent, region, data);
  region:SetWidth(data.width);
  region:SetHeight(data.height);
  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;

  Private.TextureBase.modify(region.texture, {
    canRotate = data.rotate,
    desaturate = data.desaturate,
    blendMode = data.blendMode,
    mirror = data.mirror,
    rotation = data.rotation,
    textureWrapMode = data.textureWrapMode
  })

  function region:Scale(scalex, scaley)
    region.scalex = scalex;
    region.scaley = scaley;
    local mirror_h, mirror_v
    if(scalex < 0) then
      mirror_h = true
      scalex = scalex * -1;
    end
    region:SetWidth(region.width * scalex);
    if(scaley < 0) then
      scaley = scaley * -1;
      mirror_v = true
    end
    region:SetHeight(region.height * scaley);

    region.texture:SetMirrorFromScale(mirror_h, mirror_v)
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
    self.texture:SetMirror(mirror)
  end

  function region:Update()
    if self.state.texture then
      self.texture:SetTexture(self.state.texture)
    end
    self:UpdateProgress()
  end

  function region:SetTexture(texture)
    self.texture:SetTexture(texture)
  end

  region.texture:SetTexture(data.texture)

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
    self.texture:SetDesaturated(b)
  end

  --- @type fun(degrees: number?)
  function region:SetAnimRotation(degrees)
    self.texture:SetAnimRotation(degrees)
  end

  --- @type fun(degrees: number)
  function region:SetRotation(degrees)
    self.texture:SetRotation(degrees)
  end

  --- @type fun(): number
  function region:GetBaseRotation()
    return self.texture:GetBaseRotation()
  end
  region:SetRotation(data.rotation)

  Private.regionPrototype.modifyFinish(parent, region, data);
end

local function validate(data)
  Private.EnforceSubregionExists(data, "subbackground")
end

Private.RegisterRegionType("texture", create, modify, default, properties, validate);
