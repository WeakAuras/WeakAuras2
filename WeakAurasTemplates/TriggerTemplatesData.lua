local AddonName, TemplatePrivate = ...
local WeakAuras = WeakAuras
if not WeakAuras.IsRetail() then return end
local L = WeakAuras.L
local GetSpellInfo, tinsert, GetItemInfo, GetSpellDescription, C_Timer, Spell = GetSpellInfo, tinsert, GetItemInfo, GetSpellDescription, C_Timer, Spell

-- The templates tables are created on demand
local templates =
  {
    class = { },
    race = {
      Human = {},
      NightElf = {},
      Dwarf = {},
      Gnome = {},
      Draenei = {},
      Worgen = {},
      Pandaren = {},
      Orc = {},
      Scourge = {},
      Tauren = {},
      Troll = {},
      BloodElf = {},
      Goblin = {},
      Nightborne = {},
      LightforgedDraenei = {},
      HighmountainTauren = {},
      VoidElf = {},
      ZandalariTroll = {},
      KulTiran = {},
      DarkIronDwarf = {},
      Vulpera = {},
      MagharOrc = {},
      Mechagnome = {}
    },
    general = {
      title = L["General"],
      icon = 136116,
      args = {}
    },
  }

local manaIcon = "Interface\\Icons\\inv_elemental_mote_mana"
local rageIcon = "Interface\\Icons\\spell_misc_emotionangry"
local comboPointsIcon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01"

local powerTypes =
  {
    [0] = { name = POWER_TYPE_MANA, icon = manaIcon },
    [1] = { name = POWER_TYPE_RED_POWER, icon = rageIcon},
    [2] = { name = POWER_TYPE_FOCUS, icon = "Interface\\Icons\\ability_hunter_focusfire"},
    [3] = { name = POWER_TYPE_ENERGY, icon = "Interface\\Icons\\spell_shadow_shadowworddominate"},
    [4] = { name = COMBO_POINTS, icon = comboPointsIcon},
    [6] = { name = RUNIC_POWER, icon = "Interface\\Icons\\inv_sword_62"},
    [7] = { name = SOUL_SHARDS_POWER, icon = "Interface\\Icons\\inv_misc_gem_amethyst_02"},
    [8] = { name = POWER_TYPE_LUNAR_POWER, icon = "Interface\\Icons\\ability_druid_eclipseorange"},
    [9] = { name = HOLY_POWER, icon = "Interface\\Icons\\achievement_bg_winsoa"},
    [11] = {name = POWER_TYPE_MAELSTROM, icon = 135990},
    [12] = {name = CHI_POWER, icon = "Interface\\Icons\\ability_monk_healthsphere"},
    [13] = {name = POWER_TYPE_INSANITY, icon = "Interface\\Icons\\spell_priest_shadoworbs"},
    [16] = {name = POWER_TYPE_ARCANE_CHARGES, icon = "Interface\\Icons\\spell_arcane_arcane01"},
    [17] = {name = POWER_TYPE_FURY_DEMONHUNTER, icon = 1344651},
    [18] = {name = POWER_TYPE_PAIN, icon = 1247265},
    [99] = {name = STAGGER, icon = "Interface\\Icons\\monk_stance_drunkenox"}
  }

