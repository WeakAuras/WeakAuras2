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
    [19] = {name = POWER_TYPE_ESSENCE, icon = 4630437},
    [99] = {name = STAGGER, icon = "Interface\\Icons\\monk_stance_drunkenox"}
  }

-- Collected by WeakAurasTemplateCollector:
--------------------------------------------------------------------------------
templates.class.EVOKER = {
  [1] = { -- Devastation
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 236321, type = "buff", unit = "player" }, -- War Banner
        { spell = 357210, type = "buff", unit = "player" }, -- Deep Breath
        { spell = 358267, type = "buff", unit = "player" }, -- Hover
        { spell = 358733, type = "buff", unit = "player" }, -- Glide
        { spell = 359618, type = "buff", unit = "player", talent = 369297 }, -- Essence Burst
        { spell = 361509, type = "buff", unit = "player" }, -- Living Flame
        { spell = 363916, type = "buff", unit = "player", talent = 363916 }, -- Obsidian Scales
        { spell = 366646, type = "buff", unit = "player" }, -- Familiar Skies
        { spell = 370454, type = "buff", unit = "player", talent = 370455 }, -- Charged Blast
        { spell = 370553, type = "buff", unit = "player", talent = 370553 }, -- Tip the Scales
        { spell = 370562, type = "buff", unit = "player", talent = 370537 }, -- Stasis
        { spell = 370818, type = "buff", unit = "player", talent = 370783 }, -- Snapfire
        { spell = 370901, type = "buff", unit = "player", talent = 369939 }, -- Leaping Flames
        { spell = 372470, type = "buff", unit = "player", talent = 372469 }, -- Scarlet Adaptation
        { spell = 374227, type = "buff", unit = "player", talent = 374227 }, -- Zephyr
        { spell = 374348, type = "buff", unit = "player", talent = 374348 }, -- Renewing Blaze
        { spell = 375087, type = "buff", unit = "player", talent = 375087 }, -- Dragonrage
        { spell = 375234, type = "buff", unit = "player", talent = 374968 }, -- Time Spiral
        { spell = 375802, type = "buff", unit = "player", talent = 375801 }, -- Burnout
        { spell = 376850, type = "buff", unit = "player", talent = 370839 }, -- Power Swell
        { spell = 381748, type = "buff", unit = "player" }, -- Blessing of the Bronze
        { spell = 386353, type = "buff", unit = "player" }, -- Iridescence: Red
        { spell = 386399, type = "buff", unit = "player" }, -- Iridescence: Blue
        { spell = 390386, type = "buff", unit = "player" }, -- Fury of the Aspects
      },
      icon = 4622463
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 353759, type = "debuff", unit = "target" }, -- Deep Breath
        { spell = 355689, type = "debuff", unit = "target", talent = 358385 }, -- Landslide
        { spell = 356995, type = "debuff", unit = "target" }, -- Disintegrate
        { spell = 357209, type = "debuff", unit = "target" }, -- Fire Breath
        { spell = 357214, type = "debuff", unit = "target" }, -- Wing Buffet
        { spell = 360806, type = "debuff", unit = "target", talent = 360806 }, -- Sleep Walk
        { spell = 361500, type = "debuff", unit = "target" }, -- Living Flame
        { spell = 368970, type = "debuff", unit = "target" }, -- Tail Swipe
        { spell = 370452, type = "debuff", unit = "target", talent = 370452 }, -- Shattering Star
        { spell = 370898, type = "debuff", unit = "target", talent = 370897 }, -- Permeating Chill
        { spell = 372048, type = "debuff", unit = "target", talent = 372048 }, -- Oppressing Roar
        { spell = 372245, type = "debuff", unit = "target", talent = 371032 }, -- Terror of the Skies
      },
      icon = 4622458
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 351338, type = "ability", requiresTarget = true, talent = 351338 }, -- Quell
        { spell = 355913, type = "ability" }, -- Emerald Blossom
        { spell = 356995, type = "ability", overlayGlow = true, requiresTarget = true }, -- Disintegrate
        { spell = 357208, type = "ability", overlayGlow = true, talent = {-375783}, exactSpellId = true, titleSuffix = L["Max 3"] }, -- Fire Breath
        { spell = 382266, type = "ability", overlayGlow = true, talent = {375783}, exactSpellId = true, titleSuffix = L["Max 4"] }, -- Fire Breath
        { spell = 357210, type = "ability", buff = true }, -- Deep Breath
        { spell = 357211, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 357211 }, -- Pyre
        { spell = 357214, type = "ability" }, -- Wing Buffet
        { spell = 358267, type = "ability", charges = true, buff = true, overlayGlow = true }, -- Hover
        { spell = 358385, type = "ability", talent = 358385 }, -- Landslide
        { spell = 358733, type = "ability", buff = true }, -- Glide
        { spell = 359073, type = "ability", overlayGlow = true, requiresTarget = true, talent = {359073, -375783}, exactSpellId = true, titleSuffix = L["Max 3"] }, -- Eternity Surge
        { spell = 382411, type = "ability", overlayGlow = true, requiresTarget = true, talent = {359073, 375783}, exactSpellId = true, titleSuffix = L["Max 4"] }, -- Eternity Surge
        { spell = 360806, type = "ability", requiresTarget = true, talent = 360806 }, -- Sleep Walk
        { spell = 360995, type = "ability", requiresTarget = true, talent = 360995 }, -- Verdant Embrace
        { spell = 361469, type = "ability", requiresTarget = true }, -- Living Flame
        { spell = 361584, type = "ability" }, -- Whirling Surge
        { spell = 362969, type = "ability", requiresTarget = true }, -- Azure Strike
        { spell = 363916, type = "ability", charges = true, buff = true, talent = 363916 }, -- Obsidian Scales
        { spell = 364342, type = "ability" }, -- Blessing of the Bronze
        { spell = 365585, type = "ability", talent = 365585 }, -- Expunge
        { spell = 368432, type = "ability", overlayGlow = true, requiresTarget = true, talent = 368432 }, -- Unravel
        { spell = 368847, type = "ability", overlayGlow = true, talent = 368847 }, -- Firestorm
        { spell = 368970, type = "ability" }, -- Tail Swipe
        { spell = 369536, type = "ability", usable = true }, -- Soar
        { spell = 370452, type = "ability", requiresTarget = true, talent = 370452 }, -- Shattering Star
        { spell = 370553, type = "ability", buff = true, usable = true, talent = 370553 }, -- Tip the Scales
        { spell = 370665, type = "ability", talent = 370665 }, -- Rescue
        { spell = 372048, type = "ability", talent = 372048 }, -- Oppressing Roar
        { spell = 372608, type = "ability" }, -- Surge Forward
        { spell = 372610, type = "ability" }, -- Skyward Ascent
        { spell = 374227, type = "ability", buff = true, talent = 374227 }, -- Zephyr
        { spell = 374251, type = "ability", talent = 374251 }, -- Cauterizing Flame
        { spell = 374348, type = "ability", buff = true, talent = 374348 }, -- Renewing Blaze
        { spell = 374968, type = "ability", talent = 374968 }, -- Time Spiral
        { spell = 375087, type = "ability", buff = true, talent = 375087 }, -- Dragonrage
        { spell = 383332, type = "ability" }, -- Time Stop
        { spell = 390386, type = "ability", buff = true }, -- Fury of the Aspects
      },
      icon = 4622452
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
        { spell = 378441, type = "buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"] }, -- Time Stop
        { spell = 378464, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Nullifying Shroud
        { spell = 383005, type = "debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"] }, -- Chrono Loop
        { spell = 378441, type = "ability", buff = true, pvptalent = 5, titleSuffix = L["cooldown"] }, -- Time Stop
        { spell = 378464, type = "ability", buff = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Nullifying Shroud
        { spell = 383005, type = "ability", requiresTarget = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Chrono Loop
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
  [2] = { -- Preservation
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 357170, type = "buff", unit = "player", talent = 357170 }, -- Time Dilation
        { spell = 357210, type = "buff", unit = "player" }, -- Deep Breath
        { spell = 358134, type = "buff", unit = "player" }, -- Star Burst
        { spell = 358267, type = "buff", unit = "player" }, -- Hover
        { spell = 358733, type = "buff", unit = "player" }, -- Glide
        { spell = 359816, type = "buff", unit = "player", talent = 359816 }, -- Dream Flight
        { spell = 362877, type = "buff", unit = "player", talent = 362874 }, -- Temporal Compression
        { spell = 363534, type = "buff", unit = "player", talent = 363534 }, -- Rewind
        { spell = 363916, type = "buff", unit = "player", talent = 363916 }, -- Obsidian Scales
        { spell = 364343, type = "buff", unit = "player", talent = 364343 }, -- Echo
        { spell = 366155, type = "buff", unit = "player", talent = 366155 }, -- Reversion
        { spell = 366646, type = "buff", unit = "player" }, -- Familiar Skies
        { spell = 369299, type = "buff", unit = "player", talent = 369297 }, -- Essence Burst
        { spell = 369536, type = "buff", unit = "player" }, -- Soar
        { spell = 370454, type = "buff", unit = "player", talent = 370455 }, -- Charged Blast
        { spell = 370537, type = "buff", unit = "player", talent = 370537 }, -- Stasis
        { spell = 370553, type = "buff", unit = "player", talent = 370553 }, -- Tip the Scales
        { spell = 370840, type = "buff", unit = "player", talent = 376138 }, -- Empath
        { spell = 370901, type = "buff", unit = "player", talent = 369939 }, -- Leaping Flames
        { spell = 370960, type = "buff", unit = "player", talent = 370960 }, -- Emerald Communion
        { spell = 372014, type = "buff", unit = "player" }, -- Visage
        { spell = 372470, type = "buff", unit = "player", talent = 372469 }, -- Scarlet Adaptation
        { spell = 373267, type = "buff", unit = "player", talent = 373270 }, -- Lifebind
        { spell = 373835, type = "buff", unit = "player", talent = 373834 }, -- Call of Ysera
        { spell = 374227, type = "buff", unit = "player", talent = 374227 }, -- Zephyr
        { spell = 374348, type = "buff", unit = "player", talent = 374348 }, -- Renewing Blaze
        { spell = 375234, type = "buff", unit = "player", talent = 374968 }, -- Time Spiral
        { spell = 375583, type = "buff", unit = "player", talent = 369990 }, -- Ancient Flame
        { spell = 377088, type = "buff", unit = "player", talent = 377086 }, -- Rush of Vitality
        { spell = 377102, type = "buff", unit = "player", talent = 377100 }, -- Exhilarating Burst
        { spell = 378001, type = "buff", unit = "player" }, -- Dream Projection
        { spell = 381748, type = "buff", unit = "player" }, -- Blessing of the Bronze
        { spell = 387350, type = "buff", unit = "player", talent = 381921 }, -- Ouroboros
        { spell = 390148, type = "buff", unit = "player", talent = 385696 }, -- Flow State
        { spell = 390386, type = "buff", unit = "player" }, -- Fury of the Aspects
      },
      icon = 4630476
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 353759, type = "debuff", unit = "target" }, -- Deep Breath
        { spell = 355689, type = "debuff", unit = "target", talent = 358385 }, -- Landslide
        { spell = 356995, type = "debuff", unit = "target" }, -- Disintegrate
        { spell = 357209, type = "debuff", unit = "target" }, -- Fire Breath
        { spell = 357214, type = "debuff", unit = "target" }, -- Wing Buffet
        { spell = 360806, type = "debuff", unit = "target", talent = 360806 }, -- Sleep Walk
        { spell = 368970, type = "debuff", unit = "target" }, -- Tail Swipe
        { spell = 370898, type = "debuff", unit = "target", talent = 370897 }, -- Permeating Chill
        { spell = 372245, type = "debuff", unit = "target", talent = 371032 }, -- Terror of the Skies
      },
      icon = 4622488
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 351338, type = "ability", requiresTarget = true, talent = 351338 }, -- Quell
        { spell = 355913, type = "ability", overlayGlow = true }, -- Emerald Blossom
        { spell = 355936, type = "ability", overlayGlow = true, talent = {355936, -375783}, exactSpellId = true, titleSuffix = L["Max 3"] }, -- Dream Breath
        { spell = 382614, type = "ability", overlayGlow = true, talent = {355936, 375783}, exactSpellId = true, titleSuffix = L["Max 4"] }, -- Dream Breath
        { spell = 356995, type = "ability", overlayGlow = true, requiresTarget = true }, -- Disintegrate
        { spell = 357170, type = "ability", buff = true, debuff = true, talent = 357170 }, -- Time Dilation
        { spell = 357208, type = "ability", overlayGlow = true, talent = {-375783}, exactSpellId = true, titleSuffix = L["Max 3"] }, -- Fire Breath
        { spell = 382266, type = "ability", overlayGlow = true, talent = {375783}, exactSpellId = true, titleSuffix = L["Max 4"] }, -- Fire Breath
        { spell = 357210, type = "ability", buff = true }, -- Deep Breath
        { spell = 357214, type = "ability" }, -- Wing Buffet
        { spell = 358267, type = "ability", charges = true, buff = true, overlayGlow = true }, -- Hover
        { spell = 358385, type = "ability", talent = 358385 }, -- Landslide
        { spell = 358733, type = "ability", buff = true }, -- Glide
        { spell = 359816, type = "ability", buff = true, talent = 359816 }, -- Dream Flight
        { spell = 360806, type = "ability", requiresTarget = true, talent = 360806 }, -- Sleep Walk
        { spell = 360823, type = "ability" }, -- Naturalize
        { spell = 360995, type = "ability", requiresTarget = true, talent = 360995 }, -- Verdant Embrace
        { spell = 361469, type = "ability", requiresTarget = true }, -- Living Flame
        { spell = 362969, type = "ability", requiresTarget = true }, -- Azure Strike
        { spell = 363534, type = "ability", charges = true, buff = true, debuff = true, talent = 363534 }, -- Rewind
        { spell = 363916, type = "ability", buff = true, talent = 363916 }, -- Obsidian Scales
        { spell = 364342, type = "ability" }, -- Blessing of the Bronze
        { spell = 364343, type = "ability", buff = true, debuff = true, overlayGlow = true, talent = 364343 }, -- Echo
        { spell = 366155, type = "ability", charges = true, buff = true, talent = 366155 }, -- Reversion
        { spell = 368970, type = "ability" }, -- Tail Swipe
        { spell = 369536, type = "ability", buff = true, usable = true }, -- Soar
        { spell = 370537, type = "ability", buff = true, usable = true, talent = 370537 }, -- Stasis
        { spell = 370553, type = "ability", buff = true, usable = true, talent = 370553 }, -- Tip the Scales
        { spell = 370665, type = "ability", talent = 370665 }, -- Rescue
        { spell = 370960, type = "ability", buff = true, talent = 370960 }, -- Emerald Communion
        { spell = 373861, type = "ability", talent = 373861 }, -- Temporal Anomaly
        { spell = 374227, type = "ability", buff = true, talent = 374227 }, -- Zephyr
        { spell = 374251, type = "ability", talent = 374251 }, -- Cauterizing Flame
        { spell = 374348, type = "ability", buff = true, talent = 374348 }, -- Renewing Blaze
        { spell = 374968, type = "ability", talent = 374968 }, -- Time Spiral
        { spell = 376743, type = "ability", charges = true }, -- Surge Forward
        { spell = 376744, type = "ability" }, -- Skyward Ascent
        { spell = 367226, type = "ability", overlayGlow = true, talent = {367226, -375783 }, exactSpellId = true, titleSuffix = L["Max 3"] }, -- Spiritbloom
        { spell = 382731, type = "ability", overlayGlow = true, talent = {367226, 375783 }, exactSpellId = true, titleSuffix = L["Max 4"] }, -- Spiritbloom
        { spell = 390386, type = "ability", buff = true }, -- Fury of the Aspects
      },
      icon = 4622474
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
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  }
}

