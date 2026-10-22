-- Farm mode: jungle and lane farming once laning stops being worth it.
--
-- Engine contract: GetDesire() is called EVERY FRAME for every mode file. The
-- highest desire wins and that mode's Think() runs. nil falls back to Valve's
-- built-in desire; 0 opts out entirely.
--
-- The previous version defined only a module method and a global
-- GetFarmAction(), neither of which the engine ever calls, so this mode could
-- never activate. The global GetDesire() and Think() below are what the
-- engine reads.
local BotLane = require("bot_lane")
local Compat = require("bot_compat")

local function NeutralTier(name)
    if name:find("ancient") then return 4 end
    if name:find("large") then return 3 end
    if name:find("medium") then return 2 end
    return 1
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    -- Low HP: retreat should win, not a neutral camp.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.4 then return 0 end

    -- Farming is the fallback: low desire, so laning and warding take priority.
    local desire = 0.25

    -- Early on the lane is the better place to be.
    if DotaTime() < 600 then desire = 0.15 end

    -- Carries want farm time more than supports do.
    local role = BotLane.GetRole(bot)
    if role == "carry" then desire = desire + 0.1
    elseif role == "support" then desire = desire - 0.1 end

    -- Nothing nearby to hit: farming has no target, let another mode run.
    if #Compat.NeutralCreeps(bot, 1500) == 0 then return 0 end

    return desire
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    -- Neutral creeps first: highest tier available.
    local neutrals = Compat.NeutralCreeps(bot, 1500)
    if #neutrals > 0 then
        local best, bestTier = nil, 0
        for _, creep in ipairs(neutrals) do
            local tier = NeutralTier(creep:GetUnitName())
            if tier > bestTier then
                best, bestTier = creep, tier
            end
        end
        if best then
            Compat.Attack(bot, best)
            return
        end
    end

    -- No neutrals: farm the lane wave, last-hitting.
    local laneCreeps = bot:GetNearbyLaneCreeps(800, true)
    if #laneCreeps > 0 then
        local best, lowest = nil, math.huge
        for _, creep in ipairs(laneCreeps) do
            local hp = creep:GetHealth()
            if hp < lowest and hp <= bot:GetAttackDamage() then
                best, lowest = creep, hp
            end
        end
        if best then
            Compat.Attack(bot, best)
            return
        end
    end

    -- Nothing to hit anywhere: hold the lane front.
    local pos = BotLane.FrontLocation(bot, 0)
    if pos then
        Compat.AttackMove(bot, pos)
    end
end

-- The engine calls the global GetDesire()/Think() above. Returning the table
-- as well lets the module be required and tested without the engine.
return {
    GetDesire = GetDesire,
    Think = Think,
}