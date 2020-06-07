if not WeakAuras.IsCorrectVersion() then return end

local tinsert, tconcat, tremove, wipe = table.insert, table.concat, table.remove, wipe
local select, pairs, next, type, unpack = select, pairs, next, type, unpack
local tostring, error = tostring, error

local Type, Version = "WeakAurasDisplayButton", 55
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
  authorOptions = true,
  config = true,
  url = true,
  semver = true,
  version = true,
  internalVersion = true,
  tocversion = true
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
  if (part == "authorOptions" or all) and not IsRegionAGroup(source) then
    destination.authorOptions = {};
    WeakAuras.DeepCopy(source.authorOptions, destination.authorOptions);
  end
  if (part == "config" or all) and not IsRegionAGroup(source) then
    destination.config = {};
    WeakAuras.DeepCopy(source.config, destination.config);
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
        WeakAuras.Add(childData)
        WeakAuras.ClearAndUpdateOptions(childData.id)
      end
    else
      copyAuraPart(clipboard.source, clipboard.current, clipboard.part);
      WeakAuras.Add(clipboard.current)
      WeakAuras.ClearAndUpdateOptions(clipboard.current.id)
    end

    WeakAuras.FillOptions()
    WeakAuras.ScanForLoads({[clipboard.current.id] = true});
    WeakAuras.SortDisplayButtons();
    WeakAuras.PickDisplay(clipboard.current.id);
    WeakAuras.UpdateDisplayButton(clipboard.current.id);
    WeakAuras.ClearAndUpdateOptions(clipboard.current.id);
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

