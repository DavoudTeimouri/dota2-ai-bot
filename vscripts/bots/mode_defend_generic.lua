-- Defend mode: go to the lane whose tier-1 tower is under attack.
--
-- Engine contract: GetDesire() runs every frame for every mode file. nil falls
-- back to Valve's desire; 0 opts out. This must stay below retreat and below
-- the fight modes, or a bot leaves a real fight to walk back to a tower.
--
-- The team decides whether defending is worth it: team_desires.lua's
-- UpdateDefendLaneDesires() returns the per-lane defend desire, and the
-- engine stores it where GetDefendLaneDesire(lane) reads it.
local BotLane = require("bot_lane")
local Compat = require("bot_compat")

-- The tier-1 tower constant for a lane.
local TOWER_CONST = {
    [BotLane.LANE_TOP] = _G.TOWER_TOP_1,
    [BotLane.LANE_MID] = _G.TOWER_MID_1,
    [BotLane.LANE_BOT] = _G.TOWER_BOT_1,
}

-- The enemy unit attacking the tier-1 tower of this lane, or nil.
local function TowerAttacker(team, lane)
    if not GetTowerAttackTarget then return nil end
    local const = TOWER_CONST[lane]
    if not const then return nil end
    local ok, target = pcall(GetTowerAttackTarget, team, const)
    if not ok or not target then return nil end
    if target.IsNull and target:IsNull() then return nil end
    -- A tower shooting a creep is not under pressure.
    if target.GetUnitName then
        local ok2, name = pcall(target.GetUnitName, target)
        if ok2 and name and not name:find("npc_dota_hero") then return nil end
    end
    return target
end

-- The position of the tier-1 tower of this lane, or nil.
local function TowerPosition(team, lane)
    if not GetTower then return nil end
    local const = TOWER_CONST[lane]
    if not const then return nil end
    local ok, tower = pcall(GetTower, team, const)
    if not ok or not tower then return nil end
    if tower.IsNull and tower:IsNull() then return nil end
    return Compat.Position(tower)
end

-- The team's defend desire for a lane.
local function TeamDefendDesire(lane)
    if not GetDefendLaneDesire then return nil end
    local ok, desire = pcall(GetDefendLaneDesire, lane)
    if ok and desire then return desire end
    return nil
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    -- Hurt: retreating beats defending a tower.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.5 then return 0 end

    local lane = BotLane.GetAssigned(bot)
    local team = bot:GetTeam()

    -- Nothing to defend.
    if not TowerAttacker(team, lane) then return 0 end

    -- The team decides how urgent this is.
    local teamDesire = TeamDefendDesire(lane)
    if not teamDesire or teamDesire < 0.2 then return 0 end

    -- A defending bot must not be alone in it.
    local enemies = #Compat.Enemies(bot, 1500)
    if enemies > #Compat.Allies(bot, 1500) + 1 then return 0 end

    return math.min(0.8, teamDesire)
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    local lane = BotLane.GetAssigned(bot)
    local team = bot:GetTeam()

    -- Hit the unit that is hitting our tower.
    local attacker = TowerAttacker(team, lane)
    if attacker then
        Compat.Attack(bot, attacker)
        return
    end

    -- Otherwise stand by the tower.
    local pos = TowerPosition(team, lane)
    if pos then
        Compat.MoveTo(bot, pos)
    end
end

-- The engine calls the global GetDesire()/Think() above. Returning the table
-- as well lets the module be required and tested without the engine.
return {
    GetDesire = GetDesire,
    Think = Think,
}
