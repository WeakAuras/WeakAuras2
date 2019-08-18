if WeakAuras.IsClassic() then return end

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
    [12] = {name = CHI_POWER, icon = "Interface\\Icons\\ability_monk_healthsphere"},
    [13] = {name = POWER_TYPE_INSANITY, icon = "Interface\\Icons\\spell_priest_shadoworbs"},
    [16] = {name = POWER_TYPE_ARCANE_CHARGES, icon = "Interface\\Icons\\spell_arcane_arcane01"},
    [17] = {name = POWER_TYPE_FURY_DEMONHUNTER, icon = 1344651},
    [18] = {name = POWER_TYPE_PAIN, icon = 1247265},
    [99] = {name = STAGGER, icon = "Interface\\Icons\\monk_stance_drunkenox"}
  }

local generalAzeriteTraits = {
  { spell = 279928, type = "buff", unit = "player"}, --Earthlink
  { spell = 271543, type = "buff", unit = "player"}, --Ablative Shielding
  { spell = 268435, type = "buff", unit = "player"}, --Azerite Fortification
  { spell = 264108, type = "buff", unit = "player"}, --Blood Siphon
  { spell = 270657, type = "buff", unit = "player"}, --Bulwark of the Masses
  { spell = 270586, type = "buff", unit = "player"}, --Champion of Azeroth
  { spell = 271538, type = "buff", unit = "player"}, --Crystalline Carapace
  { spell = 272572, type = "buff", unit = "player"}, --Ephemeral Recovery
  { spell = 270576, type = "buff", unit = "player"}, --Gemhide
  { spell = 268437, type = "buff", unit = "player"}, --Impassive Visage
  { spell = 270621, type = "buff", unit = "player"}, --Lifespeed
  { spell = 267879, type = "buff", unit = "player"}, --On My Way
  { spell = 270568, type = "buff", unit = "player"}, --Resounding Protection
  { spell = 270661, type = "buff", unit = "player"}, --Self Reliance
  { spell = 272090, type = "buff", unit = "player"}, --Synergistic Growth
  { spell = 269239, type = "buff", unit = "player"}, --Vampiric Speed
  { spell = 269214, type = "buff", unit = "player"}, --Winds of War
  { spell = 281516, type = "buff", unit = "player"}, --Unstable Catalyst
  { spell = 279902, type = "buff", unit = "player"}, --Unstable Flames
  { spell = 279956, type = "debuff", unit = "multi"}, --Azerite Globules
  { spell = 270674, type = "buff", unit = "player"}, --Azerite Veins
  { spell = 271843, type = "buff", unit = "player"}, --Blessed Portents
  { spell = 272276, type = "buff", unit = "target"}, --Bracing Chill
  { spell = 272260, type = "buff", unit = "target"}, --Concentrated Mending
  { spell = 268955, type = "buff", unit = "player"}, --Elemental Whirl
  { spell = 263987, type = "buff", unit = "player"}, --Heed My Call
  { spell = 271711, type = "buff", unit = "player"}, --Overwhelming Power
  { spell = 271550, type = "buff", unit = "player"}, --Strength in Numbers
  { spell = 271559, type = "buff", unit = "player"}, --Shimmering Haven
  { spell = 269085, type = "buff", unit = "player"}, --Woundbinder
  { spell = 273685, type = "buff", unit = "player"}, --Meticulous Scheming
  { spell = 273714, type = "buff", unit = "player"}, --Seize the Moment!
  { spell = 273870, type = "buff", unit = "player"}, --Sandstorm
  { spell = 280204, type = "buff", unit = "player"}, --Wandering Soul
  { spell = 280409, type = "buff", unit = "player"}, --Blood Rite
  { spell = 273836, type = "buff", unit = "player"}, --Filthy Transfusion
  { spell = 280413, type = "buff", unit = "player"}, --Incite the Pack
  { spell = 273794, type = "debuff", unit = "multi"}, --Rezan's Fury
  { spell = 280433, type = "buff", unit = "player"}, --Swirling Sands
  { spell = 280385, type = "debuff", unit = "multi"}, --Thunderous Blast
  { spell = 280404, type = "buff", unit = "target"}, --Tidal Surge
  { spell = 273842, type = "buff", unit = "player"}, --Secrets of the Deep
  { spell = 280286, type = "debuff", unit = "target"}, --Dagger in the Back
  { spell = 281843, type = "buff", unit = "player"}, --Tradewinds
  { spell = 280709, type = "buff", unit = "player"}, --Archive of the Titans
  { spell = 280573, type = "buff", unit = "player"}, --Reorigination Array
  { spell = 287471, type = "buff", unit = "player"}, --Shadow of Elune
  { spell = 287610, type = "buff", unit = "player"}, --Ancient's Bulwark (Deep Roots)
  { spell = 287608, type = "buff", unit = "player"}, --Ancient's Bulwark (Uproot)
}

local pvpAzeriteTraits = {
  { spell = 280876, type = "buff", unit = "player"}, --Anduin's Dedication
  { spell = 280809, type = "buff", unit = "player"}, --Sylvanas' Resolve
  { spell = 280855, type = "debuff", unit = "target"}, --Battlefield Precision
  { spell = 280817, type = "debuff", unit = "target"}, --Battlefield Focus
  { spell = 280858, type = "buff", unit = "player"}, --Stand As One
  { spell = 280830, type = "buff", unit = "player"}, --Liberator's Might
  { spell = 280780, type = "buff", unit = "player"}, --Glory in Battle
  { spell = 280861, type = "buff", unit = "player"}, --Last Gift
  { spell = 280787, type = "buff", unit = "player"}, --Retaliatory Fury
}

-- Collected by WeakAurasTemplateCollector:

