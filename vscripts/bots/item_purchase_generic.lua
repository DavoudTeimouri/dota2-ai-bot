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
        { "item_medallion_of_courage", 400, "side" },
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

-- Buy the first affordable, reachable, not-yet-owned item in the build order.
-- ActionImmediate_PurchaseItem returns a PURCHASE_ITEM_* code, so a failure
-- (wrong shop, wrong gold, item unavailable) is a no-op rather than a crash.
function ItemPurchase:PurchaseItem(bot)
    if not bot or bot:IsNull() then return false end

    -- Nothing to spend.
    local gold = bot:GetGold()
    if gold <= 0 then return false end

    local build = self.BUILDS[NormalizeRole(bot:GetRole())]
    for _, entry in ipairs(build) do
        local item, minGold, shop = entry[1], entry[2], entry[3]
        -- Must be standing at that shop; elsewhere the purchase silently fails.
        if gold >= minGold and not bot:HasItem(item) and AtShop(bot, shop) then
            if bot:ActionImmediate_PurchaseItem(item) == PURCHASE_ITEM_SUCCESS then
                return true
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

    local build = self.BUILDS[NormalizeRole(bot:GetRole())]
    for _, entry in ipairs(build) do
        local item, minGold, shop = entry[1], entry[2], entry[3]
        if gold >= minGold and not bot:HasItem(item) then
            return not AtShop(bot, shop)
        end
    end
    return false
end

-- Engine hook. Declared after the local table on purpose.
function ItemPurchaseThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    ItemPurchase:PurchaseItem(bot)
end

return ItemPurchase