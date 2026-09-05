-- Runs every test in this directory, each in its own interpreter process so
-- that stubbed globals cannot leak from one test into another.
--
-- Usage: lua5.1 tests/run.lua
--    or: luajit tests/run.lua
local testsDir = arg[0]:match("^(.*)[/\\][^/\\]*$") or "."
package.path = testsDir .. "/?.lua;" .. package.path
io.stdout:setvbuf("no") -- keep the headers in order with the child output
require("helpers") -- exits with a clear message on an unsupported Lua version

local tests = {
  "aura_environment_test.lua",
  "common_options_test.lua",
}

local interpreter = arg[-1]
local failed = {}
for _, name in ipairs(tests) do
  print("==> " .. name)
  local status = os.execute(string.format('"%s" "%s/%s"', interpreter, testsDir, name))
  if status ~= 0 then
    failed[#failed + 1] = name
  end
  print("")
end

if #failed > 0 then
  print("FAILED: " .. table.concat(failed, ", "))
  os.exit(1)
end
print("All test files passed.")
