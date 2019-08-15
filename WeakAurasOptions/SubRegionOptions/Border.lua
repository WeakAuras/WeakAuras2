if not WeakAuras.IsCorrectVersion() then return end

local SharedMedia = LibStub("LibSharedMedia-3.0");
local L = WeakAuras.L;

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local function DeleteSubRegion(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    tremove(data.subRegions, index)
    WeakAuras.Add(data)
    WeakAuras.ReloadOptions2(data.id, data)
  end
end

local function MoveSubRegionUp(data, index, regionType)
  if not data.subRegions or index <= 1 then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType then
    data.subRegions[index - 1], data.subRegions[index] = data.subRegions[index], data.subRegions[index - 1]
    WeakAuras.Add(data)
    WeakAuras.ReloadOptions2(data.id, data)
  end
end

local function MoveSubRegionDown(data, index, regionType)
  if not data.subRegions then
    return
  end
  if data.subRegions[index] and data.subRegions[index].type == regionType and data.subRegions[index + 1] then
    data.subRegions[index], data.subRegions[index + 1] = data.subRegions[index + 1], data.subRegions[index]
    WeakAuras.Add(data)
    WeakAuras.ReloadOptions2(data.id, data)
  end
end

local function createOptions(parentData, data, index, subIndex)
  local order = 9
  local options = {
    __title = L["Border %s"]:format(subIndex),
    __order = 1,
    __up = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, MoveSubRegionUp, index, "subborder")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __down = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, MoveSubRegionDown, index, "subborder")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    __delete = function()
      if (WeakAuras.ApplyToDataOrChildData(parentData, DeleteSubRegion, index, "subborder")) then
        WeakAuras.ReloadOptions2(parentData.id, parentData)
      end
    end,
    border_visible = {
      type = "toggle",
      width = WeakAuras.doubleWidth,
      name = L["Show Border"],
      order = order + 0.1,
    },
    border_edge = {
      type = "select",
      width = WeakAuras.normalWidth,
      dialogControl = "LSM30_Border",
      name = L["Border Style"],
      order = order + 0.2,
      values = AceGUIWidgetLSMlists.border,
    },
    border_color = {
      type = "color",
      width = WeakAuras.normalWidth,
      name = L["Border Color"],
      hasAlpha = true,
      order = order + 0.3,
    },
    border_offset = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Border Offset"],
      order = order + 0.4,
      softMin = 0,
      softMax = 32,
      bigStep = 1,
    },
    border_size = {
      type = "range",
      width = WeakAuras.normalWidth,
      name = L["Border Size"],
      order = order + 0.5,
      softMin = 1,
      softMax = 64,
      bigStep = 1,
    },
    border_anchor = {
      type = "select",
      width = WeakAuras.normalWidth,
      name = L["Border Anchor"],
      order = order + 0.6,
      values = {
        icon = L["Icon"],
        fg = L["Foreground"],
        bg = L["Background"],
        bar = L["Bar"],
      },
      hidden = function() return parentData.regionType ~= "aurabar" end
    }
  }

  return options
end

WeakAuras.RegisterSubRegionOptions("subborder", createOptions, L["Shows a border"]);
