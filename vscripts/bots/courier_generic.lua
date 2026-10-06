-- Courier generic
local Courier = {}
function Courier:CourierUsageThink(bot)
    -- stub
end
function CourierUsageThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        Courier:CourierUsageThink(bot)
    end
end