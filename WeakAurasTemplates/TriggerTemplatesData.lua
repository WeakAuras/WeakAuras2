local WeakAuras = WeakAuras
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
      VoidElf = {}
    },
    general = {
      title = L["General"],
      icon = 136116,
      args = {}
    },
    items = {
    },
  }

local powerTypes =
  {
    [0] = { name = MANA, icon = "Interface\\Icons\\inv_elemental_mote_mana" },
    [1] = { name = RAGE, icon = "Interface\\Icons\\spell_misc_emotionangry"},
    [2] = { name = FOCUS, icon = "Interface\\Icons\\ability_hunter_focusfire"},
    [3] = { name = ENERGY, icon = "Interface\\Icons\\spell_shadow_shadowworddominate"},
    [4] = { name = COMBO_POINTS, icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01"},
    [6] = { name = RUNIC_POWER, icon = "Interface\\Icons\\inv_sword_62"},
    [7] = { name = SOUL_SHARDS, icon = "Interface\\Icons\\inv_misc_gem_amethyst_02"},
    [8] = { name = LUNAR_POWER, icon = "Interface\\Icons\\ability_druid_eclipseorange"},
    [9] = { name = HOLY_POWER, icon = "Interface\\Icons\\achievement_bg_winsoa"},
    [11] = {name = MAELSTROM, icon = 135990},
    [12] = {name = CHI, icon = "Interface\\Icons\\ability_monk_healthsphere"},
    [13] = {name = INSANITY, icon = "Interface\\Icons\\spell_priest_shadoworbs"},
    [16] = {name = ARCANE_CHARGES, icon = "Interface\\Icons\\spell_arcane_arcane01"},
    [17] = {name = FURY, icon = 1344651},
    [18] = {name = PAIN, icon = 1247265},
    [99] = {name = L["Stagger"], icon = "Interface\\Icons\\monk_stance_drunkenox"}
  }

-- Collected by WeakAurasTemplateCollector:

templates.class.WARRIOR = {
  [1] = { -- Arms
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 458972
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 464973
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 132355
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198827, type = "debuff", unit = "target", pvptalent = 17}, -- Echo Slam
        { spell = 198760, type = "buff", unit = "group", pvptalent = 13}, -- Intercept
        { spell = 198817, type = "ability", pvptalent = 18}, -- Spell Reflection
        { spell = 236077, type = "debuff", unit = "target", titleSuffix = L["debuff"], pvptalent = 8 }, -- Disarm
        { spell = 236077, type = "ability", titleSuffix = L["cooldown"], pvptalent = 8 }, -- Disarm
        { spell = 236273, type = "debuff", unit = "target", titleSuffix = L["debuff"], pvptalent = 14 }, -- Duel
        { spell = 236273, type = "ability", titleSuffix = L["cooldown"], pvptalent = 14 }, -- Duel
        { spell = 236320, type = "ability", pvptalent = 15 }, -- War Banner
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_misc_emotionangry",
    },
  },
  [2] = { -- Fury
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 136224
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 132154
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 136012
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_misc_emotionangry",
    },
  },
  [3] = { -- Protection
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 1377132
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 132090
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 134951
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_misc_emotionangry",
    },
  },
}

templates.class.PALADIN = {
  [1] = { -- Holy
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 236254
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {

      },
      icon = 135972
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [2] = { -- Protection
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 236265
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 135874
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [3] = { -- Retribution
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 135993
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 135891
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\achievement_bg_winsoa",
    },
  },
}

templates.class.HUNTER = {
  [1] = { -- Beast Master
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135860
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 132176
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\ability_hunter_focusfire",
    },
  },
  [2] = { -- Marksmanship
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 461846
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 236188
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 132329
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\ability_hunter_focusfire",
    },
  },
  [3] = { -- Survival
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 1376044
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 132309
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 236184
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\ability_hunter_focusfire",
    },
  },
}


templates.class.ROGUE = {
  [1] = { -- Assassination
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 132302
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 458726
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01",
    },
  },
  [2] = { -- Outlaw
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 132350
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 1373908
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 135610
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01",
    },
  },
  [3] = { -- Subtlety
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 376022
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 136175
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 236279
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01",
    },
  },
}

