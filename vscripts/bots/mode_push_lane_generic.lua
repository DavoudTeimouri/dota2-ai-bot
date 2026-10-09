-- Push mode: take the lane forward when the wave is strong and we can win.
--
-- Engine contract: GetDesire() runs every frame for every mode file. nil falls
-- back to Valve's desire; 0 opts out. This must stay below retreat so a hurt
-- bot never pushes, and above laning only when the numbers justify it.
local function CountAllies(bot)
    if not bot.GetNearbyAlliedHeroes then return 0 end
    return #bot:GetNearbyAlliedHeroes(1800)
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    -- Hurt or outnumbered: retreat and shopping come first.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.5 then return 0 end

    local enemies = #bot:GetNearbyEnemyHeroes(1800, true)
    local allies = CountAllies(bot)
    if allies <= enemies then return 0 end

    -- Nothing to push with.
    if #bot:GetPushingWaves(800) == 0 then return nil end

    -- A big wave is the whole point of a push.
    if #bot:GetPushingWaves(800) < 2 then return nil end

    local desire = 0.5
    if allies >= enemies + 2 then desire = desire + 0.15 end
    if DotaTime() > 1200 then desire = desire + 0.1 end

    return desire
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    local lane = (bot.GetAssignedLane and bot:GetAssignedLane()) or "safe"

    -- Push to the far end of our lane, where the enemy tower is.
    local pos = GetLaneFrontLocation(GetTeam(), lane, 1000)
    if not pos then
        -- Lane name unknown to the map helper: fall back to mid.
        pos = GetLaneFrontLocation(GetTeam(), "mid", 1000)
    end
    if pos then
        bot:Action_AttackMove(pos)
    end
end