-- Laning mode: hold the assigned lane, last hit, and deny when the wave is near.
--
-- Engine contract (Valve):
--   GetDesire() is called EVERY FRAME for EVERY mode file. The highest desire
--   wins and that mode's Think() runs; nil falls back to Valve's own desire.
--   So GetDesire must be cheap and must never throw.
--
-- Lane roles. Support needs to leave lane to pull and ward, so its desire
-- drops off as soon as it has something to do.
local LANE_ROLES = {
    safe    = { pos = 1, name = "safe" },
    mid     = { pos = 2, name = "mid" },
    off     = { pos = 3, name = "off" },
    offlane = { pos = 3, name = "off" },
    support = { pos = 5, name = "safe" },
}

local function IsReadyToFarm(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return false end
    if bot:GetHealth() < bot:GetMaxHealth() * 0.25 then return false end
    return true
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end
    if bot:GetHealth() < bot:GetMaxHealth() * 0.25 then return 0 end

    local lane = (bot.GetAssignedLane and bot:GetAssignedLane()) or "safe"
    local info = LANE_ROLES[lane] or LANE_ROLES.safe
    local desire = 0.4

    -- Supports want to ward and roam, not stand on the wave.
    if info.pos == 5 then desire = 0.2 end

    -- Give way when badly hurt so retreat/push can win.
    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    if hpPct < 0.5 then desire = desire * 0.5 end

    -- Supports with an unplaced observer want the ward mode to win instead.
    if info.pos == 5 and bot:GetAvailableWards() > 0 then
        desire = desire * 0.5
    end

    return desire
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not IsReadyToFarm(bot) then return end

    local lane = (bot.GetAssignedLane and bot:GetAssignedLane()) or "safe"

    -- Last hit: only swing when the creep dies to it.
    local laneCreeps = bot:GetNearbyLaneCreeps(800, true)
    if #laneCreeps > 0 then
        local best, lowest = nil, math.huge
        for _, creep in ipairs(laneCreeps) do
            local hp = creep:GetHealth()
            if hp < lowest and hp <= bot:GetAttackDamage() then
                best, lowest = creep, hp
            end
        end
        -- No clean last hit: do not feed, hold position in lane.
        if best then
            bot:AttackTarget(best)
            return
        end
    end

    -- Nothing to hit: walk to the front of our lane.
    local pos = GetLaneFrontLocation(GetTeam(), lane, 0)
    if pos then
        bot:Action_AttackMove(pos)
    end
end