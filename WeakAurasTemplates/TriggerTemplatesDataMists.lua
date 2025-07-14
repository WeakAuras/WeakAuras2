local AddonName, TemplatePrivate = ...
---@class WeakAuras
local WeakAuras = WeakAuras
if not WeakAuras.IsMists() then return end
local L = WeakAuras.L
local GetSpellInfo, tinsert, GetSpellDescription, C_Timer, Spell
    = GetSpellInfo, tinsert, GetSpellDescription, C_Timer, Spell

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
      Orc = {},
      Scourge = {},
      Tauren = {},
      Troll = {},
      BloodElf = {},
      Pandaren = {},
    },
    general = {
      title = L["General"],
      icon = 136116,
      args = {}
    },
  }

local manaIcon = "Interface\\Icons\\spell_frost_manarecharge.blp"
local rageIcon = "Interface\\Icons\\ability_racial_bloodrage.blp"
local comboPointsIcon = "Interface\\Icons\\ability_backstab"

local powerTypes =
  {
    [0] = { name = POWER_TYPE_MANA, icon = manaIcon },
    [1] = { name = POWER_TYPE_RED_POWER, icon = rageIcon},
    [2] = { name = POWER_TYPE_FOCUS, icon = "Interface\\Icons\\ability_hunter_focusfire"},
    [3] = { name = POWER_TYPE_ENERGY, icon = "Interface\\Icons\\spell_shadow_shadowworddominate"},
    [4] = { name = COMBO_POINTS, icon = comboPointsIcon},
    [12] = {name = CHI_POWER, icon = "Interface\\Icons\\ability_monk_healthsphere"},
  }

-- Collected by WeakAurasTemplateCollector:
--------------------------------------------------------------------------------

-- DONE
templates.class.WARRIOR = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 469, type = "buff", unit = "player" }, -- Commanding Shout
        { spell = 871, type = "buff", unit = "player" }, -- Shield Wall
        { spell = 1719, type = "buff", unit = "player" }, -- Recklessness
        { spell = 6673, type = "buff", unit = "player" }, -- Battle Shout
        { spell = 12292, type = "buff", unit = "player", talent = 17 }, -- Bloodbath
        { spell = 12328, type = "buff", unit = "player" }, -- Sweeping Strikes
        { spell = 12880, type = "buff", unit = "player" }, -- Enrage
        { spell = 12968, type = "buff", unit = "player" }, -- Flurry
        { spell = 18499, type = "buff", unit = "player" }, -- Berserker Rage
        { spell = 20572, type = "buff", unit = "player" }, -- Blood Fury
        { spell = 23920, type = "buff", unit = "player" }, -- Spell Reflection
        { spell = 46916, type = "buff", unit = "player" }, -- Bloodsurge
        { spell = 50227, type = "buff", unit = "player" }, -- Sword and Board
        { spell = 52437, type = "buff", unit = "player" }, -- Sudden Death
        { spell = 55694, type = "buff", unit = "player", talent = 4 }, -- Enraged Regeneration
        { spell = 60503, type = "buff", unit = "player" }, -- Taste for Blood
        { spell = 97463, type = "buff", unit = "player" }, -- Rallying Cry
        { spell = 107574, type = "buff", unit = "player", talent = 16 }, -- Avatar
        { spell = 112048, type = "buff", unit = "player" }, -- Shield Barrier
        { spell = 114028, type = "buff", unit = "player", talent = 13 }, -- Mass Spell Reflection
        { spell = 118038, type = "buff", unit = "player" }, -- Die by the Sword
        { spell = 122510, type = "buff", unit = "player" }, -- Ultimatum
        { spell = 125565, type = "buff", unit = "player" }, -- Demoralizing Shout
        { spell = 126513, type = "buff", unit = "player" }, -- Poised to Strike
        { spell = 131116, type = "buff", unit = "player" }, -- Raging Blow!
        { spell = 132404, type = "buff", unit = "player" }, -- Shield Block
        { spell = 139958, type = "buff", unit = "player" }, -- Sudden Execute
        { spell = 147833, type = "buff", unit = "target" }, -- Intervene
      },
      icon = 132333
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1160, type = "debuff", unit = "target" }, -- Demoralizing Shout
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target" }, -- Intimidating Shout
        { spell = 7922, type = "debuff", unit = "target" }, -- Charge Stun
        { spell = 12323, type = "debuff", unit = "target", talent = 8 }, -- Piercing Howl
        { spell = 64382, type = "debuff", unit = "target" }, -- Shattering Throw
        { spell = 81326, type = "debuff", unit = "target" }, -- Physical Vulnerability
        { spell = 86346, type = "debuff", unit = "target" }, -- Colossus Smash
        { spell = 105771, type = "debuff", unit = "target", talent = 3 }, -- Warbringer
        { spell = 107566, type = "debuff", unit = "target", talent = 7 }, -- Staggering Shout
        { spell = 113344, type = "debuff", unit = "target", talent = 17 }, -- Bloodbath
        { spell = 113746, type = "debuff", unit = "target" }, -- Weakened Armor
        { spell = 115767, type = "debuff", unit = "target" }, -- Deep Wounds
        { spell = 115798, type = "debuff", unit = "target" }, -- Weakened Blows
        { spell = 115804, type = "debuff", unit = "target" }, -- Mortal Wounds
        { spell = 132168, type = "debuff", unit = "target", talent = 11 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 18 }, -- Storm Bolt
      },
      icon = 132366
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 71, type = "ability" }, -- Defensive Stance
        { spell = 78, type = "ability", overlayGlow = true, requiresTarget = true }, -- Heroic Strike
        { spell = 100, type = "ability", requiresTarget = true, usable = true }, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true }, -- Taunt
        { spell = 469, type = "ability", buff = true }, -- Commanding Shout
        { spell = 676, type = "ability", requiresTarget = true }, -- Disarm
        { spell = 845, type = "ability", overlayGlow = true, requiresTarget = true }, -- Cleave
        { spell = 871, type = "ability", buff = true }, -- Shield Wall
        { spell = 1160, type = "ability", debuff = true }, -- Demoralizing Shout
        { spell = 1464, type = "ability", requiresTarget = true }, -- Slam
        { spell = 1715, type = "ability", debuff = true, requiresTarget = true }, -- Hamstring
        { spell = 1719, type = "ability", buff = true }, -- Recklessness
        { spell = 2457, type = "ability" }, -- Battle Stance
        { spell = 2458, type = "ability" }, -- Berserker Stance
        { spell = 2565, type = "ability", charges = true, usable = true }, -- Shield Block
        { spell = 3411, type = "ability", requiresTarget = true }, -- Intervene
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true }, -- Intimidating Shout
        { spell = 5308, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Execute
        { spell = 6343, type = "ability" }, -- Thunder Clap
        { spell = 6552, type = "ability", requiresTarget = true }, -- Pummel
        { spell = 6572, type = "ability", requiresTarget = true }, -- Revenge
        { spell = 6673, type = "ability", buff = true }, -- Battle Shout
        { spell = 7384, type = "ability", charges = true, requiresTarget = true, usable = true }, -- Overpower
        { spell = 7386, type = "ability", requiresTarget = true }, -- Sunder Armor
        { spell = 12292, type = "ability", buff = true, talent = 17 }, -- Bloodbath
        { spell = 12294, type = "ability", requiresTarget = true }, -- Mortal Strike
        { spell = 12328, type = "ability", buff = true }, -- Sweeping Strikes
        { spell = 18499, type = "ability", buff = true }, -- Berserker Rage
        { spell = 20243, type = "ability", requiresTarget = true, usable = true }, -- Devastate
        { spell = 20572, type = "ability", buff = true }, -- Blood Fury
        { spell = 23881, type = "ability", requiresTarget = true }, -- Bloodthirst
        { spell = 23920, type = "ability", buff = true }, -- Spell Reflection
        { spell = 23922, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Shield Slam
        { spell = 34428, type = "ability", requiresTarget = true, usable = true }, -- Victory Rush
        { spell = 46924, type = "ability", talent = 10 }, -- Bladestorm
        { spell = 46968, type = "ability", talent = 11 }, -- Shockwave
        { spell = 55694, type = "ability", buff = true, talent = 4 }, -- Enraged Regeneration
        { spell = 57755, type = "ability", requiresTarget = true }, -- Heroic Throw
        { spell = 64382, type = "ability", debuff = true, requiresTarget = true }, -- Shattering Throw
        { spell = 85288, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Raging Blow
        { spell = 86346, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Colossus Smash
        { spell = 97462, type = "ability" }, -- Rallying Cry
        { spell = 100130, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Wild Strike
        { spell = 102060, type = "ability", talent = 9 }, -- Disrupting Shout
        { spell = 103840, type = "ability", requiresTarget = true, talent = 6 }, -- Impending Victory
        { spell = 107566, type = "ability", debuff = true, talent = 7 }, -- Staggering Shout
        { spell = 107570, type = "ability", requiresTarget = true, talent = 18 }, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true, talent = 16 }, -- Avatar
        { spell = 112048, type = "ability", buff = true, usable = true }, -- Shield Barrier
        { spell = 114028, type = "ability", buff = true, talent = 13 }, -- Mass Spell Reflection
        { spell = 118000, type = "ability", talent = 12 }, -- Dragon Roar
        { spell = 118038, type = "ability", buff = true }, -- Die by the Sword
        { spell = 122475, type = "ability", requiresTarget = true }, -- Throw
        { spell = 1250619, type = "ability", charges = true, requiresTarget = true }, -- Charge
      },
      icon = 132355
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = rageIcon,
    }
  }
}

