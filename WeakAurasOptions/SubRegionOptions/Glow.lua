if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;
local LCG = LibStub("LibCustomGlow-1.0")

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;


local indentWidth = 0.15

local glows = LCG:GetGlows()
local function getDefaults(glowType)
  local options = {}
  local function recurse(settings, prefix, parent)
    for k, v in pairs(settings) do
        if ( type(v) == "table" ) then
          recurse(
              v,
              (prefix or "")..(v.args and k.."_" or ""),
              k
          )
        end
        if settings.type ~= "group" and k == "default" then
          options[prefix..parent] = v
        end
    end
  end
  glowType = glows[glowType] and glowType or "Button Glow" -- TODO: remove after migration is done
  recurse(glows[glowType])
  return options
end

local function LCGkeyToData(glowType, key)
  glowType = glows[glowType] and glowType or "Button Glow" -- TODO: remove after migration is done
  local key1, key2, key3, key4, more
  key1, more = key:match("^([^_]+)(.*)")
  if more then
    key2, more = more:match("_([^_]+)(.*)")
    if more then
        key3, more = more:match("_([^_]+)(.*)")
        if more then
          key4 = more:match("_([^_]+)(.*)")
      end
    end
  end
  if key1 then
    if key2 then
      if key3 then
        if key4 then
          return glows[glowType].args[key1].args[key2].args[key3].args[key4]
        else
          return glows[glowType].args[key1].args[key2].args[key3]
        end
      else
        return glows[glowType].args[key1].args[key2]
      end
    else
      return glows[glowType].args[key1]
    end
  end
end

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
            local key = v.name and ("sub."..index..".subglow."..(level > 2 and prefix or ""))..k or k
            copy[key] = MyCopyTable(
              v,
              level + 1,
              glowType or k,
              (level > 2 and prefix or "")..(v.args and k.."_" or "")
            )
          else
            copy[k] = v
            if k == "desc" then
              copy.width = WeakAuras.normalWidth - ((level - 1) * 0.03)
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
        local defaults = getDefaults(data.glowType)
        for k, v in pairs(defaults) do
          if data[k] then
            local keyData = LCGkeyToData(data.glowType, k)
            local default = keyData and keyData.default
            if type(v) ~= "table" then
              if data[k] ~= v then
                if type(v) == "boolean" then
                  line = ("%s %s,"):format(line, WrapTextInColorCode(keyData.name, data[k] and "ff00ff00" or "ffff0000"))
                else
                  line = ("%s %s: %s,"):format(line, keyData.name, tostring(data[k]))
                end
              end
            else
              if keyData.type == "color"
                and (
                  data[k][1] ~= v[1]
                  or data[k][2] ~= v[2]
                  or data[k][3] ~= v[3]
                )
              then
                line = ("%s %s,"):format(line, WrapTextInColorCode(keyData.name, CreateColor(data[k][1], data[k][2], data[k][3], 1):GenerateHexColor()))
              end
            end
          end
        end
        return line:match("(.*),$") or line
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
