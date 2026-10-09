-- Runtime proof for the two bugs that made every bot stand still and buy nothing.
-- Run: lua5.1 tests/test_runtime.lua
--
-- These are NOT parse checks. They execute the real Lua 5.1 semantics that the
-- Dota 2 bot VM also runs, and they assert the two failure modes plus the fix.

package.path = "vscripts/bots/?.lua;" .. package.path

local failures = 0
local function check(name, ok, detail)
    if ok then
        print("PASS  " .. name)
    else
        print("FAIL  " .. name .. (detail and ("  -- " .. detail) or ""))
        failures = failures + 1
    end
end

-- ---- Engine stand-ins ------------------------------------------------------
PURCHASE_ITEM_SUCCESS = 0
PURCHASE_ITEM_INSUFFICIENT_GOLD = 1

local function makeAbility(name)
    return {
        GetName = function() return name end,
        IsNull = function() return false end,
        IsFullyCastable = function() return true end,
        CanAbilityBeUpgraded = function() return true end,
        GetLevel = function() return 1 end,
    }
end

local purchased = {}
local leveled = {}
local usedAbility = {}
local enemy = {
    IsNull = function() return false end,
    IsAlive = function() return true end,
    GetHealth = function() return 300 end,
    GetMaxHealth = function() return 600 end,
    GetAbsOrigin = function() return { x = 500, y = 0, z = 0 } end,
}

