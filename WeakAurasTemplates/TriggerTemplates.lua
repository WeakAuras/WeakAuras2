-- Special layout for the New Aura Trigger template page

local AddonName, TemplatePrivate = ...

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

local colors = {
  grey = { 0.5, 0.5, 0.5, 1 },
  blue = { 0.5, 0.5, 1, 1 },
  red = { 0.8, 0.1, 0.1, 1 },
  white = { 1, 1, 1, 1 },
  yellow = { 1, 1, 0, 1 },
  green = { 0, 1, 0, 1},
};

local regionColorProperty = {
  icon = "color",
  aurabar= "barColor",
  progresstexture = "foregroundColor",
  text = "color",
  texture = "color",
};

local function changes(property, regionType)
  if colors[property] and regionColorProperty[regionType] then
    return {
      value = colors[property],
      property = regionColorProperty[regionType],
    };
  elseif property == "glow" and (regionType == "icon" or regionType == "aurabar") then
    local subregionPos = regionType == "aurabar" and 1 or 2
    return {
      value = true,
      property = "sub."..subregionPos..".glow"
    };
  elseif TemplatePrivate.Private.regionTypes[regionType].default[property] == nil then
    return nil;
  elseif property == "cooldownSwipe" then
    return {
      value = true,
      property = "cooldownSwipe",
    };
  elseif property == "alpha" then
    return {
      value = 0.5,
      property = "alpha",
    };
  elseif property == "inverse" then
    return {
      value = false,
      property = "inverse",
    };
  end
end

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
  buffedAuraFound = {
    variable = "show",
    value = 1,
  },
  buffedAuraAlways = {
    variable = "buffed",
    value = 1,
  },
  buffedFalseAuraAlways = {
    variable = "buffed",
    value = 0,
  },
  duration = {
    variable = "show",
    value = 1,
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
  overlayGlow = {
    variable = "show",
    value = 1,
  },
  uninterruptible = {
    variable = "interruptible",
    value = 0,
  },
  enchantMissing = {
    variable = "enchanted",
    value = 0
  },
  queued = {
    variable = "show",
    value = 1,
  }
}

local function buildCondition(trigger, check, properties)
  local result = {};
  result.check = CopyTable(check);
  if (not result.check.trigger) then
    result.check.trigger = trigger;
  end

  result.changes = {};
  local hasChanges = false;
  for index, v in ipairs(properties) do
    result.changes[index] = CopyTable(v);
    hasChanges = true;
  end
  return hasChanges and result or nil;
end

local function missingBuffGreyed(conditions, trigger, regionType)
  tinsert(conditions, buildCondition(trigger, checks.buffedFalseAuraAlways, {changes("grey", regionType)}));
end

local function hasTargetAlpha(conditions, regionType)
  tinsert(conditions, buildCondition(nil, checks.hasTarget, {changes("alpha", regionType)}));
end

local function isNotUsableBlue(conditions, trigger, regionType)
  tinsert(conditions, buildCondition(trigger, checks.usable, {changes("blue", regionType)}));
end

local function insufficientResourcesBlue(conditions, trigger, regionType)
  tinsert(conditions, buildCondition(trigger, checks.insufficientResources, {changes("blue", regionType)}));
end

local function hasChargesGrey(conditions, trigger, regionType)
  if regionType == "icon" then
    tinsert(conditions, buildCondition(trigger, checks.charges, {changes("cooldownSwipe", regionType)}));
  else
    tinsert(conditions, buildCondition(trigger, checks.charges, {changes("grey", regionType)}));
  end
end

local function isOnCdGrey(conditions, trigger, regionType)
  tinsert(conditions, buildCondition(trigger, checks.onCooldown, {changes("grey", regionType)}));
end

local function GenericGlow(conditions, trigger, regionType, check)
  if regionType == "icon" then
    tinsert(conditions, buildCondition(trigger, check, {changes("inverse", regionType), changes("glow", regionType), changes("white", regionType)}));
  elseif regionType == "aurabar" then
    tinsert(conditions, buildCondition(trigger, check, {changes("inverse", regionType), changes("glow", regionType), changes("yellow", regionType)}));
  elseif regionType == "progresstexture" then
    tinsert(conditions, buildCondition(trigger, check, {changes("inverse", regionType), changes("yellow", regionType)}));
  else
    tinsert(conditions, buildCondition(trigger, check, {changes("yellow", regionType)}));
  end
end

local function isQueuedGlow(conditions, trigger, regionType)
  GenericGlow(conditions, trigger, regionType, checks.queued)
end

local function isBuffedGlow(conditions, trigger, regionType)
  GenericGlow(conditions, trigger, regionType, checks.buffedAuraFound)
end

local function isDurationGlow(conditions, trigger, regionType)
  GenericGlow(conditions, trigger, regionType, checks.duration)
end

local function isBuffedGlowAuraAlways(conditions, trigger, regionType)
  GenericGlow(conditions, trigger, regionType, checks.buffedAuraAlways)
end

local function totemActiveGlow(conditions, trigger, regionType)
  GenericGlow(conditions, trigger, regionType, checks.totem)
end

local function isMissingEnchantGlow(conditions, trigger, regionType)
  tinsert(conditions, buildCondition(trigger, checks.enchantMissing, {changes("glow", regionType)}));
end

local function overlayGlow(conditions, trigger, regionType)
  if regionType == "icon" or regionType == "aurabar" then
    tinsert(conditions, buildCondition(trigger, checks.overlayGlow, {changes("glow", regionType)}));
  else
    tinsert(conditions, buildCondition(trigger, checks.overlayGlow, {changes("yellow", regionType)}));
  end
end

local function uninterruptibleRed(conditions, trigger, regionType)
  tinsert(conditions, buildCondition(trigger, checks.uninterruptible, {changes("red", regionType)}));
end

local function isSpellNotInRangeRed(conditions, trigger, regionType)
  tinsert(conditions, buildCondition(trigger, checks.spellInRange, {changes("red", regionType)}));
end

local function itemInRangeRed(conditions, trigger, regionType)
  tinsert(conditions, buildCondition(trigger, checks.itemInRange, {changes("red", regionType)}));
end

