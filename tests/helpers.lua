-- Shared helpers for the tests in this directory.
local M = {}

-- The sandbox is built on loadstring and setfenv, which Lua 5.2 removed.
if not (loadstring and setfenv) then
  print(("These tests need Lua 5.1 or LuaJIT. %s has no loadstring/setfenv."):format(_VERSION))
  os.exit(2)
end

M.testsDir = arg[0]:match("^(.*)[/\\][^/\\]*$") or "."
M.repoRoot = M.testsDir .. "/.."

local passes, failures = 0, 0

function M.section(name)
  print("# " .. name)
end

--- Returns the condition so a caller can skip checks that depend on it.
function M.expect(condition, message)
  if condition then
    passes = passes + 1
    print("  ok    " .. message)
  else
    failures = failures + 1
    print("  FAIL  " .. message)
  end
  return condition
end

function M.finish()
  print(("%d passed, %d failed"):format(passes, failures))
  os.exit(failures > 0 and 1 or 0)
end

--- Loads a repository Lua file the way WoW does: the chunk receives the addon
--- name and the private table as its vararg.
function M.loadAddonFile(relativePath, addonName, privateTable)
  local chunk = assert(loadfile(M.repoRoot .. "/" .. relativePath))
  return chunk(addonName, privateTable)
end

return M
