if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L;
local indentWidth = 0.15

local function createOptions(parentData, data, index, subIndex)

  local hiddenGlowExtra = function()
    return OptionsPrivate.IsCollapsed("glow", "glow", "glowextra" .. index, true);
  end

  local options = {
    __title = L["Glow %s"]:format(subIndex),
    __order = 1,
    glow = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Glow"],
      order = 2,
    },
    glowType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Type"],
      order = 2,
      values = OptionsPrivate.Private.glow_types,
    },
    glow_anchor = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Glow Anchor"],
      order = 3,
      values = OptionsPrivate.Private.aurabar_anchor_areas,
      hidden = function() return parentData.regionType ~= "aurabar" end
    },
    glowExtraDescription = {
      type = "execute",
      control = "WeakAurasExpandSmall",
      name = function()
        local line = L["|cFFffcc00Extra Options:|r"]
        local color = L["Default Color"]
        if data.useGlowColor then
          color = L["|c%02x%02x%02x%02xCustom Color|r"]:format(
            data.glowColor[4] * 255,
            data.glowColor[1] * 255,
            data.glowColor[2] * 255,
            data.glowColor[3] * 255
          )
        end
        if data.glowType == "buttonOverlay" then
          line = ("%s %s"):format(line, color)
        elseif data.glowType == "ACShine" then
          line = L["%s %s, Particles: %d, Frequency: %0.2f, Scale: %0.2f"]:format(
            line,
            color,
            data.glowLines,
            data.glowFrequency,
            data.glowScale
          )
          if data.glowXOffset ~= 0 or data.glowYOffset ~= 0 then
            line = L["%s, offset: %0.2f;%0.2f"]:format(line, data.glowXOffset, data.glowYOffset)
          end
        elseif data.glowType == "Pixel" then
          line = L["%s %s, Lines: %d, Frequency: %0.2f, Length: %d, Thickness: %d"]:format(
            line,
            color,
            data.glowLines,
            data.glowFrequency,
            data.glowLength,
            data.glowThickness
          )
          if data.glowXOffset ~= 0 or data.glowYOffset ~= 0 then
            line = L["%s, Offset: %0.2f;%0.2f"]:format(line, data.glowXOffset, data.glowYOffset)
          end
          if data.glowBorder then
            line = L["%s, Border"]:format(line)
          end
        elseif data.glowType == "Proc" then
          line = ("%s %s, Duration: %d"):format(line, color, data.glowDuration)
          if data.glowStartAnim then
            line = L["%s, Start Animation"]:format(line)
          end
          if data.glowXOffset ~= 0 or data.glowYOffset ~= 0 then
            line = L["%s, offset: %0.2f;%0.2f"]:format(line, data.glowXOffset, data.glowYOffset)
          end
        end
        return line
      end,
      width = WeakAuras.doubleWidth,
      order = 4,
      image = function()
        local collapsed = OptionsPrivate.IsCollapsed("glow", "glow", "glowextra" .. index, true);
        return collapsed and "collapsed" or "expanded"
      end,
      imageWidth = 15,
      imageHeight = 15,
      func = function(info, button)
        local collapsed = OptionsPrivate.IsCollapsed("glow", "glow", "glowextra" .. index, true);
        OptionsPrivate.SetCollapsed("glow", "glow", "glowextra" .. index, not collapsed);
      end,
      arg = {
        expanderName = "glow" .. index .. "#" .. subIndex
      }
    },
    glow_space1 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = 5,
      hidden = hiddenGlowExtra,
    },
    useGlowColor = {
      type = "toggle",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Use Custom Color"],
      desc = L["If unchecked, then a default color will be used (usually yellow)"],
      order = 6,
      hidden = hiddenGlowExtra
    },
    glowColor = {
      type = "color",
      hasAlpha = true,
      width = WeakAuras.normalWidth,
      name = L["Custom Color"],
      order = 7,
      disabled = function() return not data.useGlowColor end,
      hidden = hiddenGlowExtra
    },
    glow_space2 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = 8,
      hidden = hiddenGlowExtra,
    },
    glowStartAnim = {
      type = "toggle",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Start Animation"],
      order = 8.5,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Proc" end
    },
    glowLines = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Lines & Particles"],
      order = 9,
      min = 1,
      softMax = 30,
      step = 1,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" or data.glowType == "Proc" end,
    },
    glowFrequency = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Frequency"],
      order = 10,
      softMin = -2,
      softMax = 2,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" or data.glowType == "Proc" end,
    },
    glowDuration = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Duration"],
      order = 10,
      softMin = 0.01,
      softMax = 3,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Proc" end,
    },
    glow_space3 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = 11,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glowLength = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Length"],
      order = 12,
      min = 1,
      softMax = 20,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glowThickness = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Thickness"],
      order = 13,
      min = 0.05,
      softMax = 20,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glow_space4 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = 14,
      hidden = hiddenGlowExtra,
    },
    glowXOffset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["X-Offset"],
      order = 15,
      softMin = -100,
      softMax = 100,
      step = 0.5,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glowYOffset = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Y-Offset"],
      order = 16,
      softMin = -100,
      softMax = 100,
      step = 0.5,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glow_space5 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = 17,
      hidden = hiddenGlowExtra,
    },
    glowScale = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Scale"],
      order = 18,
      min = 0.05,
      softMax = 10,
      step = 0.05,
      isPercent = true,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "ACShine" end,
    },
    glowBorder = {
      type = "toggle",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Border"],
      order = 19,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },

    glow_expand_anchor = {
      type = "description",
      name = "",
      order = 20,
      hidden = hiddenGlowExtra,
      control = "WeakAurasExpandAnchor",
      arg = {
        expanderName = "glow" .. index .. "#" .. subIndex
      }
    }
  }

  OptionsPrivate.AddUpDownDeleteDuplicate(options, parentData, index, "subglow")

  return options
end

WeakAuras.RegisterSubRegionOptions("subglow", createOptions, L["Shows a glow"]);
