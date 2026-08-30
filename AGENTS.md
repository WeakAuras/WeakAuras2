# Repository guide for coding agents

This file applies to the complete repository. Read `CONTRIBUTING.md` before you
change code. A more specific `AGENTS.md` can add rules for its own directory.

## Project map

WeakAuras is a World of Warcraft addon written for Lua 5.1. The repository
ships five addon packages:

- `WeakAuras/` is the always-loaded runtime. It owns saved display data,
  triggers, regions, conditions, animations, import, export, and migrations.
- `WeakAurasOptions/` is the load-on-demand configuration UI. It depends on
  `WeakAuras/`. Runtime code must not depend on this package.
- `WeakAurasTemplates/` is the load-on-demand template browser and its
  game-version data.
- `WeakAurasModelPaths/` contains generated model-path data.
- `WeakAurasArchive/` is the load-on-demand saved-variable container for the
  archive.

The `.toc` files define the load order. Treat this order as an API. When you
add, remove, or move a Lua file, update every relevant `.toc` file and put the
file after its dependencies.

## Runtime ownership

- `WeakAuras/Init.lua` creates the public global `WeakAuras` table.
- Most runtime files use `local Private = select(2, ...)` for internal state
  shared across files. Put public addon APIs on `WeakAuras` and internal APIs
  on `Private`. Do not create another global.
- `WeakAuras/Types.lua` and the per-client `WeakAuras/Types_*.lua` files fill
  `Private` with shared option data, such as value lists and their localized
  display names. Each `.toc` loads the flavor file before `Types.lua`. Keep
  the flavor files consistent with each other, and keep this data consistent
  with the runtime code that reads it.
- `WeakAuras/Prototypes.lua`, `WeakAuras/GenericTrigger.lua`, and
  `WeakAuras/BuffTrigger2.lua` own major trigger behavior. Event dispatch and
  trigger updates are hot paths. Avoid repeated scans, temporary tables, and
  closures in these paths unless the behavior needs them.
- `WeakAuras/RegionTypes/RegionPrototype.lua` owns common region behavior.
  Concrete regions live in `WeakAuras/RegionTypes/`, and subregions live in
  `WeakAuras/SubRegionTypes/`.
- Region types register through `Private.RegisterRegionType`. Subregion types
  register through `WeakAuras.RegisterSubRegionType`. Trigger systems register
  through `WeakAuras.RegisterTriggerSystem`. Follow the nearby registration
  pattern instead of adding a second registry.
- A runtime region or subregion change often needs a matching change in
  `WeakAurasOptions/RegionOptions/` or `WeakAurasOptions/SubRegionOptions/`.
  Check both sides before you finish.

## Persistent and wire data

`WeakAurasSaved` and `WeakAurasArchive` survive addon reloads. Imported and
exported display data also crosses addon versions.

- Treat persisted table shapes, absent fields, `nil`, and `false` as public
  compatibility behavior.
- Add display-data migrations in `WeakAuras/Modernize.lua` when a shape change
  needs old data to continue to work.
- Review `WeakAuras/Transmission.lua` for changes that affect import, export,
  serialization, or supported data versions.
- Preserve deterministic ordering where serialized output or user-visible
  output depends on it.
- Do not move runtime state into the options package. The options package may
  not be loaded during combat, login, or normal event handling.

## Supported game versions

The addon supports Cataclysm, Mists, The Burning Crusade, Classic Era, and
Wrath/Titan. Each package has parallel `.toc` files for these clients.

- Keep common behavior in common files when the WoW APIs have the same
  contract.
- Put real client differences in the existing flavor files, such as
  `WeakAuras/Types_Cata.lua`, `WeakAuras/Types_Mists.lua`,
  `WeakAuras/Types_TBC.lua`, `WeakAuras/Types_Vanilla.lua`, and
  `WeakAuras/Types_Wrath.lua`.
- Template and model-path data also have flavor-specific files. Check all five
  clients when you change either area.
- Preserve the adjacency of each `## Interface:` line and its
  `# WOW_INTERFACE_TARGETS:` marker. The
  `.github/workflows/update-wow-interface.yml` workflow owns their values.
- Do not assume a WoW API exists on every client. Use the repository's current
  feature checks and compatibility patterns.

## WoW API reference

Always consult <https://warcraft.wiki.gg/wiki/World_of_Warcraft_API> for
questions about the WoW API. Each function's page documents its signature,
behavior, and the client flavors and patch versions that support it. Check it
before you call an API in flavor-sensitive code, and trust it over memory when
the two disagree. For historical changes to an API, such as a rename, a
removal, or a changed signature in a given patch, reference
<https://warcraft.wiki.gg/wiki/API_change_summaries>.

## Secure execution and taint

WoW separates secure Blizzard code from tainted addon code. Taint that spreads
into secure code blocks protected actions and raises blocked-action errors for
users. See <https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting> for
the model.

- Do not write to Blizzard frames, globals, or tables that secure code reads.
  Hook a Blizzard function with `hooksecurefunc`, as
  `WeakAuras/Transmission.lua` does for `SetItemRef`.
