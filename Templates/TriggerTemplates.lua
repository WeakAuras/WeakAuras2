-- Special layout for the New Aura Trigger template page

local AceGUI = LibStub("AceGUI-3.0");
local floor, ceil, tinsert = floor, ceil, tinsert;
local CreateFrame, UnitClass, UnitRace, GetSpecialization = CreateFrame, UnitClass, UnitRace, GetSpecialization;
local WeakAuras = WeakAuras;
local L = WeakAuras.L

AceGUI:RegisterLayout("WATemplateTriggerLayoutFlyout", function(content, children)
  local width = content.width or content:GetWidth() or 0
  local columns = floor(width / 250);

  local rows = columns > 0 and ceil(#children / columns) or 0;
  columns = rows > 0 and ceil(#children / rows) or 1;
  local relWidth = 1 / columns;
  for i = 1, #children do
    local child = children[i]
    if (not child:IsFullWidth()) then
      child:SetRelativeWidth(relWidth);
    end
  end
  local flowLayout = AceGUI:GetLayout("Flow");
  flowLayout(content, children);
end);

function WeakAuras.CreateTemplateView(frame)
  local newView = AceGUI:Create("InlineGroup");
  newView.frame:SetParent(frame);
  newView.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 42);
  newView.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  newView.frame:Hide();
  newView:SetLayout("fill");

  local newViewScroll = AceGUI:Create("ScrollFrame");
  newViewScroll:SetLayout("flow");
  newView:AddChild(newViewScroll);

  local function createNewId(prefix)
    local new_id = prefix or "New";
    local num = 2;
    while(WeakAuras.GetData(new_id)) do
      new_id = prefix .. " " .. num;
      num = num + 1;
    end
    return new_id;
  end

  local function createTriggersFor(item)
    if (item.type == "buff" or item.type == "debuff") then
      local triggers = {
        [0] = {
          trigger = {
            unit = item.unit,
            type = "aura",
            spellIds = {
              item.spell
            },
            debuffType = item.type == "buff" and "HELPFUL" or "HARMFUL",
            ownOnly = true,
          }
        },
      };
      if (item.spellIds) then
        WeakAuras.DeepCopy(item.spellIds, triggers[0].trigger.spellIds);
      end
      if (item.fullscan) then
        triggers[0].trigger.use_spellId = true;
        triggers[0].trigger.fullscan = true;
        triggers[0].trigger.spellId = tostring(item.spell);
      end
      if (item.unit == "group") then
        triggers[0].trigger.name_info = "players";
      end
      if (item.unit == "multi") then
        triggers[0].trigger.spellId = item.spell;
      end
      return triggers
    elseif (item.type == "ability") then
      local triggers = {
        [0] = {
          trigger = {
            event = "Cooldown Progress (Spell)",
            spellName = item.spell,
            type = "status",
            unevent = "auto",
            use_showOn = true,
            showOn = "showOnCooldown",
          }
        }
      }
      return triggers;
    elseif (item.type == "item") then
      local triggers = {
        [0] = {
          trigger = {
            type = "status",
            event = "Cooldown Progress (Item)",
            unevent = "auto",
            use_showOn = true,
            showOn = "showOnCooldown",
            itemName = item.spell
          }
        }
      };
      return triggers;
    elseif (item.type == "totem") then
      local triggers = {
        [0] = {
          trigger = {
            type = "status",
            event = "Totem",
            use_totemName = true,
            totemName = item.spell,
            unevent = "auto"
          }
        }
      };
      if (item.totemNumber) then
        triggers[0].trigger.use_totemType = true;
        triggers[0].trigger.totemType = item.totemNumber;
      end
      return triggers;
    end
  end

  -- Trigger Template
  local function sortedPairs (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
      i = i + 1
      if a[i] == nil then return nil
      else return a[i], t[a[i]]
      end
    end
    return iter
  end

  local function createSortFunctionFor(table)
    return function(a, b)
      return table[a].title < table[b].title;
    end
  end

  local function replaceTrigger(data, item)
    data.additional_triggers = nil;
    local triggers;
    if (item.triggers) then
      triggers = item.triggers;
    else
      triggers = createTriggersFor(item);
    end

    for i, v in pairs(triggers) do
      if (i == 0) then
        data.trigger = {};
        WeakAuras.DeepCopy(v.trigger, data.trigger);
        data.untrigger = {};
        if (v.untrigger) then
          WeakAuras.DeepCopy(v.untrigger, data.untrigger);
        end
      else
        data.additional_triggers = data.additional_triggers or {};
        data.additional_triggers[i] = data.additional_triggers[i] or {};
        data.additional_triggers[i].trigger = {};
        WeakAuras.DeepCopy(v.trigger, data.additional_triggers[i].trigger);
        data.additional_triggers[i].untrigger = {};
        if (v.untrigger) then
          WeakAuras.DeepCopy(v.untrigger, data.additional_triggers[i].untrigger);
        end
      end
    end
    data.numTriggers = 1 + (data.additional_triggers and #data.additional_triggers or 0);
    if (item.disjunctive) then
      data.disjunctive = item.disjunctive;
    end
  end

  local function addTrigger(data, item)
    data.additional_triggers = data.additional_triggers or {};

    local triggers;
    if (item.triggers) then
      triggers = item.triggers;
    else
      triggers = createTriggersFor(item);
    end

    for i, v in pairs(triggers) do
      local position = data.numTriggers + i;
      data.additional_triggers[position] = data.additional_triggers[position] or {};
      data.additional_triggers[position].trigger = {};
      WeakAuras.DeepCopy(v.trigger, data.additional_triggers[position].trigger);
      data.additional_triggers[position].untrigger = {};
      if (v.untrigger) then
        WeakAuras.DeepCopy(v.untrigger, data.additional_triggers[position].untrigger);
      end
    end
    data.numTriggers = 1 + (data.additional_triggers and #data.additional_triggers or 0);
    if (item.disjunctive) then
      data.disjunctive = item.disjunctive;
    end
  end

  local createButtons;

  local function createRegionButton(regionType, regionData, selectedItem)
    local button = AceGUI:Create("WeakAurasNewButton");
    button:SetTitle(regionData.displayName);
    if(type(regionData.icon) == "string") then
      button:SetIcon(regionData.icon);
    elseif(type(regionData.icon) == "function") then
      button:SetIcon(regionData.icon());
    end
    button:SetDescription(regionData.description);
    button:SetFullWidth(true);
    if (regionType == selectedItem) then
      button.frame:LockHighlight(true);
    end
    button:SetClick(function()
      createButtons((selectedItem ~= regionType) and regionType);
    end);
    return button;
  end

  local function createRegionFlyout(regionType, regionData)
    local group = AceGUI:Create("WeakAurasTemplateGroup");
    group:SetFullWidth(true);
    group:SetLayout("WATemplateTriggerLayoutFlyout");
    for _, item in ipairs(regionData.templates) do
      local templateButton = AceGUI:Create("WeakAurasNewButton");
      if (item.icon) then
        templateButton:SetIcon(item.icon);
      else
        local thumbnail = regionData.createThumbnail(templateButton.frame, regionData.create);
        regionData.modifyThumbnail(templateButton.frame, thumbnail, item.data, true, regionData.modify)
        templateButton:SetIcon(thumbnail);
      end

      templateButton:SetTitle(item.title);
      templateButton:SetDescription(item.description);
      templateButton:SetClick(function()
        newView.data = {};
        WeakAuras.DeepCopy(item.data, newView.data);
        newView.data.regionType = regionType;
        createButtons();
      end);
      group:AddChild(templateButton);
    end
    return group;
  end

  local function createDropdown(member, values)
    local selector = AceGUI:Create("Dropdown");
    selector:SetList(values);
    selector:SetValue(newView[member]);
    selector:SetCallback("OnValueChanged", function(self, callback, v)
      newView[member] = v;
      createButtons();
    end);
    return selector;
  end

  local function createSpacer()
    local spacer = AceGUI:Create("Label");
    spacer:SetFullWidth(true);
    spacer:SetText(" ");
    return spacer;
  end

  local function relativeWidth(totalWidth)
    local columns = floor(totalWidth / 300);
    return 1 / columns;
  end

  local function createTriggerFlyout(section, fullWidth)
    local group = AceGUI:Create("WeakAurasTemplateGroup");
    group:SetFullWidth(true);
    group:SetLayout("WATemplateTriggerLayoutFlyout");
    if (section) then
      for j, item in sortedPairs(section, createSortFunctionFor(section)) do
        local button = AceGUI:Create("WeakAurasNewButton");
        button:SetTitle(item.title);
        button:SetDescription(item.description);
        if (fullWidth) then
          button:SetFullWidth(true);
        end
        if(item.icon) then
          button:SetIcon(item.icon);
        end
        button:SetClick(function()
          if (newView.existingAura) then
            newView.choosenItem = item;
            createButtons();
          else
            replaceTrigger(newView.data, item);
            newView.data.id = createNewId(item.title);
            newView.data.load = {};
            if (item.load) then
              WeakAuras.DeepCopy(item.load, newView.data.load);
            end
            newView:CancelClose();
            WeakAuras.Add(newView.data);
            WeakAuras.NewDisplayButton(newView.data);
            WeakAuras.PickDisplay(newView.data.id);
          end
        end);
        group:AddChild(button);
      end
    end
    return group;
  end

  local function createTriggerButton(section, selectedItem, fullWidth)
    local button = AceGUI:Create("WeakAurasNewButton");
    button:SetTitle(section.title);
    button:SetDescription(section.description);
    if (section.icon) then
      button:SetIcon(section.icon);
    end
    button:SetFullWidth(true);
    button:SetClick(function()
      createButtons((selectedItem ~= section) and section);
    end);
    newViewScroll:AddChild(button);
    if (section == selectedItem) then
      button.frame:LockHighlight(true);
      local group = createTriggerFlyout(section.args, fullWidth);
      newViewScroll:AddChild(group);
    end
  end
  -- Creates a button + flyout (if the button is selected) for one section
  local function createTriggerButtons(templates, selectedItem, fullWidth)
    for k, section in ipairs(templates) do
      createTriggerButton(section, selectedItem, fullWidth);
    end
  end

  local function replaceTriggers(data, item)
    local function handle(data, item)
      replaceTrigger(data, item);
      WeakAuras.optionTriggerChoices[data.id] = 0;
      newView.CancelClose();
      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
    end
    if (data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          handle(childData, item);
        end
      end
    else
      handle(data, item);
      WeakAuras.PickDisplay(data.id);
    end
  end

  local function addTriggers(data, item)
    local function handle(data, item)
      addTrigger(data, item);
      WeakAuras.optionTriggerChoices[data.id] = data.numTriggers - 1;
      newView.CancelClose();
      WeakAuras.Add(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
    end
    if (data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          handle(childData, item);
        end
      end
    else
      handle(data, item);
      WeakAuras.PickDisplay(data.id);
    end
  end

  local function createLastPage()
    local replaceButton = AceGUI:Create("WeakAurasNewButton");
    replaceButton:SetTitle(L["Replace Triggers"]);
    replaceButton:SetDescription(L["Replace all existing triggers"]);
    replaceButton:SetIcon("Interface\\Icons\\Spell_ChargeNegative");
    replaceButton:SetFullWidth(true);
    replaceButton:SetClick(function()
      replaceTriggers(newView.data, newView.choosenItem);
    end);
    newViewScroll:AddChild(replaceButton);

    local addButton = AceGUI:Create("WeakAurasNewButton");
    addButton:SetTitle(L["Add Triggers"]);
    addButton:SetDescription(L["Keeps existing triggers intact"]);
    addButton:SetIcon("Interface\\Icons\\Spell_ChargePositive");
    addButton:SetFullWidth(true);
    addButton:SetClick(function()
      addTriggers(newView.data, newView.choosenItem);
    end);
    newViewScroll:AddChild(addButton);
  end

  createButtons = function(selectedItem) -- selectedItem is either a regionType or a trigger section
    newViewScroll:ReleaseChildren();
    if (not newView.data) then
      -- First step: Show region types
      for regionType, regionData in pairs(WeakAuras.regionOptions) do
        if (regionData.templates) then
          local button = createRegionButton(regionType, regionData, selectedItem);
          newViewScroll:AddChild(button);
          if (regionType == selectedItem) then
            local group = createRegionFlyout(regionType, regionData);
            newViewScroll:AddChild(group);
          end
        end
      end
      newView.backButton:Hide();
    elseif (newView.data and not newView.choosenItem) then
      -- Second step: Trigger selection screen

      -- Class
      local classSelector = createDropdown("class", WeakAuras.class_types);
      newViewScroll:AddChild(classSelector);

      local specSelector = createDropdown("spec", WeakAuras.spec_types_specific[newView.class]);
      newViewScroll:AddChild(specSelector);
      newViewScroll:AddChild(createSpacer());

      if (WeakAuras.triggerTemplates.class[newView.class] and WeakAuras.triggerTemplates.class[newView.class][newView.spec]) then
        createTriggerButtons(WeakAuras.triggerTemplates.class[newView.class][newView.spec], selectedItem);
      end
      local classHeader = AceGUI:Create("Heading");
      classHeader:SetFullWidth(true);
      newViewScroll:AddChild(classHeader);

      createTriggerButton(WeakAuras.triggerTemplates.general, selectedItem);

      -- Race
      local raceHeader = AceGUI:Create("Heading");
      raceHeader:SetFullWidth(true);
      newViewScroll:AddChild(raceHeader);
      local raceSelector = createDropdown("race", WeakAuras.race_types);
      newViewScroll:AddChild(raceSelector);
      newViewScroll:AddChild(createSpacer());
      if (WeakAuras.triggerTemplates.race[newView.race]) then
        local group = createTriggerFlyout(WeakAuras.triggerTemplates.race[newView.race], true);
        newViewScroll:AddChild(group);
      end

      local itemHeader = AceGUI:Create("Heading");
      itemHeader:SetFullWidth(true);
      newViewScroll:AddChild(itemHeader);
      local itemTypes = {};
      for _, section in pairs(WeakAuras.triggerTemplates.items) do
        tinsert(itemTypes, section.title);
      end
      newView.item = newView.item or 1;
      local itemSelector = createDropdown("item", itemTypes);
      newViewScroll:AddChild(itemSelector);
      newViewScroll:AddChild(createSpacer());
      if (WeakAuras.triggerTemplates.items[newView.item]) then
        local group = createTriggerFlyout(WeakAuras.triggerTemplates.items[newView.item].args, true);
        newViewScroll:AddChild(group);
      end
      if (newView.existingAura) then
        newView.backButton:Hide();
      else
        newView.backButton:Show();
      end
    else
      --Third Step: (only for existing auras): replace or add triggers?
      createLastPage();
      newView.backButton:Show();
    end
  end

  local newViewBack = CreateFrame("Button", nil, newView.frame, "UIPanelButtonTemplate");
  newViewBack:SetScript("OnClick", function()
    if (newView.existingAura) then
      newView.choosenItem = nil;
    else
      newView.data = nil;
    end
    createButtons();
  end);
  newViewBack:SetPoint("BOTTOMRIGHT", -147, -23);
  newViewBack:SetHeight(20);
  newViewBack:SetWidth(100);
  newViewBack:SetText(L["Back"]);
  newView.backButton = newViewBack;

  local newViewCancel = CreateFrame("Button", nil, newView.frame, "UIPanelButtonTemplate");
  newViewCancel:SetScript("OnClick", function() newView:CancelClose() end);
  newViewCancel:SetPoint("BOTTOMRIGHT", -27, -23);
  newViewCancel:SetHeight(20);
  newViewCancel:SetWidth(100);
  newViewCancel:SetText(L["Cancel"]);

  function newView.Open(self, data)
    frame.container.frame:Hide();
    frame.buttonsContainer.frame:Hide();
    self.frame:Show();
    frame.window = "newView";
    if (data) then
      self.data = {};
      WeakAuras.DeepCopy(data, self.data);
      newView.existingAura = true;
      newView.choosenItem = nil;
    else
      self.data = nil; -- Data is cloned from display template
      newView.existingAura = false;
      newView.choosenItem = nil;
    end
    newView.class = select(2, UnitClass("player"));
    newView.spec = GetSpecialization() or 1;
    newView.race = select(2, UnitRace('player'));
    createButtons();
  end

  function newView.CancelClose(self)
    newView.frame:Hide();
    frame.buttonsContainer.frame:Show();
    frame.container.frame:Show();
    frame.window = "default";
    frame:PickOption("New");
  end

  function WeakAuras.OpenTriggerTemplate(data)
    frame.newView:Open(data);
  end

  return newView;
end
