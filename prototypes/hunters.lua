-- Hunter chassis (spidertron clones), their hidden deployment tokens, and the
-- recipes that build them. Two-axis design: the VEHICLE ingredient sets the
-- chassis (durability), the AMMO ingredient sets the weapon (loaded into the
-- deployed hunter by scripts/autobattler.lua). All hunters are spider-class
-- because only SpiderVehicles can autopilot + auto-fire with no driver.
--
-- Gun count and a resistance multiplier per tier come from STARTUP mod settings
-- (see settings.lua). `gun_pool` lists candidate guns; the gun-count setting
-- takes the first N. The resistance setting scales each tier's tuned profile.
--
-- Entity name == token item name == recipe name for each tier, so the runtime
-- mapping (token -> entity) is a trivial string match. To add a hunter, add one
-- entry to TIERS below, a settings.lua entry, and a matching ammo loadout in
-- scripts/autobattler.lua.

local flib_data_util = require("__flib__.data-util")

-- Clone the real spidertron so every leg/graphics/energy field stays valid.
-- It inherits energy_source = void, so it walks with no equipment grid power.
local function clone_chassis(name)
    local h = flib_data_util.copy_prototype(data.raw["spider-vehicle"]["spidertron"], name)
    h.minable = nil -- hunters can't be picked up
    return h
end

-- Tinted spidertron icon, so the recipes read as distinct in the UI.
local function tinted_icon(tint)
    local icons = flib_data_util.create_icons(data.raw["item-with-entity-data"]["spidertron"])
    if icons then
        for _, layer in pairs(icons) do
            layer.tint = tint
        end
    end
    return icons
end

-- Scale a resistance profile's percents/decreases by `mult` (percent capped 100).
local function scale_resistances(res, mult)
    if not res or mult == 1 then return res end -- res may be false/nil
    local out = {}
    for _, r in pairs(res) do
        out[#out + 1] = {
            type = r.type,
            decrease = (r.decrease or 0) * mult,
            percent = math.min(100, (r.percent or 0) * mult),
        }
    end
    return out
end

local LAUNCHERS = {
    "spidertron-rocket-launcher-1", "spidertron-rocket-launcher-2",
    "spidertron-rocket-launcher-3", "spidertron-rocket-launcher-4",
}
local function repeat_gun(name) return { name, name, name, name } end

-- Per-tier config.
--   key         : settings/short name (fmf-<key>-guns, fmf-<key>-resistance)
--   gun_pool    : candidate guns; the gun-count setting takes the first N
--   resistances : array to set; false to strip all; omit to keep spidertron's defaults
--   tint        : recipe/token icon tint
--   craft       : recipe craft time in seconds (default 5)
--   ingredients : recipe ingredients {name, amount}; first is the chassis "vehicle"
local TIERS = {
    {
        id = "fmf-hunter-light", key = "light", hp = 150,
        gun_pool = repeat_gun("vehicle-machine-gun"), resistances = false,
        tint = { r = 0.60, g = 1.00, b = 0.60, a = 1 },
        ingredients = { { "car", 1 }, { "firearm-magazine", 10 } },
    },
    {
        id = "fmf-hunter-medium", key = "medium", hp = 500,
        gun_pool = repeat_gun("tank-machine-gun"),
        resistances = {
            { type = "physical",  decrease = 5, percent = 30 },
            { type = "explosion", decrease = 0, percent = 30 },
        },
        tint = { r = 1.00, g = 0.90, b = 0.40, a = 1 },
        ingredients = { { "tank", 1 }, { "piercing-rounds-magazine", 20 } },
    },
    {
        id = "fmf-hunter-heavy", key = "heavy", hp = 1200,
        gun_pool = LAUNCHERS, -- keeps default resistances
        tint = { r = 1.00, g = 0.50, b = 0.40, a = 1 },
        ingredients = { { "tank", 1 }, { "explosive-rocket", 20 } },
    },
    {
        id = "fmf-hunter-cannon", key = "cannon", hp = 700,
        gun_pool = repeat_gun("tank-cannon"),
        resistances = {
            { type = "physical",  decrease = 8, percent = 35 },
            { type = "explosion", decrease = 5, percent = 40 },
        },
        tint = { r = 0.70, g = 0.45, b = 0.20, a = 1 },
        craft = 10,
        ingredients = { { "tank", 1 }, { "explosive-cannon-shell", 20 } },
    },
    {
        id = "fmf-hunter-siege", key = "siege", hp = 1500,
        gun_pool = repeat_gun("tank-cannon"),
        resistances = {
            { type = "physical",  decrease = 15, percent = 50 },
            { type = "explosion", decrease = 10, percent = 50 },
            { type = "acid",      decrease = 0,  percent = 70 },
        },
        tint = { r = 0.30, g = 0.65, b = 0.80, a = 1 },
        craft = 12,
        ingredients = { { "spidertron", 1 }, { "uranium-cannon-shell", 20 } },
    },
    {
        id = "fmf-hunter-nuclear", key = "nuclear", hp = 2000,
        gun_pool = LAUNCHERS,
        -- 100% explosion resistance = immune to nuclear blasts (the whole nuke
        -- chain deals only "explosion" damage). Note: a resistance multiplier
        -- below 1.0 lowers this and the hunter can start nuking itself.
        resistances = {
            { type = "explosion", decrease = 1000, percent = 100 },
            { type = "physical",  decrease = 15,   percent = 60 },
            { type = "acid",      decrease = 0,    percent = 70 },
            { type = "fire",      decrease = 15,   percent = 70 },
        },
        tint = { r = 0.70, g = 1.00, b = 0.20, a = 1 },
        craft = 20,
        ingredients = { { "spidertron", 1 }, { "atomic-bomb", 8 } },
    },
}

local prototypes = {}

for _, t in pairs(TIERS) do
    local gun_count = settings.startup["fmf-" .. t.key .. "-guns"].value
    local res_mult = settings.startup["fmf-" .. t.key .. "-resistance"].value

    local chassis = clone_chassis(t.id)
    chassis.max_health = t.hp

    local guns = {}
    for i = 1, gun_count do
        guns[i] = t.gun_pool[i] or t.gun_pool[#t.gun_pool]
    end
    chassis.guns = guns

    if t.resistances == false then
        chassis.resistances = nil
    elseif t.resistances then
        chassis.resistances = scale_resistances(t.resistances, res_mult)
    else
        chassis.resistances = scale_resistances(chassis.resistances, res_mult)
    end
    prototypes[#prototypes + 1] = chassis

    prototypes[#prototypes + 1] = {
        type = "item",
        name = t.id,
        icons = tinted_icon(t.tint),
        hidden = true,
        stack_size = 10,
        flags = { "hide-from-bonus-gui" },
    }

    local ingredients = {}
    for _, ing in pairs(t.ingredients) do
        ingredients[#ingredients + 1] = { type = "item", name = ing[1], amount = ing[2] }
    end
    prototypes[#prototypes + 1] = {
        type = "recipe",
        name = t.id,
        category = "fmf-hunter",
        enabled = true,
        energy_required = t.craft or 5,
        ingredients = ingredients,
        results = { { type = "item", name = t.id, amount = 1 } },
    }
end

data:extend(prototypes)
