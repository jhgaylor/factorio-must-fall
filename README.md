# Factorio Must Fall

A combat **autobattler** for **Factorio 2.0** (Space Age era; developed against 2.0.76).
Build a factory that builds an army that fights for you.

> Not affiliated with — but surely name-inspired by —
> [The Factory Must Fall](https://store.steampowered.com/app/3970860/The_Factory_Must_Fall/),
> a standalone game in the same genre that was already on Steam (though not yet
> released) when this mod was made. Check it out if you want more of this.

## What it does

You craft a **Vehicle Hangar** — a power-hungry assembling machine. Instead of
items, it builds **hunters**: autonomous spidertron-class war machines that drive
off on their own, seek out the nearest enemy anywhere nearby, and fight without a
driver. Clear a nest and they roll on to the next. Lose one and you just build
another.

Each hunter is a **recipe** combining a **vehicle** (the chassis — how tough it is)
with **ammo** (the weapon — how hard it hits):

| Hunter  | Recipe (vehicle + ammo)              | Role |
|---------|--------------------------------------|------|
| Light   | car + firearm magazines              | cheap, fast, fragile |
| Medium  | tank + piercing magazines            | sturdier machine-gunner |
| Heavy   | tank + explosive rockets             | rocket bombardment |
| Cannon  | tank + explosive cannon shells       | hard-hitting direct fire |
| Siege   | spidertron + uranium cannon shells   | armored heavy cannons |
| Nuclear | spidertron + atomic bombs            | walking apocalypse (immune to its own nukes) |

Feed the hangar power and ingredients and it churns out a self-deploying army.
Tougher vehicles make tankier hunters; stronger ammo makes deadlier ones — so the
fleet scales with your factory's tech and output.

Gun counts, per-hunter resistances, and friendly fire are all adjustable in
**Settings → Mod settings**.

> Requires [flib](https://mods.factorio.com/mod/flib).

## Layout

```
info.json            Mod manifest: name, version, factorio_version, dependencies.
settings.lua         Settings stage — defines mod settings.
data.lua             Data stage — registers prototypes (requires prototypes/*).
data-updates.lua     Data stage, second pass — modify other mods' prototypes.
control.lua          Runtime stage — events, game logic (uses `storage`, not `global`).
changelog.txt        Strict Factorio changelog format (drives the in-game changelog).
locale/en/locale.cfg Translatable strings (setting names, item names, messages).
prototypes/          Prototype definitions, required from data.lua.
scripts/             Runtime Lua modules, required from control.lua.
graphics/            PNG assets.
dev/link.sh          Symlink this repo into the Factorio mods dir for live dev.
dev/factorio-defs/   Generated Factorio API type defs for LuaLS (gitignored).
package.json         Dev tooling only (FMTK) — not shipped. npm scripts below.
```

## Load stages (in order)

`settings` → `settings-updates` → `settings-final-fixes` → `data` → `data-updates` → `data-final-fixes` → game starts → `control.lua`.

The data stage builds the global `data.raw` prototype table. The control stage
runs inside a live save and may not touch `data.raw` — it uses the runtime API.

## Develop

```bash
npm install          # one-time: pull pinned FMTK tooling
npm run defs         # one-time: generate Factorio API type defs into dev/factorio-defs/
npm run flib         # one-time: extract flib into dev/flib/ for LuaLS autocomplete
./dev/link.sh        # symlink into ~/Library/Application Support/factorio/mods/
npm run check        # fast Lua syntax gate (node-only) — run before loading the game
luacheck .           # deeper lint (needs a Lua toolchain; config in .luacheckrc)
```

Then start Factorio. Enable the mod in **Mods**. After Lua edits, restart
Factorio (or reload the save) — there is no hot reload for mod code, though the
in-game console (`/c`) helps for quick experiments.

### Editor

Open in VS Code and install the recommended extensions (`.vscode/extensions.json`):
- **sumneko.lua** (LuaLS) — autocomplete & type-checking, configured by `.luarc.json`
  against the generated Factorio API defs.
- **justarandomgeek.factoriomod-debug** (FMTK) — breakpoint debugger + profiler.

`node_modules/` and `dev/factorio-defs/` are gitignored; `npm install && npm run defs`
rebuild them. None of this is shipped — the mod is pure Lua.

## Release

Releases are automated. Pushing a `v*` tag triggers
`.github/workflows/release.yml`, which builds the zip and publishes a GitHub
Release with it attached (notes come from the matching `changelog.txt` section).

```bash
npm run version      # bump info.json + add a new changelog section
#                      ...then write that section's notes and commit + push
npm run release      # tag v<version> from info.json and push it -> CI publishes
```

The tag must match the `info.json` version, and `changelog.txt` must have a
section for it (the `release` script checks both).

Manual / mod-portal options:

```bash
npm run package      # build -> factorio-must-fall_<version>.zip locally
npm run publish      # package + upload to the mod portal (needs an API key)
```

Packaging is handled by FMTK; what gets included is everything except dotfiles,
`modname_*.zip`, and the globs in `info.json#/package/ignore` (node_modules, dev/,
package.json, CLAUDE.md).

## Reference

- Modding docs / tutorial: https://wiki.factorio.com/Modding
- Lua runtime API: https://lua-api.factorio.com/latest/
- Prototype docs: https://lua-api.factorio.com/latest/prototypes.html

## License

[MIT](LICENSE) © Jake Gaylor
