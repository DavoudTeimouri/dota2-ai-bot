-- Retreat mode: disengage when low and outnumbered.
--
-- Engine contract: GetDesire() runs every frame for every mode file. nil falls
-- back to Valve's desire; 0 opts out. Returning a high value here must beat the
-- other modes, otherwise a dying bot keeps trying to last hit.
local function CountAllies(bot)
    if not bot.GetNearbyAlliedHeroes then return 0 end
    return #bot:GetNearbyAlliedHeroes(1600)
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    local enemies = #bot:GetNearbyEnemyHeroes(1600, true)
    local allies = CountAllies(bot)

    local danger = 0
    if hpPct < 0.2 then danger = danger + 0.5
    elseif hpPct < 0.35 then danger = danger + 0.3 end

    if enemies > allies then danger = danger + 0.2 end

    -- Outnumbered and hurt is the real panic case.
    if hpPct < 0.4 and enemies >= allies + 2 then danger = danger + 0.3 end

    if danger <= 0 then return nil end
    if danger > 1.0 then danger = 1.0 end

    -- Shopping wants 0.5, so a bot that is only mildly worried keeps shopping
    -- and a badly hurt one retreats instead.
    return danger
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    -- Walk away from the nearest enemy. Bot origin minus enemy direction.
    local enemies = bot:GetNearbyEnemyHeroes(1600, true)
    if #enemies == 0 then
        -- Nothing chasing: go home and heal.
        if GetShopLocation then
            local home = GetShopLocation(bot:GetTeam(), SHOP_HOME)
            if home then bot:Action_MoveToLocation(home) end
        end
        return
    end

    local pos = bot:GetAbsOrigin()
    local epos = enemies[1]:GetAbsOrigin()
    local dx = pos.x - epos.x
    local dy = pos.y - epos.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end

    local away = Vector(pos.x + (dx / len) * 1200, pos.y + (dy / len) * 1200)
    if away then
        bot:Action_MoveToLocation(away)
    end
end