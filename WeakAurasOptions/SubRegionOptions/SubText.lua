if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0")
local L = WeakAuras.L

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20

local self_point_types = {
  BOTTOMLEFT = L["Bottom Left"],
  BOTTOM = L["Bottom"],
  BOTTOMRIGHT = L["Bottom Right"],
  RIGHT = L["Right"],
  TOPRIGHT = L["Top Right"],
  TOP = L["Top"],
  TOPLEFT = L["Top Left"],
  LEFT = L["Left"],
  CENTER = L["Center"],
  AUTO = L["Automatic"]
}

local function createOptions(parentData, data, index, subIndex)
  -- The toggles for font flags is intentionally not keyed on the id
  -- So that all auras share the state of that toggle
  local hiddenFontExtra = function()
    return WeakAuras.IsCollapsed("subtext", "subtext", "fontflags" .. index, true)
  end

  local indentWidth = 0.15

  local options = {
    __title = L["Text %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionUp, index, "subtext")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __down = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.MoveSubRegionDown, index, "subtext")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __duplicate = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DuplicateSubRegion, index, "subtext")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __delete = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, WeakAuras.DeleteSubRegion, index, "subtext")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    text_visible = {
      type = "toggle",
      width = WeakAuras.halfWidth,
      order = 9,
      name = L["Show Text"],
    },
    text_color = {
      type = "color",
      width = WeakAuras.halfWidth,
      name = L["Color"],
      hasAlpha = true,
      order = 10,
    },
    text_text = {
      type = "input",
      width = WeakAuras.normalWidth,
      desc = function()
        return L["Dynamic text tooltip"] .. WeakAuras.GetAdditionalProperties(parentData)
      end,
      name = L["Display Text"],
      order = 11,
    },
    text_font = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Font",
      name = L["Font"],
      order = 12,
      values = AceGUIWidgetLSMlists.font,
    },
    text_fontSize = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Size"],
      order = 13,
      min = 6,
      softMax = 72,
      step = 1,
    },
    text_fontFlagsDescription = {
      type = "description",
      name = function()
        local textFlags = WeakAuras.font_flags[data.text_fontType]
        local color = format("%02x%02x%02x%02x",
                             data.text_shadowColor[4] * 255, data.text_shadowColor[1] * 255,
                             data.text_shadowColor[2] * 255, data.text_shadowColor[3]*255)

        local textJustify = ""
        if data.text_justify == "CENTER" then

        elseif data.text_justify == "LEFT" then
          textJustify = " " .. L["and aligned left"]
        elseif data.text_justify == "RIGHT" then
          textJustify = " " ..  L["and aligned right"]
        end

        local textRotate = ""
        if data.rotateText == "LEFT" then
          textRotate = " " .. L["and rotated left"]
        elseif data.rotateText == "RIGHT" then
          textRotate = " " .. L["and rotated right"]
        end

        local secondline = L["|cFFffcc00Font Flags:|r |cFFFF0000%s|r and shadow |c%sColor|r with offset |cFFFF0000%s/%s|r%s%s"]:format(textFlags, color, data.text_shadowXOffset, data.text_shadowYOffset, textRotate, textJustify)

        return secondline
      end,
      width = WeakAuras.doubleWidth - 0.15,
      order = 44,
      fontSize = "medium"
    },
    text_fontFlagsExpand = {
      type = "execute",
      name = "",
      order = 44.1,
      width = 0.15,
      image = function()
        local collapsed = WeakAuras.IsCollapsed("subtext", "subtext", "fontflags" .. index, true)
        return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
      end,
      imageWidth = 24,
      imageHeight = 24,
      func = function()
        local collapsed = WeakAuras.IsCollapsed("subtext", "subtext", "fontflags" .. index, true)
        WeakAuras.SetCollapsed("subtext", "subtext", "fontflags" .. index, not collapsed)
      end
    },

    text_font_space = {
      type = "description",
      name = "",
      order = 45,
      hidden = hiddenFontExtra,
      width = indentWidth
    },

    text_fontType = {
      type = "select",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Outline"],
      order = 46,
      values = WeakAuras.font_flags,
      hidden = hiddenFontExtra
    },
    text_shadowColor = {
      type = "color",
      hasAlpha = true,
      width = WeakAuras.normalWidth,
      name = L["Shadow Color"],
      order = 47,
      hidden = hiddenFontExtra
    },

    text_font_space3 = {
      type = "description",
      name = "",
      order = 47.5,
      hidden = hiddenFontExtra,
      width = indentWidth
    },
    text_shadowXOffset = {
      type = "range",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Shadow X Offset"],
      softMin = -15,
      softMax = 15,
      bigStep = 1,
      order = 48,
      hidden = hiddenFontExtra
    },
    text_shadowYOffset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Shadow Y Offset"],
      softMin = -15,
      softMax = 15,
      bigStep = 1,
      order = 49,
      hidden = hiddenFontExtra
    },

    text_font_space4 = {
      type = "description",
      name = "",
      order = 49.5,
      hidden = hiddenFontExtra,
      width = indentWidth
    },
    rotateText = {
      type = "select",
      width = WeakAuras.normalWidth - indentWidth,
      name = L["Rotate Text"],
      values = WeakAuras.text_rotate_types,
      order = 50,
      hidden = hiddenFontExtra
    },
    text_justify = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Alignment"],
      values = WeakAuras.justify_types,
      order = 50.5,
      hidden = hiddenFontExtra
    }
  }

  -- Note: Anchor Options need to be generalized once there are multiple sub regions
  -- While every sub region will have anchor options, the initial
  -- design I had for anchor options proved to be not general enough for
  -- what SubText needed. So, I removed it, and postponed making it work for unknown future
  -- sub regions
  local anchors
  if parentData.controlledChildren then
    anchors = {}
    for index, childId in ipairs(parentData.controlledChildren) do
      local childData = WeakAuras.GetData(childId)
      Mixin(anchors, WeakAuras.GetAnchorsForData(childData, "point"))
    end
  else
     anchors = WeakAuras.GetAnchorsForData(parentData, "point")
  end
  -- Anchor Options
  options.text_anchorsDescription = {
    type = "description",
    name = function()
      local selfPoint = data.text_selfPoint ~= "AUTO" and self_point_types[data.text_selfPoint]
      local anchorPoint = anchors[data.text_anchorPoint or "CENTER"] or anchors["CENTER"]

      local xOffset = data.anchorXOffset or 0
      local yOffset = data.anchorYOffset or 0

      if (type(anchorPoint) == "table") then
        anchorPoint = anchorPoint[1] .. "/" .. anchorPoint[2]
      end

      if selfPoint then
        if xOffset == 0 and yOffset == 0 then
          return L["|cFFffcc00Anchors:|r Anchored |cFFFF0000%s|r to frame's |cFFFF0000%s|r"]:format(selfPoint, anchorPoint)
        else
          return L["|cFFffcc00Anchors:|r Anchored |cFFFF0000%s|r to frame's |cFFFF0000%s|r with offset |cFFFF0000%s/%s|r"]:format(selfPoint, anchorPoint, xOffset, yOffset)
        end
      else
        if xOffset == 0 and yOffset == 0 then
          return L["|cFFffcc00Anchors:|r Anchored to frame's |cFFFF0000%s|r"]:format(anchorPoint)
        else
          return L["|cFFffcc00Anchors:|r Anchored to frame's |cFFFF0000%s|r with offset |cFFFF0000%s/%s|r"]:format(anchorPoint, xOffset, yOffset)
        end
      end
    end,
    width = WeakAuras.doubleWidth - 0.15,
    order = 60,
    fontSize = "medium"
  }

  options.text_expandAnchors = {
    type = "execute",
    name = "",
    order = 60.1,
    width = 0.15,
    image = function()
      local collapsed = WeakAuras.IsCollapsed("subregion", "text_anchors", tostring(index), true)
      return collapsed and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
    end,
    imageWidth = 24,
    imageHeight = 24,
    func = function()
      local collapsed = WeakAuras.IsCollapsed("subregion", "text_anchors", tostring(index), true)
      WeakAuras.SetCollapsed("subregion", "text_anchors", tostring(index), not collapsed)
    end
  }

  local hiddenFunction = function()
    return WeakAuras.IsCollapsed("subregion", "text_anchors", tostring(index), true)
  end

  options.text_anchor_space = {
    type = "description",
    name = "",
    order = 60.15,
    hidden = hiddenFunction,
    width = indentWidth
  }

  options.text_selfPoint = {
    type = "select",
    width = WeakAuras.normalWidth - indentWidth,
    name = L["Anchor"],
    order = 60.2,
    values = self_point_types,
    hidden = hiddenFunction
  }

  options.text_anchorPoint = {
    type = "select",
    width = WeakAuras.normalWidth,
    name = function()
      return L["To Frame's"]
    end,
    order = 60.3,
    values = anchors,
    hidden = hiddenFunction,
    control = "WeakAurasTwoColumnDropdown"
  }

  options.text_anchor_space2 = {
    type = "description",
    name = "",
    order = 60.35,
    hidden = hiddenFunction,
    width = indentWidth
  }

  options.text_anchorXOffset = {
    type = "range",
    width = WeakAuras.normalWidth - indentWidth,
    name = L["X Offset"],
    order = 60.4,
    softMin = (-1 * screenWidth),
    softMax = screenWidth,
    bigStep = 10,
    hidden = hiddenFunction
  }

  options.text_anchorYOffset = {
    type = "range",
    width = WeakAuras.normalWidth,
    name = L["Y Offset"],
    order = 60.5,
    softMin = (-1 * screenHeight),
    softMax = screenHeight,
    bigStep = 10,
    hidden = hiddenFunction
  }

  local function hideCustomTextOption()
    if not parentData.subRegions then
      return true
    end

    for index, subRegion in ipairs(parentData.subRegions) do
      if subRegion.type == "subtext" and WeakAuras.ContainsCustomPlaceHolder(subRegion.text_text) then
        return false
      end
    end
    return true
  end

  local function CheckTextOptions(placeholders)
    return function()
      if not parentData.subRegions then
        return true
      end

      for index, subRegion in ipairs(parentData.subRegions) do
        if subRegion.type == "subtext" and WeakAuras.ContainsPlaceHolders(subRegion.text_text, placeholders) then
          return false
        end
      end
      return true
    end
  end

  local CheckForTimePlaceHolders = CheckTextOptions("pt")

  local commonTextOptions = {
    __title = L["Common Text"],
    __hidden = function() return hideCustomTextOption() and CheckForTimePlaceHolders() end,
    text_customTextUpdate = {
      type = "select",
      width = WeakAuras.doubleWidth,
      hidden = hideCustomTextOption,
      name = L["Update Custom Text On..."],
      values = WeakAuras.text_check_types,
      order = 3,
      get = function() return parentData.customTextUpdate or "event" end,
      set = function(info, v)
        parentData.customTextUpdate = v
        WeakAuras.Add(parentData)
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    },
    -- Code Editor added below
    text_progressPrecision = {
      type = "select",
      width = WeakAuras.normalWidth,
      hidden = CheckForTimePlaceHolders,
      disabled = CheckTextOptions("p"),
      order = 5,
      name = L["Remaining Time Precision"],
      values = WeakAuras.precision_types,
      get = function() return parentData.progressPrecision or 1 end,
      set = function(info, v)
        parentData.progressPrecision = v
        WeakAuras.Add(parentData)
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end,
    },
    text_totalPrecision = {
      type = "select",
      width = WeakAuras.normalWidth,
      hidden = CheckForTimePlaceHolders,
      disabled = CheckTextOptions("t"),
      order = 6,
      name = L["Total Time Precision"],
      values = WeakAuras.precision_types,
      get = function() return parentData.totalPrecision or 1 end,
      set = function(info, v)
        parentData.totalPrecision = v
        WeakAuras.Add(parentData)
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end,
    },
  }

  WeakAuras.AddCodeOption(commonTextOptions, parentData, L["Custom Function"], "customText", 4,  hideCustomTextOption, {"customText"}, false)

  return options, commonTextOptions
end

WeakAuras.RegisterSubRegionOptions("subtext", createOptions, L["Shows one or more lines of text, which can include dynamic information such as progress or stacks"])
