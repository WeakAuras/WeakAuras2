if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

-- Lua APIs
local tinsert, tremove, wipe = table.insert, table.remove, wipe
local pairs, type = pairs, type
local error = error
local coroutine = coroutine
local _G = _G

-- WoW APIs
local InCombatLockdown = InCombatLockdown
local CreateFrame = CreateFrame

local AceGUI = LibStub("AceGUI-3.0")

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L
local ADDON_NAME = "WeakAurasOptions";

local displayButtons = {};
OptionsPrivate.displayButtons = displayButtons;

local spellCache = WeakAuras.spellCache;
local savedVars = {};
OptionsPrivate.savedVars = savedVars;

OptionsPrivate.expanderAnchors = {}
OptionsPrivate.expanderButtons = {}

local collapsedOptions = {}
local collapsed = {} -- magic value

local tempGroup = {
  id = {"tempGroup"},
  regionType = "group",
  controlledChildren = {},
  load = {},
  triggers = {{}},
  config = {},
  authorOptions = {},
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0
};
OptionsPrivate.tempGroup = tempGroup;

-- Does not duplicate child auras.
function OptionsPrivate.DuplicateAura(data, newParent, massEdit, targetIndex)
  local base_id = data.id .. " "
  local num = 2

  -- if the old id ends with a number increment the number
  local matchName, matchNumber = string.match(data.id, "^(.-)(%d*)$")
  matchNumber = tonumber(matchNumber)
  if (matchName ~= "" and matchNumber ~= nil) then
    base_id = matchName
    num = matchNumber + 1
  end

  local new_id = base_id .. num
  while(WeakAuras.GetData(new_id)) do
    new_id = base_id .. num
    num = num + 1
  end

  local newData = CopyTable(data)
  newData.id = new_id
  newData.parent = nil
  newData.uid = WeakAuras.GenerateUniqueID()
  if newData.controlledChildren then
    newData.controlledChildren = {}
  end
  WeakAuras.Add(newData)
  WeakAuras.NewDisplayButton(newData, massEdit)
  if(newParent or data.parent) then
    local parentId = newParent or data.parent
    local parentData = WeakAuras.GetData(parentId)
    local index
    if targetIndex then
      index = targetIndex
    elseif newParent then
      index = #parentData.controlledChildren + 1
    else
      index = tIndexOf(parentData.controlledChildren, data.id) + 1
    end
    if(index) then
      tinsert(parentData.controlledChildren, index, newData.id)
      newData.parent = parentId
      WeakAuras.Add(newData)
      WeakAuras.Add(parentData)
      OptionsPrivate.Private.AddParents(parentData)

      for index, id in pairs(parentData.controlledChildren) do
        local childButton = OptionsPrivate.GetDisplayButton(id)
        childButton:SetGroup(parentData.id, parentData.regionType == "dynamicgroup")
        childButton:SetGroupOrder(index, #parentData.controlledChildren)
      end

      if not massEdit then
        local button = OptionsPrivate.GetDisplayButton(parentData.id)
        button.callbacks.UpdateExpandButton()
        button:UpdateParentWarning()
      end
      OptionsPrivate.ClearOptions(parentData.id)
    end
  end
  return newData
end

AceGUI:RegisterLayout("AbsoluteList", function(content, children)
  local yOffset = 0;
  for i = 1, #children do
    local child = children[i]

    local frame = child.frame;
    frame:ClearAllPoints();
    frame:Show();

    frame:SetPoint("LEFT", content);
    frame:SetPoint("RIGHT", content);
    frame:SetPoint("TOP", content, "TOP", 0, yOffset)

    if child.DoLayout then
      child:DoLayout()
    end

    yOffset = yOffset - ((frame.height or frame:GetHeight() or 0) + 2);
  end
  if(content.obj.LayoutFinished) then
    content.obj:LayoutFinished(nil, yOffset * -1);
  end
end);

AceGUI:RegisterLayout("ButtonsScrollLayout", function(content, children, skipLayoutFinished)
  local yOffset = 0
  local scrollTop, scrollBottom = content.obj:GetScrollPos()
  for i = 1, #children do
    local child = children[i]
    local frame = child.frame;

    if not child.dragging then
      local frameHeight = (frame.height or frame:GetHeight() or 0);
      frame:ClearAllPoints();
      if (-yOffset + frameHeight > scrollTop and -yOffset - frameHeight < scrollBottom) then
        frame:Show();
        frame:SetPoint("LEFT", content);
        frame:SetPoint("RIGHT", content);
        frame:SetPoint("TOP", content, "TOP", 0, yOffset)
      else
        frame:Hide();
        frame.yOffset = yOffset
      end
      yOffset = yOffset - (frameHeight + 2);
    end

    if child.DoLayout then
      child:DoLayout()
    end

  end
  if(content.obj.LayoutFinished and not skipLayoutFinished) then
    content.obj:LayoutFinished(nil, yOffset * -1)
  end
end)

function OptionsPrivate.MultipleDisplayTooltipDesc()
  local desc = {{L["Multiple Displays"], L["Temporary Group"]}};
  for index, id in pairs(tempGroup.controlledChildren) do
    desc[index + 1] = {" ", id};
  end
  desc[2][1] = L["Children:"]
  tinsert(desc, " ");
  tinsert(desc, {" ", "|cFF00FFFF"..L["Right-click for more options"]});
  tinsert(desc, {" ", "|cFF00FFFF"..L["Drag to move"]});
  return desc;
end

local frame;
local db;
local odb;
--- @type boolean?
local reopenAfterCombat = false;
local loadedFrame = CreateFrame("Frame");
loadedFrame:RegisterEvent("ADDON_LOADED");
loadedFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
loadedFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
loadedFrame:SetScript("OnEvent", function(self, event, addon)
  if (event == "ADDON_LOADED") then
    if(addon == ADDON_NAME) then
      db = WeakAurasSaved;
      WeakAurasOptionsSaved = WeakAurasOptionsSaved or {};

      odb = WeakAurasOptionsSaved;

      -- Remove icon and id cache (replaced with spellCache)
      if (odb.iconCache) then
        odb.iconCache = nil;
      end
      if (odb.idCache) then
        odb.idCache = nil;
      end
      odb.spellCache = odb.spellCache or {};
      spellCache.Load(odb);

      if odb.magnetAlign == nil then
        odb.magnetAlign = true
      end

      if db.import_disabled then
        db.import_disabled = nil
      end

      savedVars.db = db;
      savedVars.odb = odb;
    end
  elseif (event == "PLAYER_REGEN_DISABLED") then
    if(frame and frame:IsVisible()) then
      reopenAfterCombat = true;
      WeakAuras.HideOptions();
    end
  elseif (event == "PLAYER_REGEN_ENABLED") then
    if (reopenAfterCombat) then
      reopenAfterCombat = nil;
      WeakAuras.ShowOptions()
    end
  end
end);

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

local function commonParent(controlledChildren)
  local allSame = true
  local parent = nil
  local targetIndex = math.huge
  for index, id in ipairs(controlledChildren) do
    local childData = WeakAuras.GetData(id);
    local childButton = OptionsPrivate.GetDisplayButton(id)
    targetIndex = min(targetIndex, childButton:GetGroupOrder() or math.huge)

    if (parent == nil) then
      parent = childData.parent
    elseif not childData.parent then
      allSame = false
    elseif childData.parent ~= parent then
      allSame = false
    end
  end
  if allSame then
    return parent, targetIndex
  end
end

local function CreateNewGroupFromSelection(regionType, resetChildPositions)
  local data = {
    id = OptionsPrivate.Private.FindUnusedId(tempGroup.controlledChildren[1].." Group"),
    regionType = regionType,
  };

  WeakAuras.DeepMixin(data, OptionsPrivate.Private.data_stub)
  data.internalVersion = WeakAuras.InternalVersion()
  OptionsPrivate.Private.validate(data, OptionsPrivate.Private.regionTypes[regionType].default);

  local parent, targetIndex = commonParent(tempGroup.controlledChildren)

  if (parent) then
    local parentData = WeakAuras.GetData(parent)
    tinsert(parentData.controlledChildren, targetIndex, data.id)
    data.parent = parent
    WeakAuras.Add(data);
    WeakAuras.Add(parentData);
    OptionsPrivate.Private.AddParents(parentData)
    WeakAuras.NewDisplayButton(data);
    WeakAuras.UpdateGroupOrders(parentData);
    OptionsPrivate.ClearOptions(parentData.id);

    local parentButton = OptionsPrivate.GetDisplayButton(parent)
    parentButton.callbacks.UpdateExpandButton();
    parentButton:Expand();
    parentButton:ReloadTooltip();
    parentButton:UpdateParentWarning();
  else
    WeakAuras.Add(data);
    WeakAuras.NewDisplayButton(data);
  end

  for index, childId in pairs(tempGroup.controlledChildren) do
    local childData = WeakAuras.GetData(childId);
    local childButton = OptionsPrivate.GetDisplayButton(childId)
    local oldParent = childData.parent
    local oldParentData = WeakAuras.GetData(oldParent)
    if (oldParent) then
      local oldIndex = childButton:GetGroupOrder()

      tremove(oldParentData.controlledChildren, oldIndex)
      WeakAuras.Add(oldParentData)
      OptionsPrivate.Private.AddParents(oldParentData)
      WeakAuras.UpdateGroupOrders(oldParentData);
      WeakAuras.ClearAndUpdateOptions(oldParent);
      local oldParentButton = OptionsPrivate.GetDisplayButton(oldParent)
      oldParentButton.callbacks.UpdateExpandButton();
      oldParentButton:ReloadTooltip()
      oldParentButton:UpdateParentWarning()
    end

    tinsert(data.controlledChildren, childId);
    childData.parent = data.id;
    if resetChildPositions then
      childData.xOffset = 0;
        childData.yOffset = 0;
    end
    WeakAuras.Add(data);
    WeakAuras.Add(childData);
    OptionsPrivate.ClearOptions(childData.id)

    childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
    childButton:SetGroupOrder(index, #data.controlledChildren);
  end

  local button = OptionsPrivate.GetDisplayButton(data.id);
  button.callbacks.UpdateExpandButton();
  button:UpdateParentWarning()
  OptionsPrivate.SortDisplayButtons();
  button:Expand();

  if data.parent then
    OptionsPrivate.Private.AddParents(data)
  end
end

function OptionsPrivate.MultipleDisplayTooltipMenu()
  local frame = frame;
  local menu = {
    {
      text = L["Add to new Group"],
      notCheckable = 1,
      func = function()
        CreateNewGroupFromSelection("group")
      end
    },
    {
      text = L["Add to new Dynamic Group"],
      notCheckable = 1,
      func = function()
        CreateNewGroupFromSelection("dynamicgroup", true)
      end
    },
    {
      text = L["Duplicate All"],
      notCheckable = 1,
      func = function()
        local duplicated = {};
        for child in OptionsPrivate.Private.TraverseAllChildren(tempGroup) do
          local newData = OptionsPrivate.DuplicateAura(child)
          tinsert(duplicated, newData.id);
        end

        OptionsPrivate.ClearPicks();
        frame:PickDisplayBatch(duplicated);
      end
    },
    {
      text = " ",
      notCheckable = 1,
      notClickable = 1
    },
    {
      text = L["Delete all"],
      notCheckable = 1,
      func = function()
        local toDelete = {};
        local parents = {};
        for child in OptionsPrivate.Private.TraverseAllChildren(tempGroup) do
          tinsert(toDelete, child)
          addParents(parents, child)
        end
        OptionsPrivate.ConfirmDelete(toDelete, parents)
      end
    },
    {
      text = " ",
      notClickable = 1,
      notCheckable = 1,
    },
    {
      text = L["Close"],
      notCheckable = 1,
      func = function() WeakAuras_DropDownMenu:Hide() end
    }
  };

  local anyGroup = false;
  local allSameParent = true
  local commonParent = nil
  local first = true
  for _, id in pairs(tempGroup.controlledChildren) do
    local childData = WeakAuras.GetData(id);
    if(childData and childData.controlledChildren) then
      anyGroup = true;
    end

    if (first) then
      commonParent = childData.parent
      first = false
    elseif childData.parent ~= commonParent then
      allSameParent = false
    end
  end

  if(anyGroup) then
    -- Disable "Add to New Dynamic Group"
    menu[2].notClickable = 1;
    menu[2].text = "|cFF777777"..menu[2].text;
  end

  -- Also disable Add to New Dynamic Group/Group if that would create
  -- a group inside a dynamic group
  if (allSameParent and commonParent) then
    local parentData = WeakAuras.GetData(commonParent);
    if (parentData and parentData.regionType == "dynamicgroup") then
      menu[1].notClickable = 1;
      menu[1].text = "|cFF777777"..menu[1].text;
      menu[2].notClickable = 1;
      menu[2].text = "|cFF777777"..menu[1].text;
    end
  end

  return menu;
end

StaticPopupDialogs["WEAKAURAS_CONFIRM_DELETE"] = {
  text = "",
  button1 = L["Delete"],
  button2 = L["Cancel"],
  OnAccept = function(self)
    if self.data then
      OptionsPrivate.DeleteAuras(self.data.toDelete, self.data.parents)
    end
  end,
  OnCancel = function(self)
    self.data = nil
  end,
  showAlert = true,
  whileDead = true,
  preferredindex = STATICPOPUP_NUMDIALOGS,
}

function OptionsPrivate.IsWagoUpdateIgnored(auraId)
    local auraData = WeakAuras.GetData(auraId)
      if auraData then
        for child in OptionsPrivate.Private.TraverseAll(auraData) do
          if child.ignoreWagoUpdate then
            return true
          end
        end
      end
    return false
end

function OptionsPrivate.HasWagoUrl(auraId)
  local auraData = WeakAuras.GetData(auraId)
    if auraData then
      for child in OptionsPrivate.Private.TraverseAll(auraData) do
        if child.url and child.url ~= "" then
          return true
        end
      end
    end
  return false
end

function OptionsPrivate.ConfirmDelete(toDelete, parents)
  if toDelete then
    local warningForm = L["You are about to delete %d aura(s). |cFFFF0000This cannot be undone!|r Would you like to continue?"]
    StaticPopupDialogs["WEAKAURAS_CONFIRM_DELETE"].text = warningForm:format(#toDelete)
    StaticPopup_Show("WEAKAURAS_CONFIRM_DELETE", "", "", {toDelete = toDelete, parents = parents})
  end
end

local function AfterScanForLoads()
  if(frame) then
    if (frame:IsVisible()) then
      OptionsPrivate.SortDisplayButtons(nil, true);
    else
      frame.needsSort = true;
    end
  end
end

local function OnAboutToDelete(event, uid, id, parentUid, parentId)
  local data = OptionsPrivate.Private.GetDataByUID(uid)
  if(data.controlledChildren) then
    for index, childId in pairs(data.controlledChildren) do
      local childButton = displayButtons[childId];
      if(childButton) then
        childButton:SetGroup();
      end
      local childData = db.displays[childId];
      if(childData) then
        childData.parent = nil;
      end
    end
  end

  OptionsPrivate.Private.CollapseAllClones(id);
  OptionsPrivate.ClearOptions(id)

  frame:ClearPicks();

  if(displayButtons[id])then
    frame.buttonsScroll:DeleteChild(displayButtons[id]);
    displayButtons[id] = nil;
  end

  collapsedOptions[id] = nil
end

local function OnRename(event, uid, oldid, newid)
  local data = OptionsPrivate.Private.GetDataByUID(uid)

  OptionsPrivate.displayButtons[newid] = OptionsPrivate.displayButtons[oldid];
  OptionsPrivate.displayButtons[newid]:SetData(data)
  OptionsPrivate.displayButtons[oldid] = nil;
  OptionsPrivate.ClearOptions(oldid)

  OptionsPrivate.displayButtons[newid]:SetTitle(newid);

  collapsedOptions[newid] = collapsedOptions[oldid]
  collapsedOptions[oldid] = nil

  if(data.controlledChildren) then
    for _, childId in pairs(data.controlledChildren) do
      OptionsPrivate.displayButtons[childId]:SetGroup(newid)
    end
  end

  OptionsPrivate.StopGrouping()
  OptionsPrivate.SortDisplayButtons()

  frame:OnRename(uid, oldid, newid)

  WeakAuras.PickDisplay(newid)

  local parent = data.parent
  while parent do
    OptionsPrivate.ClearOptions(parent)
    local parentData = WeakAuras.GetData(parent)
    parent = parentData.parent
  end
end

local function OptionsFrame()
  if(frame) then
    return frame
  else
    return nil
  end
end

---@type fun(msg: string, Private: Private)
function WeakAuras.ToggleOptions(msg, Private)
  if not Private then
    return
  end
  if not OptionsPrivate.Private then
    OptionsPrivate.Private = Private
    Private.OptionsFrame = OptionsFrame
    for _, fn in ipairs(OptionsPrivate.registerRegions) do
      fn()
    end
    OptionsPrivate.Private.callbacks:RegisterCallback("AuraWarningsUpdated", function(event, uid)
      local id = OptionsPrivate.Private.UIDtoID(uid)
      if displayButtons[id] then
        -- The button does not yet exists if a new aura is created
        displayButtons[id]:UpdateWarning()
      end
      local data = Private.GetDataByUID(uid)
      if data and data.parent then
        local button = OptionsPrivate.GetDisplayButton(data.parent);
        if button then
          button:UpdateParentWarning()
        end
      end
    end)

    OptionsPrivate.Private.callbacks:RegisterCallback("ScanForLoads", AfterScanForLoads)
    OptionsPrivate.Private.callbacks:RegisterCallback("AboutToDelete", OnAboutToDelete)
    OptionsPrivate.Private.callbacks:RegisterCallback("Rename", OnRename)
    OptionsPrivate.Private.OpenUpdate = OptionsPrivate.OpenUpdate
  end

  if(frame and frame:IsVisible()) then
    WeakAuras.HideOptions();
  elseif (InCombatLockdown()) then
    WeakAuras.prettyPrint(L["Options will open after combat ends."])
    reopenAfterCombat = true;
  else
    WeakAuras.ShowOptions(msg);
  end
end

function WeakAuras.HideOptions()
  if(frame) then
    frame:Hide()
  end
end

function WeakAuras.IsOptionsOpen()
  if(frame and frame:IsVisible()) then
    return true;
  else
    return false;
  end
end

local function EnsureDisplayButton(data)
  local id = data.id;
  if not(displayButtons[id]) then
    displayButtons[id] = AceGUI:Create("WeakAurasDisplayButton");
    if(displayButtons[id]) then
      displayButtons[id]:SetData(data);
      displayButtons[id]:Initialize();
      displayButtons[id]:UpdateWarning()
    else
      print("|cFF8800FFWeakAuras|r: Error creating button for", id);
    end
  end
end

local function GetSortedOptionsLists()
  local loadedSorted, unloadedSorted = {}, {};
  local to_sort = {};
  for id, data in pairs(db.displays) do
    if(data.parent) then
    -- Do nothing; children will be added later
  elseif(OptionsPrivate.Private.loaded[id]) then
      tinsert(to_sort, id);
    end
  end
  table.sort(to_sort, function(a, b) return a:lower() < b:lower() end)
  for _, id in ipairs(to_sort) do
    local data = WeakAuras.GetData(id);
    for child in OptionsPrivate.Private.TraverseAll(data) do
      tinsert(loadedSorted, child.id)
    end
  end

  wipe(to_sort);
  for id, data in pairs(db.displays) do
    if(data.parent) then
    -- Do nothing; children will be added later
    elseif not(OptionsPrivate.Private.loaded[id]) then
      tinsert(to_sort, id);
    end
  end
  table.sort(to_sort, function(a, b) return a:lower() < b:lower() end)
  for _, id in ipairs(to_sort) do
    local data = WeakAuras.GetData(id);
    for child in OptionsPrivate.Private.TraverseAll(data) do
      tinsert(unloadedSorted, child.id)
    end
  end

  return loadedSorted, unloadedSorted;
end

local function LayoutDisplayButtons(msg)
  local total = 0;
  for _,_ in pairs(db.displays) do
    total = total + 1;
  end

  local loadedSorted, unloadedSorted = GetSortedOptionsLists();

  frame:SetLoadProgressVisible(true)
  if OptionsPrivate.Private.CompanionData.slugs then
    frame.buttonsScroll:AddChild(frame.pendingInstallButton);
    frame.buttonsScroll:AddChild(frame.pendingUpdateButton);
  end
  frame.buttonsScroll:AddChild(frame.loadedButton);
  frame.buttonsScroll:AddChild(frame.unloadedButton);

  local func2 = function()
    local num = frame.loadProgressNum or 0;
    for _, id in pairs(unloadedSorted) do
      local data = WeakAuras.GetData(id);
      if(data) then
        EnsureDisplayButton(data);
        WeakAuras.UpdateThumbnail(data);

        frame.buttonsScroll:AddChild(displayButtons[data.id]);

        if (num % 50 == 0) then
          frame.buttonsScroll:ResumeLayout()
          frame.buttonsScroll:PerformLayout()
          frame.buttonsScroll:PauseLayout()
        end

        num = num + 1;
      end
      frame.loadProgress:SetText(L["Creating buttons: "]..num.."/"..total);
      frame.loadProgressNum = num;
      coroutine.yield();
    end

    frame.buttonsScroll:ResumeLayout()
    frame.buttonsScroll:PerformLayout()
    OptionsPrivate.SortDisplayButtons(msg);

    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    if (WeakAuras.IsOptionsOpen()) then
      for id, button in pairs(displayButtons) do
        if OptionsPrivate.Private.loaded[id] then
          button:PriorityShow(1);
        end
      end
      OptionsPrivate.Private.OptionsFrame().loadedButton:RecheckVisibility()
    end
    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)

    frame:SetLoadProgressVisible(false)
  end

  local func1 = function()
    local num = frame.loadProgressNum or 0;
    frame.buttonsScroll:PauseLayout()
    for _, id in pairs(loadedSorted) do
      local data = WeakAuras.GetData(id);
      if(data) then
        EnsureDisplayButton(data);
        WeakAuras.UpdateThumbnail(data);

        local button = displayButtons[data.id]
        frame.buttonsScroll:AddChild(button);
        num = num + 1;
      end

      if (num % 50 == 0) then
        frame.buttonsScroll:ResumeLayout()
        frame.buttonsScroll:PerformLayout()
        frame.buttonsScroll:PauseLayout()
      end

      frame.loadProgress:SetText(L["Creating buttons: "]..num.."/"..total);
      frame.loadProgressNum = num;
      coroutine.yield();
    end

    local co2 = coroutine.create(func2);
    OptionsPrivate.Private.dynFrame:AddAction("LayoutDisplayButtons2", co2);
  end

  local co1 = coroutine.create(func1);
  OptionsPrivate.Private.dynFrame:AddAction("LayoutDisplayButtons1", co1);
end

function OptionsPrivate.DeleteAuras(auras, parents)
  local func1 = function()
    frame:SetLoadProgressVisible(true)
    local num = 0
    local total = 0
    for _, auraData in pairs(auras) do
      total = total +1
    end

    frame.loadProgress:SetText(L["Deleting auras: "]..num.."/"..total)

    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    OptionsPrivate.massDelete = true
    for _, auraData in pairs(auras) do
      WeakAuras.Delete(auraData)
      num = num +1
      frame.loadProgress:SetText(L["Deleting auras: "]..num.."/"..total)
      coroutine.yield()
    end
    OptionsPrivate.massDelete = false

    if parents then
      for id in pairs(parents) do
        local parentData = WeakAuras.GetData(id)
        local parentButton = OptionsPrivate.GetDisplayButton(id)
        WeakAuras.UpdateGroupOrders(parentData)
        if(#parentData.controlledChildren == 0) then
          parentButton:DisableExpand()
        else
          parentButton:EnableExpand()
        end
        parentButton:SetNormalTooltip()
        WeakAuras.Add(parentData)
        WeakAuras.ClearAndUpdateOptions(parentData.id)
        parentButton:UpdateParentWarning()
        frame.loadProgress:SetText(L["Finishing..."])
        coroutine.yield()
      end
    end
    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
    OptionsPrivate.SortDisplayButtons(nil, true)

    frame:SetLoadProgressVisible(false)
  end

  local co1 = coroutine.create(func1)
  OptionsPrivate.Private.dynFrame:AddAction("Deleting Auras", co1)
end

function WeakAuras.ShowOptions(msg)
  local firstLoad = not(frame);
  OptionsPrivate.Private.Pause();
  OptionsPrivate.Private.SetFakeStates()

  WeakAuras.spellCache.Build()

  if (firstLoad) then
    frame = OptionsPrivate.CreateFrame();
    frame.buttonsScroll.frame:Show();

    LayoutDisplayButtons(msg);
  end

  if (frame:GetWidth() > GetScreenWidth()) then
    frame:SetWidth(GetScreenWidth())
  end

  if (frame:GetHeight() > GetScreenHeight() - 50) then
    frame:SetHeight(GetScreenHeight() - 50)
  end

  frame.buttonsScroll.frame:Show();

  if (frame.needsSort) then
    OptionsPrivate.SortDisplayButtons();
    frame.needsSort = nil;
  end

  frame:Show();

  if (OptionsPrivate.Private.mouseFrame) then
    OptionsPrivate.Private.mouseFrame:OptionsOpened();
  end

  if (OptionsPrivate.Private.personalRessourceDisplayFrame) then
    OptionsPrivate.Private.personalRessourceDisplayFrame:OptionsOpened();
  end

  if frame.moversizer then
    frame.moversizer:OptionsOpened()
  end

  if not(firstLoad) then
    -- Show what was last shown
    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    for id, button in pairs(displayButtons) do
      button:SyncVisibility()
    end
    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
  end

  if (frame.pickedDisplay) then
    if (OptionsPrivate.IsPickedMultiple()) then
      local children = {}
      for k,v in pairs(tempGroup.controlledChildren) do
        children[k] = v
      end
      frame:PickDisplayBatch(children);
    else
      WeakAuras.PickDisplay(frame.pickedDisplay);
    end
  else
    frame:NewAura();
  end

  if (frame.window == "codereview") then
    frame.codereview:Close();
  end

  if firstLoad then
    frame:ShowTip()
  end

end

function OptionsPrivate.UpdateOptions()
  frame:UpdateOptions()
end

function WeakAuras.ClearAndUpdateOptions(id, clearChildren)
  frame:ClearAndUpdateOptions(id, clearChildren)
end

function OptionsPrivate.ClearOptions(id)
  frame:ClearOptions(id)
end

function WeakAuras.FillOptions()
  frame:FillOptions()
end

function OptionsPrivate.EnsureOptions(data, subOption)
  return frame:EnsureOptions(data, subOption)
end

function OptionsPrivate.GetPickedDisplay()
  return frame:GetPickedDisplay()
end

function OptionsPrivate.OpenTextEditor(...)
  frame.texteditor:Open(...);
end

function OptionsPrivate.ExportToString(id)
  frame.importexport:Open("export", id);
end

function OptionsPrivate.ExportToTable(id)
  frame.importexport:Open("table", id);
end

function OptionsPrivate.ImportFromString()
  frame.importexport:Open("import");
end

function OptionsPrivate.OpenDebugLog(text)
  frame.debugLog:Open(text)
end

function OptionsPrivate.OpenUpdate(data, children, target, linkedAuras, sender, callbackFunc)
  return frame.update:Open(data, children, target, linkedAuras, sender, callbackFunc)
end

function OptionsPrivate.ConvertDisplay(data, newType)
  local id = data.id;
  local visibility = displayButtons[id]:GetVisibility();
  displayButtons[id]:PriorityHide(2);

  if OptionsPrivate.Private.regions[id] and OptionsPrivate.Private.regions[id].region then
    OptionsPrivate.Private.regions[id].region:Collapse()
  end
  OptionsPrivate.Private.CollapseAllClones(id);

  OptionsPrivate.Private.Convert(data, newType);
  displayButtons[id]:Initialize();
  displayButtons[id]:PriorityShow(visibility);
  frame:ClearOptions(id)
  frame:FillOptions();
  WeakAuras.UpdateThumbnail(data);
  WeakAuras.SetMoverSizer(id)
  OptionsPrivate.ResetMoverSizer();
  OptionsPrivate.SortDisplayButtons()
end

function WeakAuras.NewDisplayButton(data, massEdit)
  local id = data.id;
  OptionsPrivate.Private.ScanForLoads({[id] = true});
  EnsureDisplayButton(db.displays[id]);
  WeakAuras.UpdateThumbnail(db.displays[id]);
  frame.buttonsScroll:AddChild(displayButtons[id]);
  if not massEdit then
    OptionsPrivate.SortDisplayButtons()
  end
end

function WeakAuras.UpdateGroupOrders(data)
  if(data.controlledChildren) then
    local total = #data.controlledChildren;
    for index, id in pairs(data.controlledChildren) do
      local button = OptionsPrivate.GetDisplayButton(id);
      button:SetGroupOrder(index, total);
    end
  end
end

function OptionsPrivate.UpdateButtonsScroll()
  if OptionsPrivate.Private.IsOptionsProcessingPaused() then return end
  frame.buttonsScroll:DoLayout()
end

local function addButton(button, aurasMatchingFilter, visible)
  button.frame:Show();
  if button.AcquireThumbnail then
    button:AcquireThumbnail()
  end
  tinsert(frame.buttonsScroll.children, button);
  visible[button] = true

  if button.data.controlledChildren and button:GetExpanded() then
    for _, childId in ipairs(button.data.controlledChildren) do
      if aurasMatchingFilter[childId] then
        addButton(displayButtons[childId], aurasMatchingFilter, visible)
      end
    end
  end
end

local previousFilter;
local pendingUpdateButtons = {}
local pendingInstallButtons = {}
function OptionsPrivate.SortDisplayButtons(filter, overrideReset, id)
  if (OptionsPrivate.Private.IsOptionsProcessingPaused()) then
    return;
  end

  local recenter = false;
  filter = filter or (overrideReset and previousFilter or "");
  if(frame.filterInput:GetText() ~= filter) then
    frame.filterInput:SetText(filter);
  end
  if(previousFilter and previousFilter ~= "" and (filter == "" or not filter)) then
    recenter = true;
  end
  previousFilter = filter;
  filter = filter:lower();

  wipe(frame.buttonsScroll.children);

  local pendingInstallButtonShown = false
  if OptionsPrivate.Private.CompanionData.stash then
    for id, companionData in pairs(OptionsPrivate.Private.CompanionData.stash) do
      if not pendingInstallButtonShown then
        tinsert(frame.buttonsScroll.children, frame.pendingInstallButton)
        pendingInstallButtonShown = true
      end
      local child = pendingInstallButtons[id]
      if frame.pendingInstallButton:GetExpanded() then
        if not child then
          child = AceGUI:Create("WeakAurasPendingInstallButton")
          pendingInstallButtons[id] = child
          child:Initialize(id, companionData)
          if companionData.logo then
            child:SetLogo(companionData.logo)
          end
          if companionData.refreshLogo then
            child:SetRefreshLogo(companionData.refreshLogo)
          end
          child.frame:Show()
          child:AcquireThumbnail()
          frame.buttonsScroll:AddChild(child)
        else
          if not child.frame:IsShown() then
            child.frame:Show()
            child:AcquireThumbnail()
          end
          tinsert(frame.buttonsScroll.children, child)
        end
      elseif child then
        child.frame:Hide()
        if child.ReleaseThumbnail then
          child:ReleaseThumbnail()
        end
      end
    end
  end
  if not pendingInstallButtonShown and frame.pendingInstallButton then
    frame.pendingInstallButton.frame:Hide()
  end

  local pendingUpdateButtonShown = false
  if OptionsPrivate.Private.CompanionData.slugs then
    local buttonsShown = {}
    for _, button in pairs(pendingUpdateButtons) do
      button:ResetLinkedAuras()
    end
    for id, aura in pairs(WeakAurasSaved.displays) do
      if not aura.ignoreWagoUpdate and aura.url and aura.url ~= "" then
        local slug, version = aura.url:match("wago.io/([^/]+)/([0-9]+)")
        if not slug and not version then
          slug = aura.url:match("wago.io/([^/]+)$")
          version = 1
        end
        if slug and version then
          local auraData = OptionsPrivate.Private.CompanionData.slugs[slug]
          if auraData and auraData.wagoVersion then
            if tonumber(auraData.wagoVersion) > tonumber(version) then
              -- there is an update for this aura
              if not pendingUpdateButtonShown then
                tinsert(frame.buttonsScroll.children, frame.pendingUpdateButton)
                pendingUpdateButtonShown = true
              end
              if frame.pendingUpdateButton:GetExpanded() then
                local child = pendingUpdateButtons[slug]
                if not child then
                  child = AceGUI:Create("WeakAurasPendingUpdateButton")
                  pendingUpdateButtons[slug] = child
                  child:Initialize(slug, auraData)
                  if auraData.logo then
                    child:SetLogo(auraData.logo)
                  end
                  if auraData.refreshLogo then
                    child:SetRefreshLogo(auraData.refreshLogo)
                  end
                  child.frame:Show()
                  child:AcquireThumbnail()
                  frame.buttonsScroll:AddChild(child)
                  buttonsShown[slug] = true
                end
                if not child.frame:IsShown() then
                  child.frame:Show()
                  child:AcquireThumbnail()
                end
                if not buttonsShown[slug] then
                  tinsert(frame.buttonsScroll.children, child)
                  buttonsShown[slug] = true
                end
                child:MarkLinkedAura(id)
                for childData in OptionsPrivate.Private.TraverseAllChildren(aura) do
                  child:MarkLinkedChildren(childData.id)
                end
              end
            end
          end
        end
      end
    end
    -- hide all buttons not marked as shown
    for slug, button in pairs(pendingUpdateButtons) do
      if not buttonsShown[slug] then
        if button and button.frame:IsShown() then
          button.frame:Hide()
          if button.ReleaseThumbnail then
            button:ReleaseThumbnail()
          end
        end
      end
    end
  end
  if not pendingUpdateButtonShown and frame.pendingUpdateButton then
    frame.pendingUpdateButton.frame:Hide()
  end

  tinsert(frame.buttonsScroll.children, frame.loadedButton);

  local aurasMatchingFilter = {}
  local useTextFilter = filter and filter ~= ""
  local topLevelLoadedAuras = {}
  local topLevelUnloadedAuras = {}
  local visible = {}

  for id, child in pairs(displayButtons) do
    if child.data.controlledChildren then
      local hasLoaded, hasStandBy, hasNotLoaded = 0, 0, 0
      for leaf in OptionsPrivate.Private.TraverseLeafs(child.data) do
        local id = leaf.id
        if OptionsPrivate.Private.loaded[id] == true then
          hasLoaded = hasLoaded + 1
        elseif OptionsPrivate.Private.loaded[id] == false then
          hasStandBy = hasStandBy + 1
        else
          hasNotLoaded = hasNotLoaded + 1
        end
      end
      if hasLoaded > 0 then
        child:SetLoaded(1, {0, 0.68, 0.30, 1}, L["Loaded"], L["%d displays loaded"]:format(hasLoaded))
      elseif hasStandBy > 0 then
        child:SetLoaded(2, {0.96, 0.82, 0.16, 1}, L["Standby"], L["%d displays on standby"]:format(hasStandBy))
      elseif hasNotLoaded > 0 then
        child:SetLoaded(3, {0.6, 0.6, 0.6, 1}, L["Not Loaded"], L["%d displays not loaded"]:format(hasNotLoaded))
      else
        child:ClearLoaded()
      end
    else
      if OptionsPrivate.Private.loaded[id] == true then
        child:SetLoaded(1, {0, 0.68, 0.30, 1}, L["Loaded"], L["This display is currently loaded"])
      elseif OptionsPrivate.Private.loaded[id] == false then
        child:SetLoaded(2, {0.96, 0.82, 0.16, 1}, L["Standby"], L["This display is on standby, it will be loaded when needed."])
      else
        child:SetLoaded(3, {0.6, 0.6, 0.6, 1}, L["Not Loaded"], L["This display is not currently loaded"])
      end
    end

    if useTextFilter then
      if(id:lower():find(filter, 1, true)) then
        aurasMatchingFilter[id] = true
        for parent in OptionsPrivate.Private.TraverseParents(child.data) do
          aurasMatchingFilter[parent.id] = true
        end
      end
    else
      aurasMatchingFilter[id] = true
    end

    if not child:GetGroup() then
      -- Top Level aura
      if OptionsPrivate.Private.loaded[id] ~= nil then
        tinsert(topLevelLoadedAuras, id)
      else
        tinsert(topLevelUnloadedAuras, id)
      end
    end
  end

  wipe(frame.loadedButton.childButtons)
  if frame.loadedButton:GetExpanded() then
    table.sort(topLevelLoadedAuras, function(a, b) return a:lower() < b:lower() end)
    for _, id in ipairs(topLevelLoadedAuras) do
      if aurasMatchingFilter[id] then
        addButton(displayButtons[id], aurasMatchingFilter, visible)
      end
    end
  end

  for _, id in ipairs(topLevelLoadedAuras) do
    for child in OptionsPrivate.Private.TraverseLeafsOrAura(WeakAuras.GetData(id)) do
      tinsert(frame.loadedButton.childButtons, displayButtons[child.id])
    end
  end

  tinsert(frame.buttonsScroll.children, frame.unloadedButton);

  wipe(frame.unloadedButton.childButtons)
  if frame.unloadedButton:GetExpanded() then
    table.sort(topLevelUnloadedAuras, function(a, b) return a:lower() < b:lower() end)
    for _, id in ipairs(topLevelUnloadedAuras) do
      if aurasMatchingFilter[id] then
        addButton(displayButtons[id], aurasMatchingFilter, visible)
      end
    end
  end

  for _, id in ipairs(topLevelUnloadedAuras) do
    for child in OptionsPrivate.Private.TraverseLeafsOrAura(WeakAuras.GetData(id)) do
      tinsert(frame.unloadedButton.childButtons, displayButtons[child.id])
    end
  end

  for _, child in pairs(displayButtons) do
    if(not visible[child]) then
      child.frame:Hide();
      if child.ReleaseThumbnail then
        child:ReleaseThumbnail()
      end
    end
  end

  frame.buttonsScroll:DoLayout();
  if(recenter) then
    frame:CenterOnPicked();
  end
end


function OptionsPrivate.IsPickedMultiple()
  if(frame.pickedDisplay == tempGroup) then
    return true;
  else
    return false;
  end
end

function OptionsPrivate.IsDisplayPicked(id)
  if(frame.pickedDisplay == tempGroup) then
    for child in OptionsPrivate.Private.TraverseLeafs(tempGroup) do
      if(id == child.id) then
        return true;
      end
    end
    return false;
  else
    return frame.pickedDisplay == id;
  end
end

function WeakAuras.PickDisplay(id, tab, noHide)
  frame:PickDisplay(id, tab, noHide)
  OptionsPrivate.UpdateButtonsScroll()
end

function OptionsPrivate.PickAndEditDisplay(id)
  frame:PickDisplay(id);
  OptionsPrivate.UpdateButtonsScroll()
  displayButtons[id].callbacks.OnRenameClick();
end

function OptionsPrivate.ClearPick(id)
  frame:ClearPick(id);
end

function OptionsPrivate.ClearPicks()
  frame:ClearPicks();
end

function OptionsPrivate.PickDisplayMultiple(id)
  frame:PickDisplayMultiple(id);
end

function OptionsPrivate.PickDisplayMultipleShift(target)
  if (frame.pickedDisplay) then
    -- get first aura selected
    local first;
    if (OptionsPrivate.IsPickedMultiple()) then
      first = tempGroup.controlledChildren[#tempGroup.controlledChildren];
    else
      first = frame.pickedDisplay;
    end
    if (first and first ~= target) then
      -- check if target and first are in same group and are not a group
      local firstData = WeakAuras.GetData(first);
      local targetData = WeakAuras.GetData(target);
      if (firstData.parent == targetData.parent and not targetData.controlledChildren and not firstData.controlledChildren) then
        local batchSelection = {};
        -- in a group
        if (firstData.parent) then
          local group = WeakAuras.GetData(targetData.parent);
          for index, child in ipairs(group.controlledChildren) do
            -- 1st button
            if (child == target or child == first) then
              table.insert(batchSelection, child);
              for i = index + 1, #group.controlledChildren do
                local current = group.controlledChildren[i];
                if (WeakAuras.GetData(current).controlledChildren) then
                  -- Skip sub groups
                else
                  table.insert(batchSelection, current);
                end
                -- last button: stop selection
                if (current == target or current == first) then
                  break;
                end
              end
              break;
            end
          end
        elseif (firstData.parent == nil and targetData.parent == nil) then
          -- top-level
          for index, button in ipairs(frame.buttonsScroll.children) do
            if button.type == "WeakAurasDisplayButton" then
              local data = button.data;
              -- 1st button
              if (data and (data.id == target or data.id == first)) then
                table.insert(batchSelection, data.id);
                for i = index + 1, #frame.buttonsScroll.children do
                  local current = frame.buttonsScroll.children[i];
                  local currentData = current.data;
                  if currentData and not currentData.parent and not currentData.controlledChildren then
                    table.insert(batchSelection, currentData.id);
                    -- last button: stop selection
                    if (currentData.id == target or currentData.id == first) then
                      break;
                    end
                  end
                end
                break;
              end
            end
          end
        end
        if #batchSelection > 0 then
          frame:PickDisplayBatch(batchSelection);
        end
      end
    end
  else
    WeakAuras.PickDisplay(target);
  end
end

function OptionsPrivate.GetDisplayButton(id)
  if(id and displayButtons[id]) then
    return displayButtons[id];
  end
end

function OptionsPrivate.AddDisplayButton(data)
  EnsureDisplayButton(data);
  WeakAuras.UpdateThumbnail(data);
  frame.buttonsScroll:AddChild(displayButtons[data.id]);
end

function OptionsPrivate.StartGrouping(data)
  if not data then
    return
  end

  if not OptionsPrivate.IsDisplayPicked(data) then
    WeakAuras.PickDisplay(data.id)
  end

  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0) then
    local children = {};
    -- start grouping for selected buttons
    for index, childId in ipairs(tempGroup.controlledChildren) do
      local button = OptionsPrivate.GetDisplayButton(childId);
      button:StartGrouping(tempGroup.controlledChildren, true);
      children[childId] = true;
    end
    -- set grouping for non selected buttons
    for _, button in pairs(displayButtons) do
      if not children[button.data.id] then
        button:StartGrouping(tempGroup.controlledChildren, false);
      end
    end
  else
    local children = {};
    for child in OptionsPrivate.Private.TraverseAllChildren(data) do
      children[child.id] = true
    end

    for id, button in pairs(displayButtons) do
      button:StartGrouping({data.id},
                           data.id == id,
                           data.regionType == "dynamicgroup" or data.regionType == "group",
                           children[id]);
    end
  end
end

function OptionsPrivate.StopGrouping(data)
  for id, button in pairs(displayButtons) do
    button:StopGrouping();
  end
end

function OptionsPrivate.Ungroup(data)
  if not OptionsPrivate.IsDisplayPicked(data.id) then
    WeakAuras.PickDisplay(data.id)
  end

  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0) then
    for index, childId in ipairs(tempGroup.controlledChildren) do
      local button = OptionsPrivate.GetDisplayButton(childId);
      button:Ungroup(data);
    end
  else
    local button = OptionsPrivate.GetDisplayButton(data.id);
    button:Ungroup(data);
  end
  WeakAuras.FillOptions()
end

function OptionsPrivate.DragReset()
  for _, button in pairs(displayButtons) do
    button:DragReset();
  end
  OptionsPrivate.UpdateButtonsScroll()
end

local function CompareButtonOrder(a, b)
  if (a.data.parent == b.data.parent) then
    if (a.data.parent) then
      return a:GetGroupOrder() < b:GetGroupOrder()
    else
      return a.data.id < b.data.id
    end
  end

  -- Different parents, so find common parent by first
  -- going up a's hierarchy

  local parents = {}

  local aNode = a.data.id
  local lastAParent = aNode

  while(aNode) do
    local parent = WeakAuras.GetData(aNode).parent
    if (parent) then
      parents[parent] = aNode
      lastAParent = parent
    end
    aNode = parent
  end

  local bNode = b.data.id
  local lastBParent = bNode

  while(bNode) do
    local parent = WeakAuras.GetData(bNode).parent
    if parent then
      if (parents[parent]) then
        -- We have found the common parent, the last node in the chain is
        -- Compare the previous nodes GroupOrder
        local aButton = OptionsPrivate.GetDisplayButton(parents[parent])
        local bButton = OptionsPrivate.GetDisplayButton(bNode)
        return aButton:GetGroupOrder() < bButton:GetGroupOrder()
      end
      lastBParent = parent
    end
    bNode = parent
  end

  -- If we are here there was no common parent
  local aButton = OptionsPrivate.GetDisplayButton(lastAParent)
  local bButton = OptionsPrivate.GetDisplayButton(lastBParent)

  return aButton.data.id < bButton.data.id
end

local function CompareButtonOrderReverse(a, b)
  return CompareButtonOrder(b, a)
end

function OptionsPrivate.Drop(mainAura, target, action, area)
  WeakAuras_DropDownMenu:Hide()

  local func1 = function()
    frame:SetLoadProgressVisible(true)

    local total = 0
    local num = 0
    for id, button in pairs(displayButtons) do
      if button:IsDragging() then
        total = total + 1
      end
    end
    frame.loadProgress:SetText(L["Moving auras: "]..num.."/"..total)

    local mode = ""
    if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0) then
      mode = "MULTI"
    elseif mainAura.controlledChildren then
      mode = "GROUP"
    else
      mode = "SINGLE"
    end

    local buttonsToSort = {}

    for id, button in pairs(displayButtons) do
      if button:IsDragging() then
        tinsert(buttonsToSort, button)
        num = num + 1
        frame.loadProgress:SetText(L["Preparing auras: "]..num.."/"..total)
      else
        button:Drop(mode, mainAura, target, action);
      end
      coroutine.yield()
    end

    num = 0
    frame.loadProgress:SetText(L["Moving auras: "]..num.."/"..total)
    if mode == "MULTI" then
      -- If we are dragging and dropping multiple auras at once, the order in which we drop is important
      -- We want to preserve the top-down order
      -- Depending on how exactly we find the insert position, we need to use the right order of insertions
      if area == "GROUP" then
        table.sort(buttonsToSort, CompareButtonOrderReverse)
      elseif area == "BEFORE" then
        table.sort(buttonsToSort, CompareButtonOrder)
      else -- After
        table.sort(buttonsToSort, CompareButtonOrderReverse)
      end
    end

    for _, button in ipairs(buttonsToSort) do
      button:Drop(mode, mainAura, target, action)
      num = num + 1
      frame.loadProgress:SetText(L["Moving auras: "]..num.."/"..total)
      coroutine.yield()
    end

    -- Update offset, this is a bit wasteful to do for every aura
    -- But we also need to update the offset if a parent was dragged
    for _, button in pairs(displayButtons) do
      button:UpdateOffset();
    end
    coroutine.yield()
    frame:SetLoadProgressVisible(false)
    OptionsPrivate.SortDisplayButtons()
    OptionsPrivate.UpdateButtonsScroll()
    WeakAuras.FillOptions()
  end

  local co1 = coroutine.create(func1)
  OptionsPrivate.Private.dynFrame:AddAction("Dropping Auras", co1)
end

function OptionsPrivate.StartDrag(mainAura)
  WeakAuras_DropDownMenu:Hide()

  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0) then
    -- Multi selection
    local children = {};
    local size = #tempGroup.controlledChildren;
    -- set dragging for selected buttons in reverse for ordering

    for child in OptionsPrivate.Private.TraverseAllChildren(tempGroup) do
      local button = OptionsPrivate.GetDisplayButton(child.id);
      button:DragStart("MULTI", true, mainAura, size)
      children[child.id] = true
    end
    -- set dragging for non selected buttons
    for id, button in pairs(displayButtons) do
      if not children[button.data.id] then
        button:DragStart("MULTI", false, mainAura);
      end
    end
  else
    if mainAura.controlledChildren then
      -- Group aura
      local mode = "GROUP"
      local children = {};
      for child in OptionsPrivate.Private.TraverseAll(mainAura) do
        local button = OptionsPrivate.GetDisplayButton(child.id);
        button:DragStart(mode, true, mainAura)
        children[child.id] = true
      end
      -- set dragging for non selected buttons
      for _, button in pairs(displayButtons) do
        if not children[button.data.id] then
          button:DragStart(mode, false, mainAura);
        end
      end
    else
      for id, button in pairs(displayButtons) do
        button:DragStart("SINGLE", id == mainAura.id, mainAura);
      end
    end
  end
  OptionsPrivate.UpdateButtonsScroll()
