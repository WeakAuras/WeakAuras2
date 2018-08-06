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
    [0] = { name = POWER_TYPE_MANA, icon = "Interface\\Icons\\inv_elemental_mote_mana" },
    [1] = { name = POWER_TYPE_RED_POWER, icon = "Interface\\Icons\\spell_misc_emotionangry"},
    [2] = { name = POWER_TYPE_FOCUS, icon = "Interface\\Icons\\ability_hunter_focusfire"},
    [3] = { name = POWER_TYPE_ENERGY, icon = "Interface\\Icons\\spell_shadow_shadowworddominate"},
    [4] = { name = COMBO_POINTS, icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01"},
    [6] = { name = RUNIC_POWER, icon = "Interface\\Icons\\inv_sword_62"},
    [7] = { name = SOUL_SHARDS_POWER, icon = "Interface\\Icons\\inv_misc_gem_amethyst_02"},
    [8] = { name = POWER_TYPE_LUNAR_POWER, icon = "Interface\\Icons\\ability_druid_eclipseorange"},
    [9] = { name = HOLY_POWER, icon = "Interface\\Icons\\achievement_bg_winsoa"},
    [11] = {name = POWER_TYPE_MAELSTROM, icon = 135990},
    [12] = {name = CHI, icon = "Interface\\Icons\\ability_monk_healthsphere"},
    [13] = {name = POWER_TYPE_INSANITY, icon = "Interface\\Icons\\spell_priest_shadoworbs"},
    [16] = {name = POWER_TYPE_ARCANE_CHARGES, icon = "Interface\\Icons\\spell_arcane_arcane01"},
    [17] = {name = POWER_TYPE_FURY_DEMONHUNTER, icon = 1344651},
    [18] = {name = POWER_TYPE_PAIN, icon = 1247265},
    [99] = {name = L["Stagger"], icon = "Interface\\Icons\\monk_stance_drunkenox"}
  }

templates.typesDescription = {
  item = {
    title = L["Item on Cooldown"],
    description = L["Show only on Cooldown"],
  },
  itemShowAlways = {
    title = L["Item"],
    description = L["Show if on Cooldown or Usable"],
  },
  ability = {
    title = L["Spell on Cooldown"],
    description = L["Show only on Cooldown"],
  },
  abilityShowAlways = {
    title = L["Spell"],
    description = L["Show if on Cooldown or Usable"],
  },
  abilityUsable = {
    title = L["Spell"],
    description = L["Show if on Cooldown or Usable"],
  },
  abilityTarget = {
    title = L["Spell"],
    description = L["Show the Cooldown, Range and Resource status"],
  },
  abilityCharge = {
    title = L["Spell"],
    description = L["Show if on Cooldown or Usable"],
  },
  abilityChargeTarget  = {
    title = L["Spell"],
    description = L["Show the Cooldown, Range and Resource status"],
  },
  abilityBuff = {
    title = L["Spell + Buff"],
    description = L["Show if on Cooldown or Usable, and show Buff duration on activation"],
  },
  abilityChargeBuff = {
    title = L["Spell + Buff"],
    description = L["Show if on Cooldown or Usable, and show Buff duration on activation"],
  },
  abilityDebuff = {
    title = L["Spell + Debuff"],
    description = L["Show if on Cooldown or Usable, and show Debuff duration on activation"],
  },
  abilityChargeDebuff = {
    title = L["Spell + Debuff"],
    description = L["Show if on Cooldown or Usable, and show Debuff duration on activation"],
  },
  debuff = {
    title = L["Debuff Active"],
    description = L["Show if unit have Debuff"],
  },
  debuffShowAlways = {
    title = L["Debuff"],
    description = L["Show if unit have or is missing Debuff"],
  },
  buff = {
    title = L["Buff Active"],
    description = L["Show if unit have Buff "],
  },
  buffShowAlways = {
    title = L["Buff"],
    description = L["Show if unit have or is missing Buff"],
  },
}

