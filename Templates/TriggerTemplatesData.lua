local WeakAuras = WeakAuras
local L = WeakAuras.L
local GetSpellInfo, tinsert, GetItemInfo, GetSpellDescription, C_Timer = GetSpellInfo, tinsert, GetItemInfo, GetSpellDescription, C_Timer

-- TODO Display Templates

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
    Goblin = {}
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
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 1719, type = "buff", unit = "player"}, -- Battle Cry
        { spell = 18499, type = "buff", unit = "player" }, -- Berserker Rage
        { spell = 60503, type = "buff", unit = "player", talent = 2}, -- Overpower!
        { spell = 97463, type = "buff", unit = "player" }, -- Commanding Shout
        { spell = 107574, type = "buff", unit = "player", talent = 9 }, -- Avatar
        { spell = 118038, type = "buff", unit = "player" }, -- Die by the Sword
        { spell = 188923, type = "buff", unit = "player" }, -- Cleave
        { spell = 197690, type = "buff", unit = "player", talent = 12 }, -- Defensive Stance
        { spell = 202164, type = "buff", unit = "player" }, -- Bounding Stride
        { spell = 207982, type = "buff", unit = "player", talent = 15 }, -- Focused Rage
        { spell = 209484, type = "buff", unit = "player" }, -- Tactical Advance
        { spell = 209567, type = "buff", unit = "player" }, -- Corrupted Blood of Zakajz
        { spell = 209706, type = "buff", unit = "player" }, -- Shattered Defenses
        { spell = 227744, type = "buff", unit = "player", talent = 21 }, -- Ravager
      },
      icon = 458972
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 772, type = "debuff", unit = "target", talent = 8 }, -- Rend
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target" }, -- Intimidating Shout
        { spell = 105771, type = "debuff", unit = "target" }, -- Charge
        { spell = 115804, type = "debuff", unit = "target" }, -- Mortal Wounds
        { spell = 132168, type = "debuff", unit = "target", talent = 4 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 5 }, -- Storm Bolt
        { spell = 208086, type = "debuff", unit = "target" }, -- Colossus Smash
        { spell = 209569, type = "debuff", unit = "target" }, -- Corrupted Blood of Zakajz
        { spell = 215537, type = "debuff", unit = "target", talent = 17 }, -- Trauma
      },
      icon = 464973
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 355, type = "ability"}, -- Taunt
        { spell = 845, type = "ability"}, -- Cleave
        { spell = 1719, type = "ability"}, -- Battle Cry
        { spell = 5246, type = "ability"}, -- Intimidating Shout
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability"}, -- Pummel
        { spell = 12294, type = "ability"}, -- Mortal Strike
        { spell = 18499, type = "ability"}, -- Berserker Rage
        { spell = 34428, type = "ability"}, -- Victory Rush
        { spell = 46968, type = "ability", talent = 4}, -- Shockwave
        { spell = 57755, type = "ability"}, -- Heroic Throw
        { spell = 97462, type = "ability"}, -- Commanding Shout
        { spell = 107570, type = "ability", talent = 5}, -- Storm Bolt
        { spell = 107574, type = "ability", talent = 9}, -- Avatar
        { spell = 118038, type = "ability"}, -- Die by the Sword
        { spell = 152277, type = "ability", talent = 21}, -- Ravager
        { spell = 167105, type = "ability"}, -- Colossus Smash
        { spell = 197690, type = "ability", talent = 12}, -- Defensive Stance
        { spell = 209577, type = "ability"}, -- Warbreaker
      },
      icon = 132355
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198827, type = "debuff", unit = "target", pvptalent = 17}, -- Echo Slam
        { spell = 198760, type = "buff", unit = "group", pvptalent = 13}, -- Intercept
        { spell = 198817, type = "ability", pvptalent = 18}, -- Spell Reflection
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_misc_emotionangry",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 1719, type = "buff", unit = "player" }, -- Battle Cry
        { spell = 12292, type = "buff", unit = "player", talent = 16 }, -- Bloodbath
        { spell = 18499, type = "buff", unit = "player" }, -- Berserker Rage
        { spell = 46924, type = "buff", unit = "player", talent = 19 }, -- Bladestorm
        { spell = 85739, type = "buff", unit = "player" }, -- Meat Cleaver
        { spell = 97463, type = "buff", unit = "player" }, -- Commanding Shout
        { spell = 107574, type = "buff", unit = "player", talent = 9 }, -- Avatar
        { spell = 118000, type = "buff", unit = "player" }, -- Dragon Roar
        { spell = 184362, type = "buff", unit = "player" }, -- Enrage
        { spell = 184364, type = "buff", unit = "player" }, -- Enraged Regeneration
        { spell = 200875, type = "buff", unit = "player" }, -- Juggernaut
        { spell = 200953, type = "buff", unit = "player" }, -- Berserking
        { spell = 200954, type = "buff", unit = "player" }, -- Battle Scars
        { spell = 200977, type = "buff", unit = "player" }, -- Unrivaled Strength
        { spell = 200979, type = "buff", unit = "player" }, -- Sense Death
        { spell = 200986, type = "buff", unit = "player" }, -- Odyn's Champion
        { spell = 202164, type = "buff", unit = "player" }, -- Bounding Stride
        { spell = 202225, type = "buff", unit = "player" }, -- Furious Charge
        { spell = 202539, type = "buff", unit = "player", talent = 17 }, -- Frenzy
        { spell = 206316, type = "buff", unit = "player", talent = 13 }, -- Massacre
        { spell = 206333, type = "buff", unit = "player" }, -- Taste for Blood
        { spell = 215570, type = "buff", unit = "player", talent = 7 }, -- Wrecking Ball
        { spell = 215557, type = "buff", unit = "player", talent = 1 }, -- War Machine
        { spell = 215572, type = "buff", unit = "player", talent = 14 }, -- Frothing Berserker
      },
      icon = 136224
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 5246, type = "debuff", unit = "target" }, -- Intimidating Shout
        { spell = 12323, type = "debuff", unit = "target" }, -- Piercing Howl
        { spell = 105771, type = "debuff", unit = "target" }, -- Charge
        { spell = 113344, type = "debuff", unit = "target" }, -- Bloodbath
        { spell = 132168, type = "debuff", unit = "target", talent = 4 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 5 }, -- Storm Bolt
        { spell = 205546, type = "debuff", unit = "target" }, -- Odyn's Fury
      },
      icon = 132154
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability"}, -- Charge
        { spell = 355, type = "ability"}, -- Taunt
        { spell = 1719, type = "ability"}, -- Battle Cry
        { spell = 5246, type = "ability"}, -- Intimidating Shout
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability"}, -- Pummel
        { spell = 12292, type = "ability", talent = 16}, -- Bloodbath
        { spell = 18499, type = "ability"}, -- Berserker Rage
        { spell = 23881, type = "ability"}, -- Bloodthirst
        { spell = 46924, type = "ability", talent = 19}, -- Bladestorm
        { spell = 46968, type = "ability", talent = 4}, -- Shockwave
        { spell = 57755, type = "ability"}, -- Heroic Throw
        { spell = 85288, type = "ability"}, -- Raging Blow
        { spell = 97462, type = "ability"}, -- Commanding Shout
        { spell = 107570, type = "ability", talent = 5}, -- Storm Bolt
        { spell = 107574, type = "ability", talent = 9}, -- Avatar
        { spell = 118000, type = "ability", talent = 21}, -- Dragon Roar
        { spell = 184364, type = "ability"}, -- Enraged Regeneration
        { spell = 205545, type = "ability"}, -- Odyn's Fury
      },
      icon = 136012
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 213858, type = "buff", unit = "group", pvptalent = 14}, -- Battle Trance
        { spell = 199261, type = "ability", pvptalent = 18}, -- Death Wish
        { spell = 199261, type = "buff", unit = "player", pvptalent = 18}, -- Death Wish
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_misc_emotionangry",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 871, type = "buff", unit = "player" }, -- Shield Wall
        { spell = 12975, type = "buff", unit = "player" }, -- Last Stand
        { spell = 18499, type = "buff", unit = "player" }, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player" }, -- Spell Reflection
        { spell = 107574, type = "buff", unit = "player", talent = 9 }, -- Avatar
        { spell = 122510, type = "buff", unit = "player", talent = 8 }, -- Ultimatum
        { spell = 125565, type = "buff", unit = "player" }, -- Demoralizing Shout
        { spell = 132404, type = "buff", unit = "player" }, -- Shield Block
        { spell = 147833, type = "buff", unit = "target" }, -- Intervene
        { spell = 188783, type = "buff", unit = "player" }, -- Might of the Vrykul
        { spell = 189064, type = "buff", unit = "player" }, -- Scales of Earth
        { spell = 190456, type = "buff", unit = "player" }, -- Ignore Pain
        { spell = 202164, type = "buff", unit = "player", talent = 11 }, -- Bounding Stride
        { spell = 202289, type = "buff", unit = "player" }, -- Renewed Fury
        { spell = 202573, type = "buff", unit = "player", talent = 16 }, -- Vengeance: Focused Rage
        { spell = 202574, type = "buff", unit = "player", talent = 16 }, -- Vengeance: Ignore Pain
        { spell = 202602, type = "buff", unit = "player", talent = 17 }, -- Into the Fray
        { spell = 203524, type = "buff", unit = "player" }, -- Neltharion's Fury
        { spell = 203581, type = "buff", unit = "player" }, -- Dragon Scales
        { spell = 204488, type = "buff", unit = "player" }, -- Focused Rage
        { spell = 223658, type = "buff", unit = "target", talent = 6 }, -- Safeguard
        { spell = 227744, type = "buff", unit = "player", talent = 21 }, -- Ravager
      },
      icon = 1377132
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1160, type = "debuff", unit = "target" }, -- Demoralizing Shout
        { spell = 6343, type = "debuff", unit = "target" }, -- Thunder Clap
        { spell = 103828, type = "debuff", unit = "target" }, -- Warbringer
        { spell = 115767, type = "debuff", unit = "target" }, -- Deep Wounds
        { spell = 132168, type = "debuff", unit = "target", talent = 1 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 2 }, -- Storm Bolt
      },
      icon = 132090
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 355, type = "ability"}, -- Taunt
        { spell = 871, type = "ability"}, -- Shield Wall
        { spell = 1160, type = "ability"}, -- Demoralizing Shout
        { spell = 1719, type = "ability"}, -- Battle Cry
        { spell = 6343, type = "ability"}, -- Thunder Clap
        { spell = 6544, type = "ability"}, -- Heroic Leap
        { spell = 6552, type = "ability"}, -- Pummel
        { spell = 6572, type = "ability"}, -- Revenge
        { spell = 12975, type = "ability"}, -- Last Stand
        { spell = 18499, type = "ability"}, -- Berserker Rage
        { spell = 23920, type = "ability"}, -- Spell Reflection
        { spell = 23922, type = "ability"}, -- Shield Slam
        { spell = 34428, type = "ability"}, -- Victory Rush
        { spell = 46968, type = "ability", talent = 1}, -- Shockwave
        { spell = 107570, type = "ability", talent = 2}, -- Storm Bolt
        { spell = 107574, type = "ability", talent = 9}, -- Avatar
        { spell = 202168, type = "ability", talent = 4}, -- Impending Victory
        { spell = 203524, type = "ability"}, -- Neltharion's Fury
        { spell = 152277, type = "ability", talent = 21}, -- Ravager
      },
      icon = 134951
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198912, type = "ability", pvptalent = 15}, -- Shield Bash
        { spell = 198912, type = "debuff", unit = "target", pvptalent = 15}, -- Shield Bash
        { spell = 199085, type = "debuff", unit = "target", pvptalent = 14}, -- Warpath
        { spell = 206572, type = "ability", pvptalent = 18}, -- Dragon Charge
        { spell = 195336, type = "buff", unit = "player", pvptalent = 4}, -- Relentless Assault
        { spell = 206891, type = "debuff", unit = "target", pvptalent = 5}, -- Intimated
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_misc_emotionangry",
    },
  },
}

templates.class.PALADIN = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 498, type = "buff", unit = "player" }, -- Divine Protection
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "group" }, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "group" }, -- Blessing of Freedom
        { spell = 6940, type = "buff", unit = "group" }, -- Blessing of Sacrifice
        { spell = 31821, type = "buff", unit = "player" }, -- Aura Mastery
        { spell = 31842, type = "buff", unit = "player" }, -- Avenging Wrath
        { spell = 53563, type = "buff", unit = "player" }, -- Beacon of Light
        { spell = 54149, type = "buff", unit = "player" }, -- Infusion of Light
        { spell = 105809, type = "buff", unit = "player", talent = 14 }, -- Holy Avenger
        { spell = 156910, type = "buff", unit = "target", talent = 19 }, -- Beacon of Faith
        { spell = 183415, type = "buff", unit = "player", talent = 12 }, -- Aura of Mercy
        { spell = 183416, type = "buff", unit = "player", talent = 11 }, -- Aura of Sacrifice
        { spell = 200025, type = "buff", unit = "player", talent = 21 }, -- Beacon of Virtue
        { spell = 200376, type = "buff", unit = "player" }, -- Vindicator
        { spell = 200652, type = "buff", unit = "player", fullscan = true, titleSuffix = L[" (Channeling)"] }, -- Tyr's Deliverance
        { spell = 200654, type = "buff", unit = "player", fullscan = true, titleSuffix = L[" (Healing received increase)"] }, -- Tyr's Deliverance
        { spell = 210320, type = "buff", unit = "player", talent = 10 }, -- Devotion Aura
        { spell = 211210, type = "buff", unit = "player" }, -- Protection of Tyr
        { spell = 211422, type = "buff", unit = "player" }, -- Knight of the Silver Hand
        { spell = 214202, type = "buff", unit = "player", talent = 6 }, -- Rule of Law
        { spell = 216413, type = "buff", unit = "player", talent = 13 }, -- Divine Purpose
        { spell = 221886, type = "buff", unit = "player", talent = 4 }, -- Divine Steed
        { spell = 223306, type = "buff", unit = "player", talent = 1 }, -- Bestow Faith
        { spell = 223316, type = "buff", unit = "player", talent = 16 }, -- Fervent Martyr
      },
      icon = 236254
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 20066, type = "debuff", unit = "multi", talent = 8 }, -- Repentance
        { spell = 25771, type = "debuff", unit = "player" }, -- Forbearance
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 9 }, -- Blinding Light
        { spell = 196941, type = "debuff", unit = "target", talent = 18 }, -- Judgment of Light
        { spell = 204242, type = "debuff", unit = "target" }, -- Consecration
        { spell = 214222, type = "debuff", unit = "target" }, -- Judgment
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
        { spell = 4987, type = "ability"}, -- Blessing of Freedom
        { spell = 6940, type = "ability"}, -- Blessing of Sacrifice
        { spell = 20066, type = "ability", talent = 8}, -- Repentance
        { spell = 20271, type = "ability"}, -- Judgment
        { spell = 20473, type = "ability"}, -- Holy Shock
        { spell = 26573, type = "ability"}, -- Consecration
        { spell = 31821, type = "ability"}, -- Aura Mastery
        { spell = 31842, type = "ability"}, -- Avenging Wrath
        { spell = 35395, type = "ability"}, -- Crusader Strike
        { spell = 53563, type = "ability"}, -- Beacon of Light
        { spell = 62124, type = "ability"}, -- Hand of Reckoning
        { spell = 85222, type = "ability"}, -- Light of Dawn
        { spell = 105809, type = "ability", talent = 14}, -- Holy Avenger
        { spell = 114158, type = "ability", talent = 2}, -- Light's Hammer
        { spell = 114165, type = "ability", talent = 15}, -- Holy Prism
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 156910, type = "ability", talent = 19}, -- Beacon of Faith
        { spell = 200025, type = "ability", talent = 21}, -- Beacon of Virtue
        { spell = 200652, type = "ability"}, -- Tyr's Deliverance
        { spell = 205656, type = "ability", talent = 4}, -- Divine Steed
        { spell = 214202, type = "ability", talent = 6}, -- Rule of Law
        { spell = 223306, type = "ability", talent = 1}, -- Bestow Faith
      },
      icon = 135972
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 216331, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Avenging Crusader
        { spell = 216331, type = "buff", unit = "player", pvptalent = 18, titleSuffix = L["buff"]}, -- Avenging Crusader
        { spell = 210391, type = "buff", unit = "player", pvptalent = 15}, -- Darkest before the Dawn
        { spell = 210294, type = "ability", pvptalent = 6, titleSuffix = L["cooldown"]}, -- Divine Favor
        { spell = 210294, type = "buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]}, -- Divine Favor
        { spell = 216328, type = "buff", unit = "player", pvptalent = 12}, -- Light's Grace
        { spell = 195329, type = "buff", unit = "player", pvptalent = 4}, -- Defender of the Weak
        { spell = 195488, type = "buff", unit = "player", pvptalent = 5}, -- Vim and Vigor
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 642, type = "buff", unit = "player"}, -- Divine Shield
        { spell = 1044, type = "buff", unit = "group"}, -- Blessing of Freedom
        { spell = 6940, type = "buff", unit = "group"}, -- Blessing of Sacrifice
        { spell = 31850, type = "buff", unit = "player" }, -- Ardent Defender
        { spell = 31884, type = "buff", unit = "player" }, -- Avenging Wrath
        { spell = 86659, type = "buff", unit = "player" }, -- Guardian of Ancient Kings
        { spell = 132403, type = "buff", unit = "player" }, -- Shield of the Righteous
        { spell = 152262, type = "buff", unit = "player", talent = 20 }, -- Seraphim
        { spell = 188370, type = "buff", unit = "player" }, -- Consecration
        { spell = 203797, type = "buff", unit = "player", talent = 12 }, -- Retribution Aura
        { spell = 204013, type = "buff", unit = "group", talent = 11 }, -- Blessing of Salvation
        { spell = 204018, type = "buff", unit = "group", talent = 10 }, -- Blessing of Spellwarding
        { spell = 204150, type = "buff", unit = "player", talent = 16, fullscan = true }, -- Aegis of Light
        { spell = 209332, type = "buff", unit = "player" }, -- Painful Truths
        { spell = 209388, type = "buff", unit = "player" }, -- Bulwark of Order
        { spell = 209540, type = "buff", unit = "player" }, -- Light of the Titans
        { spell = 221886, type = "buff", unit = "player" }, -- Divine Steed
      },
      icon = 236265
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 20066, type = "debuff", unit = "multi", talent = 8 }, -- Repentance
        { spell = 25771, type = "debuff", unit = "player" }, -- Forbearance
        { spell = 31935, type = "debuff", unit = "target" }, -- Avenger's Shield
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 9 }, -- Blinding Light
        { spell = 196941, type = "debuff", unit = "target", talent = 17 }, -- Judgment of Light
        { spell = 204079, type = "debuff", unit = "target", talent = 15 }, -- Final Stand
        { spell = 204242, type = "debuff", unit = "target" }, -- Consecration
        { spell = 209202, type = "debuff", unit = "target" }, -- Eye of Tyr
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 633, type = "ability"}, -- Lay on Hands
        { spell = 642, type = "ability"}, -- Divine Shield
        { spell = 853, type = "ability"}, -- Hammer of Justice
        { spell = 1044, type = "ability"}, -- Blessing of Freedom
        { spell = 6940, type = "ability"}, -- Blessing of Sacrifice
        { spell = 20066, type = "ability", talent = 8}, -- Repentance
        { spell = 20271, type = "ability"}, -- Judgment
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
        { spell = 152262, type = "ability", talent = 20}, -- Seraphim
        { spell = 190784, type = "ability"}, -- Divine Steed
        { spell = 204013, type = "ability", talent = 11}, -- Blessing of Salvation
        { spell = 204018, type = "ability", talent = 10}, -- Blessing of Spellwarding
        { spell = 204019, type = "ability", talent = 5}, -- Blessed Hammer
        { spell = 204035, type = "ability", talent = 2}, -- Bastion of Light
        { spell = 204150, type = "ability", talent = 16}, -- Aegis of Light
        { spell = 209202, type = "ability"}, -- Eye of Tyr
        { spell = 213644, type = "ability"}, -- Cleanse Toxins
        { spell = 213652, type = "ability", talent = 13}, -- Hand of the Protector
      },
      icon = 135874
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 216857, type = "buff", unit = "player", pvptalent = 14}, -- Guarded by the Light
        { spell = 228049, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Guardian of the Forgotten Queen
        { spell = 228049, type = "buff", unit = "group", pvptalent = 18, titleSuffix = L["buff"]}, -- Guardian of the Forgotten Queen
        { spell = 215652, type = "ability", pvptalent = 7, titleSuffix = L["cooldown"]}, -- Shield of Virtue
        { spell = 215652, type = "buff", unit = "group", pvptalent = 7, titleSuffix = L["buff"]}, --Shield of Virtue
        { spell = 195336, type = "buff", unit = "player", pvptalent = 4}, -- Relentless Assault
        { spell = 206891, type = "debuff", unit = "target", pvptalent = 5}, -- Intimated
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "group" }, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "group" }, -- Blessing of Freedom
        { spell = 31884, type = "buff", unit = "player" }, -- Avenging Wrath
        { spell = 184662, type = "buff", unit = "player" }, -- Shield of Vengeance
        { spell = 202273, type = "buff", unit = "player", talent = 18 }, -- Seal of Light
        { spell = 203528, type = "buff", unit = "group" }, -- Greater Blessing of Might
        { spell = 203538, type = "buff", unit = "group" }, -- Greater Blessing of Kings
        { spell = 203539, type = "buff", unit = "group" }, -- Greater Blessing of Wisdom
        { spell = 205191, type = "buff", unit = "player", talent = 14 }, -- Eye for an Eye
        { spell = 209785, type = "buff", unit = "player", talent = 4 }, -- The Fires of Justice
        { spell = 217020, type = "buff", unit = "player", talent = 5 }, -- Zeal
        { spell = 221886, type = "buff", unit = "player", talent = 17 }, -- Divine Steed
        { spell = 223819, type = "buff", unit = "player" }, -- Divine Purpose
        { spell = 224668, type = "buff", unit = "player", talent = 20 }, -- Crusade
      },
      icon = 135993
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 20066, type = "debuff", unit = "multi", talent = 8 }, -- Repentance
        { spell = 25771, type = "debuff", unit = "player" }, -- Forbearance
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 9 }, -- Blinding Light
        { spell = 183218, type = "debuff", unit = "target" }, -- Hand of Hindrance
        { spell = 197277, type = "debuff", unit = "target" }, -- Judgment
        { spell = 202270, type = "debuff", unit = "target" }, -- Blade of Wrath
        { spell = 205273, type = "debuff", unit = "target" }, -- Wake of Ashes
        { spell = 213757, type = "debuff", unit = "target", talent = 2 }, -- Execution Sentence
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
        { spell = 31884, type = "ability"}, -- Avenging Wrath
        { spell = 35395, type = "ability"}, -- Crusader Strike
        { spell = 62124, type = "ability"}, -- Hand of Reckoning
        { spell = 96231, type = "ability"}, -- Rebuke
        { spell = 115750, type = "ability", talent = 9}, -- Blinding Light
        { spell = 183218, type = "ability"}, -- Hand of Hindrance
        { spell = 184575, type = "ability"}, -- Blade of Justice
        { spell = 184662, type = "ability"}, -- Shield of Vengeance
        { spell = 198034, type = "ability", talent = 12}, -- Divine Hammer
        { spell = 202270, type = "ability", talent = 11}, -- Blade of Wrath
        { spell = 205191, type = "ability", talent = 14}, -- Eye for an Eye
        { spell = 205228, type = "ability", talent = 3}, -- Consecration
        { spell = 205273, type = "ability"}, -- Wake of Ashes
        { spell = 205656, type = "ability", talent = 17}, -- Divine Steed
        { spell = 210191, type = "ability", talent = 15}, -- Word of Glory
        { spell = 210220, type = "ability", talent = 21}, -- Holy Wrath
        { spell = 213644, type = "ability"}, -- Cleanse Toxins
        { spell = 213757, type = "ability", talent = 2}, -- Execution Sentence
        { spell = 217020, type = "ability", talent = 5}, -- Zeal
        { spell = 224668, type = "ability", talent = 20}, -- Crusade
      },
      icon = 135891
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 210324, type = "buff", unit = "player", pvptalent = 13}, -- Vengeance Aura
        { spell = 210256, type = "ability", pvptalent = 14, titleSuffix = L["cooldown"]}, -- Blessing of Sanctuary
        { spell = 210256, type = "buff", unit = "group", pvptalent = 14, titleSuffix = L["buff"]}, -- Blessing of Sanctuary
        { spell = 204939, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Hammer of Reckoning
        { spell = 204940, type = "buff", unit = "player", pvptalent = 18, titleSuffix = L["buff"]}, -- Blessing of Sanctuary
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\achievement_bg_winsoa",
    },
  },
}

