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

local Compat = require("bot_compat")

-- Max ability slots per hero.
local MAX_SLOTS = 6

-- Score an enemy hero as a spell target: closer and lower HP is better.
local function ScoreTarget(bot, enemy)
    local pos = Compat.Position(bot)
    local epos = Compat.Position(enemy)
    if not pos or not epos then return 0 end
    local dx = epos.x - pos.x
    local dy = epos.y - pos.y
    local d = math.sqrt(dx * dx + dy * dy)
    local hp = enemy:GetHealth() / math.max(1, enemy:GetMaxHealth())
    return 3000 - d - hp * 1000
end

-- Is this ability the hero's ultimate? IsUltimate() is on the ability handle.
local function IsUltimate(ability)
    if ability.IsUltimate then return ability:IsUltimate() end
    return false
end

-- The ultimate is worth spending on a bigger target than a normal spell:
-- two or more enemies nearby, or a target already low on health.
local function UltimateIsWorthIt(ability, target, enemyCount)
    if not IsUltimate(ability) then return false end
    if enemyCount >= 2 then return true end
    local hp = target:GetHealth() / math.max(1, target:GetMaxHealth())
    return hp < 0.4
end

-- Pick the best ability to cast on the best visible enemy, or nil if none.
function AbilityUsage:GetAbilityUsage(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return nil end

    local enemies = Compat.Enemies(bot, 1200)
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
        local ability = Compat.AbilityInSlot(bot, i)
        if ability and not ability:IsNull() and ability:IsFullyCastable() then
            local top, target = 0, nil
            for _, enemy in ipairs(ranked) do
                local score = ScoreTarget(bot, enemy)
                if score > top then top, target = score, enemy end
            end
            if target then
                -- An ultimate that is worth it beats every normal spell.
                local score = top
                if UltimateIsWorthIt(ability, target, #ranked) then
                    score = score + 10000
                end
                if score > bestScore then
                    bestAbility, bestTarget, bestScore = ability, target, score
                end
            end
        end
    end
    if not bestAbility then return nil end
    return bestAbility, bestTarget
end

-- Use an active item (dust, smoke, orchid) when enemies are near.
-- No-target items (dust, smoke) are cast on self; unit-target items (orchid)
-- are cast on the nearest enemy.
local NO_TARGET_ITEMS = { "item_dust", "item_smoke_of_deceit" }
local UNIT_TARGET_ITEMS = { "item_orchid_malevolence" }

function AbilityUsage:GetItemUsage(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return nil end

    local enemies = Compat.Enemies(bot, 900)
    if #enemies == 0 then return nil end

    -- No-target items: cast on self when enemies nearby.
    for _, name in ipairs(NO_TARGET_ITEMS) do
        if Compat.HasItem(bot, name) then
            local it = Compat.ItemByName(bot, name)
            if it then return it, nil end
        end
    end

    -- Unit-target items: cast on nearest visible enemy.
    for _, name in ipairs(UNIT_TARGET_ITEMS) do
        if Compat.HasItem(bot, name) then
            local it = Compat.ItemByName(bot, name)
            if it then return it, enemies[1] end
        end
    end

    -- Neutral item (slot 16): free loot from a neutral camp. Use it when it
    -- is off cooldown and there is a fight to use it in.
    local neutral = Compat.NeutralItem(bot)
    if neutral then
        local ready = true
        if neutral.IsFullyCastable then
            local ok, castable = pcall(neutral.IsFullyCastable, neutral)
            ready = ok and castable
        end
        if ready then
            -- Neutral items mostly help the bot itself; cast on self unless
            -- the item clearly wants a unit target.
            local target = nil
            if neutral.GetName then
                local ok, name = pcall(neutral.GetName, neutral)
                if ok and name and name:find("tome") then
                    target = enemies[1]
                end
            end
            return neutral, target
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
        local ability = Compat.AbilityInSlot(bot, i)
        if ability and not ability:IsNull() and ability:CanAbilityBeUpgraded() then
            return Compat.LevelAbility(bot, ability)
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
    Compat.UseAbility(bot, ability, target)
end

function ItemUsageThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    local item, target = AbilityUsage:GetItemUsage(bot)
    if not item then return end
    Compat.UseAbility(bot, item, target)
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