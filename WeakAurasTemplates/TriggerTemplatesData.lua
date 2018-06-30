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
        { spell = 248622, type = "buff", unit = "player", talent = 16}, -- In For The Kill
        { spell = 197690, type = "buff", unit = "player", talent = 12}, -- Defensive Stance
        { spell = 118038, type = "buff", unit = "player"}, -- Die by the Sword
        { spell = 6673, type = "buff", unit = "player"}, -- Battle Shout
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
      icon = 458972
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
      icon = 464973
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability"}, -- Charge
        { spell = 355, type = "ability"}, -- Taunt
        { spell = 845, type = "ability", talent = 15}, -- Cleave
        { spell = 5246, type = "ability"}, -- Intimidating Shout
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability"}, -- Pummel
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 7384, type = "ability"}, -- Overpower
        { spell = 12294, type = "ability"}, -- Mortal Strike
        { spell = 18499, type = "ability"}, -- Berserker Rage
        { spell = 57755, type = "ability"}, -- Heroic Throw
        { spell = 97462, type = "ability"}, -- Rallying Cry
        { spell = 107570, type = "ability", talent = 6}, -- Storm Bolt
        { spell = 107574, type = "ability", talent = 17}, -- Avatar
        { spell = 118038, type = "ability"}, -- Die by the Sword
        { spell = 152277, type = "ability", talent = 21}, -- Ravager
        { spell = 167105, type = "ability"}, -- Colossus Smash
        { spell = 202168, type = "ability"}, -- Impending Victory
        { spell = 212520, type = "ability", talent = 12}, -- Defensive Stance
        { spell = 227847, type = "ability"}, -- Bladestorm
        { spell = 260643, type = "ability", talent = 3}, -- Skullsplitter
        { spell = 260708, type = "ability"}, -- Sweeping Strikes
        { spell = 262161, type = "ability", talent = 14}, -- Warbreaker
        { spell = 262228, type = "ability", talent = 18}, -- Deadly Calm
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
        { spell = 6673, type = "buff", unit = "player"}, -- Battle Shout
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
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability"}, -- Charge
        { spell = 355, type = "ability"}, -- Taunt
        { spell = 1719, type = "ability"}, -- Recklessness
        { spell = 5246, type = "ability"}, -- Intimidating Shout
        { spell = 5308, type = "ability"}, -- Execute
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability"}, -- Pummel
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 18499, type = "ability"}, -- Berserker Rage
        { spell = 23881, type = "ability"}, -- Bloodthirst
        { spell = 46924, type = "ability", talent = 18}, -- Bladestorm
        { spell = 57755, type = "ability"}, -- Heroic Throw
        { spell = 85288, type = "ability"}, -- Raging Blow
        { spell = 97462, type = "ability"}, -- Rallying Cry
        { spell = 107570, type = "ability", talent = 6}, -- Storm Bolt
        { spell = 118000, type = "ability", talent = 17}, -- Dragon Roar
        { spell = 184364, type = "ability"}, -- Enraged Regeneration
        { spell = 202168, type = "ability", talent = 5}, -- Impending Victory
        { spell = 280772, type = "ability", talent = 21}, -- Siegebreaker

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
        { spell = 12975, type = "buff", unit = "player"}, -- Last Stand
        { spell = 202164, type = "buff", unit = "player", talent = 5}, -- Bounding Stride
        { spell = 18499, type = "buff", unit = "player"}, -- Berserker Rage
        { spell = 202573, type = "buff", unit = "player", talent = 17}, -- Vengeance: Revenge
        { spell = 871, type = "buff", unit = "player"}, -- Shield Wall
        { spell = 227744, type = "buff", unit = "player", talent = 21}, -- Ravager
        { spell = 202574, type = "buff", unit = "player", talent = 17}, -- Vengeance: Ignore Pain
        { spell = 6673, type = "buff", unit = "player"}, -- Battle Shout
        { spell = 132404, type = "buff", unit = "player"}, -- Shield Block
        { spell = 202602, type = "buff", unit = "player", talent = 1}, -- Into the Fray
        { spell = 97463, type = "buff", unit = "player"}, -- Rallying Cry
        { spell = 190456, type = "buff", unit = "player"}, -- Ignore Pain
        { spell = 23920, type = "buff", unit = "player"}, -- Spell Reflection
        { spell = 107574, type = "buff", unit = "player"}, -- Avatar
        { spell = 147833, type = "buff", unit = "target"}, -- Intervene
        { spell = 223658, type = "buff", unit = "target", talent = 6}, -- Safeguard

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
      title = L["Cooldowns"],
      args = {
        { spell = 355, type = "ability"}, -- Taunt
        { spell = 871, type = "ability"}, -- Shield Wall
        { spell = 1160, type = "ability"}, -- Demoralizing Shout
        { spell = 2565, type = "ability"}, -- Shield Block
        { spell = 5246, type = "ability"}, -- Intimidating Shout
        { spell = 6343, type = "ability"}, -- Thunder Clap
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability"}, -- Pummel
        { spell = 6572, type = "ability"}, -- Revenge
        { spell = 6673, type = "ability"}, -- Battle Shout
        { spell = 12975, type = "ability"}, -- Last Stand
        { spell = 18499, type = "ability"}, -- Berserker Rage
        { spell = 23920, type = "ability"}, -- Spell Reflection
        { spell = 23922, type = "ability"}, -- Shield Slam
        { spell = 46968, type = "ability"}, -- Shockwave
        { spell = 57755, type = "ability"}, -- Heroic Throw
        { spell = 97462, type = "ability"}, -- Rallying Cry
        { spell = 107570, type = "ability", talent = 15}, -- Storm Bolt
        { spell = 107574, type = "ability"}, -- Avatar
        { spell = 118000, type = "ability", talent = 9}, -- Dragon Roar
        { spell = 198304, type = "ability"}, -- Intercept
        { spell = 202168, type = "ability", talent = 3}, -- Impending Victory
        { spell = 228920, type = "ability", talent = 21}, -- Ravager

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
      icon = 236254
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 204242, type = "debuff", unit = "target"}, -- Consecration
        { spell = 105421, type = "debuff", unit = "target", talent = 9}, -- Blinding Light
        { spell = 853, type = "debuff", unit = "target"}, -- Hammer of Justice
        { spell = 214222, type = "debuff", unit = "target"}, -- Judgment
        { spell = 196941, type = "debuff", unit = "target", talent = 13}, -- Judgment of Light
        { spell = 20066, type = "debuff", unit = "target", talent = 8}, -- Repentance
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 498, type = "ability"}, -- Divine Protection
        { spell = 633, type = "ability"}, -- Lay on Hands
        { spell = 642, type = "ability"}, -- Divine Shield
        { spell = 853, type = "ability"}, -- Hammer of Justice
        { spell = 1022, type = "ability"}, -- Blessing of Protection
        { spell = 1044, type = "ability"}, -- Blessing of Freedom
        { spell = 6940, type = "ability"}, -- Blessing of Sacrifice
        { spell = 20066, type = "ability", talent = 8}, -- Repentance
        { spell = 20473, type = "ability"}, -- Holy Shock
        { spell = 26573, type = "ability"}, -- Consecration
        { spell = 31821, type = "ability"}, -- Aura Mastery
        { spell = 31884, type = "ability"}, -- Avenging Wrath
        { spell = 35395, type = "ability"}, -- Crusader Strike
        { spell = 85222, type = "ability"}, -- Light of Dawn
        { spell = 105809, type = "ability", talent = 15}, -- Holy Avenger
        { spell = 114158, type = "ability", talent = 3}, -- Light's Hammer
        { spell = 114165, type = "ability", talent = 14}, -- Holy Prism
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 200025, type = "ability", talent = 21}, -- Beacon of Virtue
        { spell = 214202, type = "ability"}, -- Rule of Law
        { spell = 216331, type = "ability"}, -- Avenging Crusader
        { spell = 223306, type = "ability", talent = 2}, -- Bestow Faith
        { spell = 275773, type = "ability"}, -- Judgment
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
        { spell = 203797, type = "buff", unit = "player", talent = 10}, -- Retribution Aura
        { spell = 132403, type = "buff", unit = "player"}, -- Shield of the Righteous
        { spell = 197561, type = "buff", unit = "player"}, -- Avenger's Valor
        { spell = 1044, type = "buff", unit = "player"}, -- Blessing of Freedom
        { spell = 6940, type = "buff", unit = "group"}, -- Blessing of Sacrifice
        { spell = 188370, type = "buff", unit = "player"}, -- Consecration
        { spell = 204150, type = "buff", unit = "player", talent = 18}, -- Aegis of Light
        { spell = 31850, type = "buff", unit = "player"}, -- Ardent Defender
        { spell = 31884, type = "buff", unit = "player"}, -- Avenging Wrath
        { spell = 204018, type = "buff", unit = "player", talent = 12}, -- Blessing of Spellwarding
        { spell = 152262, type = "buff", unit = "player", talent = 21}, -- Seraphim
        { spell = 86659, type = "buff", unit = "player"}, -- Guardian of Ancient Kings
        { spell = 1022, type = "buff", unit = "player"}, -- Blessing of Protection
        { spell = 221883, type = "buff", unit = "player"}, -- Divine Steed
        { spell = 204335, type = "buff", unit = "player"}, -- Aegis of Light
        { spell = 642, type = "buff", unit = "player"}, -- Divine Shield
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
        { spell = 20066, type = "debuff", unit = "target", talent = 8}, -- Repentance
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 633, type = "ability"}, -- Lay on Hands
        { spell = 642, type = "ability"}, -- Divine Shield
        { spell = 853, type = "ability"}, -- Hammer of Justice
        { spell = 1022, type = "ability"}, -- Blessing of Protection
        { spell = 1044, type = "ability"}, -- Blessing of Freedom
        { spell = 6940, type = "ability"}, -- Blessing of Sacrifice
        { spell = 20066, type = "ability", talent = 8}, -- Repentance
        { spell = 26573, type = "ability"}, -- Consecration
        { spell = 31850, type = "ability"}, -- Ardent Defender
        { spell = 31884, type = "ability"}, -- Avenging Wrath
        { spell = 31935, type = "ability"}, -- Avenger's Shield
        { spell = 53595, type = "ability"}, -- Hammer of the Righteous
        { spell = 53600, type = "ability"}, -- Shield of the Righteous
        { spell = 62124, type = "ability"}, -- Hand of Reckoning
        { spell = 86659, type = "ability"}, -- Guardian of Ancient Kings
        { spell = 96231, type = "ability"}, -- Rebuke
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 152262, type = "ability", talent = 21}, -- Seraphim
        { spell = 184092, type = "ability"}, -- Light of the Protector
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 204018, type = "ability", talent = 12}, -- Blessing of Spellwarding
        { spell = 204019, type = "ability"}, -- Blessed Hammer
        { spell = 204035, type = "ability"}, -- Bastion of Light
        { spell = 204150, type = "ability"}, -- Aegis of Light
        { spell = 213652, type = "ability"}, -- Hand of the Protector
        { spell = 275779, type = "ability"}, -- Judgment
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
        { spell = 20066, type = "debuff", unit = "target", talent = 8}, -- Repentance
        { spell = 255937, type = "debuff", unit = "target", talent = 12}, -- Wake of Ashes

      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 633, type = "ability"}, -- Lay on Hands
        { spell = 642, type = "ability"}, -- Divine Shield
        { spell = 853, type = "ability"}, -- Hammer of Justice
        { spell = 1022, type = "ability"}, -- Blessing of Protection
        { spell = 1044, type = "ability"}, -- Blessing of Freedom
        { spell = 20066, type = "ability", talent = 8}, -- Repentance
        { spell = 20271, type = "ability"}, -- Judgment
        { spell = 24275, type = "ability", talent = 6}, -- Hammer of Wrath
        { spell = 31884, type = "ability"}, -- Avenging Wrath
        { spell = 35395, type = "ability"}, -- Crusader Strike
        { spell = 62124, type = "ability"}, -- Hand of Reckoning
        { spell = 96231, type = "ability"}, -- Rebuke
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 183218, type = "ability"}, -- Hand of Hindrance
        { spell = 184575, type = "ability"}, -- Blade of Justice
        { spell = 184662, type = "ability"}, -- Shield of Vengeance
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 205191, type = "ability", talent = 15}, -- Eye for an Eye
        { spell = 205228, type = "ability", talent = 11}, -- Consecration
        { spell = 210191, type = "ability", talent = 18}, -- Word of Glory
        { spell = 255937, type = "ability", talent = 11}, -- Wake of Ashes
        { spell = 267798, type = "ability", talent = 3}, -- Execution Sentence
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
        { spell = 186257, type = "buff", unit = "player"}, -- Aspect of the Cheetah
        { spell = 281036, type = "buff", unit = "player", talent = 3}, -- Dire Beast
        { spell = 186265, type = "buff", unit = "player"}, -- Aspect of the Turtle
        { spell = 6197, type = "buff", unit = "player"}, -- Eagle Eye
        { spell = 246152, type = "buff", unit = "player"}, -- Barbed Shot
        { spell = 264663, type = "buff", unit = "target"}, -- Predator's Thirst
        { spell = 34477, type = "buff", unit = "target"}, -- Misdirection
        { spell = 24450, type = "buff", unit = "pet"}, -- Prowl
        { spell = 264663, type = "buff", unit = "pet"}, -- Predator's Thirst
        { spell = 118455, type = "buff", unit = "pet"}, -- Beast Cleave
        { spell = 193530, type = "buff", unit = "pet"}, -- Aspect of the Wild
        { spell = 272790, type = "buff", unit = "pet"}, -- Frenzy
        { spell = 186254, type = "buff", unit = "pet"}, -- Bestial Wrath
        { spell = 199483, type = "buff", unit = "pet", talent = 9}, -- Camouflage
        { spell = 136, type = "buff", unit = "pet"}, -- Mend Pet
        { spell = 34477, type = "buff", unit = "pet"}, -- Misdirection
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 135299, type = "debuff", unit = "target"}, -- Tar Trap
        { spell = 217200, type = "debuff", unit = "target"}, -- Barbed Shot
        { spell = 117405, type = "debuff", unit = "target", talent = 15}, -- Binding Shot
        { spell = 3355, type = "debuff", unit = "target"}, -- Freezing Trap
        { spell = 2649, type = "debuff", unit = "target"}, -- Growl
        { spell = 24394, type = "debuff", unit = "target"}, -- Intimidation
        { spell = 5116, type = "debuff", unit = "target"}, -- Concussive Shot
      },
      icon = 135860
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
      { spell = 781, type = "ability"}, -- Disengage
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 2649, type = "ability"}, -- Growl
        { spell = 5116, type = "ability"}, -- Concussive Shot
        { spell = 5384, type = "ability"}, -- Feign Death
        { spell = 16827, type = "ability"}, -- Claw
        { spell = 19574, type = "ability"}, -- Bestial Wrath
        { spell = 19577, type = "ability"}, -- Intimidation
        { spell = 24450, type = "ability"}, -- Prowl
        { spell = 34026, type = "ability"}, -- Kill Command
        { spell = 34477, type = "ability"}, -- Misdirection
        { spell = 53209, type = "ability", talent = 6}, -- Chimaera Shot
        { spell = 109248, type = "ability", talent = 15}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 120360, type = "ability", talent = 17}, -- Barrage
        { spell = 120679, type = "ability", talent = 3}, -- Dire Beast
        { spell = 131894, type = "ability", talent = 12}, -- A Murder of Crows
        { spell = 147362, type = "ability"}, -- Counter Shot
        { spell = 186257, type = "ability"}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability"}, -- Aspect of the Turtle
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 193530, type = "ability"}, -- Aspect of the Wild
        { spell = 199483, type = "ability", talent = 9}, -- Camouflage
        { spell = 201430, type = "ability", talent = 18}, -- Stampede
        { spell = 217200, type = "ability"}, -- Barbed Shot
        { spell = 264667, type = "ability"}, -- Primal Rage
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
        { spell = 186257, type = "buff", unit = "player"}, -- Aspect of the Cheetah
        { spell = 118922, type = "buff", unit = "player", talent = 14}, -- Posthaste
        { spell = 186265, type = "buff", unit = "player"}, -- Aspect of the Turtle
        { spell = 193534, type = "buff", unit = "player", talent = 10}, -- Steady Focus
        { spell = 264663, type = "buff", unit = "player"}, -- Predator's Thirst
        { spell = 199483, type = "buff", unit = "player", talent = 9}, -- Camouflage
        { spell = 24450, type = "buff", unit = "target"}, -- Prowl
        { spell = 264663, type = "buff", unit = "target"}, -- Predator's Thirst
        { spell = 34477, type = "buff", unit = "target"}, -- Misdirection
        { spell = 264663, type = "buff", unit = "pet"}, -- Predator's Thirst
        { spell = 24450, type = "buff", unit = "pet"}, -- Prowl
        { spell = 136, type = "buff", unit = "pet"}, -- Mend Pet

      },
      icon = 461846
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 135299, type = "debuff", unit = "target"}, -- Tar Trap
        { spell = 5116, type = "debuff", unit = "target"}, -- Concussive Shot
        { spell = 186387, type = "debuff", unit = "target"}, -- Bursting Shot
        { spell = 3355, type = "debuff", unit = "target"}, -- Freezing Trap
        { spell = 271788, type = "debuff", unit = "target"}, -- Serpent Sting
        { spell = 257284, type = "debuff", unit = "target", talent = 12}, -- Hunter's Mark
        { spell = 131894, type = "debuff", unit = "target", talent = 3}, -- A Murder of Crows

      },
      icon = 236188
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 781, type = "ability"}, -- Disengage
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 5116, type = "ability"}, -- Concussive Shot
        { spell = 5384, type = "ability"}, -- Feign Death
        { spell = 19434, type = "ability"}, -- Aimed Shot
        { spell = 34477, type = "ability"}, -- Misdirection
        { spell = 109248, type = "ability", talent = 15}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 120360, type = "ability", talent = 17}, -- Barrage
        { spell = 131894, type = "ability", talent = 3}, -- A Murder of Crows
        { spell = 147362, type = "ability"}, -- Counter Shot
        { spell = 185358, type = "ability"}, -- Arcane Shot
        { spell = 186257, type = "ability"}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability"}, -- Aspect of the Turtle
        { spell = 186387, type = "ability"}, -- Bursting Shot
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 193526, type = "ability"}, -- Trueshot
        { spell = 198670, type = "ability", talent = 21}, -- Piercing Shot
        { spell = 199483, type = "ability", talent = 9}, -- Camouflage
        { spell = 212431, type = "ability", talent = 6}, -- Explosive Shot
        { spell = 257044, type = "ability"}, -- Rapid Fire
        { spell = 257620, type = "ability"}, -- Multi-Shot
        { spell = 260402, type = "ability", talent = 18}, -- Double Tap
        { spell = 264667, type = "ability"}, -- Primal Rage
        { spell = 272678, type = "ability"}, -- Primal Rage

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
        { spell = 1966, type = "buff", unit = "player"}, -- Feint
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
        { spell = 1330, type = "debuff", unit = "target"}, -- Garrote - Silence
        { spell = 256148, type = "debuff", unit = "target", talent = 14}, -- Iron Wire
        { spell = 154953, type = "debuff", unit = "target", talent = 13}, -- Internal Bleeding
        { spell = 1833, type = "debuff", unit = "target"}, -- Cheap Shot
        { spell = 6770, type = "debuff", unit = "target"}, -- Sap
        { spell = 255909, type = "debuff", unit = "target", talent = 15}, -- Prey on the Weak
        { spell = 703, type = "debuff", unit = "target"}, -- Garrote
        { spell = 245389, type = "debuff", unit = "target", talent = 17}, -- Toxic Blade
        { spell = 2818, type = "debuff", unit = "target"}, -- Deadly Poison
        { spell = 3409, type = "debuff", unit = "target"}, -- Crippling Poison
        { spell = 2094, type = "debuff", unit = "target"}, -- Blind
        { spell = 408, type = "debuff", unit = "target"}, -- Kidney Shot
        { spell = 121411, type = "debuff", unit = "target", talent = 21}, -- Crimson Tempest
        { spell = 79140, type = "debuff", unit = "target"}, -- Vendetta
        { spell = 1943, type = "debuff", unit = "target"}, -- Rupture
        { spell = 8680, type = "debuff", unit = "target"}, -- Wound Poison
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 132302
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, type = "ability"}, -- Kidney Shot
        { spell = 703, type = "ability"}, -- Garrote
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1766, type = "ability"}, -- Kick
        { spell = 1784, type = "ability"}, -- Stealth
        { spell = 1856, type = "ability"}, -- Vanish
        { spell = 1966, type = "ability"}, -- Feint
        { spell = 2094, type = "ability"}, -- Blind
        { spell = 2983, type = "ability"}, -- Sprint
        { spell = 5277, type = "ability"}, -- Evasion
        { spell = 31224, type = "ability"}, -- Cloak of Shadows
        { spell = 36554, type = "ability"}, -- Shadowstep
        { spell = 79140, type = "ability"}, -- Vendetta
        { spell = 114018, type = "ability"}, -- Shroud of Concealment
        { spell = 115191, type = "ability"}, -- Stealth
        { spell = 137619, type = "ability", talent = 9}, -- Marked for Death
        { spell = 185311, type = "ability"}, -- Crimson Vial
        { spell = 200806, type = "ability", talent = 18}, -- Exsanguinate
        { spell = 245388, type = "ability", talent = 17}, -- Toxic Blade
        { spell = 57934, type = "ability"}, -- Tricks of the Trade
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
        { spell = 1966, type = "buff", unit = "player"}, -- Feint
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
        { spell = 2094, type = "debuff", unit = "target"}, -- Blind
        { spell = 1776, type = "debuff", unit = "target"}, -- Gouge
        { spell = 6770, type = "debuff", unit = "target"}, -- Sap
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 1373908
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1766, type = "ability"}, -- Kick
        { spell = 1776, type = "ability"}, -- Gouge
        { spell = 1784, type = "ability"}, -- Stealth
        { spell = 1856, type = "ability"}, -- Vanish
        { spell = 1966, type = "ability"}, -- Feint
        { spell = 2094, type = "ability"}, -- Blind
        { spell = 2983, type = "ability"}, -- Sprint
        { spell = 13750, type = "ability"}, -- Adrenaline Rush
        { spell = 13877, type = "ability"}, -- Blade Flurry
        { spell = 31224, type = "ability"}, -- Cloak of Shadows
        { spell = 51690, type = "ability", talent = 21}, -- Killing Spree
        { spell = 79096, type = "ability"}, -- Restless Blades
        { spell = 114018, type = "ability"}, -- Shroud of Concealment
        { spell = 137619, type = "ability", talent = 9}, -- Marked for Death
        { spell = 185311, type = "ability"}, -- Crimson Vial
        { spell = 195457, type = "ability"}, -- Grappling Hook
        { spell = 196937, type = "ability", talent = 3}, -- Ghostly Strike
        { spell = 199754, type = "ability"}, -- Riposte
        { spell = 199804, type = "ability"}, -- Between the Eyes
        { spell = 271877, type = "ability", talent = 20}, -- Blade Rush
        { spell = 57934, type = "ability"}, -- Tricks of the Trade
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
        { spell = 1966, type = "buff", unit = "player"}, -- Feint
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
        { spell = 2094, type = "debuff", unit = "target"}, -- Blind
        { spell = 137619, type = "debuff", unit = "target"}, -- Marked for Death
        { spell = 1833, type = "debuff", unit = "target"}, -- Cheap Shot
        { spell = 206760, type = "debuff", unit = "target", talent = 14}, -- Shadow's Grasp
        { spell = 408, type = "debuff", unit = "target"}, -- Kidney Shot
        { spell = 6770, type = "debuff", unit = "target"}, -- Sap
        { spell = 45181, type = "debuff", unit = "player", talent = 11 }, -- Cheated Death
      },
      icon = 136175
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, type = "ability"}, -- Kidney Shot
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1766, type = "ability"}, -- Kick
        { spell = 1784, type = "ability"}, -- Stealth
        { spell = 1856, type = "ability"}, -- Vanish
        { spell = 1966, type = "ability"}, -- Feint
        { spell = 2094, type = "ability"}, -- Blind
        { spell = 2983, type = "ability"}, -- Sprint
        { spell = 5277, type = "ability"}, -- Evasion
        { spell = 31224, type = "ability"}, -- Cloak of Shadows
        { spell = 36554, type = "ability"}, -- Shadowstep
        { spell = 114018, type = "ability"}, -- Shroud of Concealment
        { spell = 115191, type = "ability"}, -- Stealth
        { spell = 121471, type = "ability"}, -- Shadow Blades
        { spell = 137619, type = "ability", talent = 9}, -- Marked for Death
        { spell = 185311, type = "ability"}, -- Crimson Vial
        { spell = 185313, type = "ability"}, -- Shadow Dance
        { spell = 212283, type = "ability"}, -- Symbols of Death
        { spell = 277925, type = "ability", talent = 21}, -- Shuriken Tornado
        { spell = 280719, type = "ability", talent = 20}, -- Secret Technique
        { spell = 57934, type = "ability"}, -- Tricks of the Trade

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
        { spell = 586, type = "buff", unit = "player"}, -- Fade
        { spell = 198069, type = "buff", unit = "player"}, -- Power of the Dark Side
        { spell = 194384, type = "buff", unit = "player"}, -- Atonement
        { spell = 17, type = "buff", unit = "player"}, -- Power Word: Shield
        { spell = 265258, type = "buff", unit = "player", talent = 2}, -- Twist of Fate
        { spell = 271466, type = "buff", unit = "player", talent = 20}, -- Luminous Barrier
        { spell = 19236, type = "buff", unit = "player"}, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player"}, -- Power Word: Fortitude
        { spell = 81782, type = "buff", unit = "player"}, -- Power Word: Barrier
        { spell = 33206, type = "buff", unit = "player"}, -- Pain Suppression
        { spell = 193065, type = "buff", unit = "player", talent = 5}, -- Masochism
        { spell = 65081, type = "buff", unit = "player", talent = 4}, -- Body and Soul
        { spell = 47536, type = "buff", unit = "player"}, -- Rapture
        { spell = 121557, type = "buff", unit = "player", talent = 6}, -- Angelic Feather
        { spell = 2096, type = "buff", unit = "player"}, -- Mind Vision
        { spell = 111759, type = "buff", unit = "player"}, -- Levitate
        { spell = 45243, type = "buff", unit = "player" }, -- Focused Will
      },
      icon = 458720
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
      title = L["Cooldowns"],
      args = {
        { spell = 527, type = "ability"}, -- Purify
        { spell = 586, type = "ability"}, -- Fade
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 19236, type = "ability"}, -- Desperate Prayer
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 33206, type = "ability"}, -- Pain Suppression
        { spell = 34433, type = "ability"}, -- Shadowfiend
        { spell = 47536, type = "ability"}, -- Rapture
        { spell = 47540, type = "ability"}, -- Penance
        { spell = 62618, type = "ability"}, -- Power Word: Barrier
        { spell = 73325, type = "ability" }, -- Leap of Faith
        { spell = 110744, type = "ability", talent = 17}, -- Divine Star
        { spell = 120517, type = "ability", talent = 18}, -- Halo
        { spell = 121536, type = "ability", talent = 6}, -- Angelic Feather
        { spell = 123040, type = "ability", talent = 8}, -- Mindbender
        { spell = 129250, type = "ability", talent = 9}, -- Power Word: Solace
        { spell = 194509, type = "ability"}, -- Power Word: Radiance
        { spell = 204065, type = "ability", talent = 15}, -- Shadow Covenant
        { spell = 204263, type = "ability", talent = 12}, -- Shining Force
        { spell = 214621, type = "ability", talent = 3}, -- Schism
        { spell = 246287, type = "ability"}, -- Evangelism
        { spell = 271466, type = "ability", talent = 21}, -- Luminous Barrier

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
        { spell = 47788, type = "buff", unit = "target"}, -- Guardian Spirit
        { spell = 64901, type = "buff", unit = "player"}, -- Symbol of Hope
        { spell = 139, type = "buff", unit = "player"}, -- Renew
        { spell = 2096, type = "buff", unit = "player"}, -- Mind Vision
        { spell = 64843, type = "buff", unit = "player"}, -- Divine Hymn
        { spell = 64844, type = "buff", unit = "player"}, -- Divine Hymn
        { spell = 19236, type = "buff", unit = "player"}, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player"}, -- Power Word: Fortitude
        { spell = 111759, type = "buff", unit = "player"}, -- Levitate
        { spell = 200183, type = "buff", unit = "player", talent = 20}, -- Apotheosis
        { spell = 27827, type = "buff", unit = "player"}, -- Spirit of Redemption
        { spell = 77489, type = "buff", unit = "target"}, -- Echo of Light
        { spell = 114255, type = "buff", unit = "player", talent = 13}, -- Surge of Light
        { spell = 121557, type = "buff", unit = "player", talent = 6}, -- Angelic Feather
        { spell = 586, type = "buff", unit = "player"}, -- Fade
        { spell = 41635, type = "buff", unit = "group"}, -- Prayer of Mending
        { spell = 139, type = "buff", unit = "target"}, -- Renew
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
      title = L["Cooldowns"],
      args = {
        { spell = 527, type = "ability"}, -- Purify
        { spell = 586, type = "ability"}, -- Fade
        { spell = 2050, type = "ability"}, -- Holy Word: Serenity
        { spell = 2061, type = "ability"}, -- Flash Heal
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 14914, type = "ability"}, -- Holy Fire
        { spell = 19236, type = "ability"}, -- Desperate Prayer
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 33076, type = "ability"}, -- Prayer of Mending
        { spell = 34861, type = "ability"}, -- Holy Word: Sanctify
        { spell = 47788, type = "ability"}, -- Guardian Spirit
        { spell = 64843, type = "ability"}, -- Divine Hymn
        { spell = 64901, type = "ability"}, -- Symbol of Hope
        { spell = 73325, type = "ability" }, -- Leap of Faith
        { spell = 88625, type = "ability"}, -- Holy Word: Chastise
        { spell = 110744, type = "ability", talent = 17}, -- Divine Star
        { spell = 120517, type = "ability", talent = 18}, -- Halo
        { spell = 121536, type = "ability", talent = 6}, -- Angelic Feather
        { spell = 200183, type = "ability", talent = 20}, -- Apotheosis
        { spell = 204263, type = "ability", talent = 12}, -- Shining Force
        { spell = 204883, type = "ability", talent = 15}, -- Circle of Healing
        { spell = 265202, type = "ability", talent = 21}, -- Holy Word: Salvation

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
        { spell = 21562, type = "buff", unit = "player"}, -- Power Word: Fortitude
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
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability"}, -- Power Word: Shield
        { spell = 586, type = "ability"}, -- Fade
        { spell = 8092, type = "ability"}, -- Mind Blast
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 15286, type = "ability"}, -- Vampiric Embrace
        { spell = 15487, type = "ability"}, -- Silence
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 32379, type = "ability", talent = 14}, -- Shadow Word: Death
        { spell = 34433, type = "ability"}, -- Shadowfiend
        { spell = 47585, type = "ability"}, -- Dispersion
        { spell = 64044, type = "ability", talent = 12}, -- Psychic Horror
        { spell = 73325, type = "ability" }, -- Leap of Faith
        { spell = 193223, type = "ability", talent = 21}, -- Surrender to Madness
        { spell = 200174, type = "ability", talent = 17}, -- Mindbender
        { spell = 205351, type = "ability", talent = 3}, -- Shadow Word: Void
        { spell = 205369, type = "ability", talent = 11}, -- Mind Bomb
        { spell = 205385, type = "ability", talent = 15}, -- Shadow Crash
        { spell = 205448, type = "ability"}, -- Void Bolt
        { spell = 213634, type = "ability"}, -- Purify Disease
        { spell = 228260, type = "ability"}, -- Void Eruption
        { spell = 263165, type = "ability", talent = 18}, -- Void Torrent
        { spell = 263346, type = "ability", talent = 9}, -- Dark Void
        { spell = 280711, type = "ability", talent = 20}, -- Dark Ascension

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
        { spell = 263806, type = "buff", unit = "player", talent = 11}, -- Wind Gust
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
        { spell = 210714, type = "buff", unit = "player", talent = 17}, -- Icefury
        { spell = 260881, type = "buff", unit = "player"}, -- Spirit Wolf
        { spell = 260734, type = "buff", unit = "player", talent = 5}, -- Master of the Elements
        { spell = 191634, type = "buff", unit = "player", talent = 20}, -- Stormkeeper
        { spell = 118337, type = "buff", unit = "player", talent = 16}, -- Harden Skin
        { spell = 974, type = "buff", unit = "player", talent = 8}, -- Earth Shield
        { spell = 6196, type = "buff", unit = "player"}, -- Far Sight
        { spell = 210658, type = "buff", unit = "player", talent = 6}, -- Ember Totem
        { spell = 173183, type = "buff", unit = "player", talent = 3}, -- Elemental Blast: Haste
        { spell = 77762, type = "buff", unit = "player"}, -- Lava Surge
        { spell = 2645, type = "buff", unit = "player"}, -- Ghost Wolf
        { spell = 118522, type = "buff", unit = "player", talent = 3}, -- Elemental Blast: Critical Strike
        { spell = 157348, type = "buff", unit = "pet"}, -- Call Lightning

      },
      icon = 451169
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
      title = L["Cooldowns"],
      args = {
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 2484, type = "ability"}, -- Earthbind Totem
        { spell = 8143, type = "ability"}, -- Tremor Totem
        { spell = 32182, type = "ability"}, -- Heroism
        { spell = 51490, type = "ability"}, -- Thunderstorm
        { spell = 51505, type = "ability"}, -- Lava Burst
        { spell = 51514, type = "ability"}, -- Hex
        { spell = 51886, type = "ability"}, -- Cleanse Spirit
        { spell = 57994, type = "ability"}, -- Wind Shear
        { spell = 108271, type = "ability"}, -- Astral Shift
        { spell = 108281, type = "ability"}, -- Ancestral Guidance
        { spell = 114050, type = "ability", talent = 21}, -- Ascendance
        { spell = 117014, type = "ability", talent = 3}, -- Elemental Blast
        { spell = 188389, type = "ability"}, -- Flame Shock
        { spell = 191634, type = "ability", talent = 20}, -- Stormkeeper
        { spell = 192058, type = "ability"}, -- Capacitor Totem
        { spell = 192077, type = "ability", talent = 15}, -- Wind Rush Totem
        { spell = 192222, type = "ability", talent = 12}, -- Liquid Magma Totem
        { spell = 192249, type = "ability", talent = 11}, -- Storm Elemental
        { spell = 198067, type = "ability"}, -- Fire Elemental
        { spell = 198103, type = "ability"}, -- Earth Elemental
        { spell = 210714, type = "ability", talent = 17}, -- Icefury
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
        { spell = 32182, type = "buff", unit = "player"}, -- Heroism
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
      title = L["Cooldowns"],
      args = {
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 2484, type = "ability"}, -- Earthbind Totem
        { spell = 8143, type = "ability"}, -- Tremor Totem
        { spell = 17364, type = "ability"}, -- Stormstrike
        { spell = 32182, type = "ability"}, -- Heroism
        { spell = 51514, type = "ability"}, -- Hex
        { spell = 51533, type = "ability"}, -- Feral Spirit
        { spell = 51886, type = "ability"}, -- Cleanse Spirit
        { spell = 57994, type = "ability"}, -- Wind Shear
        { spell = 58875, type = "ability"}, -- Spirit Walk
        { spell = 108271, type = "ability"}, -- Astral Shift
        { spell = 114051, type = "ability", talent = 21 }, -- Ascendance
        { spell = 115356, type = "ability", talent = 21 }, -- Windstrike
        { spell = 187837, type = "ability", talent = 12 }, -- Lightning Bolt
        { spell = 187874, type = "ability"}, -- Crash Lightning
        { spell = 188089, type = "ability", talent = 20 }, -- Earthen Spike
        { spell = 192058, type = "ability"}, -- Capacitor Totem
        { spell = 192077, type = "ability", talent = 15 }, -- Wind Rush Totem
        { spell = 193786, type = "ability"}, -- Rockbiter
        { spell = 193796, type = "ability"}, -- Flametongue
        { spell = 196884, type = "ability", talent = 14 }, -- Feral Lunge
        { spell = 197214, type = "ability", talent = 18 }, -- Sundering
        { spell = 198103, type = "ability"}, -- Earth Elemental
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
        { spell = 32182, type = "buff", unit = "player"}, -- Heroism
        { spell = 61295, type = "buff", unit = "player"}, -- Riptide
        { spell = 98007, type = "buff", unit = "player"}, -- Spirit Link Totem
        { spell = 77762, type = "buff", unit = "player"}, -- Lava Surge
        { spell = 207400, type = "buff", unit = "player", talent = 10 }, -- Ancestral Vigor
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
        { spell = 64695, type = "debuff", unit = "target", talent = 0 }, -- Earthgrab
        { spell = 3600, type = "debuff", unit = "target"}, -- Earthbind
        { spell = 116947, type = "debuff", unit = "target", talent = 0 }, -- Earthbind
        { spell = 188838, type = "debuff", unit = "target"}, -- Flame Shock

      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 556, type = "ability"}, -- Astral Recall
        { spell = 2484, type = "ability"}, -- Earthbind Totem
        { spell = 5394, type = "ability"}, -- Healing Stream Totem
        { spell = 8143, type = "ability"}, -- Tremor Totem
        { spell = 32182, type = "ability"}, -- Heroism
        { spell = 51485, type = "ability", talent = 8 }, -- Earthgrab Totem
        { spell = 51505, type = "ability"}, -- Lava Burst
        { spell = 51514, type = "ability"}, -- Hex
        { spell = 57994, type = "ability"}, -- Wind Shear
        { spell = 61295, type = "ability"}, -- Riptide
        { spell = 73685, type = "ability", talent = 0 }, -- Unleash Life
        { spell = 73920, type = "ability"}, -- Healing Rain
        { spell = 79206, type = "ability"}, -- Spiritwalker's Grace
        { spell = 98008, type = "ability"}, -- Spirit Link Totem
        { spell = 108271, type = "ability"}, -- Astral Shift
        { spell = 108280, type = "ability"}, -- Healing Tide Totem
        { spell = 114052, type = "ability", talent = 21 }, -- Ascendance
        { spell = 157153, type = "ability", talent = 18 }, -- Cloudburst Totem
        { spell = 188838, type = "ability"}, -- Flame Shock
        { spell = 192058, type = "ability"}, -- Capacitor Totem
        { spell = 192077, type = "ability", talent = 15 }, -- Wind Rush Totem
        { spell = 197995, type = "ability", talent = 20 }, -- Wellspring
        { spell = 198103, type = "ability"}, -- Earth Elemental
        { spell = 198838, type = "ability", talent = 11 }, -- Earthen Wall Totem
        { spell = 207399, type = "ability", talent = 12 }, -- Ancestral Protection Totem
        { spell = 207778, type = "ability", talent = 17 }, -- Downpour
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
        { spell = 80353, type = "buff", unit = "player"}, -- Time Warp
        { spell = 110960, type = "buff", unit = "player"}, -- Greater Invisibility
        { spell = 45438, type = "buff", unit = "player"}, -- Ice Block
        { spell = 116267, type = "buff", unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 1459, type = "buff", unit = "player"}, -- Arcane Intellect
        { spell = 212799, type = "buff", unit = "player"}, -- Displacement Beacon
        { spell = 210126, type = "buff", unit = "player", talent = 3 }, -- Arcane Familiar
        { spell = 236298, type = "buff", unit = "player", talent = 13 }, -- Chrono Shift
        { spell = 116014, type = "buff", unit = "player", talent = 9 }, -- Rune of Power
        { spell = 130, type = "buff", unit = "player"}, -- Slow Fall
        { spell = 263725, type = "buff", unit = "player"}, -- Clearcasting
        { spell = 235450, type = "buff", unit = "player"}, -- Prismatic Barrier
        { spell = 186401, type = "buff", unit = "player"}, -- Sign of the Skirmisher
        { spell = 12051, type = "buff", unit = "player"}, -- Evocation
        { spell = 205025, type = "buff", unit = "player"}, -- Presence of Mind
        { spell = 264774, type = "buff", unit = "player", talent = 2 }, -- Rule of Threes
        { spell = 113862, type = "buff", unit = "player"}, -- Greater Invisibility
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
      title = L["Cooldowns"],
      args = {
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability"}, -- Counterspell
        { spell = 12042, type = "ability"}, -- Arcane Power
        { spell = 12051, type = "ability"}, -- Evocation
        { spell = 44425, type = "ability"}, -- Arcane Barrage
        { spell = 45438, type = "ability"}, -- Ice Block
        { spell = 55342, type = "ability", talent = 8 }, -- Mirror Image
        { spell = 80353, type = "ability"}, -- Time Warp
        { spell = 110959, type = "ability"}, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 15 }, -- Ring of Frost
        { spell = 116011, type = "ability", talent = 9 }, -- Rune of Power
        { spell = 153626, type = "ability", talent = 21 }, -- Arcane Orb
        { spell = 157980, type = "ability", talent = 12 }, -- Supernova
        { spell = 190336, type = "ability"}, -- Conjure Refreshment
        { spell = 195676, type = "ability"}, -- Displacement
        { spell = 205022, type = "ability", talent = 3 }, -- Arcane Familiar
        { spell = 205025, type = "ability"}, -- Presence of Mind
        { spell = 205032, type = "ability", talent = 11 }, -- Charged Up
        { spell = 212653, type = "ability", talent = 5 }, -- Shimmer
        { spell = 235450, type = "ability"}, -- Prismatic Barrier
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
        { spell = 236060, type = "buff", unit = "player", talent = 13 }, -- Frenetic Speed
        { spell = 80353, type = "buff", unit = "player"}, -- Time Warp
        { spell = 186401, type = "buff", unit = "player"}, -- Sign of the Skirmisher
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
        { spell = 1459, type = "buff", unit = "player"}, -- Arcane Intellect
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
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability"}, -- Invisibility
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability"}, -- Counterspell
        { spell = 31661, type = "ability"}, -- Dragon's Breath
        { spell = 44457, type = "ability", talent = 18 }, -- Living Bomb
        { spell = 45438, type = "ability"}, -- Ice Block
        { spell = 55342, type = "ability", talent = 8 }, -- Mirror Image
        { spell = 80353, type = "ability"}, -- Time Warp
        { spell = 108853, type = "ability"}, -- Fire Blast
        { spell = 113724, type = "ability", talent = 15 }, -- Ring of Frost
        { spell = 116011, type = "ability", talent = 9 }, -- Rune of Power
        { spell = 153561, type = "ability", talent = 21 }, -- Meteor
        { spell = 157981, type = "ability", talent = 6 }, -- Blast Wave
        { spell = 190319, type = "ability"}, -- Combustion
        { spell = 190336, type = "ability"}, -- Conjure Refreshment
        { spell = 212653, type = "ability", talent = 5 }, -- Shimmer
        { spell = 235313, type = "ability"}, -- Blazing Barrier
        { spell = 257541, type = "ability", talent = 12 }, -- Phoenix Flames
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
        { spell = 186401, type = "buff", unit = "player"}, -- Sign of the Skirmisher
        { spell = 199844, type = "buff", unit = "player", talent = 21 }, -- Glacial Spike!
        { spell = 45438, type = "buff", unit = "player"}, -- Ice Block
        { spell = 66, type = "buff", unit = "player"}, -- Invisibility
        { spell = 116267, type = "buff", unit = "player", talent = 7 }, -- Incanter's Flow
        { spell = 1459, type = "buff", unit = "player"}, -- Arcane Intellect
        { spell = 32612, type = "buff", unit = "player"}, -- Invisibility
        { spell = 108839, type = "buff", unit = "player", talent = 6 }, -- Ice Floes
        { spell = 278310, type = "buff", unit = "player", talent = 11 }, -- Chain Reaction
        { spell = 12472, type = "buff", unit = "player"}, -- Icy Veins
        { spell = 11426, type = "buff", unit = "player"}, -- Ice Barrier
        { spell = 130, type = "buff", unit = "player"}, -- Slow Fall
        { spell = 205473, type = "buff", unit = "player"}, -- Icicles
        { spell = 270232, type = "buff", unit = "player", talent = 16 }, -- Freezing Rain
        { spell = 190446, type = "buff", unit = "player"}, -- Brain Freeze
        { spell = 116014, type = "buff", unit = "player", talent = 9 }, -- Rune of Power
        { spell = 80353, type = "buff", unit = "player"}, -- Time Warp
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
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability"}, -- Invisibility
        { spell = 120, type = "ability"}, -- Cone of Cold
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 475, type = "ability"}, -- Remove Curse
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability"}, -- Counterspell
        { spell = 11426, type = "ability"}, -- Ice Barrier
        { spell = 12472, type = "ability"}, -- Icy Veins
        { spell = 30455, type = "ability"}, -- Ice Lance
        { spell = 31687, type = "ability"}, -- Summon Water Elemental
        { spell = 31707, type = "ability"}, -- Waterbolt
        { spell = 45438, type = "ability"}, -- Ice Block
        { spell = 55342, type = "ability", talent = 8 }, -- Mirror Image
        { spell = 80353, type = "ability"}, -- Time Warp
        { spell = 84714, type = "ability"}, -- Frozen Orb
        { spell = 108839, type = "ability", talent = 6 }, -- Ice Floes
        { spell = 113724, type = "ability", talent = 15 }, -- Ring of Frost
        { spell = 116011, type = "ability", talent = 9 }, -- Rune of Power
        { spell = 153595, type = "ability", talent = 18 }, -- Comet Storm
        { spell = 157997, type = "ability", talent = 3 }, -- Ice Nova
        { spell = 190336, type = "ability"}, -- Conjure Refreshment
        { spell = 190356, type = "ability"}, -- Blizzard
        { spell = 205021, type = "ability", talent = 20 }, -- Ray of Frost
        { spell = 212653, type = "ability", talent = 5 }, -- Shimmer
        { spell = 235219, type = "ability"}, -- Cold Snap
        { spell = 257537, type = "ability", talent = 12 }, -- Ebonbolt
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
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability"}, -- Path of Frost
        { spell = 43265, type = "ability"}, -- Death and Decay
        { spell = 47528, type = "ability"}, -- Mind Freeze
        { spell = 48265, type = "ability"}, -- Death's Advance
        { spell = 48707, type = "ability"}, -- Anti-Magic Shell
        { spell = 48792, type = "ability"}, -- Icebound Fortitude
        { spell = 49028, type = "ability"}, -- Dancing Rune Weapon
        { spell = 49576, type = "ability"}, -- Death Grip
        { spell = 50842, type = "ability"}, -- Blood Boil
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 55233, type = "ability"}, -- Vampiric Blood
        { spell = 56222, type = "ability"}, -- Dark Command
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 108199, type = "ability"}, -- Gorefiend's Grasp
        { spell = 111673, type = "ability"}, -- Control Undead
        { spell = 194679, type = "ability", talent = 12}, -- Rune Tap
        { spell = 194844, type = "ability", talent = 21}, -- Bonestorm
        { spell = 195182, type = "ability"}, -- Marrowrend
        { spell = 195292, type = "ability"}, -- Death's Caress
        { spell = 206930, type = "ability"}, -- Heart Strike
        { spell = 206931, type = "ability", talent = 2}, -- Blooddrinker
        { spell = 206940, type = "ability", talent = 18}, -- Mark of Blood
        { spell = 210764, type = "ability", talent = 3}, -- Rune Strike
        { spell = 212552, type = "ability", talent = 15}, -- Wraith Walk
        { spell = 219809, type = "ability", talent = 9}, -- Tombstone
        { spell = 221562, type = "ability"}, -- Asphyxiate
        { spell = 274156, type = "ability", talent = 6}, -- Consumption
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

      },
      icon = 237522
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability"}, -- Path of Frost
        { spell = 45524, type = "ability"}, -- Chains of Ice
        { spell = 47528, type = "ability"}, -- Mind Freeze
        { spell = 47568, type = "ability"}, -- Empower Rune Weapon
        { spell = 48265, type = "ability", talent = 15}, -- Death's Advance
        { spell = 48707, type = "ability"}, -- Anti-Magic Shell
        { spell = 48743, type = "ability"}, -- Death Pact
        { spell = 48792, type = "ability"}, -- Icebound Fortitude
        { spell = 49020, type = "ability"}, -- Obliterate
        { spell = 49184, type = "ability"}, -- Howling Blast
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 51271, type = "ability"}, -- Pillar of Frost
        { spell = 56222, type = "ability"}, -- Dark Command
        { spell = 57330, type = "ability", talent = 6}, -- Horn of Winter
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 111673, type = "ability"}, -- Control Undead
        { spell = 152279, type = "ability", talent = 21}, -- Breath of Sindragosa
        { spell = 194913, type = "ability"}, -- Glacial Advance
        { spell = 196770, type = "ability"}, -- Remorseless Winter
        { spell = 207167, type = "ability", talent = 9}, -- Blinding Sleet
        { spell = 207230, type = "ability", talent = 12}, -- Frostscythe
        { spell = 212552, type = "ability", talent = 14}, -- Wraith Walk
        { spell = 279302, type = "ability", talent = 18}, -- Frostwyrm's Fury
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
        { spell = 3714, type = "buff", unit = "pet"}, -- Path of Frost
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
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability"}, -- Path of Frost
        { spell = 42650, type = "ability"}, -- Army of the Dead
        { spell = 43265, type = "ability"}, -- Death and Decay
        { spell = 45524, type = "ability"}, -- Chains of Ice
        { spell = 46584, type = "ability"}, -- Raise Dead
        { spell = 47468, type = "ability"}, -- Claw
        { spell = 47481, type = "ability"}, -- Gnaw
        { spell = 47484, type = "ability"}, -- Huddle
        { spell = 47528, type = "ability"}, -- Mind Freeze
        { spell = 48265, type = "ability"}, -- Death's Advance
        { spell = 48707, type = "ability"}, -- Anti-Magic Shell
        { spell = 48743, type = "ability"}, -- Death Pact
        { spell = 48792, type = "ability"}, -- Icebound Fortitude
        { spell = 49206, type = "ability", talent = 21}, -- Summon Gargoyle
        { spell = 50977, type = "ability"}, -- Death Gate
        { spell = 55090, type = "ability"}, -- Scourge Strike
        { spell = 56222, type = "ability"}, -- Dark Command
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 63560, type = "ability"}, -- Dark Transformation
        { spell = 77575, type = "ability"}, -- Outbreak
        { spell = 85948, type = "ability"}, -- Festering Strike
        { spell = 108194, type = "ability", talent = 9}, -- Asphyxiate
        { spell = 111673, type = "ability"}, -- Control Undead
        { spell = 115989, type = "ability", talent = 6}, -- Unholy Blight
        { spell = 130736, type = "ability", talent = 12}, -- Soul Reaper
        { spell = 152280, type = "ability", talent = 17}, -- Defile
        { spell = 207289, type = "ability", talent = 20}, -- Unholy Frenzy
        { spell = 207311, type = "ability"}, -- Clawing Shadows
        { spell = 212552, type = "ability", talent = 14}, -- Wraith Walk
        { spell = 275699, type = "ability"}, -- Apocalypse
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

local function enrichDatabase()
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
