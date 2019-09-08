if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;


local indentWidth = 0.15


local function createOptions(parentData, data, index, subIndex)

  local hiddenGlowExtra = function()
    return WeakAuras.IsCollapsed("glow", "glow", "glowextra" .. index, true);
  end

  local order = 9
  local options = {
    __title = L["Glow %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionUp, index, "subglow")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __down = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionDown, index, "subglow")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __duplicate = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DuplicateSubRegion, index, "subglow")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __delete = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DeleteSubRegion, index, "subglow")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    glow = {
      type = "toggle",
      width = WeakAuras.normalWidth,
      name = L["Show Glow"],
      order = order + 0.02,
    },
    glowType = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Type"],
      order = order + 0.03,
      values = WeakAuras.glow_types,
    },
    glow_anchor = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Border Anchor"],
      order = order + 0.6,
      values = WeakAuras.aurabar_anchor_areas,
      hidden = function() return parentData.regionType ~= "aurabar" end
    },
    glowExtraDescription = {
      type = "description",
      name = function()
        local line = L["|cFFffcc00Extra Options:|r"]
        local color = L["Default Color"]
        if data.useGlowColor then
          color = L["|c%02x%02x%02x%02xColor|r"]:format(
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
        end
        return line
      end,
      width = WeakAuras.doubleWidth - 0.15,
      order = order + 1,
      fontSize = "medium"
    },
    glowExpand = {
      type = "execute",
      name = function()
        local collapsed = WeakAuras.IsCollapsed("glow", "glow", "glowextra" .. index, true)
        return collapsed and L["Show Extra Options"] or L["Hide Extra Options"]
      end,
      order = order + 1.01,
      width = 0.15,
      image = function()
        local collapsed = WeakAuras.IsCollapsed("glow", "glow", "glowextra" .. index, true);
        return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
      end,
      imageWidth = 24,
      imageHeight = 24,
      func = function()
        local collapsed = WeakAuras.IsCollapsed("glow", "glow", "glowextra" .. index, true);
        WeakAuras.SetCollapsed("glow", "glow", "glowextra" .. index, not collapsed);
      end,
      control = "WeakAurasIcon"
    },
    glow_space1 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.10,
      hidden = hiddenGlowExtra,
    },
    useGlowColor = {
      type = "toggle",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Color"],
      desc = L["If unchecked, then a default color will be used (usually yellow)"],
      order = order + 1.11,
      hidden = hiddenGlowExtra
    },
    glowColor = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Color"],
      order = order + 1.12,
      disabled = function() return not data.useGlowColor end,
      hidden = hiddenGlowExtra
    },
    glow_space2 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.20,
      hidden = hiddenGlowExtra,
    },
    glowLines = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Lines & Particles"],
      order = order + 1.21,
      min = 1,
      softMax = 30,
      step = 1,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glowFrequency = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Frequency"],
      order = order + 1.22,
      softMin = -2,
      softMax = 2,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glow_space3 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.30,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glowLength = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Length"],
      order = order + 1.31,
      min = 1,
      softMax = 20,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glowThickness = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Thickness"],
      order = order + 1.32,
      min = 0.05,
      softMax = 20,
      step = 0.05,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    },
    glow_space4 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.40,
      hidden = hiddenGlowExtra,
    },
    glowXOffset = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["X-Offset"],
      order = order + 1.41,
      softMin = -100,
      softMax = 100,
      step = 0.5,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glowYOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Y-Offset"],
      order = order + 1.42,
      softMin = -100,
      softMax = 100,
      step = 0.5,
      hidden = function() return hiddenGlowExtra() or data.glowType == "buttonOverlay" end,
    },
    glow_space5 = {
      type = "description",
      name = "",
      width = indentWidth,
      order = order + 1.50,
      hidden = hiddenGlowExtra,
    },
    glowScale = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Scale"],
      order = order + 1.52,
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
      order = order + 1.53,
      hidden = function() return hiddenGlowExtra() or data.glowType ~= "Pixel" end,
    }
  }
  return options
end

WeakAuras.RegisterSubRegionOptions("subglow", createOptions, L["Shows a glow"]);
