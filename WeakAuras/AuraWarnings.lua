if not WeakAuras.IsCorrectVersion() then return end
local AddonName, Private = ...

local WeakAuras = WeakAuras
local L = WeakAuras.L

-- keyed on uid, key, { severity, message }
local warnings = {}
local printedWarnings = {}

local function OnDelete(event, uid)
  warnings[uid] = nil
end

Private:RegisterCallback("Delete", OnDelete)

local function UpdateWarning(uid, key, severity, message, printOnConsole)
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
  else
    warnings[uid][key] = nil
  end

  Private.callbacks:Fire("AuraWarningsUpdated", uid)
end

local severityLevel = {
  info = 0,
  warning = 1,
  error = 2
}

local icons = {
  info = [[Interface/friendsframe/informationicon.blp]],
  warning = [[Interface/buttons/adventureguidemicrobuttonalert.blp]],
  error =  [[Interface/DialogFrame/UI-Dialog-Icon-AlertNew]]
}

local titles = {
  info = L["Information"],
  warning = L["Warning"],
  error = L["Error"]
}

local function AddMessages(result, messages, icon, mixedSeverity)
  if not messages then
    return result
  end
  for index, message in ipairs(messages) do
    if result ~= "" then
      result = result .. "\n\n"
    end
    if mixedSeverity then
      result = result .. "|T" .. icon .. ":12:12:0:0:64:64:4:60:4:60|t"
    end
    result = result .. message
  end
  return result
end

local function FormatWarnings(uid)
  if not warnings[uid] then
    return
  end

  local maxSeverity
  local mixedSeverity = false

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

  local result = ""
  result = AddMessages(result, messagePerSeverity["error"], icons["error"], mixedSeverity)
  result = AddMessages(result, messagePerSeverity["warning"], icons["warning"], mixedSeverity)
  result = AddMessages(result, messagePerSeverity["info"], icons["info"], mixedSeverity)
  return icons[maxSeverity], titles[maxSeverity], result
end

Private.AuraWarnings = {}
Private.AuraWarnings.UpdateWarning = UpdateWarning
Private.AuraWarnings.FormatWarnings = FormatWarnings