end

function OptionsPrivate.DropIndicator()
  local indicator = frame.dropIndicator
  if not indicator then
    ---@class Frame
    indicator = CreateFrame("Frame", "WeakAuras_DropIndicator")
    indicator:SetHeight(4)
    indicator:SetFrameStrata("FULLSCREEN")

    local groupTexture = indicator:CreateTexture(nil, "ARTWORK")
    groupTexture:SetBlendMode("ADD")
    groupTexture:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite")

    local lineTexture = indicator:CreateTexture(nil, "ARTWORK")
    lineTexture:SetBlendMode("ADD")
    lineTexture:SetAllPoints(indicator)
    lineTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")

    indicator.lineTexture = lineTexture
    indicator.groupTexture = groupTexture
    frame.dropIndicator = indicator
    indicator:Hide()

    function indicator:ShowAction(target, action)
      self:Show()
      self:ClearAllPoints()
      if action == "GROUP" then
        self.groupTexture:ClearAllPoints()
        self.groupTexture:SetVertexColor(0.4, 0.7, 1, 0.7)
        self.groupTexture:Show()
        self.groupTexture:SetPoint("TOPLEFT", target.icon, "TOPRIGHT", 2, -1)
        self.groupTexture:SetPoint("BOTTOMRIGHT", target.frame, "BOTTOMRIGHT", 0, 1)
      else
        self.groupTexture:Hide()
      end

      -- Position line texture, if needed
      if action == "BEFORE" then
        self.lineTexture:Show()
        self:SetPoint("BOTTOMLEFT", target.frame, "TOPLEFT", 0, -1)
        self:SetPoint("BOTTOMRIGHT", target.frame, "TOPRIGHT", 0, -1)
        self:SetHeight(4)
      elseif action == "AFTER" then
        self.lineTexture:Show()
        self:SetPoint("TOPLEFT", target.frame, "BOTTOMLEFT", 0, 1)
        self:SetPoint("TOPRIGHT", target.frame, "BOTTOMRIGHT", 0, 1)
        self:SetHeight(4)
      else
        self.lineTexture:Hide()
      end
    end

  end
  return indicator