-- Collected by WeakAurasTemplateCollector:
--------------------------------------------------------------------------------
templates.class.EVOKER = {
  [1] = { -- Devastation
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 370818, type = "buff", unit = "player", talent = 31 }, -- Snapfire
        { spell = 370454, type = "buff", unit = "player", talent = 24 }, -- Charged Blast
        { spell = 375802, type = "buff", unit = "player", talent = 30 }, -- Burnout
        { spell = 357210, type = "buff", unit = "player" }, -- Deep Breath
        { spell = 372470, type = "buff", unit = "player", talent = 87 }, -- Scarlet Adaptation
        { spell = 186403, type = "buff", unit = "player" }, -- Sign of Battle
        { spell = 386353, type = "buff", unit = "player" }, -- Iridescence: Red
        { spell = 376850, type = "buff", unit = "player", talent = 17 }, -- Power Swell
        { spell = 370553, type = "buff", unit = "player", talent = 86 }, -- Tip the Scales
        { spell = 375087, type = "buff", unit = "player", talent = 38 }, -- Dragonrage
        { spell = 363916, type = "buff", unit = "player", talent = 75 }, -- Obsidian Scales
        { spell = 386399, type = "buff", unit = "player" }, -- Iridescence: Blue
        { spell = 374348, type = "buff", unit = "player", talent = 52 }, -- Renewing Blaze
        { spell = 358267, type = "buff", unit = "player" }, -- Hover
        { spell = 236321, type = "buff", unit = "player" }, -- War Banner
        { spell = 358733, type = "buff", unit = "player" }, -- Glide
        { spell = 366646, type = "buff", unit = "player" }, -- Familiar Skies
        { spell = 370901, type = "buff", unit = "player", talent = 62 }, -- Leaping Flames
        { spell = 2479, type = "buff", unit = "player" }, -- Honorless Target
        { spell = 375234, type = "buff", unit = "player", talent = 49 }, -- Time Spiral
        { spell = 361509, type = "buff", unit = "player" }, -- Living Flame
        { spell = 374227, type = "buff", unit = "player", talent = 55 }, -- Zephyr
        { spell = 390386, type = "buff", unit = "player" }, -- Fury of the Aspects
        { spell = 359618, type = "buff", unit = "player", talent = 45 }, -- Essence Burst
        { spell = 381748, type = "buff", unit = "player" }, -- Blessing of the Bronze
      },
      icon = 458972
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 357209, type = "debuff", unit = "target" }, -- Fire Breath
        { spell = 372048, type = "debuff", unit = "target", talent = 68 }, -- Oppressing Roar
        { spell = 360806, type = "debuff", unit = "target", talent = 4 }, -- Sleep Walk
        { spell = 361500, type = "debuff", unit = "target" }, -- Living Flame
        { spell = 357214, type = "debuff", unit = "target" }, -- Wing Buffet
        { spell = 370898, type = "debuff", unit = "target", talent = 76 }, -- Permeating Chill
        { spell = 370452, type = "debuff", unit = "target", talent = 14 }, -- Shattering Star
        { spell = 372245, type = "debuff", unit = "target", talent = 48 }, -- Terror of the Skies
        { spell = 355689, type = "debuff", unit = "target", talent = 81 }, -- Landslide
        { spell = 356995, type = "debuff", unit = "target" }, -- Disintegrate
        { spell = 353759, type = "debuff", unit = "target" }, -- Deep Breath
        { spell = 368970, type = "debuff", unit = "target" }, -- Tail Swipe
      },
      icon = 458972
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 351338, type = "ability", requiresTarget = true, talent = 65 }, -- Quell
        { spell = 355913, type = "ability" }, -- Emerald Blossom
        { spell = 356995, type = "ability", overlayGlow = true, requiresTarget = true }, -- Disintegrate
        { spell = 357208, type = "ability", overlayGlow = true }, -- Fire Breath
        { spell = 357210, type = "ability", buff = true }, -- Deep Breath
        { spell = 357211, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 42 }, -- Pyre
        { spell = 357214, type = "ability" }, -- Wing Buffet
        { spell = 358267, type = "ability", charges = true, buff = true, overlayGlow = true }, -- Hover
        { spell = 358385, type = "ability", talent = 81 }, -- Landslide
        { spell = 358733, type = "ability", buff = true }, -- Glide
        { spell = 359073, type = "ability", overlayGlow = true, requiresTarget = true, talent = 20 }, -- Eternity Surge
        { spell = 360806, type = "ability", requiresTarget = true, talent = 4 }, -- Sleep Walk
        { spell = 360995, type = "ability", requiresTarget = true, talent = 88 }, -- Verdant Embrace
        { spell = 361469, type = "ability", requiresTarget = true }, -- Living Flame
        { spell = 361584, type = "ability" }, -- Whirling Surge
        { spell = 362969, type = "ability", requiresTarget = true }, -- Azure Strike
        { spell = 363916, type = "ability", buff = true, talent = 75 }, -- Obsidian Scales
        { spell = 364342, type = "ability" }, -- Blessing of the Bronze
        { spell = 365585, type = "ability", talent = 89 }, -- Expunge
        { spell = 368432, type = "ability", overlayGlow = true, requiresTarget = true, talent = 63 }, -- Unravel
        { spell = 368847, type = "ability", overlayGlow = true, talent = 32 }, -- Firestorm
        { spell = 368970, type = "ability" }, -- Tail Swipe
        { spell = 369536, type = "ability", usable = true }, -- Soar
        { spell = 370452, type = "ability", requiresTarget = true, talent = 14 }, -- Shattering Star
        { spell = 370553, type = "ability", buff = true, talent = 86 }, -- Tip the Scales
        { spell = 370665, type = "ability", talent = 58 }, -- Rescue
        { spell = 372048, type = "ability", talent = 68 }, -- Oppressing Roar
        { spell = 372608, type = "ability" }, -- Surge Forward
        { spell = 372610, type = "ability" }, -- Skyward Ascent
        { spell = 374227, type = "ability", buff = true, talent = 55 }, -- Zephyr
        { spell = 374251, type = "ability", talent = 73 }, -- Cauterizing Flame
        { spell = 374348, type = "ability", buff = true, talent = 52 }, -- Renewing Blaze
        { spell = 374968, type = "ability", talent = 49 }, -- Time Spiral
        { spell = 375087, type = "ability", buff = true, talent = 38 }, -- Dragonrage
        { spell = 383332, type = "ability" }, -- Time Stop
        { spell = 390386, type = "ability", buff = true }, -- Fury of the Aspects
      },
      icon = 136012
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {
      title = L["PvP Talents"],
      args = {
        { spell = 378464, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Nullifying Shroud
        { spell = 378441, type = "buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"] }, -- Time Stop
        { spell = 383005, type = "debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"] }, -- Chrono Loop
        { spell = 378441, type = "ability", buff = true, pvptalent = 5, titleSuffix = L["cooldown"] }, -- Time Stop
        { spell = 378464, type = "ability", buff = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Nullifying Shroud
        { spell = 383005, type = "ability", requiresTarget = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Chrono Loop
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
    },
  },
  [2] = { -- Preservation
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 381748, type = "buff", unit = "player" }, -- Blessing of the Bronze
        { spell = 377102, type = "buff", unit = "player", talent = 10 }, -- Exhilarating Burst
        { spell = 357210, type = "buff", unit = "player" }, -- Deep Breath
        { spell = 370960, type = "buff", unit = "player", talent = 9 }, -- Emerald Communion
        { spell = 378001, type = "buff", unit = "player" }, -- Dream Projection
        { spell = 377088, type = "buff", unit = "player", talent = 8 }, -- Rush of Vitality
        { spell = 358267, type = "buff", unit = "player" }, -- Hover
        { spell = 374348, type = "buff", unit = "player", talent = 55 }, -- Renewing Blaze
        { spell = 370537, type = "buff", unit = "player", talent = 18 }, -- Stasis
        { spell = 370553, type = "buff", unit = "player", talent = 89 }, -- Tip the Scales
        { spell = 370901, type = "buff", unit = "player", talent = 65 }, -- Leaping Flames
        { spell = 390148, type = "buff", unit = "player", talent = 25 }, -- Flow State
        { spell = 2479, type = "buff", unit = "player" }, -- Honorless Target
        { spell = 375234, type = "buff", unit = "player", talent = 52 }, -- Time Spiral
        { spell = 370840, type = "buff", unit = "player", talent = 38 }, -- Empath
        { spell = 390386, type = "buff", unit = "player" }, -- Fury of the Aspects
        { spell = 374227, type = "buff", unit = "player", talent = 58 }, -- Zephyr
        { spell = 357170, type = "buff", unit = "player", talent = 28 }, -- Time Dilation
        { spell = 363502, type = "buff", unit = "player", talent = 12 }, -- Dream Flight
        { spell = 363534, type = "buff", unit = "player", talent = 27 }, -- Rewind
        { spell = 375583, type = "buff", unit = "player", talent = 74 }, -- Ancient Flame
        { spell = 373646, type = "buff", unit = "player" }, -- Soar
        { spell = 387350, type = "buff", unit = "player", talent = 15 }, -- Ouroboros
        { spell = 358134, type = "buff", unit = "player" }, -- Star Burst
        { spell = 358733, type = "buff", unit = "player" }, -- Glide
        { spell = 373835, type = "buff", unit = "player", talent = 33 }, -- Call of Ysera
        { spell = 370562, type = "buff", unit = "player", talent = 18 }, -- Stasis
        { spell = 373267, type = "buff", unit = "player", talent = 49 }, -- Lifebind
        { spell = 363916, type = "buff", unit = "player", talent = 78 }, -- Obsidian Scales
        { spell = 359816, type = "buff", unit = "player", talent = 12 }, -- Dream Flight
        { spell = 362877, type = "buff", unit = "player", talent = 41 }, -- Temporal Compression
        { spell = 366646, type = "buff", unit = "player" }, -- Familiar Skies
        { spell = 372014, type = "buff", unit = "player" }, -- Visage
        { spell = 364343, type = "buff", unit = "player", talent = 43 }, -- Echo
        { spell = 369299, type = "buff", unit = "player", talent = 45 }, -- Essence Burst
        { spell = 372470, type = "buff", unit = "player", talent = 90 }, -- Scarlet Adaptation
        { spell = 366155, type = "buff", unit = "player", talent = 44 }, -- Reversion
        { spell = 186403, type = "buff", unit = "player" }, -- Sign of Battle
        { spell = 367364, type = "buff", unit = "player", talent = 44 }, -- Reversion
        { spell = 363534, type = "buff", unit = "target", talent = 27 }, -- Rewind
        { spell = 364343, type = "buff", unit = "target", talent = 43 }, -- Echo
        { spell = 357170, type = "buff", unit = "target", talent = 28 }, -- Time Dilation
        { spell = 373862, type = "buff", unit = "target", talent = 26 }, -- Temporal Anomaly
        { spell = 381923, type = "buff", unit = "target", talent = 14 }, -- Renewing Breath
      },
      icon = 458972
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 356995, type = "debuff", unit = "target" }, -- Disintegrate
        { spell = 357209, type = "debuff", unit = "target" }, -- Fire Breath
        { spell = 360806, type = "debuff", unit = "target", talent = 4 }, -- Sleep Walk
        { spell = 368970, type = "debuff", unit = "target" }, -- Tail Swipe
        { spell = 357214, type = "debuff", unit = "target" }, -- Wing Buffet
        { spell = 370898, type = "debuff", unit = "target", talent = 79 }, -- Permeating Chill
        { spell = 372245, type = "debuff", unit = "target", talent = 51 }, -- Terror of the Skies
        { spell = 355689, type = "debuff", unit = "target", talent = 84 }, -- Landslide
        { spell = 353759, type = "debuff", unit = "target" }, -- Deep Breath
      },
      icon = 458972
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 351338, type = "ability", requiresTarget = true, talent = 68 }, -- Quell
        { spell = 355913, type = "ability", overlayGlow = true }, -- Emerald Blossom
        { spell = 355936, type = "ability", overlayGlow = true, talent = 42 }, -- Dream Breath
        { spell = 356995, type = "ability", overlayGlow = true, requiresTarget = true }, -- Disintegrate
        { spell = 357170, type = "ability", buff = true, debuff = true, talent = 28 }, -- Time Dilation
        { spell = 357208, type = "ability", overlayGlow = true }, -- Fire Breath
        { spell = 357210, type = "ability", buff = true }, -- Deep Breath
        { spell = 357214, type = "ability" }, -- Wing Buffet
        { spell = 358267, type = "ability", charges = true, buff = true, overlayGlow = true }, -- Hover
        { spell = 358385, type = "ability", talent = 84 }, -- Landslide
        { spell = 358733, type = "ability", buff = true }, -- Glide
        { spell = 359816, type = "ability", buff = true, talent = 12 }, -- Dream Flight
        { spell = 360806, type = "ability", requiresTarget = true, talent = 4 }, -- Sleep Walk
        { spell = 360823, type = "ability" }, -- Naturalize
        { spell = 360995, type = "ability", requiresTarget = true, talent = 91 }, -- Verdant Embrace
        { spell = 361469, type = "ability", requiresTarget = true }, -- Living Flame
        { spell = 362969, type = "ability", requiresTarget = true }, -- Azure Strike
        { spell = 363534, type = "ability", charges = true, buff = true, debuff = true, talent = 27 }, -- Rewind
        { spell = 363916, type = "ability", buff = true, talent = 78 }, -- Obsidian Scales
        { spell = 364342, type = "ability" }, -- Blessing of the Bronze
        { spell = 364343, type = "ability", buff = true, debuff = true, overlayGlow = true, talent = 43 }, -- Echo
        { spell = 366155, type = "ability", charges = true, buff = true, talent = 44 }, -- Reversion
        { spell = 367226, type = "ability", overlayGlow = true, talent = 40 }, -- Spiritbloom
        { spell = 368970, type = "ability" }, -- Tail Swipe
        { spell = 369536, type = "ability", usable = true }, -- Soar
        { spell = 370537, type = "ability", buff = true, usable = true, talent = 18 }, -- Stasis
        { spell = 370553, type = "ability", buff = true, usable = true, talent = 89 }, -- Tip the Scales
        { spell = 370665, type = "ability", talent = 61 }, -- Rescue
        { spell = 370960, type = "ability", buff = true, talent = 9 }, -- Emerald Communion
        { spell = 373861, type = "ability", talent = 26 }, -- Temporal Anomaly
        { spell = 374227, type = "ability", buff = true, talent = 58 }, -- Zephyr
        { spell = 374251, type = "ability", talent = 76 }, -- Cauterizing Flame
        { spell = 374348, type = "ability", buff = true, talent = 55 }, -- Renewing Blaze
        { spell = 374968, type = "ability", talent = 52 }, -- Time Spiral
        { spell = 382266, type = "ability", overlayGlow = true }, -- Fire Breath
        { spell = 382614, type = "ability", overlayGlow = true, talent = 42 }, -- Dream Breath
        { spell = 382731, type = "ability", overlayGlow = true, talent = 40 }, -- Spiritbloom
        { spell = 390386, type = "ability", buff = true }, -- Fury of the Aspects
      },
      icon = 136012
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {
      title = L["PvP Talents"],
      args = {
        { spell = 377509, type = "buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"] }, -- Dream Projection
        { spell = 377509, type = "ability", buff = true, pvptalent = 10, titleSuffix = L["cooldown"] }, -- Dream Projection
        { spell = 383005, type = "ability", requiresTarget = true, pvptalent = 9, titleSuffix = L["cooldown"] }, -- Chrono Loop
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
    },
  }
}

