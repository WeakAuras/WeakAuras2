local WeakAuras = WeakAuras;
local L = WeakAuras.L;

local LSM = LibStub("LibSharedMedia-3.0");
local LibBabbleRace = LibStub("LibBabble-Race-3.0");
local LBR_Locale = LibBabbleRace:GetUnstrictLookupTable()
local LBR_Base = LibBabbleRace:GetBaseLookupTable();

-- luacheck: globals POWER_TYPE_MANA POWER_TYPE_RED_POWER POWER_TYPE_FOCUS POWER_TYPE_ENERGY POWER_TYPE_COMBO_POINTS POWER_TYPE_RUNIC_POWER SOUL_SHARDS_POWER POWER_TYPE_LUNAR_POWER POWER_TYPE_HOLY_POWER POWER_TYPE_MAELSTROM POWER_TYPE_CHI POWER_TYPE_INSANITY POWER_TYPE_ARCANE_CHARGES POWER_TYPE_FURY_DEMONHUNTER POWER_TYPE_PAIN STAT_STAGGER

local wipe, tinsert = wipe, tinsert
local GetNumShapeshiftForms, GetShapeshiftFormInfo = GetNumShapeshiftForms, GetShapeshiftFormInfo
local GetNumSpecializationsForClassID, GetSpecializationInfoForClassID = GetNumSpecializationsForClassID, GetSpecializationInfoForClassID

WeakAuras.glow_action_types = {
  show = L["Show"],
  hide = L["Hide"]
}

WeakAuras.circular_group_constant_factor_types = {
  RADIUS = L["Radius"],
  SPACING = L["Spacing"]
}

WeakAuras.frame_strata_types = {
  [1] = L["Inherited"],
  [2] = "BACKGROUND",
  [3] = "LOW",
  [4] = "MEDIUM",
  [5] = "HIGH",
  [6] = "DIALOG",
  [7] = "FULLSCREEN",
  [8] = "FULLSCREEN_DIALOG",
  [9] = "TOOLTIP"
}

WeakAuras.hostility_types = {
  hostile = L["Hostile"],
  friendly = L["Friendly"]
}

WeakAuras.character_types = {
  player = L["Player Character"],
  npc = L["Non-player Character"]
}

WeakAuras.group_sort_types = {
  ascending = L["Ascending"],
  descending = L["Descending"],
  hybrid = L["Hybrid"],
  none = L["None"]
}

WeakAuras.group_hybrid_position_types = {
  hybridFirst = L["Marked First"],
  hybridLast = L["Marked Last"]
}

WeakAuras.group_hybrid_sort_types = {
  ascending = L["Ascending"],
  descending = L["Descending"]
}

WeakAuras.precision_types = {
  [0] = "12",
  [1] = "12.3",
  [2] = "12.34",
  [3] = "12.345",
  [4] = "Dynamic 12.3", -- will show 1 digit precision when time is lower than 3 seconds, hardcoded
  [5] = "Dynamic 12.34" -- will show 2 digits precision when time is lower than 3 seconds, hardcoded
}

WeakAuras.sound_channel_types = {
  Master = L["Master"],
  SFX = L["Sound Effects"],
  Ambience = L["Ambience"],
  Music = L["Music"],
  Dialog = L["Dialog"]
}

WeakAuras.sound_condition_types = {
  Play = L["Play"],
  Loop = L["Loop"],
  Stop = L["Stop"]
}

WeakAuras.trigger_require_types = {
  any = L["Any Triggers"],
  all = L["All Triggers"],
  custom = L["Custom Function"]
}

WeakAuras.trigger_require_types_one = {
  any = L["Trigger 1"],
  custom = L["Custom Function"]
}

WeakAuras.trigger_modes = {
  ["first_active"] = -10,
}

WeakAuras.trigger_types = {
  aura = L["Aura"],
  status = L["Status"],
  event = L["Event"],
  custom = L["Custom"]
}

WeakAuras.debuff_types = {
  HELPFUL = L["Buff"],
  HARMFUL = L["Debuff"]
}

WeakAuras.tooltip_count = {
  [1] = L["First"],
  [2] = L["Second"],
  [3] = L["Third"]
}

WeakAuras.aura_types = {
  BUFF = L["Buff"],
  DEBUFF = L["Debuff"]
}

WeakAuras.debuff_class_types = {
  magic = L["Magic"],
  curse = L["Curse"],
  disease = L["Disease"],
  poison = L["Poison"],
  enrage = L["Enrage"],
  none = L["None"]
}

WeakAuras.unit_types = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  group = L["Group"],
  member = L["Specific Unit"],
  pet = L["Pet"],
  multi = L["Multi-target"]
}

WeakAuras.actual_unit_types_with_specific = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  pet = L["Pet"],
  member = L["Specific Unit"]
}

WeakAuras.actual_unit_types = {
  player = L["Player"],
  target = L["Target"],
  focus = L["Focus"],
  pet = L["Pet"]
}

WeakAuras.threat_unit_types = {
  target = L["Target"],
  focus = L["Focus"],
  member = L["Specific Unit"],
  none = L["At Least One Enemy"]
}

WeakAuras.unit_threat_situation_types = {
  [-1] = L["Not On Threat Table"],
  [0] = "|cFFB0B0B0"..L["Lower Than Tank"],
  [1] = "|cFFFFFF77"..L["Higher Than Tank"],
  [2] = "|cFFFF9900"..L["Tanking But Not Highest"],
  [3] = "|cFFFF0000"..L["Tanking And Highest"]
}

WeakAuras.class_types = {}
WeakAuras.class_color_types = {}
local C_S_O, R_C_C, L_C_N_M, F_C_C_C = _G.CLASS_SORT_ORDER, _G.RAID_CLASS_COLORS, _G.LOCALIZED_CLASS_NAMES_MALE, _G.FONT_COLOR_CODE_CLOSE
do
  for i,eClass in ipairs(C_S_O) do
    WeakAuras.class_color_types[eClass] = "|c"..R_C_C[eClass].colorStr
    WeakAuras.class_types[eClass] = WeakAuras.class_color_types[eClass]..L_C_N_M[eClass]..F_C_C_C
  end
end

local function LBR(key)
  return LBR_Locale[key] or LBR_Base[key];
end

WeakAuras.race_types = {
  Pandaren = LBR("Pandaren"),
  Worgen = LBR("Worgen"),
  Draenei = LBR("Draenei"),
  Dwarf = LBR("Dwarf"),
  Gnome = LBR("Gnome"),
  Human = LBR("Human"),
  NightElf = LBR("Night Elf"),
  Goblin = LBR("Goblin"),
  BloodElf = LBR("Blood Elf"),
  Orc = LBR("Orc"),
  Tauren = LBR("Tauren"),
  Troll = LBR("Troll"),
  Scourge = LBR("Undead"),
  LightforgedDraenei = LBR("Lightforged Draenei"),
  VoidElf = LBR("Void Elf"),
  HighmountainTauren = LBR("Highmountain Tauren"),
  Nightborne = LBR("Nightborne"),
  DarkIronDwarf = LBR("Dark Iron Dwarf"),
  ZandalariTroll = LBR("Zandalari Troll"),
  MagharOrc = LBR("Mag'har Orc"),
}

WeakAuras.faction_group = {
  Alliance = L["Alliance"],
  Horde = L["Horde"],
  Neutral = L["Neutral"]
}

WeakAuras.form_types = {};
local function update_forms()
  wipe(WeakAuras.form_types);
  WeakAuras.form_types[0] = "0 - "..L["Humanoid"]
  for i = 1, GetNumShapeshiftForms() do
    local _, _, _, id = GetShapeshiftFormInfo(i);
    if(id) then
      local name = GetSpellInfo(id);
      if(name) then
        WeakAuras.form_types[i] = i.." - "..name
      end
    end
  end
end
local form_frame = CreateFrame("frame");
form_frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
form_frame:RegisterEvent("PLAYER_LOGIN")
form_frame:SetScript("OnEvent", update_forms);

WeakAuras.blend_types = {
  ADD = L["Glow"],
  BLEND = L["Opaque"]
}

WeakAuras.texture_wrap_types = {
  CLAMP = L["Clamp"],
  MIRROR = L["Mirror"],
  REPEAT = L["Repeat"]
}

WeakAuras.slant_mode = {
  INSIDE = L["Keep Inside"],
  EXTEND = L["Extend Outside"]
}

WeakAuras.text_check_types = {
  update = L["Every Frame"],
  event = L["Trigger Update"]
}

WeakAuras.check_types = {
  update = L["Every Frame"],
  event = L["Event(s)"]
}

WeakAuras.point_types = {
  BOTTOMLEFT = L["Bottom Left"],
  BOTTOM = L["Bottom"],
  BOTTOMRIGHT = L["Bottom Right"],
  RIGHT = L["Right"],
  TOPRIGHT = L["Top Right"],
  TOP = L["Top"],
  TOPLEFT = L["Top Left"],
  LEFT = L["Left"],
  CENTER = L["Center"]
}

WeakAuras.inverse_point_types = {
  BOTTOMLEFT = "TOPRIGHT",
  BOTTOM = "TOP",
  BOTTOMRIGHT = "TOPLEFT",
  RIGHT = "LEFT",
  TOPRIGHT = "BOTTOMLEFT",
  TOP = "BOTTOM",
  TOPLEFT = "BOTTOMRIGHT",
  LEFT = "RIGHT",
  CENTER = "CENTER"
}