templates.class.HUNTER = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 5384, type = "buff", unit = "player" }, -- Feign Death
        { spell = 6197, type = "buff", unit = "player" }, -- Eagle Eye
        { spell = 19574, type = "buff", unit = "player" }, -- Bestial Wrath
        { spell = 35079, type = "buff", unit = "player" }, -- Misdirection
        { spell = 53478, type = "buff", unit = "pet", titleSuffix = L["(Pet)"] }, -- Last Stand
        { spell = 53480, type = "buff", unit = "player" }, -- Roar of Sacrifice
        { spell = 118455, type = "buff", unit = "pet" }, -- Beast Cleave
        { spell = 118922, type = "buff", unit = "player", talent = 7 }, -- Posthaste
        { spell = 120694, type = "buff", unit = "player" }, -- Dire Beast
        { spell = 185791, type = "buff", unit = "player" }, -- Wild Call
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 191414, type = "buff", unit = "pet", talent = 21 }, -- Bestial Tenacity
        { spell = 193530, type = "buff", unit = "player" }, -- Aspect of the Wild
        { spell = 194386, type = "buff", unit = "player", talent = 18 }, -- Volley
        { spell = 197161, type = "buff", unit = "player" }, -- Mimiron's Shell
        { spell = 211138, type = "buff", unit = "target" }, -- Hunter's Advantage
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target" }, -- Growl
        { spell = 5116, type = "debuff", unit = "target" }, -- Concussive Shot
        { spell = 19386, type = "debuff", unit = "target", talent = 14 }, -- Wyvern Sting
        { spell = 24394, type = "debuff", unit = "target", talent = 15 }, -- Intimidation
        { spell = 117405, type = "debuff", unit = "target", talent = 13 }, -- Binding Shot
        { spell = 131894, type = "debuff", unit = "target", talent = 16 }, -- A Murder of Crows
        { spell = 191397, type = "debuff", unit = "target", talent = 21 }, -- Bestial Cunning
        { spell = 191413, type = "debuff", unit = "target", talent = 21 }, -- Bestial Ferocity
      },
      icon = 135860
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 781, type = "ability"}, -- Disengage
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 5116, type = "ability"}, -- Concussive Shot
        { spell = 5384, type = "ability"}, -- Feign Death
        { spell = 19386, type = "ability", talent = 14}, -- Wyvern Sting
        { spell = 19574, type = "ability", talent = 15}, -- Bestial Wrath
        { spell = 19577, type = "ability"}, -- Intimidation
        { spell = 34026, type = "ability"}, -- Kill Command
        { spell = 34477, type = "ability"}, -- Misdirection
        { spell = 53209, type = "ability", talent = 6}, -- Chimaera Shot
        { spell = 53478, type = "ability"}, -- Last Stand
        { spell = 53480, type = "ability"}, -- Roar of Sacrifice
        { spell = 55709, type = "ability"}, -- Heart of the Phoenix
        { spell = 109248, type = "ability", talent = 13}, -- Binding Shot
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 120360, type = "ability", talent = 17}, -- Barrage
        { spell = 120679, type = "ability"}, -- Dire Beast
        { spell = 131894, type = "ability", talent = 16}, -- A Murder of Crows
        { spell = 147362, type = "ability"}, -- Counter Shot
        { spell = 186257, type = "ability"}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability"}, -- Aspect of the Turtle
        { spell = 193530, type = "ability"}, -- Aspect of the Wild
        { spell = 201430, type = "ability", talent = 19}, -- Stampede
        { spell = 207068, type = "ability"}, -- Titan's Thunder
        { spell = 217200, type = "ability", talent = 5}, -- Dire Frenzy
      },
      icon = 132176
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 205691, type = "ability", pvptalent = 18}, -- Dire Beast: Basilisk
        { spell = 208652, type = "ability", pvptalent = 17}, -- Dire Beast: Hawk
        { spell = 213882, type = "buff", unit = "pet", pvptalent = 14},  -- Separation Anxiety
        { spell = 204205, type = "buff", unit = "group", pvptalent = 15} -- Wild Protector
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\ability_hunter_focusfire",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 5384, type = "buff", unit = "player" }, -- Feign Death
        { spell = 6197, type = "buff", unit = "player" }, -- Eagle Eye
        { spell = 35079, type = "buff", unit = "player" }, -- Misdirection
        { spell = 53478, type = "buff", unit = "pet", titleSuffix = L["(Pet)"] }, -- Last Stand
        { spell = 53480, type = "buff", unit = "player" }, -- Roar of Sacrifice
        { spell = 82921, type = "buff", unit = "player" }, -- Bombardment
        { spell = 118922, type = "buff", unit = "player", talent = 7 }, -- Posthaste
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186258, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 190515, type = "buff", unit = "player" }, -- Survival of the Fittest
        { spell = 191342, type = "buff", unit = "player" }, -- Rapid Killing
        { spell = 193526, type = "buff", unit = "player" }, -- Trueshot
        { spell = 193534, type = "buff", unit = "player", talent = 2 }, -- Steady Focus
        { spell = 194386, type = "buff", unit = "player", talent = 18 }, -- Volley
        { spell = 194594, type = "buff", unit = "player", talent = 4 }, -- Lock and Load
        { spell = 199483, type = "buff", unit = "player", talent = 15 }, -- Camouflage
        { spell = 203924, type = "buff", unit = "player" }, -- Healing Shell
        { spell = 204090, type = "buff", unit = "player" }, -- Bullseye
        { spell = 204477, type = "buff", unit = "player" }, -- Windburst
        { spell = 223138, type = "buff", unit = "player" }, -- Marking Targets
        { spell = 227272, type = "buff", unit = "player" }, -- Trick Shot
      },
      icon = 461846
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target" }, -- Growl
        { spell = 5116, type = "debuff", unit = "target" }, -- Concussive Shot
        { spell = 19386, type = "debuff", unit = "target", talent = 14 }, -- Wyvern Sting
        { spell = 63468, type = "debuff", unit = "target", talent = 3 }, -- Careful Aim
        { spell = 117405, type = "debuff", unit = "target", talent = 13 }, -- Binding Shot
        { spell = 131894, type = "debuff", unit = "target", talent = 16 }, -- A Murder of Crows
        { spell = 185365, type = "debuff", unit = "target" }, -- Hunter's Mark
        { spell = 187131, type = "debuff", unit = "target" }, -- Vulnerable
        { spell = 194599, type = "debuff", unit = "target", talent = 5 }, -- Black Arrow
        { spell = 199803, type = "debuff", unit = "target", talent = 6 }, -- True Aim
        { spell = 204683, type = "debuff", unit = "target" }, -- Dark Whisper
        { spell = 224729, type = "debuff", unit = "target" }, -- Bursting Shot
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
        { spell = 19386, type = "ability", talent = 14}, -- Wyvern Sting
        { spell = 34477, type = "ability"}, -- Misdirection
        { spell = 53478, type = "ability"}, -- Last Stand
        { spell = 53480, type = "ability"}, -- Roar of Sacrifice
        { spell = 55709, type = "ability"}, -- Heart of the Phoenix
        { spell = 109248, type = "ability", talent = 13}, -- Binding Shot
        { spell = 120360, type = "ability", talent = 17}, -- Barrage
        { spell = 131894, type = "ability", talent = 4}, -- A Murder of Crows
        { spell = 147362, type = "ability"}, -- Counter Shot
        { spell = 186257, type = "ability"}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability"}, -- Aspect of the Turtle
        { spell = 186387, type = "ability"}, -- Bursting Shot
        { spell = 193526, type = "ability"}, -- Trueshot
        { spell = 194291, type = "ability"}, -- Exhilaration
        { spell = 194599, type = "ability", talent = 5}, -- Black Arrow
        { spell = 198670, type = "ability", talent = 20}, -- Piercing Shot
        { spell = 199483, type = "ability", talent = 15}, -- Camouflage
        { spell = 204147, type = "ability"}, -- Windburst
        { spell = 206817, type = "ability", talent = 11}, -- Sentinel
        { spell = 212431, type = "ability", talent = 10}, -- Explosive Shot
        { spell = 214579, type = "ability", talent = 19}, -- Sidewinders
      },
      icon = 132329
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 209789, type = "ability", pvptalent = 15, titleSuffix = L["cooldown"]}, -- Freezing Arrow
        { spell = 209790, type = "debuff", unit = "target", pvptalent = 15, titleSuffix = L["debuff"]}, -- Freezing Arrow
        { spell = 213691, type = "ability", pvptalent = 14, titleSuffix = L["cooldown"]}, -- Scatter Shot
        { spell = 213691, type = "debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"]}, -- Scatter Shot
        { spell = 203155, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Sniper Shot
        { spell = 203155, type = "buff", unit = "player", pvptalent = 18, titleSuffix = L["buff"]}, -- Sniper Shot
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\ability_hunter_focusfire",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 5384, type = "buff", unit = "player" }, -- Feign Death
        { spell = 53478, type = "buff", unit = "pet", titleSuffix = L["(Pet)"] }, -- Last Stand
        { spell = 53480, type = "buff", unit = "player" }, -- Roar of Sacrifice
        { spell = 118922, type = "buff", unit = "player", talent = 7 }, -- Posthaste
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186258, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 186289, type = "buff", unit = "player" }, -- Aspect of the Eagle
        { spell = 190931, type = "buff", unit = "player" }, -- Mongoose Fury
        { spell = 191414, type = "buff", unit = "pet", talent = 21 }, -- Bestial Tenacity
        { spell = 194407, type = "buff", unit = "player" }, -- Spitting Cobra
        { spell = 199483, type = "buff", unit = "player", talent = 15 }, -- Camouflage
        { spell = 201081, type = "buff", unit = "player", talent = 3 }, -- Mok'Nathal Tactics
        { spell = 203927, type = "buff", unit = "player" }, -- Aspect of the Skylord
        { spell = 204321, type = "buff", unit = "player", talent = 1 }, -- Instincts of the Raptor
        { spell = 204324, type = "buff", unit = "player", talent = 1 }, -- Instincts of the Cheetah
        { spell = 204333, type = "buff", unit = "player", talent = 1 }, -- Instincts of the Mongoose
      },
      icon = 1376044
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target" }, -- Growl
        { spell = 3355, type = "debuff", unit = "target" }, -- Freezing Trap
        { spell = 13812, type = "debuff", unit = "target" }, -- Explosive Trap
        { spell = 118253, type = "debuff", unit = "target", talent = 18 }, -- Serpent Sting
        { spell = 135299, type = "debuff", unit = "target" }, -- Tar Trap
        { spell = 162487, type = "debuff", unit = "target", talent = 12 }, -- Steel Trap
        { spell = 185855, type = "debuff", unit = "target" }, -- Lacerate
        { spell = 190927, type = "debuff", unit = "target" }, -- Harpoon
        { spell = 191241, type = "debuff", unit = "target", talent = 13 }, -- Sticky Bomb
        { spell = 191397, type = "debuff", unit = "target", talent = 21 }, -- Bestial Cunning
        { spell = 191413, type = "debuff", unit = "target", talent = 21 }, -- Bestial Ferocity
        { spell = 194279, type = "debuff", unit = "target", talent = 10 }, -- Caltrops
        { spell = 194858, type = "debuff", unit = "target", talent = 17 }, -- Dragonsfire Grenade
        { spell = 195645, type = "debuff", unit = "target" }, -- Wing Clip
        { spell = 200108, type = "debuff", unit = "target", talent = 14, fullscan = true, titleSuffix = L["Rooted"] }, -- Ranger's Net
        { spell = 201142, type = "debuff", unit = "target", talent = 20 }, -- Frozen Wake
        { spell = 204081, type = "debuff", unit = "target" }, -- On the Trail
        { spell = 206505, type = "debuff", unit = "target", talent = 4 }, -- A Murder of Crows
        { spell = 206755, type = "debuff", unit = "target", talent = 14, fullscan = true, titleSuffix = L["Slowed"] }, -- Ranger's Net
      },
      icon = 132309
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 1543, type = "ability"}, -- Flare
        { spell = 5384, type = "ability"}, -- Feign Death
        { spell = 53478, type = "ability"}, -- Last Stand
        { spell = 53480, type = "ability"}, -- Roar of Sacrifice
        { spell = 55709, type = "ability"}, -- Heart of the Phoenix
        { spell = 109304, type = "ability"}, -- Exhilaration
        { spell = 162488, type = "ability", talent = 12}, -- Steel Trap
        { spell = 185855, type = "ability"}, -- Lacerate
        { spell = 186257, type = "ability"}, -- Aspect of the Cheetah
        { spell = 186265, type = "ability"}, -- Aspect of the Turtle
        { spell = 186289, type = "ability"}, -- Aspect of the Eagle
        { spell = 187650, type = "ability"}, -- Freezing Trap
        { spell = 187698, type = "ability"}, -- Tar Trap
        { spell = 187707, type = "ability"}, -- Muzzle
        { spell = 190925, type = "ability"}, -- Harpoon
        { spell = 190928, type = "ability"}, -- Mongoose Bite
        { spell = 191241, type = "ability", talent = 13}, -- Sticky Bomb
        { spell = 191433, type = "ability"}, -- Explosive Trap
        { spell = 194277, type = "ability", talent = 10}, -- Caltrops
        { spell = 194407, type = "ability", talent = 19}, -- Spitting Cobra
        { spell = 194855, type = "ability", talent = 17}, -- Dragonsfire Grenade
        { spell = 199483, type = "ability", talent = 15}, -- Camouflage
        { spell = 200163, type = "ability", talent = 2}, -- Throwing Axes
        { spell = 201078, type = "ability", talent = 6}, -- Snake Hunter
        { spell = 202800, type = "ability"}, -- Flanking Strike
        { spell = 203415, type = "ability"}, -- Fury of the Eagle
        { spell = 206505, type = "ability", talent = 10}, -- A Murder of Crows
        { spell = 212436, type = "ability", talent = 16}, -- Butchery
      },
      icon = 236184
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 53271, type = "ability", pvptalent = 15, titleSuffix = L["cooldown"]}, -- Master's Call
        { spell = 62305, type = "buff", unit = "player", pvptalent = 15, titleSuffix = L["buff"]}, -- Master's Call
        { spell = 212640, type = "ability", pvptalent = 14, titleSuffix = L["cooldown"]}, -- Mending Bandage
        { spell = 212640, type = "buff", unit = "group", pvptalent = 14, titleSuffix = L["buff"]}, -- Mending Bandage
        { spell = 203268, type = "debuff", unit = "target", pvptalent = 16}, -- Sticky Tar
        { spell = 212638, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Tracker's Net
        { spell = 212638, type = "debuff", unit = "target", pvptalent = 18, titleSuffix = L["buff"]}, -- Tracker's Net
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\ability_hunter_focusfire",
    },
  },
}


