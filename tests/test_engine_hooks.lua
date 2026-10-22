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

-- Load a file into a fresh scope and return that scope, so a hook can be
-- checked in the file's OWN namespace. env[hook] would fall through to _G
-- and find a global installed by a require() from another file.
local function loadScope(file)
    local chunk, err = loadfile(file)
    if not chunk then return nil, err end
    local env = setmetatable({}, { __index = _G, __newindex = function(t, k, v) rawset(t, k, v) end })
    setfenv(chunk, env)
    local ok, rerr = pcall(chunk)
    if not ok then return nil, rerr end
    return env
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

-- ---- Hook placement -------------------------------------------------------
-- The engine picks hooks by FILENAME. A hook defined in a file the engine
-- does not read is dead code, and the bot silently never does that thing.
-- This is the check that catches it: every hook must live in the file the
-- engine reads it from.
local HOOK_FILE = {
    AbilityUsageThink     = "ability_item_usage_generic.lua",
    ItemUsageThink        = "ability_item_usage_generic.lua",
    BuybackUsageThink     = "ability_item_usage_generic.lua",
    AbilityLevelUpThink   = "ability_item_usage_generic.lua",
    CourierUsageThink     = "ability_item_usage_generic.lua",
    ItemPurchaseThink     = "item_purchase_generic.lua",
    SkillBuildThink       = "skill_build_generic.lua",
    Think                 = "hero_selection.lua",
    TeamThink             = "team_desires.lua",
    UpdatePushLaneDesires = "team_desires.lua",
    UpdateDefendLaneDesires = "team_desires.lua",
    UpdateFarmLaneDesires = "team_desires.lua",
    UpdateRoamDesire      = "team_desires.lua",
    UpdateRoshanDesire    = "team_desires.lua",
    MinionThink           = "bot_generic.lua",
}

local hookNames = {}
for hook in pairs(HOOK_FILE) do hookNames[#hookNames + 1] = hook end
table.sort(hookNames)

for _, hook in ipairs(hookNames) do
    local file = HOOK_FILE[hook]
    local env = loadScope("vscripts/bots/" .. file)
    -- rawget: the hook must be in THIS file's scope, not a global that
    -- another file's require() happened to install.
    check("hook placement: " .. hook .. " is defined in " .. file,
        env ~= nil and rawget(env, hook) ~= nil)
end

-- The courier hook in particular: it was in courier_generic.lua, which the
-- engine never reads, so the bot never touched its courier.
local courierScope = loadScope("vscripts/bots/ability_item_usage_generic.lua")
check("courier: the engine-read file carries the hook",
    courierScope ~= nil and rawget(courierScope, "CourierUsageThink") ~= nil)
if courierScope and rawget(courierScope, "CourierUsageThink") then
    local ok, err = pcall(rawget(courierScope, "CourierUsageThink"))
    check("courier: CourierUsageThink() runs", ok, err)
end

-- 4. courier_generic: the module loads, and the hook it used to own now
-- lives in the file the engine actually reads.
local courierScope = loadScope("vscripts/bots/courier_generic.lua")
check("courier_generic: the duplicate hook is gone",
    courierScope ~= nil and rawget(courierScope, "CourierUsageThink") == nil)
do
    local ok, mod = pcall(require, "courier_generic")
    check("courier_generic: loads as a module", ok and type(mod) == "table",
        ok and "not a table" or tostring(mod))
    if ok and type(mod) == "table" then
        check("courier_generic: exposes CourierUsageThink", type(mod.CourierUsageThink) == "function")
    end
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