local function createBuffTrigger(triggers, position, item, buffShowOn, isBuff)
  triggers[position] = {
    trigger = {
      unit = item.unit or isBuff and "player" or "target",
      type = "aura2",
      matchesShowOn = buffShowOn,
      debuffType = isBuff and "HELPFUL" or "HARMFUL",
      ownOnly = not item.forceOwnOnly and true or item.ownOnly,
      unitExists = false,
    }
  };

  if item.spellIds then
    if item.exactSpellId then
      triggers[position].trigger.useExactSpellId = true
      triggers[position].trigger.auraspellids = {}
      for index, spell in ipairs(item.spellIds) do
        triggers[position].trigger.auraspellids[index] = tostring(spell)
      end
    else
      triggers[position].trigger.useName = true
      triggers[position].trigger.auranames = {}
      for index, spell in ipairs(item.spellIds) do
        triggers[position].trigger.auranames[index] = tostring(spell)
      end
    end
  else
    if item.exactSpellId then
      triggers[position].trigger.useExactSpellId = true
      triggers[position].trigger.auraspellids = { tostring(item.buffId or item.spell) }
    else
      triggers[position].trigger.useName = true
      triggers[position].trigger.auranames = { tostring(item.buffId or item.spell) }
    end
  end

  if triggers[position].trigger.unit == "multi" and buffShowOn == "showOnActive"  then
    local trigger = triggers[position].trigger
    trigger.useGroup_count = true
    trigger.group_countOperator =  ">="
    trigger.group_count = "1"
  end

  if (item.unit == "group") then
    triggers[position].trigger.name_info = "players";
  end
  if (item.unit == "multi") then
    triggers[position].trigger.spellId = item.buffId or item.spell;
  end
end

local function createDurationTrigger(triggers, position, item)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Combat Log"),
      event = "Combat Log",
      subeventSuffix = "_CAST_SUCCESS",
      use_sourceUnit = true,
      sourceUnit = item.unit or "player",
      use_spellId = true,
      spellId = tostring(item.spell),
      duration = tostring(item.duration),
    }
  };
end

local function createTotemTrigger(triggers, position, item)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Totem"),
      event = "Totem",
      use_totemName = item.totemNumber == nil,
      totemName = GetSpellInfo(item.spell),
    }
  };
  if (item.totemNumber) then
    triggers[position].trigger.use_totemType = true;
    triggers[position].trigger.totemType = item.totemNumber;
  end
end

local function createPowerTrigger(triggers, position, item)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Power"),
      event = "Power",
      use_unit = true,
      unit = "player",
      use_powertype = true,
      use_showCost = true,
      powertype = item.powertype,
    },
  };
end

local function createHealthTrigger(triggers, position, item)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Health"),
      event = "Health",
      unit = "player",
      use_unit = true,
      use_absorbMode = true,
      use_showAbsorb = true,
      use_showIncomingHeal = true,
    },
  };
end

local function createCastTrigger(triggers, position, item)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Cast"),
      event = "Cast",
      use_unit = true,
      unit = item.unit or "player",
    },
  };
end

local function createAbilityTrigger(triggers, position, item, genericShowOn)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Cooldown Progress (Spell)"),
      event = "Cooldown Progress (Spell)",
      spellName = item.spell,
      use_genericShowOn = true,
      genericShowOn = genericShowOn,
    }
  };
  if genericShowOn == "showOnReady" then
    triggers[position].trigger.use_track = true
    triggers[position].trigger.track = "cooldown"
  end
end

local function createItemTrigger(triggers, position, item, genericShowOn)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Cooldown Progress (Item)"),
      event = "Cooldown Progress (Item)",
      use_genericShowOn = true,
      genericShowOn = genericShowOn,
      itemName = item.spell,
    }
  };
end

local function createOverlayGlowTrigger(triggers, position, item)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Spell Activation Overlay"),
      event = "Spell Activation Overlay",
      spellName = item.spell,
    }
  };
end

local function createWeaponEnchantTrigger(triggers, position, item, showOn)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Weapon Enchant"),
      event = "Weapon Enchant",
      use_enchant = true,
      enchant = tostring(item.enchant),
      weapon = item.weapon,
      showOn = showOn
    }
  }
end

local function createQueuedActionTrigger(triggers, position, item)
  triggers[position] = {
    trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Queued Action"),
      event = "Queued Action",
      spellName = item.spell
    }
  }
end

local function createAbilityAndQueuedActionTrigger(triggers, item)
  createAbilityTrigger(triggers, 1, item, "showAlways");
  createQueuedActionTrigger(triggers, 2, item);
end

local function createAbilityAndDurationTrigger(triggers, item)
  createDurationTrigger(triggers, 1, item);
  createAbilityTrigger(triggers, 2, item, "showAlways");
end

local function createAbilityAndBuffTrigger(triggers, item)
  createBuffTrigger(triggers, 1, item, "showOnActive", true);
  createAbilityTrigger(triggers, 2, item, "showAlways");
end

local function createAbilityAndDebuffTrigger(triggers, item)
  createBuffTrigger(triggers, 1, item, "showOnActive", false);
  createAbilityTrigger(triggers, 2, item, "showAlways");
end

local function createAbilityAndOverlayGlowTrigger(triggers, item)
  createAbilityTrigger(triggers, 1, item, "showAlways");
  createOverlayGlowTrigger(triggers, 2, item);
end

-- Create preview thumbnail
local function createThumbnail(parent)
  -- Preview frame
  local borderframe = CreateFrame("Frame", nil, parent);
  borderframe:SetWidth(32);
  borderframe:SetHeight(32);

  -- Preview border
  local border = borderframe:CreateTexture(nil, "OVERLAY");
  border:SetAllPoints(borderframe);
  border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2.blp");
  border:SetTexCoord(0.2, 0.8, 0.2, 0.8);

  -- Main region
  local region = CreateFrame("Frame", nil, borderframe);
  borderframe.region = region;

  -- Preview children
  region.children = {};

  -- Return preview
  return borderframe;
end