templates.class.ROGUE = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 1784, type = "buff", unit = "player" }, -- Stealth
        { spell = 1966, type = "buff", unit = "player" }, -- Feint
        { spell = 2823, type = "buff", unit = "player" }, -- Deadly Poison
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 3408, type = "buff", unit = "player" }, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player" }, -- Evasion
        { spell = 8679, type = "buff", unit = "player" }, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 31224, type = "buff", unit = "player" }, -- Cloak of Shadows
        { spell = 32645, type = "buff", unit = "player" }, -- Envenom
        { spell = 36554, type = "buff", unit = "player" }, -- Shadowstep
        { spell = 45182, type = "buff", unit = "player", talent = 12 }, -- Cheating Death
        { spell = 57934, type = "buff", unit = "group"}, -- Tricks of the Trade
        { spell = 108211, type = "buff", unit = "player", talent = 10 }, -- Leeching Poison
        { spell = 115191, type = "buff", unit = "player" }, -- Stealth
        { spell = 115192, type = "buff", unit = "player", talent = 5 }, -- Subterfuge
        { spell = 115193, type = "buff", unit = "player" }, -- Vanish
        { spell = 152150, type = "buff", unit = "player" }, -- Death from Above
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 192432, type = "buff", unit = "player" }, -- From the Shadows
        { spell = 193538, type = "buff", unit = "player", talent = 17 }, -- Alacrity
        { spell = 193641, type = "buff", unit = "player", talent = 2 }, -- Elaborate Planning
        { spell = 200802, type = "buff", unit = "player", talent = 16 }, -- Agonizing Poison
        { spell = 226364, type = "buff", unit = "player" }, -- Evasion
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 703, type = "debuff", unit = "target" }, -- Garrote
        { spell = 1833, type = "debuff", unit = "target" }, -- Cheap Shot
        { spell = 1943, type = "debuff", unit = "target" }, -- Rupture
        { spell = 2818, type = "debuff", unit = "target" }, -- Deadly Poison
        { spell = 3409, type = "debuff", unit = "target" }, -- Crippling Poison
        { spell = 6770, type = "debuff", unit = "multi" }, -- Sap
        { spell = 8680, type = "debuff", unit = "target" }, -- Wound Poison
        { spell = 16511, type = "debuff", unit = "target", talent = 3 }, -- Hemorrhage
        { spell = 45181, type = "debuff", unit = "player", talent = 12 }, -- Cheated Death
        { spell = 79140, type = "debuff", unit = "target" }, -- Vendetta
        { spell = 137619, type = "debuff", unit = "target", talent = 20 }, -- Marked for Death
        { spell = 154953, type = "debuff", unit = "target", talent = 15 }, -- Internal Bleeding
        { spell = 192425, type = "debuff", unit = "target" }, -- Surge of Toxins
        { spell = 192759, type = "debuff", unit = "target" }, -- Kingsbane
        { spell = 192925, type = "debuff", unit = "target" }, -- Blood of the Assassinated
        { spell = 200803, type = "debuff", unit = "target" }, -- Agonizing Poison
      },
      icon = 132302
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, type = "ability"}, -- Kidney Shot
        { spell = 703, type = "ability"}, -- Garrote
        { spell = 1329, type = "ability"}, -- Mutilate
        { spell = 1725, type = "ability"}, -- Distract
        { spell = 1766, type = "ability"}, -- Kick
        { spell = 1784, type = "ability"}, -- Stealth
        { spell = 1833, type = "ability"}, -- Cheap Shot
        { spell = 1856, type = "ability"}, -- Vanish
        { spell = 1943, type = "ability"}, -- Rupture
        { spell = 1966, type = "ability"}, -- Feint
        { spell = 2983, type = "ability"}, -- Sprint
        { spell = 5277, type = "ability"}, -- Evasion
        { spell = 6770, type = "ability"}, -- Sap
        { spell = 16511, type = "ability", talent = 3}, -- Hemorrhage
        { spell = 31224, type = "ability"}, -- Cloak of Shadows
        { spell = 32645, type = "ability"}, -- Envenom
        { spell = 36554, type = "ability"}, -- Shadowstep
        { spell = 51723, type = "ability"}, -- Fan of Knives
        { spell = 57934, type = "ability"}, -- Tricks of the Trade
        { spell = 79140, type = "ability"}, -- Vendetta
        { spell = 115191, type = "ability"}, -- Stealth
        { spell = 137619, type = "ability", talent = 20}, -- Marked for Death
        { spell = 152150, type = "ability", talent = 21}, -- Death from Above
        { spell = 185311, type = "ability"}, -- Crimson Vial
        { spell = 185565, type = "ability"}, -- Poisoned Knife
        { spell = 192759, type = "ability"}, -- Kingsbane
        { spell = 200806, type = "ability", talent = 18}, -- Exsanguinate
      },
      icon = 458726
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 209754, type = "buff", unit = "player", pvptalent = 8}, -- Boarding Party
        { spell = 213995, type = "buff", unit = "player", pvptalent = 16}, -- Cheap Tricks
        { spell = 207777, type = "ability", pvptalent = 17, titleSuffix = L["cooldown"]}, -- Dismantle
        { spell = 207777, type = "debuff", unit = "target", pvptalent = 17, titleSuffix = L["debuff"]}, -- Dismantle
        { spell = 212210, type = "ability", pvptalent = 15, titleSuffix = L["cooldown"]}, -- Drink Up Me Hearties
        {
          title = L["Crimson Vial Item Count"],
          icon = "Interface\\Icons\\inv_misc_potiona5",
          pvptalent = 15,
          triggers = { [0] = { trigger = { type = "status", event = "Item Count", use_itemName = true, itemName = "137222", unevent = "auto" }}}
        },
        { spell = 198529, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Plunder Armor
        { spell = 198529, type = "debuff", unit = "target", pvptalent = 18, titleSuffix = L["debuff"]}, -- Plunder Armor
        { spell = 198368, type = "buff", unit = "group", pvptalent = 13}, -- Take Your Cut
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 1784, type = "buff", unit = "player" }, -- Stealth
        { spell = 1966, type = "buff", unit = "player" }, -- Feint
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 5171, type = "buff", unit = "player", talent = 19 }, -- Slice and Dice
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 13750, type = "buff", unit = "player" }, -- Adrenaline Rush
        { spell = 13877, type = "buff", unit = "player" }, -- Blade Flurry
        { spell = 31224, type = "buff", unit = "player" }, -- Cloak of Shadows
        { spell = 45182, type = "buff", unit = "player", talent = 12 }, -- Cheating Death
        { spell = 51690, type = "buff", unit = "player" }, -- Killing Spree
        { spell = 152150, type = "buff", unit = "player" }, -- Death from Above
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 193356, type = "buff", unit = "player" }, -- Broadsides
        { spell = 193357, type = "buff", unit = "player" }, -- Shark Infested Waters
        { spell = 193358, type = "buff", unit = "player" }, -- Grand Melee
        { spell = 193359, type = "buff", unit = "player" }, -- True Bearing
        { spell = 193538, type = "buff", unit = "player", talent = 17 }, -- Alacrity
        { spell = 195627, type = "buff", unit = "player" }, -- Opportunity
        { spell = 199600, type = "buff", unit = "player" }, -- Buried Treasure
        { spell = 199603, type = "buff", unit = "player" }, -- Jolly Roger
        { spell = 199754, type = "buff", unit = "player" }, -- Riposte
        { spell = 202754, type = "buff", unit = "player" }, -- Hidden Blade
        { spell = 202776, type = "buff", unit = "player" }, -- Blurred Time
      },
      icon = 132350
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1776, type = "debuff", unit = "target" }, -- Gouge
        { spell = 1833, type = "debuff", unit = "target" }, -- Cheap Shot
        { spell = 2094, type = "debuff", unit = "multi" }, -- Blind
        { spell = 6770, type = "debuff", unit = "multi" }, -- Sap
        { spell = 45181, type = "debuff", unit = "player", talent = 12 }, -- Cheated Death
        { spell = 199743, type = "debuff", unit = "multi", talent = 13 }, -- Parley
        { spell = 137619, type = "debuff", unit = "target", talent = 20 }, -- Marked for Death
        { spell = 185763, type = "debuff", unit = "target" }, -- Pistol Shot
        { spell = 185778, type = "debuff", unit = "target", talent = 16 }, -- Shellshocked
        { spell = 196937, type = "debuff", unit = "target", talent = 1 }, -- Ghostly Strike
        { spell = 199740, type = "debuff", unit = "target" }, -- Bribe
        { spell = 199804, type = "debuff", unit = "target" }, -- Between the Eyes
        { spell = 202665, type = "debuff", unit = "player" }, -- Curse of the Dreadblades
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
        { spell = 1833, type = "ability"}, -- Cheap Shot
        { spell = 1856, type = "ability"}, -- Vanish
        { spell = 1966, type = "ability"}, -- Feint
        { spell = 2094, type = "ability"}, -- Blind
        { spell = 2098, type = "ability"}, -- Run Through
        { spell = 2983, type = "ability"}, -- Sprint
        { spell = 6770, type = "ability"}, -- Sap
        { spell = 8676, type = "ability"}, -- Ambush
        { spell = 13750, type = "ability"}, -- Adrenaline Rush
        { spell = 13877, type = "ability"}, -- Blade Flurry
        { spell = 31224, type = "ability"}, -- Cloak of Shadows
        { spell = 51690, type = "ability", talent = 18}, -- Killing Spree
        { spell = 137619, type = "ability", talent = 20}, -- Marked for Death
        { spell = 152150, type = "ability", talent = 21}, -- Death from Above
        { spell = 185311, type = "ability"}, -- Crimson Vial
        { spell = 185763, type = "ability"}, -- Pistol Shot
        { spell = 185767, type = "ability", talent = 16}, -- Cannonball Barrage
        { spell = 193315, type = "ability"}, -- Saber Slash
        { spell = 193316, type = "ability"}, -- Roll the Bones
        { spell = 195457, type = "ability", talent = 4}, -- Grappling Hook
        { spell = 199740, type = "ability"}, -- Bribe
        { spell = 199743, type = "ability", talent = 13}, -- Parley
        { spell = 199754, type = "ability"}, -- Riposte
        { spell = 199804, type = "ability"}, -- Between the Eyes
        { spell = 202665, type = "ability"}, -- Curse of the Dreadblades
      },
      icon = 135610
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198097, type = "debuff", unit = "target", pvptalent = 16}, -- Creeping Venom
        { spell = 206328, type = "ability", pvptalent = 15}, -- Shiv
        { spell = 197091, type = "debuff", unit = "target", pvptalent = 15}, -- Neurotoxin
        { spell = 198222, type = "debuff", unit = "target", pvptalent = 18}, -- System Shock
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 1784, type = "buff", unit = "player" }, -- Stealth
        { spell = 1966, type = "buff", unit = "player" }, -- Feint
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 5277, type = "buff", unit = "player" }, -- Evasion
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 31224, type = "buff", unit = "player" }, -- Cloak of Shadows
        { spell = 31665, type = "buff", unit = "player" }, -- Master of Subtlety
        { spell = 36554, type = "buff", unit = "player" }, -- Shadowstep
        { spell = 45182, type = "buff", unit = "player", talent = 12 }, -- Cheating Death
        { spell = 115191, type = "buff", unit = "player" }, -- Stealth
        { spell = 115192, type = "buff", unit = "player", talent = 5 }, -- Subterfuge
        { spell = 115193, type = "buff", unit = "player" }, -- Vanish
        { spell = 121471, type = "buff", unit = "player" }, -- Shadow Blades
        { spell = 152150, type = "buff", unit = "player", talent = 21 }, -- Death from Above
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 185422, type = "buff", unit = "player" }, -- Shadow Dance
        { spell = 193538, type = "buff", unit = "player", talent = 17 }, -- Alacrity
        { spell = 197603, type = "buff", unit = "player" }, -- Embrace of Darkness
        { spell = 206237, type = "buff", unit = "player" }, -- Enveloping Shadows
        { spell = 212283, type = "buff", unit = "player" }, -- Symbols of Death
        { spell = 220901, type = "buff", unit = "player" }, -- Goremaw's Bite
        { spell = 227151, type = "buff", unit = "player" }, -- Death
      },
      icon = 376022
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 1833, type = "debuff", unit = "target" }, -- Cheap Shot
        { spell = 2094, type = "debuff", unit = "target" }, -- Blind
        { spell = 6770, type = "debuff", unit = "multi" }, -- Sap
        { spell = 45181, type = "debuff", unit = "player", talent = 12 }, -- Cheated Death
        { spell = 137619, type = "debuff", unit = "target", talent = 20 }, -- Marked for Death
        { spell = 195452, type = "debuff", unit = "target" }, -- Nightblade
        { spell = 196958, type = "debuff", unit = "target" }, -- Strike from the Shadows
        { spell = 206760, type = "debuff", unit = "target" }, -- Night Terrors
        { spell = 209786, type = "debuff", unit = "target" }, -- Goremaw's Bite
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
        { spell = 1833, type = "ability"}, -- Cheap Shot
        { spell = 1856, type = "ability"}, -- Vanish
        { spell = 1966, type = "ability"}, -- Feint
        { spell = 2094, type = "ability"}, -- Blind
        { spell = 2983, type = "ability"}, -- Sprint
        { spell = 5277, type = "ability"}, -- Evasion
        { spell = 6770, type = "ability"}, -- Sap
        { spell = 31224, type = "ability"}, -- Cloak of Shadows
        { spell = 36554, type = "ability"}, -- Shadowstep
        { spell = 114014, type = "ability"}, -- Shuriken Toss
        { spell = 115191, type = "ability"}, -- Stealth
        { spell = 121471, type = "ability"}, -- Shadow Blades
        { spell = 137619, type = "ability", talent = 20}, -- Marked for Death
        { spell = 152150, type = "ability", talent = 21}, -- Death from Above
        { spell = 185311, type = "ability"}, -- Crimson Vial
        { spell = 185313, type = "ability"}, -- Shadow Dance
        { spell = 185438, type = "ability"}, -- Shadowstrike
        { spell = 195452, type = "ability"}, -- Nightblade
        { spell = 197393, type = "ability"}, -- Finality: Eviscerate
        { spell = 197835, type = "ability"}, -- Shuriken Storm
        { spell = 200758, type = "ability", talent = 3}, -- Gloomblade
        { spell = 206237, type = "ability"}, -- Enveloping Shadows
        { spell = 209782, type = "ability"}, -- Goremaw's Bite
        { spell = 212283, type = "ability"}, -- Symbols of Death
      },
      icon = 236279
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 213981, type = "ability", pvptalent = 15, titleSuffix = L["cooldown"]}, -- Cold Blood
        { spell = 213981, type = "buff", unit = "player", pvptalent = 15, titleSuffix = L["debuff"]}, -- Cold Blood
        { spell = 198688, type = "debuff", unit = "target", pvptalent = 14}, -- Cold Blood
        { spell = 207736, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Shadowy Duel
        { spell = 207736, type = "buff", unit = "player", pvptalent = 18, titleSuffix = L["debuff"]}, -- Shadowy Duel
        { spell = 212182, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"]}, -- Smoke Bomb
        { spell = 212182, type = "debuff", unit = "player", pvptalent = 12, titleSuffix = L["debuff"]}, -- Smoke Bomb
        { spell = 199027, type = "buff", unit = "player", pvptalent = 13}, -- Smoke Bomb
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01",
    },
  },
}

templates.class.PRIEST = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 17, type = "buff", unit = "group" }, -- Power Word: Shield
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 2096, type = "buff", unit = "player" }, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player", talent = 14 }, -- Power Infusion
        { spell = 33206, type = "buff", unit = "group" }, -- Pain Suppression
        { spell = 45243, type = "buff", unit = "player" }, -- Focused Will
        { spell = 47536, type = "buff", unit = "player" }, -- Rapture
        { spell = 65081, type = "buff", unit = "player", talent = 5 }, -- Body and Soul
        { spell = 81782, type = "buff", unit = "group" }, -- Power Word: Barrier
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 121557, type = "buff", unit = "player", talent = 4 }, -- Angelic Feather
        { spell = 123254, type = "buff", unit = "player", talent = 15 }, -- Angelic Feather
        { spell = 152118, type = "buff", unit = "target", talent = 16 }, -- Clarity of Will
        { spell = 193065, type = "buff", unit = "player", talent = 3 }, -- Masochism
        { spell = 194384, type = "buff", unit = "group" }, -- Atonement
        { spell = 197763, type = "buff", unit = "player" }, -- Borrowed Time
        { spell = 197767, type = "buff", unit = "player" }, -- Speed of the Pious
        { spell = 198069, type = "buff", unit = "player" }, -- Power of the Dark Side
        { spell = 198076, type = "buff", unit = "player" }, -- Sins of the Many
        { spell = 216135, type = "buff", unit = "player" }, -- Vestments of Discipline
      },
      icon = 458720
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 605, type = "debuff", unit = "multi"}, -- Mind Control
        { spell = 2096, type = "debuff", unit = "target" }, -- Mind Vision
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
        { spell = 204213, type = "debuff", unit = "target", talent = 19 }, -- Purge the Wicked
        { spell = 208772, type = "debuff", unit = "target" }, -- Smite
        { spell = 214621, type = "debuff", unit = "target", talent = 3 }, -- Schism
        { spell = 219521, type = "debuff", unit = "player" }, -- Shadow Covenant
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability"}, -- Power Word: Shield
        { spell = 527, type = "ability"}, -- Purify
        { spell = 586, type = "ability"}, -- Fade
        { spell = 8122, type = "ability"}, -- Psychic Scream
        { spell = 9484, type = "ability" }, -- Shackle Undead
        { spell = 10060, type = "ability", talent = 14}, -- Power Infusion
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 33206, type = "ability"}, -- Pain Suppression
        { spell = 34433, type = "ability"}, -- Shadowfiend
        { spell = 47536, type = "ability"}, -- Rapture
        { spell = 47540, type = "ability"}, -- Penance
        { spell = 62618, type = "ability"}, -- Power Word: Barrier
        { spell = 73325, type = "ability"}, -- Leap of Faith
        { spell = 110744, type = "ability", talent = 17}, -- Divine Star
        { spell = 120517, type = "ability", talent = 18}, -- Halo
        { spell = 121536, type = "ability", talent = 4}, -- Angelic Feather
        { spell = 123040, type = "ability", talent = 12}, -- Mindbender
        { spell = 129250, type = "ability", talent = 10}, -- Power Word: Solace
        { spell = 204263, type = "ability", talent = 7}, -- Shining Force
        { spell = 207946, type = "ability"}, -- Light's Wrath
        { spell = 214621, type = "ability", talent = 3}, -- Schism
      },
      icon = 253400
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 197862, type = "ability", pvptalent = 17, titleSuffix = L["cooldown"]}, -- Archangel
        { spell = 197862, type = "buff", unit = "player", pvptalent = 17, titleSuffix = L["buff"]}, -- Archangel
        { spell = 197871, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Dark Archangel
        { spell = 197871, type = "buff", unit = "player", pvptalent = 18, titleSuffix = L["buff"]}, -- Dark Archangel
        { spell = 211681, type = "buff", unit = "group", pvptalent = 16}, -- Power Word: Fortitude
        { spell = 196440, type = "buff", unit = "target", pvptalent = 9}, -- Purified Resolve
        { spell = 221660, type = "buff", unit = "player", pvptalent = 11}, -- Holy Concentration
        { spell = 195329, type = "buff", unit = "player", pvptalent = 4}, -- Defender of the Weak
        { spell = 195488, type = "buff", unit = "player", pvptalent = 5}, -- Vim and Vigor
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 139, type = "buff", unit = "group" }, -- Renew
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 19236, type = "buff", unit = "player" }, -- Desperate Prayer
        { spell = 41635, type = "buff", unit = "group" }, -- Prayer of Mending
        { spell = 45243, type = "buff", unit = "player" }, -- Focused Will
        { spell = 47788, type = "buff", unit = "group" }, -- Guardian Spirit
        { spell = 64843, type = "buff", unit = "player", fullscan = true }, -- Divine Hymn
        { spell = 64844, type = "buff", unit = "player", fullscan = true }, -- Divine Hymn
        { spell = 64901, type = "buff", unit = "player", talent = 12 }, -- Symbol of Hope
        { spell = 77489, type = "buff", unit = "player" }, -- Echo of Light
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 114255, type = "buff", unit = "player", talent = 13 }, -- Surge of Light
        { spell = 121557, type = "buff", unit = "player", talent = 4 }, -- Angelic Feather
        { spell = 123254, type = "buff", unit = "player" }, -- Twist of Fate
        { spell = 196490, type = "buff", unit = "player" }, -- Power of the Naaru
        { spell = 196644, type = "buff", unit = "player" }, -- Blessing of T'uure
        { spell = 197030, type = "buff", unit = "player" }, -- Divinity
        { spell = 200183, type = "buff", unit = "player", talent = 19 }, -- Apotheosis
        { spell = 208065, type = "buff", unit = "player" }, -- Light of T'uure
        { spell = 214121, type = "buff", unit = "player", talent = 5 }, -- Body and Mind
      },
      icon = 135953
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 605, type = "debuff", unit = "multi"}, -- Mind Control
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
        { spell = 14914, type = "debuff", unit = "target" }, -- Holy Fire
        { spell = 200196, type = "debuff", unit = "target" }, -- Holy Word: Chastise
        { spell = 200200, type = "debuff", unit = "target" }, -- Holy Word: Chastise
      },
      icon = 135972
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 527, type = "ability"}, -- Purify
        { spell = 586, type = "ability"}, -- Fade
        { spell = 2050, type = "ability"}, -- Holy Word: Serenity
        { spell = 9484, type = "ability" }, -- Shackle Undead
        { spell = 14914, type = "ability"}, -- Holy Fire
        { spell = 19236, type = "ability", talent = 6}, -- Desperate Prayer
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 33076, type = "ability"}, -- Prayer of Mending
        { spell = 34861, type = "ability"}, -- Holy Word: Sanctify
        { spell = 47788, type = "ability"}, -- Guardian Spirit
        { spell = 64843, type = "ability"}, -- Divine Hymn
        { spell = 64901, type = "ability", talent = 12}, -- Symbol of Hope
        { spell = 73325, type = "ability" }, -- Leap of Faith
        { spell = 88625, type = "ability"}, -- Holy Word: Chastise
        { spell = 110744, type = "ability", talent = 17}, -- Divine Star
        { spell = 120517, type = "ability", talent = 18}, -- Halo
        { spell = 121536, type = "ability", talent = 4}, -- Angelic Feather
        { spell = 200183, type = "ability", talent = 19}, -- Apotheosis
        { spell = 204263, type = "ability", talent = 7}, -- Shining Force
        { spell = 204883, type = "ability", talent = 21}, -- Circle of Healing
        { spell = 208065, type = "ability"}, -- Light of T'uure
        { spell = 214121, type = "ability", talent = 5}, -- Body and Mind
      },
      icon = 135937
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 221660, type = "buff", unit = "player", pvptalent = 11}, -- Holy Concentration
        { spell = 213602, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"]}, -- Greater Fade
        { spell = 213602, type = "buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]}, -- Greater Fade
        { spell = 213610, type = "ability", pvptalent = 9, titleSuffix = L["cooldown"]}, -- Holy Ward
        { spell = 213610, type = "buff", unit = "group", pvptalent = 9, titleSuffix = L["buff"]}, -- Holy Ward
        { spell = 196762, type = "ability", pvptalent = 6, titleSuffix = L["cooldown"]}, -- Inner Focus
        { spell = 196762, type = "buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"]}, -- Inner Focus
        { spell = 197268, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Ray of Hope
        { spell = 197268, type = "buff", unit = "group", pvptalent = 18, titleSuffix = L["buff"]}, -- Ray of Hope
        { spell = 20711, type = "ability", pvptalent = 17}, -- Spirit of Redemption
        { spell = 195329, type = "buff", unit = "player", pvptalent = 4}, -- Defender of the Weak
        { spell = 195488, type = "buff", unit = "player", pvptalent = 5}, -- Vim and Vigor
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 17, type = "buff", unit = "player" }, -- Power Word: Shield
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 2096, type = "buff", unit = "player" }, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player", talent = 16 }, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player" }, -- Vampiric Embrace
        { spell = 15407, type = "buff", unit = "player" }, -- Mind Flay
        { spell = 47585, type = "buff", unit = "player" }, -- Dispersion
        { spell = 65081, type = "buff", unit = "player", talent = 5 }, -- Body and Soul
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 123254, type = "buff", unit = "player", talent = 1 }, -- Twist of Fate
        { spell = 124430, type = "buff", unit = "player", talent = 15 }, -- Shadowy Insight
        { spell = 193065, type = "buff", unit = "player", talent = 3 }, -- Masochism
        { spell = 193223, type = "buff", unit = "player", talent = 21 }, -- Surrender to Madness
        { spell = 194022, type = "buff", unit = "player" }, -- Mental Fortitude
        { spell = 194025, type = "buff", unit = "player" }, -- Thrive in the Shadows
        { spell = 194249, type = "buff", unit = "player" }, -- Voidform
        { spell = 197937, type = "buff", unit = "player" }, -- Lingering Insanity
        { spell = 205065, type = "buff", unit = "player" }, -- Void Torrent
        { spell = 205372, type = "buff", unit = "player", talent = 12 }, -- Void Ray
      },
      icon = 237566
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 605, type = "debuff", unit = "multi"}, -- Mind Control
        { spell = 2096, type = "debuff", unit = "target" }, -- Mind Vision
        { spell = 9484, type = "debuff", unit = "multi" }, -- Shackle Undead
        { spell = 15407, type = "debuff", unit = "target" }, -- Mind Flay
        { spell = 15487, type = "debuff", unit = "target" }, -- Silence
        { spell = 34914, type = "debuff", unit = "target" }, -- Vampiric Touch
        { spell = 48045, type = "debuff", unit = "target" }, -- Mind Sear
        { spell = 193473, type = "debuff", unit = "target" }, -- Mind Flay
        { spell = 205065, type = "debuff", unit = "target" }, -- Void Torrent
        { spell = 205369, type = "debuff", unit = "target" }, -- Mind Bomb
        { spell = 212570, type = "debuff", unit = "player", talent = 21 }, -- Surrendered Soul
        { spell = 217673, type = "debuff", unit = "target" }, -- Mind Spike
        { spell = 226943, type = "debuff", unit = "target", talent = 7 }, -- Mind Bomb
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability"}, -- Power Word: Shield
        { spell = 586, type = "ability"}, -- Fade
        { spell = 8092, type = "ability"}, -- Mind Blast
        { spell = 9484, type = "ability"}, -- Shackle Undead
        { spell = 10060, type = "ability", talent = 16}, -- Power Infusion
        { spell = 15286, type = "ability"}, -- Vampiric Embrace
        { spell = 15487, type = "ability"}, -- Silence
        { spell = 32375, type = "ability"}, -- Mass Dispel
        { spell = 32379, type = "ability"}, -- Shadow Word: Death
        { spell = 34433, type = "ability"}, -- Shadowfiend
        { spell = 47585, type = "ability"}, -- Dispersion
        { spell = 193223, type = "ability", talent = 21}, -- Surrender to Madness
        { spell = 200174, type = "ability", talent = 18}, -- Mindbender
        { spell = 205065, type = "ability"}, -- Void Torrent
        { spell = 205351, type = "ability", talent = 3}, -- Shadow Word: Void
        { spell = 205369, type = "ability", talent = 7}, -- Mind Bomb
        { spell = 205385, type = "ability", talent = 17}, -- Shadow Crash
        { spell = 205448, type = "ability"}, -- Void Bolt
        { spell = 213634, type = "ability"}, -- Purify Diesease
      },
      icon = 136230
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 199412, type = "buff", unit = "player", pvptalent = 12}, -- Edge of Insanity
        { spell = 199683, type = "debuff", unit = "target", pvptalent = 17}, -- Last Word
        { spell = 211522, type = "ability", pvptalent = 16}, -- Psyfiend
        { spell = 108968, type = "ability", pvptalent = 18}, -- Void Shift
        { spell = 195640, type = "buff", unit = "player", pvptalent = 4}, -- Train of Thought
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_priest_shadoworbs",
    },
  },
}

