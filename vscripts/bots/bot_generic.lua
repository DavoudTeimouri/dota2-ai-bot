-- AetherWeaver Bot Generic
-- Workshop addon: vscripts/bots/bot_generic.lua
-- MAIN ENTRY POINT - Engine calls global Think() here

local AetherWeaver = require("init")

-- Global Think function called by engine every frame
function Think()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        AetherWeaver.hero = bot
        AetherWeaver:BotThink()
    end
end

-- Global ability usage hook
function AbilityUsageThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local AbilityUsage = require("ability_item_usage_generic")
        local ability, target = AbilityUsage:GetAbilityUsage(bot)
        if ability and target then
            if type(target) == "userdata" and target.IsAlive and target:IsAlive() then
                bot:Action_UseAbilityOnEntity(ability, target)
            elseif type(target) == "table" and target.x and target.y and target.z then
                bot:Action_UseAbilityOnLocation(ability, target)
            else
                bot:Action_UseAbility(ability)
            end
        end
    end
end

-- Global item purchase hook
function ItemPurchaseThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local ItemPurchase = require("item_purchase_generic")
        ItemPurchase:PurchaseItem(bot)
    end
end

-- Global skill build hook
function AbilityLevelUpThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local SkillBuild = require("skill_build_generic")
        SkillBuild:AbilityLevelUpThink(bot)
    end
end

-- Global courier hook
function CourierUsageThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local Courier = require("courier_generic")
        Courier:CourierUsageThink(bot)
    end
end

-- Global item usage hook
function ItemUsageThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local AbilityUsage = require("ability_item_usage_generic")
        local item, target = AbilityUsage:GetItemUsage(bot)
        if item and target then
            if type(target) == "userdata" and target.IsAlive and target:IsAlive() then
                bot:Action_UseAbilityOnEntity(item, target)
            elseif type(target) == "table" and target.x and target.y and target.z then
                bot:Action_UseAbilityOnLocation(item, target)
            else
                bot:Action_UseAbility(item)
            end
        end
    end
end

-- Global buyback hook
function BuybackUsageThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local AbilityUsage = require("ability_item_usage_generic")
        if AbilityUsage:ShouldBuyback(bot) then
            bot:ActionImmediate_Buyback()
        end
    end
end