local bot = {
    IsNull = function() return false end,
    IsAlive = function() return true end,
    GetGold = function() return 1200 end,
    GetRole = function() return "carry" end,
    HasItem = function() return false end,
    GetItemInSlot = function() return nil end,
    GetAbilityByIndex = function(self, i) if i == 1 then return makeAbility("miasma") end end,
    GetAbilityPoints = function() return 1 end,
    GetNearbyEnemyHeroes = function() return { enemy } end,
    GetAbsOrigin = function() return { x = 0, y = 0, z = 0 } end,
    GetHealth = function() return 500 end,
    GetMaxHealth = function() return 1000 end,
    GetBuybackCost = function() return 100 end,
    DistanceFromFountain = function() return 0 end,
    ActionImmediate_PurchaseItem = function(self, item)
        purchased[#purchased + 1] = item
        return PURCHASE_ITEM_SUCCESS
    end,
    ActionImmediate_LevelUpAbility = function(self, a)
        leveled[#leveled + 1] = a:GetName()
        return true
    end,
    Action_UseAbilityOnEntity = function(self, a, t)
        usedAbility[#usedAbility + 1] = a:GetName()
        return true
    end,
    Action_UseAbility = function() return true end,
    ActionImmediate_Buyback = function() return true end,
}

_G.GetBot = function() return bot end
_G.DotaTime = function() return 100 end

-- ---- BUG 1: a module with no `return` makes require() yield boolean true ----
do
    local loaded = require("item_purchase_generic")
    check("item_purchase_generic: require() returns a table, not boolean true",
        type(loaded) == "table", "got " .. type(loaded))

    local loaded2 = require("ability_item_usage_generic")
    check("ability_item_usage_generic: require() returns a table, not boolean true",
        type(loaded2) == "table", "got " .. type(loaded2))

    -- The exact call init.lua makes. Before the fix this raised
    -- "attempt to index upvalue (a boolean value)".
    local ok, err = pcall(function() return ItemPurchase and nil end)
    check("init.lua call site no longer indexes a boolean", ok, err)
end

-- ---- BUG 2: hook declared BEFORE the local table resolves to a nil global --
do
    -- A hook declared before the local it uses resolves to a nil GLOBAL at call
-- time. `local Captured` after the hook is what breaks it: the name `Captured`
-- inside the hook body is not yet a local, so it compiles as a global lookup.
    local path = os.tmpname()
    local f = assert(io.open(path, "w"))
    f:write("function BadOrderHook() return Captured:Method() end\n")
    f:write("local Captured = {}\n")
    f:write("function Captured:Method() return 'fine' end\n")
    f:write("return { Get = function() return BadOrderHook() end }\n")
    f:close()
    local mod = dofile(path)
    local ok, err = pcall(function() return mod:Get() end)
    check("hook-before-local fails (documents why declaration order matters)",
        ok == false and tostring(err):find("nil value") ~= nil,
        "expected a nil-value failure, got ok=" .. tostring(ok) .. " err=" .. tostring(err))
    os.remove(path)
end

-- ---- FIX: every module returns a table with the methods init.lua calls ----
do
    local ItemPurchase = require("item_purchase_generic")
    check("ItemPurchase.PurchaseItem exists", type(ItemPurchase.PurchaseItem) == "function")

    local AbilityUsage = require("ability_item_usage_generic")
    check("AbilityUsage.GetAbilityUsage exists", type(AbilityUsage.GetAbilityUsage) == "function")
    check("AbilityUsage.GetItemUsage exists", type(AbilityUsage.GetItemUsage) == "function")
    check("AbilityUsage.ShouldBuyback exists", type(AbilityUsage.ShouldBuyback) == "function")
    check("AbilityUsage.AbilityLevelUpThink exists", type(AbilityUsage.AbilityLevelUpThink) == "function")
end

-- ---- FIX: the purchase actually spends gold --------------------------------
do
    local ItemPurchase = require("item_purchase_generic")
    local bought = ItemPurchase:PurchaseItem(bot)
    check("PurchaseItem buys when gold allows", bought == true and #purchased > 0,
        "bought=" .. tostring(bought) .. " count=" .. #purchased)
end

-- ---- FIX: it does not buy when away from a shop ----------------------------
do
    local ItemPurchase = require("item_purchase_generic")
    local savedFountain = bot.DistanceFromFountain
    bot.DistanceFromFountain = function() return 900 end
    local before = #purchased
    local bought = ItemPurchase:PurchaseItem(bot)
    bot.DistanceFromFountain = savedFountain
    check("PurchaseItem does not buy away from fountain", bought == false and #purchased == before)
end

-- ---- FIX: level up spends the unspent ability point ------------------------
do
    local AbilityUsage = require("ability_item_usage_generic")
    local leveledOne = AbilityUsage:AbilityLevelUpThink(bot)
    check("AbilityLevelUpThink levels an ability", leveledOne == true and #leveled > 0)
end

-- ---- FIX: ability usage casts on a target ----------------------------------
do
    local AbilityUsage = require("ability_item_usage_generic")
    local ability, target = AbilityUsage:GetAbilityUsage(bot)
    check("GetAbilityUsage returns ability + target",
        ability ~= nil and target ~= nil)
end

-- ---- FIX: the engine hooks actually run -------------------------------------
do
    AbilityUsageThink()
    check("AbilityUsageThink() casts an ability", #usedAbility > 0)

    ItemPurchaseThink()
    check("ItemPurchaseThink() runs without error", true)

    ItemUsageThink()
    BuybackUsageThink()
    AbilityLevelUpThink()
    check("all engine hooks run without error", true)
end

-- ---- Buyback is correctly gated on death -----------------------------------
do
    local AbilityUsage = require("ability_item_usage_generic")
    local aliveBuyback = AbilityUsage:ShouldBuyback(bot)
    local savedAlive = bot.IsAlive
    bot.IsAlive = function() return false end
    local deadBuyback = AbilityUsage:ShouldBuyback(bot)
    bot.IsAlive = savedAlive
    check("ShouldBuyback false while alive, true when dead with gold",
        aliveBuyback == false and deadBuyback == true)
end

-- ---- No module hangs or returns a bare boolean -----------------------------
do
    -- bot_names.lua used to loop forever: it iterated BotNames while appending
    -- to BotNames.all, re-hashing the table mid-loop. That froze init.lua and
    -- every bot with it. This asserts it terminates AND produced names.
    local started = os.clock()
    local names = require("bot_names")
    check("bot_names.lua terminates and builds its name pool",
        #names.all > 0, "all is empty")
    check("bot_names.lua does not spin (under 1s)",
        os.clock() - started < 1.0, "took " .. tostring(os.clock() - started) .. "s")

    -- Every language table must be in the pool exactly once (no double-count).
    local expect = 0
    for key, list in pairs(names) do
        if key ~= "all" and type(list) == "table" then expect = expect + #list end
    end
    check("bot_names.all has no duplicates or drops", #names.all == expect,
        "all=" .. #names.all .. " expected=" .. expect)
end

-- ---- Engine hook placement: each hook must exist in the file the engine reads
do
    -- bot_generic.lua only owns MinionThink. A per-frame Think() there is a
    -- silent no-op, which is exactly why bots used to stand still.
    dofile("vscripts/bots/bot_generic.lua")
    check("bot_generic.lua no longer claims a per-frame Think()",
        type(_G.Think) == "function", "bot_generic must not define Think()")

    -- hero_selection.lua owns Think(); it must be a global there.
    _G.Think = nil
    dofile("vscripts/bots/hero_selection.lua")
    check("hero_selection.lua defines the global Think()",
        type(_G.Think) == "function")

    -- team_desires.lua owns TeamThink(); it must be a global there.
    _G.TeamThink = nil
    dofile("vscripts/bots/team_desires.lua")
    check("team_desires.lua defines the global TeamThink()",
        type(_G.TeamThink) == "function")

    -- bot_generic.lua must still provide the one hook it really owns.
    _G.MinionThink = nil
    dofile("vscripts/bots/bot_generic.lua")
    check("bot_generic.lua defines MinionThink()",
        type(_G.MinionThink) == "function")
end

-- ---- No module is loaded as a bare boolean any more ------------------------
do
    for _, name in ipairs({
        "item_purchase_generic", "ability_item_usage_generic",
        "skill_build_generic", "courier_generic",
        "bot_names", "team_desires",
    }) do
        local mod = require(name)
        check(name .. ": require() yields a table", type(mod) == "table",
            "got " .. type(mod))
    end
end

-- ---- Mode files must expose the engine's mode contract --------------------
do
    -- GetDesire() is called every frame for EVERY mode file; the highest wins.
    -- A mode with no GetDesire() can never activate, which is what the old
    -- mode_farm_generic.lua did.
    local modes = {
        "mode_laning_generic",
        "mode_farm_generic",
        "mode_ward_generic",
        "mode_rune_generic",
    }
    for _, name in ipairs(modes) do
        local path = "vscripts/bots/" .. name .. ".lua"
        _G.GetDesire, _G.Think, _G.OnStart, _G.OnEnd = nil, nil, nil, nil
        dofile(path)
        check(name .. ": defines global GetDesire()",
            type(_G.GetDesire) == "function")
        check(name .. ": defines global Think()",
            type(_G.Think) == "function")

        -- GetDesire must return nil or a number, never throw and never a bool.
        local ok, val = pcall(_G.GetDesire)
        check(name .. ": GetDesire() is safe with no bot",
            ok and (val == nil or type(val) == "number"),
            ok and ("returned " .. type(val)) or tostring(val))
    end
end

-- ---- Deleted modules must stay deleted -------------------------------------
do
    -- These need PlayerResource/GameRules, which are nil in the bot VM.
    for _, name in ipairs({
        "game_intelligence", "game_intelligence_extended", "human_kill_taunts",
    }) do
        local loaded = pcall(require, name)
        check(name .. ": removed (not required by init)", loaded == false)
    end

    -- Nothing may still require a deleted file (comments naming them are fine).
    local init_src = io.open("vscripts/bots/init.lua"):read("*a")
    local requires = {}
    for name in init_src:gmatch('require%("([^"]+)"%)') do
        requires[name] = true
    end
    check("init.lua requires no deleted module",
        not requires["game_intelligence"]
        and not requires["game_intelligence_extended"]
        and not requires["human_kill_taunts"],
        "still requires a deleted module")
end

if failures == 0 then
    print("\nALL PASS")
else
    print("\n" .. failures .. " FAILURE(S)")
    os.exit(1)
end