templates.class.WARRIOR = {
  [1] = { -- Arms
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 6673, type = "buff", unit = "player" }, -- Battle Shout
        { spell = 7384, type = "buff", unit = "player", talent = 7384 }, -- Overpower
        { spell = 18499, type = "buff", unit = "player", talent = 18499 }, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player", talent = 23920 }, -- Spell Reflection
        { spell = 52437, type = "buff", unit = "player", talent = 29725 }, -- Sudden Death
        { spell = 97463, type = "buff", unit = "player", talent = 97462 }, -- Rallying Cry
        { spell = 107574, type = "buff", unit = "player", talent = 107574 }, -- Avatar
        { spell = 118038, type = "buff", unit = "player", talent = 118038 }, -- Die by the Sword
        { spell = 132404, type = "buff", unit = "player" }, -- Shield Block
        { spell = 202164, type = "buff", unit = "player", talent = 202163 }, -- Bounding Stride
        { spell = 227847, type = "buff", unit = "player", talent = 227847 }, -- Bladestorm
        { spell = 260708, type = "buff", unit = "player", talent = 260708 }, -- Sweeping Strikes
        { spell = 351077, type = "buff", unit = "player", talent = 29838 }, -- Second Wind
        { spell = 383290, type = "buff", unit = "player", talent = 383292 }, -- Juggernaut
        { spell = 383316, type = "buff", unit = "player", talent = 383317 }, -- Merciless Bonegrinder
        { spell = 385013, type = "buff", unit = "player", talent = 385008 }, -- Test of Might
        { spell = 386164, type = "buff", unit = "player", talent = 386164 }, -- Battle Stance
        { spell = 386208, type = "buff", unit = "player", talent = 386208 }, -- Defensive Stance
        { spell = 386631, type = "buff", unit = "player", talent = 386630 }, -- Battlelord
        { spell = 390581, type = "buff", unit = "player", talent = 390563 }, -- Hurricane
        { spell = 392778, type = "buff", unit = "player", talent = 382946 }, -- Wild Strikes
        { spell = 147833, type = "buff", unit = "target", talent = 3411 }, -- Intervene
      },
      icon = 132333
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target", talent = 5246 }, -- Intimidating Shout
        { spell = 6343, type = "debuff", unit = "target", talent = 6343 }, -- Thunder Clap
        { spell = 12323, type = "debuff", unit = "target", talent = 12323 }, -- Piercing Howl
        { spell = 105771, type = "debuff", unit = "target" }, -- Charge
        { spell = 115804, type = "debuff", unit = "target" }, -- Mortal Wounds
        { spell = 132168, type = "debuff", unit = "target", talent = 46968 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 107570 }, -- Storm Bolt
        { spell = 208086, type = "debuff", unit = "target", talent = 167105 }, -- Colossus Smash
        { spell = 262115, type = "debuff", unit = "target" }, -- Deep Wounds
        { spell = 376080, type = "debuff", unit = "target", talent = 376079 }, -- Spear of Bastion
        { spell = 383704, type = "debuff", unit = "target" }, -- Fatal Mark
        { spell = 384318, type = "debuff", unit = "target", talent = 384318 }, -- Thunderous Roar
        { spell = 386633, type = "debuff", unit = "target", talent = 386634 }, -- Executioner's Precision
        { spell = 388539, type = "debuff", unit = "target", talent = 772 }, -- Rend
      },
      icon = 132366
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability", charges = true, requiresTarget = true }, -- Charge
        { spell = 355, type = "ability", requiresTarget = true }, -- Taunt
        { spell = 772, type = "ability", requiresTarget = true, talent = 772 }, -- Rend
        { spell = 845, type = "ability", overlayGlow = true, usable = true, talent = 845 }, -- Cleave
        { spell = 1464, type = "ability", requiresTarget = true }, -- Slam
        { spell = 1715, type = "ability", requiresTarget = true }, -- Hamstring
        { spell = 2565, type = "ability", usable = true }, -- Shield Block
        { spell = 3411, type = "ability", talent = 3411 }, -- Intervene
        { spell = 5246, type = "ability", requiresTarget = true, talent = 5246 }, -- Intimidating Shout
        { spell = 6343, type = "ability", talent = 6343 }, -- Thunder Clap
        { spell = 6544, type = "ability", talent = 6544 }, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true }, -- Pummel
        { spell = 6673, type = "ability", buff = true }, -- Battle Shout
        { spell = 7384, type = "ability", charges = true, buff = true, overlayGlow = true, requiresTarget = true, talent = 7384 }, -- Overpower
        { spell = 12294, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 12294 }, -- Mortal Strike
        { spell = 12323, type = "ability", talent = 12323 }, -- Piercing Howl
        { spell = 18499, type = "ability", buff = true, talent = 18499 }, -- Berserker Rage
        { spell = 23920, type = "ability", buff = true, talent = 23920 }, -- Spell Reflection
        { spell = 23922, type = "ability", requiresTarget = true, usable = true }, -- Shield Slam
        { spell = 34428, type = "ability", requiresTarget = true, usable = true }, -- Victory Rush
        { spell = 46968, type = "ability", talent = 46968 }, -- Shockwave
        { spell = 57755, type = "ability", requiresTarget = true }, -- Heroic Throw
        { spell = 64382, type = "ability", requiresTarget = true, talent = 64382 }, -- Shattering Throw
        { spell = 97462, type = "ability", talent = 97462 }, -- Rallying Cry
        { spell = 107570, type = "ability", requiresTarget = true, talent = 107570 }, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true, talent = 107574 }, -- Avatar
        { spell = 118038, type = "ability", buff = true, talent = 118038 }, -- Die by the Sword
        { spell = 163201, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Execute
        { spell = 227847, type = "ability", buff = true, talent = 227847 }, -- Bladestorm
        { spell = 260643, type = "ability", requiresTarget = true, talent = 260643 }, -- Skullsplitter
        { spell = 260708, type = "ability", buff = true, talent = 260708 }, -- Sweeping Strikes
        { spell = 262161, type = "ability", talent = 262161 }, -- Warbreaker
        { spell = 376079, type = "ability", talent = 376079 }, -- Spear of Bastion
        { spell = 383762, type = "ability", talent = 383762 }, -- Bitter Immunity
        { spell = 384318, type = "ability", talent = 384318 }, -- Thunderous Roar
        { spell = 386164, type = "ability", buff = true, talent = 386164 }, -- Battle Stance
        { spell = 386208, type = "ability", buff = true, talent = 386208 }, -- Defensive Stance
        { spell = 394062, type = "ability", requiresTarget = true, talent = 394062 }, -- Rend
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
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 1719, type = "buff", unit = "player", talent = 1719 }, -- Recklessness
        { spell = 6673, type = "buff", unit = "player" }, -- Battle Shout
        { spell = 18499, type = "buff", unit = "player", talent = 18499 }, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player", talent = 23920 }, -- Spell Reflection
        { spell = 85739, type = "buff", unit = "player" }, -- Whirlwind
        { spell = 97463, type = "buff", unit = "player", talent = 97462 }, -- Rallying Cry
        { spell = 107574, type = "buff", unit = "player", talent = 107574 }, -- Avatar
        { spell = 132404, type = "buff", unit = "player" }, -- Shield Block
        { spell = 184362, type = "buff", unit = "player" }, -- Enrage
        { spell = 184364, type = "buff", unit = "player", talent = 184364 }, -- Enraged Regeneration
        { spell = 202164, type = "buff", unit = "player", talent = 202163 }, -- Bounding Stride
        { spell = 202602, type = "buff", unit = "player", talent = 202603 }, -- Into the Fray
        { spell = 280776, type = "buff", unit = "player", talent = 280721 }, -- Sudden Death
        { spell = 311193, type = "buff", unit = "player", talent = 386285 }, -- Elysian Might
        { spell = 335082, type = "buff", unit = "player", talent = 335077 }, -- Frenzy
        { spell = 351077, type = "buff", unit = "player", talent = 29838 }, -- Second Wind
        { spell = 386196, type = "buff", unit = "player", talent = 386196 }, -- Berserker Stance
        { spell = 386208, type = "buff", unit = "player", talent = 386208 }, -- Defensive Stance
        { spell = 391688, type = "buff", unit = "player", talent = 391683 }, -- Dancing Blades
        { spell = 392537, type = "buff", unit = "player", talent = 392536 }, -- Ashen Juggernaut
        { spell = 392778, type = "buff", unit = "player", talent = 382946 }, -- Wild Strikes
        { spell = 393931, type = "buff", unit = "player", talent = 388004 }, -- Slaughtering Strikes
        { spell = 393951, type = "buff", unit = "player", talent = 393950 }, -- Bloodcraze
        { spell = 147833, type = "buff", unit = "target", talent = 3411 }, -- Intervene
      },
      icon = 136224
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target", talent = 5246 }, -- Intimidating Shout
        { spell = 6343, type = "debuff", unit = "target", talent = 6343 }, -- Thunder Clap
        { spell = 12323, type = "debuff", unit = "target", talent = 12323 }, -- Piercing Howl
        { spell = 105771, type = "debuff", unit = "target" }, -- Charge
        { spell = 132168, type = "debuff", unit = "target", talent = 46968 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 107570 }, -- Storm Bolt
        { spell = 376080, type = "debuff", unit = "target", talent = 376079 }, -- Spear of Bastion
        { spell = 384318, type = "debuff", unit = "target", talent = 384318 }, -- Thunderous Roar
        { spell = 385042, type = "debuff", unit = "target" }, -- Gushing Wound
        { spell = 385060, type = "debuff", unit = "target", talent = 385059 }, -- Odyn's Fury
      },
      icon = 132154
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability", charges = true, requiresTarget = true }, -- Charge
        { spell = 355, type = "ability", requiresTarget = true }, -- Taunt
        { spell = 1464, type = "ability", requiresTarget = true }, -- Slam
        { spell = 1715, type = "ability", requiresTarget = true }, -- Hamstring
        { spell = 1719, type = "ability", buff = true, talent = 1719 }, -- Recklessness
        { spell = 2565, type = "ability", charges = true, usable = true }, -- Shield Block
        { spell = 3411, type = "ability", talent = 3411 }, -- Intervene
        { spell = 5246, type = "ability", requiresTarget = true, talent = 5246 }, -- Intimidating Shout
        { spell = 5308, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Execute
        { spell = 6343, type = "ability", talent = 6343 }, -- Thunder Clap
        { spell = 6544, type = "ability", talent = 6544 }, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true }, -- Pummel
        { spell = 6673, type = "ability", buff = true }, -- Battle Shout
        { spell = 12323, type = "ability", talent = 12323 }, -- Piercing Howl
        { spell = 18499, type = "ability", buff = true, talent = 18499 }, -- Berserker Rage
        { spell = 23881, type = "ability", requiresTarget = true, talent = 23881 }, -- Bloodthirst
        { spell = 23920, type = "ability", buff = true, talent = 23920 }, -- Spell Reflection
        { spell = 23922, type = "ability", requiresTarget = true, usable = true }, -- Shield Slam
        { spell = 34428, type = "ability", requiresTarget = true }, -- Victory Rush
        { spell = 46968, type = "ability", talent = 46968 }, -- Shockwave
        { spell = 57755, type = "ability", requiresTarget = true }, -- Heroic Throw
        { spell = 85288, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 85288 }, -- Raging Blow
        { spell = 97462, type = "ability", talent = 97462 }, -- Rallying Cry
        { spell = 107570, type = "ability", requiresTarget = true, talent = 107570 }, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true, talent = 107574 }, -- Avatar
        { spell = 184364, type = "ability", buff = true, talent = 184364 }, -- Enraged Regeneration
        { spell = 184367, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 184367 }, -- Rampage
        { spell = 190411, type = "ability" }, -- Whirlwind
        { spell = 202168, type = "ability", requiresTarget = true, talent = 202168 }, -- Impending Victory
        { spell = 228920, type = "ability", charges = true, talent = 228920 }, -- Ravager
        { spell = 280735, type = "ability", overlayGlow = true, requiresTarget = true }, -- Execute
        { spell = 315720, type = "ability", requiresTarget = true, usable = true, talent = 315720 }, -- Onslaught
        { spell = 376079, type = "ability", talent = 376079 }, -- Spear of Bastion
        { spell = 383762, type = "ability", talent = 383762 }, -- Bitter Immunity
        { spell = 384110, type = "ability", requiresTarget = true, talent = 384110 }, -- Wrecking Throw
        { spell = 384318, type = "ability", talent = 384318 }, -- Thunderous Roar
        { spell = 385059, type = "ability", talent = 385059 }, -- Odyn's Fury
        { spell = 386196, type = "ability", buff = true, talent = 386196 }, -- Berserker Stance
        { spell = 386208, type = "ability", buff = true, talent = 386208 }, -- Defensive Stance
        { spell = 396719, type = "ability", talent = 396719 }, -- Thunder Clap
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
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 871, type = "buff", unit = "player", talent = 871 }, -- Shield Wall
        { spell = 6673, type = "buff", unit = "player" }, -- Battle Shout
        { spell = 12975, type = "buff", unit = "player", talent = 12975 }, -- Last Stand
        { spell = 18499, type = "buff", unit = "player", talent = 18499 }, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player", talent = 23920 }, -- Spell Reflection
        { spell = 52437, type = "buff", unit = "player", talent = 29725 }, -- Sudden Death
        { spell = 97463, type = "buff", unit = "player", talent = 97462 }, -- Rallying Cry
        { spell = 132404, type = "buff", unit = "player" }, -- Shield Block
        { spell = 190456, type = "buff", unit = "player", talent = 190456 }, -- Ignore Pain
        { spell = 202164, type = "buff", unit = "player", talent = 202163 }, -- Bounding Stride
        { spell = 202602, type = "buff", unit = "player", talent = 202603 }, -- Into the Fray
        { spell = 351077, type = "buff", unit = "player", talent = 29838 }, -- Second Wind
        { spell = 383290, type = "buff", unit = "player", talent = 393967 }, -- Juggernaut
        { spell = 385842, type = "buff", unit = "player", talent = 385843 }, -- Show of Force
        { spell = 386029, type = "buff", unit = "player", talent = 386030 }, -- Brace For Impact
        { spell = 386164, type = "buff", unit = "player", talent = 386164 }, -- Battle Stance
        { spell = 386208, type = "buff", unit = "player", talent = 386208 }, -- Defensive Stance
        { spell = 386478, type = "buff", unit = "player", talent = 386477 }, -- Violent Outburst
        { spell = 386486, type = "buff", unit = "player" }, -- Seeing Red
        { spell = 392778, type = "buff", unit = "player", talent = 382946 }, -- Wild Strikes
      },
      icon = 1377132
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1160, type = "debuff", unit = "target", talent = 1160 }, -- Demoralizing Shout
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target", talent = 5246 }, -- Intimidating Shout
        { spell = 6343, type = "debuff", unit = "target", talent = 6343 }, -- Thunder Clap
        { spell = 12323, type = "debuff", unit = "target", talent = 12323 }, -- Piercing Howl
        { spell = 105771, type = "debuff", unit = "target" }, -- Charge
        { spell = 115767, type = "debuff", unit = "target" }, -- Deep Wounds
        { spell = 132168, type = "debuff", unit = "target", talent = 46968 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 107570 }, -- Storm Bolt
        { spell = 376080, type = "debuff", unit = "target", talent = 376079 }, -- Spear of Bastion
        { spell = 384318, type = "debuff", unit = "target", talent = 384318 }, -- Thunderous Roar
        { spell = 385954, type = "debuff", unit = "target", talent = 385952 }, -- Shield Charge
        { spell = 386071, type = "debuff", unit = "target", talent = 386071 }, -- Disrupting Shout
      },
      icon = 132090
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability", charges = true, requiresTarget = true }, -- Charge
        { spell = 355, type = "ability", requiresTarget = true }, -- Taunt
        { spell = 772, type = "ability", requiresTarget = true, talent = 772 }, -- Rend
        { spell = 871, type = "ability", charges = true, buff = true, talent = 871 }, -- Shield Wall
        { spell = 1160, type = "ability", talent = 1160 }, -- Demoralizing Shout
        { spell = 1464, type = "ability", requiresTarget = true }, -- Slam
        { spell = 1715, type = "ability", requiresTarget = true }, -- Hamstring
        { spell = 2565, type = "ability", charges = true }, -- Shield Block
        { spell = 3411, type = "ability", talent = 3411 }, -- Intervene
        { spell = 5246, type = "ability", requiresTarget = true, talent = 5246 }, -- Intimidating Shout
        { spell = 6343, type = "ability", talent = 6343 }, -- Thunder Clap
        { spell = 6544, type = "ability", talent = 6544 }, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true }, -- Pummel
        { spell = 6673, type = "ability", buff = true }, -- Battle Shout
        { spell = 12323, type = "ability", talent = 12323 }, -- Piercing Howl
        { spell = 12975, type = "ability", buff = true, talent = 12975 }, -- Last Stand
        { spell = 18499, type = "ability", buff = true, talent = 18499 }, -- Berserker Rage
        { spell = 20243, type = "ability", requiresTarget = true }, -- Devastate
        { spell = 23920, type = "ability", buff = true, talent = 23920 }, -- Spell Reflection
        { spell = 23922, type = "ability", overlayGlow = true, requiresTarget = true }, -- Shield Slam
        { spell = 34428, type = "ability", requiresTarget = true, usable = true }, -- Victory Rush
        { spell = 46968, type = "ability", talent = 46968 }, -- Shockwave
        { spell = 57755, type = "ability", requiresTarget = true }, -- Heroic Throw
        { spell = 64382, type = "ability", requiresTarget = true, talent = 64382 }, -- Shattering Throw
        { spell = 97462, type = "ability", talent = 97462 }, -- Rallying Cry
        { spell = 107570, type = "ability", requiresTarget = true, talent = 107570 }, -- Storm Bolt
        { spell = 163201, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Execute
        { spell = 190456, type = "ability", buff = true, talent = 190456 }, -- Ignore Pain
        { spell = 202168, type = "ability", requiresTarget = true, talent = 202168 }, -- Impending Victory
        { spell = 228920, type = "ability", charges = true, talent = 228920 }, -- Ravager
        { spell = 281000, type = "ability", requiresTarget = true }, -- Execute
        { spell = 376079, type = "ability", talent = 376079 }, -- Spear of Bastion
        { spell = 383762, type = "ability", talent = 383762 }, -- Bitter Immunity
        { spell = 384090, type = "ability", requiresTarget = true, talent = 384090 }, -- Titanic Throw
        { spell = 384110, type = "ability", requiresTarget = true, talent = 384110 }, -- Wrecking Throw
        { spell = 384318, type = "ability", talent = 384318 }, -- Thunderous Roar
        { spell = 385952, type = "ability", requiresTarget = true, talent = 385952 }, -- Shield Charge
        { spell = 386071, type = "ability", talent = 386071 }, -- Disrupting Shout
        { spell = 386164, type = "ability", buff = true, talent = 386164 }, -- Battle Stance
        { spell = 386208, type = "ability", buff = true, talent = 386208 }, -- Defensive Stance
        { spell = 394062, type = "ability", requiresTarget = true, talent = 394062 }, -- Rend
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
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 465, type = "buff", unit = "player" }, -- Devotion Aura
        { spell = 498, type = "buff", unit = "player", talent = 498 }, -- Divine Protection
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "player", talent = 1022 }, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "player", talent = 1044 }, -- Blessing of Freedom
        { spell = 5502, type = "buff", unit = "player" }, -- Sense Undead
        { spell = 31821, type = "buff", unit = "player", talent = 31821 }, -- Aura Mastery
        { spell = 31884, type = "buff", unit = "player", talent = 384376 }, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player" }, -- Crusader Aura
        { spell = 53563, type = "buff", unit = "player" }, -- Beacon of Light
        { spell = 54149, type = "buff", unit = "player" }, -- Infusion of Light
        { spell = 105809, type = "buff", unit = "player", talent = 105809 }, -- Holy Avenger
        { spell = 148039, type = "buff", unit = "player", talent = 148039 }, -- Barrier of Faith
        { spell = 152262, type = "buff", unit = "player", talent = 152262 }, -- Seraphim
        { spell = 183435, type = "buff", unit = "player" }, -- Retribution Aura
        { spell = 200025, type = "buff", unit = "player", talent = 200025 }, -- Beacon of Virtue
        { spell = 200652, type = "buff", unit = "player", talent = 200652 }, -- Tyr's Deliverance
        { spell = 200656, type = "buff", unit = "player", talent = 200474 }, -- Power of the Silver Hand
        { spell = 210294, type = "buff", unit = "player", talent = 210294 }, -- Divine Favor
        { spell = 210391, type = "buff", unit = "player" }, -- Darkest before the Dawn
        { spell = 214202, type = "buff", unit = "player", talent = 214202 }, -- Rule of Law
        { spell = 216331, type = "buff", unit = "player", talent = 394088 }, -- Avenging Crusader
        { spell = 221886, type = "buff", unit = "player", talent = 190784 }, -- Divine Steed
        { spell = 223306, type = "buff", unit = "player", talent = 223306 }, -- Bestow Faith
        { spell = 223819, type = "buff", unit = "player", talent = 223817 }, -- Divine Purpose
        { spell = 317920, type = "buff", unit = "player" }, -- Concentration Aura
        { spell = 385126, type = "buff", unit = "player" }, -- Blessing of Dusk
        { spell = 385127, type = "buff", unit = "player" }, -- Blessing of Dawn
        { spell = 387178, type = "buff", unit = "player", talent = 387170 }, -- Empyrean Legacy
        { spell = 387480, type = "buff", unit = "player", talent = 387479 }, -- Sanctified Ground
        { spell = 387895, type = "buff", unit = "player", talent = 387893 }, -- Divine Resonance
        { spell = 388007, type = "buff", unit = "player", talent = 388007 }, -- Blessing of Summer
        { spell = 394709, type = "buff", unit = "player", talent = 387998 }, -- Unending Light
      },
      icon = 135964
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 115750 }, -- Blinding Light
        { spell = 196941, type = "debuff", unit = "target", talent = 183778 }, -- Judgment of Light
        { spell = 197277, type = "debuff", unit = "target" }, -- Judgment
        { spell = 204242, type = "debuff", unit = "target" }, -- Consecration
        { spell = 287280, type = "debuff", unit = "target", talent = 325966 }, -- Glimmer of Light
        { spell = 385723, type = "debuff", unit = "target", talent = 385728 }, -- Seal of the Crusader
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 498, type = "ability", buff = true, talent = 498 }, -- Divine Protection
        { spell = 633, type = "ability", talent = 633 }, -- Lay on Hands
        { spell = 642, type = "ability", buff = true, usable = true }, -- Divine Shield
        { spell = 853, type = "ability", requiresTarget = true }, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true, talent = 1022 }, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true, talent = 1044 }, -- Blessing of Freedom
        { spell = 10326, type = "ability", talent = 10326 }, -- Turn Evil
        { spell = 20066, type = "ability", talent = 20066 }, -- Repentance
        { spell = 20473, type = "ability", requiresTarget = true, talent = 20473 }, -- Holy Shock
        { spell = 24275, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 24275 }, -- Hammer of Wrath
        { spell = 26573, type = "ability", totem = true }, -- Consecration
        { spell = 31821, type = "ability", buff = true, talent = 31821 }, -- Aura Mastery
        { spell = 31884, type = "ability", buff = true, talent = 384376 }, -- Avenging Wrath
        { spell = 35395, type = "ability", charges = true, requiresTarget = true }, -- Crusader Strike
        { spell = 62124, type = "ability", requiresTarget = true }, -- Hand of Reckoning
        { spell = 96231, type = "ability", requiresTarget = true, talent = 96231 }, -- Rebuke
        { spell = 105809, type = "ability", buff = true, talent = 105809 }, -- Holy Avenger
        { spell = 114158, type = "ability", talent = 114158 }, -- Light's Hammer
        { spell = 115750, type = "ability", talent = 115750 }, -- Blinding Light
        { spell = 148039, type = "ability", buff = true, talent = 148039 }, -- Barrier of Faith
        { spell = 152262, type = "ability", buff = true, talent = 152262 }, -- Seraphim
        { spell = 190784, type = "ability", charges = true, talent = 190784 }, -- Divine Steed
        { spell = 200025, type = "ability", buff = true, talent = 200025 }, -- Beacon of Virtue
        { spell = 200652, type = "ability", buff = true, talent = 200652 }, -- Tyr's Deliverance
        { spell = 210294, type = "ability", buff = true, usable = true, talent = 210294 }, -- Divine Favor
        { spell = 214202, type = "ability", charges = true, buff = true, talent = 214202 }, -- Rule of Law
        { spell = 216331, type = "ability", buff = true, talent = 394088 }, -- Avenging Crusader
        { spell = 223306, type = "ability", buff = true, talent = 223306 }, -- Bestow Faith
        { spell = 275773, type = "ability", charges = true, requiresTarget = true }, -- Judgment
        { spell = 375576, type = "ability", requiresTarget = true, talent = 375576 }, -- Divine Toll
        { spell = 388007, type = "ability", buff = true, talent = 388007 }, -- Blessing of Summer
        { spell = 388010, type = "ability" }, -- Blessing of Autumn
        { spell = 391054, type = "ability" }, -- Intercession
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
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 465, type = "buff", unit = "player" }, -- Devotion Aura
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "player", talent = 1022 }, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "player", talent = 1044 }, -- Blessing of Freedom
        { spell = 5502, type = "buff", unit = "player" }, -- Sense Undead
        { spell = 31850, type = "buff", unit = "player", talent = 31850 }, -- Ardent Defender
        { spell = 31884, type = "buff", unit = "player", talent = 384376 }, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player" }, -- Crusader Aura
        { spell = 105809, type = "buff", unit = "player", talent = 105809 }, -- Holy Avenger
        { spell = 132403, type = "buff", unit = "player" }, -- Shield of the Righteous
        { spell = 152262, type = "buff", unit = "player", talent = 152262 }, -- Seraphim
        { spell = 182104, type = "buff", unit = "player", talent = 321136 }, -- Shining Light
        { spell = 183435, type = "buff", unit = "player" }, -- Retribution Aura
        { spell = 188370, type = "buff", unit = "player" }, -- Consecration
        { spell = 209388, type = "buff", unit = "player", talent = 209389 }, -- Bulwark of Order
        { spell = 210391, type = "buff", unit = "player" }, -- Darkest before the Dawn
        { spell = 221886, type = "buff", unit = "player", talent = 190784 }, -- Divine Steed
        { spell = 223819, type = "buff", unit = "player", talent = 223817 }, -- Divine Purpose
        { spell = 280375, type = "buff", unit = "player", talent = 280373 }, -- Redoubt
        { spell = 317920, type = "buff", unit = "player" }, -- Concentration Aura
        { spell = 327193, type = "buff", unit = "player", talent = 327193 }, -- Moment of Glory
        { spell = 378412, type = "buff", unit = "player", talent = 378405 }, -- Light of the Titans
        { spell = 378974, type = "buff", unit = "player", talent = 378974 }, -- Bastion of Light
        { spell = 379041, type = "buff", unit = "player", talent = 379043 }, -- Faith in the Light
        { spell = 383389, type = "buff", unit = "player", talent = 383388 }, -- Relentless Inquisitor
        { spell = 385126, type = "buff", unit = "player" }, -- Blessing of Dusk
        { spell = 385127, type = "buff", unit = "player" }, -- Blessing of Dawn
        { spell = 385417, type = "buff", unit = "player", talent = 385416 }, -- Aspiration of Divinity
        { spell = 385724, type = "buff", unit = "player", talent = 385726 }, -- Barricade of Faith
        { spell = 386556, type = "buff", unit = "player", talent = 386568 }, -- Inner Light
        { spell = 387480, type = "buff", unit = "player" }, -- Sanctified Ground
        { spell = 389539, type = "buff", unit = "player", talent = 385438 }, -- Sentinel
        { spell = 393019, type = "buff", unit = "player", talent = 393022 }, -- Inspiring Vanguard
      },
      icon = 236265
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 31935, type = "debuff", unit = "target", talent = 31935 }, -- Avenger's Shield
        { spell = 105421, type = "debuff", unit = "target", talent = 115750 }, -- Blinding Light
        { spell = 197277, type = "debuff", unit = "target" }, -- Judgment
        { spell = 204242, type = "debuff", unit = "target" }, -- Consecration
        { spell = 204301, type = "debuff", unit = "target", talent = 204019 }, -- Blessed Hammer
        { spell = 206891, type = "debuff", unit = "target" }, -- Focused Assault
        { spell = 217824, type = "debuff", unit = "target" }, -- Shield of Virtue
        { spell = 383843, type = "debuff", unit = "target", talent = 380188 }, -- Crusader's Resolve
        { spell = 385723, type = "debuff", unit = "target", talent = 385728 }, -- Seal of the Crusader
        { spell = 387174, type = "debuff", unit = "target", talent = 387174 }, -- Eye of Tyr
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 633, type = "ability", talent = 633 }, -- Lay on Hands
        { spell = 642, type = "ability", buff = true, usable = true }, -- Divine Shield
        { spell = 853, type = "ability", requiresTarget = true }, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true, talent = 1022 }, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true, talent = 1044 }, -- Blessing of Freedom
        { spell = 10326, type = "ability", talent = 10326 }, -- Turn Evil
        { spell = 20066, type = "ability", talent = 20066 }, -- Repentance
        { spell = 24275, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 24275 }, -- Hammer of Wrath
        { spell = 26573, type = "ability", totem = true }, -- Consecration
        { spell = 31850, type = "ability", buff = true, talent = 31850 }, -- Ardent Defender
        { spell = 31884, type = "ability", buff = true, talent = 384376 }, -- Avenging Wrath
        { spell = 31935, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 31935 }, -- Avenger's Shield
        { spell = 35395, type = "ability", requiresTarget = true }, -- Crusader Strike
        { spell = 53595, type = "ability", charges = true, requiresTarget = true, talent = 53595 }, -- Hammer of the Righteous
        { spell = 53600, type = "ability", usable = true }, -- Shield of the Righteous
        { spell = 62124, type = "ability", requiresTarget = true }, -- Hand of Reckoning
        { spell = 96231, type = "ability", requiresTarget = true, talent = 96231 }, -- Rebuke
        { spell = 105809, type = "ability", buff = true, talent = 105809 }, -- Holy Avenger
        { spell = 115750, type = "ability", talent = 115750 }, -- Blinding Light
        { spell = 152262, type = "ability", buff = true, talent = 152262 }, -- Seraphim
        { spell = 190784, type = "ability", charges = true, talent = 190784 }, -- Divine Steed
        { spell = 204018, type = "ability", talent = 204018 }, -- Blessing of Spellwarding
        { spell = 204019, type = "ability", charges = true, talent = 204019 }, -- Blessed Hammer
        { spell = 213644, type = "ability", talent = 213644 }, -- Cleanse Toxins
        { spell = 275779, type = "ability", charges = true, requiresTarget = true }, -- Judgment
        { spell = 327193, type = "ability", buff = true, talent = 327193 }, -- Moment of Glory
        { spell = 375576, type = "ability", requiresTarget = true, talent = 375576 }, -- Divine Toll
        { spell = 378974, type = "ability", buff = true, talent = 378974 }, -- Bastion of Light
        { spell = 387174, type = "ability", talent = 387174 }, -- Eye of Tyr
        { spell = 389539, type = "ability", buff = true, talent = 385438 }, -- Sentinel
        { spell = 391054, type = "ability" }, -- Intercession
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
        { spell = 215652, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Shield of Virtue
        { spell = 207028, type = "ability", requiresTarget = true, pvptalent = 4, titleSuffix = L["cooldown"] }, -- Inquisition
        { spell = 215652, type = "ability", buff = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Shield of Virtue
        { spell = 228049, type = "ability", pvptalent = 10, titleSuffix = L["cooldown"] }, -- Guardian of the Forgotten Queen
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 465, type = "buff", unit = "player" }, -- Devotion Aura
        { spell = 498, type = "buff", unit = "player", talent = 498 }, -- Divine Protection
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "player", talent = 1022 }, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "player", talent = 1044 }, -- Blessing of Freedom
        { spell = 5502, type = "buff", unit = "player" }, -- Sense Undead
        { spell = 31884, type = "buff", unit = "player", talent = 384376 }, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player" }, -- Crusader Aura
        { spell = 105809, type = "buff", unit = "player", talent = 105809 }, -- Holy Avenger
        { spell = 114250, type = "buff", unit = "player", talent = 85804 }, -- Selfless Healer
        { spell = 152262, type = "buff", unit = "player", talent = 152262 }, -- Seraphim
        { spell = 183435, type = "buff", unit = "player" }, -- Retribution Aura
        { spell = 184662, type = "buff", unit = "player", talent = 184662 }, -- Shield of Vengeance
        { spell = 210391, type = "buff", unit = "player" }, -- Darkest before the Dawn
        { spell = 221886, type = "buff", unit = "player", talent = 190784 }, -- Divine Steed
        { spell = 223819, type = "buff", unit = "player", talent = 223817 }, -- Divine Purpose
        { spell = 231895, type = "buff", unit = "player", talent = 384392 }, -- Crusade
        { spell = 267611, type = "buff", unit = "player", talent = 267610 }, -- Righteous Verdict
        { spell = 269571, type = "buff", unit = "player", talent = 269569 }, -- Zeal
        { spell = 281178, type = "buff", unit = "player", talent = 231832 }, -- Blade of Wrath
        { spell = 317920, type = "buff", unit = "player" }, -- Concentration Aura
        { spell = 326733, type = "buff", unit = "player", talent = 326732 }, -- Empyrean Power
        { spell = 382522, type = "buff", unit = "player", talent = 382275 }, -- Consecrated Blade
        { spell = 383307, type = "buff", unit = "player", talent = 383304 }, -- Virtuous Command
        { spell = 383311, type = "buff", unit = "player", talent = 383314 }, -- Vanguard's Momentum
        { spell = 383329, type = "buff", unit = "player", talent = 383328 }, -- Final Verdict
        { spell = 383389, type = "buff", unit = "player", talent = 383388 }, -- Relentless Inquisitor
        { spell = 384029, type = "buff", unit = "player", talent = 384027 }, -- Divine Resonance
        { spell = 385126, type = "buff", unit = "player" }, -- Blessing of Dusk
        { spell = 385127, type = "buff", unit = "player" }, -- Blessing of Dawn
        { spell = 385417, type = "buff", unit = "player", talent = 385416 }, -- Aspiration of Divinity
        { spell = 387178, type = "buff", unit = "player", talent = 387170 }, -- Empyrean Legacy
        { spell = 387480, type = "buff", unit = "player", talent = 387479 }, -- Sanctified Ground
        { spell = 387643, type = "buff", unit = "player", talent = 387640 }, -- Sealed Verdict
      },
      icon = 135993
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 115750 }, -- Blinding Light
        { spell = 183218, type = "debuff", unit = "target", talent = 183218 }, -- Hand of Hindrance
        { spell = 196941, type = "debuff", unit = "target", talent = 183778 }, -- Judgment of Light
        { spell = 197277, type = "debuff", unit = "target", talent = 231663 }, -- Judgment
        { spell = 204242, type = "debuff", unit = "target" }, -- Consecration
        { spell = 255937, type = "debuff", unit = "target", talent = 255937 }, -- Wake of Ashes
        { spell = 343527, type = "debuff", unit = "target", talent = 343527 }, -- Execution Sentence
        { spell = 343721, type = "debuff", unit = "target", talent = 343721 }, -- Final Reckoning
        { spell = 343724, type = "debuff", unit = "target" }, -- Reckoning
        { spell = 382538, type = "debuff", unit = "target", talent = 382536 }, -- Sanctify
        { spell = 383208, type = "debuff", unit = "target", talent = 383185 }, -- Exorcism
        { spell = 383346, type = "debuff", unit = "target", talent = 383344 }, -- Expurgation
        { spell = 383351, type = "debuff", unit = "target", talent = 383350 }, -- Truth's Wake
        { spell = 385723, type = "debuff", unit = "target", talent = 385728 }, -- Seal of the Crusader
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 498, type = "ability", buff = true, talent = 498 }, -- Divine Protection
        { spell = 633, type = "ability", talent = 633 }, -- Lay on Hands
        { spell = 642, type = "ability", buff = true, usable = true }, -- Divine Shield
        { spell = 853, type = "ability", requiresTarget = true }, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true, talent = 1022 }, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true, talent = 1044 }, -- Blessing of Freedom
        { spell = 10326, type = "ability", talent = 10326 }, -- Turn Evil
        { spell = 20066, type = "ability", talent = 20066 }, -- Repentance
        { spell = 20271, type = "ability", charges = true, requiresTarget = true, talent = 231663 }, -- Judgment
        { spell = 24275, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 24275 }, -- Hammer of Wrath
        { spell = 26573, type = "ability", totem = true }, -- Consecration
        { spell = 31884, type = "ability", buff = true, talent = 384376 }, -- Avenging Wrath
        { spell = 35395, type = "ability", charges = true, requiresTarget = true }, -- Crusader Strike
        { spell = 62124, type = "ability", requiresTarget = true }, -- Hand of Reckoning
        { spell = 85256, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Templar's Verdict
        { spell = 96231, type = "ability", requiresTarget = true, talent = 96231 }, -- Rebuke
        { spell = 105809, type = "ability", buff = true, talent = 105809 }, -- Holy Avenger
        { spell = 115750, type = "ability", talent = 115750 }, -- Blinding Light
        { spell = 152262, type = "ability", buff = true, talent = 152262 }, -- Seraphim
        { spell = 183218, type = "ability", requiresTarget = true, talent = 183218 }, -- Hand of Hindrance
        { spell = 184575, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 184575 }, -- Blade of Justice
        { spell = 184662, type = "ability", buff = true, talent = 184662 }, -- Shield of Vengeance
        { spell = 190784, type = "ability", charges = true, talent = 190784 }, -- Divine Steed
        { spell = 213644, type = "ability", talent = 213644 }, -- Cleanse Toxins
        { spell = 215661, type = "ability", requiresTarget = true, talent = 215661 }, -- Justicar's Vengeance
        { spell = 231663, type = "ability", requiresTarget = true, talent = 231663 }, -- Greater Judgment
        { spell = 231895, type = "ability", buff = true, talent = 384392 }, -- Crusade
        { spell = 255937, type = "ability", talent = 255937 }, -- Wake of Ashes
        { spell = 343527, type = "ability", requiresTarget = true, talent = 343527 }, -- Execution Sentence
        { spell = 343721, type = "ability", talent = 343721 }, -- Final Reckoning
        { spell = 375576, type = "ability", requiresTarget = true, talent = 375576 }, -- Divine Toll
        { spell = 383185, type = "ability", requiresTarget = true, talent = 383185 }, -- Exorcism
        { spell = 383328, type = "ability", requiresTarget = true, talent = 383328 }, -- Final Verdict
        { spell = 391054, type = "ability" }, -- Intercession
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
        { spell = 210256, type = "buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"] }, -- Blessing of Sanctuary
        { spell = 210323, type = "buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"] }, -- Vengeance Aura
        { spell = 210256, type = "ability", buff = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Blessing of Sanctuary
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 5384, type = "buff", unit = "player" }, -- Feign Death
        { spell = 6197, type = "buff", unit = "player" }, -- Eagle Eye
        { spell = 19574, type = "buff", unit = "player", talent = 19574 }, -- Bestial Wrath
        { spell = 34477, type = "buff", unit = "player", talent = 34477 }, -- Misdirection
        { spell = 118922, type = "buff", unit = "player", talent = 109215 }, -- Posthaste
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 193530, type = "buff", unit = "player", talent = 193530 }, -- Aspect of the Wild
        { spell = 199483, type = "buff", unit = "player", talent = 199483 }, -- Camouflage
        { spell = 202748, type = "buff", unit = "player" }, -- Survival Tactics
        { spell = 212704, type = "buff", unit = "player" }, -- The Beast Within
        { spell = 231390, type = "buff", unit = "player", talent = 199921 }, -- Trailblazer
        { spell = 246152, type = "buff", unit = "player", talent = 217200 }, -- Barbed Shot
        { spell = 248519, type = "buff", unit = "player" }, -- Interlope
        { spell = 257946, type = "buff", unit = "player", talent = 257944 }, -- Thrill of the Hunt
        { spell = 264656, type = "buff", unit = "player", talent = 378002 }, -- Pathfinding
        { spell = 264663, type = "buff", unit = "player" }, -- Predator's Thirst
        { spell = 264667, type = "buff", unit = "player" }, -- Primal Rage
        { spell = 264735, type = "buff", unit = "player", talent = 264735 }, -- Survival of the Fittest
        { spell = 268877, type = "buff", unit = "player", talent = 115939 }, -- Beast Cleave
        { spell = 281036, type = "buff", unit = "player", talent = 120679 }, -- Dire Beast
        { spell = 321297, type = "buff", unit = "player" }, -- Eyes of the Beast
        { spell = 359844, type = "buff", unit = "player", talent = 359844 }, -- Call of the Wild
        { spell = 378215, type = "buff", unit = "player", talent = 378210 }, -- Hunter's Prey
        { spell = 385540, type = "buff", unit = "player", talent = 385539 }, -- Rejuvenating Wind
        { spell = 388045, type = "buff", unit = "player", talent = 388045 }, -- Sentinel Owl
        { spell = 392296, type = "buff", unit = "player", talent = 378750 }, -- Cobra Sting
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 61684, type = "buff", unit = "pet" }, -- Dash
        { spell = 264360, type = "buff", unit = "pet" }, -- Winged Agility
        { spell = 272790, type = "buff", unit = "pet" }, -- Frenzy
        { spell = 392054, type = "buff", unit = "pet", talent = 392053 }, -- Piercing Fangs
        { spell = 393774, type = "buff", unit = "pet", talent = 388056 }, -- Sentinel's Perception
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target" }, -- Growl
        { spell = 3355, type = "debuff", unit = "target" }, -- Freezing Trap
        { spell = 5116, type = "debuff", unit = "target", talent = 5116 }, -- Concussive Shot
        { spell = 24394, type = "debuff", unit = "target", talent = 19577 }, -- Intimidation
        { spell = 117405, type = "debuff", unit = "target", talent = 109248 }, -- Binding Shot
        { spell = 131894, type = "debuff", unit = "target", talent = 131894 }, -- A Murder of Crows
        { spell = 135299, type = "debuff", unit = "target", talent = 187698 }, -- Tar Trap
        { spell = 162480, type = "debuff", unit = "target", talent = 162488 }, -- Steel Trap
        { spell = 209967, type = "debuff", unit = "target" }, -- Dire Beast: Basilisk
        { spell = 212431, type = "debuff", unit = "target", talent = 212431 }, -- Explosive Shot
        { spell = 213691, type = "debuff", unit = "target", talent = 213691 }, -- Scatter Shot
        { spell = 217200, type = "debuff", unit = "target", talent = 217200 }, -- Barbed Shot
        { spell = 236777, type = "debuff", unit = "target", talent = 236776 }, -- High Explosive Trap
        { spell = 257284, type = "debuff", unit = "target" }, -- Hunter's Mark
        { spell = 269576, type = "debuff", unit = "target", talent = 260309 }, -- Master Marksman
        { spell = 271788, type = "debuff", unit = "target", talent = 271788 }, -- Serpent Sting
        { spell = 321469, type = "debuff", unit = "target", talent = 321468 }, -- Binding Shackles
        { spell = 321538, type = "debuff", unit = "target", talent = 321530 }, -- Bloodshed
        { spell = 356723, type = "debuff", unit = "target" }, -- Scorpid Venom
        { spell = 356727, type = "debuff", unit = "target" }, -- Spider Venom
        { spell = 356730, type = "debuff", unit = "target" }, -- Viper Venom
        { spell = 375893, type = "debuff", unit = "target", talent = 375891 }, -- Death Chakram
        { spell = 378015, type = "debuff", unit = "target" }, -- Latent Poison
        { spell = 390232, type = "debuff", unit = "target", talent = 390231 }, -- Arctic Bola
        { spell = 392061, type = "debuff", unit = "target", talent = 392060 }, -- Wailing Arrow
        { spell = 393456, type = "debuff", unit = "target", talent = 393344 }, -- Entrapment
        { spell = 393480, type = "debuff", unit = "target" }, -- Sentinel
      },
      icon = 135860
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 781, type = "ability" }, -- Disengage
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 2643, type = "ability", requiresTarget = true, usable = true, talent = 2643 }, -- Multi-Shot
        { spell = 2649, type = "ability" }, -- Growl
        { spell = 5116, type = "ability", requiresTarget = true, talent = 5116 }, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true, usable = true }, -- Feign Death
        { spell = 17253, type = "ability" }, -- Bite
        { spell = 19574, type = "ability", buff = true, talent = 19574 }, -- Bestial Wrath
        { spell = 19577, type = "ability", talent = 19577 }, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true, talent = 19801 }, -- Tranquilizing Shot
        { spell = 34026, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 34026 }, -- Kill Command
        { spell = 34477, type = "ability", buff = true, talent = 34477 }, -- Misdirection
        { spell = 53351, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 53351 }, -- Kill Shot
        { spell = 61684, type = "ability", buff = true, unit = 'pet' }, -- Dash
        { spell = 109248, type = "ability", talent = 109248 }, -- Binding Shot
        { spell = 109304, type = "ability" }, -- Exhilaration
        { spell = 120360, type = "ability", talent = 120360 }, -- Barrage
        { spell = 120679, type = "ability", requiresTarget = true, talent = 120679 }, -- Dire Beast
        { spell = 131894, type = "ability", requiresTarget = true, talent = 131894 }, -- A Murder of Crows
        { spell = 147362, type = "ability", requiresTarget = true, usable = true, talent = 147362 }, -- Counter Shot
        { spell = 162488, type = "ability", talent = 162488 }, -- Steel Trap
        { spell = 185358, type = "ability", requiresTarget = true, usable = true }, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true }, -- Aspect of the Turtle
        { spell = 187650, type = "ability" }, -- Freezing Trap
        { spell = 187698, type = "ability", talent = 187698 }, -- Tar Trap
        { spell = 193455, type = "ability", requiresTarget = true, usable = true, talent = 193455 }, -- Cobra Shot
        { spell = 193530, type = "ability", buff = true, requiresTarget = true, talent = 193530 }, -- Aspect of the Wild
        { spell = 199483, type = "ability", buff = true, talent = 199483 }, -- Camouflage
        { spell = 201430, type = "ability", talent = 201430 }, -- Stampede
        { spell = 212431, type = "ability", requiresTarget = true, talent = 212431 }, -- Explosive Shot
        { spell = 213691, type = "ability", requiresTarget = true, talent = 213691 }, -- Scatter Shot
        { spell = 217200, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 217200 }, -- Barbed Shot
        { spell = 236776, type = "ability", talent = 236776 }, -- High Explosive Trap
        { spell = 257284, type = "ability", requiresTarget = true }, -- Hunter's Mark
        { spell = 257620, type = "ability", requiresTarget = true, talent = 257620 }, -- Multi-Shot
        { spell = 259489, type = "ability", requiresTarget = true, talent = 259489 }, -- Kill Command
        { spell = 264360, type = "ability", buff = true, unit = 'pet' }, -- Winged Agility
        { spell = 264667, type = "ability", buff = true }, -- Primal Rage
        { spell = 264735, type = "ability", buff = true, talent = 264735 }, -- Survival of the Fittest
        { spell = 271788, type = "ability", requiresTarget = true, talent = 271788 }, -- Serpent Sting
        { spell = 272678, type = "ability" }, -- Primal Rage
        { spell = 320976, type = "ability", requiresTarget = true, talent = 320976 }, -- Kill Shot
        { spell = 321530, type = "ability", requiresTarget = true, talent = 321530 }, -- Bloodshed
        { spell = 359844, type = "ability", buff = true, requiresTarget = true, talent = 359844 }, -- Call of the Wild
        { spell = 375891, type = "ability", requiresTarget = true, talent = 375891 }, -- Death Chakram
        { spell = 388045, type = "ability", charges = true, buff = true, talent = 388045 }, -- Sentinel Owl
        { spell = 392060, type = "ability", requiresTarget = true, talent = 392060 }, -- Wailing Arrow
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
        { spell = 53480, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Roar of Sacrifice
        { spell = 53480, type = "ability", buff = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Roar of Sacrifice
        { spell = 205691, type = "ability", requiresTarget = true, pvptalent = 12, titleSuffix = L["cooldown"] }, -- Dire Beast: Basilisk
        { spell = 208652, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"] }, -- Dire Beast: Hawk
        { spell = 248518, type = "ability", pvptalent = 4, titleSuffix = L["cooldown"] }, -- Interlope
        { spell = 356719, type = "ability", requiresTarget = true, pvptalent = 2, titleSuffix = L["cooldown"] }, -- Chimaeral Sting
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 5384, type = "buff", unit = "player" }, -- Feign Death
        { spell = 34477, type = "buff", unit = "player", talent = 34477 }, -- Misdirection
        { spell = 118922, type = "buff", unit = "player", talent = 109215 }, -- Posthaste
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 193534, type = "buff", unit = "player", talent = 193533 }, -- Steady Focus
        { spell = 194594, type = "buff", unit = "player", talent = 194595 }, -- Lock and Load
        { spell = 231390, type = "buff", unit = "player", talent = 199921 }, -- Trailblazer
        { spell = 257622, type = "buff", unit = "player", talent = 257621 }, -- Trick Shots
        { spell = 260242, type = "buff", unit = "player", talent = 260240 }, -- Precise Shots
        { spell = 260243, type = "buff", unit = "player", talent = 260243 }, -- Volley
        { spell = 260402, type = "buff", unit = "player", talent = 260402 }, -- Double Tap
        { spell = 264656, type = "buff", unit = "player", talent = 378002 }, -- Pathfinding
        { spell = 264663, type = "buff", unit = "player" }, -- Predator's Thirst
        { spell = 264667, type = "buff", unit = "player" }, -- Primal Rage
        { spell = 264735, type = "buff", unit = "player", talent = 264735 }, -- Survival of the Fittest
        { spell = 288613, type = "buff", unit = "player", talent = 288613 }, -- Trueshot
        { spell = 342076, type = "buff", unit = "player", talent = 260367 }, -- Streamline
        { spell = 378770, type = "buff", unit = "player", talent = 378769 }, -- Deathblow
        { spell = 385540, type = "buff", unit = "player", talent = 385539 }, -- Rejuvenating Wind
        { spell = 386875, type = "buff", unit = "player", talent = 378880 }, -- Bombardment
        { spell = 386877, type = "buff", unit = "player", talent = 386878 }, -- Unerring Vision
        { spell = 388045, type = "buff", unit = "player", talent = 388045 }, -- Sentinel Owl
        { spell = 388998, type = "buff", unit = "player", talent = 384790 }, -- Razor Fragments
        { spell = 389450, type = "buff", unit = "player", talent = 389449 }, -- Eagletalon's True Focus
        { spell = 393777, type = "buff", unit = "player", talent = 388057 }, -- Sentinel's Protection
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 61684, type = "buff", unit = "pet" }, -- Dash
        { spell = 264360, type = "buff", unit = "pet" }, -- Winged Agility
        { spell = 393774, type = "buff", unit = "pet", talent = 388056 }, -- Sentinel's Perception
      },
      icon = 461846
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target" }, -- Growl
        { spell = 3355, type = "debuff", unit = "target" }, -- Freezing Trap
        { spell = 5116, type = "debuff", unit = "target", talent = 5116 }, -- Concussive Shot
        { spell = 24394, type = "debuff", unit = "target", talent = 19577 }, -- Intimidation
        { spell = 117405, type = "debuff", unit = "target", talent = 109248 }, -- Binding Shot
        { spell = 135299, type = "debuff", unit = "target", talent = 187698 }, -- Tar Trap
        { spell = 162480, type = "debuff", unit = "target", talent = 162488 }, -- Steel Trap
        { spell = 201594, type = "debuff", unit = "target", talent = 201430 }, -- Stampede
        { spell = 212431, type = "debuff", unit = "target", talent = 212431 }, -- Explosive Shot
        { spell = 213691, type = "debuff", unit = "target", talent = 213691 }, -- Scatter Shot
        { spell = 236777, type = "debuff", unit = "target", talent = 236776 }, -- High Explosive Trap
        { spell = 257044, type = "debuff", unit = "target", talent = 257044 }, -- Rapid Fire
        { spell = 257284, type = "debuff", unit = "target" }, -- Hunter's Mark
        { spell = 269576, type = "debuff", unit = "target", talent = 260309 }, -- Master Marksman
        { spell = 271788, type = "debuff", unit = "target", talent = 271788 }, -- Serpent Sting
        { spell = 321469, type = "debuff", unit = "target", talent = 321468 }, -- Binding Shackles
        { spell = 356723, type = "debuff", unit = "target" }, -- Scorpid Venom
        { spell = 356727, type = "debuff", unit = "target" }, -- Spider Venom
        { spell = 356730, type = "debuff", unit = "target" }, -- Viper Venom
        { spell = 375893, type = "debuff", unit = "target", talent = 375891 }, -- Death Chakram
        { spell = 378015, type = "debuff", unit = "target" }, -- Latent Poison
        { spell = 385638, type = "debuff", unit = "target", talent = 384790 }, -- Razor Fragments
        { spell = 390232, type = "debuff", unit = "target", talent = 390231 }, -- Arctic Bola
        { spell = 392061, type = "debuff", unit = "target", talent = 392060 }, -- Wailing Arrow
        { spell = 393456, type = "debuff", unit = "target", talent = 393344 }, -- Entrapment
        { spell = 393480, type = "debuff", unit = "target" }, -- Sentinel
      },
      icon = 236188
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 781, type = "ability" }, -- Disengage
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 2643, type = "ability", requiresTarget = true, talent = 2643 }, -- Multi-Shot
        { spell = 2649, type = "ability" }, -- Growl
        { spell = 5116, type = "ability", requiresTarget = true, talent = 5116 }, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true, usable = true }, -- Feign Death
        { spell = 17253, type = "ability" }, -- Bite
        { spell = 19434, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 19434 }, -- Aimed Shot
        { spell = 19577, type = "ability", talent = 19577 }, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true, talent = 19801 }, -- Tranquilizing Shot
        { spell = 34026, type = "ability", charges = true, requiresTarget = true, talent = 34026 }, -- Kill Command
        { spell = 34477, type = "ability", buff = true, usable = true, talent = 34477 }, -- Misdirection
        { spell = 53351, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 53351 }, -- Kill Shot
        { spell = 56641, type = "ability", requiresTarget = true, usable = true }, -- Steady Shot
        { spell = 61684, type = "ability", buff = true, unit = 'pet' }, -- Dash
        { spell = 109248, type = "ability", talent = 109248 }, -- Binding Shot
        { spell = 109304, type = "ability" }, -- Exhilaration
        { spell = 120360, type = "ability", talent = 120360 }, -- Barrage
        { spell = 147362, type = "ability", requiresTarget = true, talent = 147362 }, -- Counter Shot
        { spell = 162488, type = "ability", talent = 162488 }, -- Steel Trap
        { spell = 185358, type = "ability", charges = true, overlayGlow = true, requiresTarget = true }, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true }, -- Aspect of the Turtle
        { spell = 186387, type = "ability", usable = true, talent = 186387 }, -- Bursting Shot
        { spell = 187650, type = "ability" }, -- Freezing Trap
        { spell = 187698, type = "ability", talent = 187698 }, -- Tar Trap
        { spell = 201430, type = "ability", talent = 201430 }, -- Stampede
        { spell = 212431, type = "ability", requiresTarget = true, talent = 212431 }, -- Explosive Shot
        { spell = 213691, type = "ability", requiresTarget = true, talent = 213691 }, -- Scatter Shot
        { spell = 236776, type = "ability", talent = 236776 }, -- High Explosive Trap
        { spell = 257044, type = "ability", requiresTarget = true, talent = 257044 }, -- Rapid Fire
        { spell = 257284, type = "ability", requiresTarget = true }, -- Hunter's Mark
        { spell = 257620, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 257620 }, -- Multi-Shot
        { spell = 260243, type = "ability", buff = true, talent = 260243 }, -- Volley
        { spell = 260402, type = "ability", buff = true, talent = 260402 }, -- Double Tap
        { spell = 264360, type = "ability", buff = true, unit = 'pet' }, -- Winged Agility
        { spell = 264667, type = "ability", buff = true }, -- Primal Rage
        { spell = 264735, type = "ability", buff = true, talent = 264735 }, -- Survival of the Fittest
        { spell = 271788, type = "ability", requiresTarget = true, talent = 271788 }, -- Serpent Sting
        { spell = 272678, type = "ability" }, -- Primal Rage
        { spell = 288613, type = "ability", buff = true, talent = 288613 }, -- Trueshot
        { spell = 342049, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 342049 }, -- Chimaera Shot
        { spell = 375891, type = "ability", requiresTarget = true, talent = 375891 }, -- Death Chakram
        { spell = 388045, type = "ability", charges = true, buff = true, talent = 388045 }, -- Sentinel Owl
        { spell = 392060, type = "ability", requiresTarget = true, talent = 392060 }, -- Wailing Arrow
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
        { spell = 53480, type = "buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"] }, -- Roar of Sacrifice
        { spell = 203155, type = "buff", unit = "player", pvptalent = 1, titleSuffix = L["buff"] }, -- Sniper Shot
        { spell = 356707, type = "buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"] }, -- Wild Kingdom
        { spell = 53480, type = "ability", buff = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Roar of Sacrifice
        { spell = 203155, type = "ability", buff = true, requiresTarget = true, pvptalent = 1, titleSuffix = L["cooldown"] }, -- Sniper Shot
        { spell = 356707, type = "ability", buff = true, pvptalent = 7, titleSuffix = L["cooldown"] }, -- Wild Kingdom
        { spell = 356719, type = "ability", requiresTarget = true, pvptalent = 4, titleSuffix = L["cooldown"] }, -- Chimaeral Sting
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 5384, type = "buff", unit = "player" }, -- Feign Death
        { spell = 34477, type = "buff", unit = "player", talent = 34477 }, -- Misdirection
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 186289, type = "buff", unit = "player", talent = 186289 }, -- Aspect of the Eagle
        { spell = 231390, type = "buff", unit = "player", talent = 199921 }, -- Trailblazer
        { spell = 259388, type = "buff", unit = "player" }, -- Mongoose Fury
        { spell = 260249, type = "buff", unit = "player", talent = 260248 }, -- Bloodseeker
        { spell = 260286, type = "buff", unit = "player", talent = 260285 }, -- Tip of the Spear
        { spell = 264656, type = "buff", unit = "player", talent = 378002 }, -- Pathfinding
        { spell = 264663, type = "buff", unit = "player" }, -- Predator's Thirst
        { spell = 264667, type = "buff", unit = "player" }, -- Primal Rage
        { spell = 264735, type = "buff", unit = "player", talent = 264735 }, -- Survival of the Fittest
        { spell = 265898, type = "buff", unit = "player", talent = 265895 }, -- Terms of Engagement
        { spell = 360952, type = "buff", unit = "player", talent = 360952 }, -- Coordinated Assault
        { spell = 360966, type = "buff", unit = "player", talent = 360966 }, -- Spearhead
        { spell = 388045, type = "buff", unit = "player", talent = 388045 }, -- Sentinel Owl
        { spell = 260249, type = "buff", unit = "target", talent = 260248 }, -- Bloodseeker
        { spell = 264663, type = "buff", unit = "target" }, -- Predator's Thirst
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 61684, type = "buff", unit = "pet" }, -- Dash
        { spell = 393774, type = "buff", unit = "pet", talent = 388056 }, -- Sentinel's Perception
      },
      icon = 1376044
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 2649, type = "ability" }, -- Growl
        { spell = 5116, type = "ability", requiresTarget = true, talent = 5116 }, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true }, -- Feign Death
        { spell = 17253, type = "ability" }, -- Bite
        { spell = 19577, type = "ability", talent = 19577 }, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true, talent = 19801 }, -- Tranquilizing Shot
        { spell = 34026, type = "ability", requiresTarget = true, talent = 34026 }, -- Kill Command
        { spell = 34477, type = "ability", buff = true, talent = 34477 }, -- Misdirection
        { spell = 53351, type = "ability", requiresTarget = true, talent = 53351 }, -- Kill Shot
        { spell = 56641, type = "ability", requiresTarget = true, usable = true }, -- Steady Shot
        { spell = 61684, type = "ability", buff = true, unit = 'pet' }, -- Dash
        { spell = 109248, type = "ability", talent = 109248 }, -- Binding Shot
        { spell = 109304, type = "ability" }, -- Exhilaration
        { spell = 162488, type = "ability", talent = 162488 }, -- Steel Trap
        { spell = 185358, type = "ability", requiresTarget = true, usable = true }, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true }, -- Aspect of the Turtle
        { spell = 186270, type = "ability", requiresTarget = true, talent = 186270 }, -- Raptor Strike
        { spell = 186289, type = "ability", buff = true, talent = 186289 }, -- Aspect of the Eagle
        { spell = 187650, type = "ability" }, -- Freezing Trap
        { spell = 187698, type = "ability", talent = 187698 }, -- Tar Trap
        { spell = 187707, type = "ability", requiresTarget = true, talent = 187707 }, -- Muzzle
        { spell = 187708, type = "ability", talent = 187708 }, -- Carve
        { spell = 190925, type = "ability", requiresTarget = true, talent = 190925 }, -- Harpoon
        { spell = 201430, type = "ability", talent = 201430 }, -- Stampede
        { spell = 203415, type = "ability", talent = 203415 }, -- Fury of the Eagle
        { spell = 212431, type = "ability", requiresTarget = true, talent = 212431 }, -- Explosive Shot
        { spell = 212436, type = "ability", charges = true, talent = 212436 }, -- Butchery
        { spell = 213691, type = "ability", requiresTarget = true, talent = 213691 }, -- Scatter Shot
        { spell = 236776, type = "ability", talent = 236776 }, -- High Explosive Trap
        { spell = 257284, type = "ability", requiresTarget = true }, -- Hunter's Mark
        { spell = 259387, type = "ability", requiresTarget = true, talent = 259387 }, -- Mongoose Bite
        { spell = 259489, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 259489 }, -- Kill Command
        { spell = 259495, type = "ability", overlayGlow = true, requiresTarget = true, talent = 259495 }, -- Wildfire Bomb
        { spell = 264667, type = "ability", buff = true }, -- Primal Rage
        { spell = 264735, type = "ability", buff = true, talent = 264735 }, -- Survival of the Fittest
        { spell = 269751, type = "ability", requiresTarget = true, talent = 269751 }, -- Flanking Strike
        { spell = 270323, type = "ability", charges = true, overlayGlow = true }, -- Pheromone Bomb
        { spell = 270335, type = "ability", charges = true, overlayGlow = true }, -- Shrapnel Bomb
        { spell = 271045, type = "ability", charges = true, overlayGlow = true }, -- Volatile Bomb
        { spell = 271788, type = "ability", requiresTarget = true, talent = 271788 }, -- Serpent Sting
        { spell = 320976, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 320976 }, -- Kill Shot
        { spell = 360952, type = "ability", buff = true, requiresTarget = true, talent = 360952 }, -- Coordinated Assault
        { spell = 360966, type = "ability", buff = true, requiresTarget = true, talent = 360966 }, -- Spearhead
        { spell = 375891, type = "ability", requiresTarget = true, talent = 375891 }, -- Death Chakram
        { spell = 388045, type = "ability", charges = true, buff = true, talent = 388045 }, -- Sentinel Owl
      },
      icon = 132309
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 2649, type = "ability" }, -- Growl
        { spell = 5116, type = "ability", requiresTarget = true, talent = 5116 }, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true }, -- Feign Death
        { spell = 17253, type = "ability" }, -- Bite
        { spell = 19577, type = "ability", talent = 19577 }, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true, talent = 19801 }, -- Tranquilizing Shot
        { spell = 34026, type = "ability", requiresTarget = true, talent = 34026 }, -- Kill Command
        { spell = 34477, type = "ability", buff = true, talent = 34477 }, -- Misdirection
        { spell = 53351, type = "ability", requiresTarget = true, talent = 53351 }, -- Kill Shot
        { spell = 56641, type = "ability", requiresTarget = true, usable = true }, -- Steady Shot
        { spell = 61684, type = "ability", buff = true, unit = 'pet' }, -- Dash
        { spell = 109248, type = "ability", talent = 109248 }, -- Binding Shot
        { spell = 109304, type = "ability" }, -- Exhilaration
        { spell = 162488, type = "ability", talent = 162488 }, -- Steel Trap
        { spell = 185358, type = "ability", requiresTarget = true, usable = true }, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true }, -- Aspect of the Turtle
        { spell = 186270, type = "ability", requiresTarget = true, talent = 186270 }, -- Raptor Strike
        { spell = 186289, type = "ability", buff = true, talent = 186289 }, -- Aspect of the Eagle
        { spell = 187650, type = "ability" }, -- Freezing Trap
        { spell = 187698, type = "ability", talent = 187698 }, -- Tar Trap
        { spell = 187707, type = "ability", requiresTarget = true, talent = 187707 }, -- Muzzle
        { spell = 187708, type = "ability", talent = 187708 }, -- Carve
        { spell = 190925, type = "ability", requiresTarget = true, talent = 190925 }, -- Harpoon
        { spell = 201430, type = "ability", talent = 201430 }, -- Stampede
        { spell = 203415, type = "ability", talent = 203415 }, -- Fury of the Eagle
        { spell = 212431, type = "ability", requiresTarget = true, talent = 212431 }, -- Explosive Shot
        { spell = 212436, type = "ability", charges = true, talent = 212436 }, -- Butchery
        { spell = 213691, type = "ability", requiresTarget = true, talent = 213691 }, -- Scatter Shot
        { spell = 236776, type = "ability", talent = 236776 }, -- High Explosive Trap
        { spell = 257284, type = "ability", requiresTarget = true }, -- Hunter's Mark
        { spell = 259387, type = "ability", requiresTarget = true, talent = 259387 }, -- Mongoose Bite
        { spell = 259489, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 259489 }, -- Kill Command
        { spell = 259495, type = "ability", overlayGlow = true, requiresTarget = true, talent = 259495 }, -- Wildfire Bomb
        { spell = 264667, type = "ability", buff = true }, -- Primal Rage
        { spell = 264735, type = "ability", buff = true, talent = 264735 }, -- Survival of the Fittest
        { spell = 269751, type = "ability", requiresTarget = true, talent = 269751 }, -- Flanking Strike
        { spell = 270323, type = "ability", charges = true, overlayGlow = true }, -- Pheromone Bomb
        { spell = 270335, type = "ability", charges = true, overlayGlow = true }, -- Shrapnel Bomb
        { spell = 271045, type = "ability", charges = true, overlayGlow = true }, -- Volatile Bomb
        { spell = 271788, type = "ability", requiresTarget = true, talent = 271788 }, -- Serpent Sting
        { spell = 320976, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 320976 }, -- Kill Shot
        { spell = 360952, type = "ability", buff = true, requiresTarget = true, talent = 360952 }, -- Coordinated Assault
        { spell = 360966, type = "ability", buff = true, requiresTarget = true, talent = 360966 }, -- Spearhead
        { spell = 375891, type = "ability", requiresTarget = true, talent = 375891 }, -- Death Chakram
        { spell = 388045, type = "ability", charges = true, buff = true, talent = 388045 }, -- Sentinel Owl
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
        { spell = 212640, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Mending Bandage
        { spell = 356707, type = "buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"] }, -- Wild Kingdom
        { spell = 212638, type = "debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"] }, -- Tracker's Net
        { spell = 212638, type = "ability", requiresTarget = true, pvptalent = 10, titleSuffix = L["cooldown"] }, -- Tracker's Net
        { spell = 212640, type = "ability", buff = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Mending Bandage
        { spell = 356707, type = "ability", buff = true, pvptalent = 5, titleSuffix = L["cooldown"] }, -- Wild Kingdom
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 1784, type = "buff", unit = "player" }, -- Stealth
        { spell = 1966, type = "buff", unit = "player", talent = 1966 }, -- Feint
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 5277, type = "buff", unit = "player", talent = 5277 }, -- Evasion
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 31224, type = "buff", unit = "player", talent = 31224 }, -- Cloak of Shadows
        { spell = 32645, type = "buff", unit = "player" }, -- Envenom
        { spell = 36554, type = "buff", unit = "player", talent = 36554 }, -- Shadowstep
        { spell = 108211, type = "buff", unit = "player", talent = 280716 }, -- Leeching Poison
        { spell = 114018, type = "buff", unit = "player" }, -- Shroud of Concealment
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 185422, type = "buff", unit = "player", talent = 185313 }, -- Shadow Dance
        { spell = 193538, type = "buff", unit = "player", talent = 193539 }, -- Alacrity
        { spell = 193641, type = "buff", unit = "player", talent = 193640 }, -- Elaborate Planning
        { spell = 315496, type = "buff", unit = "player" }, -- Slice and Dice
        { spell = 315584, type = "buff", unit = "player" }, -- Instant Poison
        { spell = 323560, type = "buff", unit = "player", talent = 385616 }, -- Echoing Reprimand
        { spell = 381802, type = "buff", unit = "player", talent = 381802 }, -- Indiscriminate Carnage
        { spell = 382245, type = "buff", unit = "player", talent = 382245 }, -- Cold Blood
        { spell = 392401, type = "buff", unit = "player", talent = 381632 }, -- Improved Garrote
        { spell = 393971, type = "buff", unit = "player", talent = 393970 }, -- Soothing Darkness
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 703, type = "debuff", unit = "target" }, -- Garrote
        { spell = 1776, type = "debuff", unit = "target", talent = 1776 }, -- Gouge
        { spell = 1833, type = "debuff", unit = "target" }, -- Cheap Shot
        { spell = 121411, type = "debuff", unit = "target", talent = 121411 }, -- Crimson Tempest
        { spell = 137619, type = "debuff", unit = "target", talent = 137619 }, -- Marked for Death
        { spell = 212183, type = "debuff", unit = "target" }, -- Smoke Bomb
        { spell = 360194, type = "debuff", unit = "target", talent = 360194 }, -- Deathmark
        { spell = 381628, type = "debuff", unit = "target", talent = 381627 }, -- Internal Bleeding
        { spell = 385627, type = "debuff", unit = "target", talent = 385627 }, -- Kingsbane
      },
      icon = 132302
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, type = "ability", requiresTarget = true, usable = true }, -- Kidney Shot
        { spell = 703, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Garrote
        { spell = 921, type = "ability", requiresTarget = true, usable = true }, -- Pick Pocket
        { spell = 1329, type = "ability", requiresTarget = true, usable = true }, -- Mutilate
        { spell = 1725, type = "ability", usable = true }, -- Distract
        { spell = 1766, type = "ability", requiresTarget = true, usable = true }, -- Kick
        { spell = 1776, type = "ability", requiresTarget = true, usable = true, talent = 1776 }, -- Gouge
        { spell = 1784, type = "ability", buff = true }, -- Stealth
        { spell = 1833, type = "ability", requiresTarget = true, usable = true }, -- Cheap Shot
        { spell = 1856, type = "ability", usable = true }, -- Vanish
        { spell = 1943, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Rupture
        { spell = 1966, type = "ability", buff = true, usable = true, talent = 1966 }, -- Feint
        { spell = 2094, type = "ability", requiresTarget = true, usable = true, talent = 2094 }, -- Blind
        { spell = 2983, type = "ability", buff = true, usable = true }, -- Sprint
        { spell = 5277, type = "ability", buff = true, usable = true, talent = 5277 }, -- Evasion
        { spell = 5938, type = "ability", charges = true, requiresTarget = true, usable = true, talent = 5938 }, -- Shiv
        { spell = 8676, type = "ability", requiresTarget = true, usable = true }, -- Ambush
        { spell = 31224, type = "ability", buff = true, usable = true, talent = 31224 }, -- Cloak of Shadows
        { spell = 32645, type = "ability", buff = true, requiresTarget = true, usable = true }, -- Envenom
        { spell = 36554, type = "ability", charges = true, buff = true, requiresTarget = true, usable = true, talent = 36554 }, -- Shadowstep
        { spell = 114018, type = "ability", buff = true, usable = true }, -- Shroud of Concealment
        { spell = 137619, type = "ability", requiresTarget = true, talent = 137619 }, -- Marked for Death
        { spell = 185311, type = "ability", buff = true, usable = true }, -- Crimson Vial
        { spell = 185313, type = "ability", talent = 185313 }, -- Shadow Dance
        { spell = 185565, type = "ability", requiresTarget = true, usable = true }, -- Poisoned Knife
        { spell = 200806, type = "ability", requiresTarget = true, usable = true, talent = 200806 }, -- Exsanguinate
        { spell = 360194, type = "ability", requiresTarget = true, usable = true, talent = 360194 }, -- Deathmark
        { spell = 381623, type = "ability", charges = true, talent = 381623 }, -- Thistle Tea
        { spell = 381802, type = "ability", buff = true, usable = true, talent = 381802 }, -- Indiscriminate Carnage
        { spell = 382245, type = "ability", buff = true, usable = true, talent = 382245 }, -- Cold Blood
        { spell = 385408, type = "ability", requiresTarget = true, usable = true, talent = 385408 }, -- Sepsis
        { spell = 385424, type = "ability", charges = true, requiresTarget = true, talent = 385424 }, -- Serrated Bone Spike
        { spell = 385616, type = "ability", requiresTarget = true, usable = true, talent = 385616 }, -- Echoing Reprimand
        { spell = 385627, type = "ability", requiresTarget = true, talent = 385627 }, -- Kingsbane
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
        { spell = 269513, type = "buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"] }, -- Death from Above
        { spell = 207777, type = "debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"] }, -- Dismantle
        { spell = 207777, type = "ability", requiresTarget = true, pvptalent = 9, titleSuffix = L["cooldown"] }, -- Dismantle
        { spell = 212182, type = "ability", pvptalent = 1, titleSuffix = L["cooldown"] }, -- Smoke Bomb
        { spell = 269513, type = "ability", buff = true, requiresTarget = true, pvptalent = 5, titleSuffix = L["cooldown"] }, -- Death from Above
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 1784, type = "buff", unit = "player" }, -- Stealth
        { spell = 1966, type = "buff", unit = "player", talent = 1966 }, -- Feint
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 3408, type = "buff", unit = "player" }, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player", talent = 5277 }, -- Evasion
        { spell = 8679, type = "buff", unit = "player" }, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 13750, type = "buff", unit = "player", talent = 13750 }, -- Adrenaline Rush
        { spell = 13877, type = "buff", unit = "player", talent = 13877 }, -- Blade Flurry
        { spell = 31224, type = "buff", unit = "player", talent = 31224 }, -- Cloak of Shadows
        { spell = 36554, type = "buff", unit = "player", talent = 36554 }, -- Shadowstep
        { spell = 51690, type = "buff", unit = "player", talent = 51690 }, -- Killing Spree
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 185422, type = "buff", unit = "player", talent = 185313 }, -- Shadow Dance
        { spell = 193356, type = "buff", unit = "player" }, -- Broadside
        { spell = 193357, type = "buff", unit = "player" }, -- Ruthless Precision
        { spell = 193358, type = "buff", unit = "player" }, -- Grand Melee
        { spell = 193538, type = "buff", unit = "player", talent = 193539 }, -- Alacrity
        { spell = 198368, type = "buff", unit = "player" }, -- Take Your Cut
        { spell = 199603, type = "buff", unit = "player" }, -- Skull and Crossbones
        { spell = 271896, type = "buff", unit = "player", talent = 271877 }, -- Blade Rush
        { spell = 315496, type = "buff", unit = "player" }, -- Slice and Dice
        { spell = 315584, type = "buff", unit = "player" }, -- Instant Poison
        { spell = 323558, type = "buff", unit = "player", talent = 385616 }, -- Echoing Reprimand
        { spell = 375939, type = "buff", unit = "player", talent = 385408 }, -- Sepsis
        { spell = 381623, type = "buff", unit = "player", talent = 381623 }, -- Thistle Tea
        { spell = 381637, type = "buff", unit = "player", talent = 381637 }, -- Atrophic Poison
        { spell = 382245, type = "buff", unit = "player", talent = 382245 }, -- Cold Blood
        { spell = 385907, type = "buff", unit = "player", talent = 382742 }, -- Take 'em by Surprise
        { spell = 386868, type = "buff", unit = "player", talent = 381990 }, -- Summarily Dispatched
        { spell = 393971, type = "buff", unit = "player", talent = 393970 }, -- Soothing Darkness
      },
      icon = 132350
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 1776, type = "debuff", unit = "target", talent = 1776 }, -- Gouge
        { spell = 1833, type = "debuff", unit = "target" }, -- Cheap Shot
        { spell = 2094, type = "debuff", unit = "target", talent = 2094 }, -- Blind
        { spell = 3409, type = "debuff", unit = "target" }, -- Crippling Poison
        { spell = 8680, type = "debuff", unit = "target" }, -- Wound Poison
        { spell = 137619, type = "debuff", unit = "target", talent = 137619 }, -- Marked for Death
        { spell = 185763, type = "debuff", unit = "target" }, -- Pistol Shot
        { spell = 212183, type = "debuff", unit = "target" }, -- Smoke Bomb
        { spell = 315341, type = "debuff", unit = "target", talent = 315341 }, -- Between the Eyes
        { spell = 316220, type = "debuff", unit = "target", talent = 91023 }, -- Find Weakness
        { spell = 385408, type = "debuff", unit = "target", talent = 385408 }, -- Sepsis
        { spell = 392388, type = "debuff", unit = "target", talent = 381637 }, -- Atrophic Poison
      },
      icon = 1373908
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, type = "ability", requiresTarget = true }, -- Kidney Shot
        { spell = 921, type = "ability", requiresTarget = true, usable = true }, -- Pick Pocket
        { spell = 1725, type = "ability" }, -- Distract
        { spell = 1766, type = "ability", requiresTarget = true }, -- Kick
        { spell = 1776, type = "ability", requiresTarget = true, talent = 1776 }, -- Gouge
        { spell = 1784, type = "ability", buff = true }, -- Stealth
        { spell = 1833, type = "ability", requiresTarget = true, usable = true }, -- Cheap Shot
        { spell = 1856, type = "ability", charges = true }, -- Vanish
        { spell = 1966, type = "ability", buff = true, talent = 1966 }, -- Feint
        { spell = 2094, type = "ability", requiresTarget = true, talent = 2094 }, -- Blind
        { spell = 2098, type = "ability", requiresTarget = true, usable = true }, -- Dispatch
        { spell = 2983, type = "ability", buff = true }, -- Sprint
        { spell = 5277, type = "ability", buff = true, talent = 5277 }, -- Evasion
        { spell = 5938, type = "ability", requiresTarget = true, talent = 5938 }, -- Shiv
        { spell = 8676, type = "ability", requiresTarget = true, usable = true }, -- Ambush
        { spell = 13750, type = "ability", buff = true, talent = 13750 }, -- Adrenaline Rush
        { spell = 13877, type = "ability", buff = true, talent = 13877 }, -- Blade Flurry
        { spell = 31224, type = "ability", buff = true, talent = 31224 }, -- Cloak of Shadows
        { spell = 36554, type = "ability", charges = true, buff = true, requiresTarget = true, talent = 36554 }, -- Shadowstep
        { spell = 51690, type = "ability", buff = true, requiresTarget = true, talent = 51690 }, -- Killing Spree
        { spell = 114018, type = "ability", usable = true }, -- Shroud of Concealment
        { spell = 137619, type = "ability", requiresTarget = true, talent = 137619 }, -- Marked for Death
        { spell = 185311, type = "ability", buff = true }, -- Crimson Vial
        { spell = 185313, type = "ability", talent = 185313 }, -- Shadow Dance
        { spell = 185763, type = "ability", requiresTarget = true }, -- Pistol Shot
        { spell = 193315, type = "ability", requiresTarget = true }, -- Sinister Strike
        { spell = 195457, type = "ability", talent = 195457 }, -- Grappling Hook
        { spell = 271877, type = "ability", requiresTarget = true, usable = true, talent = 271877 }, -- Blade Rush
        { spell = 315341, type = "ability", requiresTarget = true, talent = 315341 }, -- Between the Eyes
        { spell = 315508, type = "ability", talent = 315508 }, -- Roll the Bones
        { spell = 381623, type = "ability", charges = true, buff = true, talent = 381623 }, -- Thistle Tea
        { spell = 381989, type = "ability", talent = 381989 }, -- Keep It Rolling
        { spell = 382245, type = "ability", buff = true, usable = true, talent = 382245 }, -- Cold Blood
        { spell = 385408, type = "ability", requiresTarget = true, talent = 385408 }, -- Sepsis
        { spell = 385616, type = "ability", requiresTarget = true, talent = 385616 }, -- Echoing Reprimand
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
        { spell = 269513, type = "buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"] }, -- Death from Above
        { spell = 207777, type = "debuff", unit = "target", pvptalent = 9, titleSuffix = L["debuff"] }, -- Dismantle
        { spell = 207777, type = "ability", requiresTarget = true, pvptalent = 9, titleSuffix = L["cooldown"] }, -- Dismantle
        { spell = 212182, type = "ability", pvptalent = 1, titleSuffix = L["cooldown"] }, -- Smoke Bomb
        { spell = 269513, type = "ability", buff = true, requiresTarget = true, pvptalent = 7, titleSuffix = L["cooldown"] }, -- Death from Above
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 1784, type = "buff", unit = "player" }, -- Stealth
        { spell = 1966, type = "buff", unit = "player", talent = 1966 }, -- Feint
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 3408, type = "buff", unit = "player" }, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player", talent = 5277 }, -- Evasion
        { spell = 8679, type = "buff", unit = "player" }, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 31224, type = "buff", unit = "player", talent = 31224 }, -- Cloak of Shadows
        { spell = 36554, type = "buff", unit = "player", talent = 36554 }, -- Shadowstep
        { spell = 121471, type = "buff", unit = "player", talent = 121471 }, -- Shadow Blades
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 185422, type = "buff", unit = "player", talent = 185313 }, -- Shadow Dance
        { spell = 193538, type = "buff", unit = "player", talent = 193539 }, -- Alacrity
        { spell = 199027, type = "buff", unit = "player" }, -- Veil of Midnight
        { spell = 212283, type = "buff", unit = "player", talent = 212283 }, -- Symbols of Death
        { spell = 257506, type = "buff", unit = "player", talent = 257505 }, -- Shot in the Dark
        { spell = 277925, type = "buff", unit = "player", talent = 277925 }, -- Shuriken Tornado
        { spell = 315496, type = "buff", unit = "player" }, -- Slice and Dice
        { spell = 315584, type = "buff", unit = "player" }, -- Instant Poison
        { spell = 323560, type = "buff", unit = "player", talent = 385616 }, -- Echoing Reprimand
        { spell = 354827, type = "buff", unit = "player" }, -- Thief's Bargain
        { spell = 375939, type = "buff", unit = "player", talent = 385408 }, -- Sepsis
        { spell = 381637, type = "buff", unit = "player", talent = 381637 }, -- Atrophic Poison
        { spell = 382245, type = "buff", unit = "player", talent = 382245 }, -- Cold Blood
        { spell = 383405, type = "buff", unit = "player", talent = 382517 }, -- Deeper Daggers
        { spell = 384631, type = "buff", unit = "player", talent = 384631 }, -- Flagellation
        { spell = 385727, type = "buff", unit = "player", talent = 385722 }, -- Silent Storm
        { spell = 385960, type = "buff", unit = "player", talent = 382524 }, -- Lingering Shadow
        { spell = 393969, type = "buff", unit = "player", talent = 382528 }, -- Danse Macabre
        { spell = 393971, type = "buff", unit = "player", talent = 393970 }, -- Soothing Darkness
        { spell = 394254, type = "buff", unit = "player", talent = 382518 }, -- Perforated Veins
      },
      icon = 376022
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 1776, type = "debuff", unit = "target", talent = 1776 }, -- Gouge
        { spell = 1943, type = "debuff", unit = "target" }, -- Rupture
        { spell = 2094, type = "debuff", unit = "target", talent = 2094 }, -- Blind
        { spell = 3409, type = "debuff", unit = "target" }, -- Crippling Poison
        { spell = 8680, type = "debuff", unit = "target" }, -- Wound Poison
        { spell = 137619, type = "debuff", unit = "target", talent = 137619 }, -- Marked for Death
        { spell = 206760, type = "debuff", unit = "target" }, -- Shadow's Grasp
        { spell = 212183, type = "debuff", unit = "target" }, -- Smoke Bomb
        { spell = 316220, type = "debuff", unit = "target", talent = 91023 }, -- Find Weakness
        { spell = 384631, type = "debuff", unit = "target", talent = 384631 }, -- Flagellation
        { spell = 385408, type = "debuff", unit = "target", talent = 385408 }, -- Sepsis
        { spell = 392388, type = "debuff", unit = "target", talent = 381637 }, -- Atrophic Poison
      },
      icon = 136175
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 53, type = "ability", requiresTarget = true }, -- Backstab
        { spell = 408, type = "ability", requiresTarget = true }, -- Kidney Shot
        { spell = 921, type = "ability", requiresTarget = true, usable = true }, -- Pick Pocket
        { spell = 1725, type = "ability" }, -- Distract
        { spell = 1766, type = "ability", requiresTarget = true }, -- Kick
        { spell = 1776, type = "ability", requiresTarget = true, talent = 1776 }, -- Gouge
        { spell = 1784, type = "ability", buff = true }, -- Stealth
        { spell = 1833, type = "ability", requiresTarget = true, usable = true }, -- Cheap Shot
        { spell = 1856, type = "ability", charges = true }, -- Vanish
        { spell = 1943, type = "ability", requiresTarget = true }, -- Rupture
        { spell = 1966, type = "ability", buff = true, talent = 1966 }, -- Feint
        { spell = 2094, type = "ability", requiresTarget = true, talent = 2094 }, -- Blind
        { spell = 2983, type = "ability", buff = true }, -- Sprint
        { spell = 5277, type = "ability", buff = true, talent = 5277 }, -- Evasion
        { spell = 5938, type = "ability", requiresTarget = true, talent = 5938 }, -- Shiv
        { spell = 31224, type = "ability", buff = true, talent = 31224 }, -- Cloak of Shadows
        { spell = 36554, type = "ability", charges = true, buff = true, requiresTarget = true, talent = 36554 }, -- Shadowstep
        { spell = 114014, type = "ability", requiresTarget = true }, -- Shuriken Toss
        { spell = 114018, type = "ability", usable = true }, -- Shroud of Concealment
        { spell = 121471, type = "ability", buff = true, talent = 121471 }, -- Shadow Blades
        { spell = 137619, type = "ability", requiresTarget = true, talent = 137619 }, -- Marked for Death
        { spell = 185311, type = "ability", buff = true }, -- Crimson Vial
        { spell = 185313, type = "ability", charges = true, talent = 185313 }, -- Shadow Dance
        { spell = 185438, type = "ability", requiresTarget = true, usable = true }, -- Shadowstrike
        { spell = 196819, type = "ability", requiresTarget = true }, -- Eviscerate
        { spell = 200758, type = "ability", requiresTarget = true, talent = 200758 }, -- Gloomblade
        { spell = 212283, type = "ability", buff = true, talent = 212283 }, -- Symbols of Death
        { spell = 277925, type = "ability", buff = true, talent = 277925 }, -- Shuriken Tornado
        { spell = 280719, type = "ability", requiresTarget = true, talent = 280719 }, -- Secret Technique
        { spell = 381623, type = "ability", charges = true, talent = 381623 }, -- Thistle Tea
        { spell = 382245, type = "ability", buff = true, talent = 382245 }, -- Cold Blood
        { spell = 384631, type = "ability", buff = true, requiresTarget = true, talent = 384631 }, -- Flagellation
        { spell = 385408, type = "ability", requiresTarget = true, talent = 385408 }, -- Sepsis
        { spell = 385616, type = "ability", requiresTarget = true, talent = 385616 }, -- Echoing Reprimand
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
        { spell = 269513, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Death from Above
        { spell = 269513, type = "ability", buff = true, requiresTarget = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Death from Above
        { spell = 359053, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"] }, -- Smoke Bomb
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 17, type = "buff", unit = "player" }, -- Power Word: Shield
        { spell = 139, type = "buff", unit = "player", talent = 139 }, -- Renew
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 2096, type = "buff", unit = "player" }, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player", talent = 10060 }, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player", talent = 15286 }, -- Vampiric Embrace
        { spell = 19236, type = "buff", unit = "player" }, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player" }, -- Power Word: Fortitude
        { spell = 33206, type = "buff", unit = "player", talent = 33206 }, -- Pain Suppression
        { spell = 41635, type = "buff", unit = "player", talent = 33076 }, -- Prayer of Mending
        { spell = 47536, type = "buff", unit = "player", talent = 47536 }, -- Rapture
        { spell = 65081, type = "buff", unit = "player", talent = 64129 }, -- Body and Soul
        { spell = 81782, type = "buff", unit = "player", talent = 62618 }, -- Power Word: Barrier
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 114255, type = "buff", unit = "player", talent = 109186 }, -- Surge of Light
        { spell = 121557, type = "buff", unit = "player", talent = 121536 }, -- Angelic Feather
        { spell = 193065, type = "buff", unit = "player", talent = 193063 }, -- Protective Light
        { spell = 194384, type = "buff", unit = "player", talent = 81749 }, -- Atonement
        { spell = 198069, type = "buff", unit = "player", talent = 198068 }, -- Power of the Dark Side
        { spell = 280398, type = "buff", unit = "player", talent = 280391 }, -- Sins of the Many
        { spell = 322105, type = "buff", unit = "player", talent = 314867 }, -- Shadow Covenant
        { spell = 358134, type = "buff", unit = "player" }, -- Star Burst
        { spell = 373181, type = "buff", unit = "player", talent = 373180 }, -- Harsh Discipline
        { spell = 390636, type = "buff", unit = "player", talent = 390622 }, -- Rhapsody
        { spell = 390677, type = "buff", unit = "player", talent = 390676 }, -- Inspiration
        { spell = 390692, type = "buff", unit = "player", talent = 390691 }, -- Borrowed Time
        { spell = 390706, type = "buff", unit = "player", talent = 390705 }, -- Twilight Equilibrium
        { spell = 390787, type = "buff", unit = "player", talent = 390786 }, -- Weal and Woe
      },
      icon = 135940
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 2096, type = "debuff", unit = "target" }, -- Mind Vision
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 204213, type = "debuff", unit = "target", talent = 204197 }, -- Purge the Wicked
        { spell = 214621, type = "debuff", unit = "target", talent = 214621 }, -- Schism
        { spell = 375901, type = "debuff", unit = "target", talent = 375901 }, -- Mindgames
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability", buff = true }, -- Power Word: Shield
        { spell = 453, type = "ability" }, -- Mind Soothe
        { spell = 527, type = "ability", charges = true }, -- Purify
        { spell = 528, type = "ability", requiresTarget = true, talent = 528 }, -- Dispel Magic
        { spell = 585, type = "ability", requiresTarget = true }, -- Smite
        { spell = 586, type = "ability", buff = true }, -- Fade
        { spell = 589, type = "ability", requiresTarget = true }, -- Shadow Word: Pain
        { spell = 8092, type = "ability", charges = true, requiresTarget = true }, -- Mind Blast
        { spell = 8122, type = "ability" }, -- Psychic Scream
        { spell = 10060, type = "ability", buff = true, talent = 10060 }, -- Power Infusion
        { spell = 15286, type = "ability", buff = true, talent = 15286 }, -- Vampiric Embrace
        { spell = 19236, type = "ability", buff = true }, -- Desperate Prayer
        { spell = 32375, type = "ability", talent = 32375 }, -- Mass Dispel
        { spell = 32379, type = "ability", overlayGlow = true, requiresTarget = true, talent = 32379 }, -- Shadow Word: Death
        { spell = 33076, type = "ability", talent = 33076 }, -- Prayer of Mending
        { spell = 33206, type = "ability", buff = true, talent = 33206 }, -- Pain Suppression
        { spell = 34433, type = "ability", requiresTarget = true, totem = true, talent = 34433 }, -- Shadowfiend
        { spell = 47536, type = "ability", buff = true, talent = 47536 }, -- Rapture
        { spell = 47540, type = "ability", requiresTarget = true }, -- Penance
        { spell = 62618, type = "ability", talent = 62618 }, -- Power Word: Barrier
        { spell = 108920, type = "ability", talent = 108920 }, -- Void Tendrils
        { spell = 110744, type = "ability", talent = 110744 }, -- Divine Star
        { spell = 120517, type = "ability", talent = 120517 }, -- Halo
        { spell = 121536, type = "ability", charges = true, talent = 121536 }, -- Angelic Feather
        { spell = 122121, type = "ability", talent = 122121 }, -- Divine Star
        { spell = 123040, type = "ability", totem = true, talent = 123040 }, -- Mindbender
        { spell = 129250, type = "ability", requiresTarget = true, talent = 129250 }, -- Power Word: Solace
        { spell = 194509, type = "ability", charges = true, talent = 194509 }, -- Power Word: Radiance
        { spell = 204197, type = "ability", requiresTarget = true, talent = 204197 }, -- Purge the Wicked
        { spell = 205364, type = "ability", talent = 205364 }, -- Dominate Mind
        { spell = 214621, type = "ability", requiresTarget = true, talent = 214621 }, -- Schism
        { spell = 314867, type = "ability", talent = 314867 }, -- Shadow Covenant
        { spell = 373129, type = "ability" }, -- Dark Reprimand
        { spell = 373178, type = "ability", requiresTarget = true, talent = 373178 }, -- Light's Wrath
        { spell = 373481, type = "ability", talent = 373481 }, -- Power Word: Life
        { spell = 375901, type = "ability", requiresTarget = true, talent = 375901 }, -- Mindgames
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
        { spell = 197862, type = "buff", unit = "player", pvptalent = 14, titleSuffix = L["buff"] }, -- Archangel
        { spell = 197871, type = "buff", unit = "player", pvptalent = 13, titleSuffix = L["buff"] }, -- Dark Archangel
        { spell = 197862, type = "ability", buff = true, pvptalent = 14, titleSuffix = L["cooldown"] }, -- Archangel
        { spell = 197871, type = "ability", buff = true, pvptalent = 13, titleSuffix = L["cooldown"] }, -- Dark Archangel
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 17, type = "buff", unit = "player" }, -- Power Word: Shield
        { spell = 139, type = "buff", unit = "player", talent = 139 }, -- Renew
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 2096, type = "buff", unit = "player" }, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player", talent = 10060 }, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player", talent = 15286 }, -- Vampiric Embrace
        { spell = 19236, type = "buff", unit = "player" }, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player" }, -- Power Word: Fortitude
        { spell = 41635, type = "buff", unit = "player", talent = 33076 }, -- Prayer of Mending
        { spell = 47788, type = "buff", unit = "player", talent = 47788 }, -- Guardian Spirit
        { spell = 64843, type = "buff", unit = "player", talent = 64843 }, -- Divine Hymn
        { spell = 64901, type = "buff", unit = "player", talent = 64901 }, -- Symbol of Hope
        { spell = 65081, type = "buff", unit = "player", talent = 64129 }, -- Body and Soul
        { spell = 77489, type = "buff", unit = "player" }, -- Echo of Light
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 121557, type = "buff", unit = "player", talent = 121536 }, -- Angelic Feather
        { spell = 193065, type = "buff", unit = "player", talent = 193063 }, -- Protective Light
        { spell = 196490, type = "buff", unit = "player", talent = 196489 }, -- Sanctified Prayers
        { spell = 232707, type = "buff", unit = "player" }, -- Ray of Hope
        { spell = 280398, type = "buff", unit = "player", talent = 280391 }, -- Sins of the Many
        { spell = 289655, type = "buff", unit = "player" }, -- Sanctified Ground
        { spell = 372313, type = "buff", unit = "player", talent = 372309 }, -- Resonant Words
        { spell = 372617, type = "buff", unit = "player", talent = 372616 }, -- Empyreal Blaze
        { spell = 372760, type = "buff", unit = "player", talent = 372760 }, -- Divine Word
        { spell = 390636, type = "buff", unit = "player", talent = 390622 }, -- Rhapsody
        { spell = 390677, type = "buff", unit = "player", talent = 390676 }, -- Inspiration
        { spell = 390885, type = "buff", unit = "player", talent = 390881 }, -- Healing Chorus
        { spell = 390989, type = "buff", unit = "player", talent = 390980 }, -- Pontifex
        { spell = 390993, type = "buff", unit = "player", talent = 390992 }, -- Lightweaver
        { spell = 391314, type = "buff", unit = "player" }, -- Catharsis
        { spell = 392990, type = "buff", unit = "player", talent = 392988 }, -- Divine Image
      },
      icon = 135953
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 2096, type = "debuff", unit = "target" }, -- Mind Vision
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 14914, type = "debuff", unit = "target", talent = 14914 }, -- Holy Fire
        { spell = 200200, type = "debuff", unit = "target", talent = 88625 }, -- Holy Word: Chastise
        { spell = 390669, type = "debuff", unit = "target", talent = 390668 }, -- Apathy
      },
      icon = 135972
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability", buff = true, debuff = true }, -- Power Word: Shield
        { spell = 453, type = "ability" }, -- Mind Soothe
        { spell = 527, type = "ability" }, -- Purify
        { spell = 528, type = "ability", requiresTarget = true, talent = 528 }, -- Dispel Magic
        { spell = 585, type = "ability", requiresTarget = true }, -- Smite
        { spell = 586, type = "ability", buff = true }, -- Fade
        { spell = 589, type = "ability", requiresTarget = true }, -- Shadow Word: Pain
        { spell = 2050, type = "ability", overlayGlow = true, talent = 2050 }, -- Holy Word: Serenity
        { spell = 8122, type = "ability" }, -- Psychic Scream
        { spell = 10060, type = "ability", buff = true, talent = 10060 }, -- Power Infusion
        { spell = 14914, type = "ability", overlayGlow = true, requiresTarget = true, talent = 14914 }, -- Holy Fire
        { spell = 15286, type = "ability", buff = true, talent = 15286 }, -- Vampiric Embrace
        { spell = 19236, type = "ability", buff = true }, -- Desperate Prayer
        { spell = 32375, type = "ability", talent = 32375 }, -- Mass Dispel
        { spell = 32379, type = "ability", overlayGlow = true, requiresTarget = true, talent = 32379 }, -- Shadow Word: Death
        { spell = 33076, type = "ability", talent = 33076 }, -- Prayer of Mending
        { spell = 34433, type = "ability", requiresTarget = true, totem = true, talent = 34433 }, -- Shadowfiend
        { spell = 34861, type = "ability", overlayGlow = true, talent = 34861 }, -- Holy Word: Sanctify
        { spell = 47788, type = "ability", buff = true, talent = 47788 }, -- Guardian Spirit
        { spell = 64843, type = "ability", buff = true, talent = 64843 }, -- Divine Hymn
        { spell = 64901, type = "ability", buff = true, talent = 64901 }, -- Symbol of Hope
        { spell = 88625, type = "ability", overlayGlow = true, requiresTarget = true, talent = 88625 }, -- Holy Word: Chastise
        { spell = 121536, type = "ability", charges = true, talent = 121536 }, -- Angelic Feather
        { spell = 200183, type = "ability", talent = 200183 }, -- Apotheosis
        { spell = 204883, type = "ability", talent = 204883 }, -- Circle of Healing
        { spell = 205364, type = "ability", talent = 205364 }, -- Dominate Mind
        { spell = 265202, type = "ability", talent = 265202 }, -- Holy Word: Salvation
        { spell = 312411, type = "ability" }, -- Bag of Tricks
        { spell = 312425, type = "ability" }, -- Rummage Your Bag
        { spell = 372616, type = "ability", talent = 372616 }, -- Empyreal Blaze
        { spell = 372760, type = "ability", buff = true, talent = 372760 }, -- Divine Word
        { spell = 372835, type = "ability", totem = true, talent = 372835 }, -- Lightwell
        { spell = 373481, type = "ability", talent = 373481 }, -- Power Word: Life
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
        { spell = 213610, type = "buff", unit = "player", pvptalent = 12, titleSuffix = L["buff"] }, -- Holy Ward
        { spell = 197268, type = "ability", pvptalent = 7, titleSuffix = L["cooldown"] }, -- Ray of Hope
        { spell = 213610, type = "ability", buff = true, pvptalent = 12, titleSuffix = L["cooldown"] }, -- Holy Ward
        { spell = 289666, type = "ability", pvptalent = 10, titleSuffix = L["cooldown"] }, -- Greater Heal
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 17, type = "buff", unit = "player" }, -- Power Word: Shield
        { spell = 139, type = "buff", unit = "player", talent = 139 }, -- Renew
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 10060, type = "buff", unit = "player", talent = 10060 }, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player", talent = 15286 }, -- Vampiric Embrace
        { spell = 21562, type = "buff", unit = "player" }, -- Power Word: Fortitude
        { spell = 41635, type = "buff", unit = "player", talent = 33076 }, -- Prayer of Mending
        { spell = 47585, type = "buff", unit = "player", talent = 47585 }, -- Dispersion
        { spell = 65081, type = "buff", unit = "player", talent = 64129 }, -- Body and Soul
        { spell = 87160, type = "buff", unit = "player", talent = 162448 }, -- Surge of Darkness
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 114255, type = "buff", unit = "player", talent = 109186 }, -- Surge of Light
        { spell = 193065, type = "buff", unit = "player", talent = 193063 }, -- Protective Light
        { spell = 232698, type = "buff", unit = "player" }, -- Shadowform
        { spell = 280398, type = "buff", unit = "player", talent = 280391 }, -- Sins of the Many
        { spell = 375981, type = "buff", unit = "player", talent = 375888 }, -- Shadowy Insight
        { spell = 377066, type = "buff", unit = "player", talent = 377065 }, -- Mental Fortitude
        { spell = 390636, type = "buff", unit = "player", talent = 390622 }, -- Rhapsody
        { spell = 390677, type = "buff", unit = "player", talent = 390676 }, -- Inspiration
        { spell = 391092, type = "buff", unit = "player", talent = 391090 }, -- Mind Melt
        { spell = 391099, type = "buff", unit = "player", talent = 391095 }, -- Dark Evangelism
        { spell = 391109, type = "buff", unit = "player", talent = 391109 }, -- Dark Ascension
        { spell = 391243, type = "buff", unit = "player", talent = 391242 }, -- Coalescing Shadows
        { spell = 391314, type = "buff", unit = "player" }, -- Catharsis
        { spell = 391401, type = "buff", unit = "player", talent = 391399 }, -- Mind Flay: Insanity
      },
      icon = 237566
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 15407, type = "debuff", unit = "target" }, -- Mind Flay
        { spell = 15487, type = "debuff", unit = "target", talent = 15487 }, -- Silence
        { spell = 34914, type = "debuff", unit = "target" }, -- Vampiric Touch
        { spell = 48045, type = "debuff", unit = "target", talent = 48045 }, -- Mind Sear
        { spell = 64044, type = "debuff", unit = "target", talent = 64044 }, -- Psychic Horror
        { spell = 199845, type = "debuff", unit = "target" }, -- Psyflay
        { spell = 263165, type = "debuff", unit = "target", talent = 263165 }, -- Void Torrent
        { spell = 322098, type = "debuff", unit = "target", talent = 321291 }, -- Death and Madness
        { spell = 335467, type = "debuff", unit = "target", talent = 335467 }, -- Devouring Plague
        { spell = 375901, type = "debuff", unit = "target", talent = 375901 }, -- Mindgames
        { spell = 390669, type = "debuff", unit = "target", talent = 390668 }, -- Apathy
        { spell = 391403, type = "debuff", unit = "target", talent = 391399 }, -- Mind Flay: Insanity
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability", buff = true }, -- Power Word: Shield
        { spell = 453, type = "ability" }, -- Mind Soothe
        { spell = 528, type = "ability", requiresTarget = true, talent = 528 }, -- Dispel Magic
        { spell = 586, type = "ability", buff = true }, -- Fade
        { spell = 589, type = "ability", requiresTarget = true }, -- Shadow Word: Pain
        { spell = 8092, type = "ability", charges = true, overlayGlow = true, requiresTarget = true }, -- Mind Blast
        { spell = 8122, type = "ability" }, -- Psychic Scream
        { spell = 10060, type = "ability", buff = true, talent = 10060 }, -- Power Infusion
        { spell = 15286, type = "ability", buff = true, talent = 15286 }, -- Vampiric Embrace
        { spell = 15407, type = "ability", requiresTarget = true }, -- Mind Flay
        { spell = 15487, type = "ability", requiresTarget = true, talent = 15487 }, -- Silence
        { spell = 32375, type = "ability", talent = 32375 }, -- Mass Dispel
        { spell = 32379, type = "ability", overlayGlow = true, requiresTarget = true, talent = 32379 }, -- Shadow Word: Death
        { spell = 33076, type = "ability", talent = 33076 }, -- Prayer of Mending
        { spell = 34433, type = "ability", requiresTarget = true, totem = true, talent = 34433 }, -- Shadowfiend
        { spell = 34914, type = "ability", requiresTarget = true }, -- Vampiric Touch
        { spell = 47585, type = "ability", buff = true, talent = 47585 }, -- Dispersion
        { spell = 48045, type = "ability", requiresTarget = true, usable = true, talent = 48045 }, -- Mind Sear
        { spell = 64044, type = "ability", requiresTarget = true, talent = 64044 }, -- Psychic Horror
        { spell = 73510, type = "ability", overlayGlow = true, requiresTarget = true, talent = 73510 }, -- Mind Spike
        { spell = 120644, type = "ability", talent = 120644 }, -- Halo
        { spell = 121536, type = "ability", charges = true, talent = 121536 }, -- Angelic Feather
        { spell = 122121, type = "ability", talent = 122121 }, -- Divine Star
        { spell = 200174, type = "ability", requiresTarget = true, totem = true, talent = 200174 }, -- Mindbender
        { spell = 205385, type = "ability", talent = 205385 }, -- Shadow Crash
        { spell = 263165, type = "ability", requiresTarget = true, talent = 263165 }, -- Void Torrent
        { spell = 335467, type = "ability", requiresTarget = true, usable = true, talent = 335467 }, -- Devouring Plague
        { spell = 341374, type = "ability", requiresTarget = true, talent = 341374 }, -- Damnation
        { spell = 373481, type = "ability", talent = 373481 }, -- Power Word: Life
        { spell = 375901, type = "ability", requiresTarget = true, talent = 375901 }, -- Mindgames
        { spell = 391109, type = "ability", buff = true, talent = 391109 }, -- Dark Ascension
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
        { spell = 211522, type = "ability", requiresTarget = true, pvptalent = 12, titleSuffix = L["cooldown"] }, -- Psyfiend
        { spell = 316262, type = "ability", pvptalent = 1, titleSuffix = L["cooldown"] }, -- Thoughtsteal
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 546, type = "buff", unit = "player" }, -- Water Walking
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 2825, type = "buff", unit = "player" }, -- Bloodlust
        { spell = 6196, type = "buff", unit = "player" }, -- Far Sight
        { spell = 8178, type = "buff", unit = "player" }, -- Grounding Totem Effect
        { spell = 58875, type = "buff", unit = "player", talent = 58875 }, -- Spirit Walk
        { spell = 77762, type = "buff", unit = "player", talent = 77756 }, -- Lava Surge
        { spell = 79206, type = "buff", unit = "player", talent = 79206 }, -- Spiritwalker's Grace
        { spell = 108271, type = "buff", unit = "player", talent = 108271 }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 108281 }, -- Ancestral Guidance
        { spell = 114050, type = "buff", unit = "player", talent = 114050 }, -- Ascendance
        { spell = 118522, type = "buff", unit = "player" }, -- Elemental Blast: Critical Strike
        { spell = 173183, type = "buff", unit = "player" }, -- Elemental Blast: Haste
        { spell = 173184, type = "buff", unit = "player" }, -- Elemental Blast: Mastery
        { spell = 191634, type = "buff", unit = "player", talent = 191634 }, -- Stormkeeper
        { spell = 191877, type = "buff", unit = "player", talent = 191861 }, -- Power of the Maelstrom
        { spell = 192082, type = "buff", unit = "player" }, -- Wind Rush
        { spell = 192106, type = "buff", unit = "player" }, -- Lightning Shield
        { spell = 208963, type = "buff", unit = "player" }, -- Skyfury Totem
        { spell = 210714, type = "buff", unit = "player", talent = 210714 }, -- Icefury
        { spell = 236502, type = "buff", unit = "player" }, -- Tidebringer
        { spell = 260734, type = "buff", unit = "player", talent = 16166 }, -- Master of the Elements
        { spell = 285514, type = "buff", unit = "player", talent = 262303 }, -- Surge of Power
        { spell = 375986, type = "buff", unit = "player", talent = 375982 }, -- Primordial Wave
        { spell = 378081, type = "buff", unit = "player", talent = 378081 }, -- Nature's Swiftness
        { spell = 378102, type = "buff", unit = "player", talent = 378094 }, -- Swirling Currents
        { spell = 378269, type = "buff", unit = "player", talent = 378268 }, -- Windspeaker's Lava Resurgence
        { spell = 378275, type = "buff", unit = "player", talent = 378271 }, -- Elemental Equilibrium
        { spell = 381668, type = "buff", unit = "player", talent = 381666 }, -- Focused Insight
        { spell = 381755, type = "buff", unit = "player", talent = 198103 }, -- Earth Elemental
        { spell = 381761, type = "buff", unit = "player", talent = 381764 }, -- Primordial Bond
        { spell = 381777, type = "buff", unit = "player", talent = 381776 }, -- Flux Melting
        { spell = 381786, type = "buff", unit = "player", talent = 381785 }, -- Oath of the Far Seer
        { spell = 381933, type = "buff", unit = "player", talent = 381932 }, -- Magma Chamber
        { spell = 382028, type = "buff", unit = "player", talent = 382027 }, -- Improved Flametongue Weapon
        { spell = 382889, type = "buff", unit = "player", talent = 382888 }, -- Flurry
        { spell = 383018, type = "buff", unit = "player" }, -- Stoneskin
        { spell = 383020, type = "buff", unit = "player" }, -- Tranquil Air
        { spell = 383648, type = "buff", unit = "player", talent = 974 }, -- Earth Shield
        { spell = 384088, type = "buff", unit = "player", talent = 384087 }, -- Echoes of Great Sundering
        { spell = 395197, type = "buff", unit = "player", talent = 381930 }, -- Mana Spring Totem
      },
      icon = 135863
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3600, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 51490, type = "debuff", unit = "target", talent = 51490 }, -- Thunderstorm
        { spell = 118297, type = "debuff", unit = "target" }, -- Immolate
        { spell = 118905, type = "debuff", unit = "target", talent = 265046 }, -- Static Charge
        { spell = 188389, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 196840, type = "debuff", unit = "target", talent = 196840 }, -- Frost Shock
        { spell = 197209, type = "debuff", unit = "target", talent = 210689 }, -- Lightning Rod
        { spell = 208997, type = "debuff", unit = "target" }, -- Counterstrike Totem
        { spell = 305485, type = "debuff", unit = "target", talent = 305483 }, -- Lightning Lasso
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 370, type = "ability", requiresTarget = true, talent = 370 }, -- Purge
        { spell = 556, type = "ability", usable = true }, -- Astral Recall
        { spell = 2484, type = "ability", totem = true }, -- Earthbind Totem
        { spell = 2825, type = "ability", buff = true }, -- Bloodlust
        { spell = 5394, type = "ability", talent = 5394 }, -- Healing Stream Totem
        { spell = 8042, type = "ability", overlayGlow = true, requiresTarget = true, talent = 8042 }, -- Earth Shock
        { spell = 8143, type = "ability", totem = true, talent = 8143 }, -- Tremor Totem
        { spell = 51490, type = "ability", talent = 51490 }, -- Thunderstorm
        { spell = 51505, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 51505 }, -- Lava Burst
        { spell = 51514, type = "ability", talent = 51514 }, -- Hex
        { spell = 51886, type = "ability", talent = 51886 }, -- Cleanse Spirit
        { spell = 57994, type = "ability", requiresTarget = true, talent = 57994 }, -- Wind Shear
        { spell = 58875, type = "ability", buff = true, talent = 58875 }, -- Spirit Walk
        { spell = 73899, type = "ability", requiresTarget = true }, -- Primal Strike
        { spell = 79206, type = "ability", buff = true, talent = 79206 }, -- Spiritwalker's Grace
        { spell = 108271, type = "ability", buff = true, talent = 108271 }, -- Astral Shift
        { spell = 108281, type = "ability", buff = true, talent = 108281 }, -- Ancestral Guidance
        { spell = 108285, type = "ability", talent = 108285 }, -- Totemic Recall
        { spell = 108287, type = "ability", talent = 108287 }, -- Totemic Projection
        { spell = 114050, type = "ability", buff = true, talent = 114050 }, -- Ascendance
        { spell = 117014, type = "ability", overlayGlow = true, requiresTarget = true, talent = 117014 }, -- Elemental Blast
        { spell = 188196, type = "ability", overlayGlow = true, requiresTarget = true }, -- Lightning Bolt
        { spell = 188389, type = "ability", requiresTarget = true }, -- Flame Shock
        { spell = 188443, type = "ability", overlayGlow = true, requiresTarget = true, talent = 188443 }, -- Chain Lightning
        { spell = 191634, type = "ability", charges = true, buff = true, talent = 191634 }, -- Stormkeeper
        { spell = 192058, type = "ability", totem = true, talent = 192058 }, -- Capacitor Totem
        { spell = 192063, type = "ability", talent = 192063 }, -- Gust of Wind
        { spell = 192077, type = "ability", totem = true, talent = 192077 }, -- Wind Rush Totem
        { spell = 192222, type = "ability", totem = true, talent = 192222 }, -- Liquid Magma Totem
        { spell = 192249, type = "ability", requiresTarget = true, talent = 192249 }, -- Storm Elemental
        { spell = 196840, type = "ability", requiresTarget = true, talent = 196840 }, -- Frost Shock
        { spell = 198067, type = "ability", requiresTarget = true, totem = true, talent = 198067 }, -- Fire Elemental
        { spell = 198103, type = "ability", requiresTarget = true, totem = true, talent = 198103 }, -- Earth Elemental
        { spell = 210714, type = "ability", buff = true, requiresTarget = true, talent = 210714 }, -- Icefury
        { spell = 305483, type = "ability", requiresTarget = true, talent = 305483 }, -- Lightning Lasso
        { spell = 375982, type = "ability", requiresTarget = true, talent = 375982 }, -- Primordial Wave
        { spell = 378081, type = "ability", buff = true, usable = true, talent = 378081 }, -- Nature's Swiftness
        { spell = 383013, type = "ability", totem = true, talent = 383013 }, -- Poison Cleansing Totem
        { spell = 383017, type = "ability", totem = true, talent = 383017 }, -- Stoneskin Totem
        { spell = 383019, type = "ability", totem = true, talent = 383019 }, -- Tranquil Air Totem
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
        { spell = 204330, type = "ability", totem = true, pvptalent = 10, titleSuffix = L["cooldown"] }, -- Skyfury Totem
        { spell = 204331, type = "ability", totem = true, pvptalent = 9, titleSuffix = L["cooldown"] }, -- Counterstrike Totem
        { spell = 204336, type = "ability", totem = true, pvptalent = 12, titleSuffix = L["cooldown"] }, -- Grounding Totem
        { spell = 355580, type = "ability", totem = true, pvptalent = 7, titleSuffix = L["cooldown"] }, -- Static Field Totem
        { spell = 356736, type = "ability", requiresTarget = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Unleash Shield
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 546, type = "buff", unit = "player" }, -- Water Walking
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 2825, type = "buff", unit = "player" }, -- Bloodlust
        { spell = 8178, type = "buff", unit = "player" }, -- Grounding Totem Effect
        { spell = 58875, type = "buff", unit = "player", talent = 58875 }, -- Spirit Walk
        { spell = 79206, type = "buff", unit = "player", talent = 79206 }, -- Spiritwalker's Grace
        { spell = 108271, type = "buff", unit = "player", talent = 108271 }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 108281 }, -- Ancestral Guidance
        { spell = 114051, type = "buff", unit = "player", talent = 114051 }, -- Ascendance
        { spell = 118522, type = "buff", unit = "player" }, -- Elemental Blast: Critical Strike
        { spell = 173183, type = "buff", unit = "player" }, -- Elemental Blast: Haste
        { spell = 173184, type = "buff", unit = "player" }, -- Elemental Blast: Mastery
        { spell = 187878, type = "buff", unit = "player", talent = 187874 }, -- Crash Lightning
        { spell = 192082, type = "buff", unit = "player" }, -- Wind Rush
        { spell = 192106, type = "buff", unit = "player" }, -- Lightning Shield
        { spell = 198300, type = "buff", unit = "player", talent = 384363 }, -- Gathering Storms
        { spell = 201846, type = "buff", unit = "player" }, -- Stormbringer
        { spell = 208963, type = "buff", unit = "player" }, -- Skyfury Totem
        { spell = 215785, type = "buff", unit = "player", talent = 201900 }, -- Hot Hand
        { spell = 224125, type = "buff", unit = "player" }, -- Molten Weapon
        { spell = 224126, type = "buff", unit = "player" }, -- Icy Edge
        { spell = 224127, type = "buff", unit = "player" }, -- Crackling Surge
        { spell = 236502, type = "buff", unit = "player" }, -- Tidebringer
        { spell = 262652, type = "buff", unit = "player", talent = 262647 }, -- Forceful Winds
        { spell = 327942, type = "buff", unit = "player", talent = 8512 }, -- Windfury Totem
        { spell = 333957, type = "buff", unit = "player", talent = 51533 }, -- Feral Spirit
        { spell = 334196, type = "buff", unit = "player", talent = 334195 }, -- Hailstorm
        { spell = 344179, type = "buff", unit = "player", talent = 187880 }, -- Maelstrom Weapon
        { spell = 375986, type = "buff", unit = "player", talent = 375982 }, -- Primordial Wave
        { spell = 378081, type = "buff", unit = "player", talent = 378081 }, -- Nature's Swiftness
        { spell = 378102, type = "buff", unit = "player", talent = 378094 }, -- Swirling Currents
        { spell = 381668, type = "buff", unit = "player", talent = 381666 }, -- Focused Insight
        { spell = 381755, type = "buff", unit = "player", talent = 198103 }, -- Earth Elemental
        { spell = 382028, type = "buff", unit = "player", talent = 382027 }, -- Improved Flametongue Weapon
        { spell = 382217, type = "buff", unit = "player", talent = 382215 }, -- Winds of Al'Akir
        { spell = 382889, type = "buff", unit = "player", talent = 382888 }, -- Flurry
        { spell = 383018, type = "buff", unit = "player" }, -- Stoneskin
        { spell = 383648, type = "buff", unit = "player", talent = 974 }, -- Earth Shield
        { spell = 384352, type = "buff", unit = "player", talent = 384352 }, -- Doom Winds
        { spell = 384357, type = "buff", unit = "player", talent = 342240 }, -- Ice Strike
        { spell = 384451, type = "buff", unit = "player", talent = 384450 }, -- Legacy of the Frost Witch
        { spell = 390371, type = "buff", unit = "player", talent = 390370 }, -- Ashen Catalyst
        { spell = 392375, type = "buff", unit = "player" }, -- Earthen Weapon
      },
      icon = 136099
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3600, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 51490, type = "debuff", unit = "target", talent = 51490 }, -- Thunderstorm
        { spell = 64695, type = "debuff", unit = "target" }, -- Earthgrab
        { spell = 118905, type = "debuff", unit = "target", talent = 265046 }, -- Static Charge
        { spell = 188389, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 196840, type = "debuff", unit = "target", talent = 196840 }, -- Frost Shock
        { spell = 197214, type = "debuff", unit = "target", talent = 197214 }, -- Sundering
        { spell = 208997, type = "debuff", unit = "target" }, -- Counterstrike Totem
        { spell = 305485, type = "debuff", unit = "target", talent = 305483 }, -- Lightning Lasso
        { spell = 334168, type = "debuff", unit = "target", talent = 334046 }, -- Lashing Flames
        { spell = 342240, type = "debuff", unit = "target", talent = 342240 }, -- Ice Strike
      },
      icon = 462327
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 370, type = "ability", requiresTarget = true, talent = 370 }, -- Purge
        { spell = 556, type = "ability", usable = true }, -- Astral Recall
        { spell = 2484, type = "ability", totem = true }, -- Earthbind Totem
        { spell = 2825, type = "ability", buff = true }, -- Bloodlust
        { spell = 5394, type = "ability", totem = true, talent = 5394 }, -- Healing Stream Totem
        { spell = 17364, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 17364 }, -- Stormstrike
        { spell = 51485, type = "ability", totem = true, talent = 51485 }, -- Earthgrab Totem
        { spell = 51490, type = "ability", talent = 51490 }, -- Thunderstorm
        { spell = 51505, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 51505 }, -- Lava Burst
        { spell = 51514, type = "ability", talent = 51514 }, -- Hex
        { spell = 51533, type = "ability", requiresTarget = true, talent = 51533 }, -- Feral Spirit
        { spell = 57994, type = "ability", requiresTarget = true, talent = 57994 }, -- Wind Shear
        { spell = 58875, type = "ability", buff = true, talent = 58875 }, -- Spirit Walk
        { spell = 60103, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 60103 }, -- Lava Lash
        { spell = 79206, type = "ability", buff = true, talent = 79206 }, -- Spiritwalker's Grace
        { spell = 108271, type = "ability", buff = true, talent = 108271 }, -- Astral Shift
        { spell = 108281, type = "ability", buff = true, talent = 108281 }, -- Ancestral Guidance
        { spell = 108285, type = "ability", talent = 108285 }, -- Totemic Recall
        { spell = 114051, type = "ability", buff = true, talent = 114051 }, -- Ascendance
        { spell = 115356, type = "ability", overlayGlow = true }, -- Windstrike
        { spell = 117014, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 117014 }, -- Elemental Blast
        { spell = 187874, type = "ability", talent = 187874 }, -- Crash Lightning
        { spell = 188196, type = "ability", overlayGlow = true, requiresTarget = true }, -- Lightning Bolt
        { spell = 188389, type = "ability", requiresTarget = true }, -- Flame Shock
        { spell = 188443, type = "ability", overlayGlow = true, requiresTarget = true, talent = 188443 }, -- Chain Lightning
        { spell = 192058, type = "ability", totem = true, talent = 192058 }, -- Capacitor Totem
        { spell = 192077, type = "ability", totem = true, talent = 192077 }, -- Wind Rush Totem
        { spell = 196840, type = "ability", overlayGlow = true, requiresTarget = true, talent = 196840 }, -- Frost Shock
        { spell = 196884, type = "ability", requiresTarget = true, talent = 196884 }, -- Feral Lunge
        { spell = 197214, type = "ability", talent = 197214 }, -- Sundering
        { spell = 198103, type = "ability", requiresTarget = true, totem = true, talent = 198103 }, -- Earth Elemental
        { spell = 204406, type = "ability", talent = 51490 }, -- Thunderstorm
        { spell = 305483, type = "ability", requiresTarget = true, talent = 305483 }, -- Lightning Lasso
        { spell = 333974, type = "ability", talent = 333974 }, -- Fire Nova
        { spell = 342240, type = "ability", requiresTarget = true, talent = 342240 }, -- Ice Strike
        { spell = 375982, type = "ability", requiresTarget = true, talent = 375982 }, -- Primordial Wave
        { spell = 378081, type = "ability", buff = true, talent = 378081 }, -- Nature's Swiftness
        { spell = 383013, type = "ability", totem = true, talent = 383013 }, -- Poison Cleansing Totem
        { spell = 383017, type = "ability", totem = true, talent = 383017 }, -- Stoneskin Totem
        { spell = 383019, type = "ability", talent = 383019 }, -- Tranquil Air Totem
        { spell = 384352, type = "ability", buff = true, requiresTarget = true, talent = 384352 }, -- Doom Winds
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
        { spell = 210918, type = "buff", unit = "player", pvptalent = 4, titleSuffix = L["buff"] }, -- Ethereal Form
        { spell = 204330, type = "ability", totem = true, pvptalent = 13, titleSuffix = L["cooldown"] }, -- Skyfury Totem
        { spell = 204331, type = "ability", totem = true, pvptalent = 12, titleSuffix = L["cooldown"] }, -- Counterstrike Totem
        { spell = 204336, type = "ability", totem = true, pvptalent = 9, titleSuffix = L["cooldown"] }, -- Grounding Totem
        { spell = 210918, type = "ability", buff = true, pvptalent = 4, titleSuffix = L["cooldown"] }, -- Ethereal Form
        { spell = 355580, type = "ability", totem = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Static Field Totem
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 546, type = "buff", unit = "player" }, -- Water Walking
        { spell = 974, type = "buff", unit = "player", talent = 974 }, -- Earth Shield
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 2825, type = "buff", unit = "player" }, -- Bloodlust
        { spell = 6196, type = "buff", unit = "player" }, -- Far Sight
        { spell = 8178, type = "buff", unit = "player" }, -- Grounding Totem Effect
        { spell = 52127, type = "buff", unit = "player", talent = 52127 }, -- Water Shield
        { spell = 53390, type = "buff", unit = "player", talent = 51564 }, -- Tidal Waves
        { spell = 58875, type = "buff", unit = "player", talent = 58875 }, -- Spirit Walk
        { spell = 61295, type = "buff", unit = "player", talent = 61295 }, -- Riptide
        { spell = 73920, type = "buff", unit = "player", talent = 73920 }, -- Healing Rain
        { spell = 77762, type = "buff", unit = "player", talent = 77756 }, -- Lava Surge
        { spell = 79206, type = "buff", unit = "player", talent = 79206 }, -- Spiritwalker's Grace
        { spell = 108271, type = "buff", unit = "player", talent = 108271 }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 108281 }, -- Ancestral Guidance
        { spell = 114052, type = "buff", unit = "player", talent = 114052 }, -- Ascendance
        { spell = 157504, type = "buff", unit = "player", talent = 157153 }, -- Cloudburst Totem
        { spell = 192082, type = "buff", unit = "player" }, -- Wind Rush
        { spell = 192106, type = "buff", unit = "player" }, -- Lightning Shield
        { spell = 201633, type = "buff", unit = "player" }, -- Earthen Wall
        { spell = 204262, type = "buff", unit = "player" }, -- Spectral Recovery
        { spell = 207400, type = "buff", unit = "player", talent = 207401 }, -- Ancestral Vigor
        { spell = 208963, type = "buff", unit = "player" }, -- Skyfury Totem
        { spell = 216251, type = "buff", unit = "player", talent = 200071 }, -- Undulation
        { spell = 236502, type = "buff", unit = "player" }, -- Tidebringer
        { spell = 260734, type = "buff", unit = "player", talent = 16166 }, -- Master of the Elements
        { spell = 260881, type = "buff", unit = "player", talent = 260878 }, -- Spirit Wolf
        { spell = 280615, type = "buff", unit = "player", talent = 280614 }, -- Flash Flood
        { spell = 288675, type = "buff", unit = "player", talent = 157154 }, -- High Tide
        { spell = 320763, type = "buff", unit = "player", talent = 16191 }, -- Mana Tide Totem
        { spell = 325174, type = "buff", unit = "player", talent = 98008 }, -- Spirit Link Totem
        { spell = 344179, type = "buff", unit = "player", talent = 187880 }, -- Maelstrom Weapon
        { spell = 375986, type = "buff", unit = "player", talent = 375982 }, -- Primordial Wave
        { spell = 378081, type = "buff", unit = "player", talent = 378081 }, -- Nature's Swiftness
        { spell = 378102, type = "buff", unit = "player", talent = 378094 }, -- Swirling Currents
        { spell = 381668, type = "buff", unit = "player", talent = 381666 }, -- Focused Insight
        { spell = 381755, type = "buff", unit = "player", talent = 198103 }, -- Earth Elemental
        { spell = 382024, type = "buff", unit = "player", talent = 382021 }, -- Earthliving Weapon
        { spell = 382029, type = "buff", unit = "player", talent = 382029 }, -- Ever-Rising Tide
        { spell = 382217, type = "buff", unit = "player", talent = 382215 }, -- Winds of Al'Akir
        { spell = 382889, type = "buff", unit = "player", talent = 382888 }, -- Flurry
        { spell = 383009, type = "buff", unit = "player", talent = 383009 }, -- Stormkeeper
        { spell = 383018, type = "buff", unit = "player" }, -- Stoneskin
        { spell = 383020, type = "buff", unit = "player" }, -- Tranquil Air
        { spell = 383235, type = "buff", unit = "player", talent = 382194 }, -- Undercurrent
        { spell = 395197, type = "buff", unit = "player", talent = 381930 }, -- Mana Spring Totem
      },
      icon = 252995
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3600, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 51490, type = "debuff", unit = "target", talent = 51490 }, -- Thunderstorm
        { spell = 118905, type = "debuff", unit = "target", talent = 265046 }, -- Static Charge
        { spell = 188389, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 196840, type = "debuff", unit = "target", talent = 196840 }, -- Frost Shock
        { spell = 356824, type = "debuff", unit = "target" }, -- Water Unleashed
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 370, type = "ability", requiresTarget = true, talent = 370 }, -- Purge
        { spell = 556, type = "ability", usable = true }, -- Astral Recall
        { spell = 2484, type = "ability", totem = true }, -- Earthbind Totem
        { spell = 2825, type = "ability", buff = true }, -- Bloodlust
        { spell = 5394, type = "ability", charges = true, totem = true, talent = 5394 }, -- Healing Stream Totem
        { spell = 8143, type = "ability", totem = true, talent = 8143 }, -- Tremor Totem
        { spell = 16191, type = "ability", totem = true, talent = 16191 }, -- Mana Tide Totem
        { spell = 51490, type = "ability", talent = 51490 }, -- Thunderstorm
        { spell = 51505, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 51505 }, -- Lava Burst
        { spell = 51514, type = "ability", talent = 51514 }, -- Hex
        { spell = 57994, type = "ability", requiresTarget = true, talent = 57994 }, -- Wind Shear
        { spell = 58875, type = "ability", buff = true, talent = 58875 }, -- Spirit Walk
        { spell = 61295, type = "ability", charges = true, buff = true, talent = 61295 }, -- Riptide
        { spell = 73899, type = "ability", requiresTarget = true }, -- Primal Strike
        { spell = 73920, type = "ability", buff = true, talent = 73920 }, -- Healing Rain
        { spell = 79206, type = "ability", buff = true, talent = 79206 }, -- Spiritwalker's Grace
        { spell = 98008, type = "ability", totem = true, talent = 98008 }, -- Spirit Link Totem
        { spell = 108271, type = "ability", buff = true, talent = 108271 }, -- Astral Shift
        { spell = 108280, type = "ability", totem = true, talent = 108280 }, -- Healing Tide Totem
        { spell = 108281, type = "ability", buff = true, talent = 108281 }, -- Ancestral Guidance
        { spell = 108285, type = "ability", talent = 108285 }, -- Totemic Recall
        { spell = 108287, type = "ability", talent = 108287 }, -- Totemic Projection
        { spell = 114052, type = "ability", buff = true, talent = 114052 }, -- Ascendance
        { spell = 157153, type = "ability", totem = true, talent = 157153 }, -- Cloudburst Totem
        { spell = 188196, type = "ability", overlayGlow = true, requiresTarget = true }, -- Lightning Bolt
        { spell = 188389, type = "ability", requiresTarget = true }, -- Flame Shock
        { spell = 188443, type = "ability", overlayGlow = true, requiresTarget = true, talent = 188443 }, -- Chain Lightning
        { spell = 192058, type = "ability", totem = true, talent = 192058 }, -- Capacitor Totem
        { spell = 192063, type = "ability", talent = 192063 }, -- Gust of Wind
        { spell = 192077, type = "ability", totem = true, talent = 192077 }, -- Wind Rush Totem
        { spell = 196840, type = "ability", requiresTarget = true, talent = 196840 }, -- Frost Shock
        { spell = 197995, type = "ability", talent = 197995 }, -- Wellspring
        { spell = 198103, type = "ability", requiresTarget = true, totem = true, talent = 198103 }, -- Earth Elemental
        { spell = 198838, type = "ability", totem = true, talent = 198838 }, -- Earthen Wall Totem
        { spell = 201764, type = "ability" }, -- Recall Cloudburst Totem
        { spell = 207399, type = "ability", talent = 207399 }, -- Ancestral Protection Totem
        { spell = 207778, type = "ability", talent = 207778 }, -- Downpour
        { spell = 305483, type = "ability", requiresTarget = true, talent = 305483 }, -- Lightning Lasso
        { spell = 375982, type = "ability", overlayGlow = true, requiresTarget = true, talent = 375982 }, -- Primordial Wave
        { spell = 378081, type = "ability", buff = true, usable = true, talent = 378081 }, -- Nature's Swiftness
        { spell = 382029, type = "ability", buff = true, talent = 382029 }, -- Ever-Rising Tide
        { spell = 383009, type = "ability", buff = true, talent = 383009 }, -- Stormkeeper
        { spell = 383013, type = "ability", totem = true, talent = 383013 }, -- Poison Cleansing Totem
        { spell = 383017, type = "ability", totem = true, talent = 383017 }, -- Stoneskin Totem
        { spell = 383019, type = "ability", totem = true, talent = 383019 }, -- Tranquil Air Totem
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
        { spell = 204330, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"] }, -- Skyfury Totem
        { spell = 204331, type = "ability", pvptalent = 10, titleSuffix = L["cooldown"] }, -- Counterstrike Totem
        { spell = 204336, type = "ability", totem = true, pvptalent = 1, titleSuffix = L["cooldown"] }, -- Grounding Totem
        { spell = 356736, type = "ability", pvptalent = 4, titleSuffix = L["cooldown"] }, -- Unleash Shield
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 66, type = "buff", unit = "player", talent = 66 }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player" }, -- Arcane Intellect
        { spell = 12051, type = "buff", unit = "player", talent = 12051 }, -- Evocation
        { spell = 45438, type = "buff", unit = "player", talent = 45438 }, -- Ice Block
        { spell = 80353, type = "buff", unit = "player" }, -- Time Warp
        { spell = 108839, type = "buff", unit = "player", talent = 108839 }, -- Ice Floes
        { spell = 110960, type = "buff", unit = "player", talent = 110959 }, -- Greater Invisibility
        { spell = 116014, type = "buff", unit = "player", talent = 116011 }, -- Rune of Power
        { spell = 116267, type = "buff", unit = "player", talent = 1463 }, -- Incanter's Flow
        { spell = 205025, type = "buff", unit = "player", talent = 205025 }, -- Presence of Mind
        { spell = 210126, type = "buff", unit = "player", talent = 205022 }, -- Arcane Familiar
        { spell = 235450, type = "buff", unit = "player", talent = 235450 }, -- Prismatic Barrier
        { spell = 236298, type = "buff", unit = "player", talent = 235711 }, -- Chrono Shift
        { spell = 263725, type = "buff", unit = "player", talent = 79684 }, -- Clearcasting
        { spell = 264774, type = "buff", unit = "player", talent = 264354 }, -- Rule of Threes
        { spell = 321388, type = "buff", unit = "player", talent = 321387 }, -- Enlightened
        { spell = 342246, type = "buff", unit = "player", talent = 342245 }, -- Alter Time
        { spell = 365362, type = "buff", unit = "player", talent = 365350 }, -- Arcane Surge
        { spell = 382290, type = "buff", unit = "player", talent = 382289 }, -- Tempest Barrier
        { spell = 382440, type = "buff", unit = "player", talent = 382440 }, -- Shifting Power
        { spell = 382824, type = "buff", unit = "player", talent = 382826 }, -- Temporal Velocity
        { spell = 383783, type = "buff", unit = "player", talent = 383782 }, -- Nether Precision
        { spell = 383997, type = "buff", unit = "player", talent = 383980 }, -- Arcane Tempo
        { spell = 384267, type = "buff", unit = "player", talent = 384187 }, -- Siphon Storm
        { spell = 384455, type = "buff", unit = "player", talent = 384452 }, -- Arcane Harmony
        { spell = 384859, type = "buff", unit = "player", talent = 384858 }, -- Orb Barrage
        { spell = 384865, type = "buff", unit = "player", talent = 384861 }, -- Foresight
        { spell = 389714, type = "buff", unit = "player" }, -- Displacement Beacon
        { spell = 393939, type = "buff", unit = "player", talent = 383676 }, -- Impetus
        { spell = 394195, type = "buff", unit = "player", talent = 390218 }, -- Overflowing Energy
      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 31589, type = "debuff", unit = "target", talent = 31589 }, -- Slow
        { spell = 31661, type = "debuff", unit = "target", talent = 31661 }, -- Dragon's Breath
        { spell = 59638, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 114923, type = "debuff", unit = "target", talent = 114923 }, -- Nether Tempest
        { spell = 155158, type = "debuff", unit = "target" }, -- Meteor Burn
        { spell = 157981, type = "debuff", unit = "target", talent = 157981 }, -- Blast Wave
        { spell = 157997, type = "debuff", unit = "target", talent = 157997 }, -- Ice Nova
        { spell = 205708, type = "debuff", unit = "target" }, -- Chilled
        { spell = 210824, type = "debuff", unit = "target", talent = 321507 }, -- Touch of the Magi
        { spell = 212792, type = "debuff", unit = "target" }, -- Cone of Cold
        { spell = 236299, type = "debuff", unit = "target", talent = 235711 }, -- Chrono Shift
        { spell = 376103, type = "debuff", unit = "target", talent = 376103 }, -- Radiant Spark
        { spell = 376104, type = "debuff", unit = "target" }, -- Radiant Spark Vulnerability
        { spell = 386770, type = "debuff", unit = "target", talent = 386763 }, -- Freezing Cold
      },
      icon = 135848
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability", buff = true, talent = 66 }, -- Invisibility
        { spell = 116, type = "ability", requiresTarget = true }, -- Frostbolt
        { spell = 120, type = "ability" }, -- Cone of Cold
        { spell = 122, type = "ability", charges = true }, -- Frost Nova
        { spell = 475, type = "ability", talent = 475 }, -- Remove Curse
        { spell = 1953, type = "ability" }, -- Blink
        { spell = 2139, type = "ability", requiresTarget = true }, -- Counterspell
        { spell = 5143, type = "ability", overlayGlow = true, requiresTarget = true, talent = 5143 }, -- Arcane Missiles
        { spell = 12051, type = "ability", buff = true, talent = 12051 }, -- Evocation
        { spell = 30449, type = "ability", requiresTarget = true, talent = 30449 }, -- Spellsteal
        { spell = 30451, type = "ability", requiresTarget = true }, -- Arcane Blast
        { spell = 31589, type = "ability", requiresTarget = true, talent = 31589 }, -- Slow
        { spell = 31661, type = "ability", talent = 31661 }, -- Dragon's Breath
        { spell = 44425, type = "ability", requiresTarget = true, talent = 44425 }, -- Arcane Barrage
        { spell = 45438, type = "ability", buff = true, usable = true, talent = 45438 }, -- Ice Block
        { spell = 55342, type = "ability", talent = 55342 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true }, -- Time Warp
        { spell = 108839, type = "ability", charges = true, buff = true, talent = 108839 }, -- Ice Floes
        { spell = 108853, type = "ability", requiresTarget = true, talent = 108853 }, -- Fire Blast
        { spell = 110959, type = "ability", talent = 110959 }, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 113724 }, -- Ring of Frost
        { spell = 114923, type = "ability", requiresTarget = true, talent = 114923 }, -- Nether Tempest
        { spell = 116011, type = "ability", totem = true, talent = 116011 }, -- Rune of Power
        { spell = 153561, type = "ability", talent = 153561 }, -- Meteor
        { spell = 153626, type = "ability", charges = true, talent = 153626 }, -- Arcane Orb
        { spell = 157980, type = "ability", requiresTarget = true, talent = 157980 }, -- Supernova
        { spell = 157981, type = "ability", talent = 157981 }, -- Blast Wave
        { spell = 157997, type = "ability", requiresTarget = true, talent = 157997 }, -- Ice Nova
        { spell = 190336, type = "ability" }, -- Conjure Refreshment
        { spell = 205022, type = "ability", talent = 205022 }, -- Arcane Familiar
        { spell = 205025, type = "ability", buff = true, usable = true, talent = 205025 }, -- Presence of Mind
        { spell = 212653, type = "ability", charges = true, talent = 212653 }, -- Shimmer
        { spell = 235450, type = "ability", buff = true, talent = 235450 }, -- Prismatic Barrier
        { spell = 319836, type = "ability", charges = true, requiresTarget = true, talent = 108853 }, -- Fire Blast
        { spell = 321507, type = "ability", requiresTarget = true, talent = 321507 }, -- Touch of the Magi
        { spell = 342245, type = "ability", talent = 342245 }, -- Alter Time
        { spell = 365350, type = "ability", requiresTarget = true, talent = 365350 }, -- Arcane Surge
        { spell = 376103, type = "ability", requiresTarget = true, talent = 376103 }, -- Radiant Spark
        { spell = 382440, type = "ability", buff = true, talent = 382440 }, -- Shifting Power
        { spell = 383121, type = "ability", talent = 383121 }, -- Mass Polymorph
        { spell = 389713, type = "ability", talent = 389713 }, -- Displacement
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
        { spell = 198111, type = "buff", unit = "player", pvptalent = 4, titleSuffix = L["buff"] }, -- Temporal Shield
        { spell = 198158, type = "buff", unit = "player", pvptalent = 9, titleSuffix = L["buff"] }, -- Mass Invisibility
        { spell = 198111, type = "ability", buff = true, pvptalent = 4, titleSuffix = L["cooldown"] }, -- Temporal Shield
        { spell = 198158, type = "ability", buff = true, pvptalent = 9, titleSuffix = L["cooldown"] }, -- Mass Invisibility
        { spell = 352278, type = "ability", pvptalent = 3, titleSuffix = L["cooldown"] }, -- Ice Wall
        { spell = 353082, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"] }, -- Ring of Fire
        { spell = 353128, type = "ability", pvptalent = 7, titleSuffix = L["cooldown"] }, -- Arcanosphere
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 66, type = "buff", unit = "player", talent = 66 }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player" }, -- Arcane Intellect
        { spell = 45438, type = "buff", unit = "player", talent = 45438 }, -- Ice Block
        { spell = 48107, type = "buff", unit = "player" }, -- Heating Up
        { spell = 48108, type = "buff", unit = "player" }, -- Hot Streak!
        { spell = 80353, type = "buff", unit = "player" }, -- Time Warp
        { spell = 108839, type = "buff", unit = "player", talent = 108839 }, -- Ice Floes
        { spell = 110960, type = "buff", unit = "player", talent = 110959 }, -- Greater Invisibility
        { spell = 116014, type = "buff", unit = "player", talent = 116011 }, -- Rune of Power
        { spell = 116267, type = "buff", unit = "player", talent = 1463 }, -- Incanter's Flow
        { spell = 190319, type = "buff", unit = "player", talent = 190319 }, -- Combustion
        { spell = 203277, type = "buff", unit = "player", talent = 203275 }, -- Flame Accelerant
        { spell = 203285, type = "buff", unit = "player" }, -- Flamecannon
        { spell = 235313, type = "buff", unit = "player", talent = 235313 }, -- Blazing Barrier
        { spell = 236060, type = "buff", unit = "player" }, -- Frenetic Speed
        { spell = 269651, type = "buff", unit = "player", talent = 269650 }, -- Pyroclasm
        { spell = 342246, type = "buff", unit = "player", talent = 342245 }, -- Alter Time
        { spell = 382290, type = "buff", unit = "player", talent = 382289 }, -- Tempest Barrier
        { spell = 382440, type = "buff", unit = "player", talent = 382440 }, -- Shifting Power
        { spell = 382824, type = "buff", unit = "player", talent = 382826 }, -- Temporal Velocity
        { spell = 383395, type = "buff", unit = "player", talent = 383391 }, -- Feel the Burn
        { spell = 383492, type = "buff", unit = "player", talent = 383489 }, -- Wildfire
        { spell = 383501, type = "buff", unit = "player", talent = 383499 }, -- Firemind
        { spell = 383637, type = "buff", unit = "player", talent = 383634 }, -- Fiery Rush
        { spell = 383811, type = "buff", unit = "player", talent = 383810 }, -- Fevered Incantation
        { spell = 383882, type = "buff", unit = "player", talent = 383886 }, -- Sun King's Blessing
        { spell = 384455, type = "buff", unit = "player", talent = 384452 }, -- Arcane Harmony
        { spell = 389714, type = "buff", unit = "player" }, -- Displacement Beacon
        { spell = 394195, type = "buff", unit = "player", talent = 390218 }, -- Overflowing Energy
      },
      icon = 1035045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 2120, type = "debuff", unit = "target", talent = 2120 }, -- Flamestrike
        { spell = 12654, type = "debuff", unit = "target" }, -- Ignite
        { spell = 31589, type = "debuff", unit = "target", talent = 31589 }, -- Slow
        { spell = 59638, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 155158, type = "debuff", unit = "target" }, -- Meteor Burn
        { spell = 157981, type = "debuff", unit = "target", talent = 157981 }, -- Blast Wave
        { spell = 157997, type = "debuff", unit = "target", talent = 157997 }, -- Ice Nova
        { spell = 205708, type = "debuff", unit = "target" }, -- Chilled
        { spell = 217694, type = "debuff", unit = "target", talent = 44457 }, -- Living Bomb
        { spell = 226757, type = "debuff", unit = "target", talent = 205023 }, -- Conflagration
        { spell = 386770, type = "debuff", unit = "target", talent = 386763 }, -- Freezing Cold
      },
      icon = 135818
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability", buff = true, talent = 66 }, -- Invisibility
        { spell = 116, type = "ability", requiresTarget = true }, -- Frostbolt
        { spell = 120, type = "ability" }, -- Cone of Cold
        { spell = 122, type = "ability", charges = true }, -- Frost Nova
        { spell = 133, type = "ability", requiresTarget = true }, -- Fireball
        { spell = 475, type = "ability", talent = 475 }, -- Remove Curse
        { spell = 1953, type = "ability" }, -- Blink
        { spell = 2139, type = "ability", requiresTarget = true }, -- Counterspell
        { spell = 2948, type = "ability", requiresTarget = true, talent = 2948 }, -- Scorch
        { spell = 11366, type = "ability", overlayGlow = true, requiresTarget = true, talent = 11366 }, -- Pyroblast
        { spell = 30449, type = "ability", requiresTarget = true, talent = 30449 }, -- Spellsteal
        { spell = 31589, type = "ability", requiresTarget = true, talent = 31589 }, -- Slow
        { spell = 31661, type = "ability", talent = 31661 }, -- Dragon's Breath
        { spell = 44457, type = "ability", requiresTarget = true, talent = 44457 }, -- Living Bomb
        { spell = 45438, type = "ability", buff = true, usable = true, talent = 45438 }, -- Ice Block
        { spell = 55342, type = "ability", talent = 55342 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true }, -- Time Warp
        { spell = 108839, type = "ability", charges = true, buff = true, talent = 108839 }, -- Ice Floes
        { spell = 108853, type = "ability", charges = true, requiresTarget = true, talent = 108853 }, -- Fire Blast
        { spell = 110959, type = "ability", talent = 110959 }, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 113724 }, -- Ring of Frost
        { spell = 116011, type = "ability", totem = true, talent = 116011 }, -- Rune of Power
        { spell = 153561, type = "ability", talent = 153561 }, -- Meteor
        { spell = 157981, type = "ability", talent = 157981 }, -- Blast Wave
        { spell = 157997, type = "ability", requiresTarget = true, talent = 157997 }, -- Ice Nova
        { spell = 190319, type = "ability", buff = true, totem = true, talent = 190319 }, -- Combustion
        { spell = 190336, type = "ability" }, -- Conjure Refreshment
        { spell = 212653, type = "ability", charges = true, talent = 212653 }, -- Shimmer
        { spell = 235313, type = "ability", buff = true, talent = 235313 }, -- Blazing Barrier
        { spell = 257541, type = "ability", charges = true, requiresTarget = true, talent = 257541 }, -- Phoenix Flames
        { spell = 342245, type = "ability", talent = 342245 }, -- Alter Time
        { spell = 382440, type = "ability", buff = true, talent = 382440 }, -- Shifting Power
        { spell = 383121, type = "ability", talent = 383121 }, -- Mass Polymorph
        { spell = 389713, type = "ability", talent = 389713 }, -- Displacement
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
        { spell = 203286, type = "ability", pvptalent = 8, titleSuffix = L["cooldown"] }, -- Greater Pyroblast
        { spell = 352278, type = "ability", pvptalent = 4, titleSuffix = L["cooldown"] }, -- Ice Wall
        { spell = 353082, type = "ability", pvptalent = 6, titleSuffix = L["cooldown"] }, -- Ring of Fire
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 66, type = "buff", unit = "player", talent = 66 }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player" }, -- Arcane Intellect
        { spell = 11426, type = "buff", unit = "player", talent = 11426 }, -- Ice Barrier
        { spell = 12472, type = "buff", unit = "player", talent = 12472 }, -- Icy Veins
        { spell = 44544, type = "buff", unit = "player", talent = 112965 }, -- Fingers of Frost
        { spell = 45438, type = "buff", unit = "player", talent = 45438 }, -- Ice Block
        { spell = 80353, type = "buff", unit = "player" }, -- Time Warp
        { spell = 108839, type = "buff", unit = "player", talent = 108839 }, -- Ice Floes
        { spell = 110960, type = "buff", unit = "player", talent = 110959 }, -- Greater Invisibility
        { spell = 116014, type = "buff", unit = "player", talent = 116011 }, -- Rune of Power
        { spell = 116267, type = "buff", unit = "player", talent = 1463 }, -- Incanter's Flow
        { spell = 190446, type = "buff", unit = "player", talent = 190447 }, -- Brain Freeze
        { spell = 199844, type = "buff", unit = "player" }, -- Glacial Spike!
        { spell = 205473, type = "buff", unit = "player" }, -- Icicles
        { spell = 205766, type = "buff", unit = "player", talent = 205027 }, -- Bone Chilling
        { spell = 270232, type = "buff", unit = "player", talent = 270233 }, -- Freezing Rain
        { spell = 278310, type = "buff", unit = "player", talent = 278309 }, -- Chain Reaction
        { spell = 342246, type = "buff", unit = "player", talent = 342245 }, -- Alter Time
        { spell = 381522, type = "buff", unit = "player", talent = 381706 }, -- Snowstorm
        { spell = 382106, type = "buff", unit = "player", talent = 382103 }, -- Freezing Winds
        { spell = 382113, type = "buff", unit = "player", talent = 382110 }, -- Cold Front
        { spell = 382148, type = "buff", unit = "player", talent = 382144 }, -- Slick Ice
        { spell = 382290, type = "buff", unit = "player", talent = 382289 }, -- Tempest Barrier
        { spell = 382440, type = "buff", unit = "player", talent = 382440 }, -- Shifting Power
        { spell = 382824, type = "buff", unit = "player", talent = 382826 }, -- Temporal Velocity
        { spell = 394195, type = "buff", unit = "player", talent = 390218 }, -- Overflowing Energy
        { spell = 394994, type = "buff", unit = "player" }, -- Touch of Ice
      },
      icon = 236227
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 12486, type = "debuff", unit = "target", talent = 190356 }, -- Blizzard
        { spell = 31589, type = "debuff", unit = "target", talent = 31589 }, -- Slow
        { spell = 31661, type = "debuff", unit = "target", talent = 31661 }, -- Dragon's Breath
        { spell = 59638, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 135029, type = "debuff", unit = "target" }, -- Water Jet
        { spell = 155158, type = "debuff", unit = "target" }, -- Meteor Burn
        { spell = 157981, type = "debuff", unit = "target", talent = 157981 }, -- Blast Wave
        { spell = 205021, type = "debuff", unit = "target", talent = 205021 }, -- Ray of Frost
        { spell = 205708, type = "debuff", unit = "target" }, -- Chilled
        { spell = 212792, type = "debuff", unit = "target" }, -- Cone of Cold
        { spell = 228354, type = "debuff", unit = "target", talent = 44614 }, -- Flurry
        { spell = 228358, type = "debuff", unit = "target" }, -- Winter's Chill
        { spell = 228600, type = "debuff", unit = "target", talent = 199786 }, -- Glacial Spike
        { spell = 289308, type = "debuff", unit = "target", talent = 84714 }, -- Frozen Orb
        { spell = 378760, type = "debuff", unit = "target", talent = 378756 }, -- Frostbite
        { spell = 386770, type = "debuff", unit = "target", talent = 386763 }, -- Freezing Cold
        { spell = 389823, type = "debuff", unit = "target" }, -- Snowdrift
        { spell = 390614, type = "debuff", unit = "target" }, -- Frost Bomb
      },
      icon = 236208
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability", buff = true, talent = 66 }, -- Invisibility
        { spell = 116, type = "ability", requiresTarget = true }, -- Frostbolt
        { spell = 120, type = "ability" }, -- Cone of Cold
        { spell = 122, type = "ability", charges = true }, -- Frost Nova
        { spell = 475, type = "ability", talent = 475 }, -- Remove Curse
        { spell = 2139, type = "ability", requiresTarget = true }, -- Counterspell
        { spell = 11426, type = "ability", buff = true, talent = 11426 }, -- Ice Barrier
        { spell = 12472, type = "ability", buff = true, talent = 12472 }, -- Icy Veins
        { spell = 30449, type = "ability", requiresTarget = true, talent = 30449 }, -- Spellsteal
        { spell = 30455, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 30455 }, -- Ice Lance
        { spell = 31589, type = "ability", requiresTarget = true, talent = 31589 }, -- Slow
        { spell = 31661, type = "ability", talent = 31661 }, -- Dragon's Breath
        { spell = 31687, type = "ability", talent = 31687 }, -- Summon Water Elemental
        { spell = 31707, type = "ability" }, -- Waterbolt
        { spell = 44614, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 44614 }, -- Flurry
        { spell = 45438, type = "ability", buff = true, usable = true, talent = 45438 }, -- Ice Block
        { spell = 55342, type = "ability", talent = 55342 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true }, -- Time Warp
        { spell = 84714, type = "ability", talent = 84714 }, -- Frozen Orb
        { spell = 108839, type = "ability", charges = true, buff = true, talent = 108839 }, -- Ice Floes
        { spell = 108853, type = "ability", requiresTarget = true, talent = 108853 }, -- Fire Blast
        { spell = 110959, type = "ability", talent = 110959 }, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 113724 }, -- Ring of Frost
        { spell = 116011, type = "ability", totem = true, talent = 116011 }, -- Rune of Power
        { spell = 135029, type = "ability" }, -- Water Jet
        { spell = 153561, type = "ability", talent = 153561 }, -- Meteor
        { spell = 153595, type = "ability", requiresTarget = true, talent = 153595 }, -- Comet Storm
        { spell = 157981, type = "ability", talent = 157981 }, -- Blast Wave
        { spell = 157997, type = "ability", requiresTarget = true, talent = 157997 }, -- Ice Nova
        { spell = 190336, type = "ability" }, -- Conjure Refreshment
        { spell = 190356, type = "ability", overlayGlow = true, talent = 190356 }, -- Blizzard
        { spell = 199786, type = "ability", overlayGlow = true, requiresTarget = true, talent = 199786 }, -- Glacial Spike
        { spell = 205021, type = "ability", requiresTarget = true, talent = 205021 }, -- Ray of Frost
        { spell = 212653, type = "ability", charges = true, talent = 212653 }, -- Shimmer
        { spell = 235219, type = "ability", talent = 235219 }, -- Cold Snap
        { spell = 257537, type = "ability", requiresTarget = true, talent = 257537 }, -- Ebonbolt
        { spell = 319836, type = "ability", requiresTarget = true, talent = 108853 }, -- Fire Blast
        { spell = 342245, type = "ability", talent = 342245 }, -- Alter Time
        { spell = 382440, type = "ability", buff = true, talent = 382440 }, -- Shifting Power
        { spell = 383121, type = "ability", talent = 383121 }, -- Mass Polymorph
        { spell = 389713, type = "ability", talent = 389713 }, -- Displacement
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
        { spell = 198144, type = "buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"] }, -- Ice Form
        { spell = 389794, type = "buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"] }, -- Snowdrift
        { spell = 390612, type = "debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"] }, -- Frost Bomb
        { spell = 198144, type = "ability", buff = true, pvptalent = 2, titleSuffix = L["cooldown"] }, -- Ice Form
        { spell = 352278, type = "ability", pvptalent = 8, titleSuffix = L["cooldown"] }, -- Ice Wall
        { spell = 353082, type = "ability", pvptalent = 4, titleSuffix = L["cooldown"] }, -- Ring of Fire
        { spell = 389794, type = "ability", buff = true, pvptalent = 7, titleSuffix = L["cooldown"] }, -- Snowdrift
        { spell = 390612, type = "ability", requiresTarget = true, pvptalent = 6, titleSuffix = L["cooldown"] }, -- Frost Bomb
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 126, type = "buff", unit = "player" }, -- Eye of Kilrogg
        { spell = 5697, type = "buff", unit = "player" }, -- Unending Breath
        { spell = 20707, type = "buff", unit = "player" }, -- Soulstone
        { spell = 48018, type = "buff", unit = "player", talent = 268358 }, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player" }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 108416 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 111400 }, -- Burning Rush
        { spell = 171982, type = "buff", unit = "player" }, -- Demonic Synergy
        { spell = 196099, type = "buff", unit = "player", talent = 108503 }, -- Grimoire of Sacrifice
        { spell = 221705, type = "buff", unit = "player" }, -- Casting Circle
        { spell = 264571, type = "buff", unit = "player", talent = 108558 }, -- Nightfall
        { spell = 328774, type = "buff", unit = "player", talent = 328774 }, -- Amplify Curse
        { spell = 333889, type = "buff", unit = "player", talent = 333889 }, -- Fel Domination
        { spell = 334320, type = "buff", unit = "player", talent = 334319 }, -- Inevitable Demise
        { spell = 386256, type = "buff", unit = "player", talent = 386256 }, -- Summon Soulkeeper
        { spell = 387018, type = "buff", unit = "player", talent = 387016 }, -- Dark Harvest
        { spell = 387079, type = "buff", unit = "player", talent = 387075 }, -- Tormented Crescendo
        { spell = 387310, type = "buff", unit = "player", talent = 387301 }, -- Haunted Soul
        { spell = 387626, type = "buff", unit = "player", talent = 385899 }, -- Soulburn
        { spell = 388068, type = "buff", unit = "player", talent = 386344 }, -- Inquisitor's Gaze
        { spell = 389614, type = "buff", unit = "player", talent = 389609 }, -- Abyss Walker
        { spell = 394810, type = "buff", unit = "player" }, -- Soulburn: Drain Life
        { spell = 7870, type = "buff", unit = "pet" }, -- Lesser Invisibility
        { spell = 32752, type = "buff", unit = "pet" }, -- Summoning Disorientation
        { spell = 112042, type = "buff", unit = "pet" }, -- Threatening Presence
      },
      icon = 136210
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 702, type = "debuff", unit = "target" }, -- Curse of Weakness
        { spell = 980, type = "debuff", unit = "target" }, -- Agony
        { spell = 1714, type = "debuff", unit = "target" }, -- Curse of Tongues
        { spell = 5484, type = "debuff", unit = "target", talent = 5484 }, -- Howl of Terror
        { spell = 6360, type = "debuff", unit = "target" }, -- Whiplash
        { spell = 6789, type = "debuff", unit = "target", talent = 6789 }, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target" }, -- Suffering
        { spell = 27243, type = "debuff", unit = "target", talent = 27243 }, -- Seed of Corruption
        { spell = 30283, type = "debuff", unit = "target", talent = 30283 }, -- Shadowfury
        { spell = 32390, type = "debuff", unit = "target", talent = 32388 }, -- Shadow Embrace
        { spell = 48181, type = "debuff", unit = "target", talent = 48181 }, -- Haunt
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
        { spell = 198590, type = "debuff", unit = "target", talent = 198590 }, -- Drain Soul
        { spell = 205179, type = "debuff", unit = "target", talent = 205179 }, -- Phantom Singularity
        { spell = 212580, type = "debuff", unit = "target" }, -- Eye of the Observer
        { spell = 234153, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 316099, type = "debuff", unit = "target", talent = 316099 }, -- Unstable Affliction
        { spell = 334275, type = "debuff", unit = "target" }, -- Curse of Exhaustion
        { spell = 384069, type = "debuff", unit = "target", talent = 384069 }, -- Shadowflame
        { spell = 386931, type = "debuff", unit = "target", talent = 278350 }, -- Vile Taint
        { spell = 386997, type = "debuff", unit = "target", talent = 386997 }, -- Soul Rot
        { spell = 389845, type = "debuff", unit = "target", talent = 389761 }, -- Malefic Affliction
        { spell = 389868, type = "debuff", unit = "target", talent = 389775 }, -- Dread Touch
      },
      icon = 136139
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 172, type = "ability", requiresTarget = true }, -- Corruption
        { spell = 686, type = "ability", overlayGlow = true, requiresTarget = true }, -- Shadow Bolt
        { spell = 698, type = "ability" }, -- Ritual of Summoning
        { spell = 702, type = "ability", requiresTarget = true }, -- Curse of Weakness
        { spell = 980, type = "ability", requiresTarget = true }, -- Agony
        { spell = 1714, type = "ability", requiresTarget = true }, -- Curse of Tongues
        { spell = 3110, type = "ability" }, -- Firebolt
        { spell = 3716, type = "ability" }, -- Consuming Shadows
        { spell = 5484, type = "ability", talent = 5484 }, -- Howl of Terror
        { spell = 5782, type = "ability", requiresTarget = true }, -- Fear
        { spell = 6360, type = "ability" }, -- Whiplash
        { spell = 6789, type = "ability", requiresTarget = true, talent = 6789 }, -- Mortal Coil
        { spell = 7814, type = "ability" }, -- Lash of Pain
        { spell = 7870, type = "ability", buff = true, unit = 'pet', debuff = true }, -- Lesser Invisibility
        { spell = 17735, type = "ability" }, -- Suffering
        { spell = 17767, type = "ability" }, -- Shadow Bulwark
        { spell = 19505, type = "ability" }, -- Devour Magic
        { spell = 19647, type = "ability" }, -- Spell Lock
        { spell = 20707, type = "ability", buff = true }, -- Soulstone
        { spell = 27243, type = "ability", requiresTarget = true, talent = 27243 }, -- Seed of Corruption
        { spell = 29893, type = "ability" }, -- Create Soulwell
        { spell = 30283, type = "ability", talent = 30283 }, -- Shadowfury
        { spell = 48018, type = "ability", buff = true, talent = 268358 }, -- Demonic Circle
        { spell = 48020, type = "ability", usable = true }, -- Demonic Circle: Teleport
        { spell = 48181, type = "ability", requiresTarget = true, talent = 48181 }, -- Haunt
        { spell = 54049, type = "ability" }, -- Shadow Bite
        { spell = 63106, type = "ability", requiresTarget = true, talent = 63106 }, -- Siphon Life
        { spell = 104773, type = "ability", buff = true }, -- Unending Resolve
        { spell = 108416, type = "ability", buff = true, talent = 108416 }, -- Dark Pact
        { spell = 108503, type = "ability", talent = 108503 }, -- Grimoire of Sacrifice
        { spell = 111771, type = "ability", talent = 111771 }, -- Demonic Gateway
        { spell = 112042, type = "ability", buff = true, unit = 'pet' }, -- Threatening Presence
        { spell = 119910, type = "ability" }, -- Spell Lock
        { spell = 205179, type = "ability", requiresTarget = true, talent = 205179 }, -- Phantom Singularity
        { spell = 205180, type = "ability", totem = true, talent = 205180 }, -- Summon Darkglare
        { spell = 234153, type = "ability", requiresTarget = true }, -- Drain Life
        { spell = 264993, type = "ability" }, -- Shadow Shield
        { spell = 278350, type = "ability", talent = 278350 }, -- Vile Taint
        { spell = 316099, type = "ability", requiresTarget = true, talent = 316099 }, -- Unstable Affliction
        { spell = 328774, type = "ability", buff = true, usable = true, talent = 328774 }, -- Amplify Curse
        { spell = 333889, type = "ability", buff = true, talent = 333889 }, -- Fel Domination
        { spell = 334275, type = "ability", requiresTarget = true }, -- Curse of Exhaustion
        { spell = 342601, type = "ability" }, -- Ritual of Doom
        { spell = 384069, type = "ability", talent = 384069 }, -- Shadowflame
        { spell = 385899, type = "ability", talent = 385899 }, -- Soulburn
        { spell = 386256, type = "ability", charges = true, buff = true, usable = true, talent = 386256 }, -- Summon Soulkeeper
        { spell = 386344, type = "ability", talent = 386344 }, -- Inquisitor's Gaze
        { spell = 386951, type = "ability", requiresTarget = true, talent = 386951 }, -- Soul Swap
        { spell = 386997, type = "ability", requiresTarget = true, talent = 386997 }, -- Soul Rot
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
        { spell = 212295, type = "buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"] }, -- Nether Ward
        { spell = 344566, type = "buff", unit = "player", pvptalent = 1, titleSuffix = L["buff"] }, -- Rapid Contagion
        { spell = 234877, type = "debuff", unit = "target", pvptalent = 6, titleSuffix = L["debuff"] }, -- Bane of Shadows
        { spell = 199954, type = "ability", requiresTarget = true, pvptalent = 5, titleSuffix = L["cooldown"] }, -- Bane of Fragility
        { spell = 201996, type = "ability", pvptalent = 8, titleSuffix = L["cooldown"] }, -- Call Observer
        { spell = 212295, type = "ability", buff = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Nether Ward
        { spell = 221703, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"] }, -- Casting Circle
        { spell = 234877, type = "ability", requiresTarget = true, pvptalent = 6, titleSuffix = L["cooldown"] }, -- Bane of Shadows
        { spell = 344566, type = "ability", buff = true, pvptalent = 1, titleSuffix = L["cooldown"] }, -- Rapid Contagion
        { spell = 353294, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"] }, -- Shadow Rift
        { spell = 353753, type = "ability", pvptalent = 10, titleSuffix = L["cooldown"] }, -- Bonds of Fel
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 126, type = "buff", unit = "player" }, -- Eye of Kilrogg
        { spell = 5697, type = "buff", unit = "player" }, -- Unending Breath
        { spell = 20707, type = "buff", unit = "player" }, -- Soulstone
        { spell = 48018, type = "buff", unit = "player", talent = 268358 }, -- Demonic Circle
        { spell = 108366, type = "buff", unit = "player" }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 108416 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 111400 }, -- Burning Rush
        { spell = 171982, type = "buff", unit = "player" }, -- Demonic Synergy
        { spell = 205146, type = "buff", unit = "player", talent = 205145 }, -- Demonic Calling
        { spell = 221705, type = "buff", unit = "player" }, -- Casting Circle
        { spell = 264173, type = "buff", unit = "player" }, -- Demonic Core
        { spell = 265273, type = "buff", unit = "player" }, -- Demonic Power
        { spell = 267218, type = "buff", unit = "player", talent = 267217 }, -- Nether Portal
        { spell = 328774, type = "buff", unit = "player", talent = 328774 }, -- Amplify Curse
        { spell = 333889, type = "buff", unit = "player", talent = 333889 }, -- Fel Domination
        { spell = 353646, type = "buff", unit = "player" }, -- Fel Obelisk
        { spell = 386256, type = "buff", unit = "player", talent = 386256 }, -- Summon Soulkeeper
        { spell = 387327, type = "buff", unit = "player", talent = 387322 }, -- Shadow's Bite
        { spell = 387393, type = "buff", unit = "player", talent = 387391 }, -- Dread Calling
        { spell = 387437, type = "buff", unit = "player", talent = 387432 }, -- Fel Covenant
        { spell = 387603, type = "buff", unit = "player", talent = 387602 }, -- Stolen Power
        { spell = 387626, type = "buff", unit = "player", talent = 385899 }, -- Soulburn
        { spell = 388068, type = "buff", unit = "player", talent = 386344 }, -- Inquisitor's Gaze
        { spell = 389614, type = "buff", unit = "player", talent = 389609 }, -- Abyss Walker
        { spell = 394810, type = "buff", unit = "player" }, -- Soulburn: Drain Life
        { spell = 89751, type = "buff", unit = "target" }, -- Felstorm
        { spell = 108366, type = "buff", unit = "target" }, -- Soul Leech
        { spell = 134477, type = "buff", unit = "target" }, -- Threatening Presence
        { spell = 171982, type = "buff", unit = "target" }, -- Demonic Synergy
        { spell = 7870, type = "buff", unit = "pet" }, -- Lesser Invisibility
        { spell = 30151, type = "buff", unit = "pet" }, -- Pursuit
        { spell = 32752, type = "buff", unit = "pet" }, -- Summoning Disorientation
        { spell = 267171, type = "buff", unit = "pet", talent = 267171 }, -- Demonic Strength
        { spell = 353646, type = "buff", unit = "pet" }, -- Fel Obelisk
        { spell = 386601, type = "buff", unit = "pet" }, -- Fiendish Wrath
        { spell = 386861, type = "buff", unit = "pet", talent = 386858 }, -- Demonic Inspiration
        { spell = 386865, type = "buff", unit = "pet", talent = 386864 }, -- Wrathful Minion
        { spell = 387496, type = "buff", unit = "pet", talent = 387494 }, -- Antoran Armaments
        { spell = 387601, type = "buff", unit = "pet", talent = 387600 }, -- The Expendables
      },
      icon = 1378284
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 603, type = "debuff", unit = "target", talent = 603 }, -- Doom
        { spell = 702, type = "debuff", unit = "target" }, -- Curse of Weakness
        { spell = 1714, type = "debuff", unit = "target" }, -- Curse of Tongues
        { spell = 5484, type = "debuff", unit = "target", talent = 5484 }, -- Howl of Terror
        { spell = 6789, type = "debuff", unit = "target", talent = 6789 }, -- Mortal Coil
        { spell = 30213, type = "debuff", unit = "target" }, -- Legion Strike
        { spell = 30283, type = "debuff", unit = "target", talent = 30283 }, -- Shadowfury
        { spell = 89766, type = "debuff", unit = "target" }, -- Axe Toss
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
        { spell = 212580, type = "debuff", unit = "target" }, -- Eye of the Observer
        { spell = 213688, type = "debuff", unit = "target" }, -- Fel Cleave
        { spell = 234153, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 267997, type = "debuff", unit = "target" }, -- Bile Spit
        { spell = 270569, type = "debuff", unit = "target", talent = 267170 }, -- From the Shadows
        { spell = 386649, type = "debuff", unit = "target", talent = 386648 }, -- Nightmare
        { spell = 387402, type = "debuff", unit = "target", talent = 387399 }, -- Fel Sunder
      },
      icon = 136122
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 172, type = "ability", requiresTarget = true }, -- Corruption
        { spell = 603, type = "ability", requiresTarget = true, talent = 603 }, -- Doom
        { spell = 686, type = "ability", requiresTarget = true }, -- Shadow Bolt
        { spell = 698, type = "ability" }, -- Ritual of Summoning
        { spell = 702, type = "ability", requiresTarget = true }, -- Curse of Weakness
        { spell = 1714, type = "ability", requiresTarget = true }, -- Curse of Tongues
        { spell = 3110, type = "ability" }, -- Firebolt
        { spell = 3716, type = "ability" }, -- Consuming Shadows
        { spell = 5484, type = "ability", talent = 5484 }, -- Howl of Terror
        { spell = 5782, type = "ability", requiresTarget = true }, -- Fear
        { spell = 6789, type = "ability", requiresTarget = true, talent = 6789 }, -- Mortal Coil
        { spell = 7814, type = "ability" }, -- Lash of Pain
        { spell = 7870, type = "ability", buff = true, unit = 'pet' }, -- Lesser Invisibility
        { spell = 17767, type = "ability" }, -- Shadow Bulwark
        { spell = 20707, type = "ability", buff = true }, -- Soulstone
        { spell = 29893, type = "ability" }, -- Create Soulwell
        { spell = 30151, type = "ability", buff = true, unit = 'pet' }, -- Pursuit
        { spell = 30213, type = "ability" }, -- Legion Strike
        { spell = 30283, type = "ability", talent = 30283 }, -- Shadowfury
        { spell = 48018, type = "ability", buff = true, talent = 268358 }, -- Demonic Circle
        { spell = 48020, type = "ability", usable = true }, -- Demonic Circle: Teleport
        { spell = 54049, type = "ability" }, -- Shadow Bite
        { spell = 89751, type = "ability", buff = true, unit = 'pet', debuff = true }, -- Felstorm
        { spell = 89766, type = "ability" }, -- Axe Toss
        { spell = 104316, type = "ability", overlayGlow = true, requiresTarget = true, talent = 104316 }, -- Call Dreadstalkers
        { spell = 105174, type = "ability", requiresTarget = true }, -- Hand of Gul'dan
        { spell = 108416, type = "ability", buff = true, talent = 108416 }, -- Dark Pact
        { spell = 111771, type = "ability", talent = 111771 }, -- Demonic Gateway
        { spell = 111898, type = "ability", requiresTarget = true, totem = true, talent = 111898 }, -- Grimoire: Felguard
        { spell = 112042, type = "ability" }, -- Threatening Presence
        { spell = 119914, type = "ability" }, -- Axe Toss
        { spell = 134477, type = "ability", buff = true, unit = 'pet', debuff = true }, -- Threatening Presence
        { spell = 196277, type = "ability", charges = true, requiresTarget = true, usable = true, talent = 196277 }, -- Implosion
        { spell = 234153, type = "ability", requiresTarget = true }, -- Drain Life
        { spell = 264057, type = "ability", requiresTarget = true, talent = 264057 }, -- Soul Strike
        { spell = 264119, type = "ability", totem = true, talent = 264119 }, -- Summon Vilefiend
        { spell = 264130, type = "ability", talent = 264130 }, -- Power Siphon
        { spell = 264178, type = "ability", overlayGlow = true, requiresTarget = true, talent = 264178 }, -- Demonbolt
        { spell = 264993, type = "ability" }, -- Shadow Shield
        { spell = 265187, type = "ability", charges = true, talent = 265187 }, -- Summon Demonic Tyrant
        { spell = 267171, type = "ability", buff = true, unit = 'pet', talent = 267171 }, -- Demonic Strength
        { spell = 267211, type = "ability", talent = 267211 }, -- Bilescourge Bombers
        { spell = 267217, type = "ability", talent = 267217 }, -- Nether Portal
        { spell = 328774, type = "ability", buff = true, usable = true, talent = 328774 }, -- Amplify Curse
        { spell = 333889, type = "ability", buff = true, talent = 333889 }, -- Fel Domination
        { spell = 334275, type = "ability", requiresTarget = true }, -- Curse of Exhaustion
        { spell = 342601, type = "ability" }, -- Ritual of Doom
        { spell = 385899, type = "ability", talent = 385899 }, -- Soulburn
        { spell = 386256, type = "ability", charges = true, buff = true, usable = true, talent = 386256 }, -- Summon Soulkeeper
        { spell = 386344, type = "ability", talent = 386344 }, -- Inquisitor's Gaze
        { spell = 386833, type = "ability", talent = 386833 }, -- Guillotine
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
        { spell = 212295, type = "buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"] }, -- Nether Ward
        { spell = 199954, type = "ability", pvptalent = 6, titleSuffix = L["cooldown"] }, -- Bane of Fragility
        { spell = 201996, type = "ability", pvptalent = 7, titleSuffix = L["cooldown"] }, -- Call Observer
        { spell = 212295, type = "ability", buff = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Nether Ward
        { spell = 212459, type = "ability", totem = true, pvptalent = 1, titleSuffix = L["cooldown"] }, -- Call Fel Lord
        { spell = 212619, type = "ability", requiresTarget = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Call Felhunter
        { spell = 221703, type = "ability", pvptalent = 10, titleSuffix = L["cooldown"] }, -- Casting Circle
        { spell = 353294, type = "ability", pvptalent = 12, titleSuffix = L["cooldown"] }, -- Shadow Rift
        { spell = 353601, type = "ability", totem = true, pvptalent = 13, titleSuffix = L["cooldown"] }, -- Fel Obelisk
        { spell = 353753, type = "ability", pvptalent = 10, titleSuffix = L["cooldown"] }, -- Bonds of Fel
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 126, type = "buff", unit = "player" }, -- Eye of Kilrogg
        { spell = 5697, type = "buff", unit = "player" }, -- Unending Breath
        { spell = 20707, type = "buff", unit = "player" }, -- Soulstone
        { spell = 48018, type = "buff", unit = "player", talent = 268358 }, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player" }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 108416 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 111400 }, -- Burning Rush
        { spell = 117828, type = "buff", unit = "player", talent = 196406 }, -- Backdraft
        { spell = 171982, type = "buff", unit = "player" }, -- Demonic Synergy
        { spell = 196099, type = "buff", unit = "player", talent = 108503 }, -- Grimoire of Sacrifice
        { spell = 221705, type = "buff", unit = "player" }, -- Casting Circle
        { spell = 266030, type = "buff", unit = "player", talent = 205148 }, -- Reverse Entropy
        { spell = 266087, type = "buff", unit = "player", talent = 266086 }, -- Rain of Chaos
        { spell = 328774, type = "buff", unit = "player", talent = 328774 }, -- Amplify Curse
        { spell = 387109, type = "buff", unit = "player", talent = 387108 }, -- Conflagration of Chaos
        { spell = 387154, type = "buff", unit = "player", talent = 387153 }, -- Burn to Ashes
        { spell = 387157, type = "buff", unit = "player", talent = 387156 }, -- Ritual of Ruin
        { spell = 387158, type = "buff", unit = "player" }, -- Impending Ruin
        { spell = 387161, type = "buff", unit = "player" }, -- Blasphemy
        { spell = 387263, type = "buff", unit = "player", talent = 387259 }, -- Flashpoint
        { spell = 387283, type = "buff", unit = "player", talent = 387279 }, -- Power Overwhelming
        { spell = 387356, type = "buff", unit = "player", talent = 387355 }, -- Crashing Chaos
        { spell = 387409, type = "buff", unit = "player", talent = 387400 }, -- Madness of the Azj'Aqir
        { spell = 387570, type = "buff", unit = "player", talent = 387569 }, -- Rolling Havoc
        { spell = 387626, type = "buff", unit = "player", talent = 385899 }, -- Soulburn
        { spell = 388068, type = "buff", unit = "player", talent = 386344 }, -- Inquisitor's Gaze
        { spell = 389614, type = "buff", unit = "player", talent = 389609 }, -- Abyss Walker
        { spell = 394087, type = "buff", unit = "player", talent = 387506 }, -- Mayhem
        { spell = 7870, type = "buff", unit = "pet" }, -- Lesser Invisibility
        { spell = 32752, type = "buff", unit = "pet" }, -- Summoning Disorientation
        { spell = 134477, type = "buff", unit = "pet" }, -- Threatening Presence
        { spell = 386861, type = "buff", unit = "pet", talent = 386858 }, -- Demonic Inspiration
        { spell = 386865, type = "buff", unit = "pet", talent = 386864 }, -- Wrathful Minion
        { spell = 387496, type = "buff", unit = "pet", talent = 387494 }, -- Antoran Armaments
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 702, type = "debuff", unit = "target" }, -- Curse of Weakness
        { spell = 1714, type = "debuff", unit = "target" }, -- Curse of Tongues
        { spell = 5484, type = "debuff", unit = "target", talent = 5484 }, -- Howl of Terror
        { spell = 6360, type = "debuff", unit = "target" }, -- Whiplash
        { spell = 17877, type = "debuff", unit = "target", talent = 17877 }, -- Shadowburn
        { spell = 22703, type = "debuff", unit = "target" }, -- Infernal Awakening
        { spell = 30283, type = "debuff", unit = "target", talent = 30283 }, -- Shadowfury
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
        { spell = 157736, type = "debuff", unit = "target" }, -- Immolate
        { spell = 196414, type = "debuff", unit = "target", talent = 196412 }, -- Eradication
        { spell = 200548, type = "debuff", unit = "target" }, -- Bane of Havoc
        { spell = 234153, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 265931, type = "debuff", unit = "target", talent = 17962 }, -- Conflagrate
        { spell = 334275, type = "debuff", unit = "target" }, -- Curse of Exhaustion
        { spell = 386649, type = "debuff", unit = "target", talent = 386648 }, -- Nightmare
        { spell = 387096, type = "debuff", unit = "target", talent = 387095 }, -- Pyrogenics
        { spell = 387476, type = "debuff", unit = "target", talent = 387475 }, -- Infernal Brand
      },
      icon = 135817
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 348, type = "ability", requiresTarget = true }, -- Immolate
        { spell = 698, type = "ability", usable = true }, -- Ritual of Summoning
        { spell = 702, type = "ability", requiresTarget = true }, -- Curse of Weakness
        { spell = 1122, type = "ability", talent = 1122 }, -- Summon Infernal
        { spell = 1714, type = "ability", requiresTarget = true }, -- Curse of Tongues
        { spell = 3110, type = "ability" }, -- Firebolt
        { spell = 5484, type = "ability", talent = 5484 }, -- Howl of Terror
        { spell = 5782, type = "ability", requiresTarget = true }, -- Fear
        { spell = 6353, type = "ability", requiresTarget = true, talent = 6353 }, -- Soul Fire
        { spell = 6360, type = "ability" }, -- Whiplash
        { spell = 7814, type = "ability" }, -- Lash of Pain
        { spell = 7870, type = "ability", buff = true, unit = 'pet' }, -- Lesser Invisibility
        { spell = 17877, type = "ability", charges = true, requiresTarget = true, talent = 17877 }, -- Shadowburn
        { spell = 17962, type = "ability", charges = true, requiresTarget = true, talent = 17962 }, -- Conflagrate
        { spell = 19647, type = "ability" }, -- Spell Lock
        { spell = 20707, type = "ability", buff = true }, -- Soulstone
        { spell = 29722, type = "ability", requiresTarget = true }, -- Incinerate
        { spell = 29893, type = "ability" }, -- Create Soulwell
        { spell = 30283, type = "ability", talent = 30283 }, -- Shadowfury
        { spell = 48018, type = "ability", buff = true, talent = 268358 }, -- Demonic Circle
        { spell = 48020, type = "ability", usable = true }, -- Demonic Circle: Teleport
        { spell = 54049, type = "ability" }, -- Shadow Bite
        { spell = 69041, type = "ability" }, -- Rocket Barrage
        { spell = 69046, type = "ability" }, -- Pack Hobgoblin
        { spell = 69070, type = "ability" }, -- Rocket Jump
        { spell = 104773, type = "ability", buff = true }, -- Unending Resolve
        { spell = 108416, type = "ability", buff = true, talent = 108416 }, -- Dark Pact
        { spell = 108503, type = "ability", talent = 108503 }, -- Grimoire of Sacrifice
        { spell = 111771, type = "ability", talent = 111771 }, -- Demonic Gateway
        { spell = 116858, type = "ability", overlayGlow = true, requiresTarget = true, talent = 116858 }, -- Chaos Bolt
        { spell = 119910, type = "ability" }, -- Spell Lock
        { spell = 152108, type = "ability", talent = 152108 }, -- Cataclysm
        { spell = 196447, type = "ability", usable = true, talent = 196447 }, -- Channel Demonfire
        { spell = 234153, type = "ability", requiresTarget = true }, -- Drain Life
        { spell = 328774, type = "ability", buff = true, usable = true, talent = 328774 }, -- Amplify Curse
        { spell = 334275, type = "ability", requiresTarget = true }, -- Curse of Exhaustion
        { spell = 342601, type = "ability", usable = true }, -- Ritual of Doom
        { spell = 385899, type = "ability", talent = 385899 }, -- Soulburn
        { spell = 386256, type = "ability", charges = true, talent = 386256 }, -- Summon Soulkeeper
        { spell = 386344, type = "ability", talent = 386344 }, -- Inquisitor's Gaze
        { spell = 387976, type = "ability", charges = true, requiresTarget = true, talent = 387976 }, -- Dimensional Rift
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
        { spell = 212295, type = "buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"] }, -- Nether Ward
        { spell = 199954, type = "ability", requiresTarget = true, pvptalent = 1, titleSuffix = L["cooldown"] }, -- Bane of Fragility
        { spell = 212295, type = "ability", buff = true, pvptalent = 2, titleSuffix = L["cooldown"] }, -- Nether Ward
        { spell = 221703, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"] }, -- Casting Circle
        { spell = 353294, type = "ability", pvptalent = 9, titleSuffix = L["cooldown"] }, -- Shadow Rift
        { spell = 353753, type = "ability", pvptalent = 4, titleSuffix = L["cooldown"] }, -- Bonds of Fel
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 101643, type = "buff", unit = "player", talent = 101643 }, -- Transcendence
        { spell = 116841, type = "buff", unit = "player", talent = 116841 }, -- Tiger's Lust
        { spell = 116847, type = "buff", unit = "player", talent = 116847 }, -- Rushing Jade Wind
        { spell = 120954, type = "buff", unit = "player", talent = 115203 }, -- Fortifying Brew
        { spell = 122278, type = "buff", unit = "player", talent = 122278 }, -- Dampen Harm
        { spell = 122783, type = "buff", unit = "player", talent = 122783 }, -- Diffuse Magic
        { spell = 125883, type = "buff", unit = "player" }, -- Zen Flight
        { spell = 132578, type = "buff", unit = "player", talent = 132578 }, -- Invoke Niuzao, the Black Ox
        { spell = 166646, type = "buff", unit = "player", talent = 157411 }, -- Windwalking
        { spell = 195630, type = "buff", unit = "player" }, -- Elusive Brawler
        { spell = 196608, type = "buff", unit = "player", talent = 196607 }, -- Eye of the Tiger
        { spell = 215479, type = "buff", unit = "player", talent = 322120 }, -- Shuffle
        { spell = 228563, type = "buff", unit = "player", talent = 196736 }, -- Blackout Combo
        { spell = 325092, type = "buff", unit = "player", talent = 322510 }, -- Purified Chi
        { spell = 322507, type = "buff", unit = "player", talent = 322507 }, -- Celestial Brew
        { spell = 325153, type = "buff", unit = "player", talent = 325153 }, -- Exploding Keg
        { spell = 325190, type = "buff", unit = "player", talent = 325177 }, -- Celestial Flames
        { spell = 383696, type = "buff", unit = "player", talent = 383695 }, -- Hit Scheme
        { spell = 386276, type = "buff", unit = "player", talent = 386276 }, -- Bonedust Brew
        { spell = 386963, type = "buff", unit = "player", talent = 386965 }, -- Charred Passions
        { spell = 387184, type = "buff", unit = "player", talent = 387184 }, -- Weapons of Order
        { spell = 389684, type = "buff", unit = "player", talent = 389574 }, -- Close to Heart
        { spell = 389685, type = "buff", unit = "player", talent = 389575 }, -- Generous Pour
        { spell = 392883, type = "buff", unit = "player", talent = 388812 }, -- Vivacious Vivification
        { spell = 393515, type = "buff", unit = "player", talent = 393516 }, -- Pretense of Instability
        { spell = 394112, type = "buff", unit = "player", talent = 394110 }, -- Escape from Reality
      },
      icon = 613398
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target" }, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "target", talent = 115078 }, -- Paralysis
        { spell = 116095, type = "debuff", unit = "target", talent = 116095 }, -- Disable
        { spell = 116189, type = "debuff", unit = "target", talent = 328670 }, -- Provoke
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target" }, -- Leg Sweep
        { spell = 121253, type = "debuff", unit = "target", talent = 121253 }, -- Keg Smash
        { spell = 123725, type = "debuff", unit = "target", talent = 115181 }, -- Breath of Fire
        { spell = 196608, type = "debuff", unit = "target", talent = 196607 }, -- Eye of the Tiger
        { spell = 202346, type = "debuff", unit = "target" }, -- Double Barrel
        { spell = 312106, type = "debuff", unit = "target", talent = 387184 }, -- Weapons of Order
        { spell = 324382, type = "debuff", unit = "target", talent = 324312 }, -- Clash
        { spell = 325153, type = "debuff", unit = "target", talent = 325153 }, -- Exploding Keg
        { spell = 386276, type = "debuff", unit = "target", talent = 386276 }, -- Bonedust Brew
      },
      icon = 611419
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100780, type = "ability", requiresTarget = true }, -- Tiger Palm
        { spell = 100784, type = "ability", requiresTarget = true }, -- Blackout Kick
        { spell = 101643, type = "ability", buff = true, talent = 101643 }, -- Transcendence
        { spell = 107428, type = "ability", requiresTarget = true, talent = 107428 }, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true, talent = 109132 }, -- Roll
        { spell = 115078, type = "ability", requiresTarget = true, talent = 115078 }, -- Paralysis
        { spell = 115098, type = "ability", requiresTarget = true, talent = 115098 }, -- Chi Wave
        { spell = 115181, type = "ability", talent = 115181 }, -- Breath of Fire
        { spell = 115203, type = "ability", talent = 115203 }, -- Fortifying Brew
        { spell = 115313, type = "ability", totem = true, talent = 115313 }, -- Summon Jade Serpent Statue
        { spell = 115315, type = "ability", totem = true, talent = 115315 }, -- Summon Black Ox Statue
        { spell = 115399, type = "ability", talent = 115399 }, -- Black Ox Brew
        { spell = 115546, type = "ability", requiresTarget = true, talent = 328670 }, -- Provoke
        { spell = 116095, type = "ability", requiresTarget = true, talent = 116095 }, -- Disable
        { spell = 116705, type = "ability", requiresTarget = true, talent = 116705 }, -- Spear Hand Strike
        { spell = 116841, type = "ability", buff = true, talent = 116841 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 116844 }, -- Ring of Peace
        { spell = 116847, type = "ability", buff = true, talent = 116847 }, -- Rushing Jade Wind
        { spell = 117952, type = "ability", requiresTarget = true }, -- Crackling Jade Lightning
        { spell = 119381, type = "ability" }, -- Leg Sweep
        { spell = 119582, type = "ability", charges = true, talent = 119582 }, -- Purifying Brew
        { spell = 119996, type = "ability" }, -- Transcendence: Transfer
        { spell = 121253, type = "ability", charges = true, requiresTarget = true, talent = 121253 }, -- Keg Smash
        { spell = 122278, type = "ability", buff = true, talent = 122278 }, -- Dampen Harm
        { spell = 122281, type = "ability", charges = true, talent = 122281 }, -- Healing Elixir
        { spell = 122783, type = "ability", buff = true, talent = 122783 }, -- Diffuse Magic
        { spell = 123986, type = "ability", talent = 123986 }, -- Chi Burst
        { spell = 126892, type = "ability" }, -- Zen Pilgrimage
        { spell = 132578, type = "ability", buff = true, requiresTarget = true, totem = true, talent = 132578 }, -- Invoke Niuzao, the Black Ox
        { spell = 205523, type = "ability", requiresTarget = true }, -- Blackout Kick
        { spell = 322101, type = "ability", talent = 322101 }, -- Expel Harm
        { spell = 322109, type = "ability", requiresTarget = true, usable = true, talent = 322113 }, -- Touch of Death
        { spell = 322113, type = "ability", requiresTarget = true, talent = 322113 }, -- Improved Touch of Death
        { spell = 322507, type = "ability", buff = true, talent = 322507 }, -- Celestial Brew
        { spell = 324312, type = "ability", requiresTarget = true, talent = 324312 }, -- Clash
        { spell = 325153, type = "ability", buff = true, talent = 325153 }, -- Exploding Keg
        { spell = 328670, type = "ability", requiresTarget = true, talent = 328670 }, -- Hasty Provocation
        { spell = 386276, type = "ability", buff = true, talent = 386276 }, -- Bonedust Brew
        { spell = 387184, type = "ability", buff = true, talent = 387184 }, -- Weapons of Order
        { spell = 388686, type = "ability", totem = true, talent = 388686 }, -- Summon White Tiger Statue
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
        { spell = 202335, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Double Barrel
        { spell = 354540, type = "buff", unit = "player", pvptalent = 1, titleSuffix = L["buff"] }, -- Nimble Brew
        { spell = 202162, type = "ability", pvptalent = 4, titleSuffix = L["cooldown"] }, -- Avert Harm
        { spell = 202335, type = "ability", buff = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Double Barrel
        { spell = 354540, type = "ability", buff = true, pvptalent = 1, titleSuffix = L["cooldown"] }, -- Nimble Brew
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 101643, type = "buff", unit = "player", talent = 101643 }, -- Transcendence
        { spell = 115175, type = "buff", unit = "player", talent = 115175 }, -- Soothing Mist
        { spell = 116680, type = "buff", unit = "player", talent = 116680 }, -- Thunder Focus Tea
        { spell = 116841, type = "buff", unit = "player", talent = 116841 }, -- Tiger's Lust
        { spell = 116849, type = "buff", unit = "player", talent = 116849 }, -- Life Cocoon
        { spell = 119611, type = "buff", unit = "player", talent = 115151 }, -- Renewing Mist
        { spell = 120954, type = "buff", unit = "player", talent = 115203 }, -- Fortifying Brew
        { spell = 122278, type = "buff", unit = "player", talent = 122278 }, -- Dampen Harm
        { spell = 122783, type = "buff", unit = "player", talent = 122783 }, -- Diffuse Magic
        { spell = 124682, type = "buff", unit = "player", talent = 124682 }, -- Enveloping Mist
        { spell = 166646, type = "buff", unit = "player", talent = 157411 }, -- Windwalking
        { spell = 191840, type = "buff", unit = "player", talent = 191837 }, -- Essence Font
        { spell = 196608, type = "buff", unit = "player", talent = 196607 }, -- Eye of the Tiger
        { spell = 197916, type = "buff", unit = "player" }, -- Lifecycles (Vivify)
        { spell = 197919, type = "buff", unit = "player" }, -- Lifecycles (Enveloping Mist)
        { spell = 202090, type = "buff", unit = "player", talent = 116645 }, -- Teachings of the Monastery
        { spell = 325209, type = "buff", unit = "player", talent = 343655 }, -- Enveloping Breath
        { spell = 343737, type = "buff", unit = "player" }, -- Soothing Breath
        { spell = 343820, type = "buff", unit = "player", talent = 325197 }, -- Invoke Chi-Ji, the Red Crane
        { spell = 386276, type = "buff", unit = "player", talent = 386276 }, -- Bonedust Brew
        { spell = 387766, type = "buff", unit = "player", talent = 387765 }, -- Nourishing Chi
        { spell = 388026, type = "buff", unit = "player", talent = 388023 }, -- Ancient Teachings
        { spell = 388193, type = "buff", unit = "player", talent = 388193 }, -- Faeline Stomp
        { spell = 388220, type = "buff", unit = "player", talent = 388218 }, -- Calming Coalescence
        { spell = 388479, type = "buff", unit = "player", talent = 388477 }, -- Unison
        { spell = 388497, type = "buff", unit = "player", talent = 388491 }, -- Secret Infusion
        { spell = 388513, type = "buff", unit = "player", talent = 388511 }, -- Overflowing Mists
        { spell = 388518, type = "buff", unit = "player", talent = 393460 }, -- Tea of Serenity
        { spell = 388555, type = "buff", unit = "player", talent = 388551 }, -- Uplifted Spirits
        { spell = 388566, type = "buff", unit = "player", talent = 388564 }, -- Accumulating Mist
        { spell = 389387, type = "buff", unit = "player", talent = 388779 }, -- Awakened Faeline
        { spell = 389391, type = "buff", unit = "player", talent = 388740 }, -- Ancient Concordance
        { spell = 389422, type = "buff", unit = "player" }, -- Yu'lon's Blessing
        { spell = 389684, type = "buff", unit = "player", talent = 389574 }, -- Close to Heart
        { spell = 389685, type = "buff", unit = "player", talent = 389575 }, -- Generous Pour
        { spell = 392883, type = "buff", unit = "player", talent = 388812 }, -- Vivacious Vivification
        { spell = 394112, type = "buff", unit = "player", talent = 394110 }, -- Escape from Reality
      },
      icon = 627487
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target" }, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "target", talent = 115078 }, -- Paralysis
        { spell = 116189, type = "debuff", unit = "target", talent = 328670 }, -- Provoke
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target" }, -- Leg Sweep
        { spell = 196608, type = "debuff", unit = "target", talent = 196607 }, -- Eye of the Tiger
        { spell = 198909, type = "debuff", unit = "target", talent = 198898 }, -- Song of Chi-Ji
        { spell = 386276, type = "debuff", unit = "target", talent = 386276 }, -- Bonedust Brew
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100780, type = "ability", requiresTarget = true }, -- Tiger Palm
        { spell = 100784, type = "ability", requiresTarget = true }, -- Blackout Kick
        { spell = 101643, type = "ability", buff = true, talent = 101643 }, -- Transcendence
        { spell = 107428, type = "ability", requiresTarget = true, talent = 107428 }, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true, talent = 109132 }, -- Roll
        { spell = 115078, type = "ability", requiresTarget = true, talent = 115078 }, -- Paralysis
        { spell = 115098, type = "ability", requiresTarget = true, talent = 115098 }, -- Chi Wave
        { spell = 115151, type = "ability", charges = true, talent = 115151 }, -- Renewing Mist
        { spell = 115203, type = "ability", talent = 115203 }, -- Fortifying Brew
        { spell = 115310, type = "ability", talent = 115310 }, -- Revival
        { spell = 115313, type = "ability", totem = true, talent = 115313 }, -- Summon Jade Serpent Statue
        { spell = 115315, type = "ability", totem = true, talent = 115315 }, -- Summon Black Ox Statue
        { spell = 115546, type = "ability", requiresTarget = true, talent = 328670 }, -- Provoke
        { spell = 116680, type = "ability", buff = true, usable = true, talent = 116680 }, -- Thunder Focus Tea
        { spell = 116705, type = "ability", requiresTarget = true, talent = 116705 }, -- Spear Hand Strike
        { spell = 116841, type = "ability", buff = true, talent = 116841 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 116844 }, -- Ring of Peace
        { spell = 116849, type = "ability", buff = true, talent = 116849 }, -- Life Cocoon
        { spell = 117952, type = "ability", requiresTarget = true }, -- Crackling Jade Lightning
        { spell = 119381, type = "ability" }, -- Leg Sweep
        { spell = 119996, type = "ability", usable = true }, -- Transcendence: Transfer
        { spell = 122278, type = "ability", buff = true, talent = 122278 }, -- Dampen Harm
        { spell = 122281, type = "ability", charges = true, talent = 122281 }, -- Healing Elixir
        { spell = 122783, type = "ability", buff = true, talent = 122783 }, -- Diffuse Magic
        { spell = 123986, type = "ability", talent = 123986 }, -- Chi Burst
        { spell = 124081, type = "ability", talent = 124081 }, -- Zen Pulse
        { spell = 126892, type = "ability", usable = true }, -- Zen Pilgrimage
        { spell = 191837, type = "ability", charges = true, talent = 191837 }, -- Essence Font
        { spell = 196725, type = "ability", talent = 196725 }, -- Refreshing Jade Wind
        { spell = 198898, type = "ability", talent = 198898 }, -- Song of Chi-Ji
        { spell = 322101, type = "ability", talent = 322101 }, -- Expel Harm
        { spell = 322109, type = "ability", requiresTarget = true, usable = true, talent = 322113 }, -- Touch of Death
        { spell = 322118, type = "ability", totem = true, talent = 322118 }, -- Invoke Yu'lon, the Jade Serpent
        { spell = 325197, type = "ability", totem = true, talent = 325197 }, -- Invoke Chi-Ji, the Red Crane
        { spell = 386276, type = "ability", buff = true, talent = 386276 }, -- Bonedust Brew
        { spell = 388193, type = "ability", buff = true, talent = 388193 }, -- Faeline Stomp
        { spell = 388686, type = "ability", totem = true, talent = 388686 }, -- Summon White Tiger Statue
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
        { spell = 209584, type = "buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"] }, -- Zen Focus Tea
        { spell = 202370, type = "ability", requiresTarget = true, pvptalent = 4, titleSuffix = L["cooldown"] }, -- Mighty Ox Kick
        { spell = 205234, type = "ability", charges = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Healing Sphere
        { spell = 209584, type = "ability", buff = true, pvptalent = 2, titleSuffix = L["cooldown"] }, -- Zen Focus Tea
        { spell = 233759, type = "ability", requiresTarget = true, pvptalent = 1, titleSuffix = L["cooldown"] }, -- Grapple Weapon
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 101643, type = "buff", unit = "player", talent = 101643 }, -- Transcendence
        { spell = 115175, type = "buff", unit = "player", talent = 115175 }, -- Soothing Mist
        { spell = 116768, type = "buff", unit = "player" }, -- Blackout Kick!
        { spell = 116841, type = "buff", unit = "player", talent = 116841 }, -- Tiger's Lust
        { spell = 116847, type = "buff", unit = "player", talent = 116847 }, -- Rushing Jade Wind
        { spell = 120954, type = "buff", unit = "player", talent = 115203 }, -- Fortifying Brew
        { spell = 122278, type = "buff", unit = "player", talent = 122278 }, -- Dampen Harm
        { spell = 122783, type = "buff", unit = "player", talent = 122783 }, -- Diffuse Magic
        { spell = 125174, type = "buff", unit = "player", talent = 122470 }, -- Touch of Karma
        { spell = 125883, type = "buff", unit = "player" }, -- Zen Flight
        { spell = 129914, type = "buff", unit = "player", talent = 121817 }, -- Power Strikes
        { spell = 137639, type = "buff", unit = "player", talent = 137639 }, -- Storm, Earth, and Fire
        { spell = 152173, type = "buff", unit = "player", talent = 152173 }, -- Serenity
        { spell = 166646, type = "buff", unit = "player", talent = 157411 }, -- Windwalking
        { spell = 195321, type = "buff", unit = "player", talent = 195300 }, -- Transfer the Power
        { spell = 196608, type = "buff", unit = "player", talent = 196607 }, -- Eye of the Tiger
        { spell = 196741, type = "buff", unit = "player", talent = 196740 }, -- Hit Combo
        { spell = 196742, type = "buff", unit = "player", talent = 152175 }, -- Whirling Dragon Punch
        { spell = 202090, type = "buff", unit = "player", talent = 116645 }, -- Teachings of the Monastery
        { spell = 248646, type = "buff", unit = "player" }, -- Tigereye Brew
        { spell = 287062, type = "buff", unit = "player", talent = 396166 }, -- Fury of Xuen
        { spell = 325202, type = "buff", unit = "player", talent = 325201 }, -- Dance of Chi-Ji
        { spell = 386276, type = "buff", unit = "player", talent = 386276 }, -- Bonedust Brew
        { spell = 388193, type = "buff", unit = "player", talent = 388193 }, -- Faeline Stomp
        { spell = 388663, type = "buff", unit = "player", talent = 388661 }, -- Invoker's Delight
        { spell = 389684, type = "buff", unit = "player", talent = 389574 }, -- Close to Heart
        { spell = 389685, type = "buff", unit = "player", talent = 389575 }, -- Generous Pour
        { spell = 392883, type = "buff", unit = "player", talent = 388812 }, -- Vivacious Vivification
        { spell = 393039, type = "buff", unit = "player" }, -- The Emperor's Capacitor
        { spell = 393053, type = "buff", unit = "player" }, -- Pressure Point
        { spell = 393057, type = "buff", unit = "player" }, -- Chi Energy
        { spell = 393565, type = "buff", unit = "player", talent = 392985 }, -- Thunderfist
        { spell = 394112, type = "buff", unit = "player", talent = 394110 }, -- Escape from Reality
        { spell = 395413, type = "buff", unit = "player" }, -- Fae Exposure
      },
      icon = 611420
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target" }, -- Mystic Touch
        { spell = 115804, type = "debuff", unit = "target" }, -- Mortal Wounds
        { spell = 116095, type = "debuff", unit = "target", talent = 116095 }, -- Disable
        { spell = 116189, type = "debuff", unit = "target", talent = 328670 }, -- Provoke
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target" }, -- Leg Sweep
        { spell = 122470, type = "debuff", unit = "target", talent = 122470 }, -- Touch of Karma
        { spell = 196608, type = "debuff", unit = "target", talent = 196607 }, -- Eye of the Tiger
        { spell = 201787, type = "debuff", unit = "target" }, -- Heavy-Handed Strikes
        { spell = 228287, type = "debuff", unit = "target", talent = 228287 }, -- Mark of the Crane
        { spell = 386276, type = "debuff", unit = "target", talent = 386276 }, -- Bonedust Brew
        { spell = 392983, type = "debuff", unit = "target", talent = 392983 }, -- Strike of the Windlord
        { spell = 393047, type = "debuff", unit = "target", talent = 392991 }, -- Skyreach
        { spell = 393050, type = "debuff", unit = "target" }, -- Skyreach Exhaustion
        { spell = 395414, type = "debuff", unit = "target" }, -- Fae Exposure
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100780, type = "ability", overlayGlow = true, requiresTarget = true }, -- Tiger Palm
        { spell = 100784, type = "ability", overlayGlow = true, requiresTarget = true }, -- Blackout Kick
        { spell = 101545, type = "ability", talent = 101545 }, -- Flying Serpent Kick
        { spell = 101546, type = "ability", charges = true, overlayGlow = true }, -- Spinning Crane Kick
        { spell = 101643, type = "ability", buff = true, talent = 101643 }, -- Transcendence
        { spell = 107428, type = "ability", requiresTarget = true, talent = 107428 }, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true, talent = 109132 }, -- Roll
        { spell = 113656, type = "ability", requiresTarget = true, totem = true, talent = 113656 }, -- Fists of Fury
        { spell = 115078, type = "ability", requiresTarget = true, talent = 115078 }, -- Paralysis
        { spell = 115098, type = "ability", requiresTarget = true, talent = 115098 }, -- Chi Wave
        { spell = 115203, type = "ability", talent = 115203 }, -- Fortifying Brew
        { spell = 115313, type = "ability", totem = true, talent = 115313 }, -- Summon Jade Serpent Statue
        { spell = 115315, type = "ability", totem = true, talent = 115315 }, -- Summon Black Ox Statue
        { spell = 115546, type = "ability", requiresTarget = true, talent = 328670 }, -- Provoke
        { spell = 116095, type = "ability", requiresTarget = true, talent = 116095 }, -- Disable
        { spell = 116705, type = "ability", requiresTarget = true, talent = 116705 }, -- Spear Hand Strike
        { spell = 116841, type = "ability", buff = true, talent = 116841 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 116844 }, -- Ring of Peace
        { spell = 116847, type = "ability", buff = true, talent = 116847 }, -- Rushing Jade Wind
        { spell = 117952, type = "ability", requiresTarget = true }, -- Crackling Jade Lightning
        { spell = 119381, type = "ability" }, -- Leg Sweep
        { spell = 119996, type = "ability", usable = true }, -- Transcendence: Transfer
        { spell = 122278, type = "ability", buff = true, talent = 122278 }, -- Dampen Harm
        { spell = 122470, type = "ability", requiresTarget = true, talent = 122470 }, -- Touch of Karma
        { spell = 122783, type = "ability", buff = true, talent = 122783 }, -- Diffuse Magic
        { spell = 123904, type = "ability", requiresTarget = true, totem = true, talent = 123904 }, -- Invoke Xuen, the White Tiger
        { spell = 123986, type = "ability", talent = 123986 }, -- Chi Burst
        { spell = 126892, type = "ability", usable = true }, -- Zen Pilgrimage
        { spell = 137639, type = "ability", charges = true, buff = true, talent = 137639 }, -- Storm, Earth, and Fire
        { spell = 152173, type = "ability", buff = true, talent = 152173 }, -- Serenity
        { spell = 152175, type = "ability", talent = 152175 }, -- Whirling Dragon Punch
        { spell = 205320, type = "ability", requiresTarget = true, talent = 205320 }, -- Strike of the Windlord
        { spell = 221771, type = "ability" }, -- Storm, Earth, and Fire: Fixate
        { spell = 322101, type = "ability", talent = 322101 }, -- Expel Harm
        { spell = 322109, type = "ability", requiresTarget = true, usable = true, talent = 322113 }, -- Touch of Death
        { spell = 322113, type = "ability", requiresTarget = true, talent = 322113 }, -- Improved Touch of Death
        { spell = 328670, type = "ability", requiresTarget = true, talent = 328670 }, -- Hasty Provocation
        { spell = 344359, type = "ability", requiresTarget = true, talent = 344359 }, -- Improved Paralysis
        { spell = 386276, type = "ability", buff = true, talent = 386276 }, -- Bonedust Brew
        { spell = 388193, type = "ability", buff = true, overlayGlow = true, talent = 388193 }, -- Faeline Stomp
        { spell = 388686, type = "ability", totem = true, talent = 388686 }, -- Summon White Tiger Statue
        { spell = 392983, type = "ability", requiresTarget = true, talent = 392983 }, -- Strike of the Windlord
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
        { spell = 247483, type = "buff", unit = "player", pvptalent = 2, titleSuffix = L["buff"] }, -- Tigereye Brew
        { spell = 202370, type = "ability", requiresTarget = true, pvptalent = 10, titleSuffix = L["cooldown"] }, -- Mighty Ox Kick
        { spell = 233759, type = "ability", requiresTarget = true, pvptalent = 9, titleSuffix = L["cooldown"] }, -- Grapple Weapon
        { spell = 247483, type = "ability", charges = true, buff = true, overlayGlow = true, pvptalent = 2, titleSuffix = L["cooldown"] }, -- Tigereye Brew
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 768, type = "buff", unit = "player" }, -- Cat Form
        { spell = 774, type = "buff", unit = "player", talent = 774 }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player" }, -- Travel Form
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 24858, type = "buff", unit = "player", talent = 24858 }, -- Moonkin Form
        { spell = 48517, type = "buff", unit = "player" }, -- Eclipse (Solar)
        { spell = 48518, type = "buff", unit = "player" }, -- Eclipse (Lunar)
        { spell = 77761, type = "buff", unit = "player", talent = 106898 }, -- Stampeding Roar
        { spell = 124974, type = "buff", unit = "player", talent = 124974 }, -- Nature's Vigil
        { spell = 191034, type = "buff", unit = "player", talent = 191034 }, -- Starfall
        { spell = 192081, type = "buff", unit = "player", talent = 192081 }, -- Ironfur
        { spell = 194223, type = "buff", unit = "player", talent = 194223 }, -- Celestial Alignment
        { spell = 202425, type = "buff", unit = "player", talent = 202425 }, -- Warrior of Elune
        { spell = 203407, type = "buff", unit = "player" }, -- Reactive Resin
        { spell = 209746, type = "buff", unit = "player" }, -- Moonkin Aura
        { spell = 234084, type = "buff", unit = "player" }, -- Moon and Stars
        { spell = 252216, type = "buff", unit = "player", talent = 252216 }, -- Tiger Dash
        { spell = 279709, type = "buff", unit = "player", talent = 202345 }, -- Starlord
        { spell = 319454, type = "buff", unit = "player", talent = 319454 }, -- Heart of the Wild
        { spell = 343648, type = "buff", unit = "player", talent = 343647 }, -- Solstice
        { spell = 385787, type = "buff", unit = "player", talent = 385786 }, -- Matted Fur
        { spell = 391528, type = "buff", unit = "player", talent = 391528 }, -- Convoke the Spirits
        { spell = 393763, type = "buff", unit = "player", talent = 393760 }, -- Umbral Embrace
        { spell = 393897, type = "buff", unit = "player", talent = 377801 }, -- Tireless Pursuit
        { spell = 393903, type = "buff", unit = "player", talent = 377842 }, -- Ursine Vigor
        { spell = 393942, type = "buff", unit = "player" }, -- Starweaver's Warp
        { spell = 393944, type = "buff", unit = "player" }, -- Starweaver's Weft
        { spell = 393955, type = "buff", unit = "player" }, -- Rattled Stars
        { spell = 393959, type = "buff", unit = "player", talent = 393958 }, -- Nature's Grace
        { spell = 393961, type = "buff", unit = "player", talent = 393960 }, -- Primordial Arcanic Pulsar
        { spell = 394049, type = "buff", unit = "player", talent = 394048 }, -- Balance of All Things
        { spell = 394108, type = "buff", unit = "player", talent = 394094 }, -- Sundered Firmament
        { spell = 395110, type = "buff", unit = "player" }, -- Parting Skies
        { spell = 395336, type = "buff", unit = "player", talent = 378986 }, -- Protector of the Pack
      },
      icon = 136097
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 1079 }, -- Rip
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 61391, type = "debuff", unit = "target", talent = 132469 }, -- Typhoon
        { spell = 81261, type = "debuff", unit = "target", talent = 78675 }, -- Solar Beam
        { spell = 81281, type = "debuff", unit = "target", talent = 392999 }, -- Fungal Growth
        { spell = 102359, type = "debuff", unit = "target", talent = 102359 }, -- Mass Entanglement
        { spell = 106830, type = "debuff", unit = "target", talent = 106832 }, -- Thrash
        { spell = 155722, type = "debuff", unit = "target", talent = 1822 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 93402 }, -- Sunfire
        { spell = 202347, type = "debuff", unit = "target", talent = 202347 }, -- Stellar Flare
        { spell = 203123, type = "debuff", unit = "target", talent = 22570 }, -- Maim
        { spell = 205644, type = "debuff", unit = "target", talent = 205636 }, -- Force of Nature
        { spell = 393957, type = "debuff", unit = "target", talent = 393956 }, -- Waning Twilight
        { spell = 394061, type = "debuff", unit = "target", talent = 394058 }, -- Astral Smolder
      },
      icon = 132114
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", talent = 99 }, -- Incapacitating Roar
        { spell = 339, type = "ability", requiresTarget = true }, -- Entangling Roots
        { spell = 768, type = "ability", buff = true }, -- Cat Form
        { spell = 783, type = "ability", buff = true }, -- Travel Form
        { spell = 1079, type = "ability", requiresTarget = true, usable = true, talent = 1079 }, -- Rip
        { spell = 1822, type = "ability", requiresTarget = true, usable = true, talent = 1822 }, -- Rake
        { spell = 1850, type = "ability", buff = true }, -- Dash
        { spell = 2782, type = "ability", talent = 2782 }, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true, talent = 2908 }, -- Soothe
        { spell = 5211, type = "ability", requiresTarget = true, talent = 5211 }, -- Mighty Bash
        { spell = 5221, type = "ability", requiresTarget = true, usable = true }, -- Shred
        { spell = 5487, type = "ability", buff = true }, -- Bear Form
        { spell = 6795, type = "ability", requiresTarget = true, usable = true }, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true }, -- Moonfire
        { spell = 18562, type = "ability", usable = true, talent = 18562 }, -- Swiftmend
        { spell = 20484, type = "ability" }, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true, usable = true }, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, usable = true, talent = 22570 }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", charges = true, usable = true, talent = 22842 }, -- Frenzied Regeneration
        { spell = 24858, type = "ability", buff = true, talent = 24858 }, -- Moonkin Form
        { spell = 33786, type = "ability", requiresTarget = true, talent = 33786 }, -- Cyclone
        { spell = 33917, type = "ability", requiresTarget = true, usable = true, talent = 231064 }, -- Mangle
        { spell = 48438, type = "ability", requiresTarget = true, talent = 48438 }, -- Wild Growth
        { spell = 77758, type = "ability", requiresTarget = true, talent = 106832 }, -- Thrash
        { spell = 77761, type = "ability", buff = true, talent = 106898 }, -- Stampeding Roar
        { spell = 78674, type = "ability", overlayGlow = true, requiresTarget = true, talent = 78674 }, -- Starsurge
        { spell = 78675, type = "ability", requiresTarget = true, talent = 78675 }, -- Solar Beam
        { spell = 88747, type = "ability", charges = true, requiresTarget = true, usable = true, talent = 88747 }, -- Wild Mushroom
        { spell = 93402, type = "ability", requiresTarget = true, talent = 93402 }, -- Sunfire
        { spell = 102359, type = "ability", requiresTarget = true, talent = 102359 }, -- Mass Entanglement
        { spell = 102401, type = "ability", requiresTarget = true, talent = 102401 }, -- Wild Charge
        { spell = 106839, type = "ability", requiresTarget = true, usable = true, talent = 106839 }, -- Skull Bash
        { spell = 108238, type = "ability", talent = 108238 }, -- Renewal
        { spell = 124974, type = "ability", buff = true, talent = 124974 }, -- Nature's Vigil
        { spell = 132469, type = "ability", talent = 132469 }, -- Typhoon
        { spell = 190984, type = "ability", charges = true, overlayGlow = true, requiresTarget = true }, -- Wrath
        { spell = 192081, type = "ability", buff = true, usable = true, talent = 192081 }, -- Ironfur
        { spell = 194153, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 194153 }, -- Starfire
        { spell = 194223, type = "ability", buff = true, talent = 194223 }, -- Celestial Alignment
        { spell = 197628, type = "ability", requiresTarget = true, talent = 197628 }, -- Starfire
        { spell = 202347, type = "ability", requiresTarget = true, talent = 202347 }, -- Stellar Flare
        { spell = 202359, type = "ability", talent = 202359 }, -- Astral Communion
        { spell = 202425, type = "ability", buff = true, usable = true, talent = 202425 }, -- Warrior of Elune
        { spell = 202770, type = "ability", requiresTarget = true, talent = 202770 }, -- Fury of Elune
        { spell = 205636, type = "ability", talent = 205636 }, -- Force of Nature
        { spell = 252216, type = "ability", buff = true, talent = 252216 }, -- Tiger Dash
        { spell = 274281, type = "ability", charges = true, requiresTarget = true, talent = 274281 }, -- New Moon
        { spell = 274282, type = "ability", charges = true }, -- Half Moon
        { spell = 274283, type = "ability", charges = true }, -- Full Moon
        { spell = 319454, type = "ability", buff = true, talent = 319454 }, -- Heart of the Wild
        { spell = 390414, type = "ability", talent = 394013 }, -- Incarnation: Chosen of Elune
        { spell = 391528, type = "ability", buff = true, talent = 391528, exactSpellId = true }, -- Convoke the Spirits
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
        { spell = 305497, type = "buff", unit = "player", pvptalent = 5, titleSuffix = L["buff"] }, -- Thorns
        { spell = 209749, type = "debuff", unit = "target", pvptalent = 10, titleSuffix = L["debuff"] }, -- Faerie Swarm
        { spell = 209749, type = "ability", requiresTarget = true, pvptalent = 10, titleSuffix = L["cooldown"] }, -- Faerie Swarm
        { spell = 305497, type = "ability", buff = true, pvptalent = 5, titleSuffix = L["cooldown"] }, -- Thorns
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 768, type = "buff", unit = "player" }, -- Cat Form
        { spell = 774, type = "buff", unit = "player", talent = 774 }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player" }, -- Travel Form
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 5217, type = "buff", unit = "player", talent = 5217 }, -- Tiger's Fury
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 22842 }, -- Frenzied Regeneration
        { spell = 61336, type = "buff", unit = "player", talent = 61336 }, -- Survival Instincts
        { spell = 69369, type = "buff", unit = "player", talent = 16974 }, -- Predatory Swiftness
        { spell = 77761, type = "buff", unit = "player", talent = 106898 }, -- Stampeding Roar
        { spell = 102401, type = "buff", unit = "player", talent = 102401 }, -- Wild Charge
        { spell = 102543, type = "buff", unit = "player", talent = 102543, exactSpellId = true }, -- Incarnation: Avatar of Ashamane
        { spell = 106951, type = "buff", unit = "player", talent = 106951 }, -- Berserk
        { spell = 124974, type = "buff", unit = "player", talent = 124974 }, -- Nature's Vigil
        { spell = 135700, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 145152, type = "buff", unit = "player", talent = 319439 }, -- Bloodtalons
        { spell = 192081, type = "buff", unit = "player", talent = 192081 }, -- Ironfur
        { spell = 197625, type = "buff", unit = "player", talent = 197625 }, -- Moonkin Form
        { spell = 197721, type = "buff", unit = "player" }, -- Flourish
        { spell = 202636, type = "buff", unit = "player" }, -- Leader of the Pack
        { spell = 236440, type = "buff", unit = "player" }, -- Strength of the Wild
        { spell = 252216, type = "buff", unit = "player", talent = 252216 }, -- Tiger Dash
        { spell = 319454, type = "buff", unit = "player", talent = 319454 }, -- Heart of the Wild
        { spell = 385787, type = "buff", unit = "player", talent = 385786 }, -- Matted Fur
        { spell = 391528, type = "buff", unit = "player", talent = 391528 }, -- Convoke the Spirits
        { spell = 391722, type = "buff", unit = "player", talent = 202031 }, -- Sabertooth
        { spell = 391873, type = "buff", unit = "player", talent = 391872 }, -- Tiger's Tenacity
        { spell = 391876, type = "buff", unit = "player", talent = 391875 }, -- Frantic Momentum
        { spell = 391882, type = "buff", unit = "player", talent = 391881 }, -- Apex Predator's Craving
        { spell = 391955, type = "buff", unit = "player", talent = 391947 }, -- Protective Growth
        { spell = 391974, type = "buff", unit = "player", talent = 384667 }, -- Sudden Ambush
        { spell = 393897, type = "buff", unit = "player", talent = 377801 }, -- Tireless Pursuit
        { spell = 393903, type = "buff", unit = "player", talent = 377842 }, -- Ursine Vigor
        { spell = 393961, type = "buff", unit = "player", talent = 393960 }, -- Primordial Arcanic Pulsar
        { spell = 395336, type = "buff", unit = "player", talent = 378986 }, -- Protector of the Pack
      },
      icon = 136170
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target", talent = 99 }, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 1079 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 5211 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 58180, type = "debuff", unit = "target", talent = 48484 }, -- Infected Wounds
        { spell = 61391, type = "debuff", unit = "target", talent = 132469 }, -- Typhoon
        { spell = 102359, type = "debuff", unit = "target", talent = 102359 }, -- Mass Entanglement
        { spell = 106830, type = "debuff", unit = "target", talent = 106832 }, -- Thrash
        { spell = 155722, type = "debuff", unit = "target", talent = 1822 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 93402 }, -- Sunfire
        { spell = 203123, type = "debuff", unit = "target", talent = 22570 }, -- Maim
        { spell = 236021, type = "debuff", unit = "target" }, -- Ferocious Wound
        { spell = 391140, type = "debuff", unit = "target" }, -- Frenzied Assault
        { spell = 391356, type = "debuff", unit = "target" }, -- Tear
        { spell = 391889, type = "debuff", unit = "target", talent = 391888 }, -- Adaptive Swarm
      },
      icon = 132152
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", talent = 99 }, -- Incapacitating Roar
        { spell = 339, type = "ability", overlayGlow = true, requiresTarget = true }, -- Entangling Roots
        { spell = 768, type = "ability", buff = true }, -- Cat Form
        { spell = 783, type = "ability", buff = true }, -- Travel Form
        { spell = 1079, type = "ability", requiresTarget = true, usable = true, talent = 1079 }, -- Rip
        { spell = 1822, type = "ability", requiresTarget = true, usable = true, talent = 1822 }, -- Rake
        { spell = 1850, type = "ability", buff = true }, -- Dash
        { spell = 2782, type = "ability", talent = 2782 }, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true, talent = 2908 }, -- Soothe
        { spell = 5176, type = "ability", charges = true, requiresTarget = true }, -- Wrath
        { spell = 5211, type = "ability", requiresTarget = true, talent = 5211 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true, usable = true }, -- Prowl
        { spell = 5217, type = "ability", buff = true, talent = 5217 }, -- Tiger's Fury
        { spell = 5221, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Shred
        { spell = 5487, type = "ability", buff = true }, -- Bear Form
        { spell = 6795, type = "ability", requiresTarget = true, usable = true }, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true }, -- Moonfire
        { spell = 18562, type = "ability", usable = true, talent = 18562 }, -- Swiftmend
        { spell = 20484, type = "ability" }, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true, usable = true }, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, usable = true, talent = 22570 }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", charges = true, buff = true, usable = true, talent = 22842 }, -- Frenzied Regeneration
        { spell = 33786, type = "ability", requiresTarget = true, talent = 33786 }, -- Cyclone
        { spell = 33917, type = "ability", requiresTarget = true, usable = true, talent = 231064 }, -- Mangle
        { spell = 48438, type = "ability", requiresTarget = true, talent = 48438 }, -- Wild Growth
        { spell = 49376, type = "ability", requiresTarget = true, talent = 102401 }, -- Wild Charge
        { spell = 61336, type = "ability", buff = true, talent = 61336 }, -- Survival Instincts
        { spell = 77758, type = "ability", requiresTarget = true, talent = 106832 }, -- Thrash
        { spell = 77761, type = "ability", buff = true, talent = 106898 }, -- Stampeding Roar
        { spell = 78674, type = "ability", requiresTarget = true, talent = 78674 }, -- Starsurge
        { spell = 93402, type = "ability", requiresTarget = true, talent = 93402 }, -- Sunfire
        { spell = 102359, type = "ability", requiresTarget = true, talent = 102359 }, -- Mass Entanglement
        { spell = 102543, type = "ability", buff = true, talent = 102543 }, -- Incarnation: Avatar of Ashamane
        { spell = 106832, type = "ability", requiresTarget = true, usable = true, talent = 106832 }, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true, usable = true, talent = 106839 }, -- Skull Bash
        { spell = 106951, type = "ability", buff = true, talent = 106951 }, -- Berserk
        { spell = 108238, type = "ability", talent = 108238 }, -- Renewal
        { spell = 124974, type = "ability", buff = true, talent = 124974 }, -- Nature's Vigil
        { spell = 132469, type = "ability", talent = 132469 }, -- Typhoon
        { spell = 192081, type = "ability", buff = true, usable = true, talent = 192081 }, -- Ironfur
        { spell = 197625, type = "ability", buff = true, talent = 197625 }, -- Moonkin Form
        { spell = 197628, type = "ability", charges = true, requiresTarget = true, talent = 197628 }, -- Starfire
        { spell = 202028, type = "ability", charges = true, overlayGlow = true, talent = 202028 }, -- Brutal Slash
        { spell = 231064, type = "ability", requiresTarget = true, talent = 231064 }, -- Mangle
        { spell = 236716, type = "ability", requiresTarget = true, usable = true }, -- Strength of the Wild
        { spell = 252216, type = "ability", buff = true, talent = 252216 }, -- Tiger Dash
        { spell = 274837, type = "ability", requiresTarget = true, usable = true, talent = 274837 }, -- Feral Frenzy
        { spell = 319454, type = "ability", buff = true, talent = 319454 }, -- Heart of the Wild
        { spell = 325727, type = "ability", requiresTarget = true, talent = 325727 }, -- Adaptive Swarm
        { spell = 391528, type = "ability", buff = true, talent = 391528, exactSpellId = true }, -- Convoke the Spirits
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
        { spell = 305497, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Thorns
        { spell = 305497, type = "ability", buff = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Thorns
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 768, type = "buff", unit = "player" }, -- Cat Form
        { spell = 774, type = "buff", unit = "player", talent = 774 }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player" }, -- Travel Form
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 22842 }, -- Frenzied Regeneration
        { spell = 50334, type = "buff", unit = "player", talent = 106951 }, -- Berserk
        { spell = 61336, type = "buff", unit = "player", talent = 61336 }, -- Survival Instincts
        { spell = 77761, type = "buff", unit = "player", talent = 106898 }, -- Stampeding Roar
        { spell = 93622, type = "buff", unit = "player", talent = 210706 }, -- Gore
        { spell = 102558, type = "buff", unit = "player", talent = 102558 }, -- Incarnation: Guardian of Ursoc
        { spell = 124974, type = "buff", unit = "player", talent = 124974 }, -- Nature's Vigil
        { spell = 135286, type = "buff", unit = "player", talent = 135288 }, -- Tooth and Claw
        { spell = 155835, type = "buff", unit = "player", talent = 155835 }, -- Bristling Fur
        { spell = 192081, type = "buff", unit = "player", talent = 192081 }, -- Ironfur
        { spell = 197625, type = "buff", unit = "player", talent = 197625 }, -- Moonkin Form
        { spell = 200851, type = "buff", unit = "player", talent = 200851 }, -- Rage of the Sleeper
        { spell = 201671, type = "buff", unit = "player", talent = 200854 }, -- Gory Fur
        { spell = 203975, type = "buff", unit = "player", talent = 203974 }, -- Earthwarden
        { spell = 213708, type = "buff", unit = "player", talent = 203964 }, -- Galactic Guardian
        { spell = 252216, type = "buff", unit = "player", talent = 252216 }, -- Tiger Dash
        { spell = 319454, type = "buff", unit = "player", talent = 319454 }, -- Heart of the Wild
        { spell = 354704, type = "buff", unit = "player" }, -- Grove Protection
        { spell = 372015, type = "buff", unit = "player", talent = 371999 }, -- Vicious Cycle
        { spell = 372505, type = "buff", unit = "player", talent = 377210 }, -- Ursoc's Fury
        { spell = 385787, type = "buff", unit = "player", talent = 385786 }, -- Matted Fur
        { spell = 391528, type = "buff", unit = "player", talent = 391528 }, -- Convoke the Spirits
        { spell = 393897, type = "buff", unit = "player", talent = 377801 }, -- Tireless Pursuit
        { spell = 393903, type = "buff", unit = "player", talent = 377842 }, -- Ursine Vigor
        { spell = 395336, type = "buff", unit = "player", talent = 378986 }, -- Protector of the Pack
      },
      icon = 1378702
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target", talent = 99 }, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 1079 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 5211 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 61391, type = "debuff", unit = "target", talent = 132469 }, -- Typhoon
        { spell = 80313, type = "debuff", unit = "target", talent = 80313 }, -- Pulverize
        { spell = 106830, type = "debuff", unit = "target", talent = 106832 }, -- Thrash
        { spell = 127797, type = "debuff", unit = "target", talent = 102793 }, -- Ursol's Vortex
        { spell = 135601, type = "debuff", unit = "target", talent = 135288 }, -- Tooth and Claw
        { spell = 155722, type = "debuff", unit = "target", talent = 1822 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 93402 }, -- Sunfire
        { spell = 202244, type = "debuff", unit = "target" }, -- Overrun
        { spell = 203123, type = "debuff", unit = "target", talent = 22570 }, -- Maim
        { spell = 206891, type = "debuff", unit = "target" }, -- Focused Assault
        { spell = 274838, type = "debuff", unit = "target", talent = 274837 }, -- Feral Frenzy
        { spell = 345209, type = "debuff", unit = "target", talent = 345208 }, -- Infected Wounds
        { spell = 354789, type = "debuff", unit = "target" }, -- Grove Protection
      },
      icon = 451161
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", talent = 99 }, -- Incapacitating Roar
        { spell = 339, type = "ability", requiresTarget = true }, -- Entangling Roots
        { spell = 768, type = "ability", buff = true }, -- Cat Form
        { spell = 783, type = "ability", buff = true }, -- Travel Form
        { spell = 1079, type = "ability", requiresTarget = true, usable = true, talent = 1079 }, -- Rip
        { spell = 1822, type = "ability", requiresTarget = true, usable = true, talent = 1822 }, -- Rake
        { spell = 1850, type = "ability", buff = true }, -- Dash
        { spell = 2782, type = "ability", talent = 2782 }, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true, talent = 2908 }, -- Soothe
        { spell = 5176, type = "ability", charges = true, requiresTarget = true }, -- Wrath
        { spell = 5211, type = "ability", requiresTarget = true, talent = 5211 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true }, -- Prowl
        { spell = 5487, type = "ability", buff = true }, -- Bear Form
        { spell = 6795, type = "ability", requiresTarget = true, usable = true }, -- Growl
        { spell = 6807, type = "ability", overlayGlow = true, requiresTarget = true, talent = 6807 }, -- Maul
        { spell = 8921, type = "ability", overlayGlow = true, requiresTarget = true }, -- Moonfire
        { spell = 20484, type = "ability" }, -- Rebirth
        { spell = 22570, type = "ability", requiresTarget = true, usable = true, talent = 22570 }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", charges = true, buff = true, usable = true, talent = 22842 }, -- Frenzied Regeneration
        { spell = 33786, type = "ability", requiresTarget = true, talent = 33786 }, -- Cyclone
        { spell = 33917, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 231064 }, -- Mangle
        { spell = 48438, type = "ability", requiresTarget = true, talent = 48438 }, -- Wild Growth
        { spell = 49376, type = "ability", talent = 102401 }, -- Wild Charge
        { spell = 50334, type = "ability", buff = true, talent = 106951 }, -- Berserk
        { spell = 61336, type = "ability", charges = true, buff = true, talent = 61336 }, -- Survival Instincts
        { spell = 77758, type = "ability", requiresTarget = true, talent = 106832 }, -- Thrash
        { spell = 77761, type = "ability", buff = true, talent = 106898 }, -- Stampeding Roar
        { spell = 78674, type = "ability", requiresTarget = true, talent = 78674 }, -- Starsurge
        { spell = 80313, type = "ability", requiresTarget = true, talent = 80313 }, -- Pulverize
        { spell = 93402, type = "ability", requiresTarget = true, talent = 93402 }, -- Sunfire
        { spell = 102558, type = "ability", buff = true, talent = 102558 }, -- Incarnation: Guardian of Ursoc
        { spell = 102793, type = "ability", talent = 102793 }, -- Ursol's Vortex
        { spell = 106839, type = "ability", requiresTarget = true, usable = true, talent = 106839 }, -- Skull Bash
        { spell = 124974, type = "ability", buff = true, talent = 124974 }, -- Nature's Vigil
        { spell = 132469, type = "ability", talent = 132469 }, -- Typhoon
        { spell = 155835, type = "ability", buff = true, talent = 155835 }, -- Bristling Fur
        { spell = 192081, type = "ability", buff = true, talent = 192081 }, -- Ironfur
        { spell = 197625, type = "ability", buff = true, talent = 197625 }, -- Moonkin Form
        { spell = 197628, type = "ability", charges = true, requiresTarget = true, talent = 197628 }, -- Starfire
        { spell = 200851, type = "ability", buff = true, talent = 200851 }, -- Rage of the Sleeper
        { spell = 231064, type = "ability", requiresTarget = true, talent = 231064 }, -- Mangle
        { spell = 252216, type = "ability", buff = true, talent = 252216 }, -- Tiger Dash
        { spell = 319454, type = "ability", buff = true, talent = 319454 }, -- Heart of the Wild
        { spell = 391528, type = "ability", buff = true, talent = 391528, exactSpellId = true }, -- Convoke the Spirits
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
        { spell = 329042, type = "buff", unit = "player", pvptalent = 7, titleSuffix = L["buff"] }, -- Emerald Slumber
        { spell = 201664, type = "debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"] }, -- Demoralizing Roar
        { spell = 201664, type = "ability", pvptalent = 14, titleSuffix = L["cooldown"] }, -- Demoralizing Roar
        { spell = 202246, type = "ability", requiresTarget = true, pvptalent = 15, titleSuffix = L["cooldown"] }, -- Overrun
        { spell = 207017, type = "ability", pvptalent = 2, titleSuffix = L["cooldown"] }, -- Alpha Challenge
        { spell = 329042, type = "ability", buff = true, usable = true, pvptalent = 7, titleSuffix = L["cooldown"] }, -- Emerald Slumber
        { spell = 354654, type = "ability", pvptalent = 11, titleSuffix = L["cooldown"] }, -- Grove Protection
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 768, type = "buff", unit = "player" }, -- Cat Form
        { spell = 774, type = "buff", unit = "player", talent = 774 }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player" }, -- Travel Form
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 16870, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 29166, type = "buff", unit = "player", talent = 29166 }, -- Innervate
        { spell = 33763, type = "buff", unit = "player", talent = 33763 }, -- Lifebloom
        { spell = 33891, type = "buff", unit = "player", talent = 33891 }, -- Incarnation: Tree of Life
        { spell = 48438, type = "buff", unit = "player", talent = 48438 }, -- Wild Growth
        { spell = 102342, type = "buff", unit = "player", talent = 102342 }, -- Ironbark
        { spell = 102351, type = "buff", unit = "player", talent = 102351 }, -- Cenarion Ward
        { spell = 102401, type = "buff", unit = "player", talent = 102401 }, -- Wild Charge
        { spell = 106898, type = "buff", unit = "player", talent = 106898 }, -- Stampeding Roar
        { spell = 114108, type = "buff", unit = "player", talent = 158478 }, -- Soul of the Forest
        { spell = 117679, type = "buff", unit = "player" }, -- Incarnation
        { spell = 132158, type = "buff", unit = "player", talent = 132158 }, -- Nature's Swiftness
        { spell = 155777, type = "buff", unit = "player" }, -- Rejuvenation (Germination)
        { spell = 157982, type = "buff", unit = "player", talent = 740 }, -- Tranquility
        { spell = 192081, type = "buff", unit = "player", talent = 192081 }, -- Ironfur
        { spell = 197625, type = "buff", unit = "player", talent = 197625 }, -- Moonkin Form
        { spell = 197721, type = "buff", unit = "player", talent = 197721 }, -- Flourish
        { spell = 203554, type = "buff", unit = "player" }, -- Focused Growth
        { spell = 207386, type = "buff", unit = "player", talent = 207385 }, -- Spring Blossoms
        { spell = 207640, type = "buff", unit = "player", talent = 207383 }, -- Abundance
        { spell = 252216, type = "buff", unit = "player", talent = 252216 }, -- Tiger Dash
        { spell = 290213, type = "buff", unit = "player" }, -- Full Bloom
        { spell = 290640, type = "buff", unit = "player" }, -- Master Shapeshifter
        { spell = 319454, type = "buff", unit = "player", talent = 319454 }, -- Heart of the Wild
        { spell = 362486, type = "buff", unit = "player" }, -- Keeper of the Grove
        { spell = 383193, type = "buff", unit = "player", talent = 383192 }, -- Grove Tending
        { spell = 385787, type = "buff", unit = "player", talent = 385786 }, -- Matted Fur
        { spell = 391528, type = "buff", unit = "player", talent = 391528 }, -- Convoke the Spirits
        { spell = 393897, type = "buff", unit = "player", talent = 377801 }, -- Tireless Pursuit
        { spell = 393903, type = "buff", unit = "player", talent = 377842 }, -- Ursine Vigor
      },
      icon = 136081
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target", talent = 99 }, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 1079 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 5211 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 45334, type = "debuff", unit = "target" }, -- Immobilized
        { spell = 50259, type = "debuff", unit = "target" }, -- Dazed
        { spell = 61391, type = "debuff", unit = "target", talent = 132469 }, -- Typhoon
        { spell = 102359, type = "debuff", unit = "target", talent = 102359 }, -- Mass Entanglement
        { spell = 106830, type = "debuff", unit = "target", talent = 106832 }, -- Thrash
        { spell = 127797, type = "debuff", unit = "target", talent = 102793 }, -- Ursol's Vortex
        { spell = 155722, type = "debuff", unit = "target", talent = 1822 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 93402 }, -- Sunfire
        { spell = 203123, type = "debuff", unit = "target", talent = 22570 }, -- Maim
        { spell = 391889, type = "debuff", unit = "target", talent = 391888 }, -- Adaptive Swarm
      },
      icon = 236216
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", talent = 99 }, -- Incapacitating Roar
        { spell = 339, type = "ability", overlayGlow = true, requiresTarget = true }, -- Entangling Roots
        { spell = 740, type = "ability", talent = 740 }, -- Tranquility
        { spell = 768, type = "ability", buff = true }, -- Cat Form
        { spell = 783, type = "ability", buff = true }, -- Travel Form
        { spell = 1079, type = "ability", requiresTarget = true, talent = 1079 }, -- Rip
        { spell = 1822, type = "ability", requiresTarget = true, talent = 1822 }, -- Rake
        { spell = 1850, type = "ability", buff = true }, -- Dash
        { spell = 2908, type = "ability", requiresTarget = true, talent = 2908 }, -- Soothe
        { spell = 5176, type = "ability", requiresTarget = true }, -- Wrath
        { spell = 5211, type = "ability", requiresTarget = true, talent = 5211 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true }, -- Prowl
        { spell = 5487, type = "ability", buff = true }, -- Bear Form
        { spell = 6795, type = "ability", requiresTarget = true, usable = true }, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true }, -- Moonfire
        { spell = 16979, type = "ability", requiresTarget = true, talent = 102401 }, -- Wild Charge
        { spell = 18562, type = "ability", usable = true, talent = 18562 }, -- Swiftmend
        { spell = 20484, type = "ability" }, -- Rebirth
        { spell = 22570, type = "ability", requiresTarget = true, talent = 22570 }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", charges = true, talent = 22842 }, -- Frenzied Regeneration
        { spell = 29166, type = "ability", buff = true, talent = 29166 }, -- Innervate
        { spell = 33786, type = "ability", requiresTarget = true, talent = 33786 }, -- Cyclone
        { spell = 33891, type = "ability", buff = true, talent = 33891 }, -- Incarnation: Tree of Life
        { spell = 33917, type = "ability", requiresTarget = true, usable = true, talent = 231064 }, -- Mangle
        { spell = 48438, type = "ability", buff = true, requiresTarget = true, talent = 48438 }, -- Wild Growth
        { spell = 49376, type = "ability", requiresTarget = true, talent = 102401 }, -- Wild Charge
        { spell = 77758, type = "ability", requiresTarget = true, talent = 106832 }, -- Thrash
        { spell = 77761, type = "ability", talent = 106898 }, -- Stampeding Roar
        { spell = 93402, type = "ability", requiresTarget = true, talent = 93402 }, -- Sunfire
        { spell = 102342, type = "ability", buff = true, talent = 102342 }, -- Ironbark
        { spell = 102351, type = "ability", buff = true, talent = 102351 }, -- Cenarion Ward
        { spell = 102359, type = "ability", requiresTarget = true, talent = 102359 }, -- Mass Entanglement
        { spell = 102401, type = "ability", buff = true, requiresTarget = true, talent = 102401 }, -- Wild Charge
        { spell = 102793, type = "ability", talent = 102793 }, -- Ursol's Vortex
        { spell = 106832, type = "ability", requiresTarget = true, talent = 106832 }, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true, talent = 106839 }, -- Skull Bash
        { spell = 108238, type = "ability", talent = 108238 }, -- Renewal
        { spell = 132158, type = "ability", buff = true, usable = true, talent = 132158 }, -- Nature's Swiftness
        { spell = 132469, type = "ability", talent = 132469 }, -- Typhoon
        { spell = 192081, type = "ability", buff = true, talent = 192081 }, -- Ironfur
        { spell = 194153, type = "ability", requiresTarget = true, talent = 194153 }, -- Starfire
        { spell = 197625, type = "ability", buff = true, talent = 197625 }, -- Moonkin Form
        { spell = 197626, type = "ability", requiresTarget = true, talent = 197626 }, -- Starsurge
        { spell = 197721, type = "ability", buff = true, talent = 197721 }, -- Flourish
        { spell = 203651, type = "ability", talent = 203651 }, -- Overgrowth
        { spell = 231064, type = "ability", requiresTarget = true, talent = 231064 }, -- Mangle
        { spell = 252216, type = "ability", buff = true, talent = 252216 }, -- Tiger Dash
        { spell = 319454, type = "ability", buff = true, talent = 319454 }, -- Heart of the Wild
        { spell = 391528, type = "ability", buff = true, talent = 391528, exactSpellId = true }, -- Convoke the Spirits
        { spell = 391888, type = "ability", requiresTarget = true, talent = 391888 }, -- Adaptive Swarm
        { spell = 392160, type = "ability", talent = 392160 }, -- Invigorate
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
        { spell = 305497, type = "buff", unit = "player", pvptalent = 3, titleSuffix = L["buff"] }, -- Thorns
        { spell = 305497, type = "ability", buff = true, pvptalent = 3, titleSuffix = L["cooldown"] }, -- Thorns
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 162264, type = "buff", unit = "player" }, -- Metamorphosis
        { spell = 188501, type = "buff", unit = "player" }, -- Spectral Sight
        { spell = 206804, type = "buff", unit = "player" }, -- Rain from Above
        { spell = 208628, type = "buff", unit = "player", talent = 206476 }, -- Momentum
        { spell = 209426, type = "buff", unit = "player", talent = 196718 }, -- Darkness
        { spell = 212800, type = "buff", unit = "player", talent = 198589 }, -- Blur
        { spell = 258920, type = "buff", unit = "player" }, -- Immolation Aura
        { spell = 343312, type = "buff", unit = "player", talent = 343311 }, -- Furious Gaze
        { spell = 347462, type = "buff", unit = "player", talent = 347461 }, -- Unbound Chaos
        { spell = 347765, type = "buff", unit = "player" }, -- Demon Soul
        { spell = 354610, type = "buff", unit = "player" }, -- Glimpse
        { spell = 358134, type = "buff", unit = "player" }, -- Star Burst
        { spell = 389890, type = "buff", unit = "player", talent = 389688 }, -- Tactical Retreat
        { spell = 390145, type = "buff", unit = "player", talent = 389693 }, -- Inner Demon
        { spell = 390195, type = "buff", unit = "player", talent = 389687 }, -- Chaos Theory
        { spell = 391215, type = "buff", unit = "player", talent = 388108 }, -- Initiative
        { spell = 391430, type = "buff", unit = "player", talent = 391429 }, -- Fodder to the Flame
        { spell = 393831, type = "buff", unit = "player", talent = 212084 }, -- Fel Devastation
      },
      icon = 1247266
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1490, type = "debuff", unit = "target" }, -- Chaos Brand
        { spell = 179057, type = "debuff", unit = "target", talent = 179057 }, -- Chaos Nova
        { spell = 185245, type = "debuff", unit = "target" }, -- Torment
        { spell = 198813, type = "debuff", unit = "target", talent = 198793 }, -- Vengeful Retreat
        { spell = 200166, type = "debuff", unit = "target" }, -- Metamorphosis
        { spell = 204598, type = "debuff", unit = "target", talent = 204596 }, -- Sigil of Flame
        { spell = 207685, type = "debuff", unit = "target", talent = 207684 }, -- Sigil of Misery
        { spell = 211881, type = "debuff", unit = "target", talent = 211881 }, -- Fel Eruption
        { spell = 213405, type = "debuff", unit = "target", talent = 389763 }, -- Master of the Glaive
        { spell = 258883, type = "debuff", unit = "target", talent = 258881 }, -- Trail of Ruin
        { spell = 320338, type = "debuff", unit = "target", talent = 258860 }, -- Essence Break
        { spell = 370966, type = "debuff", unit = "target", talent = 370965 }, -- The Hunt
        { spell = 390155, type = "debuff", unit = "target", talent = 390154 }, -- Serrated Glaive
        { spell = 390181, type = "debuff", unit = "target", talent = 388106 }, -- Soulrend
      },
      icon = 1392554
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 131347, type = "ability" }, -- Glide
        { spell = 162243, type = "ability", requiresTarget = true, usable = true }, -- Demon's Bite
        { spell = 162794, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Chaos Strike
        { spell = 179057, type = "ability", usable = true, talent = 179057 }, -- Chaos Nova
        { spell = 183752, type = "ability", requiresTarget = true, usable = true, talent = 320361 }, -- Disrupt
        { spell = 185123, type = "ability", charges = true, requiresTarget = true, usable = true }, -- Throw Glaive
        { spell = 185245, type = "ability", requiresTarget = true, usable = true }, -- Torment
        { spell = 188499, type = "ability", usable = true }, -- Blade Dance
        { spell = 188501, type = "ability", buff = true, usable = true }, -- Spectral Sight
        { spell = 191427, type = "ability", usable = true }, -- Metamorphosis
        { spell = 195072, type = "ability", charges = true, overlayGlow = true, usable = true }, -- Fel Rush
        { spell = 196718, type = "ability", usable = true, talent = 196718 }, -- Darkness
        { spell = 198013, type = "ability", usable = true, talent = 198013 }, -- Eye Beam
        { spell = 198589, type = "ability", usable = true, talent = 198589 }, -- Blur
        { spell = 198793, type = "ability", usable = true, talent = 198793 }, -- Vengeful Retreat
        { spell = 203720, type = "ability", charges = true }, -- Demon Spikes
        { spell = 204596, type = "ability", usable = true, talent = 204596 }, -- Sigil of Flame
        { spell = 207684, type = "ability", usable = true, talent = 207684 }, -- Sigil of Misery
        { spell = 210152, type = "ability" }, -- Death Sweep
        { spell = 211881, type = "ability", requiresTarget = true, usable = true, talent = 211881 }, -- Fel Eruption
        { spell = 217832, type = "ability", usable = true, talent = 217832 }, -- Imprison
        { spell = 232893, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 232893 }, -- Felblade
        { spell = 258860, type = "ability", talent = 258860 }, -- Essence Break
        { spell = 258920, type = "ability", buff = true, usable = true }, -- Immolation Aura
        { spell = 258925, type = "ability", usable = true, talent = 258925 }, -- Fel Barrage
        { spell = 278326, type = "ability", requiresTarget = true, usable = true, talent = 278326 }, -- Consume Magic
        { spell = 342817, type = "ability", usable = true, talent = 342817 }, -- Glaive Tempest
        { spell = 344865, type = "ability", charges = true, overlayGlow = true }, -- Fel Rush
        { spell = 370965, type = "ability", requiresTarget = true, usable = true, talent = 370965 }, -- The Hunt
        { spell = 390163, type = "ability", usable = true, talent = 390163 }, -- Elysian Decree
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
        { spell = 206803, type = "buff", unit = "player", pvptalent = 8, titleSuffix = L["buff"] }, -- Rain from Above
        { spell = 205604, type = "ability", usable = true, pvptalent = 5, titleSuffix = L["cooldown"] }, -- Reverse Magic
        { spell = 206803, type = "ability", buff = true, usable = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Rain from Above
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 187827, type = "buff", unit = "player" }, -- Metamorphosis
        { spell = 188501, type = "buff", unit = "player" }, -- Spectral Sight
        { spell = 203819, type = "buff", unit = "player" }, -- Demon Spikes
        { spell = 203981, type = "buff", unit = "player" }, -- Soul Fragments
        { spell = 209426, type = "buff", unit = "player", talent = 196718 }, -- Darkness
        { spell = 258920, type = "buff", unit = "player" }, -- Immolation Aura
        { spell = 263648, type = "buff", unit = "player", talent = 263648 }, -- Soul Barrier
        { spell = 358134, type = "buff", unit = "player" }, -- Star Burst
        { spell = 389847, type = "buff", unit = "player", talent = 389846 }, -- Felfire Haste
        { spell = 391166, type = "buff", unit = "player", talent = 391165 }, -- Soul Furnace
        { spell = 391171, type = "buff", unit = "player", talent = 389720 }, -- Calcified Spikes
        { spell = 393009, type = "buff", unit = "player", talent = 389705 }, -- Fel Flame Fortification
      },
      icon = 1247263
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1490, type = "debuff", unit = "target" }, -- Chaos Brand
        { spell = 179057, type = "debuff", unit = "target", talent = 179057 }, -- Chaos Nova
        { spell = 185245, type = "debuff", unit = "target" }, -- Torment
        { spell = 198813, type = "debuff", unit = "target", talent = 198793 }, -- Vengeful Retreat
        { spell = 204490, type = "debuff", unit = "target", talent = 202137 }, -- Sigil of Silence
        { spell = 204598, type = "debuff", unit = "target", talent = 204596 }, -- Sigil of Flame
        { spell = 204843, type = "debuff", unit = "target", talent = 202138 }, -- Sigil of Chains
        { spell = 206891, type = "debuff", unit = "target" }, -- Focused Assault
        { spell = 207407, type = "debuff", unit = "target", talent = 207407 }, -- Soul Carver
        { spell = 207771, type = "debuff", unit = "target", talent = 204021 }, -- Fiery Brand
        { spell = 213491, type = "debuff", unit = "target" }, -- Demonic Trample
        { spell = 247456, type = "debuff", unit = "target", talent = 389958 }, -- Frailty
        { spell = 289212, type = "debuff", unit = "target" }, -- Trampled
        { spell = 370966, type = "debuff", unit = "target", talent = 370965 }, -- The Hunt
      },
      icon = 1344647
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 131347, type = "ability" }, -- Glide
        { spell = 179057, type = "ability", talent = 179057 }, -- Chaos Nova
        { spell = 183752, type = "ability", requiresTarget = true, talent = 320361 }, -- Disrupt
        { spell = 185245, type = "ability", requiresTarget = true }, -- Torment
        { spell = 187827, type = "ability", buff = true }, -- Metamorphosis
        { spell = 188501, type = "ability", buff = true }, -- Spectral Sight
        { spell = 189110, type = "ability", charges = true }, -- Infernal Strike
        { spell = 196718, type = "ability", talent = 196718 }, -- Darkness
        { spell = 198793, type = "ability", talent = 198793 }, -- Vengeful Retreat
        { spell = 202137, type = "ability", talent = 202137 }, -- Sigil of Silence
        { spell = 202140, type = "ability", talent = 207684 }, -- Sigil of Misery
        { spell = 203720, type = "ability", charges = true }, -- Demon Spikes
        { spell = 203782, type = "ability", requiresTarget = true }, -- Shear
        { spell = 204021, type = "ability", charges = true, requiresTarget = true, talent = 204021 }, -- Fiery Brand
        { spell = 204157, type = "ability", charges = true, requiresTarget = true }, -- Throw Glaive
        { spell = 204513, type = "ability", talent = 204596 }, -- Sigil of Flame
        { spell = 204596, type = "ability", talent = 204596 }, -- Sigil of Flame
        { spell = 207407, type = "ability", requiresTarget = true, talent = 207407 }, -- Soul Carver
        { spell = 207665, type = "ability", talent = 202138 }, -- Sigil of Chains
        { spell = 212084, type = "ability", talent = 212084 }, -- Fel Devastation
        { spell = 217832, type = "ability", talent = 217832 }, -- Imprison
        { spell = 228477, type = "ability", charges = true, requiresTarget = true }, -- Soul Cleave
        { spell = 232893, type = "ability", overlayGlow = true, requiresTarget = true, talent = 232893 }, -- Felblade
        { spell = 247454, type = "ability", charges = true, usable = true, talent = 247454 }, -- Spirit Bomb
        { spell = 258920, type = "ability", buff = true }, -- Immolation Aura
        { spell = 263642, type = "ability", charges = true, requiresTarget = true, talent = 263642 }, -- Fracture
        { spell = 263648, type = "ability", charges = true, buff = true, talent = 263648 }, -- Soul Barrier
        { spell = 278326, type = "ability", requiresTarget = true, talent = 278326 }, -- Consume Magic
        { spell = 370965, type = "ability", requiresTarget = true, talent = 370965 }, -- The Hunt
        { spell = 390163, type = "ability", talent = 390163 }, -- Elysian Decree
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
        { spell = 205629, type = "buff", unit = "player", pvptalent = 6, titleSuffix = L["buff"] }, -- Demonic Trample
        { spell = 205630, type = "buff", unit = "player", pvptalent = 14, titleSuffix = L["buff"] }, -- Illidan's Grasp
        { spell = 205630, type = "debuff", unit = "target", pvptalent = 14, titleSuffix = L["debuff"] }, -- Illidan's Grasp
        { spell = 205604, type = "ability", pvptalent = 5, titleSuffix = L["cooldown"] }, -- Reverse Magic
        { spell = 205629, type = "ability", charges = true, buff = true, pvptalent = 6, titleSuffix = L["cooldown"] }, -- Demonic Trample
        { spell = 205630, type = "ability", buff = true, overlayGlow = true, requiresTarget = true, pvptalent = 14, titleSuffix = L["cooldown"] }, -- Illidan's Grasp
        { spell = 206803, type = "ability", pvptalent = 8, titleSuffix = L["cooldown"] }, -- Rain from Above
        { spell = 207029, type = "ability", requiresTarget = true, pvptalent = 15, titleSuffix = L["cooldown"] }, -- Tormentor
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
    },
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = 1247265,
    }
  },
}

