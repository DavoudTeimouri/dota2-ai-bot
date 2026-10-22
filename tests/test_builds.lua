-- Item builds, live prices, shop placement, stock and the hero lines.
--
-- Run: lua5.1 tests/test_builds.lua

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

-- ---- Fake engine -----------------------------------------------------------
local unitName = "npc_dota_hero_antimage"
local gold = 3000
local inventory = {}
local purchased = {}

local function makeItem(name)
    return {
        GetName = function() return name end,
        IsNull = function() return false end,
        IsFullyCastable = function() return true end,
    }
end

local bot = {
    IsNull = function() return false end,
    IsAlive = function() return true end,
    GetGold = function() return gold end,
    GetHealth = function() return 900 end,
    GetMaxHealth = function() return 1000 end,
    GetTeam = function() return 2 end,
    GetPlayerID = function() return 0 end,
    GetUnitName = function() return unitName end,
    GetRole = function() return "carry" end,
    GetAssignedLane = function() return 3 end,
    SetAssignedLane = function() end,
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
    GetAbilityPoints = function() return 0 end,
    GetNearbyEnemyHeroes = function() return {} end,
    GetNearbyAlliedHeroes = function() return {} end,
    GetNearbyLaneCreeps = function() return {} end,
    GetNearbyNeutralCreeps = function() return {} end,
    GetPushingWaves = function() return {} end,
    GetAvailableWards = function() return 0 end,
    DistanceFromFountain = function() return 0 end,
    DistanceFromSideShop = function() return 4000 end,
    DistanceFromSecretShop = function() return 8000 end,
    ActionImmediate_PurchaseItem = function(self, name)
        purchased[#purchased + 1] = name
        return 0
    end,
    Action_MoveToLocation = function() end,
    Action_AttackMove = function() end,
    Action_AttackUnit = function() end,
    Action_UseAbility = function() end,
    Action_UseAbilityOnEntity = function() end,
    Action_UseAbilityOnLocation = function() end,
    ActionImmediate_Chat = function() end,
}

_G.GetBot = function() return bot end
_G.DotaTime = function() return 900 end
_G.PURCHASE_ITEM_SUCCESS = 0
_G.SHOP_HOME, _G.SHOP_SIDE, _G.SHOP_SECRET = 0, 1, 2
_G.LANE_TOP, _G.LANE_MID, _G.LANE_BOT = 1, 2, 3

local ItemPurchase = require("item_purchase_generic")
local HeroBuilds = require("hero_builds")

-- ============================================================================
-- Per-hero builds.
-- ============================================================================
local amBuild = ItemPurchase:BuildFor(bot)
check("builds: a listed hero gets its own build", amBuild ~= ItemPurchase.BUILDS.carry)
check("builds: the Anti-Mage build is used",
    amBuild[1] and amBuild[1][1] == "item_tango")
check("builds: the Anti-Mage build has a Manta Style",
    (function()
        for _, e in ipairs(amBuild) do
            if e[1] == "item_manta_style" then return true end
        end
        return false
    end)())

-- A hero with no entry of its own falls back to the role build.
unitName = "npc_dota_hero_some_new_hero"
local fallback = ItemPurchase:BuildFor(bot)
check("builds: a hero with no entry of its own falls back to the role build",
    fallback == ItemPurchase.BUILDS.carry)
unitName = "npc_dota_hero_antimage"

check("builds: the lookup strips the unit-name prefix",
    HeroBuilds.For("npc_dota_hero_invoker") ~= nil)
check("builds: an unknown hero has no build", HeroBuilds.For("npc_dota_hero_zzz") == nil)

-- ============================================================================
-- Live prices and shop placement.
-- ============================================================================
_G.GetItemCost = function(name)
    if name == "item_tango" then return 90 end
    if name == "item_manta_style" then return 4900 end
    return 1000
end
_G.IsItemPurchasedFromSecretShop = function(name)
    return name == "item_aghanims_scepter"
end
_G.IsItemPurchasedFromSideShop = function(name)
    return name == "item_manta_style"
end

check("price: the live cost is used",
    ItemPurchase:CostFor("item_tango", 999) == 90)
check("price: the fallback is used when the query is missing",
    ItemPurchase:CostFor("item_tango", 777) == 90)
_G.GetItemCost = nil
check("price: the build number is the fallback without the query",
    ItemPurchase:CostFor("item_tango", 777) == 777)
_G.GetItemCost = function(name)
    if name == "item_tango" then return 90 end
    return 1000
end

check("shop: the live secret shop is used",
    ItemPurchase:ShopFor("item_aghanims_scepter", "home") == "secret")
check("shop: the live side shop is used",
    ItemPurchase:ShopFor("item_manta_style", "home") == "side")
check("shop: the build fallback is used for a home item",
    ItemPurchase:ShopFor("item_tango", "home") == "home")

-- ============================================================================
-- Stock.
-- ============================================================================
_G.GetItemStockCount = function(name)
    if name == "item_ward_observer" then return 0 end
    return 10
end
check("stock: an empty shelf is reported as out of stock",
    ItemPurchase:InStock("item_ward_observer") == false)
check("stock: a stocked item is in stock",
    ItemPurchase:InStock("item_tango") == true)
_G.GetItemStockCount = nil
check("stock: without the query everything is in stock",
    ItemPurchase:InStock("item_ward_observer") == true)

-- ============================================================================
-- The purchase honours the live cost, shop and stock.
-- ============================================================================
purchased = {}
gold = 100
-- The first thing the Anti-Mage build wants is a Tango, which costs 90.
ItemPurchase:PurchaseItem(bot)
check("purchase: it buys what it can afford",
    #purchased == 1 and purchased[1] == "item_tango",
    #purchased == 1 and purchased[1] or "none")

purchased = {}
gold = 50
ItemPurchase:PurchaseItem(bot)
check("purchase: it does not buy what it cannot afford", #purchased == 0,
    tostring(#purchased))

-- An out-of-stock item is skipped.
_G.GetItemStockCount = function() return 0 end
purchased = {}
gold = 3000
ItemPurchase:PurchaseItem(bot)
check("purchase: an out-of-stock item is not bought", #purchased == 0,
    tostring(#purchased))
_G.GetItemStockCount = nil

-- ============================================================================
-- The ward mode refuses to place a ward it cannot place.
-- ============================================================================
local wardMode = require("mode_ward_generic")
inventory[0] = "item_ward_observer"
-- GetAvailableWards() is 0: the item is there but the charges are used.
local desire = wardMode.GetDesire()
check("ward: no desire when the ward charges are used up", desire == nil,
    tostring(desire))

bot.GetAvailableWards = function() return 3 end
desire = wardMode.GetDesire()
check("ward: it wants to ward when charges are left", desire ~= nil and desire > 0,
    tostring(desire))

-- ============================================================================
-- The hero chat lines.
-- ============================================================================
local AetherWeaver = require("init")
local Messages = AetherWeaver.messages
local line = Messages.get_hero_line("npc_dota_hero_antimage")
check("chat: the Anti-Mage line is found through the alias map", line ~= nil)
check("chat: a hero with no lines returns nil",
    Messages.get_hero_line("npc_dota_hero_zzz") == nil)
check("chat: a hero with lines is found by its own name",
    Messages.get_hero_line("npc_dota_hero_invoker") ~= nil)

if failures == 0 then
    print("ALL PASS")
else
    print(failures .. " FAILURE(S)")
    os.exit(1)
end
