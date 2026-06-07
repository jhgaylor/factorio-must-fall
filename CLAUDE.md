# factorio-must-fall — Factorio mod

A Factorio **2.0** mod (Space Age era). Target engine version: 2.0.76. Lua 5.2.

## Project layout
See `README.md` for the full file map. Key entry points: `settings.lua`,
`data.lua` (+ `data-updates.lua`), `control.lua`. Prototype definitions go in
`prototypes/` (required from `data.lua`); runtime modules in `scripts/`
(required from `control.lua`).

## Non-obvious rules (get these wrong and the mod breaks)
- **Two worlds.** The data/prototype stage and the runtime/control stage are
  separate Lua states. `data.lua` builds `data.raw`; `control.lua` may NOT touch
  `data.raw` and instead uses the runtime API (`game`, `script`, `defines`, ...).
- **`storage`, not `global`.** In 2.0 the persistent per-save table was renamed
  from `global` to `storage`. Use `storage`. Only put deterministic, serialisable
  data in it (no functions/metatables; re-fetch LuaObjects rather than storing).
- **Determinism.** Runtime code must be deterministic for multiplayer — no
  `math.random` outside `game`-seeded RNG, no real-world time, no iteration-order
  dependence on `pairs` over non-deterministic keys.
- **Load order:** settings → data → data-updates → data-final-fixes → control.
  To modify another mod's prototype, do it in `data-updates`/`data-final-fixes`,
  not `data.lua`.
- **Changelog format is strict.** `changelog.txt` must start with a separator
  line, then `Version: x.y.z`, `Date: ...`, then 2-space-indented categories
  (`Features:`, `Bugfixes:`, `Changes:`) with 4-space `- ` entries. Keep it in
  sync with `info.json` `version` on every release.
- **Locale.** User-facing strings should be localised keys in
  `locale/en/locale.cfg`, referenced as `{"category.key"}`, not hardcoded.

## Dev workflow
- `./dev/link.sh` symlinks this repo into `~/Library/Application Support/factorio/mods/`
  (as a folder named exactly `factorio-must-fall`). Enable in the Mods menu.
- No hot reload for mod code: restart Factorio / reload the save after Lua edits.
  Use the in-game console `/c <lua>` for quick runtime experiments.
- `npm run package` (FMTK) builds the release zip; what's included is everything
  except dotfiles, `modname_*.zip`, and the globs in `info.json#/package/ignore`.
- `luacheck .` lints (globals declared in `.luacheckrc`); install via luarocks.

## flib (Factorio Library) — reach for it before reinventing
Declared dependency (`flib >= 0.16.5` in `info.json`). Used via
`require("__flib__.<module>")`. Prefer flib helpers over hand-rolling:
- `on-tick-n` — schedule a task for a future tick (vs manual `on_tick` bookkeeping).
- `position`, `bounding-box`, `direction`, `orientation`, `math` — geometry/math.
- `table` — deep copy/merge, map/filter/reduce, `for_n_of`.
- `gui` + `gui-templates` — declarative GUI building + handler registry (use for any UI).
- `format` — number (commas/SI) and tick→`hh:mm:ss` formatting.
- `dictionary` — runtime localised-string translation (heavy; only if needed).
- data stage: `data-util`, `prototypes`, `technology`.

Source is extracted to `dev/flib/` (gitignored) for LuaLS autocomplete; re-extract
from the installed mod with `npm run flib`. flib has no online docs — read the
EmmyLua annotations in `dev/flib/<module>.lua` for signatures.

## Tooling (FMTK + LuaLS)
- **`npm run check`** — fast node-only Lua 5.2 syntax gate over all mod `.lua`
  files (catches load-breaking typos without launching Factorio). Run it before
  loading the game. `npm run lint` (luacheck) is deeper but needs a Lua toolchain.
- **Releases are automated**: `npm run version` (bump + new changelog section),
  write the notes, commit/push, then `npm run release` pushes a `v<version>` tag.
  `.github/workflows/release.yml` then builds the zip and publishes a GitHub
  Release (notes from the matching changelog section). Tag must match info.json.
- **FMTK** (`factoriomod-debug`) is pinned in `package.json`. Run via `npx fmtk ...`
  or the npm scripts: `npm run package`, `npm run version`, `npm run datestamp`,
  `npm run publish`, `npm run defs`. The VS Code extension
  `justarandomgeek.factoriomod-debug` adds an in-editor debugger + profiler.
- **LuaLS** (`sumneko.lua`) is configured by `.luarc.json` (Lua 5.2, Factorio
  plugin, the generated library). Recommended extensions live in `.vscode/`.
- **Generated API type defs** live in `dev/factorio-defs/` (gitignored, ~6.8M,
  version-tied to 2.0.76). Regenerate with `npm run defs`. These are the most
  reliable API reference — prefer reading
  `dev/factorio-defs/factorio/library/runtime-api/` and `.../prototype-api/`
  (full `@class`/`@field` annotations with doc links) over recalling the API.
- `node_modules/` and `dev/factorio-defs/` are gitignored; `npm install` +
  `npm run defs` rebuild them. The shipped mod is pure Lua — none of this is packaged.

## Docs
Runtime API: https://lua-api.factorio.com/latest/ — Prototypes:
https://lua-api.factorio.com/latest/prototypes.html — Wiki: https://wiki.factorio.com/Modding
There is a `/factorio-mod` project skill with deeper conventions.
