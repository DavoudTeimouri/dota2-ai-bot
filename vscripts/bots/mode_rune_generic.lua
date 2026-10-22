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
local Compat = require("bot_compat")

-- Which bot has claimed which rune. The file is loaded once and the hooks
-- run for every bot, so this table is shared across the team: without it
-- every bot walks to the same rune.
local claimed = {}

local function AvailableRune(locList, statusCheck)
    if not GetRuneStatus then return nil end
    for _, loc in ipairs(locList) do
        if loc and GetRuneStatus(loc) == statusCheck then
            return loc
        end
    end
    return nil
end

-- An available rune in the list that no other bot has claimed.
local function FreeRune(locList, statusCheck, bot)
    if not GetRuneStatus then return nil end
    for _, loc in ipairs(locList) do
        if loc and GetRuneStatus(loc) == statusCheck then
            local owner = claimed[loc]
            if not owner or owner == bot then return loc end
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

-- Drop claims on runes that are gone, so the next spawn at the same spot is
-- free again.
local function ReleaseStaleClaims()
    if not GetRuneStatus then return end
    for loc in pairs(claimed) do
        if GetRuneStatus(loc) ~= RUNE_STATUS_AVAILABLE then
            claimed[loc] = nil
        end
    end
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    ReleaseStaleClaims()

    -- A power rune buffs the whole team, so only one bot needs to take it.
    -- The mid claims it: it is closest to both power rune spots.
    if BotLane.GetRole(bot) == "mid" then
        local power = FreeRune(RUNE_SPOTS, RUNE_STATUS_AVAILABLE, bot)
        if power and GetRuneSpawnLocation then
            claimed[power] = bot
            Compat.MoveTo(bot, GetRuneSpawnLocation(power))
            return
        end
    end

    -- A bounty rune is worth a different bot each time, so spread the team
    -- over the available spots.
    local bounty = FreeRune(BOUNTY_SPOTS, RUNE_STATUS_AVAILABLE, bot)
    if bounty and GetRuneSpawnLocation then
        claimed[bounty] = bot
        Compat.MoveTo(bot, GetRuneSpawnLocation(bounty))
        return
    end

    -- Unknown: contest mid, where power runes always spawn.
    if GetLaneFrontLocation then
        local pos = GetLaneFrontLocation(bot:GetTeam(), BotLane.LANE_MID, 0)
        if pos then
            Compat.MoveTo(bot, pos)
        end
    end
end

-- The engine calls the global GetDesire()/Think() above. Returning the table
-- as well lets the module be required and tested without the engine.
return {
    GetDesire = GetDesire,
    Think = Think,
}