templates.class.WARRIOR = {
  [1] = { -- Arms
  },
  [2] = { -- Fury
  },
  [3] = { -- Protection
  }
}

templates.class.PALADIN = {
  [1] = { -- Holy
  },
  [2] = { -- Protection
  },
  [3] = { -- Retribution
  },
}

templates.class.HUNTER = {
  [1] = { -- Beast Master
  },
  [2] = { -- Marksmanship
  },
  [3] = { -- Survival
  },
}

templates.class.ROGUE = {
  [1] = { -- Assassination
  },
  [2] = { -- Outlaw
  },
  [3] = { -- Subtlety
  },
}

templates.class.PRIEST = {
  [1] = { -- Discipline
  },
  [2] = { -- Holy
  },
  [3] = { -- Shadow
  },
}

templates.class.SHAMAN = {
  [1] = { -- Elemental
  },
  [2] = { -- Enhancement
  },
  [3] = { -- Restoration
  },
}

templates.class.MAGE = {
  [1] = { -- Arcane
  },
  [2] = { -- Fire
  },
  [3] = { -- Frost
  },
}

templates.class.WARLOCK = {
  [1] = { -- Affliction
  },
  [2] = { -- Demonology
  },
  [3] = { -- Destruction
  },
}

templates.class.MONK = {
  [1] = { -- Brewmaster
  },
  [2] = { -- Mistweaver
  },
  [3] = { -- Windwalker
  },
}

