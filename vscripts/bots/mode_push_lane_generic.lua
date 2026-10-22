-- Push mode: take the lane forward when the wave is strong and we can win.
--
-- Engine contract: GetDesire() runs every frame for every mode file. nil falls
-- back to Valve's desire; 0 opts out. This must stay below retreat so a hurt
-- bot never pushes, and above laning only when the numbers justify it.
local BotLane = require("bot_lane")
local Compat = require("bot_compat")

local function CountAllies(bot)
    return #Compat.Allies(bot, 1800)
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    -- Hurt or outnumbered: retreat and shopping come first.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.5 then return 0 end

    local enemies = #Compat.Enemies(bot, 1800)
    local allies = CountAllies(bot)
    if allies <= enemies then return 0 end

    -- Nothing to push with.
    local pushingWaves = #Compat.PushingWaves(bot, 800)
    if pushingWaves == 0 then return nil end

    -- A big wave is the whole point of a push.
    if pushingWaves < 2 then return nil end

    local desire = 0.5
    if allies >= enemies + 2 then desire = desire + 0.15 end
    if DotaTime() > 1200 then desire = desire + 0.1 end

    return desire
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    -- Push to the far end of our lane, where the enemy tower is.
    local pos = BotLane.FrontLocation(bot, 1000)
    if not pos then
        -- Lane name unknown to the map helper: fall back to mid.
        if GetLaneFrontLocation then
            pos = GetLaneFrontLocation(bot:GetTeam(), BotLane.LANE_MID, 1000)
        end
    end
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