end

function WeakAuras.UpdateThumbnail(data)
  local id = data.id
  local button = displayButtons[id]
  if (not button) then
    return
  end
  button:UpdateThumbnail()
end

function OptionsPrivate.OpenTexturePicker(baseObject, paths, properties, textures, SetTextureFunc, adjustSize)
  frame.texturePicker:Open(baseObject, paths, properties, textures, SetTextureFunc, adjustSize)
end

function OptionsPrivate.OpenIconPicker(baseObject, paths, groupIcon)
  frame.iconPicker:Open(baseObject, paths, groupIcon)
end

function OptionsPrivate.OpenModelPicker(baseObject, path)
  if not(C_AddOns.IsAddOnLoaded("WeakAurasModelPaths")) then
    local loaded, reason = C_AddOns.LoadAddOn("WeakAurasModelPaths");
    if not(loaded) then
      reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
      WeakAuras.prettyPrint(string.format(L["ModelPaths could not be loaded, the addon is %s"], reason));
      WeakAuras.ModelPaths = {};
    end
    frame.modelPicker.modelTree:SetTree(WeakAuras.ModelPaths);
  end
  frame.modelPicker:Open(baseObject, path);
end

function OptionsPrivate.OpenCodeReview(data)
  frame.codereview:Open(data);