templates.class.PALADIN = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 498, type = "buff", unit = "player" }, -- Divine Protection
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "player" }, -- Hand of Protection
        { spell = 1038, type = "buff", unit = "player" }, -- Hand of Salvation
        { spell = 1044, type = "buff", unit = "player" }, -- Hand of Freedom
        { spell = 19740, type = "buff", unit = "player" }, -- Blessing of Might
        { spell = 20217, type = "buff", unit = "player" }, -- Blessing of Kings
        { spell = 20925, type = "buff", unit = "player", talent = 9 }, -- Sacred Shield
        { spell = 25780, type = "buff", unit = "player" }, -- Righteous Fury
        { spell = 31821, type = "buff", unit = "player" }, -- Devotion Aura
        { spell = 31842, type = "buff", unit = "player" }, -- Divine Favor
        { spell = 31850, type = "buff", unit = "player" }, -- Ardent Defender
        { spell = 31884, type = "buff", unit = "player" }, -- Avenging Wrath
        { spell = 53563, type = "buff", unit = "player" }, -- Beacon of Light
        { spell = 54428, type = "buff", unit = "player" }, -- Divine Plea
        { spell = 84963, type = "buff", unit = "player" }, -- Inquisition
        { spell = 85499, type = "buff", unit = "player", talent = 1 }, -- Speed of Light
        { spell = 86273, type = "buff", unit = "player" }, -- Illuminated Healing
        { spell = 86659, type = "buff", unit = "player" }, -- Guardian of Ancient Kings
        { spell = 86700, type = "buff", unit = "player" }, -- Ancient Power
        { spell = 90174, type = "buff", unit = "player", talent = 15 }, -- Divine Purpose
        { spell = 105809, type = "buff", unit = "player", talent = 13 }, -- Holy Avenger
        { spell = 114039, type = "buff", unit = "player", talent = 10 }, -- Hand of Purity
        { spell = 114163, type = "buff", unit = "player", talent = 8 }, -- Eternal Flame
        { spell = 114250, type = "buff", unit = "player", talent = 7 }, -- Selfless Healer
        { spell = 114637, type = "buff", unit = "player" }, -- Bastion of Glory
        { spell = 114695, type = "buff", unit = "player", talent = 3 }, -- Pursuit of Justice
        { spell = 126513, type = "buff", unit = "player" }, -- Poised to Strike
        { spell = 132403, type = "buff", unit = "player" }, -- Shield of the Righteous
      },
      icon = 135964
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 2812, type = "debuff", unit = "target" }, -- Denounce
        { spell = 20170, type = "debuff", unit = "target" }, -- Seal of Justice
        { spell = 31803, type = "debuff", unit = "target" }, -- Censure
        { spell = 31935, type = "debuff", unit = "target" }, -- Avenger's Shield
        { spell = 62124, type = "debuff", unit = "target" }, -- Reckoning
        { spell = 81298, type = "debuff", unit = "target" }, -- Consecration
        { spell = 81326, type = "debuff", unit = "target" }, -- Physical Vulnerability
        { spell = 105421, type = "debuff", unit = "target" }, -- Blinding Light
        { spell = 105593, type = "debuff", unit = "target", talent = 4 }, -- Fist of Justice
        { spell = 114916, type = "debuff", unit = "target", talent = 18 }, -- Execution Sentence
        { spell = 114919, type = "debuff", unit = "target" }, -- Arcing Light
        { spell = 115798, type = "debuff", unit = "target" }, -- Weakened Blows
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 498, type = "ability", buff = true }, -- Divine Protection
        { spell = 633, type = "ability" }, -- Lay on Hands
        { spell = 642, type = "ability", buff = true }, -- Divine Shield
        { spell = 853, type = "ability", debuff = true, requiresTarget = true }, -- Hammer of Justice
        { spell = 879, type = "ability", overlayGlow = true }, -- Exorcism
        { spell = 1022, type = "ability", charges = true, buff = true, usable = true }, -- Hand of Protection
        { spell = 1038, type = "ability", charges = true, buff = true }, -- Hand of Salvation
        { spell = 1044, type = "ability", charges = true, buff = true }, -- Hand of Freedom
        { spell = 2812, type = "ability", debuff = true, requiresTarget = true }, -- Denounce
        { spell = 4987, type = "ability" }, -- Cleanse
        { spell = 6940, type = "ability", charges = true }, -- Hand of Sacrifice
        { spell = 10326, type = "ability" }, -- Turn Evil
        { spell = 20066, type = "ability", talent = 5 }, -- Repentance
        { spell = 20271, type = "ability", requiresTarget = true, usable = true }, -- Judgment
        { spell = 20473, type = "ability" }, -- Holy Shock
        { spell = 20925, type = "ability", buff = true, talent = 9 }, -- Sacred Shield
        { spell = 24275, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Hammer of Wrath
        { spell = 25780, type = "ability", buff = true }, -- Righteous Fury
        { spell = 26573, type = "ability", totem = true }, -- Consecration
        { spell = 31821, type = "ability", buff = true }, -- Devotion Aura
        { spell = 31842, type = "ability", buff = true }, -- Divine Favor
        { spell = 31850, type = "ability", buff = true }, -- Ardent Defender
        { spell = 31884, type = "ability", buff = true }, -- Avenging Wrath
        { spell = 31935, type = "ability", debuff = true, usable = true }, -- Avenger's Shield
        { spell = 35395, type = "ability", requiresTarget = true, usable = true }, -- Crusader Strike
        { spell = 53563, type = "ability", buff = true }, -- Beacon of Light
        { spell = 53595, type = "ability", requiresTarget = true, usable = true }, -- Hammer of the Righteous
        { spell = 53600, type = "ability", requiresTarget = true, usable = true }, -- Shield of the Righteous
        { spell = 54428, type = "ability", buff = true }, -- Divine Plea
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true }, -- Reckoning
        { spell = 85256, type = "ability", overlayGlow = true, requiresTarget = true }, -- Templar's Verdict
        { spell = 85499, type = "ability", buff = true, talent = 1 }, -- Speed of Light
        { spell = 85673, type = "ability", overlayGlow = true }, -- Word of Glory
        { spell = 86659, type = "ability", buff = true }, -- Guardian of Ancient Kings
        { spell = 96231, type = "ability", requiresTarget = true }, -- Rebuke
        { spell = 105593, type = "ability", debuff = true, requiresTarget = true, talent = 4 }, -- Fist of Justice
        { spell = 105809, type = "ability", buff = true, talent = 13 }, -- Holy Avenger
        { spell = 114039, type = "ability", buff = true, talent = 10 }, -- Hand of Purity
        { spell = 114157, type = "ability", talent = 18 }, -- Execution Sentence
        { spell = 114158, type = "ability", totem = true, talent = 17 }, -- Light's Hammer
        { spell = 114163, type = "ability", buff = true, talent = 8 }, -- Eternal Flame
        { spell = 114165, type = "ability", talent = 16 }, -- Holy Prism
        { spell = 115750, type = "ability" }, -- Blinding Light
        { spell = 119072, type = "ability" }, -- Holy Wrath
      },
      icon = 135972
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  }
}

templates.class.HUNTER = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 3045, type = "buff", unit = "player" }, -- Rapid Fire
        { spell = 5118, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 5384, type = "buff", unit = "player" }, -- Feign Death
        { spell = 13159, type = "buff", unit = "player" }, -- Aspect of the Pack
        { spell = 13165, type = "buff", unit = "player" }, -- Aspect of the Hawk
        { spell = 19263, type = "buff", unit = "player" }, -- Deterrence
        { spell = 19506, type = "buff", unit = "player" }, -- Trueshot Aura
        { spell = 19615, type = "buff", unit = "player" }, -- Frenzy
        { spell = 34471, type = "buff", unit = "player" }, -- The Beast Within
        { spell = 34720, type = "buff", unit = "player", talent = 12 }, -- Thrill of the Hunt
        { spell = 45444, type = "buff", unit = "player" }, -- Bonfire's Blessing
        { spell = 51755, type = "buff", unit = "player" }, -- Camouflage
        { spell = 53257, type = "buff", unit = "player" }, -- Cobra Strikes
        { spell = 54216, type = "buff", unit = "player" }, -- Master's Call
        { spell = 54227, type = "buff", unit = "player" }, -- Rapid Recuperation
        { spell = 56453, type = "buff", unit = "player" }, -- Lock and Load
        { spell = 77769, type = "buff", unit = "player" }, -- Trap Launcher
        { spell = 82692, type = "buff", unit = "player" }, -- Focus Fire
        { spell = 82726, type = "buff", unit = "player", talent = 10 }, -- Fervor
        { spell = 109260, type = "buff", unit = "player", talent = 8 }, -- Aspect of the Iron Hawk
        { spell = 118694, type = "buff", unit = "player", talent = 9 }, -- Spirit Bond
        { spell = 118922, type = "buff", unit = "player", talent = 1 }, -- Posthaste
        { spell = 126483, type = "buff", unit = "player" }, -- Windswept Pages
        { spell = 136, type = "buff", unit = "target" }, -- Mend Pet
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 19574, type = "buff", unit = "pet" }, -- Bestial Wrath
        { spell = 61684, type = "buff", unit = "pet" }, -- Dash
        { spell = 62305, type = "buff", unit = "pet" }, -- Master's Call
        { spell = 82728, type = "buff", unit = "pet", talent = 10 }, -- Fervor
        { spell = 118455, type = "buff", unit = "pet" }, -- Beast Cleave
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1130, type = "debuff", unit = "target" }, -- Hunter's Mark
        { spell = 2649, type = "debuff", unit = "target" }, -- Growl
        { spell = 3674, type = "debuff", unit = "target" }, -- Black Arrow
        { spell = 4167, type = "debuff", unit = "target" }, -- Web
        { spell = 5116, type = "debuff", unit = "target" }, -- Concussive Shot
        { spell = 19386, type = "debuff", unit = "target", talent = 5 }, -- Wyvern Sting
        { spell = 19503, type = "debuff", unit = "target" }, -- Scatter Shot
        { spell = 20736, type = "debuff", unit = "target" }, -- Distracting Shot
        { spell = 24394, type = "debuff", unit = "target", talent = 6 }, -- Intimidation
        { spell = 34490, type = "debuff", unit = "target" }, -- Silencing Shot
        { spell = 35101, type = "debuff", unit = "target" }, -- Concussive Barrage
        { spell = 53301, type = "debuff", unit = "target" }, -- Explosive Shot
        { spell = 82654, type = "debuff", unit = "target" }, -- Widow Venom
        { spell = 117405, type = "debuff", unit = "target", talent = 4 }, -- Binding Shot
        { spell = 118253, type = "debuff", unit = "target" }, -- Serpent Sting
        { spell = 120699, type = "debuff", unit = "target", talent = 15 }, -- Lynx Rush
        { spell = 120761, type = "debuff", unit = "target", talent = 16 }, -- Glaive Toss
        { spell = 131894, type = "debuff", unit = "target", talent = 13 }, -- A Murder of Crows
      },
      icon = 135860
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 75, type = "ability", requiresTarget = true, usable = true }, -- Auto Shot
        { spell = 781, type = "ability" }, -- Disengage
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 1978, type = "ability", requiresTarget = true, usable = true }, -- Serpent Sting
        { spell = 2643, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Multi-Shot
        { spell = 2649, type = "ability", debuff = true }, -- Growl
        { spell = 3044, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Arcane Shot
        { spell = 3045, type = "ability", buff = true }, -- Rapid Fire
        { spell = 3674, type = "ability", debuff = true }, -- Black Arrow
        { spell = 4167, type = "ability", debuff = true }, -- Web
        { spell = 5116, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Concussive Shot
        { spell = 5118, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 5384, type = "ability", buff = true }, -- Feign Death
        { spell = 6991, type = "ability", requiresTarget = true, usable = true }, -- Feed Pet
        { spell = 13159, type = "ability", buff = true }, -- Aspect of the Pack
        { spell = 13165, type = "ability", buff = true }, -- Aspect of the Hawk
        { spell = 17253, type = "ability" }, -- Bite
        { spell = 19263, type = "ability", charges = true, buff = true }, -- Deterrence
        { spell = 19386, type = "ability", debuff = true, talent = 5 }, -- Wyvern Sting
        { spell = 19503, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Scatter Shot
        { spell = 19574, type = "ability", buff = true, unit = 'pet' }, -- Bestial Wrath
        { spell = 19577, type = "ability", talent = 6 }, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true, usable = true }, -- Tranquilizing Shot
        { spell = 20736, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Distracting Shot
        { spell = 34026, type = "ability" }, -- Kill Command
        { spell = 34490, type = "ability", debuff = true }, -- Silencing Shot
        { spell = 51753, type = "ability" }, -- Camouflage
        { spell = 53209, type = "ability" }, -- Chimera Shot
        { spell = 53271, type = "ability" }, -- Master's Call
        { spell = 53301, type = "ability", debuff = true, overlayGlow = true }, -- Explosive Shot
        { spell = 53351, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Kill Shot
        { spell = 61684, type = "ability", buff = true, unit = 'pet' }, -- Dash
        { spell = 77767, type = "ability", requiresTarget = true, usable = true }, -- Cobra Shot
        { spell = 77769, type = "ability", buff = true }, -- Trap Launcher
        { spell = 82654, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Widow Venom
        { spell = 82692, type = "ability", charges = true, buff = true, overlayGlow = true, usable = true }, -- Focus Fire
        { spell = 82726, type = "ability", buff = true, talent = 10 }, -- Fervor
        { spell = 109248, type = "ability", usable = true, talent = 4 }, -- Binding Shot
        { spell = 109259, type = "ability", talent = 17 }, -- Powershot
        { spell = 109260, type = "ability", buff = true, talent = 8 }, -- Aspect of the Iron Hawk
        { spell = 109304, type = "ability", talent = 7 }, -- Exhilaration
        { spell = 117050, type = "ability", requiresTarget = true, usable = true, talent = 16 }, -- Glaive Toss
        { spell = 120360, type = "ability", usable = true, talent = 18 }, -- Barrage
        { spell = 120679, type = "ability", talent = 11 }, -- Dire Beast
        { spell = 120697, type = "ability", talent = 15 }, -- Lynx Rush
        { spell = 121818, type = "ability", requiresTarget = true }, -- Stampede
        { spell = 131894, type = "ability", debuff = true, requiresTarget = true, talent = 13 }, -- A Murder of Crows
        { spell = 147362, type = "ability", requiresTarget = true, usable = true }, -- Counter Shot
        { spell = 148467, type = "ability", charges = true, buff = true }, -- Deterrence
      },
      icon = 135130
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  }
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
        { spell = 5171, type = "buff", unit = "player" }, -- Slice and Dice
        { spell = 5277, type = "buff", unit = "player" }, -- Evasion
        { spell = 5761, type = "buff", unit = "player" }, -- Mind-numbing Poison
        { spell = 8679, type = "buff", unit = "player" }, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 13750, type = "buff", unit = "player" }, -- Adrenaline Rush
        { spell = 13877, type = "buff", unit = "player" }, -- Blade Flurry
        { spell = 31224, type = "buff", unit = "player" }, -- Cloak of Shadows
        { spell = 31665, type = "buff", unit = "player" }, -- Master of Subtlety
        { spell = 32645, type = "buff", unit = "player" }, -- Envenom
        { spell = 36554, type = "buff", unit = "player", talent = 11 }, -- Shadowstep
        { spell = 51690, type = "buff", unit = "player" }, -- Killing Spree
        { spell = 51713, type = "buff", unit = "player" }, -- Shadow Dance
        { spell = 73651, type = "buff", unit = "player" }, -- Recuperate
        { spell = 74001, type = "buff", unit = "player", talent = 6 }, -- Combat Readiness
        { spell = 84745, type = "buff", unit = "player" }, -- Shallow Insight
        { spell = 108211, type = "buff", unit = "player", talent = 8 }, -- Leeching Poison
        { spell = 108215, type = "buff", unit = "player", talent = 14 }, -- Paralytic Poison
        { spell = 112942, type = "buff", unit = "player", talent = 3 }, -- Shadow Focus
        { spell = 113742, type = "buff", unit = "player" }, -- Swiftblade's Cunning
        { spell = 114018, type = "buff", unit = "player" }, -- Shroud of Concealment
        { spell = 114842, type = "buff", unit = "player" }, -- Shadow Walk
        { spell = 115189, type = "buff", unit = "player", talent = 18 }, -- Anticipation
        { spell = 115192, type = "buff", unit = "player", talent = 2 }, -- Subterfuge
        { spell = 121153, type = "buff", unit = "player" }, -- Blindside
        { spell = 121471, type = "buff", unit = "player" }, -- Shadow Blades
        { spell = 137573, type = "buff", unit = "player", talent = 12 }, -- Burst of Speed
        { spell = 1246774, type = "buff", unit = "player" }, -- Bandit's Guile
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 703, type = "debuff", unit = "target" }, -- Garrote
        { spell = 1330, type = "debuff", unit = "target" }, -- Garrote - Silence
        { spell = 1776, type = "debuff", unit = "target" }, -- Gouge
        { spell = 1833, type = "debuff", unit = "target" }, -- Cheap Shot
        { spell = 1943, type = "debuff", unit = "target" }, -- Rupture
        { spell = 2094, type = "debuff", unit = "target" }, -- Blind
        { spell = 2818, type = "debuff", unit = "target" }, -- Deadly Poison
        { spell = 3409, type = "debuff", unit = "target" }, -- Crippling Poison
        { spell = 5760, type = "debuff", unit = "target" }, -- Mind-numbing Poison
        { spell = 8680, type = "debuff", unit = "target" }, -- Wound Poison
        { spell = 79140, type = "debuff", unit = "target" }, -- Vendetta
        { spell = 84617, type = "debuff", unit = "target" }, -- Revealing Strike
        { spell = 88611, type = "debuff", unit = "target" }, -- Smoke Bomb
        { spell = 89775, type = "debuff", unit = "target" }, -- Hemorrhage
        { spell = 91021, type = "debuff", unit = "target" }, -- Find Weakness
        { spell = 93068, type = "debuff", unit = "target" }, -- Master Poisoner
        { spell = 112947, type = "debuff", unit = "target", talent = 5 }, -- Nerve Strike
        { spell = 112961, type = "debuff", unit = "target", talent = 8 }, -- Leeching Poison
        { spell = 113746, type = "debuff", unit = "target" }, -- Weakened Armor
        { spell = 113952, type = "debuff", unit = "target", talent = 14 }, -- Paralytic Poison
        { spell = 113953, type = "debuff", unit = "target" }, -- Paralysis
        { spell = 115197, type = "debuff", unit = "target" }, -- Partial Paralysis
        { spell = 122233, type = "debuff", unit = "target" }, -- Crimson Tempest
        { spell = 137619, type = "debuff", unit = "target", talent = 17 }, -- Marked for Death
      },
      icon = 132302
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 53, type = "ability", requiresTarget = true }, -- Backstab
        { spell = 408, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Kidney Shot
        { spell = 703, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Garrote
        { spell = 921, type = "ability", requiresTarget = true, usable = true }, -- Pick Pocket
        { spell = 1725, type = "ability" }, -- Distract
        { spell = 1752, type = "ability", requiresTarget = true, usable = true }, -- Sinister Strike
        { spell = 1766, type = "ability", requiresTarget = true }, -- Kick
        { spell = 1776, type = "ability", debuff = true, requiresTarget = true }, -- Gouge
        { spell = 1784, type = "ability", buff = true, usable = true }, -- Stealth
        { spell = 1833, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Cheap Shot
        { spell = 1856, type = "ability" }, -- Vanish
        { spell = 1943, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Rupture
        { spell = 2094, type = "ability", debuff = true, requiresTarget = true }, -- Blind
        { spell = 2098, type = "ability", requiresTarget = true, usable = true }, -- Eviscerate
        { spell = 2983, type = "ability", buff = true, usable = true }, -- Sprint
        { spell = 5277, type = "ability", buff = true }, -- Evasion
        { spell = 5938, type = "ability", requiresTarget = true }, -- Shiv
        { spell = 8647, type = "ability", requiresTarget = true }, -- Expose Armor
        { spell = 8676, type = "ability", requiresTarget = true, usable = true }, -- Ambush
        { spell = 13750, type = "ability", buff = true }, -- Adrenaline Rush
        { spell = 13877, type = "ability", buff = true }, -- Blade Flurry
        { spell = 14183, type = "ability", requiresTarget = true, usable = true }, -- Premeditation
        { spell = 14185, type = "ability" }, -- Preparation
        { spell = 16511, type = "ability", requiresTarget = true }, -- Hemorrhage
        { spell = 31224, type = "ability", buff = true }, -- Cloak of Shadows
        { spell = 36554, type = "ability", buff = true, requiresTarget = true, talent = 11 }, -- Shadowstep
        { spell = 51690, type = "ability", buff = true }, -- Killing Spree
        { spell = 51713, type = "ability", buff = true }, -- Shadow Dance
        { spell = 51722, type = "ability", requiresTarget = true }, -- Dismantle
        { spell = 73981, type = "ability", requiresTarget = true }, -- Redirect
        { spell = 74001, type = "ability", buff = true, talent = 6 }, -- Combat Readiness
        { spell = 76577, type = "ability" }, -- Smoke Bomb
        { spell = 79140, type = "ability", debuff = true }, -- Vendetta
        { spell = 84617, type = "ability", debuff = true, requiresTarget = true }, -- Revealing Strike
        { spell = 114018, type = "ability", buff = true, usable = true }, -- Shroud of Concealment
        { spell = 114842, type = "ability", buff = true, usable = true }, -- Shadow Walk
        { spell = 115191, type = "ability", buff = true }, -- Stealth
        { spell = 121471, type = "ability", buff = true }, -- Shadow Blades
        { spell = 121733, type = "ability", requiresTarget = true }, -- Throw
        { spell = 137619, type = "ability", debuff = true, requiresTarget = true, talent = 17 }, -- Marked for Death
      },
      icon = 132350
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = comboPointsIcon,
    },
  }
}

