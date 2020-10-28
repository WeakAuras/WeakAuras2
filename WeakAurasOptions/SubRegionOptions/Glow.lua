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
    --local subindex = 0
    local function MyCopyTable(settings, glowType, level)
      local copy = {}
      if settings.type == "gradient" then -- TODO: not a valid ace3 type
        return nil
      end
      for k, v in pairs(settings) do
        if ( type(v) == "table" ) then
          --[[
          if v.desc then
            if subindex % 2 == 0 then
              copy[(level==1 and glowType or "")..k.."space"] = {
                type = "description",
                name = "",
                width = indentWidth,
                order = order,
                hidden = function() return hiddenGlowExtra() or data.glowType ~= glowType end
              }
              order = order + 1
              print("add space")
            end
          end
          subindex = 0
          ]]--
          copy[(level==1 and glowType or "")..k] = MyCopyTable(v, glowType, level + 1)
        else
          copy[k] = v
          if k == "desc" then
            copy.order = order
            --copy.width = v.type == "group" and WeakAuras.normalWidth or (subindex % 2 == 0) and WeakAuras.normalWidth - indentWidth or WeakAuras.normalWidth
            copy.width = WeakAuras.normalWidth
            local glowType = glowType
            copy.hidden = function() return hiddenGlowExtra() or data.glowType ~= glowType end
            copy.default = nil
            copy.start = nil
            copy.stop = nil
            order = order + 1
            --subindex = subindex + 1 -- (v.type == "group" and subindex % 2 == 0 and 2 or 1)
          end
        end
      end
      --subindex = 0
      return copy
    end

    for glowType, glowTable in pairs(LCG:GetGlows()) do
      WeakAuras.DeepMixin(options, MyCopyTable(glowTable.args, glowType, 1))
      --ViragDevTool_AddData(MyCopyTable(glowTable.args, glowType), glowType)
    end
    ViragDevTool_AddData(options, "options")
    return order
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
  return options
end

WeakAuras.RegisterSubRegionOptions("subglow", createOptions, L["Shows a glow"]);
