if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L;

local function createOptions(parentData, data, index, subIndex)
  local pointAnchors = {}
  local areaAnchors = {}
  for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
    Mixin(pointAnchors, OptionsPrivate.Private.GetAnchorsForData(child, "point"))
    Mixin(areaAnchors, OptionsPrivate.Private.GetAnchorsForData(child, "area"))
  end

  local options = {
    __title = L["Circular Texture %s"]:format(subIndex),
    __order = 1,
    circularTextureVisible = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Show Circular Texture"],
      order = 1,
    },
    circularTextureTexture = {
      type = "input",
      width = WeakAuras.doubleWidth - 0.15,
      name = L["Texture"],
      order = 2,
    },
    chooseTexture = {
      type = "execute",
      width = 0.15,
      name = L["Choose"],
      order = 3,
      func = function()
        local path = { "subRegions", index }
        local paths = {}
        for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
          paths[child.id] = path
        end
        OptionsPrivate.OpenTexturePicker(parentData, paths, {
          texture = "circularTextureTexture",
          color = "circularTextureColor",
          blendMode = "circularTextureBlendMode"
        }, OptionsPrivate.Private.texture_types, nil)
      end,
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon",
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
    },
    circularTextureClockwise = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Clockwise"],
      order = 4,
    },
    circularTextureMirror = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Mirror"],
      order = 5,
    },
    circularTextureColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      hasAlpha = true,
      order = 6
    },
    circularTextureDesaturate = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Desaturate"],
      order = 7,
    },
    circularTextureBlendMode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Blend Mode"],
      order = 8,
      values = OptionsPrivate.Private.blend_types
    },
    circularTextureInverse = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Inverse"],
      order = 8.5,
    },
    circularTextureStartAngle = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      order = 9,
      name = L["Start Angle"],
      min = 0,
      max = 360,
      bigStep = 1,
    },
    circularTextureEndAngle = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      order = 10,
      name = L["End Angle"],
      min = 0,
      max = 360,
      bigStep = 1,
     },
     circularTextureCrop_x = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Crop X"],
      order = 11,
      min = 0,
      softMax = 2,
      bigStep = 0.01,
      isPercent = true,
    },
    circularTextureCrop_y = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Crop Y"],
      order = 12,
      min = 0,
      softMax = 2,
      bigStep = 0.01,
      isPercent = true,
    },
    -- Doesn't appear to work
    circularTextureRotation = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Texture Rotation"],
      desc = L["Uses Texture Coordinates to rotate the texture."],
      order = 13,
      min = 0,
      max = 360,
      bigStep = 1
    },
    -- Doesn't appear to work
    circularTextureAuraRotation = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Rotation"],
      order = 14,
      min = 0,
      max = 360,
      bigStep = 1
    },
  }

  OptionsPrivate.commonOptions.ProgressOptionsForSubElement(parentData, data, options, 16)
  OptionsPrivate.commonOptions.PositionOptionsForSubElement(data, options, 17, areaAnchors, pointAnchors)

  OptionsPrivate.AddUpDownDeleteDuplicate(options, parentData, index, "subcirculartexture")

  return options
end

  WeakAuras.RegisterSubRegionOptions("subcirculartexture", createOptions, L["Shows a Circular Progress Texture"]);
