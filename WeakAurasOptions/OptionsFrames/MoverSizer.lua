-- Lua APIs
local pairs = pairs

-- WoW APIs
local IsShiftKeyDown, CreateFrame =  IsShiftKeyDown, CreateFrame

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WeakAuras = WeakAuras

local moversizer
local mover

local savedVars = WeakAuras.savedVars

local function EnsureTexture(self, texture)
  if(texture) then
    return texture;
  else
    local ret = self:CreateTexture();
    ret:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp");
    ret:SetWidth(16);
    ret:SetHeight(16);
    ret:SetTexCoord(0, 0.25, 0, 1);
    ret:SetVertexColor(1, 1, 1, 0.25);
    return ret;
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
      WeakAuras.Add(data)
      WeakAuras.SetThumbnail(data)
      WeakAuras.ResetMoverSizer()
      if(data.parent) then
        local parentData = WeakAuras.GetData(data.parent)
        if(parentData) then
          WeakAuras.Add(parentData)
          WeakAuras.SetThumbnail(parentData)
        end
      end
      WeakAuras.ReloadOptions(data.id)
    end
  end
end

local function ConstructMover(frame)
  local top = CreateFrame("BUTTON", nil, frame)
  top:SetSize(25, 25)
  top:SetPoint("LEFT", frame, "RIGHT", 1, 10)
  local bottom = CreateFrame("BUTTON", nil, frame)
  bottom:SetSize(25, 25)
  bottom:SetPoint("LEFT", frame, "RIGHT", 1, -10)
  local left = CreateFrame("BUTTON", nil, frame)
  left:SetSize(25, 25)
  left:SetPoint("TOP", frame, "BOTTOM", -10, -1)
  local right = CreateFrame("BUTTON", nil, frame)
  right:SetSize(25, 25)
  right:SetPoint("TOP", frame, "BOTTOM", 10, -1)

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

  return top, bottom, left, right
end

local function PositionMover(frame)
  if frame.moveTop:GetLeft() then
    if frame.moveTop:GetLeft() < 0 then
      frame.moveTop:ClearAllPoints()
      frame.moveTop:SetPoint("LEFT", frame, "RIGHT", 1, 10)
      frame.moveBottom:ClearAllPoints()
      frame.moveBottom:SetPoint("LEFT", frame, "RIGHT", 1, -10)
    elseif frame.moveTop:GetRight() > UIParent:GetRight() then
      frame.moveTop:ClearAllPoints()
      frame.moveTop:SetPoint("RIGHT", frame, "LEFT", -1, 10)
      frame.moveBottom:ClearAllPoints()
      frame.moveBottom:SetPoint("RIGHT", frame, "LEFT", -1, -10)
    end

    if frame.moveLeft:GetBottom() < 0 then
      frame.moveLeft:ClearAllPoints()
      frame.moveLeft:SetPoint("BOTTOM", frame, "TOP", -10, 1)
      frame.moveRight:ClearAllPoints()
      frame.moveRight:SetPoint("BOTTOM", frame, "TOP", 10, 1)
    elseif frame.moveLeft:GetTop() > UIParent:GetTop() then
      frame.moveLeft:ClearAllPoints()
      frame.moveLeft:SetPoint("TOP", frame, "BOTTOM", -10, -1)
      frame.moveRight:ClearAllPoints()
      frame.moveRight:SetPoint("TOP", frame, "BOTTOM", 10, -1)
    end
  end
end