templates.class.PRIEST = {
  [1] = { -- Discipline
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 458720
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 253400
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [2] = { -- Holy
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 135953
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135972
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 135937
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [3] = { -- Shadow
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 237566
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 136230
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_priest_shadoworbs",
    },
  },
}

templates.class.SHAMAN = {
  [1] = { -- Elemental
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 451169
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 135790
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = 135990,
    },
  },
  [2] = { -- Enhancement
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 136099
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 462327
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 1370984
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = 135990,
    },
  },
  [3] = { -- Restoration
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 252995
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 135127
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
}

templates.class.MAGE = {
  [1] = { -- Arcane
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135848
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 136075
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_arcane_arcane01",
    },
  },
  [2] = { -- Fire
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 1035045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135818
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 610633
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [3] = { -- Frost
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 236227
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 236208
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 629077
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
}


templates.class.WARLOCK = {
  [1] = { -- Affliction
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 136139
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 615103
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
    },
  },
  [2] = { -- Demonology
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 1378284
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 136122
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 1378282
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
    },
  },
  [3] = { -- Destruction
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 135817
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 135807
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
    },
  },
}

templates.class.MONK = {
  [1] = { -- Brewmaster
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 613398
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 611419
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 133701
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\monk_stance_drunkenox",
    },
  },
  [2] = { -- Mistweaver
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 627487
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 627485
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [3] = { -- Windwalker
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 611420
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 627606
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\ability_monk_healthsphere",
    },
  },
}

templates.class.DRUID = {
  [1] = { -- Balance
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 535045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 236216
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 136060
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = "Interface\\Icons\\ability_druid_eclipseorange",
    },
  },
  [2] = { -- Feral
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 136170
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 132152
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 236149
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01",
    },
  },
  [3] = { -- Guardian
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 1378702
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 451161
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 236169
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = "Interface\\Icons\\spell_misc_emotionangry",
    },
  },
  [4] = { -- Restoration
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 136081
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 236216
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 236153
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
}

templates.class.DEMONHUNTER = {
  [1] = { -- Havoc
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 1247266
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 1392554
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 1305156
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = 1344651,
    },
  },
  [2] = { -- Vengeance
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 1247263
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 1344647
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 1344650
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = 1247265,
    },
  },
}

templates.class.DEATHKNIGHT = {
  [1] = { -- Blood
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 237514
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 136120
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune",
    },
  },
  [2] = { -- Frost
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 135305
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 237522
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 135372
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune",
    },
  },
  [3] = { -- Unholy
    [1] = {
      title = L["Buffs"],
      args = {
      },
      icon = 136181
    },
    [2] = {
      title = L["Debuffs"],
      args = {
      },
      icon = 1129420
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      },
      icon = 136144
    },
    [4] = {
      title = L["Azerite Traits"],
      args = {
      },
      icon = 135349
    },
    [5] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [6] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune",
    },
  },
}

-- General Section
tinsert(templates.general.args, {
  title = L["Health"],
  icon = "Interface\\Icons\\inv_alchemy_70_red",
  triggers = { [0] = { trigger = { type = "status", event = "Health", unit = "player", use_unit = true, unevent = "auto" }}}
});
tinsert(templates.general.args, {
  title = L["Cast"],
  icon = 136209,
  triggers = {[0] = { trigger = { type = "status", event = "Cast", unevent = "auto", use_unit = true, unit = "player" }}}
});
tinsert(templates.general.args, {
  title = L["Always Active"],
  icon = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura78",
  triggers = {[0] = { trigger = { type = "status", event = "Conditions", unevent = "auto", use_alwaystrue = true}}}
});

tinsert(templates.general.args, {
  title = L["Pet alive"],
  icon = "Interface\\Icons\\ability_hunter_pet_raptor",
  triggers = {[0] = { trigger = { type = "status", event = "Conditions", unevent = "auto", use_HasPet = true}}}
});

tinsert(templates.general.args, {
  title = L["Pet Behavior"],
  icon = "Interface\\Icons\\Ability_hunter_pet_assist",
  triggers = {[0] = { trigger = { type = "status", event = "Pet Behavior", unevent = "auto", use_behavior = true, behavior = "assist"}}}
});

