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
    { Name = "ids", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "isItemBonusId", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "CheckForItemEquipped",
   Type = "Function",

   Arguments =
   {
    { Name = "itemName", Type = "string", Nilable = false },
    { Name = "specificSlot", Type = "number", Nilable = true },
   },

   Returns =
   {
    { Name = "isItemEquipped", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "CheckNumericIds",
   Type = "Function",

   Arguments =
   {
    { Name = "loadids", Type = "string", Nilable = false },
    { Name = "currentId", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "CheckPvpTalentByIndex",
   Type = "Function",

   Arguments =
   {
    { Name = "index", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "hasTalent", Type = "bool", Nilable = false },
    { Name = "talentId", Type = "number", Nilable = true },
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
    { Name = "index", Type = "number", Nilable = false },
    { Name = "extraOption", Type = "bool", Nilable = true },
   },

   Returns =
   {
    { Name = "hasTalent", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "CheckTalentId",
   Type = "Function",

   Arguments =
   {
    { Name = "talentId", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "hasTalent", Type = "bool", Nilable = false },
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
   Name = "EnsureString",
   Type = "Function",

   Arguments =
   {
    { Name = "input", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
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
    { Name = "name", Type = "string", Nilable = false },
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
    { Name = "undefined", Type = "string", Nilable = false },
    { Name = "undefined", Type = "string", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
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
    { Name = "undefined", Type = "string", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
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
   Name = "GetBonusIdInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "ids", Type = "string", Nilable = false },
    { Name = "specificSlot", Type = "number", Nilable = true },
   },

   Returns =
   {
    { Name = "id", Type = "string", Nilable = true },
    { Name = "itemID", Type = "string", Nilable = true },
    { Name = "itemName", Type = "string", Nilable = true },
    { Name = "icon", Type = "number", Nilable = true },
    { Name = "slot", Type = "number", Nilable = true },
    { Name = "itemSlot", Type = "number", Nilable = true },
   },
  },
  {
   Name = "GetCastLatency",
   Type = "Function",

   Returns =
   {
    { Name = "castLatencyF", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetCritChance",
   Type = "Function",

   Returns =
   {
    { Name = "critChance", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetData",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "string", Nilable = false },
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
    { Name = "result", Type = "number", Nilable = false },
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
    { Name = "essence", Type = "number", Nilable = true },
   },

   Returns =
   {
    { Name = "duration", Type = "number", Nilable = true },
    { Name = "expirationTime", Type = "number", Nilable = true },
    { Name = "remaining", Type = "number", Nilable = true },
    { Name = "paused", Type = "bool", Nilable = true },
    { Name = "power", Type = "number", Nilable = true },
    { Name = "total", Type = "number", Nilable = true },
   },
  },
  {
   Name = "GetGCDInfo",
   Type = "Function",

   Returns =
   {
    { Name = "duration", Type = "number", Nilable = false },
    { Name = "expirationTime", Type = "number", Nilable = false },
    { Name = "name", Type = "string", Nilable = false },
    { Name = "icon", Type = "string", Nilable = false },
    { Name = "modrate", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetHSVTransition",
   Type = "Function",

   Arguments =
   {
    { Name = "perc", Type = "number", Nilable = false },
    { Name = "r1", Type = "number", Nilable = false },
    { Name = "g1", Type = "number", Nilable = false },
    { Name = "b1", Type = "number", Nilable = false },
    { Name = "a1", Type = "number", Nilable = false },
    { Name = "r2", Type = "number", Nilable = false },
    { Name = "g2", Type = "number", Nilable = false },
    { Name = "b2", Type = "number", Nilable = false },
    { Name = "a2", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "r", Type = "number", Nilable = false },
    { Name = "g", Type = "number", Nilable = false },
    { Name = "b", Type = "number", Nilable = false },
    { Name = "a", Type = "number", Nilable = false },
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

   Returns =
   {
    { Name = "hitChance", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetItemCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "string", Nilable = false },
    { Name = "showgcd", Type = "bool", Nilable = false },
   },

   Returns =
   {
    { Name = "startTime", Type = "number", Nilable = false },
    { Name = "duration", Type = "number", Nilable = false },
    { Name = "enabled", Type = "bool", Nilable = false },
    { Name = "gcdCooldown", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetItemSlotCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "string", Nilable = false },
    { Name = "showgcd", Type = "bool", Nilable = false },
   },

   Returns =
   {
    { Name = "startTime", Type = "number", Nilable = false },
    { Name = "duration", Type = "number", Nilable = false },
    { Name = "enabled", Type = "bool", Nilable = false },
    { Name = "gcdCooldown", Type = "number", Nilable = false },
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
    { Name = "undefined", Type = "string", Nilable = false },
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
    { Name = "undefined", Type = "string", Nilable = false },
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
    { Name = "setID", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "quantity", Type = "number", Nilable = true },
    { Name = "maxQuantity", Type = "number", Nilable = true },
    { Name = "setName", Type = "string", Nilable = true },
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
    { Name = "undefined", Type = "string", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetPlayerReaction",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "UnitToken", Nilable = false },
   },

   Returns =
   {
    { Name = "reaction", Type = "string", Nilable = true },
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
    { Name = "spellID", Type = "number", Nilable = true },
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
    { Name = "id", Type = "string", Nilable = false },
    { Name = "cloneId", Type = "string", Nilable = true },
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
    { Name = "id", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "cooldownStart", Type = "number", Nilable = false },
    { Name = "cooldownDuration", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetSpellCharges",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "string", Nilable = false },
    { Name = "ignoreSpellKnown", Type = "bool", Nilable = false },
    { Name = "followoverride", Type = "bool", Nilable = false },
   },

   Returns =
   {
    { Name = "charges", Type = "number", Nilable = true },
    { Name = "chargesMax", Type = "number", Nilable = true },
    { Name = "count", Type = "number", Nilable = true },
    { Name = "chargeGainTime", Type = "number", Nilable = true },
    { Name = "chargeLostTime", Type = "number", Nilable = true },
   },
  },
  {
   Name = "GetSpellCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "string", Nilable = false },
    { Name = "ignoreRuneCD", Type = "bool", Nilable = false },
    { Name = "showgcd", Type = "bool", Nilable = false },
    { Name = "ignoreSpellKnown", Type = "bool", Nilable = false },
    { Name = "track", Type = "bool", Nilable = false },
    { Name = "followOverride", Type = "bool", Nilable = false },
   },

   Returns =
   {
    { Name = "startTime", Type = "number", Nilable = true },
    { Name = "duration", Type = "number", Nilable = true },
    { Name = "gcdCooldown", Type = "number", Nilable = true },
    { Name = "readyTime", Type = "number", Nilable = true },
    { Name = "modRate", Type = "number", Nilable = true },
    { Name = "paused", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "GetSpellCooldownUnified",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "string", Nilable = false },
    { Name = "runeDuration", Type = "number", Nilable = true },
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
    { Name = "powerTypeToCheck", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "cost", Type = "number", Nilable = true },
   },
  },
  {
   Name = "GetSwingTimerInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "hand", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "duration", Type = "number", Nilable = false },
    { Name = "expirationTime", Type = "number", Nilable = false },
    { Name = "weaponName", Type = "string", Nilable = true },
    { Name = "icon", Type = "number", Nilable = true },
   },
  },
  {
   Name = "GetTalentById",
   Type = "Function",

   Arguments =
   {
    { Name = "talentId", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "spellName", Type = "string", Nilable = true },
    { Name = "icon", Type = "number", Nilable = true },
    { Name = "spellId", Type = "number", Nilable = true },
    { Name = "rank", Type = "number", Nilable = true },
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
    { Name = "cloneId", Type = "number", Nilable = false },
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
    { Name = "undefined", Type = "string", Nilable = true },
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
   Name = "InstanceDifficulty",
   Type = "Function",

   Returns =
   {
    { Name = "difficulty", Type = "string", Nilable = false },
   },
  },
  {
   Name = "InstanceType",
   Type = "Function",

   Returns =
   {
    { Name = "instanceType", Type = "string", Nilable = false },
   },
  },
  {
   Name = "InstanceTypeRaw",
   Type = "Function",

   Returns =
   {
    { Name = "difficultyID", Type = "number", Nilable = true },
   },
  },
  {
   Name = "InternalVersion",
   Type = "Function",

   Returns =
   {
    { Name = "version", Type = "number", Nilable = false },
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
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsCataOrRetail",
   Type = "Function",

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsClassicEra",
   Type = "Function",

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsClassicEraOrWrath",
   Type = "Function",

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsClassicEraOrWrathOrCata",
   Type = "Function",

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
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
    { Name = "spell", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsRetail",
   Type = "Function",

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
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
    { Name = "spell", Type = "string", Nilable = false },
    { Name = "pet", Type = "bool", Nilable = true },
   },

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsSpellKnownIncludingPet",
   Type = "Function",

   Arguments =
   {
    { Name = "spell", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsUntrackableSoftTarget",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "UnitToken", Nilable = false },
   },

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsWrathClassic",
   Type = "Function",

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsWrathOrCata",
   Type = "Function",

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsWrathOrCataOrRetail",
   Type = "Function",

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
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
    { Name = "flag", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "index", Type = "number", Nilable = false },
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
    { Name = "txt", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "result", Type = "string", Nilable = false },
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
    { Name = "number", Type = "number", Nilable = true },
   },
  },
  {
   Name = "ScanEvents",
   Type = "Function",

   Arguments =
   {
    { Name = "event", Type = "string", Nilable = false },
    { Name = "arg1", Type = "any", Nilable = false },
    { Name = "arg2", Type = "any", Nilable = false },
    { Name = "undefined", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ScanUnitEvents",
   Type = "Function",

   Arguments =
   {
    { Name = "event", Type = "string", Nilable = false },
    { Name = "unit", Type = "UnitToken", Nilable = false },
    { Name = "undefined", Type = "any", Nilable = false },
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
    { Name = "id", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "overlayGlowActive", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "SpellSchool",
   Type = "Function",

   Arguments =
   {
    { Name = "school", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "school", Type = "string", Nilable = false },
   },
  },
  {
   Name = "StartProfile",
   Type = "Function",

   Arguments =
   {
    { Name = "_", Type = "string", Nilable = false },
   },
  },
  {
   Name = "StopProfile",
   Type = "Function",
  },
  {
   Name = "TimeToSeconds",
   Type = "Function",

   Arguments =
   {
    { Name = "val", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "result", Type = "number", Nilable = true },
   },
  },
  {
   Name = "Toggle",
   Type = "Function",
  },
  {
   Name = "ToggleOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "msg", Type = "string", Nilable = false },
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
    { Name = "unit", Type = "UnitToken", Nilable = false },
    { Name = "smart", Type = "bool", Nilable = true },
   },

   Returns =
   {
    { Name = "unitExists", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "UnitIsPet",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "UnitToken", Nilable = false },
   },

   Returns =
   {
    { Name = "isPet", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "UnitNameWithRealm",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "UnitToken", Nilable = false },
   },

   Returns =
   {
    { Name = "name", Type = "string", Nilable = false },
    { Name = "realm", Type = "string", Nilable = false },
   },
  },
  {
   Name = "UnitPowerDisplayMod",
   Type = "Function",

   Arguments =
   {
    { Name = "powerType", Type = "number", Nilable = false },
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
    { Name = "unit", Type = "UnitToken", Nilable = false },
   },

   Returns =
   {
    { Name = "role", Type = "string", Nilable = true },
   },
  },
  {
   Name = "UnitStagger",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "UnitToken", Nilable = false },
   },

   Returns =
   {
    { Name = "stagger", Type = "number", Nilable = false },
   },
  },
  {
   Name = "UntrackableUnit",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "UnitToken", Nilable = false },
   },

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
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
    { Name = "powerType", Type = "number", Nilable = false },
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
    { Name = "isNumeric", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "ValidateNumericOrPercent",
   Type = "Function",

   Arguments =
   {
    { Name = "info", Type = "any", Nilable = false },
    { Name = "val", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "result", Type = "bool", Nilable = false },
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
    { Name = "isTime", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "WatchForQueuedSpell",
   Type = "Function",
  },
  {
   Name = "WatchUnitChange",
   Type = "Function",

   Arguments =
   {
    { Name = "unit", Type = "UnitToken", Nilable = false },
   },
  },
  {
   Name = "gcdDuration",
   Type = "Function",

   Returns =
   {
    { Name = "duration", Type = "number", Nilable = false },
   },
  },
  {
   Name = "prettyPrint",
   Type = "Function",

   Arguments =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "split",
   Type = "Function",

   Arguments =
   {
    { Name = "input", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "subStrings", Type = "string", Nilable = false },
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