templates.class.DRUID = {
  [1] = { -- Balance
  },
  [2] = { -- Feral
  },
  [3] = { -- Guardian
  },
  [4] = { -- Restoration
  },
}

templates.class.DEMONHUNTER = {
  [1] = { -- Havoc
  },
  [2] = { -- Vengeance
  },
}

templates.class.DEATHKNIGHT = {
  [1] = { -- Blood
  },
  [2] = { -- Frost
  },
  [3] = { -- Unholy
  },
}

-- General Section
tinsert(templates.general.args, {
  title = L["Health"],
  icon = "Interface\\Icons\\inv_alchemy_70_red",
  type = "health"
});
tinsert(templates.general.args, {
  title = L["Cast"],
  icon = 136209,
  type = "cast"
});
tinsert(templates.general.args, {
  title = L["Always Active"],
  icon = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura78",
  triggers = {[1] = { trigger = {
    type = WeakAuras.GetTriggerCategoryFor("Conditions"),
    event = "Conditions",
    use_alwaystrue = true}}}
});

tinsert(templates.general.args, {
  title = L["Pet alive"],
  icon = "Interface\\Icons\\ability_hunter_pet_raptor",
  triggers = {[1] = { trigger = {
    type = WeakAuras.GetTriggerCategoryFor("Conditions"),
    event = "Conditions",
    use_HasPet = true}}}
});

