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

local changes = {
  grey = {
    value = {
        0.5,
        0.5,
        0.5,
        1,
    },
    property = "color",
  },
  blue = {
    value = {
      0.5,
      0.5,
      1,
      1,
    },
    property = "color",
  },
  red = {
    value = {
      0.8,
      0.1,
      0.1,
      1,
    },
    property = "color",
  },
  white = {
    value = {
      1,
      1,
      1,
      1,
    },
    property = "color",
  },
  alpha = {
    value = 0.5,
    property = "alpha"
  },
  inverse = {
    value = false,
    property = "inverse",
  },
  glow = {
    value = true,
    property = "glow",
  }
}

local checks = {
  spellInRange = {
    variable = "spellInRange",
    value = 0,
  },
  itemInRange = {
    variable = "itemInRange",
    value = 0,
  },
  hasTarget = {
    trigger = -1,
    variable = "hastarget",
    value = 0,
  },
  insufficientResources =  {
    variable = "insufficientResources",
    value = 1,
  },
  buffed = {
    variable = "buffed",
    value = 1,
  },
  buffedFalse = {
    variable = "buffed",
    value = 0,
  },
  onCooldown = {
    variable = "onCooldown",
    value = 1,
  },
  charges = {
    variable = "charges",
    op = "==",
    value = "0",
  },
  usable = {
    variable = "spellUsable",
    value = 0,
  },
  totem = {
    variable = "show",
    value = 1,
  },
}

local function buildCondition(trigger, check, properties)
  local result = {};
  result.check = CopyTable(check);
  if (not result.check.trigger) then
    result.check.trigger = trigger;
  end

  result.changes = {};
  for index, v in ipairs(properties) do
    result.changes[index] = CopyTable(v);
  end
  return result;
end

local function buffGreyed(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.buffedFalse, {changes.grey}));
end

local function hasTargetAlpha(conditions)
  tinsert(conditions, buildCondition(nil, checks.hasTarget, {changes.alpha}));
end

local function isUsableBlue(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.usable, {changes.blue}));
end

local function insufficientResourcesBlue(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.insufficientResources, {changes.blue}));
end

local function hasChargesGrey(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.charges, {changes.grey}));
end

local function onCdCheckGrey(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.onCooldown, {changes.grey}));
end

local function isBuffedGlow(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.buffed, {changes.inverse, changes.glow, changes.white}));
end

local function totemActiveGlow(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.totem, {changes.inverse, changes.glow, changes.white}));
end

local function spellInRangeRed(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.spellInRange, {changes.red}));
end

local function itemInRangeRed(conditions, trigger)
  tinsert(conditions, buildCondition(trigger, checks.itemInRange, {changes.red}));
end

local function createBuffTrigger(triggers, position, item, buffShowOn, isBuff)
  triggers[position] = {
    trigger = {
      unit = item.unit or isBuff and "player" or "target",
      type = "aura",
      spellIds = {
        item.spell
      },
      buffShowOn = buffShowOn,
      debuffType = isBuff and "HELPFUL" or "HARMFUL",
      ownOnly = not item.forceOwnOnly and true or item.ownOnly,
      unitExists = true,
    }
  };
  if (item.spellIds) then
    WeakAuras.DeepCopy(item.spellIds, triggers[position].trigger.spellIds);
  end
  if (item.fullscan) then
    triggers[position].trigger.use_spellId = true;
    triggers[position].trigger.fullscan = true;
    triggers[position].trigger.spellId = tostring(item.spell);
  end
  if (item.unit == "group") then
    triggers[position].trigger.name_info = "players";
  end
  if (item.unit == "multi") then
    triggers[position].trigger.spellId = item.spell;
  end
end

local function createTotemTrigger(triggers, position, item)
  triggers[position] = {
    trigger = {
      type = "status",
      event = "Totem",
      use_totemName = item.totemNumber == nil,
      totemName = GetSpellInfo(item.spell),
      unevent = "auto"
    }
  };
  if (item.totemNumber) then
    triggers[position].trigger.use_totemType = true;
    triggers[position].trigger.totemType = item.totemNumber;
  end
