if not WeakAuras.IsLibsOK() then return end
local AddonName, OptionsPrivate = ...


-- Lua APIs
local pairs = pairs

-- WoW APIs
local IsShiftKeyDown, CreateFrame =  IsShiftKeyDown, CreateFrame

local WeakAuras = WeakAuras
local L = WeakAuras.L

local moversizer
local mover

local function EnsureTexture(self, texture)
  if texture then
    return texture
  else
    local ret = self:CreateTexture()
    ret:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp")
    ret:SetWidth(16)
    ret:SetHeight(16)
    ret:SetTexCoord(0, 0.25, 0, 1)
    ret:SetVertexColor(1, 1, 1, 0.25)
    return ret
  end
end

local function moveOnePxl(direction)
  if mover and mover.moving then
    local data = mover.moving.data
    if data then
      if direction == "top" then
        data.yOffset = data.yOffset + 1
      elseif direction == "bottom" then
        data.yOffset = data.yOffset - 1
      elseif direction == "left" then
        data.xOffset = data.xOffset - 1
      elseif direction == "right" then
        data.xOffset = data.xOffset + 1
      end
      WeakAuras.Add(data, nil, true)
      WeakAuras.UpdateThumbnail(data)
      OptionsPrivate.ResetMoverSizer()
      OptionsPrivate.Private.AddParents(data)
      WeakAuras.FillOptions()
    end
  end
end

local function ConstructMover(frame)
  local topAndBottom = CreateFrame("Frame", nil, frame)
  topAndBottom:SetClampedToScreen(true)
  topAndBottom:SetSize(25, 45)
  topAndBottom:SetPoint("LEFT", frame, "RIGHT", 1, 0)
  local top = CreateFrame("Button", nil, topAndBottom)
  top:SetSize(25, 25)
  top:SetPoint("TOP", topAndBottom)
  top:SetFrameStrata("BACKGROUND")
  local bottom = CreateFrame("Button", nil, topAndBottom)
  bottom:SetSize(25, 25)
  bottom:SetPoint("BOTTOM", topAndBottom)
  bottom:SetFrameStrata("BACKGROUND")

  local leftAndRight = CreateFrame("Frame", nil, frame)
  leftAndRight:SetClampedToScreen(true)
  leftAndRight:SetSize(45, 25)
  leftAndRight:SetPoint("TOP", frame, "BOTTOM", 0, 1)
  local left = CreateFrame("Button", nil, leftAndRight)
  left:SetSize(25, 25)
  left:SetPoint("LEFT", leftAndRight)
  left:SetFrameStrata("BACKGROUND")
  local right = CreateFrame("Button", nil, leftAndRight)
  right:SetSize(25, 25)
  right:SetPoint("RIGHT", leftAndRight)
  right:SetFrameStrata("BACKGROUND")

  top:SetNormalTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-up.blp")
  top:SetHighlightTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-highlight.blp")
  top:SetPushedTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-down.blp")
  top:SetScript("OnClick", function() moveOnePxl("top") end)

  bottom:SetNormalTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-up.blp")
  bottom:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
  bottom:SetHighlightTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-highlight.blp")
  bottom:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
  bottom:SetPushedTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-down.blp")
  bottom:GetPushedTexture():SetTexCoord(0, 1, 1, 0)
  bottom:SetScript("OnClick", function() moveOnePxl("bottom") end)

  left:SetNormalTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-up.blp")
  left:GetNormalTexture():SetRotation(math.pi/2)
  left:SetHighlightTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-highlight.blp")
  left:GetHighlightTexture():SetRotation(math.pi/2)
  left:SetPushedTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-down.blp")
  left:GetPushedTexture():SetRotation(math.pi/2)
  left:SetScript("OnClick", function() moveOnePxl("left") end)

  right:SetNormalTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-up.blp")
  right:GetNormalTexture():SetRotation(-math.pi/2)
  right:SetHighlightTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-highlight.blp")
  right:GetHighlightTexture():SetRotation(-math.pi/2)
  right:SetPushedTexture("interface\\buttons\\ui-scrollbar-scrollupbutton-down.blp")
  right:GetPushedTexture():SetRotation(-math.pi/2)
  right:SetScript("OnClick", function() moveOnePxl("right") end)

  local arrow = CreateFrame("Frame", nil, frame)
  arrow:SetClampedToScreen(true)
  arrow:SetSize(196, 196)
  arrow:SetPoint("CENTER", frame, "CENTER")
  arrow:SetFrameStrata("HIGH")
  local arrowTexture = arrow:CreateTexture()
  arrowTexture:SetTexture("Interface\\Addons\\WeakAuras\\Media\\Textures\\offscreen.tga")
  arrowTexture:SetSize(128, 128)
  arrowTexture:SetPoint("CENTER", arrow, "CENTER")
  arrowTexture:SetVertexColor(0.8, 0.8, 0.2)
  arrowTexture:Hide()
  local offscreenText = arrow:CreateFontString(nil, "OVERLAY")
  offscreenText:SetFont(STANDARD_TEXT_FONT, 14, "THICKOUTLINE");
  offscreenText:SetText(L["Aura is\nOff Screen"])
  offscreenText:Hide()
  offscreenText:SetPoint("CENTER", arrow, "CENTER")

  local lineX = frame:CreateLine(nil, "OVERLAY", 7)
  lineX:SetThickness(2)
  lineX:SetColorTexture(1,1,0)
  lineX:SetStartPoint("BOTTOMLEFT", UIParent)
  lineX:SetEndPoint("BOTTOMRIGHT", UIParent)
  lineX:Hide()
  lineX:SetIgnoreParentAlpha(true)

  local lineY = frame:CreateLine(nil, "OVERLAY", 7)
  lineY:SetThickness(2)
  lineY:SetColorTexture(1,1,0)
  lineY:SetStartPoint("TOPLEFT", UIParent)
  lineY:SetEndPoint("BOTTOMLEFT", UIParent)
  lineY:SetIgnoreParentAlpha(true)
  lineY:Hide()

  return lineX, lineY, arrowTexture, offscreenText