tinsert(templates.general.args, {
  title = L["Pet Behavior"],
  icon = "Interface\\Icons\\Ability_hunter_pet_assist",
  triggers = {[1] = { trigger = {
    type = WeakAuras.GetTriggerCategoryFor("Pet Behavior"),
    event = "Pet Behavior",
    use_behavior = true,
    behavior = "assist"}}}
});

tinsert(templates.general.args, {
  spell = 2825, type = "buff", unit = "player",
  forceOwnOnly = true,
  ownOnly = nil,
  overideTitle = L["Bloodlust/Heroism"],
  spellIds = {2825, 32182, 80353, 264667}}
);

-- Meta template for Power triggers
local function createSimplePowerTemplate(powertype)
  local power = {
    title = powerTypes[powertype].name,
    icon = powerTypes[powertype].icon,
    type = "power",
    powertype = powertype,
  }
  return power;
end

-------------------------------
-- Hardcoded trigger templates
-------------------------------
local resourceSection = 11
-- Warrior
for i = 1, 3 do
  tinsert(templates.class.WARRIOR[i][resourceSection].args, createSimplePowerTemplate(1));
end

-- Paladin
for i = 1, 3 do
  tinsert(templates.class.PALADIN[i][resourceSection].args, createSimplePowerTemplate(9));
  tinsert(templates.class.PALADIN[i][resourceSection].args, createSimplePowerTemplate(0));
