local AddonName, TemplatePrivate = ...
---@class WeakAuras
local WeakAuras = WeakAuras
if not WeakAuras.IsCataClassic() then return end
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
  }

-- Collected by WeakAurasTemplateCollector:
--------------------------------------------------------------------------------

templates.class.WARRIOR = {
  [1] = {
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 469, type = "buff", unit = "player" }, -- Commanding Shout
        { spell = 871, type = "buff", unit = "player" }, -- Shield Wall
        { spell = 1134, type = "buff", unit = "player" }, -- Inner Rage
        { spell = 1719, type = "buff", unit = "player" }, -- Recklessness
        { spell = 2565, type = "buff", unit = "player" }, -- Shield Block
        { spell = 6673, type = "buff", unit = "player" }, -- Battle Shout
        { spell = 12292, type = "buff", unit = "player", talent = 35 }, -- Death Wish
        { spell = 12328, type = "buff", unit = "player", talent = 4 }, -- Sweeping Strikes
        { spell = 12964, type = "buff", unit = "player", talent = 29 }, -- Battle Trance
        { spell = 12968, type = "buff", unit = "player", talent = 37 }, -- Flurry
        { spell = 14202, type = "buff", unit = "player", talent = 32 }, -- Enrage
        { spell = 18499, type = "buff", unit = "player" }, -- Berserker Rage
        { spell = 20230, type = "buff", unit = "player" }, -- Retaliation
        { spell = 23885, type = "buff", unit = "player" }, -- Bloodthirst
        { spell = 23920, type = "buff", unit = "player" }, -- Spell Reflection
        { spell = 29801, type = "buff", unit = "player", talent = 41 }, -- Rampage
        { spell = 46916, type = "buff", unit = "player", talent = 42 }, -- Bloodsurge
        { spell = 55694, type = "buff", unit = "player" }, -- Enraged Regeneration
        { spell = 60116, type = "buff", unit = "player" }, -- Armored Brown Bear
        { spell = 60503, type = "buff", unit = "player", talent = 12 }, -- Taste for Blood
        { spell = 65156, type = "buff", unit = "player", talent = 6 }, -- Juggernaut
        { spell = 84586, type = "buff", unit = "player" }, -- Slaughter
        { spell = 85730, type = "buff", unit = "player", talent = 17 }, -- Deadly Calm
        { spell = 85739, type = "buff", unit = "player", talent = 38 }, -- Meat Cleaver
        { spell = 87096, type = "buff", unit = "player", talent = 68 }, -- Thunderstruck
        { spell = 97954, type = "buff", unit = "player" }, -- Spell Block
        { spell = 102740, type = "buff", unit = "player" }, -- Strength of Courage
        { spell = 102742, type = "buff", unit = "player" }, -- Mastery of Nimbleness
      },
      icon = 132333
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1160, type = "debuff", unit = "target" }, -- Demoralizing Shout
        { spell = 1161, type = "debuff", unit = "target" }, -- Challenging Shout
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 6343, type = "debuff", unit = "target" }, -- Thunder Clap
        { spell = 7922, type = "debuff", unit = "target" }, -- Charge Stun
        { spell = 12294, type = "debuff", unit = "target" }, -- Mortal Strike
        { spell = 12323, type = "debuff", unit = "target", talent = 33 }, -- Piercing Howl
        { spell = 18498, type = "debuff", unit = "target" }, -- Silenced - Gag Order
        { spell = 20253, type = "debuff", unit = "target" }, -- Intercept
        { spell = 20511, type = "debuff", unit = "target" }, -- Intimidating Shout
        { spell = 30070, type = "debuff", unit = "target", talent = 9 }, -- Blood Frenzy
        { spell = 46857, type = "debuff", unit = "target" }, -- Trauma
        { spell = 46968, type = "debuff", unit = "target", talent = 73 }, -- Shockwave
        { spell = 56112, type = "debuff", unit = "target", talent = 36 }, -- Furious Attacks
        { spell = 58567, type = "debuff", unit = "target" }, -- Sunder Armor
        { spell = 64382, type = "debuff", unit = "target" }, -- Shattering Throw
        { spell = 85388, type = "debuff", unit = "target", talent = 16 }, -- Throwdown
        { spell = 86346, type = "debuff", unit = "target" }, -- Colossus Smash
        { spell = 94009, type = "debuff", unit = "target" }, -- Rend
        { spell = 413763, type = "debuff", unit = "target", talent = 1 }, -- Deep Wounds
      },
      icon = 132366
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 71, type = "ability" }, -- Defensive Stance
        { spell = 78, type = "ability", requiresTarget = true }, -- Heroic Strike
        { spell = 100, type = "ability", requiresTarget = true, usable = true }, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Taunt
        { spell = 469, type = "ability", buff = true }, -- Commanding Shout
        { spell = 676, type = "ability", requiresTarget = true, usable = true }, -- Disarm
        { spell = 772, type = "ability", requiresTarget = true, usable = true }, -- Rend
        { spell = 845, type = "ability", requiresTarget = true }, -- Cleave
        { spell = 871, type = "ability", buff = true, usable = true }, -- Shield Wall
        { spell = 1134, type = "ability", buff = true }, -- Inner Rage
        { spell = 1161, type = "ability", debuff = true }, -- Challenging Shout
        { spell = 1464, type = "ability", overlayGlow = true, requiresTarget = true }, -- Slam
        { spell = 1680, type = "ability", usable = true }, -- Whirlwind
        { spell = 1715, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Hamstring
        { spell = 1719, type = "ability", buff = true, usable = true }, -- Recklessness
        { spell = 2457, type = "ability" }, -- Battle Stance
        { spell = 2458, type = "ability" }, -- Berserker Stance
        { spell = 2565, type = "ability", buff = true, usable = true }, -- Shield Block
        { spell = 2764, type = "ability", requiresTarget = true }, -- Throw
        { spell = 3018, type = "ability", requiresTarget = true }, -- Shoot
        { spell = 5246, type = "ability", requiresTarget = true }, -- Intimidating Shout
        { spell = 5308, type = "ability", requiresTarget = true, usable = true }, -- Execute
        { spell = 6343, type = "ability", debuff = true, usable = true }, -- Thunder Clap
        { spell = 6544, type = "ability" }, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true }, -- Pummel
        { spell = 6572, type = "ability", requiresTarget = true, usable = true }, -- Revenge
        { spell = 6673, type = "ability", buff = true }, -- Battle Shout
        { spell = 7384, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Overpower
        { spell = 7386, type = "ability", requiresTarget = true }, -- Sunder Armor
        { spell = 12292, type = "ability", buff = true, talent = 35 }, -- Death Wish
        { spell = 12294, type = "ability", debuff = true, requiresTarget = true }, -- Mortal Strike
        { spell = 12328, type = "ability", buff = true, usable = true, talent = 4 }, -- Sweeping Strikes
        { spell = 12809, type = "ability", talent = 63 }, -- Concussion Blow
        { spell = 18499, type = "ability", buff = true }, -- Berserker Rage
        { spell = 20230, type = "ability", buff = true, usable = true }, -- Retaliation
        { spell = 20243, type = "ability", requiresTarget = true, usable = true, talent = 67 }, -- Devastate
        { spell = 20252, type = "ability", requiresTarget = true, usable = true }, -- Intercept
        { spell = 23881, type = "ability", requiresTarget = true }, -- Bloodthirst
        { spell = 23920, type = "ability", buff = true, usable = true }, -- Spell Reflection
        { spell = 23922, type = "ability", requiresTarget = true, usable = true }, -- Shield Slam
        { spell = 34428, type = "ability", requiresTarget = true, usable = true }, -- Victory Rush
        { spell = 46924, type = "ability", talent = 8 }, -- Bladestorm
        { spell = 46968, type = "ability", debuff = true, talent = 73 }, -- Shockwave
        { spell = 55694, type = "ability", buff = true, usable = true }, -- Enraged Regeneration
        { spell = 57755, type = "ability", requiresTarget = true }, -- Heroic Throw
        { spell = 60970, type = "ability", talent = 40 }, -- Heroic Fury
        { spell = 64382, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Shattering Throw
        { spell = 85288, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 47 }, -- Raging Blow
        { spell = 85388, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 16 }, -- Throwdown
        { spell = 85730, type = "ability", buff = true, talent = 17 }, -- Deadly Calm
        { spell = 86346, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Colossus Smash
        { spell = 88161, type = "ability", requiresTarget = true }, -- Strike
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
        { spell = 465, type = "buff", unit = "player" }, -- Devotion Aura
        { spell = 498, type = "buff", unit = "player" }, -- Divine Protection
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "player" }, -- Hand of Protection
        { spell = 1038, type = "buff", unit = "player" }, -- Hand of Salvation
        { spell = 1044, type = "buff", unit = "player" }, -- Hand of Freedom
        { spell = 7294, type = "buff", unit = "player" }, -- Retribution Aura
        { spell = 19746, type = "buff", unit = "player" }, -- Concentration Aura
        { spell = 19891, type = "buff", unit = "player" }, -- Resistance Aura
        { spell = 20052, type = "buff", unit = "player", talent = 17 }, -- Conviction
        { spell = 20154, type = "buff", unit = "player" }, -- Seal of Righteousness
        { spell = 20164, type = "buff", unit = "player" }, -- Seal of Justice
        { spell = 20165, type = "buff", unit = "player" }, -- Seal of Insight
        { spell = 20925, type = "buff", unit = "player", talent = 37 }, -- Holy Shield
        { spell = 25780, type = "buff", unit = "player" }, -- Righteous Fury
        { spell = 31801, type = "buff", unit = "player" }, -- Seal of Truth
        { spell = 31821, type = "buff", unit = "player", talent = 5 }, -- Aura Mastery
        { spell = 31842, type = "buff", unit = "player", talent = 12 }, -- Divine Favor
        { spell = 31850, type = "buff", unit = "player", talent = 36 }, -- Ardent Defender
        { spell = 31884, type = "buff", unit = "player" }, -- Avenging Wrath
        { spell = 31930, type = "buff", unit = "player" }, -- Judgements of the Wise
        { spell = 32223, type = "buff", unit = "player" }, -- Crusader Aura
        { spell = 53563, type = "buff", unit = "player", talent = 10 }, -- Beacon of Light
        { spell = 53655, type = "buff", unit = "player", talent = 8 }, -- Judgements of the Pure
        { spell = 54149, type = "buff", unit = "player", talent = 9 }, -- Infusion of Light
        { spell = 54428, type = "buff", unit = "player" }, -- Divine Plea
        { spell = 57669, type = "buff", unit = "player" }, -- Replenishment
        { spell = 59578, type = "buff", unit = "player", talent = 61 }, -- The Art of War
        { spell = 60116, type = "buff", unit = "player" }, -- Armored Brown Bear
        { spell = 79063, type = "buff", unit = "player" }, -- Blessing of Kings
        { spell = 79102, type = "buff", unit = "player" }, -- Blessing of Might
        { spell = 82327, type = "buff", unit = "player" }, -- Holy Radiance
        { spell = 84963, type = "buff", unit = "player" }, -- Inquisition
        { spell = 85416, type = "buff", unit = "player", talent = 44 }, -- Grand Crusader
        { spell = 85433, type = "buff", unit = "player", talent = 38 }, -- Sacred Duty
        { spell = 85497, type = "buff", unit = "player", talent = 15 }, -- Speed of Light
        { spell = 85696, type = "buff", unit = "player", talent = 69 }, -- Zealotry
        { spell = 88819, type = "buff", unit = "player", talent = 16 }, -- Daybreak
        { spell = 89906, type = "buff", unit = "player" }, -- Judgements of the Bold
        { spell = 90174, type = "buff", unit = "player", talent = 57 }, -- Divine Purpose
        { spell = 102740, type = "buff", unit = "player" }, -- Strength of Courage
        { spell = 102742, type = "buff", unit = "player" }, -- Mastery of Nimbleness
      },
      icon = 135964
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 20170, type = "debuff", unit = "target" }, -- Seal of Justice
        { spell = 26017, type = "debuff", unit = "target", talent = 41 }, -- Vindication
        { spell = 31803, type = "debuff", unit = "target" }, -- Censure
        { spell = 31935, type = "debuff", unit = "target" }, -- Avenger's Shield
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 68055, type = "debuff", unit = "target", talent = 39 }, -- Judgements of the Just
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 498, type = "ability", buff = true }, -- Divine Protection
        { spell = 633, type = "ability", usable = true }, -- Lay on Hands
        { spell = 642, type = "ability", buff = true, usable = true }, -- Divine Shield
        { spell = 853, type = "ability", debuff = true, requiresTarget = true }, -- Hammer of Justice
        { spell = 879, type = "ability", overlayGlow = true, requiresTarget = true }, -- Exorcism
        { spell = 1022, type = "ability", buff = true, usable = true }, -- Hand of Protection
        { spell = 1038, type = "ability", buff = true }, -- Hand of Salvation
        { spell = 1044, type = "ability", buff = true }, -- Hand of Freedom
        { spell = 2812, type = "ability" }, -- Holy Wrath
        { spell = 6940, type = "ability" }, -- Hand of Sacrifice
        { spell = 20066, type = "ability", talent = 62 }, -- Repentance
        { spell = 20271, type = "ability", requiresTarget = true, usable = true }, -- Judgement
        { spell = 20473, type = "ability", requiresTarget = true }, -- Holy Shock
        { spell = 20925, type = "ability", buff = true, usable = true, talent = 37 }, -- Holy Shield
        { spell = 24275, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Hammer of Wrath
        { spell = 26573, type = "ability", totem = true }, -- Consecration
        { spell = 31821, type = "ability", buff = true, talent = 5 }, -- Aura Mastery
        { spell = 31842, type = "ability", buff = true, talent = 12 }, -- Divine Favor
        { spell = 31850, type = "ability", buff = true, talent = 36 }, -- Ardent Defender
        { spell = 31884, type = "ability", buff = true }, -- Avenging Wrath
        { spell = 31935, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Avenger's Shield
        { spell = 35395, type = "ability", requiresTarget = true, usable = true }, -- Crusader Strike
        { spell = 53385, type = "ability", talent = 66 }, -- Divine Storm
        { spell = 53595, type = "ability", requiresTarget = true, usable = true, talent = 40 }, -- Hammer of the Righteous
        { spell = 53600, type = "ability", requiresTarget = true, usable = true, talent = 46 }, -- Shield of the Righteous
        { spell = 54428, type = "ability", buff = true }, -- Divine Plea
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true }, -- Hand of Reckoning
        { spell = 82327, type = "ability", buff = true, requiresTarget = true }, -- Holy Radiance
        { spell = 85256, type = "ability", overlayGlow = true, requiresTarget = true }, -- Templar's Verdict
        { spell = 85673, type = "ability" }, -- Word of Glory
        { spell = 85696, type = "ability", buff = true, overlayGlow = true, talent = 69 }, -- Zealotry
        { spell = 96231, type = "ability", requiresTarget = true }, -- Rebuke
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
        { spell = 19506, type = "buff", unit = "player", talent = 38 }, -- Trueshot Aura
        { spell = 20043, type = "buff", unit = "player" }, -- Aspect of the Wild
        { spell = 24529, type = "buff", unit = "player", talent = 8 }, -- Spirit Bond
        { spell = 34471, type = "buff", unit = "player", talent = 16 }, -- The Beast Within
        { spell = 34477, type = "buff", unit = "player" }, -- Misdirection
        { spell = 53220, type = "buff", unit = "player", talent = 34 }, -- Improved Steady Shot
        { spell = 53290, type = "buff", unit = "player", talent = 70 }, -- Hunting Party
        { spell = 54216, type = "buff", unit = "player" }, -- Master's Call
        { spell = 54227, type = "buff", unit = "player", talent = 42 }, -- Rapid Recuperation
        { spell = 56453, type = "buff", unit = "player", talent = 63 }, -- Lock and Load
        { spell = 64420, type = "buff", unit = "player", talent = 71 }, -- Sniper Training
        { spell = 75447, type = "buff", unit = "player", talent = 9 }, -- Ferocious Inspiration
        { spell = 77769, type = "buff", unit = "player" }, -- Trap Launcher
        { spell = 82661, type = "buff", unit = "player" }, -- Aspect of the Fox
        { spell = 82692, type = "buff", unit = "player", talent = 10 }, -- Focus Fire
        { spell = 82921, type = "buff", unit = "player", talent = 37 }, -- Bombardment
        { spell = 82925, type = "buff", unit = "player" }, -- Ready, Set, Aim...
        { spell = 82926, type = "buff", unit = "player" }, -- Fire!
        { spell = 89388, type = "buff", unit = "player", talent = 32 }, -- Sic 'Em!
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 19574, type = "buff", unit = "pet", talent = 12 }, -- Bestial Wrath
        { spell = 19615, type = "buff", unit = "pet" }, -- Frenzy Effect
        { spell = 62305, type = "buff", unit = "pet" }, -- Master's Call
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1130, type = "debuff", unit = "target" }, -- Hunter's Mark
        { spell = 1978, type = "debuff", unit = "target" }, -- Serpent Sting
        { spell = 2974, type = "debuff", unit = "target" }, -- Wing Clip
        { spell = 3355, type = "debuff", unit = "target" }, -- Freezing Trap
        { spell = 3674, type = "debuff", unit = "target", talent = 72 }, -- Black Arrow
        { spell = 5116, type = "debuff", unit = "target" }, -- Concussive Shot
        { spell = 13797, type = "debuff", unit = "target" }, -- Immolation Trap
        { spell = 13810, type = "debuff", unit = "target" }, -- Ice Trap
        { spell = 13812, type = "debuff", unit = "target" }, -- Explosive Trap
        { spell = 19386, type = "debuff", unit = "target", talent = 67 }, -- Wyvern Sting
        { spell = 19503, type = "debuff", unit = "target" }, -- Scatter Shot
        { spell = 20736, type = "debuff", unit = "target" }, -- Distracting Shot
        { spell = 24394, type = "debuff", unit = "target" }, -- Intimidation
        { spell = 25810, type = "debuff", unit = "target" }, -- Mind-numbing Poison
        { spell = 34490, type = "debuff", unit = "target", talent = 43 }, -- Silencing Shot
        { spell = 34655, type = "debuff", unit = "target" }, -- Deadly Poison
        { spell = 35101, type = "debuff", unit = "target", talent = 36 }, -- Concussive Barrage
        { spell = 50518, type = "debuff", unit = "target" }, -- Ravage
        { spell = 53301, type = "debuff", unit = "target" }, -- Explosive Shot
        { spell = 82654, type = "debuff", unit = "target" }, -- Widow Venom
        { spell = 88691, type = "debuff", unit = "target", talent = 45 }, -- Marked for Death
        { spell = 94528, type = "debuff", unit = "target" }, -- Flare
        { spell = 413848, type = "debuff", unit = "target", talent = 47 }, -- Piercing Shots
      },
      icon = 135860
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 75, type = "ability", requiresTarget = true, usable = true }, -- Auto Shot
        { spell = 781, type = "ability" }, -- Disengage
        { spell = 1499, type = "ability" }, -- Freezing Trap
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 1978, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Serpent Sting
        { spell = 2643, type = "ability", requiresTarget = true, usable = true }, -- Multi-Shot
        { spell = 2649, type = "ability" }, -- Growl
        { spell = 2973, type = "ability", requiresTarget = true, usable = true }, -- Raptor Strike
        { spell = 2974, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Wing Clip
        { spell = 3044, type = "ability", requiresTarget = true, usable = true }, -- Arcane Shot
        { spell = 3045, type = "ability", buff = true }, -- Rapid Fire
        { spell = 3674, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 72 }, -- Black Arrow
        { spell = 5116, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Concussive Shot
        { spell = 5118, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 5384, type = "ability", buff = true }, -- Feign Death
        { spell = 6991, type = "ability", requiresTarget = true, usable = true }, -- Feed Pet
        { spell = 13159, type = "ability", buff = true }, -- Aspect of the Pack
        { spell = 13165, type = "ability", buff = true }, -- Aspect of the Hawk
        { spell = 13795, type = "ability" }, -- Immolation Trap
        { spell = 13809, type = "ability" }, -- Ice Trap
        { spell = 13813, type = "ability" }, -- Explosive Trap
        { spell = 17253, type = "ability" }, -- Bite
        { spell = 19263, type = "ability", buff = true }, -- Deterrence
        { spell = 19306, type = "ability", requiresTarget = true, usable = true, talent = 61 }, -- Counterattack
        { spell = 19386, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 67 }, -- Wyvern Sting
        { spell = 19434, type = "ability", overlayGlow = true, requiresTarget = true }, -- Aimed Shot
        { spell = 19503, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Scatter Shot
        { spell = 19574, type = "ability", buff = true, unit = 'pet', talent = 12 }, -- Bestial Wrath
        { spell = 19577, type = "ability" }, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true, usable = true }, -- Tranquilizing Shot
        { spell = 20043, type = "ability", buff = true }, -- Aspect of the Wild
        { spell = 20736, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Distracting Shot
        { spell = 23989, type = "ability", talent = 35 }, -- Readiness
        { spell = 34026, type = "ability" }, -- Kill Command
        { spell = 34477, type = "ability", buff = true }, -- Misdirection
        { spell = 34490, type = "ability", debuff = true, requiresTarget = true, talent = 43 }, -- Silencing Shot
        { spell = 34600, type = "ability" }, -- Snake Trap
        { spell = 50518, type = "ability", debuff = true }, -- Ravage
        { spell = 51753, type = "ability", usable = true }, -- Camouflage
        { spell = 53209, type = "ability", requiresTarget = true, talent = 46 }, -- Chimera Shot
        { spell = 53271, type = "ability" }, -- Master's Call
        { spell = 53301, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Explosive Shot
        { spell = 53351, type = "ability", requiresTarget = true, usable = true }, -- Kill Shot
        { spell = 56641, type = "ability", requiresTarget = true, usable = true }, -- Steady Shot
        { spell = 60192, type = "ability", overlayGlow = true }, -- Freezing Trap
        { spell = 77767, type = "ability", requiresTarget = true, usable = true }, -- Cobra Shot
        { spell = 77769, type = "ability", buff = true, usable = true }, -- Trap Launcher
        { spell = 82654, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Widow Venom
        { spell = 82661, type = "ability", buff = true }, -- Aspect of the Fox
        { spell = 82692, type = "ability", buff = true, overlayGlow = true, talent = 10 }, -- Focus Fire
        { spell = 82726, type = "ability", talent = 5 }, -- Fervor
        { spell = 82939, type = "ability", overlayGlow = true }, -- Explosive Trap
        { spell = 82941, type = "ability", overlayGlow = true }, -- Ice Trap
        { spell = 82945, type = "ability", overlayGlow = true }, -- Immolation Trap
        { spell = 82948, type = "ability", overlayGlow = true }, -- Snake Trap
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
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 5171, type = "buff", unit = "player" }, -- Slice and Dice
        { spell = 5277, type = "buff", unit = "player" }, -- Evasion
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 13750, type = "buff", unit = "player", talent = 33 }, -- Adrenaline Rush
        { spell = 13877, type = "buff", unit = "player" }, -- Blade Flurry
        { spell = 14177, type = "buff", unit = "player", talent = 6 }, -- Cold Blood
        { spell = 31224, type = "buff", unit = "player" }, -- Cloak of Shadows
        { spell = 31665, type = "buff", unit = "player" }, -- Master of Subtlety
        { spell = 32645, type = "buff", unit = "player" }, -- Envenom
        { spell = 36554, type = "buff", unit = "player" }, -- Shadowstep
        { spell = 51690, type = "buff", unit = "player", talent = 42 }, -- Killing Spree
        { spell = 51701, type = "buff", unit = "player", talent = 68 }, -- Honor Among Thieves
        { spell = 51713, type = "buff", unit = "player", talent = 70 }, -- Shadow Dance
        { spell = 58427, type = "buff", unit = "player", talent = 7 }, -- Overkill
        { spell = 73651, type = "buff", unit = "player" }, -- Recuperate
        { spell = 74001, type = "buff", unit = "player" }, -- Combat Readiness
        { spell = 102742, type = "buff", unit = "player" }, -- Mastery of Nimbleness
        { spell = 102747, type = "buff", unit = "player" }, -- Agility of the Tiger
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
        { spell = 8647, type = "debuff", unit = "target" }, -- Expose Armor
        { spell = 13218, type = "debuff", unit = "target" }, -- Wound Poison
        { spell = 16511, type = "debuff", unit = "target", talent = 64 }, -- Hemorrhage
        { spell = 26679, type = "debuff", unit = "target" }, -- Deadly Throw
        { spell = 51585, type = "debuff", unit = "target", talent = 37 }, -- Blade Twisting
        { spell = 51693, type = "debuff", unit = "target", talent = 67 }, -- Waylay
        { spell = 58683, type = "debuff", unit = "target", talent = 41 }, -- Savage Combat
        { spell = 79140, type = "debuff", unit = "target", talent = 14 }, -- Vendetta
        { spell = 88611, type = "debuff", unit = "target" }, -- Smoke Bomb
        { spell = 93068, type = "debuff", unit = "target", talent = 10 }, -- Master Poisoner
      },
      icon = 132302
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 53, type = "ability", requiresTarget = true, usable = true }, -- Backstab
        { spell = 408, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Kidney Shot
        { spell = 703, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Garrote
        { spell = 921, type = "ability", requiresTarget = true, usable = true }, -- Pick Pocket
        { spell = 1329, type = "ability", requiresTarget = true }, -- Mutilate
        { spell = 1725, type = "ability" }, -- Distract
        { spell = 1752, type = "ability", requiresTarget = true }, -- Sinister Strike
        { spell = 1766, type = "ability", requiresTarget = true }, -- Kick
        { spell = 1776, type = "ability", debuff = true, requiresTarget = true }, -- Gouge
        { spell = 1784, type = "ability", buff = true, usable = true }, -- Stealth
        { spell = 1833, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Cheap Shot
        { spell = 1856, type = "ability" }, -- Vanish
        { spell = 1943, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Rupture
        { spell = 1966, type = "ability", buff = true, requiresTarget = true }, -- Feint
        { spell = 2094, type = "ability", debuff = true, requiresTarget = true }, -- Blind
        { spell = 2098, type = "ability", requiresTarget = true, usable = true }, -- Eviscerate
        { spell = 2764, type = "ability", requiresTarget = true }, -- Throw
        { spell = 2983, type = "ability", buff = true, usable = true }, -- Sprint
        { spell = 3018, type = "ability", requiresTarget = true, usable = true }, -- Shoot
        { spell = 5277, type = "ability", buff = true }, -- Evasion
        { spell = 5938, type = "ability", requiresTarget = true }, -- Shiv
        { spell = 8647, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Expose Armor
        { spell = 8676, type = "ability", requiresTarget = true, usable = true }, -- Ambush
        { spell = 13750, type = "ability", buff = true, talent = 33 }, -- Adrenaline Rush
        { spell = 13877, type = "ability", buff = true }, -- Blade Flurry
        { spell = 14177, type = "ability", buff = true, usable = true, talent = 6 }, -- Cold Blood
        { spell = 14183, type = "ability", requiresTarget = true, usable = true, talent = 63 }, -- Premeditation
        { spell = 14185, type = "ability", talent = 62 }, -- Preparation
        { spell = 16511, type = "ability", debuff = true, requiresTarget = true, talent = 64 }, -- Hemorrhage
        { spell = 26679, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Deadly Throw
        { spell = 31224, type = "ability", buff = true }, -- Cloak of Shadows
        { spell = 32645, type = "ability", buff = true, requiresTarget = true, usable = true }, -- Envenom
        { spell = 36554, type = "ability", buff = true, requiresTarget = true, usable = true }, -- Shadowstep
        { spell = 51690, type = "ability", buff = true, talent = 42 }, -- Killing Spree
        { spell = 51713, type = "ability", buff = true, talent = 70 }, -- Shadow Dance
        { spell = 51722, type = "ability", requiresTarget = true }, -- Dismantle
        { spell = 57934, type = "ability" }, -- Tricks of the Trade
        { spell = 73981, type = "ability", requiresTarget = true }, -- Redirect
        { spell = 74001, type = "ability", buff = true }, -- Combat Readiness
        { spell = 76577, type = "ability", duration = 5 }, -- Smoke Bomb
        { spell = 79140, type = "ability", debuff = true, requiresTarget = true, talent = 14 }, -- Vendetta
        { spell = 84617, type = "ability", requiresTarget = true, talent = 46 }, -- Revealing Strike
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
        { spell = 10060, type = "buff", unit = "player", talent = 10 }, -- Power Infusion
        { spell = 14751, type = "buff", unit = "player", talent = 41 }, -- Chakra
        { spell = 15286, type = "buff", unit = "player", talent = 63 }, -- Vampiric Embrace
        { spell = 15357, type = "buff", unit = "player", talent = 31 }, -- Inspiration
        { spell = 15473, type = "buff", unit = "player", talent = 66 }, -- Shadowform
        { spell = 33206, type = "buff", unit = "player", talent = 13 }, -- Pain Suppression
        { spell = 41635, type = "buff", unit = "player" }, -- Prayer of Mending
        { spell = 47585, type = "buff", unit = "player", talent = 72 }, -- Dispersion
        { spell = 47753, type = "buff", unit = "player", talent = 9 }, -- Divine Aegis
        { spell = 47788, type = "buff", unit = "player", talent = 38 }, -- Guardian Spirit
        { spell = 49868, type = "buff", unit = "player" }, -- Mind Quickening
        { spell = 57669, type = "buff", unit = "player" }, -- Replenishment
        { spell = 59888, type = "buff", unit = "player", talent = 17 }, -- Borrowed Time
        { spell = 60116, type = "buff", unit = "player" }, -- Armored Brown Bear
        { spell = 63735, type = "buff", unit = "player", talent = 32 }, -- Serendipity
        { spell = 64843, type = "buff", unit = "player" }, -- Divine Hymn
        { spell = 64901, type = "buff", unit = "player" }, -- Hymn of Hope
        { spell = 65081, type = "buff", unit = "player", talent = 34 }, -- Body and Soul
        { spell = 73413, type = "buff", unit = "player" }, -- Inner Will
        { spell = 77487, type = "buff", unit = "player" }, -- Shadow Orb
        { spell = 77489, type = "buff", unit = "player" }, -- Echo of Light
        { spell = 77613, type = "buff", unit = "player", talent = 14 }, -- Grace
        { spell = 79105, type = "buff", unit = "player" }, -- Power Word: Fortitude
        { spell = 79107, type = "buff", unit = "player" }, -- Shadow Protection
        { spell = 81208, type = "buff", unit = "player" }, -- Chakra: Serenity
        { spell = 81782, type = "buff", unit = "player", talent = 6 }, -- Power Word: Barrier
        { spell = 87160, type = "buff", unit = "player", talent = 64 }, -- Mind Melt
        { spell = 88684, type = "buff", unit = "player" }, -- Holy Word: Serenity
        { spell = 89485, type = "buff", unit = "player", talent = 3 }, -- Inner Focus
        { spell = 91139, type = "buff", unit = "player" }, -- Cleansing Tears
        { spell = 91724, type = "buff", unit = "player" }, -- Spell Warding
        { spell = 95799, type = "buff", unit = "player" }, -- Empowered Shadow
        { spell = 96267, type = "buff", unit = "player", talent = 20 }, -- Strength of Soul
        { spell = 17, type = "buff", unit = "target" }, -- Power Word: Shield
        { spell = 47788, type = "buff", unit = "target", talent = 38 }, -- Guardian Spirit
        { spell = 65081, type = "buff", unit = "target", talent = 34 }, -- Body and Soul
        { spell = 63619, type = "buff", unit = "pet" }, -- Shadowcrawl
      },
      icon = 135940
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 2944, type = "debuff", unit = "target" }, -- Devouring Plague
        { spell = 6788, type = "debuff", unit = "target" }, -- Weakened Soul
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 15407, type = "debuff", unit = "target" }, -- Mind Flay
        { spell = 15487, type = "debuff", unit = "target", talent = 62 }, -- Silence
        { spell = 34914, type = "debuff", unit = "target", talent = 70 }, -- Vampiric Touch
        { spell = 48045, type = "debuff", unit = "target" }, -- Mind Sear
        { spell = 48301, type = "debuff", unit = "target" }, -- Mind Trauma
        { spell = 64044, type = "debuff", unit = "target", talent = 69 }, -- Psychic Horror
        { spell = 87178, type = "debuff", unit = "target" }, -- Mind Spike
        { spell = 87194, type = "debuff", unit = "target", talent = 75 }, -- Paralysis
        { spell = 88625, type = "debuff", unit = "target" }, -- Holy Word: Chastise
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability", buff = true, usable = true }, -- Power Word: Shield
        { spell = 527, type = "ability", requiresTarget = true }, -- Dispel Magic
        { spell = 585, type = "ability", requiresTarget = true }, -- Smite
        { spell = 586, type = "ability", buff = true }, -- Fade
        { spell = 589, type = "ability", debuff = true, requiresTarget = true }, -- Shadow Word: Pain
        { spell = 724, type = "ability", totem = true, talent = 40 }, -- Lightwell
        { spell = 2944, type = "ability", debuff = true, requiresTarget = true }, -- Devouring Plague
        { spell = 6346, type = "ability", buff = true }, -- Fear Ward
        { spell = 8092, type = "ability", overlayGlow = true, requiresTarget = true }, -- Mind Blast
        { spell = 8122, type = "ability", debuff = true }, -- Psychic Scream
        { spell = 8129, type = "ability", requiresTarget = true }, -- Mana Burn
        { spell = 10060, type = "ability", buff = true, talent = 10 }, -- Power Infusion
        { spell = 14751, type = "ability", buff = true, usable = true, talent = 41 }, -- Chakra
        { spell = 14914, type = "ability", requiresTarget = true }, -- Holy Fire
        { spell = 15407, type = "ability", debuff = true, requiresTarget = true }, -- Mind Flay
        { spell = 15473, type = "ability", buff = true, usable = true, talent = 66 }, -- Shadowform
        { spell = 15487, type = "ability", debuff = true, requiresTarget = true, talent = 62 }, -- Silence
        { spell = 19236, type = "ability", talent = 43 }, -- Desperate Prayer
        { spell = 32379, type = "ability", requiresTarget = true }, -- Shadow Word: Death
        { spell = 33076, type = "ability" }, -- Prayer of Mending
        { spell = 33206, type = "ability", buff = true, talent = 13 }, -- Pain Suppression
        { spell = 34433, type = "ability", requiresTarget = true }, -- Shadowfiend
        { spell = 34861, type = "ability", requiresTarget = true, talent = 36 }, -- Circle of Healing
        { spell = 34914, type = "ability", debuff = true, requiresTarget = true, talent = 70 }, -- Vampiric Touch
        { spell = 47540, type = "ability", requiresTarget = true }, -- Penance
        { spell = 47585, type = "ability", buff = true, talent = 72 }, -- Dispersion
        { spell = 47788, type = "ability", buff = true, talent = 38 }, -- Guardian Spirit
        { spell = 48045, type = "ability", debuff = true, requiresTarget = true }, -- Mind Sear
        { spell = 62618, type = "ability", talent = 6 }, -- Power Word: Barrier
        { spell = 64044, type = "ability", debuff = true, requiresTarget = true, talent = 69 }, -- Psychic Horror
        { spell = 64843, type = "ability", buff = true }, -- Divine Hymn
        { spell = 64901, type = "ability", buff = true }, -- Hymn of Hope
        { spell = 73510, type = "ability", overlayGlow = true, requiresTarget = true }, -- Mind Spike
        { spell = 88625, type = "ability", debuff = true, requiresTarget = true }, -- Holy Word: Chastise
        { spell = 88684, type = "ability", buff = true, overlayGlow = true }, -- Holy Word: Serenity
        { spell = 89485, type = "ability", buff = true, usable = true, talent = 3 }, -- Inner Focus
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
        { spell = 974, type = "buff", unit = "player" }, -- Earth Shield
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 2825, type = "buff", unit = "player" }, -- Bloodlust
        { spell = 2895, type = "buff", unit = "player" }, -- Wrath of Air Totem
        { spell = 5677, type = "buff", unit = "player" }, -- Mana Spring
        { spell = 8072, type = "buff", unit = "player" }, -- Stoneskin
        { spell = 8076, type = "buff", unit = "player" }, -- Strength of Earth
        { spell = 8178, type = "buff", unit = "player" }, -- Grounding Totem Effect
        { spell = 8185, type = "buff", unit = "player" }, -- Elemental Resistance
        { spell = 8515, type = "buff", unit = "player" }, -- Windfury Totem
        { spell = 16166, type = "buff", unit = "player", talent = 4 }, -- Elemental Mastery
        { spell = 16188, type = "buff", unit = "player", talent = 61 }, -- Nature's Swiftness
        { spell = 16191, type = "buff", unit = "player" }, -- Mana Tide
        { spell = 16236, type = "buff", unit = "player" }, -- Ancestral Fortitude
        { spell = 16246, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 16278, type = "buff", unit = "player", talent = 29 }, -- Flurry
        { spell = 29178, type = "buff", unit = "player", talent = 44 }, -- Elemental Devastation
        { spell = 30802, type = "buff", unit = "player", talent = 35 }, -- Unleashed Rage
        { spell = 30823, type = "buff", unit = "player", talent = 36 }, -- Shamanistic Rage
        { spell = 51470, type = "buff", unit = "player", talent = 11 }, -- Elemental Oath
        { spell = 52109, type = "buff", unit = "player" }, -- Flametongue Totem
        { spell = 52127, type = "buff", unit = "player" }, -- Water Shield
        { spell = 53390, type = "buff", unit = "player", talent = 68 }, -- Tidal Waves
        { spell = 53817, type = "buff", unit = "player", talent = 39 }, -- Maelstrom Weapon
        { spell = 60116, type = "buff", unit = "player" }, -- Armored Brown Bear
        { spell = 61295, type = "buff", unit = "player", talent = 69 }, -- Riptide
        { spell = 77747, type = "buff", unit = "player", talent = 13 }, -- Totemic Wrath
        { spell = 77800, type = "buff", unit = "player", talent = 71 }, -- Focused Insight
        { spell = 98007, type = "buff", unit = "player", talent = 76 }, -- Spirit Link Totem
        { spell = 105284, type = "buff", unit = "player" }, -- Ancestral Vigor
        { spell = 8178, type = "buff", unit = "pet" }, -- Grounding Totem Effect
        { spell = 8185, type = "buff", unit = "pet" }, -- Elemental Resistance
        { spell = 52109, type = "buff", unit = "pet" }, -- Flametongue Totem
      },
      icon = 135863
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3600, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 8034, type = "debuff", unit = "target" }, -- Frostbrand Attack
        { spell = 8042, type = "debuff", unit = "target" }, -- Earth Shock
        { spell = 8050, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 8056, type = "debuff", unit = "target" }, -- Frost Shock
        { spell = 17364, type = "debuff", unit = "target", talent = 34 }, -- Stormstrike
        { spell = 58861, type = "debuff", unit = "target" }, -- Bash
        { spell = 77661, type = "debuff", unit = "target", talent = 41 }, -- Searing Flames
        { spell = 100955, type = "debuff", unit = "target" }, -- Thunderstorm
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
        { spell = 2062, type = "ability", totem = true }, -- Earth Elemental Totem
        { spell = 2484, type = "ability", totem = true }, -- Earthbind Totem
        { spell = 2825, type = "ability", buff = true }, -- Bloodlust
        { spell = 2894, type = "ability", totem = true }, -- Fire Elemental Totem
        { spell = 5730, type = "ability" }, -- Stoneclaw Totem
        { spell = 8042, type = "ability", debuff = true, requiresTarget = true }, -- Earth Shock
        { spell = 8050, type = "ability", debuff = true, requiresTarget = true }, -- Flame Shock
        { spell = 8056, type = "ability", debuff = true, requiresTarget = true }, -- Frost Shock
        { spell = 8143, type = "ability" }, -- Tremor Totem
        { spell = 8177, type = "ability", totem = true }, -- Grounding Totem
        { spell = 16166, type = "ability", buff = true, usable = true, talent = 4 }, -- Elemental Mastery
        { spell = 16188, type = "ability", buff = true, usable = true, talent = 61 }, -- Nature's Swiftness
        { spell = 16190, type = "ability", totem = true, talent = 60 }, -- Mana Tide Totem
        { spell = 17364, type = "ability", debuff = true, requiresTarget = true, talent = 34 }, -- Stormstrike
        { spell = 30823, type = "ability", buff = true, talent = 36 }, -- Shamanistic Rage
        { spell = 51490, type = "ability" }, -- Thunderstorm
        { spell = 51505, type = "ability", requiresTarget = true }, -- Lava Burst
        { spell = 51514, type = "ability" }, -- Hex
        { spell = 51533, type = "ability", talent = 40 }, -- Feral Spirit
        { spell = 57994, type = "ability", requiresTarget = true }, -- Wind Shear
        { spell = 60103, type = "ability", requiresTarget = true, usable = true }, -- Lava Lash
        { spell = 61295, type = "ability", buff = true, talent = 69 }, -- Riptide
        { spell = 61882, type = "ability", talent = 10 }, -- Earthquake
        { spell = 73899, type = "ability" }, -- Primal Strike
        { spell = 98008, type = "ability", totem = true, talent = 76 }, -- Spirit Link Totem
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
        { spell = 543, type = "buff", unit = "player" }, -- Mage Ward
        { spell = 1463, type = "buff", unit = "player" }, -- Mana Shield
        { spell = 6117, type = "buff", unit = "player" }, -- Mage Armor
        { spell = 7302, type = "buff", unit = "player" }, -- Frost Armor
        { spell = 11426, type = "buff", unit = "player", talent = 65 }, -- Ice Barrier
        { spell = 12042, type = "buff", unit = "player", talent = 9 }, -- Arcane Power
        { spell = 12043, type = "buff", unit = "player", talent = 6 }, -- Presence of Mind
        { spell = 12051, type = "buff", unit = "player" }, -- Evocation
        { spell = 12472, type = "buff", unit = "player", talent = 59 }, -- Icy Veins
        { spell = 12536, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 30482, type = "buff", unit = "player" }, -- Molten Armor
        { spell = 44544, type = "buff", unit = "player", talent = 63 }, -- Fingers of Frost
        { spell = 45438, type = "buff", unit = "player" }, -- Ice Block
        { spell = 48108, type = "buff", unit = "player", talent = 43 }, -- Hot Streak
        { spell = 57531, type = "buff", unit = "player", talent = 8 }, -- Arcane Potency
        { spell = 57669, type = "buff", unit = "player" }, -- Replenishment
        { spell = 57761, type = "buff", unit = "player", talent = 66 }, -- Brain Freeze
        { spell = 64343, type = "buff", unit = "player", talent = 32 }, -- Impact
        { spell = 79058, type = "buff", unit = "player" }, -- Arcane Brilliance
        { spell = 79683, type = "buff", unit = "player" }, -- Arcane Missiles!
        { spell = 80169, type = "buff", unit = "player" }, -- Food
        { spell = 80353, type = "buff", unit = "player" }, -- Time Warp
        { spell = 82930, type = "buff", unit = "player", talent = 17 }, -- Arcane Tactics
        { spell = 87959, type = "buff", unit = "player" }, -- Drink
        { spell = 90887, type = "buff", unit = "player" }, -- Witching Hour
        { spell = 90898, type = "buff", unit = "player" }, -- Tendrils of Darkness
        { spell = 54646, type = "buff", unit = "target", talent = 16 }, -- Focus Magic
        { spell = 57669, type = "buff", unit = "pet" }, -- Replenishment
      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 116, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 120, type = "debuff", unit = "target" }, -- Cone of Cold
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 11113, type = "debuff", unit = "target", talent = 37 }, -- Blast Wave
        { spell = 11366, type = "debuff", unit = "target" }, -- Pyroblast
        { spell = 12355, type = "debuff", unit = "target", talent = 32 }, -- Impact
        { spell = 12485, type = "debuff", unit = "target" }, -- Chilled
        { spell = 22959, type = "debuff", unit = "target", talent = 33 }, -- Critical Mass
        { spell = 31589, type = "debuff", unit = "target", talent = 13 }, -- Slow
        { spell = 31661, type = "debuff", unit = "target", talent = 42 }, -- Dragon's Breath
        { spell = 44457, type = "debuff", unit = "target", talent = 44 }, -- Living Bomb
        { spell = 44572, type = "debuff", unit = "target", talent = 68 }, -- Deep Freeze
        { spell = 44614, type = "debuff", unit = "target" }, -- Frostfire Bolt
        { spell = 84721, type = "debuff", unit = "target", talent = 72 }, -- Frostfire Orb
        { spell = 92315, type = "debuff", unit = "target" }, -- Pyroblast!
        { spell = 413841, type = "debuff", unit = "target", talent = 30 }, -- Ignite
      },
      icon = 135848
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability", buff = true }, -- Invisibility
        { spell = 116, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Frostbolt
        { spell = 120, type = "ability", debuff = true }, -- Cone of Cold
        { spell = 122, type = "ability", debuff = true }, -- Frost Nova
        { spell = 133, type = "ability", overlayGlow = true, requiresTarget = true }, -- Fireball
        { spell = 543, type = "ability", buff = true }, -- Mage Ward
        { spell = 1463, type = "ability", buff = true }, -- Mana Shield
        { spell = 1953, type = "ability" }, -- Blink
        { spell = 2136, type = "ability", overlayGlow = true, requiresTarget = true }, -- Fire Blast
        { spell = 2139, type = "ability", requiresTarget = true }, -- Counterspell
        { spell = 2948, type = "ability", requiresTarget = true }, -- Scorch
        { spell = 5143, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Arcane Missiles
        { spell = 11113, type = "ability", debuff = true, talent = 37 }, -- Blast Wave
        { spell = 11426, type = "ability", buff = true, talent = 65 }, -- Ice Barrier
        { spell = 11958, type = "ability", talent = 62 }, -- Cold Snap
        { spell = 12042, type = "ability", buff = true, usable = true, talent = 9 }, -- Arcane Power
        { spell = 12043, type = "ability", buff = true, usable = true, talent = 6 }, -- Presence of Mind
        { spell = 12051, type = "ability", buff = true }, -- Evocation
        { spell = 12472, type = "ability", buff = true, talent = 59 }, -- Icy Veins
        { spell = 30449, type = "ability", requiresTarget = true }, -- Spellsteal
        { spell = 30451, type = "ability", requiresTarget = true }, -- Arcane Blast
        { spell = 30455, type = "ability", overlayGlow = true, requiresTarget = true }, -- Ice Lance
        { spell = 31589, type = "ability", debuff = true, requiresTarget = true, talent = 13 }, -- Slow
        { spell = 31661, type = "ability", debuff = true, talent = 42 }, -- Dragon's Breath
        { spell = 31707, type = "ability" }, -- Waterbolt
        { spell = 43987, type = "ability", usable = true }, -- Ritual of Refreshment
        { spell = 44425, type = "ability", requiresTarget = true }, -- Arcane Barrage
        { spell = 44572, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 68 }, -- Deep Freeze
        { spell = 44614, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Frostfire Bolt
        { spell = 45438, type = "ability", buff = true, usable = true }, -- Ice Block
        { spell = 55342, type = "ability" }, -- Mirror Image
        { spell = 82676, type = "ability" }, -- Ring of Frost
        { spell = 82731, type = "ability" }, -- Flame Orb
        { spell = 92283, type = "ability", talent = 72 }, -- Frostfire Orb
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
        { spell = 687, type = "buff", unit = "player" }, -- Demon Armor
        { spell = 1949, type = "buff", unit = "player" }, -- Hellfire
        { spell = 5697, type = "buff", unit = "player" }, -- Unending Breath
        { spell = 6229, type = "buff", unit = "player" }, -- Shadow Ward
        { spell = 6307, type = "buff", unit = "player" }, -- Blood Pact
        { spell = 25228, type = "buff", unit = "player" }, -- Soul Link
        { spell = 28176, type = "buff", unit = "player" }, -- Fel Armor
        { spell = 47241, type = "buff", unit = "player", talent = 37 }, -- Metamorphosis
        { spell = 47283, type = "buff", unit = "player", talent = 68 }, -- Empowered Imp
        { spell = 48018, type = "buff", unit = "player" }, -- Demonic Circle: Summon
        { spell = 50589, type = "buff", unit = "player" }, -- Immolation Aura
        { spell = 53646, type = "buff", unit = "player", talent = 36 }, -- Demonic Pact
        { spell = 54276, type = "buff", unit = "player", talent = 66 }, -- Backdraft
        { spell = 57669, type = "buff", unit = "player" }, -- Replenishment
        { spell = 64371, type = "buff", unit = "player", talent = 9 }, -- Eradication
        { spell = 71165, type = "buff", unit = "player", talent = 34 }, -- Molten Core
        { spell = 74434, type = "buff", unit = "player" }, -- Soulburn
        { spell = 79268, type = "buff", unit = "player" }, -- Soul Harvest
        { spell = 79462, type = "buff", unit = "player" }, -- Demon Soul: Felguard
        { spell = 85383, type = "buff", unit = "player", talent = 59 }, -- Improved Soul Fire
        { spell = 85768, type = "buff", unit = "player" }, -- Dark Intent
        { spell = 86211, type = "buff", unit = "player", talent = 16 }, -- Soul Swap
        { spell = 90887, type = "buff", unit = "player" }, -- Witching Hour
        { spell = 90898, type = "buff", unit = "player" }, -- Tendrils of Darkness
        { spell = 6307, type = "buff", unit = "target" }, -- Blood Pact
        { spell = 25228, type = "buff", unit = "target" }, -- Soul Link
        { spell = 53646, type = "buff", unit = "target", talent = 36 }, -- Demonic Pact
        { spell = 54508, type = "buff", unit = "target", talent = 38 }, -- Demonic Empowerment
        { spell = 85767, type = "buff", unit = "target" }, -- Dark Intent
        { spell = 6307, type = "buff", unit = "pet" }, -- Blood Pact
        { spell = 25228, type = "buff", unit = "pet" }, -- Soul Link
        { spell = 53646, type = "buff", unit = "pet", talent = 36 }, -- Demonic Pact
        { spell = 54508, type = "buff", unit = "pet", talent = 38 }, -- Demonic Empowerment
        { spell = 57669, type = "buff", unit = "pet" }, -- Replenishment
        { spell = 85759, type = "buff", unit = "pet" }, -- Dark Intent
        { spell = 89751, type = "buff", unit = "pet" }, -- Felstorm
      },
      icon = 136210
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 172, type = "debuff", unit = "target" }, -- Corruption
        { spell = 348, type = "debuff", unit = "target" }, -- Immolate
        { spell = 603, type = "debuff", unit = "target" }, -- Bane of Doom
        { spell = 689, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 702, type = "debuff", unit = "target" }, -- Curse of Weakness
        { spell = 980, type = "debuff", unit = "target" }, -- Bane of Agony
        { spell = 1120, type = "debuff", unit = "target" }, -- Drain Soul
        { spell = 1490, type = "debuff", unit = "target" }, -- Curse of the Elements
        { spell = 1714, type = "debuff", unit = "target" }, -- Curse of Tongues
        { spell = 5484, type = "debuff", unit = "target" }, -- Howl of Terror
        { spell = 5782, type = "debuff", unit = "target" }, -- Fear
        { spell = 6789, type = "debuff", unit = "target" }, -- Death Coil
        { spell = 17800, type = "debuff", unit = "target", talent = 57 }, -- Shadow and Flame
        { spell = 18118, type = "debuff", unit = "target", talent = 74 }, -- Aftermath
        { spell = 18223, type = "debuff", unit = "target", talent = 8 }, -- Curse of Exhaustion
        { spell = 27243, type = "debuff", unit = "target" }, -- Seed of Corruption
        { spell = 30108, type = "debuff", unit = "target" }, -- Unstable Affliction
        { spell = 30213, type = "debuff", unit = "target" }, -- Legion Strike
        { spell = 30283, type = "debuff", unit = "target", talent = 67 }, -- Shadowfury
        { spell = 32389, type = "debuff", unit = "target", talent = 7 }, -- Shadow Embrace
        { spell = 47960, type = "debuff", unit = "target" }, -- Shadowflame
        { spell = 48181, type = "debuff", unit = "target", talent = 13 }, -- Haunt
        { spell = 54786, type = "debuff", unit = "target" }, -- Demon Leap
        { spell = 60947, type = "debuff", unit = "target" }, -- Nightmare
        { spell = 80240, type = "debuff", unit = "target", talent = 63 }, -- Bane of Havoc
        { spell = 85421, type = "debuff", unit = "target", talent = 72 }, -- Burning Embers
        { spell = 86000, type = "debuff", unit = "target" }, -- Curse of Gul'dan
        { spell = 89766, type = "debuff", unit = "target" }, -- Axe Toss
        { spell = 93986, type = "debuff", unit = "target", talent = 47 }, -- Aura of Foreboding
      },
      icon = 136139
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 172, type = "ability", debuff = true, requiresTarget = true }, -- Corruption
        { spell = 348, type = "ability", debuff = true, requiresTarget = true }, -- Immolate
        { spell = 603, type = "ability", debuff = true, requiresTarget = true }, -- Bane of Doom
        { spell = 686, type = "ability", requiresTarget = true }, -- Shadow Bolt
        { spell = 689, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Drain Life
        { spell = 698, type = "ability", usable = true }, -- Ritual of Summoning
        { spell = 702, type = "ability", debuff = true, requiresTarget = true }, -- Curse of Weakness
        { spell = 980, type = "ability", debuff = true, requiresTarget = true }, -- Bane of Agony
        { spell = 1120, type = "ability", debuff = true, requiresTarget = true }, -- Drain Soul
        { spell = 1122, type = "ability" }, -- Summon Infernal
        { spell = 1490, type = "ability", debuff = true, requiresTarget = true }, -- Curse of the Elements
        { spell = 1714, type = "ability", debuff = true, requiresTarget = true }, -- Curse of Tongues
        { spell = 5484, type = "ability", debuff = true }, -- Howl of Terror
        { spell = 5676, type = "ability", overlayGlow = true, requiresTarget = true }, -- Searing Pain
        { spell = 5782, type = "ability", debuff = true, requiresTarget = true }, -- Fear
        { spell = 6229, type = "ability", buff = true }, -- Shadow Ward
        { spell = 6353, type = "ability", overlayGlow = true, requiresTarget = true }, -- Soul Fire
        { spell = 6789, type = "ability", debuff = true, requiresTarget = true }, -- Death Coil
        { spell = 17877, type = "ability", requiresTarget = true, usable = true, talent = 60 }, -- Shadowburn
        { spell = 17962, type = "ability", requiresTarget = true, usable = true }, -- Conflagrate
        { spell = 18223, type = "ability", debuff = true, requiresTarget = true, talent = 8 }, -- Curse of Exhaustion
        { spell = 18540, type = "ability" }, -- Summon Doomguard
        { spell = 27243, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Seed of Corruption
        { spell = 29722, type = "ability", overlayGlow = true, requiresTarget = true }, -- Incinerate
        { spell = 29858, type = "ability" }, -- Soulshatter
        { spell = 29893, type = "ability" }, -- Ritual of Souls
        { spell = 30108, type = "ability", debuff = true, requiresTarget = true }, -- Unstable Affliction
        { spell = 30151, type = "ability" }, -- Pursuit
        { spell = 30213, type = "ability", debuff = true }, -- Legion Strike
        { spell = 30283, type = "ability", debuff = true, talent = 67 }, -- Shadowfury
        { spell = 47193, type = "ability", talent = 38 }, -- Demonic Empowerment
        { spell = 47241, type = "ability", buff = true, talent = 37 }, -- Metamorphosis
        { spell = 47897, type = "ability" }, -- Shadowflame
        { spell = 48020, type = "ability", overlayGlow = true, usable = true }, -- Demonic Circle: Teleport
        { spell = 48181, type = "ability", debuff = true, requiresTarget = true, talent = 13 }, -- Haunt
        { spell = 50589, type = "ability", buff = true, usable = true }, -- Immolation Aura
        { spell = 50796, type = "ability", requiresTarget = true, talent = 70 }, -- Chaos Bolt
        { spell = 54785, type = "ability", usable = true }, -- Demon Leap
        { spell = 71521, type = "ability", requiresTarget = true, totem = true, talent = 44 }, -- Hand of Gul'dan
        { spell = 74434, type = "ability", buff = true }, -- Soulburn
        { spell = 77799, type = "ability", requiresTarget = true }, -- Fel Flame
        { spell = 77801, type = "ability" }, -- Demon Soul
        { spell = 79268, type = "ability", buff = true, usable = true }, -- Soul Harvest
        { spell = 80240, type = "ability", debuff = true, requiresTarget = true, talent = 63 }, -- Bane of Havoc
        { spell = 86121, type = "ability", requiresTarget = true, talent = 16 }, -- Soul Swap
        { spell = 89751, type = "ability", buff = true, unit = 'pet' }, -- Felstorm
        { spell = 89766, type = "ability", debuff = true }, -- Axe Toss
        { spell = 89792, type = "ability" }, -- Flee
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
        { spell = 467, type = "buff", unit = "player" }, -- Thorns
        { spell = 768, type = "buff", unit = "player" }, -- Cat Form
        { spell = 774, type = "buff", unit = "player" }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player" }, -- Travel Form
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 5217, type = "buff", unit = "player" }, -- Tiger's Fury
        { spell = 5229, type = "buff", unit = "player" }, -- Enrage
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 16689, type = "buff", unit = "player" }, -- Nature's Grasp
        { spell = 16870, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 17116, type = "buff", unit = "player", talent = 60 }, -- Nature's Swiftness
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player" }, -- Frenzied Regeneration
        { spell = 24858, type = "buff", unit = "player", talent = 15 }, -- Moonkin Form
        { spell = 24907, type = "buff", unit = "player" }, -- Moonkin Aura
        { spell = 24932, type = "buff", unit = "player", talent = 39 }, -- Leader of the Pack
        { spell = 29166, type = "buff", unit = "player" }, -- Innervate
        { spell = 33763, type = "buff", unit = "player" }, -- Lifebloom
        { spell = 33891, type = "buff", unit = "player", talent = 67 }, -- Tree of Life
        { spell = 44203, type = "buff", unit = "player" }, -- Tranquility
        { spell = 48438, type = "buff", unit = "player", talent = 69 }, -- Wild Growth
        { spell = 48504, type = "buff", unit = "player", talent = 61 }, -- Living Seed
        { spell = 48505, type = "buff", unit = "player", talent = 13 }, -- Starfall
        { spell = 50334, type = "buff", unit = "player", talent = 43 }, -- Berserk
        { spell = 51185, type = "buff", unit = "player", talent = 38 }, -- King of the Jungle
        { spell = 52610, type = "buff", unit = "player" }, -- Savage Roar
        { spell = 57669, type = "buff", unit = "player" }, -- Replenishment
        { spell = 60116, type = "buff", unit = "player" }, -- Armored Brown Bear
        { spell = 77761, type = "buff", unit = "player" }, -- Stampeding Roar
        { spell = 79061, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 80879, type = "buff", unit = "player", talent = 40 }, -- Primal Madness
        { spell = 81022, type = "buff", unit = "player", talent = 32 }, -- Stampede
        { spell = 91143, type = "buff", unit = "player" }, -- Anthem
      },
      icon = 136097
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target" }, -- Demoralizing Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target" }, -- Rip
        { spell = 5209, type = "debuff", unit = "target" }, -- Challenging Roar
        { spell = 5211, type = "debuff", unit = "target" }, -- Bash
        { spell = 5570, type = "debuff", unit = "target" }, -- Insect Swarm
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 8921, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 22570, type = "debuff", unit = "target" }, -- Maim
        { spell = 33745, type = "debuff", unit = "target" }, -- Lacerate
        { spell = 33876, type = "debuff", unit = "target" }, -- Mangle
        { spell = 50259, type = "debuff", unit = "target" }, -- Dazed
        { spell = 58180, type = "debuff", unit = "target", talent = 46 }, -- Infected Wounds
        { spell = 60433, type = "debuff", unit = "target", talent = 14 }, -- Earth and Moon
        { spell = 61391, type = "debuff", unit = "target", talent = 17 }, -- Typhoon
        { spell = 81261, type = "debuff", unit = "target", talent = 4 }, -- Solar Beam
        { spell = 91565, type = "debuff", unit = "target" }, -- Faerie Fire
      },
      icon = 132114
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 339, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Entangling Roots
        { spell = 467, type = "ability", buff = true, requiresTarget = true }, -- Thorns
        { spell = 740, type = "ability" }, -- Tranquility
        { spell = 770, type = "ability", requiresTarget = true }, -- Faerie Fire
        { spell = 779, type = "ability", usable = true }, -- Swipe
        { spell = 1079, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Rip
        { spell = 1082, type = "ability", requiresTarget = true, usable = true }, -- Claw
        { spell = 1126, type = "ability", requiresTarget = true }, -- Mark of the Wild
        { spell = 1822, type = "ability", requiresTarget = true, usable = true }, -- Rake
        { spell = 1850, type = "ability", buff = true, usable = true }, -- Dash
        { spell = 2908, type = "ability", requiresTarget = true }, -- Soothe
        { spell = 2912, type = "ability", requiresTarget = true }, -- Starfire
        { spell = 5176, type = "ability", overlayGlow = true, requiresTarget = true }, -- Wrath
        { spell = 5209, type = "ability", debuff = true, usable = true }, -- Challenging Roar
        { spell = 5211, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Bash
        { spell = 5215, type = "ability", buff = true, usable = true }, -- Prowl
        { spell = 5217, type = "ability", buff = true, usable = true }, -- Tiger's Fury
        { spell = 5221, type = "ability", requiresTarget = true, usable = true }, -- Shred
        { spell = 5229, type = "ability", buff = true, usable = true }, -- Enrage
        { spell = 5570, type = "ability", debuff = true, requiresTarget = true }, -- Insect Swarm
        { spell = 6785, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Ravage
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Growl
        { spell = 6807, type = "ability", requiresTarget = true, usable = true }, -- Maul
        { spell = 8921, type = "ability", debuff = true, requiresTarget = true }, -- Moonfire
        { spell = 8998, type = "ability", requiresTarget = true, usable = true }, -- Cower
        { spell = 9005, type = "ability", requiresTarget = true, usable = true }, -- Pounce
        { spell = 16689, type = "ability", buff = true }, -- Nature's Grasp
        { spell = 16857, type = "ability", requiresTarget = true, usable = true }, -- Faerie Fire (Feral)
        { spell = 16979, type = "ability", requiresTarget = true, talent = 31 }, -- Feral Charge
        { spell = 17116, type = "ability", buff = true, usable = true, talent = 60 }, -- Nature's Swiftness
        { spell = 18562, type = "ability", usable = true }, -- Swiftmend
        { spell = 20484, type = "ability", usable = true }, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true, usable = true }, -- Ferocious Bite
        { spell = 22570, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", buff = true, usable = true }, -- Frenzied Regeneration
        { spell = 29166, type = "ability", buff = true, requiresTarget = true }, -- Innervate
        { spell = 33745, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Lacerate
        { spell = 33786, type = "ability", requiresTarget = true }, -- Cyclone
        { spell = 33831, type = "ability", talent = 11 }, -- Force of Nature
        { spell = 33876, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Mangle
        { spell = 33878, type = "ability", overlayGlow = true, requiresTarget = true }, -- Mangle
        { spell = 33891, type = "ability", buff = true, talent = 67 }, -- Tree of Life
        { spell = 48438, type = "ability", buff = true, overlayGlow = true, requiresTarget = true, talent = 69 }, -- Wild Growth
        { spell = 48505, type = "ability", buff = true, talent = 13 }, -- Starfall
        { spell = 49376, type = "ability", requiresTarget = true, usable = true, talent = 31 }, -- Feral Charge
        { spell = 49377, type = "ability", requiresTarget = true, talent = 31 }, -- Feral Charge
        { spell = 50334, type = "ability", buff = true, talent = 43 }, -- Berserk
        { spell = 50516, type = "ability", talent = 17 }, -- Typhoon
        { spell = 77758, type = "ability", usable = true }, -- Thrash
        { spell = 77761, type = "ability", buff = true, usable = true }, -- Stampeding Roar
        { spell = 77764, type = "ability", usable = true }, -- Stampeding Roar
        { spell = 78674, type = "ability", requiresTarget = true }, -- Starsurge
        { spell = 78675, type = "ability", requiresTarget = true, talent = 4 }, -- Solar Beam
        { spell = 80313, type = "ability", requiresTarget = true, usable = true, talent = 37 }, -- Pulverize
        { spell = 80964, type = "ability", requiresTarget = true, usable = true }, -- Skull Bash
        { spell = 80965, type = "ability", requiresTarget = true, usable = true }, -- Skull Bash
        { spell = 88751, type = "ability" }, -- Wild Mushroom: Detonate
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
        { spell = 45529, type = "buff", unit = "player" }, -- Blood Tap
        { spell = 48263, type = "buff", unit = "player" }, -- Blood Presence
        { spell = 48265, type = "buff", unit = "player" }, -- Unholy Presence
        { spell = 48266, type = "buff", unit = "player" }, -- Frost Presence
        { spell = 48707, type = "buff", unit = "player" }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player" }, -- Icebound Fortitude
        { spell = 49016, type = "buff", unit = "player", talent = 71 }, -- Unholy Frenzy
        { spell = 49222, type = "buff", unit = "player", talent = 14 }, -- Bone Shield
        { spell = 50461, type = "buff", unit = "player", talent = 68 }, -- Anti-Magic Zone
        { spell = 51124, type = "buff", unit = "player", talent = 41 }, -- Killing Machine
        { spell = 51271, type = "buff", unit = "player", talent = 30 }, -- Pillar of Frost
        { spell = 51460, type = "buff", unit = "player", talent = 65 }, -- Runic Corruption
        { spell = 51721, type = "buff", unit = "player" }, -- Dominion Over Acherus
        { spell = 53138, type = "buff", unit = "player", talent = 11 }, -- Abomination's Might
        { spell = 55233, type = "buff", unit = "player", talent = 10 }, -- Vampiric Blood
        { spell = 55610, type = "buff", unit = "player", talent = 44 }, -- Improved Icy Talons
        { spell = 57330, type = "buff", unit = "player" }, -- Horn of Winter
        { spell = 59052, type = "buff", unit = "player" }, -- Freezing Fog
        { spell = 81141, type = "buff", unit = "player", talent = 18 }, -- Crimson Scourge
        { spell = 81340, type = "buff", unit = "player", talent = 72 }, -- Sudden Doom
        { spell = 91364, type = "buff", unit = "player" }, -- Heartened
        { spell = 96268, type = "buff", unit = "player", talent = 76 }, -- Death's Advance
        { spell = 102740, type = "buff", unit = "player" }, -- Strength of Courage
        { spell = 102742, type = "buff", unit = "player" }, -- Mastery of Nimbleness
        { spell = 63560, type = "buff", unit = "pet", talent = 67 }, -- Dark Transformation
        { spell = 91342, type = "buff", unit = "pet", talent = 74 }, -- Shadow Infusion
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 43265, type = "debuff", unit = "target" }, -- Death and Decay
        { spell = 45524, type = "debuff", unit = "target" }, -- Chains of Ice
        { spell = 47476, type = "debuff", unit = "target" }, -- Strangulate
        { spell = 49203, type = "debuff", unit = "target", talent = 36 }, -- Hungering Cold
        { spell = 49206, type = "debuff", unit = "target", talent = 60 }, -- Summon Gargoyle
        { spell = 50435, type = "debuff", unit = "target", talent = 45 }, -- Chilblains
        { spell = 50536, type = "debuff", unit = "target", talent = 59 }, -- Unholy Blight
        { spell = 55078, type = "debuff", unit = "target" }, -- Blood Plague
        { spell = 55095, type = "debuff", unit = "target" }, -- Frost Fever
        { spell = 56222, type = "debuff", unit = "target" }, -- Dark Command
        { spell = 65142, type = "debuff", unit = "target" }, -- Ebon Plague
        { spell = 73975, type = "debuff", unit = "target" }, -- Necrotic Strike
        { spell = 77606, type = "debuff", unit = "target" }, -- Dark Simulacrum
        { spell = 81130, type = "debuff", unit = "target", talent = 17 }, -- Scarlet Fever
        { spell = 81325, type = "debuff", unit = "target", talent = 31 }, -- Brittle Bones
        { spell = 91800, type = "debuff", unit = "target" }, -- Gnaw
      },
      icon = 237514
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability", buff = true }, -- Path of Frost
        { spell = 42650, type = "ability", buff = true }, -- Army of the Dead
        { spell = 43265, type = "ability", debuff = true }, -- Death and Decay
        { spell = 45462, type = "ability", requiresTarget = true }, -- Plague Strike
        { spell = 45477, type = "ability", overlayGlow = true, requiresTarget = true }, -- Icy Touch
        { spell = 45524, type = "ability", debuff = true, requiresTarget = true }, -- Chains of Ice
        { spell = 45529, type = "ability", buff = true }, -- Blood Tap
        { spell = 45902, type = "ability", requiresTarget = true }, -- Blood Strike
        { spell = 46584, type = "ability", totem = true }, -- Raise Dead
        { spell = 47468, type = "ability" }, -- Claw
        { spell = 47476, type = "ability", debuff = true, requiresTarget = true }, -- Strangulate
        { spell = 47481, type = "ability" }, -- Gnaw
        { spell = 47482, type = "ability" }, -- Leap
        { spell = 47484, type = "ability" }, -- Huddle
        { spell = 47528, type = "ability", requiresTarget = true }, -- Mind Freeze
        { spell = 47541, type = "ability", overlayGlow = true, requiresTarget = true }, -- Death Coil
        { spell = 47568, type = "ability" }, -- Empower Rune Weapon
        { spell = 48707, type = "ability", buff = true }, -- Anti-Magic Shell
        { spell = 48721, type = "ability", overlayGlow = true }, -- Blood Boil
        { spell = 48743, type = "ability" }, -- Death Pact
        { spell = 48792, type = "ability", buff = true }, -- Icebound Fortitude
        { spell = 48982, type = "ability", talent = 4 }, -- Rune Tap
        { spell = 49016, type = "ability", buff = true, talent = 71 }, -- Unholy Frenzy
        { spell = 49020, type = "ability", overlayGlow = true, requiresTarget = true }, -- Obliterate
        { spell = 49028, type = "ability", requiresTarget = true, talent = 8 }, -- Dancing Rune Weapon
        { spell = 49143, type = "ability", overlayGlow = true, requiresTarget = true }, -- Frost Strike
        { spell = 49184, type = "ability", overlayGlow = true, requiresTarget = true, talent = 33 }, -- Howling Blast
        { spell = 49203, type = "ability", debuff = true, talent = 36 }, -- Hungering Cold
        { spell = 49206, type = "ability", debuff = true, talent = 60 }, -- Summon Gargoyle
        { spell = 49222, type = "ability", buff = true, talent = 14 }, -- Bone Shield
        { spell = 49576, type = "ability", requiresTarget = true }, -- Death Grip
        { spell = 49998, type = "ability", requiresTarget = true }, -- Death Strike
        { spell = 50842, type = "ability", requiresTarget = true }, -- Pestilence
        { spell = 50977, type = "ability", usable = true }, -- Death Gate
        { spell = 51052, type = "ability", talent = 68 }, -- Anti-Magic Zone
        { spell = 51271, type = "ability", buff = true, talent = 30 }, -- Pillar of Frost
        { spell = 55050, type = "ability", requiresTarget = true }, -- Heart Strike
        { spell = 55090, type = "ability", requiresTarget = true }, -- Scourge Strike
        { spell = 55233, type = "ability", buff = true, talent = 10 }, -- Vampiric Blood
        { spell = 56222, type = "ability", debuff = true, requiresTarget = true }, -- Dark Command
        { spell = 56815, type = "ability", requiresTarget = true, usable = true }, -- Rune Strike
        { spell = 57330, type = "ability", buff = true }, -- Horn of Winter
        { spell = 61999, type = "ability" }, -- Raise Ally
        { spell = 63560, type = "ability", buff = true, unit = 'pet', overlayGlow = true, usable = true, talent = 67 }, -- Dark Transformation
        { spell = 73975, type = "ability", debuff = true, requiresTarget = true }, -- Necrotic Strike
        { spell = 77575, type = "ability", requiresTarget = true }, -- Outbreak
        { spell = 77606, type = "ability", debuff = true, requiresTarget = true }, -- Dark Simulacrum
        { spell = 85948, type = "ability", requiresTarget = true }, -- Festering Strike
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