templates.class.PRIEST = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 17, type = "buff", unit = "player" }, -- Power Word: Shield
        { spell = 139, type = "buff", unit = "player" }, -- Renew
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 588, type = "buff", unit = "player" }, -- Inner Fire
        { spell = 6346, type = "buff", unit = "player" }, -- Fear Ward
        { spell = 10060, type = "buff", unit = "player", talent = 14 }, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player" }, -- Vampiric Embrace
        { spell = 15473, type = "buff", unit = "player" }, -- Shadowform
        { spell = 21562, type = "buff", unit = "player" }, -- Power Word: Fortitude
        { spell = 33206, type = "buff", unit = "player" }, -- Pain Suppression
        { spell = 41635, type = "buff", unit = "player" }, -- Prayer of Mending
        { spell = 47585, type = "buff", unit = "player" }, -- Dispersion
        { spell = 47753, type = "buff", unit = "player" }, -- Divine Aegis
        { spell = 47788, type = "buff", unit = "player" }, -- Guardian Spirit
        { spell = 49868, type = "buff", unit = "player" }, -- Mind Quickening
        { spell = 59889, type = "buff", unit = "player" }, -- Borrowed Time
        { spell = 63735, type = "buff", unit = "player" }, -- Serendipity
        { spell = 64843, type = "buff", unit = "player" }, -- Divine Hymn
        { spell = 64901, type = "buff", unit = "player" }, -- Hymn of Hope
        { spell = 65081, type = "buff", unit = "player", talent = 4 }, -- Body and Soul
        { spell = 73413, type = "buff", unit = "player" }, -- Inner Will
        { spell = 77489, type = "buff", unit = "player" }, -- Echo of Light
        { spell = 77613, type = "buff", unit = "player" }, -- Grace
        { spell = 81206, type = "buff", unit = "player" }, -- Chakra: Sanctuary
        { spell = 81208, type = "buff", unit = "player" }, -- Chakra: Serenity
        { spell = 81209, type = "buff", unit = "player" }, -- Chakra: Chastise
        { spell = 81661, type = "buff", unit = "player" }, -- Evangelism
        { spell = 81700, type = "buff", unit = "player" }, -- Archangel
        { spell = 81782, type = "buff", unit = "player" }, -- Power Word: Barrier
        { spell = 88684, type = "buff", unit = "player" }, -- Holy Word: Serenity
        { spell = 89485, type = "buff", unit = "player" }, -- Inner Focus
        { spell = 109964, type = "buff", unit = "player" }, -- Spirit Shell
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 114239, type = "buff", unit = "player", talent = 6 }, -- Phantasm
        { spell = 114255, type = "buff", unit = "player" }, -- Surge of Light
        { spell = 119032, type = "buff", unit = "player", talent = 11 }, -- Spectral Guise
        { spell = 121557, type = "buff", unit = "player", talent = 5 }, -- Angelic Feather
        { spell = 124430, type = "buff", unit = "player", talent = 15 }, -- Divine Insight
        { spell = 63619, type = "buff", unit = "pet" }, -- Shadowcrawl
      },
      icon = 135940
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 2096, type = "debuff", unit = "target" }, -- Mind Vision
        { spell = 2944, type = "debuff", unit = "target" }, -- Devouring Plague
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 14914, type = "debuff", unit = "target" }, -- Holy Fire
        { spell = 15407, type = "debuff", unit = "target" }, -- Mind Flay
        { spell = 15487, type = "debuff", unit = "target" }, -- Silence
        { spell = 34914, type = "debuff", unit = "target" }, -- Vampiric Touch
        { spell = 48045, type = "debuff", unit = "target" }, -- Mind Sear
        { spell = 64044, type = "debuff", unit = "target" }, -- Psychic Horror
        { spell = 88625, type = "debuff", unit = "target" }, -- Holy Word: Chastise
        { spell = 129197, type = "debuff", unit = "target" }, -- Mind Flay (Insanity)
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability", buff = true, usable = true }, -- Power Word: Shield
        { spell = 527, type = "ability" }, -- Purify
        { spell = 528, type = "ability", requiresTarget = true }, -- Dispel Magic
        { spell = 585, type = "ability", requiresTarget = true }, -- Smite
        { spell = 586, type = "ability", buff = true }, -- Fade
        { spell = 589, type = "ability", debuff = true, requiresTarget = true }, -- Shadow Word: Pain
        { spell = 2944, type = "ability", debuff = true, requiresTarget = true }, -- Devouring Plague
        { spell = 5019, type = "ability", requiresTarget = true, usable = true }, -- Shoot
        { spell = 6346, type = "ability", buff = true }, -- Fear Ward
        { spell = 8092, type = "ability", overlayGlow = true, requiresTarget = true }, -- Mind Blast
        { spell = 8122, type = "ability", debuff = true }, -- Psychic Scream
        { spell = 10060, type = "ability", buff = true, talent = 14 }, -- Power Infusion
        { spell = 14914, type = "ability", debuff = true, requiresTarget = true }, -- Holy Fire
        { spell = 15286, type = "ability", buff = true }, -- Vampiric Embrace
        { spell = 15407, type = "ability", debuff = true, requiresTarget = true }, -- Mind Flay
        { spell = 15487, type = "ability", debuff = true, requiresTarget = true }, -- Silence
        { spell = 19236, type = "ability", talent = 10 }, -- Desperate Prayer
        { spell = 32375, type = "ability" }, -- Mass Dispel
        { spell = 32379, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Shadow Word: Death
        { spell = 33076, type = "ability" }, -- Prayer of Mending
        { spell = 33206, type = "ability", buff = true }, -- Pain Suppression
        { spell = 34433, type = "ability", requiresTarget = true }, -- Shadowfiend
        { spell = 34861, type = "ability" }, -- Circle of Healing
        { spell = 34914, type = "ability", debuff = true, requiresTarget = true }, -- Vampiric Touch
        { spell = 47540, type = "ability", requiresTarget = true }, -- Penance
        { spell = 47585, type = "ability", buff = true }, -- Dispersion
        { spell = 47788, type = "ability", buff = true }, -- Guardian Spirit
        { spell = 48045, type = "ability", debuff = true, requiresTarget = true }, -- Mind Sear
        { spell = 62618, type = "ability" }, -- Power Word: Barrier
        { spell = 64044, type = "ability", debuff = true, requiresTarget = true }, -- Psychic Horror
        { spell = 64843, type = "ability", buff = true }, -- Divine Hymn
        { spell = 64901, type = "ability", buff = true }, -- Hymn of Hope
        { spell = 73510, type = "ability", requiresTarget = true }, -- Mind Spike
        { spell = 81700, type = "ability", buff = true, overlayGlow = true, usable = true }, -- Archangel
        { spell = 88625, type = "ability", debuff = true }, -- Holy Word: Chastise
        { spell = 88684, type = "ability", buff = true }, -- Holy Word: Serenity
        { spell = 88685, type = "ability" }, -- Holy Word: Sanctuary
        { spell = 89485, type = "ability", buff = true, usable = true }, -- Inner Focus
        { spell = 108920, type = "ability", talent = 1 }, -- Void Tendrils
        { spell = 108921, type = "ability", talent = 2 }, -- Psyfiend
        { spell = 109964, type = "ability", buff = true }, -- Spirit Shell
        { spell = 110744, type = "ability", talent = 17 }, -- Divine Star
        { spell = 112833, type = "ability", talent = 11 }, -- Spectral Guise
        { spell = 120517, type = "ability", talent = 18 }, -- Halo
        { spell = 120644, type = "ability", talent = 18 }, -- Halo
        { spell = 121135, type = "ability", requiresTarget = true, talent = 16 }, -- Cascade
        { spell = 121536, type = "ability", charges = true, talent = 5 }, -- Angelic Feather
        { spell = 123040, type = "ability", talent = 8 }, -- Mindbender
        { spell = 126135, type = "ability", totem = true }, -- Lightwell
      },
      icon = 136224
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  }
}

