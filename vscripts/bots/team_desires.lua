-- AetherWeaver Team Desires
-- Workshop addon: vscripts/bots/team_desires.lua
-- Provides Think() for team coordination and desire broadcasting

local TeamDesires = {}
local Compat = require("bot_compat")

-- Team desire types
local DESIRE_TYPES = {
    PUSH = "push",
    DEFEND = "defend",
    ROSHAN = "roshan",
    TEAMFIGHT = "teamfight",
    SMOKE = "smoke",
    WARD = "ward",
    HUMAN_GANK = "human_gank",
    FARM = "farm",
    RETREAT = "retreat",
}

-- Desire state
local desireState = {
    values = {},
    lastUpdate = 0,
    updateInterval = 1.0, -- Update every second
    initialized = false
}

-- Get current game time
-- DotaTime() is the bot VM's clock; GameRules is nil here, so fall back so the
-- offline test harness (no DotaTime either) reports 0 rather than crashing.
local function GetGameTime()
    if DotaTime then return DotaTime() end
    return 0
end

-- Check if turbo mode. Turbo is not exposed to bot scripts; never enabled.
local function IsTurboMode()
    return false
end

-- Get all allied bots
local function GetAlliedBots()
    if not PlayerResource then
        -- No PlayerResource in the bot VM: fall back to the ally query.
        local bot = GetBot()
        if not bot or bot:IsNull() then return {} end
        return Compat.Allies(bot, 50000)
    end
    local bots = {}
    local team = GetTeam()
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) == team then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() and hero:IsAlive() then
                table.insert(bots, hero)
            end
        end
    end
    return bots
end

-- Get enemy heroes visible
local function GetVisibleEnemies()
    if not PlayerResource then
        -- No PlayerResource in the bot VM: fall back to the enemy query.
        local bot = GetBot()
        if not bot or bot:IsNull() then return {} end
        return Compat.Enemies(bot, 50000)
    end
    local enemies = {}
    local team = GetTeam()
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= team then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() and hero:IsAlive() then
                table.insert(enemies, hero)
            end
        end
    end
    return enemies
end

-- Count human players on enemy team.
-- The player-level API (IsPlayerBot) works in the bot VM, where PlayerResource
-- does not exist, so the fallback is the normal path rather than the exception.
local function CountHumanEnemies()
    local count = 0
    if not PlayerResource then
        for _, enemy in ipairs(Compat.EnemyHeroes()) do
            if not enemy.isBot then count = count + 1 end
        end
        return count
    end
    local team = GetTeam()
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= team then
            if not PlayerResource:IsFakeClient(i) then
                count = count + 1
            end
        end
    end
    return count
end

-- Count human cores (carry/mid) on enemy team
local function CountHumanCores()
    local count = 0
    if not PlayerResource then
        for _, enemy in ipairs(Compat.EnemyHeroes()) do
            if not enemy.isBot and enemy.level >= 10 then
                count = count + 1
            end
        end
        return count
    end
    local team = GetTeam()
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= team then
            if not PlayerResource:IsFakeClient(i) then
                local hero = PlayerResource:GetSelectedHeroEntity(i)
                if hero and not hero:IsNull() then
                    local name = hero:GetUnitName()
                    -- Check for core heroes
                    if name:find("antimage") or name:find("juggernaut") or name:find("phantom_assassin") 
                        or name:find("spectre") or name:find("medusa") or name:find("luna")
                        or name:find("invoker") or name:find("storm") or name:find("templar")
                        or name:find("puck") or name:find("ember") then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

-- Get alive allied count
local function GetAliveAlliedCount()
    local count = 0
    local bots = GetAlliedBots()
    for _, bot in ipairs(bots) do
        if bot and not bot:IsNull() and bot:IsAlive() then
            count = count + 1
        end
    end
    return count
end

-- Check if smoke of deceit available
local function HasSmokeAvailable()
    local bots = GetAlliedBots()
    for _, bot in ipairs(bots) do
        if bot and not bot:IsNull() then
            -- Compat handles handles that do not expose an inventory.
            if Compat.HasItem(bot, "item_smoke_of_deceit") then
                return true
            end
        end
    end
    return false
end