tinsert(templates.general.args, { spell = 2825, type = "buff", unit = "player",
  overideTitle = L["Bloodlust/Heroism"],
  spellIds = {2825, 32182, 80353, 90355, 160452} } -- TODO 8.0
);

-- Items section
templates.items[1] = {
  title = L["Enchants"], -- TODO
  args = {
  }
}

templates.items[2] = {
  title = L["Tank Trinkets"],
  args = {
  }
}

templates.items[3] = {
  title = L["Damage Trinkets"],
  args = {
  }
}

templates.items[4] = {
  title = L["Healer Trinkets"],
  args = {
  }
}


templates.items[5] = {
  title = L["PVP Trinkets"],
  args = {
  }
}

-- Meta template for Power triggers
local function createSimplePowerTemplate(powertype)
  local power = {
    title = powerTypes[powertype].name,
    icon = powerTypes[powertype].icon,
    triggers = {
      [0] = {
        ["trigger"] = {
          type = "status",
          event = "Power",
          unevent = "auto",
          use_unit = true,
          unit = "player",
          use_powertype = true,
          powertype = powertype
        },
      }
    }
  }
  return power;
end

------------------------------
-- PVP Talents
-------------------------------

for _, class in pairs(templates.class) do
  for _, spec in pairs(class) do
    -- TODO 8.0
    -- tinsert(spec[5].args, { spell = 195710, type = "ability"}) -- Honorable Medallion
    -- tinsert(spec[5].args, { spell = 208683, type = "ability", pvptalent = 1}) -- Gladiator's Medallion
  end
end


------------------------------
-- Hardcoded trigger templates
-------------------------------

-- Warrior
for i = 1, 3 do
  tinsert(templates.class.WARRIOR[i][6].args, createSimplePowerTemplate(1));
end

-- Paladin
tinsert(templates.class.PALADIN[3][6].args, createSimplePowerTemplate(9));
for i = 1, 3 do
  tinsert(templates.class.PALADIN[i][6].args, createSimplePowerTemplate(0));
end

-- Hunter
for i = 1, 3 do
  tinsert(templates.class.HUNTER[i][6].args, createSimplePowerTemplate(2));
end

-- Rogue
for i = 1, 3 do
  tinsert(templates.class.ROGUE[i][6].args, createSimplePowerTemplate(3));
  tinsert(templates.class.ROGUE[i][6].args, createSimplePowerTemplate(4));
end

-- Priest
for i = 1, 3 do
  tinsert(templates.class.PRIEST[i][6].args, createSimplePowerTemplate(0));
end
tinsert(templates.class.PRIEST[3][6].args, createSimplePowerTemplate(13));

-- Shaman
for i = 1, 3 do
  tinsert(templates.class.SHAMAN[i][6].args, createSimplePowerTemplate(0));

  templates.class.SHAMAN[i][7] = {
    title = L["Totems"],
    args = {
    },
    icon = 538575,
  };
end

for i = 1, 2 do
  tinsert(templates.class.SHAMAN[i][6].args, createSimplePowerTemplate(11));
end

-- Mage
tinsert(templates.class.MAGE[1][6].args, createSimplePowerTemplate(16));
for i = 1, 3 do
  tinsert(templates.class.MAGE[i][6].args, createSimplePowerTemplate(0));
end

-- Warlock
for i = 1, 3 do
  tinsert(templates.class.WARLOCK[i][6].args, createSimplePowerTemplate(0));
  tinsert(templates.class.WARLOCK[i][6].args, createSimplePowerTemplate(7));
end

-- Monk
tinsert(templates.class.MONK[1][6].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[2][6].args, createSimplePowerTemplate(0));
tinsert(templates.class.MONK[3][6].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[3][6].args, createSimplePowerTemplate(12));

templates.class.MONK[1][7] = {
  title = L["Ability Charges"],
  args = {
  },
  icon = 627486,
};

templates.class.MONK[2][7] = {
  title = L["Ability Charges"],
  args = {
  },
  icon = 1242282,
};

templates.class.MONK[3][7] = {
  title = L["Ability Charges"],
  args = {
  },
  icon = 606543,
};

