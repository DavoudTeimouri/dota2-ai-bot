-- Lobby simulation: run one full game frame the way the Dota 2 engine does
-- and assert the bot actually acts.
--
-- The user-reported failure was "the bots don't move after the lobby started
-- and they don't buy anything". This exercises the real hook sequence with
-- a fake engine, so a silent no-op shows up as a failed assertion instead of
-- a bot that stands in the fountain all game.
--
-- Run: lua5.1 tests/test_lobby.lua

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

-- ---- Recorded actions ------------------------------------------------------
local moved, purchased, leveled, casted, usedItem = {}, {}, {}, {}, {}

local function Reset()
    moved, purchased, leveled, casted, usedItem = {}, {}, {}, {}, {}
end

-- ---- Fake engine -----------------------------------------------------------
local gold = 3000
local inventory = {}          -- slot -> item name
local abilityPoints = 3
local heroUnit = "npc_dota_hero_antimage"

local function makeItem(name)
    return {
        GetName = function() return name end,
        IsNull = function() return false end,
        IsFullyCastable = function() return true end,
    }
end

local function makeAbility(name)
    return {
        GetName = function() return name end,
        IsNull = function() return false end,
        IsFullyCastable = function() return true end,
        CanAbilityBeUpgraded = function() return true end,
    }
end

local function makeEnemy()
    return {
        IsNull = function() return false end,
        IsAlive = function() return true end,
        GetHealth = function() return 300 end,
        GetMaxHealth = function() return 600 end,
        GetAbsOrigin = function() return { x = 600, y = 0, z = 0 } end,
        GetLocation = function() return { x = 600, y = 0, z = 0 } end,
    }
end

