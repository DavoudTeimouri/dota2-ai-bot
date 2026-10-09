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

-- Cheapest first, so a freshly spawned bot still spends its starting gold.
ItemPurchase.STARTERS = {
    support = { "item_tango", "item_ward_observer", "item_fairy_flare" },
    mid     = { "item_tango", "item_null_talisman", "item_fairy_flare" },
    offlane = { "item_tango", "item_branches", "item_fairy_flare" },
    carry   = { "item_tango", "item_fairy_flare", "item_branches" },
}

local function NormalizeRole(role)
    if role == "support" or role == "mid" or role == "offlane" or role == "carry" then
        return role
    end
    return "carry"
end

-- Buy one starter item if we stand in fountain range and can afford it.
-- ActionImmediate_PurchaseItem returns a PURCHASE_ITEM_* code, so a failure
-- (wrong shop, wrong gold, item unavailable) is a no-op rather than a crash.
function ItemPurchase:PurchaseItem(bot)
    if not bot or bot:IsNull() then return false end

    -- Nothing to spend.
    if bot:GetGold() <= 0 then return false end

    -- Must physically be at a shop or the purchase silently does nothing.
    if bot:DistanceFromFountain() ~= 0 then return false end

    local list = self.STARTERS[NormalizeRole(bot:GetRole())]
    for i = 1, #list do
        local item = list[i]
        if not bot:HasItem(item) and bot:ActionImmediate_PurchaseItem(item) == PURCHASE_ITEM_SUCCESS then
            return true
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