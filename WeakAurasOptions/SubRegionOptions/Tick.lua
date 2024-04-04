if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L;

local function createOptions(parentData, data, index, subIndex)
  local hiddentickextras = function()
    return OptionsPrivate.IsCollapsed("subtext", "subtext", "tickextras" .. index, true)
  end
  local options = {
    __title = L["Tick %s"]:format(subIndex),
    __order = 1,
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

    tick_thickness = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Thickness"],
      order = 2.5,
      min = 0,
      softMax = 20,
      step = 1,
    },

    tick_progress_source_space = {
      type = "description",
      name = "",
      order = 3,
      width = WeakAuras.normalWidth,
    },

    tick_placement_mode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Tick Mode"],
      order = 3.1,
      values = OptionsPrivate.Private.tick_placement_modes,
    },


    tick_progress_source_space_2 = {
      type = "description",
      name = "",
      order = 3.2,
      width = WeakAuras.normalWidth,
    },

    tick_add = {
      type = "execute",
      name = L["Add"],
      order = 5,
      width = WeakAuras.normalWidth,
      func = function()
        tinsert(data.tick_placements, 0)
        WeakAuras.Add(parentData)
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
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
      order = 7,
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
      order = 8,
      desc = L["Matches the height setting of a horizontal bar or width for a vertical bar."],
      hidden = hiddentickextras,
    },
    tick_length = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Length"],
      order = 9,
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
      order = 10,
      hidden = hiddentickextras,
    },
    tick_blend_mode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Blend Mode"],
      order = 11,
      values = OptionsPrivate.Private.blend_types,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
    },
    tick_texture = {
      type = "input",
      name = L["Texture"],
      order = 12,
      width = WeakAuras.doubleWidth - 0.15,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
    },
    texture_chooser = {
      type = "execute",
      name = L["Choose"],
      width = 0.15,
      order = 12.5,
      func = function()
        local path = { "subRegions", index }
        local paths = {}
        for child in OptionsPrivate.Private.TraverseLeafsOrAura(parentData) do
          paths[child.id] = path
        end
        OptionsPrivate.OpenTexturePicker(parentData, paths, {
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
      order = 13,
      hidden = hiddentickextras,
    },
    tick_rotation = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Rotation"],
      min = 0,
      max = 360,
      step = 1,
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
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["x-Offset"],
      order = 16,
      softMin = -200,
      softMax = 200,
      step = 1,
      hidden = hiddentickextras,
    },
    tick_yOffset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["y-Offset"],
      order = 17,
      softMin = -200,
      softMax = 200,
      step = 1,
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

  if data then
    for i in ipairs(data.tick_placements) do
      options["tick_progress_source" .. i] = {
        type = "select",
        width = WeakAuras.normalWidth,
        name = L["Progress Source"],
        order = 4 + i / 100,
        control = "WeakAurasTwoColumnDropdown",
        values = OptionsPrivate.Private.GetProgressSourcesForUi(parentData, true),
        get = function(info)
          return OptionsPrivate.Private.GetProgressValueConstant(data.progressSources[i] or {-2, ""})
        end,
        set = function(info, value)
          if value then
            data.progressSources = data.progressSources or {}
            data.progressSources[i] = data.progressSources[i] or {}
            -- Copy only trigger + property
            data.progressSources[i][1] = value[1]
            data.progressSources[i][2] = value[2]
          else
            data.progressSources[i] = nil
          end
          WeakAuras.Add(parentData)
        end,
        hidden = function()
          return not(data.tick_placement_mode == "ValueOffset")
        end
      }

      options["tick_placement" .. i] = {
        type = "input",
        width = WeakAuras.normalWidth - 0.15,
        name = L["Tick Placement"],
        order = 4 + i / 100 + 0.001,
        validate = WeakAuras.ValidateNumeric,
        desc = L["Enter in a value for the tick's placement."],
        get = function(info)
          return data.tick_placements[i] or ""
        end,
        set = function(info, value)
          data.tick_placements[i] = value
          WeakAuras.Add(parentData)
        end
      }

      options["tick_placement_delete" .. i] = {
        type = "execute",
        width = 0.15,
        name = L["Delete"],
        order = 4 + i / 100 + 0.002,
        func = function()
          tremove(data.tick_placements, i)
          WeakAuras.Add(parentData)
          WeakAuras.ClearAndUpdateOptions(parentData.id)
        end,
        image = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\delete",
        imageWidth = 24,
        imageHeight = 24,
        control = "WeakAurasIcon",
        disabled = function()
          return #data.tick_placements < 2
        end
      }
    end
  end

  OptionsPrivate.AddUpDownDeleteDuplicate(options, parentData, index, "subtick")

  return options
end

WeakAuras.RegisterSubRegionOptions("subtick", createOptions, L["Places a tick on the bar"]);
