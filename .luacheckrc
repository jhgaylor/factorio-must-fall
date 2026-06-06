-- luacheck config for a Factorio mod. Declares the engine-provided globals so
-- luacheck doesn't flag them. Run: luacheck .
std = "lua52"
max_line_length = false

read_globals = {
    "data", "mods", "settings", "defines", "table_size", "log", "localised_print",
    "serpent", "script", "game", "rendering", "rcon", "commands", "remote",
    "prototypes",
}

-- `storage` is the persistent runtime table (assigned to by the mod).
globals = { "storage" }