end

local function ConstructSizer(frame)
  -- topright, bottomright, bottomleft, topleft

  local topright = CreateFrame("Frame", nil, frame)
  topright:EnableMouse()
  topright:SetWidth(16)
  topright:SetHeight(16)
  topright:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

  local texTR1 = topright:CreateTexture(nil, "OVERLAY")
  texTR1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texTR1:SetBlendMode("ADD")
  texTR1:SetTexCoord(0.5, 0, 0, 0, 0.5, 1, 0, 1)
  texTR1:SetPoint("TOPRIGHT", topright, "TOPRIGHT", -3, -3)
  texTR1:SetPoint("BOTTOMLEFT", topright, "BOTTOM")

  local texTR2 = topright:CreateTexture(nil, "OVERLAY")
  texTR2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texTR2:SetBlendMode("ADD")
  texTR2:SetTexCoord(0, 0, 0, 1, 0.5, 0, 0.5, 1)
  texTR2:SetPoint("TOPRIGHT", texTR1, "TOPLEFT")
  texTR2:SetPoint("BOTTOMLEFT", topright, "LEFT")

  topright.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texTR1:Show()
    texTR2:Show()
  end
  topright.Clear = function()
    texTR1:Hide()
    texTR2:Hide()
  end

  local bottomright = CreateFrame("Frame", nil, frame)
  bottomright:EnableMouse()
  bottomright:SetWidth(16)
  bottomright:SetHeight(16)
  bottomright:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local texBR1 = bottomright:CreateTexture(nil, "OVERLAY")
  texBR1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texBR1:SetBlendMode("ADD")
  texBR1:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1)
  texBR1:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMRIGHT", -3, 3)
  texBR1:SetPoint("TOPLEFT", bottomright, "TOP")

  local texBR2 = bottomright:CreateTexture(nil, "OVERLAY")
  texBR2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texBR2:SetBlendMode("ADD")
  texBR2:SetTexCoord(0, 0, 0, 1, 0.5, 0, 0.5, 1)
  texBR2:SetPoint("BOTTOMRIGHT", texBR1, "BOTTOMLEFT")
  texBR2:SetPoint("TOPLEFT", bottomright, "LEFT")

  bottomright.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texBR1:Show()
    texBR2:Show()
  end
  bottomright.Clear = function()
    texBR1:Hide()
    texBR2:Hide()
  end

  local bottomleft = CreateFrame("Frame", nil, frame)
  bottomleft:EnableMouse()
  bottomleft:SetSize(16, 16)
  bottomleft:SetHeight(16)
  bottomleft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")

  local texBL1 = bottomleft:CreateTexture(nil, "OVERLAY")
  texBL1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texBL1:SetBlendMode("ADD")
  texBL1:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1)
  texBL1:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3)
  texBL1:SetPoint("TOPRIGHT", bottomleft, "TOP")

  local texBL2 = bottomleft:CreateTexture(nil, "OVERLAY")
  texBL2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texBL2:SetBlendMode("ADD")
  texBL2:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1)
  texBL2:SetPoint("BOTTOMLEFT", texBL1, "BOTTOMRIGHT")
  texBL2:SetPoint("TOPRIGHT", bottomleft, "RIGHT")

  bottomleft.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texBL1:Show()
    texBL2:Show()
  end
  bottomleft.Clear = function()
    texBL1:Hide()
    texBL2:Hide()
  end

  local topleft = CreateFrame("Frame", nil, frame)
  topleft:EnableMouse()
  topleft:SetWidth(16)
  topleft:SetHeight(16)
  topleft:SetPoint("TOPLEFT", frame, "TOPLEFT")

  local texTL1 = topleft:CreateTexture(nil, "OVERLAY")
  texTL1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texTL1:SetBlendMode("ADD")
  texTL1:SetTexCoord(0.5, 0, 0, 0, 0.5, 1, 0, 1)
  texTL1:SetPoint("TOPLEFT", topleft, "TOPLEFT", 3, -3)
  texTL1:SetPoint("BOTTOMRIGHT", topleft, "BOTTOM")

  local texTL2 = topleft:CreateTexture(nil, "OVERLAY")
  texTL2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texTL2:SetBlendMode("ADD")
  texTL2:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1)
  texTL2:SetPoint("TOPLEFT", texTL1, "TOPRIGHT")
  texTL2:SetPoint("BOTTOMRIGHT", topleft, "RIGHT")

  topleft.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texTL1:Show()
    texTL2:Show()
  end
  topleft.Clear = function()
    texTL1:Hide()
    texTL2:Hide()
  end

  -- top, right, bottom, left

  local top = CreateFrame("Frame", nil, frame)
  top:EnableMouse()
  top:SetHeight(8)
  top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
  top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")

  local texT = top:CreateTexture(nil, "OVERLAY")
  texT:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texT:SetBlendMode("ADD")
  texT:SetPoint("TOPRIGHT", topright, "TOPRIGHT", -3, -3)
  texT:SetPoint("BOTTOMLEFT", topleft, "LEFT", 3, 0)

  top.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texT:Show()
  end
  top.Clear = function()
    texT:Hide()
  end

  local right = CreateFrame("Frame", nil, frame)
  right:EnableMouse()
  right:SetWidth(8)
  right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
  right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")

  local texR = right:CreateTexture(nil, "OVERLAY")
  texR:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texR:SetBlendMode("ADD")
  texR:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMRIGHT", -3, 3)
  texR:SetPoint("TOPLEFT", topright, "TOP", 0, -3)

  right.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texR:Show()
  end
  right.Clear = function()
    texR:Hide()
  end

  local bottom = CreateFrame("Frame", nil, frame)
  bottom:EnableMouse()
  bottom:SetHeight(8)
  bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
  bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")

  local texB = bottom:CreateTexture(nil, "OVERLAY")
  texB:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texB:SetBlendMode("ADD")
  texB:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
  texB:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3)
  texB:SetPoint("TOPRIGHT", bottomright, "RIGHT", -3, 0)

  bottom.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texB:Show()
  end
  bottom.Clear = function()
    texB:Hide()
  end

  local left = CreateFrame("Frame", nil, frame)
  left:EnableMouse()
  left:SetWidth(8)
  left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
  left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")

  local texL = left:CreateTexture(nil, "OVERLAY")
  texL:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
  texL:SetBlendMode("ADD")
  texL:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
  texL:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3)
  texL:SetPoint("TOPRIGHT", topleft, "TOP", 0, -3)

  left.Highlight = function()
    if WeakAurasOptionsSaved.lockPositions then
      return
    end
    texL:Show()
  end
  left.Clear = function()
    texL:Hide()
  end

  -- return in cw order
  return top, topright, right, bottomright, bottom, bottomleft, left, topleft
