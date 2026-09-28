-- Courier usage think function (engine hook)
function CourierUsageThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        CourierGeneric:CourierUsageThink(bot)
    end
end

-- Courier module
local CourierGeneric = {}

-- Courier states
CourierGeneric.STATE_IDLE = 0
CourierGeneric.STATE_DELIVERING = 1
CourierGeneric.STATE_RETURNING = 2
CourierGeneric.STATE_FILLING = 3

CourierGeneric.courierState = CourierGeneric.STATE_IDLE
CourierGeneric.lastStateChange = 0
CourierGeneric.deliveryTarget = nil
CourierGeneric.itemsToDeliver = {}

-- Main courier think
function CourierGeneric:CourierUsageThink(bot)
    local courier = GetCourier(0)
    if not courier or courier:IsNull() then return end
    
    local gameTime = GameRules:GetGameTime()
    
    -- Handle courier state machine
    if self.courierState == self.STATE_IDLE then
        self:CheckForDeliveryRequests(bot, courier)
    elseif self.courierState == self.STATE_DELIVERING then
        self:HandleDelivery(bot, courier)
    elseif self.courierState == self.STATE_RETURNING then
        self:HandleReturn(courier)
    elseif self.courierState == self.STATE_FILLING then
        self:HandleFilling(courier)
    end
    
    -- Upgrade to flying courier at 3 min
    if gameTime > 180 and not courier:HasFlyingCourier() then
        local flyingCourier = GetItemByName("item_flying_courier")
        if flyingCourier then
            courier:ActionImmediate_PurchaseItem("item_flying_courier")
        end
    end
end

-- Check if any bot needs items delivered
function CourierGeneric:CheckForDeliveryRequests(bot, courier)
    -- Check this bot's inventory for items at stash
    local stashItems = {}
    for i = 9, 14 do
        local item = bot:GetItemInSlot(i)
        if item then
            table.insert(stashItems, item)
        end
    end
    
    if #stashItems > 0 then
        -- Check if courier is near base
        local fountain = GetFountain()
        if fountain and (courier:GetLocation() - fountain:GetLocation()):Length2D() < 1500 then
            self.courierState = self.STATE_FILLING
            self.itemsToDeliver = stashItems
            self.deliveryTarget = bot
            self.lastStateChange = GameRules:GetGameTime()
        else
            -- Call courier
            courier:Action_MoveToLocation(GetFountain():GetLocation())
        end
    end
    
    -- Check if need to retrieve items from secret shop
    if bot.secretShopItems and #bot.secretShopItems > 0 then
        -- TODO: implement secret shop retrieval
    end
end

-- Fill courier with items
function CourierGeneric:HandleFilling(courier)
    if not self.deliveryTarget or self.deliveryTarget:IsNull() then
        self.courierState = self.STATE_RETURNING
        return
    end
    
    -- Transfer items from stash to courier
    local target = self.deliveryTarget
    for i = 9, 14 do
        local item = target:GetItemInSlot(i)
        if item then
            courier:Action_TakeStashItem(item)
        end
    end
    
    -- Small delay then start delivery
    if GameRules:GetGameTime() - self.lastStateChange > 0.5 then
        self.courierState = self.STATE_DELIVERING
        self.lastStateChange = GameRules:GetGameTime()
    end
end

-- Deliver items to target
function CourierGeneric:HandleDelivery(bot, courier)
    if not self.deliveryTarget or self.deliveryTarget:IsNull() then
        self.courierState = self.STATE_RETURNING
        return
    end
    
    local target = self.deliveryTarget
    
    -- If target dead, return
    if not target:IsAlive() then
        self.courierState = self.STATE_RETURNING
        return
    end
    
    -- Move to target
    courier:Action_MoveToUnit(target)
    
    -- Check if close enough to deliver
    local dist = (courier:GetLocation() - target:GetLocation()):Length2D()
    if dist < 500 then
        -- Transfer items
        for i = 0, 8 do
            local item = courier:GetItemInSlot(i)
            if item then
                courier:Action_GiveItem(target, item)
            end
        end
        self.courierState = self.STATE_RETURNING
        self.lastStateChange = GameRules:GetGameTime()
    end
    
    -- Timeout - return if taking too long
    if GameRules:GetGameTime() - self.lastStateChange > 30 then
        self.courierState = self.STATE_RETURNING
    end
end

-- Return to base
function CourierGeneric:HandleReturn(courier)
    local fountain = GetFountain()
    if fountain then
        courier:Action_MoveToLocation(fountain:GetLocation())
        
        local dist = (courier:GetLocation() - fountain:GetLocation()):Length2D()
        if dist < 500 then
            self.courierState = self.STATE_IDLE
            self.itemsToDeliver = {}
            self.deliveryTarget = nil
        end
    end
end

return CourierGeneric