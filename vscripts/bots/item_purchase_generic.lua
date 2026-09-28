-- Item purchase think function (engine hook)
function ItemPurchaseThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        ItemPurchaseGeneric:PurchaseItem(bot)
    end
end

-- Item purchase module
local ItemPurchaseGeneric = {}

-- Generic item builds per role
local ITEM_BUILDS = {
    carry = {
        starting = {"item_quelling_blade", "item_tango", "item_flask", "item_gauntlets"},
        early = {"item_power_treads", "item_magic_wand", "item_wraith_band", "item_wraith_band"},
        core = {"item_maelstrom", "item_black_king_bar", "item_butterfly", "item_satanic"},
        luxury = {"item_monkey_king_bar", "item_skadi", "item_abyssal_blade", "item_moon_shard"},
    },
    mid = {
        starting = {"item_faerie_fire", "item_tango", "item_flask", "item_mantle"},
        early = {"item_power_treads", "item_magic_wand", "item_null_talisman", "item_bottle"},
        core = {"item_kaya", "item_orchid", "item_sheepstick", "item_shivas_guard"},
        luxury = {"item_octarine_core", "item_refresher", "item_bloodstone", "item_aeon_disk"},
    },
    offlane = {
        starting = {"item_quelling_blade", "item_tango", "item_flask", "item_ring_of_protection"},
        early = {"item_power_treads", "item_magic_wand", "item_bracer", "item_hood_of_defiance"},
        core = {"item_pipe", "item_crimson_guard", "item_shivas_guard", "item_heart"},
        luxury = {"item_assault", "item_lotus_orb", "item_aeon_disk", "item_shivas_guard"},
    },
    support = {
        starting = {"item_tango", "item_flask", "item_clarity", "item_enchanted_mango", "item_enchanted_mango", "item_enchanted_mango"},
        early = {"item_arcane_boots", "item_magic_wand", "item_glimmer_cape", "item_urn_of_shadows"},
        core = {"item_force_staff", "item_aeon_disk", "item_glimmer_cape", "item_lotus_orb"},
        luxury = {"item_octarine_core", "item_refresher", "item_shivas_guard", "item_guardian_greaves"},
    },
    hard_support = {
        starting = {"item_tango", "item_flask", "item_clarity", "item_enchanted_mango", "item_enchanted_mango", "item_enchanted_mango", "item_ward_observer"},
        early = {"item_arcane_boots", "item_magic_wand", "item_glimmer_cape", "item_urn_of_shadows"},
        core = {"item_force_staff", "item_aeon_disk", "item_glimmer_cape", "item_lotus_orb"},
        luxury = {"item_octarine_core", "item_refresher", "item_shivas_guard", "item_guardian_greaves"},
    },
}

-- Get role-based build
function ItemPurchaseGeneric:GetBuildForBot(bot)
    local role = bot:GetRole() or "carry"
    local lane = bot:GetAssignedLane() or "safe"
    
    if role == "mid" or lane == "mid" then return ITEM_BUILDS.mid end
    if role == "offlane" or lane == "off" then return ITEM_BUILDS.offlane end
    if role == "support" then
        if lane == "safe" then return ITEM_BUILDS.hard_support end
        return ITEM_BUILDS.support
    end
    return ITEM_BUILDS.carry
end

-- Purchase logic
function ItemPurchaseGeneric:PurchaseItem(bot)
    if bot:GetGold() < 50 then return end
    
    -- Buy courier if none
    if not self:HasCourier(bot) and bot:GetGold() >= 300 then
        bot:ActionImmediate_PurchaseItem("item_courier")
        return
    end
    
    -- Buy flying courier upgrade
    if self:HasCourier(bot) and not self:HasFlyingCourier(bot) and bot:GetGold() >= 400 then
        bot:ActionImmediate_PurchaseItem("item_flying_courier")
        return
    end
    
    local build = self:GetBuildForBot(bot)
    local allItems = {}
    
    -- Flatten build into purchase order
    for _, category in ipairs({"starting", "early", "core", "luxury"}) do
        for _, item in ipairs(build[category] or {}) do
            table.insert(allItems, item)
        end
    end
    
    -- Try to buy next item in build
    for _, itemName in ipairs(allItems) do
        local itemCost = GetItemCost(itemName)
        if itemCost and bot:GetGold() >= itemCost then
            -- Check if already have item
            local hasItem = false
            for i = 0, 14 do
                local item = bot:GetItemInSlot(i)
                if item and item:GetName() == itemName then
                    hasItem = true
                    break
                end
            end
            if not hasItem then
                bot:ActionImmediate_PurchaseItem(itemName)
                return
            end
        end
    end
    
    -- Buy TP scrolls
    if bot:GetGold() >= 75 then
        local hasTP = false
        for i = 0, 14 do
            local item = bot:GetItemInSlot(i)
            if item and (item:GetName() == "item_tpscroll" or item:GetName() == "item_travel_boots" or item:GetName() == "item_travel_boots_2") then
                hasTP = true
                break
            end
        end
        if not hasTP then
            bot:ActionImmediate_PurchaseItem("item_tpscroll")
        end
    end
    
    -- Buy wards as support
    local role = bot:GetRole()
    if (role == "support" or role == "hard_support") and bot:GetGold() >= 50 then
        local obsWards = bot:GetItemCount("item_ward_observer")
        local sentWards = bot:GetItemCount("item_ward_sentry")
        if obsWards < 2 and bot:GetGold() >= 50 then
            bot:ActionImmediate_PurchaseItem("item_ward_observer")
        elseif sentWards < 1 and bot:GetGold() >= 50 then
            bot:ActionImmediate_PurchaseItem("item_ward_sentry")
        end
    end
end

-- Check for courier
function ItemPurchaseGeneric:HasCourier(bot)
    -- This is simplified - in reality would check team courier
    return false
end

function ItemPurchaseGeneric:HasFlyingCourier(bot)
    return false
end

return ItemPurchaseGeneric