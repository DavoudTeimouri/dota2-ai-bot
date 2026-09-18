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
    -- Radiant side
    {x = -2100, y = 1900, name = "Top Bounty"},
    {x = 1900, y = -2100, name = "Bot Bounty"},
    {x = -2200, y = -2200, name = "Top River"},
    {x = 2200, y = 2200, name = "Bot River"},
    -- Power runes (mirrored for Dire)
    {x = 2100, y = -1900, name = "Top Bounty (Dire)"},
    {x = -1900, y = 2100, name = "Bot Bounty (Dire)"},
}

function Rune:GetNearestRuneSpot(bot)
    local botPos = bot:GetAbsOrigin()
    local bestSpot = nil
    local bestDist = 99999
    
    for _, spot in ipairs(self.RuneSpots) do
        local dist = (botPos - Vector(spot.x, spot.y, 0)):Length2D()
        if dist < bestDist then
            bestDist = dist
            bestSpot = spot
        end
    end
    return bestSpot, bestDist
end

function Rune:GetRuneAtSpot(spot)
    -- Check what rune is at this spot
    -- This would need Dota 2 API access to actual rune entities
    return nil
end

function Rune:ShouldGetRune(bot, gameTime)
    local role = self:GetBotRole(bot)
    
    -- Mid laner prioritizes power runes
    if role == "mid" then
        local minute = math.floor(gameTime / 60)
        if minute % 2 == 0 and (gameTime % 60) < 30 then -- Even minutes, first 30 seconds
            return true
        end
    end
    
    -- Everyone can grab bounty runes
    if gameTime % 300 < 10 then -- First 10 seconds of 5-minute cycle
        return true
    end
    
    return false
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
    if not self:ShouldGetRune(bot, gameTime) then return end
    
    local spot, dist = self:GetNearestRuneSpot(bot)
    if spot and dist < 2000 then
        bot:Action_MoveToLocation(Vector(spot.x, spot.y, 0))
    end
end

return Rune