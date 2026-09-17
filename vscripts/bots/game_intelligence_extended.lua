-- Game Intelligence Extended Features for AetherWeaver
-- Additional suggestions from Gaming Specialist

local GameIntelligenceExtended = {}

-- ============================================================================
-- 1. IMPROVE LAST-HIT: PREDICT CREEP EQUILIBRIUM DYNAMICALLY
-- ============================================================================
function GameIntelligenceExtended:PredictCreepEquilibrium(bot, lane)
    -- Predict where the creep wave will be in the next few seconds
    -- Based on current creep positions, hero damage, and tower damage
    -- Returns the predicted equilibrium point (distance from tower)
    -- This is a simplified version
    local laneCreeps = bot:GetNearbyLaneCreeps(1500, true) -- enemy creeps
    local alliedCreeps = bot:GetNearbyLaneCreeps(1500, false) -- allied creeps
    
    if #laneCreeps == 0 and #alliedCreeps == 0 then
        return nil
    end
    
    -- Calculate average position of enemy and allied creeps
    local enemyAvgPos = Vector(0,0)
    local alliedAvgPos = Vector(0,0)
    for _, creep in ipairs(laneCreeps) do
        enemyAvgPos = enemyAvgPos + creep:GetAbsOrigin()
    end
    if #laneCreeps > 0 then
        enemyAvgPos = enemyAvgPos / #laneCreeps
    end
    for _, creep in ipairs(alliedCreeps) do
        alliedAvgPos = alliedAvgPos + creep:GetAbsOrigin()
    end
    if #alliedCreeps > 0 then
        alliedAvgPos = alliedAvgPos / #alliedCreeps
    end
    
    -- Predict where the wave will meet (simplified: midpoint)
    local predictedPos = (enemyAvgPos + alliedAvgPos) / 2
    -- Convert to distance from tower (we would need the tower position)
    -- For now, return the predicted position
    return predictedPos
end

-- ============================================================================
-- 2. ADD LANE PRIORITY: HERO MATCHUP + MISSING ENEMIES
-- ============================================================================
function GameIntelligenceExtended:GetLanePriority(bot, lane, enemyHeroInLane)
    local priority = 0
    local heroName = bot:GetUnitName()
    local enemyName = enemyHeroInLane and enemyHeroInLane:GetUnitName() or nil
    
    -- Base priority from role
    local rolePriority = {carry = 3, mid = 2, offlane = 1, support = 0}
    local role = bot:GetRole() -- We assume bot has GetRole method
    priority = priority + (rolePriority[role] or 0) * 10
    
    -- Hero matchup advantage
    if enemyName then
        local matchupScore = self:GetHeroMatchupScore(heroName, enemyName)
        priority = priority + matchupScore
    end
    
    -- Missing enemies in lane increase priority (safe to farm)
    if not enemyHeroInLane then
        priority = priority + 15 -- safer to farm if enemy missing
    end
    
    -- Enemy presence decreases priority
    if enemyHeroInLane then
        priority = priority - 10
    end
    
    return priority
end

function GameIntelligenceExtended:GetHeroMatchupScore(ourHero, enemyHero)
    -- Simplified: return a score based on hardcoded matchups
    -- In reality, this would be a large table
    local matchups = {
        ["npc_dota_hero_antimage"] = {
            ["npc_dota_hero_spectre"] = 10, -- good against spectre
            ["npc_dota_hero_medusa"] = 5,
            ["npc_dota_hero_juggernaut"] = 0,
        },
        ["npc_dota_hero_invoker"] = {
            ["npc_dota_hero_puck"] = -5, -- bad vs puck
            ["npc_dota_hero_storm_spirit"] = 0,
        },
        -- ... more matchups
    }
    local ourMatchups = matchups[ourHero]
    if ourMatchups and ourMatchups[enemyHero] then
        return ourMatchups[enemyHero]
    end
    return 0
end