-- Get net worth advantage.
-- GetNetWorth() is a bot method, so the total is available without
-- PlayerResource: our own net worth from the bot, the enemy total from the
-- team members we can see.
local function GetNetWorthAdvantage()
    local bot = GetBot()
    local myNW = 0
    if bot and not bot:IsNull() and bot.GetNetWorth then
        local ok, nw = pcall(bot.GetNetWorth, bot)
        if ok and nw then myNW = nw end
    end

    local enemyNW = 0
    if PlayerResource then
        local team = GetTeam()
        for i = 0, 9 do
            if PlayerResource:IsValidPlayer(i) then
                local nw = PlayerResource:GetNetWorth(i)
                if PlayerResource:GetTeam(i) == team then
                    myNW = myNW + nw
                else
                    enemyNW = enemyNW + nw
                end
            end
        end
    else
        -- No PlayerResource: sum the net worth of the visible enemies.
        for _, enemy in ipairs(Compat.Enemies(bot, 30000)) do
            if enemy and not enemy:IsNull() and enemy.GetNetWorth then
                local ok, nw = pcall(enemy.GetNetWorth, enemy)
                if ok and nw then enemyNW = enemyNW + nw end
            end
        end
    end

    return myNW - enemyNW
end

-- Check Roshan status.
-- GetRoshanKillTime() is the real API: the DotaTime() stamp of the last
-- Roshan kill, 0 if it has never been killed. Roshan respawns 8-11 minutes
-- after a kill, so it is available again once that window has passed.
local function IsRoshanAlive()
    if not GetRoshanKillTime then return true end
    local lastKill = GetRoshanKillTime()
    if lastKill <= 0 then return true end
    local sinceKill = GetGameTime() - lastKill
    return sinceKill >= 480  -- 8 minutes: the lower bound of the respawn window
end

-- Calculate push desire
local function CalculatePushDesire()
    local desire = 0
    local gameTime = GetGameTime()
    local aliveAllies = GetAliveAlliedCount()
    local visibleEnemies = #GetVisibleEnemies()
    
    -- Base push desire increases over time
    desire = desire + (gameTime / 3600) * 0.3 -- 0.3 at 1 hour
    
    -- Numbers advantage
    if aliveAllies > visibleEnemies + 1 then
        desire = desire + 0.2
    elseif aliveAllies > visibleEnemies then
        desire = desire + 0.1
    end
    
    -- Late game
    if gameTime > 1800 then -- 30 min
        desire = desire + 0.15
    elseif gameTime > 1200 then -- 20 min
        desire = desire + 0.1
    end
    
    -- Net worth ahead
    local nwAdv = GetNetWorthAdvantage()
    if nwAdv > 5000 then
        desire = desire + 0.1
    elseif nwAdv > 10000 then
        desire = desire + 0.2
    end
    
    return math.min(desire, 1.0)
end

-- Calculate defend desire
local function CalculateDefendDesire()
    local desire = 0
    local gameTime = GetGameTime()
    local aliveAllies = GetAliveAlliedCount()
    local visibleEnemies = #GetVisibleEnemies()
    
    -- Numbers disadvantage
    if visibleEnemies > aliveAllies + 1 then
        desire = desire + 0.3
    elseif visibleEnemies > aliveAllies then
        desire = desire + 0.15
    end
    
    -- Early game less defend
    if gameTime < 600 then -- 10 min
        desire = desire * 0.5
    end
    
    -- Net worth behind
    local nwAdv = GetNetWorthAdvantage()
    if nwAdv < -5000 then
        desire = desire + 0.15
    elseif nwAdv < -10000 then
        desire = desire + 0.25
    end
    
    return math.min(desire, 1.0)
end

-- Calculate Roshan desire
local function CalculateRoshanDesire()
    local desire = 0
    local gameTime = GetGameTime()
    local aliveAllies = GetAliveAlliedCount()
    
    -- Roshan becomes relevant after 20 min
    if gameTime < 1200 then return 0 end
    
    -- No point grouping up for a Roshan that is not there.
    if not IsRoshanAlive() then return 0 end
    
    -- Need at least 3 alive allies
    if aliveAllies < 3 then return 0 end
    
    -- Base desire
    desire = 0.2
    
    -- Aegis holder dead or no Aegis
    -- (would check actual Aegis status)
    
    -- Team fight winning
    local visibleEnemies = #GetVisibleEnemies()
    if aliveAllies > visibleEnemies then
        desire = desire + 0.2
    end
    
    -- Post 30 min higher
    if gameTime > 1800 then
        desire = desire + 0.15
    end
    
    -- Third Roshan (Refresher Shard)
    if gameTime > 2700 then -- 45 min
        desire = desire + 0.2
    end
    
    return math.min(desire, 1.0)
