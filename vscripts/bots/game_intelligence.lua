-- AetherWeaver Dota 2 Bot - Game Intelligence Modules
-- Workshop addon: vscripts/bots/init.lua

-- ============================================================================
-- MODULE: GAME INTELLIGENCE (Game Designer specialist)
-- ============================================================================
local GameIntelligence = {}

-- ============================================================================
-- 1. HERO PICK/BAN SYSTEM
-- ============================================================================
GameIntelligence.PickBan = {}

-- Hero database with roles, counters, meta strength
GameIntelligence.PickBan.heroDatabase = {
    -- Carry
    npc_dota_hero_antimage = {role = "carry", counters = {"npc_dota_hero_phantom_assassin", "npc_dota_hero_spectre", "npc_dota_hero_medusa"}, metaStrength = 0.8, difficulty = 0.6},
    npc_dota_hero_juggernaut = {role = "carry", counters = {"npc_dota_hero_pugna", "npc_dota_hero_necrophos", "npc_dota_hero_razor"}, metaStrength = 0.9, difficulty = 0.4},
    npc_dota_hero_phantom_assassin = {role = "carry", counters = {"npc_dota_hero_antimage", "npc_dota_hero_spectre", "npc_dota_hero_phantom_lancer"}, metaStrength = 0.85, difficulty = 0.5},
    npc_dota_hero_spectre = {role = "carry", counters = {"npc_dota_hero_antimage", "npc_dota_hero_phantom_lancer", "npc_dota_hero_naga_siren"}, metaStrength = 0.9, difficulty = 0.5},
    npc_dota_hero_medusa = {role = "carry", counters = {"npc_dota_hero_antimage", "npc_dota_hero_nyx_assassin", "npc_dota_hero_invoker"}, metaStrength = 0.75, difficulty = 0.6},
    
    -- Mid
    npc_dota_hero_invoker = {role = "mid", counters = {"npc_dota_hero_pugna", "npc_dota_hero_silencer", "npc_dota_hero_nyx_assassin"}, metaStrength = 0.85, difficulty = 0.9},
    npc_dota_hero_storm_spirit = {role = "mid", counters = {"npc_dota_hero_skywrath_mage", "npc_dota_hero_oracle", "npc_dota_hero_pugna"}, metaStrength = 0.8, difficulty = 0.8},
    npc_dota_hero_templar_assassin = {role = "mid", counters = {"npc_dota_hero_jakiro", "npc_dota_hero_venomancer", "npc_dota_hero_huskar"}, metaStrength = 0.8, difficulty = 0.7},
    npc_dota_hero_puck = {role = "mid", counters = {"npc_dota_hero_silencer", "npc_dota_hero_nyx_assassin", "npc_dota_hero_doom"}, metaStrength = 0.75, difficulty = 0.7},
    npc_dota_hero_ember_spirit = {role = "mid", counters = {"npc_dota_hero_earth_spirit", "npc_dota_hero_doom", "npc_dota_hero_silencer"}, metaStrength = 0.8, difficulty = 0.8},
    
    -- Offlane
    npc_dota_hero_centaur = {role = "offlane", counters = {"npc_dota_hero_necrophos", "npc_dota_hero_ancient_apparition", "npc_dota_hero_reaper"}, metaStrength = 0.85, difficulty = 0.3},
    npc_dota_hero_tidehunter = {role = "offlane", counters = {"npc_dota_hero_necrophos", "npc_dota_hero_viper", "npc_dota_hero_reaper"}, metaStrength = 0.8, difficulty = 0.3},
    npc_dota_hero_dragon_knight = {role = "offlane", counters = {"npc_dota_hero_necrophos", "npc_dota_hero_reaper", "npc_dota_hero_viper"}, metaStrength = 0.8, difficulty = 0.4},
    npc_dota_hero_axe = {role = "offlane", counters = {"npc_dota_hero_necrophos", "npc_dota_hero_viper", "npc_dota_hero_razor"}, metaStrength = 0.85, difficulty = 0.4},
    npc_dota_hero_mars = {role = "offlane", counters = {"npc_dota_hero_necrophos", "npc_dota_hero_reaper", "npc_dota_hero_viper"}, metaStrength = 0.8, difficulty = 0.5},
    
    -- Support
    npc_dota_hero_crystal_maiden = {role = "support", counters = {"npc_dota_hero_pugna", "npc_dota_hero_nyx_assassin", "npc_dota_hero_earth_spirit"}, metaStrength = 0.7, difficulty = 0.3},
    npc_dota_hero_lich = {role = "support", counters = {"npc_dota_hero_anti_mage", "npc_dota_hero_pugna", "npc_dota_hero_nyx_assassin"}, metaStrength = 0.75, difficulty = 0.3},
    npc_dota_hero_witch_doctor = {role = "support", counters = {"npc_dota_hero_pugna", "npc_dota_hero_silencer", "npc_dota_hero_nyx_assassin"}, metaStrength = 0.75, difficulty = 0.4},
    npc_dota_hero_shadow_shaman = {role = "support", counters = {"npc_dota_hero_pugna", "npc_dota_hero_anti_mage", "npc_dota_hero_nyx_assassin"}, metaStrength = 0.8, difficulty = 0.4},
    npc_dota_hero_lion = {role = "support", counters = {"npc_dota_hero_pugna", "npc_dota_hero_anti_mage", "npc_dota_hero_nyx_assassin"}, metaStrength = 0.85, difficulty = 0.3},
    npc_dota_hero_dazzle = {role = "support", counters = {"npc_dota_hero_necrophos", "npc_dota_hero_axe", "npc_dota_hero_ancient_apparition"}, metaStrength = 0.8, difficulty = 0.4},
    npc_dota_hero_oracle = {role = "support", counters = {"npc_dota_hero_silencer", "npc_dota_hero_pugna", "npc_dota_hero_nyx_assassin"}, metaStrength = 0.85, difficulty = 0.7},
}