end

local function createAbilityTrigger(triggers, position, item, genericShowOn)
  triggers[position] = {
    trigger = {
      event = "Cooldown Progress (Spell)",
      spellName = item.spell,
      type = "status",
      unevent = "auto",
      use_genericShowOn = true,
      genericShowOn = genericShowOn,
    }
  };
end

local function createItemTrigger(triggers, position, item, genericShowOn)
  triggers[position] = {
    trigger = {
      type = "status",
      event = "Cooldown Progress (Item)",
      unevent = "auto",
      use_genericShowOn = true,
      genericShowOn = genericShowOn,
      itemName = item.spell
    }
  };
end

local function createAbilityAndBuffTrigger(triggers, item)
  createBuffTrigger(triggers, 0, item, "showOnActive", true);
  createAbilityTrigger(triggers, 1, item, "showAlways");
end

local function createAbilityAndDebuffTrigger(triggers, item)
  createBuffTrigger(triggers, 0, item, "showOnActive", false);
  createAbilityTrigger(triggers, 1, item, "showAlways");
end

local function subTypesFor(item)
  local types = {};
  if (item.type == "ability") then
    tinsert(types, {
      title = L["Basic Show On Cooldown"],
      description = L["Only shows the aura when the ability is on cooldown."],
      createTriggers = function(triggers, item)
        createAbilityTrigger(triggers, 0, item, "showOnCooldown");
      end,
    });
    if (item.charges) then
      tinsert(types, {
        title = L["Charge Tracking"],
        description = L["Always shows the aura, turns greys on zero charges, blue on insufficient resources."],
        createTriggers = function(triggers, item)
          createAbilityTrigger(triggers, 0, item, "showAlways");
        end,
        createConditions = function(conditions, item)
          insufficientResourcesBlue(conditions, 0);
          hasChargesGrey(conditions, 0);
        end,
      });
      if (item.buff) then
        tinsert(types, {
          title = L["Charge and Buff Tracking"],
          description = L["Tracks the charge and the buff, glows while the buff is active, blue on insufficient resources."],
          createTriggers = createAbilityAndBuffTrigger,
          createConditions = function(conditions, item)
            insufficientResourcesBlue(conditions, 1);
            hasChargesGrey(conditions, 1);
            isBuffedGlow(conditions, 0);
          end,
        });
      elseif(item.debuff) then
        tinsert(types, {
          title = L["Charge and Debuff Tracking"],
          description = L["Tracks the charge and the debuff, glows while the debuff is active, blue on insufficient resources."],
          createTriggers = createAbilityAndDebuffTrigger,
          createConditions = function(conditions, item)
            insufficientResourcesBlue(conditions, 1);
            hasChargesGrey(conditions, 1);
            isBuffedGlow(conditions, 0);
          end,
        })
      elseif(item.requiresTarget) then
        tinsert(types,  {
          title = L["Show Charges with Range Tracking"],
          description = L["Always shows the aura, turns grey when on zero charges, red when out of range, blue on insufficient resources."],
          genericShowOn = "showAlways",
          createTriggers = function(triggers, item)
            createAbilityTrigger(triggers, 0, item, "showAlways");
          end,
          createConditions = function(conditions, item)
            insufficientResourcesBlue(conditions, 0);
            hasChargesGrey(conditions, 0);
            spellInRangeRed(conditions, 0);
          end,
        });
        if (item.usable) then
          tinsert(types,  {
            title = L["Show Charges with Usable Check"],
            description = L["Always shows the aura, turns red when out of range, blue on insufficient resources."],
            createTriggers = function(triggers, item)
              createAbilityTrigger(triggers, 0, item, "showAlways");
            end,
            createConditions = function(conditions, item)
              isUsableBlue(conditions, 0);
              hasChargesGrey(conditions, 0);
              spellInRangeRed(conditions, 0);
            end,
          });
        end
      elseif(item.totem) then
        tinsert(types, {
          title = L["Show Totem and Charge Information"],
          description = L["Always shows the aura, turns grey when on zero charges, glows when active, blue on insufficient resources."],
          createTriggers = function(triggers, item)
            createTotemTrigger(triggers, 0, item);
            createAbilityTrigger(triggers, 1, item, "showAlways");
          end,
          createConditions = function(conditions, item)
            insufficientResourcesBlue(conditions, 1);
            hasChargesGrey(conditions, 1);
            totemActiveGlow(conditions, 0);
          end,
        });
      elseif(item.usable) then
        tinsert(types, {
          title = L["Show Charges and Check Usable"],
          description = L["Always shows the aura, turns grey when on zero charges, blue when usable."],
          createTriggers = function(triggers, item)
            createAbilityTrigger(triggers, 0, item, "showAlways");
          end,
          createConditions = function(conditions, item)
            isUsableBlue(conditions, 0);
            hasChargesGrey(conditions, 0);
          end,
        });
      end
    else -- Ability without charges
      tinsert(types, {
        title = L["Show Only On Cooldown"],
        description = L["Always shows the aura, turns grey when on cooldown, blue when unusable."],
        createTriggers = function(triggers, item)
          createAbilityTrigger(triggers, 0, item, "showAlways");
        end,
        createConditions = function(conditions, item)
          insufficientResourcesBlue(conditions, 0);
          onCdCheckGrey(conditions, 0);
        end,
      });
      if (item.buff) then
        tinsert(types, {
          title = L["Show Cooldown and Buff"],
          description = L["Glows while buffed."],
          createTriggers = createAbilityAndBuffTrigger,
          createConditions = function(conditions, item)
            insufficientResourcesBlue(conditions, 1);
            onCdCheckGrey(conditions, 1);
            isBuffedGlow(conditions, 0);
          end,
        });
        if (item.usable) then
          tinsert(types, {
            title = L["Show Cooldown and Buff and Check Usable"],
            description = L["Glows while buffed."],
            createTriggers = createAbilityAndBuffTrigger,
            createConditions = function(conditions, item)
              isUsableBlue(conditions, 1);
              onCdCheckGrey(conditions, 1);
              isBuffedGlow(conditions, 0);
            end,
          });
        end
        if (item.requiresTarget) then
          tinsert(types, {
            title = L["Show Cooldown and Buff and Check for Target"],
            description = L["Glows while buffed, red when out of range."],
            createTriggers = createAbilityAndBuffTrigger,
            createConditions = function(conditions, item)
              insufficientResourcesBlue(conditions, 1);
              onCdCheckGrey(conditions, 1);
              spellInRangeRed(conditions, 1);
              isBuffedGlow(conditions, 0);
            end,
          });
        end
      elseif(item.debuff) then
        tinsert(types, {
          title = L["Show Cooldown and Debuff"],
          description = L["Glows while debuffed."],
          createTriggers = createAbilityAndDebuffTrigger,
          createConditions = function(conditions, item)
            insufficientResourcesBlue(conditions, 1);
            onCdCheckGrey(conditions, 1);
            isBuffedGlow(conditions, 0);
          end,
        });
        if (item.requiresTarget) then
          tinsert(types, {
            title = L["Show Cooldown and Debuff and Check for Target"],
            description = L["Glows while debuffed, red when out of range."],
            createTriggers = createAbilityAndDebuffTrigger,
            createConditions = function(conditions, item)
              insufficientResourcesBlue(conditions, 1);
              onCdCheckGrey(conditions, 1);
              spellInRangeRed(conditions, 1);
              isBuffedGlow(conditions, 0);
            end,
          });
        end
      elseif(item.totem) then
        tinsert(types, {
          title = L["Show Cooldown and Totem Information"],
          description = L["Always shows the aura, turns grey if the ability is not usable."],
          createTriggers = function(triggers, item)
            createTotemTrigger(triggers, 0, item);
            createAbilityTrigger(triggers, 1, item, "showAlways");
          end,
          createConditions = function(conditions, item)
            insufficientResourcesBlue(conditions, 1);
            onCdCheckGrey(conditions, 1);
            totemActiveGlow(conditions, 0);
          end,
        });
      else
        if (item.usable) then
          tinsert(types, {
            title = L["Show Cooldown and Check Usable"],
            description = L["Always shows the aura, turns grey if the ability is not usable."],
            createTriggers = function(triggers, item)
              createAbilityTrigger(triggers, 0, item, "showAlways");
            end,
            createConditions = function(conditions, item)
              isUsableBlue(conditions, 0);
              onCdCheckGrey(conditions, 0);
            end,
          });
          if (item.requiresTarget) then
            tinsert(types, {
              title = L["Show Cooldown and Check Usable & Target"],
              description = L["Always shows the aura, turns grey if the ability is not usable and red when out of range."],
              createTriggers = function(triggers, item)
                createAbilityTrigger(triggers, 0, item, "showAlways");
              end,
              createConditions = function(conditions, item)
                isUsableBlue(conditions, 0);
                onCdCheckGrey(conditions, 0);
                spellInRangeRed(conditions, 0);
              end,
            });
          end
        end
        if (item.requiresTarget) then
          tinsert(types, {
            title = L["Show Cooldown and Check for Target"],
            description = L["Always shows the aura, turns red when out of range."],
            createTriggers = function(triggers, item)
              createAbilityTrigger(triggers, 0, item, "showAlways");
            end,
            createConditions = function(conditions, item)
              insufficientResourcesBlue(conditions, 0);
              onCdCheckGrey(conditions, 0);
              spellInRangeRed(conditions, 0);
            end,
          });
        end
      end
    end
  elseif(item.type == "buff") then
    tinsert(types, {
      title = L["Show Only if Buffed"],
      description = L["Only shows the aura if the target has the buff."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 0, item, "showOnActive", true);
      end
    });
    tinsert(types, {
      title = L["Always Show"],
      description = L["Always shows the aura, makes it glow if buffed."],
      buffShowOn = "showAlways",
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 0, item, "showAlways", true);
      end,
      createConditions = function(conditions, item)
        isBuffedGlow(conditions, 0);
      end,
    });
    tinsert(types, {
      title = L["Always Show"],
      description = L["Always shows the aura, grey if buff not active."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 0, item, "showAlways", true);
      end,
      createConditions = function(conditions, item)
        buffGreyed(conditions, 0);
      end,
    });
  elseif(item.type == "debuff") then
    tinsert(types, {
      title = L["Show Only if Debuffed"],
      description = L["Only show the aura if the target has the debuff."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 0, item, "showOnActive", false);
      end
    });
    tinsert(types, {
      title = L["Always Show"],
      description = L["Always show the aura, makes it glow if debuffed."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 0, item, "showAlways", false);
      end,
      createConditions = function(conditions, item)
        isBuffedGlow(conditions, 0);
      end,
    });
    tinsert(types, {
      title = L["Always Show"],
      description = L["Always show the aura, turns grey if the debuff not active."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 0, item, "showAlways", false);
      end,
      createConditions = function(conditions, item)
        buffGreyed(conditions, 0);
      end,
    });
  elseif(item.type == "item") then
    tinsert(types, {
      title = L["Show Only if on Cooldown"],
      description = L["Only show the aura when the item is on cooldown."],
      createTriggers = function(triggers, item)
        createItemTrigger(triggers, 0, item, "showOnCooldown");
      end
    });
    tinsert(types, {
      title = L["Always Show"],
      description = L["Always show the aura, turns grey if on cooldown."],
      createTriggers = function(triggers, item)
        createItemTrigger(triggers, 0, item, "showAlways");
      end,
      createConditions = function(conditions, item)
        onCdCheckGrey(conditions, 0);
      end,
    });
  elseif(item.type == "totem") then
    tinsert(types, {
      title = L["Always Show"],
      description = L["Always shows the aura, turns grey if on cooldown."],
      createTriggers = function(triggers, item)
        createTotemTrigger(triggers, 0, item);
      end,
      createConditions = function(conditions, item)
        totemActiveGlow(conditions, 0);
      end,
    });
  end

  return types;