end

-- Hunter
for i = 1, 3 do
  tinsert(templates.class.HUNTER[i][resourceSection].args, createSimplePowerTemplate(2));
end

-- Rogue
for i = 1, 3 do
  tinsert(templates.class.ROGUE[i][resourceSection].args, createSimplePowerTemplate(3));
  tinsert(templates.class.ROGUE[i][resourceSection].args, createSimplePowerTemplate(4));
end

-- Priest
for i = 1, 3 do
  tinsert(templates.class.PRIEST[i][resourceSection].args, createSimplePowerTemplate(0));
end
tinsert(templates.class.PRIEST[3][resourceSection].args, createSimplePowerTemplate(13));

-- Shaman
for i = 1, 3 do
  tinsert(templates.class.SHAMAN[i][resourceSection].args, createSimplePowerTemplate(0));
end
for i = 1, 2 do
  tinsert(templates.class.SHAMAN[i][resourceSection].args, createSimplePowerTemplate(11));
end

-- Mage
tinsert(templates.class.MAGE[1][resourceSection].args, createSimplePowerTemplate(16));
for i = 1, 3 do
  tinsert(templates.class.MAGE[i][resourceSection].args, createSimplePowerTemplate(0));
end

-- Warlock
for i = 1, 3 do
  tinsert(templates.class.WARLOCK[i][resourceSection].args, createSimplePowerTemplate(0));
  tinsert(templates.class.WARLOCK[i][resourceSection].args, createSimplePowerTemplate(7));
end

-- Monk
tinsert(templates.class.MONK[1][resourceSection].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[2][resourceSection].args, createSimplePowerTemplate(0));
tinsert(templates.class.MONK[3][resourceSection].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[3][resourceSection].args, createSimplePowerTemplate(12));

-- Druid
for i = 1, 4 do
  -- Shapeshift Form
  tinsert(templates.class.DRUID[i][resourceSection].args, {
    title = L["Shapeshift Form"],
    icon = 132276,
    triggers = {[1] = { trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Stance/Form/Aura"),
      event = "Stance/Form/Aura",
      }}}
  });
end
for j, id in ipairs({5487, 768, 783, 114282, 1394966}) do
  local title, _, icon = GetSpellInfo(id)
  if title then
    for i = 1, 4 do
      tinsert(templates.class.DRUID[i][resourceSection].args, {
        title = title,
        icon = icon,
        triggers = {
          [1] = {
            trigger = {
              type = WeakAuras.GetTriggerCategoryFor("Stance/Form/Aura"),
              event = "Stance/Form/Aura",
              use_form = true,
              form = { single = j }
            }
          }
        }
      });
    end
  end
end

-- Astral Power
tinsert(templates.class.DRUID[1][resourceSection].args, createSimplePowerTemplate(8));

for i = 1, 4 do
  tinsert(templates.class.DRUID[i][resourceSection].args, createSimplePowerTemplate(0)); -- Mana
  tinsert(templates.class.DRUID[i][resourceSection].args, createSimplePowerTemplate(1)); -- Rage
  tinsert(templates.class.DRUID[i][resourceSection].args, createSimplePowerTemplate(3)); -- Energy
  tinsert(templates.class.DRUID[i][resourceSection].args, createSimplePowerTemplate(4)); -- Combo Points
end

-- Efflorescence aka Mushroom
tinsert(templates.class.DRUID[4][3].args,  {spell = 145205, type = "totem"});

-- Demon Hunter
tinsert(templates.class.DEMONHUNTER[1][resourceSection].args, createSimplePowerTemplate(17));
tinsert(templates.class.DEMONHUNTER[2][resourceSection].args, createSimplePowerTemplate(17));

-- Death Knight
for i = 1, 3 do
  tinsert(templates.class.DEATHKNIGHT[i][resourceSection].args, createSimplePowerTemplate(6));

  tinsert(templates.class.DEATHKNIGHT[i][resourceSection].args, {
    title = L["Runes"],
    icon = "Interface\\Icons\\spell_deathknight_frozenruneweapon",
    triggers = {[1] = { trigger = {
      type = WeakAuras.GetTriggerCategoryFor("Death Knight Rune"),
      event = "Death Knight Rune"}}}
  });
end

------------------------------
-- Hardcoded race templates
-------------------------------