-- Pick logic: fill missing role, counter enemy, consider meta
function GameIntelligence.PickBan:GetBestPick(humanRoles, enemyPicks, bannedHeroes)
    local neededRoles = {}
    for role, has in pairs(humanRoles) do
        if not has then table.insert(neededRoles, role) end
    end
    if #neededRoles == 0 then neededRoles = {"carry", "mid", "offlane", "support"} end
    
    local bestHero = nil
    local bestScore = -1
    
    for heroName, data in pairs(self.heroDatabase) do
        if not bannedHeroes[heroName] then
            local roleMatch = false
            for _, role in ipairs(neededRoles) do
                if data.role == role then roleMatch = true break end
            end
            
            if roleMatch then
                local score = data.metaStrength * 10
                
                -- Counter enemy picks bonus
                for _, enemyHero in ipairs(enemyPicks) do
                    if data.counters then
                        for _, counter in ipairs(data.counters) do
                            if enemyHero:find(counter) then
                                score = score + 15
                                break
                            end
                        end
                    end
                end
                
                -- Avoid counter-picked
                local countered = false
                for _, enemyHero in ipairs(enemyPicks) do
                    local enemyData = self.heroDatabase[enemyHero]
                    if enemyData and enemyData.counters then
                        for _, counter in ipairs(enemyData.counters) do
                            if heroName == counter then
                                countered = true
                                score = score - 20
                                break
                            end
                        end
                    end
                end
                
                if score > bestScore then
                    bestScore = score
                    bestHero = heroName
                end
            end
        end
    end
    
    return bestHero or "npc_dota_hero_antimage"
end

-- Ban logic: ban strong meta heroes that counter our team or are generally OP
function GameIntelligence.PickBan:GetBestBan(ourPicks, enemyPicks)
    local bestHero = nil
    local bestScore = -1
    
    for heroName, data in pairs(self.heroDatabase) do
        if not ourPicks[heroName] and not enemyPicks[heroName] then
            local score = data.metaStrength * 10
            
            -- Prioritize banning heroes that counter our picks
            for _, ourHero in pairs(ourPicks) do
                local ourData = self.heroDatabase[ourHero]
                if ourData and ourData.counters then
                    for _, counter in ipairs(ourData.counters) do
                        if heroName == counter then
                            score = score + 20
                            break
                        end
                    end
                end
            end
            
            if score > bestScore then
                bestScore = score
                bestHero = heroName
            end
        end
    end
    
    return bestHero
end

-- ============================================================================
-- 2. LANE ASSIGNMENT & DYNAMIC LANE SWITCHING
-- ============================================================================
GameIntelligence.Lanes = {}

GameIntelligence.Lanes.lanePositions = {
    radiant = {
        safe = {x = -4000, y = -1000, name = "safe"},
        mid = {x = 0, y = 0, name = "mid"},
        off = {x = 1000, y = 4000, name = "off"},
        jungle = {x = -2000, y = -3000, name = "jungle"},
    },
    dire = {
        safe = {x = 4000, y = 1000, name = "safe"},
        mid = {x = 0, y = 0, name = "mid"},
        off = {x = -1000, y = -4000, name = "off"},
        jungle = {x = 2000, y = 3000, name = "jungle"},
    }
}