- A protected frame cannot change during combat lockdown. Follow the pattern
  in `WeakAuras/RegionTypes/RegionPrototype.lua`: check `region:IsProtected()`
  and `InCombatLockdown()`, raise an aura warning instead of touching the
  frame, and point users to
  <https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames>.
- Defer work that combat blocks until `PLAYER_REGEN_ENABLED`, as
  `Private.LoadOptions` in `WeakAuras/WeakAuras.lua` defers the options UI.
- Custom aura code runs in the sandbox that `WeakAuras/AuraEnvironment.lua`
  builds. When you expose a new function there, check that it cannot spread
  taint into secure code or perform a protected action.

## Code conventions

- Use Lua 5.1 syntax. WoW runs a customized Lua 5.1: it removes standard
  libraries such as `io` and most of `os`, and it adds utility functions and
  aliases such as `strsplit`, `tinsert`, and `wipe`. See
  <https://warcraft.wiki.gg/wiki/Lua_functions> for the full list. WoW
  supplies the globals listed in `.luacheckrc`.
- Use two spaces for indentation, LF line endings, a final newline, and no
  trailing whitespace. Follow `.editorconfig` for its listed exceptions.
- Do not add semicolons to new files. In an existing file, follow its local
  form, but prefer no semicolons.
- Localize every user-visible string. The translation scraper requires the
  exact form `L["text"]`, with double quotes and a local table named `L`.
- Mark a new user-visible feature with `WeakAuras.newFeatureString` as
  described in `CONTRIBUTING.md`.
- Keep changes narrow. Do not mix a fix with unrelated formatting, renaming,
  or speculative refactoring.
- Prefer a clear local branch over a new abstraction when the abstraction does
  not remove a real invalid state, repeated decision, or repeated lookup.
- Explain non-obvious ownership, lifecycle, and compatibility decisions. Do
  not add comments that only repeat the code.

## Generated data and external libraries

Do not hand-edit generated files unless the task explicitly asks for generated
output and you use the owning generator.

- `.github/scripts/update-model-paths.sh` generates the large
  `WeakAurasModelPaths/ModelPaths*.lua` files. Do not open or format these files
  as part of a broad repository rewrite.
- `.github/scripts/update-atlas-files.sh` and
  `.github/scripts/atlas_update.lua` generate atlas data.
- `.github/scripts/discordupdate.py` generates `WeakAuras/DiscordList.lua`.
- `generate_changelog.sh` generates changelog output, including
  `WeakAurasOptions/Changelog.lua`.
- `babelfish.lua` extracts localization phrases. `update_translations.sh`
  performs network writes and needs external credentials. Do not run it for
  normal code validation.
- `.pkgmeta` defines libraries that the BigWigs packager fetches into
  `WeakAuras/Libs/` and `WeakAurasOptions/Libs/`. Do not vendor or edit a
  fetched library unless the task is dependency work.
- Release and update scripts can change many files or external services. Run
  them only when the task requires that effect.

## Validation

Select checks that prove the changed behavior. Do not add a test that only
restates the implementation.

For every change:

1. Run `git diff --check`.
2. Parse each changed Lua file with `luac -p path/to/file.lua` when a compatible
   Lua compiler is available. Local `luac` can use a newer Lua version, so CI
   remains the authority for Lua 5.1 compatibility.
3. Run `luacheck . --no-color -q` when Luacheck is available. This matches the
   lint intent in `.github/workflows/pull_request.yml`.
4. Use a focused Lua harness with WoW globals stubbed, or verify the behavior
   in the correct WoW clients, when the change needs runtime proof.

Also check the relevant boundaries:

- For a region or subregion change, validate runtime behavior and its options
  controls.
- For a new or moved file, inspect every relevant `.toc` load order.
- For flavor-sensitive behavior, validate all affected clients.
- For saved or transmitted data, validate old data, new data, import, export,
  and migration behavior as applicable.
- For hot-path work, compare allocations and work per event or frame.

Pull-request CI runs Luacheck and a dry-run package build. It can catch load
order and packaging errors that a single-file check cannot catch. Do not say a
check passed unless you ran it or GitHub reports it as passed.

## Git and review

- Start a focused topic branch from current `main`.
- Use conventional commit messages.
- Keep each commit reviewable and keep the pull request description clear
  about the reason, behavior change, risks, and validation.
- Open every pull request with the repository template. `gh pr create` does
  not apply `.github/pull_request_template.md` on its own, so read that file
  and pass its filled-in content as the body. Keep its sections, which are
  Description, Type of change, How Has This Been Tested, and Checklist. Fill
  each one in for this change, and delete only the type-of-change options
  that do not apply.
- Update the pull request title and description when new commits change what
  the pull request does.
- Read all current review comments before you revise a pull request. When a
  comment is addressed, reply to its thread with what changed and the commit
  hash, then resolve the thread.
- Sign agent-authored content. Append a footer that names the agent and the
  model when you post a comment, create an issue, or open a pull request.
  Example:

  ```markdown
  ---
  Written by an agent (Claude Code, claude-opus-4-7).
  ```

- Preserve unrelated work in a dirty worktree.
