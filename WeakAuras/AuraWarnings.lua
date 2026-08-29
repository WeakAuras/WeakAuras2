if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

--- @alias AuraWarningSeverity
--- | "info"
--- | "sound"
--- | "tts"
--- | "warning"
--- | "error"

---@class WeakAuras
local WeakAuras = WeakAuras
local L = WeakAuras.L

--- @type table<uid, table<string, {severity: AuraWarningSeverity, message: string}>>
local warnings = {}
--- @type table<uid, table<string, boolean>>
local printedWarnings = {}

local function OnDelete(event, uid)
  warnings[uid] = nil
  printedWarnings[uid] = nil
end

Private.callbacks:RegisterCallback("Delete", OnDelete)

--- @class AuraWarnings
--- @field UpdateWarning fun(uid: uid, key: string, severity: AuraWarningSeverity?, message: string?, printOnConsole: boolean?)
--- @field FormatWarnings fun(uid: uid): string?, string?, string?
Private.AuraWarnings = {
  UpdateWarning = function(uid, key, severity, message, printOnConsole)
  end,
  FormatWarnings = function(uid)
  end
}

function Private.AuraWarnings.UpdateWarning(uid, key, severity, message, printOnConsole)
  if not uid then
    WeakAuras.prettyPrint(L["Warning for unknown aura:"], message)
    return
  end
  if printOnConsole then
    printedWarnings[uid] = printedWarnings[uid] or {}
    if printedWarnings[uid][key] == nil then
      WeakAuras.prettyPrint(string.format(L["Aura '%s': %s"], Private.UIDtoID(uid), message))
      printedWarnings[uid][key] = true
    end
  end

  warnings[uid] = warnings[uid] or {}
  if severity and message then
    warnings[uid][key] = {
      severity = severity,
      message = message
    }
    Private.callbacks:Fire("AuraWarningsUpdated", uid)
  else
    if warnings[uid][key] then
      warnings[uid][key] = nil
      if printedWarnings[uid] then
        printedWarnings[uid][key] = nil
      end
      Private.callbacks:Fire("AuraWarningsUpdated", uid)
    end
  end
end

---@class AuraWarningSeverityDescriptor
---@field id AuraWarningSeverity
---@field level number
---@field icon string
---@field title string

--- @type AuraWarningSeverityDescriptor[]
local severityDescriptors = {
  {
    id = "error",
    level = 4,
    icon = [[Interface/HELPFRAME/HelpIcon-Bug]],
    title = L["Error"]
  },
  {
    id = "warning",
    level = 3,
    icon = [[services-icon-warning]],
    title = L["Warning"]
  },
  {
    id = "tts",
    level = 2,
    icon = [[chatframe-button-icon-tts]],
    title = L["Text To Speech"]
  },
  {
    id = "sound",
    level = 1,
    icon = [[chatframe-button-icon-voicechat]],
    title = L["Sound"]
  },
  {
    id = "info",
    level = 0,
    icon = [[Interface/friendsframe/informationicon.blp]],
    title = L["Information"]
  }
}

--- @type table<AuraWarningSeverity, AuraWarningSeverityDescriptor>
local severityById = {}
for _, severity in ipairs(severityDescriptors) do
  severityById[severity.id] = severity
end

---@param result string
---@param messages string[]
---@param icon string
---@param mixedSeverity boolean
---@return string
local function AddMessages(result, messages, icon, mixedSeverity)
  if not messages then
    return result
  end
  for index, message in ipairs(messages) do
    if result ~= "" then
      result = result .. "\n\n"
    end
    if mixedSeverity then
      if C_Texture.GetAtlasInfo(icon) then
        result = result .. "|A:" .. icon .. ":12:12:0:0|a"
      else
        result = result .. "|T" .. icon .. ":12:12:0:0:64:64:4:60:4:60|t"
      end
    end
    result = result .. message
  end
  return result
end

function Private.AuraWarnings.FormatWarnings(uid)
  if not warnings[uid] then
    return
  end

  --- @type AuraWarningSeverityDescriptor
  local maxSeverity
  --- @type AuraWarningSeverity
  local firstSeverity
  --- @type boolean
  local mixedSeverity = false

  ---@type table<AuraWarningSeverity, string[]>
  local messagePerSeverity = {}

  for key, warning in pairs(warnings[uid]) do
    local severity = severityById[warning.severity]
    if not maxSeverity or severity.level > maxSeverity.level then
      maxSeverity = severity
    end
    if firstSeverity and firstSeverity ~= warning.severity then
      mixedSeverity = true
    else
      firstSeverity = warning.severity
    end
    messagePerSeverity[warning.severity] = messagePerSeverity[warning.severity] or {}
    tinsert(messagePerSeverity[warning.severity], warning.message)
  end

  if not maxSeverity then
    return
  end

  --- @type string
  local result = ""
  for _, severity in ipairs(severityDescriptors) do
    result = AddMessages(result, messagePerSeverity[severity.id], severity.icon, mixedSeverity)
  end
  return maxSeverity.icon, maxSeverity.title, result
end

function Private.AuraWarnings.GetAllWarnings(uid)
  local results = {}
  local thisWarnings
  local data = Private.GetDataByUID(uid)
  if data.regionType == "group" or data.regionType == "dynamicgroup" then
    thisWarnings = {}
    for child in Private.TraverseLeafs(data) do
      local childWarnings = warnings[child.uid]
      if childWarnings then
        for key, warning in pairs(childWarnings) do
          if not thisWarnings[key] then
            thisWarnings[key] = {
              severity = warning.severity,
              message = warning.message,
              auraId = child.id
            }
          end
        end
      end
    end
  else
    thisWarnings = CopyTable(warnings[uid])
    local auraId = Private.UIDtoID(uid)
    for key in pairs(thisWarnings) do
      thisWarnings[key].auraId = auraId
    end
  end

  -- Order them by severity, keeping just one per severity
  for key, warning in pairs(thisWarnings) do
    local severity = severityById[warning.severity]
    results[warning.severity] = {
      icon = severity.icon,
      prio = 5 + severity.level,
      title = severity.title,
      message = warning.message,
      auraId = warning.auraId,
      key = key
    }
  end
  return results
end
