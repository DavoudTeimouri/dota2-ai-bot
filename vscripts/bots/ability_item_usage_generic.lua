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
local HeroRules = require("hero_rules")

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

-- The hero's own name, for the per-hero rules.
local function HeroName(bot)
    if bot.GetUnitName then
        local ok, name = pcall(bot.GetUnitName, bot)
        if ok and name then return HeroRules.ShortName(name) end
    end
    if GetSelectedHeroName and bot.GetPlayerID then
        local ok, id = pcall(bot.GetPlayerID, bot)
        if ok then
            local ok2, name = pcall(GetSelectedHeroName, id)
            if ok2 and name then return HeroRules.ShortName(name) end
        end
    end
    return nil
end

-- Is an ally in danger? Used by the defensive ultimates.
local function AllyInDanger(bot)
    for _, ally in ipairs(Compat.Allies(bot, 1200)) do
        if ally and not ally:IsNull() and ally:IsAlive() then
            local hp = ally:GetHealth() / math.max(1, ally:GetMaxHealth())
            if hp < 0.25 then return true end
        end
    end
    return false
end

-- Should the ultimate be spent now? The rule comes from hero_rules.lua.
-- A hero that is not listed falls back to the default: two or more enemies
-- nearby, or a target that is already low.
local function UltimateIsWorthIt(bot, ability, target, enemyCount)
    if not IsUltimate(ability) then return false end

    local rules = HeroRules.For(HeroName(bot))
    local rule = rules and rules.ult

    if rule == "always" then return true end
    if rule == "initiate" then return enemyCount >= 2 end
    if rule == "burst" then
        local hp = target:GetHealth() / math.max(1, target:GetMaxHealth())
        return hp < 0.4
    end
    if rule == "defend" then return AllyInDanger(bot) end
    if rule == "transform" then return enemyCount >= 1 end
    if rule == "dodge" then
        local hpPct = bot:GetHealth() / math.max(1, bot:GetMaxHealth())
        return hpPct < 0.3
    end

    -- Default: two or more enemies, or a target already low. This is also
    -- the rule for the heroes marked "default" in hero_rules.lua.
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
                if UltimateIsWorthIt(bot, ability, target, #ranked) then
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
local NO_TARGET_ITEMS = { "item_dust" }
local UNIT_TARGET_ITEMS = { "item_orchid_malevolence" }

-- Smoke is worth spending only as a group: the point of it is that the
-- whole team moves in unseen. A lone bot using it just walks into a gank
-- alone.
local function SmokeIsWorthIt(bot)
    local allies = Compat.Allies(bot, 1200)
    if #allies < 2 then return false end
    -- Do not waste it in the first minutes.
    if DotaTime and DotaTime() < 480 then return false end
    return true
end

-- Teleport to a friendly tower that is under attack, when the defend desire
-- is high enough to justify the scroll. Moves the bot instantly instead of
-- walking the whole lane. Returns the scroll and the tower location, or nil.
local function TowerDefendTP(bot)
    if not bot or bot:IsNull() then return nil, nil end
    local team = bot:GetTeam and bot:GetTeam(bot)
    if not team then return nil, nil end
    local tpscroll = Compat.ItemByName(bot, "item_tpscroll")
    if not tpscroll then return nil, nil end
    local bestLane, bestDesire = nil, 0
    for _, lane in ipairs({ LANE_TOP, LANE_MID, LANE_BOT }) do
        if GetDefendLaneDesire then
            local ok, d = pcall(GetDefendLaneDesire, lane)
            if ok and d and d > bestDesire then
                bestDesire, bestLane = d, lane
            end
        end
    end
    if not bestLane or bestDesire < 0.5 then return nil, nil end
    local towerConst = { [LANE_TOP] = _G.TOWER_TOP_1, [LANE_MID] = _G.TOWER_MID_1, [LANE_BOT] = _G.TOWER_BOT_1 }[bestLane]
    if not towerConst then return nil, nil end
    local ok, tower = pcall(GetTower, team, towerConst)
    if not ok or not tower or tower:IsNull() or not tower:IsAlive() then return nil, nil end
    if tower.GetLocation then
        local ok2, loc = pcall(tower.GetLocation, tower)
        if ok2 and loc then return tpscroll, loc end
    end
    return nil, nil
end

function AbilityUsage:GetItemUsage(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return nil end

    -- Teleport to a friendly tower under attack instead of walking the lane.
    local tpi, tploc = TowerDefendTP(bot)
    if tpi then return tpi, tploc end

    local enemies = Compat.Enemies(bot, 900)
    if #enemies == 0 then return nil end

    -- Smoke: the group gank.
    if Compat.HasItem(bot, "item_smoke_of_deceit") and SmokeIsWorthIt(bot) then
        local smoke = Compat.ItemByName(bot, "item_smoke_of_deceit")
        if smoke then return smoke, nil end
    end

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
    if cost == 0 or bot:GetGold() < cost then return false end
    -- Only buy back when there is a fight to join. A dead bot that buys back
    -- walks back alone; that is a waste of gold unless allies are nearby.
    local allies = Compat.Allies(bot, 1400)
    return #allies > 0
end

-- Spend an unspent ability point. The hero's own level order wins when
-- hero_rules.lua has one for it; otherwise the slot order is used.
function AbilityUsage:AbilityLevelUpThink(bot)
    if not bot or bot:IsNull() then return false end
    if bot:GetAbilityPoints() <= 0 then return false end

    local rules = HeroRules.For(HeroName(bot))
    if rules and rules.level and bot.GetAbilityByName then
        for _, name in ipairs(rules.level) do
            local ability = bot:GetAbilityByName(name)
            if ability and not ability:IsNull() and ability:CanAbilityBeUpgraded() then
                return Compat.LevelAbility(bot, ability)
            end
        end
    end

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

-- The engine reads CourierUsageThink() from THIS file, not from
-- courier_generic.lua: it picks hooks by filename and gives each script its
-- own Lua scope, so a hook defined in a file the engine does not read is
-- dead code. courier_generic.lua holds the logic; this is the hook.
function CourierUsageThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    local Courier = require("courier_generic")
    Courier:CourierUsageThink(bot)
end

return AbilityUsage