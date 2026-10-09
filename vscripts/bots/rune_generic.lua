-- Rune generic
-- Runes are a bot MODE (mode_rune_generic.lua) in Dota 2's system, not a
-- Think() hook. This module only exposes a reset for init.lua's init block.
local RuneGeneric = {}

function RuneGeneric:Reset()
    -- No state to reset: rune pickup is handled by the mode script.
end

function RuneGeneric:Think(hero)
    -- Intentionally empty. See note above.
end

return RuneGeneric