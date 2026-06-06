---
name: factorio-mod
description: >-
  Conventions and reference for developing this Factorio 2.0 mod — load
  stages, the data vs control split, prototypes, runtime events, settings,
  locale, migrations, and the build/test loop. Use when adding items, recipes,
  entities, technologies, or runtime behaviour to factorio-must-fall.
---

# Factorio 2.0 mod development

Target: Factorio 2.0 (Space Age era), Lua 5.2. Engine validated at 2.0.76.

## The two stages (most common source of bugs)

A mod runs in two completely separate Lua states:

1. **Data / prototype stage** — defines what *can* exist. Loads `settings*.lua`
   then `data*.lua`. Builds the global `data.raw` table via `data:extend{...}`.
   No `game`, no `storage`, no events. This is just constructing definitions.
2. **Control / runtime stage** — `control.lua`, runs inside a live save. Uses the
   runtime API (`game`, `script`, `defines`, `storage`, `settings`, `rendering`,
   `remote`, `commands`). `data.raw` does not exist here. Prototypes are read-only
   via `prototypes.*` (e.g. `prototypes.item`, `prototypes.entity`).

Load order across all mods: `settings` → `settings-updates` →
`settings-final-fixes` → `data` → `data-updates` → `data-final-fixes` → game →
`control.lua`. To touch another mod's prototype, do it in `data-updates` (after
their `data.lua`) or `data-final-fixes` (to win).

## Prototypes (data stage)

```lua
-- prototypes/items.lua
data:extend({
  {
    type = "item",
    name = "fmf-widget",
    icon = "__factorio-must-fall__/graphics/widget.png", -- __<mod-name>__ path prefix
    icon_size = 64,
    stack_size = 50,
    subgroup = "intermediate-product",
    order = "z[fmf]",
  },
})
```
- Asset paths use `__<mod-name>__/...` → `__factorio-must-fall__/graphics/...`.
- Every referenced prototype name must exist by the end of the data stage or the
  game errors on load. Modify-don't-replace existing prototypes when possible.
- Recipes, technologies, entities follow the same `data:extend` pattern; consult
  https://lua-api.factorio.com/latest/prototypes.html for required fields per type.

## Runtime (control stage)

```lua
script.on_init(function() storage.foo = storage.foo or {} end)
script.on_configuration_changed(function(e) --[[ migrations ]] end)
script.on_event(defines.events.on_built_entity, function(e)
  local ent = e.entity
  -- ...
end)
script.on_nth_tick(60, function() --[[ ~once/second ]] end)
```
- **`storage`** is the only persisted table (renamed from `global` in 2.0). Store
  only deterministic, serialisable data. Re-fetch LuaObjects each tick rather than
  caching them across saves (they can become invalid).
- **Determinism for multiplayer:** no real-world time, no unseeded randomness
  (use `game`-provided RNG), avoid behaviour that depends on `pairs` order over
  non-deterministic keys. Desyncs come from non-determinism.
- Filter events where possible (e.g. event filters on `on_built_entity`) for perf.
- `settings.global["name"].value` (runtime-global), `settings.startup["name"].value`
  (data + control), `settings.get_player_settings(player)["name"].value` (per-user).

## Settings

Defined in `settings.lua` via `data:extend`. Types: `bool-setting`, `int-setting`,
`double-setting`, `string-setting`. `setting_type`: `startup`, `runtime-global`,
`runtime-per-user`. Localise names in `locale/en/locale.cfg` under
`[mod-setting-name]` / `[mod-setting-description]` keyed by the setting `name`.

## Locale

`locale/en/locale.cfg` is INI-style: `[section]` then `key=value`. Reference from
Lua as a localised string: `{"section.key"}` or with params
`{"section.key", arg1, arg2}` (use `__1__` placeholders in the value). Item/entity
names come from `[item-name]`, `[entity-name]`, etc. keyed by prototype name.

## Migrations