templates.class.SHAMAN = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 324, type = "buff", unit = "player" }, -- Lightning Shield
        { spell = 546, type = "buff", unit = "player" }, -- Water Walking
        { spell = 974, type = "buff", unit = "player" }, -- Earth Shield
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 2825, type = "buff", unit = "player" }, -- Bloodlust
        { spell = 8178, type = "buff", unit = "player" }, -- Grounding Totem Effect
        { spell = 16166, type = "buff", unit = "player", talent = 10 }, -- Elemental Mastery
        { spell = 16188, type = "buff", unit = "player", talent = 11 }, -- Ancestral Swiftness
        { spell = 16246, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 16278, type = "buff", unit = "player" }, -- Flurry
        { spell = 30809, type = "buff", unit = "player" }, -- Unleashed Rage
        { spell = 30823, type = "buff", unit = "player" }, -- Shamanistic Rage
        { spell = 51470, type = "buff", unit = "player" }, -- Elemental Oath
        { spell = 51945, type = "buff", unit = "player" }, -- Earthliving
        { spell = 52127, type = "buff", unit = "player" }, -- Water Shield
        { spell = 53390, type = "buff", unit = "player" }, -- Tidal Waves
        { spell = 53817, type = "buff", unit = "player" }, -- Maelstrom Weapon
        { spell = 58875, type = "buff", unit = "player" }, -- Spirit Walk
        { spell = 61295, type = "buff", unit = "player" }, -- Riptide
        { spell = 73681, type = "buff", unit = "player" }, -- Unleash Wind
        { spell = 73683, type = "buff", unit = "player" }, -- Unleash Flame
        { spell = 73920, type = "buff", unit = "player" }, -- Healing Rain
        { spell = 77747, type = "buff", unit = "player" }, -- Burning Wrath
        { spell = 77762, type = "buff", unit = "player" }, -- Lava Surge
        { spell = 79206, type = "buff", unit = "player" }, -- Spiritwalker's Grace
        { spell = 98007, type = "buff", unit = "player" }, -- Spirit Link Totem
        { spell = 105284, type = "buff", unit = "player" }, -- Ancestral Vigor
        { spell = 108271, type = "buff", unit = "player", talent = 3 }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 14 }, -- Ancestral Guidance
        { spell = 114050, type = "buff", unit = "player" }, -- Ascendance
        { spell = 114893, type = "buff", unit = "player" }, -- Stone Bulwark
        { spell = 114896, type = "buff", unit = "player", talent = 6 }, -- Windwalk Totem
        { spell = 116956, type = "buff", unit = "player" }, -- Grace of Air
        { spell = 118474, type = "buff", unit = "player", talent = 16 }, -- Unleashed Fury
        { spell = 118522, type = "buff", unit = "player", talent = 18 }, -- Elemental Blast
        { spell = 120676, type = "buff", unit = "player" }, -- Stormlash Totem
      },
      icon = 135863
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3600, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 8034, type = "debuff", unit = "target" }, -- Frostbrand Attack
        { spell = 8050, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 8056, type = "debuff", unit = "target" }, -- Frost Shock
        { spell = 17364, type = "debuff", unit = "target" }, -- Stormstrike
        { spell = 51490, type = "debuff", unit = "target" }, -- Thunderstorm
        { spell = 61882, type = "debuff", unit = "target" }, -- Earthquake
        { spell = 63685, type = "debuff", unit = "target" }, -- Freeze
        { spell = 64695, type = "debuff", unit = "target" }, -- Earthgrab
        { spell = 73682, type = "debuff", unit = "target" }, -- Unleash Frost
        { spell = 73684, type = "debuff", unit = "target" }, -- Unleash Earth
        { spell = 115798, type = "debuff", unit = "target" }, -- Weakened Blows
        { spell = 118470, type = "debuff", unit = "target", talent = 16 }, -- Unleashed Fury
        { spell = 118905, type = "debuff", unit = "target" }, -- Static Charge
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 370, type = "ability", requiresTarget = true }, -- Purge
        { spell = 403, type = "ability", requiresTarget = true }, -- Lightning Bolt
        { spell = 421, type = "ability", requiresTarget = true }, -- Chain Lightning
        { spell = 556, type = "ability", usable = true }, -- Astral Recall
        { spell = 1535, type = "ability" }, -- Fire Nova
        { spell = 2825, type = "ability", buff = true }, -- Bloodlust
        { spell = 8042, type = "ability", overlayGlow = true, requiresTarget = true }, -- Earth Shock
        { spell = 8050, type = "ability", debuff = true, requiresTarget = true }, -- Flame Shock
        { spell = 8056, type = "ability", debuff = true, requiresTarget = true }, -- Frost Shock
        { spell = 16166, type = "ability", buff = true, talent = 10 }, -- Elemental Mastery
        { spell = 16188, type = "ability", buff = true, talent = 11 }, -- Ancestral Swiftness
        { spell = 17364, type = "ability", debuff = true, requiresTarget = true }, -- Stormstrike
        { spell = 30823, type = "ability", buff = true }, -- Shamanistic Rage
        { spell = 51490, type = "ability", debuff = true }, -- Thunderstorm
        { spell = 51505, type = "ability", overlayGlow = true, requiresTarget = true }, -- Lava Burst
        { spell = 51514, type = "ability", debuff = true }, -- Hex
        { spell = 51533, type = "ability" }, -- Feral Spirit
        { spell = 51886, type = "ability" }, -- Cleanse Spirit
        { spell = 57994, type = "ability", requiresTarget = true }, -- Wind Shear
        { spell = 58875, type = "ability", buff = true }, -- Spirit Walk
        { spell = 60103, type = "ability", requiresTarget = true, usable = true }, -- Lava Lash
        { spell = 61295, type = "ability", buff = true }, -- Riptide
        { spell = 61882, type = "ability", debuff = true }, -- Earthquake
        { spell = 73680, type = "ability", requiresTarget = true }, -- Unleash Elements
        { spell = 73899, type = "ability", requiresTarget = true }, -- Primal Strike
        { spell = 73920, type = "ability", buff = true }, -- Healing Rain
        { spell = 77130, type = "ability" }, -- Purify Spirit
        { spell = 79206, type = "ability", buff = true }, -- Spiritwalker's Grace
        { spell = 107079, type = "ability", requiresTarget = true }, -- Quaking Palm
        { spell = 108271, type = "ability", buff = true, talent = 3 }, -- Astral Shift
        { spell = 108281, type = "ability", buff = true, talent = 14 }, -- Ancestral Guidance
        { spell = 108285, type = "ability", talent = 7 }, -- Call of the Elements
        { spell = 108287, type = "ability", talent = 9 }, -- Totemic Projection
        { spell = 114049, type = "ability", buff = true }, -- Ascendance
        { spell = 117014, type = "ability", talent = 18, requiresTarget = true }, -- Elemental Blast
      },
      icon = 135963
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = 135990,
    },
  }
}