-- The bot stands at the fountain, so it can buy and is 0 distance from home.
local bot = {
    IsNull = function() return false end,
    IsAlive = function() return true end,
    GetGold = function() return gold end,
    GetRole = function() return "carry" end,
    GetHealth = function() return 900 end,
    GetMaxHealth = function() return 1000 end,
    GetTeam = function() return 2 end,
    GetPlayerID = function() return 0 end,
    GetAbilityPoints = function() return abilityPoints end,
    GetCourier = function() return nil end,
    GetStashValue = function() return 0 end,
    GetCourierValue = function() return 0 end,
    GetBuybackCost = function() return 0 end,
    GetAssignedLane = function() return 1 end,
    SetAssignedLane = function() end,
    GetAmountAlongLane = function() return 0.2 end,
    DistanceFromFountain = function() return 0 end,
    DistanceFromSideShop = function() return 4000 end,
    DistanceFromSecretShop = function() return 8000 end,

    GetAbsOrigin = function() return { x = 0, y = 0, z = 0 } end,
    GetLocation = function() return { x = 0, y = 0, z = 0 } end,

    GetItemInSlot = function(self, slot)
        local name = inventory[slot]
        if name then return makeItem(name) end
        return nil
    end,
    HasItem = function(self, name)
        for _, n in pairs(inventory) do
            if n == name then return true end
        end
        return false
    end,

    GetAbilityByIndex = function(self, i)
        if i == 0 then return makeAbility("antimage_blink") end
        if i == 1 then return makeAbility("antimage_counterspell") end
        return nil
    end,
    GetAbilityInSlot = function(self, i) return self:GetAbilityByIndex(i) end,
    GetAbilityByName = function(self, name)
        if name == "antimage_blink" then return makeAbility(name) end
        return nil
    end,

    GetNearbyEnemyHeroes = function() return { makeEnemy() } end,
    GetNearbyAlliedHeroes = function() return { makeEnemy() } end,
    GetNearbyLaneCreeps = function() return {} end,
    GetNearbyNeutralCreeps = function() return {} end,
    GetPushingWaves = function() return {} end,
    GetAvailableWards = function() return 2 end,

    -- Actions the engine records.
    Action_MoveToLocation = function(self, loc) moved[#moved + 1] = loc end,
    Action_MoveDirectly = function(self, loc) moved[#moved + 1] = loc end,
    Action_AttackMove = function(self, loc) moved[#moved + 1] = loc end,
    Action_AttackUnit = function(self, u) end,
    Action_UseAbility = function(self, a) casted[#casted + 1] = a end,
    Action_UseAbilityOnEntity = function(self, a, t) casted[#casted + 1] = a end,
    Action_UseAbilityOnLocation = function(self, a, t) casted[#casted + 1] = a end,
    ActionImmediate_Chat = function() end,
    ActionImmediate_Buyback = function() end,
    ActionImmediate_LevelAbility = function(self, name) leveled[#leveled + 1] = name end,
    ActionImmediate_LevelUpAbility = function(self, h) leveled[#leveled + 1] = h end,
    ActionImmediate_Courier = function() end,
    ActionImmediate_PurchaseItem = function(self, name)
        purchased[#purchased + 1] = name
        -- The engine charges gold and puts the item in the first free slot.
        gold = gold - 100
        for slot = 0, 8 do
            if not inventory[slot] then
                inventory[slot] = name
                break
            end
        end
        return _G.PURCHASE_ITEM_SUCCESS or 0
    end,
}

_G.PURCHASE_ITEM_SUCCESS = 0
_G.GetBot = function() return bot end
_G.DotaTime = function() return 300 end
_G.GetGameTime = function() return 300 end
_G.GameTime = function() return 300 end
_G.GetShopLocation = function(team, shop)
    if shop == 0 then return { x = 0, y = 0, z = 0 } end
    return { x = 4000, y = 4000, z = 0 }
end
_G.GetLaneFrontLocation = function(team, lane, offset)
    return { x = 1000, y = 1000, z = 0 }
end
_G.GetRuneStatus = function() return 1 end
_G.GetRuneSpawnLocation = function() return { x = 0, y = 0, z = 0 } end
_G.RUNE_POWERUP_1 = 1
_G.RUNE_POWERUP_2 = 2
_G.RUNE_BOUNTY_1 = 3
_G.RUNE_BOUNTY_2 = 4
_G.RUNE_BOUNTY_3 = 5
_G.RUNE_BOUNTY_4 = 6
_G.RUNE_STATUS_AVAILABLE = 0
_G.SHOP_HOME = 0
_G.SHOP_SIDE = 1
_G.SHOP_SECRET = 2
_G.LANE_TOP = 1
_G.LANE_MID = 2
_G.LANE_BOT = 3

-- ---- Load the modules the way the engine does -------------------------------
local mods = {}
for _, name in ipairs({
    "bot_compat", "bot_lane", "bot_names", "hero_selection", "team_desires",
    "ability_item_usage_generic", "item_purchase_generic", "skill_build_generic",
    "courier_generic", "mode_laning_generic", "mode_farm_generic",
    "mode_item_generic", "mode_ward_generic", "mode_rune_generic",
    "mode_push_lane_generic", "mode_retreat_generic", "mode_team_roam_generic",
}) do
    local ok, mod = pcall(require, name)
    check("lobby: " .. name .. " loads", ok and type(mod) == "table",
        ok and "not a table" or tostring(mod))
    mods[name] = mod
end

-- The engine calls the hooks as globals, not as methods on the module table.
local function LoadHook(file)
    local path = "vscripts/bots/" .. file
    local chunk = loadfile(path)
    if not chunk then return nil end
    chunk()
    return true
end

for _, file in ipairs({
    "ability_item_usage_generic.lua", "item_purchase_generic.lua",
    "skill_build_generic.lua", "courier_generic.lua", "mode_laning_generic.lua",
    "mode_farm_generic.lua", "mode_item_generic.lua", "mode_ward_generic.lua",
    "mode_rune_generic.lua", "mode_push_lane_generic.lua",
    "mode_retreat_generic.lua", "mode_team_roam_generic.lua",
    "team_desires.lua", "hero_selection.lua",
}) do
    check("lobby: " .. file .. " loads without error", LoadHook(file))
end

-- ============================================================================
-- FRAME 1: the bot is at the fountain with gold. It must buy.
-- ============================================================================
Reset()
if _G.ItemPurchaseThink then _G.ItemPurchaseThink() end
check("lobby: the bot buys an item while standing at the fountain",
    #purchased > 0, "purchases=" .. #purchased)

-- ============================================================================
-- FRAME 2: the bot must move. Drive every mode's Think() and look for an order.
-- ============================================================================
Reset()
local modes = {
    "mode_laning_generic", "mode_farm_generic", "mode_item_generic",
    "mode_ward_generic", "mode_rune_generic", "mode_push_lane_generic",
    "mode_retreat_generic", "mode_team_roam_generic",
}
for _, name in ipairs(modes) do
    local ok, err = pcall(function()
        local m = mods[name]
        if m and m.GetDesire then m.GetDesire() end
        if m and m.Think then m.Think() end
    end)
    if not ok then
        check("lobby: " .. name .. " GetDesire/Think() runs", false, tostring(err))
    end
end
check("lobby: at least one mode issues a movement order",
    #moved > 0, "moves=" .. #moved)

-- ============================================================================
-- FRAME 3: unspent ability points must be spent.
-- ============================================================================
Reset()
if _G.AbilityLevelUpThink then _G.AbilityLevelUpThink() end
check("lobby: the bot spends an unspent ability point",
    #leveled > 0, "leveled=" .. #leveled)

-- ============================================================================
-- FRAME 4: the whole hook sequence must not raise.
-- ============================================================================
Reset()
local ok, err = pcall(function()
    if _G.TeamThink then _G.TeamThink() end
    if _G.AbilityUsageThink then _G.AbilityUsageThink() end
    if _G.ItemUsageThink then _G.ItemUsageThink() end
    if _G.CourierUsageThink then _G.CourierUsageThink() end
    if _G.SkillBuildThink then _G.SkillBuildThink() end
    if _G.ItemPurchaseThink then _G.ItemPurchaseThink() end
end)
check("lobby: the full hook sequence runs without raising", ok, tostring(err))

-- ============================================================================
-- FRAME 5: a bot with no hero, no gold and no abilities must still not raise.
-- ============================================================================
Reset()
local broken = {
    IsNull = function() return false end,
    IsAlive = function() return false end,
    GetGold = function() return 0 end,
    GetHealth = function() return 0 end,
    GetMaxHealth = function() return 1 end,
    GetTeam = function() return 3 end,
    GetPlayerID = function() return 5 end,
    GetAbilityPoints = function() return 0 end,
}
local savedBot = _G.GetBot
_G.GetBot = function() return broken end
local ok2, err2 = pcall(function()
    for _, name in ipairs(modes) do
        local m = mods[name]
        if m and m.GetDesire then m.GetDesire() end
        if m and m.Think then m.Think() end
    end
    if _G.AbilityUsageThink then _G.AbilityUsageThink() end
    if _G.ItemPurchaseThink then _G.ItemPurchaseThink() end
    if _G.CourierUsageThink then _G.CourierUsageThink() end
end)
check("lobby: a bare bot does not raise in any hook", ok2, tostring(err2))
_G.GetBot = savedBot

if failures == 0 then
    print("ALL PASS")
else
    print(failures .. " FAILURE(S)")
    os.exit(1)
end
