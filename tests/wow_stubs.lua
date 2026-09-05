-- Stand-ins for the WoW globals that WeakAuras/AuraEnvironment.lua and
-- WeakAurasOptions/CommonOptions.lua touch when they load or when the tests
-- drive them. This is not a WoW API emulation. It provides only what the
-- sandbox needs to be constructed and exercised.
local M = {}

local function strsplit(delimiter, text)
  local out = {}
  local escaped = delimiter:gsub("%p", "%%%0")
  for piece in (text .. delimiter):gmatch("([^" .. escaped .. "]*)" .. escaped) do
    out[#out + 1] = piece
  end
  return unpack(out)
end

local function strtrim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function CopyTable(source)
  local copy = {}
  for key, value in pairs(source) do
    copy[key] = type(value) == "table" and CopyTable(value) or value
  end
  return copy
end

--- Installs the global helpers, API functions, frames, libraries, and
--- sensitive globals that the tests refer to. Sensitive globals return a
--- marker string so a test can tell the real function from a sandbox stub.
function M.install()
  _G.strsplit = strsplit
  _G.strtrim = strtrim
  -- WoW adds trim to the string library, so code can call ("x"):trim()
  rawset(string, "trim", strtrim)
  _G.tinsert = table.insert
  _G.tremove = table.remove
  _G.ceil = math.ceil
  _G.wipe = function(t)
    for key in pairs(t) do
      t[key] = nil
    end
    return t
  end
  _G.CopyTable = CopyTable

  _G.GetUnitName = function() return "Tester" end
  _G.UnitGUID = function() return "Player-1-1" end
  _G.UnitAura = function() return nil end
  _G.IsInRaid = function() return false end
  _G.UnitExists = function() return false end
  _G.C_Timer = { After = function() end, NewTicker = function() end }

  -- Frames are plain tables here. A child frame without a name is reached
  -- through its parent, which is what the frame chooser produces.
  _G.PlayerFrame = { healthbar = {} }

  -- Globals the sandbox must hide from aura code.
  _G.EnumerateFrames = function() return "REAL_EnumerateFrames" end
  _G.RunScript = function() return "REAL_RunScript" end
  _G.SendMail = function() return "REAL_SendMail" end
  _G.securecall = function() return "REAL_securecall" end
  _G.SlashCmdList = {}
  _G.WeakAurasSaved = { displays = {} }
  _G.WeakAurasOptions = {}

  local libs = {
    LibSerialize = {},
    LibDeflate = {},
    ["LibCustomGlow-1.0"] = { ButtonGlow_Start = function() end, ButtonGlow_Stop = function() end },
    ["LibGetFrame-1.0"] = { GetUnitFrame = function() end, GetUnitNameplate = function() end },
  }
  _G.LibStub = setmetatable({ GetLibrary = function(_, name) return libs[name] end }, {
    __call = function(_, name) return libs[name] end,
  })
end

--- Returns a table that answers any unknown key with a no-op function. Use it
--- for objects whose many members a test does not exercise.
function M.permissive(table)
  return setmetatable(table or {}, {
    __index = function() return function() end end,
  })
end

--- A WeakAuras table with markers for the functions that aura code must not be
--- able to reach.
function M.newWeakAuras()
  return {
    IsLibsOK = function() return true end,
    L = setmetatable({}, { __index = function(_, key) return key end }),
    Add = function() return "REAL_Add" end,
    PreAdd = function() return "REAL_PreAdd" end,
    Import = function() return "REAL_Import" end,
    Delete = function() return "REAL_Delete" end,
    HideOptions = function() return "REAL_HideOptions" end,
    GetData = function() return nil end,
    GetRegion = function() return nil end,
    doubleWidth = 2,
    normalWidth = 1,
    halfWidth = 0.5,
  }
end

--- The Private table that AuraEnvironment.lua expects. Sandbox warnings are
--- appended to the returned list as { key = ..., message = ... }.
function M.newPrivate()
  local warnings = {}
  local Private = {
    ExecEnv = {},
    clones = {},
    regions = {},
    multiUnitUnits = { nameplate = {} },
    AuraWarnings = {
      UpdateWarning = function(_, key, severity, message)
        -- A call without a severity clears a warning.
        if severity then
          warnings[#warnings + 1] = { key = key, message = message }
        end
      end,
    },
    UIDtoID = function() return nil end,
    DebugLog = { Print = function() end },
    customActionsFunctions = {},
    GetErrorHandlerId = function() return function() end end,
    EnsureRegion = function() return nil end,
    AuraEnvironmentWrappedSystem = { Get = function() return _G.C_Timer end },
  }
  return Private, warnings
end

return M
