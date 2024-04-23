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
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
  {
   Name = "CleanUpLines",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "AlignmentLines", Nilable = false },
   },
  },
  {
   Name = "CreateLineInformation",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "AlignmentLines", Nilable = false },
    { Name = "data", Type = "auraData", Nilable = false },
    { Name = "sizerPoint", Type = "AnchorPoint", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "LineInformation", Nilable = false },
    { Name = "undefined", Type = "LineInformation", Nilable = false },
   },
  },
  {
   Name = "CreateLines",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "AlignmentLines", Nilable = false },
    { Name = "data", Type = "auraData", Nilable = false },
    { Name = "sizerPoint", Type = "AnchorPoint?", Nilable = true },
   },
  },
  {
   Name = "CreateMiddleLines",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "AlignmentLines", Nilable = false },
    { Name = "sizerPoint", Type = "AnchorPoint?", Nilable = true },
   },
  },
  {
   Name = "MergeLineInformation",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "AlignmentLines", Nilable = false },
    { Name = "lines", Type = "LineInformation", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "LineInformation", Nilable = false },
   },
  },
  {
   Name = "ShowLinesFor",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "AlignmentLines", Nilable = false },
    { Name = "ctrlKey", Type = "any", Nilable = false },
    { Name = "region", Type = "any", Nilable = false },
    { Name = "sizePoint", Type = "any", Nilable = false },
   },
  },
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
  {
   Name = "GetAllWarnings",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
  {
   Name = "AuraCanFunction",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
    { Name = "data", Type = "auraData", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "Disable",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
    { Name = "id", Type = "string", Nilable = false },
   },
  },
  {
   Name = "Enable",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
    { Name = "id", Type = "string", Nilable = false },
   },
  },
  {
   Name = "Enabled",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
    { Name = "id", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "Exists",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
    { Name = "id", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "Hydrate",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
   },
  },
  {
   Name = "ListFeatures",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "Register",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
    { Name = "feature", Type = "feature", Nilable = false },
   },
  },
  {
   Name = "Subscribe",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
    { Name = "id", Type = "string", Nilable = false },
    { Name = "enable", Type = "function", Nilable = false },
    { Name = "disable", Type = "function", Nilable = false },
   },
  },
  {
   Name = "Wrap",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Features", Nilable = false },
    { Name = "id", Type = "string", Nilable = false },
    { Name = "enabledFunc", Type = "function", Nilable = false },
    { Name = "disabledFunc", Type = "function?", Nilable = true },
   },

   Returns =
   {
    { Name = "undefined", Type = "function", Nilable = false },
   },
  },
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
  {
   Name = "AddDisplayButton",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "AddTextFormatOption",
   Type = "Function",

   Arguments =
   {
    { Name = "input", Type = "any", Nilable = false },
    { Name = "withHeader", Type = "any", Nilable = false },
    { Name = "get", Type = "any", Nilable = false },
    { Name = "addOption", Type = "any", Nilable = false },
    { Name = "hidden", Type = "any", Nilable = false },
    { Name = "setHidden", Type = "any", Nilable = false },
    { Name = "withoutColor", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
    { Name = "total", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "AddTriggerMetaFunctions",
   Type = "Function",

   Arguments =
   {
    { Name = "options", Type = "any", Nilable = false },
    { Name = "data", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
   },
  },
  {
   Name = "AddUpDownDeleteDuplicate",
   Type = "Function",

   Arguments =
   {
    { Name = "options", Type = "any", Nilable = false },
    { Name = "parentData", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
    { Name = "subRegionType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ClearOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ClearPick",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ClearPicks",
   Type = "Function",
  },
  {
   Name = "ClearTriggerExpandState",
   Type = "Function",
  },
  {
   Name = "CodeReview",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "ConfirmDelete",
   Type = "Function",

   Arguments =
   {
    { Name = "toDelete", Type = "any", Nilable = false },
    { Name = "parents", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ConstructOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "prototype", Type = "any", Nilable = false },
    { Name = "data", Type = "any", Nilable = false },
    { Name = "startorder", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
    { Name = "triggertype", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "ConvertDisplay",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "newType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "CreateFrame",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "DebugLog",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "DeleteAuras",
   Type = "Function",

   Arguments =
   {
    { Name = "auras", Type = "any", Nilable = false },
    { Name = "parents", Type = "any", Nilable = false },
   },
  },
  {
   Name = "DeleteSubRegion",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
    { Name = "regionType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "DragReset",
   Type = "Function",
  },
  {
   Name = "Drop",
   Type = "Function",

   Arguments =
   {
    { Name = "mainAura", Type = "any", Nilable = false },
    { Name = "target", Type = "any", Nilable = false },
    { Name = "action", Type = "any", Nilable = false },
    { Name = "area", Type = "any", Nilable = false },
   },
  },
  {
   Name = "DropIndicator",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "DuplicateAura",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "newParent", Type = "any", Nilable = false },
    { Name = "massEdit", Type = "any", Nilable = false },
    { Name = "targetIndex", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "DuplicateCollapseData",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "namespace", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
   },
  },
  {
   Name = "DuplicateSubRegion",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
    { Name = "regionType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "EnsureOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "subOption", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ExportToString",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ExportToTable",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "GetActionOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetAnimationOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetAuthorOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetConditionOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetDisplayButton",
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
   Name = "GetDisplayOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetFlipbookTileSize",
   Type = "Function",

   Arguments =
   {
    { Name = "name", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetGroupOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetInformationOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "auraData", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetLoadOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetPickedDisplay",
   Type = "Function",
  },
  {
   Name = "GetTriggerOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetTriggerTitle",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "HasWagoUrl",
   Type = "Function",

   Arguments =
   {
    { Name = "auraId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IconPicker",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "ImportExport",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "ImportFromString",
   Type = "Function",
  },
  {
   Name = "InsertCollapsed",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "namespace", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
    { Name = "value", Type = "any", Nilable = false },
   },
  },
  {
   Name = "IsCollapsed",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "namespace", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
    { Name = "default", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "IsDisplayPicked",
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
   Name = "IsPickedMultiple",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "IsWagoUpdateIgnored",
   Type = "Function",

   Arguments =
   {
    { Name = "auraId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "LoadDocumentation",
   Type = "Function",
  },
  {
   Name = "ModelPicker",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "MoveCollapseDataDown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "namespace", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
   },
  },
  {
   Name = "MoveCollapseDataUp",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "namespace", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
   },
  },
  {
   Name = "MoveSubRegionDown",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
    { Name = "regionType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "MoveSubRegionUp",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
    { Name = "regionType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "MoverSizer",
   Type = "Function",

   Arguments =
   {
    { Name = "parent", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "MultipleDisplayTooltipDesc",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "MultipleDisplayTooltipMenu",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "OpenCodeReview",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "OpenDebugLog",
   Type = "Function",

   Arguments =
   {
    { Name = "text", Type = "any", Nilable = false },
   },
  },
  {
   Name = "OpenIconPicker",
   Type = "Function",

   Arguments =
   {
    { Name = "baseObject", Type = "any", Nilable = false },
    { Name = "paths", Type = "any", Nilable = false },
    { Name = "groupIcon", Type = "any", Nilable = false },
   },
  },
  {
   Name = "OpenModelPicker",
   Type = "Function",

   Arguments =
   {
    { Name = "baseObject", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
   },
  },
  {
   Name = "OpenTextEditor",
   Type = "Function",

   Arguments =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "OpenTexturePicker",
   Type = "Function",

   Arguments =
   {
    { Name = "baseObject", Type = "any", Nilable = false },
    { Name = "paths", Type = "any", Nilable = false },
    { Name = "properties", Type = "any", Nilable = false },
    { Name = "textures", Type = "any", Nilable = false },
    { Name = "SetTextureFunc", Type = "any", Nilable = false },
    { Name = "adjustSize", Type = "any", Nilable = false },
   },
  },
  {
   Name = "OpenTriggerTemplate",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "targetId", Type = "any", Nilable = false },
   },
  },
  {
   Name = "OpenUpdate",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "children", Type = "any", Nilable = false },
    { Name = "target", Type = "any", Nilable = false },
    { Name = "linkedAuras", Type = "any", Nilable = false },
    { Name = "sender", Type = "any", Nilable = false },
    { Name = "callbackFunc", Type = "any", Nilable = false },
   },
  },
  {
   Name = "PickAndEditDisplay",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "PickDisplayMultiple",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "PickDisplayMultipleShift",
   Type = "Function",

   Arguments =
   {
    { Name = "target", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RemoveCollapsed",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "namespace", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ResetCollapsed",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "namespace", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ResetMoverSizer",
   Type = "Function",
  },
  {
   Name = "SetCollapsed",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "namespace", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
    { Name = "v", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetTitle",
   Type = "Function",

   Arguments =
   {
    { Name = "title", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SortDisplayButtons",
   Type = "Function",

   Arguments =
   {
    { Name = "filter", Type = "any", Nilable = false },
    { Name = "overrideReset", Type = "any", Nilable = false },
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "StartDrag",
   Type = "Function",

   Arguments =
   {
    { Name = "mainAura", Type = "any", Nilable = false },
   },
  },
  {
   Name = "StartFrameChooser",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
   },
  },
  {
   Name = "StartGrouping",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "StopFrameChooser",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "StopGrouping",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "TextEditor",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "TexturePicker",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "Ungroup",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UpdateButtonsScroll",
   Type = "Function",
  },
  {
   Name = "UpdateFrame",
   Type = "Function",

   Arguments =
   {
    { Name = "frame", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "GroupUpdateFrame", Nilable = false },
   },
  },
  {
   Name = "UpdateOptions",
   Type = "Function",
  },
 },
 Functions =
 {
 },
 Functions =
 {
  {
   Name = "ActivateEvent",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
    { Name = "data", Type = "any", Nilable = false },
    { Name = "state", Type = "any", Nilable = false },
    { Name = "errorHandler", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "state", Nilable = false },
   },
  },
  {
   Name = "ActiveTrigger",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "AddMany",
   Type = "Function",

   Arguments =
   {
    { Name = "tbl", Type = "auraData[]", Nilable = false },
    { Name = "takeSnapshots", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "AddParents",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "AddProgressSourceMetaData",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "progressSource", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table|nil", Nilable = true },
   },
  },
  {
   Name = "AnchorFrame",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "region", Type = "any", Nilable = false },
    { Name = "parent", Type = "any", Nilable = false },
    { Name = "force", Type = "any", Nilable = false },
   },
  },
  {
   Name = "Animate",
   Type = "Function",

   Arguments =
   {
    { Name = "namespace", Type = "any", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "type", Type = "any", Nilable = false },
    { Name = "anim", Type = "any", Nilable = false },
    { Name = "region", Type = "any", Nilable = false },
    { Name = "inverse", Type = "any", Nilable = false },
    { Name = "onFinished", Type = "any", Nilable = false },
    { Name = "loop", Type = "any", Nilable = false },
    { Name = "cloneId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "AnyEveryFrameFormatters",
   Type = "Function",

   Arguments =
   {
    { Name = "textStr", Type = "any", Nilable = false },
    { Name = "everyFrameFormatters", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "ApplyFrameLevel",
   Type = "Function",

   Arguments =
   {
    { Name = "region", Type = "any", Nilable = false },
    { Name = "frameLevel", Type = "any", Nilable = false },
   },
  },
  {
   Name = "CanConvertBuffTrigger2",
   Type = "Function",

   Arguments =
   {
    { Name = "trigger", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
    { Name = "undefined", Type = "string", Nilable = true },
   },
  },
  {
   Name = "CancelAllDelayedTriggers",
   Type = "Function",
  },
  {
   Name = "CancelAnimation",
   Type = "Function",

   Arguments =
   {
    { Name = "region", Type = "any", Nilable = false },
    { Name = "resetPos", Type = "any", Nilable = false },
    { Name = "resetAlpha", Type = "any", Nilable = false },
    { Name = "resetScale", Type = "any", Nilable = false },
    { Name = "resetRotation", Type = "any", Nilable = false },
    { Name = "resetColor", Type = "any", Nilable = false },
    { Name = "doOnFinished", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "CancelDelayedTrigger",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "CheckCooldownReady",
   Type = "Function",
  },
  {
   Name = "CheckItemCooldowns",
   Type = "Function",
  },
  {
   Name = "CheckItemSlotCooldowns",
   Type = "Function",
  },
  {
   Name = "CheckRuneCooldown",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "CheckSpellCooldown",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "runeDuration", Type = "any", Nilable = false },
   },
  },
  {
   Name = "CheckSpellCooldows",
   Type = "Function",

   Arguments =
   {
    { Name = "runeDuration", Type = "any", Nilable = false },
   },
  },
  {
   Name = "CheckSpellKnown",
   Type = "Function",
  },
  {
   Name = "CleanArchive",
   Type = "Function",

   Arguments =
   {
    { Name = "historyCutoff", Type = "any", Nilable = false },
    { Name = "migrationCutoff", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ClearAuraEnvironment",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ClearAuraEnvironmentSavedData",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ClearFakeStates",
   Type = "Function",
  },
  {
   Name = "CollapseAllClones",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
   },
  },
  {
   Name = "Convert",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "newType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ConvertBuffTrigger2",
   Type = "Function",

   Arguments =
   {
    { Name = "trigger", Type = "any", Nilable = false },
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
   Name = "CreateFormatters",
   Type = "Function",

   Arguments =
   {
    { Name = "input", Type = "any", Nilable = false },
    { Name = "getter", Type = "any", Nilable = false },
    { Name = "withoutColor", Type = "any", Nilable = false },
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "CreatingRegions",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "DataToString",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "DeleteAuraEnvironment",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "DisplayToString",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "forChat", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "EnforceSubregionExists",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "subregionType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "EveryFrameUpdateRename",
   Type = "Function",

   Arguments =
   {
    { Name = "oldid", Type = "any", Nilable = false },
    { Name = "newid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ExpandCurrencyList",
   Type = "Function",

   Arguments =
   {
    { Name = "index", Type = "number", Nilable = false },
    { Name = "expand", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "ExpandCustomVariables",
   Type = "Function",

   Arguments =
   {
    { Name = "variables", Type = "table", Nilable = false },
   },
  },
  {
   Name = "FakeStatesFor",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "visible", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "FinishLoadUnload",
   Type = "Function",
  },
  {
   Name = "GetAdditionalProperties",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "GetAnchorsForData",
   Type = "Function",

   Arguments =
   {
    { Name = "parentData", Type = "any", Nilable = false },
    { Name = "type", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table|unknown|nil", Nilable = true },
   },
  },
  {
   Name = "GetCurrencyIDFromLink",
   Type = "Function",

   Arguments =
   {
    { Name = "currencyLink", Type = "string", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetCurrencyInfoForTrigger",
   Type = "Function",

   Arguments =
   {
    { Name = "trigger", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "CurrencyInfo|nil", Nilable = true },
   },
  },
  {
   Name = "GetCurrencyListInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "index", Type = "number", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetDiscoveredCurrencies",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "GetDiscoveredCurrenciesHeaders",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "GetDiscoveredCurrenciesSorted",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetGlobalConditionState",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetGlobalConditions",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetMigrationSnapshot",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "GetOverlayInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "GetProgressSourceFor",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "trigger", Type = "any", Nilable = false },
    { Name = "property", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table|nil", Nilable = true },
   },
  },
  {
   Name = "GetProgressSources",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetProgressSourcesForUi",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "subelement", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetProgressValueConstant",
   Type = "Function",

   Arguments =
   {
    { Name = "v", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetProperties",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetReputations",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "GetReputationsHeaders",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "GetReputationsSorted",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetSanitizedGlobal",
   Type = "Function",

   Arguments =
   {
    { Name = "key", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetSetId",
   Type = "Function",

   Arguments =
   {
    { Name = "itemId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "GetSubRegionProperties",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "properties", Type = "any", Nilable = false },
   },
  },
  {
   Name = "GetTalentData",
   Type = "Function",

   Arguments =
   {
    { Name = "specId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table|nil", Nilable = true },
   },
  },
  {
   Name = "GetTalentInfo",
   Type = "Function",

   Arguments =
   {
    { Name = "specId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetTriggerConditions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "GetTsuConditionVariablesExpanded",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "HandleChatAction",
   Type = "Function",

   Arguments =
   {
    { Name = "message_type", Type = "any", Nilable = false },
    { Name = "message", Type = "any", Nilable = false },
    { Name = "message_dest", Type = "any", Nilable = false },
    { Name = "message_dest_isunit", Type = "any", Nilable = false },
    { Name = "message_channel", Type = "any", Nilable = false },
    { Name = "r", Type = "any", Nilable = false },
    { Name = "g", Type = "any", Nilable = false },
    { Name = "b", Type = "any", Nilable = false },
    { Name = "region", Type = "any", Nilable = false },
    { Name = "customFunc", Type = "any", Nilable = false },
    { Name = "when", Type = "any", Nilable = false },
    { Name = "formatters", Type = "any", Nilable = false },
    { Name = "voice", Type = "any", Nilable = false },
   },
  },
  {
   Name = "HandleGlowAction",
   Type = "Function",

   Arguments =
   {
    { Name = "actions", Type = "any", Nilable = false },
    { Name = "region", Type = "any", Nilable = false },
   },
  },
  {
   Name = "HideTooltip",
   Type = "Function",
  },
  {
   Name = "IconSources",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "InitCooldownReady",
   Type = "Function",
  },
  {
   Name = "InitializeEncounterAndZoneLists",
   Type = "Function",
  },
  {
   Name = "InitializeEncounterAndZoneLists",
   Type = "Function",
  },
  {
   Name = "InitializeEncounterAndZoneLists",
   Type = "Function",
  },
  {
   Name = "InitializeEncounterAndZoneLists",
   Type = "Function",
  },
  {
   Name = "IsAuraActive",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "IsEnvironmentInitialized",
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
   Name = "IsOptionsProcessingPaused",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "LoadConditionFunction",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "LoadConditionPropertyFunctions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "LoadDisplays",
   Type = "Function",

   Arguments =
   {
    { Name = "toLoad", Type = "any", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "Login",
   Type = "Function",

   Arguments =
   {
    { Name = "initialTime", Type = "any", Nilable = false },
    { Name = "takeNewSnapshots", Type = "any", Nilable = false },
   },
  },
  {
   Name = "LoginMessage",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "ModelSetTransformFixed",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "Private", Nilable = false },
    { Name = "tx", Type = "any", Nilable = false },
    { Name = "ty", Type = "any", Nilable = false },
    { Name = "tz", Type = "any", Nilable = false },
    { Name = "rx", Type = "any", Nilable = false },
    { Name = "ry", Type = "any", Nilable = false },
    { Name = "rz", Type = "any", Nilable = false },
    { Name = "s", Type = "any", Nilable = false },
   },
  },
  {
   Name = "Modernize",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "auraData", Nilable = false },
   },
  },
  {
   Name = "NeedToRepairDatabase",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "ParseTextStr",
   Type = "Function",

   Arguments =
   {
    { Name = "textStr", Type = "any", Nilable = false },
    { Name = "symbolCallback", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ParseTooltipText",
   Type = "Function",

   Arguments =
   {
    { Name = "tooltipText", Type = "any", Nilable = false },
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
   Name = "Pause",
   Type = "Function",
  },
  {
   Name = "PauseAllDynamicGroups",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "PerformActions",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "when", Type = "any", Nilable = false },
    { Name = "region", Type = "any", Nilable = false },
   },
  },
  {
   Name = "PostAddCompanion",
   Type = "Function",
  },
  {
   Name = "ProfileRenameAura",
   Type = "Function",

   Arguments =
   {
    { Name = "oldid", Type = "any", Nilable = false },
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RegisterEveryFrameUpdate",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RegisterForGlobalConditions",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RegisterGroupForPositioning",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "region", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RegisterLoadEvents",
   Type = "Function",
  },
  {
   Name = "RegisterRegionOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "_", Type = "string", Nilable = false },
    { Name = "_", Type = "function", Nilable = false },
    { Name = "_", Type = "string", Nilable = false },
    { Name = "_", Type = "string", Nilable = false },
   },
  },
  {
   Name = "RegisterRegionOptions",
   Type = "Function",

   Arguments =
   {
    { Name = "name", Type = "any", Nilable = false },
    { Name = "createFunction", Type = "any", Nilable = false },
    { Name = "icon", Type = "any", Nilable = false },
    { Name = "displayName", Type = "any", Nilable = false },
    { Name = "createThumbnail", Type = "any", Nilable = false },
    { Name = "modifyThumbnail", Type = "any", Nilable = false },
    { Name = "description", Type = "any", Nilable = false },
    { Name = "templates", Type = "any", Nilable = false },
    { Name = "getAnchors", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ReleaseClone",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "cloneId", Type = "any", Nilable = false },
    { Name = "regionType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RemoveHistory",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RenameAuraEnvironment",
   Type = "Function",

   Arguments =
   {
    { Name = "oldid", Type = "any", Nilable = false },
    { Name = "newid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ReplaceLocalizedRaidMarkers",
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
   Name = "ReplacePlaceHolders",
   Type = "Function",

   Arguments =
   {
    { Name = "textStr", Type = "any", Nilable = false },
    { Name = "region", Type = "any", Nilable = false },
    { Name = "customFunc", Type = "any", Nilable = false },
    { Name = "useHiddenStates", Type = "any", Nilable = false },
    { Name = "formatters", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = true },
   },
  },
  {
   Name = "RestoreAuraEnvironment",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RestoreFromHistory",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "Resume",
   Type = "Function",
  },
  {
   Name = "ResumeAllDynamicGroups",
   Type = "Function",

   Arguments =
   {
    { Name = "suspended", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RunConditions",
   Type = "Function",

   Arguments =
   {
    { Name = "region", Type = "any", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "hideRegion", Type = "any", Nilable = false },
   },
  },
  {
   Name = "RunTriggerFuncWithDelay",
   Type = "Function",

   Arguments =
   {
    { Name = "delay", Type = "any", Nilable = false },
    { Name = "id", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
    { Name = "data", Type = "any", Nilable = false },
    { Name = "event", Type = "any", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "SaveAuraEnvironment",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ScanEventsWatchedTrigger",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "watchedTriggernums", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ScanForLoads",
   Type = "Function",

   Arguments =
   {
    { Name = "toCheck", Type = "any", Nilable = false },
    { Name = "event", Type = "any", Nilable = false },
    { Name = "arg1", Type = "any", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "ScanForLoadsGroup",
   Type = "Function",

   Arguments =
   {
    { Name = "toCheck", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SendDelayedWatchedTriggers",
   Type = "Function",
  },
  {
   Name = "SerializeTable",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "SetAllStatesHidden",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "SetAllStatesHiddenExcept",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
    { Name = "triggernum", Type = "any", Nilable = false },
    { Name = "list", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetFakeStates",
   Type = "Function",
  },
  {
   Name = "SetHistory",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "data", Type = "any", Nilable = false },
    { Name = "source", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "SetImporting",
   Type = "Function",

   Arguments =
   {
    { Name = "b", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetMigrationSnapshot",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "oldData", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetRegion",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "cloneId", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "SetTextureOrAtlas",
   Type = "Function",

   Arguments =
   {
    { Name = "texture", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
    { Name = "wrapModeH", Type = "any", Nilable = false },
    { Name = "wrapModeV", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ShowMouseoverTooltip",
   Type = "Function",

   Arguments =
   {
    { Name = "region", Type = "any", Nilable = false },
    { Name = "owner", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SortOrderForValues",
   Type = "Function",

   Arguments =
   {
    { Name = "values", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "SquelchingActions",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "StartProfileUID",
   Type = "Function",
  },
  {
   Name = "StopProfileUID",
   Type = "Function",
  },
  {
   Name = "SyncParentChildRelationships",
   Type = "Function",

   Arguments =
   {
    { Name = "silent", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UnloadAllConditions",
   Type = "Function",
  },
  {
   Name = "UnloadConditions",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UnloadDisplays",
   Type = "Function",

   Arguments =
   {
    { Name = "toUnload", Type = "any", Nilable = false },
    { Name = "undefined", Type = "unknown", Nilable = false },
   },
  },
  {
   Name = "UnregisterAllEveryFrameUpdate",
   Type = "Function",
  },
  {
   Name = "UnregisterEveryFrameUpdate",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UnregisterForGlobalConditions",
   Type = "Function",

   Arguments =
   {
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UpdateCurrentInstanceType",
   Type = "Function",

   Arguments =
   {
    { Name = "instanceType", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UpdateFakeStatesFor",
   Type = "Function",

   Arguments =
   {
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UpdateSoundIcon",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ValidateUniqueDataIds",
   Type = "Function",

   Arguments =
   {
    { Name = "silent", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ValueFromPath",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "ValueToPath",
   Type = "Function",

   Arguments =
   {
    { Name = "data", Type = "any", Nilable = false },
    { Name = "path", Type = "any", Nilable = false },
    { Name = "value", Type = "any", Nilable = false },
   },
  },
  {
   Name = "checkForSingleLoadCondition",
   Type = "Function",

   Arguments =
   {
    { Name = "trigger", Type = "table", Nilable = false },
    { Name = "name", Type = "string", Nilable = false },
    { Name = "validateFn", Type = "bool", Nilable = true },
   },

   Returns =
   {
    { Name = "undefined", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ensurePRDFrame",
   Type = "Function",
  },
  {
   Name = "getDefaultGlow",
   Type = "Function",

   Arguments =
   {
    { Name = "regionType", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table", Nilable = false },
   },
  },
  {
   Name = "get_encounters_list",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "get_encounters_list",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "get_encounters_list",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "get_encounters_list",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "get_zoneId_list",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "get_zoneId_list",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "get_zoneId_list",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "get_zoneId_list",
   Type = "Function",

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "pauseOptionsProcessing",
   Type = "Function",

   Arguments =
   {
    { Name = "enable", Type = "any", Nilable = false },
   },
  },
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
  {
   Name = "ChangeId",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "id", Type = "any", Nilable = false },
   },
  },
  {
   Name = "ChangeUID",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "newUid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "Contains",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "Dump",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "EnsureUniqueIdOfUnmatched",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "IncProgress", Type = "any", Nilable = false },
   },
  },
  {
   Name = "GetChildren",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "GetDiff",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "categories", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "table|nil", Nilable = true },
   },
  },
  {
   Name = "GetGroupOrder",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = true },
    { Name = "undefined", Type = "number", Nilable = true },
   },
  },
  {
   Name = "GetGroupRegionType",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = ""aurabar"|"dynamicgroup"|"fallback"|"group"|"icon"...(+6)", Nilable = false },
   },
  },
  {
   Name = "GetIdFor",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = true },
   },
  },
  {
   Name = "GetOriginalName",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = true },
   },
  },
  {
   Name = "GetParent",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = true },
   },
  },
  {
   Name = "GetParentIsDynamicGroup",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = true },
   },
  },
  {
   Name = "GetPhase1Data",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "withAppliedPath", Type = "any", Nilable = false },
    { Name = "activeCategories", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "GetPhase2Data",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "withAppliedPath", Type = "any", Nilable = false },
    { Name = "activeCategories", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "unknown", Nilable = true },
   },
  },
  {
   Name = "GetRawChildren",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "GetRawData",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "auraData|nil", Nilable = true },
   },
  },
  {
   Name = "GetRootUID",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = false },
   },
  },
  {
   Name = "GetSortHybrid",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "GetTotalCount",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "number", Nilable = false },
   },
  },
  {
   Name = "GetType",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = ""new"|"old"", Nilable = false },
   },
  },
  {
   Name = "GetUIDMatch",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "string", Nilable = true },
   },
  },
  {
   Name = "InsertData",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "data", Type = "any", Nilable = false },
    { Name = "parentUid", Type = "any", Nilable = false },
    { Name = "children", Type = "any", Nilable = false },
    { Name = "sortHybrid", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
   },
  },
  {
   Name = "InsertUnmatchedFrom",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "otherUidMap", Type = "any", Nilable = false },
    { Name = "IncProgress", Type = "any", Nilable = false },
   },
  },
  {
   Name = "InsertUnmatchedPhase1",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "otherUidMap", Type = "any", Nilable = false },
    { Name = "otherUid", Type = "any", Nilable = false },
    { Name = "IncProgress", Type = "any", Nilable = false },
   },

   Returns =
   {
    { Name = "undefined", Type = "bool", Nilable = false },
   },
  },
  {
   Name = "Remove",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetDiff",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "diff", Type = "any", Nilable = false },
    { Name = "categories", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetGroupOrder",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "index", Type = "any", Nilable = false },
    { Name = "total", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetParentIsDynamicGroup",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "parentIsDynamicGroup", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetRootParent",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "parentId", Type = "any", Nilable = false },
   },
  },
  {
   Name = "SetUIDMatch",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
    { Name = "matchedUid", Type = "any", Nilable = false },
   },
  },
  {
   Name = "UnsetParent",
   Type = "Function",

   Arguments =
   {
    { Name = "self", Type = "UidMap", Nilable = false },
    { Name = "uid", Type = "any", Nilable = false },
   },
  },
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
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
   Name = "StartProfile",
   Type = "Function",

   Arguments =
   {
    { Name = "startType", Type = "any", Nilable = false },
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
   Name = "ToggleMinimap",
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
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
 },
 Functions =
 {
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

