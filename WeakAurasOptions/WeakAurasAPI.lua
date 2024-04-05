if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local WeakAurasAPI =
{
 Name = "WeakAuras",
 Type = "System",
 Namespace = "WeakAuras",
 Functions =
 {
  {
   Name = "Add",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "simpleChange", Type = "any", Nilable = false },
   },
  },
  {
   Name = "AddCompanionData",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "CalculatedGcdDuration",
   Type = "Function",
  },
  {
   Name = "CalculatedGcdDuration",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "CalculatedGcdDuration",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "CalculatedGcdDuration",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "CheckForItemBonusId",
   Type = "Function",

   Arguments =
   {
    { Name = "ids", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "CheckForItemEquipped",
   Type = "Function",

   Arguments =
   {
    { Name = "itemName", Type = "any", Nilable = false },
    { Name = "specificSlot", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "CheckNumericIds",
   Type = "Function",

   Arguments =
   {
    { Name = "loadids", Type = "any", Nilable = false },
    { Name = "currentId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "CheckPvpTalentByIndex",
   Type = "Function",

   Arguments =
   {
    { Name = "index", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "CheckRange",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
    { Name = "range", Type = "any", Nilable = false },
    { Name = "operator", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "CheckTalentByIndex",
   Type = "Function",

   Arguments =
   {
    { Name = "index", Type = "any", Nilable = false },
    { Name = "extraOption", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "CheckTalentId",
   Type = "Function",

   Arguments =
   {
    { Name = "talentId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "ClearAndUpdateOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "clearChildren", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ComposeSorts",
   Type = "Function",

   Arguments =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "function", Nilable = false },
   },
  },
  {
   Name = "CountWagoUpdates",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "CreateTemplateView",
   Type = "Function",

   Arguments =
   {
    { Name = "Private", Type = "any", Nilable = false },
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "DeepMixin",
   Type = "Function",

   Arguments =
   {
    { Name = "dest", Type = "any", Nilable = false },
    { Name = "source", Type = "any", Nilable = false },
   },
  },
  {
   Name = "Delete",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "EnsureString",
   Type = "Function",

   Arguments =
   {
    { Name = "input", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "cstring", Nilable = false },
   },
  },
  {
   Name = "FillOptions",
   Type = "Function",
  },
  {
   Name = "GcdSpellName",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetActiveConditions",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "cloneId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetActiveStates",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetActiveTriggers",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetAuraInstanceTooltipInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
    { Name = "auraInstanceId", Type = "any", Nilable = false },
    { Name = "filter", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetAuraTooltipInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
    { Name = "filter", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetBonusIdInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "ids", Type = "any", Nilable = false },
    { Name = "specificSlot", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "cstring", Nilable = false },
   },
  },
  {
   Name = "GetCastLatency",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetCritChance",
   Type = "Function",
  },
  {
   Name = "GetData",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "cstring", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetEffectiveAttackPower",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetEquipmentSetInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "itemSetName", Type = "any", Nilable = false },
    { Name = "partial", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetEssenceCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "essence", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetGCDInfo",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetHSVTransition",
   Type = "Function",

   Arguments =
   {
    { Name = "perc", Type = "any", Nilable = false },
    { Name = "r1", Type = "any", Nilable = false },
    { Name = "g1", Type = "any", Nilable = false },
    { Name = "b1", Type = "any", Nilable = false },
    { Name = "a1", Type = "any", Nilable = false },
    { Name = "r2", Type = "any", Nilable = false },
    { Name = "g2", Type = "any", Nilable = false },
    { Name = "b2", Type = "any", Nilable = false },
    { Name = "a2", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetHiddenTooltip",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetHitChance",
   Type = "Function",
  },
  {
   Name = "GetItemCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "showgcd", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "GetItemSlotCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "showgcd", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "GetLegendaryData",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "GetMHTenchInfo",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetMoverSizerId",
   Type = "Function",
  },
  {
   Name = "GetNumSetItemsEquipped",
   Type = "Function",

   Arguments =
   {
    { Name = "setID", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = true },
    { Name = "undefined", Type = "number", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "GetOHTenchInfo",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetPlayerReaction",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "cstring", Nilable = false },
   },
  },
  {
   Name = "GetPolarCoordinates",
   Type = "Function",

   Arguments =
   {
    { Name = "x", Type = "any", Nilable = false },
    { Name = "y", Type = "any", Nilable = false },
    { Name = "originX", Type = "any", Nilable = false },
    { Name = "originY", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetQueuedSpell",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetRange",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
    { Name = "checkVisible", Type = "any", Nilable = false },
   },
  },
  {
   Name = "GetRegion",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "cstring", Nilable = false },
    { Name = "cloneId", Type = "cstring", Nilable = true },
   },

   Returns =
   {
    { Name = "undefined", Type = "table|nil", Nilable = true },
   },
  },
  {
   Name = "GetRuneCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetSpellCharges",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "ignoreSpellKnown", Type = "any", Nilable = false },
    { Name = "followoverride", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "GetSpellCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "ignoreRuneCD", Type = "any", Nilable = false },
    { Name = "showgcd", Type = "any", Nilable = false },
    { Name = "ignoreSpellKnown", Type = "any", Nilable = false },
    { Name = "track", Type = "any", Nilable = false },
    { Name = "followOverride", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = true },
    { Name = "undefined", Type = "number", Nilable = true },
    { Name = "undefined", Type = "bool", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "number", Nilable = true },
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "GetSpellCooldownUnified",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "runeDuration", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "bool", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "bool", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "GetSpellCost",
   Type = "Function",

   Arguments =
   {
    { Name = "powerTypeToCheck", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetSwingTimerInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "hand", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "GetTalentById",
   Type = "Function",

   Arguments =
   {
    { Name = "talentId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetTriggerCategoryFor",
   Type = "Function",

   Arguments =
   {
    { Name = "triggerType", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetTriggerStateForTrigger",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table|unknown", Nilable = false },
   },
  },
  {
   Name = "GetUniqueCloneId",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetUnitNameplate",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },
  },
  {
   Name = "HideOptions",
   Type = "Function",
  },
  {
   Name = "Import",
   Type = "Function",

   Arguments =
   {
    { Name = "inData", Type = "any", Nilable = false },
    { Name = "target", Type = "any", Nilable = false },
    { Name = "callbackFunc", Type = "any", Nilable = false },
    { Name = "linkedAuras", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
    { Name = "undefined", Type = "cstring", Nilable = true },
   },
  },
  {
   Name = "InLoadingScreen",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "InitEssenceCooldown",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "InitSwingTimer",
   Type = "Function",
  },
  {
   Name = "InstanceDifficulty",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "InstanceType",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "nil", Nilable = true },
   },
  },
  {
   Name = "InstanceTypeRaw",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "InternalVersion",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "InvertSort",
   Type = "Function",

   Arguments =
   {
    { Name = "sortFunc", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "function", Nilable = false },
   },
  },
  {
   Name = "IsAuraActive",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "IsAuraLoaded",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsCataClassic",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsCataOrRetail",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsClassicEra",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsClassicEraOrWrath",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsClassicEraOrWrathOrCata",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsImporting",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsLibsOK",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsLoginFinished",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsOptionsOpen",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsOptionsOpen",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsPaused",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsPlayerSpellOrOverridesAndBaseIsPlayerSpell",
   Type = "Function",

   Arguments =
   {
    { Name = "spell", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsRetail",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsSpellInRange",
   Type = "Function",

   Arguments =
   {
    { Name = "spellId", Type = "any", Nilable = false },
    { Name = "unit", Type = "any", Nilable = false },
   },
  },
  {
   Name = "IsSpellKnown",
   Type = "Function",

   Arguments =
   {
    { Name = "spell", Type = "any", Nilable = false },
    { Name = "pet", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsSpellKnownForLoad",
   Type = "Function",

   Arguments =
   {
    { Name = "spell", Type = "any", Nilable = false },
    { Name = "exact", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsSpellKnownIncludingPet",
   Type = "Function",

   Arguments =
   {
    { Name = "spell", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsUntrackableSoftTarget",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "IsWrathClassic",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsWrathOrCata",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsWrathOrCataOrRetail",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "LoadFromArchive",
   Type = "Function",

   Arguments =
   {
    { Name = "storeType", Type = "any", Nilable = false },
    { Name = "storeID", Type = "any", Nilable = false },
   },
  },
  {
   Name = "LoadFunction",
   Type = "Function",

   Arguments =
   {
    { Name = "string", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "NewAura",
   Type = "Function",

   Arguments =
   {
    { Name = "sourceData", Type = "any", Nilable = false },
    { Name = "regionType", Type = "any", Nilable = false },
    { Name = "targetId", Type = "any", Nilable = false },
   },
  },
  {
   Name = "NewDisplayButton",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "massEdit", Type = "any", Nilable = false },
   },
  },
  {
   Name = "OpenOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "msg", Type = "any", Nilable = false },
   },
  },
  {
   Name = "PickDisplay",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "tab", Type = "any", Nilable = false },
    { Name = "noHide", Type = "any", Nilable = false },
   },
  },
  {
   Name = "PreAdd",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "PrintProfile",
   Type = "Function",
  },
  {
   Name = "PrintProfile",
   Type = "Function",
  },
  {
   Name = "ProfileDisplays",
   Type = "Function",

   Arguments =
   {
    { Name = "all", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ProfileFrames",
   Type = "Function",

   Arguments =
   {
    { Name = "all", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RaidFlagToIndex",
   Type = "Function",

   Arguments =
   {
    { Name = "flag", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "RegisterItemCountWatch",
   Type = "Function",
  },
  {
   Name = "RegisterSubRegionOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "name", Type = "any", Nilable = false },
    { Name = "createFunction", Type = "any", Nilable = false },
    { Name = "description", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RegisterSubRegionType",
   Type = "Function",

   Arguments =
   {
    { Name = "name", Type = "any", Nilable = false },
    { Name = "displayName", Type = "any", Nilable = false },
    { Name = "supportFunction", Type = "any", Nilable = false },
    { Name = "createFunction", Type = "any", Nilable = false },
    { Name = "modifyFunction", Type = "any", Nilable = false },
    { Name = "onAcquire", Type = "any", Nilable = false },
    { Name = "onRelease", Type = "any", Nilable = false },
    { Name = "default", Type = "any", Nilable = false },
    { Name = "addDefaultsForNewAura", Type = "any", Nilable = false },
    { Name = "properties", Type = "any", Nilable = false },
    { Name = "supportsAdd", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RegisterTriggerSystem",
   Type = "Function",

   Arguments =
   {
    { Name = "types", Type = "any", Nilable = false },
    { Name = "triggerSystem", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RegisterTriggerSystemOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "types", Type = "any", Nilable = false },
    { Name = "func", Type = "any", Nilable = false },
   },
  },
  {
   Name = "Rename",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "newid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ReplaceRaidMarkerSymbols",
   Type = "Function",

   Arguments =
   {
    { Name = "txt", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "SafeToNumber",
   Type = "Function",

   Arguments =
   {
    { Name = "input", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = true },
   },
  },
  {
   Name = "ScanEvents",
   Type = "Function",

   Arguments =
   {
    { Name = "event", Type = "any", Nilable = false },
    { Name = "arg1", Type = "any", Nilable = false },
    { Name = "arg2", Type = "any", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "ScanEventsInternal",
   Type = "Function",

   Arguments =
   {
    { Name = "event_list", Type = "any", Nilable = false },
    { Name = "event", Type = "any", Nilable = false },
    { Name = "arg1", Type = "any", Nilable = false },
    { Name = "arg2", Type = "any", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "ScanUnitEvents",
   Type = "Function",

   Arguments =
   {
    { Name = "event", Type = "any", Nilable = false },
    { Name = "unit", Type = "any", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "SetModel",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
    { Name = "model_path", Type = "any", Nilable = false },
    { Name = "model_fileId", Type = "any", Nilable = false },
    { Name = "isUnit", Type = "any", Nilable = false },
    { Name = "isDisplayInfo", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetMoverSizer",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ShowOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "msg", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SortAscending",
   Type = "Function",

   Arguments =
   {
    { Name = "path", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "function", Nilable = false },
   },
  },
  {
   Name = "SortDescending",
   Type = "Function",

   Arguments =
   {
    { Name = "path", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "function", Nilable = false },
   },
  },
  {
   Name = "SortGreaterLast",
   Type = "Function",

   Arguments =
   {
    { Name = "a", Type = "any", Nilable = false },
    { Name = "b", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "SortNilFirst",
   Type = "Function",

   Arguments =
   {
    { Name = "a", Type = "any", Nilable = false },
    { Name = "b", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "SortNilLast",
   Type = "Function",

   Arguments =
   {
    { Name = "a", Type = "any", Nilable = false },
    { Name = "b", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "SortRegionData",
   Type = "Function",

   Arguments =
   {
    { Name = "path", Type = "any", Nilable = false },
    { Name = "sortFunc", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "function", Nilable = false },
   },
  },
  {
   Name = "SpellActivationActive",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "SpellSchool",
   Type = "Function",

   Arguments =
   {
    { Name = "school", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "cstring", Nilable = false },
   },
  },
  {
   Name = "StartProfile",
   Type = "Function",

   Arguments =
   {
    { Name = "_", Type = "cstring", Nilable = false },
   },
  },
  {
   Name = "StartProfile",
   Type = "Function",

   Arguments =
   {
    { Name = "startType", Type = "cstring", Nilable = false },
   },
  },
  {
   Name = "StopProfile",
   Type = "Function",
  },
  {
   Name = "StopProfile",
   Type = "Function",
  },
  {
   Name = "TenchInit",
   Type = "Function",
  },
  {
   Name = "TimeToSeconds",
   Type = "Function",

   Arguments =
   {
    { Name = "val", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "Toggle",
   Type = "Function",
  },
  {
   Name = "ToggleMinimap",
   Type = "Function",
  },
  {
   Name = "ToggleOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "msg", Type = "cstring", Nilable = false },
    { Name = "Private", Type = "Private", Nilable = false },
   },
  },
  {
   Name = "ToggleProfile",
   Type = "Function",
  },
  {
   Name = "UnitChannelInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "UnitDetailedThreatSituation",
   Type = "Function",

   Arguments =
   {
    { Name = "unit1", Type = "any", Nilable = false },
    { Name = "unit2", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "UnitExistsFixed",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
    { Name = "smart", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "UnitIsPet",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "UnitNameWithRealm",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "cstring", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "UnitPowerDisplayMod",
   Type = "Function",

   Arguments =
   {
    { Name = "powerType", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "UnitRaidRole",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "UnitStagger",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "UntrackableUnit",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "UpdateGroupOrders",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UpdateThumbnail",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UseUnitPowerThirdArg",
   Type = "Function",

   Arguments =
   {
    { Name = "powerType", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "ValidateNumeric",
   Type = "Function",

   Arguments =
   {
    { Name = "info", Type = "any", Nilable = false },
    { Name = "val", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "ValidateNumericOrPercent",
   Type = "Function",

   Arguments =
   {
    { Name = "info", Type = "any", Nilable = false },
    { Name = "val", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "ValidateTime",
   Type = "Function",

   Arguments =
   {
    { Name = "info", Type = "any", Nilable = false },
    { Name = "val", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "WatchForCastLatency",
   Type = "Function",
  },
  {
   Name = "WatchForNameplateTargetChange",
   Type = "Function",
  },
  {
   Name = "WatchForPetDeath",
   Type = "Function",
  },
  {
   Name = "WatchForPlayerMoving",
   Type = "Function",
  },
  {
   Name = "WatchForQueuedSpell",
   Type = "Function",
  },
  {
   Name = "WatchGCD",
   Type = "Function",
  },
  {
   Name = "WatchItemCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "WatchItemSlotCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "WatchRuneCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "WatchSpellActivation",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "WatchSpellCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "ignoreRunes", Type = "any", Nilable = false },
    { Name = "followoverride", Type = "any", Nilable = false },
   },
  },
  {
   Name = "WatchUnitChange",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "any", Nilable = false },
   },
  },
  {
   Name = "gcdDuration",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "prettyPrint",
   Type = "Function",

   Arguments =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "split",
   Type = "Function",

   Arguments =
   {
    { Name = "input", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
 },

 Events =
 {
 },

 Tables =
 {
 },
};
local loaded = false
function OptionsPrivate.LoadDocumentation()
  if not loaded then
    APIDocumentation:AddDocumentationTable(WeakAurasAPI);
    loaded = true
  end
end

