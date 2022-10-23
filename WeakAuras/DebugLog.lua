if not WeakAuras.IsLibsOK() then return end
--- @type string, Private
local AddonName, Private = ...

local WeakAuras = WeakAuras
local L = WeakAuras.L

--- @type table<uid, string[]|nil>
local debugLogs = {}
--- @type table<uid, boolean|nil>
local enabled = {}

--- @class debugLog
--- @field Print fun(uid: uid, text: string, ...: any)
--- @field Clear fun(uid: uid)
--- @field SetEnabled fun(uid: uid, enabled: uid)
--- @field IsEnabled fun(uid: uid) : boolean|nil
--- @field GetLogs fun(uid: uid) : string|nil

--- @type debugLog
Private.DebugLog = {
}

local function serialize(log, input)
  if type(input) == "table" then
    if log[#log] == "" then
      log[#log] = L["Dumping table"]
    else
      tinsert(log, L["Dumping table"])
    end
    -- Use dump to create a table dump, because that already handles depth limitation
    -- and cycles and looks nice
    -- But this requires temporarily setting DEFAULT_CHAT_FRAME
    -- Nothing can go wrong with that.
    local defaultChatFrame = _G.DEFAULT_CHAT_FRAME
    _G.DEFAULT_CHAT_FRAME = log
    DevTools_Dump(input)
    _G.DEFAULT_CHAT_FRAME = defaultChatFrame
    tinsert(log, "")
  else
    if log[#log] == "" then
      log[#log] = tostring(input)
    else
      log[#log] = log[#log] .. " " .. tostring(input)
    end
  end
end

--- DebugLog.Print the DebugPrint function for custom auras to call
---@param uid uid
---@param text string
---@param ... any
function Private.DebugLog.Print(uid, text, ...)
  if enabled[uid] then
    --- @type string[]
    local log = debugLogs[uid]
    tinsert(log, "")
    if select('#', ...) == 0 then
      serialize(log, text)
    else
      serialize(log, text)
      local texts = {...}
      for i = 1, select('#', ...) do
        local v = select(i, ...)
        serialize(log, v)
      end
    end

    if #log > 1000 then
      Private.AuraWarnings.UpdateWarning(uid, "Debug Log", "warning", L["Debug Log contains more than 1000 entries"], true)
    end
  end
end

--- Adds a message to the debug log
---@param self any
---@param msg string
local function AddMessage(self, msg)
  tinsert(self, msg)
end

--- Clears the debug log for a given uid
---@param uid uid
function Private.DebugLog.Clear(uid)
  if enabled[uid] then
    debugLogs[uid] = {
      AddMessage = AddMessage
    }
    -- Dance to clear a potential console message from the AuraWarnings
    Private.AuraWarnings.UpdateWarning(uid, "Debug Log", "info")
    Private.AuraWarnings.UpdateWarning(uid, "Debug Log", "info", L["Debug Logging enabled"])
  end
end

--- Enables/Disables the debug logging for a aura
---@param uid uid
---@param enable boolean
function Private.DebugLog.SetEnabled(uid, enable)
  if enabled[uid] == enable then
    return
  end
  enabled[uid] = enable
  if enable then
    debugLogs[uid] = {
      AddMessage = AddMessage
    }
    Private.AuraWarnings.UpdateWarning(uid, "Debug Log", "info", L["Debug Logging enabled"])
  else
    debugLogs[uid] = nil
    Private.AuraWarnings.UpdateWarning(uid, "Debug Log", "info")
  end
end

---Returns whether debug logging is enabled for the given aura uid
---@param uid uid
---@return boolean
function Private.DebugLog.IsEnabled(uid)
  return enabled[uid]
end

--- Returns the logs for a given aura uid
---@param uid uid
---@return string?
function Private.DebugLog.GetLogs(uid)
  if debugLogs[uid] then
    return table.concat(debugLogs[uid], "\n")
  end
end

--- Handles the deletion of an aura
---@param _ any
---@param uid uid
local function OnDelete(_, uid)
  debugLogs[uid] = nil
  enabled[uid] = nil
end

Private.callbacks:RegisterCallback("Delete", OnDelete)


