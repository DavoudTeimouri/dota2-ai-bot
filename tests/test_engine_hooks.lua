-- Test harness: proves the local-before-declaration bug is a real runtime failure.
-- Dota 2's VM is Lua 5.1. Each engine hook is called as a GLOBAL function.
-- Run: lua5.1 tests/test_engine_hooks.lua

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

-- ---- Minimal engine stub -------------------------------------------------
local fakeBot = {
    IsNull = function() return false end,
    IsAlive = function() return true end,
    GetAbilityByIndex = function() return nil end,
    GetNearbyEnemyHeroes = function() return {} end,
    GetNearbyCreeps = function() return {} end,
    GetGold = function() return 0 end,
    GetItemInSlot = function() return nil end,
    GetAbilityPoints = function() return 0 end,
    GetUnitName = function() return "npc_dota_hero_antimage" end,
    GetRole = function() return "carry" end,
    GetAssignedLane = function() return "safe" end,
}
_G.GetBot = function() return fakeBot end
_G.GameRules = { GetGameTime = function() return 0 end }
_G.GetTeam = function() return 2 end
_G.Vector = function(x, y, z) return { x = x, y = y, z = z } end
_G.PLAYER_ID = 0

-- ---- The bug: engine hook references a local declared AFTER it ------------
-- Each of these files declares `local X = {}` AFTER the global hook that
-- references X. In Lua 5.1 the reference inside the hook body resolves to a
-- GLOBAL (nil at call time), not the local.

local function loadHook(file, hookName)
    -- load the file in a fresh-ish env so we can call the global hook
    local chunk, err = loadfile(file)
    if not chunk then
        return nil, err
    end
    local env = setmetatable({}, { __index = _G, __newindex = function(t, k, v) rawset(t, k, v) end })
    setfenv(chunk, env)
    local ok, rerr = pcall(chunk)
    if not ok then return nil, rerr end
    return env[hookName]
end

-- 1. ability_item_usage_generic
local fn = loadHook("vscripts/bots/ability_item_usage_generic.lua", "AbilityUsageThink")
check("ability_item_usage_generic: hook is a global function", fn ~= nil)
if fn then
    local ok, err = pcall(fn)
    check("ability_item_usage_generic: AbilityUsageThink() runs", ok, err)
end

-- 2. item_purchase_generic
local fn2 = loadHook("vscripts/bots/item_purchase_generic.lua", "ItemPurchaseThink")
check("item_purchase_generic: hook is a global function", fn2 ~= nil)
if fn2 then
    local ok, err = pcall(fn2)
    check("item_purchase_generic: ItemPurchaseThink() runs", ok, err)
end

-- 3. skill_build_generic
local fn3 = loadHook("vscripts/bots/skill_build_generic.lua", "SkillBuildThink")
check("skill_build_generic: hook is a global function", fn3 ~= nil)
if fn3 then
    local ok, err = pcall(fn3)
    check("skill_build_generic: SkillBuildThink() runs", ok, err)
end

-- 4. courier_generic
local fn4 = loadHook("vscripts/bots/courier_generic.lua", "CourierUsageThink")
check("courier_generic: hook is a global function", fn4 ~= nil)
if fn4 then
    local ok, err = pcall(fn4)
    check("courier_generic: CourierUsageThink() runs", ok, err)
end

-- ---- Everything must parse ------------------------------------------------
local f = io.popen("find vscripts -name '*.lua' | sort")
for line in f:lines() do
    local chunk, err = loadfile(line)
    check("parses: " .. line, chunk ~= nil, err)
end
f:close()

print("")
if failures == 0 then
    print("ALL PASS")
else
    print(failures .. " FAILURE(S)")
end
os.exit(failures == 0 and 0 or 1)
