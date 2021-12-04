if not WeakAuras.IsCorrectVersion() then return end

local Type, Version = "WeakAurasLoadedHeaderButton", 20
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local L = WeakAuras.L

local function Hide_Tooltip()
  GameTooltip:Hide();
end

local function Show_Tooltip(owner, line1, line2)
  GameTooltip:SetOwner(owner, "ANCHOR_NONE");
  GameTooltip:SetPoint("LEFT", owner, "RIGHT");
  GameTooltip:ClearLines();
  GameTooltip:AddLine(line1);
  GameTooltip:AddLine(line2, 1, 1, 1, 1);
  GameTooltip:Show();
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(1000);
    self:SetHeight(20);
  end,
  ["SetText"] = function(self, text)
    self.frame:SetText(" "..text);
  end,
  ["SetClick"] = function(self, func)
    self.frame:SetScript("OnClick", func);
  end,
  ["Disable"] = function(self)
    self.frame:Disable();
  end,
  ["Enable"] = function(self)
    self.frame:Enable();
  end,
  ["Pick"] = function(self)
    self.frame:LockHighlight();
  end,
  ["ClearPick"] = function(self)
    self.frame:UnlockHighlight();
  end,
  ["Expand"] = function(self, reloadTooltip)
    self.expand:Enable();
    self.expanded = true;
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-MinusButton-Up.blp");
    self.expand:SetPushedTexture("Interface\\BUTTONS\\UI-MinusButton-Down.blp");
    self.expand.title = L["Collapse"];
    self.expand.desc = self.expand.collapsedesc;
    self.expand:SetScript("OnClick", function() self:Collapse(true) end);
    self.expand.func();
    if(reloadTooltip) then
      Hide_Tooltip();
      Show_Tooltip(self.frame, self.expand.title, self.expand.desc);
    end
  end,
  ["Collapse"] = function(self, reloadTooltip)
    self.expand:Enable();
    self.expanded = false;
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Up.blp");
    self.expand:SetPushedTexture("Interface\\BUTTONS\\UI-PlusButton-Down.blp");
    self.expand.title = L["Expand"];
    self.expand.desc = self.expand.expanddesc;
    self.expand:SetScript("OnClick", function() self:Expand(true) end);
    self.expand.func();
    if(reloadTooltip) then
      Hide_Tooltip();
      Show_Tooltip(self.frame, self.expand.title, self.expand.desc);
    end
  end,
  ["SetOnExpandCollapse"] = function(self, func)
    self.expand.func = func;
  end,
  ["GetExpanded"] = function(self)
    return self.expanded;
  end,
  ["DisableExpand"] = function(self)
    self.expand:Disable();
    self.expand.disabled = true;
    self.expand.expanded = false;
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Disabled.blp");
  end,
  ["EnableExpand"] = function(self)
    self.expand.disabled = false;
    if(self:GetExpanded()) then
      self:Expand();
    else
      self:Collapse();
    end
  end,
  ["SetViewClick"] = function(self, func)
    self.view:SetScript("OnClick", func);
  end,
  ["PriorityShow"] = function(self, priority)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.view.visibility and self.view.visibility ~= priority) then
      self.view.visibility = priority;
      self:UpdateViewTexture()
    end
  end,
  ["PriorityHide"] = function(self, priority)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.view.visibility and self.view.visibility ~= 0) then
      self.view.visibility = 0;
      self:UpdateViewTexture()
    end
  end,
  ["UpdateViewTexture"] = function(self)
    local visibility = self.view.visibility
    if(visibility == 2) then
      self.view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking0.blp");
    elseif(visibility == 1) then
      self.view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking2.blp");
    else
      self.view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking4.blp");
    end
  end,
  ["SetViewDescription"] = function(self, desc)
    self.view.desc = desc;
  end,
  ["SetExpandDescription"] = function(self, desc)
    self.expand.expanddesc = desc;
  end,
  ["SetCollapseDescription"] = function(self, desc)
    self.expand.collapsedesc = desc;
    self.expand.desc = desc;
  end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
  local name = Type..AceGUI:GetNextWidgetNum(Type)
  local button = CreateFrame("BUTTON", name, UIParent, "OptionsListButtonTemplate");
  button:SetHeight(20);
  button:SetWidth(1000);
  button:SetDisabledFontObject("GameFontNormal");

  local background = button:CreateTexture(nil, "BACKGROUND");
  button.background = background;
  background:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
  background:SetBlendMode("ADD");
  background:SetVertexColor(0.5, 0.5, 0.5, 0.25);
  background:SetAllPoints(button);

  local expand = CreateFrame("BUTTON", nil, button);
  button.expand = expand;
  expand.expanded = true;
  expand.disabled = true;
  expand.func = function() end;
  expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Disabled.blp");
  expand:Disable();
  expand:SetWidth(16);
  expand:SetHeight(16);
  expand:SetPoint("RIGHT", button, "RIGHT");
  expand:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  expand.title = L["Disabled"];
  expand.desc = L["Expansion is disabled because this group has no children"];
  expand.expanddesc = "";
  expand.collapsedesc = "";
  expand:SetScript("OnEnter", function() Show_Tooltip(button, expand.title, expand.desc) end);
  expand:SetScript("OnLeave", Hide_Tooltip);

  local view = CreateFrame("BUTTON", nil, button);
  button.view = view;
  view:SetWidth(16);
  view:SetHeight(16);
  view:SetPoint("RIGHT", button, "RIGHT", -16, 0);
  local viewTexture = view:CreateTexture()
  view.texture = viewTexture;
  viewTexture:SetTexture("Interface\\LFGFrame\\BattlenetWorking1.blp");
  viewTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9);
  viewTexture:SetAllPoints(view);
  view:SetNormalTexture(viewTexture);
  view:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  view.desc = "";
  view:SetScript("OnEnter", function() Show_Tooltip(button, L["View"], view.desc) end);
  view:SetScript("OnLeave", Hide_Tooltip);
  view.visibility = 0;

  local widget = {
    frame = button,
    expand = expand,
    view = view,
    type = Type
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