end

function WeakAuras.CreateTemplateView(frame)
  local newView = AceGUI:Create("InlineGroup");
  newView.frame:SetParent(frame);
  newView.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 42);
  newView.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -10);
  newView.frame:Hide();
  newView:SetLayout("fill");

  local newViewScroll = AceGUI:Create("ScrollFrame");
  newViewScroll:SetLayout("flow");
  newViewScroll.frame:SetClipsChildren(true);
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

  local function createConditionsFor(item, subType)
    if (subType.createConditions) then
      local conditions = {};
      subType.createConditions(conditions, item);
      return conditions;
    end
  end

  local function replaceCondition(data, item, subType)
    local conditions = createConditionsFor(item, subType);
    if conditions then
      data.conditions = {}
      WeakAuras.DeepCopy(conditions, data.conditions);
    end
  end

  local function addCondition(data, item, subType, prevNumTriggers)
    local conditions = createConditionsFor(item, subType);
    if conditions then
      if data.conditions then
        local position = #data.conditions + 1;
        for i,v in pairs(conditions) do
          data.conditions[position] = data.conditions[position] or {};
          if v.check.trigger ~= -1 then
            v.check.trigger = v.check.trigger + prevNumTriggers;
          end
          WeakAuras.DeepCopy(v, data.conditions[position]);
          position = position + 1;
        end
      else
        data.conditions = {};
        WeakAuras.DeepCopy(conditions, data.conditions);
      end
    end
  end

  local function createTriggersFor(item, subType)
    local triggers = {};
    subType.createTriggers(triggers, item);
    return triggers;
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

  local function replaceTrigger(data, item, subType)
    data.additional_triggers = nil;
    local triggers;
    if (item.triggers) then
      triggers = item.triggers;
    else
      triggers = createTriggersFor(item, subType);
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
    if (triggers[1]) then -- Multiple triggers
      data.disjunctive = "any";
      data.activeTriggerMode = -10;
    end
  end

  local function addTrigger(data, item, subType)
    data.additional_triggers = data.additional_triggers or {};
    local triggers;
    if (item.triggers) then
      triggers = item.triggers;
    else
      triggers = createTriggersFor(item, subType);
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
     -- Multiple Triggers, override disjunctive, even if the users set it previously
    if (triggers[1]) then
      data.disjunctive = "any";
      data.activeTriggerMode = -10;
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
        WeakAuras.validate(newView.data, WeakAuras.data_stub);
        newView.data.internalVersion = WeakAuras.InternalVersion();
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
          local subTypes = subTypesFor(item);
          if #subTypes < 2 then
            local subType = subTypes[1] or {}
            if (newView.existingAura) then
              newView.choosenItem = item;
              newView.choosenSubType = subType;
              createButtons();
            else
              replaceTrigger(newView.data, item, subType);
              replaceCondition(newView.data, item, subType);
              newView.data.id = WeakAuras.FindUnusedId(item.title);
              newView.data.load = {};
              if (item.load) then
                WeakAuras.DeepCopy(item.load, newView.data.load);
              end
              newView:CancelClose();
              WeakAuras.Add(newView.data);
              WeakAuras.NewDisplayButton(newView.data);
              WeakAuras.PickDisplay(newView.data.id);
            end
          else
            -- create trigger type selection
            newView.choosenItem = item;
            createButtons();
          end
        end);
        group:AddChild(button);
      end
    end
    return group;
  end

  local function createTriggerTypeButtons()
    local item = newView.choosenItem;
    local group = AceGUI:Create("WeakAurasTemplateGroup");
    group:SetFullWidth(true);
    local subTypes = subTypesFor(item);
    for _, subType in pairs(subTypes) do
      local button = AceGUI:Create("WeakAurasNewButton");
      button:SetTitle(subType.title);
      button:SetDescription(subType.description);
      button:SetFullWidth(true);
      button:SetClick(function()
        if (newView.existingAura) then
          newView.choosenItem = item;
          newView.choosenSubType = subType;
          createButtons();
        else
          replaceTrigger(newView.data, item, subType);
          replaceCondition(newView.data, item, subType);
          newView.data.id = WeakAuras.FindUnusedId(item.title);
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

  local function replaceTriggers(data, item, subType)
    local function handle(data, item, subType)
      replaceTrigger(data, item, subType);
      replaceCondition(data, item, subType);
      WeakAuras.optionTriggerChoices[data.id] = 0;
      newView:CancelClose();
      WeakAuras.Add(data);
      WeakAuras.NewDisplayButton(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
    end
    if (data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          handle(childData, item, subType);
        end
      end
    else
      handle(data, item, subType);
      WeakAuras.PickDisplay(data.id);
    end
  end

  local function addTriggers(data, item, subType)
    local function handle(data, item, subType)
      local prevNumTriggers = data.numTriggers;
      addTrigger(data, item, subType);
      addCondition(data, item, subType, prevNumTriggers);
      WeakAuras.optionTriggerChoices[data.id] = prevNumTriggers;
      newView:CancelClose();
      WeakAuras.Add(data);
      WeakAuras.NewDisplayButton(data);
      WeakAuras.SetThumbnail(data);
      WeakAuras.SetIconNames(data);
      WeakAuras.UpdateDisplayButton(data);
    end
    if (data.controlledChildren) then
      for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
          handle(childData, item, subType);
        end
      end
    else
      handle(data, item, subType);
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
      replaceTriggers(newView.data, newView.choosenItem, newView.choosenSubType);
      for _,v in pairs({"class","spec","talent","pvptalent","race"}) do
        newView.data.load[v] = nil;
        newView.data.load["use_"..v] = nil;
      end
      newView.data.load.class = {};
      newView.data.load.spec = {};
      WeakAuras.DeepCopy(WeakAuras.data_stub.load.class, newView.data.load.class);
      WeakAuras.DeepCopy(WeakAuras.data_stub.load.spec, newView.data.load.spec);
      if (newView.choosenItem.load) then
        WeakAuras.DeepCopy(newView.choosenItem.load, newView.data.load);
      end
    end);
    newViewScroll:AddChild(replaceButton);

    local addButton = AceGUI:Create("WeakAurasNewButton");
    addButton:SetTitle(L["Add Triggers"]);
    addButton:SetDescription(L["Keeps existing triggers intact"]);
    addButton:SetIcon("Interface\\Icons\\Spell_ChargePositive");
    addButton:SetFullWidth(true);
    addButton:SetClick(function()
      addTriggers(newView.data, newView.choosenItem, newView.choosenSubType);
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

      -- Items
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

      -- backButton
      if (newView.existingAura) then
        newView.backButton:Hide();
      else
        newView.backButton:Show();
      end
    elseif (newView.data and newView.choosenItem and not newView.choosenSubType) then
      -- Multi-Type template
      local typeHeader = AceGUI:Create("Heading");
      typeHeader:SetFullWidth(true);
      newViewScroll:AddChild(typeHeader);
      local group = createTriggerTypeButtons();
      newViewScroll:AddChild(group);
      newView.backButton:Show();
    else
      --Third Step: (only for existing auras): replace or add triggers?
      createLastPage();
      newView.backButton:Show();
    end
  end

  local newViewBack = CreateFrame("Button", nil, newView.frame, "UIPanelButtonTemplate");
  newViewBack:SetScript("OnClick", function()
    if (newView.existingAura) then
      if newView.choosenSubType then
        newView.choosenSubType = nil;
        local subTypes = subTypesFor(newView.choosenItem);
        if #subTypes < 2 then -- No subtype selection, go back twice
          newView.choosenItem = nil;
        end
      else
        newView.choosenItem = nil;
      end
    else
      if newView.choosenSubType then
        newView.choosenSubType = nil;
      else
        if newView.choosenItem then
          newView.choosenItem = nil;
        else
          newView.data = nil;
        end
      end
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
      self.data = data;
      newView.existingAura = true;
      newView.choosenItem = nil;
      newView.choosenSubType = nil;
    else
      self.data = nil; -- Data is cloned from display template
      newView.existingAura = false;
      newView.choosenItem = nil;
      newView.choosenSubType = nil;
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
    if (not self.data) then
      frame:PickOption("New");
    end
  end

  function WeakAuras.OpenTriggerTemplate(data)
    frame.newView:Open(data);
  end

  return newView;
end
