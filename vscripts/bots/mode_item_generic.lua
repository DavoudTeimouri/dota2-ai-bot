-- Item/shop mode: walk to the shop when we can afford the next item.
--
-- Engine contract: GetDesire() is called every frame for every mode file. nil
-- falls back to Valve's built-in desire for this mode; 0 opts out.
--
-- ItemPurchaseThink() runs every frame regardless of mode, but it can only buy
-- when the bot is physically standing at a shop. Without this mode a bot earns
-- gold mid-lane and never walks back, so it buys nothing all game.
local ItemPurchase = require("item_purchase_generic")

-- Map a build-order shop name onto the engine's SHOP_* constant.
local SHOP_CONST = {
    home   = SHOP_HOME,
    side   = SHOP_SIDE,
    secret = SHOP_SECRET,
}

-- The next item this bot wants, and which shop sells it.
function GetNextPurchase(bot)
    local gold = bot:GetGold()
    if gold <= 0 then return nil end

    local build = ItemPurchase.BUILDS[ItemPurchase.NormalizeRole(bot:GetRole())]
    for _, entry in ipairs(build) do
        local item, minGold, shop = entry[1], entry[2], entry[3]
        if gold >= minGold and not bot:HasItem(item) then
            return item, shop
        end
    end
    return nil
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end
    if bot:GetGold() <= 0 then return nil end
    if not ItemPurchase:NeedsToShop(bot) then return nil end

    -- Buyable, but we have to walk. Enough to beat farming, not enough to
    -- abandon a fight outright.
    return 0.5
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    local _, shop = GetNextPurchase(bot)
    if not shop or not SHOP_CONST[shop] then return end
    if not GetShopLocation then return end

    local loc = GetShopLocation(bot:GetTeam(), SHOP_CONST[shop])
    if loc then
        bot:Action_MoveToLocation(loc)
    end
end