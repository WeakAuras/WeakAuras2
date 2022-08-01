if not WeakAuras.IsLibsOK() then return end
local AddonName, Private = ...

local WeakAuras = WeakAuras
local L = WeakAuras.L

local debugLogs = {}
local enabled = {}

Private.DebugLog = {
  -- Print
  -- Clear
  -- SetEnabled
  -- IsEnabled
  -- GetLogs
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

function Private.DebugLog.Print(uid, text, ...)
  if enabled[uid] then
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

local function AddMessage(self, msg)
  tinsert(self, msg)
end

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

function Private.DebugLog.IsEnabled(uid)
  return enabled[uid]
end

function Private.DebugLog.GetLogs(uid)
  if debugLogs[uid] then
    return table.concat(debugLogs[uid], "\n")
  end
end

local function OnDelete(_, uid)
  debugLogs[uid] = nil
  enabled[uid] = nil
end

Private.callbacks:RegisterCallback("Delete", OnDelete)