-- Druid
for i = 1, 4 do
  -- Shapeshift Form
  tinsert(templates.class.DRUID[i][6].args, {
    title = L["Shapeshift Form"],
    icon = 132276,
    triggers = {[0] = { trigger = { type = "status", event = "Stance/Form/Aura", unevent = "auto"}}}
  });
end

-- Astral Power
tinsert(templates.class.DRUID[1][6].args, createSimplePowerTemplate(8));

for i = 1, 4 do
  tinsert(templates.class.DRUID[i][6].args, createSimplePowerTemplate(0)); -- Mana
  tinsert(templates.class.DRUID[i][6].args, createSimplePowerTemplate(1)); -- Rage
  tinsert(templates.class.DRUID[i][6].args, createSimplePowerTemplate(3)); -- Energy
  tinsert(templates.class.DRUID[i][6].args, createSimplePowerTemplate(4)); -- Combo Points
end

-- Demon Hunter
tinsert(templates.class.DEMONHUNTER[1][6].args, createSimplePowerTemplate(17));
tinsert(templates.class.DEMONHUNTER[2][6].args, createSimplePowerTemplate(18));

-- Death Knight
for i = 1, 3 do
  tinsert(templates.class.DEATHKNIGHT[i][6].args, createSimplePowerTemplate(6));

  tinsert(templates.class.DEATHKNIGHT[i][6].args, {
    title = L["Runes"],
    icon = "Interface\\Icons\\spell_deathknight_frozenruneweapon",
    triggers = {[0] = { trigger = { type = "status", event = "Death Knight Rune", unevent = "auto"}}}
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
tinsert(templates.race.NightElf, { spell = 58984, type = "buff", titleSuffix = L["Buff"]});
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
tinsert(templates.race.Tauren, { spell = 20549, type = "buff", titleSuffix = L["buff"]});
--Beserking
tinsert(templates.race.Troll, { spell = 26297, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Troll, { spell = 26297, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Arcane Torment
tinsert(templates.race.BloodElf, { spell = 69179, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.BloodElf, { spell = 69179, type = "buff", titleSuffix = L["buff"]});
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

------------------------------
-- Helper code for options
-------------------------------

-- Enrich items from spell, set title
local function handleItem(item)
  if (item.spell) then
    local name, icon, _;
    if (item.type == "item") then
      name, _, _, _, _, _, _, _, _, icon = GetItemInfo(item.spell);
      if (name == nil) then
        name = L["Unknown Item"] .. " " .. tostring(item.spell);
      end
    else
      name, _, icon = GetSpellInfo(item.spell);
      if (name == nil) then
        name = L["Unknown Spell"] .. " " .. tostring(item.spell);
        print ("Error: Unknown spell", item.spell);
      end
    end
    if (icon and not item.icon) then
      item.icon = icon;
    end

    item.title = item.overideTitle or name;
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
    item.load.use_talent = true;
    item.load.talent = {
      single = item.talent;
      multi = {};
    }
  end
  if (item.pvptalent) then
    item.load = item.load or {};
    item.load.use_pvptalent = true;
    item.load.pvptalent = {
      single = item.pvptalent;
      multi = {};
    }
  end
end

local function addLoadCondition(item, loadCondition)
  -- No need to deep copy here, templates are read-only
  item.load = item.load or {};
  for k, v in pairs(loadCondition) do
    item.load[k] = v;
  end
end

local function enrichDatabase()
  for className, class in pairs(templates.class) do
    for specIndex, spec in pairs(class) do
      for _, section in pairs(spec) do
        local loadCondition = {
          use_class = true, class = { single = className, multi = {} },
          use_spec = true, spec = { single = specIndex, multi = {}}
        };
        for _, item in pairs(section.args) do
          handleItem(item);
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
      handleItem(item);
      addLoadCondition(item, loadCondition);
    end
  end

  for _, item in pairs(templates.general.args) do
    handleItem(item);
  end

  for _, section in pairs(templates.items) do
    for _, item in pairs(section.args) do
      handleItem(item);
    end
  end
end

enrichDatabase();

local delayedEnrichDatabase = false;
local itemInfoReceived = CreateFrame("frame")
itemInfoReceived:RegisterEvent("GET_ITEM_INFO_RECEIVED");
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
