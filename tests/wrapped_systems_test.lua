-- A callback an aura schedules runs long after the aura environment is gone. The
-- wrapped systems put the environment back and name the aura when the callback errors.
-- Without that, a Lua error from the callback points at the timer library instead.
local testsDir = arg[0]:match("^(.*)[/\\][^/\\]*$") or "."
package.path = testsDir .. "/?.lua;" .. package.path
local T = require("helpers")
local stubs = require("wow_stubs")

stubs.install()
_G.SafePack = function(...) return { n = select("#", ...), ... } end
_G.SafeUnpack = function(packed) return unpack(packed, 1, packed.n) end

_G.WeakAuras = stubs.newWeakAuras()
local WeakAuras = _G.WeakAuras
local Private = stubs.newPrivate()

local auraData = { id = "test", uid = "test-uid", config = {}, information = {}, actions = {} }
WeakAuras.GetData = function(id)
  if id == "test" then
    return auraData
  end
end
local region = { id = "test" }
WeakAuras.GetRegion = function() return region end
Private.EnsureRegion = function() return region end
Private.UIDtoID = function() return "test" end
Private.callbacks = { RegisterCallback = function() end }

-- Records what the error handler was told, so a test can check the attribution.
local attributed = {}
Private.GetErrorHandlerId = function(id, context)
  return function(message)
    attributed[#attributed + 1] = { id = id, context = context, message = message }
  end
end

-- Stand-ins for the two timer systems. Both just keep the callback so a test can fire it.
local scheduled = {}
WeakAuras.timer = {
  ScheduleTimer = function(self, func, delay)
    scheduled[#scheduled + 1] = { self = self, func = func, delay = delay }
    return "handle-" .. #scheduled
  end,
  CancelTimer = function(self, handle) return handle end,
}
_G.C_Timer = {
  After = function(delay, func)
    scheduled[#scheduled + 1] = { func = func, delay = delay }
  end,
  NewTimer = function() end,
  NewTicker = function() end,
}

T.loadAddonFile("WeakAuras/AuraEnvironment.lua", "WeakAuras", Private)
T.loadAddonFile("WeakAuras/AuraEnvironmentWrappedSystems.lua", "WeakAuras", Private)

--- Runs code the way a custom action runs it: inside an activated aura environment.
local function runCustom(body)
  local fn, err = WeakAuras.LoadFunction("return function()\n" .. body .. "\nend", "test")
  assert(fn, err)
  Private.ActivateAuraEnvironment("test")
  local result = fn()
  Private.ActivateAuraEnvironment()
  return result
end

--- The wrapper swallows the callback's error through xpcall. Catch it here too, so that
--- an unwrapped callback reports a failed expectation instead of ending the run.
local function fireLast()
  local entry = scheduled[#scheduled]
  assert(entry, "nothing was scheduled")
  local escaped = not pcall(entry.func)
  return entry, escaped
end

local function clear()
  for i = #attributed, 1, -1 do attributed[i] = nil end
  for i = #scheduled, 1, -1 do scheduled[i] = nil end
end

T.section("WeakAuras.timer callbacks are attributed to the aura")
do
  clear()
  local entry = runCustom([[
    return WeakAuras.timer:ScheduleTimer(function()
      if aura_env then aura_env.ranInside = aura_env.id end
      error("Intentional callback error")
    end, 1)
  ]])
  T.expect(entry == "handle-1", "ScheduleTimer still returns the library's handle")
  T.expect(#scheduled == 1, "the call reached the timer")
  T.expect(scheduled[1].delay == 1, "the delay is passed through unchanged")
  T.expect(scheduled[1].func ~= nil, "a callback was scheduled")

  local _, escaped = fireLast()
  T.expect(not escaped, "the error did not escape to whatever fired the timer")
  T.expect(#attributed == 1, "the error went to an error handler")
  if #attributed == 1 then
    T.expect(attributed[1].id == "test", "the handler names the aura")
    T.expect(attributed[1].context == "Callback function", "with the callback context")
    T.expect(attributed[1].message:find("Intentional callback error", 1, true) ~= nil,
             "and carries the original message")
  end
  T.expect(runCustom("return aura_env.ranInside") == "test",
           "the aura environment was active inside the callback")
end

T.section("a callback that does not error still runs")
do
  clear()
  runCustom([[
    WeakAuras.timer:ScheduleTimer(function()
      aura_env.ranClean = true
    end, 2)
  ]])
  fireLast()
  T.expect(#attributed == 0, "no error was reported")
  T.expect(runCustom("return aura_env.ranClean") == true, "the callback body ran")
end

T.section("non-callback arguments are left alone")
do
  clear()
  -- AceTimer also takes a method name on the scheduling object.
  runCustom([[WeakAuras.timer:ScheduleTimer("CancelTimer", 3)]])
  T.expect(scheduled[1].func == "CancelTimer", "a string callback is passed through")
end

T.section("C_Timer keeps its existing attribution")
do
  clear()
  runCustom([[
    C_Timer.After(1, function()
      error("Intentional C_Timer error")
    end)
  ]])
  fireLast()
  T.expect(#attributed == 1, "the error went to an error handler")
  if #attributed == 1 then
    T.expect(attributed[1].id == "test", "the handler names the aura")
  end
end

T.section("outside an aura environment nothing is wrapped")
do
  clear()
  -- Called without activating an environment first, so there is no aura to attribute to.
  local fn = assert(WeakAuras.LoadFunction(
    "return function() return WeakAuras.timer.ScheduleTimer end", "test"))
  T.expect(fn() == WeakAuras.timer.ScheduleTimer, "the library's own function is handed out")
end

T.section("unwrapped timer methods stay reachable")
do
  clear()
  T.expect(runCustom([[return WeakAuras.timer:CancelTimer("handle-7")]]) == "handle-7",
           "CancelTimer falls through to the library")
end

T.finish()
