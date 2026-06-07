-- settings.lua — the SETTINGS stage (runs first, before data).
--
-- Per-tier hunter tuning is exposed as STARTUP settings (only changeable from the
-- main-menu mod settings, since they rebuild prototypes in the data stage):
--   fmf-<tier>-guns        : how many guns that hunter deploys with (1-4)
--   fmf-<tier>-resistance  : multiplier on that hunter's tuned resistances
-- Runtime toggles (changeable mid-game):
--   fmf-enabled                : master switch for the runtime logic
--   fmf-disable-friendly-fire  : turn off friendly fire so hunters don't self-damage
-- Localised in locale/en/locale.cfg under [mod-setting-name]/[mod-setting-description].

local TIERS = {
    { key = "light",   guns = 1 },
    { key = "medium",  guns = 2 },
    { key = "heavy",   guns = 2 },
    { key = "cannon",  guns = 2 },
    { key = "siege",   guns = 3 },
    { key = "nuclear", guns = 1 },
}

local defs = {
    {
        type = "bool-setting",
        name = "fmf-enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "a",
    },
    {
        type = "bool-setting",
        name = "fmf-disable-friendly-fire",
        setting_type = "runtime-global",
        default_value = true,
        order = "b",
    },
}

for i, t in ipairs(TIERS) do
    local base = "c" .. string.format("%02d", i)
    defs[#defs + 1] = {
        type = "int-setting",
        name = "fmf-" .. t.key .. "-guns",
        setting_type = "startup",
        default_value = t.guns,
        minimum_value = 1,
        maximum_value = 4,
        order = base .. "a",
    }
    defs[#defs + 1] = {
        type = "double-setting",
        name = "fmf-" .. t.key .. "-resistance",
        setting_type = "startup",
        default_value = 1.0,
        minimum_value = 0.0,
        maximum_value = 4.0,
        order = base .. "b",
    }
end

data:extend(defs)