GameIntelligence.Lanes.heroLanePreference = {
    carry = "safe",
    mid = "mid",
    offlane = "off",
    support = "jungle"
}

function GameIntelligence.Lanes:GetInitialLane(heroName, team)
    local heroData = GameIntelligence.PickBan.heroDatabase[heroName]
    local role = heroData and heroData.role or "carry"
    local pref = self.heroLanePreference[role] or "safe"
    local teamLanes = self.lanePositions[team == DOTA_TEAM_GOODGUYS and "radiant" or "dire"]
    return teamLanes[pref], pref
end

function GameIntelligence.Lanes:ShouldSwitchLane(bot, currentLane, gameTime)
    local team = bot:GetTeam()
    local enemyTeam = team == DOTA_TEAM_GOODGUYS and DOTA_TEAM_BADGUYS or DOTA_TEAM_GOODGUYS
    
    -- Check tower states
    local ourTower = self:GetLaneTower(currentLane, team)
    local enemyTower = self:GetLaneTower(currentLane, enemyTeam)
    
    -- Switch if our tower is down and enemy tower is up (pushed out)
    if ourTower and ourTower:IsNull() and enemyTower and not enemyTower:IsNull() then
        return true, "safe"
    end
    
    -- Switch if enemy tower is down (can push advantage)
    if enemyTower and enemyTower:IsNull() and ourTower and not ourTower:IsNull() then
        return true, currentLane -- stay and push
    end
    
    -- Check enemy rotations (missing enemies in our lane)
    local missingInLane = self:CountMissingEnemiesInLane(currentLane)
    if missingInLane >= 2 and gameTime > 600 then -- after 10 min
        return true, "jungle" -- play safe
    end
    
    -- Farm efficiency: if lane is pushed out and we're support, go jungle/stack
    if gameTime > 900 and bot:GetRole() == "support" then
        local laneState = self:GetLaneEquilibrium(currentLane)
        if laneState == "pushed_out" then
            return true, "jungle"
        end
    end
    
    return false, currentLane
end

function GameIntelligence.Lanes:GetLaneTower(lane, team)
    -- Implementation depends on Dota API
    return nil
end

function GameIntelligence.Lanes:CountMissingEnemiesInLane(lane)
    -- Count enemy heroes not visible in this lane
    return 0
end

function GameIntelligence.Lanes:GetLaneEquilibrium(lane)
    -- Returns "pushed_in", "equilibrium", "pushed_out"
    return "equilibrium"
end

-- ============================================================================
-- 3. FARMING PATTERNS
-- ============================================================================
GameIntelligence.Farming = {}

GameIntelligence.Farming.patterns = {
    lane = {
        lastHitThreshold = 0.5, -- HP % to last hit
        denyThreshold = 0.5,
        equilibriumRange = 500, -- distance from tower for equilibrium
    },
    jungle = {
        campPriorities = {"large", "medium", "small", "ancient"},
        stackTimings = {53, 54, 55}, -- seconds to stack
        pullTimings = {15, 16, 17}, -- seconds to pull
    }
}

function GameIntelligence.Farming:GetBestFarmTarget(bot, gameTime)
    local role = bot:GetRole()
    local lane = bot:GetAssignedLane()
    
    -- Early game: lane farm
    if gameTime < 600 then -- first 10 min
        return self:GetLaneFarmTarget(bot, lane)
    end
    
    -- Mid game: mix of lane and jungle
    if gameTime < 1800 then -- 10-30 min
        if role == "carry" or role == "mid" then
            return self:GetMixedFarmTarget(bot)
        else
            return self:GetSupportFarmTarget(bot)
        end
    end
    
    -- Late game: team fights and objectives
    return self:GetLateGameFarmTarget(bot)
end

function GameIntelligence.Farming:GetLaneFarmTarget(bot, lane)
    -- Find creeps in lane equilibrium zone
    local creeps = bot:GetNearbyCreeps(1200, true)
    local bestCreep = nil
    local bestScore = -1
    
    for _, creep in ipairs(creeps) do
        if creep:GetTeam() ~= bot:GetTeam() then
            local hpPct = creep:GetHealth() / creep:GetMaxHealth()
            if hpPct <= self.patterns.lane.lastHitThreshold then
                local score = 100 - (hpPct * 100) -- lower HP = higher priority
                if score > bestScore then
                    bestScore = score
                    bestCreep = creep
                end
            end
        else -- allied creep for deny
            local hpPct = creep:GetHealth() / creep:GetMaxHealth()
            if hpPct <= self.patterns.lane.denyThreshold then
                local score = 80 - (hpPct * 100)
                if score > bestScore then
                    bestScore = score
                    bestCreep = creep
                end
            end
        end
    end
    
    return bestCreep
