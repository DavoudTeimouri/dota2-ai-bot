-- AetherWeaver ability + item active usage
-- Engine hooks: AbilityUsageThink(), ItemUsageThink(), BuybackUsageThink(),
--               AbilityLevelUpThink().
--
-- Two rules that matter (both proven by tests/test_runtime.lua):
--   1. This file must `return` a table. A bot module with no return makes
--      require() yield boolean `true`, and `AbilityUsage:GetAbilityUsage(bot)`
--      then dies with "attempt to index upvalue ... (a boolean value)".
--   2. Every global hook is declared AFTER `local AbilityUsage`, otherwise the
--      hook body resolves the name to a nil GLOBAL at call time.

local AbilityUsage = {}

-- Max ability slots per hero.
local MAX_SLOTS = 6

-- Score an enemy hero as a spell target: closer and lower HP is better.
local function ScoreTarget(bot, enemy)
    local pos = bot:GetAbsOrigin()
    local epos = enemy:GetAbsOrigin()
    local dx = epos.x - pos.x
    local dy = epos.y - pos.y
    local d = math.sqrt(dx * dx + dy * dy)
    local hp = enemy:GetHealth() / math.max(1, enemy:GetMaxHealth())
    return 3000 - d - hp * 1000
end

-- Pick the best ability to cast on the best visible enemy, or nil if none.
function AbilityUsage:GetAbilityUsage(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return nil end

    local enemies = bot:GetNearbyEnemyHeroes(1200, true)
    if #enemies == 0 then return nil end

    -- Rank visible enemies once, then reuse for every ability.
    local ranked = {}
    for _, enemy in ipairs(enemies) do
        if enemy and not enemy:IsNull() and enemy:IsAlive() then
            ranked[#ranked + 1] = enemy
        end
    end
    if #ranked == 0 then return nil end

    local bestAbility, bestTarget, bestScore = nil, nil, 0
    for i = 0, MAX_SLOTS - 1 do
        local ability = bot:GetAbilityByIndex(i)
        if ability and not ability:IsNull() and ability:IsFullyCastable() then
            local top, target = 0, nil
            for _, enemy in ipairs(ranked) do
                local score = ScoreTarget(bot, enemy)
                if score > top then top, target = score, enemy end
            end
            if target and top > bestScore then
                bestAbility, bestTarget, bestScore = ability, target, top
            end
        end
    end
    if not bestAbility then return nil end
    return bestAbility, bestTarget
end

-- Use an active item (dust, smoke, orchid) when enemies are near.
function AbilityUsage:GetItemUsage(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return nil end

    local enemies = bot:GetNearbyEnemyHeroes(900, true)
    if enemies and #enemies > 0 then
        for _, name in ipairs({ "item_dust", "item_smoke_of_deceit", "item_orchid_malevolence" }) do
            if bot:HasItem(name) then
                -- Resolve the handle by scanning inventory slots 0-8.
                for s = 0, 8 do
                    local it = bot:GetItemInSlot(s)
                    if it and not it:IsNull() and it:GetName() == name then
                        return it, enemies[1]
                    end
                end
            end
        end
    end
    return nil
end

-- Buy back only when the bot is dead and gold covers the cost.
function AbilityUsage:ShouldBuyback(bot)
    if not bot or bot:IsNull() then return false end
    if bot:IsAlive() then return false end
    local cost = bot:GetBuybackCost()
    return cost > 0 and bot:GetGold() >= cost
end

-- Spend an unspent ability point on the first upgradable ability.
function AbilityUsage:AbilityLevelUpThink(bot)
    if not bot or bot:IsNull() then return false end
    if bot:GetAbilityPoints() <= 0 then return false end
    for i = 0, MAX_SLOTS - 1 do
        local ability = bot:GetAbilityByIndex(i)
        if ability and not ability:IsNull() and ability:CanAbilityBeUpgraded() then
            return bot:ActionImmediate_LevelUpAbility(ability) and true or false
        end
    end
    return false
end

-- Engine hooks. All declared after the local table on purpose.

function AbilityUsageThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    local ability, target = AbilityUsage:GetAbilityUsage(bot)
    if not ability then return end
    if target then
        bot:Action_UseAbilityOnEntity(ability, target)
    else
        bot:Action_UseAbility(ability)
    end
end

function ItemUsageThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    local item, target = AbilityUsage:GetItemUsage(bot)
    if not item then return end
    if target then
        bot:Action_UseAbilityOnEntity(item, target)
    else
        bot:Action_UseAbility(item)
    end
end

function BuybackUsageThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    if AbilityUsage:ShouldBuyback(bot) then
        bot:ActionImmediate_Buyback()
    end
end

function AbilityLevelUpThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    AbilityUsage:AbilityLevelUpThink(bot)
end

return AbilityUsage