-- Farm mode: decide what to do when farming
local FarmModeGeneric = {}

-- Farm action types
FarmModeGeneric.ACTION_TYPES = {
    ATTACK = "attack",
    MOVE_TO_LANE = "move_to_lane",
    MOVE_TO_CAMP = "move_to_camp",
    WAIT = "wait",
}

-- Get farm action for bot
function FarmModeGeneric:GetFarmAction(bot, gameTime)
    if not bot or bot:IsNull() then return { type = self.ACTION_TYPES.WAIT } end
    
    -- Check for nearby enemy creeps (lane farming)
    local laneCreeps = bot:GetNearbyLaneCreeps(800, true)
    if #laneCreeps > 0 then
        -- Find lowest HP creep to last hit
        local bestCreep = nil
        local lowestHP = math.huge
        for _, creep in ipairs(laneCreeps) do
            if creep:GetHealth() < lowestHP and creep:GetHealth() <= bot:GetAttackDamage() * 1.5 then
                lowestHP = creep:GetHealth()
                bestCreep = creep
            end
        end
        if bestCreep then
            return { type = self.ACTION_TYPES.ATTACK, target = bestCreep }
        end
        
        -- Attack any creep if no last hit available
        return { type = self.ACTION_TYPES.ATTACK, target = laneCreeps[1] }
    end
    
    -- Check for neutral camps
    local neutrals = bot:GetNearbyNeutralCreeps(800)
    if #neutrals > 0 then
        -- Prioritize ancients > large > medium > small
        local bestCamp = nil
        local bestScore = 0
        for _, creep in ipairs(neutrals) do
            local score = 0
            local name = creep:GetUnitName()
            if name:find("ancient") then score = 100
            elseif name:find("large") then score = 80
            elseif name:find("medium") then score = 60
            elseif name:find("small") then score = 40 end
            
            if score > bestScore then
                bestScore = score
                bestCamp = creep
            end
        end
        if bestCamp then
            return { type = self.ACTION_TYPES.ATTACK, target = bestCamp }
        end
    end
    
    -- No farm targets - move to assigned lane
    local lane = bot:GetAssignedLane() or "safe"
    local laneFront = GetLaneFrontLocation(GetTeam(), lane, 0)
    if laneFront then
        return { type = self.ACTION_TYPES.MOVE_TO_LANE, target = laneFront }
    end
    
    return { type = self.ACTION_TYPES.WAIT }
end

-- Engine hook (optional - can be called from init.lua)
function GetFarmAction(bot, gameTime)
    return FarmModeGeneric:GetFarmAction(bot, gameTime)
end

return FarmModeGeneric