local function ConstructSizer(frame)
  -- topright, bottomright, bottomleft, topleft

  local topright = CreateFrame("FRAME", nil, frame);
  topright:EnableMouse();
  topright:SetWidth(16);
  topright:SetHeight(16);
  topright:SetPoint("TOPRIGHT", frame, "TOPRIGHT");

  local texTR1 = topright:CreateTexture(nil, "OVERLAY");
  texTR1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texTR1:SetBlendMode("ADD");
  texTR1:SetTexCoord(0.5, 0, 0, 0, 0.5, 1, 0, 1);
  texTR1:SetPoint("TOPRIGHT", topright, "TOPRIGHT", -3, -3);
  texTR1:SetPoint("BOTTOMLEFT", topright, "BOTTOM");

  local texTR2 = topright:CreateTexture(nil, "OVERLAY");
  texTR2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texTR2:SetBlendMode("ADD");
  texTR2:SetTexCoord(0, 0, 0, 1, 0.5, 0, 0.5, 1);
  texTR2:SetPoint("TOPRIGHT", texTR1, "TOPLEFT");
  texTR2:SetPoint("BOTTOMLEFT", topright, "LEFT");

  topright.Highlight = function()
    texTR1:Show();
    texTR2:Show();
  end
  topright.Clear = function()
    texTR1:Hide();
    texTR2:Hide();
  end

  local bottomright = CreateFrame("FRAME", nil, frame);
  bottomright:EnableMouse();
  bottomright:SetWidth(16);
  bottomright:SetHeight(16);
  bottomright:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT");

  local texBR1 = bottomright:CreateTexture(nil, "OVERLAY");
  texBR1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texBR1:SetBlendMode("ADD");
  texBR1:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1);
  texBR1:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMRIGHT", -3, 3);
  texBR1:SetPoint("TOPLEFT", bottomright, "TOP");

  local texBR2 = bottomright:CreateTexture(nil, "OVERLAY");
  texBR2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texBR2:SetBlendMode("ADD");
  texBR2:SetTexCoord(0, 0, 0, 1, 0.5, 0, 0.5, 1);
  texBR2:SetPoint("BOTTOMRIGHT", texBR1, "BOTTOMLEFT");
  texBR2:SetPoint("TOPLEFT", bottomright, "LEFT");

  bottomright.Highlight = function()
    texBR1:Show();
    texBR2:Show();
  end
  bottomright.Clear = function()
    texBR1:Hide();
    texBR2:Hide();
  end

  local bottomleft = CreateFrame("FRAME", nil, frame);
  bottomleft:EnableMouse();
  bottomleft:SetSize(16, 16);
  bottomleft:SetHeight(16);
  bottomleft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT");

  local texBL1 = bottomleft:CreateTexture(nil, "OVERLAY");
  texBL1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texBL1:SetBlendMode("ADD");
  texBL1:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1);
  texBL1:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3);
  texBL1:SetPoint("TOPRIGHT", bottomleft, "TOP");

  local texBL2 = bottomleft:CreateTexture(nil, "OVERLAY");
  texBL2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texBL2:SetBlendMode("ADD");
  texBL2:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1);
  texBL2:SetPoint("BOTTOMLEFT", texBL1, "BOTTOMRIGHT");
  texBL2:SetPoint("TOPRIGHT", bottomleft, "RIGHT");

  bottomleft.Highlight = function()
    texBL1:Show();
    texBL2:Show();
  end
  bottomleft.Clear = function()
    texBL1:Hide();
    texBL2:Hide();
  end

  local topleft = CreateFrame("FRAME", nil, frame);
  topleft:EnableMouse();
  topleft:SetWidth(16);
  topleft:SetHeight(16);
  topleft:SetPoint("TOPLEFT", frame, "TOPLEFT");

  local texTL1 = topleft:CreateTexture(nil, "OVERLAY");
  texTL1:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texTL1:SetBlendMode("ADD");
  texTL1:SetTexCoord(0.5, 0, 0, 0, 0.5, 1, 0, 1);
  texTL1:SetPoint("TOPLEFT", topleft, "TOPLEFT", 3, -3);
  texTL1:SetPoint("BOTTOMRIGHT", topleft, "BOTTOM");

  local texTL2 = topleft:CreateTexture(nil, "OVERLAY");
  texTL2:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texTL2:SetBlendMode("ADD");
  texTL2:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1);
  texTL2:SetPoint("TOPLEFT", texTL1, "TOPRIGHT");
  texTL2:SetPoint("BOTTOMRIGHT", topleft, "RIGHT");

  topleft.Highlight = function()
    texTL1:Show();
    texTL2:Show();
  end
  topleft.Clear = function()
    texTL1:Hide();
    texTL2:Hide();
  end

  -- top, right, bottom, left

  local top = CreateFrame("FRAME", nil, frame);
  top:EnableMouse();
  top:SetHeight(8);
  top:SetPoint("TOPRIGHT", topright, "TOPLEFT");
  top:SetPoint("TOPLEFT", topleft, "TOPRIGHT");

  local texT = top:CreateTexture(nil, "OVERLAY");
  texT:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texT:SetBlendMode("ADD");
  texT:SetPoint("TOPRIGHT", topright, "TOPRIGHT", -3, -3);
  texT:SetPoint("BOTTOMLEFT", topleft, "LEFT", 3, 0);

  top.Highlight = function()
    texT:Show();
  end
  top.Clear = function()
    texT:Hide();
  end

  local right = CreateFrame("FRAME", nil, frame);
  right:EnableMouse();
  right:SetWidth(8);
  right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT");
  right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT");

  local texR = right:CreateTexture(nil, "OVERLAY");
  texR:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texR:SetBlendMode("ADD");
  texR:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMRIGHT", -3, 3);
  texR:SetPoint("TOPLEFT", topright, "TOP", 0, -3);

  right.Highlight = function()
    texR:Show();
  end
  right.Clear = function()
    texR:Hide();
  end

  local bottom = CreateFrame("FRAME", nil, frame);
  bottom:EnableMouse();
  bottom:SetHeight(8);
  bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT");
  bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT");

  local texB = bottom:CreateTexture(nil, "OVERLAY");
  texB:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texB:SetBlendMode("ADD");
  texB:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1);
  texB:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3);
  texB:SetPoint("TOPRIGHT", bottomright, "RIGHT", -3, 0);

  bottom.Highlight = function()
    texB:Show();
  end
  bottom.Clear = function()
    texB:Hide();
  end

  local left = CreateFrame("FRAME", nil, frame);
  left:EnableMouse();
  left:SetWidth(8);
  left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT");
  left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT");

  local texL = left:CreateTexture(nil, "OVERLAY");
  texL:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp");
  texL:SetBlendMode("ADD");
  texL:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1);
  texL:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMLEFT", 3, 3);
  texL:SetPoint("TOPRIGHT", topleft, "TOP", 0, -3);

  left.Highlight = function()
    texL:Show();
  end
  left.Clear = function()
    texL:Hide();
  end

  -- return in cw order
  return top, topright, right, bottomright, bottom, bottomleft, left, topleft