WeakAuras.anchor_frame_types = {
  SCREEN = L["Screen/Parent Group"],
  PRD = L["Personal Resource Display"],
  MOUSE = L["Mouse Cursor"],
  SELECTFRAME = L["Select Frame"]
}

WeakAuras.spark_rotation_types = {
  AUTO = L["Automatic Rotation"],
  MANUAL = L["Manual Rotation"]
}

WeakAuras.spark_hide_types = {
  NEVER = L["Never"],
  FULL  = L["Full"],
  EMPTY = L["Empty"],
  BOTH  = L["Full/Empty"]
}

WeakAuras.containment_types = {
  OUTSIDE = L["Outside"],
  INSIDE = L["Inside"]
}

WeakAuras.font_flags = {
  None = L["None"],
  MONOCHROME = L["Monochrome"],
  OUTLINE = L["Outline"],
  THICKOUTLINE  = L["Thick Outline"],
  ["MONOCHROME|OUTLINE"] = L["Monochrome Outline"],
  ["MONOCHROME|THICKOUTLINE"] = L["Monochrome Thick Outline"]
}

WeakAuras.text_automatic_width = {
  Auto = L["Automatic"],
  Fixed = L["Fixed"]
}

WeakAuras.text_word_wrap = {
  WordWrap = L["Wrap"],
  Elide = L["Elide"]
}

WeakAuras.event_types = {};
for name, prototype in pairs(WeakAuras.event_prototypes) do
  if(prototype.type == "event") then
    WeakAuras.event_types[name] = prototype.name;
  end
end

WeakAuras.status_types = {};
for name, prototype in pairs(WeakAuras.event_prototypes) do
  if(prototype.type == "status") then
    WeakAuras.status_types[name] = prototype.name;
  end
end

WeakAuras.subevent_prefix_types = {
  SWING = L["Swing"],
  RANGE = L["Range"],
  SPELL = L["Spell"],
  SPELL_PERIODIC = L["Periodic Spell"],
  SPELL_BUILDING = L["Spell (Building)"],
  ENVIRONMENTAL = L["Environmental"],
  DAMAGE_SHIELD = L["Damage Shield"],
  DAMAGE_SPLIT = L["Damage Split"],
  DAMAGE_SHIELD_MISSED = L["Damage Shield Missed"],
  PARTY_KILL = L["Party Kill"],
  UNIT_DIED = L["Unit Died"],
  UNIT_DESTROYED = L["Unit Destroyed"]
}

WeakAuras.subevent_actual_prefix_types = {
  SWING = L["Swing"],
  RANGE = L["Range"],
  SPELL = L["Spell"],
  SPELL_PERIODIC = L["Periodic Spell"],
  SPELL_BUILDING = L["Spell (Building)"],
  ENVIRONMENTAL = L["Environmental"]
}

WeakAuras.subevent_suffix_types = {
  _DAMAGE = L["Damage"],
  _MISSED = L["Missed"],
  _HEAL = L["Heal"],
  _ENERGIZE = L["Energize"],
  _DRAIN = L["Drain"],
  _LEECH = L["Leech"],
  _INTERRUPT = L["Interrupt"],
  _DISPEL = L["Dispel"],
  _DISPEL_FAILED = L["Dispel Failed"],
  _STOLEN = L["Stolen"],
  _EXTRA_ATTACKS = L["Extra Attacks"],
  _AURA_APPLIED = L["Aura Applied"],
  _AURA_REMOVED = L["Aura Removed"],
  _AURA_APPLIED_DOSE = L["Aura Applied Dose"],
  _AURA_REMOVED_DOSE = L["Aura Removed Dose"],
  _AURA_REFRESH = L["Aura Refresh"],
  _AURA_BROKEN = L["Aura Broken"],
  _AURA_BROKEN_SPELL = L["Aura Broken Spell"],
  _CAST_START = L["Cast Start"],
  _CAST_SUCCESS = L["Cast Success"],
  _CAST_FAILED = L["Cast Failed"],
  _INSTAKILL = L["Instakill"],
  _DURABILITY_DAMAGE = L["Durability Damage"],
  _DURABILITY_DAMAGE_ALL = L["Durability Damage All"],
  _CREATE = L["Create"],
  _SUMMON = L["Summon"],
  _RESURRECT = L["Resurrect"]
}

WeakAuras.power_types = {
  [0] = POWER_TYPE_MANA,
  [1] = POWER_TYPE_RED_POWER,
  [2] = POWER_TYPE_FOCUS,
  [3] = POWER_TYPE_ENERGY,
  [4] = COMBO_POINTS,
  [6] = RUNIC_POWER,
  [7] = SOUL_SHARDS_POWER,
  [8] = POWER_TYPE_LUNAR_POWER,
  [9] = HOLY_POWER,
  [11] = POWER_TYPE_MAELSTROM,
  [12] = CHI,
  [13] = POWER_TYPE_INSANITY,
  [16] = POWER_TYPE_ARCANE_CHARGES,
  [17] = POWER_TYPE_FURY_DEMONHUNTER,
  [18] = POWER_TYPE_PAIN
}

WeakAuras.power_types_with_stagger = {
  [0] = POWER_TYPE_MANA,
  [1] = POWER_TYPE_RED_POWER,
  [2] = POWER_TYPE_FOCUS,
  [3] = POWER_TYPE_ENERGY,
  [4] = COMBO_POINTS,
  [6] = RUNIC_POWER,
  [7] = SOUL_SHARDS_POWER,
  [8] = POWER_TYPE_LUNAR_POWER,
  [9] = HOLY_POWER,
  [11] = POWER_TYPE_MAELSTROM,
  [12] = CHI,
  [13] = POWER_TYPE_INSANITY,
  [16] = POWER_TYPE_ARCANE_CHARGES,
  [17] = POWER_TYPE_FURY_DEMONHUNTER,
  [18] = POWER_TYPE_PAIN,
  [99] = STAT_STAGGER
}

WeakAuras.miss_types = {
  ABSORB = L["Absorb"],
  BLOCK = L["Block"],
  DEFLECT = L["Deflect"],
  DODGE = L["Dodge"],
  EVADE = L["Evade"],
  IMMUNE = L["Immune"],
  MISS = L["Miss"],
  PARRY = L["Parry"],
  REFLECT = L["Reflect"],
  RESIST = L["Resist"]
}

WeakAuras.environmental_types = {
  Drowning = L["Drowning"],
  Falling = L["Falling"],
  Fatigue = L["Fatigue"],
  Fire = L["Fire"],
  Lava = L["Lava"],
  Slime = L["Slime"]
}

WeakAuras.combatlog_flags_check_type = {
  InGroup = L["In Group"],
  NotInGroup = L["Not in Group"]
}

WeakAuras.combatlog_raid_mark_check_type = {
  [0] = L["None"],
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1:0|t " .. L["Star"],
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_2:0|t " .. L["Circle"],
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_3:0|t " .. L["Diamond"],
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_4:0|t " .. L["Triangle"],
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_5:0|t " .. L["Moon"],
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6:0|t " .. L["Square"],
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_7:0|t " .. L["Cross"],
  "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8:0|t " .. L["Skull"],
  L["Any"]
}

WeakAuras.orientation_types = {
  HORIZONTAL_INVERSE = L["Left to Right"],
  HORIZONTAL = L["Right to Left"],
  VERTICAL = L["Bottom to Top"],
  VERTICAL_INVERSE = L["Top to Bottom"]
}

WeakAuras.orientation_with_circle_types = {
  HORIZONTAL_INVERSE = L["Left to Right"],
  HORIZONTAL = L["Right to Left"],
  VERTICAL = L["Bottom to Top"],
  VERTICAL_INVERSE = L["Top to Bottom"],
  CLOCKWISE = L["Clockwise"],
  ANTICLOCKWISE = L["Anticlockwise"]
}

WeakAuras.spec_types = {
  [1] = _G.SPECIALIZATION.." 1",
  [2] = _G.SPECIALIZATION.." 2",
  [3] = _G.SPECIALIZATION.." 3",
  [4] = _G.SPECIALIZATION.." 4"
}

WeakAuras.spec_types_3 = {
  [1] = _G.SPECIALIZATION.." 1",
  [2] = _G.SPECIALIZATION.." 2",
  [3] = _G.SPECIALIZATION.." 3"
}

WeakAuras.spec_types_2 = {
  [1] = _G.SPECIALIZATION.." 1",
  [2] = _G.SPECIALIZATION.." 2"
}

WeakAuras.spec_types_specific = {}
local function update_specs()
  for classFileName, classID in pairs(WeakAuras.class_ids) do
    WeakAuras.spec_types_specific[classFileName] = {}
    local numSpecs = GetNumSpecializationsForClassID(classID)
    for i=1, numSpecs do
      local _, tabName, _, icon = GetSpecializationInfoForClassID(classID, i);
      if tabName then
        tinsert(WeakAuras.spec_types_specific[classFileName], "|T"..(icon or "error")..":0|t "..(tabName or "error"));
      end
    end
  end
end

local spec_frame = CreateFrame("frame");
spec_frame:RegisterEvent("PLAYER_LOGIN")
spec_frame:SetScript("OnEvent", update_specs);
WeakAuras.talent_types = {}
do
  local numTalents, numTiers, numColumns = MAX_TALENT_TIERS * NUM_TALENT_COLUMNS, MAX_TALENT_TIERS, NUM_TALENT_COLUMNS
  local talentId, tier, column = 1, 1, 1
  while talentId <= numTalents do
    while tier <= numTiers do
      while column <= numColumns do
        WeakAuras.talent_types[talentId] = L["Tier "]..tier.." - "..column
        column = column + 1
        talentId = talentId + 1
      end
      column = 1
      tier = tier + 1
    end
    tier = 1
  end
