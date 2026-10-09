-- Rune mode: contest power runes when they are worth the walk.
--
-- Engine contract: GetDesire runs every frame for every mode; nil falls back
-- to Valve's desire. Runes spawn on a fixed cadence, so desire has to be low
-- most of the time, otherwise the bot abandons lane permanently.
local POWER_RUNE_INTERVAL = 120  -- seconds between rune spawns

-- Rune locations worth walking to, in preference order.
local RUNE_SPOTS = {
    RUNE_POWERUP_1,
    RUNE_POWERUP_2,
}

local function AvailableRune()
    if not GetRuneStatus then return nil end
    for _, loc in ipairs(RUNE_SPOTS) do
        if loc and GetRuneStatus(loc) == RUNE_STATUS_AVAILABLE then
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

    -- Only worth it briefly around a spawn; otherwise fall back to lane work.
    local phase = now % POWER_RUNE_INTERVAL
    if phase > 60 then return nil end

    -- Carry and mid contest first; supports only bother for power runes.
    local desire = 0.45
    if bot:GetRole() == "support" then desire = 0.25 end

    -- Already know a rune is up: stronger pull.
    if AvailableRune() then desire = desire + 0.15 end

    -- Badly hurt: do not walk into a rune fight.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.35 then return 0 end

    return desire
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    -- Prefer a rune we know is sitting there.
    local loc = AvailableRune()
    if loc and GetRuneSpawnLocation then
        bot:Action_MoveToLocation(GetRuneSpawnLocation(loc))
        return
    end

    -- Unknown: contest mid, where power runes always spawn.
    local pos = GetLaneFrontLocation(GetTeam(), "mid", 0)
    if pos then
        bot:Action_MoveToLocation(pos)
    end
end