templates.class.MAGE = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 66, type = "buff", unit = "player" }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player" }, -- Arcane Brilliance
        { spell = 1463, type = "buff", unit = "player", talent = 18 }, -- Incanter's Ward
        { spell = 6117, type = "buff", unit = "player" }, -- Mage Armor
        { spell = 7302, type = "buff", unit = "player" }, -- Frost Armor
        { spell = 11426, type = "buff", unit = "player", talent = 6 }, -- Ice Barrier
        { spell = 12042, type = "buff", unit = "player" }, -- Arcane Power
        { spell = 12043, type = "buff", unit = "player", talent = 1 }, -- Presence of Mind
        { spell = 12051, type = "buff", unit = "player" }, -- Evocation
        { spell = 12472, type = "buff", unit = "player" }, -- Icy Veins
        { spell = 30482, type = "buff", unit = "player" }, -- Molten Armor
        { spell = 44544, type = "buff", unit = "player" }, -- Fingers of Frost
        { spell = 45438, type = "buff", unit = "player" }, -- Ice Block
        { spell = 48107, type = "buff", unit = "player" }, -- Heating Up
        { spell = 48108, type = "buff", unit = "player" }, -- Pyroblast!
        { spell = 57761, type = "buff", unit = "player" }, -- Brain Freeze
        { spell = 79683, type = "buff", unit = "player" }, -- Arcane Missiles!
        { spell = 80353, type = "buff", unit = "player" }, -- Time Warp
        { spell = 108839, type = "buff", unit = "player", talent = 3 }, -- Ice Floes
        { spell = 108843, type = "buff", unit = "player", talent = 2 }, -- Blazing Speed
        { spell = 110909, type = "buff", unit = "player" }, -- Alter Time
        { spell = 110960, type = "buff", unit = "player", talent = 10 }, -- Greater Invisibility
        { spell = 111264, type = "buff", unit = "player", talent = 8 }, -- Ice Ward
        { spell = 115610, type = "buff", unit = "player", talent = 4 }, -- Temporal Shield
        { spell = 116014, type = "buff", unit = "player", talent = 17 }, -- Rune of Power
        { spell = 116257, type = "buff", unit = "player" }, -- Invoker's Energy
        { spell = 126476, type = "buff", unit = "player" }, -- Predation
      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 120, type = "debuff", unit = "target" }, -- Cone of Cold
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 2120, type = "debuff", unit = "target" }, -- Flamestrike
        { spell = 11113, type = "debuff", unit = "target" }, -- Blast Wave
        { spell = 11366, type = "debuff", unit = "target" }, -- Pyroblast
        { spell = 12486, type = "debuff", unit = "target" }, -- Chilled
        { spell = 31589, type = "debuff", unit = "target" }, -- Slow
        { spell = 31661, type = "debuff", unit = "target" }, -- Dragon's Breath
        { spell = 33395, type = "debuff", unit = "target" }, -- Freeze
        { spell = 44457, type = "debuff", unit = "target", talent = 14 }, -- Living Bomb
        { spell = 44572, type = "debuff", unit = "target" }, -- Deep Freeze
        { spell = 44614, type = "debuff", unit = "target" }, -- Frostfire Bolt
        { spell = 55021, type = "debuff", unit = "target" }, -- Silenced - Improved Counterspell
        { spell = 59638, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 83853, type = "debuff", unit = "target" }, -- Combustion
        { spell = 84721, type = "debuff", unit = "target" }, -- Frozen Orb
        { spell = 102051, type = "debuff", unit = "target", talent = 9 }, -- Frostjaw
        { spell = 112948, type = "debuff", unit = "target", talent = 15 }, -- Frost Bomb
        { spell = 114923, type = "debuff", unit = "target", talent = 13 }, -- Nether Tempest
        { spell = 118271, type = "debuff", unit = "target" }, -- Combustion Impact
        { spell = 132210, type = "debuff", unit = "target" }, -- Pyromaniac
        { spell = 413841, type = "debuff", unit = "target" }, -- Ignite
      },
      icon = 135848
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability", buff = true }, -- Invisibility
        { spell = 116, type = "ability", requiresTarget = true }, -- Frostbolt
        { spell = 120, type = "ability", debuff = true }, -- Cone of Cold
        { spell = 122, type = "ability", debuff = true }, -- Frost Nova
        { spell = 475, type = "ability" }, -- Remove Curse
        { spell = 1463, type = "ability", buff = true, talent = 18 }, -- Incanter's Ward
        { spell = 1953, type = "ability" }, -- Blink
        { spell = 2120, type = "ability", debuff = true }, -- Flamestrike
        { spell = 2136, type = "ability", requiresTarget = true }, -- Fire Blast
        { spell = 2139, type = "ability", requiresTarget = true }, -- Counterspell
        { spell = 5019, type = "ability", requiresTarget = true, usable = true }, -- Shoot
        { spell = 5143, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Arcane Missiles
        { spell = 11129, type = "ability" }, -- Combustion
        { spell = 11426, type = "ability", buff = true, talent = 6 }, -- Ice Barrier
        { spell = 11958, type = "ability", talent = 12 }, -- Cold Snap
        { spell = 12042, type = "ability", buff = true }, -- Arcane Power
        { spell = 12043, type = "ability", buff = true, usable = true, talent = 1 }, -- Presence of Mind
        { spell = 12051, type = "ability", buff = true }, -- Evocation
        { spell = 12472, type = "ability", buff = true }, -- Icy Veins
        { spell = 30449, type = "ability", requiresTarget = true }, -- Spellsteal
        { spell = 30451, type = "ability", requiresTarget = true }, -- Arcane Blast
        { spell = 30455, type = "ability", charges = true, overlayGlow = true, requiresTarget = true }, -- Ice Lance
        { spell = 31589, type = "ability", debuff = true, requiresTarget = true }, -- Slow
        { spell = 31661, type = "ability", debuff = true }, -- Dragon's Breath
        { spell = 31687, type = "ability" }, -- Summon Water Elemental
        { spell = 31707, type = "ability" }, -- Waterbolt
        { spell = 33395, type = "ability", debuff = true }, -- Freeze
        { spell = 43987, type = "ability" }, -- Conjure Refreshment Table
        { spell = 44425, type = "ability", requiresTarget = true }, -- Arcane Barrage
        { spell = 44572, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Deep Freeze
        { spell = 44614, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Frostfire Bolt
        { spell = 45438, type = "ability", buff = true, usable = true }, -- Ice Block
        { spell = 55342, type = "ability" }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true }, -- Time Warp
        { spell = 84714, type = "ability" }, -- Frozen Orb
        { spell = 102051, type = "ability", debuff = true, requiresTarget = true, talent = 9 }, -- Frostjaw
        { spell = 108839, type = "ability", charges = true, buff = true, talent = 3 }, -- Ice Floes
        { spell = 108843, type = "ability", buff = true, usable = true, talent = 2 }, -- Blazing Speed
        { spell = 108853, type = "ability" }, -- Inferno Blast
        { spell = 108978, type = "ability" }, -- Alter Time
        { spell = 110959, type = "ability", talent = 10 }, -- Greater Invisibility
        { spell = 111264, type = "ability", buff = true, talent = 8 }, -- Ice Ward
        { spell = 112948, type = "ability", debuff = true, requiresTarget = true, talent = 15 }, -- Frost Bomb
        { spell = 113724, type = "ability", talent = 7 }, -- Ring of Frost
        { spell = 114923, type = "ability", debuff = true, requiresTarget = true, talent = 13 }, -- Nether Tempest
        { spell = 115610, type = "ability", buff = true, talent = 4 }, -- Temporal Shield
        { spell = 127140, type = "ability" }, -- Alter Time
        { spell = 140376, type = "ability", talent = 7 }, -- Ring of Frost
      },
      icon = 136075
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  }
}