templates.class.SHAMAN = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 546, type = "buff", unit = "player" }, -- Water Walking
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 6196, type = "buff", unit = "player" }, -- Far Sight
        { spell = 16166, type = "buff", unit = "player", talent = 16}, -- Elemental Mastery
        { spell = 16246, type = "buff", unit = "player"}, -- Elemental Focus
        { spell = 77762, type = "buff", unit = "player" }, -- Lava Surge
        { spell = 108271, type = "buff", unit = "player" }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 5 }, -- Ancestral Guidance
        { spell = 114050, type = "buff", unit = "player", talent = 19 }, -- Ascendance
        { spell = 118522, type = "buff", unit = "player", talent = 10 }, -- Elemental Blast: Critical Strike
        { spell = 157384, type = "buff", unit = "player" }, -- Eye of the Storm
        { spell = 173183, type = "buff", unit = "player", talent = 10 }, -- Elemental Blast: Haste
        { spell = 173184, type = "buff", unit = "player", talent = 10 }, -- Elemental Blast: Mastery
        { spell = 191877, type = "buff", unit = "player" }, -- Power of the Maelstrom
        { spell = 192082, type = "buff", unit = "player", talent = 6 }, -- Wind Rush
        { spell = 202192, type = "buff", unit = "player", talent = 1 }, -- Resonance Totem
        { spell = 205495, type = "buff", unit = "player" }, -- Stormkeeper
        { spell = 210652, type = "buff", unit = "player", talent = 1 }, -- Storm Totem
        { spell = 210658, type = "buff", unit = "player", talent = 1 }, -- Ember Totem
        { spell = 210659, type = "buff", unit = "player", talent = 1 }, -- Tailwind Totem
        { spell = 210714, type = "buff", unit = "player", talent = 15 }, -- Icefury
      },
      icon = 451169
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 51490, type = "debuff", unit = "target" }, -- Thunderstorm
        { spell = 51514, type = "debuff", unit = "multi"}, -- Hex
        { spell = 64695, type = "debuff", unit = "target", talent = 8 }, -- Earthgrab
        { spell = 77505, type = "debuff", unit = "target" }, -- Earthquake
        { spell = 116947, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 118297, type = "debuff", unit = "target" }, -- Immolate
        { spell = 118345, type = "debuff", unit = "target" }, -- Pulverize
        { spell = 118905, type = "debuff", unit = "target", talent = 7 }, -- Static Charge
        { spell = 157375, type = "debuff", unit = "target" }, -- Gale Force
        { spell = 182387, type = "debuff", unit = "target" }, -- Earthquake
        { spell = 188389, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 196840, type = "debuff", unit = "target" }, -- Frost Shock
        { spell = 197209, type = "debuff", unit = "multi", talent = 20 }, -- Lightning Rod
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 2825, type = "ability"}, -- Bloodlust
        { spell = 16166, type = "ability", talent = 16}, -- Elemental Mastery
        { spell = 51485, type = "ability", talent = 8}, -- Earthgrab Totem
        { spell = 51490, type = "ability"}, -- Thunderstorm
        { spell = 51505, type = "ability"}, -- Lava Burst
        { spell = 51514, type = "ability"}, -- Hex
        { spell = 51886, type = "ability"}, -- Cleanse Spirit
        { spell = 57994, type = "ability"}, -- Wind Shear
        { spell = 108271, type = "ability"}, -- Astral Shift
        { spell = 108281, type = "ability", talent = 5}, -- Ancestral Guidance
        { spell = 114050, type = "ability", talent = 19}, -- Ascendance
        { spell = 117014, type = "ability", talent = 10}, -- Elemental Blast
        { spell = 192058, type = "ability", talent = 7}, -- w Totem
        { spell = 192063, type = "ability", talent = 4}, -- Gust of Wind
        { spell = 192077, type = "ability", talent = 6}, -- Wind Rush Totem
        { spell = 192222, type = "ability", talent = 21}, -- Liquid Magma Totem
        { spell = 192249, type = "ability", talent = 17}, -- Storm Elemental
        { spell = 196932, type = "ability", talent = 9}, -- Voodoo Totem
        { spell = 198067, type = "ability"}, -- Fire Elemental
        { spell = 198103, type = "ability"}, -- Earth Elemental
        { spell = 205495, type = "ability"}, -- Stormkeeper
        { spell = 210714, type = "ability", talent = 15}, -- Icefury
      },
      icon = 135790
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 204399, type = "debuff", unit = "target", pvptalent = 16}, -- Earthfury
        { spell = 204437, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Lightning Lasso
        { spell = 204437, type = "debuff", unit = "target", pvptalent = 18, titleSuffix = L["debuff"]}, -- Lightning Lasso
        { spell = 195640, type = "buff", unit = "player", pvptalent = 4}, -- Train of Thought
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = 135990,
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 546, type = "buff", unit = "player" }, -- Water Walking
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 6196, type = "buff", unit = "player" }, -- Far Sight
        { spell = 58875, type = "buff", unit = "player" }, -- Spirit Walk
        { spell = 108271, type = "buff", unit = "player" }, -- Astral Shift
        { spell = 114051, type = "buff", unit = "player", talent = 19 }, -- Ascendance
        { spell = 187878, type = "buff", unit = "player" }, -- Crash Lightning
        { spell = 192082, type = "buff", unit = "player", talent = 6 }, -- Wind Rush
        { spell = 192106, type = "buff", unit = "player" }, -- Lightning Shield
        { spell = 194084, type = "buff", unit = "player" }, -- Flametongue
        { spell = 195222, type = "buff", unit = "player" }, -- Stormlash
        { spell = 196834, type = "buff", unit = "player" }, -- Frostbrand
        { spell = 197211, type = "buff", unit = "player" }, -- Fury of Air
        { spell = 198249, type = "buff", unit = "player" }, -- Elemental Healing
        { spell = 198293, type = "buff", unit = "player" }, -- Wind Strikes
        { spell = 198300, type = "buff", unit = "player" }, -- Gathering Storms
        { spell = 199055, type = "buff", unit = "player" }, -- Unleash Doom
        { spell = 201846, type = "buff", unit = "player" }, -- Stormbringer
        { spell = 201898, type = "buff", unit = "player", talent = 1 }, -- Windsong
        { spell = 202004, type = "buff", unit = "player", talent = 20 }, -- Landslide
        { spell = 204945, type = "buff", unit = "player" }, -- Doom Winds
        { spell = 215785, type = "buff", unit = "player", talent = 2 }, -- Hot Hand
        { spell = 215864, type = "buff", unit = "player", talent = 4 }, -- Rainfall
        { spell = 218825, type = "buff", unit = "player", talent = 3 }, -- Boulderfist
      },
      icon = 136099
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 51514, type = "debuff", unit = "multi"}, -- Hex
        { spell = 64695, type = "debuff", unit = "target", talent = 8 }, -- Earthgrab
        { spell = 116947, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 118905, type = "debuff", unit = "target", talent = 7 }, -- Static Charge
        { spell = 147732, type = "debuff", unit = "target" }, -- Frostbrand Attack
        { spell = 188089, type = "debuff", unit = "target", talent = 21 }, -- Earthen Spike
        { spell = 197214, type = "debuff", unit = "target" }, -- Sundering
        { spell = 197385, type = "debuff", unit = "target", talent = 17 }, -- Fury of Air
        { spell = 224125, type = "debuff", unit = "target" }, -- Fiery Jaws
        { spell = 224127, type = "debuff", unit = "target" }, -- Crackling Surge
      },
      icon = 462327
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 2825, type = "ability", talent = 3}, -- Bloodlust
        { spell = 17364, type = "ability"}, -- Stormstrike
        { spell = 51485, type = "ability", talent = 8}, -- Earthgrab Totem
        { spell = 51514, type = "ability"}, -- Hex
        { spell = 51886, type = "ability"}, -- Cleanse Spirit
        { spell = 57994, type = "ability"}, -- Wind Shear
        { spell = 58875, type = "ability"}, -- Spirit Walk
        { spell = 108271, type = "ability"}, -- Astral Shift
        { spell = 114051, type = "ability", talent = 19}, -- Ascendance
        { spell = 187837, type = "ability", talent = 14}, -- Lightning Bolt
        { spell = 187874, type = "ability"}, -- Crash Lightning
        { spell = 188089, type = "ability", talent = 21}, -- Earthen Spike
        { spell = 192058, type = "ability", talent = 7}, -- Lightning Surge Totem
        { spell = 192077, type = "ability", talent = 6}, -- Wind Rush Totem
        { spell = 193796, type = "ability"}, -- Flametongue
        { spell = 196884, type = "ability", talent = 5}, -- Feral Lunge
        { spell = 196932, type = "ability", talent = 9}, -- Voodoo Totem
        { spell = 197214, type = "ability", talent =18}, -- Sundering
        { spell = 198506, type = "ability"}, -- Feral Spirit
        { spell = 201897, type = "ability", talent = 3}, -- Boulderfist
        { spell = 201898, type = "ability", talent = 1}, -- Windsong
        { spell = 204945, type = "ability"}, -- Doom Winds
        { spell = 215864, type = "ability", talent = 4}, -- Rainfall
      },
      icon = 1370984
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 210918, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"]}, -- Ethereal Form
        { spell = 210918, type = "buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]}, -- Ethereal Form
        { spell = 204366, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Thundercharge
        { spell = 204366, type = "buff", unit = "player", pvptalent = 18, titleSuffix = L["buff"]}, -- Thundercharge
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = 135990,
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 546, type = "buff", unit = "player" }, -- Water Walking
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 6196, type = "buff", unit = "player" }, -- Far Sight
        { spell = 53390, type = "buff", unit = "player" }, -- Tidal Waves
        { spell = 61295, type = "buff", unit = "player" }, -- Riptide
        { spell = 73685, type = "buff", unit = "player", talent = 2 }, -- Unleash Life
        { spell = 73920, type = "buff", unit = "player" }, -- Healing Rain
        { spell = 77762, type = "buff", unit = "player" }, -- Lava Surge
        { spell = 79206, type = "buff", unit = "player" }, -- Spiritwalker's Grace
        { spell = 98007, type = "buff", unit = "player" }, -- Spirit Link Totem
        { spell = 108271, type = "buff", unit = "player" }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 8 }, -- Ancestral Guidance
        { spell = 114052, type = "buff", unit = "player", talent = 19 }, -- Ascendance
        { spell = 157504, type = "buff", unit = "player" }, -- Cloudburst Totem
        { spell = 192082, type = "buff", unit = "player", talent = 6 }, -- Wind Rush
        { spell = 201633, type = "buff", unit = "player", talent = 14 }, -- Earthen Shield
        { spell = 207288, type = "buff", unit = "player" }, -- Queen Ascendant
        { spell = 207400, type = "buff", unit = "target" }, -- Ancestral Vigor
        { spell = 207495, type = "buff", unit = "target", talent = 13 }, -- Ancestral Protection
        { spell = 207527, type = "buff", unit = "player" }, -- Ghost in the Mist
        { spell = 207778, type = "buff", unit = "player" }, -- Gift of the Queen
        { spell = 208205, type = "buff", unit = "player" }, -- Cumulative Upkeep
        { spell = 208416, type = "buff", unit = "player" }, -- Sense of Urgency
        { spell = 208899, type = "buff", unit = "player" }, -- Queen's Decree
        { spell = 209950, type = "buff", unit = "player" }, -- Caress of the Tidemother
        { spell = 216251, type = "buff", unit = "player", talent = 1 }, -- Undulation
      },
      icon = 252995
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 51514, type = "debuff", unit = "multi"}, -- Hex
        { spell = 64695, type = "debuff", unit = "target", talent = 8 }, -- Earthgrab
        { spell = 116947, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 118905, type = "debuff", unit = "target", talent = 7 }, -- Static Charge
        { spell = 188838, type = "debuff", unit = "target" }, -- Flame Shock
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 2825, type = "ability"}, -- Bloodlust
        { spell = 5394, type = "ability"}, -- Healing Stream Totem
        { spell = 51485, type = "ability", talent = 8}, -- Earthgrab Totem
        { spell = 51505, type = "ability"}, -- Lava Burst
        { spell = 51514, type = "ability"}, -- Hex
        { spell = 57994, type = "ability"}, -- Wind Shear
        { spell = 61295, type = "ability"}, -- Riptide
        { spell = 73685, type = "ability", talent = 2}, -- Unleash Life
        { spell = 73920, type = "ability"}, -- Healing Rain
        { spell = 77130, type = "ability"}, -- Purify Spirit
        { spell = 79206, type = "ability"}, -- Spiritwalker's Grace
        { spell = 98008, type = "ability"}, -- Spirit Link Totem
        { spell = 108271, type = "ability"}, -- Astral Shift
        { spell = 108280, type = "ability"}, -- Healing Tide Totem
        { spell = 108281, type = "ability", talent = 8}, -- Ancestral Guidance
        { spell = 114052, type = "ability", talent = 19}, -- Ascendance
        { spell = 157153, type = "ability", talent = 17}, -- Cloudburst Totem
        { spell = 188838, type = "ability"}, -- Flame Shock
        { spell = 192058, type = "ability", talent = 7}, -- Lightning Surge Totem
        { spell = 192063, type = "ability", talent = 4}, -- Gust of Wind
        { spell = 192077, type = "ability", talent = 6}, -- Wind Rush Totem
        { spell = 196932, type = "ability", talent = 9}, -- Voodoo Totem
        { spell = 197995, type = "ability", talent = 20}, -- Wellspring
        { spell = 198838, type = "ability", talent = 14}, -- Earthen Shield Totem
        { spell = 207399, type = "ability", talent = 13}, -- Ancestral Protection Totem
        { spell = 207778, type = "ability"}, -- Gift of the Queen
      },
      icon = 135127
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 204288, type = "ability", pvptalent = 17, titleSuffix = L["cooldown"]}, -- Earth Shield
        { spell = 204288, type = "buff", unit = "group", pvptalent = 17, titleSuffix = L["buff"]}, -- Earth Shield
        { spell = 204336, type = "ability", pvptalent = 15}, -- Grounding Totem
        { spell = 204293, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Spirit Link
        { spell = 204293, type = "buff", unit = "group", pvptalent = 18, titleSuffix = L["buff"]}, -- Spirit Link
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
}

templates.class.MAGE = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 11426, type = "buff", unit = "player" }, -- Ice Barrier
        { spell = 12042, type = "buff", unit = "player" }, -- Arcane Power
        { spell = 12051, type = "buff", unit = "player" }, -- Evocation
        { spell = 45438, type = "buff", unit = "player" }, -- Ice Block
        { spell = 79683, type = "buff", unit = "player" }, -- Arcane Missiles!
        { spell = 108839, type = "buff", unit = "player", talent = 13 }, -- Ice Floes
        { spell = 110960, type = "buff", unit = "player", fullscan = true }, -- Greater Invisibility
        { spell = 116267, type = "buff", unit = "player", talent = 9 }, -- Incanter's Flow
        { spell = 198924, type = "buff", unit = "player", talent = 20 }, -- Quickening
        { spell = 205025, type = "buff", unit = "player", talent = 2 }, -- Presence of Mind
        { spell = 210126, type = "buff", unit = "player", talent = 1 }, -- Arcane Familiar
        { spell = 212799, type = "buff", unit = "player" }, -- Displacement Beacon
      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 31589, type = "debuff", unit = "target" }, -- Slow
        { spell = 41425, type = "debuff", unit = "player" }, -- Hypothermia
        { spell = 82691, type = "debuff", unit = "target", talent = 14 }, -- Ring of Frost
        { spell = 87023, type = "debuff", unit = "player", talent = 5 }, -- Cauterize
        { spell = 87024, type = "debuff", unit = "player", talent = 5 }, -- Cauterized
        { spell = 114923, type = "debuff", unit = "target", talent = 16 }, -- Nether Tempest
        { spell = 210134, type = "debuff", unit = "target", talent = 18 }, -- Erosion
        { spell = 210824, type = "debuff", unit = "target" }, -- Touch of the Magi
      },
      icon = 135848
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability"}, -- Counterspell
        { spell = 11426, type = "ability"}, -- Ice Barrier
        { spell = 12042, type = "ability"}, -- Arcane Power
        { spell = 12051, type = "ability"}, -- Evocation
        { spell = 44425, type = "ability"}, -- Arcane Barrage
        { spell = 45438, type = "ability"}, -- Ice Block
        { spell = 55342, type = "ability", talent = 7}, -- Mirror Image
        { spell = 80353, type = "ability"}, -- Time Warp
        { spell = 108839, type = "ability", talent = 13}, -- Ice Floes
        { spell = 110959, type = "ability"}, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 14}, -- Ring of Frost
        { spell = 116011, type = "ability", talent = 8}, -- Rune of Power
        { spell = 153626, type = "ability", talent = 21}, -- Arcane Orb
        { spell = 157980, type = "ability", talent = 10}, -- Supernova
        { spell = 195676, type = "ability"}, -- Displacement
        { spell = 205022, type = "ability", talent = 1}, -- Arcane Familiar
        { spell = 205025, type = "ability", talent = 2}, -- Presence of Mind
        { spell = 205032, type = "ability", talent = 11}, -- Charged Up
        { spell = 212653, type = "ability", talent = 4}, -- Shimmer
      },
      icon = 136075
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 198158, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Mass Invisibility
        { spell = 198158, type = "buff", unit = "player", pvptalent = 18, titleSuffix = L["buff"]}, -- Mass Invisibility
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\spell_arcane_arcane01",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 66, type = "buff", unit = "player" }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 11426, type = "buff", unit = "player" }, -- Ice Barrier
        { spell = 32612, type = "buff", unit = "player" }, -- Invisibility
        { spell = 45438, type = "buff", unit = "player" }, -- Ice Block
        { spell = 48107, type = "buff", unit = "player" }, -- Heating Up
        { spell = 48108, type = "buff", unit = "player" }, -- Hot Streak!
        { spell = 108839, type = "buff", unit = "player", talent = 13 }, -- Ice Floes
        { spell = 116267, type = "buff", unit = "player", talent = 9 }, -- Incanter's Flow
        { spell = 157644, type = "buff", unit = "player" }, -- Enhanced Pyrotechnics
        { spell = 190319, type = "buff", unit = "player" }, -- Combustion
        { spell = 194316, type = "buff", unit = "player" }, -- Cauterizing Blink
        { spell = 194329, type = "buff", unit = "player" }, -- Pyretic Incantation
        { spell = 227482, type = "buff", unit = "player" }, -- Scorched Earth
      },
      icon = 1035045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 2120, type = "debuff", unit = "target" }, -- Flamestrike
        { spell = 12654, type = "debuff", unit = "target" }, -- Ignite
        { spell = 31661, type = "debuff", unit = "target" }, -- Dragon's Breath
        { spell = 41425, type = "debuff", unit = "player" }, -- Hypothermia
        { spell = 82691, type = "debuff", unit = "target", talent = 14 }, -- Ring of Frost
        { spell = 87023, type = "debuff", unit = "player", talent = 5 }, -- Cauterize
        { spell = 87024, type = "debuff", unit = "player", talent = 5 }, -- Cauterized
        { spell = 155158, type = "debuff", unit = "target", talent = 21 }, -- Meteor Burn
        { spell = 157981, type = "debuff", unit = "target", talent = 10 }, -- Blast Wave
        { spell = 194432, type = "debuff", unit = "target" }, -- Aftershocks
        { spell = 194522, type = "debuff", unit = "target" }, -- Blast Furnace
        { spell = 217694, type = "debuff", unit = "target", talent = 16 }, -- Living Bomb
        { spell = 226757, type = "debuff", unit = "target", talent = 2 }, -- Conflagration
      },
      icon = 135818
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability"}, -- Invisibility
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 2139, type = "ability"}, -- Counterspell
        { spell = 11426, type = "ability"}, -- Ice Barrier
        { spell = 31661, type = "ability"}, -- Dragon's Breath
        { spell = 44457, type = "ability", talent = 16}, -- Living Bomb
        { spell = 45438, type = "ability"}, -- Ice Block
        { spell = 55342, type = "ability", talent = 7}, -- Mirror Image
        { spell = 80353, type = "ability"}, -- Time Warp
        { spell = 108839, type = "ability", talent = 13}, -- Ice Floes
        { spell = 108853, type = "ability"}, -- Inferno Blast
        { spell = 113724, type = "ability", talent = 14}, -- Ring of Frost
        { spell = 116011, type = "ability", talent = 8}, -- Rune of Power
        { spell = 153561, type = "ability", talent = 21}, -- Meteor
        { spell = 157981, type = "ability", talent = 10}, -- Blast Wave
        { spell = 190319, type = "ability"}, -- Combustion
        { spell = 194466, type = "ability"}, -- Phoenix's Flames
        { spell = 198929, type = "ability", talent = 20}, -- Cinderstorm
        { spell = 205029, type = "ability", talent = 11}, -- Flame On
        { spell = 212653, type = "ability", talent = 4}, -- Shimmer
      },
      icon = 610633
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 203285, type = "buff", unit = "player", pvptalent = 17}, -- Flamecannon
        { spell = 203278, type = "buff", unit = "player", pvptalent = 13}, -- Tinder
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 66, type = "buff", unit = "player" }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 12472, type = "buff", unit = "player" }, -- Icy Veins
        { spell = 44544, type = "buff", unit = "player" }, -- Fingers of Frost
        { spell = 45438, type = "buff", unit = "player" }, -- Ice Block
        { spell = 108839, type = "buff", unit = "player", talent = 13 }, -- Ice Floes
        { spell = 116267, type = "buff", unit = "player", talent = 9 }, -- Incanter's Flow
        { spell = 195391, type = "buff", unit = "player" }, -- Jouster
        { spell = 195418, type = "buff", unit = "player" }, -- Chain Reaction
        { spell = 195446, type = "buff", unit = "player" }, -- Chilled to the Core
        { spell = 205473, type = "buff", unit = "player" }, -- Icicles
        { spell = 205766, type = "buff", unit = "player", talent = 3 }, -- Bone Chilling
        { spell = 208166, type = "buff", unit = "player", fullscan = true }, -- Ray of Frost
      },
      icon = 236227
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 118, type = "debuff", unit = "multi" }, -- Polymorph
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 41425, type = "debuff", unit = "player" }, -- Hypothermia
        { spell = 59638, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 82691, type = "debuff", unit = "target", talent = 14 }, -- Ring of Frost
        { spell = 87023, type = "debuff", unit = "player", talent = 5 }, -- Cauterize
        { spell = 87024, type = "debuff", unit = "player", talent = 5 }, -- Cauterized
        { spell = 112948, type = "debuff", unit = "target", talent = 16 }, -- Frost Bomb
        { spell = 135029, type = "debuff", unit = "target" }, -- Water Jet
        { spell = 157997, type = "debuff", unit = "target" }, -- Ice Nova
        { spell = 199786, type = "debuff", unit = "target", talent = 20 }, -- Glacial Spike
        { spell = 205021, type = "debuff", unit = "target", talent = 1 }, -- Ray of Frost
        { spell = 205708, type = "debuff", unit = "target" }, -- Chilled
        { spell = 212792, type = "debuff", unit = "target" }, -- Cone of Cold
      },
      icon = 236208
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability"}, -- Invisibility
        { spell = 120, type = "ability"}, -- Cone of Cold
        { spell = 122, type = "ability"}, -- Frost Nova
        { spell = 1953, type = "ability"}, -- Blink
        { spell = 12472, type = "ability"}, -- Icy Veins
        { spell = 31687, type = "ability"}, -- Summon Water Elemental
        { spell = 33395, type = "ability", titleSuffix = L["(Water Elemental)"]}, -- Freeze
        { spell = 45438, type = "ability"}, -- Ice Block
        { spell = 55342, type = "ability", talent = 7}, -- Mirror Image
        { spell = 80353, type = "ability"}, -- Time Warp
        { spell = 84714, type = "ability"}, -- Frozen Orb
        { spell = 108839, type = "ability", talent = 13}, -- Ice Floes
        { spell = 113724, type = "ability", talent = 14}, -- Ring of Frost
        { spell = 116011, type = "ability", talent = 8}, -- Rune of Power
        { spell = 153595, type = "ability", talent = 21}, -- Comet Storm
        { spell = 157997, type = "ability", talent = 10}, -- Ice Nova
        { spell = 190356, type = "ability"}, -- Blizzard
        { spell = 205021, type = "ability", talent = 1}, -- Ray of Frost
        { spell = 205030, type = "ability", talent = 11}, -- Frozen Touch
        { spell = 212653, type = "ability", talent = 4}, -- Shimmer
        { spell = 214634, type = "ability"}, -- Ebonbolt
      },
      icon = 629077
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 206432, type = "buff", unit = "player", pvptalent = 17}, -- Burst of Cold
        { spell = 198121, type = "debuff", unit = "target", pvptalent = 14}, -- Frostbite
        { spell = 198144, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Ice Form
        { spell = 198144, type = "buff", unit = "player", pvptalent = 18, titleSuffix = L["buff"]}, -- Ice Form
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
}