end

function OptionsPrivate.OpenTriggerTemplate(data, targetId)
  if not(C_AddOns.IsAddOnLoaded("WeakAurasTemplates")) then
    local loaded, reason = C_AddOns.LoadAddOn("WeakAurasTemplates");
    if not(loaded) then
      reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
      WeakAuras.prettyPrint(string.format(L["Templates could not be loaded, the addon is %s"], reason));
      return;
    end
    frame.newView = WeakAuras.CreateTemplateView(OptionsPrivate.Private, frame);
  end
  -- This is called multiple times if a group is selected
  if frame.window ~= "newView" then
    frame.newView:Open(data, targetId);
  end
end

function OptionsPrivate.ResetMoverSizer()
  if(frame and frame.mover and frame.moversizer and frame.mover.moving.region and frame.mover.moving.data) then
    frame.moversizer:SetToRegion(frame.mover.moving.region, frame.mover.moving.data);
  end
end

function WeakAuras.SetMoverSizer(id)
  OptionsPrivate.Private.EnsureRegion(id)
  if OptionsPrivate.Private.regions[id].region.toShow then
    frame.moversizer:SetToRegion(OptionsPrivate.Private.regions[id].region, db.displays[id])
  else
    if OptionsPrivate.Private.clones[id] then
      local _, clone = next(OptionsPrivate.Private.clones[id])
      if clone then
        frame.moversizer:SetToRegion(clone, db.displays[id])
      end
    end
  end