end

WeakAuras.pvp_talent_types = {
  select(2, GetPvpTalentInfoByID(3589)),
  select(2, GetPvpTalentInfoByID(3588)),
  select(2, GetPvpTalentInfoByID(3587)),
  nil
};

for i = 1,10 do
  tinsert(WeakAuras.pvp_talent_types, string.format(L["PvP Talent %i"], i));
end

-- GetTotemInfo() only works for the first 5 totems
WeakAuras.totem_types = {};
local totemString = L["Totem #%i"];
for i = 1, 5 do
  WeakAuras.totem_types[i] = totemString:format(i);
end

WeakAuras.texture_types = {
  ["Blizzard Alerts"] = {
    ["Textures\\SpellActivationOverlays\\Arcane_Missiles"] = "Arcane Missiles",
    ["Textures\\SpellActivationOverlays\\Arcane_Missiles_1"] = "Arcane Missiles 1",
    ["Textures\\SpellActivationOverlays\\Arcane_Missiles_2"] = "Arcane Missiles 2",
    ["Textures\\SpellActivationOverlays\\Arcane_Missiles_3"] = "Arcane Missiles 3",
    ["Textures\\SpellActivationOverlays\\Art_of_War"] = "Art of War",
    ["Textures\\SpellActivationOverlays\\Backlash_Green"] = "Backlash_Green",
    ["Textures\\SpellActivationOverlays\\Bandits_Guile"] = "Bandits Guile",
    ["Textures\\SpellActivationOverlays\\Blood_Surge"] = "Blood Surge",
    ["Textures\\SpellActivationOverlays\\Brain_Freeze"] = "Brain Freeze",
    ["Textures\\SpellActivationOverlays\\Echo_of_the_Elements"] = "Echo of the Elements",
    ["Textures\\SpellActivationOverlays\\Eclipse_Moon"] = "Eclipse Moon",
    ["Textures\\SpellActivationOverlays\\Eclipse_Sun"] = "Eclipse Sun",
    ["Textures\\SpellActivationOverlays\\Focus_Fire"] = "Focus Fire",
    ["Textures\\SpellActivationOverlays\\Frozen_Fingers"] = "Frozen Fingers",
    ["Textures\\SpellActivationOverlays\\GenericArc_01"] = "Generic Arc 1",
    ["Textures\\SpellActivationOverlays\\GenericArc_02"] = "Generic Arc 2",
    ["Textures\\SpellActivationOverlays\\GenericArc_03"] = "Generic Arc 3",
    ["Textures\\SpellActivationOverlays\\GenericArc_04"] = "Generic Arc 4",
    ["Textures\\SpellActivationOverlays\\GenericArc_05"] = "Generic Arc 5",
    ["Textures\\SpellActivationOverlays\\GenericArc_06"] = "Generic Arc 6",
    ["Textures\\SpellActivationOverlays\\GenericTop_01"] = "Generic Top 1",
    ["Textures\\SpellActivationOverlays\\GenericTop_02"] = "Generic Top 2",
    ["Textures\\SpellActivationOverlays\\Grand_Crusader"] = "Grand Crusader",
    ["Textures\\SpellActivationOverlays\\Hot_Streak"] = "Hot Streak",
    ["Textures\\SpellActivationOverlays\\Imp_Empowerment"] = "Imp Empowerment",
    ["Textures\\SpellActivationOverlays\\Imp_Empowerment_Green"] = "Imp Empowerment Green",
    ["Textures\\SpellActivationOverlays\\Impact"] = "Impact",
    ["Textures\\SpellActivationOverlays\\Lock_and_Load"] = "Lock and Load",
    ["Textures\\SpellActivationOverlays\\Maelstrom_Weapon"] = "Maelstrom Weapon",
    ["Textures\\SpellActivationOverlays\\Maelstrom_Weapon_1"] = "Maelstrom Weapon 1",
    ["Textures\\SpellActivationOverlays\\Maelstrom_Weapon_2"] = "Maelstrom Weapon 2",
    ["Textures\\SpellActivationOverlays\\Maelstrom_Weapon_3"] = "Maelstrom Weapon 3",
    ["Textures\\SpellActivationOverlays\\Maelstrom_Weapon_4"] = "Maelstrom Weapon 4",
    ["Textures\\SpellActivationOverlays\\Master_Marksman"] = "Master Marksman",
    ["Textures\\SpellActivationOverlays\\Monk_BlackoutKick"] = "Monk Blackout Kick",
    ["Textures\\SpellActivationOverlays\\Natures_Grace"] = "Nature's Grace",
    ["Textures\\SpellActivationOverlays\\Nightfall"] = "Nightfall",
    ["Textures\\SpellActivationOverlays\\Predatory_Swiftness"] = "Predatory Swiftness",
    ["Textures\\SpellActivationOverlays\\Raging_Blow"] = "Raging Blow",
    ["Textures\\SpellActivationOverlays\\Rime"] = "Rime",
    ["Textures\\SpellActivationOverlays\\Slice_and_Dice"] = "Slice and Dice",
    ["Textures\\SpellActivationOverlays\\Sudden_Death"] = "Sudden Death",
    ["Textures\\SpellActivationOverlays\\Sudden_Doom"] = "Sudden Doom",
    ["Textures\\SpellActivationOverlays\\Surge_of_Light"] = "Surge of Light",
    ["Textures\\SpellActivationOverlays\\Sword_and_Board"] = "Sword and Board",
    ["Textures\\SpellActivationOverlays\\Thrill_of_the_Hunt_1"] = "Thrill of the Hunt 1",
    ["Textures\\SpellActivationOverlays\\Thrill_of_the_Hunt_2"] = "Thrill of the Hunt 2",
    ["Textures\\SpellActivationOverlays\\Thrill_of_the_Hunt_3"] = "Thrill of the Hunt 3",
    ["Textures\\SpellActivationOverlays\\Tooth_and_Claw"] = "Tooth and Claw",
    ["Textures\\SpellActivationOverlays\\Backlash"] = "Backslash",
    ["Textures\\SpellActivationOverlays\\Berserk"] = "Berserk",
    ["Textures\\SpellActivationOverlays\\Blood_Boil"] = "Blood Boil",
    ["Textures\\SpellActivationOverlays\\Dark_Transformation"] = "Dark Transformation",
    ["Textures\\SpellActivationOverlays\\Denounce"] = "Denounce",
    ["Textures\\SpellActivationOverlays\\Feral_OmenOfClarity"] = "Omen of Clarity (Feral)",
    ["Textures\\SpellActivationOverlays\\Fulmination"] = "Fulmination",
    ["Textures\\SpellActivationOverlays\\Fury_of_Stormrage"] = "Fury of Stormrage",
    ["Textures\\SpellActivationOverlays\\Hand_of_Light"] = "Hand of Light",
    ["Textures\\SpellActivationOverlays\\Killing_Machine"] = "Killing Machine",
    ["Textures\\SpellActivationOverlays\\Molten_Core"] = "Molten Core",
    ["Textures\\SpellActivationOverlays\\Molten_Core_Green"] = "Molten Core Green",
    ["Textures\\SpellActivationOverlays\\Necropolis"] = "Necropolis",
    ["Textures\\SpellActivationOverlays\\Serendipity"] = "Serendipity",
    ["Textures\\SpellActivationOverlays\\Shooting_Stars"] = "Shooting Stars",
    ["Textures\\SpellActivationOverlays\\Dark_Tiger"] = "Dark Tiger",
    ["Textures\\SpellActivationOverlays\\Daybreak"] = "Daybreak",
    ["Textures\\SpellActivationOverlays\\Monk_Ox"] = "Monk Ox",
    ["Textures\\SpellActivationOverlays\\Monk_Ox_2"] = "Monk Ox 2",
    ["Textures\\SpellActivationOverlays\\Monk_Ox_3"] = "Monk Ox 3",
    ["Textures\\SpellActivationOverlays\\Monk_Serpent"] = "Monk Serpent",
    ["Textures\\SpellActivationOverlays\\Monk_Tiger"] = "Monk Tiger",
    ["Textures\\SpellActivationOverlays\\Monk_TigerPalm"] = "Monk Tiger Palm",
    ["Textures\\SpellActivationOverlays\\Shadow_of_Death"] = "Shadow of Death",
    ["Textures\\SpellActivationOverlays\\Shadow_Word_Insanity"] = "Shadow Word Insanity",
    ["Textures\\SpellActivationOverlays\\Surge_of_Darkness"] = "Surge of Darkness",
    ["Textures\\SpellActivationOverlays\\Ultimatum"] = "Ultimatum",
    ["Textures\\SpellActivationOverlays\\White_Tiger"] = "White Tiger",
    ["Textures\\SpellActivationOverlays\\spellActivationOverlay_0"] = "Spell Activation Overlay 0"
  },
  ["Icons"] = {
    ["Spells\\Agility_128"] = "Paw",
    ["Spells\\ArrowFeather01"] = "Feathers",
    ["Spells\\Aspect_Beast"] = "Lion",
    ["Spells\\Aspect_Cheetah"] = "Cheetah",
    ["Spells\\Aspect_Hawk"] = "Hawk",
    ["Spells\\Aspect_Monkey"] = "Monkey",
    ["Spells\\Aspect_Snake"] = "Snake",
    ["Spells\\Aspect_Wolf"] = "Wolf",
    ["Spells\\EndlessRage"] = "Rage",
    ["Spells\\Eye"] = "Eye",
    ["Spells\\Eyes"] = "Eyes",
    ["Spells\\Fire_Rune_128"] = "Fire",
    ["Spells\\HolyRuinProtect"] = "Holy Ruin",
    ["Spells\\Intellect_128"] = "Intellect",
    ["Spells\\MoonCrescentGlow2"] = "Crescent",
    ["Spells\\Nature_Rune_128"] = "Leaf",
    ["Spells\\PROTECT_128"] = "Shield",
    ["Spells\\Ice_Rune_128"] = "Snowflake",
    ["Spells\\PoisonSkull1"] = "Poison Skull",
    ["Spells\\InnerFire_Rune_128"] = "Inner Fire",
    ["Spells\\RapidFire_Rune_128"] = "Rapid Fire",
    ["Spells\\Rampage"] = "Rampage",
    ["Spells\\Reticle_128"] = "Reticle",
    ["Spells\\Stamina_128"] = "Bull",
    ["Spells\\Strength_128"] = "Crossed Swords",
    ["Spells\\StunWhirl_reverse"] = "Stun Whirl",
    ["Spells\\T_Star3"] = "Star",
    ["Spells\\Spirit1"] = "Spirit"
  },
  ["Runes"] = {
    ["Spells\\starrune"] = "Star Rune",
    ["Spells\\RUNEBC1"] = "Heavy BC Rune",
    ["Spells\\RuneBC2"] = "Light BC Rune",
    ["Spells\\RUNEFROST"] = "Circular Frost Rune",
    ["Spells\\Rune1d_White"] = "Dense Circular Rune",
    ["Spells\\RUNE1D_GLOWLESS"] = "Sparse Circular Rune",
    ["Spells\\Rune1d"] = "Ringed Circular Rune",
    ["Spells\\Rune1c"] = "Filled Circular Rune",
    ["Spells\\RogueRune1"] = "Dual Blades",
    ["Spells\\RogueRune2"] = "Octagonal Skulls",
    ["Spells\\HOLY_RUNE1"] = "Holy Rune",
    ["Spells\\Holy_Rune_128"] = "Holy Cross Rune",
    ["Spells\\DemonRune5backup"] = "Demon Rune",
    ["Spells\\DemonRune6"] = "Demon Rune",
    ["Spells\\DemonRune7"] = "Demon Rune",
    ["Spells\\DemonicRuneSummon01"] = "Demonic Summon",
    ["Spells\\Death_Rune"] = "Death Rune",
    ["Spells\\DarkSummon"] = "Dark Summon",
    ["Spells\\AuraRune256b"] = "Square Aura Rune",
    ["Spells\\AURARUNE256"] = "Ringed Aura Rune",
    ["Spells\\AURARUNE8"] = "Spike-Ringed Aura Rune",
    ["Spells\\AuraRune7"] = "Tri-Circle Ringed Aura Rune",
    ["Spells\\AuraRune5Green"] = "Tri-Circle Aura Rune",
    ["Spells\\AURARUNE_C"] = "Oblong Aura Rune",
    ["Spells\\AURARUNE_B"] = "Sliced Aura Rune",
    ["Spells\\AURARUNE_A"] = "Small Tri-Circle Aura Rune"
  },
  ["PvP Emblems"] = {
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-1"] = "Wheelchair",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-2"] = "Recycle",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-3"] = "Biohazard",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-4"] = "Heart",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-5"] = "Lightning Bolt",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-6"] = "Bone",
    ["Interface\\PVPFrame\\PVP-Banner-Emblem-7"] = "Glove",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-2"] = "Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-3"] = "Bird Claw",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-4"] = "Canary",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-5"] = "Mushroom",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-6"] = "Cherries",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-7"] = "Ninja",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-8"] = "Dog Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-9"] = "Circled Drop",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-10"] = "Circled Glove",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-11"] = "Winged Blade",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-12"] = "Circled Cross",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-13"] = "Dynamite",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-14"] = "Intellect",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-15"] = "Feather",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-16"] = "Present",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-17"] = "Giant Jaws",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-18"] = "Drums",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-19"] = "Panda",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-20"] = "Crossed Clubs",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-21"] = "Skeleton Key",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-22"] = "Heart Potion",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-23"] = "Trophy",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-24"] = "Crossed Mallets",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-25"] = "Circled Cheetah",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-26"] = "Mutated Chicken",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-27"] = "Anvil",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-28"] = "Dwarf Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-29"] = "Brooch",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-30"] = "Spider",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-31"] = "Dual Hawks",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-32"] = "Cleaver",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-33"] = "Spiked Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-34"] = "Fist of Thunder",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-35"] = "Lean Bull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-36"] = "Mug",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-37"] = "Sliced Circle",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-38"] = "Totem",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-39"] = "Skull and Crossbones",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-40"] = "Voodoo Doll",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-41"] = "Dual Wolves",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-42"] = "Wolf",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-43"] = "Crossed Wrenches",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-44"] = "Saber-toothed Tiger",
    --["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-45"] = "Targeting Eye", -- Duplicate of 53
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-46"] = "Artifact Disc",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-47"] = "Dice",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-48"] = "Fish Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-49"] = "Crossed Axes",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-50"] = "Doughnut",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-51"] = "Human Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-52"] = "Eyeball",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-53"] = "Targeting Eye",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-54"] = "Monkey Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-55"] = "Circle Skull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-56"] = "Tipped Glass",
    --["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-57"] = "Saber-toothed Tiger", -- Duplicate of 44
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-58"] = "Pile of Weapons",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-59"] = "Mushrooms",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-60"] = "Pounding Mallet",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-61"] = "Winged Mask",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-62"] = "Axe",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-63"] = "Spiked Shield",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-64"] = "The Horns",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-65"] = "Ice Cream Cone",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-66"] = "Ornate Lockbox",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-67"] = "Roasting Marshmallow",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-68"] = "Smiley Bomb",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-69"] = "Fist",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-70"] = "Spirit Wings",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-71"] = "Ornate Pipe",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-72"] = "Scarab",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-73"] = "Glowing Ball",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-74"] = "Circular Rune",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-75"] = "Tree",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-76"] = "Flower Pot",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-77"] = "Night Elf Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-78"] = "Nested Egg",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-79"] = "Helmed Chicken",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-80"] = "Winged Boot",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-81"] = "Skull and Cross-Wrenches",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-82"] = "Cracked Skull",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-83"] = "Rocket",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-84"] = "Wooden Whistle",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-85"] = "Cogwheel",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-86"] = "Lizard Eye",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-87"] = "Baited Hook",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-88"] = "Beast Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-89"] = "Talons",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-90"] = "Rabbit",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-91"] = "4-Toed Pawprint",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-92"] = "Paw",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-93"] = "Mask",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-94"] = "Spiked Helm",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-95"] = "Dog Treat",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-96"] = "Targeted Orc",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-97"] = "Bird Face",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-98"] = "Lollipop",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-99"] = "5-Toed Pawprint",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-100"] = "Frightened Cat",
    ["Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-101"] = "Eagle Face"
  },
  ["Beams"] = {
    ["Textures\\SPELLCHAINEFFECTS\\Beam_Purple"] = "Purple Beam",
    ["Textures\\SPELLCHAINEFFECTS\\Beam_Red"] = "Red Beam",
    ["Textures\\SPELLCHAINEFFECTS\\Beam_RedDrops"] = "Red Drops Beam",
    ["Textures\\SPELLCHAINEFFECTS\\DrainManaLightning"] = "Drain Mana Lightning",
    ["Textures\\SPELLCHAINEFFECTS\\Ethereal_Ribbon_Spell"] = "Ethereal Ribbon",
    ["Textures\\SPELLCHAINEFFECTS\\Ghost1_Chain"] = "Ghost Chain",
    ["Textures\\SPELLCHAINEFFECTS\\Ghost2purple_Chain"] = "Purple Ghost Chain",
    ["Textures\\SPELLCHAINEFFECTS\\HealBeam"] = "Heal Beam",
    ["Textures\\SPELLCHAINEFFECTS\\Lightning"] = "Lightning",
    ["Textures\\SPELLCHAINEFFECTS\\LightningRed"] = "Red Lightning",
    ["Textures\\SPELLCHAINEFFECTS\\ManaBeam"] = "Mana Beam",
    ["Textures\\SPELLCHAINEFFECTS\\ManaBurnBeam"] = "Mana Burn Beam",
    ["Textures\\SPELLCHAINEFFECTS\\RopeBeam"] = "Rope",
    ["Textures\\SPELLCHAINEFFECTS\\ShockLightning"] = "Shock Lightning",
    ["Textures\\SPELLCHAINEFFECTS\\SoulBeam"] = "Soul Beam",
    ["Spells\\TEXTURES\\Beam_ChainGold"] = "Gold Chain",
    ["Spells\\TEXTURES\\Beam_ChainIron"] = "Iron Chain",
    ["Spells\\TEXTURES\\Beam_FireGreen"] = "Green Fire Beam",
    ["Spells\\TEXTURES\\Beam_FireRed"] = "Red Fire Beam",
    ["Spells\\TEXTURES\\Beam_Purple_02"] = "Straight Purple Beam",
    ["Spells\\TEXTURES\\Beam_Shadow_01"] = "Shadow Beam",
    ["Spells\\TEXTURES\\Beam_SmokeBrown"] = "Brown Smoke Beam",
    ["Spells\\TEXTURES\\Beam_SmokeGrey"] = "Grey Smoke Beam",
    ["Spells\\TEXTURES\\Beam_SpiritLink"] = "Spirit Link Beam",
    ["Spells\\TEXTURES\\Beam_SummonGargoyle"] = "Summon Gargoyle Beam",
    ["Spells\\TEXTURES\\Beam_VineGreen"] = "Green Vine",
    ["Spells\\TEXTURES\\Beam_VineRed"] = "Red Vine",
    ["Spells\\TEXTURES\\Beam_WaterBlue"] = "Blue Water Beam",
    ["Spells\\TEXTURES\\Beam_WaterGreen"] = "Green Water Beam"
  },
  ["Shapes"] = {
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth"] = "Smooth Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth_Border"] = "Smooth Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Squirrel"] = "Spiralled Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Squirrel_Border"] = "Spiralled Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_White"] = "Circle",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_White_Border"] = "Circle with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth"] = "Smooth Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border"] = "Smooth Square with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border2"] = "Smooth Square with Border 2",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Squirrel"] = "Spiralled Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Squirrel_Border"] = "Spiralled Square with Border",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White"] = "Square",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White_Border"] = "Square with Border"
  },
  ["Sparks"] = {
    ["Interface\\CastingBar\\UI-CastingBar-Spark"] = "Blizzard Spark",
    ["Insanity-Spark"] = "Blizzard Insanity Spark",
    ["XPBarAnim-OrangeSpark"] = "Blizzard XPBar Spark",
    ["GarrMission_EncounterBar-Spark"] = "Blizzard Garrison Mission Encounter Spark",
    ["Legionfall_BarSpark"]= "Blizzard Legionfall Spark",
    ["honorsystem-bar-spark"] = "Blizzard Honor System Spark",
    ["bonusobjectives-bar-spark"] = "Bonus Objectives Spark",
    ["worldstate-capturebar-spark-green"] = "Capture Bar Green Spark",
    ["worldstate-capturebar-spark-yellow"] = "Capture Bar Yellow Spark"
  }
}

