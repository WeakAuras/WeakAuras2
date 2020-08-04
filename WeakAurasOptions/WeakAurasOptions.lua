if not WeakAuras.IsCorrectVersion() then return end

-- Lua APIs
local tinsert, tremove, wipe = table.insert, table.remove, wipe
local pairs, type, unpack = pairs, type, unpack
local loadstring, error = loadstring, error
local coroutine = coroutine
local _G = _G

-- WoW APIs
local InCombatLockdown = InCombatLockdown
local CreateFrame, IsAddOnLoaded, LoadAddOn = CreateFrame, IsAddOnLoaded, LoadAddOn

local AceGUI = LibStub("AceGUI-3.0")

local WeakAuras = WeakAuras
local L = WeakAuras.L
local ADDON_NAME = "WeakAurasOptions";

local dynFrame = WeakAuras.dynFrame;
WeakAuras.transmitCache = {};

local displayButtons = {};
WeakAuras.displayButtons = displayButtons;

local aceOptions = {}
WeakAuras.aceOptions = aceOptions

local loaded = WeakAuras.loaded;
local spellCache = WeakAuras.spellCache;
local savedVars = {};
WeakAuras.savedVars = savedVars;

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
WeakAuras.tempGroup = tempGroup;

function WeakAuras.DuplicateAura(data, newParent)
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

  local newData = {}
  WeakAuras.DeepCopy(data, newData)
  newData.id = new_id
  newData.parent = nil
  newData.uid = WeakAuras.GenerateUniqueID()
  if newData.controlledChildren then
    newData.controlledChildren = {}
  end
  WeakAuras.Add(newData)
  WeakAuras.NewDisplayButton(newData)
  if(newParent or data.parent) then
    local parentId = newParent or data.parent
    local parentData = WeakAuras.GetData(parentId)
    local index
    if newParent then
      index = #parentData.controlledChildren
    else
      index = tIndexOf(parentData.controlledChildren, data.id)
    end
    if(index) then
      tinsert(parentData.controlledChildren, index + 1, newData.id)
      newData.parent = parentId
      WeakAuras.Add(parentData)
      WeakAuras.Add(newData)

      for index, id in pairs(parentData.controlledChildren) do
        local childButton = WeakAuras.GetDisplayButton(id)
        childButton:SetGroup(parentData.id, parentData.regionType == "dynamicgroup")
        childButton:SetGroupOrder(index, #parentData.controlledChildren)
      end

      local button = WeakAuras.GetDisplayButton(parentData.id)
      button.callbacks.UpdateExpandButton()
      WeakAuras.UpdateDisplayButton(parentData)
      WeakAuras.ClearOptions(parentData.id)
    end
  end
  return newData.id
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

function WeakAuras.MultipleDisplayTooltipDesc()
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
local reopenAfterCombat = false;
local loadedFrame = CreateFrame("FRAME");
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

function WeakAuras.MultipleDisplayTooltipMenu()
  local frame = frame;
  local menu = {
    {
      text = L["Add to new Group"],
      notCheckable = 1,
      func = function()
        local data = {
          id = WeakAuras.FindUnusedId(tempGroup.controlledChildren[1].." Group"),
          regionType = "group",
        };
        WeakAuras.Add(data);
        WeakAuras.NewDisplayButton(data);

        for index, childId in pairs(tempGroup.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          tinsert(data.controlledChildren, childId);
          childData.parent = data.id;
          WeakAuras.Add(data);
          WeakAuras.Add(childData);
          WeakAuras.ClearOptions(childData.id)
        end

        for index, id in pairs(data.controlledChildren) do
          local childButton = WeakAuras.GetDisplayButton(id);
          childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
          childButton:SetGroupOrder(index, #data.controlledChildren);
        end

        local button = WeakAuras.GetDisplayButton(data.id);
        button.callbacks.UpdateExpandButton();
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.SortDisplayButtons();
        button:Expand();
      end
    },
    {
      text = L["Add to new Dynamic Group"],
      notCheckable = 1,
      func = function()
        local data = {
          id = WeakAuras.FindUnusedId(tempGroup.controlledChildren[1].." Group"),
          regionType = "dynamicgroup",
        };

        WeakAuras.Add(data);
        WeakAuras.NewDisplayButton(data);

        for index, childId in pairs(tempGroup.controlledChildren) do
          local childData = WeakAuras.GetData(childId);
          tinsert(data.controlledChildren, childId);
          childData.parent = data.id;
          childData.xOffset = 0;
          childData.yOffset = 0;
          WeakAuras.Add(data);
          WeakAuras.Add(childData);
        end

        for index, id in pairs(data.controlledChildren) do
          local childButton = WeakAuras.GetDisplayButton(id);
          childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
          childButton:SetGroupOrder(index, #data.controlledChildren);
        end

        local button = WeakAuras.GetDisplayButton(data.id);
        button.callbacks.UpdateExpandButton();
        WeakAuras.UpdateDisplayButton(data);
        WeakAuras.SortDisplayButtons();
        button:Expand();
        WeakAuras.PickDisplay(data.id);
      end
    },
    {
      text = L["Duplicate All"],
      notCheckable = 1,
      func = function()
        local toDuplicate = {};
        for index, id in pairs(tempGroup.controlledChildren) do
          toDuplicate[index] = id;
        end

        local duplicated = {};

        for index, id in ipairs(toDuplicate) do
          local childData = WeakAuras.GetData(id);
          duplicated[index] = WeakAuras.DuplicateAura(childData);
        end

        WeakAuras.ClearPicks();
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
        for index, id in pairs(tempGroup.controlledChildren) do
          local childData = WeakAuras.GetData(id);
          toDelete[index] = childData;
          if(childData.parent) then
            parents[childData.parent] = true;
          end
        end
        WeakAuras.ConfirmDelete(toDelete, parents)
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
  local anyGrouped = false;
  for index, id in pairs(tempGroup.controlledChildren) do
    local childData = WeakAuras.GetData(id);
    if(childData and childData.parent) then
      anyGrouped = true;
      break;
    end
  end
  if(anyGrouped) then
    menu[1].notClickable = 1;
    menu[1].text = "|cFF777777"..menu[1].text;
    menu[2].notClickable = 1;
    menu[2].text = "|cFF777777"..menu[2].text;
  end
  return menu;
end

function WeakAuras.DeleteOption(data, massDelete)
  local id = data.id;
  local parentData;
  if(data.parent) then
    parentData = db.displays[data.parent];
  end

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

  WeakAuras.CollapseAllClones(id);
  WeakAuras.ClearOptions(id)

  frame:ClearPicks();
  WeakAuras.Delete(data);

  if(displayButtons[id])then
    frame.buttonsScroll:DeleteChild(displayButtons[id]);
    displayButtons[id] = nil;
  end

  if(parentData and parentData.controlledChildren and not massDelete) then
    for index, childId in pairs(parentData.controlledChildren) do
      local childButton = displayButtons[childId];
      if(childButton) then
        childButton:SetGroupOrder(index, #parentData.controlledChildren);
      end
    end
    WeakAuras.Add(parentData);
    WeakAuras.ClearAndUpdateOptions(parentData.id);
    WeakAuras.UpdateDisplayButton(parentData);
  end
end

StaticPopupDialogs["WEAKAURAS_CONFIRM_DELETE"] = {
  text = "",
  button1 = L["Delete"],
  button2 = L["Cancel"],
  OnAccept = function(self)
    if self.data then
      for _, auraData in pairs(self.data.toDelete) do
        WeakAuras.DeleteOption(auraData, true)
      end
      if self.data.parents then
        for id in pairs(self.data.parents) do
          local parentData = WeakAuras.GetData(id)
          local parentButton = WeakAuras.GetDisplayButton(id)
          WeakAuras.UpdateGroupOrders(parentData)
          if(#parentData.controlledChildren == 0) then
            parentButton:DisableExpand()
          else
            parentButton:EnableExpand()
          end
          parentButton:SetNormalTooltip()
          WeakAuras.Add(parentData)
          WeakAuras.ClearAndUpdateOptions(parentData.id)
          WeakAuras.UpdateDisplayButton(parentData)
        end
      end
      WeakAuras.SortDisplayButtons()
    end
  end,
  OnCancel = function(self)
    if self.data.parents then
      for id in pairs(self.data.parents) do
        local parentRegion = WeakAuras.GetRegion(id)
        if parentRegion.Resume then
          parentRegion:Resume()
        end
      end
    end
    self.data = nil
  end,
  showAlert = true,
  whileDead = true,
  preferredindex = STATICPOPUP_NUMDIALOGS,
}

function WeakAuras.ConfirmDelete(toDelete, parents)
  if toDelete then
    local warningForm = L["You are about to delete %d aura(s). |cFFFF0000This cannot be undone!|r Would you like to continue?"]
    StaticPopupDialogs["WEAKAURAS_CONFIRM_DELETE"].text = warningForm:format(#toDelete)
    StaticPopup_Show("WEAKAURAS_CONFIRM_DELETE", "", "", {toDelete = toDelete, parents = parents})
  end
end

function WeakAuras.OptionsFrame()
  if(frame) then
    return frame;
  else
    return nil;
  end
end

function WeakAuras.ToggleOptions(msg)
  if(frame and frame:IsVisible()) then
    WeakAuras.HideOptions();
  elseif (InCombatLockdown()) then
    WeakAuras.prettyPrint(L["Options will open after combat ends."])
    reopenAfterCombat = true;
  else
    WeakAuras.ShowOptions(msg);
  end
end

function WeakAuras.UpdateCloneConfig(data)
  if(WeakAuras.CanHaveClones(data)) then
    local cloneRegion = WeakAuras.EnsureClone(data.id, 1);
    cloneRegion:Expand();

    cloneRegion = WeakAuras.EnsureClone(data.id, 2);
    cloneRegion:Expand();
  end
end

function WeakAuras.ShowOptions(msg)
  local firstLoad = not(frame);
  WeakAuras.Pause();
  WeakAuras.SetFakeStates()

  WeakAuras.spellCache.Build()

  if (firstLoad) then
    frame = WeakAuras.CreateFrame();
    frame.buttonsScroll.frame:Show();
    WeakAuras.LayoutDisplayButtons(msg);
  end
  frame.buttonsScroll.frame:Show();

  if (frame.needsSort) then
    WeakAuras.SortDisplayButtons();
    frame.needsSort = nil;
  end

  frame:Show();

  if (WeakAuras.mouseFrame) then
    WeakAuras.mouseFrame:OptionsOpened();
  end

  if (WeakAuras.personalRessourceDisplayFrame) then
    WeakAuras.personalRessourceDisplayFrame:OptionsOpened();
  end

  if not(firstLoad) then
    -- Show what was last shown
    WeakAuras.PauseAllDynamicGroups();
    for id, button in pairs(displayButtons) do
      if (button:GetVisibility() > 0) then
        button:PriorityShow(button:GetVisibility());
      end
    end
    WeakAuras.ResumeAllDynamicGroups();
  end

  if (frame.pickedDisplay) then
    if (WeakAuras.IsPickedMultiple()) then
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

function WeakAuras.GetSortedOptionsLists()
  local loadedSorted, unloadedSorted = {}, {};
  local to_sort = {};
  for id, data in pairs(db.displays) do
    if(data.parent) then
    -- Do nothing; children will be added later
    elseif(loaded[id]) then
      tinsert(to_sort, id);
    end
  end
  table.sort(to_sort, function(a, b) return a < b end);
  for _, id in ipairs(to_sort) do
    tinsert(loadedSorted, id);
    local data = WeakAuras.GetData(id);
    local controlledChildren = data.controlledChildren;
    if(controlledChildren) then
      for _, childId in pairs(controlledChildren) do
        tinsert(loadedSorted, childId);
      end
    end
  end

  wipe(to_sort);
  for id, data in pairs(db.displays) do
    if(data.parent) then
    -- Do nothing; children will be added later
    elseif not(loaded[id]) then
      tinsert(to_sort, id);
    end
  end
  table.sort(to_sort, function(a, b) return a < b end);
  for _, id in ipairs(to_sort) do
    tinsert(unloadedSorted, id);
    local data = WeakAuras.GetData(id);
    local controlledChildren = data.controlledChildren;
    if(controlledChildren) then
      for _, childId in pairs(controlledChildren) do
        tinsert(unloadedSorted, childId);
      end
    end
  end

  return loadedSorted, unloadedSorted;
end

function WeakAuras.LayoutDisplayButtons(msg)
  local total = 0;
  for _,_ in pairs(db.displays) do
    total = total + 1;
  end

  local loadedSorted, unloadedSorted = WeakAuras.GetSortedOptionsLists();

  frame:SetLoadProgressVisible(true)
  --frame.buttonsScroll:AddChild(frame.newButton);
  --if(frame.addonsButton) then
  --  frame.buttonsScroll:AddChild(frame.addonsButton);
  --end
  frame.buttonsScroll:AddChild(frame.loadedButton);
  frame.buttonsScroll:AddChild(frame.unloadedButton);

  local func2 = function()
    local num = frame.loadProgressNum or 0;
    for index, id in pairs(unloadedSorted) do
      local data = WeakAuras.GetData(id);
      if(data) then
        WeakAuras.EnsureDisplayButton(data);
        WeakAuras.UpdateDisplayButton(data);

        frame.buttonsScroll:AddChild(displayButtons[data.id]);
        if(WeakAuras.regions[data.id].region.SetStacks) then
          WeakAuras.regions[data.id].region:SetStacks(1);
        end

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
    WeakAuras.SortDisplayButtons(msg);

    WeakAuras.PauseAllDynamicGroups();
    if (WeakAuras.IsOptionsOpen()) then
      for id, button in pairs(displayButtons) do
        if(loaded[id] ~= nil) then
          button:PriorityShow(1);
        end
        if WeakAurasCompanion and not button.data.parent then
          -- initialize update icons on top level buttons
          button:RefreshUpdate()
        end
      end
    end
    WeakAuras.ResumeAllDynamicGroups();

    frame:SetLoadProgressVisible(false)
  end

  local func1 = function()
    local num = frame.loadProgressNum or 0;
    frame.buttonsScroll:PauseLayout()
    for index, id in pairs(loadedSorted) do
      local data = WeakAuras.GetData(id);
      if(data) then
        WeakAuras.EnsureDisplayButton(data);
        WeakAuras.UpdateDisplayButton(data);

        local button = displayButtons[data.id]
        frame.buttonsScroll:AddChild(button);
        if(WeakAuras.regions[data.id].region.SetStacks) then
          WeakAuras.regions[data.id].region:SetStacks(1);
        end

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
    dynFrame:AddAction("LayoutDisplayButtons2", co2);
  end

  local co1 = coroutine.create(func1);
  dynFrame:AddAction("LayoutDisplayButtons1", co1);
end

function WeakAuras.UpdateOptions()
  frame:UpdateOptions()
end

function WeakAuras.ClearAndUpdateOptions(id, clearChildren)
  frame:ClearAndUpdateOptions(id, clearChildren)
end

function WeakAuras.ClearOptions(id)
  frame:ClearOptions(id)
end

function WeakAuras.FillOptions()
  frame:FillOptions()
end

function WeakAuras.GetSubOptions(id, subOption)
  return frame:GetSubOptions(id, subOption)
end

function WeakAuras.EnsureOptions(data, subOption)
  return frame:EnsureOptions(data, subOption)
end

function WeakAuras.GetPickedDisplay()
  return frame:GetPickedDisplay()
end

function WeakAuras.GetSpellTooltipText(id)
  local tooltip = WeakAuras.GetHiddenTooltip();
  tooltip:SetSpellByID(id);
  local lines = { tooltip:GetRegions() };
  local i = 1;
  local tooltipText = "";
  while(lines[i]) do
    if(lines[i]:GetObjectType() == "FontString") then
      if(lines[i]:GetText()) then
        if(tooltipText == "") then
          tooltipText = lines[i]:GetText();
        else
          tooltipText = tooltipText.." - "..lines[i]:GetText();
        end
      end
    end
    i = i + 1;
  end
  tooltipText = tooltipText or L["No tooltip text"];
  return tooltipText;
end

function WeakAuras.OpenTextEditor(...)
  frame.texteditor:Open(...);
end

function WeakAuras.ExportToString(id)
  frame.importexport:Open("export", id);
end

function WeakAuras.ExportToTable(id)
  frame.importexport:Open("table", id);
end

function WeakAuras.ImportFromString()
  frame.importexport:Open("import");
end

function WeakAuras.CloseImportExport()
  frame.codereview:Close();
  frame.importexport:Close();
end

function WeakAuras.ConvertDisplay(data, newType)
  local id = data.id;
  local visibility = displayButtons[id]:GetVisibility();
  displayButtons[id]:PriorityHide(0);

  WeakAuras.regions[id].region:Collapse();
  WeakAuras.CollapseAllClones(id);

  WeakAuras.Convert(data, newType);
  displayButtons[id]:SetViewRegion(WeakAuras.regions[id].region);
  displayButtons[id]:Initialize();
  displayButtons[id]:PriorityShow(visibility);
  frame:ClearOptions(id)
  frame:FillOptions();
  WeakAuras.UpdateDisplayButton(data);
  WeakAuras.SetMoverSizer(id)
  WeakAuras.ResetMoverSizer();
  WeakAuras.SortDisplayButtons()
end

function WeakAuras.NewDisplayButton(data)
  local id = data.id;
  WeakAuras.ScanForLoads({[id] = true});
  WeakAuras.EnsureDisplayButton(db.displays[id]);
  WeakAuras.UpdateDisplayButton(db.displays[id]);
  frame.buttonsScroll:AddChild(displayButtons[id]);
  WeakAuras.SortDisplayButtons();
end

function WeakAuras.UpdateGroupOrders(data)
  if(data.controlledChildren) then
    local total = #data.controlledChildren;
    for index, id in pairs(data.controlledChildren) do
      local button = WeakAuras.GetDisplayButton(id);
      button:SetGroupOrder(index, total);
    end
  end
end

function WeakAuras.UpdateButtonsScroll()
  if WeakAuras.IsOptionsProcessingPaused() then return end
  frame.buttonsScroll:DoLayout()
end

local previousFilter;
function WeakAuras.SortDisplayButtons(filter, overrideReset, id)
  if (WeakAuras.IsOptionsProcessingPaused()) then
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
  --tinsert(frame.buttonsScroll.children, frame.newButton);
  --if(frame.addonsButton) then
  --  tinsert(frame.buttonsScroll.children, frame.addonsButton);
  --end
  tinsert(frame.buttonsScroll.children, frame.loadedButton);
  local numLoaded = 0;
  local to_sort = {};
  local children = {};
  local containsFilter = false;

  local visible = {}

  for id, child in pairs(displayButtons) do
    containsFilter = not filter or filter == "";
    local data = WeakAuras.GetData(id);
    if not(data) then
      print("|cFF8800FFWeakAuras|r: No data for", id);
    else
      if(not containsFilter and data.controlledChildren) then
        for index, childId in pairs(data.controlledChildren) do
          if(childId:lower():find(filter, 1, true)) then
            containsFilter = true;
            break;
          end
        end
      end
      if(
        frame.loadedButton:GetExpanded()
        and (not filter or id:lower():find(filter, 1, true) or containsFilter)
        ) then

        local group = child:GetGroup();
        if(group) then
          -- In a Group
          if(loaded[group]) then
            if(loaded[id]) then
              child:EnableLoaded();
            else
              child:DisableLoaded();
            end
            children[group] = children[group] or {};
            visible[id] = true
            tinsert(children[group], id);
          end
        else
          -- Top Level
          if(loaded[id] ~= nil) then
            if(loaded[id]) then
              child:EnableLoaded();
            else
              child:DisableLoaded();
            end
            visible[id] = true
            tinsert(to_sort, child);
          end
        end
      end
    end
  end
  table.sort(to_sort, function(a, b) return a:GetTitle() < b:GetTitle() end);

  for _, child in ipairs(to_sort) do
    child.frame:Show();
    if child.AcquireThumbnail then
      child:AcquireThumbnail()
    end
    tinsert(frame.buttonsScroll.children, child);
    local controlledChildren = children[child:GetTitle()];
    if(controlledChildren) then
      table.sort(controlledChildren, function(a, b) return displayButtons[a]:GetGroupOrder() <  displayButtons[b]:GetGroupOrder(); end);
      for _, groupchild in ipairs(controlledChildren) do
        if(child:GetExpanded() and visible[groupchild]) then
          displayButtons[groupchild].frame:Show();
          if displayButtons[groupchild].AcquireThumbnail then
            displayButtons[groupchild]:AcquireThumbnail()
          end
          tinsert(frame.buttonsScroll.children, displayButtons[groupchild]);
        end
      end
    end
  end

  -- Now handle unloaded auras
  tinsert(frame.buttonsScroll.children, frame.unloadedButton);
  local numUnloaded = 0;
  wipe(to_sort);
  wipe(children);

  for id, child in pairs(displayButtons) do
    containsFilter = not filter or filter == "";
    local data = WeakAuras.GetData(id);
    if(not containsFilter and data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        if(childId:lower():find(filter, 1, true)) then
          containsFilter = true;
          break;
        end
      end
    end
    if(
      frame.unloadedButton:GetExpanded()
      and (not filter or id:lower():find(filter, 1, true) or containsFilter)
      ) then
      local group = child:GetGroup();
      if(group) then
        if not(loaded[group]) then
          if(loaded[id]) then
            child:EnableLoaded();
          else
            child:DisableLoaded();
          end
          children[group] = children[group] or {};
          visible[id] = true
          tinsert(children[group], id);
        end
      else
        if(loaded[id] == nil) then
          child:DisableLoaded();
          visible[id] = true
          tinsert(to_sort, child);
        end
      end
    end
  end
  table.sort(to_sort, function(a, b) return a:GetTitle() < b:GetTitle() end);

  for _, child in ipairs(to_sort) do
    child.frame:Show();
    if child.AcquireThumbnail then
      child:AcquireThumbnail()
    end
    tinsert(frame.buttonsScroll.children, child);
    local controlledChildren = children[child:GetTitle()];
    if(controlledChildren) then
      table.sort(controlledChildren, function(a, b) return  displayButtons[a]:GetGroupOrder() <  displayButtons[b]:GetGroupOrder(); end);
      for _, groupchild in ipairs(controlledChildren) do
        if(child:GetExpanded() and visible[groupchild]) then
          displayButtons[groupchild].frame:Show();
          if displayButtons[groupchild].AcquireThumbnail then
            displayButtons[groupchild]:AcquireThumbnail()
          end
          tinsert(frame.buttonsScroll.children, displayButtons[groupchild]);
        end
      end
    end
  end

  -- Hiding the other buttons
  for id, child in pairs(displayButtons) do
    local group = child:GetGroup();
    local groupVisible = not group or visible[group] and displayButtons[group]:GetExpanded()
    if(not groupVisible or not visible[id]) then
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

WeakAuras.afterScanForLoads = function()
  if(frame) then
    if (frame:IsVisible()) then
      WeakAuras.SortDisplayButtons(nil, true);
    else
      frame.needsSort = true;
    end
  end
end

function WeakAuras.IsPickedMultiple()
  if(frame.pickedDisplay == tempGroup) then
    return true;
  else
    return false;
  end
end

function WeakAuras.IsDisplayPicked(id)
  if(frame.pickedDisplay == tempGroup) then
    for index, childId in pairs(tempGroup.controlledChildren) do
      if(id == childId) then
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
  WeakAuras.UpdateButtonsScroll()
end

function WeakAuras.PickAndEditDisplay(id)
  frame:PickDisplay(id);
  displayButtons[id].callbacks.OnRenameClick();
  WeakAuras.UpdateButtonsScroll()
end

function WeakAuras.ClearPick(id)
  frame:ClearPick(id);
end

function WeakAuras.ClearPicks()
  frame:ClearPicks();
end

function WeakAuras.PickDisplayMultiple(id)
  frame:PickDisplayMultiple(id);
end

function WeakAuras.PickDisplayMultipleShift(target)
  if (frame.pickedDisplay) then
    -- get first aura selected
    local first;
    if (WeakAuras.IsPickedMultiple()) then
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
                table.insert(batchSelection, current);
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
        if #batchSelection > 0 then
          frame:PickDisplayBatch(batchSelection);
        end
      end
    end
  else
    WeakAuras.PickDisplay(target);
  end
end

function WeakAuras.GetDisplayButton(id)
  if(id and displayButtons[id]) then
    return displayButtons[id];
  end
end

function WeakAuras.AddDisplayButton(data)
  WeakAuras.EnsureDisplayButton(data);
  WeakAuras.UpdateDisplayButton(data);
  frame.buttonsScroll:AddChild(displayButtons[data.id]);
  if(WeakAuras.regions[data.id] and WeakAuras.regions[data.id].region.SetStacks) then
    WeakAuras.regions[data.id].region:SetStacks(1);
  end
end

function WeakAuras.EnsureDisplayButton(data)
  local id = data.id;
  if not(displayButtons[id]) then
    displayButtons[id] = AceGUI:Create("WeakAurasDisplayButton");
    if(displayButtons[id]) then
      displayButtons[id]:SetData(data);
      displayButtons[id]:Initialize();
    else
      print("|cFF8800FFWeakAuras|r: Error creating button for", id);
    end
  end
end

function WeakAuras.SetGrouping(data)
  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0 and data) then
    local children = {};
    -- set grouping for selected buttons
    for index, childId in ipairs(tempGroup.controlledChildren) do
      local button = WeakAuras.GetDisplayButton(childId);
      button:SetGrouping(tempGroup.controlledChildren, true);
      children[childId] = true;
    end
    -- set grouping for non selected buttons
    for id, button in pairs(displayButtons) do
      if not children[button.data.id] then
        button:SetGrouping(tempGroup.controlledChildren);
      end
    end
  else
    for id, button in pairs(displayButtons) do
      button:SetGrouping(data);
    end
  end
end

function WeakAuras.Ungroup(data)
  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0) then
    for index, childId in ipairs(tempGroup.controlledChildren) do
      local button = WeakAuras.GetDisplayButton(childId);
      button:Ungroup(data);
    end
  else
    local button = WeakAuras.GetDisplayButton(data.id);
    button:Ungroup(data);
  end
  WeakAuras.FillOptions()
end

function WeakAuras.SetDragging(data, drop)
  WeakAuras_DropDownMenu:Hide()
  if (frame.pickedDisplay == tempGroup and #tempGroup.controlledChildren > 0) then
    local children = {};
    local size = #tempGroup.controlledChildren;
    -- set dragging for selected buttons in reverse for ordering
    for index = size, 1, -1 do
      local childId = tempGroup.controlledChildren[index];
      local button = WeakAuras.GetDisplayButton(childId);
      button:SetDragging(data, drop, size);
      children[childId] = true;
    end
    -- set dragging for non selected buttons
    for id, button in pairs(displayButtons) do
      if not children[button.data.id] then
        button:SetDragging(data, drop);
      end
    end
  else
    for id, button in pairs(displayButtons) do
      button:SetDragging(data, drop);
    end
  end
end

function WeakAuras.DropIndicator()
  local indicator = frame.dropIndicator
  if not indicator then
    indicator = CreateFrame("Frame", "WeakAuras_DropIndicator")
    indicator:SetHeight(4)
    indicator:SetFrameStrata("FULLSCREEN")

    local texture = indicator:CreateTexture(nil, "FULLSCREEN")
    texture:SetBlendMode("ADD")
    texture:SetAllPoints(indicator)
    texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")

    local icon = indicator:CreateTexture(nil, "OVERLAY")
    icon:SetSize(16,16)
    icon:SetPoint("CENTER", indicator)

    indicator.icon = icon
    indicator.texture = texture
    frame.dropIndicator = indicator
    indicator:Hide()
  end
  return indicator
end

function WeakAuras.UpdateDisplayButton(data)
  local id = data.id;
  local button = displayButtons[id];
  if (button) then
    button:UpdateThumbnail()
    if WeakAurasCompanion and button:IsGroup() then
      button:RefreshUpdate()
    end
    -- TODO: remove this once legacy aura trigger is removed
    button:RefreshBT2UpgradeIcon()
  end
end

function WeakAuras.UpdateThumbnail(data)
  local id = data.id
  local button = displayButtons[id]
  if (not button) then
    return
  end
  button:UpdateThumbnail()
end

function WeakAuras.OpenTexturePicker(data, field, textures, stopMotion)
  frame.texturePicker:Open(data, field, textures, stopMotion);
end

function WeakAuras.OpenIconPicker(data, field, groupIcon)
  frame.iconPicker:Open(data, field, groupIcon);
end

function WeakAuras.OpenModelPicker(data, field, parentData)
  if not(IsAddOnLoaded("WeakAurasModelPaths")) then
    local loaded, reason = LoadAddOn("WeakAurasModelPaths");
    if not(loaded) then
      reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
      print(WeakAuras.printPrefix .. "ModelPaths could not be loaded, the addon is " .. reason);
      WeakAuras.ModelPaths = {};
    end
    frame.modelPicker.modelTree:SetTree(WeakAuras.ModelPaths);
  end
  frame.modelPicker:Open(data, field, parentData);
end

function WeakAuras.OpenCodeReview(data)
  frame.codereview:Open(data);
end

function WeakAuras.CloseCodeReview(data)
  frame.codereview:Close();
end

function WeakAuras.OpenTriggerTemplate(data, targetId)
  if not(IsAddOnLoaded("WeakAurasTemplates")) then
    local loaded, reason = LoadAddOn("WeakAurasTemplates");
    if not(loaded) then
      reason = string.lower("|cffff2020" .. _G["ADDON_" .. reason] .. "|r.")
      print(WeakAuras.printPrefix .. "Templates could not be loaded, the addon is " .. reason);
      return;
    end
    frame.newView = WeakAuras.CreateTemplateView(frame);
  end
  frame.newView.targetId = targetId;
  frame.newView:Open(data);
end

function WeakAuras.ResetMoverSizer()
  if(frame and frame.mover and frame.moversizer and frame.mover.moving.region and frame.mover.moving.data) then
    frame.moversizer:SetToRegion(frame.mover.moving.region, frame.mover.moving.data);
  end
end

function WeakAuras.SetMoverSizer(id)
  if WeakAuras.regions[id].region.toShow then
    frame.moversizer:SetToRegion(WeakAuras.regions[id].region, db.displays[id])
  else
    if WeakAuras.clones[id] then
      local cloneId, clone = next(WeakAuras.clones[id])
      if clone then
        frame.moversizer:SetToRegion(clone, db.displays[id])
      end
    end
  end
end

function WeakAuras.GetMoverSizerId()
  return frame.moversizer:GetCurrentId()
end

function WeakAuras.ShowCloneDialog(data)
  if(
    not(
    data.parent
    and WeakAuras.GetData(data.parent)
    and WeakAuras.GetData(data.parent).regionType == "dynamicgroup"
    )
    and not(odb.preventCloneDialog)
    ) then
    StaticPopupDialogs["WEAKAURAS_CLONE_OPTION_ENABLED"] = {
      text = L["Clone option enabled dialog"],
      button1 = L["Yes"],
      button2 = L["No"],
      button3 = L["Never"],
      OnAccept = function()
        local parentData = {
          id = WeakAuras.FindUnusedId(data.id.." Group"),
          regionType = "dynamicgroup",
        };
        WeakAuras.Add(parentData);
        WeakAuras.NewDisplayButton(parentData);

        tinsert(parentData.controlledChildren, data.id);
        data.parent = parentData.id;
        WeakAuras.Add(parentData);
        WeakAuras.Add(data);

        local button = WeakAuras.GetDisplayButton(data.id);
        button:SetGroup(parentData.id, true);
        button:SetGroupOrder(1, #parentData.controlledChildren);

        local parentButton = WeakAuras.GetDisplayButton(parentData.id);
        parentButton.callbacks.UpdateExpandButton();
        WeakAuras.UpdateDisplayButton(parentData);
        WeakAuras.ClearAndUpdateOptions(parentData.id);
        WeakAuras.SortDisplayButtons();
        parentButton:Expand();
      end,
      OnCancel = function()
      -- do nothing
      end,
      OnAlt = function()
        odb.preventCloneDialog = true
      end,
      hideOnEscape = true,
      whileDead = true,
      timeout = 0,
      preferredindex = STATICPOPUP_NUMDIALOGS
    };

    StaticPopup_Show("WEAKAURAS_CLONE_OPTION_ENABLED");
  end
end

local function AddDefaultSubRegions(data)
  data.subRegions = data.subRegions or {}
  for type, subRegionData in pairs(WeakAuras.subRegionTypes) do
    if subRegionData.addDefaultsForNewAura then
      subRegionData.addDefaultsForNewAura(data)
    end
  end
end

function WeakAuras.NewAura(sourceData, regionType, targetId)
  local function ensure(t, k, v)
    return t and k and v and t[k] == v
  end
  local new_id = WeakAuras.FindUnusedId("New")
  local data = {id = new_id, regionType = regionType, uid = WeakAuras.GenerateUniqueID()}
  WeakAuras.DeepCopy(WeakAuras.data_stub, data);
  if (sourceData) then
    WeakAuras.DeepCopy(sourceData, data);
  end
  data.internalVersion = WeakAuras.InternalVersion();
  WeakAuras.validate(data, WeakAuras.regionTypes[regionType].default);

  AddDefaultSubRegions(data)

  if (data.regionType ~= "group" and data.regionType ~= "dynamicgroup" and targetId) then
    local target = WeakAuras.GetDisplayButton(targetId);
    local group
    if (target) then
      if (target:IsGroup()) then
        group = target;
      else
        group = WeakAuras.GetDisplayButton(target.data.parent);
      end
      if (group) then
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
        WeakAuras.NewDisplayButton(data);
        WeakAuras.UpdateGroupOrders(group.data);
        WeakAuras.ClearOptions(group.data.id);
        WeakAuras.UpdateDisplayButton(group.data);
        group.callbacks.UpdateExpandButton();
        group:Expand();
        group:ReloadTooltip();
        WeakAuras.PickAndEditDisplay(data.id);
      else
        -- move source into the top-level list
        WeakAuras.Add(data);
        WeakAuras.NewDisplayButton(data);
        WeakAuras.PickAndEditDisplay(data.id);
      end
    else
      error("Calling 'WeakAuras.NewAura' with invalid groupId. Reload your UI to fix the display list.")
    end
  else
    -- move source into the top-level list
    WeakAuras.Add(data);
    WeakAuras.NewDisplayButton(data);
    WeakAuras.PickAndEditDisplay(data.id);
  end
end

local collapsedOptions = {}
local collapsed = {} -- magic value
WeakAuras.collapsedOptions = collapsedOptions
function WeakAuras.ResetCollapsed(id, namespace)
  if id then
    if namespace and collapsedOptions[id] then
      collapsedOptions[id][namespace] = nil
    else
      collapsedOptions[id] = nil
    end
  end
end

function WeakAuras.IsCollapsed(id, namespace, path, default)
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

function WeakAuras.SetCollapsed(id, namespace, path, v)
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

function WeakAuras.MoveCollapseDataUp(id, namespace, path)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    collapsedOptions[id][namespace][path], collapsedOptions[id][namespace][path - 1] = collapsedOptions[id][namespace][path - 1], collapsedOptions[id][namespace][path]
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

function WeakAuras.MoveCollapseDataDown(id, namespace, path)
  collapsedOptions[id] = collapsedOptions[id] or {}
  collapsedOptions[id][namespace] = collapsedOptions[id][namespace] or {}
  if type(path) ~= "table" then
    collapsedOptions[id][namespace][path], collapsedOptions[id][namespace][path + 1] = collapsedOptions[id][namespace][path + 1], collapsedOptions[id][namespace][path]
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

function WeakAuras.RemoveCollapsed(id, namespace, path)
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

function WeakAuras.InsertCollapsed(id, namespace, path, value)
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

function WeakAuras.RenameCollapsedData(oldid, newid)
  collapsedOptions[newid] = collapsedOptions[oldid]
  collapsedOptions[oldid] = nil
end

function WeakAuras.DeleteCollapsedData(id)
  collapsedOptions[id] = nil
end

function WeakAuras.AddTextFormatOption(input, withHeader, get, addOption, hidden, setHidden)
  local headerOption
  if withHeader then
    headerOption =  {
      type = "execute",
      control = "WeakAurasExpandSmall",
      name = L["|cFFffcc00Format Options|r"],
      width = WeakAuras.doubleWidth,
      func = function(info, button)
        setHidden(not hidden())
      end,
      image = function()
        return hidden() and "Interface\\AddOns\\WeakAuras\\Media\\Textures\\edit" or "Interface\\AddOns\\WeakAuras\\Media\\Textures\\editdown"
      end,
      imageWidth = 24,
      imageHeight = 24
    }
    addOption("header", headerOption)
  else
    hidden = false
  end


  local seenSymbols = {}
  WeakAuras.ParseTextStr(input, function(symbol)
    if not seenSymbols[symbol] then
      local triggerNum, sym = string.match(symbol, "(.+)%.(.+)")
      sym = sym or symbol

      if sym == "c" or sym == "i" then
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
          values = WeakAuras.format_types_display,
          hidden = hidden,
          reloadOptions = true
        })

        local selectedFormat = get(symbol .. "_format")
        if (WeakAuras.format_types[selectedFormat]) then
          WeakAuras.format_types[selectedFormat].AddOptions(symbol, hidden, addOption, get)
        end

      end
    end
    seenSymbols[symbol] = true
  end)

  if not next(seenSymbols) and withHeader then
    headerOption.hidden = true
  end

  return next(seenSymbols) ~= nil
end
