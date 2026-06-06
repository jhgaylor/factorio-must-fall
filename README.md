# Factorio Must Fall

A mod for **Factorio 2.0** (Space Age era; developed against 2.0.76).

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
luacheck .           # lint (config in .luacheckrc)
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

```bash
npm run datestamp    # stamp today's date into the top changelog section
npm run version      # bump info.json + changelog version
npm run package      # build -> factorio-must-fall_<version>.zip
npm run publish      # package + upload to the mod portal (needs credentials)
```

Packaging is handled by FMTK; what gets included is everything except dotfiles,
`modname_*.zip`, and the globs in `info.json#/package/ignore` (node_modules, dev/,
package.json, CLAUDE.md). Keep `info.json` `version` and the `changelog.txt` top
entry in sync (`npm run version` does both).

## Reference

- Modding docs / tutorial: https://wiki.factorio.com/Modding
- Lua runtime API: https://lua-api.factorio.com/latest/
- Prototype docs: https://lua-api.factorio.com/latest/prototypes.html

## License

[MIT](LICENSE) © Jake Gaylor
