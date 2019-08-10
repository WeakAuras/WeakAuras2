if not WeakAuras.IsCorrectVersion() then return end

--[[-----------------------------------------------------------------------------
WeakAurasTemplateGroup Container
Simple container that is used in the template selection
-------------------------------------------------------------------------------]]
local Type, Version = "WeakAurasTemplateGroup", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(300)
    self:SetHeight(100)
  end,

  ["LayoutFinished"] = function(self, width, height)
    if self.noAutoHeight then return end
    self:SetHeight((height or 0) + 15)
  end,

  ["OnWidthSet"] = function(self, width)
    local content = self.content
    local contentwidth = width - 20
    if contentwidth < 0 then
      contentwidth = 0
    end
    content:SetWidth(contentwidth)
    content.width = contentwidth
  end,

  ["OnHeightSet"] = function(self, height)
    local content = self.content
    local contentheight = height - 15
    if contentheight < 0 then
      contentheight = 0
    end
    content:SetHeight(contentheight)
    content.height = contentheight
  end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local PaneBackdrop  = {
  bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")

  --Container Support
  local content = CreateFrame("Frame", nil, frame)
  content:SetPoint("TOPLEFT", 20, 0)
  content:SetPoint("BOTTOMRIGHT", 0, 15)

  local widget = {
    frame     = frame,
    content   = content,
    type      = Type
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
