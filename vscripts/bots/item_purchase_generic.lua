-- AetherWeaver item purchase
-- Engine hook: ItemPurchaseThink() -- called every frame by Dota 2.
--
-- Two rules that matter (both proven by tests/test_runtime.lua):
--   1. This file must `return` a table. A bot module with no return makes
--      require() yield boolean `true`, and `ItemPurchase.PurchaseItem(bot)`
--      then dies with "attempt to index upvalue ... (a boolean value)".
--   2. The global hook is declared AFTER `local ItemPurchase`, otherwise the
--      hook body resolves the name to a nil GLOBAL at call time.

local ItemPurchase = {}

-- Buy order by role, cheapest first. Each entry is
--   { item, minGold, shop }  where shop is "home", "side" or "secret".
-- Home = fountain, side = side shop, secret = secret shop.
-- Costs are the vanilla values and drift per patch; the minGold gate means a
-- wrong number only delays a purchase, it never causes a crash.
ItemPurchase.BUILDS = {
    support = {
        { "item_tango",         90,  "home"   },
        { "item_ward_observer", 50,  "home"   },
        { "item_tango",         90,  "home"   },
        { "item_fairy_flare",   180, "home"   },
        { "item_ward_sentry",   50,  "home"   },
        { "item_medallion_of_courage", 400, "secret" },
        { "item_ghost_scepter", 1500, "side" },
        { "item_aghanims_scepter", 4200, "secret" },
        { "item_ward_dispensary", 900, "side" },
    },
    mid = {
        { "item_tango",         90,  "home"   },
        { "item_tango",         90,  "home"   },
        { "item_null_talisman", 40,  "home"   },
        { "item_fairy_flare",   180, "home"   },
        { "item_blink",         2250, "side"  },
        { "item_sheepstick",    1800, "side"  },
        { "item_aghanims_scepter", 4200, "secret" },
    },
    offlane = {
        { "item_tango",         90,  "home"   },
        { "item_tango",         90,  "home"   },
        { "item_branches",      90,  "home"   },
        { "item_fairy_flare",   180, "home"   },
        { "item_blink",         2250, "side"  },
        { "item_bravado",       1800, "side"  },
        { "item_aghanims_scepter", 4200, "secret" },
    },
    carry = {
        { "item_tango",         90,  "home"   },
        { "item_fairy_flare",   180, "home"   },
        { "item_tango",         90,  "home"   },
        { "item_branches",      90,  "home"   },
        { "item_power_treads",  1400, "side"   },
        { "item_butterfly",     2100, "side"   },
        { "item_monster_breaker_135", 3300, "side" },
        { "item_aghanims_scepter", 4200, "secret" },
    },
}

-- Secret shop items can only be bought when standing at it; keep the mapping
-- explicit so a wrong answer is a skipped purchase, not an error.
local function AtShop(bot, shop)
    if shop == "home" then return bot:DistanceFromFountain() == 0 end
    if shop == "side" then return bot:DistanceFromSideShop() == 0 end
    if shop == "secret" then return bot:DistanceFromSecretShop() == 0 end
    return false
end

-- Exported: mode_item_generic.lua needs it to read the same build order.
function ItemPurchase.NormalizeRole(role)
    if role == "support" or role == "mid" or role == "offlane" or role == "carry" then
        return role
    end
    return "carry"
end

local NormalizeRole = ItemPurchase.NormalizeRole

-- The bot's role, resolved through bot_lane so a VM without bot:GetRole()
-- still picks the right build.
local BotLane = require("bot_lane")

-- The build order for this bot, by role.
function ItemPurchase:BuildFor(bot)
    return self.BUILDS[NormalizeRole(BotLane.GetRole(bot))]
end

-- How many copies of `item` the build order asks for.
-- The build lists an item once per copy it wants (e.g. three item_tango),
-- so count the occurrences.
local function DesiredCount(build, item)
    local n = 0
    for _, entry in ipairs(build) do
        if entry[1] == item then n = n + 1 end
    end
    return n
end

-- How many copies the bot currently holds. HasItem() is only a boolean, so
-- scan the inventory slots and count matching item names.
local function OwnedCount(bot, item)
    if not bot.GetItemInSlot then
        return (bot:HasItem(item)) and 1 or 0
    end
    local n = 0
    for s = 0, 8 do
        local it = bot:GetItemInSlot(s)
        if it and not it:IsNull() and it:GetName() == item then
            n = n + 1
        end
    end
    return n
end

-- Buy the first affordable, reachable item that the bot still needs a copy of.
-- ActionImmediate_PurchaseItem returns a PURCHASE_ITEM_* code, so a failure
-- (wrong shop, wrong gold, item unavailable) is a no-op rather than a crash.
function ItemPurchase:PurchaseItem(bot)
    if not bot or bot:IsNull() then return false end

    -- Nothing to spend.
    local gold = bot:GetGold()
    if gold <= 0 then return false end

    local build = self:BuildFor(bot)
    for _, entry in ipairs(build) do
        local item, minGold, shop = entry[1], entry[2], entry[3]
        -- Must be standing at that shop; elsewhere the purchase silently fails.
        if gold >= minGold and AtShop(bot, shop) then
            -- Only buy while we still need a copy: the build may list the same
            -- item several times (two tangos, three wards) and a boolean
            -- HasItem() would stop after the first one.
            if OwnedCount(bot, item) < DesiredCount(build, item) then
                if bot:ActionImmediate_PurchaseItem(item) == PURCHASE_ITEM_SUCCESS then
                    return true
                end
            end
        end
    end
    return false
end

-- True when the bot can afford its next item but is not standing at the shop
-- that sells it. The mode files use this to stop competing with Valve's own
-- shopping behaviour, otherwise a bot mid-lane never walks back to buy.
function ItemPurchase:NeedsToShop(bot)
    if not bot or bot:IsNull() then return false end
    local gold = bot:GetGold()
    if gold <= 0 then return false end

    local build = self:BuildFor(bot)
    for _, entry in ipairs(build) do
        local item, minGold, shop = entry[1], entry[2], entry[3]
        if gold >= minGold and OwnedCount(bot, item) < DesiredCount(build, item) then
            return not AtShop(bot, shop)
        end
    end
    return false
end

-- The next item this bot wants and which shop sells it.
-- mode_item_generic.lua uses this to walk to the right shop.
function ItemPurchase:GetNextPurchase(bot)
    if not bot or bot:IsNull() then return nil end
    local gold = bot:GetGold()
    if gold <= 0 then return nil end

    local build = self:BuildFor(bot)
    for _, entry in ipairs(build) do
        local item, minGold, shop = entry[1], entry[2], entry[3]
        if gold >= minGold and OwnedCount(bot, item) < DesiredCount(build, item) then
            return item, shop
        end
    end
    return nil
end

-- Engine hook. Declared after the local table on purpose.
function ItemPurchaseThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    ItemPurchase:PurchaseItem(bot)
end

return ItemPurchase