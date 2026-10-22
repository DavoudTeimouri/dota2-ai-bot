-- Rune mode: contest power and bounty runes when they are worth the walk.
--
-- Engine contract: GetDesire runs every frame for every mode; nil falls back
-- to Valve's desire. Runes spawn on a fixed cadence, so desire has to be low
-- most of the time, otherwise the bot abandons lane permanently.
local POWER_RUNE_INTERVAL = 120  -- seconds between power rune spawns
local BOUNTY_RUNE_INTERVAL = 300 -- seconds between bounty rune spawns

-- Rune locations worth walking to, in preference order.
local RUNE_SPOTS = {
    RUNE_POWERUP_1,
    RUNE_POWERUP_2,
}

local BOUNTY_SPOTS = {
    RUNE_BOUNTY_1,
    RUNE_BOUNTY_2,
    RUNE_BOUNTY_3,
    RUNE_BOUNTY_4,
}

local BotLane = require("bot_lane")

local function AvailableRune(locList, statusCheck)
    if not GetRuneStatus then return nil end
    for _, loc in ipairs(locList) do
        if loc and GetRuneStatus(loc) == statusCheck then
            return loc
        end
    end
    return nil
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    local now = DotaTime()
    if now < 0 then return nil end

    -- Power runes: worth contesting briefly around spawn (first 60s of 2-min cycle).
    local powerPhase = now % POWER_RUNE_INTERVAL
    local powerDesire = 0
    if powerPhase <= 60 then
        powerDesire = 0.45
        if BotLane.GetRole(bot) == "support" then powerDesire = 0.25 end
        if AvailableRune(RUNE_SPOTS, RUNE_STATUS_AVAILABLE) then
            powerDesire = powerDesire + 0.15
        end
    end

    -- Bounty runes: worth contesting briefly around spawn (first 60s of 5-min cycle).
    local bountyPhase = now % BOUNTY_RUNE_INTERVAL
    local bountyDesire = 0
    if bountyPhase <= 60 then
        bountyDesire = 0.35
        if AvailableRune(BOUNTY_SPOTS, RUNE_STATUS_AVAILABLE) then
            bountyDesire = bountyDesire + 0.1
        end
    end

    -- Badly hurt: do not walk into a rune fight.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.35 then return 0 end

    local desire = math.max(powerDesire, bountyDesire)
    if desire <= 0 then return nil end
    return desire
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    -- Prefer a power rune we know is sitting there.
    local loc = AvailableRune(RUNE_SPOTS, RUNE_STATUS_AVAILABLE)
    if loc and GetRuneSpawnLocation then
        bot:Action_MoveToLocation(GetRuneSpawnLocation(loc))
        return
    end

    -- Otherwise a bounty rune.
    loc = AvailableRune(BOUNTY_SPOTS, RUNE_STATUS_AVAILABLE)
    if loc and GetRuneSpawnLocation then
        bot:Action_MoveToLocation(GetRuneSpawnLocation(loc))
        return
    end

    -- Unknown: contest mid, where power runes always spawn.
    if GetLaneFrontLocation then
        local pos = GetLaneFrontLocation(bot:GetTeam(), BotLane.LANE_MID, 0)
        if pos then
            bot:Action_MoveToLocation(pos)
        end
    end
end