templates.class.WARLOCK = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 126, type = "buff", unit = "player" }, -- Eye of Kilrogg
        { spell = 1949, type = "buff", unit = "player" }, -- Hellfire
        { spell = 5697, type = "buff", unit = "player" }, -- Unending Breath
        { spell = 6229, type = "buff", unit = "player" }, -- Twilight Ward
        { spell = 17941, type = "buff", unit = "player" }, -- Shadow Trance
        { spell = 20707, type = "buff", unit = "player" }, -- Soulstone
        { spell = 48018, type = "buff", unit = "player" }, -- Demonic Circle: Summon
        { spell = 59752, type = "buff", unit = "player" }, -- Will to Survive
        { spell = 74434, type = "buff", unit = "player" }, -- Soulburn
        { spell = 80240, type = "buff", unit = "player" }, -- Havoc
        { spell = 86211, type = "buff", unit = "player" }, -- Soul Swap
        { spell = 103958, type = "buff", unit = "player" }, -- Metamorphosis
        { spell = 104232, type = "buff", unit = "player" }, -- Rain of Fire
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108359, type = "buff", unit = "player", talent = 1 }, -- Dark Regeneration
        { spell = 108416, type = "buff", unit = "player", talent = 8 }, -- Sacrificial Pact
        { spell = 108503, type = "buff", unit = "player", talent = 15 }, -- Grimoire of Sacrifice
        { spell = 108508, type = "buff", unit = "player", talent = 18 }, -- Mannoroth's Fury
        { spell = 109773, type = "buff", unit = "player" }, -- Dark Intent
        { spell = 110913, type = "buff", unit = "player", talent = 9 }, -- Dark Bargain
        { spell = 111397, type = "buff", unit = "player", talent = 10 }, -- Blood Horror
        { spell = 111400, type = "buff", unit = "player", talent = 11 }, -- Burning Rush
        { spell = 113858, type = "buff", unit = "player" }, -- Dark Soul: Instability
        { spell = 113860, type = "buff", unit = "player" }, -- Dark Soul: Misery
        { spell = 113861, type = "buff", unit = "player" }, -- Dark Soul: Knowledge
        { spell = 114925, type = "buff", unit = "player" }, -- Demonic Calling
        { spell = 117828, type = "buff", unit = "player" }, -- Backdraft
        { spell = 119899, type = "buff", unit = "player" }, -- Cauterize Master
        { spell = 122355, type = "buff", unit = "player" }, -- Molten Core
        { spell = 126476, type = "buff", unit = "player" }, -- Predation
        { spell = 30151, type = "buff", unit = "pet" }, -- Pursuit
        { spell = 89751, type = "buff", unit = "pet" }, -- Felstorm
        { spell = 134477, type = "buff", unit = "pet" }, -- Threatening Presence
      },
      icon = 136210
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 348, type = "debuff", unit = "target" }, -- Immolate
        { spell = 689, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 980, type = "debuff", unit = "target" }, -- Agony
        { spell = 1120, type = "debuff", unit = "target" }, -- Drain Soul
        { spell = 1490, type = "debuff", unit = "target" }, -- Curse of the Elements
        { spell = 5484, type = "debuff", unit = "target" }, -- Howl of Terror
        { spell = 6789, type = "debuff", unit = "target", talent = 5 }, -- Mortal Coil
        { spell = 17962, type = "debuff", unit = "target" }, -- Conflagrate
        { spell = 18223, type = "debuff", unit = "target" }, -- Curse of Exhaustion
        { spell = 22703, type = "debuff", unit = "target" }, -- Infernal Awakening
        { spell = 27243, type = "debuff", unit = "target" }, -- Seed of Corruption
        { spell = 30108, type = "debuff", unit = "target" }, -- Unstable Affliction
        { spell = 30213, type = "debuff", unit = "target" }, -- Legion Strike
        { spell = 30283, type = "debuff", unit = "target", talent = 6 }, -- Shadowfury
        { spell = 47960, type = "debuff", unit = "target" }, -- Shadowflame
        { spell = 48181, type = "debuff", unit = "target" }, -- Haunt
        { spell = 60947, type = "debuff", unit = "target" }, -- Nightmare
        { spell = 103103, type = "debuff", unit = "target" }, -- Malefic Grasp
        { spell = 109466, type = "debuff", unit = "target" }, -- Curse of Enfeeblement
        { spell = 116858, type = "debuff", unit = "target" }, -- Chaos Bolt
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
      },
      icon = 136139
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 172, type = "ability", requiresTarget = true }, -- Corruption
        { spell = 686, type = "ability", requiresTarget = true }, -- Shadow Bolt
        { spell = 689, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Drain Life
        { spell = 698, type = "ability", usable = true }, -- Ritual of Summoning
        { spell = 980, type = "ability", debuff = true, requiresTarget = true }, -- Agony
        { spell = 1120, type = "ability", debuff = true, requiresTarget = true }, -- Drain Soul
        { spell = 1122, type = "ability" }, -- Summon Infernal
        { spell = 1490, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Curse of the Elements
        { spell = 5019, type = "ability", requiresTarget = true, usable = true }, -- Shoot
        { spell = 5484, type = "ability", debuff = true }, -- Howl of Terror
        { spell = 5782, type = "ability", requiresTarget = true }, -- Fear
        { spell = 6229, type = "ability", buff = true }, -- Twilight Ward
        { spell = 6353, type = "ability", charges = true, overlayGlow = true }, -- Soul Fire
        { spell = 6789, type = "ability", debuff = true, requiresTarget = true, talent = 5 }, -- Mortal Coil
        { spell = 17962, type = "ability", charges = true, debuff = true }, -- Conflagrate
        { spell = 18223, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Curse of Exhaustion
        { spell = 18540, type = "ability", requiresTarget = true }, -- Summon Doomguard
        { spell = 20707, type = "ability", buff = true }, -- Soulstone
        { spell = 27243, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Seed of Corruption
        { spell = 29858, type = "ability" }, -- Soulshatter
        { spell = 29893, type = "ability" }, -- Create Soulwell
        { spell = 30108, type = "ability", debuff = true, requiresTarget = true }, -- Unstable Affliction
        { spell = 30151, type = "ability", buff = true, unit = 'pet' }, -- Pursuit
        { spell = 30213, type = "ability", debuff = true }, -- Legion Strike
        { spell = 30283, type = "ability", debuff = true, talent = 6 }, -- Shadowfury
        { spell = 47897, type = "ability", talent = 4 }, -- Demonic Breath
        { spell = 48020, type = "ability", overlayGlow = true, usable = true }, -- Demonic Circle: Teleport
        { spell = 48181, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Haunt
        { spell = 59752, type = "ability", buff = true }, -- Will to Survive
        { spell = 74434, type = "ability", buff = true }, -- Soulburn
        { spell = 77799, type = "ability", requiresTarget = true }, -- Fel Flame
        { spell = 80240, type = "ability", buff = true, debuff = true }, -- Havoc
        { spell = 86121, type = "ability", overlayGlow = true, requiresTarget = true }, -- Soul Swap
        { spell = 89751, type = "ability", buff = true, unit = 'pet' }, -- Felstorm
        { spell = 103103, type = "ability", debuff = true, requiresTarget = true }, -- Malefic Grasp
        { spell = 103958, type = "ability", buff = true }, -- Metamorphosis
        { spell = 103967, type = "ability", usable = true }, -- Carrion Swarm
        { spell = 104027, type = "ability", charges = true, overlayGlow = true }, -- Soul Fire
        { spell = 104136, type = "ability" }, -- Demonic Circle: Teleport
        { spell = 104773, type = "ability", buff = true }, -- Unending Resolve
        { spell = 105174, type = "ability", charges = true }, -- Hand of Gul'dan
        { spell = 108359, type = "ability", buff = true, talent = 1 }, -- Dark Regeneration
        { spell = 108416, type = "ability", buff = true, talent = 8 }, -- Sacrificial Pact
        { spell = 108482, type = "ability", talent = 12 }, -- Unbound Will
        { spell = 108503, type = "ability", buff = true, talent = 15 }, -- Grimoire of Sacrifice
        { spell = 108508, type = "ability", buff = true, talent = 18 }, -- Mannoroth's Fury
        { spell = 109151, type = "ability" }, -- Demonic Leap
        { spell = 109466, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Curse of Enfeeblement
        { spell = 110913, type = "ability", buff = true, talent = 9 }, -- Dark Bargain
        { spell = 111397, type = "ability", buff = true, talent = 10 }, -- Blood Horror
        { spell = 111771, type = "ability" }, -- Demonic Gateway
        { spell = 112921, type = "ability" }, -- Summon Abyssal
        { spell = 112927, type = "ability" }, -- Summon Terrorguard
        { spell = 113858, type = "ability", buff = true }, -- Dark Soul: Instability
        { spell = 113860, type = "ability", charges = true, buff = true }, -- Dark Soul: Misery
        { spell = 113861, type = "ability", buff = true }, -- Dark Soul: Knowledge
        { spell = 114794, type = "ability", overlayGlow = true }, -- Demonic Circle: Teleport
        { spell = 115746, type = "ability" }, -- Felbolt
        { spell = 119899, type = "ability", buff = true }, -- Cauterize Master
        { spell = 119905, type = "ability" }, -- Cauterize Master
        { spell = 119914, type = "ability" }, -- Felstorm
        { spell = 124916, type = "ability", charges = true }, -- Chaos Waves
        { spell = 132411, type = "ability" }, -- Singe Magic
        { spell = 134477, type = "ability", buff = true, unit = 'pet' }, -- Threatening Presence
      },
      icon = 135808
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
    },
  }
}

templates.class.DRUID = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 768, type = "buff", unit = "player" }, -- Cat Form
        { spell = 774, type = "buff", unit = "player" }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player" }, -- Travel Form
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 5217, type = "buff", unit = "player" }, -- Tiger's Fury
        { spell = 5229, type = "buff", unit = "player" }, -- Enrage
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 16689, type = "buff", unit = "player" }, -- Nature's Grasp
        { spell = 16886, type = "buff", unit = "player" }, -- Nature's Grace
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 24858, type = "buff", unit = "player" }, -- Moonkin Form
        { spell = 24907, type = "buff", unit = "player" }, -- Moonkin Aura
        { spell = 24932, type = "buff", unit = "player" }, -- Leader of the Pack
        { spell = 29166, type = "buff", unit = "player" }, -- Innervate
        { spell = 33763, type = "buff", unit = "player" }, -- Lifebloom
        { spell = 33891, type = "buff", unit = "player" }, -- Incarnation: Tree of Life
        { spell = 40120, type = "buff", unit = "player" }, -- Swift Flight Form
        { spell = 44203, type = "buff", unit = "player" }, -- Tranquility
        { spell = 48438, type = "buff", unit = "player" }, -- Wild Growth
        { spell = 48504, type = "buff", unit = "player" }, -- Living Seed
        { spell = 48505, type = "buff", unit = "player" }, -- Starfall
        { spell = 48518, type = "buff", unit = "player" }, -- Eclipse (Lunar)
        { spell = 50334, type = "buff", unit = "player" }, -- Berserk
        { spell = 52610, type = "buff", unit = "player" }, -- Savage Roar
        { spell = 61336, type = "buff", unit = "player" }, -- Survival Instincts
        { spell = 69369, type = "buff", unit = "player" }, -- Predatory Swiftness
        { spell = 77761, type = "buff", unit = "player" }, -- Stampeding Roar
        { spell = 81192, type = "buff", unit = "player" }, -- Lunar Shower
        { spell = 93400, type = "buff", unit = "player" }, -- Shooting Stars
        { spell = 100977, type = "buff", unit = "player" }, -- Harmony
        { spell = 102342, type = "buff", unit = "player" }, -- Ironbark
        { spell = 102351, type = "buff", unit = "player", talent = 6 }, -- Cenarion Ward
        { spell = 102543, type = "buff", unit = "player" }, -- Incarnation: King of the Jungle
        { spell = 106922, type = "buff", unit = "player" }, -- Might of Ursoc
        { spell = 108291, type = "buff", unit = "player", talent = 16 }, -- Heart of the Wild
        { spell = 112071, type = "buff", unit = "player" }, -- Celestial Alignment
        { spell = 117679, type = "buff", unit = "player", talent = 11 }, -- Incarnation
        { spell = 124974, type = "buff", unit = "player", talent = 18 }, -- Nature's Vigil
        { spell = 127663, type = "buff", unit = "player" }, -- Astral Communion
        { spell = 132158, type = "buff", unit = "player" }, -- Nature's Swiftness
        { spell = 132402, type = "buff", unit = "player" }, -- Savage Defense
        { spell = 135286, type = "buff", unit = "player" }, -- Tooth and Claw
        { spell = 135700, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 137452, type = "buff", unit = "player", talent = 2 }, -- Displacer Beast
        { spell = 145138, type = "buff", unit = "player" }, -- Astral Insight
      },
      icon = 136097
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target", talent = 13 }, -- Disorienting Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 770, type = "debuff", unit = "target" }, -- Faerie Fire
        { spell = 1079, type = "debuff", unit = "target" }, -- Rip
        { spell = 1822, type = "debuff", unit = "target" }, -- Rake
        { spell = 5211, type = "debuff", unit = "target", talent = 15 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 8921, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 9005, type = "debuff", unit = "target" }, -- Pounce
        { spell = 9007, type = "debuff", unit = "target" }, -- Pounce Bleed
        { spell = 16914, type = "debuff", unit = "target" }, -- Hurricane
        { spell = 22570, type = "debuff", unit = "target" }, -- Maim
        { spell = 33745, type = "debuff", unit = "target" }, -- Lacerate
        { spell = 45334, type = "debuff", unit = "target" }, -- Immobilized
        { spell = 58180, type = "debuff", unit = "target" }, -- Infected Wounds
        { spell = 61391, type = "debuff", unit = "target", talent = 9 }, -- Typhoon
        { spell = 77758, type = "debuff", unit = "target" }, -- Thrash
        { spell = 81261, type = "debuff", unit = "target" }, -- Solar Beam
        { spell = 81281, type = "debuff", unit = "target" }, -- Fungal Growth
        { spell = 93402, type = "debuff", unit = "target" }, -- Sunfire
        { spell = 102355, type = "debuff", unit = "target", talent = 7 }, -- Faerie Swarm
        { spell = 102359, type = "debuff", unit = "target", talent = 8 }, -- Mass Entanglement
        { spell = 102795, type = "debuff", unit = "target" }, -- Bear Hug
        { spell = 106996, type = "debuff", unit = "target" }, -- Astral Storm
        { spell = 113746, type = "debuff", unit = "target" }, -- Weakened Armor
        { spell = 113830, type = "debuff", unit = "target" }, -- Taunt
        { spell = 115798, type = "debuff", unit = "target" }, -- Weakened Blows
        { spell = 127797, type = "debuff", unit = "target", talent = 14 }, -- Ursol's Vortex
        { spell = 135601, type = "debuff", unit = "target" }, -- Tooth and Claw
      },
      icon = 132114
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", debuff = true, talent = 13 }, -- Disorienting Roar
        { spell = 339, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Entangling Roots
        { spell = 740, type = "ability", usable = true }, -- Tranquility
        { spell = 770, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Faerie Fire
        { spell = 779, type = "ability" }, -- Swipe
        { spell = 1079, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Rip
        { spell = 1822, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Rake
        { spell = 1850, type = "ability", buff = true, usable = true }, -- Dash
        { spell = 2782, type = "ability", usable = true }, -- Remove Corruption
        { spell = 5211, type = "ability", debuff = true, requiresTarget = true, talent = 15 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true, usable = true }, -- Prowl
        { spell = 5217, type = "ability", buff = true }, -- Tiger's Fury
        { spell = 5221, type = "ability", requiresTarget = true, usable = true }, -- Shred
        { spell = 5225, type = "ability", usable = true }, -- Track Humanoids
        { spell = 5229, type = "ability", buff = true }, -- Enrage
        { spell = 6785, type = "ability", requiresTarget = true, usable = true }, -- Ravage
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Growl
        { spell = 6807, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Maul
        { spell = 9005, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Pounce
        { spell = 16689, type = "ability", buff = true, usable = true }, -- Nature's Grasp
        { spell = 16979, type = "ability", talent = 3 }, -- Wild Charge
        { spell = 18562, type = "ability", usable = true }, -- Swiftmend
        { spell = 20484, type = "ability", usable = true }, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true, usable = true }, -- Ferocious Bite
        { spell = 22570, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Maim
        { spell = 22812, type = "ability", buff = true, usable = true }, -- Barkskin
        { spell = 22842, type = "ability", usable = true }, -- Frenzied Regeneration
        { spell = 29166, type = "ability", buff = true, usable = true }, -- Innervate
        { spell = 33745, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Lacerate
        { spell = 33786, type = "ability", requiresTarget = true, usable = true }, -- Cyclone
        { spell = 33878, type = "ability", overlayGlow = true, requiresTarget = true }, -- Mangle
        { spell = 33891, type = "ability", buff = true }, -- Incarnation: Tree of Life
        { spell = 33917, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Mangle
        { spell = 48438, type = "ability", buff = true, overlayGlow = true }, -- Wild Growth
        { spell = 48505, type = "ability", buff = true, overlayGlow = true, usable = true }, -- Starfall
        { spell = 50334, type = "ability", buff = true }, -- Berserk
        { spell = 61336, type = "ability", buff = true }, -- Survival Instincts
        { spell = 62606, type = "ability", charges = true, usable = true }, -- Savage Defense
        { spell = 77758, type = "ability", debuff = true, requiresTarget = true }, -- Thrash
        { spell = 77761, type = "ability", buff = true }, -- Stampeding Roar
        { spell = 77764, type = "ability" }, -- Stampeding Roar
        { spell = 78674, type = "ability", overlayGlow = true, usable = true }, -- Starsurge
        { spell = 78675, type = "ability", usable = true }, -- Solar Beam
        { spell = 88423, type = "ability" }, -- Nature's Cure
        { spell = 88751, type = "ability", usable = true }, -- Wild Mushroom: Detonate
        { spell = 102280, type = "ability", talent = 2 }, -- Displacer Beast
        { spell = 102342, type = "ability", buff = true }, -- Ironbark
        { spell = 102351, type = "ability", buff = true, talent = 6 }, -- Cenarion Ward
        { spell = 102359, type = "ability", debuff = true, usable = true, talent = 8 }, -- Mass Entanglement
        { spell = 102401, type = "ability", requiresTarget = true, usable = true, talent = 3 }, -- Wild Charge
        { spell = 102543, type = "ability", buff = true }, -- Incarnation: King of the Jungle
        { spell = 102547, type = "ability", buff = true }, -- Prowl
        { spell = 102791, type = "ability" }, -- Wild Mushroom: Bloom
        { spell = 102793, type = "ability", talent = 14 }, -- Ursol's Vortex
        { spell = 102795, type = "ability", debuff = true, requiresTarget = true }, -- Bear Hug
        { spell = 106737, type = "ability", charges = true, talent = 12 }, -- Force of Nature
        { spell = 106832, type = "ability", requiresTarget = true, usable = true }, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true, usable = true }, -- Skull Bash
        { spell = 106898, type = "ability", buff = true, usable = true }, -- Stampeding Roar
        { spell = 106922, type = "ability", buff = true }, -- Ursocs Macht
        { spell = 106951, type = "ability" }, -- Berserk
        { spell = 106952, type = "ability", usable = true }, -- Berserk
        { spell = 108238, type = "ability", usable = true, talent = 5 }, -- Renewal
        { spell = 108291, type = "ability", buff = true, talent = 16 }, -- Heart of the Wild
        { spell = 110309, type = "ability", usable = true }, -- Symbiosis
        { spell = 112071, type = "ability", buff = true, usable = true }, -- Celestial Alignment
        { spell = 124974, type = "ability", buff = true, talent = 18 }, -- Nature's Vigil
        { spell = 132158, type = "ability", buff = true, usable = true }, -- Nature's Swiftness
        { spell = 132469, type = "ability", talent = 9 }, -- Typhoon
        { spell = 145205, type = "ability", totem = true }, -- Wild Mushroom
      },
      icon = 132134
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources and Shapeshift Form"],
      args = {
      },
      icon = manaIcon,
    },
  },
}

templates.class.DEATHKNIGHT = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 3714, type = "buff", unit = "player" }, -- Path of Frost
        { spell = 42650, type = "buff", unit = "player" }, -- Army of the Dead
        { spell = 48263, type = "buff", unit = "player" }, -- Blood Presence
        { spell = 48265, type = "buff", unit = "player" }, -- Unholy Presence
        { spell = 48266, type = "buff", unit = "player" }, -- Frost Presence
        { spell = 48707, type = "buff", unit = "player" }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player" }, -- Icebound Fortitude
        { spell = 49016, type = "buff", unit = "player" }, -- Unholy Frenzy
        { spell = 49039, type = "buff", unit = "player", talent = 4 }, -- Lichborne
        { spell = 49222, type = "buff", unit = "player" }, -- Bone Shield
        { spell = 50421, type = "buff", unit = "player" }, -- Scent of Blood
        { spell = 51124, type = "buff", unit = "player" }, -- Killing Machine
        { spell = 51271, type = "buff", unit = "player" }, -- Pillar of Frost
        { spell = 51460, type = "buff", unit = "player", talent = 15 }, -- Runic Corruption
        { spell = 51721, type = "buff", unit = "player" }, -- Dominion Over Acherus
        { spell = 55233, type = "buff", unit = "player" }, -- Vampiric Blood
        { spell = 55610, type = "buff", unit = "player" }, -- Unholy Aura
        { spell = 57330, type = "buff", unit = "player" }, -- Horn of Winter
        { spell = 59052, type = "buff", unit = "player" }, -- Freezing Fog
        { spell = 81141, type = "buff", unit = "player" }, -- Crimson Scourge
        { spell = 81256, type = "buff", unit = "player" }, -- Dancing Rune Weapon
        { spell = 81340, type = "buff", unit = "player" }, -- Sudden Doom
        { spell = 91342, type = "buff", unit = "player" }, -- Shadow Infusion
        { spell = 96268, type = "buff", unit = "player", talent = 7 }, -- Death's Advance
        { spell = 108200, type = "buff", unit = "player", talent = 17 }, -- Remorseless Winter
        { spell = 114851, type = "buff", unit = "player" }, -- Blood Charge
        { spell = 115018, type = "buff", unit = "player", talent = 18 }, -- Desecrated Ground
        { spell = 115989, type = "buff", unit = "player", talent = 3 }, -- Unholy Blight
        { spell = 119975, type = "buff", unit = "player", talent = 12 }, -- Conversion
        { spell = 126513, type = "buff", unit = "player" }, -- Poised to Strike
        { spell = 145629, type = "buff", unit = "player", talent = 5 }, -- Anti-Magic Zone
        { spell = 63560, type = "buff", unit = "pet" }, -- Dark Transformation
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 43265, type = "debuff", unit = "target" }, -- Death and Decay
        { spell = 49206, type = "debuff", unit = "target" }, -- Summon Gargoyle
        { spell = 55078, type = "debuff", unit = "target" }, -- Blood Plague
        { spell = 55095, type = "debuff", unit = "target" }, -- Frost Fever
        { spell = 73975, type = "debuff", unit = "target" }, -- Necrotic Strike
        { spell = 77606, type = "debuff", unit = "target" }, -- Dark Simulacrum
        { spell = 81326, type = "debuff", unit = "target" }, -- Physical Vulnerability
        { spell = 114866, type = "debuff", unit = "target" }, -- Soul Reaper
        { spell = 115798, type = "debuff", unit = "target" }, -- Weakened Blows
      },
      icon = 237514
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability", buff = true }, -- Path of Frost
        { spell = 42650, type = "ability", buff = true }, -- Army of the Dead
        { spell = 43265, type = "ability", debuff = true, overlayGlow = true }, -- Death and Decay
        { spell = 45462, type = "ability", requiresTarget = true }, -- Plague Strike
        { spell = 45477, type = "ability", overlayGlow = true }, -- Icy Touch
        { spell = 45524, type = "ability" }, -- Chains of Ice
        { spell = 45529, type = "ability", charges = true, talent = 13 }, -- Blood Tap
        { spell = 45902, type = "ability", requiresTarget = true }, -- Blood Strike
        { spell = 46584, type = "ability", totem = true }, -- Raise Dead
        { spell = 47468, type = "ability" }, -- Claw
        { spell = 47476, type = "ability" }, -- Strangulate
        { spell = 47481, type = "ability" }, -- Gnaw
        { spell = 47484, type = "ability" }, -- Huddle
        { spell = 47528, type = "ability", requiresTarget = true }, -- Mind Freeze
        { spell = 47568, type = "ability" }, -- Empower Rune Weapon
        { spell = 48707, type = "ability", buff = true }, -- Anti-Magic Shell
        { spell = 48721, type = "ability", overlayGlow = true }, -- Blood Boil
        { spell = 48743, type = "ability", talent = 10 }, -- Death Pact
        { spell = 48792, type = "ability", buff = true }, -- Icebound Fortitude
        { spell = 48982, type = "ability" }, -- Rune Tap
        { spell = 49016, type = "ability", buff = true }, -- Unholy Frenzy
        { spell = 49020, type = "ability", overlayGlow = true, requiresTarget = true }, -- Obliterate
        { spell = 49028, type = "ability" }, -- Dancing Rune Weapon
        { spell = 49039, type = "ability", buff = true, talent = 4 }, -- Lichborne
        { spell = 49143, type = "ability", overlayGlow = true, requiresTarget = true }, -- Frost Strike
        { spell = 49184, type = "ability", overlayGlow = true }, -- Howling Blast
        { spell = 49206, type = "ability", debuff = true }, -- Summon Gargoyle
        { spell = 49222, type = "ability", buff = true }, -- Bone Shield
        { spell = 49576, type = "ability" }, -- Death Grip
        { spell = 49998, type = "ability", charges = true, requiresTarget = true }, -- Death Strike
        { spell = 50842, type = "ability", requiresTarget = true }, -- Pestilence
        { spell = 50977, type = "ability", usable = true }, -- Death Gate
        { spell = 51052, type = "ability", talent = 5 }, -- Anti-Magic Zone
        { spell = 51271, type = "ability", buff = true }, -- Pillar of Frost
        { spell = 55050, type = "ability", requiresTarget = true }, -- Heart Strike
        { spell = 55090, type = "ability", requiresTarget = true }, -- Scourge Strike
        { spell = 55233, type = "ability", buff = true }, -- Vampiric Blood
        { spell = 56222, type = "ability" }, -- Dark Command
        { spell = 56815, type = "ability", requiresTarget = true }, -- Rune Strike
        { spell = 57330, type = "ability", buff = true }, -- Horn of Winter
        { spell = 61999, type = "ability" }, -- Raise Ally
        { spell = 63560, type = "ability", charges = true, buff = true, unit = 'pet', overlayGlow = true, usable = true }, -- Dark Transformation
        { spell = 73975, type = "ability", debuff = true, requiresTarget = true }, -- Necrotic Strike
        { spell = 77575, type = "ability" }, -- Outbreak
        { spell = 77606, type = "ability", debuff = true }, -- Dark Simulacrum
        { spell = 85948, type = "ability", requiresTarget = true }, -- Festering Strike
        { spell = 96268, type = "ability", buff = true, talent = 7 }, -- Death's Advance
        { spell = 108194, type = "ability", talent = 9 }, -- Asphyxiate
        { spell = 108199, type = "ability", talent = 16 }, -- Gorefiend's Grasp
        { spell = 108200, type = "ability", buff = true, talent = 17 }, -- Remorseless Winter
        { spell = 108201, type = "ability", talent = 18 }, -- Desecrated Ground
        { spell = 111673, type = "ability" }, -- Control Undead
        { spell = 114866, type = "ability", debuff = true, requiresTarget = true }, -- Soul Reaper
        { spell = 115989, type = "ability", buff = true, talent = 3 }, -- Unholy Blight
        { spell = 123693, type = "ability", talent = 2 }, -- Plague Leech
        { spell = 130735, type = "ability", debuff = true, requiresTarget = true }, -- Soul Reaper
        { spell = 130736, type = "ability", debuff = true, requiresTarget = true }, -- Soul Reaper
      },
      icon = 136120
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune",
    },
  }
}

