if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...

local L = WeakAuras.L
local GetAtlasInfo = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo

local function IsAtlas(input)
  return type(input) == "string" and GetAtlasInfo(input) ~= nil
end

local function createOptions(id, data)
  local options = {
    __title = L["Texture Settings"],
    __order = 1,
    texture = {
      type = "input",
      width = WeakAuras.doubleWidth - 0.15,
      name = L["Texture"],
      order = 1
    },
    chooseTexture = {
      type = "execute",
      name = L["Choose"],
      width = 0.15,
      order = 1.1,
      func = function()
        OptionsPrivate.OpenTexturePicker(data, {}, {
          texture = "texture",
          color = "color",
          auraRotation = "rotation",
          mirror = "mirror",
          blendMode = "blendMode"
        }, OptionsPrivate.Private.texture_types);
      end,
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon",
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
    },
    color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      hasAlpha = true,
      order = 2
    },
    desaturate = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Desaturate"],
      order = 3,
    },
    alpha = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Alpha"],
      order = 4,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    },
    blendMode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Blend Mode"],
      order = 5,
      values = OptionsPrivate.Private.blend_types
    },
    rotation = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Rotation"],
      min = 0,
      max = 360,
      step = 1,
      bigStep = 3,
      order = 6,
    },
    mirror = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Mirror"],
      order = 7,
    },
    legacyZoomOut = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Legacy Zoom Out"],
      desc = L["Rotating a texture around arbitary angles used to require a zoom out. This is no longer required, this option only exist for compatibility with previous behaviour."],
      order = 8,
      hidden = IsAtlas(data.texture)
    },
    textureWrapMode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Texture Wrap"],
      order = 9,
      values = OptionsPrivate.Private.texture_wrap_types,
      hidden = IsAtlas(data.texture)
    },
    endHeader = {
      type = "header",
      order = 100,
      name = "",
    },
  };

  return {
    texture = options,
    position = OptionsPrivate.commonOptions.PositionOptions(id, data),
  };
end

local function createThumbnail()
  local borderframe = CreateFrame("Frame", nil, UIParent);
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
  if(data.height > data.width) then
    local scale = data.width / data.height;
    region.texture:SetWidth(scale * size)
    region.texture:SetHeight(size);
  else
    local scale = data.height / data.width;
    region.texture:SetWidth(size)
    region.texture:SetHeight(scale * size)
  end

  WeakAuras.SetTextureOrAtlas(region.texture, data.texture, data.textureWrapMode, data.textureWrapMode);
  region.texture:SetVertexColor(data.color[1], data.color[2], data.color[3], data.color[4]);
  region.texture:SetBlendMode(data.blendMode)
  region.texture:SetRotation((data.rotation / 180) * math.pi)

  local ulx,uly, llx,lly, urx,ury, lrx,lry = 0,0, 0,1, 1,0, 1,1
  if(data.mirror) then
    region.texture:SetTexCoord(urx,ury, lrx,lry, ulx,uly, llx,lly)
  else
    region.texture:SetTexCoord(ulx,uly, llx,lly, urx,ury, lrx,lry)
  end
end

local function createIcon()
  local data = {
    height = 40,
    width = 40,
    texture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura3",
    color = {1, 1, 1, 1},
    blendMode = "ADD",
    rotate = true;
    rotation = 0;
  };

  local thumbnail = createThumbnail();
  modifyThumbnail(UIParent, thumbnail, data, nil, 36)

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
      texture = "241049", -- Spells\\T_Star3
      blendMode = "ADD",
      width = 200,
      height = 200,
      discrete_rotation = 0,
    }
  },
  {
    title = L["Leaf"],
    data = {
      texture = "166606", -- Spells\\Nature_Rune_128
      blendMode = "ADD",
      width = 200,
      height = 200,
      discrete_rotation = 0,
    }
  },
  {
    title = L["Hawk"],
    data = {
      texture = "165609", -- Spells\\Aspect_Hawk
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

if WeakAuras.IsClassic() then
  table.remove(templates, 2)
end

WeakAuras.RegisterRegionOptions("texture", createOptions, createIcon, L["Texture"], createThumbnail, modifyThumbnail,
                                L["Shows a custom texture"], templates);
