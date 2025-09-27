--[[
Name: LibRangeCheck-3.0
Author(s): mitch0, WoWUIDev Community
Website: https://www.curseforge.com/wow/addons/librangecheck-3-0
Description: A range checking library based on interact distances and spell ranges
Dependencies: LibStub
License: MIT
]]

--- LibRangeCheck-3.0 provides an easy way to check for ranges and get suitable range checking functions for specific ranges.\\
-- The checkers use spell and item range checks, or interact based checks for special units where those two cannot be used.\\
-- The lib handles the refreshing of checker lists in case talents / spells change and in some special cases when equipment changes (for example some of the mage pvp gloves change the range of the Fire Blast spell), and also handles the caching of items used for item-based range checks.\\
-- A callback is provided for those interested in checker changes.
-- @usage
-- local rc = LibStub("LibRangeCheck-3.0")
--
-- rc.RegisterCallback(self, rc.CHECKERS_CHANGED, function() print("need to refresh my stored checkers") end)
--
-- local minRange, maxRange = rc:GetRange('target')
-- if not minRange then
--     print("cannot get range estimate for target")
-- elseif not maxRange then
--     print("target is over " .. minRange .. " yards")
-- else
--     print("target is between " .. minRange .. " and " .. maxRange .. " yards")
-- end
--
-- local meleeChecker = rc:GetFriendMaxChecker(rc.MeleeRange) or rc:GetFriendMinChecker(rc.MeleeRange) -- use the closest checker (MinChecker) if no valid Melee checker is found
-- for i = 1, 4 do
--     -- TODO: check if unit is valid, etc
--     if meleeChecker("party" .. i) then
--         print("Party member " .. i .. " is in Melee range")
--     end
-- end
--
-- local safeDistanceChecker = rc:GetHarmMinChecker(30)
-- -- negate the result of the checker!
-- local isSafelyAway = not safeDistanceChecker('target')
--
-- @class file
-- @name LibRangeCheck-3.0
local MAJOR_VERSION = "LibRangeCheck-3.0"
local MINOR_VERSION = 28

---@class lib
local lib, oldminor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then
  return
end

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

local InCombatLockdownRestriction = function(unit) return InCombatLockdown() and not UnitCanAttack("player", unit) end

local _G = _G
local next = next
local sort = sort
local type = type
local wipe = wipe
local print = print
local pairs = pairs
local ipairs = ipairs
local tinsert = tinsert
local tremove = tremove
local tostring = tostring
local setmetatable = setmetatable
local BOOKTYPE_SPELL = BOOKTYPE_SPELL or Enum.SpellBookSpellBank.Player
local GetSpellBookItemName = GetSpellBookItemName or C_SpellBook.GetSpellBookItemName
local C_Item = C_Item
local UnitCanAttack = UnitCanAttack
local UnitCanAssist = UnitCanAssist
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitGUID = UnitGUID
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local CheckInteractDistance = CheckInteractDistance
local IsSpellBookItemInRange = _G.IsSpellInRange or function(index, spellBank, unit)
  local result = C_Spell.IsSpellInRange(index, unit)
  if result == true then
    return 1
  elseif result == false then
    return 0
  end
  return nil