templates.class.DEATHKNIGHT = {
  [1] = { -- Blood
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 3714, type = "buff", unit = "player" }, -- Path of Frost
        { spell = 47568, type = "buff", unit = "player", talent = 47568 }, -- Empower Rune Weapon
        { spell = 48265, type = "buff", unit = "player" }, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player", talent = 48707 }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player", talent = 48792 }, -- Icebound Fortitude
        { spell = 49039, type = "buff", unit = "player" }, -- Lichborne
        { spell = 55233, type = "buff", unit = "player", talent = 55233 }, -- Vampiric Blood
        { spell = 77535, type = "buff", unit = "player" }, -- Blood Shield
        { spell = 81141, type = "buff", unit = "player", talent = 81136 }, -- Crimson Scourge
        { spell = 81256, type = "buff", unit = "player", talent = 49028 }, -- Dancing Rune Weapon
        { spell = 145629, type = "buff", unit = "player", talent = 51052 }, -- Anti-Magic Zone
        { spell = 188290, type = "buff", unit = "player" }, -- Death and Decay
        { spell = 194679, type = "buff", unit = "player", talent = 194679 }, -- Rune Tap
        { spell = 194844, type = "buff", unit = "player", talent = 194844 }, -- Bonestorm
        { spell = 194879, type = "buff", unit = "player", talent = 194878 }, -- Icy Talons
        { spell = 195181, type = "buff", unit = "player" }, -- Bone Shield
        { spell = 212552, type = "buff", unit = "player", talent = 212552 }, -- Wraith Walk
        { spell = 219788, type = "buff", unit = "player", talent = 219786 }, -- Ossuary
        { spell = 219809, type = "buff", unit = "player", talent = 219809 }, -- Tombstone
        { spell = 228581, type = "buff", unit = "player" }, -- Decomposing Aura
        { spell = 228583, type = "buff", unit = "player" }, -- Necrotic Aura
        { spell = 253595, type = "buff", unit = "player", talent = 253593 }, -- Inexorable Assault
        { spell = 273947, type = "buff", unit = "player", talent = 273946 }, -- Hemostasis
        { spell = 274009, type = "buff", unit = "player", talent = 273953 }, -- Voracious
        { spell = 374271, type = "buff", unit = "player", talent = 374265 }, -- Unholy Ground
        { spell = 374585, type = "buff", unit = "player", talent = 374574 }, -- Rune Mastery
        { spell = 374748, type = "buff", unit = "player", talent = 374747 }, -- Perseverance of the Ebon Blade
        { spell = 377656, type = "buff", unit = "player", talent = 377655 }, -- Heartrend
        { spell = 383269, type = "buff", unit = "player", talent = 383269 }, -- Abomination Limb
        { spell = 391459, type = "buff", unit = "player", talent = 391458 }, -- Sanguine Ground
        { spell = 391481, type = "buff", unit = "player", talent = 391477 }, -- Coagulopathy
        { spell = 391519, type = "buff", unit = "player", talent = 391517 }, -- Umbilicus Eternus
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target", talent = 45524 }, -- Chains of Ice
        { spell = 51399, type = "debuff", unit = "target" }, -- Death Grip
        { spell = 55078, type = "debuff", unit = "target" }, -- Blood Plague
        { spell = 56222, type = "debuff", unit = "target" }, -- Dark Command
        { spell = 91800, type = "debuff", unit = "target" }, -- Gnaw
        { spell = 199721, type = "debuff", unit = "target" }, -- Decomposing Aura
        { spell = 206891, type = "debuff", unit = "target" }, -- Focused Assault
        { spell = 206930, type = "debuff", unit = "target", talent = 206930 }, -- Heart Strike
        { spell = 206931, type = "debuff", unit = "target", talent = 206931 }, -- Blooddrinker
        { spell = 206940, type = "debuff", unit = "target", talent = 206940 }, -- Mark of Blood
        { spell = 214968, type = "debuff", unit = "target" }, -- Necrotic Aura
        { spell = 221562, type = "debuff", unit = "target", talent = 221562 }, -- Asphyxiate
        { spell = 343294, type = "debuff", unit = "target", talent = 343294 }, -- Soul Reaper
        { spell = 374557, type = "debuff", unit = "target", talent = 374504 }, -- Brittle
        { spell = 374776, type = "debuff", unit = "target", talent = 206970 }, -- Tightening Grasp
        { spell = 389681, type = "debuff", unit = "target", talent = 389679 }, -- Clenching Grasp
        { spell = 392490, type = "debuff", unit = "target", talent = 392566 }, -- Enfeeble
      },
      icon = 237514
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 43265, type = "ability", charges = true, overlayGlow = true }, -- Death and Decay
        { spell = 45524, type = "ability", requiresTarget = true, talent = 45524 }, -- Chains of Ice
        { spell = 46585, type = "ability", totem = true, talent = 46585 }, -- Raise Dead
        { spell = 47528, type = "ability", requiresTarget = true, talent = 47528 }, -- Mind Freeze
        { spell = 47541, type = "ability", requiresTarget = true }, -- Death Coil
        { spell = 47568, type = "ability", buff = true, talent = 47568 }, -- Empower Rune Weapon
        { spell = 48265, type = "ability", charges = true, buff = true }, -- Death's Advance
        { spell = 48707, type = "ability", buff = true, talent = 48707 }, -- Anti-Magic Shell
        { spell = 48743, type = "ability", talent = 48743 }, -- Death Pact
        { spell = 48792, type = "ability", buff = true, talent = 48792 }, -- Icebound Fortitude
        { spell = 49028, type = "ability", requiresTarget = true, talent = 49028 }, -- Dancing Rune Weapon
        { spell = 49039, type = "ability", buff = true }, -- Lichborne
        { spell = 49576, type = "ability", charges = true, requiresTarget = true }, -- Death Grip
        { spell = 49998, type = "ability", requiresTarget = true, talent = 49998 }, -- Death Strike
        { spell = 50842, type = "ability", charges = true, talent = 50842 }, -- Blood Boil
        { spell = 50977, type = "ability", usable = true }, -- Death Gate
        { spell = 51052, type = "ability", talent = 51052 }, -- Anti-Magic Zone
        { spell = 55233, type = "ability", buff = true, talent = 55233 }, -- Vampiric Blood
        { spell = 56222, type = "ability", requiresTarget = true }, -- Dark Command
        { spell = 61999, type = "ability" }, -- Raise Ally
        { spell = 108199, type = "ability", requiresTarget = true, talent = 108199 }, -- Gorefiend's Grasp
        { spell = 194679, type = "ability", charges = true, buff = true, talent = 194679 }, -- Rune Tap
        { spell = 194844, type = "ability", buff = true, talent = 194844 }, -- Bonestorm
        { spell = 195182, type = "ability", charges = true, requiresTarget = true, talent = 195182 }, -- Marrowrend
        { spell = 195292, type = "ability", requiresTarget = true, talent = 195292 }, -- Death's Caress
        { spell = 206930, type = "ability", requiresTarget = true, talent = 206930 }, -- Heart Strike
        { spell = 206931, type = "ability", requiresTarget = true, talent = 206931 }, -- Blooddrinker
        { spell = 206940, type = "ability", requiresTarget = true, talent = 206940 }, -- Mark of Blood
        { spell = 207167, type = "ability", talent = 207167 }, -- Blinding Sleet
        { spell = 212552, type = "ability", buff = true, talent = 212552 }, -- Wraith Walk
        { spell = 219809, type = "ability", buff = true, usable = true, talent = 219809 }, -- Tombstone
        { spell = 221562, type = "ability", requiresTarget = true, talent = 221562 }, -- Asphyxiate
        { spell = 221699, type = "ability", charges = true, talent = 221699 }, -- Blood Tap
        { spell = 274156, type = "ability", talent = 274156 }, -- Consumption
        { spell = 327574, type = "ability", talent = 327574 }, -- Sacrificial Pact
        { spell = 343294, type = "ability", requiresTarget = true, talent = 343294 }, -- Soul Reaper
        { spell = 383269, type = "ability", buff = true, talent = 383269 }, -- Abomination Limb
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
        { spell = 47476, type = "debuff", unit = "target", pvptalent = 11, titleSuffix = L["debuff"] }, -- Strangulate
        { spell = 203173, type = "debuff", unit = "target", pvptalent = 8, titleSuffix = L["debuff"] }, -- Death Chain
        { spell = 47476, type = "ability", requiresTarget = true, pvptalent = 11, titleSuffix = L["cooldown"] }, -- Strangulate
        { spell = 203173, type = "ability", requiresTarget = true, pvptalent = 8, titleSuffix = L["cooldown"] }, -- Death Chain
        { spell = 207018, type = "ability", requiresTarget = true, pvptalent = 5, titleSuffix = L["cooldown"] }, -- Murderous Intent
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 3714, type = "buff", unit = "player" }, -- Path of Frost
        { spell = 47568, type = "buff", unit = "player", talent = 47568 }, -- Empower Rune Weapon
        { spell = 48265, type = "buff", unit = "player" }, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player", talent = 48707 }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player", talent = 48792 }, -- Icebound Fortitude
        { spell = 49039, type = "buff", unit = "player" }, -- Lichborne
        { spell = 51124, type = "buff", unit = "player", talent = 51128 }, -- Killing Machine
        { spell = 51271, type = "buff", unit = "player", talent = 51271 }, -- Pillar of Frost
        { spell = 59052, type = "buff", unit = "player", talent = 59057 }, -- Rime
        { spell = 145629, type = "buff", unit = "player", talent = 51052 }, -- Anti-Magic Zone
        { spell = 152279, type = "buff", unit = "player", talent = 152279 }, -- Breath of Sindragosa
        { spell = 188290, type = "buff", unit = "player" }, -- Death and Decay
        { spell = 194879, type = "buff", unit = "player", talent = 194878 }, -- Icy Talons
        { spell = 196770, type = "buff", unit = "player", talent = 196770 }, -- Remorseless Winter
        { spell = 207203, type = "buff", unit = "player" }, -- Frost Shield
        { spell = 211805, type = "buff", unit = "player", talent = 194912 }, -- Gathering Storm
        { spell = 212552, type = "buff", unit = "player", talent = 212552 }, -- Wraith Walk
        { spell = 228579, type = "buff", unit = "player" }, -- Shroud of Winter
        { spell = 253595, type = "buff", unit = "player", talent = 253593 }, -- Inexorable Assault
        { spell = 281209, type = "buff", unit = "player", talent = 281208 }, -- Cold Heart
        { spell = 358134, type = "buff", unit = "player" }, -- Star Burst
        { spell = 374271, type = "buff", unit = "player", talent = 374265 }, -- Unholy Ground
        { spell = 374585, type = "buff", unit = "player", talent = 374574 }, -- Rune Mastery
        { spell = 376907, type = "buff", unit = "player", talent = 376905 }, -- Unleashed Frenzy
        { spell = 377101, type = "buff", unit = "player", talent = 377098 }, -- Bonegrinder
        { spell = 377192, type = "buff", unit = "player", talent = 377190 }, -- Enduring Strength
        { spell = 383269, type = "buff", unit = "player", talent = 383269 }, -- Abomination Limb
      },
      icon = 135305
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target", talent = 45524 }, -- Chains of Ice
        { spell = 51714, type = "debuff", unit = "target" }, -- Razorice
        { spell = 55095, type = "debuff", unit = "target" }, -- Frost Fever
        { spell = 56222, type = "debuff", unit = "target" }, -- Dark Command
        { spell = 91800, type = "debuff", unit = "target" }, -- Gnaw
        { spell = 204085, type = "debuff", unit = "target" }, -- Deathchill
        { spell = 204206, type = "debuff", unit = "target" }, -- Chilled
        { spell = 207167, type = "debuff", unit = "target", talent = 207167 }, -- Blinding Sleet
        { spell = 211793, type = "debuff", unit = "target", talent = 196770 }, -- Remorseless Winter
        { spell = 221562, type = "debuff", unit = "target", talent = 221562 }, -- Asphyxiate
        { spell = 273977, type = "debuff", unit = "target", talent = 273952 }, -- Grip of the Dead
        { spell = 279303, type = "debuff", unit = "target", talent = 279302 }, -- Frostwyrm's Fury
        { spell = 343294, type = "debuff", unit = "target", talent = 343294 }, -- Soul Reaper
        { spell = 374557, type = "debuff", unit = "target", talent = 374504 }, -- Brittle
        { spell = 376974, type = "debuff", unit = "target", talent = 376938 }, -- Everfrost
        { spell = 377048, type = "debuff", unit = "target", talent = 377047 }, -- Absolute Zero
        { spell = 391568, type = "debuff", unit = "target", talent = 391566 }, -- Insidious Chill
      },
      icon = 237522
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability", buff = true }, -- Path of Frost
        { spell = 43265, type = "ability" }, -- Death and Decay
        { spell = 45524, type = "ability", overlayGlow = true, requiresTarget = true, talent = 45524 }, -- Chains of Ice
        { spell = 46585, type = "ability", totem = true, talent = 46585 }, -- Raise Dead
        { spell = 47528, type = "ability", requiresTarget = true, talent = 47528 }, -- Mind Freeze
        { spell = 47541, type = "ability", requiresTarget = true }, -- Death Coil
        { spell = 47568, type = "ability", buff = true, talent = 47568 }, -- Empower Rune Weapon
        { spell = 48265, type = "ability", buff = true }, -- Death's Advance
        { spell = 48707, type = "ability", buff = true, talent = 48707 }, -- Anti-Magic Shell
        { spell = 48743, type = "ability", talent = 48743 }, -- Death Pact
        { spell = 48792, type = "ability", buff = true, talent = 48792 }, -- Icebound Fortitude
        { spell = 49020, type = "ability", overlayGlow = true, requiresTarget = true, talent = 49020 }, -- Obliterate
        { spell = 49039, type = "ability", buff = true }, -- Lichborne
        { spell = 49143, type = "ability", requiresTarget = true, talent = 49143 }, -- Frost Strike
        { spell = 49184, type = "ability", overlayGlow = true, requiresTarget = true, talent = 49184 }, -- Howling Blast
        { spell = 49576, type = "ability", requiresTarget = true }, -- Death Grip
        { spell = 49998, type = "ability", requiresTarget = true, talent = 49998 }, -- Death Strike
        { spell = 50977, type = "ability", usable = true }, -- Death Gate
        { spell = 51052, type = "ability", talent = 51052 }, -- Anti-Magic Zone
        { spell = 51271, type = "ability", buff = true, talent = 51271 }, -- Pillar of Frost
        { spell = 56222, type = "ability", requiresTarget = true }, -- Dark Command
        { spell = 57330, type = "ability", talent = 57330 }, -- Horn of Winter
        { spell = 61999, type = "ability" }, -- Raise Ally
        { spell = 152279, type = "ability", buff = true, talent = 152279 }, -- Breath of Sindragosa
        { spell = 196770, type = "ability", buff = true, talent = 196770 }, -- Remorseless Winter
        { spell = 207167, type = "ability", talent = 207167 }, -- Blinding Sleet
        { spell = 212552, type = "ability", buff = true, talent = 212552 }, -- Wraith Walk
        { spell = 221562, type = "ability", requiresTarget = true, talent = 221562 }, -- Asphyxiate
        { spell = 279302, type = "ability", talent = 279302 }, -- Frostwyrm's Fury
        { spell = 305392, type = "ability", requiresTarget = true, talent = 305392 }, -- Chill Streak
        { spell = 327574, type = "ability", talent = 327574 }, -- Sacrificial Pact
        { spell = 343294, type = "ability", requiresTarget = true, talent = 343294 }, -- Soul Reaper
        { spell = 383269, type = "ability", buff = true, talent = 383269 }, -- Abomination Limb
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
        { spell = 47476, type = "debuff", unit = "target", pvptalent = 1, titleSuffix = L["debuff"] }, -- Strangulate
        { spell = 47476, type = "ability", requiresTarget = true, pvptalent = 1, titleSuffix = L["cooldown"] }, -- Strangulate
        { spell = 77606, type = "ability", requiresTarget = true, pvptalent = 9, titleSuffix = L["cooldown"] }, -- Dark Simulacrum
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
        { spell = 3714, type = "buff", unit = "player" }, -- Path of Frost
        { spell = 42650, type = "buff", unit = "player", talent = 42650 }, -- Army of the Dead
        { spell = 47568, type = "buff", unit = "player", talent = 47568 }, -- Empower Rune Weapon
        { spell = 48265, type = "buff", unit = "player" }, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player", talent = 48707 }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player", talent = 48792 }, -- Icebound Fortitude
        { spell = 49039, type = "buff", unit = "player" }, -- Lichborne
        { spell = 51460, type = "buff", unit = "player" }, -- Runic Corruption
        { spell = 81340, type = "buff", unit = "player", talent = 49530 }, -- Sudden Doom
        { spell = 115989, type = "buff", unit = "player", talent = 115989 }, -- Unholy Blight
        { spell = 145629, type = "buff", unit = "player", talent = 51052 }, -- Anti-Magic Zone
        { spell = 188290, type = "buff", unit = "player" }, -- Death and Decay
        { spell = 194879, type = "buff", unit = "player", talent = 194878 }, -- Icy Talons
        { spell = 207203, type = "buff", unit = "player" }, -- Frost Shield
        { spell = 207289, type = "buff", unit = "player", talent = 207289 }, -- Unholy Assault
        { spell = 212552, type = "buff", unit = "player", talent = 212552 }, -- Wraith Walk
        { spell = 228583, type = "buff", unit = "player" }, -- Necrotic Aura
        { spell = 253595, type = "buff", unit = "player", talent = 253593 }, -- Inexorable Assault
        { spell = 374271, type = "buff", unit = "player", talent = 374265 }, -- Unholy Ground
        { spell = 374585, type = "buff", unit = "player", talent = 374574 }, -- Rune Mastery
        { spell = 377588, type = "buff", unit = "player", talent = 377587 }, -- Ghoulish Frenzy
        { spell = 377591, type = "buff", unit = "player", talent = 377590 }, -- Festermight
        { spell = 383269, type = "buff", unit = "player", talent = 383269 }, -- Abomination Limb
        { spell = 390178, type = "buff", unit = "player", talent = 390175 }, -- Plaguebringer
        { spell = 63560, type = "buff", unit = "pet", talent = 63560 }, -- Dark Transformation
        { spell = 91838, type = "buff", unit = "pet" }, -- Huddle
      },
      icon = 136181
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target", talent = 45524 }, -- Chains of Ice
        { spell = 55078, type = "debuff", unit = "target" }, -- Blood Plague
        { spell = 55095, type = "debuff", unit = "target" }, -- Frost Fever
        { spell = 56222, type = "debuff", unit = "target" }, -- Dark Command
        { spell = 91800, type = "debuff", unit = "target" }, -- Gnaw
        { spell = 115994, type = "debuff", unit = "target", talent = 115989 }, -- Unholy Blight
        { spell = 191587, type = "debuff", unit = "target" }, -- Virulent Plague
        { spell = 194310, type = "debuff", unit = "target" }, -- Festering Wound
        { spell = 207167, type = "debuff", unit = "target", talent = 207167 }, -- Blinding Sleet
        { spell = 210141, type = "debuff", unit = "target" }, -- Zombie Explosion
        { spell = 214968, type = "debuff", unit = "target" }, -- Necrotic Aura
        { spell = 221562, type = "debuff", unit = "target", talent = 221562 }, -- Asphyxiate
        { spell = 273977, type = "debuff", unit = "target", talent = 273952 }, -- Grip of the Dead
        { spell = 317792, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 343294, type = "debuff", unit = "target", talent = 343294 }, -- Soul Reaper
        { spell = 374557, type = "debuff", unit = "target", talent = 374504 }, -- Brittle
        { spell = 377445, type = "debuff", unit = "target", talent = 377440 }, -- Unholy Aura
        { spell = 377540, type = "debuff", unit = "target", talent = 377537 }, -- Death Rot
        { spell = 389681, type = "debuff", unit = "target", talent = 389679 }, -- Clenching Grasp
        { spell = 390271, type = "debuff", unit = "target", talent = 390270 }, -- Coil of Devastation
        { spell = 390276, type = "debuff", unit = "target", talent = 390275 }, -- Rotten Touch
        { spell = 391568, type = "debuff", unit = "target", talent = 391566 }, -- Insidious Chill
        { spell = 392490, type = "debuff", unit = "target", talent = 392566 }, -- Enfeeble
      },
      icon = 1129420
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability", buff = true }, -- Path of Frost
        { spell = 42650, type = "ability", buff = true, talent = 42650 }, -- Army of the Dead
        { spell = 43265, type = "ability", charges = true }, -- Death and Decay
        { spell = 45524, type = "ability", requiresTarget = true, talent = 45524 }, -- Chains of Ice
        { spell = 46584, type = "ability", talent = 46584 }, -- Raise Dead
        { spell = 46585, type = "ability", totem = true, talent = 46585 }, -- Raise Dead
        { spell = 47468, type = "ability" }, -- Claw
        { spell = 47481, type = "ability" }, -- Gnaw
        { spell = 47484, type = "ability" }, -- Huddle
        { spell = 47528, type = "ability", requiresTarget = true, talent = 47528 }, -- Mind Freeze
        { spell = 47541, type = "ability", overlayGlow = true, requiresTarget = true }, -- Death Coil
        { spell = 47568, type = "ability", buff = true, talent = 47568 }, -- Empower Rune Weapon
        { spell = 48265, type = "ability", charges = true, buff = true }, -- Death's Advance
        { spell = 48707, type = "ability", buff = true, talent = 48707 }, -- Anti-Magic Shell
        { spell = 48743, type = "ability", talent = 48743 }, -- Death Pact
        { spell = 48792, type = "ability", buff = true, talent = 48792 }, -- Icebound Fortitude
        { spell = 49039, type = "ability", buff = true }, -- Lichborne
        { spell = 49206, type = "ability", requiresTarget = true, totem = true, talent = 49206 }, -- Summon Gargoyle
        { spell = 49576, type = "ability", charges = true, requiresTarget = true }, -- Death Grip
        { spell = 49998, type = "ability", requiresTarget = true, talent = 49998 }, -- Death Strike
        { spell = 50977, type = "ability", usable = true }, -- Death Gate
        { spell = 51052, type = "ability", talent = 51052 }, -- Anti-Magic Zone
        { spell = 55090, type = "ability", requiresTarget = true, talent = 55090 }, -- Scourge Strike
        { spell = 56222, type = "ability", requiresTarget = true }, -- Dark Command
        { spell = 61999, type = "ability" }, -- Raise Ally
        { spell = 63560, type = "ability", buff = true, unit = 'pet', talent = 63560 }, -- Dark Transformation
        { spell = 77575, type = "ability", requiresTarget = true, talent = 77575 }, -- Outbreak
        { spell = 85948, type = "ability", requiresTarget = true, talent = 85948 }, -- Festering Strike
        { spell = 111673, type = "ability", talent = 111673 }, -- Control Undead
        { spell = 115989, type = "ability", buff = true, talent = 115989 }, -- Unholy Blight
        { spell = 207167, type = "ability", talent = 207167 }, -- Blinding Sleet
        { spell = 207289, type = "ability", buff = true, requiresTarget = true, talent = 207289 }, -- Unholy Assault
        { spell = 207311, type = "ability", requiresTarget = true, talent = 207311 }, -- Clawing Shadows
        { spell = 212552, type = "ability", buff = true, talent = 212552 }, -- Wraith Walk
        { spell = 221562, type = "ability", requiresTarget = true, talent = 221562 }, -- Asphyxiate
        { spell = 275699, type = "ability", requiresTarget = true, usable = true, talent = 275699 }, -- Apocalypse
        { spell = 327574, type = "ability", talent = 327574 }, -- Sacrificial Pact
        { spell = 343294, type = "ability", requiresTarget = true, talent = 343294 }, -- Soul Reaper
        { spell = 383269, type = "ability", buff = true, talent = 383269 }, -- Abomination Limb
        { spell = 390279, type = "ability", requiresTarget = true, talent = 390279 }, -- Vile Contagion
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
        { spell = 47476, type = "debuff", unit = "target", pvptalent = 4, titleSuffix = L["debuff"] }, -- Strangulate
        { spell = 47476, type = "ability", pvptalent = 4, titleSuffix = L["cooldown"] }, -- Strangulate
        { spell = 288853, type = "ability", totem = true, pvptalent = 2, titleSuffix = L["cooldown"] }, -- Raise Abomination
      },
      icon = "Interface/Icons/Achievement_BG_winWSG",
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
-- tinsert(templates.class.DRUID[4][3].args,  {spell = 145205, type = "totem"});

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