templates.class.MONK = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 101546, type = "buff", unit = "player" }, -- Spinning Crane Kick
        { spell = 101643, type = "buff", unit = "player" }, -- Transcendence
        { spell = 113656, type = "buff", unit = "player" }, -- Fists of Fury
        { spell = 115175, type = "buff", unit = "player" }, -- Soothing Mist
        { spell = 115213, type = "buff", unit = "player" }, -- Avert Harm
        { spell = 115288, type = "buff", unit = "player" }, -- Energizing Brew
        { spell = 115295, type = "buff", unit = "player" }, -- Guard
        { spell = 115307, type = "buff", unit = "player" }, -- Shuffle
        { spell = 115308, type = "buff", unit = "player" }, -- Elusive Brew
        { spell = 115867, type = "buff", unit = "player" }, -- Mana Tea
        { spell = 116680, type = "buff", unit = "player" }, -- Thunder Focus Tea
        { spell = 116781, type = "buff", unit = "player" }, -- Legacy of the White Tiger
        { spell = 116841, type = "buff", unit = "player", talent = 2 }, -- Tiger's Lust
        { spell = 116844, type = "buff", unit = "player", talent = 10 }, -- Ring of Peace
        { spell = 116847, type = "buff", unit = "player", talent = 16 }, -- Rushing Jade Wind
        { spell = 116849, type = "buff", unit = "player" }, -- Life Cocoon
        { spell = 117666, type = "buff", unit = "player" }, -- Legacy of the Emperor
        { spell = 118636, type = "buff", unit = "player" }, -- Power Guard
        { spell = 118674, type = "buff", unit = "player" }, -- Vital Mists
        { spell = 119085, type = "buff", unit = "player", talent = 3 }, -- Momentum
        { spell = 119611, type = "buff", unit = "player" }, -- Renewing Mist
        { spell = 120273, type = "buff", unit = "player" }, -- Tiger Strikes
        { spell = 120954, type = "buff", unit = "player" }, -- Fortifying Brew
        { spell = 121125, type = "buff", unit = "player" }, -- Death Note
        { spell = 122278, type = "buff", unit = "player", talent = 14 }, -- Dampen Harm
        { spell = 122783, type = "buff", unit = "player", talent = 15 }, -- Diffuse Magic
        { spell = 124081, type = "buff", unit = "player", talent = 5 }, -- Zen Sphere
        { spell = 124458, type = "buff", unit = "player" }, -- Healing Sphere
        { spell = 125174, type = "buff", unit = "player" }, -- Touch of Karma
        { spell = 125359, type = "buff", unit = "player" }, -- Tiger Power
        { spell = 126119, type = "buff", unit = "player" }, -- Sanctuary of the Ox
        { spell = 126483, type = "buff", unit = "player" }, -- Windswept Pages
        { spell = 127722, type = "buff", unit = "player" }, -- Serpent's Zeal
        { spell = 129914, type = "buff", unit = "player", talent = 7 }, -- Power Strikes
        { spell = 131523, type = "buff", unit = "player" }, -- Zen Meditation
        { spell = 132120, type = "buff", unit = "player" }, -- Enveloping Mist
        { spell = 134563, type = "buff", unit = "player", talent = 13 }, -- Healing Elixirs
        { spell = 137562, type = "buff", unit = "player" }, -- Nimble Brew
        { spell = 137639, type = "buff", unit = "player" }, -- Storm, Earth, and Fire
        { spell = 139597, type = "buff", unit = "player" }, -- Muscle Memory
        { spell = 1247275, type = "buff", unit = "player" }, -- Tigereye Brew
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 107079, type = "debuff", unit = "target" }, -- Quaking Palm
        { spell = 115078, type = "debuff", unit = "target" }, -- Paralysis
        { spell = 115798, type = "debuff", unit = "target" }, -- Weakened Blows
        { spell = 115804, type = "debuff", unit = "target" }, -- Mortal Wounds
        { spell = 116095, type = "debuff", unit = "target" }, -- Disable
        { spell = 116189, type = "debuff", unit = "target" }, -- Provoke
        { spell = 116330, type = "debuff", unit = "target" }, -- Dizzying Haze
        { spell = 116709, type = "debuff", unit = "target" }, -- Spear Hand Strike
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target", talent = 12 }, -- Leg Sweep
        { spell = 119392, type = "debuff", unit = "target", talent = 11 }, -- Charging Ox Wave
        { spell = 120086, type = "debuff", unit = "target" }, -- Fists of Fury
        { spell = 122470, type = "debuff", unit = "target" }, -- Touch of Karma
        { spell = 123725, type = "debuff", unit = "target" }, -- Breath of Fire
        { spell = 130320, type = "debuff", unit = "target" }, -- Rising Sun Kick
        { spell = 137460, type = "debuff", unit = "target" }, -- Silenced
        { spell = 140023, type = "debuff", unit = "target", talent = 10 }, -- Ring of Peace
      },
      icon = 237514
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100784, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Blackout Kick
        { spell = 100787, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Tiger Palm
        { spell = 101545, type = "ability", usable = true }, -- Flying Serpent Kick
        { spell = 101643, type = "ability", buff = true, usable = true }, -- Transcendence
        { spell = 107079, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Quaking Palm
        { spell = 107428, type = "ability", requiresTarget = true, usable = true }, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true, usable = true }, -- Roll
        { spell = 113656, type = "ability", buff = true, usable = true }, -- Fists of Fury
        { spell = 115008, type = "ability", charges = true, usable = true, talent = 18 }, -- Chi Torpedo
        { spell = 115072, type = "ability", usable = true }, -- Expel Harm
        { spell = 115078, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Paralysis
        { spell = 115080, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Touch of Death
        { spell = 115098, type = "ability", usable = true, talent = 4 }, -- Chi Wave
        { spell = 115151, type = "ability", usable = true }, -- Renewing Mist
        { spell = 115176, type = "ability", usable = true }, -- Zen Meditation
        { spell = 115203, type = "ability", usable = true }, -- Fortifying Brew
        { spell = 115213, type = "ability", buff = true, usable = true }, -- Avert Harm
        { spell = 115288, type = "ability", buff = true, usable = true }, -- Energizing Brew
        { spell = 115294, type = "ability", charges = true, usable = true }, -- Mana Tea
        { spell = 115295, type = "ability", buff = true, overlayGlow = true, usable = true }, -- Guard
        { spell = 115308, type = "ability", charges = true, buff = true, usable = true }, -- Elusive Brew
        { spell = 115310, type = "ability", usable = true }, -- Revival
        { spell = 115313, type = "ability", totem = true, usable = true }, -- Summon Jade Serpent Statue
        { spell = 115315, type = "ability", totem = true, usable = true }, -- Summon Black Ox Statue
        { spell = 115399, type = "ability", charges = true, talent = 9 }, -- Chi Brew
        { spell = 115450, type = "ability", usable = true }, -- Detox
        { spell = 115460, type = "ability", usable = true }, -- Healing Sphere
        { spell = 115546, type = "ability", usable = true }, -- Provoke
        { spell = 116095, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Disable
        { spell = 116680, type = "ability", buff = true, usable = true }, -- Thunder Focus Tea
        { spell = 116705, type = "ability", requiresTarget = true, usable = true }, -- Spear Hand Strike
        { spell = 116841, type = "ability", buff = true, usable = true, talent = 2 }, -- Tiger's Lust
        { spell = 116844, type = "ability", buff = true, usable = true, talent = 10 }, -- Ring of Peace
        { spell = 116847, type = "ability", buff = true, usable = true, talent = 16 }, -- Rushing Jade Wind
        { spell = 116849, type = "ability", buff = true, usable = true }, -- Life Cocoon
        { spell = 117368, type = "ability", usable = true }, -- Grapple Weapon
        { spell = 119381, type = "ability", debuff = true, usable = true, talent = 12 }, -- Leg Sweep
        { spell = 119392, type = "ability", debuff = true, usable = true, talent = 11 }, -- Charging Ox Wave
        { spell = 119582, type = "ability", usable = true }, -- Purifying Brew
        { spell = 119996, type = "ability", usable = true }, -- Transcendence: Transfer
        { spell = 121253, type = "ability", requiresTarget = true, usable = true }, -- Keg Smash
        { spell = 121827, type = "ability", charges = true }, -- Roll
        { spell = 122057, type = "ability", requiresTarget = true, usable = true }, -- Clash
        { spell = 122278, type = "ability", buff = true, usable = true, talent = 14 }, -- Dampen Harm
        { spell = 122470, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Touch of Karma
        { spell = 122783, type = "ability", buff = true, usable = true, talent = 15 }, -- Diffuse Magic
        { spell = 123904, type = "ability", usable = true, talent = 17 }, -- Invoke Xuen, the White Tiger
        { spell = 123986, type = "ability", usable = true, talent = 6 }, -- Chi Burst
        { spell = 124081, type = "ability", buff = true, usable = true, talent = 5 }, -- Zen Sphere
        { spell = 126892, type = "ability", usable = true }, -- Zen Pilgrimage
        { spell = 137562, type = "ability", buff = true, usable = true }, -- Nimble Brew
        { spell = 1247275, type = "ability", charges = true, buff = true }, -- Tigereye Brew
      },
      icon = 136120
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {
      title = L["Resources"],
      args = {
      },
      icon = "Interface\\Icons\\monk_stance_drunkenox",
    },
  }
}

-- General Section
tinsert(templates.general.args, {
  title = L["Health"],
  icon = "Interface\\Icons\\inv_potion_54",
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
  icon = "Interface\\Icons\\ability_defend.blp",
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
  spellIds = {2825, 32182}}
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

-- Warrior
tinsert(templates.class.WARRIOR[1][8].args, {
  title = L["Stance"],
  icon = 132349,
  triggers = {[1] = { trigger = {
    type = WeakAuras.GetTriggerCategoryFor("Stance/Form/Aura"),
    event = "Stance/Form/Aura"}}}
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

tinsert(templates.class.WARRIOR[1][8].args, createSimplePowerTemplate(1));
tinsert(templates.class.PALADIN[1][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.HUNTER[1][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.ROGUE[1][8].args, createSimplePowerTemplate(3));
tinsert(templates.class.ROGUE[1][8].args, createSimplePowerTemplate(4));
tinsert(templates.class.PRIEST[1][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.SHAMAN[1][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.MAGE[1][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.WARLOCK[1][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.DRUID[1][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.DRUID[1][8].args, createSimplePowerTemplate(1));
tinsert(templates.class.DRUID[1][8].args, createSimplePowerTemplate(3));
tinsert(templates.class.DRUID[1][8].args, createSimplePowerTemplate(4));

tinsert(templates.class.MONK[1][8].args, createSimplePowerTemplate(0));
tinsert(templates.class.MONK[1][8].args, createSimplePowerTemplate(3));
tinsert(templates.class.MONK[1][8].args, createSimplePowerTemplate(12));

-- Shapeshift Form
tinsert(templates.class.DRUID[1][8].args, {
  title = L["Shapeshift Form"],
  icon = 132276,
  triggers = {[1] = { trigger = {
    type = WeakAuras.GetTriggerCategoryFor("Stance/Form/Aura"),
    event = "Stance/Form/Aura"}}}
});
for j, id in ipairs({5487, 768, 783, 114282, 1394966}) do
  local title, _, icon = GetSpellInfo(id)
  if title then
    tinsert(templates.class.DRUID[1][8].args, {
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


------------------------------
-- Hardcoded race templates
-------------------------------

-- Will of Survive
tinsert(templates.race.Human, { spell = 59752, type = "ability" });
-- Stoneform
tinsert(templates.race.Dwarf, { spell = 20594, type = "ability", buff = true, titleSuffix = L["cooldown"]});
tinsert(templates.race.Dwarf, { spell = 20594, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Shadow Meld
tinsert(templates.race.NightElf, { spell = 58984, type = "ability", buff = true, titleSuffix = L["cooldown"]});
tinsert(templates.race.NightElf, { spell = 58984, type = "buff", titleSuffix = L["buff"]});
-- Escape Artist
tinsert(templates.race.Gnome, { spell = 20589, type = "ability" });

-- Blood Fury
tinsert(templates.race.Orc, { spell = 20572, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Orc, { spell = 20572, type = "buff", unit = "player", titleSuffix = L["buff"]});
--Cannibalize
tinsert(templates.race.Scourge, { spell = 20577, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Scourge, { spell = 20578, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Will of the Forsaken
tinsert(templates.race.Scourge, { spell = 7744, type = "ability", buff = true, titleSuffix = L["cooldown"]});
tinsert(templates.race.Scourge, { spell = 7744, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- War Stomp
tinsert(templates.race.Tauren, { spell = 20549, type = "ability", debuff = true, titleSuffix = L["cooldown"]});
tinsert(templates.race.Tauren, { spell = 20549, type = "debuff", titleSuffix = L["debuff"]});
--Beserking
tinsert(templates.race.Troll, { spell = 26297, type = "ability", buff = true, titleSuffix = L["cooldown"]});
tinsert(templates.race.Troll, { spell = 26297, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Arcane Torrent
tinsert(templates.race.BloodElf, { spell = 28730, type = "ability", debuff = true, titleSuffix = L["cooldown"]});
-- Gift of the Naaru
tinsert(templates.race.Draenei, { spell = 28880, type = "ability", buff = true, titleSuffix = L["cooldown"]});
tinsert(templates.race.Draenei, { spell = 28880, type = "buff", unit = "player", titleSuffix = L["buff"]});
-- Quaking Palm
tinsert(templates.race.Pandaren, { spell = 107079, type = "ability", titleSuffix = L["cooldown"]});
tinsert(templates.race.Pandaren, { spell = 107079, type = "buff", titleSuffix = L["buff"]});
------------------------------
-- Helper code for options
-------------------------------

-- Enrich items from spell, set title
local function handleItem(item)
  local waitingForItemInfo = false;
  if (item.spell) then
    local name, icon, _;
    if (item.type == "item") then
      name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(item.spell);
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
      local prefix = C_Item.GetItemInfo(item.titleItemPrefix);
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


TemplatePrivate.triggerTemplates = templates