end

-- Calculate teamfight desire
local function CalculateTeamfightDesire()
    local desire = 0
    local aliveAllies = GetAliveAlliedCount()
    local visibleEnemies = #GetVisibleEnemies()
    
    -- Both teams have heroes nearby
    if aliveAllies >= 3 and visibleEnemies >= 3 then
        desire = 0.4
        
        -- Numbers advantage
        if aliveAllies > visibleEnemies then
            desire = desire + 0.2
        end
        
        -- Late game
        local gameTime = GetGameTime()
        if gameTime > 1800 then
            desire = desire + 0.15
        end
    end
    
    return math.min(desire, 1.0)
end

-- Calculate smoke gank desire
local function CalculateSmokeDesire()
    local desire = 0
    local gameTime = GetGameTime()
    local aliveAllies = GetAliveAlliedCount()
    
    -- Need smoke
    if not HasSmokeAvailable() then return 0 end
    
    -- Need at least 3 allies
    if aliveAllies < 3 then return 0 end
    
    -- Mid game timing
    if gameTime > 600 and gameTime < 1800 then -- 10-30 min
        desire = 0.3
        
        -- Human enemies present
        local humanEnemies = CountHumanEnemies()
        if humanEnemies > 0 then
            desire = desire + 0.2
        end
        
        -- Post 20 min
        if gameTime > 1200 then
            desire = desire + 0.1
        end
    end
    
    -- Turbo mode: more frequent
    if IsTurboMode() then
        desire = desire * 1.5
    end
    
    return math.min(desire, 1.0)
end

-- Calculate ward desire
local function CalculateWardDesire()
    local desire = 0
    local gameTime = GetGameTime()
    
    -- Support role should ward
    local bot = GetBot()
    if not bot then return 0 end
    
    -- Base ward timing - every 3 minutes (180s)
    local interval = 180
    if IsTurboMode() then interval = 90 end
    
    -- Check if it's ward time
    local wardTime = math.floor(gameTime / interval) * interval
    if gameTime - wardTime < 30 then -- Within 30s of ward timing
        desire = 0.4
    end
    
    -- Late game more wards
    if gameTime > 1800 then
        desire = desire + 0.1
    end
    
    return math.min(desire, 1.0)
end

-- Calculate human gank desire (priority targeting of human players)
local function CalculateHumanGankDesire()
    local desire = 0
    local gameTime = GetGameTime()
    local aliveAllies = GetAliveAlliedCount()
    
    -- Need human enemies
    local humanEnemies = CountHumanEnemies()
    if humanEnemies == 0 then return 0 end
    
    desire = 0.3 -- Base for human presence
    
    -- Human cores bonus
    local humanCores = CountHumanCores()
    if humanCores > 0 then
        desire = desire + 0.25
    end
    
    -- Numbers advantage
    if aliveAllies >= 4 then
        desire = desire + 0.2
    elseif aliveAllies >= 3 then
        desire = desire + 0.1
    end
    
    -- Smoke available
    if HasSmokeAvailable() then
        desire = desire + 0.2
    end
    
    -- Timing
    if gameTime > 1200 then -- Post 20 min
        desire = desire + 0.15
    elseif gameTime > 600 then -- Post 10 min
        desire = desire + 0.1
    end
    
    -- Net worth factor
    local nwAdv = GetNetWorthAdvantage()
    if nwAdv > 5000 then
        desire = desire + 0.1
    elseif nwAdv < -5000 then
        desire = desire - 0.1
    end
    
    return math.min(desire, 1.0)
end

-- Calculate farm desire
local function CalculateFarmDesire()
    local desire = 0.3 -- Base farming desire
    local gameTime = GetGameTime()
    
    -- Early game more farm
    if gameTime < 600 then
        desire = 0.6
    elseif gameTime < 1200 then
        desire = 0.4
    end
    
    -- Turbo mode: less farm time needed
    if IsTurboMode() then
        desire = desire * 0.7
    end
    
    return math.min(desire, 1.0)