When you change `storage` shape or rename/remove prototypes, handle upgrades in
`script.on_configuration_changed`, and optionally add migration scripts in a
`migrations/` folder (`.lua` runs in control context, `.json` remaps prototypes).

## changelog.txt (strict format)

```
---------------------------------------------------------------------------------------------------
Version: 0.1.0
Date: 2026-06-06
  Features:
    - Thing added.
  Bugfixes:
    - Thing fixed.
```
First line MUST be a separator (line of dashes). Categories indented 2 spaces,
entries 4 spaces + `- `. Keep `version` here matched to `info.json`.

## Build & test loop

- `./dev/link.sh` — symlink repo into the mods dir (folder named exactly the mod
  name, no version). Enable in Mods menu.
- Edit Lua → restart Factorio or reload the save (no hot reload). Quick runtime
  pokes via in-game console `/c game.player.print(...)` (disables achievements).
- `luacheck .` — lint (globals in `.luacheckrc`).
- Package with `npm run package` (FMTK). It zips everything except dotfiles,
  `modname_*.zip`, and the globs in `info.json#/package/ignore` (node_modules,
  dev/, package.json, CLAUDE.md). Bump version with `npm run version`, datestamp
  the changelog with `npm run datestamp`, publish with `npm run publish`.
- Errors on load print a stack trace in-game and to `factorio-current.log` in the
  Factorio data dir — read that log when something fails to load.

## flib — use it before hand-rolling utilities

flib (Factorio Library) is a declared dependency (`flib >= 0.16.5`). Require modules
as `local flib_x = require("__flib__.x")`. Reach for these instead of reinventing:

```lua
local migration = require("__flib__.migration")   -- version-keyed migrations
local on_tick_n = require("__flib__.on-tick-n")    -- schedule task for a future tick
local position  = require("__flib__.position")     -- pos math (shorthand + explicit)
local bbox      = require("__flib__.bounding-box")
local table     = require("__flib__.table")        -- deep copy/merge, map/filter, for_n_of
local flib_gui  = require("__flib__.gui")           -- declarative GUI + handler registry
local format    = require("__flib__.format")        -- number (commas/SI), tick->hh:mm:ss
```

Other modules: `direction`, `orientation`, `math`, `queue`, `dictionary`
(runtime translation, heavy), `gui-templates`, and data-stage helpers
`data-util`, `prototypes`, `technology`, plus `reverse-defines`, `locale`.

flib has **no online docs** — read the EmmyLua annotations in `dev/flib/<module>.lua`
(gitignored; `npm run flib` re-extracts from the installed mod). LuaLS picks it up
via `.luarc.json`'s `workspace.library`, so autocomplete/types work in-editor.
`on-tick-n` and `dictionary` require init calls in `on_init` — check their headers.

## API reference — use the generated type defs FIRST

`dev/factorio-defs/` holds FMTK-generated LuaLS type definitions for the exact
engine version (2.0.76), ~1100 files. They are the most reliable API source —
each class/method has `@class`/`@field`/`@param` annotations and a doc link.
Before recalling a signature, grep them:

```bash
grep -rl "create_entity" dev/factorio-defs/factorio/library/runtime-api/
# runtime API: dev/factorio-defs/factorio/library/runtime-api/   (LuaSurface, LuaEntity, defines, ...)
# prototypes:  dev/factorio-defs/factorio/library/prototype-api/  (item, recipe, technology, ...)
```

Regenerate (e.g. after a Factorio update) with `npm run defs`. The defs are
gitignored — if absent, run `npm install && npm run defs`. LuaLS (`sumneko.lua`,
configured by `.luarc.json`) and the FMTK VS Code extension give the human
autocomplete + a breakpoint debugger/profiler.

## Reference
- Runtime API: https://lua-api.factorio.com/latest/
- Prototypes: https://lua-api.factorio.com/latest/prototypes.html
- Modding wiki / tutorial: https://wiki.factorio.com/Modding
- Data.raw browser: https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html
