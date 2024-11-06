local AddonName, TemplatePrivate = ...
---@class WeakAuras
local WeakAuras = WeakAuras
if not WeakAuras.IsRetail() then return end
local L = WeakAuras.L
local tinsert, C_Timer, Spell = tinsert, C_Timer, Spell

local GetSpellInfo, GetSpellIcon, GetSpellDescription = GetSpellInfo, GetSpellTexture, GetSpellDescription
-- TWW Compatibility, we don't use functions from Compatibility.lua because TemplatePrivate.Private isn't set yet
if GetSpellInfo == nil then
  GetSpellInfo = function(spellID)
    if not spellID then
      return nil
    end
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
      return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
    end
  end
  GetSpellIcon = C_Spell.GetSpellTexture
  GetSpellDescription = C_Spell.GetSpellDescription
end

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
      Dracthyr = {},
      EarthenDwarf = {},
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
        { spell = 357210, type = "buff", unit = "player" }, -- Deep Breath
        { spell = 358267, type = "buff", unit = "player" }, -- Hover
        { spell = 359618, type = "buff", unit = "player", talent = 115520 }, -- Essence Burst
        { spell = 363916, type = "buff", unit = "player", talent = 115613 }, -- Obsidian Scales
        { spell = 370454, type = "buff", unit = "player", talent = 115628 }, -- Charged Blast
        { spell = 370553, type = "buff", unit = "player", talent = 115665 }, -- Tip the Scales
        { spell = 370818, type = "buff", unit = "player", talent = 115584 }, -- Snapfire
        { spell = 370901, type = "buff", unit = "player", talent = 115657 }, -- Leaping Flames
        { spell = 374227, type = "buff", unit = "player", talent = 115661 }, -- Zephyr
        { spell = 374348, type = "buff", unit = "player", talent = 115669 }, -- Renewing Blaze
        { spell = 375087, type = "buff", unit = "player", talent = 115643 }, -- Dragonrage
        { spell = 375234, type = "buff", unit = "player", talent = 115666 }, -- Time Spiral
        { spell = 375583, type = "buff", unit = "player", talent = 115577 }, -- Ancient Flame
        { spell = 375802, type = "buff", unit = "player", talent = 115624 }, -- Burnout
        { spell = 376850, type = "buff", unit = "player", talent = 115634 }, -- Power Swell
        { spell = 381748, type = "buff", unit = "player" }, -- Blessing of the Bronze
        { spell = 386353, type = "buff", unit = "player" }, -- Iridescence: Red
        { spell = 386399, type = "buff", unit = "player" }, -- Iridescence: Blue
        { spell = 390386, type = "buff", unit = "player" }, -- Fury of the Aspects
        { spell = 405874, type = "buff", unit = "player", talent = 115623 }, -- Feed the Flames
        { spell = 406732, type = "buff", unit = "player", talent = 125610 }, -- Spatial Paradox
        { spell = 411055, type = "buff", unit = "player", talent = 115638 }, -- Imminent Destruction
        { spell = 436336, type = "buff", unit = "player", herotalent = 117536 }, -- Mass Disintegrate
        { spell = 441248, type = "buff", unit = "player", herotalent = 117531 }, -- Unrelenting Siege
        { spell = 444019, type = "buff", unit = "player", herotalent = 117543 }, -- Burning Adrenaline
        { spell = 445740, type = "buff", unit = "player", herotalent = 117553 }, -- Enkindle
        { spell = 455962, type = "buff", unit = "player", talent = 115610 }, -- Recall
      },
      icon = 4622463
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 353759, type = "debuff", unit = "target" }, -- Deep Breath
        { spell = 355689, type = "debuff", unit = "target", talent = 115614 }, -- Landslide
        { spell = 356995, type = "debuff", unit = "target" }, -- Disintegrate
        { spell = 357209, type = "debuff", unit = "target" }, -- Fire Breath
        { spell = 357214, type = "debuff", unit = "target" }, -- Wing Buffet
        { spell = 361500, type = "debuff", unit = "target" }, -- Living Flame
        { spell = 368970, type = "debuff", unit = "target" }, -- Tail Swipe
        { spell = 370452, type = "debuff", unit = "target", talent = 115627 }, -- Shattering Star
        { spell = 370898, type = "debuff", unit = "target" }, -- Permeating Chill
        { spell = 406971, type = "debuff", unit = "target", talent = 115607 }, -- Oppressing Roar
        { spell = 434473, type = "debuff", unit = "target", herotalent = 117533 }, -- Bombardments
        { spell = 441172, type = "debuff", unit = "target", herotalent = 117518 }, -- Melt Armor
        { spell = 444017, type = "debuff", unit = "target", herotalent = 117553 }, -- Enkindle
      },
      icon = 4622458
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 351338, type = "ability", requiresTarget = true, talent = 115620 }, -- Quell
        { spell = 355913, type = "ability" }, -- Emerald Blossom
        { spell = 356995, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Disintegrate
        { spell = 357208, type = "ability", overlayGlow = true }, -- Fire Breath
        { spell = 357210, type = "ability", buff = true }, -- Deep Breath
        { spell = 357211, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 115647 }, -- Pyre
        { spell = 357214, type = "ability", debuff = true }, -- Wing Buffet
        { spell = 358267, type = "ability", charges = true, buff = true, overlayGlow = true }, -- Hover
        { spell = 358385, type = "ability", talent = 115614 }, -- Landslide
        { spell = 359073, type = "ability", overlayGlow = true, requiresTarget = true, talent = 115581 }, -- Eternity Surge
        { spell = 360806, type = "ability", requiresTarget = true, talent = 115601 }, -- Sleep Walk
        { spell = 360995, type = "ability", talent = 115655 }, -- Verdant Embrace
        { spell = 361469, type = "ability", overlayGlow = true, requiresTarget = true }, -- Living Flame
        { spell = 362969, type = "ability", requiresTarget = true }, -- Azure Strike
        { spell = 363916, type = "ability", charges = true, buff = true, talent = 115613 }, -- Obsidian Scales
        { spell = 364342, type = "ability" }, -- Blessing of the Bronze
        { spell = 365585, type = "ability", talent = 115615 }, -- Expunge
        { spell = 368432, type = "ability", requiresTarget = true, talent = 115617 }, -- Unravel
        { spell = 368847, type = "ability", overlayGlow = true, talent = 115585 }, -- Firestorm
        { spell = 368970, type = "ability", debuff = true }, -- Tail Swipe
        { spell = 370452, type = "ability", debuff = true, requiresTarget = true, talent = 115627 }, -- Shattering Star
        { spell = 370553, type = "ability", buff = true, talent = 115665 }, -- Tip the Scales
        { spell = 370665, type = "ability", talent = 115596 }, -- Rescue
        { spell = 374227, type = "ability", buff = true, talent = 115661 }, -- Zephyr
        { spell = 374251, type = "ability", talent = 115602 }, -- Cauterizing Flame
        { spell = 374348, type = "ability", buff = true, talent = 115669 }, -- Renewing Blaze
        { spell = 374968, type = "ability", talent = 115666 }, -- Time Spiral
        { spell = 375087, type = "ability", buff = true, talent = 115643 }, -- Dragonrage
        { spell = 382266, type = "ability", overlayGlow = true }, -- Fire Breath
        { spell = 382411, type = "ability", overlayGlow = true, requiresTarget = true, talent = 115581 }, -- Eternity Surge
        { spell = 390386, type = "ability", buff = true }, -- Fury of the Aspects
        { spell = 406732, type = "ability", buff = true, talent = 125610 }, -- Spatial Paradox
        { spell = 406971, type = "ability", debuff = true, talent = 115607 }, -- Oppressing Roar
        { spell = 433874, type = "ability", buff = true }, -- Deep Breath
        { spell = 443328, type = "ability", charges = true, requiresTarget = true, herotalent = 117547 }, -- Engulf
      },
      icon = 4622452
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 355941, type = "buff", unit = "player", talent = 115542 }, -- Dream Breath
        { spell = 357170, type = "buff", unit = "player", talent = 115650 }, -- Time Dilation
        { spell = 357210, type = "buff", unit = "player" }, -- Deep Breath
        { spell = 358267, type = "buff", unit = "player" }, -- Hover
        { spell = 359816, type = "buff", unit = "player", talent = 115573 }, -- Dream Flight
        { spell = 362877, type = "buff", unit = "player", talent = 115543 }, -- Temporal Compression
        { spell = 363534, type = "buff", unit = "player", talent = 115651 }, -- Rewind
        { spell = 363916, type = "buff", unit = "player", talent = 115613 }, -- Obsidian Scales
        { spell = 364343, type = "buff", unit = "player", talent = 115653 }, -- Echo
        { spell = 366155, type = "buff", unit = "player", talent = 115652 }, -- Reversion
        { spell = 369299, type = "buff", unit = "player", talent = 115541 }, -- Essence Burst
        { spell = 370537, type = "buff", unit = "player", talent = 115567 }, -- Stasis
        { spell = 370553, type = "buff", unit = "player", talent = 115665 }, -- Tip the Scales
        { spell = 370901, type = "buff", unit = "player", talent = 115657 }, -- Leaping Flames
        { spell = 370960, type = "buff", unit = "player", talent = 115549 }, -- Emerald Communion
        { spell = 371877, type = "buff", unit = "player", talent = 115572 }, -- Cycle of Life
        { spell = 373267, type = "buff", unit = "player", talent = 115557 }, -- Lifebind
        { spell = 373835, type = "buff", unit = "player", talent = 115554 }, -- Call of Ysera
        { spell = 373862, type = "buff", unit = "player", talent = 115561 }, -- Temporal Anomaly
        { spell = 374227, type = "buff", unit = "player", talent = 115661 }, -- Zephyr
        { spell = 374348, type = "buff", unit = "player", talent = 115669 }, -- Renewing Blaze
        { spell = 375583, type = "buff", unit = "player", talent = 115577 }, -- Ancient Flame
        { spell = 377102, type = "buff", unit = "player", talent = 115550 }, -- Exhilarating Burst
        { spell = 381748, type = "buff", unit = "player" }, -- Blessing of the Bronze
        { spell = 387350, type = "buff", unit = "player", talent = 115555 }, -- Ouroboros
        { spell = 390148, type = "buff", unit = "player", talent = 115560 }, -- Flow State
        { spell = 390386, type = "buff", unit = "player" }, -- Fury of the Aspects
        { spell = 406732, type = "buff", unit = "player", talent = 125610 }, -- Spatial Paradox
        { spell = 409895, type = "buff", unit = "player", talent = 115546 }, -- Spiritbloom
        { spell = 431654, type = "buff", unit = "player", herotalent = 117548 }, -- Primacy
        { spell = 431698, type = "buff", unit = "player", herotalent = 117552 }, -- Temporal Burst
        { spell = 431872, type = "buff", unit = "player", herotalent = 117532 }, -- Temporality
        { spell = 431991, type = "buff", unit = "player", herotalent = 117786 }, -- Time Convergence
        { spell = 443176, type = "buff", unit = "player", talent = 123294 }, -- Lifespark
        { spell = 444019, type = "buff", unit = "player", herotalent = 117543 }, -- Burning Adrenaline
        { spell = 445740, type = "buff", unit = "player", herotalent = 117553 }, -- Enkindle
      },
      icon = 4630476
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 353759, type = "debuff", unit = "target" }, -- Deep Breath
        { spell = 355689, type = "debuff", unit = "target", talent = 115614 }, -- Landslide
        { spell = 356995, type = "debuff", unit = "target" }, -- Disintegrate
        { spell = 357209, type = "debuff", unit = "target" }, -- Fire Breath
        { spell = 360806, type = "debuff", unit = "target", talent = 115601 }, -- Sleep Walk
        { spell = 370898, type = "debuff", unit = "target" }, -- Permeating Chill
        { spell = 406971, type = "debuff", unit = "target", talent = 115607 }, -- Oppressing Roar
        { spell = 444017, type = "debuff", unit = "target", herotalent = 117553 }, -- Enkindle
      },
      icon = 4622488
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 351338, type = "ability", requiresTarget = true, talent = 115620 }, -- Quell
        { spell = 355913, type = "ability", overlayGlow = true }, -- Emerald Blossom
        { spell = 356995, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Disintegrate
        { spell = 357170, type = "ability", buff = true, talent = 115650 }, -- Time Dilation
        { spell = 357210, type = "ability", buff = true }, -- Deep Breath
        { spell = 357214, type = "ability" }, -- Wing Buffet
        { spell = 358267, type = "ability", charges = true, buff = true }, -- Hover
        { spell = 358385, type = "ability", talent = 115614 }, -- Landslide
        { spell = 359816, type = "ability", buff = true, talent = 115573 }, -- Dream Flight
        { spell = 360806, type = "ability", debuff = true, requiresTarget = true, talent = 115601 }, -- Sleep Walk
        { spell = 360823, type = "ability" }, -- Naturalize
        { spell = 360995, type = "ability", talent = 115655 }, -- Verdant Embrace
        { spell = 361469, type = "ability", overlayGlow = true, requiresTarget = true }, -- Living Flame
        { spell = 362969, type = "ability", requiresTarget = true }, -- Azure Strike
        { spell = 363534, type = "ability", charges = true, buff = true, talent = 115651 }, -- Rewind
        { spell = 363916, type = "ability", charges = true, buff = true, talent = 115613 }, -- Obsidian Scales
        { spell = 364342, type = "ability" }, -- Blessing of the Bronze
        { spell = 364343, type = "ability", buff = true, overlayGlow = true, talent = 115653 }, -- Echo
        { spell = 366155, type = "ability", charges = true, buff = true, talent = 115652 }, -- Reversion
        { spell = 368432, type = "ability", requiresTarget = true, talent = 115617 }, -- Unravel
        { spell = 368970, type = "ability" }, -- Tail Swipe
        { spell = 370537, type = "ability", buff = true, talent = 115567 }, -- Stasis
        { spell = 370553, type = "ability", buff = true, talent = 115665 }, -- Tip the Scales
        { spell = 370665, type = "ability", talent = 115596 }, -- Rescue
        { spell = 370960, type = "ability", buff = true, talent = 115549 }, -- Emerald Communion
        { spell = 373861, type = "ability", talent = 115561 }, -- Temporal Anomaly
        { spell = 374227, type = "ability", buff = true, talent = 115661 }, -- Zephyr
        { spell = 374251, type = "ability", talent = 115602 }, -- Cauterizing Flame
        { spell = 374348, type = "ability", buff = true, talent = 115669 }, -- Renewing Blaze
        { spell = 374968, type = "ability", talent = 115666 }, -- Time Spiral
        { spell = 382266, type = "ability", overlayGlow = true }, -- Fire Breath
        { spell = 382614, type = "ability", overlayGlow = true, talent = 115542 }, -- Dream Breath
        { spell = 382731, type = "ability", overlayGlow = true, talent = 115546 }, -- Spiritbloom
        { spell = 390386, type = "ability", buff = true }, -- Fury of the Aspects
        { spell = 406732, type = "ability", buff = true, talent = 125610 }, -- Spatial Paradox
        { spell = 406971, type = "ability", debuff = true, talent = 115607 }, -- Oppressing Roar
        { spell = 443328, type = "ability", charges = true, requiresTarget = true, herotalent = 117547 }, -- Engulf
      },
      icon = 4622474
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
    [11] = {
      title = L["Resources"],
      args = {
      },
      icon = manaIcon,
    },
  },
  [3] = { -- Augmentation
    [1] = {
      title = L["Buffs"],
      args = {
        { spell = 360827, type = "buff", unit = "player", talent = 115508 }, -- Blistering Scales
        { spell = 361021, type = "buff", unit = "player" }, -- Sense Power
        { spell = 363916, type = "buff", unit = "player", talent = 115613 }, -- Obsidian Scales
        { spell = 370553, type = "buff", unit = "player", talent = 115665 }, -- Tip the Scales
        { spell = 370901, type = "buff", unit = "player", talent = 115657 }, -- Leaping Flames
        { spell = 374227, type = "buff", unit = "player", talent = 115661 }, -- Zephyr
        { spell = 374348, type = "buff", unit = "player", talent = 115669 }, -- Renewing Blaze
        { spell = 375583, type = "buff", unit = "player", talent = 115577 }, -- Ancient Flame
        { spell = 375802, type = "buff", unit = "player" }, -- Burnout
        { spell = 381748, type = "buff", unit = "player" }, -- Blessing of the Bronze
        { spell = 390386, type = "buff", unit = "player" }, -- Fury of the Aspects
        { spell = 392268, type = "buff", unit = "player", talent = 115520 }, -- Essence Burst
        { spell = 395296, type = "buff", unit = "player", talent = 115496 }, -- Ebon Might
        { spell = 403264, type = "buff", unit = "player" }, -- Black Attunement
        { spell = 403265, type = "buff", unit = "player" }, -- Bronze Attunement
        { spell = 404977, type = "buff", unit = "player", talent = 115533 }, -- Time Skip
        { spell = 406732, type = "buff", unit = "player", talent = 125610 }, -- Spatial Paradox
        { spell = 407254, type = "buff", unit = "player" }, -- Black Aspect's Favor
        { spell = 410263, type = "buff", unit = "player", talent = 115495 }, -- Inferno's Blessing
        { spell = 410355, type = "buff", unit = "player", talent = 115534 }, -- Stretch Time
        { spell = 410651, type = "buff", unit = "player", talent = 115510 }, -- Molten Blood
        { spell = 410686, type = "buff", unit = "player", talent = 115515 }, -- Symbiotic Bloom
        { spell = 412710, type = "buff", unit = "player", talent = 115679 }, -- Timelessness
        { spell = 438588, type = "buff", unit = "player", herotalent = 122279 }, -- Mass Eruption
        { spell = 441248, type = "buff", unit = "player", herotalent = 117531 }, -- Unrelenting Siege
        { spell = 442204, type = "buff", unit = "player", talent = 115536 }, -- Breath of Eons
        { spell = 455962, type = "buff", unit = "player", talent = 115610 }, -- Recall
        { spell = 459574, type = "buff", unit = "player", talent = 126304 }, -- Imminent Destruction
      },
      icon = 5061347
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355689, type = "debuff", unit = "target", talent = 115614 }, -- Landslide
        { spell = 357209, type = "debuff", unit = "target" }, -- Fire Breath
        { spell = 357214, type = "debuff", unit = "target" }, -- Wing Buffet
        { spell = 360806, type = "debuff", unit = "target", talent = 115601 }, -- Sleep Walk
        { spell = 368970, type = "debuff", unit = "target" }, -- Tail Swipe
        { spell = 370898, type = "debuff", unit = "target" }, -- Permeating Chill
        { spell = 406971, type = "debuff", unit = "target", talent = 115607 }, -- Oppressing Roar
        { spell = 409560, type = "debuff", unit = "target" }, -- Temporal Wound
        { spell = 434473, type = "debuff", unit = "target", herotalent = 117533 }, -- Bombardments
        { spell = 439606, type = "debuff", unit = "target", talent = 115537 }, -- Perilous Fate
        { spell = 441172, type = "debuff", unit = "target", herotalent = 117518 }, -- Melt Armor
        { spell = 441201, type = "debuff", unit = "target", herotalent = 120125 }, -- Menacing Presence
      },
      icon = 5199622
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 351338, type = "ability", requiresTarget = true, talent = 115620 }, -- Quell
        { spell = 355913, type = "ability" }, -- Emerald Blossom
        { spell = 357208, type = "ability", overlayGlow = true }, -- Fire Breath
        { spell = 357214, type = "ability", debuff = true }, -- Wing Buffet
        { spell = 358267, type = "ability", charges = true }, -- Hover
        { spell = 358385, type = "ability", talent = 115614 }, -- Landslide
        { spell = 360806, type = "ability", debuff = true, requiresTarget = true, talent = 115601 }, -- Sleep Walk
        { spell = 360827, type = "ability", buff = true, talent = 115508 }, -- Blistering Scales
        { spell = 360995, type = "ability", talent = 115655 }, -- Verdant Embrace
        { spell = 361021, type = "ability", buff = true }, -- Sense Power
        { spell = 361469, type = "ability", overlayGlow = true, requiresTarget = true }, -- Living Flame
        { spell = 362969, type = "ability", requiresTarget = true }, -- Azure Strike
        { spell = 363916, type = "ability", charges = true, buff = true, talent = 115613 }, -- Obsidian Scales
        { spell = 364342, type = "ability" }, -- Blessing of the Bronze
        { spell = 365585, type = "ability", talent = 115615 }, -- Expunge
        { spell = 368432, type = "ability", requiresTarget = true, talent = 115617 }, -- Unravel
        { spell = 368970, type = "ability", debuff = true }, -- Tail Swipe
        { spell = 370553, type = "ability", buff = true, talent = 115665 }, -- Tip the Scales
        { spell = 370665, type = "ability", talent = 115596 }, -- Rescue
        { spell = 374227, type = "ability", buff = true, talent = 115661 }, -- Zephyr
        { spell = 374251, type = "ability", talent = 115602 }, -- Cauterizing Flame
        { spell = 374348, type = "ability", buff = true, talent = 115669 }, -- Renewing Blaze
        { spell = 374968, type = "ability", talent = 115666 }, -- Time Spiral
        { spell = 382266, type = "ability", overlayGlow = true }, -- Fire Breath
        { spell = 390386, type = "ability", buff = true }, -- Fury of the Aspects
        { spell = 395152, type = "ability", talent = 115496 }, -- Ebon Might
        { spell = 395160, type = "ability", overlayGlow = true, requiresTarget = true, talent = 115498 }, -- Eruption
        { spell = 396286, type = "ability", overlayGlow = true, requiresTarget = true, talent = 115502 }, -- Upheaval
        { spell = 403264, type = "ability", buff = true }, -- Black Attunement
        { spell = 403265, type = "ability", buff = true }, -- Bronze Attunement
        { spell = 404977, type = "ability", buff = true, talent = 115533 }, -- Time Skip
        { spell = 406732, type = "ability", buff = true, talent = 125610 }, -- Spatial Paradox
        { spell = 406971, type = "ability", debuff = true, talent = 115607 }, -- Oppressing Roar
        { spell = 408092, type = "ability", overlayGlow = true, requiresTarget = true, talent = 115502 }, -- Upheaval
        { spell = 408233, type = "ability", talent = 115493 }, -- Bestow Weyrnstone
        { spell = 409311, type = "ability", charges = true, talent = 115675 }, -- Prescience
        { spell = 442204, type = "ability", buff = true, talent = 115536 }, -- Breath of Eons
      },
      icon = 5199630
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 1719, type = "buff", unit = "player" }, -- Recklessness
        { spell = 6673, type = "buff", unit = "player" }, -- Battle Shout
        { spell = 7384, type = "buff", unit = "player", talent = 112123 }, -- Overpower
        { spell = 18499, type = "buff", unit = "player" }, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player", talent = 112253 }, -- Spell Reflection
        { spell = 52437, type = "buff", unit = "player", talent = 112126 }, -- Sudden Death
        { spell = 97463, type = "buff", unit = "player", talent = 112188 }, -- Rallying Cry
        { spell = 107574, type = "buff", unit = "player", talent = 112232 }, -- Avatar
        { spell = 118038, type = "buff", unit = "player", talent = 112128 }, -- Die by the Sword
        { spell = 132404, type = "buff", unit = "player" }, -- Shield Block
        { spell = 190456, type = "buff", unit = "player", talent = 114738 }, -- Ignore Pain
        { spell = 202164, type = "buff", unit = "player", talent = 112219 }, -- Bounding Stride
        { spell = 227847, type = "buff", unit = "player", talent = 112314 }, -- Bladestorm
        { spell = 228920, type = "buff", unit = "player", talent = 119138 }, -- Ravager
        { spell = 248622, type = "buff", unit = "player", talent = 112142 }, -- In For The Kill
        { spell = 260708, type = "buff", unit = "player" }, -- Sweeping Strikes
        { spell = 334783, type = "buff", unit = "player", talent = 114739 }, -- Collateral Damage
        { spell = 351077, type = "buff", unit = "player", talent = 112190 }, -- Second Wind
        { spell = 383290, type = "buff", unit = "player", talent = 112319 }, -- Juggernaut
        { spell = 383316, type = "buff", unit = "player", talent = 112117 }, -- Merciless Bonegrinder
        { spell = 384100, type = "buff", unit = "player", talent = 112211 }, -- Berserker Shout
        { spell = 385013, type = "buff", unit = "player", talent = 112141 }, -- Test of Might
        { spell = 386164, type = "buff", unit = "player", talent = 112184 }, -- Battle Stance
        { spell = 386208, type = "buff", unit = "player", talent = 114643 }, -- Defensive Stance
        { spell = 392778, type = "buff", unit = "player", talent = 112224 }, -- Wild Strikes
        { spell = 439601, type = "buff", unit = "player", talent = 112119 }, -- Storm of Swords
        { spell = 440989, type = "buff", unit = "player", herotalent = 117416 }, -- Colossal Might
        { spell = 445606, type = "buff", unit = "player", herotalent = 117385 }, -- Imminent Demise
        { spell = 446044, type = "buff", unit = "player", herotalent = 117392 }, -- Relentless Pursuit
        { spell = 446918, type = "buff", unit = "player", herotalent = 123409 }, -- Brutal Finish
        { spell = 456120, type = "buff", unit = "player", herotalent = 123770 }, -- Opportunist
        { spell = 458689, type = "buff", unit = "player", herotalent = 117384 }, -- Fierce Followthrough
        { spell = 147833, type = "buff", unit = "target", talent = 112186 }, -- Intervene
      },
      icon = 132333
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target", talent = 112252 }, -- Intimidating Shout
        { spell = 12323, type = "debuff", unit = "target", talent = 112210 }, -- Piercing Howl
        { spell = 105771, type = "debuff", unit = "target" }, -- Charge
        { spell = 115804, type = "debuff", unit = "target" }, -- Mortal Wounds
        { spell = 132168, type = "debuff", unit = "target", talent = 112242 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 112198 }, -- Storm Bolt
        { spell = 208086, type = "debuff", unit = "target", talent = 112144 }, -- Colossus Smash
        { spell = 262115, type = "debuff", unit = "target" }, -- Deep Wounds
        { spell = 376080, type = "debuff", unit = "target", talent = 112247 }, -- Champion's Spear
        { spell = 383704, type = "debuff", unit = "target" }, -- Fatal Mark
        { spell = 386633, type = "debuff", unit = "target", talent = 112318 }, -- Executioner's Precision
        { spell = 388539, type = "debuff", unit = "target", talent = 112136 }, -- Rend
        { spell = 397364, type = "debuff", unit = "target", talent = 112223 }, -- Thunderous Roar
        { spell = 424597, type = "debuff", unit = "target" }, -- Storm of Destruction
        { spell = 427040, type = "debuff", unit = "target", talent = 112133 }, -- Skullsplitter
        { spell = 435203, type = "debuff", unit = "target", talent = 112205 }, -- Thunder Clap
        { spell = 445584, type = "debuff", unit = "target" }, -- Marked for Execution
        { spell = 445836, type = "debuff", unit = "target" }, -- Overwhelmed
        { spell = 447513, type = "debuff", unit = "target" }, -- Wrecked
        { spell = 458480, type = "debuff", unit = "target", herotalent = 117386 }, -- Boneshaker
      },
      icon = 132366
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability", charges = true, requiresTarget = true, usable = true }, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true }, -- Taunt
        { spell = 772, type = "ability", requiresTarget = true, talent = 112136 }, -- Rend
        { spell = 845, type = "ability", overlayGlow = true, talent = 112147 }, -- Cleave
        { spell = 1464, type = "ability", requiresTarget = true }, -- Slam
        { spell = 1715, type = "ability", debuff = true, requiresTarget = true }, -- Hamstring
        { spell = 2565, type = "ability", usable = true }, -- Shield Block
        { spell = 3411, type = "ability", talent = 112186 }, -- Intervene
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true, talent = 112252 }, -- Intimidating Shout
        { spell = 6343, type = "ability", talent = 112205 }, -- Thunder Clap
        { spell = 6544, type = "ability", talent = 112208 }, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true }, -- Pummel
        { spell = 6673, type = "ability", buff = true }, -- Battle Shout
        { spell = 7384, type = "ability", charges = true, buff = true, overlayGlow = true, requiresTarget = true, talent = 112123 }, -- Overpower
        { spell = 12294, type = "ability", overlayGlow = true, requiresTarget = true, talent = 112122 }, -- Mortal Strike
        { spell = 12323, type = "ability", debuff = true, talent = 112210 }, -- Piercing Howl
        { spell = 18499, type = "ability", buff = true }, -- Berserker Rage
        { spell = 23920, type = "ability", buff = true, talent = 112253 }, -- Spell Reflection
        { spell = 23922, type = "ability", requiresTarget = true, usable = true }, -- Shield Slam
        { spell = 34428, type = "ability", requiresTarget = true, usable = true }, -- Victory Rush
        { spell = 46968, type = "ability", talent = 112242 }, -- Shockwave
        { spell = 57755, type = "ability", requiresTarget = true }, -- Heroic Throw
        { spell = 64382, type = "ability", requiresTarget = true, talent = 112214 }, -- Shattering Throw
        { spell = 97462, type = "ability", talent = 112188 }, -- Rallying Cry
        { spell = 107570, type = "ability", requiresTarget = true, talent = 112198 }, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true, talent = 112232 }, -- Avatar
        { spell = 118038, type = "ability", buff = true, talent = 112128 }, -- Die by the Sword
        { spell = 163201, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Execute
        { spell = 167105, type = "ability", requiresTarget = true, debuff = true }, -- Colossus Smash
        { spell = 190456, type = "ability", buff = true, talent = 114738 }, -- Ignore Pain
        { spell = 202168, type = "ability", requiresTarget = true, talent = 112183 }, -- Impending Victory
        { spell = 227847, type = "ability", buff = true, talent = 112314 }, -- Bladestorm
        { spell = 228920, type = "ability", buff = true, talent = 119138 }, -- Ravager
        { spell = 260643, type = "ability", requiresTarget = true, talent = 112133 }, -- Skullsplitter
        { spell = 260708, type = "ability", buff = true }, -- Sweeping Strikes
        { spell = 262161, type = "ability", talent = 112139 }, -- Warbreaker
        { spell = 281000, type = "ability", overlayGlow = true, requiresTarget = true }, -- Execute
        { spell = 316593, type = "ability", debuff = true, talent = 112252 }, -- Intimidating Shout
        { spell = 376079, type = "ability", talent = 112247 }, -- Champion's Spear
        { spell = 383762, type = "ability", talent = 112220 }, -- Bitter Immunity
        { spell = 384100, type = "ability", buff = true, talent = 112211 }, -- Berserker Shout
        { spell = 384110, type = "ability", requiresTarget = true, talent = 112215 }, -- Wrecking Throw
        { spell = 384318, type = "ability", talent = 112223 }, -- Thunderous Roar
        { spell = 386164, type = "ability", buff = true, talent = 112184 }, -- Battle Stance
        { spell = 386208, type = "ability", buff = true, talent = 114643 }, -- Defensive Stance
        { spell = 394062, type = "ability", requiresTarget = true, talent = 112156 }, -- Rend
        { spell = 436358, type = "ability", overlayGlow = true, requiresTarget = true, herotalent = 117415 }, -- Demolish
      },
      icon = 132355
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 1719, type = "buff", unit = "player", talent = 112281 }, -- Recklessness
        { spell = 6673, type = "buff", unit = "player" }, -- Battle Shout
        { spell = 18499, type = "buff", unit = "player" }, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player", talent = 112253 }, -- Spell Reflection
        { spell = 85739, type = "buff", unit = "player" }, -- Whirlwind
        { spell = 97463, type = "buff", unit = "player", talent = 112188 }, -- Rallying Cry
        { spell = 107574, type = "buff", unit = "player", talent = 114770 }, -- Avatar
        { spell = 132404, type = "buff", unit = "player" }, -- Shield Block
        { spell = 184362, type = "buff", unit = "player" }, -- Enrage
        { spell = 184364, type = "buff", unit = "player", talent = 112264 }, -- Enraged Regeneration
        { spell = 202164, type = "buff", unit = "player", talent = 112219 }, -- Bounding Stride
        { spell = 228920, type = "buff", unit = "player", talent = 112256 }, -- Ravager
        { spell = 280746, type = "buff", unit = "player" }, -- Barbarian
        { spell = 280776, type = "buff", unit = "player", talent = 112300 }, -- Sudden Death
        { spell = 335082, type = "buff", unit = "player", talent = 112275 }, -- Frenzy
        { spell = 351077, type = "buff", unit = "player", talent = 112190 }, -- Second Wind
        { spell = 384100, type = "buff", unit = "player", talent = 112211 }, -- Berserker Shout
        { spell = 386196, type = "buff", unit = "player", talent = 112182 }, -- Berserker Stance
        { spell = 386208, type = "buff", unit = "player", talent = 114644 }, -- Defensive Stance
        { spell = 391688, type = "buff", unit = "player", talent = 112288 }, -- Dancing Blades
        { spell = 392537, type = "buff", unit = "player", talent = 112278 }, -- Ashen Juggernaut
        { spell = 392778, type = "buff", unit = "player", talent = 112224 }, -- Wild Strikes
        { spell = 393931, type = "buff", unit = "player", talent = 112280 }, -- Slaughtering Strikes
        { spell = 393951, type = "buff", unit = "player", talent = 112274 }, -- Bloodcraze
        { spell = 396752, type = "buff", unit = "player" }, -- Crushing Blow
        { spell = 435615, type = "buff", unit = "player", herotalent = 117382 }, -- Thunder Blast
        { spell = 437121, type = "buff", unit = "player", herotalent = 117404 }, -- Burst of Power
        { spell = 437152, type = "buff", unit = "player", herotalent = 118836 }, -- Steadfast as the Peaks
        { spell = 438591, type = "buff", unit = "player", herotalent = 117395 }, -- Keep Your Feet on the Ground
        { spell = 445606, type = "buff", unit = "player", herotalent = 117385 }, -- Imminent Demise
        { spell = 446035, type = "buff", unit = "player", talent = 119139 }, -- Bladestorm
        { spell = 446044, type = "buff", unit = "player", herotalent = 117392 }, -- Relentless Pursuit
        { spell = 446918, type = "buff", unit = "player", herotalent = 123409 }, -- Brutal Finish
        { spell = 458689, type = "buff", unit = "player", herotalent = 117384 }, -- Fierce Followthrough
        { spell = 461288, type = "buff", unit = "player" }, -- Bloodbath
        { spell = 147833, type = "buff", unit = "target", talent = 112186 }, -- Intervene
        { spell = 438598, type = "buff", unit = "target", herotalent = 118835 }, -- Storm Shield
      },
      icon = 136224
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target", talent = 112252 }, -- Intimidating Shout
        { spell = 12323, type = "debuff", unit = "target", talent = 112210 }, -- Piercing Howl
        { spell = 105771, type = "debuff", unit = "target" }, -- Charge
        { spell = 132168, type = "debuff", unit = "target", talent = 112242 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 112198 }, -- Storm Bolt
        { spell = 376080, type = "debuff", unit = "target", talent = 112247 }, -- Champion's Spear
        { spell = 385042, type = "debuff", unit = "target" }, -- Gushing Wound
        { spell = 385060, type = "debuff", unit = "target", talent = 112289 }, -- Odyn's Fury
        { spell = 397364, type = "debuff", unit = "target", talent = 112223 }, -- Thunderous Roar
        { spell = 435203, type = "debuff", unit = "target", talent = 112205 }, -- Thunder Clap
        { spell = 445584, type = "debuff", unit = "target" }, -- Marked for Execution
        { spell = 445836, type = "debuff", unit = "target" }, -- Overwhelmed
      },
      icon = 132154
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability", charges = true, requiresTarget = true, usable = true }, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true }, -- Taunt
        { spell = 772, type = "ability", requiresTarget = true, talent = 112136 }, -- Rend
        { spell = 845, type = "ability", talent = 112147 }, -- Cleave
        { spell = 1464, type = "ability", requiresTarget = true }, -- Slam
        { spell = 1715, type = "ability", debuff = true, requiresTarget = true }, -- Hamstring
        { spell = 1719, type = "ability", buff = true, talent = 112281 }, -- Recklessness
        { spell = 2565, type = "ability", usable = true }, -- Shield Block
        { spell = 3411, type = "ability", talent = 112186 }, -- Intervene
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true, talent = 112252 }, -- Intimidating Shout
        { spell = 5308, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Execute
        { spell = 6343, type = "ability", overlayGlow = true, talent = 112205 }, -- Thunder Clap
        { spell = 6544, type = "ability", charges = true, overlayGlow = true, talent = 112208 }, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true }, -- Pummel
        { spell = 6673, type = "ability", buff = true }, -- Battle Shout
        { spell = 12323, type = "ability", debuff = true, talent = 112210 }, -- Piercing Howl
        { spell = 18499, type = "ability", buff = true }, -- Berserker Rage
        { spell = 23881, type = "ability", overlayGlow = true, requiresTarget = true, talent = 112261 }, -- Bloodthirst
        { spell = 23920, type = "ability", buff = true, talent = 112253 }, -- Spell Reflection
        { spell = 23922, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Shield Slam
        { spell = 34428, type = "ability", requiresTarget = true }, -- Victory Rush
        { spell = 46968, type = "ability", talent = 112242 }, -- Shockwave
        { spell = 57755, type = "ability", requiresTarget = true }, -- Heroic Throw
        { spell = 64382, type = "ability", requiresTarget = true, talent = 112214 }, -- Shattering Throw
        { spell = 85288, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 112265 }, -- Raging Blow
        { spell = 97462, type = "ability", talent = 112188 }, -- Rallying Cry
        { spell = 107570, type = "ability", talent = 112198 }, -- Storm Bolt
        { spell = 107574, type = "ability", buff = true, talent = 114770 }, -- Avatar
        { spell = 184364, type = "ability", buff = true, talent = 112264 }, -- Enraged Regeneration
        { spell = 184367, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 112277 }, -- Rampage
        { spell = 202168, type = "ability", requiresTarget = true, talent = 112183 }, -- Impending Victory
        { spell = 228920, type = "ability", buff = true, talent = 112256 }, -- Ravager
        { spell = 280735, type = "ability", overlayGlow = true, requiresTarget = true }, -- Execute
        { spell = 315720, type = "ability", requiresTarget = true, talent = 112295 }, -- Onslaught
        { spell = 316593, type = "ability", debuff = true, requiresTarget = true, talent = 112252 }, -- Intimidating Shout
        { spell = 335096, type = "ability", overlayGlow = true, requiresTarget = true }, -- Bloodbath
        { spell = 335097, type = "ability", charges = true, overlayGlow = true, requiresTarget = true }, -- Crushing Blow
        { spell = 376079, type = "ability", talent = 112247 }, -- Champion's Spear
        { spell = 383762, type = "ability", talent = 112220 }, -- Bitter Immunity
        { spell = 384100, type = "ability", buff = true, talent = 112211 }, -- Berserker Shout
        { spell = 384110, type = "ability", requiresTarget = true, talent = 112215 }, -- Wrecking Throw
        { spell = 384318, type = "ability", talent = 112223 }, -- Thunderous Roar
        { spell = 385059, type = "ability", talent = 112289 }, -- Odyn's Fury
        { spell = 386164, type = "ability", talent = 112184 }, -- Battle Stance
        { spell = 386196, type = "ability", buff = true, talent = 112182 }, -- Berserker Stance
        { spell = 386208, type = "ability", buff = true, talent = 114644 }, -- Defensive Stance
        { spell = 435222, type = "ability", overlayGlow = true, herotalent = 117382 }, -- Thunder Blast
        { spell = 436358, type = "ability", requiresTarget = true, herotalent = 117415 }, -- Demolish
        { spell = 446035, type = "ability", charges = true, buff = true, talent = 119139 }, -- Bladestorm
      },
      icon = 136012
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 871, type = "buff", unit = "player", talent = 112167 }, -- Shield Wall
        { spell = 5302, type = "buff", unit = "player" }, -- Revenge!
        { spell = 6673, type = "buff", unit = "player" }, -- Battle Shout
        { spell = 12975, type = "buff", unit = "player", talent = 112151 }, -- Last Stand
        { spell = 18499, type = "buff", unit = "player" }, -- Berserker Rage
        { spell = 23920, type = "buff", unit = "player", talent = 112253 }, -- Spell Reflection
        { spell = 52437, type = "buff", unit = "player", talent = 112111 }, -- Sudden Death
        { spell = 97463, type = "buff", unit = "player", talent = 112188 }, -- Rallying Cry
        { spell = 132404, type = "buff", unit = "player" }, -- Shield Block
        { spell = 190456, type = "buff", unit = "player", talent = 112149 }, -- Ignore Pain
        { spell = 202164, type = "buff", unit = "player", talent = 112219 }, -- Bounding Stride
        { spell = 202602, type = "buff", unit = "player", talent = 112175 }, -- Into the Fray
        { spell = 351077, type = "buff", unit = "player", talent = 112190 }, -- Second Wind
        { spell = 384043, type = "buff", unit = "player", talent = 112327 }, -- Unnerving Focus
        { spell = 385842, type = "buff", unit = "player", talent = 112177 }, -- Show of Force
        { spell = 386029, type = "buff", unit = "player", talent = 112150 }, -- Brace For Impact
        { spell = 386164, type = "buff", unit = "player", talent = 112112 }, -- Battle Stance
        { spell = 386208, type = "buff", unit = "player", talent = 112187 }, -- Defensive Stance
        { spell = 386486, type = "buff", unit = "player" }, -- Seeing Red
        { spell = 392778, type = "buff", unit = "player", talent = 112224 }, -- Wild Strikes
        { spell = 392966, type = "buff", unit = "player", talent = 112110 }, -- Spell Block
        { spell = 393968, type = "buff", unit = "player", talent = 112322 }, -- Juggernaut
        { spell = 394313, type = "buff", unit = "player", talent = 112113 }, -- Battering Ram
        { spell = 401150, type = "buff", unit = "player", talent = 114769 }, -- Avatar
        { spell = 435615, type = "buff", unit = "player", talent = 117382 }, -- Thunder Blast
        { spell = 437121, type = "buff", unit = "player", talent = 117404 }, -- Burst of Power
        { spell = 437152, type = "buff", unit = "player", talent = 118836 }, -- Steadfast as the Peaks
        { spell = 438591, type = "buff", unit = "player", talent = 117395 }, -- Keep Your Feet on the Ground
        { spell = 440989, type = "buff", unit = "player", talent = 117416 }, -- Colossal Might
        { spell = 147833, type = "buff", unit = "target", talent = 112186 }, -- Intervene
        { spell = 438598, type = "buff", unit = "target", talent = 118835 }, -- Storm Shield
      },
      icon = 1377132
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 355, type = "debuff", unit = "target" }, -- Taunt
        { spell = 1160, type = "debuff", unit = "target", talent = 112159 }, -- Demoralizing Shout
        { spell = 1715, type = "debuff", unit = "target" }, -- Hamstring
        { spell = 5246, type = "debuff", unit = "target", talent = 112252 }, -- Intimidating Shout
        { spell = 105771, type = "debuff", unit = "target" }, -- Charge
        { spell = 115767, type = "debuff", unit = "target" }, -- Deep Wounds
        { spell = 132168, type = "debuff", unit = "target", talent = 112242 }, -- Shockwave
        { spell = 132169, type = "debuff", unit = "target", talent = 112198 }, -- Storm Bolt
        { spell = 275335, type = "debuff", unit = "target", talent = 112323 }, -- Punish
        { spell = 376080, type = "debuff", unit = "target", talent = 112247 }, -- Champion's Spear
        { spell = 385954, type = "debuff", unit = "target", talent = 112173 }, -- Shield Charge
        { spell = 386071, type = "debuff", unit = "target", talent = 112161 }, -- Disrupting Shout
        { spell = 388539, type = "debuff", unit = "target", talent = 112156 }, -- Rend
        { spell = 397364, type = "debuff", unit = "target", talent = 112223 }, -- Thunderous Roar
        { spell = 435203, type = "debuff", unit = "target", talent = 112205 }, -- Thunder Clap
        { spell = 447513, type = "debuff", unit = "target" }, -- Wrecked
        { spell = 458480, type = "debuff", unit = "target", talent = 117386 }, -- Boneshaker
      },
      icon = 132090
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100, type = "ability", charges = true, requiresTarget = true, usable = true }, -- Charge
        { spell = 355, type = "ability", debuff = true, requiresTarget = true }, -- Taunt
        { spell = 871, type = "ability", buff = true, requiresTarget = true, talent = 112167 }, -- Shield Wall
        { spell = 1160, type = "ability", debuff = true, talent = 112159 }, -- Demoralizing Shout
        { spell = 1161, type = "ability", talent = 112163 }, -- Challenging Shout
        { spell = 1715, type = "ability", debuff = true, requiresTarget = true }, -- Hamstring
        { spell = 2565, type = "ability", charges = true }, -- Shield Block
        { spell = 3411, type = "ability", requiresTarget = true, talent = 112186 }, -- Intervene
        { spell = 5246, type = "ability", debuff = true, requiresTarget = true, talent = 112252 }, -- Intimidating Shout
        { spell = 6343, type = "ability", overlayGlow = true, talent = 112205 }, -- Thunder Clap
        { spell = 6544, type = "ability", talent = 112208 }, -- Heroic Leap
        { spell = 6552, type = "ability", requiresTarget = true }, -- Pummel
        { spell = 6572, type = "ability", overlayGlow = true, talent = 112152 }, -- Revenge
        { spell = 6673, type = "ability", buff = true }, -- Battle Shout
        { spell = 12323, type = "ability", talent = 112210 }, -- Piercing Howl
        { spell = 12975, type = "ability", buff = true, talent = 112151 }, -- Last Stand
        { spell = 18499, type = "ability", buff = true }, -- Berserker Rage
        { spell = 23920, type = "ability", buff = true, talent = 112253 }, -- Spell Reflection
        { spell = 23922, type = "ability", overlayGlow = true, requiresTarget = true }, -- Shield Slam
        { spell = 34428, type = "ability", requiresTarget = true, usable = true }, -- Victory Rush
        { spell = 46968, type = "ability", talent = 112242 }, -- Shockwave
        { spell = 57755, type = "ability", requiresTarget = true }, -- Heroic Throw
        { spell = 64382, type = "ability", requiresTarget = true, talent = 112214 }, -- Shattering Throw
        { spell = 97462, type = "ability", talent = 112188 }, -- Rallying Cry
        { spell = 107570, type = "ability", requiresTarget = true, talent = 112198 }, -- Storm Bolt
        { spell = 163201, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Execute
        { spell = 190456, type = "ability", buff = true, talent = 112149 }, -- Ignore Pain
        { spell = 202168, type = "ability", requiresTarget = true, talent = 112183 }, -- Impending Victory
        { spell = 227847, type = "ability", talent = 119139 }, -- Bladestorm
        { spell = 228920, type = "ability", talent = 112304 }, -- Ravager
        { spell = 316593, type = "ability", debuff = true, requiresTarget = true, talent = 112252 }, -- Intimidating Shout
        { spell = 376079, type = "ability", talent = 112247 }, -- Champion's Spear
        { spell = 383762, type = "ability", requiresTarget = true, talent = 112220 }, -- Bitter Immunity
        { spell = 384100, type = "ability", talent = 112211 }, -- Berserker Shout
        { spell = 384110, type = "ability", requiresTarget = true, talent = 112215 }, -- Wrecking Throw
        { spell = 384318, type = "ability", talent = 112223 }, -- Thunderous Roar
        { spell = 385952, type = "ability", requiresTarget = true, talent = 112173 }, -- Shield Charge
        { spell = 386071, type = "ability", debuff = true, talent = 112161 }, -- Disrupting Shout
        { spell = 386164, type = "ability", buff = true, talent = 112112 }, -- Battle Stance
        { spell = 386196, type = "ability", talent = 112182 }, -- Berserker Stance
        { spell = 386208, type = "ability", buff = true, talent = 112187 }, -- Defensive Stance
        { spell = 392966, type = "ability", buff = true, talent = 112110 }, -- Spell Block
        { spell = 394062, type = "ability", requiresTarget = true, talent = 112156 }, -- Rend
        { spell = 401150, type = "ability", buff = true, talent = 114769 }, -- Avatar
        { spell = 435222, type = "ability", overlayGlow = true, herotalent = 117382 }, -- Thunder Blast
        { spell = 436358, type = "ability", overlayGlow = true, requiresTarget = true, herotalent = 117415 }, -- Demolish
      },
      icon = 134951
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 498, type = "buff", unit = "player" }, -- Divine Protection
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "player", talent = 102604 }, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "player", talent = 102587 }, -- Blessing of Freedom
        { spell = 5502, type = "buff", unit = "player" }, -- Sense Undead
        { spell = 31821, type = "buff", unit = "player", talent = 102548 }, -- Aura Mastery
        { spell = 31884, type = "buff", unit = "player", talent = 102593 }, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player", talent = 102587 }, -- Crusader Aura
        { spell = 53563, type = "buff", unit = "player" }, -- Beacon of Light
        { spell = 54149, type = "buff", unit = "player" }, -- Infusion of Light
        { spell = 96231, type = "buff", unit = "player", talent = 102591 }, -- Rebuke
        { spell = 148039, type = "buff", unit = "player", talent = 102560 }, -- Barrier of Faith
        { spell = 156322, type = "buff", unit = "player", herotalent = 117692 }, -- Eternal Flame
        { spell = 188370, type = "buff", unit = "player" }, -- Consecration
        { spell = 200025, type = "buff", unit = "player", talent = 102532 }, -- Beacon of Virtue
        { spell = 200652, type = "buff", unit = "player", talent = 102573 }, -- Tyr's Deliverance
        { spell = 210294, type = "buff", unit = "player", talent = 102551 }, -- Divine Favor
        { spell = 211210, type = "buff", unit = "player", talent = 102546 }, -- Protection of Tyr
        { spell = 216331, type = "buff", unit = "player", talent = 102568 }, -- Avenging Crusader
        { spell = 223819, type = "buff", unit = "player", talent = 115489 }, -- Divine Purpose
        { spell = 317920, type = "buff", unit = "player" }, -- Concentration Aura
        { spell = 379017, type = "buff", unit = "player", talent = 102464 }, -- Faith's Armor
        { spell = 383389, type = "buff", unit = "player", talent = 102575 }, -- Relentless Inquisitor
        { spell = 385126, type = "buff", unit = "player" }, -- Blessing of Dusk
        { spell = 385127, type = "buff", unit = "player" }, -- Blessing of Dawn
        { spell = 386730, type = "buff", unit = "player", talent = 115466 }, -- Divine Resonance
        { spell = 387178, type = "buff", unit = "player", talent = 102576 }, -- Empyrean Legacy
        { spell = 387792, type = "buff", unit = "player", talent = 128255 }, -- Empyreal Ward
        { spell = 387804, type = "buff", unit = "player" }, -- Echoing Protection
        { spell = 388007, type = "buff", unit = "player", talent = 116183 }, -- Blessing of Summer
        { spell = 388010, type = "buff", unit = "player" }, -- Blessing of Autumn
        { spell = 388011, type = "buff", unit = "player" }, -- Blessing of Winter
        { spell = 388013, type = "buff", unit = "player" }, -- Blessing of Spring
        { spell = 392939, type = "buff", unit = "player", talent = 102565 }, -- Veneration
        { spell = 394454, type = "buff", unit = "player" }, -- Echoing Freedom
        { spell = 394709, type = "buff", unit = "player", talent = 102558 }, -- Unending Light
        { spell = 400745, type = "buff", unit = "player", talent = 102601 }, -- Afterimage
        { spell = 414196, type = "buff", unit = "player", talent = 116205 }, -- Awakening
        { spell = 414204, type = "buff", unit = "player", talent = 102581 }, -- Rising Sunlight
        { spell = 414444, type = "buff", unit = "player", talent = 102541 }, -- Shining Righteousness
        { spell = 431381, type = "buff", unit = "player", herotalent = 117696 }, -- Dawnlight
        { spell = 431415, type = "buff", unit = "player", herotalent = 117669 }, -- Sun Sear
        { spell = 431462, type = "buff", unit = "player", herotalent = 117777 }, -- Will of the Dawn
        { spell = 431481, type = "buff", unit = "player", herotalent = 117778 }, -- Gleaming Rays
        { spell = 431539, type = "buff", unit = "player", herotalent = 117670 }, -- Morning Star
        { spell = 432496, type = "buff", unit = "player", herotalent = 117882 }, -- Holy Bulwark
        { spell = 432502, type = "buff", unit = "player" }, -- Sacred Weapon
        { spell = 433019, type = "buff", unit = "player", herotalent = 117883 }, -- Blessed Assurance
        { spell = 439841, type = "buff", unit = "player", herotalent = 117691 }, -- Solar Grace
        { spell = 445204, type = "buff", unit = "player", herotalent = 117668 }, -- Blessing of An'she
        { spell = 447988, type = "buff", unit = "player", talent = 102540 }, -- Light of the Martyr
        { spell = 460822, type = "buff", unit = "player", herotalent = 117884 }, -- Divine Guidance
        { spell = 461499, type = "buff", unit = "player", talent = 102535 }, -- Overflowing Light
        { spell = 461578, type = "buff", unit = "player", talent = 102557 }, -- Saved by the Light
      },
      icon = 135964
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 102584 }, -- Blinding Light
        { spell = 196941, type = "debuff", unit = "target", talent = 102596 }, -- Judgment of Light
        { spell = 204242, type = "debuff", unit = "target" }, -- Consecration
        { spell = 414022, type = "debuff", unit = "target" }, -- Unworthy
        { spell = 431380, type = "debuff", unit = "target", herotalent = 117696 }, -- Dawnlight
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 498, type = "ability", buff = true }, -- Divine Protection
        { spell = 633, type = "ability", usable = true, talent = 102583 }, -- Lay on Hands
        { spell = 642, type = "ability", buff = true, usable = true }, -- Divine Shield
        { spell = 853, type = "ability", debuff = true, requiresTarget = true }, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true, usable = true, talent = 102604 }, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true, talent = 102587 }, -- Blessing of Freedom
        { spell = 4987, type = "ability" }, -- Cleanse
        { spell = 10326, type = "ability", talent = 102623 }, -- Turn Evil
        { spell = 20066, type = "ability", talent = 102585 }, -- Repentance
        { spell = 20473, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 102534 }, -- Holy Shock
        { spell = 24275, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 102479 }, -- Hammer of Wrath
        { spell = 26573, type = "ability", totem = true }, -- Consecration
        { spell = 31821, type = "ability", buff = true, talent = 102548 }, -- Aura Mastery
        { spell = 31884, type = "ability", buff = true, talent = 102593 }, -- Avenging Wrath
        { spell = 35395, type = "ability", charges = true, requiresTarget = true }, -- Crusader Strike
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true }, -- Hand of Reckoning
        { spell = 96231, type = "ability", buff = true, requiresTarget = true, talent = 102591 }, -- Rebuke
        { spell = 114165, type = "ability", requiresTarget = true, talent = 102561 }, -- Holy Prism
        { spell = 115750, type = "ability", talent = 102584 }, -- Blinding Light
        { spell = 148039, type = "ability", buff = true, talent = 102560 }, -- Barrier of Faith
        { spell = 190784, type = "ability", charges = true, talent = 102625 }, -- Divine Steed
        { spell = 200025, type = "ability", buff = true, talent = 102532 }, -- Beacon of Virtue
        { spell = 200652, type = "ability", buff = true, talent = 102573 }, -- Tyr's Deliverance
        { spell = 216331, type = "ability", buff = true, talent = 102568 }, -- Avenging Crusader
        { spell = 275773, type = "ability", requiresTarget = true }, -- Judgment
        { spell = 375576, type = "ability", requiresTarget = true, talent = 102465 }, -- Divine Toll
        { spell = 388007, type = "ability", buff = true, talent = 116183 }, -- Blessing of Summer
        { spell = 388010, type = "ability", buff = true }, -- Blessing of Autumn
        { spell = 388011, type = "ability", buff = true }, -- Blessing of Winter
        { spell = 388013, type = "ability", buff = true }, -- Blessing of Spring
        { spell = 391054, type = "ability" }, -- Intercession
        { spell = 414273, type = "ability", talent = 115876 }, -- Hand of Divinity
        { spell = 415091, type = "ability" }, -- Shield of the Righteous
        { spell = 432459, type = "ability", charges = true, herotalent = 117882 }, -- Holy Bulwark
        { spell = 432472, type = "ability", charges = true }, -- Sacred Weapon

      },
      icon = 135972
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 1022, type = "buff", unit = "player", talent = 102604 }, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "player", talent = 102587 }, -- Blessing of Freedom
        { spell = 5502, type = "buff", unit = "player" }, -- Sense Undead
        { spell = 31850, type = "buff", unit = "player", talent = 102445 }, -- Ardent Defender
        { spell = 31884, type = "buff", unit = "player", talent = 102611 }, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player", talent = 102587 }, -- Crusader Aura
        { spell = 86659, type = "buff", unit = "player", talent = 102456 }, -- Guardian of Ancient Kings
        { spell = 96231, type = "buff", unit = "player", talent = 102591 }, -- Rebuke
        { spell = 132403, type = "buff", unit = "player" }, -- Shield of the Righteous
        { spell = 182104, type = "buff", unit = "player", talent = 102467 }, -- Shining Light
        { spell = 188370, type = "buff", unit = "player" }, -- Consecration
        { spell = 204018, type = "buff", unit = "player", talent = 111886 }, -- Blessing of Spellwarding
        { spell = 209388, type = "buff", unit = "player", talent = 102468 }, -- Bulwark of Order
        { spell = 223819, type = "buff", unit = "player", talent = 115490 }, -- Divine Purpose
        { spell = 280375, type = "buff", unit = "player", talent = 102462 }, -- Redoubt
        { spell = 317920, type = "buff", unit = "player" }, -- Concentration Aura
        { spell = 327193, type = "buff", unit = "player", talent = 102474 }, -- Moment of Glory
        { spell = 378412, type = "buff", unit = "player", talent = 102472 }, -- Light of the Titans
        { spell = 378974, type = "buff", unit = "player", talent = 102454 }, -- Bastion of Light
        { spell = 379017, type = "buff", unit = "player", talent = 102464 }, -- Faith's Armor
        { spell = 379041, type = "buff", unit = "player", talent = 102450 }, -- Faith in the Light
        { spell = 383389, type = "buff", unit = "player", talent = 102475 }, -- Relentless Inquisitor
        { spell = 385126, type = "buff", unit = "player" }, -- Blessing of Dusk
        { spell = 385127, type = "buff", unit = "player" }, -- Blessing of Dawn
        { spell = 385724, type = "buff", unit = "player", talent = 102470 }, -- Barricade of Faith
        { spell = 386556, type = "buff", unit = "player", talent = 102463 }, -- Inner Light
        { spell = 386652, type = "buff", unit = "player", talent = 102457 }, -- Bulwark of Righteous Fury
        { spell = 386730, type = "buff", unit = "player", talent = 102443 }, -- Divine Resonance
        { spell = 387792, type = "buff", unit = "player", talent = 128255 }, -- Empyreal Ward
        { spell = 389539, type = "buff", unit = "player", talent = 102447 }, -- Sentinel
        { spell = 393019, type = "buff", unit = "player", talent = 102439 }, -- Inspiring Vanguard
        { spell = 393038, type = "buff", unit = "player", talent = 102461 }, -- Strength in Adversity
        { spell = 400745, type = "buff", unit = "player", talent = 115480 }, -- Afterimage
        { spell = 431536, type = "buff", unit = "player", herotalent = 117823 }, -- Shake the Heavens
        { spell = 432496, type = "buff", unit = "player", herotalent = 117882 }, -- Holy Bulwark
        { spell = 432502, type = "buff", unit = "player" }, -- Sacred Weapon
        { spell = 432629, type = "buff", unit = "player", herotalent = 117822 }, -- Undisputed Ruling
        { spell = 433019, type = "buff", unit = "player", herotalent = 117883 }, -- Blessed Assurance
        { spell = 433550, type = "buff", unit = "player", herotalent = 117881 }, -- Rite of Sanctification
        { spell = 433584, type = "buff", unit = "player", herotalent = 117880 }, -- Rite of Adjuration
        { spell = 433618, type = "buff", unit = "player", herotalent = 117859 }, -- For Whom the Bell Tolls
        { spell = 433671, type = "buff", unit = "player", herotalent = 117819 }, -- Sanctification
        { spell = 433674, type = "buff", unit = "player", herotalent = 117815 }, -- Light's Deliverance
        { spell = 447988, type = "buff", unit = "player", talent = 102540 }, -- Light of the Martyr
        { spell = 452244, type = "buff", unit = "player", herotalent = 117820 }, -- Endless Wrath
        { spell = 453804, type = "buff", unit = "player", talent = 102625 }, -- Divine Steed
        { spell = 460822, type = "buff", unit = "player", herotalent = 117884 }, -- Divine Guidance
        { spell = 461867, type = "buff", unit = "player", herotalent = 117812 }, -- Sacrosanct Crusade
      },
      icon = 236265
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 31935, type = "debuff", unit = "target", talent = 102471 }, -- Avenger's Shield
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 102584 }, -- Blinding Light
        { spell = 196941, type = "debuff", unit = "target", talent = 102596 }, -- Judgment of Light
        { spell = 197277, type = "debuff", unit = "target" }, -- Judgment
        { spell = 204079, type = "debuff", unit = "target", talent = 102473 }, -- Final Stand
        { spell = 204242, type = "debuff", unit = "target" }, -- Consecration
        { spell = 204301, type = "debuff", unit = "target", talent = 102430 }, -- Blessed Hammer
        { spell = 383843, type = "debuff", unit = "target", talent = 102460 }, -- Crusader's Resolve
        { spell = 387174, type = "debuff", unit = "target", talent = 102466 }, -- Eye of Tyr
        { spell = 431625, type = "debuff", unit = "target" }, -- Empyrean Hammer
        { spell = 469882, type = "debuff", unit = "target", talent = 102459 }, -- Refining Fire
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 633, type = "ability", usable = true, talent = 102583 }, -- Lay on Hands
        { spell = 642, type = "ability", buff = true, usable = true }, -- Divine Shield
        { spell = 853, type = "ability", debuff = true, requiresTarget = true }, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true, usable = true, talent = 102604 }, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true, talent = 102587 }, -- Blessing of Freedom
        { spell = 10326, type = "ability", talent = 102623 }, -- Turn Evil
        { spell = 20066, type = "ability", talent = 102585 }, -- Repentance
        { spell = 24275, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 102479 }, -- Hammer of Wrath
        { spell = 26573, type = "ability", totem = true }, -- Consecration
        { spell = 31850, type = "ability", buff = true, talent = 102445 }, -- Ardent Defender
        { spell = 31884, type = "ability", buff = true, talent = 102611 }, -- Avenging Wrath
        { spell = 31935, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, talent = 102471 }, -- Avenger's Shield
        { spell = 53595, type = "ability", charges = true, requiresTarget = true, talent = 102431 }, -- Hammer of the Righteous
        { spell = 53600, type = "ability" }, -- Shield of the Righteous
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true }, -- Hand of Reckoning
        { spell = 86659, type = "ability", buff = true, talent = 102456 }, -- Guardian of Ancient Kings
        { spell = 96231, type = "ability", buff = true, requiresTarget = true, talent = 102591 }, -- Rebuke
        { spell = 115750, type = "ability", debuff = true, talent = 102584 }, -- Blinding Light
        { spell = 190784, type = "ability", charges = true, buff = true, talent = 102625 }, -- Divine Steed
        { spell = 204018, type = "ability", buff = true, usable = true, talent = 111886 }, -- Blessing of Spellwarding
        { spell = 204019, type = "ability", charges = true, talent = 102430 }, -- Blessed Hammer
        { spell = 275779, type = "ability", charges = true, requiresTarget = true }, -- Judgment
        { spell = 327193, type = "ability", buff = true, talent = 102474 }, -- Moment of Glory
        { spell = 375576, type = "ability", requiresTarget = true, talent = 102465 }, -- Divine Toll
        { spell = 378974, type = "ability", buff = true, talent = 102454 }, -- Bastion of Light
        { spell = 387174, type = "ability", debuff = true, talent = 102466 }, -- Eye of Tyr
        { spell = 389539, type = "ability", buff = true, talent = 102447 }, -- Sentinel
        { spell = 391054, type = "ability" }, -- Intercession
        { spell = 432459, type = "ability", charges = true, herotalent = 117882 }, -- Holy Bulwark
        { spell = 432472, type = "ability", charges = true }, -- Sacred Weapon
      },
      icon = 135874
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 642, type = "buff", unit = "player" }, -- Divine Shield
        { spell = 1022, type = "buff", unit = "player", talent = 102604 }, -- Blessing of Protection
        { spell = 1044, type = "buff", unit = "player", talent = 102587 }, -- Blessing of Freedom
        { spell = 5502, type = "buff", unit = "player" }, -- Sense Undead
        { spell = 20271, type = "buff", unit = "player" }, -- Judgment
        { spell = 31884, type = "buff", unit = "player", talent = 102593 }, -- Avenging Wrath
        { spell = 32223, type = "buff", unit = "player", talent = 102587 }, -- Crusader Aura
        { spell = 96231, type = "buff", unit = "player", talent = 102591 }, -- Rebuke
        { spell = 156322, type = "buff", unit = "player", herotalent = 117692 }, -- Eternal Flame
        { spell = 184662, type = "buff", unit = "player", talent = 125130 }, -- Shield of Vengeance
        { spell = 188370, type = "buff", unit = "player" }, -- Consecration
        { spell = 317920, type = "buff", unit = "player" }, -- Concentration Aura
        { spell = 326733, type = "buff", unit = "player", talent = 115051 }, -- Empyrean Power
        { spell = 379017, type = "buff", unit = "player", talent = 102464 }, -- Faith's Armor
        { spell = 383329, type = "buff", unit = "player", talent = 102504 }, -- Final Verdict
        { spell = 384029, type = "buff", unit = "player", talent = 115468 }, -- Divine Resonance
        { spell = 385126, type = "buff", unit = "player" }, -- Blessing of Dusk
        { spell = 385127, type = "buff", unit = "player" }, -- Blessing of Dawn
        { spell = 387178, type = "buff", unit = "player", talent = 115453 }, -- Empyrean Legacy
        { spell = 387792, type = "buff", unit = "player", talent = 128255 }, -- Empyreal Ward
        { spell = 400745, type = "buff", unit = "player", talent = 115482 }, -- Afterimage
        { spell = 403876, type = "buff", unit = "player" }, -- Divine Protection
        { spell = 403976, type = "buff", unit = "player", talent = 115164 }, -- Inquisitor's Ire
        { spell = 406975, type = "buff", unit = "player", talent = 102514 }, -- Divine Arbiter
        { spell = 407065, type = "buff", unit = "player", talent = 115475 }, -- Rush of Light
        { spell = 408458, type = "buff", unit = "player", talent = 102608 }, -- Divine Purpose
        { spell = 431381, type = "buff", unit = "player", herotalent = 117696 }, -- Dawnlight
        { spell = 431462, type = "buff", unit = "player", herotalent = 117777 }, -- Will of the Dawn
        { spell = 431481, type = "buff", unit = "player", herotalent = 117778 }, -- Gleaming Rays
        { spell = 431539, type = "buff", unit = "player", herotalent = 117670 }, -- Morning Star
        { spell = 433618, type = "buff", unit = "player", herotalent = 117859 }, -- For Whom the Bell Tolls
        { spell = 433671, type = "buff", unit = "player", herotalent = 117819 }, -- Sanctification
        { spell = 433674, type = "buff", unit = "player", herotalent = 117815 }, -- Light's Deliverance
        { spell = 439841, type = "buff", unit = "player", herotalent = 117691 }, -- Solar Grace
        { spell = 445206, type = "buff", unit = "player", herotalent = 117668 }, -- Blessing of An'she
        { spell = 452244, type = "buff", unit = "player", herotalent = 117820 }, -- Endless Wrath
        { spell = 453433, type = "buff", unit = "player", talent = 115477 }, -- Judge, Jury and Executioner
        { spell = 453804, type = "buff", unit = "player", talent = 102625 }, -- Divine Steed
        { spell = 454373, type = "buff", unit = "player", talent = 125129 }, -- Crusade
        { spell = 461867, type = "buff", unit = "player", herotalent = 117812 }, -- Sacrosanct Crusade
      },
      icon = 135993
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 853, type = "debuff", unit = "target" }, -- Hammer of Justice
        { spell = 62124, type = "debuff", unit = "target" }, -- Hand of Reckoning
        { spell = 105421, type = "debuff", unit = "target", talent = 102584 }, -- Blinding Light
        { spell = 196941, type = "debuff", unit = "target", talent = 102596 }, -- Judgment of Light
        { spell = 197277, type = "debuff", unit = "target" }, -- Judgment
        { spell = 198137, type = "debuff", unit = "target", talent = 115016 }, -- Divine Hammer
        { spell = 204242, type = "debuff", unit = "target" }, -- Consecration
        { spell = 343527, type = "debuff", unit = "target", talent = 115435 }, -- Execution Sentence
        { spell = 343721, type = "debuff", unit = "target", talent = 102513 }, -- Final Reckoning
        { spell = 383346, type = "debuff", unit = "target", talent = 114830 }, -- Expurgation
        { spell = 403695, type = "debuff", unit = "target" }, -- Truth's Wake
        { spell = 408383, type = "debuff", unit = "target", talent = 115440 }, -- Judgment of Justice
        { spell = 431380, type = "debuff", unit = "target", herotalent = 117696 }, -- Dawnlight
        { spell = 431414, type = "debuff", unit = "target", herotalent = 117669 }, -- Sun Sear
        { spell = 431625, type = "debuff", unit = "target" }, -- Empyrean Hammer
        { spell = 447142, type = "debuff", unit = "target" }, -- Templar Slash
      },
      icon = 135952
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 633, type = "ability", usable = true, talent = 102583 }, -- Lay on Hands
        { spell = 642, type = "ability", buff = true, usable = true }, -- Divine Shield
        { spell = 853, type = "ability", debuff = true, requiresTarget = true }, -- Hammer of Justice
        { spell = 1022, type = "ability", buff = true, usable = true, talent = 102604 }, -- Blessing of Protection
        { spell = 1044, type = "ability", buff = true, talent = 102587 }, -- Blessing of Freedom
        { spell = 10326, type = "ability", debuff = true, talent = 102623 }, -- Turn Evil
        { spell = 20066, type = "ability", debuff = true, talent = 102585 }, -- Repentance
        { spell = 20271, type = "ability", charges = true, debuff = true, requiresTarget = true }, -- Judgment
        { spell = 24275, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 102479 }, -- Hammer of Wrath
        { spell = 31884, type = "ability", buff = true, talent = 102593 }, -- Avenging Wrath
        { spell = 35395, type = "ability", charges = true, requiresTarget = true }, -- Crusader Strike
        { spell = 62124, type = "ability", debuff = true, requiresTarget = true }, -- Hand of Reckoning
        { spell = 96231, type = "ability", buff = true, requiresTarget = true, talent = 102591 }, -- Rebuke
        { spell = 115750, type = "ability", debuff = true, talent = 102584 }, -- Blinding Light
        { spell = 184575, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 102498 }, -- Blade of Justice
        { spell = 184662, type = "ability", buff = true, talent = 125130 }, -- Shield of Vengeance
        { spell = 190784, type = "ability", charges = true, buff = true, talent = 102625 }, -- Divine Steed
        { spell = 198034, type = "ability", talent = 115016 }, -- Divine Hammer
        { spell = 215661, type = "ability", requiresTarget = true, talent = 114831 }, -- Justicar's Vengeance
        { spell = 255937, type = "ability", requiresTarget = true, talent = 102497 }, -- Wake of Ashes
        { spell = 343527, type = "ability", debuff = true, requiresTarget = true, talent = 115435 }, -- Execution Sentence
        { spell = 343721, type = "ability", debuff = true, talent = 102513 }, -- Final Reckoning
        { spell = 375576, type = "ability", requiresTarget = true, talent = 102465 }, -- Divine Toll
        { spell = 383328, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 102504 }, -- Final Verdict
        { spell = 391054, type = "ability" }, -- Intercession
        { spell = 403876, type = "ability", buff = true }, -- Divine Protection
        { spell = 407480, type = "ability", overlayGlow = true, requiresTarget = true }, -- Templar Strike
      },
      icon = 135891
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 19574, type = "buff", unit = "player", talent = 126402 }, -- Bestial Wrath
        { spell = 34477, type = "buff", unit = "player", talent = 126484 }, -- Misdirection
        { spell = 53480, type = "buff", unit = "player", talent = 126469 }, -- Roar of Sacrifice
        { spell = 59976, type = "buff", unit = "player" }, -- Black Proto-Drake
        { spell = 118922, type = "buff", unit = "player", talent = 126475 }, -- Posthaste
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 199483, type = "buff", unit = "player", talent = 126478 }, -- Camouflage
        { spell = 231390, type = "buff", unit = "player", talent = 126464 }, -- Trailblazer
        { spell = 246152, type = "buff", unit = "player", talent = 126440 }, -- Barbed Shot
        { spell = 257946, type = "buff", unit = "player", talent = 126407 }, -- Thrill of the Hunt
        { spell = 264656, type = "buff", unit = "player", talent = 126468 }, -- Pathfinding
        { spell = 264663, type = "buff", unit = "player" }, -- Predator's Thirst
        { spell = 264667, type = "buff", unit = "player" }, -- Primal Rage
        { spell = 264735, type = "buff", unit = "player", talent = 126488 }, -- Survival of the Fittest
        { spell = 268877, type = "buff", unit = "player", talent = 126403 }, -- Beast Cleave
        { spell = 281036, type = "buff", unit = "player", talent = 126439 }, -- Dire Beast
        { spell = 359844, type = "buff", unit = "player", talent = 126397 }, -- Call of the Wild
        { spell = 378770, type = "buff", unit = "player", talent = 126474 }, -- Deathblow
        { spell = 385540, type = "buff", unit = "player", talent = 126444 }, -- Rejuvenating Wind
        { spell = 431917, type = "buff", unit = "player", herotalent = 117588 }, -- Vicious Hunt
        { spell = 447262, type = "buff", unit = "player", herotalent = 117585 }, -- Frenzied Tear
        { spell = 448777, type = "buff", unit = "player", herotalent = 117569 }, -- Den Recovery
        { spell = 450143, type = "buff", unit = "player", herotalent = 123781 }, -- Beast of Opportunity
        { spell = 452101, type = "buff", unit = "player", herotalent = 123782 }, -- Cornered Prey
        { spell = 459468, type = "buff", unit = "player", talent = 126448 }, -- Ghillie Suit
        { spell = 459689, type = "buff", unit = "player", talent = 126433 }, -- Explosive Venom
        { spell = 459731, type = "buff", unit = "player", talent = 126411 }, -- Huntmaster's Call
        { spell = 459735, type = "buff", unit = "player" }, -- Summon Fenryr
        { spell = 459759, type = "buff", unit = "player", talent = 126414 }, -- A Murder of Crows
        { spell = 466991, type = "buff", unit = "player", herotalent = 117590 }, -- Withering Fire
        { spell = 461866, type = "buff", unit = "player", herotalent = 117566 }, -- Scattered Prey
        { spell = 462515, type = "buff", unit = "player", herotalent = 117589 }, -- Howl of the Pack
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 61684, type = "buff", unit = "pet" }, -- Dash
        { spell = 272790, type = "buff", unit = "pet" }, -- Frenzy
        { spell = 392054, type = "buff", unit = "pet", talent = 126434 }, -- Piercing Fangs
        { spell = 445695, type = "buff", unit = "pet", herotalent = 117582 }, -- Pack Coordination
        { spell = 459547, type = "buff", unit = "pet", talent = 126476 }, -- No Hard Feelings
        { spell = 459722, type = "buff", unit = "pet" }, -- Mastery: Spirit Bond
        { spell = 468703, type = "buff", unit = "player" }, -- Serpentine Ryhthm
        { spell = 468704, type = "buff", unit = "player" }, -- Serpentine Blessing
      },
      icon = 132242
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target" }, -- Growl
        { spell = 3355, type = "debuff", unit = "target" }, -- Freezing Trap
        { spell = 5116, type = "debuff", unit = "target", talent = 126471 }, -- Concussive Shot
        { spell = 24394, type = "debuff", unit = "target", talent = 126461 }, -- Intimidation
        { spell = 117405, type = "debuff", unit = "target", talent = 126449 }, -- Binding Shot
        { spell = 131894, type = "debuff", unit = "target", talent = 126414 }, -- A Murder of Crows
        { spell = 135299, type = "debuff", unit = "target", talent = 126457 }, -- Tar Trap
        { spell = 186387, type = "debuff", unit = "target", talent = 126487 }, -- Bursting Shot
        { spell = 195645, type = "debuff", unit = "target" }, -- Wing Clip
        { spell = 212431, type = "debuff", unit = "target", talent = 126485 }, -- Explosive Shot
        { spell = 213691, type = "debuff", unit = "target", talent = 126486 }, -- Scatter Shot
        { spell = 217200, type = "debuff", unit = "target", talent = 126440 }, -- Barbed Shot
        { spell = 236777, type = "debuff", unit = "target", talent = 126830 }, -- High Explosive Trap
        { spell = 257284, type = "debuff", unit = "target" }, -- Hunter's Mark
        { spell = 271788, type = "debuff", unit = "target" }, -- Serpent Sting
        { spell = 321469, type = "debuff", unit = "target", talent = 126451 }, -- Binding Shackles
        { spell = 321538, type = "debuff", unit = "target", talent = 126424 }, -- Bloodshed
        { spell = 393456, type = "debuff", unit = "target", talent = 126467 }, -- Entrapment
        { spell = 424567, type = "debuff", unit = "target", talent = 126401 }, -- Wild Instincts
        { spell = 430703, type = "debuff", unit = "target", herotalent = 117584 }, -- Black Arrow
        { spell = 442396, type = "debuff", unit = "target", herotalent = 117557 }, -- Dark Chains
        { spell = 449233, type = "debuff", unit = "target", herotalent = 117564 }, -- Cull the Herd
        { spell = 459560, type = "debuff", unit = "target", talent = 126432 }, -- Laceration
        { spell = 459668, type = "debuff", unit = "target", talent = 126429 }, -- Venomous Bite
        { spell = 459753, type = "debuff", unit = "target" }, -- Ravenous Leap
        { spell = 462033, type = "debuff", unit = "target", talent = 126829 }, -- Implosive Trap
        { spell = 467745, type = "debuff", unit = "target", herotalent = 128219 }, -- Shadow Dagger
      },
      icon = 135860
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 75, type = "ability", requiresTarget = true }, -- Auto Shot
        { spell = 781, type = "ability" }, -- Disengage
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 2643, type = "ability", requiresTarget = true, usable = true, talent = 126425 }, -- Multi-Shot
        { spell = 2649, type = "ability", debuff = true, requiresTarget = true }, -- Growl
        { spell = 5116, type = "ability", debuff = true, requiresTarget = true, talent = 126471 }, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true, usable = true }, -- Feign Death
        { spell = 17253, type = "ability", requiresTarget = true }, -- Bite
        { spell = 19574, type = "ability", buff = true, talent = 126402 }, -- Bestial Wrath
        { spell = 19577, type = "ability", usable = true, talent = 126461 }, -- Intimidation
        { spell = 19801, type = "ability", requiresTarget = true, usable = true, talent = 126443 }, -- Tranquilizing Shot
        { spell = 34026, type = "ability", charges = true, usable = true, talent = 126408 }, -- Kill Command
        { spell = 34477, type = "ability", buff = true, talent = 126484 }, -- Misdirection
        { spell = 53351, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 126441 }, -- Kill Shot
        { spell = 53480, type = "ability", buff = true, talent = 126469 }, -- Roar of Sacrifice
        { spell = 56641, type = "ability", requiresTarget = true, usable = true }, -- Steady Shot
        { spell = 61684, type = "ability", buff = true, unit = 'pet' }, -- Dash
        { spell = 109248, type = "ability", talent = 126449 }, -- Binding Shot
        { spell = 109304, type = "ability" }, -- Exhilaration
        { spell = 120360, type = "ability", usable = true, talent = 126396 }, -- Barrage
        { spell = 120679, type = "ability", talent = 126439 }, -- Dire Beast
        { spell = 147362, type = "ability", requiresTarget = true, usable = true, talent = 126352 }, -- Counter Shot
        { spell = 186257, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true }, -- Aspect of the Turtle
        { spell = 186387, type = "ability", debuff = true, talent = 126487 }, -- Bursting Shot
        { spell = 187650, type = "ability" }, -- Freezing Trap
        { spell = 187698, type = "ability", talent = 126457 }, -- Tar Trap
        { spell = 193455, type = "ability", requiresTarget = true, usable = true, talent = 126416 }, -- Cobra Shot
        { spell = 195645, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Wing Clip
        { spell = 199483, type = "ability", buff = true, usable = true, talent = 126478 }, -- Camouflage
        { spell = 212431, type = "ability", debuff = true, requiresTarget = true, talent = 126485 }, -- Explosive Shot
        { spell = 213691, type = "ability", debuff = true, talent = 126486 }, -- Scatter Shot
        { spell = 217200, type = "ability", charges = true, debuff = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 126440 }, -- Barbed Shot
        { spell = 236776, type = "ability", talent = 126830 }, -- High Explosive Trap
        { spell = 257284, type = "ability", debuff = true }, -- Hunter's Mark
        { spell = 264667, type = "ability", buff = true }, -- Primal Rage
        { spell = 264735, type = "ability", charges = true, buff = true, talent = 126488 }, -- Survival of the Fittest
        { spell = 272678, type = "ability" }, -- Primal Rage
        { spell = 321530, type = "ability", talent = 126424 }, -- Bloodshed
        { spell = 359844, type = "ability", buff = true, requiresTarget = true, talent = 126397 }, -- Call of the Wild
        { spell = 430703, type = "ability", debuff = true, requiresTarget = true, usable = true, herotalent = 117584 }, -- Black Arrow
        { spell = 462031, type = "ability", talent = 126829 }, -- Implosive Trap
      },
      icon = 135130
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 6197, type = "buff", unit = "player" }, -- Eagle Eye
        { spell = 118922, type = "buff", unit = "player", talent = 126475 }, -- Posthaste
        { spell = 164273, type = "buff", unit = "player", talent = 126360 }, -- Lone Wolf
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 193534, type = "buff", unit = "player", talent = 126353 }, -- Steady Focus
        { spell = 194594, type = "buff", unit = "player", talent = 126384 }, -- Lock and Load
        { spell = 199483, type = "buff", unit = "player", talent = 126478 }, -- Camouflage
        { spell = 202748, type = "buff", unit = "player" }, -- Survival Tactics
        { spell = 204090, type = "buff", unit = "player", talent = 126358 }, -- Bullseye
        { spell = 231390, type = "buff", unit = "player", talent = 126464 }, -- Trailblazer
        { spell = 257622, type = "buff", unit = "player", talent = 126369 }, -- Trick Shots
        { spell = 260242, type = "buff", unit = "player", talent = 126354 }, -- Precise Shots
        { spell = 260243, type = "buff", unit = "player", talent = 126377 }, -- Volley
        { spell = 264663, type = "buff", unit = "player" }, -- Predator's Thirst
        { spell = 264735, type = "buff", unit = "player", talent = 126488 }, -- Survival of the Fittest
        { spell = 288613, type = "buff", unit = "player", talent = 126364 }, -- Trueshot
        { spell = 342076, type = "buff", unit = "player", talent = 126368 }, -- Streamline
        { spell = 378770, type = "buff", unit = "player", talent = 126365 }, -- Deathblow
        { spell = 386877, type = "buff", unit = "player", talent = 126372 }, -- Unerring Vision
        { spell = 388998, type = "buff", unit = "player", talent = 126382 }, -- Razor Fragments
        { spell = 389020, type = "buff", unit = "player", talent = 126363 }, -- Bulletstorm
        { spell = 392956, type = "buff", unit = "player" }, -- Fortitude of the Bear
        { spell = 400456, type = "buff", unit = "player", talent = 126376 }, -- Salvo
        { spell = 407405, type = "buff", unit = "player", talent = 126379 }, -- In the Rhythm
        { spell = 451180, type = "buff", unit = "player", herotalent = 123871 }, -- Eyes Closed
        { spell = 451447, type = "buff", unit = "player", herotalent = 117586 }, -- Don't Look Back
        { spell = 459468, type = "buff", unit = "player", talent = 126448 }, -- Ghillie Suit
        { spell = 459805, type = "buff", unit = "player", talent = 126359 }, -- Wailing Arrow
        { spell = 459919, type = "buff", unit = "player", talent = 126370 }, -- Kill Zone
        { spell = 466991, type = "buff", unit = "player", herotalent = 117590 }, -- Withering Fire
        { spell = 378770, type = "buff", unit = "player", talent = 126474 }, -- Deathblow
        { spell = 264663, type = "buff", unit = "pet" }, -- Predator's Thirst
        { spell = 459722, type = "buff", unit = "pet" }, -- Mastery: Spirit Bond
      },
      icon = 461846
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 3355, type = "debuff", unit = "target" }, -- Freezing Trap
        { spell = 5116, type = "debuff", unit = "target", talent = 126471 }, -- Concussive Shot
        { spell = 24394, type = "debuff", unit = "target", talent = 126461 }, -- Intimidation
        { spell = 135299, type = "debuff", unit = "target", talent = 126457 }, -- Tar Trap
        { spell = 186387, type = "debuff", unit = "target", talent = 126487 }, -- Bursting Shot
        { spell = 195645, type = "debuff", unit = "target" }, -- Wing Clip
        { spell = 212431, type = "debuff", unit = "target", talent = 126485 }, -- Explosive Shot
        { spell = 213691, type = "debuff", unit = "target", talent = 126486 }, -- Scatter Shot
        { spell = 236777, type = "debuff", unit = "target", talent = 126830 }, -- High Explosive Trap
        { spell = 257044, type = "debuff", unit = "target", talent = 126378 }, -- Rapid Fire
        { spell = 257284, type = "debuff", unit = "target" }, -- Hunter's Mark
        { spell = 269576, type = "debuff", unit = "target", talent = 126356 }, -- Master Marksman
        { spell = 271788, type = "debuff", unit = "target" }, -- Serpent Sting
        { spell = 321469, type = "debuff", unit = "target", talent = 126451 }, -- Binding Shackles
        { spell = 385638, type = "debuff", unit = "target", talent = 126382 }, -- Razor Fragments
        { spell = 392061, type = "debuff", unit = "target", talent = 126359 }, -- Wailing Arrow
        { spell = 393456, type = "debuff", unit = "target", talent = 126467 }, -- Entrapment
        { spell = 393480, type = "debuff", unit = "target", talent = 126370 }, -- Kill Zone
        { spell = 430703, type = "debuff", unit = "target", herotalent = 117584 }, -- Black Arrow
        { spell = 450387, type = "debuff", unit = "target", herotalent = 117573 }, -- Sentinel
        { spell = 450845, type = "debuff", unit = "target", herotalent = 123869 }, -- Sideline
        { spell = 450884, type = "debuff", unit = "target", herotalent = 117575 }, -- Lunar Storm
        { spell = 451531, type = "debuff", unit = "target", herotalent = 123870 }, -- Crescent Steel
        { spell = 459796, type = "debuff", unit = "target", talent = 126392 }, -- Barrage
        { spell = 462033, type = "debuff", unit = "target", talent = 126829 }, -- Implosive Trap
        { spell = 467745, type = "debuff", unit = "target", herotalent = 128219 }, -- Shadow Dagger
      },
      icon = 236188
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 781, type = "ability" }, -- Disengage
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 5116, type = "ability", talent = 126471 }, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true, usable = true }, -- Feign Death
        { spell = 19434, type = "ability", charges = true, overlayGlow = true, usable = true, talent = 126357 }, -- Aimed Shot
        { spell = 19577, type = "ability", usable = true, talent = 126461 }, -- Intimidation
        { spell = 19801, type = "ability", usable = true, talent = 126443 }, -- Tranquilizing Shot
        { spell = 34477, type = "ability", talent = 126484 }, -- Misdirection
        { spell = 53351, type = "ability", overlayGlow = true, usable = true, talent = 126463 }, -- Kill Shot
        { spell = 53480, type = "ability", talent = 126469 }, -- Roar of Sacrifice
        { spell = 109248, type = "ability", talent = 126449 }, -- Binding Shot
        { spell = 109304, type = "ability" }, -- Exhilaration
        { spell = 147362, type = "ability", usable = true, talent = 126466 }, -- Counter Shot
        { spell = 185358, type = "ability", charges = true, usable = true }, -- Arcane Shot
        { spell = 186257, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true }, -- Aspect of the Turtle
        { spell = 186387, type = "ability", debuff = true, talent = 126487 }, -- Bursting Shot
        { spell = 187650, type = "ability" }, -- Freezing Trap
        { spell = 187698, type = "ability", talent = 126457 }, -- Tar Trap
        { spell = 195645, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Wing Clip
        { spell = 199483, type = "ability", buff = true, usable = true, talent = 126478 }, -- Camouflage
        { spell = 212431, type = "ability", debuff = true, usable = true, talent = 126485 }, -- Explosive Shot
        { spell = 213691, type = "ability", debuff = true, talent = 126486 }, -- Scatter Shot
        { spell = 236776, type = "ability", talent = 126830 }, -- High Explosive Trap
        { spell = 257044, type = "ability", debuff = true, usable = true, talent = 126378 }, -- Rapid Fire
        { spell = 257284, type = "ability", debuff = true }, -- Hunter's Mark
        { spell = 257620, type = "ability", charges = true, usable = true, talent = 126355 }, -- Multi-Shot
        { spell = 260243, type = "ability", buff = true, talent = 126377 }, -- Volley
        { spell = 264735, type = "ability", charges = true, buff = true, talent = 126488 }, -- Survival of the Fittest
        { spell = 288613, type = "ability", buff = true, talent = 126364 }, -- Trueshot
        { spell = 342049, type = "ability", charges = true, talent = 126383 }, -- Chimaera Shot
        { spell = 392956, type = "ability", buff = true }, -- Fortitude of the Bear
        { spell = 400456, type = "ability", buff = true, talent = 126376 }, -- Salvo
        { spell = 430703, type = "ability", debuff = true, usable = true, herotalent = 117584 }, -- Black Arrow
        { spell = 459796, type = "ability", debuff = true, talent = 126392 }, -- Barrage
        { spell = 462031, type = "ability", talent = 126829 }, -- Implosive Trap
      },
      icon = 132329
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 6197, type = "buff", unit = "player" }, -- Eagle Eye
        { spell = 34477, type = "buff", unit = "player", talent = 126484 }, -- Misdirection
        { spell = 53480, type = "buff", unit = "player", talent = 126469 }, -- Roar of Sacrifice
        { spell = 118922, type = "buff", unit = "player", talent = 126475 }, -- Posthaste
        { spell = 186257, type = "buff", unit = "player" }, -- Aspect of the Cheetah
        { spell = 186265, type = "buff", unit = "player" }, -- Aspect of the Turtle
        { spell = 186289, type = "buff", unit = "player" }, -- Aspect of the Eagle
        { spell = 199483, type = "buff", unit = "player", talent = 126478 }, -- Camouflage
        { spell = 231390, type = "buff", unit = "player", talent = 126464 }, -- Trailblazer
        { spell = 259388, type = "buff", unit = "player" }, -- Mongoose Fury
        { spell = 260249, type = "buff", unit = "player", talent = 126330 }, -- Bloodseeker
        { spell = 260286, type = "buff", unit = "player", talent = 126323 }, -- Tip of the Spear
        { spell = 264663, type = "buff", unit = "player" }, -- Predator's Thirst
        { spell = 264735, type = "buff", unit = "player", talent = 126488 }, -- Survival of the Fittest
        { spell = 265898, type = "buff", unit = "player", talent = 126315 }, -- Terms of Engagement
        { spell = 360952, type = "buff", unit = "player", talent = 126311 }, -- Coordinated Assault
        { spell = 431917, type = "buff", unit = "player", herotalent = 117588 }, -- Vicious Hunt
        { spell = 447262, type = "buff", unit = "player", herotalent = 117585 }, -- Frenzied Tear
        { spell = 448777, type = "buff", unit = "player", herotalent = 117569 }, -- Den Recovery
        { spell = 448814, type = "buff", unit = "player", herotalent = 117576 }, -- Furious Assault
        { spell = 451180, type = "buff", unit = "player", herotalent = 123871 }, -- Eyes Closed
        { spell = 451447, type = "buff", unit = "player", herotalent = 117586 }, -- Don't Look Back
        { spell = 452101, type = "buff", unit = "player", herotalent = 123782 }, -- Cornered Prey
        { spell = 459468, type = "buff", unit = "player", talent = 126448 }, -- Ghillie Suit
        { spell = 459722, type = "buff", unit = "player" }, -- Mastery: Spirit Bond
        { spell = 459830, type = "buff", unit = "player", talent = 126326 }, -- Sulfur-Lined Pockets
        { spell = 459859, type = "buff", unit = "player", talent = 126333 }, -- Bombardier
        { spell = 459864, type = "buff", unit = "player", talent = 126331 }, -- Exposed Flank
        { spell = 461409, type = "buff", unit = "player" }, -- Sic' Em
        { spell = 462515, type = "buff", unit = "player", herotalent = 117589 }, -- Howl of the Pack
        { spell = 470070, type = "buff", unit = "player", talent = 126321 }, -- Ruthless Marauder
        { spell = 136, type = "buff", unit = "pet" }, -- Mend Pet
        { spell = 61684, type = "buff", unit = "pet" }, -- Dash
        { spell = 445695, type = "buff", unit = "pet", herotalent = 117582 }, -- Pack Coordination
        { spell = 459547, type = "buff", unit = "pet", talent = 126476 }, -- No Hard Feelings
      },
      icon = 1376044
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 2649, type = "debuff", unit = "target" }, -- Growl
        { spell = 3355, type = "debuff", unit = "target" }, -- Freezing Trap
        { spell = 5116, type = "debuff", unit = "target", talent = 126471 }, -- Concussive Shot
        { spell = 24394, type = "debuff", unit = "target", talent = 126461 }, -- Intimidation
        { spell = 135299, type = "debuff", unit = "target", talent = 126457 }, -- Tar Trap
        { spell = 190925, type = "debuff", unit = "target" }, -- Harpoon
        { spell = 195645, type = "debuff", unit = "target" }, -- Wing Clip
        { spell = 212431, type = "debuff", unit = "target", talent = 126485 }, -- Explosive Shot
        { spell = 213691, type = "debuff", unit = "target", talent = 126486 }, -- Scatter Shot
        { spell = 236777, type = "debuff", unit = "target", talent = 126830 }, -- High Explosive Trap
        { spell = 257284, type = "debuff", unit = "target" }, -- Hunter's Mark
        { spell = 259277, type = "debuff", unit = "target", talent = 126314 }, -- Kill Command
        { spell = 259491, type = "debuff", unit = "target" }, -- Serpent Sting
        { spell = 269747, type = "debuff", unit = "target", talent = 126324 }, -- Wildfire Bomb
        { spell = 321469, type = "debuff", unit = "target", talent = 126451 }, -- Binding Shackles
        { spell = 378957, type = "debuff", unit = "target", talent = 126351 }, -- Spearhead
        { spell = 393456, type = "debuff", unit = "target", talent = 126467 }, -- Entrapment
        { spell = 449233, type = "debuff", unit = "target", herotalent = 117564 }, -- Cull the Herd
        { spell = 450387, type = "debuff", unit = "target", herotalent = 117573 }, -- Sentinel
        { spell = 450845, type = "debuff", unit = "target", herotalent = 123869 }, -- Sideline
        { spell = 450884, type = "debuff", unit = "target", herotalent = 117575 }, -- Lunar Storm
        { spell = 451531, type = "debuff", unit = "target", herotalent = 123870 }, -- Crescent Steel
        { spell = 462033, type = "debuff", unit = "target", talent = 126829 }, -- Implosive Trap
        { spell = 459870, type = "debuff", unit = "target", talent = 126327 }, -- Merciless Blow
      },
      icon = 132309
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 75, type = "ability" }, -- Auto Shot
        { spell = 781, type = "ability" }, -- Disengage
        { spell = 1543, type = "ability" }, -- Flare
        { spell = 2649, type = "ability", debuff = true, requiresTarget = true }, -- Growl
        { spell = 5116, type = "ability", debuff = true, talent = 126471 }, -- Concussive Shot
        { spell = 5384, type = "ability", buff = true, usable = true }, -- Feign Death
        { spell = 17253, type = "ability", requiresTarget = true }, -- Bite
        { spell = 19577, type = "ability", usable = true, talent = 126461 }, -- Intimidation
        { spell = 19801, type = "ability", talent = 126443 }, -- Tranquilizing Shot
        { spell = 34477, type = "ability", buff = true, talent = 126484 }, -- Misdirection
        { spell = 53480, type = "ability", buff = true, talent = 126469 }, -- Roar of Sacrifice
        { spell = 61684, type = "ability", buff = true, unit = 'pet' }, -- Dash
        { spell = 109248, type = "ability", talent = 126449 }, -- Binding Shot
        { spell = 109304, type = "ability" }, -- Exhilaration
        { spell = 186257, type = "ability", buff = true }, -- Aspect of the Cheetah
        { spell = 186265, type = "ability", buff = true }, -- Aspect of the Turtle
        { spell = 186270, type = "ability", overlayGlow = true, requiresTarget = true, talent = 126322 }, -- Raptor Strike
        { spell = 186289, type = "ability", buff = true }, -- Aspect of the Eagle
        { spell = 186387, type = "ability", talent = 126487 }, -- Bursting Shot
        { spell = 187650, type = "ability" }, -- Freezing Trap
        { spell = 187698, type = "ability", talent = 126457 }, -- Tar Trap
        { spell = 187707, type = "ability", requiresTarget = true, usable = true, talent = 100543 }, -- Muzzle
        { spell = 190925, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Harpoon
        { spell = 195645, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Wing Clip
        { spell = 199483, type = "ability", buff = true,  usable = true, talent = 126478 }, -- Camouflage
        { spell = 203415, type = "ability", usable = true, talent = 126335 }, -- Fury of the Eagle
        { spell = 212431, type = "ability", debuff = true, overlayGlow = true, usable = true, talent = 126485 }, -- Explosive Shot
        { spell = 212436, type = "ability", usable = true, talent = 126350 }, -- Butchery
        { spell = 213691, type = "ability", debuff = true, talent = 126486 }, -- Scatter Shot
        { spell = 236776, type = "ability", talent = 126830 }, -- High Explosive Trap
        { spell = 257284, type = "ability", debuff = true }, -- Hunter's Mark
        { spell = 259387, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 126316 }, -- Mongoose Bite
        { spell = 259489, type = "ability", charges = true, overlayGlow = true, usable = true, talent = 126314 }, -- Kill Command
        { spell = 259495, type = "ability", charges = true, usable = true, talent = 126324 }, -- Wildfire Bomb
        { spell = 264667, type = "ability" }, -- Primal Rage
        { spell = 264735, type = "ability", charges = true, buff = true, talent = 126488 }, -- Survival of the Fittest
        { spell = 269751, type = "ability", requiresTarget = true, usable = true, talent = 126338 }, -- Flanking Strike
        { spell = 272678, type = "ability" }, -- Primal Rage
        { spell = 320976, type = "ability", overlayGlow = true, usable = true, talent = 126442 }, -- Kill Shot
        { spell = 360952, type = "ability", buff = true, usable = true, talent = 126311 }, -- Coordinated Assault
        { spell = 360966, type = "ability", usable = true, talent = 126351 }, -- Spearhead
        { spell = 462031, type = "ability", talent = 126829 }, -- Implosive Trap
      },
      icon = 236184
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 1966, type = "buff", unit = "player" }, -- Feint
        { spell = 2823, type = "buff", unit = "player", talent = 112676 }, -- Deadly Poison
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 3408, type = "buff", unit = "player" }, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player", talent = 112657 }, -- Evasion
        { spell = 5761, type = "buff", unit = "player", talent = 112656 }, -- Numbing Poison
        { spell = 8679, type = "buff", unit = "player" }, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 31224, type = "buff", unit = "player", talent = 112585 }, -- Cloak of Shadows
        { spell = 32645, type = "buff", unit = "player" }, -- Envenom
        { spell = 36554, type = "buff", unit = "player" }, -- Shadowstep
        { spell = 108211, type = "buff", unit = "player", talent = 112650 }, -- Leeching Poison
        { spell = 114018, type = "buff", unit = "player" }, -- Shroud of Concealment
        { spell = 115192, type = "buff", unit = "player", talent = 112576 }, -- Subterfuge
        { spell = 121153, type = "buff", unit = "player", talent = 112679 }, -- Blindside
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 193538, type = "buff", unit = "player", talent = 112643 }, -- Alacrity
        { spell = 256735, type = "buff", unit = "player", talent = 112508 }, -- Master Assassin
        { spell = 315496, type = "buff", unit = "player" }, -- Slice and Dice
        { spell = 315584, type = "buff", unit = "player" }, -- Instant Poison
        { spell = 323559, type = "buff", unit = "player", talent = 112525 }, -- Echoing Reprimand
        { spell = 381623, type = "buff", unit = "player", talent = 112648 }, -- Thistle Tea
        { spell = 381637, type = "buff", unit = "player", talent = 112655 }, -- Atrophic Poison
        { spell = 381664, type = "buff", unit = "player", talent = 112505 }, -- Amplifying Poison
        { spell = 382245, type = "buff", unit = "player", talent = 112639 }, -- Cold Blood
        { spell = 385747, type = "buff", unit = "player", talent = 112667 }, -- Indiscriminate Carnage
        { spell = 392401, type = "buff", unit = "player", talent = 112673 }, -- Improved Garrote
        { spell = 393971, type = "buff", unit = "player", talent = 112579 }, -- Soothing Darkness
        { spell = 394080, type = "buff", unit = "player", talent = 112668 }, -- Scent of Blood
        { spell = 452562, type = "buff", unit = "player" }, -- Lucky Coin
        { spell = 452917, type = "buff", unit = "player" }, -- Fatebound Coin (Tails)
        { spell = 452923, type = "buff", unit = "player" }, -- Fatebound Coin (Heads)
        { spell = 455144, type = "buff", unit = "player", talent = 112644 }, -- Acrobatic Strikes
        { spell = 455366, type = "buff", unit = "player" }, -- Serrated Bone Spike
        { spell = 457115, type = "buff", unit = "player", herotalent = 117728 }, -- Momentum of Despair
        { spell = 457160, type = "buff", unit = "player", herotalent = 117733 }, -- Deathstalker's Mark
        { spell = 457167, type = "buff", unit = "player", herotalent = 126030 }, -- Symbolic Victory
        { spell = 457178, type = "buff", unit = "player", herotalent = 117707 }, -- Clear the Witnesses
        { spell = 457273, type = "buff", unit = "player", herotalent = 117706 }, -- Lingering Darkness
        { spell = 457280, type = "buff", unit = "player", herotalent = 117739 }, -- Darkest Night
      },
      icon = 132290
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 703, type = "debuff", unit = "target" }, -- Garrote
        { spell = 1330, type = "debuff", unit = "target" }, -- Garrote - Silence
        { spell = 1776, type = "debuff", unit = "target", talent = 112631 }, -- Gouge
        { spell = 1833, type = "debuff", unit = "target" }, -- Cheap Shot
        { spell = 1943, type = "debuff", unit = "target" }, -- Rupture
        { spell = 2094, type = "debuff", unit = "target", talent = 112572 }, -- Blind
        { spell = 2818, type = "debuff", unit = "target", talent = 112676 }, -- Deadly Poison
        { spell = 3409, type = "debuff", unit = "target" }, -- Crippling Poison
        { spell = 5760, type = "debuff", unit = "target", talent = 112656 }, -- Numbing Poison
        { spell = 8680, type = "debuff", unit = "target" }, -- Wound Poison
        { spell = 121411, type = "debuff", unit = "target", talent = 112517 }, -- Crimson Tempest
        { spell = 256148, type = "debuff", unit = "target", talent = 117134 }, -- Iron Wire
        { spell = 319504, type = "debuff", unit = "target", talent = 112630 }, -- Shiv
        { spell = 360194, type = "debuff", unit = "target", talent = 112662 }, -- Deathmark
        { spell = 381628, type = "debuff", unit = "target", talent = 117136 }, -- Internal Bleeding
        { spell = 383414, type = "debuff", unit = "target", talent = 112505 }, -- Amplifying Poison
        { spell = 385627, type = "debuff", unit = "target", talent = 117130 }, -- Kingsbane
        { spell = 392388, type = "debuff", unit = "target", talent = 112655 }, -- Atrophic Poison
        { spell = 394021, type = "debuff", unit = "target" }, -- Mutilated Flesh
        { spell = 394036, type = "debuff", unit = "target" }, -- Serrated Bone Spike
        { spell = 394119, type = "debuff", unit = "target", talent = 117143 }, -- Blackjack
        { spell = 421976, type = "debuff", unit = "target", talent = 117137 }, -- Caustic Spatter
        { spell = 457129, type = "debuff", unit = "target", herotalent = 117733 }, -- Deathstalker's Mark
        { spell = 457133, type = "debuff", unit = "target", herotalent = 117705 }, -- Corrupt the Blood
        { spell = 461981, type = "debuff", unit = "target", herotalent = 117732 }, -- Fatal Intent
      },
      icon = 132302
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, type = "ability", debuff = true, requiresTarget = true }, -- Kidney Shot
        { spell = 703, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Garrote
        { spell = 921, type = "ability", requiresTarget = true, usable = true }, -- Pick Pocket
        { spell = 1329, type = "ability", requiresTarget = true }, -- Mutilate
        { spell = 1725, type = "ability" }, -- Distract
        { spell = 1766, type = "ability", requiresTarget = true }, -- Kick
        { spell = 1776, type = "ability", debuff = true, requiresTarget = true, talent = 112631 }, -- Gouge
        { spell = 1784, type = "ability", buff = true, usable = true }, -- Stealth
        { spell = 1833, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Cheap Shot
        { spell = 1856, type = "ability", charges = true }, -- Vanish
        { spell = 1943, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Rupture
        { spell = 1966, type = "ability", charges = true, buff = true }, -- Feint
        { spell = 2094, type = "ability", debuff = true, requiresTarget = true, talent = 112572 }, -- Blind
        { spell = 2983, type = "ability", buff = true }, -- Sprint
        { spell = 5277, type = "ability", buff = true, talent = 112657 }, -- Evasion
        { spell = 5938, type = "ability", charges = true, requiresTarget = true, talent = 112630 }, -- Shiv
        { spell = 8676, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Ambush
        { spell = 31224, type = "ability", buff = true, talent = 112585 }, -- Cloak of Shadows
        { spell = 32645, type = "ability", buff = true, requiresTarget = true }, -- Envenom
        { spell = 36554, type = "ability", charges = true, buff = true, requiresTarget = true }, -- Shadowstep
        { spell = 114018, type = "ability", buff = true, usable = true }, -- Shroud of Concealment
        { spell = 185311, type = "ability", buff = true }, -- Crimson Vial
        { spell = 360194, type = "ability", debuff = true, requiresTarget = true, talent = 112662 }, -- Deathmark
        { spell = 381623, type = "ability", charges = true, buff = true, talent = 112648 }, -- Thistle Tea
        { spell = 382245, type = "ability", buff = true, usable = true, talent = 112639 }, -- Cold Blood
        { spell = 385616, type = "ability", requiresTarget = true, talent = 112525 }, -- Echoing Reprimand
        { spell = 385627, type = "ability", debuff = true, requiresTarget = true, talent = 117130 }, -- Kingsbane
      },
      icon = 132350
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 1966, type = "buff", unit = "player" }, -- Feint
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 3408, type = "buff", unit = "player" }, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player", talent = 112657 }, -- Evasion
        { spell = 5761, type = "buff", unit = "player", talent = 112656 }, -- Numbing Poison
        { spell = 8679, type = "buff", unit = "player" }, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 13750, type = "buff", unit = "player", talent = 112545 }, -- Adrenaline Rush
        { spell = 13877, type = "buff", unit = "player" }, -- Blade Flurry
        { spell = 31224, type = "buff", unit = "player", talent = 112585 }, -- Cloak of Shadows
        { spell = 51690, type = "buff", unit = "player", talent = 117149 }, -- Killing Spree
        { spell = 108211, type = "buff", unit = "player", talent = 112650 }, -- Leeching Poison
        { spell = 114018, type = "buff", unit = "player" }, -- Shroud of Concealment
        { spell = 115192, type = "buff", unit = "player", talent = 112576 }, -- Subterfuge
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 193356, type = "buff", unit = "player" }, -- Broadside
        { spell = 193357, type = "buff", unit = "player" }, -- Ruthless Precision
        { spell = 193358, type = "buff", unit = "player" }, -- Grand Melee
        { spell = 193359, type = "buff", unit = "player" }, -- True Bearing
        { spell = 193538, type = "buff", unit = "player", talent = 112643 }, -- Alacrity
        { spell = 195627, type = "buff", unit = "player", talent = 112571 }, -- Opportunity
        { spell = 199600, type = "buff", unit = "player" }, -- Buried Treasure
        { spell = 199603, type = "buff", unit = "player" }, -- Skull and Crossbones
        { spell = 256171, type = "buff", unit = "player", talent = 112542 }, -- Loaded Dice
        { spell = 271896, type = "buff", unit = "player", talent = 112551 }, -- Blade Rush
        { spell = 315341, type = "buff", unit = "player" }, -- Between the Eyes
        { spell = 315584, type = "buff", unit = "player" }, -- Instant Poison
        { spell = 323559, type = "buff", unit = "player", talent = 112525 }, -- Echoing Reprimand
        { spell = 381623, type = "buff", unit = "player", talent = 112648 }, -- Thistle Tea
        { spell = 381637, type = "buff", unit = "player", talent = 112655 }, -- Atrophic Poison
        { spell = 385907, type = "buff", unit = "player", talent = 112563 }, -- Take 'em by Surprise
        { spell = 386270, type = "buff", unit = "player", talent = 112527 }, -- Audacity
        { spell = 386868, type = "buff", unit = "player", talent = 112539 }, -- Summarily Dispatched
        { spell = 393971, type = "buff", unit = "player", talent = 112579 }, -- Soothing Darkness
        { spell = 441326, type = "buff", unit = "player", herotalent = 117708 }, -- Flawless Form
        { spell = 441640, type = "buff", unit = "player" }, -- Smokescreen
        { spell = 441776, type = "buff", unit = "player", herotalent = 117712 }, -- Coup de Grace
        { spell = 441786, type = "buff", unit = "player" }, -- Escalating Blade
        { spell = 452562, type = "buff", unit = "player" }, -- Lucky Coin
        { spell = 452917, type = "buff", unit = "player" }, -- Fatebound Coin (Tails)
        { spell = 452923, type = "buff", unit = "player" }, -- Fatebound Coin (Heads)
        { spell = 455144, type = "buff", unit = "player", talent = 112644 }, -- Acrobatic Strikes
        { spell = 456330, type = "buff", unit = "player", talent = 112639 }, -- Cold Blood
        { spell = 457343, type = "buff", unit = "player", herotalent = 125140 }, -- Death's Arrival
      },
      icon = 132350
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 1776, type = "debuff", unit = "target", talent = 112631 }, -- Gouge
        { spell = 2094, type = "debuff", unit = "target", talent = 112572 }, -- Blind
        { spell = 3409, type = "debuff", unit = "target" }, -- Crippling Poison
        { spell = 5760, type = "debuff", unit = "target", talent = 112656 }, -- Numbing Poison
        { spell = 8680, type = "debuff", unit = "target" }, -- Wound Poison
        { spell = 185763, type = "debuff", unit = "target" }, -- Pistol Shot
        { spell = 196937, type = "debuff", unit = "target", talent = 117162 }, -- Ghostly Strike
        { spell = 255909, type = "debuff", unit = "target" }, -- Stinging Vulnerability
        { spell = 392388, type = "debuff", unit = "target", talent = 112655 }, -- Atrophic Poison
        { spell = 394036, type = "debuff", unit = "target" }, -- Serrated Bone Spike
        { spell = 394119, type = "debuff", unit = "target", talent = 117143 }, -- Blackjack
        { spell = 441224, type = "debuff", unit = "target" }, -- Fazed
      },
      icon = 1373908
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 408, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Kidney Shot
        { spell = 921, type = "ability", requiresTarget = true, usable = true }, -- Pick Pocket
        { spell = 1725, type = "ability", usable = true }, -- Distract
        { spell = 1766, type = "ability", requiresTarget = true, usable = true }, -- Kick
        { spell = 1776, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 112631 }, -- Gouge
        { spell = 1784, type = "ability", buff = true, usable = true }, -- Stealth
        { spell = 1833, type = "ability", requiresTarget = true, usable = true }, -- Cheap Shot
        { spell = 1856, type = "ability", charges = true, usable = true }, -- Vanish
        { spell = 1966, type = "ability", charges = true, buff = true, usable = true }, -- Feint
        { spell = 2094, type = "ability", debuff = true, usable = true, talent = 112572 }, -- Blind
        { spell = 2098, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Dispatch
        { spell = 2983, type = "ability", buff = true, usable = true }, -- Sprint
        { spell = 5277, type = "ability", buff = true, usable = true, talent = 112657 }, -- Evasion
        { spell = 5938, type = "ability", requiresTarget = true, usable = true, talent = 112630 }, -- Shiv
        { spell = 8676, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Ambush
        { spell = 13750, type = "ability", buff = true, usable = true, talent = 112545 }, -- Adrenaline Rush
        { spell = 13877, type = "ability", buff = true, usable = true }, -- Blade Flurry
        { spell = 31224, type = "ability", buff = true, usable = true, talent = 112585 }, -- Cloak of Shadows
        { spell = 51690, type = "ability", buff = true, requiresTarget = true, usable = true, talent = 117149 }, -- Killing Spree
        { spell = 114018, type = "ability", buff = true, usable = true }, -- Shroud of Concealment
        { spell = 185311, type = "ability", buff = true, usable = true }, -- Crimson Vial
        { spell = 193315, type = "ability", requiresTarget = true, usable = true }, -- Sinister Strike
        { spell = 195457, type = "ability", charges = true, overlayGlow = true, usable = true }, -- Grappling Hook
        { spell = 196937, type = "ability", debuff = true, requiresTarget = true, talent = 117162 }, -- Ghostly Strike
        { spell = 271877, type = "ability", usable = true, talent = 112551 }, -- Blade Rush
        { spell = 315341, type = "ability", buff = true, usable = true }, -- Between the Eyes
        { spell = 315508, type = "ability", usable = true }, -- Roll the Bones
        { spell = 381623, type = "ability", charges = true, buff = true, usable = true, talent = 112648 }, -- Thistle Tea
        { spell = 381989, type = "ability", usable = true, talent = 112538 }, -- Keep It Rolling
        { spell = 385616, type = "ability", requiresTarget = true, usable = true, talent = 112525 }, -- Echoing Reprimand
        { spell = 441587, type = "ability" }, -- Distract
        { spell = 456330, type = "ability", buff = true, talent = 112639 }, -- Cold Blood
      },
      icon = 135610
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 1966, type = "buff", unit = "player" }, -- Feint
        { spell = 2983, type = "buff", unit = "player" }, -- Sprint
        { spell = 3408, type = "buff", unit = "player" }, -- Crippling Poison
        { spell = 5277, type = "buff", unit = "player", talent = 112657 }, -- Evasion
        { spell = 5761, type = "buff", unit = "player", talent = 112656 }, -- Numbing Poison
        { spell = 8679, type = "buff", unit = "player" }, -- Wound Poison
        { spell = 11327, type = "buff", unit = "player" }, -- Vanish
        { spell = 31224, type = "buff", unit = "player", talent = 112585 }, -- Cloak of Shadows
        { spell = 36554, type = "buff", unit = "player" }, -- Shadowstep
        { spell = 108211, type = "buff", unit = "player", talent = 112650 }, -- Leeching Poison
        { spell = 114018, type = "buff", unit = "player" }, -- Shroud of Concealment
        { spell = 115192, type = "buff", unit = "player", talent = 112576 }, -- Subterfuge
        { spell = 121471, type = "buff", unit = "player", talent = 112614 }, -- Shadow Blades
        { spell = 185311, type = "buff", unit = "player" }, -- Crimson Vial
        { spell = 185422, type = "buff", unit = "player" }, -- Shadow Dance
        { spell = 193538, type = "buff", unit = "player", talent = 112643 }, -- Alacrity
        { spell = 196911, type = "buff", unit = "player" }, -- Shadow Techniques
        { spell = 196980, type = "buff", unit = "player", talent = 112624 }, -- Master of Shadows
        { spell = 212283, type = "buff", unit = "player" }, -- Symbols of Death
        { spell = 257506, type = "buff", unit = "player", talent = 112586 }, -- Shot in the Dark
        { spell = 277925, type = "buff", unit = "player", talent = 112604 }, -- Shuriken Tornado
        { spell = 315496, type = "buff", unit = "player" }, -- Slice and Dice
        { spell = 315584, type = "buff", unit = "player" }, -- Instant Poison
        { spell = 323559, type = "buff", unit = "player", talent = 112525 }, -- Echoing Reprimand
        { spell = 343173, type = "buff", unit = "player", talent = 112627 }, -- Premeditation
        { spell = 381623, type = "buff", unit = "player", talent = 112648 }, -- Thistle Tea
        { spell = 381637, type = "buff", unit = "player", talent = 112655 }, -- Atrophic Poison
        { spell = 382245, type = "buff", unit = "player", talent = 112639 }, -- Cold Blood
        { spell = 383405, type = "buff", unit = "player", talent = 112609 }, -- Deeper Daggers
        { spell = 384631, type = "buff", unit = "player", talent = 112606 }, -- Flagellation
        { spell = 385727, type = "buff", unit = "player", talent = 112602 }, -- Silent Storm
        { spell = 385948, type = "buff", unit = "player" }, -- Finality: Black Powder
        { spell = 385949, type = "buff", unit = "player" }, -- Finality: Eviscerate
        { spell = 385951, type = "buff", unit = "player" }, -- Finality: Rupture
        { spell = 385960, type = "buff", unit = "player", talent = 112619 }, -- Lingering Shadow
        { spell = 386165, type = "buff", unit = "player", talent = 112622 }, -- Cloaked in Shadows
        { spell = 386237, type = "buff", unit = "player", talent = 112621 }, -- Fade to Nothing
        { spell = 393969, type = "buff", unit = "player", talent = 112618 }, -- Danse Macabre
        { spell = 393971, type = "buff", unit = "player", talent = 112579 }, -- Soothing Darkness
        { spell = 394203, type = "buff", unit = "player", talent = 112593 }, -- The Rotten
        { spell = 394254, type = "buff", unit = "player", talent = 112595 }, -- Perforated Veins
        { spell = 426593, type = "buff", unit = "player", talent = 117169 }, -- Goremaw's Bite
        { spell = 428389, type = "buff", unit = "player", talent = 117753 }, -- Terrifying Pace
        { spell = 428488, type = "buff", unit = "player", talent = 112599 }, -- Exhilarating Execution
        { spell = 441326, type = "buff", unit = "player", herotalent = 117708 }, -- Flawless Form
        { spell = 441640, type = "buff", unit = "player" }, -- Smokescreen
        { spell = 441776, type = "buff", unit = "player", herotalent = 117712 }, -- Coup de Grace
        { spell = 441786, type = "buff", unit = "player" }, -- Escalating Blade
        { spell = 455144, type = "buff", unit = "player", talent = 112644 }, -- Acrobatic Strikes
        { spell = 457115, type = "buff", unit = "player", herotalent = 117728 }, -- Momentum of Despair
        { spell = 457160, type = "buff", unit = "player", herotalent = 117733 }, -- Deathstalker's Mark
        { spell = 457167, type = "buff", unit = "player", herotalent = 126030 }, -- Symbolic Victory
        { spell = 457178, type = "buff", unit = "player", herotalent = 117707 }, -- Clear the Witnesses
        { spell = 457273, type = "buff", unit = "player", herotalent = 117706 }, -- Lingering Darkness
        { spell = 457280, type = "buff", unit = "player", herotalent = 117739 }, -- Darkest Night
        { spell = 470677, type = "buff", unit = "player", talent = 112625 }, -- The First Dance
      },
      icon = 376022
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 408, type = "debuff", unit = "target" }, -- Kidney Shot
        { spell = 1776, type = "debuff", unit = "target", talent = 112631 }, -- Gouge
        { spell = 1943, type = "debuff", unit = "target" }, -- Rupture
        { spell = 2094, type = "debuff", unit = "target", talent = 112572 }, -- Blind
        { spell = 3409, type = "debuff", unit = "target" }, -- Crippling Poison
        { spell = 5760, type = "debuff", unit = "target", talent = 112656 }, -- Numbing Poison
        { spell = 8680, type = "debuff", unit = "target" }, -- Wound Poison
        { spell = 206760, type = "debuff", unit = "target" }, -- Shadow's Grasp
        { spell = 316220, type = "debuff", unit = "target", talent = 112578 }, -- Find Weakness
        { spell = 384631, type = "debuff", unit = "target", talent = 112606 }, -- Flagellation
        { spell = 392388, type = "debuff", unit = "target", talent = 112655 }, -- Atrophic Poison
        { spell = 394119, type = "debuff", unit = "target", talent = 117143 }, -- Blackjack
        { spell = 441224, type = "debuff", unit = "target" }, -- Fazed
        { spell = 457129, type = "debuff", unit = "target", herotalent = 117733 }, -- Deathstalker's Mark
        { spell = 457133, type = "debuff", unit = "target", herotalent = 117705 }, -- Corrupt the Blood
        { spell = 461981, type = "debuff", unit = "target", herotalent = 117732 }, -- Fatal Intent
      },
      icon = 136175
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 53, type = "ability", requiresTarget = true, usable = true }, -- Backstab
        { spell = 408, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Kidney Shot
        { spell = 921, type = "ability", requiresTarget = true, usable = true }, -- Pick Pocket
        { spell = 1725, type = "ability" }, -- Distract
        { spell = 1766, type = "ability", requiresTarget = true, usable = true }, -- Kick
        { spell = 1776, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 112631 }, -- Gouge
        { spell = 1784, type = "ability", buff = true, usable = true }, -- Stealth
        { spell = 1833, type = "ability", requiresTarget = true, usable = true }, -- Cheap Shot
        { spell = 1856, type = "ability", charges = true, usable = true }, -- Vanish
        { spell = 1943, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Rupture
        { spell = 1966, type = "ability", charges = true, buff = true, usable = true }, -- Feint
        { spell = 2094, type = "ability", debuff = true, usable = true, talent = 112572 }, -- Blind
        { spell = 2983, type = "ability", buff = true, usable = true }, -- Sprint
        { spell = 5277, type = "ability", buff = true, usable = true, talent = 112657 }, -- Evasion
        { spell = 5938, type = "ability", requiresTarget = true, usable = true, talent = 112630 }, -- Shiv
        { spell = 31224, type = "ability", buff = true, usable = true, talent = 112585 }, -- Cloak of Shadows
        { spell = 36554, type = "ability", charges = true, buff = true, usable = true }, -- Shadowstep
        { spell = 114018, type = "ability", buff = true, usable = true }, -- Shroud of Concealment
        { spell = 121471, type = "ability", buff = true, usable = true, talent = 112614 }, -- Shadow Blades
        { spell = 185311, type = "ability", buff = true, usable = true }, -- Crimson Vial
        { spell = 185313, type = "ability", charges = true, usable = true }, -- Shadow Dance
        { spell = 185438, type = "ability", requiresTarget = true, usable = true }, -- Shadowstrike
        { spell = 196819, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Eviscerate
        { spell = 200758, type = "ability", requiresTarget = true, usable = true, talent = 112587 }, -- Gloomblade
        { spell = 212283, type = "ability", buff = true, usable = true }, -- Symbols of Death
        { spell = 277925, type = "ability", buff = true, talent = 112604 }, -- Shuriken Tornado
        { spell = 280719, type = "ability", requiresTarget = true, usable = true, talent = 112603 }, -- Secret Technique
        { spell = 381623, type = "ability", charges = true, buff = true, talent = 112648 }, -- Thistle Tea
        { spell = 382245, type = "ability", buff = true, usable = true, talent = 112639 }, -- Cold Blood
        { spell = 384631, type = "ability", buff = true, debuff = true, requiresTarget = true, talent = 112606 }, -- Flagellation
        { spell = 385616, type = "ability", requiresTarget = true, talent = 112525 }, -- Echoing Reprimand
        { spell = 426591, type = "ability", requiresTarget = true, talent = 117169 }, -- Goremaw's Bite
        { spell = 441587, type = "ability" }, -- Distract
      },
      icon = 236279
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 139, type = "buff", unit = "player", talent = 103869 }, -- Renew
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 2096, type = "buff", unit = "player" }, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player", talent = 103844 }, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player", talent = 103841 }, -- Vampiric Embrace
        { spell = 19236, type = "buff", unit = "player" }, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player" }, -- Power Word: Fortitude
        { spell = 33206, type = "buff", unit = "player", talent = 103713 }, -- Pain Suppression
        { spell = 41635, type = "buff", unit = "player", talent = 103870 }, -- Prayer of Mending
        { spell = 47536, type = "buff", unit = "player", talent = 103727 }, -- Rapture
        { spell = 47753, type = "buff", unit = "player", talent = 103732 }, -- Divine Aegis
        { spell = 65081, type = "buff", unit = "player", talent = 103856 }, -- Body and Soul
        { spell = 81782, type = "buff", unit = "player", talent = 103687 }, -- Power Word: Barrier
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 121557, type = "buff", unit = "player", talent = 103853 }, -- Angelic Feather
        { spell = 193065, type = "buff", unit = "player", talent = 103858 }, -- Protective Light
        { spell = 194384, type = "buff", unit = "player", talent = 103723 }, -- Atonement
        { spell = 198069, type = "buff", unit = "player", talent = 103724 }, -- Power of the Dark Side
        { spell = 271466, type = "buff", unit = "player", talent = 116182 }, -- Luminous Barrier
        { spell = 280398, type = "buff", unit = "player" }, -- Sins of the Many
        { spell = 290793, type = "buff", unit = "player" }, -- Trinity
        { spell = 322105, type = "buff", unit = "player", talent = 103706 }, -- Shadow Covenant
        { spell = 355851, type = "buff", unit = "player", talent = 103693 }, -- Blaze of Light
        { spell = 373183, type = "buff", unit = "player", talent = 103697 }, -- Harsh Discipline
        { spell = 390617, type = "buff", unit = "player", talent = 103857 }, -- From Darkness Comes Light
        { spell = 390636, type = "buff", unit = "player", talent = 103850 }, -- Rhapsody
        { spell = 390692, type = "buff", unit = "player", talent = 103729 }, -- Borrowed Time
        { spell = 390706, type = "buff", unit = "player", talent = 103696 }, -- Twilight Equilibrium
        { spell = 390787, type = "buff", unit = "player", talent = 103694 }, -- Weal and Woe
        { spell = 390933, type = "buff", unit = "player", talent = 103873 }, -- Words of the Pious
        { spell = 390978, type = "buff", unit = "player", talent = 103833 }, -- Twist of Fate
        { spell = 421453, type = "buff", unit = "player", talent = 103700 }, -- Ultimate Penitence
        { spell = 428930, type = "buff", unit = "player" }, -- Premonition of Piety
        { spell = 428933, type = "buff", unit = "player" }, -- Premonition of Insight
        { spell = 428934, type = "buff", unit = "player" }, -- Premonition of Solace
        { spell = 440683, type = "buff", unit = "player", herotalent = 117282 }, -- Waste No Time
        { spell = 449887, type = "buff", unit = "player", herotalent = 117295 }, -- Voidheart
      },
      icon = 135940
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 204213, type = "debuff", unit = "target", talent = 103718 }, -- Purge the Wicked
        { spell = 208772, type = "debuff", unit = "target", talent = 108225 }, -- Sanctuary
        { spell = 214621, type = "debuff", unit = "target", talent = 103704 }, -- Schism
        { spell = 356084, type = "debuff", unit = "target", talent = 103693 }, -- Blaze of Light
        { spell = 390669, type = "debuff", unit = "target", talent = 103839 }, -- Apathy
        { spell = 451210, type = "debuff", unit = "target", herotalent = 117296 }, -- No Escape
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability", buff = true }, -- Power Word: Shield
        { spell = 453, type = "ability" }, -- Mind Soothe
        { spell = 527, type = "ability", charges = true }, -- Purify
        { spell = 528, type = "ability", requiresTarget = true, talent = 103867 }, -- Dispel Magic
        { spell = 585, type = "ability", requiresTarget = true }, -- Smite
        { spell = 586, type = "ability", buff = true }, -- Fade
        { spell = 589, type = "ability", debuff = true, requiresTarget = true }, -- Shadow Word: Pain
        { spell = 8092, type = "ability", charges = true, requiresTarget = true }, -- Mind Blast
        { spell = 8122, type = "ability", debuff = true }, -- Psychic Scream
        { spell = 10060, type = "ability", buff = true, talent = 103844 }, -- Power Infusion
        { spell = 15286, type = "ability", buff = true, talent = 103841 }, -- Vampiric Embrace
        { spell = 19236, type = "ability", buff = true }, -- Desperate Prayer
        { spell = 32375, type = "ability", talent = 103849 }, -- Mass Dispel
        { spell = 32379, type = "ability", overlayGlow = true, requiresTarget = true, talent = 103864 }, -- Shadow Word: Death
        { spell = 33076, type = "ability", talent = 103870 }, -- Prayer of Mending
        { spell = 33206, type = "ability", charges = true, buff = true, talent = 103713 }, -- Pain Suppression
        { spell = 34433, type = "ability", requiresTarget = true, totem = true, talent = 103865 }, -- Shadowfiend
        { spell = 47536, type = "ability", buff = true, talent = 103727 }, -- Rapture
        { spell = 47540, type = "ability", overlayGlow = true, requiresTarget = true }, -- Penance
        { spell = 62618, type = "ability", talent = 103687 }, -- Power Word: Barrier
        { spell = 108920, type = "ability", talent = 103859 }, -- Void Tendrils
        { spell = 108968, type = "ability", talent = 103820 }, -- Void Shift
        { spell = 110744, type = "ability", talent = 103831 }, -- Divine Star
        { spell = 120517, type = "ability", talent = 103830 }, -- Halo
        { spell = 120644, type = "ability", talent = 103827 }, -- Halo
        { spell = 121536, type = "ability", charges = true, talent = 103853 }, -- Angelic Feather
        { spell = 122121, type = "ability", talent = 103828 }, -- Divine Star
        { spell = 123040, type = "ability", requiresTarget = true, talent = 103710 }, -- Mindbender
        { spell = 194509, type = "ability", charges = true, overlayGlow = true, talent = 103722 }, -- Power Word: Radiance
        { spell = 200174, type = "ability", requiresTarget = true, talent = 103788 }, -- Mindbender
        { spell = 204197, type = "ability", requiresTarget = true, talent = 103718 }, -- Purge the Wicked
        { spell = 205364, type = "ability", talent = 103678 }, -- Dominate Mind
        { spell = 246287, type = "ability", talent = 103691 }, -- Evangelism
        { spell = 271466, type = "ability", buff = true, talent = 116182 }, -- Luminous Barrier
        { spell = 373481, type = "ability", usable = true, talent = 103822 }, -- Power Word: Life
        { spell = 400169, type = "ability" }, -- Dark Reprimand
        { spell = 421453, type = "ability", buff = true, requiresTarget = true, talent = 103700 }, -- Ultimate Penitence
        { spell = 428930, type = "ability", charges = true, buff = true }, -- Premonition of Piety
        { spell = 428933, type = "ability", charges = true, buff = true }, -- Premonition of Insight
        { spell = 428934, type = "ability", charges = true, buff = true }, -- Premonition of Solace
        { spell = 440725, type = "ability", charges = true }, -- Premonition of Clairvoyance
        { spell = 451235, type = "ability", requiresTarget = true, totem = true, herotalent = 123841 }, -- Voidwraith
      },
      icon = 136224
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 139, type = "buff", unit = "player", talent = 103869 }, -- Renew
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 2096, type = "buff", unit = "player" }, -- Mind Vision
        { spell = 10060, type = "buff", unit = "player", talent = 103844 }, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player", talent = 103841 }, -- Vampiric Embrace
        { spell = 19236, type = "buff", unit = "player" }, -- Desperate Prayer
        { spell = 21562, type = "buff", unit = "player" }, -- Power Word: Fortitude
        { spell = 41635, type = "buff", unit = "player", talent = 103870 }, -- Prayer of Mending
        { spell = 47788, type = "buff", unit = "player", talent = 103774 }, -- Guardian Spirit
        { spell = 64843, type = "buff", unit = "player", talent = 103755 }, -- Divine Hymn
        { spell = 64901, type = "buff", unit = "player", talent = 103751 }, -- Symbol of Hope
        { spell = 65081, type = "buff", unit = "player", talent = 103856 }, -- Body and Soul
        { spell = 77489, type = "buff", unit = "player" }, -- Echo of Light
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 114255, type = "buff", unit = "player", talent = 103823 }, -- Surge of Light
        { spell = 121557, type = "buff", unit = "player", talent = 103853 }, -- Angelic Feather
        { spell = 193065, type = "buff", unit = "player", talent = 103858 }, -- Protective Light
        { spell = 196490, type = "buff", unit = "player", talent = 103768 }, -- Sanctified Prayers
        { spell = 200183, type = "buff", unit = "player", talent = 103743 }, -- Apotheosis
        { spell = 289655, type = "buff", unit = "player" }, -- Sanctified Ground
        { spell = 321379, type = "buff", unit = "player", talent = 103760 }, -- Prayer Circle
        { spell = 372313, type = "buff", unit = "player", talent = 103735 }, -- Resonant Words
        { spell = 372617, type = "buff", unit = "player", talent = 103777 }, -- Empyreal Blaze
        { spell = 372760, type = "buff", unit = "player", talent = 103676 }, -- Divine Word
        { spell = 372761, type = "buff", unit = "player" }, -- Divine Favor: Chastise
        { spell = 372791, type = "buff", unit = "player" }, -- Divine Favor: Serenity
        { spell = 372838, type = "buff", unit = "player", talent = 103733 }, -- Lightwell
        { spell = 390617, type = "buff", unit = "player", talent = 103857 }, -- From Darkness Comes Light
        { spell = 390636, type = "buff", unit = "player", talent = 103850 }, -- Rhapsody
        { spell = 390677, type = "buff", unit = "player", talent = 103846 }, -- Inspiration
        { spell = 390885, type = "buff", unit = "player", talent = 103759 }, -- Healing Chorus
        { spell = 390933, type = "buff", unit = "player", talent = 103873 }, -- Words of the Pious
        { spell = 390978, type = "buff", unit = "player", talent = 103833 }, -- Twist of Fate
        { spell = 390989, type = "buff", unit = "player", talent = 103763 }, -- Pontifex
        { spell = 390993, type = "buff", unit = "player", talent = 103734 }, -- Lightweaver
        { spell = 405963, type = "buff", unit = "player", talent = 103675 }, -- Divine Image
        { spell = 428930, type = "buff", unit = "player" }, -- Premonition of Piety
        { spell = 428933, type = "buff", unit = "player" }, -- Premonition of Insight
        { spell = 428934, type = "buff", unit = "player" }, -- Premonition of Solace
        { spell = 440683, type = "buff", unit = "player", herotalent = 117282 }, -- Waste No Time
        { spell = 453846, type = "buff", unit = "player", herotalent = 117284 }, -- Resonant Energy
        { spell = 453983, type = "buff", unit = "player", herotalent = 117280 }, -- Perfected Form
        { spell = 454002, type = "buff", unit = "player", herotalent = 125085 }, -- Sustained Potency
      },
      icon = 135953
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 14914, type = "debuff", unit = "target" }, -- Holy Fire
        { spell = 200200, type = "debuff", unit = "target", talent = 103776 }, -- Holy Word: Chastise
        { spell = 453848, type = "debuff", unit = "target", herotalent = 117289 }, -- Shock Pulse
      },
      icon = 135972
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability", buff = true }, -- Power Word: Shield
        { spell = 453, type = "ability" }, -- Mind Soothe
        { spell = 586, type = "ability", buff = true }, -- Fade
        { spell = 2050, type = "ability", charges = true, overlayGlow = true, talent = 103775 }, -- Holy Word: Serenity
        { spell = 2060, type = "ability", charges = true, overlayGlow = true }, -- Heal
        { spell = 2061, type = "ability", charges = true, overlayGlow = true }, -- Flash Heal
        { spell = 8122, type = "ability", debuff = true }, -- Psychic Scream
        { spell = 10060, type = "ability", buff = true, talent = 103844 }, -- Power Infusion
        { spell = 14914, type = "ability", debuff = true, overlayGlow = true }, -- Holy Fire
        { spell = 15286, type = "ability", buff = true, talent = 103841 }, -- Vampiric Embrace
        { spell = 19236, type = "ability", buff = true }, -- Desperate Prayer
        { spell = 32375, type = "ability", talent = 103849 }, -- Mass Dispel
        { spell = 32379, type = "ability", overlayGlow = true, talent = 103864 }, -- Shadow Word: Death
        { spell = 33076, type = "ability", overlayGlow = true, talent = 103870 }, -- Prayer of Mending
        { spell = 34433, type = "ability", totem = true, talent = 103865 }, -- Shadowfiend
        { spell = 34861, type = "ability", charges = true, overlayGlow = true, talent = 103766 }, -- Holy Word: Sanctify
        { spell = 47788, type = "ability", buff = true, talent = 103774 }, -- Guardian Spirit
        { spell = 64843, type = "ability", buff = true, talent = 103755 }, -- Divine Hymn
        { spell = 64901, type = "ability", buff = true, talent = 103751 }, -- Symbol of Hope
        { spell = 88625, type = "ability", overlayGlow = true, talent = 103776 }, -- Holy Word: Chastise
        { spell = 108920, type = "ability", talent = 103859 }, -- Void Tendrils
        { spell = 108968, type = "ability", talent = 103820 }, -- Void Shift
        { spell = 110744, type = "ability", talent = 103831 }, -- Divine Star
        { spell = 120517, type = "ability", talent = 103830 }, -- Halo
        { spell = 121536, type = "ability", buff = true, charges = true, talent = 103853 }, -- Angelic Feather
        { spell = 200183, type = "ability", buff = true, talent = 103743 }, -- Apotheosis
        { spell = 204883, type = "ability", talent = 103758 }, -- Circle of Healing
        { spell = 205364, type = "ability", talent = 103678 }, -- Dominate Mind
        { spell = 265202, type = "ability", talent = 103742 }, -- Holy Word: Salvation
        { spell = 372760, type = "ability", buff = true, talent = 103676 }, -- Divine Word
        { spell = 372835, type = "ability", totem = true, talent = 103733 }, -- Lightwell
        { spell = 373481, type = "ability", usable = true, talent = 103822 }, -- Power Word: Life
        { spell = 428930, type = "ability", charges = true, buff = true }, -- Premonition of Piety
        { spell = 428933, type = "ability", charges = true, buff = true }, -- Premonition of Insight
        { spell = 428934, type = "ability", charges = true, buff = true }, -- Premonition of Solace
        { spell = 440725, type = "ability", charges = true }, -- Premonition of Clairvoyance
      },
      icon = 135937
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 139, type = "buff", unit = "player", talent = 103869 }, -- Renew
        { spell = 586, type = "buff", unit = "player" }, -- Fade
        { spell = 10060, type = "buff", unit = "player", talent = 103844 }, -- Power Infusion
        { spell = 15286, type = "buff", unit = "player", talent = 103841 }, -- Vampiric Embrace
        { spell = 21562, type = "buff", unit = "player" }, -- Power Word: Fortitude
        { spell = 41635, type = "buff", unit = "player", talent = 103870 }, -- Prayer of Mending
        { spell = 47585, type = "buff", unit = "player", talent = 103806 }, -- Dispersion
        { spell = 65081, type = "buff", unit = "player", talent = 103856 }, -- Body and Soul
        { spell = 111759, type = "buff", unit = "player" }, -- Levitate
        { spell = 114255, type = "buff", unit = "player", talent = 103823 }, -- Surge of Light
        { spell = 121557, type = "buff", unit = "player", talent = 103853 }, -- Angelic Feather
        { spell = 193065, type = "buff", unit = "player", talent = 103858 }, -- Protective Light
        { spell = 194249, type = "buff", unit = "player" }, -- Voidform
        { spell = 232698, type = "buff", unit = "player" }, -- Shadowform
        { spell = 247776, type = "buff", unit = "player" }, -- Mind Trauma
        { spell = 341282, type = "buff", unit = "player", talent = 103804 }, -- Unfurling Darkness
        { spell = 373204, type = "buff", unit = "player", talent = 103684 }, -- Mind Devourer
        { spell = 373213, type = "buff", unit = "player", talent = 103683 }, -- Insidious Ire
        { spell = 373276, type = "buff", unit = "player", talent = 103817 }, -- Idol of Yogg-Saron
        { spell = 375981, type = "buff", unit = "player", talent = 103805 }, -- Shadowy Insight
        { spell = 377066, type = "buff", unit = "player", talent = 103800 }, -- Mental Fortitude
        { spell = 390617, type = "buff", unit = "player", talent = 103857 }, -- From Darkness Comes Light
        { spell = 390636, type = "buff", unit = "player", talent = 103850 }, -- Rhapsody
        { spell = 390933, type = "buff", unit = "player", talent = 103873 }, -- Words of the Pious
        { spell = 390978, type = "buff", unit = "player", talent = 103833 }, -- Twist of Fate
        { spell = 391092, type = "buff", unit = "player", talent = 115449 }, -- Mind Melt
        { spell = 391099, type = "buff", unit = "player", talent = 103802 }, -- Dark Evangelism
        { spell = 391109, type = "buff", unit = "player", talent = 103680 }, -- Dark Ascension
        { spell = 391401, type = "buff", unit = "player" }, -- Mind Flay: Insanity
        { spell = 392511, type = "buff", unit = "player", talent = 103681 }, -- Deathspeaker
        { spell = 393919, type = "buff", unit = "player", talent = 103789 }, -- Screams of the Void
        { spell = 407468, type = "buff", unit = "player" }, -- Mind Spike: Insanity
      },
      icon = 237566
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 589, type = "debuff", unit = "target" }, -- Shadow Word: Pain
        { spell = 8122, type = "debuff", unit = "target" }, -- Psychic Scream
        { spell = 15407, type = "debuff", unit = "target" }, -- Mind Flay
        { spell = 15487, type = "debuff", unit = "target", talent = 103792 }, -- Silence
        { spell = 34914, type = "debuff", unit = "target" }, -- Vampiric Touch
        { spell = 64044, type = "debuff", unit = "target", talent = 103793 }, -- Psychic Horror
        { spell = 114404, type = "debuff", unit = "target" }, -- Void Tendril's Grasp
        { spell = 247777, type = "debuff", unit = "target" }, -- Mind Trauma
        { spell = 263165, type = "debuff", unit = "target", talent = 103796 }, -- Void Torrent
        { spell = 322098, type = "debuff", unit = "target", talent = 103863 }, -- Death and Madness
        { spell = 335467, type = "debuff", unit = "target", talent = 103808 }, -- Devouring Plague
        { spell = 373281, type = "debuff", unit = "target" }, -- Echoing Void
        { spell = 390669, type = "debuff", unit = "target", talent = 103839 }, -- Apathy
        { spell = 391403, type = "debuff", unit = "target" }, -- Mind Flay: Insanity
        { spell = 394976, type = "debuff", unit = "target" }, -- Mind Sear
        { spell = 453850, type = "debuff", unit = "target", herotalent = 117284 }, -- Resonant Energy
      },
      icon = 136207
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 17, type = "ability", buff = true, usable = true }, -- Power Word: Shield
        { spell = 453, type = "ability", usable = true }, -- Mind Soothe
        { spell = 586, type = "ability", buff = true, usable = true }, -- Fade
        { spell = 8092, type = "ability", charges = true, overlayGlow = true, usable = true }, -- Mind Blast
        { spell = 8122, type = "ability", debuff = true, usable = true }, -- Psychic Scream
        { spell = 10060, type = "ability", buff = true, usable = true, talent = 103844 }, -- Power Infusion
        { spell = 15286, type = "ability", buff = true, talent = 103841 }, -- Vampiric Embrace
        { spell = 15487, type = "ability", debuff = true, usable = true, talent = 103792 }, -- Silence
        { spell = 32375, type = "ability", usable = true, talent = 103849 }, -- Mass Dispel
        { spell = 32379, type = "ability", charges = true, overlayGlow = true, usable = true, talent = 103864 }, -- Shadow Word: Death
        { spell = 33076, type = "ability", usable = true, talent = 103870 }, -- Prayer of Mending
        { spell = 34433, type = "ability", talent = 103865 }, -- Shadowfiend
        { spell = 47585, type = "ability", buff = true, talent = 103806 }, -- Dispersion
        { spell = 64044, type = "ability", debuff = true, talent = 103793 }, -- Psychic Horror
        { spell = 108920, type = "ability", talent = 103859 }, -- Void Tendrils
        { spell = 108968, type = "ability", talent = 103820 }, -- Void Shift
        { spell = 120644, type = "ability", usable = true, talent = 103827 }, -- Halo
        { spell = 121536, type = "ability", charges = true, usable = true, talent = 103853 }, -- Angelic Feather
        { spell = 122121, type = "ability", talent = 103828 }, -- Divine Star
        { spell = 194249, type = "ability", buff = true }, -- Voidform
        { spell = 200174, type = "ability", totem = true, usable = true, talent = 103788 }, -- Mindbender
        { spell = 205364, type = "ability", talent = 103678 }, -- Dominate Mind
        { spell = 205385, type = "ability", talent = 125983 }, -- Shadow Crash
        { spell = 205448, type = "ability" }, -- Void Bolt
        { spell = 213634, type = "ability", usable = true, talent = 103854 }, -- Purify Disease
        { spell = 228260, type = "ability", talent = 103674 }, -- Void Eruption
        { spell = 263165, type = "ability", debuff = true, talent = 103796 }, -- Void Torrent
        { spell = 373481, type = "ability", talent = 103822 }, -- Power Word: Life
        { spell = 391109, type = "ability", buff = true, usable = true, talent = 103680 }, -- Dark Ascension
        { spell = 391403, type = "ability", charges = true, debuff = true, overlayGlow = true }, -- Mind Flay: Insanity
        { spell = 457042, type = "ability", usable = true, talent = 103813 }, -- Shadow Crash
      },
      icon = 136230
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 58875, type = "buff", unit = "player", talent = 127865 }, -- Spirit Walk
        { spell = 77762, type = "buff", unit = "player" }, -- Lava Surge
        { spell = 79206, type = "buff", unit = "player", talent = 127857 }, -- Spiritwalker's Grace
        { spell = 108271, type = "buff", unit = "player", talent = 127893 }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 128116 }, -- Ancestral Guidance
        { spell = 114050, type = "buff", unit = "player", talent = 101877 }, -- Ascendance
        { spell = 114893, type = "buff", unit = "player" }, -- Stone Bulwark
        { spell = 191634, type = "buff", unit = "player", talent = 101860 }, -- Stormkeeper
        { spell = 191877, type = "buff", unit = "player", talent = 101892 }, -- Power of the Maelstrom
        { spell = 192082, type = "buff", unit = "player" }, -- Wind Rush
        { spell = 192106, type = "buff", unit = "player" }, -- Lightning Shield
        { spell = 260734, type = "buff", unit = "player", talent = 101879 }, -- Master of the Elements
        { spell = 260881, type = "buff", unit = "player", talent = 127854 }, -- Spirit Wolf
        { spell = 263806, type = "buff", unit = "player" }, -- Wind Gust
        { spell = 285514, type = "buff", unit = "player", talent = 101873 }, -- Surge of Power
        { spell = 375986, type = "buff", unit = "player", talent = 101891 }, -- Primordial Wave
        { spell = 381755, type = "buff", unit = "player", talent = 127858 }, -- Earth Elemental
        { spell = 381761, type = "buff", unit = "player", talent = 127889 }, -- Primordial Bond
        { spell = 381933, type = "buff", unit = "player", talent = 101883 }, -- Magma Chamber
        { spell = 382028, type = "buff", unit = "player", talent = 101886 }, -- Improved Flametongue Weapon
        { spell = 382043, type = "buff", unit = "player", talent = 101844 }, -- Splintered Elements
        { spell = 382217, type = "buff", unit = "player", talent = 127891 }, -- Winds of Al'Akir
        { spell = 383648, type = "buff", unit = "player", talent = 127871 }, -- Earth Shield
        { spell = 384088, type = "buff", unit = "player", talent = 101862 }, -- Echoes of Great Sundering
        { spell = 443454, type = "buff", unit = "player", herotalent = 117491 }, -- Ancestral Swiftness
        { spell = 447244, type = "buff", unit = "player", herotalent = 117485 }, -- Call of the Ancestors
        { spell = 454015, type = "buff", unit = "player", herotalent = 117489 }, -- Tempest
        { spell = 454025, type = "buff", unit = "player", herotalent = 128226 }, -- Electroshock
        { spell = 454376, type = "buff", unit = "player", herotalent = 125617 }, -- Surging Currents
        { spell = 454394, type = "buff", unit = "player", herotalent = 117483 }, -- Unlimited Power
        { spell = 455089, type = "buff", unit = "player", herotalent = 117470 }, -- Storm Swell
        { spell = 462131, type = "buff", unit = "player", herotalent = 117464 }, -- Awakening Storms
        { spell = 462725, type = "buff", unit = "player", talent = 127917 }, -- Storm Frenzy
        { spell = 462818, type = "buff", unit = "player", talent = 101870 }, -- Icefury
        { spell = 462854, type = "buff", unit = "player" }, -- Skyfury
        { spell = 468226, type = "buff", unit = "player", herotalent = 117460 }, -- Lightning Conduit
        { spell = 157348, type = "buff", unit = "pet" }, -- Call Lightning
      },
      icon = 135863
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 51490, type = "debuff", unit = "target", talent = 127878 }, -- Thunderstorm
        { spell = 64695, type = "debuff", unit = "target" }, -- Earthgrab
        { spell = 77505, type = "debuff", unit = "target", talent = 127925 }, -- Earthquake
        { spell = 116947, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 118297, type = "debuff", unit = "target" }, -- Immolate
        { spell = 118345, type = "debuff", unit = "target" }, -- Pulverize
        { spell = 118905, type = "debuff", unit = "target", talent = 127896 }, -- Static Charge
        { spell = 157375, type = "debuff", unit = "target", herotalent = 117489 }, -- Tempest
        { spell = 188389, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 196840, type = "debuff", unit = "target", talent = 127879 }, -- Frost Shock
        { spell = 197209, type = "debuff", unit = "target", talent = 101864 }, -- Lightning Rod
        { spell = 285515, type = "debuff", unit = "target", talent = 101873 }, -- Surge of Power
        { spell = 454025, type = "debuff", unit = "target", herotalent = 117460 }, -- Shocking Grasp
        { spell = 454029, type = "debuff", unit = "target", herotalent = 117477 }, -- Nature's Protection
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 370, type = "ability", requiresTarget = true, talent = 127905 }, -- Purge
        { spell = 556, type = "ability", usable = true }, -- Astral Recall
        { spell = 2825, type = "ability", buff = true }, -- Bloodlust
        { spell = 5394, type = "ability", totem = true, talent = 127863 }, -- Healing Stream Totem
        { spell = 8042, type = "ability", overlayGlow = true, requiresTarget = true, talent = 101854 }, -- Earth Shock
        { spell = 8143, type = "ability", totem = true, talent = 127868 }, -- Tremor Totem
        { spell = 51485, type = "ability", totem = true, talent = 127894 }, -- Earthgrab Totem
        { spell = 51490, type = "ability", debuff = true, talent = 127878 }, -- Thunderstorm
        { spell = 51505, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 127873 }, -- Lava Burst
        { spell = 51514, type = "ability", talent = 127903 }, -- Hex
        { spell = 51886, type = "ability", talent = 127884 }, -- Cleanse Spirit
        { spell = 57994, type = "ability", requiresTarget = true, talent = 127892 }, -- Wind Shear
        { spell = 58875, type = "ability", buff = true, talent = 127865 }, -- Spirit Walk
        { spell = 61882, type = "ability", overlayGlow = true, requiresTarget = true, talent = 127925 }, -- Earthquake
        { spell = 73899, type = "ability", requiresTarget = true }, -- Primal Strike
        { spell = 79206, type = "ability", buff = true, talent = 127857 }, -- Spiritwalker's Grace
        { spell = 108270, type = "ability", totem = true, talent = 127911 }, -- Stone Bulwark Totem
        { spell = 108271, type = "ability", buff = true, talent = 127893 }, -- Astral Shift
        { spell = 108281, type = "ability", buff = true, talent = 128116 }, -- Ancestral Guidance
        { spell = 108285, type = "ability", talent = 127870 }, -- Totemic Recall
        { spell = 108287, type = "ability", talent = 127859 }, -- Totemic Projection
        { spell = 114050, type = "ability", buff = true, talent = 101877 }, -- Ascendance
        { spell = 188196, type = "ability", overlayGlow = true, requiresTarget = true }, -- Lightning Bolt
        { spell = 188389, type = "ability", debuff = true, requiresTarget = true }, -- Flame Shock
        { spell = 188443, type = "ability", overlayGlow = true, requiresTarget = true, talent = 127856 }, -- Chain Lightning
        { spell = 191634, type = "ability", buff = true, talent = 101860 }, -- Stormkeeper
        { spell = 192058, type = "ability", totem = true, talent = 127851 }, -- Capacitor Totem
        { spell = 192077, type = "ability", totem = true, talent = 127909 }, -- Wind Rush Totem
        { spell = 192222, type = "ability", totem = true, talent = 101884 }, -- Liquid Magma Totem
        { spell = 192249, type = "ability", requiresTarget = true, talent = 101849 }, -- Storm Elemental
        { spell = 196840, type = "ability", debuff = true, requiresTarget = true, talent = 127879 }, -- Frost Shock
        { spell = 198067, type = "ability", requiresTarget = true, totem = true, talent = 101850 }, -- Fire Elemental
        { spell = 198103, type = "ability", requiresTarget = true, talent = 127858 }, -- Earth Elemental
        { spell = 305483, type = "ability", requiresTarget = true, talent = 127862 }, -- Lightning Lasso
        { spell = 375982, type = "ability", requiresTarget = true, talent = 101891 }, -- Primordial Wave
        { spell = 378773, type = "ability", requiresTarget = true, talent = 127904 }, -- Greater Purge
        { spell = 383013, type = "ability", totem = true, talent = 127885 }, -- Poison Cleansing Totem
        { spell = 443454, type = "ability", buff = true, usable = true, herotalent = 117491 }, -- Ancestral Swiftness
      },
      icon = 135963
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 58875, type = "buff", unit = "player", talent = 127865 }, -- Spirit Walk
        { spell = 79206, type = "buff", unit = "player", talent = 127857 }, -- Spiritwalker's Grace
        { spell = 108271, type = "buff", unit = "player", talent = 127893 }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 128116 }, -- Ancestral Guidance
        { spell = 114051, type = "buff", unit = "player", talent = 114291 }, -- Ascendance
        { spell = 114893, type = "buff", unit = "player" }, -- Stone Bulwark
        { spell = 118522, type = "buff", unit = "player" }, -- Elemental Blast: Critical Strike
        { spell = 173183, type = "buff", unit = "player" }, -- Elemental Blast: Haste
        { spell = 173184, type = "buff", unit = "player" }, -- Elemental Blast: Mastery
        { spell = 187878, type = "buff", unit = "player", talent = 101840 }, -- Crash Lightning
        { spell = 192082, type = "buff", unit = "player" }, -- Wind Rush
        { spell = 192106, type = "buff", unit = "player" }, -- Lightning Shield
        { spell = 198300, type = "buff", unit = "player", talent = 101839 }, -- Converging Storms
        { spell = 201846, type = "buff", unit = "player" }, -- Stormbringer
        { spell = 215785, type = "buff", unit = "player", talent = 101809 }, -- Hot Hand
        { spell = 224125, type = "buff", unit = "player" }, -- Molten Weapon
        { spell = 224126, type = "buff", unit = "player" }, -- Icy Edge
        { spell = 224127, type = "buff", unit = "player" }, -- Crackling Surge
        { spell = 260881, type = "buff", unit = "player", talent = 127854 }, -- Spirit Wolf
        { spell = 262652, type = "buff", unit = "player", talent = 101834 }, -- Forceful Winds
        { spell = 333957, type = "buff", unit = "player", talent = 101838 }, -- Feral Spirit
        { spell = 334196, type = "buff", unit = "player", talent = 101808 }, -- Hailstorm
        { spell = 344179, type = "buff", unit = "player" }, -- Maelstrom Weapon
        { spell = 375986, type = "buff", unit = "player", talent = 101830 }, -- Primordial Wave
        { spell = 378076, type = "buff", unit = "player", talent = 127853 }, -- Thunderous Paws
        { spell = 378078, type = "buff", unit = "player", talent = 127907 }, -- Spiritwalker's Aegis
        { spell = 378081, type = "buff", unit = "player", talent = 127899 }, -- Nature's Swiftness
        { spell = 381755, type = "buff", unit = "player", talent = 127858 }, -- Earth Elemental
        { spell = 381761, type = "buff", unit = "player", talent = 127889 }, -- Primordial Bond
        { spell = 382217, type = "buff", unit = "player", talent = 127891 }, -- Winds of Al'Akir
        { spell = 382889, type = "buff", unit = "player", talent = 101799 }, -- Flurry
        { spell = 383648, type = "buff", unit = "player", talent = 127871 }, -- Earth Shield
        { spell = 384352, type = "buff", unit = "player", talent = 101824 }, -- Doom Winds
        { spell = 384451, type = "buff", unit = "player", talent = 101815 }, -- Legacy of the Frost Witch
        { spell = 384357, type = "buff", unit = "player" }, -- Ice Strike
        { spell = 390371, type = "buff", unit = "player", talent = 101811 }, -- Ashen Catalyst
        { spell = 392375, type = "buff", unit = "player" }, -- Earthen Weapon
        { spell = 453405, type = "buff", unit = "player" }, -- Whirling Fire
        { spell = 453406, type = "buff", unit = "player" }, -- Whirling Earth
        { spell = 453409, type = "buff", unit = "player" }, -- Whirling Air
        { spell = 454015, type = "buff", unit = "player", herotalent = 117489 }, -- Tempest
        { spell = 454025, type = "buff", unit = "player", herotalent = 128226 }, -- Electroshock
        { spell = 454376, type = "buff", unit = "player", herotalent = 125617 }, -- Surging Currents
        { spell = 454394, type = "buff", unit = "player", herotalent = 117483 }, -- Unlimited Power
        { spell = 455097, type = "buff", unit = "player", herotalent = 125616 }, -- Arc Discharge
        { spell = 455089, type = "buff", unit = "player", herotalent = 117470 }, -- Storm Swell
        { spell = 456369, type = "buff", unit = "player", herotalent = 117471 }, -- Amplification Core
        { spell = 457387, type = "buff", unit = "player", herotalent = 117488 }, -- Wind Barrier
        { spell = 458269, type = "buff", unit = "player", herotalent = 117487 }, -- Totemic Rebound
        { spell = 461242, type = "buff", unit = "player", herotalent = 117479 }, -- Lively Totems
        { spell = 462131, type = "buff", unit = "player", herotalent = 117464 }, -- Awakening Storms
        { spell = 462854, type = "buff", unit = "player" }, -- Skyfury
        { spell = 468226, type = "buff", unit = "player", herotalent = 117460 }, -- Lightning Conduit
        { spell = 470058, type = "buff", unit = "player", talent = 128270 }, -- Voltaic Blaze
      },
      icon = 136099
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 51490, type = "debuff", unit = "target", talent = 127878 }, -- Thunderstorm
        { spell = 64695, type = "debuff", unit = "target" }, -- Earthgrab
        { spell = 116947, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 118905, type = "debuff", unit = "target", talent = 127896 }, -- Static Charge
        { spell = 188389, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 196840, type = "debuff", unit = "target", talent = 127879 }, -- Frost Shock
        { spell = 197209, type = "debuff", unit = "target", talent = 101864 }, -- Lightning Rod
        { spell = 197214, type = "debuff", unit = "target", talent = 101841 }, -- Sundering
        { spell = 305485, type = "debuff", unit = "target", talent = 127862 }, -- Lightning Lasso
        { spell = 334168, type = "debuff", unit = "target", talent = 101812 }, -- Lashing Flames
        { spell = 342240, type = "debuff", unit = "target" }, -- Ice Strike
        { spell = 454025, type = "debuff", unit = "target", herotalent = 117460 }, -- Shocking Grasp
      },
      icon = 462327
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 370, type = "ability", requiresTarget = true, talent = 127905 }, -- Purge
        { spell = 556, type = "ability", usable = true }, -- Astral Recall
        { spell = 2825, type = "ability", buff = true }, -- Bloodlust
        { spell = 5394, type = "ability", totem = true, talent = 127863 }, -- Healing Stream Totem
        { spell = 8143, type = "ability", totem = true, talent = 127868 }, -- Tremor Totem
        { spell = 17364, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true, talent = 101804 }, -- Stormstrike
        { spell = 51485, type = "ability", totem = true, talent = 127894 }, -- Earthgrab Totem
        { spell = 51490, type = "ability", debuff = true, talent = 127878 }, -- Thunderstorm
        { spell = 51505, type = "ability", overlayGlow = true, requiresTarget = true, talent = 127873 }, -- Lava Burst
        { spell = 51514, type = "ability", talent = 127903 }, -- Hex
        { spell = 51533, type = "ability", requiresTarget = true, talent = 101838 }, -- Feral Spirit
        { spell = 51886, type = "ability", talent = 127884 }, -- Cleanse Spirit
        { spell = 57994, type = "ability", requiresTarget = true, talent = 127892 }, -- Wind Shear
        { spell = 58875, type = "ability", buff = true, talent = 127865 }, -- Spirit Walk
        { spell = 60103, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 101805 }, -- Lava Lash
        { spell = 79206, type = "ability", buff = true, talent = 127857 }, -- Spiritwalker's Grace
        { spell = 108270, type = "ability", totem = true, talent = 127911 }, -- Stone Bulwark Totem
        { spell = 108271, type = "ability", buff = true, talent = 127893 }, -- Astral Shift
        { spell = 108281, type = "ability", buff = true, talent = 128116 }, -- Ancestral Guidance
        { spell = 108285, type = "ability", talent = 127870 }, -- Totemic Recall
        { spell = 108287, type = "ability", talent = 127859 }, -- Totemic Projection
        { spell = 114051, type = "ability", buff = true, talent = 114291 }, -- Ascendance
        { spell = 115356, type = "ability", overlayGlow = true }, -- Windstrike
        { spell = 117014, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 117750 }, -- Elemental Blast
        { spell = 187874, type = "ability", talent = 101840 }, -- Crash Lightning
        { spell = 188196, type = "ability", overlayGlow = true, requiresTarget = true }, -- Lightning Bolt
        { spell = 188389, type = "ability", debuff = true, requiresTarget = true }, -- Flame Shock
        { spell = 188443, type = "ability", overlayGlow = true, requiresTarget = true, talent = 127856 }, -- Chain Lightning
        { spell = 192058, type = "ability", totem = true, talent = 127851 }, -- Capacitor Totem
        { spell = 192063, type = "ability", talent = 127864 }, -- Gust of Wind
        { spell = 192077, type = "ability", talent = 127909 }, -- Wind Rush Totem
        { spell = 196840, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, talent = 127879 }, -- Frost Shock
        { spell = 196884, type = "ability", requiresTarget = true }, -- Feral Lunge
        { spell = 197214, type = "ability", debuff = true, talent = 101841 }, -- Sundering
        { spell = 198103, type = "ability", requiresTarget = true, totem = true, talent = 127858 }, -- Earth Elemental
        { spell = 204406, type = "ability", talent = 127878 }, -- Thunderstorm
        { spell = 305483, type = "ability", requiresTarget = true, talent = 127862 }, -- Lightning Lasso
        { spell = 333974, type = "ability", talent = 101807 }, -- Fire Nova
        { spell = 375982, type = "ability", requiresTarget = true, talent = 101830 }, -- Primordial Wave
        { spell = 378081, type = "ability", buff = true, usable = true, talent = 127899 }, -- Nature's Swiftness
        { spell = 378773, type = "ability", requiresTarget = true, talent = 127904 }, -- Greater Purge
        { spell = 383013, type = "ability", talent = 127885 }, -- Poison Cleansing Totem
        { spell = 384352, type = "ability", buff = true, requiresTarget = true, talent = 101824 }, -- Doom Winds
        { spell = 444995, type = "ability", totem = true, herotalent = 117474 }, -- Surging Totem
        { spell = 470194, type = "ability", debuff = true, requiresTarget = true }, -- Ice Strike
      },
      icon = 1370984
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 974, type = "buff", unit = "player", talent = 127871 }, -- Earth Shield
        { spell = 2645, type = "buff", unit = "player" }, -- Ghost Wolf
        { spell = 2825, type = "buff", unit = "player" }, -- Bloodlust
        { spell = 52127, type = "buff", unit = "player" }, -- Water Shield
        { spell = 53390, type = "buff", unit = "player", talent = 101899 }, -- Tidal Waves
        { spell = 58875, type = "buff", unit = "player", talent = 127865 }, -- Spirit Walk
        { spell = 61295, type = "buff", unit = "player", talent = 101905 }, -- Riptide
        { spell = 73685, type = "buff", unit = "player", talent = 101918 }, -- Unleash Life
        { spell = 73920, type = "buff", unit = "player", talent = 101923 }, -- Healing Rain
        { spell = 77762, type = "buff", unit = "player" }, -- Lava Surge
        { spell = 79206, type = "buff", unit = "player", talent = 127857 }, -- Spiritwalker's Grace
        { spell = 108271, type = "buff", unit = "player", talent = 127893 }, -- Astral Shift
        { spell = 108281, type = "buff", unit = "player", talent = 128116 }, -- Ancestral Guidance
        { spell = 114052, type = "buff", unit = "player", talent = 101942 }, -- Ascendance
        { spell = 114893, type = "buff", unit = "player" }, -- Stone Bulwark
        { spell = 157504, type = "buff", unit = "player", talent = 101933 }, -- Cloudburst Totem
        { spell = 192082, type = "buff", unit = "player" }, -- Wind Rush
        { spell = 192106, type = "buff", unit = "player" }, -- Lightning Shield
        { spell = 201633, type = "buff", unit = "player" }, -- Earthen Wall
        { spell = 207400, type = "buff", unit = "player", talent = 127673 }, -- Ancestral Vigor
        { spell = 207778, type = "buff", unit = "player", talent = 101842 }, -- Downpour
        { spell = 216251, type = "buff", unit = "player", talent = 101919 }, -- Undulation
        { spell = 236502, type = "buff", unit = "player", talent = 101924 }, -- Tidebringer
        { spell = 260881, type = "buff", unit = "player", talent = 127854 }, -- Spirit Wolf
        { spell = 320763, type = "buff", unit = "player", talent = 101929 }, -- Mana Tide Totem
        { spell = 325174, type = "buff", unit = "player", talent = 101913 }, -- Spirit Link Totem
        { spell = 375986, type = "buff", unit = "player", talent = 101917 }, -- Primordial Wave
        { spell = 378076, type = "buff", unit = "player", talent = 127853 }, -- Thunderous Paws
        { spell = 378078, type = "buff", unit = "player", talent = 127907 }, -- Spiritwalker's Aegis
        { spell = 381755, type = "buff", unit = "player", talent = 127858 }, -- Earth Elemental
        { spell = 381761, type = "buff", unit = "player", talent = 127889 }, -- Primordial Bond
        { spell = 382024, type = "buff", unit = "player", talent = 101935 }, -- Earthliving Weapon
        { spell = 382217, type = "buff", unit = "player", talent = 127891 }, -- Winds of Al'Akir
        { spell = 383235, type = "buff", unit = "player", talent = 101939 }, -- Undercurrent
        { spell = 404523, type = "buff", unit = "player", talent = 114817 }, -- Spiritwalker's Tidal Totem
        { spell = 443454, type = "buff", unit = "player", herotalent = 117491 }, -- Ancestral Swiftness
        { spell = 447244, type = "buff", unit = "player", herotalent = 117485 }, -- Call of the Ancestors
        { spell = 453406, type = "buff", unit = "player" }, -- Whirling Earth
        { spell = 453407, type = "buff", unit = "player" }, -- Whirling Water
        { spell = 453409, type = "buff", unit = "player" }, -- Whirling Air
        { spell = 456369, type = "buff", unit = "player", herotalent = 117471 }, -- Amplification Core
        { spell = 457387, type = "buff", unit = "player", herotalent = 117488 }, -- Wind Barrier
        { spell = 462377, type = "buff", unit = "player", talent = 101896 }, -- Master of the Elements
        { spell = 462568, type = "buff", unit = "player", talent = 127876 }, -- Elemental Resistance
        { spell = 462854, type = "buff", unit = "player" }, -- Skyfury
        { spell = 467665, type = "buff", unit = "player" }, -- Swelling Tide
        { spell = 470077, type = "buff", unit = "player", talent = 128332 }, -- Coalescing Water
      },
      icon = 252995
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 51490, type = "debuff", unit = "target", talent = 127878 }, -- Thunderstorm
        { spell = 64695, type = "debuff", unit = "target" }, -- Earthgrab
        { spell = 116947, type = "debuff", unit = "target" }, -- Earthbind
        { spell = 118905, type = "debuff", unit = "target", talent = 127896 }, -- Static Charge
        { spell = 188389, type = "debuff", unit = "target" }, -- Flame Shock
        { spell = 196840, type = "debuff", unit = "target", talent = 127879 }, -- Frost Shock
        { spell = 305485, type = "debuff", unit = "target", talent = 127862 }, -- Lightning Lasso
      },
      icon = 135813
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 370, type = "ability", requiresTarget = true, talent = 127905 }, -- Purge
        { spell = 556, type = "ability", usable = true }, -- Astral Recall
        { spell = 2484, type = "ability" }, -- Earthbind Totem
        { spell = 2825, type = "ability", buff = true }, -- Bloodlust
        { spell = 5394, type = "ability", charges = true, totem = true, talent = 127863 }, -- Healing Stream Totem
        { spell = 8004, type = "ability", charges = true, overlayGlow = true }, -- Healing Surge
        { spell = 8143, type = "ability", totem = true, talent = 127868 }, -- Tremor Totem
        { spell = 16191, type = "ability", totem = true, talent = 101929 }, -- Mana Tide Totem
        { spell = 51485, type = "ability", totem = true, talent = 127894 }, -- Earthgrab Totem
        { spell = 51490, type = "ability", debuff = true, talent = 127878 }, -- Thunderstorm
        { spell = 51505, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 127873 }, -- Lava Burst
        { spell = 51514, type = "ability", talent = 127903 }, -- Hex
        { spell = 57994, type = "ability", requiresTarget = true, talent = 127892 }, -- Wind Shear
        { spell = 58875, type = "ability", buff = true, talent = 127865 }, -- Spirit Walk
        { spell = 61295, type = "ability", charges = true, buff = true, talent = 101905 }, -- Riptide
        { spell = 73685, type = "ability", buff = true, talent = 101918 }, -- Unleash Life
        { spell = 73899, type = "ability", requiresTarget = true }, -- Primal Strike
        { spell = 73920, type = "ability", buff = true, talent = 101923 }, -- Healing Rain
        { spell = 77472, type = "ability", charges = true, overlayGlow = true, talent = 101904 }, -- Healing Wave
        { spell = 79206, type = "ability", buff = true, talent = 127857 }, -- Spiritwalker's Grace
        { spell = 98008, type = "ability", totem = true, talent = 101913 }, -- Spirit Link Totem
        { spell = 108270, type = "ability", totem = true, talent = 127911 }, -- Stone Bulwark Totem
        { spell = 108271, type = "ability", buff = true, talent = 127893 }, -- Astral Shift
        { spell = 108280, type = "ability", totem = true, talent = 101912 }, -- Healing Tide Totem
        { spell = 108281, type = "ability", buff = true, talent = 128116 }, -- Ancestral Guidance
        { spell = 108285, type = "ability", talent = 127870 }, -- Totemic Recall
        { spell = 108287, type = "ability", talent = 127859 }, -- Totemic Projection
        { spell = 114052, type = "ability", buff = true, talent = 101942 }, -- Ascendance
        { spell = 157153, type = "ability", charges = true, totem = true, talent = 101933 }, -- Cloudburst Totem
        { spell = 188196, type = "ability", requiresTarget = true }, -- Lightning Bolt
        { spell = 188389, type = "ability", debuff = true, requiresTarget = true }, -- Flame Shock
        { spell = 188443, type = "ability", requiresTarget = true, talent = 127856 }, -- Chain Lightning
        { spell = 192058, type = "ability", totem = true, talent = 127851 }, -- Capacitor Totem
        { spell = 192063, type = "ability", talent = 127864 }, -- Gust of Wind
        { spell = 192077, type = "ability", totem = true, talent = 127909 }, -- Wind Rush Totem
        { spell = 196840, type = "ability", debuff = true, requiresTarget = true, talent = 127879 }, -- Frost Shock
        { spell = 197995, type = "ability", talent = 127676 }, -- Wellspring
        { spell = 198103, type = "ability", requiresTarget = true, totem = true, talent = 127858 }, -- Earth Elemental
        { spell = 198838, type = "ability", totem = true, talent = 101931 }, -- Earthen Wall Totem
        { spell = 201764, type = "ability" }, -- Recall Cloudburst Totem
        { spell = 207399, type = "ability", talent = 101930 }, -- Ancestral Protection Totem
        { spell = 305483, type = "ability", requiresTarget = true, talent = 127862 }, -- Lightning Lasso
        { spell = 375982, type = "ability", requiresTarget = true, talent = 101830 }, -- Primordial Wave
        { spell = 378773, type = "ability", requiresTarget = true, talent = 127904 }, -- Greater Purge
        { spell = 443454, type = "ability", buff = true, usable = true, herotalent = 117491 }, -- Ancestral Swiftness
        { spell = 444995, type = "ability", totem = true, herotalent = 117474 }, -- Surging Totem
      },
      icon = 135127
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 66, type = "buff", unit = "player" }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player" }, -- Arcane Intellect
        { spell = 12051, type = "buff", unit = "player", talent = 126529 }, -- Evocation
        { spell = 45438, type = "buff", unit = "player", talent = 80181 }, -- Ice Block
        { spell = 55342, type = "buff", unit = "player", talent = 80183 }, -- Mirror Image
        { spell = 80353, type = "buff", unit = "player" }, -- Time Warp
        { spell = 110960, type = "buff", unit = "player", talent = 115877 }, -- Greater Invisibility
        { spell = 116267, type = "buff", unit = "player", talent = 80177 }, -- Incanter's Flow
        { spell = 205025, type = "buff", unit = "player", talent = 126530 }, -- Presence of Mind
        { spell = 210126, type = "buff", unit = "player", talent = 126509 }, -- Arcane Familiar
        { spell = 235450, type = "buff", unit = "player", talent = 80180 }, -- Prismatic Barrier
        { spell = 263725, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 321388, type = "buff", unit = "player", talent = 126540 }, -- Enlightened
        { spell = 342246, type = "buff", unit = "player", talent = 80174 }, -- Alter Time
        { spell = 365362, type = "buff", unit = "player", talent = 126519 }, -- Arcane Surge
        { spell = 382290, type = "buff", unit = "player", talent = 80169 }, -- Tempest Barrier
        { spell = 382294, type = "buff", unit = "player", talent = 80170 }, -- Incantation of Swiftness
        { spell = 382440, type = "buff", unit = "player", talent = 80171 }, -- Shifting Power
        { spell = 382824, type = "buff", unit = "player", talent = 80156 }, -- Temporal Velocity
        { spell = 383783, type = "buff", unit = "player", talent = 126543 }, -- Nether Precision
        { spell = 383997, type = "buff", unit = "player", talent = 126506 }, -- Arcane Tempo
        { spell = 384267, type = "buff", unit = "player" }, -- Siphon Storm
        { spell = 384379, type = "buff", unit = "player", talent = 126508 }, -- Concentration
        { spell = 384455, type = "buff", unit = "player", talent = 126517 }, -- Arcane Harmony
        { spell = 389714, type = "buff", unit = "player" }, -- Displacement Beacon
        { spell = 393939, type = "buff", unit = "player", talent = 126550 }, -- Impetus
        { spell = 394195, type = "buff", unit = "player", talent = 80179 }, -- Overflowing Energy
        { spell = 414658, type = "buff", unit = "player", talent = 80141 }, -- Ice Cold
        { spell = 444754, type = "buff", unit = "player", herotalent = 117262 }, -- Slippery Slinging
        { spell = 444981, type = "buff", unit = "player", herotalent = 123407 }, -- Unerring Proficiency
        { spell = 448604, type = "buff", unit = "player" }, -- Spellfire Sphere
        { spell = 448659, type = "buff", unit = "player" }, -- Arcane Phoenix
        { spell = 449322, type = "buff", unit = "player", herotalent = 117256 }, -- Mana Cascade
        { spell = 449331, type = "buff", unit = "player", herotalent = 117252 }, -- Merely a Setback
        { spell = 449400, type = "buff", unit = "player", herotalent = 117250 }, -- Spellfire Spheres
        { spell = 451038, type = "buff", unit = "player" }, -- Arcane Soul
        { spell = 451049, type = "buff", unit = "player", herotalent = 117247 }, -- Burden of Power
        { spell = 451073, type = "buff", unit = "player", herotalent = 117248 }, -- Glorious Incandescence
        { spell = 453601, type = "buff", unit = "player", talent = 126546 }, -- Aether Attunement
        { spell = 453758, type = "buff", unit = "player", talent = 126544 }, -- Leydrinker
        { spell = 461145, type = "buff", unit = "player" }, -- Lingering Embers
        { spell = 461515, type = "buff", unit = "player", talent = 126545 }, -- Static Cloud
        { spell = 461531, type = "buff", unit = "player", talent = 126516 }, -- Big Brained
        { spell = 467634, type = "buff", unit = "player", talent = 126518 }, -- Aethervision
      },
      icon = 136096
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 31589, type = "debuff", unit = "target", talent = 80154 }, -- Slow
        { spell = 31661, type = "debuff", unit = "target", talent = 125819 }, -- Dragon's Breath
        { spell = 59638, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 82691, type = "debuff", unit = "target", talent = 80144 }, -- Ring of Frost
        { spell = 157981, type = "debuff", unit = "target", talent = 80160 }, -- Blast Wave
        { spell = 157997, type = "debuff", unit = "target", talent = 125820 }, -- Ice Nova
        { spell = 205708, type = "debuff", unit = "target" }, -- Chilled
        { spell = 210824, type = "debuff", unit = "target", talent = 126538 }, -- Touch of the Magi
        { spell = 386770, type = "debuff", unit = "target", talent = 80143 }, -- Freezing Cold
        { spell = 444735, type = "debuff", unit = "target" }, -- Embedded Arcane Splinter
        { spell = 453599, type = "debuff", unit = "target", talent = 126533 }, -- Arcane Debilitation
        { spell = 454004, type = "debuff", unit = "target", talent = 126504 }, -- Nether Munitions
        { spell = 454214, type = "debuff", unit = "target", herotalent = 117266 }, -- Controlled Instincts
        { spell = 461498, type = "debuff", unit = "target", talent = 126526 }, -- Dematerialize
      },
      icon = 135848
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability", buff = true }, -- Invisibility
        { spell = 116, type = "ability", requiresTarget = true }, -- Frostbolt
        { spell = 120, type = "ability" }, -- Cone of Cold
        { spell = 122, type = "ability", charges = true, debuff = true }, -- Frost Nova
        { spell = 475, type = "ability", talent = 80175 }, -- Remove Curse
        { spell = 2139, type = "ability", requiresTarget = true }, -- Counterspell
        { spell = 5143, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 126537 }, -- Arcane Missiles
        { spell = 12051, type = "ability", buff = true, talent = 126529 }, -- Evocation
        { spell = 30449, type = "ability", requiresTarget = true, talent = 80140 }, -- Spellsteal
        { spell = 30451, type = "ability", requiresTarget = true }, -- Arcane Blast
        { spell = 31589, type = "ability", debuff = true, requiresTarget = true, talent = 80154 }, -- Slow
        { spell = 31661, type = "ability", debuff = true, talent = 125819 }, -- Dragon's Breath
        { spell = 44425, type = "ability", overlayGlow = true, requiresTarget = true }, -- Arcane Barrage
        { spell = 45438, type = "ability", buff = true, talent = 80181 }, -- Ice Block
        { spell = 55342, type = "ability", buff = true, talent = 80183 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true }, -- Time Warp
        { spell = 108839, type = "ability", charges = true, talent = 80162 }, -- Ice Floes
        { spell = 110959, type = "ability", talent = 115877 }, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 80144 }, -- Ring of Frost
        { spell = 153626, type = "ability", charges = true }, -- Arcane Orb
        { spell = 157980, type = "ability", talent = 125818 }, -- Supernova
        { spell = 157981, type = "ability", debuff = true, talent = 80160 }, -- Blast Wave
        { spell = 157997, type = "ability", debuff = true, requiresTarget = true, talent = 125820 }, -- Ice Nova
        { spell = 190336, type = "ability" }, -- Conjure Refreshment
        { spell = 205025, type = "ability", buff = true, talent = 126530 }, -- Presence of Mind
        { spell = 212653, type = "ability", charges = true, talent = 80163 }, -- Shimmer
        { spell = 235450, type = "ability", buff = true, talent = 80180 }, -- Prismatic Barrier
        { spell = 319836, type = "ability", requiresTarget = true }, -- Fire Blast
        { spell = 321507, type = "ability", requiresTarget = true, talent = 126538 }, -- Touch of the Magi
        { spell = 342245, type = "ability", talent = 80174 }, -- Alter Time
        { spell = 365350, type = "ability", requiresTarget = true, talent = 126519 }, -- Arcane Surge
        { spell = 382440, type = "ability", buff = true, talent = 80171 }, -- Shifting Power
        { spell = 383121, type = "ability", talent = 80164 }, -- Mass Polymorph
        { spell = 389713, type = "ability", usable = true, talent = 80152 }, -- Displacement
        { spell = 414658, type = "ability", buff = true, talent = 80141 }, -- Ice Cold
        { spell = 414660, type = "ability", talent = 125817 }, -- Mass Barrier
        { spell = 414664, type = "ability", buff = true, talent = 115878 }, -- Mass Invisibility
        { spell = 449700, type = "ability", herotalent = 123832 }, -- Gravity Lapse
      },
      icon = 136075
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 66, type = "buff", unit = "player" }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player" }, -- Arcane Intellect
        { spell = 11426, type = "buff", unit = "player" }, -- Ice Barrier
        { spell = 45438, type = "buff", unit = "player", talent = 80181 }, -- Ice Block
        { spell = 48107, type = "buff", unit = "player" }, -- Heating Up
        { spell = 48108, type = "buff", unit = "player" }, -- Hot Streak!
        { spell = 55342, type = "buff", unit = "player", talent = 80183 }, -- Mirror Image
        { spell = 80353, type = "buff", unit = "player" }, -- Time Warp
        { spell = 108839, type = "buff", unit = "player", talent = 80162 }, -- Ice Floes
        { spell = 110960, type = "buff", unit = "player", talent = 115877 }, -- Greater Invisibility
        { spell = 116267, type = "buff", unit = "player", talent = 80177 }, -- Incanter's Flow
        { spell = 190319, type = "buff", unit = "player", talent = 124756 }, -- Combustion
        { spell = 235313, type = "buff", unit = "player", talent = 80178 }, -- Blazing Barrier
        { spell = 236060, type = "buff", unit = "player" }, -- Frenetic Speed
        { spell = 342246, type = "buff", unit = "player", talent = 80174 }, -- Alter Time
        { spell = 382290, type = "buff", unit = "player", talent = 80169 }, -- Tempest Barrier
        { spell = 382294, type = "buff", unit = "player", talent = 80170 }, -- Incantation of Swiftness
        { spell = 382440, type = "buff", unit = "player", talent = 80171 }, -- Shifting Power
        { spell = 382824, type = "buff", unit = "player", talent = 80156 }, -- Temporal Velocity
        { spell = 383395, type = "buff", unit = "player", talent = 124777 }, -- Feel the Burn
        { spell = 383492, type = "buff", unit = "player", talent = 125942 }, -- Wildfire
        { spell = 383637, type = "buff", unit = "player", talent = 124764 }, -- Fiery Rush
        { spell = 383811, type = "buff", unit = "player", talent = 124783 }, -- Fevered Incantation
        { spell = 383874, type = "buff", unit = "player", talent = 125940 }, -- Hyperthermia
        { spell = 383882, type = "buff", unit = "player", talent = 124791 }, -- Sun King's Blessing
        { spell = 383883, type = "buff", unit = "player" }, -- Fury of the Sun King
        { spell = 384035, type = "buff", unit = "player", talent = 124757 }, -- Firefall
        { spell = 389714, type = "buff", unit = "player" }, -- Displacement Beacon
        { spell = 394195, type = "buff", unit = "player", talent = 80179 }, -- Overflowing Energy
        { spell = 408673, type = "buff", unit = "player" }, -- Calefaction
        { spell = 409964, type = "buff", unit = "player" }, -- Flame's Fury
        { spell = 414658, type = "buff", unit = "player", talent = 80141 }, -- Ice Cold
        { spell = 414664, type = "buff", unit = "player", talent = 115878 }, -- Mass Invisibility
        { spell = 431039, type = "buff", unit = "player" }, -- Frost Mastery
        { spell = 431040, type = "buff", unit = "player" }, -- Fire Mastery
        { spell = 431177, type = "buff", unit = "player", herotalent = 117235 }, -- Frostfire Empowerment
        { spell = 431190, type = "buff", unit = "player", herotalent = 117243 }, -- Severe Temperatures
        { spell = 438611, type = "buff", unit = "player", herotalent = 117242 }, -- Excess Frost
        { spell = 438624, type = "buff", unit = "player", herotalent = 117240 }, -- Excess Fire
        { spell = 448604, type = "buff", unit = "player" }, -- Spellfire Sphere
        { spell = 448659, type = "buff", unit = "player" }, -- Arcane Phoenix
        { spell = 449314, type = "buff", unit = "player", herotalent = 117256 }, -- Mana Cascade
        { spell = 449400, type = "buff", unit = "player", herotalent = 117250 }, -- Spellfire Spheres
        { spell = 451049, type = "buff", unit = "player", herotalent = 117247 }, -- Burden of Power
        { spell = 451073, type = "buff", unit = "player", herotalent = 117248 }, -- Glorious Incandescence
        { spell = 453207, type = "buff", unit = "player", talent = 124755 }, -- Lit Fuse
        { spell = 453283, type = "buff", unit = "player", talent = 126021 }, -- Flame Accelerant
        { spell = 453329, type = "buff", unit = "player", talent = 124770 }, -- Majesty of the Phoenix
        { spell = 453385, type = "buff", unit = "player", talent = 124765 }, -- Fire's Ire
        { spell = 457729, type = "buff", unit = "player", talent = 126020 }, -- Sparking Cinders
        { spell = 458964, type = "buff", unit = "player", talent = 126019 }, -- Heat Shimmer
        { spell = 461145, type = "buff", unit = "player" }, -- Lingering Embers
        { spell = 461515, type = "buff", unit = "player", talent = 126545 }, -- Static Cloud
      },
      icon = 1035045
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 2120, type = "debuff", unit = "target" }, -- Flamestrike
        { spell = 12654, type = "debuff", unit = "target" }, -- Ignite
        { spell = 31589, type = "debuff", unit = "target", talent = 80154 }, -- Slow
        { spell = 31661, type = "debuff", unit = "target", talent = 125819 }, -- Dragon's Breath
        { spell = 59638, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 82691, type = "debuff", unit = "target", talent = 80144 }, -- Ring of Frost
        { spell = 155158, type = "debuff", unit = "target" }, -- Meteor Burn
        { spell = 157981, type = "debuff", unit = "target", talent = 80160 }, -- Blast Wave
        { spell = 217694, type = "debuff", unit = "target" }, -- Living Bomb
        { spell = 383608, type = "debuff", unit = "target", talent = 124774 }, -- Improved Scorch
        { spell = 386770, type = "debuff", unit = "target", talent = 80143 }, -- Freezing Cold
        { spell = 431044, type = "debuff", unit = "target", herotalent = 117244 }, -- Frostfire Bolt
        { spell = 449700, type = "debuff", unit = "target", herotalent = 123832 }, -- Gravity Lapse
        { spell = 453268, type = "debuff", unit = "target", talent = 124763 }, -- Controlled Destruction
      },
      icon = 135818
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability", buff = true }, -- Invisibility
        { spell = 120, type = "ability" }, -- Cone of Cold
        { spell = 122, type = "ability", charges = true, debuff = true }, -- Frost Nova
        { spell = 475, type = "ability", talent = 80175 }, -- Remove Curse
        { spell = 2139, type = "ability" }, -- Counterspell
        { spell = 31661, type = "ability", debuff = true, talent = 125819 }, -- Dragon's Breath
        { spell = 45438, type = "ability", buff = true, talent = 80181 }, -- Ice Block
        { spell = 55342, type = "ability", buff = true, talent = 80183 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true }, -- Time Warp
        { spell = 108839, type = "ability", charges = true, buff = true, talent = 80162 }, -- Ice Floes
        { spell = 108853, type = "ability", charges = true, overlayGlow = true, talent = 124750 }, -- Fire Blast
        { spell = 110959, type = "ability", talent = 115877 }, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 80144 }, -- Ring of Frost
        { spell = 153561, type = "ability", talent = 124779 }, -- Meteor
        { spell = 157980, type = "ability", talent = 125818 }, -- Supernova
        { spell = 157981, type = "ability", debuff = true, talent = 80160 }, -- Blast Wave
        { spell = 190319, type = "ability", buff = true, talent = 124756 }, -- Combustion
        { spell = 190336, type = "ability" }, -- Conjure Refreshment
        { spell = 212653, type = "ability", charges = true, talent = 80163 }, -- Shimmer
        { spell = 235313, type = "ability", buff = true, talent = 80178 }, -- Blazing Barrier
        { spell = 257541, type = "ability", charges = true, overlayGlow = true, talent = 124775 }, -- Phoenix Flames
        { spell = 342245, type = "ability", talent = 80174 }, -- Alter Time
        { spell = 382440, type = "ability", buff = true, talent = 80171 }, -- Shifting Power
        { spell = 383121, type = "ability", talent = 80164 }, -- Mass Polymorph
        { spell = 389713, type = "ability", usable = true, talent = 80152 }, -- Displacement
        { spell = 414658, type = "ability", buff = true, talent = 80141 }, -- Ice Cold
        { spell = 414660, type = "ability", talent = 125817 }, -- Mass Barrier
        { spell = 414664, type = "ability", buff = true, talent = 115878 }, -- Mass Invisibility
        { spell = 449700, type = "ability", debuff = true, herotalent = 123832 }, -- Gravity Lapse
      },
      icon = 610633
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 66, type = "buff", unit = "player" }, -- Invisibility
        { spell = 130, type = "buff", unit = "player" }, -- Slow Fall
        { spell = 1459, type = "buff", unit = "player" }, -- Arcane Intellect
        { spell = 11426, type = "buff", unit = "player", talent = 80176 }, -- Ice Barrier
        { spell = 12472, type = "buff", unit = "player", talent = 80235 }, -- Icy Veins
        { spell = 44544, type = "buff", unit = "player", talent = 80227 }, -- Fingers of Frost
        { spell = 45438, type = "buff", unit = "player", talent = 80181 }, -- Ice Block
        { spell = 55342, type = "buff", unit = "player", talent = 80183 }, -- Mirror Image
        { spell = 80353, type = "buff", unit = "player" }, -- Time Warp
        { spell = 108839, type = "buff", unit = "player", talent = 80162 }, -- Ice Floes
        { spell = 110960, type = "buff", unit = "player", talent = 115877 }, -- Greater Invisibility
        { spell = 116267, type = "buff", unit = "player", talent = 80177 }, -- Incanter's Flow
        { spell = 190446, type = "buff", unit = "player", talent = 80244 }, -- Brain Freeze
        { spell = 199844, type = "buff", unit = "player" }, -- Glacial Spike!
        { spell = 205473, type = "buff", unit = "player" }, -- Icicles
        { spell = 205766, type = "buff", unit = "player", talent = 80230 }, -- Bone Chilling
        { spell = 235313, type = "buff", unit = "player", talent = 80178 }, -- Blazing Barrier
        { spell = 270232, type = "buff", unit = "player", talent = 80212 }, -- Freezing Rain
        { spell = 278310, type = "buff", unit = "player", talent = 80224 }, -- Chain Reaction
        { spell = 342246, type = "buff", unit = "player", talent = 80174 }, -- Alter Time
        { spell = 382106, type = "buff", unit = "player", talent = 80250 }, -- Freezing Winds
        { spell = 382113, type = "buff", unit = "player", talent = 80218 }, -- Cold Front
        { spell = 382148, type = "buff", unit = "player", talent = 80219 }, -- Slick Ice
        { spell = 382290, type = "buff", unit = "player", talent = 80169 }, -- Tempest Barrier
        { spell = 382294, type = "buff", unit = "player", talent = 80170 }, -- Incantation of Swiftness
        { spell = 382440, type = "buff", unit = "player", talent = 80171 }, -- Shifting Power
        { spell = 382824, type = "buff", unit = "player", talent = 80156 }, -- Temporal Velocity
        { spell = 389714, type = "buff", unit = "player" }, -- Displacement Beacon
        { spell = 394195, type = "buff", unit = "player", talent = 80179 }, -- Overflowing Energy
        { spell = 414658, type = "buff", unit = "player", talent = 80141 }, -- Ice Cold
        { spell = 414664, type = "buff", unit = "player", talent = 115878 }, -- Mass Invisibility
        { spell = 417488, type = "buff", unit = "player" }, -- Frigid Empowerment
        { spell = 417492, type = "buff", unit = "player", talent = 80215 }, -- Cryopathy
        { spell = 431039, type = "buff", unit = "player" }, -- Frost Mastery
        { spell = 431040, type = "buff", unit = "player" }, -- Fire Mastery
        { spell = 431177, type = "buff", unit = "player", herotalent = 117235 }, -- Frostfire Empowerment
        { spell = 431190, type = "buff", unit = "player", herotalent = 117243 }, -- Severe Temperatures
        { spell = 438611, type = "buff", unit = "player", herotalent = 117242 }, -- Excess Frost
        { spell = 438624, type = "buff", unit = "player", herotalent = 117240 }, -- Excess Fire
        { spell = 444976, type = "buff", unit = "player", herotalent = 123407 }, -- Unerring Proficiency
        { spell = 454371, type = "buff", unit = "player", talent = 125131 }, -- Death's Chill
        { spell = 455122, type = "buff", unit = "player", talent = 80233 }, -- Permafrost Lances
        { spell = 458411, type = "buff", unit = "player", herotalent = 117258 }, -- Spellfrost Teachings
      },
      icon = 236227
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 122, type = "debuff", unit = "target" }, -- Frost Nova
        { spell = 12486, type = "debuff", unit = "target" }, -- Blizzard
        { spell = 31661, type = "debuff", unit = "target", talent = 125819 }, -- Dragon's Breath
        { spell = 33395, type = "debuff", unit = "target" }, -- Freeze
        { spell = 59638, type = "debuff", unit = "target" }, -- Frostbolt
        { spell = 82691, type = "debuff", unit = "target", talent = 80144 }, -- Ring of Frost
        { spell = 135029, type = "debuff", unit = "target" }, -- Water Jet
        { spell = 155158, type = "debuff", unit = "target" }, -- Meteor Burn
        { spell = 157981, type = "debuff", unit = "target", talent = 80160 }, -- Blast Wave
        { spell = 157997, type = "debuff", unit = "target", talent = 125820 }, -- Ice Nova
        { spell = 205021, type = "debuff", unit = "target", talent = 80216 }, -- Ray of Frost
        { spell = 205708, type = "debuff", unit = "target" }, -- Chilled
        { spell = 212792, type = "debuff", unit = "target" }, -- Cone of Cold
        { spell = 228354, type = "debuff", unit = "target", talent = 80243 }, -- Flurry
        { spell = 228358, type = "debuff", unit = "target" }, -- Winter's Chill
        { spell = 228600, type = "debuff", unit = "target", talent = 80220 }, -- Glacial Spike
        { spell = 289308, type = "debuff", unit = "target", talent = 80242 }, -- Frozen Orb
        { spell = 378760, type = "debuff", unit = "target", talent = 102428 }, -- Frostbite
        { spell = 386770, type = "debuff", unit = "target", talent = 80143 }, -- Freezing Cold
        { spell = 417490, type = "debuff", unit = "target" }, -- Numbing Blast
        { spell = 431044, type = "debuff", unit = "target", herotalent = 117244 }, -- Frostfire Bolt
        { spell = 438671, type = "debuff", unit = "target" }, -- Living Bomb
        { spell = 443740, type = "debuff", unit = "target" }, -- Embedded Frost Splinter
        { spell = 463192, type = "debuff", unit = "target", herotalent = 117266 }, -- Controlled Instincts
      },
      icon = 236208
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 66, type = "ability", buff = true }, -- Invisibility
        { spell = 120, type = "ability" }, -- Cone of Cold
        { spell = 122, type = "ability", charges = true, debuff = true }, -- Frost Nova
        { spell = 475, type = "ability", talent = 80175 }, -- Remove Curse
        { spell = 2139, type = "ability" }, -- Counterspell
        { spell = 11426, type = "ability", buff = true, talent = 80176 }, -- Ice Barrier
        { spell = 12472, type = "ability", buff = true, talent = 80235 }, -- Icy Veins
        { spell = 30455, type = "ability", charges = true, overlayGlow = true, talent = 80241 }, -- Ice Lance
        { spell = 31589, type = "ability", requiresTarget = true, talent = 80154 }, -- Slow
        { spell = 31661, type = "ability", debuff = true, talent = 125819 }, -- Dragon's Breath
        { spell = 31707, type = "ability" }, -- Waterbolt
        { spell = 33395, type = "ability", debuff = true }, -- Freeze
        { spell = 44614, type = "ability", charges = true, overlayGlow = true, talent = 80243 }, -- Flurry
        { spell = 45438, type = "ability", buff = true, usable = true, talent = 80181 }, -- Ice Block
        { spell = 55342, type = "ability", buff = true, talent = 80183 }, -- Mirror Image
        { spell = 80353, type = "ability", buff = true }, -- Time Warp
        { spell = 84714, type = "ability", overlayGlow = true, talent = 80242 }, -- Frozen Orb
        { spell = 108839, type = "ability", charges = true, buff = true, talent = 80162 }, -- Ice Floes
        { spell = 110959, type = "ability", talent = 115877 }, -- Greater Invisibility
        { spell = 113724, type = "ability", talent = 80144 }, -- Ring of Frost
        { spell = 135029, type = "ability", debuff = true }, -- Water Jet
        { spell = 153595, type = "ability", talent = 80248 }, -- Comet Storm
        { spell = 157980, type = "ability", talent = 125818 }, -- Supernova
        { spell = 157981, type = "ability", debuff = true, talent = 80160 }, -- Blast Wave
        { spell = 157997, type = "ability", debuff = true, talent = 125820 }, -- Ice Nova
        { spell = 190336, type = "ability" }, -- Conjure Refreshment
        { spell = 190356, type = "ability", overlayGlow = true }, -- Blizzard
        { spell = 205021, type = "ability", debuff = true, overlayGlow = true, talent = 80216 }, -- Ray of Frost
        { spell = 212653, type = "ability", charges = true, talent = 80163 }, -- Shimmer
        { spell = 235219, type = "ability" }, -- Cold Snap
        { spell = 319836, type = "ability", overlayGlow = true, talent = 124750 }, -- Fire Blast
        { spell = 342245, type = "ability", talent = 80174 }, -- Alter Time
        { spell = 382440, type = "ability", buff = true, talent = 80171 }, -- Shifting Power
        { spell = 383121, type = "ability", talent = 80164 }, -- Mass Polymorph
        { spell = 389713, type = "ability", usable = true, talent = 80152 }, -- Displacement
        { spell = 414658, type = "ability", buff = true, talent = 80141 }, -- Ice Cold
        { spell = 414660, type = "ability", talent = 125817 }, -- Mass Barrier
        { spell = 414664, type = "ability", buff = true, talent = 115878 }, -- Mass Invisibility
      },
      icon = 629077
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 48018, type = "buff", unit = "player", talent = 124694 }, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player", talent = 91441 }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 91444 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 91460 }, -- Burning Rush
        { spell = 196099, type = "buff", unit = "player", talent = 124691 }, -- Grimoire of Sacrifice
        { spell = 264571, type = "buff", unit = "player", talent = 91568 }, -- Nightfall
        { spell = 328774, type = "buff", unit = "player", talent = 91442 }, -- Amplify Curse
        { spell = 333889, type = "buff", unit = "player", talent = 91439 }, -- Fel Domination
        { spell = 386647, type = "buff", unit = "player", talent = 91449 }, -- Lifeblood
        { spell = 387018, type = "buff", unit = "player", talent = 126062 }, -- Dark Harvest
        { spell = 387079, type = "buff", unit = "player", talent = 91551 }, -- Tormented Crescendo
        { spell = 387626, type = "buff", unit = "player", talent = 91469 }, -- Soulburn
        { spell = 387633, type = "buff", unit = "player" }, -- Soulburn: Demonic Circle
        { spell = 387636, type = "buff", unit = "player" }, -- Soulburn: Healthstone
        { spell = 389614, type = "buff", unit = "player", talent = 91465 }, -- Abyss Walker
        { spell = 442726, type = "buff", unit = "player", herotalent = 117439 }, -- Malevolence
        { spell = 449793, type = "buff", unit = "player" }, -- Succulent Soul
        { spell = 458043, type = "buff", unit = "player", talent = 91579 }, -- Malign Omen
        { spell = 17767, type = "buff", unit = "pet" }, -- Shadow Bulwark
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
        { spell = 5484, type = "debuff", unit = "target", talent = 91458 }, -- Howl of Terror
        { spell = 6360, type = "debuff", unit = "target" }, -- Whiplash
        { spell = 6789, type = "debuff", unit = "target", talent = 91457 }, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target" }, -- Suffering
        { spell = 27243, type = "debuff", unit = "target", talent = 91571 }, -- Seed of Corruption
        { spell = 30283, type = "debuff", unit = "target", talent = 91452 }, -- Shadowfury
        { spell = 32390, type = "debuff", unit = "target", talent = 124690 }, -- Shadow Embrace
        { spell = 48181, type = "debuff", unit = "target", talent = 91552 }, -- Haunt
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
        { spell = 198590, type = "debuff", unit = "target", talent = 124692 }, -- Drain Soul
        { spell = 205179, type = "debuff", unit = "target", talent = 126061 }, -- Phantom Singularity
        { spell = 234153, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 316099, type = "debuff", unit = "target", talent = 91570 }, -- Unstable Affliction
        { spell = 334275, type = "debuff", unit = "target" }, -- Curse of Exhaustion
        { spell = 384069, type = "debuff", unit = "target", talent = 91450 }, -- Shadowflame
        { spell = 386931, type = "debuff", unit = "target", talent = 91556 }, -- Vile Taint
        { spell = 386997, type = "debuff", unit = "target", talent = 91578 }, -- Soul Rot
        { spell = 417537, type = "debuff", unit = "target", talent = 91503 }, -- Oblivion
        { spell = 442804, type = "debuff", unit = "target", herotalent = 117419 }, -- Curse of the Satyr
        { spell = 445474, type = "debuff", unit = "target", herotalent = 117437 }, -- Wither
        { spell = 449587, type = "debuff", unit = "target", herotalent = 123309 }, -- Aura of Enfeeblement
        { spell = 450538, type = "debuff", unit = "target", herotalent = 117444 }, -- Soul Anathema
        { spell = 450591, type = "debuff", unit = "target", herotalent = 117420 }, -- Shared Fate
        { spell = 458219, type = "debuff", unit = "target", talent = 126065 }, -- Infirmity
      },
      icon = 136139
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 686, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Shadow Bolt
        { spell = 698, type = "ability", usable = true }, -- Ritual of Summoning
        { spell = 702, type = "ability", debuff = true, requiresTarget = true }, -- Curse of Weakness
        { spell = 980, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Agony
        { spell = 3110, type = "ability", requiresTarget = true }, -- Firebolt
        { spell = 3716, type = "ability" }, -- Consuming Shadows
        { spell = 5484, type = "ability", debuff = true, talent = 91458 }, -- Howl of Terror
        { spell = 5782, type = "ability", requiresTarget = true, usable = true }, -- Fear
        { spell = 6360, type = "ability", debuff = true, requiresTarget = true }, -- Whiplash
        { spell = 6789, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 91457 }, -- Mortal Coil
        { spell = 7814, type = "ability", requiresTarget = true }, -- Lash of Pain
        { spell = 7870, type = "ability" }, -- Lesser Invisibility
        { spell = 17735, type = "ability", debuff = true, requiresTarget = true }, -- Suffering
        { spell = 17767, type = "ability", buff = true, unit = 'pet' }, -- Shadow Bulwark
        { spell = 19647, type = "ability" }, -- Spell Lock
        { spell = 20707, type = "ability", buff = true, usable = true }, -- Soulstone
        { spell = 27243, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 91571 }, -- Seed of Corruption
        { spell = 29893, type = "ability", usable = true }, -- Create Soulwell
        { spell = 30283, type = "ability", debuff = true, usable = true, talent = 91452 }, -- Shadowfury
        { spell = 48018, type = "ability", buff = true, usable = true, talent = 124694 }, -- Demonic Circle
        { spell = 48020, type = "ability", overlayGlow = true, usable = true }, -- Demonic Circle: Teleport
        { spell = 48181, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 91552 }, -- Haunt
        { spell = 54049, type = "ability", requiresTarget = true }, -- Shadow Bite
        { spell = 104773, type = "ability", buff = true, usable = true }, -- Unending Resolve
        { spell = 108416, type = "ability", buff = true, talent = 91444 }, -- Dark Pact
        { spell = 108503, type = "ability", talent = 124691 }, -- Grimoire of Sacrifice
        { spell = 111771, type = "ability", overlayGlow = true, usable = true, talent = 91466 }, -- Demonic Gateway
        { spell = 112042, type = "ability", buff = true, unit = 'pet' }, -- Threatening Presence
        { spell = 119907, type = "ability" }, -- Shadow Bulwark
        { spell = 119910, type = "ability" }, -- Spell Lock
        { spell = 132411, type = "ability" }, -- Singe Magic
        { spell = 205179, type = "ability", debuff = true, talent = 126061 }, -- Phantom Singularity
        { spell = 205180, type = "ability", totem = true, usable = true, talent = 91554 }, -- Summon Darkglare
        { spell = 234153, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Drain Life
        { spell = 278350, type = "ability", talent = 91556 }, -- Vile Taint
        { spell = 316099, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 91570 }, -- Unstable Affliction
        { spell = 328774, type = "ability", buff = true, usable = true, talent = 91442 }, -- Amplify Curse
        { spell = 333889, type = "ability", buff = true, usable = true, talent = 91439 }, -- Fel Domination
        { spell = 342601, type = "ability", usable = true }, -- Ritual of Doom
        { spell = 384069, type = "ability", debuff = true, talent = 91450 }, -- Shadowflame
        { spell = 385899, type = "ability", usable = true, talent = 91469 }, -- Soulburn
        { spell = 386997, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 91578 }, -- Soul Rot
        { spell = 417537, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 91503 }, -- Oblivion
        { spell = 442726, type = "ability", buff = true, herotalent = 117439 }, -- Malevolence
        { spell = 445468, type = "ability", requiresTarget = true, herotalent = 117437 }, -- Wither
      },
      icon = 135808
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 48018, type = "buff", unit = "player", talent = 124694 }, -- Demonic Circle
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player", talent = 91441 }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 91444 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 91460 }, -- Burning Rush
        { spell = 205146, type = "buff", unit = "player", talent = 125848 }, -- Demonic Calling
        { spell = 264173, type = "buff", unit = "player" }, -- Demonic Core
        { spell = 328774, type = "buff", unit = "player", talent = 91442 }, -- Amplify Curse
        { spell = 333889, type = "buff", unit = "player", talent = 91439 }, -- Fel Domination
        { spell = 386614, type = "buff", unit = "player", talent = 91464 }, -- Accrued Vitality
        { spell = 386647, type = "buff", unit = "player", talent = 91449 }, -- Lifeblood
        { spell = 387393, type = "buff", unit = "player", talent = 125831 }, -- Dread Calling
        { spell = 387626, type = "buff", unit = "player", talent = 91469 }, -- Soulburn
        { spell = 387633, type = "buff", unit = "player" }, -- Soulburn: Demonic Circle
        { spell = 389614, type = "buff", unit = "player", talent = 91465 }, -- Abyss Walker
        { spell = 428524, type = "buff", unit = "player" }, -- Demonic Art: Overlord
        { spell = 431944, type = "buff", unit = "player" }, -- Diabolic Ritual: Overlord
        { spell = 432794, type = "buff", unit = "player" }, -- Demonic Art: Mother of Chaos
        { spell = 432795, type = "buff", unit = "player" }, -- Demonic Art: Pit Lord
        { spell = 432815, type = "buff", unit = "player" }, -- Diabolic Ritual: Mother of Chaos
        { spell = 432816, type = "buff", unit = "player" }, -- Diabolic Ritual: Pit Lord
        { spell = 433885, type = "buff", unit = "player", herotalent = 117427 }, -- Ruination
        { spell = 433891, type = "buff", unit = "player" }, -- Infernal Bolt
        { spell = 434559, type = "buff", unit = "player", herotalent = 117449 }, -- Infernal Vitality
        { spell = 434561, type = "buff", unit = "player", herotalent = 118839 }, -- Infernal Bulwark
        { spell = 449793, type = "buff", unit = "player" }, -- Succulent Soul
        { spell = 456323, type = "buff", unit = "player", herotalent = 117428 }, -- Abyssal Dominion
        { spell = 30151, type = "buff", unit = "pet" }, -- Pursuit
        { spell = 32752, type = "buff", unit = "pet" }, -- Summoning Disorientation
        { spell = 89751, type = "buff", unit = "pet" }, -- Felstorm
        { spell = 112042, type = "buff", unit = "pet" }, -- Threatening Presence
        { spell = 265273, type = "buff", unit = "pet" }, -- Demonic Power
        { spell = 267171, type = "buff", unit = "pet", talent = 125832 }, -- Demonic Strength
        { spell = 386176, type = "buff", unit = "pet", talent = 125826 }, -- Annihilan Training
        { spell = 386601, type = "buff", unit = "pet" }, -- Fiendish Wrath
        { spell = 387496, type = "buff", unit = "pet", talent = 125859 }, -- Antoran Armaments
        { spell = 387601, type = "buff", unit = "pet", talent = 125847 }, -- The Expendables
      },
      icon = 1378284
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 702, type = "debuff", unit = "target" }, -- Curse of Weakness
        { spell = 1714, type = "debuff", unit = "target" }, -- Curse of Tongues
        { spell = 5484, type = "debuff", unit = "target", talent = 91458 }, -- Howl of Terror
        { spell = 6360, type = "debuff", unit = "target" }, -- Whiplash
        { spell = 6789, type = "debuff", unit = "target", talent = 91457 }, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target" }, -- Suffering
        { spell = 30213, type = "debuff", unit = "target" }, -- Legion Strike
        { spell = 30283, type = "debuff", unit = "target", talent = 91452 }, -- Shadowfury
        { spell = 89766, type = "debuff", unit = "target" }, -- Axe Toss
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 146739, type = "debuff", unit = "target" }, -- Corruption
        { spell = 234153, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 267997, type = "debuff", unit = "target" }, -- Bile Spit
        { spell = 270569, type = "debuff", unit = "target", talent = 125872 }, -- Wicked Maw
        { spell = 334275, type = "debuff", unit = "target" }, -- Curse of Exhaustion
        { spell = 384069, type = "debuff", unit = "target", talent = 91450 }, -- Shadowflame
        { spell = 387402, type = "debuff", unit = "target", talent = 125857 }, -- Fel Sunder
        { spell = 405802, type = "debuff", unit = "target", talent = 125861 }, -- Umbral Blaze
        { spell = 409722, type = "debuff", unit = "target" }, -- Temporal Wound
        { spell = 434424, type = "debuff", unit = "target" }, -- Cloven Soul
        { spell = 450538, type = "debuff", unit = "target", herotalent = 117444 }, -- Soul Anathema
        { spell = 450591, type = "debuff", unit = "target", herotalent = 117420 }, -- Shared Fate
        { spell = 460553, type = "debuff", unit = "target", talent = 125865 }, -- Doom
      },
      icon = 136122
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 172, type = "ability", requiresTarget = true, usable = true }, -- Corruption
        { spell = 686, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Shadow Bolt
        { spell = 698, type = "ability", usable = true }, -- Ritual of Summoning
        { spell = 702, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Curse of Weakness
        { spell = 3110, type = "ability", requiresTarget = true }, -- Firebolt
        { spell = 3716, type = "ability" }, -- Consuming Shadows
        { spell = 5484, type = "ability", debuff = true, talent = 91458 }, -- Howl of Terror
        { spell = 5782, type = "ability", requiresTarget = true, usable = true }, -- Fear
        { spell = 6360, type = "ability", debuff = true, requiresTarget = true }, -- Whiplash
        { spell = 6789, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 91457 }, -- Mortal Coil
        { spell = 7814, type = "ability", requiresTarget = true }, -- Lash of Pain
        { spell = 7870, type = "ability" }, -- Lesser Invisibility
        { spell = 17735, type = "ability", debuff = true, requiresTarget = true }, -- Suffering
        { spell = 17767, type = "ability" }, -- Shadow Bulwark
        { spell = 19505, type = "ability", requiresTarget = true }, -- Devour Magic
        { spell = 19647, type = "ability", requiresTarget = true }, -- Spell Lock
        { spell = 20707, type = "ability", buff = true, usable = true }, -- Soulstone
        { spell = 29893, type = "ability", usable = true }, -- Create Soulwell
        { spell = 30151, type = "ability", buff = true, unit = 'pet', requiresTarget = true }, -- Pursuit
        { spell = 30213, type = "ability", debuff = true, requiresTarget = true }, -- Legion Strike
        { spell = 30283, type = "ability", debuff = true, usable = true, talent = 91452 }, -- Shadowfury
        { spell = 48018, type = "ability", buff = true, usable = true, talent = 124694 }, -- Demonic Circle
        { spell = 48020, type = "ability", overlayGlow = true, usable = true }, -- Demonic Circle: Teleport
        { spell = 54049, type = "ability", requiresTarget = true }, -- Shadow Bite
        { spell = 89751, type = "ability", buff = true, unit = 'pet' }, -- Felstorm
        { spell = 89766, type = "ability", debuff = true, requiresTarget = true }, -- Axe Toss
        { spell = 89792, type = "ability" }, -- Flee
        { spell = 89808, type = "ability" }, -- Singe Magic
        { spell = 104316, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 125837 }, -- Call Dreadstalkers
        { spell = 104773, type = "ability", buff = true, usable = true }, -- Unending Resolve
        { spell = 105174, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Hand of Gul'dan
        { spell = 108416, type = "ability", buff = true, talent = 91444 }, -- Dark Pact
        { spell = 111771, type = "ability", overlayGlow = true, usable = true, talent = 91466 }, -- Demonic Gateway
        { spell = 111898, type = "ability", totem = true, talent = 125852 }, -- Grimoire: Felguard
        { spell = 112042, type = "ability", buff = true, unit = 'pet' }, -- Threatening Presence
        { spell = 119905, type = "ability" }, -- Singe Magic
        { spell = 119910, type = "ability", requiresTarget = true }, -- Spell Lock
        { spell = 119914, type = "ability", requiresTarget = true }, -- Axe Toss
        { spell = 125439, type = "ability" }, -- Revive Battle Pets
        { spell = 134477, type = "ability", buff = true, unit = 'pet' }, -- Threatening Presence
        { spell = 196277, type = "ability", charges = true, requiresTarget = true, usable = true, talent = 125836 }, -- Implosion
        { spell = 234153, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Drain Life
        { spell = 264057, type = "ability", talent = 125844 }, -- Soul Strike
        { spell = 264119, type = "ability", totem = true, talent = 125845 }, -- Summon Vilefiend
        { spell = 264130, type = "ability", usable = true, talent = 125862 }, -- Power Siphon
        { spell = 264178, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Demonbolt
        { spell = 265187, type = "ability", usable = true, talent = 125850 }, -- Summon Demonic Tyrant
        { spell = 267171, type = "ability", buff = true, unit = 'pet', talent = 125832 }, -- Demonic Strength
        { spell = 267211, type = "ability", talent = 125833 }, -- Bilescourge Bombers
        { spell = 328774, type = "ability", buff = true, usable = true, talent = 91442 }, -- Amplify Curse
        { spell = 333889, type = "ability", buff = true, usable = true, talent = 91439 }, -- Fel Domination
        { spell = 342601, type = "ability", usable = true }, -- Ritual of Doom
        { spell = 384069, type = "ability", debuff = true, talent = 91450 }, -- Shadowflame
        { spell = 385899, type = "ability", usable = true, talent = 91469 }, -- Soulburn
        { spell = 386833, type = "ability", talent = 125840 }, -- Guillotine
        { spell = 455465, type = "ability", totem = true }, -- Summon Gloomhound
        { spell = 455476, type = "ability", totem = true }, -- Summon Charhound
      },
      icon = 1378282
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 48018, type = "buff", unit = "player", talent = 124694 }, -- Demonic Circle
        { spell = 59752, type = "buff", unit = "player" }, -- Will to Survive
        { spell = 104773, type = "buff", unit = "player" }, -- Unending Resolve
        { spell = 108366, type = "buff", unit = "player", talent = 91441 }, -- Soul Leech
        { spell = 108416, type = "buff", unit = "player", talent = 91444 }, -- Dark Pact
        { spell = 111400, type = "buff", unit = "player", talent = 91460 }, -- Burning Rush
        { spell = 117828, type = "buff", unit = "player", talent = 91590 }, -- Backdraft
        { spell = 196099, type = "buff", unit = "player", talent = 125618 }, -- Grimoire of Sacrifice
        { spell = 328774, type = "buff", unit = "player", talent = 91442 }, -- Amplify Curse
        { spell = 333889, type = "buff", unit = "player", talent = 91439 }, -- Fel Domination
        { spell = 386647, type = "buff", unit = "player", talent = 91449 }, -- Lifeblood
        { spell = 387109, type = "buff", unit = "player", talent = 91583 }, -- Conflagration of Chaos
        { spell = 387154, type = "buff", unit = "player", talent = 91477 }, -- Burn to Ashes
        { spell = 387157, type = "buff", unit = "player", talent = 91483 }, -- Ritual of Ruin
        { spell = 387158, type = "buff", unit = "player" }, -- Impending Ruin
        { spell = 387263, type = "buff", unit = "player", talent = 91485 }, -- Flashpoint
        { spell = 387283, type = "buff", unit = "player", talent = 91478 }, -- Power Overwhelming
        { spell = 387570, type = "buff", unit = "player", talent = 91474 }, -- Rolling Havoc
        { spell = 387626, type = "buff", unit = "player", talent = 91469 }, -- Soulburn
        { spell = 387633, type = "buff", unit = "player" }, -- Soulburn: Demonic Circle
        { spell = 389614, type = "buff", unit = "player", talent = 91465 }, -- Abyss Walker
        { spell = 394087, type = "buff", unit = "player", talent = 91494 }, -- Mayhem
        { spell = 394810, type = "buff", unit = "player" }, -- Soulburn: Drain Life
        { spell = 417282, type = "buff", unit = "player", talent = 91473 }, -- Crashing Chaos
        { spell = 428524, type = "buff", unit = "player" }, -- Demonic Art: Overlord
        { spell = 431944, type = "buff", unit = "player" }, -- Diabolic Ritual: Overlord
        { spell = 432794, type = "buff", unit = "player" }, -- Demonic Art: Mother of Chaos
        { spell = 432795, type = "buff", unit = "player" }, -- Demonic Art: Pit Lord
        { spell = 432815, type = "buff", unit = "player" }, -- Diabolic Ritual: Mother of Chaos
        { spell = 432816, type = "buff", unit = "player" }, -- Diabolic Ritual: Pit Lord
        { spell = 433885, type = "buff", unit = "player", herotalent = 117427 }, -- Ruination
        { spell = 433891, type = "buff", unit = "player" }, -- Infernal Bolt
        { spell = 434559, type = "buff", unit = "player", herotalent = 117449 }, -- Infernal Vitality
        { spell = 434561, type = "buff", unit = "player", herotalent = 118839 }, -- Infernal Bulwark
        { spell = 442726, type = "buff", unit = "player", herotalent = 117439 }, -- Malevolence
        { spell = 457555, type = "buff", unit = "player", talent = 126007 }, -- Decimation
        { spell = 7870, type = "buff", unit = "pet" }, -- Lesser Invisibility
        { spell = 17767, type = "buff", unit = "pet" }, -- Shadow Bulwark
        { spell = 32752, type = "buff", unit = "pet" }, -- Summoning Disorientation
        { spell = 112042, type = "buff", unit = "pet" }, -- Threatening Presence
        { spell = 386176, type = "buff", unit = "pet", talent = 125826 }, -- Annihilan Training
        { spell = 387496, type = "buff", unit = "pet", talent = 125859 }, -- Antoran Armaments
      },
      icon = 136150
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 702, type = "debuff", unit = "target" }, -- Curse of Weakness
        { spell = 1714, type = "debuff", unit = "target" }, -- Curse of Tongues
        { spell = 5484, type = "debuff", unit = "target", talent = 91458 }, -- Howl of Terror
        { spell = 6360, type = "debuff", unit = "target" }, -- Whiplash
        { spell = 6789, type = "debuff", unit = "target", talent = 91457 }, -- Mortal Coil
        { spell = 17735, type = "debuff", unit = "target" }, -- Suffering
        { spell = 17877, type = "debuff", unit = "target", talent = 91582 }, -- Shadowburn
        { spell = 22703, type = "debuff", unit = "target" }, -- Infernal Awakening
        { spell = 80240, type = "debuff", unit = "target", talent = 91493 }, -- Havoc
        { spell = 118699, type = "debuff", unit = "target" }, -- Fear
        { spell = 157736, type = "debuff", unit = "target" }, -- Immolate
        { spell = 196414, type = "debuff", unit = "target", talent = 91501 }, -- Eradication
        { spell = 234153, type = "debuff", unit = "target" }, -- Drain Life
        { spell = 265931, type = "debuff", unit = "target", talent = 91591 }, -- Conflagrate
        { spell = 334275, type = "debuff", unit = "target" }, -- Curse of Exhaustion
        { spell = 384069, type = "debuff", unit = "target", talent = 91450 }, -- Shadowflame
        { spell = 387096, type = "debuff", unit = "target", talent = 91489 }, -- Pyrogenics
        { spell = 409992, type = "debuff", unit = "target" }, -- Temporal Wound
        { spell = 434424, type = "debuff", unit = "target" }, -- Cloven Soul
        { spell = 442804, type = "debuff", unit = "target", herotalent = 117419 }, -- Curse of the Satyr
        { spell = 445474, type = "debuff", unit = "target", herotalent = 117437 }, -- Wither
        { spell = 449587, type = "debuff", unit = "target", herotalent = 123309 }, -- Aura of Enfeeblement
      },
      icon = 135817
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 698, type = "ability", usable = true }, -- Ritual of Summoning
        { spell = 702, type = "ability", debuff = true, requiresTarget = true }, -- Curse of Weakness
        { spell = 1122, type = "ability", talent = 91502 }, -- Summon Infernal
        { spell = 3110, type = "ability", requiresTarget = true }, -- Firebolt
        { spell = 3716, type = "ability" }, -- Consuming Shadows
        { spell = 5484, type = "ability", debuff = true, talent = 91458 }, -- Howl of Terror
        { spell = 5697, type = "ability", buff = true, requiresTarget = true }, -- Unending Breath
        { spell = 5782, type = "ability", requiresTarget = true }, -- Fear
        { spell = 6353, type = "ability", overlayGlow = true, requiresTarget = true, talent = 91492 }, -- Soul Fire
        { spell = 6360, type = "ability", debuff = true, requiresTarget = true }, -- Whiplash
        { spell = 6789, type = "ability", debuff = true, requiresTarget = true, talent = 91457 }, -- Mortal Coil
        { spell = 7814, type = "ability", requiresTarget = true }, -- Lash of Pain
        { spell = 7870, type = "ability", buff = true, unit = 'pet' }, -- Lesser Invisibility
        { spell = 17735, type = "ability", debuff = true, requiresTarget = true }, -- Suffering
        { spell = 17767, type = "ability", buff = true, unit = 'pet' }, -- Shadow Bulwark
        { spell = 17877, type = "ability", charges = true, debuff = true, requiresTarget = true, talent = 91582 }, -- Shadowburn
        { spell = 17962, type = "ability", charges = true, requiresTarget = true, talent = 91591 }, -- Conflagrate
        { spell = 19505, type = "ability", requiresTarget = true }, -- Devour Magic
        { spell = 19647, type = "ability", requiresTarget = true }, -- Spell Lock
        { spell = 20707, type = "ability", buff = true }, -- Soulstone
        { spell = 29893, type = "ability" }, -- Create Soulwell
        { spell = 30283, type = "ability", talent = 91452 }, -- Shadowfury
        { spell = 48018, type = "ability", buff = true, talent = 124694 }, -- Demonic Circle
        { spell = 48020, type = "ability", overlayGlow = true, usable = true }, -- Demonic Circle: Teleport
        { spell = 54049, type = "ability", requiresTarget = true }, -- Shadow Bite
        { spell = 59752, type = "ability", buff = true }, -- Will to Survive
        { spell = 80240, type = "ability", debuff = true, requiresTarget = true, talent = 91493 }, -- Havoc
        { spell = 89808, type = "ability" }, -- Singe Magic
        { spell = 104773, type = "ability", buff = true }, -- Unending Resolve
        { spell = 108416, type = "ability", buff = true, talent = 91444 }, -- Dark Pact
        { spell = 108503, type = "ability", talent = 125618 }, -- Grimoire of Sacrifice
        { spell = 111771, type = "ability", overlayGlow = true, talent = 91466 }, -- Demonic Gateway
        { spell = 112042, type = "ability", buff = true, unit = 'pet' }, -- Threatening Presence
        { spell = 116858, type = "ability", overlayGlow = true, requiresTarget = true }, -- Chaos Bolt
        { spell = 119905, type = "ability" }, -- Singe Magic
        { spell = 119907, type = "ability" }, -- Shadow Bulwark
        { spell = 119910, type = "ability", requiresTarget = true }, -- Spell Lock
        { spell = 125439, type = "ability" }, -- Revive Battle Pets
        { spell = 132411, type = "ability" }, -- Singe Magic
        { spell = 152108, type = "ability", talent = 91487 }, -- Cataclysm
        { spell = 196447, type = "ability", usable = true, talent = 91586 }, -- Channel Demonfire
        { spell = 200546, type = "ability" }, -- Bane of Havoc
        { spell = 234153, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Drain Life
        { spell = 328774, type = "ability", buff = true, usable = true, talent = 91442 }, -- Amplify Curse
        { spell = 333889, type = "ability", buff = true, talent = 91439 }, -- Fel Domination
        { spell = 342601, type = "ability", usable = true }, -- Ritual of Doom
        { spell = 384069, type = "ability", debuff = true, talent = 91450 }, -- Shadowflame
        { spell = 385899, type = "ability", talent = 91469 }, -- Soulburn
        { spell = 387976, type = "ability", charges = true, talent = 91423 }, -- Dimensional Rift
        { spell = 442726, type = "ability", buff = true, herotalent = 117439 }, -- Malevolence
      },
      icon = 135807
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 101643, type = "buff", unit = "player", talent = 124962 }, -- Transcendence
        { spell = 115175, type = "buff", unit = "player", talent = 124933 }, -- Soothing Mist
        { spell = 115176, type = "buff", unit = "player", talent = 125006 }, -- Zen Meditation
        { spell = 116841, type = "buff", unit = "player", talent = 124937 }, -- Tiger's Lust
        { spell = 116847, type = "buff", unit = "player", talent = 125007 }, -- Rushing Jade Wind
        { spell = 120954, type = "buff", unit = "player", talent = 124968 }, -- Fortifying Brew
        { spell = 122783, type = "buff", unit = "player", talent = 124959 }, -- Diffuse Magic
        { spell = 132578, type = "buff", unit = "player", talent = 124849 }, -- Invoke Niuzao, the Black Ox
        { spell = 166646, type = "buff", unit = "player", talent = 124971 }, -- Windwalking
        { spell = 195630, type = "buff", unit = "player" }, -- Elusive Brawler
        { spell = 215479, type = "buff", unit = "player", talent = 124864 }, -- Shuffle
        { spell = 228563, type = "buff", unit = "player", talent = 124999 }, -- Blackout Combo
        { spell = 322507, type = "buff", unit = "player", talent = 124841 }, -- Celestial Brew
        { spell = 325153, type = "buff", unit = "player", talent = 125001 }, -- Exploding Keg
        { spell = 325190, type = "buff", unit = "player", talent = 124844 }, -- Celestial Flames
        { spell = 383696, type = "buff", unit = "player", talent = 124845 }, -- Hit Scheme
        { spell = 386963, type = "buff", unit = "player", talent = 124986 }, -- Charred Passions
        { spell = 387184, type = "buff", unit = "player", talent = 124996 }, -- Weapons of Order
        { spell = 392883, type = "buff", unit = "player", talent = 124935 }, -- Vivacious Vivification
        { spell = 393515, type = "buff", unit = "player", talent = 124851 }, -- Pretense of Instability
        { spell = 394112, type = "buff", unit = "player", talent = 124973 }, -- Escape from Reality
        { spell = 414143, type = "buff", unit = "player", talent = 124960 }, -- Yu'lon's Grace
        { spell = 418361, type = "buff", unit = "player", talent = 124997 }, -- Press the Advantage
        { spell = 449609, type = "buff", unit = "player", talent = 124963 }, -- Lighter Than Air
        { spell = 450380, type = "buff", unit = "player", talent = 126502 }, -- Chi Wave
        { spell = 450521, type = "buff", unit = "player", herotalent = 125033 }, -- Aspect of Harmony
        { spell = 450552, type = "buff", unit = "player", talent = 124954 }, -- Jade Walk
        { spell = 450574, type = "buff", unit = "player", talent = 124965 }, -- Flow of Chi
        { spell = 451021, type = "buff", unit = "player" }, -- Flurry Charge
        { spell = 451084, type = "buff", unit = "player", herotalent = 125038 }, -- Path of Resurgence
        { spell = 451085, type = "buff", unit = "player", herotalent = 125070 }, -- Veteran's Eye
        { spell = 451233, type = "buff", unit = "player", herotalent = 125063 }, -- Vigilant Watch
        { spell = 451299, type = "buff", unit = "player" }, -- Chi Cocoon
        { spell = 451508, type = "buff", unit = "player", herotalent = 125043 }, -- Balanced Stratagem
        { spell = 454494, type = "buff", unit = "player", talent = 124861 }, -- August Blessing
        { spell = 455071, type = "buff", unit = "player", talent = 125004 }, -- Ox Stance
        { spell = 470670, type = "buff", unit = "player", herotalent = 125069, progressSource = "stacks", maxProgress = "240" }, -- Flurry Strikes
      },
      icon = 613398
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target" }, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "target", talent = 124932 }, -- Paralysis
        { spell = 116189, type = "debuff", unit = "target" }, -- Provoke
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target" }, -- Leg Sweep
        { spell = 121253, type = "debuff", unit = "target", talent = 124865 }, -- Keg Smash
        { spell = 198909, type = "debuff", unit = "target", talent = 124925 }, -- Song of Chi-Ji
        { spell = 324382, type = "debuff", unit = "target", talent = 124945 }, -- Clash
        { spell = 325153, type = "debuff", unit = "target", talent = 125001 }, -- Exploding Keg
        { spell = 387179, type = "debuff", unit = "target", talent = 124996 }, -- Weapons of Order
        { spell = 393786, type = "debuff", unit = "target", talent = 124994 }, -- Chi Surge
        { spell = 450342, type = "debuff", unit = "target", talent = 124940 }, -- Crashing Momentum
        { spell = 450763, type = "debuff", unit = "target", herotalent = 125033 }, -- Aspect of Harmony
      },
      icon = 611419
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100780, type = "ability", requiresTarget = true }, -- Tiger Palm
        { spell = 101643, type = "ability", buff = true, talent = 124962 }, -- Transcendence
        { spell = 107428, type = "ability", requiresTarget = true, talent = 124985 }, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true }, -- Roll
        { spell = 115078, type = "ability", debuff = true, requiresTarget = true, talent = 124932 }, -- Paralysis
        { spell = 115176, type = "ability", buff = true, talent = 125006 }, -- Zen Meditation
        { spell = 115181, type = "ability", talent = 124843 }, -- Breath of Fire
        { spell = 115203, type = "ability", talent = 124968 }, -- Fortifying Brew
        { spell = 115315, type = "ability", totem = true, talent = 124967 }, -- Summon Black Ox Statue
        { spell = 115399, type = "ability", talent = 124991 }, -- Black Ox Brew
        { spell = 115546, type = "ability", requiresTarget = true }, -- Provoke
        { spell = 116705, type = "ability", requiresTarget = true, talent = 124943 }, -- Spear Hand Strike
        { spell = 116841, type = "ability", buff = true, requiresTarget = true, talent = 124937 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 124926 }, -- Ring of Peace
        { spell = 116847, type = "ability", buff = true, talent = 125007 }, -- Rushing Jade Wind
        { spell = 117952, type = "ability", debuff = true, requiresTarget = true }, -- Crackling Jade Lightning
        { spell = 119381, type = "ability", debuff = true }, -- Leg Sweep
        { spell = 119582, type = "ability", charges = true, talent = 124838 }, -- Purifying Brew
        { spell = 119996, type = "ability", usable = true }, -- Transcendence: Transfer
        { spell = 121253, type = "ability", charges = true, debuff = true, requiresTarget = true, talent = 124865 }, -- Keg Smash
        { spell = 122783, type = "ability", buff = true, talent = 124959 }, -- Diffuse Magic
        { spell = 123986, type = "ability", talent = 126501 }, -- Chi Burst
        { spell = 126892, type = "ability" }, -- Zen Pilgrimage
        { spell = 132578, type = "ability", buff = true, requiresTarget = true, totem = true, talent = 124849 }, -- Invoke Niuzao, the Black Ox
        { spell = 198898, type = "ability", talent = 124925 }, -- Song of Chi-Ji
        { spell = 205523, type = "ability", requiresTarget = true }, -- Blackout Kick
        { spell = 218164, type = "ability", talent = 124867 }, -- Detox
        { spell = 322101, type = "ability", charges = true }, -- Expel Harm
        { spell = 322109, type = "ability", requiresTarget = true, usable = true }, -- Touch of Death
        { spell = 322507, type = "ability", charges = true, buff = true, talent = 124841 }, -- Celestial Brew
        { spell = 324312, type = "ability", requiresTarget = true, talent = 124945 }, -- Clash
        { spell = 325153, type = "ability", buff = true, debuff = true, talent = 125001 }, -- Exploding Keg
        { spell = 387184, type = "ability", buff = true, talent = 124996 }, -- Weapons of Order
      },
      icon = 133701
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 101643, type = "buff", unit = "player", talent = 124962 }, -- Transcendence
        { spell = 115175, type = "buff", unit = "player", talent = 124933 }, -- Soothing Mist
        { spell = 115294, type = "buff", unit = "player", talent = 124920 }, -- Mana Tea
        { spell = 116680, type = "buff", unit = "player", talent = 124921 }, -- Thunder Focus Tea
        { spell = 116841, type = "buff", unit = "player", talent = 124937 }, -- Tiger's Lust
        { spell = 116849, type = "buff", unit = "player", talent = 124875 }, -- Life Cocoon
        { spell = 119085, type = "buff", unit = "player", talent = 124981 }, -- Chi Torpedo
        { spell = 119611, type = "buff", unit = "player", talent = 124888 }, -- Renewing Mist
        { spell = 120954, type = "buff", unit = "player", talent = 124968 }, -- Fortifying Brew
        { spell = 122783, type = "buff", unit = "player", talent = 124959 }, -- Diffuse Magic
        { spell = 124682, type = "buff", unit = "player", talent = 124922 }, -- Enveloping Mist
        { spell = 166646, type = "buff", unit = "player", talent = 124971 }, -- Windwalking
        { spell = 196725, type = "buff", unit = "player", talent = 124870 }, -- Refreshing Jade Wind
        { spell = 197916, type = "buff", unit = "player", talent = 124916 }, -- Lifecycles
        { spell = 202090, type = "buff", unit = "player", talent = 124827 }, -- Teachings of the Monastery
        { spell = 325209, type = "buff", unit = "player" }, -- Enveloping Breath
        { spell = 343737, type = "buff", unit = "player" }, -- Soothing Breath
        { spell = 388026, type = "buff", unit = "player", talent = 124882 }, -- Jadefire Teachings
        { spell = 388193, type = "buff", unit = "player", talent = 124881 }, -- Jadefire Stomp
        { spell = 388220, type = "buff", unit = "player", talent = 124873 }, -- Calming Coalescence
        { spell = 388498, type = "buff", unit = "player", talent = 124908 }, -- Secret Infusion
        { spell = 388513, type = "buff", unit = "player", talent = 124872 }, -- Overflowing Mists
        { spell = 388518, type = "buff", unit = "player", talent = 124884 }, -- Tea of Serenity
        { spell = 388524, type = "buff", unit = "player", talent = 124883 }, -- Tea of Plenty
        { spell = 388555, type = "buff", unit = "player", talent = 124869 }, -- Uplifted Spirits
        { spell = 388663, type = "buff", unit = "player", talent = 124907 }, -- Invoker's Delight
        { spell = 389387, type = "buff", unit = "player", talent = 124885 }, -- Awakened Jadefire
        { spell = 389422, type = "buff", unit = "player" }, -- Yu'lon's Blessing
        { spell = 392883, type = "buff", unit = "player", talent = 124935 }, -- Vivacious Vivification
        { spell = 400100, type = "buff", unit = "player" }, -- Lesson of Despair
        { spell = 405807, type = "buff", unit = "player" }, -- Shaohao's Lesson - Anger
        { spell = 405810, type = "buff", unit = "player" }, -- Shaohao's Lesson - Despair
        { spell = 406139, type = "buff", unit = "player" }, -- Chi Cocoon
        { spell = 414143, type = "buff", unit = "player", talent = 124960 }, -- Yu'lon's Grace
        { spell = 427296, type = "buff", unit = "player", talent = 124890 }, -- Healing Elixir
        { spell = 432180, type = "buff", unit = "player", talent = 124929 }, -- Dance of the Wind
        { spell = 438443, type = "buff", unit = "player", talent = 124887 }, -- Dance of Chi-Ji
        { spell = 442749, type = "buff", unit = "player", herotalent = 125057 }, -- Niuzao's Protection
        { spell = 442850, type = "buff", unit = "player", herotalent = 125051 }, -- August Dynasty
        { spell = 443028, type = "buff", unit = "player", herotalent = 125062 }, -- Celestial Conduit
        { spell = 443112, type = "buff", unit = "player", herotalent = 125060 }, -- Strength of the Black Ox
        { spell = 443506, type = "buff", unit = "player", herotalent = 125055 }, -- Heart of the Jade Serpent
        { spell = 443569, type = "buff", unit = "player", herotalent = 125059 }, -- Chi-Ji's Swiftness
        { spell = 443572, type = "buff", unit = "player" }, -- Crane Stance
        { spell = 443574, type = "buff", unit = "player", talent = 125004 }, -- Ox Stance
        { spell = 443575, type = "buff", unit = "player" }, -- Tiger Stance
        { spell = 446334, type = "buff", unit = "player", talent = 124889 }, -- Zen Pulse
        { spell = 448508, type = "buff", unit = "player", herotalent = 125056 }, -- Jade Sanctuary
        { spell = 450380, type = "buff", unit = "player", talent = 126500 }, -- Chi Wave
        { spell = 450521, type = "buff", unit = "player", herotalent = 125033 }, -- Aspect of Harmony
        { spell = 450552, type = "buff", unit = "player", talent = 124954 }, -- Jade Walk
        { spell = 450574, type = "buff", unit = "player", talent = 124965 }, -- Flow of Chi
        { spell = 450805, type = "buff", unit = "player", herotalent = 125035 }, -- Purified Spirit
        { spell = 451084, type = "buff", unit = "player", herotalent = 125038 }, -- Path of Resurgence
        { spell = 451181, type = "buff", unit = "player", herotalent = 125040 }, -- Clarity of Purpose
        { spell = 451452, type = "buff", unit = "player", herotalent = 125042 }, -- Mantra of Purity
        { spell = 451508, type = "buff", unit = "player", herotalent = 125043 }, -- Balanced Stratagem
        { spell = 460127, type = "buff", unit = "player", herotalent = 125061 }, -- Courage of the White Tiger
        { spell = 467317, type = "buff", unit = "player", talent = 128220 }, -- Jade Empowerment
        { spell = 467341, type = "buff", unit = "player" }, -- Rushing Winds
      },
      icon = 627487
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target" }, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "target", talent = 124932 }, -- Paralysis
        { spell = 116189, type = "debuff", unit = "target" }, -- Provoke
        { spell = 117952, type = "debuff", unit = "target" }, -- Crackling Jade Lightning
        { spell = 119381, type = "debuff", unit = "target" }, -- Leg Sweep
        { spell = 198909, type = "debuff", unit = "target", talent = 124925 }, -- Song of Chi-Ji
        { spell = 324382, type = "debuff", unit = "target", talent = 124945 }, -- Clash
        { spell = 450342, type = "debuff", unit = "target", talent = 124940 }, -- Crashing Momentum
        { spell = 450763, type = "debuff", unit = "target", herotalent = 125033 }, -- Aspect of Harmony
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100780, type = "ability", requiresTarget = true }, -- Tiger Palm
        { spell = 100784, type = "ability", requiresTarget = true }, -- Blackout Kick
        { spell = 101643, type = "ability", buff = true, talent = 124962 }, -- Transcendence
        { spell = 107428, type = "ability", overlayGlow = true, requiresTarget = true, talent = 124985 }, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true }, -- Roll
        { spell = 115008, type = "ability", charges = true, talent = 124981 }, -- Chi Torpedo
        { spell = 115078, type = "ability", debuff = true, requiresTarget = true, talent = 124932 }, -- Paralysis
        { spell = 115151, type = "ability", charges = true, overlayGlow = true, talent = 124888 }, -- Renewing Mist
        { spell = 115203, type = "ability", talent = 124968 }, -- Fortifying Brew
        { spell = 115294, type = "ability", charges = true, buff = true, usable = true, talent = 124920 }, -- Mana Tea
        { spell = 115310, type = "ability", talent = 124919 }, -- Revival
        { spell = 115313, type = "ability", totem = true, talent = 124958 }, -- Summon Jade Serpent Statue
        { spell = 115450, type = "ability", talent = 124941 }, -- Detox
        { spell = 115546, type = "ability", requiresTarget = true }, -- Provoke
        { spell = 116680, type = "ability", charges = true, buff = true, talent = 124921 }, -- Thunder Focus Tea
        { spell = 116705, type = "ability", requiresTarget = true, talent = 124943 }, -- Spear Hand Strike
        { spell = 116841, type = "ability", buff = true, talent = 124937 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 124926 }, -- Ring of Peace
        { spell = 116849, type = "ability", buff = true, talent = 124875 }, -- Life Cocoon
        { spell = 117952, type = "ability", debuff = true, requiresTarget = true }, -- Crackling Jade Lightning
        { spell = 119381, type = "ability", debuff = true }, -- Leg Sweep
        { spell = 119996, type = "ability", usable = true }, -- Transcendence: Transfer
        { spell = 122783, type = "ability", buff = true, talent = 124959 }, -- Diffuse Magic
        { spell = 123986, type = "ability", talent = 126499 }, -- Chi Burst
        { spell = 126892, type = "ability" }, -- Zen Pilgrimage
        { spell = 198898, type = "ability", talent = 124925 }, -- Song of Chi-Ji
        { spell = 322101, type = "ability", overlayGlow = true }, -- Expel Harm
        { spell = 322109, type = "ability", requiresTarget = true, usable = true }, -- Touch of Death
        { spell = 322118, type = "ability", totem = true, talent = 124915 }, -- Invoke Yu'lon, the Jade Serpent
        { spell = 324312, type = "ability", requiresTarget = true, talent = 124945 }, -- Clash
        { spell = 388193, type = "ability", buff = true, overlayGlow = true, talent = 124881 }, -- Jadefire Stomp
        { spell = 388615, type = "ability", talent = 124918 }, -- Restoral
        { spell = 399491, type = "ability", charges = true, talent = 124904 }, -- Sheilun's Gift
        { spell = 443028, type = "ability", buff = true, herotalent = 125062 }, -- Celestial Conduit
        { spell = 467307, type = "ability", talent = 128221 }, -- Rushing Wind Kick
      },
      icon = 627485
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 101643, type = "buff", unit = "player", talent = 124962 }, -- Transcendence
        { spell = 115175, type = "buff", unit = "player", talent = 124933 }, -- Soothing Mist
        { spell = 116768, type = "buff", unit = "player" }, -- Blackout Kick!
        { spell = 116841, type = "buff", unit = "player", talent = 124937 }, -- Tiger's Lust
        { spell = 116847, type = "buff", unit = "player", talent = 124818 }, -- Rushing Jade Wind
        { spell = 120954, type = "buff", unit = "player", talent = 124968 }, -- Fortifying Brew
        { spell = 122783, type = "buff", unit = "player", talent = 124959 }, -- Diffuse Magic
        { spell = 125174, type = "buff", unit = "player" }, -- Touch of Karma
        { spell = 129914, type = "buff", unit = "player", talent = 125025 }, -- Combat Wisdom
        { spell = 137639, type = "buff", unit = "player", talent = 124826 }, -- Storm, Earth, and Fire
        { spell = 166646, type = "buff", unit = "player", talent = 124971 }, -- Windwalking
        { spell = 195321, type = "buff", unit = "player", talent = 125019 }, -- Transfer the Power
        { spell = 202090, type = "buff", unit = "player", talent = 124827 }, -- Teachings of the Monastery
        { spell = 325202, type = "buff", unit = "player", talent = 124834 }, -- Dance of Chi-Ji
        { spell = 388193, type = "buff", unit = "player", talent = 126026 }, -- Jadefire Stomp
        { spell = 388663, type = "buff", unit = "player", talent = 125014 }, -- Invoker's Delight
        { spell = 392883, type = "buff", unit = "player", talent = 124935 }, -- Vivacious Vivification
        { spell = 393039, type = "buff", unit = "player" }, -- The Emperor's Capacitor
        { spell = 393053, type = "buff", unit = "player" }, -- Pressure Point
        { spell = 393057, type = "buff", unit = "player" }, -- Chi Energy
        { spell = 393565, type = "buff", unit = "player", talent = 124811 }, -- Thunderfist
        { spell = 394112, type = "buff", unit = "player", talent = 124973 }, -- Escape from Reality
        { spell = 395413, type = "buff", unit = "player" }, -- Jadefire Brand
        { spell = 396167, type = "buff", unit = "player", talent = 125018 }, -- Fury of Xuen
        { spell = 414143, type = "buff", unit = "player", talent = 124960 }, -- Yu'lon's Grace
        { spell = 432180, type = "buff", unit = "player", talent = 124927 }, -- Dance of the Wind
        { spell = 442749, type = "buff", unit = "player", herotalent = 125057 }, -- Niuzao's Protection
        { spell = 442850, type = "buff", unit = "player", herotalent = 125051 }, -- August Dynasty
        { spell = 443028, type = "buff", unit = "player", herotalent = 125062 }, -- Celestial Conduit
        { spell = 443112, type = "buff", unit = "player", herotalent = 125060 }, -- Strength of the Black Ox
        { spell = 443424, type = "buff", unit = "player", herotalent = 125055 }, -- Heart of the Jade Serpent
        { spell = 443569, type = "buff", unit = "player", herotalent = 125059 }, -- Chi-Ji's Swiftness
        { spell = 443572, type = "buff", unit = "player" }, -- Crane Stance
        { spell = 443574, type = "buff", unit = "player" }, -- Ox Stance
        { spell = 443575, type = "buff", unit = "player" }, -- Tiger Stance
        { spell = 450380, type = "buff", unit = "player", talent = 124953 }, -- Chi Wave
        { spell = 450552, type = "buff", unit = "player", talent = 124954 }, -- Jade Walk
        { spell = 450574, type = "buff", unit = "player", talent = 124965 }, -- Flow of Chi
        { spell = 451021, type = "buff", unit = "player" }, -- Flurry Charge
        { spell = 451061, type = "buff", unit = "player", herotalent = 125074 }, -- Against All Odds
        { spell = 451085, type = "buff", unit = "player", herotalent = 125070 }, -- Veteran's Eye
        { spell = 451233, type = "buff", unit = "player", herotalent = 125063 }, -- Vigilant Watch
        { spell = 451242, type = "buff", unit = "player", herotalent = 125073 }, -- Wisdom of the Wall
        { spell = 451298, type = "buff", unit = "player", talent = 124820 }, -- Momentum Boost
        { spell = 451457, type = "buff", unit = "player", talent = 124830 }, -- Martial Mixture
        { spell = 451462, type = "buff", unit = "player", talent = 124823 }, -- Ordered Elements
        { spell = 451833, type = "buff", unit = "player", talent = 125020 }, -- Dual Threat
        { spell = 451943, type = "buff", unit = "player" }, -- Jade Swiftness
        { spell = 454970, type = "buff", unit = "player", talent = 125016 }, -- Memory of the Monastery
        { spell = 457459, type = "buff", unit = "player", herotalent = 125050 }, -- Flight of the Red Crane
        { spell = 459841, type = "buff", unit = "player", talent = 126307 }, -- Darting Hurricane
        { spell = 460127, type = "buff", unit = "player", herotalent = 125061 }, -- Courage of the White Tiger
        { spell = 460490, type = "buff", unit = "player", talent = 124952 }, -- Chi Burst
        { spell = 470670, type = "buff", unit = "player", herotalent = 125069, progressSource = "stacks", maxProgress = "240" }, -- Flurry Strikes
      },
      icon = 611420
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 113746, type = "debuff", unit = "target" }, -- Mystic Touch
        { spell = 115078, type = "debuff", unit = "target", talent = 124932 }, -- Paralysis
        { spell = 115804, type = "debuff", unit = "target" }, -- Mortal Wounds
        { spell = 116189, type = "debuff", unit = "target" }, -- Provoke
        { spell = 119381, type = "debuff", unit = "target" }, -- Leg Sweep
        { spell = 122470, type = "debuff", unit = "target" }, -- Touch of Karma
        { spell = 198909, type = "debuff", unit = "target", talent = 124925 }, -- Song of Chi-Ji
        { spell = 228287, type = "debuff", unit = "target" }, -- Mark of the Crane
        { spell = 324382, type = "debuff", unit = "target", talent = 124945 }, -- Clash
        { spell = 392983, type = "debuff", unit = "target", talent = 125022 }, -- Strike of the Windlord
        { spell = 395414, type = "debuff", unit = "target" }, -- Jadefire Brand
        { spell = 450596, type = "debuff", unit = "target", talent = 124928 }, -- Spirit's Essence
        { spell = 451433, type = "debuff", unit = "target", talent = 124806 }, -- Acclamation
        { spell = 451582, type = "debuff", unit = "target", talent = 124817 }, -- Gale Force
      },
      icon = 629534
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 100780, type = "ability", requiresTarget = true }, -- Tiger Palm
        { spell = 100784, type = "ability", overlayGlow = true, requiresTarget = true }, -- Blackout Kick
        { spell = 101545, type = "ability" }, -- Flying Serpent Kick
        { spell = 101546, type = "ability", charges = true, overlayGlow = true }, -- Spinning Crane Kick
        { spell = 101643, type = "ability", buff = true, talent = 124962 }, -- Transcendence
        { spell = 107428, type = "ability", requiresTarget = true, talent = 124985 }, -- Rising Sun Kick
        { spell = 109132, type = "ability", charges = true }, -- Roll
        { spell = 113656, type = "ability", requiresTarget = true, talent = 125026 }, -- Fists of Fury
        { spell = 115078, type = "ability", debuff = true, requiresTarget = true, talent = 124932 }, -- Paralysis
        { spell = 115203, type = "ability", talent = 124968 }, -- Fortifying Brew
        { spell = 115546, type = "ability", requiresTarget = true }, -- Provoke
        { spell = 116705, type = "ability", requiresTarget = true, talent = 124943 }, -- Spear Hand Strike
        { spell = 116841, type = "ability", buff = true, talent = 124937 }, -- Tiger's Lust
        { spell = 116844, type = "ability", talent = 124926 }, -- Ring of Peace
        { spell = 117952, type = "ability", requiresTarget = true }, -- Crackling Jade Lightning
        { spell = 119381, type = "ability", debuff = true }, -- Leg Sweep
        { spell = 119996, type = "ability", usable = true }, -- Transcendence: Transfer
        { spell = 122470, type = "ability", debuff = true, requiresTarget = true }, -- Touch of Karma
        { spell = 122783, type = "ability", buff = true, usable = true, talent = 124959 }, -- Diffuse Magic
        { spell = 123904, type = "ability", requiresTarget = true, totem = true, talent = 125013 }, -- Invoke Xuen, the White Tiger
        { spell = 126892, type = "ability" }, -- Zen Pilgrimage
        { spell = 137639, type = "ability", charges = true, buff = true, talent = 124826 }, -- Storm, Earth, and Fire
        { spell = 152175, type = "ability", usable = true, talent = 125011 }, -- Whirling Dragon Punch
        { spell = 198898, type = "ability", talent = 124925 }, -- Song of Chi-Ji
        { spell = 322109, type = "ability", requiresTarget = true, usable = true }, -- Touch of Death
        { spell = 324312, type = "ability", requiresTarget = true, talent = 124945 }, -- Clash
        { spell = 388193, type = "ability", buff = true, talent = 126026 }, -- Jadefire Stomp
        { spell = 392983, type = "ability", debuff = true, requiresTarget = true, talent = 125022 }, -- Strike of the Windlord
        { spell = 443028, type = "ability", buff = true, herotalent = 125062 }, -- Celestial Conduit
      },
      icon = 627606
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 774, type = "buff", unit = "player", talent = 103295 }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player" }, -- Travel Form
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 103298 }, -- Frenzied Regeneration
        { spell = 24858, type = "buff", unit = "player" }, -- Moonkin Form
        { spell = 48438, type = "buff", unit = "player", talent = 103320 }, -- Wild Growth
        { spell = 48517, type = "buff", unit = "player" }, -- Eclipse (Solar)
        { spell = 48518, type = "buff", unit = "player" }, -- Eclipse (Lunar)
        { spell = 77764, type = "buff", unit = "player", talent = 103312 }, -- Stampeding Roar
        { spell = 102560, type = "buff", unit = "player", talent = 109839 }, -- Incarnation: Chosen of Elune
        { spell = 124974, type = "buff", unit = "player", talent = 103324 }, -- Nature's Vigil
        { spell = 157228, type = "buff", unit = "player" }, -- Owlkin Frenzy
        { spell = 191034, type = "buff", unit = "player" }, -- Starfall
        { spell = 192081, type = "buff", unit = "player", talent = 103305 }, -- Ironfur
        { spell = 202425, type = "buff", unit = "player", talent = 114648 }, -- Warrior of Elune
        { spell = 252216, type = "buff", unit = "player", talent = 103275 }, -- Tiger Dash
        { spell = 279709, type = "buff", unit = "player", talent = 109840 }, -- Starlord
        { spell = 319454, type = "buff", unit = "player", talent = 103309 }, -- Heart of the Wild
        { spell = 343648, type = "buff", unit = "player", talent = 109835 }, -- Solstice
        { spell = 383410, type = "buff", unit = "player", talent = 109849 }, -- Celestial Alignment
        { spell = 385787, type = "buff", unit = "player", talent = 103314 }, -- Matted Fur
        { spell = 391528, type = "buff", unit = "player", talent = 109838 }, -- Convoke the Spirits
        { spell = 393763, type = "buff", unit = "player", talent = 109850 }, -- Umbral Embrace
        { spell = 393903, type = "buff", unit = "player", talent = 103313 }, -- Ursine Vigor
        { spell = 393942, type = "buff", unit = "player", talent = 109873 }, -- Starweaver's Warp
        { spell = 393944, type = "buff", unit = "player", talent = 109873 }, -- Starweaver's Weft
        { spell = 394049, type = "buff", unit = "player", talent = 109848 }, -- Balance of All Things (Nature)
        { spell = 394050, type = "buff", unit = "player", talent = 109848 }, -- Balance of All Things (Arcane)
        { spell = 394108, type = "buff", unit = "player", talent = 109831 }, -- Sundered Firmament
        { spell = 395110, type = "buff", unit = "player", talent = 109851 }, -- Parting Skies
        { spell = 400126, type = "buff", unit = "player", talent = 123792 }, -- Forestwalk
        { spell = 428735, type = "buff", unit = "player", herotalent = 117203 }, -- Harmony of the Grove
        { spell = 429438, type = "buff", unit = "player", herotalent = 117196 }, -- Blooming Infusion
        { spell = 431250, type = "buff", unit = "player", herotalent = 117190 }, -- Lunar Amplification
        { spell = 433749, type = "buff", unit = "player", herotalent = 117186 }, -- Protective Growth
        { spell = 433832, type = "buff", unit = "player" }, -- Dream Burst
        { spell = 450346, type = "buff", unit = "player", talent = 109857 }, -- Dreamstate
        { spell = 450360, type = "buff", unit = "player", talent = 109857 }, -- Touch the Cosmos
        { spell = 450599, type = "buff", unit = "player", talent = 109871 }, -- Astral Communion
        { spell = 450419, type = "buff", unit = "player", talent = 109851 }, -- Umbral Inspiration
        { spell = 455801, type = "buff", unit = "player", herotalent = 117199 }, -- Cenarius' Might
      },
      icon = 136097
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target", talent = 103316 }, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 103300 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 103315 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 50259, type = "debuff", unit = "target" }, -- Dazed
        { spell = 61391, type = "debuff", unit = "target", talent = 103287 }, -- Typhoon
        { spell = 81261, type = "debuff", unit = "target", talent = 109867 }, -- Solar Beam
        { spell = 81281, type = "debuff", unit = "target" }, -- Fungal Growth
        { spell = 102359, type = "debuff", unit = "target", talent = 103322 }, -- Mass Entanglement
        { spell = 127797, type = "debuff", unit = "target", talent = 103321 }, -- Ursol's Vortex
        { spell = 155722, type = "debuff", unit = "target", talent = 103277 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 103286 }, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target", talent = 103301 }, -- Thrash
        { spell = 202347, type = "debuff", unit = "target", talent = 109841 }, -- Stellar Flare
        { spell = 203123, type = "debuff", unit = "target", talent = 103299 }, -- Maim
        { spell = 205644, type = "debuff", unit = "target", talent = 109844 }, -- Force of Nature
        { spell = 393957, type = "debuff", unit = "target", talent = 109834 }, -- Waning Twilight
        { spell = 394061, type = "debuff", unit = "target", talent = 109836 }, -- Astral Smolder
        { spell = 430589, type = "debuff", unit = "target", herotalent = 117204 }, -- Atmospheric Exposure
        { spell = 450214, type = "debuff", unit = "target", talent = 109865 }, -- Stellar Amplification
      },
      icon = 132114
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", debuff = true, talent = 103316 }, -- Incapacitating Roar
        { spell = 339, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Entangling Roots
        { spell = 768, type = "ability", buff = true }, -- Cat Form
        { spell = 783, type = "ability", buff = true }, -- Travel Form
        { spell = 1079, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 103300 }, -- Rip
        { spell = 1822, type = "ability", requiresTarget = true, usable = true, talent = 103277 }, -- Rake
        { spell = 1850, type = "ability", buff = true }, -- Dash
        { spell = 2782, type = "ability", talent = 103283 }, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true, talent = 103307 }, -- Soothe
        { spell = 5211, type = "ability", debuff = true, requiresTarget = true, talent = 103315 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true, usable = true }, -- Prowl
        { spell = 5221, type = "ability", requiresTarget = true, usable = true }, -- Shred
        { spell = 5487, type = "ability", buff = true }, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true }, -- Moonfire
        { spell = 20484, type = "ability" }, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true, usable = true }, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, usable = true, talent = 103299 }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", charges = true, buff = true, usable = true, talent = 103298 }, -- Frenzied Regeneration
        { spell = 24858, type = "ability", buff = true }, -- Moonkin Form
        { spell = 33786, type = "ability", requiresTarget = true, talent = 103291 }, -- Cyclone
        { spell = 33917, type = "ability", requiresTarget = true, usable = true }, -- Mangle
        { spell = 48438, type = "ability", buff = true, requiresTarget = true, talent = 103320 }, -- Wild Growth
        { spell = 49376, type = "ability", talent = 103276 }, -- Wild Charge
        { spell = 77758, type = "ability", talent = 103301 }, -- Thrash
        { spell = 77764, type = "ability", buff = true, talent = 103312 }, -- Stampeding Roar
        { spell = 78674, type = "ability", overlayGlow = true, requiresTarget = true, talent = 103280 }, -- Starsurge
        { spell = 78675, type = "ability", requiresTarget = true, talent = 109867 }, -- Solar Beam
        { spell = 88747, type = "ability", charges = true, requiresTarget = true, talent = 117100 }, -- Wild Mushroom
        { spell = 93402, type = "ability", requiresTarget = true, talent = 103286 }, -- Sunfire
        { spell = 102359, type = "ability", debuff = true, requiresTarget = true, talent = 103322 }, -- Mass Entanglement
        { spell = 102560, type = "ability", buff = true, talent = 109839 }, -- Incarnation: Chosen of Elune
        { spell = 102793, type = "ability", talent = 103321 }, -- Ursol's Vortex
        { spell = 106832, type = "ability", usable = true, talent = 103301 }, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true, usable = true, talent = 103302 }, -- Skull Bash
        { spell = 108238, type = "ability", talent = 103310 }, -- Renewal
        { spell = 124974, type = "ability", buff = true, talent = 103324 }, -- Nature's Vigil
        { spell = 132469, type = "ability", talent = 103287 }, -- Typhoon
        { spell = 190984, type = "ability", charges = true, overlayGlow = true, requiresTarget = true }, -- Wrath
        { spell = 192081, type = "ability", buff = true, usable = true, talent = 103305 }, -- Ironfur
        { spell = 194153, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 103279 }, -- Starfire
        { spell = 202347, type = "ability", debuff = true, requiresTarget = true, talent = 109841 }, -- Stellar Flare
        { spell = 202425, type = "ability", buff = true, talent = 114648 }, -- Warrior of Elune
        { spell = 202770, type = "ability", requiresTarget = true, talent = 109859 }, -- Fury of Elune
        { spell = 205636, type = "ability", talent = 109844 }, -- Force of Nature
        { spell = 252216, type = "ability", buff = true, talent = 103275 }, -- Tiger Dash
        { spell = 274281, type = "ability", charges = true, requiresTarget = true, usable = true, talent = 109860 }, -- New Moon
        { spell = 274282, type = "ability", charges = true, requiresTarget = true, usable = true, talent = 109860 }, -- Half Moon
        { spell = 274283, type = "ability", charges = true, requiresTarget = true, usable = true, talent = 109860 }, -- Full Moon
        { spell = 319454, type = "ability", buff = true, talent = 103309 }, -- Heart of the Wild
        { spell = 383410, type = "ability", charges = true, buff = true, talent = 109849 }, -- Celestial Alignment
        { spell = 391528, type = "ability", buff = true, talent = 109838 }, -- Convoke the Spirits
      },
      icon = 132134
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 774, type = "buff", unit = "player", talent = 103295 }, -- Rejuvenation
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5217, type = "buff", unit = "player", talent = 103188 }, -- Tiger's Fury
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 103298 }, -- Frenzied Regeneration
        { spell = 61336, type = "buff", unit = "player", talent = 103180 }, -- Survival Instincts
        { spell = 69369, type = "buff", unit = "player", talent = 103167 }, -- Predatory Swiftness
        { spell = 77764, type = "buff", unit = "player", talent = 103312 }, -- Stampeding Roar
        { spell = 102543, type = "buff", unit = "player", talent = 103178 }, -- Incarnation: Avatar of Ashamane
        { spell = 106951, type = "buff", unit = "player", talent = 103162 }, -- Berserk
        { spell = 124974, type = "buff", unit = "player", talent = 103324 }, -- Nature's Vigil
        { spell = 135700, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 145152, type = "buff", unit = "player", talent = 103171 }, -- Bloodtalons
        { spell = 192081, type = "buff", unit = "player", talent = 103305 }, -- Ironfur
        { spell = 252216, type = "buff", unit = "player", talent = 103275 }, -- Tiger Dash
        { spell = 319454, type = "buff", unit = "player", talent = 103309 }, -- Heart of the Wild
        { spell = 385787, type = "buff", unit = "player", talent = 103314 }, -- Matted Fur
        { spell = 391528, type = "buff", unit = "player", talent = 103177 }, -- Convoke the Spirits
        { spell = 391873, type = "buff", unit = "player", talent = 103168 }, -- Tiger's Tenacity
        { spell = 391876, type = "buff", unit = "player", talent = 103179 }, -- Frantic Momentum
        { spell = 391882, type = "buff", unit = "player", talent = 103152 }, -- Apex Predator's Craving
        { spell = 391974, type = "buff", unit = "player", talent = 103165 }, -- Sudden Ambush
        { spell = 393903, type = "buff", unit = "player", talent = 103313 }, -- Ursine Vigor
        { spell = 400126, type = "buff", unit = "player", talent = 123792 }, -- Forestwalk
        { spell = 405189, type = "buff", unit = "player" }, -- Overflowing Power
        { spell = 421442, type = "buff", unit = "player", talent = 103176 }, -- Ashamane's Guidance
        { spell = 439530, type = "buff", unit = "player" }, -- Symbiotic Blooms
        { spell = 439887, type = "buff", unit = "player", herotalent = 117233 }, -- Root Network
        { spell = 439891, type = "buff", unit = "player", herotalent = 117223 }, -- Strategic Infusion
        { spell = 441585, type = "buff", unit = "player", herotalent = 117206 }, -- Ravage
        { spell = 441685, type = "buff", unit = "player", herotalent = 117207 }, -- Wildshape Mastery
        { spell = 441695, type = "buff", unit = "player" }, -- Ursine Potential
        { spell = 441817, type = "buff", unit = "player", herotalent = 117219 }, -- Ruthless Aggression
        { spell = 441825, type = "buff", unit = "player", herotalent = 123048 }, -- Killing Strikes
        { spell = 449538, type = "buff", unit = "player", talent = 103144 }, -- Coiled to Spring
        { spell = 449646, type = "buff", unit = "player", talent = 103160 }, -- Savage Fury
        { spell = 455496, type = "buff", unit = "player", herotalent = 117229 }, -- Implant
      },
      icon = 136170
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target", talent = 103316 }, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 103300 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 103315 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 50259, type = "debuff", unit = "target" }, -- Dazed
        { spell = 58180, type = "debuff", unit = "target", talent = 103182 }, -- Infected Wounds
        { spell = 61391, type = "debuff", unit = "target", talent = 103287 }, -- Typhoon
        { spell = 102359, type = "debuff", unit = "target", talent = 103322 }, -- Mass Entanglement
        { spell = 127797, type = "debuff", unit = "target", talent = 103321 }, -- Ursol's Vortex
        { spell = 155625, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 155722, type = "debuff", unit = "target", talent = 103277 }, -- Rake
        { spell = 164815, type = "debuff", unit = "target", talent = 103286 }, -- Sunfire
        { spell = 203123, type = "debuff", unit = "target", talent = 103299 }, -- Maim
        { spell = 274838, type = "debuff", unit = "target", talent = 103170 }, -- Feral Frenzy
        { spell = 391140, type = "debuff", unit = "target" }, -- Frenzied Assault
        { spell = 391356, type = "debuff", unit = "target" }, -- Tear
        { spell = 391722, type = "debuff", unit = "target", talent = 103163 }, -- Sabertooth
        { spell = 391889, type = "debuff", unit = "target", talent = 103175 }, -- Adaptive Swarm
        { spell = 405233, type = "debuff", unit = "target", talent = 103301 }, -- Thrash
        { spell = 439531, type = "debuff", unit = "target" }, -- Bloodseeker Vines
        { spell = 441812, type = "debuff", unit = "target", herotalent = 117220 }, -- Dreadful Wound
      },
      icon = 132152
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", debuff = true, talent = 103316 }, -- Incapacitating Roar
        { spell = 339, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Entangling Roots
        { spell = 768, type = "ability", buff = true }, -- Cat Form
        { spell = 1079, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 103300 }, -- Rip
        { spell = 1822, type = "ability", requiresTarget = true, usable = true, talent = 103277 }, -- Rake
        { spell = 1850, type = "ability", buff = true }, -- Dash
        { spell = 2782, type = "ability", talent = 103282 }, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true, talent = 103307 }, -- Soothe
        { spell = 5176, type = "ability", charges = true, requiresTarget = true }, -- Wrath
        { spell = 5211, type = "ability", debuff = true, requiresTarget = true, talent = 103315 }, -- Mighty Bash
        { spell = 5217, type = "ability", buff = true, talent = 103188 }, -- Tiger's Fury
        { spell = 5221, type = "ability", requiresTarget = true, usable = true }, -- Shred
        { spell = 5487, type = "ability", buff = true }, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true }, -- Moonfire
        { spell = 20484, type = "ability" }, -- Rebirth
        { spell = 22568, type = "ability", overlayGlow = true, requiresTarget = true, usable = true }, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, usable = true, talent = 103299 }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", charges = true, buff = true, usable = true, talent = 103298 }, -- Frenzied Regeneration
        { spell = 33786, type = "ability", requiresTarget = true, talent = 103291 }, -- Cyclone
        { spell = 33917, type = "ability", requiresTarget = true, usable = true }, -- Mangle
        { spell = 61336, type = "ability", buff = true, talent = 103180 }, -- Survival Instincts
        { spell = 77758, type = "ability", requiresTarget = true, talent = 103301 }, -- Thrash
        { spell = 77764, type = "ability", buff = true, talent = 103312 }, -- Stampeding Roar
        { spell = 78674, type = "ability", requiresTarget = true, talent = 103280 }, -- Starsurge
        { spell = 93402, type = "ability", requiresTarget = true, talent = 103286 }, -- Sunfire
        { spell = 102359, type = "ability", debuff = true, requiresTarget = true, talent = 103322 }, -- Mass Entanglement
        { spell = 102401, type = "ability", requiresTarget = true, talent = 103276 }, -- Wild Charge
        { spell = 102543, type = "ability", buff = true, talent = 103178 }, -- Incarnation: Avatar of Ashamane
        { spell = 102793, type = "ability", talent = 103321 }, -- Ursol's Vortex
        { spell = 106832, type = "ability", requiresTarget = true, usable = true, talent = 103301 }, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true, usable = true, talent = 103302 }, -- Skull Bash
        { spell = 106951, type = "ability", buff = true, talent = 103162 }, -- Berserk
        { spell = 108238, type = "ability", talent = 103310 }, -- Renewal
        { spell = 124974, type = "ability", buff = true, talent = 103324 }, -- Nature's Vigil
        { spell = 132469, type = "ability", talent = 103287 }, -- Typhoon
        { spell = 192081, type = "ability", buff = true, usable = true, talent = 103305 }, -- Ironfur
        { spell = 194153, type = "ability", requiresTarget = true, talent = 103279 }, -- Starfire
        { spell = 197626, type = "ability", requiresTarget = true, talent = 103278 }, -- Starsurge
        { spell = 197628, type = "ability", requiresTarget = true, talent = 112967 }, -- Starfire
        { spell = 202028, type = "ability", charges = true, usable = true, talent = 103151 }, -- Brutal Slash
        { spell = 252216, type = "ability", buff = true, talent = 103275 }, -- Tiger Dash
        { spell = 274837, type = "ability", requiresTarget = true, usable = true, talent = 103170 }, -- Feral Frenzy
        { spell = 319454, type = "ability", buff = true, talent = 103309 }, -- Heart of the Wild
        { spell = 391528, type = "ability", buff = true, talent = 103177 }, -- Convoke the Spirits
        { spell = 391888, type = "ability", requiresTarget = true, talent = 103175 }, -- Adaptive Swarm
      },
      icon = 236149
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 774, type = "buff", unit = "player", talent = 103295 }, -- Rejuvenation
        { spell = 783, type = "buff", unit = "player" }, -- Travel Form
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 103298 }, -- Frenzied Regeneration
        { spell = 50334, type = "buff", unit = "player", talent = 103224 }, -- Berserk
        { spell = 61336, type = "buff", unit = "player", talent = 103193 }, -- Survival Instincts
        { spell = 77761, type = "buff", unit = "player", talent = 103312 }, -- Stampeding Roar
        { spell = 93622, type = "buff", unit = "player", talent = 103190 }, -- Gore
        { spell = 102558, type = "buff", unit = "player", talent = 103201 }, -- Incarnation: Guardian of Ursoc
        { spell = 124974, type = "buff", unit = "player", talent = 103324 }, -- Nature's Vigil
        { spell = 135286, type = "buff", unit = "player", talent = 103197 }, -- Tooth and Claw
        { spell = 155835, type = "buff", unit = "player", talent = 103230 }, -- Bristling Fur
        { spell = 192081, type = "buff", unit = "player", talent = 103305 }, -- Ironfur
        { spell = 200851, type = "buff", unit = "player", talent = 103207 }, -- Rage of the Sleeper
        { spell = 201671, type = "buff", unit = "player", talent = 103196 }, -- Gory Fur
        { spell = 203975, type = "buff", unit = "player", talent = 103225 }, -- Earthwarden
        { spell = 204066, type = "buff", unit = "player", talent = 114700 }, -- Lunar Beam
        { spell = 213680, type = "buff", unit = "player", talent = 103205 }, -- Guardian of Elune
        { spell = 213708, type = "buff", unit = "player", talent = 103212 }, -- Galactic Guardian
        { spell = 252216, type = "buff", unit = "player", talent = 103275 }, -- Tiger Dash
        { spell = 319454, type = "buff", unit = "player", talent = 103309 }, -- Heart of the Wild
        { spell = 372015, type = "buff", unit = "player", talent = 103227 }, -- Vicious Cycle
        { spell = 372505, type = "buff", unit = "player", talent = 103219 }, -- Ursoc's Fury
        { spell = 385787, type = "buff", unit = "player", talent = 103314 }, -- Matted Fur
        { spell = 391528, type = "buff", unit = "player", talent = 103200 }, -- Convoke the Spirits
        { spell = 393903, type = "buff", unit = "player", talent = 103313 }, -- Ursine Vigor
        { spell = 400126, type = "buff", unit = "player", talent = 123792 }, -- Forestwalk
        { spell = 400734, type = "buff", unit = "player", talent = 103206 }, -- After the Wildfire
        { spell = 431250, type = "buff", unit = "player", herotalent = 117190 }, -- Lunar Amplification
        { spell = 441602, type = "buff", unit = "player", herotalent = 117206 }, -- Ravage
        { spell = 441685, type = "buff", unit = "player", herotalent = 117207 }, -- Wildshape Mastery
        { spell = 441701, type = "buff", unit = "player" }, -- Feline Potential
        { spell = 441817, type = "buff", unit = "player", herotalent = 117219 }, -- Ruthless Aggression
        { spell = 441825, type = "buff", unit = "player", herotalent = 123048 }, -- Killing Strikes
      },
      icon = 1378702
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target", talent = 103316 }, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 103300 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 103315 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 45334, type = "debuff", unit = "target" }, -- Immobilized
        { spell = 50259, type = "debuff", unit = "target" }, -- Dazed
        { spell = 61391, type = "debuff", unit = "target", talent = 103287 }, -- Typhoon
        { spell = 80313, type = "debuff", unit = "target", talent = 103222 }, -- Pulverize
        { spell = 102359, type = "debuff", unit = "target", talent = 103322 }, -- Mass Entanglement
        { spell = 127797, type = "debuff", unit = "target", talent = 103321 }, -- Ursol's Vortex
        { spell = 135601, type = "debuff", unit = "target", talent = 103197 }, -- Tooth and Claw
        { spell = 155722, type = "debuff", unit = "target", talent = 103277 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 103286 }, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target", talent = 103301 }, -- Thrash
        { spell = 203123, type = "debuff", unit = "target", talent = 103299 }, -- Maim
        { spell = 345209, type = "debuff", unit = "target", talent = 103232 }, -- Infected Wounds
        { spell = 430589, type = "debuff", unit = "target", herotalent = 117204 }, -- Atmospheric Exposure
        { spell = 451177, type = "debuff", unit = "target", herotalent = 117220 }, -- Dreadful Wound
      },
      icon = 451161
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", debuff = true, talent = 103316 }, -- Incapacitating Roar
        { spell = 339, type = "ability", debuff = true, requiresTarget = true }, -- Entangling Roots
        { spell = 768, type = "ability", buff = true }, -- Cat Form
        { spell = 783, type = "ability", buff = true }, -- Travel Form
        { spell = 1079, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 103300 }, -- Rip
        { spell = 1822, type = "ability", requiresTarget = true, usable = true, talent = 103277 }, -- Rake
        { spell = 1850, type = "ability", buff = true }, -- Dash
        { spell = 2782, type = "ability", talent = 103293 }, -- Remove Corruption
        { spell = 2908, type = "ability", requiresTarget = true, talent = 103307 }, -- Soothe
        { spell = 5176, type = "ability", charges = true, requiresTarget = true }, -- Wrath
        { spell = 5211, type = "ability", debuff = true, requiresTarget = true, talent = 103315 }, -- Mighty Bash
        { spell = 5221, type = "ability", requiresTarget = true, usable = true }, -- Shred
        { spell = 5487, type = "ability", buff = true }, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Growl
        { spell = 6807, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 103191 }, -- Maul
        { spell = 8921, type = "ability", overlayGlow = true, requiresTarget = true }, -- Moonfire
        { spell = 16979, type = "ability", requiresTarget = true, talent = 103276 }, -- Wild Charge
        { spell = 20484, type = "ability" }, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true, usable = true }, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, usable = true, talent = 103299 }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", charges = true, buff = true, usable = true, talent = 103298 }, -- Frenzied Regeneration
        { spell = 33786, type = "ability", requiresTarget = true, talent = 103291 }, -- Cyclone
        { spell = 33917, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 103195 }, -- Mangle
        { spell = 48438, type = "ability", requiresTarget = true, talent = 103320 }, -- Wild Growth
        { spell = 50334, type = "ability", buff = true, talent = 103224 }, -- Berserk
        { spell = 61336, type = "ability", charges = true, buff = true, talent = 103193 }, -- Survival Instincts
        { spell = 77758, type = "ability", requiresTarget = true, talent = 103301 }, -- Thrash
        { spell = 77761, type = "ability", buff = true, talent = 103312 }, -- Stampeding Roar
        { spell = 80313, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 103222 }, -- Pulverize
        { spell = 93402, type = "ability", requiresTarget = true, talent = 103286 }, -- Sunfire
        { spell = 102359, type = "ability", debuff = true, requiresTarget = true, talent = 103322 }, -- Mass Entanglement
        { spell = 102558, type = "ability", buff = true, talent = 103201 }, -- Incarnation: Guardian of Ursoc
        { spell = 102793, type = "ability", talent = 103321 }, -- Ursol's Vortex
        { spell = 106832, type = "ability", requiresTarget = true, usable = true, talent = 103301 }, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true, usable = true, talent = 103302 }, -- Skull Bash
        { spell = 108238, type = "ability", talent = 103310 }, -- Renewal
        { spell = 124974, type = "ability", buff = true, talent = 103324 }, -- Nature's Vigil
        { spell = 132469, type = "ability", talent = 103287 }, -- Typhoon
        { spell = 155835, type = "ability", buff = true, talent = 103230 }, -- Bristling Fur
        { spell = 192081, type = "ability", buff = true, usable = true, talent = 103305 }, -- Ironfur
        { spell = 197626, type = "ability", requiresTarget = true, talent = 103278 }, -- Starsurge
        { spell = 197628, type = "ability", charges = true, requiresTarget = true, talent = 112964 }, -- Starfire
        { spell = 200851, type = "ability", buff = true, usable = true, talent = 103207 }, -- Rage of the Sleeper
        { spell = 204066, type = "ability", buff = true, talent = 114700 }, -- Lunar Beam
        { spell = 252216, type = "ability", buff = true, talent = 103275 }, -- Tiger Dash
        { spell = 319454, type = "ability", buff = true, talent = 103309 }, -- Heart of the Wild
        { spell = 391528, type = "ability", buff = true, talent = 103200 }, -- Convoke the Spirits
      },
      icon = 236169
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 774, type = "buff", unit = "player", talent = 103295 }, -- Rejuvenation
        { spell = 1126, type = "buff", unit = "player" }, -- Mark of the Wild
        { spell = 1850, type = "buff", unit = "player" }, -- Dash
        { spell = 5215, type = "buff", unit = "player" }, -- Prowl
        { spell = 5487, type = "buff", unit = "player" }, -- Bear Form
        { spell = 8936, type = "buff", unit = "player" }, -- Regrowth
        { spell = 16870, type = "buff", unit = "player" }, -- Clearcasting
        { spell = 22812, type = "buff", unit = "player" }, -- Barkskin
        { spell = 22842, type = "buff", unit = "player", talent = 103298 }, -- Frenzied Regeneration
        { spell = 29166, type = "buff", unit = "player", talent = 103323 }, -- Innervate
        { spell = 33763, type = "buff", unit = "player", talent = 103100 }, -- Lifebloom
        { spell = 33891, type = "buff", unit = "player", talent = 103120 }, -- Incarnation: Tree of Life
        { spell = 48438, type = "buff", unit = "player", talent = 103320 }, -- Wild Growth
        { spell = 77764, type = "buff", unit = "player", talent = 103312 }, -- Stampeding Roar
        { spell = 102342, type = "buff", unit = "player", talent = 103141 }, -- Ironbark
        { spell = 102351, type = "buff", unit = "player", talent = 103104 }, -- Cenarion Ward
        { spell = 114108, type = "buff", unit = "player", talent = 103113 }, -- Soul of the Forest
        { spell = 117679, type = "buff", unit = "player" }, -- Incarnation
        { spell = 124974, type = "buff", unit = "player", talent = 103324 }, -- Nature's Vigil
        { spell = 132158, type = "buff", unit = "player", talent = 103101 }, -- Nature's Swiftness
        { spell = 145205, type = "buff", unit = "player", talent = 103111 }, -- Efflorescence
        { spell = 155777, type = "buff", unit = "player" }, -- Rejuvenation (Germination)
        { spell = 157982, type = "buff", unit = "player", talent = 103108 }, -- Tranquility
        { spell = 192081, type = "buff", unit = "player", talent = 103305 }, -- Ironfur
        { spell = 197721, type = "buff", unit = "player", talent = 123776 }, -- Flourish
        { spell = 207386, type = "buff", unit = "player", talent = 103116 }, -- Spring Blossoms
        { spell = 207640, type = "buff", unit = "player", talent = 103105 }, -- Abundance
        { spell = 252216, type = "buff", unit = "player", talent = 103275 }, -- Tiger Dash
        { spell = 319454, type = "buff", unit = "player", talent = 103309 }, -- Heart of the Wild
        { spell = 383193, type = "buff", unit = "player", talent = 103098 }, -- Grove Tending
        { spell = 385787, type = "buff", unit = "player", talent = 103314 }, -- Matted Fur
        { spell = 391528, type = "buff", unit = "player", talent = 103119 }, -- Convoke the Spirits
        { spell = 392303, type = "buff", unit = "player", talent = 103134 }, -- Power of the Archdruid
        { spell = 392360, type = "buff", unit = "player", talent = 103125 }, -- Reforestation
        { spell = 393903, type = "buff", unit = "player", talent = 103313 }, -- Ursine Vigor
        { spell = 400126, type = "buff", unit = "player", talent = 123792 }, -- Forestwalk
        { spell = 428737, type = "buff", unit = "player", herotalent = 117203 }, -- Harmony of the Grove
        { spell = 428866, type = "buff", unit = "player", herotalent = 117201 }, -- Power of Nature
        { spell = 429474, type = "buff", unit = "player", herotalent = 117196 }, -- Blooming Infusion
        { spell = 433749, type = "buff", unit = "player", herotalent = 117186 }, -- Protective Growth
        { spell = 434112, type = "buff", unit = "player", herotalent = 117195 }, -- Dream Surge
        { spell = 439530, type = "buff", unit = "player" }, -- Symbiotic Blooms
        { spell = 439887, type = "buff", unit = "player", herotalent = 117233 }, -- Root Network
        { spell = 439893, type = "buff", unit = "player", herotalent = 117223 }, -- Strategic Infusion
        { spell = 455801, type = "buff", unit = "player", herotalent = 117199 }, -- Cenarius' Might
      },
      icon = 136081
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 99, type = "debuff", unit = "target", talent = 103316 }, -- Incapacitating Roar
        { spell = 339, type = "debuff", unit = "target" }, -- Entangling Roots
        { spell = 1079, type = "debuff", unit = "target", talent = 103300 }, -- Rip
        { spell = 5211, type = "debuff", unit = "target", talent = 103315 }, -- Mighty Bash
        { spell = 6795, type = "debuff", unit = "target" }, -- Growl
        { spell = 50259, type = "debuff", unit = "target" }, -- Dazed
        { spell = 61391, type = "debuff", unit = "target", talent = 103287 }, -- Typhoon
        { spell = 102359, type = "debuff", unit = "target", talent = 103322 }, -- Mass Entanglement
        { spell = 127797, type = "debuff", unit = "target", talent = 103321 }, -- Ursol's Vortex
        { spell = 155722, type = "debuff", unit = "target", talent = 103277 }, -- Rake
        { spell = 164812, type = "debuff", unit = "target" }, -- Moonfire
        { spell = 164815, type = "debuff", unit = "target", talent = 103286 }, -- Sunfire
        { spell = 192090, type = "debuff", unit = "target", talent = 103301 }, -- Thrash
        { spell = 203123, type = "debuff", unit = "target", talent = 103299 }, -- Maim
        { spell = 439531, type = "debuff", unit = "target" }, -- Bloodseeker Vines
      },
      icon = 236216
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 99, type = "ability", debuff = true, talent = 103316 }, -- Incapacitating Roar
        { spell = 339, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Entangling Roots
        { spell = 740, type = "ability", talent = 103108 }, -- Tranquility
        { spell = 768, type = "ability", buff = true }, -- Cat Form
        { spell = 1079, type = "ability", debuff = true, requiresTarget = true, usable = true, talent = 103300 }, -- Rip
        { spell = 1822, type = "ability", requiresTarget = true, usable = true, talent = 103277 }, -- Rake
        { spell = 1850, type = "ability", buff = true }, -- Dash
        { spell = 2908, type = "ability", requiresTarget = true, talent = 103307 }, -- Soothe
        { spell = 5176, type = "ability", overlayGlow = true, requiresTarget = true }, -- Wrath
        { spell = 5211, type = "ability", debuff = true, requiresTarget = true, talent = 103315 }, -- Mighty Bash
        { spell = 5215, type = "ability", buff = true, usable = true }, -- Prowl
        { spell = 5221, type = "ability", requiresTarget = true, usable = true }, -- Shred
        { spell = 5487, type = "ability", buff = true }, -- Bear Form
        { spell = 6795, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Growl
        { spell = 8921, type = "ability", requiresTarget = true }, -- Moonfire
        { spell = 16979, type = "ability", requiresTarget = true, talent = 103276 }, -- Wild Charge
        { spell = 18562, type = "ability", charges = true, usable = true }, -- Swiftmend
        { spell = 20484, type = "ability" }, -- Rebirth
        { spell = 22568, type = "ability", requiresTarget = true, usable = true }, -- Ferocious Bite
        { spell = 22570, type = "ability", requiresTarget = true, usable = true, talent = 103299 }, -- Maim
        { spell = 22812, type = "ability", buff = true }, -- Barkskin
        { spell = 22842, type = "ability", charges = true, buff = true, usable = true, talent = 103298 }, -- Frenzied Regeneration
        { spell = 29166, type = "ability", buff = true, talent = 103323 }, -- Innervate
        { spell = 33786, type = "ability", requiresTarget = true, talent = 103291 }, -- Cyclone
        { spell = 33891, type = "ability", buff = true, talent = 103120 }, -- Incarnation: Tree of Life
        { spell = 33917, type = "ability", requiresTarget = true, usable = true, talent = 103195 }, -- Mangle
        { spell = 48438, type = "ability", buff = true, overlayGlow = true, requiresTarget = true, talent = 103320 }, -- Wild Growth
        { spell = 77758, type = "ability", requiresTarget = true, talent = 103301 }, -- Thrash
        { spell = 77764, type = "ability", buff = true, talent = 103312 }, -- Stampeding Roar
        { spell = 88423, type = "ability" }, -- Nature's Cure
        { spell = 93402, type = "ability", requiresTarget = true, talent = 103286 }, -- Sunfire
        { spell = 102342, type = "ability", buff = true, talent = 103141 }, -- Ironbark
        { spell = 102351, type = "ability", buff = true, talent = 103104 }, -- Cenarion Ward
        { spell = 102359, type = "ability", debuff = true, requiresTarget = true, talent = 103322 }, -- Mass Entanglement
        { spell = 102693, type = "ability", charges = true, talent = 117104 }, -- Grove Guardians
        { spell = 102793, type = "ability", talent = 103321 }, -- Ursol's Vortex
        { spell = 106832, type = "ability", requiresTarget = true, usable = true, talent = 103301 }, -- Thrash
        { spell = 106839, type = "ability", requiresTarget = true, usable = true, talent = 103302 }, -- Skull Bash
        { spell = 108238, type = "ability", talent = 103310 }, -- Renewal
        { spell = 124974, type = "ability", buff = true, talent = 103324 }, -- Nature's Vigil
        { spell = 132158, type = "ability", charges = true, buff = true, usable = true, talent = 103101 }, -- Nature's Swiftness
        { spell = 132469, type = "ability", talent = 103287 }, -- Typhoon
        { spell = 192081, type = "ability", buff = true, usable = true, talent = 103305 }, -- Ironfur
        { spell = 197626, type = "ability", requiresTarget = true, talent = 103278 }, -- Starsurge
        { spell = 197628, type = "ability", overlayGlow = true, requiresTarget = true, talent = 112963 }, -- Starfire
        { spell = 197721, type = "ability", buff = true, talent = 123776 }, -- Flourish
        { spell = 203651, type = "ability", talent = 103115 }, -- Overgrowth
        { spell = 252216, type = "ability", buff = true, talent = 103275 }, -- Tiger Dash
        { spell = 319454, type = "ability", buff = true, talent = 103309 }, -- Heart of the Wild
        { spell = 391528, type = "ability", buff = true, talent = 103119 }, -- Convoke the Spirits
      },
      icon = 236153
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 196555, type = "buff", unit = "player", talent = 115247 }, -- Netherwalk
        { spell = 208628, type = "buff", unit = "player", talent = 112943 }, -- Momentum
        { spell = 209426, type = "buff", unit = "player", talent = 112921 }, -- Darkness
        { spell = 212800, type = "buff", unit = "player" }, -- Blur
        { spell = 258920, type = "buff", unit = "player" }, -- Immolation Aura
        { spell = 258925, type = "buff", unit = "player", talent = 117742 }, -- Fel Barrage
        { spell = 343312, type = "buff", unit = "player", talent = 112948 }, -- Furious Gaze
        { spell = 347462, type = "buff", unit = "player", talent = 112942 }, -- Unbound Chaos
        { spell = 389847, type = "buff", unit = "player", talent = 112850 }, -- Felfire Haste
        { spell = 389890, type = "buff", unit = "player", talent = 112944 }, -- Tactical Retreat
        { spell = 390145, type = "buff", unit = "player", talent = 112947 }, -- Inner Demon
        { spell = 390192, type = "buff", unit = "player", talent = 112827 }, -- Ragefire
        { spell = 390195, type = "buff", unit = "player", talent = 112958 }, -- Chaos Theory
        { spell = 390212, type = "buff", unit = "player", talent = 117765 }, -- Restless Hunter
        { spell = 391215, type = "buff", unit = "player", talent = 112950 }, -- Initiative
        { spell = 427641, type = "buff", unit = "player", talent = 117744 }, -- Inertia
        { spell = 427901, type = "buff", unit = "player", talent = 115246 }, -- Deflecting Dance
        { spell = 442435, type = "buff", unit = "player" }, -- Glaive Flurry
        { spell = 442442, type = "buff", unit = "player" }, -- Rending Strike
        { spell = 442503, type = "buff", unit = "player", herotalent = 117503 }, -- Warblade's Hunger
        { spell = 442688, type = "buff", unit = "player", herotalent = 117516 }, -- Thrill of the Fight
        { spell = 442715, type = "buff", unit = "player" }, -- Blade Ward
        { spell = 442788, type = "buff", unit = "player", herotalent = 123046 }, -- Incorruptible Spirit
        { spell = 444661, type = "buff", unit = "player", herotalent = 117512 }, -- Art of the Glaive
        { spell = 444929, type = "buff", unit = "player", herotalent = 117508 }, -- Evasive Action
        { spell = 452416, type = "buff", unit = "player", herotalent = 117514 }, -- Demonsurge
        { spell = 452550, type = "buff", unit = "player", herotalent = 117506 }, -- Monster Rising
        { spell = 453239, type = "buff", unit = "player", herotalent = 117499 }, -- Student of Suffering
        { spell = 453314, type = "buff", unit = "player", herotalent = 117513 }, -- Enduring Torment
      },
      icon = 1247266
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1490, type = "debuff", unit = "target" }, -- Chaos Brand
        { spell = 185245, type = "debuff", unit = "target" }, -- Torment
        { spell = 198813, type = "debuff", unit = "target", talent = 112853 }, -- Vengeful Retreat
        { spell = 200166, type = "debuff", unit = "target" }, -- Metamorphosis
        { spell = 204598, type = "debuff", unit = "target" }, -- Sigil of Flame
        { spell = 207685, type = "debuff", unit = "target", talent = 112859 }, -- Sigil of Misery
        { spell = 211881, type = "debuff", unit = "target" }, -- Fel Eruption
        { spell = 258883, type = "debuff", unit = "target", talent = 112824 }, -- Trail of Ruin
        { spell = 320338, type = "debuff", unit = "target", talent = 112956 }, -- Essence Break
        { spell = 356608, type = "debuff", unit = "target", talent = 117743 }, -- Mortal Dance
        { spell = 370966, type = "debuff", unit = "target", talent = 112837 }, -- The Hunt
        { spell = 390155, type = "debuff", unit = "target", talent = 112934 }, -- Serrated Glaive
        { spell = 390181, type = "debuff", unit = "target", talent = 117764 }, -- Soulscar
        { spell = 391191, type = "debuff", unit = "target", talent = 112826 }, -- Burning Wound
        { spell = 394933, type = "debuff", unit = "target", talent = 112838 }, -- Demon Muzzle
        { spell = 442624, type = "debuff", unit = "target", herotalent = 117500 }, -- Reaver's Mark
        { spell = 453177, type = "debuff", unit = "target", herotalent = 117502 }, -- Burning Blades
      },
      icon = 1392554
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 131347, type = "ability", usable = true }, -- Glide
        { spell = 162243, type = "ability", requiresTarget = true, usable = true }, -- Demon's Bite
        { spell = 162794, type = "ability", requiresTarget = true, usable = true }, -- Chaos Strike
        { spell = 179057, type = "ability", usable = true, talent = 112911 }, -- Chaos Nova
        { spell = 183752, type = "ability", requiresTarget = true, usable = true }, -- Disrupt
        { spell = 185123, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, usable = true }, -- Throw Glaive
        { spell = 185245, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Torment
        { spell = 188499, type = "ability", overlayGlow = true, usable = true }, -- Blade Dance
        { spell = 188501, type = "ability", buff = true, usable = true }, -- Spectral Sight
        { spell = 191427, type = "ability", usable = true }, -- Metamorphosis
        { spell = 195072, type = "ability", charges = true, overlayGlow = true, usable = true }, -- Fel Rush
        { spell = 196555, type = "ability", buff = true, usable = true, talent = 115247 }, -- Netherwalk
        { spell = 196718, type = "ability", usable = true, talent = 112921 }, -- Darkness
        { spell = 198013, type = "ability", usable = true, talent = 112939 }, -- Eye Beam
        { spell = 198589, type = "ability", usable = true }, -- Blur
        { spell = 198793, type = "ability", usable = true, talent = 112853 }, -- Vengeful Retreat
        { spell = 202137, type = "ability", requiresTarget = true, talent = 112904 }, -- Sigil of Silence
        { spell = 202138, type = "ability", requiresTarget = true, talent = 112867 }, -- Sigil of Chains
        { spell = 204596, type = "ability", requiresTarget = true, usable = true }, -- Sigil of Flame
        { spell = 207684, type = "ability", requiresTarget = true, talent = 112859 }, -- Sigil of Misery
        { spell = 210152, type = "ability", overlayGlow = true }, -- Death Sweep
        { spell = 211881, type = "ability", debuff = true, requiresTarget = true, usable = true }, -- Fel Eruption
        { spell = 217832, type = "ability", usable = true, talent = 112927 }, -- Imprison
        { spell = 232893, type = "ability", overlayGlow = true, requiresTarget = true, usable = true, talent = 117759 }, -- Felblade
        { spell = 258860, type = "ability", usable = true, talent = 112956 }, -- Essence Break
        { spell = 258920, type = "ability", charges = true, buff = true, usable = true }, -- Immolation Aura
        { spell = 258925, type = "ability", buff = true, usable = true, talent = 117742 }, -- Fel Barrage
        { spell = 278326, type = "ability", requiresTarget = true, usable = true, talent = 112926 }, -- Consume Magic
        { spell = 342817, type = "ability", talent = 117763 }, -- Glaive Tempest
        { spell = 370965, type = "ability", requiresTarget = true, usable = true, talent = 112837 }, -- The Hunt
        { spell = 389815, type = "ability", requiresTarget = true, talent = 117755 }, -- Sigil of Spite
        { spell = 427785, type = "ability", overlayGlow = true }, -- Fel Rush
        { spell = 427917, type = "ability", charges = true }, -- Immolation Aura
        { spell = 452487, type = "ability", overlayGlow = true }, -- Consuming Fire
        { spell = 452497, type = "ability", overlayGlow = true }, -- Abyssal Gaze
      },
      icon = 1305156
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 131347, type = "buff", unit = "player" }, -- Glide
        { spell = 187827, type = "buff", unit = "player" }, -- Metamorphosis
        { spell = 188501, type = "buff", unit = "player" }, -- Spectral Sight
        { spell = 203819, type = "buff", unit = "player" }, -- Demon Spikes
        { spell = 203981, type = "buff", unit = "player" }, -- Soul Fragments
        { spell = 207693, type = "buff", unit = "player", talent = 112884 }, -- Feast of Souls
        { spell = 209426, type = "buff", unit = "player", talent = 112921 }, -- Darkness
        { spell = 212988, type = "buff", unit = "player", talent = 112892 }, -- Painbringer
        { spell = 258920, type = "buff", unit = "player" }, -- Immolation Aura
        { spell = 263648, type = "buff", unit = "player", talent = 112870 }, -- Soul Barrier
        { spell = 326863, type = "buff", unit = "player", talent = 112880 }, -- Ruinous Bulwark
        { spell = 343013, type = "buff", unit = "player", talent = 112871 }, -- Revel in Pain
        { spell = 389847, type = "buff", unit = "player", talent = 112850 }, -- Felfire Haste
        { spell = 391166, type = "buff", unit = "player", talent = 112890 }, -- Soul Furnace
        { spell = 391171, type = "buff", unit = "player", talent = 112882 }, -- Calcified Spikes
        { spell = 391234, type = "buff", unit = "player", talent = 112889 }, -- Soulmonger
        { spell = 393009, type = "buff", unit = "player", talent = 112868 }, -- Fel Flame Fortification
        { spell = 442435, type = "buff", unit = "player" }, -- Glaive Flurry
        { spell = 442442, type = "buff", unit = "player" }, -- Rending Strike
        { spell = 442503, type = "buff", unit = "player", herotalent = 117503 }, -- Warblade's Hunger
        { spell = 442688, type = "buff", unit = "player", herotalent = 117516 }, -- Thrill of the Fight
        { spell = 442715, type = "buff", unit = "player" }, -- Blade Ward
        { spell = 442788, type = "buff", unit = "player", herotalent = 123046 }, -- Incorruptible Spirit
        { spell = 444661, type = "buff", unit = "player", herotalent = 117512 }, -- Art of the Glaive
        { spell = 444929, type = "buff", unit = "player", herotalent = 117508 }, -- Evasive Action
        { spell = 452416, type = "buff", unit = "player", herotalent = 117514 }, -- Demonsurge
        { spell = 452550, type = "buff", unit = "player", herotalent = 117506 }, -- Monster Rising
        { spell = 453239, type = "buff", unit = "player", herotalent = 117499 }, -- Student of Suffering
        { spell = 453314, type = "buff", unit = "player", herotalent = 117513 }, -- Enduring Torment
      },
      icon = 1247263
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 1490, type = "debuff", unit = "target" }, -- Chaos Brand
        { spell = 179057, type = "debuff", unit = "target", talent = 112911 }, -- Chaos Nova
        { spell = 185245, type = "debuff", unit = "target" }, -- Torment
        { spell = 198813, type = "debuff", unit = "target", talent = 112853 }, -- Vengeful Retreat
        { spell = 204490, type = "debuff", unit = "target", talent = 112904 }, -- Sigil of Silence
        { spell = 204598, type = "debuff", unit = "target" }, -- Sigil of Flame
        { spell = 204843, type = "debuff", unit = "target", talent = 112867 }, -- Sigil of Chains
        { spell = 207407, type = "debuff", unit = "target", talent = 112898 }, -- Soul Carver
        { spell = 207685, type = "debuff", unit = "target", talent = 112859 }, -- Sigil of Misery
        { spell = 207771, type = "debuff", unit = "target", talent = 112864 }, -- Fiery Brand
        { spell = 247456, type = "debuff", unit = "target", talent = 112907 }, -- Frailty
        { spell = 370966, type = "debuff", unit = "target", talent = 112837 }, -- The Hunt
        { spell = 394933, type = "debuff", unit = "target", talent = 112838 }, -- Demon Muzzle
        { spell = 442624, type = "debuff", unit = "target", herotalent = 117500 }, -- Reaver's Mark
        { spell = 453177, type = "debuff", unit = "target", herotalent = 117502 }, -- Burning Blades
      },
      icon = 1344647
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 131347, type = "ability", buff = true, usable = true }, -- Glide
        { spell = 179057, type = "ability", debuff = true, talent = 112911 }, -- Chaos Nova
        { spell = 183752, type = "ability", requiresTarget = true }, -- Disrupt
        { spell = 185245, type = "ability", debuff = true, requiresTarget = true }, -- Torment
        { spell = 187827, type = "ability", buff = true }, -- Metamorphosis
        { spell = 188501, type = "ability", buff = true }, -- Spectral Sight
        { spell = 189110, type = "ability", charges = true }, -- Infernal Strike
        { spell = 196718, type = "ability", talent = 112921 }, -- Darkness
        { spell = 198793, type = "ability", talent = 112853 }, -- Vengeful Retreat
        { spell = 202137, type = "ability", requiresTarget = true, talent = 112904 }, -- Sigil of Silence
        { spell = 202138, type = "ability", requiresTarget = true, talent = 112867 }, -- Sigil of Chains
        { spell = 203720, type = "ability", charges = true }, -- Demon Spikes
        { spell = 204021, type = "ability", charges = true, requiresTarget = true, talent = 112864 }, -- Fiery Brand
        { spell = 204157, type = "ability", charges = true, overlayGlow = true, requiresTarget = true }, -- Throw Glaive
        { spell = 204596, type = "ability", requiresTarget = true }, -- Sigil of Flame
        { spell = 207407, type = "ability", debuff = true, requiresTarget = true, talent = 112898 }, -- Soul Carver
        { spell = 207684, type = "ability", requiresTarget = true, talent = 112859 }, -- Sigil of Misery
        { spell = 212084, type = "ability", talent = 112908 }, -- Fel Devastation
        { spell = 217832, type = "ability", talent = 112927 }, -- Imprison
        { spell = 228477, type = "ability", charges = true, overlayGlow = true, requiresTarget = true }, -- Soul Cleave
        { spell = 232893, type = "ability", requiresTarget = true, talent = 117759 }, -- Felblade
        { spell = 247454, type = "ability", charges = true, overlayGlow = true, usable = true, talent = 112894 }, -- Spirit Bomb
        { spell = 258920, type = "ability", buff = true }, -- Immolation Aura
        { spell = 263642, type = "ability", charges = true, requiresTarget = true, talent = 112885 }, -- Fracture
        { spell = 263648, type = "ability", charges = true, buff = true, talent = 112870 }, -- Soul Barrier
        { spell = 278326, type = "ability", requiresTarget = true, talent = 112926 }, -- Consume Magic
        { spell = 320341, type = "ability", talent = 112869 }, -- Bulk Extraction
        { spell = 370965, type = "ability", usable = true, talent = 112837 }, -- The Hunt
        { spell = 389815, type = "ability", requiresTarget = true, talent = 117755 }, -- Sigil of Spite
        { spell = 452436, type = "ability", charges = true, overlayGlow = true }, -- Soul Sunder
        { spell = 452486, type = "ability", overlayGlow = true }, -- Fel Desolation
        { spell = 452487, type = "ability", overlayGlow = true }, -- Consuming Fire
      },
      icon = 1344650
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 48265, type = "buff", unit = "player" }, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player" }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player", talent = 96210 }, -- Icebound Fortitude
        { spell = 49039, type = "buff", unit = "player" }, -- Lichborne
        { spell = 55233, type = "buff", unit = "player", talent = 96308 }, -- Vampiric Blood
        { spell = 77535, type = "buff", unit = "player" }, -- Blood Shield
        { spell = 81141, type = "buff", unit = "player" }, -- Crimson Scourge
        { spell = 81256, type = "buff", unit = "player", talent = 96269 }, -- Dancing Rune Weapon
        { spell = 145629, type = "buff", unit = "player", talent = 96194 }, -- Anti-Magic Zone
        { spell = 188290, type = "buff", unit = "player" }, -- Death and Decay
        { spell = 194679, type = "buff", unit = "player", talent = 96301 }, -- Rune Tap
        { spell = 194844, type = "buff", unit = "player", talent = 96258 }, -- Bonestorm
        { spell = 194879, type = "buff", unit = "player", talent = 96214 }, -- Icy Talons
        { spell = 195181, type = "buff", unit = "player" }, -- Bone Shield
        { spell = 207203, type = "buff", unit = "player" }, -- Frost Shield
        { spell = 212552, type = "buff", unit = "player", talent = 96206 }, -- Wraith Walk
        { spell = 219788, type = "buff", unit = "player", talent = 96277 }, -- Ossuary
        { spell = 219809, type = "buff", unit = "player", talent = 96270 }, -- Tombstone
        { spell = 273947, type = "buff", unit = "player", talent = 96268 }, -- Hemostasis
        { spell = 274009, type = "buff", unit = "player", talent = 96171 }, -- Voracious
        { spell = 274156, type = "buff", unit = "player", talent = 126299 }, -- Consumption
        { spell = 374271, type = "buff", unit = "player", talent = 96198 }, -- Unholy Ground
        { spell = 374585, type = "buff", unit = "player", talent = 96208 }, -- Rune Mastery
        { spell = 374748, type = "buff", unit = "player", talent = 96255 }, -- Perseverance of the Ebon Blade
        { spell = 383269, type = "buff", unit = "player", talent = 96177 }, -- Abomination Limb
        { spell = 391459, type = "buff", unit = "player", talent = 96169 }, -- Sanguine Ground
        { spell = 391481, type = "buff", unit = "player", talent = 96166 }, -- Coagulopathy
        { spell = 391519, type = "buff", unit = "player", talent = 96168 }, -- Umbilicus Eternus
        { spell = 433925, type = "buff", unit = "player" }, -- Essence of the Blood Queen
        { spell = 434034, type = "buff", unit = "player", herotalent = 117645 }, -- Blood-Soaked Ground
        { spell = 434105, type = "buff", unit = "player", herotalent = 117653 }, -- Vampiric Aura
        { spell = 434153, type = "buff", unit = "player", herotalent = 117650 }, -- Gift of the San'layn
        { spell = 440289, type = "buff", unit = "player", herotalent = 123420 }, -- Rune Carved Plates
        { spell = 441416, type = "buff", unit = "player", herotalent = 117665 }, -- Exterminate
        { spell = 458745, type = "buff", unit = "player", talent = 96279 }, -- Ossified Vitriol
        { spell = 460049, type = "buff", unit = "player", herotalent = 117630 }, -- Infliction of Sorrow
        { spell = 461130, type = "buff", unit = "player", herotalent = 117642 }, -- Visceral Strength
        { spell = 469169, type = "buff", unit = "player", herotalent = 117629 }, -- Swift and Painful
        { spell = 469172, type = "buff", unit = "player", herotalent = 128235 }, -- Reaper of Souls
      },
      icon = 237517
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target" }, -- Chains of Ice
        { spell = 55078, type = "debuff", unit = "target" }, -- Blood Plague
        { spell = 206931, type = "debuff", unit = "target", talent = 126300 }, -- Blooddrinker
        { spell = 206940, type = "debuff", unit = "target", talent = 96271 }, -- Mark of Blood
        { spell = 343294, type = "debuff", unit = "target", talent = 96192 }, -- Soul Reaper
        { spell = 374557, type = "debuff", unit = "target", talent = 96190 }, -- Brittle
        { spell = 391568, type = "debuff", unit = "target", talent = 96179 }, -- Insidious Chill
        { spell = 434765, type = "debuff", unit = "target", herotalent = 117659 }, -- Reaper's Mark
        { spell = 443404, type = "debuff", unit = "target", herotalent = 117633 }, -- Wave of Souls
        { spell = 454824, type = "debuff", unit = "target", talent = 96209 }, -- Subduing Grasp
        { spell = 458478, type = "debuff", unit = "target", herotalent = 117637 }, -- Incite Terror
      },
      icon = 237514
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability", buff = true }, -- Path of Frost
        { spell = 43265, type = "ability", charges = true, overlayGlow = true }, -- Death and Decay
        { spell = 45524, type = "ability", debuff = true, requiresTarget = true }, -- Chains of Ice
        { spell = 47528, type = "ability", requiresTarget = true, talent = 96213 }, -- Mind Freeze
        { spell = 47541, type = "ability", requiresTarget = true }, -- Death Coil
        { spell = 48265, type = "ability", charges = true, buff = true }, -- Death's Advance
        { spell = 48707, type = "ability", buff = true }, -- Anti-Magic Shell
        { spell = 48743, type = "ability", talent = 96204 }, -- Death Pact
        { spell = 48792, type = "ability", buff = true, talent = 96210 }, -- Icebound Fortitude
        { spell = 49028, type = "ability", requiresTarget = true, talent = 96269 }, -- Dancing Rune Weapon
        { spell = 49039, type = "ability", buff = true }, -- Lichborne
        { spell = 49576, type = "ability", charges = true, requiresTarget = true }, -- Death Grip
        { spell = 49998, type = "ability", requiresTarget = true, talent = 96200 }, -- Death Strike
        { spell = 50842, type = "ability", charges = true, talent = 96305 }, -- Blood Boil
        { spell = 50977, type = "ability", usable = true }, -- Death Gate
        { spell = 51052, type = "ability", talent = 96194 }, -- Anti-Magic Zone
        { spell = 55233, type = "ability", buff = true, talent = 96308 }, -- Vampiric Blood
        { spell = 56222, type = "ability", requiresTarget = true }, -- Dark Command
        { spell = 61999, type = "ability" }, -- Raise Ally
        { spell = 108199, type = "ability", requiresTarget = true, talent = 96170 }, -- Gorefiend's Grasp
        { spell = 111673, type = "ability", talent = 96188 }, -- Control Undead
        { spell = 194679, type = "ability", charges = true, buff = true, talent = 96301 }, -- Rune Tap
        { spell = 194844, type = "ability", buff = true, usable = true, talent = 96258 }, -- Bonestorm
        { spell = 195182, type = "ability", charges = true, overlayGlow = true, requiresTarget = true, talent = 96303 }, -- Marrowrend
        { spell = 195292, type = "ability", requiresTarget = true }, -- Death's Caress
        { spell = 206930, type = "ability", overlayGlow = true, requiresTarget = true, talent = 96304 }, -- Heart Strike
        { spell = 206931, type = "ability", debuff = true, requiresTarget = true, talent = 126300 }, -- Blooddrinker
        { spell = 206940, type = "ability", debuff = true, requiresTarget = true, talent = 96271 }, -- Mark of Blood
        { spell = 207167, type = "ability", talent = 96172 }, -- Blinding Sleet
        { spell = 212552, type = "ability", buff = true, talent = 96206 }, -- Wraith Walk
        { spell = 219809, type = "ability", buff = true, usable = true, talent = 96270 }, -- Tombstone
        { spell = 221562, type = "ability", requiresTarget = true, talent = 96193 }, -- Asphyxiate
        { spell = 221699, type = "ability", charges = true, talent = 96167 }, -- Blood Tap
        { spell = 274156, type = "ability", buff = true, talent = 126299 }, -- Consumption
        { spell = 343294, type = "ability", debuff = true, requiresTarget = true, talent = 96192 }, -- Soul Reaper
        { spell = 383269, type = "ability", buff = true, talent = 96177 }, -- Abomination Limb
        { spell = 433895, type = "ability", overlayGlow = true, herotalent = 117648 }, -- Vampiric Strike
        { spell = 439843, type = "ability", requiresTarget = true, herotalent = 117659 }, -- Reaper's Mark
      },
      icon = 136120
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 47568, type = "buff", unit = "player", talent = 96240 }, -- Empower Rune Weapon
        { spell = 48265, type = "buff", unit = "player" }, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player" }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player", talent = 96210 }, -- Icebound Fortitude
        { spell = 49039, type = "buff", unit = "player" }, -- Lichborne
        { spell = 51124, type = "buff", unit = "player", talent = 96247 }, -- Killing Machine
        { spell = 51271, type = "buff", unit = "player", talent = 125874 }, -- Pillar of Frost
        { spell = 59052, type = "buff", unit = "player" }, -- Rime
        { spell = 145629, type = "buff", unit = "player", talent = 96194 }, -- Anti-Magic Zone
        { spell = 152279, type = "buff", unit = "player", talent = 96222 }, -- Breath of Sindragosa
        { spell = 188290, type = "buff", unit = "player" }, -- Death and Decay
        { spell = 194879, type = "buff", unit = "player", talent = 96214 }, -- Icy Talons
        { spell = 196770, type = "buff", unit = "player" }, -- Remorseless Winter
        { spell = 207203, type = "buff", unit = "player" }, -- Frost Shield
        { spell = 211805, type = "buff", unit = "player", talent = 96229 }, -- Gathering Storm
        { spell = 212552, type = "buff", unit = "player", talent = 96206 }, -- Wraith Walk
        { spell = 253595, type = "buff", unit = "player", talent = 96165 }, -- Inexorable Assault
        { spell = 281209, type = "buff", unit = "player", talent = 96163 }, -- Cold Heart
        { spell = 374271, type = "buff", unit = "player", talent = 96198 }, -- Unholy Ground
        { spell = 374585, type = "buff", unit = "player", talent = 96208 }, -- Rune Mastery
        { spell = 376907, type = "buff", unit = "player", talent = 96248 }, -- Unleashed Frenzy
        { spell = 377101, type = "buff", unit = "player", talent = 96253 }, -- Bonegrinder
        { spell = 377192, type = "buff", unit = "player", talent = 96230 }, -- Enduring Strength
        { spell = 377253, type = "buff", unit = "player", talent = 96236 }, -- Frostwhelp's Aid
        { spell = 383269, type = "buff", unit = "player", talent = 96177 }, -- Abomination Limb
        { spell = 440289, type = "buff", unit = "player", herotalent = 123420 }, -- Rune Carved Plates
        { spell = 441416, type = "buff", unit = "player", herotalent = 117665 }, -- Exterminate
        { spell = 443532, type = "buff", unit = "player", herotalent = 117640 }, -- Bind in Darkness
        { spell = 444505, type = "buff", unit = "player", herotalent = 117664 }, -- Mograine's Might
        { spell = 444763, type = "buff", unit = "player" }, -- Apocalyptic Conquest
        { spell = 456370, type = "buff", unit = "player", talent = 96239 }, -- Cryogenic Chamber
        { spell = 469169, type = "buff", unit = "player", herotalent = 117629 }, -- Swift and Painful
        { spell = 469172, type = "buff", unit = "player", herotalent = 128235 }, -- Reaper of Souls
      },
      icon = 135305
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target" }, -- Chains of Ice
        { spell = 51714, type = "debuff", unit = "target" }, -- Razorice
        { spell = 55095, type = "debuff", unit = "target" }, -- Frost Fever
        { spell = 204206, type = "debuff", unit = "target" }, -- Chilled
        { spell = 211793, type = "debuff", unit = "target" }, -- Remorseless Winter
        { spell = 343294, type = "debuff", unit = "target", talent = 96192 }, -- Soul Reaper
        { spell = 374557, type = "debuff", unit = "target", talent = 96190 }, -- Brittle
        { spell = 376974, type = "debuff", unit = "target", talent = 96243 }, -- Everfrost
        { spell = 377359, type = "debuff", unit = "target", talent = 96227 }, -- Piercing Chill
        { spell = 391568, type = "debuff", unit = "target", talent = 96179 }, -- Insidious Chill
        { spell = 392490, type = "debuff", unit = "target", talent = 96189 }, -- Enfeeble
        { spell = 434765, type = "debuff", unit = "target", herotalent = 117659 }, -- Reaper's Mark
        { spell = 443404, type = "debuff", unit = "target", herotalent = 117633 }, -- Wave of Souls
        { spell = 444633, type = "debuff", unit = "target" }, -- Undeath
        { spell = 458169, type = "debuff", unit = "target", talent = 96238 }, -- Hyperpyrexia
      },
      icon = 237522
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 3714, type = "ability", buff = true }, -- Path of Frost
        { spell = 43265, type = "ability", charges = true }, -- Death and Decay
        { spell = 45524, type = "ability", debuff = true, overlayGlow = true, requiresTarget = true }, -- Chains of Ice
        { spell = 46585, type = "ability", totem = true, talent = 96201 }, -- Raise Dead
        { spell = 47528, type = "ability", requiresTarget = true, talent = 96213 }, -- Mind Freeze
        { spell = 47541, type = "ability", requiresTarget = true }, -- Death Coil
        { spell = 47568, type = "ability", buff = true, talent = 96240 }, -- Empower Rune Weapon
        { spell = 48265, type = "ability", charges = true, buff = true }, -- Death's Advance
        { spell = 48707, type = "ability", buff = true }, -- Anti-Magic Shell
        { spell = 48743, type = "ability", talent = 96204 }, -- Death Pact
        { spell = 48792, type = "ability", buff = true, talent = 96210 }, -- Icebound Fortitude
        { spell = 49020, type = "ability", overlayGlow = true, requiresTarget = true, talent = 96246 }, -- Obliterate
        { spell = 49039, type = "ability", buff = true }, -- Lichborne
        { spell = 49143, type = "ability", requiresTarget = true, talent = 96245 }, -- Frost Strike
        { spell = 49184, type = "ability", overlayGlow = true, requiresTarget = true, talent = 96244 }, -- Howling Blast
        { spell = 49576, type = "ability", charges = true, requiresTarget = true }, -- Death Grip
        { spell = 49998, type = "ability", requiresTarget = true, talent = 96200 }, -- Death Strike
        { spell = 50977, type = "ability", usable = true }, -- Death Gate
        { spell = 51052, type = "ability", talent = 96194 }, -- Anti-Magic Zone
        { spell = 51271, type = "ability", buff = true, talent = 125874 }, -- Pillar of Frost
        { spell = 56222, type = "ability", requiresTarget = true }, -- Dark Command
        { spell = 57330, type = "ability", talent = 96218 }, -- Horn of Winter
        { spell = 61999, type = "ability" }, -- Raise Ally
        { spell = 152279, type = "ability", buff = true, talent = 96222 }, -- Breath of Sindragosa
        { spell = 196770, type = "ability", buff = true }, -- Remorseless Winter
        { spell = 207167, type = "ability", talent = 96172 }, -- Blinding Sleet
        { spell = 207230, type = "ability", talent = 96225 }, -- Frostscythe
        { spell = 212552, type = "ability", buff = true, talent = 96206 }, -- Wraith Walk
        { spell = 221562, type = "ability", requiresTarget = true, talent = 96193 }, -- Asphyxiate
        { spell = 279302, type = "ability", talent = 125876 }, -- Frostwyrm's Fury
        { spell = 305392, type = "ability", requiresTarget = true, talent = 96228 }, -- Chill Streak
        { spell = 327574, type = "ability", talent = 125608 }, -- Sacrificial Pact
        { spell = 343294, type = "ability", debuff = true, requiresTarget = true, talent = 96192 }, -- Soul Reaper
        { spell = 383269, type = "ability", buff = true, talent = 96177 }, -- Abomination Limb
        { spell = 439843, type = "ability", requiresTarget = true, herotalent = 117659 }, -- Reaper's Mark
      },
      icon = 135372
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
        { spell = 48265, type = "buff", unit = "player" }, -- Death's Advance
        { spell = 48707, type = "buff", unit = "player" }, -- Anti-Magic Shell
        { spell = 48792, type = "buff", unit = "player", talent = 96210 }, -- Icebound Fortitude
        { spell = 49039, type = "buff", unit = "player" }, -- Lichborne
        { spell = 51460, type = "buff", unit = "player" }, -- Runic Corruption
        { spell = 81340, type = "buff", unit = "player", talent = 96328 }, -- Sudden Doom
        { spell = 145629, type = "buff", unit = "player", talent = 96194 }, -- Anti-Magic Zone
        { spell = 188290, type = "buff", unit = "player" }, -- Death and Decay
        { spell = 194879, type = "buff", unit = "player", talent = 96214 }, -- Icy Talons
        { spell = 207203, type = "buff", unit = "player" }, -- Frost Shield
        { spell = 207289, type = "buff", unit = "player", talent = 96285 }, -- Unholy Assault
        { spell = 212552, type = "buff", unit = "player", talent = 96206 }, -- Wraith Walk
        { spell = 374271, type = "buff", unit = "player", talent = 96198 }, -- Unholy Ground
        { spell = 374585, type = "buff", unit = "player", talent = 96208 }, -- Rune Mastery
        { spell = 377588, type = "buff", unit = "player", talent = 96331 }, -- Ghoulish Frenzy
        { spell = 377591, type = "buff", unit = "player", talent = 96286 }, -- Festermight
        { spell = 383269, type = "buff", unit = "player", talent = 96177 }, -- Abomination Limb
        { spell = 390178, type = "buff", unit = "player", talent = 96319 }, -- Plaguebringer
        { spell = 390260, type = "buff", unit = "player", talent = 96283 }, -- Commander of the Dead
        { spell = 433925, type = "buff", unit = "player" }, -- Essence of the Blood Queen
        { spell = 434034, type = "buff", unit = "player", herotalent = 117645 }, -- Blood-Soaked Ground
        { spell = 434105, type = "buff", unit = "player", herotalent = 117653 }, -- Vampiric Aura
        { spell = 434159, type = "buff", unit = "player", herotalent = 117642 }, -- Visceral Strength
        { spell = 440861, type = "buff", unit = "player", herotalent = 123411 }, -- A Feast of Souls
        { spell = 444347, type = "buff", unit = "player", herotalent = 123412 }, -- Death Charge
        { spell = 444505, type = "buff", unit = "player", herotalent = 117664 }, -- Mograine's Might
        { spell = 444763, type = "buff", unit = "player" }, -- Apocalyptic Conquest
        { spell = 453773, type = "buff", unit = "player", herotalent = 123410 }, -- Pact of the Apocalypse
        { spell = 459238, type = "buff", unit = "player", talent = 96330 }, -- Festering Scythe
        { spell = 63560, type = "buff", unit = "pet", talent = 96324 }, -- Dark Transformation
      },
      icon = 136181
    },
    [2] = {
      title = L["Debuffs"],
      args = {
        { spell = 45524, type = "debuff", unit = "target" }, -- Chains of Ice
        { spell = 55078, type = "debuff", unit = "target" }, -- Blood Plague
        { spell = 55095, type = "debuff", unit = "target" }, -- Frost Fever
        { spell = 115994, type = "debuff", unit = "target", talent = 96297 }, -- Unholy Blight
        { spell = 191587, type = "debuff", unit = "target" }, -- Virulent Plague
        { spell = 194310, type = "debuff", unit = "target" }, -- Festering Wound
        { spell = 343294, type = "debuff", unit = "target", talent = 96192 }, -- Soul Reaper
        { spell = 374557, type = "debuff", unit = "target", talent = 96190 }, -- Brittle
        { spell = 377445, type = "debuff", unit = "target", talent = 96284 }, -- Unholy Aura
        { spell = 377540, type = "debuff", unit = "target", talent = 96292 }, -- Death Rot
        { spell = 390271, type = "debuff", unit = "target", talent = 96290 }, -- Coil of Devastation
        { spell = 390276, type = "debuff", unit = "target", talent = 96310 }, -- Rotten Touch
        { spell = 391568, type = "debuff", unit = "target", talent = 96179 }, -- Insidious Chill
        { spell = 392490, type = "debuff", unit = "target", talent = 96189 }, -- Enfeeble
        { spell = 444633, type = "debuff", unit = "target" }, -- Undeath
        { spell = 454824, type = "debuff", unit = "target", talent = 96209 }, -- Subduing Grasp
        { spell = 458478, type = "debuff", unit = "target", herotalent = 117637 }, -- Incite Terror
      },
      icon = 1129420
    },
    [3] = {
      title = L["Cooldowns"],
      args = {
        { spell = 43265, type = "ability", charges = true }, -- Death and Decay
        { spell = 45524, type = "ability", debuff = true, requiresTarget = true }, -- Chains of Ice
        { spell = 46584, type = "ability", talent = 96325 }, -- Raise Dead
        { spell = 47468, type = "ability", requiresTarget = true }, -- Claw
        { spell = 47481, type = "ability", requiresTarget = true }, -- Gnaw
        { spell = 47484, type = "ability" }, -- Huddle
        { spell = 47528, type = "ability", requiresTarget = true, talent = 96213 }, -- Mind Freeze
        { spell = 47541, type = "ability", overlayGlow = true, requiresTarget = true }, -- Death Coil
        { spell = 48265, type = "ability", charges = true, buff = true }, -- Death's Advance
        { spell = 48707, type = "ability", buff = true }, -- Anti-Magic Shell
        { spell = 48743, type = "ability", talent = 96204 }, -- Death Pact
        { spell = 48792, type = "ability", buff = true, talent = 96210 }, -- Icebound Fortitude
        { spell = 49039, type = "ability", buff = true }, -- Lichborne
        { spell = 49206, type = "ability", requiresTarget = true, totem = true, talent = 96311 }, -- Summon Gargoyle
        { spell = 49576, type = "ability", charges = true, requiresTarget = true }, -- Death Grip
        { spell = 49998, type = "ability", requiresTarget = true, talent = 96200 }, -- Death Strike
        { spell = 50977, type = "ability", usable = true }, -- Death Gate
        { spell = 51052, type = "ability", talent = 96194 }, -- Anti-Magic Zone
        { spell = 55090, type = "ability", requiresTarget = true, talent = 96327 }, -- Scourge Strike
        { spell = 56222, type = "ability", requiresTarget = true }, -- Dark Command
        { spell = 61999, type = "ability" }, -- Raise Ally
        { spell = 63560, type = "ability", buff = true, unit = 'pet', talent = 96324 }, -- Dark Transformation
        { spell = 77575, type = "ability", requiresTarget = true }, -- Outbreak
        { spell = 85948, type = "ability", requiresTarget = true, talent = 96326 }, -- Festering Strike
        { spell = 152280, type = "ability", charges = true, talent = 96315 }, -- Defile
        { spell = 207167, type = "ability", talent = 96172 }, -- Blinding Sleet
        { spell = 207289, type = "ability", buff = true, requiresTarget = true, talent = 96285 }, -- Unholy Assault
        { spell = 207311, type = "ability", requiresTarget = true, talent = 96320 }, -- Clawing Shadows
        { spell = 212552, type = "ability", buff = true, usable = true, talent = 96206 }, -- Wraith Walk
        { spell = 221562, type = "ability", requiresTarget = true, talent = 96193 }, -- Asphyxiate
        { spell = 275699, type = "ability", requiresTarget = true, usable = true, talent = 96322 }, -- Apocalypse
        { spell = 327574, type = "ability", talent = 125608 }, -- Sacrificial Pact
        { spell = 343294, type = "ability", debuff = true, requiresTarget = true, talent = 96192 }, -- Soul Reaper
        { spell = 383269, type = "ability", buff = true, talent = 96177 }, -- Abomination Limb
        { spell = 390279, type = "ability", requiresTarget = true, talent = 96293 }, -- Vile Contagion
        { spell = 444347, type = "ability", charges = true, buff = true, herotalent = 123412 }, -- Death Charge
        { spell = 455395, type = "ability", totem = true, talent = 96287 }, -- Raise Abomination
      },
      icon = 136144
    },
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
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
  spellIds = {2825, 32182, 80353, 264667, 390386, 178207, 230935, 256740, 309658}}
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

for i = 1, 4 do
  local ids = i == 1 and {5487, 768, 783, 24858, 114282, 210053} or {5487, 768, 783, 114282, 210053}
  for j, id in ipairs(ids) do
    local title, _, icon = GetSpellInfo(id)
    if title then
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
      })
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
-- Tail Swipe
tinsert(templates.race.Dracthyr, { spell = 368970, type = "ability" })
-- Wing Buffet
tinsert(templates.race.Dracthyr, { spell = 357214, type = "ability" })
-- Soar
tinsert(templates.race.Dracthyr, { spell = 369536, type = "ability" })
 -- Azerite Surge)
tinsert(templates.race.EarthenDwarf, { spell = 436344, type = "ability" })
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
              local icon = GetSpellIcon(item.spell)
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

