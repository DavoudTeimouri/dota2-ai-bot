-- Ward mode: plant vision where it pays off.
--
-- Engine contract: GetDesire runs every frame for every mode; nil falls back
-- to Valve's desire. A support with no wards must return nil (not 0) so
-- Valve's built-in warding takes over instead of leaving the bot passive.
local BotLane = require("bot_lane")
local Compat = require("bot_compat")

local function HasObserver(bot)
    return Compat.HasItem(bot, "item_ward_observer")
        or Compat.HasItem(bot, "item_ward_sentry")
end

-- Known warding spots by lane: {x, y} offsets from lane front toward river/jungle.
-- These are safe, commonly useful spots (rune entrances, jungle paths).
local WARDSPOTS = {
    [BotLane.LANE_BOT] = { { x = 700,  y = 1200 }, { x = -400, y = 2800 } },
    [BotLane.LANE_MID] = { { x = -1200, y = 1200 }, { x = 1200,  y = -1200 } },
    [BotLane.LANE_TOP] = { { x = -2800, y = -400 }, { x = -1200, y = -700 } },
}

local function GetWardSpot(bot)
    local lane = BotLane.GetAssigned(bot)
    local spots = WARDSPOTS[lane] or WARDSPOTS[BotLane.LANE_BOT]
    local pos = Compat.Position(bot)
    if not pos then return spots[1] end
    -- Pick the spot closest to the bot so it doesn't walk halfway across map.
    local best, bestDist = nil, math.huge
    for _, spot in ipairs(spots) do
        local dx = spot.x - pos.x
        local dy = spot.y - pos.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d < bestDist then
            bestDist = d
            best = spot
        end
    end
    return best
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    -- Only wards with something to plant.
    if not HasObserver(bot) then return nil end

    -- Very low HP: warding gets you killed, retreat should win.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.35 then return 0 end

    local desire = 0.5

    -- Carry/mid have better things to do than sitting on sentries.
    local role = BotLane.GetRole(bot)
    if role == "carry" then desire = 0.2
    elseif role == "mid" then desire = 0.3 end

    -- Standing in fountain with spare wards is a good time to place them.
    if bot:DistanceFromFountain() == 0 then desire = desire + 0.2 end

    -- If enemies are visible nearby, fight mode should win.
    if #Compat.Enemies(bot, 1200) > 0 then
        desire = desire - 0.3
    end

    if desire <= 0 then return nil end
    return desire
end

-- Resolve a ward handle by name; the slot is not fixed.
local function FindWard(bot)
    local ward = Compat.ItemByName(bot, "item_ward_observer")
    if ward then return ward end
    return Compat.ItemByName(bot, "item_ward_sentry")
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    local ward = FindWard(bot)
    if not ward then return end

    -- Place at a known ward spot near the bot's lane, not blindly at lane front.
    local spot = GetWardSpot(bot)
    if spot then
        Compat.UseAbility(bot, ward, spot)
    end
end

-- The engine calls the global GetDesire()/Think() above. Returning the table
-- as well lets the module be required and tested without the engine.
return {
    GetDesire = GetDesire,
    Think = Think,
}