-- Retreat mode: disengage when low and outnumbered.
--
-- Engine contract: GetDesire() runs every frame for every mode file. nil falls
-- back to Valve's desire; 0 opts out. Returning a high value here must beat the
-- other modes, otherwise a dying bot keeps trying to last hit.
local BotLane = require("bot_lane")
local Compat = require("bot_compat")

local function CountAllies(bot)
    return #Compat.Allies(bot, 1600)
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    local enemies = #Compat.Enemies(bot, 1600)
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
    local enemies = Compat.Enemies(bot, 1600)
    if #enemies == 0 then
        -- Nothing chasing: go home and heal.
        if GetShopLocation then
            -- SHOP_HOME is provided by the Dota 2 VM; guard against absence.
            local shopHome = _G.SHOP_HOME or 0
            local home = GetShopLocation(bot:GetTeam(), shopHome)
            if home then Compat.MoveTo(bot, home) end
        end
        return
    end

    local pos = Compat.Position(bot)
    local epos = Compat.Position(enemies[1])
    if not pos or not epos then return end
    local dx = pos.x - epos.x
    local dy = pos.y - epos.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end

    local awayX = pos.x + (dx / len) * 1200
    local awayY = pos.y + (dy / len) * 1200
    local away
    if Vector then
        away = Vector(awayX, awayY)
    else
        away = { x = awayX, y = awayY }
    end
    if away then
        Compat.MoveTo(bot, away)
    end
end

-- The engine calls the global GetDesire()/Think() above. Returning the table
-- as well lets the module be required and tested without the engine.
return {
    GetDesire = GetDesire,
    Think = Think,
}