templates.class.WARRIOR = {
  [1] = { -- Arms
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 248622, type = "buff", unit = "player", talent = 16}, -- In For The Kill
        { spell = 197690, type = "buff", unit = "player", talent = 12}, -- Defensive Stance
        { spell = 118038, type = "buff", unit = "player"}, -- Die by the Sword
        { spell = 6673, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 107574, type = "buff", unit = "player", talent = 17}, -- Avatar
        { spell = 262228, type = "buff", unit = "player", talent = 18}, -- Deadly Calm
        { spell = 32216, type = "buff", unit = "player", talent = 5}, -- Victorious
        { spell = 227847, type = "buff", unit = "player"}, -- Bladestorm
        { spell = 52437, type = "buff", unit = "player", talent = 2}, -- Sudden Death
        { spell = 18499, type = "buff", unit = "player"}, -- Berserker Rage
        { spell = 202164, type = "buff", unit = "player", talent = 11}, -- Bounding Stride
        { spell = 7384, type = "buff", unit = "player"}, -- Overpower
        { spell = 262232, type = "buff", unit = "player", talent = 1}, -- War Machine
        { spell = 97463, type = "buff", unit = "player"}, -- Rallying Cry
        { spell = 260708, type = "buff", unit = "player"}, -- Sweeping Strikes
      },
      icon = 132333
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115804, type = "debuff", unit = "target"}, -- Mortal Wounds
        { spell = 772, type = "debuff", unit = "target", talent = 9}, -- Rend
        { spell = 208086, type = "debuff", unit = "target"}, -- Colossus Smash
        { spell = 105771, type = "debuff", unit = "target"}, -- Charge
        { spell = 5246, type = "debuff", unit = "target"}, -- Intimidating Shout
        { spell = 1715, type = "debuff", unit = "target"}, -- Hamstring
        { spell = 355, type = "debuff", unit = "target"}, -- Taunt
        { spell = 262115, type = "debuff", unit = "target"}, -- Deep Wounds
        { spell = 132169, type = "debuff", unit = "target", talent = 6}, -- Storm Bolt
      },
      icon = 132366
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100, type = "ability", requiresTarget = true, talent = {5,6}, classic = false}, -- Charge
        { spell = 100, type = "ability", requiresTarget = true, classic = true}, -- Charge
        { spell = 100, type = "ability", charges = true, requiresTarget = true, talent = 4, titleSuffix=" (2 Charges)", classic = false}, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true}, -- Taunt
        { spell = 845, type = "ability", talent = 15}, -- Cleave
        { spell = 1464, type = "ability", requiresTarget = true}, -- Slam
        { spell = 1680, type = "ability"}, -- Whirlwind
        { spell = 1715, type = "ability", requiresTarget = true}, -- Hamstring
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true}, -- Intimidating Shout
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true}, -- Pummel
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 7384, type = "ability", requiresTarget = true, overlayGlow = true, talent = {19,21}}, -- Overpower
        { spell = 7384, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 20, titleSuffix=" (2 Charges)", classic = false}, -- Overpower
        { spell = 12294, type = "ability", requiresTarget = true}, -- Mortal Strike
        { spell = 18499, type = "ability", buff = true}, -- Berserker Rage
        { spell = 34428, type = "ability", usable = true, requiresTarget = true}, -- Victory Rush
        { spell = 57755, type = "ability", requiresTarget = true}, -- Heroic Throw
        { spell = 97462, type = "ability", buff = true}, -- Rallying Cry
        { spell = 107570, type = "ability", debuff = true, requiresTarget = true, talent = 6}, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true, talent = 17}, -- Avatar
        { spell = 118038, type = "ability", buff = true}, -- Die by the Sword
        { spell = 152277, type = "ability", talent = 21}, -- Ravager
        { spell = 163201, type = "ability", requiresTarget = true}, -- Execute
        { spell = 167105, type = "ability", debuff = true, requiresTarget = true}, -- Colossus Smash
        { spell = 202168, type = "ability", requiresTarget = true}, -- Impending Victory
        { spell = 212520, type = "ability", talent = 12}, -- Defensive Stance
        { spell = 227847, type = "ability"}, -- Bladestorm
        { spell = 260643, type = "ability", requiresTarget = true, talent = 3}, -- Skullsplitter
        { spell = 260708, type = "ability", buff = true}, -- Sweeping Strikes
        { spell = 262161, type = "ability", debuff = true, requiresTarget = true, talent = 14}, -- Warbreaker
        { spell = 262228, type = "ability", buff = true, talent = 18}, -- Deadly Calm
      },
      icon = 132355
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280212, type = "buff", unit = "player"}, --Bury the Hatchet
        { spell = 280210, type = "buff", unit = "group"}, --Moment of Glory
        { spell = 278826, type = "buff", unit = "player"}, --Crushing Assault
        { spell = 288455, type = "buff", unit = "player"}, --Striking the Anvil
        { spell = 273415, type = "buff", unit = "player"}, --Gathering Storm
        { spell = 275540, type = "buff", unit = "player"}, --Test of Might
        { spell = 288653, type = "debuff", unit = "target"}, --Intimidating Presence
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 236273, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Duel
        { spell = 236273, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Duel
        { spell = 216890, type="ability", pvptalent = 6},-- Spell Reflection
        { spell = 236077, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Disarm
        { spell = 236077, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"]},-- Disarm
        { spell = 236320, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- War Banner
        { spell = 236321, type="buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]},-- War Banner
        { spell = 198817, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Sharpen Blade
        { spell = 198817, type="buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]},-- Sharpen Blade
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
        { spell = 262232, type = "buff", unit = "player", talent = 1}, -- War Machine
        { spell = 32216, type = "buff", unit = "player", talent = 5}, -- Victorious
        { spell = 215572, type = "buff", unit = "player", talent = 15}, -- Frothing Berserker
        { spell = 202539, type = "buff", unit = "player", talent = 9}, -- Furious Slash
        { spell = 18499, type = "buff", unit = "player"}, -- Berserker Rage
        { spell = 1719, type = "buff", unit = "player"}, -- Recklessness
        { spell = 46924, type = "buff", unit = "player", talent = 18}, -- Bladestorm
        { spell = 202164, type = "buff", unit = "player", talent = 11}, -- Bounding Stride
        { spell = 85739, type = "buff", unit = "player"}, -- Whirlwind
        { spell = 280776, type = "buff", unit = "player", talent = 8}, -- Sudden Death
        { spell = 202225, type = "buff", unit = "player", talent = 10}, -- Furious Charge
        { spell = 184362, type = "buff", unit = "player"}, -- Enrage
        { spell = 184364, type = "buff", unit = "player"}, -- Enraged Regeneration
        { spell = 6673, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 97463, type = "buff", unit = "player"}, -- Rallying Cry
      },
      icon = 136224
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 132169, type = "debuff", unit = "target", talent = 6}, -- Storm Bolt
        { spell = 118000, type = "debuff", unit = "target", talent = 17}, -- Dragon Roar
        { spell = 280773, type = "debuff", unit = "target", talent = 21}, -- Siegebreaker
        { spell = 105771, type = "debuff", unit = "target"}, -- Charge
        { spell = 355, type = "debuff", unit = "target"}, -- Taunt
      },
      icon = 132154
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100, type = "ability", requiresTarget = true, talent = {5,6}}, -- Charge    !!TODO: add prefix or name or something when 2 times same talent
        { spell = 100, type = "ability", charges = true, requiresTarget = true, talent = 4, classic = false}, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true}, -- Taunt
        { spell = 1719, type = "ability", buff = true}, -- Recklessness
        { spell = 5246, type = "ability"}, -- Intimidating Shout
        { spell = 5308, type = "ability", requiresTarget = true, overlayGlow = true}, -- Execute
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true}, -- Pummel
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 12323, type = "ability"}, -- Piercing Howl
        { spell = 18499, type = "ability", buff = true}, -- Berserker Rage
        { spell = 23881, type = "ability", requiresTarget = true}, -- Bloodthirst
        { spell = 46924, type = "ability", talent = 18}, -- Bladestorm
        { spell = 57755, type = "ability", requiresTarget = true}, -- Heroic Throw
        { spell = 85288, type = "ability", charges = true, requiresTarget = true, overlayGlow = true}, -- Raging Blow
        { spell = 97462, type = "ability", buff = true}, -- Rallying Cry
        { spell = 100130, type = "ability", requiresTarget = true}, -- Furious Slash
        { spell = 107570, type = "ability", debuff = true, requiresTarget = true, talent = 6}, -- Storm Bolt
        { spell = 118000, type = "ability", talent = 17}, -- Dragon Roar
        { spell = 184364, type = "ability", buff = true}, -- Enraged Regeneration
        { spell = 184367, type = "ability", requiresTarget = true, overlayGlow = true}, -- Rampage
        { spell = 190411, type = "ability"}, -- Whirlwind
        { spell = 202168, type = "ability", requiresTarget = true, talent = 5}, -- Impending Victory
        { spell = 280772, type = "ability", debuff = true, requiresTarget = true, talent = 21}, -- Siegebreaker

      },
      icon = 136012
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280212, type = "buff", unit = "player"}, --Bury the Hatchet
        { spell = 280210, type = "buff", unit = "group"}, --Moment of Glory
        { spell = 288091, type = "buff", unit = "player"}, --Cold Steel, Hot Blood
        { spell = 278134, type = "buff", unit = "player"}, --Infinite Fury
        { spell = 275672, type = "buff", unit = "player"}, --Pulverizing Blows
        { spell = 288653, type = "debuff", unit = "target"}, --Intimidating Presence
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 280746, type="buff", unit = "player", pvptalent = 5},-- Barbarian
        { spell = 213858, type="buff", unit = "player", pvptalent = 6},-- Battle Trance
        { spell = 199203, type="buff", unit = "player", pvptalent = 7},-- Thirst for Battle
        { spell = 199261, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Death Wish
        { spell = 199261, type="buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- Death Wish
        { spell = 236077, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Disarm
        { spell = 236077, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Disarm
        { spell = 216890, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Spell Reflection
        { spell = 216890, type="buff", unit = "player", pvptalent = 13, titleSuffix = L["buff"]},-- Spell Reflection
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
        { spell = 12975, type = "buff", unit = "player"}, -- Last Stand
        { spell = 202164, type = "buff", unit = "player", talent = 5}, -- Bounding Stride
        { spell = 18499, type = "buff", unit = "player"}, -- Berserker Rage
        { spell = 202573, type = "buff", unit = "player", talent = 17}, -- Vengeance: Revenge
        { spell = 871, type = "buff", unit = "player"}, -- Shield Wall
        { spell = 227744, type = "buff", unit = "player", talent = 21}, -- Ravager
        { spell = 202574, type = "buff", unit = "player", talent = 17}, -- Vengeance: Ignore Pain
        { spell = 6673, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 132404, type = "buff", unit = "player"}, -- Shield Block
        { spell = 202602, type = "buff", unit = "player", talent = 1}, -- Into the Fray
        { spell = 97463, type = "buff", unit = "player"}, -- Rallying Cry
        { spell = 190456, type = "buff", unit = "player"}, -- Ignore Pain
        { spell = 23920, type = "buff", unit = "player"}, -- Spell Reflection
        { spell = 107574, type = "buff", unit = "player"}, -- Avatar
        { spell = 147833, type = "buff", unit = "target"}, -- Intervene
        { spell = 223658, type = "buff", unit = "target", talent = 6}, -- Safeguard
        { spell = 288653, type = "debuff", unit = "target"}, --Intimidating Presence

      },
      icon = 1377132
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115767, type = "debuff", unit = "target"}, -- Deep Wounds
        { spell = 1160, type = "debuff", unit = "target"}, -- Demoralizing Shout
        { spell = 355, type = "debuff", unit = "target"}, -- Taunt
        { spell = 132169, type = "debuff", unit = "target", talent = 15}, -- Storm Bolt
        { spell = 105771, type = "debuff", unit = "target"}, -- Charge
        { spell = 5246, type = "debuff", unit = "target"}, -- Intimidating Shout
        { spell = 6343, type = "debuff", unit = "target"}, -- Thunder Clap
        { spell = 132168, type = "debuff", unit = "target"}, -- Shockwave
        { spell = 275335, type = "debuff", unit = "target", talent = 2}, -- Punish
      },
      icon = 132090
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 23922, type = "ability", requiresTarget = true, overlayGlow = true}, -- Shield Slam
        { spell = 355, type = "ability", debuff = true, requiresTarget = true}, -- Taunt
        { spell = 871, type = "ability", buff = true}, -- Shield Wall
        { spell = 1160, type = "ability", debuff = true}, -- Demoralizing Shout
        { spell = 2565, type = "ability", charges = true, buff = true}, -- Shield Block
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true}, -- Intimidating Shout
        { spell = 6343, type = "ability"}, -- Thunder Clap
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true}, -- Pummel
        { spell = 6572, type = "ability", overlayGlow = true}, -- Revenge
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 12975, type = "ability", buff = true}, -- Last Stand
        { spell = 18499, type = "ability", buff = true}, -- Berserker Rage
        { spell = 20243, type = "ability", requiresTarget = true, talent = {16, 17}}, -- Devastate
        { spell = 23920, type = "ability", buff = true}, -- Spell Reflection
        { spell = 23922, type = "ability", requiresTarget = true}, -- Shield Slam
        { spell = 34428, type = "ability", usable = true, requiresTarget = true}, -- Victory Rush
        { spell = 46968, type = "ability"}, -- Shockwave
        { spell = 57755, type = "ability", requiresTarget = true}, -- Heroic Throw
        { spell = 97462, type = "ability"}, -- Rallying Cry
        { spell = 107570, type = "ability", debuff = true, requiresTarget = true, talent = 15}, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true}, -- Avatar
        { spell = 118000, type = "ability", talent = 9}, -- Dragon Roar
        { spell = 198304, type = "ability", charges = true, requiresTarget = true}, -- Intercept
        { spell = 202168, type = "ability", requiresTarget = true, talent = 3}, -- Impending Victory
        { spell = 228920, type = "ability", talent = 21}, -- Ravager

      },
      icon = 134951
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280212, type = "buff", unit = "player"}, --Bury the Hatchet
        { spell = 280210, type = "buff", unit = "group"}, --Moment of Glory
        { spell = 279194, type = "buff", unit = "player"}, --Bloodsport
        { spell = 278124, type = "buff", unit = "player"}, --Brace for Impact
        { spell = 278999, type = "buff", unit = "player"}, --Callous Reprisal
        { spell = 287379, type = "buff", unit = "player"}, --Bastion of Might
        { spell = 273445, type = "buff", unit = "player"}, --Sword and Board
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 213871, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Bodyguard
        { spell = 213871, type="buff", unit = "group", pvptalent = 6, titleSuffix = L["buff"]},-- Bodyguard
        { spell = 198912, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Shield Bash
        { spell = 198912, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Shield Bash
        { spell = 205800, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Oppressor
        { spell = 206891, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"]},-- Oppressor
        { spell = 199085, type="debuff", unit = "target", pvptalent = 10},-- Warpath
        { spell = 206572, type="ability", pvptalent = 11},-- Dragon Charge
        { spell = 236077, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Disarm
        { spell = 236077, type="debuff", unit = "target", pvptalent = 13, titleSuffix = L["debuff"]},-- Disarm
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
        { spell = 1022, type = "buff", unit = "group"}, -- Blessing of Protection
        { spell = 53563, type = "buff", unit = "group"}, -- Beacon of Light
        { spell = 6940, type = "buff", unit = "group"}, -- Blessing of Sacrifice
        { spell = 31821, type = "buff", unit = "player"}, -- Aura Mastery
        { spell = 183415, type = "buff", unit = "player", talent = 12}, -- Aura of Mercy
        { spell = 31884, type = "buff", unit = "player"}, -- Avenging Wrath
        { spell = 498, type = "buff", unit = "player"}, -- Divine Protection
        { spell = 210320, type = "buff", unit = "player", talent = 10}, -- Devotion Aura
        { spell = 642, type = "buff", unit = "player"}, -- Divine Shield
        { spell = 200025, type = "buff", unit = "group", talent = 21}, -- Beacon of Virtue
        { spell = 156910, type = "buff", unit = "group", talent = 20}, -- Beacon of Faith
        { spell = 54149, type = "buff", unit = "player"}, -- Infusion of Light
        { spell = 105809, type = "buff", unit = "player"}, -- Holy Avenger
        { spell = 216331, type = "buff", unit = "player", talent = 17}, -- Avenging Crusader
        { spell = 214202, type = "buff", unit = "player"}, -- Rule of Law
        { spell = 183416, type = "buff", unit = "player", talent = 11}, -- Aura of Sacrifice
        { spell = 1044, type = "buff", unit = "group"}, -- Blessing of Freedom
        { spell = 221883, type = "buff", unit = "player"}, -- Divine Steed
        { spell = 223306, type = "buff", unit = "target", talent = 2}, -- Bestow Faith
      },
      icon = 135964
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 204242, type = "debuff", unit = "target"}, -- Consecration
        { spell = 105421, type = "debuff", unit = "target", talent = 9}, -- Blinding Light
        { spell = 853, type = "debuff", unit = "target"}, -- Hammer of Justice
        { spell = 214222, type = "debuff", unit = "target"}, -- Judgment
        { spell = 196941, type = "debuff", unit = "target", talent = 13}, -- Judgment of Light
        { spell = 20066, type = "debuff", unit = "multi", talent = 8}, -- Repentance
      },
      icon = 135952
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 498, type = "ability", buff = true}, -- Divine Protection
        { spell = 633, type = "ability"}, -- Lay on Hands
        { spell = 642, type = "ability", buff = true}, -- Divine Shield
        { spell = 853, type = "ability", requiresTarget = true}, -- Hammer of Justice
        { spell = 1022, type = "ability"}, -- Blessing of Protection
        { spell = 1044, type = "ability"}, -- Blessing of Freedom
        { spell = 4987, type = "ability"}, -- Cleanse
        { spell = 6940, type = "ability"}, -- Blessing of Sacrifice
        { spell = 20066, type = "ability", requiresTarget = true, talent = 8}, -- Repentance
        { spell = 20473, type = "ability", overlayGlow = true}, -- Holy Shock
        { spell = 26573, type = "ability", totem = true}, -- Consecration
        { spell = 31821, type = "ability", buff = true}, -- Aura Mastery
        { spell = 31884, type = "ability", buff = true, talent = {16, 18}}, -- Avenging Wrath
        { spell = 35395, type = "ability", charges = true, requiresTarget = true}, -- Crusader Strike
        { spell = 85222, type = "ability", overlayGlow = true}, -- Light of Dawn
        { spell = 105809, type = "ability", buff = true, talent = 15}, -- Holy Avenger
        { spell = 114158, type = "ability", talent = 3}, -- Light's Hammer
        { spell = 114165, type = "ability", talent = 14}, -- Holy Prism
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 200025, type = "ability", talent = 21}, -- Beacon of Virtue
        { spell = 214202, type = "ability", charges = true, buff = true}, -- Rule of Law
        { spell = 216331, type = "ability", buff = true, talent = 17}, -- Avenging Crusader
        { spell = 223306, type = "ability", talent = 2}, -- Bestow Faith
        { spell = 275773, type = "ability", debuff = true, requiresTarget = true}, -- Judgment
      },
      icon = 135972
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275468, type = "buff", unit = "player"}, --Divine Revelations
        { spell = 280191, type = "buff", unit = "player"}, --Gallant Steed
        { spell = 278785, type = "buff", unit = "player"}, --Grace of the Justicar
        { spell = 287280, type = "buff", unit = "multi"}, --Glimmer of Light
        { spell = 278145, type = "debuff", unit = "target"}, --Radiant Incandescence
        { spell = 274395, type = "buff", unit = "group"}, --Stalwart Protector
        { spell = 287731, type = "buff", unit = "player"}, --Empyreal Ward
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 199507, type="buff", unit = "group", pvptalent = 4},-- Spreading the Word
        { spell = 216328, type="buff", unit = "target", pvptalent = 5},-- Light's Grace
        { spell = 210294, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Divine Favor
        { spell = 210294, type="buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- Divine Favor
        { spell = 210391, type="buff", unit = "player", pvptalent = 13},-- Darkest before the Dawn
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
        { spell = 203797, type = "buff", unit = "player", talent = 10}, -- Retribution Aura
        { spell = 132403, type = "buff", unit = "player"}, -- Shield of the Righteous
        { spell = 197561, type = "buff", unit = "player"}, -- Avenger's Valor
        { spell = 1044, type = "buff", unit = "group"}, -- Blessing of Freedom
        { spell = 6940, type = "buff", unit = "group"}, -- Blessing of Sacrifice
        { spell = 188370, type = "buff", unit = "player"}, -- Consecration
        { spell = 204150, type = "buff", unit = "player", talent = 18}, -- Aegis of Light
        { spell = 31850, type = "buff", unit = "player"}, -- Ardent Defender
        { spell = 31884, type = "buff", unit = "player"}, -- Avenging Wrath
        { spell = 204018, type = "buff", unit = "player", talent = 12}, -- Blessing of Spellwarding
        { spell = 152262, type = "buff", unit = "player", talent = 21}, -- Seraphim
        { spell = 86659, type = "buff", unit = "player"}, -- Guardian of Ancient Kings
        { spell = 1022, type = "buff", unit = "group"}, -- Blessing of Protection
        { spell = 221883, type = "buff", unit = "player"}, -- Divine Steed
        { spell = 204335, type = "buff", unit = "player"}, -- Aegis of Light
        { spell = 642, type = "buff", unit = "player"}, -- Divine Shield
        { spell = 280375, type = "buff", unit = "player"}, -- Redoubt
      },
      icon = 236265
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 62124, type = "debuff", unit = "target"}, -- Hand of Reckoning
        { spell = 204242, type = "debuff", unit = "target"}, -- Consecration
        { spell = 196941, type = "debuff", unit = "target", talent = 16}, -- Judgment of Light
        { spell = 105421, type = "debuff", unit = "target", talent = 9}, -- Blinding Light
        { spell = 853, type = "debuff", unit = "target"}, -- Hammer of Justice
        { spell = 204301, type = "debuff", unit = "target"}, -- Blessed Hammer
        { spell = 204079, type = "debuff", unit = "target", talent = 13}, -- Final Stand
        { spell = 31935, type = "debuff", unit = "target"}, -- Avenger's Shield
        { spell = 20066, type = "debuff", unit = "multi", talent = 8}, -- Repentance
      },
      icon = 135952
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 633, type = "ability"}, -- Lay on Hands
        { spell = 642, type = "ability", buff = true}, -- Divine Shield
        { spell = 853, type = "ability", requiresTarget = true}, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true}, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true}, -- Blessing of Freedom
        { spell = 6940, type = "ability", debuff = true, requiresTarget = true, unit="player"}, -- Blessing of Sacrifice
        { spell = 20066, type = "ability", requiresTarget = true, talent = 8}, -- Repentance
        { spell = 26573, type = "ability", buff = true}, -- Consecration
        { spell = 31850, type = "ability", buff = true}, -- Ardent Defender
        { spell = 31884, type = "ability", buff = true}, -- Avenging Wrath
        { spell = 31935, type = "ability", requiresTarget = true, overlayGlow = true}, -- Avenger's Shield
        { spell = 53595, type = "ability"}, -- Hammer of the Righteous                  Couldn't find this spell
        { spell = 53600, type = "ability", charges = true, buff = true}, -- Shield of the Righteous
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true}, -- Hand of Reckoning
        { spell = 86659, type = "ability", buff = true}, -- Guardian of Ancient Kings
        { spell = 96231, type = "ability", requiresTarget = true}, -- Rebuke
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 152262, type = "ability", buff = true, talent = 21}, -- Seraphim
        { spell = 184092, type = "ability"}, -- Light of the Protector
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 204018, type = "ability", talent = 12}, -- Blessing of Spellwarding
        { spell = 204019, type = "ability", charges = true, debuff = true}, -- Blessed Hammer
        { spell = 204035, type = "ability"}, -- Bastion of Light
        { spell = 204150, type = "ability", buff = true}, -- Aegis of Light
        { spell = 213644, type = "ability"}, -- Cleanse Toxins
        { spell = 213652, type = "ability"}, -- Hand of the Protector
        { spell = 275779, type = "ability", debuff = true, requiresTarget = true}, -- Judgment
      },
      icon = 135874
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272979, type = "buff", unit = "player"}, --Bulwark of Light
        { spell = 280191, type = "buff", unit = "player"}, --Gallant Steed
        { spell = 278785, type = "buff", unit = "group"}, --Grace of the Justicar
        { spell = 275481, type = "buff", unit = "player"}, --Inner Light
        { spell = 279397, type = "buff", unit = "player"}, --Inspiring Vanguard
        { spell = 278574, type = "buff", unit = "player"}, --Judicious Defense
        { spell = 278954, type = "buff", unit = "player"}, --Soaring Shield
        { spell = 274395, type = "buff", unit = "group"}, --Stalwart Protector
        { spell = 287731, type = "buff", unit = "player"}, --Empyreal Ward
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 228049, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Guardian of the Forgotten Queen
        { spell = 228050, type="buff", unit = "group", pvptalent = 5, titleSuffix = L["buff"]},-- Guardian of the Forgotten Queen
        { spell = 216857, type="buff", unit = "target", pvptalent = 6},-- Guarded by the Light
        { spell = 236186, type="ability", pvptalent = 9},-- Cleansing Light
        { spell = 215652, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Shield of Virtue
        { spell = 217824, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Shield of Virtue
        { spell = 207028, type="ability", pvptalent = 15, titleSuffix = L["cooldown"]},-- Inquisition
        { spell = 206891, type="debuff", unit = "target", pvptalent = 15, titleSuffix = L["buff"]},-- Inquisition
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
        { spell = 267611, type = "buff", unit = "player", talent = 2}, -- Righteous Verdict
        { spell = 205191, type = "buff", unit = "player", talent = 15}, -- Eye for an Eye
        { spell = 1022, type = "buff", unit = "group"}, -- Blessing of Protection
        { spell = 184662, type = "buff", unit = "player"}, -- Shield of Vengeance
        { spell = 271581, type = "buff", unit = "player", talent = 10}, -- Divine Judgment
        { spell = 84963, type = "buff", unit = "player", talent = 21}, -- Inquisition
        { spell = 203538, type = "buff", unit = "group"}, -- Greater Blessing of Kings
        { spell = 221883, type = "buff", unit = "player"}, -- Divine Steed
        { spell = 642, type = "buff", unit = "player"}, -- Divine Shield
        { spell = 203539, type = "buff", unit = "group"}, -- Greater Blessing of Wisdom
        { spell = 114250, type = "buff", unit = "player", talent = 16}, -- Selfless Healer
        { spell = 31884, type = "buff", unit = "player"}, -- Avenging Wrath
        { spell = 269571, type = "buff", unit = "player", talent = 1}, -- Zeal
        { spell = 281178, type = "buff", unit = "player", talent = 5}, -- Blade of Wrath
        { spell = 1044, type = "buff", unit = "group"}, -- Blessing of Freedom
        { spell = 209785, type = "buff", unit = "player", talent = 4}, -- Fires of Justice
        { spell = 223819, type = "buff", unit = "player", talent = 19}, -- Divine Purpose
        { spell = 183436, type = "buff", unit = "player"}, -- Retribution
      },
      icon = 135993
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 62124, type = "debuff", unit = "target"}, -- Hand of Reckoning
        { spell = 197277, type = "debuff", unit = "target"}, -- Judgment
        { spell = 267799, type = "debuff", unit = "target", talent = 3}, -- Execution Sentence
        { spell = 105421, type = "debuff", unit = "target"}, -- Blinding Light
        { spell = 853, type = "debuff", unit = "target"}, -- Hammer of Justice
        { spell = 183218, type = "debuff", unit = "target"}, -- Hand of Hindrance
        { spell = 20066, type = "debuff", unit = "multi", talent = 8}, -- Repentance
        { spell = 255937, type = "debuff", unit = "target", talent = 12}, -- Wake of Ashes

      },
      icon = 135952
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 633, type = "ability"}, -- Lay on Hands
        { spell = 642, type = "ability", buff = true}, -- Divine Shield
        { spell = 853, type = "ability", requiresTarget = true}, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true}, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true}, -- Blessing of Freedom
        { spell = 20066, type = "ability", requiresTarget = true, talent = 8}, -- Repentance
        { spell = 20271, type = "ability", debuff = true, requiresTarget = true}, -- Judgment
        { spell = 24275, type = "ability", talent = 6}, -- Hammer of Wrath
        { spell = 31884, type = "ability", buff = true}, -- Avenging Wrath
        { spell = 35395, type = "ability", charges = true, requiresTarget = true}, -- Crusader Strike
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true}, -- Hand of Reckoning
        { spell = 96231, type = "ability", requiresTarget = true}, -- Rebuke
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 183218, type = "ability", debuff = true, requiresTarget = true}, -- Hand of Hindrance
        { spell = 184575, type = "ability", requiresTarget = true, overlayGlow = true}, -- Blade of Justice
        { spell = 184662, type = "ability", buff = true}, -- Shield of Vengeance
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 205191, type = "ability", buff = true, talent = 15}, -- Eye for an Eye
        { spell = 205228, type = "ability", totem = true, talent = 11}, -- Consecration
        { spell = 210191, type = "ability", charges = true, talent = 18}, -- Word of Glory
        { spell = 213644, type = "ability"}, -- Cleanse Toxins
        { spell = 215661, type = "ability", requiresTarget = true, talent = 17}, -- Justiciar's Vengeance
        { spell = 255937, type = "ability", debuff = true, requiresTarget = true, talent = 11}, -- Wake of Ashes
        { spell = 267798, type = "ability", debuff = true, requiresTarget = true, talent = 3}, -- Execution Sentence
      },
      icon = 135891
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272903, type = "buff", unit = "player"}, --Avenger's Might
        { spell = 286393, type = "buff", unit = "player"}, --Empyrean Power
        { spell = 273481, type = "buff", unit = "player"}, --Expurgation
        { spell = 280191, type = "buff", unit = "player"}, --Gallant Steed
        { spell = 278785, type = "buff", unit = "group"}, --Grace of the Justicar
        { spell = 279204, type = "buff", unit = "player"}, --Relentless Inquisitor
        { spell = 286232, type = "buff", unit = "player"}, --Light's Decree
        { spell = 274395, type = "buff", unit = "group"}, --Stalwart Protector
        { spell = 287731, type = "buff", unit = "player"}, --Empyreal Ward
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 236186, type="ability", pvptalent = 4},-- Cleansing Light
        { spell = 247675, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Hammer of Reckoning
        { spell = 247675, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Hammer of Reckoning
        { spell = 210323, type="buff", unit = "target", pvptalent = 9},-- Vengeance Aura
        { spell = 210256, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Blessing of Sanctuary
        { spell = 210256, type="buff", unit = "target", pvptalent = 10, titleSuffix = L["buff"]},-- Blessing of Sanctuary
        { spell = 287947, type="buff", unit = "player", pvptalent = 11},-- Ultimate Retribution
        { spell = 246807, type="buff", unit = "target", pvptalent = 12},-- Lawbringer
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
        { spell = 246851, type = "buff", unit = "player"}, -- Barbed Shot
        { spell = 35079, type = "buff", unit = "player"}, -- Misdirection
        { spell = 231390, type = "buff", unit = "player", talent = 7}, -- Trailblazer
        { spell = 186258, type = "buff", unit = "player"}, -- Aspect of the Cheetah
        { spell = 264667, type = "buff", unit = "player"}, -- Primal Rage
        { spell = 257946, type = "buff", unit = "player"}, -- Thrill of the Hunt
        { spell = 19574, type = "buff", unit = "player"}, -- Bestial Wrath
        { spell = 268877, type = "buff", unit = "player"}, -- Beast Cleave
        { spell = 264663, type = "buff", unit = "player"}, -- Predator's Thirst
        { spell = 118922, type = "buff", unit = "player", talent = 14}, -- Posthaste
        { spell = 193530, type = "buff", unit = "player"}, -- Aspect of the Wild
        { spell = 5384, type = "buff", unit = "player"}, -- Feign Death
        { spell = 199483, type = "buff", unit = "player"}, -- Camouflage
        { spell = 281036, type = "buff", unit = "player", talent = 3}, -- Dire Beast
        { spell = 186265, type = "buff", unit = "player"}, -- Aspect of the Turtle
        { spell = 6197, type = "buff", unit = "player"}, -- Eagle Eye
        { spell = 246152, type = "buff", unit = "player"}, -- Barbed Shot
        { spell = 24450, type = "buff", unit = "pet"}, -- Prowl
        { spell = 272790, type = "buff", unit = "pet"}, -- Frenzy
        { spell = 136, type = "buff", unit = "pet"}, -- Mend Pet
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 135299, type = "debuff", unit = "target"}, -- Tar Trap
        { spell = 217200, type = "debuff", unit = "target"}, -- Barbed Shot
        { spell = 117405, type = "debuff", unit = "target", talent = 15}, -- Binding Shot
        { spell = 3355, type = "debuff", unit = "multi"}, -- Freezing Trap
        { spell = 2649, type = "debuff", unit = "target"}, -- Growl
        { spell = 24394, type = "debuff", unit = "target"}, -- Intimidation
        { spell = 5116, type = "debuff", unit = "target"}, -- Concussive Shot
      },
      icon = 135860
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 781, type = "ability"}, -- Disengage
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 2649, type = "ability", requiresTarget = true, debuff = true}, -- Growl
        { spell = 5116, type = "ability", requiresTarget = true}, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true}, -- Feign Death
        { spell = 16827, type = "ability", requiresTarget = true}, -- Claw
        { spell = 19574, type = "ability", buff = true}, -- Bestial Wrath
        { spell = 19577, type = "ability", requiresTarget = true, debuff = true}, -- Intimidation
        { spell = 24450, type = "ability"}, -- Prowl
        { spell = 34026, type = "ability"}, -- Kill Command
        { spell = 34477, type = "ability", requiresTarget = true}, -- Misdirection
        { spell = 53209, type = "ability", requiresTarget = true, talent = 6}, -- Chimaera Shot
        { spell = 109248, type = "ability", requiresTarget = true, talent = 15}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 120360, type = "ability", talent = 17}, -- Barrage
        { spell = 120679, type = "ability", requiresTarget = true, buff = true, talent = 3}, -- Dire Beast
        { spell = 131894, type = "ability", requiresTarget = true, talent = 12}, -- A Murder of Crows
        { spell = 147362, type = "ability", requiresTarget = true}, -- Counter Shot
        { spell = 186257, type = "ability", buff = true}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true}, -- Aspect of the Turtle
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 193530, type = "ability", buff = true}, -- Aspect of the Wild
        { spell = 199483, type = "ability", talent = 9}, -- Camouflage
        { spell = 201430, type = "ability", talent = 18}, -- Stampede
        { spell = 217200, type = "ability", charges = true, requiresTarget = true, overlayGlow = true}, -- Barbed Shot
        { spell = 264667, type = "ability", buff = true}, -- Primal Rage
        { spell = 264735, type = "ability", unit = "pet", buff = true}, -- Survival of the Fittest
        { spell = 90361, type = "ability",  unit = "pet", buff = true}, -- Spirit Mend
        { spell = 58875, type = "ability",  unit = "pet", buff = true}, -- Spirit Walk
        { spell = 264265, type = "ability"}, -- Spirit Shock
      },
      icon = 135130
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277916, type = "debuff", unit = "target"}, --Cobra's Bite
        { spell = 274443, type = "buff", unit = "player"}, --Dance of Death
        { spell = 280170, type = "buff", unit = "player"}, --Duck and Cover
        { spell = 269625, type = "buff", unit = "player"}, --Flashing Fangs
        { spell = 273264, type = "buff", unit = "player"}, --Haze of Rage
        { spell = 279810, type = "buff", unit = "player"}, --Primal Instincts
        { spell = 263821, type = "buff", unit = "player"}, --Ride the Lightning
        { spell = 264195, type = "buff", unit = "player"}, --Rotting Jaws
        { spell = 274357, type = "buff", unit = "player"}, --Shellshock
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 204205, type="buff", unit = "player", pvptalent = 4},-- Wild Protector
        { spell = 208652, type="ability", pvptalent = 5},-- Dire Beast: Hawk
        { spell = 205691, type="ability", pvptalent = 6},-- Dire Beast: Basilisk
        { spell = 248518, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Interlope
        { spell = 248519, type="buff", unit = "group", pvptalent = 7, titleSuffix = L["buff"]},-- Interlope
        { spell = 53480, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Roar of Sacrifice
        { spell = 53480, type="buff", unit = "group", pvptalent = 10, titleSuffix = L["buff"]},-- Roar of Sacrifice
        { spell = 236776, type="ability", pvptalent = 11},-- Hi-Explosive Trap
        { spell = 202900, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Scorpid Sting
        { spell = 202900, type="debuff", unit = "target", pvptalent = 12, titleSuffix = L["debuff"]},-- Scorpid Sting
        { spell = 202914, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Spider Sting
        { spell = 202914, type="debuff", unit = "target", pvptalent = 13, titleSuffix = L["debuff"]},-- Spider Sting
        { spell = 202797, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Viper Sting
        { spell = 202797, type="debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"]},-- Viper Sting
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
        { spell = 35079, type = "buff", unit = "player"}, -- Misdirection
        { spell = 231390, type = "buff", unit = "player", talent = 7}, -- Trailblazer
        { spell = 186258, type = "buff", unit = "player"}, -- Aspect of the Cheetah
        { spell = 264667, type = "buff", unit = "player"}, -- Primal Rage
        { spell = 260395, type = "buff", unit = "player", talent = 16}, -- Lethal Shots
        { spell = 194594, type = "buff", unit = "player", talent = 20}, -- Lock and Load
        { spell = 257044, type = "buff", unit = "player"}, -- Rapid Fire
        { spell = 164273, type = "buff", unit = "player"}, -- Lone Wolf
        { spell = 6197, type = "buff", unit = "player"}, -- Eagle Eye
        { spell = 257622, type = "buff", unit = "player"}, -- Trick Shots
        { spell = 193526, type = "buff", unit = "player"}, -- Trueshot
        { spell = 260242, type = "buff", unit = "player"}, -- Precise Shots
        { spell = 5384, type = "buff", unit = "player"}, -- Feign Death
        { spell = 260402, type = "buff", unit = "player", talent = 18}, -- Double Tap
        { spell = 118922, type = "buff", unit = "player", talent = 14}, -- Posthaste
        { spell = 186265, type = "buff", unit = "player"}, -- Aspect of the Turtle
        { spell = 193534, type = "buff", unit = "player", talent = 10}, -- Steady Focus
        { spell = 264663, type = "buff", unit = "player"}, -- Predator's Thirst
        { spell = 199483, type = "buff", unit = "player", talent = 9}, -- Camouflage
        { spell = 24450, type = "buff", unit = "pet"}, -- Prowl
        { spell = 136, type = "buff", unit = "pet"}, -- Mend Pet
        { spell = 264735, type = "ability", unit = "pet", buff = true}, -- Survival of the Fittest
      },
      icon = 461846
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 135299, type = "debuff", unit = "target"}, -- Tar Trap
        { spell = 5116, type = "debuff", unit = "target"}, -- Concussive Shot
        { spell = 186387, type = "debuff", unit = "target"}, -- Bursting Shot
        { spell = 3355, type = "debuff", unit = "multi"}, -- Freezing Trap
        { spell = 271788, type = "debuff", unit = "target"}, -- Serpent Sting
        { spell = 257284, type = "debuff", unit = "target", talent = 12}, -- Hunter's Mark
        { spell = 131894, type = "debuff", unit = "target", talent = 3}, -- A Murder of Crows

      },
      icon = 236188
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 781, type = "ability"}, -- Disengage
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 5116, type = "ability", requiresTarget = true}, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true}, -- Feign Death
        { spell = 19434, type = "ability", requiresTarget = true, charges = true, overlayGlow = true}, -- Aimed Shot
        { spell = 34477, type = "ability", requiresTarget = true}, -- Misdirection
        { spell = 109248, type = "ability", requiresTarget = true, talent = 15}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 120360, type = "ability", talent = 17}, -- Barrage
        { spell = 131894, type = "ability", talent = 3}, -- A Murder of Crows
        { spell = 147362, type = "ability", requiresTarget = true}, -- Counter Shot
        { spell = 185358, type = "ability", requiresTarget = true, overlayGlow = true}, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true}, -- Aspect of the Turtle
        { spell = 186387, type = "ability"}, -- Bursting Shot
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 193526, type = "ability", buff = true}, -- Trueshot
        { spell = 198670, type = "ability", talent = 21}, -- Piercing Shot
        { spell = 199483, type = "ability", talent = 9}, -- Camouflage
        { spell = 212431, type = "ability", talent = 6}, -- Explosive Shot
        { spell = 257044, type = "ability", requiresTarget = true, overlayGlow = true}, -- Rapid Fire
        { spell = 257620, type = "ability", requiresTarget = true}, -- Multi-Shot
        { spell = 260402, type = "ability", buff = true, talent = 18}, -- Double Tap
        { spell = 264667, type = "ability", buff = true}, -- Primal Rage
        { spell = 264735, type = "ability", unit = "pet", buff = true}, -- Survival of the Fittest
      },
      icon = 132329
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 263814, type = "buff", unit = "player"}, --Arrowstorm
        { spell = 280170, type = "buff", unit = "player"}, --Duck and Cover
        { spell = 272733, type = "buff", unit = "player"}, --In The Rhythm
        { spell = 263821, type = "buff", unit = "player"}, --Ride the Lightning
        { spell = 274357, type = "buff", unit = "player"}, --Shellshock
        { spell = 277959, type = "debuff", unit = "target"}, --Steady Aim
        { spell = 274447, type = "buff", unit = "player"}, --Unerring Vision
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 202797, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Viper Sting
        { spell = 202797, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Viper Sting
        { spell = 202900, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Scorpid Sting
        { spell = 202900, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Scorpid Sting
        { spell = 202914, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Spider Sting
        { spell = 202914, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Spider Sting
        { spell = 53480, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Roar of Sacrifice
        { spell = 53480, type="buff", unit = "group", pvptalent = 9, titleSuffix = L["buff"]},-- Roar of Sacrifice
        { spell = 203155, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Sniper Shot
        { spell = 203155, type="buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]},-- Sniper Shot
        { spell = 213691, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Scatter Shot
        { spell = 213691, type="debuff", unit = "target", pvptalent = 13, titleSuffix = L["debuff"]},-- Scatter Shot
        { spell = 236776, type="ability", pvptalent = 15},-- Hi-Explosive Trap
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
        { spell = 199483, type = "buff", unit = "player", talent = 9}, -- Camouflage
        { spell = 35079, type = "buff", unit = "player"}, -- Misdirection
        { spell = 231390, type = "buff", unit = "player", talent = 7 }, -- Trailblazer
        { spell = 186258, type = "buff", unit = "player"}, -- Aspect of the Cheetah
        { spell = 264667, type = "buff", unit = "player"}, -- Primal Rage
        { spell = 259388, type = "buff", unit = "player", talent = 17 }, -- Mongoose Fury
        { spell = 225788, type = "buff", unit = "player"}, -- Sign of the Emissary
        { spell = 268552, type = "buff", unit = "player", talent = 1 }, -- Viper's Venom
        { spell = 260249, type = "buff", unit = "player"}, -- Predator
        { spell = 6197, type = "buff", unit = "player"}, -- Eagle Eye
        { spell = 264663, type = "buff", unit = "player"}, -- Predator's Thirst
        { spell = 266779, type = "buff", unit = "player"}, -- Coordinated Assault
        { spell = 5384, type = "buff", unit = "player"}, -- Feign Death
        { spell = 260286, type = "buff", unit = "player", talent = 16 }, -- Tip of the Spear
        { spell = 186265, type = "buff", unit = "player"}, -- Aspect of the Turtle
        { spell = 118922, type = "buff", unit = "player", talent = 14 }, -- Posthaste
        { spell = 265898, type = "buff", unit = "player", talent = 2 }, -- Terms of Engagement
        { spell = 186289, type = "buff", unit = "player"}, -- Aspect of the Eagle
        { spell = 264663, type = "buff", unit = "pet"}, -- Predator's Thirst
        { spell = 266779, type = "buff", unit = "pet"}, -- Coordinated Assault
        { spell = 263892, type = "buff", unit = "pet"}, -- Catlike Reflexes
        { spell = 61684, type = "buff", unit = "pet"}, -- Dash
        { spell = 136, type = "buff", unit = "pet"}, -- Mend Pet
        { spell = 260249, type = "buff", unit = "pet"}, -- Predator
        { spell = 24450, type = "buff", unit = "pet"}, -- Prowl

      },
      icon = 1376044
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 270339, type = "debuff", unit = "target", talent = 20 }, -- Shrapnel Bomb
        { spell = 270332, type = "debuff", unit = "target", talent = 20 }, -- Pheromone Bomb
        { spell = 24394, type = "debuff", unit = "target"}, -- Intimidation
        { spell = 135299, type = "debuff", unit = "target"}, -- Tar Trap
        { spell = 270343, type = "debuff", unit = "target"}, -- Internal Bleeding
        { spell = 195645, type = "debuff", unit = "target"}, -- Wing Clip
        { spell = 269747, type = "debuff", unit = "target"}, -- Wildfire Bomb
        { spell = 162487, type = "debuff", unit = "target", talent = 11 }, -- Steel Trap
        { spell = 131894, type = "debuff", unit = "target", talent = 12 }, -- A Murder of Crows
        { spell = 259277, type = "debuff", unit = "target", talent = 10 }, -- Kill Command
        { spell = 190927, type = "debuff", unit = "target"}, -- Harpoon
        { spell = 162480, type = "debuff", unit = "target"}, -- Steel Trap
        { spell = 2649, type = "debuff", unit = "target"}, -- Growl
        { spell = 3355, type = "debuff", unit = "multi"}, -- Freezing Trap
        { spell = 259491, type = "debuff", unit = "target"}, -- Serpent Sting
        { spell = 271049, type = "debuff", unit = "target"}, -- Volatile Bomb
        { spell = 117405, type = "debuff", unit = "target", talent = 15 }, -- Binding Shot

      },
      icon = 132309
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 781, type = "ability"}, -- Disengage
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 2649, type = "ability", requiresTarget = true, debuff = true}, -- Growl
        { spell = 5384, type = "ability", buff = true}, -- Feign Death
        { spell = 16827, type = "ability", requiresTarget = true}, -- Claw
        { spell = 19434, type = "ability", requiresTarget = true}, -- Aimed Shot
        { spell = 19577, type = "ability", requiresTarget = true, debuff = true}, -- Intimidation
        { spell = 24450, type = "ability"}, -- Prowl
        { spell = 34477, type = "ability", requiresTarget = true}, -- Misdirection
        { spell = 61684, type = "ability"}, -- Dash
        { spell = 109248, type = "ability", requiresTarget = true}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 131894, type = "ability", talent = 12}, -- A Murder of Crows
        { spell = 162488, type = "ability", talent = 11}, -- Steel Trap
        { spell = 186257, type = "ability", buff = true}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true}, -- Aspect of the Turtle
        { spell = 186289, type = "ability", buff = true}, -- Aspect of the Eagle
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 187707, type = "ability", requiresTarget = true}, -- Muzzle
        { spell = 187708, type = "ability"}, -- Carve
        { spell = 190925, type = "ability", requiresTarget = true}, -- Harpoon
        { spell = 199483, type = "ability", talent = 9}, -- Camouflage
        { spell = 212436, type = "ability", charges = true, talent = 6 }, -- Butchery
        { spell = 259391, type = "ability", requiresTarget = true, talent = 21 }, -- Chakrams
        { spell = 259489, type = "ability", requiresTarget = true, overlayGlow = true}, -- Kill Command
        { spell = 259491, type = "ability", requiresTarget = true, overlayGlow = true}, -- Serpent Sting
        { spell = 259495, type = "ability", requiresTarget = true}, -- Wildfire Bomb
        { spell = 263892, type = "ability"}, -- Catlike Reflexes
        { spell = 264667, type = "ability", buff = true}, -- Primal Rage
        { spell = 266779, type = "ability", buff = true}, -- Coordinated Assault
        { spell = 269751, type = "ability", requiresTarget = true, talent = 18 }, -- Flanking Strike
        { spell = 270323, type = "ability", talent = 20 }, -- Pheromone Bomb
        { spell = 270335, type = "ability", talent = 20}, -- Shrapnel Bomb
        { spell = 271045, type = "ability", talent = 20}, -- Volatile Bomb
        { spell = 272678, type = "ability", buff = true}, -- Primal Rage
      },
      icon = 236184
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277969, type = "buff", unit = "player"}, --Blur of Talons
        { spell = 280170, type = "buff", unit = "player"}, --Duck and Cover
        { spell = 273286, type = "buff", unit = "player"}, --Latent Poison
        { spell = 263821, type = "buff", unit = "player"}, --Ride the Lightning
        { spell = 274357, type = "buff", unit = "player"}, --Shellshock
        { spell = 288573, type = "buff", unit = "player"}, --Prime Intuition
        { spell = 263818, type = "buff", unit = "player"}, --Vigorous Wings
        { spell = 264199, type = "buff", unit = "player"}, --Whirling Rebound

      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 202914, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Spider Sting
        { spell = 202914, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Spider Sting
        { spell = 202900, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Scorpid Sting
        { spell = 202900, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuiff"]},-- Scorpid Sting
        { spell = 212638, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Tracker's Net
        { spell = 212638, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Tracker's Net
        { spell = 202797, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Viper Sting
        { spell = 202797, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"]},-- Viper Sting
        { spell = 212640, type="ability", pvptalent = 11},-- Mending Bandage
        { spell = 53480, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Roar of Sacrifice
        { spell = 53480, type="buff", unit = "group", pvptalent = 12, titleSuffix = L["buff"]},-- Roar of Sacrifice
        { spell = 203268, type="debuff", unit = "target", pvptalent = 13},-- Sticky Tar
        { spell = 236776, type="ability", pvptalent = 15},-- Hi-Explosive Trap
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
  ["classic"] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 14177, type = "buff", unit = "player"}, -- Cold Blood
        { spell = 14149, type = "buff", unit = "player"}, -- Remorseless
        { spell = 14278, type = "buff", unit = "player"}, -- Ghostly Strike
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 14251, type = "debuff", unit = "target"}, -- Riposte
        { spell = 11198, type = "debuff", unit = "target"}, -- Expose Armor
        { spell = 18425, type = "debuff", unit = "target"}, -- Kick - Silenced
        { spell = 17348, type = "debuff", unit = "target"}, -- Hemorrhage
        { spell = 14183, type = "debuff", unit = "target"}, -- Premeditation
      },
      icon = 132302
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 11198, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Expose Armor
        { spell = 6774, type = "ability", requiresTarget = true, usable = true, buff = true}, -- Slice and Dice
        { spell = 14177, type = "ability", buff = true}, -- Cold Blood
        { spell = 14251, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Riposte
        { spell = 17348, type = "ability", requiresTarget = true, debuff = true}, -- Hemorrhage
        { spell = 14185, type = "ability"}, -- Preparation
        { spell = 921, type = "ability", requiresTarget = true, usable = true}, -- Pick Pocket
        { spell = 14183, type = "ability", requiresTarget = true, debuff = true}, -- Premeditation
        { spell = 14278, type = "ability", requiresTarget = true, buff = true}, -- Ghostly Strike
      },
      icon = 132350
    },
  },
  [1] = { -- Assassination
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 121153, type = "buff", unit = "player"}, -- Blindside
        { spell = 5277, type = "buff", unit = "player"}, -- Evasion
        { spell = 8679, type = "buff", unit = "player"}, -- Wound Poison
        { spell = 57934, type = "buff", unit = "player"}, -- Tricks of the Trade
        { spell = 108211, type = "buff", unit = "player", talent = 10}, -- Leeching Poison
        { spell = 2823, type = "buff", unit = "player"}, -- Deadly Poison
        { spell = 193641, type = "buff", unit = "player", talent = 2}, -- Elaborate Planning
        { spell = 115192, type = "buff", unit = "player", talent = 5}, -- Subterfuge
        { spell = 114018, type = "buff", unit = "player"}, -- Shroud of Concealment
        { spell = 32645, type = "buff", unit = "player"}, -- Envenom
        { spell = 36554, type = "buff", unit = "player"}, -- Shadowstep
        { spell = 185311, type = "buff", unit = "player"}, -- Crimson Vial
        { spell = 270070, type = "buff", unit = "player", talent = 20}, -- Hidden Blades
        { spell = 256735, type = "buff", unit = "player", talent = 6}, -- Master Assassin
        { spell = 1966, type = "buff", unit = "player", classic = false}, -- Feint
        { spell = 1784, type = "buff", unit = "player"}, -- Stealth
        { spell = 31224, type = "buff", unit = "player"}, -- Cloak of Shadows
        { spell = 11327, type = "buff", unit = "player"}, -- Vanish
        { spell = 3408, type = "buff", unit = "player"}, -- Crippling Poison
        { spell = 2983, type = "buff", unit = "player"}, -- Sprint
        { spell = 45182, type = "buff", unit = "player", talent = 11 }, -- Cheating Death
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 137619, type = "debuff", unit = "target", talent = 9}, -- Marked for Death
        { spell = 1330, type = "debuff", unit = "target", classic = false}, -- Garrote - Silence
        { spell = 256148, type = "debuff", unit = "target", talent = 14}, -- Iron Wire
        { spell = 154953, type = "debuff", unit = "target", talent = 13}, -- Internal Bleeding
        { spell = 1833, type = "debuff", unit = "target"}, -- Cheap Shot
        { spell = 6770, type = "debuff", unit = "multi"}, -- Sap
        { spell = 255909, type = "debuff", unit = "target", talent = 15}, -- Prey on the Weak
        { spell = 703, type = "debuff", unit = "target"}, -- Garrote
        { spell = 245389, type = "debuff", unit = "target", talent = 17}, -- Toxic Blade
        { spell = 2818, type = "debuff", unit = "target"}, -- Deadly Poison
        { spell = 3409, type = "debuff", unit = "target"}, -- Crippling Poison
        { spell = 2094, type = "debuff", unit = "multi"}, -- Blind
        { spell = 408, type = "debuff", unit = "target"}, -- Kidney Shot
        { spell = 121411, type = "debuff", unit = "target", talent = 21}, -- Crimson Tempest
        { spell = 79140, type = "debuff", unit = "target"}, -- Vendetta
        { spell = 1943, type = "debuff", unit = "target"}, -- Rupture
        { spell = 8680, type = "debuff", unit = "target", classic = false}, -- Wound Poison
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 132302
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 408, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Kidney Shot
        { spell = 703, type = "ability", requiresTarget = true, debuff = true}, -- Garrote
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1752, type = "ability", requiresTarget = true}, -- Sinister Strike / Mutilate
        { spell = 1766, type = "ability", requiresTarget = true}, -- Kick
        { spell = 1784, type = "ability", buff = true}, -- Stealth
        { spell = 1833, type = "ability", usable = true, requiresTarget = true, debuff = true}, -- Cheap Shot
        { spell = 1856, type = "ability", buff = true}, -- Vanish
        { spell = 1943, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Rupture
        { spell = 1966, type = "ability", buff = true}, -- Feint
        { spell = 2094, type = "ability", requiresTarget = true}, -- Blind
        { spell = 2983, type = "ability", buff = true}, -- Sprint
        { spell = 51723, type = "ability"}, -- Fan of Knives
        { spell = 57934, type = "ability", requiresTarget = true}, -- Tricks of the Trade
        { spell = 6770, type = "ability", usable = true, requiresTarget = true, debuff = true}, -- Sap
        { spell = 5277, type = "ability", buff = true}, -- Evasion
        { spell = 31224, type = "ability", buff = true}, -- Cloak of Shadows
        { spell = 36554, type = "ability", requiresTarget = true}, -- Shadowstep
        { spell = 79140, type = "ability", requiresTarget = true, debuff = true}, -- Vendetta
        { spell = 114018, type = "ability", usable = true, buff = true}, -- Shroud of Concealment
        { spell = 115191, type = "ability", buff = true}, -- Stealth
        { spell = 137619, type = "ability", requiresTarget = true, debuff = true, talent = 9}, -- Marked for Death
        { spell = 185311, type = "ability", buff = true}, -- Crimson Vial
        { spell = 196819, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Envenom
        { spell = 200806, type = "ability", requiresTarget = true, usable = true, talent = 18}, -- Exsanguinate
        { spell = 245388, type = "ability", requiresTarget = true, talent = 17}, -- Toxic Blade
        { spell = 57934, type = "ability", requiresTarget = true, debuff = true}, -- Tricks of the Trade
      },
      icon = 132350
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 274695, type = "buff", unit = "group"}, --Footpad
        { spell = 280200, type = "buff", unit = "player"}, --Shrouded Mantle
        { spell = 286581, type = "debuff", unit = "target"}, --Nothing Personal
        { spell = 277731, type = "buff", unit = "player"}, --Scent of Blood
        { spell = 279703, type = "buff", unit = "player"}, --Shrouded Suffocation
        { spell = 288158, type = "buff", unit = "player"}, --Lying in Wait
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 269513, type="ability", pvptalent = 4},-- Death from Above
        { spell = 197003, type="buff", unit = "target", pvptalent = 5},-- Maneuverability
        { spell = 248744, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Shiv
        { spell = 248744, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Shiv
        { spell = 197051, type="debuff", unit = "target", pvptalent = 8},-- Mind-Numbing Poison
        { spell = 198222, type="debuff", unit = "target", pvptalent = 9},-- System Shock
        { spell = 206328, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Neurotoxin
        { spell = 197091, type="debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]},-- Neurotoxin
        { spell = 198097, type="debuff", unit = "target", pvptalent = 13},-- Creeping Venom
        { spell = 212182, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Smoke Bomb
        { spell = 212183, type="debuff", unit = "player", pvptalent = 14, titleSuffix = L["buff"]},-- Smoke Bomb
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
        { spell = 193357, type = "buff", unit = "player"}, -- Ruthless Precision
        { spell = 199600, type = "buff", unit = "player"}, -- Buried Treasure
        { spell = 193358, type = "buff", unit = "player"}, -- Grand Melee
        { spell = 51690, type = "buff", unit = "player", talent = 21}, -- Killing Spree
        { spell = 114018, type = "buff", unit = "player"}, -- Shroud of Concealment
        { spell = 271896, type = "buff", unit = "player", talent = 20}, -- Blade Rush
        { spell = 5171, type = "buff", unit = "player", talent = 18}, -- Slice and Dice
        { spell = 13750, type = "buff", unit = "player"}, -- Adrenaline Rush
        { spell = 193359, type = "buff", unit = "player"}, -- True Bearing
        { spell = 199603, type = "buff", unit = "player"}, -- Skull and Crossbones
        { spell = 199754, type = "buff", unit = "player"}, -- Riposte
        { spell = 185311, type = "buff", unit = "player"}, -- Crimson Vial
        { spell = 2983, type = "buff", unit = "player"}, -- Sprint
        { spell = 1966, type = "buff", unit = "player", classic = false}, -- Feint
        { spell = 193538, type = "buff", unit = "player", talent = 17}, -- Alacrity
        { spell = 1784, type = "buff", unit = "player"}, -- Stealth
        { spell = 31224, type = "buff", unit = "player"}, -- Cloak of Shadows
        { spell = 195627, type = "buff", unit = "player"}, -- Opportunity
        { spell = 11327, type = "buff", unit = "player"}, -- Vanish
        { spell = 13877, type = "buff", unit = "player"}, -- Blade Flurry
        { spell = 193356, type = "buff", unit = "player"}, -- Broadside
        { spell = 57934, type = "buff", unit = "player"}, -- Tricks of the Trade
        { spell = 45182, type = "buff", unit = "player", talent = 11 }, -- Cheating Death
      },
      icon = 132350
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 255909, type = "debuff", unit = "target", talent = 15}, -- Prey on the Weak
        { spell = 199804, type = "debuff", unit = "target"}, -- Between the Eyes
        { spell = 185763, type = "debuff", unit = "target"}, -- Pistol Shot
        { spell = 1833, type = "debuff", unit = "target"}, -- Cheap Shot
        { spell = 196937, type = "debuff", unit = "target", talent = 3}, -- Ghostly Strike
        { spell = 137619, type = "debuff", unit = "target", talent = 9}, -- Marked for Death
        { spell = 2094, type = "debuff", unit = "multi"}, -- Blind
        { spell = 1776, type = "debuff", unit = "target"}, -- Gouge
        { spell = 6770, type = "debuff", unit = "multi"}, -- Sap
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 1373908
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1752, type = "ability", requiresTarget = true}, -- Sinister Strike
        { spell = 1766, type = "ability", requiresTarget = true}, -- Kick
        { spell = 1776, type = "ability", requiresTarget = true, debuff = true}, -- Gouge
        { spell = 1784, type = "ability", buff = true}, -- Stealth
        { spell = 1856, type = "ability", buff = true}, -- Vanish
        { spell = 1966, type = "ability", buff = true}, -- Feint
        { spell = 2094, type = "ability", requiresTarget = true, debuff = true}, -- Blind
        { spell = 2098, type = "ability", requiresTarget = true, usable = true}, -- Dispatch
        { spell = 2983, type = "ability", buff = true }, -- Sprint
        { spell = 8676, type = "ability", requiresTarget = true, usable = true}, -- Shroud of Concealment
        { spell = 13750, type = "ability", buff = true}, -- Adrenaline Rush
        { spell = 13877, type = "ability", buff = true, charges = true}, -- Blade Flurry
        { spell = 31224, type = "ability", buff = true}, -- Cloak of Shadows
        { spell = 51690, type = "ability", requiresTarget = true, talent = 21}, -- Killing Spree
        { spell = 57934, type = "ability", requiresTarget = true}, -- Tricks of the Trade
        { spell = 79096, type = "ability"}, -- Restless Blades
        { spell = 114018, type = "ability", usable = true, buff = true}, -- Shroud of Concealment
        { spell = 137619, type = "ability", requiresTarget = true, debuff = true, talent = 9}, -- Marked for Death
        { spell = 185311, type = "ability", buff = true}, -- Crimson Vial
        { spell = 185763, type = "ability", requiresTarget = true}, -- Pistol Shot
        { spell = 193316, type = "ability", requiresTarget = true, usable = true}, -- Roll the Bones
        { spell = 195457, type = "ability", requiresTarget = true}, -- Grappling Hook
        { spell = 196937, type = "ability", requiresTarget = true, debuff = true, talent = 3}, -- Ghostly Strike
        { spell = 199754, type = "ability", buff = true}, -- Riposte
        { spell = 199804, type = "ability", usable = true, requiresTarget = true}, -- Between the Eyes
        { spell = 271877, type = "ability", buff = true, talent = 20}, -- Blade Rush
        { spell = 57934, type = "ability", requiresTarget = true, debuff = true}, -- Tricks of the Trade
      },
      icon = 135610
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277725, type = "buff", unit = "player"}, --Brigand's Blitz
        { spell = 272940, type = "buff", unit = "player"}, --Deadshot
        { spell = 274695, type = "buff", unit = "group"}, --Footpad
        { spell = 278962, type = "buff", unit = "player"}, --Paradise Lost
        { spell = 280200, type = "buff", unit = "player"}, --Shrouded Mantle
        { spell = 275863, type = "buff", unit = "player"}, --Snake Eyes
        { spell = 288988, type = "buff", unit = "player"}, --Keep Your Wits About You
        { spell = 288158, type = "buff", unit = "player"}, --Lying in Wait
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 207777, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Dismantle
        { spell = 207777, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Dismantle
        { spell = 198368, type="buff", unit = "player", pvptalent = 5},-- Take Your Cut
        { spell = 212210, type="ability", pvptalent = 6},-- Drink Up Me Hearties
        { spell = 269513, type="ability", pvptalent = 7},-- Death from Above
        { spell = 197003, type="buff", unit = "target", pvptalent = 8},-- Maneuverability
        { spell = 209754, type="buff", unit = "player", pvptalent = 9},-- Boarding Party
        { spell = 212182, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Smoke Bomb
        { spell = 212183, type="debuff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Smoke Bomb
        { spell = 198027, type="buff", unit = "player", pvptalent = 12},-- Turn the Tables
        { spell = 198529, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Plunder Armor
        { spell = 198529, type="buff", unit = "player", pvptalent = 14, titleSuffix = L["debuff"]},-- Plunder Armor
        { spell = 248744, type="debuff", unit = "target", pvptalent = 15},-- Shiv
        { spell = 213995, type="buff", unit = "player", pvptalent = 16, titleSuffix = L["buff"]},-- Cheap Tricks
        { spell = 212150, type="debuff", unit = "target", pvptalent = 16, titleSuffix = L["debuff"]},-- Cheap Tricks
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
        { spell = 196980, type = "buff", unit = "player", talent = 19}, -- Master of Shadows
        { spell = 5277, type = "buff", unit = "player"}, -- Evasion
        { spell = 121471, type = "buff", unit = "player"}, -- Shadow Blades
        { spell = 212283, type = "buff", unit = "player"}, -- Symbols of Death
        { spell = 185422, type = "buff", unit = "player"}, -- Shadow Dance
        { spell = 115192, type = "buff", unit = "player", talent = 4}, -- Subterfuge
        { spell = 114018, type = "buff", unit = "player"}, -- Shroud of Concealment
        { spell = 257506, type = "buff", unit = "player"}, -- Shot in the Dark
        { spell = 185311, type = "buff", unit = "player"}, -- Crimson Vial
        { spell = 277925, type = "buff", unit = "player", talent = 21}, -- Shuriken Tornado
        { spell = 1966, type = "buff", unit = "player", classic = false}, -- Feint
        { spell = 193538, type = "buff", unit = "player", talent = 17}, -- Alacrity
        { spell = 1784, type = "buff", unit = "player"}, -- Stealth
        { spell = 31224, type = "buff", unit = "player"}, -- Cloak of Shadows
        { spell = 115191, type = "buff", unit = "player"}, -- Stealth
        { spell = 11327, type = "buff", unit = "player"}, -- Vanish
        { spell = 245640, type = "buff", unit = "player"}, -- Shuriken Combo
        { spell = 2983, type = "buff", unit = "player"}, -- Sprint
        { spell = 57934, type = "buff", unit = "player"}, -- Tricks of the Trade
        { spell = 45182, type = "buff", unit = "player", talent = 11 }, -- Cheating Death
      },
      icon = 376022
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 255909, type = "debuff", unit = "target", talent = 15}, -- Prey on the Weak
        { spell = 91021, type = "debuff", unit = "target", talent = 2}, -- Find Weakness
        { spell = 195452, type = "debuff", unit = "target"}, -- Nightblade
        { spell = 2094, type = "debuff", unit = "multi"}, -- Blind
        { spell = 137619, type = "debuff", unit = "target"}, -- Marked for Death
        { spell = 1833, type = "debuff", unit = "target"}, -- Cheap Shot
        { spell = 206760, type = "debuff", unit = "target", talent = 14}, -- Shadow's Grasp
        { spell = 408, type = "debuff", unit = "target"}, -- Kidney Shot
        { spell = 6770, type = "debuff", unit = "multi"}, -- Sap
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 136175
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 53, type = "ability", requiresTarget = true}, -- Backstab
        { spell = 408, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Kidney Shot
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1752, type = "ability", requiresTarget = true}, -- Sinister Strike
        { spell = 1766, type = "ability", requiresTarget = true}, -- Kick
        { spell = 1784, type = "ability", buff = true}, -- Stealth
        { spell = 1833, type = "ability", usable = true, requiresTarget = true, debuff = true}, -- Cheap Shot
        { spell = 1856, type = "ability", buff = true}, -- Vanish
        { spell = 1966, type = "ability", buff = true}, -- Feint
        { spell = 2094, type = "ability", requiresTarget = true, debuff = true}, -- Blind
        { spell = 2983, type = "ability", buff = true}, -- Sprint
        { spell = 5277, type = "ability", buff = true}, -- Evasion
        { spell = 57934, type = "ability", requiresTarget = true}, -- Tricks of the Trade
        { spell = 6770, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Sap
        { spell = 31224, type = "ability", buff = true}, -- Cloak of Shadows
        { spell = 36554, type = "ability", charges = true, requiresTarget = true}, -- Shadowstep
        { spell = 114014, type = "ability", requiresTarget = true}, -- Shuriken Toss
        { spell = 114018, type = "ability", usable = true, buff = true}, -- Shroud of Concealment
        { spell = 115191, type = "ability", buff = true}, -- Stealth
        { spell = 121471, type = "ability", buff = true}, -- Shadow Blades
        { spell = 137619, type = "ability", requiresTarget = true, debuff = true, talent = 9}, -- Marked for Death
        { spell = 185311, type = "ability", buff = true}, -- Crimson Vial
        { spell = 185313, type = "ability", charges = true, buff = true}, -- Shadow Dance
        { spell = 185438, type = "ability", requiresTarget = true, usable = true}, -- Kidney Shot
        { spell = 195452, type = "ability", usable = true, requiresTarget = true, debuff = true}, -- Nightblade
        { spell = 196819, type = "ability", usable = true, requiresTarget = true}, -- Eviscerate
        { spell = 197835, type = "ability"}, -- Shuriken Storm
        { spell = 212283, type = "ability", buff = true}, -- Symbols of Death
        { spell = 277925, type = "ability", buff = true, talent = 21}, -- Shuriken Tornado
        { spell = 280719, type = "ability", requiresTarget = true, usable = true, debuff = true, talent = 20}, -- Secret Technique
        { spell = 57934, type = "ability", requiresTarget = true, debuff = true}, -- Tricks of the Trade
      },
      icon = 236279
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 279754, type = "buff", unit = "player"}, --Blade In The Shadows
        { spell = 272940, type = "buff", unit = "player"}, --Deadshot
        { spell = 273424, type = "buff", unit = "player"}, --Night's Vengeance
        { spell = 277720, type = "buff", unit = "player"}, --Perforate
        { spell = 280200, type = "buff", unit = "player"}, --Shrouded Mantle
        { spell = 278981, type = "buff", unit = "player"}, --The First Dance
        { spell = 288158, type = "buff", unit = "player"}, --Lying in Wait
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198688, type="debuff", unit = "target", pvptalent = 5},-- Dagger in the Dark
        { spell = 212182, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Smoke Bomb
        { spell = 212183, type="debuff", unit = "player", pvptalent = 7, titleSuffix = L["buff"]},-- Smoke Bomb
        { spell = 207736, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Shadowy Duel
        { spell = 207736, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Shadowy Duel
        { spell = 213981, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Cold Blood
        { spell = 213981, type="buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- Cold Blood
        { spell = 197003, type="buff", unit = "player", pvptalent = 10},-- Maneuverability
        { spell = 248744, type="debuff", unit = "target", pvptalent = 11},-- Shiv
        { spell = 269513, type="ability", pvptalent = 13},-- Death from Above
        { spell = 199027, type="buff", unit = "player", pvptalent = 14},-- Veil of Midnight
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
        { spell = 586, type = "buff", unit = "player"}, -- Fade
        { spell = 198069, type = "buff", unit = "player"}, -- Power of the Dark Side
        { spell = 194384, type = "buff", unit = "player"}, -- Atonement
        { spell = 17, type = "buff", unit = "target"}, -- Power Word: Shield
        { spell = 265258, type = "buff", unit = "player", talent = 2}, -- Twist of Fate
        { spell = 271466, type = "buff", unit = "player", talent = 20}, -- Luminous Barrier
        { spell = 19236, type = "buff", unit = "player"}, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 81782, type = "buff", unit = "target"}, -- Power Word: Barrier
        { spell = 33206, type = "buff", unit = "group"}, -- Pain Suppression
        { spell = 193065, type = "buff", unit = "player", talent = 5}, -- Masochism
        { spell = 65081, type = "buff", unit = "player", talent = 4}, -- Body and Soul
        { spell = 47536, type = "buff", unit = "player"}, -- Rapture
        { spell = 121557, type = "buff", unit = "player", talent = 6}, -- Angelic Feather
        { spell = 2096, type = "buff", unit = "player"}, -- Mind Vision
        { spell = 111759, type = "buff", unit = "player"}, -- Levitate
        { spell = 45243, type = "buff", unit = "player" }, -- Focused Will
      },
      icon = 135940
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 8122, type = "debuff", unit = "target"}, -- Psychic Scream
        { spell = 204263, type = "debuff", unit = "target", talent = 12}, -- Shining Force
        { spell = 208772, type = "debuff", unit = "target"}, -- Smite
        { spell = 204213, type = "debuff", unit = "target", talent = 16}, -- Purge the Wicked
        { spell = 2096, type = "debuff", unit = "target"}, -- Mind Vision
        { spell = 214621, type = "debuff", unit = "target", talent = 3}, -- Schism
        { spell = 589, type = "debuff", unit = "target"}, -- Shadow Word: Pain
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
      },
      icon = 136207
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 527, type = "ability"}, -- Purify
        { spell = 586, type = "ability", buff = true}, -- Fade
        { spell = 2061, type = "ability", overlayGlow = true}, -- Flash Heal
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 19236, type = "ability", buff = true}, -- Desperate Prayer
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 33206, type = "ability"}, -- Pain Suppression
        { spell = 34433, type = "ability", totem = true, requiresTarget = true}, -- Shadowfiend
        { spell = 47536, type = "ability", buff = true}, -- Rapture
        { spell = 47540, type = "ability", requiresTarget = true}, -- Penance
        { spell = 62618, type = "ability"}, -- Power Word: Barrier
        { spell = 73325, type = "ability"}, -- Leap of Faith
        { spell = 110744, type = "ability", talent = 17}, -- Divine Star
        { spell = 120517, type = "ability", talent = 18}, -- Halo
        { spell = 121536, type = "ability", charges = true, buff = true, talent = 6}, -- Angelic Feather
        { spell = 123040, type = "ability", totem = true, requiresTarget = true, talent = 8}, -- Mindbender
        { spell = 129250, type = "ability", requiresTarget = true, talent = 9}, -- Power Word: Solace
        { spell = 194509, type = "ability", charges = true}, -- Power Word: Radiance
        { spell = 204065, type = "ability", talent = 15}, -- Shadow Covenant
        { spell = 204263, type = "ability", talent = 12}, -- Shining Force
        { spell = 214621, type = "ability", requiresTarget = true, debuff = true, talent = 3}, -- Schism
        { spell = 246287, type = "ability"}, -- Evangelism
        { spell = 271466, type = "ability", talent = 20}, -- Luminous Barrier

      },
      icon = 136224
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275544, type = "buff", unit = "player"}, --Depth of the Shadows
        { spell = 274369, type = "buff", unit = "player"}, --Sanctum
        { spell = 287723, type = "buff", unit = "player"}, --Death Denied
        { spell = 287360, type = "buff", unit = "player"}, --Sudden Revelation
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 197871, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Dark Archangel
        { spell = 197871, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Dark Archangel
        { spell = 305498, type="ability", pvptalent = 12},-- Premonition
        { spell = 197862, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Archangel
        { spell = 197862, type="buff", unit = "player", pvptalent = 13, titleSuffix = L["buff"]},-- Archangel
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
        { spell = 47788, type = "buff", unit = "target"}, -- Guardian Spirit
        { spell = 64901, type = "buff", unit = "player"}, -- Symbol of Hope
        { spell = 139, type = "buff", unit = "target"}, -- Renew
        { spell = 2096, type = "buff", unit = "player"}, -- Mind Vision
        { spell = 64843, type = "buff", unit = "player"}, -- Divine Hymn
        { spell = 19236, type = "buff", unit = "player"}, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 111759, type = "buff", unit = "player"}, -- Levitate
        { spell = 200183, type = "buff", unit = "player", talent = 20}, -- Apotheosis
        { spell = 27827, type = "buff", unit = "player"}, -- Spirit of Redemption
        { spell = 77489, type = "buff", unit = "target"}, -- Echo of Light
        { spell = 114255, type = "buff", unit = "player", talent = 13}, -- Surge of Light
        { spell = 121557, type = "buff", unit = "player", talent = 6}, -- Angelic Feather
        { spell = 586, type = "buff", unit = "player"}, -- Fade
        { spell = 41635, type = "buff", unit = "group"}, -- Prayer of Mending
        { spell = 45243, type = "buff", unit = "player" }, -- Focused Will
      },
      icon = 135953
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 8122, type = "debuff", unit = "target"}, -- Psychic Scream
        { spell = 200196, type = "debuff", unit = "target"}, -- Holy Word: Chastise
        { spell = 14914, type = "debuff", unit = "target"}, -- Holy Fire
        { spell = 2096, type = "debuff", unit = "target"}, -- Mind Vision
        { spell = 204263, type = "debuff", unit = "target"}, -- Shining Force
        { spell = 200200, type = "debuff", unit = "target"}, -- Holy Word: Chastise
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
      },
      icon = 135972
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 527, type = "ability"}, -- Purify
        { spell = 586, type = "ability", buff = true}, -- Fade
        { spell = 2050, type = "ability"}, -- Holy Word: Serenity
        { spell = 2061, type = "ability"}, -- Flash Heal
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 14914, type = "ability", requiresTarget = true}, -- Holy Fire
        { spell = 19236, type = "ability", buff = true}, -- Desperate Prayer
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 33076, type = "ability"}, -- Prayer of Mending
        { spell = 34861, type = "ability"}, -- Holy Word: Sanctify
        { spell = 47788, type = "ability"}, -- Guardian Spirit
        { spell = 64843, type = "ability", buff = true}, -- Divine Hymn
        { spell = 64901, type = "ability", buff = true}, -- Symbol of Hope
        { spell = 73325, type = "ability"}, -- Leap of Faith
        { spell = 88625, type = "ability", requiresTarget = true, debuff = true}, -- Holy Word: Chastise
        { spell = 110744, type = "ability", talent = 17}, -- Divine Star
        { spell = 120517, type = "ability", talent = 18}, -- Halo
        { spell = 121536, type = "ability", charges = true, buff = true, talent = 6}, -- Angelic Feather
        { spell = 200183, type = "ability", buff = true, talent = 20}, -- Apotheosis
        { spell = 204263, type = "ability", talent = 12}, -- Shining Force
        { spell = 204883, type = "ability", talent = 15}, -- Circle of Healing
        { spell = 265202, type = "ability", talent = 21}, -- Holy Word: Salvation

      },
      icon = 135937
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272783, type = "buff", unit = "target"}, --Permeating Glow
        { spell = 274369, type = "buff", unit = "player"}, --Sanctum
        { spell = 287723, type = "buff", unit = "player"}, --Death Denied
        { spell = 287340, type = "buff", unit = "player"}, --Promise of Deliverance
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 215982, type="ability", pvptalent = 6},-- Spirit of the Redeemer
        { spell = 197268, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Ray of Hope
        { spell = 232707, type="buff", unit = "target", pvptalent = 7, titleSuffix = L["buff"]},-- Ray of Hope
        { spell = 213610, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Holy Ward
        { spell = 213610, type="buff", unit = "target", pvptalent = 9, titleSuffix = L["buff"]},-- Holy Ward
        { spell = 289657, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Holy Word: Concentration
        { spell = 289655, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Holy Word: Concentration
        { spell = 213602, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Greater Fade
        { spell = 213602, type="buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]},-- Greater Fade
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
        { spell = 193223, type = "buff", unit = "player", talent = 21}, -- Surrender to Madness
        { spell = 263165, type = "buff", unit = "player", talent = 18}, -- Void Torrent
        { spell = 586, type = "buff", unit = "player"}, -- Fade
        { spell = 2096, type = "buff", unit = "player"}, -- Mind Vision
        { spell = 15286, type = "buff", unit = "player"}, -- Vampiric Embrace
        { spell = 124430, type = "buff", unit = "player", talent = 2}, -- Shadowy Insight
        { spell = 17, type = "buff", unit = "player"}, -- Power Word: Shield
        { spell = 65081, type = "buff", unit = "player", talent = 4}, -- Body and Soul
        { spell = 197937, type = "buff", unit = "player", talent = 16}, -- Lingering Insanity
        { spell = 194249, type = "buff", unit = "player"}, -- Voidform
        { spell = 47585, type = "buff", unit = "player"}, -- Dispersion
        { spell = 232698, type = "buff", unit = "player"}, -- Shadowform
        { spell = 21562, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 111759, type = "buff", unit = "player"}, -- Levitate
        { spell = 123254, type = "buff", unit = "player", talent = 7 }, -- Twist of Fate
      },
      icon = 237566
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 15407, type = "debuff", unit = "target"}, -- Mind Flay
        { spell = 48045, type = "debuff", unit = "target"}, -- Mind Sear
        { spell = 2096, type = "debuff", unit = "target"}, -- Mind Vision
        { spell = 205369, type = "debuff", unit = "target", talent = 11}, -- Mind Bomb
        { spell = 226943, type = "debuff", unit = "target", talent = 11}, -- Mind Bomb
        { spell = 263165, type = "debuff", unit = "target", talent = 18}, -- Void Torrent
        { spell = 15487, type = "debuff", unit = "target"}, -- Silence
        { spell = 589, type = "debuff", unit = "target"}, -- Shadow Word: Pain
        { spell = 8122, type = "debuff", unit = "target"}, -- Psychic Scream
        { spell = 34914, type = "debuff", unit = "target"}, -- Vampiric Touch
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
      },
      icon = 136207
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 17, type = "ability", buff = true}, -- Power Word: Shield
        { spell = 586, type = "ability", buff = true}, -- Fade
        { spell = 8092, type = "ability", requiresTarget = true}, -- Mind Blast
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 15286, type = "ability", buff = true}, -- Vampiric Embrace
        { spell = 15487, type = "ability", requiresTarget = true}, -- Silence
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 32379, type = "ability", charges = true, usable = true, requiresTarget = true, talent = 14}, -- Shadow Word: Death
        { spell = 34433, type = "ability", totem = true, requiresTarget = true}, -- Shadowfiend
        { spell = 47585, type = "ability", buff = true}, -- Dispersion
        { spell = 64044, type = "ability", requiresTarget = true, talent = 12}, -- Psychic Horror
        { spell = 73325, type = "ability"}, -- Leap of Faith
        { spell = 193223, type = "ability", usable = true, buff = true, talent = 21}, -- Surrender to Madness
        { spell = 200174, type = "ability", totem = true, requiresTarget = true, talent = 17}, -- Mindbender
        { spell = 205351, type = "ability", charges = true, requiresTarget = true, talent = 3}, -- Shadow Word: Void
        { spell = 205369, type = "ability", requiresTarget = true, talent = 11}, -- Mind Bomb
        { spell = 205385, type = "ability", talent = 15}, -- Shadow Crash
        { spell = 205448, type = "ability", usable = true, requiresTarget = true}, -- Void Bolt
        { spell = 213634, type = "ability"}, -- Purify Disease
        { spell = 228260, type = "ability", usable = true, requiresTarget = true}, -- Void Eruption
        { spell = 263165, type = "ability", usable = true, requiresTarget = true, talent = 18}, -- Void Torrent
        { spell = 263346, type = "ability", requiresTarget = true, talent = 9}, -- Dark Void
        { spell = 280711, type = "ability", requiresTarget = true, talent = 20}, -- Dark Ascension

      },
      icon = 136230
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 279572, type = "buff", unit = "player"}, --Chorus of Insanity
        { spell = 275544, type = "buff", unit = "player"}, --Depth of the Shadows
        { spell = 273321, type = "buff", unit = "player"}, --Harvested Thoughts
        { spell = 274369, type = "buff", unit = "player"}, --Sanctum
        { spell = 275726, type = "buff", unit = "player"}, --Whispers of the Damned
        { spell = 287723, type = "buff", unit = "player"}, --Death Denied
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 211522, type="ability", pvptalent = 7},-- Psyfiend
        { spell = 199412, type="buff", unit = "player", pvptalent = 8},-- Edge of Insanity
        { spell = 108968, type="ability", pvptalent = 11},-- Void Shift
        { spell = 247776, type="buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]},-- Mind Trauma
        { spell = 247777, type="debuff", unit = "target", pvptalent = 12, titleSuffix = L["debuff"]},-- Mind Trauma
        { spell = 213602, type="buff", unit = "target", pvptalent = 13},-- Greater Fade
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
        { spell = 192082, type = "buff", unit = "player", talent = 15}, -- Wind Rush
        { spell = 202192, type = "buff", unit = "player", talent = 6}, -- Resonance Totem
        { spell = 210659, type = "buff", unit = "player", talent = 6}, -- Tailwind Totem
        { spell = 173184, type = "buff", unit = "player", talent = 3}, -- Elemental Blast: Mastery
        { spell = 108271, type = "buff", unit = "player"}, -- Astral Shift
        { spell = 210652, type = "buff", unit = "player", talent = 6}, -- Storm Totem
        { spell = 272737, type = "buff", unit = "player", talent = 19}, -- Unlimited Power
        { spell = 108281, type = "buff", unit = "player", talent = 14}, -- Ancestral Guidance
        { spell = 546, type = "buff", unit = "player"}, -- Water Walking
        { spell = 114050, type = "buff", unit = "player", talent = 21}, -- Ascendance
        { spell = 210714, type = "buff", unit = "player", talent = 18}, -- Icefury
        { spell = 260881, type = "buff", unit = "player", talent = 7}, -- Spirit Wolf
        { spell = 260734, type = "buff", unit = "player", talent = 10}, -- Master of the Elements
        { spell = 191634, type = "buff", unit = "player", talent = 20}, -- Stormkeeper
        { spell = 285514, type = "buff", unit = "player", talent = 16}, -- Surge of Power
        { spell = 974, type = "buff", unit = "player", talent = 8}, -- Earth Shield
        { spell = 6196, type = "buff", unit = "player"}, -- Far Sight
        { spell = 210658, type = "buff", unit = "player", talent = 6}, -- Ember Totem
        { spell = 173183, type = "buff", unit = "player", talent = 3}, -- Elemental Blast: Haste
        { spell = 77762, type = "buff", unit = "player"}, -- Lava Surge
        { spell = 2645, type = "buff", unit = "player"}, -- Ghost Wolf
        { spell = 118522, type = "buff", unit = "player", talent = 3}, -- Elemental Blast: Critical Strike
        { spell = 157348, type = "buff", unit = "pet", talent = {11,17}}, -- Call Lightning

      },
      icon = 135863
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 269808, type = "debuff", unit = "target", talent = 1}, -- Exposed Elements
        { spell = 118905, type = "debuff", unit = "target"}, -- Static Charge
        { spell = 182387, type = "debuff", unit = "target"}, -- Earthquake
        { spell = 188389, type = "debuff", unit = "target"}, -- Flame Shock
        { spell = 51490, type = "debuff", unit = "target"}, -- Thunderstorm
        { spell = 196840, type = "debuff", unit = "target"}, -- Frost Shock
        { spell = 118297, type = "debuff", unit = "target"}, -- Immolate
        { spell = 3600, type = "debuff", unit = "target"}, -- Earthbind
        { spell = 157375, type = "debuff", unit = "target"}, -- Eye of the Storm
        { spell = 118345, type = "debuff", unit = "target"}, -- Pulverize

      },
      icon = 135813
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 2484, type = "ability", totem = true}, -- Earthbind Totem
        { spell = 8143, type = "ability", totem = true}, -- Tremor Totem
        { spell = 32182, type = "ability", buff = true}, -- Heroism
        { spell = 2825, type = "ability", buff = true}, -- Bloodlust
        { spell = 51490, type = "ability"}, -- Thunderstorm
        { spell = 51505, type = "ability", requiresTarget = true, talent = {1,3}, overlayGlow = true}, -- Lava Burst
        { spell = 51505, type = "ability", charges = true, requiresTarget = true, talent = 2, titleSuffix = " (2 Charges)", overlayGlow = true}, -- Lava Burst
        { spell = 51514, type = "ability", requiresTarget = true}, -- Hex
        { spell = 51886, type = "ability"}, -- Cleanse Spirit
        { spell = 57994, type = "ability", requiresTarget = true}, -- Wind Shear
        { spell = 108271, type = "ability", buff = true}, -- Astral Shift
        { spell = 108281, type = "ability", buff = true}, -- Ancestral Guidance
        { spell = 114050, type = "ability", buff = true, talent = 21}, -- Ascendance
        { spell = 117014, type = "ability", requiresTarget = true, talent = 3}, -- Elemental Blast
        { spell = 188389, type = "ability", debuff = true, requiresTarget = true}, -- Flame Shock
        { spell = 191634, type = "ability", buff = true, talent = 20}, -- Stormkeeper
        { spell = 192058, type = "ability", totem = true}, -- Capacitor Totem
        { spell = 192077, type = "ability", totem = true, talent = 15}, -- Wind Rush Totem
        { spell = 192222, type = "ability", totem = true, talent = 12}, -- Liquid Magma Totem
        { spell = 192249, type = "ability", duration = 30,talent = 11}, -- Storm Elemental
        { spell = 198067, type = "ability", duration = 30}, -- Fire Elemental
        { spell = 198103, type = "ability", duration = 60}, -- Earth Elemental
        { spell = 210714, type = "ability", debuff = true, requiresTarget = true, talent = 18}, -- Icefury
      },
      icon = 135963
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277942, type = "buff", unit = "player"}, --Ancestral Resonance
        { spell = 263786, type = "buff", unit = "player"}, --Astral Shift
        { spell = 264113, type = "buff", unit = "player"}, --Flames of the Forefathers
        { spell = 263792, type = "buff", unit = "player"}, --Lightningburn
        { spell = 279028, type = "buff", unit = "player"}, --Natural Harmony (Fire)
        { spell = 279029, type = "buff", unit = "player"}, --Natural Harmony (Frost)
        { spell = 279033, type = "buff", unit = "player"}, --Natural Harmony (Nature)
        { spell = 280205, type = "buff", unit = "player"}, --Pack Spirit
        { spell = 286976, type = "buff", unit = "player"}, --Tectonic Thunder
        { spell = 277960, type = "buff", unit = "player"}, --Synapse Shock
        { spell = 272981, type = "buff", unit = "player"}, --Volcanic Lightning
        { spell = 287786, type = "buff", unit = "player"}, --Ancient Ankh Talisman
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 305483, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Lightning Lasso
        { spell = 305485, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Lightning Lasso
        { spell = 236746, type="buff", unit = "player", pvptalent = 8},-- Control of Lava
        { spell = 204330, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Skyfury Totem
        { spell = 208963, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Skyfury Totem
        { spell = 204336, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Grounding Totem
        { spell = 8178, type="buff", unit = "target", pvptalent = 12, titleSuffix = L["buff"]},-- Grounding Totem
        { spell = 204331, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Counterstrike Totem
        { spell = 208997, type="debuff", unit = "target", pvptalent = 13, titleSuffix = L["debuff"]},-- Counterstrike Totem
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
        { spell = 273323, type = "buff", unit = "player", talent = 3 }, -- Lightning Shield Overcharge
        { spell = 192082, type = "buff", unit = "player", talent = 15 }, -- Wind Rush
        { spell = 974, type = "buff", unit = "player", talent = 8 }, -- Earth Shield
        { spell = 262652, type = "buff", unit = "player", talent = 5 }, -- Forceful Winds
        { spell = 187878, type = "buff", unit = "player"}, -- Crash Lightning
        { spell = 262397, type = "buff", unit = "player", talent = 6 }, -- Storm Totem
        { spell = 192106, type = "buff", unit = "player", talent = 3 }, -- Lightning Shield
        { spell = 108271, type = "buff", unit = "player"}, -- Astral Shift
        { spell = 6196, type = "buff", unit = "player"}, -- Far Sight
        { spell = 196834, type = "buff", unit = "player"}, -- Frostbrand
        { spell = 224126, type = "buff", unit = "player", talent = 19 }, -- Icy Edge
        { spell = 546, type = "buff", unit = "player"}, -- Water Walking
        { spell = 114051, type = "buff", unit = "player", talent = 21 }, -- Ascendance
        { spell = 224125, type = "buff", unit = "player", talent = 19 }, -- Molten Weapon
        { spell = 202004, type = "buff", unit = "player", talent = 4 }, -- Landslide
        { spell = 262400, type = "buff", unit = "player", talent = 6 }, -- Tailwind Totem
        { spell = 58875, type = "buff", unit = "player"}, -- Spirit Walk
        { spell = 198300, type = "buff", unit = "player"}, -- Gathering Storms
        { spell = 224127, type = "buff", unit = "player", talent = 19 }, -- Crackling Surge
        { spell = 197211, type = "buff", unit = "player", talent = 17 }, -- Fury of Air
        { spell = 201846, type = "buff", unit = "player"}, -- Stormbringer
        { spell = 260881, type = "buff", unit = "player", talent = 7 }, -- Spirit Wolf
        { spell = 262417, type = "buff", unit = "player", talent = 6 }, -- Resonance Totem
        { spell = 262399, type = "buff", unit = "player", talent = 6 }, -- Ember Totem
        { spell = 2645, type = "buff", unit = "player"}, -- Ghost Wolf
        { spell = 215785, type = "buff", unit = "player", talent = 2 }, -- Hot Hand
        { spell = 194084, type = "buff", unit = "player"}, -- Flametongue
      },
      icon = 136099
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118905, type = "debuff", unit = "target"}, -- Static Charge
        { spell = 197214, type = "debuff", unit = "target", talent = 18 }, -- Sundering
        { spell = 147732, type = "debuff", unit = "target"}, -- Frostbrand
        { spell = 271924, type = "debuff", unit = "target", talent = 19 }, -- Molten Weapon
        { spell = 3600, type = "debuff", unit = "target"}, -- Earthbind
        { spell = 188089, type = "debuff", unit = "target", talent = 20 }, -- Earthen Spike
        { spell = 197385, type = "debuff", unit = "target", talent = 17 }, -- Fury of Air
        { spell = 268429, type = "debuff", unit = "target", talent = 10 }, -- Searing Assault
      },
      icon = 462327
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 2484, type = "ability", totem = true}, -- Earthbind Totem
        { spell = 8143, type = "ability", totem = true}, -- Tremor Totem
        { spell = 17364, type = "ability", requiresTarget = true, overlayGlow = true}, -- Stormstrike
        { spell = 32182, type = "ability", buff = true}, -- Heroism
        { spell = 2825, type = "ability", buff = true}, -- Bloodlust
        { spell = 51514, type = "ability", requiresTarget = true}, -- Hex
        { spell = 51533, type = "ability", duration = 15}, -- Feral Spirit
        { spell = 51886, type = "ability"}, -- Cleanse Spirit
        { spell = 57994, type = "ability", requiresTarget = true}, -- Wind Shear
        { spell = 58875, type = "ability", buff = true}, -- Spirit Walk
        { spell = 108271, type = "ability", buff = true}, -- Astral Shift
        { spell = 114051, type = "ability", buff = true, talent = 21 }, -- Ascendance
        { spell = 115356, type = "ability", talent = 21 }, -- Windstrike
        { spell = 187837, type = "ability", requiresTarget = true, talent = 12 }, -- Lightning Bolt
        { spell = 187874, type = "ability", requiresTarget = true}, -- Crash Lightning
        { spell = 188089, type = "ability", debuff = true, requiresTarget = true, talent = 20 }, -- Earthen Spike
        { spell = 192058, type = "ability", totem = true}, -- Capacitor Totem
        { spell = 192077, type = "ability", totem = true, talent = 15 }, -- Wind Rush Totem
        { spell = 193786, type = "ability", charges = true, requiresTarget = true}, -- Rockbiter
        { spell = 193796, type = "ability", buff = true, requiresTarget = true}, -- Flametongue
        { spell = 196884, type = "ability", requiresTarget = true, talent = 14 }, -- Feral Lunge
        { spell = 197214, type = "ability", talent = 18 }, -- Sundering
        { spell = 198103, type = "ability", duration = 60 }, -- Earth Elemental
      },
      icon = 1370984
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 277942, type = "buff", unit = "player"}, --Ancestral Resonance
        { spell = 263786, type = "buff", unit = "player"}, --Astral Shift
        { spell = 264121, type = "buff", unit = "player"}, --Electropotence
        { spell = 275391, type = "buff", unit = "target"}, --Lightning Conduit
        { spell = 280205, type = "buff", unit = "player"}, --Pack Spirit
        { spell = 273006, type = "buff", unit = "player"}, --Primal Primer
        { spell = 279515, type = "buff", unit = "player"}, --Roiling Storm
        { spell = 263795, type = "buff", unit = "player"}, --Storm's Eye
        { spell = 273465, type = "buff", unit = "player"}, --Strength of Earth
        { spell = 277960, type = "buff", unit = "player"}, --Synapse Shock
        { spell = 287786, type = "buff", unit = "player"}, --Ancient Ankh Talisman
        { spell = 287802, type = "buff", unit = "player"}, --Thunderaan's Fury
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 204366, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Thundercharge
        { spell = 204366, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Thundercharge
        { spell = 210918, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Ethereal Form
        { spell = 210918, type="buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"]},-- Ethereal Form
        { spell = 204330, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Skyfury Totem
        { spell = 208963, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Skyfury Totem
        { spell = 204331, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Counterstrike Totem
        { spell = 208997, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Counterstrike Totem
        { spell = 204336, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Grounding Totem
        { spell = 8178, type="buff", unit = "player", pvptalent = 13, titleSuffix = L["debuff"]},-- Grounding Totem
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
        { spell = 79206, type = "buff", unit = "player"}, -- Spiritwalker's Grace
        { spell = 114052, type = "buff", unit = "player", talent = 21 }, -- Ascendance
        { spell = 974, type = "buff", unit = "group", talent = 6 }, -- Earth Shield
        { spell = 216251, type = "buff", unit = "player", talent = 2 }, -- Undulation
        { spell = 108271, type = "buff", unit = "player"}, -- Astral Shift
        { spell = 6196, type = "buff", unit = "player"}, -- Far Sight
        { spell = 207498, type = "buff", unit = "player", talent = 12 }, -- Ancestral Protection
        { spell = 73685, type = "buff", unit = "player", talent = 3 }, -- Unleash Life
        { spell = 546, type = "buff", unit = "player"}, -- Water Walking
        { spell = 157504, type = "buff", unit = "player", talent = 18 }, -- Cloudburst Totem
        { spell = 260881, type = "buff", unit = "player", talent = 7 }, -- Spirit Wolf
        { spell = 61295, type = "buff", unit = "target"}, -- Riptide
        { spell = 98007, type = "buff", unit = "player"}, -- Spirit Link Totem
        { spell = 77762, type = "buff", unit = "player"}, -- Lava Surge
        { spell = 207400, type = "buff", unit = "target", talent = 10 }, -- Ancestral Vigor
        { spell = 201633, type = "buff", unit = "player", talent = 11 }, -- Earthen Wall
        { spell = 73920, type = "buff", unit = "player"}, -- Healing Rain
        { spell = 280615, type = "buff", unit = "player", talent = 16 }, -- Flash Flood
        { spell = 2645, type = "buff", unit = "player"}, -- Ghost Wolf
        { spell = 53390, type = "buff", unit = "player"}, -- Tidal Waves
      },
      icon = 252995
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118905, type = "debuff", unit = "target"}, -- Static Charge
        { spell = 64695, type = "debuff", unit = "target", talent = 8 }, -- Earthgrab
        { spell = 3600, type = "debuff", unit = "target"}, -- Earthbind
        { spell = 188838, type = "debuff", unit = "target"}, -- Flame Shock
      },
      icon = 135813
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 2484, type = "ability", totem = true}, -- Earthbind Totem
        { spell = 5394, type = "ability", totem = true, talent = {5,6}}, -- Healing Stream Totem
        { spell = 5394, type = "ability", charges = true, totem = true, talent = 4, titleSuffix = " (2 Charges)"}, -- Healing Stream Totem
        { spell = 8143, type = "ability", totem = true}, -- Tremor Totem
        { spell = 32182, type = "ability", buff = true}, -- Heroism
        { spell = 2825, type = "ability", buff = true}, -- Bloodlust
        { spell = 51485, type = "ability", totem = true, talent = 8 }, -- Earthgrab Totem
        { spell = 51505, type = "ability", requiresTarget = true, talent = {5,6}}, -- Lava Burst
        { spell = 51505, type = "ability", charges = true, requiresTarget = true, talent = 4, titleSuffix = " (2 Charges)"}, -- Lava Burst
        { spell = 51514, type = "ability", requiresTarget = true}, -- Hex
        { spell = 57994, type = "ability", requiresTarget = true}, -- Wind Shear
        { spell = 61295, type = "ability", talent = {5,6}}, -- Riptide
        { spell = 61295, type = "ability", charges = true, talent = 4, titleSuffix = " (2 Charges)"}, -- Riptide
        { spell = 73685, type = "ability", buff = true, talent = 3 }, -- Unleash Life
        { spell = 73920, type = "ability", duration = 10}, -- Healing Rain
        { spell = 79206, type = "ability", buff = true}, -- Spiritwalker's Grace
        { spell = 98008, type = "ability", totem = true}, -- Spirit Link Totem
        { spell = 108271, type = "ability", buff = true}, -- Astral Shift
        { spell = 108280, type = "ability", totem = true}, -- Healing Tide Totem
        { spell = 114052, type = "ability", buff = true, talent = 21 }, -- Ascendance
        { spell = 157153, type = "ability", charges = true, totem = true, talent = 18 }, -- Cloudburst Totem
        { spell = 188838, type = "ability", debuff = true, requiresTarget = true}, -- Flame Shock
        { spell = 192058, type = "ability", totem = true}, -- Capacitor Totem
        { spell = 192077, type = "ability", totem = true, talent = 15 }, -- Wind Rush Totem
        { spell = 197995, type = "ability", talent = 20 }, -- Wellspring
        { spell = 198103, type = "ability", duration = 60 }, -- Earth Elemental
        { spell = 198838, type = "ability", totem = true, talent = 11 }, -- Earthen Wall Totem
        { spell = 207399, type = "ability", totem = true, talent = 12 }, -- Ancestral Protection Totem
        { spell = 207778, type = "ability", talent = 17 }, -- Downpour
      },
      icon = 135127
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 263786, type = "buff", unit = "player"}, --Astral Shift
        { spell = 263790, type = "buff", unit = "player"}, --Ancestral Reach
        { spell = 277942, type = "buff", unit = "player"}, --Ancestral Resonance
        { spell = 264113, type = "buff", unit = "player"}, --Flames of the Forefathers
        { spell = 278095, type = "buff", unit = "group"}, --Overflowing Shores
        { spell = 280205, type = "buff", unit = "player"}, --Pack Spirit
        { spell = 279505, type = "buff", unit = "group"}, --Spouting Spirits
        { spell = 279187, type = "buff", unit = "target"}, --Surging Tides
        { spell = 272981, type = "debuff", unit = "target"}, --Volcanic Lightning
        { spell = 273019, type = "buff", unit = "player"}, --Soothing Waters
        { spell = 287786, type = "buff", unit = "player"}, --Ancient Ankh Talisman
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 290254, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Ancestral Gift
        { spell = 290641, type="buff", unit = "player", pvptalent = 4, titleSuffix = L["buff"]},-- Ancestral Gift
        { spell = 206647, type="debuff", unit = "target", pvptalent = 5},-- Electrocute
        { spell = 204293, type="buff", unit = "target", pvptalent = 6},-- Spirit Link
        { spell = 236502, type="buff", unit = "player", pvptalent = 7},-- Tidebringer
        { spell = 204336, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Grounding Totem
        { spell = 8178, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Grounding Totem
        { spell = 204330, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Skyfury Totem
        { spell = 208963, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Skyfury Totem
        { spell = 204331, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Counterstrike Totem
        { spell = 208997, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Counterstrike Totem
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
        { spell = 110960, type = "buff", unit = "player"}, -- Greater Invisibility
        { spell = 45438, type = "buff", unit = "player"}, -- Ice Block
        { spell = 116267, type = "buff", unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 1459, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil}, -- Arcane Intellect
        { spell = 212799, type = "buff", unit = "player"}, -- Displacement Beacon
        { spell = 210126, type = "buff", unit = "player", talent = 3 }, -- Arcane Familiar
        { spell = 236298, type = "buff", unit = "player", talent = 13 }, -- Chrono Shift
        { spell = 116014, type = "buff", unit = "player", talent = 9 }, -- Rune of Power
        { spell = 130, type = "buff", unit = "player"}, -- Slow Fall
        { spell = 263725, type = "buff", unit = "player"}, -- Clearcasting
        { spell = 235450, type = "buff", unit = "player"}, -- Prismatic Barrier
        { spell = 12051, type = "buff", unit = "player"}, -- Evocation
        { spell = 205025, type = "buff", unit = "player"}, -- Presence of Mind
        { spell = 264774, type = "buff", unit = "player", talent = 2 }, -- Rule of Threes
        { spell = 12042, type = "buff", unit = "player"}, -- Arcane Power

      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 82691, type = "debuff", unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 114923, type = "debuff", unit = "target", talent = 18 }, -- Nether Tempest
        { spell = 210824, type = "debuff", unit = "target", talent = 17 }, -- Touch of the Magi
        { spell = 236299, type = "debuff", unit = "target", talent = 13 }, -- Chrono Shift
        { spell = 31589, type = "debuff", unit = "target"}, -- Slow
        { spell = 122, type = "debuff", unit = "target"}, -- Frost Nova
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
      },
      icon = 135848
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1449, type = "ability", overlayGlow = true}, -- Arcane Explosion
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability", requiresTarget = true}, -- Counterspell
        { spell = 5143, type = "ability", requiresTarget = true, overlayGlow = true}, -- Arcane Missiles
        { spell = 12042, type = "ability", buff = true}, -- Arcane Power
        { spell = 12051, type = "ability", buff = true}, -- Evocation
        { spell = 44425, type = "ability", requiresTarget = true}, -- Arcane Barrage
        { spell = 45438, type = "ability", buff = true}, -- Ice Block
        { spell = 55342, type = "ability", talent = 8 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true}, -- Time Warp
        { spell = 110959, type = "ability", buff = true}, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 15 }, -- Ring of Frost
        { spell = 116011, type = "ability", charges = true, buff = true, talent = 9 }, -- Rune of Power
        { spell = 153626, type = "ability", talent = 21 }, -- Arcane Orb
        { spell = 157980, type = "ability", requiresTarget = true, talent = 12 }, -- Supernova
        { spell = 190336, type = "ability"}, -- Conjure Refreshment
        { spell = 195676, type = "ability", usable = true}, -- Displacement
        { spell = 205022, type = "ability", talent = 3 }, -- Arcane Familiar
        { spell = 205025, type = "ability", buff = true}, -- Presence of Mind
        { spell = 205032, type = "ability", talent = 11 }, -- Charged Up
        { spell = 212653, type = "ability", charges = true, talent = 5 }, -- Shimmer
        { spell = 235450, type = "ability", buff = true}, -- Prismatic Barrier
      },
      icon = 136075
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 270670, type = "buff", unit = "player"}, --Arcane Pumeling
        { spell = 273330, type = "buff", unit = "player"}, --Brain Storm
        { spell = 280177, type = "buff", unit = "player"}, --Cauterizing Blink
        { spell = 264353, type = "buff", unit = "player"}, --Equipoise
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198111, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Temporal Shield
        { spell = 198111, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Temporal Shield
        { spell = 198065, type="buff", unit = "player", pvptalent = 9},-- Prismatic Cloak
        { spell = 198158, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Mass Invisibility
        { spell = 198158, type="buff", unit = "player", pvptalent = 13, titleSuffix = L["buff"]},-- Mass Invisibility
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
        { spell = 236060, type = "buff", unit = "player", talent = 13 }, -- Frenetic Speed
        { spell = 116267, type = "buff", unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 269651, type = "buff", unit = "player", talent = 20 }, -- Pyroclasm
        { spell = 45444, type = "buff", unit = "player"}, -- Bonfire's Blessing
        { spell = 48107, type = "buff", unit = "player"}, -- Heating Up
        { spell = 116014, type = "buff", unit = "player", talent = 9 }, -- Rune of Power
        { spell = 235313, type = "buff", unit = "player"}, -- Blazing Barrier
        { spell = 45438, type = "buff", unit = "player"}, -- Ice Block
        { spell = 157644, type = "buff", unit = "player"}, -- Enhanced Pyrotechnics
        { spell = 190319, type = "buff", unit = "player"}, -- Combustion
        { spell = 66, type = "buff", unit = "player"}, -- Invisibility
        { spell = 1459, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Arcane Intellect
        { spell = 130, type = "buff", unit = "player"}, -- Slow Fall
        { spell = 48108, type = "buff", unit = "player"}, -- Hot Streak!
      },
      icon = 1035045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 31661, type = "debuff", unit = "target"}, -- Dragon's Breath
        { spell = 2120, type = "debuff", unit = "target"}, -- Flamestrike
        { spell = 155158, type = "debuff", unit = "target", talent = 21 }, -- Meteor Burn
        { spell = 157981, type = "debuff", unit = "target", talent = 6 }, -- Blast Wave
        { spell = 226757, type = "debuff", unit = "target", talent = 17 }, -- Conflagration
        { spell = 217694, type = "debuff", unit = "target", talent = 18 }, -- Living Bomb
        { spell = 12654, type = "debuff", unit = "target"}, -- Ignite
        { spell = 82691, type = "debuff", unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 87023, type = "debuff", unit = "player" }, -- Cauterize
        { spell = 87024, type = "debuff", unit = "player" }, -- Cauterized
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
      },
      icon = 135818
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 66, type = "ability", buff = true}, -- Invisibility
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2120, type = "ability", overlayGlow = true}, -- Flamestrike
        { spell = 2139, type = "ability", requiresTarget = true}, -- Counterspell
        { spell = 11366, type = "ability", requiresTarget = true, overlayGlow = true}, -- Pyroblast
        { spell = 31661, type = "ability"}, -- Dragon's Breath
        { spell = 44457, type = "ability", debuff = true, requiresTarget = true, talent = 18 }, -- Living Bomb
        { spell = 45438, type = "ability", buff = true}, -- Ice Block
        { spell = 55342, type = "ability", talent = 8 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true}, -- Time Warp
        { spell = 108853, type = "ability", charges = true}, -- Fire Blast
        { spell = 113724, type = "ability", talent = 15 }, -- Ring of Frost
        { spell = 116011, type = "ability", charges = true, buff = true, talent = 9 }, -- Rune of Power
        { spell = 153561, type = "ability", talent = 21 }, -- Meteor
        { spell = 157981, type = "ability", talent = 6 }, -- Blast Wave
        { spell = 190319, type = "ability", buff = true}, -- Combustion
        { spell = 190336, type = "ability"}, -- Conjure Refreshment
        { spell = 212653, type = "ability", charges = true, talent = 5 }, -- Shimmer
        { spell = 235313, type = "ability", buff = true}, -- Blazing Barrier
        { spell = 257541, type = "ability", charges = true, talent = 12 }, -- Phoenix Flames
      },
      icon = 610633
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 274598, type = "buff", unit = "player"}, --Blaster Master
        { spell = 280177, type = "buff", unit = "player"}, --Cauterizing Blink
        { spell = 279715, type = "buff", unit = "player"}, --Firemind
        { spell = 288800, type = "buff", unit = "player"}, --Wildfire
        { spell = 277703, type = "debuff", unit = "multi"}, --Trailing Embers
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198111, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Temporal Shield
        { spell = 198111, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Temporal Shield
        { spell = 203285, type="buff", unit = "target", pvptalent = 7},-- Flamecannon
        { spell = 203277, type="buff", unit = "player", pvptalent = 13},-- Tinder
        { spell = 198065, type="buff", unit = "player", pvptalent = 14},-- Prismatic Cloak
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
        { spell = 199844, type = "buff", unit = "player", talent = 21 }, -- Glacial Spike!
        { spell = 45438, type = "buff", unit = "player"}, -- Ice Block
        { spell = 66, type = "buff", unit = "player"}, -- Invisibility
        { spell = 116267, type = "buff", unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 1459, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Arcane Intellect
        { spell = 108839, type = "buff", unit = "player", talent = 6 }, -- Ice Floes
        { spell = 278310, type = "buff", unit = "player", talent = 11 }, -- Chain Reaction
        { spell = 12472, type = "buff", unit = "player"}, -- Icy Veins
        { spell = 11426, type = "buff", unit = "player"}, -- Ice Barrier
        { spell = 130, type = "buff", unit = "player"}, -- Slow Fall
        { spell = 205473, type = "buff", unit = "player"}, -- Icicles
        { spell = 270232, type = "buff", unit = "player", talent = 16 }, -- Freezing Rain
        { spell = 190446, type = "buff", unit = "player"}, -- Brain Freeze
        { spell = 116014, type = "buff", unit = "player", talent = 9 }, -- Rune of Power
        { spell = 44544, type = "buff", unit = "player"}, -- Fingers of Frost
        { spell = 205766, type = "buff", unit = "player", talent = 1 }, -- Bone Chilling
      },
      icon = 236227
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 228354, type = "debuff", unit = "target"}, -- Flurry
        { spell = 205708, type = "debuff", unit = "target"}, -- Chilled
        { spell = 228600, type = "debuff", unit = "target", talent = 21 }, -- Glacial Spike
        { spell = 157997, type = "debuff", unit = "target", talent = 3 }, -- Ice Nova
        { spell = 228358, type = "debuff", unit = "target"}, -- Winter's Chill
        { spell = 205021, type = "debuff", unit = "target", talent = 20 }, -- Ray of Frost
        { spell = 122, type = "debuff", unit = "target"}, -- Frost Nova
        { spell = 82691, type = "debuff", unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 212792, type = "debuff", unit = "target"}, -- Cone of Cold
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
      },
      icon = 236208
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 66, type = "ability", buff = true}, -- Invisibility
        { spell = 120, type = "ability"}, -- Cone of Cold
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability", requiresTarget = true}, -- Counterspell
        { spell = 11426, type = "ability", buff = true}, -- Ice Barrier
        { spell = 12472, type = "ability", buff = true}, -- Icy Veins
        { spell = 30455, type = "ability", requiresTarget = true}, -- Ice Lance
        { spell = 31687, type = "ability"}, -- Summon Water Elemental
        { spell = 31707, type = "ability"}, -- Waterbolt
        { spell = 45438, type = "ability", buff = true}, -- Ice Block
        { spell = 55342, type = "ability", talent = 8 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true}, -- Time Warp
        { spell = 84714, type = "ability"}, -- Frozen Orb
        { spell = 108839, type = "ability", charges = true, buff = true, talent = 6 }, -- Ice Floes
        { spell = 113724, type = "ability", talent = 15 }, -- Ring of Frost
        { spell = 116011, type = "ability", charges = true, buff = true, talent = 9 }, -- Rune of Power
        { spell = 153595, type = "ability", requiresTarget = true, talent = 18 }, -- Comet Storm
        { spell = 157997, type = "ability", talent = 3 }, -- Ice Nova
        { spell = 190336, type = "ability"}, -- Conjure Refreshment
        { spell = 190356, type = "ability"}, -- Blizzard
        { spell = 199786, type = "ability", usable = true, requiresTarget = true, overlayGlow = true, talent = 21}, -- Glacial SPike
        { spell = 205021, type = "ability", requiresTarget = true, talent = 20 }, -- Ray of Frost
        { spell = 212653, type = "ability", charges = true, talent = 5 }, -- Shimmer
        { spell = 235219, type = "ability"}, -- Cold Snap
        { spell = 257537, type = "ability", requiresTarget = true, talent = 12 }, -- Ebonbolt
      },
      icon = 629077
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280177, type = "buff", unit = "player"}, --Cauterizing Blink
        { spell = 279684, type = "buff", unit = "player"}, --Frigid Grasp
        { spell = 275517, type = "buff", unit = "player"}, --Orbital Precision
        { spell = 277904, type = "buff", unit = "player"}, --Tunnel of Ice
        { spell = 273347, type = "buff", unit = "player"}, --Winter's Reach
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198065, type="buff", unit = "player", pvptalent = 5},-- Prismatic Cloak
        { spell = 206432, type="buff", unit = "player", pvptalent = 7},-- Burst of Cold
        { spell = 198144, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Ice Form
        { spell = 198144, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Ice Form
        { spell = 198111, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Temporal Shield
        { spell = 198111, type="buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]},-- Temporal Shield
        { spell = 198121, type="debuff", unit = "target", pvptalent = 13},-- Frostbite
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
        { spell = 196099, type = "buff", unit = "player", talent = 18 }, -- Grimoire of Sacrifice
        { spell = 104773, type = "buff", unit = "player"}, -- Unending Resolve
        { spell = 126, type = "buff", unit = "player"}, -- Eye of Kilrogg
        { spell = 113860, type = "buff", unit = "player", talent = 21 }, -- Dark Soul: Misery
        { spell = 48018, type = "buff", unit = "player", talent = 15 }, -- Demonic Circle
        { spell = 108416, type = "buff", unit = "player", talent = 9 }, -- Dark Pact
        { spell = 108366, type = "buff", unit = "player"}, -- Soul Leech
        { spell = 5697, type = "buff", unit = "player"}, -- Unending Breath
        { spell = 264571, type = "buff", unit = "player", talent = 1 }, -- Nightfall
        { spell = 111400, type = "buff", unit = "player", talent = 8 }, -- Burning Rush
        { spell = 20707, type = "buff", unit = "group"}, -- Soulstone
        { spell = 7870, type = "buff", unit = "pet"}, -- Lesser Invisibility
        { spell = 112042, type = "buff", unit = "pet"}, -- Threatening Presence
        { spell = 17767, type = "buff", unit = "pet"}, -- Shadow Bulwark
        { spell = 755, type = "buff", unit = "pet"}, -- Health Funnel
      },
      icon = 136210
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 233490, type = "debuff", unit = "target"}, -- Unstable Affliction
        { spell = 27243, type = "debuff", unit = "target"}, -- Seed of Corruption
        { spell = 710, type = "debuff", unit = "multi"}, -- Banish
        { spell = 234153, type = "debuff", unit = "target"}, -- Drain Life
        { spell = 6358, type = "debuff", unit = "target"}, -- Seduction
        { spell = 30283, type = "debuff", unit = "target"}, -- Shadowfury
        { spell = 6789, type = "debuff", unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 118699, type = "debuff", unit = "target"}, -- Fear
        { spell = 198590, type = "debuff", unit = "target", talent = 2 }, -- Drain Soul
        { spell = 17735, type = "debuff", unit = "target"}, -- Suffering
        { spell = 6360, type = "debuff", unit = "target"}, -- Whiplash
        { spell = 278350, type = "debuff", unit = "target", talent = 12 }, -- Vile Taint
        { spell = 1098, type = "debuff", unit = "multi"}, -- Enslave Demon
        { spell = 48181, type = "debuff", unit = "target", talent = 17 }, -- Haunt
        { spell = 32390, type = "debuff", unit = "target", talent = 16 }, -- Shadow Embrace
        { spell = 146739, type = "debuff", unit = "target"}, -- Corruption
        { spell = 205179, type = "debuff", unit = "target", talent = 11 }, -- Phantom Singularity
        { spell = 63106, type = "debuff", unit = "target", talent = 6 }, -- Siphon Life
        { spell = 980, type = "debuff", unit = "target"}, -- Agony
      },
      icon = 136139
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 172, type = "ability", requiresTarget = true, debuff = true}, -- Corruption
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 710, type = "ability", requiresTarget = true, debuff = true}, -- Banish
        { spell = 980, type = "ability", requiresTarget = true, debuff = true}, -- Agony
        { spell = 3110, type = "ability", requiresTarget = true}, -- Firebolt
        { spell = 3716, type = "ability", requiresTarget = true}, -- Consuming Shadows
        { spell = 5782, type = "ability", requiresTarget = true, debuff = true}, -- Fear
        { spell = 6358, type = "ability", requiresTarget = true}, -- Seduction
        { spell = 6360, type = "ability", requiresTarget = true}, -- Whiplash
        { spell = 6789, type = "ability", requiresTarget = true, talent = 15 }, -- Mortal Coil
        { spell = 7814, type = "ability", requiresTarget = true}, -- Lash of Pain
        { spell = 7870, type = "ability"}, -- Lesser Invisibility
        { spell = 17735, type = "ability", requiresTarget = true, debuff = true}, -- Suffering
        { spell = 17767, type = "ability"}, -- Shadow Bulwark
        { spell = 19505, type = "ability", requiresTarget = true}, -- Devour Magic
        { spell = 19647, type = "ability", requiresTarget = true}, -- Spell Lock
        { spell = 20707, type = "ability"}, -- Soulstone
        { spell = 27243, type = "ability", requiresTarget = true}, -- Seed of Corruption
        { spell = 29893, type = "ability"}, -- Create Soulwell
        { spell = 30108, type = "ability", requiresTarget = true}, -- Unstable Affliction
        { spell = 30283, type = "ability"}, -- Shadowfury
        { spell = 48018, type = "ability", talent = 15 }, -- Demonic Circle
        { spell = 48020, type = "ability", talent = 15 }, -- Demonic Circle: Teleport
        { spell = 48181, type = "ability", requiresTarget = true, debuff = true, talent = 17 }, -- Haunt
        { spell = 54049, type = "ability", requiresTarget = true}, -- Shadow Bite
        { spell = 63106, type = "ability", requiresTarget = true, debuff = true, talent = 6}, -- Siphon Life
        { spell = 89792, type = "ability" }, -- Flee
        { spell = 89808, type = "ability"}, -- Singe Magic
        { spell = 104773, type = "ability", buff = true}, -- Unending Resolve
        { spell = 108416, type = "ability", buff = true, talent = 9 }, -- Dark Pact
        { spell = 108503, type = "ability", talent = 18 }, -- Grimoire of Sacrifice
        { spell = 111771, type = "ability"}, -- Demonic Gateway
        { spell = 112042, type = "ability"}, -- Threatening Presence
        { spell = 113860, type = "ability", buff = true, talent = 21 }, -- Dark Soul: Misery
        { spell = 119910, type = "ability", requiresTarget = true}, -- Spell Lock
        { spell = 205179, type = "ability", requiresTarget = true, debuff = true, talent = 11 }, -- Phantom Singularity
        { spell = 205180, type = "ability", totem = true}, -- Summon Darkglare
        { spell = 232670, type = "ability", requiresTarget = true, overlayGlow = true}, -- Shadow Bolt
        { spell = 234153, type = "ability", requiresTarget = true}, -- Drain Life
        { spell = 264106, type = "ability", requiresTarget = true, talent = 3 }, -- Deathbolt
        { spell = 264993, type = "ability"}, -- Shadow Shield
        { spell = 278350, type = "ability", requiresTarget = true, talent = 12 }, -- Vile Taint
      },
      icon = 135808
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275378, type = "buff", unit = "player"}, --Cascading Calamity
        { spell = 280208, type = "buff", unit = "player"}, --Desperate Power
        { spell = 273525, type = "buff", unit = "player"}, --Inevitable Demise
        { spell = 274420, type = "buff", unit = "player"}, --Lifeblood
        { spell = 272893, type = "buff", unit = "player"}, --Wracking Brilliance
        { spell = 287828, type = "buff", unit = "player"}, --Terror of the Mind
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 199890, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Curse of Tongues
        { spell = 199890, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Curse of Tongues
        { spell = 285933, type="buff", unit = "player", pvptalent = 5},-- Demon Armor
        { spell = 221715, type="debuff", unit = "target", pvptalent = 6},-- Essence Drain
        { spell = 221703, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Casting Circle
        { spell = 221705, type="buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"]},-- Casting Circle
        { spell = 212356, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Soulshatter
        { spell = 236471, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Soulshatter
        { spell = 199892, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Curse of Weakness
        { spell = 199892, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"]},-- Curse of Weakness
        { spell = 199954, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Curse of Fragility
        { spell = 199954, type="debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]},-- Curse of Fragility
        { spell = 305388, type="debuff", unit = "target", pvptalent = 11},-- Endless Affliction
        { spell = 212295, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Nether Ward
        { spell = 212295, type="buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]},-- Nether Ward
        { spell = 234877, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Curse of Shadows
        { spell = 234877, type="debuff", unit = "target", pvptalent = 13, titleSuffix = L["debuff"]},-- Curse of Shadows
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
        { spell = 104773, type = "buff", unit = "player"}, -- Unending Resolve
        { spell = 126, type = "buff", unit = "player"}, -- Eye of Kilrogg
        { spell = 267218, type = "buff", unit = "player", talent = 21 }, -- Nether Portal
        { spell = 48018, type = "buff", unit = "player", talent = 15 }, -- Demonic Circle
        { spell = 108416, type = "buff", unit = "player", talent = 9 }, -- Dark Pact
        { spell = 108366, type = "buff", unit = "player"}, -- Soul Leech
        { spell = 205146, type = "buff", unit = "player", talent = 4 }, -- Demonic Calling
        { spell = 5697, type = "buff", unit = "player"}, -- Unending Breath
        { spell = 265273, type = "buff", unit = "player"}, -- Demonic Power
        { spell = 111400, type = "buff", unit = "player", talent = 8 }, -- Burning Rush
        { spell = 20707, type = "buff", unit = "group"}, -- Soulstone
        { spell = 264173, type = "buff", unit = "player"}, -- Demonic Core
        { spell = 134477, type = "buff", unit = "pet"}, -- Threatening Presence
        { spell = 30151, type = "buff", unit = "pet"}, -- Pursuit
        { spell = 267171, type = "buff", unit = "pet", talent = 2 }, -- Demonic Strength
        { spell = 17767, type = "buff", unit = "pet"}, -- Shadow Bulwark
        { spell = 89751, type = "buff", unit = "pet"}, -- Felstorm
        { spell = 755, type = "buff", unit = "pet"}, -- Health Funnel
      },
      icon = 1378284
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 270569, type = "debuff", unit = "target", talent = 10 }, -- From the Shadows
        { spell = 267997, type = "debuff", unit = "target", talent = 3 }, -- Bile Spit
        { spell = 17735, type = "debuff", unit = "target"}, -- Suffering
        { spell = 118699, type = "debuff", unit = "target"}, -- Fear
        { spell = 30283, type = "debuff", unit = "target"}, -- Shadowfury
        { spell = 89766, type = "debuff", unit = "target"}, -- Axe Toss
        { spell = 6789, type = "debuff", unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 234153, type = "debuff", unit = "target"}, -- Drain Life
        { spell = 30213, type = "debuff", unit = "target"}, -- Legion Strike
        { spell = 6360, type = "debuff", unit = "target"}, -- Whiplash
        { spell = 265412, type = "debuff", unit = "target", talent = 6 }, -- Doom
        { spell = 710, type = "debuff", unit = "multi"}, -- Banish
        { spell = 1098, type = "debuff", unit = "multi"}, -- Enslave Demon
        { spell = 6358, type = "debuff", unit = "target"}, -- Seduction
      },
      icon = 136122
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 686, type = "ability", requiresTarget = true}, -- Shadow Bolt
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 710, type = "ability", requiresTarget = true, debuff = true}, -- Banish
        { spell = 3716, type = "ability", requiresTarget = true}, -- Consuming Shadows
        { spell = 5782, type = "ability", requiresTarget = true, debuff = true}, -- Fear
        { spell = 6360, type = "ability", requiresTarget = true}, -- Whiplash
        { spell = 6789, type = "ability", requiresTarget = true, talent = 14 }, -- Mortal Coil
        { spell = 7814, type = "ability", requiresTarget = true}, -- Lash of Pain
        { spell = 7870, type = "ability"}, -- Lesser Invisibility
        { spell = 17735, type = "ability", requiresTarget = true, debuff = true}, -- Suffering
        { spell = 17767, type = "ability"}, -- Shadow Bulwark
        { spell = 19505, type = "ability", requiresTarget = true}, -- Devour Magic
        { spell = 19647, type = "ability", requiresTarget = true}, -- Spell Lock
        { spell = 20707, type = "ability"}, -- Soulstone
        { spell = 29893, type = "ability"}, -- Create Soulwell
        { spell = 30151, type = "ability", requiresTarget = true}, -- Pursuit
        { spell = 30213, type = "ability", requiresTarget = true}, -- Legion Strike
        { spell = 30283, type = "ability"}, -- Shadowfury
        { spell = 48018, type = "ability", talent = 15 }, -- Demonic Circle
        { spell = 48020, type = "ability", talent = 15 }, -- Demonic Circle: Teleport
        { spell = 54049, type = "ability", requiresTarget = true}, -- Shadow Bite
        { spell = 89751, type = "ability"}, -- Felstorm
        { spell = 89766, type = "ability", requiresTarget = true, debuff = true}, -- Axe Toss
        { spell = 89792, type = "ability"}, -- Flee
        { spell = 89808, type = "ability"}, -- Singe Magic
        { spell = 104316, type = "ability", requiresTarget = true, overlayGlow = true}, -- Call Dreadstalkers
        { spell = 104773, type = "ability", buff = true}, -- Unending Resolve
        { spell = 105174, type = "ability", requiresTarget = true}, -- Hand of Gul'dan
        { spell = 108416, type = "ability", buff = true, talent = 9 }, -- Dark Pact
        { spell = 111771, type = "ability"}, -- Demonic Gateway
        { spell = 111898, type = "ability", requiresTarget = true, talent = 18 }, -- Grimoire: Felguard
        { spell = 112042, type = "ability"}, -- Threatening Presence
        { spell = 264057, type = "ability", requiresTarget = true, talent = 11 }, -- Soul Strike
        { spell = 264119, type = "ability", talent = 12 }, -- Summon Vilefiend
        { spell = 264130, type = "ability", usable = true, talent = 5 }, -- Power Siphon
        { spell = 264178, type = "ability", requiresTarget = true, overlayGlow = true}, -- Demonbolt
        { spell = 264993, type = "ability"}, -- Shadow Shield
        { spell = 265187, type = "ability"}, -- Summon Demonic Tyrant
        { spell = 265412, type = "ability", requiresTarget = true, debuff = true, talent = 6}, -- Doom
        { spell = 267171, type = "ability", requiresTarget = true, talent = 2 }, -- Demonic Strength
        { spell = 267211, type = "ability", talent = 3 }, -- Bilescourge Bombers
        { spell = 267217, type = "ability", buff = true, talent = 21 }, -- Nether Portal
        { spell = 6358, type = "ability", requiresTarget = true}, -- Seduction
      },
      icon = 1378282
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 280208, type = "buff", unit = "player"}, --Desperate Power
        { spell = 276027, type = "buff", unit = "player"}, --Excoriate
        { spell = 275398, type = "buff", unit = "player"}, --Explosive Potential
        { spell = 274420, type = "buff", unit = "player"}, --Lifeblood
        { spell = 272945, type = "buff", unit = "player"}, --Shadow's Bite
        { spell = 279885, type = "buff", unit = "player"}, --Supreme Commander
        { spell = 273526, type = "debuff", unit = "target"}, --Umbral Blaze
        { spell = 287828, type = "buff", unit = "player"}, --Terror of the Mind
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 201996, type="ability", pvptalent = 4},-- Call Observer
        { spell = 212295, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Nether Ward
        { spell = 212295, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Nether Ward
        { spell = 221715, type="debuff", unit = "target", pvptalent = 6},-- Essence Drain
        { spell = 221703, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Casting Circle
        { spell = 221705, type="buff", unit = "target", pvptalent = 7, titleSuffix = L["buff"]},-- Casting Circle
        { spell = 199890, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Curse of Tongues
        { spell = 199890, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Curse of Tongues
        { spell = 199954, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Curse of Fragility
        { spell = 199954, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"]},-- Curse of Fragility
        { spell = 199892, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Curse of Weakness
        { spell = 199892, type="debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]},-- Curse of Weakness
        { spell = 212623, type="ability", pvptalent = 11},-- Singe Magic
        { spell = 212619, type="ability", pvptalent = 12},-- Call Felhunter
        { spell = 212459, type="ability", pvptalent = 14},-- Call Fel Lord
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
        { spell = 104773, type = "buff", unit = "player"}, -- Unending Resolve
        { spell = 126, type = "buff", unit = "player"}, -- Eye of Kilrogg
        { spell = 113858, type = "buff", unit = "player", talent = 21 }, -- Dark Soul: Instability
        { spell = 196099, type = "buff", unit = "player", talent = 18 }, -- Grimoire of Sacrifice
        { spell = 266091, type = "buff", unit = "player", talent = 17 }, -- Grimoire of Supremacy
        { spell = 108366, type = "buff", unit = "player"}, -- Soul Leech
        { spell = 266030, type = "buff", unit = "player", talent = 4 }, -- Reverse Entropy
        { spell = 5697, type = "buff", unit = "player"}, -- Unending Breath
        { spell = 48018, type = "buff", unit = "player", talent = 15 }, -- Demonic Circle
        { spell = 111400, type = "buff", unit = "player", talent = 8 }, -- Burning Rush
        { spell = 20707, type = "buff", unit = "group"}, -- Soulstone
        { spell = 108416, type = "buff", unit = "player", talent = 9 }, -- Dark Pact
        { spell = 117828, type = "buff", unit = "player"}, -- Backdraft
        { spell = 7870, type = "buff", unit = "pet"}, -- Lesser Invisibility
        { spell = 112042, type = "buff", unit = "pet"}, -- Threatening Presence
        { spell = 17767, type = "buff", unit = "pet"}, -- Shadow Bulwark
        { spell = 108366, type = "buff", unit = "pet"}, -- Soul Leech
        { spell = 755, type = "buff", unit = "pet"}, -- Health Funnel
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 157736, type = "debuff", unit = "target"}, -- Immolate
        { spell = 22703, type = "debuff", unit = "target"}, -- Infernal Awakening
        { spell = 265931, type = "debuff", unit = "target"}, -- Conflagrate
        { spell = 17735, type = "debuff", unit = "target"}, -- Suffering
        { spell = 118699, type = "debuff", unit = "target"}, -- Fear
        { spell = 80240, type = "debuff", unit = "target"}, -- Havoc
        { spell = 6789, type = "debuff", unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 196414, type = "debuff", unit = "target", talent = 2 }, -- Eradication
        { spell = 234153, type = "debuff", unit = "target"}, -- Drain Life
        { spell = 6360, type = "debuff", unit = "target"}, -- Whiplash
        { spell = 30283, type = "debuff", unit = "target"}, -- Shadowfury
        { spell = 710, type = "debuff", unit = "multi"}, -- Banish
        { spell = 1098, type = "debuff", unit = "multi"}, -- Enslave Demon
        { spell = 6358, type = "debuff", unit = "target"}, -- Seduction

      },
      icon = 135817
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 348, type = "ability", requiresTarget = true, debuff = true}, -- Immolate
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 710, type = "ability", requiresTarget = true, debuff = true}, -- Banish
        { spell = 1122, type = "ability", duration = 30}, -- Summon Infernal
        { spell = 3110, type = "ability", requiresTarget = true}, -- Firebolt
        { spell = 3716, type = "ability", requiresTarget = true}, -- Consuming Shadows
        { spell = 5740, type = "ability"}, -- Rain of Fire
        { spell = 5782, type = "ability", requiresTarget = true, debuff = true}, -- Fear
        { spell = 6353, type = "ability", talent = 3 }, -- Soul Fire
        { spell = 6360, type = "ability", requiresTarget = true}, -- Whiplash
        { spell = 6789, type = "ability", requiresTarget = true, talent = 14 }, -- Mortal Coil
        { spell = 7814, type = "ability", requiresTarget = true}, -- Lash of Pain
        { spell = 7870, type = "ability"}, -- Lesser Invisibility
        { spell = 17735, type = "ability", requiresTarget = true, debuff = true}, -- Suffering
        { spell = 17767, type = "ability"}, -- Shadow Bulwark
        { spell = 17877, type = "ability", requiresTarget = true, charges = true, talent = 6 }, -- Shadowburn
        { spell = 17962, type = "ability", requiresTarget = true, charges = true}, -- Conflagrate
        { spell = 19647, type = "ability", requiresTarget = true}, -- Spell Lock
        { spell = 20707, type = "ability"}, -- Soulstone
        { spell = 29722, type = "ability", requiresTarget = true}, -- Incinerate
        { spell = 29893, type = "ability"}, -- Create Soulwell
        { spell = 30283, type = "ability"}, -- Shadowfury
        { spell = 48018, type = "ability", talent = 15 }, -- Demonic Circle
        { spell = 48020, type = "ability", talent = 15 }, -- Demonic Circle: Teleport
        { spell = 54049, type = "ability", requiresTarget = true}, -- Shadow Bite
        { spell = 80240, type = "ability", requiresTarget = true, debuff = true}, -- Havoc
        { spell = 89792, type = "ability"}, -- Flee
        { spell = 89808, type = "ability"}, -- Singe Magic
        { spell = 104773, type = "ability", buff = true}, -- Unending Resolve
        { spell = 108416, type = "ability", buff = true, talent = 9 }, -- Dark Pact
        { spell = 108503, type = "ability", talent = 18 }, -- Grimoire of Sacrifice
        { spell = 111771, type = "ability"}, -- Demonic Gateway
        { spell = 112042, type = "ability"}, -- Threatening Presence
        { spell = 113858, type = "ability", buff = true, talent = 21 }, -- Dark Soul: Instability
        { spell = 152108, type = "ability", talent = 12 }, -- Cataclysm
        { spell = 116858, type = "ability", requiresTarget = true}, -- Chaos Bolt
        { spell = 196447, type = "ability", usable = true, talent = 20 }, -- Channel Demonfire
        { spell = 234153, type = "ability", requiresTarget = true}, -- Drain Life
        { spell = 264993, type = "ability"}, -- Shadow Shield
        { spell = 6358, type = "ability", requiresTarget = true}, -- Seduction
      },
      icon = 135807
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 287660, type = "buff", unit = "player"}, --Chaos Shards
        { spell = 279913, type = "buff", unit = "player"}, --Bursting Flare
        { spell = 279673, type = "buff", unit = "player"}, --Chaotic Inferno
        { spell = 280208, type = "buff", unit = "player"}, --Desperate Power
        { spell = 275429, type = "buff", unit = "player"}, --Flashpoint
        { spell = 274420, type = "buff", unit = "player"}, --Lifeblood
        { spell = 278931, type = "buff", unit = "player"}, --Rolling Havoc
        { spell = 277706, type = "buff", unit = "player"}, --Crashing Chaos
        { spell = 287828, type = "buff", unit = "player"}, --Terror of the Mind
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 200587, type="debuff", unit = "target", pvptalent = 5},-- Fel Fissure
        { spell = 233582, type="debuff", unit = "target", pvptalent = 6},-- Entrenched in Flame
        { spell = 285933, type="buff", unit = "target", pvptalent = 7},-- Demon Armor
        { spell = 200546, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Bane of Havoc
        { spell = 200548, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Bane of Havoc
        { spell = 199954, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Curse of Fragility
        { spell = 199954, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"]},-- Curse of Fragility
        { spell = 199890, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Curse of Tongues
        { spell = 199890, type="debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]},-- Curse of Tongues
        { spell = 199892, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Curse of Weakness
        { spell = 199892, type="buff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Curse of Weakness
        { spell = 212295, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Nether Ward
        { spell = 212295, type="buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]},-- Nether Ward
        { spell = 221715, type="debuff", unit = "target", pvptalent = 13},-- Essence Drain
        { spell = 221703, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Casting Circle
        { spell = 221705, type="buff", unit = "target", pvptalent = 14, titleSuffix = L["buff"]},-- Casting Circle
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
        { spell = 116847, type = "buff", unit = "player", talent = 17 }, -- Rushing Jade Wind
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 119085, type = "buff", unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 195630, type = "buff", unit = "player"}, -- Elusive Brawler
        { spell = 228563, type = "buff", unit = "player", talent = 21 }, -- Blackout Combo
        { spell = 215479, type = "buff", unit = "player"}, -- Ironskin Brew
        { spell = 115176, type = "buff", unit = "player"}, -- Zen Meditation
        { spell = 115295, type = "buff", unit = "player", talent = 20 }, -- Guard
        { spell = 116841, type = "buff", unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 120954, type = "buff", unit = "player"}, -- Fortifying Brew
        { spell = 196608, type = "buff", unit = "player", talent = 1 }, -- Eye of the Tiger
        { spell = 101643, type = "buff", unit = "player"}, -- Transcendence
        { spell = 2479, type = "buff", unit = "player"}, -- Honorless Target

      },
      icon = 613398
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 119381, type = "debuff", unit = "target"}, -- Leg Sweep
        { spell = 196608, type = "debuff", unit = "target", talent = 1 }, -- Eye of the Tiger
        { spell = 113746, type = "debuff", unit = "target"}, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "multi"}, -- Paralysis
        { spell = 117952, type = "debuff", unit = "target"}, -- Crackling Jade Lightning
        { spell = 121253, type = "debuff", unit = "target"}, -- Keg Smash
        { spell = 116189, type = "debuff", unit = "target"}, -- Provoke
        { spell = 124273, type = "debuff", unit = "player" }, -- Heavy Stagger
        { spell = 124274, type = "debuff", unit = "player" }, -- Moderate Stagger
        { spell = 124275, type = "debuff", unit = "player" }, -- Light Stagger
      },
      icon = 611419
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 107079, type = "ability"}, -- Quaking Palm
        { spell = 109132, type = "ability", charges = true}, -- Roll
        { spell = 115008, type = "ability", charges = true, talent = 5 }, -- Chi Torpedo
        { spell = 115078, type = "ability", requiresTarget = true}, -- Paralysis
        { spell = 115098, type = "ability", talent = 2 }, -- Chi Wave
        { spell = 115176, type = "ability", buff = true}, -- Zen Meditation
        { spell = 115181, type = "ability"}, -- Breath of Fire
        { spell = 115203, type = "ability", buff = true}, -- Fortifying Brew
        { spell = 115295, type = "ability", talent = 20 }, -- Guard
        { spell = 115308, type = "ability", charges = true, buff = true}, -- Ironskin Brew
        { spell = 115315, type = "ability", totem = true, totemNumber = 1, talent = 11 }, -- Summon Black Ox Statue
        { spell = 115399, type = "ability", talent = 9 }, -- Black Ox Brew
        { spell = 115546, type = "ability", debuff = true, requiresTarget = true}, -- Provoke
        { spell = 116705, type = "ability"}, -- Spear Hand Strike
        { spell = 116841, type = "ability", talent = 3 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 12 }, -- Ring of Peace
        { spell = 116847, type = "ability", buff = true, talent = 17 }, -- Rushing Jade Wind
        { spell = 119381, type = "ability"}, -- Leg Sweep
        { spell = 119582, type = "ability", charges = true}, -- Purifying Brew
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 121253, type = "ability", requiresTarget = true}, -- Keg Smash
        { spell = 122278, type = "ability", buff = true, talent = 15 }, -- Dampen Harm
        { spell = 122281, type = "ability", charges = true, buff = true, talent = 14 }, -- Healing Elixir
        { spell = 123986, type = "ability", talent = 3 }, -- Chi Burst
        { spell = 126892, type = "ability"}, -- Zen Pilgrimage
        { spell = 132578, type = "ability", requiresTarget = true, talent = 18 }, -- Invoke Niuzao, the Black Ox
        { spell = 205523, type = "ability", requiresTarget = true}, -- Blackout Strike
        { spell = 218164, type = "ability"}, -- Detox

      },
      icon = 133701
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 275893, type = "buff", unit = "player"}, --Fit to Burst
        { spell = 285959, type = "buff", unit = "player"}, --Straight, No Chaser
        { spell = 273469, type = "buff", unit = "player"}, --Staggering Strikes
        { spell = 274774, type = "buff", unit = "player"}, --Strength of Spirit
        { spell = 280187, type = "buff", unit = "player"}, --Sweep the Leg
        { spell = 278767, type = "buff", unit = "player"}, --Training of Niuzao
        { spell = 289324, type = "buff", unit = "player"}, --Exit Strategy
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 202370, type="ability", pvptalent = 5},-- Mighty Ox Kick
        { spell = 202335, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Double Barrel
        { spell = 202335, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Double Barrel
        { spell = 213658, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Craft: Nimble Brew
        { spell = 213664, type="buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"]},-- Craft: Nimble Brew
        { spell = 202162, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Avert Harm
        { spell = 202162, type="buff", unit = "group", pvptalent = 8, titleSuffix = L["buff"]},-- Avert Harm
        { spell = 207025, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Admonishment
        { spell = 206891, type="debuff", unit = "target", pvptalent = 13, titleSuffix = L["debuff"]},-- Admonishment
        { spell = 202274, type="debuff", unit = "target", pvptalent = 14},-- Incendiary Breath
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
        { spell = 119611, type = "buff", unit = "target"}, -- Renewing Mist
        { spell = 196725, type = "buff", unit = "player", talent = 17 }, -- Refreshing Jade Wind
        { spell = 122783, type = "buff", unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 116680, type = "buff", unit = "player"}, -- Thunder Focus Tea
        { spell = 243435, type = "buff", unit = "player"}, -- Fortifying Brew
        { spell = 124682, type = "buff", unit = "target"}, -- Enveloping Mist
        { spell = 116841, type = "buff", unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 197908, type = "buff", unit = "player", talent = 9 }, -- Mana Tea
        { spell = 191840, type = "buff", unit = "player"}, -- Essence Font
        { spell = 115175, type = "buff", unit = "target"}, -- Soothing Mist
        { spell = 119085, type = "buff", unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 202090, type = "buff", unit = "player"}, -- Teachings of the Monastery
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 197919, type = "buff", unit = "player", talent = 7 }, -- Lifecycles (Enveloping Mist)
        { spell = 116849, type = "buff", unit = "target"}, -- Life Cocoon
        { spell = 101643, type = "buff", unit = "player"}, -- Transcendence
        { spell = 197916, type = "buff", unit = "player", talent = 7 }, -- Lifecycles (Vivify)

      },
      icon = 627487
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 119381, type = "debuff", unit = "target"}, -- Leg Sweep
        { spell = 115078, type = "debuff", unit = "multi"}, -- Paralysis
        { spell = 117952, type = "debuff", unit = "target"}, -- Crackling Jade Lightning
        { spell = 116189, type = "debuff", unit = "target"}, -- Provoke
        { spell = 113746, type = "debuff", unit = "target"}, -- Mystic Touch
      },
      icon = 629534
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100784, type = "ability", requiresTarget = true}, -- Blackout Kick
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 107079, type = "ability"}, -- Quaking Palm
        { spell = 107428, type = "ability", requiresTarget = true}, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true}, -- Roll
        { spell = 115008, type = "ability", charges = true, talent = 5 }, -- Chi Torpedo
        { spell = 115078, type = "ability", requiresTarget = true}, -- Paralysis
        { spell = 115098, type = "ability", talent = 2 }, -- Chi Wave
        { spell = 115151, type = "ability", charges = true}, -- Renewing Mist
        { spell = 115310, type = "ability"}, -- Revival
        { spell = 115313, type = "ability", totem = true, totemNumber = 1, talent = 16 }, -- Summon Jade Serpent Statue
        { spell = 115540, type = "ability"}, -- Detox
        { spell = 115546, type = "ability", debuff = true, requiresTarget = true}, -- Provoke
        { spell = 116680, type = "ability", buff = true}, -- Thunder Focus Tea                    -- add talent = 19 abilityChargeBuff
        { spell = 116841, type = "ability", talent = 6 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 12 }, -- Ring of Peace
        { spell = 116849, type = "ability"}, -- Life Cocoon
        { spell = 119381, type = "ability"}, -- Leg Sweep
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 122278, type = "ability", buff = true, talent = 15 }, -- Dampen Harm
        { spell = 122281, type = "ability", charges = true, buff = true, talent = 13 }, -- Healing Elixir
        { spell = 122783, type = "ability", buff = true, talent = 14 }, -- Diffuse Magic
        { spell = 123986, type = "ability", talent = 3 }, -- Chi Burst
        { spell = 126892, type = "ability"}, -- Zen Pilgrimage
        { spell = 191837, type = "ability"}, -- Essence Font
        { spell = 196725, type = "ability", buff = true, talent = 17 }, -- Refreshing Jade Wind
        { spell = 197908, type = "ability", buff = true, talent = 9 }, -- Mana Tea
        { spell = 198664, type = "ability", talent = 18 }, -- Invoke Chi-Ji, the Red Crane
        { spell = 198898, type = "ability", talent = 11 }, -- Song of Chi-Ji
        { spell = 243435, type = "ability", buff = true}, -- Fortifying Brew
      },
      icon = 627485
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 276025, type = "buff", unit = "player"}, --Misty Peaks
        { spell = 273348, type = "buff", unit = "target"}, --Overflowing Mists
        { spell = 274774, type = "buff", unit = "player"}, --Strength of Spirit
        { spell = 273299, type = "debuff", unit = "target"}, --Sunrise Technique
        { spell = 280187, type = "buff", unit = "player"}, --Sweep the Leg
        { spell = 289324, type = "buff", unit = "player"}, --Exit Strategy
        { spell = 287837, type = "buff", unit = "player"}, --Secret Infusion
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 216113, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Way of the Crane
        { spell = 216113, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Way of the Crane
        { spell = 233759, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Grapple Weapon
        { spell = 233759, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Grapple Weapon
        { spell = 205234, type="ability", pvptalent = 8},-- Healing Sphere
        { spell = 227344, type="buff", unit = "target", pvptalent = 9},-- Surging Mist
        { spell = 209584, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Zen Focus Tea
        { spell = 209584, type="buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]},-- Zen Focus Tea
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
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 125174, type = "buff", unit = "player"}, -- Touch of Karma
        { spell = 119085, type = "buff", unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 152173, type = "buff", unit = "player", talent = 21 }, -- Serenity
        { spell = 261715, type = "buff", unit = "player", talent = 17 }, -- Rushing Jade Wind
        { spell = 101643, type = "buff", unit = "player"}, -- Transcendence
        { spell = 261769, type = "buff", unit = "player", talent = 13 }, -- Inner Strength
        { spell = 116841, type = "buff", unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 122783, type = "buff", unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 137639, type = "buff", unit = "player"}, -- Storm, Earth, and Fire
        { spell = 196741, type = "buff", unit = "player", talent = 16 }, -- Hit Combo
        { spell = 196608, type = "buff", unit = "player", talent = 1 }, -- Eye of the Tiger
        { spell = 166646, type = "buff", unit = "player" }, -- Windwalking
        { spell = 116768, type = "buff", unit = "player"}, -- Blackout Kick!
      },
      icon = 611420
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115078, type = "debuff", unit = "multi"}, -- Paralysis
        { spell = 116189, type = "debuff", unit = "target"}, -- Provoke
        { spell = 115080, type = "debuff", unit = "target"}, -- Touch of Death
        { spell = 113746, type = "debuff", unit = "target"}, -- Mystic Touch
        { spell = 228287, type = "debuff", unit = "target"}, -- Mark of the Crane
        { spell = 115804, type = "debuff", unit = "target"}, -- Mortal Wounds
        { spell = 116706, type = "debuff", unit = "target"}, -- Disable
        { spell = 117952, type = "debuff", unit = "target"}, -- Crackling Jade Lightning
        { spell = 196608, type = "debuff", unit = "target", talent = 1 }, -- Eye of the Tiger
        { spell = 122470, type = "debuff", unit = "target"}, -- Touch of Karma
        { spell = 119381, type = "debuff", unit = "target"}, -- Leg Sweep
        { spell = 123586, type = "debuff", unit = "target"}, -- Flying Serpent Kick

      },
      icon = 629534
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100780, type = "ability", requiresTarget = true}, -- Tiger Palm
        { spell = 100784, type = "ability", requiresTarget = true, overlayGlow = true}, -- Blackout Kick
        { spell = 101545, type = "ability"}, -- Flying Serpent Kick
        { spell = 101546, type = "ability"}, -- Spinning Crane Kick
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 107428, type = "ability", requiresTarget = true}, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true}, -- Roll
        { spell = 113656, type = "ability", requiresTarget = true}, -- Fists of Fury
        { spell = 115008, type = "ability", charges = true, talent = 5 }, -- Chi Torpedo
        { spell = 115078, type = "ability", requiresTarget = true}, -- Paralysis
        { spell = 115080, type = "ability", debuff = true, requiresTarget = true}, -- Touch of Death
        { spell = 115098, type = "ability", talent = 2 }, -- Chi Wave
        { spell = 115288, type = "ability", talent = 9 }, -- Energizing Elixir
        { spell = 115546, type = "ability", debuff = true, requiresTarget = true}, -- Provoke
        { spell = 116095, type = "ability", requiresTarget = true}, -- Disable
        { spell = 116705, type = "ability", requiresTarget = true}, -- Spear Hand Strike
        { spell = 116841, type = "ability", talent = 6 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 12 }, -- Ring of Peace
        { spell = 119381, type = "ability"}, -- Leg Sweep
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 122278, type = "ability", buff = true, talent = 15 }, -- Dampen Harm
        { spell = 122470, type = "ability", debuff = true, requiresTarget = true}, -- Touch of Karma
        { spell = 122783, type = "ability", buff = true, talent = 14 }, -- Diffuse Magic
        { spell = 123904, type = "ability", requiresTarget = true, talent = 18 }, -- Invoke Xuen, the White Tiger
        { spell = 123986, type = "ability", talent = 3 }, -- Chi Burst
        { spell = 126892, type = "ability"}, -- Zen Pilgrimage
        { spell = 137639, type = "ability", charges = true, buff = true}, -- Storm, Earth, and Fire
        { spell = 152173, type = "ability", buff = true, talent = 21 }, -- Serenity
        { spell = 152175, type = "ability", usable = true, talent = 20 }, -- Whirling Dragon Punch
        { spell = 218164, type = "ability"}, -- Detox
        { spell = 261715, type = "ability", buff = true, talent = 17 }, -- Rushing Jade Wind
        { spell = 261947, type = "ability", talent = 8 }, -- Fist of the White Tiger
      },
      icon = 627606
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 287062, type = "buff", unit = "player"}, --Fury of Xuen
        { spell = 279922, type = "buff", unit = "player"}, --Open Palm Strikes
        { spell = 273299, type = "debuff", unit = "target"}, --Sunrise Technique
        { spell = 286587, type = "buff", unit = "player"}, --Dance of Chi-Ji
        { spell = 289324, type = "buff", unit = "player"}, --Exit Strategy
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 233759, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Grapple Weapon
        { spell = 233759, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Grapple Weapon
        { spell = 287504, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Alpha Tiger
        { spell = 290512, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Alpha Tiger
        { spell = 201787, type="debuff", unit = "target", pvptalent = 7},-- Turbo Fists
        { spell = 287771, type="ability", pvptalent = 9},-- Reverse Harm
        { spell = 201447, type="buff", unit = "player", pvptalent = 11},-- Ride the Wind
        { spell = 201318, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Fortifying Brew
        { spell = 201318, type="buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]},-- Fortifying Brew
        { spell = 247483, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Tigereye Brew
        { spell = 248646, type="buff", unit = "player", pvptalent = 13, titleSuffix = L["buff"]},-- Tigereye Brew
        { spell = 247483, type="buff", unit = "player", pvptalent = 13, titleSuffix = L["buff"]},-- Tigereye Brew
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
        { spell = 279709, type = "buff", unit = "player", talent = 14 }, -- Starlord
        { spell = 22842, type = "buff", unit = "player", talent = 7 }, -- Frenzied Regeneration
        { spell = 24858, type = "buff", unit = "player"}, -- Moonkin Form
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 202425, type = "buff", unit = "player", talent = 2 }, -- Warrior of Elune
        { spell = 164547, type = "buff", unit = "player"}, -- Lunar Empowerment
        { spell = 5487, type = "buff", unit = "player"}, -- Bear Form
        { spell = 8936, type = "buff", unit = "player"}, -- Regrowth
        { spell = 252216, type = "buff", unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 194223, type = "buff", unit = "player"}, -- Celestial Alignment
        { spell = 191034, type = "buff", unit = "player"}, -- Starfall
        { spell = 102560, type = "buff", unit = "player", talent = 15 }, -- Incarnation: Chosen of Elune
        { spell = 164545, type = "buff", unit = "player"}, -- Solar Empowerment
        { spell = 783, type = "buff", unit = "player"}, -- Travel Form
        { spell = 768, type = "buff", unit = "player"}, -- Cat Form
        { spell = 202461, type = "buff", unit = "player", talent = 18 }, -- Stellar Drift
        { spell = 48438, type = "buff", unit = "player", talent = 9 }, -- Wild Growth
        { spell = 192081, type = "buff", unit = "player", talent = 8 }, -- Ironfur
        { spell = 22812, type = "buff", unit = "player"}, -- Barkskin
        { spell = 1850, type = "buff", unit = "player"}, -- Dash
        { spell = 5215, type = "buff", unit = "player"}, -- Prowl
        { spell = 29166, type = "buff", unit = "group"}, -- Innervate
      },
      icon = 136097
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 155722, type = "debuff", unit = "target", talent = 7 }, -- Rake
        { spell = 205644, type = "debuff", unit = "target", talent = 3 }, -- Force of Nature
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 339, type = "debuff", unit = "multi"}, -- Entangling Roots
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 1079, type = "debuff", unit = "target", talent = 7 }, -- Rip
        { spell = 164815, type = "debuff", unit = "target"}, -- Sunfire
        { spell = 202347, type = "debuff", unit = "target", talent = 18 }, -- Stellar Flare
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 192090, type = "debuff", unit = "target", talent = 8 }, -- Thrash
        { spell = 164812, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 6795, type = "debuff", unit = "target"}, -- Growl
        { spell = 81261, type = "debuff", unit = "target"}, -- Solar Beam
        { spell = 2637, type = "debuff", unit = "multi"}, -- Hibernate
      },
      icon = 132114
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 768, type = "ability"}, -- Cat Form
        { spell = 783, type = "ability"}, -- Travel Form
        { spell = 1850, type = "ability", buff = true}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true}, -- Soothe
        { spell = 5211, type = "ability", requiresTarget = true, talent = 6 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true}, -- Prowl
        { spell = 5487, type = "ability"}, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true}, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true, debuff = true}, -- Moonfire
        { spell = 16979, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 18562, type = "ability", talent = 9 }, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22812, type = "ability", buff = true}, -- Barkskin
        { spell = 22842, type = "ability", buff = true, talent = 8 }, -- Frenzied Regeneration
        { spell = 24858, type = "ability"}, -- Moonkin Form
        { spell = 29166, type = "ability", buff = true}, -- Innervate
        { spell = 33917, type = "ability", requiresTarget = true}, -- Mangle
        { spell = 48438, type = "ability", talent = 9 }, -- Wild Growth
        { spell = 49376, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 77758, type = "ability", talent = 8 }, -- Thrash
        { spell = 78674, type = "ability", requiresTarget = true}, -- Starsurge
        { spell = 78675, type = "ability", requiresTarget = true}, -- Solar Beam
        { spell = 93402, type = "ability", requiresTarget = true, debuff = true}, -- Sunfire
        { spell = 102359, type = "ability", requiresTarget = true, talent = 11 }, -- Mass Entanglement
        { spell = 102383, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102401, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102560, type = "ability", buff = true, talent = 15 }, -- Incarnation: Chosen of Elune
        { spell = 108238, type = "ability", talent = 9 }, -- Renewal
        { spell = 132469, type = "ability", talent = 12 }, -- Typhoon
        { spell = 190984, type = "ability", requiresTarget = true, overlayGlow = true}, -- Solar Wrath
        { spell = 191034, type = "ability", duration = 8}, -- Starfall
        { spell = 192081, type = "ability", buff = true, talent = 8 }, -- Ironfur
        { spell = 194153, type = "ability", requiresTarget = true, overlayGlow = true}, -- Lunar Strike
        { spell = 194223, type = "ability"}, -- Celestial Alignment
        { spell = 202347, type = "ability", requiresTarget = true, debuff = true}, -- Stellar Flare
        { spell = 202425, type = "ability", buff = true, talent = 2 }, -- Warrior of Elune
        { spell = 202770, type = "ability", buff = true, talent = 20 }, -- Fury of Elune
        { spell = 205636, type = "ability", duration = 10, talent = 3 }, -- Force of Nature
        { spell = 252216, type = "ability", buff = true, talent = 4 }, -- Tiger Dash
        { spell = 274281, type = "ability", requiresTarget = true, charges = true, target = true, talent = 21 }, -- New Moon
      },
      icon = 132134
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 276154, type = "buff", unit = "player"}, --Dawning Sun
        { spell = 279648, type = "buff", unit = "player"}, --Lively Spirit
        { spell = 269380, type = "buff", unit = "player"}, --Long Night
        { spell = 274814, type = "buff", unit = "player"}, --Reawakening
        { spell = 272871, type = "buff", unit = "player"}, --Streaking Stars
        { spell = 287790, type = "buff", unit = "player"}, --Arcanic Pulsar
        { spell = 280165, type = "buff", unit = "player"}, --Ursoc's Endurance
        { spell = 287809, type = "buff", unit = "player"}, --Switch Hitter
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 305497, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Thorns
        { spell = 305497, type="buff", unit = "target", pvptalent = 4, titleSuffix = L["buff"]},-- Thorns
        { spell = 209731, type="buff", unit = "player", pvptalent = 5},-- Protector of the Grove
        { spell = 209749, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Faerie Swarm
        { spell = 209749, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Faerie Swarm
        { spell = 209753, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Cyclone
        { spell = 209753, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Cyclone
        { spell = 234084, type="buff", unit = "player", pvptalent = 14},-- Moon and Stars
        { spell = 209746, type="buff", unit = "player", pvptalent = 15},-- Moonkin Aura
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
        { spell = 106951, type = "buff", unit = "player"}, -- Berserk
        { spell = 61336, type = "buff", unit = "player"}, -- Survival Instincts
        { spell = 22842, type = "buff", unit = "player", talent = 8 }, -- Frenzied Regeneration
        { spell = 5215, type = "buff", unit = "player"}, -- Prowl
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 164547, type = "buff", unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 5487, type = "buff", unit = "player"}, -- Bear Form
        { spell = 8936, type = "buff", unit = "player"}, -- Regrowth
        { spell = 145152, type = "buff", unit = "player", talent = 20 }, -- Bloodtalons
        { spell = 252216, type = "buff", unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 52610, type = "buff", unit = "player", talent = 18 }, -- Savage Roar
        { spell = 48438, type = "buff", unit = "player", talent = 9 }, -- Wild Growth
        { spell = 106898, type = "buff", unit = "player"}, -- Stampeding Roar
        { spell = 5217, type = "buff", unit = "player"}, -- Tiger's Fury
        { spell = 252071, type = "buff", unit = "player", talent = 15 }, -- Jungle Stalker
        { spell = 164545, type = "buff", unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 783, type = "buff", unit = "player"}, -- Travel Form
        { spell = 768, type = "buff", unit = "player"}, -- Cat Form
        { spell = 69369, type = "buff", unit = "player"}, -- Predatory Swiftness
        { spell = 135700, type = "buff", unit = "player"}, -- Clearcasting
        { spell = 102543, type = "buff", unit = "player", talent = 15 }, -- Incarnation: King of the Jungle
        { spell = 192081, type = "buff", unit = "player", talent = 8 }, -- Ironfur
        { spell = 1850, type = "buff", unit = "player"}, -- Dash
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
      },
      icon = 136170
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 164812, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 106830, type = "debuff", unit = "target"}, -- Thrash
        { spell = 339, type = "debuff", unit = "multi"}, -- Entangling Roots
        { spell = 274838, type = "debuff", unit = "target", talent = 21 }, -- Feral Frenzy
        { spell = 58180, type = "debuff", unit = "target"}, -- Infected Wounds
        { spell = 1079, type = "debuff", unit = "target"}, -- Rip
        { spell = 164815, type = "debuff", unit = "target", talent = 7 }, -- Sunfire
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 155625, type = "debuff", unit = "target", talent = 7 }, -- Moonfire
        { spell = 203123, type = "debuff", unit = "target"}, -- Maim
        { spell = 6795, type = "debuff", unit = "target"}, -- Growl
        { spell = 155722, type = "debuff", unit = "target"}, -- Rake
        { spell = 2637, type = "debuff", unit = "multi"}, -- Hibernate
      },
      icon = 132152
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 339, type = "ability", requiresTarget = true, overlayGlow = true}, -- Entangling Roots
        { spell = 768, type = "ability"}, -- Cat Form
        { spell = 783, type = "ability"}, -- Travel Form
        { spell = 2637, type = "ability"}, -- Hibernate
        { spell = 1822, type = "ability", debuff = true, requiresTarget = true}, -- Rake
        { spell = 1850, type = "ability", buff = true}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true}, -- Soothe
        { spell = 5211, type = "ability", requiresTarget = true, talent = 10 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true}, -- Prowl
        { spell = 5217, type = "ability", buff = true}, -- Tiger's Fury
        { spell = 5221, type = "ability", requiresTarget = true, overlayGlow = true}, -- Shred
        { spell = 5487, type = "ability"}, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true}, -- Growl
        { spell = 8921, type = "ability", debuff = true, requiresTarget = true}, -- Moonfire
        { spell = 8936, type = "ability", overlayGlow = true}, -- Regrowth
        { spell = 1079, type = "ability", debuff = true, requiresTarget = true}, -- Rip
        { spell = 16979, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 18562, type = "ability", talent = 9 }, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true}, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, debuff = true}, -- Maim
        { spell = 22842, type = "ability", buff = true, talent = 8 }, -- Frenzied Regeneration
        { spell = 33917, type = "ability", requiresTarget = true}, -- Mangle
        { spell = 48438, type = "ability", talent = 9 }, -- Wild Growth
        { spell = 49376, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 61336, type = "ability", charges = true, buff = true}, -- Survival Instincts
        { spell = 102359, type = "ability", requiresTarget = true, talent = 11 }, -- Mass Entanglement
        { spell = 102401, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102543, type = "ability", buff = true, talent = 15 }, -- Incarnation: King of the Jungle
        { spell = 106830, type = "ability", overlayGlow = true}, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true}, -- Skull Bash
        { spell = 106898, type = "ability", buff = true}, -- Stampeding Roar
        { spell = 106951, type = "ability"}, -- Berserk
        { spell = 108238, type = "ability", talent = 5 }, -- Renewal
        { spell = 132469, type = "ability", talent = 12 }, -- Typhoon
        { spell = 192081, type = "ability", buff = true, talent = 8 }, -- Ironfur
        { spell = 197625, type = "ability", talent = 7 }, -- Moonkin Form
        { spell = 197626, type = "ability", requiresTarget = true, talent = 7 }, -- Starsurge
        { spell = 202028, type = "ability", charges = true, overlayGlow = true, talent = 17 }, -- Brutal Slash
        { spell = 252216, type = "ability", buff = true, talent = 4 }, -- Tiger Dash
        { spell = 274837, type = "ability", requiresTarget = true, talent = 21 }, -- Feral Frenzy
      },
      icon = 236149
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 276026, type = "buff", unit = "player"}, --Iron Jaws
        { spell = 272753, type = "buff", unit = "player"}, --Primordial Rage
        { spell = 274814, type = "buff", unit = "player"}, --Reawakening
        { spell = 274426, type = "buff", unit = "player"}, --Jungle Fury
        { spell = 280165, type = "buff", unit = "player"}, --Ursoc's Endurance
        { spell = 287809, type = "buff", unit = "player"}, --Switch Hitter
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 203059, type="buff", unit = "player", pvptalent = 5},-- King of the Jungle
        { spell = 236021, type="debuff", unit = "target", pvptalent = 6},-- Ferocious Wound
        { spell = 203242, type="ability", pvptalent = 8},-- Rip and Tear
        { spell = 202636, type="buff", unit = "player", pvptalent = 9},-- Leader of the Pack
        { spell = 209731, type="buff", unit = "player", pvptalent = 10},-- Heart of the Wild
        { spell = 33786, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Cyclone
        { spell = 33786, type="debuff", unit = "target", pvptalent = 13, titleSuffix = L["debuff"]},-- Cyclone
        { spell = 305497, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Thorns
        { spell = 305497, type="buff", unit = "group", pvptalent = 14, titleSuffix = L["buff"]},-- Thorns
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
        { spell = 155835, type = "buff", unit = "player", talent = 3 }, -- Bristling Fur
        { spell = 61336, type = "buff", unit = "player"}, -- Survival Instincts
        { spell = 22842, type = "buff", unit = "player"}, -- Frenzied Regeneration
        { spell = 5215, type = "buff", unit = "player"}, -- Prowl
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 203975, type = "buff", unit = "player", talent = 16 }, -- Earthwarden
        { spell = 164547, type = "buff", unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 5487, type = "buff", unit = "player"}, -- Bear Form
        { spell = 8936, type = "buff", unit = "player"}, -- Regrowth
        { spell = 93622, type = "buff", unit = "player"}, -- Gore
        { spell = 158792, type = "buff", unit = "player", talent = 21 }, -- Pulverize
        { spell = 213680, type = "buff", unit = "player", talent = 18 }, -- Guardian of Elune
        { spell = 102558, type = "buff", unit = "player", talent = 15 }, -- Incarnation: Guardian of Ursoc
        { spell = 213708, type = "buff", unit = "player", talent = 14 }, -- Galactic Guardian
        { spell = 48438, type = "buff", unit = "player", talent = 9 }, -- Wild Growth
        { spell = 77764, type = "buff", unit = "player"}, -- Stampeding Roar
        { spell = 783, type = "buff", unit = "player"}, -- Travel Form
        { spell = 192081, type = "buff", unit = "player"}, -- Ironfur
        { spell = 164545, type = "buff", unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 252216, type = "buff", unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 22812, type = "buff", unit = "player"}, -- Barkskin
        { spell = 1850, type = "buff", unit = "player"}, -- Dash
        { spell = 768, type = "buff", unit = "player"}, -- Cat Form
      },
      icon = 1378702
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 164812, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 339, type = "debuff", unit = "multi"}, -- Entangling Roots
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 1079, type = "debuff", unit = "target", talent = 8 }, -- Rip
        { spell = 164815, type = "debuff", unit = "target", talent = 7 }, -- Sunfire
        { spell = 45334, type = "debuff", unit = "target", talent = 6 }, -- Immobilized
        { spell = 155722, type = "debuff", unit = "target", talent = 8 }, -- Rake
        { spell = 99, type = "debuff", unit = "target"}, -- Incapacitating Roar
        { spell = 236748, type = "debuff", unit = "target", talent = 5 }, -- Intimidating Roar
        { spell = 6795, type = "debuff", unit = "target"}, -- Growl
        { spell = 192090, type = "debuff", unit = "target"}, -- Thrash
      },
      icon = 451161
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 99, type = "ability"}, -- Incapacitating Roar
        { spell = 768, type = "ability"}, -- Cat Form
        { spell = 783, type = "ability"}, -- Travel Form
        { spell = 2908, type = "ability", requiresTarget = true}, -- Soothe
        { spell = 1850, type = "ability", buff = true}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 5211, type = "ability", requiresTarget = true, talent = 10 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true}, -- Prowl
        { spell = 5487, type = "ability"}, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true}, -- Growl
        { spell = 6807, type = "ability", requiresTarget = true}, -- Maul
        { spell = 8921, type = "ability", debuff = true, requiresTarget = true, overlayGlow = true}, -- Moonfire
        { spell = 16979, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 18562, type = "ability", talent = 9 }, -- Swiftmend
        { spell = 18576, type = "ability", requiresTarget = true, talent = 11}, -- Mass Entanglement
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22812, type = "ability", buff = true}, -- Barkskin
        { spell = 22842, type = "ability", charges = true, buff = true}, -- Frenzied Regeneration
        { spell = 33917, type = "ability", requiresTarget = true, overlayGlow = true}, -- Mangle
        { spell = 48438, type = "ability", talent = 9 }, -- Wild Growth
        { spell = 49376, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 61336, type = "ability", charges = true, buff = true}, -- Survival Instincts
        { spell = 77758, type = "ability"}, -- Thrash
        { spell = 77761, type = "ability", buff = true}, -- Stampeding Roar
        { spell = 80313, type = "ability", buff = true, requiresTarget = true}, -- Pulverize
        { spell = 102359, type = "ability", requiresTarget = true, talent = 11 }, -- Mass Entanglement
        { spell = 102383, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102401, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102558, type = "ability", buff = true, talent = 15 }, -- Incarnation: Guardian of Ursoc
        { spell = 106839, type = "ability", requiresTarget = true}, -- Skull Bash
        { spell = 106898, type = "ability"}, -- Stampeding Roar
        { spell = 132469, type = "ability", talent = 12 }, -- Typhoon
        { spell = 155835, type = "ability", buff = true, talent = 3 }, -- Bristling Fur
        { spell = 192081, type = "ability", buff = true}, -- Ironfur
        { spell = 197625, type = "ability", talent = 7 }, -- Moonkin Form
        { spell = 197626, type = "ability", requiresTarget = true, talent = 7 }, -- Starsurge
        { spell = 204066, type = "ability", talent = 20 }, -- Lunar Beam
        { spell = 236748, type = "ability", talent = 5 }, -- Intimidating Roar
        { spell = 252216, type = "ability", buff = true, talent = 4 }, -- Tiger Dash
      },
      icon = 236169
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 289315, type = "buff", unit = "player"}, --Burst of Savagery
        { spell = 279793, type = "buff", unit = "player"}, --Grove Tending
        { spell = 279541, type = "buff", unit = "player"}, --Guardian's Wrath
        { spell = 272764, type = "buff", unit = "player"}, --Heartblood
        { spell = 279555, type = "buff", unit = "player"}, --Layered Mane
        { spell = 273349, type = "buff", unit = "player"}, --Masterful Instincts
        { spell = 274814, type = "buff", unit = "player"}, --Reawakening
        { spell = 275909, type = "buff", unit = "player"}, --Twisted Claws
        { spell = 280165, type = "buff", unit = "player"}, --Ursoc's Endurance
        { spell = 287809, type = "buff", unit = "player"}, --Switch Hitter
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 279943, type="buff", unit = "target", pvptalent = 4},-- Sharpened Claws
        { spell = 201664, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Demoralizing Roar
        { spell = 201664, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Demoralizing Roar
        { spell = 236187, type="buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]},-- Master Shapeshifter
        { spell = 236185, type="buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]},-- Master Shapeshifter
        { spell = 207017, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Alpha Challenge
        { spell = 206891, type="debuff", unit = "target", pvptalent = 12, titleSuffix = L["debuff"]},-- Alpha Challenge
        { spell = 202246, type="ability", pvptalent = 16, titleSuffix = L["cooldown"]},-- Overrun
        { spell = 202244, type="debuff", unit = "target", pvptalent = 16, titleSuffix = L["debuff"]},-- Overrun
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
        { spell = 207640, type = "buff", unit = "player", talent = 1 }, -- Abundance
        { spell = 157982, type = "buff", unit = "player"}, -- Tranquility
        { spell = 29166, type = "buff", unit = "player"}, -- Innervate
        { spell = 200389, type = "buff", unit = "player", talent = 14 }, -- Cultivation
        { spell = 5215, type = "buff", unit = "player"}, -- Prowl
        { spell = 774, type = "buff", unit = "target"}, -- Rejuvenation
        { spell = 155777, type = "buff", unit = "target", talent = 20 }, -- Rejuvenation (Germination)
        { spell = 164547, type = "buff", unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 197721, type = "buff", unit = "target", talent = 21 }, -- Flourish
        { spell = 117679, type = "buff", unit = "player", talent = 15 }, -- Incarnation
        { spell = 5487, type = "buff", unit = "player"}, -- Bear Form
        { spell = 8936, type = "buff", unit = "target"}, -- Regrowth
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 207386, type = "buff", unit = "target", talent = 18 }, -- Spring Blossoms
        { spell = 252216, type = "buff", unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 22812, type = "buff", unit = "target"}, -- Barkskin
        { spell = 33763, type = "buff", unit = "target"}, -- Lifebloom
        { spell = 102401, type = "buff", unit = "player", talent = 6 }, -- Wild Charge
        { spell = 192081, type = "buff", unit = "player", talent = 9 }, -- Ironfur
        { spell = 22842, type = "buff", unit = "player", talent = 9 }, -- Frenzied Regeneration
        { spell = 33891, type = "buff", unit = "player", talent = 15 }, -- Incarnation: Tree of Life
        { spell = 164545, type = "buff", unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 783, type = "buff", unit = "player"}, -- Travel Form
        { spell = 16870, type = "buff", unit = "player"}, -- Clearcasting
        { spell = 102351, type = "buff", unit = "player", talent = 3 }, -- Cenarion Ward
        { spell = 102342, type = "buff", unit = "player"}, -- Ironbark
        { spell = 1850, type = "buff", unit = "player"}, -- Dash
        { spell = 114108, type = "buff", unit = "player", talent = 13 }, -- Soul of the Forest
        { spell = 48438, type = "buff", unit = "player"}, -- Wild Growth
        { spell = 768, type = "buff", unit = "player"}, -- Cat Form

      },
      icon = 136081
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 127797, type = "debuff", unit = "target"}, -- Ursol's Vortex
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 339, type = "debuff", unit = "multi"}, -- Entangling Roots
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 1079, type = "debuff", unit = "target", talent = 8 }, -- Rip
        { spell = 164815, type = "debuff", unit = "target"}, -- Sunfire
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 192090, type = "debuff", unit = "target", talent = 9 }, -- Thrash
        { spell = 164812, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 6795, type = "debuff", unit = "target"}, -- Growl
        { spell = 155722, type = "debuff", unit = "target", talent = 8 }, -- Rake
        { spell = 2637, type = "debuff", unit = "multi"}, -- Hibernate
      },
      icon = 236216
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 740, type = "ability"}, -- Tranquility
        { spell = 768, type = "ability"}, -- Cat Form
        { spell = 783, type = "ability"}, -- Travel Form
        { spell = 1850, type = "ability", buff = true}, -- Dash
        { spell = 2637, type = "ability", requiresTarget = true}, -- Hibernate
        { spell = 2908, type = "ability", requiresTarget = true}, -- Soothe
        { spell = 5211, type = "ability", requiresTarget = true, talent = 10 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true}, -- Prowl
        { spell = 5487, type = "ability"}, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true}, -- Growl
        { spell = 18562, type = "ability"}, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22812, type = "ability", buff = true}, -- Barkskin
        { spell = 22842, type = "ability", buff = true, talent = 9 }, -- Frenzied Regeneration
        { spell = 29166, type = "ability", buff = true}, -- Innervate
        { spell = 33891, type = "ability", buff = true, talent = 15 }, -- Incarnation: Tree of Life
        { spell = 33917, type = "ability", requiresTarget = true}, -- Mangle
        { spell = 48438, type = "ability"}, -- Wild Growth
        { spell = 77758, type = "ability", talent = 9 }, -- Thrash
        { spell = 88423, type = "ability"}, -- Nature's Cure
        { spell = 102342, type = "ability"}, -- Ironbark
        { spell = 102351, type = "ability", talent = 3 }, -- Cenarion Ward
        { spell = 102359, type = "ability", requiresTarget = true, talent = 11 }, -- Mass Entanglement
        { spell = 102401, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102793, type = "ability"}, -- Ursol's Vortex
        { spell = 108238, type = "ability", talent = 5 }, -- Renewal
        { spell = 132469, type = "ability", talent = 12 }, -- Typhoon
        { spell = 192081, type = "ability", buff = true, talent = 9 }, -- Ironfur
        { spell = 197625, type = "ability", talent = 7 }, -- Moonkin Form
        { spell = 197626, type = "ability", requiresTarget = true, talent = 7 }, -- Starsurge
        { spell = 197721, type = "ability", talent = 21 }, -- Flourish
        { spell = 252216, type = "ability", buff = true, talent = 4 }, -- Tiger Dash
      },
      icon = 236153
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 279793, type = "buff", unit = "target"}, --Grove Tending
        { spell = 279648, type = "buff", unit = "player"}, --Lively Spirit
        { spell = 274814, type = "buff", unit = "player"}, --Reawakening
        { spell = 269498, type = "buff", unit = "player"}, --Rejuvenating Breath
        { spell = 280165, type = "buff", unit = "player"}, --Ursoc's Endurance
        { spell = 287809, type = "buff", unit = "player"}, --Switch Hitter
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 289022, type="ability", pvptalent = 4},-- Nourish
        { spell = 203407, type="buff", unit = "target", pvptalent = 5},-- Revitalize
        { spell = 247563, type="buff", unit = "group", pvptalent = 6},-- Entangling Bark
        { spell = 305497, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Thorns
        { spell = 305497, type="buff", unit = "group", pvptalent = 7, titleSuffix = L["buff"]},-- Thorns
        { spell = 203554, type="buff", unit = "target", pvptalent = 9},-- Focused Growth
        { spell = 200947, type="debuff", unit = "target", pvptalent = 10},-- Encroaching Vines
        { spell = 203651, type="ability", pvptalent = 11},-- Overgrowth
        { spell = 290213, type="buff", unit = "target", pvptalent = 12},-- Early Spring
        { spell = 33786, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Cyclone
        { spell = 33786, type="debuff", unit = "target", pvptalent = 13, titleSuffix = L["debuff"]},-- Cyclone
        { spell = 236187, type="buff", unit = "player", pvptalent = 14},-- Master Shapeshifter
        { spell = 289318, type="buff", unit = "group", pvptalent = 15},-- Mark of the Wild
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
        { spell = 208628, type = "buff", unit = "player", talent = 20 }, -- Momentum
        { spell = 162264, type = "buff", unit = "player"}, -- Metamorphosis
        { spell = 203650, type = "buff", unit = "player", talent = 20 }, -- Prepared
        { spell = 188499, type = "buff", unit = "player"}, -- Blade Dance
        { spell = 212800, type = "buff", unit = "player"}, -- Blur
        { spell = 196555, type = "buff", unit = "player", talent = 12 }, -- Netherwalk
        { spell = 258920, type = "buff", unit = "player", talent = 6 }, -- Immolation Aura
        { spell = 131347, type = "buff", unit = "player"}, -- Glide
        { spell = 188501, type = "buff", unit = "player"}, -- Spectral Sight
        { spell = 209426, type = "buff", unit = "player"}, -- Darkness
      },
      icon = 1247266
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1490, type = "debuff", unit = "target"}, -- Chaos Brand
        { spell = 258883, type = "debuff", unit = "target", talent = 7}, -- Trail of Ruin
        { spell = 213405, type = "debuff", unit = "target", talent = 17 }, -- Master of the Glaive
        { spell = 179057, type = "debuff", unit = "target"}, -- Chaos Nova
        { spell = 281854, type = "debuff", unit = "target"}, -- Torment
        { spell = 200166, type = "debuff", unit = "target"}, -- Metamorphosis
        { spell = 206491, type = "debuff", unit = "target", talent = 21 }, -- Nemesis
        { spell = 198813, type = "debuff", unit = "target"}, -- Vengeful Retreat
        { spell = 258860, type = "debuff", unit = "target", talent = 15 }, -- Dark Slash
        { spell = 211881, type = "debuff", unit = "target", talent = 18 }, -- Fel Eruption
        { spell = 217832, type = "debuff", unit = "multi" }, -- Imprison
      },
      icon = 1392554
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 131347, type = "ability"}, -- Glide
        { spell = 179057, type = "ability"}, -- Chaos Nova
        { spell = 183752, type = "ability", requiresTarget = true}, -- Disrupt
        { spell = 185123, type = "ability", requiresTarget = true}, -- Throw Glaive
        { spell = 188499, type = "ability"}, -- Blade Dance
        { spell = 188501, type = "ability"}, -- Spectral Sight
        { spell = 191427, type = "ability", buff = true}, -- Metamorphosis
        { spell = 195072, type = "ability", charges = true}, -- Fel Rush
        { spell = 196555, type = "ability", buff = true, talent = 12 }, -- Netherwalk
        { spell = 196718, type = "ability"}, -- Darkness
        { spell = 198013, type = "ability"}, -- Eye Beam
        { spell = 198589, type = "ability", buff = true}, -- Blur
        { spell = 198793, type = "ability"}, -- Vengeful Retreat
        { spell = 206491, type = "ability", buff = true, talent = 21 }, -- Nemesis
        { spell = 210152, type = "ability"}, -- Death Sweep
        { spell = 211881, type = "ability", talent = 18 }, -- Fel Eruption
        { spell = 217832, type = "ability", requiresTarget = true}, -- Imprison
        { spell = 232893, type = "ability", requiresTarget = true, overlayGlow = true, talent = 3 }, -- Felblade
        { spell = 258860, type = "ability", debuff = true, requiresTarget = true, talent = 15 }, -- Dark Slash
        { spell = 258920, type = "ability", buff = true, talent = 6 }, -- Immolation Aura
        { spell = 258925, type = "ability", talent = 9 }, -- Fel Barrage
        { spell = 278326, type = "ability", requiresTarget = true}, -- Consume Magic
        { spell = 281854, type = "ability", debuff = true, requiresTarget = true}, -- Torment
      },
      icon = 1305156
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272794, type = "buff", unit = "player"}, --Devour
        { spell = 273232, type = "buff", unit = "player"}, --Furious Gaze
        { spell = 279584, type = "buff", unit = "player"}, --Revolving Blades
        { spell = 274346, type = "buff", unit = "player"}, --Soulmonger
        { spell = 278736, type = "buff", unit = "player"}, --Thirsting Blades
        { spell = 275936, type = "buff", unit = "player"}, --Seething Power
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 205604, type="ability", pvptalent = 5},-- Reverse Magic
        { spell = 206649, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Eye of Leotheras
        { spell = 206649, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Eye of Leotheras
        { spell = 235903, type="ability", pvptalent = 7},-- Mana Rift
        { spell = 203704, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Mana Break
        { spell = 203704, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Mana Break
        { spell = 211510, type="buff", unit = "target", pvptalent = 13},-- Solitude
        { spell = 206803, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Rain from Above
        { spell = 206803, type="buff", unit = "player", pvptalent = 14, titleSuffix = L["buff"]},-- Rain from Above
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
        { spell = 187827, type = "buff", unit = "player"}, -- Metamorphosis
        { spell = 263648, type = "buff", unit = "player", talent = 21 }, -- Soul Barrier
        { spell = 207693, type = "buff", unit = "player", talent = 4}, -- Feast of Souls
        { spell = 131347, type = "buff", unit = "player"}, -- Glide
        { spell = 203981, type = "buff", unit = "player"}, -- Soul Fragments
        { spell = 188501, type = "buff", unit = "player"}, -- Spectral Sight
        { spell = 203819, type = "buff", unit = "player"}, -- Demon Spikes
        { spell = 178740, type = "buff", unit = "player"}, -- Immolation Aura

      },
      icon = 1247263
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 207744, type = "debuff", unit = "target"}, -- Fiery Brand
        { spell = 1490, type = "debuff", unit = "target"}, -- Chaos Brand
        { spell = 204598, type = "debuff", unit = "target"}, -- Sigil of Flame
        { spell = 268178, type = "debuff", unit = "target", talent = 20 }, -- Void Reaver
        { spell = 204490, type = "debuff", unit = "target"}, -- Sigil of Silence
        { spell = 204843, type = "debuff", unit = "target", talent = 15 }, -- Sigil of Chains
        { spell = 207771, type = "debuff", unit = "target", talent = 6 }, -- Fiery Brand
        { spell = 247456, type = "debuff", unit = "target", talent = 17 }, -- Frailty
        { spell = 210003, type = "debuff", unit = "target", talent = 3 }, -- Razor Spikes
        { spell = 207685, type = "debuff", unit = "target"}, -- Sigil of Misery
        { spell = 185245, type = "debuff", unit = "target"}, -- Torment
        { spell = 217832, type = "debuff", unit = "multi" }, -- Imprison
      },
      icon = 1344647
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 131347, type = "ability"}, -- Glide
        { spell = 178740, type = "ability", buff = true}, -- Immolation Aura
        { spell = 183752, type = "ability", requiresTarget = true}, -- Disrupt
        { spell = 185245, type = "ability", debuff = true, requiresTarget = true}, -- Torment
        { spell = 187827, type = "ability", buff = true}, -- Metamorphosis
        { spell = 188501, type = "ability"}, -- Spectral Sight
        { spell = 189110, type = "ability", charges = true}, -- Infernal Strike
        { spell = 202137, type = "ability"}, -- Sigil of Silence
        { spell = 202138, type = "ability", talent = 15 }, -- Sigil of Chains
        { spell = 202140, type = "ability"}, -- Sigil of Misery
        { spell = 203720, type = "ability", charges = true, buff = true}, -- Demon Spikes
        { spell = 204021, type = "ability", debuff = true, requiresTarget = true}, -- Fiery Brand
        { spell = 204157, type = "ability", requiresTarget = true}, -- Throw Glaive
        { spell = 204513, type = "ability"}, -- Sigil of Flame
        { spell = 212084, type = "ability", talent = 18 }, -- Fel Devastation
        { spell = 217832, type = "ability", requiresTarget = true}, -- Imprison
        { spell = 228477, type = "ability", requiresTarget = true}, -- Soul Cleave
        { spell = 232893, type = "ability", requiresTarget = true, overlayGlow = true, talent = 9 }, -- Felblade
        { spell = 247454, type = "ability", usable = true, talent = 17 }, -- Spirit Bomb
        { spell = 263642, type = "ability", charges = true, talent = 12 }, -- Fracture
        { spell = 263648, type = "ability", buff = true, talent = 21 }, -- Soul Barrier
        { spell = 278326, type = "ability", requiresTarget = true}, -- Consume Magic

      },
      icon = 1344650
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 278769, type = "buff", unit = "player"}, --Cycle of Binding
        { spell = 272794, type = "buff", unit = "player"}, --Devour
        { spell = 288882, type = "buff", unit = "player"}, --Hour of Reaping
        { spell = 273238, type = "buff", unit = "player"}, --Infernal Armor
        { spell = 272987, type = "buff", unit = "player"}, --Revel in Pain
        { spell = 275351, type = "buff", unit = "player"}, --Rigid Carapace
        { spell = 275936, type = "buff", unit = "player"}, --Seething Power
        { spell = 274346, type = "buff", unit = "player"}, --Soulmonger
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 205629, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Demonic Trample
        { spell = 213491, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Demonic Trample
        { spell = 208769, type="buff", unit = "player", pvptalent = 7},-- Everlasting Hunt
        { spell = 207029, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Tormentor
        { spell = 206891, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Tormentor
        { spell = 211510, type="buff", unit = "target", pvptalent = 12},-- Solitude
        { spell = 205630, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Illidan's Grasp
        { spell = 205630, type="debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"]},-- Illidan's Grasp
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
        { spell = 81256, type = "buff", unit = "player"}, -- Dancing Rune Weapon
        { spell = 55233, type = "buff", unit = "player"}, -- Vampiric Blood
        { spell = 3714, type = "buff", unit = "player"}, -- Path of Frost
        { spell = 194679, type = "buff", unit = "player", talent = 12}, -- Rune Tap
        { spell = 48265, type = "buff", unit = "player"}, -- Death's Advance
        { spell = 219809, type = "buff", unit = "player", talent = 9}, -- Tombstone
        { spell = 188290, type = "buff", unit = "player"}, -- Death and Decay
        { spell = 273947, type = "buff", unit = "player", talent = 5}, -- Hemostasis
        { spell = 48707, type = "buff", unit = "player"}, -- Anti-Magic Shell
        { spell = 81141, type = "buff", unit = "player"}, -- Crimson Scourge
        { spell = 195181, type = "buff", unit = "player"}, -- Bone Shield
        { spell = 194844, type = "buff", unit = "player", talent = 21}, -- Bonestorm
        { spell = 274009, type = "buff", unit = "player", talent = 16}, -- Voracious
        { spell = 53365, type = "buff", unit = "player"}, -- Unholy Strength
        { spell = 77535, type = "buff", unit = "player"}, -- Blood Shield
        { spell = 212552, type = "buff", unit = "player", talent = 15}, -- Wraith Walk
        { spell = 48792, type = "buff", unit = "player"}, -- Icebound Fortitude
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 206930, type = "debuff", unit = "target"}, -- Heart Strike
        { spell = 206931, type = "debuff", unit = "target", talent = 2}, -- Blooddrinker
        { spell = 221562, type = "debuff", unit = "target"}, -- Asphyxiate
        { spell = 273977, type = "debuff", unit = "target", talent = 13}, -- Grip of the Dead
        { spell = 55078, type = "debuff", unit = "target"}, -- Blood Plague
        { spell = 56222, type = "debuff", unit = "target"}, -- Dark Command
        { spell = 51399, type = "debuff", unit = "target"}, -- Death Grip
        { spell = 114556, type = "debuff", unit = "player", talent = 19 }, -- Purgatory
      },
      icon = 237514
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 3714, type = "ability", buff = true}, -- Path of Frost
        { spell = 43265, type = "ability", buff = true, buffId = 188290, overlayGlow = true}, -- Death and Decay
        { spell = 47528, type = "ability", requiresTarget = true}, -- Mind Freeze
        { spell = 48265, type = "ability", buff = true}, -- Death's Advance
        { spell = 48707, type = "ability", buff = true}, -- Anti-Magic Shell
        { spell = 48792, type = "ability", buff = true}, -- Icebound Fortitude
        { spell = 49028, type = "ability", buff = true}, -- Dancing Rune Weapon
        { spell = 49576, type = "ability", requiresTarget = true}, -- Death Grip
        { spell = 50842, type = "ability", charges = true}, -- Blood Boil
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 55233, type = "ability", buff = true}, -- Vampiric Blood
        { spell = 56222, type = "ability", requiresTarget = true, debuff = true}, -- Dark Command
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 108199, type = "ability", requiresTarget = true}, -- Gorefiend's Grasp
        { spell = 111673, type = "ability", requiresTarget = true, debuff = true, unit = "pet"}, -- Control Undead
        { spell = 194679, type = "ability", charges = true, buff = true, talent = 12}, -- Rune Tap
        { spell = 194844, type = "ability", buff = true, talent = 21}, -- Bonestorm
        { spell = 195182, type = "ability", buff = true, buffId = 195181, requiresTarget = true}, -- Marrowrend
        { spell = 195292, type = "ability", requiresTarget = true}, -- Death's Caress
        { spell = 206930, type = "ability", requiresTarget = true}, -- Heart Strike
        { spell = 206931, type = "ability", requiresTarget = true, debuff = true, talent = 2}, -- Blooddrinker
        { spell = 206940, type = "ability", requiresTarget = true, debuff = true, talent = 18}, -- Mark of Blood
        { spell = 210764, type = "ability", requiresTarget = true, charges = true, talent = 3}, -- Rune Strike
        { spell = 212552, type = "ability", buff = true, talent = 15}, -- Wraith Walk
        { spell = 219809, type = "ability", usable = true, buff = true, talent = 9}, -- Tombstone
        { spell = 221562, type = "ability", requiresTarget = true}, -- Asphyxiate
        { spell = 274156, type = "ability", talent = 6}, -- Consumption
      },
      icon = 136120
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 289349, type = "buff", unit = "player"}, -- Bloody Runeblade
        { spell = 279503, type = "buff", unit = "player"}, -- Bones of the Damned
        { spell = 278543, type = "buff", unit = "player"}, -- Eternal Rune Weapon
        { spell = 288426, type = "buff", unit = "player"}, -- Cold Hearted
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 203173, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Death Chain
        { spell = 203173, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["buff"]},-- Death Chain
        { spell = 233411, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Blood for Blood
        { spell = 233411, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Blood for Blood
        { spell = 207018, type="ability", pvptalent = 7},-- Murderous Intent
        { spell = 206891, type="debuff", unit = "target", pvptalent = 7},-- Murderous Intent
        { spell = 47476, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Strangulate
        { spell = 47476, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["buff"]},-- Strangulate
        { spell = 212610, type="debuff", unit = "target", pvptalent = 9},-- Walking Dead
        { spell = 214968, type="debuff", unit = "target", pvptalent = 11},-- Necrotic Aura
        { spell = 199721, type="debuff", unit = "target", pvptalent = 12},-- Decomposing Aura
        { spell = 51052, type="ability", pvptalent = 13, titleSuffix = L["Cooldown"]},-- Anti-Magic Zone
        { spell = 145629, type="buff", unit = "player", pvptalent = 13, titleSuffix = L["buff"]},-- Anti-Magic Zone
        { spell = 77606, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Dark Simulacrum
        { spell = 77606, type="debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"]},-- Dark Simulacrum
        { spell = 77616, type="buff", unit = "player", pvptalent = 14, titleSuffix = L["buff"]},-- Dark Simulacrum
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
        { spell = 3714, type = "buff", unit = "player"}, -- Path of Frost
        { spell = 207203, type = "buff", unit = "player"}, -- Frost Shield
        { spell = 152279, type = "buff", unit = "player", talent = 21}, -- Breath of Sindragosa
        { spell = 59052, type = "buff", unit = "player"}, -- Rime
        { spell = 48265, type = "buff", unit = "player"}, -- Death's Advance
        { spell = 281209, type = "buff", unit = "player", talent = 3}, -- Cold Heart
        { spell = 51124, type = "buff", unit = "player"}, -- Killing Machine
        { spell = 48707, type = "buff", unit = "player"}, -- Anti-Magic Shell
        { spell = 211805, type = "buff", unit = "player", talent = 16}, -- Gathering Storm
        { spell = 51271, type = "buff", unit = "player"}, -- Pillar of Frost
        { spell = 212552, type = "buff", unit = "player", talent = 14}, -- Wraith Walk
        { spell = 53365, type = "buff", unit = "player"}, -- Unholy Strength
        { spell = 196770, type = "buff", unit = "player"}, -- Remorseless Winter
        { spell = 47568, type = "buff", unit = "player"}, -- Empower Rune Weapon
        { spell = 194879, type = "buff", unit = "player", talent = 2}, -- Icy Talons
        { spell = 48792, type = "buff", unit = "player"}, -- Icebound Fortitude
        { spell = 253595, type = "buff", unit = "player", talent = 1}, -- Inexorable Assault
        { spell = 178819, type = "buff", unit = "player" }, -- Dark Succor
      },
      icon = 135305
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 207167, type = "debuff", unit = "target", talent = 9}, -- Blinding Sleet
        { spell = 45524, type = "debuff", unit = "target"}, -- Chains of Ice
        { spell = 51714, type = "debuff", unit = "target"}, -- Razorice
        { spell = 56222, type = "debuff", unit = "target"}, -- Dark Command
        { spell = 211793, type = "debuff", unit = "target"}, -- Remorseless Winter
        { spell = 55095, type = "debuff", unit = "target"}, -- Frost Fever
        { spell = 48743, type = "debuff", unit = "player"}, -- Death Pact

      },
      icon = 237522
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 3714, type = "ability", buff = true}, -- Path of Frost
        { spell = 45524, type = "ability", requiresTarget = true, debuff = true}, -- Chains of Ice
        { spell = 47528, type = "ability", requiresTarget = true}, -- Mind Freeze
        { spell = 47568, type = "ability", buff = true}, -- Empower Rune Weapon
        { spell = 48707, type = "ability", buff = true}, -- Anti-Magic Shell
        { spell = 48743, type = "ability", debuff = true, unit = "player", talent = 15}, -- Death Pact
        { spell = 48792, type = "ability", buff = true}, -- Icebound Fortitude
        { spell = 49020, type = "ability", requiresTarget = true, overlayGlow = true}, -- Obliterate
        { spell = 49184, type = "ability", requiresTarget = true, overlayGlow = true}, -- Howling Blast
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 51271, type = "ability", buff = true}, -- Pillar of Frost
        { spell = 56222, type = "ability", requiresTarget = true, debuff = true}, -- Dark Command
        { spell = 57330, type = "ability", talent = 6}, -- Horn of Winter
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 111673, type = "ability", requiresTarget = true, debuff = true, unit = "pet"}, -- Control Undead
        { spell = 152279, type = "ability", buff = true, talent = 21}, -- Breath of Sindragosa
        { spell = 194913, type = "ability"}, -- Glacial Advance
        { spell = 196770, type = "ability", buff = true}, -- Remorseless Winter
        { spell = 207167, type = "ability", talent = 9}, -- Blinding Sleet
        { spell = 207230, type = "ability", talent = 12}, -- Frostscythe
        { spell = 212552, type = "ability", buff = true, talent = 14}, -- Wraith Walk
        { spell = 279302, type = "ability", talent = 18}, -- Frostwyrm's Fury
      },
      icon = 135372
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272723, type = "buff", unit = "player"}, -- Icy Citadel
        { spell = 287338, type = "buff", unit = "player"}, -- Frostwhelp's Indignation
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 213726, type="debuff", unit = "player", pvptalent = 4},-- Cadaverous Pallor
        { spell = 77606, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Dark Simulacrum
        { spell = 77606, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Dark Simulacrum
        { spell = 77616, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Dark Simulacrum
        { spell = 51052, type="ability", pvptalent = 6, titleSuffix = L["Cooldown"]},-- Anti-Magic Zone
        { spell = 145629, type="buff", unit = "target", pvptalent = 6, titleSuffix = L["buff"]},-- Anti-Magic Zone
        { spell = 214968, type="debuff", unit = "target", pvptalent = 7},-- Necrotic Aura
        { spell = 289959, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["slow debuff"]},-- Dead of Winter
        { spell = 287254, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["stun debuff"]},-- Dead of Winter
        { spell = 228579, type="buff", unit = "target", pvptalent = 9},-- Heartstop Aura
        { spell = 287081, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Lichborne
        { spell = 287081, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Lichborne
        { spell = 288977, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Transfusion
        { spell = 288977, type="buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]},-- Transfusion
        { spell = 233395, type="debuff", unit = "target", pvptalent = 12},-- Deathchill
        { spell = 233397, type="debuff", unit = "target", pvptalent = 13},-- Delirium
        { spell = 305392, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Chill Streak
        { spell = 204206, type="debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"]},-- Chill Streak
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
        { spell = 3714, type = "buff", unit = "player"}, -- Path of Frost
        { spell = 212552, type = "buff", unit = "player", talent = 14}, -- Wraith Walk
        { spell = 48707, type = "buff", unit = "player"}, -- Anti-Magic Shell
        { spell = 53365, type = "buff", unit = "player"}, -- Unholy Strength
        { spell = 207289, type = "buff", unit = "player"}, -- Unholy Frenzy
        { spell = 188290, type = "buff", unit = "player"}, -- Death and Decay
        { spell = 115989, type = "buff", unit = "player", talent = 6}, -- Unholy Blight
        { spell = 48792, type = "buff", unit = "player"}, -- Icebound Fortitude
        { spell = 42650, type = "buff", unit = "player"}, -- Army of the Dead
        { spell = 81340, type = "buff", unit = "player"}, -- Sudden Doom
        { spell = 48265, type = "buff", unit = "player"}, -- Death's Advance
        { spell = 51460, type = "buff", unit = "player"}, -- Runic Corruption
        { spell = 63560, type = "buff", unit = "pet"}, -- Dark Transformation
        { spell = 178819, type = "buff", unit = "player" }, -- Dark Succor
      },
      icon = 136181
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target"}, -- Chains of Ice
        { spell = 115994, type = "debuff", unit = "target", talent = 6}, -- Unholy Blight
        { spell = 91800, type = "debuff", unit = "target"}, -- Gnaw
        { spell = 194310, type = "debuff", unit = "target"}, -- Festering Wound
        { spell = 56222, type = "debuff", unit = "target"}, -- Dark Command
        { spell = 196782, type = "debuff", unit = "target"}, -- Outbreak
        { spell = 108194, type = "debuff", unit = "target", talent = 9}, -- Asphyxiate
        { spell = 273977, type = "debuff", unit = "target"}, -- Grip of the Dead
        { spell = 130736, type = "debuff", unit = "target", talent = 12}, -- Soul Reaper
        { spell = 191587, type = "debuff", unit = "target"}, -- Virulent Plague
      },
      icon = 1129420
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 3714, type = "ability", buff = true}, -- Path of Frost
        { spell = 42650, type = "ability", buff = true}, -- Army of the Dead
        { spell = 43265, type = "ability", buff = true, buffId = 188290}, -- Death and Decay
        { spell = 45524, type = "ability", requiresTarget = true, debuff = true}, -- Chains of Ice
        { spell = 46584, type = "ability"}, -- Raise Dead
        { spell = 47468, type = "ability", requiresTarget = true}, -- Claw
        { spell = 47481, type = "ability", requiresTarget = true, debuff = true}, -- Gnaw
        { spell = 47484, type = "ability", requiresTarget = true}, -- Huddle
        { spell = 47528, type = "ability", requiresTarget = true}, -- Mind Freeze
        { spell = 47541, type = "ability", requiresTarget = true, usable = true, overlayGlow = true}, -- Death Coil
        { spell = 48265, type = "ability", buff = true}, -- Death's Advance
        { spell = 48707, type = "ability", buff = true}, -- Anti-Magic Shell
        { spell = 48743, type = "ability", debuff = true, unit = "player", talent = 15}, -- Death Pact
        { spell = 48792, type = "ability", buff = true}, -- Icebound Fortitude
        { spell = 49206, type = "ability", requiresTarget = true, talent = 21}, -- Summon Gargoyle
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 55090, type = "ability", requiresTarget = true, talent = {1, 2}}, -- Scourge Strike
        { spell = 56222, type = "ability", requiresTarget = true, debuff = true}, -- Dark Command
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 63560, type = "ability", buff = true, unit = "pet"}, -- Dark Transformation
        { spell = 77575, type = "ability", requiresTarget = true, debuff = true, buffId = 191587}, -- Outbreak
        { spell = 85948, type = "ability", requiresTarget = true, debuff = true, buffId = 194310}, -- Festering Strike
        { spell = 108194, type = "ability", requiresTarget = true, debuff = true, talent = 9}, -- Asphyxiate
        { spell = 111673, type = "ability", requiresTarget = true, debuff = true, unit = "pet"}, -- Control Undead
        { spell = 115989, type = "ability", buff = true, talent = 6}, -- Unholy Blight
        { spell = 130736, type = "ability", requiresTarget = true, debuff = true, talent = 12}, -- Soul Reaper
        { spell = 152280, type = "ability", buff = true, buffId = 188290, talent = 17}, -- Defile
        { spell = 207289, type = "ability", buff = true, talent = 20}, -- Unholy Frenzy
        { spell = 207311, type = "ability", requiresTarget = true, talent = 3}, -- Clawing Shadows
        { spell = 212552, type = "ability", buff = true, talent = 14}, -- Wraith Walk
        { spell = 275699, type = "ability", usable = true, requiresTarget = true}, -- Apocalypse
      },
      icon = 136144
    },
    [4] = {},
    [5] = {
      title = L["Specific Azerite Traits"],
      args = {
        { spell = 272738, type = "buff", unit = "player"}, -- Festering Doom
        { spell = 274373, type = "buff", unit = "player"}, -- Festermight
        { spell = 275931, type = "debuff", unit = "target"}, -- Harrowing Decay
        { spell = 286979, type = "buff", unit = "player"}, -- Helchains
      },
      icon = 135349
    },
    [6] = {},
    [7] = {
      title = L["PvP Talents"],
      args = {
        { spell = 210128, type="ability", pvptalent = 4},-- Reanimation
        { spell = 288977, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Transfusion
        { spell = 288977, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Transfusion
        { spell = 77606, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Dark Simulacrum
        { spell = 77606, type="debuff", unit = "target", pvptalent = 7, titleSuffix = L["debuff"]},-- Dark Simulacrum
        { spell = 77616, type="buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"]},-- Dark Simulacrum
        { spell = 288849, type="debuff", unit = "target", pvptalent = 8},-- Necromancer's Bargain
        { spell = 214968, type="buff", unit = "target", pvptalent = 9},-- Necrotic Aura
        { spell = 51052, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Anti-Magic Zone
        { spell = 145629, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Anti-Magic Zone
        { spell = 223929, type="debuff", unit = "target", pvptalent = 11},-- Necrotic Strike
        { spell = 213726, type="debuff", unit = "player", pvptalent = 12},-- Cadaverous Pallor
        { spell = 288853, type="ability", pvptalent = 13},-- Raise Abomination
        { spell = 287081, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Lichborne
        { spell = 287081, type="buff", unit = "player", pvptalent = 14, titleSuffix = L["buff"]},-- Lichborne
        { spell = 199721, type="debuff", unit = "target", pvptalent = 15},-- Decomposing Aura
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
  triggers = {[1] = { trigger = { type = "status", event = "Conditions", unevent = "auto", use_alwaystrue = true}}}
});

tinsert(templates.general.args, {
  title = L["Pet alive"],
  icon = "Interface\\Icons\\ability_hunter_pet_raptor",
  triggers = {[1] = { trigger = { type = "status", event = "Conditions", unevent = "auto", use_HasPet = true}}}
});

tinsert(templates.general.args, {
  title = L["Pet Behavior"],
  icon = "Interface\\Icons\\Ability_hunter_pet_assist",
  triggers = {[1] = { trigger = { type = "status", event = "Pet Behavior", unevent = "auto", use_behavior = true, behavior = "assist"}}}
});

tinsert(templates.general.args, {
  spell = 2825, type = "buff", unit = "player",
  forceOwnOnly = true,
  ownOnly = nil,
  overideTitle = L["Bloodlust/Heroism"],
  spellIds = {2825, 32182, 80353, 264667}}
);

-- Items section
if not WeakAuras.IsClassic() then
  templates.items[1] = {
    title = L["Enchants"],
    args = {
      { spell = 268905, type = "buff", unit = "player"}, --Deadly Navigation
      { spell = 267612, type = "buff", unit = "player"}, --Gale-Force Striking
      { spell = 268899, type = "buff", unit = "player"}, --Masterful Navigation
      { spell = 268887, type = "buff", unit = "player"}, --Quick Navigation
      { spell = 268911, type = "buff", unit = "player"}, --Stalwart Navigation
      { spell = 267685, type = "buff", unit = "player"}, --Torrent of Elements
      { spell = 268854, type = "buff", unit = "player"}, --Versatile Navigation
      -- Machinist's Brilliance
      { spell = 300693, type = "buff", unit = "player"}, -- Int
      { spell = 300761, type = "buff", unit = "player"}, -- Haste
      { spell = 300762, type = "buff", unit = "player"}, -- Mastery
      { spell = 298431, type = "buff", unit = "player"}, -- Crit
      -- Force Multiplier
      { spell = 300809, type = "buff", unit = "player"}, -- Mastery
      { spell = 300802, type = "buff", unit = "player"}, -- Haste
      { spell = 300801, type = "buff", unit = "player"}, -- Crit
      { spell = 300691, type = "buff", unit = "player"}, -- Strength
      { spell = 300893, type = "buff", unit = "player"}, -- Agility
      -- Oceanic Restoration
      { spell = 298512, type = "buff", unit = "player"},
      -- Naga Hide
      { spell = 298466, type = "buff", unit = "player"}, -- Agility
      { spell = 298461, type = "buff", unit = "player"}, -- Absorb
      { spell = 300800, type = "buff", unit = "player"}, -- Strength
    }
  }

  templates.items[2] = {
    title = L["On Use Trinkets (Aura)"],
    args = {
      { spell = 278383, type = "buff", unit = "player", titleItemPrefix = 161377},
      { spell = 278385, type = "buff", unit = "player", titleItemPrefix = 161379},
      { spell = 278227, type = "buff", unit = "player", titleItemPrefix = 161411},
      { spell = 278086, type = "buff", unit = "player", titleItemPrefix = 160649}, --heal
      { spell = 278317, type = "buff", unit = "player", titleItemPrefix = 161462},
      { spell = 278364, type = "buff", unit = "player", titleItemPrefix = 161463},
      { spell = 281543, type = "buff", unit = "player", titleItemPrefix = 163936},
      { spell = 265954, type = "buff", unit = "player", titleItemPrefix = 158319},
      { spell = 266018, type = "buff", unit = "target", titleItemPrefix = 158320}, --heal
      { spell = 271054, type = "buff", unit = "player", titleItemPrefix = 158368}, --heal
      { spell = 268311, type = "buff", unit = "player", titleItemPrefix = 159614}, --heal
      { spell = 271115, type = "buff", unit = "player", titleItemPrefix = 159615},
      { spell = 271107, type = "buff", unit = "player", titleItemPrefix = 159617},
      { spell = 265946, type = "buff", unit = "player", titleItemPrefix = 159618}, --tank
      { spell = 271465, type = "debuff", unit = "target", titleItemPrefix = 159624},
      { spell = 268836, type = "buff", unit = "player", titleItemPrefix = 159625},
      { spell = 266047, type = "buff", unit = "player", titleItemPrefix = 159627},
      { spell = 268998, type = "buff", unit = "player", titleItemPrefix = 159630},
      { spell = 273935, type = "buff", unit = "player", titleItemPrefix = 158162},
      { spell = 273955, type = "buff", unit = "player", titleItemPrefix = 158163},
      { spell = 273942, type = "buff", unit = "player", titleItemPrefix = 158164},
      { spell = 268550, type = "buff", unit = "player", titleItemPrefix = 158215},
      { spell = 274472, type = "buff", unit = "player", titleItemPrefix = 161117},
      { spell = 288267, type = "buff", unit = "player", titleItemPrefix = 165574},
      { spell = 291170, type = "debuff", unit = "player", titleItemPrefix = 165578}, --heal
      { spell = 288156, type = "buff", unit = "player", titleItemPrefix = 165580},
      { spell = 287568, type = "buff", unit = "player", titleItemPrefix = 165569}, --tank
    }
  }

  templates.items[3] = {
    title = L["On Use Trinkets (CD)"],
    args = {
      { spell = 161377, type = "item"},
      { spell = 161379, type = "item"},
      { spell = 161411, type = "item"},
      { spell = 160649, type = "item"}, --heal
      { spell = 161462, type = "item"},
      { spell = 161463, type = "item"},
      { spell = 163936, type = "item"},
      { spell = 158319, type = "item"},
      { spell = 158320, type = "item"}, --heal
      { spell = 158368, type = "item"}, --heal
      { spell = 159614, type = "item"}, --heal
      { spell = 159615, type = "item"},
      { spell = 159617, type = "item"},
      { spell = 159618, type = "item"}, --tank
      { spell = 159624, type = "item"},
      { spell = 159625, type = "item"},
      { spell = 159627, type = "item"},
      { spell = 159630, type = "item"},
      { spell = 159611, type = "item"},
      { spell = 158367, type = "item"},
      { spell = 158162, type = "item"},
      { spell = 158163, type = "item"},
      { spell = 158164, type = "item"},
      { spell = 158215, type = "item"},
      { spell = 158216, type = "item"},
      { spell = 158224, type = "item"},
      { spell = 161117, type = "item"},
      { spell = 165574, type = "item"},
      { spell = 165568, type = "item"},
      { spell = 165578, type = "item"}, --heal
      { spell = 165580, type = "item"},
      { spell = 165576, type = "item"},
      { spell = 165572, type = "item"},
      { spell = 165569, type = "item"}, --tank
    }
  }

  templates.items[4] = {
    title = L["On Procc Trinkets (Aura)"],
    args = {
      { spell = 278143, type = "buff", unit = "player", titleItemPrefix = 160648},
      { spell = 278070, type = "buff", unit = "player", titleItemPrefix = 160652},
      { spell = 278110, type = "debuff", unit = "multi", titleItemPrefix = 160655}, --debuff?
      { spell = 278155, type = "buff", unit = "player", titleItemPrefix = 160656},
      { spell = 278379, type = "buff", unit = "player", titleItemPrefix = 161376},
      { spell = 278381, type = "buff", unit = "player", titleItemPrefix = 161378},
      { spell = 278862, type = "buff", unit = "player", titleItemPrefix = 161380},
      { spell = 278388, type = "buff", unit = "player", titleItemPrefix = 161381},
      { spell = 278225, type = "buff", unit = "player", titleItemPrefix = 161412},
      { spell = 278288, type = "buff", unit = "player", titleItemPrefix = 161419},
      { spell = 278359, type = "buff", unit = "player", titleItemPrefix = 161461},
      { spell = 281546, type = "buff", unit = "player", titleItemPrefix = 163935},
      { spell = 276132, type = "debuff", unit = "target", titleItemPrefix = 159126}, --debuff?
      { spell = 267325, type = "buff", unit = "player", titleItemPrefix = 155881},
      { spell = 267327, type = "buff", unit = "player", titleItemPrefix = 155881},
      { spell = 267330, type = "buff", unit = "player", titleItemPrefix = 155881},
      { spell = 267179, type = "buff", unit = "player", titleItemPrefix = 158374},
      { spell = 271103, type = "buff", unit = "player", titleItemPrefix = 158712},
      { spell = 268439, type = "buff", unit = "player", titleItemPrefix = 159612},
      { spell = 271105, type = "buff", unit = "player", titleItemPrefix = 159616},
      { spell = 268194, type = "debuff", unit = "multi", titleItemPrefix = 159619}, --debuff?
      { spell = 271071, type = "buff", unit = "player", titleItemPrefix = 159620},
      { spell = 268756, type = "debuff", unit = "multi", titleItemPrefix = 159623}, --debuff?
      { spell = 268062, type = "buff", unit = "player", titleItemPrefix = 159626},
      { spell = 271194, type = "buff", unit = "player", titleItemPrefix = 159628},
      { spell = 278159, type = "buff", unit = "player", titleItemPrefix = 160653}, --tank
      { spell = 268518, type = "buff", unit = "player", titleItemPrefix = 155568},
      { spell = 273992, type = "buff", unit = "player", titleItemPrefix = 158154},
      { spell = 273988, type = "buff", unit = "player", titleItemPrefix = 158155},
      { spell = 268532, type = "buff", unit = "player", titleItemPrefix = 158218}, --tank
      { spell = 268528, type = "buff", unit = "player", titleItemPrefix = 158556},
      { spell = 273974, type = "buff", unit = "player", titleItemPrefix = 158153},
      { spell = 274430, type = "buff", unit = "player",  spellIds = {274430, 274431}, titleItemPrefix = 161113},
      { spell = 274459, type = "buff", unit = "player", titleItemPrefix = 161115},
      { spell = 288194, type = "debuff", unit = "player", titleItemPrefix = 165577}, --tank
      { spell = 288305, type = "buff", unit = "player", titleItemPrefix = 165581},
      { spell = 288024, type = "buff", unit = "player", titleItemPrefix = 165573}, --tank
      { spell = 289526, type = "debuff", unit = "target", titleItemPrefix = 165570},
      { spell = 289524, type = "buff", unit = "player", titleItemPrefix = 165571},
      { spell = 289523, type = "buff", unit = "player", titleItemPrefix = 165571},
      { spell = 288330, type = "debuff", unit = "target", titleItemPrefix = 165579},
      { spell = 290042, type = "buff", unit = "player", titleItemPrefix = 165572},
    }
  }

  templates.items[5] = {
    title = L["PVP Trinkets (Aura)"],
    args = {
      { spell = 278812, type = "buff", unit = "player", titleItemPrefix = 161472},
      { spell = 278806, type = "buff", unit = "player", titleItemPrefix = 161473},
      { spell = 278819, type = "buff", unit = "player", titleItemPrefix = 161474}, -- on use
      { spell = 277179, type = "buff", unit = "player", titleItemPrefix = 161674}, -- on use
      { spell = 277181, type = "buff", unit = "player", titleItemPrefix = 161676},
      { spell = 277187, type = "buff", unit = "player", titleItemPrefix = 161675},-- on use
    }
  }

  templates.items[6] = {
    title = L["PVP Trinkets (CD)"],
    args = {
      { spell = 161474, type = "item"}, --on use
      { spell = 161674, type = "item"}, --on use
      { spell = 161675, type = "item"}, --on use
    }
  }
end

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

------------------------------
-- PVP Talents
-------------------------------


for _, class in pairs(templates.class) do
  for _, spec in pairs(class) do
    if spec[7] and spec[7].args then
      tinsert(spec[7].args, { spell = 208683, type = "ability", pvptalent = 1}) -- Gladiator's Medallion
    end
  end
end

if not WeakAuras.IsClassic() then
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
end

-------------------------------
-- Hardcoded trigger templates
-------------------------------

-- Warrior
for i = 1, 3 do
  tinsert(templates.class.WARRIOR[i][8].args, createSimplePowerTemplate(1));
end

if WeakAuras.IsClassic() then
  tinsert(templates.class.WARRIOR[1][8].args, {
    title = L["Stance"],
    icon = 132349,
    triggers = {[1] = { trigger = { type = "status", event = "Stance/Form/Aura", unevent = "auto"}}}
  })
  for j, id in ipairs({2457, 71, 2458}) do
    local title, _, icon = GetSpellInfo(id)
    if title then
      tinsert(templates.class.WARRIOR[1][8].args, {
        title = title,
        icon = icon,
        triggers = {
          [1] = {
            trigger = {
              type = "status",
              event = "Stance/Form/Aura",
              unevent = "auto",
              use_form = true,
              form = { single = j }
            }
          }
        }
      });
    end
  end
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
    { spell = 115072, type = "ability", charges = true}, -- Expel Harm
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
    triggers = {[1] = { trigger = { type = "status", event = "Stance/Form/Aura", unevent = "auto"}}}
  });
end
for j, id in ipairs({5487, 768, 783, 114282, 1394966}) do
  local title, _, icon = GetSpellInfo(id)
  if title then
    for i = 1, 4 do
      tinsert(templates.class.DRUID[i][8].args, {
        title = title,
        icon = icon,
        triggers = {
          [1] = {
            trigger = {
              type = "status",
              event = "Stance/Form/Aura",
              unevent = "auto",
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
tinsert(templates.class.DRUID[1][8].args, createSimplePowerTemplate(8));

for i = 1, 4 do
  tinsert(templates.class.DRUID[i][8].args, createSimplePowerTemplate(0)); -- Mana
  tinsert(templates.class.DRUID[i][8].args, createSimplePowerTemplate(1)); -- Rage
  tinsert(templates.class.DRUID[i][8].args, createSimplePowerTemplate(3)); -- Energy
  tinsert(templates.class.DRUID[i][8].args, createSimplePowerTemplate(4)); -- Combo Points
end

-- Efflorescence aka Mushroom
tinsert(templates.class.DRUID[4][3].args,  {spell = 145205, type = "totem"});

-- Demon Hunter
tinsert(templates.class.DEMONHUNTER[1][8].args, createSimplePowerTemplate(17));
tinsert(templates.class.DEMONHUNTER[2][8].args, createSimplePowerTemplate(18));

-- Death Knight
for i = 1, 3 do
  tinsert(templates.class.DEATHKNIGHT[i][8].args, createSimplePowerTemplate(6));

  tinsert(templates.class.DEATHKNIGHT[i][8].args, {
    title = L["Runes"],
    icon = "Interface\\Icons\\spell_deathknight_frozenruneweapon",
    triggers = {[1] = { trigger = { type = "status", event = "Death Knight Rune", unevent = "auto"}}}
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
        if WeakAuras.IsClassic() then
          item.classic = false
        else
          item.classic = true
        end
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
        single = item.talent;
        multi = {};
      };
      item.load.use_talent = true;
    end
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
        if WeakAuras.IsClassic() then
          loadCondition.use_spec = nil
          loadCondition.spec = nil
        end
        for itemIndex, item in pairs(section.args or {}) do
          local handle = handleItem(item)
          if(handle) then
            waitingForItemInfo = true;
          end
          -- item.classic is a tristate property, true = show only on classic, false = show only on retail, nil = show for both
          if (WeakAuras.IsClassic() and item.classic == false)
          or (not WeakAuras.IsClassic() and item.classic)
          then
            section.args[itemIndex] = nil
          else
            addLoadCondition(item, loadCondition);
          end
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

if not WeakAuras.IsClassic() then
  local fixupIconsFrame = CreateFrame("frame");
  fixupIconsFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
  fixupIconsFrame:SetScript("OnEvent", fixupIcons);
end

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

if WeakAuras.IsClassic() then
  -- consolidate talents from all specs in a new dummy "classic" spec, indexed by spell or title for no duplicate
  for _, class in pairs(templates.class) do
    class["classic"] = class["classic"] or {}
    for specIndex, spec in pairs(class) do
      if specIndex ~= "classic" then
        for sectionIndex, section in pairs(spec) do
          if not class["classic"][sectionIndex] then
            class["classic"][sectionIndex] = {
              icon = section.icon,
              title = section.title,
              args = {}
            }
          end
          local args = class["classic"][sectionIndex].args
          for itemIndex, item in pairs(section.args or {}) do
            if item.spell then
              args[item.spell] = item
            else
              args[itemIndex] = item
            end
          end
        end
      end
    end
  end
end

WeakAuras.triggerTemplates = templates;
