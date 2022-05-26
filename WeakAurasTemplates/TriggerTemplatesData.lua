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
templates.class.WARRIOR = {
  [1] = { -- Arms
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 6673, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 7384, type = "buff", unit = "player"}, -- Overpower
        { spell = 18499, type = "buff", unit = "player"}, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player"}, -- Spell Reflection
        { spell = 32216, type = "buff", unit = "player", talent = 5}, -- Victorious
        { spell = 52437, type = "buff", unit = "player", talent = 2}, -- Sudden Death
        { spell = 97463, type = "buff", unit = "player"}, -- Rallying Cry
        { spell = 107574, type = "buff", unit = "player", talent = 17}, -- Avatar
        { spell = 118038, type = "buff", unit = "player"}, -- Die by the Sword
        { spell = 132404, type = "buff", unit = "player"}, -- Shield Block
        { spell = 190456, type = "buff", unit = "player"}, -- Ignore Pain
        { spell = 197690, type = "buff", unit = "player", talent = 12}, -- Defensive Stance
        { spell = 202164, type = "buff", unit = "player", talent = 11}, -- Bounding Stride
        { spell = 227847, type = "buff", unit = "player"}, -- Bladestorm
        { spell = 248622, type = "buff", unit = "player", talent = 16}, -- In For The Kill
        { spell = 260708, type = "buff", unit = "player"}, -- Sweeping Strikes
        { spell = 262228, type = "buff", unit = "player", talent = 18}, -- Deadly Calm
        { spell = 262232, type = "buff", unit = "player", talent = 1}, -- War Machine
        { spell = 334783, type = "buff", unit = "player", talent = 13}, -- Collateral Damage
      },
      icon = 132333
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target"}, -- Taunt
        { spell = 772, type = "debuff", unit = "target", talent = 9}, -- Rend
        { spell = 1715, type = "debuff", unit = "target"}, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target"}, -- Intimidating Shout
        { spell = 12323, type = "debuff", unit = "target"}, -- Piercing Howl
        { spell = 105771, type = "debuff", unit = "target"}, -- Charge
        { spell = 115804, type = "debuff", unit = "target"}, -- Mortal Wounds
        { spell = 132169, type = "debuff", unit = "target", talent = 6}, -- Storm Bolt
        { spell = 208086, type = "debuff", unit = "target"}, -- Colossus Smash
        { spell = 262115, type = "debuff", unit = "target"}, -- Deep Wounds
      },
      icon = 132366
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100, type = "ability", requiresTarget = true, talent = {5,6}, titleSuffix =" (1 Charge)" }, -- Charge
        { spell = 100, type = "ability", requiresTarget = true}, -- Charge
        { spell = 100, type = "ability", charges = true, requiresTarget = true, talent = 4, titleSuffix =" (2 Charges)"}, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true}, -- Taunt
        { spell = 772, type = "ability", debuff = true, requiresTarget = true, talent = 9}, -- Rend
        { spell = 845, type = "ability", talent = 15}, -- Cleave
        { spell = 1161, type = "ability"}, -- Challenging Shout
        { spell = 1464, type = "ability", requiresTarget = true}, -- Slam
        { spell = 1680, type = "ability"}, -- Whirlwind
        { spell = 1715, type = "ability", debuff = true,  requiresTarget = true}, -- Hamstring
        { spell = 2565, type = "ability", buff = true, charges = true}, -- Shield Block
        { spell = 3411, type = "ability"}, -- Intervene
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true}, -- Intimidating Shout
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true}, -- Pummel
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 7384, type = "ability", requiresTarget = true, overlayGlow = true, talent = {19,21}, titleSuffix =" (1 Charge)"}, -- Overpower
        { spell = 7384, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 20, titleSuffix =" (2 Charges)"}, -- Overpower
        { spell = 12294, type = "ability", requiresTarget = true}, -- Mortal Strike
        { spell = 12323, type = "ability", debuff = true}, -- Piercing Howl
        { spell = 18499, type = "ability", buff = true}, -- Berserker Rage
        { spell = 23920, type = "ability", buff = true}, -- Spell Reflection
        { spell = 23922, type = "ability", requiresTarget = true}, -- Shield Slam
        { spell = 34428, type = "ability", usable = true, requiresTarget = true}, -- Victory Rush
        { spell = 57755, type = "ability", requiresTarget = true}, -- Heroic Throw
        { spell = 64382, type = "ability", requiresTarget = true}, -- Shattering Throw
        { spell = 97462, type = "ability", buff = true}, -- Rallying Cry
        { spell = 107570, type = "ability", debuff = true, requiresTarget = true, talent = 6}, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true, talent = 17}, -- Avatar
        { spell = 118038, type = "ability", buff = true}, -- Die by the Sword
        { spell = 152277, type = "a bility", talent = 21}, -- Ravager
        { spell = 163201, type = "ability", requiresTarget = true}, -- Execute
        { spell = 167105, type = "ability", debuff = true, requiresTarget = true}, -- Colossus Smash
        { spell = 190456, type = "ability", buff = true}, -- Ignore Pain
        { spell = 197690, type = "ability", buff = true, talenbt = 12}, -- Defensive Stance
        { spell = 202168, type = "ability", requiresTarget = true, talent = 5}, -- Impending Victory
        { spell = 227847, type = "ability"}, -- Bladestorm
        { spell = 260643, type = "ability", requiresTarget = true, talent = 3}, -- Skullsplitter
        { spell = 260708, type = "ability", buff = true}, -- Sweeping Strikes
        { spell = 262161, type = "ability", debuff = true, requiresTarget = true, talent = 14}, -- Warbreaker
        { spell = 262228, type = "ability", buff = true, talent = 18}, -- Deadly Calm
      },
      icon = 132355
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
        { spell = 198817, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Sharpen Blade
        { spell = 198817, type="buff", unit = "player", pvptalent = 4, titleSuffix = L["buff"]},-- Sharpen Blade
        { spell = 236077, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Disarm
        { spell = 236077, type="debuff", unit = "target", pvptalent = 2, titleSuffix = L["debuff"]},-- Disarm
        { spell = 236273, type="ability", pvptalent = 3, titleSuffix = L["cooldown"]},-- Duel
        { spell = 236273, type="debuff", unit = "target", pvptalent = 3, titleSuffix = L["debuff"]},-- Duel
        { spell = 236320, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- War Banner
        { spell = 236321, type="buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- War Banner
        { spell = 330279, type="buff", unit = "group", pvptalent = 5},-- Overwatch
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = rageIcon,
    },
  },
  [2] = { -- Fury
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 1719, type = "buff", unit = "player"}, -- Recklessness
        { spell = 6673, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 18499, type = "buff", unit = "player"}, -- Berserker Rage
        { spell = 32216, type = "buff", unit = "player", talent = 5}, -- Victorious
        { spell = 46924, type = "buff", unit = "player", talent = 18}, -- Bladestorm
        { spell = 85739, type = "buff", unit = "player"}, -- Whirlwind
        { spell = 97463, type = "buff", unit = "player"}, -- Rallying Cry
        { spell = 132404, type = "buff", unit = "player"}, -- Shield Block
        { spell = 184362, type = "buff", unit = "player"}, -- Enrage
        { spell = 184364, type = "buff", unit = "player"}, -- Enraged Regeneration
        { spell = 190456, type = "buff", unit = "player"}, -- Ignore Pain
        { spell = 202164, type = "buff", unit = "player", talent = 11}, -- Bounding Stride
        { spell = 202225, type = "buff", unit = "player", talent = 10}, -- Furious Charge
        { spell = 262232, type = "buff", unit = "player", talent = 1}, -- War Machine
        { spell = 280776, type = "buff", unit = "player", talent = 2}, -- Sudden Death
        { spell = 335082, type = "buff", unit = "player", talent = 8}, -- Frenzy
      },
      icon = 136224
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target"}, -- Taunt
        { spell = 1715, type = "debuff", unit = "target"}, -- Hamstring
        { spell = 12323, type = "debuff", unit = "target"}, -- Piercing Howl
        { spell = 105771, type = "debuff", unit = "target"}, -- Charge
        { spell = 118000, type = "debuff", unit = "target", talent = 17}, -- Dragon Roar
        { spell = 132169, type = "debuff", unit = "target", talent = 6}, -- Storm Bolt
        { spell = 280773, type = "debuff", unit = "target", talent = 21}, -- Siegebreaker
      },
      icon = 132154
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100, type = "ability", requiresTarget = true, talent = {5,6}, titleSuffix =" (1 Charge)" }, -- Charge
        { spell = 100, type = "ability", requiresTarget = true}, -- Charge
        { spell = 100, type = "ability", charges = true, requiresTarget = true, talent = 4, titleSuffix =" (2 Charges)"}, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true}, -- Taunt
        { spell = 1161, type = "ability"}, -- Challenging Shout
        { spell = 1464, type = "ability", requiresTarget = true}, -- Slam
        { spell = 1680, type = "ability"}, -- Whirlwind
        { spell = 1715, type = "ability", debuff = true,  requiresTarget = true}, -- Hamstring
        { spell = 1719, type = "ability", buff = true}, -- Recklessness
        { spell = 2565, type = "ability", buff = true, charges = true}, -- Shield Block
        { spell = 3411, type = "ability"}, -- Intervene
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true}, -- Intimidating Shout
        { spell = 5308, type = "ability", requiresTarget = true, overlayGlow = true}, -- Execute
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true}, -- Pummel
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 12323, type = "ability", debuff = true}, -- Piercing Howl
        { spell = 18499, type = "ability", buff = true}, -- Berserker Rage
        { spell = 23881, type = "ability", requiresTarget = true}, -- Bloodthirst
        { spell = 23920, type = "ability", buff = true}, -- Spell Reflection
        { spell = 23922, type = "ability", requiresTarget = true}, -- Shield Slam
        { spell = 34428, type = "ability", usable = true, requiresTarget = true}, -- Victory Rush
        { spell = 46924, type = "ability", talent = 18}, -- Bladestorm
        { spell = 57755, type = "ability", requiresTarget = true}, -- Heroic Throw
        { spell = 64382, type = "ability", requiresTarget = true}, -- Shattering Throw
        { spell = 85288, type = "ability", charges = true, requiresTarget = true, overlayGlow = true}, -- Raging Blow
        { spell = 97462, type = "ability", buff = true}, -- Rallying Cry
        { spell = 100130, type = "ability", requiresTarget = true}, -- Furious Slash
        { spell = 107570, type = "ability", debuff = true, requiresTarget = true, talent = 6}, -- Storm Bolt
        { spell = 118000, type = "ability", talent = 17}, -- Dragon Roar
        { spell = 163201, type = "ability", requiresTarget = true}, -- Execute
        { spell = 184364, type = "ability", buff = true}, -- Enraged Regeneration
        { spell = 184367, type = "ability", requiresTarget = true, overlayGlow = true}, -- Rampage
        { spell = 190411, type = "ability"}, -- Whirlwind
        { spell = 190456, type = "ability", buff = true}, -- Ignore Pain
        { spell = 202168, type = "ability", requiresTarget = true, talent = 5}, -- Impending Victory
        { spell = 280772, type = "ability", debuff = true, requiresTarget = true, talent = 21}, -- Siegebreaker
        { spell = 315720, type = "ability", requiresTarget = true, talent = 9}, -- Onslaught
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
        { spell = 199261, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Death Wish
        { spell = 199261, type="buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]},-- Death Wish
        { spell = 213858, type="buff", unit = "player", pvptalent = 4},-- Battle Trance
        { spell = 236077, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Disarm
        { spell = 236077, type="debuff", unit = "target", pvptalent = 7, titleSuffix = L["debuff"]},-- Disarm
        { spell = 280746, type="buff", unit = "player", pvptalent = 1},-- Barbarian
        { spell = 329038, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Death Wish
        { spell = 329038, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Death Wish
        { spell = 330279, type="buff", unit = "group", pvptalent = 10},-- Overwatch
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = rageIcon,
    },
  },
  [3] = { -- Protection
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 871, type = "buff", unit = "player"}, -- Shield Wall
        { spell = 6673, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Battle Shout
        { spell = 12975, type = "buff", unit = "player"}, -- Last Stand
        { spell = 18499, type = "buff", unit = "player"}, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player"}, -- Spell Reflection
        { spell = 97463, type = "buff", unit = "player"}, -- Rallying Cry
        { spell = 107574, type = "buff", unit = "player"}, -- Avatar
        { spell = 132404, type = "buff", unit = "player"}, -- Shield Block
        { spell = 147833, type = "buff", unit = "target"}, -- Intervene
        { spell = 190456, type = "buff", unit = "player"}, -- Ignore Pain
        { spell = 202164, type = "buff", unit = "player", talent = 11}, -- Bounding Stride
        { spell = 202602, type = "buff", unit = "player", talent = 16}, -- Into the Fray
        { spell = 262232, type = "buff", unit = "player", talent = 1}, -- War Machine
        { spell = 288653, type = "debuff", unit = "target"}, --Intimidating Presence
      },
      icon = 1377132
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target"}, -- Taunt
        { spell = 1160, type = "debuff", unit = "target"}, -- Demoralizing Shout
        { spell = 1715, type = "debuff", unit = "target"}, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target"}, -- Intimidating Shout
        { spell = 6343, type = "debuff", unit = "target"}, -- Thunder Clap
        { spell = 105771, type = "debuff", unit = "target"}, -- Charge
        { spell = 115767, type = "debuff", unit = "target"}, -- Deep Wounds
        { spell = 132168, type = "debuff", unit = "target"}, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 6}, -- Storm Bolt
        { spell = 275335, type = "debuff", unit = "target", talent = 2}, -- Punish
      },
      icon = 132090
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100, type = "ability", requiresTarget = true, talent = {5,6}, titleSuffix =" (1 Charge)" }, -- Charge
        { spell = 100, type = "ability", requiresTarget = true}, -- Charge
        { spell = 100, type = "ability", charges = true, requiresTarget = true, talent = 4, titleSuffix =" (2 Charges)"}, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true}, -- Taunt
        { spell = 871, type = "ability", buff = true}, -- Shield Wall
        { spell = 1160, type = "ability", debuff = true}, -- Demoralizing Shout
        { spell = 1161, type = "ability"}, -- Challenging Shout
        { spell = 1464, type = "ability", overlayGlow = true,  requiresTarget = true}, -- Revenge
        { spell = 1715, type = "ability", debuff = true,  requiresTarget = true}, -- Hamstring
        { spell = 1680, type = "ability"}, -- Whirlwind
        { spell = 2565, type = "ability", charges = true, buff = true}, -- Shield Block
        { spell = 3411, type = "ability"}, -- Intervene
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true}, -- Intimidating Shout
        { spell = 6343, type = "ability"}, -- Thunder Clap
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true}, -- Pummel
        { spell = 6572, type = "ability", overlayGlow = true}, -- Revenge
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 12975, type = "ability", buff = true}, -- Last Stand
        { spell = 18499, type = "ability", buff = true}, -- Berserker Rage
        { spell = 20243, type = "ability", requiresTarget = true, talent = {1, 2}}, -- Devastate
        { spell = 23920, type = "ability", buff = true}, -- Spell Reflection
        { spell = 23922, type = "ability", requiresTarget = true, overlayGlow = true}, -- Shield Slam
        { spell = 23922, type = "ability", requiresTarget = true}, -- Shield Slam
        { spell = 34428, type = "ability", usable = true, requiresTarget = true}, -- Victory Rush
        { spell = 46968, type = "ability"}, -- Shockwave
        { spell = 57755, type = "ability", requiresTarget = true}, -- Heroic Throw
        { spell = 64382, type = "ability", requiresTarget = true}, -- Shattering Throw
        { spell = 97462, type = "ability"}, -- Rallying Cry
        { spell = 107570, type = "ability", debuff = true, requiresTarget = true, talent = 6}, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true}, -- Avatar
        { spell = 118000, type = "ability", talent = 9}, -- Dragon Roar
        { spell = 163201, type = "ability", requiresTarget = true}, -- Execute
        { spell = 198304, type = "ability", charges = true, requiresTarget = true}, -- Intercept
        { spell = 202168, type = "ability", requiresTarget = true, talent = 15}, -- Impending Victory
        { spell = 228920, type = "ability", talent = 18}, -- Ravager
      },
      icon = 134951
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
        { spell = 198912, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Shield Bash
        { spell = 198912, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Shield Bash
        { spell = 199085, type="debuff", unit = "target", pvptalent = 6},-- Warpath
        { spell = 205800, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Oppressor
        { spell = 206572, type="ability", pvptalent = 8},-- Dragon Charge
        { spell = 206891, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Oppressor
        { spell = 213871, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Bodyguard
        { spell = 213871, type="buff", unit = "group", pvptalent = 2, titleSuffix = L["buff"]},-- Bodyguard
        { spell = 236077, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Disarm
        { spell = 236077, type="debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]},-- Disarm
        { spell = 330279, type="buff", unit = "group", pvptalent = 12},-- Overwatch
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = rageIcon,
    }
  }
}

templates.class.PALADIN = {
  [1] = { -- Holy
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 465, type = "buff", unit = "player"}, -- Devotion Aura
        { spell = 498, type = "buff", unit = "player"}, -- Divine Protection
        { spell = 642, type = "buff", unit = "player"}, -- Divine Shield
        { spell = 1022, type = "buff", unit = "group"}, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "group"}, -- Blessing of Freedom
        { spell = 6940, type = "buff", unit = "group"}, -- Blessing of Sacrifice
        { spell = 31821, type = "buff", unit = "player"}, -- Aura Mastery
        { spell = 31884, type = "buff", unit = "player"}, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player"}, -- Crusader Aura
        { spell = 53563, type = "buff", unit = "group"}, -- Beacon of Light
        { spell = 54149, type = "buff", unit = "player"}, -- Infusion of Light
        { spell = 105809, type = "buff", unit = "player"}, -- Holy Avenger
        { spell = 156910, type = "buff", unit = "group", talent = 20}, -- Beacon of Faith
        { spell = 183435, type = "buff", unit = "player"}, -- Retribution Aura
        { spell = 200025, type = "buff", unit = "group", talent = 21}, -- Beacon of Virtue
        { spell = 214202, type = "buff", unit = "player"}, -- Rule of Law
        { spell = 216331, type = "buff", unit = "player", talent = 17}, -- Avenging Crusader
        { spell = 221885, type = "buff", unit = "player"}, -- Divine Steed
        { spell = 223306, type = "buff", unit = "target", talent = 2}, -- Bestow Faith
        { spell = 287280, type = "buff", unit = "group", talent = 19}, -- Glimmer of Light
        { spell = 317920, type = "buff", unit = "player"}, -- Concentration Aura
      },
      icon = 135964
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target"}, -- Hammer of Justice
        { spell = 10326, type = "debuff", unit = "target"}, -- Turn Evil
        { spell = 62124, type = "debuff", unit = "target"}, -- Hammer of Justice
        { spell = 20066, type = "debuff", unit = "multi", talent = 8}, -- Repentance
        { spell = 105421, type = "debuff", unit = "target", talent = 9}, -- Blinding Light
        { spell = 196941, type = "debuff", unit = "target", talent = 5}, -- Judgment of Light
        { spell = 204242, type = "debuff", unit = "target"}, -- Consecration
        { spell = 214222, type = "debuff", unit = "target"}, -- Judgment
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
        { spell = 10326, type = "ability"}, -- Turn Evil
        { spell = 20066, type = "ability", requiresTarget = true, talent = 8}, -- Repentance
        { spell = 20271, type = "ability", requiresTarget = true}, -- Hammer of Wrath
        { spell = 20473, type = "ability", overlayGlow = true}, -- Holy Shock
        { spell = 24275, type = "ability"}, -- Hammer of Wrath
        { spell = 26573, type = "ability", totem = true}, -- Consecration
        { spell = 31821, type = "ability", buff = true}, -- Aura Mastery
        { spell = 31821, type = "ability"}, -- Aura Mastery
        { spell = 31884, type = "ability", buff = true, talent = {16, 18}}, -- Avenging Wrath
        { spell = 35395, type = "ability", charges = true, requiresTarget = true}, -- Crusader Strike
        { spell = 53600, type = "ability"}, -- Shield of the Righteous
        { spell = 62124, type = "ability"}, -- Hand of Reckoning
        { spell = 85222, type = "ability", overlayGlow = true}, -- Light of Dawn
        { spell = 85673, type = "ability"}, -- Word of Glory
        { spell = 105809, type = "ability", buff = true, talent = 14}, -- Holy Avenger
        { spell = 114158, type = "ability", talent = 3}, -- Light's Hammer
        { spell = 114165, type = "ability", talent = 6}, -- Holy Prism
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 152262, type = "ability", buff = true, talent = 15}, -- Seraphim
        { spell = 183998, type = "ability"}, -- Light of the Martyr
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 200025, type = "ability", talent = 21}, -- Beacon of Virtue
        { spell = 214202, type = "ability", charges = true, buff = true, talent = 12}, -- Rule of Law
        { spell = 216331, type = "ability", buff = true, talent = 17}, -- Avenging Crusader
        { spell = 223306, type = "ability", talent = 2}, -- Bestow Faith
        { spell = 275773, type = "ability", debuff = true, requiresTarget = true}, -- Judgment
      },
      icon = 135972
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
        { spell = 199507, type="buff", unit = "group", pvptalent = 9},-- Spreading the Word
        { spell = 210294, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Divine Favor
        { spell = 210294, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Divine Favor
        { spell = 210391, type="buff", unit = "player", pvptalent = 5},-- Darkest before the Dawn
        { spell = 216328, type="buff", unit = "target", pvptalent = 10},-- Light's Grace
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
  [2] = { -- Protection
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 465, type = "buff", unit = "player"}, -- Devotion Aura
        { spell = 642, type = "buff", unit = "player"}, -- Divine Shield
        { spell = 1022, type = "buff", unit = "group"}, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "group"}, -- Blessing of Freedom
        { spell = 6940, type = "buff", unit = "group"}, -- Blessing of Sacrifice
        { spell = 31850, type = "buff", unit = "player"}, -- Ardent Defender
        { spell = 31884, type = "buff", unit = "player"}, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player"}, -- Crusader Aura
        { spell = 86659, type = "buff", unit = "player"}, -- Guardian of Ancient Kings
        { spell = 132403, type = "buff", unit = "player"}, -- Shield of the Righteous
        { spell = 152262, type = "buff", unit = "player", talent = 15}, -- Seraphim
        { spell = 182104, type = "buff", unit = "player"}, -- Shining Light
        { spell = 188370, type = "buff", unit = "player"}, -- Consecration
        { spell = 183435, type = "buff", unit = "player"}, -- Retribution Aura
        { spell = 197561, type = "buff", unit = "player"}, -- Avenger's Valor
        { spell = 204018, type = "buff", unit = "player", talent = 12}, -- Blessing of Spellwarding
        { spell = 221883, type = "buff", unit = "player"}, -- Divine Steed
        { spell = 280375, type = "buff", unit = "player", talent = 2}, -- Redoubt
        { spell = 317920, type = "buff", unit = "player"}, -- Concentration Aura
        { spell = 327225, type = "buff", unit = "player", talent = 4}, -- First Avenger
      },
      icon = 236265
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target"}, -- Hammer of Justice
        { spell = 20066, type = "debuff", unit = "multi", talent = 8}, -- Repentance
        { spell = 31935, type = "debuff", unit = "target"}, -- Avenger's Shield
        { spell = 62124, type = "debuff", unit = "target"}, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 9}, -- Blinding Light
        { spell = 196941, type = "debuff", unit = "target", talent = 18}, -- Judgment of Light
        { spell = 204079, type = "debuff", unit = "target", talent = 21}, -- Final Stand
        { spell = 204242, type = "debuff", unit = "target"}, -- Consecration
        { spell = 204301, type = "debuff", unit = "target", talent = 3}, -- Blessed Hammer
      },
      icon = 135952
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 498, type = "ability"}, -- Ardent Defender
        { spell = 633, type = "ability"}, -- Lay on Hands
        { spell = 642, type = "ability", buff = true}, -- Divine Shield
        { spell = 853, type = "ability", requiresTarget = true}, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true}, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true}, -- Blessing of Freedom
        { spell = 6940, type = "ability", debuff = true, requiresTarget = true, unit="player"}, -- Blessing of Sacrifice
        { spell = 10326, type = "ability"}, -- Turn Evil
        { spell = 20066, type = "ability", requiresTarget = true, talent = 8}, -- Repentance
        { spell = 20271, type = "ability"}, -- Judgment
        { spell = 24275, type = "ability"}, -- Hammer of Wrath
        { spell = 26573, type = "ability", buff = true}, -- Consecration
        { spell = 31850, type = "ability", buff = true}, -- Ardent Defender
        { spell = 31884, type = "ability", buff = true}, -- Avenging Wrath
        { spell = 31935, type = "ability", requiresTarget = true, overlayGlow = true}, -- Avenger's Shield
        { spell = 35395, type = "ability"}, -- Hammer of the Righteous
        { spell = 53600, type = "ability", charges = true, buff = true}, -- Shield of the Righteous
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true}, -- Hand of Reckoning
        { spell = 85673, type = "ability"}, -- Word of Glory
        { spell = 86659, type = "ability", buff = true}, -- Guardian of Ancient Kings
        { spell = 96231, type = "ability", requiresTarget = true}, -- Rebuke
        { spell = 105809, type = "ability", talent = 14}, -- Holy Avenger
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 152262, type = "ability", buff = true, talent = 15}, -- Seraphim
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 204018, type = "ability", talent = 12}, -- Blessing of Spellwarding
        { spell = 204019, type = "ability", charges = true, debuff = true, talent = 3}, -- Blessed Hammer
        { spell = 213644, type = "ability"}, -- Cleanse Toxins
        { spell = 275779, type = "ability", debuff = true, requiresTarget = true}, -- Judgment
        { spell = 327193, type = "ability", buff = true, talent = 6}, -- Moment of Glory
      },
      icon = 135874
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
        { spell = 206891, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["buff"]},-- Inquisition
        { spell = 207028, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Inquisition
        { spell = 215652, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Shield of Virtue
        { spell = 216857, type="buff", unit = "target", pvptalent = 1},-- Guarded by the Light
        { spell = 217824, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Shield of Virtue
        { spell = 228049, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Guardian of the Forgotten Queen
        { spell = 228050, type="buff", unit = "group", pvptalent = 12, titleSuffix = L["buff"]},-- Guardian of the Forgotten Queen
        { spell = 236186, type="ability", pvptalent = 7},-- Cleansing Light
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
  [3] = { -- Retribution
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 465, type = "buff", unit = "player"}, -- Devotion Aura
        { spell = 642, type = "buff", unit = "player"}, -- Divine Shield
        { spell = 1022, type = "buff", unit = "group"}, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "group"}, -- Blessing of Freedom
        { spell = 31884, type = "buff", unit = "player"}, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player"}, -- Crusader Aura
        { spell = 114250, type = "buff", unit = "player", talent = 16}, -- Selfless Healer
        { spell = 183435, type = "buff", unit = "player"}, -- Retribution Aura
        { spell = 184662, type = "buff", unit = "player"}, -- Shield of Vengeance
        { spell = 205191, type = "buff", unit = "player", talent = 12}, -- Eye for an Eye
        { spell = 209785, type = "buff", unit = "player", talent = 4}, -- Fires of Justice
        { spell = 221883, type = "buff", unit = "player"}, -- Divine Steed
        { spell = 223819, type = "buff", unit = "player", talent = 13}, -- Divine Purpose
        { spell = 267611, type = "buff", unit = "player", talent = 2}, -- Righteous Verdict
        { spell = 269571, type = "buff", unit = "player", talent = 1}, -- Zeal
        { spell = 281178, type = "buff", unit = "player", talent = 5}, -- Blade of Wrath
        { spell = 317920, type = "buff", unit = "player"}, -- Concentration Aura
        { spell = 326733, type = "buff", unit = "player", talent = 6}, -- Empyrean Power
      },
      icon = 135993
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target"}, -- Hammer of Justice
        { spell = 20066, type = "debuff", unit = "multi", talent = 8}, -- Repentance
        { spell = 62124, type = "debuff", unit = "target"}, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target"}, -- Blinding Light
        { spell = 183218, type = "debuff", unit = "target"}, -- Hand of Hindrance
        { spell = 197277, type = "debuff", unit = "target"}, -- Judgment
        { spell = 255937, type = "debuff", unit = "target"}, -- Wake of Ashes
        { spell = 343527, type = "debuff", unit = "target", talent = 3}, -- Execution Sentence
        { spell = 343724, type = "debuff", unit = "target", talent = 21}, -- Reckoning
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
        { spell = 6940, type = "ability", buff = true}, -- Blessing of Sacrifice
        { spell = 10326, type = "ability"}, -- Turn Evil
        { spell = 20066, type = "ability", requiresTarget = true, talent = 8}, -- Repentance
        { spell = 20271, type = "ability", debuff = true, requiresTarget = true}, -- Judgment
        { spell = 24275, type = "ability"}, -- Hammer of Wrath
        { spell = 26573, type = "ability"}, -- Consecration
        { spell = 31884, type = "ability", buff = true}, -- Avenging Wrath
        { spell = 35395, type = "ability", charges = true, requiresTarget = true}, -- Crusader Strike
        { spell = 53600, type = "ability", buff = true, requiresTarget = true}, -- Shield of the Righteous
        { spell = 53385, type = "ability"}, -- Divine Storm
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true}, -- Hand of Reckoning
        { spell = 85256, type = "ability"}, -- Templar's Verdict
        { spell = 85673, type = "ability"}, -- Word of Glory
        { spell = 96231, type = "ability", requiresTarget = true}, -- Rebuke
        { spell = 105809, type = "ability", talent = 14}, -- Holy Avenger
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 152262, type = "ability", talent = 15, buff = true}, -- Seraphim
        { spell = 183218, type = "ability", debuff = true, requiresTarget = true}, -- Hand of Hindrance
        { spell = 184575, type = "ability", requiresTarget = true, overlayGlow = true}, -- Blade of Justice
        { spell = 184662, type = "ability", buff = true}, -- Shield of Vengeance
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 205191, type = "ability", buff = true, talent = 12}, -- Eye for an Eye
        { spell = 205228, type = "ability", totem = true}, -- Consecration
        { spell = 213644, type = "ability"}, -- Cleanse Toxins
        { spell = 215661, type = "ability", requiresTarget = true, talent = 17}, -- Justiciar's Vengeance
        { spell = 231895, type = "ability", buff = true, talent = 20}, -- Crusade
        { spell = 255937, type = "ability", debuff = true, requiresTarget = true}, -- Wake of Ashes
        { spell = 343527, type = "ability", debuff = true, requiresTarget = true, talent = 3}, -- Execution Sentence
      },
      icon = 135891
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
        { spell = 210256, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Blessing of Sanctuary
        { spell = 210256, type="buff", unit = "target", pvptalent = 5, titleSuffix = L["buff"]},-- Blessing of Sanctuary
        { spell = 210323, type="buff", unit = "target", pvptalent = 4},-- Vengeance Aura
        { spell = 236186, type="ability", pvptalent = 2},-- Cleansing Light
        { spell = 246807, type="buff", unit = "target", pvptalent = 10},-- Lawbringer
        { spell = 287947, type="buff", unit = "player", pvptalent = 11},-- Ultimate Retribution
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 136, type = "buff", unit = "pet"}, -- Mend Pet
        { spell = 5384, type = "buff", unit = "player"}, -- Feign Death
        { spell = 6197, type = "buff", unit = "player"}, -- Eagle Eye
        { spell = 19574, type = "buff", unit = "player"}, -- Bestial Wrath
        { spell = 24450, type = "buff", unit = "pet"}, -- Prowl
        { spell = 35079, type = "buff", unit = "player"}, -- Misdirection
        { spell = 118922, type = "buff", unit = "player", talent = 14}, -- Posthaste
        { spell = 186258, type = "buff", unit = "player"}, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player"}, -- Aspect of the Turtle
        { spell = 193530, type = "buff", unit = "player"}, -- Aspect of the Wild
        { spell = 199483, type = "buff", unit = "player"}, -- Camouflage
        { spell = 231390, type = "buff", unit = "player", talent = 7}, -- Trailblazer
        { spell = 217200, type = "buff", unit = "player"}, -- Barbed Shot
        { spell = 257946, type = "buff", unit = "player", talent = 11}, -- Thrill of the Hunt
        { spell = 264663, type = "buff", unit = "player"}, -- Predator's Thirst
        { spell = 264667, type = "buff", unit = "player"}, -- Primal Rage
        { spell = 268877, type = "buff", unit = "player"}, -- Beast Cleave
        { spell = 272790, type = "buff", unit = "pet"}, -- Frenzy
        { spell = 281036, type = "buff", unit = "player", talent = 3}, -- Dire Beast
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target"}, -- Growl
        { spell = 3355, type = "debuff", unit = "multi"}, -- Freezing Trap
        { spell = 5116, type = "debuff", unit = "target"}, -- Concussive Shot
        { spell = 24394, type = "debuff", unit = "target"}, -- Intimidation
        { spell = 117405, type = "debuff", unit = "target", talent = 15}, -- Binding Shot
        { spell = 131894, type = "debuff", unit = "target"}, -- A Murder of Crows
        { spell = 135299, type = "debuff", unit = "target"}, -- Tar Trap
        { spell = 217200, type = "debuff", unit = "target"}, -- Barbed Shot
        { spell = 257284, type = "debuff", unit = "target"}, -- Hunter's Mark
      },
      icon = 135860
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 781, type = "ability"}, -- Disengage
        { spell = 1513, type = "ability"}, -- Scare Beast
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 2643, type = "ability", requiresTarget = true}, -- Multi-Shot
        { spell = 2649, type = "ability", requiresTarget = true, debuff = true}, -- Growl
        { spell = 5116, type = "ability", requiresTarget = true}, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true}, -- Feign Death
        { spell = 6197, type = "ability", buff = true}, -- Eagle Eye
        { spell = 16827, type = "ability", requiresTarget = true}, -- Claw
        { spell = 19574, type = "ability", buff = true}, -- Bestial Wrath
        { spell = 19577, type = "ability", requiresTarget = true, debuff = true}, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true}, -- Tranquilizing Shot
        { spell = 24450, type = "ability"}, -- Prowl
        { spell = 34026, type = "ability", requiresTarget = true}, -- Kill Command
        { spell = 34477, type = "ability", requiresTarget = true}, -- Misdirection
        { spell = 53209, type = "ability", requiresTarget = true, talent = 6}, -- Chimaera Shot
        { spell = 53351, type = "ability", requiresTarget = true}, -- Kill Shot
        { spell = 56641, type = "ability", requiresTarget = true}, -- Cobra Shot
        { spell = 58875, type = "ability",  unit = "pet", buff = true}, -- Spirit Walk
        { spell = 90361, type = "ability",  unit = "pet", buff = true}, -- Spirit Mend
        { spell = 109248, type = "ability", requiresTarget = true, talent = 15}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 120360, type = "ability", talent = 17}, -- Barrage
        { spell = 120679, type = "ability", requiresTarget = true, buff = true, talent = 3}, -- Dire Beast
        { spell = 131894, type = "ability", requiresTarget = true, talent = 12}, -- A Murder of Crows
        { spell = 147362, type = "ability", requiresTarget = true}, -- Counter Shot
        { spell = 185358, type = "ability"}, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true}, -- Aspect of the Turtle
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 193530, type = "ability", buff = true}, -- Aspect of the Wild
        { spell = 195645, type = "ability", debuff = true}, -- Concussive Shot
        { spell = 199483, type = "ability", talent = 9}, -- Camouflage
        { spell = 201430, type = "ability", talent = 18}, -- Stampede
        { spell = 217200, type = "ability", charges = true, requiresTarget = true, overlayGlow = true}, -- Barbed Shot
        { spell = 272651, type = "ability"}, -- Command Pet Ability
        { spell = 257284, type = "ability", debuff = true, requiresTarget = true}, -- Hunter's Mark
        { spell = 264667, type = "ability", buff = true}, -- Primal Rage
        { spell = 264735, type = "ability", unit = "pet", buff = true}, -- Survival of the Fittest
        { spell = 321297, type = "ability", buff = true}, -- Eyes of the Beast
        { spell = 321530, type = "ability", debuff = true}, -- Bloodshedew
      },
      icon = 135130
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
        { spell = 53480, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Roar of Sacrifice
        { spell = 53480, type="buff", unit = "group", pvptalent = 7, titleSuffix = L["buff"]},-- Roar of Sacrifice
        { spell = 202797, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Viper Sting
        { spell = 202797, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Viper Sting
        { spell = 202900, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Scorpid Sting
        { spell = 202900, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Scorpid Sting
        { spell = 202914, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Spider Sting
        { spell = 202914, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Spider Sting
        { spell = 204205, type="buff", unit = "player", pvptalent = 10},-- Wild Protector
        { spell = 205691, type="ability", pvptalent = 8},-- Dire Beast: Basilisk
        { spell = 208652, type="ability", pvptalent = 1},-- Dire Beast: Hawk
        { spell = 236776, type="ability", pvptalent = 11},-- Hi-Explosive Trap
        { spell = 248518, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Interlope
        { spell = 248519, type="buff", unit = "group", pvptalent = 13, titleSuffix = L["buff"]},-- Interlope
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 136, type = "buff", unit = "pet"}, -- Mend Pet
        { spell = 5384, type = "buff", unit = "player"}, -- Feign Death
        { spell = 6197, type = "buff", unit = "player"}, -- Eagle Eye
        { spell = 24450, type = "buff", unit = "pet"}, -- Prowl
        { spell = 35079, type = "buff", unit = "player"}, -- Misdirection
        { spell = 118922, type = "buff", unit = "player", talent = 14}, -- Posthaste
        { spell = 164273, type = "buff", unit = "player"}, -- Lone Wolf
        { spell = 186258, type = "buff", unit = "player"}, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player"}, -- Aspect of the Turtle
        { spell = 193534, type = "buff", unit = "player", talent = 10}, -- Steady Focus
        { spell = 194594, type = "buff", unit = "player", talent = 20}, -- Lock and Load
        { spell = 199483, type = "buff", unit = "player", talent = 9}, -- Camouflage
        { spell = 231390, type = "buff", unit = "player", talent = 7}, -- Trailblazer
        { spell = 257044, type = "buff", unit = "player"}, -- Rapid Fire
        { spell = 257622, type = "buff", unit = "player"}, -- Trick Shots
        { spell = 260242, type = "buff", unit = "player"}, -- Precise Shots
        { spell = 260395, type = "buff", unit = "player", talent = 16}, -- Lethal Shots
        { spell = 260402, type = "buff", unit = "player", talent = 18}, -- Double Tap
        { spell = 264663, type = "buff", unit = "player"}, -- Predator's Thirst
        { spell = 264667, type = "buff", unit = "player"}, -- Primal Rage
        { spell = 264735, type = "ability", unit = "pet", buff = true}, -- Survival of the Fittest
        { spell = 288613, type = "buff", unit = "player"}, -- Trueshot
        { spell = 321461, type = "buff", unit = "player", talent = 17}, -- Dead Eye
      },
      icon = 461846
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3355, type = "debuff", unit = "multi"}, -- Freezing Trap
        { spell = 5116, type = "debuff", unit = "target"}, -- Concussive Shot
        { spell = 131894, type = "debuff", unit = "target", talent = 3}, -- A Murder of Crows
        { spell = 135299, type = "debuff", unit = "target"}, -- Tar Trap
        { spell = 186387, type = "debuff", unit = "target"}, -- Bursting Shot
        { spell = 257284, type = "debuff", unit = "target", talent = 12}, -- Hunter's Mark
        { spell = 269576, type = "debuff", unit = "target", talent = 1}, -- Master Marksman
        { spell = 271788, type = "debuff", unit = "target", talent = 2}, -- Serpent Sting
        { spell = 321469, type = "debuff", unit = "target", talent = 15}, -- Binding Shackles
      },
      icon = 236188
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 781, type = "ability"}, -- Disengage
        { spell = 1513, type = "ability", debuff = true}, -- Scare Beast
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 5116, type = "ability", requiresTarget = true}, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true}, -- Feign Death
        { spell = 6197, type = "ability", buff = true}, -- Eagle Eye
        { spell = 19434, type = "ability", requiresTarget = true, charges = true, overlayGlow = true}, -- Aimed Shot
        { spell = 19801, type = "ability", requiresTarget = true}, -- Tranquilizing Shot
        { spell = 34477, type = "ability", requiresTarget = true}, -- Misdirection
        { spell = 53351, type = "ability", requiresTarget = true}, -- Kill Shot
        { spell = 56641, type = "ability", requiresTarget = true}, -- Steady Shot
        { spell = 109248, type = "ability", requiresTarget = true}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 120360, type = "ability", talent = 5}, -- Barrage
        { spell = 131894, type = "ability", talent = 3}, -- A Murder of Crows
        { spell = 147362, type = "ability", requiresTarget = true}, -- Counter Shot
        { spell = 185358, type = "ability", requiresTarget = true, overlayGlow = true}, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true}, -- Aspect of the Turtle
        { spell = 186387, type = "ability", debuff = true}, -- Bursting Shot
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 195645, type = "ability", debuff = true}, -- Concussive Shot
        { spell = 199483, type = "ability", talent = 9}, -- Camouflage
        { spell = 212431, type = "ability", talent = 6}, -- Explosive Shot
        { spell = 257044, type = "ability", requiresTarget = true, overlayGlow = true}, -- Rapid Fire
        { spell = 257284, type = "ability", requiresTarget = true}, -- Hunter's Mark
        { spell = 257620, type = "ability", requiresTarget = true}, -- Multi-Shot
        { spell = 260243, type = "ability", talent = 21}, -- Volley
        { spell = 260402, type = "ability", buff = true, talent = 18}, -- Double Tap
        { spell = 264667, type = "ability", buff = true}, -- Primal Rage
        { spell = 264735, type = "ability", unit = "pet", buff = true}, -- Survival of the Fittest
        { spell = 271788, type = "ability", debuff = true, talent = 2}, -- Serpent Sting
        { spell = 272651, type = "ability"}, -- Command Pet Ability
        { spell = 288613, type = "ability", buff = true}, -- Trueshot
        { spell = 321297, type = "ability"}, -- Eyes of the Beast
        { spell = 342049, type = "ability", talent = 12}, -- Chimaera Shot
      },
      icon = 132329
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
        { spell = 53480, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Roar of Sacrifice
        { spell = 53480, type="buff", unit = "group", pvptalent = 7, titleSuffix = L["buff"]},-- Roar of Sacrifice
        { spell = 202797, type="ability", pvptalent = 3, titleSuffix = L["cooldown"]},-- Viper Sting
        { spell = 202797, type="debuff", unit = "target", pvptalent = 3, titleSuffix = L["debuff"]},-- Viper Sting
        { spell = 202900, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Scorpid Sting
        { spell = 202900, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Scorpid Sting
        { spell = 202914, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Spider Sting
        { spell = 202914, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Spider Sting
        { spell = 203155, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Sniper Shot
        { spell = 203155, type="buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]},-- Sniper Shot
        { spell = 213691, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Scatter Shot
        { spell = 213691, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Scatter Shot
        { spell = 236776, type="ability", pvptalent = 8},-- Hi-Explosive Trap
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 136, type = "buff", unit = "pet"}, -- Mend Pet
        { spell = 5384, type = "buff", unit = "player"}, -- Feign Death
        { spell = 6197, type = "buff", unit = "player"}, -- Eagle Eye
        { spell = 24450, type = "buff", unit = "pet"}, -- Prowl
        { spell = 35079, type = "buff", unit = "player"}, -- Misdirection
        { spell = 61684, type = "buff", unit = "pet"}, -- Dash
        { spell = 118922, type = "buff", unit = "player", talent = 14 }, -- Posthaste
        { spell = 186258, type = "buff", unit = "player"}, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player"}, -- Aspect of the Turtle
        { spell = 186289, type = "buff", unit = "player"}, -- Aspect of the Eagle
        { spell = 199483, type = "buff", unit = "player", talent = 9}, -- Camouflage
        { spell = 225788, type = "buff", unit = "player"}, -- Sign of the Emissary
        { spell = 231390, type = "buff", unit = "player", talent = 7 }, -- Trailblazer
        { spell = 259388, type = "buff", unit = "player", talent = 17 }, -- Mongoose Fury
        { spell = 260249, type = "buff", unit = "pet"}, -- Predator
        { spell = 260249, type = "buff", unit = "player"}, -- Predator
        { spell = 260286, type = "buff", unit = "player", talent = 16 }, -- Tip of the Spear
        { spell = 263892, type = "buff", unit = "pet"}, -- Catlike Reflexes
        { spell = 264663, type = "buff", unit = "pet"}, -- Predator's Thirst
        { spell = 264663, type = "buff", unit = "player"}, -- Predator's Thirst
        { spell = 264667, type = "buff", unit = "player"}, -- Primal Rage
        { spell = 265898, type = "buff", unit = "player", talent = 2 }, -- Terms of Engagement
        { spell = 266779, type = "buff", unit = "pet"}, -- Coordinated Assault
        { spell = 266779, type = "buff", unit = "player"}, -- Coordinated Assault
        { spell = 268552, type = "buff", unit = "player", talent = 1 }, -- Viper's Venom

      },
      icon = 1376044
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target"}, -- Growl
        { spell = 3355, type = "debuff", unit = "multi"}, -- Freezing Trap
        { spell = 24394, type = "debuff", unit = "target"}, -- Intimidation
        { spell = 117405, type = "debuff", unit = "target", talent = 15 }, -- Binding Shot
        { spell = 131894, type = "debuff", unit = "target", talent = 12 }, -- A Murder of Crows
        { spell = 135299, type = "debuff", unit = "target"}, -- Tar Trap
        { spell = 162480, type = "debuff", unit = "target"}, -- Steel Trap
        { spell = 162487, type = "debuff", unit = "target", talent = 11 }, -- Steel Trap
        { spell = 190927, type = "debuff", unit = "target"}, -- Harpoon
        { spell = 195645, type = "debuff", unit = "target"}, -- Wing Clip
        { spell = 259277, type = "debuff", unit = "target", talent = 10 }, -- Kill Command
        { spell = 259491, type = "debuff", unit = "target"}, -- Serpent Sting
        { spell = 269747, type = "debuff", unit = "target"}, -- Wildfire Bomb
        { spell = 270332, type = "debuff", unit = "target", talent = 20 }, -- Pheromone Bomb
        { spell = 270339, type = "debuff", unit = "target", talent = 20 }, -- Shrapnel Bomb
        { spell = 270343, type = "debuff", unit = "target"}, -- Internal Bleeding
        { spell = 271049, type = "debuff", unit = "target"}, -- Volatile Bomb

      },
      icon = 132309
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 781, type = "ability"}, -- Disengage
        { spell = 1513, type = "ability", debuff = true}, -- Scare Beast
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 2649, type = "ability", requiresTarget = true, debuff = true}, -- Growl
        { spell = 5384, type = "ability", buff = true}, -- Feign Death
        { spell = 6197, type = "ability", buff = true}, -- Eagle Eye
        { spell = 16827, type = "ability", requiresTarget = true}, -- Claw
        { spell = 19434, type = "ability", requiresTarget = true}, -- Aimed Shot
        { spell = 19577, type = "ability", requiresTarget = true, debuff = true}, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true}, -- Tranquilizing Shot
        { spell = 24450, type = "ability"}, -- Prowl
        { spell = 34477, type = "ability", requiresTarget = true}, -- Misdirection
        { spell = 56641, type = "ability", requiresTarget = true}, -- Steady Shot
        { spell = 61684, type = "ability"}, -- Dash
        { spell = 109248, type = "ability"}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 131894, type = "ability", talent = 12}, -- A Murder of Crows
        { spell = 162488, type = "ability", talent = 11}, -- Steel Trap
        { spell = 185358, type = "ability"}, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true}, -- Aspect of the Turtle
        { spell = 186270, type = "ability"}, -- Raptor Strike
        { spell = 186289, type = "ability", buff = true}, -- Aspect of the Eagle
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 187707, type = "ability", requiresTarget = true}, -- Muzzle
        { spell = 187708, type = "ability"}, -- Carve
        { spell = 190925, type = "ability", requiresTarget = true}, -- Harpoon
        { spell = 195645, type = "ability", requiresTarget = true}, -- Wing Clip
        { spell = 199483, type = "ability", talent = 9}, -- Camouflage
        { spell = 212436, type = "ability", charges = true, talent = 6 }, -- Butchery
        { spell = 257284, type = "ability", debuff = true}, -- Hunter's Mark
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
        { spell = 272651, type = "ability"}, -- Command Pet
        { spell = 321297, type = "ability"}, -- Eyes of the Beast
        { spell = 320976, type = "ability", requiresTarget = true}, -- Kill Shot
      },
      icon = 236184
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
        { spell = 53480, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Roar of Sacrifice
        { spell = 53480, type="buff", unit = "group", pvptalent = 11, titleSuffix = L["buff"]},-- Roar of Sacrifice
        { spell = 202797, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Viper Sting
        { spell = 202797, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"]},-- Viper Sting
        { spell = 202900, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Scorpid Sting
        { spell = 202900, type="debuff", unit = "target", pvptalent = 7, titleSuffix = L["debuff"]},-- Scorpid Sting
        { spell = 202914, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Spider Sting
        { spell = 202914, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Spider Sting
        { spell = 203268, type="debuff", unit = "target", pvptalent = 3},-- Sticky Tar
        { spell = 212638, type="ability", pvptalent = 1, titleSuffix = L["cooldown"]},-- Tracker's Net
        { spell = 212638, type="debuff", unit = "target", pvptalent = 1, titleSuffix = L["debuff"]},-- Tracker's Net
        { spell = 212640, type="ability", pvptalent = 10},-- Mending Bandage
        { spell = 236776, type="ability", pvptalent = 4},-- Hi-Explosive Trap
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 1784, type = "buff", unit = "player"}, -- Stealth
        { spell = 1966, type = "buff", unit = "player"}, -- Feint
        { spell = 2823, type = "buff", unit = "player"}, -- Deadly Poison
        { spell = 2983, type = "buff", unit = "player"}, -- Sprint
        { spell = 3408, type = "buff", unit = "player"}, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player"}, -- Evasion
        { spell = 5761, type = "buff", unit = "player"}, -- Numbing Poison
        { spell = 8679, type = "buff", unit = "player"}, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player"}, -- Vanish
        { spell = 31224, type = "buff", unit = "player"}, -- Cloak of Shadows
        { spell = 32645, type = "buff", unit = "player"}, -- Envenom
        { spell = 36554, type = "buff", unit = "player"}, -- Shadowstep
        { spell = 45182, type = "buff", unit = "player", talent = 11 }, -- Cheating Death
        { spell = 57934, type = "buff", unit = "player"}, -- Tricks of the Trade
        { spell = 108211, type = "buff", unit = "player", talent = 10}, -- Leeching Poison
        { spell = 114018, type = "buff", unit = "player"}, -- Shroud of Concealment
        { spell = 115192, type = "buff", unit = "player", talent = 5}, -- Subterfuge
        { spell = 121153, type = "buff", unit = "player", talent = 3}, -- Blindside
        { spell = 185311, type = "buff", unit = "player"}, -- Crimson Vial
        { spell = 193538, type = "buff", unit = "player", talent = 17}, -- Alacrity
        { spell = 193641, type = "buff", unit = "player", talent = 2}, -- Elaborate Planning
        { spell = 256735, type = "buff", unit = "player", talent = 6}, -- Master Assassin
        { spell = 270070, type = "buff", unit = "player", talent = 20}, -- Hidden Blades
        { spell = 315496, type = "buff"}, -- Slice and Dice
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target"}, -- Kidney Shot
        { spell = 703, type = "debuff", unit = "target"}, -- Garrote
        { spell = 1330, type = "debuff", unit = "target"}, -- Garrote - Silence
        { spell = 1833, type = "debuff", unit = "target"}, -- Cheap Shot
        { spell = 1943, type = "debuff", unit = "target"}, -- Rupture
        { spell = 2094, type = "debuff", unit = "multi"}, -- Blind
        { spell = 2818, type = "debuff", unit = "target"}, -- Deadly Poison
        { spell = 3409, type = "debuff", unit = "target"}, -- Crippling Poison
        { spell = 6770, type = "debuff", unit = "multi"}, -- Sap
        { spell = 8680, type = "debuff", unit = "target"}, -- Wound Poison
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
        { spell = 79140, type = "debuff", unit = "target"}, -- Vendetta
        { spell = 121411, type = "debuff", unit = "target", talent = 21}, -- Crimson Tempest
        { spell = 137619, type = "debuff", unit = "target", talent = 9}, -- Marked for Death
        { spell = 154953, type = "debuff", unit = "target", talent = 13}, -- Internal Bleeding
        { spell = 256148, type = "debuff", unit = "target", talent = 14}, -- Iron Wire
        { spell = 255909, type = "debuff", unit = "target", talent = 15}, -- Prey on the Weak
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
        { spell = 5277, type = "ability", buff = true}, -- Evasion
        { spell = 5938, type = "ability", requiresTarget = true}, -- Shiv
        { spell = 6770, type = "ability", usable = true, requiresTarget = true, debuff = true}, -- Sap
        { spell = 8676, type = "ability"}, -- Ambush
        { spell = 31224, type = "ability", buff = true}, -- Cloak of Shadows
        { spell = 36554, type = "ability", requiresTarget = true}, -- Shadowstep
        { spell = 51723, type = "ability"}, -- Fan of Knives
        { spell = 57934, type = "ability", requiresTarget = true}, -- Tricks of the Trade
        { spell = 79140, type = "ability", requiresTarget = true, debuff = true}, -- Vendetta
        { spell = 114018, type = "ability", usable = true, buff = true}, -- Shroud of Concealment
        { spell = 115191, type = "ability", buff = true}, -- Stealth
        { spell = 121411, type = "ability"}, -- Crimson Tempest
        { spell = 137619, type = "ability", requiresTarget = true, debuff = true, talent = 9}, -- Marked for Death
        { spell = 185311, type = "ability", buff = true}, -- Crimson Vial
        { spell = 185565, type = "ability"}, -- Poisoned Knife
        { spell = 196819, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Envenom
        { spell = 200806, type = "ability", requiresTarget = true, usable = true, talent = 18}, -- Exsanguinate
        { spell = 315496, type = "ability"}, -- Slice and Dice
      },
      icon = 132350
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
        { spell = 197003, type="buff", unit = "target", pvptalent = 10},-- Maneuverability
        { spell = 197051, type="debuff", unit = "target", pvptalent = 6},-- Mind-Numbing Poison
        { spell = 197091, type="debuff", unit = "target", pvptalent = 7, titleSuffix = L["debuff"]},-- Neurotoxin
        { spell = 198097, type="debuff", unit = "target", pvptalent = 3},-- Creeping Venom
        { spell = 198222, type="debuff", unit = "target", pvptalent = 5},-- System Shock
        { spell = 269513, type="ability", pvptalent = 8},-- Death from Above
        { spell = 206328, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Neurotoxin
        { spell = 212182, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Smoke Bomb
        { spell = 212183, type="debuff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- Smoke Bomb
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = comboPointsIcon,
    },
  },
  [2] = { -- Outlaw
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 1784, type = "buff", unit = "player"}, -- Stealth
        { spell = 1966, type = "buff", unit = "player"}, -- Feint
        { spell = 2983, type = "buff", unit = "player"}, -- Sprint
        { spell = 3408, type = "buff", unit = "player"}, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player"}, -- Evasion
        { spell = 5761, type = "buff", unit = "player"}, -- Numbing Poison
        { spell = 8679, type = "buff", unit = "player"}, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player"}, -- Vanish
        { spell = 13750, type = "buff", unit = "player"}, -- Adrenaline Rush
        { spell = 13877, type = "buff", unit = "player"}, -- Blade Flurry
        { spell = 31224, type = "buff", unit = "player"}, -- Cloak of Shadows
        { spell = 45182, type = "buff", unit = "player", talent = 11 }, -- Cheating Death
        { spell = 51690, type = "buff", unit = "player", talent = 21}, -- Killing Spree
        { spell = 57934, type = "buff", unit = "player"}, -- Tricks of the Trade
        { spell = 13750, type = "buff", unit = "player"}, -- Adrenaline Rush
        { spell = 114018, type = "buff", unit = "player"}, -- Shroud of Concealment
        { spell = 185311, type = "buff", unit = "player"}, -- Crimson Vial
        { spell = 193357, type = "buff", unit = "player"}, -- Ruthless Precision
        { spell = 193358, type = "buff", unit = "player"}, -- Grand Melee
        { spell = 193538, type = "buff", unit = "player", talent = 17}, -- Alacrity
        { spell = 193359, type = "buff", unit = "player"}, -- True Bearing
        { spell = 199600, type = "buff", unit = "player"}, -- Buried Treasure
        { spell = 199603, type = "buff", unit = "player"}, -- Skull and Crossbones
        { spell = 199754, type = "buff", unit = "player"}, -- Riposte
        { spell = 195627, type = "buff", unit = "player"}, -- Opportunity
        { spell = 193356, type = "buff", unit = "player"}, -- Broadside
        { spell = 271896, type = "buff", unit = "player", talent = 20}, -- Blade Rush
        { spell = 315496, type = "buff"}, -- Slice and Dice
        { spell = 315584, type = "buff", unit = "player"}, -- Instant Poison
      },
      icon = 132350
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target"}, -- Kindney Shot
        { spell = 1776, type = "debuff", unit = "target"}, -- Gouge
        { spell = 1833, type = "debuff", unit = "target"}, -- Cheap Shot
        { spell = 2094, type = "debuff", unit = "multi"}, -- Blind
        { spell = 6770, type = "debuff", unit = "multi"}, -- Sap
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
        { spell = 137619, type = "debuff", unit = "target", talent = 9}, -- Marked for Death
        { spell = 185763, type = "debuff", unit = "target"}, -- Pistol Shot
        { spell = 199804, type = "debuff", unit = "target"}, -- Between the Eyes
        { spell = 196937, type = "debuff", unit = "target", talent = 3}, -- Ghostly Strike
        { spell = 255909, type = "debuff", unit = "target", talent = 15}, -- Prey on the Weak
      },
      icon = 1373908
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 408, type = "ability"}, -- Kindney Shot
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1752, type = "ability", requiresTarget = true}, -- Sinister Strike
        { spell = 1766, type = "ability", requiresTarget = true}, -- Kick
        { spell = 1776, type = "ability", requiresTarget = true, debuff = true}, -- Gouge
        { spell = 1784, type = "ability", buff = true}, -- Stealth
        { spell = 1833, type = "ability", debuff = true}, -- Cheap Shot
        { spell = 1856, type = "ability", buff = true}, -- Vanish
        { spell = 1966, type = "ability", buff = true}, -- Feint
        { spell = 2094, type = "ability", requiresTarget = true, debuff = true}, -- Blind
        { spell = 2098, type = "ability", requiresTarget = true, usable = true}, -- Dispatch
        { spell = 2983, type = "ability", buff = true }, -- Sprint
        { spell = 5277, type = "ability", buff = true }, -- Evasion
        { spell = 5938, type = "ability"}, -- Shiv
        { spell = 6770, type = "ability", debuff = true }, -- Sap
        { spell = 8676, type = "ability", requiresTarget = true, usable = true}, -- Ambush
        { spell = 13750, type = "ability", buff = true}, -- Adrenaline Rush
        { spell = 13877, type = "ability", buff = true, charges = true}, -- Blade Flurry
        { spell = 31224, type = "ability", buff = true}, -- Cloak of Shadows
        { spell = 51690, type = "ability", requiresTarget = true, talent = 21}, -- Killing Spree
        { spell = 57934, type = "ability", requiresTarget = true, debuff = true}, -- Tricks of the Trade
        { spell = 57934, type = "ability", requiresTarget = true}, -- Tricks of the Trade
        { spell = 79096, type = "ability"}, -- Restless Blades
        { spell = 114018, type = "ability", usable = true, buff = true}, -- Shroud of Concealment
        { spell = 137619, type = "ability", requiresTarget = true, debuff = true, talent = 9}, -- Marked for Death
        { spell = 185311, type = "ability", buff = true}, -- Crimson Vial
        { spell = 185763, type = "ability", requiresTarget = true}, -- Pistol Shot
        { spell = 195457, type = "ability", requiresTarget = true}, -- Grappling Hook
        { spell = 196937, type = "ability", requiresTarget = true, debuff = true, talent = 3}, -- Ghostly Strike
        { spell = 199754, type = "ability", buff = true}, -- Riposte
        { spell = 196819, type = "ability"}, -- Dispatch
        { spell = 199804, type = "ability", usable = true, requiresTarget = true}, -- Between the Eyes
        { spell = 271877, type = "ability", buff = true, talent = 20}, -- Blade Rush
        { spell = 315496, type = "ability", buff = true}, -- Slice and Dice
        { spell = 315341, type = "ability", debuff = true}, -- Between the Eyes
        { spell = 315508, type = "ability", requiresTarget = true, usable = true}, -- Roll the Bones
        { spell = 343142, type = "ability", requiresTarget = true}, -- Dreadblades
      },
      icon = 135610
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
        { spell = 197003, type="buff", unit = "target", pvptalent = 5},-- Maneuverability
        { spell = 198027, type="buff", unit = "player", pvptalent = 2},-- Turn the Tables
        { spell = 198368, type="buff", unit = "player", pvptalent = 11},-- Take Your Cut
        { spell = 198529, type="ability", pvptalent = 13, titleSuffix = L["cooldown"]},-- Plunder Armor
        { spell = 198529, type="buff", unit = "player", pvptalent = 13, titleSuffix = L["debuff"]},-- Plunder Armor
        { spell = 207777, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Dismantle
        { spell = 207777, type="debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]},-- Dismantle
        { spell = 209754, type="buff", unit = "player", pvptalent = 12},-- Boarding Party
        { spell = 212150, type="debuff", unit = "target", pvptalent = 1, titleSuffix = L["debuff"]},-- Cheap Tricks
        { spell = 212210, type="ability", pvptalent = 7},-- Drink Up Me Hearties
        { spell = 213995, type="buff", unit = "player", pvptalent = 1, titleSuffix = L["buff"]},-- Cheap Tricks
        { spell = 212182, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Smoke Bomb
        { spell = 212183, type="debuff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Smoke Bomb
        { spell = 269513, type="ability", pvptalent = 3},-- Death from Above
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = comboPointsIcon,
    },
  },
  [3] = { -- Subtlety
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 1784, type = "buff", unit = "player"}, -- Stealth
        { spell = 1966, type = "buff", unit = "player"}, -- Feint
        { spell = 2983, type = "buff", unit = "player"}, -- Sprint
        { spell = 3408, type = "buff", unit = "player"}, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player"}, -- Evasion
        { spell = 5761, type = "buff", unit = "player"}, -- Numbing Poison
        { spell = 8679, type = "buff", unit = "player"}, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player"}, -- Vanish
        { spell = 31224, type = "buff", unit = "player"}, -- Cloak of Shadows
        { spell = 45182, type = "buff", unit = "player", talent = 11 }, -- Cheating Death
        { spell = 57934, type = "buff", unit = "player"}, -- Tricks of the Trade
        { spell = 114018, type = "buff", unit = "player"}, -- Shroud of Concealment
        { spell = 115191, type = "buff", unit = "player"}, -- Stealth
        { spell = 115192, type = "buff", unit = "player", talent = 5}, -- Subterfuge
        { spell = 121471, type = "buff", unit = "player"}, -- Shadow Blades
        { spell = 185311, type = "buff", unit = "player"}, -- Crimson Vial
        { spell = 185422, type = "buff", unit = "player"}, -- Shadow Dance
        { spell = 196980, type = "buff", unit = "player", talent = 19}, -- Master of Shadows
        { spell = 212283, type = "buff", unit = "player"}, -- Symbols of Death
        { spell = 257506, type = "buff", unit = "player", talent = 13}, -- Shot in the Dark
        { spell = 277925, type = "buff", unit = "player", talent = 21}, -- Shuriken Tornado
        { spell = 193538, type = "buff", unit = "player", talent = 17}, -- Alacrity
        { spell = 245640, type = "buff", unit = "player"}, -- Shuriken Combo
        { spell = 315496, type = "buff", unit = "player"}, -- Slice and Dice
        { spell = 315584, type = "buff", unit = "player"}, -- Instant Poison
        { spell = 343173, type = "buff", unit = "player", talent = 2}, -- Premeditation
      },
      icon = 376022
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target"}, -- Kidney Shot
        { spell = 1833, type = "debuff", unit = "target"}, -- Cheap Shot
        { spell = 1943, type = "debuff", unit = "target"}, -- Rupture
        { spell = 2094, type = "debuff", unit = "multi"}, -- Blind
        { spell = 6770, type = "debuff", unit = "multi"}, -- Sap
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
        { spell = 91021, type = "debuff", unit = "target"}, -- Find Weakness
        { spell = 137619, type = "debuff", unit = "target", talent = 9}, -- Marked for Death
        { spell = 195452, type = "debuff", unit = "target"}, -- Nightblade
        { spell = 206760, type = "debuff", unit = "target", talent = 14}, -- Shadow's Grasp
        { spell = 255909, type = "debuff", unit = "target", talent = 15}, -- Prey on the Weak
      },
      icon = 136175
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 408, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Kidney Shot
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1752, type = "ability", requiresTarget = true}, -- Backstab
        { spell = 1766, type = "ability", requiresTarget = true}, -- Kick
        { spell = 1784, type = "ability", buff = true}, -- Stealth
        { spell = 1833, type = "ability", usable = true, requiresTarget = true, debuff = true}, -- Cheap Shot
        { spell = 1856, type = "ability", buff = true}, -- Vanish
        { spell = 1943, type = "ability", debuff = true}, -- Rupture
        { spell = 1966, type = "ability", buff = true}, -- Feint
        { spell = 2094, type = "ability", requiresTarget = true, debuff = true}, -- Blind
        { spell = 2983, type = "ability", buff = true}, -- Sprint
        { spell = 5277, type = "ability", buff = true}, -- Evasion
        { spell = 5938, type = "ability"}, -- Shiv
        { spell = 6770, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Sap
        { spell = 8676, type = "ability", requiresTarget = true, usable = true}, -- Shadowstrike
        { spell = 57934, type = "ability", requiresTarget = true}, -- Tricks of the Trade
        { spell = 57934, type = "ability", requiresTarget = true, debuff = true}, -- Tricks of the Trade
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
        { spell = 200758, type = "ability"}, -- Gloomblade
        { spell = 212283, type = "ability", buff = true}, -- Symbols of Death
        { spell = 277925, type = "ability", buff = true, talent = 21}, -- Shuriken Tornado
        { spell = 280719, type = "ability", requiresTarget = true, usable = true, debuff = true, talent = 20}, -- Secret Technique
        { spell = 315496, type = "ability", buff = true}, -- Slice and Dice
        { spell = 319175, type = "ability", buff = true}, -- Shadow Vault
      },
      icon = 236279
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
        { spell = 198688, type="debuff", unit = "target", pvptalent = 7},-- Dagger in the Dark
        { spell = 199027, type="buff", unit = "player", pvptalent = 10},-- Veil of Midnight
        { spell = 197003, type="buff", unit = "player", pvptalent = 3},-- Maneuverability
        { spell = 207736, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Shadowy Duel
        { spell = 207736, type="buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"]},-- Shadowy Duel
        { spell = 212182, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Smoke Bomb
        { spell = 212183, type="debuff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- Smoke Bomb
        { spell = 213981, type="ability", pvptalent = 1, titleSuffix = L["cooldown"]},-- Cold Blood
        { spell = 213981, type="buff", unit = "player", pvptalent = 1, titleSuffix = L["buff"]},-- Cold Blood
        { spell = 269513, type="ability", pvptalent = 5},-- Death from Above
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = comboPointsIcon,
    },
  },
}

