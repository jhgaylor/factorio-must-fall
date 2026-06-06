-- data-updates.lua — the DATA-UPDATES stage.
-- Runs after every mod's data.lua. Use this to modify prototypes that other
-- mods (or base) defined, when you need their data.lua to have run first.
-- For changes that must win against everything else, use data-final-fixes.lua.

-- Example: tweak an existing prototype only if it exists.
-- if data.raw["lab"] and data.raw["lab"]["lab"] then
--     data.raw["lab"]["lab"].researching_speed = 2
-- end