end

function WeakAuras.GetMoverSizerId()
  return frame.moversizer:GetCurrentId()
end

local function AddDefaultSubRegions(data)
  data.subRegions = data.subRegions or {}
  for type, subRegionData in pairs(OptionsPrivate.Private.subRegionTypes) do
    if subRegionData.addDefaultsForNewAura then
      subRegionData.addDefaultsForNewAura(data)
    end
  end
end

function WeakAuras.NewAura(sourceData, regionType, targetId)
  local function ensure(t, k, v)
    return t and k and v and t[k] == v
  end
  local new_id = OptionsPrivate.Private.FindUnusedId("New")
  local data = {id = new_id, regionType = regionType, uid = WeakAuras.GenerateUniqueID()}
  WeakAuras.DeepMixin(data, OptionsPrivate.Private.data_stub);
  if (sourceData) then
    WeakAuras.DeepMixin(data, sourceData);
  end
  data.internalVersion = WeakAuras.InternalVersion();
  OptionsPrivate.Private.validate(data, OptionsPrivate.Private.regionTypes[regionType].default);

  AddDefaultSubRegions(data)

  if targetId then
    local target = OptionsPrivate.GetDisplayButton(targetId);
    local group
    if (target) then
      if (target:IsGroup()) then
        group = target;
      else
        group = OptionsPrivate.GetDisplayButton(target.data.parent);
      end
      if (group) then
        -- Sanity check so that we don't create a group/dynamic group in a group
        if (regionType == "group" or regionType == "dynamicgroup") and group.data.regionType == "dynamicgroup" then
          return
        end

        local children = group.data.controlledChildren;
        local index = target:GetGroupOrder();
        if (ensure(children, index, target.data.id)) then
          -- account for insert position
          index = index + 1;
          tinsert(children, index, data.id);
        else
          -- move source into group as the first child
          tinsert(children, 1, data.id);
        end
        data.parent = group.data.id;
        WeakAuras.Add(data);
        WeakAuras.Add(group.data);
        OptionsPrivate.Private.AddParents(group.data)
        WeakAuras.NewDisplayButton(data);
        WeakAuras.UpdateGroupOrders(group.data);
        OptionsPrivate.ClearOptions(group.data.id);
        group.callbacks.UpdateExpandButton();
        group:UpdateParentWarning();
        group:Expand();
        group:ReloadTooltip();
        OptionsPrivate.PickAndEditDisplay(data.id);
      else
        -- move source into the top-level list
        WeakAuras.Add(data);
        WeakAuras.NewDisplayButton(data);
        OptionsPrivate.PickAndEditDisplay(data.id);
      end
    else
      error(string.format("Calling 'WeakAuras.NewAura' with invalid groupId %s. Reload your UI to fix the display list.", targetId))
    end
  else
    -- move source into the top-level list
    WeakAuras.Add(data);
    WeakAuras.NewDisplayButton(data);
    OptionsPrivate.PickAndEditDisplay(data.id);
  end
