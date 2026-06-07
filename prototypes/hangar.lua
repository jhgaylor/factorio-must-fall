-- The Vehicle Hangar: an assembling-machine that crafts "hunter" recipes
-- (vehicle + ammo -> a hidden deployment token). scripts/autobattler.lua watches
-- its output and deploys the matching spidertron-class hunter.
--
-- MVP: cloned from assembling-machine-2 so all graphics/animation stay valid,
-- then switched to its own crafting category and made power-free (void energy)
-- so it works anywhere. Custom art comes later.

local flib_data_util = require("__flib__.data-util")

local HANGAR = "fmf-hangar"

-- A crafting category only the hangar provides, so hunter recipes appear only here.
data:extend({ { type = "recipe-category", name = "fmf-hunter" } })

local entity = flib_data_util.copy_prototype(data.raw["assembling-machine"]["assembling-machine-2"], HANGAR)
entity.crafting_categories = { "fmf-hunter" }
entity.crafting_speed = 1
-- Requires electricity: keep the cloned assembling-machine-2 electric source
-- (and its pollution), but draw serious power for a war factory.
entity.energy_usage = "1MW"
entity.max_health = 500
entity.next_upgrade = nil        -- don't let upgrade planner turn it into AM-3
entity.fast_replaceable_group = nil

local item = flib_data_util.copy_prototype(data.raw["item"]["assembling-machine-2"], HANGAR)
item.place_result = HANGAR
item.order = "z[fmf]-a[hangar]"

-- Tint the (assembler placeholder) icon orange so it stands out until it gets art.
local TINT = { r = 1, g = 0.55, b = 0.15, a = 1 }
local icons = flib_data_util.create_icons(item)
if icons then
    for _, layer in pairs(icons) do
        layer.tint = TINT
    end
    item.icons = icons
    item.icon = nil
    item.icon_size = nil
end

local recipe = {
    type = "recipe",
    name = HANGAR,
    enabled = true, -- available from the start for now; gate behind a tech later
    energy_required = 2,
    ingredients = {
        { type = "item", name = "steel-plate",      amount = 20 },
        { type = "item", name = "iron-gear-wheel",  amount = 20 },
        { type = "item", name = "advanced-circuit", amount = 10 },
    },
    results = {
        { type = "item", name = HANGAR, amount = 1 },
    },
}

data:extend({ entity, item, recipe })
