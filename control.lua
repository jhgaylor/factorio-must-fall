-- control.lua — the RUNTIME (control) stage.
-- This runs inside a live game. The data/prototype stage is DONE; you no longer
-- touch `data.raw`. Instead you use the runtime API: `game`, `script`, `defines`,
-- `storage`, `settings`, `rendering`, etc.
--
-- 2.0 NOTE: the persistent per-save table is `storage` (it was named `global`
-- before 2.0). Anything you put in `storage` is saved/loaded and must be
-- deterministic — never store functions, metatables, or LuaObjects you can't
-- re-fetch. Everything here must be deterministic for multiplayer to stay in sync.

local function init()
    storage.players = storage.players or {}
end

-- Fired once when the mod is first added to a save (or a new game starts).
script.on_init(init)

-- Fired when mods/versions change on an existing save — run migrations here.
script.on_configuration_changed(function(_event)
    init()
end)

-- Example event handler. settings.global holds runtime-global mod settings.
script.on_event(defines.events.on_player_created, function(event)
    if not settings.global["fmf-enabled"].value then return end
    local player = game.get_player(event.player_index)
    if player then
        player.print("[Factorio Must Fall] active.")
    end
end)
