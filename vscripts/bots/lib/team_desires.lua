-- Team Desires: High-level strategic coordination
local TeamDesires = {}
local GameIntelligence = require("lib/game_intelligence")
local GuideIntegration = require("lib/guide_integration")

-- Team-wide desire weights
TeamDesires.desires = {
    push_top = 0,
    push_mid = 0,
    push_bot = 0,
    roshan = 0,
    defend_top = 0,
    defend_mid = 0,
    defend_bot = 0,
    farm = 0,
    gank = 0,
    teamfight = 0,
    ward = 0,
    smoke = 0,
    human_gank = 0,  -- Coordinated gank on human players
}

-- Thresholds for activating desires
local THRESHOLDS = {
    push = 0.7,
    defend = 0.6,
    roshan = 0.75,
    teamfight = 0.65,
    smoke = 0.5,
    human_gank = 0.6,
}

function TeamDesires:Update()
    -- Reset desires
    for k, _ in pairs(self.desires) do
        self.desires[k] = 0
    end
    
    local radiant = (GetTeam() == DOTA_TEAM_GOODGUYS)
    local gameTime = DotaTime()
    local aliveAllies = self:GetAliveAllies()
    local aliveEnemies = self:GetAliveEnemies()
    local netWorthDiff = self:GetNetWorthDiff()
    local roshanAlive = self:IsRoshanAlive()
    
    -- Roshan desire
    if roshanAlive and #aliveAllies >= 3 then
        local roshanPower = self:CalculateRoshanPower(aliveAllies)
        if roshanPower > THRESHOLDS.roshan then
            self.desires.roshan = roshanPower
        end
    end
    
    -- Push desires per lane
    for _, lane in ipairs({LANE_TOP, LANE_MID, LANE_BOT}) do
        local pushPower = self:CalculatePushPower(lane, aliveAllies, aliveEnemies)
        local defendPower = self:CalculateDefendPower(lane, aliveAllies, aliveEnemies)
        
        if radiant then
            self.desires["push_" .. self:LaneName(lane)] = pushPower
            self.desires["defend_" .. self:LaneName(lane)] = defendPower
        else
            -- Dire pushes opposite lanes
            self.desires["push_" .. self:OppositeLane(lane)] = pushPower
            self.desires["defend_" .. self:OppositeLane(lane)] = defendPower
        end
    end
    
    -- Teamfight desire
    if #aliveAllies >= 4 and #aliveEnemies >= 3 then
        local tfPower = self:CalculateTeamfightPower(aliveAllies, aliveEnemies)
        if tfPower > THRESHOLDS.teamfight then
            self.desires.teamfight = tfPower
        end
    end
    
    -- Smoke gank desire
    if gameTime > 600 and gameTime < 1800 and #aliveAllies >= 3 then
        local smokePower = self:CalculateSmokePower(aliveAllies, aliveEnemies)
        if smokePower > THRESHOLDS.smoke then
            self.desires.smoke = smokePower
        end
    end
    
    -- Ward desire (supports)
    local supports = self:GetSupports(aliveAllies)
    if #supports > 0 then
        self.desires.ward = 0.5
    end
    
    -- Human gank desire - coordinated ganking of human players
    self:CalculateHumanGankDesire(aliveAllies, aliveEnemies)
    
    -- Human orders override
    self:ApplyHumanOrders()
end

function TeamDesires:CalculateHumanGankDesire(allies, enemies)
    -- Count human enemies
    local humanEnemies = {}
    local humanCores = {}
    for _, enemy in ipairs(enemies) do
        local playerID = enemy:GetPlayerID()
        if playerID and not PlayerResource:IsFakeClient(playerID) then
            table.insert(humanEnemies, enemy)
            local heroName = enemy:GetUnitName()
            if heroName:find("antimage") or heroName:find("phantom_assassin") or 
               heroName:find("spectre") or heroName:find("medusa") or
               heroName:find("invoker") or heroName:find("storm_spirit") or
               heroName:find("templar_assassin") or heroName:find("nevermore") or
               heroName:find("puck") or heroName:find("ember_spirit") or
               heroName:find("queenofpain") then
                table.insert(humanCores, enemy)
            end
        end
    end
    
    if #humanEnemies == 0 then return end
    
    local gameTime = DotaTime()
    local baseDesire = 0.3
    
    -- Higher desire for human cores
    if #humanCores > 0 then
        baseDesire = baseDesire + 0.25
    end
    
    -- More desire with more allies available
    local aliveCount = #allies
    if aliveCount >= 4 then
        baseDesire = baseDesire + 0.2
    elseif aliveCount >= 3 then
        baseDesire = baseDesire + 0.1
    end
    
    -- Check for smoke
    local hasSmoke = false
    for _, ally in ipairs(allies) do
        if ally:HasItem("item_smoke_of_deceit") then
            hasSmoke = true
            break
        end
    end
    if hasSmoke then
        baseDesire = baseDesire + 0.2
    end
    
    -- Time-based scaling (more aggressive mid-late game)
    if gameTime > 1200 then
        baseDesire = baseDesire + 0.15
    elseif gameTime > 600 then
        baseDesire = baseDesire + 0.1
    end
    
    -- Net worth advantage
    local netWorthDiff = self:GetNetWorthDiff()
    if netWorthDiff > 5000 then
        baseDesire = baseDesire + 0.1
    elseif netWorthDiff < -5000 then
        baseDesire = baseDesire - 0.1
    end
    
    self.desires.human_gank = math.min(math.max(baseDesire, 0), 1.0)