templates.class.WARLOCK = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 126, type = "buff", unit = "player" }, -- Eye of Kilrogg
        { spell = 5697, type = "buff", unit = "player" }, -- Unending Breath
        { spell = 20707, type = "buff", unit = "group" }, -- Soulstone
        { spell = 48018, type = "buff", unit = "player", talent = 13 }, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player" }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 15 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 14 }, -- Burning Rush
        { spell = 119899, type = "buff", unit = "player" }, -- Cauterize Master
        { spell = 196098, type = "buff", unit = "player", talent = 12 }, -- Soul Harvest
        { spell = 196099, type = "buff", unit = "player", talent = 18 }, -- Demonic Power
        { spell = 196104, type = "buff", unit = "player", talent = 6 }, -- Mana Tap
        { spell = 199281, type = "buff", unit = "player" }, -- Compound Interest
        { spell = 199646, type = "buff", unit = "player" }, -- Wrath of Consumption
        { spell = 216695, type = "buff", unit = "player" }, -- Tormented Souls
        { spell = 216708, type = "buff", unit = "player" }, -- Deadwind Harvester
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 689, type = "debuff", unit = "target"}, -- Drain Life
        { spell = 710, type = "debuff", unit = "multi" }, -- Banish
        { spell = 980, type = "debuff", unit = "target" }, -- Agony
        { spell = 5484, type = "debuff", unit = "target", talent = 9 }, -- Howl of Terror
        { spell = 6789, type = "debuff", unit = "target", talent = 8 }, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target" }, -- Suffering
        { spell = 22703, type = "debuff", unit = "target" }, -- Infernal Awakening
        { spell = 27243, type = "debuff", unit = "target" }, -- Seed of Corruption
        { spell = 30108, type = "debuff", unit = "target" }, -- Unstable Affliction
        { spell = 48181, type = "debuff", unit = "target", talent = 1 }, -- Haunt
        { spell = 63106, type = "debuff", unit = "target", talent = 10 }, -- Siphon Life
        { spell = 113942, type = "debuff", unit = "player" }, -- Demonic Gateway
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
        { spell = 168501, type = "debuff", unit = "multi" }, -- Enslave Demon
        { spell = 170995, type = "debuff", unit = "target" }, -- Cripple
        { spell = 171014, type = "debuff", unit = "target" }, -- Seethe
        { spell = 171017, type = "debuff", unit = "target" }, -- Meteor Strike
        { spell = 198590, type = "debuff", unit = "target", talent = 3 }, -- Drain Soul
        { spell = 205178, type = "debuff", unit = "target", talent = 19 }, -- Soul Effigy
        { spell = 205179, type = "debuff", unit = "target", talent = 20 }, -- Phantom Singularity
      },
      icon = 136139
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 1122, type = "ability"}, -- Summon Infernal
        { spell = 5484, type = "ability", talent = 9}, -- Howl of Terror
        { spell = 6789, type = "ability", talent = 8}, -- Mortal Coil
        { spell = 18540, type = "ability"}, -- Summon Doomguard
        { spell = 20707, type = "ability"}, -- Soulstone
        { spell = 29893, type = "ability"}, -- Create Soulwell
        { spell = 48020, type = "ability", talent = 13}, -- Demonic Circle
        { spell = 48181, type = "ability", talent = 1}, -- Haunt
        { spell = 104773, type = "ability"}, -- Unending Resolve
        { spell = 108416, type = "ability", talent = 15}, -- Dark Pact
        { spell = 108503, type = "ability", talent = 18}, -- Grimoire of Sacrifice
        { spell = 111771, type = "ability"}, -- Demonic Gateway
        { spell = 119905, type = "ability"}, -- Cauterize Master
        { spell = 119909, type = "ability"}, -- Whiplash
        { spell = 119910, type = "ability"}, -- Spell Lock
        { spell = 171140, type = "ability"}, -- Shadow Lock
        { spell = 171152, type = "ability"}, -- Meteor Strike
        { spell = 196098, type = "ability", talent = 12}, -- Soul Harvest
        { spell = 205179, type = "ability", talent = 20}, -- Phantom Singularity
        { spell = 6358, type = "ability", L["(Pet)"]}, -- Seduction
        { spell = 17735, type = "ability", L["(Pet)"]}, -- Suffering
        { spell = 19647, type = "ability", L["(Pet)"]}, -- Shadow Bulwark
        { spell = 89808, type = "ability", L["(Pet)"]}, -- Singe Magic
      },
      icon = 615103
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 86121, type = "ability", pvptalent = 18}, -- Soul Swap
        { spell = 213398, type = "ability", pvptalent = 14, titleSuffix = L["cooldown"]}, -- Soulburn
        { spell = 213398, type = "buff", unit = "player", pvptalent = 14, titleSuffix = L["buff"]}, -- Soulburn
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 5697, type = "buff", unit = "player" }, -- Unending Breath
        { spell = 20707, type = "buff", unit = "group" }, -- Soulstone
        { spell = 48018, type = "buff", unit = "player", talent = 13 }, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player" }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 18 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 17 }, -- Burning Rush
        { spell = 119899, type = "buff", unit = "player" }, -- Cauterize Master
        { spell = 171982, type = "buff", unit = "player", talent = 18 }, -- Demonic Synergy
        { spell = 193440, type = "buff", unit = "player" }, -- Demonwrath
        { spell = 196098, type = "buff", unit = "player", talent = 12 }, -- Soul Harvest
        { spell = 196606, type = "buff", unit = "player", talent = 1 }, -- Shadowy Inspiration
        { spell = 199281, type = "buff", unit = "player" }, -- Compound Interest
        { spell = 205146, type = "buff", unit = "player", talent = 3 }, -- Demonic Calling
        { spell = 216695, type = "buff", unit = "player" }, -- Tormented Souls
      },
      icon = 1378284
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 603, type = "debuff", unit = "target" }, -- Doom
        { spell = 689, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 710, type = "debuff", unit = "multi" }, -- Banish
        { spell = 6789, type = "debuff", unit = "target", talent = 8}, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target" }, -- Suffering
        { spell = 30213, type = "debuff", unit = "target" }, -- Legion Strike
        { spell = 30283, type = "debuff", unit = "target", talent = 9 }, -- Shadowfury
        { spell = 89766, type = "debuff", unit = "target" }, -- Axe Toss
        { spell = 113942, type = "debuff", unit = "player" }, -- Demonic Gateway
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
        { spell = 168501, type = "debuff", unit = "multi" }, -- Enslave Demon
        { spell = 205178, type = "debuff", unit = "target" }, -- Soul Effigy
        { spell = 205181, type = "debuff", unit = "target", talent = 2 }, -- Shadowflame
      },
      icon = 136122
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 1122, type = "ability"}, -- Summon Infernal
        { spell = 6789, type = "ability", talent = 8}, -- Mortal Coil
        { spell = 18540, type = "ability"}, -- Summon Doomguard
        { spell = 20707, type = "ability"}, -- Soulstone
        { spell = 29893, type = "ability"}, -- Create Soulwell
        { spell = 30283, type = "ability", talent = 9}, -- Shadowfury
        { spell = 48020, type = "ability", talent = 13}, -- Demonic Circle
        { spell = 104316, type = "ability"}, -- Call Dreadstalkers
        { spell = 104773, type = "ability"}, -- Unending Resolve
        { spell = 108416, type = "ability", talent = 15}, -- Dark Pact
        { spell = 111771, type = "ability"}, -- Demonic Gateway
        { spell = 119905, type = "ability"}, -- Cauterize Master
        { spell = 119909, type = "ability"}, -- Whiplash
        { spell = 119910, type = "ability"}, -- Spell Lock
        { spell = 119914, type = "ability"}, -- Felstorm
        { spell = 196098, type = "ability", talent = 12}, -- Soul Harvest
        { spell = 205180, type = "ability", talent = 19}, -- Summon Darkglare
        { spell = 205181, type = "ability", talent = 2}, -- Shadowflame
        { spell = 211714, type = "ability"}, -- Thal'kiel's Consumption
        { spell = 6358, type = "ability", L["(Pet)"]}, -- Seduction
        { spell = 17735, type = "ability", L["(Pet)"]}, -- Shadow Bulwark
        { spell = 19647, type = "ability", L["(Pet)"]}, -- Shadow Bulwark
        { spell = 89808, type = "ability", L["(Pet)"]}, -- Singe Magic
        { spell = 89751, type = "ability", L["(Pet)"]}, -- Felstorm
        { spell = 89766, type = "ability", L["(Pet)"]}, -- Axe Toss
      },
      icon = 1378282
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 212459, type = "ability", pvptalent = 17}, -- Call Fel Lord
        { spell = 212619, type = "ability", pvptalent = 14}, -- Call Felhunter
        { spell = 201996, type = "ability", pvptalent = 18}, -- Call Observer
        { spell = 212623, type = "ability", pvptalent = 15}, -- Singe Magic
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 126, type = "buff", unit = "player" }, -- Eye of Kilrogg
        { spell = 5697, type = "buff", unit = "player" }, -- Unending Breath
        { spell = 20707, type = "buff", unit = "group" }, -- Soulstone
        { spell = 48018, type = "buff", unit = "player", talent = 13 }, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player" }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 15 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 14 }, -- Burning Rush
        { spell = 117828, type = "buff", unit = "player", talent = 1 }, -- Backdraft
        { spell = 196098, type = "buff", unit = "player", talent = 12 }, -- Soul Harvest
        { spell = 196099, type = "buff", unit = "player", talent = 18 }, -- Demonic Power
        { spell = 196104, type = "buff", unit = "player", talent = 6 }, -- Mana Tap
        { spell = 196304, type = "buff", unit = "player" }, -- Eternal Struggle
        { spell = 196546, type = "buff", unit = "player" }, -- Conflagration of Chaos
        { spell = 215165, type = "buff", unit = "player" }, -- Devourer of Life
        { spell = 216695, type = "buff", unit = "player" }, -- Tormented Souls
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 689, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 710, type = "debuff", unit = "multi" }, -- Banish
        { spell = 6789, type = "debuff", unit = "target", talent = 8 }, -- Mortal Coil
        { spell = 22703, type = "debuff", unit = "target" }, -- Infernal Awakening
        { spell = 30283, type = "debuff", unit = "target", talent = 9 }, -- Shadowfury
        { spell = 80240, type = "debuff", unit = "target" }, -- Havoc
        { spell = 89766, type = "debuff", unit = "player" }, -- Axe Toss
        { spell = 113942, type = "debuff", unit = "player" }, -- Demonic Gateway
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
        { spell = 157736, type = "debuff", unit = "target" }, -- Immolate
        { spell = 168501, type = "debuff", unit = "multi" }, -- Enslave Demon
        { spell = 196414, type = "debuff", unit = "target", talent = 10 }, -- Eradication
        { spell = 226802, type = "debuff", unit = "player" }, -- Lord of Flames
      },
      icon = 135817
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 698, type = "ability"}, -- Ritual of Summoning
        { spell = 1122, type = "ability"}, -- Summon Infernal
        { spell = 6789, type = "ability", talent = 8}, -- Mortal Coil
        { spell = 17962, type = "ability"}, -- Conflagrate
        { spell = 18540, type = "ability"}, -- Summon Doomguard
        { spell = 20707, type = "ability"}, -- Soulstone
        { spell = 29893, type = "ability"}, -- Create Soulwell
        { spell = 30283, type = "ability", talent = 9}, -- Shadowfury
        { spell = 48020, type = "ability", talent = 13}, -- Demonic Circle
        { spell = 80240, type = "ability"}, -- Havoc
        { spell = 104773, type = "ability"}, -- Unending Resolve
        { spell = 108416, type = "ability", talent = 15}, -- Dark Pact
        { spell = 108503, type = "ability", talent = 18}, -- Grimoire of Sacrific
        { spell = 111771, type = "ability"}, -- Demonic Gatewaye
        { spell = 152108, type = "ability", talent = 5}, -- Cataclysm
        { spell = 196098, type = "ability", talent = 12}, -- Soul Harvest
        { spell = 196447, type = "ability", talent = 20}, -- Channel Demonfire
        { spell = 196586, type = "ability"}, -- Dimensional Rift
        { spell = 6358, type = "ability", L["(Pet)"]}, -- Seduction
        { spell = 17735, type = "ability", L["(Pet)"]}, -- Shadow Bulwark
        { spell = 19647, type = "ability", L["(Pet)"]}, -- Shadow Bulwark
        { spell = 89808, type = "ability", L["(Pet)"]}, -- Singe Magic
      },
      icon = 135807
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 212269, type = "debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"]}, -- Fel Fissure
        { spell = 212284, type = "ability", pvptalent = 17, titleSuffix = L["cooldown"]}, -- Firestone
        { spell = 212284, type = "buff", unit = "player", pvptalent = 17, titleSuffix = L["buff"]}, -- Firestone
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
    },
  },
}

templates.class.MONK = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 101643, type = "buff", unit = "player" }, -- Transcendence
        { spell = 116841, type = "buff", unit = "player", talent = 5 }, -- Tiger's Lust
        { spell = 116844, type = "buff", unit = "player", talent = 10 }, -- Ring of Peace
        { spell = 116847, type = "buff", unit = "player" }, -- Rushing Jade Wind
        { spell = 119085, type = "buff", unit = "player", talent = 4 }, -- Chi Torpedo
        { spell = 120954, type = "buff", unit = "player" }, -- Fortifying Brew
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 122783, type = "buff", unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 195630, type = "buff", unit = "player" }, -- Elusive Brawler
        { spell = 196608, type = "buff", unit = "player", talent = 2 }, -- Eye of the Tiger
        { spell = 196739, type = "buff", unit = "player", talent = 19 }, -- Elusive Dance
        { spell = 213177, type = "buff", unit = "player" }, -- Swift as a Coursing River
        { spell = 213341, type = "buff", unit = "player" }, -- Fortification
        { spell = 214373, type = "buff", unit = "player" }, -- Brew-Stache
        { spell = 215479, type = "buff", unit = "player" }, -- Ironskin Brew
        { spell = 228563, type = "buff", unit = "player", talent = 20 }, -- Blackout Combo
        { spell = 227678, type = "buff", unit = "player" }, -- Gifted Student
      },
      icon = 613398
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115078, type = "debuff", unit = "multi" }, -- Paralysis
        { spell = 116189, type = "debuff", unit = "target" }, -- Provoke
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target", talent = 12 }, -- Leg Sweep
        { spell = 121253, type = "debuff", unit = "target" }, -- Keg Smash
        { spell = 123725, type = "debuff", unit = "target" }, -- Breath of Fire
        { spell = 124273, type = "debuff", unit = "player" }, -- Heavy Stagger
        { spell = 124274, type = "debuff", unit = "player" }, -- Moderate Stagger
        { spell = 124275, type = "debuff", unit = "player" }, -- Light Stagger
        { spell = 115069, type = "debuff", unit = "player",
          spellIds = {124275, 124274, 124273} }, -- Any Stagger
        { spell = 140023, type = "debuff", unit = "target", talent = 10 }, -- Ring of Peace
        { spell = 196608, type = "debuff", unit = "target", talent = 2 }, -- Eye of the Tiger
        { spell = 196727, type = "debuff", unit = "target" }, -- Provoke
        { spell = 213063, type = "debuff", unit = "target" }, -- Dark Side of the Moon
        { spell = 214326, type = "debuff", unit = "target" }, -- Exploding Keg
      },
      icon = 611419
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 109132, type = "ability"}, -- Roll
        { spell = 115008, type = "ability", talent = 4}, -- Chi Torpedo
        { spell = 115078, type = "ability"}, -- Paralysis
        { spell = 115098, type = "ability", talent = 3}, -- Chi Wave
        { spell = 115176, type = "ability"}, -- Zen Meditation
        { spell = 115181, type = "ability"}, -- Breath of Fire
        { spell = 115203, type = "ability"}, -- Fortifying Brew
        { spell = 115308, type = "ability"}, -- Ironskin Brew
        { spell = 115315, type = "ability", talent = 11}, -- Summon Black Ox Statue
        { spell = 115399, type = "ability", talent = 8}, -- Black Ox Brew
        { spell = 115546, type = "ability"}, -- Provoke
        { spell = 116705, type = "ability"}, -- Spear Hand Strike
        { spell = 116841, type = "ability", talent = 5}, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 10}, -- Ring of Peace
        { spell = 116847, type = "ability", talent = 16}, -- Rushing Jade Wind
        { spell = 119381, type = "ability", talent = 12}, -- Leg Sweep
        { spell = 119582, type = "ability"}, -- Purifying Brew
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 121253, type = "ability"}, -- Keg Smash
        { spell = 122278, type = "ability"}, -- Dampen Harm
        { spell = 122281, type = "ability", talent = 13}, -- Healing Elixir
        { spell = 122783, type = "ability"}, -- Diffuse Magic
        { spell = 123986, type = "ability", talent = 1}, -- Chi Burst
        { spell = 132578, type = "ability", talent = 17}, -- Invoke Niuzao, the Black Ox
        { spell = 205523, type = "ability"}, -- Blackout Strike
        { spell = 214326, type = "ability"}, -- Exploding Keg
        { spell = 218164, type = "ability"}, -- Detox
      },
      icon = 133701
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 202335, type = "ability", pvptalent = 17, titleSuffix = L["cooldown"]}, -- Double Barrel
        { spell = 202335, type = "buff", unit = "player", pvptalent = 17, titleSuffix = L["buff"]}, -- Double Barrel
        { spell = 202346, type = "debuff", unit = "target", pvptalent = 17, titleSuffix = L["debuff"]}, -- Double Barrel
        { spell = 202162, type = "ability", pvptalent = 13, titleSuffix = L["cooldown"]}, -- Guard
        { spell = 202162, type = "buff", unit = "player", pvptalent = 13, titleSuffix = L["buff"]}, -- Guard
        { spell = 202272, type = "ability", pvptalent = 16, titleSuffix = L["cooldown"]}, -- Incendiary Brew
        { spell = 202272, type = "buff", unit = "player", pvptalent = 16, titleSuffix = L["buff"]}, -- Incendiary Brew
        { spell = 202370, type = "ability", pvptalent = 18}, -- Mighty Ox Kick
        { spell = 213658, type = "ability", pvptalent = 15, titleSuffix = L["cooldown"]}, -- Craft: Nimble Brew
        {
          title = L["Nimble Brew Item Count"],
          icon = "Interface\\Icons\\spell_monk_nimblebrew",
          pvptalent = 15,
          triggers = { [0] = { trigger = { type = "status", event = "Item Count", use_itemName = true, itemName = "137648", unevent = "auto" }}}
        },
        { spell = 213664, type = "buff", unit = "player", pvptalent = 15, titleSuffix = L["buff"]}, -- Nimble Brew
        { spell = 195336, type = "buff", unit = "player", pvptalent = 4}, -- Relentless Assault
        { spell = 206891, type = "debuff", unit = "target", pvptalent = 5}, -- Intimated
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\monk_stance_drunkenox",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 101546, type = "buff", unit = "player" }, -- Spinning Crane Kick
        { spell = 101643, type = "buff", unit = "player" }, -- Transcendence
        { spell = 115175, type = "buff", unit = "player" }, -- Soothing Mist
        { spell = 116680, type = "buff", unit = "player" }, -- Thunder Focus Tea
        { spell = 116841, type = "buff", unit = "player", talent = 5 }, -- Tiger's Lust
        { spell = 116844, type = "buff", unit = "player", talent = 10 }, -- Ring of Peace
        { spell = 116849, type = "buff", unit = "group" }, -- Life Cocoon
        { spell = 119085, type = "buff", unit = "player", talent = 4 }, -- Chi Torpedo
        { spell = 119611, type = "buff", unit = "player" }, -- Renewing Mist
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 122783, type = "buff", unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 124682, type = "buff", unit = "player" }, -- Enveloping Mist
        { spell = 191840, type = "buff", unit = "player" }, -- Essence Font
        { spell = 196725, type = "buff", unit = "player" }, -- Refreshing Jade Wind
        { spell = 197206, type = "buff", unit = "player" }, -- Uplifting Trance
        { spell = 197908, type = "buff", unit = "player" }, -- Mana Tea
        { spell = 197916, type = "buff", unit = "player", talent = 7 }, -- Lifecycles (Vivify)
        { spell = 197919, type = "buff", unit = "player", talent = 7 }, -- Lifecycles (Enveloping Mist)
        { spell = 198533, type = "buff", unit = "player" }, -- Soothing Mist
        { spell = 199407, type = "buff", unit = "player" }, -- Light on Your Feet
        { spell = 199668, type = "buff", unit = "player" }, -- Blessings of Yu'lon
        { spell = 199888, type = "buff", unit = "player" }, -- The Mists of Sheilun
        { spell = 202090, type = "buff", unit = "player", talent = 8 }, -- Teachings of the Monastery
        { spell = 214478, type = "buff", unit = "player" }, -- Shroud of Mist
      },
      icon = 627487
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115078, type = "debuff", unit = "multi" }, -- Paralysis
        { spell = 116189, type = "debuff", unit = "target" }, -- Provoke
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 140023, type = "debuff", unit = "target", talent = 10 }, -- Ring of Peace
        { spell = 198909, type = "debuff", unit = "target", talent = 11 }, -- Song of Chi-Ji
        { spell = 199387, type = "debuff", unit = "target" }, -- Spirit Tether
        { spell = 214411, type = "debuff", unit = "player" }, -- Celestial Breath
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100784, type = "ability"}, -- Blackout Kick
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 107428, type = "ability"}, -- Rising Sun Kick
        { spell = 115008, type = "ability", talent = 4}, -- Chi Torpedo
        { spell = 115078, type = "ability"}, -- Paralysis
        { spell = 115151, type = "ability"}, -- Renewing Mist
        { spell = 115310, type = "ability"}, -- Revival
        { spell = 115313, type = "ability", talent = 18}, -- Summon Jade Serpent Statue
        { spell = 115450, type = "ability"}, -- Detox
        { spell = 115546, type = "ability"}, -- Provoke
        { spell = 116680, type = "ability"}, -- Thunder Focus Tea
        { spell = 116841, type = "ability", talent = 5}, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 10}, -- Ring of Peace
        { spell = 116849, type = "ability"}, -- Life Cocoon
        { spell = 119381, type = "ability", talent = 12}, -- Leg Sweep
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 122278, type = "ability", talent = 15}, -- Dampen Harm
        { spell = 122281, type = "ability", talent = 13}, -- Healing Elixir
        { spell = 122783, type = "ability", talent = 14}, -- Diffuse Magic
        { spell = 123986, type = "ability", talent = 1}, -- Chi Burst
        { spell = 124081, type = "ability", talent = 2}, -- Zen Pulse
        { spell = 196725, type = "ability", talent = 16}, -- Refreshing Jade Wind
        { spell = 197908, type = "ability", talent = 19}, -- Mana Tea
        { spell = 197945, type = "ability", talent = 3}, -- Mistwalk
        { spell = 198664, type = "ability", talent = 17}, -- Invoke Chi-Ji, the Red Crane
        { spell = 198898, type = "ability", talent = 11}, -- Song of Chi-Ji
      },
      icon = 627485
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 201318, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"]}, -- Fortifying Elixir
        { spell = 201318, type = "buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]}, -- Fortifying Elixir
        { spell = 201447, type = "buff", unit = "player", pvptalent = 15}, -- Ride the Wind
        { spell = 202077, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Spinning Fire Blossom
        { spell = 123407, type = "debuff", unit = "target", pvptalent = 18, titleSuffix = L["debuff"]}, -- Spinning Fire Blossom
        { spell = 201233, type = "buff", unit = "player", pvptalent = 10}, -- Whirling Kicks
        { spell = 201325, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"]}, -- Zen Meditation
        { spell = 201325, type = "buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]}, -- Zen Meditation
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 101546, type = "buff", unit = "player" }, -- Spinning Crane Kick
        { spell = 101643, type = "buff", unit = "player" }, -- Transcendence
        { spell = 116768, type = "buff", unit = "player" }, -- Blackout Kick!
        { spell = 116841, type = "buff", unit = "player", talent = 5 }, -- Tiger's Lust
        { spell = 116844, type = "buff", unit = "player", talent = 10 }, -- Ring of Peace
        { spell = 116847, type = "buff", unit = "player", talent = 16 }, -- Rushing Jade Wind
        { spell = 119085, type = "buff", unit = "player", talent = 4 }, -- Chi Torpedo
        { spell = 122278, type = "buff", unit = "player", talent = 15 }, -- Dampen Harm
        { spell = 122783, type = "buff", unit = "player", talent = 14 }, -- Diffuse Magic
        { spell = 125174, type = "buff", unit = "player" }, -- Touch of Karma
        { spell = 129914, type = "buff", unit = "player", talent = 9 }, -- Power Strikes
        { spell = 137639, type = "buff", unit = "player" }, -- Storm, Earth, and Fire
        { spell = 152173, type = "buff", unit = "player", talent = 21 }, -- Serenity
        { spell = 195312, type = "buff", unit = "player" }, -- Good Karma
        { spell = 195321, type = "buff", unit = "player" }, -- Transfer the Power
        { spell = 195381, type = "buff", unit = "player" }, -- Healing Winds
        { spell = 196608, type = "buff", unit = "player", talent = 2 }, -- Eye of the Tiger
        { spell = 196741, type = "buff", unit = "player", talent = 15 }, -- Hit Combo
      },
      icon = 611420
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 115078, type = "debuff", unit = "multi" }, -- Paralysis
        { spell = 115080, type = "debuff", unit = "target" }, -- Touch of Death
        { spell = 115804, type = "debuff", unit = "target" }, -- Mortal Wounds
        { spell = 116095, type = "debuff", unit = "target" }, -- Disable
        { spell = 116189, type = "debuff", unit = "target" }, -- Provoke
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target", talent = 12 }, -- Leg Sweep
        { spell = 122470, type = "debuff", unit = "target" }, -- Touch of Karma
        { spell = 140023, type = "debuff", unit = "target", talent = 10 }, -- Ring of Peace
        { spell = 196608, type = "debuff", unit = "target", talent = 2 }, -- Eye of the Tiger
        { spell = 196723, type = "debuff", unit = "target", talent = 11 }, -- Dizzying Kicks
        { spell = 205320, type = "debuff", unit = "target" }, -- Strike of the Windlord
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 101545, type = "ability"}, -- Flying Serpent Kick
        { spell = 101643, type = "ability"}, -- Transcendence
        { spell = 107428, type = "ability"}, -- Rising Sun Kick
        { spell = 109132, type = "ability"}, -- Roll
        { spell = 113656, type = "ability"}, -- Fists of Fury
        { spell = 115008, type = "ability", talent = 4}, -- Chi Torpedo
        { spell = 115078, type = "ability"}, -- Paralysis
        { spell = 115080, type = "ability"}, -- Touch of Death
        { spell = 115098, type = "ability", talent = 3}, -- Chi Wave
        { spell = 115288, type = "ability", talent = 7}, -- Energizing Elixir
        { spell = 115546, type = "ability"}, -- Provoke
        { spell = 116705, type = "ability"}, -- Spear Hand Strike
        { spell = 116841, type = "ability", talent = 5}, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 10}, -- Ring of Peace
        { spell = 116847, type = "ability", talent = 16}, -- Rushing Jade Wind
        { spell = 119381, type = "ability", talent = 12}, -- Leg Sweep
        { spell = 119996, type = "ability"}, -- Transcendence: Transfer
        { spell = 122278, type = "ability", talent = 15}, -- Dampen Harm
        { spell = 122281, type = "ability", talent = 13}, -- Healing Elixir
        { spell = 122470, type = "ability"}, -- Touch of Karma
        { spell = 122783, type = "ability", talent = 14}, -- Diffuse Magic
        { spell = 123904, type = "ability", talent = 17}, -- Invoke Xuen, the White Tiger
        { spell = 123986, type = "ability", talent = 1}, -- Chi Burst
        { spell = 152173, type = "ability", talent = 21}, -- Serenity
        { spell = 152175, type = "ability", talent = 20}, -- Whirling Dragon Punch
        { spell = 205320, type = "ability"}, -- Strike of the Windlord
        { spell = 218164, type = "ability"}, -- Detox
      },
      icon = 627606
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 205655, type = "buff", unit = "target", pvptalent = 15}, -- Dome of Mist
        { spell = 216915, type = "buff", unit = "target", pvptalent = 16}, -- Fortune Turned
        { spell = 205234, type = "ability", pvptalent = 18}, -- Fortune Turned
        { spell = 124682, type = "ability", pvptalent = 10}, -- Surge of Mist
        { spell = 216113, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"]}, -- Way of the Crane
        { spell = 216113, type = "buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]}, -- Way of the Crane
        { spell = 124488, type = "buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]}, -- Zen Focus
        { spell = 195329, type = "buff", unit = "player", pvptalent = 4}, -- Defender of the Weak
        { spell = 195488, type = "buff", unit = "player", pvptalent = 5}, -- Vim and Vigor
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\ability_monk_healthsphere",
    },
  },
}

