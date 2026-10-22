-- AetherWeaver lane and role helpers.
--
-- The Dota 2 bot scripting API exposes lanes as INT constants:
--   LANE_TOP = 1, LANE_MID = 2, LANE_BOT = 3
-- GetAssignedLane() returns one of those ints, and GetLaneFrontLocation()
-- and SetAssignedLane() take them.
--
-- Older code (and some tools) use the string names "safe" / "mid" / "off" /
-- "top" / "bot" instead, so every value here is normalised to an int. A
-- string lane was previously looked up in a table keyed by strings, so an int
-- lane silently fell through to the safe lane and the bot farmed the wrong
-- side of the map.
--
-- Role: bot:GetRole() is not present in every Dota 2 VM build, so the role is
-- derived from the assigned lane when it is missing or returns an unknown
-- value. Lane -> role mapping: mid -> mid, safe -> carry, off -> offlane.

local BotLane = {}

BotLane.LANE_TOP = 1
BotLane.LANE_MID = 2
BotLane.LANE_BOT = 3

-- String lane names mapped to the int constants.
local STRING_LANES = {
    top   = BotLane.LANE_TOP,
    bot   = BotLane.LANE_BOT,
    mid   = BotLane.LANE_MID,
    -- "safe" is the bottom lane for Radiant and the top lane for Dire;
    -- callers that need that distinction use SafeLaneForTeam().
    safe  = BotLane.LANE_BOT,
    off   = BotLane.LANE_TOP,
}

-- Normalise any lane representation to an int constant.
function BotLane.ToInt(lane)
    if type(lane) == "number" then
        if lane >= BotLane.LANE_TOP and lane <= BotLane.LANE_BOT then
            return lane
        end
        return BotLane.LANE_MID
    end
    if type(lane) == "string" then
        return STRING_LANES[lane:lower()] or BotLane.LANE_MID
    end
    return BotLane.LANE_MID
end

-- The bot's assigned lane as an int constant.
function BotLane.GetAssigned(bot)
    if not bot or bot:IsNull() then return BotLane.LANE_MID end
    if not bot.GetAssignedLane then return BotLane.LANE_MID end
    return BotLane.ToInt(bot:GetAssignedLane())
end

-- The safe lane for a team: Radiant safe is bottom, Dire safe is top.
function BotLane.SafeLaneForTeam(team)
    -- TEAM_RADIANT = 2, TEAM_DIRE = 3
    if team == 3 then return BotLane.LANE_TOP end
    return BotLane.LANE_BOT
end

-- The offlane for a team: Radiant off is top, Dire off is bottom.
function BotLane.OffLaneForTeam(team)
    if team == 3 then return BotLane.LANE_BOT end
    return BotLane.LANE_TOP
end

-- Lane -> role, used when bot:GetRole() is unavailable.
local LANE_ROLE = {
    [BotLane.LANE_MID] = "mid",
    [BotLane.LANE_BOT] = "carry",
    [BotLane.LANE_TOP] = "offlane",
}

-- The bot's role: "carry", "mid", "offlane" or "support".
-- Prefers bot:GetRole() when the VM provides it and it returns a known value;
-- otherwise falls back to the lane.
function BotLane.GetRole(bot)
    if not bot or bot:IsNull() then return "carry" end

    if bot.GetRole then
        local role = bot:GetRole()
        if role == "carry" or role == "mid" or role == "offlane" or role == "support" then
            return role
        end
    end

    local lane = BotLane.GetAssigned(bot)
    local role = LANE_ROLE[lane] or "carry"
    return role
end

-- Set the bot's lane using the int constant the API expects.
function BotLane.Set(bot, lane)
    if not bot or bot:IsNull() then return end
    if not bot.SetAssignedLane then return end
    bot:SetAssignedLane(BotLane.ToInt(lane))
end

-- Lane front position for the bot's current lane.
function BotLane.FrontLocation(bot, delta)
    if not GetLaneFrontLocation then return nil end
    local lane = BotLane.GetAssigned(bot)
    return GetLaneFrontLocation(bot:GetTeam(), lane, delta or 0)
end

return BotLane