if(WeakAuras.PowerAurasPath ~= "") then
  WeakAuras.texture_types["PowerAuras Heads-Up"] = {
    [WeakAuras.PowerAurasPath.."Aura1"] = "Runed Text",
    [WeakAuras.PowerAurasPath.."Aura2"] = "Runed Text On Ring",
    [WeakAuras.PowerAurasPath.."Aura3"] = "Power Waves",
    [WeakAuras.PowerAurasPath.."Aura4"] = "Majesty",
    [WeakAuras.PowerAurasPath.."Aura5"] = "Runed Ends",
    [WeakAuras.PowerAurasPath.."Aura6"] = "Extra Majesty",
    [WeakAuras.PowerAurasPath.."Aura7"] = "Triangular Highlights",
    [WeakAuras.PowerAurasPath.."Aura11"] = "Oblong Highlights",
    [WeakAuras.PowerAurasPath.."Aura16"] = "Thin Crescents",
    [WeakAuras.PowerAurasPath.."Aura17"] = "Crescent Highlights",
    [WeakAuras.PowerAurasPath.."Aura18"] = "Dense Runed Text",
    [WeakAuras.PowerAurasPath.."Aura23"] = "Runed Spiked Ring",
    [WeakAuras.PowerAurasPath.."Aura24"] = "Smoke",
    [WeakAuras.PowerAurasPath.."Aura28"] = "Flourished Text",
    [WeakAuras.PowerAurasPath.."Aura33"] = "Droplet Highlights"
  }
  WeakAuras.texture_types["PowerAuras Icons"] = {
    [WeakAuras.PowerAurasPath.."Aura8"] = "Rune",
    [WeakAuras.PowerAurasPath.."Aura9"] = "Stylized Ghost",
    [WeakAuras.PowerAurasPath.."Aura10"] = "Skull and Crossbones",
    [WeakAuras.PowerAurasPath.."Aura12"] = "Snowflake",
    [WeakAuras.PowerAurasPath.."Aura13"] = "Flame",
    [WeakAuras.PowerAurasPath.."Aura14"] = "Holy Rune",
    [WeakAuras.PowerAurasPath.."Aura15"] = "Zig-Zag Exclamation Point",
    [WeakAuras.PowerAurasPath.."Aura19"] = "Crossed Swords",
    [WeakAuras.PowerAurasPath.."Aura21"] = "Shield",
    [WeakAuras.PowerAurasPath.."Aura22"] = "Glow",
    [WeakAuras.PowerAurasPath.."Aura25"] = "Cross",
    [WeakAuras.PowerAurasPath.."Aura26"] = "Droplet",
    [WeakAuras.PowerAurasPath.."Aura27"] = "Alert",
    [WeakAuras.PowerAurasPath.."Aura29"] = "Paw",
    [WeakAuras.PowerAurasPath.."Aura30"] = "Bull",
    --   [WeakAuras.PowerAurasPath.."Aura31"] = "Heiroglyphics Horizontal",
    [WeakAuras.PowerAurasPath.."Aura32"] = "Heiroglyphics",
    [WeakAuras.PowerAurasPath.."Aura34"] = "Circled Arrow",
    [WeakAuras.PowerAurasPath.."Aura35"] = "Short Sword",
    --   [WeakAuras.PowerAurasPath.."Aura36"] = "Short Sword Horizontal",
    [WeakAuras.PowerAurasPath.."Aura45"] = "Circular Glow",
    [WeakAuras.PowerAurasPath.."Aura48"] = "Totem",
    [WeakAuras.PowerAurasPath.."Aura49"] = "Dragon Blade",
    [WeakAuras.PowerAurasPath.."Aura50"] = "Ornate Design",
    [WeakAuras.PowerAurasPath.."Aura51"] = "Inverted Holy Rune",
    [WeakAuras.PowerAurasPath.."Aura52"] = "Stylized Skull",
    [WeakAuras.PowerAurasPath.."Aura53"] = "Exclamation Point",
    [WeakAuras.PowerAurasPath.."Aura54"] = "Nonagon",
    [WeakAuras.PowerAurasPath.."Aura68"] = "Wings",
    [WeakAuras.PowerAurasPath.."Aura69"] = "Rectangle",
    [WeakAuras.PowerAurasPath.."Aura70"] = "Low Mana",
    [WeakAuras.PowerAurasPath.."Aura71"] = "Ghostly Eye",
    [WeakAuras.PowerAurasPath.."Aura72"] = "Circle",
    [WeakAuras.PowerAurasPath.."Aura73"] = "Ring",
    [WeakAuras.PowerAurasPath.."Aura74"] = "Square",
    [WeakAuras.PowerAurasPath.."Aura75"] = "Square Brackets",
    [WeakAuras.PowerAurasPath.."Aura76"] = "Bob-omb",
    [WeakAuras.PowerAurasPath.."Aura77"] = "Goldfish",
    [WeakAuras.PowerAurasPath.."Aura78"] = "Check",
    [WeakAuras.PowerAurasPath.."Aura79"] = "Ghostly Face",
    [WeakAuras.PowerAurasPath.."Aura84"] = "Overlapping Boxes",
    --   [WeakAuras.PowerAurasPath.."Aura85"] = "Overlapping Boxes 45°",
    --   [WeakAuras.PowerAurasPath.."Aura86"] = "Overlapping Boxes 270°",
    [WeakAuras.PowerAurasPath.."Aura87"] = "Fairy",
    [WeakAuras.PowerAurasPath.."Aura88"] = "Comet",
    [WeakAuras.PowerAurasPath.."Aura95"] = "Dual Spiral",
    [WeakAuras.PowerAurasPath.."Aura96"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura97"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura98"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura99"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura100"] = "Japanese Character",
    [WeakAuras.PowerAurasPath.."Aura101"] = "Ball of Flame",
    [WeakAuras.PowerAurasPath.."Aura102"] = "Zig-Zag",
    [WeakAuras.PowerAurasPath.."Aura103"] = "Thorny Ring",
    [WeakAuras.PowerAurasPath.."Aura110"] = "Hunter's Mark",
    --   [WeakAuras.PowerAurasPath.."Aura111"] = "Hunter's Mark Horizontal",
    [WeakAuras.PowerAurasPath.."Aura112"] = "Kaleidoscope",
    [WeakAuras.PowerAurasPath.."Aura113"] = "Jesus Face",
    [WeakAuras.PowerAurasPath.."Aura114"] = "Green Mushrrom",
    [WeakAuras.PowerAurasPath.."Aura115"] = "Red Mushroom",
    [WeakAuras.PowerAurasPath.."Aura116"] = "Fire Flower",
    [WeakAuras.PowerAurasPath.."Aura117"] = "Radioactive",
    [WeakAuras.PowerAurasPath.."Aura118"] = "X",
    [WeakAuras.PowerAurasPath.."Aura119"] = "Flower",
    [WeakAuras.PowerAurasPath.."Aura120"] = "Petal",
    [WeakAuras.PowerAurasPath.."Aura130"] = "Shoop Da Woop",
    [WeakAuras.PowerAurasPath.."Aura131"] = "8-Bit Symbol",
    [WeakAuras.PowerAurasPath.."Aura132"] = "Cartoon Skull",
    [WeakAuras.PowerAurasPath.."Aura138"] = "Stop",
    [WeakAuras.PowerAurasPath.."Aura139"] = "Thumbs Up",
    [WeakAuras.PowerAurasPath.."Aura140"] = "Palette",
    [WeakAuras.PowerAurasPath.."Aura141"] = "Blue Ring",
    [WeakAuras.PowerAurasPath.."Aura142"] = "Ornate Ring",
    [WeakAuras.PowerAurasPath.."Aura143"] = "Ghostly Skull"
  }
  WeakAuras.texture_types["PowerAuras Separated"] = {
    [WeakAuras.PowerAurasPath.."Aura46"] = "8-Part Ring 1",
    [WeakAuras.PowerAurasPath.."Aura47"] = "8-Part Ring 2",
    [WeakAuras.PowerAurasPath.."Aura55"] = "Skull on Gear 1",
    [WeakAuras.PowerAurasPath.."Aura56"] = "Skull on Gear 2",
    [WeakAuras.PowerAurasPath.."Aura57"] = "Skull on Gear 3",
    [WeakAuras.PowerAurasPath.."Aura58"] = "Skull on Gear 4",
    [WeakAuras.PowerAurasPath.."Aura59"] = "Rune Ring Full",
    [WeakAuras.PowerAurasPath.."Aura60"] = "Rune Ring Empty",
    [WeakAuras.PowerAurasPath.."Aura61"] = "Rune Ring Left",
    [WeakAuras.PowerAurasPath.."Aura62"] = "Rune Ring Right",
    [WeakAuras.PowerAurasPath.."Aura63"] = "Spiked Rune Ring Full",
    [WeakAuras.PowerAurasPath.."Aura64"] = "Spiked Rune Ring Empty",
    [WeakAuras.PowerAurasPath.."Aura65"] = "Spiked Rune Ring Left",
    [WeakAuras.PowerAurasPath.."Aura66"] = "Spiked Rune Ring Bottom",
    [WeakAuras.PowerAurasPath.."Aura67"] = "Spiked Rune Ring Right",
    [WeakAuras.PowerAurasPath.."Aura80"] = "Spiked Helm Background",
    [WeakAuras.PowerAurasPath.."Aura81"] = "Spiked Helm Full",
    [WeakAuras.PowerAurasPath.."Aura82"] = "Spiked Helm Bottom",
    [WeakAuras.PowerAurasPath.."Aura83"] = "Spiked Helm Top",
    [WeakAuras.PowerAurasPath.."Aura89"] = "5-Part Ring 1",
    [WeakAuras.PowerAurasPath.."Aura90"] = "5-Part Ring 2",
    [WeakAuras.PowerAurasPath.."Aura91"] = "5-Part Ring 3",
    [WeakAuras.PowerAurasPath.."Aura92"] = "5-Part Ring 4",
    [WeakAuras.PowerAurasPath.."Aura93"] = "5-Part Ring 5",
    [WeakAuras.PowerAurasPath.."Aura94"] = "5-Part Ring Full",
    [WeakAuras.PowerAurasPath.."Aura104"] = "Shield Center",
    [WeakAuras.PowerAurasPath.."Aura105"] = "Shield Full",
    [WeakAuras.PowerAurasPath.."Aura106"] = "Shield Top Right",
    [WeakAuras.PowerAurasPath.."Aura107"] = "Shiled Top Left",
    [WeakAuras.PowerAurasPath.."Aura108"] = "Shield Bottom Right",
    [WeakAuras.PowerAurasPath.."Aura109"] = "Shield Bottom Left",
    [WeakAuras.PowerAurasPath.."Aura121"] = "Vine Top Right Leaf",
    [WeakAuras.PowerAurasPath.."Aura122"] = "Vine Left Leaf",
    [WeakAuras.PowerAurasPath.."Aura123"] = "Vine Bottom Right Leaf",
    [WeakAuras.PowerAurasPath.."Aura124"] = "Vine Stem",
    [WeakAuras.PowerAurasPath.."Aura125"] = "Vine Thorns",
    [WeakAuras.PowerAurasPath.."Aura126"] = "3-Part Circle 1",
    [WeakAuras.PowerAurasPath.."Aura127"] = "3-Part Circle 2",
    [WeakAuras.PowerAurasPath.."Aura128"] = "3-Part Circle 3",
    [WeakAuras.PowerAurasPath.."Aura129"] = "3-Part Circle Full",
    [WeakAuras.PowerAurasPath.."Aura133"] = "Sliced Orb 1",
    [WeakAuras.PowerAurasPath.."Aura134"] = "Sliced Orb 2",
    [WeakAuras.PowerAurasPath.."Aura135"] = "Sliced Orb 3",
    [WeakAuras.PowerAurasPath.."Aura136"] = "Sliced Orb 4",
    [WeakAuras.PowerAurasPath.."Aura137"] = "Sliced Orb 5",
    [WeakAuras.PowerAurasPath.."Aura144"] = "Taijitu Bottom",
    [WeakAuras.PowerAurasPath.."Aura145"] = "Taijitu Top"
  }
  WeakAuras.texture_types["PowerAuras Words"] = {
    [WeakAuras.PowerAurasPath.."Aura20"] = "Power",
    [WeakAuras.PowerAurasPath.."Aura37"] = "Slow",
    [WeakAuras.PowerAurasPath.."Aura38"] = "Stun",
    [WeakAuras.PowerAurasPath.."Aura39"] = "Silence",
    [WeakAuras.PowerAurasPath.."Aura40"] = "Root",
    [WeakAuras.PowerAurasPath.."Aura41"] = "Disorient",
    [WeakAuras.PowerAurasPath.."Aura42"] = "Dispell",
    [WeakAuras.PowerAurasPath.."Aura43"] = "Danger",
    [WeakAuras.PowerAurasPath.."Aura44"] = "Buff",
    [WeakAuras.PowerAurasPath.."Aura44"] = "Buff",
    ["Interface\\AddOns\\WeakAuras\\Media\\Textures\\interrupt"] = "Interrupt"
  }