local generalAzeriteTraits = {
  { spell = 279928, types = {"buff","buffShowAlways"}, unit = "player"}, --Earthlink
  { spell = 271543, types = {"buff","buffShowAlways"}, unit = "player"}, --Ablative Shielding
  { spell = 268435, types = {"buff","buffShowAlways"}, unit = "player"}, --Azerite Fortification
  { spell = 264108, types = {"buff","buffShowAlways"}, unit = "player"}, --Blood Siphon
  { spell = 270657, types = {"buff","buffShowAlways"}, unit = "player"}, --Bulwark of the Masses
  { spell = 270586, types = {"buff","buffShowAlways"}, unit = "player"}, --Champion of Azeroth
  { spell = 271538, types = {"buff","buffShowAlways"}, unit = "player"}, --Crystalline Carapace
  { spell = 272572, types = {"buff","buffShowAlways"}, unit = "player"}, --Ephemeral Recovery
  { spell = 270576, types = {"buff","buffShowAlways"}, unit = "player"}, --Gemhide
  { spell = 268437, types = {"buff","buffShowAlways"}, unit = "player"}, --Impassive Visage
  { spell = 270621, types = {"buff","buffShowAlways"}, unit = "player"}, --Lifespeed
  { spell = 267879, types = {"buff","buffShowAlways"}, unit = "player"}, --On My Way
  { spell = 270568, types = {"buff","buffShowAlways"}, unit = "player"}, --Resounding Protection
  { spell = 270661, types = {"buff","buffShowAlways"}, unit = "player"}, --Self Reliance
  { spell = 272090, types = {"buff","buffShowAlways"}, unit = "player"}, --Synergistic Growth
  { spell = 269239, types = {"buff","buffShowAlways"}, unit = "player"}, --Vampiric Speed
  { spell = 269214, types = {"buff","buffShowAlways"}, unit = "player"}, --Winds of War
  { spell = 281516, types = {"buff","buffShowAlways"}, unit = "player"}, --Unstable Catalyst
  { spell = 279902, types = {"buff","buffShowAlways"}, unit = "player"}, --Unstable Flames
  { spell = 279956, types = {"debuff","debuffShowAlways"}, unit = "multi"}, --Azerite Globules
  { spell = 270674, types = {"buff","buffShowAlways"}, unit = "player"}, --Azerite Veins
  { spell = 271843, types = {"buff","buffShowAlways"}, unit = "player"}, --Blessed Portents
  { spell = 272276, types = {"buff","buffShowAlways"}, unit = "target"}, --Bracing Chill
  { spell = 272260, types = {"buff","buffShowAlways"}, unit = "target"}, --Concentrated Mending
  { spell = 268955, types = {"buff","buffShowAlways"}, unit = "player"}, --Elemental Whirl
  { spell = 263987, types = {"buff","buffShowAlways"}, unit = "player"}, --Heed My Call
  { spell = 271711, types = {"buff","buffShowAlways"}, unit = "player"}, --Overwhelming Power
  { spell = 271550, types = {"buff","buffShowAlways"}, unit = "player"}, --Strength in Numbers
  { spell = 271559, types = {"buff","buffShowAlways"}, unit = "player"}, --Shimmering Haven
  { spell = 269085, types = {"buff","buffShowAlways"}, unit = "player"}, --Woundbinder
  { spell = 273685, types = {"buff","buffShowAlways"}, unit = "player"}, --Meticulous Scheming
  { spell = 273714, types = {"buff","buffShowAlways"}, unit = "player"}, --Seize the Moment!
  { spell = 273870, types = {"buff","buffShowAlways"}, unit = "player"}, --Sandstorm
  { spell = 280204, types = {"buff","buffShowAlways"}, unit = "player"}, --Wandering Soul
  { spell = 280409, types = {"buff","buffShowAlways"}, unit = "player"}, --Blood Rite
  { spell = 273836, types = {"buff","buffShowAlways"}, unit = "player"}, --Filthy Transfusion
  { spell = 280413, types = {"buff","buffShowAlways"}, unit = "player"}, --Incite the Pack
  { spell = 273794, types = {"debuff","debuffShowAlways"}, unit = "multi"}, --Rezan's Fury
  { spell = 280433, types = {"buff","buffShowAlways"}, unit = "player"}, --Swirling Sands
  { spell = 280385, types = {"debuff","debuffShowAlways"}, unit = "multi"}, --Thunderous Blast
  { spell = 280404, types = {"buff","buffShowAlways"}, unit = "target"}, --Tidal Surge
  { spell = 273842, types = {"buff","buffShowAlways"}, unit = "player"}, --Secrets of the Deep
  { spell = 280286, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Dagger in the Back
  { spell = 281843, types = {"buff","buffShowAlways"}, unit = "player"}, --Tradewinds
}

local pvpAzeriteTraits = {
  { spell = 280876, types = {"buff","buffShowAlways"}, unit = "player"}, --Anduin's Dedication
  { spell = 280809, types = {"buff","buffShowAlways"}, unit = "player"}, --Sylvanas' Resolve
  { spell = 280855, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Battlefield Precision
  { spell = 280817, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Battlefield Focus
  { spell = 280858, types = {"buff","buffShowAlways"}, unit = "player"}, --Stand As One
  { spell = 280830, types = {"buff","buffShowAlways"}, unit = "player"}, --Liberator's Might
  { spell = 280780, types = {"buff","buffShowAlways"}, unit = "player"}, --Glory in Battle
  { spell = 280861, types = {"buff","buffShowAlways"}, unit = "player"}, --Last Gift
  { spell = 280787, types = {"buff","buffShowAlways"}, unit = "player"}, --Retaliatory Fury
}

-- Collected by WeakAurasTemplateCollector:

templates.class.WARRIOR = {
  [1] = { -- Arms
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 248622, types = {"buff","buffShowAlways"}, unit = "player", talent = 16}, -- In For The Kill
        { spell = 197690, types = {"buff","buffShowAlways"}, unit = "player", talent = 12}, -- Defensive Stance
        { spell = 118038, types = {"buff","buffShowAlways"}, unit = "player"}, -- Die by the Sword
        { spell = 6673, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 107574, types = {"buff","buffShowAlways"}, unit = "player", talent = 17}, -- Avatar
        { spell = 262228, types = {"buff","buffShowAlways"}, unit = "player", talent = 18}, -- Deadly Calm
        { spell = 32216, types = {"buff","buffShowAlways"}, unit = "player", talent = 5}, -- Victorious
        { spell = 227847, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bladestorm
        { spell = 52437, types = {"buff","buffShowAlways"}, unit = "player", talent = 2}, -- Sudden Death
        { spell = 18499, types = {"buff","buffShowAlways"}, unit = "player"}, -- Berserker Rage
        { spell = 202164, types = {"buff","buffShowAlways"}, unit = "player", talent = 11}, -- Bounding Stride
        { spell = 7384, types = {"buff","buffShowAlways"}, unit = "player"}, -- Overpower
        { spell = 262232, types = {"buff","buffShowAlways"}, unit = "player", talent = 1}, -- War Machine
        { spell = 97463, types = {"buff","buffShowAlways"}, unit = "player"}, -- Rallying Cry
        { spell = 260708, types = {"buff","buffShowAlways"}, unit = "player"}, -- Sweeping Strikes
      },
      icon = 458972
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115804, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mortal Wounds
        { spell = 772, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 9}, -- Rend
        { spell = 208086, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Colossus Smash
        { spell = 105771, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Charge
        { spell = 5246, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Intimidating Shout
        { spell = 1715, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Hamstring
        { spell = 355, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Taunt
        { spell = 262115, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Deep Wounds
        { spell = 132169, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 6}, -- Storm Bolt
      },
      icon = 464973
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, types = {"ability","abilityShowAlways"}}, -- Charge
        { spell = 355, types = {"ability","abilityShowAlways"}}, -- Taunt
        { spell = 845, types = {"ability","abilityShowAlways"}, talent = 15}, -- Cleave
        { spell = 5246, types = {"ability","abilityShowAlways"}}, -- Intimidating Shout
        { spell = 6544, types = {"ability","abilityShowAlways"}}, -- Heroic Leap
        { spell = 6552, types = {"ability","abilityShowAlways"}}, -- Pummel
        { spell = 6673, types = {"ability","abilityShowAlways"}}, -- Battle Shout
        { spell = 7384, types = {"ability","abilityShowAlways"}}, -- Overpower
        { spell = 12294, types = {"ability","abilityShowAlways"}}, -- Mortal Strike
        { spell = 18499, types = {"ability","abilityShowAlways"}}, -- Berserker Rage
        { spell = 57755, types = {"ability","abilityShowAlways"}}, -- Heroic Throw
        { spell = 97462, types = {"ability","abilityShowAlways"}}, -- Rallying Cry
        { spell = 107570, types = {"ability","abilityShowAlways"}, talent = 6}, -- Storm Bolt
        { spell = 107574, types = {"ability","abilityShowAlways"}, talent = 17}, -- Avatar
        { spell = 118038, types = {"ability","abilityShowAlways"}}, -- Die by the Sword
        { spell = 152277, types = {"ability","abilityShowAlways"}, talent = 21}, -- Ravager
        { spell = 167105, types = {"ability","abilityShowAlways"}}, -- Colossus Smash
        { spell = 202168, types = {"ability","abilityShowAlways"}}, -- Impending Victory
        { spell = 212520, types = {"ability","abilityShowAlways"}, talent = 12}, -- Defensive Stance
        { spell = 227847, types = {"ability","abilityShowAlways"}}, -- Bladestorm
        { spell = 260643, types = {"ability","abilityShowAlways"}, talent = 3}, -- Skullsplitter
        { spell = 260708, types = {"ability","abilityShowAlways"}}, -- Sweeping Strikes
        { spell = 262161, types = {"ability","abilityShowAlways"}, talent = 14}, -- Warbreaker
        { spell = 262228, types = {"ability","abilityShowAlways"}, talent = 18}, -- Deadly Calm
      },
      icon = 132355
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280212, types = {"buff","buffShowAlways"}, unit = "player"}, --Bury the Hatchet
        { spell = 280210, types = {"buff","buffShowAlways"}, unit = "group"}, --Moment of Glory
        { spell = 278826, types = {"buff","buffShowAlways"}, unit = "player"}, --Crushing Assault
        { spell = 272870, types = {"buff","buffShowAlways"}, unit = "player"}, --Executioner's Precision
        { spell = 273415, types = {"buff","buffShowAlways"}, unit = "player"}, --Gathering Storm
        { spell = 275540, types = {"buff","buffShowAlways"}, unit = "player"}, --Test of Might
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 262232, types = {"buff","buffShowAlways"}, unit = "player", talent = 1}, -- War Machine
        { spell = 32216, types = {"buff","buffShowAlways"}, unit = "player", talent = 5}, -- Victorious
        { spell = 215572, types = {"buff","buffShowAlways"}, unit = "player", talent = 15}, -- Frothing Berserker
        { spell = 202539, types = {"buff","buffShowAlways"}, unit = "player", talent = 9}, -- Furious Slash
        { spell = 18499, types = {"buff","buffShowAlways"}, unit = "player"}, -- Berserker Rage
        { spell = 1719, types = {"buff","buffShowAlways"}, unit = "player"}, -- Recklessness
        { spell = 46924, types = {"buff","buffShowAlways"}, unit = "player", talent = 18}, -- Bladestorm
        { spell = 202164, types = {"buff","buffShowAlways"}, unit = "player", talent = 11}, -- Bounding Stride
        { spell = 85739, types = {"buff","buffShowAlways"}, unit = "player"}, -- Whirlwind
        { spell = 280776, types = {"buff","buffShowAlways"}, unit = "player", talent = 8}, -- Sudden Death
        { spell = 202225, types = {"buff","buffShowAlways"}, unit = "player", talent = 10}, -- Furious Charge
        { spell = 184362, types = {"buff","buffShowAlways"}, unit = "player"}, -- Enrage
        { spell = 184364, types = {"buff","buffShowAlways"}, unit = "player"}, -- Enraged Regeneration
        { spell = 6673, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 97463, types = {"buff","buffShowAlways"}, unit = "player"}, -- Rallying Cry
      },
      icon = 136224
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 132169, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 6}, -- Storm Bolt
        { spell = 118000, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 17}, -- Dragon Roar
        { spell = 280773, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 21}, -- Siegebreaker
        { spell = 105771, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Charge
        { spell = 355, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Taunt
      },
      icon = 132154
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, types = {"ability","abilityShowAlways"}}, -- Charge
        { spell = 355, types = {"ability","abilityShowAlways"}}, -- Taunt
        { spell = 1719, types = {"ability","abilityShowAlways"}}, -- Recklessness
        { spell = 5246, types = {"ability","abilityShowAlways"}}, -- Intimidating Shout
        { spell = 5308, types = {"ability","abilityShowAlways"}}, -- Execute
        { spell = 6544, types = {"ability","abilityShowAlways"}}, -- Heroic Leap
        { spell = 6552, types = {"ability","abilityShowAlways"}}, -- Pummel
        { spell = 6673, types = {"ability","abilityShowAlways"}}, -- Battle Shout
        { spell = 18499, types = {"ability","abilityShowAlways"}}, -- Berserker Rage
        { spell = 23881, types = {"ability","abilityShowAlways"}}, -- Bloodthirst
        { spell = 46924, types = {"ability","abilityShowAlways"}, talent = 18}, -- Bladestorm
        { spell = 57755, types = {"ability","abilityShowAlways"}}, -- Heroic Throw
        { spell = 85288, types = {"ability","abilityShowAlways"}}, -- Raging Blow
        { spell = 97462, types = {"ability","abilityShowAlways"}}, -- Rallying Cry
        { spell = 107570, types = {"ability","abilityShowAlways"}, talent = 6}, -- Storm Bolt
        { spell = 118000, types = {"ability","abilityShowAlways"}, talent = 17}, -- Dragon Roar
        { spell = 184364, types = {"ability","abilityShowAlways"}}, -- Enraged Regeneration
        { spell = 202168, types = {"ability","abilityShowAlways"}, talent = 5}, -- Impending Victory
        { spell = 280772, types = {"ability","abilityShowAlways"}, talent = 21}, -- Siegebreaker

      },
      icon = 136012
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280212, types = {"buff","buffShowAlways"}, unit = "player"}, --Bury the Hatchet
        { spell = 280210, types = {"buff","buffShowAlways"}, unit = "group"}, --Moment of Glory
        { spell = 273428, types = {"buff","buffShowAlways"}, unit = "player"}, --Bloodcraze
        { spell = 278134, types = {"buff","buffShowAlways"}, unit = "player"}, --Infinite Fury
        { spell = 275672, types = {"buff","buffShowAlways"}, unit = "player"}, --Pulverizing Blows
        { spell = 272838, types = {"buff","buffShowAlways"}, unit = "player"}, --Trample the Weak
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 12975, types = {"buff","buffShowAlways"}, unit = "player"}, -- Last Stand
        { spell = 202164, types = {"buff","buffShowAlways"}, unit = "player", talent = 5}, -- Bounding Stride
        { spell = 18499, types = {"buff","buffShowAlways"}, unit = "player"}, -- Berserker Rage
        { spell = 202573, types = {"buff","buffShowAlways"}, unit = "player", talent = 17}, -- Vengeance: Revenge
        { spell = 871, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shield Wall
        { spell = 227744, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Ravager
        { spell = 202574, types = {"buff","buffShowAlways"}, unit = "player", talent = 17}, -- Vengeance: Ignore Pain
        { spell = 6673, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 132404, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shield Block
        { spell = 202602, types = {"buff","buffShowAlways"}, unit = "player", talent = 1}, -- Into the Fray
        { spell = 97463, types = {"buff","buffShowAlways"}, unit = "player"}, -- Rallying Cry
        { spell = 190456, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ignore Pain
        { spell = 23920, types = {"buff","buffShowAlways"}, unit = "player"}, -- Spell Reflection
        { spell = 107574, types = {"buff","buffShowAlways"}, unit = "player"}, -- Avatar
        { spell = 147833, types = {"buff","buffShowAlways"}, unit = "target"}, -- Intervene
        { spell = 223658, types = {"buff","buffShowAlways"}, unit = "target", talent = 6}, -- Safeguard

      },
      icon = 1377132
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115767, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Deep Wounds
        { spell = 1160, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Demoralizing Shout
        { spell = 355, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Taunt
        { spell = 132169, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15}, -- Storm Bolt
        { spell = 105771, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Charge
        { spell = 5246, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Intimidating Shout
        { spell = 6343, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Thunder Clap
        { spell = 132168, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Shockwave
        { spell = 275335, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 2}, -- Punish
      },
      icon = 132090
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 355, types = {"ability","abilityShowAlways"}}, -- Taunt
        { spell = 871, types = {"ability","abilityShowAlways"}}, -- Shield Wall
        { spell = 1160, types = {"ability","abilityShowAlways"}}, -- Demoralizing Shout
        { spell = 2565, types = {"ability","abilityShowAlways"}}, -- Shield Block
        { spell = 5246, types = {"ability","abilityShowAlways"}}, -- Intimidating Shout
        { spell = 6343, types = {"ability","abilityShowAlways"}}, -- Thunder Clap
        { spell = 6544, types = {"ability","abilityShowAlways"}}, -- Heroic Leap
        { spell = 6552, types = {"ability","abilityShowAlways"}}, -- Pummel
        { spell = 6572, types = {"ability","abilityShowAlways"}}, -- Revenge
        { spell = 6673, types = {"ability","abilityShowAlways"}}, -- Battle Shout
        { spell = 12975, types = {"ability","abilityShowAlways"}}, -- Last Stand
        { spell = 18499, types = {"ability","abilityShowAlways"}}, -- Berserker Rage
        { spell = 23920, types = {"ability","abilityShowAlways"}}, -- Spell Reflection
        { spell = 23922, types = {"ability","abilityShowAlways"}}, -- Shield Slam
        { spell = 46968, types = {"ability","abilityShowAlways"}}, -- Shockwave
        { spell = 57755, types = {"ability","abilityShowAlways"}}, -- Heroic Throw
        { spell = 97462, types = {"ability","abilityShowAlways"}}, -- Rallying Cry
        { spell = 107570, types = {"ability","abilityShowAlways"}, talent = 15}, -- Storm Bolt
        { spell = 107574, types = {"ability","abilityShowAlways"}}, -- Avatar
        { spell = 118000, types = {"ability","abilityShowAlways"}, talent = 9}, -- Dragon Roar
        { spell = 198304, types = {"ability","abilityShowAlways"}}, -- Intercept
        { spell = 202168, types = {"ability","abilityShowAlways"}, talent = 3}, -- Impending Victory
        { spell = 228920, types = {"ability","abilityShowAlways"}, talent = 21}, -- Ravager

      },
      icon = 134951
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280212, types = {"buff","buffShowAlways"}, unit = "player"}, --Bury the Hatchet
        { spell = 280210, types = {"buff","buffShowAlways"}, unit = "group"}, --Moment of Glory
        { spell = 279194, types = {"buff","buffShowAlways"}, unit = "player"}, --Bloodsport
        { spell = 278124, types = {"buff","buffShowAlways"}, unit = "player"}, --Brace for Impact
        { spell = 278999, types = {"buff","buffShowAlways"}, unit = "player"}, --Callous Reprisal
        { spell = 275867, types = {"buff","buffShowAlways"}, unit = "player"}, --Reinforced Plating
        { spell = 273445, types = {"buff","buffShowAlways"}, unit = "player"}, --Sword and Board
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 1022, types = {"buff","buffShowAlways"}, unit = "group"}, -- Blessing of Protection
        { spell = 53563, types = {"buff","buffShowAlways"}, unit = "group"}, -- Beacon of Light
        { spell = 6940, types = {"buff","buffShowAlways"}, unit = "group"}, -- Blessing of Sacrifice
        { spell = 31821, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aura Mastery
        { spell = 183415, types = {"buff","buffShowAlways"}, unit = "player", talent = 12}, -- Aura of Mercy
        { spell = 31884, types = {"buff","buffShowAlways"}, unit = "player"}, -- Avenging Wrath
        { spell = 498, types = {"buff","buffShowAlways"}, unit = "player"}, -- Divine Protection
        { spell = 210320, types = {"buff","buffShowAlways"}, unit = "player", talent = 10}, -- Devotion Aura
        { spell = 642, types = {"buff","buffShowAlways"}, unit = "player"}, -- Divine Shield
        { spell = 200025, types = {"buff","buffShowAlways"}, unit = "group", talent = 21}, -- Beacon of Virtue
        { spell = 156910, types = {"buff","buffShowAlways"}, unit = "group", talent = 20}, -- Beacon of Faith
        { spell = 54149, types = {"buff","buffShowAlways"}, unit = "player"}, -- Infusion of Light
        { spell = 105809, types = {"buff","buffShowAlways"}, unit = "player"}, -- Holy Avenger
        { spell = 216331, types = {"buff","buffShowAlways"}, unit = "player", talent = 17}, -- Avenging Crusader
        { spell = 214202, types = {"buff","buffShowAlways"}, unit = "player"}, -- Rule of Law
        { spell = 183416, types = {"buff","buffShowAlways"}, unit = "player", talent = 11}, -- Aura of Sacrifice
        { spell = 1044, types = {"buff","buffShowAlways"}, unit = "group"}, -- Blessing of Freedom
        { spell = 221883, types = {"buff","buffShowAlways"}, unit = "player"}, -- Divine Steed
        { spell = 223306, types = {"buff","buffShowAlways"}, unit = "target", talent = 2}, -- Bestow Faith
      },
      icon = 236254
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 204242, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Consecration
        { spell = 105421, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 9}, -- Blinding Light
        { spell = 853, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Hammer of Justice
        { spell = 214222, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Judgment
        { spell = 196941, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 13}, -- Judgment of Light
        { spell = 20066, types = {"debuff","debuffShowAlways"}, unit = "multi", talent = 8}, -- Repentance
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 498, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Divine Protection
        { spell = 633, types = {"ability","abilityShowAlways"}}, -- Lay on Hands
        { spell = 642, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Divine Shield
        { spell = 853, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Hammer of Justice
        { spell = 1022, types = {"ability","abilityShowAlways"}}, -- Blessing of Protection
        { spell = 1044, types = {"ability","abilityShowAlways"}}, -- Blessing of Freedom
        { spell = 6940, types = {"ability","abilityShowAlways"}}, -- Blessing of Sacrifice
        { spell = 20066, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 8}, -- Repentance
        { spell = 20473, types = {"ability","abilityShowAlways"}}, -- Holy Shock
        { spell = 26573, types = {"ability","abilityShowAlways"}}, -- Consecration
        { spell = 31821, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Aura Mastery
        { spell = 31884, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Avenging Wrath
        { spell = 35395, types = {"ability","abilityCharge","abilityChargeTarget"}}, -- Crusader Strike
        { spell = 85222, types = {"ability","abilityShowAlways"}}, -- Light of Dawn
        { spell = 105809, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 15}, -- Holy Avenger
        { spell = 114158, types = {"ability","abilityShowAlways"}, talent = 3}, -- Light's Hammer
        { spell = 114165, types = {"ability","abilityShowAlways"}, talent = 14}, -- Holy Prism
        { spell = 115750, types = {"ability","abilityShowAlways"}, talent = 9}, -- Blinding Light
        { spell = 190784, types = {"ability","abilityShowAlways"}}, -- Divine Steed
        { spell = 200025, types = {"ability","abilityShowAlways"}, talent = 21}, -- Beacon of Virtue
        { spell = 214202, types = {"ability","abilityShowAlways","abilityChargeBuff"}}, -- Rule of Law
        { spell = 216331, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Avenging Crusader
        { spell = 223306, types = {"ability","abilityShowAlways"}, talent = 2}, -- Bestow Faith
        { spell = 275773, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Judgment
      },
      icon = 135972
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275468, types = {"buff","buffShowAlways"}, unit = "player"}, --Divine Revelations
        { spell = 280191, types = {"buff","buffShowAlways"}, unit = "player"}, --Gallant Steed
        { spell = 278785, types = {"buff","buffShowAlways"}, unit = "player"}, --Grace of the Justicar
        { spell = 273034, types = {"buff","buffShowAlways"}, unit = "player"}, --Martyr's Breath
        { spell = 278145, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Radiant Incandescence
        { spell = 274395, types = {"buff","buffShowAlways"}, unit = "group"}, --Stalwart Protector
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 203797, types = {"buff","buffShowAlways"}, unit = "player", talent = 10}, -- Retribution Aura
        { spell = 132403, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shield of the Righteous
        { spell = 197561, types = {"buff","buffShowAlways"}, unit = "player"}, -- Avenger's Valor
        { spell = 1044, types = {"buff","buffShowAlways"}, unit = "group"}, -- Blessing of Freedom
        { spell = 6940, types = {"buff","buffShowAlways"}, unit = "group"}, -- Blessing of Sacrifice
        { spell = 188370, types = {"buff","buffShowAlways"}, unit = "player"}, -- Consecration
        { spell = 204150, types = {"buff","buffShowAlways"}, unit = "player", talent = 18}, -- Aegis of Light
        { spell = 31850, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ardent Defender
        { spell = 31884, types = {"buff","buffShowAlways"}, unit = "player"}, -- Avenging Wrath
        { spell = 204018, types = {"buff","buffShowAlways"}, unit = "player", talent = 12}, -- Blessing of Spellwarding
        { spell = 152262, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Seraphim
        { spell = 86659, types = {"buff","buffShowAlways"}, unit = "player"}, -- Guardian of Ancient Kings
        { spell = 1022, types = {"buff","buffShowAlways"}, unit = "group"}, -- Blessing of Protection
        { spell = 221883, types = {"buff","buffShowAlways"}, unit = "player"}, -- Divine Steed
        { spell = 204335, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aegis of Light
        { spell = 642, types = {"buff","buffShowAlways"}, unit = "player"}, -- Divine Shield
      },
      icon = 236265
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 62124, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Hand of Reckoning
        { spell = 204242, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Consecration
        { spell = 196941, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 16}, -- Judgment of Light
        { spell = 105421, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 9}, -- Blinding Light
        { spell = 853, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Hammer of Justice
        { spell = 204301, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Blessed Hammer
        { spell = 204079, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 13}, -- Final Stand
        { spell = 31935, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Avenger's Shield
        { spell = 20066, types = {"debuff","debuffShowAlways"}, unit = "multi", talent = 8}, -- Repentance
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 633, types = {"ability","abilityShowAlways"}}, -- Lay on Hands
        { spell = 642, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Divine Shield
        { spell = 853, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Hammer of Justice
        { spell = 1022, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Blessing of Protection
        { spell = 1044, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Blessing of Freedom
        { spell = 6940, types = {"ability","abilityShowAlways","abilityDebuff"}, unit="player"}, -- Blessing of Sacrifice
        { spell = 20066, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 8}, -- Repentance
        { spell = 26573, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Consecration
        { spell = 31850, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Ardent Defender
        { spell = 31884, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Avenging Wrath
        { spell = 31935, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Avenger's Shield
        { spell = 53595, types = {"ability","abilityShowAlways"}}, -- Hammer of the Righteous                  Couldn't find this spell
        { spell = 53600, types = {"ability","abilityCharge","abilityChargeBuff"}}, -- Shield of the Righteous
        { spell = 62124, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Hand of Reckoning
        { spell = 86659, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Guardian of Ancient Kings
        { spell = 96231, types = {"ability","abilityShowAlways"}}, -- Rebuke
        { spell = 115750, types = {"ability","abilityShowAlways"}, talent = 9}, -- Blinding Light
        { spell = 152262, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 21}, -- Seraphim
        { spell = 184092, types = {"ability","abilityShowAlways"}}, -- Light of the Protector
        { spell = 190784, types = {"ability","abilityShowAlways"}}, -- Divine Steed
        { spell = 204018, types = {"ability","abilityShowAlways"}, talent = 12}, -- Blessing of Spellwarding
        { spell = 204019, types = {"ability","abilityCharge","abilityChargeDebuff"}}, -- Blessed Hammer
        { spell = 204035, types = {"ability","abilityShowAlways"}}, -- Bastion of Light
        { spell = 204150, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Aegis of Light
        { spell = 213652, types = {"ability","abilityShowAlways"}}, -- Hand of the Protector
        { spell = 275779, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Judgment
      },
      icon = 135874
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272979, types = {"buff","buffShowAlways"}, unit = "player"}, --Bulwark of Light
        { spell = 280191, types = {"buff","buffShowAlways"}, unit = "player"}, --Gallant Steed
        { spell = 278785, types = {"buff","buffShowAlways"}, unit = "group"}, --Grace of the Justicar
        { spell = 275481, types = {"buff","buffShowAlways"}, unit = "player"}, --Inner Light
        { spell = 279397, types = {"buff","buffShowAlways"}, unit = "player"}, --Inspiring Vanguard
        { spell = 278574, types = {"buff","buffShowAlways"}, unit = "player"}, --Judicious Defense
        { spell = 278954, types = {"buff","buffShowAlways"}, unit = "player"}, --Soaring Shield
        { spell = 274395, types = {"buff","buffShowAlways"}, unit = "group"}, --Stalwart Protector
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 267611, types = {"buff","buffShowAlways"}, unit = "player", talent = 2}, -- Righteous Verdict
        { spell = 205191, types = {"buff","buffShowAlways"}, unit = "player", talent = 15}, -- Eye for an Eye
        { spell = 1022, types = {"buff","buffShowAlways"}, unit = "group"}, -- Blessing of Protection
        { spell = 184662, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shield of Vengeance
        { spell = 271581, types = {"buff","buffShowAlways"}, unit = "player", talent = 10}, -- Divine Judgment
        { spell = 84963, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Inquisition
        { spell = 203538, types = {"buff","buffShowAlways"}, unit = "group"}, -- Greater Blessing of Kings
        { spell = 221883, types = {"buff","buffShowAlways"}, unit = "player"}, -- Divine Steed
        { spell = 642, types = {"buff","buffShowAlways"}, unit = "player"}, -- Divine Shield
        { spell = 203539, types = {"buff","buffShowAlways"}, unit = "group"}, -- Greater Blessing of Wisdom
        { spell = 114250, types = {"buff","buffShowAlways"}, unit = "player", talent = 16}, -- Selfless Healer
        { spell = 31884, types = {"buff","buffShowAlways"}, unit = "player"}, -- Avenging Wrath
        { spell = 269571, types = {"buff","buffShowAlways"}, unit = "player", talent = 1}, -- Zeal
        { spell = 281178, types = {"buff","buffShowAlways"}, unit = "player", talent = 5}, -- Blade of Wrath
        { spell = 1044, types = {"buff","buffShowAlways"}, unit = "group"}, -- Blessing of Freedom
        { spell = 209785, types = {"buff","buffShowAlways"}, unit = "player", talent = 4}, -- Fires of Justice
      },
      icon = 135993
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 62124, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Hand of Reckoning
        { spell = 197277, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Judgment
        { spell = 267799, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 3}, -- Execution Sentence
        { spell = 105421, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Blinding Light
        { spell = 853, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Hammer of Justice
        { spell = 183218, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Hand of Hindrance
        { spell = 20066, types = {"debuff","debuffShowAlways"}, unit = "multi", talent = 8}, -- Repentance
        { spell = 255937, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12}, -- Wake of Ashes

      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 633, types = {"ability","abilityShowAlways"}}, -- Lay on Hands
        { spell = 642, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Divine Shield
        { spell = 853, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Hammer of Justice
        { spell = 1022, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Blessing of Protection
        { spell = 1044, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Blessing of Freedom
        { spell = 20066, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 8}, -- Repentance
        { spell = 20271, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Judgment
        { spell = 24275, types = {"ability","abilityShowAlways"}, talent = 6}, -- Hammer of Wrath
        { spell = 31884, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Avenging Wrath
        { spell = 35395, types = {"ability","abilityCharge"}}, -- Crusader Strike
        { spell = 62124, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Hand of Reckoning
        { spell = 96231, types = {"ability","abilityShowAlways"}}, -- Rebuke
        { spell = 115750, types = {"ability","abilityShowAlways"}, talent = 9}, -- Blinding Light
        { spell = 183218, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Hand of Hindrance
        { spell = 184575, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Blade of Justice
        { spell = 184662, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Shield of Vengeance
        { spell = 190784, types = {"ability","abilityShowAlways"}}, -- Divine Steed
        { spell = 205191, types = {"ability","abilityShowAlways"}, talent = 15}, -- Eye for an Eye
        { spell = 205228, types = {"ability","abilityShowAlways"}, talent = 11}, -- Consecration
        { spell = 210191, types = {"ability","abilityCharge"}, talent = 18}, -- Word of Glory
        { spell = 255937, types = {"ability","abilityShowAlways","abilityDebuff"}, talent = 11}, -- Wake of Ashes
        { spell = 267798, types = {"ability","abilityShowAlways","abilityDebuff"}, talent = 3}, -- Execution Sentence
      },
      icon = 135891
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272903, types = {"buff","buffShowAlways"}, unit = "player"}, --Avenger's Might
        { spell = 278523, types = {"buff","buffShowAlways"}, unit = "player"}, --Divine Right
        { spell = 273481, types = {"buff","buffShowAlways"}, unit = "player"}, --Expurgation
        { spell = 280191, types = {"buff","buffShowAlways"}, unit = "player"}, --Gallant Steed
        { spell = 278785, types = {"buff","buffShowAlways"}, unit = "group"}, --Grace of the Justicar
        { spell = 279204, types = {"buff","buffShowAlways"}, unit = "player"}, --Relentless Inquisitor
        { spell = 278989, types = {"buff","buffShowAlways"}, unit = "player"}, --Zealotry
        { spell = 274395, types = {"buff","buffShowAlways"}, unit = "group"}, --Stalwart Protector
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 246851, types = {"buff","buffShowAlways"}, unit = "player"}, -- Barbed Shot
        { spell = 35079, types = {"buff","buffShowAlways"}, unit = "player"}, -- Misdirection
        { spell = 231390, types = {"buff","buffShowAlways"}, unit = "player", talent = 7}, -- Trailblazer
        { spell = 186258, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aspect of the Cheetah
        { spell = 264667, types = {"buff","buffShowAlways"}, unit = "player"}, -- Primal Rage
        { spell = 257946, types = {"buff","buffShowAlways"}, unit = "player"}, -- Thrill of the Hunt
        { spell = 19574, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bestial Wrath
        { spell = 268877, types = {"buff","buffShowAlways"}, unit = "player"}, -- Beast Cleave
        { spell = 264663, types = {"buff","buffShowAlways"}, unit = "player"}, -- Predator's Thirst
        { spell = 118922, types = {"buff","buffShowAlways"}, unit = "player", talent = 14}, -- Posthaste
        { spell = 193530, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aspect of the Wild
        { spell = 5384, types = {"buff","buffShowAlways"}, unit = "player"}, -- Feign Death
        { spell = 199483, types = {"buff","buffShowAlways"}, unit = "player"}, -- Camouflage
        { spell = 281036, types = {"buff","buffShowAlways"}, unit = "player", talent = 3}, -- Dire Beast
        { spell = 186265, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aspect of the Turtle
        { spell = 6197, types = {"buff","buffShowAlways"}, unit = "player"}, -- Eagle Eye
        { spell = 246152, types = {"buff","buffShowAlways"}, unit = "player"}, -- Barbed Shot
        { spell = 24450, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Prowl
        { spell = 272790, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Frenzy
        { spell = 136, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Mend Pet
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 135299, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Tar Trap
        { spell = 217200, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Barbed Shot
        { spell = 117405, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15}, -- Binding Shot
        { spell = 3355, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Freezing Trap
        { spell = 2649, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Growl
        { spell = 24394, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Intimidation
        { spell = 5116, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Concussive Shot
      },
      icon = 135860
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 781, types = {"ability","abilityShowAlways"}}, -- Disengage
        { spell = 1543, types = {"ability","abilityShowAlways"}}, -- Flare
        { spell = 2649, types = {"ability","abilityShowAlways"}}, -- Growl
        { spell = 5116, types = {"ability","abilityShowAlways"}}, -- Concussive Shot
        { spell = 5384, types = {"ability","abilityShowAlways"}}, -- Feign Death
        { spell = 16827, types = {"ability","abilityShowAlways"}}, -- Claw
        { spell = 19574, types = {"ability","abilityShowAlways"}}, -- Bestial Wrath
        { spell = 19577, types = {"ability","abilityShowAlways"}}, -- Intimidation
        { spell = 24450, types = {"ability","abilityShowAlways"}}, -- Prowl
        { spell = 34026, types = {"ability","abilityShowAlways"}}, -- Kill Command
        { spell = 34477, types = {"ability","abilityShowAlways"}}, -- Misdirection
        { spell = 53209, types = {"ability","abilityShowAlways"}, talent = 6}, -- Chimaera Shot
        { spell = 109248, types = {"ability","abilityShowAlways"}, talent = 15}, -- Binding Shot
        { spell = 109304, types = {"ability","abilityShowAlways"}}, -- Exhilaration
        { spell = 120360, types = {"ability","abilityShowAlways"}, talent = 17}, -- Barrage
        { spell = 120679, types = {"ability","abilityShowAlways"}, talent = 3}, -- Dire Beast
        { spell = 131894, types = {"ability","abilityShowAlways"}, talent = 12}, -- A Murder of Crows
        { spell = 147362, types = {"ability","abilityShowAlways"}}, -- Counter Shot
        { spell = 186257, types = {"ability","abilityShowAlways"}}, -- Aspect of the Cheetah
        { spell = 186265, types = {"ability","abilityShowAlways"}}, -- Aspect of the Turtle
        { spell = 187650, types = {"ability","abilityShowAlways"}}, -- Freezing Trap
        { spell = 187698, types = {"ability","abilityShowAlways"}}, -- Tar Trap
        { spell = 193530, types = {"ability","abilityShowAlways"}}, -- Aspect of the Wild
        { spell = 199483, types = {"ability","abilityShowAlways"}, talent = 9}, -- Camouflage
        { spell = 201430, types = {"ability","abilityShowAlways"}, talent = 18}, -- Stampede
        { spell = 217200, types = {"ability","abilityShowAlways"}}, -- Barbed Shot
        { spell = 264667, types = {"ability","abilityShowAlways"}}, -- Primal Rage
      },
      icon = 132176
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277916, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Cobra's Bite
        { spell = 274443, types = {"buff","buffShowAlways"}, unit = "player"}, --Dance of Death
        { spell = 280170, types = {"buff","buffShowAlways"}, unit = "player"}, --Duck and Cover
        { spell = 269625, types = {"buff","buffShowAlways"}, unit = "player"}, --Flashing Fangs
        { spell = 273264, types = {"buff","buffShowAlways"}, unit = "player"}, --Haze of Rage
        { spell = 279810, types = {"buff","buffShowAlways"}, unit = "player"}, --Primal Instincts
        { spell = 263821, types = {"buff","buffShowAlways"}, unit = "player"}, --Ride the Lightning
        { spell = 264195, types = {"buff","buffShowAlways"}, unit = "player"}, --Rotting Jaws
        { spell = 274357, types = {"buff","buffShowAlways"}, unit = "player"}, --Shellshock
        { spell = 274598, types = {"buff","buffShowAlways"}, unit = "player"}, --PH
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 35079, types = {"buff","buffShowAlways"}, unit = "player"}, -- Misdirection
        { spell = 231390, types = {"buff","buffShowAlways"}, unit = "player", talent = 7}, -- Trailblazer
        { spell = 186258, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aspect of the Cheetah
        { spell = 264667, types = {"buff","buffShowAlways"}, unit = "player"}, -- Primal Rage
        { spell = 260395, types = {"buff","buffShowAlways"}, unit = "player", talent = 16}, -- Lethal Shots
        { spell = 194594, types = {"buff","buffShowAlways"}, unit = "player", talent = 20}, -- Lock and Load
        { spell = 257044, types = {"buff","buffShowAlways"}, unit = "player"}, -- Rapid Fire
        { spell = 164273, types = {"buff","buffShowAlways"}, unit = "player"}, -- Lone Wolf
        { spell = 6197, types = {"buff","buffShowAlways"}, unit = "player"}, -- Eagle Eye
        { spell = 257622, types = {"buff","buffShowAlways"}, unit = "player"}, -- Trick Shots
        { spell = 193526, types = {"buff","buffShowAlways"}, unit = "player"}, -- Trueshot
        { spell = 260242, types = {"buff","buffShowAlways"}, unit = "player"}, -- Precise Shots
        { spell = 5384, types = {"buff","buffShowAlways"}, unit = "player"}, -- Feign Death
        { spell = 260402, types = {"buff","buffShowAlways"}, unit = "player", talent = 18}, -- Double Tap
        { spell = 118922, types = {"buff","buffShowAlways"}, unit = "player", talent = 14}, -- Posthaste
        { spell = 186265, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aspect of the Turtle
        { spell = 193534, types = {"buff","buffShowAlways"}, unit = "player", talent = 10}, -- Steady Focus
        { spell = 264663, types = {"buff","buffShowAlways"}, unit = "player"}, -- Predator's Thirst
        { spell = 199483, types = {"buff","buffShowAlways"}, unit = "player", talent = 9}, -- Camouflage
        { spell = 24450, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Prowl
        { spell = 136, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Mend Pet

      },
      icon = 461846
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 135299, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Tar Trap
        { spell = 5116, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Concussive Shot
        { spell = 186387, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Bursting Shot
        { spell = 3355, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Freezing Trap
        { spell = 271788, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Serpent Sting
        { spell = 257284, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12}, -- Hunter's Mark
        { spell = 131894, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 3}, -- A Murder of Crows

      },
      icon = 236188
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 781, types = {"ability","abilityShowAlways"}}, -- Disengage
        { spell = 1543, types = {"ability","abilityShowAlways"}}, -- Flare
        { spell = 5116, types = {"ability","abilityShowAlways"}}, -- Concussive Shot
        { spell = 5384, types = {"ability","abilityShowAlways"}}, -- Feign Death
        { spell = 19434, types = {"ability","abilityShowAlways"}}, -- Aimed Shot
        { spell = 34477, types = {"ability","abilityShowAlways"}}, -- Misdirection
        { spell = 109248, types = {"ability","abilityShowAlways"}, talent = 15}, -- Binding Shot
        { spell = 109304, types = {"ability","abilityShowAlways"}}, -- Exhilaration
        { spell = 120360, types = {"ability","abilityShowAlways"}, talent = 17}, -- Barrage
        { spell = 131894, types = {"ability","abilityShowAlways"}, talent = 3}, -- A Murder of Crows
        { spell = 147362, types = {"ability","abilityShowAlways"}}, -- Counter Shot
        { spell = 185358, types = {"ability","abilityShowAlways"}}, -- Arcane Shot
        { spell = 186257, types = {"ability","abilityShowAlways"}}, -- Aspect of the Cheetah
        { spell = 186265, types = {"ability","abilityShowAlways"}}, -- Aspect of the Turtle
        { spell = 186387, types = {"ability","abilityShowAlways"}}, -- Bursting Shot
        { spell = 187650, types = {"ability","abilityShowAlways"}}, -- Freezing Trap
        { spell = 187698, types = {"ability","abilityShowAlways"}}, -- Tar Trap
        { spell = 193526, types = {"ability","abilityShowAlways"}}, -- Trueshot
        { spell = 198670, types = {"ability","abilityShowAlways"}, talent = 21}, -- Piercing Shot
        { spell = 199483, types = {"ability","abilityShowAlways"}, talent = 9}, -- Camouflage
        { spell = 212431, types = {"ability","abilityShowAlways"}, talent = 6}, -- Explosive Shot
        { spell = 257044, types = {"ability","abilityShowAlways"}}, -- Rapid Fire
        { spell = 257620, types = {"ability","abilityShowAlways"}}, -- Multi-Shot
        { spell = 260402, types = {"ability","abilityShowAlways"}, talent = 18}, -- Double Tap
        { spell = 264667, types = {"ability","abilityShowAlways"}}, -- Primal Rage

      },
      icon = 132329
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 273267, types = {"buff","buffShowAlways"}, unit = "player"}, --Arcane Flurry
        { spell = 263814, types = {"buff","buffShowAlways"}, unit = "player"}, --Arrowstorm
        { spell = 280170, types = {"buff","buffShowAlways"}, unit = "player"}, --Duck and Cover
        { spell = 272733, types = {"buff","buffShowAlways"}, unit = "player"}, --In The Rhythm
        { spell = 263821, types = {"buff","buffShowAlways"}, unit = "player"}, --Ride the Lightning
        { spell = 274357, types = {"buff","buffShowAlways"}, unit = "player"}, --Shellshock
        { spell = 277959, types = {"buff","buffShowAlways"}, unit = "player"}, --Steady Aim
        { spell = 274447, types = {"buff","buffShowAlways"}, unit = "player"}, --Unerring Vision
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 199483, types = {"buff","buffShowAlways"}, unit = "player", talent = 9}, -- Camouflage
        { spell = 35079, types = {"buff","buffShowAlways"}, unit = "player"}, -- Misdirection
        { spell = 231390, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Trailblazer
        { spell = 186258, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aspect of the Cheetah
        { spell = 264667, types = {"buff","buffShowAlways"}, unit = "player"}, -- Primal Rage
        { spell = 259388, types = {"buff","buffShowAlways"}, unit = "player", talent = 17 }, -- Mongoose Fury
        { spell = 225788, types = {"buff","buffShowAlways"}, unit = "player"}, -- Sign of the Emissary
        { spell = 268552, types = {"buff","buffShowAlways"}, unit = "player", talent = 1 }, -- Viper's Venom
        { spell = 260249, types = {"buff","buffShowAlways"}, unit = "player"}, -- Predator
        { spell = 6197, types = {"buff","buffShowAlways"}, unit = "player"}, -- Eagle Eye
        { spell = 264663, types = {"buff","buffShowAlways"}, unit = "player"}, -- Predator's Thirst
        { spell = 266779, types = {"buff","buffShowAlways"}, unit = "player"}, -- Coordinated Assault
        { spell = 5384, types = {"buff","buffShowAlways"}, unit = "player"}, -- Feign Death
        { spell = 260286, types = {"buff","buffShowAlways"}, unit = "player", talent = 16 }, -- Tip of the Spear
        { spell = 186265, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aspect of the Turtle
        { spell = 118922, types = {"buff","buffShowAlways"}, unit = "player", talent = 14 }, -- Posthaste
        { spell = 265898, types = {"buff","buffShowAlways"}, unit = "player", talent = 2 }, -- Terms of Engagement
        { spell = 186289, types = {"buff","buffShowAlways"}, unit = "player"}, -- Aspect of the Eagle
        { spell = 264663, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Predator's Thirst
        { spell = 266779, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Coordinated Assault
        { spell = 263892, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Catlike Reflexes
        { spell = 61684, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Dash
        { spell = 136, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Mend Pet
        { spell = 260249, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Predator
        { spell = 24450, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Prowl

      },
      icon = 1376044
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 270339, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 20 }, -- Shrapnel Bomb
        { spell = 270332, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 20 }, -- Pheromone Bomb
        { spell = 24394, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Intimidation
        { spell = 135299, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Tar Trap
        { spell = 270343, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Internal Bleeding
        { spell = 195645, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Wing Clip
        { spell = 269747, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Wildfire Bomb
        { spell = 162487, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 11 }, -- Steel Trap
        { spell = 131894, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12 }, -- A Murder of Crows
        { spell = 259277, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 10 }, -- Kill Command
        { spell = 190927, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Harpoon
        { spell = 162480, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Steel Trap
        { spell = 2649, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Growl
        { spell = 3355, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Freezing Trap
        { spell = 259491, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Serpent Sting
        { spell = 271049, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Volatile Bomb
        { spell = 117405, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15 }, -- Binding Shot

      },
      icon = 132309
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 781, types = {"ability","abilityShowAlways"}}, -- Disengage
        { spell = 1543, types = {"ability","abilityShowAlways"}}, -- Flare
        { spell = 2649, types = {"ability","abilityShowAlways"}}, -- Growl
        { spell = 5384, types = {"ability","abilityShowAlways"}}, -- Feign Death
        { spell = 16827, types = {"ability","abilityShowAlways"}}, -- Claw
        { spell = 19434, types = {"ability","abilityShowAlways"}}, -- Aimed Shot
        { spell = 19577, types = {"ability","abilityShowAlways"}}, -- Intimidation
        { spell = 24450, types = {"ability","abilityShowAlways"}}, -- Prowl
        { spell = 34477, types = {"ability","abilityShowAlways"}}, -- Misdirection
        { spell = 61684, types = {"ability","abilityShowAlways"}}, -- Dash
        { spell = 109248, types = {"ability","abilityShowAlways"}}, -- Binding Shot
        { spell = 109304, types = {"ability","abilityShowAlways"}}, -- Exhilaration
        { spell = 131894, types = {"ability","abilityShowAlways"}, talent = 12}, -- A Murder of Crows
        { spell = 162488, types = {"ability","abilityShowAlways"}, talent = 11}, -- Steel Trap
        { spell = 186257, types = {"ability","abilityShowAlways"}}, -- Aspect of the Cheetah
        { spell = 186265, types = {"ability","abilityShowAlways"}}, -- Aspect of the Turtle
        { spell = 186289, types = {"ability","abilityShowAlways"}}, -- Aspect of the Eagle
        { spell = 187650, types = {"ability","abilityShowAlways"}}, -- Freezing Trap
        { spell = 187698, types = {"ability","abilityShowAlways"}}, -- Tar Trap
        { spell = 187707, types = {"ability","abilityShowAlways"}}, -- Muzzle
        { spell = 187708, types = {"ability","abilityShowAlways"}}, -- Carve
        { spell = 190925, types = {"ability","abilityShowAlways"}}, -- Harpoon
        { spell = 199483, types = {"ability","abilityShowAlways"}, talent = 9}, -- Camouflage
        { spell = 212436, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Butchery
        { spell = 259391, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Chakrams
        { spell = 259489, types = {"ability","abilityShowAlways"}}, -- Kill Command
        { spell = 259495, types = {"ability","abilityShowAlways"}}, -- Wildfire Bomb
        { spell = 263892, types = {"ability","abilityShowAlways"}}, -- Catlike Reflexes
        { spell = 264667, types = {"ability","abilityShowAlways"}}, -- Primal Rage
        { spell = 266779, types = {"ability","abilityShowAlways"}}, -- Coordinated Assault
        { spell = 269751, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Flanking Strike
        { spell = 270323, types = {"ability","abilityShowAlways"}, talent = 20 }, -- Pheromone Bomb
        { spell = 270335, types = {"ability","abilityShowAlways"}, talent = 20}, -- Shrapnel Bomb
        { spell = 271045, types = {"ability","abilityShowAlways"}, talent = 20}, -- Volatile Bomb
        { spell = 272678, types = {"ability","abilityShowAlways"}}, -- Primal Rage

      },
      icon = 236184
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277969, types = {"buff","buffShowAlways"}, unit = "player"}, --Blur of Talons
        { spell = 280170, types = {"buff","buffShowAlways"}, unit = "player"}, --Duck and Cover
        { spell = 273286, types = {"buff","buffShowAlways"}, unit = "player"}, --Latent Poison
        { spell = 263821, types = {"buff","buffShowAlways"}, unit = "player"}, --Ride the Lightning
        { spell = 274357, types = {"buff","buffShowAlways"}, unit = "player"}, --Shellshock
        { spell = 279593, types = {"buff","buffShowAlways"}, unit = "player"}, --Up Close And Personal
        { spell = 263818, types = {"buff","buffShowAlways"}, unit = "player"}, --Vigorous Wings
        { spell = 264199, types = {"buff","buffShowAlways"}, unit = "player"}, --Whirling Rebound
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 121153, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blindside
        { spell = 5277, types = {"buff","buffShowAlways"}, unit = "player"}, -- Evasion
        { spell = 8679, types = {"buff","buffShowAlways"}, unit = "player"}, -- Wound Poison
        { spell = 57934, types = {"buff","buffShowAlways"}, unit = "player"}, -- Tricks of the Trade
        { spell = 108211, types = {"buff","buffShowAlways"}, unit = "player", talent = 10}, -- Leeching Poison
        { spell = 2823, types = {"buff","buffShowAlways"}, unit = "player"}, -- Deadly Poison
        { spell = 193641, types = {"buff","buffShowAlways"}, unit = "player", talent = 2}, -- Elaborate Planning
        { spell = 115192, types = {"buff","buffShowAlways"}, unit = "player", talent = 5}, -- Subterfuge
        { spell = 114018, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shroud of Concealment
        { spell = 32645, types = {"buff","buffShowAlways"}, unit = "player"}, -- Envenom
        { spell = 36554, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shadowstep
        { spell = 185311, types = {"buff","buffShowAlways"}, unit = "player"}, -- Crimson Vial
        { spell = 270070, types = {"buff","buffShowAlways"}, unit = "player", talent = 20}, -- Hidden Blades
        { spell = 256735, types = {"buff","buffShowAlways"}, unit = "player", talent = 6}, -- Master Assassin
        { spell = 1966, types = {"buff","buffShowAlways"}, unit = "player"}, -- Feint
        { spell = 1784, types = {"buff","buffShowAlways"}, unit = "player"}, -- Stealth
        { spell = 31224, types = {"buff","buffShowAlways"}, unit = "player"}, -- Cloak of Shadows
        { spell = 11327, types = {"buff","buffShowAlways"}, unit = "player"}, -- Vanish
        { spell = 3408, types = {"buff","buffShowAlways"}, unit = "player"}, -- Crippling Poison
        { spell = 2983, types = {"buff","buffShowAlways"}, unit = "player"}, -- Sprint
        { spell = 45182, types = {"buff","buffShowAlways"}, unit = "player", talent = 11 }, -- Cheating Death
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 137619, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 9}, -- Marked for Death
        { spell = 1330, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Garrote - Silence
        { spell = 256148, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 14}, -- Iron Wire
        { spell = 154953, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 13}, -- Internal Bleeding
        { spell = 1833, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Cheap Shot
        { spell = 6770, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Sap
        { spell = 255909, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15}, -- Prey on the Weak
        { spell = 703, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Garrote
        { spell = 245389, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 17}, -- Toxic Blade
        { spell = 2818, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Deadly Poison
        { spell = 3409, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Crippling Poison
        { spell = 2094, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Blind
        { spell = 408, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Kidney Shot
        { spell = 121411, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 21}, -- Crimson Tempest
        { spell = 79140, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Vendetta
        { spell = 1943, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Rupture
        { spell = 8680, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Wound Poison
        { spell = 45181, types = {"debuff","debuffShowAlways"}, unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 132302
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, types = {"ability","abilityShowAlways"}}, -- Kidney Shot
        { spell = 703, types = {"ability","abilityShowAlways"}}, -- Garrote
        { spell = 1725, types = {"ability","abilityShowAlways"}}, -- Distract
        { spell = 1766, types = {"ability","abilityShowAlways"}}, -- Kick
        { spell = 1784, types = {"ability","abilityShowAlways"}}, -- Stealth
        { spell = 1856, types = {"ability","abilityShowAlways"}}, -- Vanish
        { spell = 1966, types = {"ability","abilityShowAlways"}}, -- Feint
        { spell = 2094, types = {"ability","abilityShowAlways"}}, -- Blind
        { spell = 2983, types = {"ability","abilityShowAlways"}}, -- Sprint
        { spell = 5277, types = {"ability","abilityShowAlways"}}, -- Evasion
        { spell = 31224, types = {"ability","abilityShowAlways"}}, -- Cloak of Shadows
        { spell = 36554, types = {"ability","abilityShowAlways"}}, -- Shadowstep
        { spell = 79140, types = {"ability","abilityShowAlways"}}, -- Vendetta
        { spell = 114018, types = {"ability","abilityShowAlways"}}, -- Shroud of Concealment
        { spell = 115191, types = {"ability","abilityShowAlways"}}, -- Stealth
        { spell = 137619, types = {"ability","abilityShowAlways"}, talent = 9}, -- Marked for Death
        { spell = 185311, types = {"ability","abilityShowAlways"}}, -- Crimson Vial
        { spell = 200806, types = {"ability","abilityShowAlways"}, talent = 18}, -- Exsanguinate
        { spell = 245388, types = {"ability","abilityShowAlways"}, talent = 17}, -- Toxic Blade
        { spell = 57934, types = {"ability","abilityShowAlways"}}, -- Tricks of the Trade
      },
      icon = 458726
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 274695, types = {"buff","buffShowAlways"}, unit = "group"}, --Footpad
        { spell = 280200, types = {"buff","buffShowAlways"}, unit = "player"}, --Shrouded Mantle
        { spell = 276083, types = {"buff","buffShowAlways"}, unit = "player"}, --Poisoned Wire
        { spell = 277731, types = {"buff","buffShowAlways"}, unit = "player"}, --Scent of Blood
        { spell = 279703, types = {"buff","buffShowAlways"}, unit = "player"}, --Shrouded Suffocation
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 193357, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ruthless Precision
        { spell = 199600, types = {"buff","buffShowAlways"}, unit = "player"}, -- Buried Treasure
        { spell = 193358, types = {"buff","buffShowAlways"}, unit = "player"}, -- Grand Melee
        { spell = 51690, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Killing Spree
        { spell = 114018, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shroud of Concealment
        { spell = 271896, types = {"buff","buffShowAlways"}, unit = "player", talent = 20}, -- Blade Rush
        { spell = 5171, types = {"buff","buffShowAlways"}, unit = "player", talent = 18}, -- Slice and Dice
        { spell = 13750, types = {"buff","buffShowAlways"}, unit = "player"}, -- Adrenaline Rush
        { spell = 193359, types = {"buff","buffShowAlways"}, unit = "player"}, -- True Bearing
        { spell = 199603, types = {"buff","buffShowAlways"}, unit = "player"}, -- Skull and Crossbones
        { spell = 199754, types = {"buff","buffShowAlways"}, unit = "player"}, -- Riposte
        { spell = 185311, types = {"buff","buffShowAlways"}, unit = "player"}, -- Crimson Vial
        { spell = 2983, types = {"buff","buffShowAlways"}, unit = "player"}, -- Sprint
        { spell = 1966, types = {"buff","buffShowAlways"}, unit = "player"}, -- Feint
        { spell = 193538, types = {"buff","buffShowAlways"}, unit = "player", talent = 17}, -- Alacrity
        { spell = 1784, types = {"buff","buffShowAlways"}, unit = "player"}, -- Stealth
        { spell = 31224, types = {"buff","buffShowAlways"}, unit = "player"}, -- Cloak of Shadows
        { spell = 195627, types = {"buff","buffShowAlways"}, unit = "player"}, -- Opportunity
        { spell = 11327, types = {"buff","buffShowAlways"}, unit = "player"}, -- Vanish
        { spell = 13877, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blade Flurry
        { spell = 193356, types = {"buff","buffShowAlways"}, unit = "player"}, -- Broadside
        { spell = 57934, types = {"buff","buffShowAlways"}, unit = "player"}, -- Tricks of the Trade
        { spell = 45182, types = {"buff","buffShowAlways"}, unit = "player", talent = 11 }, -- Cheating Death
      },
      icon = 132350
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 255909, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15}, -- Prey on the Weak
        { spell = 199804, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Between the Eyes
        { spell = 185763, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Pistol Shot
        { spell = 1833, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Cheap Shot
        { spell = 196937, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 3}, -- Ghostly Strike
        { spell = 137619, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 9}, -- Marked for Death
        { spell = 2094, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Blind
        { spell = 1776, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Gouge
        { spell = 6770, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Sap
        { spell = 45181, types = {"debuff","debuffShowAlways"}, unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 1373908
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 1725, types = {"ability","abilityShowAlways"}}, -- Distract
        { spell = 1766, types = {"ability","abilityShowAlways"}}, -- Kick
        { spell = 1776, types = {"ability","abilityShowAlways"}}, -- Gouge
        { spell = 1784, types = {"ability","abilityShowAlways"}}, -- Stealth
        { spell = 1856, types = {"ability","abilityShowAlways"}}, -- Vanish
        { spell = 1966, types = {"ability","abilityShowAlways"}}, -- Feint
        { spell = 2094, types = {"ability","abilityShowAlways"}}, -- Blind
        { spell = 2983, types = {"ability","abilityShowAlways"}}, -- Sprint
        { spell = 13750, types = {"ability","abilityShowAlways"}}, -- Adrenaline Rush
        { spell = 13877, types = {"ability","abilityShowAlways"}}, -- Blade Flurry
        { spell = 31224, types = {"ability","abilityShowAlways"}}, -- Cloak of Shadows
        { spell = 51690, types = {"ability","abilityShowAlways"}, talent = 21}, -- Killing Spree
        { spell = 79096, types = {"ability","abilityShowAlways"}}, -- Restless Blades
        { spell = 114018, types = {"ability","abilityShowAlways"}}, -- Shroud of Concealment
        { spell = 137619, types = {"ability","abilityShowAlways"}, talent = 9}, -- Marked for Death
        { spell = 185311, types = {"ability","abilityShowAlways"}}, -- Crimson Vial
        { spell = 195457, types = {"ability","abilityShowAlways"}}, -- Grappling Hook
        { spell = 196937, types = {"ability","abilityShowAlways"}, talent = 3}, -- Ghostly Strike
        { spell = 199754, types = {"ability","abilityShowAlways"}}, -- Riposte
        { spell = 199804, types = {"ability","abilityShowAlways"}}, -- Between the Eyes
        { spell = 271877, types = {"ability","abilityShowAlways"}, talent = 20}, -- Blade Rush
        { spell = 57934, types = {"ability","abilityShowAlways"}}, -- Tricks of the Trade
      },
      icon = 135610
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277725, types = {"buff","buffShowAlways"}, unit = "player"}, --Brigand's Blitz
        { spell = 272940, types = {"buff","buffShowAlways"}, unit = "player"}, --Deadshot
        { spell = 274695, types = {"buff","buffShowAlways"}, unit = "group"}, --Footpad
        { spell = 278962, types = {"buff","buffShowAlways"}, unit = "player"}, --Paradise Lost
        { spell = 280200, types = {"buff","buffShowAlways"}, unit = "player"}, --Shrouded Mantle
        { spell = 275863, types = {"buff","buffShowAlways"}, unit = "player"}, --Snake Eyes
        { spell = 273455, types = {"buff","buffShowAlways"}, unit = "player"}, --Storm of Steel
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 196980, types = {"buff","buffShowAlways"}, unit = "player", talent = 19}, -- Master of Shadows
        { spell = 5277, types = {"buff","buffShowAlways"}, unit = "player"}, -- Evasion
        { spell = 121471, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shadow Blades
        { spell = 212283, types = {"buff","buffShowAlways"}, unit = "player"}, -- Symbols of Death
        { spell = 185422, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shadow Dance
        { spell = 115192, types = {"buff","buffShowAlways"}, unit = "player", talent = 4}, -- Subterfuge
        { spell = 114018, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shroud of Concealment
        { spell = 257506, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shot in the Dark
        { spell = 185311, types = {"buff","buffShowAlways"}, unit = "player"}, -- Crimson Vial
        { spell = 277925, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Shuriken Tornado
        { spell = 1966, types = {"buff","buffShowAlways"}, unit = "player"}, -- Feint
        { spell = 193538, types = {"buff","buffShowAlways"}, unit = "player", talent = 17}, -- Alacrity
        { spell = 1784, types = {"buff","buffShowAlways"}, unit = "player"}, -- Stealth
        { spell = 31224, types = {"buff","buffShowAlways"}, unit = "player"}, -- Cloak of Shadows
        { spell = 115191, types = {"buff","buffShowAlways"}, unit = "player"}, -- Stealth
        { spell = 11327, types = {"buff","buffShowAlways"}, unit = "player"}, -- Vanish
        { spell = 245640, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shuriken Combo
        { spell = 2983, types = {"buff","buffShowAlways"}, unit = "player"}, -- Sprint
        { spell = 57934, types = {"buff","buffShowAlways"}, unit = "player"}, -- Tricks of the Trade
        { spell = 45182, types = {"buff","buffShowAlways"}, unit = "player", talent = 11 }, -- Cheating Death
      },
      icon = 376022
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 255909, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15}, -- Prey on the Weak
        { spell = 91021, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 2}, -- Find Weakness
        { spell = 195452, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Nightblade
        { spell = 2094, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Blind
        { spell = 137619, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Marked for Death
        { spell = 1833, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Cheap Shot
        { spell = 206760, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 14}, -- Shadow's Grasp
        { spell = 408, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Kidney Shot
        { spell = 6770, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Sap
        { spell = 45181, types = {"debuff","debuffShowAlways"}, unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 136175
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, types = {"ability","abilityShowAlways"}}, -- Kidney Shot
        { spell = 1725, types = {"ability","abilityShowAlways"}}, -- Distract
        { spell = 1766, types = {"ability","abilityShowAlways"}}, -- Kick
        { spell = 1784, types = {"ability","abilityShowAlways"}}, -- Stealth
        { spell = 1856, types = {"ability","abilityShowAlways"}}, -- Vanish
        { spell = 1966, types = {"ability","abilityShowAlways"}}, -- Feint
        { spell = 2094, types = {"ability","abilityShowAlways"}}, -- Blind
        { spell = 2983, types = {"ability","abilityShowAlways"}}, -- Sprint
        { spell = 5277, types = {"ability","abilityShowAlways"}}, -- Evasion
        { spell = 31224, types = {"ability","abilityShowAlways"}}, -- Cloak of Shadows
        { spell = 36554, types = {"ability","abilityShowAlways"}}, -- Shadowstep
        { spell = 114018, types = {"ability","abilityShowAlways"}}, -- Shroud of Concealment
        { spell = 115191, types = {"ability","abilityShowAlways"}}, -- Stealth
        { spell = 121471, types = {"ability","abilityShowAlways"}}, -- Shadow Blades
        { spell = 137619, types = {"ability","abilityShowAlways"}, talent = 9}, -- Marked for Death
        { spell = 185311, types = {"ability","abilityShowAlways"}}, -- Crimson Vial
        { spell = 185313, types = {"ability","abilityShowAlways"}}, -- Shadow Dance
        { spell = 212283, types = {"ability","abilityShowAlways"}}, -- Symbols of Death
        { spell = 277925, types = {"ability","abilityShowAlways"}, talent = 21}, -- Shuriken Tornado
        { spell = 280719, types = {"ability","abilityShowAlways"}, talent = 20}, -- Secret Technique
        { spell = 57934, types = {"ability","abilityShowAlways"}}, -- Tricks of the Trade

      },
      icon = 236279
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 279754, types = {"buff","buffShowAlways"}, unit = "player"}, --Blade In The Shadows
        { spell = 272940, types = {"buff","buffShowAlways"}, unit = "player"}, --Deadshot
        { spell = 273424, types = {"buff","buffShowAlways"}, unit = "player"}, --Night's Vengeance
        { spell = 277720, types = {"buff","buffShowAlways"}, unit = "player"}, --Perforate
        { spell = 272916, types = {"buff","buffShowAlways"}, unit = "player"}, --Sharpened Blades
        { spell = 280200, types = {"buff","buffShowAlways"}, unit = "player"}, --Shrouded Mantle
        { spell = 278981, types = {"buff","buffShowAlways"}, unit = "player"}, --The First Dance
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 586, types = {"buff","buffShowAlways"}, unit = "player"}, -- Fade
        { spell = 198069, types = {"buff","buffShowAlways"}, unit = "player"}, -- Power of the Dark Side
        { spell = 194384, types = {"buff","buffShowAlways"}, unit = "player"}, -- Atonement
        { spell = 17, types = {"buff","buffShowAlways"}, unit = "target"}, -- Power Word: Shield
        { spell = 265258, types = {"buff","buffShowAlways"}, unit = "player", talent = 2}, -- Twist of Fate
        { spell = 271466, types = {"buff","buffShowAlways"}, unit = "player", talent = 20}, -- Luminous Barrier
        { spell = 19236, types = {"buff","buffShowAlways"}, unit = "player"}, -- Desperate Prayer
        { spell = 21562, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 81782, types = {"buff","buffShowAlways"}, unit = "target"}, -- Power Word: Barrier
        { spell = 33206, types = {"buff","buffShowAlways"}, unit = "group"}, -- Pain Suppression
        { spell = 193065, types = {"buff","buffShowAlways"}, unit = "player", talent = 5}, -- Masochism
        { spell = 65081, types = {"buff","buffShowAlways"}, unit = "player", talent = 4}, -- Body and Soul
        { spell = 47536, types = {"buff","buffShowAlways"}, unit = "player"}, -- Rapture
        { spell = 121557, types = {"buff","buffShowAlways"}, unit = "player", talent = 6}, -- Angelic Feather
        { spell = 2096, types = {"buff","buffShowAlways"}, unit = "player"}, -- Mind Vision
        { spell = 111759, types = {"buff","buffShowAlways"}, unit = "player"}, -- Levitate
        { spell = 45243, types = {"buff","buffShowAlways"}, unit = "player" }, -- Focused Will
      },
      icon = 458720
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 8122, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Psychic Scream
        { spell = 204263, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12}, -- Shining Force
        { spell = 208772, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Smite
        { spell = 204213, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 16}, -- Purge the Wicked
        { spell = 2096, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mind Vision
        { spell = 214621, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 3}, -- Schism
        { spell = 589, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Shadow Word: Pain
        { spell = 9484, types = {"debuff","debuffShowAlways"}, unit = "multi" }, -- Shackle Undead
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 527, types = {"ability","abilityShowAlways"}}, -- Purify
        { spell = 586, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Fade
        { spell = 8122, types = {"ability","abilityShowAlways"}}, -- Psychic Scream
        { spell = 19236, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Desperate Prayer
        { spell = 32375, types = {"ability","abilityShowAlways"}}, -- Mass Dispel
        { spell = 33206, types = {"ability","abilityShowAlways"}}, -- Pain Suppression
        { spell = 34433, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Shadowfiend
        { spell = 47536, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Rapture
        { spell = 47540, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Penance
        { spell = 62618, types = {"ability","abilityShowAlways"}}, -- Power Word: Barrier
        { spell = 73325, types = {"ability","abilityShowAlways"}}, -- Leap of Faith
        { spell = 110744, types = {"ability","abilityShowAlways"}, talent = 17}, -- Divine Star
        { spell = 120517, types = {"ability","abilityShowAlways"}, talent = 18}, -- Halo
        { spell = 121536, types = {"ability","abilityCharge","abilityChargeBuff"}, talent = 6}, -- Angelic Feather
        { spell = 123040, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 8}, -- Mindbender
        { spell = 129250, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 9}, -- Power Word: Solace
        { spell = 194509, types = {"ability","abilityCharge"}}, -- Power Word: Radiance
        { spell = 204065, types = {"ability","abilityShowAlways"}, talent = 15}, -- Shadow Covenant
        { spell = 204263, types = {"ability","abilityShowAlways"}, talent = 12}, -- Shining Force
        { spell = 214621, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 3}, -- Schism
        { spell = 246287, types = {"ability","abilityShowAlways"}}, -- Evangelism
        { spell = 271466, types = {"ability","abilityShowAlways"}, talent = 20}, -- Luminous Barrier

      },
      icon = 253400
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275544, types = {"buff","buffShowAlways"}, unit = "player"}, --Depth of the Shadows
        { spell = 274369, types = {"buff","buffShowAlways"}, unit = "player"}, --Sanctum
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 47788, types = {"buff","buffShowAlways"}, unit = "target"}, -- Guardian Spirit
        { spell = 64901, types = {"buff","buffShowAlways"}, unit = "player"}, -- Symbol of Hope
        { spell = 139, types = {"buff","buffShowAlways"}, unit = "target"}, -- Renew
        { spell = 2096, types = {"buff","buffShowAlways"}, unit = "player"}, -- Mind Vision
        { spell = 64843, types = {"buff","buffShowAlways"}, unit = "player"}, -- Divine Hymn
        { spell = 19236, types = {"buff","buffShowAlways"}, unit = "player"}, -- Desperate Prayer
        { spell = 21562, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 111759, types = {"buff","buffShowAlways"}, unit = "player"}, -- Levitate
        { spell = 200183, types = {"buff","buffShowAlways"}, unit = "player", talent = 20}, -- Apotheosis
        { spell = 27827, types = {"buff","buffShowAlways"}, unit = "player"}, -- Spirit of Redemption
        { spell = 77489, types = {"buff","buffShowAlways"}, unit = "target"}, -- Echo of Light
        { spell = 114255, types = {"buff","buffShowAlways"}, unit = "player", talent = 13}, -- Surge of Light
        { spell = 121557, types = {"buff","buffShowAlways"}, unit = "player", talent = 6}, -- Angelic Feather
        { spell = 586, types = {"buff","buffShowAlways"}, unit = "player"}, -- Fade
        { spell = 41635, types = {"buff","buffShowAlways"}, unit = "group"}, -- Prayer of Mending
        { spell = 45243, types = {"buff","buffShowAlways"}, unit = "player" }, -- Focused Will
      },
      icon = 135953
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 8122, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Psychic Scream
        { spell = 200196, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Holy Word: Chastise
        { spell = 14914, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Holy Fire
        { spell = 2096, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mind Vision
        { spell = 204263, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Shining Force
        { spell = 200200, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Holy Word: Chastise
        { spell = 9484, types = {"debuff","debuffShowAlways"}, unit = "multi" }, -- Shackle Undead
      },
      icon = 135972
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 527, types = {"ability","abilityShowAlways"}}, -- Purify
        { spell = 586, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Fade
        { spell = 2050, types = {"ability","abilityShowAlways"}}, -- Holy Word: Serenity
        { spell = 2061, types = {"ability","abilityShowAlways"}}, -- Flash Heal
        { spell = 8122, types = {"ability","abilityShowAlways"}}, -- Psychic Scream
        { spell = 14914, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Holy Fire
        { spell = 19236, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Desperate Prayer
        { spell = 32375, types = {"ability","abilityShowAlways"}}, -- Mass Dispel
        { spell = 33076, types = {"ability","abilityShowAlways"}}, -- Prayer of Mending
        { spell = 34861, types = {"ability","abilityShowAlways"}}, -- Holy Word: Sanctify
        { spell = 47788, types = {"ability","abilityShowAlways"}}, -- Guardian Spirit
        { spell = 64843, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Divine Hymn
        { spell = 64901, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Symbol of Hope
        { spell = 73325, types = {"ability","abilityShowAlways"}}, -- Leap of Faith
        { spell = 88625, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Holy Word: Chastise
        { spell = 110744, types = {"ability","abilityShowAlways"}, talent = 17}, -- Divine Star
        { spell = 120517, types = {"ability","abilityShowAlways"}, talent = 18}, -- Halo
        { spell = 121536, types = {"ability","abilityCharge","abilityChargeBuff"}, talent = 6}, -- Angelic Feather
        { spell = 200183, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 20}, -- Apotheosis
        { spell = 204263, types = {"ability","abilityShowAlways"}, talent = 12}, -- Shining Force
        { spell = 204883, types = {"ability","abilityShowAlways"}, talent = 15}, -- Circle of Healing
        { spell = 265202, types = {"ability","abilityShowAlways"}, talent = 21}, -- Holy Word: Salvation

      },
      icon = 135937
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272783, types = {"buff","buffShowAlways"}, unit = "target"}, --Permeating Glow
        { spell = 274369, types = {"buff","buffShowAlways"}, unit = "player"}, --Sanctum
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 193223, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Surrender to Madness
        { spell = 263165, types = {"buff","buffShowAlways"}, unit = "player", talent = 18}, -- Void Torrent
        { spell = 586, types = {"buff","buffShowAlways"}, unit = "player"}, -- Fade
        { spell = 2096, types = {"buff","buffShowAlways"}, unit = "player"}, -- Mind Vision
        { spell = 15286, types = {"buff","buffShowAlways"}, unit = "player"}, -- Vampiric Embrace
        { spell = 124430, types = {"buff","buffShowAlways"}, unit = "player", talent = 2}, -- Shadowy Insight
        { spell = 17, types = {"buff","buffShowAlways"}, unit = "player"}, -- Power Word: Shield
        { spell = 65081, types = {"buff","buffShowAlways"}, unit = "player", talent = 4}, -- Body and Soul
        { spell = 197937, types = {"buff","buffShowAlways"}, unit = "player", talent = 16}, -- Lingering Insanity
        { spell = 194249, types = {"buff","buffShowAlways"}, unit = "player"}, -- Voidform
        { spell = 47585, types = {"buff","buffShowAlways"}, unit = "player"}, -- Dispersion
        { spell = 232698, types = {"buff","buffShowAlways"}, unit = "player"}, -- Shadowform
        { spell = 21562, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 111759, types = {"buff","buffShowAlways"}, unit = "player"}, -- Levitate
        { spell = 123254, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Twist of Fate
      },
      icon = 237566
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 15407, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mind Flay
        { spell = 48045, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mind Sear
        { spell = 2096, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mind Vision
        { spell = 205369, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 11}, -- Mind Bomb
        { spell = 226943, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 11}, -- Mind Bomb
        { spell = 263165, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 18}, -- Void Torrent
        { spell = 15487, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Silence
        { spell = 589, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Shadow Word: Pain
        { spell = 8122, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Psychic Scream
        { spell = 34914, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Vampiric Touch
        { spell = 9484, types = {"debuff","debuffShowAlways"}, unit = "multi" }, -- Shackle Undead
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Power Word: Shield
        { spell = 586, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Fade
        { spell = 8092, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Mind Blast
        { spell = 8122, types = {"ability","abilityShowAlways"}}, -- Psychic Scream
        { spell = 15286, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Vampiric Embrace
        { spell = 15487, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Silence
        { spell = 32375, types = {"ability","abilityShowAlways"}}, -- Mass Dispel
        { spell = 32379, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 14}, -- Shadow Word: Death
        { spell = 34433, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Shadowfiend
        { spell = 47585, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Dispersion
        { spell = 64044, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 12}, -- Psychic Horror
        { spell = 73325, types = {"ability","abilityShowAlways"}}, -- Leap of Faith
        { spell = 193223, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 21}, -- Surrender to Madness
        { spell = 200174, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 17}, -- Mindbender
        { spell = 205351, types = {"ability","abilityCharge","abilityChargeTarget"}, talent = 3}, -- Shadow Word: Void
        { spell = 205369, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 11}, -- Mind Bomb
        { spell = 205385, types = {"ability","abilityShowAlways"}, talent = 15}, -- Shadow Crash
        { spell = 205448, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Void Bolt
        { spell = 213634, types = {"ability","abilityShowAlways"}}, -- Purify Disease
        { spell = 228260, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Void Eruption
        { spell = 263165, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 18}, -- Void Torrent
        { spell = 263346, types = {"ability","abilityShowAlways"}, talent = 9}, -- Dark Void
        { spell = 280711, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 20}, -- Dark Ascension

      },
      icon = 136230
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 279572, types = {"buff","buffShowAlways"}, unit = "player"}, --Chorus of Insanity
        { spell = 275544, types = {"buff","buffShowAlways"}, unit = "player"}, --Depth of the Shadows
        { spell = 273321, types = {"buff","buffShowAlways"}, unit = "player"}, --Harvested Thoughts
        { spell = 274369, types = {"buff","buffShowAlways"}, unit = "player"}, --Sanctum
        { spell = 275726, types = {"buff","buffShowAlways"}, unit = "player"}, --Whispers of the Damned
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 263806, types = {"buff","buffShowAlways"}, unit = "player", talent = 11}, -- Wind Gust
        { spell = 192082, types = {"buff","buffShowAlways"}, unit = "player", talent = 15}, -- Wind Rush
        { spell = 202192, types = {"buff","buffShowAlways"}, unit = "player", talent = 6}, -- Resonance Totem
        { spell = 210659, types = {"buff","buffShowAlways"}, unit = "player", talent = 6}, -- Tailwind Totem
        { spell = 173184, types = {"buff","buffShowAlways"}, unit = "player", talent = 3}, -- Elemental Blast: Mastery
        { spell = 108271, types = {"buff","buffShowAlways"}, unit = "player"}, -- Astral Shift
        { spell = 210652, types = {"buff","buffShowAlways"}, unit = "player", talent = 6}, -- Storm Totem
        { spell = 272737, types = {"buff","buffShowAlways"}, unit = "player", talent = 19}, -- Unlimited Power
        { spell = 108281, types = {"buff","buffShowAlways"}, unit = "player", talent = 14}, -- Ancestral Guidance
        { spell = 546, types = {"buff","buffShowAlways"}, unit = "player"}, -- Water Walking
        { spell = 114050, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Ascendance
        { spell = 210714, types = {"buff","buffShowAlways"}, unit = "player", talent = 17}, -- Icefury
        { spell = 260881, types = {"buff","buffShowAlways"}, unit = "player"}, -- Spirit Wolf
        { spell = 260734, types = {"buff","buffShowAlways"}, unit = "player", talent = 5}, -- Master of the Elements
        { spell = 191634, types = {"buff","buffShowAlways"}, unit = "player", talent = 20}, -- Stormkeeper
        { spell = 118337, types = {"buff","buffShowAlways"}, unit = "player", talent = 16}, -- Harden Skin
        { spell = 974, types = {"buff","buffShowAlways"}, unit = "player", talent = 8}, -- Earth Shield
        { spell = 6196, types = {"buff","buffShowAlways"}, unit = "player"}, -- Far Sight
        { spell = 210658, types = {"buff","buffShowAlways"}, unit = "player", talent = 6}, -- Ember Totem
        { spell = 173183, types = {"buff","buffShowAlways"}, unit = "player", talent = 3}, -- Elemental Blast: Haste
        { spell = 77762, types = {"buff","buffShowAlways"}, unit = "player"}, -- Lava Surge
        { spell = 2645, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ghost Wolf
        { spell = 118522, types = {"buff","buffShowAlways"}, unit = "player", talent = 3}, -- Elemental Blast: Critical Strike
        { spell = 157348, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Call Lightning

      },
      icon = 451169
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 269808, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 1}, -- Exposed Elements
        { spell = 118905, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Static Charge
        { spell = 182387, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Earthquake
        { spell = 188389, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Flame Shock
        { spell = 51490, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Thunderstorm
        { spell = 196840, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Frost Shock
        { spell = 118297, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Immolate
        { spell = 3600, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Earthbind
        { spell = 157375, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Eye of the Storm
        { spell = 118345, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Pulverize

      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 556, types = {"ability","abilityShowAlways"}}, -- Astral Recall
        { spell = 2484, types = {"ability","abilityShowAlways"}}, -- Earthbind Totem
        { spell = 8143, types = {"ability","abilityShowAlways"}}, -- Tremor Totem
        { spell = 32182, types = {"ability","abilityShowAlways"}}, -- Heroism
        { spell = 51490, types = {"ability","abilityShowAlways"}}, -- Thunderstorm
        { spell = 51505, types = {"ability","abilityShowAlways"}}, -- Lava Burst
        { spell = 51514, types = {"ability","abilityShowAlways"}}, -- Hex
        { spell = 51886, types = {"ability","abilityShowAlways"}}, -- Cleanse Spirit
        { spell = 57994, types = {"ability","abilityShowAlways"}}, -- Wind Shear
        { spell = 108271, types = {"ability","abilityShowAlways"}}, -- Astral Shift
        { spell = 108281, types = {"ability","abilityShowAlways"}}, -- Ancestral Guidance
        { spell = 114050, types = {"ability","abilityShowAlways"}, talent = 21}, -- Ascendance
        { spell = 117014, types = {"ability","abilityShowAlways"}, talent = 3}, -- Elemental Blast
        { spell = 188389, types = {"ability","abilityShowAlways"}}, -- Flame Shock
        { spell = 191634, types = {"ability","abilityShowAlways"}, talent = 20}, -- Stormkeeper
        { spell = 192058, types = {"ability","abilityShowAlways"}}, -- Capacitor Totem
        { spell = 192077, types = {"ability","abilityShowAlways"}, talent = 15}, -- Wind Rush Totem
        { spell = 192222, types = {"ability","abilityShowAlways"}, talent = 12}, -- Liquid Magma Totem
        { spell = 192249, types = {"ability","abilityShowAlways"}, talent = 11}, -- Storm Elemental
        { spell = 198067, types = {"ability","abilityShowAlways"}}, -- Fire Elemental
        { spell = 198103, types = {"ability","abilityShowAlways"}}, -- Earth Elemental
        { spell = 210714, types = {"ability","abilityShowAlways"}, talent = 17}, -- Icefury
      },
      icon = 135790
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277942, types = {"buff","buffShowAlways"}, unit = "player"}, --Ancestral Resonance
        { spell = 263786, types = {"buff","buffShowAlways"}, unit = "player"}, --Astral Shift
        { spell = 264113, types = {"buff","buffShowAlways"}, unit = "player"}, --Flames of the Forefathers
        { spell = 263792, types = {"buff","buffShowAlways"}, unit = "player"}, --Lightningburn
        { spell = 279028, types = {"buff","buffShowAlways"}, unit = "player"}, --Natural Harmony (Fire)
        { spell = 279029, types = {"buff","buffShowAlways"}, unit = "player"}, --Natural Harmony (Frost)
        { spell = 279033, types = {"buff","buffShowAlways"}, unit = "player"}, --Natural Harmony (Nature)
        { spell = 280205, types = {"buff","buffShowAlways"}, unit = "player"}, --Pack Spirit
        { spell = 279523, types = {"buff","buffShowAlways"}, unit = "player"}, --Rumbling Tremors
        { spell = 277960, types = {"buff","buffShowAlways"}, unit = "player"}, --Synapse Shock
        { spell = 272981, types = {"buff","buffShowAlways"}, unit = "player"}, --Volcanic Lightning
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 273323, types = {"buff","buffShowAlways"}, unit = "player", talent = 3 }, -- Lightning Shield Overcharge
        { spell = 192082, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Wind Rush
        { spell = 974, types = {"buff","buffShowAlways"}, unit = "player", talent = 8 }, -- Earth Shield
        { spell = 262652, types = {"buff","buffShowAlways"}, unit = "player", talent = 5 }, -- Forceful Winds
        { spell = 187878, types = {"buff","buffShowAlways"}, unit = "player"}, -- Crash Lightning
        { spell = 262397, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Storm Totem
        { spell = 192106, types = {"buff","buffShowAlways"}, unit = "player", talent = 3 }, -- Lightning Shield
        { spell = 108271, types = {"buff","buffShowAlways"}, unit = "player"}, -- Astral Shift
        { spell = 6196, types = {"buff","buffShowAlways"}, unit = "player"}, -- Far Sight
        { spell = 196834, types = {"buff","buffShowAlways"}, unit = "player"}, -- Frostbrand
        { spell = 224126, types = {"buff","buffShowAlways"}, unit = "player", talent = 19 }, -- Icy Edge
        { spell = 546, types = {"buff","buffShowAlways"}, unit = "player"}, -- Water Walking
        { spell = 114051, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Ascendance
        { spell = 224125, types = {"buff","buffShowAlways"}, unit = "player", talent = 19 }, -- Molten Weapon
        { spell = 202004, types = {"buff","buffShowAlways"}, unit = "player", talent = 4 }, -- Landslide
        { spell = 262400, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Tailwind Totem
        { spell = 58875, types = {"buff","buffShowAlways"}, unit = "player"}, -- Spirit Walk
        { spell = 198300, types = {"buff","buffShowAlways"}, unit = "player"}, -- Gathering Storms
        { spell = 224127, types = {"buff","buffShowAlways"}, unit = "player", talent = 19 }, -- Crackling Surge
        { spell = 197211, types = {"buff","buffShowAlways"}, unit = "player", talent = 17 }, -- Fury of Air
        { spell = 201846, types = {"buff","buffShowAlways"}, unit = "player"}, -- Stormbringer
        { spell = 260881, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Spirit Wolf
        { spell = 262417, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Resonance Totem
        { spell = 262399, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Ember Totem
        { spell = 2645, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ghost Wolf
        { spell = 215785, types = {"buff","buffShowAlways"}, unit = "player", talent = 2 }, -- Hot Hand
        { spell = 194084, types = {"buff","buffShowAlways"}, unit = "player"}, -- Flametongue
      },
      icon = 136099
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118905, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Static Charge
        { spell = 197214, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 18 }, -- Sundering
        { spell = 147732, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Frostbrand
        { spell = 271924, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 19 }, -- Molten Weapon
        { spell = 3600, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Earthbind
        { spell = 188089, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 20 }, -- Earthen Spike
        { spell = 197385, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 17 }, -- Fury of Air
        { spell = 268429, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 10 }, -- Searing Assault
      },
      icon = 462327
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 556, types = {"ability","abilityShowAlways"}}, -- Astral Recall
        { spell = 2484, types = {"ability","abilityShowAlways"}}, -- Earthbind Totem
        { spell = 8143, types = {"ability","abilityShowAlways"}}, -- Tremor Totem
        { spell = 17364, types = {"ability","abilityShowAlways"}}, -- Stormstrike
        { spell = 32182, types = {"ability","abilityShowAlways"}}, -- Heroism
        { spell = 51514, types = {"ability","abilityShowAlways"}}, -- Hex
        { spell = 51533, types = {"ability","abilityShowAlways"}}, -- Feral Spirit
        { spell = 51886, types = {"ability","abilityShowAlways"}}, -- Cleanse Spirit
        { spell = 57994, types = {"ability","abilityShowAlways"}}, -- Wind Shear
        { spell = 58875, types = {"ability","abilityShowAlways"}}, -- Spirit Walk
        { spell = 108271, types = {"ability","abilityShowAlways"}}, -- Astral Shift
        { spell = 114051, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Ascendance
        { spell = 115356, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Windstrike
        { spell = 187837, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Lightning Bolt
        { spell = 187874, types = {"ability","abilityShowAlways"}}, -- Crash Lightning
        { spell = 188089, types = {"ability","abilityShowAlways"}, talent = 20 }, -- Earthen Spike
        { spell = 192058, types = {"ability","abilityShowAlways"}}, -- Capacitor Totem
        { spell = 192077, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Wind Rush Totem
        { spell = 193786, types = {"ability","abilityShowAlways"}}, -- Rockbiter
        { spell = 193796, types = {"ability","abilityShowAlways"}}, -- Flametongue
        { spell = 196884, types = {"ability","abilityShowAlways"}, talent = 14 }, -- Feral Lunge
        { spell = 197214, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Sundering
        { spell = 198103, types = {"ability","abilityShowAlways"}}, -- Earth Elemental
      },
      icon = 1370984
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277942, types = {"buff","buffShowAlways"}, unit = "player"}, --Ancestral Resonance
        { spell = 263786, types = {"buff","buffShowAlways"}, unit = "player"}, --Astral Shift
        { spell = 264121, types = {"buff","buffShowAlways"}, unit = "player"}, --Electropotence
        { spell = 275391, types = {"buff","buffShowAlways"}, unit = "target"}, --Lightning Conduit
        { spell = 280205, types = {"buff","buffShowAlways"}, unit = "player"}, --Pack Spirit
        { spell = 273006, types = {"buff","buffShowAlways"}, unit = "player"}, --Primal Primer
        { spell = 279515, types = {"buff","buffShowAlways"}, unit = "player"}, --Roiling Storm
        { spell = 263795, types = {"buff","buffShowAlways"}, unit = "player"}, --Storm's Eye
        { spell = 273465, types = {"buff","buffShowAlways"}, unit = "player"}, --Strength of Earth
        { spell = 277960, types = {"buff","buffShowAlways"}, unit = "player"}, --Synapse Shock
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 79206, types = {"buff","buffShowAlways"}, unit = "player"}, -- Spiritwalker's Grace
        { spell = 114052, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Ascendance
        { spell = 974, types = {"buff","buffShowAlways"}, unit = "group", talent = 6 }, -- Earth Shield
        { spell = 216251, types = {"buff","buffShowAlways"}, unit = "player", talent = 2 }, -- Undulation
        { spell = 108271, types = {"buff","buffShowAlways"}, unit = "player"}, -- Astral Shift
        { spell = 6196, types = {"buff","buffShowAlways"}, unit = "player"}, -- Far Sight
        { spell = 207498, types = {"buff","buffShowAlways"}, unit = "player", talent = 12 }, -- Ancestral Protection
        { spell = 73685, types = {"buff","buffShowAlways"}, unit = "player", talent = 3 }, -- Unleash Life
        { spell = 546, types = {"buff","buffShowAlways"}, unit = "player"}, -- Water Walking
        { spell = 157504, types = {"buff","buffShowAlways"}, unit = "player", talent = 18 }, -- Cloudburst Totem
        { spell = 260881, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Spirit Wolf
        { spell = 61295, types = {"buff","buffShowAlways"}, unit = "target"}, -- Riptide
        { spell = 98007, types = {"buff","buffShowAlways"}, unit = "player"}, -- Spirit Link Totem
        { spell = 77762, types = {"buff","buffShowAlways"}, unit = "player"}, -- Lava Surge
        { spell = 207400, types = {"buff","buffShowAlways"}, unit = "target", talent = 10 }, -- Ancestral Vigor
        { spell = 201633, types = {"buff","buffShowAlways"}, unit = "player", talent = 11 }, -- Earthen Wall
        { spell = 73920, types = {"buff","buffShowAlways"}, unit = "player"}, -- Healing Rain
        { spell = 280615, types = {"buff","buffShowAlways"}, unit = "player", talent = 16 }, -- Flash Flood
        { spell = 2645, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ghost Wolf
        { spell = 53390, types = {"buff","buffShowAlways"}, unit = "player"}, -- Tidal Waves
      },
      icon = 252995
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118905, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Static Charge
        { spell = 64695, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 8 }, -- Earthgrab
        { spell = 3600, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Earthbind
        { spell = 188838, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Flame Shock
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 556, types = {"ability","abilityShowAlways"}}, -- Astral Recall
        { spell = 2484, types = {"ability","abilityShowAlways"}}, -- Earthbind Totem
        { spell = 5394, types = {"ability","abilityShowAlways"}}, -- Healing Stream Totem
        { spell = 8143, types = {"ability","abilityShowAlways"}}, -- Tremor Totem
        { spell = 32182, types = {"ability","abilityShowAlways"}}, -- Heroism
        { spell = 51485, types = {"ability","abilityShowAlways"}, talent = 8 }, -- Earthgrab Totem
        { spell = 51505, types = {"ability","abilityShowAlways"}}, -- Lava Burst
        { spell = 51514, types = {"ability","abilityShowAlways"}}, -- Hex
        { spell = 57994, types = {"ability","abilityShowAlways"}}, -- Wind Shear
        { spell = 61295, types = {"ability","abilityShowAlways"}}, -- Riptide
        { spell = 73685, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Unleash Life
        { spell = 73920, types = {"ability","abilityShowAlways"}}, -- Healing Rain
        { spell = 79206, types = {"ability","abilityShowAlways"}}, -- Spiritwalker's Grace
        { spell = 98008, types = {"ability","abilityShowAlways"}}, -- Spirit Link Totem
        { spell = 108271, types = {"ability","abilityShowAlways"}}, -- Astral Shift
        { spell = 108280, types = {"ability","abilityShowAlways"}}, -- Healing Tide Totem
        { spell = 114052, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Ascendance
        { spell = 157153, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Cloudburst Totem
        { spell = 188838, types = {"ability","abilityShowAlways"}}, -- Flame Shock
        { spell = 192058, types = {"ability","abilityShowAlways"}}, -- Capacitor Totem
        { spell = 192077, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Wind Rush Totem
        { spell = 197995, types = {"ability","abilityShowAlways"}, talent = 20 }, -- Wellspring
        { spell = 198103, types = {"ability","abilityShowAlways"}}, -- Earth Elemental
        { spell = 198838, types = {"ability","abilityShowAlways"}, talent = 11 }, -- Earthen Wall Totem
        { spell = 207399, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Ancestral Protection Totem
        { spell = 207778, types = {"ability","abilityShowAlways"}, talent = 17 }, -- Downpour
      },
      icon = 135127
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 263786, types = {"buff","buffShowAlways"}, unit = "player"}, --Astral Shift
        { spell = 263790, types = {"buff","buffShowAlways"}, unit = "player"}, --Ancestral Reach
        { spell = 277942, types = {"buff","buffShowAlways"}, unit = "player"}, --Ancestral Resonance
        { spell = 264113, types = {"buff","buffShowAlways"}, unit = "player"}, --Flames of the Forefathers
        { spell = 278095, types = {"buff","buffShowAlways"}, unit = "group"}, --Overflowing Shores
        { spell = 280205, types = {"buff","buffShowAlways"}, unit = "player"}, --Pack Spirit
        { spell = 279505, types = {"buff","buffShowAlways"}, unit = "group"}, --Spouting Spirits
        { spell = 279187, types = {"buff","buffShowAlways"}, unit = "target"}, --Surging Tides
        { spell = 272981, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Volcanic Lightning
        { spell = 273019, types = {"buff","buffShowAlways"}, unit = "player"}, --Soothing Waters
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 110960, types = {"buff","buffShowAlways"}, unit = "player"}, -- Greater Invisibility
        { spell = 45438, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ice Block
        { spell = 116267, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 1459, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil}, -- Arcane Intellect
        { spell = 212799, types = {"buff","buffShowAlways"}, unit = "player"}, -- Displacement Beacon
        { spell = 210126, types = {"buff","buffShowAlways"}, unit = "player", talent = 3 }, -- Arcane Familiar
        { spell = 236298, types = {"buff","buffShowAlways"}, unit = "player", talent = 13 }, -- Chrono Shift
        { spell = 116014, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Rune of Power
        { spell = 130, types = {"buff","buffShowAlways"}, unit = "player"}, -- Slow Fall
        { spell = 263725, types = {"buff","buffShowAlways"}, unit = "player"}, -- Clearcasting
        { spell = 235450, types = {"buff","buffShowAlways"}, unit = "player"}, -- Prismatic Barrier
        { spell = 12051, types = {"buff","buffShowAlways"}, unit = "player"}, -- Evocation
        { spell = 205025, types = {"buff","buffShowAlways"}, unit = "player"}, -- Presence of Mind
        { spell = 264774, types = {"buff","buffShowAlways"}, unit = "player", talent = 2 }, -- Rule of Threes
        { spell = 12042, types = {"buff","buffShowAlways"}, unit = "player"}, -- Arcane Power

      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 82691, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 114923, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 18 }, -- Nether Tempest
        { spell = 210824, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 17 }, -- Touch of the Magi
        { spell = 236299, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 13 }, -- Chrono Shift
        { spell = 31589, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Slow
        { spell = 122, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Frost Nova
        { spell = 118, types = {"debuff","debuffShowAlways"}, unit = "multi" }, -- Polymorph
      },
      icon = 135848
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 122, types = {"ability","abilityShowAlways"}}, -- Frost Nova
        { spell = 475, types = {"ability","abilityShowAlways"}}, -- Remove Curse
        { spell = 1953, types = {"ability","abilityShowAlways"}}, -- Blink
        { spell = 2139, types = {"ability","abilityShowAlways"}}, -- Counterspell
        { spell = 12042, types = {"ability","abilityShowAlways"}}, -- Arcane Power
        { spell = 12051, types = {"ability","abilityShowAlways"}}, -- Evocation
        { spell = 44425, types = {"ability","abilityShowAlways"}}, -- Arcane Barrage
        { spell = 45438, types = {"ability","abilityShowAlways"}}, -- Ice Block
        { spell = 55342, types = {"ability","abilityShowAlways"}, talent = 8 }, -- Mirror Image
        { spell = 80353, types = {"ability","abilityShowAlways"}}, -- Time Warp
        { spell = 110959, types = {"ability","abilityShowAlways"}}, -- Greater Invisibility
        { spell = 113724, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Ring of Frost
        { spell = 116011, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Rune of Power
        { spell = 153626, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Arcane Orb
        { spell = 157980, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Supernova
        { spell = 190336, types = {"ability","abilityShowAlways"}}, -- Conjure Refreshment
        { spell = 195676, types = {"ability","abilityShowAlways"}}, -- Displacement
        { spell = 205022, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Arcane Familiar
        { spell = 205025, types = {"ability","abilityShowAlways"}}, -- Presence of Mind
        { spell = 205032, types = {"ability","abilityShowAlways"}, talent = 11 }, -- Charged Up
        { spell = 212653, types = {"ability","abilityShowAlways"}, talent = 5 }, -- Shimmer
        { spell = 235450, types = {"ability","abilityShowAlways"}}, -- Prismatic Barrier
      },
      icon = 136075
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 270670, types = {"buff","buffShowAlways"}, unit = "player"}, --Arcane Pumeling
        { spell = 273330, types = {"buff","buffShowAlways"}, unit = "player"}, --Brain Storm
        { spell = 280177, types = {"buff","buffShowAlways"}, unit = "player"}, --Cauterizing Blink
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 236060, types = {"buff","buffShowAlways"}, unit = "player", talent = 13 }, -- Frenetic Speed
        { spell = 116267, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 269651, types = {"buff","buffShowAlways"}, unit = "player", talent = 20 }, -- Pyroclasm
        { spell = 45444, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bonfire's Blessing
        { spell = 48107, types = {"buff","buffShowAlways"}, unit = "player"}, -- Heating Up
        { spell = 116014, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Rune of Power
        { spell = 235313, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blazing Barrier
        { spell = 45438, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ice Block
        { spell = 157644, types = {"buff","buffShowAlways"}, unit = "player"}, -- Enhanced Pyrotechnics
        { spell = 190319, types = {"buff","buffShowAlways"}, unit = "player"}, -- Combustion
        { spell = 66, types = {"buff","buffShowAlways"}, unit = "player"}, -- Invisibility
        { spell = 1459, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Arcane Intellect
        { spell = 130, types = {"buff","buffShowAlways"}, unit = "player"}, -- Slow Fall
        { spell = 48108, types = {"buff","buffShowAlways"}, unit = "player"}, -- Hot Streak!
      },
      icon = 1035045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 31661, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Dragon's Breath
        { spell = 2120, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Flamestrike
        { spell = 155158, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 21 }, -- Meteor Burn
        { spell = 157981, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 6 }, -- Blast Wave
        { spell = 226757, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 17 }, -- Conflagration
        { spell = 217694, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 18 }, -- Living Bomb
        { spell = 12654, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Ignite
        { spell = 82691, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 87023, types = {"debuff","debuffShowAlways"}, unit = "player" }, -- Cauterize
        { spell = 87024, types = {"debuff","debuffShowAlways"}, unit = "player" }, -- Cauterized
        { spell = 118, types = {"debuff","debuffShowAlways"}, unit = "multi" }, -- Polymorph
      },
      icon = 135818
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, types = {"ability","abilityShowAlways"}}, -- Invisibility
        { spell = 475, types = {"ability","abilityShowAlways"}}, -- Remove Curse
        { spell = 1953, types = {"ability","abilityShowAlways"}}, -- Blink
        { spell = 2139, types = {"ability","abilityShowAlways"}}, -- Counterspell
        { spell = 31661, types = {"ability","abilityShowAlways"}}, -- Dragon's Breath
        { spell = 44457, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Living Bomb
        { spell = 45438, types = {"ability","abilityShowAlways"}}, -- Ice Block
        { spell = 55342, types = {"ability","abilityShowAlways"}, talent = 8 }, -- Mirror Image
        { spell = 80353, types = {"ability","abilityShowAlways"}}, -- Time Warp
        { spell = 108853, types = {"ability","abilityShowAlways"}}, -- Fire Blast
        { spell = 113724, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Ring of Frost
        { spell = 116011, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Rune of Power
        { spell = 153561, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Meteor
        { spell = 157981, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Blast Wave
        { spell = 190319, types = {"ability","abilityShowAlways"}}, -- Combustion
        { spell = 190336, types = {"ability","abilityShowAlways"}}, -- Conjure Refreshment
        { spell = 212653, types = {"ability","abilityShowAlways"}, talent = 5 }, -- Shimmer
        { spell = 235313, types = {"ability","abilityShowAlways"}}, -- Blazing Barrier
        { spell = 257541, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Phoenix Flames
      },
      icon = 610633
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 274598, types = {"buff","buffShowAlways"}, unit = "player"}, --Blaster Master
        { spell = 280177, types = {"buff","buffShowAlways"}, unit = "player"}, --Cauterizing Blink
        { spell = 279715, types = {"buff","buffShowAlways"}, unit = "player"}, --Firemind
        { spell = 273333, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Preheat
        { spell = 277703, types = {"debuff","debuffShowAlways"}, unit = "multi"}, --Trailing Embers
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 199844, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Glacial Spike!
        { spell = 45438, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ice Block
        { spell = 66, types = {"buff","buffShowAlways"}, unit = "player"}, -- Invisibility
        { spell = 116267, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 1459, types = {"buff","buffShowAlways"}, unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Arcane Intellect
        { spell = 108839, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Ice Floes
        { spell = 278310, types = {"buff","buffShowAlways"}, unit = "player", talent = 11 }, -- Chain Reaction
        { spell = 12472, types = {"buff","buffShowAlways"}, unit = "player"}, -- Icy Veins
        { spell = 11426, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ice Barrier
        { spell = 130, types = {"buff","buffShowAlways"}, unit = "player"}, -- Slow Fall
        { spell = 205473, types = {"buff","buffShowAlways"}, unit = "player"}, -- Icicles
        { spell = 270232, types = {"buff","buffShowAlways"}, unit = "player", talent = 16 }, -- Freezing Rain
        { spell = 190446, types = {"buff","buffShowAlways"}, unit = "player"}, -- Brain Freeze
        { spell = 116014, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Rune of Power
        { spell = 44544, types = {"buff","buffShowAlways"}, unit = "player"}, -- Fingers of Frost
        { spell = 205766, types = {"buff","buffShowAlways"}, unit = "player", talent = 1 }, -- Bone Chilling
      },
      icon = 236227
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 228354, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Flurry
        { spell = 205708, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Chilled
        { spell = 228600, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 21 }, -- Glacial Spike
        { spell = 157997, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 3 }, -- Ice Nova
        { spell = 228358, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Winter's Chill
        { spell = 205021, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 20 }, -- Ray of Frost
        { spell = 122, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Frost Nova
        { spell = 82691, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 212792, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Cone of Cold
        { spell = 118, types = {"debuff","debuffShowAlways"}, unit = "multi" }, -- Polymorph
      },
      icon = 236208
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, types = {"ability","abilityShowAlways"}}, -- Invisibility
        { spell = 120, types = {"ability","abilityShowAlways"}}, -- Cone of Cold
        { spell = 122, types = {"ability","abilityShowAlways"}}, -- Frost Nova
        { spell = 475, types = {"ability","abilityShowAlways"}}, -- Remove Curse
        { spell = 1953, types = {"ability","abilityShowAlways"}}, -- Blink
        { spell = 2139, types = {"ability","abilityShowAlways"}}, -- Counterspell
        { spell = 11426, types = {"ability","abilityShowAlways"}}, -- Ice Barrier
        { spell = 12472, types = {"ability","abilityShowAlways"}}, -- Icy Veins
        { spell = 30455, types = {"ability","abilityShowAlways"}}, -- Ice Lance
        { spell = 31687, types = {"ability","abilityShowAlways"}}, -- Summon Water Elemental
        { spell = 31707, types = {"ability","abilityShowAlways"}}, -- Waterbolt
        { spell = 45438, types = {"ability","abilityShowAlways"}}, -- Ice Block
        { spell = 55342, types = {"ability","abilityShowAlways"}, talent = 8 }, -- Mirror Image
        { spell = 80353, types = {"ability","abilityShowAlways"}}, -- Time Warp
        { spell = 84714, types = {"ability","abilityShowAlways"}}, -- Frozen Orb
        { spell = 108839, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Ice Floes
        { spell = 113724, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Ring of Frost
        { spell = 116011, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Rune of Power
        { spell = 153595, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Comet Storm
        { spell = 157997, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Ice Nova
        { spell = 190336, types = {"ability","abilityShowAlways"}}, -- Conjure Refreshment
        { spell = 190356, types = {"ability","abilityShowAlways"}}, -- Blizzard
        { spell = 205021, types = {"ability","abilityShowAlways"}, talent = 20 }, -- Ray of Frost
        { spell = 212653, types = {"ability","abilityShowAlways"}, talent = 5 }, -- Shimmer
        { spell = 235219, types = {"ability","abilityShowAlways"}}, -- Cold Snap
        { spell = 257537, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Ebonbolt
      },
      icon = 629077
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280177, types = {"buff","buffShowAlways"}, unit = "player"}, --Cauterizing Blink
        { spell = 279684, types = {"buff","buffShowAlways"}, unit = "player"}, --Frigid Grasp
        { spell = 275517, types = {"buff","buffShowAlways"}, unit = "player"}, --Orbital Precision
        { spell = 277904, types = {"buff","buffShowAlways"}, unit = "player"}, --Tunnel of Ice
        { spell = 273347, types = {"buff","buffShowAlways"}, unit = "player"}, --Winter's Reach
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 196099, types = {"buff","buffShowAlways"}, unit = "player", talent = 18 }, -- Grimoire of Sacrifice
        { spell = 104773, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unending Resolve
        { spell = 126, types = {"buff","buffShowAlways"}, unit = "player"}, -- Eye of Kilrogg
        { spell = 113860, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Dark Soul: Misery
        { spell = 48018, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Demonic Circle
        { spell = 108416, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Dark Pact
        { spell = 6307, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blood Pact
        { spell = 108366, types = {"buff","buffShowAlways"}, unit = "player"}, -- Soul Leech
        { spell = 5697, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unending Breath
        { spell = 264571, types = {"buff","buffShowAlways"}, unit = "player", talent = 1 }, -- Nightfall
        { spell = 111400, types = {"buff","buffShowAlways"}, unit = "player", talent = 8 }, -- Burning Rush
        { spell = 20707, types = {"buff","buffShowAlways"}, unit = "group"}, -- Soulstone
        { spell = 7870, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Lesser Invisibility
        { spell = 112042, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Threatening Presence
        { spell = 17767, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Shadow Bulwark
        { spell = 755, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Health Funnel
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 233490, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Unstable Affliction
        { spell = 27243, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Seed of Corruption
        { spell = 710, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Banish
        { spell = 234153, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Drain Life
        { spell = 6358, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Seduction
        { spell = 30283, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Shadowfury
        { spell = 6789, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 118699, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Fear
        { spell = 198590, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 2 }, -- Drain Soul
        { spell = 17735, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Suffering
        { spell = 6360, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Whiplash
        { spell = 278350, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12 }, -- Vile Taint
        { spell = 1098, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Enslave Demon
        { spell = 48181, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 17 }, -- Haunt
        { spell = 32390, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 16 }, -- Shadow Embrace
        { spell = 146739, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Corruption
        { spell = 205179, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 11 }, -- Phantom Singularity
        { spell = 63106, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 6 }, -- Siphon Life
        { spell = 980, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Agony
      },
      icon = 136139
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 698, types = {"ability","abilityShowAlways"}}, -- Ritual of Summoning
        { spell = 3110, types = {"ability","abilityShowAlways"}}, -- Firebolt
        { spell = 3716, types = {"ability","abilityShowAlways"}}, -- Consuming Shadows
        { spell = 6358, types = {"ability","abilityShowAlways"}}, -- Seduction
        { spell = 6360, types = {"ability","abilityShowAlways"}}, -- Whiplash
        { spell = 6789, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Mortal Coil
        { spell = 7814, types = {"ability","abilityShowAlways"}}, -- Lash of Pain
        { spell = 7870, types = {"ability","abilityShowAlways"}}, -- Lesser Invisibility
        { spell = 17735, types = {"ability","abilityShowAlways"}}, -- Suffering
        { spell = 17767, types = {"ability","abilityShowAlways"}}, -- Shadow Bulwark
        { spell = 19505, types = {"ability","abilityShowAlways"}}, -- Devour Magic
        { spell = 19647, types = {"ability","abilityShowAlways"}}, -- Spell Lock
        { spell = 20707, types = {"ability","abilityShowAlways"}}, -- Soulstone
        { spell = 29893, types = {"ability","abilityShowAlways"}}, -- Create Soulwell
        { spell = 30283, types = {"ability","abilityShowAlways"}}, -- Shadowfury
        { spell = 48018, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Demonic Circle
        { spell = 48020, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Demonic Circle: Teleport
        { spell = 48181, types = {"ability","abilityShowAlways"}, talent = 17 }, -- Haunt
        { spell = 54049, types = {"ability","abilityShowAlways"}}, -- Shadow Bite
        { spell = 89792, types = {"ability","abilityShowAlways"} }, -- Flee
        { spell = 89808, types = {"ability","abilityShowAlways"}}, -- Singe Magic
        { spell = 104773, types = {"ability","abilityShowAlways"}}, -- Unending Resolve
        { spell = 108416, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Dark Pact
        { spell = 108503, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Grimoire of Sacrifice
        { spell = 111771, types = {"ability","abilityShowAlways"}}, -- Demonic Gateway
        { spell = 112042, types = {"ability","abilityShowAlways"}}, -- Threatening Presence
        { spell = 113860, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Dark Soul: Misery
        { spell = 119910, types = {"ability","abilityShowAlways"}}, -- Spell Lock
        { spell = 205179, types = {"ability","abilityShowAlways"}, talent = 11 }, -- Phantom Singularity
        { spell = 205180, types = {"ability","abilityShowAlways"}}, -- Summon Darkglare
        { spell = 264106, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Deathbolt
        { spell = 264993, types = {"ability","abilityShowAlways"}}, -- Shadow Shield
        { spell = 278350, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Vile Taint
      },
      icon = 615103
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275378, types = {"buff","buffShowAlways"}, unit = "player"}, --Cascading Calamity
        { spell = 280208, types = {"buff","buffShowAlways"}, unit = "player"}, --Desperate Power
        { spell = 273525, types = {"buff","buffShowAlways"}, unit = "player"}, --Inevitable Demise
        { spell = 274420, types = {"buff","buffShowAlways"}, unit = "player"}, --Lifeblood
        { spell = 272893, types = {"buff","buffShowAlways"}, unit = "player"}, --Wracking Brilliance
        { spell = 277695, types = {"debuff","debuffShowAlways"}, unit = "multi"}, --Deathbloom
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 104773, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unending Resolve
        { spell = 126, types = {"buff","buffShowAlways"}, unit = "player"}, -- Eye of Kilrogg
        { spell = 267218, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Nether Portal
        { spell = 48018, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Demonic Circle
        { spell = 108416, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Dark Pact
        { spell = 6307, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blood Pact
        { spell = 108366, types = {"buff","buffShowAlways"}, unit = "player"}, -- Soul Leech
        { spell = 205146, types = {"buff","buffShowAlways"}, unit = "player", talent = 4 }, -- Demonic Calling
        { spell = 5697, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unending Breath
        { spell = 265273, types = {"buff","buffShowAlways"}, unit = "player"}, -- Demonic Power
        { spell = 111400, types = {"buff","buffShowAlways"}, unit = "player", talent = 8 }, -- Burning Rush
        { spell = 20707, types = {"buff","buffShowAlways"}, unit = "group"}, -- Soulstone
        { spell = 264173, types = {"buff","buffShowAlways"}, unit = "player"}, -- Demonic Core
        { spell = 134477, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Threatening Presence
        { spell = 30151, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Pursuit
        { spell = 267171, types = {"buff","buffShowAlways"}, unit = "pet", talent = 2 }, -- Demonic Strength
        { spell = 17767, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Shadow Bulwark
        { spell = 89751, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Felstorm
        { spell = 755, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Health Funnel
      },
      icon = 1378284
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 270569, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 10 }, -- From the Shadows
        { spell = 267997, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 3 }, -- Bile Spit
        { spell = 17735, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Suffering
        { spell = 118699, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Fear
        { spell = 30283, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Shadowfury
        { spell = 89766, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Axe Toss
        { spell = 6789, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 234153, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Drain Life
        { spell = 30213, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Legion Strike
        { spell = 6360, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Whiplash
        { spell = 265412, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 6 }, -- Doom
        { spell = 710, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Banish
        { spell = 1098, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Enslave Demon
        { spell = 6358, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Seduction
      },
      icon = 136122
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 698, types = {"ability","abilityShowAlways"}}, -- Ritual of Summoning
        { spell = 3716, types = {"ability","abilityShowAlways"}}, -- Consuming Shadows
        { spell = 6360, types = {"ability","abilityShowAlways"}}, -- Whiplash
        { spell = 6789, types = {"ability","abilityShowAlways"}, talent = 14 }, -- Mortal Coil
        { spell = 7814, types = {"ability","abilityShowAlways"}}, -- Lash of Pain
        { spell = 7870, types = {"ability","abilityShowAlways"}}, -- Lesser Invisibility
        { spell = 17735, types = {"ability","abilityShowAlways"}}, -- Suffering
        { spell = 17767, types = {"ability","abilityShowAlways"}}, -- Shadow Bulwark
        { spell = 19505, types = {"ability","abilityShowAlways"}}, -- Devour Magic
        { spell = 19647, types = {"ability","abilityShowAlways"}}, -- Spell Lock
        { spell = 20707, types = {"ability","abilityShowAlways"}}, -- Soulstone
        { spell = 29893, types = {"ability","abilityShowAlways"}}, -- Create Soulwell
        { spell = 30151, types = {"ability","abilityShowAlways"}}, -- Pursuit
        { spell = 30213, types = {"ability","abilityShowAlways"}}, -- Legion Strike
        { spell = 30283, types = {"ability","abilityShowAlways"}}, -- Shadowfury
        { spell = 48018, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Demonic Circle
        { spell = 48020, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Demonic Circle: Teleport
        { spell = 54049, types = {"ability","abilityShowAlways"}}, -- Shadow Bite
        { spell = 89751, types = {"ability","abilityShowAlways"}}, -- Felstorm
        { spell = 89766, types = {"ability","abilityShowAlways"}}, -- Axe Toss
        { spell = 89792, types = {"ability","abilityShowAlways"}}, -- Flee
        { spell = 89808, types = {"ability","abilityShowAlways"}}, -- Singe Magic
        { spell = 104316, types = {"ability","abilityShowAlways"}}, -- Call Dreadstalkers
        { spell = 104773, types = {"ability","abilityShowAlways"}}, -- Unending Resolve
        { spell = 108416, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Dark Pact
        { spell = 111771, types = {"ability","abilityShowAlways"}}, -- Demonic Gateway
        { spell = 111898, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Grimoire: Felguard
        { spell = 112042, types = {"ability","abilityShowAlways"}}, -- Threatening Presence
        { spell = 264057, types = {"ability","abilityShowAlways"}, talent = 11 }, -- Soul Strike
        { spell = 264119, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Summon Vilefiend
        { spell = 264130, types = {"ability","abilityShowAlways"}, talent = 5 }, -- Power Siphon
        { spell = 264993, types = {"ability","abilityShowAlways"}}, -- Shadow Shield
        { spell = 265187, types = {"ability","abilityShowAlways"}}, -- Summon Demonic Tyrant
        { spell = 267171, types = {"ability","abilityShowAlways"}, talent = 2 }, -- Demonic Strength
        { spell = 267211, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Bilescourge Bombers
        { spell = 267217, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Nether Portal
        { spell = 6358, types = {"ability","abilityShowAlways"}}, -- Seduction
      },
      icon = 1378282
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280208, types = {"buff","buffShowAlways"}, unit = "player"}, --Desperate Power
        { spell = 276027, types = {"buff","buffShowAlways"}, unit = "player"}, --Excoriate
        { spell = 275398, types = {"buff","buffShowAlways"}, unit = "player"}, --Explosive Potential
        { spell = 274420, types = {"buff","buffShowAlways"}, unit = "player"}, --Lifeblood
        { spell = 272945, types = {"buff","buffShowAlways"}, unit = "player"}, --Shadow's Bite
        { spell = 279885, types = {"buff","buffShowAlways"}, unit = "player"}, --Supreme Commander
        { spell = 273526, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Umbral Blaze
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 104773, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unending Resolve
        { spell = 126, types = {"buff","buffShowAlways"}, unit = "player"}, -- Eye of Kilrogg
        { spell = 113858, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Dark Soul: Instability
        { spell = 196099, types = {"buff","buffShowAlways"}, unit = "player", talent = 18 }, -- Grimoire of Sacrifice
        { spell = 6307, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blood Pact
        { spell = 266091, types = {"buff","buffShowAlways"}, unit = "player", talent = 17 }, -- Grimoire of Supremacy
        { spell = 108366, types = {"buff","buffShowAlways"}, unit = "player"}, -- Soul Leech
        { spell = 266030, types = {"buff","buffShowAlways"}, unit = "player", talent = 4 }, -- Reverse Entropy
        { spell = 5697, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unending Breath
        { spell = 48018, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Demonic Circle
        { spell = 111400, types = {"buff","buffShowAlways"}, unit = "player", talent = 8 }, -- Burning Rush
        { spell = 20707, types = {"buff","buffShowAlways"}, unit = "group"}, -- Soulstone
        { spell = 108416, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Dark Pact
        { spell = 117828, types = {"buff","buffShowAlways"}, unit = "player"}, -- Backdraft
        { spell = 7870, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Lesser Invisibility
        { spell = 112042, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Threatening Presence
        { spell = 17767, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Shadow Bulwark
        { spell = 108366, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Soul Leech
        { spell = 755, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Health Funnel
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 157736, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Immolate
        { spell = 22703, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Infernal Awakening
        { spell = 265931, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Conflagrate
        { spell = 17735, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Suffering
        { spell = 118699, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Fear
        { spell = 80240, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Havoc
        { spell = 6789, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 196414, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 2 }, -- Eradication
        { spell = 234153, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Drain Life
        { spell = 6360, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Whiplash
        { spell = 30283, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Shadowfury
        { spell = 710, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Banish
        { spell = 1098, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Enslave Demon
        { spell = 6358, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Seduction

      },
      icon = 135817
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 698, types = {"ability","abilityShowAlways"}}, -- Ritual of Summoning
        { spell = 1122, types = {"ability","abilityShowAlways"}}, -- Summon Infernal
        { spell = 3110, types = {"ability","abilityShowAlways"}}, -- Firebolt
        { spell = 3716, types = {"ability","abilityShowAlways"}}, -- Consuming Shadows
        { spell = 6353, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Soul Fire
        { spell = 6360, types = {"ability","abilityShowAlways"}}, -- Whiplash
        { spell = 6789, types = {"ability","abilityShowAlways"}, talent = 14 }, -- Mortal Coil
        { spell = 7814, types = {"ability","abilityShowAlways"}}, -- Lash of Pain
        { spell = 7870, types = {"ability","abilityShowAlways"}}, -- Lesser Invisibility
        { spell = 17735, types = {"ability","abilityShowAlways"}}, -- Suffering
        { spell = 17767, types = {"ability","abilityShowAlways"}}, -- Shadow Bulwark
        { spell = 17877, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Shadowburn
        { spell = 17962, types = {"ability","abilityShowAlways"}}, -- Conflagrate
        { spell = 19647, types = {"ability","abilityShowAlways"}}, -- Spell Lock
        { spell = 20707, types = {"ability","abilityShowAlways"}}, -- Soulstone
        { spell = 29893, types = {"ability","abilityShowAlways"}}, -- Create Soulwell
        { spell = 30283, types = {"ability","abilityShowAlways"}}, -- Shadowfury
        { spell = 48018, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Demonic Circle
        { spell = 48020, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Demonic Circle: Teleport
        { spell = 54049, types = {"ability","abilityShowAlways"}}, -- Shadow Bite
        { spell = 80240, types = {"ability","abilityShowAlways"}}, -- Havoc
        { spell = 89792, types = {"ability","abilityShowAlways"}}, -- Flee
        { spell = 89808, types = {"ability","abilityShowAlways"}}, -- Singe Magic
        { spell = 104773, types = {"ability","abilityShowAlways"}}, -- Unending Resolve
        { spell = 108416, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Dark Pact
        { spell = 108503, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Grimoire of Sacrifice
        { spell = 111771, types = {"ability","abilityShowAlways"}}, -- Demonic Gateway
        { spell = 112042, types = {"ability","abilityShowAlways"}}, -- Threatening Presence
        { spell = 113858, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Dark Soul: Instability
        { spell = 152108, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Cataclysm
        { spell = 196447, types = {"ability","abilityShowAlways"}, talent = 20 }, -- Channel Demonfire
        { spell = 264993, types = {"ability","abilityShowAlways"}}, -- Shadow Shield
        { spell = 6358, types = {"ability","abilityShowAlways"}}, -- Seduction
      },
      icon = 135807
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272957, types = {"buff","buffShowAlways"}, unit = "player"}, --Accelerant
        { spell = 279913, types = {"buff","buffShowAlways"}, unit = "player"}, --Bursting Flare
        { spell = 279673, types = {"buff","buffShowAlways"}, unit = "player"}, --Chaotic Inferno
        { spell = 280208, types = {"buff","buffShowAlways"}, unit = "player"}, --Desperate Power
        { spell = 275429, types = {"buff","buffShowAlways"}, unit = "player"}, --Flashpoint
        { spell = 274420, types = {"buff","buffShowAlways"}, unit = "player"}, --Lifeblood
        { spell = 278931, types = {"buff","buffShowAlways"}, unit = "player"}, --Rolling Havoc
        { spell = 277706, types = {"buff","buffShowAlways"}, unit = "player"}, --Crashing Chaos
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 116847, types = {"buff","buffShowAlways"}, unit = "player", talent = 17 }, -- Rushing Jade Wind
        { spell = 122278, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 119085, types = {"buff","buffShowAlways"}, unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 195630, types = {"buff","buffShowAlways"}, unit = "player"}, -- Elusive Brawler
        { spell = 228563, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Blackout Combo
        { spell = 215479, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ironskin Brew
        { spell = 115176, types = {"buff","buffShowAlways"}, unit = "player"}, -- Zen Meditation
        { spell = 115295, types = {"buff","buffShowAlways"}, unit = "player", talent = 20 }, -- Guard
        { spell = 116841, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 120954, types = {"buff","buffShowAlways"}, unit = "player"}, -- Fortifying Brew
        { spell = 196608, types = {"buff","buffShowAlways"}, unit = "player", talent = 1 }, -- Eye of the Tiger
        { spell = 101643, types = {"buff","buffShowAlways"}, unit = "player"}, -- Transcendence
        { spell = 2479, types = {"buff","buffShowAlways"}, unit = "player"}, -- Honorless Target

      },
      icon = 613398
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 119381, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Leg Sweep
        { spell = 196608, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 1 }, -- Eye of the Tiger
        { spell = 113746, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mystic Touch
        { spell = 115078, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Paralysis
        { spell = 117952, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Crackling Jade Lightning
        { spell = 121253, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Keg Smash
        { spell = 116189, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Provoke
        { spell = 124273, types = {"debuff","debuffShowAlways"}, unit = "player" }, -- Heavy Stagger
        { spell = 124274, types = {"debuff","debuffShowAlways"}, unit = "player" }, -- Moderate Stagger
        { spell = 124275, types = {"debuff","debuffShowAlways"}, unit = "player" }, -- Light Stagger
      },
      icon = 611419
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 101643, types = {"ability","abilityShowAlways"}}, -- Transcendence
        { spell = 107079, types = {"ability","abilityShowAlways"}}, -- Quaking Palm
        { spell = 109132, types = {"ability","abilityCharge"}}, -- Roll
        { spell = 115008, types = {"ability","abilityCharge"}, talent = 5 }, -- Chi Torpedo
        { spell = 115078, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Paralysis
        { spell = 115098, types = {"ability","abilityShowAlways"}, talent = 2 }, -- Chi Wave
        { spell = 115176, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Zen Meditation
        { spell = 115181, types = {"ability","abilityShowAlways"}}, -- Breath of Fire
        { spell = 115203, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Fortifying Brew
        { spell = 115295, types = {"ability","abilityShowAlways"}, talent = 20 }, -- Guard
        { spell = 115308, types = {"ability","abilityCharge","abilityChargeBuff"}}, -- Ironskin Brew
        { spell = 115315, types = {"ability","abilityShowAlways"}, talent = 11 }, -- Summon Black Ox Statue
        { spell = 115399, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Black Ox Brew
        { spell = 115546, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Provoke
        { spell = 116705, types = {"ability","abilityShowAlways"}}, -- Spear Hand Strike
        { spell = 116841, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Tiger's Lust
        { spell = 116844, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Ring of Peace
        { spell = 116847, types = {"ability","abilityShowAlways"}, talent = 17 }, -- Rushing Jade Wind
        { spell = 119381, types = {"ability","abilityShowAlways"}}, -- Leg Sweep
        { spell = 119582, types = {"ability","abilityCharge"}}, -- Purifying Brew
        { spell = 119996, types = {"ability","abilityShowAlways"}}, -- Transcendence: Transfer
        { spell = 121253, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Keg Smash
        { spell = 122278, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 15 }, -- Dampen Harm
        { spell = 122281, types = {"ability","abilityCharge","abilityChargeBuff"}, talent = 14 }, -- Healing Elixir
        { spell = 123986, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Chi Burst
        { spell = 126892, types = {"ability","abilityShowAlways"}}, -- Zen Pilgrimage
        { spell = 132578, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Invoke Niuzao, the Black Ox
        { spell = 205523, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Blackout Strike

      },
      icon = 133701
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275893, types = {"buff","buffShowAlways"}, unit = "player"}, --Fit to Burst
        { spell = 278535, types = {"buff","buffShowAlways"}, unit = "player"}, --Niuzao's Blessing
        { spell = 273469, types = {"buff","buffShowAlways"}, unit = "player"}, --Staggering Strikes
        { spell = 274774, types = {"buff","buffShowAlways"}, unit = "player"}, --Strength of Spirit
        { spell = 280187, types = {"buff","buffShowAlways"}, unit = "player"}, --Sweep the Leg
        { spell = 278767, types = {"buff","buffShowAlways"}, unit = "player"}, --Training of Niuzao
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 119611, types = {"buff","buffShowAlways"}, unit = "target"}, -- Renewing Mist
        { spell = 196725, types = {"buff","buffShowAlways"}, unit = "player", talent = 17 }, -- Refreshing Jade Wind
        { spell = 122783, types = {"buff","buffShowAlways"}, unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 116680, types = {"buff","buffShowAlways"}, unit = "player"}, -- Thunder Focus Tea
        { spell = 243435, types = {"buff","buffShowAlways"}, unit = "player"}, -- Fortifying Brew
        { spell = 124682, types = {"buff","buffShowAlways"}, unit = "target"}, -- Enveloping Mist
        { spell = 116841, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 197908, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Mana Tea
        { spell = 191840, types = {"buff","buffShowAlways"}, unit = "player"}, -- Essence Font
        { spell = 115175, types = {"buff","buffShowAlways"}, unit = "target"}, -- Soothing Mist
        { spell = 119085, types = {"buff","buffShowAlways"}, unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 202090, types = {"buff","buffShowAlways"}, unit = "player"}, -- Teachings of the Monastery
        { spell = 122278, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 197919, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Lifecycles (Enveloping Mist)
        { spell = 116849, types = {"buff","buffShowAlways"}, unit = "target"}, -- Life Cocoon
        { spell = 101643, types = {"buff","buffShowAlways"}, unit = "player"}, -- Transcendence
        { spell = 197916, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Lifecycles (Vivify)

      },
      icon = 627487
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 119381, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Leg Sweep
        { spell = 115078, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Paralysis
        { spell = 117952, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Crackling Jade Lightning
        { spell = 116189, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Provoke
        { spell = 113746, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mystic Touch
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100784, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Blackout Kick
        { spell = 101643, types = {"ability","abilityShowAlways"}}, -- Transcendence
        { spell = 107079, types = {"ability","abilityShowAlways"}}, -- Quaking Palm
        { spell = 107428, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Rising Sun Kick
        { spell = 109132, types = {"ability","abilityCharge"}}, -- Roll
        { spell = 115008, types = {"ability","abilityCharge"}, talent = 5 }, -- Chi Torpedo
        { spell = 115078, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Paralysis
        { spell = 115098, types = {"ability","abilityShowAlways"}, talent = 2 }, -- Chi Wave
        { spell = 115151, types = {"ability","abilityCharge"}}, -- Renewing Mist
        { spell = 115310, types = {"ability","abilityShowAlways"}}, -- Revival
        { spell = 115313, types = {"ability","abilityShowAlways"}, talent = 16 }, -- Summon Jade Serpent Statue
        { spell = 115546, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Provoke
        { spell = 116680, types = {"ability","abilityShowAlways"}}, -- Thunder Focus Tea                    -- add talent = 19 abilityChargeBuff
        { spell = 116841, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Tiger's Lust
        { spell = 116844, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Ring of Peace
        { spell = 116849, types = {"ability","abilityShowAlways"}}, -- Life Cocoon
        { spell = 119381, types = {"ability","abilityShowAlways"}}, -- Leg Sweep
        { spell = 119996, types = {"ability","abilityShowAlways"}}, -- Transcendence: Transfer
        { spell = 122278, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 15 }, -- Dampen Harm
        { spell = 122281, types = {"ability","abilityCharge","abilityChargeBuff"}, talent = 13 }, -- Healing Elixir
        { spell = 122783, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 14 }, -- Diffuse Magic
        { spell = 123986, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Chi Burst
        { spell = 126892, types = {"ability","abilityShowAlways"}}, -- Zen Pilgrimage
        { spell = 191837, types = {"ability","abilityShowAlways"}}, -- Essence Font
        { spell = 196725, types = {"ability","abilityShowAlways"}, talent = 17 }, -- Refreshing Jade Wind
        { spell = 197908, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 9 }, -- Mana Tea
        { spell = 198664, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Invoke Chi-Ji, the Red Crane
        { spell = 198898, types = {"ability","abilityShowAlways"}, talent = 11 }, -- Song of Chi-Ji
        { spell = 243435, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Fortifying Brew
      },
      icon = 627485
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 276025, types = {"buff","buffShowAlways"}, unit = "player"}, --Misty Peaks
        { spell = 273348, types = {"buff","buffShowAlways"}, unit = "target"}, --Overflowing Mists
        { spell = 274774, types = {"buff","buffShowAlways"}, unit = "player"}, --Strength of Spirit
        { spell = 273299, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Sunrise Technique
        { spell = 280187, types = {"buff","buffShowAlways"}, unit = "player"}, --Sweep the Leg
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 122278, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 125174, types = {"buff","buffShowAlways"}, unit = "player"}, -- Touch of Karma
        { spell = 119085, types = {"buff","buffShowAlways"}, unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 152173, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Serenity
        { spell = 261715, types = {"buff","buffShowAlways"}, unit = "player", talent = 17 }, -- Rushing Jade Wind
        { spell = 101643, types = {"buff","buffShowAlways"}, unit = "player"}, -- Transcendence
        { spell = 261769, types = {"buff","buffShowAlways"}, unit = "player", talent = 13 }, -- Inner Strength
        { spell = 116841, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 122783, types = {"buff","buffShowAlways"}, unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 137639, types = {"buff","buffShowAlways"}, unit = "player"}, -- Storm, Earth, and Fire
        { spell = 196741, types = {"buff","buffShowAlways"}, unit = "player", talent = 16 }, -- Hit Combo
        { spell = 196608, types = {"buff","buffShowAlways"}, unit = "player", talent = 1 }, -- Eye of the Tiger
        { spell = 166646, types = {"buff","buffShowAlways"}, unit = "player" }, -- Windwalking
        { spell = 116768, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blackout Kick!
      },
      icon = 611420
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115078, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Paralysis
        { spell = 116189, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Provoke
        { spell = 115080, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Touch of Death
        { spell = 113746, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mystic Touch
        { spell = 228287, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mark of the Crane
        { spell = 115804, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Mortal Wounds
        { spell = 116706, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Disable
        { spell = 117952, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Crackling Jade Lightning
        { spell = 196608, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 1 }, -- Eye of the Tiger
        { spell = 122470, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Touch of Karma
        { spell = 119381, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Leg Sweep
        { spell = 123586, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Flying Serpent Kick

      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100784, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Blackout Kick
        { spell = 101545, types = {"ability","abilityShowAlways"}}, -- Flying Serpent Kick
        { spell = 101546, types = {"ability","abilityShowAlways"}}, -- Spinning Crane Kick
        { spell = 101643, types = {"ability","abilityShowAlways"}}, -- Transcendence
        { spell = 107428, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Rising Sun Kick
        { spell = 109132, types = {"ability","abilityCharge"}}, -- Roll
        { spell = 113656, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Fists of Fury
        { spell = 115008, types = {"ability","abilityCharge"}, talent = 5 }, -- Chi Torpedo
        { spell = 115078, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Paralysis
        { spell = 115080, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Touch of Death
        { spell = 115098, types = {"ability","abilityShowAlways"}, talent = 2 }, -- Chi Wave
        { spell = 115288, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Energizing Elixir
        { spell = 115546, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Provoke
        { spell = 116705, types = {"ability","abilityShowAlways"}}, -- Spear Hand Strike
        { spell = 116841, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Tiger's Lust
        { spell = 116844, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Ring of Peace
        { spell = 119381, types = {"ability","abilityShowAlways"}}, -- Leg Sweep
        { spell = 119996, types = {"ability","abilityShowAlways"}}, -- Transcendence: Transfer
        { spell = 122278, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Dampen Harm
        { spell = 122470, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Touch of Karma
        { spell = 122783, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 14 }, -- Diffuse Magic
        { spell = 123904, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Invoke Xuen, the White Tiger
        { spell = 123986, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Chi Burst
        { spell = 126892, types = {"ability","abilityShowAlways"}}, -- Zen Pilgrimage
        { spell = 137639, types = {"ability","abilityShowAlways","abilityChargeBuff"}}, -- Storm, Earth, and Fire
        { spell = 152173, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 21 }, -- Serenity
        { spell = 152175, types = {"ability","abilityUsable"}, talent = 20 }, -- Whirling Dragon Punch
        { spell = 261715, types = {"ability","abilityShowAlways"}, talent = 17 }, -- Rushing Jade Wind
        { spell = 261947, types = {"ability","abilityShowAlways"}, talent = 8 }, -- Fist of the White Tiger
      },
      icon = 627606
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272806, types = {"buff","buffShowAlways"}, unit = "player"}, --Iron Fists
        { spell = 279922, types = {"buff","buffShowAlways"}, unit = "player"}, --Open Palm Strikes
        { spell = 273299, types = {"debuff","debuffShowAlways"}, unit = "target"}, --Sunrise Technique
        { spell = 278710, types = {"buff","buffShowAlways"}, unit = "player"}, --Swift Roundhouse
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 279709, types = {"buff","buffShowAlways"}, unit = "player", talent = 14 }, -- Starlord
        { spell = 22842, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Frenzied Regeneration
        { spell = 24858, types = {"buff","buffShowAlways"}, unit = "player"}, -- Moonkin Form
        { spell = 774, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 202425, types = {"buff","buffShowAlways"}, unit = "player", talent = 2 }, -- Warrior of Elune
        { spell = 164547, types = {"buff","buffShowAlways"}, unit = "player"}, -- Lunar Empowerment
        { spell = 5487, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bear Form
        { spell = 8936, types = {"buff","buffShowAlways"}, unit = "player"}, -- Regrowth
        { spell = 252216, types = {"buff","buffShowAlways"}, unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 194223, types = {"buff","buffShowAlways"}, unit = "player"}, -- Celestial Alignment
        { spell = 191034, types = {"buff","buffShowAlways"}, unit = "player"}, -- Starfall
        { spell = 102560, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Incarnation: Chosen of Elune
        { spell = 164545, types = {"buff","buffShowAlways"}, unit = "player"}, -- Solar Empowerment
        { spell = 783, types = {"buff","buffShowAlways"}, unit = "player"}, -- Travel Form
        { spell = 768, types = {"buff","buffShowAlways"}, unit = "player"}, -- Cat Form
        { spell = 202461, types = {"buff","buffShowAlways"}, unit = "player", talent = 18 }, -- Stellar Drift
        { spell = 48438, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Wild Growth
        { spell = 192081, types = {"buff","buffShowAlways"}, unit = "player", talent = 8 }, -- Ironfur
        { spell = 22812, types = {"buff","buffShowAlways"}, unit = "player"}, -- Barkskin
        { spell = 1850, types = {"buff","buffShowAlways"}, unit = "player"}, -- Dash
        { spell = 5215, types = {"buff","buffShowAlways"}, unit = "player"}, -- Prowl
        { spell = 29166, types = {"buff","buffShowAlways"}, unit = "group"}, -- Innervate
      },
      icon = 535045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 155722, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 7 }, -- Rake
        { spell = 205644, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 3 }, -- Force of Nature
        { spell = 102359, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 339, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Entangling Roots
        { spell = 5211, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 1079, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 7 }, -- Rip
        { spell = 164815, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Sunfire
        { spell = 202347, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 18 }, -- Stellar Flare
        { spell = 61391, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12 }, -- Typhoon
        { spell = 192090, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 8 }, -- Thrash
        { spell = 164812, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Moonfire
        { spell = 6795, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Growl
        { spell = 81261, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Solar Beam
        { spell = 2637, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Hibernate
      },
      icon = 236216
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 768, types = {"ability","abilityShowAlways"}}, -- Cat Form
        { spell = 783, types = {"ability","abilityShowAlways"}}, -- Travel Form
        { spell = 1850, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Dash
        { spell = 2782, types = {"ability","abilityShowAlways"}}, -- Remove Corruption
        { spell = 2908, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Soothe
        { spell = 5211, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Mighty Bash
        { spell = 5215, types = {"ability","abilityShowAlways"}}, -- Prowl
        { spell = 5487, types = {"ability","abilityShowAlways"}}, -- Bear Form
        { spell = 6795, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Growl
        { spell = 16979, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 18562, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Swiftmend
        { spell = 20484, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Rebirth
        { spell = 22812, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Barkskin
        { spell = 22842, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 8 }, -- Frenzied Regeneration
        { spell = 24858, types = {"ability","abilityShowAlways"}}, -- Moonkin Form
        { spell = 29166, types = {"ability","abilityShowAlways"}}, -- Innervate
        { spell = 33917, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Mangle
        { spell = 48438, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Wild Growth
        { spell = 49376, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 77758, types = {"ability","abilityShowAlways"}, talent = 8 }, -- Thrash
        { spell = 78675, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Solar Beam
        { spell = 102359, types = {"ability","abilityShowAlways"}, talent = 11 }, -- Mass Entanglement
        { spell = 102383, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 102401, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 102560, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 15 }, -- Incarnation: Chosen of Elune
        { spell = 108238, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Renewal
        { spell = 132469, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Typhoon
        { spell = 192081, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 8 }, -- Ironfur
        { spell = 190984, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Solar Wrath                -- these two
        { spell = 194153, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Lunar Strike               -- doesn't have a cooldown
        { spell = 194223, types = {"ability","abilityShowAlways"}}, -- Celestial Alignment
        { spell = 202425, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 2 }, -- Warrior of Elune
        { spell = 202770, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 20 }, -- Fury of Elune
        { spell = 205636, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Force of Nature
        { spell = 252216, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 4 }, -- Tiger Dash
        { spell = 274281, types = {"ability","abilityChargeTarget"}, talent = 21 }, -- New Moon
        { spell = 274282, types = {"ability","abilityChargeTarget"}, talent = 21 }, -- Half Moon
        { spell = 274283, types = {"ability","abilityChargeTarget"}, talent = 21 }, -- Full Moon
      },
      icon = 136060
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 276154, types = {"buff","buffShowAlways"}, unit = "player"}, --Dawning Sun
        { spell = 279648, types = {"buff","buffShowAlways"}, unit = "player"}, --Lively Spirit
        { spell = 269380, types = {"buff","buffShowAlways"}, unit = "player"}, --Long Night
        { spell = 274814, types = {"buff","buffShowAlways"}, unit = "player"}, --Reawakening
        { spell = 272871, types = {"buff","buffShowAlways"}, unit = "player"}, --Streaking Stars
        { spell = 274399, types = {"buff","buffShowAlways"}, unit = "player"}, --Sunblaze
        { spell = 280165, types = {"buff","buffShowAlways"}, unit = "player"}, --Ursoc's Endurance
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 106951, types = {"buff","buffShowAlways"}, unit = "player"}, -- Berserk
        { spell = 61336, types = {"buff","buffShowAlways"}, unit = "player"}, -- Survival Instincts
        { spell = 22842, types = {"buff","buffShowAlways"}, unit = "player", talent = 8 }, -- Frenzied Regeneration
        { spell = 5215, types = {"buff","buffShowAlways"}, unit = "player"}, -- Prowl
        { spell = 774, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 164547, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 5487, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bear Form
        { spell = 8936, types = {"buff","buffShowAlways"}, unit = "player"}, -- Regrowth
        { spell = 145152, types = {"buff","buffShowAlways"}, unit = "player", talent = 20 }, -- Bloodtalons
        { spell = 252216, types = {"buff","buffShowAlways"}, unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 52610, types = {"buff","buffShowAlways"}, unit = "player", talent = 18 }, -- Savage Roar
        { spell = 48438, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Wild Growth
        { spell = 106898, types = {"buff","buffShowAlways"}, unit = "player"}, -- Stampeding Roar
        { spell = 5217, types = {"buff","buffShowAlways"}, unit = "player"}, -- Tiger's Fury
        { spell = 252071, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Jungle Stalker
        { spell = 164545, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 783, types = {"buff","buffShowAlways"}, unit = "player"}, -- Travel Form
        { spell = 768, types = {"buff","buffShowAlways"}, unit = "player"}, -- Cat Form
        { spell = 69369, types = {"buff","buffShowAlways"}, unit = "player"}, -- Predatory Swiftness
        { spell = 135700, types = {"buff","buffShowAlways"}, unit = "player"}, -- Clearcasting
        { spell = 102543, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Incarnation: King of the Jungle
        { spell = 192081, types = {"buff","buffShowAlways"}, unit = "player", talent = 8 }, -- Ironfur
        { spell = 1850, types = {"buff","buffShowAlways"}, unit = "player"}, -- Dash
        { spell = 197625, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Moonkin Form
      },
      icon = 136170
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 164812, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Moonfire
        { spell = 102359, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 106830, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Thrash
        { spell = 339, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Entangling Roots
        { spell = 274838, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 21 }, -- Feral Frenzy
        { spell = 58180, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Infected Wounds
        { spell = 1079, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Rip
        { spell = 164815, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 7 }, -- Sunfire
        { spell = 61391, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12 }, -- Typhoon
        { spell = 5211, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 155625, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 7 }, -- Moonfire
        { spell = 203123, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Maim
        { spell = 6795, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Growl
        { spell = 155722, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Rake
        { spell = 2637, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Hibernate
      },
      icon = 132152
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 768, types = {"ability","abilityShowAlways"}}, -- Cat Form
        { spell = 783, types = {"ability","abilityShowAlways"}}, -- Travel Form
        { spell = 1850, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Dash
        { spell = 2782, types = {"ability","abilityShowAlways"}}, -- Remove Corruption
        { spell = 2908, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Soothe
        { spell = 5211, types = {"ability","abilityShowAlways"}, talent = 10 }, -- Mighty Bash
        { spell = 5215, types = {"ability","abilityShowAlways"}}, -- Prowl
        { spell = 5217, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Tiger's Fury
        { spell = 5487, types = {"ability","abilityShowAlways"}}, -- Bear Form
        { spell = 6795, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Growl
        { spell = 16979, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 18562, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Swiftmend
        { spell = 20484, types = {"ability","abilityShowAlways"}}, -- Rebirth
        { spell = 22570, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Maim
        { spell = 22842, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 8 }, -- Frenzied Regeneration
        { spell = 33917, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Mangle
        { spell = 48438, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Wild Growth
        { spell = 49376, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 61336, types = {"ability","abilityCharge","abilityChargeBuff"}}, -- Survival Instincts
        { spell = 77758, types = {"ability","abilityShowAlways"}}, -- Thrash
        { spell = 102359, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 11 }, -- Mass Entanglement
        { spell = 102401, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 102543, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 15 }, -- Incarnation: King of the Jungle
        { spell = 106839, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Skull Bash
        { spell = 106898, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Stampeding Roar
        { spell = 106951, types = {"ability","abilityShowAlways"}}, -- Berserk
        { spell = 108238, types = {"ability","abilityShowAlways"}, talent = 5 }, -- Renewal
        { spell = 132469, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Typhoon
        { spell = 192081, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 8 }, -- Ironfur
        { spell = 197625, types = {"ability","abilityShowAlways"}, talent = 7 }, -- Moonkin Form
        { spell = 197626, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 7 }, -- Starsurge
        { spell = 202028, types = {"ability","abilityCharge"}, talent = 17 }, -- Brutal Slash
        { spell = 252216, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 4 }, -- Tiger Dash
        { spell = 274837, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 21 }, -- Feral Frenzy
      },
      icon = 236149
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 276026, types = {"buff","buffShowAlways"}, unit = "player"}, --Iron Jaws
        { spell = 272753, types = {"buff","buffShowAlways"}, unit = "player"}, --Primordial Rage
        { spell = 273340, types = {"buff","buffShowAlways"}, unit = "player"}, --Raking Ferocity
        { spell = 274814, types = {"buff","buffShowAlways"}, unit = "player"}, --Reawakening
        { spell = 274426, types = {"buff","buffShowAlways"}, unit = "player"}, --Shredding Fury
        { spell = 280165, types = {"buff","buffShowAlways"}, unit = "player"}, --Ursoc's Endurance
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 155835, types = {"buff","buffShowAlways"}, unit = "player", talent = 3 }, -- Bristling Fur
        { spell = 61336, types = {"buff","buffShowAlways"}, unit = "player"}, -- Survival Instincts
        { spell = 22842, types = {"buff","buffShowAlways"}, unit = "player"}, -- Frenzied Regeneration
        { spell = 5215, types = {"buff","buffShowAlways"}, unit = "player"}, -- Prowl
        { spell = 774, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 203975, types = {"buff","buffShowAlways"}, unit = "player", talent = 16 }, -- Earthwarden
        { spell = 164547, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 5487, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bear Form
        { spell = 8936, types = {"buff","buffShowAlways"}, unit = "player"}, -- Regrowth
        { spell = 93622, types = {"buff","buffShowAlways"}, unit = "player"}, -- Gore
        { spell = 158792, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Pulverize
        { spell = 213680, types = {"buff","buffShowAlways"}, unit = "player", talent = 18 }, -- Guardian of Elune
        { spell = 102558, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Incarnation: Guardian of Ursoc
        { spell = 213708, types = {"buff","buffShowAlways"}, unit = "player", talent = 14 }, -- Galactic Guardian
        { spell = 48438, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Wild Growth
        { spell = 77764, types = {"buff","buffShowAlways"}, unit = "player"}, -- Stampeding Roar
        { spell = 783, types = {"buff","buffShowAlways"}, unit = "player"}, -- Travel Form
        { spell = 192081, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ironfur
        { spell = 164545, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 197625, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 252216, types = {"buff","buffShowAlways"}, unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 22812, types = {"buff","buffShowAlways"}, unit = "player"}, -- Barkskin
        { spell = 1850, types = {"buff","buffShowAlways"}, unit = "player"}, -- Dash
        { spell = 768, types = {"buff","buffShowAlways"}, unit = "player"}, -- Cat Form
      },
      icon = 1378702
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 164812, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Moonfire
        { spell = 102359, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 339, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Entangling Roots
        { spell = 5211, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 61391, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12 }, -- Typhoon
        { spell = 1079, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 8 }, -- Rip
        { spell = 164815, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 7 }, -- Sunfire
        { spell = 45334, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 6 }, -- Immobilized
        { spell = 155722, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 8 }, -- Rake
        { spell = 99, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Incapacitating Roar
        { spell = 236748, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 5 }, -- Intimidating Roar
        { spell = 6795, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Growl
        { spell = 192090, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Thrash
      },
      icon = 451161
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, types = {"ability","abilityShowAlways"}}, -- Incapacitating Roar
        { spell = 768, types = {"ability","abilityShowAlways"}}, -- Cat Form
        { spell = 783, types = {"ability","abilityShowAlways"}}, -- Travel Form
        { spell = 1850, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Dash
        { spell = 2782, types = {"ability","abilityShowAlways"}}, -- Remove Corruption
        { spell = 5211, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 10 }, -- Mighty Bash
        { spell = 5215, types = {"ability","abilityShowAlways"}}, -- Prowl
        { spell = 5487, types = {"ability","abilityShowAlways"}}, -- Bear Form
        { spell = 6795, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Growl
        { spell = 16979, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 18562, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Swiftmend
        { spell = 20484, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Rebirth
        { spell = 22812, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Barkskin
        { spell = 22842, types = {"ability","abilityCharge","abilityChargeBuff"}}, -- Frenzied Regeneration
        { spell = 33917, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Mangle
        { spell = 48438, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Wild Growth
        { spell = 49376, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 61336, types = {"ability","abilityCharge","abilityChargeBuff"}}, -- Survival Instincts
        { spell = 77758, types = {"ability","abilityShowAlways"}}, -- Thrash
        { spell = 102359, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 11 }, -- Mass Entanglement
        { spell = 102383, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 102401, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 102558, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 15 }, -- Incarnation: Guardian of Ursoc
        { spell = 106839, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Skull Bash
        { spell = 106898, types = {"ability","abilityShowAlways"}}, -- Stampeding Roar
        { spell = 132469, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Typhoon
        { spell = 155835, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 3 }, -- Bristling Fur
        { spell = 192081, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Ironfur
        { spell = 197625, types = {"ability","abilityShowAlways"}, talent = 7 }, -- Moonkin Form
        { spell = 197626, types = {"ability","abilityShowAlways"}, talent = 7 }, -- Starsurge
        { spell = 204066, types = {"ability","abilityShowAlways"}, talent = 20 }, -- Lunar Beam
        { spell = 236748, types = {"ability","abilityShowAlways"}, talent = 5 }, -- Intimidating Roar
        { spell = 252216, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 4 }, -- Tiger Dash
      },
      icon = 236169
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 276157, types = {"buff","buffShowAlways"}, unit = "player"}, --Craggy Bark
        { spell = 279793, types = {"buff","buffShowAlways"}, unit = "player"}, --Grove Tending
        { spell = 279541, types = {"buff","buffShowAlways"}, unit = "player"}, --Guardian's Wrath
        { spell = 272764, types = {"buff","buffShowAlways"}, unit = "player"}, --Heartblood
        { spell = 279555, types = {"buff","buffShowAlways"}, unit = "player"}, --Layered Mane
        { spell = 273349, types = {"buff","buffShowAlways"}, unit = "player"}, --Masterful Instincts
        { spell = 274814, types = {"buff","buffShowAlways"}, unit = "player"}, --Reawakening
        { spell = 275909, types = {"buff","buffShowAlways"}, unit = "player"}, --Twisted Claws
        { spell = 280165, types = {"buff","buffShowAlways"}, unit = "player"}, --Ursoc's Endurance
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 207640, types = {"buff","buffShowAlways"}, unit = "player", talent = 1 }, -- Abundance
        { spell = 157982, types = {"buff","buffShowAlways"}, unit = "player"}, -- Tranquility
        { spell = 29166, types = {"buff","buffShowAlways"}, unit = "player"}, -- Innervate
        { spell = 200389, types = {"buff","buffShowAlways"}, unit = "player", talent = 14 }, -- Cultivation
        { spell = 5215, types = {"buff","buffShowAlways"}, unit = "player"}, -- Prowl
        { spell = 774, types = {"buff","buffShowAlways"}, unit = "target"}, -- Rejuvenation
        { spell = 155777, types = {"buff","buffShowAlways"}, unit = "target", talent = 20 }, -- Rejuvenation (Germination)
        { spell = 164547, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 197721, types = {"buff","buffShowAlways"}, unit = "target", talent = 21 }, -- Flourish
        { spell = 117679, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Incarnation
        { spell = 5487, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bear Form
        { spell = 8936, types = {"buff","buffShowAlways"}, unit = "target"}, -- Regrowth
        { spell = 197625, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 207386, types = {"buff","buffShowAlways"}, unit = "target", talent = 18 }, -- Spring Blossoms
        { spell = 252216, types = {"buff","buffShowAlways"}, unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 22812, types = {"buff","buffShowAlways"}, unit = "target"}, -- Barkskin
        { spell = 33763, types = {"buff","buffShowAlways"}, unit = "target"}, -- Lifebloom
        { spell = 102401, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Wild Charge
        { spell = 192081, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Ironfur
        { spell = 22842, types = {"buff","buffShowAlways"}, unit = "player", talent = 9 }, -- Frenzied Regeneration
        { spell = 33891, types = {"buff","buffShowAlways"}, unit = "player", talent = 15 }, -- Incarnation: Tree of Life
        { spell = 164545, types = {"buff","buffShowAlways"}, unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 783, types = {"buff","buffShowAlways"}, unit = "player"}, -- Travel Form
        { spell = 16870, types = {"buff","buffShowAlways"}, unit = "player"}, -- Clearcasting
        { spell = 102351, types = {"buff","buffShowAlways"}, unit = "player", talent = 3 }, -- Cenarion Ward
        { spell = 102342, types = {"buff","buffShowAlways"}, unit = "player"}, -- Ironbark
        { spell = 1850, types = {"buff","buffShowAlways"}, unit = "player"}, -- Dash
        { spell = 114108, types = {"buff","buffShowAlways"}, unit = "player", talent = 13 }, -- Soul of the Forest
        { spell = 48438, types = {"buff","buffShowAlways"}, unit = "player"}, -- Wild Growth
        { spell = 768, types = {"buff","buffShowAlways"}, unit = "player"}, -- Cat Form

      },
      icon = 136081
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 127797, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Ursol's Vortex
        { spell = 102359, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 339, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Entangling Roots
        { spell = 5211, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 1079, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 8 }, -- Rip
        { spell = 164815, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Sunfire
        { spell = 61391, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12 }, -- Typhoon
        { spell = 192090, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 9 }, -- Thrash
        { spell = 164812, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Moonfire
        { spell = 6795, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Growl
        { spell = 155722, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 8 }, -- Rake
        { spell = 2637, types = {"debuff","debuffShowAlways"}, unit = "multi"}, -- Hibernate
      },
      icon = 236216
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 740, types = {"ability","abilityShowAlways"}}, -- Tranquility
        { spell = 768, types = {"ability","abilityShowAlways"}}, -- Cat Form
        { spell = 783, types = {"ability","abilityShowAlways"}}, -- Travel Form
        { spell = 1850, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Dash
        { spell = 2908, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Soothe
        { spell = 5211, types = {"ability","abilityShowAlways"}, talent = 10 }, -- Mighty Bash
        { spell = 5215, types = {"ability","abilityShowAlways"}}, -- Prowl
        { spell = 5487, types = {"ability","abilityShowAlways"}}, -- Bear Form
        { spell = 6795, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Growl
        { spell = 18562, types = {"ability","abilityShowAlways"}}, -- Swiftmend
        { spell = 20484, types = {"ability","abilityShowAlways"}}, -- Rebirth
        { spell = 22812, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Barkskin
        { spell = 22842, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 9 }, -- Frenzied Regeneration
        { spell = 29166, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Innervate
        { spell = 33891, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 15 }, -- Incarnation: Tree of Life
        { spell = 33917, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Mangle
        { spell = 48438, types = {"ability","abilityShowAlways"}}, -- Wild Growth
        { spell = 77758, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Thrash
        { spell = 102342, types = {"ability","abilityShowAlways"}}, -- Ironbark
        { spell = 102351, types = {"ability","abilityShowAlways"}, talent = 3 }, -- Cenarion Ward
        { spell = 102359, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 11 }, -- Mass Entanglement
        { spell = 102401, types = {"ability","abilityShowAlways"}, talent = 6 }, -- Wild Charge
        { spell = 102793, types = {"ability","abilityShowAlways"}}, -- Ursol's Vortex
        { spell = 108238, types = {"ability","abilityShowAlways"}, talent = 5 }, -- Renewal
        { spell = 132469, types = {"ability","abilityShowAlways"}, talent = 12 }, -- Typhoon
        { spell = 192081, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 9 }, -- Ironfur
        { spell = 197625, types = {"ability","abilityShowAlways"}, talent = 7 }, -- Moonkin Form
        { spell = 197626, types = {"ability","abilityShowAlways"}, talent = 7 }, -- Starsurge
        { spell = 197721, types = {"ability","abilityShowAlways"}, talent = 21 }, -- Flourish
        { spell = 252216, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 4 }, -- Tiger Dash
      },
      icon = 236153
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 279793, types = {"buff","buffShowAlways"}, unit = "target"}, --Grove Tending
        { spell = 279648, types = {"buff","buffShowAlways"}, unit = "player"}, --Lively Spirit
        { spell = 274814, types = {"buff","buffShowAlways"}, unit = "player"}, --Reawakening
        { spell = 269498, types = {"buff","buffShowAlways"}, unit = "player"}, --Rejuvenating Breath
        { spell = 280165, types = {"buff","buffShowAlways"}, unit = "player"}, --Ursoc's Endurance
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 208628, types = {"buff","buffShowAlways"}, unit = "player", talent = 20 }, -- Momentum
        { spell = 162264, types = {"buff","buffShowAlways"}, unit = "player"}, -- Metamorphosis
        { spell = 203650, types = {"buff","buffShowAlways"}, unit = "player", talent = 20 }, -- Prepared
        { spell = 188499, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blade Dance
        { spell = 212800, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blur
        { spell = 196555, types = {"buff","buffShowAlways"}, unit = "player", talent = 12 }, -- Netherwalk
        { spell = 258920, types = {"buff","buffShowAlways"}, unit = "player", talent = 6 }, -- Immolation Aura
        { spell = 131347, types = {"buff","buffShowAlways"}, unit = "player"}, -- Glide
        { spell = 188501, types = {"buff","buffShowAlways"}, unit = "player"}, -- Spectral Sight
        { spell = 209426, types = {"buff","buffShowAlways"}, unit = "player"}, -- Darkness
      },
      icon = 1247266
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1490, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Chaos Brand
        { spell = 258883, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 7}, -- Trail of Ruin
        { spell = 213405, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 17 }, -- Master of the Glaive
        { spell = 179057, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Chaos Nova
        { spell = 281854, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Torment
        { spell = 200166, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Metamorphosis
        { spell = 206491, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 21 }, -- Nemesis
        { spell = 198813, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Vengeful Retreat
        { spell = 258860, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15 }, -- Dark Slash
        { spell = 211881, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 18 }, -- Fel Eruption
        { spell = 217832, types = {"debuff","debuffShowAlways"}, unit = "multi" }, -- Imprison
      },
      icon = 1392554
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 131347, types = {"ability","abilityShowAlways"}}, -- Glide
        { spell = 179057, types = {"ability","abilityShowAlways"}}, -- Chaos Nova
        { spell = 183752, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Disrupt
        { spell = 185123, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Throw Glaive
        { spell = 188499, types = {"ability","abilityShowAlways"}}, -- Blade Dance
        { spell = 188501, types = {"ability","abilityShowAlways"}}, -- Spectral Sight
        { spell = 191427, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Metamorphosis
        { spell = 195072, types = {"ability","abilityCharge"}}, -- Fel Rush
        { spell = 196555, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 12 }, -- Netherwalk
        { spell = 196718, types = {"ability","abilityShowAlways"}}, -- Darkness
        { spell = 198013, types = {"ability","abilityShowAlways"}}, -- Eye Beam
        { spell = 198589, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Blur
        { spell = 198793, types = {"ability","abilityShowAlways"}}, -- Vengeful Retreat
        { spell = 206491, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 21 }, -- Nemesis
        { spell = 210152, types = {"ability","abilityShowAlways"}}, -- Death Sweep
        { spell = 211881, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Fel Eruption
        { spell = 217832, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Imprison
        { spell = 232893, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 3 }, -- Felblade
        { spell = 258860, types = {"ability","abilityShowAlways","abilityDebuff"}, talent = 15 }, -- Dark Slash
        { spell = 258920, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 6 }, -- Immolation Aura
        { spell = 258925, types = {"ability","abilityShowAlways"}, talent = 9 }, -- Fel Barrage
        { spell = 278326, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Consume Magic
        { spell = 281854, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Torment
      },
      icon = 1305156
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272794, types = {"buff","buffShowAlways"}, unit = "player"}, --Devour
        { spell = 273232, types = {"buff","buffShowAlways"}, unit = "player"}, --Furious Gaze
        { spell = 279584, types = {"buff","buffShowAlways"}, unit = "player"}, --Revolving Blades
        { spell = 274346, types = {"buff","buffShowAlways"}, unit = "player"}, --Soulmonger
        { spell = 278736, types = {"buff","buffShowAlways"}, unit = "player"}, --Thirsting Blades
        { spell = 275936, types = {"buff","buffShowAlways"}, unit = "player"}, --Seething Power
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 187827, types = {"buff","buffShowAlways"}, unit = "player"}, -- Metamorphosis
        { spell = 263648, types = {"buff","buffShowAlways"}, unit = "player", talent = 21 }, -- Soul Barrier
        { spell = 207693, types = {"buff","buffShowAlways"}, unit = "player", talent = 4}, -- Feast of Souls
        { spell = 131347, types = {"buff","buffShowAlways"}, unit = "player"}, -- Glide
        { spell = 203981, types = {"buff","buffShowAlways"}, unit = "player"}, -- Soul Fragments
        { spell = 188501, types = {"buff","buffShowAlways"}, unit = "player"}, -- Spectral Sight
        { spell = 203819, types = {"buff","buffShowAlways"}, unit = "player"}, -- Demon Spikes
        { spell = 178740, types = {"buff","buffShowAlways"}, unit = "player"}, -- Immolation Aura

      },
      icon = 1247263
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 207744, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Fiery Brand
        { spell = 1490, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Chaos Brand
        { spell = 204598, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Sigil of Flame
        { spell = 268178, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 20 }, -- Void Reaver
        { spell = 204490, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Sigil of Silence
        { spell = 204843, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 15 }, -- Sigil of Chains
        { spell = 207771, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 6 }, -- Fiery Brand
        { spell = 247456, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 17 }, -- Frailty
        { spell = 210003, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 3 }, -- Razor Spikes
        { spell = 207685, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Sigil of Misery
        { spell = 185245, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Torment
        { spell = 217832, types = {"debuff","debuffShowAlways"}, unit = "multi" }, -- Imprison
      },
      icon = 1344647
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 131347, types = {"ability","abilityShowAlways"}}, -- Glide
        { spell = 178740, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Immolation Aura
        { spell = 183752, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Disrupt
        { spell = 185245, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Torment
        { spell = 187827, types = {"ability","abilityShowAlways","abilityBuff"}}, -- Metamorphosis
        { spell = 188501, types = {"ability","abilityShowAlways"}}, -- Spectral Sight
        { spell = 189110, types = {"ability","abilityChargeS"}}, -- Infernal Strike
        { spell = 202137, types = {"ability","abilityShowAlways"}}, -- Sigil of Silence
        { spell = 202138, types = {"ability","abilityShowAlways"}, talent = 15 }, -- Sigil of Chains
        { spell = 202140, types = {"ability","abilityShowAlways"}}, -- Sigil of Misery
        { spell = 203720, types = {"ability","abilityCharge","abilityChargeBuff"}}, -- Demon Spikes
        { spell = 204021, types = {"ability","abilityShowAlways","abilityDebuff"}}, -- Fiery Brand
        { spell = 204157, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Throw Glaive
        { spell = 204513, types = {"ability","abilityShowAlways"}}, -- Sigil of Flame
        { spell = 212084, types = {"ability","abilityShowAlways"}, talent = 18 }, -- Fel Devastation
        { spell = 217832, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Imprison
        { spell = 228477, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Soul Cleave
        { spell = 232893, types = {"ability","abilityShowAlways","abilityTarget"}, talent = 9 }, -- Felblade
        { spell = 247454, types = {"ability","abilityShowAlways"}, talent = 17 }, -- Spirit Bomb
        { spell = 263642, types = {"ability","abilityCharge"}, talent = 12 }, -- Fracture
        { spell = 263648, types = {"ability","abilityShowAlways","abilityBuff"}, talent = 21 }, -- Soul Barrier
        { spell = 278326, types = {"ability","abilityShowAlways","abilityTarget"}}, -- Consume Magic

      },
      icon = 1344650
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 278769, types = {"buff","buffShowAlways"}, unit = "player"}, --Cycle of Binding
        { spell = 272794, types = {"buff","buffShowAlways"}, unit = "player"}, --Devour
        { spell = 275972, types = {"buff","buffShowAlways"}, unit = "player"}, --Gaping Maw
        { spell = 273238, types = {"buff","buffShowAlways"}, unit = "player"}, --Infernal Armor
        { spell = 272987, types = {"buff","buffShowAlways"}, unit = "player"}, --Revel in Pain
        { spell = 275351, types = {"buff","buffShowAlways"}, unit = "player"}, --Rigid Carapace
        { spell = 275936, types = {"buff","buffShowAlways"}, unit = "player"}, --Seething Power
        { spell = 274346, types = {"buff","buffShowAlways"}, unit = "player"}, --Soulmonger
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 81256, types = {"buff","buffShowAlways"}, unit = "player"}, -- Dancing Rune Weapon
        { spell = 55233, types = {"buff","buffShowAlways"}, unit = "player"}, -- Vampiric Blood
        { spell = 3714, types = {"buff","buffShowAlways"}, unit = "player"}, -- Path of Frost
        { spell = 194679, types = {"buff","buffShowAlways"}, unit = "player", talent = 12}, -- Rune Tap
        { spell = 48265, types = {"buff","buffShowAlways"}, unit = "player"}, -- Death's Advance
        { spell = 219809, types = {"buff","buffShowAlways"}, unit = "player", talent = 9}, -- Tombstone
        { spell = 188290, types = {"buff","buffShowAlways"}, unit = "player"}, -- Death and Decay
        { spell = 273947, types = {"buff","buffShowAlways"}, unit = "player", talent = 5}, -- Hemostasis
        { spell = 48707, types = {"buff","buffShowAlways"}, unit = "player"}, -- Anti-Magic Shell
        { spell = 81141, types = {"buff","buffShowAlways"}, unit = "player"}, -- Crimson Scourge
        { spell = 195181, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bone Shield
        { spell = 194844, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Bonestorm
        { spell = 274009, types = {"buff","buffShowAlways"}, unit = "player", talent = 16}, -- Voracious
        { spell = 53365, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unholy Strength
        { spell = 77535, types = {"buff","buffShowAlways"}, unit = "player"}, -- Blood Shield
        { spell = 212552, types = {"buff","buffShowAlways"}, unit = "player", talent = 15}, -- Wraith Walk
        { spell = 48792, types = {"buff","buffShowAlways"}, unit = "player"}, -- Icebound Fortitude
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 206930, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Heart Strike
        { spell = 206931, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 2}, -- Blooddrinker
        { spell = 221562, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Asphyxiate
        { spell = 273977, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 13}, -- Grip of the Dead
        { spell = 55078, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Blood Plague
        { spell = 56222, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Dark Command
        { spell = 51399, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Death Grip
        { spell = 114556, types = {"debuff","debuffShowAlways"}, unit = "player", talent = 19 }, -- Purgatory
      },
      icon = 237514
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, types = {"ability","abilityShowAlways"}}, -- Path of Frost
        { spell = 43265, types = {"ability","abilityShowAlways"}}, -- Death and Decay
        { spell = 47528, types = {"ability","abilityShowAlways"}}, -- Mind Freeze
        { spell = 48265, types = {"ability","abilityShowAlways"}}, -- Death's Advance
        { spell = 48707, types = {"ability","abilityShowAlways"}}, -- Anti-Magic Shell
        { spell = 48792, types = {"ability","abilityShowAlways"}}, -- Icebound Fortitude
        { spell = 49028, types = {"ability","abilityShowAlways"}}, -- Dancing Rune Weapon
        { spell = 49576, types = {"ability","abilityShowAlways"}}, -- Death Grip
        { spell = 50842, types = {"ability","abilityShowAlways"}}, -- Blood Boil
        { spell = 50977, types = {"ability","abilityShowAlways"}}, -- Death Gate
        { spell = 55233, types = {"ability","abilityShowAlways"}}, -- Vampiric Blood
        { spell = 56222, types = {"ability","abilityShowAlways"}}, -- Dark Command
        { spell = 61999, types = {"ability","abilityShowAlways"}}, -- Raise Ally
        { spell = 108199, types = {"ability","abilityShowAlways"}}, -- Gorefiend's Grasp
        { spell = 111673, types = {"ability","abilityShowAlways"}}, -- Control Undead
        { spell = 194679, types = {"ability","abilityShowAlways"}, talent = 12}, -- Rune Tap
        { spell = 194844, types = {"ability","abilityShowAlways"}, talent = 21}, -- Bonestorm
        { spell = 195182, types = {"ability","abilityShowAlways"}}, -- Marrowrend
        { spell = 195292, types = {"ability","abilityShowAlways"}}, -- Death's Caress
        { spell = 206930, types = {"ability","abilityShowAlways"}}, -- Heart Strike
        { spell = 206931, types = {"ability","abilityShowAlways"}, talent = 2}, -- Blooddrinker
        { spell = 206940, types = {"ability","abilityShowAlways"}, talent = 18}, -- Mark of Blood
        { spell = 210764, types = {"ability","abilityShowAlways"}, talent = 3}, -- Rune Strike
        { spell = 212552, types = {"ability","abilityShowAlways"}, talent = 15}, -- Wraith Walk
        { spell = 219809, types = {"ability","abilityShowAlways"}, talent = 9}, -- Tombstone
        { spell = 221562, types = {"ability","abilityShowAlways"}}, -- Asphyxiate
        { spell = 274156, types = {"ability","abilityShowAlways"}, talent = 6}, -- Consumption
      },
      icon = 136120
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275926, types = {"buff","buffShowAlways"}, unit = "player"}, -- Embrace of the Darkfallen
        { spell = 279503, types = {"buff","buffShowAlways"}, unit = "player"}, -- Bones of the Damned
        { spell = 278543, types = {"buff","buffShowAlways"}, unit = "player"}, -- Eternal Rune Weapon
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 3714, types = {"buff","buffShowAlways"}, unit = "player"}, -- Path of Frost
        { spell = 207203, types = {"buff","buffShowAlways"}, unit = "player"}, -- Frost Shield
        { spell = 152279, types = {"buff","buffShowAlways"}, unit = "player", talent = 21}, -- Breath of Sindragosa
        { spell = 59052, types = {"buff","buffShowAlways"}, unit = "player"}, -- Rime
        { spell = 48265, types = {"buff","buffShowAlways"}, unit = "player"}, -- Death's Advance
        { spell = 281209, types = {"buff","buffShowAlways"}, unit = "player", talent = 3}, -- Cold Heart
        { spell = 51124, types = {"buff","buffShowAlways"}, unit = "player"}, -- Killing Machine
        { spell = 48707, types = {"buff","buffShowAlways"}, unit = "player"}, -- Anti-Magic Shell
        { spell = 211805, types = {"buff","buffShowAlways"}, unit = "player", talent = 16}, -- Gathering Storm
        { spell = 51271, types = {"buff","buffShowAlways"}, unit = "player"}, -- Pillar of Frost
        { spell = 212552, types = {"buff","buffShowAlways"}, unit = "player", talent = 14}, -- Wraith Walk
        { spell = 53365, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unholy Strength
        { spell = 196770, types = {"buff","buffShowAlways"}, unit = "player"}, -- Remorseless Winter
        { spell = 47568, types = {"buff","buffShowAlways"}, unit = "player"}, -- Empower Rune Weapon
        { spell = 194879, types = {"buff","buffShowAlways"}, unit = "player", talent = 2}, -- Icy Talons
        { spell = 48792, types = {"buff","buffShowAlways"}, unit = "player"}, -- Icebound Fortitude
        { spell = 253595, types = {"buff","buffShowAlways"}, unit = "player", talent = 1}, -- Inexorable Assault
        { spell = 178819, types = {"buff","buffShowAlways"}, unit = "player" }, -- Dark Succor
      },
      icon = 135305
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 207167, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 9}, -- Blinding Sleet
        { spell = 45524, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Chains of Ice
        { spell = 51714, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Razorice
        { spell = 56222, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Dark Command
        { spell = 211793, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Remorseless Winter
        { spell = 55095, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Frost Fever

      },
      icon = 237522
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, types = {"ability","abilityShowAlways"}}, -- Path of Frost
        { spell = 45524, types = {"ability","abilityShowAlways"}}, -- Chains of Ice
        { spell = 47528, types = {"ability","abilityShowAlways"}}, -- Mind Freeze
        { spell = 47568, types = {"ability","abilityShowAlways"}}, -- Empower Rune Weapon
        { spell = 48265, types = {"ability","abilityShowAlways"}, talent = 15}, -- Death's Advance
        { spell = 48707, types = {"ability","abilityShowAlways"}}, -- Anti-Magic Shell
        { spell = 48743, types = {"ability","abilityShowAlways"}}, -- Death Pact
        { spell = 48792, types = {"ability","abilityShowAlways"}}, -- Icebound Fortitude
        { spell = 49020, types = {"ability","abilityShowAlways"}}, -- Obliterate
        { spell = 49184, types = {"ability","abilityShowAlways"}}, -- Howling Blast
        { spell = 50977, types = {"ability","abilityShowAlways"}}, -- Death Gate
        { spell = 51271, types = {"ability","abilityShowAlways"}}, -- Pillar of Frost
        { spell = 56222, types = {"ability","abilityShowAlways"}}, -- Dark Command
        { spell = 57330, types = {"ability","abilityShowAlways"}, talent = 6}, -- Horn of Winter
        { spell = 61999, types = {"ability","abilityShowAlways"}}, -- Raise Ally
        { spell = 111673, types = {"ability","abilityShowAlways"}}, -- Control Undead
        { spell = 152279, types = {"ability","abilityShowAlways"}, talent = 21}, -- Breath of Sindragosa
        { spell = 194913, types = {"ability","abilityShowAlways"}}, -- Glacial Advance
        { spell = 196770, types = {"ability","abilityShowAlways"}}, -- Remorseless Winter
        { spell = 207167, types = {"ability","abilityShowAlways"}, talent = 9}, -- Blinding Sleet
        { spell = 207230, types = {"ability","abilityShowAlways"}, talent = 12}, -- Frostscythe
        { spell = 212552, types = {"ability","abilityShowAlways"}, talent = 14}, -- Wraith Walk
        { spell = 279302, types = {"ability","abilityShowAlways"}, talent = 18}, -- Frostwyrm's Fury
      },
      icon = 135372
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272723, types = {"buff","buffShowAlways"}, unit = "player"}, -- Icy Citadel
        { spell = 274074, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Glacial Contagion
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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
        { spell = 3714, types = {"buff","buffShowAlways"}, unit = "player"}, -- Path of Frost
        { spell = 212552, types = {"buff","buffShowAlways"}, unit = "player", talent = 14}, -- Wraith Walk
        { spell = 48707, types = {"buff","buffShowAlways"}, unit = "player"}, -- Anti-Magic Shell
        { spell = 53365, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unholy Strength
        { spell = 207289, types = {"buff","buffShowAlways"}, unit = "player"}, -- Unholy Frenzy
        { spell = 188290, types = {"buff","buffShowAlways"}, unit = "player"}, -- Death and Decay
        { spell = 115989, types = {"buff","buffShowAlways"}, unit = "player", talent = 6}, -- Unholy Blight
        { spell = 48792, types = {"buff","buffShowAlways"}, unit = "player"}, -- Icebound Fortitude
        { spell = 42650, types = {"buff","buffShowAlways"}, unit = "player"}, -- Army of the Dead
        { spell = 81340, types = {"buff","buffShowAlways"}, unit = "player"}, -- Sudden Doom
        { spell = 48265, types = {"buff","buffShowAlways"}, unit = "player"}, -- Death's Advance
        { spell = 51460, types = {"buff","buffShowAlways"}, unit = "player"}, -- Runic Corruption
        { spell = 63560, types = {"buff","buffShowAlways"}, unit = "pet"}, -- Dark Transformation
        { spell = 178819, types = {"buff","buffShowAlways"}, unit = "player" }, -- Dark Succor
      },
      icon = 136181
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Chains of Ice
        { spell = 115994, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 6}, -- Unholy Blight
        { spell = 91800, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Gnaw
        { spell = 194310, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Festering Wound
        { spell = 56222, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Dark Command
        { spell = 196782, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Outbreak
        { spell = 108194, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 9}, -- Asphyxiate
        { spell = 273977, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Grip of the Dead
        { spell = 130736, types = {"debuff","debuffShowAlways"}, unit = "target", talent = 12}, -- Soul Reaper
        { spell = 191587, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Virulent Plague
      },
      icon = 1129420
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, types = {"ability","abilityShowAlways"}}, -- Path of Frost
        { spell = 42650, types = {"ability","abilityShowAlways"}}, -- Army of the Dead
        { spell = 43265, types = {"ability","abilityShowAlways"}}, -- Death and Decay
        { spell = 45524, types = {"ability","abilityShowAlways"}}, -- Chains of Ice
        { spell = 46584, types = {"ability","abilityShowAlways"}}, -- Raise Dead
        { spell = 47468, types = {"ability","abilityShowAlways"}}, -- Claw
        { spell = 47481, types = {"ability","abilityShowAlways"}}, -- Gnaw
        { spell = 47484, types = {"ability","abilityShowAlways"}}, -- Huddle
        { spell = 47528, types = {"ability","abilityShowAlways"}}, -- Mind Freeze
        { spell = 48265, types = {"ability","abilityShowAlways"}}, -- Death's Advance
        { spell = 48707, types = {"ability","abilityShowAlways"}}, -- Anti-Magic Shell
        { spell = 48743, types = {"ability","abilityShowAlways"}}, -- Death Pact
        { spell = 48792, types = {"ability","abilityShowAlways"}}, -- Icebound Fortitude
        { spell = 49206, types = {"ability","abilityShowAlways"}, talent = 21}, -- Summon Gargoyle
        { spell = 50977, types = {"ability","abilityShowAlways"}}, -- Death Gate
        { spell = 55090, types = {"ability","abilityShowAlways"}}, -- Scourge Strike
        { spell = 56222, types = {"ability","abilityShowAlways"}}, -- Dark Command
        { spell = 61999, types = {"ability","abilityShowAlways"}}, -- Raise Ally
        { spell = 63560, types = {"ability","abilityShowAlways"}}, -- Dark Transformation
        { spell = 77575, types = {"ability","abilityShowAlways"}}, -- Outbreak
        { spell = 85948, types = {"ability","abilityShowAlways"}}, -- Festering Strike
        { spell = 108194, types = {"ability","abilityShowAlways"}, talent = 9}, -- Asphyxiate
        { spell = 111673, types = {"ability","abilityShowAlways"}}, -- Control Undead
        { spell = 115989, types = {"ability","abilityShowAlways"}, talent = 6}, -- Unholy Blight
        { spell = 130736, types = {"ability","abilityShowAlways"}, talent = 12}, -- Soul Reaper
        { spell = 152280, types = {"ability","abilityShowAlways"}, talent = 17}, -- Defile
        { spell = 207289, types = {"ability","abilityShowAlways"}, talent = 20}, -- Unholy Frenzy
        { spell = 207311, types = {"ability","abilityShowAlways"}}, -- Clawing Shadows
        { spell = 212552, types = {"ability","abilityShowAlways"}, talent = 14}, -- Wraith Walk
        { spell = 275699, types = {"ability","abilityShowAlways"}}, -- Apocalypse
      },
      icon = 136144
    },
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272738, types = {"buff","buffShowAlways"}, unit = "player"}, -- Festering Doom
        { spell = 274373, types = {"buff","buffShowAlways"}, unit = "player"}, -- Festermight
        { spell = 275931, types = {"debuff","debuffShowAlways"}, unit = "target"}, -- Harrowing Decay
      },
      icon = 135349
    },
    [7] = {
      title = L["PvP Talents"],
      args = {
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [8] = {
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

tinsert(templates.general.args, {
  spell = 2825, types = {"buff","buffShowAlways"}, unit = "player",
  forceOwnOnly = true,
  ownOnly = nil,
  overideTitle = L["Bloodlust/Heroism"],
  spellIds = {2825, 32182, 80353, 90355, 160452, 264667}}
);

-- Items section
templates.items[1] = {
  title = L["Enchants"],
  args = {
    { spell = 268905, types = {"buff","buffShowAlways"}, unit = "player"}, --Deadly Navigation
    { spell = 267612, types = {"buff","buffShowAlways"}, unit = "player"}, --Gale-Force Striking
    { spell = 268899, types = {"buff","buffShowAlways"}, unit = "player"}, --Masterful Navigation
    { spell = 268887, types = {"buff","buffShowAlways"}, unit = "player"}, --Quick Navigation
    { spell = 268911, types = {"buff","buffShowAlways"}, unit = "player"}, --Stalwart Navigation
    { spell = 267685, types = {"buff","buffShowAlways"}, unit = "player"}, --Torrent of Elements
    { spell = 268854, types = {"buff","buffShowAlways"}, unit = "player"}, --Versatile Navigation
  }
}

templates.items[2] = {
  title = L["On Use Trinkets (Buff)"],
  args = {
    { spell = 278383, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161377},
    { spell = 278385, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161379},
    { spell = 278227, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161411},
    { spell = 278086, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 160649}, --heal
    { spell = 278317, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161462},
    { spell = 278364, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161463},
    { spell = 281543, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 163936},
    { spell = 265954, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 158319},
    { spell = 266018, types = {"buff","buffShowAlways"}, unit = "target", titleItemPrefix = 158320}, --heal
    { spell = 271054, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 158368}, --heal
    { spell = 268311, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159614}, --heal
    { spell = 271115, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159615},
    { spell = 271107, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159617},
    { spell = 265946, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159618}, --tank
    { spell = 271465, types = {"debuff","debuffShowAlways"}, unit = "target", titleItemPrefix = 159624},
    { spell = 268836, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159625},
    { spell = 266047, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159627},
    { spell = 268998, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159630},
  }
}

templates.items[3] = {
  title = L["On Use Trinkets (CD)"],
  args = {
    { spell = 161377, types = {"item","itemShowAlways"}},
    { spell = 161379, types = {"item","itemShowAlways"}},
    { spell = 161411, types = {"item","itemShowAlways"}},
    { spell = 160649, types = {"item","itemShowAlways"}}, --heal
    { spell = 161462, types = {"item","itemShowAlways"}},
    { spell = 161463, types = {"item","itemShowAlways"}},
    { spell = 163936, types = {"item","itemShowAlways"}},
    { spell = 158319, types = {"item","itemShowAlways"}},
    { spell = 158320, types = {"item","itemShowAlways"}}, --heal
    { spell = 158368, types = {"item","itemShowAlways"}}, --heal
    { spell = 159614, types = {"item","itemShowAlways"}}, --heal
    { spell = 159615, types = {"item","itemShowAlways"}},
    { spell = 159617, types = {"item","itemShowAlways"}},
    { spell = 159618, types = {"item","itemShowAlways"}}, --tank
    { spell = 159624, types = {"item","itemShowAlways"}},
    { spell = 159625, types = {"item","itemShowAlways"}},
    { spell = 159627, types = {"item","itemShowAlways"}},
    { spell = 159630, types = {"item","itemShowAlways"}},
    { spell = 159611, types = {"item","itemShowAlways"}}, -- no buff
    { spell = 158367, types = {"item","itemShowAlways"}}, --no buff
  }
}

templates.items[4] = {
  title = L["On Procc Trinkets (Buff)"],
  args = {
    { spell = 278143, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 160648},
    { spell = 278070, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 160652},
    { spell = 278110, types = {"debuff","debuffShowAlways"}, unit = "multi", titleItemPrefix = 160655}, --debuff?
    { spell = 278155, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 160656},
    { spell = 278379, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161376},
    { spell = 278381, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161378},
    { spell = 278862, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161380},
    { spell = 278388, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161381},
    { spell = 278225, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161412},
    { spell = 278288, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161419},
    { spell = 278359, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161461},
    { spell = 281546, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 163935},
    { spell = 276132, types = {"debuff","debuffShowAlways"}, unit = "target", titleItemPrefix = 159126}, --debuff?
    { spell = 267325, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 155881},
    { spell = 267327, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 155881},
    { spell = 267330, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 155881},
    { spell = 267179, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 158374},
    { spell = 271103, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 158712},
    { spell = 268439, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159612},
    { spell = 271105, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159616},
    { spell = 268194, types = {"debuff","debuffShowAlways"}, unit = "multi", titleItemPrefix = 159619}, --debuff?
    { spell = 271071, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159620},
    { spell = 268756, types = {"debuff","debuffShowAlways"}, unit = "multi", titleItemPrefix = 159623}, --debuff?
    { spell = 268062, types = {"buff","buffShowAlways"}, unit = "multi", titleItemPrefix = 159626}, --buff on spawned spores?
    { spell = 271194, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 159628},
    { spell = 278159, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 160653}, --tank
  }
}

templates.items[5] = {
  title = L["PVP Trinkets (Buff)"],
  args = {
    { spell = 278812, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161472},
    { spell = 278806, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161473},
    { spell = 278819, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161474}, -- on use
    { spell = 277179, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161674}, -- on use
    { spell = 277181, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161676},
    { spell = 277187, types = {"buff","buffShowAlways"}, unit = "player", titleItemPrefix = 161675},-- on use
  }
}

templates.items[6] = {
  title = L["PVP Trinkets (CD)"],
  args = {
    { spell = 161474, types = {"item","itemShowAlways"}}, --on use
    { spell = 161674, types = {"item","itemShowAlways"}}, --on use
    { spell = 161675, types = {"item","itemShowAlways"}}, --on use
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
  -- tinsert(spec[5].args, { spell = 195710, types = {"ability","abilityShowAlways"}}) -- Honorable Medallion
  -- tinsert(spec[5].args, { spell = 208683, types = {"ability","abilityShowAlways"}, pvptalent = 1}) -- Gladiator's Medallion
  end
end

for _, class in pairs(templates.class) do
  for _, spec in pairs(class) do
    spec[4] = {
      title = L["General Azerite Traits"],
      args = CopyTable(generalAzeriteTraits),
      icon = 2065624
    }
    spec[6] = {
      title = L["PvP Azerite Traits"],
      args = CopyTable(pvpAzeriteTraits),
      icon = 236396
    }
  end
end

-------------------------------
-- Hardcoded trigger templates
-------------------------------

-- Warrior
for i = 1, 3 do
  tinsert(templates.class.WARRIOR[i][8].args, createSimplePowerTemplate(1));
end

-- Paladin
tinsert(templates.class.PALADIN[3][8].args, createSimplePowerTemplate(9));
for i = 1, 3 do
  tinsert(templates.class.PALADIN[i][8].args, createSimplePowerTemplate(0));
end

-- Hunter
for i = 1, 3 do
  tinsert(templates.class.HUNTER[i][8].args, createSimplePowerTemplate(2));
end

-- Rogue
for i = 1, 3 do
  tinsert(templates.class.ROGUE[i][8].args, createSimplePowerTemplate(3));
  tinsert(templates.class.ROGUE[i][8].args, createSimplePowerTemplate(4));
end

-- Priest
for i = 1, 3 do
  tinsert(templates.class.PRIEST[i][8].args, createSimplePowerTemplate(0));
end
tinsert(templates.class.PRIEST[3][8].args, createSimplePowerTemplate(13));

-- Shaman
for i = 1, 3 do
  tinsert(templates.class.SHAMAN[i][8].args, createSimplePowerTemplate(0));

  templates.class.SHAMAN[i][7] = {
    title = L["Totems"],
    args = {
    },
    icon = 538575,
  };
end

for i = 1, 2 do
  tinsert(templates.class.SHAMAN[i][8].args, createSimplePowerTemplate(11));
end

-- Mage
tinsert(templates.class.MAGE[1][8].args, createSimplePowerTemplate(16));
for i = 1, 3 do
  tinsert(templates.class.MAGE[i][8].args, createSimplePowerTemplate(0));
end

-- Warlock
for i = 1, 3 do
  tinsert(templates.class.WARLOCK[i][8].args, createSimplePowerTemplate(0));
  tinsert(templates.class.WARLOCK[i][8].args, createSimplePowerTemplate(7));
end

-- Monk
tinsert(templates.class.MONK[1][8].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[2][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.MONK[3][8].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[3][8].args, createSimplePowerTemplate(12));

templates.class.MONK[1][9] = {
  title = L["Ability Charges"],
  args = {
    { spell = 115072, types = {"ability","abilityShowAlways"}, buffShowOn = "showAlways"}, -- Expel Harm
  },
  icon = 627486,
};

templates.class.MONK[2][9] = {
  title = L["Ability Charges"],
  args = {
  },
  icon = 1242282,
};

templates.class.MONK[3][9] = {
  title = L["Ability Charges"],
  args = {
  },
  icon = 606543,
};

-- Druid
for i = 1, 4 do
  -- Shapeshift Form
  tinsert(templates.class.DRUID[i][8].args, {
    title = L["Shapeshift Form"],
    icon = 132276,
    triggers = {[0] = { trigger = { type = "status", event = "Stance/Form/Aura", unevent = "auto"}}}
  });
end

-- Astral Power
tinsert(templates.class.DRUID[1][8].args, createSimplePowerTemplate(8));

for i = 1, 4 do
  tinsert(templates.class.DRUID[i][8].args, createSimplePowerTemplate(0)); -- Mana
  tinsert(templates.class.DRUID[i][8].args, createSimplePowerTemplate(1)); -- Rage
  tinsert(templates.class.DRUID[i][8].args, createSimplePowerTemplate(3)); -- Energy
  tinsert(templates.class.DRUID[i][8].args, createSimplePowerTemplate(4)); -- Combo Points
end

-- Efflorescence aka Mushroom
tinsert(templates.class.DRUID[4][3].args,  {spell = 145205, types = {"totem"}});

-- Demon Hunter
tinsert(templates.class.DEMONHUNTER[1][8].args, createSimplePowerTemplate(17));
tinsert(templates.class.DEMONHUNTER[2][8].args, createSimplePowerTemplate(18));

-- Death Knight
for i = 1, 3 do
  tinsert(templates.class.DEATHKNIGHT[i][8].args, createSimplePowerTemplate(6));

  tinsert(templates.class.DEATHKNIGHT[i][8].args, {
    title = L["Runes"],
    icon = "Interface\\Icons\\spell_deathknight_frozenruneweapon",
    triggers = {[0] = { trigger = { type = "status", event = "Death Knight Rune", unevent = "auto"}}}
  });
end

------------------------------
-- Hardcoded race templates
-------------------------------

-- Every Man for Himself
tinsert(templates.race.Human, { spell = 59752, types = {"ability","abilityShowAlways"} });
-- Stoneform
tinsert(templates.race.Dwarf, { spell = 20594, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.Dwarf, { spell = 65116, types = {"buff","buffShowAlways"}, unit = "player", titleSuffix = L["buff"]});
-- Shadow Meld
tinsert(templates.race.NightElf, { spell = 58984, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.NightElf, { spell = 58984, types = {"buff","buffShowAlways"}, titleSuffix = L["Buff"]});
-- Escape Artist
tinsert(templates.race.Gnome, { spell = 20589, types = {"ability","abilityShowAlways"} });
-- Gift of the Naaru
tinsert(templates.race.Draenei, { spell = 28880, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.Draenei, { spell = 28880, types = {"buff","buffShowAlways"}, unit = "player", titleSuffix = L["buff"]});
-- Dark Flight
tinsert(templates.race.Worgen, { spell = 68992, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.Worgen, { spell = 68992, types = {"buff","buffShowAlways"}, unit = "player", titleSuffix = L["buff"]});
-- Quaking Palm
tinsert(templates.race.Pandaren, { spell = 107079, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.Pandaren, { spell = 107079, types = {"buff","buffShowAlways"}, titleSuffix = L["buff"]});
-- Blood Fury
tinsert(templates.race.Orc, { spell = 20572, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.Orc, { spell = 20572, types = {"buff","buffShowAlways"}, unit = "player", titleSuffix = L["buff"]});
--Cannibalize
tinsert(templates.race.Scourge, { spell = 20577, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.Scourge, { spell = 20578, types = {"buff","buffShowAlways"}, unit = "player", titleSuffix = L["buff"]});
-- War Stomp
tinsert(templates.race.Tauren, { spell = 20549, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.Tauren, { spell = 20549, types = {"buff","buffShowAlways"}, titleSuffix = L["buff"]});
--Beserking
tinsert(templates.race.Troll, { spell = 26297, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.Troll, { spell = 26297, types = {"buff","buffShowAlways"}, unit = "player", titleSuffix = L["buff"]});
-- Arcane Torment
tinsert(templates.race.BloodElf, { spell = 69179, types = {"ability","abilityShowAlways"}, titleSuffix = L["cooldown"]});
tinsert(templates.race.BloodElf, { spell = 69179, types = {"buff","buffShowAlways"}, titleSuffix = L["buff"]});
-- Pack Hobgoblin
tinsert(templates.race.Goblin, { spell = 69046, types = {"ability","abilityShowAlways"} });
-- Rocket Barrage
tinsert(templates.race.Goblin, { spell = 69041, types = {"ability","abilityShowAlways"} });

-- Arcane Pulse
tinsert(templates.race.Nightborne, { spell = 260364, types = {"ability","abilityShowAlways"} });
-- Cantrips
tinsert(templates.race.Nightborne, { spell = 255661, types = {"ability","abilityShowAlways"} });
-- Light's Judgment
tinsert(templates.race.LightforgedDraenei, { spell = 255647, types = {"ability","abilityShowAlways"} });
-- Forge of Light
tinsert(templates.race.LightforgedDraenei, { spell = 259930, types = {"ability","abilityShowAlways"} });
-- Bull Rush
tinsert(templates.race.HighmountainTauren, { spell = 255654, types = {"ability","abilityShowAlways"} });
--Spatial Rift
tinsert(templates.race.VoidElf, { spell = 256948, types = {"ability","abilityShowAlways"} });

------------------------------
-- Helper code for options
-------------------------------

-- Enrich items from spell, set title
local function handleItem(item)
  local waitingForItemInfo = false;
  if (item.spell) then
    local name, icon, _;
    if (item.types[1] == "item") then
      name, _, _, _, _, _, _, _, _, icon = GetItemInfo(item.spell);
      if (name == nil) then
        name = L["Unknown Item"] .. " " .. tostring(item.spell);
        waitingForItemInfo = true;
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
      else
        waitingForItemInfo = true;
      end
    end
    if (item.types[1] ~= "item") then
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
local itemInfoReceived = CreateFrame("frame")

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
        for _, item in pairs(section.args) do
          if(handleItem(item)) then
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
      if (handleItem(item)) then
        waitingForItemInfo = true;
      end
      addLoadCondition(item, loadCondition);
    end
  end

  for _, item in pairs(templates.general.args) do
    if (handleItem(item)) then
      waitingForItemInfo = true;
    end
  end

  for _, section in pairs(templates.items) do
    for _, item in pairs(section.args) do
      if (handleItem(item)) then
        waitingForItemInfo = true;
      end
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
        for _, item in pairs(section.args) do
          if (item.spell and item.types[1] ~= "item") then
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

local fixupIconsFrame = CreateFrame("frame");
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