-- Evoker
tinsert(templates.class.EVOKER[1][resourceSection].args, createSimplePowerTemplate(19)); -- Essence
tinsert(templates.class.EVOKER[1][resourceSection].args, createSimplePowerTemplate(0)); -- Mana
tinsert(templates.class.EVOKER[2][resourceSection].args, createSimplePowerTemplate(19)); -- Essence
tinsert(templates.class.EVOKER[2][resourceSection].args, createSimplePowerTemplate(0)); -- Mana

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
-- Combat Analysis
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
    item.load = item.load or {}
    item.load.use_talent = false
    item.load.talent = { multi = {} }
    if type(item.talent) == "table" then
      for _,v in pairs(item.talent) do
        if v > 0 then
          item.load.talent.multi[v] = true
        else
          item.load.talent.multi[-v] = false
        end
      end
    else
      item.load.talent.multi[item.talent] = true
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
        local loadCondition
        if WeakAuras.IsRetail() then
          local specializationId
          for classID = 1, GetNumClasses() do
            local _, classFile = GetClassInfo(classID)
            if classFile == className then
              specializationId = GetSpecializationInfoForClassID(classID, specIndex)
              break
            end
          end
          loadCondition = {
            use_class_and_spec = true, class_and_spec = { single = specializationId, multi = {} },
          }
        else
          loadCondition = {
            use_class = true, class = { single = className, multi = {} },
            use_spec = true, spec = { single = specIndex, multi = {}}
          };
        end
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

TemplatePrivate.triggerTemplates = templates