end
local spellTypes = {"SPELL", "FUTURESPELL", "PETACTION", "FLYOUT"}
local GetSpellBookItemInfo = _G.GetSpellBookItemInfo or function(index, spellBank)
  if type(spellBank) == "string" then
    spellBank = (spellBank == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.Pet;
  end
  local info = C_SpellBook.GetSpellBookItemInfo(index, spellBank)
  --map spell-type
  if info and spellTypes[info.itemType or 0] then
    return spellTypes[info.itemType or 0] or "None", info.spellID, info
  end
end
local UnitClass = UnitClass
local UnitRace = UnitRace
local GetInventoryItemLink = GetInventoryItemLink
local GetTime = GetTime
local HandSlotId = GetInventorySlotInfo("HANDSSLOT")
local math_floor = math.floor
local UnitIsVisible = UnitIsVisible

local GetSpellInfo = GetSpellInfo or function(spellID)
  if not spellID then
    return nil;
  end

  local spellInfo = C_Spell.GetSpellInfo(spellID);
  if spellInfo then
    return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID;
  end
end

local GetNumSpellTabs = GetNumSpellTabs or C_SpellBook.GetNumSpellBookSkillLines
local GetSpellTabInfo = GetSpellTabInfo or function(index)
  local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(index);
  if skillLineInfo then
    return skillLineInfo.name,
        skillLineInfo.iconID,
        skillLineInfo.itemIndexOffset,
        skillLineInfo.numSpellBookItems,
        skillLineInfo.isGuild,
        skillLineInfo.offSpecID,
        skillLineInfo.shouldHide,
        skillLineInfo.specID;
  end
end

-- << STATIC CONFIG

local UpdateDelay = 0.5
local ItemRequestTimeout = 10.0

-- interact distance based checks. ranges are based on my own measurements (thanks for all the folks who helped me with this)
local DefaultInteractList = {
  --  [1] = 28, -- Compare Achievements
  --  [2] = 9,  -- Trade
  [3] = 8, -- Duel
  [4] = 28, -- Follow
  --  [5] = 7,  -- unknown
}

-- interact list overrides for races
local InteractLists = {
  Tauren = {
    --  [2] = 7,
    [3] = 6,
    [4] = 25,
  },
  Scourge = {
    --  [2] = 8,
    [3] = 7,
    [4] = 27,
  },
}

local MeleeRange = 2
local FriendSpells, HarmSpells, ResSpells, PetSpells = {}, {}, {}, {}

for _, n in ipairs({ "EVOKER", "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "HUNTER", "SHAMAN", "MAGE", "PALADIN", "PRIEST", "WARLOCK", "WARRIOR", "MONK", "ROGUE" }) do
  FriendSpells[n], HarmSpells[n], ResSpells[n], PetSpells[n] = {}, {}, {}, {}
end

-- Evoker
tinsert(HarmSpells.EVOKER, 362969) -- Azure Strike (25 yards)

tinsert(FriendSpells.EVOKER, 355913) -- Emerald Blossom (25 yards)
tinsert(FriendSpells.EVOKER, 361469) -- Living Flame (25 yards)
tinsert(FriendSpells.EVOKER, 360823) -- Naturalize (Preservation) (30 yards)

tinsert(ResSpells.EVOKER, 361227) -- Return (40 yards)

-- Death Knights
tinsert(HarmSpells.DEATHKNIGHT, 49576) -- Death Grip (30 yards)
tinsert(HarmSpells.DEATHKNIGHT, 47541) -- Death Coil (Unholy) (40 yards)

tinsert(ResSpells.DEATHKNIGHT, 61999) -- Raise Ally (40 yards)

-- Demon Hunters
tinsert(HarmSpells.DEMONHUNTER, 185123) -- Throw Glaive (Havoc) (30 yards)
tinsert(HarmSpells.DEMONHUNTER, 183752) -- Consume Magic (20 yards)
tinsert(HarmSpells.DEMONHUNTER, 204021) -- Fiery Brand (Vengeance) (30 yards)

-- Druids
tinsert(FriendSpells.DRUID, 8936) -- Regrowth (40 yards, level 3)
tinsert(FriendSpells.DRUID, 774) -- Rejuvenation (Restoration) (40 yards, level 10)
tinsert(FriendSpells.DRUID, 2782) -- Remove Corruption (Restoration) (40 yards, level 19)
tinsert(FriendSpells.DRUID, 88423) -- Natures Cure (Restoration) (40 yards, level 19)

if not isRetail then
  tinsert(FriendSpells.DRUID, 5185) -- Healing Touch (40 yards, level 1, rank 1)
end

tinsert(HarmSpells.DRUID, 5176) -- Wrath (40 yards)
tinsert(HarmSpells.DRUID, 339) -- Entangling Roots (35 yards)
tinsert(HarmSpells.DRUID, 6795) -- Growl (30 yards)
tinsert(HarmSpells.DRUID, 33786) -- Cyclone (20 yards)
tinsert(HarmSpells.DRUID, 22568) -- Ferocious Bite (Melee Range)
tinsert(HarmSpells.DRUID, 8921) -- Moonfire (40 yards, level 2)

tinsert(ResSpells.DRUID, 50769) -- Revive (40 yards, level 14)
tinsert(ResSpells.DRUID, 20484) -- Rebirth (40 yards, level 29)

-- Hunters
tinsert(HarmSpells.HUNTER, 466930) -- Black Arrow (40 yards)
tinsert(HarmSpells.HUNTER, 75) -- Auto Shot (40 yards)

if not isRetail then
  tinsert(HarmSpells.HUNTER, 2764) -- Throw (30 yards, level 1)
end

tinsert(PetSpells.HUNTER, 136) -- Mend Pet (45 yards)

-- Mages
tinsert(FriendSpells.MAGE, 1459) -- Arcane Intellect (40 yards, level 8)
tinsert(FriendSpells.MAGE, 475) -- Remove Curse (40 yards, level 28)

if not isRetail then
  tinsert(FriendSpells.MAGE, 130) -- Slow Fall (40 yards, level 12)
end

tinsert(HarmSpells.MAGE, 44614) -- Flurry (40 yards)
tinsert(HarmSpells.MAGE, 5019) -- Shoot (30 yards)
tinsert(HarmSpells.MAGE, 118) -- Polymorph (30 yards)
tinsert(HarmSpells.MAGE, 116) -- Frostbolt (40 yards)
tinsert(HarmSpells.MAGE, 133) -- Fireball (40 yards)
tinsert(HarmSpells.MAGE, 44425) -- Arcane Barrage (40 yards)

-- Monks
tinsert(FriendSpells.MONK, 115450) -- Detox (40 yards)
tinsert(FriendSpells.MONK, 115546) -- Provoke (30 yards)
tinsert(FriendSpells.MONK, 116670) -- Vivify (40 yards)

tinsert(HarmSpells.MONK, 115546) -- Provoke (30 yards)
tinsert(HarmSpells.MONK, 115078) -- Paralysis (20 yards)
tinsert(HarmSpells.MONK, 100780) -- Tiger Palm (Melee Range)
tinsert(HarmSpells.MONK, 117952) -- Crackling Jade Lightning (40 yards)

tinsert(ResSpells.MONK, 115178) -- Resuscitate (40 yards, level 13)

-- Paladins
tinsert(FriendSpells.PALADIN, 19750) -- Flash of Light (40 yards, level 4)
tinsert(FriendSpells.PALADIN, 85673) -- Word of Glory (40 yards, level 7)
tinsert(FriendSpells.PALADIN, 4987) -- Cleanse (Holy) (40 yards, level 12)
tinsert(FriendSpells.PALADIN, 213644) -- Cleanse Toxins (Protection, Retribution) (40 yards, level 12)

if not isRetail then
  tinsert(FriendSpells.PALADIN, 635) -- Holy Light (40 yards, level 1, rank 1)
end

tinsert(HarmSpells.PALADIN, 853) -- Hammer of Justice (10 yards)
tinsert(HarmSpells.PALADIN, 35395) -- Crusader Strike (Melee Range)
tinsert(HarmSpells.PALADIN, 62124) -- Hand of Reckoning (30 yards)
tinsert(HarmSpells.PALADIN, 183218) -- Hand of Hindrance (30 yards)
tinsert(HarmSpells.PALADIN, 20271) -- Judgement (30 yards)
tinsert(HarmSpells.PALADIN, 20473) -- Holy Shock (40 yards)

tinsert(ResSpells.PALADIN, 7328) -- Redemption (40 yards)

-- Priests
if isRetail then
  tinsert(FriendSpells.PRIEST, 21562) -- Power Word: Fortitude (40 yards, level 6) [use first to fix Kyrian boon/fae soulshape]
  tinsert(FriendSpells.PRIEST, 17) -- Power Word: Shield (40 yards, level 4)
else -- PWS is group only in classic, use lesser heal as main spell check
  tinsert(FriendSpells.PRIEST, 2050) -- Lesser Heal (40 yards, level 1, rank 1)
end

tinsert(FriendSpells.PRIEST, 527) -- Purify / Dispel Magic (40 yards retail, 30 yards tbc, level 18, rank 1)
tinsert(FriendSpells.PRIEST, 2061) -- Flash Heal (40 yards, level 3 retail, level 20 tbc)

tinsert(HarmSpells.PRIEST, 589) -- Shadow Word: Pain (40 yards)
if isEra then
  tinsert(HarmSpells.PRIEST, 18807) -- Mind Flay (20-24 yards)
end
tinsert(HarmSpells.PRIEST, 8092) -- Mind Blast (40 yards)
tinsert(HarmSpells.PRIEST, 585) -- Smite (40 yards)
tinsert(HarmSpells.PRIEST, 5019) -- Shoot (30 yards)

if not isRetail then
  tinsert(HarmSpells.PRIEST, 8092) -- Mindblast (30 yards, level 10)
end

tinsert(ResSpells.PRIEST, 2006) -- Resurrection (40 yards, level 10)

-- Rogues
if isRetail then
  tinsert(FriendSpells.ROGUE, 36554) -- Shadowstep (Assassination, Subtlety) (25 yards, level 18) -- works on friendly in retail
  tinsert(FriendSpells.ROGUE, 921) -- Pick Pocket (10 yards, level 24) -- this works for range, keep it in friendly as well for retail but on classic this is melee range and will return min 0 range 0
else
  tinsert(HarmSpells.ROGUE, 2764) -- Throw (30 yards)
end

tinsert(HarmSpells.ROGUE, 185565) -- Poisoned Knife (Assassination) (30 yards, level 29)
tinsert(HarmSpells.ROGUE, 36554) -- Shadowstep (Assassination, Subtlety) (25 yards, level 18)
tinsert(HarmSpells.ROGUE, 185763) -- Pistol Shot (Outlaw) (20 yards)
tinsert(HarmSpells.ROGUE, 2094) -- Blind (15 yards)
tinsert(HarmSpells.ROGUE, 921) -- Pick Pocket (10 yards, level 24)

-- Shamans
tinsert(FriendSpells.SHAMAN, 546) -- Water Walking (30 yards)
tinsert(FriendSpells.SHAMAN, 8004) -- Healing Surge (Resto, Elemental) (40 yards)
tinsert(FriendSpells.SHAMAN, 188070) -- Healing Surge (Enhancement) (40 yards)

if not isRetail then
  tinsert(FriendSpells.SHAMAN, 331) -- Healing Wave (40 yards, level 1, rank 1)
  tinsert(FriendSpells.SHAMAN, 526) -- Cure Poison (40 yards, level 16)
  tinsert(FriendSpells.SHAMAN, 2870) -- Cure Disease (40 yards, level 22)
end

tinsert(HarmSpells.SHAMAN, 370) -- Purge (30 yards)
tinsert(HarmSpells.SHAMAN, 8042) -- Earth Shock (40 yards)
tinsert(HarmSpells.SHAMAN, 117014) -- Elemental Blast (40 yards)
tinsert(HarmSpells.SHAMAN, 188196) -- Lightning Bolt (40 yards)
tinsert(HarmSpells.SHAMAN, 73899) -- Primal Strike (Melee Range)

if not isRetail then
  tinsert(HarmSpells.SHAMAN, 403) -- Lightning Bolt (30 yards, level 1, rank 1)
  tinsert(HarmSpells.SHAMAN, 8042) -- Earth Shock (20 yards, level 4, rank 1)
end

tinsert(ResSpells.SHAMAN, 2008) -- Ancestral Spirit (40 yards, level 13)

-- Warriors
tinsert(HarmSpells.WARRIOR, 355) -- Taunt (30 yards)
tinsert(HarmSpells.WARRIOR, 5246) -- Intimidating Shout (Arms, Fury) (8 yards)
tinsert(HarmSpells.WARRIOR, 100) -- Charge (Arms, Fury) (8-25 yards)

if not isRetail then
  tinsert(HarmSpells.WARRIOR, 2764) -- Throw (30 yards, level 1, 5-30 range)
end

-- Warlocks
if isEra then
  tinsert(FriendSpells.WARLOCK, 132) -- Detect Invisibility (30 yards, level 26)
else
  tinsert(FriendSpells.WARLOCK, 20707) -- Soulstone (40 yards) ~ this can be precasted so leave it in friendly as well as res
end
tinsert(FriendSpells.WARLOCK, 5697) -- Unending Breath (30 yards)

if isRetail then
  tinsert(HarmSpells.WARLOCK, 234153) -- Drain Life (40 yards, level 9)
  tinsert(HarmSpells.WARLOCK, 198590) -- Drain Soul (40 yards, level 15)
  tinsert(HarmSpells.WARLOCK, 232670) -- Shadow Bolt (40 yards)
else
  tinsert(HarmSpells.WARLOCK, 172) -- Corruption (30/33/36 yards, level 4, rank 1)
  tinsert(HarmSpells.WARLOCK, 348) -- Immolate (30/33/36 yards, level 1, rank 1)
  tinsert(HarmSpells.WARLOCK, 17877) -- Shadowburn (Destruction) (20/22/24 yards, rank 1)
  tinsert(HarmSpells.WARLOCK, 18223) -- Curse of Exhaustion (Affliction) (30/33/36/35/38/42 yards)
  tinsert(HarmSpells.WARLOCK, 689) -- Drain Life (Affliction) (20/22/24 yards, level 14, rank 1)
end
if isEra then
  tinsert(HarmSpells.WARLOCK, 403677) -- Master Channeler (Affliction) (20/22/24 yards, level 14, rank 1)
  tinsert(HarmSpells.WARLOCK, 426320) -- Shadowflame (30/33/36/39/42 yards, level 14, rank 1)
end

tinsert(HarmSpells.WARLOCK, 5019) -- Shoot (30 yards)
tinsert(HarmSpells.WARLOCK, 686) -- Shadow Bolt (Demonology, Affliction) (40 yards)
tinsert(HarmSpells.WARLOCK, 5782) -- Fear (30 yards)

if not isEra then
  tinsert(ResSpells.WARLOCK, 20707) -- Soulstone (40 yards)
end

tinsert(PetSpells.WARLOCK, 755) -- Health Funnel (45 yards)

-- Items

local FriendItems
if isEra then
  FriendItems = {
    [5] = {
      1970,   -- Restoring Balm
      8149,   -- Voodoo Charm
      15826,  -- Curative Animal Salve
      16308,  -- Northridge Crowbar
      16991,  -- Triage Bandage
      17117,  -- Rat Catcher's Flute
      20403,  -- Proxy of Nozdormu
      22259,  -- Unbestowed Friendship Bracelet
      208855, -- Rainbow Fin Albacore Chum
      209027, -- Crab Treats
      209057, -- Prototype Engine
      213036, -- Water of Elune'ara
      221199, -- Satyrweed Tincture
      225943, -- Rancid Hunk of Flesh
    },
    [10] = {
      17626,  -- Frostwolf Muzzle
      17689,  -- Stormpike Training Collar
      21267,  -- Toasting Goblet
      23164,  -- Bubbly Beverage
      226207, -- Echo of Anastari
      226208, -- Echo of Barthilas
      226209, -- Echo of Dathrohan
      226210, -- Echo of Maleki
      226211, -- Echo of Nerub'enkan
      226212, -- Echo of Ramstein
      226213, -- Echo of Rivendare
      226214, -- Echo of Willey
    },
    [15] = {
      1251,   -- Linen Bandage
      2581,   -- Heavy Linen Bandage
      3530,   -- Wool Bandage
      3531,   -- Heavy Wool Bandage
      6450,   -- Silk Bandage
      6451,   -- Heavy Silk Bandage
      8544,   -- Mageweave Bandage
      8545,   -- Heavy Mageweave Bandage
      14529,  -- Runecloth Bandage
      14530,  -- Heavy Runecloth Bandage
      19066,  -- Warsong Gulch Runecloth Bandage
      19067,  -- Warsong Gulch Mageweave Bandage
      19068,  -- Warsong Gulch Silk Bandage
      19307,  -- Alterac Heavy Runecloth Bandage
      20065,  -- Arathi Basin Mageweave Bandage
      20066,  -- Arathi Basin Runecloth Bandage
      20067,  -- Arathi Basin Silk Bandage
      20232,  -- Defiler's Mageweave Bandage
      20234,  -- Defiler's Runecloth Bandage
      20235,  -- Defiler's Silk Bandage
      20237,  -- Highlander's Mageweave Bandage
      20243,  -- Highlander's Runecloth Bandage
      20244,  -- Highlander's Silk Bandage
      23684,  -- Crystal Infused Bandage
      232433, -- Dense Runecloth Bandage
    },
    [20] = {
      12450,  -- Juju Flurry
      12451,  -- Juju Power
      12455,  -- Juju Ember
      12457,  -- Juju Chill
      12458,  -- Juju Guile
      12460,  -- Juju Might
      17757,  -- Amulet of Spirits
      21519,  -- Mistletoe
      219963, -- Deputization Authorization: Duskwood Mission I
      219965, -- Deputization Authorization: Duskwood Mission II
      219983, -- Deputization Authorization: Duskwood Mission III
      219984, -- Deputization Authorization: Duskwood Mission IV
      219985, -- Deputization Authorization: Duskwood Mission V
      219986, -- Deputization Authorization: Duskwood Mission VI
      219987, -- Deputization Authorization: Duskwood Mission VII
      219988, -- Deputization Authorization: Duskwood Mission VIII
      219989, -- Deputization Authorization: Duskwood Mission IX
      219990, -- Deputization Authorization: Duskwood Mission X
      219991, -- Deputization Authorization: Duskwood Mission XI
      219992, -- Deputization Authorization: Duskwood Mission XII
      219993, -- Deputization Authorization: Duskwood Mission XIII
      219994, -- Deputization Authorization: Duskwood Mission XIV
      219995, -- Deputization Authorization: Duskwood Mission XV
      219996, -- Deputization Authorization: Duskwood Mission XVI
      219997, -- Deputization Authorization: Duskwood Mission XVII
      219998, -- Deputization Authorization: Duskwood Mission XVIII
      220053, -- Deputization Authorization: Ashenvale Mission I
      220054, -- Deputization Authorization: Ashenvale Mission II
      220055, -- Deputization Authorization: Ashenvale Mission III
      220056, -- Deputization Authorization: Ashenvale Mission IV
      220057, -- Deputization Authorization: Ashenvale Mission V
      220058, -- Deputization Authorization: Ashenvale Mission VI
      220059, -- Deputization Authorization: Ashenvale Mission VII
      220060, -- Deputization Authorization: Ashenvale Mission VIII
      220061, -- Deputization Authorization: Ashenvale Mission IX
      220062, -- Deputization Authorization: Ashenvale Mission X
      220063, -- Deputization Authorization: Ashenvale Mission XI
      220064, -- Deputization Authorization: Ashenvale Mission XII
      220065, -- Deputization Authorization: Ashenvale Mission XIII
      220066, -- Deputization Authorization: Ashenvale Mission XIV
      220067, -- Deputization Authorization: Ashenvale Mission XV
      220068, -- Deputization Authorization: Ashenvale Mission XVI
      220069, -- Deputization Authorization: Ashenvale Mission XVII
      220070, -- Deputization Authorization: Ashenvale Mission XVIII
      220071, -- Deputization Authorization: Hinterlands Mission I
      220072, -- Deputization Authorization: Hinterlands Mission II
      220073, -- Deputization Authorization: Hinterlands Mission III
      220074, -- Deputization Authorization: Hinterlands Mission IV
      220075, -- Deputization Authorization: Hinterlands Mission V
      220076, -- Deputization Authorization: Hinterlands Mission VI
      220077, -- Deputization Authorization: Hinterlands Mission VII
      220078, -- Deputization Authorization: Hinterlands Mission VIII
      220079, -- Deputization Authorization: Hinterlands Mission IX
      220080, -- Deputization Authorization: Hinterlands Mission X
      220081, -- Deputization Authorization: Hinterlands Mission XI
      220082, -- Deputization Authorization: Hinterlands Mission XII
      220083, -- Deputization Authorization: Hinterlands Mission XIII
      220084, -- Deputization Authorization: Hinterlands Mission XIV
      220085, -- Deputization Authorization: Hinterlands Mission XV
      220086, -- Deputization Authorization: Hinterlands Mission XVI
      220087, -- Deputization Authorization: Hinterlands Mission XVII
      220088, -- Deputization Authorization: Hinterlands Mission XVIII
      220089, -- Deputization Authorization: Feralas Mission I
      220090, -- Deputization Authorization: Feralas Mission II
      220091, -- Deputization Authorization: Feralas Mission III
      220092, -- Deputization Authorization: Feralas Mission IV
      220093, -- Deputization Authorization: Feralas Mission V
      220094, -- Deputization Authorization: Feralas Mission VI
      220095, -- Deputization Authorization: Feralas Mission VII
      220096, -- Deputization Authorization: Feralas Mission VIII
      220097, -- Deputization Authorization: Feralas Mission IX
      220098, -- Deputization Authorization: Feralas Mission X
      220099, -- Deputization Authorization: Feralas Mission XI
      220100, -- Deputization Authorization: Feralas Mission XII
      220101, -- Deputization Authorization: Feralas Mission XIII
      220102, -- Deputization Authorization: Feralas Mission XIV
      220103, -- Deputization Authorization: Feralas Mission XV
      220104, -- Deputization Authorization: Feralas Mission XVI
      220105, -- Deputization Authorization: Feralas Mission XVII
      220106, -- Deputization Authorization: Feralas Mission XVIII
      220792, -- Scroll of Spatial Mending
      223168, -- Worldcore Fragment
      223171, -- Scroll of Geomancy
      224806, -- Legion Portal Tuner
      224893, -- Overcharged Portal Tuner
      231298, -- Scroll of Lesser Spatial Mending
      231836, -- Glowing Scroll of Spatial Mending
      232344, -- Vick's VIP Pass
    },
    [25] = {
      13289,  -- Egan's Blaster
    },
    [30] = {
      954,    -- Scroll of Strength
      955,    -- Scroll of Intellect
      1180,   -- Scroll of Stamina
      1181,   -- Scroll of Spirit
      1477,   -- Scroll of Agility II
      1478,   -- Scroll of Protection II
      1711,   -- Scroll of Stamina II
      1712,   -- Scroll of Spirit II
      1851,   -- Cleansing Water
      1912,   -- Deprecated Reed Pipe
      2289,   -- Scroll of Strength II
      2290,   -- Scroll of Intellect II
      2948,   -- Deprecated Talisman of Cleansing
      3012,   -- Scroll of Agility
      3013,   -- Scroll of Protection
      4381,   -- Minor Recombobulator
      4419,   -- Scroll of Intellect III
      4421,   -- Scroll of Protection III
      4422,   -- Scroll of Stamina III
      4424,   -- Scroll of Spirit III
      4425,   -- Scroll of Agility III
      4426,   -- Scroll of Strength III
      4444,   -- Black Husk Shield
      5232,   -- Minor Soulstone
      5613,   -- Staff of the Purifier
      6452,   -- Anti-Venom
      6453,   -- Strong Anti-Venom
      10305,  -- Scroll of Protection IV
      10306,  -- Scroll of Spirit IV
      10307,  -- Scroll of Stamina IV
      10308,  -- Scroll of Intellect IV
      10309,  -- Scroll of Agility IV
      10310,  -- Scroll of Strength IV
      11563,  -- Crystal Force
      11564,  -- Crystal Ward
      11567,  -- Crystal Spire
      16892,  -- Lesser Soulstone
      16893,  -- Soulstone
      16895,  -- Greater Soulstone
      16896,  -- Major Soulstone
      17202,  -- Snowball
      17310,  -- Aspect of Neptulon
      18637,  -- Major Recombobulator
      19440,  -- Powerful Anti-Venom
      20908,  -- Festival of Nian Firework
      21038,  -- Hardpacked Snowball
      21713,  -- Elune's Candle
      22200,  -- Silver Shafted Arrow
      22206,  -- Bouquet of Red Roses
      22218,  -- Handful of Rose Petals
    },
    [35] = {
      18904,  -- Zorbin's Ultra-Shrinker
    },
    [40] = {
      1713,   -- Ankh of Life
      5205,   -- Sprouted Frond
      5323,   -- Everglow Lantern
      8346,   -- Gauntlets of the Sea
      11562,  -- Crystal Restore
      18640,  -- Happy Fun Rock
      18662,  -- Heavy Leather Ball
      213349, -- Gniodine Pill Bottle
      216500, -- Bloodbonded Grove Talisman
      216503, -- Bloodstorm Jewel
      216517, -- Sanguine Sanctuary
      216607, -- Bloodlight Offering
      230280, -- Aegis of Preservation
    },
    [45] = {
      221316, -- Premo's Poise-Demanding Uniform
    },
    [50] = {
      221315, -- Rainbow Generator
    },
    [100] = {
      5418,   -- Weapon of Mass Destruction (test)
      17162,  -- Eric Test Item A
      23715,  -- Permanent Lung Juice Cocktail
      23718,  -- Permanent Ground Scorpok Assay
      23719,  -- Permanent Cerebral Cortex Compound
      23721,  -- Permanent Gizzard Gum
      23722,  -- Permanent R.O.I.D.S.
      227685, -- Modified Shadow Scalpel
    },
    -- [50000] = {
    --   228227, -- Scroll of Overwhelming Power
    -- },
  }
elseif isCata then
  FriendItems = {
    [3] = {
      42732,  -- Everfrost Razor
    },
    [5] = {
      1970,   -- Restoring Balm
      8149,   -- Voodoo Charm
      15826,  -- Curative Animal Salve
      16991,  -- Triage Bandage
      17117,  -- Rat Catcher's Flute
      20403,  -- Proxy of Nozdormu
      22259,  -- Unbestowed Friendship Bracelet
      23485,  -- Empty Birdcage
      23659,  -- Fel-Tainted Morsels
      33310,  -- The Sergeant's Machete
      33342,  -- The Brave's Machete
      33563,  -- Forsaken Banner
      34954,  -- Torp's Kodo Snaffle
      34973,  -- Re-Cursive Transmatter Injection
      35116,  -- The Ultrasonic Screwdriver
      35401,  -- The Greatmother's Soulcatcher
      35736,  -- Bounty Hunter's Cage
      36771,  -- Sturdy Crates
      36786,  -- Bark of the Walkers
      36956,  -- Liquid Fire of Elune
      37187,  -- Container of Rats
      37202,  -- Onslaught Riding Crop
      37568,  -- Renewing Tourniquet
      37576,  -- Renewing Bandage
      38330,  -- Crusader's Bandage
      38467,  -- Softknuckle Poker
      38627,  -- Mammoth Harness
      38676,  -- Whisker of Har'koa
      38731,  -- Ahunae's Knife
      40587,  -- Darkmender's Tincture
      45001,  -- Medicated Salve
      45080,  -- Large Femur
      49743,  -- Sten's First Aid Kit
      49948,  -- Calder's Bonesaw
      50471,  -- The Heartbreaker
      50742,  -- Tara's Tar Scraper
      50746,  -- Tara's Tar Scraper
      52014,  -- Herb-Soaked Bandages
      52271,  -- Northwatch Manacles
      52712,  -- Remote Control Fireworks
      53120,  -- Bottled Bileberry Brew
      56837,  -- Sturdy Manacles
      58502,  -- Explosive Bonding Compound
      58885,  -- Rockslide Reagent
      58955,  -- Razgar's Fillet Knife
      58965,  -- Deepvein's Patch Kit
      61302,  -- Light-Touched Blades
      63150,  -- Shovel
      63427,  -- Worgsaw
      65667,  -- Shovel of Mercy
      67232,  -- Sullah's Pygmy Pen
      71978,  -- Darkmoon Bandage
      72110,  -- Battered Wrench
    },
    [7] = {
      61323,  -- Ruby Seeds
      62899,  -- Enchanted Imp Sack
      63350,  -- Razor-Sharp Scorpid Barb
    },
    [8] = {
      29052,  -- Warp Nether Extractor
      33278,  -- Burning Torch
      34368,  -- Attuned Crystal Cores
      35943,  -- Jeremiah's Tools
      37932,  -- Miner's Lantern
      56821,  -- Oil Extrusion Pump
      68678,  -- Child Safety Harness
    },
    [10] = {
      17626,  -- Frostwolf Muzzle
      17689,  -- Stormpike Training Collar
      21267,  -- Toasting Goblet
      22896,  -- Healing Crystal
      22962,  -- Inoculating Crystal
      23164,  -- Bubbly Beverage
      30656,  -- Protovoltaic Magneto Collector
      32321,  -- Sparrowhawk Net
      33418,  -- Tillinghast's Plague Canister
      34083,  -- Awakening Rod
      34250,  -- Skill: Throw Bullet
      35293,  -- Cenarion Horn
      36859,  -- Snow of Eternal Slumber
      37307,  -- Purified Ashes of Vordrassil
      38697,  -- Jungle Punch Sample
      40551,  -- Gore Bladder
      41988,  -- Telluric Poultice
      42164,  -- Hodir's Horn
      43059,  -- Drakuru's Last Wish
      44576,  -- Bright Flare
      47033,  -- Light-Blessed Relic
      50131,  -- Snagglebolt's Air Analyzer
      52709,  -- Gnomish Playback Device
      52819,  -- Frostgale Crystal
      53009,  -- Juniper Berries
      54215,  -- Vol'jin's War Drums
      54462,  -- Moanah's Baitstick
      54463,  -- Flameseer's Staff
      56012,  -- Stone Knife of Sealing
      56222,  -- Runes of Return
      58167,  -- Spirit Totem
      58200,  -- Techno-Grenade
      58203,  -- Paintinator
      60382,  -- Mylra's Knife
      60870,  -- Barrel of Explosive Ale
      62057,  -- Teleport Beacon
      62326,  -- Heavy Manacles
      62541,  -- Heavy Manacles
      64312,  -- Totem of Freedom
      67249,  -- Viewpoint Equalizer
      68677,  -- Moldy Lunch
      68679,  -- Goblin Gas Tank
      68682,  -- Inflatable Lifesaver
      69240,  -- Enchanted Salve
    },
    [15] = {
      1251,   -- Linen Bandage
      2581,   -- Heavy Linen Bandage
      3530,   -- Wool Bandage
      3531,   -- Heavy Wool Bandage
      6450,   -- Silk Bandage
      6451,   -- Heavy Silk Bandage
      8544,   -- Mageweave Bandage
      8545,   -- Heavy Mageweave Bandage
      14529,  -- Runecloth Bandage
      14530,  -- Heavy Runecloth Bandage
      19066,  -- Warsong Gulch Runecloth Bandage
      19067,  -- Warsong Gulch Mageweave Bandage
      19068,  -- Warsong Gulch Silk Bandage
      19307,  -- Alterac Heavy Runecloth Bandage
      20065,  -- Arathi Basin Mageweave Bandage
      20066,  -- Arathi Basin Runecloth Bandage
      20067,  -- Arathi Basin Silk Bandage
      20232,  -- Defiler's Mageweave Bandage
      20234,  -- Defiler's Runecloth Bandage
      20235,  -- Defiler's Silk Bandage
      20237,  -- Highlander's Mageweave Bandage
      20243,  -- Highlander's Runecloth Bandage
      20244,  -- Highlander's Silk Bandage
      21990,  -- Netherweave Bandage
      21991,  -- Heavy Netherweave Bandage
      30651,  -- Dertrok's First Wand
      30652,  -- Dertrok's Second Wand
      30653,  -- Dertrok's Third Wand
      30654,  -- Dertrok's Fourth Wand
      31129,  -- Blackwhelp Net
      32907,  -- Wolpertinger Net
      33621,  -- Plague Spray
      34721,  -- Frostweave Bandage
      34722,  -- Heavy Frostweave Bandage
      36764,  -- Shard of the Earth
      38573,  -- RJR Rifle
      38640,  -- Dense Frostweave Bandage
      38641,  -- Deprecated Frostweave Bandage [PH]
      38643,  -- Thick Frostweave Bandage
      39268,  -- Medallion of Mam'toth
      44646,  -- Dalaran Bandage
      44959,  -- Soothing Totem
      46722,  -- Grol'dom Net
      52481,  -- Blastshadow's Soulstone
      53049,  -- Embersilk Bandage
      53050,  -- Heavy Embersilk Bandage
      53051,  -- Dense Embersilk Bandage
      53101,  -- Tessina's Wisp Call
      53104,  -- Tessina's Hippogryph Call
      53105,  -- Tessina's Treant Call
      54851,  -- Anemone Chemical Application Device
      56180,  -- Duarn's Net UNUSED
      56184,  -- Duarn's Net
      58169,  -- Elementium Grapple Line
      58966,  -- Jesana's Faerie Dragon Call
      58967,  -- Jesana's Giant Call
      63391,  -- Baradin's Wardens Bandage
      64995,  -- Hellscream's Reach Bandage
    },
    [20] = {
      17757,  -- Amulet of Spirits
      21519,  -- Mistletoe
      22473,  -- Antheol's Disciplinary Rod
      23394,  -- Healing Salve
      23693,  -- Carinda's Scroll of Retribution
      29817,  -- Talbuk Tagger
      29818,  -- Energy Field Modulator
      30175,  -- Gor'drek's Ointment
      32424,  -- Blade's Edge Ogre Brew
      33088,  -- Brogg's Totem
      34127,  -- Tasty Reef Fish
      34257,  -- Fel Siphon
      34711,  -- Core of Malice
      34869,  -- Warsong Banner
      36796,  -- Gavrock's Runebreaker
      36827,  -- Blood Gem
      36835,  -- Unholy Gem
      36847,  -- Frost Gem
      37708,  -- Stick
      39157,  -- Scepter of Suggestion
      39206,  -- Scepter of Empowerment
      39238,  -- Scepter of Command
      39577,  -- Rejek's Blade
      39651,  -- Venture Co. Explosives
      39664,  -- Scepter of Domination
      40397,  -- Lifeblood Gem
      42624,  -- Battered Storm Hammer
      42894,  -- Horn of Elemental Fury
      43206,  -- War Horn of Acherus
      43315,  -- Sigil of the Ebon Blade
      44817,  -- The Mischief Maker
      44975,  -- Orb of Elune
      46363,  -- Lifebringer Sapling
      48104,  -- The Refleshifier
      49202,  -- Black Gunpowder Keg
      50053,  -- Bloodtalon Lasso
      52044,  -- Bilgewater Cartel Promotional Delicacy Morsels
      52073,  -- Bramblestaff
      52484,  -- Kaja'Cola Zero-One
      52566,  -- Motivate-a-Tron
      53107,  -- Flameseer's Staff
      55141,  -- Spiralung
      55158,  -- Fake Treasure
      55230,  -- Soul Stick
      56798,  -- Jin'Zil's Voodoo Stick
      57920,  -- Revantusk War Drums
      58177,  -- Earthen Ring Proclamation
      63079,  -- Titanium Shackles
      63426,  -- Lethality Analyzer
      67241,  -- Sullah's Camel Harness
      68606,  -- Murloc Leash
      68607,  -- Candy Cleanser
      71085,  -- Runestaff of Nordrassil
    },
    [25] = {
      13289,  -- Egan's Blaster
      31463,  -- Zezzak's Shard
      32966,  -- DEBUG - Headless Horseman - Start Fire
      34979,  -- Pouch of Crushed Bloodspore
      46885,  -- Weighted Net
      56247,  -- Box of Crossbow Bolts
    },
    [30] = {
      954,    -- Scroll of Strength
      955,    -- Scroll of Intellect
      1180,   -- Scroll of Stamina
      1181,   -- Scroll of Spirit
      1477,   -- Scroll of Agility II
      1478,   -- Scroll of Protection II
      1711,   -- Scroll of Stamina II
      1712,   -- Scroll of Spirit II
      1912,   -- Deprecated Reed Pipe
      2289,   -- Scroll of Strength II
      2290,   -- Scroll of Intellect II
      3012,   -- Scroll of Agility
      3013,   -- Scroll of Protection
      4381,   -- Minor Recombobulator
      4419,   -- Scroll of Intellect III
      4421,   -- Scroll of Protection III
      4422,   -- Scroll of Stamina III
      4424,   -- Scroll of Spirit III
      4425,   -- Scroll of Agility III
      4426,   -- Scroll of Strength III
      4444,   -- Black Husk Shield
      5613,   -- Staff of the Purifier
      6452,   -- Anti-Venom
      6453,   -- Strong Anti-Venom
      10305,  -- Scroll of Protection IV
      10306,  -- Scroll of Spirit IV
      10307,  -- Scroll of Stamina IV
      10308,  -- Scroll of Intellect IV
      10309,  -- Scroll of Agility IV
      10310,  -- Scroll of Strength IV
      11567,  -- Crystal Spire
      17202,  -- Snowball
      17310,  -- Aspect of Neptulon
      18637,  -- Major Recombobulator
      19440,  -- Powerful Anti-Venom
      20908,  -- Festival of Nian Firework
      21713,  -- Elune's Candle
      22200,  -- Silver Shafted Arrow
      22206,  -- Bouquet of Red Roses
      22218,  -- Handful of Rose Petals
      23337,  -- Cenarion Antidote
      27498,  -- Scroll of Agility V
      27499,  -- Scroll of Intellect V
      27500,  -- Scroll of Protection V
      27501,  -- Scroll of Spirit V
      27502,  -- Scroll of Stamina V
      27503,  -- Scroll of Strength V
      31437,  -- Medicinal Drake Essence
      31828,  -- Ritual Prayer Beads
      32680,  -- Booterang
      32960,  -- Elekk Dispersion Ray
      33108,  -- Ooze Buster
      33457,  -- Scroll of Agility VI
      33458,  -- Scroll of Intellect VI
      33459,  -- Scroll of Protection VI
      33460,  -- Scroll of Spirit VI
      33461,  -- Scroll of Stamina VI
      33462,  -- Scroll of Strength VI
      33865,  -- Amani Hex Stick
      34068,  -- Weighted Jack-o'-Lantern
      34191,  -- Handful of Snowflakes
      34598,  -- The King's Empty Conch
      34684,  -- Handful of Summer Petals
      35557,  -- Huge Snowball
      36732,  -- Potent Explosive Charges
      37091,  -- Scroll of Intellect VII
      37092,  -- Scroll of Intellect VIII
      37093,  -- Scroll of Stamina VII
      37094,  -- Scroll of Stamina VIII
      37097,  -- Scroll of Spirit VII
      37098,  -- Scroll of Spirit VIII
      38515,  -- Tangled Skein Thrower
      40686,  -- U.D.E.D.
      40917,  -- Lord-Commander's Nullifier
      42774,  -- Arngrim's Tooth
      43463,  -- Scroll of Agility VII
      43464,  -- Scroll of Agility VIII
      43465,  -- Scroll of Strength VII
      43466,  -- Scroll of Strength VIII
      43467,  -- Scroll of Protection VII
      43468,  -- Scroll of Protection VIII
      44414,  -- Soul Lash
      44653,  -- Volatile Acid
      44731,  -- Bouquet of Ebon Roses
      44915,  -- Elune's Candle
      45073,  -- Spring Flowers
      49138,  -- Bottle of Leeches
      49199,  -- Infernal Power Core
      49219,  -- Infernal Power Core
      49882,  -- Soothing Seeds
      50163,  -- Lovely Rose
      52710,  -- Enchanted Conch
      52715,  -- Butcherbot Control Gizmo
      56069,  -- Alliance Weapon Crate
      56227,  -- Enchanted Conch
      57172,  -- Attuned Runestone of Binding
      58935,  -- Gryphon Chow
      60861,  -- Holy Thurible
      63303,  -- Scroll of Agility IX
      63304,  -- Scroll of Strength IX
      63305,  -- Scroll of Intellect IX
      63306,  -- Scroll of Stamina IX
      63307,  -- Scroll of Spirit IX
      63308,  -- Scroll of Protection IX
      64637,  -- Tanrir's Overcharged Totem
      69825,  -- Essence Gatherer
    },
    [35] = {
      16103,  -- Test Enchant Boots Stamina
      18904,  -- Zorbin's Ultra-Shrinker
      24501,  -- Gordawg's Boulder
      35121,  -- Wolf Bait
      41505,  -- Thorim's Charm of Earth
      44890,  -- To'kini's Blowgun
      49028,  -- Nitro-Potassium Bananas
      56576,  -- Orb of Suggestion
    },
    [40] = {
      1713,   -- Ankh of Life
      5323,   -- Everglow Lantern
      8346,   -- Gauntlets of the Sea
      11562,  -- Crystal Restore
      18640,  -- Happy Fun Rock
      18662,  -- Heavy Leather Ball
      24541,  -- Medicinal Swamp Moss
      31088,  -- Tainted Core
      33081,  -- Voodoo Skull
      33581,  -- Vrykul Insult
      34255,  -- Razorthorn Flayer Gland
      34471,  -- Vial of the Sunwell
      34494,  -- Paper Zeppelin
      37438,  -- Rod of Compulsion
      38266,  -- Rotund Relic
      38308,  -- Ethereal Essence Sphere
      38332,  -- Modified Mojo
      39305,  -- Tiki Hex Remover
      39615,  -- Crusader Parachute
      40532,  -- Living Ice Crystals
      44114,  -- Old Spices
      44222,  -- Dart Gun
      44228,  -- Baby Spice
      44804,  -- Indalamar's Debuffer
      44812,  -- Turkey Shooter
      44832,  -- Squirt Gun [PH]
      50354,  -- Bauble of True Blood
      50430,  -- Scraps of Rotting Meat
      50726,  -- Bauble of True Blood
      52490,  -- Stardust
      53794,  -- Rendel's Bridle
      55165,  -- Enchanted Sea Snack
      56136,  -- Corrupted Egg Shell
      56169,  -- Breathstone
      56463,  -- Corrupted Egg Shell
      60490,  -- The Axe of Earthly Sundering
      60808,  -- Mutant Bush Chicken Cage
      65162,  -- Emergency Pool Pony
      71627,  -- Throwing Starfish
    },
    [45] = {
      28369,  -- Battery Recharging Blaster
      32698,  -- Wrangling Rope
      34691,  -- Arcane Binder
      49647,  -- Drum of the Soothed Earth
      52059,  -- Murloc Leash
      52833,  -- Modified Soul Orb
      62794,  -- Licensed Proton Accelerator Cannon
    },
    [60] = {
      32825,  -- Soul Cannon
      34111,  -- Trained Rock Falcon
      34121,  -- Trained Rock Falcon
      37877,  -- Silver Feather
      37887,  -- Seeds of Nature's Wrath
      50851,  -- Pulsing Life Crystal
    },
    [70] = {
      41265,  -- Eyesore Blaster
    },
    [80] = {
      28131,  -- Reaver Buster Launcher
      35278,  -- Reinforced Net
      35506,  -- Raelorasz's Spear
      42769,  -- Spear of Hodir
      50031,  -- Tomusa's Hook
      62775,  -- Barbed Fleshhook
      63092,  -- Wyrmhunter Hooks
      63104,  -- Elemental Nullifier
      63393,  -- Shoulder-Mounted Drake-Dropper
    },
    [100] = {
      17162,  -- Eric Test Item A
      23715,  -- Permanent Lung Juice Cocktail
      23718,  -- Permanent Ground Scorpok Assay
      23719,  -- Permanent Cerebral Cortex Compound
      23721,  -- Permanent Gizzard Gum
      23722,  -- Permanent R.O.I.D.S.
      28025,  -- Video Mount
      29877,  -- Indalamar's Super Hot
      34151,  -- Player, Draenei/Tauren
      34152,  -- Player, Dwarf/Orc
      34153,  -- Player, Gnome/Blood Elf
      34154,  -- Player, Human/Undead
      34155,  -- Player, Troll/Night Elf
      41058,  -- Hyldnir Harpoon
      44212,  -- SGM-3
    },
    [150] = {
      46954,  -- Flaming Spears
    },
    -- [50000] = {
    --   5418,   -- Weapon of Mass Destruction (test)
    --   28261,  -- Video Invis
    --   29025,  -- [UNUSED]Triangulation Device
    --   33001,  -- Reflective Dust
    -- },
  }
else
  FriendItems = {
    [2] = {
      168948, -- Dried Kelp
      194718, -- Premium Salamander Feed
    },
    [3] = {
      42732,  -- Everfrost Razor
      200469, -- Khadgar's Disenchanting Rod
    },
    [4] = {
      129055, -- Shoe Shine Kit
    },
    [5] = {
      1970,   -- Restoring Balm
      8149,   -- Voodoo Charm
      15826,  -- Curative Animal Salve
      16991,  -- Triage Bandage
      17117,  -- Rat Catcher's Flute
      20403,  -- Proxy of Nozdormu
      22259,  -- Unbestowed Friendship Bracelet
      23485,  -- Empty Birdcage
      23659,  -- Fel-Tainted Morsels
      33310,  -- The Sergeant's Machete
      33342,  -- The Brave's Machete
      33563,  -- Forsaken Banner
      34954,  -- Torp's Kodo Snaffle
      34973,  -- Re-Cursive Transmatter Injection
      35116,  -- The Ultrasonic Screwdriver
      35401,  -- The Greatmother's Soulcatcher
      35736,  -- Bounty Hunter's Cage
      36771,  -- Sturdy Crates
      36786,  -- Bark of the Walkers
      36956,  -- Liquid Fire of Elune
      37187,  -- Container of Rats
      37202,  -- Onslaught Riding Crop
      37568,  -- Renewing Tourniquet
      37576,  -- Renewing Bandage
      38330,  -- Crusader's Bandage
      38467,  -- Softknuckle Poker
      38627,  -- Mammoth Harness
      38676,  -- Whisker of Har'koa
      38731,  -- Ahunae's Knife
      40587,  -- Darkmender's Tincture
      45001,  -- Medicated Salve
      45080,  -- Large Femur
      49948,  -- Calder's Bonesaw
      50471,  -- The Heartbreaker
      50742,  -- Tara's Tar Scraper
      50746,  -- Tara's Tar Scraper
      52014,  -- Herb-Soaked Bandages
      52271,  -- Northwatch Manacles
      52712,  -- Remote Control Fireworks
      53120,  -- Bottled Bileberry Brew
      56837,  -- Sturdy Manacles
      58502,  -- Explosive Bonding Compound
      58885,  -- Rockslide Reagent
      58955,  -- Razgar's Fillet Knife
      58965,  -- Deepvein's Patch Kit
      61302,  -- Light-Touched Blades
      63150,  -- Shovel
      63427,  -- Worgsaw
      65667,  -- Shovel of Mercy
      67232,  -- Sullah's Pygmy Pen
      71978,  -- Darkmoon Bandage
      72110,  -- Battered Wrench
      79021,  -- Ken-Ken's Mask
      79057,  -- Ken-Ken's Mask
      79102,  -- Green Cabbage Seeds
      79819,  -- Dit Da Jow
      79932,  -- Qu Mo Mask
      80302,  -- EZ-Gro Green Cabbage Seeds
      80590,  -- Juicycrunch Carrot Seeds
      80591,  -- Scallion Seeds
      80592,  -- Mogu Pumpkin Seeds
      80593,  -- Red Blossom Leek Seeds
      80594,  -- Pink Turnip Seeds
      80595,  -- White Turnip Seeds
      85215,  -- Snakeroot Seed
      85216,  -- Enigma Seed
      85217,  -- Magebulb Seed
      85219,  -- Ominous Seed
      85267,  -- Autumn Blossom Sapling
      85268,  -- Spring Blossom Sapling
      85269,  -- Winter Blossom Sapling
      89197,  -- Windshear Cactus Seed
      89202,  -- Raptorleaf Seed
      89233,  -- Songbell Seed
      89326,  -- Witchberry Seeds
      89328,  -- Jade Squash Seeds
      89329,  -- Striped Melon Seeds
      89880,  -- Dented Shovel
      91806,  -- Unstable Portal Shard
      114835, -- Rooby Reat
      120293, -- Lukewarm Yak Roast Broth
      133065, -- Tony Mourdain's Cleaver
      136605, -- Solendra's Compassion
      137299, -- Nightborne Spellblade
      139463, -- Felbat Toxin Salve
      142065, -- Dusk Lily Sigil
      142262, -- Electrified Key
      143597, -- Fruit of the Arcan'dor
      143773, -- Contagion Counteragent
      150759, -- Restorative Balm
      151563, -- Hallowed Prayer Effigy
      151570, -- Lightbound Crystal
      151624, -- Y'mera's Arcanocrystal
      152472, -- Chieftain's Salve
      152630, -- Ranah's Watering Can
      152971, -- Talisman of the Prophet
      152995, -- Sacred Stone
      153049, -- Scroll of Purging
      153112, -- Scroll of Purging
      153496, -- Tasty Treats
      153513, -- Cleansing Tonic
      156518, -- Lucille's Sewing Needle
      156532, -- Inquisitor's Regalia
      157771, -- Holy Water
      158678, -- Antivenom
      159470, -- Faithless Scimitar
      159782, -- Milk Pail
      160045, -- Antidote Salve
      160429, -- Rope and Hook
      160433, -- Bandages
      160559, -- Scroll of Purification
      160561, -- Goldfield's Knife
      160571, -- Lucille's Sewing Needle
      160585, -- Soulcaller Scroll
      161247, -- Marshal's Regalia
      162450, -- Portal Orb
      162589, -- Alexxi's Foolproof Remedy
      163607, -- Lucille's Sewing Needle
      163720, -- Mildenhall Growth Formula
      163740, -- Drust Ritual Knife
      166972, -- Emergency Powerpack
      166973, -- Emergency Repair Kit
      167041, -- Coiled Current Culler
      168410, -- First Aid Kit
      169653, -- Potion of Mental Clarity
      172020, -- Battered Weapon
      173013, -- Bag of Faerie Dust
      173148, -- Steel Cleaver
      174197, -- Loremaster's Notebook
      174326, -- Rough Burlap Bandages
      177817, -- Voodoo Powder
      180613, -- Fragile Humility Scroll
      181364, -- Cluster of Seeds
      183689, -- Crusader's Dressing
      183698, -- Torturer's Key
      183797, -- Crusader's Dressing
      184622, -- Stygian Hammer
      186445, -- Mikanikos' Restorative Contraption
      186448, -- Mikanikos' Restorative Contraption
      186695, -- Lovely Pet Bandage
      187504, -- Mikanikos' Restorative Contraption
      192467, -- Bandages
      192795, -- Rejuvenating Draught
      194052, -- Forlorn Funeral Pall
      194434, -- Pungent Salve
      197805, -- Suspicious Persons Scanner
      202874, -- Healing Draught
      203731, -- Enchanted Bandage
      208124, -- The Dreamer's Essence
      208738, -- Ephemeral Pear
      208985, -- Silly Hat
      213539, -- Nebb's Poultice
      215145, -- Remembrance Stone
      216687, -- Cobbled Together Bandage
      217159, -- Nebb's Improved Poultice
      219385, -- Antiparalytic Serum
      224799, -- Nizrek's potion
    },
    [6] = {
      164766, -- Iwen's Enchanting Rod
      219525, -- Globe of Nourishment
    },
    [7] = {
      61323,  -- Ruby Seeds
      62899,  -- Enchanted Imp Sack
      63350,  -- Razor-Sharp Scorpid Barb
      88589,  -- Cremating Torch
      153249, -- Y'mera's Attuning Crystal
    },
    [8] = {
      33278,  -- Burning Torch
      34368,  -- Attuned Crystal Cores
      35943,  -- Jeremiah's Tools
      37932,  -- Miner's Lantern
      56821,  -- Oil Extrusion Pump
      82311,  -- Zouchin Rations
      82787,  -- Citron-Infused Bandages
      84242,  -- Shado-Pan Bandages
      128776, -- Red Wooden Sled
      152730, -- Sumber's Totem
    },
    [10] = {
      17626,  -- Frostwolf Muzzle
      17689,  -- Stormpike Training Collar
      21267,  -- Toasting Goblet
      22962,  -- Inoculating Crystal
      30656,  -- Protovoltaic Magneto Collector
      32321,  -- Sparrowhawk Net
      33418,  -- Tillinghast's Plague Canister
      34083,  -- Awakening Rod
      35293,  -- Cenarion Horn
      36859,  -- Snow of Eternal Slumber
      37307,  -- Purified Ashes of Vordrassil
      38697,  -- Jungle Punch Sample
      40551,  -- Gore Bladder
      41988,  -- Telluric Poultice
      42164,  -- Hodir's Horn
      43059,  -- Drakuru's Last Wish
      44576,  -- Bright Flare
      47033,  -- Light-Blessed Relic
      50131,  -- Snagglebolt's Air Analyzer
      52709,  -- Gnomish Playback Device
      52819,  -- Frostgale Crystal
      53009,  -- Juniper Berries
      54215,  -- Vol'jin's War Drums
      54462,  -- Moanah's Baitstick
      54463,  -- Flameseer's Staff
      56012,  -- Stone Knife of Sealing
      56222,  -- Runes of Return
      58167,  -- Spirit Totem
      58200,  -- Techno-Grenade
      58203,  -- Paintinator
      60382,  -- Mylra's Knife
      60870,  -- Barrel of Explosive Ale
      62057,  -- Teleport Beacon
      62326,  -- Heavy Manacles
      62541,  -- Heavy Manacles
      64312,  -- Totem of Freedom
      67249,  -- Viewpoint Equalizer
      68679,  -- Goblin Gas Tank
      69240,  -- Enchanted Salve
      78947,  -- Silken Rope
      79884,  -- Bucket of Slicky Water
      80220,  -- Forest Remedy
      81177,  -- Pandaren Healing Draught
      82381,  -- Yak's Milk Flask
      90067,  -- B. F. F. Necklace
      106958, -- Winterwasp Antidote
      106987, -- Sigil of Karabor
      107656, -- Kaz's Disturbing Crate
      112321, -- Enchanted Dust
      118418, -- Mug of Rousing Coffee
      119440, -- Training Shoes
      124100, -- Moonwater Vial
      129190, -- Rope of Friendship
      132877, -- Eye of Azzorok
      136386, -- Bloodstone
      140314, -- Crab Shank
      152278, -- Cracked Wand
      153537, -- Animate Sphere
      153565, -- Shackles
      156549, -- Writ of Sacrifice
      158190, -- Target Marker
      158907, -- Moonstone Pendant
      158908, -- Moonstone Weapon
      166701, -- Warbeast Kraal Dinner Bell
      166784, -- Narassin's Soul Gem
      166785, -- Detoxified Blight Grenade
      168053, -- Unusually Wise Hermit Crab
      168811, -- Wand of Absorption
      168891, -- Cursed Lover's Ring
      169860, -- Tiny Dapper Hat
      169943, -- Little Princess Cap
      169944, -- Minuscule Fez
      170161, -- Unusually Wise Hermit Crab
      172955, -- Gormherd Branch
      173870, -- Fading Glimmerdust
      174323, -- Torch
      175063, -- Aqir Egg Cluster
      184292, -- Ancient Elethium Coin
      184314, -- Broker Device
      187943, -- Fae Net
      191375, -- Delicate Suspension of Spores
      191376, -- Delicate Suspension of Spores
      191377, -- Delicate Suspension of Spores
      193917, -- Rejuvenating Draught
      202096, -- Armaments of the Scale
      202112, -- Crystal Shattering Armaments
      202271, -- Pouch of Gold Coins
      202714, -- M.U.S.T
      205045, -- B.B.F. Fist
      207632, -- Dream-Attuned Crystal
      219469, -- Fog Beast Tracker
      223322, -- Hannan's Scythe
    },
    [12] = {
      208068, -- Rotten Delicious
    },
    [15] = {
      1251,   -- Linen Bandage
      2581,   -- Heavy Linen Bandage
      3530,   -- Wool Bandage
      3531,   -- Heavy Wool Bandage
      6450,   -- Silk Bandage
      6451,   -- Heavy Silk Bandage
      8544,   -- Mageweave Bandage
      8545,   -- Heavy Mageweave Bandage
      14529,  -- Runecloth Bandage
      14530,  -- Heavy Runecloth Bandage
      19066,  -- Warsong Gulch Runecloth Bandage
      19067,  -- Warsong Gulch Mageweave Bandage
      19068,  -- Warsong Gulch Silk Bandage
      19307,  -- Alterac Heavy Runecloth Bandage
      20065,  -- Arathi Basin Mageweave Bandage
      20066,  -- Arathi Basin Runecloth Bandage
      20067,  -- Arathi Basin Silk Bandage
      20232,  -- Defiler's Mageweave Bandage
      20234,  -- Defiler's Runecloth Bandage
      20235,  -- Defiler's Silk Bandage
      20237,  -- Highlander's Mageweave Bandage
      20243,  -- Highlander's Runecloth Bandage
      20244,  -- Highlander's Silk Bandage
      21990,  -- Netherweave Bandage
      21991,  -- Heavy Netherweave Bandage
      30651,  -- Dertrok's First Wand
      30652,  -- Dertrok's Second Wand
      30653,  -- Dertrok's Third Wand
      30654,  -- Dertrok's Fourth Wand
      31129,  -- Blackwhelp Net
      32907,  -- Wolpertinger Net
      33621,  -- Plague Spray
      34721,  -- Frostweave Bandage
      34722,  -- Heavy Frostweave Bandage
      36764,  -- Shard of the Earth
      38573,  -- RJR Rifle
      39268,  -- Medallion of Mam'toth
      44646,  -- Dalaran Bandage
      44959,  -- Soothing Totem
      46722,  -- Grol'dom Net
      52481,  -- Blastshadow's Soulstone
      53049,  -- Embersilk Bandage
      53050,  -- Heavy Embersilk Bandage
      53051,  -- Dense Embersilk Bandage
      53101,  -- Tessina's Wisp Call
      53104,  -- Tessina's Hippogryph Call
      53105,  -- Tessina's Treant Call
      54851,  -- Anemone Chemical Application Device
      56184,  -- Duarn's Net
      58169,  -- Elementium Grapple Line
      58966,  -- Jesana's Faerie Dragon Call
      58967,  -- Jesana's Giant Call
      63391,  -- Baradin's Wardens Bandage
      64995,  -- Hellscream's Reach Bandage
      72985,  -- Windwool Bandage
      72986,  -- Heavy Windwool Bandage
      79027,  -- Saltback Meat
      82829,  -- Windwool Bandage
      111603, -- Antiseptic Bandage
      115475, -- Vial of Untested Serum
      115497, -- Ashran Bandage
      115533, -- Vial of Refined Serum
      133940, -- Silkweave Bandage
      133942, -- Silkweave Splint
      136653, -- Silvery Salve
      143636, -- Arcane Splint
      144228, -- Dino Mojo
      146971, -- Yseralline Poultice
      147445, -- Ancient Draught of Regeneration
      152395, -- Counter Spell Charm
      152613, -- Sar'jun's Torch
      158381, -- Tidespray Linen Bandage
      158382, -- Deep Sea Bandage
      158935, -- Depleted Soul Shard
      161333, -- Ultra-Safe Electrified Alpaca Lasso
      165762, -- Embiggifier Core
      165815, -- Tranquilizer Dart
      173191, -- Heavy Shrouded Cloth Bandage
      173192, -- Shrouded Cloth Bandage
      173691, -- Anima Drainer
      179359, -- Sinstone Fragment
      179921, -- Hydra Gutter
      179978, -- Infused Animacones
      179983, -- Infused Animacones
      186102, -- Lady Moonberry's Wand
      186569, -- Angry Needler Nest
      189384, -- Ornithological Medical Kit
      193064, -- Smoke Diffuser
      194048, -- Wildercloth Bandage
      194049, -- Wildercloth Bandage
      194050, -- Wildercloth Bandage
      197928, -- Captivating Cap
      211943, -- Scarlet Silk Bandage
      215133, -- Binding of Binding
      219322, -- Malodorous Philter
      219323, -- Gelatinous Unguent
      219324, -- Roiling Elixir
      224194, -- Fashion Frenzy Ribbon
      224440, -- Weavercloth Bandage
      224441, -- Weavercloth Bandage
      224442, -- Weavercloth Bandage
    },
    [20] = {
      17757,  -- Amulet of Spirits
      21519,  -- Mistletoe
      22473,  -- Antheol's Disciplinary Rod
      23394,  -- Healing Salve
      23693,  -- Carinda's Scroll of Retribution
      29817,  -- Talbuk Tagger
      29818,  -- Energy Field Modulator
      30175,  -- Gor'drek's Ointment
      33088,  -- Brogg's Totem
      34127,  -- Tasty Reef Fish
      34257,  -- Fel Siphon
      34711,  -- Core of Malice
      34869,  -- Warsong Banner
      36796,  -- Gavrock's Runebreaker
      36827,  -- Blood Gem
      36835,  -- Unholy Gem
      36847,  -- Frost Gem
      37708,  -- Stick
      39157,  -- Scepter of Suggestion
      39206,  -- Scepter of Empowerment
      39238,  -- Scepter of Command
      39577,  -- Rejek's Blade
      39651,  -- Venture Co. Explosives
      39664,  -- Scepter of Domination
      40397,  -- Lifeblood Gem
      42624,  -- Battered Storm Hammer
      42894,  -- Horn of Elemental Fury
      43206,  -- War Horn of Acherus
      43315,  -- Sigil of the Ebon Blade
      44817,  -- The Mischief Maker
      44975,  -- Orb of Elune
      46363,  -- Lifebringer Sapling
      48104,  -- The Refleshifier
      49202,  -- Black Gunpowder Keg
      52044,  -- Bilgewater Cartel Promotional Delicacy Morsels
      52073,  -- Bramblestaff
      52484,  -- Kaja'Cola Zero-One
      52566,  -- Motivate-a-Tron
      53107,  -- Flameseer's Staff
      55141,  -- Spiralung
      55158,  -- Fake Treasure
      55230,  -- Soul Stick
      56798,  -- Jin'Zil's Voodoo Stick
      57920,  -- Revantusk War Drums
      58177,  -- Earthen Ring Proclamation
      63079,  -- Titanium Shackles
      63426,  -- Lethality Analyzer
      67241,  -- Sullah's Camel Harness
      68606,  -- Murloc Leash
      71085,  -- Runestaff of Nordrassil
      77475,  -- Stack of Mantras
      85884,  -- Sonic Emitter
      87558,  -- Ella's Brew
      87763,  -- Ella's Brew
      88487,  -- Volatile Orb
      88587,  -- Iron Belly Spirits
      91902,  -- Universal Remote
      93180,  -- Re-Configured Remote
      93751,  -- Blessed Torch
      103786, -- \"Dapper Gentleman\" Costume
      103789, -- \"Little Princess\" Costume
      103795, -- \"Dread Pirate\" Costume
      103797, -- Big Pink Bow
      110508, -- \"Fragrant\" Pheromone Fish
      114967, -- Torch
      116172, -- Perky Blaster
      116810, -- \"Mad Alchemist\" Costume
      116811, -- \"Lil' Starlet\" Costume
      116812, -- \"Yipp-Saron\" Costume
      118414, -- Awesomefish
      118415, -- Grieferfish
      118511, -- Tyfish
      124506, -- Vial of Fel Cleansing
      127707, -- Indestructible Bone
      128634, -- Mysterious Brew
      128650, -- \"Merry Munchkin\" Costume
      130260, -- Thaedris's Elixir
      134119, -- Overloaded Collar
      134824, -- \"Sir Pugsington\" Costume
      134860, -- Peddlefeet's Buffing Creme
      142260, -- Arcane Nullifier
      142494, -- Purple Blossom
      142495, -- Fake Teeth
      142496, -- Dirty Spoon
      142497, -- Tiny Pack
      143865, -- Abyssal Crest
      147886, -- Battle Token
      151135, -- Stein of Grog
      151763, -- Crab Trap
      151912, -- Shroud of Arcane Echoes
      152590, -- Wicker Charm
      158174, -- Battleworn Armor Kit
      162140, -- Battleworn Armor Kit
      162631, -- Souvenir Tiki Tumbler
      163172, -- Green Glowing Puffer
      163516, -- Blue Glowing Puffer
      163517, -- Red Glowing Puffer
      163518, -- Purple Glowing Puffer
      163520, -- Orange Glowing Puffer
      163521, -- Yellow Glowing Puffer
      167071, -- Mechano-Treat
      167091, -- Maedin's Scroll
      168122, -- NRG-100
      168525, -- Poison Globule
      173534, -- Gormherd Branch
      174749, -- Bone Splinter
      183105, -- Tormentor's Rod
      184505, -- \"Adorable Ascended\" Costume
      184506, -- \"Flying Faerie\" Costume
      186094, -- Siphoning Device
      187708, -- Broken Helm
      187816, -- Irresistible Goop
      187839, -- Tonal Jammer
      188002, -- Broken Helm
      188697, -- Kinematic Micro-Life Recalibrator
      189449, -- Jiro Scan
      189479, -- Chromatic Rosid
      189561, -- Tame Prime: Orixal
      189572, -- Tame Prime: Hadeon the Stonebreaker
      189573, -- Tame Prime: Garudeon
      191408, -- Explosive Pie
      191682, -- Explosive Pie
      191854, -- Briny Seawater
      191865, -- Bottle of Briny Seawater
      192477, -- [PH] Primalist Keystone
      192743, -- Wild Bushfruit
      194447, -- Totem of Respite
      202310, -- Defective Doomsday Device
      202875, -- Snail Lasso
      203706, -- Hurricane Scepter
      205980, -- Snail Lasso
      208884, -- Root Restoration Fruit
      211535, -- Scroll of Shattering
      223312, -- Trusty Hat
      223316, -- Trusty Hat
      229413, -- \"Dogg-Saron\" Costume
    },
    [25] = {
      13289,  -- Egan's Blaster
      31463,  -- Zezzak's Shard
      34979,  -- Pouch of Crushed Bloodspore
      46885,  -- Weighted Net
      56247,  -- Box of Crossbow Bolts
      74771,  -- Staff of Pei-Zhi
      117013, -- Wand of Lightning Shield
      152983, -- Bundle of Ranishu \"Food\"
      153012, -- Poisoned Mojo Flask
      169308, -- Chain of Suffering
      170540, -- Ravenous Anima Cell
      185775, -- Codex of Renewed Vigor
      198088, -- Darkmoon Deck: Dance
      198478, -- Darkmoon Deck Box: Dance
      204274, -- Ancient Memories
      204808, -- Empowered Temporal Gossamer
      208846, -- Restored Dreamleaf
      209349, -- Lydiara's Notes on Rune Reagents
      210010, -- Erden's Notes on Symbiotic Spores
      210011, -- Shalasar's Notes on Sophic Magic
      210199, -- Tattered Dreamleaf
      210881, -- Cunning Charm
      228996, -- Relic of Crystal Connections
    },
    [30] = {
      954,    -- Scroll of Strength
      955,    -- Scroll of Intellect
      1180,   -- Scroll of Stamina
      1181,   -- Scroll of Versatility
      1477,   -- Scroll of Agility II
      1478,   -- Scroll of Protection II
      1711,   -- Scroll of Stamina II
      1712,   -- Scroll of Versatility II
      2289,   -- Scroll of Strength II
      2290,   -- Scroll of Intellect II
      3012,   -- Scroll of Agility
      3013,   -- Scroll of Protection
      4381,   -- Minor Recombobulator
      4419,   -- Scroll of Intellect III
      4421,   -- Scroll of Protection III
      4422,   -- Scroll of Stamina III
      4424,   -- Scroll of Versatility III
      4425,   -- Scroll of Agility III
      4426,   -- Scroll of Strength III
      4444,   -- Black Husk Shield
      5613,   -- Staff of the Purifier
      6452,   -- Anti-Venom
      6453,   -- Strong Anti-Venom
      10305,  -- Scroll of Protection IV
      10306,  -- Scroll of Versatility IV
      10307,  -- Scroll of Stamina IV
      10308,  -- Scroll of Intellect IV
      10309,  -- Scroll of Agility IV
      10310,  -- Scroll of Strength IV
      11567,  -- Crystal Spire
      17202,  -- Snowball
      17310,  -- Aspect of Neptulon
      18637,  -- Major Recombobulator
      19440,  -- Powerful Anti-Venom
      21713,  -- Elune's Candle
      22200,  -- Silver Shafted Arrow
      22218,  -- Handful of Rose Petals
      23337,  -- Cenarion Antidote
      27498,  -- Scroll of Agility V
      27499,  -- Scroll of Intellect V
      27500,  -- Scroll of Protection V
      27501,  -- Scroll of Versatility V
      27502,  -- Scroll of Stamina V
      27503,  -- Scroll of Strength V
      31437,  -- Medicinal Drake Essence
      31828,  -- Ritual Prayer Beads
      32680,  -- Booterang
      32960,  -- Elekk Dispersion Ray
      33108,  -- Ooze Buster
      33457,  -- Scroll of Agility VI
      33458,  -- Scroll of Intellect VI
      33459,  -- Scroll of Protection VI
      33460,  -- Scroll of Versatility VI
      33461,  -- Scroll of Stamina VI
      33462,  -- Scroll of Strength VI
      33865,  -- Amani Hex Stick
      34068,  -- Weighted Jack-o'-Lantern
      34191,  -- Handful of Snowflakes
      34598,  -- The King's Empty Conch
      34684,  -- Handful of Summer Petals
      35557,  -- Huge Snowball
      36732,  -- Potent Explosive Charges
      37091,  -- Scroll of Intellect VII
      37092,  -- Scroll of Intellect VIII
      37093,  -- Scroll of Stamina VII
      37094,  -- Scroll of Stamina VIII
      37097,  -- Scroll of Versatility VII
      37098,  -- Scroll of Versatility VIII
      38515,  -- Tangled Skein Thrower
      40686,  -- U.D.E.D.
      40917,  -- Lord-Commander's Nullifier
      42774,  -- Arngrim's Tooth
      43463,  -- Scroll of Agility VII
      43464,  -- Scroll of Agility VIII
      43465,  -- Scroll of Strength VII
      43466,  -- Scroll of Strength VIII
      43467,  -- Scroll of Protection VII
      43468,  -- Scroll of Protection VIII
      44653,  -- Volatile Acid
      44915,  -- Elune's Candle
      45073,  -- Spring Flowers
      49138,  -- Bottle of Leeches
      49199,  -- Infernal Power Core
      49882,  -- Soothing Seeds
      50163,  -- Lovely Rose
      52710,  -- Enchanted Conch
      52715,  -- Butcherbot Control Gizmo
      56069,  -- Alliance Weapon Crate
      56227,  -- Enchanted Conch
      57172,  -- Attuned Runestone of Binding
      58935,  -- Gryphon Chow
      60861,  -- Holy Thurible
      63303,  -- Scroll of Agility IX
      63304,  -- Scroll of Strength IX
      63305,  -- Scroll of Intellect IX
      63306,  -- Scroll of Stamina IX
      63307,  -- Scroll of Versatility IX
      63308,  -- Scroll of Protection IX
      64637,  -- Tanrir's Overcharged Totem
      69825,  -- Essence Gatherer
      80337,  -- Ken-Ken's Mask
      85231,  -- Bag of Clams
      86589,  -- Ai-Li's Skymirror
      88580,  -- Ken-Ken's Mask
      92019,  -- The Bilgewater Molotov
      110490, -- Larry Bugged Item
      110492, -- Flamewrought Jewel
      116648, -- Manufactured Love Prism
      116651, -- True Love Prism
      118179, -- Talbuk Lasso
      118181, -- Clefthoof Lasso
      118182, -- Wolf Lasso
      118183, -- Riverbeast Lasso
      118184, -- Elekk Lasso
      118185, -- Boar Lasso
      118283, -- Wolf Lasso
      118284, -- Talbuk Lasso
      118285, -- Riverbeast Lasso
      118286, -- Elekk Lasso
      118287, -- Clefthoof Lasso
      118288, -- Boar Lasso
      118643, -- Huge Crate of Weapons
      119083, -- Fruit Basket
      128632, -- Savage Snowball
      128648, -- Yellow Snowball
      136339, -- Spellstone of Kel'danath
      138026, -- Empowered Charging Device
      138733, -- Shadescale Manipulator
      139427, -- Wild Mana Wand
      143863, -- Fel Exfoliator
      147420, -- Pebble
      153219, -- Squished Demon Eye
      156665, -- Bag of Transmutation Stones
      156831, -- Bag of Transmutation Stones
      158332, -- Zeth'jir Channeling Rod
      160307, -- Raal's Hexing Stick
      160525, -- Tongo's Head
      166230, -- Re-Discombobulator
      166797, -- Star Topaz
      168407, -- Friendship Net
      168947, -- Scroll of Bursting Power
      169209, -- Scroll of Bursting Power
      169446, -- Water Filled Bladder
      169673, -- Blue Paint Filled Bladder
      169674, -- Green Paint Filled Bladder
      169675, -- Orange Paint Filled Bladder
      173358, -- Invitations
      173693, -- Jar of Maggots
      173888, -- Shard of Self Sacrifice
      178873, -- Concentrated Anima Vial
      183944, -- Heron Net
      188692, -- Pouch of Ebon Rose Petals
      188693, -- Pouch of Red Rose Petals
      189454, -- Feather-Plucker 3300
      192471, -- Arch Instructor's Wand
      193736, -- Water's Beating Heart
      193757, -- Ruby Whelp Shell
      193892, -- Wish's Whistle
      194122, -- Sour Apple
      194712, -- Empty Duck Trap
      194731, -- Illusion Parchment: Magma Missile
      194733, -- Illusion Parchment: Aqua Torrent
      194734, -- Illusion Parchment: Whirling Breeze
      194735, -- Illusion Parchment: Arcane Burst
      194736, -- Illusion Parchment: Chilling Wind
      194738, -- Illusion Parchment: Shadow Orb
      194818, -- Proto-Drake Wrangler Rope
      200120, -- Irideus' Power Core
      202270, -- [DNT] Twice-Woven Rope
      204473, -- Element Siphoner
      205688, -- Glutinous Glitterscale Glob
      206160, -- Madam Shadow's Grimoire
      210755, -- Silent Mark of the Dreamsaber
      210764, -- Silent Mark of the Dreamtalon
      210766, -- Silent Mark of the Umbraclaw
      210767, -- Silent Mark of the Dreamstag
      212602, -- Titan Emitter
      215142, -- Freydrin's Shillelagh
      215158, -- Freydrin's Shillelagh
      218124, -- Element Extractor
      223220, -- Kaheti All-Purpose Cleanser
      224026, -- Storm Vessel
      225887, -- Titan Emitter
    },
    [35] = {
      18904,  -- Zorbin's Ultra-Shrinker
      24501,  -- Gordawg's Boulder
      35121,  -- Wolf Bait
      41505,  -- Thorim's Charm of Earth
      44890,  -- To'kini's Blowgun
      49028,  -- Nitro-Potassium Bananas
      56576,  -- Orb of Suggestion
      151363, -- Ticker's Rocket Launcher
      180899, -- Riding Hook
      193212, -- Marmoni Rescue Pack
    },
    [38] = {
      140786, -- Ley Spider Eggs
    },
    [40] = {
      1713,   -- Ankh of Life
      5232,   -- Soulstone
      5323,   -- Everglow Lantern
      8346,   -- Gauntlets of the Sea
      11562,  -- Crystal Restore
      18640,  -- Happy Fun Rock
      18662,  -- Heavy Leather Ball
      31088,  -- Tainted Core
      33081,  -- Voodoo Skull
      33581,  -- Vrykul Insult
      34255,  -- Razorthorn Flayer Gland
      34471,  -- Vial of the Sunwell
      34494,  -- Paper Zeppelin
      37438,  -- Rod of Compulsion
      38266,  -- Rotund Relic
      38308,  -- Ethereal Essence Sphere
      38332,  -- Modified Mojo
      39305,  -- Tiki Hex Remover
      39615,  -- Crusader Parachute
      40532,  -- Living Ice Crystals
      44114,  -- Old Spices
      44222,  -- Dart Gun
      44228,  -- Baby Spice
      44812,  -- Turkey Shooter
      50354,  -- Bauble of True Blood
      50430,  -- Scraps of Rotting Meat
      50726,  -- Bauble of True Blood
      52490,  -- Stardust
      53794,  -- Rendel's Bridle
      55165,  -- Enchanted Sea Snack
      56136,  -- Corrupted Egg Shell
      56169,  -- Breathstone
      56463,  -- Corrupted Egg Shell
      60490,  -- The Axe of Earthly Sundering
      60808,  -- Mutant Bush Chicken Cage
      65162,  -- Emergency Pool Pony
      71627,  -- Throwing Starfish
      74612,  -- Red Panda Lasso
      82468,  -- Yak Lasso
      90883,  -- The Pigskin
      90888,  -- Special Edition Foot Ball
      92965,  -- Rotten Fruit
      92980,  -- Friendly Favor
      93668,  -- Saur Fetish
      94525,  -- Stolen Relic of Zuldazar
      95763,  -- Stolen Relic of Zuldazar
      96135,  -- Stolen Relic of Zuldazar
      96507,  -- Stolen Relic of Zuldazar
      96879,  -- Stolen Relic of Zuldazar
      104323, -- The Swineskin
      104324, -- Foot Ball
      110426, -- Goblin Hot Potato
      110506, -- Parasitic Starfish
      114926, -- Restorative Goldcap
      116400, -- Silver-Plated Turkey Shooter
      116759, -- Blixthraz's Frightening Grudgesolver
      118190, -- Blixthraz's Frightening Grudgesolver
      118236, -- Counterfeit Coin
      119159, -- Happy Fun Skull
      128505, -- Celebration Wand - Murloc
      128506, -- Celebration Wand - Gnoll
      128772, -- Branch of the Runewood
      132511, -- Pump-Action Bandage Gun
      133305, -- Corrupted Egg Shell
      133462, -- Vial of the Sunwell
      133706, -- Mossgill Bait
      133928, -- Prototype Pump-Action Bandage Gun
      133998, -- Rainbow Generator
      133999, -- Inert Crystal
      136927, -- Scarlet Confessional Book
      137462, -- Jewel of Insatiable Desire
      138884, -- Throwing Sausage
      139333, -- Horn of Cenarius
      139882, -- Vial of Hippogryph Pheromones
      141005, -- Vial of Hippogryph Pheromones
      141306, -- Wisp in a Bottle
      141411, -- Translocation Anomaly Neutralization Crystal
      147882, -- Celebration Wand - Trogg
      147883, -- Celebration Wand - Quilboar
      152574, -- Corbyn's Beacon
      152996, -- Vrykul Toy Boat
      153182, -- Holy Lightsphere
      153483, -- Modified Blood Fetish
      153571, -- Poisoned Blow Dart
      153675, -- Scroll of Capsizing
      155567, -- Mr. Munchykins
      155569, -- Mayor Striggs
      156528, -- Titan Manipulator
      156649, -- Zandalari Effigy Amulet
      156868, -- Crawg Poison Gland
      158320, -- Revitalizing Voodoo Totem
      159882, -- Bug Zapper
      160649, -- Inoculating Extract
      163741, -- Magic Fun Rock
      165702, -- Shard of Vesara
      167863, -- Pillar of the Drowned Cabal
      167865, -- Void Stone
      168012, -- Apexis Focusing Shard
      169152, -- Empty Beehive
      169305, -- Aquipotent Nautilus
      169311, -- Ashvane's Razor Coral
      169490, -- Relic of the Black Empire
      173379, -- Purify Stone
      174007, -- Purifying Draught
      174927, -- Zan-Tien Lasso
      175733, -- Brimming Ember Shard
      178495, -- Shattered Helm of Domination
      178496, -- Baron's Warhorn
      178530, -- Wreath-A-Rang
      180953, -- Soultwinning Scepter
      181360, -- Brimming Ember Shard
      182653, -- Larion Treats
      183599, -- Tossable Head
      183808, -- Leashed Construct
      184017, -- Bargast's Leash
      184313, -- Shattered Helm of Domination
      184841, -- Lyre of Sacred Purpose
      185720, -- Draka's Battlehorn
      186421, -- Forbidden Necromantic Tome
      186474, -- Korayn's Javelin
      188761, -- Happy Fun Sphere
      191044, -- Spider Squasher
      193678, -- Miniature Singing Stone
      193826, -- Trusty Dragonkin Rake
      193856, -- Flowery's Rake
      198047, -- Kul Tiran Red
      198081, -- Caregiver's Charm
      201815, -- Cloak of Many Faces
      203714, -- Ward of Faceless Ire
      204343, -- Trusty Dragonkin Rake
      204388, -- Draconic Cauterizing Magma
      204714, -- Satchel of Healing Spores
      207390, -- Delve Ring
      211000, -- Cunning Charm
      217929, -- Timeless Scroll of Cleansing
      219306, -- Burin of the Candle King
      225656, -- Goldenglow Censer
    },
    [45] = {
      28369,  -- Battery Recharging Blaster
      32698,  -- Wrangling Rope
      34691,  -- Arcane Binder
      49647,  -- Drum of the Soothed Earth
      52059,  -- Murloc Leash
      52833,  -- Modified Soul Orb
      62794,  -- Licensed Proton Accelerator Cannon
      88377,  -- Turnip Paint \"Gun\"
      207057, -- Gift of the White War Wolf
      207083, -- Gift of the Ravenous Black Gryphon
    },
    [46] = {
      219320, -- Viscous Coaglam
    },
    [50] = {
      110009, -- Leaf of the Ancient Protectors
      116139, -- Haunting Memento
      147006, -- Archive of Faith
      147007, -- The Deceiver's Grand Design
      151957, -- Ishkar's Felshield Emitter
      151958, -- Tarratus Keystone
      160443, -- The Glaive of Vol'jin
      160557, -- Pungent Onion
      161452, -- The Glaive of Vol'jin
      165578, -- Mirror of Entwined Fate
      182451, -- Glimmerdust's Grand Design
      184020, -- Tuft of Smoldering Plumage
      184029, -- Manabound Mirror
      207084, -- Auebry's Marker Pistol
      212175, -- Draconic Commendation
    },
    [55] = {
      74637,  -- Kiryn's Poison Vial
    },
    [60] = {
      32825,  -- Soul Cannon
      34111,  -- Trained Rock Falcon
      34121,  -- Trained Rock Falcon
      37877,  -- Silver Feather
      37887,  -- Seeds of Nature's Wrath
      50851,  -- Pulsing Life Crystal
      127030, -- Granny's Flare Grenades
      153679, -- Tether Shot
      156928, -- Tether Shot
      169279, -- Pedram's Marker Pistol
    },
    [70] = {
      41265,  -- Eyesore Blaster
      202642, -- Proto-Killing Spear
    },
    [80] = {
      35278,  -- Reinforced Net
      35506,  -- Raelorasz's Spear
      42769,  -- Spear of Hodir
      50031,  -- Tomusa's Hook
      62775,  -- Barbed Fleshhook
      63092,  -- Wyrmhunter Hooks
      63104,  -- Elemental Nullifier
      63393,  -- Shoulder-Mounted Drake-Dropper
      152572, -- Sezahjin's Trusty Vulture Bow
      152610, -- Sur'jan's Grappling Hook
      159761, -- Grappling Hook
      168253, -- Fathom Hook
      185742, -- Mawsworn Chains
      194891, -- Arcane Hook
    },
    [90] = {
      133925, -- Fel Lash
    },
    [100] = {
      41058,  -- Hyldnir Harpoon
      44212,  -- SGM-3
      83134,  -- Bronze Claws
      109082, -- Barbed Harpoon
      160739, -- Goblin Rocket Launcher
      161422, -- Magister Umbric's Void Shard
      200549, -- Restored Titan Artifact
      202020, -- Chasing Storm
      210223, -- Unstable Element
      222976, -- Flame-Tempered Harpoon
    },
    [120] = {
      160988, -- Goblin Incendiary Rocket Launcher
      168430, -- Clobberbottom's Boomer
      169681, -- BOOM-TASTIC 3000
      211963, -- Ceiling Sweeper
    },
    [150] = {
      46954,  -- Flaming Spears
      153204, -- All-Seer's Eye
      192750, -- Black Iron Javelin
    },
    [200] = {
      75208,  -- Rancher's Lariat
      86546,  -- Sky Crystal
      89163,  -- Requisitioned Firework Launcher
      152657, -- Target Designator
    },
    -- [50000] = {
    --   130867, -- Tag Toy
    --   136403, -- Staff of Four Winds
    --   146406, -- Vantus Rune: Tomb of Sargeras
    --   151610, -- Vantus Rune: Antorus, the Burning Throne
    --   153673, -- Vantus Rune: Uldir
    --   165692, -- Vantus Rune: Battle of Dazar'alor
    --   165733, -- Vantus Rune: Crucible of Storms
    --   168624, -- Vantus Rune: The Eternal Palace
    --   171203, -- Vantus Rune: Ny'alotha, the Waking City
    --   173067, -- Vantus Rune: Castle Nathria
    --   186662, -- Vantus Rune: Sanctum of Domination
    --   187805, -- Vantus Rune: Sepulcher of the First Ones
    --   189584, -- Sepulcher's Savior
    --   198491, -- Vantus Rune: Vault of the Incarnates
    --   198492, -- Vantus Rune: Vault of the Incarnates
    --   198493, -- Vantus Rune: Vault of the Incarnates
    --   204858, -- Vantus Rune: Aberrus, the Shadowed Crucible
    --   204859, -- Vantus Rune: Aberrus, the Shadowed Crucible
    --   204860, -- Vantus Rune: Aberrus, the Shadowed Crucible
    --   210247, -- Vantus Rune: Amirdrassil, the Dream's Hope
    --   210248, -- Vantus Rune: Amirdrassil, the Dream's Hope
    --   210249, -- Vantus Rune: Amirdrassil, the Dream's Hope
    -- },
  }
end

local HarmItems
if isEra then
  HarmItems = {
    [5] = {
      8149,   -- Voodoo Charm
      15826,  -- Curative Animal Salve
      16308,  -- Northridge Crowbar
      17117,  -- Rat Catcher's Flute
      22259,  -- Unbestowed Friendship Bracelet
      22432,  -- Devilsaur Barb
      206466, -- Prairie Crown
      208760, -- Glade Crown
      208855, -- Rainbow Fin Albacore Chum
      209027, -- Crab Treats
      209057, -- Prototype Engine
      213036, -- Water of Elune'ara
      221199, -- Satyrweed Tincture
      225943, -- Rancid Hunk of Flesh
    },
    [10] = {
      9606,   -- Treant Muisek Vessel
      9618,   -- Wildkin Muisek Vessel
      9619,   -- Hippogryph Muisek Vessel
      9620,   -- Faerie Dragon Muisek Vessel
      9621,   -- Mountain Giant Muisek Vessel
      10699,  -- Yeh'kinya's Bramble
      17626,  -- Frostwolf Muzzle
      17689,  -- Stormpike Training Collar
      226472, -- Stratholme Shadow Jar
    },
    [15] = {
      4559,   -- CHU's QUEST ITEM
    },
    [20] = {
      1191,   -- Bag of Marbles
      2012,   -- Deprecated Phylactery of Rot
      4388,   -- Discombobulator Ray
      10645,  -- Gnomish Death Ray
      13892,  -- Kodo Kombobulator
      17757,  -- Amulet of Spirits
      18209,  -- Energized Sparkplug
      22048,  -- Lord Valthalak's Amulet
      202251, -- Bag of Pet Treats
      227936, -- Diplomat Ring
      232344, -- Vick's VIP Pass
    },
    [25] = {
      13289,  -- Egan's Blaster
    },
    [30] = {
      835,    -- Large Rope Net
      1404,   -- Tidal Charm
      1434,   -- Glowing Wax Stick
      1444,   -- Deprecated Inferno Stone
      1472,   -- Deprecated Polished Lakestone Charm
      1704,   -- Deprecated Cold Basilisk Eye
      1854,   -- Deprecated Brooch of the Night Watch
      1914,   -- Deprecated Miniature Silver Hammer
      1995,   -- Deprecated Cat's Paw
      2091,   -- Magic Dust
      3434,   -- Slumber Sand
      3441,   -- Deprecated Crippling Agent
      4479,   -- Burning Charm
      4480,   -- Thundering Charm
      4481,   -- Cresting Charm
      4941,   -- Really Sticky Glue
      5079,   -- Cold Basilisk Eye
      5457,   -- Severed Voodoo Claw
      6436,   -- Burning Gem
      7344,   -- Torch of Holy Flame
      7734,   -- Six Demon Bag
      9328,   -- Super Snapper FX
      9394,   -- Horned Viking Helmet
      10588,  -- Goblin Rocket Helmet
      10716,  -- Gnomish Shrink Ray
      10720,  -- Gnomish Net-o-Matic Projector
      11170,  -- Deprecated Silver Totem of Aquementas
      11522,  -- Silver Totem of Aquementas
      11565,  -- Crystal Yield
      12288,  -- Encased Corrupt Ooze
      12646,  -- Infus Emerald
      12647,  -- Felhas Ruby
      13213,  -- Smolderweb's Eye
      13509,  -- Clutch of Foresight
      13514,  -- Wail of the Banshee
      17202,  -- Snowball
      17310,  -- Aspect of Neptulon
      20084,  -- Hunting Net
      20908,  -- Festival of Nian Firework
      21038,  -- Hardpacked Snowball
      21713,  -- Elune's Candle
      22200,  -- Silver Shafted Arrow
      22206,  -- Bouquet of Red Roses
      22218,  -- Handful of Rose Petals
      220649, -- Merithra's Inheritence
      228576, -- Smolderweb's Eye
      233226, -- Ancient Zandalarian Rope
    },
    [35] = {
      996,    -- Ring of Righteous Flame (TEST)
      1258,   -- Bind On Use Test Item
      1399,   -- Magic Candle
      1402,   -- Brimstone
      8688,   -- Bind On Acquire Test Item
      18904,  -- Zorbin's Ultra-Shrinker
      220568, -- Temple Explorer's Gun Axe
      233216, -- Freez-O-Matic Ray
    },
    [40] = {
      4945,   -- Faintly Glowing Skull
      8348,   -- Helm of Fire
      191414, -- Skeletal Artifact
      208773, -- Fishing Harpoon
      208843, -- Battle Totem
      209047, -- Gnarled Harpoon
    },
    [45] = {
      221316, -- Premo's Poise-Demanding Uniform
    },
    [100] = {
      5418,   -- Weapon of Mass Destruction (test)
      17162,  -- Eric Test Item A
      23715,  -- Permanent Lung Juice Cocktail
      23718,  -- Permanent Ground Scorpok Assay
      23719,  -- Permanent Cerebral Cortex Compound
      23721,  -- Permanent Gizzard Gum
      23722,  -- Permanent R.O.I.D.S.
      227685, -- Modified Shadow Scalpel
    },
    -- [50000] = {
    --   228227, -- Scroll of Overwhelming Power
    -- },
  }
elseif isCata then
  HarmItems = {
    [3] = {
      42732,  -- Everfrost Razor
    },
    [5] = {
      8149,   -- Voodoo Charm
      15826,  -- Curative Animal Salve
      17117,  -- Rat Catcher's Flute
      22259,  -- Unbestowed Friendship Bracelet
      22432,  -- Devilsaur Barb
      23485,  -- Empty Birdcage
      23659,  -- Fel-Tainted Morsels
      33310,  -- The Sergeant's Machete
      33342,  -- The Brave's Machete
      33554,  -- Grick's Bonesaw
      33563,  -- Forsaken Banner
      33806,  -- Runeseeking Pick
      34954,  -- Torp's Kodo Snaffle
      34973,  -- Re-Cursive Transmatter Injection
      35116,  -- The Ultrasonic Screwdriver
      35401,  -- The Greatmother's Soulcatcher
      35736,  -- Bounty Hunter's Cage
      36771,  -- Sturdy Crates
      36786,  -- Bark of the Walkers
      36956,  -- Liquid Fire of Elune
      37045,  -- Kilian's Camera
      37125,  -- Rokar's Camera
      37187,  -- Container of Rats
      37202,  -- Onslaught Riding Crop
      37568,  -- Renewing Tourniquet
      37576,  -- Renewing Bandage
      38330,  -- Crusader's Bandage
      38467,  -- Softknuckle Poker
      38627,  -- Mammoth Harness
      38676,  -- Whisker of Har'koa
      38731,  -- Ahunae's Knife
      40587,  -- Darkmender's Tincture
      45001,  -- Medicated Salve
      45080,  -- Large Femur
      49743,  -- Sten's First Aid Kit
      49948,  -- Calder's Bonesaw
      50742,  -- Tara's Tar Scraper
      50746,  -- Tara's Tar Scraper
      52014,  -- Herb-Soaked Bandages
      52271,  -- Northwatch Manacles
      52712,  -- Remote Control Fireworks
      53120,  -- Bottled Bileberry Brew
      56837,  -- Sturdy Manacles
      58502,  -- Explosive Bonding Compound
      58885,  -- Rockslide Reagent
      58955,  -- Razgar's Fillet Knife
      58965,  -- Deepvein's Patch Kit
      61302,  -- Light-Touched Blades
      63150,  -- Shovel
      63427,  -- Worgsaw
      65667,  -- Shovel of Mercy
      67232,  -- Sullah's Pygmy Pen
      71978,  -- Darkmoon Bandage
      72110,  -- Battered Wrench
    },
    [7] = {
      61323,  -- Ruby Seeds
      62899,  -- Enchanted Imp Sack
      63350,  -- Razor-Sharp Scorpid Barb
    },
    [8] = {
      29052,  -- Warp Nether Extractor
      33278,  -- Burning Torch
      34368,  -- Attuned Crystal Cores
      35943,  -- Jeremiah's Tools
      37932,  -- Miner's Lantern
      56821,  -- Oil Extrusion Pump
      68678,  -- Child Safety Harness
    },
    [10] = {
      9606,   -- Treant Muisek Vessel
      9618,   -- Beast Muisek Vessel
      9619,   -- Hippogryph Muisek Vessel
      9620,   -- Faerie Dragon Muisek Vessel
      9621,   -- Mountain Giant Muisek Vessel
      10699,  -- Yeh'kinya's Bramble
      17626,  -- Frostwolf Muzzle
      17689,  -- Stormpike Training Collar
      22896,  -- Healing Crystal
      22962,  -- Inoculating Crystal
      28547,  -- Elemental Power Extractor
      30656,  -- Protovoltaic Magneto Collector
      32321,  -- Sparrowhawk Net
      33418,  -- Tillinghast's Plague Canister
      34083,  -- Awakening Rod
      34250,  -- Skill: Throw Bullet
      35293,  -- Cenarion Horn
      36859,  -- Snow of Eternal Slumber
      37307,  -- Purified Ashes of Vordrassil
      38697,  -- Jungle Punch Sample
      40551,  -- Gore Bladder
      41988,  -- Telluric Poultice
      42164,  -- Hodir's Horn
      43059,  -- Drakuru's Last Wish
      44576,  -- Bright Flare
      47033,  -- Light-Blessed Relic
      50131,  -- Snagglebolt's Air Analyzer
      52709,  -- Gnomish Playback Device
      52819,  -- Frostgale Crystal
      53009,  -- Juniper Berries
      54215,  -- Vol'jin's War Drums
      54462,  -- Moanah's Baitstick
      54463,  -- Flameseer's Staff
      56012,  -- Stone Knife of Sealing
      56222,  -- Runes of Return
      56794,  -- Subjugator Devo's Whip
      58167,  -- Spirit Totem
      58200,  -- Techno-Grenade
      58203,  -- Paintinator
      60382,  -- Mylra's Knife
      60870,  -- Barrel of Explosive Ale
      62057,  -- Teleport Beacon
      62326,  -- Heavy Manacles
      62541,  -- Heavy Manacles
      64312,  -- Totem of Freedom
      67249,  -- Viewpoint Equalizer
      68677,  -- Moldy Lunch
      68679,  -- Goblin Gas Tank
      68682,  -- Inflatable Lifesaver
      69240,  -- Enchanted Salve
    },
    [15] = {
      30651,  -- Dertrok's First Wand
      30652,  -- Dertrok's Second Wand
      30653,  -- Dertrok's Third Wand
      30654,  -- Dertrok's Fourth Wand
      31129,  -- Blackwhelp Net
      32907,  -- Wolpertinger Net
      33069,  -- Sturdy Rope
      33621,  -- Plague Spray
      36764,  -- Shard of the Earth
      38573,  -- RJR Rifle
      39268,  -- Medallion of Mam'toth
      42480,  -- Ebon Blade Banner
      44959,  -- Soothing Totem
      46722,  -- Grol'dom Net
      50741,  -- Vile Fumigator's Mask
      52481,  -- Blastshadow's Soulstone
      53101,  -- Tessina's Wisp Call
      53104,  -- Tessina's Hippogryph Call
      53105,  -- Tessina's Treant Call
      54455,  -- Paint Bomb
      56180,  -- Duarn's Net UNUSED
      56184,  -- Duarn's Net
      58169,  -- Elementium Grapple Line
      58966,  -- Jesana's Faerie Dragon Call
      58967,  -- Jesana's Giant Call
    },
    [20] = {
      1191,   -- Bag of Marbles
      4388,   -- Discombobulator Ray
      10645,  -- Gnomish Death Ray
      13892,  -- Kodo Kombobulator
      17757,  -- Amulet of Spirits
      18209,  -- Energized Sparkplug
      22048,  -- Lord Valthalak's Amulet
      22473,  -- Antheol's Disciplinary Rod
      22783,  -- Sunwell Blade
      22784,  -- Sunwell Orb
      23394,  -- Healing Salve
      23655,  -- Elven Manacles
      23693,  -- Carinda's Scroll of Retribution
      29513,  -- Staff of the Dreghood Elders
      29817,  -- Talbuk Tagger
      29818,  -- Energy Field Modulator
      30175,  -- Gor'drek's Ointment
      30259,  -- Voren'thal's Presence
      31518,  -- Exorcism Feather
      31678,  -- Mental Interference Rod
      32424,  -- Blade's Edge Ogre Brew
      33088,  -- Brogg's Totem
      33796,  -- Rune of Command
      34127,  -- Tasty Reef Fish
      34257,  -- Fel Siphon
      34711,  -- Core of Malice
      34869,  -- Warsong Banner
      36796,  -- Gavrock's Runebreaker
      36827,  -- Blood Gem
      36835,  -- Unholy Gem
      36847,  -- Frost Gem
      37708,  -- Stick
      39157,  -- Scepter of Suggestion
      39206,  -- Scepter of Empowerment
      39238,  -- Scepter of Command
      39577,  -- Rejek's Blade
      39651,  -- Venture Co. Explosives
      39664,  -- Scepter of Domination
      40397,  -- Lifeblood Gem
      42624,  -- Battered Storm Hammer
      42894,  -- Horn of Elemental Fury
      43206,  -- War Horn of Acherus
      43315,  -- Sigil of the Ebon Blade
      44889,  -- Blessed Herb Bundle
      44975,  -- Orb of Elune
      46363,  -- Lifebringer Sapling
      48104,  -- The Refleshifier
      49202,  -- Black Gunpowder Keg
      50053,  -- Bloodtalon Lasso
      52044,  -- Bilgewater Cartel Promotional Delicacy Morsels
      52073,  -- Bramblestaff
      52484,  -- Kaja'Cola Zero-One
      52566,  -- Motivate-a-Tron
      53107,  -- Flameseer's Staff
      55141,  -- Spiralung
      55158,  -- Fake Treasure
      55230,  -- Soul Stick
      56798,  -- Jin'Zil's Voodoo Stick
      57920,  -- Revantusk War Drums
      58177,  -- Earthen Ring Proclamation
      63079,  -- Titanium Shackles
      63426,  -- Lethality Analyzer
      67241,  -- Sullah's Camel Harness
      68606,  -- Murloc Leash
      68607,  -- Candy Cleanser
      71085,  -- Runestaff of Nordrassil
    },
    [25] = {
      13289,  -- Egan's Blaster
      24268,  -- Netherweave Net
      31463,  -- Zezzak's Shard
      32408,  -- Naj'entus Spine
      32966,  -- DEBUG - Headless Horseman - Start Fire
      34979,  -- Pouch of Crushed Bloodspore
      46885,  -- Weighted Net
      49649,  -- Impaling Spine
      50307,  -- Infernal Spear
      55049,  -- Fang of Goldrinn
      55050,  -- Fang of Lo'Gosh
    },
    [30] = {
      835,    -- Large Rope Net
      1399,   -- Magic Candle
      1404,   -- Tidal Charm
      1434,   -- Glowing Wax Stick
      1472,   -- Deprecated Polished Lakestone Charm
      1704,   -- Deprecated Cold Basilisk Eye
      1854,   -- Deprecated Brooch of the Night Watch
      1914,   -- Deprecated Miniature Silver Hammer
      1995,   -- Deprecated Cat's Paw
      2091,   -- Magic Dust
      3434,   -- Slumber Sand
      3441,   -- Deprecated Crippling Agent
      4479,   -- Burning Charm
      4480,   -- Thundering Charm
      4481,   -- Cresting Charm
      4941,   -- Really Sticky Glue
      5079,   -- Cold Basilisk Eye
      5457,   -- Severed Voodoo Claw
      6436,   -- Burning Gem
      7734,   -- Six Demon Bag
      9328,   -- Super Snapper FX
      9394,   -- Horned Viking Helmet
      10588,  -- Goblin Rocket Helmet
      10716,  -- Gnomish Shrink Ray
      10720,  -- Gnomish Net-o-Matic Projector
      11170,  -- Deprecated Silver Totem of Aquementas
      11522,  -- Silver Totem of Aquementas
      11565,  -- Crystal Yield
      12288,  -- Encased Corrupt Ooze
      12646,  -- Infus Emerald
      12647,  -- Felhas Ruby
      13213,  -- Smolderweb's Eye
      13509,  -- Clutch of Foresight
      13514,  -- Wail of the Banshee
      17202,  -- Snowball
      17310,  -- Aspect of Neptulon
      20084,  -- Hunting Net
      20908,  -- Festival of Nian Firework
      21038,  -- Hardpacked Snowball
      21713,  -- Elune's Candle
      22200,  -- Silver Shafted Arrow
      22206,  -- Bouquet of Red Roses
      22218,  -- Handful of Rose Petals
      23337,  -- Cenarion Antidote
      23417,  -- Sanctified Crystal
      23835,  -- Gnomish Poultryizer
      23995,  -- Murloc Tagger
      30811,  -- Scroll of Demonic Unbanishing
      30854,  -- Book of Fel Names
      31403,  -- Sablemane's Sleeping Powder
      31809,  -- Evergrove Wand
      31828,  -- Ritual Prayer Beads
      32680,  -- Booterang
      32960,  -- Elekk Dispersion Ray
      33108,  -- Ooze Buster
      33606,  -- Lurielle's Pendant
      33607,  -- Enchanted Ice Core
      33865,  -- Amani Hex Stick
      34068,  -- Weighted Jack-o'-Lantern
      34191,  -- Handful of Snowflakes
      34598,  -- The King's Empty Conch
      34684,  -- Handful of Summer Petals
      35557,  -- Huge Snowball
      36732,  -- Potent Explosive Charges
      38331,  -- Emerald Quill DEPRECATED
      38515,  -- Tangled Skein Thrower
      40686,  -- U.D.E.D.
      40917,  -- Lord-Commander's Nullifier
      41121,  -- Gnomish Lightning Generator
      42774,  -- Arngrim's Tooth
      43166,  -- The Bone Witch's Amulet
      43663,  -- Stormbound Tome
      44246,  -- Orb of Illusion
      44414,  -- Soul Lash
      44653,  -- Volatile Acid
      44731,  -- Bouquet of Ebon Roses
      44915,  -- Elune's Candle
      45073,  -- Spring Flowers
      49138,  -- Bottle of Leeches
      49199,  -- Infernal Power Core
      49219,  -- Infernal Power Core
      49882,  -- Soothing Seeds
      50163,  -- Lovely Rose
      52710,  -- Enchanted Conch
      52715,  -- Butcherbot Control Gizmo
      56069,  -- Alliance Weapon Crate
      56227,  -- Enchanted Conch
      57172,  -- Attuned Runestone of Binding
      58935,  -- Gryphon Chow
      60861,  -- Holy Thurible
      64637,  -- Tanrir's Overcharged Totem
      69825,  -- Essence Gatherer
    },
    [35] = {
      16103,  -- Test Enchant Boots Stamina
      18904,  -- Zorbin's Ultra-Shrinker
      24269,  -- Heavy Netherweave Net
      24501,  -- Gordawg's Boulder
      35121,  -- Wolf Bait
      39158,  -- Quetz'lun's Hexxing Stick
      41505,  -- Thorim's Charm of Earth
      41509,  -- Frostweave Net
      44890,  -- To'kini's Blowgun
      49028,  -- Nitro-Potassium Bananas
      54442,  -- Embersilk Net
      56576,  -- Orb of Suggestion
    },
    [40] = {
      996,    -- Ring of Righteous Flame (TEST)
      1258,   -- Bind On Use Test Item
      2012,   -- Deprecated Phylactery of Rot
      4945,   -- Faintly Glowing Skull
      8688,   -- Bind On Acquire Test Item
      24420,  -- Unique Equippable Test Item
      28767,  -- The Decapitator
      33581,  -- Vrykul Insult
      34255,  -- Razorthorn Flayer Gland
      37438,  -- Rod of Compulsion
      38332,  -- Modified Mojo
      38380,  -- Zul'Drak Rat
      39615,  -- Crusader Parachute
      44114,  -- Old Spices
      44222,  -- Dart Gun
      44228,  -- Baby Spice
      44804,  -- Indalamar's Debuffer
      44812,  -- Turkey Shooter
      44832,  -- Squirt Gun [PH]
      50430,  -- Scraps of Rotting Meat
      52490,  -- Stardust
      53794,  -- Rendel's Bridle
      55165,  -- Enchanted Sea Snack
      56169,  -- Breathstone
      56847,  -- Chelsea's Nightmare
      60490,  -- The Axe of Earthly Sundering
      60808,  -- Mutant Bush Chicken Cage
      65162,  -- Emergency Pool Pony
      65357,  -- Rainbow Generator
      69826,  -- Glacial Grenade
      69832,  -- Burd Sticker
      206272, -- Holy Hand Grenade
    },
    [45] = {
      23836,  -- Goblin Rocket Launcher
      28369,  -- Battery Recharging Blaster
      32698,  -- Wrangling Rope
      34691,  -- Arcane Binder
      34812,  -- Crafty's Ultra-Advanced Proto-Typical Shortening Blaster
      35352,  -- Sage's Lightning Rod
      35485,  -- Goblin Rocket Launcher [PH]
      35499,  -- Ninja Grenade [PH]
      49647,  -- Drum of the Soothed Earth
      52059,  -- Murloc Leash
      52833,  -- Modified Soul Orb
      62794,  -- Licensed Proton Accelerator Cannon
      64445,  -- Banshee Mirror
    },
    [60] = {
      32825,  -- Soul Cannon
      34111,  -- Trained Rock Falcon
      34121,  -- Trained Rock Falcon
      37877,  -- Silver Feather
      37887,  -- Seeds of Nature's Wrath
      49700,  -- SFG
      50851,  -- Pulsing Life Crystal
      52043,  -- Bootzooka
    },
    [70] = {
      41265,  -- Eyesore Blaster
    },
    [80] = {
      28131,  -- Reaver Buster Launcher
      35278,  -- Reinforced Net
      35506,  -- Raelorasz's Spear
      42769,  -- Spear of Hodir
      49596,  -- Cryomatic 16
      50031,  -- Tomusa's Hook
      62775,  -- Barbed Fleshhook
      63092,  -- Wyrmhunter Hooks
      63104,  -- Elemental Nullifier
      63393,  -- Shoulder-Mounted Drake-Dropper
    },
    [100] = {
      17162,  -- Eric Test Item A
      23715,  -- Permanent Lung Juice Cocktail
      23718,  -- Permanent Ground Scorpok Assay
      23719,  -- Permanent Cerebral Cortex Compound
      23721,  -- Permanent Gizzard Gum
      23722,  -- Permanent R.O.I.D.S.
      28025,  -- Video Mount
      29877,  -- Indalamar's Super Hot
      30292,  -- My Little Friend
      33119,  -- Malister's Frost Wand
      34151,  -- Player, Draenei/Tauren
      34152,  -- Player, Dwarf/Orc
      34153,  -- Player, Gnome/Blood Elf
      34154,  -- Player, Human/Undead
      34155,  -- Player, Troll/Night Elf
      41058,  -- Hyldnir Harpoon
      44212,  -- SGM-3
    },
    [150] = {
      46954,  -- Flaming Spears
    },
    -- [50000] = {
    --   5418,   -- Weapon of Mass Destruction (test)
    --   28261,  -- Video Invis
    --   29025,  -- [UNUSED]Triangulation Device
    --   34026,  -- Feathered Charm
    -- },
  }
else
  HarmItems = {
    [2] = {
      168948, -- Dried Kelp
      194718, -- Premium Salamander Feed
    },
    [3] = {
      42732,  -- Everfrost Razor
      200469, -- Khadgar's Disenchanting Rod
    },
    [4] = {
      129055, -- Shoe Shine Kit
    },
    [5] = {
      8149,   -- Voodoo Charm
      15826,  -- Curative Animal Salve
      17117,  -- Rat Catcher's Flute
      22259,  -- Unbestowed Friendship Bracelet
      22432,  -- Devilsaur Barb
      23485,  -- Empty Birdcage
      23659,  -- Fel-Tainted Morsels
      33310,  -- The Sergeant's Machete
      33342,  -- The Brave's Machete
      33554,  -- Grick's Bonesaw
      33563,  -- Forsaken Banner
      33806,  -- Runeseeking Pick
      34954,  -- Torp's Kodo Snaffle
      34973,  -- Re-Cursive Transmatter Injection
      35116,  -- The Ultrasonic Screwdriver
      35401,  -- The Greatmother's Soulcatcher
      35736,  -- Bounty Hunter's Cage
      36771,  -- Sturdy Crates
      36786,  -- Bark of the Walkers
      36956,  -- Liquid Fire of Elune
      37045,  -- Kilian's Camera
      37125,  -- Rokar's Camera
      37187,  -- Container of Rats
      37202,  -- Onslaught Riding Crop
      37568,  -- Renewing Tourniquet
      37576,  -- Renewing Bandage
      38330,  -- Crusader's Bandage
      38467,  -- Softknuckle Poker
      38627,  -- Mammoth Harness
      38676,  -- Whisker of Har'koa
      38731,  -- Ahunae's Knife
      40587,  -- Darkmender's Tincture
      45001,  -- Medicated Salve
      45080,  -- Large Femur
      49948,  -- Calder's Bonesaw
      50742,  -- Tara's Tar Scraper
      50746,  -- Tara's Tar Scraper
      52014,  -- Herb-Soaked Bandages
      52271,  -- Northwatch Manacles
      52712,  -- Remote Control Fireworks
      53120,  -- Bottled Bileberry Brew
      56837,  -- Sturdy Manacles
      58502,  -- Explosive Bonding Compound
      58885,  -- Rockslide Reagent
      58955,  -- Razgar's Fillet Knife
      58965,  -- Deepvein's Patch Kit
      61302,  -- Light-Touched Blades
      63150,  -- Shovel
      63427,  -- Worgsaw
      65667,  -- Shovel of Mercy
      67232,  -- Sullah's Pygmy Pen
      71978,  -- Darkmoon Bandage
      72110,  -- Battered Wrench
      79021,  -- Ken-Ken's Mask
      79057,  -- Ken-Ken's Mask
      79102,  -- Green Cabbage Seeds
      79819,  -- Dit Da Jow
      79932,  -- Qu Mo Mask
      80302,  -- EZ-Gro Green Cabbage Seeds
      80590,  -- Juicycrunch Carrot Seeds
      80591,  -- Scallion Seeds
      80592,  -- Mogu Pumpkin Seeds
      80593,  -- Red Blossom Leek Seeds
      80594,  -- Pink Turnip Seeds
      80595,  -- White Turnip Seeds
      85215,  -- Snakeroot Seed
      85216,  -- Enigma Seed
      85217,  -- Magebulb Seed
      85219,  -- Ominous Seed
      85267,  -- Autumn Blossom Sapling
      85268,  -- Spring Blossom Sapling
      85269,  -- Winter Blossom Sapling
      89197,  -- Windshear Cactus Seed
      89202,  -- Raptorleaf Seed
      89233,  -- Songbell Seed
      89326,  -- Witchberry Seeds
      89328,  -- Jade Squash Seeds
      89329,  -- Striped Melon Seeds
      89880,  -- Dented Shovel
      91806,  -- Unstable Portal Shard
      114835, -- Rooby Reat
      133065, -- Tony Mourdain's Cleaver
      136605, -- Solendra's Compassion
      137299, -- Nightborne Spellblade
      139463, -- Felbat Toxin Salve
      142065, -- Dusk Lily Sigil
      142262, -- Electrified Key
      143597, -- Fruit of the Arcan'dor
      143773, -- Contagion Counteragent
      150759, -- Restorative Balm
      151563, -- Hallowed Prayer Effigy
      151570, -- Lightbound Crystal
      151624, -- Y'mera's Arcanocrystal
      152472, -- Chieftain's Salve
      152630, -- Ranah's Watering Can
      152971, -- Talisman of the Prophet
      152995, -- Sacred Stone
      153049, -- Scroll of Purging
      153112, -- Scroll of Purging
      153496, -- Tasty Treats
      153513, -- Cleansing Tonic
      156518, -- Lucille's Sewing Needle
      156532, -- Inquisitor's Regalia
      157771, -- Holy Water
      158678, -- Antivenom
      159470, -- Faithless Scimitar
      159782, -- Milk Pail
      160045, -- Antidote Salve
      160429, -- Rope and Hook
      160433, -- Bandages
      160559, -- Scroll of Purification
      160561, -- Goldfield's Knife
      160571, -- Lucille's Sewing Needle
      160585, -- Soulcaller Scroll
      161247, -- Marshal's Regalia
      162450, -- Portal Orb
      162589, -- Alexxi's Foolproof Remedy
      163607, -- Lucille's Sewing Needle
      163720, -- Mildenhall Growth Formula
      163740, -- Drust Ritual Knife
      166972, -- Emergency Powerpack
      166973, -- Emergency Repair Kit
      167041, -- Coiled Current Culler
      168410, -- First Aid Kit
      169653, -- Potion of Mental Clarity
      172020, -- Battered Weapon
      173013, -- Bag of Faerie Dust
      173148, -- Steel Cleaver
      174197, -- Loremaster's Notebook
      174326, -- Rough Burlap Bandages
      177817, -- Voodoo Powder
      180613, -- Fragile Humility Scroll
      181364, -- Cluster of Seeds
      183689, -- Crusader's Dressing
      183698, -- Torturer's Key
      183797, -- Crusader's Dressing
      184622, -- Stygian Hammer
      186445, -- Mikanikos' Restorative Contraption
      186448, -- Mikanikos' Restorative Contraption
      186695, -- Lovely Pet Bandage
      187504, -- Mikanikos' Restorative Contraption
      192467, -- Bandages
      192795, -- Rejuvenating Draught
      194052, -- Forlorn Funeral Pall
      194434, -- Pungent Salve
      197805, -- Suspicious Persons Scanner
      202874, -- Healing Draught
      208124, -- The Dreamer's Essence
      208738, -- Ephemeral Pear
      208985, -- Silly Hat
      213539, -- Nebb's Poultice
      215145, -- Remembrance Stone
      216687, -- Cobbled Together Bandage
      217159, -- Nebb's Improved Poultice
      219385, -- Antiparalytic Serum
      224799, -- Nizrek's potion
    },
    [6] = {
      200868, -- Integrated Primal Fire
      206964, -- Paracausal Fragment of Doomhammer
      207024, -- Paracausal Fragment of Shalamayne
      207165, -- Bandolier of Twisted Blades
      207783, -- Cruel Dreamcarver
      212449, -- Sikran's Endless Arsenal
      219915, -- Foul Behemoth's Chelicera
    },
    [6] = {
      164766, -- Iwen's Enchanting Rod
      219525, -- Globe of Nourishment
    },
    [7] = {
      61323,  -- Ruby Seeds
      62899,  -- Enchanted Imp Sack
      63350,  -- Razor-Sharp Scorpid Barb
      153249, -- Y'mera's Attuning Crystal
    },
    [8] = {
      33278,  -- Burning Torch
      34368,  -- Attuned Crystal Cores
      35943,  -- Jeremiah's Tools
      37932,  -- Miner's Lantern
      56821,  -- Oil Extrusion Pump
      82311,  -- Zouchin Rations
      128776, -- Red Wooden Sled
      152730, -- Sumber's Totem
      178751, -- Spare Meat Hook
      178901, -- Vineseed
    },
    [9] = {
      212453, -- Skyterror's Corrosive Organ
    },
    [10] = {
      9606,   -- Treant Muisek Vessel
      9618,   -- Beast Muisek Vessel
      9619,   -- Hippogryph Muisek Vessel
      9620,   -- Faerie Dragon Muisek Vessel
      9621,   -- Mountain Giant Muisek Vessel
      10699,  -- Yeh'kinya's Bramble
      17626,  -- Frostwolf Muzzle
      17689,  -- Stormpike Training Collar
      22962,  -- Inoculating Crystal
      28547,  -- Elemental Power Extractor
      30656,  -- Protovoltaic Magneto Collector
      32321,  -- Sparrowhawk Net
      33418,  -- Tillinghast's Plague Canister
      34083,  -- Awakening Rod
      35293,  -- Cenarion Horn
      36859,  -- Snow of Eternal Slumber
      37307,  -- Purified Ashes of Vordrassil
      38697,  -- Jungle Punch Sample
      40551,  -- Gore Bladder
      41988,  -- Telluric Poultice
      42164,  -- Hodir's Horn
      43059,  -- Drakuru's Last Wish
      44576,  -- Bright Flare
      47033,  -- Light-Blessed Relic
      50131,  -- Snagglebolt's Air Analyzer
      52709,  -- Gnomish Playback Device
      52819,  -- Frostgale Crystal
      53009,  -- Juniper Berries
      54215,  -- Vol'jin's War Drums
      54462,  -- Moanah's Baitstick
      54463,  -- Flameseer's Staff
      56012,  -- Stone Knife of Sealing
      56222,  -- Runes of Return
      56794,  -- Subjugator Devo's Whip
      58167,  -- Spirit Totem
      58200,  -- Techno-Grenade
      58203,  -- Paintinator
      60382,  -- Mylra's Knife
      60870,  -- Barrel of Explosive Ale
      62057,  -- Teleport Beacon
      62326,  -- Heavy Manacles
      62541,  -- Heavy Manacles
      64312,  -- Totem of Freedom
      67249,  -- Viewpoint Equalizer
      68679,  -- Goblin Gas Tank
      69240,  -- Enchanted Salve
      78947,  -- Silken Rope
      79884,  -- Bucket of Slicky Water
      80220,  -- Forest Remedy
      81177,  -- Pandaren Healing Draught
      82381,  -- Yak's Milk Flask
      86536,  -- Wu Kao Dart of Lethargy
      90067,  -- B. F. F. Necklace
      106958, -- Winterwasp Antidote
      106987, -- Sigil of Karabor
      107656, -- Kaz's Disturbing Crate
      112321, -- Enchanted Dust
      118418, -- Mug of Rousing Coffee
      119440, -- Training Shoes
      124100, -- Moonwater Vial
      129190, -- Rope of Friendship
      132877, -- Eye of Azzorok
      136386, -- Bloodstone
      139584, -- Sticky Bombs
      152278, -- Cracked Wand
      153537, -- Animate Sphere
      153565, -- Shackles
      156549, -- Writ of Sacrifice
      158190, -- Target Marker
      158907, -- Moonstone Pendant
      158908, -- Moonstone Weapon
      166784, -- Narassin's Soul Gem
      166785, -- Detoxified Blight Grenade
      168053, -- Unusually Wise Hermit Crab
      168811, -- Wand of Absorption
      169860, -- Tiny Dapper Hat
      169943, -- Little Princess Cap
      169944, -- Minuscule Fez
      170161, -- Unusually Wise Hermit Crab
      172955, -- Gormherd Branch
      173870, -- Fading Glimmerdust
      174040, -- Chains of Regret
      174323, -- Torch
      175063, -- Aqir Egg Cluster
      184292, -- Ancient Elethium Coin
      184314, -- Broker Device
      187943, -- Fae Net
      193917, -- Rejuvenating Draught
      202096, -- Armaments of the Scale
      202112, -- Crystal Shattering Armaments
      202271, -- Pouch of Gold Coins
      202714, -- M.U.S.T
      205045, -- B.B.F. Fist
      205276, -- Deepflayer Lure
      207632, -- Dream-Attuned Crystal
      219469, -- Fog Beast Tracker
      223322, -- Hannan's Scythe
    },
    [12] = {
      208068, -- Rotten Delicious
    },
    [15] = {
      30651,  -- Dertrok's First Wand
      30652,  -- Dertrok's Second Wand
      30653,  -- Dertrok's Third Wand
      30654,  -- Dertrok's Fourth Wand
      31129,  -- Blackwhelp Net
      32907,  -- Wolpertinger Net
      33069,  -- Sturdy Rope
      33621,  -- Plague Spray
      36764,  -- Shard of the Earth
      38573,  -- RJR Rifle
      39268,  -- Medallion of Mam'toth
      42480,  -- Ebon Blade Banner
      44959,  -- Soothing Totem
      46722,  -- Grol'dom Net
      50741,  -- Vile Fumigator's Mask
      52481,  -- Blastshadow's Soulstone
      53101,  -- Tessina's Wisp Call
      53104,  -- Tessina's Hippogryph Call
      53105,  -- Tessina's Treant Call
      54455,  -- Paint Bomb
      56184,  -- Duarn's Net
      58169,  -- Elementium Grapple Line
      58966,  -- Jesana's Faerie Dragon Call
      58967,  -- Jesana's Giant Call
      79027,  -- Saltback Meat
      115475, -- Vial of Untested Serum
      115533, -- Vial of Refined Serum
      152395, -- Counter Spell Charm
      152613, -- Sar'jun's Torch
      153024, -- Scroll of Combustion
      158935, -- Depleted Soul Shard
      161333, -- Ultra-Safe Electrified Alpaca Lasso
      165723, -- Embiggifier Core
      165762, -- Embiggifier Core
      165815, -- Tranquilizer Dart
      170557, -- Re-Sizer v9.0.1
      173691, -- Anima Drainer
      178051, -- Re-Sizer v9.0.1
      179359, -- Sinstone Fragment
      179921, -- Hydra Gutter
      179978, -- Infused Animacones
      179983, -- Infused Animacones
      186089, -- Niya's Staff
      186102, -- Lady Moonberry's Wand
      186199, -- Lady Moonberry's Wand
      186569, -- Angry Needler Nest
      188252, -- Chains of Domination
      189384, -- Ornithological Medical Kit
      193064, -- Smoke Diffuser
      197928, -- Captivating Cap
      219322, -- Malodorous Philter
      219323, -- Gelatinous Unguent
      219324, -- Roiling Elixir
      224194, -- Fashion Frenzy Ribbon
    },
    [20] = {
      1191,   -- Bag of Marbles
      4388,   -- Discombobulator Ray
      10645,  -- Gnomish Death Ray
      13892,  -- Kodo Kombobulator
      17757,  -- Amulet of Spirits
      22048,  -- Lord Valthalak's Amulet
      22473,  -- Antheol's Disciplinary Rod
      22783,  -- Sunwell Blade
      22784,  -- Sunwell Orb
      23394,  -- Healing Salve
      23693,  -- Carinda's Scroll of Retribution
      29513,  -- Staff of the Dreghood Elders
      29817,  -- Talbuk Tagger
      29818,  -- Energy Field Modulator
      30175,  -- Gor'drek's Ointment
      30259,  -- Voren'thal's Presence
      31518,  -- Exorcism Feather
      31678,  -- Mental Interference Rod
      33088,  -- Brogg's Totem
      33796,  -- Rune of Command
      34127,  -- Tasty Reef Fish
      34257,  -- Fel Siphon
      34711,  -- Core of Malice
      34869,  -- Warsong Banner
      36796,  -- Gavrock's Runebreaker
      36827,  -- Blood Gem
      36835,  -- Unholy Gem
      36847,  -- Frost Gem
      37708,  -- Stick
      39157,  -- Scepter of Suggestion
      39206,  -- Scepter of Empowerment
      39238,  -- Scepter of Command
      39577,  -- Rejek's Blade
      39651,  -- Venture Co. Explosives
      39664,  -- Scepter of Domination
      40397,  -- Lifeblood Gem
      42624,  -- Battered Storm Hammer
      42894,  -- Horn of Elemental Fury
      43206,  -- War Horn of Acherus
      43315,  -- Sigil of the Ebon Blade
      44889,  -- Blessed Herb Bundle
      44975,  -- Orb of Elune
      46363,  -- Lifebringer Sapling
      48104,  -- The Refleshifier
      49202,  -- Black Gunpowder Keg
      52044,  -- Bilgewater Cartel Promotional Delicacy Morsels
      52073,  -- Bramblestaff
      52484,  -- Kaja'Cola Zero-One
      52566,  -- Motivate-a-Tron
      53107,  -- Flameseer's Staff
      55141,  -- Spiralung
      55158,  -- Fake Treasure
      55230,  -- Soul Stick
      56798,  -- Jin'Zil's Voodoo Stick
      57920,  -- Revantusk War Drums
      58177,  -- Earthen Ring Proclamation
      63079,  -- Titanium Shackles
      63426,  -- Lethality Analyzer
      67241,  -- Sullah's Camel Harness
      68606,  -- Murloc Leash
      71085,  -- Runestaff of Nordrassil
      77475,  -- Stack of Mantras
      80074,  -- Celestial Jade
      85884,  -- Sonic Emitter
      87558,  -- Ella's Brew
      87763,  -- Ella's Brew
      91902,  -- Universal Remote
      93180,  -- Re-Configured Remote
      93751,  -- Blessed Torch
      93806,  -- Resonance Siphon
      94123,  -- Attuned Crystal
      102464, -- Black Ash
      103786, -- \"Dapper Gentleman\" Costume
      103789, -- \"Little Princess\" Costume
      103795, -- \"Dread Pirate\" Costume
      103797, -- Big Pink Bow
      114967, -- Torch
      116172, -- Perky Blaster
      116810, -- \"Mad Alchemist\" Costume
      116811, -- \"Lil' Starlet\" Costume
      116812, -- \"Yipp-Saron\" Costume
      118414, -- Awesomefish
      118415, -- Grieferfish
      118511, -- Tyfish
      118905, -- Sinister Spores
      124506, -- Vial of Fel Cleansing
      127707, -- Indestructible Bone
      128634, -- Mysterious Brew
      128650, -- \"Merry Munchkin\" Costume
      130260, -- Thaedris's Elixir
      131760, -- Cleansing Ritual Focus
      133647, -- Gift of Radiance
      134119, -- Overloaded Collar
      134824, -- \"Sir Pugsington\" Costume
      134860, -- Peddlefeet's Buffing Creme
      137538, -- Orb of Torment
      142260, -- Arcane Nullifier
      142494, -- Purple Blossom
      142495, -- Fake Teeth
      142496, -- Dirty Spoon
      142497, -- Tiny Pack
      151135, -- Stein of Grog
      151763, -- Crab Trap
      152590, -- Wicker Charm
      153350, -- Repurposed Gilnean Staff
      162631, -- Souvenir Tiki Tumbler
      166230, -- Re-Discombobulator
      167071, -- Mechano-Treat
      167091, -- Maedin's Scroll
      168122, -- NRG-100
      168525, -- Poison Globule
      169069, -- Wraps of Electrostatic Potential
      173534, -- Gormherd Branch
      174749, -- Bone Splinter
      178940, -- Vashj's Signal
      183105, -- Tormentor's Rod
      184505, -- \"Adorable Ascended\" Costume
      184506, -- \"Flying Faerie\" Costume
      186094, -- Siphoning Device
      187708, -- Broken Helm
      187816, -- Irresistible Goop
      187839, -- Tonal Jammer
      188002, -- Broken Helm
      188697, -- Kinematic Micro-Life Recalibrator
      189449, -- Jiro Scan
      189479, -- Chromatic Rosid
      189561, -- Tame Prime: Orixal
      189572, -- Tame Prime: Hadeon the Stonebreaker
      189573, -- Tame Prime: Garudeon
      191408, -- Explosive Pie
      191682, -- Explosive Pie
      191854, -- Briny Seawater
      191865, -- Bottle of Briny Seawater
      192477, -- [PH] Primalist Keystone
      192743, -- Wild Bushfruit
      194447, -- Totem of Respite
      198355, -- Tyrhold Conduit
      202613, -- Zaqali Chaos Grapnel
      202875, -- Snail Lasso
      203383, -- Notes on Dragonkin Equality
      203390, -- Maldra's Ring of Elemental Binding
      203706, -- Hurricane Scepter
      205980, -- Snail Lasso
      208884, -- Root Restoration Fruit
      211535, -- Scroll of Shattering
      229413, -- \"Dogg-Saron\" Costume
    },
    [25] = {
      13289,  -- Egan's Blaster
      24268,  -- Netherweave Net
      31463,  -- Zezzak's Shard
      32408,  -- Naj'entus Spine
      34979,  -- Pouch of Crushed Bloodspore
      46885,  -- Weighted Net
      49649,  -- Impaling Spine
      50307,  -- Infernal Spear
      55049,  -- Fang of Goldrinn
      55050,  -- Fang of Lo'Gosh
      74771,  -- Staff of Pei-Zhi
      86567,  -- Yaungol Wind Chime
      104298, -- Ordon Death Chime
      117013, -- Wand of Lightning Shield
      117015, -- Wand of Mana Stealing
      153012, -- Poisoned Mojo Flask
      170540, -- Ravenous Anima Cell
      195519, -- Kharnalex, The First Light
      198088, -- Darkmoon Deck: Dance
      198478, -- Darkmoon Deck Box: Dance
      202855, -- Maldra's Ring of Elemental Binding
      204274, -- Ancient Memories
      204808, -- Empowered Temporal Gossamer
      206448, -- Fyr'alath the Dreamrender
      208846, -- Restored Dreamleaf
      209349, -- Lydiara's Notes on Rune Reagents
      210010, -- Erden's Notes on Symbiotic Spores
      210011, -- Shalasar's Notes on Sophic Magic
      210199, -- Tattered Dreamleaf
      210881, -- Cunning Charm
      228996, -- Relic of Crystal Connections
    },
    [30] = {
      835,    -- Large Rope Net
      1399,   -- Magic Candle
      1434,   -- Glowing Wax Stick
      4479,   -- Burning Charm
      4480,   -- Thundering Charm
      4481,   -- Cresting Charm
      4941,   -- Really Sticky Glue
      5079,   -- Cold Basilisk Eye
      5457,   -- Severed Voodoo Claw
      6436,   -- Burning Gem
      7734,   -- Six Demon Bag
      9328,   -- Super Snapper FX
      10716,  -- Gnomish Shrink Ray
      10720,  -- Gnomish Net-o-Matic Projector
      11522,  -- Silver Totem of Aquementas
      11565,  -- Crystal Yield
      12288,  -- Encased Corrupt Ooze
      12646,  -- Infus Emerald
      12647,  -- Felhas Ruby
      13213,  -- Smolderweb's Eye
      13514,  -- Wail of the Banshee
      17202,  -- Snowball
      17310,  -- Aspect of Neptulon
      21038,  -- Hardpacked Snowball
      21713,  -- Elune's Candle
      22200,  -- Silver Shafted Arrow
      22218,  -- Handful of Rose Petals
      23337,  -- Cenarion Antidote
      23417,  -- Sanctified Crystal
      23835,  -- Gnomish Poultryizer
      23995,  -- Murloc Tagger
      30811,  -- Scroll of Demonic Unbanishing
      30854,  -- Book of Fel Names
      31403,  -- Sablemane's Sleeping Powder
      31809,  -- Evergrove Wand
      31828,  -- Ritual Prayer Beads
      32680,  -- Booterang
      32960,  -- Elekk Dispersion Ray
      33108,  -- Ooze Buster
      33606,  -- Lurielle's Pendant
      33607,  -- Enchanted Ice Core
      33865,  -- Amani Hex Stick
      34068,  -- Weighted Jack-o'-Lantern
      34191,  -- Handful of Snowflakes
      34598,  -- The King's Empty Conch
      34684,  -- Handful of Summer Petals
      35557,  -- Huge Snowball
      36732,  -- Potent Explosive Charges
      38515,  -- Tangled Skein Thrower
      40354,  -- Monster Slayer's Kit
      40686,  -- U.D.E.D.
      40917,  -- Lord-Commander's Nullifier
      41121,  -- Gnomish Lightning Generator
      42774,  -- Arngrim's Tooth
      43166,  -- The Bone Witch's Amulet
      43663,  -- Stormbound Tome
      44246,  -- Orb of Illusion
      44653,  -- Volatile Acid
      44915,  -- Elune's Candle
      45073,  -- Spring Flowers
      49138,  -- Bottle of Leeches
      49199,  -- Infernal Power Core
      49882,  -- Soothing Seeds
      50163,  -- Lovely Rose
      52710,  -- Enchanted Conch
      52715,  -- Butcherbot Control Gizmo
      56069,  -- Alliance Weapon Crate
      56227,  -- Enchanted Conch
      57172,  -- Attuned Runestone of Binding
      58935,  -- Gryphon Chow
      60861,  -- Holy Thurible
      64637,  -- Tanrir's Overcharged Totem
      69825,  -- Essence Gatherer
      80337,  -- Ken-Ken's Mask
      85231,  -- Bag of Clams
      86589,  -- Ai-Li's Skymirror
      92019,  -- The Bilgewater Molotov
      93159,  -- Enchanted Sleeping Dust
      101677, -- Thunderlord Grapple
      110490, -- Larry Bugged Item
      110492, -- Flamewrought Jewel
      114983, -- Sticky Grenade Launcher
      116119, -- Ango'rosh Sorcerer Stone
      116648, -- Manufactured Love Prism
      116651, -- True Love Prism
      117438, -- Gnomish Net Launcher
      118179, -- Talbuk Lasso
      118181, -- Clefthoof Lasso
      118182, -- Wolf Lasso
      118183, -- Riverbeast Lasso
      118184, -- Elekk Lasso
      118185, -- Boar Lasso
      118283, -- Wolf Lasso
      118284, -- Talbuk Lasso
      118285, -- Riverbeast Lasso
      118286, -- Elekk Lasso
      118287, -- Clefthoof Lasso
      118288, -- Boar Lasso
      118643, -- Huge Crate of Weapons
      119083, -- Fruit Basket
      122120, -- Gaze of the Darkmoon
      128632, -- Savage Snowball
      128648, -- Yellow Snowball
      130233, -- Sorcerous Shadowruby Pendant
      133580, -- Brutarg's Sword Tip
      133585, -- Judgment of the Naaru
      136339, -- Spellstone of Kel'danath
      138026, -- Empowered Charging Device
      138733, -- Shadescale Manipulator
      139427, -- Wild Mana Wand
      143863, -- Fel Exfoliator
      147023, -- Leviathan's Hunger
      147420, -- Pebble
      153219, -- Squished Demon Eye
      155823, -- Icy Snowball
      156665, -- Bag of Transmutation Stones
      156831, -- Bag of Transmutation Stones
      156868, -- Crawg Poison Gland
      158332, -- Zeth'jir Channeling Rod
      160307, -- Raal's Hexing Stick
      160525, -- Tongo's Head
      168407, -- Friendship Net
      168947, -- Scroll of Bursting Power
      169209, -- Scroll of Bursting Power
      169446, -- Water Filled Bladder
      169673, -- Blue Paint Filled Bladder
      169674, -- Green Paint Filled Bladder
      169675, -- Orange Paint Filled Bladder
      173157, -- Vial of Caustic Goo
      173358, -- Invitations
      173693, -- Jar of Maggots
      177839, -- Anima Siphon
      178873, -- Concentrated Anima Vial
      180446, -- Curiously Corrosive Concoction
      180661, -- Darktower Parchments: Affliction Most Foul
      180678, -- Peck Acorn
      180688, -- Infused Remnant of Light
      180689, -- Pocket Embers
      180874, -- Gargon Whistle
      183602, -- Sticky Webbing
      183944, -- Heron Net
      185946, -- Long Tail Dynarats
      186431, -- Ebonsoul Vise
      186679, -- Scroll of Domination
      187186, -- Orb of Deception
      188261, -- Intrusive Thoughtcage
      188268, -- Architect's Ingenuity Core
      188692, -- Pouch of Ebon Rose Petals
      188693, -- Pouch of Red Rose Petals
      189454, -- Feather-Plucker 3300
      189862, -- Gavel of the First Arbiter
      192471, -- Arch Instructor's Wand
      193757, -- Ruby Whelp Shell
      193892, -- Wish's Whistle
      194122, -- Sour Apple
      194712, -- Empty Duck Trap
      194731, -- Illusion Parchment: Magma Missile
      194733, -- Illusion Parchment: Aqua Torrent
      194734, -- Illusion Parchment: Whirling Breeze
      194735, -- Illusion Parchment: Arcane Burst
      194736, -- Illusion Parchment: Chilling Wind
      194738, -- Illusion Parchment: Shadow Orb
      194818, -- Proto-Drake Wrangler Rope
      198087, -- Darkmoon Deck: Rime
      198477, -- Darkmoon Deck Box: Rime
      200120, -- Irideus' Power Core
      202270, -- [DNT] Twice-Woven Rope
      204473, -- Element Siphoner
      206160, -- Madam Shadow's Grimoire
      209996, -- Tethercoil Rune
      210755, -- Silent Mark of the Dreamsaber
      210764, -- Silent Mark of the Dreamtalon
      210766, -- Silent Mark of the Umbraclaw
      210767, -- Silent Mark of the Dreamstag
      211302, -- Slumberfruit
      212602, -- Titan Emitter
      215142, -- Freydrin's Shillelagh
      215158, -- Freydrin's Shillelagh
      218124, -- Element Extractor
      223220, -- Kaheti All-Purpose Cleanser
      224026, -- Storm Vessel
      225200, -- Alcor's Sunrazor
      225887, -- Titan Emitter
    },
    [35] = {
      18904,  -- Zorbin's Ultra-Shrinker
      24269,  -- Heavy Netherweave Net
      24501,  -- Gordawg's Boulder
      35121,  -- Wolf Bait
      39158,  -- Quetz'lun's Hexxing Stick
      41505,  -- Thorim's Charm of Earth
      41509,  -- Frostweave Net
      44890,  -- To'kini's Blowgun
      49028,  -- Nitro-Potassium Bananas
      54442,  -- Embersilk Net
      56576,  -- Orb of Suggestion
      88378,  -- Mothallus' Spinneret
      119216, -- Super Sticky Glitter Bomb
      151363, -- Ticker's Rocket Launcher
      180899, -- Riding Hook
      193212, -- Marmoni Rescue Pack
    },
    [38] = {
      140786, -- Ley Spider Eggs
    },
    [40] = {
      4945,   -- Faintly Glowing Skull
      28767,  -- The Decapitator
      33581,  -- Vrykul Insult
      34255,  -- Razorthorn Flayer Gland
      37438,  -- Rod of Compulsion
      38332,  -- Modified Mojo
      38380,  -- Zul'Drak Rat
      39615,  -- Crusader Parachute
      44114,  -- Old Spices
      44222,  -- Dart Gun
      44228,  -- Baby Spice
      44812,  -- Turkey Shooter
      50430,  -- Scraps of Rotting Meat
      52490,  -- Stardust
      53794,  -- Rendel's Bridle
      55165,  -- Enchanted Sea Snack
      56169,  -- Breathstone
      56847,  -- Chelsea's Nightmare
      60490,  -- The Axe of Earthly Sundering
      60808,  -- Mutant Bush Chicken Cage
      65162,  -- Emergency Pool Pony
      69832,  -- Burd Sticker
      74612,  -- Red Panda Lasso
      82468,  -- Yak Lasso
      88577,  -- Explosive Barrel
      88590,  -- Nurong's Gun
      93668,  -- Saur Fetish
      108903, -- Tiny Iron Star
      114125, -- Preserved Discombobulator Ray
      114926, -- Restorative Goldcap
      116400, -- Silver-Plated Turkey Shooter
      116759, -- Blixthraz's Frightening Grudgesolver
      118007, -- Mecha-Blast Rocket
      118190, -- Blixthraz's Frightening Grudgesolver
      118199, -- Poison Cask
      118616, -- Olaf's Shield
      124224, -- Mirror of the Blademaster
      128505, -- Celebration Wand - Murloc
      128506, -- Celebration Wand - Gnoll
      128772, -- Branch of the Runewood
      132500, -- Blink-Trigger Headgun
      132501, -- Tactical Headgun
      132502, -- Bolt-Action Headgun
      132503, -- Reinforced Headgun
      132504, -- Semi-Automagic Cranial Cannon
      132505, -- Sawed-Off Cranial Cannon
      132506, -- Double-Barreled Cranial Cannon
      132507, -- Ironsight Cranial Cannon
      132510, -- Gunpowder Charge
      133706, -- Mossgill Bait
      133761, -- Flintlocke's Headgun Prototype
      133775, -- Gunpowder Charges
      133928, -- Prototype Pump-Action Bandage Gun
      133998, -- Rainbow Generator
      133999, -- Inert Crystal
      137329, -- Figurehead of the Naglfar
      138116, -- Throwing Torch
      139589, -- Poisoned Throwing Knives
      139882, -- Vial of Hippogryph Pheromones
      141005, -- Vial of Hippogryph Pheromones
      141306, -- Wisp in a Bottle
      141411, -- Translocation Anomaly Neutralization Crystal
      142173, -- Ring of Collapsing Futures
      144331, -- Tailored Skullblasters
      144332, -- Rugged Skullblasters
      144333, -- Chain Skullblasters
      144334, -- Heavy Skullblasters
      147882, -- Celebration Wand - Trogg
      147883, -- Celebration Wand - Quilboar
      151368, -- Experimental Alchemy Reagent
      151369, -- Lightning Absorption Capsule
      151370, -- Military Explosives
      152574, -- Corbyn's Beacon
      153483, -- Modified Blood Fetish
      153571, -- Poisoned Blow Dart
      153675, -- Scroll of Capsizing
      156528, -- Titan Manipulator
      156649, -- Zandalari Effigy Amulet
      159796, -- Meatification Potion
      159882, -- Bug Zapper
      160052, -- Flour Bomb
      160659, -- Hunting Rifle
      160753, -- Sanguinating Totem
      160833, -- Fetish of the Tormented Mind
      165702, -- Shard of Vesara
      165806, -- Sinister Gladiator's Maledict
      167013, -- Fiery Brinestone Shard
      167018, -- Azure Brinestone Shard
      167019, -- Violet Brinestone Shard
      167383, -- Notorious Gladiator's Maledict
      168012, -- Apexis Focusing Shard
      168271, -- Stolen Ramkahen Banner
      169305, -- Aquipotent Nautilus
      169307, -- Vision of Demise
      169311, -- Ashvane's Razor Coral
      169490, -- Relic of the Black Empire
      169769, -- Remote Guidance Device
      169816, -- Quasi-Faceted Scanner
      169858, -- \"Bee Bee\" Gun
      170252, -- Pouch of Gangrenous Spores
      171373, -- Introspection
      172672, -- Corrupted Gladiator's Maledict
      173069, -- Darkmoon Deck: Putrescence
      173087, -- Darkmoon Deck: Voracity
      174927, -- Zan-Tien Lasso
      175732, -- Tablet of Despair
      175733, -- Brimming Ember Shard
      177836, -- Wingpierce Javelin
      178495, -- Shattered Helm of Domination
      178496, -- Baron's Warhorn
      178567, -- Kein's Runeblade
      178809, -- Soulletting Ruby
      178810, -- Vial of Spectral Essence
      178826, -- Sunblood Amethyst
      179535, -- Crumbling Pride Extractors
      179613, -- Extra Sticky Spidey Webs
      179938, -- Crumbling Pride Extractors
      179939, -- Wriggling Spider Sac
      180117, -- Empyreal Ordnance
      180708, -- Mirror of Despair
      181357, -- Tablet of Despair
      181360, -- Brimming Ember Shard
      182653, -- Larion Treats
      184313, -- Shattered Helm of Domination
      185720, -- Draka's Battlehorn
      186421, -- Forbidden Necromantic Tome
      186474, -- Korayn's Javelin
      188254, -- Grim Eclipse
      188265, -- Cache of Acquired Treasures
      191044, -- Spider Squasher
      191372, -- Residual Neural Channeling Agent
      191373, -- Residual Neural Channeling Agent
      191374, -- Residual Neural Channeling Agent
      193826, -- Trusty Dragonkin Rake
      193856, -- Flowery's Rake
      194308, -- Manic Grieftorch
      194872, -- Darkmoon Deck Box: Inferno
      198047, -- Kul Tiran Red
      198086, -- Darkmoon Deck: Inferno
      201815, -- Cloak of Many Faces
      204343, -- Trusty Dragonkin Rake
      205224, -- Just a Rock
      208321, -- Iridal, the Earth's Master
      211000, -- Cunning Charm
      212257, -- Potion of Unwavering Focus
      212258, -- Potion of Unwavering Focus
      212259, -- Potion of Unwavering Focus
      212325, -- QA Potion of Unwavering Focus
      212450, -- Swarmlord's Authority
      212963, -- Fleeting Potion of Unwavering Focus
      212964, -- Fleeting Potion of Unwavering Focus
      212965, -- Fleeting Potion of Unwavering Focus
      213629, -- Debugger Hat
      224047, -- Water Blast
      225651, -- Kaheti Shadeweaver's Emblem
    },
    [45] = {
      23836,  -- Goblin Rocket Launcher
      28369,  -- Battery Recharging Blaster
      32698,  -- Wrangling Rope
      34691,  -- Arcane Binder
      34812,  -- Crafty's Ultra-Advanced Proto-Typical Shortening Blaster
      35352,  -- Sage's Lightning Rod
      49647,  -- Drum of the Soothed Earth
      52059,  -- Murloc Leash
      52833,  -- Modified Soul Orb
      62794,  -- Licensed Proton Accelerator Cannon
      64445,  -- Banshee Mirror
      167870, -- G99.99 Landshark
      179719, -- Anima Lure
      194304, -- Iceblood Deathsnare
      194310, -- Desperate Invoker's Codex
      203963, -- Beacon to the Beyond
      207057, -- Gift of the White War Wolf
      207083, -- Gift of the Ravenous Black Gryphon
      208615, -- Nymue's Unraveling Spindle
      208616, -- Dreambinder, Loom of the Great Cycle
    },
    [46] = {
      202610, -- Dragonfire Bomb Dispenser
    },
    [50] = {
      116139, -- Haunting Memento
      129372, -- Spymaster Jenri's Scope
      134836, -- Trident
      147017, -- Tarnished Sentinel Medallion
      147019, -- Tome of Unraveling Sanity
      151960, -- Carafe of Searing Light
      151970, -- Vitality Resonator
      155565, -- Trunksy
      158216, -- Living Oil Canister
      159624, -- Rotcrusted Voodoo Doll
      160443, -- The Glaive of Vol'jin
      160557, -- Pungent Onion
      161452, -- The Glaive of Vol'jin
      165576, -- Tidestorm Codex
      168905, -- Shiver Venom Relic
      173944, -- Forbidden Obsidian Claw
      184021, -- Glyph of Assimilation
      184030, -- Dreadfire Vessel
      186422, -- Tome of Monstrous Constructions
      186437, -- Relic of the Frozen Wastes
      207084, -- Auebry's Marker Pistol
      208389, -- Spear of the Wilds
      211344, -- Miniaturizer
      212454, -- Mad Queen's Mandate
      219313, -- Mereldar's Toll
    },
    [55] = {
      74637,  -- Kiryn's Poison Vial
    },
    [60] = {
      32825,  -- Soul Cannon
      34111,  -- Trained Rock Falcon
      34121,  -- Trained Rock Falcon
      37877,  -- Silver Feather
      37887,  -- Seeds of Nature's Wrath
      49700,  -- SFG
      50851,  -- Pulsing Life Crystal
      52043,  -- Bootzooka
      127030, -- Granny's Flare Grenades
      153679, -- Tether Shot
      155822, -- Sedative Quill
      156516, -- Sedative Quill
      156928, -- Tether Shot
      169279, -- Pedram's Marker Pistol
      183165, -- Mawsworn Crossbow
      192436, -- Ruby Spear
      209999, -- Lydiara's Rune of Shadowbinding
    },
    [70] = {
      41265,  -- Eyesore Blaster
      202642, -- Proto-Killing Spear
    },
    [75] = {
      185949, -- Korayn's Spear
    },
    [80] = {
      35278,  -- Reinforced Net
      35506,  -- Raelorasz's Spear
      42769,  -- Spear of Hodir
      49596,  -- Cryomatic 16
      50031,  -- Tomusa's Hook
      62775,  -- Barbed Fleshhook
      63092,  -- Wyrmhunter Hooks
      63104,  -- Elemental Nullifier
      63393,  -- Shoulder-Mounted Drake-Dropper
      152572, -- Sezahjin's Trusty Vulture Bow
      152610, -- Sur'jan's Grappling Hook
      159761, -- Grappling Hook
      168253, -- Fathom Hook
      185742, -- Mawsworn Chains
      185829, -- Trueheart Spear
      194891, -- Arcane Hook
    },
    [90] = {
      133925, -- Fel Lash
    },
    [100] = {
      33119,  -- Malister's Frost Wand
      41058,  -- Hyldnir Harpoon
      44212,  -- SGM-3
      83134,  -- Bronze Claws
      109082, -- Barbed Harpoon
      144227, -- Soul of Frost
      151307, -- Void Stalker's Contract
      160739, -- Goblin Rocket Launcher
      161422, -- Magister Umbric's Void Shard
      163604, -- Net-o-Matic 5000
      222976, -- Flame-Tempered Harpoon
    },
    [120] = {
      160988, -- Goblin Incendiary Rocket Launcher
      168430, -- Clobberbottom's Boomer
      169681, -- BOOM-TASTIC 3000
      211963, -- Ceiling Sweeper
    },
    [150] = {
      42986,  -- The RP-GG
      46954,  -- Flaming Spears
      153204, -- All-Seer's Eye
      154893, -- Faithless Trapper's Spear
      192750, -- Black Iron Javelin
    },
    [200] = {
      75208,  -- Rancher's Lariat
      86546,  -- Sky Crystal
      89163,  -- Requisitioned Firework Launcher
      152657, -- Target Designator
    },
    [300] = {
      201414, -- Qalashi Wingshredder
    },
    -- [50000] = {
    --   34026,  -- Feathered Charm
    --   130867, -- Tag Toy
    --   136403, -- Staff of Four Winds
    --   146406, -- Vantus Rune: Tomb of Sargeras
    --   151610, -- Vantus Rune: Antorus, the Burning Throne
    --   153673, -- Vantus Rune: Uldir
    --   165692, -- Vantus Rune: Battle of Dazar'alor
    --   165733, -- Vantus Rune: Crucible of Storms
    --   168624, -- Vantus Rune: The Eternal Palace
    --   171203, -- Vantus Rune: Ny'alotha, the Waking City
    --   173067, -- Vantus Rune: Castle Nathria
    --   186662, -- Vantus Rune: Sanctum of Domination
    --   187805, -- Vantus Rune: Sepulcher of the First Ones
    --   189584, -- Sepulcher's Savior
    --   198491, -- Vantus Rune: Vault of the Incarnates
    --   198492, -- Vantus Rune: Vault of the Incarnates
    --   198493, -- Vantus Rune: Vault of the Incarnates
    --   204858, -- Vantus Rune: Aberrus, the Shadowed Crucible
    --   204859, -- Vantus Rune: Aberrus, the Shadowed Crucible
    --   204860, -- Vantus Rune: Aberrus, the Shadowed Crucible
    --   210247, -- Vantus Rune: Amirdrassil, the Dream's Hope
    --   210248, -- Vantus Rune: Amirdrassil, the Dream's Hope
    --   210249, -- Vantus Rune: Amirdrassil, the Dream's Hope
    --   226034, -- Vantus Rune: Nerub-ar Palace
    --   226035, -- Vantus Rune: Nerub-ar Palace
    --   226036, -- Vantus Rune: Nerub-ar Palace
    -- },
  }
end

-- This could've been done by checking player race as well and creating tables for those, but it's easier like this
for _, v in pairs(FriendSpells) do
  tinsert(v, 28880) -- Gift of the Naaru (40 yards)
end

-- >> END OF STATIC CONFIG

-- temporary stuff

local pendingItemRequest = {}
local itemRequestTimeoutAt = {}
local foundNewItems
local cacheAllItems
local friendItemRequests
local harmItemRequests
local lastUpdate = 0

local checkers_Spell = setmetatable({}, {
  __index = function(t, spellIdx)
    local func = function(unit)
      if IsSpellBookItemInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1 then
        return true
      end
    end
    t[spellIdx] = func
    return func
  end,
})
local checkers_SpellWithMin = {} -- see getCheckerForSpellWithMinRange()
local checkers_Item = setmetatable({}, {
  __index = function(t, item)
    local func = function(unit, skipInCombatCheck)
      if not skipInCombatCheck and InCombatLockdownRestriction(unit) then
        return nil
      else
        return C_Item.IsItemInRange(item, unit) or nil
      end
    end
    t[item] = func
    return func
  end,
})
local checkers_Interact = setmetatable({}, {
  __index = function(t, index)
    local func = function(unit, skipInCombatCheck)
      if not skipInCombatCheck and InCombatLockdownRestriction(unit) then
        return nil
      else
        return CheckInteractDistance(unit, index) and true or false
      end
    end
    t[index] = func
    return func
  end,
})

-- helper functions
local function copyTable(src, dst)
  if type(dst) ~= "table" then
    dst = {}
  end
  if type(src) == "table" then
    for k, v in pairs(src) do
      if type(v) == "table" then
        v = copyTable(v, dst[k])
      end
      dst[k] = v
    end
  end
  return dst
end

local function initItemRequests(cacheAll)
  friendItemRequests = copyTable(FriendItems)
  harmItemRequests = copyTable(HarmItems)
  cacheAllItems = cacheAll
  foundNewItems = nil
end

local function getNumSpells()
  local _, _, offset, numSpells = GetSpellTabInfo(GetNumSpellTabs())
  if not offset or not numSpells then
    return 0
  end
  return offset + numSpells
end

-- return the spellIndex of the given spell by scanning the spellbook
local function findSpellIdx(spellName)
  if not spellName or spellName == "" then
    return nil
  end
  for i = 1, getNumSpells() do
    local spell = GetSpellBookItemName(i, BOOKTYPE_SPELL)
    if spell == spellName then
      local spellType, spellID, spellInfo = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
      if spellInfo then -- new API output available
        if Enum.SpellBookItemType and spellInfo.itemType == Enum.SpellBookItemType.Spell and not spellInfo.isOffSpec then -- retail - filter for only active spec "SPELL"
          return spellID
        end
      elseif spellType == "SPELL" then -- classic/era
        return i
      end
    end
  end
  return nil
end

local function fixRange(range)
  if range then
    return math_floor(range + 0.5)
  end
end

local function getSpellData(sid)
  local name, _, _, _, minRange, range = GetSpellInfo(sid)
  return name, fixRange(minRange), fixRange(range), findSpellIdx(name)
end

local function findMinRangeChecker(origMinRange, origRange, spellList, interactLists)
  for i = 1, #spellList do
    local sid = spellList[i]
    local name, minRange, range, spellIdx = getSpellData(sid)
    if range and spellIdx and origMinRange <= range and range <= origRange and minRange == 0 then
      return checkers_Spell[spellIdx]
    end
  end
  for index, range in pairs(interactLists) do
    if origMinRange <= range and range <= origRange then
      return checkers_Interact[index]
    end
  end
end

local function getCheckerForSpellWithMinRange(spellIdx, minRange, range, spellList, interactLists)
  local checker = checkers_SpellWithMin[spellIdx]
  if checker then
    return checker
  end
  local minRangeChecker = findMinRangeChecker(minRange, range, spellList, interactLists)
  if minRangeChecker then
    checker = function(unit)
      if IsSpellBookItemInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1 then
        return true
      elseif minRangeChecker(unit) then
        return true, true
      end
    end
    checkers_SpellWithMin[spellIdx] = checker
    return checker
  end
end

-- minRange should be nil if there's no minRange, not 0
local function addChecker(t, range, minRange, checker, info)
  local rc = { ["range"] = range, ["minRange"] = minRange, ["checker"] = checker, ["info"] = info }
  for i = 1, #t do
    local v = t[i]
    if rc.range == v.range then
      return
    end
    if rc.range > v.range then
      tinsert(t, i, rc)
      return
    end
  end
  tinsert(t, rc)
end

local function createCheckerList(spellList, itemList, interactList)
  local res, resInCombat = {}, {}
  if itemList then
    for range, items in pairs(itemList) do
      for i = 1, #items do
        local item = items[i]
        if Item:CreateFromItemID(item):IsItemDataCached() and C_Item.GetItemInfo(item) then
          addChecker(res, range, nil, checkers_Item[item], "item:" .. item)
          break
        end
      end
    end
  end

  if interactList and not next(res) then
    for index, range in pairs(interactList) do
      addChecker(res, range, nil, checkers_Interact[index], "interact:" .. index)
    end
  end

  if spellList then
    for i = 1, #spellList do
      local sid = spellList[i]
      local name, minRange, range, spellIdx = getSpellData(sid)
      if spellIdx and range then
        -- print("### spell: " .. tostring(name) .. ", " .. tostring(minRange) .. " - " ..  tostring(range))

        if minRange == 0 then -- getRange() expects minRange to be nil in this case
          minRange = nil
        end

        if range == 0 then
          range = MeleeRange
        end

        if minRange then
          local checker = getCheckerForSpellWithMinRange(spellIdx, minRange, range, spellList, interactList)
          if checker then
            addChecker(res, range, minRange, checker, "spell:" .. sid .. ":" .. tostring(name))
            addChecker(resInCombat, range, minRange, checker, "spell:" .. sid .. ":" .. tostring(name))
          end
        else
          addChecker(res, range, minRange, checkers_Spell[spellIdx], "spell:" .. sid .. ":" .. tostring(name))
          addChecker(resInCombat, range, minRange, checkers_Spell[spellIdx], "spell:" .. sid .. ":" .. tostring(name))
        end
      end
    end
  end

  return res, resInCombat
end

local rangeCache = {}

local function resetRangeCache()
  wipe(rangeCache)
end

local function invalidateRangeCache(maxAge)
  local currentTime = GetTime()
  for k, v in pairs(rangeCache) do
    -- if the entry is older than maxAge, clear this data from the cache
    if v.updateTime + maxAge < currentTime then
      rangeCache[k] = nil
    end
  end
end

-- returns minRange, maxRange  or nil
local function getRangeWithCheckerList(unit, checkerList)
  local lo, hi = 1, #checkerList
  while lo <= hi do
    local mid = math_floor((lo + hi) / 2)
    local rc = checkerList[mid]
    if rc.checker(unit, true) then
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  if #checkerList == 0 then
    return nil, nil
  elseif lo > #checkerList then
    return 0, checkerList[#checkerList].range
  elseif lo <= 1 then
    return checkerList[1].range, nil
  else
    return checkerList[lo].range, checkerList[lo - 1].range
  end
end

local function getRange(unit, noItems)
  local canAssist = UnitCanAssist("player", unit)
  if UnitIsDeadOrGhost(unit) then
    if canAssist then
      return getRangeWithCheckerList(unit, InCombatLockdownRestriction(unit) and lib.resRCInCombat or lib.resRC)
    else
      return getRangeWithCheckerList(unit, InCombatLockdownRestriction(unit) and lib.miscRCInCombat or lib.miscRC)
    end
  end

  if UnitCanAttack("player", unit) then
    return getRangeWithCheckerList(unit, noItems and lib.harmNoItemsRC or lib.harmRC)
  elseif UnitIsUnit("pet", unit) then
    if InCombatLockdownRestriction(unit) then
      local minRange, maxRange = getRangeWithCheckerList(unit, noItems and lib.friendNoItemsRCInCombat or lib.friendRCInCombat)
      if minRange or maxRange then
        return minRange, maxRange
      else
        return getRangeWithCheckerList(unit, lib.petRCInCombat)
      end
    else
      local minRange, maxRange = getRangeWithCheckerList(unit, noItems and lib.friendNoItemsRC or lib.friendRC)
      if minRange or maxRange then
        return minRange, maxRange
      else
        return getRangeWithCheckerList(unit, lib.petRC)
      end
    end
  elseif canAssist then
    if InCombatLockdownRestriction(unit) then
      return getRangeWithCheckerList(unit, noItems and lib.friendNoItemsRCInCombat or lib.friendRCInCombat)
    else
      return getRangeWithCheckerList(unit, noItems and lib.friendNoItemsRC or lib.friendRC)
    end
  else
    return getRangeWithCheckerList(unit, InCombatLockdownRestriction(unit) and lib.miscRCInCombat or lib.miscRC)
  end
end

local function getCachedRange(unit, noItems, maxCacheAge)
  -- maxCacheAge has a default of 0.1 and a maximum of 1 second
  maxCacheAge = maxCacheAge or 0.1
  maxCacheAge = maxCacheAge > 1 and 1 or maxCacheAge

  -- compose cache key out of unit guid and noItems
  local guid = UnitGUID(unit)
  local cacheKey = guid .. (noItems and "-1" or "-0")
  local cacheItem = rangeCache[cacheKey]

  local currentTime = GetTime()

  -- if then cache item is valid return it
  if cacheItem and cacheItem.updateTime + maxCacheAge > currentTime then
    return cacheItem.minRange, cacheItem.maxRange
  end

  -- otherwise create a new or update the existing cache item
  local result = cacheItem or {}
  result.minRange, result.maxRange = getRange(unit, noItems)
  result.updateTime = currentTime
  rangeCache[cacheKey] = result
  return result.minRange, result.maxRange
end

local function updateList(origList, newList)
  if #origList ~= #newList then
    wipe(origList)
    copyTable(newList, origList)
    return true
  end
  for i = 1, #origList do
    if origList[i].range ~= newList[i].range or origList[i].checker ~= newList[i].checker then
      wipe(origList)
      copyTable(newList, origList)
      return true
    end
  end
end

local function updateCheckers(origList, origList2, newList, newList2)
  local changed = updateList(origList, newList)
  changed = updateList(origList2, newList2) or changed
  return changed
end

local function rcIterator(checkerList)
  local curr = #checkerList
  return function()
    local rc = checkerList[curr]
    if not rc then
      return nil
    end
    curr = curr - 1
    return rc.range, rc.checker
  end
end

local function getMinChecker(checkerList, range)
  local checker, checkerRange
  for i = 1, #checkerList do
    local rc = checkerList[i]
    if rc.range < range then
      return checker, checkerRange
    end
    checker, checkerRange = rc.checker, rc.range
  end
  return checker, checkerRange
end

local function getMaxChecker(checkerList, range)
  for i = 1, #checkerList do
    local rc = checkerList[i]
    if rc.range <= range then
      return rc.checker, rc.range
    end
  end
end

local function getChecker(checkerList, range)
  for i = 1, #checkerList do
    local rc = checkerList[i]
    if rc.range == range then
      return rc.checker
    end
  end
end

local function null() end

local function createSmartChecker(friendChecker, harmChecker, miscChecker)
  miscChecker = miscChecker or null
  friendChecker = friendChecker or miscChecker
  harmChecker = harmChecker or miscChecker
  return function(unit)
    if not UnitExists(unit) then
      return nil
    end
    if UnitIsDeadOrGhost(unit) then
      return miscChecker(unit)
    end
    if UnitCanAttack("player", unit) then
      return harmChecker(unit)
    elseif UnitCanAssist("player", unit) then
      return friendChecker(unit)
    else
      return miscChecker(unit)
    end
  end
end

local minItemChecker = function(item)
  if C_Item.GetItemInfo(item) then
    return function(unit)
      return C_Item.IsItemInRange(item, unit)
    end
  end
end

-- OK, here comes the actual lib

-- pre-initialize the checkerLists here so that we can return some meaningful result even if
-- someone manages to call us before we're properly initialized. miscRC should be independent of
-- race/class/talents, so it's safe to initialize it here
-- friendRC and harmRC will be properly initialized later when we have all the necessary data for them
lib.checkerCache_Spell = lib.checkerCache_Spell or {}
lib.checkerCache_Item = lib.checkerCache_Item or {}
lib.miscRC = createCheckerList(nil, nil, DefaultInteractList)
lib.miscRCInCombat = {}
lib.friendRC = createCheckerList(nil, nil, DefaultInteractList)
lib.friendRCInCombat = {}
lib.harmRC = createCheckerList(nil, nil, DefaultInteractList)
lib.harmRCInCombat = {}
lib.resRC = createCheckerList(nil, nil, DefaultInteractList)
lib.resRCInCombat = {}
lib.petRC = createCheckerList(nil, nil, DefaultInteractList)
lib.petRCInCombat = {}
lib.friendNoItemsRC = createCheckerList(nil, nil, DefaultInteractList)
lib.friendNoItemsRCInCombat = {}
lib.harmNoItemsRC = createCheckerList(nil, nil, DefaultInteractList)
lib.harmNoItemsRCInCombat = {}

lib.failedItemRequests = {}

-- << Public API

--- The callback name that is fired when checkers are changed.
-- @field
lib.CHECKERS_CHANGED = "CHECKERS_CHANGED"
-- "export" it, maybe someone will need it for formatting
--- Constant for Melee range (2yd).
-- @field
lib.MeleeRange = MeleeRange

function lib:findSpellIndex(spell)
  if type(spell) == "number" then
    spell = GetSpellInfo(spell)
  end
  return findSpellIdx(spell)
end

-- returns the range estimate as a string
-- deprecated, use :getRange(unit) instead and build your own strings
-- @param checkVisible if set to true, then a UnitIsVisible check is made, and **nil** is returned if the unit is not visible
function lib:getRangeAsString(unit, checkVisible, showOutOfRange)
  local minRange, maxRange = self:getRange(unit, checkVisible)
  if not minRange then
    return nil
  end
  if not maxRange then
    return showOutOfRange and minRange .. " +" or nil
  end
  return minRange .. " - " .. maxRange
end

-- initialize RangeCheck if not yet initialized or if "forced"
function lib:init(forced)
  if self.initialized and not forced then
    return
  end
  self.initialized = true
  local _, playerClass = UnitClass("player")
  local _, playerRace = UnitRace("player")

  local interactList = InteractLists[playerRace] or DefaultInteractList
  self.handSlotItem = GetInventoryItemLink("player", HandSlotId)
  local changed = false
  if updateCheckers(self.friendRC, self.friendRCInCombat, createCheckerList(FriendSpells[playerClass], FriendItems, interactList)) then
    changed = true
  end
  if updateCheckers(self.harmRC, self.harmRCInCombat, createCheckerList(HarmSpells[playerClass], HarmItems, interactList)) then
    changed = true
  end
  if updateCheckers(self.friendNoItemsRC, self.friendNoItemsRCInCombat, createCheckerList(FriendSpells[playerClass], nil, interactList)) then
    changed = true
  end
  if updateCheckers(self.harmNoItemsRC, self.harmNoItemsRCInCombat, createCheckerList(HarmSpells[playerClass], nil, interactList)) then
    changed = true
  end
  if updateCheckers(self.miscRC, self.miscRCInCombat, createCheckerList(nil, nil, interactList)) then
    changed = true
  end
  if updateCheckers(self.resRC, self.resRCInCombat, createCheckerList(ResSpells[playerClass], nil, interactList)) then
    changed = true
  end
  if updateCheckers(self.petRC, self.petRCInCombat, createCheckerList(PetSpells[playerClass], nil, interactList)) then
    changed = true
  end
  if changed and self.callbacks then
    self.callbacks:Fire(self.CHECKERS_CHANGED)
  end
end

--- Return an iterator for checkers usable on friendly units as (**range**, **checker**) pairs.
-- @param inCombat if true, only checkers that can be used in combat ar returned
function lib:GetFriendCheckers(inCombat)
  return rcIterator(inCombat and self.friendRCInCombat or self.friendRC)
end

--- Return an iterator for checkers usable on friendly units as (**range**, **checker**) pairs.
-- @param inCombat if true, only checkers that can be used in combat ar returned
function lib:GetFriendCheckersNoItems(inCombat)
  return rcIterator(inCombat and self.friendNoItemsRCInCombat or self.friendNoItemsRC)
end


--- Return an iterator for checkers usable on enemy units as (**range**, **checker**) pairs.
-- @param inCombat if true, only checkers that can be used in combat ar returned
function lib:GetHarmCheckers(inCombat)
  return rcIterator(inCombat and self.harmRCInCombat or self.harmRC)
end


--- Return an iterator for checkers usable on enemy units as (**range**, **checker**) pairs.
-- @param inCombat if true, only checkers that can be used in combat ar returned
function lib:GetHarmCheckersNoItems(inCombat)
  return rcIterator(inCombat and self.harmNoItemsRCInCombat or self.harmNoItemsRC)
end


--- Return an iterator for checkers usable on miscellaneous units as (**range**, **checker**) pairs.  These units are neither enemy nor friendly, such as people in sanctuaries or corpses.
-- @param inCombat if true, only checkers that can be used in combat ar returned
function lib:GetMiscCheckers(inCombat)
  return rcIterator(inCombat and self.miscRCInCombat or self.miscRC)
end

--- Return a checker suitable for out-of-range checking on friendly units, that is, a checker whose range is equal or larger than the requested range.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetFriendMinChecker(range, inCombat)
  return getMinChecker(inCombat and self.friendRCInCombat or self.friendRC , range)
end

--- Return a checker suitable for out-of-range checking on enemy units, that is, a checker whose range is equal or larger than the requested range.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetHarmMinChecker(range, inCombat)
  return getMinChecker(inCombat and self.harmRCInCombat or self.harmRC, range)
end

--- Return a checker suitable for out-of-range checking on miscellaneous units, that is, a checker whose range is equal or larger than the requested range.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetMiscMinChecker(range, inCombat)
  return getMinChecker(inCombat and self.miscRCInCombat or self.miscRC, range)
end

--- Return a checker suitable for in-range checking on friendly units, that is, a checker whose range is equal or smaller than the requested range.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetFriendMaxChecker(range, inCombat)
  return getMaxChecker(inCombat and self.friendRCInCombat or self.friendRC, range)
end

--- Return a checker suitable for in-range checking on enemy units, that is, a checker whose range is equal or smaller than the requested range.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetHarmMaxChecker(range, inCombat)
  return getMaxChecker(inCombat and self.harmRCInCombat or self.harmRC, range)
end

--- Return a checker suitable for in-range checking on miscellaneous units, that is, a checker whose range is equal or smaller than the requested range.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker**, **range** pair or **nil** if no suitable checker is available. **range** is the actual range the returned **checker** checks for.
function lib:GetMiscMaxChecker(range, inCombat)
  return getMaxChecker(inCombat and self.miscRCInCombat and self.miscRC, range)
end

--- Return a checker for the given range for friendly units.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker** function or **nil** if no suitable checker is available.
function lib:GetFriendChecker(range, inCombat)
  return getChecker(inCombat and self.friendRCInCombat or self.friendRC, range)
end

--- Return a checker for the given range for enemy units.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker** function or **nil** if no suitable checker is available.
function lib:GetHarmChecker(range, inCombat)
  return getChecker(inCombat and self.harmRCInCombat or self.harmRC, range)
end

--- Return a checker for the given range for miscellaneous units.
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker** function or **nil** if no suitable checker is available.
function lib:GetMiscChecker(range, inCombat)
  return getChecker(inCombat and self.miscRCInCombat or self.miscRC, range)
end

--- Return a checker suitable for out-of-range checking that checks the unit type and calls the appropriate checker (friend/harm/misc).
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker** function.
function lib:GetSmartMinChecker(range, inCombat)
  if inCombat then
    return createSmartChecker(getMinChecker(self.friendRCInCombat, range),
                              getMinChecker(self.harmRCInCombat, range),
                              getMinChecker(self.miscRCInCombat, range))
  else
    return createSmartChecker(getMinChecker(self.friendRC, range),
                              getMinChecker(self.harmRC, range),
                              getMinChecker(self.miscRC, range))
  end
end

--- Return a checker suitable for in-range checking that checks the unit type and calls the appropriate checker (friend/harm/misc).
-- @param range the range to check for.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker** function.
function lib:GetSmartMaxChecker(range, inCombat)
  if inCombat then
    return createSmartChecker(getMaxChecker(self.friendRCInCombat, range),
                              getMaxChecker(self.harmRCInCombat, range),
                              getMaxChecker(self.miscRCInCombat, range))
  else
    return createSmartChecker(getMaxChecker(self.friendRC, range),
                              getMaxChecker(self.harmRC, range),
                              getMaxChecker(self.miscRC, range))
  end
end

--- Return a checker for the given range that checks the unit type and calls the appropriate checker (friend/harm/misc).
-- @param range the range to check for.
-- @param fallback optional fallback function that gets called as fallback(unit) if a checker is not available for the given type (friend/harm/misc) at the requested range. The default fallback function return nil.
-- @param inCombat if true, only checkers that can be used in combat ar returned
-- @return **checker** function.
function lib:GetSmartChecker(range, fallback, inCombat)
  if inCombat then
    return createSmartChecker(getChecker(self.friendRCInCombat, range) or fallback,
                              getChecker(self.harmRCInCombat, range) or fallback,
                              getChecker(self.miscRCInCombat, range) or fallback)
  else
    return createSmartChecker(getChecker(self.friendRC, range) or fallback,
                              getChecker(self.harmRC, range) or fallback,
                              getChecker(self.miscRC, range) or fallback)
  end
end

--- Get a range estimate as **minRange**, **maxRange**.
-- @param unit the target unit to check range to.
-- @param checkVisible if set to true, then a UnitIsVisible check is made, and **nil** is returned if the unit is not visible
-- @param noItems if set to true, no items and only spells are being used for the range check
-- @param maxCacheAge the timespan a cached range value is considered valid (default 0.1 seconds, maximum 1 second)
-- @return **minRange**, **maxRange** pair if a range estimate could be determined, **nil** otherwise. **maxRange** is **nil** if **unit** is further away than the highest possible range we can check.
-- Includes checks for unit validity and friendly/enemy status.
-- @usage
-- local rc = LibStub("LibRangeCheck-3.0")
-- local minRange, maxRange = rc:GetRange('target')
-- local minRangeIfVisible, maxRangeIfVisible = rc:GetRange('target', true)
function lib:GetRange(unit, checkVisible, noItems, maxCacheAge)
  if not UnitExists(unit) then
    return nil
  end

  if checkVisible and not UnitIsVisible(unit) then
    return nil
  end

  return getCachedRange(unit, noItems, maxCacheAge)
end

-- keep this for compatibility
lib.getRange = lib.GetRange

-- >> Public API

function lib:OnEvent(event, ...)
  if type(self[event]) == "function" then
    self[event](self, event, ...)
  end
end

function lib:LEARNED_SPELL_IN_TAB()
  self:scheduleInit()
end

function lib:CHARACTER_POINTS_CHANGED()
  self:scheduleInit()
end

function lib:PLAYER_TALENT_UPDATE()
  self:scheduleInit()
end

function lib:SPELLS_CHANGED()
  self:scheduleInit()
end

function lib:CVAR_UPDATE(_, cvar)
  if cvar == "ShowAllSpellRanks" then
    self:scheduleInit()
  end
end

function lib:UNIT_INVENTORY_CHANGED(event, unit)
  if self.initialized and unit == "player" and self.handSlotItem ~= GetInventoryItemLink("player", HandSlotId) then
    self:scheduleInit()
  end
end

function lib:UNIT_AURA(event, unit)
  if self.initialized and unit == "player" then
    self:scheduleAuraCheck()
  end
end

function lib:GET_ITEM_INFO_RECEIVED(event, item, success)
  -- print("### GET_ITEM_INFO_RECEIVED: " .. tostring(item) .. ", " .. tostring(success))
  if pendingItemRequest[item] then
    pendingItemRequest[item] = nil
    itemRequestTimeoutAt[item] = nil
    if not success then
      self.failedItemRequests[item] = true
    end
    lastUpdate = UpdateDelay
  end
end

function lib:processItemRequests(itemRequests)
  while true do
    local range, items = next(itemRequests)
    if not range then
      return
    end
    while true do
      local i, item = next(items)
      if not i then
        itemRequests[range] = nil
        break
      elseif Item:CreateFromItemID(item):IsItemEmpty() or self.failedItemRequests[item] then
        -- print("### processItemRequests: failed: " .. tostring(item))
        tremove(items, i)
      elseif pendingItemRequest[item] and GetTime() < itemRequestTimeoutAt[item] then
        return true -- still waiting for server response
      elseif C_Item.GetItemInfo(item) then
        -- print("### processItemRequests: found: " .. tostring(item))
        foundNewItems = true
        itemRequestTimeoutAt[item] = nil
        pendingItemRequest[item] = nil
        if not cacheAllItems then
          itemRequests[range] = nil
          break
        end
        tremove(items, i)
      elseif not itemRequestTimeoutAt[item] then
        -- print("### processItemRequests: waiting: " .. tostring(item))
        itemRequestTimeoutAt[item] = GetTime() + ItemRequestTimeout
        pendingItemRequest[item] = true
        if not self.frame:IsEventRegistered("GET_ITEM_INFO_RECEIVED") then
          self.frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        end
        return true
      elseif GetTime() >= itemRequestTimeoutAt[item] then
        -- print("### processItemRequests: timeout: " .. tostring(item))
        if cacheAllItems then
          print(MAJOR_VERSION .. ": timeout for item: " .. tostring(item))
        end
        self.failedItemRequests[item] = true
        itemRequestTimeoutAt[item] = nil
        pendingItemRequest[item] = nil
        tremove(items, i)
      else
        return true -- still waiting for server response
      end
    end
  end
end

function lib:initialOnUpdate()
  self:init()
  if friendItemRequests then
    if self:processItemRequests(friendItemRequests) then
      return
    end
    friendItemRequests = nil
  end
  if harmItemRequests then
    if self:processItemRequests(harmItemRequests) then
      return
    end
    harmItemRequests = nil
  end
  if foundNewItems then
    self:init(true)
    foundNewItems = nil
  end
  if cacheAllItems then
    print(MAJOR_VERSION .. ": finished cache")
    cacheAllItems = nil
  end
  self.frame:Hide()
  self.frame:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
end

function lib:scheduleInit()
  self.initialized = nil
  lastUpdate = 0
  self.frame:Show()
end

function lib:scheduleAuraCheck()
  lastUpdate = UpdateDelay
  self.frame:Show()
end


-- << load-time initialization

function lib:activate()
  if not self.frame then
    local frame = CreateFrame("Frame")
    self.frame = frame

    frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
    frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
    frame:RegisterEvent("SPELLS_CHANGED")

    if isEra or isCata then
      frame:RegisterEvent("CVAR_UPDATE")
    end

    if isRetail or isCata then
      frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    end

    local _, playerClass = UnitClass("player")
    if playerClass == "MAGE" or playerClass == "SHAMAN" then
      -- Mage and Shaman gladiator gloves modify spell ranges
      frame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
    end
  end

  if not self.cacheResetTimer then
    self.cacheResetTimer = C_Timer.NewTicker(5, function()
      invalidateRangeCache(5)
    end)
  end

  initItemRequests()

  self.frame:SetScript("OnEvent", function(_, ...)
    self:OnEvent(...)
  end)
  self.frame:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < UpdateDelay then
      return
    end
    lastUpdate = 0
    self:initialOnUpdate()
  end)

  self:scheduleInit()
end

--- BEGIN CallbackHandler stuff

do
  --- Register a callback to get called when checkers are updated
  -- @class function
  -- @name lib.RegisterCallback
  -- @usage
  -- rc.RegisterCallback(self, rc.CHECKERS_CHANGED, "myCallback")
  -- -- or
  -- rc.RegisterCallback(self, "CHECKERS_CHANGED", someCallbackFunction)
  -- @see CallbackHandler-1.0 documentation for more details
  lib.RegisterCallback = lib.RegisterCallback
    or function(...)
      local CBH = LibStub("CallbackHandler-1.0")
      lib.RegisterCallback = nil -- extra safety, we shouldn't get this far if CBH is not found, but better an error later than an infinite recursion now
      lib.callbacks = CBH:New(lib)
      -- ok, CBH hopefully injected or new shiny RegisterCallback
      return lib.RegisterCallback(...)
    end
end

--- END CallbackHandler stuff

lib:activate()