-- Shared helpers for the tests in this directory.
--
-- The tests load real addon files with the WoW globals they need stubbed, so
-- they run in any Lua 5.1 compatible interpreter. The aura sandbox is built on
-- loadstring and setfenv, which Lua 5.2 removed, so Lua 5.2 and later cannot
-- run these tests.
local M = {}

if not (loadstring and setfenv) then
  print(("These tests need Lua 5.1 or LuaJIT. %s has no loadstring/setfenv."):format(_VERSION))
  os.exit(2)
end

-- Directory of the running test script, and the repository root above it.
local script = arg and arg[0] or ""
M.testsDir = script:match("^(.*)[/\\][^/\\]*$") or "."
M.repoRoot = M.testsDir .. "/.."

local passes, failures = 0, 0

function M.section(name)
  print("# " .. name)
end

--- Records one expectation. Prints ok or FAIL, and returns the condition so a
--- caller can skip follow-up checks that depend on it.
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
  local chunk, err = loadfile(M.repoRoot .. "/" .. relativePath)
  if not chunk then
    error(err)
  end
  return chunk(addonName, privateTable)
end

return M
