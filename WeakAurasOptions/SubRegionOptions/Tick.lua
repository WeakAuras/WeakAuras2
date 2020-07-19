if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local indentWidth = WeakAuras.normalWidth * 0.06

local function createOptions(parentData, data, index, subIndex)
  local hiddentickextras = function()
    return WeakAuras.IsCollapsed("subtext", "subtext", "tickextras" .. index, true)
  end
  local options = {
    __title = L["Tick %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionUp, index, "subtick")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __down = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionDown, index, "subtick")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __duplicate = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DuplicateSubRegion, index, "subtick")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __delete = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DeleteSubRegion, index, "subtick")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
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
      values = WeakAuras.tick_placement_modes,
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
          local blendtext = WeakAuras.blend_types[data.tick_blend_mode]
          texturetext = L["|cFFFF0000custom|r texture with |cFFFF0000%s|r blend mode"]:format(blendtext)
        else
          texturetext = L["|cFFFF0000default|r texture"]
        end

        local description = L["|cFFffcc00Extra:|r %s and %s"]:format(lengthtext, texturetext)

        return description
      end,
      width = WeakAuras.doubleWidth,
      order = 6,
      func = function(info, button)
        local collapsed = WeakAuras.IsCollapsed("subtext", "subtext", "tickextras" .. index, true)
        WeakAuras.SetCollapsed("subtext", "subtext", "tickextras" .. index, not collapsed)
      end,
      image = function()
        local collapsed = WeakAuras.IsCollapsed("subtext", "subtext", "tickextras" .. index, true)
        return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
      end,
      imageWidth = 24,
      imageHeight = 24
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
      name = L["Use texture"],
      order = 9,
      hidden = hiddentickextras,
    },
    tick_space1 = {
      type = "description",
      width = WeakAuras.normalWidth,
      name = "",
      order = 10,
    },
    tick_texture = {
      type = "input",
      name = L["Spark Texture"],
      order = 11,
      width = WeakAuras.doubleWidth,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
    },
    tick_blend_mode = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Blend Mode"],
      order = 12,
      values = WeakAuras.blend_types,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
    },
    texture_chooser = {
      type = "execute",
      name = L["Choose"],
      width = WeakAuras.normalWidth,
      order = 13,
      func = function()
        WeakAuras.OpenTexturePicker(data, "tick_texture", WeakAuras.texture_types);
      end,
      disabled = function() return not data.use_texture end,
      hidden = hiddentickextras,
    },
  }
  return options
end

WeakAuras.RegisterSubRegionOptions("subtick", createOptions, L["Places a tick on the bar"]);