end


function OptionsPrivate.ResetCollapsed(id, namespace)
  if id then
    if namespace and collapsedOptions[id] then
      collapsedOptions[id][namespace] = nil
    else
      collapsedOptions[id] = nil
    end
  end
end

function OptionsPrivate.IsCollapsed(id, namespace, path, default)
  local tmp = collapsedOptions[id]
  if tmp == nil then return default end

  tmp = tmp[namespace]
  if tmp == nil then return default end

  if type(path) ~= "table" then
    tmp = tmp[path]
  else
    for _, key in ipairs(path) do
      tmp = tmp[key]
      if tmp == nil or tmp[collapsed] then
        break
      end
    end
  end
  if tmp == nil or tmp[collapsed] == nil then
    return default
  else
    return tmp[collapsed]
  end
end

function OptionsPrivate.SetCollapsed(id, namespace, path, v)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    collapsedOptions[id][namespace][path] = collapsedOptions[id][namespace][path] or {}
    collapsedOptions[id][namespace][path][collapsed] = v
  else
    local tmp = collapsedOptions[id][namespace] or {}
    for _, key in ipairs(path) do
      tmp[key] = tmp[key] or {}
      tmp = tmp[key]
    end
    tmp[collapsed] = v
  end
end

function OptionsPrivate.MoveCollapseDataUp(id, namespace, path)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    collapsedOptions[id][namespace][path], collapsedOptions[id][namespace][path - 1]
      = collapsedOptions[id][namespace][path - 1], collapsedOptions[id][namespace][path]
  else
    local tmp = collapsedOptions[id][namespace]
    local lastKey = tremove(path)
    for _, key in ipairs(path) do
      tmp[key] = tmp[key] or {}
      tmp = tmp[key]
    end
    tmp[lastKey], tmp[lastKey - 1] = tmp[lastKey - 1], tmp[lastKey]
  end
