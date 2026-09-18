-- Rune System for AetherWeaver

local Rune = {}

Rune.RuneTypes = {
    RUNE_BOUNTY = 0,
    RUNE_DOUBLEDAMAGE = 1,
    RUNE_HASTE = 2,
    RUNE_ILLUSION = 3,
    RUNE_INVISIBILITY = 4,
    RUNE_REGENERATION = 5,
    RUNE_ARCANE = 6,
    RUNE_WATER = 7
}

Rune.RuneSpots = {
    -- Bounty runes (4 corners)
    {x = -2100, y = 1900, name = "Top Bounty", type = "bounty"},
    {x = 1900, y = -2100, name = "Bot Bounty", type = "bounty"},
    {x = -1900, y = 2100, name = "Top Bounty (Dire)", type = "bounty"},
    {x = 2100, y = -1900, name = "Bot Bounty (Dire)", type = "bounty"},
    -- Power runes (river)
    {x = -2200, y = -2200, name = "Top Power", type = "power"},
    {x = 2200, y = 2200, name = "Bot Power", type = "power"},
    -- Wisdom rune (Roshan pit area)
    {x = -2464, y = 1824, name = "Roshan Wisdom", type = "wisdom"},
}

Rune.assignedBots = {}  -- Track which bot is going for which rune

function Rune:GetNearestRuneSpot(bot, runeType)
    local botPos = bot:GetAbsOrigin()
    local bestSpot = nil
    local bestDist = 99999
    
    for _, spot in ipairs(self.RuneSpots) do
        if not runeType or spot.type == runeType then
            local key = spot.name
            -- Check if another bot is already assigned
            if not self.assignedBots[key] or self.assignedBots[key] == bot then
                local dist = (botPos - Vector(spot.x, spot.y, 0)):Length2D()
                if dist < bestDist then
                    bestDist = dist
                    bestSpot = spot
                end
            end
        end
    end
    return bestSpot, bestDist
end

function Rune:GetRuneAtSpot(spot)
    -- Check what rune is at this spot
    -- This would need Dota 2 API access to actual rune entities
    return nil
end

function Rune:AssignRune(bot, spotName)
    if spotName then
        self.assignedBots[spotName] = bot
    end
end

function Rune:UnassignRune(bot)
    for spotName, assignedBot in pairs(self.assignedBots) do
        if assignedBot == bot then
            self.assignedBots[spotName] = nil
        end
    end
end

function Rune:ShouldGetRune(bot, gameTime)
    local role = self:GetBotRole(bot)
    
    -- Mid laner prioritizes power runes (even minutes)
    if role == "mid" then
        local minute = math.floor(gameTime / 60)
        if minute % 2 == 0 and (gameTime % 60) < 30 then
            return true, "power"
        end
    end
    
    -- Bounty runes every 5 minutes - distribute among team
    if gameTime % 300 < 15 then
        return true, "bounty"
    end
    
    -- Wisdom rune near Roshan after 20 min
    if gameTime > 1200 then
        local roshanAlive = self:IsRoshanAlive()
        if not roshanAlive then
            return true, "wisdom"
        end
    end
    
    return false, nil
end

function Rune:IsRoshanAlive()
    local roshan = FindUnitsInRadius(GetTeam(), Vector(-2464, 1824, 0), nil, 500, 
        DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false)
    return #roshan > 0
end

function Rune:GetBotRole(bot)
    local heroName = bot:GetUnitName()
    local carryHeroes = {"antimage", "juggernaut", "phantom_assassin", "spectre", "medusa"}
    local midHeroes = {"invoker", "storm_spirit", "templar_assassin", "puck", "ember_spirit"}
    local offlaneHeroes = {"centaur", "tidehunter", "dragon_knight", "axe", "mars"}
    
    for _, h in ipairs(carryHeroes) do if heroName:find(h) then return "carry" end end
    for _, h in ipairs(midHeroes) do if heroName:find(h) then return "mid" end end
    for _, h in ipairs(offlaneHeroes) do if heroName:find(h) then return "offlane" end end
    return "support"
end

function Rune:Think(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    local gameTime = DotaTime()
    local shouldGet, runeType = self:ShouldGetRune(bot, gameTime)
    if not shouldGet then 
        self:UnassignRune(bot)
        return 
    end
    
    local spot, dist = self:GetNearestRuneSpot(bot, runeType)
    if spot and dist < 3000 then
        self:AssignRune(bot, spot.name)
        bot:Action_MoveToLocation(Vector(spot.x, spot.y, 0))
    else
        self:UnassignRune(bot)
    end
end

return Rune