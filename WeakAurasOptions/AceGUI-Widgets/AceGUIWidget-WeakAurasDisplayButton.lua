local tinsert, tconcat, tremove, wipe = table.insert, table.concat, table.remove, wipe
local select, pairs, next, type, unpack = select, pairs, next, type, unpack
local tostring, error = tostring, error

local Type, Version = "WeakAurasDisplayButton", 38
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local L = WeakAuras.L;
local fullName;
local clipboard = {};

local function IsRegionAGroup(data)
  return data and (data.regionType == "group" or data.regionType == "dynamicgroup");
end

local ignoreForCopyingDisplay = {
  triggers = true,
  conditions = true,
  load = true,
  actions = true,
  animation = true,
  id = true,
  parent = true,
  controlledChildren = true,
  uid = true,
}

local function copyAuraPart(source, destination, part)
  local all = (part == "all");
  if (part == "display" or all) then
    for k, v in pairs(source) do
      if (not ignoreForCopyingDisplay[k]) then
        if (type(v) == "table") then
          destination[k] = CopyTable(v);
        else
          destination[k] = v;
        end
      end
    end
  end
  if (part == "trigger" or all) and not IsRegionAGroup(source) then
    destination.triggers = {};
    WeakAuras.DeepCopy(source.triggers, destination.triggers);
  end
  if (part == "condition" or all) and not IsRegionAGroup(source) then
    destination.conditions = {};
    WeakAuras.DeepCopy(source.conditions, destination.conditions);
  end
  if (part == "load" or all) and not IsRegionAGroup(source) then
    destination.load = {};
    WeakAuras.DeepCopy(source.load, destination.load);
  end
  if (part == "action" or all) and not IsRegionAGroup(source) then
    destination.actions = {};
    WeakAuras.DeepCopy(source.actions, destination.actions);
  end
  if (part == "animation" or all) and not IsRegionAGroup(source) then
    destination.animation = {};
    WeakAuras.DeepCopy(source.animation, destination.animation);
  end
end

local function CopyToClipboard(part, description)
  clipboard.part = part;
  clipboard.pasteText = description;
  clipboard.source = {};
  WeakAuras.DeepCopy(clipboard.current, clipboard.source);
end