templates.class.DRUID = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 8936, type = "buff", unit = "player", talent = 9 }, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 8 }, -- Frenzied Regeneration
        { spell = 24858, type = "buff", unit = "player" }, -- Moonkin Form
        { spell = 29166, type = "buff", unit = "group" }, -- Innervate
        { spell = 102560, type = "buff", unit = "player", talent = 14 }, -- Incarnation: Chosen of Elune
        { spell = 137452, type = "buff", unit = "player", talent = 5 }, -- Displacer Beast
        { spell = 164545, type = "buff", unit = "player" }, -- Solar Empowerment
        { spell = 164547, type = "buff", unit = "player" }, -- Lunar Empowerment
        { spell = 191034, type = "buff", unit = "player" }, -- Starfall
        { spell = 192081, type = "buff", unit = "player", talent = 8 }, -- Ironfur
        { spell = 194223, type = "buff", unit = "player" }, -- Celestial Alignment
        { spell = 202425, type = "buff", unit = "player", talent = 2 }, -- Warrior of Elune
        { spell = 202461, type = "buff", unit = "player" }, -- Stellar Drift
        { spell = 202737, type = "buff", unit = "player", talent = 18 }, -- Blessing of Elune
        { spell = 202739, type = "buff", unit = "player", talent = 18 }, -- Blessing of An'she
        { spell = 202770, type = "buff", unit = "player", talent = 19 }, -- Fury of Elune
        { spell = 202942, type = "buff", unit = "player" }, -- Star Power
      },
      icon = 535045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 7 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 81261, type = "debuff", unit = "target" }, -- Solar Beam
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 155722, type = "debuff", unit = "target", fullscan = "true", titleSuffix = L["Bleed"] }, -- Rake
        { spell = 163505, type = "debuff", unit = "target", fullscan = "true", titleSuffix = L["Stun"] }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target" }, -- Sunfire
        { spell = 197637, type = "debuff", unit = "target" }, -- Stellar Empowerment
        { spell = 202347, type = "debuff", unit = "target", talent = 15 }, -- Stellar Flare
        { spell = 205644, type = "debuff", unit = "target" }, -- Force of Nature

      },
      icon = 236216
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 1850, type = "ability"}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 5211, type = "ability", talent = 10}, -- Mighty Bash
        { spell = 5215, type = "ability"}, -- Prowl
        { spell = 6795, type = "ability"}, -- Growl
        { spell = 18562, type = "ability", talent = 9}, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22812, type = "ability"}, -- Barkskin
        { spell = 22842, type = "ability", talent = 8}, -- Frenzied Regeneration
        { spell = 29166, type = "ability"}, -- Innervate
        { spell = 33917, type = "ability", talent = 8}, -- Mangle
        { spell = 78675, type = "ability"}, -- Solar Beam
        { spell = 102280, type = "ability", talent = 5}, -- Displacer Beast
        { spell = 102359, type = "ability", talent = 11}, -- Mass Entanglement
        { spell = 102383, type = "ability", talent = 6}, -- Wild Charge
        { spell = 102560, type = "ability", talent = 14}, -- Incarnation: Chosen of Elune
        { spell = 108238, type = "ability", talent = 4}, -- Renewal
        { spell = 132469, type = "ability", talent = 12}, -- Typhoon
        { spell = 194223, type = "ability"}, -- Celestial Alignment
        { spell = 202359, type = "ability", talent = 17}, -- Astral Communion
        { spell = 202360, type = "ability", talent = 18}, -- Blessing of the Ancients
        { spell = 202425, type = "ability", talent = 2}, -- Warrior of Elune
        { spell = 202767, type = "ability"}, -- New Moon
        { spell = 202770, type = "ability", talent = 19}, -- Fury of Elune
        { spell = 205636, type = "ability", talent = 1}, -- Force of Nature
      },
      icon = 136060
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 209753, type = "ability", pvptalent = 16, titleSuffix = L["cooldown"]}, -- Cyclone
        { spell = 209753, type = "debuff", unit = "target", pvptalent = 16, titleSuffix = L["debuff"]}, -- Cyclone
        { spell = 209749, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Faerie Swarm
        { spell = 209749, type = "debuff", unit = "target", pvptalent = 18, titleSuffix = L["debuff"]}, -- Faerie Swarm
        { spell = 209746, type = "buff", unit = "group", pvptalent = 15}, -- Moonkin Aura
        { spell = 195640, type = "buff", unit = "player", pvptalent = 4}, -- Train of Thought
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = "Interface\\Icons\\ability_druid_eclipseorange",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 5217, type = "buff", unit = "player" }, -- Tiger's Fury
        { spell = 8936, type = "buff", unit = "player", talent = 9 }, -- Regrowth
        { spell = 22842, type = "buff", unit = "player", talent = 8 }, -- Frenzied Regeneration
        { spell = 52610, type = "buff", unit = "player", talent = 15 }, -- Savage Roar
        { spell = 61336, type = "buff", unit = "player" }, -- Survival Instincts
        { spell = 69369, type = "buff", unit = "player" }, -- Predatory Swiftness
        { spell = 102543, type = "buff", unit = "player", talent = 14 }, -- Incarnation: King of the Jungle
        { spell = 102547, type = "buff", unit = "player" }, -- Prowl
        { spell = 106898, type = "buff", unit = "player" }, -- Stampeding Roar
        { spell = 106951, type = "buff", unit = "player" }, -- Berserk
        { spell = 135700, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 137452, type = "buff", unit = "player", talent = 5 }, -- Displacer Beast
        { spell = 145152, type = "buff", unit = "player", talent = 20 }, -- Bloodtalons
        { spell = 164545, type = "buff", unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 164547, type = "buff", unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 192081, type = "buff", unit = "player", talent = 8 }, -- Ironfur
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 202737, type = "buff", unit = "player" }, -- Blessing of Elune
        { spell = 210583, type = "buff", unit = "player" }, -- Ashamane's Energy
        { spell = 210649, type = "buff", unit = "player" }, -- Feral Instinct
        { spell = 210655, type = "buff", unit = "player" }, -- Protection of Ashamane
        { spell = 210664, type = "buff", unit = "player" }, -- Scent of Blood
      },
      icon = 136170
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target" }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 50259, type = "debuff", unit = "target" }, -- Dazed
        { spell = 58180, type = "debuff", unit = "target" }, -- Infected Wounds
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 106830, type = "debuff", unit = "target" }, -- Thrash
        { spell = 155625, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 155722, type = "debuff", unit = "target", fullscan = "true", titleSuffix = L["Bleed"] }, -- Rake
        { spell = 163505, type = "debuff", unit = "target", fullscan = "true", titleSuffix = L["Stun"] }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 7 }, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target" }, -- Thrash
        { spell = 203123, type = "debuff", unit = "target" }, -- Maim
        { spell = 210670, type = "debuff", unit = "target" }, -- Open Wounds
        { spell = 210705, type = "debuff", unit = "target" }, -- Ashamane's Rip
        { spell = 210723, type = "debuff", unit = "target" }, -- Ashamane's Frenzy
      },
      icon = 132152
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 1850, type = "ability"}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 5211, type = "ability", talent = 10}, -- Mighty Bash
        { spell = 5215, type = "ability"}, -- Prowl
        { spell = 5217, type = "ability"}, -- Tiger's Fury
        { spell = 6795, type = "ability"}, -- Growl
        { spell = 18562, type = "ability", talent = 9}, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22570, type = "ability"}, -- Maim
        { spell = 22842, type = "ability", talent = 8}, -- Frenzied Regeneration
        { spell = 33917, type = "ability", talent = 8}, -- Mangle
        { spell = 49376, type = "ability", talent = 6}, -- Wild Charge
        { spell = 61336, type = "ability"}, -- Survival Instincts
        { spell = 77758, type = "ability"}, -- Thrash
        { spell = 102280, type = "ability", talent = 5}, -- Displacer Beast
        { spell = 102359, type = "ability", talent = 11}, -- Mass Entanglement
        { spell = 102401, type = "ability", talent = 6}, -- Wild Charge
        { spell = 102543, type = "ability", talent = 14}, -- Incarnation: King of the Jungle
        { spell = 102547, type = "ability"}, -- Prowl
        { spell = 106839, type = "ability"}, -- Skull Bash
        { spell = 106898, type = "ability"}, -- Stampeding Roar
        { spell = 106951, type = "ability"}, -- Berserk
        { spell = 108238, type = "ability", talent = 4}, -- Renewal
        { spell = 132469, type = "ability", talent = 12}, -- Typhoon
        { spell = 197625, type = "ability", talent = 7}, -- Moonkin Form
        { spell = 197626, type = "ability", talent = 7}, -- Starsurge
        { spell = 202028, type = "ability", talent = 19}, -- Brutal Slash
        { spell = 202060, type = "ability", talent = 18}, -- Elune's Guidance
        { spell = 210722, type = "ability"}, -- Ashamane's Frenzy
      },
      icon = 236149
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 203199, type = "buff", unit = "player", pvptalent = 15}, -- Fury Swipes
        { spell = 202812, type = "buff", unit = "player", pvptalent = 12}, -- Primal Vitality
        { spell = 203242, type = "ability", pvptalent = 18}, -- Rip and Tear
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = "Interface\\Icons\\inv_mace_2h_pvp410_c_01",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 774, type = "buff", unit = "player", talent = 9 }, -- Rejuvenation
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 8936, type = "buff", unit = "player", talent = 9 }, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player" }, -- Frenzied Regeneration
        { spell = 61336, type = "buff", unit = "player" }, -- Survival Instincts
        { spell = 93622, type = "buff", unit = "player" }, -- Mangle!
        { spell = 102558, type = "buff", unit = "player", talent = 14 }, -- Incarnation: Guardian of Ursoc
        { spell = 106898, type = "buff", unit = "player" }, -- Stampeding Roar
        { spell = 137452, type = "buff", unit = "player", talent = 5 }, -- Displacer Beast
        { spell = 155835, type = "buff", unit = "player", talent = 2 }, -- Bristling Fur
        { spell = 158792, type = "buff", unit = "player", talent = 21 }, -- Pulverize
        { spell = 164545, type = "buff", unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 164547, type = "buff", unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 192081, type = "buff", unit = "player" }, -- Ironfur
        { spell = 192083, type = "buff", unit = "player" }, -- Mark of Ursol
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 200851, type = "buff", unit = "player" }, -- Rage of the Sleeper
        { spell = 201671, type = "buff", unit = "player" }, -- Gory Fur
        { spell = 203975, type = "buff", unit = "player", talent = 16 }, -- Earthwarden
        { spell = 200850, type = "buff", unit = "player" }, -- Adaptive Fur
        { spell = 213680, type = "buff", unit = "player", talent = 17 }, -- Guardian of Elune
        { spell = 213708, type = "buff", unit = "player", talent = 15 }, -- Galactic Guardian
        { spell = 214998, type = "buff", unit = "player" }, -- Roar of the Crowd
      },
      icon = 1378702
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target" }, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 8 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 45334, type = "debuff", unit = "target" }, -- Immobilized
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 155722, type = "debuff", unit = "target", fullscan = "true", titleSuffix = L["Bleed"] }, -- Rake
        { spell = 163505, type = "debuff", unit = "target", fullscan = "true", titleSuffix = L["Stun"] }, -- Rake
        { spell = 164812, type = "debuff", unit = "target", talent = 15 }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 7 }, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target" }, -- Thrash
        { spell = 214995, type = "debuff", unit = "target" }, -- Bloody Paws
      },
      icon = 451161
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability"}, -- Incapacitating Roar
        { spell = 1850, type = "ability"}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 5211, type = "ability", talent = 10}, -- Mighty Bash
        { spell = 5215, type = "ability"}, -- Prowl
        { spell = 6795, type = "ability"}, -- Growl
        { spell = 6807, type = "ability"}, -- Maul
        { spell = 16979, type = "ability", talent = 6}, -- Wild Charge
        { spell = 18562, type = "ability", talent = 9}, -- Swiftmend
        { spell = 22812, type = "ability"}, -- Barkskin
        { spell = 33917, type = "ability"}, -- Mangle
        { spell = 61336, type = "ability"}, -- Survival Instincts
        { spell = 77758, type = "ability"}, -- Thrash
        { spell = 102280, type = "ability", talent = 5}, -- Displacer Beast
        { spell = 102359, type = "ability", talent = 11}, -- Mass Entanglement
        { spell = 102401, type = "ability", talent = 6}, -- Wild Charge
        { spell = 102558, type = "ability", talent = 14}, -- Incarnation: Guardian of Ursoc
        { spell = 106839, type = "ability"}, -- Skull Bash
        { spell = 106898, type = "ability"}, -- Stampeding Roar
        { spell = 132469, type = "ability", talent = 12}, -- Typhoon
        { spell = 155835, type = "ability", talent = 2}, -- Bristling Fur
        { spell = 197626, type = "ability", talent = 7}, -- Starsurge
        { spell = 200851, type = "ability"}, -- Rage of the Sleeper
        { spell = 204066, type = "ability", talent = 20}, -- Lunar Beam
      },
      icon = 236169
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 201664, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"]}, -- Demoralizing Roar
        { spell = 201664, type = "debuff", unit = "target", pvptalent = 12, titleSuffix = L["debuff"]}, -- Demoralizing Roar
        { spell = 339, type = "ability", pvptalent = 17}, -- Entangling Claws
        { spell = 202246, type = "debuff", unit = "target", pvptalent = 18, titleSuffix = L["debuff"]}, -- Overrun
        { spell = 202246, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Overrun
        { spell = 202043, type = "buff", unit = "player", pvptalent = 11}, -- Protector of the Pack
        { spell = 195336, type = "buff", unit = "player", pvptalent = 4}, -- Relentless Assault
        { spell = 206891, type = "debuff", unit = "target", pvptalent = 5}, -- Intimated
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = "Interface\\Icons\\spell_misc_emotionangry",
    },
  },
  [4] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 774, type = "buff", unit = "group" }, -- Rejuvenation
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 16870, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 9 }, -- Frenzied Regeneration
        { spell = 29166, type = "buff", unit = "group" }, -- Innervate
        { spell = 33763, type = "buff", unit = "group" }, -- Lifebloom
        { spell = 33891, type = "buff", unit = "player", talent = 14 }, -- Incarnation: Tree of Life
        { spell = 48438, type = "buff", unit = "player" }, -- Wild Growth
        { spell = 48504, type = "buff", unit = "player" }, -- Living Seed
        { spell = 102342, type = "buff", unit = "group" }, -- Ironbark
        { spell = 102351, type = "buff", unit = "group", talent = 2 }, -- Cenarion Ward
        { spell = 114108, type = "buff", unit = "player" }, -- Soul of the Forest
        { spell = 117679, type = "buff", unit = "player", talent = 16 }, -- Incarnation
        { spell = 137452, type = "buff", unit = "player", talent = 5 }, -- Displacer Beast
        { spell = 155777, type = "buff", unit = "group", talent = 18 }, -- Rejuvenation (Germination)
        { spell = 164545, type = "buff", unit = "player", talent = 7 }, -- Solar Empowerment
        { spell = 164547, type = "buff", unit = "player", talent = 7 }, -- Lunar Empowerment
        { spell = 186370, type = "buff", unit = "player" }, -- Mark of Shifting
        { spell = 189877, type = "buff", unit = "player" }, -- Power of the Archdruid
        { spell = 192081, type = "buff", unit = "player", talent = 9 }, -- Ironfur
        { spell = 197625, type = "buff", unit = "player", talent = 7 }, -- Moonkin Form
        { spell = 200389, type = "buff", unit = "group", talent = 15 }, -- Cultivation
        { spell = 207386, type = "buff", unit = "group", talent = 16 }, -- Spring Blossoms
        { spell = 207640, type = "buff", unit = "player", talent = 3 }, -- Abundance
        { spell = 208253, type = "buff", unit = "group" }, -- Essence of G'Hanir
      },
      icon = 136081
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 8 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 10 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 61391, type = "debuff", unit = "target", talent = 12 }, -- Typhoon
        { spell = 102359, type = "debuff", unit = "target", talent = 11 }, -- Mass Entanglement
        { spell = 127797, type = "debuff", unit = "target" }, -- Ursol's Vortex
        { spell = 155722, type = "debuff", unit = "target", fullscan = "true", titleSuffix = L["Bleed"] }, -- Rake
        { spell = 163505, type = "debuff", unit = "target", fullscan = "true", titleSuffix = L["Stun"] }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target" }, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target" }, -- Thrash
      },
      icon = 236216
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 740, type = "ability"}, -- Tranquility
        { spell = 1850, type = "ability"}, -- Dash
        { spell = 2782, type = "ability"}, -- Remove Corruption
        { spell = 5211, type = "ability", talent = 10}, -- Mighty Bash
        { spell = 5215, type = "ability"}, -- Prowl
        { spell = 6795, type = "ability"}, -- Growl
        { spell = 16979, type = "ability"}, -- Wild Charge
        { spell = 18562, type = "ability"}, -- Swiftmend
        { spell = 20484, type = "ability"}, -- Rebirth
        { spell = 22812, type = "ability"}, -- Barkskin
        { spell = 29166, type = "ability"}, -- Innervate
        { spell = 33891, type = "ability", talent = 14}, -- Incarnation: Tree of Life
        { spell = 33917, type = "ability", talent = 9}, -- Mangle
        { spell = 48438, type = "ability"}, -- Wild Growth
        { spell = 77758, type = "ability"}, -- Thrash
        { spell = 88423, type = "ability"}, -- Nature's Cure
        { spell = 102280, type = "ability", talent = 5}, -- Displacer Beast
        { spell = 102342, type = "ability"}, -- Ironbark
        { spell = 102351, type = "ability"}, -- Cenarion Ward
        { spell = 102359, type = "ability", talent = 11}, -- Mass Entanglement
        { spell = 102383, type = "ability", talent = 6}, -- Wild Charge
        { spell = 102793, type = "ability"}, -- Ursol's Vortex
        { spell = 108238, type = "ability", talent = 4}, -- Renewal
        { spell = 132469, type = "ability", talent = 12}, -- Typhoon
        { spell = 197626, type = "ability", talent = 7}, -- Starsurge
        { spell = 197721, type = "ability", talent = 21}, -- Flourish
        { spell = 208253, type = "ability"}, -- Essence of G'Hanir
      },
      icon = 236153
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 33786, type = "ability", pvptalent = 10, titleSuffix = L["cooldown"]}, -- Cyclone
        { spell = 33786, type = "debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"]}, -- Cyclone
        { spell = 200947, type = "debuff", unit = "target", pvptalent = 11}, -- Encroaching Vines
        { spell = 203554, type = "buff", unit = "target", pvptalent = 16}, -- Focused Growth
        { spell = 203651, type = "ability", pvptalent = 21}, -- Overgrowth
        { spell = 203727, type = "ability", pvptalent = 8, titleSuffix = L["cooldown"]}, -- Thorns
        { spell = 203727, type = "debuff", unit = "target", pvptalent = 8, titleSuffix = L["buff"]}, -- Thorns
        { spell = 195329, type = "buff", unit = "player", pvptalent = 4}, -- Defender of the Weak
        { spell = 195488, type = "buff", unit = "player", pvptalent = 5}, -- Vim and Vigor
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = "Interface\\Icons\\inv_elemental_mote_mana",
    },
  },
}

