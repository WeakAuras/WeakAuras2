local Type, Version = "WeakAurasDisplayButton", 20
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local L = WeakAuras.L;

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

local function Show_Long_Tooltip(owner, description)
  GameTooltip:SetOwner(owner, "ANCHOR_NONE");
  GameTooltip:SetPoint("LEFT", owner, "RIGHT");
  GameTooltip:ClearLines();
  line = 1;
  for i,v in pairs(description) do
    if(type(v) == "string") then
      if(line > 1) then
        GameTooltip:AddLine(v, 1, 1, 1, 1);
      else
        GameTooltip:AddLine(v);
      end
    elseif(type(v) == "table") then
      if(i == 1) then
        GameTooltip:AddDoubleLine(v[1], v[2]..(v[3] and (" |T"..v[3]..":12:12:0:0:64:64:4:60:4:60|t") or ""));
      else
        GameTooltip:AddDoubleLine(v[1], v[2]..(v[3] and (" |T"..v[3]..":12:12:0:0:64:64:4:60:4:60|t") or ""), 1, 1, 1, 1, 1, 1, 1, 1);
      end
    end
    line = line + 1;
  end
  GameTooltip:Show();
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(150);
		self:SetHeight(32);
	end,
  ["ReloadTooltip"] = function(self)
    Show_Long_Tooltip(self.frame, self.frame.description)
  end,
	["SetTitle"] = function(self, title)
		self.title:SetText(title);
	end,
  ["GetTitle"] = function(self)
    return self.title:GetText();
  end,
  ["SetDescription"] = function(self, ...)
    self.frame.description = {...};
  end,
  ["SetIcon"] = function(self, icon)
    if(type(icon) == "string") then
      self.icon:SetTexture(icon);
      self.icon:Show();
      if(self.iconRegion and self.iconRegion.Hide) then
        self.iconRegion:Hide();
      end
    else
      self.iconRegion = icon;
      icon:SetAllPoints(self.icon);
      icon:SetParent(self.frame);
      self.icon:Hide();
    end
  end,
  ["SetClick"] = function(self, func)
    self.frame:SetScript("OnClick", func);
  end,
  ["SetCopyClick"] = function(self, func)
    self.copy:SetScript("OnClick", func);
  end,
  ["SetViewRegion"] = function(self, region)
    self.view.region = region;
    self.view.func = function() return self.view.visibility end;
    self.view:SetScript("OnClick", function()
      if(self.view.visibility < 2) then
        self.view:PriorityShow(2);
      else
        self.view:PriorityHide(2);
      end
    end);
  end,
  ["SetViewClick"] = function(self, func)
    self.view:SetScript("OnClick", func);
  end,
  ["SetViewTest"] = function(self, func)
    self.view.func = func;
  end,
  ["SetDeleteClick"] = function(self, func)
    self.delete:SetScript("OnClick", func);
  end,
  ["SetRenameAction"] = function(self, func)
    self.renamebox.func = function()
      func(self.renamebox:GetText());
    end
  end,
  ["DisableGroup"] = function(self)
    self.group:Hide();
    self.loaded:Hide();
    self.expand:Show();
  end,
  ["EnableGroup"] = function(self)
    self.group:Show();
    self.loaded:Show();
    self.expand:Hide();
  end,
  ["SetGroupClick"] = function(self, func)
    self.group:SetScript("OnClick", func);
  end,
  ["SetUngroupClick"] = function(self, func)
    self.ungroup:SetScript("OnClick", func);
  end,
  ["SetIds"] = function(self, ids)
    self.renamebox.ids = ids;
  end,
  ["SetGroup"] = function(self, group)
    self.frame.dgroup = group;
    if(group) then
      self.icon:SetPoint("LEFT", self.ungroup, "RIGHT");
      self.background:SetPoint("LEFT", self.ungroup, "RIGHT");
      self.ungroup:Show();
      self.group:Hide();
      self.upgroup:Show();
      self.downgroup:Show();
    else
      self.icon:SetPoint("LEFT", self.frame, "LEFT");
      self.background:SetPoint("LEFT", self.frame, "LEFT");
      self.ungroup:Hide();
      self.group:Show();
      self.upgroup:Hide();
      self.downgroup:Hide();
    end
  end,
  ["GetGroup"] = function(self)
    return self.frame.dgroup;
  end,
  ["SetData"] = function(self, data)
    self.data = data;
  end,
  ["GetData"] = function(self)
    return self.data;
  end,
  ["Expand"] = function(self, reloadTooltip)
    self.expand:Enable();
    self.data.expanded = true;
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-MinusButton-Up.blp");
    self.expand:SetPushedTexture("Interface\\BUTTONS\\UI-MinusButton-Down.blp");
    self.expand.title = L["Collapse"];
    self.expand.desc = L["Hide this group's children"];
    self.expand:SetScript("OnClick", function() self:Collapse(true) end);
    self.expand.func();
    if(reloadTooltip) then
      Hide_Tooltip();
      Show_Tooltip(self.frame, self.expand.title, self.expand.desc);
    end
  end,
  ["Collapse"] = function(self, reloadTooltip)
    self.expand:Enable();
    self.data.expanded = false;
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Up.blp");
    self.expand:SetPushedTexture("Interface\\BUTTONS\\UI-PlusButton-Down.blp");
    self.expand.title = L["Expand"];
    self.expand.desc = L["Show this group's children"];
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
    return self.data.expanded;
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
  ["SetGroupOrder"] = function(self, order, max)
    if(order == 1) then
      self:DisableUpGroup();
    else
      self:EnableUpGroup();
    end
    if(order == max) then
      self:DisableDownGroup();
    else
      self:EnableDownGroup();
    end
    self.frame.dgrouporder = order;
  end,
  ["GetGroupOrder"] = function(self)
    return self.frame.dgrouporder;
  end,
  ["DisableUpGroup"] = function(self)
    self.upgroup:Disable();
    self.upgroup.texture:SetVertexColor(0.3, 0.3, 0.3);
  end,
  ["EnableUpGroup"] = function(self)
    self.upgroup:Enable();
    self.upgroup.texture:SetVertexColor(1, 1, 1);
  end,
  ["DisableDownGroup"] = function(self)
    self.downgroup:Disable();
    self.downgroup.texture:SetVertexColor(0.3, 0.3, 0.3);
  end,
  ["EnableDownGroup"] = function(self)
    self.downgroup:Enable();
    self.downgroup.texture:SetVertexColor(1, 1, 1);
  end,
  ["DisableLoaded"] = function(self)
    self.loaded.title = "Not Loaded";
    self.loaded.desc = L["This display is not currently loaded"];
    self.loaded:SetNormalTexture("Interface\\BUTTONS\\UI-GuildButton-OfficerNote-Disabled.blp");
  end,
  ["EnableLoaded"] = function(self)
    self.loaded.title = "Loaded";
    self.loaded.desc = L["This display is currently loaded"];
    self.loaded:SetNormalTexture("Interface\\BUTTONS\\UI-GuildButton-OfficerNote-Up.blp");
  end,
  ["SetUpGroupClick"] = function(self, func)
    self.upgroup:SetScript("OnClick", func);
  end,
  ["SetDownGroupClick"] = function(self, func)
    self.downgroup:SetScript("OnClick", func);
  end,
  ["Pick"] = function(self)
    self.frame:LockHighlight();
    self.view:PriorityShow(1);
  end,
  ["ClearPick"] = function(self)
    self.frame:UnlockHighlight();
    self.view:PriorityHide(1);
  end,
  ["PriorityShow"] = function(self, priority)
    self.view:PriorityShow(priority);
  end,
  ["PriorityHide"] = function(self, priority)
    self.view:PriorityHide(priority);
  end,
  ["GetVisibility"] = function(self)
    return self.view.visibility;
  end,
  ["Disable"] = function(self)
    self.background:Hide();
    self.frame:Disable();
    self.view:Disable();
    self.copy:Disable();
    self.rename:Disable();
    self.delete:Disable();
    self.group:Disable();
    self.ungroup:Disable();
    self.upgroup:Disable();
    self.downgroup:Disable();
    self.loaded:Disable();
    self.expand:Disable();
  end,
  ["Enable"] = function(self)
    self.background:Show();
    self.frame:Enable();
    self.view:Enable();
    self.copy:Enable();
    self.rename:Enable();
    self.delete:Enable();
    self.group:Enable();
    self.ungroup:Enable();
    self.upgroup:Enable();
    self.downgroup:Enable();
    self.loaded:Enable();
    if not(self.expand.disabled) then
      self.expand:Enable();
    end
  end,
  ["IsEnabled"] = function(self)
    return self.frame:IsEnabled();
  end,
  ["OnRelease"] = function(self)
    self:Enable();
    self:SetGroup();
    self:EnableGroup();
    self.renamebox:Hide();
    self.title:Show();
    self.data = {};
    self.frame:ClearAllPoints();
  end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
	local name = "WeakAurasDisplayButton"..AceGUI:GetNextWidgetNum(Type);
	local button = CreateFrame("BUTTON", name, UIParent, "OptionsListButtonTemplate");
  button:SetHeight(32);
  button:SetWidth(150);
  button.dgroup = nil;
  button.data = {};
  
  local background = button:CreateTexture(nil, "BACKGROUND");
  button.background = background;
  background:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
  background:SetBlendMode("ADD");
  background:SetVertexColor(0.5, 0.5, 0.5, 0.25);
  background:SetPoint("TOP", button, "TOP");
  background:SetPoint("BOTTOM", button, "BOTTOM");
  background:SetPoint("LEFT", button, "LEFT");
  background:SetPoint("RIGHT", button, "RIGHT");
  
  local icon = button:CreateTexture(nil, "OVERLAY");
  button.icon = icon;
  icon:SetWidth(32);
  icon:SetHeight(32);
  icon:SetPoint("LEFT", button, "LEFT");
  
  local title = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  button.title = title;
  title:SetHeight(14);
  title:SetJustifyH("LEFT");
  title:SetPoint("TOP", button, "TOP", 0, -2);
  title:SetPoint("LEFT", icon, "RIGHT", 2, 0);
  title:SetPoint("RIGHT", button, "RIGHT");
  
  button.description = {};
  
  button:SetScript("OnEnter", function() Show_Long_Tooltip(button, button.description) end);
	button:SetScript("OnLeave", Hide_Tooltip);
  
  local delete = CreateFrame("BUTTON", nil, button);
  button.delete = delete;
  delete:SetWidth(16);
  delete:SetHeight(16);
  delete:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0);
  delete:SetNormalTexture("Interface\\GLUES\\LOGIN\\Glues-CheckBox-Check.blp");
  delete:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  delete:SetScript("OnEnter", function() Show_Tooltip(button, L["Delete"], L["Deletes this display - |cFF8080FFShift|r must be held down while clicking"]) end);
	delete:SetScript("OnLeave", Hide_Tooltip);
  
  local view = CreateFrame("BUTTON", nil, button);
  button.view = view;
  view:SetWidth(16);
  view:SetHeight(16);
  view:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -50, 0);
  local viewTexture = view:CreateTexture()
  view.texture = viewTexture;
  viewTexture:SetTexture("Interface\\LFGFrame\\BattlenetWorking1.blp");
  viewTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9);
  viewTexture:SetAllPoints(view);
  view:SetNormalTexture(viewTexture);
  view:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  view:SetScript("OnEnter", function() Show_Tooltip(button, L["View"], L["Toggle the visibility of this display"]) end);
	view:SetScript("OnLeave", Hide_Tooltip);
  view.visibility = 0;
  view.PriorityShow = function(self, priority)
    if(priority >= self.visibility) then
      self.visibility = priority;
      if(self.region and self.region.Expand) then
        self.region:Expand();
      end
    end
  end
  view.PriorityHide = function(self, priority)
    if(priority >= self.visibility) then
      self.visibility = 0;
      if(self.region and self.region.Collapse) then
        self.region:Collapse();
      end
    end
  end
  view.func = function() return view.visibility end;
  view:SetScript("OnUpdate", function()
    if(view.func() == 2) then
      view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking0.blp");
    elseif(view.func() == 1) then
      view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking2.blp");
    else
      view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking4.blp");
    end
  end);
  
  local copy = CreateFrame("BUTTON", nil, button);
  button.copy = copy;
  copy:SetWidth(16);
  copy:SetHeight(16);
  copy:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -34, 0);
  copy:SetNormalTexture("Interface\\GossipFrame\\TrainerGossipIcon.blp");
  copy:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  copy:SetScript("OnEnter", function() Show_Tooltip(button, L["Copy"], L["Copy settings from another display"]) end);
	copy:SetScript("OnLeave", Hide_Tooltip);
  
  local loaded = CreateFrame("BUTTON", nil, button);
  button.loaded = loaded;
  loaded:SetWidth(16);
  loaded:SetHeight(16);
  loaded:SetPoint("BOTTOM", button, "BOTTOM");
  loaded:SetPoint("LEFT", icon, "RIGHT", 0, 0);
  loaded:SetNormalTexture("Interface\\BUTTONS\\UI-GuildButton-OfficerNote-Up.blp");
  loaded:SetDisabledTexture("Interface\\BUTTONS\\UI-GuildButton-OfficerNote-Down.blp");
  --loaded:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  loaded.title = L["Loaded"];
  loaded.desc = L["This display is currently loaded"];
  loaded:SetScript("OnEnter", function() Show_Tooltip(button, loaded.title, loaded.desc) end);
	loaded:SetScript("OnLeave", Hide_Tooltip);
  
  local renamebox = CreateFrame("EDITBOX", nil, button, "InputBoxTemplate");
  renamebox:SetHeight(14);
  renamebox:SetPoint("TOP", button, "TOP");
  renamebox:SetPoint("LEFT", icon, "RIGHT", 6, 0);
  renamebox:SetPoint("RIGHT", button, "RIGHT", -4, 0);
  renamebox:Hide();
  
  local rename = CreateFrame("BUTTON", nil, button);
  button.rename = rename;
  rename:SetWidth(16);
  rename:SetHeight(16);
  rename:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -18, 0);
  local renameTexture = rename:CreateTexture(nil, "BACKGROUND");
  renameTexture:SetTexture("Interface\\BUTTONS\\UI-RotationRight-Button-Up.blp");
  renameTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9);
  renameTexture:SetAllPoints(rename);
  rename:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  rename:SetScript("OnEnter", function() Show_Tooltip(button, L["Rename"], L["Change the name of this display"]) end);
	rename:SetScript("OnLeave", Hide_Tooltip);
  
  renamebox.func = function() --[[By default, do nothing!]] end;
  renamebox.ids = {};
  renamebox:SetScript("OnEnterPressed", function()
    if(renamebox.ids[renamebox:GetText()] and button.title:GetText() ~= renamebox:GetText()) then
      renamebox:SetText(button.title:GetText());
    else
      renamebox.func();
      title:SetText(renamebox:GetText());
      title:Show();
      renamebox:Hide();
    end
  end);
  
  renamebox:SetScript("OnEscapePressed", function()
    title:Show();
    renamebox:Hide();
  end);
  
  rename:SetScript("OnClick", function()
    if(title:IsVisible()) then
      title:Hide();
      renamebox:SetText(title:GetText());
      renamebox:Show();
    else
      title:Show();
      renamebox:Hide();
    end
  end);
  
  local group = CreateFrame("BUTTON", nil, button);
  button.group = group;
  group:SetWidth(16);
  group:SetHeight(16);
  group:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -66, 0);
  local grouptexture = group:CreateTexture(nil, "OVERLAY");
  group.texture = grouptexture;
  grouptexture:SetTexture("Interface\\GLUES\\CharacterCreate\\UI-RotationRight-Big-Up.blp");
  grouptexture:SetTexCoord(0.15, 0.85, 0.15, 0.85);
  grouptexture:SetAllPoints(group);
  group:SetNormalTexture(grouptexture);
  group:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  group:SetScript("OnEnter", function() Show_Tooltip(button, L["Group (verb)"], L["Put this display in a group"]) end);
	group:SetScript("OnLeave", Hide_Tooltip);
  
  local ungroup = CreateFrame("BUTTON", nil, button);
  button.ungroup = ungroup;
  ungroup:SetWidth(11);
  ungroup:SetHeight(11);
  ungroup:SetPoint("LEFT", button, "LEFT", 0, 0);
  local ungrouptexture = group:CreateTexture(nil, "OVERLAY");
  ungrouptexture:SetTexture("Interface\\MoneyFrame\\Arrow-Left-Down.blp");
  ungrouptexture:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1);
  ungrouptexture:SetAllPoints(ungroup);
  ungroup:SetNormalTexture(ungrouptexture);
  ungroup:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  ungroup:SetScript("OnEnter", function() Show_Tooltip(button, L["Ungroup"], L["Remove this display from its group"]) end);
	ungroup:SetScript("OnLeave", Hide_Tooltip);
  ungroup:Hide();
  
  local upgroup = CreateFrame("BUTTON", nil, button);
  button.upgroup = upgroup;
  upgroup:SetWidth(11);
  upgroup:SetHeight(11);
  upgroup:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
  local upgrouptexture = group:CreateTexture(nil, "OVERLAY");
  upgroup.texture = upgrouptexture;
  upgrouptexture:SetTexture("Interface\\MoneyFrame\\Arrow-Left-Down.blp");
  upgrouptexture:SetTexCoord(0.5, 1, 1, 1, 0.5, 0, 1, 0);
  upgrouptexture:SetVertexColor(1, 1, 1);
  upgrouptexture:SetAllPoints(upgroup);
  upgroup:SetNormalTexture(upgrouptexture);
  upgroup:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  upgroup:SetScript("OnEnter", function() Show_Tooltip(button, L["Move Up"], L["Move this display up in its group's order"]) end);
	upgroup:SetScript("OnLeave", Hide_Tooltip);
  upgroup:Hide();
  
  local downgroup = CreateFrame("BUTTON", nil, button);
  button.downgroup = downgroup;
  downgroup:SetWidth(11);
  downgroup:SetHeight(11);
  downgroup:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0);
  local downgrouptexture = group:CreateTexture(nil, "OVERLAY");
  downgroup.texture = downgrouptexture;
  downgrouptexture:SetTexture("Interface\\MoneyFrame\\Arrow-Left-Down.blp");
  downgrouptexture:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1);
  downgrouptexture:SetAllPoints(downgroup);
  downgroup:SetNormalTexture(downgrouptexture);
  downgroup:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  downgroup:SetScript("OnEnter", function() Show_Tooltip(button, L["Move Down"], L["Move this display down in its group's order"]) end);
	downgroup:SetScript("OnLeave", Hide_Tooltip);
  downgroup:Hide();
  
  local expand = CreateFrame("BUTTON", nil, button);
  button.expand = expand;
  expand.expanded = true;
  expand.disabled = true;
  expand.func = function() end;
  expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Disabled.blp");
  expand:Disable();
  expand:SetWidth(16);
  expand:SetHeight(16);
  expand:SetPoint("BOTTOM", button, "BOTTOM");
  expand:SetPoint("LEFT", icon, "RIGHT", 0, 0);
  expand:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  expand.title = L["Disabled"];
  expand.desc = L["Expansion is disabled because this group has no children"];
  expand:SetScript("OnEnter", function() Show_Tooltip(button, expand.title, expand.desc) end);
	expand:SetScript("OnLeave", Hide_Tooltip);

	local widget = {
		frame = button,
		title = title,
    icon = icon,
    delete = delete,
    copy = copy,
    view = view,
    rename = rename,
    renamebox = renamebox,
    group = group,
    ungroup = ungroup,
    upgroup = upgroup,
    downgroup = downgroup,
    loaded = loaded,
    background = background,
    expand = expand,
		type = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
