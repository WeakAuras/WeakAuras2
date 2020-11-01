if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;
local LCG = LibStub("LibCustomGlow-1.0")

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;


local indentWidth = 0.15

local function createOptions(parentData, data, index, subIndex)
  local hiddenGlowExtra = function()
    return OptionsPrivate.IsCollapsed("glow", "glow", "glowextra" .. index, true);
  end

  local addOptionsFromLCG = function(options, order)
    local maxOrder = 0

    local function MyCopyTable(settings, level, glowType, prefix)
      local copy = {}
      if settings.type == "gradient" then -- TODO: not a valid ace3 type
        return nil
      end
      for k, v in pairs(settings) do
        if k ~= "default"
        and k ~= "start"
        and k ~= "stop"
        then
          if ( type(v) == "table" ) then
            local key = v.name and ("sub."..index..".subglow."..(prefix or ""))..k or k
            copy[key] = MyCopyTable(
              v,
              level + 1,
              glowType or k,
              (prefix or "")..(v.args and k.."_" or "")
            )
          else
            copy[k] = v
            if k == "desc" then
              copy.width = WeakAuras.normalWidth - (level < 4 and indentWidth or indentWidth * 1.5)
              local glowType = glowType
              copy.hidden = function() return hiddenGlowExtra() or data.glowType ~= glowType end
            elseif k == "type" and v == "group" then
              copy.inline = true
            elseif k == "order" and level == 2 then
              copy[k] = v + order
              maxOrder = max(maxOrder, copy[k])
            end
          end
        end
      end
      return copy
    end

    WeakAuras.DeepMixin(options, MyCopyTable(LCG:GetGlows(), 1))
    --ViragDevTool_AddData(options, "options")
    return maxOrder + 1
  end

  local options = {
    __title = L["Glow %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (OptionsPrivate.Private.ApplyToDataOrChildData(parentData, OptionsPrivate.MoveSubRegionUp, index, "subglow")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __down = function()
      if (OptionsPrivate.Private.ApplyToDataOrChildData(parentData, OptionsPrivate.MoveSubRegionDown, index, "subglow")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __duplicate = function()
      if (OptionsPrivate.Private.ApplyToDataOrChildData(parentData, OptionsPrivate.DuplicateSubRegion, index, "subglow")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
    __delete = function()
      if (OptionsPrivate.Private.ApplyToDataOrChildData(parentData, WeakAuras.DeleteSubRegion, index, "subglow")) then
        WeakAuras.ClearAndUpdateOptions(parentData.id)
      end
    end,
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
    }
  }

  local order = addOptionsFromLCG(options, 6)
  options.glow_anchor_anchor = {
    type = "description",
    name = "",
    order = order,
    hidden = hiddenGlowExtra,
    control = "WeakAurasExpandAnchor",
    arg = {
      expanderName = "glow" .. index .. "#" .. subIndex
    }
  }
  --ViragDevTool_AddData(options, "createOptions")
  return options
end

WeakAuras.RegisterSubRegionOptions("subglow", createOptions, L["Shows a glow"]);