end

local function ConstructMoverSizer(parent)
  local frame = CreateFrame("FRAME", nil, parent);
  frame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
  });
  frame:EnableMouse();
  frame:SetFrameStrata("HIGH");

  frame.top, frame.topright, frame.right, frame.bottomright, frame.bottom, frame.bottomleft, frame.left, frame.topleft
  = ConstructSizer(frame)

  frame.moveTop, frame.moveBottom, frame.moveLeft, frame.moveRight = ConstructMover(frame)
  PositionMover(frame)

  frame.top.Clear();
  frame.topright.Clear();
  frame.right.Clear();
  frame.bottomright.Clear();
  frame.bottom.Clear();
  frame.bottomleft.Clear();
  frame.left.Clear();
  frame.topleft.Clear();

  local mover = CreateFrame("FRAME", nil, frame);
  mover:RegisterEvent("PLAYER_REGEN_DISABLED")
  mover:EnableMouse();
  mover.moving = {};
  mover.interims = {};
  mover.selfPointIcon = mover:CreateTexture();
  mover.selfPointIcon:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp");
  mover.selfPointIcon:SetWidth(16);
  mover.selfPointIcon:SetHeight(16);
  mover.selfPointIcon:SetTexCoord(0, 0.25, 0, 1);
  mover.anchorPointIcon = mover:CreateTexture();
  mover.anchorPointIcon:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp");
  mover.anchorPointIcon:SetWidth(16);
  mover.anchorPointIcon:SetHeight(16);
  mover.anchorPointIcon:SetTexCoord(0, 0.25, 0, 1);

  local moverText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  mover.text = moverText;
  moverText:Hide();

  local sizerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  frame.text = sizerText;
  sizerText:Hide();

  frame.ScaleCorners = function(self, width, height)
    local limit = math.min(width, height) + 16;
    local size = 16;
    if(limit <= 40) then
      size = limit * (2/5);
    end
    frame.bottomleft:SetWidth(size);
    frame.bottomleft:SetHeight(size);
    frame.bottomright:SetWidth(size);
    frame.bottomright:SetHeight(size);
    frame.topright:SetWidth(size);
    frame.topright:SetHeight(size);
    frame.topleft:SetWidth(size);
    frame.topleft:SetHeight(size);
  end

  frame.ReAnchor = function(self)
    if(mover.moving.region) then
      self:AnchorPoints(mover.moving.region, mover.moving.data);
    end
  end

  frame.AnchorPoints = function(self, region, data)
    local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
    if(data.regionType == "group") then
      mover:SetWidth((region.trx - region.blx) * scale);
      mover:SetHeight((region.try - region.bly) * scale);
    else
      mover:SetWidth(region:GetWidth() * scale);
      mover:SetHeight(region:GetHeight() * scale);
    end
  end

  frame.SetToRegion = function(self, region, data)
    local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
    mover.moving.region = region;
    mover.moving.data = data;
    local xOff, yOff;
    mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1);
    xOff = xOff or 0;
    yOff = yOff or 0;
    mover:ClearAllPoints();
    frame:ClearAllPoints();
    if(data.regionType == "group") then
      mover:SetWidth((region.trx - region.blx) * scale);
      mover:SetHeight((region.try - region.bly) * scale);
      mover:SetPoint(mover.selfPoint or "CENTER", mover.anchor or UIParent, mover.anchorPoint or "CENTER", (xOff + region.blx) * scale, (yOff + region.bly) * scale);
    else
      mover:SetWidth(region:GetWidth() * scale);
      mover:SetHeight(region:GetHeight() * scale);
      mover:SetPoint(mover.selfPoint or "CENTER", mover.anchor or UIParent, mover.anchorPoint or "CENTER", xOff * scale, yOff * scale);
    end
    frame:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", -8, -8);
    frame:SetPoint("TOPRIGHT", mover, "TOPRIGHT", 8, 8);
    frame:ScaleCorners(region:GetWidth(), region:GetHeight());

    local db = savedVars.db;
    mover.startMoving = function()
      WeakAuras.CancelAnimation(region, true, true, true, true, true);
      mover:ClearAllPoints();
      if(data.regionType == "group") then
        local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
        mover:SetPoint(mover.selfPoint, region, mover.anchorPoint, region.blx * scale, region.bly * scale);
      else
        mover:SetPoint(mover.selfPoint, region, mover.selfPoint);
      end
      region:StartMoving();
      mover.isMoving = true;
      mover.text:Show();
    end

    mover.doneMoving = function(self)
      if (not mover.isMoving) then
        return
      end
      local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
      region:StopMovingOrSizing();
      mover.isMoving = false;
      mover.text:Hide();

      if(data.xOffset and data.yOffset) then
        local selfX, selfY = mover.selfPointIcon:GetCenter();
        local anchorX, anchorY = mover.anchorPointIcon:GetCenter();
        local dX = selfX - anchorX;
        local dY = selfY - anchorY;
        data.xOffset = dX / scale;
        data.yOffset = dY / scale;
      end
      region:ResetPosition();
      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      mover.selfPoint, mover.anchor, mover.anchorPoint, xOff, yOff = region:GetPoint(1);
      mover:ClearAllPoints();
      if(data.regionType == "group") then
        mover:SetWidth((region.trx - region.blx) * scale);
        mover:SetHeight((region.try - region.bly) * scale);
        mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, (xOff + region.blx) * scale, (yOff + region.bly) * scale);
      else
        mover:SetWidth(region:GetWidth() * scale);
        mover:SetHeight(region:GetHeight() * scale);
        mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale);
      end
      if(data.parent) then
        local parentData = db.displays[data.parent];
        if(parentData) then
          WeakAuras.Add(parentData);
          WeakAuras.SetThumbnail(parentData);
        end
      end
      AceConfigDialog:Open("WeakAuras", parent.container);
      WeakAuras.Animate("display", data, "main", data.animation.main, WeakAuras.regions[data.id].region, false, nil, true);
    end

    if(data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup") then
      mover:SetScript("OnMouseDown", nil);
      mover:SetScript("OnMouseUp", nil);
      mover:SetScript("OnEvent", nil);
    else
      mover:SetScript("OnMouseDown", mover.startMoving);
      mover:SetScript("OnMouseUp", mover.doneMoving);
      mover:SetScript("OnEvent", mover.doneMoving);
    end

    if(region:IsResizable()) then
      frame.startSizing = function(point)
        mover.isMoving = true;
        WeakAuras.CancelAnimation(region, true, true, true, true, true);
        local rSelfPoint, rAnchor, rAnchorPoint, rXOffset, rYOffset = region:GetPoint(1);
        region:StartSizing(point);
        local textpoint, anchorpoint;
        if(point:find("BOTTOM")) then textpoint = "TOP"; anchorpoint = "BOTTOM";
        elseif(point:find("TOP")) then textpoint = "BOTTOM"; anchorpoint = "TOP";
        elseif(point:find("LEFT")) then textpoint = "RIGHT"; anchorpoint = "LEFT";
        elseif(point:find("RIGHT")) then textpoint = "LEFT"; anchorpoint = "RIGHT"; end
        frame.text:ClearAllPoints();
        frame.text:SetPoint(textpoint, frame, anchorpoint);
        frame.text:Show();
        mover:SetAllPoints(region);
        frame:SetScript("OnUpdate", function()
          frame.text:SetText(("(%.2f, %.2f)"):format(region:GetWidth(), region:GetHeight()));
          if(data.width and data.height) then
            data.width = region:GetWidth();
            data.height = region:GetHeight();
          end
          region:ResetPosition();
          WeakAuras.Add(data);
          frame:ScaleCorners(region:GetWidth(), region:GetHeight());
          AceConfigDialog:Open("WeakAuras", parent.container);
        end);
      end

      frame.doneSizing = function()
        local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale();
        mover.isMoving = false;
        region:StopMovingOrSizing();
        region:ResetPosition();
        WeakAuras.Add(data);
        WeakAuras.SetThumbnail(data);
        if(data.parent) then
          local parentData = db.displays[data.parent];
          WeakAuras.Add(parentData);
          WeakAuras.SetThumbnail(parentData);
        end
        frame.text:Hide();
        frame:SetScript("OnUpdate", nil);
        mover:ClearAllPoints();
        mover:SetWidth(region:GetWidth() * scale);
        mover:SetHeight(region:GetHeight() * scale);
        mover:SetPoint(mover.selfPoint, mover.anchor, mover.anchorPoint, xOff * scale, yOff * scale);
        WeakAuras.Animate("display", data, "main", data.animation.main, WeakAuras.regions[data.id].region, false, nil, true);
      end

      frame.bottomleft:SetScript("OnMouseDown", function() frame.startSizing("BOTTOMLEFT") end);
      frame.bottomleft:SetScript("OnMouseUp", frame.doneSizing);
      frame.bottomleft:SetScript("OnEnter", frame.bottomleft.Highlight);
      frame.bottomleft:SetScript("OnLeave", frame.bottomleft.Clear);
      frame.bottom:SetScript("OnMouseDown", function() frame.startSizing("BOTTOM") end);
      frame.bottom:SetScript("OnMouseUp", frame.doneSizing);
      frame.bottom:SetScript("OnEnter", frame.bottom.Highlight);
      frame.bottom:SetScript("OnLeave", frame.bottom.Clear);
      frame.bottomright:SetScript("OnMouseDown", function() frame.startSizing("BOTTOMRIGHT") end);
      frame.bottomright:SetScript("OnMouseUp", frame.doneSizing);
      frame.bottomright:SetScript("OnEnter", frame.bottomright.Highlight);
      frame.bottomright:SetScript("OnLeave", frame.bottomright.Clear);
      frame.right:SetScript("OnMouseDown", function() frame.startSizing("RIGHT") end);
      frame.right:SetScript("OnMouseUp", frame.doneSizing);
      frame.right:SetScript("OnEnter", frame.right.Highlight);
      frame.right:SetScript("OnLeave", frame.right.Clear);
      frame.topright:SetScript("OnMouseDown", function() frame.startSizing("TOPRIGHT") end);
      frame.topright:SetScript("OnMouseUp", frame.doneSizing);
      frame.topright:SetScript("OnEnter", frame.topright.Highlight);
      frame.topright:SetScript("OnLeave", frame.topright.Clear);
      frame.top:SetScript("OnMouseDown", function() frame.startSizing("TOP") end);
      frame.top:SetScript("OnMouseUp", frame.doneSizing);
      frame.top:SetScript("OnEnter", frame.top.Highlight);
      frame.top:SetScript("OnLeave", frame.top.Clear);
      frame.topleft:SetScript("OnMouseDown", function() frame.startSizing("TOPLEFT") end);
      frame.topleft:SetScript("OnMouseUp", frame.doneSizing);
      frame.topleft:SetScript("OnEnter", frame.topleft.Highlight);
      frame.topleft:SetScript("OnLeave", frame.topleft.Clear);
      frame.left:SetScript("OnMouseDown", function() frame.startSizing("LEFT") end);
      frame.left:SetScript("OnMouseUp", frame.doneSizing);
      frame.left:SetScript("OnEnter", frame.left.Highlight);
      frame.left:SetScript("OnLeave", frame.left.Clear);

      frame.bottomleft:Show();
      frame.bottom:Show();
      frame.bottomright:Show();
      frame.right:Show();
      frame.topright:Show();
      frame.top:Show();
      frame.topleft:Show();
      frame.left:Show();
    else
      frame.bottomleft:Hide();
      frame.bottom:Hide();
      frame.bottomright:Hide();
      frame.right:Hide();
      frame.topright:Hide();
      frame.top:Hide();
      frame.topleft:Hide();
      frame.left:Hide();
    end
    frame:Show();
  end

  mover:SetScript("OnUpdate", function(self, elaps)
    if(IsShiftKeyDown()) then
      self.goalAlpha = 0.1;
    else
      self.goalAlpha = 1;
    end

    if(self.currentAlpha ~= self.goalAlpha) then
      self.currentAlpha = self.currentAlpha or self:GetAlpha();
      local newAlpha = (self.currentAlpha < self.goalAlpha) and self.currentAlpha + (elaps * 4) or self.currentAlpha - (elaps * 4);
      newAlpha = (newAlpha > 1 and 1) or (newAlpha < 0.1 and 0.1) or newAlpha;
      mover:SetAlpha(newAlpha);
      frame:SetAlpha(newAlpha);
      self.currentAlpha = newAlpha;
    end

    local db = savedVars.db;
    local region = self.moving.region;
    local data = self.moving.data;
    if not(self.isMoving) then
      self.selfPoint, self.anchor, self.anchorPoint = region:GetPoint(1);
    end
    self.selfPointIcon:ClearAllPoints();
    self.selfPointIcon:SetPoint("CENTER", region, self.selfPoint);
    local selfX, selfY = self.selfPointIcon:GetCenter();
    selfX, selfY = selfX or 0, selfY or 0;
    self.anchorPointIcon:ClearAllPoints();
    self.anchorPointIcon:SetPoint("CENTER", self.anchor, self.anchorPoint);
    local anchorX, anchorY = self.anchorPointIcon:GetCenter();
    anchorX, anchorY = anchorX or 0, anchorY or 0;
    if(data.parent and db.displays[data.parent] and db.displays[data.parent].regionType == "dynamicgroup") then
      self.selfPointIcon:Hide();
      self.anchorPointIcon:Hide();
    else
      self.selfPointIcon:Show();
      self.anchorPointIcon:Show();
    end

    local dX = selfX - anchorX;
    local dY = selfY - anchorY;
    local distance = sqrt(dX^2 + dY^2);
    local angle = atan2(dY, dX);

    local numInterim = floor(distance/40);

    for index, texture in pairs(self.interims) do
      texture:Hide();
    end
    for i = 1, numInterim  do
      local x = (distance - (i * 40)) * cos(angle);
      local y = (distance - (i * 40)) * sin(angle);
      self.interims[i] = EnsureTexture(self, self.interims[i]);
      self.interims[i]:ClearAllPoints();
      self.interims[i]:SetPoint("CENTER", self.anchorPointIcon, "CENTER", x, y);
      self.interims[i]:Show();
    end
    local regionScale = self.moving.region:GetScale()
    self.text:SetText(("(%.2f, %.2f)"):format(dX*1/regionScale, dY*1/regionScale));
    local midx = (distance / 2) * cos(angle);
    local midy = (distance / 2) * sin(angle);
    self.text:SetPoint("CENTER", self.anchorPointIcon, "CENTER", midx, midy);
    if((midx > 0 and (self.text:GetRight() or 0) > (frame:GetLeft() or 0)) or (midx < 0 and (self.text:GetLeft() or 0) < (frame:GetRight() or 0))) then
      if(midy > 0 and (self.text:GetTop() or 0) > (frame:GetBottom() or 0)) then
        midy = midy - ((self.text:GetTop() or 0) - (frame:GetBottom() or 0));
      elseif(midy < 0 and (self.text:GetBottom() or 0) < (frame:GetTop() or 0)) then
        midy = midy + ((frame:GetTop() or 0) - (self.text:GetBottom() or 0));
      end
    end
    self.text:SetPoint("CENTER", self.anchorPointIcon, "CENTER", midx, midy);
    if self.isMoving then
      PositionMover(frame)
    end
  end);

  return frame, mover
end

function WeakAuras.MoverSizer(parent)
  if not moversizer or not mover then
    moversizer, mover = ConstructMoverSizer(parent)
  end
  return moversizer, mover
end
