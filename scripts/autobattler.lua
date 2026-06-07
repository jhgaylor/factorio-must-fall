-- Autobattler core: track hangars (assembling-machines), deploy the hunters they
-- craft, and steer each hunter toward the nearest enemy. Combat is handled by the
-- engine (a spider-vehicle with ammo and `auto_target_without_gunner` fires on its
-- own); we only supply movement targets via the autopilot. Gun count, resistance,
-- and friendly fire are configurable via mod settings (see settings.lua).
--
-- The hangar crafts a hidden token item per hunter; we read its output inventory,
-- spawn the matching chassis (entity name == token name), load the tier's ammo,
-- and remove the token. All state lives in `storage` keyed by unit_number, and
-- every per-entity action is order-independent, so this stays deterministic.

local flib_position = require("__flib__.position")

local autobattler = {}

local HANGAR = "fmf-hangar"
-- How far a hunter looks for its next target. Keep this BOUNDED: find_nearest_enemy
-- scans chunks within the radius and, when no enemy is near (e.g. a cleared area),
-- scans the whole circle -- a huge value here hangs the game. Because the search
-- re-centers on the hunter as it moves, this is enough to chain nest-to-nest.
local SEEK_RADIUS = 1500
local SPAWN_RADIUS = 16 -- search radius for a clear deploy spot near the hangar

-- token/entity name -> the ammo type and body color to apply on deploy. Each
-- hunter is loaded with a FULL STACK of this ammo per gun slot (computed at
-- runtime). Colors match each tier's recipe icon tint. Keep the keys in sync
-- with the TIERS table in prototypes/hunters.lua.
local HUNTERS = {
    ["fmf-hunter-light"]   = { ammo = "firearm-magazine",         color = { r = 0.35, g = 0.85, b = 0.35, a = 1 } },
    ["fmf-hunter-medium"]  = { ammo = "piercing-rounds-magazine", color = { r = 1.00, g = 0.80, b = 0.20, a = 1 } },
    ["fmf-hunter-heavy"]   = { ammo = "explosive-rocket",         color = { r = 0.90, g = 0.25, b = 0.20, a = 1 } },
    ["fmf-hunter-cannon"]  = { ammo = "explosive-cannon-shell",   color = { r = 0.70, g = 0.45, b = 0.20, a = 1 } },
    ["fmf-hunter-siege"]   = { ammo = "uranium-cannon-shell",     color = { r = 0.30, g = 0.65, b = 0.80, a = 1 } },
    ["fmf-hunter-nuclear"] = { ammo = "atomic-bomb",              color = { r = 0.70, g = 1.00, b = 0.20, a = 1 } },
}

-- Storage shape:
--   storage.hangars : table<uint, LuaEntity>  placed hangars
--   storage.hunters : table<uint, LuaEntity>  active deployed hunters

-- Friendly fire is off (so hunters don't self-damage) unless the runtime setting
-- re-enables it. Affects the whole player force.
function autobattler.apply_friendly_fire()
    local ff = not settings.global["fmf-disable-friendly-fire"].value
    local player_force = game and game.forces["player"]
    if player_force then
        player_force.friendly_fire = ff
    end
end

function autobattler.init()
    storage.hangars = storage.hangars or {}
    storage.hunters = storage.hunters or {}
    autobattler.apply_friendly_fire()
end

local function enable_auto_fire(hunter)
    hunter.vehicle_automatic_targeting_parameters = {
        auto_target_without_gunner = true,
        auto_target_with_gunner = true,
    }
end

-- Rebuild the hangar list from the world (used on configuration changes), and
-- make sure every tracked hunter has engine auto-fire on.
function autobattler.rescan()
    autobattler.init()
    storage.hangars = {}
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered({ name = HANGAR })) do
            storage.hangars[entity.unit_number] = entity
        end
    end
    for _, hunter in pairs(storage.hunters) do
        if hunter.valid then
            enable_auto_fire(hunter)
        end
    end
end

function autobattler.register_hangar(entity)
    if entity.name == HANGAR then
        storage.hangars[entity.unit_number] = entity
    end
end

-- Works for both hangars and hunters: clear whichever map holds this unit.
function autobattler.unregister_entity(entity)
    local un = entity.unit_number
    if un then
        storage.hangars[un] = nil
        storage.hunters[un] = nil
    end
end

-- Spawn one hunter of the given type next to its hangar, loaded with ammo.
local function deploy(hangar, hunter_name, spec)
    local surface = hangar.surface
    -- Apply the friendly-fire setting to the owning force (covers team forces).
    hangar.force.friendly_fire = settings.global["fmf-disable-friendly-fire"].value == false

    local origin = flib_position.add(hangar.position, { x = 0, y = 3 })
    local pos = surface.find_non_colliding_position(hunter_name, origin, SPAWN_RADIUS, 1)
    if not pos then
        return false
    end

    local hunter = surface.create_entity({
        name = hunter_name,
        position = pos,
        force = hangar.force,
        create_build_effect_smoke = true,
    })
    if not hunter then
        return false
    end

    hunter.color = spec.color -- recolors the spidertron's tintable body layers

    -- Load a full stack of ammo into every gun slot (slots == number of guns).
    local stack = prototypes.item[spec.ammo].stack_size
    local ammo_inv = hunter.get_inventory(defines.inventory.spider_ammo)
    if ammo_inv then
        ammo_inv.insert({ name = spec.ammo, count = stack * #ammo_inv })
    else
        hunter.insert({ name = spec.ammo, count = stack })
    end

    enable_auto_fire(hunter)

    storage.hunters[hunter.unit_number] = hunter
    rendering.draw_text({
        text = { "fmf.launched" },
        surface = surface,
        target = pos,
        color = { r = 1, g = 0.65, b = 0.25 },
        scale = 1.5,
        alignment = "center",
        time_to_live = 90,
    })
    return true
end

-- Deploy every finished hunter token sitting in a hangar's output.
local function service_hangar(hangar)
    local out = hangar.get_output_inventory()
    if not out then
        return
    end
    for _, stack in pairs(out.get_contents()) do
        local spec = HUNTERS[stack.name]
        if spec then
            for _ = 1, stack.count do
                deploy(hangar, stack.name, spec)
            end
            out.remove({ name = stack.name, count = stack.count, quality = stack.quality })
        end
    end
end

-- Point a hunter at the nearest enemy within SEEK_RADIUS. Re-running this each
-- interval means that once a target dies (or it arrives and clears the area), it
-- immediately retargets the next nearest enemy instead of idling. Enemy
-- "military targets" include spawners/worms, so hunters keep pushing into new
-- nests; the search re-centers on the hunter, so it chains across the map.
local function update_hunt(hunter)
    local enemy = hunter.surface.find_nearest_enemy({
        position = hunter.position,
        max_distance = SEEK_RADIUS,
        force = hunter.force,
    })
    if enemy and enemy.valid then
        hunter.autopilot_destination = enemy.position
    end
end

-- Called on a fixed interval from control.lua.
function autobattler.on_interval()
    for un, hangar in pairs(storage.hangars) do
        if hangar.valid then
            service_hangar(hangar)
        else
            storage.hangars[un] = nil
        end
    end
    for un, hunter in pairs(storage.hunters) do
        if hunter.valid then
            update_hunt(hunter)
        else
            storage.hunters[un] = nil
        end
    end
end

return autobattler