end

function OptionsPrivate.MoveCollapseDataDown(id, namespace, path)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    collapsedOptions[id][namespace][path], collapsedOptions[id][namespace][path + 1]
      = collapsedOptions[id][namespace][path + 1], collapsedOptions[id][namespace][path]
  else
    local tmp = collapsedOptions[id][namespace]
    local lastKey = tremove(path)
    for _, key in ipairs(path) do
      tmp[key] = tmp[key] or {}
      tmp = tmp[key]
    end
    tmp[lastKey], tmp[lastKey + 1] = tmp[lastKey + 1], tmp[lastKey]
  end
end

function OptionsPrivate.RemoveCollapsed(id, namespace, path)
  local data = collapsedOptions[id] and collapsedOptions[id][namespace]
  if not data then
    return
  end
  local index
  local maxIndex = 0
  if type(path) ~= "table" then
    index = path
  else
    index = path[#path]
    for i = 1, #path - 1 do
      data = data[path[i]]
      if not data then
        return
      end
    end
  end
  for k in pairs(data) do
    if k ~= collapsed then
      maxIndex = max(maxIndex, k)
    end
  end
  while index <= maxIndex do
    data[index] = data[index + 1]
    index = index + 1
  end
end

function OptionsPrivate.InsertCollapsed(id, namespace, path, value)
  local data = collapsedOptions[id] and collapsedOptions[id][namespace]
  if not data then
    return
  end
  local insertPoint
  local maxIndex
  if type(path) ~= "table" then
    insertPoint = path
  else
    insertPoint = path[#path]
    for i = 1, #path - 1 do
      data = data[path[i]]
      if not data then
        return
      end
    end
  end
  for k in pairs(data) do
    if k ~= collapsed and k >= insertPoint then
      if not maxIndex or k > maxIndex then
        maxIndex = k
      end
    end
  end
  if maxIndex then -- may be nil if insertPoint is greater than the max of anything else
    for i = maxIndex, insertPoint, -1 do
      data[i + 1] = data[i]
    end
  end
  data[insertPoint] = {[collapsed] = value}
end

function OptionsPrivate.DuplicateCollapseData(id, namespace, path)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    if (collapsedOptions[id][namespace][path]) then
      tinsert(collapsedOptions[id][namespace], path + 1, CopyTable(collapsedOptions[id][namespace][path]))
    end
  else
    local tmp = collapsedOptions[id][namespace]
    local lastKey = tremove(path)
    for _, key in ipairs(path) do
      tmp[key] = tmp[key] or {}
      tmp = tmp[key]
    end

    if (tmp[lastKey]) then
      tinsert(tmp, lastKey + 1, CopyTable(tmp[lastKey]))
    end
  end
end

function OptionsPrivate.AddTextFormatOption(input, withHeader, get, addOption, hidden, setHidden,
                                            withoutColor, index, total)
  local headerOption
  if withHeader and (not index or index == 1) then
    headerOption =  {
      type = "execute",
      control = "WeakAurasExpandSmall",
      name = L["|cffffcc00Format Options|r"],
      width = WeakAuras.doubleWidth,
      func = function(info, button)
        setHidden(not hidden())
      end,
      image = function()
        return hidden() and "collapsed" or "expanded"
      end,
      imageWidth = 15,
      imageHeight = 15,
      arg = {
        expanderName = tostring(addOption)
      }
    }
    addOption("header", headerOption)
  else
    hidden = false
  end


  local seenSymbols = {}

  local parseFn = function(symbol)
    if not seenSymbols[symbol] then
      local _, sym = string.match(symbol, "(.+)%.(.+)")
      sym = sym or symbol

      if sym == "i" then
        -- No special options for these
      else
        addOption(symbol .. "desc", {
          type = "description",
          name = L["Format for %s"]:format("%" .. symbol),
          width = WeakAuras.normalWidth,
          hidden = hidden
        })
        addOption(symbol .. "_format", {
          type = "select",
          name = L["Format"],
          width = WeakAuras.normalWidth,
          values = OptionsPrivate.Private.format_types_display,
          hidden = hidden,
          reloadOptions = true
        })

        local selectedFormat = get(symbol .. "_format")
        if (OptionsPrivate.Private.format_types[selectedFormat]) then
          OptionsPrivate.Private.format_types[selectedFormat].AddOptions(symbol, hidden, addOption, get, withoutColor)
        end
        seenSymbols[symbol] = true
      end
    end
  end

  if type(input) == "table" then
    for _, txt in ipairs(input) do
      OptionsPrivate.Private.ParseTextStr(txt, parseFn)
    end
  else
    OptionsPrivate.Private.ParseTextStr(input, parseFn)
  end

  if withHeader and (not index or index == total) then
    addOption("header_anchor",
    {
      type = "description",
      name = "",
      control = "WeakAurasExpandAnchor",
      arg = {
        expanderName = tostring(addOption)
      }
    }

  )
  end

  if not next(seenSymbols) and headerOption and not index then
    headerOption.hidden = true
  end

  return next(seenSymbols) ~= nil
end