-- ============================================================================
-- 3. ADAPTIVE ITEMS: COUNTER-PICK BASED ON ENEMY COMP
-- ============================================================================
GameIntelligenceExtended.ItemBuilds = {
    -- Base builds per role
    carry = {
        early = {"item_tango", "item_flask", "item_stout_shield", "item_quelling_blade", "item_branches", "item_branches", "item_branches", "item_boots"},
        mid = {"item_wraith_band", "item_power_treads", "item_yasha", "item_blink"},
        late = {"item_butterfly", "item_abyssal_blade", "item_satanic", "item_manta", "item_heart", "item_assault"},
    },
    mid = {
        early = {"item_tango", "item_flask", "item_mantle", "item_branches", "item_branches", "item_branches", "item_boots"},
        mid = {"item_wraith_band", "item_power_treads", "item_oblivion_staff", "item_ultimate_orb"},
        late = {"item_sheepstick", "item_black_king_bar", "item_shivas_guard", "item_bloodstone", "item_overwhelming_blink"},
    },
    -- ... other roles
}

-- Counter-pick adjustments
GameIntelligenceExtended.ItemCounters = {
    -- If enemy has lots of magic damage, add more magic resistance
    magic_damage = {"item_black_king_bar", "item_pipe", "item_hood_of_defiance", "item_crimson_guard"},
    -- If enemy has lots of physical damage, add more armor
    physical_damage = {"item_assault", "item_heart", "item_blade_mail", "item_solar_crest"},
    -- If enemy has lots of disables, add more dispel
    disables = {"item_lotus_orb", "item_sphere", "item_abyssal_blade", "item_wind_waker"},
    -- If enemy has lots of healing, add more anti-heal
    healing = {"item_grimoire", "item_solar_crest", "item_ancient_janggo", "item_medallion_of_courage"},
}

function GameIntelligenceExtended:GetAdaptiveItemBuild(bot, enemyTeam)
    local role = bot:GetRole()
    local build = deepcopy(self.ItemBuilds[role].early) -- start with early
    
    -- Analyze enemy team composition
    local enemyMagic = 0
    local enemyPhysical = 0
    local enemyDisables = 0
    local enemyHealing = 0
    
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= bot:GetTeam() then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                local heroName = hero:GetUnitName()
                -- Simple classification (would be more detailed in reality)
                if heroName:find("lich") or heroName:find("lion") or heroName:find("shadow_shaman") or heroName:find("enigma") then
                    enemyMagic = enemyMagic + 1
                end
                if heroName:find("juggernaut") or heroName:find("phantom_assassin") or heroName:find("riki") then
                    enemyPhysical = enemyPhysical + 1
                end
                if heroName:find("bane") or heroName:find("lion") or heroName:find("shadow_shaman") then
                    enemyDisables = enemyDisables + 1
                end
                if heroName:find("abaddon") or heroName:find("oracle") or heroName:find("dazzle") then
                    enemyHealing = enemyHealing + 1
                end
            end
        end
    end
    
    -- Adjust build based on enemy composition
    if enemyMagic > 2 then
        table.insert(build, self.ItemCounters.magic_damage[1]) -- BKB
    end
    if enemyPhysical > 2 then
        table.insert(build, self.ItemCounters.physical_damage[1]) -- Assault
    end
    if enemyDisables > 1 then
        table.insert(build, self.ItemCounters.disables[1]) -- Lotus
    end
    if enemyHealing > 0 then
        table.insert(build, self.ItemCounters.healing[1]) -- Grimoire
    end
    
    return build
end

-- ============================================================================
-- 4. TEAMFIGHT POSITIONING: THREAT EVAL + SAFE RETREAT ZONES
-- ============================================================================
function GameIntelligenceExtended:EvaluateTeamfightThreat(bot, enemies, allies)
    local threatScore = 0
    local safeZones = {}
    
    -- Evaluate enemy threats
    for _, enemy in ipairs(enemies) do
        if enemy:IsHero() and enemy:IsAlive() and not enemy:IsIllusion() then
            local threat = 0
            -- Check for disables
            if self:HeroHasStrongDisable(enemy) then
                threat = threat + 30
            end
            -- Check for burst damage
            if self:HeroHasHighBurst(enemy) then
                threat = threat + 25
            end
            -- Check for ult readiness
            if enemy:IsUltimateReady() then
                threat = threat + 20
            end
            -- Check for item advantages (BKB, etc.)
            if enemy:HasItem("item_black_king_bar") then
                threat = threat + 15
            end
            threatScore = threatScore + threat
        end
    end
    
    -- Calculate safe zones (behind allies, near towers, etc.)
    safeZones = self:GetSafeRetreatZones(bot, allies)
    
    return threatScore, safeZones
end