local function subTypesFor(item, regionType)
  local types = {};
  local icon = {
    target = function()
      local thumbnail = createThumbnail();
      local t1 = thumbnail:CreateTexture(nil, "ARTWORK");
      t1:SetTexture(134376);
      t1:SetAllPoints(thumbnail);

      thumbnail.elapsed = 0;
      thumbnail:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed;
        if(self.elapsed < 0.5) then
          t1:SetVertexColor(1,0,0,1);
        elseif(self.elapsed < 1.5) then
          t1:SetVertexColor(1,1,1,1);
        elseif(self.elapsed < 3) then
          -- Do nothing
        else
          self.elapsed = self.elapsed - 3;
        end
      end);
      return thumbnail;
    end, -- 132212,
    glow = function()
      local thumbnail = createThumbnail();
      local t1 = thumbnail:CreateTexture(nil, "ARTWORK");
      t1:SetTexture(134376);
      t1:SetAllPoints(thumbnail);
      WeakAuras.ShowOverlayGlow(thumbnail); -- where to call HideOverlayGlow() ?
      return thumbnail;
    end, -- 571554
    charges = function()
      local thumbnail = createThumbnail();
      local t1 = thumbnail:CreateTexture(nil, "ARTWORK");
      t1:SetTexture(134376);
      t1:SetAllPoints(thumbnail);
      local t2 = thumbnail:CreateFontString(nil, "ARTWORK");
      t2:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE");
      t2:SetTextColor(1,1,1,1);
      t2:SetText("2");
      t2:SetPoint("BOTTOMRIGHT", -2, 2);
      return thumbnail;
    end,
    cd = 134377,
    cd2 = 134376,
  };
  local data = {}
  local dataGlow = {}
  if regionType == "aurabar" then
    dataGlow.subRegions = {
      [1] = TemplatePrivate.Private.getDefaultGlow(regionType)
    }
  end
  if (item.type == "ability") then
    tinsert(types, {
      fallback = true,
      icon = icon.cd,
      title = L["Basic Show On Cooldown"],
      description = L["Only shows the aura when the ability is on cooldown."],
      createTriggers = function(triggers, item)
        createAbilityTrigger(triggers, 1, item, "showOnCooldown");
      end,
    });
    tinsert(types, {
      icon = icon.cd,
      title = L["Basic Show On Cooldown"],
      description = L["Only shows the aura when the ability is on cooldown."],
      createTriggers = function(triggers, item)
        createAbilityTrigger(triggers, 1, item, "showOnCooldown");
      end,
      createConditions = function(conditions, item, regionType)
        isNotUsableBlue(conditions, 1, regionType)
      end,
    });
    tinsert(types, {
      icon = icon.cd,
      title = L["Basic Show On Ready"],
      description = L["Only shows the aura when the ability is ready to use."],
      createTriggers = function(triggers, item)
        createAbilityTrigger(triggers, 1, item, "showOnReady");
      end,
      createConditions = function(conditions, item, regionType)
        isNotUsableBlue(conditions, 1, regionType)
      end,
    });
    if (item.charges) then
      data.cooldownSwipe = false
      data.cooldownEdge = true
      dataGlow.cooldownSwipe = false
      dataGlow.cooldownEdge = true
      tinsert(types, {
        icon = icon.charges,
        title = L["Charge Tracking"],
        description = L["Always shows the aura, turns blue on insufficient resources."],
        createTriggers = function(triggers, item)
          createAbilityTrigger(triggers, 1, item, "showAlways");
        end,
        createConditions = function(conditions, item, regionType)
          insufficientResourcesBlue(conditions, 1, regionType);
          hasChargesGrey(conditions, 1, regionType);
        end,
        data = data,
      });
      if (item.duration) then
        tinsert(types, {
          icon = icon.glow,
          title = L["Charge and Duration Tracking"],
          description = L["Tracks the charge and the duration of spell, highlight while the spell is active, blue on insufficient resources."],
          createTriggers = createAbilityAndDurationTrigger,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 2, regionType);
            hasChargesGrey(conditions, 2, regionType);
            isDurationGlow(conditions, 1, regionType);
          end,
          data = dataGlow,
        });
      elseif (item.buff) then
        tinsert(types, {
          icon = icon.glow,
          title = L["Charge and Buff Tracking"],
          description = L["Tracks the charge and the buff, highlight while the buff is active, blue on insufficient resources."],
          createTriggers = createAbilityAndBuffTrigger,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 2, regionType);
            hasChargesGrey(conditions, 2, regionType);
            isBuffedGlow(conditions, 1, regionType);
          end,
          data = dataGlow,
        });
      elseif(item.debuff) then
        tinsert(types, {
          icon = icon.glow,
          title = L["Charge and Debuff Tracking"],
          description = L["Tracks the charge and the debuff, highlight while the debuff is active, blue on insufficient resources."],
          createTriggers = createAbilityAndDebuffTrigger,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 2, regionType);
            hasChargesGrey(conditions, 2, regionType);
            isBuffedGlow(conditions, 1, regionType);
          end,
          data = dataGlow,
        })
      elseif(item.requiresTarget) then
        tinsert(types,  {
          icon = icon.target,
          title = L["Show Charges with Range Tracking"],
          description = L["Always shows the aura, turns red when out of range, blue on insufficient resources."],
          genericShowOn = "showAlways",
          createTriggers = function(triggers, item)
            createAbilityTrigger(triggers, 1, item, "showAlways");
          end,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 1, regionType);
            hasChargesGrey(conditions, 1, regionType);
            isSpellNotInRangeRed(conditions, 1, regionType);
          end,
          data = data,
        });
        if (item.usable) then
          tinsert(types,  {
            icon = icon.target,
            title = L["Show Charges with Usable Check"],
            description = L["Always shows the aura, turns red when out of range, blue on insufficient resources."],
            createTriggers = function(triggers, item)
              createAbilityTrigger(triggers, 1, item, "showAlways");
            end,
            createConditions = function(conditions, item, regionType)
              isNotUsableBlue(conditions, 1, regionType);
              hasChargesGrey(conditions, 1, regionType);
              isSpellNotInRangeRed(conditions, 1, regionType);
            end,
            data = data,
          });
        end
        if (item.overlayGlow) then
          tinsert(types,  {
            icon = icon.glow,
            title = L["Show Charges with Proc Tracking"],
            description = L["Track the charge and proc, highlight while proc is active, turns red when out of range, blue on insufficient resources."],
            createTriggers = createAbilityAndOverlayGlowTrigger,
            createConditions = function(conditions, item, regionType)
              isNotUsableBlue(conditions, 1, regionType);
              hasChargesGrey(conditions, 1, regionType);
              isSpellNotInRangeRed(conditions, 1, regionType);
              overlayGlow(conditions, 2, regionType);
            end,
            data = dataGlow,
          });
        end
      elseif(item.totem) then
        tinsert(types, {
          icon = icon.charges,
          title = L["Show Totem and Charge Information"],
          description = L["Always shows the aura, highlight when active, turns blue on insufficient resources."],
          createTriggers = function(triggers, item)
            createTotemTrigger(triggers, 1, item);
            createAbilityTrigger(triggers, 2, item, "showAlways");
          end,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 2, regionType);
            hasChargesGrey(conditions, 2, regionType);
            totemActiveGlow(conditions, 1, regionType);
          end,
          data = dataGlow,
        });
      elseif(item.usable) then
        tinsert(types, {
          icon = icon.charges,
          title = L["Show Charges and Check Usable"],
          description = L["Always shows the aura, turns blue when not usable."],
          createTriggers = function(triggers, item)
            createAbilityTrigger(triggers, 1, item, "showAlways");
          end,
          createConditions = function(conditions, item, regionType)
            isNotUsableBlue(conditions, 1, regionType);
            hasChargesGrey(conditions, 1, regionType);
          end,
          data = data,
        });
        if (item.overlayGlow) then
          tinsert(types,  {
            icon = icon.glow,
            title = L["Show Charges with Proc Tracking"],
            description = L["Always shows the aura, highlight while proc is active, blue when not usable."],
            createTriggers = createAbilityAndOverlayGlowTrigger,
            createConditions = function(conditions, item, regionType)
              isNotUsableBlue(conditions, 1, regionType);
              hasChargesGrey(conditions, 1, regionType);
              overlayGlow(conditions, 2, regionType);
            end,
            data = dataGlow,
          });
        end
      end
    else -- Ability without charges
      tinsert(types, {
        icon = icon.cd2,
        title = L["Cooldown Tracking"],
        description = L["Always shows the aura, turns blue when not usable."],
        createTriggers = function(triggers, item)
          createAbilityTrigger(triggers, 1, item, "showAlways");
        end,
        createConditions = function(conditions, item, regionType)
          insufficientResourcesBlue(conditions, 1, regionType);
          isOnCdGrey(conditions, 1, regionType);
        end,
      });
      if (item.duration) then
        data.cooldownSwipe = false
        data.cooldownEdge = true
        dataGlow.cooldownSwipe = false
        dataGlow.cooldownEdge = true
        tinsert(types, {
          icon = icon.glow,
          title = L["Show Cooldown and Duration"],
          description = L["Highlight while spell is active."],
          createTriggers = createAbilityAndDurationTrigger,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 2, regionType);
            isOnCdGrey(conditions, 2, regionType);
            isDurationGlow(conditions, 1, regionType);
          end,
          data = dataGlow
        });
        if (item.usable) then
          tinsert(types, {
            icon = icon.glow,
            title = L["Show Cooldown and Duration and Check Usable"],
            description = L["Highlight while active."],
            createTriggers = createAbilityAndDurationTrigger,
            createConditions = function(conditions, item, regionType)
              isNotUsableBlue(conditions, 2, regionType);
              isOnCdGrey(conditions, 2, regionType);
              isDurationGlow(conditions, 1, regionType);
            end,
            data = dataGlow
          });
        end
        if (item.requiresTarget) then
          tinsert(types, {
            icon = icon.target,
            title = L["Show Cooldown and Duration and Check for Target"],
            description = L["Highlight while active, red when out of range."],
            createTriggers = createAbilityAndDurationTrigger,
            createConditions = function(conditions, item, regionType)
              insufficientResourcesBlue(conditions, 2, regionType);
              isOnCdGrey(conditions, 2, regionType);
              isSpellNotInRangeRed(conditions, 2, regionType);
              isDurationGlow(conditions, 1, regionType);
            end,
            data = dataGlow
          });
        end
      elseif (item.queued) then
        tinsert(types, {
          icon = icon.glow,
          title = L["Show Cooldown and Action Queued"],
          description = L["Highlight while action is queued."],
          createTriggers = createAbilityAndQueuedActionTrigger,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 1, regionType);
            isOnCdGrey(conditions, 1, regionType);
            isQueuedGlow(conditions, 2, regionType);
          end,
          data = dataGlow
        });
      elseif (item.buff) then
        tinsert(types, {
          icon = icon.glow,
          title = L["Show Cooldown and Buff"],
          description = L["Highlight while buffed."],
          createTriggers = createAbilityAndBuffTrigger,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 2, regionType);
            isOnCdGrey(conditions, 2, regionType);
            isBuffedGlow(conditions, 1, regionType);
          end,
          data = dataGlow
        });
        if (item.usable) then
          tinsert(types, {
            icon = icon.glow,
            title = L["Show Cooldown and Buff and Check Usable"],
            description = L["Highlight while buffed."],
            createTriggers = createAbilityAndBuffTrigger,
            createConditions = function(conditions, item, regionType)
              isNotUsableBlue(conditions, 2, regionType);
              isOnCdGrey(conditions, 2, regionType);
              isBuffedGlow(conditions, 1, regionType);
            end,
            data = dataGlow
          });
        end
        if (item.requiresTarget) then
          tinsert(types, {
            icon = icon.target,
            title = L["Show Cooldown and Buff and Check for Target"],
            description = L["Highlight while buffed, red when out of range."],
            createTriggers = createAbilityAndBuffTrigger,
            createConditions = function(conditions, item, regionType)
              if item.usable then
                isNotUsableBlue(conditions, 2, regionType);
              else
                insufficientResourcesBlue(conditions, 2, regionType);
              end
              isOnCdGrey(conditions, 2, regionType);
              isSpellNotInRangeRed(conditions, 2, regionType);
              isBuffedGlow(conditions, 1, regionType);
            end,
            data = dataGlow
          });
        end
      elseif(item.debuff) then
        tinsert(types, {
          icon = icon.glow,
          title = L["Show Cooldown and Debuff"],
          description = L["Highlight while debuffed."],
          createTriggers = createAbilityAndDebuffTrigger,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 2, regionType);
            isOnCdGrey(conditions, 2, regionType);
            isBuffedGlow(conditions, 1, regionType);
          end,
          data = dataGlow
        });
        if (item.requiresTarget) then
          tinsert(types, {
            icon = icon.target,
            title = L["Show Cooldown and Debuff and Check for Target"],
            description = L["Highlight while debuffed, red when out of range."],
            createTriggers = createAbilityAndDebuffTrigger,
            createConditions = function(conditions, item, regionType)
              if item.usable then
                isNotUsableBlue(conditions, 2, regionType);
              else
                insufficientResourcesBlue(conditions, 2, regionType);
              end
              isOnCdGrey(conditions, 2, regionType);
              isSpellNotInRangeRed(conditions, 2, regionType);
              isBuffedGlow(conditions, 1, regionType);
            end,
            data = dataGlow
          });
        end
      elseif(item.totem) then
        tinsert(types, {
          icon = icon.cd2,
          title = L["Show Cooldown and Totem Information"],
          description = L["Always shows the aura, turns grey if the ability is not usable."],
          createTriggers = function(triggers, item)
            createTotemTrigger(triggers, 1, item);
            createAbilityTrigger(triggers, 2, item, "showAlways");
          end,
          createConditions = function(conditions, item, regionType)
            insufficientResourcesBlue(conditions, 2, regionType);
            isOnCdGrey(conditions, 2, regionType);
            totemActiveGlow(conditions, 1, regionType);
          end,
          data = dataGlow
        });
      else
        if (item.requiresTarget) then
          tinsert(types, {
            icon = icon.target,
            title = L["Show Cooldown and Check for Target"],
            description = L["Always shows the aura, turns red when out of range."],
            createTriggers = function(triggers, item)
              createAbilityTrigger(triggers, 1, item, "showAlways");
            end,
            createConditions = function(conditions, item, regionType)
              insufficientResourcesBlue(conditions, 1, regionType);
              isOnCdGrey(conditions, 1, regionType);
              isSpellNotInRangeRed(conditions, 1, regionType);
            end,
          });
          if (item.overlayGlow) then
            tinsert(types,  {
              icon = icon.glow,
              title = L["Show Cooldown and Check for Target & Proc Tracking"],
              description = L["Always shows the aura, highlight while proc is active, turns red when out of range, blue on insufficient resources."],
              createTriggers = createAbilityAndOverlayGlowTrigger,
              createConditions = function(conditions, item, regionType)
                insufficientResourcesBlue(conditions, 1, regionType);
                isOnCdGrey(conditions, 1, regionType);
                isSpellNotInRangeRed(conditions, 1, regionType);
                overlayGlow(conditions, 2, regionType);
              end,
              data = dataGlow
            });
          end
        elseif (item.overlayGlow) then
          tinsert(types,  {
            icon = icon.glow,
            title = L["Show Cooldown and Proc Tracking"],
            description = L["Always shows the aura, highlight while proc is active, blue on insufficient resources."],
            createTriggers = createAbilityAndOverlayGlowTrigger,
            createConditions = function(conditions, item, regionType)
              insufficientResourcesBlue(conditions, 1, regionType);
              isOnCdGrey(conditions, 1, regionType);
              overlayGlow(conditions, 2, regionType);
            end,
            data = dataGlow
          });
        end
        if (item.usable) then
          tinsert(types, {
            icon = icon.cd2,
            title = L["Show Cooldown and Check Usable"],
            description = L["Always shows the aura, turns grey if the ability is not usable."],
            createTriggers = function(triggers, item)
              createAbilityTrigger(triggers, 1, item, "showAlways");
            end,
            createConditions = function(conditions, item, regionType)
              isNotUsableBlue(conditions, 1, regionType);
              isOnCdGrey(conditions, 1, regionType);
            end,
          });
          if (item.requiresTarget) then
            tinsert(types, {
              icon = icon.target,
              title = L["Show Cooldown and Check Usable & Target"],
              description = L["Always shows the aura, turns grey if the ability is not usable and red when out of range."],
              createTriggers = function(triggers, item)
                createAbilityTrigger(triggers, 1, item, "showAlways");
              end,
              createConditions = function(conditions, item, regionType)
                isNotUsableBlue(conditions, 1, regionType);
                isOnCdGrey(conditions, 1, regionType);
                isSpellNotInRangeRed(conditions, 1, regionType);
              end,
            });
            if (item.overlayGlow) then
              tinsert(types,  {
                icon = icon.glow,
                title = L["Show Cooldown and Check Usable, Target & Proc Tracking"],
                description = L["Always shows the aura, highlight while proc is active, turns red when out of range, blue on insufficient resources."],
                createTriggers = createAbilityAndOverlayGlowTrigger,
                createConditions = function(conditions, item, regionType)
                  isNotUsableBlue(conditions, 1, regionType);
                  isOnCdGrey(conditions, 1, regionType);
                  isSpellNotInRangeRed(conditions, 1, regionType);
                  overlayGlow(conditions, 2, regionType);
                end,
                data = dataGlow
              });
            end
          else
            if (item.overlayGlow) then
              tinsert(types,  {
                icon = icon.glow,
                title = L["Show Cooldown and Check Usable, Proc Tracking"],
                description = L["Always shows the aura, highlight while proc is active, blue on insufficient resources."],
                createTriggers = createAbilityAndOverlayGlowTrigger,
                createConditions = function(conditions, item, regionType)
                  isNotUsableBlue(conditions, 1, regionType);
                  isOnCdGrey(conditions, 1, regionType);
                  overlayGlow(conditions, 2, regionType);
                end,
                data = dataGlow
              });
            end
          end
        end
      end
    end
  elseif(item.type == "buff") then
    data.inverse = false
    dataGlow.inverse = false
    tinsert(types, {
      icon = icon.cd,
      title = L["Show Only if Buffed"],
      description = L["Only shows the aura if the target has the buff."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 1, item, "showOnActive", true);
      end,
      data = data,
    });
    tinsert(types, {
      icon = icon.glow,
      title = L["Always Show"],
      description = L["Always shows the aura, highlight it if buffed."],
      buffShowOn = "showAlways",
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 1, item, "showAlways", true);
      end,
      createConditions = function(conditions, item, regionType)
        isBuffedGlowAuraAlways(conditions, 1, regionType);
      end,
      data = dataGlow,
    });
    tinsert(types, {
      icon = icon.cd2,
      title = L["Always Show"],
      description = L["Always shows the aura, grey if buff not active."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 1, item, "showAlways", true);
      end,
      createConditions = function(conditions, item, regionType)
        missingBuffGreyed(conditions, 1, regionType);
      end,
      data = data,
    });
  elseif(item.type == "debuff") then
    data.inverse = false
    dataGlow.inverse = false
    tinsert(types, {
      icon = icon.cd,
      title = L["Show Only if Debuffed"],
      description = L["Only show the aura if the target has the debuff."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 1, item, "showOnActive", false);
      end,
      data = data,
    });
    tinsert(types, {
      icon = icon.glow,
      title = L["Always Show"],
      description = L["Always show the aura, highlight it if debuffed."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 1, item, "showAlways", false);
      end,
      createConditions = function(conditions, item, regionType)
        isBuffedGlowAuraAlways(conditions, 1, regionType);
      end,
      data = dataGlow,
    });
    tinsert(types, {
      icon = icon.cd2,
      title = L["Always Show"],
      description = L["Always show the aura, turns grey if the debuff not active."],
      createTriggers = function(triggers, item)
        createBuffTrigger(triggers, 1, item, "showAlways", false);
      end,
      createConditions = function(conditions, item, regionType)
        missingBuffGreyed(conditions, 1, regionType);
      end,
      data = data,
    });
  elseif(item.type == "item") then
    tinsert(types, {
      icon = icon.cd,
      title = L["Show Only if on Cooldown"],
      description = L["Only show the aura when the item is on cooldown."],
      createTriggers = function(triggers, item)
        createItemTrigger(triggers, 1, item, "showOnCooldown");
      end,
    });
    tinsert(types, {
      icon = icon.cd,
      title = L["Show on Ready"],
      description = L["Only shows the aura when the ability is ready to use."],
      createTriggers = function(triggers, item)
        createItemTrigger(triggers, 1, item, "showOnReady");
      end,
    });
    tinsert(types, {
      icon = icon.cd2,
      title = L["Always Show"],
      description = L["Always show the aura, turns grey if on cooldown."],
      createTriggers = function(triggers, item)
        createItemTrigger(triggers, 1, item, "showAlways");
      end,
      createConditions = function(conditions, item, regionType)
        isOnCdGrey(conditions, 1, regionType);
      end,
    });
  elseif(item.type == "totem") then
    tinsert(types, {
      fallback = true,
      icon = icon.cd2,
      title = L["Always Show"],
      description = L["Always shows the aura."],
      createTriggers = function(triggers, item)
        createTotemTrigger(triggers, 1, item);
      end,
    });
    tinsert(types, {
      icon = icon.cd2,
      title = L["Always Show"],
      description = L["Always shows the aura, turns grey if on cooldown."],
      createTriggers = function(triggers, item)
        createTotemTrigger(triggers, 1, item);
      end,
      createConditions = function(conditions, item, regionType)
        totemActiveGlow(conditions, 1, regionType);
      end,
      data = dataGlow
    });
  elseif(item.type == "power") then
    data.inverse = false
    data.icon = false
    data.text = false
    tinsert(types, {
      icon = item.icon,
      title = item.title,
      createTriggers = function(triggers, item)
        createPowerTrigger(triggers, 1, item);
      end,
      data = data,
    });
  elseif(item.type == "health") then
    data.inverse = false
    data.icon = false
    data.text = false
    tinsert(types, {
      icon = item.icon,
      title = item.title,
      createTriggers = function(triggers, item)
        createHealthTrigger(triggers, 1, item);
      end,
      data = data,
    });
  elseif(item.type == "cast") then
    data.inverse = false
    tinsert(types, {
      fallback = true,
      icon = item.icon,
      title = item.title,
      createTriggers = function(triggers, item)
        createCastTrigger(triggers, 1, item);
      end,
      data = data,
    });
    tinsert(types, {
      icon = item.icon,
      title = item.title,
      createTriggers = function(triggers, item)
        createCastTrigger(triggers, 1, item);
      end,
      createConditions = function(conditions, item, regionType)
        uninterruptibleRed(conditions, 1, regionType);
      end,
      data = data,
    });
  elseif (item.type == "weaponenchant") then
    data.inverse = false
    tinsert(types, {
      icon = icon.cd,
      title = L["Show Only if Enchanted"],
      description = L["Only shows if the weapon is enchanted."],
      createTriggers = function(triggers, item)
        createWeaponEnchantTrigger(triggers, 1, item, "showOnActive");
      end,
      data = data,
    });
    tinsert(types, {
      icon = icon.cd,
      title = L["Show if Enchant Missing"],
      description = L["Only shows if the weapon is not enchanted."],
      createTriggers = function(triggers, item)
        createWeaponEnchantTrigger(triggers, 1, item, "showOnMissing");
      end,
      data = data,
    });
    tinsert(types, {
      icon = icon.glow,
      title = L["Show Always, Glow on Missing"],
      description = L["Always shows highlights if enchant missing."],
      createTriggers = function(triggers, item)
        createWeaponEnchantTrigger(triggers, 1, item, "showAlways");
      end,
      createConditions = function(conditions, item, regionType)
        isMissingEnchantGlow(conditions, 1, regionType);
      end,
      data = dataGlow,
    });
  end

  -- filter when createConditions return nothing for this regionType
  local fallbacks = {}
  for index = #types, 1, -1 do
    local type = types[index];
    if type.createConditions then
      local conditions = {}
      type.createConditions(conditions, item, regionType)
      if #conditions == 0 then
        tremove(types, index);
      end
    elseif type.fallback then
      tremove(types, index);
      tinsert(fallbacks, type)
    end
  end

  if #types > 0 then
    return types
  end
  return fallbacks