end

-- Calculate retreat desire
local function CalculateRetreatDesire()
    local desire = 0
    local bot = GetBot()
    if not bot then return 0 end
    
    -- Low HP
    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    if hpPct < 0.25 then
        desire = desire + 0.5
    elseif hpPct < 0.4 then
        desire = desire + 0.2
    end
    
    -- Outnumbered
    local nearbyEnemies = #Compat.Enemies(bot, 1200)
    local nearbyAllies = #Compat.Allies(bot, 1200)
    if nearbyEnemies > nearbyAllies + 1 then
        desire = desire + 0.3
    end
    
    return math.min(desire, 1.0)
end

-- Update all desires
local function UpdateDesires()
    local gameTime = GetGameTime()
    
    -- Throttle updates
    if gameTime - desireState.lastUpdate < desireState.updateInterval then
        return
    end
    desireState.lastUpdate = gameTime
    
    -- Calculate all desires
    local desires = {}
    desires[DESIRE_TYPES.PUSH] = CalculatePushDesire()
    desires[DESIRE_TYPES.DEFEND] = CalculateDefendDesire()
    desires[DESIRE_TYPES.ROSHAN] = CalculateRoshanDesire()
    desires[DESIRE_TYPES.TEAMFIGHT] = CalculateTeamfightDesire()
    desires[DESIRE_TYPES.SMOKE] = CalculateSmokeDesire()
    desires[DESIRE_TYPES.WARD] = CalculateWardDesire()
    desires[DESIRE_TYPES.HUMAN_GANK] = CalculateHumanGankDesire()
    desires[DESIRE_TYPES.FARM] = CalculateFarmDesire()
    desires[DESIRE_TYPES.RETREAT] = CalculateRetreatDesire()
    
    -- Store
    desireState.values = desires
    
    -- Broadcast highest priority desire (could be read by init.lua)
    -- Find max desire
    local maxDesire = 0
    local maxType = DESIRE_TYPES.FARM
    for dtype, value in pairs(desires) do
        if value > maxDesire then
            maxDesire = value
            maxType = dtype
        end
    end
    
    -- Could expose via GameIntelligence API
    -- GameIntelligence.SetTeamDesire(maxType, maxDesire)
end

-- Get current desire value
function TeamDesires:GetDesire(desireType)
    return desireState.values[desireType] or 0
end

-- Main Think function called by Dota 2
function TeamDesires:Think()
    -- Initialize on first call
    if not desireState.initialized then
        desireState.initialized = true
        print("[TeamDesires] Initialized")
    end
    
    -- Update desires
    UpdateDesires()
end

-- ============================================================================
-- ENGINE TEAM-DESIRE CONTRACT
-- The engine does not read desireState. It calls these five globals itself
-- and stores the answers, then the modes read them back through
-- GetPushLaneDesire(lane), GetDefendLaneDesire(lane), GetFarmLaneDesire(lane),
-- GetRoamDesire(), GetRoamTarget() and GetRoshanDesire().
--
-- Without them the engine has no team strategy at all: no push, no defence,
-- no Roshan call, no roam.
-- ============================================================================

-- Enemy heroes per lane, from their last known position. A sighting older
-- than 30 seconds is stale and does not count.
local function LaneEnemyCounts()
    local counts = { [1] = 0, [2] = 0, [3] = 0 }
    for _, enemy in ipairs(Compat.EnemyHeroes()) do
        if enemy.alive and enemy.pos and enemy.lastSeen < 30 then
            local lane = Compat.LaneOfPosition(enemy.pos)
            if lane and counts[lane] then counts[lane] = counts[lane] + 1 end
        end
    end
    return counts
end

-- Allied heroes per lane, from where they stand right now.
local function LaneAllyCounts()
    local counts = { [1] = 0, [2] = 0, [3] = 0 }
    for _, member in ipairs(Compat.TeamMembers()) do
        local pos = Compat.Position(member)
        local lane = Compat.LaneOfPosition(pos)
        if lane and counts[lane] then counts[lane] = counts[lane] + 1 end
    end
    return counts
end

-- The shape the engine expects: one entry per lane. It is indexed both
-- numerically (LANE_TOP=1, LANE_MID=2, LANE_BOT=3) and by name, because the
-- reference only says "{top, mid, bot}".
local function DesireTable(top, mid, bot)
    return {
        [1] = top, [2] = mid, [3] = bot,
        top = top, mid = mid, bot = bot,
    }
