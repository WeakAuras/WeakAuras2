if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local tinsert, tremove = table.insert, table.remove
local select, pairs, type, unpack = select, pairs, type, unpack
local error = error

local Type, Version = "WeakAurasDisplayButton", 60
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

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
    destination.triggers = CopyTable(source.triggers);
  end
  if (part == "condition" or all) and not IsRegionAGroup(source) then
    destination.conditions = CopyTable(source.conditions);
  end
  if (part == "load" or all) and not IsRegionAGroup(source) then
    destination.load = CopyTable(source.load);
  end
  if (part == "action" or all) and not IsRegionAGroup(source) then
    destination.actions = CopyTable(source.actions);
  end
  if (part == "animation" or all) and not IsRegionAGroup(source) then
    destination.animation = CopyTable(source.animation);
  end
  if (part == "authorOptions" or all) and not IsRegionAGroup(source) then
    destination.authorOptions = CopyTable(source.authorOptions);
  end
  if (part == "config" or all) and not IsRegionAGroup(source) then
    destination.config = CopyTable(source.config);
  end

end

local function CopyToClipboard(part, description)
  clipboard.part = part;
  clipboard.pasteText = description;
  clipboard.source = CopyTable(clipboard.current);
end

clipboard.pasteMenuEntry = {
  text = nil, -- Hidden by default
  notCheckable = true,
  func = function()
    if (not IsRegionAGroup(clipboard.source) and IsRegionAGroup(clipboard.current)) then
      -- Copy from a single aura to a group => paste it to each individual aura
      for child in OptionsPrivate.Private.TraverseLeafs(clipboard.current) do
        copyAuraPart(clipboard.source, child, clipboard.part);
        WeakAuras.Add(child)
        WeakAuras.ClearAndUpdateOptions(child.id)
      end
    else
      copyAuraPart(clipboard.source, clipboard.current, clipboard.part);
      WeakAuras.Add(clipboard.current)
      WeakAuras.ClearAndUpdateOptions(clipboard.current.id)
    end

    WeakAuras.FillOptions()
    OptionsPrivate.Private.ScanForLoads({[clipboard.current.id] = true});
    OptionsPrivate.SortDisplayButtons(nil, true);
    WeakAuras.PickDisplay(clipboard.current.id);
    WeakAuras.UpdateThumbnail(clipboard.current.id);
    WeakAuras.ClearAndUpdateOptions(clipboard.current.id);
  end
}