end

local function BuildAlignLines(mover)
  local data = mover.moving.data
  local align = {
    x = {},
    y = {}
  }
  local x, y = {}, {}
  local skipIds = {}
  for child in OptionsPrivate.Private.TraverseAll(data) do
    skipIds[child.id] = true
  end

  for k, v in pairs(WeakAuras.displayButtons) do
    local region = v.view.region
    if not skipIds[k] and v.view.visibility ~= 0 and region then
      local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
      if not IsControlKeyDown() then
        tinsert(x, (region:GetLeft() or 0) * scale)
        tinsert(x, (region:GetRight() or 0) * scale)
        tinsert(y, (region:GetTop() or 0) * scale)
        tinsert(y, (region:GetBottom() or 0) * scale)
      else
        local centerX, centerY = region:GetCenter()
        tinsert(x, (centerX or 0) * scale)
        tinsert(y, (centerY or 0) * scale)
      end
    end
  end
  local midX, midY = UIParent:GetCenter()
  tinsert(x, midX)
  tinsert(y, midY)
  table.sort(x)
  table.sort(y)
  for index, value in ipairs(x) do
    if value ~= x[index+1] then
      tinsert(align.x, value)
    end
  end
  for index, value in ipairs(y) do
    if value ~= y[index+1] then
      tinsert(align.y, value)
    end
  end
  return align
end