end

WeakAuras.operator_types = {
  ["=="] = L["="],
  ["~="] = L["!="],
  [">"] = L[">"],
  ["<"] = L["<"],
  [">="] = L[">="],
  ["<="] = L["<="]
}

WeakAuras.equality_operator_types = {
  ["=="] = L["="],
  ["~="] = L["!="]
}

WeakAuras.operator_types_without_equal = {
  [">="] = L[">="],
  ["<="] = L["<="]
}

WeakAuras.string_operator_types = {
  ["=="] = L["Is Exactly"],
  ["find('%s')"] = L["Contains"],
  ["match('%s')"] = L["Matches (Pattern)"]
}

WeakAuras.weapon_types = {
  ["main"] = L["Main Hand"],
  ["off"] = L["Off Hand"]
}

WeakAuras.swing_types = {
  ["main"] = L["Main Hand"],
  ["off"] = L["Off Hand"]
}

WeakAuras.rune_specific_types = {
  [1] = L["Rune #1"],
  [2] = L["Rune #2"],
  [3] = L["Rune #3"],
  [4] = L["Rune #4"],
  [5] = L["Rune #5"],
  [6] = L["Rune #6"]
}

WeakAuras.custom_trigger_types = {
  ["event"] = L["Event"],
  ["status"] = L["Status"],
  ["stateupdate"] = L["Trigger State Updater"]
}