clipboard.copyEverythingEntry = {
  text = L["Everything"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("all", L["Paste Settings"])
  end
};

clipboard.copyGroupEntry = {
  text = L["Group"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("display", L["Paste Group Settings"])
  end
};

clipboard.copyDisplayEntry = {
  text = L["Display"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("display", L["Paste Display Settings"])
  end
};

clipboard.copyTriggerEntry = {
  text = L["Trigger"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("trigger", L["Paste Trigger Settings"])
  end
};

clipboard.copyConditionsEntry = {
  text = L["Conditions"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("condition", L["Paste Condition Settings"])
  end
};

clipboard.copyLoadEntry = {
  text = L["Load"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("load", L["Paste Load Settings"])
  end
};

clipboard.copyActionsEntry = {
  text = L["Actions"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("action", L["Paste Action Settings"])
  end
};

clipboard.copyAnimationsEntry = {
  text = L["Animations"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("animation", L["Paste Animations Settings"])
  end
};

clipboard.copyAuthorOptionsEntry = {
  text = L["Author Options"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
    CopyToClipboard("authorOptions", L["Paste Author Options Settings"])
  end
};

clipboard.copyUserConfigEntry = {
  text = L["Custom Configuration"],
  notCheckable = true,
  func = function()
    LibDD:CloseDropDownMenus()
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
  GameTooltip:ClearAllPoints()
  GameTooltip:SetPoint("LEFT", owner, "RIGHT");
  GameTooltip:ClearLines();
  GameTooltip:AddLine(line1);
  GameTooltip:AddLine(line2, 1, 1, 1, 1);
  GameTooltip:Show();
end

local function Show_Long_Tooltip(owner, description)
  GameTooltip:SetOwner(owner, "ANCHOR_NONE");
  GameTooltip:ClearAllPoints()
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
        GameTooltip:AddDoubleLine(v[1], v[2]..(v[3] and (" |T"..v[3]..":12:12:0:0:64:64:4:60:4:60|t") or ""),
                                  1, 1, 1, 1, 1, 1, 1, 1);
      end
    end
    line = line + 1;
  end
  GameTooltip:Show();
end

local function ensure(t, k, v)
  return t and k and v and t[k] == v
end

local statusIconPool = CreateFramePool("Button")

--[[     Actions     ]]--

local Actions = {
  -- move source into group or top-level list / optionally place it before or after target
  ["Group"] = function(source, groupId, target, before)
    if source and not source.data.parent then
      if groupId then
        local group = OptionsPrivate.GetDisplayButton(groupId)
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
          OptionsPrivate.Private.AddParents(group.data)
          WeakAuras.UpdateGroupOrders(group.data)
          WeakAuras.ClearAndUpdateOptions(group.data.id)
          WeakAuras.ClearAndUpdateOptions(source.data.id)
          group.callbacks.UpdateExpandButton();
          group:UpdateParentWarning()
          group:ReloadTooltip()
        else
          WeakAuras.Add(source.data)
          WeakAuras.ClearAndUpdateOptions(source.data.id)
        end
      else
        -- move source into the top-level list
        WeakAuras.Add(source.data)
        WeakAuras.ClearAndUpdateOptions(source.data.id)
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
        OptionsPrivate.Private.AddParents(parent)
        WeakAuras.UpdateGroupOrders(parent);
        WeakAuras.ClearAndUpdateOptions(parent.id);
        local group = OptionsPrivate.GetDisplayButton(parent.id)
        group.callbacks.UpdateExpandButton();
        group:UpdateParentWarning()
        group:ReloadTooltip()
      else
        error("Display thinks it is a member of a group which does not control it")
      end
    else
      error("Calling 'Ungroup' with invalid source. Reload your UI to fix the display list.")
    end
  end
}


local function GetAction(target, area)
  if target and area then
    if area == "GROUP" then
      return function(_source, _target)
        if _source.data.parent then
          Actions["Ungroup"](_source)
        end
        Actions["Group"](_source, _target.data.id)
      end
    else -- BEFORE or AFTER
      -- Insert into target's parent, at the right position
      if target.data.parent then
        return function(_source, _target)
          if _source.data.parent then
            Actions["Ungroup"](_source)
          end
          Actions["Group"](_source, _target.data.parent, _target, area == "BEFORE")
        end
      end
    end
  end
end

-------------------------

local function GetDropTarget()
  local buttonList = OptionsPrivate.displayButtons

  for id, button in pairs(buttonList) do
    if not button.dragging and button:IsEnabled() and button:IsShown() then
      local halfHeight = button.frame:GetHeight() / 2
      local height = button.frame:GetHeight()
      if button.data.controlledChildren then
        if button.data.parent == nil and button.frame:IsMouseOver(1, -1) then
          -- Top level group, always group into
          return id, button, "GROUP"
        end

        -- For sub groups, middle third is for grouping
        if button.frame:IsMouseOver(-height / 3, height / 3) then
          return id, button, "GROUP"
        end
      end

      if button.frame:IsMouseOver(1, height / 2) then
        return id, button, "BEFORE"
      elseif button.frame:IsMouseOver(-height / 2, -1) then
        return id, button, "AFTER"
      end
    end
  end
end

local function Show_DropIndicator(id)
  local indicator = OptionsPrivate.DropIndicator()
  local source = OptionsPrivate.GetDisplayButton(id)
  local target, pos
  if source then
    target, pos = select(2, GetDropTarget())
  end
  local action = GetAction(target, pos)
  if action then
    indicator:ShowAction(target, pos)
  else
    indicator:Hide()
  end
end

-- WORKAROUND
-- Blizzard in its infinite wisdom did:
-- * Force enable the profanity filter for the chinese region
-- * Add a realm name's part to the profanity filter
local function ObfuscateName(name)
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

local function IsParentRecursive(needle, parent)
  if needle.id == parent.id then
    return true
  end
  if needle.parent then
    local needleParent = WeakAuras.GetData(needle.parent)
    return IsParentRecursive(needleParent, parent)
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
    self.first = false
    self.last = false
  end,
  ["Initialize"] = function(self)
    self.callbacks = {};

    function self.callbacks.OnClickNormal(_, mouseButton)
      if(IsControlKeyDown() and not self.data.controlledChildren) then
        if (OptionsPrivate.IsDisplayPicked(self.data.id)) then
          OptionsPrivate.ClearPick(self.data.id);
        else
          OptionsPrivate.PickDisplayMultiple(self.data.id);
        end
        self:ReloadTooltip();
      elseif(IsShiftKeyDown()) then
        local editbox = GetCurrentKeyBoardFocus();
        if(editbox) then
          if (not fullName) then
            local name, realm = UnitFullName("player")
            if realm then
              fullName = name.."-".. ObfuscateName(realm)
            else
              fullName = name
            end
          end
          local url = ""
          if self.data.url then
            url = " ".. self.data.url
          end
          editbox:Insert("[WeakAuras: "..fullName.." - "..self.data.id.."]"..url)
          OptionsPrivate.Private.linked = OptionsPrivate.Private.linked or {}
          OptionsPrivate.Private.linked[self.data.id] = GetTime()
        elseif not self.data.controlledChildren then
          -- select all buttons between 1st select and current
          OptionsPrivate.PickDisplayMultipleShift(self.data.id)
        end
      else
        if(mouseButton == "RightButton") then
          Hide_Tooltip();
          if(OptionsPrivate.IsDisplayPicked(self.data.id) and OptionsPrivate.IsPickedMultiple()) then
            LibDD:EasyMenu(OptionsPrivate.MultipleDisplayTooltipMenu(), WeakAuras_DropDownMenu, self.frame, 0, 0, "MENU");
          else
            UpdateClipboardMenuEntry(self.data);
            LibDD:EasyMenu(self.menu, WeakAuras_DropDownMenu, self.frame, 0, 0, "MENU");
            if not(OptionsPrivate.IsDisplayPicked(self.data.id)) then
              if self.data.controlledChildren then
                WeakAuras.PickDisplay(self.data.id, "group")
              else
                WeakAuras.PickDisplay(self.data.id);
              end
            end
          end
        else
          if (OptionsPrivate.IsDisplayPicked(self.data.id)) then
            OptionsPrivate.ClearPicks();
          else
            if self.data.controlledChildren then
              WeakAuras.PickDisplay(self.data.id, "group")
            else
              WeakAuras.PickDisplay(self.data.id);
            end
          end
          self:ReloadTooltip();
        end
      end
    end

    function self.callbacks.UpdateExpandButton()
      if(not self.data.controlledChildren or #self.data.controlledChildren == 0) then
        self:DisableExpand();
      else
        self:EnableExpand();
      end
    end


    function self.callbacks.OnClickGrouping()
      if (WeakAuras.IsImporting()) then return end;
      for index, selectedId in ipairs(self.grouping) do
        local selectedData = WeakAuras.GetData(selectedId);
        tinsert(self.data.controlledChildren, selectedId);
        local selectedButton = OptionsPrivate.GetDisplayButton(selectedId);
        while selectedData.parent do
          selectedButton:Ungroup();
        end
        selectedButton:SetGroup(self.data.id, self.data.regionType == "dynamicgroup");
        selectedButton:SetGroupOrder(#self.data.controlledChildren, #self.data.controlledChildren);
        selectedData.parent = self.data.id;
        if (self.data.regionType == "dynamicgroup") then
          selectedData.xOffset = 0
          selectedData.yOffset = 0
        end
        WeakAuras.Add(selectedData);
        OptionsPrivate.ClearOptions(selectedId)

        if (selectedData.controlledChildren) then
          for child in OptionsPrivate.Private.TraverseAllChildren(selectedData) do
            local childButton = OptionsPrivate.GetDisplayButton(child.id)
            childButton:UpdateOffset()
          end
        end
      end

      WeakAuras.Add(self.data);
      OptionsPrivate.Private.AddParents(self.data)
      self.callbacks.UpdateExpandButton();
      self:UpdateParentWarning();
      OptionsPrivate.StopGrouping();
      OptionsPrivate.ClearOptions(self.data.id);
      WeakAuras.FillOptions();
      WeakAuras.UpdateGroupOrders(self.data);
      OptionsPrivate.SortDisplayButtons();
      self:ReloadTooltip();
      self:Expand()
      OptionsPrivate.ResetMoverSizer();
    end

    function self.callbacks.OnClickGroupingSelf()
      OptionsPrivate.StopGrouping();
      self:ReloadTooltip();
    end

    function self.callbacks.OnGroupClick()
      OptionsPrivate.StartGrouping(self.data);
    end

    local function addParents(hash, data)
      local parent = data.parent
      if parent then
        hash[parent] = true
        local parentData = WeakAuras.GetData(parent)
        if parentData then
          addParents(hash, parentData)
        end
      end
    end

    function self.callbacks.OnDeleteClick()
      if (WeakAuras.IsImporting()) then return end;
      local toDelete = {self.data}
      local parents = {}
      addParents(parents, self.data)
      OptionsPrivate.ConfirmDelete(toDelete, parents)
    end

    local function DuplicateGroups(sourceParent, targetParent, mapping)
      for index, childId in pairs(sourceParent.controlledChildren) do
        local childData = WeakAuras.GetData(childId)
        if childData.controlledChildren then
          local newChildGroup = OptionsPrivate.DuplicateAura(childData, targetParent.id)
          mapping[childData] = newChildGroup
          DuplicateGroups(childData, newChildGroup, mapping)
        end
      end
    end

    local function DuplicateAuras(sourceParent, targetParent, mapping)
      for index, childId in pairs(sourceParent.controlledChildren) do
        local childData = WeakAuras.GetData(childId)
        if childData.controlledChildren then
          DuplicateAuras(childData, mapping[childData], mapping)
        else
          OptionsPrivate.DuplicateAura(childData, targetParent.id, true, index)
        end
      end
    end

    function self.callbacks.OnDuplicateClick()
      if (WeakAuras.IsImporting()) then return end;
      if self.data.controlledChildren then
        local newGroup = OptionsPrivate.DuplicateAura(self.data)

        local mapping = {}
        -- This builds the group skeleton
        DuplicateGroups(self.data, newGroup, mapping)
        -- Do this after duplicating all groups
        local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
        -- And this fills in the leafs
        DuplicateAuras(self.data, newGroup, mapping)

        local button = OptionsPrivate.GetDisplayButton(newGroup.id)
        button.callbacks.UpdateExpandButton()
        button:UpdateParentWarning()

        for old, new in pairs(mapping) do
          local button = OptionsPrivate.GetDisplayButton(new.id)
          button.callbacks.UpdateExpandButton()
          button:UpdateParentWarning()
        end

        OptionsPrivate.SortDisplayButtons(nil, true)
        OptionsPrivate.PickAndEditDisplay(newGroup.id)

        OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
      else
        local new = OptionsPrivate.DuplicateAura(self.data)
        OptionsPrivate.SortDisplayButtons(nil, true)
        OptionsPrivate.PickAndEditDisplay(new.id)
      end
    end

    function self.callbacks.OnDeleteAllClick()
      if (WeakAuras.IsImporting()) then return end;
      local toDelete = {}
      if(self.data.controlledChildren) then
        for child in OptionsPrivate.Private.TraverseAllChildren(self.data) do
          tinsert(toDelete, child);
        end
      end
      tinsert(toDelete, self.data)
      local parents = {}
      addParents(parents, self.data)
      OptionsPrivate.ConfirmDelete(toDelete, parents);
    end

    function self.callbacks.OnUngroupClick()
      OptionsPrivate.Ungroup(self.data);
    end

    function self.callbacks.OnUpGroupClick()
      if (WeakAuras.IsImporting()) then return end;
      if(self.data.parent) then
        local id = self.data.id;
        local parentData = WeakAuras.GetData(self.data.parent);
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
            OptionsPrivate.Private.AddParents(parentData)
            WeakAuras.ClearAndUpdateOptions(parentData.id)
            self:SetGroupOrder(index - 1, #parentData.controlledChildren);
            local otherbutton = OptionsPrivate.GetDisplayButton(parentData.controlledChildren[index]);
            otherbutton:SetGroupOrder(index, #parentData.controlledChildren);
            OptionsPrivate.SortDisplayButtons();
            local updata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = -32};
            local downdata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = 32};
            OptionsPrivate.Private.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index-1]).uid, "main", updata, self.frame, true, function() OptionsPrivate.SortDisplayButtons() end);
            OptionsPrivate.Private.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index]).uid, "main", downdata, otherbutton.frame, true, function() OptionsPrivate.SortDisplayButtons() end);
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
      if(self.data.parent) then
        local id = self.data.id;
        local parentData = WeakAuras.GetData(self.data.parent);
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
            OptionsPrivate.Private.AddParents(parentData)
            WeakAuras.ClearAndUpdateOptions(parentData.id)
            self:SetGroupOrder(index + 1, #parentData.controlledChildren);
            local otherbutton = OptionsPrivate.GetDisplayButton(parentData.controlledChildren[index]);
            otherbutton:SetGroupOrder(index, #parentData.controlledChildren);
            OptionsPrivate.SortDisplayButtons()
            local updata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = -32};
            local downdata = {duration = 0.15, type = "custom", use_translate = true, x = 0, y = 32};
            OptionsPrivate.Private.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index+1]).uid, "main", downdata, self.frame, true, function() OptionsPrivate.SortDisplayButtons() end);
            OptionsPrivate.Private.Animate("button", WeakAuras.GetData(parentData.controlledChildren[index]).uid, "main", updata, otherbutton.frame, true, function() OptionsPrivate.SortDisplayButtons() end);
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
      local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
      if(self.view.visibility == 2) then
        for child in OptionsPrivate.Private.TraverseAllChildren(self.data) do
          OptionsPrivate.GetDisplayButton(child.id):PriorityHide(2);
        end
        self:PriorityHide(2)
      else
        for child in OptionsPrivate.Private.TraverseAllChildren(self.data) do
          OptionsPrivate.GetDisplayButton(child.id):PriorityShow(2);
        end
        self:PriorityShow(2)
      end
      self:RecheckParentVisibility()
      OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
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
      local oldid = self.data.id;
      if not(newid == oldid) then
        WeakAuras.Rename(self.data, newid);
      end
      self:UpdateParentWarning()
    end

    function self.callbacks.OnDragStart()
      if WeakAuras.IsImporting() then return end;
      if not OptionsPrivate.IsDisplayPicked(self.data.id) then
        WeakAuras.PickDisplay(self.data.id)
      end
      OptionsPrivate.StartDrag(self.data);
    end

    function self.callbacks.OnDragStop()
      if not self.dragging then return end
      local target, area = select(2, GetDropTarget())
      local action = GetAction(target, area)
      OptionsPrivate.Drop(self.data, target, action, area)
    end

    function self.callbacks.OnKeyDown(self, key)
      if (key == "ESCAPE") then
        OptionsPrivate.DragReset()
      end
    end

    self.frame:SetScript("OnEnter", function()
      if(OptionsPrivate.IsPickedMultiple() and OptionsPrivate.IsDisplayPicked(self.frame.id)) then
        Show_Long_Tooltip(self.frame, OptionsPrivate.MultipleDisplayTooltipDesc());
      else
        if not self.grouping then
          self:SetNormalTooltip();
        end
        Show_Long_Tooltip(self.frame, self.frame.description);
      end
    end);
    self.frame:SetScript("OnLeave", Hide_Tooltip);

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

    self:SetTitle(self.data.id);
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

    if (not self.data.controlledChildren) then
      local convertMenu = {};
      for regionType, regionData in pairs(OptionsPrivate.Private.regionOptions) do
        if(regionType ~= "group" and regionType ~= "dynamicgroup" and regionType ~= self.data.regionType) then
          tinsert(convertMenu, {
            text = regionData.displayName,
            notCheckable = true,
            func = function()
              OptionsPrivate.ConvertDisplay(self.data, regionType);
              LibDD:CloseDropDownMenus()
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
      text = L["Export..."],
      notCheckable = true,
      func = function() OptionsPrivate.ExportToString(self.data.id) end
    });
    tinsert(self.menu, {
      text = L["Export debug table..."],
      notCheckable = true,
      func = function() OptionsPrivate.ExportToTable(self.data.id) end
    });

    tinsert(self.menu, {
      text = " ",
      notClickable = true,
      notCheckable = true,
    });
    if not self.data.controlledChildren then
      tinsert(self.menu, {
        text = L["Delete"],
        notCheckable = true,
        func = self.callbacks.OnDeleteClick
      });
    end

    if (self.data.controlledChildren) then
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
      func = function() LibDD:CloseDropDownMenus() end
    });
    if(self.data.controlledChildren) then
      self.expand:Show();
      self.callbacks.UpdateExpandButton();
      self:SetOnExpandCollapse(function() OptionsPrivate.SortDisplayButtons(nil, true) end);
    else
      self.expand:Hide();
    end
    self.group:Show();

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
    self.view:SetScript("OnClick", self.callbacks.OnViewClick);

    if self.data.parent then
      local parentData = WeakAuras.GetData(self.data.parent);
      local index;
      for childIndex, childId in pairs(parentData.controlledChildren) do
        if(childId == self.data.id) then
          index = childIndex;
          break;
        end
      end
      if(index) then
        self:SetGroup(self.data.parent);
        self:SetGroupOrder(index, #parentData.controlledChildren);
      else
        error("Display \""..self.data.id.."\" thinks it is a member of group \""..self.data.parent.."\" which does not control it");
      end
    end

    self.frame:Hide()
  end,
  ["SetNormalTooltip"] = function(self)
    local data = self.data;
    local namestable = {};
    if(data.controlledChildren) then
      namestable[1] = "";
      local function addChildrenNames(data, indent)
        for index, childId in pairs(data.controlledChildren) do
          tinsert(namestable, indent .. childId);
          local childData = WeakAuras.GetData(childId)
          if not childData then
            return
          end
          if (childData.controlledChildren) then
            addChildrenNames(childData, indent .. "  ")
          end
        end
      end
      addChildrenNames(data, "  ")

      if (#namestable > 30) then
        local size = #namestable;
        namestable[26] = {" ", "[...]"};
        namestable[27] = {L[string.format(L["%s total auras"], #namestable)], " " }
        for i = 28, size do
          namestable[i] = nil;
        end
      end

      if(#namestable > 1) then
        namestable[1] = L["Children:"];
      else
        namestable[1] = L["No Children"];
      end
    else
      OptionsPrivate.Private.GetTriggerDescription(data, -1, namestable)
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
    tinsert(namestable, {" ", "|cFF00FFFF"..L["Drag to move"]});
    if not(data.controlledChildren) then
      tinsert(namestable, {" ", "|cFF00FFFF"..L["Control-click to select multiple displays"]});
    end
    tinsert(namestable, {" ", "|cFF00FFFF"..L["Shift-click to create chat link"]});
    local regionData = OptionsPrivate.Private.regionOptions[data.regionType or ""]
    local displayName = regionData and regionData.displayName or "";
    self:SetDescription({data.id, displayName}, unpack(namestable));
  end,
  ["ReloadTooltip"] = function(self)
    if(OptionsPrivate.IsPickedMultiple() and OptionsPrivate.IsDisplayPicked(self.data.id)) then
      Show_Long_Tooltip(self.frame, OptionsPrivate.MultipleDisplayTooltipDesc());
    else
      Show_Long_Tooltip(self.frame, self.frame.description);
    end
  end,
  ["StartGrouping"] = function(self, groupingData, selected, groupingGroup, childOfGrouping)
    self.grouping = groupingData;
    self:UpdateIconsVisible()
    if(selected) then
      self.frame:SetScript("OnClick", self.callbacks.OnClickGroupingSelf);
      self:SetDescription(L["Cancel"], L["Do not group this display"]);
    elseif (childOfGrouping) then
      self:Disable();
    else
      if(self.data.regionType == "dynamicgroup" and groupingGroup) then
        self:Disable();
      elseif (self.data.regionType == "group" or self.data.regionType == "dynamicgroup") then
        self.frame:SetScript("OnClick", self.callbacks.OnClickGrouping);
        self:SetDescription(self.data.id, L["Add to group %s"]:format(self.data.id));
      else
        self:Disable();
      end
    end
  end,
  ["StopGrouping"] = function(self)
    if self.grouping then
      self.grouping = nil
      self:UpdateIconsVisible()
      self:SetNormalTooltip()
      self.frame:SetScript("OnClick", self.callbacks.OnClickNormal)
      self:Enable()
    end
  end,
  ["Ungroup"] = function(self)
    if (WeakAuras.IsImporting()) then return end;
    local parentData = WeakAuras.GetData(self.data.parent);
    if not parentData then return end;
    local index = tIndexOf(parentData.controlledChildren, self.data.id);
    if(index) then
      tremove(parentData.controlledChildren, index);
      WeakAuras.Add(parentData);
      OptionsPrivate.Private.AddParents(parentData)
      WeakAuras.ClearAndUpdateOptions(parentData.id);
    else
      error("Display thinks it is a member of a group which does not control it");
    end

    local newParent = parentData.parent and WeakAuras.GetData(parentData.parent)
    if newParent then
      local insertIndex = tIndexOf(newParent.controlledChildren, parentData.id)
      if not insertIndex then
        error("Parent Display thinks it is a member of a group which does not control it");
      end
      insertIndex = insertIndex + 1
      tinsert(newParent.controlledChildren, insertIndex, self.data.id)
    end

    self:SetGroup(newParent and newParent.id);
    self.data.parent = newParent and newParent.id;
    WeakAuras.Add(self.data);
    self:UpdateIconsVisible()
    if newParent then
      WeakAuras.Add(newParent)
      OptionsPrivate.Private.AddParents(newParent)
      WeakAuras.ClearAndUpdateOptions(newParent.id)
      WeakAuras.UpdateGroupOrders(newParent)
    end
    WeakAuras.ClearAndUpdateOptions(self.data.id);
    WeakAuras.UpdateGroupOrders(parentData);
    local parentButton = OptionsPrivate.GetDisplayButton(parentData.id)
    if(#parentData.controlledChildren == 0) then
      parentButton:DisableExpand()
    end
    parentButton:UpdateParentWarning()

    for child in OptionsPrivate.Private.TraverseAllChildren(self.data) do
      local button = OptionsPrivate.GetDisplayButton(child.id)
      button:UpdateOffset()
    end

    OptionsPrivate.SortDisplayButtons();
  end,
  ["UpdateIconsVisible"] = function(self)
    if self.dragging or self.grouping then
      self.downgroup:Hide()
      self.group:Hide()
      self.ungroup:Hide()
      self.upgroup:Hide()
    else
      self.group:Show()
      if self.data.parent then
        self.downgroup:Show()
        self.ungroup:Show()
        self.upgroup:Show()
      else
        self.downgroup:Hide()
        self.ungroup:Hide()
        self.upgroup:Hide()
      end
    end
  end,
  ["DragStart"] = function(self, mode, picked, mainAura, size)
    self.frame:SetScript("OnClick", nil)
    self.view:Hide()
    self.expand:Hide()
    self.statusIcons:Hide()
    Hide_Tooltip()
    if picked then
      self.frame:EnableKeyboard(true)
      local uiscale, scale = UIParent:GetScale(), self.frame:GetEffectiveScale()
      local x, w = self.frame:GetLeft(), self.frame:GetWidth()
      local _, y = GetCursorPosition()
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
      if self.data.id == mainAura.id then
        self.frame:SetPoint("Center", UIParent, "BOTTOMLEFT", (x+w/2)*scale/uiscale, y/uiscale)
        if mode == "MULTI" then
          -- change label & icon
          self.frame:SetPoint("Center", UIParent, "BOTTOMLEFT", (x+w/2)*scale/uiscale, y/uiscale)
          self.frame.temp.title = self.title:GetText()
          self.title:SetText((L["%i auras selected"]):format(size))
          self:OverrideIcon();
        end
      else
        -- Hide frames
        self.frame:StopMovingOrSizing()
        self.frame:Hide()
      end
      -- attach OnUpdate event to update drop indicator
      if self.data.id == mainAura.id then
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
      self:UpdateIconsVisible()
    else
      -- Are we a valid target?
      -- Top level auras that aren't groups aren't
      if not self.data.parent and not self:IsGroup() then
        self:Disable()
      end

      -- If we are dragging a group, dynamic groups aren't valid targets
      if mode == "GROUP" then
        if self.data.regionType == "dynamicgroup" then
          self:Disable()
        else
          local parentData = self.data.parent and WeakAuras.GetData(self.data.parent)
          if (parentData and parentData.regionType == "dynamicgroup") then
            self:Disable()
          end
        end
      end
    end
  end,
  ["Drop"] = function(self, mode, mainAura, target, func)
    if mode == "MULTI" or mode == "SINGLE" then
      if self.dragging then
        if func and target then
          func(self, target)
        end
      end
    elseif mode == "GROUP" then
      if mainAura.id == self.data.id then
        if func and target then
          func(self, target)
        end
      end
    end
    self:DropEnd()
  end,
  ["IsDragging"] = function(self)
    return self.dragging
  end,
  ["DragReset"] = function(self)
    self:DropEnd()
  end,
  ["DropEnd"] = function(self)
    Show_DropIndicator()

    self.frame:SetScript("OnClick", self.callbacks.OnClickNormal)
    self.frame:EnableKeyboard(false); -- disables self.callbacks.OnKeyDown
    self.view:Show()
    self.statusIcons:Show()
    if self.data.controlledChildren then
      self.expand:Show()
    end
    self:Enable()

    -- get action and execute it
    self.frame:StopMovingOrSizing()
    self.frame:SetScript("OnUpdate", nil)
    if self.dragging then
      if self.frame.temp.title then
        -- restore title and icon
        self.title:SetText(self.frame.temp.title)
        self:RestoreIcon();
      end
      self.frame:SetParent(self.frame.temp.parent)
      self.frame:SetFrameStrata(self.frame.temp.strata)
      self.frame.temp = nil
    end
    self.dragging = false
    self:UpdateIconsVisible()
  end,
  ["ShowTooltip"] = function(self)
  end,
  ["UpdateOffset"] = function(self)
    local group = self.frame.dgroup
    if group then
      local depth = 0
      while(group) do
        depth = depth + 1
        group = WeakAuras.GetData(group).parent
      end
      self.offset:SetWidth(depth * 8 + 1)
    else
      self.offset:SetWidth(1)
    end
  end,
  ["GetOffset"] = function(self)
    return self.offset:GetWidth()
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
  ["SetRenameAction"] = function(self, func)
    self.renamebox.func = function()
      func(self.renamebox:GetText());
    end
  end,
  ["EnableGroup"] = function(self)

  end,
  ["SetIds"] = function(self, ids)
    self.renamebox.ids = ids;
  end,
  ["SetGroup"] = function(self, group)
    self.frame.dgroup = group;
    if(group) then
      self.icon:SetPoint("LEFT", self.ungroup, "RIGHT");
      self.background:SetPoint("LEFT", self.offset, "RIGHT");
    else
      self.icon:SetPoint("LEFT", self.frame, "LEFT");
      self.background:SetPoint("LEFT", self.frame, "LEFT");
    end
    self:UpdateIconsVisible()
    self:UpdateOffset()
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
    OptionsPrivate.SetCollapsed(self.data.id, "displayButton", "", false)
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
    OptionsPrivate.SetCollapsed(self.data.id, "displayButton", "", true)
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
    return not OptionsPrivate.IsCollapsed(self.data.id, "displayButton", "", true)
  end,
  ["DisableExpand"] = function(self)
    if self.expand.disabled then
      return
    end
    self.expand:Disable();
    self.expand.disabled = true;
    self.expand.expanded = false;
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Disabled.blp");
  end,
  ["EnableExpand"] = function(self)
    if not self.expand.disabled then
      return
    end
    self.expand.disabled = false;
    if(self:GetExpanded()) then
      self:Expand();
    else
      self:Collapse();
    end
  end,
  ["UpdateStatusIcon"] = function(self, key, prio, icon, title, tooltip, onClick, color)
    local iconButton
    for _, button in ipairs(self.statusIcons.buttons) do
      if button.key == key then
        iconButton = button
        break
      end
    end
    if not iconButton then
      iconButton = statusIconPool:Acquire()
      tinsert(self.statusIcons.buttons, iconButton)
      iconButton:SetParent(self.statusIcons)
      iconButton.key = key
      iconButton:SetSize(16, 16)
    end
    iconButton.prio = prio
    if C_Texture.GetAtlasInfo(icon) then
      iconButton:SetNormalAtlas(icon)
    else
      iconButton:SetNormalTexture(icon)
    end
    if title then
      iconButton:SetScript("OnEnter", function()
        Show_Tooltip(
          self.frame,
          title,
          tooltip
        )
      end)
      iconButton:SetScript("OnLeave", Hide_Tooltip)
    else
      iconButton:SetScript("OnEnter", nil)
    end
    if color then
      iconButton:GetNormalTexture():SetVertexColor(unpack(color))
    else
      iconButton:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
    end
    iconButton:SetScript("OnClick", onClick)
    iconButton:Show()
  end,
  ["ClearStatusIcon"] = function(self, key)
    for index, button in ipairs(self.statusIcons.buttons) do
      if button.key == key then
        statusIconPool:Release(button)
        table.remove(self.statusIcons.buttons, index)
        return
      end
    end
  end,
  ["SortStatusIcons"] = function(self)
    table.sort(self.statusIcons.buttons, function(a, b)
      return a.prio < b.prio
    end)
    local lastAnchor = self.statusIcons
    if self:IsGroup() then
      self.statusIcons:SetWidth(17)
    else
      self.statusIcons:SetWidth(1)
    end
    for _, button in ipairs(self.statusIcons.buttons) do
      button:ClearAllPoints()
      button:SetPoint("BOTTOMLEFT", lastAnchor, "BOTTOMRIGHT", 4, 0)
      lastAnchor = button
    end
  end,
  ["UpdateWarning"] = function(self)
    local warnings = OptionsPrivate.Private.AuraWarnings.GetAllWarnings(self.data.uid)
    local warningTypes = {"info", "sound", "tts", "warning", "error"}
    for _, key in ipairs(warningTypes) do
      self:ClearStatusIcon(key)
    end
    if warnings then
      for severity, warning in pairs(warnings) do
        local onClick = function()
          WeakAuras.PickDisplay(warning.auraId, warning.tab)
        end
        self:UpdateStatusIcon(severity, warning.prio, warning.icon, warning.title, warning.message, onClick)
      end
    end
    self:SortStatusIcons()
  end,
  ["UpdateParentWarning"] = function(self)
    self:UpdateWarning()
    for parent in OptionsPrivate.Private.TraverseParents(self.data) do
      local parentButton = OptionsPrivate.GetDisplayButton(parent.id)
      if parentButton then
        parentButton:UpdateWarning()
      end
    end
  end,
  ["SetGroupOrder"] = function(self, order, max)
    self.first = (order == 1)
    self.last = (order == max)
    self.frame.dgrouporder = order;
    self:UpdateUpDownButtons()
  end,
  ["UpdateUpDownButtons"] = function(self)
    if self.first or not self:IsEnabled() then
      self.upgroup:Disable();
      self.upgroup.texture:SetVertexColor(0.3, 0.3, 0.3);
    else
      self.upgroup:Enable();
      self.upgroup.texture:SetVertexColor(1, 1, 1);
    end

    if self.last or not self:IsEnabled() then
      self.downgroup:Disable();
      self.downgroup.texture:SetVertexColor(0.3, 0.3, 0.3);
    else
      self.downgroup:Enable();
      self.downgroup.texture:SetVertexColor(1, 1, 1);
    end
  end,
  ["GetGroupOrder"] = function(self)
    return self.frame.dgrouporder;
  end,
  ["ClearLoaded"] = function(self)
    self:ClearStatusIcon("load")
    self:SortStatusIcons()
  end,
  ["SetLoaded"] = function(self, prio, color, title, description)
    self:UpdateStatusIcon("load", prio, "Interface\\AddOns\\WeakAuras\\Media\\Textures\\loaded", title, description, nil, color)
    self:SortStatusIcons()
  end,
  ["IsLoaded"] = function(self)
    return OptionsPrivate.Private.loaded[self.data.id] == true
  end,
  ["IsStandby"] = function(self)
    return OptionsPrivate.Private.loaded[self.data.id] == false
  end,
  ["IsUnloaded"] = function(self)
    return OptionsPrivate.Private.loaded[self.data.id] == nil
  end,
  ["Pick"] = function(self)
    self.frame:LockHighlight();
    self:PriorityShow(1);
    self:RecheckParentVisibility()
  end,
  ["ClearPick"] = function(self, noHide)
    self.frame:UnlockHighlight();
    if not noHide then
      self:PriorityHide(1);
      self:RecheckParentVisibility()
    end
  end,
  ["SyncVisibility"] = function(self)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if self.view.visibility >= 1 then
      if not OptionsPrivate.Private.IsGroupType(self.data) then
        OptionsPrivate.Private.FakeStatesFor(self.data.id, true)
      end
      if (OptionsPrivate.Private.personalRessourceDisplayFrame) then
        OptionsPrivate.Private.personalRessourceDisplayFrame:expand(self.data.id);
      end
      if (OptionsPrivate.Private.mouseFrame) then
        OptionsPrivate.Private.mouseFrame:expand(self.data.id);
      end
    else
      if not OptionsPrivate.Private.IsGroupType(self.data) then
        OptionsPrivate.Private.FakeStatesFor(self.data.id, false)
      end
      if (OptionsPrivate.Private.personalRessourceDisplayFrame) then
        OptionsPrivate.Private.personalRessourceDisplayFrame:collapse(self.data.id);
      end
      if (OptionsPrivate.Private.mouseFrame) then
        OptionsPrivate.Private.mouseFrame:collapse(self.data.id);
      end
    end
  end,
  ["PriorityShow"] = function(self, priority)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.view.visibility and self.view.visibility ~= priority) then
      self.view.visibility = priority;
      self:SyncVisibility()
      self:UpdateViewTexture()
    end
    local region = OptionsPrivate.Private.EnsureRegion(self.data.id)
    if region and region.ClickToPick then
      region:ClickToPick();
    end
  end,
  ["PriorityHide"] = function(self, priority)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.view.visibility and self.view.visibility ~= 0) then
      self.view.visibility = 0;
      self:SyncVisibility()
      self:UpdateViewTexture()
    end
  end,
  ["RecheckParentVisibility"] = function(self)
    if self.data.parent then
      local parentButton = OptionsPrivate.GetDisplayButton(self.data.parent)
      parentButton:RecheckVisibility()
    else
      OptionsPrivate.Private.OptionsFrame().loadedButton:RecheckVisibility()
      OptionsPrivate.Private.OptionsFrame().unloadedButton:RecheckVisibility()
    end
  end,
  ["RecheckVisibility"] = function(self)
    local none, all = true, true;
    for child in OptionsPrivate.Private.TraverseAllChildren(self.data) do
      local childButton = OptionsPrivate.GetDisplayButton(child.id);
      if(childButton) then
        if(childButton:GetVisibility() ~= 2) then
          all = false;
        end
        if(childButton:GetVisibility() ~= 0) then
          none = false;
        end
      end
    end
    local newVisibility
    if(all) then
      newVisibility = 2;
    elseif(none) then
      newVisibility = 0;
    else
      newVisibility = 1;
    end
    if newVisibility ~= self.view.visibility then
      self.view.visibility = newVisibility
      self:UpdateViewTexture()

      self:RecheckParentVisibility()
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
  ["GetVisibility"] = function(self)
    return self.view.visibility;
  end,
  ["Disable"] = function(self)
    self.background:Hide();
    self.frame:Disable();
    self.view:Disable();
    self.group:Disable();
    self.ungroup:Disable();
    self.expand:Disable();
    for _, button in ipairs(self.statusIcons.buttons) do
      button:Disable();
    end
    self:UpdateUpDownButtons()
  end,
  ["Enable"] = function(self)
    self.background:Show();
    self.frame:Enable();
    self.view:Enable();
    self.group:Enable();
    self.ungroup:Enable();
    for _, button in ipairs(self.statusIcons.buttons) do
      button:Enable();
    end
    self:UpdateUpDownButtons()
    if not(self.expand.disabled) then
      self.expand:Enable();
    end
  end,
  ["IsEnabled"] = function(self)
    return self.frame:IsEnabled();
  end,
  ["OnRelease"] = function(self)
    self:ReleaseThumbnail()
    self:Enable();
    self:SetGroup();
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
    for _, button in ipairs(self.statusIcons.buttons) do
      statusIconPool:Release(button)
    end
    wipe(self.statusIcons.buttons)
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
      local option = OptionsPrivate.Private.regionOptions[self.thumbnailType]
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
      local option = OptionsPrivate.Private.regionOptions[regionType]
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

    local option = OptionsPrivate.Private.regionOptions[regionType]
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
  ---@class Button
  local button = CreateFrame("Button", name, UIParent, "OptionsListButtonTemplate");
  button:SetHeight(32);
  button:SetWidth(1000);
  button.dgroup = nil;
  button.data = {};

  local offset = CreateFrame("Frame", nil, button)
  button.offset = offset
  offset:SetPoint("TOP", button, "TOP");
  offset:SetPoint("BOTTOM", button, "BOTTOM");
  offset:SetPoint("LEFT", button, "LEFT");
  offset:SetWidth(1)

  local background = button:CreateTexture(nil, "BACKGROUND");
  button.background = background;
  background:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
  background:SetBlendMode("ADD");
  background:SetVertexColor(0.5, 0.5, 0.5, 0.25);
  background:SetPoint("TOP", button, "TOP");
  background:SetPoint("BOTTOM", button, "BOTTOM");
  background:SetPoint("LEFT", button, "LEFT")
  background:SetPoint("RIGHT", button, "RIGHT");

  local icon = button:CreateTexture(nil, "OVERLAY");
  button.icon = icon;
  icon:SetWidth(32);
  icon:SetHeight(32);
  icon:SetPoint("LEFT", offset, "RIGHT");

  local title = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  button.title = title;
  title:SetHeight(14);
  title:SetJustifyH("LEFT");
  title:SetPoint("TOP", button, "TOP", 0, -2);
  title:SetPoint("LEFT", icon, "RIGHT", 2, 0);
  title:SetPoint("RIGHT", button, "RIGHT");

  button.description = {};

  ---@class Button
  local view = CreateFrame("Button", nil, button);
  button.view = view;
  view:SetWidth(16);
  view:SetHeight(16);
  view:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0);
  local viewTexture = view:CreateTexture()
  view.texture = viewTexture;
  viewTexture:SetTexture("Interface\\LFGFrame\\BattlenetWorking4.blp");
  viewTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9);
  viewTexture:SetAllPoints(view);
  view:SetNormalTexture(viewTexture);
  view:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  view:SetScript("OnEnter", function() Show_Tooltip(button, L["View"], L["Toggle the visibility of this display"]) end);
  view:SetScript("OnLeave", Hide_Tooltip);

  view.visibility = 0;

  local renamebox = CreateFrame("EditBox", nil, button, "InputBoxTemplate");
  renamebox:SetHeight(14);
  renamebox:SetPoint("TOP", button, "TOP");
  renamebox:SetPoint("LEFT", icon, "RIGHT", 6, 0);
  renamebox:SetPoint("RIGHT", button, "RIGHT", -4, 0);
  renamebox:SetFont(STANDARD_TEXT_FONT, 10, "");
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

  local group = CreateFrame("Button", nil, button);
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

  local ungroup = CreateFrame("Button", nil, button);
  button.ungroup = ungroup;
  ungroup:SetWidth(11);
  ungroup:SetHeight(11);
  ungroup:SetPoint("LEFT", offset, "RIGHT", 0, 0);
  local ungrouptexture = group:CreateTexture(nil, "OVERLAY");
  ungrouptexture:SetTexture("Interface\\MoneyFrame\\Arrow-Left-Down.blp");
  ungrouptexture:SetTexCoord(0.5, 0, 0.5, 1, 1, 0, 1, 1);
  ungrouptexture:SetAllPoints(ungroup);
  ungroup:SetNormalTexture(ungrouptexture);
  ungroup:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  ungroup:SetScript("OnEnter", function() Show_Tooltip(button, L["Ungroup"], L["Remove this display from its group"]) end);
  ungroup:SetScript("OnLeave", Hide_Tooltip);
  ungroup:Hide();

  local upgroup = CreateFrame("Button", nil, button);
  button.upgroup = upgroup;
  upgroup:SetWidth(11);
  upgroup:SetHeight(11);
  upgroup:SetPoint("TOPLEFT", offset, "TOPRIGHT", 0, 0);
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

  local downgroup = CreateFrame("Button", nil, button);
  button.downgroup = downgroup;
  downgroup:SetWidth(11);
  downgroup:SetHeight(11);
  downgroup:SetPoint("BOTTOMLEFT", offset, "BOTTOMRIGHT", 0, 0);
  local downgrouptexture = group:CreateTexture(nil, "OVERLAY");
  downgroup.texture = downgrouptexture;
  downgrouptexture:SetTexture("Interface\\MoneyFrame\\Arrow-Left-Down.blp");
  downgrouptexture:SetTexCoord(1, 0, 0.5, 0, 1, 1, 0.5, 1);
  downgrouptexture:SetAllPoints(downgroup);
  downgroup:SetNormalTexture(downgrouptexture);
  downgroup:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight.blp");
  downgroup:SetScript("OnEnter", function()
    Show_Tooltip(button, L["Move Down"], L["Move this display down in its group's order"])
  end)
  downgroup:SetScript("OnLeave", Hide_Tooltip);
  downgroup:Hide();

  ---@class Button
  local expand = CreateFrame("Button", nil, button);
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

  local statusIcons = CreateFrame("Frame", nil, button);
  button.statusIcons = statusIcons
  statusIcons:SetPoint("BOTTOM", button, "BOTTOM", 0, 1);
  statusIcons:SetPoint("LEFT", icon, "RIGHT");
  statusIcons:SetSize(1,1)
  statusIcons.buttons = {}

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
    background = background,
    expand = expand,
    statusIcons = statusIcons,
    type = Type,
    offset = offset
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
