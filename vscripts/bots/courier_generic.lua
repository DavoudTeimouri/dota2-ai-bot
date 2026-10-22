-- Courier generic
-- Engine hook: CourierUsageThink(). Two jobs:
--   1. Deliver the stashed starting items to the bot once.
--   2. Later, use the courier to carry items to a teammate who needs them
--      but cannot come to the shop.
--
-- API (from the Dota 2 bot reference):
--   GetCourier(nIndex)                              -- global, 0-indexed
--   GetCourierState(hCourier)                       -- COURIER_STATE_*
--   IsCourierAvailable() / GetNumCouriers()
--   bot:ActionImmediate_Courier(hCourier, nAction)   -- COURIER_ACTION_*
--   bot:GetStashValue() / bot:GetCourierValue()
--
-- Older bot scripts expose the courier as bot:GetCourier() and deliver with
-- courier:ActionImmediate_Pickup(). Both shapes are supported here.
local Courier = {}

-- Bots that have already picked up their starting stash items.
local delivered = {}

-- COURIER_STATE_IDLE: the courier is at base with nothing to do.
local STATE_IDLE = _G.COURIER_STATE_IDLE
-- COURIER_ACTION_TAKE_AND_TRANSFER_ITEMS: pick the stash up and bring it over.
local ACTION_TRANSFER = _G.COURIER_ACTION_TAKE_AND_TRANSFER_ITEMS

-- The team's courier, or nil. Tries the global accessor first, then the
-- per-bot one. Named differently from the global GetCourier on purpose:
-- a local with the same name would shadow it and recurse.
local function GetTeamCourier(bot)
    if type(GetCourier) == "function" then
        local ok, courier = pcall(GetCourier, 0)
        if ok and courier and not courier:IsNull() then return courier end
    end
    if bot and bot.GetCourier then
        local ok, courier = pcall(bot.GetCourier, bot)
        if ok and courier and not courier:IsNull() then return courier end
    end
    return nil
end

-- Is the courier parked at base and free to be given an order?
local function CourierIsIdle(courier)
    if not GetCourierState then return true end
    if STATE_IDLE == nil then return true end
    local ok, state = pcall(GetCourierState, courier)
    if not ok then return true end
    return state == STATE_IDLE
end

-- Order the courier to bring the bot's stash over. Returns true when the
-- order was actually given.
local function OrderTransfer(bot, courier)
    -- Preferred: the documented courier action.
    if bot.ActionImmediate_Courier and ACTION_TRANSFER then
        local ok = pcall(bot.ActionImmediate_Courier, bot, courier, ACTION_TRANSFER)
        if ok then return true end
    end
    -- Fallback: older scripts drive the courier directly.
    if courier.ActionImmediate_Pickup then
        local ok = pcall(courier.ActionImmediate_Pickup, courier)
        if ok then return true end
    end
    return false
end

-- Value of the items waiting on the courier for this bot.
local function CourierValue(bot)
    if bot.GetCourierValue then
        local ok, value = pcall(bot.GetCourierValue, bot)
        if ok and value then return value end
    end
    return 0
end

-- Value of the items in this bot's own stash.
local function StashValue(bot)
    if bot.GetStashValue then
        local ok, value = pcall(bot.GetStashValue, bot)
        if ok and value then return value end
    end
    return 0
end

-- Deliver the starting items. Runs once per bot.
local function DeliverStartingItems(bot)
    if delivered[bot] then return end
    delivered[bot] = true

    -- Nothing to deliver before the horn. DotaTime is missing in the offline
    -- test harness, so treat an absent clock as "already in game".
    if DotaTime and DotaTime() < 0 then return end

    if StashValue(bot) <= 0 then return end

    local courier = GetTeamCourier(bot)
    if not courier then return end
    if not CourierIsIdle(courier) then return end

    OrderTransfer(bot, courier)
end

-- A teammate who would benefit from the courier: low on consumables and
-- far from the shop. Returns the bot handle or nil.
local function FindNeedyAlly(bot)
    local Compat = require("bot_compat")
    local allies = Compat.Allies(bot, 50000)
    local best, bestNeed = nil, 0
    for _, ally in ipairs(allies) do
        if ally and not ally:IsNull() and ally:IsAlive() then
            -- Needs a ward, and is not sitting in the fountain.
            local wantsWard = not Compat.HasItem(ally, "item_ward_observer")
                and not Compat.HasItem(ally, "item_ward_sentry")
            if wantsWard then
                local far = 0
                if ally.DistanceFromFountain then
                    local ok, d = pcall(ally.DistanceFromFountain, ally)
                    if ok and d then far = d end
                end
                if far > 2000 and far > bestNeed then
                    best, bestNeed = ally, far
                end
            end
        end
    end
    return best
end

-- Later game: run items to a teammate who needs them.
local function DeliverToAlly(bot)
    if not bot.ActionImmediate_Courier then return end
    if not ACTION_TRANSFER then return end
    if CourierValue(bot) <= 0 then return end

    local courier = GetTeamCourier(bot)
    if not courier then return end
    if not CourierIsIdle(courier) then return end

    local ally = FindNeedyAlly(bot)
    if not ally then return end

    -- The courier action transfers this bot's stash to the courier; the
    -- engine then routes it. Only order it when a teammate can use it.
    local ok = pcall(bot.ActionImmediate_Courier, bot, courier, ACTION_TRANSFER)
    return ok
end

function Courier:CourierUsageThink(bot)
    if not bot or bot:IsNull() then return end

    -- Starting items first: they are the highest value delivery.
    if not delivered[bot] then
        DeliverStartingItems(bot)
        return
    end

    -- Then help teammates who are stuck in lane without consumables.
    DeliverToAlly(bot)
end

-- The CourierUsageThink() hook lives in ability_item_usage_generic.lua,
-- because that is the file the engine reads it from. Defining it here as
-- well would be a second global with the same name in a file the engine
-- never loads.
return Courier