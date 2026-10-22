-- Item/shop mode: walk to the shop when we can afford the next item.
--
-- Engine contract: GetDesire() is called every frame for every mode file. nil
-- falls back to Valve's built-in desire for this mode; 0 opts out.
--
-- ItemPurchaseThink() runs every frame regardless of mode, but it can only buy
-- when the bot is physically standing at a shop. Without this mode a bot earns
-- gold mid-lane and never walks back, so it buys nothing all game.
local ItemPurchase = require("item_purchase_generic")
local Compat = require("bot_compat")

-- Map a build-order shop name onto the engine's SHOP_* constant.
local SHOP_CONST = {
    home   = _G.SHOP_HOME   or 0,
    side   = _G.SHOP_SIDE   or 1,
    secret = _G.SHOP_SECRET or 2,
}

-- The next item this bot wants and which shop sells it comes from
-- ItemPurchase:GetNextPurchase(), so the purchase logic and the walk-to-shop
-- logic can never disagree about what the bot is saving for.
local function GetNextPurchase(bot)
    return ItemPurchase:GetNextPurchase(bot)
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
        Compat.MoveTo(bot, loc)
    end
end

-- The engine calls the global GetDesire()/Think() above. Returning the table
-- as well lets the module be required and tested without the engine.
return {
    GetDesire = GetDesire,
    Think = Think,
}