-- Every Man for Himself
tinsert(templates.race.Human, { spell = 59752, type = "ability" });
-- Stoneform
tinsert(templates.race.Dwarf, { spell = 20594, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Dwarf, { spell = 65116, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Shadow Meld
tinsert(templates.race.NightElf, { spell = 58984, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.NightElf, { spell = 58984, type = "buff", titleSuffix = L["buff"]});
-- Escape Artist
tinsert(templates.race.Gnome, { spell = 20589, type = "ability" });
-- Gift of the Naaru
tinsert(templates.race.Draenei, { spell = 28880, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Draenei, { spell = 28880, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Dark Flight
tinsert(templates.race.Worgen, { spell = 68992, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Worgen, { spell = 68992, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Quaking Palm
tinsert(templates.race.Pandaren, { spell = 107079, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Pandaren, { spell = 107079, type = "buff", titleSuffix = L["buff"]});
-- Blood Fury
tinsert(templates.race.Orc, { spell = 20572, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Orc, { spell = 20572, type = "buff", unit = "player", titleSuffix = L["buff"]});
--Cannibalize
tinsert(templates.race.Scourge, { spell = 20577, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Scourge, { spell = 20578, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- War Stomp
tinsert(templates.race.Tauren, { spell = 20549, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Tauren, { spell = 20549, type = "debuff", titleSuffix = L["debuff"]});
--Beserking
tinsert(templates.race.Troll, { spell = 26297, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Troll, { spell = 26297, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Arcane Torrent
tinsert(templates.race.BloodElf, { spell = 69179, type = "ability", titleSuffix = L["cooldown"]});
-- Pack Hobgoblin
tinsert(templates.race.Goblin, { spell = 69046, type = "ability" });
-- Rocket Barrage
tinsert(templates.race.Goblin, { spell = 69041, type = "ability" });

-- Arcane Pulse
tinsert(templates.race.Nightborne, { spell = 260364, type = "ability" });
-- Cantrips
tinsert(templates.race.Nightborne, { spell = 255661, type = "ability" });
-- Light's Judgment
tinsert(templates.race.LightforgedDraenei, { spell = 255647, type = "ability" });
-- Forge of Light
tinsert(templates.race.LightforgedDraenei, { spell = 259930, type = "ability" });
-- Bull Rush
tinsert(templates.race.HighmountainTauren, { spell = 255654, type = "ability" });
--Spatial Rift
tinsert(templates.race.VoidElf, { spell = 256948, type = "ability" });
-- Fireblood
tinsert(templates.race.DarkIronDwarf, { spell = 265221, type = "ability" });
-- Mole Machine
tinsert(templates.race.DarkIronDwarf, { spell = 265225, type = "ability" });
--Haymaker
tinsert(templates.race.KulTiran, { spell = 287712, type = "ability", requiresTarget = true });
-- Brush it Off
tinsert(templates.race.KulTiran, { spell = 291843, type = "buff"});
-- Hyper Organic Light Originator
tinsert(templates.race.Mechagnome, { spell = 312924, type = "ability" });
-- Combat Anlysis
tinsert(templates.race.Mechagnome, { spell = 313424, type = "buff" });
-- Recently Failed
tinsert(templates.race.Mechagnome, { spell = 313015, type = "debuff" });
-- Ancestral Call
tinsert(templates.race.MagharOrc, { spell = 274738, type = "ability" });
-- ZandalariTroll = {}
-- Pterrordax Swoop
tinsert(templates.race.ZandalariTroll, { spell = 281954, type = "ability" });
-- Regenratin'
tinsert(templates.race.ZandalariTroll, { spell = 291944, type = "ability" });
-- Embrace of the Loa
tinsert(templates.race.ZandalariTroll, { spell = 292752, type = "ability" });
-- Vulpera = {}
-- Bag of Tricks
tinsert(templates.race.Vulpera, { spell = 312411, type = "ability" });
-- Make Camp
tinsert(templates.race.Vulpera, { spell = 312370, type = "ability" });


------------------------------
-- Helper code for options
-------------------------------

-- Enrich items from spell, set title
local function handleItem(item)
  local waitingForItemInfo = false;
  if (item.spell) then
    local name, icon, _;
    if (item.type == "item") then
      name, _, _, _, _, _, _, _, _, icon = GetItemInfo(item.spell);
      if (name == nil) then
        name = L["Unknown Item"] .. " " .. tostring(item.spell);
        waitingForItemInfo = true;
      end
    else
      name, _, icon = GetSpellInfo(item.spell);
      if (name == nil) then
        name = L["Unknown Spell"] .. " " .. tostring(item.spell);
      end
    end
    if (icon and not item.icon) then
      item.icon = icon;
    end

    item.title = item.overideTitle or name or "";
    if (item.titleSuffix) then
      item.title = item.title .. " " .. item.titleSuffix;
    end
    if (item.titlePrefix) then
      item.title = item.titlePrefix .. item.title;
    end
    if (item.titleItemPrefix) then
      local prefix = GetItemInfo(item.titleItemPrefix);
      if (prefix) then
        item.title = prefix .. "-" .. item.title;
      else
        waitingForItemInfo = true;
      end
    end
    if (item.type ~= "item") then
      local spell = Spell:CreateFromSpellID(item.spell);
      if (not spell:IsSpellEmpty()) then
        spell:ContinueOnSpellLoad(function()
          item.description = GetSpellDescription(spell:GetSpellID());
        end);
      end
      item.description = GetSpellDescription(item.spell);
    end
  end
  if (item.talent) then
    item.load = item.load or {};
    if type(item.talent) == "table" then
      item.load.talent = { multi = {} };
      for _,v in pairs(item.talent) do
        item.load.talent.multi[v] = true;
      end
      item.load.use_talent = false;
    else
      item.load.talent = {
        single = item.talent,
        multi = {};
      };
      item.load.use_talent = true;
    end
  end
  if (item.pvptalent) then
    item.load = item.load or {};
    item.load.use_pvptalent = true;
    item.load.pvptalent = {
      single = item.pvptalent,
      multi = {};
    }
  end
  -- form field is lazy handled by a usable condition
  if item.form then
    item.usable = true
  end
  return waitingForItemInfo;
end

local function addLoadCondition(item, loadCondition)
  -- No need to deep copy here, templates are read-only
  item.load = item.load or {};
  for k, v in pairs(loadCondition) do
    item.load[k] = v;
  end
end

local delayedEnrichDatabase = false;
local itemInfoReceived = CreateFrame("Frame")

local enrichTries = 0;
local function enrichDatabase()
  if (enrichTries > 3) then
    return;
  end
  enrichTries = enrichTries + 1;

  local waitingForItemInfo = false;
  for className, class in pairs(templates.class) do
    for specIndex, spec in pairs(class) do
      for _, section in pairs(spec) do
        local loadCondition = {
          use_class = true, class = { single = className, multi = {} },
          use_spec = true, spec = { single = specIndex, multi = {}}
        };
        for itemIndex, item in pairs(section.args or {}) do
          local handle = handleItem(item)
          if(handle) then
            waitingForItemInfo = true;
          end
          addLoadCondition(item, loadCondition);
        end
      end
    end
  end

  for raceName, race in pairs(templates.race) do
    local loadCondition = {
      use_race = true, race = { single = raceName, multi = {} }
    };
    for _, item in pairs(race) do
      local handle = handleItem(item)
      if handle then
        waitingForItemInfo = true;
      end
      if handle ~= nil then
        addLoadCondition(item, loadCondition);
      end
    end
  end

  for _, item in pairs(templates.general.args) do
    if (handleItem(item)) then
      waitingForItemInfo = true;
    end
  end

  if (waitingForItemInfo) then
    itemInfoReceived:RegisterEvent("GET_ITEM_INFO_RECEIVED");
  else
    itemInfoReceived:UnregisterEvent("GET_ITEM_INFO_RECEIVED");
  end
end

local function fixupIcons()
  for className, class in pairs(templates.class) do
    for specIndex, spec in pairs(class) do
      for _, section in pairs(spec) do
        if section.args then
          for _, item in pairs(section.args) do
            if (item.spell and (not item.type ~= "item")) then
              local icon = select(3, GetSpellInfo(item.spell));
              if (icon) then
                item.icon = icon;
              end
            end
          end
        end
      end
    end
  end
end

local fixupIconsFrame = CreateFrame("Frame");
fixupIconsFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
fixupIconsFrame:SetScript("OnEvent", fixupIcons);

enrichDatabase();

itemInfoReceived:SetScript("OnEvent", function()
  if (not delayedEnrichDatabase) then
    delayedEnrichDatabase = true;
    C_Timer.After(2, function()
      enrichDatabase();
      delayedEnrichDatabase = false;
    end)
  end
end);


-- Enrich Display templates with default values
for regionType, regionData in pairs(WeakAuras.regionOptions) do
  if (regionData.templates) then
    for _, item in ipairs(regionData.templates) do
      for k, v in pairs(WeakAuras.regionTypes[regionType].default) do
        if (item.data[k] == nil) then
          item.data[k] = v;
        end
      end
    end
  end
end

WeakAuras.triggerTemplates = templates;
