-- Hunter chassis (spidertron clones), their hidden deployment tokens, and the
-- recipes that build them. Two-axis design: the VEHICLE ingredient sets the
-- chassis (durability), the AMMO ingredient sets the weapon (loaded into the
-- deployed hunter by scripts/autobattler.lua). All hunters are spider-class
-- because only SpiderVehicles can autopilot + auto-fire with no driver.
--
-- Entity name == token item name == recipe name for each tier, so the runtime
-- mapping (token -> entity) is a trivial string match. To add a hunter, add one
-- entry to TIERS below AND a matching ammo loadout in scripts/autobattler.lua.

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

-- Per-tier config.
--   guns        : list of gun item names; omit to keep the spidertron's 4 rocket launchers.
--   resistances : array to set; false to strip all; omit to keep spidertron's defaults.
--   tint        : recipe/token icon tint.
--   craft       : recipe craft time in seconds (default 5).
--   ingredients : recipe ingredients {name, amount}; first is the chassis "vehicle".
local TIERS = {
    {
        id = "fmf-hunter-light", hp = 150,
        guns = { "vehicle-machine-gun" }, resistances = false,
        tint = { r = 0.60, g = 1.00, b = 0.60, a = 1 },
        ingredients = { { "car", 1 }, { "firearm-magazine", 10 } },
    },
    {
        id = "fmf-hunter-medium", hp = 500,
        guns = { "tank-machine-gun", "tank-machine-gun" },
        resistances = {
            { type = "physical",  decrease = 5, percent = 30 },
            { type = "explosion", decrease = 0, percent = 30 },
        },
        tint = { r = 1.00, g = 0.90, b = 0.40, a = 1 },
        ingredients = { { "tank", 1 }, { "piercing-rounds-magazine", 20 } },
    },
    {
        id = "fmf-hunter-heavy", hp = 1200,
        -- keeps the spidertron's 4 rocket launchers + default resistances
        tint = { r = 1.00, g = 0.50, b = 0.40, a = 1 },
        ingredients = { { "tank", 1 }, { "explosive-rocket", 20 } },
    },
    {
        id = "fmf-hunter-cannon", hp = 700,
        guns = { "tank-cannon", "tank-cannon" },
        resistances = {
            { type = "physical",  decrease = 8, percent = 35 },
            { type = "explosion", decrease = 5, percent = 40 },
        },
        tint = { r = 0.70, g = 0.45, b = 0.20, a = 1 },
        craft = 10,
        ingredients = { { "tank", 1 }, { "explosive-cannon-shell", 20 } },
    },
    {
        id = "fmf-hunter-siege", hp = 1500,
        guns = { "tank-cannon", "tank-cannon", "tank-cannon" },
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
        id = "fmf-hunter-nuclear", hp = 2000,
        -- keeps the 4 rocket launchers (rocket category fits atomic-bomb).
        -- 100% explosion resistance = immune to nuclear blasts (the whole nuke
        -- chain deals only "explosion" damage), incl. its own and other nukes.
        -- Still dies to biters (physical/acid).
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
    local chassis = clone_chassis(t.id)
    chassis.max_health = t.hp
    if t.guns then chassis.guns = t.guns end
    if t.resistances == false then
        chassis.resistances = nil
    elseif t.resistances then
        chassis.resistances = t.resistances
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