templates.class.DEMONHUNTER = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 131347, type = "buff", unit = "player" }, -- Glide
        { spell = 162264, type = "buff", unit = "player" }, -- Metamorphosis
        { spell = 188499, type = "buff", unit = "player" }, -- Blade Dance
        { spell = 188501, type = "buff", unit = "player" }, -- Spectral Sight
        { spell = 196555, type = "buff", unit = "player" }, -- Netherwalk
        { spell = 203650, type = "buff", unit = "player" }, -- Prepared
        { spell = 208614, type = "buff", unit = "player", talent = 15 }, -- Nemesis
        { spell = 208628, type = "buff", unit = "player", talent = 13 }, -- Momentum
        { spell = 209426, type = "buff", unit = "player" }, -- Darkness
        { spell = 210152, type = "buff", unit = "player" }, -- Death Sweep
        { spell = 211048, type = "buff", unit = "player" }, -- Chaos Blades
        { spell = 211053, type = "buff", unit = "player" }, -- Fel Barrage
        { spell = 212800, type = "buff", unit = "player" }, -- Blur
      },
      icon = 1247266
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 179057, type = "debuff", unit = "target" }, -- Chaos Nova
        { spell = 198813, type = "debuff", unit = "target" }, -- Vengeful Retreat
        { spell = 200166, type = "debuff", unit = "target" }, -- Metamorphosis
        { spell = 202443, type = "debuff", unit = "target" }, -- Anguish
        { spell = 206491, type = "debuff", unit = "target", talent = 15 }, -- Nemesis
        { spell = 207690, type = "debuff", unit = "target" }, -- Bloodlet
        { spell = 211053, type = "debuff", unit = "target" }, -- Fel Barrage
        { spell = 217832, type = "debuff", unit = "multi" }, -- Imprison
        { spell = 211881, type = "debuff", unit = "target" }, -- Fel Eruption
      },
      icon = 1392554
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 179057, type = "ability"}, -- Chaos Nova
        { spell = 183752, type = "ability"}, -- Consume Magic
        { spell = 185123, type = "ability"}, -- Throw Glaive
        { spell = 188499, type = "ability"}, -- Blade Dance
        { spell = 188501, type = "ability"}, -- Spectral Sight
        { spell = 191427, type = "ability"}, -- Metamorphosis
        { spell = 195072, type = "ability"}, -- Fel Rush
        { spell = 196555, type = "ability", talent = 8}, -- Netherwalk
        { spell = 196718, type = "ability"}, -- Darkness
        { spell = 198013, type = "ability"}, -- Eye Beam
        { spell = 198589, type = "ability"}, -- Blur
        { spell = 198793, type = "ability"}, -- Vengeful Retreat
        { spell = 201467, type = "ability"}, -- Fury of the Illidari
        { spell = 206491, type = "ability", talent = 15}, -- Nemesis
        { spell = 210152, type = "ability"}, -- Death Sweep
        { spell = 211048, type = "ability", talent = 19}, -- Chaos Blades
        { spell = 211053, type = "ability", talent = 20}, -- Fel Barrage
        { spell = 211881, type = "ability", talent = 14}, -- Fel Eruption
        { spell = 213241, type = "ability", talent = 7}, -- Felblade
        { spell = 217832, type = "ability"}, -- Imprison
      },
      icon = 1305156
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 203704, type = "ability", pvptalent = 18}, -- Mana Break
        { spell = 207488, type = "debuff", unit = "target", pvptalent = 15}, -- Pinning Glare
        { spell = 206803, type = "ability", pvptalent = 17}, -- Rain from Above
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = 1344651,
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 131347, type = "buff", unit = "player" }, -- Glide
        { spell = 178740, type = "buff", unit = "player" }, -- Immolation Aura
        { spell = 187827, type = "buff", unit = "player" }, -- Metamorphosis
        { spell = 188501, type = "buff", unit = "player" }, -- Spectral Sight
        { spell = 203819, type = "buff", unit = "player" }, -- Demon Spikes
        { spell = 203981, type = "buff", unit = "player" }, -- Soul Fragments
        { spell = 207709, type = "buff", unit = "player", talent = 17 }, -- Blade Turning
        { spell = 207810, type = "buff", unit = "group", talent = 20 }, -- Nether Bond
        { spell = 209426, type = "buff", unit = "player" }, -- Darkness
        { spell = 212988, type = "buff", unit = "player" }, -- Painbringer
        { spell = 218256, type = "buff", unit = "player" }, -- Empower Wards
        { spell = 227225, type = "buff", unit = "player" }, -- Soul Barrier
        { spell = 227330, type = "buff", unit = "player", talent = 9 }, -- Gluttony
      },
      icon = 1247263
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 185245, type = "debuff", unit = "target" }, -- Torment
        { spell = 204490, type = "debuff", unit = "target" }, -- Sigil of Silence
        { spell = 204598, type = "debuff", unit = "target" }, -- Sigil of Flame
        { spell = 204843, type = "debuff", unit = "target" }, -- Sigil of Chains
        { spell = 207407, type = "debuff", unit = "target" }, -- Soul Carver
        { spell = 207685, type = "debuff", unit = "target" }, -- Sigil of Misery
        { spell = 207744, type = "debuff", unit = "target" }, -- Fiery Brand
        { spell = 209261, type = "debuff", unit = "player", talent = 19 }, -- Uncontained Fel
        { spell = 210003, type = "debuff", unit = "target", talent = 3 }, -- Razor Spikes
        { spell = 211881, type = "debuff", unit = "target", talent = 14 }, -- Fel Eruption
        { spell = 217832, type = "debuff", unit = "multi" }, -- Imprison
        { spell = 212818, type = "debuff", unit = "target" }, -- Fiery Demise
        { spell = 224509, type = "debuff", unit = "target" }, -- Frailty
      },
      icon = 1344647
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 178740, type = "ability"}, -- Immolation Aura
        { spell = 183752, type = "ability"}, -- Consume Magic
        { spell = 185245, type = "ability"}, -- Torment
        { spell = 187827, type = "ability"}, -- Metamorphosis
        { spell = 188501, type = "ability"}, -- Spectral Sight
        { spell = 196718, type = "ability"}, -- Darkness
        { spell = 202137, type = "ability"}, -- Sigil of Silence
        { spell = 202138, type = "ability"}, -- Sigil of Chains
        { spell = 203720, type = "ability"}, -- Demon Spikes
        { spell = 204021, type = "ability"}, -- Fiery Brand
        { spell = 204157, type = "ability"}, -- Throw Glaive
        { spell = 204596, type = "ability"}, -- Sigil of Flame
        { spell = 207407, type = "ability"}, -- Soul Carver
        { spell = 207684, type = "ability"}, -- Sigil of Misery
        { spell = 207810, type = "ability", talent = 20}, -- Nether Bond
        { spell = 211881, type = "ability", talent = 14}, -- Fel Eruption
        { spell = 212084, type = "ability", talent = 16}, -- Fel Devastation
        { spell = 213241, type = "ability", talent = 7}, -- Felblade
        { spell = 217832, type = "ability"}, -- Imprison
        { spell = 218256, type = "ability"}, -- Empower Wards
        { spell = 227225, type = "ability", talent = 21}, -- Soul Barrier
      },
      icon = 1344650
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 205629, type = "ability", pvptalent = 17}, -- Demonic Trample
        { spell = 208769, type = "buff", unit = "player", pvptalent = 13}, -- Everlasting Hunt
        { spell = 205630, type = "ability", pvptalent = 18, titleSuffix = L["cooldown"]}, -- Illidan's Grasp
        { spell = 205630, type = "debuff", unit = "target", pvptalent = 18, titleSuffix = L["buff"]}, -- Illidan's Grasp
        { spell = 195336, type = "buff", unit = "player", pvptalent = 4}, -- Relentless Assault
        { spell = 206891, type = "debuff", unit = "target", pvptalent = 5}, -- Intimated
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = 1247265,
    },
  },
}

templates.class.DEATHKNIGHT = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 3714, type = "buff", unit = "player" }, -- Path of Frost
        { spell = 48707, type = "buff", unit = "player" }, -- Anti-Magic Shell
        { spell = 53365, type = "buff", unit = "player" }, -- Unholy Strength
        { spell = 55233, type = "buff", unit = "player" }, -- Vampiric Blood
        { spell = 77535, type = "buff", unit = "player" }, -- Blood Shield
        { spell = 81141, type = "buff", unit = "player" }, -- Crimson Scourge
        { spell = 81256, type = "buff", unit = "player" }, -- Dancing Rune Weapon
        { spell = 188290, type = "buff", unit = "player" }, -- Death and Decay
        { spell = 193320, type = "buff", unit = "player", fullscan = true }, -- Umbilicus Eternus
        { spell = 194679, type = "buff", unit = "player" }, -- Rune Tap
        { spell = 194844, type = "buff", unit = "player" }, -- Bonestorm
        { spell = 195181, type = "buff", unit = "player" }, -- Bone Shield
        { spell = 205725, type = "buff", unit = "player" }, -- Anti-Magic Barrier
        { spell = 206977, type = "buff", unit = "player" }, -- Blood Mirror
        { spell = 212552, type = "buff", unit = "player" }, -- Wraith Walk
        { spell = 219788, type = "buff", unit = "player" }, -- Ossuary
        { spell = 219809, type = "buff", unit = "player" }, -- Tombstone
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 51399, type = "debuff", unit = "target" }, -- Death Grip
        { spell = 51714, type = "debuff", unit = "target" }, -- Razorice
        { spell = 55078, type = "debuff", unit = "target" }, -- Blood Plague
        { spell = 56222, type = "debuff", unit = "target" }, -- Dark Command
        { spell = 111673, type = "debuff", unit = "multi"}, -- Control Undead
        { spell = 114556, type = "debuff", unit = "player" }, -- Purgatory
        { spell = 193261, type = "debuff", unit = "target" }, -- Bleeding Profusely
        { spell = 206930, type = "debuff", unit = "target" }, -- Heart Strike
        { spell = 206931, type = "debuff", unit = "target" }, -- Blooddrinker
        { spell = 206940, type = "debuff", unit = "target" }, -- Mark of Blood
        { spell = 206961, type = "debuff", unit = "target" }, -- Tremble Before Me
        { spell = 206977, type = "debuff", unit = "target" }, -- Blood Mirror
        { spell = 221562, type = "debuff", unit = "target" }, -- Asphyxiate
      },
      icon = 237514
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability"}, -- Path of Frost
        { spell = 43265, type = "ability"}, -- Death and Decay
        { spell = 47528, type = "ability"}, -- Mind Freeze
        { spell = 48707, type = "ability"}, -- Anti-Magic Shell
        { spell = 49028, type = "ability"}, -- Dancing Rune Weapon
        { spell = 49576, type = "ability"}, -- Death Grip
        { spell = 50842, type = "ability"}, -- Blood Boil
        { spell = 55233, type = "ability"}, -- Vampiric Blood
        { spell = 56222, type = "ability"}, -- Dark Command
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 108199, type = "ability"}, -- Gorefiend's Grasp
        { spell = 111673, type = "ability"}, -- Control Undead
        { spell = 194679, type = "ability"}, -- Rune Tap
        { spell = 194844, type = "ability"}, -- Bonestorm
        { spell = 195182, type = "ability"}, -- Marrowrend
        { spell = 195292, type = "ability"}, -- Death's Caress
        { spell = 205223, type = "ability"}, -- Consumption
        { spell = 206930, type = "ability"}, -- Heart Strike
        { spell = 206931, type = "ability"}, -- Blooddrinker
        { spell = 206977, type = "ability"}, -- Blood Mirror
        { spell = 212552, type = "ability"}, -- Wraith Walk
        { spell = 219809, type = "ability"}, -- Tombstone
        { spell = 221562, type = "ability"}, -- Asphyxiate
        { spell = 221699, type = "ability"}, -- Blood Tap
      },
      icon = 136120
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 203173, type = "buff", unit = "player", pvptalent = 18}, -- Death Chain
        { spell = 47476, type = "ability", pvptalent = 15, titleSuffix = L["cooldown"]}, -- Strangulate
        { spell = 47476, type = "debuff", unit = "target", pvptalent = 15, titleSuffix = L["buff"]}, -- Strangulate
        { spell = 212610, type = "debuff", unit = "target", pvptalent = 14}, -- Walking Dead
        { spell = 206891, type = "debuff", unit = "target", pvptalent = 5}, -- Murderous Intent
        { spell = 195336, type = "buff", unit = "player", pvptalent = 4}, -- Relentless Assault
        { spell = 206891, type = "debuff", unit = "target", pvptalent = 5}, -- Intimated
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune",
    },
  },
  [2] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 3714, type = "buff", unit = "player" }, -- Path of Frost
        { spell = 48707, type = "buff", unit = "player" }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player" }, -- Icebound Fortitude
        { spell = 51124, type = "buff", unit = "player" }, -- Killing Machine
        { spell = 51271, type = "buff", unit = "player" }, -- Pillar of Frost
        { spell = 53365, type = "buff", unit = "player" }, -- Unholy Strength
        { spell = 59052, type = "buff", unit = "player" }, -- Rime
        { spell = 152279, type = "buff", unit = "player" }, -- Breath of Sindragosa
        { spell = 194879, type = "buff", unit = "player" }, -- Icy Talons
        { spell = 178819, type = "buff", unit = "player" }, -- Dark Succor
        { spell = 196770, type = "buff", unit = "player" }, -- Remorseless Winter
        { spell = 204957, type = "buff", unit = "player" }, -- Frozen Soul
        { spell = 207127, type = "buff", unit = "player" }, -- Hungering Rune Weapon
        { spell = 207203, type = "buff", unit = "player" }, -- Frost Shield
        { spell = 207256, type = "buff", unit = "player" }, -- Obliteration
        { spell = 211805, type = "buff", unit = "player" }, -- Gathering Storm
        { spell = 212552, type = "buff", unit = "player" }, -- Wraith Walk
      },
      icon = 135305
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target" }, -- Chains of Ice
        { spell = 51399, type = "debuff", unit = "target" }, -- Death Grip
        { spell = 51714, type = "debuff", unit = "target" }, -- Razorice
        { spell = 55095, type = "debuff", unit = "target" }, -- Frost Fever
        { spell = 56222, type = "debuff", unit = "target" }, -- Dark Command
        { spell = 111673, type = "debuff", unit = "multi"}, -- Control Undead
        { spell = 190780, type = "debuff", unit = "target" }, -- Frost Breath
        { spell = 207165, type = "debuff", unit = "target" }, -- Abomination's Might
        { spell = 207167, type = "debuff", unit = "target" }, -- Blinding Sleet
        { spell = 207171, type = "debuff", unit = "target" }, -- Winter is Coming
        { spell = 211793, type = "debuff", unit = "target" }, -- Remorseless Winter
        { spell = 211794, type = "debuff", unit = "target" }, -- Winter is Coming
        { spell = 212764, type = "debuff", unit = "target" }, -- White Walker
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
        { spell = 48707, type = "ability"}, -- Anti-Magic Shell
        { spell = 48792, type = "ability"}, -- Icebound Fortitude
        { spell = 49020, type = "ability"}, -- Obliterate
        { spell = 49184, type = "ability"}, -- Howling Blast
        { spell = 49576, type = "ability"}, -- Death Grip
        { spell = 51271, type = "ability"}, -- Pillar of Frost
        { spell = 56222, type = "ability"}, -- Dark Command
        { spell = 57330, type = "ability"}, -- Horn of Winter
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 111673, type = "ability"}, -- Control Undead
        { spell = 152279, type = "ability"}, -- Breath of Sindragosa
        { spell = 190778, type = "ability"}, -- Sindragosa's Fury
        { spell = 194913, type = "ability"}, -- Glacial Advance
        { spell = 196770, type = "ability"}, -- Remorseless Winter
        { spell = 207127, type = "ability"}, -- Hungering Rune Weapon
        { spell = 207167, type = "ability"}, -- Blinding Sleet
        { spell = 207230, type = "ability"}, -- Frostscythe
        { spell = 207256, type = "ability"}, -- Obliteration
        { spell = 212552, type = "ability"}, -- Wraith Walk
      },
      icon = 135372
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 204160, type = "ability", pvptalent = 18}, -- Chill Streak
        { spell = 204143, type = "ability", pvptalent = 17, titleSuffix = L["cooldown"]}, -- Killing Machine
        { spell = 204143, type = "buff", unit = "player", pvptalent = 17, titleSuffix = L["buff"]}, -- Killing Machine
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune",
    },
  },
  [3] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 3714, type = "buff", unit = "player" }, -- Path of Frost
        { spell = 42650, type = "buff", unit = "player" }, -- Army of the Dead
        { spell = 48707, type = "buff", unit = "player" }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player" }, -- Icebound Fortitude
        { spell = 51460, type = "buff", unit = "player" }, -- Runic Corruption
        { spell = 53365, type = "buff", unit = "player" }, -- Unholy Strength
        { spell = 81340, type = "buff", unit = "player" }, -- Sudden Doom
        { spell = 178819, type = "buff", unit = "player" }, -- Dark Succor
        { spell = 188290, type = "buff", unit = "player" }, -- Death and Decay
        { spell = 194918, type = "buff", unit = "player" }, -- Blighted Rune Weapon
        { spell = 207290, type = "buff", unit = "player" }, -- Unholy Frenzy
        { spell = 207319, type = "buff", unit = "player" }, -- Corpse Shield
        { spell = 212552, type = "buff", unit = "player" }, -- Wraith Walk
        { spell = 215711, type = "buff", unit = "player" }, -- Soul Reaper
        { spell = 216974, type = "buff", unit = "player" }, -- Necrosis
        { spell = 218100, type = "buff", unit = "player" }, -- Defile
      },
      icon = 136181
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target" }, -- Chains of Ice
        { spell = 51399, type = "debuff", unit = "target" }, -- Death Grip
        { spell = 51714, type = "debuff", unit = "target" }, -- Razorice
        { spell = 56222, type = "debuff", unit = "target" }, -- Dark Command
        { spell = 91800, type = "debuff", unit = "target" }, -- Gnaw
        { spell = 111673, type = "debuff", unit = "multi"}, -- Control Undead
        { spell = 130736, type = "debuff", unit = "target" }, -- Soul Reaper
        { spell = 156004, type = "debuff", unit = "target" }, -- Defile
        { spell = 191587, type = "debuff", unit = "target" }, -- Virulent Plague
        { spell = 191748, type = "debuff", unit = "target" }, -- Scourge of Worlds
        { spell = 194310, type = "debuff", unit = "target" }, -- Festering Wound
        { spell = 196782, type = "debuff", unit = "target" }, -- Outbreak
        { spell = 208278, type = "debuff", unit = "target" }, -- Debilitating Infestation
        { spell = 212332, type = "debuff", unit = "target" }, -- Smash
        { spell = 221562, type = "debuff", unit = "target" }, -- Asphyxiate
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
        { spell = 47528, type = "ability"}, -- Mind Freeze
        { spell = 48707, type = "ability"}, -- Anti-Magic Shell
        { spell = 48792, type = "ability"}, -- Icebound Fortitude
        { spell = 49206, type = "ability"}, -- Summon Gargoyle
        { spell = 49576, type = "ability"}, -- Death Grip
        { spell = 55090, type = "ability"}, -- Scourge Strike
        { spell = 56222, type = "ability"}, -- Dark Command
        { spell = 61999, type = "ability"}, -- Raise Ally
        { spell = 63560, type = "ability"}, -- Dark Transformation
        { spell = 77575, type = "ability"}, -- Outbreak
        { spell = 85948, type = "ability"}, -- Festering Strike
        { spell = 111673, type = "ability"}, -- Control Undead
        { spell = 130736, type = "ability"}, -- Soul Reaper
        { spell = 152280, type = "ability"}, -- Defile
        { spell = 194918, type = "ability"}, -- Blighted Rune Weapon
        { spell = 207311, type = "ability"}, -- Clawing Shadows
        { spell = 207317, type = "ability"}, -- Epidemic
        { spell = 207319, type = "ability"}, -- Corpse Shield
        { spell = 207349, type = "ability"}, -- Dark Arbiter
        { spell = 212552, type = "ability"}, -- Wraith Walk
        { spell = 220143, type = "ability"}, -- Apocalypse
        { spell = 221562, type = "ability"}, -- Asphyxiate
        { spell = 47482, type = "ability", titleSuffix = L["(Pet)"]}, -- Leap
        { spell = 47484, type = "ability", titleSuffix = L["(Pet)"]}, -- Huddle
      },
      icon = 136144
    },
    [4] = {
      title = L["PvP Talents"],
      args = {
        { spell = 204160, type = "ability", pvptalent = 18}, -- Necrotic Strike
        { spell = 223929, type = "debuff", unit = "target", pvptalent = 18}, -- Necrotic Strike
        { spell = 210128, type = "ability", pvptalent = 17}, -- Reanimation
        { spell = 199725, type = "ability", pvptalent = 15, titleSuffix = L["cooldown"]}, -- Wandering Plague
      },
      icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    [5] = {
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
  overideTitle = L["BloodLust/Heroism"],
  spellIds = {2825, 32182, 80353, 90355, 160452} }
);