templates.class.PRIEST = {
  [1] = { -- Discipline
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 17, type = "buff", unit = "target"}, -- Power Word: Shield
        { spell = 586, type = "buff", unit = "player"}, -- Fade
        { spell = 2096, type = "buff", unit = "player"}, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player"}, -- Power Infusion
        { spell = 19236, type = "buff", unit = "player"}, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 33206, type = "buff", unit = "group"}, -- Pain Suppression
        { spell = 47536, type = "buff", unit = "player"}, -- Rapture
        { spell = 45243, type = "buff", unit = "player" }, -- Focused Will
        { spell = 65081, type = "buff", unit = "player", talent = 4}, -- Body and Soul
        { spell = 81782, type = "buff", unit = "target"}, -- Power Word: Barrier
        { spell = 109964, type = "buff", unit = "player"}, -- Spirit Shell
        { spell = 111759, type = "buff", unit = "player"}, -- Levitate
        { spell = 121557, type = "buff", unit = "player", talent = 6}, -- Angelic Feather
        { spell = 193065, type = "buff", unit = "player", talent = 5}, -- Masochism
        { spell = 194384, type = "buff", unit = "group"}, -- Atonement
        { spell = 198069, type = "buff", unit = "player"}, -- Power of the Dark Side
        { spell = 265258, type = "buff", unit = "player", talent = 2}, -- Twist of Fate
        { spell = 280398, type = "buff", unit = "player", talent = 13}, -- Sins of the Many
      },
      icon = 135940
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target"}, -- Shadow Word: Pain
        { spell = 2096, type = "debuff", unit = "target"}, -- Mind Vision
        { spell = 8122, type = "debuff", unit = "target"}, -- Psychic Scream
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
        { spell = 204263, type = "debuff", unit = "target", talent = 12}, -- Shining Force
        { spell = 208772, type = "debuff", unit = "target"}, -- Smite
        { spell = 204213, type = "debuff", unit = "target", talent = 16}, -- Purge the Wicked
        { spell = 214621, type = "debuff", unit = "target", talent = 3}, -- Schism
      },
      icon = 136207
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 17, type = "ability"}, -- Power Word: Shield
        { spell = 453, type = "ability"}, -- Mind Soothe
        { spell = 527, type = "ability"}, -- Purify
        { spell = 528, type = "ability"}, -- Dispel Magic
        { spell = 585, type = "ability"}, -- Smite
        { spell = 586, type = "ability", buff = true}, -- Fade
        { spell = 605, type = "ability"}, -- Mind Control
        { spell = 1706, type = "ability", buff = true}, -- Levitate
        { spell = 2061, type = "ability", overlayGlow = true}, -- Shadow Mend
        { spell = 2096, type = "ability"}, -- Mind Vision
        { spell = 2006, type = "ability"}, -- Resurrection
        { spell = 8092, type = "ability", requiresTarget = true}, -- Mind Blast
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 9484, type = "ability", debuff = true}, -- Shackle Undead
        { spell = 10060, type = "ability"}, -- Power Infusion
        { spell = 19236, type = "ability", buff = true}, -- Desperate Prayer
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 32379, type = "ability", charges = true, usable = true, requiresTarget = true}, -- Shadow Word: Death
        { spell = 33206, type = "ability"}, -- Pain Suppression
        { spell = 34433, type = "ability", totem = true, requiresTarget = true}, -- Shadowfiend
        { spell = 47536, type = "ability", buff = true}, -- Rapture
        { spell = 47540, type = "ability", requiresTarget = true}, -- Penance
        { spell = 48045, type = "ability", requiresTarget = true}, -- Mind Sear
        { spell = 62618, type = "ability"}, -- Power Word: Barrier
        { spell = 73325, type = "ability"}, -- Leap of Faith
        { spell = 109964, type = "ability", buff = true, talent = 20}, -- Divine Star
        { spell = 110744, type = "ability", talent = 17}, -- Divine Star
        { spell = 120517, type = "ability", talent = 18}, -- Halo
        { spell = 121536, type = "ability", charges = true, buff = true, talent = 6}, -- Angelic Feather
        { spell = 123040, type = "ability", totem = true, requiresTarget = true, talent = 8}, -- Mindbender
        { spell = 129250, type = "ability", requiresTarget = true, talent = 9}, -- Power Word: Solace
        { spell = 132157, type = "ability"}, -- Holy Nova
        { spell = 194509, type = "ability", charges = true}, -- Power Word: Radiance
        { spell = 204197, type = "ability", talent = 16}, -- Purge the Wicked
        { spell = 204263, type = "ability", talent = 12}, -- Shining Force
        { spell = 212036, type = "ability"}, -- Mass Resurrection
        { spell = 214621, type = "ability", requiresTarget = true, debuff = true, talent = 3}, -- Schism
        { spell = 246287, type = "ability", talent = 21}, -- Evangelism
        { spell = 314867, type = "ability", talent = 15}, -- Shadow Covenant
      },
      icon = 136224
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
        { spell = 197862, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Archangel
        { spell = 197862, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Archangel
        { spell = 197871, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Dark Archangel
        { spell = 197871, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Dark Archangel
        { spell = 316262, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Thoughtsteal
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
  [2] = { -- Holy
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 17, type = "buff", unit = "player"}, -- Power Word: Shield
        { spell = 139, type = "buff", unit = "target"}, -- Renew
        { spell = 586, type = "buff", unit = "player"}, -- Fade
        { spell = 2096, type = "buff", unit = "player"}, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player"}, -- Power Infusion
        { spell = 19236, type = "buff", unit = "player"}, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 27827, type = "buff", unit = "player"}, -- Spirit of Redemption
        { spell = 41635, type = "buff", unit = "group"}, -- Prayer of Mending
        { spell = 45243, type = "buff", unit = "player" }, -- Focused Will
        { spell = 47788, type = "buff", unit = "target"}, -- Guardian Spirit
        { spell = 64843, type = "buff", unit = "player"}, -- Divine Hymn
        { spell = 64901, type = "buff", unit = "player"}, -- Symbol of Hope
        { spell = 65081, type = "buff", unit = "player"}, -- Body and Soul
        { spell = 77489, type = "buff", unit = "target"}, -- Echo of Light
        { spell = 111759, type = "buff", unit = "player"}, -- Levitate
        { spell = 114255, type = "buff", unit = "player", talent = 13}, -- Surge of Light
        { spell = 121557, type = "buff", unit = "player", talent = 6}, -- Angelic Feather
        { spell = 200183, type = "buff", unit = "player", talent = 20}, -- Apotheosis
        { spell = 321379, type = "buff", unit = "player", talent = 15}, -- Prayer Circle
      },
      icon = 135953
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target"}, -- Shadow Word: Pain
        { spell = 2096, type = "debuff", unit = "target"}, -- Mind Vision
        { spell = 8122, type = "debuff", unit = "target"}, -- Psychic Scream
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
        { spell = 14914, type = "debuff", unit = "target"}, -- Holy Fire
        { spell = 200200, type = "debuff", unit = "target"}, -- Holy Word: Chastise
        { spell = 200196, type = "debuff", unit = "target"}, -- Holy Word: Chastise
        { spell = 204263, type = "debuff", unit = "target"}, -- Shining Force
      },
      icon = 135972
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 17, type = "ability"}, -- Power Word: Shield
        { spell = 139, type = "ability"}, -- Renew
        { spell = 527, type = "ability"}, -- Purify
        { spell = 453, type = "ability"}, -- Mind Soothe
        { spell = 528, type = "ability"}, -- Dispel Magic
        { spell = 585, type = "ability"}, -- Smite
        { spell = 586, type = "ability", buff = true}, -- Fade
        { spell = 589, type = "ability"}, -- Shadow Word: Pain
        { spell = 596, type = "ability"}, -- Prayer of Healing
        { spell = 605, type = "ability"}, -- Mind Control
        { spell = 1706, type = "ability"}, -- Levitate
        { spell = 2006, type = "ability"}, -- Resurrection
        { spell = 2050, type = "ability"}, -- Holy Word: Serenity
        { spell = 2060, type = "ability"}, -- Heal
        { spell = 2061, type = "ability"}, -- Flash Heal
        { spell = 2096, type = "ability"}, -- Mind Vision
        { spell = 8092, type = "ability", requiresTarget = true}, -- Holy Fire
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 9484, type = "ability"}, -- Shackle Undead
        { spell = 10060, type = "ability", buff = true}, -- Power Infusion
        { spell = 14914, type = "ability", requiresTarget = true}, -- Holy Fire
        { spell = 19236, type = "ability", buff = true}, -- Desperate Prayer
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 32379, type = "ability"}, -- Shadow Word: Death
        { spell = 32379, type = "ability", charges = true, usable = true, requiresTarget = true}, -- Shadow Word: Death
        { spell = 32546, type = "ability"}, -- Binding Heal
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
        { spell = 132157, type = "ability"}, -- Holy Nova
        { spell = 200183, type = "ability", buff = true, talent = 20}, -- Apotheosis
        { spell = 204263, type = "ability", talent = 12}, -- Shining Force
        { spell = 204883, type = "ability"}, -- Circle of Healing
        { spell = 212036, type = "ability"}, -- Mass Resurrection
        { spell = 265202, type = "ability", talent = 21}, -- Holy Word: Salvation

      },
      icon = 135937
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
        { spell = 197268, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Ray of Hope
        { spell = 213602, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Greater Fade
        { spell = 213602, type="buff", unit = "player", pvptalent = 4, titleSuffix = L["buff"]},-- Greater Fade
        { spell = 213610, type="ability", pvptalent = 3, titleSuffix = L["cooldown"]},-- Holy Ward
        { spell = 213610, type="buff", unit = "target", pvptalent = 3, titleSuffix = L["buff"]},-- Holy Ward
        { spell = 215982, type="ability", pvptalent = 6},-- Spirit of the Redeemer
        { spell = 232707, type="buff", unit = "target", pvptalent = 5, titleSuffix = L["buff"]},-- Ray of Hope
        { spell = 289657, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Holy Word: Concentration
        { spell = 289655, type="buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- Holy Word: Concentration
        { spell = 289666, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Greater Heal
        { spell = 316262, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Thoughtsteal
        { spell = 328530, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Divine Ascension
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
  [3] = { -- Shadow
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 17, type = "buff", unit = "player"}, -- Power Word: Shield
        { spell = 586, type = "buff", unit = "player"}, -- Fade
        { spell = 2096, type = "buff", unit = "player"}, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player"}, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player"}, -- Vampiric Embrace
        { spell = 19236, type = "buff", unit = "player"}, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Power Word: Fortitude
        { spell = 45243, type = "buff", unit = "player" }, -- Focused Will
        { spell = 47585, type = "buff", unit = "player"}, -- Dispersion
        { spell = 65081, type = "buff", unit = "player", talent = 4}, -- Body and Soul
        { spell = 111759, type = "buff", unit = "player"}, -- Levitate
        { spell = 124430, type = "buff", unit = "player", talent = 2}, -- Shadowy Insight
        { spell = 123254, type = "buff", unit = "player", talent = 7}, -- Twist of Fate
        { spell = 193223, type = "buff", unit = "player", talent = 21}, -- Surrender to Madness
        { spell = 194249, type = "buff", unit = "player"}, -- Voidform
        { spell = 197937, type = "buff", unit = "player", talent = 16}, -- Lingering Insanity
        { spell = 232698, type = "buff", unit = "player"}, -- Shadowform
        { spell = 263165, type = "buff", unit = "player", talent = 18}, -- Void Torrent
        { spell = 319952, type = "buff", unit = "player", talent = 21}, -- Surrender to Madness
        { spell = 321973, type = "buff", unit = "player", talent = 2}, -- Death and Madness
        { spell = 341207, type = "buff", unit = "player"}, -- Dark Thoughts
        { spell = 341282, type = "buff", unit = "player", talent = 3}, -- Unfurling Darkness
      },
      icon = 237566
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target"}, -- Shadow Word: Pain
        { spell = 2096, type = "debuff", unit = "target"}, -- Mind Vision
        { spell = 8122, type = "debuff", unit = "target"}, -- Psychic Scream
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
        { spell = 15407, type = "debuff", unit = "target"}, -- Mind Flay
        { spell = 15487, type = "debuff", unit = "target"}, -- Silence
        { spell = 34914, type = "debuff", unit = "target"}, -- Vampiric Touch
        { spell = 48045, type = "debuff", unit = "target"}, -- Mind Sear
        { spell = 64044, type = "debuff", unit = "target"}, -- Psychic Horror
        { spell = 205369, type = "debuff", unit = "target", talent = 11}, -- Mind Bomb
        { spell = 226943, type = "debuff", unit = "target", talent = 11}, -- Mind Bomb
        { spell = 263165, type = "debuff", unit = "target", talent = 18}, -- Void Torrent
        { spell = 335467, type = "debuff", unit = "target"}, -- Devouring Plague
        { spell = 341291, type = "debuff", unit = "player", talent = 3}, -- Unfurling Darkness
      },
      icon = 136207
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 17, type = "ability", buff = true}, -- Power Word: Shield
        { spell = 453, type = "ability"}, -- Mind Soothe
        { spell = 528, type = "ability"}, -- Dispel Magic
        { spell = 585, type = "ability"}, -- Mind Flay
        { spell = 586, type = "ability", buff = true}, -- Fade
        { spell = 589, type = "ability", debuff = true}, -- Shadow Word: Pain
        { spell = 605, type = "ability", buff = true}, -- Mind Control
        { spell = 1706, type = "ability", buff = true}, -- Levitate
        { spell = 2006, type = "ability"}, -- Resurrection
        { spell = 2096, type = "ability"}, -- Mind Vision
        { spell = 2061, type = "ability"}, -- Shadow Mend
        { spell = 8092, type = "ability", requiresTarget = true}, -- Mind Blast
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 9484, type = "ability"}, -- Shackle Undead
        { spell = 10060, type = "ability", buff = true}, -- Power Infusion
        { spell = 15286, type = "ability", buff = true}, -- Vampiric Embrace
        { spell = 15487, type = "ability", requiresTarget = true}, -- Silence
        { spell = 19236, type = "ability", buff = true}, -- Desperate Prayer
        { spell = 32379, type = "ability"}, -- Shadow Word: Death
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 34915, type = "ability", debuff = true}, -- Vampiric Touch
        { spell = 32379, type = "ability", charges = true, usable = true, requiresTarget = true}, -- Shadow Word: Death
        { spell = 34433, type = "ability", totem = true, requiresTarget = true}, -- Shadowfiend
        { spell = 47585, type = "ability", buff = true}, -- Dispersion
        { spell = 48045, type = "ability"}, -- Mind Sear
        { spell = 64044, type = "ability", requiresTarget = true, talent = 12}, -- Psychic Horror
        { spell = 73325, type = "ability"}, -- Leap of Faith
        { spell = 200174, type = "ability", totem = true, requiresTarget = true, talent = 17}, -- Mindbender
        { spell = 205351, type = "ability", charges = true, requiresTarget = true, talent = 3}, -- Shadow Word: Void
        { spell = 205369, type = "ability", requiresTarget = true, talent = 11}, -- Mind Bomb
        { spell = 205448, type = "ability", usable = true, requiresTarget = true}, -- Void Bolt
        { spell = 213634, type = "ability"}, -- Purify Disease
        { spell = 228260, type = "ability", requiresTarget = true}, -- Void Eruption
        { spell = 263165, type = "ability", requiresTarget = true, talent = 18}, -- Void Torrent
        { spell = 263346, type = "ability", requiresTarget = true, talent = 9}, -- Dark Void
        { spell = 319952, type = "ability", talent = 21}, -- Surrender to Madness
        { spell = 341374, type = "ability", talent = 16}, -- Damnation
        { spell = 341385, type = "ability", requiresTarget = true, usable = true, talent = 9}, -- Searing Nightmares
        { spell = 342834, type = "ability", talent = 15}, -- Shadow Crash
        { spell = 335467, type = "ability", requiresTarget = true, usable = true, debuff = true}, -- Devouring Plague
      },
      icon = 136230
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
        { spell = 108968, type="ability", pvptalent = 3},-- Void Shift
        { spell = 213602, type="buff", unit = "target", pvptalent = 7},-- Greater Fade
        { spell = 211522, type="ability", pvptalent = 4},-- Psyfiend
        { spell = 247776, type="buff", unit = "player", pvptalent = 1, titleSuffix = L["buff"]},-- Mind Trauma
        { spell = 247777, type="debuff", unit = "target", pvptalent = 1, titleSuffix = L["debuff"]},-- Mind Trauma
        { spell = 316262, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Thoughtsteal
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 546, type = "buff", unit = "player"}, -- Water Walking
        { spell = 974, type = "buff", unit = "player", talent = 8}, -- Earth Shield
        { spell = 2645, type = "buff", unit = "player"}, -- Ghost Wolf
        { spell = 6196, type = "buff", unit = "player"}, -- Far Sight
        { spell = 77762, type = "buff", unit = "player"}, -- Lava Surge
        { spell = 79206, type = "buff", unit = "player"}, -- Spiritwalker's Grace
        { spell = 108271, type = "buff", unit = "player"}, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 14}, -- Ancestral Guidance
        { spell = 114050, type = "buff", unit = "player", talent = 21}, -- Ascendance
        { spell = 118522, type = "buff", unit = "player", talent = 6}, -- Elemental Blast: Critical Strike
        { spell = 157348, type = "buff", unit = "pet", talent = {11,17}}, -- Call Lightning
        { spell = 173183, type = "buff", unit = "player", talent = 6}, -- Elemental Blast: Haste
        { spell = 173184, type = "buff", unit = "player", talent = 6}, -- Elemental Blast: Mastery
        { spell = 191634, type = "buff", unit = "player", talent = 20}, -- Stormkeeper
        { spell = 192082, type = "buff", unit = "player", talent = 15}, -- Wind Rush
        { spell = 202192, type = "buff", unit = "player", talent = 6}, -- Resonance Totem
        { spell = 210652, type = "buff", unit = "player", talent = 6}, -- Storm Totem
        { spell = 210658, type = "buff", unit = "player", talent = 6}, -- Ember Totem
        { spell = 210659, type = "buff", unit = "player", talent = 6}, -- Tailwind Totem
        { spell = 210714, type = "buff", unit = "player", talent = 18}, -- Icefury
        { spell = 260734, type = "buff", unit = "player", talent = 10}, -- Master of the Elements
        { spell = 260881, type = "buff", unit = "player", talent = 7}, -- Spirit Wolf
        { spell = 272737, type = "buff", unit = "player", talent = 19}, -- Unlimited Power
        { spell = 285514, type = "buff", unit = "player", talent = 16}, -- Surge of Power

        -- Enchant
        { spell = 318038, type = "weaponenchant", enchant = 5400, weapon = "main"}, -- Flametongue Weapon
      },
      icon = 135863
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3600, type = "debuff", unit = "target"}, -- Earthbind
        { spell = 51490, type = "debuff", unit = "target"}, -- Thunderstorm
        { spell = 118297, type = "debuff", unit = "target"}, -- Immolate
        { spell = 118345, type = "debuff", unit = "target"}, -- Pulverize
        { spell = 118905, type = "debuff", unit = "target"}, -- Static Charge
        { spell = 188389, type = "debuff", unit = "target"}, -- Flame Shock
        { spell = 157375, type = "debuff", unit = "target"}, -- Eye of the Storm
        { spell = 196840, type = "debuff", unit = "target"}, -- Frost Shock
        { spell = 269808, type = "debuff", unit = "target", talent = 1}, -- Exposed Elements

      },
      icon = 135813
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 370, type = "ability"}, -- Purge
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 1064, type = "ability"}, -- Chain Heal
        { spell = 2008, type = "ability"}, -- Ancestral Spirit
        { spell = 2484, type = "ability", totem = true}, -- Earthbind Totem
        { spell = 2825, type = "ability", buff = true}, -- Bloodlust
        { spell = 5394, type = "ability", totem = true}, -- Healing Stream Totem
        { spell = 6196, type = "ability"}, -- Far Sight
        { spell = 8004, type = "ability"}, -- Healing Surge
        { spell = 8042, type = "ability"}, -- Earth Shock
        { spell = 8143, type = "ability", totem = true}, -- Tremor Totem
        { spell = 32182, type = "ability", buff = true}, -- Heroism
        { spell = 51490, type = "ability"}, -- Thunderstorm
        { spell = 51505, type = "ability", requiresTarget = true, talent = {1,3}, overlayGlow = true}, -- Lava Burst
        { spell = 51505, type = "ability", charges = true, requiresTarget = true, talent = 2, titleSuffix = " (2 Charges)", overlayGlow = true}, -- Lava Burst
        { spell = 51514, type = "ability", requiresTarget = true}, -- Hex
        { spell = 51886, type = "ability"}, -- Cleanse Spirit
        { spell = 57994, type = "ability", requiresTarget = true}, -- Wind Shear
        { spell = 61882, type = "ability"}, -- Earthquake
        { spell = 73899, type = "ability", requiresTarget = true}, -- Primal Strike
        { spell = 79206, type = "ability", buff = true}, -- Spiritwalker's Grace
        { spell = 108271, type = "ability", buff = true}, -- Astral Shift
        { spell = 108281, type = "ability", buff = true, talent = 14}, -- Ancestral Guidance
        { spell = 114050, type = "ability", buff = true, talent = 21}, -- Ascendance
        { spell = 117014, type = "ability", requiresTarget = true, talent = 6}, -- Elemental Blast
        { spell = 188196, type = "ability", requiresTarget = true}, -- Lightning Bolt
        { spell = 188389, type = "ability", debuff = true, requiresTarget = true}, -- Flame Shock
        { spell = 188443, type = "ability", requiresTarget = true}, -- Chain Lightning
        { spell = 191634, type = "ability", buff = true, talent = 20}, -- Stormkeeper
        { spell = 192106, type = "ability", buff = true}, -- Lightning Shield
        { spell = 192058, type = "ability", totem = true}, -- Capacitor Totem
        { spell = 192077, type = "ability", totem = true, talent = 15}, -- Wind Rush Totem
        { spell = 192222, type = "ability", totem = true, talent = 12}, -- Liquid Magma Totem
        { spell = 192249, type = "ability", duration = 30, talent = 11}, -- Storm Elemental
        { spell = 196840, type = "ability", debuff = true}, -- Frost Shock
        { spell = 198067, type = "ability", duration = 30}, -- Fire Elemental
        { spell = 198103, type = "ability", duration = 60}, -- Earth Elemental
        { spell = 210714, type = "ability", debuff = true, requiresTarget = true, talent = 18}, -- Icefury
        { spell = 320125, type = "ability", talent = 5}, -- Echoing Shock
        { spell = 342243, type = "ability", talent = 3}, -- Static Discharge
      },
      icon = 135963
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
        { spell = 8178, type="buff", unit = "target", pvptalent = 9, titleSuffix = L["buff"]},-- Grounding Totem
        { spell = 204330, type="ability", totem = true, pvptalent = 3, titleSuffix = L["cooldown"]},-- Skyfury Totem
        { spell = 204331, type="ability", totem = true, pvptalent = 8, titleSuffix = L["cooldown"]},-- Counterstrike Totem
        { spell = 204336, type="ability", totem = true, pvptalent = 9, titleSuffix = L["cooldown"]},-- Grounding Totem
        { spell = 208963, type="buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"]},-- Skyfury Totem
        { spell = 208997, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Counterstrike Totem
        { spell = 236746, type="buff", unit = "player", pvptalent = 5},-- Control of Lava
        { spell = 305483, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Lightning Lasso
        { spell = 305485, type="debuff", unit = "target", pvptalent = 2, titleSuffix = L["debuff"]},-- Lightning Lasso
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 546, type = "buff", unit = "player"}, -- Water Walking
        { spell = 974, type = "buff", unit = "player", talent = 8 }, -- Earth Shield
        { spell = 2645, type = "buff", unit = "player"}, -- Ghost Wolf
        { spell = 6196, type = "buff", unit = "player"}, -- Far Sight
        { spell = 58875, type = "buff", unit = "player"}, -- Spirit Walk
        { spell = 108271, type = "buff", unit = "player"}, -- Astral Shift
        { spell = 114051, type = "buff", unit = "player", talent = 21 }, -- Ascendance
        { spell = 118522, type = "buff", unit = "player", talent = 3 }, -- Elemental Blast: Crit
        { spell = 173183, type = "buff", unit = "player", talent = 3 }, -- Elemental Blast: Haste
        { spell = 173184, type = "buff", unit = "player", talent = 3 }, -- Elemental Blast: Mastery
        { spell = 187878, type = "buff", unit = "player"}, -- Crash Lightning
        { spell = 192082, type = "buff", unit = "player", talent = 15 }, -- Wind Rush
        { spell = 192106, type = "buff", unit = "player", talent = 3 }, -- Lightning Shield
        { spell = 196834, type = "buff", unit = "player"}, -- Frostbrand
        { spell = 197211, type = "buff", unit = "player", talent = 17 }, -- Fury of Air
        { spell = 198300, type = "buff", unit = "player"}, -- Gathering Storms
        { spell = 201846, type = "buff", unit = "player"}, -- Stormbringer
        { spell = 202004, type = "buff", unit = "player", talent = 4 }, -- Landslide
        { spell = 215785, type = "buff", unit = "player", talent = 5 }, -- Hot Hand
        { spell = 224125, type = "buff", unit = "player", talent = 19 }, -- Molten Weapon
        { spell = 224126, type = "buff", unit = "player", talent = 19 }, -- Icy Edge
        { spell = 224127, type = "buff", unit = "player", talent = 19 }, -- Crackling Surge
        { spell = 260881, type = "buff", unit = "player", talent = 7 }, -- Spirit Wolf
        { spell = 262397, type = "buff", unit = "player", talent = 6 }, -- Storm Totem
        { spell = 262399, type = "buff", unit = "player", talent = 6 }, -- Ember Totem
        { spell = 262652, type = "buff", unit = "player", talent = 2 }, -- Forceful Winds
        { spell = 262400, type = "buff", unit = "player", talent = 6 }, -- Tailwind Totem
        { spell = 262417, type = "buff", unit = "player", talent = 6 }, -- Resonance Totem
        { spell = 273323, type = "buff", unit = "player", talent = 3 }, -- Lightning Shield Overcharge
        { spell = 320137, type = "buff", unit = "player" }, -- Stormkeeper
        { spell = 344179, type = "buff", unit = "player" }, -- Maelstrom Weapon
        { spell = 334196, type = "buff", unit = "player", talent = 11 }, -- Hailstorm

        -- Enchant
        { spell = 33757, type = "weaponenchant", enchant = 5401, weapon = "main"}, -- Windfury Weapon


        { spell = 318038, type = "weaponenchant", enchant = 5400, weapon = "off"}, -- Flametongue Weapon

      },
      icon = 136099
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3600, type = "debuff", unit = "target"}, -- Earthbind
        { spell = 118905, type = "debuff", unit = "target"}, -- Static Charge
        { spell = 147732, type = "debuff", unit = "target"}, -- Frostbrand
        { spell = 188089, type = "debuff", unit = "target", talent = 20 }, -- Earthen Spike
        { spell = 197214, type = "debuff", unit = "target", talent = 18 }, -- Sundering
        { spell = 197385, type = "debuff", unit = "target", talent = 17 }, -- Fury of Air
        { spell = 268429, type = "debuff", unit = "target", talent = 10 }, -- Searing Assault
        { spell = 271924, type = "debuff", unit = "target", talent = 19 }, -- Molten Weapon
        { spell = 334046, type = "debuff", unit = "target", talent = 1}, -- Lashing Flames
      },
      icon = 462327
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 370, type = "ability"}, -- Purge
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 974, type = "ability", talent = 8}, -- Earth Shield
        { spell = 1064, type = "ability"}, -- Chain Heal
        { spell = 2008, type = "ability"}, -- Ancestral Spirit
        { spell = 2484, type = "ability", totem = true}, -- Earthbind Totem
        { spell = 2645, type = "ability"}, -- Ghost Wolf
        { spell = 2825, type = "ability", buff = true}, -- Bloodlust
        { spell = 5394, type = "ability", totem = true}, -- Healing Stream Totem
        { spell = 6196, type = "ability"}, -- Far Sight
        { spell = 8004, type = "ability"}, -- Healing Surge
        { spell = 8143, type = "ability", totem = true}, -- Tremor Totem
        { spell = 8512, type = "ability", totem = true}, -- Windfury Totem
        { spell = 17364, type = "ability", requiresTarget = true, overlayGlow = true}, -- Stormstrike
        { spell = 32182, type = "ability"}, -- Heroism
        { spell = 51514, type = "ability", requiresTarget = true}, -- Hex
        { spell = 51533, type = "ability", duration = 15}, -- Feral Spirit
        { spell = 51886, type = "ability"}, -- Cleanse Spirit
        { spell = 57994, type = "ability", requiresTarget = true}, -- Wind Shear
        { spell = 58875, type = "ability", buff = true}, -- Spirit Walk
        { spell = 60103, type = "ability"}, -- Lava Lash
        { spell = 73899, type = "ability"}, -- Stormstrike
        { spell = 108271, type = "ability", buff = true}, -- Astral Shift
        { spell = 114051, type = "ability", buff = true, talent = 21 }, -- Ascendance
        { spell = 115356, type = "ability", talent = 21 }, -- Windstrike
        { spell = 117014, type = "ability", talent = 3 }, -- Elemental Blast
        { spell = 188196, type = "ability"}, -- Lightning Bolt
        { spell = 187874, type = "ability"}, -- Crash Lightning
        { spell = 188089, type = "ability", debuff = true, requiresTarget = true, talent = 20 }, -- Earthen Spike
        { spell = 188389, type = "ability", debuff = true, requiresTarget = true}, -- Flame Shock
        { spell = 188443, type = "ability", requiresTarget = true}, -- Chain Lightning
        { spell = 192106, type = "ability", buff = true}, -- Lightning Shield
        { spell = 192058, type = "ability", totem = true}, -- Capacitor Totem
        { spell = 192077, type = "ability", totem = true, talent = 15 }, -- Wind Rush Totem
        { spell = 193786, type = "ability", charges = true, requiresTarget = true}, -- Rockbiter
        { spell = 193796, type = "ability", buff = true, requiresTarget = true}, -- Flametongue
        { spell = 196884, type = "ability", requiresTarget = true, talent = 14 }, -- Feral Lunge
        { spell = 197214, type = "ability", talent = 18 }, -- Sundering
        { spell = 198103, type = "ability", duration = 60 }, -- Earth Elemental
        { spell = 196840, type = "ability" }, -- Frost Shock
        { spell = 196884, type = "ability", talent = 14 }, -- Feral Lunge
        { spell = 320137, type = "ability", buff = true, talent = 17 }, -- Stormkeeper
        { spell = 333974, type = "ability", talent = 12 }, -- Fire Nova
        { spell = 342240, type = "ability", talent = 6 }, -- Ice Strike
      },
      icon = 1370984
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
        { spell = 8178, type="buff", unit = "player", pvptalent = 1, titleSuffix = L["debuff"]},-- Grounding Totem
        { spell = 204330, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Skyfury Totem
        { spell = 204331, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Counterstrike Totem
        { spell = 204336, type="ability", pvptalent = 1, titleSuffix = L["cooldown"]},-- Grounding Totem
        { spell = 204366, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Thundercharge
        { spell = 204366, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Thundercharge
        { spell = 208963, type="buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"]},-- Skyfury Totem
        { spell = 208997, type="debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]},-- Counterstrike Totem
        { spell = 210918, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Ethereal Form
        { spell = 210918, type="buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- Ethereal Form
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 546, type = "buff", unit = "player"}, -- Water Walking
        { spell = 974, type = "buff", unit = "group", talent = 6 }, -- Earth Shield
        { spell = 2645, type = "buff", unit = "player"}, -- Ghost Wolf
        { spell = 6196, type = "buff", unit = "player"}, -- Far Sight
        { spell = 53390, type = "buff", unit = "player"}, -- Tidal Waves
        { spell = 61295, type = "buff", unit = "target"}, -- Riptide
        { spell = 73685, type = "buff", unit = "player", talent = 3 }, -- Unleash Life
        { spell = 73920, type = "buff", unit = "player"}, -- Healing Rain
        { spell = 77762, type = "buff", unit = "player"}, -- Lava Surge
        { spell = 79206, type = "buff", unit = "player"}, -- Spiritwalker's Grace
        { spell = 98007, type = "buff", unit = "player"}, -- Spirit Link Totem
        { spell = 108271, type = "buff", unit = "player"}, -- Astral Shift
        { spell = 114052, type = "buff", unit = "player", talent = 21 }, -- Ascendance
        { spell = 157504, type = "buff", unit = "player", talent = 18 }, -- Cloudburst Totem
        { spell = 201633, type = "buff", unit = "player", talent = 11 }, -- Earthen Wall
        { spell = 207400, type = "buff", unit = "target", talent = 10 }, -- Ancestral Vigor
        { spell = 207498, type = "buff", unit = "player", talent = 12 }, -- Ancestral Protection
        { spell = 216251, type = "buff", unit = "player", talent = 2 }, -- Undulation
        { spell = 260881, type = "buff", unit = "player", talent = 7 }, -- Spirit Wolf
        { spell = 280615, type = "buff", unit = "player", talent = 16 }, -- Flash Flood

        -- Enchant
        { spell = 318038, type = "weaponenchant", enchant = 5400, weapon = "main"}, -- Flametongue Weapon
      },
      icon = 252995
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3600, type = "debuff", unit = "target"}, -- Earthbind
        { spell = 64695, type = "debuff", unit = "target", talent = 8 }, -- Earthgrab
        { spell = 118905, type = "debuff", unit = "target"}, -- Static Charge
        { spell = 188389, type = "debuff", unit = "target"}, -- Flame Shock
      },
      icon = 135813
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 2484, type = "ability", totem = true}, -- Earthbind Totem
        { spell = 2825, type = "ability", buff = true}, -- Bloodlust
        { spell = 5394, type = "ability", totem = true, talent = {5,6}}, -- Healing Stream Totem
        { spell = 5394, type = "ability", charges = true, totem = true, talent = 4, titleSuffix = " (2 Charges)"}, -- Healing Stream Totem
        { spell = 8143, type = "ability", totem = true}, -- Tremor Totem
        { spell = 32182, type = "ability", buff = true}, -- Heroism
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
        { spell = 188389, type = "ability", debuff = true, requiresTarget = true}, -- Flame Shock
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
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {
      title = L["PvP Talents"],
      args = {
        { spell = 8178, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Grounding Totem
        { spell = 204293, type="buff", unit = "target", pvptalent = 6},-- Spirit Link
        { spell = 204330, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Skyfury Totem
        { spell = 204331, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Counterstrike Totem
        { spell = 204336, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Grounding Totem
        { spell = 206647, type="debuff", unit = "target", pvptalent = 5},-- Electrocute
        { spell = 208963, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Skyfury Totem
        { spell = 208997, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Counterstrike Totem
        { spell = 236502, type="buff", unit = "player", pvptalent = 7},-- Tidebringer
        { spell = 290254, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Ancestral Gift
        { spell = 290641, type="buff", unit = "player", pvptalent = 4, titleSuffix = L["buff"]},-- Ancestral Gift
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
}

templates.class.MAGE = {
  [1] = { -- Arcane
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 130, type = "buff", unit = "player"}, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil}, -- Arcane Intellect
        { spell = 12042, type = "buff", unit = "player"}, -- Arcane Power
        { spell = 12051, type = "buff", unit = "player"}, -- Evocation
        { spell = 45438, type = "buff", unit = "player"}, -- Ice Block
        { spell = 110960, type = "buff", unit = "player"}, -- Greater Invisibility
        { spell = 116014, type = "buff", unit = "player", talent = 9 }, -- Rune of Power
        { spell = 116267, type = "buff", unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 205025, type =  "buff", unit = "player"}, -- Presence of Mind
        { spell = 210126, type = "buff", unit = "player", talent = 3 }, -- Arcane Familiar
        { spell = 212799, type = "buff", unit = "player"}, -- Displacement Beacon
        { spell = 236298, type = "buff", unit = "player", talent = 13 }, -- Chrono Shift
        { spell = 263725, type = "buff", unit = "player"}, -- Clearcasting
        { spell = 235450, type = "buff", unit = "player"}, -- Prismatic Barrier
        { spell = 264774, type = "buff", unit = "player", talent = 2 }, -- Rule of Threes
        { spell = 342246, type = "buff", unit = "player"}, -- Alter Time
        { spell = 321358, type = "buff", unit = "group", titleSuffix = L["Buff on Other"]}, -- Focus Magic
        { spell = 321388, type = "buff", unit = "player", talent = 21, titleSuffix = L[">70% Mana"]}, -- Enlightened
        { spell = 321390, type = "buff", unit = "player", talent = 21, titleSuffix = L["<70% Mana"]}, -- Enlightened
      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
        { spell = 122, type = "debuff", unit = "target"}, -- Frost Nova
        { spell = 31589, type = "debuff", unit = "target"}, -- Slow
        { spell = 41425, type = "debuff", unit = "player"}, -- Hypothermia
        { spell = 82691, type = "debuff", unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 114923, type = "debuff", unit = "target", talent = 12 }, -- Nether Tempest
        { spell = 205708, type = "debuff", unit = "target"}, -- Chilled
        { spell = 210824, type = "debuff", unit = "target"}, -- Touch of the Magi
        { spell = 236299, type = "debuff", unit = "target", talent = 13 }, -- Chrono Shift
      },
      icon = 135848
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 66, type = "ability"}, -- Greater Invisibility
        { spell = 116, type = "ability"}, -- Frostbolt
        { spell = 118, type = "ability"}, -- Polymorph
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1449, type = "ability", overlayGlow = true}, -- Arcane Explosion
        { spell = 1459, type = "ability"}, -- Arcane Intellect
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability", requiresTarget = true}, -- Counterspell
        { spell = 5143, type = "ability", requiresTarget = true, overlayGlow = true}, -- Arcane Missiles
        { spell = 12042, type = "ability", buff = true}, -- Arcane Power
        { spell = 12051, type = "ability", buff = true}, -- Evocation
        { spell = 30449, type = "ability"}, -- Spellsteal
        { spell = 30451, type = "ability"}, -- Arcane Blast
        { spell = 31589, type = "ability"}, -- Slow
        { spell = 44425, type =  "ability", requiresTarget = true}, -- Arcane Barrage
        { spell = 45438, type = "ability", buff = true}, -- Ice Block
        { spell = 55342, type = "ability"}, -- Mirror Image
        { spell = 80353, type = "ability", buff = true}, -- Time Warp
        { spell = 110959, type = "ability", buff = true}, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 15 }, -- Ring of Frost
        { spell = 114923, type = "ability", talent = 12 }, -- Nether Tempest
        { spell = 116011, type = "ability", charges = true, buff = true, talent = 9 }, -- Rune of Power
        { spell = 153626, type = "ability", talent = 17 }, -- Arcane Orb
        { spell = 157980, type = "ability", requiresTarget = true, talent = 18 }, -- Supernova
        { spell = 190336, type = "ability"}, -- Conjure Refreshment
        { spell = 195676, type = "ability", usable = true}, -- Displacement
        { spell = 205022, type = "ability", talent = 3 }, -- Arcane Familiar
        { spell = 205025, type = "ability", buff = true}, -- Presence of Mind
        { spell = 205032, type = "ability", talent = 11 }, -- Charged Up
        { spell = 212653, type = "ability", charges = true, talent = 5 }, -- Shimmer
        { spell = 235450, type = "ability", buff = true}, -- Prismatic Barrier
        { spell = 319836, type = "ability"}, -- Fire Blast
        { spell = 321507, type = "ability", debuff = true}, -- Touch of the Magi
        { spell = 342245, type = "ability", buff = true}, -- Alter Time
      },
      icon = 136075
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
        { spell = 198111, type="ability", pvptalent = 1, titleSuffix = L["cooldown"]},-- Temporal Shield
        { spell = 198111, type="buff", unit = "player", pvptalent = 1, titleSuffix = L["buff"]},-- Temporal Shield
        { spell = 198065, type="buff", unit = "player", pvptalent = 9},-- Prismatic Cloak
        { spell = 198158, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Mass Invisibility
        { spell = 198158, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Mass Invisibility
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 66, type = "buff", unit = "player"}, -- Invisibility
        { spell = 130, type = "buff", unit = "player"}, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Arcane Intellect
        { spell = 45438, type = "buff", unit = "player"}, -- Ice Block
        { spell = 45444, type = "buff", unit = "player"}, -- Bonfire's Blessing
        { spell = 48107, type = "buff", unit = "player"}, -- Heating Up
        { spell = 48108, type = "buff", unit = "player"}, -- Hot Streak!
        { spell = 110909, type = "buff", unit = "player"}, -- Alter Time
        { spell = 116014, type = "buff", unit = "player", talent = 9 }, -- Rune of Power
        { spell = 116267, type = "buff", unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 157644, type = "buff", unit = "player"}, -- Enhanced Pyrotechnics
        { spell = 190319, type = "buff", unit = "player"}, -- Combustion
        { spell = 236060, type = "buff", unit = "player", talent = 13 }, -- Frenetic Speed
        { spell = 269651, type = "buff", unit = "player", talent = 20 }, -- Pyroclasm
        { spell = 235313, type = "buff", unit = "player"}, -- Blazing Barrier
        { spell = 321358, type = "buff", unit = "group", titleSuffix = L["Buff on Other"]}, -- Focus Magic
      },
      icon = 1035045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
        { spell = 122, type = "debuff", unit = "multi" }, -- Frost Nova
        { spell = 2120, type = "debuff", unit = "target"}, -- Flamestrike
        { spell = 12654, type = "debuff", unit = "target"}, -- Ignite
        { spell = 31661, type = "debuff", unit = "target"}, -- Dragon's Breath
        { spell = 41425, type = "debuff", unit = "player"}, -- Hypothermia
        { spell = 82691, type = "debuff", unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 87023, type = "debuff", unit = "player" }, -- Cauterize
        { spell = 87024, type = "debuff", unit = "player" }, -- Cauterized
        { spell = 155158, type = "debuff", unit = "target", talent = 21 }, -- Meteor Burn
        { spell = 157981, type = "debuff", unit = "target", talent = 6 }, -- Blast Wave
        { spell = 205708, type = "debuff", unit = "target" }, -- Chilled
        { spell = 217694, type = "debuff", unit = "target", talent = 18 }, -- Living Bomb
        { spell = 226757, type = "debuff", unit = "target", talent = 17 }, -- Conflagration
      },
      icon = 135818
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 66, type = "ability", buff = true}, -- Invisibility
        { spell = 116, type = "ability"}, -- Frostbolt
        { spell = 118, type = "ability"}, -- Polymorph
        { spell = 122, type = "ability", debuff = true}, -- Frost Nova
        { spell = 133, type = "ability"}, -- Fireball
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1449, type = "ability"}, -- Arcane Explosion
        { spell = 1459, type = "ability"}, -- Arcane Intellect
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2120, type = "ability", overlayGlow = true}, -- Flamestrike
        { spell = 2139, type = "ability", requiresTarget = true}, -- Counterspell
        { spell = 2948, type = "ability", requiresTarget = true}, -- Scorch
        { spell = 11366, type = "ability", requiresTarget = true, overlayGlow = true}, -- Pyroblast
        { spell = 30449, type = "ability"}, -- Spealsteal
        { spell = 31661, type = "ability"}, -- Dragon's Breath
        { spell = 44457, type = "ability", debuff = true, requiresTarget = true, talent = 18 }, -- Living Bomb
        { spell = 45438, type = "ability", buff = true}, -- Ice Block
        { spell = 55342, type = "ability" }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true}, -- Time Warp
        { spell = 108978, type = "ability", buff = true}, -- Alter Time
        { spell = 108853, type = "ability", charges = true}, -- Fire Blast
        { spell = 113724, type = "ability", talent = 15 }, -- Ring of Frost
        { spell = 116011, type = "ability", charges = true, buff = true, talent = 9 }, -- Rune of Power
        { spell = 153561, type = "ability", talent = 21 }, -- Meteor
        { spell = 157981, type = "ability", talent = 6 }, -- Blast Wave
        { spell = 190319, type = "ability", buff = true}, -- Combustion
        { spell = 190336, type = "ability"}, -- Conjure Refreshment
        { spell = 212653, type = "ability", charges = true, talent = 5 }, -- Shimmer
        { spell = 235313, type = "ability", buff = true}, -- Blazing Barrier
        { spell = 257541, type = "ability", charges = true }, -- Phoenix Flames
        { spell = 319836, type = "ability", charges = true }, -- Fire Blast
      },
      icon = 610633
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
        { spell = 198065, type="buff", unit = "player", pvptalent = 2},-- Prismatic Cloak
        { spell = 203285, type="buff", unit = "target", pvptalent = 6},-- Flamecannon
        { spell = 203277, type="buff", unit = "player", pvptalent = 10},-- Tinder
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
  [3] = { -- Frost
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 66, type = "buff", unit = "player"}, -- Invisibility
        { spell = 130, type = "buff", unit = "player"}, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player", forceOwnOnly = true, ownOnly = nil }, -- Arcane Intellect
        { spell = 11426, type = "buff", unit = "player"}, -- Ice Barrier
        { spell = 12472, type = "buff", unit = "player"}, -- Icy Veins
        { spell = 44544, type = "buff", unit = "player"}, -- Fingers of Frost
        { spell = 45438, type = "buff", unit = "player"}, -- Ice Block
        { spell = 108839, type = "buff", unit = "player", talent = 6 }, -- Ice Floes
        { spell = 110909, type = "buff", unit = "player" }, -- Alter Time
        { spell = 116014, type = "buff", unit = "player", talent = 9 }, -- Rune of Power
        { spell = 116267, type = "buff", unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 190446, type = "buff", unit = "player"}, -- Brain Freeze
        { spell = 199844, type = "buff", unit = "player", talent = 21 }, -- Glacial Spike!
        { spell = 205473, type = "buff", unit = "player"}, -- Icicles
        { spell = 205766, type = "buff", unit = "player", talent = 1 }, -- Bone Chilling
        { spell = 270232, type = "buff", unit = "player", talent = 16 }, -- Freezing Rain
        { spell = 278310, type = "buff", unit = "player", talent = 11 }, -- Chain Reaction
        { spell = 321358, type = "buff", unit = "group", titleSuffix = L["Buff on Other"]}, -- Focus Magic
      },
      icon = 236227
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
        { spell = 122, type = "debuff", unit = "target"}, -- Frost Nova
        { spell = 12486, type = "debuff", unit = "target"}, -- Blizzard
        { spell = 41425, type = "debuff", unit = "player"}, -- Hypothermia
        { spell = 82691, type = "debuff", unit = "target", talent = 15 }, -- Ring of Frost
        { spell = 157997, type = "debuff", unit = "target", talent = 3 }, -- Ice Nova
        { spell = 205021, type = "debuff", unit = "target", talent = 20 }, -- Ray of Frost
        { spell = 205708, type = "debuff", unit = "target"}, -- Chilled
        { spell = 212792, type = "debuff", unit = "target"}, -- Cone of Cold
        { spell = 228354, type = "debuff", unit = "target"}, -- Flurry
        { spell = 228358, type = "debuff", unit = "target"}, -- Winter's Chill
        { spell = 228600, type = "debuff", unit = "target", talent = 21 }, -- Glacial Spike
      },
      icon = 236208
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 66, type = "ability", buff = true}, -- Invisibility
        { spell = 116, type = "ability"}, -- Frostbolt
        { spell = 118, type = "ability"}, -- Polymorph
        { spell = 120, type = "ability"}, -- Cone of Cold
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1449, type = "ability"}, -- Arcane Explosion
        { spell = 1459, type = "ability"}, -- Arcane Intellect
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability", requiresTarget = true}, -- Counterspell
        { spell = 11426, type = "ability", buff = true}, -- Ice Barrier
        { spell = 12472, type = "ability", buff = true}, -- Icy Veins
        { spell = 30455, type = "ability", requiresTarget = true}, -- Ice Lance
        { spell = 30449, type = "ability", requiresTarget = true}, -- Spellsteal
        { spell = 31687, type = "ability"}, -- Summon Water Elemental
        { spell = 31707, type = "ability"}, -- Waterbolt
        { spell = 31687, type = "ability"}, -- Summon Water Elemental
        { spell = 44614, type = "ability"}, -- Flurry
        { spell = 45438, type = "ability", buff = true}, -- Ice Block
        { spell = 55342, type = "ability"}, -- Mirror Image
        { spell = 80353, type = "ability", buff = true}, -- Time Warp
        { spell = 84714, type = "ability"}, -- Frozen Orb
        { spell = 108839, type = "ability", charges = true, buff = true, talent = 6 }, -- Ice Floes
        { spell = 108978, type = "ability", buff = true }, -- Alter Time
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
        { spell = 319836, type = "ability", requiresTarget = true }, -- Fire Blast
      },
      icon = 629077
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
        { spell = 198065, type="buff", unit = "player", pvptalent = 7},-- Prismatic Cloak
        { spell = 198144, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Ice Form
        { spell = 198144, type="buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]},-- Ice Form
        { spell = 198121, type="debuff", unit = "target", pvptalent = 4},-- Frostbite
        { spell = 206432, type="buff", unit = "player", pvptalent = 10},-- Burst of Cold
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
}

templates.class.WARLOCK = {
  [1] = { -- Affliction
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 126, type = "buff", unit = "player"}, -- Eye of Kilrogg
        { spell = 755, type = "buff", unit = "pet"}, -- Health Funnel
        { spell = 5697, type = "buff", unit = "player"}, -- Unending Breath
        { spell = 7870, type = "buff", unit = "pet"}, -- Lesser Invisibility
        { spell = 17767, type = "buff", unit = "pet"}, -- Shadow Bulwark
        { spell = 20707, type = "buff", unit = "group"}, -- Soulstone
        { spell = 48018, type = "buff", unit = "player"}, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player"}, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player"}, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 9 }, -- Dark Pact
        { spell = 112042, type = "buff", unit = "pet"}, -- Threatening Presence
        { spell = 113860, type = "buff", unit = "player", talent = 21 }, -- Dark Soul: Misery
        { spell = 111400, type = "buff", unit = "player", talent = 8 }, -- Burning Rush
        { spell = 196099, type = "buff", unit = "player", talent = 18 }, -- Grimoire of Sacrifice
        { spell = 264571, type = "buff", unit = "player", talent = 1 }, -- Nightfall
        { spell = 334320, type = "buff", unit = "player", talent = 2 }, -- Inevitable Demise
      },
      icon = 136210
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 702, type = "debuff", unit = "target"}, -- Curse of Weakness
        { spell = 710, type = "debuff", unit = "multi"}, -- Banish
        { spell = 980, type = "debuff", unit = "target"}, -- Agony
        { spell = 1098, type = "debuff", unit = "multi"}, -- Enslave Demon
        { spell = 1714, type = "debuff", unit = "target"}, -- Curse of Tongues
        { spell = 6358, type = "debuff", unit = "target"}, -- Seduction
        { spell = 6360, type = "debuff", unit = "target"}, -- Whiplash
        { spell = 6789, type = "debuff", unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target"}, -- Suffering
        { spell = 27243, type = "debuff", unit = "target"}, -- Seed of Corruption
        { spell = 30283, type = "debuff", unit = "target"}, -- Shadowfury
        { spell = 48181, type = "debuff", unit = "target", talent = 17 }, -- Haunt
        { spell = 63106, type = "debuff", unit = "target", talent = 6 }, -- Siphon Life
        { spell = 118699, type = "debuff", unit = "target"}, -- Fear
        { spell = 146739, type = "debuff", unit = "target"}, -- Corruption
        { spell = 198590, type = "debuff", unit = "target", talent = 2 }, -- Drain Soul
        { spell = 205179, type = "debuff", unit = "target", talent = 11 }, -- Phantom Singularity
        { spell = 234153, type = "debuff", unit = "target"}, -- Drain Life
        { spell = 233490, type = "debuff", unit = "target"}, -- Unstable Affliction
        { spell = 278350, type = "debuff", unit = "target", talent = 12 }, -- Vile Taint
        { spell = 334275, type = "debuff", unit = "target"}, -- Curse of Exhaustion
      },
      icon = 136139
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 126, type = "ability"}, -- Eye of Kilrogg
        { spell = 172, type = "ability", requiresTarget = true, debuff = true}, -- Corruption
        { spell = 686, type = "ability", requiresTarget = true}, -- Shadow Bolt
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 702, type = "ability", requiresTarget = true, debuff = true}, -- Curse of Weakness
        { spell = 710, type = "ability", requiresTarget = true, debuff = true}, -- Banish
        { spell = 755, type = "ability"}, -- Health Funnel
        { spell = 980, type = "ability", requiresTarget = true, debuff = true}, -- Agony
        { spell = 1714, type = "ability", requiresTarget = true, debuff = true}, -- Curse of Tongues
        { spell = 3110, type = "ability", requiresTarget = true}, -- Firebolt
        { spell = 3716, type = "ability", requiresTarget = true}, -- Consuming Shadows
        { spell = 5484, type = "ability"}, -- Howl of Terror
        { spell = 5782, type = "ability", requiresTarget = true, debuff = true}, -- Fear
        { spell = 6358, type = "ability", requiresTarget = true}, -- Seduction
        { spell = 6360, type = "ability", requiresTarget = true}, -- Whiplash
        { spell = 6789, type = "ability", requiresTarget = true, talent = 14 }, -- Mortal Coil
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
        { spell = 48018, type = "ability"}, -- Demonic Circle
        { spell = 48020, type = "ability", usable = true }, -- Demonic Circle: Teleport
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
        { spell = 119910, type = "ability", requiresTarget = true}, -- Command Demon
        { spell = 198590, type = "ability", requiresTarget = true}, -- Drain Soul
        { spell = 205179, type = "ability", requiresTarget = true, debuff = true, talent = 11 }, -- Phantom Singularity
        { spell = 205180, type = "ability", totem = true}, -- Summon Darkglare
        { spell = 232670, type = "ability", requiresTarget = true, overlayGlow = true}, -- Shadow Bolt
        { spell = 234153, type = "ability", requiresTarget = true}, -- Drain Life
        { spell = 264106, type = "ability", requiresTarget = true, talent = 3 }, -- Deathbolt
        { spell = 264993, type = "ability"}, -- Shadow Shield
        { spell = 278350, type = "ability", requiresTarget = true, talent = 12 }, -- Vile Taint
        { spell = 316099, type = "ability", requiresTarget = true }, -- Unstable Affliction
        { spell = 333889, type = "ability" }, -- Fel Domination
        { spell = 334275, type = "ability", debuff = true, requiresTarget = true }, -- Curse of Exhaustion
        { spell = 342601, type = "ability" }, -- Ritual of Doom
        { spell = 324536, type = "ability" }, -- Malefic Rapture
      },
      icon = 135808
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
        { spell = 199954, type="ability", debuff = true, pvptalent = 9, titleSuffix = L["cooldown"]},-- Bane of Fragility
        { spell = 199954, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"]},-- Bane of Fragility
        { spell = 212295, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Nether Ward
        { spell = 212295, type="buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"]},-- Nether Ward
        { spell = 212356, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Soulshatter
        { spell = 221703, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Casting Circle
        { spell = 221705, type="buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"]},-- Casting Circle
        { spell = 221715, type="debuff", unit = "target", pvptalent = 6},-- Essence Drain
        { spell = 264106, type="ability", pvptalent = 4},-- Deathbolt
        { spell = 285933, type="buff", unit = "player", pvptalent = 13},-- Demon Armor
        { spell = 234877, type="ability", pvptalent = 4},-- Bane of Shadows
        { spell = 328774, type="ability", buff = true, pvptalent = 8},-- Amplify Curse
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 126, type = "buff", unit = "player"}, -- Eye of Kilrogg
        { spell = 755, type = "buff", unit = "pet"}, -- Health Funnel
        { spell = 5697, type = "buff", unit = "player"}, -- Unending Breath
        { spell = 17767, type = "buff", unit = "pet"}, -- Shadow Bulwark
        { spell = 20707, type = "buff", unit = "group"}, -- Soulstone
        { spell = 30151, type = "buff", unit = "pet"}, -- Pursuit
        { spell = 48018, type = "buff", unit = "player"}, -- Demonic Circle
        { spell = 89751, type = "buff", unit = "pet"}, -- Felstorm
        { spell = 104773, type = "buff", unit = "player"}, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player"}, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 9 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 8 }, -- Burning Rush
        { spell = 134477, type = "buff", unit = "pet"}, -- Threatening Presence
        { spell = 205146, type = "buff", unit = "player", talent = 4 }, -- Demonic Calling
        { spell = 265273, type = "buff", unit = "player"}, -- Demonic Power
        { spell = 267218, type = "buff", unit = "player", talent = 21 }, -- Nether Portal
        { spell = 264173, type = "buff", unit = "player"}, -- Demonic Core
        { spell = 267171, type = "buff", unit = "pet", talent = 3 }, -- Demonic Strength
      },
      icon = 1378284
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 603, type = "debuff", unit = "target"}, -- Doom
        { spell = 702, type = "debuff", unit = "target"}, -- Curse of Weakness
        { spell = 710, type = "debuff", unit = "multi"}, -- Banish
        { spell = 1098, type = "debuff", unit = "multi"}, -- Enslave Demon
        { spell = 1714, type = "debuff", unit = "target"}, -- Curse of Tongues
        { spell = 6358, type = "debuff", unit = "target"}, -- Seduction
        { spell = 6360, type = "debuff", unit = "target"}, -- Whiplash
        { spell = 6789, type = "debuff", unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target"}, -- Suffering
        { spell = 30213, type = "debuff", unit = "target"}, -- Legion Strike
        { spell = 30283, type = "debuff", unit = "target"}, -- Shadowfury
        { spell = 89766, type = "debuff", unit = "target"}, -- Axe Toss
        { spell = 118699, type = "debuff", unit = "target"}, -- Fear
        { spell = 146739, type = "debuff", unit = "target"}, -- Corruption
        { spell = 267997, type = "debuff", unit = "target", talent = 2 }, -- Bile Spit
        { spell = 270569, type = "debuff", unit = "target", talent = 10 }, -- From the Shadows
        { spell = 234153, type = "debuff", unit = "target"}, -- Drain Life
        { spell = 265412, type = "debuff", unit = "target", talent = 6 }, -- Doom
        { spell = 334275, type = "debuff", unit = "target"}, -- Curse of Exhaustion
      },
      icon = 136122
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 126, type = "ability" }, -- Eyew of Kilrogg
        { spell = 172, type = "ability" }, -- Corruption
        { spell = 603, type = "ability", requiresTarget = true, debuff = true, talent = 6}, -- Doom
        { spell = 686, type = "ability", requiresTarget = true}, -- Shadow Bolt
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 702, type = "ability", requiresTarget = true, debuff = true}, -- Curse of Weakness
        { spell = 710, type = "ability", requiresTarget = true, debuff = true}, -- Banish
        { spell = 755, type = "ability"}, -- Health Funnel
        { spell = 1098, type = "ability"}, -- Subjugate Demon
        { spell = 1714, type = "ability", requiresTarget = true, debuff = true}, -- Curse of Tongues
        { spell = 3716, type = "ability", requiresTarget = true}, -- Consuming Shadows
        { spell = 5484, type = "ability", debuff = true, talent = 15}, -- Howl of Terror
        { spell = 5782, type = "ability", requiresTarget = true, debuff = true}, -- Fear
        { spell = 6358, type = "ability", requiresTarget = true}, -- Seduction
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
        { spell = 48018, type = "ability" }, -- Demonic Circle
        { spell = 48020, type = "ability" }, -- Demonic Circle: Teleport
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
        { spell = 119898, type = "ability" }, -- Command Demon
        { spell = 196277, type = "ability" }, -- Implosion
        { spell = 234153, type = "ability", requiresTarget = true }, -- Drain Life
        { spell = 264057, type = "ability", requiresTarget = true, talent = 11 }, -- Soul Strike
        { spell = 264119, type = "ability", talent = 12 }, -- Summon Vilefiend
        { spell = 264130, type = "ability", usable = true, talent = 5 }, -- Power Siphon
        { spell = 264178, type = "ability", requiresTarget = true, overlayGlow = true}, -- Demonbolt
        { spell = 264993, type = "ability"}, -- Shadow Shield
        { spell = 265187, type = "ability"}, -- Summon Demonic Tyrant
        { spell = 265412, type = "ability", requiresTarget = true, debuff = true, talent = 6}, -- Doom
        { spell = 267171, type = "ability", requiresTarget = true, talent = 3 }, -- Demonic Strength
        { spell = 267211, type = "ability", talent = 2 }, -- Bilescourge Bombers
        { spell = 267217, type = "ability", buff = true, talent = 21 }, -- Nether Portal
        { spell = 333889, type = "ability" }, -- Fel Domination
        { spell = 334275, type = "ability", debuff = true }, -- Curse of Exhaustion
        { spell = 342601, type = "ability" }, -- Ritual of Doom
      },
      icon = 1378282
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
        { spell = 199954, type="ability", debuff = true, pvptalent = 3, titleSuffix = L["cooldown"]},-- Bane of Fragility
        { spell = 199954, type="debuff", unit = "target", pvptalent = 3, titleSuffix = L["debuff"]},-- Bane of Fragility
        { spell = 201996, type="ability", pvptalent = 9},-- Call Observer
        { spell = 212295, type="ability", pvptalent = 12, titleSuffix = L["cooldown"]},-- Nether Ward
        { spell = 212295, type="buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]},-- Nether Ward
        { spell = 212459, type="ability", pvptalent = 2},-- Call Fel Lord
        { spell = 212619, type="ability", pvptalent = 6},-- Call Felhunter
        { spell = 212623, type="ability", pvptalent = 7},-- Singe Magic
        { spell = 221703, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Casting Circle
        { spell = 221705, type="buff", unit = "target", pvptalent = 10, titleSuffix = L["buff"]},-- Casting Circle
        { spell = 221715, type="debuff", unit = "target", pvptalent = 11},-- Essence Drain
        { spell = 328774, type="ability", buff = true, pvptalent = 8},-- Amplify Curse
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 126, type = "buff", unit = "player"}, -- Eye of Kilrogg
        { spell = 755, type = "buff", unit = "pet"}, -- Health Funnel
        { spell = 5697, type = "buff", unit = "player"}, -- Unending Breath
        { spell = 7870, type = "buff", unit = "pet"}, -- Lesser Invisibility
        { spell = 17767, type = "buff", unit = "pet"}, -- Shadow Bulwark
        { spell = 20707, type = "buff", unit = "group"}, -- Soulstone
        { spell = 48018, type = "buff", unit = "player"}, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player"}, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player"}, -- Soul Leech
        { spell = 108366, type = "buff", unit = "pet"}, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 9 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 8 }, -- Burning Rush
        { spell = 112042, type = "buff", unit = "pet"}, -- Threatening Presence
        { spell = 113858, type = "buff", unit = "player", talent = 21 }, -- Dark Soul: Instability
        { spell = 117828, type = "buff", unit = "player"}, -- Backdraft
        { spell = 196099, type = "buff", unit = "player", talent = 18 }, -- Grimoire of Sacrifice
        { spell = 266030, type = "buff", unit = "player", talent = 4 }, -- Reverse Entropy
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 172, type = "debuff", unit = "target"}, -- Coruption
        { spell = 348, type = "debuff", unit = "target"}, -- Immolate
        { spell = 702, type = "debuff", unit = "target"}, -- Curse of Weakness
        { spell = 710, type = "debuff", unit = "multi"}, -- Banish
        { spell = 1714, type = "debuff", unit = "target"}, -- Curse of Tongues
        { spell = 1098, type = "debuff", unit = "multi"}, -- Enslave Demon
        { spell = 5782, type = "debuff", unit = "target"}, -- Fear
        { spell = 6358, type = "debuff", unit = "target"}, -- Seduction
        { spell = 6360, type = "debuff", unit = "target"}, -- Whiplash
        { spell = 6789, type = "debuff", unit = "target", talent = 14 }, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target"}, -- Suffering
        { spell = 22703, type = "debuff", unit = "target"}, -- Infernal Awakening
        { spell = 30283, type = "debuff", unit = "target"}, -- Shadowfury
        { spell = 80240, type = "debuff", unit = "target"}, -- Havoc
        { spell = 118699, type = "debuff", unit = "target"}, -- Fear
        { spell = 157736, type = "debuff", unit = "target"}, -- Immolate
        { spell = 196414, type = "debuff", unit = "target", talent = 2 }, -- Eradication
        { spell = 234153, type = "debuff", unit = "target"}, -- Drain Life
        { spell = 265931, type = "debuff", unit = "target"}, -- Conflagrate
        { spell = 334275, type = "debuff", unit = "target"}, -- Curse of Exhaustion
      },
      icon = 135817
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 126, type = "ability"}, -- Eye of Kilrogg
        { spell = 172, type = "ability", requiresTarget = true, debuff = true}, -- Corruption
        { spell = 348, type = "ability", requiresTarget = true, debuff = true}, -- Immolate
        { spell = 686, type = "ability"}, -- Incinerate
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 702, type = "ability", requiresTarget = true, debuff = true}, -- Curse of Weakness
        { spell = 710, type = "ability", requiresTarget = true, debuff = true}, -- Banish
        { spell = 1098, type = "ability"}, -- Subjugate Demon
        { spell = 1122, type = "ability", duration = 30}, -- Summon Infernal
        { spell = 1714, type = "ability", requiresTarget = true, debuff = true}, -- Curse of Tongues
        { spell = 3110, type = "ability", requiresTarget = true}, -- Firebolt
        { spell = 3716, type = "ability", requiresTarget = true}, -- Consuming Shadows
        { spell = 5484, type = "ability"}, -- Howl of Terror
        { spell = 5740, type = "ability"}, -- Rain of Fire
        { spell = 5782, type = "ability", requiresTarget = true, debuff = true}, -- Fear
        { spell = 6353, type = "ability", talent = 3 }, -- Soul Fire
        { spell = 6358, type = "ability", requiresTarget = true}, -- Seduction
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
        { spell = 48018, type = "ability"}, -- Demonic Circle
        { spell = 48020, type = "ability"}, -- Demonic Circle: Teleport
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
        { spell = 116858, type = "ability" }, -- Chaos Bolt
        { spell = 119898, type = "ability" }, -- Dark Command Demon
        { spell = 152108, type = "ability", talent = 12 }, -- Cataclysm
        { spell = 116858, type = "ability", requiresTarget = true}, -- Chaos Bolt
        { spell = 196447, type = "ability", usable = true, talent = 20 }, -- Channel Demonfire
        { spell = 234153, type = "ability", requiresTarget = true}, -- Drain Life
        { spell = 264993, type = "ability"}, -- Shadow Shield
        { spell = 333889, type = "ability" }, -- Fel Domination
        { spell = 334275, type = "ability", debuff = true, requiresTarget = true }, -- Curse of Exhaustion
      },
      icon = 135807
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
        { spell = 199954, type="ability", debuff = true, pvptalent = 4, titleSuffix = L["cooldown"]},-- Bane of Fragility
        { spell = 199954, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Bane of Fragility
        { spell = 200546, type="ability", pvptalent = 5, titleSuffix = L["cooldown"]},-- Bane of Havoc
        { spell = 200548, type="debuff", unit = "target", pvptalent = 5, titleSuffix = L["debuff"]},-- Bane of Havoc
        { spell = 200587, type="debuff", unit = "target", pvptalent = 10},-- Fel Fissure
        { spell = 212295, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Nether Ward
        { spell = 212295, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Nether Ward
        { spell = 221703, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Casting Circle
        { spell = 221705, type="buff", unit = "target", pvptalent = 8, titleSuffix = L["buff"]},-- Casting Circle
        { spell = 221715, type="debuff", unit = "target", pvptalent = 7},-- Essence Drain
        { spell = 285933, type="buff", unit = "target", pvptalent = 2},-- Demon Armor
        { spell = 328774, type="ability", buff = true, pvptalent = 3},-- Amplify Curse
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 101643, type = "buff", unit = "player"}, -- Transcendence
        { spell = 115176, type = "buff", unit = "player"}, -- Zen Meditation
        { spell = 116841, type = "buff", unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 116847, type = "buff", unit = "player", talent = 17 }, -- Rushing Jade Wind
        { spell = 119085, type = "buff", unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 120954, type = "buff", unit = "player"}, -- Fortifying Brew
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 132578, type = "buff", unit = "player" }, -- Invoke Niuzao, the Black Ox
        { spell = 195630, type = "buff", unit = "player"}, -- Elusive Brawler
        { spell = 196608, type = "buff", unit = "player", talent = 1 }, -- Eye of the Tiger
        { spell = 215479, type = "buff", unit = "player" }, -- Shuffle
        { spell = 228563, type = "buff", unit = "player", talent = 21 }, -- Blackout Combo
        { spell = 325190, type = "buff", unit = "player"}, -- Celestial Flames
      },
      icon = 613398
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target", forceOwnOnly = true, ownOnly = nil}, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "multi"}, -- Paralysis
        { spell = 116189, type = "debuff", unit = "target"}, -- Provoke
        { spell = 117952, type = "debuff", unit = "target"}, -- Crackling Jade Lightning
        { spell = 121253, type = "debuff", unit = "target"}, -- Keg Smash
        { spell = 124273, type = "debuff", unit = "player" }, -- Heavy Stagger
        { spell = 124274, type = "debuff", unit = "player" }, -- Moderate Stagger
        { spell = 124275, type = "debuff", unit = "player" }, -- Light Stagger
        { spell = 119381, type = "debuff", unit = "target"}, -- Leg Sweep
        { spell = 196608, type = "debuff", unit = "target", talent = 1 }, -- Eye of the Tiger
        { spell = 325153, type = "debuff", unit = "target"}, -- Exploding Keg
      },
      icon = 611419
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100780, type = "ability"}, -- Tiger Palm
        { spell = 100784, type = "ability"}, -- Blackout Kick
        { spell = 101546, type = "ability"}, -- Spinning Crane Kick
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 107079, type = "ability"}, -- Quaking Palm
        { spell = 109132, type = "ability", charges = true}, -- Roll
        { spell = 115008, type = "ability", charges = true, talent = 5 }, -- Chi Torpedo
        { spell = 115078, type = "ability", requiresTarget = true}, -- Paralysis
        { spell = 115098, type = "ability", talent = 2 }, -- Chi Wave
        { spell = 115176, type = "ability", buff = true}, -- Zen Meditation
        { spell = 115181, type = "ability", debuff = true, overlayGlow = true}, -- Breath of Fire
        { spell = 115203, type = "ability", buff = true}, -- Fortifying Brew
        { spell = 115315, type = "ability", totem = true, totemNumber = 1, talent = 11 }, -- Summon Black Ox Statue
        { spell = 115399, type = "ability", talent = 9 }, -- Blackw Ox Brew
        { spell = 115546, type = "ability", debuff = true, requiresTarget = true}, -- Provoke
        { spell = 116670, type = "ability"}, -- Vivify
        { spell = 116705, type = "ability"}, -- Spear Hand Strike
        { spell = 116841, type = "ability", talent = 6 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 12 }, -- Ring of Peace
        { spell = 116847, type = "ability", buff = true, talent = 17 }, -- Rushing Jade Wind
        { spell = 117952, type = "ability"}, -- Crackling Jade Lightning
        { spell = 119381, type = "ability"}, -- Leg Sweep
        { spell = 119582, type = "ability", charges = true}, -- Purifying Brew
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 121253, type = "ability", requiresTarget = true, debuff = true}, -- Keg Smash
        { spell = 122278, type = "ability", buff = true, talent = 15 }, -- Dampen Harm
        { spell = 122281, type = "ability", charges = true, buff = true, talent = 14 }, -- Healing Elixir
        { spell = 123986, tyqpe = "ability", talent = 3 }, -- Chi Burst
        { spell = 126892, type = "ability"}, -- Zen Pilgrimage
        { spell = 132578, type = "ability", buff = true, requiresTarget = true }, -- Invoke Niuzao, the Black Ox
        { spell = 205523, type = "ability", requiresTarget = true}, -- Blackout Strike
        { spell = 218164, type = "ability"}, -- Detox
        { spell = 322101, type = "ability"}, -- Expel Harm
        { spell = 322109, type = "ability"}, -- Touch of Death
        { spell = 325153, type = "ability", debuff = true}, -- Exploding Keg
        { spell = 322507, type = "ability", buff = true}, -- Celestial Brew
        { spell = 324312, type = "ability"}, -- Clash

      },
      icon = 133701
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
        { spell = 202335, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Double Barrel
        { spell = 202335, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Double Barrel
        { spell = 202162, type="ability", pvptalent = 1, titleSuffix = L["cooldown"]},-- Avert Harm
        { spell = 202162, type="buff", unit = "group", pvptalent = 1, titleSuffix = L["buff"]},-- Avert Harm
        { spell = 202274, type="debuff", unit = "target", pvptalent = 7},-- Incendiary Breath
        { spell = 202370, type="ability", pvptalent = 9},-- Mighty Ox Kick
        { spell = 206891, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Admonishment
        { spell = 207025, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Admonishment
        { spell = 213658, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Craft: Nimble Brew
        { spell = 213664, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Craft: Nimble Brew
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 101643, type = "buff", unit = "player"}, -- Transcendence
        { spell = 116680, type = "buff", unit = "player"}, -- Thunder Focus Tea
        { spell = 115175, type = "buff", unit = "target"}, -- Soothing Mist
        { spell = 116841, type = "buff", unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 116849, type = "buff", unit = "target"}, -- Life Cocoon
        { spell = 119085, type = "buff", unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 119611, type = "buff", unit = "target"}, -- Renewing Mist
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 122783, type = "buff", unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 124682, type = "buff", unit = "target"}, -- Enveloping Mist
        { spell = 191840, type = "buff", unit = "player"}, -- Essence Font
        { spell = 196725, type = "buff", unit = "player", talent = 17 }, -- Refreshing Jade Wind
        { spell = 197908, type = "buff", unit = "player", talent = 9 }, -- Mana Tea
        { spell = 197916, type = "buff", unit = "player", talent = 7 }, -- Lifecycles (Vivify)
        { spell = 197919, type = "buff", unit = "player", talent = 7 }, -- Lifecycles (Enveloping Mist)
        { spell = 243435, type = "buff", unit = "player"}, -- Fortifying Brew
        { spell = 202090, type = "buff", unit = "player"}, -- Teachings of the Monastery

      },
      icon = 627487
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target", forceOwnOnly = true, ownOnly = nil}, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "multi"}, -- Paralysis
        { spell = 116189, type = "debuff", unit = "target"}, -- Provoke
        { spell = 117952, type = "debuff", unit = "target"}, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target"}, -- Leg Sweep
        { spell = 198909, type = "debuff", unit = "target", talent = 11}, -- Song of Chi-Ji
      },
      icon = 629534
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100780, type = "ability", requiresTarget = true}, -- Tiger Palm
        { spell = 100784, type = "ability", requiresTarget = true}, -- Blackout Kick
        { spell = 101546, type = "ability"}, -- Spinning Crane Kick
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 107079, type = "ability"}, -- Quaking Palm
        { spell = 107428, type = "ability", requiresTarget = true}, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true}, -- Roll
        { spell = 115008, type = "ability", charges = true, talent = 5 }, -- Chi Torpedo
        { spell = 115078, type = "ability", requiresTarget = true}, -- Paralysis
        { spell = 115098, type = "ability", talent = 2 }, -- Chi Wave
        { spell = 115175, type = "ability"}, -- Soothing Mist
        { spell = 115203, type = "ability", buff = true}, -- Fortifying Brew
        { spell = 115151, type = "ability", charges = true, buff = true}, -- Renewing Mist
        { spell = 115310, type = "ability"}, -- Revival
        { spell = 115313, type = "ability", totem = true, totemNumber = 1, talent = 16 }, -- Summon Jade Serpent Statue
        { spell = 115540, type = "ability"}, -- Detox
        { spell = 115546, type = "ability", debuff = true, requiresTarget = true}, -- Provoke
        { spell = 116670, type = "ability"}, -- Vivify
        { spell = 116680, type = "ability", buff = true, charges = true}, -- Thunder Focus Tea
        { spell = 116841, type = "ability", talent = 6 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 12 }, -- Ring of Peace
        { spell = 116849, type = "ability", buff = true, requiresTarget = true}, -- Life Cocoon
        { spell = 117952, type = "ability"}, -- Crackling Jade Lightning
        { spell = 119381, type = "ability", debuff = true}, -- Leg Sweep
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 122278, type = "ability", buff = true, talent = 15 }, -- Dampen Harm
        { spell = 122281, type = "ability", charges = true, buff = true, talent = 13 }, -- Healing Elixir
        { spell = 122783, type = "ability", buff = true, talent = 14 }, -- Diffuse Magic
        { spell = 123986, type = "ability", talent = 3 }, -- Chi Burst
        { spell = 124682, type = "ability", buff = true, requiresTarget = true }, -- Enveloping Mist
        { spell = 126892, type = "ability"}, -- Zen Pilgrimage
        { spell = 191837, type = "ability"}, -- Essence Font
        { spell = 196725, type = "ability", buff = true, talent = 17 }, -- Refreshing Jade Wind
        { spell = 197908, type = "ability", buff = true, talent = 9 }, -- Mana Tea
        { spell = 198898, type = "ability", talent = 11 }, -- Song of Chi-Ji
        { spell = 218164, type = "ability"}, -- Detox
        { spell = 243435, type = "ability", buff = true}, -- Fortifying Brew
        { spell = 322101, type = "ability"}, -- Expel Harm
        { spell = 322109, type = "ability", usable = true}, -- Touch of Death
        { spell = 322118, type = "ability", duration = 25}, -- Invoke Yu'lon, the Jade Serpent
        { spell = 325197, type = "ability", talent = 18 }, -- Invoke Chi-Ji, the Red Crane
      },
      icon = 627485
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
        { spell = 205234, type="ability", pvptalent = 6},-- Healing Sphere
        { spell = 209584, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Zen Focus Tea
        { spell = 209584, type="buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"]},-- Zen Focus Tea
        { spell = 227344, type="buff", unit = "target", pvptalent = 7},-- Surging Mist
        { spell = 205655, type="buff", unit = "target", pvptalent = 5},-- Dome of Mist
        { spell = 233759, type="ability", pvptalent = 1, titleSuffix = L["cooldown"]},-- Grapple Weapon
        { spell = 233759, type="debuff", unit = "target", pvptalent = 1, titleSuffix = L["debuff"]},-- Grapple Weapon
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
  [3] = { -- Windwalker
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 101643, type = "buff", unit = "player"}, -- Transcendence
        { spell = 115288, type = "buff", unit = "player", talent = 9}, -- Energizing Brew
        { spell = 116768, type = "buff", unit = "player"}, -- Blackout Kick!
        { spell = 116841, type = "buff", unit = "player", talent = 6 }, -- Tiger's Lust
        { spell = 119085, type = "buff", unit = "player", talent = 5 }, -- Chi Torpedo
        { spell = 122783, type = "buff", unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 125174, type = "buff", unit = "player"}, -- Touch of Karma
        { spell = 137639, type = "buff", unit = "player"}, -- Storm, Earth, and Fire
        { spell = 152173, type = "buff", unit = "player", talent = 21 }, -- Serenity
        { spell = 166646, type = "buff", unit = "player" }, -- Windwalking
        { spell = 196608, type = "buff", unit = "player", talent = 1 }, -- Eye of the Tiger
        { spell = 196741, type = "buff", unit = "player", talent = 16 }, -- Hit Combo
        { spell = 243435, type = "buff", unit = "player" }, -- Fortifying Brew
        { spell = 261715, type = "buff", unit = "player", talent = 17 }, -- Rushing Jade Wind
        { spell = 261769, type = "buff", unit = "player", talent = 13 }, -- Inner Strength
        { spell = 325202, type = "buff", unit = "player", talent = 18 }, -- Dance of Chi-Ji
      },
      icon = 611420
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target", forceOwnOnly = true, ownOnly = nil}, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "multi"}, -- Paralysis
        { spell = 115080, type = "debuff", unit = "target"}, -- Touch of Death
        { spell = 115804, type = "debuff", unit = "target"}, -- Mortal Wounds
        { spell = 116189, type = "debuff", unit = "target"}, -- Provoke
        { spell = 116706, type = "debuff", unit = "target"}, -- Disable
        { spell = 117952, type = "debuff", unit = "target"}, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target"}, -- Leg Sweep
        { spell = 122470, type = "debuff", unit = "target"}, -- Touch of Karma
        { spell = 123586, type = "debuff", unit = "target"}, -- Flying Serpent Kick
        { spell = 196608, type = "debuff", unit = "target", talent = 1 }, -- Eye of the Tiger
        { spell = 228287, type = "debuff", unit = "target"}, -- Mark of the Crane

      },
      icon = 629534
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 100780, type = "ability", requiresTarget = true}, -- Tiger Palm
        { spell = 100784, type = "ability", requiresTarget = true, overlayGlow = true}, -- Blackout Kick
        { spell = 101545, type = "ability"}, -- Flying Serpent Kick
        { spell = 101546, type = "ability", overlayGlow = true}, -- Spinning Crane Kick
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 107428, type = "ability", requiresTarget = true}, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true}, -- Roll
        { spell = 113656, type = "ability", requiresTarget = true}, -- Fists of Fury
        { spell = 115008, type = "ability", charges = true, talent = 5 }, -- Chi Torpedo
        { spell = 115078, type = "ability", requiresTarget = true}, -- Paralysis
        { spell = 115098, type = "ability", talent = 2 }, -- Chi Wave
        { spell = 115203, type = "ability", buff = true }, -- Fortifying Brew
        { spell = 115288, type = "ability", talent = 9 }, -- Energizing Elixir
        { spell = 115546, type = "ability", debuff = true, requiresTarget = true}, -- Provoke
        { spell = 116095, type = "ability", requiresTarget = true}, -- Disable
        { spell = 116705, type = "ability", requiresTarget = true}, -- Spear Hand Strike
        { spell = 116670, type = "ability"}, -- Vivify
        { spell = 116841, type = "ability", talent = 6 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 12 }, -- Ring of Peace
        { spell = 116847, type = "ability", talent = 17 }, -- Rushing Jade Wind
        { spell = 117952, type = "ability"}, -- Crackling Jade Lightning
        { spell = 119381, type = "ability"}, -- Leg Sweep
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 122278, type = "ability", buff = true, talent = 15 }, -- Dampen Harm
        { spell = 122470, type = "ability", debuff = true, requiresTarget = true}, -- Touch of Karma
        { spell = 122783, type = "ability", buff = true, talent = 14 }, -- Diffuse Magic
        { spell = 123904, type = "ability", requiresTarget = true }, -- Invoke Xuen, the White Tiger
        { spell = 123986, type = "ability", talent = 3 }, -- Chi Burst
        { spell = 126892, type = "ability"}, -- Zen Pilgrimage
        { spell = 137639, type = "ability", charges = true, buff = true}, -- Storm, Earth, and Fire
        { spell = 152173, type = "ability", buff = true, talent = 21 }, -- Serenity
        { spell = 152175, type = "ability", usable = true, talent = 20 }, -- Whirling Dragon Punch
        { spell = 218164, type = "ability"}, -- Detox
        { spell = 261715, type = "ability", buff = true, talent = 17 }, -- Rushing Jade Wind
        { spell = 261947, type = "ability", talent = 8 }, -- Fist of the White Tiger
        { spell = 322101, type = "ability"}, -- Expel Harm
        { spell = 322109, type = "ability", usable = true, requiresTarget = true}, -- Touch of Death
      },
      icon = 627606
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
        { spell = 201447, type="buff", unit = "player", pvptalent = 4},-- Ride the Wind
        { spell = 201787, type="debuff", unit = "target", pvptalent = 1},-- Turbo Fists
        { spell = 233759, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Grapple Weapon
        { spell = 233759, type="debuff", unit = "target", pvptalent = 7, titleSuffix = L["debuff"]},-- Grapple Weapon
        { spell = 247483, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Tigereye Brew
        { spell = 247483, type="buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"]},-- Tigereye Brew
        { spell = 248646, type="buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"]},-- Tigereye Brew
        { spell = 287504, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Alpha Tiger
        { spell = 287771, type="ability", pvptalent = 3},-- Reverse Harm
        { spell = 290512, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Alpha Tiger
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 768, type = "buff", unit = "player"}, -- Cat Form
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player"}, -- Travel Form
        { spell = 1850, type = "buff", unit = "player"}, -- Dash
        { spell = 5215, type = "buff", unit = "player"}, -- Prowl
        { spell = 5487, type = "buff", unit = "player"}, -- Bear Form
        { spell = 8936, type = "buff", unit = "player"}, -- Regrowth
        { spell = 22812, type = "buff", unit = "player"}, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 8 }, -- Frenzied Regeneration
        { spell = 24858, type = "buff", unit = "player"}, -- Moonkin Form
        { spell = 29166, type = "buff", unit = "group"}, -- Innervate
        { spell = 48517, type = "buff", unit = "player" }, -- Eclipse (Solar)
        { spell = 48438, type = "buff", unit = "player", talent = 9 }, -- Wild Growth
        { spell = 48518, type = "buff", unit = "player" }, -- Eclipse (Lunar)
        { spell = 102560, type = "buff", unit = "player", talent = 15 }, -- Incarnation: Chosen of Elune
        { spell = 106898, type = "buff", unit = "player" }, -- Stampeding Roar
        { spell = 108294, type = "buff", unit = "player", talent = 12 }, -- Heart of the Wild
        { spell = 191034, type = "buff", unit = "player"}, -- Starfall
        { spell = 192081, type = "buff", unit = "player" }, -- Ironfur
        { spell = 194223, type = "buff", unit = "player"}, -- Celestial Alignment
        { spell = 202425, type = "buff", unit = "player", talent = 2 }, -- Warrior of Elune
        { spell = 202461, type = "buff", unit = "player", talent = 16 }, -- Stellar Drift
        { spell = 252216, type = "buff", unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 279709, type = "buff", unit = "player", talent = 14 }, -- Starlord
      },
      icon = 136097
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 339, type = "debuff", unit = "multi"}, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 7 }, -- Rip
        { spell = 2637, type = "debuff", unit = "multi"}, -- Hibernate
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target"}, -- Growl
        { spell = 33786, type = "debuff", unit = "target"}, -- Cyclone
        { spell = 61391, type = "debuff", unit = "target"}, -- Typhoon
        { spell = 81261, type = "debuff", unit = "target"}, -- Solar Beam
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 155722, type = "debuff", unit = "target", talent = 7 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target"}, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target", talent = 8 }, -- Thrash
        { spell = 202347, type = "debuff", unit = "target", talent = 18 }, -- Stellar Flare
        { spell = 205644, type = "debuff", unit = "target", talent = 3 }, -- Force of Nature
      },
      icon = 132114
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 99, type = "ability", talent = 8}, -- Incapacitating Roar
        { spell = 339, type = "ability", debuff = true}, -- Entangling Roots
        { spell = 768, type = "ability"}, -- Cat Form
        { spell = 783, type = "ability"}, -- Travel Form
        { spell = 1079, type = "ability", talent = 7}, -- Rip
        { spell = 1822, type = "ability", debuff = true, talent = 7}, -- Rake
        { spell = 1850, type = "ability", buff = true}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true}, -- Soothe
        { spell = 5176, type = "ability", requiresTarget = true }, -- Wrath
        { spell = 5211, type = "ability", requiresTarget = true, talent = 10 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true}, -- Prowl
        { spell = 5221, type = "ability"}, -- Shred
        { spell = 5487, type = "ability"}, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true}, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true, debuff = true}, -- Moonfire
        { spell = 8936, type = "ability"}, -- Regrowth
        { spell = 16979, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 18562, type = "ability", talent = 9 }, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true}, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, talent = 7}, -- Maim
        { spell = 22812, type = "ability", buff = true}, -- Barkskin
        { spell = 22842, type = "ability", buff = true, talent = 8 }, -- Frenzied Regeneration
        { spell = 24858, type = "ability"}, -- Moonkin Form
        { spell = 29166, type = "ability"}, -- Innervate
        { spell = 33917, type = "ability", requiresTarget = true}, -- Mangle
        { spell = 33786, type = "ability", requiresTarget = true, debuff = true}, -- Cyclone
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
        { spell = 102793, type = "ability", talent = 9 }, -- Ursol's Vortex
        { spell = 106832, type = "ability", talent = 8 }, -- Thrash
        { spell = 106898, type = "ability" }, -- Stampeding Roar
        { spell = 108238, type = "ability", talent = 5 }, -- Renewal
        { spell = 132469, type = "ability"}, -- Typhoon
        { spell = 190984, type = "ability", requiresTarget = true, overlayGlow = true}, -- Solar Wrath
        { spell = 191034, type = "ability", buff = true}, -- Starfall
        { spell = 192081, type = "ability", buff = true }, -- Ironfur
        { spell = 194153, type = "ability", requiresTarget = true, overlayGlow = true}, -- Starfire
        { spell = 194223, type = "ability", buff = true}, -- Celestial Alignment
        { spell = 202347, type = "ability", requiresTarget = true, debuff = true, talent = 18}, -- Stellar Flare
        { spell = 202425, type = "ability", buff = true, talent = 2 }, -- Warrior of Elune
        { spell = 202770, type = "ability", talent = 20 }, -- Fury of Elune
        { spell = 205636, type = "ability", duration = 10, talent = 3 }, -- Force of Nature
        { spell = 213764, type = "ability", talent = 7 }, -- Swipe
        { spell = 252216, type = "ability", buff = true, talent = 4 }, -- Tiger Dash
        { spell = 274281, type = "ability", requiresTarget = true, charges = true, talent = 21 }, -- New Moon
        { spell = 319454, type = "ability", buff = true, talent = 12}, -- Heart of the Wild
      },
      icon = 132134
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
        { spell = 200947, type="debuff", unit = "target", pvptalent = 10},-- High Winds
        { spell = 209731, type="buff", unit = "player", pvptalent = 6},-- Protector of the Grove
        { spell = 209746, type="buff", unit = "player", pvptalent = 5},-- Moonkin Aura
        { spell = 209749, type="ability", pvptalent = 3, titleSuffix = L["cooldown"]},-- Faerie Swarm
        { spell = 209749, type="debuff", unit = "target", pvptalent = 3, titleSuffix = L["debuff"]},-- Faerie Swarm
        { spell = 305497, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Thorns
        { spell = 305497, type="buff", unit = "target", pvptalent = 7, titleSuffix = L["buff"]},-- Thorns
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 768, type = "buff", unit = "player"}, -- Cat Form
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player"}, -- Travel Form
        { spell = 1850, type = "buff", unit = "player"}, -- Dash
        { spell = 5215, type = "buff", unit = "player"}, -- Prowl
        { spell = 5217, type = "buff", unit = "player"}, -- Tiger's Fury
        { spell = 5487, type = "buff", unit = "player"}, -- Bear Form
        { spell = 8936, type = "buff", unit = "player"}, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 8 }, -- Frenzied Regeneration
        { spell = 48438, type = "buff", unit = "player", talent = 9 }, -- Wild Growth
        { spell = 52610, type = "buff", unit = "player", talent = 14 }, -- Savage Roar
        { spell = 61336, type = "buff", unit = "player"}, -- Survival Instincts
        { spell = 69369, type = "buff", unit = "player"}, -- Predatory Swiftness
        { spell = 102543, type = "buff", unit = "player", talent = 15 }, -- Incarnation: King of the Jungle
        { spell = 106898, type = "buff", unit = "player"}, -- Stampeding Roar
        { spell = 106951, type = "buff", unit = "player"}, -- Berserk
        { spell = 108294, type = "buff", unit = "player"}, -- Hearth of the Wild
        { spell = 135700, type = "buff", unit = "player"}, -- Clearcastingp
        { spell = 145152, type = "buff", unit = "player", talent = 20 }, -- Bloodtalons
        { spell = 192081, type = "buff", unit = "player" }, -- Ironfur
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 252071, type = "buff", unit = "player", talent = 15 }, -- Jungle Stalker
        { spell = 252216, type = "buff", unit = "player", talent = 4 }, -- Tiger Dash
        { spell = 285646, type = "buff", unit = "player", talent = 16 }, -- Scent of Blood
      },
      icon = 136170
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 339, type = "debuff", unit = "multi"}, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target"}, -- Rip
        { spell = 2637, type = "debuff", unit = "multi"}, -- Hibernate
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target"}, -- Growl
        { spell = 33786, type = "debuff", unit = "target"}, -- Cyclone
        { spell = 58180, type = "debuff", unit = "target"}, -- Infected Wounds
        { spell = 61391, type = "debuff", unit = "target", talent = 7 }, -- Typhoon
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 106830, type = "debuff", unit = "target"}, -- Thrash
        { spell = 155625, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 155722, type = "debuff", unit = "target"}, -- Rake
        { spell = 164815, type = "debuff", unit = "target", talent = 7 }, -- Sunfire
        { spell = 164812, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 203123, type = "debuff", unit = "target"}, -- Maim
        { spell = 274838, type = "debuff", unit = "target", talent = 21 }, -- Feral Frenzy
      },
      icon = 132152
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 99, type = "ability", talent = 8}, -- Incapacitating Roar
        { spell = 339, type = "ability", requiresTarget = true, overlayGlow = true}, -- Entangling Roots
        { spell = 768, type = "ability"}, -- Cat Form
        { spell = 774, type = "ability", buff = true, talent = 9}, -- Rejuvenation
        { spell = 783, type = "ability"}, -- Travel Form
        { spell = 1079, type = "ability", debuff = true, requiresTarget = true}, -- Rip
        { spell = 1822, type = "ability", debuff = true, requiresTarget = true}, -- Rake
        { spell = 1850, type = "ability", buff = true}, -- Dash
        { spell = 2637, type = "ability"}, -- Hibernate
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true}, -- Soothe
        { spell = 5176, type = "ability", requiresTarget = true }, -- Wrath
        { spell = 5211, type = "ability", requiresTarget = true, talent = 10 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true}, -- Prowl
        { spell = 5217, type = "ability", buff = true}, -- Tiger's Fury
        { spell = 5221, type = "ability", requiresTarget = true, overlayGlow = true}, -- Shred
        { spell = 5487, type = "ability"}, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true}, -- Growl
        { spell = 8921, type = "ability", debuff = true, requiresTarget = true}, -- Moonfire
        { spell = 8936, type = "ability", overlayGlow = true}, -- Regrowth
        { spell = 16979, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 18562, type = "ability", talent = 9, usable = true }, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true}, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, debuff = true}, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", buff = true, talent = 8 }, -- Frenzied Regeneration
        { spell = 33786, type = "ability", requiresTarget = true, debuff = true}, -- Cyclone
        { spell = 33917, type = "ability", requiresTarget = true}, -- Mangle
        { spell = 48438, type = "ability", talent = 9 }, -- Wild Growth
        { spell = 49376, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 52610, type = "ability", buff = true, talent = 14}, -- Savage Roar
        { spell = 61336, type = "ability", charges = true, buff = true}, -- Survival Instincts
        { spell = 102359, type = "ability", requiresTarget = true, talent = 11 }, -- Mass Entanglement
        { spell = 102401, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102543, type = "ability", buff = true, talent = 15 }, -- Incarnation: King of the Jungle
        { spell = 102793, type = "ability", talent = 9 }, -- Ursol's Vortex
        { spell = 106832, type = "ability", overlayGlow = true}, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true}, -- Skull Bash
        { spell = 106898, type = "ability", buff = true}, -- Stampeding Roar
        { spell = 106951, type = "ability"}, -- Berserk
        { spell = 108238, type = "ability", talent = 5 }, -- Renewal
        { spell = 132469, type = "ability", talent = 7 }, -- Typhoon
        { spell = 192081, type = "ability", buff = true }, -- Ironfur
        { spell = 197625, type = "ability", talent = 7 }, -- Moonkin Form
        { spell = 197626, type = "ability", requiresTarget = true, talent = 7 }, -- Starsurge
        { spell = 197628, type = "ability", requiresTarget = true, talent = 7 }, -- Starfire
        { spell = 197630, type = "ability", debuff = true, requiresTarget = true, talent = 7 }, -- Sunfire
        { spell = 202028, type = "ability", charges = true, overlayGlow = true, talent = 17 }, -- Brutal Slash
        { spell = 213764, type = "ability", overlayGlow = true}, -- Swipe
        { spell = 252216, type = "ability", buff = true, talent = 4 }, -- Tiger Dash
        { spell = 274837, type = "ability", requiresTarget = true, talent = 21 }, -- Feral Frenzy
        { spell = 285381, type = "ability", talent = 18 }, -- Primal Wrath
        { spell = 319454, type = "ability", talent = 12 }, -- Heart of the Wild
      },
      icon = 236149
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
        { spell = 202636, type="buff", unit = "player", pvptalent = 10},-- Leader of the Pack
        { spell = 203059, type="buff", unit = "player", pvptalent = 4},-- King of the Jungle
        { spell = 203242, type="ability", pvptalent = 6},-- Rip and Tear
        { spell = 200947, type="debuff", unit = "target", pvptalent = 9},-- High Winds
        { spell = 236021, type="debuff", unit = "target", pvptalent = 8},-- Ferocious Wound
        { spell = 209731, type="buff", unit = "player", pvptalent = 7}, -- Strenght of the Wild
        { spell = 236716, type="ability", pvptalent = 7},-- Strenght of the Wild
        { spell = 305497, type="ability", pvptalent = 1, titleSuffix = L["cooldown"]},-- Thorns
        { spell = 305497, type="buff", unit = "group", pvptalent = 1, titleSuffix = L["buff"]},-- Thorns
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = comboPointsIcon,
    },
  },
  [3] = { -- Guardian
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 768, type = "buff", unit = "player"}, -- Cat Form
        { spell = 783, type = "buff", unit = "player"}, -- Travel Form
        { spell = 1850, type = "buff", unit = "player"}, -- Dash
        { spell = 5215, type = "buff", unit = "player"}, -- Prowl
        { spell = 5487, type = "buff", unit = "player"}, -- Bear Form
        { spell = 8936, type = "buff", unit = "player"}, -- Regrowth
        { spell = 22812, type = "buff", unit = "player"}, -- Barkskin
        { spell = 22842, type = "buff", unit = "player"}, -- Frenzied Regeneration
        { spell = 48438, type = "buff", unit = "player", talent = 9 }, -- Wild Growth
        { spell = 50334, type = "buff", unit = "player" }, -- Berserk
        { spell = 61336, type = "buff", unit = "player"}, -- Survival Instincts
        { spell = 93622, type = "buff", unit = "player"}, -- Gore
        { spell = 102558, type = "buff", unit = "player", talent = 15 }, -- Incarnation: Guardian of Ursoc
        { spell = 106898, type = "buff", unit = "player"}, -- Stampeding Roarew
        { spell = 135286, type = "buff", unit = "player", talent = 20 }, -- Tooth and Claw
        { spell = 155835, type = "buff", unit = "player", talent = 3 }, -- Bristling Fur
        { spell = 192081, type = "buff", unit = "player"}, -- Ironfur
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 203975, type = "buff", unit = "player", talent = 16 }, -- Earthwarden
        { spell = 213680, type = "buff", unit = "player", talent = 18 }, -- Guardian of Elune
        { spell = 213708, type = "buff", unit = "player", talent = 14 }, -- Galactic Guardian
        { spell = 252216, type = "buff", unit = "player", talent = 4 }, -- Tiger Dash
      },
      icon = 1378702
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target"}, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "multi"}, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 8 }, -- Rip
        { spell = 2637, type = "debuff", unit = "multi"}, -- Hibernate
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target"}, -- Growl
        { spell = 33786, type = "debuff", unit = "target"}, -- Cyclone
        { spell = 45334, type = "debuff", unit = "target", talent = 6 }, -- Immobilized
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 80313, type = "debuff", unit = "target", talent = 21 }, -- Pulverize
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 155722, type = "debuff", unit = "target", talent = 8 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 7 }, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target"}, -- Thrash
        { spell = 236748, type = "debuff", unit = "target", talent = 5 }, -- Intimidating Roar
        { spell = 345208, type = "debuff", unit = "target" }, -- Infected Wounds
      },
      icon = 451161
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 99, type = "ability"}, -- Incapacitating Roar
        { spell = 339, type = "ability"}, -- Entangling Roots
        { spell = 768, type = "ability"}, -- Cat Form
        { spell = 774, type = "ability", buff = true, talent = 9}, -- Rejuvenation
        { spell = 783, type = "ability"}, -- Travel Form
        { spell = 1079, type = "ability", debuff = true, talent = 8}, -- Rip
        { spell = 1850, type = "ability", buff = true}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true}, -- Soothe
        { spell = 5211, type = "ability", requiresTarget = true, talent = 10 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true}, -- Prowl
        { spell = 5221, type = "ability"}, -- Shred
        { spell = 5487, type = "ability"}, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true}, -- Growl
        { spell = 6807, type = "ability", requiresTarget = true}, -- Maul
        { spell = 8921, type = "ability", debuff = true, requiresTarget = true, overlayGlow = true}, -- Moonfire
        { spell = 8936, type = "ability"}, -- Regrowth
        { spell = 16979, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 18562, type = "ability", talent = 9, usable = true }, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22812, type = "ability", buff = true}, -- Barkskin
        { spell = 22842, type = "ability", charges = true, buff = true}, -- Frenzied Regeneration
        { spell = 22568, type = "ability"}, -- Ferocious Bite
        { spell = 22570, type = "ability", talent = 8}, -- Maim
        { spell = 33786, type = "ability", requiresTarget = true, debuff = true}, -- Cyclone
        { spell = 33917, type = "ability", requiresTarget = true, overlayGlow = true}, -- Mangle
        { spell = 48438, type = "ability", talent = 9 }, -- Wild Growth
        { spell = 49376, type = "ability", requiresTarget = true, talent = 6 }, -- Wild Charge
        { spell = 50334, type = "ability", buff = true}, -- Berserk
        { spell = 61336, type = "ability", charges = true, buff = true}, -- Survival Instincts
        { spell = 77758, type = "ability"}, -- Thrash
        { spell = 77761, type = "ability", buff = true}, -- Stampeding Roar
        { spell = 80313, type = "ability", buff = true, requiresTarget = true, usable = true, talent = 21}, -- Pulverize
        { spell = 102359, type = "ability", requiresTarget = true, talent = 11 }, -- Mass Entanglement
        { spell = 102383, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102401, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102558, type = "ability", buff = true, talent = 15 }, -- Incarnation: Guardian of Ursoc
        { spell = 102359, type = "ability", requiresTarget = true, talent = 11}, -- Mass Entanglement
        { spell = 102793, type = "ability", talent = 9 }, -- Ursol's Vortex
        { spell = 106832, type = "ability", requiresTarget = true}, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true}, -- Skull Bash
        { spell = 106898, type = "ability"}, -- Stampeding Roar
        { spell = 108238, type = "ability"}, -- Renewal
        { spell = 132469, type = "ability", talent = 7 }, -- Typhoon
        { spell = 155835, type = "ability", buff = true, talent = 3 }, -- Bristling Fur
        { spell = 192081, type = "ability", buff = true}, -- Ironfur
        { spell = 197626, type = "ability", requiresTarget = true, talent = 7 }, -- Starsurge
        { spell = 197628, type = "ability", requiresTarget = true, talent = 7 }, -- Starfire
        { spell = 197630, type = "ability", requiresTarget = true, talent = 7 }, -- Sunfire
        { spell = 204066, type = "ability", talent = 20 }, -- Lunar Beam
        { spell = 213764, type = "ability" }, -- Swipe
        { spell = 236748, type = "ability", talent = 5 }, -- Intimidating Roar
        { spell = 252216, type = "ability", buff = true, talent = 4 }, -- Tiger Dash
        { spell = 319454, type = "ability", buff = true, talent = 12 }, -- Heart of the Wild
      },
      icon = 236169
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
        { spell = 201664, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Demoralizing Roar
        { spell = 201664, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Demoralizing Roar
        { spell = 202244, type="debuff", unit = "target", pvptalent = 2, titleSuffix = L["debuff"]},-- Overrun
        { spell = 202246, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Overrun
        { spell = 206891, type="debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"]},-- Alpha Challenge
        { spell = 207017, type="ability", pvptalent = 14, titleSuffix = L["cooldown"]},-- Alpha Challenge
        { spell = 200947, type="debuff", unit = "target", pvptalent = 6},-- High Winds
        { spell = 236187, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Master Shapeshifter
        { spell = 236185, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Master Shapeshifter
        { spell = 279943, type="buff", unit = "player", pvptalent = 1},-- Sharpened Claws
        { spell = 329042, type="buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"]},-- Roar of the Protector
        { spell = 329042, type="ability", pvptalent = 3, titleSuffix = L["cooldown"]},-- Roar of the Protector
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = rageIcon,
    },
  },
  [4] = { -- Restoration
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 768, type = "buff", unit = "player"}, -- Cat Form
        { spell = 774, type = "buff", unit = "target"}, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player"}, -- Travel Form
        { spell = 1850, type = "buff", unit = "player"}, -- Dash
        { spell = 5215, type = "buff", unit = "player"}, -- Prowl
        { spell = 5487, type = "buff", unit = "player"}, -- Bear Form
        { spell = 8936, type = "buff", unit = "target"}, -- Regrowth
        { spell = 16870, type = "buff", unit = "player"}, -- Clearcasting
        { spell = 22812, type = "buff", unit = "target"}, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 9 }, -- Frenzied Regeneration
        { spell = 33891, type = "buff", unit = "player", talent = 15 }, -- Incarnation: Tree of Life
        { spell = 29166, type = "buff", unit = "player"}, -- Innervate
        { spell = 33763, type = "buff", unit = "target"}, -- Lifebloom
        { spell = 48438, type = "buff", unit = "player"}, -- Wild Growth
        { spell = 102351, type = "buff", unit = "player", talent = 3 }, -- Cenarion Ward
        { spell = 102342, type = "buff", unit = "player"}, -- Ironbark
        { spell = 102401, type = "buff", unit = "player", talent = 6 }, -- Wild Charge
        { spell = 106898, type = "buff", unit = "player" }, -- Stampeding Roar
        { spell = 114108, type = "buff", unit = "player", talent = 13 }, -- Soul of the Forest
        { spell = 117679, type = "buff", unit = "player", talent = 15 }, -- Incarnation
        { spell = 155777, type = "buff", unit = "target", talent = 20 }, -- Rejuvenation (Germination)
        { spell = 157982, type = "buff", unit = "player"}, -- Tranquility
        { spell = 192081, type = "buff", unit = "player" }, -- Ironfur
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 197721, type = "buff", unit = "target", talent = 21 }, -- Flourish
        { spell = 200389, type = "buff", unit = "player", talent = 14 }, -- Cultivation
        { spell = 207640, type = "buff", unit = "player", talent = 1 }, -- Abundance
        { spell = 207386, type = "buff", unit = "target", talent = 17 }, -- Spring Blossoms
        { spell = 252216, type = "buff", unit = "player", talent = 4 }, -- Tiger Dash

      },
      icon = 136081
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 339, type = "debuff", unit = "multi"}, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 8 }, -- Rip
        { spell = 1822, type = "debuff", unit = "target", talent = 8 }, -- Rake
        { spell = 2637, type = "debuff", unit = "multi"}, -- Hibernate
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target"}, -- Growl
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 33786, type = "debuff", unit = "target"}, -- Cyclone
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 127797, type = "debuff", unit = "target"}, -- Ursol's Vortex
        { spell = 155722, type = "debuff", unit = "target", talent = 8 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target"}, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 7}, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target", talent = 9 }, -- Thrash
      },
      icon = 236216
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 99, type = "ability", debuff = true, talent = 9}, -- Incapacitating Roar
        { spell = 339, type = "ability", debuff = true}, -- Entangling Roots
        { spell = 740, type = "ability"}, -- Tranquility
        { spell = 768, type = "ability"}, -- Cat Form
        { spell = 774, type = "ability"}, -- Rejuvenation
        { spell = 783, type = "ability"}, -- Travel Form
        { spell = 1079, type = "ability", debuff = true, talent = 8}, -- Rip
        { spell = 1822, type = "ability", debuff = true, talent = 8}, -- Rake
        { spell = 1850, type = "ability", buff = true}, -- Dash
        { spell = 2637, type = "ability", requiresTarget = true}, -- Hibernate
        { spell = 2908, type = "ability", requiresTarget = true}, -- Soothe
        { spell = 5176, type = "ability"}, -- Wrath
        { spell = 5211, type = "ability", requiresTarget = true, talent = 10 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true}, -- Prowl
        { spell = 5221, type = "ability"}, -- Shred
        { spell = 5487, type = "ability"}, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true}, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true, debuff = true}, -- Moonfire
        { spell = 8936, type = "ability"}, -- Regrowth
        { spell = 18562, type = "ability", usable = true}, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true}, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, talent = 8}, -- Maim
        { spell = 22812, type = "ability", buff = true}, -- Barkskin
        { spell = 22842, type = "ability", buff = true, talent = 9 }, -- Frenzied Regeneration
        { spell = 29166, type = "ability", buff = true}, -- Innervate
        { spell = 33786, type = "ability", requiresTarget = true, debuff = true}, -- Cyclone
        { spell = 33891, type = "ability", buff = true, talent = 15 }, -- Incarnation: Tree of Life
        { spell = 33917, type = "ability", requiresTarget = true}, -- Mangle
        { spell = 48438, type = "ability"}, -- Wild Growth
        { spell = 50464, type = "ability", talent = 2}, -- Nourish
        { spell = 77758, type = "ability", talent = 9 }, -- Thrash
        { spell = 88423, type = "ability"}, -- Nature's Cure
        { spell = 93402, type = "ability", requiresTarget = true, talent = 7 }, -- Sunfire
        { spell = 102342, type = "ability"}, -- Ironbark
        { spell = 102351, type = "ability", talent = 3 }, -- Cenarion Ward
        { spell = 102359, type = "ability", requiresTarget = true, talent = 11 }, -- Mass Entanglement
        { spell = 102401, type = "ability", talent = 6 }, -- Wild Charge
        { spell = 102793, type = "ability"}, -- Ursol's Vortex
        { spell = 106832, type = "ability", debuff = true, talent = 9 }, -- Thrash
        { spell = 106898, type = "ability" }, -- Stampeding Roar
        { spell = 108238, type = "ability", talent = 5 }, -- Renewal
        { spell = 108293, type = "buff", unit = "player", talent = 12 }, -- Heart of the Wild
        { spell = 132158, type = "ability" }, -- Nature's Swiftness
        { spell = 132469, type = "ability", talent = 7 }, -- Typhoon
        { spell = 192081, type = "ability", buff = true }, -- Ironfur
        { spell = 197625, type = "ability", talent = 7 }, -- Moonkin Form
        { spell = 197626, type = "ability", requiresTarget = true, talent = 7 }, -- Starsurge
        { spell = 197628, type = "ability", requiresTarget = true, talent = 7 }, -- Starfire
        { spell = 197721, type = "ability", talent = 21 }, -- Flourish
        { spell = 203651, type = "ability", talent = 18 }, -- Overgrowth
        { spell = 213764, type = "ability", talent = 8}, -- Swipe
        { spell = 252216, type = "ability", buff = true, talent = 4 }, -- Tiger Dash
        { spell = 319454, type = "ability", buff = true, talent = 12}, -- Heart of the Wild
      },
      icon = 236153
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
        { spell = 200947, type="debuff", unit = "target", pvptalent = 10},-- High Winds
        { spell = 203407, type="buff", unit = "target", pvptalent = 6},-- Revitalize
        { spell = 203554, type="buff", unit = "target", pvptalent = 1},-- Focused Growth
        { spell = 236187, type="buff", unit = "player", pvptalent = 2},-- Master Shapeshifter
        { spell = 247563, type="buff", unit = "group", pvptalent = 5},-- Entangling Bark
        { spell = 289318, type="buff", unit = "group", pvptalent = 3},-- Mark of the Wild
        { spell = 290213, type="buff", unit = "target", pvptalent = 9},-- Early Spring
        { spell = 305497, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Thorns
        { spell = 305497, type="buff", unit = "group", pvptalent = 4, titleSuffix = L["buff"]},-- Thorns
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = manaIcon,
    },
  },
}