function GameIntelligenceExtended:GetSafeRetreatZones(bot, allies)
    local zones = {}
    local tower = bot:GetNearestTower(1200, true) -- allied tower
    if tower and not tower:IsNull() then
        table.insert(zones, {pos = tower:GetAbsOrigin(), radius = 800, type = "tower"})
    end
    -- Add ally positions
    for _, ally in ipairs(allies) do
        if ally:IsHero() and ally:IsAlive() and not ally:IsNull() then
            table.insert(zones, {pos = ally:GetAbsOrigin(), radius = 600, type = "ally"})
        end
    end
    return zones
end

function GameIntelligenceExtended:HeroHasStrongDisable(enemy)
    local name = enemy:GetUnitName()
    return name:find("bane") or name:find("lion") or name:find("shadow_shaman") or name:find("faceless_void") or name:find("disruptor")
end

function GameIntelligenceExtended:HeroHasHighBurst(enemy)
    local name = enemy:GetUnitName()
    return name:find("invoker") or name:find("lina") or name:find("zeus") or name:find("lion") or name:find("agrim")
end

-- ============================================================================
-- 5. COMMUNICATION PINGS: MISSING DANGER ASSIST REQUESTS TIMING
-- ============================================================================
function GameIntelligenceExtended:ShouldPingMissingEnemy(bot, gameTime)
    -- Ping if enemy has been missing for a while and we are in danger
    local missingTime = bot:GetMissingEnemyTime() -- we would need to track this
    if missingTime > 10 and gameTime > 60 then -- missing for 10 seconds after 1 min
        return true
    end
    return false
end

function GameIntelligenceExtended:ShouldRequestAssist(bot, gameTime)
    -- Request assist if we are being ganked or in a tough lane
    local enemyCount = bot:GetNearbyEnemyHeroes(800):length()
    local allyCount = bot:GetNearbyAlliedHeroes(800):length()
    if enemyCount > allyCount + 1 and bot:GetHealth() / bot:GetMaxHealth() < 0.5 then
        return true
    end
    return false
end

