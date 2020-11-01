if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local indentWidth = WeakAuras.normalWidth * 0.06

local function createOptions(parentData, data, index, subIndex)
  local hiddentickextras = function()
    return OptionsPrivate.IsCollapsed("subtext", "subtext", "tickextras" .. index, true)
  end
  local options = {
    __title = L["Tick %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (OptionsPrivate.Private.ApplyToDataOrChildData(parentData, OptionsPrivate.MoveSubRegionUp, index, "subtick")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __down = function()
      if (OptionsPrivate.Private.ApplyToDataOrChildData(parentData, OptionsPrivate.MoveSubRegionDown, index, "subtick")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __duplicate = function()
      if (OptionsPrivate.Private.ApplyToDataOrChildData(parentData, OptionsPrivate.DuplicateSubRegion, index, "subtick")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __delete = function()
      if (OptionsPrivate.Private.ApplyToDataOrChildData(parentData, WeakAuras.DeleteSubRegion, index, "subtick")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    tick_visible = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Tick"],
      order = 1,
    },
    tick_color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      order = 2,
      hasAlpha = true,
    },
    tick_placement_mode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Tick Mode"],
      order = 3,
      values = OptionsPrivate.Private.tick_placement_modes,
    },
    tick_placement = {
      type = "input",
      width = WeakAuras.normalWidth,
      name = L["Tick Placement"],
      order = 4,
      validate = WeakAuras.ValidateNumeric,
      desc = L["Enter in a value for the tick's placement."],
    },
    tick_thickness = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Thickness"],
      order = 5,
      min = 0,
      softMax = 20,
      step = 1,
    },
    tick_extrasDescription = {
      type = "execute",
      control = "WeakAurasExpandSmall",
      name = function()
        local lengthtext = ""
        if data.automatic_length then
          lengthtext = L["|cFFFF0000Automatic|r length"]
        else
          lengthtext = L["Length of |cFFFF0000%s|r"]:format(data.tick_length)
        end

        local texturetext = ""
        if data.use_texture then
          local desaturatetext = data.tick_desaturate and L["|cFFFF0000desaturated|r "] or ""
          local blendtext = OptionsPrivate.Private.blend_types[data.tick_blend_mode]
          local rotationtext = data.tick_rotation ~= 0 and L[" rotated |cFFFF0000%s|r degrees"]:format(data.tick_rotation) or ""
          local mirrortext = data.tick_mirror and L[" and |cFFFF0000mirrored|r"] or ""
          texturetext = L["%s|cFFFF0000custom|r texture with |cFFFF0000%s|r blend mode%s%s"]:format(desaturatetext, blendtext, rotationtext, mirrortext)
        else
          texturetext = L["|cFFFF0000default|r texture"]
        end

        local offsettext = ""
        if data.tick_xOffset ~=0 or data.tick_yOffset ~=0 then
          offsettext = L["Offset by |cFFFF0000%s|r/|cFFFF0000%s|r"]:format(data.tick_xOffset, data.tick_yOffset)
        end

        local description = L["|cFFffcc00Extra:|r %s and %s %s"]:format(lengthtext, texturetext, offsettext)

        return description
      end,
      width = WeakAuras.doubleWidth,
      order = 6,
      func = function(info, button)
        local collapsed = OptionsPrivate.IsCollapsed("subtext", "subtext", "tickextras" .. index, true)
        OptionsPrivate.SetCollapsed("subtext", "subtext", "tickextras" .. index, not collapsed)
      end,
      image = function()
        local collapsed = OptionsPrivate.IsCollapsed("subtext", "subtext", "tickextras" .. index, true)
        return collapsed and "collapsed" or "expanded"
      end,
      imageWidth = 15,
      imageHeight = 15,
      arg = {
        expanderName = "tick" .. index .. "#" .. subIndex
      }
    },
    automatic_length = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Automatic length"],
      order = 7,
      desc = L["Matches the height setting of a horizontal bar or width for a vertical bar."],
      hidden = hiddentickextras,
    },
    tick_length = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Length"],
      order = 8,
      min = 0,
      softMax = 50,
      step = 1,
      disabled = function() return data.automatic_length end,
      hidden = hiddentickextras,
    },
    use_texture = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Use Texture"],
      order = 9,
      hidden = hiddentickextras,
    },
    tick_blend_mode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Blend Mode"],
      order = 10,
      values = OptionsPrivate.Private.blend_types,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
    },
    tick_texture = {
      type = "input",
      name = L["Texture"],
      order = 11,
      width = WeakAuras.doubleWidth - 0.15,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
    },
    texture_chooser = {
      type = "execute",
      name = L["Choose"],
      width = 0.15,
      order = 11.5,
      func = function()
        OptionsPrivate.OpenTexturePicker(parentData, {
          "subRegions", index
        }, {
          texture = "tick_texture",
          color = "tick_color",
          blendMode = "tick_blend_mode"
        }, OptionsPrivate.Private.texture_types);
      end,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
      imageWidth = 24,
      imageHeight = 24,
      control = "WeakAurasIcon",
      image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\browse",
    },
    tick_desaturate = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Desaturate"],
      order = 12,
      hidden = hiddentickextras,
    },
    tick_rotation = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Rotation"],
      min = 0,
      max = 360,
      order = 14,
      hidden = hiddentickextras,
    },
    tick_mirror = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Mirror"],
      order = 15,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
    },
    tick_xOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["x-Offset"],
      order = 16,
      softMin = -200,
      softMax = 200,
      hidden = hiddentickextras,
    },
    tick_yOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["y-Offset"],
      order = 17,
      softMin = -200,
      softMax = 200,
      hidden = hiddentickextras,
    },

    tick_anchor = {
      type = "description",
      name = "",
      order = 18,
      hidden = hiddentickextras,
      control = "WeakAurasExpandAnchor",
      arg = {
        expanderName = "tick" .. index .. "#" .. subIndex
      }
    }
  }
  return options
end

WeakAuras.RegisterSubRegionOptions("subtick", createOptions, L["Places a tick on the bar"]);