end

function WeakAuras.CreateTemplateView(Private, frame)
  TemplatePrivate.Private = Private

  -- Enrich Display templates with default values
  for regionType, regionData in pairs(TemplatePrivate.Private.regionOptions) do
    if (regionData.templates) then
      for _, item in ipairs(regionData.templates) do
        for k, v in pairs(TemplatePrivate.Private.regionTypes[regionType].default) do
          if (item.data[k] == nil) then
            item.data[k] = v
          end
        end
      end
    end
  end

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

  local function createConditionsFor(item, subType, regionType)
    if (subType.createConditions) then
      local conditions = {};
      subType.createConditions(conditions, item, regionType);
      return conditions;
    end
  end

  local function replaceCondition(data, item, subType)
    local conditions = createConditionsFor(item, subType, data.regionType);
    if conditions then
      data.conditions = CopyTable(conditions);
    end
  end

  local function addCondition(data, item, subType, prevNumTriggers)
    local conditions = createConditionsFor(item, subType, data.regionType);
    if conditions then
      if data.conditions then
        local position = #data.conditions + 1;
        for i,v in pairs(conditions) do
          data.conditions[position] = data.conditions[position] or {};
          if v.check.trigger ~= -1 then
            v.check.trigger = v.check.trigger + prevNumTriggers;
          end
          data.conditions[position] = CopyTable(v);
          position = position + 1;
        end
      else
        data.conditions = CopyTable(conditions);
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
    local triggers;
    if (item.triggers) then
      triggers = item.triggers;
    else
      triggers = createTriggersFor(item, subType);
    end

    data.triggers = {}
    for i, v in pairs(triggers) do
      data.triggers[i] = data.triggers[i] or {};
      data.triggers[i].trigger = CopyTable(v.trigger);
      data.triggers[i].untrigger = {};
      if (v.untrigger) then
        data.triggers[i].untrigger = CopyTable(v.untrigger);
      end
    end
    if (#data.triggers > 1) then -- Multiple triggers
      data.triggers.disjunctive = "any";
      data.triggers.activeTriggerMode = -10;
    end
  end

  local function addTrigger(data, item, subType)
    local triggers;
    if (item.triggers) then
      triggers = item.triggers;
    else
      triggers = createTriggersFor(item, subType);
    end

    for i, v in pairs(triggers) do
      local position = #data.triggers + 1
      data.triggers[position] = data.triggers[position] or {};
      data.triggers[position].trigger = CopyTable(v.trigger);
      data.triggers[position].untrigger = {};
      if (v.untrigger) then
        data.triggers[position].untrigger = CopyTable(v.untrigger);
      end
    end
     -- Multiple Triggers, override disjunctive, even if the users set it previously
    if (triggers[2]) then
      data.triggers.disjunctive = "any";
      data.triggers.activeTriggerMode = -10;
    end
  end

  local createButtons;

  local function createRegionButton(regionType, regionData, selectedItem)
    local button = AceGUI:Create("WeakAurasNewButton");
    button:SetTitle(regionData.displayName);
    if(type(regionData.icon) == "string" or type(regionData.icon) == "table") then
      button:SetIcon(regionData.templateIcon);
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
        templateButton:SetThumbnail(regionType, item.data)
      end

      templateButton:SetTitle(item.title);
      templateButton:SetDescription(item.description);
      templateButton:SetClick(function()
        newView.data = CopyTable(item.data);
        TemplatePrivate.Private.validate(newView.data, TemplatePrivate.Private.data_stub);
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

  local function batchModeToggler(value)
    if (not value) then
      -- clean selection
      for k in pairs(newView.chosenItemBatch) do
        newView.chosenItemBatch[k] = nil;
      end
      for k, f in pairs(newView.chosenItemButtonsBatch) do
        f.frame:UnlockHighlight();
        newView.chosenItemButtonsBatch[k] = nil;
      end
      newView.batchButton:Hide();
    end
  end

  local function createTriggerFlyout(section, fullWidth)
    local group = AceGUI:Create("WeakAurasTemplateGroup");
    group:SetFullWidth(true);
    newView.chosenItemBatch = {};
    newView.chosenItemButtonsBatch = {};
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
          if (IsControlKeyDown() and not newView.existingAura) then
            if newView.chosenItemBatch[item] then
              button.frame:UnlockHighlight();
              newView.chosenItemBatch[item] = nil;
              newView.chosenItemButtonsBatch[j] = nil;
            else
              button.frame:LockHighlight();
              newView.chosenItemBatch[item] = true;
              newView.chosenItemButtonsBatch[j] = button;
            end
            local count = 0;
            for _ in pairs(newView.chosenItemBatch) do
              count = count + 1;
            end
            if count == 0 then
              newView.batchButton:Hide();
              newView.backButton:ClearAllPoints()
              newView.backButton:SetPoint("BOTTOMRIGHT", -147, -23);
            else
              newView.batchButton:Show();
              newView.backButton:ClearAllPoints()
              newView.backButton:SetPoint("BOTTOMRIGHT", -267, -23);
            end
          else
            newView.backButton:ClearAllPoints()
            newView.backButton:SetPoint("BOTTOMRIGHT", -147, -23);
            local subTypes = subTypesFor(item, newView.data.regionType);
            if #subTypes < 2 then
              local subType = subTypes[1] or {}
              if (newView.existingAura) then
                newView.chosenItem = item;
                newView.chosenSubType = subType;
                createButtons();
              else
                replaceTrigger(newView.data, item, subType);
                replaceCondition(newView.data, item, subType);
                newView.data.id = TemplatePrivate.Private.FindUnusedId(item.title);
                newView.data.load = {};
                if (item.load) then
                  newView.data.load = CopyTable(item.load);
                end
                if (subType.data) then
                  WeakAuras.DeepMixin(newView.data, subType.data)
                end
                newView:CancelClose();
                WeakAuras.NewAura(newView.data, newView.data.regionType, newView.targetId);
              end
            else
              -- create trigger type selection
              newView.chosenItem = item;
              createButtons();
            end
          end
        end);
        group:AddChild(button);
      end
    end
    return group;
  end

  local function createTriggerTypeButtons()
    local item = newView.chosenItem;
    local group = AceGUI:Create("WeakAurasTemplateGroup");
    group:SetFullWidth(true);
    local subTypes = subTypesFor(item, newView.data.regionType);
    local subTypesButtons = {}
    local lastButton
    for k, subType in pairs(subTypes) do
      local button = AceGUI:Create("WeakAurasNewButton");
      subTypesButtons[k] = button;
      button:SetTitle(subType.title);
      button:SetDescription(subType.description);
      if subType.icon then
        if type(subType.icon) == "function" then
          button:SetIcon(subType.icon());
        else
          button:SetIcon(subType.icon);
        end
      end
      button:SetFullWidth(true);
      button:SetClick(function()
        if (newView.batchStep) then
          for index, subTypesButton in pairs(subTypesButtons) do
            if (index == k) then
              subTypesButton.frame:LockHighlight();
            else
              subTypesButton.frame:UnlockHighlight();
            end
          end
          newView.chosenItemBatchSubType[item] = subType;
        elseif (newView.existingAura) then
          newView.chosenItem = item;
          newView.chosenSubType = subType;
          createButtons();
        else
          replaceTrigger(newView.data, item, subType);
          replaceCondition(newView.data, item, subType);
          newView.data.id = TemplatePrivate.Private.FindUnusedId(item.title);
          newView.data.load = {};
          if (item.load) then
            newView.data.load = CopyTable(item.load);
          end
          if (subType.data) then
            WeakAuras.DeepMixin(newView.data, subType.data)
          end
          newView:CancelClose();
          WeakAuras.NewAura(newView.data, newView.data.regionType, newView.targetId);
        end
      end);
      if newView.batchStep then
        button.frame:LockHighlight();
        newView.chosenItemBatchSubType[item] = subType;
        if lastButton then
          lastButton.frame:UnlockHighlight();
        end
        lastButton = button
      end
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
      if section.args and next(section.args) then
        createTriggerButton(section, selectedItem, fullWidth);
      end
    end
  end

  local function replaceTriggers(data, item, subType)
    local function handle(data, item, subType)
      replaceTrigger(data, item, subType);
      replaceCondition(data, item, subType);
      newView:CancelClose();
      WeakAuras.Add(data);
      WeakAuras.ClearAndUpdateOptions(data.id)
      WeakAuras.FillOptions()
      WeakAuras.NewDisplayButton(data);
      WeakAuras.UpdateThumbnail(data);
    end
    for child in TemplatePrivate.Private.TraverseLeafsOrAura(data) do
      handle(child, item, subType);
    end
    WeakAuras.ClearAndUpdateOptions(data.id)
  end

  local function addTriggers(data, item, subType)
    local function handle(data, item, subType)
      local prevNumTriggers = #data.triggers;
      addTrigger(data, item, subType);
      addCondition(data, item, subType, prevNumTriggers);
      newView:CancelClose();
      WeakAuras.Add(data);
      WeakAuras.ClearAndUpdateOptions(data.id)
      WeakAuras.FillOptions()
      WeakAuras.NewDisplayButton(data);
      WeakAuras.UpdateThumbnail(data);
    end
    for child in TemplatePrivate.Private.TraverseLeafsOrAura(data) do
      handle(child, item, subType);
    end
    WeakAuras.ClearAndUpdateOptions(data.id)
  end

  local function createLastPage()
    local replaceButton = AceGUI:Create("WeakAurasNewButton");
    replaceButton:SetTitle(L["Replace Triggers"]);
    replaceButton:SetDescription(L["Replace all existing triggers"]);
    replaceButton:SetIcon("Interface\\Icons\\Spell_ChargeNegative");
    replaceButton:SetFullWidth(true);
    replaceButton:SetClick(function()
      replaceTriggers(newView.data, newView.chosenItem, newView.chosenSubType);
      for _,v in pairs({"class", "spec", "talent", "pvptalent", "race", "covenant"}) do
        newView.data.load[v] = nil;
        newView.data.load["use_"..v] = nil;
      end
      newView.data.load.class = CopyTable(TemplatePrivate.Private.data_stub.load.class);
      newView.data.load.spec = CopyTable(TemplatePrivate.Private.data_stub.load.spec);
      if (newView.chosenItem.load) then
        WeakAuras.DeepMixin(newView.data.load, newView.chosenItem.load)
      end
    end);
    newViewScroll:AddChild(replaceButton);

    local addButton = AceGUI:Create("WeakAurasNewButton");
    addButton:SetTitle(L["Add Triggers"]);
    addButton:SetDescription(L["Keeps existing triggers intact"]);
    addButton:SetIcon("Interface\\Icons\\Spell_ChargePositive");
    addButton:SetFullWidth(true);
    addButton:SetClick(function()
      addTriggers(newView.data, newView.chosenItem, newView.chosenSubType);
    end);
    newViewScroll:AddChild(addButton);
  end

  createButtons = function(selectedItem) -- selectedItem is either a regionType or a trigger section
    newViewScroll:ReleaseChildren();
    newView.makeBatchButton:Hide();
    newView.batchButton:Hide();
    newView.batchModeLabel:Hide();
    if (not newView.data) then
      -- First step: Show region types
      for regionType, regionData in pairs(TemplatePrivate.Private.regionOptions) do
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
    elseif (newView.data and newView.batchStep) then
      -- Batch
      if (newView.batchStep) then
        newView.chosenItemBatchSubType = {};
        for item in pairs(newView.chosenItemBatch) do
          local classHeader = AceGUI:Create("Heading");
          classHeader:SetFullWidth(true);
          newViewScroll:AddChild(classHeader);

          local button = AceGUI:Create("WeakAurasNewButton");
          button:SetTitle(item.title);
          button:SetDescription(item.description);
          button:SetFullWidth(true);
          if(item.icon) then
            button:SetIcon(item.icon);
          end
          newViewScroll:AddChild(button);

          newView.chosenItem = item;
          local typesButtons = createTriggerTypeButtons();
          newViewScroll:AddChild(typesButtons);
        end
        newView.makeBatchButton:Show()
        newView.backButton:ClearAllPoints()
        newView.backButton:SetPoint("BOTTOMRIGHT", -267, -23);
      end
      newView.batchModeLabel:Hide();
    elseif (newView.data and not newView.chosenItem) then
      -- Second step: Trigger selection screen

      -- Class
      local classSelector = createDropdown("class", WeakAuras.class_types);
      newViewScroll:AddChild(classSelector);

      if WeakAuras.IsRetail() then
        local specSelector = createDropdown("spec", WeakAuras.spec_types_specific[newView.class]);
        newViewScroll:AddChild(specSelector);
        newViewScroll:AddChild(createSpacer());
      end
      if (TemplatePrivate.triggerTemplates.class[newView.class] and TemplatePrivate.triggerTemplates.class[newView.class][newView.spec]) then
        createTriggerButtons(TemplatePrivate.triggerTemplates.class[newView.class][newView.spec], selectedItem);
      end
      local classHeader = AceGUI:Create("Heading");
      classHeader:SetFullWidth(true);
      newViewScroll:AddChild(classHeader);

      createTriggerButton(TemplatePrivate.triggerTemplates.general, selectedItem);

      -- Race
      local raceHeader = AceGUI:Create("Heading");
      raceHeader:SetFullWidth(true);
      newViewScroll:AddChild(raceHeader);
      local raceSelector = createDropdown("race", WeakAuras.race_types);
      newViewScroll:AddChild(raceSelector);
      newViewScroll:AddChild(createSpacer());
      if (TemplatePrivate.triggerTemplates.race[newView.race]) then
        local group = createTriggerFlyout(TemplatePrivate.triggerTemplates.race[newView.race], true)
        newViewScroll:AddChild(group);
      end

      -- backButton
      if (not newView.existingAura) then
        newView.backButton:Show();
      end

      -- batchButton
      newView.chosenItemBatch = {};
      if not newView.existingAura then
        newView.batchModeLabel:Show();
      end
    elseif (newView.data and newView.chosenItem and not newView.chosenSubType) then
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

  local batchModeLabel = CreateFrame("Frame", "batchModeLabel", newView.frame);
  batchModeLabel:SetSize(300, 20);
  local batchModeLabelString = batchModeLabel:CreateFontString(nil, "ARTWORK");
  batchModeLabelString:SetFont(STANDARD_TEXT_FONT, 10); -- "OUTLINE"
  batchModeLabelString:SetTextColor(1,1,1,1);
  batchModeLabelString:SetText(L["Hold CTRL to create multiple auras at once"]);
  batchModeLabelString:SetJustifyH("LEFT")
  batchModeLabelString:SetAllPoints(batchModeLabel);
  batchModeLabel:SetPoint("BOTTOMLEFT", 10, -23);
  newView.batchModeLabel = batchModeLabel;

  local newViewMakeBatch = CreateFrame("Button", nil, newView.frame, "UIPanelButtonTemplate");
  newViewMakeBatch:SetScript("OnClick", function()
    local saveData = CopyTable(newView.data);
    for item in pairs(newView.chosenItemBatch) do
      -- clean data
      newView.data = CopyTable(saveData);
      -- copy data
      local subType = newView.chosenItemBatchSubType[item]
      replaceTrigger(newView.data, item, subType);
      replaceCondition(newView.data, item, subType);
      newView.data.id = TemplatePrivate.Private.FindUnusedId(item.title);
      newView.data.load = {};
      if (item.load) then
        newView.data.load = CopyTable(item.load);
      end
      if (subType.data) then
        WeakAuras.DeepMixin(newView.data, subType.data)
      end
      -- create aura
      WeakAuras.NewAura(newView.data, newView.data.regionType, newView.targetId);
    end
    newView:CancelClose();
  end);
  newViewMakeBatch:SetPoint("BOTTOMRIGHT", -147, -23);
  newViewMakeBatch:SetHeight(20);
  newViewMakeBatch:SetWidth(100);
  newViewMakeBatch:SetText(L["Create Auras"]);
  newView.makeBatchButton = newViewMakeBatch;
  newView.makeBatchButton:Hide();

  local newViewBatch = CreateFrame("Button", nil, newView.frame, "UIPanelButtonTemplate");
  newViewBatch:SetScript("OnClick", function()
    newView.batchStep = true;
    newView.batchButton:Hide();
    createButtons();
  end);
  newViewBatch:SetPoint("BOTTOMRIGHT", -147, -23);
  newViewBatch:SetHeight(20);
  newViewBatch:SetWidth(100);
  newViewBatch:SetText(L["Next"]);
  newView.batchButton = newViewBatch;
  newView.batchButton:Hide();

  local newViewBack = CreateFrame("Button", nil, newView.frame, "UIPanelButtonTemplate");
  newViewBack:SetScript("OnClick", function()
    if (newView.existingAura) then
      if newView.chosenSubType then
        newView.chosenSubType = nil;
        local subTypes = subTypesFor(newView.chosenItem, newView.data.regionType);
        if #subTypes < 2 then -- No subtype selection, go back twice
          newView.chosenItem = nil;
        end
      else
        newView.chosenItem = nil;
      end
    else
      if newView.chosenSubType then
        newView.chosenSubType = nil;
      else
        if newView.chosenItem then
          newView.chosenItem = nil;
        else
          newView.data = nil;
        end
      end
    end
    newView.batchButton:Hide();
    newView.chosenItemBatch = {};
    newView.batchStep = nil;
    newView.backButton:ClearAllPoints()
    newView.backButton:SetPoint("BOTTOMRIGHT", -147, -23);
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

  function newView.Open(self, data, targetId)
    frame.window = "newView";
    frame:UpdateFrameVisible()
    self.targetId = targetId
    self.data = data -- Might be nil
    if (data) then
      newView.existingAura = true;
      newView.chosenItem = nil;
      newView.chosenSubType = nil;
    else
      newView.existingAura = false;
      newView.chosenItem = nil;
      newView.chosenSubType = nil;
      newView.batchStep = nil;
      newView.chosenItemBatch = {};
    end
    newView.class = select(2, UnitClass("player"));
    if WeakAuras.IsRetail() then
      newView.spec = GetSpecialization() or 1;
    else
      newView.spec = 1
    end
    newView.race = select(2, UnitRace('player'));

    createButtons();
  end

  function newView.CancelClose(self)
    frame.window = "default";
    frame:UpdateFrameVisible()
    if (not self.data) then
      frame:NewAura();
    end
  end

  return newView;
end