local function ConstructMoverSizer(parent)
  local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  frame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
  })
  frame:EnableMouse()

  frame.top, frame.topright, frame.right, frame.bottomright, frame.bottom, frame.bottomleft, frame.left, frame.topleft
  = ConstructSizer(frame)

  frame.lineX, frame.lineY, frame.arrowTexture, frame.offscreenText = ConstructMover(frame)

  frame.top.Clear()
  frame.topright.Clear()
  frame.right.Clear()
  frame.bottomright.Clear()
  frame.bottom.Clear()
  frame.bottomleft.Clear()
  frame.left.Clear()
  frame.topleft.Clear()

  local mover = CreateFrame("Frame", nil, frame)
  mover:RegisterEvent("PLAYER_REGEN_DISABLED")
  mover:EnableMouse()
  mover.moving = {}
  mover.interims = {}
  mover.selfPointIcon = mover:CreateTexture()
  mover.selfPointIcon:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp")
  mover.selfPointIcon:SetWidth(16)
  mover.selfPointIcon:SetHeight(16)
  mover.selfPointIcon:SetTexCoord(0, 0.25, 0, 1)
  mover.anchorPointIcon = mover:CreateTexture()
  mover.anchorPointIcon:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp")
  mover.anchorPointIcon:SetWidth(16)
  mover.anchorPointIcon:SetHeight(16)
  mover.anchorPointIcon:SetTexCoord(0, 0.25, 0, 1)

  local moverText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  mover.text = moverText
  moverText:Hide()

  local sizerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.text = sizerText
  sizerText:Hide()

  frame.ScaleCorners = function(self, width, height)
    local limit = math.min(width, height) + 16
    local size = 16
    if limit <= 40 then
      size = limit * (2/5)
    end
    frame.bottomleft:SetWidth(size)
    frame.bottomleft:SetHeight(size)
    frame.bottomright:SetWidth(size)
    frame.bottomright:SetHeight(size)
    frame.topright:SetWidth(size)
    frame.topright:SetHeight(size)
    frame.topleft:SetWidth(size)
    frame.topleft:SetHeight(size)
  end

  frame.ReAnchor = function(self)
    if mover.moving.region then
      self:AnchorPoints(mover.moving.region, mover.moving.data)
    end
  end

  frame.AnchorPoints = function(self, region, data)
    local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if data.regionType == "group" then
      mover:SetWidth((region.trx - region.blx) * scale)
      mover:SetHeight((region.try - region.bly) * scale)
    else
      mover:SetWidth(region:GetWidth() * scale)
      mover:SetHeight(region:GetHeight() * scale)
    end
  end

  frame.GetCurrentId = function(self)
    return self.currentId
  end

  frame.SetToRegion = function(self, region, data)
    frame.currentId = data.id
    local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
    mover.moving.region = region
    mover.moving.data = data
    local ok, selfPoint, anchor, anchorPoint, xOff, yOff = pcall(region.GetPoint, region, 1)
    if not ok then
      return
    end
    self:Show()

    mover.selfPoint, mover.anchor, mover.anchorPoint = selfPoint, anchor, anchorPoint

    xOff = xOff or 0
    yOff = yOff or 0
    mover:ClearAllPoints()
    frame:ClearAllPoints()
    if data.regionType == "group" then
      mover:SetWidth((region.trx - region.blx) * scale)
      mover:SetHeight((region.try - region.bly) * scale)
      mover:SetPoint("BOTTOMLEFT", mover.anchor or UIParent, mover.anchorPoint or "CENTER", (xOff + region.blx) * scale, (yOff + region.bly) * scale)
    else
      mover:SetWidth(region:GetWidth() * scale)
      mover:SetHeight(region:GetHeight() * scale)
      mover:SetPoint(mover.selfPoint or "CENTER", mover.anchor or UIParent, mover.anchorPoint or "CENTER", xOff * scale, yOff * scale)
    end
    frame:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", -8, -8)
    frame:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 8, 8)
    frame:ScaleCorners(region:GetWidth(), region:GetHeight())
    local regionStrata = region:GetFrameStrata()
    if regionStrata then
      local strata = math.min(tIndexOf(OptionsPrivate.Private.frame_strata_types, regionStrata) + 1, 9)
      frame:SetFrameStrata(OptionsPrivate.Private.frame_strata_types[strata])
      mover:SetFrameStrata(OptionsPrivate.Private.frame_strata_types[strata])
    end

    local db = OptionsPrivate.savedVars.db
    mover.startMoving = function()
      if WeakAurasOptionsSaved.lockPositions then
        return
      end
      OptionsPrivate.Private.CancelAnimation(region, true, true, true, true, true)
      mover:ClearAllPoints()
      if data.regionType == "group" then
        mover:SetPoint("BOTTOMLEFT", region, mover.anchorPoint, region.blx * scale, region.bly * scale)
      else
        mover:SetPoint(mover.selfPoint, region, mover.selfPoint)
      end
      region:StartMoving()
      mover.isMoving = true
      mover.text:Show()
      -- build list of alignment coordinates
      mover.align = BuildAlignLines(mover)
    end

    mover.doneMoving = function(self, event, key)
      if event == "MODIFIER_STATE_CHANGED" then
        if key == "LCTRL" or key == "RCTRL" then
          mover.align = BuildAlignLines(mover)
        end
        return
      end

      if not mover.isMoving then
        return
      end
      region:StopMovingOrSizing()
      mover.isMoving = false
      mover.text:Hide()

      local align = (WeakAurasOptionsSaved.magnetAlign and not IsShiftKeyDown())
                    or (not WeakAurasOptionsSaved.magnetAlign and IsShiftKeyDown())

      if align and (mover.alignXFrom or mover.alignYFrom) then
        if mover.alignXFrom == "LEFT" then
          local left = region:GetLeft() * scale
          local selfPoint, anchor, anchorPoint, xOff, yOff = region:GetPoint(1)
          if data.regionType == "group" then
            xOff = xOff - region.blx
          end
          region:ClearAllPoints()
          region:SetPoint(selfPoint, anchor, anchorPoint, (xOff * scale - left + mover.alignXOf) / scale, yOff)
        elseif mover.alignXFrom == "RIGHT" then
          local right = region:GetRight() * scale
          local selfPoint, anchor, anchorPoint, xOff, yOff = region:GetPoint(1)
          if data.regionType == "group" then
            xOff = xOff - region.trx
          end
          region:ClearAllPoints()
          region:SetPoint(selfPoint, anchor, anchorPoint, (xOff * scale - right + mover.alignXOf) / scale, yOff)
        elseif mover.alignXFrom == "CENTER" then
          local center = region:GetCenter() * scale
          local selfPoint, anchor, anchorPoint, xOff, yOff = region:GetPoint(1)
          if data.regionType == "group" then
            xOff = xOff - region.trx + (region.trx - region.blx) / 2
          end
          region:ClearAllPoints()
          region:SetPoint(selfPoint, anchor, anchorPoint, (xOff * scale - center + mover.alignXOf) / scale, yOff)
        end
        if mover.alignYFrom == "TOP" then
          local top = region:GetTop() * scale
          local selfPoint, anchor, anchorPoint, xOff, yOff = region:GetPoint(1)
          if data.regionType == "group" then
            yOff = yOff - region.try
          end
          region:ClearAllPoints()
          region:SetPoint(selfPoint, anchor, anchorPoint, xOff, (yOff * scale - top + mover.alignYOf) / scale)
        elseif mover.alignYFrom == "BOTTOM" then
          local bottom = region:GetBottom() * scale
          local selfPoint, anchor, anchorPoint, xOff, yOff = region:GetPoint(1)
          if data.regionType == "group" then
            yOff = yOff - region.bly
          end
          region:ClearAllPoints()
          region:SetPoint(selfPoint, anchor, anchorPoint, xOff, (yOff * scale - bottom + mover.alignYOf) / scale)
        elseif mover.alignYFrom == "CENTER" then
          local _, center = region:GetCenter()
          center = center * scale
          local selfPoint, anchor, anchorPoint, xOff, yOff = region:GetPoint(1)
          if data.regionType == "group" then
            yOff = yOff - region.try + (region.try - region.bly) / 2
          end
          region:ClearAllPoints()
          region:SetPoint(selfPoint, anchor, anchorPoint, xOff, (yOff * scale - center + mover.alignYOf) / scale)
        end
      end

      if data.xOffset and data.yOffset then
        local selfX, selfY = mover.selfPointIcon:GetCenter()
        local anchorX, anchorY = mover.anchorPointIcon:GetCenter()
        local dX = selfX - anchorX
        local dY = selfY - anchorY
        data.xOffset = dX / scale
        data.yOffset = dY / scale
      end
      region:ResetPosition()
      WeakAuras.Add(data, nil, true)
      WeakAuras.UpdateThumbnail(data)
      local xOff, yOff
      mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1)
      mover:ClearAllPoints()
      if data.regionType == "group" then
        mover:SetWidth((region.trx - region.blx) * scale)
        mover:SetHeight((region.try - region.bly) * scale)
        mover:SetPoint("BOTTOMLEFT", mover.anchor, mover.anchorPoint, (xOff + region.blx) * scale, (yOff + region.bly) * scale)
      else
        mover:SetWidth(region:GetWidth() * scale)
        mover:SetHeight(region:GetHeight() * scale)
        mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale)
      end
      OptionsPrivate.Private.AddParents(data)
      WeakAuras.FillOptions()
      OptionsPrivate.Private.Animate("display", data.uid, "main", data.animation.main, WeakAuras.regions[data.id].region, false, nil, true)
      -- hide alignment lines
      frame.lineY:Hide()
      frame.lineX:Hide()
    end

    if data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup" then
      mover:SetScript("OnMouseDown", nil)
      mover:SetScript("OnMouseUp", nil)
      mover:SetScript("OnEvent", nil)
      mover:SetScript("OnHide", nil)
    else
      mover:SetScript("OnMouseDown", mover.startMoving)
      mover:SetScript("OnMouseUp", mover.doneMoving)
      mover:SetScript("OnEvent", mover.doneMoving)
      mover:SetScript("OnHide", mover.doneMoving)
      mover:RegisterEvent("MODIFIER_STATE_CHANGED")
    end

    if region:IsResizable() then
      frame.startSizing = function(point)
        if WeakAurasOptionsSaved.lockPositions then
          return
        end
        mover.isMoving = true
        OptionsPrivate.Private.CancelAnimation(region, true, true, true, true, true)
        local rSelfPoint, rAnchor, rAnchorPoint, rXOffset, rYOffset = region:GetPoint(1)
        region:StartSizing(point)
        frame.text:ClearAllPoints()
        frame.text:SetPoint("CENTER", frame, "CENTER", 0, -15)
        frame.text:Show()
        mover:ClearAllPoints()
        mover:SetAllPoints(region)
        frame:SetScript("OnUpdate", function()
          frame.text:SetText(("(%.2f, %.2f)"):format(region:GetWidth(), region:GetHeight()))
          if data.width and data.height then
            if IsControlKeyDown() then
              data.width = region:GetWidth()
              data.height = region:GetHeight()
            else
              if point:find("RIGHT") then
                data.xOffset = region.xOffset + (region:GetWidth() - data.width) / 2
              elseif point:find("LEFT") then
                data.xOffset = region.xOffset - (region:GetWidth() - data.width) / 2
              end
              if point:find("TOP") then
                data.yOffset = region.yOffset + (region:GetHeight() - data.height) / 2
              elseif point:find("BOTTOM") then
                data.yOffset = region.yOffset - (region:GetHeight() - data.height) / 2
              end
              data.width = region:GetWidth()
              data.height = region:GetHeight()
            end
          end
          region:ResetPosition()
          WeakAuras.Add(data, nil, true)
          frame:ScaleCorners(region:GetWidth(), region:GetHeight())
          WeakAuras.FillOptions()
        end)

        mover.align = BuildAlignLines(mover)
        mover.sizePoint = point
      end

      frame.doneSizing = function(point)
        mover.isMoving = false
        region:StopMovingOrSizing()

        local width = region:GetWidth()
        local height = region:GetHeight()

        local align = (WeakAurasOptionsSaved.magnetAlign and not IsShiftKeyDown())
                      or (not WeakAurasOptionsSaved.magnetAlign and IsShiftKeyDown())

        if not IsControlKeyDown() then
          if point:find("RIGHT") then
            if mover.alignXFrom and align then
              width = math.abs(region:GetLeft() * scale - mover.alignXOf) / scale
            end
            data.xOffset = region.xOffset + (width - data.width) / 2
          elseif point:find("LEFT") then
            if mover.alignXFrom and align then
              width = math.abs(mover.alignXOf - region:GetRight() * scale) / scale
            end
            data.xOffset = region.xOffset - (width - data.width) / 2
          end
          if point:find("TOP") then
            if mover.alignYFrom and align then
              height = math.abs(region:GetBottom() * scale - mover.alignYOf) / scale
            end
            data.yOffset = region.yOffset + (height - data.height) / 2
          elseif point:find("BOTTOM") then
            if mover.alignYFrom and align then
              height = math.abs(mover.alignYOf - region:GetTop() * scale) / scale
            end
            data.yOffset = region.yOffset - (height - data.height) / 2
          end
        end
        data.width = width
        data.height = height

        region:ResetPosition()
        WeakAuras.Add(data, nil, true)
        OptionsPrivate.Private.AddParents(data)
        WeakAuras.UpdateThumbnail(data)

        frame:ScaleCorners(region:GetWidth(), region:GetHeight())
        local xOff, yOff
        mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1)
        xOff = xOff or 0
        yOff = yOff or 0
        mover:ClearAllPoints()
        if data.regionType == "group" then
          mover:SetWidth((region.trx - region.blx) * scale)
          mover:SetHeight((region.try - region.bly) * scale)
          mover:SetPoint("BOTTOMLEFT", mover.anchor, mover.anchorPoint, (xOff + region.blx) * scale, (yOff + region.bly) * scale)
        else
          mover:SetWidth(region:GetWidth() * scale)
          mover:SetHeight(region:GetHeight() * scale)
          mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale)
        end
        frame.text:Hide()
        frame:SetScript("OnUpdate", nil)
        WeakAuras.FillOptions()
        OptionsPrivate.Private.Animate("display", data.uid, "main", data.animation.main, WeakAuras.regions[data.id].region, false, nil, true)
        -- hide alignment lines
        frame.lineY:Hide()
        frame.lineX:Hide()
        mover.sizePoint = nil
      end

      frame.bottomleft:SetScript("OnMouseDown", function() frame.startSizing("BOTTOMLEFT") end)
      frame.bottomleft:SetScript("OnMouseUp", function() frame.doneSizing("BOTTOMLEFT") end)
      frame.bottomleft:SetScript("OnEnter", frame.bottomleft.Highlight)
      frame.bottomleft:SetScript("OnLeave", frame.bottomleft.Clear)
      frame.bottom:SetScript("OnMouseDown", function() frame.startSizing("BOTTOM") end)
      frame.bottom:SetScript("OnMouseUp", function() frame.doneSizing("BOTTOM") end)
      frame.bottom:SetScript("OnEnter", frame.bottom.Highlight)
      frame.bottom:SetScript("OnLeave", frame.bottom.Clear)
      frame.bottomright:SetScript("OnMouseDown", function() frame.startSizing("BOTTOMRIGHT") end)
      frame.bottomright:SetScript("OnMouseUp", function() frame.doneSizing("BOTTOMRIGHT") end)
      frame.bottomright:SetScript("OnEnter", frame.bottomright.Highlight)
      frame.bottomright:SetScript("OnLeave", frame.bottomright.Clear)
      frame.right:SetScript("OnMouseDown", function() frame.startSizing("RIGHT") end)
      frame.right:SetScript("OnMouseUp", function() frame.doneSizing("RIGHT") end)
      frame.right:SetScript("OnEnter", frame.right.Highlight)
      frame.right:SetScript("OnLeave", frame.right.Clear)
      frame.topright:SetScript("OnMouseDown", function() frame.startSizing("TOPRIGHT") end)
      frame.topright:SetScript("OnMouseUp", function() frame.doneSizing("TOPRIGHT") end)
      frame.topright:SetScript("OnEnter", frame.topright.Highlight)
      frame.topright:SetScript("OnLeave", frame.topright.Clear)
      frame.top:SetScript("OnMouseDown", function() frame.startSizing("TOP") end)
      frame.top:SetScript("OnMouseUp", function() frame.doneSizing("TOP") end)
      frame.top:SetScript("OnEnter", frame.top.Highlight)
      frame.top:SetScript("OnLeave", frame.top.Clear)
      frame.topleft:SetScript("OnMouseDown", function() frame.startSizing("TOPLEFT") end)
      frame.topleft:SetScript("OnMouseUp", function() frame.doneSizing("TOPLEFT") end)
      frame.topleft:SetScript("OnEnter", frame.topleft.Highlight)
      frame.topleft:SetScript("OnLeave", frame.topleft.Clear)
      frame.left:SetScript("OnMouseDown", function() frame.startSizing("LEFT") end)
      frame.left:SetScript("OnMouseUp", function() frame.doneSizing("LEFT") end)
      frame.left:SetScript("OnEnter", frame.left.Highlight)
      frame.left:SetScript("OnLeave", frame.left.Clear)

      frame.bottomleft:Show()
      frame.bottom:Show()
      frame.bottomright:Show()
      frame.right:Show()
      frame.topright:Show()
      frame.top:Show()
      frame.topleft:Show()
      frame.left:Show()
    else
      frame.bottomleft:Hide()
      frame.bottom:Hide()
      frame.bottomright:Hide()
      frame.right:Hide()
      frame.topright:Hide()
      frame.top:Hide()
      frame.topleft:Hide()
      frame.left:Hide()
    end
    mover.alignXFrom = nil
    mover.alignYFrom = nil
    mover.alignYOf = nil
    mover.alignYOf = nil
    frame:Show()
  end

  mover:SetScript("OnUpdate", function(self, elaps)
    if not IsShiftKeyDown() then
      self.goalAlpha = 1
    else
      self.goalAlpha = 0.1
    end

    if self.currentAlpha ~= self.goalAlpha then
      self.currentAlpha = self.currentAlpha or self:GetAlpha()
      local newAlpha = (self.currentAlpha < self.goalAlpha) and self.currentAlpha + (elaps * 4) or self.currentAlpha - (elaps * 4)
      newAlpha = (newAlpha > 1 and 1) or (newAlpha < 0.1 and 0.1) or newAlpha
      mover:SetAlpha(newAlpha)
      frame:SetAlpha(newAlpha)
      self.currentAlpha = newAlpha
    end

    local align = (WeakAurasOptionsSaved.magnetAlign and not IsShiftKeyDown())
                  or (not WeakAurasOptionsSaved.magnetAlign and IsShiftKeyDown())
    if align then
      self.alignGoalAlpha = 1
    else
      self.alignGoalAlpha = 0.1
    end

    if self.alignCurrentAlpha ~= self.alignGoalAlpha then
      self.alignCurrentAlpha = self.alignCurrentAlpha or self:GetAlpha()
      local newAlpha = (self.alignCurrentAlpha < self.alignGoalAlpha) and self.alignCurrentAlpha + (elaps * 4) or self.alignCurrentAlpha - (elaps * 4)
      newAlpha = (newAlpha > 1 and 1) or (newAlpha < 0.1 and 0.1) or newAlpha
      frame.lineX:SetAlpha(newAlpha)
      frame.lineY:SetAlpha(newAlpha)
      self.alignCurrentAlpha = newAlpha
    end

    local db = OptionsPrivate.savedVars.db
    local region = self.moving.region
    local data = self.moving.data
    if not self.isMoving then
      local ok, selfPoint, anchor, anchorPoint = pcall(region.GetPoint, region, 1)
      if not ok then
        self:Hide()
        return
      end
      self.selfPoint, self.anchor, self.anchorPoint = selfPoint, anchor, anchorPoint
    end
    self.selfPointIcon:ClearAllPoints()
    self.selfPointIcon:SetPoint("CENTER", region, self.selfPoint)
    local selfX, selfY = self.selfPointIcon:GetCenter()
    selfX, selfY = selfX or 0, selfY or 0
    self.anchorPointIcon:ClearAllPoints()
    self.anchorPointIcon:SetPoint("CENTER", self.anchor, self.anchorPoint)
    local anchorX, anchorY = self.anchorPointIcon:GetCenter()
    anchorX, anchorY = anchorX or 0, anchorY or 0
    if data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup" then
      self.selfPointIcon:Hide()
      self.anchorPointIcon:Hide()
    else
      self.selfPointIcon:Show()
      self.anchorPointIcon:Show()
    end

    local dX = selfX - anchorX
    local dY = selfY - anchorY
    local distance = sqrt(dX^2 + dY^2)
    local angle = atan2(dY, dX)

    local numInterim = floor(distance/40)

    for _, texture in pairs(self.interims) do
      texture:Hide()
    end
    for i = 1, numInterim  do
      local x = (distance - (i * 40)) * cos(angle)
      local y = (distance - (i * 40)) * sin(angle)
      self.interims[i] = EnsureTexture(self, self.interims[i])
      self.interims[i]:ClearAllPoints()
      self.interims[i]:SetPoint("CENTER", self.anchorPointIcon, "CENTER", x, y)
      self.interims[i]:Show()
    end

    -- HERE
    frame.arrowTexture:Hide()
    frame.offscreenText:Hide()

    -- Check if the center is offscreen
    -- How many pixels of the aura need to be visible
    local margin = 30
    local x, y = mover:GetCenter()
    if x and y then
      if mover:GetRight() < margin or mover:GetLeft() + margin > GetScreenWidth() or mover:GetTop() < 20 or mover:GetBottom() + margin > GetScreenHeight() then
        local arrowX, arrowY = frame.arrowTexture:GetCenter()
        local arrowAngle = atan2(y - arrowY, x - arrowX)
        frame.offscreenText:Show()
        frame.arrowTexture:Show()
        frame.arrowTexture:SetRotation( (arrowAngle - 90) / 180 * math.pi)
      end
    end

    local regionScale = self.moving.region:GetScale()
    self.text:SetText(("(%.2f, %.2f)"):format(dX*1/regionScale, dY*1/regionScale))
    local midX = (distance / 2) * cos(angle)
    local midY = (distance / 2) * sin(angle)
    self.text:SetPoint("CENTER", self.anchorPointIcon, "CENTER", midX, midY)
    local left, right, top, bottom, centerX, centerY = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom(), frame:GetCenter()
    if (midX > 0 and (self.text:GetRight() or 0) > (left or 0))
    or (midX < 0 and (self.text:GetLeft() or 0) < (right or 0))
    then
      if midY > 0 and (self.text:GetTop() or 0) > (top or 0) then
        midY = midY - ((self.text:GetTop() or 0) - (bottom or 0))
      elseif midY < 0 and (self.text:GetBottom() or 0) < (top or 0) then
        midY = midY + ((top or 0) - (self.text:GetBottom() or 0))
      end
    end
    self.text:SetPoint("CENTER", self.anchorPointIcon, "CENTER", midX, midY)
    if self.isMoving then
      if mover.align then
        local ctrlDown = IsControlKeyDown()
        local foundX, foundY = false, false
        local point = mover.sizePoint
        local reverse, start, finish, step
        if mover.lastX ~= selfX then
          -- if mouse move to the right, take first line found from the right, and match right side of the frame first
          reverse = mover.lastX and mover.lastX < selfX -- reverse = mouse move to the right
          start = reverse and #mover.align.x or 1
          finish = reverse and 1 or #mover.align.x
          step = reverse and -1 or 1
          for i=start,finish,step do
            local v = mover.align.x[i]
            if not ctrlDown and (
              ((left >= v - 5 and left <= v + 5) and (not point or point:find("LEFT")))
              or ((right >= v - 5 and right <= v + 5) and (not point or point:find("RIGHT")))
            ) or (
              ctrlDown and centerX >= v - 5 and centerX <= v + 5
            )
            then
              frame.lineY:SetStartPoint("TOPLEFT", UIParent, v, 0)
              frame.lineY:SetEndPoint("BOTTOMLEFT", UIParent, v, 0)
              frame.lineY:Show()
              mover.alignXFrom = ctrlDown and "CENTER"
                or (reverse and ((right >= v - 5 and right <= v + 5) and "RIGHT" or "LEFT")) -- right side first
                or (not reverse and ((left >= v - 5 and left <= v + 5) and "LEFT" or "RIGHT")) -- left side first
              mover.alignXOf = v
              foundX = true
              break
            end
          end
          if not foundX then
            mover.alignXFrom = nil
            mover.alignXOf = nil
            frame.lineY:Hide()
          end
        end
        if mover.lastY ~= selfY then
          -- if mouse move to the top, take first line found from the top, and match top side of the frame first
          reverse = mover.lastY and mover.lastY < selfY
          start = reverse and #mover.align.y or 1
          finish = reverse and 1 or #mover.align.y
          step = reverse and -1 or 1
          for i=start,finish,step do
            local v = mover.align.y[i]
            if not ctrlDown and (
              ((top >= v - 5 and top <= v + 5) and (not point or point:find("TOP")))
              or ((bottom >= v - 5 and bottom <= v + 5) and (not point or point:find("BOTTOM")))
            ) or (
              ctrlDown and centerY >= v - 5 and centerY <= v + 5
            )
            then
              frame.lineX:SetStartPoint("BOTTOMLEFT", UIParent, 0, v)
              frame.lineX:SetEndPoint("BOTTOMRIGHT", UIParent, 0, v)
              frame.lineX:Show()
              mover.alignYFrom = (ctrlDown and "CENTER" or (top >= v - 5 and top <= v + 5) and "TOP" or "BOTTOM")
                or (reverse and ((top >= v - 5 and top <= v + 5) and "TOP" or "BOTTOM")) -- top side first
                or (not reverse and ((bottom >= v - 5 and bottom <= v + 5) and "BOTTOM" or "TOP")) -- bottom side first
              mover.alignYOf = v
              foundY = true
              break
            end
          end
          if not foundY then
            mover.alignYFrom = nil
            mover.alignYOf = nil
            frame.lineX:Hide()
          end
        end
        mover.lastX, mover.lastY = selfX, selfY
      end
    end
  end)

  return frame, mover
end

function OptionsPrivate.MoverSizer(parent)
  if not moversizer or not mover then
    moversizer, mover = ConstructMoverSizer(parent)
  end
  return moversizer, mover
end