clipboard.pasteMenuEntry = {
  text = nil, -- Hidden by default
  notCheckable = true,
  func = function()
    if (not IsRegionAGroup(clipboard.source) and IsRegionAGroup(clipboard.current)) then
      -- Copy from a single aura to a group => paste it to each individual aura
      for index, childId in pairs(clipboard.current.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        copyAuraPart(clipboard.source, childData, clipboard.part);
        WeakAuras.Add(childData);
      end
    else
      copyAuraPart(clipboard.source, clipboard.current, clipboard.part);
      WeakAuras.Add(clipboard.current);
    end

    WeakAuras.ScanForLoads();
    WeakAuras.SortDisplayButtons();
    WeakAuras.PickDisplay(clipboard.current.id);
    WeakAuras.UpdateDisplayButton(clipboard.current.id);
  end
}

clipboard.copyEverythingEntry = {
  text = L["Everything"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("all", L["Paste Settings"])
  end
};

clipboard.copyGroupEntry = {
  text = L["Group"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("display", L["Paste Group Settings"])
  end
};

clipboard.copyDisplayEntry = {
  text = L["Display"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("display", L["Paste Display Settings"])
  end
};

clipboard.copyTriggerEntry = {
  text = L["Trigger"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("trigger", L["Paste Trigger Settings"])
  end
};

clipboard.copyConditionsEntry = {
  text = L["Conditions"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("condition", L["Paste Condition Settings"])
  end
};

clipboard.copyLoadEntry = {
  text = L["Load"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("load", L["Paste Load Settings"])
  end
};

clipboard.copyActionsEntry = {
  text = L["Actions"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("action", L["Paste Action Settings"])
  end
};

clipboard.copyAnimationsEntry = {
  text = L["Animations"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("animation", L["Paste Animations Settings"])
  end
};

local function UpdateClipboardMenuEntry(data)
  clipboard.current = data;

  if (IsRegionAGroup(clipboard.source) and not IsRegionAGroup(clipboard.current)) then
    -- Don't copy from a group to a non group
    clipboard.pasteMenuEntry.text = nil;
  else
    clipboard.pasteMenuEntry.text = clipboard.pasteText;
  end

  if (IsRegionAGroup(clipboard.current)) then
    clipboard.copyEverythingEntry.text = nil;
    clipboard.copyDisplayEntry.text = nil;
    clipboard.copyTriggerEntry.text = nil;
    clipboard.copyConditionsEntry.text = nil;
    clipboard.copyLoadEntry.text = nil;
    clipboard.copyActionsEntry.text = nil;
    clipboard.copyAnimationsEntry.text = nil;
    clipboard.copyGroupEntry.text = L["Group"];
  else
    clipboard.copyEverythingEntry.text = L["Everything"];
    clipboard.copyDisplayEntry.text = L["Display"];
    clipboard.copyTriggerEntry.text = L["Trigger"];
    clipboard.copyConditionsEntry.text = L["Conditions"];
    clipboard.copyLoadEntry.text = L["Load"];
    clipboard.copyActionsEntry.text = L["Actions"];
    clipboard.copyAnimationsEntry.text = L["Animations"];
    clipboard.copyGroupEntry.text = nil;
  end
end

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
  local line = 1;
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

local function ensure(t, k, v)
  return t and k and v and t[k] == v
end

--[[     Actions     ]]--

local Actions = {
  -- move source into group or top-level list / optionally place it before or after target
  ["Group"] = function(source, groupId, target, before)
    if source and not source.data.parent then
      if groupId then
        local group = WeakAuras.GetDisplayButton(groupId)
        if group and group:IsGroup() then
          local children = group.data.controlledChildren
          if target then
            local index = target:GetGroupOrder()
            if ensure(children, index, target.data.id) then
              -- account for insert position
              index = before and index or index+1
              tinsert(children, index, source.data.id)
            else
              error("Calling 'Group' with invalid target. Reload your UI to fix the display list.")
            end
          else
            -- move source into group as the first child
            tinsert(children, 1, source.data.id)
          end
          source:SetGroup(groupId)
          source.data.parent = groupId
          WeakAuras.Add(source.data)
          WeakAuras.Add(group.data)
          WeakAuras.UpdateGroupOrders(group.data)
          WeakAuras.ReloadGroupRegionOptions(group.data)
          WeakAuras.UpdateDisplayButton(group.data)
          group.callbacks.UpdateExpandButton();
          group:ReloadTooltip()
        else
          WeakAuras.Add(source.data)
        end
      else
        -- move source into the top-level list
        WeakAuras.Add(source.data)
      end
    else
      error("Calling 'Group' with invalid source. Reload your UI to fix the display list.")
    end
  end,
  -- remove source from its group or top-level list
  ["Ungroup"] =  function(source)
    if source and source.data.parent then
      local parent = WeakAuras.GetData(source.data.parent)
      local children = parent.controlledChildren
      local index = source:GetGroupOrder()
      if ensure(children, index, source.data.id) then
        tremove(children, index)
        source:SetGroup()
        source.data.parent = nil
        WeakAuras.Add(parent);
        WeakAuras.UpdateGroupOrders(parent);
        WeakAuras.ReloadGroupRegionOptions(parent);
        WeakAuras.UpdateDisplayButton(parent);
        local group = WeakAuras.GetDisplayButton(parent.id)
        group.callbacks.UpdateExpandButton();
        group:ReloadTooltip()
      else
        error("Display thinks it is a member of a group which does not control it")
      end
    else
      error("Calling 'Ungroup' with invalid source. Reload your UI to fix the display list.")
    end
  end,
  -- move source inside its own group before or after target
  ["Move"] = function(source, target, before )
    if source and source.data.parent then
      local parent = WeakAuras.GetData(source.data.parent)
      local children = parent.controlledChildren
      local i = source:GetGroupOrder()
      if ensure(children, i, source.data.id) then
        if target and target.data.parent then
          local j = target:GetGroupOrder()
          if ensure(children, j, target.data.id) then
            -- account for possible reorder
            j = i < j and j-1 or j
            -- account for insert position
            j = before and j or j+1
            tremove(children, i)
            tinsert(children, j, source.data.id)
          else
            error("Calling 'Move' with invalid target. Reload your UI to fix the display list.")
          end
        else
          tremove(children, i)
          tinsert(children, 1, source.data.id)
        end
        WeakAuras.Add(parent)
        WeakAuras.UpdateGroupOrders(parent)
        WeakAuras.UpdateDisplayButton(parent)
      else
        error("Calling 'Move' with invalid source. Reload your UI to fix the display list.")
      end
    else
      error("Calling 'Move' with invalid source. Reload your UI to fix the display list.")
    end
  end,
}

local Icons = {
  ["Group"] = "Interface\\GossipFrame\\TrainerGossipIcon",
  ["Ungroup"] = "Interface\\GossipFrame\\UnlearnGossipIcon",
  ["Move"] = nil
}

local function GetAction(target, area, source)
  if target and source and (area == "TOP" or area == "BOTTOM")then
    if target.data.parent and source.data.parent then
      if source.data.parent == target.data.parent then
        return function(_source, _target)
          Actions["Move"](_source, _target, area=="TOP")
        end,
        Icons["Move"]
      else
        return function(_source, _target)
          Actions["Ungroup"](_source)
          Actions["Group"](_source, _target.data.parent, _target, area == "TOP")
        end,
        Icons["Group"]
      end
    elseif target.data.parent then -- and not source.data.parent
      return function(_source, _target)
        Actions["Group"](_source, _target.data.parent, _target, area == "TOP")
      end,
      Icons["Group"]
    elseif source.data.parent then -- and not target.data.parent
      if area == "TOP" then
        return function(_source, _target)
          Actions["Ungroup"](_source)
          Actions["Group"](_source)
        end,
        Icons["Ungroup"]
    else -- area == "BOTTOM"
      if source.data.parent == target.data.id then
        return Actions["Move"], Icons["Move"]
    else
      return function(_source, _target)
        Actions["Ungroup"](_source)
        Actions["Group"](_source, _target.data.id)
      end,
      Icons["Group"]
    end
    end
    else -- not target.data.parent and not source.data.parent
      if target:IsGroup() and area == "BOTTOM" then
        return function(_source, _target)
          Actions["Group"](_source, _target.data.id)
        end,
        Icons["Group"]
    else
      return nil
    end
    end
  end
end

-------------------------

local function GetDropTarget()
  local buttonList = WeakAuras.displayButtons
  local id, button, pos, offset
  repeat
    repeat
      id, button = next(buttonList, id)
    until not id or not button.dragging and button:IsEnabled() and button:IsShown()
    if id and button then
      offset = (button.frame.height or button.frame:GetHeight() or 16) / 2
      pos = button.frame:IsMouseOver(1,offset) and "TOP"
        or button.frame:IsMouseOver(-offset,-1) and "BOTTOM"
    end
  until not id or pos
  return id, button, pos
end

local function Show_DropIndicator(id)
  local indicator = WeakAuras.DropIndicator()
  local source = WeakAuras.GetDisplayButton(id)
  local target, pos
  if source then
    target, pos = select(2, GetDropTarget())
  end
  indicator:ClearAllPoints()
  local action, icon = GetAction(target, pos, source)
  if action then
    -- show line
    if pos == "TOP" then
      indicator:SetPoint("BOTTOMLEFT", target.frame, "TOPLEFT", 0, -1)
      indicator:SetPoint("BOTTOMRIGHT", target.frame, "TOPRIGHT", 0, -1)
      indicator:Show()
    elseif pos == "BOTTOM" then
      indicator:SetPoint("TOPLEFT", target.frame, "BOTTOMLEFT", 0, 1)
      indicator:SetPoint("TOPRIGHT", target.frame, "BOTTOMRIGHT", 0, 1)
      indicator:Show()
    else
      error("Invalid value pos '"..tostring(pos))
    end
    -- show icon
    if icon then
      if indicator.icon.texture ~= icon then
        indicator.icon.texture = icon
        indicator.icon:SetTexture(icon)
      end
      indicator.icon:Show()
    else
      indicator.icon:Hide()
    end
  else
    indicator:Hide()
  end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(1000);
    self:SetHeight(32);
  end,
  ["Initialize"] = function(self)
    local data = self.data;
    self.callbacks = {};

    function self.callbacks.OnClickNormal(_, mouseButton)
      if(IsControlKeyDown() and not data.controlledChildren) then
        if (WeakAuras.IsDisplayPicked(data.id)) then
          WeakAuras.ClearPick(data.id);
        else
          WeakAuras.PickDisplayMultiple(data.id);
        end
        self:ReloadTooltip();
      elseif(IsShiftKeyDown()) then
        local editbox = GetCurrentKeyBoardFocus();
        if(editbox) then
          if (not fullName) then
            local name, realm = UnitFullName("player")
            fullName = name.."-"..realm
          end
          editbox:Insert("[WeakAuras: "..fullName.." - "..data.id.."]");
        end
      else
        if(mouseButton == "RightButton") then
          Hide_Tooltip();
          if(WeakAuras.IsDisplayPicked(data.id) and WeakAuras.IsPickedMultiple()) then
            EasyMenu(WeakAuras.MultipleDisplayTooltipMenu(), WeakAuras_DropDownMenu, self.frame, 0, 0, "MENU");
          else
            UpdateClipboardMenuEntry(data);
            EasyMenu(self.menu, WeakAuras_DropDownMenu, self.frame, 0, 0, "MENU");
            if not(WeakAuras.IsDisplayPicked(data.id)) then
              WeakAuras.PickDisplay(data.id);
            end
          end
        else
          if (WeakAuras.IsDisplayPicked(data.id)) then
            WeakAuras.ClearPicks(data.id);
          else
            WeakAuras.PickDisplay(data.id);
          end
          self:ReloadTooltip();
        end
      end
    end

    function self.callbacks.UpdateExpandButton()
      if(#self.data.controlledChildren == 0) then
        self:DisableExpand();
      else
        self:EnableExpand();
      end
    end

    function self.callbacks.OnClickGrouping()
      if (WeakAuras.IsImporting()) then return end;
      tinsert(data.controlledChildren, self.grouping.id);
      local childButton = WeakAuras.GetDisplayButton(self.grouping.id);
      childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
      childButton:SetGroupOrder(#data.controlledChildren, #data.controlledChildren);
      self.callbacks.UpdateExpandButton();
      self.grouping.parent = data.id;
      if (data.regionType == "dynamicgroup") then
        self.grouping.xOffset = 0;
        self.grouping.yOffset = 0;
      end
      WeakAuras.Add(data);
      WeakAuras.Add(self.grouping);
      WeakAuras.SetGrouping();
      WeakAuras.UpdateDisplayButton(data);
      WeakAuras.ReloadGroupRegionOptions(data);
      WeakAuras.UpdateGroupOrders(data);
      WeakAuras.SortDisplayButtons();
      self:ReloadTooltip();
      WeakAuras.ResetMoverSizer();
    end

    function self.callbacks.OnClickGroupingSelf()
      WeakAuras.SetGrouping();
      self:ReloadTooltip();
    end

    function self.callbacks.OnGroupClick()
      WeakAuras.PickDisplay(data.id);
      WeakAuras.SetGrouping(data);
    end

    function self.callbacks.OnDeleteClick()
      if (WeakAuras.IsImporting()) then return end;
      local toDelete = {data}
      local parents = data.parent and {[data.parent] = true}
      WeakAuras.ConfirmDelete(toDelete, parents)
    end

    function self.callbacks.OnDuplicateClick()
      if (WeakAuras.IsImporting()) then return end;
      local new_id = WeakAuras.DuplicateAura(data);
      WeakAuras.SortDisplayButtons();
      WeakAuras.DoConfigUpdate();
      WeakAuras.PickAndEditDisplay(new_id);
    end

    function self.callbacks.OnDeleteAllClick()
      if (WeakAuras.IsImporting()) then return end;
      local toDelete = {}
      if(data.controlledChildren) then

        local region = WeakAuras.regions[data.id];
        if (region.ControlChildren) then
          region:Pause();
        end

        for _, id in pairs(data.controlledChildren) do
          tinsert(toDelete, WeakAuras.GetData(id));
        end
      end
      tinsert(toDelete, data)
      WeakAuras.ConfirmDelete(toDelete);
    end

    function self.callbacks.OnUngroupClick()
      if (WeakAuras.IsImporting()) then return end;
      local parentData = WeakAuras.GetData(data.parent);
      local index;
      for childIndex, childId in pairs(parentData.controlledChildren) do
        if(childId == data.id) then
          index = childIndex;
          break;
        end
      end
      if(index) then
        tremove(parentData.controlledChildren, index);
        WeakAuras.Add(parentData);
        WeakAuras.ReloadGroupRegionOptions(parentData);
      else
        error("Display thinks it is a member of a group which does not control it");
      end
      self:SetGroup();
      data.parent = nil;
      WeakAuras.Add(data);
      WeakAuras.UpdateGroupOrders(parentData);
      WeakAuras.UpdateDisplayButton(parentData);
      WeakAuras.SortDisplayButtons();
    end

    function self.callbacks.OnUpGroupClick()
      if (WeakAuras.IsImporting()) then return end;
      if(data.parent) then
        local id = data.id;
        local parentData = WeakAuras.GetData(data.parent);
        local index;
        for childIndex, childId in pairs(parentData.controlledChildren) do
          if(childId == id) then
            index = childIndex;
            break;
          end
        end
        if(index) then
          if(index <= 1) then
            error("Attempt to move up the first element in a group");
          else
            tremove(parentData.controlledChildren, index);
            tinsert(parentData.controlledChildren, index - 1, id);
            WeakAuras.Add(parentData);
            self:SetGroupOrder(index - 1, #parentData.controlledChildren);
            local otherbutton = WeakAuras.GetDisplayButton(parentData.controlledChildren[index]);
            otherbutton:SetGroupOrder(index, #parentData.controlledChildren);
            WeakAuras.SortDisplayButtons();
            local updata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = -32};
            local downdata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = 32};
            WeakAuras.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index-1]), "main", updata, self.frame, true, function() WeakAuras.SortDisplayButtons() end);
            WeakAuras.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index]), "main", downdata, otherbutton.frame, true, function() WeakAuras.SortDisplayButtons() end);
            WeakAuras.UpdateDisplayButton(parentData);
          end
        else
          error("Display thinks it is a member of a group which does not control it");
        end
      else
        error("This display is not in a group. You should not have been able to click this button");
      end
    end

    function self.callbacks.OnDownGroupClick()
      if (WeakAuras.IsImporting()) then return end;
      if(data.parent) then
        local id = data.id;
        local parentData = WeakAuras.GetData(data.parent);
        local index;
        for childIndex, childId in pairs(parentData.controlledChildren) do
          if(childId == id) then
            index = childIndex;
            break;
          end
        end
        if(index) then
          if(index >= #parentData.controlledChildren) then
            error("Attempt to move down the last element in a group");
          else
            tremove(parentData.controlledChildren, index);
            tinsert(parentData.controlledChildren, index + 1, id);
            WeakAuras.Add(parentData);
            self:SetGroupOrder(index + 1, #parentData.controlledChildren);
            local otherbutton = WeakAuras.GetDisplayButton(parentData.controlledChildren[index]);
            otherbutton:SetGroupOrder(index, #parentData.controlledChildren);
            WeakAuras.SortDisplayButtons()
            local updata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = -32};
            local downdata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = 32};
            WeakAuras.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index+1]), "main", downdata, self.frame, true, function() WeakAuras.SortDisplayButtons() end);
            WeakAuras.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index]), "main", updata, otherbutton.frame, true, function() WeakAuras.SortDisplayButtons() end);
            WeakAuras.UpdateDisplayButton(parentData);
          end
        else
          error("Display thinks it is a member of a group which does not control it");
        end
      else
        error("This display is not in a group. You should not have been able to click this button");
      end
    end

    function self.callbacks.OnViewClick()
      WeakAuras.PauseAllDynamicGroups();

      if(self.view.func() == 2) then
        for index, childId in ipairs(data.controlledChildren) do
          WeakAuras.GetDisplayButton(childId):PriorityHide(2);
        end
      else
        for index, childId in ipairs(data.controlledChildren) do
          WeakAuras.GetDisplayButton(childId):PriorityShow(2);
        end
      end

      WeakAuras.ResumeAllDynamicGroups();
    end

    function self.callbacks.ViewTest()
      local none, all = true, true;
      for index, childId in ipairs(data.controlledChildren) do
        local childButton = WeakAuras.GetDisplayButton(childId);
        if(childButton) then
          if(childButton:GetVisibility() ~= 2) then
            all = false;
          end
          if(childButton:GetVisibility() ~= 0) then
            none = false;
          end
        end
      end
      if(all) then
        return 2;
      elseif(none) then
        return 0;
      else
        return 1;
      end
    end

    function self.callbacks.OnRenameClick()
      if (WeakAuras.IsImporting()) then return end;
      if(self.title:IsVisible()) then
        self.title:Hide();
        self.renamebox:SetText(self.title:GetText());
        self.renamebox:Show();
      else
        self.title:Show();
        self.renamebox:Hide();
      end
    end

    function self.callbacks.OnRenameAction(newid)
      if (WeakAuras.IsImporting()) then return end;
      local oldid = data.id;
      if not(newid == oldid) then
        local temp;

        WeakAuras.Rename(data, newid);

        WeakAuras.thumbnails[newid] = WeakAuras.thumbnails[oldid];
        WeakAuras.thumbnails[oldid] = nil;
        WeakAuras.displayButtons[newid] = WeakAuras.displayButtons[oldid];
        WeakAuras.displayButtons[oldid] = nil;
        WeakAuras.displayOptions[oldid] = nil;
        WeakAuras.AddOption(newid, data);

        WeakAuras.displayButtons[newid]:SetTitle(newid);

        if(data.controlledChildren) then
          for index, childId in pairs(data.controlledChildren) do
            WeakAuras.displayButtons[childId]:SetGroup(newid);
          end
        end

        WeakAuras.SetGrouping();
        WeakAuras.SortDisplayButtons();
        WeakAuras.PickDisplay(newid);
      end
    end

    function self.callbacks.OnDragStart()
      if WeakAuras.IsImporting() or self:IsGroup() then return end;
      if #WeakAuras.tempGroup.controlledChildren == 0 then
        WeakAuras.PickDisplay(data.id);
      end
      WeakAuras.SetDragging(data);
    end

    function self.callbacks.OnDragStop()
      if not self.dragging then return end
      WeakAuras.SetDragging(data, true)
    end

    function self.callbacks.OnKeyDown(self, key)
      if (key == "ESCAPE") then
        WeakAuras.SetDragging();
      end
    end

    self.frame.terribleCodeOrganizationHackTable = {};

    function self.frame.terribleCodeOrganizationHackTable.IsGroupingOrCopying()
      return self.grouping;
    end

    function self.frame.terribleCodeOrganizationHackTable.SetNormalTooltip()
      self:SetNormalTooltip();
    end

    function self.frame.terribleCodeOrganizationHackTable.OnShow()
      WeakAuras.UpdateCloneConfig(data);
    end

    function self.frame.terribleCodeOrganizationHackTable.OnHide()
      WeakAuras.CollapseAllClones(data.id);
    end

    local copyEntries = {};
    tinsert(copyEntries, clipboard.copyEverythingEntry);
    tinsert(copyEntries, clipboard.copyGroupEntry);
    tinsert(copyEntries, clipboard.copyDisplayEntry);
    tinsert(copyEntries, clipboard.copyTriggerEntry);
    tinsert(copyEntries, clipboard.copyConditionsEntry);
    tinsert(copyEntries, clipboard.copyLoadEntry);
    tinsert(copyEntries, clipboard.copyActionsEntry);
    tinsert(copyEntries, clipboard.copyAnimationsEntry);

    self:SetTitle(data.id);
    self.menu = {
      {
        text = L["Rename"],
        notCheckable = 1,
        func = self.callbacks.OnRenameClick
      },
      {
        text = L["Copy settings..."],
        notCheckable = 1,
        hasArrow = true,
        menuList = copyEntries;
      },
    };

    tinsert(self.menu, clipboard.pasteMenuEntry);

    if (not data.controlledChildren) then
      local convertMenu = {};
      for regionType, regionData in pairs(WeakAuras.regionOptions) do
        if(regionType ~= "group" and regionType ~= "dynamicgroup" and regionType ~= "timer" and regionType ~= data.regionType) then
          tinsert(convertMenu, {
            text = regionData.displayName,
            notCheckable = 1,
            func = function()
              WeakAuras.ConvertDisplay(data, regionType);
              WeakAuras_DropDownMenu:Hide();
            end
          });
        end
      end
      tinsert(self.menu, {
        text = L["Convert to..."],
        notCheckable = 1,
        hasArrow = true,
        menuList = convertMenu
      });
      tinsert(self.menu, {
        text = L["Duplicate"],
        notCheckable = 1,
        func = self.callbacks.OnDuplicateClick
      });
    end

    tinsert(self.menu, {
      text = L["Set tooltip description"],
      notCheckable = 1,
      func = function() WeakAuras.ShowDisplayTooltip(data, nil, nil, nil, nil, nil, "desc") end
    });


    if (data.url and data.url ~= "") then
      tinsert(self.menu, {
        text = L["Copy URL"],
        notCheckable = 1,
        func = function() WeakAuras.ShowDisplayTooltip(data, nil, nil, nil, nil, nil, "url") end
      });
    end

    tinsert(self.menu, {
      text = L["Export to string..."],
      notCheckable = 1,
      func = function() WeakAuras.ExportToString(data.id) end
    });
    tinsert(self.menu, {
      text = L["Export to Lua table..."],
      notCheckable = 1,
      func = function() WeakAuras.ExportToTable(data.id) end
    });
    tinsert(self.menu, {
      text = " ",
      notClickable = 1,
      notCheckable = 1,
    });
    tinsert(self.menu, {
      text = L["Delete"],
      notCheckable = 1,
      func = self.callbacks.OnDeleteClick
    });

    if (data.controlledChildren) then
      tinsert(self.menu, {
        text = L["Delete children and group"],
        notCheckable = 1,
        func = self.callbacks.OnDeleteAllClick
      });
    end
    tinsert(self.menu, {
      text = " ",
      notClickable = 1,
      notCheckable = 1,
    });
    tinsert(self.menu, {
      text = L["Close"],
      notCheckable = 1,
      func = function() WeakAuras_DropDownMenu:Hide() end
    });
    if(data.controlledChildren) then
      self:SetViewClick(self.callbacks.OnViewClick);
      self:SetViewTest(self.callbacks.ViewTest);
      self:DisableGroup();
      self.callbacks.UpdateExpandButton();
      self:SetOnExpandCollapse(function() WeakAuras.SortDisplayButtons(nil, true) end);
    else
      self:SetViewRegion(WeakAuras.regions[data.id].region);
      self:EnableGroup();
    end
    self:SetNormalTooltip();
    self.frame:SetScript("OnClick", self.callbacks.OnClickNormal);
    self.frame:SetScript("OnKeyDown", self.callbacks.OnKeyDown);
    self.frame:EnableKeyboard(false);
    self.frame:SetMovable(true);
    self.frame:RegisterForDrag("LeftButton");
    self.frame:SetScript("OnDragStart", self.callbacks.OnDragStart);
    self.frame:SetScript("OnDragStop", self.callbacks.OnDragStop);

    self:Enable();
    self:SetRenameAction(self.callbacks.OnRenameAction);
    self.group:SetScript("OnClick", self.callbacks.OnGroupClick);
    self.ungroup:SetScript("OnClick", self.callbacks.OnUngroupClick);
    self.upgroup:SetScript("OnClick", self.callbacks.OnUpGroupClick);
    self.downgroup:SetScript("OnClick", self.callbacks.OnDownGroupClick);
    if(data.parent) then
      local parentData = WeakAuras.GetData(data.parent);
      local index;
      for childIndex, childId in pairs(parentData.controlledChildren) do
        if(childId == data.id) then
          index = childIndex;
          break;
        end
      end
      if(index) then
        self:SetGroup(data.parent);
        self:SetGroupOrder(index, #parentData.controlledChildren);
      else
        error("Display \""..data.id.."\" thinks it is a member of group \""..data.parent.."\" which does not control it");
      end
    end
  end,
  ["SetNormalTooltip"] = function(self)
    local data = self.data;
    local namestable = {};
    if(data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        tinsert(namestable, {" ", childId});
      end

      if (#namestable > 30) then
        local size = #namestable;
        namestable[26] = {" ", "[...]"};
        namestable[27] = {L[string.format(L["%s total auras"], #data.controlledChildren)], " " }
        for i = 28, size do
          namestable[i] = nil;
        end
      end

      if(#namestable > 0) then
        namestable[1][1] = L["Children:"];
      else
        namestable[1] = L["No Children"];
      end
    else
      for triggernum, triggerData in ipairs(data.triggers) do
        local trigger = triggerData.trigger
        if(trigger) then
          if(trigger.type == "aura") then
            if(trigger.fullscan) then
              tinsert(namestable, {L["Aura:"], L["Full Scan"]});
            else
              for index, name in pairs(trigger.names) do
                local left = " ";
                if(index == 1) then
                  if(#trigger.names > 0) then
                    if(#trigger.names > 1) then
                      left = L["Auras:"];
                    else
                      left = L["Aura:"];
                    end
                  end
                end
                local icon = WeakAuras.spellCache.GetIcon(name) or "Interface\\Icons\\INV_Misc_QuestionMark";
                tinsert(namestable, {left, name, icon});
              end
            end
          elseif(trigger.type == "event" or trigger.type == "status") then
            if(trigger.type == "event") then
              tinsert(namestable, {L["Trigger:"], (WeakAuras.event_types[trigger.event] or L["Undefined"])});
            else
              tinsert(namestable, {L["Trigger:"], (WeakAuras.status_types[trigger.event] or L["Undefined"])});
            end
            if(trigger.event == "Combat Log" and trigger.subeventPrefix and trigger.subeventSuffix) then
              tinsert(namestable, {L["Message type:"], (WeakAuras.subevent_prefix_types[trigger.subeventPrefix] or L["Undefined"]).." "..(WeakAuras.subevent_suffix_types[trigger.subeventSuffix] or L["Undefined"])});
            end
          else
            tinsert(namestable, {L["Trigger:"], L["Custom"]});
          end
        end
      end
    end
    if(WeakAuras.CanHaveClones(data)) then
      tinsert(namestable, {" ", "|cFF00FF00"..L["Auto-cloning enabled"]})
    end
    if(WeakAuras.IsDefinedByAddon(data.id)) then
      tinsert(namestable, " ");
      tinsert(namestable, {" ", "|cFF00FFFF"..L["Addon"]..": "..WeakAuras.IsDefinedByAddon(data.id)});
    end

    local hasDescription = data.desc and data.desc ~= "";
    local hasUrl = data.url and data.url ~= "";
    local hasVersion = data.version and data.version ~= "";

    if(hasDescription or hasUrl or hasVersion) then
      tinsert(namestable, " ");
    end

    if(hasDescription) then
      tinsert(namestable, "|cFFFFD100\""..data.desc.."\"");
    end

    if (hasUrl) then
      tinsert(namestable, "|cFFFFD100" .. data.url .. "|r");
    end

    if (hasVersion) then
      tinsert(namestable, "|cFFFFD100" .. L["Version: "]  .. data.version .. "|r");
    end

    tinsert(namestable, " ");
    tinsert(namestable, {" ", "|cFF00FFFF"..L["Right-click for more options"]});
    if not(data.controlledChildren) then
      tinsert(namestable, {" ", "|cFF00FFFF"..L["Drag to move"]});
      tinsert(namestable, {" ", "|cFF00FFFF"..L["Control-click to select multiple displays"]});
    end
    tinsert(namestable, {" ", "|cFF00FFFF"..L["Shift-click to create chat link"]});
    local regionData = WeakAuras.regionOptions[data.regionType or ""]
    local displayName = regionData and regionData.displayName or "";
    self:SetDescription({data.id, displayName}, unpack(namestable));
  end,
  ["ReloadTooltip"] = function(self)if(
    WeakAuras.IsPickedMultiple() and WeakAuras.IsDisplayPicked(self.data.id)) then
    Show_Long_Tooltip(self.frame, WeakAuras.MultipleDisplayTooltipDesc());
  else
    Show_Long_Tooltip(self.frame, self.frame.description);
  end
  end,
  ["SetGrouping"] = function(self, groupingData)
    self.grouping = groupingData;
    if(self.grouping) then
      if(self.data.id == self.grouping.id) then
        self.frame:SetScript("OnClick", self.callbacks.OnClickGroupingSelf);
        self:SetDescription(L["Cancel"], L["Do not group this display"]);
      else
        if(self.data.regionType == "group" or self.data.regionType == "dynamicgroup") then
          self.frame:SetScript("OnClick", self.callbacks.OnClickGrouping);
          self:SetDescription(self.data.id, L["Add to group %s"]:format(self.data.id));
        else
          self:Disable();
        end
      end
    else
      self:SetNormalTooltip();
      self.frame:SetScript("OnClick", self.callbacks.OnClickNormal);
      self:Enable();
    end
  end,
  ["SetDragging"] = function(self, data, drop)
    if data then
      -- self
      if self.data.id == data.id or self.multi then
        if drop then
          --self.frame:Show()
          self:Drop()
          self.frame:SetScript("OnClick", self.callbacks.OnClickNormal)
          self.frame:EnableKeyboard(false); -- disables self.callbacks.OnKeyDown
        else
          Hide_Tooltip()
          self.frame:SetScript("OnClick", nil)
          self.frame:EnableKeyboard(true); -- enables self.callbacks.OnKeyDown
          self:Drag()
        end
        -- invalid targets
      elseif not self.data.parent and not self:IsGroup()
      then
        if drop then
          self:Enable()
        else
          self:Disable()
        end
        -- valid target
      else
        if drop then
          self.frame:SetScript("OnClick", self.callbacks.OnClickNormal)
        else
          self.frame:SetScript("OnClick", nil)
        end
      end
    else
      -- restore events and layout
      self.frame:SetScript("OnClick", self.callbacks.OnClickNormal)
      self.frame:EnableKeyboard(false);
      self:Enable()
      if (self.dragging) then
        self:Drop(true)
      end
    end
  end,
  ["ShowTooltip"] = function(self)
  end,
  ["Drag"] = function(self)
    local uiscale, scale = UIParent:GetScale(), self.frame:GetEffectiveScale()
    local x, w = self.frame:GetLeft(), self.frame:GetWidth()
    local _, y = GetCursorPosition()
    -- hide "visual clutter"
    self.downgroup:Hide()
    self.group:Hide()
    self.loaded:Hide()
    self.ungroup:Hide()
    self.upgroup:Hide()
    self.view:Hide()
    -- mark as being dragged, attach to mouse and raise frame strata
    self.dragging = true
    self.frame:StartMoving()
    self.frame:ClearAllPoints()
    self.frame.temp = {
      parent = self.frame:GetParent(),
      strata = self.frame:GetFrameStrata(),
    }
    self.frame:SetParent(UIParent)
    self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    if not self.multi then
      self.frame:SetPoint("Center", UIParent, "BOTTOMLEFT", (x+w/2)*scale/uiscale, y/uiscale)
    else
      if self.multi.selected then
        -- change label & icon
        self.frame:SetPoint("Center", UIParent, "BOTTOMLEFT", (x+w/2)*scale/uiscale, y/uiscale)
        self.frame.temp.title = self.title:GetText()
        self.title:SetText((L["%i auras selected"]):format(self.multi.size))
        self.icon:SetTexture("Interface\\Addons\\WeakAuras\\Media\\Textures\\icon.blp")
        self.icon:Show()
      else
        -- Hide frames
        self.frame:StopMovingOrSizing()
        self.frame:Hide()
      end
    end
    -- attach OnUpdate event to update drop indicator
    if not self.multi or (self.multi and self.multi.selected) then
      local id = self.data.id
      self.frame:SetScript("OnUpdate", function(self,elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed > 0.1 then
          Show_DropIndicator(id)
          self.elapsed = 0
        end
      end)
      Show_DropIndicator(id)
    end
    WeakAuras.UpdateButtonsScroll()
  end,
  ["Drop"] = function(self, reset)
    Show_DropIndicator()
    local target, area = select(2, GetDropTarget())
    -- get action and execute it
    self.frame:StopMovingOrSizing()
    self.frame:SetScript("OnUpdate", nil)
    if self.multi and self.multi.selected then
      -- restore title and icon
      self.title:SetText(self.frame.temp.title)
      WeakAuras.UpdateDisplayButton(self.data)
    end
    if self.dragging then
      self.frame:SetParent(self.frame.temp.parent)
      self.frame:SetFrameStrata(self.frame.temp.strata)
      self.frame.temp = nil
      if self.data.parent then
        self.downgroup:Show()
        self.ungroup:Show()
        self.upgroup:Show()
      else
        self.group:Show()
      end
      self.loaded:Show()
      self.view:Show()
    end
    self.dragging = false
    -- exit if we have no target or only want to reset
    if reset or not target then
      return WeakAuras.UpdateButtonsScroll()
    end
    local action = GetAction(target, area, self)
    if action then
      action(self,target)
    end
    self.multi = nil
    WeakAuras.SortDisplayButtons()
  end,
  ["GetGroupOrCopying"] = function(self)
    return self.group;
  end,
  ["SetTitle"] = function(self, title)
    self.titletext = title;
    self.title:SetText(title);
  end,
  ["GetTitle"] = function(self)
    return self.titletext;
  end,
  ["SetDescription"] = function(self, ...)
    self.frame.description = {...};
  end,
  ["SetIcon"] = function(self, icon)
    if(type(icon) == "string" or type(icon) == "number") then
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
  ["IsGroup"] = function(self)
    return self.data.regionType == "group" or self.data.regionType == "dynamicgroup"
  end,
  ["SetData"] = function(self, data)
    self.data = data;
    self.frame.id = data.id;
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
    self.loaded.title = L["Not Loaded"];
    self.loaded.desc = L["This display is not currently loaded"];
    self.loaded:SetNormalTexture("Interface\\BUTTONS\\UI-GuildButton-OfficerNote-Disabled.blp");
  end,
  ["EnableLoaded"] = function(self)
    self.loaded.title = L["Loaded"];
    self.loaded.desc = L["This display is currently loaded"];
    self.loaded:SetNormalTexture("Interface\\BUTTONS\\UI-GuildButton-OfficerNote-Up.blp");
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
    self:SetViewRegion();
    self:Enable();
    self:SetGroup();
    self:EnableGroup();
    self.renamebox:Hide();
    self.title:Show();
    local id = self.data.id;
    self.frame:SetScript("OnEnter", nil);
    self.frame:SetScript("OnLeave", nil);
    self.frame:SetScript("OnClick", nil);
    self.frame:SetScript("OnDragStart", nil);
    self.frame:SetScript("OnDragStop", nil);
    --self.frame:EnableMouse(false);
    self.frame:ClearAllPoints();
    self.frame:Hide();
    self.frame = nil;
    self.data = nil;
  end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
  local name = "WeakAurasDisplayButton"..AceGUI:GetNextWidgetNum(Type);
  local button = CreateFrame("BUTTON", name, UIParent, "OptionsListButtonTemplate");
  button:SetHeight(32);
  button:SetWidth(1000);
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

  button:SetScript("OnEnter", function()
    if(WeakAuras.IsPickedMultiple() and WeakAuras.IsDisplayPicked(button.id)) then
      Show_Long_Tooltip(button, WeakAuras.MultipleDisplayTooltipDesc());
    else
      if not(button.terribleCodeOrganizationHackTable.IsGroupingOrCopying()) then
        button.terribleCodeOrganizationHackTable.SetNormalTooltip();
      end
      Show_Long_Tooltip(button, button.description);
    end
  end);
  button:SetScript("OnLeave", Hide_Tooltip);

  local view = CreateFrame("BUTTON", nil, button);
  button.view = view;
  view:SetWidth(16);
  view:SetHeight(16);
  view:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0);
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
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.visibility) then
      self.visibility = priority;
      if(self.region and self.region.Expand) then
        button.terribleCodeOrganizationHackTable.OnShow();
        self.region:Expand();
        if (WeakAuras.personalRessourceDisplayFrame) then
          WeakAuras.personalRessourceDisplayFrame:expand(self.region.id);
        end
        if (WeakAuras.mouseFrame) then
          WeakAuras.mouseFrame:expand(self.region.id);
        end
      end
    end
  end
  view.PriorityHide = function(self, priority)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.visibility) then
      self.visibility = 0;
      if(self.region and self.region.Collapse) then
        button.terribleCodeOrganizationHackTable.OnHide();
        self.region:Collapse();
        if (WeakAuras.personalRessourceDisplayFrame) then
          WeakAuras.personalRessourceDisplayFrame:collapse(self.region.id);
        end
        if (WeakAuras.mouseFrame) then
          WeakAuras.mouseFrame:collapse(self.region.id);
        end
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

  local loaded = CreateFrame("BUTTON", nil, button);
  button.loaded = loaded;
  loaded:SetWidth(16);
  loaded:SetHeight(16);
  loaded:SetPoint("BOTTOM", button, "BOTTOM");
  loaded:SetPoint("LEFT", icon, "RIGHT", 0, 0);
  loaded:SetNormalTexture("Interface\\BUTTONS\\UI-GuildButton-OfficerNote-Up.blp");
  loaded:SetDisabledTexture("Interface\\BUTTONS\\UI-GuildButton-OfficerNote-Disabled.blp");
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
  renamebox:SetFont(STANDARD_TEXT_FONT, 10);
  renamebox:Hide();

  renamebox.func = function() --[[By default, do nothing!]] end;
  renamebox:SetScript("OnEnterPressed", function()
    local oldid = button.title:GetText();
    local newid = renamebox:GetText();
    if(newid == "" or (newid ~= oldid and WeakAuras.GetData(newid))) then
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

  local group = CreateFrame("BUTTON", nil, button);
  button.group = group;
  group:SetWidth(16);
  group:SetHeight(16);
  group:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -18, 0);
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
    --delete = delete, -- There is no variable called delete?
    --copy = copy, -- There is no variable called copy?
    view = view,
    --rename = rename, -- There is no variable called rename?
    renamebox = renamebox,
    --descbox = descbox, -- There is no variable called descbox?
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

  return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