function GameIntelligenceExtended:GetPingMessageForMissingEnemy(enemyName)
    local messages = {
        "Enemy %s missing! Be careful!",
        "Missing %s - possible gank incoming!",
        "%s mia - check your surroundings!",
        "Watch out for %s - they could be anywhere!",
    }
    return messages[math.random(#messages)]:format(enemyName)
end

function GameIntelligenceExtended:GetAssistRequestMessage()
    local messages = {
        "I need help!",
        "Can someone assist me?",
        "I'm in trouble - please come!",
        "Assist needed!",
    }
    return messages[math.random(#messages)]
end

-- ============================================================================
-- 6. LEARN FROM REPLAYS: OFFLINE RL TWEAK WEIGHTS
-- ============================================================================
-- Note: This would require an external system to process replays and adjust weights.
-- We will provide a placeholder function that could be called by an external process.
function GameIntelligenceExtended:LearnFromReplay(replayData)
    -- This function would analyze replay data and adjust internal weights
    -- For example, adjust hero pick weights, item build preferences, etc.
    -- Since we cannot implement a full RL system here, we leave it as a placeholder.
    print("[GameIntelligenceExtended] Learning from replay (placeholder)")
    -- In reality, we would update tables like heroDatabase, ItemBuilds, etc.
end

-- ============================================================================
-- 7. HERO MICRO: BLINK DODGE SKILLSHOT AVOIDANCE
-- ============================================================================
function GameIntelligenceExtended:ShouldBlinkDodge(bot, incomingProjectile)
    -- Check if bot has a blink ability and if the projectile is a skillshot worth dodging
    if not bot:HasAbility("item_blink") and not bot:HasAbility("antimage_blink") then
        return false
    end
    
    -- Check if the projectile is likely to hit us
    local timeToImpact = self:CalculateProjectileTimeToImpact(bot, incomingProjectile)
    if timeToImpact > 0 and timeToImpact < 1.5 then -- within 1.5 seconds
        -- Check if the projectile is a stun or high damage
        if self:IsProjectileDangerous(incomingProjectile) then
            return true
        end
    end
    return false
end

function GameIntelligenceExtended:CalculateProjectileTimeToImpact(bot, projectile)
    -- Simplified: assume projectile travels at 1000 units per second
    local distance = (bot:GetAbsOrigin() - projectile:GetAbsOrigin()):Length2D()
    return distance / 1000.0
end

function GameIntelligenceExtended:IsProjectileDangerous(projectile)
    -- Check if the projectile is a stun, nuke, or high damage ability
    local name = projectile:GetAbilityName()
    return name:find("stun") or name:find("bolt") or name:find("blast") or name:find("spear") or name:find("arrow")
end

function GameIntelligenceExtended:GetBlinkDodgePosition(bot, incomingProjectile)
    -- Blink perpendicular to the projectile path
    local botPos = bot:GetAbsOrigin()
    local projPos = projectile:GetAbsOrigin()
    local toBot = (botPos - projPos):Normalized()
    -- Perpendicular vector
    local perp = Vector(-toBot.y, toBot.x, 0)
    -- Blink 300 units in perpendicular direction
    return botPos + perp * 300
end

-- ============================================================================
-- 8. ECONOMY SHARING: COURIER WARDS SUPPORT ITEMS WHEN AHEAD
-- ============================================================================
function GameIntelligenceExtended:ShouldShareEconomy(bot)
    -- Check if we are ahead as a support
    if bot:GetRole() ~= "support" then return false end
    local ourNetWorth = bot:GetNetWorth()
    local enemyCarryNetWorth = self:GetEnemyCarryNetWorth()
    return ourNetWorth > enemyCarryNetWorth * 1.2 -- we are ahead by 20%
end

function GameIntelligenceExtended:GetEnemyCarryNetWorth()
    -- Find the enemy carry and get their net worth
    local maxNetWorth = 0
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= DOTA_TEAM_GOODGUYS then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                local role = self:GetHeroRole(hero:GetUnitName())
                if role == "carry" then
                    local netWorth = hero:GetNetWorth()
                    if netWorth > maxNetWorth then
                        maxNetWorth = netWorth
                    end
                end
            end
        end
    end
    return maxNetWorth
end

function GameIntelligenceExtended:GetHeroRole(heroName)
    -- Simplified role detection
    if heroName:find("antimage") or heroName:find("juggernaut") or heroName:find("phantom_assassin") or heroName:find("spectre") or heroName:find("medusa") then
        return "carry"
    elseif heroName:find("invoker") or heroName:find("storm") or heroName:find("templar") or heroName:find("puck") or heroName:find("ember") then
        return "mid"
    elseif heroName:find("centaur") or heroName:find("tidehunter") or heroName:find("dragon_knight") or heroName:find("axe") or heroName:find("mars") then
        return "offlane"
    else
        return "support"
    end
end

function GameIntelligenceExtended:GetEconomyShareItems()
    -- Items to share: wards, courier upgrades, support items
    local items = {}
    table.insert(items, "item_observer")
    table.insert(items, "item_sentry")
    table.insert(items, "item_courier")
    table.insert(items, "item_flying_courier")
    table.insert(items, "item_magic_stick")
    table.insert(items, "item_soft_boots")
    return items
end

-- ============================================================================
-- 9. VISION CONTROL: OPTIMAL WARD PLACEMENT VS ROAM PATTERNS
-- ============================================================================
function GameIntelligenceExtended:GetOptimalWardSpot(bot, gameTime)
    -- Consider enemy roam patterns, common gank paths, and rune times
    local team = bot:GetTeam() == DOTA_TEAM_GOODGUYS and "radiant" or "dire"
    local spots = self:GetWardSpotsForTeam(team)
    
    -- Score each spot based on:
    -- 1. Is it warded already? (lower score if yes)
    -- 2. Is it a rune spot at rune time? (higher score if yes)
    -- 3. Is it on a common gank path? (higher score if yes)
    -- 4. Is it deep in enemy territory? (higher score if yes, but more risky)
    
    local bestSpot = nil
    local bestScore = -1
    
    for _, spot in ipairs(spots) do
        local score = 0
        -- Check if already warded (we would need to check observer/sentry nearby)
        if self:IsSpotWarded(spot) then
            score = score - 10
        end
        
        -- Rune time bonus
        if self:IsRuneSpot(spot) and self:IsRuneTime(gameTime) then
            score = score + 20
        end
        
        -- Gank path bonus
        if self:IsOnGankPath(spot, team) then
            score = score + 15
        end
        
        -- Depth bonus (but not too deep to be dangerous)
        local depthScore = self:CalculateSpotDepth(spot, team)
        score = score + depthScore
        
        if score > bestScore then
            bestScore = score
            bestSpot = spot
        end
    end
    
    return bestSpot
end

function GameIntelligenceExtended:IsRuneTime(gameTime)
    local minute = math.floor(gameTime / 60)
    return minute % 2 == 0 -- even minutes: 0, 2, 4, ...
end

function GameIntelligenceExtended:IsRuneSpot(spot)
    -- Define rune spots
    local runeSpots = {
        {x = -1500, y = 1500}, -- top rune radiant
        {x = 1500, y = -1500}, -- bot rune radiant
        {x = 1500, y = 1500}, -- top rune dire (mirrored)
        {x = -1500, y = -1500}, -- bot rune dire
    }
    for _, runeSpot in ipairs(runeSpots) do
        if math.abs(spot.x - runeSpot.x) < 100 and math.abs(spot.y - runeSpot.y) < 100 then
            return true
        end
    end
    return false
end

function GameIntelligenceExtended:IsOnGankPath(spot, team)
    -- Simplified: assume spots near the river are on gank paths
    local riverY = team == "radiant" and 0 or 0 -- river is at y=0 for both? Actually, radiant river is negative y, dire positive? We'll simplify.
    return math.abs(spot.y) < 500 -- within 500 units of river
end

function GameIntelligenceExtended:CalculateSpotDepth(spot, team)
    -- How deep into enemy territory is the spot?
    -- For radiant, enemy territory is positive x and positive y? We'll use a simple heuristic.
    local depth = 0
    if team == "radiant" then
        depth = spot.x + spot.y -- assuming enemy is top-right
    else
        depth = -spot.x - spot.y -- assuming enemy is bottom-left
    end
    return depth * 0.1 -- scale down
end

function GameIntelligenceExtended:IsSpotWarded(spot)
    -- Check if there is an observer or sentry ward near this spot
    -- We would need to scan for wards
    return false -- placeholder
end

function GameIntelligenceExtended:GetWardSpotsForTeam(team)
    if team == "radiant" then
        return {
            {x = -2000, y = 2000, type = "observer", priority = "high", desc = "Top rune + river vision"},
            {x = 2000, y = -2000, type = "observer", priority = "high", desc = "Bot rune + river vision"},
            {x = -4000, y = 0, type = "observer", priority = "medium", desc = "Offlane defensive"},
            {x = 0, y = 4000, type = "observer", priority = "medium", desc = "Safelane defensive"},
            {x = -1000, y = -1000, type = "observer", priority = "high", desc = "Mid river control"},
            {x = -5000, y = -3000, type = "observer", priority = "low", desc = "Enemy jungle deep"},
            
            {x = -2000, y = 2000, type = "sentry", priority = "high", desc = "Deward top rune"},
            {x = 2000, y = -2000, type = "sentry", priority = "high", desc = "Deward bot rune"},
            {x = -1000, y = -1000, type = "sentry", priority = "medium", desc = "Deward mid river"},
        }
    else
        return {
            {x = 2000, y = -2000, type = "observer", priority = "high", desc = "Top rune + river vision"},
            {x = -2000, y = 2000, type = "observer", priority = "high", desc = "Bot rune + river vision"},
            {x = 4000, y = 0, type = "observer", priority = "medium", desc = "Offlane defensive"},
            {x = 0, y = -4000, type = "observer", priority = "medium", desc = "Safelane defensive"},
            {x = 1000, y = 1000, type = "observer", priority = "high", desc = "Mid river control"},
            {x = 5000, y = 3000, type = "observer", priority = "low", desc = "Enemy jungle deep"},
            
            {x = 2000, y = -2000, type = "sentry", priority = "high", desc = "Deward top rune"},
            {x = -2000, y = 2000, type = "sentry", priority = "high", desc = "Deward bot rune"},
            {x = 1000, y = 1000, type = "sentry", priority = "medium", desc = "Deward mid river"},
        }
    end
end

-- ============================================================================
-- 10. BEHAVIORAL VARIANCE: OCCASIONAL RANDOMNESS AVOID PREDICTABILITY
-- ============================================================================
function GameIntelligenceExtended:ShouldAddRandomVariance()
    -- 10% chance to add some randomness to decisions
    return math.random() < 0.1
end

function GameIntelligenceExtended:ApplyRandomVariance(value, variancePercent)
    if not self:ShouldAddRandomVariance() then return value end
    local variance = value * (variancePercent / 100.0) * (math.random() * 2 - 1) -- -variance to +variance
    return value + variance
end

-- ============================================================================
-- EXPORT
-- ============================================================================
return GameIntelligenceExtended