-- AetherWeaver bot entry point.
--
-- Dota 2 loads each bot script into its OWN Lua scope and calls fixed global
-- hooks, chosen by FILENAME. The real hooks and the file that owns each:
--
--   hero_selection.lua                Think()
--   team_desires.lua                  TeamThink(), UpdatePushLaneDesires(), ...
--   mode_<name>_generic.lua           GetDesire(), OnStart(), OnEnd(), Think()
--   item_purchase_generic.lua         ItemPurchaseThink()
--   ability_item_usage_generic.lua    AbilityLevelUpThink(), AbilityUsageThink(),
--                                     ItemUsageThink(), BuybackUsageThink(),
--                                     CourierUsageThink()
--   bot_generic.lua                   MinionThink(hMinionUnit)   <-- only this one
--
-- bot_generic.lua therefore does NOT own a per-frame Think(). The previous
-- version defined one here plus copies of every ability/item hook; the engine
-- never called them (wrong file scope), so bots never moved, never bought and
-- never cast. They now live in the files the engine actually reads.

local AetherWeaver = require("init")

-- Summoned/minion AI (Treants, Necronomicon, ...). The one hook the engine
-- really does call in this file.
function MinionThink(hMinionUnit)
    -- ponytail: minion AI is unimplemented. Wire it when summoned units need
    -- commands; hero-level decisions already run through the ability/item
    -- hooks in ability_item_usage_generic.lua.
end

return AetherWeaver