end

function GameIntelligence.Farming:GetMixedFarmTarget(bot)
    -- Check for jungle camps
    local camps = bot:GetNearbyNeutralCamps(1500)
    if #camps > 0 then
        -- Prioritize stacked camps
        for _, camp in ipairs(camps) do
            if camp:IsStacked() then return camp end
        end
        return camps[1]
    end
    return self:GetLaneFarmTarget(bot, bot:GetAssignedLane())
end

function GameIntelligence.Farming:GetSupportFarmTarget(bot)
    -- Supports: pull camps, stack, ward, harass
    local pullCamp = bot:GetPullCamp()
    if pullCamp and GameRules:GetGameTime() % 60 >= 15 and GameRules:GetGameTime() % 60 <= 17 then
        return pullCamp
    end
    return nil -- supports don't farm creeps primarily
end

function GameIntelligence.Farming:GetLateGameFarmTarget(bot)
    -- Farm waves pushing to towers, take Roshan, push lanes
    local pushingWaves = bot:GetPushingWaves()
    if #pushingWaves > 0 then return pushingWaves[1] end
    return nil
end

-- ============================================================================
-- 4. SUPPORTING ROLE (Warding, Pulling, Stacking, Courier, Smoke)
-- ============================================================================
GameIntelligence.Support = {}

