-- Courier System for AetherWeaver

local Courier = {}

function Courier:Think(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    local courier = bot:GetCourier(0)
    if not courier or courier:IsNull() then return end
    
    local gameTime = DotaTime()
    
    -- Upgrade courier at 3 minutes
    if gameTime > 180 and not courier:HasFlyingCourier() then
        if bot:GetGold() >= 400 then
            bot:ActionImmediate_PurchaseItem("item_flying_courier")
        end
    end
    
    -- Use courier to deliver items
    if courier:IsIdle() then
        -- Transfer items from stash
        bot:ActionImmediate_Courier(courier, COURIER_ACTION_TRANSFER_ITEMS)
    end
end

return Courier