clipboard.copyAuthorOptionsEntry = {
  text = L["Author Options"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("authorOptions", L["Paste Author Options Settings"])
  end
};

clipboard.copyUserConfigEntry = {
  text = L["Custom Configuration"],
  notCheckable = true,
  func = function()
    WeakAuras_DropDownMenu:Hide();
    CopyToClipboard("config", L["Paste Custom Configuration"])
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
    clipboard.copyAuthorOptionsEntry = nil;
    clipboard.copyUserConfigEntry = nil;
    clipboard.copyGroupEntry.text = L["Group"];
  else
    clipboard.copyEverythingEntry.text = L["Everything"];
    clipboard.copyDisplayEntry.text = L["Display"];
    clipboard.copyTriggerEntry.text = L["Trigger"];
    clipboard.copyConditionsEntry.text = L["Conditions"];
    clipboard.copyLoadEntry.text = L["Load"];
    clipboard.copyActionsEntry.text = L["Actions"];
    clipboard.copyAnimationsEntry.text = L["Animations"];
    clipboard.copyAuthorOptionsEntry = L["Author Options"];
    clipboard.copyUserConfigEntry = L["Custom Configuration"];
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
          WeakAuras.ClearAndUpdateOptions(group.data.id)
          WeakAuras.ClearAndUpdateOptions(source.data.id)
          WeakAuras.UpdateDisplayButton(group.data)
          WeakAuras.FillOptions()
          group.callbacks.UpdateExpandButton();
          group:ReloadTooltip()
        else
          WeakAuras.Add(source.data)
          WeakAuras.ClearAndUpdateOptions(source.data.id)
          WeakAuras.FillOptions()
        end
      else
        -- move source into the top-level list
        WeakAuras.Add(source.data)
        WeakAuras.ClearAndUpdateOptions(source.data.id)
        WeakAuras.FillOptions()
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
        WeakAuras.ClearAndUpdateOptions(parent.id);
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
        WeakAuras.ClearAndUpdateOptions(parent.id)
        WeakAuras.FillOptions()
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

-- WORKAROUND
-- Blizzard in its infinite wisdom did:
-- * Force enable the profanity filter for the chinese region
-- * Add a realm name's part to the profanity filter
function WeakAuras.ObfuscateName(name)
  if (GetCurrentRegion() == 5) then
    local result = ""
    for i = 1, #name do
      local b = name:byte(i)
      if (b >= 196 and i ~= 1) then
        -- UTF8 Start byte
        result = result .. string.char(46, b)
      else
        result = result .. string.char(b)
      end
    end
    return result
  else
    return name
  end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(1000);
    self:SetHeight(32);
    self.hasThumbnail = false
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
            if realm then
              fullName = name.."-".. WeakAuras.ObfuscateName(realm)
            else
              fullName = name
            end
          end
          editbox:Insert("[WeakAuras: "..fullName.." - "..data.id.."]");
        elseif not data.controlledChildren then
          -- select all buttons between 1st select and current
          WeakAuras.PickDisplayMultipleShift(data.id)
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
            WeakAuras.ClearPicks();
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
      if #self.grouping > 0 then
        for index, childId in ipairs(self.grouping) do
          tinsert(data.controlledChildren, childId);
          local childButton = WeakAuras.GetDisplayButton(childId);
          local childData = WeakAuras.GetData(childId);
          if childData.parent then
            childButton:Ungroup();
          end
          childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
          childButton:SetGroupOrder(#data.controlledChildren, #data.controlledChildren);
          childData.parent = data.id;
          WeakAuras.Add(childData);
          WeakAuras.ClearAndUpdateOptions(childData.id)
        end
      else
        tinsert(data.controlledChildren, self.grouping.id);
        local childButton = WeakAuras.GetDisplayButton(self.grouping.id);
        childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
        childButton:SetGroupOrder(#data.controlledChildren, #data.controlledChildren);
        self.grouping.parent = data.id;
        WeakAuras.Add(self.grouping);
        WeakAuras.ClearAndUpdateOptions(self.grouping.id);
      end
      if (data.regionType == "dynamicgroup") then
        self.grouping.xOffset = 0;
        self.grouping.yOffset = 0;
      end
      WeakAuras.Add(data);
      WeakAuras.ClearAndUpdateOptions(data.id)
      self.callbacks.UpdateExpandButton();
      WeakAuras.SetGrouping();
      WeakAuras.UpdateDisplayButton(data);
      WeakAuras.ClearAndUpdateOptions(data.id);
      WeakAuras.FillOptions();
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
      if data.controlledChildren then
        local new_idGroup = WeakAuras.DuplicateAura(data)
        for index, childId in pairs(data.controlledChildren) do
          local childData = WeakAuras.GetData(childId)
          WeakAuras.DuplicateAura(childData, new_idGroup)
        end
        WeakAuras.SortDisplayButtons()
        WeakAuras.PickAndEditDisplay(new_idGroup)
      else
        local new_id = WeakAuras.DuplicateAura(data)
        WeakAuras.SortDisplayButtons()
        WeakAuras.PickAndEditDisplay(new_id)
      end
    end

    function self.callbacks.OnDeleteAllClick()
      if (WeakAuras.IsImporting()) then return end;
      local toDelete = {}
      if(data.controlledChildren) then

        local region = WeakAuras.regions[data.id];
        if (region.Suspend) then
          region:Suspend();
        end

        for _, id in pairs(data.controlledChildren) do
          tinsert(toDelete, WeakAuras.GetData(id));
        end
      end
      tinsert(toDelete, data)
      WeakAuras.ConfirmDelete(toDelete);
    end

    function self.callbacks.OnUngroupClick()
      WeakAuras.Ungroup(data);
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
            WeakAuras.ClearAndUpdateOptions(parentData.id)
            self:SetGroupOrder(index - 1, #parentData.controlledChildren);
            local otherbutton = WeakAuras.GetDisplayButton(parentData.controlledChildren[index]);
            otherbutton:SetGroupOrder(index, #parentData.controlledChildren);
            WeakAuras.SortDisplayButtons();
            local updata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = -32};
            local downdata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = 32};
            WeakAuras.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index-1]), "main", updata, self.frame, true, function() WeakAuras.SortDisplayButtons() end);
            WeakAuras.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index]), "main", downdata, otherbutton.frame, true, function() WeakAuras.SortDisplayButtons() end);
            WeakAuras.UpdateDisplayButton(parentData);
            WeakAuras.FillOptions()
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
            WeakAuras.ClearAndUpdateOptions(parentData.id)
            self:SetGroupOrder(index + 1, #parentData.controlledChildren);
            local otherbutton = WeakAuras.GetDisplayButton(parentData.controlledChildren[index]);
            otherbutton:SetGroupOrder(index, #parentData.controlledChildren);
            WeakAuras.SortDisplayButtons()
            local updata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = -32};
            local downdata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = 32};
            WeakAuras.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index+1]), "main", downdata, self.frame, true, function() WeakAuras.SortDisplayButtons() end);
            WeakAuras.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index]), "main", updata, otherbutton.frame, true, function() WeakAuras.SortDisplayButtons() end);
            WeakAuras.UpdateDisplayButton(parentData);
            WeakAuras.FillOptions()
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

    function self.callbacks.OnUpdateClick()
      local _,_,updateData = self:HasUpdate()
      if updateData then
        WeakAuras.Import(updateData.encoded, self.data)
      end
    end

    function self.callbacks.OnRenameAction(newid)
      if (WeakAuras.IsImporting()) then return end;
      local oldid = data.id;
      if not(newid == oldid) then

        WeakAuras.Rename(data, newid);
        WeakAuras.Add(data)

        WeakAuras.displayButtons[newid] = WeakAuras.displayButtons[oldid];
        WeakAuras.displayButtons[newid]:SetData(data)
        WeakAuras.displayButtons[oldid] = nil;
        WeakAuras.ClearOptions(oldid)

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

    function self.callbacks.wagoStopIgnoreAll(_, skipUpdateIcon)
      self.data.ignoreWagoUpdate = nil
      self.data.skipWagoUpdate = nil
      if not skipUpdateIcon then
        self:RefreshUpdate("wagoStopIgnoreAll")
      end
    end

    function self.callbacks.wagoIgnoreAll(_, skipUpdateIcon)
      self.data.ignoreWagoUpdate = true
      if not skipUpdateIcon then
        self:RefreshUpdate("wagoIgnoreAll")
      end
    end

    function self.callbacks.wagoStopIgnoreNext(_, skipUpdateIcon)
      self.data.skipWagoUpdate = nil
      if not skipUpdateIcon then
        self:RefreshUpdate("wagoStopIgnoreNext")
      end
    end

    function self.callbacks.wagoIgnoreNext(_, skipUpdateIcon)
      self.data.skipWagoUpdate = self.update.version
      if not skipUpdateIcon then
        self:RefreshUpdate("wagoIgnoreNext")
      end
    end

    self.frame.terribleCodeOrganizationHackTable = {};

    function self.frame.terribleCodeOrganizationHackTable.IsGroupingOrCopying()
      return self.grouping;
    end

    function self.frame.terribleCodeOrganizationHackTable.SetNormalTooltip()
      self:SetNormalTooltip();
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
    tinsert(copyEntries, clipboard.copyAuthorOptionsEntry);
    tinsert(copyEntries, clipboard.copyUserConfigEntry);

    self:SetTitle(data.id);
    self.menu = {
      {
        text = L["Rename"],
        notCheckable = true,
        func = self.callbacks.OnRenameClick
      },
      {
        text = L["Copy settings..."],
        notCheckable = true,
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
            notCheckable = true,
            func = function()
              WeakAuras.ConvertDisplay(data, regionType);
              WeakAuras_DropDownMenu:Hide();
            end
          });
        end
      end
      tinsert(self.menu, {
        text = L["Convert to..."],
        notCheckable = true,
        hasArrow = true,
        menuList = convertMenu
      });
    end

    tinsert(self.menu, {
      text = L["Duplicate"],
      notCheckable = true,
      func = self.callbacks.OnDuplicateClick
    });

    tinsert(self.menu, {
      text = L["Set tooltip description"],
      notCheckable = true,
      func = function() WeakAuras.ShowDisplayTooltip(data, nil, nil, nil, nil, nil, nil, "desc") end
    });


    if (data.url and data.url ~= "") then
      tinsert(self.menu, {
        text = L["Copy URL"],
        notCheckable = true,
        func = function() WeakAuras.ShowDisplayTooltip(data, nil, nil, nil, nil, nil, nil, "url") end
      });
    end

    tinsert(self.menu, {
      text = L["Export to string..."],
      notCheckable = true,
      func = function() WeakAuras.ExportToString(data.id) end
    });
    tinsert(self.menu, {
      text = L["Export to Lua table..."],
      notCheckable = true,
      func = function() WeakAuras.ExportToTable(data.id) end
    });

    if WeakAurasCompanion then
      tinsert(self.menu, {
        text = '|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t' .. L["Wago Update"],
        notCheckable = true,
        hasArrow = true,
        menuList = { }
      });
    end

    tinsert(self.menu, {
      text = " ",
      notClickable = true,
      notCheckable = true,
    });
    if not data.controlledChildren then
      tinsert(self.menu, {
        text = L["Delete"],
        notCheckable = true,
        func = self.callbacks.OnDeleteClick
      });
    end

    if (data.controlledChildren) then
      tinsert(self.menu, {
        text = L["Delete children and group"],
        notCheckable = true,
        func = self.callbacks.OnDeleteAllClick
      });
    end
    tinsert(self.menu, {
      text = " ",
      notClickable = true,
      notCheckable = true,
    });
    tinsert(self.menu, {
      text = L["Close"],
      notCheckable = true,
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

    if WeakAurasCompanion then
      local hasUpdate, _, updateData = self:HasUpdate()
      if hasUpdate then
        self.update.hasUpdate = hasUpdate
        self.update.version = updateData.wagoVersion
        local showVersion = self.data.semver or self.data.version or 0
        local showCompanionVersion = updateData.wagoSemver or updateData.wagoVersion
        self.update.title = L["Update %s by %s"]:format(updateData.name, updateData.author)
        self.update.desc = L["From version %s to version %s"]:format(showVersion, showCompanionVersion)
        if updateData.versionNote then
          self.update.desc = ("%s\n\n%s"):format(self.update.desc, updateData.versionNote)
        end
        self.update:SetScript("OnClick", self.callbacks.OnUpdateClick);
      end
    end

    if data.parent then
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

    self.frame:Hide()
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
      WeakAuras.GetTriggerDescription(data, -1, namestable)
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
    local hasVersion = (data.semver and data.semver ~= "") or (data.version and data.version ~= "");

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
      tinsert(namestable, "|cFFFFD100" .. L["Version: "]  .. (data.semver or data.version) .. "|r");
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
  ["SetGrouping"] = function(self, groupingData, multi)
    self.grouping = groupingData;
    if(self.grouping) then
      if(self.data.id == self.grouping.id or multi) then
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
  ["Ungroup"] = function(self)
    if (WeakAuras.IsImporting()) then return end;
    local parentData = WeakAuras.GetData(self.data.parent);
    if not parentData then return end;
    local index;
    for childIndex, childId in pairs(parentData.controlledChildren) do
      if(childId == self.data.id) then
        index = childIndex;
        break;
      end
    end
    if(index) then
      tremove(parentData.controlledChildren, index);
      WeakAuras.Add(parentData);
      WeakAuras.ClearAndUpdateOptions(parentData.id);
    else
      error("Display thinks it is a member of a group which does not control it");
    end
    self:SetGroup();
    self.data.parent = nil;
    WeakAuras.Add(self.data);
    WeakAuras.ClearAndUpdateOptions(self.data.id);
    WeakAuras.UpdateGroupOrders(parentData);
    WeakAuras.UpdateDisplayButton(parentData);
    WeakAuras.SortDisplayButtons();
  end,
  ["SetDragging"] = function(self, data, drop, size)
    if (size) then
      self.multi = {
        size = size,
        selected = data and (data.id == self.data.id)
      }
    end
    if data then
      -- self
      if self.data.id == data.id or self.multi then
        if drop then
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
        self:OverrideIcon();
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
      self:RestoreIcon();
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
    self.multi = nil
    if reset or not target then
      return WeakAuras.UpdateButtonsScroll()
    end
    local action = GetAction(target, area, self)
    if action then
      action(self, target)
    end
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
    WeakAuras.SetCollapsed(self.data.id, "displayButton", "", false)
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
    WeakAuras.SetCollapsed(self.data.id, "displayButton", "", true)
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
    return not WeakAuras.IsCollapsed(self.data.id, "displayButton", "", true)
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
  ["ShowGroupUpdate"] = function(self)
    if self.groupUpdate and self.groupUpdate.disabled then
      self.groupUpdate:Show()
      self.groupUpdate.disabled = false
    end
  end,
  ["HideGroupUpdate"] = function(self)
    if self.groupUpdate and not self.groupUpdate.disabled then
      self.groupUpdate:Hide()
      self.groupUpdate.disabled = true
    end
  end,
  ["RefreshUpdateMenu"] = function(self)
    local pos
    for k, menu in pairs(self.menu) do
      if menu.text and menu.text:find(L["Wago Update"]) then
        pos = k
        break
      end
    end
    if pos then
      local wagoMenu = self.menu[pos].menuList
      for i=1,#wagoMenu do tremove(wagoMenu, 1) end
      tinsert(wagoMenu, {
        text = self.data.ignoreWagoUpdate and L["Stop ignoring Updates"] or L["Ignore all Updates"],
        notCheckable = true,
        func = self.data.ignoreWagoUpdate and self.callbacks.wagoStopIgnoreAll or self.callbacks.wagoIgnoreAll
      })
      if not self.data.ignoreWagoUpdate and self.update.hasUpdate then
        if self.data.skipWagoUpdate and self.update.version == self.data.skipWagoUpdate then
          tinsert(wagoMenu, {
            text =  L["Don't skip this Version"],
            notCheckable = true,
            func = self.callbacks.wagoStopIgnoreNext
          });
        else
          tinsert(wagoMenu, {
            text = L["Skip this Version"],
            notCheckable = true,
            func = self.callbacks.wagoIgnoreNext
          });
          tinsert(wagoMenu, {
            text = " ",
            notClickable = true,
            notCheckable = true,
          });
          tinsert(wagoMenu, {
            text = L["Update this Aura"],
            notCheckable = true,
            func = self.callbacks.OnUpdateClick
          });
        end
      end
    end
  end,
  ["ShowUpdateIcon"] = function(self)
    if self.update and self.update.disabled then
      self.update:Show()
      self.update:Enable()
      self.updateLogo:Show()
      self.update.disabled = false
    end
  end,
  ["HideUpdateIcon"] = function(self)
    if self.update and not self.update.disabled then
      self.update:Hide()
      self.update:Disable()
      self.updateLogo:Hide()
      self.update.disabled = true
    end
  end,
  ["HasUpdate"] = function(self)
    -- return hasUpdate, skipVersion, updateData, key
    if not WeakAurasCompanion or self.data.ignoreWagoUpdate then return end
    local slug = self.data.uid and WeakAurasCompanion.uids[self.data.uid] or WeakAurasCompanion.ids[self.data.id]
    if slug then
      local updateData = WeakAurasCompanion.slugs[slug]
      if updateData then
        if not (self.data.skipWagoUpdate and self.data.skipWagoUpdate == updateData.wagoVersion) then
          if not self.data.version or tonumber(updateData.wagoVersion) > tonumber(self.data.version) then
            -- got update
            return true, false, updateData, slug
          end
        else
          -- version skip flag
          return true, true, updateData, slug
        end
      end
    end
    -- no addon, or no data, or ignore flag
    return false, false, nil, nil
  end,
  ["RefreshBT2UpgradeIcon"] = function(self)
    if not self.data.controlledChildren and self.data.triggers then
      for index, t in ipairs(self.data.triggers) do
        if t.trigger and t.trigger.type == "aura" then
          self.bt2upgrade:SetScript("OnClick", function()
            WeakAuras.PickDisplay(self.data.id, "trigger")
          end)
          self.bt2upgrade:Show()
          return
        end
      end
    end
    self.bt2upgrade:Hide()
  end,
  ["RefreshUpdate"] = function(self, actionFunc)
    if self.data.parent then
      -- is in a group
      local parentButton = WeakAuras.GetDisplayButton(self.data.parent)
      if parentButton then
        parentButton:RefreshUpdate(actionFunc)
      end
    else
      -- is top level
      local hasUpdate, skipVersion, _, slug = self:HasUpdate()
      self:RefreshUpdateMenu()
      if hasUpdate and not skipVersion then
        self:ShowUpdateIcon()
      else
        self:HideUpdateIcon()
      end
      if self.data.controlledChildren then
        -- is a group
        local hasUpdate, skipVersion, _, slug = self:HasUpdate()
        local showGroupUpdateIcon = false
        for childIndex, childId in pairs(self.data.controlledChildren) do
          local childButton = WeakAuras.GetDisplayButton(childId);
          if childButton then
            if actionFunc then
              childButton.callbacks[actionFunc](nil, true)
            end
            childButton:RefreshUpdateMenu()
            local childHasUpdate, childSkipVersion, _, childSlug = childButton:HasUpdate()
            if childHasUpdate and slug ~= childSlug and not childSkipVersion then
              showGroupUpdateIcon = true
              childButton:ShowUpdateIcon()
            else
              childButton:HideUpdateIcon()
            end
          end
        end
        if showGroupUpdateIcon then
          self:ShowGroupUpdate()
        else
          self:HideGroupUpdate()
        end
      end
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
  ["ClearPick"] = function(self, noHide)
    self.frame:UnlockHighlight();
    if not noHide then
      self.view:PriorityHide(1);
    end
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
    self:ReleaseThumbnail()
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
  end,
  ["UpdateThumbnail"] = function(self)
    if not self.hasThumbnail then
      return
    end

    if self.data.regionType ~= self.thumbnailType then
      self:ReleaseThumbnail()
      self:AcquireThumbnail()
    else
      local option = WeakAuras.regionOptions[self.thumbnailType]
      if option and option.modifyThumbnail then
        option.modifyThumbnail(self.frame, self.thumbnail, self.data)
      end
    end
  end,
  ["ReleaseThumbnail"] = function(self)
    if not self.hasThumbnail then
      return
    end
    self.hasThumbnail = false

    if self.thumbnail then
      local regionType = self.thumbnailType
      local option = WeakAuras.regionOptions[regionType]
      option.releaseThumbnail(self.thumbnail)
      self.thumbnail = nil
    end
  end,
  ["AcquireThumbnail"] = function(self)
    if self.hasThumbnail then
      return
    end

    if not self.data then
      return
    end

    self.hasThumbnail = true

    local button = self.frame
    local regionType = self.data.regionType
    self.thumbnailType = regionType

    local option = WeakAuras.regionOptions[regionType]
    if option and option.acquireThumbnail then
      self.thumbnail = option.acquireThumbnail(button, self.data)
      self:SetIcon(self.thumbnail)
    else
      self:SetIcon("Interface\\Icons\\INV_Misc_QuestionMark")
    end
  end,
  ["SetIcon"] = function(self, icon)
    self.orgIcon = icon;
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
      icon:Show()
      self.iconRegion:Show();
      self.icon:Hide();
    end
  end,
  ["OverrideIcon"] = function(self)
    self.icon:SetTexture("Interface\\Addons\\WeakAuras\\Media\\Textures\\icon.blp")
    self.icon:Show()
    if(self.iconRegion and self.iconRegion.Hide) then
      self.iconRegion:Hide();
    end
  end,
  ["RestoreIcon"] = function(self)
    self:SetIcon(self.orgIcon);
  end,
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
        WeakAuras.FakeStatesFor(self.region.id, true)
        if (WeakAuras.personalRessourceDisplayFrame) then
          WeakAuras.personalRessourceDisplayFrame:expand(self.region.id);
        end
        if (WeakAuras.mouseFrame) then
          WeakAuras.mouseFrame:expand(self.region.id);
        end
      end
    end
    if self.region and self.region.ClickToPick then
      self.region:ClickToPick();
    end
  end
  view.PriorityHide = function(self, priority)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.visibility) then
      self.visibility = 0;
      if(self.region and self.region.Collapse) then
        WeakAuras.FakeStatesFor(self.region.id, false)
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

  local update, updateLogo
  local groupUpdate
  if WeakAurasCompanion then
    update = CreateFrame("BUTTON", nil, button);
    button.update = update
    update.disabled = true
    update.func = function() end
    update:SetNormalTexture([[Interface\AddOns\WeakAuras\Media\Textures\wagoupdate_refresh.tga]])
    update:Disable()
    update:SetWidth(24)
    update:SetHeight(24)
    update:SetPoint("RIGHT", button, "RIGHT", -35, 0)
    update.title = ""
    update.desc = ""
    update.hasUpdate = false
    update.version = nil
    update.menuDisabled = true

    -- Add logo
    updateLogo = CreateFrame("Frame", nil, button)
    button.updateLogo = updateLogo
    local tex = updateLogo:CreateTexture(nil, "OVERLAY")
    tex:SetTexture([[Interface\AddOns\WeakAuras\Media\Textures\wagoupdate_logo.tga]])
    tex:SetAllPoints()
    updateLogo:SetSize(24,24)
    updateLogo:SetPoint("CENTER",update)

    -- Animation On Hover
    local animGroup = update:CreateAnimationGroup()
    update.animGroup = animGroup
    local animRotate = animGroup:CreateAnimation("rotation")
    animRotate:SetDegrees(-360)
    animRotate:SetDuration(1)
    animRotate:SetSmoothing("OUT")

    animGroup:SetScript("OnFinished",function() if (MouseIsOver(update)) then animGroup:Play() end end)
    update:SetScript("OnEnter", function()
      animGroup:Play()
      Show_Tooltip(button, update.title, update.desc)
    end);
    update:SetScript("OnLeave", Hide_Tooltip)
    update:Hide()
    updateLogo:Hide()

    -- Update in group icon
    groupUpdate = CreateFrame("Frame", nil, button)
    button.groupUpdate = groupUpdate
    local gTex = groupUpdate:CreateTexture(nil, "OVERLAY")
    gTex:SetTexture([[Interface\AddOns\WeakAuras\Media\Textures\wagoupdate_logo.tga]])
    gTex:SetAllPoints()
    groupUpdate:SetSize(16, 16)
    groupUpdate:SetPoint("BOTTOM", button, "BOTTOM")
    groupUpdate:SetPoint("LEFT", icon, "RIGHT", 20, 0)
    groupUpdate.disabled = true
    groupUpdate.title = L["Update in Group"]
    groupUpdate.desc = L["Group contains updates from Wago"]
    groupUpdate:SetScript("OnEnter", function() Show_Tooltip(button, groupUpdate.title, groupUpdate.desc) end)
    groupUpdate:SetScript("OnLeave", Hide_Tooltip)
    groupUpdate:Hide()
  end

  -- TODO: remove this once legacy aura trigger is removed
  local bt2upgrade = CreateFrame("BUTTON", nil, button);
  button.bt2upgrade = bt2upgrade
  bt2upgrade.func = function() end
  bt2upgrade:SetNormalTexture([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
  bt2upgrade:SetWidth(16)
  bt2upgrade:SetHeight(16)
  bt2upgrade:SetPoint("RIGHT", button, "RIGHT", -60, 0)
  bt2upgrade:SetScript("OnEnter", function()
    Show_Tooltip(
      button,
      L["Legacy Aura Trigger"],
      L["This aura has legacy aura trigger(s). Convert them to the new system to benefit from enhanced performance and features"]
    )
  end)
  bt2upgrade:SetScript("OnLeave", Hide_Tooltip)
  bt2upgrade:Hide()

  local widget = {
    frame = button,
    title = title,
    icon = icon,
    view = view,
    renamebox = renamebox,
    group = group,
    ungroup = ungroup,
    upgroup = upgroup,
    downgroup = downgroup,
    loaded = loaded,
    background = background,
    expand = expand,
    update = update,
    bt2upgrade = bt2upgrade,
    groupUpdate = groupUpdate,
    updateLogo = updateLogo,
    type = Type
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
