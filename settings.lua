-- settings.lua — the SETTINGS stage (runs first, before data).
-- Define mod settings here with data:extend{...}. Setting types:
--   "startup"        : locked at game start, available in the data stage.
--   "runtime-global" : per-save, changeable in-game (admin), read via settings.global.
--   "runtime-per-user": per-player, read via settings.get_player_settings(player).
-- Localise names/descriptions in locale/en/locale.cfg under [mod-setting-name]
-- and [mod-setting-description] using the setting's `name`.

data:extend({
    {
        type = "bool-setting",
        name = "fmf-enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "a",
    },
})