WeakAuras.eventend_types = {
  ["timed"] = L["Timed"],
  ["custom"] = L["Custom"]
}

WeakAuras.autoeventend_types = {
  ["auto"] = L["Automatic"],
  ["custom"] = L["Custom"]
}

WeakAuras.justify_types = {
  ["LEFT"] = L["Left"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Right"]
}

WeakAuras.grow_types = {
  ["LEFT"] = L["Left"],
  ["RIGHT"] = L["Right"],
  ["UP"] = L["Up"],
  ["DOWN"] = L["Down"],
  ["HORIZONTAL"] = L["Centered Horizontal"],
  ["VERTICAL"] = L["Centered Vertical"],
  ["CIRCLE"] = L["Counter Clockwise"],
  ["COUNTERCIRCLE"] =L["Clockwise"]
}

WeakAuras.text_rotate_types = {
  ["LEFT"] = L["Left"],
  ["NONE"] = L["None"],
  ["RIGHT"] = L["Right"]
}

WeakAuras.align_types = {
  ["LEFT"] = L["Left"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Right"]
}

WeakAuras.rotated_align_types = {
  ["LEFT"] = L["Top"],
  ["CENTER"] = L["Center"],
  ["RIGHT"] = L["Bottom"]
}

WeakAuras.icon_side_types = {
  ["LEFT"] = L["Left"],
  ["RIGHT"] = L["Right"]
}

WeakAuras.rotated_icon_side_types = {
  ["LEFT"] = L["Top"],
  ["RIGHT"] = L["Bottom"]
}

WeakAuras.anim_types = {
  none = L["None"],
  preset = L["Preset"],
  custom = L["Custom"]
}

WeakAuras.anim_translate_types = {
  straightTranslate = L["Normal"],
  circle = L["Circle"],
  spiral = L["Spiral"],
  spiralandpulse = L["Spiral In And Out"],
  shake = L["Shake"],
  bounce = L["Bounce"],
  bounceDecay = L["Bounce with Decay"],
  custom = L["Custom Function"]
}

WeakAuras.anim_scale_types = {
  straightScale = L["Normal"],
  pulse = L["Pulse"],
  fauxspin = L["Spin"],
  fauxflip = L["Flip"],
  custom = L["Custom Function"]
}

WeakAuras.anim_alpha_types = {
  straight = L["Normal"],
  alphaPulse = L["Pulse"],
  hide = L["Hide"],
  custom = L["Custom Function"]
}

WeakAuras.anim_rotate_types = {
  straight = L["Normal"],
  backandforth = L["Back and Forth"],
  wobble = L["Wobble"],
  custom = L["Custom Function"]
}

WeakAuras.anim_color_types = {
  straightColor = L["Legacy RGB Gradient"],
  straightHSV = L["Gradient"],
  pulseColor = L["Legacy RGB Gradient Pulse"],
  pulseHSV = L["Gradient Pulse"],
  custom = L["Custom Function"]
}

WeakAuras.instance_types = {
  none = L["No Instance"],
  scenario = L["Scenario"],
  party = L["5 Man Dungeon"],
  ten = L["10 Man Raid"],
  twenty = L["20 Man Raid"],
  twentyfive = L["25 Man Raid"],
  fortyman = L["40 Man Raid"],
  flexible = L["Flex Raid"],
  pvp = L["Battleground"],
  arena = L["Arena"]
}

WeakAuras.group_types = {
  solo = L["Not in Group"],
  group = L["In Group"],
  raid = L["In Raid"]
}

WeakAuras.difficulty_types = {
  none = L["None"],
  normal = L["Normal"],
  heroic = L["Heroic"],
  mythic = L["Mythic"],
  timewalking = L["Timewalking"],
  lfr = L["Looking for Raid"],
  challenge = L["Challenge"]
}

WeakAuras.role_types = {
  TANK = L["Tank"],
  DAMAGER = L["Damager"],
  HEALER = L["Healer"]
}

WeakAuras.anim_start_preset_types = {
  slidetop = L["Slide from Top"],
  slideleft = L["Slide from Left"],
  slideright = L["Slide from Right"],
  slidebottom = L["Slide from Bottom"],
  fade = L["Fade In"],
  shrink = L["Grow"],
  grow = L["Shrink"],
  spiral = L["Spiral"],
  bounceDecay = L["Bounce"]
}

WeakAuras.anim_main_preset_types = {
  shake = L["Shake"],
  spin = L["Spin"],
  flip = L["Flip"],
  wobble = L["Wobble"],
  pulse = L["Pulse"],
  alphaPulse = L["Flash"],
  rotateClockwise = L["Rotate Right"],
  rotateCounterClockwise = L["Rotate Left"],
  spiralandpulse = L["Spiral"],
  orbit = L["Orbit"],
  bounce = L["Bounce"]
}

WeakAuras.anim_finish_preset_types = {
  slidetop = L["Slide to Top"],
  slideleft = L["Slide to Left"],
  slideright = L["Slide to Right"],
  slidebottom = L["Slide to Bottom"],
  fade = L["Fade Out"],
  shrink = L["Shrink"],
  grow =L["Grow"],
  spiral = L["Spiral"],
  bounceDecay = L["Bounce"]
};

WeakAuras.chat_message_types = {
  CHAT_MSG_INSTANCE_CHAT = L["Instance"],
  CHAT_MSG_BG_SYSTEM_NEUTRAL = L["BG-System Neutral"],
  CHAT_MSG_BG_SYSTEM_ALLIANCE = L["BG-System Alliance"],
  CHAT_MSG_BG_SYSTEM_HORDE = L["BG-System Horde"],
  CHAT_MSG_BN_WHISPER = L["Battle.net Whisper"],
  CHAT_MSG_CHANNEL = L["Channel"],
  CHAT_MSG_EMOTE = L["Emote"],
  CHAT_MSG_GUILD = L["Guild"],
  CHAT_MSG_MONSTER_YELL = L["Monster Yell"],
  CHAT_MSG_MONSTER_EMOTE = L["Monster Emote"],
  CHAT_MSG_MONSTER_SAY = L["Monster Say"],
  CHAT_MSG_MONSTER_WHISPER = L["Monster Whisper"],
  CHAT_MSG_MONSTER_PARTY = L["Monster Party"],
  CHAT_MSG_OFFICER = L["Officer"],
  CHAT_MSG_PARTY = L["Party"],
  CHAT_MSG_RAID = L["Raid"],
  CHAT_MSG_RAID_BOSS_EMOTE = L["Boss Emote"],
  CHAT_MSG_RAID_BOSS_WHISPER = L["Boss Whisper"],
  CHAT_MSG_RAID_WARNING = L["Raid Warning"],
  CHAT_MSG_SAY = L["Say"],
  CHAT_MSG_WHISPER = L["Whisper"],
  CHAT_MSG_YELL = L["Yell"],
  CHAT_MSG_SYSTEM = L["System"]
}

WeakAuras.send_chat_message_types = {
  WHISPER = L["Whisper"],
  CHANNEL = L["Channel"],
  SAY = L["Say"],
  EMOTE = L["Emote"],
  YELL = L["Yell"],
  PARTY = L["Party"],
  GUILD = L["Guild"],
  OFFICER = L["Officer"],
  RAID = L["Raid"],
  SMARTRAID = L["BG>Raid>Party>Say"],
  RAID_WARNING = L["Raid Warning"],
  INSTANCE_CHAT = L["Instance"],
  COMBAT = L["Blizzard Combat Text"],
  PRINT = L["Chat Frame"]
}

WeakAuras.group_aura_name_info_types = {
  aura = L["Aura Name"],
  players = L["Player(s) Affected"],
  nonplayers = L["Player(s) Not Affected"]
}

WeakAuras.group_aura_stack_info_types = {
  count = L["Number Affected"],
  stack = L["Aura Stack"]
}

WeakAuras.cast_types = {
  cast = L["Cast"],
  channel = L["Channel (Spell)"]
}

-- register sounds
LSM:Register("sound", "Batman Punch", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BatmanPunch.ogg")
LSM:Register("sound", "Bike Horn", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BikeHorn.ogg")
LSM:Register("sound", "Boxing Arena Gong", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BoxingArenaSound.ogg")
LSM:Register("sound", "Bleat", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Bleat.ogg")
LSM:Register("sound", "Cartoon Hop", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonHop.ogg")
LSM:Register("sound", "Cat Meow", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CatMeow2.ogg")
LSM:Register("sound", "Kitten Meow", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\KittenMeow.ogg")
LSM:Register("sound", "Robot Blip", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RobotBlip.ogg")
LSM:Register("sound", "Sharp Punch", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SharpPunch.ogg")
LSM:Register("sound", "Water Drop", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\WaterDrop.ogg")
LSM:Register("sound", "Air Horn", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\AirHorn.ogg")
LSM:Register("sound", "Applause", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Applause.ogg")
LSM:Register("sound", "Banana Peel Slip", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BananaPeelSlip.ogg")
LSM:Register("sound", "Blast", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Blast.ogg")
LSM:Register("sound", "Cartoon Voice Baritone", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonVoiceBaritone.ogg")
LSM:Register("sound", "Cartoon Walking", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonWalking.ogg")
LSM:Register("sound", "Cow Mooing", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CowMooing.ogg")
LSM:Register("sound", "Ringing Phone", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RingingPhone.ogg")
LSM:Register("sound", "Roaring Lion", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RoaringLion.ogg")
LSM:Register("sound", "Shotgun", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Shotgun.ogg")
LSM:Register("sound", "Squish Fart", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SquishFart.ogg")
LSM:Register("sound", "Temple Bell", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\TempleBellHuge.ogg")
LSM:Register("sound", "Torch", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Torch.ogg")
LSM:Register("sound", "Warning Siren", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\WarningSiren.ogg")
LSM:Register("sound", "Lich King Apocalypse", "Sound\\Creature\\LichKing\\IC_Lich King_Special01.ogg")

if(WeakAuras.PowerAurasSoundPath ~= "") then
  LSM:Register("sound", "Aggro", WeakAuras.PowerAurasSoundPath.."aggro.ogg")
  LSM:Register("sound", "Arrow Swoosh", WeakAuras.PowerAurasSoundPath.."Arrow_swoosh.ogg")
  LSM:Register("sound", "Bam", WeakAuras.PowerAurasSoundPath.."bam.ogg")
  LSM:Register("sound", "Polar Bear", WeakAuras.PowerAurasSoundPath.."bear_polar.ogg")
  LSM:Register("sound", "Big Kiss", WeakAuras.PowerAurasSoundPath.."bigkiss.ogg")
  LSM:Register("sound", "Bite", WeakAuras.PowerAurasSoundPath.."BITE.ogg")
  LSM:Register("sound", "Burp", WeakAuras.PowerAurasSoundPath.."burp4.ogg")
  LSM:Register("sound", "Cat", WeakAuras.PowerAurasSoundPath.."cat2.ogg")
  LSM:Register("sound", "Chant Major 2nd", WeakAuras.PowerAurasSoundPath.."chant2.ogg")
  LSM:Register("sound", "Chant Minor 3rd", WeakAuras.PowerAurasSoundPath.."chant4.ogg")
  LSM:Register("sound", "Chimes", WeakAuras.PowerAurasSoundPath.."chimes.ogg")
  LSM:Register("sound", "Cookie Monster", WeakAuras.PowerAurasSoundPath.."cookie.ogg")
  LSM:Register("sound", "Electrical Spark", WeakAuras.PowerAurasSoundPath.."ESPARK1.ogg")
  LSM:Register("sound", "Fireball", WeakAuras.PowerAurasSoundPath.."Fireball.ogg")
  LSM:Register("sound", "Gasp", WeakAuras.PowerAurasSoundPath.."Gasp.ogg")
  LSM:Register("sound", "Heartbeat", WeakAuras.PowerAurasSoundPath.."heartbeat.ogg")
  LSM:Register("sound", "Hiccup", WeakAuras.PowerAurasSoundPath.."hic3.ogg")
  LSM:Register("sound", "Huh?", WeakAuras.PowerAurasSoundPath.."huh_1.ogg")
  LSM:Register("sound", "Hurricane", WeakAuras.PowerAurasSoundPath.."hurricane.ogg")
  LSM:Register("sound", "Hyena", WeakAuras.PowerAurasSoundPath.."hyena.ogg")
  LSM:Register("sound", "Kaching", WeakAuras.PowerAurasSoundPath.."kaching.ogg")
  LSM:Register("sound", "Moan", WeakAuras.PowerAurasSoundPath.."moan.ogg")
  LSM:Register("sound", "Panther", WeakAuras.PowerAurasSoundPath.."panther1.ogg")
  LSM:Register("sound", "Phone", WeakAuras.PowerAurasSoundPath.."phone.ogg")
  LSM:Register("sound", "Punch", WeakAuras.PowerAurasSoundPath.."PUNCH.ogg")
  LSM:Register("sound", "Rain", WeakAuras.PowerAurasSoundPath.."rainroof.ogg")
  LSM:Register("sound", "Rocket", WeakAuras.PowerAurasSoundPath.."rocket.ogg")
  LSM:Register("sound", "Ship's Whistle", WeakAuras.PowerAurasSoundPath.."shipswhistle.ogg")
  LSM:Register("sound", "Gunshot", WeakAuras.PowerAurasSoundPath.."shot.ogg")
  LSM:Register("sound", "Snake Attack", WeakAuras.PowerAurasSoundPath.."snakeatt.ogg")
  LSM:Register("sound", "Sneeze", WeakAuras.PowerAurasSoundPath.."sneeze.ogg")
  LSM:Register("sound", "Sonar", WeakAuras.PowerAurasSoundPath.."sonar.ogg")
  LSM:Register("sound", "Splash", WeakAuras.PowerAurasSoundPath.."splash.ogg")
  LSM:Register("sound", "Squeaky Toy", WeakAuras.PowerAurasSoundPath.."Squeakypig.ogg")
  LSM:Register("sound", "Sword Ring", WeakAuras.PowerAurasSoundPath.."swordecho.ogg")
  LSM:Register("sound", "Throwing Knife", WeakAuras.PowerAurasSoundPath.."throwknife.ogg")
  LSM:Register("sound", "Thunder", WeakAuras.PowerAurasSoundPath.."thunder.ogg")
  LSM:Register("sound", "Wicked Male Laugh", WeakAuras.PowerAurasSoundPath.."wickedmalelaugh1.ogg")
  LSM:Register("sound", "Wilhelm Scream", WeakAuras.PowerAurasSoundPath.."wilhelm.ogg")
  LSM:Register("sound", "Wicked Female Laugh", WeakAuras.PowerAurasSoundPath.."wlaugh.ogg")
  LSM:Register("sound", "Wolf Howl", WeakAuras.PowerAurasSoundPath.."wolf5.ogg")
  LSM:Register("sound", "Yeehaw", WeakAuras.PowerAurasSoundPath.."yeehaw.ogg")
end

WeakAuras.sound_types = {
  [" custom"] = " " .. L["Custom"],
  [" KitID"] = " " .. L["Sound by Kit ID"]
}

for name, path in next, LSM:HashTable("sound") do
  WeakAuras.sound_types[path] = name
end

LSM.RegisterCallback(WeakAuras, "LibSharedMedia_Registered", function(_, mediatype, key)
  if mediatype == "sound" then
    local path = LSM:Fetch(mediatype, key)
    if path then
      WeakAuras.sound_types[path] = key
    end
  end
end)

-- register options font
LSM:Register("font", "Fira Mono Medium", "Interface\\Addons\\WeakAuras\\Media\\Fonts\\FiraMono-Medium.ttf")

WeakAuras.duration_types = {
  seconds = L["Seconds"],
  relative = L["Relative"]
}

WeakAuras.duration_types_no_choice = {
  seconds = L["Seconds"]
}

WeakAuras.gtfo_types = {
  [1] = L["High Damage"],
  [2] = L["Low Damage"],
  [3] = L["Fail Alert"],
  [4] = L["Friendly Fire"]
}

WeakAuras.pet_behavior_types = {
  passive = L["Passive"],
  defensive = L["Defensive"],
  assist = L["Assist"]
}

WeakAuras.pet_spec_types = {
  [1] = L["Ferocity"],
  [2] = L["Tenacity"],
  [3] = L["Cunning"]
}

WeakAuras.cooldown_progress_behavior_types = {
  showOnCooldown = L["On Cooldown"],
  showOnReady = L["Not on Cooldown"],
  showAlways = L["Always"]
}

WeakAuras.bufftrigger_progress_behavior_types = {
  showOnActive = L["Buffed/Debuffed"],
  showOnMissing = L["Missing"],
  showAlways= L["Always"]
}

WeakAuras.item_slot_types = {
  [1]  = L["Head"],
  [2]  = L["Neck"],
  [3]  = L["Shoulder"],
  [5]  = L["Chest"],
  [6]  = L["Waist"],
  [7]  = L["Legs"],
  [8]  = L["Feet"],
  [9]  = L["Wrist"],
  [10] = L["Hands"],
  [11] = L["Finger 1"],
  [12] = L["Finger 2"],
  [13] = L["Trinket 1"],
  [14] = L["Trinket 2"],
  [15] = L["Back"],
  [19] = L["Tabard"]
}

WeakAuras.charges_change_type = {
  GAINED = L["Gained"],
  LOST = L["Lost"],
  CHANGED = L["Changed"]
}

WeakAuras.charges_change_condition_type = {
  GAINED = L["Gained"],
  LOST = L["Lost"]
}

WeakAuras.combat_event_type = {
  PLAYER_REGEN_ENABLED = L["Leaving"],
  PLAYER_REGEN_DISABLED = L["Entering"]
}

WeakAuras.bool_types = {
  [0] = L["False"],
  [1] = L["True"]
}

WeakAuras.absorb_modes = {
  OVERLAY_FROM_START = L["Attach to Start"],
  OVERLAY_FROM_END = L["Attach to End"]
}

WeakAuras.mythic_plus_affixes = {
  [2] = true,
  [3] = true,
  [4] = true,
  [5] = true,
  [6] = true,
  [7] = true,
  [8] = true,
  [9] = true,
  [10] = true,
  [11] = true,
  [12] = true,
  [13] = true,
  [14] = true,
  [16] = true,
}

for k in pairs(WeakAuras.mythic_plus_affixes) do
  WeakAuras.mythic_plus_affixes[k] = C_ChallengeMode.GetAffixInfo(k);
end

WeakAuras.update_categories = {
  {
    name = "anchor",
    fields = {
      "xOffset",
      "yOffset",
      "selfPoint",
      "anchorPoint",
      "anchorFrameType",
      "anchorFrameFrame",
      "frameStrata",
      "height",
      "width",
      "fontSize",
      "scale",
    },
    label = L["Size & Position"],
  },
  {
    name = "name",
    fields = {"id"},
    label = L["Aura Names"],
  },
  {
    name = "metadata",
    fields = {
      "url",
      "desc",
    },
    label = L["Meta Data"],
  },
  {
    name = "display",
    fields = {},
    label = L["Display"],
  },
  {
    name = "trigger",
    fields = {
      "trigger",
      "untrigger",
      "disjunctive",
      "additional_triggers",
      "activeTriggerMode",
      "numTriggers",
      "customTriggerLogic"
    },
    label = L["Trigger"],
  },
  {
    name = "conditions",
    fields = {"conditions"},
    label = L["Conditions"],
  },
  {
    name = "load",
    fields = {"load"},
    label = L["Load Conditions"],
  },
  {
    name = "action",
    fields = {"actions"},
    label = L["Actions"],
  },
  {
    name = "animation",
    fields = {"animation"},
    label = L["Animations"],
  },
  {
    name = "arrangement",
    fields = {},
    label = L["Group Arrangement"],
  },
  {
    name = "oldchildren",
    fields = {},
    label = L["Remove Obsolete Auras"],
  },
  {
    name = "newchildren",
    fields = {},
    label = L["Add Missing Auras"],
  },
}

WeakAuras.internal_fields = {
  uid = true,
  controlledChildren = true,
  parent = true,
  internalVersion = true,
  sortHybridTable = true,
  expanded = true,
  parent = true,
  init_started = true,
}

WeakAuras.data_stub = {
  -- note: this is the minimal data stub which prevents false positives in WeakAuras.diff upon reimporting an aura.
  -- pending a refactor of other code which adds unnecessary fields, it is possible to shrink it
  trigger = {
    type = "aura",
    names = {},
    event = "Health",
    subeventPrefix = "SPELL",
    subeventSuffix = "_CAST_START",
    spellIds = {},
    unit = "player",
    debuffType = "HELPFUL",
  },
  numTriggers = 1,
  untrigger = {},
  load = {
    size = {
      multi = {},
    },
    spec = {
      multi = {},
    },
    class = {
      multi = {},
    },
    ingroup = {
      multi = {},
    },
  },
  actions = {
    init = {},
    start = {},
    finish = {},
  },
  animation = {
    start = {
      type = "none",
      duration_type = "seconds",
    },
    main = {
      type = "none",
      duration_type = "seconds",
    },
    finish = {
      type = "none",
      duration_type = "seconds",
    },
  },
  conditions = {},
}

