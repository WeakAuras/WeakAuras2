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

--- @type table<AuraWarningSeverity, number>
local severityLevel = {
  info = 0,
  sound = 1,
  tts = 2,
  warning = 3,
  error = 4
}

--- @type table<AuraWarningSeverity, string>
local icons = {
  info = [[Interface/friendsframe/informationicon.blp]],
  sound = [[chatframe-button-icon-voicechat]],
  tts = [[chatframe-button-icon-tts]],
  warning = [[services-icon-warning]],
  error = [[Interface/HELPFRAME/HelpIcon-Bug]]
}

--- @type table<AuraWarningSeverity, string>
local titles = {
  info = L["Information"],
  sound = L["Sound"],
  tts = L["Text To Speech"],
  warning = L["Warning"],
  error = L["Error"],
}

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

  --- @type AuraWarningSeverity
  local maxSeverity
  --- @type boolean
  local mixedSeverity = false

  ---@type table<AuraWarningSeverity, string[]>
  local messagePerSeverity = {}

  for key, warning in pairs(warnings[uid]) do
    if not maxSeverity then
      maxSeverity = warning.severity
    elseif severityLevel[warning.severity] > severityLevel[maxSeverity] then
      maxSeverity = warning.severity
    elseif severityLevel[warning.severity] < severityLevel[maxSeverity] then
      mixedSeverity = true
    end
    messagePerSeverity[warning.severity] = messagePerSeverity[warning.severity] or {}
    tinsert(messagePerSeverity[warning.severity], warning.message)
  end

  if not maxSeverity then
    return
  end

  --- @type string
  local result = ""
  result = AddMessages(result, messagePerSeverity["error"], icons["error"], mixedSeverity)
  result = AddMessages(result, messagePerSeverity["warning"], icons["warning"], mixedSeverity)
  result = AddMessages(result, messagePerSeverity["sound"], icons["sound"], mixedSeverity)
  result = AddMessages(result, messagePerSeverity["tts"], icons["tts"], mixedSeverity)
  result = AddMessages(result, messagePerSeverity["info"], icons["info"], mixedSeverity)
  return icons[maxSeverity], titles[maxSeverity], result
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
    results[warning.severity] = {
      icon = icons[warning.severity],
      prio = 5 + severityLevel[warning.severity],
      title = titles[warning.severity] or warning.severity,
      message = warning.message,
      auraId = warning.auraId,
      key = key
    }
  end
  return results
end
