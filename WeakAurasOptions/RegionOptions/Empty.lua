if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L

local function createOptions(id, data)
  local options = {
    __title = L["Settings"],
    __order = 1,
    alpha = {
      type = "range",
      control = "WeakAurasSpinBox",
      width = WeakAuras.normalWidth,
      name = L["Alpha"],
      order = 1,
      min = 0,
      max = 1,
      bigStep = 0.01,
      isPercent = true
    },
  }

  return {
    empty = options,
    position = OptionsPrivate.commonOptions.PositionOptions(id, data),
  }

end

local function createThumbnail()
  ---@class frame: FrameScriptObject
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetWidth(32)
  frame:SetHeight(32)

  local border = frame:CreateTexture(nil, "OVERLAY")
  border:SetAllPoints(frame)
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp")
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8)

  return frame
end

local function modifyThumbnail(parent, frame, data)

end

-- Register new region type options with WeakAuras
OptionsPrivate.registerRegions = OptionsPrivate.registerRegions or {}
table.insert(OptionsPrivate.registerRegions, function()
  OptionsPrivate.Private.RegisterRegionOptions("empty", createOptions, createThumbnail, L["Empty Base Region"],
                                               createThumbnail, modifyThumbnail,
                                               L["Shows nothing, except sub elements"]);
end)