GameIntelligence.Support.wardSpots = {
    radiant = {
        -- Observer wards
        {x = -2000, y = 2000, type = "observer", priority = "high", desc = "Top rune + river vision"},
        {x = 2000, y = -2000, type = "observer", priority = "high", desc = "Bot rune + river vision"},
        {x = -4000, y = 0, type = "observer", priority = "medium", desc = "Offlane defensive"},
        {x = 0, y = 4000, type = "observer", priority = "medium", desc = "Safelane defensive"},
        {x = -1000, y = -1000, type = "observer", priority = "high", desc = "Mid river control"},
        {x = -5000, y = -3000, type = "observer", priority = "low", desc = "Enemy jungle deep"},
        
        -- Sentry wards
        {x = -2000, y = 2000, type = "sentry", priority = "high", desc = "Deward top rune"},
        {x = 2000, y = -2000, type = "sentry", priority = "high", desc = "Deward bot rune"},
        {x = -1000, y = -1000, type = "sentry", priority = "medium", desc = "Deward mid river"},
    },
    dire = {
        -- Mirror positions
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
}

function GameIntelligence.Support:GetNextWardAction(bot, gameTime)
    local wards = bot:GetAvailableWards()
    if wards.observer == 0 and wards.sentry == 0 then return nil end
    
    local team = bot:GetTeam() == DOTA_TEAM_GOODGUYS and "radiant" or "dire"
    local spots = self.wardSpots[team]
    
    -- Early game: rune wards
    if gameTime < 300 then
        for _, spot in ipairs(spots) do
            if spot.type == "observer" and spot.priority == "high" and not self:IsWarded(spot) then
                return spot
            end
        end
    end
    
    -- Mid game: vision control
    if gameTime < 1800 then
        for _, spot in ipairs(spots) do
            if spot.type == "observer" and not self:IsWarded(spot) then
                -- Check if enemy has vision there (need sentry)
                if self:EnemyHasVision(spot) and wards.sentry > 0 then
                    return {x = spot.x, y = spot.y, type = "sentry", priority = "deward"}
                end
                return spot
            end
        end
    end
    
    -- Late game: deep wards / dewards
    for _, spot in ipairs(spots) do
        if spot.type == "sentry" and spot.priority == "deward" and not self:IsWarded(spot) then
            return spot
        end
    end
    
    return nil
end

function GameIntelligence.Support:IsWarded(spot)
    -- Check if ward already placed nearby
    return false
end

function GameIntelligence.Support:EnemyHasVision(spot)
    -- Check if enemy likely has ward there
    return false
end

function GameIntelligence.Support:GetPullAction(bot, gameTime)
    local minute = math.floor(gameTime / 60)
    local second = gameTime % 60
    
    -- Pull at :15-:17, :45-:47
    if (second >= 15 and second <= 17) or (second >= 45 and second <= 47) then
        local pullCamp = bot:GetPullCamp()
        if pullCamp then return pullCamp end
    end
    return nil
end

function GameIntelligence.Support:GetStackAction(bot, gameTime)
    local second = gameTime % 60
    
    -- Stack at :53-:55
    if second >= 53 and second <= 55 then
        local camps = bot:GetNearbyNeutralCamps(1000)
        for _, camp in ipairs(camps) do
            if not camp:IsStacked() then return camp end
        end
    end
    return nil
end

function GameIntelligence.Support:GetCourierAction(bot)
    -- Upgrade courier at 3 min, flying at 12 min
    local gameTime = GameRules:GetGameTime()
    local courier = bot:GetCourier()
    
    if gameTime < 180 and courier and not courier:HasFlyingCourier() then
        return "upgrade"
    elseif gameTime < 720 and courier and courier:HasFlyingCourier() and not courier:HasFlyingUpgrade() then
        return "flying_upgrade"
    end
    return nil
end

function GameIntelligence.Support:GetSmokeGankAction(bot, gameTime)
    -- Smoke gank when: have smoke, mid laner has ult, enemy out of position
    if gameTime < 600 then return nil end -- too early
    
    local hasSmoke = bot:HasItem("item_smoke_of_deceit")
    if not hasSmoke then return nil end
    
    local midHero = bot:GetMidHero()
    if midHero and midHero:HasUltimateReady() then
        local targetLane = self:FindGankableLane()
        if targetLane then return targetLane end
    end
    
    return nil
end

function GameIntelligence.Support:FindGankableLane()
    -- Find lane with: enemy pushed up, no vision, our hero has CC
    return nil
end

-- ============================================================================
-- 5. TEAM FIGHT DECISION MAKING
-- ============================================================================
GameIntelligence.TeamFight = {}

GameIntelligence.TeamFight.targetPriorities = {
    -- Priority: higher = more important target
    carry = 100,
    mid = 90,
    support = 70,
    offlane = 60,
    -- Specific hero adjustments
    npc_dota_hero_medusa = 110,
    npc_dota_hero_spectre = 105,
    npc_dota_hero_huskar = 95,
    npc_dota_hero_bristleback = 60, -- tanky, lower priority
    npc_dota_hero_centaur = 55,
}

function GameIntelligence.TeamFight:FindBestTarget(bot, enemies)
    local bestTarget = nil
    local bestScore = -1
    
    for _, enemy in ipairs(enemies) do
        if not enemy:IsNull() and enemy:IsAlive() and not enemy:IsIllusion() then
            local score = self:GetTargetPriority(enemy)
            
            -- Adjust for distance (prefer closer)
            local dist = (bot:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
            score = score - (dist / 100)
            
            -- Adjust for HP (prefer low HP)
            local hpPct = enemy:GetHealth() / enemy:GetMaxHealth()
            score = score + (1 - hpPct) * 30
            
            -- Adjust for disable immunity (BKB, etc.)
            if enemy:IsMagicImmune() then score = score - 40 end
            
            if score > bestScore then
                bestScore = score
                bestTarget = enemy
            end
        end
    end
    
    return bestTarget
end

function GameIntelligence.TeamFight:GetTargetPriority(enemy)
    local name = enemy:GetUnitName()
    if self.targetPriorities[name] then return self.targetPriorities[name] end
    
    -- Determine role from hero name
    if name:find("antimage") or name:find("juggernaut") or name:find("phantom_assassin") or name:find("spectre") or name:find("medusa") then
        return self.targetPriorities.carry
    elseif name:find("invoker") or name:find("storm") or name:find("templar") or name:find("puck") or name:find("ember") then
        return self.targetPriorities.mid
    elseif name:find("centaur") or name:find("tidehunter") or name:find("dragon_knight") or name:find("axe") or name:find("mars") then
        return self.targetPriorities.offlane
    else
        return self.targetPriorities.support
    end
end

function GameIntelligence.TeamFight:ShouldEngage(bot, enemies, allies)
    local ourPower = self:CalculateTeamPower(allies)
    local enemyPower = self:CalculateTeamPower(enemies)
    
    -- Engage if we have advantage
    if ourPower > enemyPower * 1.2 then return true end
    
    -- Engage if key enemy ult is down
    for _, enemy in ipairs(enemies) do
        if enemy:IsHero() and not enemy:HasUltimateReady() and self:GetTargetPriority(enemy) > 80 then
            return true
        end
    end
    
    -- Disengage if we're outnumbered or key ally ult down
    if ourPower < enemyPower * 0.8 then return false end
    
    return false
end

function GameIntelligence.TeamFight:CalculateTeamPower(heroes)
    local power = 0
    for _, hero in ipairs(heroes) do
        if hero:IsHero() and hero:IsAlive() then
            local hpPct = hero:GetHealth() / hero:GetMaxHealth()
            local manaPct = hero:GetMana() / hero:GetMaxMana()
            local basePower = self:GetTargetPriority(hero)
            power = power + basePower * hpPct * (0.5 + manaPct * 0.5)
        end
    end
    return power
end

function GameIntelligence.TeamFight:GetBestPosition(bot, target)
    local role = bot:GetRole()
    local attackRange = bot:GetAttackRange()
    
    if role == "carry" or role == "mid" then
        -- Behind frontline, at attack range
        local dir = (bot:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
        return target:GetAbsOrigin() + dir * math.max(attackRange - 100, 300)
    elseif role == "offlane" then
        -- Frontline, initiate
        return target:GetAbsOrigin() + (target:GetAbsOrigin() - bot:GetAbsOrigin()):Normalized() * 200
    else -- support
        -- Behind carry, safe distance
        local carry = bot:GetCarryAlly()
        if carry then
            return carry:GetAbsOrigin() + (carry:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * 400
        end
    end
    return bot:GetAbsOrigin()
end

function GameIntelligence.TeamFight:GetAbilityUsage(bot, target)
    local abilities = {}
    for i = 0, 23 do
        local abil = bot:GetAbilityByIndex(i)
        if abil and abil:IsFullyCastable() and not abil:IsPassive() and not abil:IsHidden() then
            table.insert(abilities, abil)
        end
    end
    
    -- Sort by priority: ult > disable > nuke > buff
    table.sort(abilities, function(a, b)
        local aIsUlt = a:IsUltimate()
        local bIsUlt = b:IsUltimate()
        if aIsUlt ~= bIsUlt then return aIsUlt end
        
        local aType = a:GetBehavior()
        local bType = b:GetBehavior()
        -- Simplified: prioritize unit target disables
        return a:GetCastRange() < b:GetCastRange()
    end)
    
    return abilities
end

-- ============================================================================
-- 6. GANKING LOGIC
-- ============================================================================
GameIntelligence.Ganking = {}

function GameIntelligence.Ganking:ShouldGank(bot, gameTime)
    if gameTime < 300 then return false end -- too early
    if bot:GetHealth() / bot:GetMaxHealth() < 0.5 then return false end -- too low
    if bot:GetMana() / bot:GetMaxMana() < 0.3 then return false end -- no mana
    
    local role = bot:GetRole()
    if role == "carry" and gameTime < 1200 then return false end -- carry farms early
    
    -- Check for smoke
    if bot:HasItem("item_smoke_of_deceit") then return true end
    
    -- Check for rune control
    if self:HasRuneAdvantage(bot) then return true end
    
    -- Check for enemy out of position
    return self:HasGankOpportunity(bot)
end

function GameIntelligence.Ganking:HasRuneAdvantage(bot)
    -- Check if we control runes
    return false
end

function GameIntelligence.Ganking:HasGankOpportunity(bot)
    -- Scan lanes for: enemy pushed up, low HP, no escape, our ally in lane
    return false
end

function GameIntelligence.Ganking:GetGankTarget(bot)
    local bestTarget = nil
    local bestScore = -1
    
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= bot:GetTeam() then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and hero:IsAlive() and not hero:IsNull() then
                local score = 0
                local hpPct = hero:GetHealth() / hero:GetMaxHealth()
                score = score + (1 - hpPct) * 50
                
                -- Check if pushed up
                if self:IsLanePushed(hero) then score = score + 30 end
                
                -- Check for escape spells
                if not self:HasEscape(hero) then score = score + 20 end
                
                -- Check for vision
                if not hero:HasModifier("modifier_truesight") then score = score + 10 end
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = hero
                end
            end
        end
    end
    
    return bestTarget
end

function GameIntelligence.Ganking:IsLanePushed(hero)
    -- Check if hero is past river
    return false
end

function GameIntelligence.Ganking:HasEscape(hero)
    -- Check for blink, force staff, invis, etc.
    return false
end

-- ============================================================================
-- 7. PUSHING STRATEGY
-- ============================================================================
GameIntelligence.Pushing = {}

function GameIntelligence.Pushing:ShouldPush(bot, gameTime)
    local team = bot:GetTeam()
    local enemyTeam = team == DOTA_TEAM_GOODGUYS and DOTA_TEAM_BADGUYS or DOTA_TEAM_GOODGUYS
    
    -- Check tower states
    local enemyTowers = self:GetEnemyTowers(team)
    local ourTowers = self:GetOurTowers(team)
    
    -- Push if enemy tier 1 down and we have advantage
    local downedT1 = 0
    for _, tower in ipairs(enemyTowers) do
        if tower:IsTier1() and tower:IsNull() then downedT1 = downedT1 + 1 end
    end
    
    if downedT1 >= 2 then return true end
    
    -- Push if Roshan just taken
    if self:JustTookRoshan() then return true end
    
    -- Push if enemy buybacks down
    if self:EnemyBuybacksDown(enemyTeam) then return true end
    
    -- Push if mega creeps
    if self:HasMegaCreeps(team) then return true end
    
    return false
end

function GameIntelligence.Pushing:GetPushLane(bot)
    -- Priority: lane with most advantage (tower down, wave pushed, enemy far)
    local lanes = {"top", "mid", "bot"}
    local bestLane = nil
    local bestScore = -1
    
    for _, lane in ipairs(lanes) do
        local score = self:CalculatePushScore(lane, bot:GetTeam())
        if score > bestScore then
            bestScore = score
            bestLane = lane
        end
    end
    
    return bestLane
end

function GameIntelligence.Pushing:CalculatePushScore(lane, team)
    local score = 0
    local enemyTeam = team == DOTA_TEAM_GOODGUYS and DOTA_TEAM_BADGUYS or DOTA_TEAM_GOODGUYS
    
    -- Tower state
    local enemyTower = self:GetLaneTower(lane, enemyTeam)
    local ourTower = self:GetLaneTower(lane, team)
    
    if enemyTower and enemyTower:IsNull() then score = score + 50 end
    if enemyTower and enemyTower:IsTier1() and not enemyTower:IsNull() then score = score + 20 end
    if ourTower and ourTower:IsNull() then score = score - 30 end
    
    -- Wave position
    local wavePos = self:GetWavePosition(lane)
    if wavePos == "enemy_tower" then score = score + 30
    elseif wavePos == "river" then score = score + 10
    elseif wavePos == "our_tower" then score = score - 20 end
    
    -- Enemy presence
    local enemiesInLane = self:CountEnemiesInLane(lane, enemyTeam)
    score = score - enemiesInLane * 15
    
    return score
end

function GameIntelligence.Pushing:GetEnemyTowers(team)
    return {}
end

function GameIntelligence.Pushing:GetOurTowers(team)
    return {}
end

function GameIntelligence.Pushing:JustTookRoshan()
    return false
end

function GameIntelligence.Pushing:EnemyBuybacksDown(team)
    return false
end

function GameIntelligence.Pushing:HasMegaCreeps(team)
    return false
end

function GameIntelligence.Pushing:GetLaneTower(lane, team)
    return nil
end

function GameIntelligence.Pushing:GetWavePosition(lane)
    return "river"
end

function GameIntelligence.Pushing:CountEnemiesInLane(lane, team)
    return 0
end

-- ============================================================================
-- 8. HUMAN GUIDANCE SYSTEM
-- ============================================================================
GameIntelligence.Guidance = {}

GameIntelligence.Guidance.tips = {
    early_game = {
        "Tip: Control the creep equilibrium by denying your own creeps!",
        "Tip: Pull the small camp at :15-:17 to reset lane equilibrium.",
        "Tip: Place observer wards on rune spots at 0:00 and 6:00.",
        "Tip: Harass the enemy offlaner when they go for last hits.",
        "Tip: Don't auto-attack creeps! Only last hit and deny.",
    },
    mid_game = {
        "Tip: Group with your team for tower pushes and Roshan fights.",
        "Tip: Smoke gank when enemy carry is farming alone.",
        "Tip: Buy dust/sentries against invisible heroes.",
        "Tip: Control bounty runes every 5 minutes for gold/xp advantage.",
        "Tip: Use TP scrolls to defend towers or join fights.",
    },
    late_game = {
        "Tip: Stick together! One pickoff can lose the game.",
        "Tip: Buyback management: don't waste it on a lost fight.",
        "Tip: High ground defense: wait for them to come to you.",
        "Tip: Refresher Shard on 3rd Roshan is game-changing.",
        "Tip: Focus enemy carries in team fights, not tanks.",
    },
    support_specific = {
        "Tip: Stack camps at :53-:55 for your carry.",
        "Tip: Pull the wave at :15-:17 to deny enemy xp.",
        "Tip: Upgrade courier at 3 min, flying at 12 min.",
        "Tip: Deward enemy observer wards with sentries.",
        "Tip: Save your stuns/disables for enemy initiators.",
    },
    role_specific = {
        carry = {
            "Tip: Farm efficiently - every missed last hit is lost gold.",
            "Tip: Battle Fury timing: aim for <18 min.",
            "Tip: Split push when team can defend 4v5.",
            "Tip: Don't fight without your core items.",
        },
        mid = {
            "Tip: Control the runes every 2 minutes.",
            "Tip: Gank side lanes after pushing wave.",
            "Tip: Bottle crow for sustain (if allowed).",
            "Tip: Match enemy mid's movements or punish them.",
        },
        offlane = {
            "Tip: Disrupt enemy carry's farm - harass, pull, zone.",
            "Tip: Get level 6 fast for kill potential.",
            "Tip: Rotate to mid after getting level advantage.",
            "Tip: Build utility items (Pipe, Crimson, Lotus).",
        },
        support = {
            "Tip: Your job is vision - buy wards every cooldown.",
            "Tip: Sacrifice yourself for your carry if needed.",
            "Tip: Stack ancients for your carry when possible.",
            "Tip: Check enemy inventories for dust/smoke.",
        },
    }
}

function GameIntelligence.Guidance:GetContextualTip(bot, gameTime, situation)
    local role = bot:GetRole()
    local category = "early_game"
    
    if gameTime > 1800 then category = "late_game"
    elseif gameTime > 600 then category = "mid_game" end
    
    local tips = self.tips[category] or {}
    
    -- Add role-specific tips
    if self.tips.role_specific[role] then
        for _, tip in ipairs(self.tips.role_specific[role]) do
            table.insert(tips, tip)
        end
    end
    
    -- Add support tips for supports
    if role == "support" then
        for _, tip in ipairs(self.tips.support_specific) do
            table.insert(tips, tip)
        end
    end
    
    -- Situation-specific
    if situation == "lost_teamfight" then
        table.insert(tips, "Tip: Don't feed after a lost fight! Regroup and defend.")
    elseif situation == "behind_gold" then
        table.insert(tips, "Tip: We're behind. Avoid fights, farm safely, wait for mistakes.")
    elseif situation == "ahead_gold" then
        table.insert(tips, "Tip: We're ahead! Group up, take objectives, don't throw.")
    elseif situation == "roshan_up" then
        table.insert(tips, "Tip: Roshan is up! Ward the pit, prepare for fight.")
    end
    
    return tips[math.random(#tips)]
end

function GameIntelligence.Guidance:SendTipToHumans(bot, situation)
    local tip = self:GetContextualTip(bot, GameRules:GetGameTime(), situation)
    if tip then
        -- Send via chat wheel or chat
        GameRules:SendCustomMessage("🤖 " .. tip, 0, 0)
    end
end

-- ============================================================================
-- 9. LANE CHANGING CONDITIONS
-- ============================================================================
GameIntelligence.LaneChanging = {}

function GameIntelligence.LaneChanging:EvaluateLaneChange(bot, gameTime)
    local currentLane = bot:GetAssignedLane()
    local role = bot:GetRole()
    
    -- Don't change lanes too frequently
    if bot.lastLaneChange and gameTime - bot.lastLaneChange < 120 then
        return currentLane
    end
    
    local shouldSwitch, newLane = GameIntelligence.Lanes:ShouldSwitchLane(bot, currentLane, gameTime)
    if shouldSwitch then
        bot.lastLaneChange = gameTime
        return newLane
    end
    
    -- Role-specific lane changes
    if role == "support" then
        -- Roaming support: rotate to help mid/offlane
        if gameTime > 300 and gameTime < 900 then
            return self:GetRoamLane(bot)
        end
    elseif role == "mid" then
        -- Mid: gank side lanes after 6
        if bot:GetLevel() >= 6 and gameTime > 420 then
            return self:GetGankLane(bot)
        end
    elseif role == "offlane" then
        -- Offlane: rotate to jungle/tri-lane after tower down
        if self:IsOfflaneTowerDown(bot:GetTeam()) then
            return "jungle"
        end
    end
    
    return currentLane
end

function GameIntelligence.LaneChanging:GetRoamLane(bot)
    -- Find lane needing help
    return nil
end

function GameIntelligence.LaneChanging:GetGankLane(bot)
    -- Find gankable side lane
    return nil
end

function GameIntelligence.LaneChanging:IsOfflaneTowerDown(team)
    return false
end

-- ============================================================================
-- EXPORT
-- ============================================================================
return GameIntelligence