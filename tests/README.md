# Tests

These are regression tests for the aura sandbox. They load real addon files
outside of World of Warcraft, with the WoW globals they need stubbed, and check
that the escape routes we have found and closed stay closed:

- `aura_environment_test.lua` checks that custom aura code compiled through
  `WeakAuras.LoadFunction` cannot reach the real global table, the blocked WoW
  functions, or the data-changing WeakAuras API, and that legitimate lookups
  such as anchoring to a child frame without a name keep working.
- `common_options_test.lua` checks that the options panel evaluates stored
  custom code only inside the sandbox when it renders the error label under a
  code box.

A passing run is not a security proof. The tests only probe the routes they
name. They cannot show that the block lists are complete, that no other route
exists, or that an allowed WoW function is harmless. They do not emulate the
WoW API, taint, or secure execution. When a new escape is found, add it here so
it cannot come back.

## Running

The sandbox is built on `loadstring` and `setfenv`, which Lua 5.2 removed, so
the tests need Lua 5.1 or LuaJIT:

```sh
lua5.1 tests/run.lua
```

or

```sh
luajit tests/run.lua
```

Each test file also runs on its own, for example
`luajit tests/aura_environment_test.lua`. A failing expectation prints `FAIL`
and the process exits with a non-zero status.

## Adding a test

Put shared WoW stubs in `wow_stubs.lua`. Keep them to what the loaded files
touch. Write a new `*_test.lua` that requires `helpers` and `wow_stubs`, loads
the addon file with `T.loadAddonFile`, states expectations with `T.expect`,
and ends with `T.finish()`. Then add the file name to the list in `run.lua`.
