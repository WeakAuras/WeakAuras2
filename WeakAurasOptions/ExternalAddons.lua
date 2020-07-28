if not WeakAuras.IsCorrectVersion() then return end
local AddonName, OptionsPrivate = ...

-- Lua APIs
local tinsert, wipe = table.insert, wipe
local pairs = pairs

local AceGUI = LibStub("AceGUI-3.0")

local collisions = WeakAuras.collisions
local displayButtons = WeakAuras.displayButtons
local savedVars = WeakAuras.savedVars

local importAddonButtons = {}
local importDisplayButtons = {}
WeakAuras.importDisplayButtons = importDisplayButtons

function WeakAuras.CreateImportButtons()
  wipe(importAddonButtons);
  wipe(importDisplayButtons);
  for addonName, addonData in pairs(WeakAuras.addons) do
    local addonButton = AceGUI:Create("WeakAurasImportButton");
    importAddonButtons[addonName] = addonButton;
    addonButton:SetTitle(addonData.displayName);
    addonButton:SetIcon(addonData.icon);
    addonButton:SetDescription(addonData.description);
    addonButton:SetClick(function()
      if(addonButton.checkbox:GetChecked()) then
        for id, data in pairs(addonData.displays) do
          if not(data.parent) then
            local childButton = importDisplayButtons[id];
            childButton.checkbox:SetChecked(true);
            WeakAuras.EnableAddonDisplay(id);
          end
        end
        for id, data in pairs(addonData.displays) do
          if(data.parent) then
            local childButton = importDisplayButtons[id];
            childButton.checkbox:SetChecked(true);
            WeakAuras.EnableAddonDisplay(id);
          end
        end
      else
        for id, data in pairs(addonData.displays) do
          if not(data.parent) then
            local childButton = importDisplayButtons[id];
            childButton.checkbox:SetChecked(false);
            WeakAuras.DisableAddonDisplay(id);
          end
        end
        for id, data in pairs(addonData.displays) do
          if(data.parent) then
            local childButton = importDisplayButtons[id];
            childButton.checkbox:SetChecked(false);
            WeakAuras.DisableAddonDisplay(id);
          end
        end
      end
      WeakAuras.ResolveCollisions(function()
        for groupId, dataFromAddon in pairs(addonData.displays) do
          if(dataFromAddon.controlledChildren) then
            local data = WeakAuras.GetData(groupId);
            if(data) then
              for index, childId in pairs(data.controlledChildren) do
                local childButton = WeakAuras.GetDisplayButton(childId);
                childButton:SetGroup(groupId, data.regionType == "dynamicgroup");
                childButton:SetGroupOrder(index, #data.controlledChildren);
              end

              local button = WeakAuras.GetDisplayButton(groupId);
              button.callbacks.UpdateExpandButton();
              WeakAuras.UpdateDisplayButton(data);
              WeakAuras.ClearAndUpdateOptions(data.id);
            end
          end
        end

        WeakAuras.ScanForLoads();
        WeakAuras.SortDisplayButtons();
      end);
    end);

    local function UpdateAddonChecked()
      local shouldBeChecked = true;
      for id, data in pairs(addonData.displays) do
        if not(WeakAuras.IsDefinedByAddon(id)) then
          shouldBeChecked = false;
          break;
        end
      end
      addonButton.checkbox:SetChecked(shouldBeChecked);
    end

    local numAddonDisplays = 0;
    for id, data in pairs(addonData.displays) do
      if(data.controlledChildren) then
        numAddonDisplays = numAddonDisplays + 1;
        local groupButton = AceGUI:Create("WeakAurasImportButton");
        importDisplayButtons[id] = groupButton;

        groupButton:SetTitle(id);
        groupButton:SetDescription(data.desc);

        local numGroupDisplays = 0;

        local function UpdateGroupChecked()
          local shouldBeChecked = true;
          for index, childId in pairs(data.controlledChildren) do
            if not(WeakAuras.IsDefinedByAddon(childId)) then
              shouldBeChecked = false;
              break;
            end
          end
          groupButton.checkbox:SetChecked(shouldBeChecked);
          UpdateAddonChecked();
        end

        for index, childId in pairs(data.controlledChildren) do
          numGroupDisplays = numGroupDisplays + 1;
          numAddonDisplays = numAddonDisplays + 1;
          local childButton = AceGUI:Create("WeakAurasImportButton");
          importDisplayButtons[childId] = childButton;

          local data = WeakAuras.addons[addonName].displays[childId];

          childButton:SetTitle(childId);
          childButton:SetDescription(data.desc);
          childButton:SetExpandVisible(false);
          childButton:SetLevel(3);

          childButton:SetClick(function()
            if(childButton.checkbox:GetChecked()) then
              WeakAuras.EnableAddonDisplay(childId);
            else
              WeakAuras.DisableAddonDisplay(childId);
            end
            WeakAuras.ResolveCollisions(function()
              WeakAuras.ScanForLoads();
              WeakAuras.SortDisplayButtons();
              UpdateGroupChecked();
            end);
          end);
          childButton.updateChecked = UpdateGroupChecked;
          childButton.checkbox:SetChecked(WeakAuras.IsDefinedByAddon(childId));
        end

        groupButton:SetClick(function()
          if(groupButton.checkbox:GetChecked()) then
            WeakAuras.EnableAddonDisplay(id);
            for index, childId in pairs(data.controlledChildren) do
              local childButton = importDisplayButtons[childId];
              childButton.checkbox:SetChecked(true);
              WeakAuras.EnableAddonDisplay(childId);
            end
          else
            WeakAuras.DisableAddonDisplay(id);
            for index, childId in pairs(data.controlledChildren) do
              local childButton = importDisplayButtons[childId];
              childButton.checkbox:SetChecked(false);
              WeakAuras.DisableAddonDisplay(childId);
            end
          end
          WeakAuras.ResolveCollisions(function()
            local data = WeakAuras.GetData(id);
            if(data) then
              for index, childId in pairs(data.controlledChildren) do
                local childButton = WeakAuras.GetDisplayButton(childId);
                childButton:SetGroup(id, data.regionType == "dynamicgroup");
                childButton:SetGroupOrder(index, #data.controlledChildren);
              end

              local button = WeakAuras.GetDisplayButton(id);
              button.callbacks.UpdateExpandButton();
              WeakAuras.UpdateDisplayButton(data);
              WeakAuras.ClearAndUpdateOptions(data.id);
            end

            WeakAuras.ScanForLoads();
            WeakAuras.SortDisplayButtons();
            UpdateAddonChecked();
          end);
        end);
        groupButton.updateChecked = UpdateAddonChecked;
        groupButton:SetExpandVisible(true);
        if(numGroupDisplays > 0) then
          groupButton:EnableExpand();
          groupButton:SetOnExpandCollapse(WeakAuras.SortImportButtons);
        end
        groupButton:SetLevel(2);
        UpdateGroupChecked();
      elseif not(importDisplayButtons[id]) then
        numAddonDisplays = numAddonDisplays + 1;
        local displayButton = AceGUI:Create("WeakAurasImportButton");
        importDisplayButtons[id] = displayButton;

        displayButton:SetTitle(id);
        displayButton:SetDescription(data.desc);
        displayButton:SetExpandVisible(false);
        displayButton:SetLevel(2);

        displayButton:SetClick(function()
          if(displayButton.checkbox:GetChecked()) then
            WeakAuras.EnableAddonDisplay(id);
          else
            WeakAuras.DisableAddonDisplay(id);
          end
          WeakAuras.ResolveCollisions(function()
            WeakAuras.SortDisplayButtons()
            UpdateAddonChecked();
          end);
        end);
        displayButton.updateChecked = UpdateAddonChecked;
        displayButton.checkbox:SetChecked(WeakAuras.IsDefinedByAddon(id));
      end
    end

    addonButton:SetExpandVisible(true);
    if(numAddonDisplays > 0) then
      addonButton:EnableExpand();
      addonButton:SetOnExpandCollapse(WeakAuras.SortImportButtons);
    end
    addonButton:SetLevel(1);
    UpdateAddonChecked();
  end
end

local container = nil;
function WeakAuras.SortImportButtons(newContainer)
  container = newContainer or container;
  wipe(container.children);
  local toSort = {};
  for addon, addonData in pairs(WeakAuras.addons) do
    container:AddChild(importAddonButtons[addon]);
    wipe(toSort);
    for id, data in pairs(addonData.displays) do
      if not(data.parent) then
        tinsert(toSort, id);
      end
    end
    table.sort(toSort, function(a, b) return a < b end);
    for index, id in ipairs(toSort) do
      if(importAddonButtons[addon]:GetExpanded()) then
        importDisplayButtons[id].frame:Show();
        container:AddChild(importDisplayButtons[id]);
      else
        importDisplayButtons[id].frame:Hide();
      end
      if(addonData.displays[id].controlledChildren) then
        for childIndex, childId in pairs(addonData.displays[id].controlledChildren) do
          if(importAddonButtons[addon]:GetExpanded() and importDisplayButtons[id]:GetExpanded()) then
            importDisplayButtons[childId].frame:Show();
            container:AddChild(importDisplayButtons[childId]);
          else
            importDisplayButtons[childId].frame:Hide();
          end
        end
      end
    end
  end

  container:DoLayout();
end

function WeakAuras.EnableAddonDisplay(id)
  local db = savedVars.db
  if not(db.registered[id]) then
    local addon, data;
    for addonName, addonData in pairs(WeakAuras.addons) do
      if(addonData.displays[id]) then
        addon = addonName;
        data = {}
        WeakAuras.DeepCopy(addonData.displays[id], data);
        break;
      end
    end

    if(db.displays[id]) then
      -- ID collision
      collisions[id] = {addon, data};
    else
      db.registered[id] = addon;
      if(data.controlledChildren) then
        wipe(data.controlledChildren);
      end
      WeakAuras.Add(data);
      WeakAuras.SyncParentChildRelationships(true);
      WeakAuras.AddDisplayButton(data);
    end
  end
end

-- This function overrides the WeakAuras.CollisionResolved that is defined in WeakAuras.lua,
-- ensuring that sidebar buttons are created properly after collision resolution
function WeakAuras.CollisionResolved(addon, data, force)
  WeakAuras.EnableAddonDisplay(data.id);
end

function WeakAuras.DisableAddonDisplay(id)
  local frame = WeakAuras.OptionsFrame()
  local db = savedVars.db
  db.registered[id] = false;
  local data = WeakAuras.GetData(id);
  if(data) then
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

    WeakAuras.Delete(data);
    WeakAuras.SyncParentChildRelationships(true);
    frame.buttonsScroll:DeleteChild(displayButtons[id]);
    displayButtons[id] = nil;

    if(parentData and parentData.controlledChildren) then
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
end