end

function TeamDesires:GetHighestDesire()
    local maxDesire = 0
    local maxKey = "farm"
    for k, v in pairs(self.desires) do
        if v > maxDesire then
            maxDesire = v
            maxKey = k
        end
    end
    return maxKey, maxDesire
end

function TeamDesires:GetAliveAllies()
    local allies = {}
    for _, hero in ipairs(GetTeamPlayers(GetTeam())) do
        if not hero:IsIllusion() and hero:IsAlive() then
            table.insert(allies, hero)
        end
    end
    return allies
end

function TeamDesires:GetAliveEnemies()
    local enemies = {}
    for _, hero in ipairs(GetTeamPlayers(GetOpposingTeam())) do
        if not hero:IsIllusion() and hero:IsAlive() then
            table.insert(enemies, hero)
        end
    end
    return enemies
end

function TeamDesires:GetNetWorthDiff()
    local radiantNW = GetTeamNetWorth(DOTA_TEAM_GOODGUYS)
    local direNW = GetTeamNetWorth(DOTA_TEAM_BADGUYS)
    return (GetTeam() == DOTA_TEAM_GOODGUYS) and (radiantNW - direNW) or (direNW - radiantNW)
end

function TeamDesires:IsRoshanAlive()
    local roshan = FindUnitsInRadius(GetTeam(), Vector(-2464, 1824, 0), nil, 500, 
        DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false)
    return #roshan > 0
end

function TeamDesires:CalculateRoshanPower(allies)
    local power = 0
    for _, hero in ipairs(allies) do
        power = power + hero:GetRawOffensivePower()
    end
    return math.min(power / 50000, 1.0)
end

function TeamDesires:CalculatePushPower(lane, allies, enemies)
    local laneAllies = 0
    local laneEnemies = 0
    for _, hero in ipairs(allies) do
        if hero:GetAssignedLane() == lane then laneAllies = laneAllies + 1 end
    end
    for _, hero in ipairs(enemies) do
        if hero:GetAssignedLane() == lane then laneEnemies = laneEnemies + 1 end
    end
    if laneAllies == 0 then return 0 end
    return math.min((laneAllies - laneEnemies) / 3.0 + 0.3, 1.0)
end

function TeamDesires:CalculateDefendPower(lane, allies, enemies)
    local laneEnemies = 0
    for _, hero in ipairs(enemies) do
        if hero:GetAssignedLane() == lane then laneEnemies = laneEnemies + 1 end
    end
    if laneEnemies == 0 then return 0 end
    return math.min(laneEnemies / 3.0, 1.0)
end

function TeamDesires:CalculateTeamfightPower(allies, enemies)
    local allyPower = 0
    local enemyPower = 0
    for _, hero in ipairs(allies) do
        allyPower = allyPower + hero:GetRawOffensivePower() * (hero:GetHealthPercent() / 100)
    end
    for _, hero in ipairs(enemies) do
        enemyPower = enemyPower + hero:GetRawOffensivePower() * (hero:GetHealthPercent() / 100)
    end
    if enemyPower == 0 then return 1 end
    return math.min(allyPower / enemyPower, 1.0)
end

function TeamDesires:CalculateSmokePower(allies, enemies)
    local invisible = 0
    for _, hero in ipairs(allies) do
        if hero:HasItem("item_smoke_of_deceit") then
            invisible = invisible + 1
        end
    end
    return math.min(invisible / 2.0, 1.0)
end

function TeamDesires:GetSupports(allies)
    local supports = {}
    for _, hero in ipairs(allies) do
        local role = hero:GetRole()
        if role == DOTA_BOT_ROAMING_SUPPORT or role == DOTA_BOT_HARD_SUPPORT then
            table.insert(supports, hero)
        end
    end
    return supports
end

function TeamDesires:LaneName(lane)
    if lane == LANE_TOP then return "top"
    elseif lane == LANE_MID then return "mid"
    else return "bot" end
end

function TeamDesires:OppositeLane(lane)
    if lane == LANE_TOP then return LANE_BOT
    elseif lane == LANE_BOT then return LANE_TOP
    else return LANE_MID end
end

function TeamDesires:ApplyHumanOrders()
    -- Human orders from GameIntelligence chat handler
    if GameIntelligence.humanOrder then
        local order = GameIntelligence.humanOrder
        if order.type == "push" and order.lane then
            self.desires["push_" .. order.lane] = 1.0
        elseif order.type == "defend" and order.lane then
            self.desires["defend_" .. order.lane] = 1.0
        elseif order.type == "roshan" then
            self.desires.roshan = 1.0
        elseif order.type == "ward" then
            self.desires.ward = 1.0
        elseif order.type == "smoke" then
            self.desires.smoke = 1.0
        elseif order.type == "teamfight" then
            self.desires.teamfight = 1.0
        elseif order.type == "gank" then
            self.desires.human_gank = 1.0
        end
        GameIntelligence.humanOrder = nil -- Consume
    end
end

function TeamDesires:OnThink()
    self:Update()
    local desire, value = self:GetHighestDesire()
    
    -- Broadcast to all bots via GameIntelligence
    if GameIntelligence.SetTeamDesire then
        GameIntelligence:SetTeamDesire(desire, value)
    end
end

-- Required Dota 2 API
function Think()
    TeamDesires:OnThink()
end

return TeamDesires