-- Courier generic
-- Engine hook: CourierUsageThink(). Deliver the stashed starting items to the
-- bot once, then do nothing. Full courier routing is Valve's job.
local Courier = {}

-- Bots that have already picked up their stash items.
local delivered = {}

function Courier:CourierUsageThink(bot)
    if not bot or bot:IsNull() then return end

    -- Nothing to deliver before the horn. DotaTime is missing in the offline
    -- test harness, so treat an absent clock as "already in game".
    if DotaTime and DotaTime() < 0 then return end

    -- Key on the bot handle itself; GetPlayerID is not always present.
    if delivered[bot] then return end
    delivered[bot] = true

    -- A bot without a courier (or before one spawns) has nothing to do.
    if not bot.GetCourier then return end
    local courier = bot:GetCourier()
    if not courier or courier:IsNull() then return end
    if not courier.ActionImmediate_Pickup then return end
    if bot:GetStashValue() <= 0 then return end

    -- Pick up whatever is on the courier, then stay out of the way.
    courier:ActionImmediate_Pickup()
end

-- Engine hook. Declared after the local table on purpose.
function CourierUsageThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        Courier:CourierUsageThink(bot)
    end
end

return Courier