-- Items section
templates.items[1] = {
  title = L["Enchants"],
  args = {
    { spell = 190909, type = "buff", unit = "player"},
    { spell = 228399, type = "buff", unit = "player"},
  }
}

templates.items[2] = {
  title = L["Legendaries"],
  args = {
    { spell = 205675, type = "debuff", unit = "target", item = 132460},
    { spell = 207283, type = "buff", unit = "player", item = 133977},
    { spell = 207472, type = "buff", unit = "player", item = 132444},
    { spell = 207589, type = "buff", unit = "player", item = 137046},
    { spell = 207635, type = "buff", unit = "player", item = 137020},
    { spell = 207724, type = "buff", unit = "player", item = 133973},
    { spell = 207776, type = "buff", unit = "player", item = 137053},
    { spell = 207844, type = "buff", unit = "player", item = 137108},
    { spell = 208052, type = "buff", unit = "player", item = 132452},
    { spell = 208081, type = "buff", unit = "player", item = 132413},
    { spell = 208215, type = "buff", unit = "player", item = 132455},
    { spell = 208218, type = "buff", unit = "player", item = 137025},
    { spell = 208284, type = "buff", unit = "player", item = 137023},
    { spell = 208403, type = "buff", unit = "player", item = 137069},
    { spell = 208723, type = "buff", unit = "player", item = 137074},
    { spell = 208742, type = "buff", unit = "player", item = 137616},
    { spell = 208764, type = "buff", unit = "player", item = 137104},
    { spell = 208913, type = "buff", unit = "player", item = 137081},
    { spell = 208822, type = "buff", unit = "player", item = 132381},
    { spell = 208871, type = "buff", unit = "player", item = 132379},
    { spell = 209423, type = "buff", unit = "player", item = 137099},
    { spell = 210607, type = "buff", unit = "player", item = 137051},
    { spell = 211319, type = "debuff", unit = "player", item = 137109},
    { spell = 211442, type = "buff", unit = "player", fullscan = true, titleSuffix = L["- Holy Word: Sanctify"], item = 132445},
    { spell = 214404, type = "buff", unit = "player", item = 138140},
    { spell = 215210, type = "buff", unit = "player", item = 132409},
    { spell = 211440, type = "buff", unit = "player", fullscan = true, titleSuffix = L["- Holy Word: Serenity"], item = 132445},
    { spell = 211440, type = "buff", unit = "player", titleSuffix = L["- Any"], item = 132445},
    { spell = 211443, type = "buff", unit = "player", fullscan = true, titleSuffix = L["- Holy Word: Chastise"], item = 132445},
    { spell = 214265, type = "debuff", unit = "target", item = 137103},
    { spell = 214637, type = "buff", unit = "player", item = 132861},
    { spell = 215157, type = "buff", unit = "player", item = 137018},
    { spell = 217474, type = "buff", unit = "player", item = 137045},
    { spell = 224852, type = "debuff", unit = "target", item = 137083},
    { spell = 225947, type = "buff", unit = "player", item = 137052},
    { spell = 226318, type = "buff", unit = "player", item = 141321},
    { spell = 226852, type = "buff", unit = "player", item = 133970},
    { spell = 228224, type = "buff", unit = "player", item = 137021},
  }
}

templates.items[3] = {
  title = L["T19 Sets"],
  args = {
    { spell = 206333, type = "buff", unit = "player", titleSuffix = L["- Warrior T19 Fury 2P Bonus"]},
    { spell = 209785, type = "buff", unit = "player", titleSuffix = L["- Paladin T19 Retribution 4P Bonus"]},
    { spell = 211160, type = "buff", unit = "player", titleSuffix = L["- T19 Druid Guardian 4P Bonus"]},
    { spell = 211669, type = "buff", unit = "player", titleSuffix = L["- Rogue T19 Outlaw 4P Bonus"]},
    { spell = 212019, type = "buff", unit = "player", titleSuffix = L["- Warlock T19 Destruction 4P Bonus"]},
  }
}

templates.items[4] = {
  title = L["T19 Tank Trinkets"],
  args = {
    { spell = 140789, type = "item"},
    { spell = 140797, type = "item"},
    { spell = 140807, type = "item"},
    { spell = 139327, type = "item"},
    { spell = 221695, type = "buff", unit = "player", titleItemPrefix = 139327},
    { spell = 222209, type = "debuff", unit = "target", titleItemPrefix = 139335},
    { spell = 222479, type = "buff", unit = "player", titleItemPrefix = 138225},
    { spell = 225033, type = "buff", unit = "player", titleItemPrefix = 140789},
    { spell = 225130, type = "buff", unit = "player", titleItemPrefix = 140797},
    { spell = 225720, type = "buff", unit = "player", titleItemPrefix = 140791},
    { spell = 225140, type = "buff", unit = "player", titleItemPrefix = 140807},

  }
}

templates.items[5] = {
  title = L["T19 Damage Trinkets"],
  args = {
    { spell = 139320, type = "item"},
    { spell = 139326, type = "item"},
    { spell = 140799, type = "item"},
    { spell = 140800, type = "item"},
    { spell = 140808, type = "item"},
    { spell = 141584, type = "item"},
    { spell = 222705, type = "debuff", unit = "target", titleItemPrefix = 139336},
    { spell = 222046, type = "buff", unit = "player", titleItemPrefix = 139326},
    { spell = 221767, type = "debuff", unit = "target", titleItemPrefix = 139328},
    { spell = 227869, type = "debuff", unit = "target", titleItemPrefix = 141585},
    { spell = 221786, type = "buff", unit = "player", titleItemPrefix = 139329},
    { spell = 221812, type = "debuff", unit = "target", titleItemPrefix = 139321},
    { spell = 222166, type = "buff", unit = "player", titleItemPrefix = 139325},
    { spell = 225141, type = "buff", unit = "player", titleItemPrefix = 140808},
    { spell = 225719, type = "buff", unit = "player", titleItemPrefix = 140792},
    { spell = 225731, type = "buff", unit = "target", titleItemPrefix = 140798},
    { spell = 225736, type = "buff", unit = "player", titleItemPrefix = 140802},
    { spell = 225774, type = "buff", unit = "player", titleItemPrefix = 140809},
  }
}

templates.items[6] = {
  title = L["T19 Healer Trinkets"],
  args = {
    { spell = 139322, type = "item"},
    { spell = 140793, type = "item"},
    { spell = 139333, type = "item"},
    { spell = 221748, type = "buff", unit = "player", titleItemPrefix = 139330},
    { spell = 225723, type = "buff", unit = "player", titleItemPrefix = 140793},
    { spell = 225724, type = "buff", unit = "player", titleItemPrefix = 140795},
    { spell = 225766, type = "buff", unit = "player", titleItemPrefix = 140805},
    { spell = 221873, type = "buff", unit = "target", titleItemPrefix = 138222},
    { spell = 221837, type = "buff", unit = "target", titleItemPrefix = 139322},
  }
}

templates.items[7] = {
  title = L["PVP Set"],
  args = {
    { spell = 165638, type = "buff", unit = "player", titleSuffix = L["- Warrior 2P Bonus"]},
    { spell = 166062, type = "buff", unit = "player", titleSuffix = L["- Deathknight Unholy 4P Bonus"]},
    { spell = 166021, type = "buff", unit = "player", titleSuffix = L["- Deathknight 2P Bonus"]},
    { spell = 171380, type = "buff", unit = "player", titleSuffix = L["- Warlock Affliction 4P/Demonology 2P Bonus"]},
    { spell = 181744, type = "buff", unit = "player", titleSuffix = L["- Monk Windwalker 4P Bonus"]},
    { spell = 170882, type = "buff", unit = "player", titleSuffix = L["- Rogue Assassination/Outlaw 4P Bonus"]},
    { spell = 170879, type = "buff", unit = "player", titleSuffix = L["- Rogue Subtlety 4P Bonus"]},
    { spell = 165909, type = "debuff", unit = "target", titleSuffix = L["- Paladin Protection 2P Bonus"]},
    { spell = 165889, type = "debuff", unit = "target", titleSuffix = L["- Paladin Retribution 2P Bonus"]},
    { spell = 171114, type = "buff", unit = "player", titleSuffix = L["- Shaman Enhancement 2P Bonus"]},
    { spell = 166100, type = "buff", unit = "player", titleSuffix = L["- Shaman Elemental 4P Bonus"]},
  }
}

templates.items[8] = {
  title = L["PVP Trinkets"],
  args = {
    { spell = 136146, type = "item"}, -- Vindictive Gladiator's Emblem of Cruelty
    { spell = 136147, type = "item"}, -- Vindictive Gladiator's Emblem of Tenacity
    { spell = 136148, type = "item"}, -- Vindictive Gladiator's Emblem of Meditation
    { spell = 136149, type = "item"}, -- Vindictive Gladiator's Badge of Dominance
    { spell = 136152, type = "item"}, -- Vindictive Gladiator's Badge of Victory
    { spell = 136155, type = "item"}, -- Vindictive Gladiator's Badge of Adaptation
    { spell = 136256, type = "item"}, -- Vindictive Gladiator's Badge of Conquest
    { spell = 190028, type = "buff", unit = "player"},
    { spell = 190029, type = "buff", unit = "player"},
    { spell = 190030, type = "buff", unit = "player"},
    { spell = 170397, type = "buff", unit = "player"},
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
    tinsert(spec[4].args, { spell = 195710, type = "ability"}) -- Honorable Medallion
    tinsert(spec[4].args, { spell = 208683, type = "ability", pvptalent = 1}) -- Gladiator's Medallion
  end
end

-- Death Knight
for i = 1, 3 do
  tinsert(templates.class.DEATHKNIGHT[i][4].args, { spell = 213726, type = "debuff", unit = "player", pvptalent = 7}); -- Cadaverous Pallor
  tinsert(templates.class.DEATHKNIGHT[i][4].args, { spell = 77606, type = "ability", pvptalent = 8, titleSuffix = L["cooldown"]}); -- Dark Simulacrum
  tinsert(templates.class.DEATHKNIGHT[i][4].args, { spell = 77606, type = "debuff", unit = "target", pvptalent = 8, titleSuffix = L["buff"]}); -- Dark Simulacrum
  tinsert(templates.class.DEATHKNIGHT[i][4].args, { spell = 51052, type = "ability", pvptalent = 9}); -- Anti Magic Zone
  tinsert(templates.class.DEATHKNIGHT[i][4].args, { spell = 199720, type = "debuff", unit = "target", pvptalent = 10}); -- Decomposing Aura
  tinsert(templates.class.DEATHKNIGHT[i][4].args, { spell = 199719, type = "debuff", unit = "target", pvptalent = 11}); -- Hearthstop Aura
  tinsert(templates.class.DEATHKNIGHT[i][4].args, { spell = 199642, type = "debuff", unit = "target", pvptalent = 12}); -- Necrotic Aura
end

-- Demon Hunter
for i = 1, 2 do
  tinsert(templates.class.DEMONHUNTER[i][4].args, { spell = 206649, type = "debuff", unit = "target", pvptalent = 12, titleSuffix = L["debuff"]}); -- Eye of Leotheras
  tinsert(templates.class.DEMONHUNTER[i][4].args, { spell = 206649, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"]}); -- Eye of Leotheras
  tinsert(templates.class.DEMONHUNTER[i][4].args, { spell = 205604, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"]}); -- Reverse Magic
end

-- Druid
for i = 1, 4 do
  tinsert(templates.class.DRUID[i][4].args, { spell = 209731, type = "buff", unit = "player", pvptalent = 7}); -- Protector of the Grove
end

-- Hunter
for i = 1, 3 do
  tinsert(templates.class.HUNTER[i][4].args, { spell = 202627, type = "buff", unit = "player", pvptalent = 8}); -- Catlike Reflexes
  tinsert(templates.class.HUNTER[i][4].args, { spell = 202900, type = "debuff", unit = "target", pvptalent = 11}); -- Scorpid Sting
  tinsert(templates.class.HUNTER[i][4].args, { spell = 202914, type = "debuff", unit = "target", pvptalent = 12, titleSuffix = L["debuff"]}); -- Spider Sting
  tinsert(templates.class.HUNTER[i][4].args, { spell = 202914, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"]}); -- Spider Sting
  tinsert(templates.class.HUNTER[i][4].args, { spell = 202797, type = "debuff", unit = "target", pvptalent = 10}); -- Viper Sting
  tinsert(templates.class.HUNTER[i][4].args, { spell = 195638, type = "buff", unit = "player", pvptalent = 4}); -- Focused Fire
end

-- Mage
for i = 1, 3 do
  tinsert(templates.class.MAGE[i][4].args, { spell = 221404, type = "buff", unit = "player", pvptalent = 8}); -- Burning Determination
  tinsert(templates.class.MAGE[i][4].args, { spell = 198065, type = "buff", unit = "player", pvptalent = 9}); -- Prismatic Cloak
  tinsert(templates.class.MAGE[i][4].args, { spell = 198111, type = "ability", pvptalent = 10, titleSuffix = L["cooldown"]}); -- Temporal Shield
  tinsert(templates.class.MAGE[i][4].args, { spell = 198111, type = "buff", unit = "player", pvptalent = 10, titleSuffix = L["buff"]}); -- Temporal Shield
  tinsert(templates.class.MAGE[i][4].args, { spell = 195640, type = "buff", unit = "player", pvptalent = 4}); -- Train of Thought
end

-- Monk
for i = 1, 3 do
  tinsert(templates.class.MAGE[i][4].args, { spell = 201198, type = "buff", unit = "player", pvptalent = 9}); -- Fast Feet
end

-- Rogue
for i = 1, 3 do
  tinsert(templates.class.ROGUE[i][4].args, { spell = 198027, type = "buff", unit = "player", pvptalent = 10}); -- Turn the Tables
  tinsert(templates.class.ROGUE[i][4].args, { spell = 209417, type = "buff", unit = "player", pvptalent = 12}); -- Unfair Advantage
  tinsert(templates.class.ROGUE[i][4].args, { spell = 197023, type = "buff", unit = "player", pvptalent = 9}); -- Cutting to the Chase
end

-- Shaman
for i = 1, 3 do
  tinsert(templates.class.SHAMAN[i][4].args, { spell = 204330, type = "ability", pvptalent = 7, titleSuffix = L["cooldown"]}); -- Skyfury Totem
  tinsert(templates.class.SHAMAN[i][4].args, { spell = 208963, type = "buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"]}); -- Skyfury Totem
  tinsert(templates.class.SHAMAN[i][4].args, { spell = 204331, type = "ability", pvptalent = 8, titleSuffix = L["cooldown"]}); -- Counterstrike Totem
  tinsert(templates.class.SHAMAN[i][4].args, { spell = 208997, type = "debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"]}); -- Counterstrike Totem
  tinsert(templates.class.SHAMAN[i][4].args, { spell = 204332, type = "ability", pvptalent = 9, titleSuffix = L["cooldown"]}); -- Windfury Totem
  tinsert(templates.class.SHAMAN[i][4].args, { spell = 78158, type = "buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"]}); -- Windfury Totem
  tinsert(templates.class.SHAMAN[i][4].args, { spell = 204262, type = "buff", unit = "player", pvptalent = 11}); -- Spectral Recovery
  tinsert(templates.class.SHAMAN[i][4].args, {spell = 204330, type = "totem", pvptalent = 7, titleSuffix = L["Totem"]}); -- Skyfury Totem
  tinsert(templates.class.SHAMAN[i][4].args, {spell = 204331, type = "totem", pvptalent = 8, titleSuffix = L["Totem"]}); -- Counterstrike Totem
  tinsert(templates.class.SHAMAN[i][4].args, {spell = 204332, type = "totem", pvptalent = 9, titleSuffix = L["Totem"]}); -- Windfury Totem
end

-- Warlock
for i = 1, 3 do
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 199890, type = "ability", pvptalent = 7, titleSuffix = L["cooldown"]}); -- Curse of Tongues
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 199890, type = "debuff", unit = "multi", pvptalent = 7, titleSuffix = L["debuff"]}); -- Curse of Tongues
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 199892, type = "ability", pvptalent = 8, titleSuffix = L["cooldown"]}); -- Curse of Weakness
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 199892, type = "debuff", unit = "multi", pvptalent = 8, titleSuffix = L["debuff"]}); -- Curse of Weakness
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 199954, type = "ability", pvptalent = 9, titleSuffix = L["cooldown"]}); -- Curse of Fragility
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 199954, type = "debuff", unit = "multi", pvptalent = 9, titleSuffix = L["debuff"]}); -- Curse of Fragility
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 221703, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"]}); -- Casting Circle
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 221705, type = "buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]}); -- Casting Circle
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 212295, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"]}); -- Nether Ward
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 212295, type = "buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"]}); -- Nether Ward
  tinsert(templates.class.WARLOCK[i][4].args, { spell = 195640, type = "buff", unit = "player", pvptalent = 4}); -- Train of Thought
end

-- Warrior
for i = 1, 3 do
  tinsert(templates.class.WARRIOR[i][4].args, { spell = 198498, type = "buff", unit = "player", pvptalent = 8}); -- Blood Hunt
  tinsert(templates.class.WARRIOR[i][4].args, { spell = 216890, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"]}); -- Spell Reflection
  tinsert(templates.class.WARRIOR[i][4].args, { spell = 216890, type = "buff", unit = "player", pvptalent = 11, titleSuffix = L["buff"]}); -- Spell Reflection
end

------------------------------
-- Hardcoded trigger templates
-------------------------------

-- Warrior
for i = 1, 3 do
  tinsert(templates.class.WARRIOR[i][5].args, createSimplePowerTemplate(1));
end

-- Paladin
tinsert(templates.class.PALADIN[3][5].args, createSimplePowerTemplate(9));
for i = 1, 3 do
  tinsert(templates.class.PALADIN[i][5].args, createSimplePowerTemplate(0));
end

-- Hunter
for i = 1, 3 do
  tinsert(templates.class.HUNTER[i][5].args, createSimplePowerTemplate(2));
end

-- Rogue
for i = 1, 3 do
  tinsert(templates.class.ROGUE[i][5].args, createSimplePowerTemplate(3));
  tinsert(templates.class.ROGUE[i][5].args, createSimplePowerTemplate(4));
end

-- Priest
for i = 1, 3 do
  tinsert(templates.class.PRIEST[i][5].args, createSimplePowerTemplate(0));
end
tinsert(templates.class.PRIEST[3][5].args, createSimplePowerTemplate(13));

-- Shaman
for i = 1, 3 do
  tinsert(templates.class.SHAMAN[i][5].args, createSimplePowerTemplate(0));

  templates.class.SHAMAN[i][6] = {
    title = L["Totems"],
    args = {
      {spell = 226772, type = "totem", talent = 3}, -- Totem Mastery
      {spell = 192078, type = "totem", talent = 6}, -- Wind Rush Totem
      {spell = 192058, type = "totem", talent = 7}, -- Lightning Surge
      {spell = 51485, type = "totem", talent = 8}, -- Earthgrab Totem
      {spell = 196935, type = "totem", talent = 9}, -- Voodoo Totem
      {spell = 192223, type = "totem", talent = 21}, -- Liquid Magma Totem
    },
    icon = 538575,
  };
end

for i = 1, 2 do
  tinsert(templates.class.SHAMAN[i][5].args, createSimplePowerTemplate(11));
end

-- Mage
tinsert(templates.class.MAGE[1][5].args, createSimplePowerTemplate(16));
for i = 1, 3 do
  tinsert(templates.class.MAGE[i][5].args, createSimplePowerTemplate(0));
end

local runeOfPower =
{
  title = GetSpellInfo(116011),
  icon = select(3, GetSpellInfo(116011)),
  talent = 8,
  triggers = {
    [0] = {
      trigger = {
        type = "status",
        event = "Totem",
        use_totemType = true,
        totemType = 1,
        unevent = "auto"
      }
    },
    [1] = {
      trigger = {
        type = "aura",
        spellIds = { 116014 },
        unit = "player",
        use_unit = true,
        debuffType = "HELPFUL",
        unevent = "auto",
        ownOnly = true
      }
    }
  },
  disjunctive = "all"
}

for i = 1, 3 do
  tinsert(templates.class.MAGE[i][1].args, runeOfPower);
end

-- Warlock
for i = 1, 3 do
  tinsert(templates.class.WARLOCK[i][5].args, createSimplePowerTemplate(0));
  tinsert(templates.class.WARLOCK[i][5].args, createSimplePowerTemplate(7));
end

-- Monk
tinsert(templates.class.MONK[1][5].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[2][5].args, createSimplePowerTemplate(0));
tinsert(templates.class.MONK[3][5].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[3][5].args, createSimplePowerTemplate(12));

-- Druid
for i = 1, 4 do
  -- Shapeshift Form
  tinsert(templates.class.DRUID[i][5].args, {
    title = L["Shapeshift Form"],
    icon = 132276,
    triggers = {[0] = { trigger = { type = "status", event = "Stance/Form/Aura", unevent = "auto"}}}
  });
end

-- Astral Power
tinsert(templates.class.DRUID[1][5].args, createSimplePowerTemplate(8));

for i = 1, 4 do
  tinsert(templates.class.DRUID[i][5].args, createSimplePowerTemplate(0)); -- Mana
  tinsert(templates.class.DRUID[i][5].args, createSimplePowerTemplate(1)); -- Rage
  tinsert(templates.class.DRUID[i][5].args, createSimplePowerTemplate(3)); -- Energy
  tinsert(templates.class.DRUID[i][5].args, createSimplePowerTemplate(4)); -- Combo Points
end

-- Efflorescence aka Mushroom
tinsert(templates.class.DRUID[4][3].args,  {spell = 145205, type = "totem", totemNumber = 1 });

-- Demon Hunter
tinsert(templates.class.DEMONHUNTER[1][5].args, createSimplePowerTemplate(17));
tinsert(templates.class.DEMONHUNTER[2][5].args, createSimplePowerTemplate(18));

-- Death Knight
for i = 1, 3 do
  tinsert(templates.class.DEATHKNIGHT[i][5].args, createSimplePowerTemplate(6));

  tinsert(templates.class.DEATHKNIGHT[i][5].args, {
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

------------------------------
-- Helper code for options
-------------------------------

-- Enrich items from spell, set title
local function handleItem(item)
  if (item.spell) then
    local name, icon, tmp;
    if (item.type == "item") then
      name, tmp, tmp, tmp, tmp, tmp, tmp, tmp, tmp, icon = GetItemInfo(item.spell);
      if (name == nil) then
        name = L["Unknown Item"] .. " " .. tostring(item.spell);
      end
    else
      name, tmp, icon = GetSpellInfo(item.spell);
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
    if (item.titleItemPrefix) then
      local prefix = GetItemInfo(item.titleItemPrefix);
      if (prefix) then
        item.title = prefix .. "-" .. item.title;
      end
    end
    if (item.type ~= "item") then
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
