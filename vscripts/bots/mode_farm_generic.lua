-- Farm mode: decide what to do when farming
return {
    -- Called each tick to decide farm action
    GetFarmAction = function(bot, gameTime)
        -- Use existing farming intelligence
        local target = GameIntelligence.Farming:GetBestFarmTarget(bot, gameTime)
        if target then
            return { type = "attack", target = target }
        end
        -- If no target, maybe move to lane
        return { type = "move_to_lane", lane = bot:GetAssignedLane() or "safe" }
    end
}