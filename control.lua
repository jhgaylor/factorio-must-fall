-- control.lua — the RUNTIME (control) stage.
-- See CLAUDE.md for the data-vs-control split and the 2.0 `storage` rule. This
-- file only wires the engine to scripts/autobattler.lua; the logic lives there.

local autobattler = require("scripts.autobattler")

local CHECK_INTERVAL = 60 -- run launch + hunt logic once per second

-- Lifecycle ------------------------------------------------------------------
script.on_init(autobattler.init)
script.on_configuration_changed(autobattler.rescan)

-- Track hangars as they appear / disappear -----------------------------------
local function on_built(event)
    local entity = event.entity
    if entity and entity.valid then
        autobattler.register_hangar(entity)
    end
end

-- Also fires for hunter deaths, which clears them from `storage`.
local function on_removed(event)
    local entity = event.entity
    if entity then
        autobattler.unregister_entity(entity)
    end
end

local build_events = {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
}
-- Space Age adds platform building; only present when that mod is active.
if defines.events.on_space_platform_built_entity then
    build_events[#build_events + 1] = defines.events.on_space_platform_built_entity
end
for _, ev in pairs(build_events) do
    script.on_event(ev, on_built)
end

for _, ev in pairs({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy,
}) do
    script.on_event(ev, on_removed)
end

-- Re-apply the friendly-fire setting when it's toggled mid-game.
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == "fmf-disable-friendly-fire" then
        autobattler.apply_friendly_fire()
    end
end)

-- Main loop ------------------------------------------------------------------
script.on_nth_tick(CHECK_INTERVAL, function()
    if settings.global["fmf-enabled"].value then
        autobattler.on_interval()
    end
end)