end

-- The team: Radiant is 2, Dire is 3.
local function OurTeam()
    local bot = GetBot()
    if bot and not bot:IsNull() and bot.GetTeam then
        local ok, team = pcall(bot.GetTeam, bot)
        if ok and team then return team end
    end
    if GetTeam then
        local ok, team = pcall(GetTeam)
        if ok and team then return team end
    end
    return 2
end

-- Which lanes have their tier-1 tower under attack.
local function LanesUnderAttack()
    local set = {}
    local team = OurTeam()
    for _, lane in ipairs({ 1, 2, 3 }) do
        if Compat.TowerUnderAttack(team, lane) then set[lane] = true end
    end
    return set
end

-- Engine hook. Returns the push desire for each lane.
function UpdatePushLaneDesires()
    UpdateDesires()
    local base = CalculatePushDesire()
    local enemies = LaneEnemyCounts()
    local allies = LaneAllyCounts()

    -- Push where we outnumber the enemy; hold back where they do.
    local function adjust(lane, value)
        local advantage = allies[lane] - enemies[lane]
        if advantage >= 2 then return value + 0.2 end
        if advantage <= 0 then return value * 0.4 end
        return value
    end
    return DesireTable(adjust(1, base), adjust(2, base), adjust(3, base))
end

-- Engine hook. Returns the defend desire for each lane.
function UpdateDefendLaneDesires()
    UpdateDesires()
    local base = CalculateDefendDesire()
    local underAttack = LanesUnderAttack()
    local enemies = LaneEnemyCounts()

    local function adjust(lane, value)
        if underAttack[lane] then
            -- Our tower is being hit: go there now.
            return math.min(1.0, value + 0.5)
        end
        if enemies[lane] > 0 then return math.min(1.0, value + 0.15) end
        return value
    end
    return DesireTable(adjust(1, base), adjust(2, base), adjust(3, base))
end

-- Engine hook. Returns the farm desire for each lane. A lane with no enemies
-- in it is the one worth farming.
function UpdateFarmLaneDesires()
    UpdateDesires()
    local base = CalculateFarmDesire()
    local enemies = LaneEnemyCounts()

    -- Contested lanes are worth less: the wave dies before you can farm.
    local function adjust(lane, value)
        if enemies[lane] > 0 then return value * 0.5 end
        return value
    end
    return DesireTable(adjust(1, base), adjust(2, base), adjust(3, base))
end

-- Engine hook. Returns the roam desire and the unit to roam to.
function UpdateRoamDesire()
    UpdateDesires()
    local desire = desireState.values[DESIRE_TYPES.TEAMFIGHT] or 0

    -- A human core is worth roaming for: ganking a human removes a real
    -- player from the game, not another bot. It raises the desire; the
    -- target stays a unit handle.
    for _, enemy in ipairs(Compat.EnemyHeroes()) do
        if enemy.alive and not enemy.isBot and enemy.level >= 10 then
            desire = math.min(1.0, desire + 0.15)
        end
    end

    -- The engine wants a unit handle. The weakest visible enemy hero is the
    -- one worth finishing off.
    local target = nil
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local weakestHp = math.huge
        for _, enemy in ipairs(Compat.Enemies(bot, 2000)) do
            if enemy and not enemy:IsNull() and enemy:IsAlive() then
                local hp = enemy:GetHealth()
                if hp < weakestHp then
                    target, weakestHp = enemy, hp
                end
            end
        end
    end

    return desire, target
end

-- Engine hook. Returns the Roshan desire.
function UpdateRoshanDesire()
    UpdateDesires()
    return desireState.values[DESIRE_TYPES.ROSHAN] or 0
end

-- Engine hook. team_desires.lua is where the engine calls TeamThink() once per
-- frame, so this is the only reliably-ticked per-frame entry point. It drives
-- AetherWeaver's periodic work (naming already happens in hero_selection).
function TeamThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local AetherWeaver = require("init")
        AetherWeaver.hero = bot
        AetherWeaver:BotThink()
    end
    TeamDesires:Think()
end

-- Export desire types for external use
TeamDesires.DESIRE_TYPES = DESIRE_TYPES

return TeamDesires