templates.class.DEMONHUNTER = {
  [1] = { -- Havoc
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 131347, type = "buff", unit = "player"}, -- Glide
        { spell = 162264, type = "buff", unit = "player"}, -- Metamorphosis
        { spell = 188499, type = "buff", unit = "player"}, -- Blade Dance
        { spell = 188501, type = "buff", unit = "player"}, -- Spectral Sight
        { spell = 196555, type = "buff", unit = "player", talent = 12 }, -- Netherwalk
        { spell = 203650, type = "buff", unit = "player", talent = 20 }, -- Prepared
        { spell = 208628, type = "buff", unit = "player", talent = 20 }, -- Momentum
        { spell = 209426, type = "buff", unit = "player"}, -- Darkness
        { spell = 212800, type = "buff", unit = "player"}, -- Blur
        { spell = 258920, type = "buff", unit = "player"}, -- Immolation Aura
        { spell = 337313, type = "buff", unit = "player" }, -- Inner Demon
        { spell = 343312, type = "buff", unit = "player" }, -- Eye Beam
        { spell = 347462, type = "buff", unit = "player", talent = 8 }, -- Unbound Chaos
      },
      icon = 1247266
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1490, type = "debuff", unit = "target", forceOwnOnly = true, ownOnly = true}, -- Chaos Brand
        { spell = 179057, type = "debuff", unit = "target"}, -- Chaos Nova
        { spell = 185245, type = "debuff", unit = "target"}, -- Torment
        { spell = 198813, type = "debuff", unit = "target"}, -- Vengeful Retreat
        { spell = 200166, type = "debuff", unit = "target"}, -- Metamorphosis
        { spell = 206491, type = "debuff", unit = "target", talent = 21 }, -- Nemesis
        { spell = 211881, type = "debuff", unit = "target", talent = 18 }, -- Fel Eruption
        { spell = 213405, type = "debuff", unit = "target", talent = 17 }, -- Master of the Glaive
        { spell = 217832, type = "debuff", unit = "multi" }, -- Imprison
        { spell = 258883, type = "debuff", unit = "target", talent = 7}, -- Trail of Ruin
        { spell = 320338, type = "debuff", unit = "target", talent = 15 }, -- Essence Break
      },
      icon = 1392554
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 131347, type = "ability"}, -- Glide
        { spell = 183752, type = "ability", requiresTarget = true}, -- Disrupt
        { spell = 185123, type = "ability", requiresTarget = true}, -- Throw Glaive
        { spell = 185245, type = "ability", requiresTarget = true, debuff = true}, -- Torment
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
        { spell = 258860, type = "ability", debuff = true, requiresTarget = true, talent = 15 }, -- Essence Break
        { spell = 258920, type = "ability", buff = true }, -- Immolation Aura
        { spell = 258925, type = "ability", talent = 21 }, -- Fel Barrage
        { spell = 278326, type = "ability", requiresTarget = true}, -- Consume Magic
        { spell = 342817, type = "ability", requiresTarget = true, talent = 9}, -- Glaive Tempest
        { spell = 344859, type = "ability", requiresTarget = true}, -- Demon's Bite
        { spell = 344862, type = "ability"}, -- Chaos Strike
        { spell = 344865, type = "ability", overlayGlow = true}, -- Fel Rush
        { spell = 344866, type = "ability"}, -- Vengeful Retreat
        { spell = 344867, type = "ability", debuff = true}, -- Chaos Nova
      },
      icon = 1305156
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
        { spell = 115804, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Mortal Rush
        { spell = 203704, type="ability", pvptalent = 11, titleSuffix = L["cooldown"]},-- Mana Break
        { spell = 203704, type="debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"]},-- Mana Break
        { spell = 205604, type="ability", pvptalent = 5},-- Reverse Magic
        { spell = 206649, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Eye of Leotheras
        { spell = 206649, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"]},-- Eye of Leotheras
        { spell = 206803, type="buff", unit = "player", pvptalent = 4, titleSuffix = L["buff"]},-- Rain from Above
        { spell = 206803, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Rain from Above
        { spell = 235903, type="ability", pvptalent = 7},-- Mana Rift
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 131347, type = "buff", unit = "player"}, -- Glide
        { spell = 178740, type = "buff", unit = "player"}, -- Immolation Aura
        { spell = 188501, type = "buff", unit = "player"}, -- Spectral Sight
        { spell = 203981, type = "buff", unit = "player"}, -- Soul Fragments
        { spell = 203819, type = "buff", unit = "player"}, -- Demon Spikes
        { spell = 207693, type = "buff", unit = "player", talent = 4}, -- Feast of Souls
        { spell = 258920, type = "buff", unit = "player"}, -- Metamorphosis
        { spell = 263648, type = "buff", unit = "player", talent = 18 }, -- Soul Barrier
        { spell = 326863, type = "buff", unit = "player", talent = 20 }, -- Ruinous Bulwark
        { spell = 343013, type = "buff", unit = "player" }, -- Revel in Pain
      },
      icon = 1247263
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1490, type = "debuff", unit = "target", forceOwnOnly = true, ownOnly = nil}, -- Chaos Brand
        { spell = 185245, type = "debuff", unit = "target"}, -- Torment
        { spell = 204490, type = "debuff", unit = "target"}, -- Sigil of Silence
        { spell = 204598, type = "debuff", unit = "target"}, -- Sigil of Flame
        { spell = 204843, type = "debuff", unit = "target", talent = 15 }, -- Sigil of Chains
        { spell = 207685, type = "debuff", unit = "target"}, -- Sigil of Misery
        { spell = 207771, type = "debuff", unit = "target" }, -- Fiery Brand
        { spell = 209261, type = "debuff", unit = "player" }, -- Uncontained Fel
        { spell = 217832, type = "debuff", unit = "multi" }, -- Imprison
        { spell = 247456, type = "debuff", unit = "target", talent = 9 }, -- Frailty
        { spell = 268178, type = "debuff", unit = "target", talent = 16 }, -- Void Reaver
      },
      icon = 1344647
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 131347, type = "ability"}, -- Glide
        { spell = 183752, type = "ability", requiresTarget = true}, -- Disrupt
        { spell = 185123, type = "ability"}, -- Throw Glaive
        { spell = 185245, type = "ability", debuff = true, requiresTarget = true}, -- Torment
        { spell = 188501, type = "ability", buff = true}, -- Spectral Sight
        { spell = 187827, type = "ability", buff = true}, -- Metamorphosis
        { spell = 189110, type = "ability", charges = true}, -- Infernal Strike
        { spell = 191427, type = "ability", buff = true}, -- Metamorphosis
        { spell = 202137, type = "ability", debuff = true}, -- Sigil of Silence
        { spell = 202138, type = "ability", talent = 15 }, -- Sigil of Chains
        { spell = 202140, type = "ability"}, -- Sigil of Misery
        { spell = 204157, type = "ability", requiresTarget = true}, -- Throw Glaive
        { spell = 204596, type = "ability", debuff = true}, -- Sigil of Flame
        { spell = 207684, type = "ability", debuff = true}, -- Sigil of Misery
        { spell = 212084, type = "ability" }, -- Fel Devastation
        { spell = 217832, type = "ability", requiresTarget = true}, -- Imprison
        { spell = 228477, type = "ability", requiresTarget = true}, -- Soul Cleave
        { spell = 232893, type = "ability", requiresTarget = true, overlayGlow = true, talent = 3 }, -- Felblade
        { spell = 247454, type = "ability", usable = true, talent = 9 }, -- Spirit Bomb
        { spell = 258920, type = "ability", buff = true}, -- Immolation Aura
        { spell = 263642, type = "ability", charges = true, talent = 12 }, -- Fracture
        { spell = 263648, type = "ability", buff = true, talent = 18 }, -- Soul Barrier
        { spell = 278326, type = "ability", requiresTarget = true}, -- Consume Magic
        { spell = 320341, type = "ability"}, -- Bulk Extraction
        { spell = 344859, type = "ability"}, -- Shear
        { spell = 344862, type = "ability"}, -- Soul Cleave
        { spell = 344865, type = "ability", charges = true}, -- Infernal Strike
        { spell = 344866, type = "ability", charges = true, buff = true}, -- Demon Spikes
        { spell = 344867, type = "ability", debuff = true, requiresTarget = true}, -- Fiery Brand
      },
      icon = 1344650
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
        { spell = 205629, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Demonic Trample
        { spell = 205604, type="ability", pvptalent = 4}, -- Reverse Magic
        { spell = 205630, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Illidan's Grasp
        { spell = 205630, type="debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]},-- Illidan's Grasp
        { spell = 206891, type="debuff", unit = "target", pvptalent = 3, titleSuffix = L["debuff"]},-- Tormentor
        { spell = 207029, type="ability", pvptalent = 3, titleSuffix = L["cooldown"]},-- Tormentor
        { spell = 208769, type="buff", unit = "player", pvptalent = 6},-- Everlasting Hunt
        { spell = 213491, type="debuff", unit = "target", pvptalent = 2, titleSuffix = L["debuff"]},-- Demonic Trample
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 3714, type = "buff", unit = "player"}, -- Path of Frost
        { spell = 48265, type = "buff", unit = "player"}, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player"}, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player"}, -- Icebound Fortitude
        { spell = 49039, type = "buff", unit = "player"}, -- Lichborne
        { spell = 55233, type = "buff", unit = "player"}, -- Vampiric Blood
        { spell = 53365, type = "buff", unit = "player"}, -- Unholy Strength
        { spell = 77535, type = "buff", unit = "player"}, -- Blood Shield
        { spell = 81141, type = "buff", unit = "player"}, -- Crimson Scourge
        { spell = 81256, type = "buff", unit = "player"}, -- Dancing Rune Weapon
        { spell = 145629, type = "buff", unit = "player"}, -- Anti-Magic Zone
        { spell = 188290, type = "buff", unit = "player"}, -- Death and Decay
        { spell = 194679, type = "buff", unit = "player"}, -- Rune Tap
        { spell = 195181, type = "buff", unit = "player"}, -- Bone Shield
        { spell = 194844, type = "buff", unit = "player", talent = 21}, -- Bonestorm
        { spell = 212552, type = "buff", unit = "player", talent = 15}, -- Wraith Walk
        { spell = 219788, type = "buff", unit = "player"}, -- Ossuary
        { spell = 219809, type = "buff", unit = "player", talent = 3}, -- Tombstone
        { spell = 273947, type = "buff", unit = "player", talent = 5}, -- Hemostasis
        { spell = 274009, type = "buff", unit = "player", talent = 16}, -- Voracious
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target"}, -- Chains of Ice
        { spell = 48743, type = "debuff", unit = "player"}, -- Death Pact
        { spell = 51399, type = "debuff", unit = "target"}, -- Death Grip
        { spell = 56222, type = "debuff", unit = "target"}, -- Dark Command
        { spell = 55078, type = "debuff", unit = "target"}, -- Blood Plague
        { spell = 114556, type = "debuff", unit = "player", talent = 19 }, -- Purgatory
        { spell = 206930, type = "debuff", unit = "target"}, -- Heart Strike
        { spell = 206931, type = "debuff", unit = "target", talent = 2}, -- Blooddrinker
        { spell = 206940, type = "debuff", unit = "target", talent = 12}, -- Mark of Blood
        { spell = 221562, type = "debuff", unit = "target"}, -- Asphyxiate
        { spell = 273977, type = "debuff", unit = "target", talent = 13}, -- Grip of the Dead
      },
      icon = 237514
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 3714, type = "ability", buff = true}, -- Path of Frost
        { spell = 43265, type = "ability", buff = true, buffId = 188290, overlayGlow = true}, -- Death and Decay
        { spell = 45524, type = "ability", requiresTarget = true}, -- Chains of Ice
        { spell = 46585, type = "ability"}, -- Raise Dead
        { spell = 47528, type = "ability", requiresTarget = true}, -- Mind Freeze
        { spell = 47541, type = "ability"}, -- Death Coil
        { spell = 48265, type = "ability", buff = true}, -- Death's Advance
        { spell = 48707, type = "ability", buff = true}, -- Anti-Magic Shell
        { spell = 48792, type = "ability", buff = true}, -- Icebound Fortitude
        { spell = 48743, type = "ability"}, -- Death Pact
        { spell = 49028, type = "ability", buff = true}, -- Dancing Rune Weapon
        { spell = 49039, type = "ability", buff = true}, -- Lichborne
        { spell = 49998, type = "ability"}, -- Death Strike
        { spell = 49576, type = "ability", requiresTarget = true}, -- Death Grip
        { spell = 50842, type = "ability", charges = true}, -- Blood Boil
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 51052, type = "ability", buff = true}, -- Anti-Magic Zone
        { spell = 55233, type = "ability", buff = true}, -- Vampiric Blood
        { spell = 56222, type = "ability", requiresTarget = true, debuff = true}, -- Dark Command
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 108199, type = "ability", requiresTarget = true}, -- Gorefiend's Grasp
        { spell = 111673, type = "ability", requiresTarget = true, debuff = true, unit = "pet"}, -- Control Undead
        { spell = 194679, type = "ability", charges = true, buff = true}, -- Rune Tap
        { spell = 194844, type = "ability", buff = true, talent = 21}, -- Bonestorm
        { spell = 195182, type = "ability", buff = true, buffId = 195181, requiresTarget = true}, -- Marrowrend
        { spell = 195292, type = "ability", requiresTarget = true}, -- Death's Caress
        { spell = 206930, type = "ability", requiresTarget = true}, -- Heart Strike
        { spell = 206931, type = "ability", requiresTarget = true, debuff = true, talent = 2}, -- Blooddrinker
        { spell = 206940, type = "ability", requiresTarget = true, debuff = true, talent = 12}, -- Mark of Blood
        { spell = 212552, type = "ability", buff = true, talent = 15}, -- Wraith Walk
        { spell = 221699, type = "ability", talent = 9}, -- Blood Tap
        { spell = 219809, type = "ability", usable = true, buff = true, talent = 3}, -- Tombstone
        { spell = 221562, type = "ability", debuff = true, requiresTarget = true}, -- Asphyxiate
        { spell = 274156, type = "ability", talent = 6}, -- Consumption
        { spell = 316239, type = "ability", requiresTarget = true}, -- Heart Strike
        { spell = 327574, type = "ability", usable = true}, -- Sacrificial Pact
      },
      icon = 136120
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
        { spell = 47476, type="ability", pvptalent = 9, titleSuffix = L["cooldown"]},-- Strangulate
        { spell = 47476, type="debuff", unit = "target", pvptalent = 9, titleSuffix = L["buff"]},-- Strangulate
        { spell = 77606, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Dark Simulacrum
        { spell = 77606, type="debuff", unit = "target", pvptalent = 2, titleSuffix = L["debuff"]},-- Dark Simulacrum
        { spell = 77616, type="buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"]},-- Dark Simulacrum
        { spell = 199721, type="debuff", unit = "target", pvptalent = 5},-- Decomposing Aura
        { spell = 203173, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Death Chain
        { spell = 203173, type="debuff", unit = "target", pvptalent = 6, titleSuffix = L["buff"]},-- Death Chain
        { spell = 206891, type="debuff", unit = "target", pvptalent = 1},-- Murderous Intent
        { spell = 207018, type="ability", pvptalent = 1},-- Murderous Intent
        { spell = 212610, type="debuff", unit = "target", pvptalent = 10},-- Walking Dead
        { spell = 214968, type="debuff", unit = "target", pvptalent = 11},-- Necrotic Aura
        { spell = 233411, type="ability", pvptalent = 8, titleSuffix = L["cooldown"]},-- Blood for Blood
        { spell = 233411, type="buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"]},-- Blood for Blood
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 47568, type = "buff", unit = "player"}, -- Empower Rune Weapon
        { spell = 48265, type = "buff", unit = "player"}, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player"}, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player"}, -- Icebound Fortitude
        { spell = 49039, type = "buff", unit = "player"}, -- Lichborne
        { spell = 51124, type = "buff", unit = "player"}, -- Killing Machine
        { spell = 51271, type = "buff", unit = "player"}, -- Pillar of Frost
        { spell = 53365, type = "buff", unit = "player"}, -- Unholy Strength
        { spell = 59052, type = "buff", unit = "player"}, -- Rime
        { spell = 145629, type = "buff", unit = "player"}, -- Anti-Magic Zone
        { spell = 152279, type = "buff", unit = "player", talent = 21}, -- Breath of Sindragosa
        { spell = 178819, type = "buff", unit = "player" }, -- Dark Succor
        { spell = 194879, type = "buff", unit = "player", talent = 2}, -- Icy Talons
        { spell = 196770, type = "buff", unit = "player"}, -- Remorseless Winter
        { spell = 207203, type = "buff", unit = "player", talent = 13}, -- Frost Shield
        { spell = 211805, type = "buff", unit = "player", talent = 16}, -- Gathering Storm
        { spell = 212552, type = "buff", unit = "player", talent = 14}, -- Wraith Walk
        { spell = 253595, type = "buff", unit = "player", talent = 1}, -- Inexorable Assault
        { spell = 281209, type = "buff", unit = "player", talent = 3}, -- Cold Heart
        { spell = 321995, type = "buff", unit = "player", talent = 17}, -- Hypothermic Presence
      },
      icon = 135305
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target"}, -- Chains of Ice
        { spell = 48743, type = "debuff", unit = "player"}, -- Death Pact
        { spell = 51714, type = "debuff", unit = "target"}, -- Razorice
        { spell = 55095, type = "debuff", unit = "target"}, -- Frost Fever
        { spell = 56222, type = "debuff", unit = "target"}, -- Dark Command
        { spell = 207167, type = "debuff", unit = "target", talent = 9}, -- Blinding Sleet
        { spell = 211793, type = "debuff", unit = "target"}, -- Remorseless Winter

      },
      icon = 237522
    },
    [3] = {
      title = L["Abilities"],
      args = {
        { spell = 3714, type = "ability", buff = true}, -- Path of Frost
        { spell = 43265, type = "ability"}, -- Death and Decay
        { spell = 45524, type = "ability", requiresTarget = true, debuff = true}, -- Chains of Ice
        { spell = 46585, type = "ability"}, -- Raise Dead
        { spell = 47528, type = "ability", requiresTarget = true}, -- Mind Freeze
        { spell = 47541, type = "ability", requiresTarget = true}, -- Death Coil
        { spell = 47568, type = "ability", buff = true}, -- Empower Rune Weapon
        { spell = 48265, type = "ability", buff = true}, -- Death's Advance
        { spell = 48707, type = "ability", buff = true}, -- Anti-Magic Shell
        { spell = 48743, type = "ability", debuff = true, unit = "player", talent = 15}, -- Death Pact
        { spell = 48792, type = "ability", buff = true}, -- Icebound Fortitude
        { spell = 49020, type = "ability", requiresTarget = true, overlayGlow = true}, -- Obliterate
        { spell = 49143, type = "ability", requiresTarget = true}, -- Frost Strike
        { spell = 49576, type = "ability", requiresTarget = true}, -- Death Grip
        { spell = 49039, type = "ability", buff = true}, -- Lichborne
        { spell = 49184, type = "ability", requiresTarget = true, overlayGlow = true}, -- Howling Blast
        { spell = 49998, type = "ability"}, -- Death Strike
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 51052, type = "ability", buff = true}, -- Anti-Magic Zone
        { spell = 51271, type = "ability", buff = true}, -- Pillar of Frost
        { spell = 56222, type = "ability", requiresTarget = true, debuff = true}, -- Dark Command
        { spell = 57330, type = "ability", talent = 6}, -- Horn of Winter
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 108194, type = "ability", debuff = true}, -- Asphyxiate
        { spell = 111673, type = "ability", requiresTarget = true, debuff = true, unit = "pet"}, -- Control Undead
        { spell = 152279, type = "ability", buff = true, talent = 21}, -- Breath of Sindragosa
        { spell = 194913, type = "ability"}, -- Glacial Advance
        { spell = 196770, type = "ability", buff = true}, -- Remorseless Winter
        { spell = 207167, type = "ability", talent = 9}, -- Blinding Sleet
        { spell = 207230, type = "ability", overlayGlow = true, talent = 12}, -- Frostscythe
        { spell = 212552, type = "ability", buff = true, talent = 14}, -- Wraith Walk
        { spell = 279302, type = "ability"}, -- Frostwyrm's Fury
        { spell = 316239, type = "ability", usable = true}, -- Rune Strike
        { spell = 321995, type = "ability", buff = true}, -- Hypothermic Presence
        { spell = 327574, type = "ability", usable = true}, -- Sacrificial Pact
      },
      icon = 135372
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
        { spell = 77606, type="ability", pvptalent = 10, titleSuffix = L["cooldown"]},-- Dark Simulacrum
        { spell = 77606, type="debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]},-- Dark Simulacrum
        { spell = 77616, type="buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]},-- Dark Simulacrum
        { spell = 204206, type="debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"]},-- Chill Streak
        { spell = 213726, type="debuff", unit = "player", pvptalent = 9},-- Cadaverous Pallor
        { spell = 214968, type="debuff", unit = "target", pvptalent = 5},-- Necrotic Aura
        { spell = 228579, type="buff", unit = "target", pvptalent = 1},-- Heartstop Aura
        { spell = 233395, type="debuff", unit = "target", pvptalent = 2},-- Deathchill
        { spell = 233397, type="debuff", unit = "target", pvptalent = 3},-- Delirium
        { spell = 287254, type="debuff", unit = "target", pvptalent = 7, titleSuffix = L["stun debuff"]},-- Dead of Winter
        { spell = 289959, type="debuff", unit = "target", pvptalent = 7, titleSuffix = L["slow debuff"]},-- Dead of Winter
        { spell = 288977, type="ability", pvptalent = 6, titleSuffix = L["cooldown"]},-- Transfusion
        { spell = 288977, type="buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]},-- Transfusion
        { spell = 305392, type="ability", pvptalent = 4, titleSuffix = L["cooldown"]},-- Chill Streak
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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
        { spell = 42650, type = "buff", unit = "player"}, -- Army of the Dead
        { spell = 48265, type = "buff", unit = "player"}, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player"}, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player"}, -- Icebound Fortitude
        { spell = 51460, type = "buff", unit = "player"}, -- Runic Corruption
        { spell = 53365, type = "buff", unit = "player"}, -- Unholy Strength
        { spell = 63560, type = "buff", unit = "pet"}, -- Dark Transformation
        { spell = 81340, type = "buff", unit = "player"}, -- Sudden Doom
        { spell = 115989, type = "buff", unit = "player", talent = 6}, -- Unholy Blight
        { spell = 178819, type = "buff", unit = "player" }, -- Dark Succor
        { spell = 188290, type = "buff", unit = "player"}, -- Death and Decay
        { spell = 207289, type = "buff", unit = "player", talent = 21}, -- Unholy Frenzy
        { spell = 212552, type = "buff", unit = "player", talent = 14}, -- Wraith Walk
        { spell = 319255, type = "buff", unit = "player", talent = 17}, -- Unholy Pact
      },
      icon = 136181
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target"}, -- Chains of Ice
        { spell = 56222, type = "debuff", unit = "target"}, -- Dark Command
        { spell = 91800, type = "debuff", unit = "target"}, -- Gnaw
        { spell = 108194, type = "debuff", unit = "target", talent = 9}, -- Asphyxiate
        { spell = 115994, type = "debuff", unit = "target", talent = 6}, -- Unholy Blight
        { spell = 191587, type = "debuff", unit = "target"}, -- Virulent Plague
        { spell = 194310, type = "debuff", unit = "target"}, -- Festering Wound
        { spell = 196782, type = "debuff", unit = "target"}, -- Outbreak
        { spell = 273977, type = "debuff", unit = "target"}, -- Grip of the Dead
        { spell = 343294, type = "debuff", unit = "target", talent = 12}, -- Soul Reaper
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
        { spell = 46585, type = "ability"}, -- Raise Dead
        { spell = 47468, type = "ability", requiresTarget = true}, -- Claw
        { spell = 47481, type = "ability", requiresTarget = true, debuff = true}, -- Gnaw
        { spell = 47484, type = "ability", requiresTarget = true}, -- Huddle
        { spell = 47528, type = "ability", requiresTarget = true}, -- Mind Freeze
        { spell = 47541, type = "ability", requiresTarget = true, usable = true, overlayGlow = true}, -- Death Coil
        { spell = 48265, type = "ability", buff = true}, -- Death's Advance
        { spell = 48707, type = "ability", buff = true}, -- Anti-Magic Shell
        { spell = 48743, type = "ability", debuff = true, unit = "player", talent = 15}, -- Death Pact
        { spell = 48792, type = "ability", buff = true}, -- Icebound Fortitude
        { spell = 49039, type = "ability", buff = true}, -- Lichborne
        { spell = 49206, type = "ability", requiresTarget = true, talent = 20}, -- Summon Gargoyle
        { spell = 49576, type = "ability", requiresTarget = true}, -- Death Grip
        { spell = 49998, type = "ability"}, -- Death Strike
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 51052, type = "ability", buff = true}, -- Anti-Magic Zone
        { spell = 55090, type = "ability", requiresTarget = true, talent = {1, 2}}, -- Scourge Strike
        { spell = 56222, type = "ability", requiresTarget = true, debuff = true}, -- Dark Command
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 63560, type = "ability", buff = true, unit = "pet"}, -- Dark Transformation
        { spell = 77575, type = "ability", requiresTarget = true, debuff = true, buffId = 191587}, -- Outbreak
        { spell = 108194, type = "ability", requiresTarget = true, debuff = true, talent = 9}, -- Asphyxiate
        { spell = 111673, type = "ability", requiresTarget = true, debuff = true, unit = "pet"}, -- Control Undead
        { spell = 115989, type = "ability", buff = true, talent = 6}, -- Unholy Blight
        { spell = 152280, type = "ability", buff = true, buffId = 188290, talent = 17}, -- Defile
        { spell = 207289, type = "ability", buff = true, talent = 21}, -- Unholy Frenzy
        { spell = 207311, type = "ability", requiresTarget = true, talent = 3}, -- Clawing Shadows
        { spell = 207317, type = "ability", overlayGlow = true}, -- Epidemic
        { spell = 212552, type = "ability", buff = true, talent = 14}, -- Wraith Walk
        { spell = 275699, type = "ability", usable = true, requiresTarget = true}, -- Apocalypse
        { spell = 316239, type = "ability", requiresTarget = true, debuff = true, buffId = 194310}, -- Festering Strike
        { spell = 327574, type = "ability", usable = true}, -- Sacrificial Pact
        { spell = 343294, type = "ability", debuff = true, talent = 12}, -- Sacrificial Pact
      },
      icon = 136144
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
        { spell = 77606, type="ability", pvptalent = 7, titleSuffix = L["cooldown"]},-- Dark Simulacrum
        { spell = 77606, type="debuff", unit = "target", pvptalent = 7, titleSuffix = L["debuff"]},-- Dark Simulacrum
        { spell = 77616, type="buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"]},-- Dark Simulacrum
        { spell = 199721, type="debuff", unit = "target", pvptalent = 9},-- Decomposing Aura
        { spell = 210128, type="ability", pvptalent = 1},-- Reanimation
        { spell = 213726, type="debuff", unit = "player", pvptalent = 5},-- Cadaverous Pallor
        { spell = 214968, type="buff", unit = "target", pvptalent = 10},-- Necrotic Aura
        { spell = 223829, type="debuff", unit = "target", pvptalent = 6},-- Necrotic Strike
        { spell = 288849, type="debuff", unit = "target", pvptalent = 4},-- Necromancer's Bargain
        { spell = 288853, type="ability", pvptalent = 3},-- Raise Abomination
        { spell = 288977, type="ability", pvptalent = 2, titleSuffix = L["cooldown"]},-- Transfusion
        { spell = 288977, type="buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"]},-- Transfusion
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [11] = {
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

---------------------------
--- Covenants
---------------------------
local covenants = {
  [4] = { -- Kyrian
    title = C_Covenants.GetCovenantData(1).name,
    icon = 3257748,
    args = {
      -- General Ability
      { spell = 324739, type = "ability"}, -- Summon Steward
      -- Soul Binds
      -- Pelgagos
      { spell = 328908, type = "buff", unit = "player"}, -- Combat Meditation
      { spell = 330896, type = "buff", unit = "player"}, -- Road of Trials
      { spell = 330749, type = "buff", unit = "player"}, -- Phial of Patience
      { spell = 328900, type = "buff", unit = "player"}, -- Let Go of the Past
      { spell = 352498, type = "buff", unit = "player"}, -- Better Together
      { spell = 352875, type = "buff", unit = "player"}, -- Path of the Devoted
      { spell = 352917, type = "buff", unit = "player"}, -- Newfound Resolve
      -- Kleia
      { spell = 331449, type = "buff", unit = "player"}, -- Valiant Strikes
      { spell = 334067, type = "buff", unit = "player"}, -- Mentorship
      { spell = 330752, type = "buff", unit = "player"}, -- Ascendant Phial
      { spell = 330927, type = "buff", unit = "player"}, -- Cleansing Rites
      { spell = 328925, type = "buff", unit = "player"}, -- Ever Forward
      { spell = 321759, type = "debuff", unit = "target"}, -- Bearer's Pursuit
      { spell = 330511, type = "buff", unit = "player"}, -- Pointed Courage
      { spell = 330859, type = "buff", unit = "player"}, -- Resonant Accolades
      { spell = 352720, type = "buff", unit = "player"}, -- Spear of the Archon
      { spell = 353192, type = "buff", unit = "player"}, -- Hope Springs Eternal
      { spell = 352981, type = "buff", unit = "player"}, -- Light the Path
      -- Forgelite Prime Mikanikos
      { spell = 332514, type = "buff", unit = "player"}, -- Bron's Call to Action
      { spell = 337697, type = "buff", unit = "player"}, -- Resilient Plumage
      { spell = 332505, type = "buff", unit = "player"}, -- Soulsteel Clamps
      { spell = 333943, type = "buff", unit = "player"}, -- Hammer of Genesis
      { spell = 332423, type = "debuff", unit = "target"}, -- Sparkling Driftglobe Core
      { spell = 352938, type = "buff", unit = "player", titleSuffix = L["Buff"]}, -- Soulglow Spectrometer
      { spell = 352939, type = "debuff", unit = "target", titleSuffix = L["Debuff"]}, -- Soulglow Spectrometer
      { spell = 352789, type = "buff", unit = "player"}, -- Reactive Retrofitting

      -- WARRIOR
      { spell = 307865, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "WARRIOR"}, -- Spear of Bastion
      { spell = 307871, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "WARRIOR"}, -- Spear of Bastion
      -- PALADIN
      { spell = 304971, type = "ability", class = "PALADIN"}, -- Divine Toll
      -- HUNTER
      { spell = 308491, type = "ability", titleSuffix = L["Cooldown"], class = "HUNTER"}, -- Resonating Arrow
      { spell = 308498, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "HUNTER"}, -- Resonating Arrow
      -- ROGUE
      { spell = 323547, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "ROGUE"}, -- Echoing Reprimand
      { spell = 323560, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "ROGUE"}, -- Echoing Reprimand
      -- PRIEST
      { spell = 325013, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "PRIEST"}, -- Boon of the Ascended
      { spell = 325013, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "PRIEST"}, -- Boon of the Ascended
      -- SHAMAN
      { spell = 324386, type = "ability", totem = true, titleSuffix = L["Cooldown"], class = "SHAMAN"}, -- Vesper Totem
      { spell = 324386, type = "totem", titleSuffix = L["Totem"], class = "SHAMAN"}, -- Vesper Totem
      -- MAGE
      { spell = 307443, type = "ability", titleSuffix = L["Cooldown"], class = "MAGE"}, -- Radiant Spark
      { spell = 307443, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "MAGE"}, -- Radiant Spark
      -- WARLOCK
      { spell = 312321, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "WARLOCK"}, -- Scouring Tithe
      { spell = 312321, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "WARLOCK"}, -- Scouring Tithe
      -- MONK
      { spell = 310454, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "MONK"}, -- Weapons of Order
      { spell = 310454, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "MONK"}, -- Weapons of Order
      -- DRUID
      { spell = 326434, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "DRUID"}, -- Kindred Spirits
      { spell = 326967, type = "buff", unit = "player", titleSuffix = L["Bonded Buff"], class = "DRUID"}, -- Kindred Spirits
      { spell = 327139, type = "buff", unit = "player", titleSuffix = L["Empowered Buff"], class = "DRUID"}, -- Kindred Spirits
      -- DEMONHUNTER
      { spell = 306830, type = "ability", class = "DEMONHUNTER"}, -- Elysian Decree
      -- DEATHKNIGHT
      { spell = 312202, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "DEATHKNIGHT"}, -- Shackle the Unworthy
      { spell = 312202, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "DEATHKNIGHT"}, -- Shackle the Unworthy
    }
  },
  [5] = { -- Venthyr
    title = C_Covenants.GetCovenantData(2).name,
    icon = 3257751,
    args = {
      -- General Ability
      { spell = 300728, type = "ability"}, -- Door of Shadows

      -- Soul Binds
      -- Nadjia the  Mistblade
      { spell = 331939, type = "buff", unit = "player"}, -- Thrillseeker
      { spell = 331937, type = "buff", unit = "player"}, -- Euphoria
      { spell = 338836, type = "debuff", unit = "target"}, -- Agent of Chaos
      { spell = 331868, type = "buff", unit = "player"}, -- Fancy Footwork
      { spell = 331934, type = "debuff", unit = "target"}, -- Adversary
      { spell = 352882, type = "buff", unit = "player"}, -- Sinful Preservation
      { spell = 354050, type = "debuff", unit = "target", titleSuffix = L["Slow"], exactSpellId = true}, -- Nimble Steps
      { spell = 354051, type = "debuff", unit = "target", titleSuffix = L["Root"], exactSpellId = true}, -- Nimble Steps
      { spell = 354054, type = "buff", unit = "player"}, -- Fatal Flaw
      -- Theotar the Mad Duke
      { spell = 336885, type = "buff", unit = "player"}, -- Soothing Shade
      { spell = 337470, type = "buff", unit = "target"}, -- Token of Appreciation
      { spell = 333218, type = "buff", unit = "player"}, -- Wasteland Propriety
      { spell = 353334, type = "buff", unit = "player"}, -- It's Always Tea Time
      { spell = 353365, type = "buff", unit = "player"}, -- Life is but an Appetizer
      { spell = 353266, type = "buff", unit = "player"}, -- The Mad Duke's Tea
      -- General Draven
      { spell = 333104, type = "buff", unit = "player"}, -- Move As One
      { spell = 321012, type = "buff", unit = "player"}, -- Enduring Gloom
      { spell = 333089, type = "buff", unit = "player"}, -- Hold Your Ground
      { spell = 332922, type = "buff", unit = "player"}, -- Superior Tactics
      { spell = 332842, type = "buff", unit = "player"}, -- Built for War
      { spell = 352802, type = "buff", unit = "player"}, -- Regenerative Stone Skin
      { spell = 353211, type = "buff", unit = "player"}, -- Intimidation Tactics
      { spell = 352858, type = "buff", unit = "player"}, -- Battlefield Presence

      -- WARRIOR
      { spell = 317320, type = "ability", titleSuffix = L["Ability"], class = "WARRIOR"}, -- Condemn
      { spell = 317491, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "WARRIOR"}, -- Condemned
      -- PALADIN
      { spell = 316958, type = "ability", class = "PALADIN"}, -- Ashen Hallow
      -- HUNTER
      { spell = 324149, type = "ability", titleSuffix = L["Cooldown"], class = "HUNTER"}, -- Flayed Shot
      { spell = 324149, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "HUNTER"}, -- Flayed Shot
      { spell = 324156, type = "buff", unit = "player", class = "HUNTER"}, -- Flayed Shot
      -- ROGUE
      { spell = 323654, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "ROGUE"}, -- Flagellation
      { spell = 323654, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "ROGUE"}, -- Flagellation
      { spell = 323654, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "ROGUE"}, -- Flagellation
      -- PRIEST
      { spell = 323673, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "PRIEST"}, -- Mindgames
      { spell = 323673, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "PRIEST"}, -- Mindgames
      -- SHAMAN
      { spell = 320674, type = "ability", class = "SHAMAN"}, -- Chain Harvest
      -- MAGE
      { spell = 314793, type = "ability", titleSuffix = L["Cooldown"], class = "MAGE"}, -- Mirrors of Torment
      { spell = 314793, type = "debuff", unit = "target", titleSuffix = L[" Debuff"], class = "MAGE"}, -- Mirrors of Torment
      { spell = 320035, type = "debuff", unit = "target", titleSuffix = L["Slow"], class = "MAGE"}, -- Mirrors of Torment
      -- WARLOCK
      { spell = 321792, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "WARLOCK"}, -- Impending Catastrophe
      { spell = 322170, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "WARLOCK"}, -- Impending Catastrophe
      -- MONK
      { spell = 326860, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "MONK"}, -- Fallen Order
      { spell = 326860, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "MONK"}, -- Fallen Order
      -- DRUID
      { spell = 323546, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "DRUID"}, -- Ravenous Frenzy
      { spell = 323546, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "DRUID"}, -- Ravenous Frenzy
      { spell = 323557, type = "debuff", unit = "player", titleSuffix = L["Stun Debuff"], class = "DRUID"}, -- Ravenous Frenzy
      -- DEMONHUNTER
      { spell = 317009, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "DEMONHUNTER"}, -- Sinful Brand
      { spell = 317009, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "DEMONHUNTER"}, -- Sinful Brand
      -- DEATHKNIGHT
      { spell = 311648, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "DEATHKNIGHT"}, -- Swarming Mist
      { spell = 311648, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "DEATHKNIGHT"}, -- Swarming Mist
    }
  },
  [6] = { -- Night Fae
    title = C_Covenants.GetCovenantData(3).name,
    icon = 3257750,
    args = {
      -- General Ability
      { spell = 310143, type = "ability", buff = true, titleSuffix = L["Cooldown"]}, -- Soulshape
      { spell = 310143, type = "buff", unit = "player", titleSuffix = L["Buff"]}, -- Soulshape

      -- Soul Binds
      -- Niya
      { spell = 342814, type = "buff", unit = "player"}, -- Grove Invigoration
      { spell = 321527, type = "buff", unit = "player"}, -- Swift Patrol
      { spell = 333526, type = "debuff", unit = "target"}, -- Niya's Tools: Burrs
      { spell = 321519, type = "debuff", unit = "target"}, -- Niya's Tools: Poison
      { spell = 321510, type = "buff", unit = "player"}, -- Niya's Tools: Herbs
      { spell = 352865, type = "buff", unit = "player"}, -- Called Shot
      { spell = 352857, type = "buff", unit = "player"}, -- Survivor's Rally
      { spell = 352881, type = "buff", unit = "player"}, -- Bonded Hearts
      -- Dreamweaver
      { spell = 320224, type = "buff", unit = "player"}, -- Podtender
      { spell = 320267, type = "buff", unit = "player"}, -- Soothing Voice
      { spell = 320212, type = "buff", unit = "player"}, -- Social Butterfly
      { spell = 320009, type = "buff", unit = "player"}, -- Empowered Chrysalis
      { spell = 319970, type = "buff", unit = "player"}, -- Faerie Dust
      { spell = 320235, type = "buff", unit = "player"}, -- Somnambulist
      { spell = 342774, type = "buff", unit = "player"}, -- Field of Blossoms

      { spell = 353472, type = "debuff", unit = "target"}, -- Cunning Dreams
      { spell = 353477, type = "buff", unit = "player"}, -- Waking Dreams
      { spell = 353353, type = "buff", unit = "target", titleSuffix = L["Debuff"]}, -- Dream Delver
      { spell = 353354, type = "debuff", unit = "target", titleSuffix = L["Buff"]}, -- Dream Delver
      -- Korayn
      { spell = 343594, type = "buff", unit = "player"}, -- Wild Hunt Tactics
      { spell = 325268, type = "buff", unit = "player"}, -- Horn of the Wild Hunt
      { spell = 325321, type = "debuff", unit = "target"}, -- Wild Hunt's Charge
      { spell = 325443, type = "buff", unit = "player"}, -- Get In Formation
      { spell = 325437, type = "debuff", unit = "target"}, -- Face Your Foes
      { spell = 325381, type = "buff", unit = "player"}, -- First Strike
      { spell = 325612, type = "buff", unit = "player"}, -- Hold the Line

      { spell = 353077, type = "debuff", unit = "target"}, -- Vorkai Ambush
      { spell = 353203, type = "buff", unit = "player"}, -- Hunt's Exhilaration

      { spell = 353286, type = "buff", unit = "player", titleSuffix = L["Initial Buff"], exactSpellId = true}, -- Wild Hunt Strategem
      { spell = 353793, type = "buff", unit = "target", titleSuffix = L["Buff"], exactSpellId = true}, -- Wild Hunt Strategem
      { spell = 353254, type = "debuff", unit = "target", titleSuffix = L["Debuff"]}, -- Wild Hunt Strategem


      -- WARRIOR
      { spell = 325886, type = "ability", class = "WARRIOR"}, -- Ancient Aftershock
      -- PALADIN
      { spell = 328620, type = "ability", titleSuffix = "Cooldown", class = "PALADIN"}, -- Blessing of Seasons
      { spell = 328620, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "PALADIN"}, -- Blessing of Summer
      { spell = 328622, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "PALADIN"}, -- Blessing of Autumn
      { spell = 328281, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "PALADIN"}, -- Blessing of Winter
      { spell = 328282, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "PALADIN"}, -- Blessing of Spring
      -- HUNTER
      { spell = 328231, type = "ability", titleSuffix = L["Cooldown"], class = "HUNTER"}, -- Wild Spirits
      { spell = 328275, type = "debuff", unit = "target", class = "HUNTER"}, -- Wild Mark
      -- ROGUE
      { spell = 328305, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "ROGUE"}, -- Sepsis
      { spell = 328305, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "ROGUE"}, -- Sepsis
      { spell = 347037, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "ROGUE"}, -- Sepsis
      -- PRIEST
      { spell = 327661, type = "ability", class = "PRIEST"}, -- Fae Guardians
      { spell = 327694, type = "buff", unit = "target", class = "PRIEST"}, -- Fae Guardians
      { spell = 327710, type = "buff", unit = "target", class = "PRIEST"}, -- Fae Guardians
      { spell = 342132, type = "debuff", unit = "target", class = "PRIEST"}, -- Fae Guardians
      -- SHAMAN
      { spell = 328923, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "SHAMAN"}, -- Fae Transfusion
      { spell = 328933, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "SHAMAN"}, -- Fae Transfusion
      -- MAGE
      { spell = 314791, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "MAGE"}, -- Shifting Power
      { spell = 314791, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "MAGE"}, -- Shifting Power
      -- WARLOCK
      { spell = 325640, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "WARLOCK"}, -- Soul Rot
      { spell = 325640, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "WARLOCK"}, -- Soul Rot
      -- MONK
      { spell = 327104, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "MONK"}, -- Faeline Stomp
      { spell = 327104, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "MONK"}, -- Faeline Stomp
      -- DRUID
      { spell = 323764, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "DRUID"}, -- Convoke the Spirits
      { spell = 323764, type = "buff", titleSuffix = L["Buff"], class = "DRUID"}, -- Convoke the Spirits
      -- DEMONHUNTER
      { spell = 323639, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "DEMONHUNTER"}, -- The Hunt
      { spell = 323802, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "DEMONHUNTER"}, -- The Hunt
      -- DEATHKNIGHT
      { spell = 324128, type = "ability", class = "DEATHKNIGHT"}, -- Death's Due
    }
  },
  [7] = { -- Necrolord
    title = C_Covenants.GetCovenantData(4).name,
    icon = 3257749,
    args = {
      -- General Ability
      { spell = 324631, type = "ability", buff = true, titleSuffix = L["Cooldown"]}, -- Fleshcraft
      { spell = 324867, type = "buff", unit = "player", titleSuffix = L["Buff"]}, -- Fleshcraft
      -- Plague Deviser Marileth
      { spell = 323510, type = "buff", unit = "player"}, -- Volatile Solvent: Undead
      { spell = 323491, type = "buff", unit = "player"}, -- Volatile Solvent: Humanoid
      { spell = 323500, type = "buff", unit = "player"}, -- Volatile Solvent: Demon
      { spell = 323506, type = "buff", unit = "player"}, -- Volatile Solvent: Giant
      { spell = 323497, type = "buff", unit = "player"}, -- Volatile Solvent: Aberration
      { spell = 323502, type = "buff", unit = "player"}, -- Volatile Solvent: Dragonkin
      { spell = 323504, type = "buff", unit = "player"}, -- Volatile Solvent: Elemental
      { spell = 323507, type = "buff", unit = "player"}, -- Volatile Solvent: Mechanical
      { spell = 323498, type = "buff", unit = "player"}, -- Volatile Solvent: Beast
      { spell = 323385, type = "buff", unit = "player"}, -- Ooz's Frictionless Coating
      { spell = 323396, type = "buff", unit = "player"}, -- Bloop's Wanderlust
      { spell = 323416, type = "debuff", unit = "target"}, -- Plaguey's Preemptive Strike
      { spell = 323524, type = "buff", unit = "player"}, -- Ultimate Form
      { spell = 352561, type = "debuff", unit = "player"}, -- Undulating Maneuvers
      -- Emeni
      { spell = 328210, type = "buff", unit = "player"}, -- Emeni's Magnificent Skin
      { spell = 324523, type = "buff", unit = "player"}, -- Cartilaginous Legs
      { spell = 324463, type = "buff", unit = "player"}, -- Gristled Toes
      { spell = 324242, type = "buff", unit = "player"}, -- Gnashing Chompers
      { spell = 324263, type = "debuff", unit = "target"}, -- Sulfuric Emission
      { spell = 351913, type = "buff", unit = "player", exactSpellId = true, titleSuffix = L["Preparation"]}, -- Sole Slough
      { spell = 351915, type = "buff", unit = "player", exactSpellId = true, titleSuffix = L["Sprint"]}, -- Sole Slough
      { spell = 351921, type = "buff", unit = "player"}, -- Resilient Stitching

      -- Bonesmith Heirmir
      { spell = 327140, type = "buff", unit = "player"}, -- Forgeborne Reveries
      { spell = 326939, type = "debuff", unit = "target"}, -- Serrated Spaulders
      { spell = 327852, type = "buff", unit = "player"}, -- Runeforged Spurs
      { spell = 327159, type = "buff", unit = "player"}, -- Heirmir's Arsenal: Gorestompers
      { spell = 327066, type = "buff", unit = "player"}, -- Marrowed Gemstone Charging
      { spell = 327069, type = "buff", unit = "player"}, -- Marrowed Gemstone Enhancement
      { spell = 326946, type = "buff", unit = "player"}, -- Heirmir's Arsenal: Ravenous Pendant
      { spell = 351414, type = "buff", unit = "player"}, -- Carver's Eye
      { spell = 351433, type = "buff", unit = "player"}, -- Waking Bone Breastplate

      -- WARRIOR
      { spell = 324143, type = "ability", class = "WARRIOR"}, -- Conqueror's Banner
      { spell = 343672, type = "buff", unit = "player", class = "WARRIOR"}, -- Conqueror's Frenzy
      { spell = 325787, type = "buff", unit = "player", class = "WARRIOR"}, -- Glory
      -- PALADIN
      { spell = 328204, type = "ability", titleSuffix = L["Cooldown"], class = "PALADIN"}, -- Conqueror's Banner
      { spell = 328204, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "PALADIN"}, -- Glory
      -- HUNTER
      { spell = 325028, type = "ability", titleSuffix = L["Cooldown"], class = "HUNTER"}, -- Death Chakram
      -- ROGUE
      { spell = 328547, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "ROGUE"}, -- Serrated Bone Spike
      { spell = 324073, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "ROGUE"}, -- Serrated Bone Spike
      -- PRIEST
      { spell = 324724, type = "ability", debuff = true, class = "PRIEST"}, -- Unholy Nova
      { spell = 325203, type = "debuff", unit = "target", class = "PRIEST"}, -- Unholy Nova
      -- SHAMAN
      { spell = 326059, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "SHAMAN"}, -- Primordial Wave
      { spell = 327164, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "SHAMAN"}, -- Primordial Wave
      -- MAGE
      { spell = 324220, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "MAGE"}, -- Shifting Power
      { spell = 324220, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "MAGE"}, -- Deathborne
      -- WARLOCK
      { spell = 325289, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "WARLOCK"}, -- Decimating Bolt
      { spell = 325299, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "WARLOCK"}, -- Decimating Bolt
      -- MONK
      { spell = 325216, type = "ability", debuff = true, titleSuffix = L["Cooldown"], class = "MONK"}, -- Bonedust Brew
      { spell = 325216, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "MONK"}, -- Bonedust Brew
      -- DRUID
      { spell = 325727, type = "ability", titleSuffix = L["Cooldown"], class = "DRUID"}, -- Adaptive Swarm
      { spell = 325748, type = "buff", unit = "player", titleSuffix = L["Bonded Buff"], class = "DRUID"}, -- Adaptive Swarm
      { spell = 325733, type = "debuff", unit = "target", titleSuffix = L["Debuff"], class = "DRUID"}, -- Adaptive Swarm
      -- DEMONHUNTER
      { spell = 329554, type = "ability", titleSuffix = L["Cooldown"], class = "DEMONHUNTER"}, -- Fodder to the Flame
      { spell = 347765, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "DEMONHUNTER"}, -- Fodder to the Flame
      -- DEATHKNIGHT
      { spell = 315443, type = "ability", buff = true, titleSuffix = L["Cooldown"], class = "DEATHKNIGHT"}, -- Abomination Limb
      { spell = 315443, type = "buff", unit = "player", titleSuffix = L["Buff"], class = "DEATHKNIGHT"}, -- Abomination Limb
    }
  }
}

-- Add covenant load option
for key, covenantData in pairs(covenants) do
  for _, entry in ipairs(covenantData.args) do
    entry.covenant = key - 3
  end
end

-- Copy to main templates table
for class, classData in pairs(templates.class) do
  for spec, specData in ipairs(classData) do
    for key, covenantData in pairs(covenants) do
      specData[key].title = covenantData.title
      specData[key].icon = covenantData.icon
      specData[key].args = {}
      for _, entry in ipairs(covenantData.args) do
        if not entry.class or class == entry.class then
          tinsert(specData[key].args, CopyTable(entry))
        end
      end
    end
  end
end

--------------------------
-- Conduits
--------------------------

local conduits = {
  WARRIOR = {
    { spell = 335234, type = "buff", unit = "player"}, -- Ashen Juggernaut
    { spell = 346574, type = "buff", unit = "player"}, -- Merciless Bonegrinder
    { spell = 339825, type = "buff", unit = "player"}, -- Show of Force
  },
  PALADIN = {
    { spell = 340147, type = "buff", unit = "player"}, -- Royal Decree
    { spell = 338788, type = "buff", unit = "player"}, -- Shielding Words
    { spell = 341741, type = "buff", unit = "player"}, -- Enkindled Spirit
    { spell = 344067, type = "debuff", unit = "target"}, -- Expurgation
    { spell = 339376, type = "debuff", unit = "target"}, -- Truth's Wake
    { spell = 339990, type = "buff", unit = "player"}, -- Untempered Dedication
    { spell = 340007, type = "debuff", unit = "target"}, -- Vengeful Shock
    { spell = 339664, type = "buff", unit = "player"}, -- Virtuous Command
  },
  HUNTER = {
    { spell = 339654, type = "debuff", unit = "target"}, -- Vengeful Shock
    { spell = 339400, type = "buff", unit = "player"}, -- Rejuvenating Wind
    { spell = 339461, type = "buff", unit = "player"}, -- Resilience of the Hunter
    { spell = 339929, type = "buff", unit = "player"}, -- Brutal Projectiles
    { spell = 341401, type = "buff", unit = "player"}, -- Flame Infusion
    { spell = 341223, type = "buff", unit = "player"}, -- Strength of the Pack
  },
  ROGUE = {
    { spell = 341533, type = "buff", unit = "player"}, -- Fade to Nothing
    { spell = 341530, type = "buff", unit = "player"}, -- Cloaked in Shadows
    { spell = 341550, type = "buff", unit = "player"}, -- Deeper Daggers
    { spell = 341572, type = "buff", unit = "player"}, -- Perforated Veins
  },
  PRIEST = {
    { spell = 337956, type = "debuff", unit = "target"}, -- Mental Recover
    { spell = 337716, type = "buff", unit = "player"}, -- Charitable Soul
    { spell = 337749, type = "buff", unit = "player"}, -- Light's Inspiration
    { spell = 337661, type = "buff", unit = "player"}, -- Translucent Image
    { spell = 343144, type = "buff", unit = "player"}, -- Dissonant Echoes
    { spell = 338333, type = "buff", unit = "player"}, -- Mind Devourer
    { spell = 337948, type = "buff", unit = "player"}, -- Resonant Words

    { spell = 345452, type = "debuff", unit = "target", covenant = 3}, -- Wrathful Faerie Fermata
    { spell = 345451, type = "buff", unit = "player", covenant = 3}, -- Guardian Faerie Fermata
    { spell = 345453, type = "buff", unit = "player", covenant = 3}, -- Benevolent Faerie Fermata
  },
  SHAMAN = {
    { spell = 338055, type = "debuff", unit = "target"}, -- Crippling Hex
    { spell = 338036, type = "buff", unit = "player"}, -- Thunderous Paws
    { spell = 337984, type = "buff", unit = "player"}, -- Vital Accretion
    { spell = 338344, type = "buff", unit = "player"}, -- Heavy Rainfall
    { spell = 338340, type = "buff", unit = "player"}, -- Swirling Currents
  },
  MAGE = {
    { spell = 337278, type = "buff", unit = "player"}, -- Incantation of Swiftness
    { spell = 337299, type = "buff", unit = "player"}, -- Tempest Barrier
    { spell = 336832, type = "buff", unit = "player"}, -- Infernal Cascade
    { spell = 337090, type = "buff", unit = "player", covenant = 4}, -- Siphoned Malice
  },
  WARLOCK = {
    { spell = 339412, type = "buff", unit = "player"}, -- Demonic Momentum
    { spell = 339298, type = "buff", unit = "player"}, -- Accrued Vitality
    { spell = 339784, type = "buff", unit = "player"}, -- Tyrant's Soul
  },
  MONK = {
    { spell = 336891, type = "debuff", unit = "target"}, -- Dizzying Tumble
    { spell = 336887, type = "debuff", unit = "target"}, -- Lingering Numbness
    { spell = 337079, type = "buff", unit = "player"}, -- Swift Transference
    { spell = 336874, type = "buff", unit = "player"}, -- Fortifying Ingredients
  },
  DRUID = {
    { spell = 341448, type = "buff", unit = "target"}, -- Born Anew
    { spell = 340546, type = "buff", unit = "player"}, -- Tireless Pursuit
    { spell = 340541, type = "buff", unit = "player"}, -- Ursine Vigor
    { spell = 340613, type = "buff", unit = "player"}, -- Savage Combatant
    { spell = 340698, type = "buff", unit = "player"}, -- Sudden Ambush
  },
  DEMONHUNTER = {
    { spell = 339051, type = "debuff", unit = "target"}, -- Demonic Parole
    { spell = 338804, type = "buff", unit = "player"}, -- Felfire Haste
    { spell = 339589, type = "debuff", unit = "target"}, -- Demon Muzzle
    { spell = 339424, type = "buff", unit = "player"}, -- Soul Furnace
  },
  DEATHKNIGHT = {
    { spell = 338093, type = "buff", unit = "player"}, -- Fleeting Wind
    { spell = 338312, type = "debuff", unit = "target"}, -- Unending Grip
    { spell = 338523, type = "debuff", unit = "target"}, -- Debilitating Malady
    { spell = 337936, type = "buff", unit = "player"}, -- Eradicating Blow
    { spell = 338501, type = "buff", unit = "player"}, -- Unleashed Frenzy
  },
  ALL = {
    { spell = 357972, type = "buff", unit = "player"}, -- Adaptive Armor Fragment
  }
}


for class, classData in pairs(templates.class) do
  for spec, specData in ipairs(classData) do
    specData[8].title = L["Conduits"]
    specData[8].icon = 3528287
    specData[8].args = {}
    for _, entry in ipairs(conduits[class]) do
      tinsert(specData[8].args, CopyTable(entry))
    end
    for _, entry in ipairs(conduits.ALL) do
      tinsert(specData[8].args, CopyTable(entry))
    end
  end
end

--------------------------------------------
--- Legendaries
--------------------------------------------
local generalLegendaries = {
  { spell = 347458, type = "buff", unit = "player", bonusItemId = 7100}, -- Echo of Eonar
  { spell = 339445, type = "buff", unit = "player", bonusItemId = 7102}, -- Norgannon's Sagacity
  { spell = 339463, type = "buff", unit = "player", bonusItemId = 7103}, -- Sephuz's Proclamation
  { spell = 339507, type = "buff", unit = "player", bonusItemId = 7104}, -- Stable Phantasma Lure
  { spell = 339970, type = "buff", unit = "player", bonusItemId = 7105}, -- Third Eye of the Jailer
  { spell = 338746, type = "buff", unit = "player", bonusItemId = 7106}, -- Vitality Sacrifice
}
local classLegendaries = {
  WARRIOR = {
    { spell = 346369, type = "buff", unit = "player", bonusItemId = 6960}, -- Battlelord
    { spell = 346369, type = "debuff", unit = "target", bonusItemId = 6961}, -- Exploiter
    { spell = 335558, type = "buff", unit = "player", bonusItemId = 6963}, -- Cadence of Fujieda
    { spell = 335597, type = "buff", unit = "player", bonusItemId = 6966}, -- Will of the Berserker
    { spell = 335734, type = "buff", unit = "player", bonusItemId = 6969}, -- Reprisal
    { spell = 311193, type = "buff", unit = "player", bonusItemId = 7730}, -- Elysian Might
  },
  PALADIN = {
    { spell = 337682, type = "buff", unit = "player", bonusItemId = 7056}, -- The Magistrate's Judgment
    { spell = 337747, type = "buff", unit = "player", bonusItemId = 7055}, -- Blessing of Dawn
    { spell = 337757, type = "buff", unit = "player", bonusItemId = 7055}, -- Blessing of Dusk
    { spell = 340459, type = "buff", unit = "player", bonusItemId = 7128}, -- Maraad's Dying Breath
    { spell = 337824, type = "buff", unit = "target", bonusItemId = 7059}, -- Shock Barrier
    { spell = 337848, type = "buff", unit = "player", bonusItemId = 7062}, -- Bulwark of Righteous Fury
    { spell = 337315, type = "buff", unit = "player", bonusItemId = 7066}, -- Relentless Inquisitor
    { spell = 345046, type = "buff", unit = "player", bonusItemId = 7065}, -- Vanguard's Momentum
    { spell = 355455, type = "buff", unit = "player", bonusItemId = 7679}, -- Divine Resonance
    { spell = 355567, type = "buff", unit = "player", bonusItemId = 7702}, -- Equinox
  },
  HUNTER = {
    { spell = 336744, type = "buff", unit = "player", bonusItemId = 7004}, -- Nesingwary's Trapping Apparatus
    { spell = 336746, type = "debuff", unit = "target", bonusItemId = 7005}, -- Soulforge Embers
    { spell = 336826, type = "buff", unit = "player", bonusItemId = 7008}, -- Flamewaker's Cobra Sting
    { spell = 336892, type = "buff", unit = "player", bonusItemId = 7013}, -- Secrets of the Unblinking Vigil
    { spell = 336908, type = "buff", unit = "player", bonusItemId = 7018}, -- Butcher's Bone Fragments
    { spell = 273286, type = "debuff", unit = "target", bonusItemId = 7017}, -- Latent Poison
    { spell = 356263, type = "buff", unit = "player", bonusItemId = 7714}, -- Pact of the Soulstalkers
    { spell = 356620, type = "debuff", unit = "target", bonusItemId = 7717}, -- Pouch of Razor Fragments
  },
  ROGUE = {
    { spell = 23580, type = "debuff", unit = "target", bonusItemId = 7113}, -- Bloodfang
    { spell = 340094, type = "buff", unit = "player", bonusItemId = 7111}, -- Master Assassin's Mark
    { spell = 340587, type = "buff", unit = "player", bonusItemId = 7122}, -- Concealed Blunderbuss
    { spell = 340573, type = "buff", unit = "player", bonusItemId = 7119}, -- Greenskin's Wickers
    { spell = 340580, type = "buff", unit = "player", bonusItemId = 7120}, -- Guile Charm
    { spell = 341202, type = "buff", unit = "player", bonusItemId = 7126}, -- Deathly Shadows
    { spell = 340600, type = "buff", unit = "player", bonusItemId = 7123}, -- Finality: Eviscerate
    { spell = 340601, type = "buff", unit = "player", bonusItemId = 7123}, -- Finality: Rupture
    { spell = 340603, type = "buff", unit = "player", bonusItemId = 7123}, -- Finality: Black Powder
    { spell = 341134, type = "buff", unit = "player", bonusItemId = 7125}, -- The Rotten
  },
  PRIEST = {
    { spell = 341824, type = "buff", unit = "player", bonusItemId = 7161}, -- Measured Contemplation
    { spell = 336267, type = "buff", unit = "player", bonusItemId = 6974}, -- Flash Concentration
    { spell = 357028, type = "buff", unit = "player", bonusItemId = 0000}, -- Shadow Word: Manipulation
  },
  SHAMAN = {
    { spell = 329771, type = "buff", unit = "player", bonusItemId = 6988}, -- Chains of Devastation
    { spell = 336217, type = "buff", unit = "player", bonusItemId = 6991}, -- Echoes of Great Sundering
    { spell = 347349, spellId = 347349, type = "debuff", unit = "player", titleSuffix = L["Debuff"], bonusItemId = 6990}, -- Elemental Equilibrium
    { spell = 336731, spellId = 336731, type = "buff", unit = "player", titleSuffix = L["Frost"], bonusItemId = 6990}, -- Elemental Equilibrium
    { spell = 336732, spellId = 336732, type = "buff", unit = "player", titleSuffix = L["Nature"], bonusItemId = 6990}, -- Elemental Equilibrium
    { spell = 336733, spellId = 336733, type = "buff", unit = "player", titleSuffix = L["Fire"], bonusItemId = 6990}, -- Elemental Equilibrium
    { spell = 336065, type = "buff", unit = "player", bonusItemId = 6992}, -- Windspeaker's Lava Resurgence
    { spell = 335903, type = "buff", unit = "player", bonusItemId = 6993}, -- Doom Winds
    { spell = 335901, type = "buff", unit = "player", bonusItemId = 6994}, -- Legacy of the Frost Witch
    { spell = 335896, type = "buff", unit = "player", bonusItemId = 6996}, -- Primal Lava Actuators
    { spell = 335894, type = "buff", unit = "player", bonusItemId = 6997}, -- Jonat's Natural Focus
    { spell = 335892, type = "buff", unit = "player", bonusItemId = 6998}, -- Spiritwalker's Tidal Totem
    { spell = 358945, type = "buff", unit = "player", bonusItemId = 7708}, -- Seeds of Rampant Growth
    { spell = 354648, type = "buff", unit = "player", bonusItemId = 7570}, -- Splintered Elements
  },
  MAGE = {
    { spell = 327371, type = "buff", unit = "player", bonusItemId = 6832}, -- Disciplinary Command
    { spell = 327495, type = "buff", unit = "player", bonusItemId = 6831}, -- Expanded Potential
    { spell = 332777, type = "buff", unit = "player", bonusItemId = 6926}, -- Arcane Harmony/Infinity
    { spell = 332934, type = "buff", unit = "player", bonusItemId = 6928}, -- Siphon Storm
    { spell = 333049, type = "buff", unit = "player", bonusItemId = 6931}, -- Fevered Incantation
    { spell = 333100, type = "buff", unit = "player", bonusItemId = 6932}, -- Firestorm
    { spell = 333170, spellId = 333170, type = "buff", unit = "player", titleSuffix = L["Build Up"], bonusItemId = 6933}, -- Molten Skyfall
    { spell = 333182, spellId = 333182, type = "buff", unit = "player",  titleSuffix = L["Meteor Ready"], bonusItemId = 6933}, -- Molten Skyfall
    { spell = 333314, spellId = 333314, type = "buff", unit = "player", titleSuffix = L["Build Up"], bonusItemId = 6934}, -- Sun King's Blessing
    { spell = 333315, spellId = 333315, type = "buff", unit = "player", titleSuffix = L["Combustion Ready"], bonusItemId = 6934}, -- Sun King's Blessing
    { spell = 327327, spellId = 327327, type = "buff", unit = "player", titleSuffix = L["Build Up"], bonusItemId = 6828}, -- Cold Front
    { spell = 327330, spellId = 327330, type = "buff", unit = "player",  titleSuffix = L["Meteor Ready"], bonusItemId = 6828}, -- Cold Front
    { spell = 327478, type = "buff", unit = "player", bonusItemId = 6829}, -- Freezing Winds
    { spell = 327509, type = "buff", unit = "player", bonusItemId = 6823}, -- Slick Ice
    { spell = 356881, type = "buff", unit = "player", bonusItemId = 7727}, -- Heart of the Fae
  },
  WARLOCK = {
    { spell = 337096, type = "buff", unit = "player", bonusItemId = 7028}, -- Pillars of the Dark Portal
    { spell = 337060, type = "buff", unit = "player", bonusItemId = 7027}, -- Relic of Demonic Synergy
    { spell = 337125, type = "buff", unit = "player", bonusItemId = 7031}, -- Malefic Wrath
    { spell = 337096, type = "debuff", unit = "target", bonusItemId = 7030}, -- Sacrolash's Dark Strike
    { spell = 337130, type = "buff", unit = "player", bonusItemId = 7032}, -- Wrath of Consumption
    { spell = 337161, type = "buff", unit = "player", bonusItemId = 7036}, -- Balespider's Burning Core
    { spell = 342997, type = "buff", unit = "player", bonusItemId = 7034}, -- Grim Inquisitor's Dread Calling
    { spell = 337139, type = "buff", unit = "player", bonusItemId = 7033}, -- Implosive Potential
    { spell = 337170, type = "buff", unit = "player", bonusItemId = 7029}, -- Madness of the Azj'Aqir
    { spell = 337164, type = "debuff", unit = "target", bonusItemId = 7034}, -- Grim Inquisitor's Dread Calling
    { spell = 356255, type = "buff", unit = "player", bonusItemId = 7710}, -- Languishing Soul Detritus
    { spell = 356342, type = "buff", unit = "player", bonusItemId = 7711}, -- Shard of Annihilation
    { spell = 356369, type = "buff", unit = "player", bonusItemId = 7712}, -- Decaying Soul Satchel
  },
  MONK = {
    { spell = 343249, type = "buff", unit = "player", bonusItemId = 7184}, -- Escape from Reality
    { spell = 338140, type = "buff", unit = "player", bonusItemId = 7076}, -- Charred Passions
    { spell = 337994, type = "buff", unit = "player", bonusItemId = 7078}, -- Mighty Pour/Celestial Infusion
    { spell = 347553, type = "buff", unit = "player", bonusItemId = 7075}, -- Ancient Teachings of the Monastery
    { spell = 337476, type = "buff", unit = "player", bonusItemId = 7074}, -- Clouded Focus
    { spell = 337476, type = "buff", unit = "player", bonusItemId = 7072}, -- Tear of Morning
    { spell = 337571, type = "buff", unit = "player", bonusItemId = 7068}, -- Jade Ignition/Chi Energy
    { spell = 337291, type = "buff", unit = "player", bonusItemId = 7069}, -- The Emperor's Capacitor
    { spell = 356773, type = "debuff", unit = "target", bonusItemId = 7721}, -- Faeline Harmony
  },
  DRUID = {
    { spell = 340060, type = "buff", unit = "player", bonusItemId = 7110}, -- Lycara's Fleeting Glimpse
    { spell = 340060, type = "buff", unit = "player", bonusItemId = 7107}, -- Balance of All Things
    { spell = 339797, type = "buff", unit = "player", bonusItemId = 7087}, -- Oneth's Clear Vision
    { spell = 338825, type = "buff", unit = "player", bonusItemId = 7088}, -- Primordial Arcanic Pulsar
    { spell = 340049, type = "buff", unit = "player", bonusItemId = 7108}, -- Timeworn Dreambinder
    { spell = 339140, type = "buff", unit = "player", bonusItemId = 7091}, -- Apex Predator's Craving
    { spell = 339142, type = "buff", unit = "player", bonusItemId = 7090}, -- Eye of Fearful Symmetry
    { spell = 189877, type = "buff", unit = "player", bonusItemId = 7096}, -- Memory of the Mother Tree
    { spell = 355779, type = "buff", unit = "player", bonusItemId = 7477}, -- Kindred Affinity
  },
  DEMONHUNTER = {
    { spell = 337567, type = "buff", unit = "player", bonusItemId = 7050}, -- Chaos Theory/Chaotic Blades
    { spell = 346264, type = "buff", unit = "player", bonusItemId = 7218}, -- Darker Nature
    { spell = 337542, type = "buff", unit = "player", bonusItemId = 7045}, -- Spirit of the Darkness Flame
    { spell = 337849, type = "buff", unit = "player", bonusItemId = 7052}, -- Fel Bombardment
    { spell = 355894, type = "buff", unit = "player", bonusItemId = 7699}, -- Blind Faith
    { spell = 355892, type = "buff", unit = "player", bonusItemId = 7698}, -- Blazing Slaughter
  },
  DEATHKNIGHT = {
    { spell = 332199, type = "buff", unit = "player", bonusItemId = 6954}, -- Phearomones
    { spell = 334526, type = "buff", unit = "player", bonusItemId = 6941}, -- Crimson Rune Weapon
    { spell = 334693, type = "debuff", unit = "target", bonusItemId = 6946}, -- Absolute Zero
    { spell = 334722, type = "buff", unit = "player", bonusItemId = 6948}, -- Grip of the Everlasting
    { spell = 353823, type = "debuff", unit = "target", bonusItemId = 7467}, -- Final Sentence
    { spell = 353546, type = "debuff", unit = "target", bonusItemId = 7458}, -- Abomination's Frenzy
  }
}

for class, classData in pairs(templates.class) do
  for spec, specData in ipairs(classData) do
    specData[9].title = L["Legendaries"]
    specData[9].icon = 463541
    specData[9].args = {}
    for _, entry in ipairs(generalLegendaries) do
      tinsert(specData[9].args, CopyTable(entry))
    end
    for _, entry in ipairs(classLegendaries[class]) do
      tinsert(specData[9].args, CopyTable(entry))
    end
  end
end

-- Shards of Domination
local shardsOfDomination = {
  title = L["Shards Of Domination"],
  icon = 1392550,
  args = {
    -- General Ability
    { spell = 356321, type = "buff", unit = "player"}, -- Unholy Aura
    { spell = 356329, type = "debuff", unit = "target"}, -- Scouring Touch
    { spell = 356043, type = "buff", unit = "player"}, -- Chaos Bane
    { spell = 356305, type = "buff", unit = "player"}, -- Accretion
    { spell = 356257, type = "buff", unit = "player"}, -- Frostrime
    { spell = 356364, type = "buff", unit = "player"}, -- Coldhearted
    { spell = 355735, type = "buff", unit = "player"}, -- Winds of Winter
    { spell = 355804, type = "debuff", unit = "target"}, -- Blood Link
  }
}

-- Copy to main templates table
for class, classData in pairs(templates.class) do
  for spec, specData in ipairs(classData) do
    specData[10].title = shardsOfDomination.title
    specData[10].icon = shardsOfDomination.icon
    specData[10].args = {}
    for _, entry in ipairs(shardsOfDomination.args) do
      tinsert(specData[10].args, CopyTable(entry))
    end
  end
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
  if (item.covenant) then
    item.load = item.load or {}
    item.load.use_covenant = true
    item.load.covenant = {
      single = item.covenant,
      multi = {}
    }
  end
  if (item.bonusItemId) then
    item.load = item.load or {}
    item.load.use_item_bonusid_equipped = true
    item.load.item_bonusid_equipped = tostring(item.bonusItemId)
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
