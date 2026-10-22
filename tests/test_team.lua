-- Team desire contract and per-hero rules.
--
-- The engine calls five globals in team_desires.lua to get the team's plan,
-- then the modes read it back through GetPushLaneDesire(lane) and friends.
-- Without those five the engine has no team strategy at all.
--
-- Run: lua5.1 tests/test_team.lua

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
local bot = {
    IsNull = function() return false end,
    IsAlive = function() return true end,
    GetGold = function() return 3000 end,
    GetHealth = function() return 900 end,
    GetMaxHealth = function() return 1000 end,
    GetTeam = function() return 2 end,
    GetPlayerID = function() return 0 end,
    GetUnitName = function() return "npc_dota_hero_lina" end,
    GetAbsOrigin = function() return { x = 0, y = 0, z = 0 } end,
    GetLocation = function() return { x = 0, y = 0, z = 0 } end,
    GetNetWorth = function() return 8000 end,
    GetItemInSlot = function() return nil end,
    HasItem = function() return false end,
    GetAbilityPoints = function() return 0 end,
    GetNearbyEnemyHeroes = function() return {} end,
    GetNearbyAlliedHeroes = function() return {} end,
    GetNearbyLaneCreeps = function() return {} end,
    GetNearbyNeutralCreeps = function() return {} end,
    GetPushingWaves = function() return {} end,
    GetAvailableWards = function() return 2 end,
    GetAssignedLane = function() return 2 end,
    SetAssignedLane = function() end,
    DistanceFromFountain = function() return 0 end,
    DistanceFromSideShop = function() return 4000 end,
    DistanceFromSecretShop = function() return 8000 end,
    Action_MoveToLocation = function() end,
    Action_AttackMove = function() end,
    Action_AttackUnit = function() end,
    Action_UseAbility = function() end,
    Action_UseAbilityOnEntity = function() end,
    Action_UseAbilityOnLocation = function() end,
    ActionImmediate_Chat = function() end,
    ActionImmediate_PurchaseItem = function() return 0 end,
}

_G.GetBot = function() return bot end
_G.DotaTime = function() return 1500 end
_G.GetGameTime = function() return 1500 end
_G.GetTeam = function() return 2 end
_G.GetOpposingTeam = function() return 3 end
_G.GetTeamPlayers = function(team)
    if team == 3 then return { 0, 1, 2, 3, 4 } end
    return { 0, 1, 2, 3, 4 }
end
_G.GetTeamMember = function(i) return nil end
_G.IsHeroAlive = function() return true end
_G.IsPlayerBot = function(pid) return pid ~= 0 end
_G.GetHeroLevel = function() return 12 end
_G.GetSelectedHeroName = function() return "npc_dota_hero_lina" end
_G.GetHeroLastSeenInfo = function() return { location = { x = 0, y = 0 }, time_since_seen = 2 } end
_G.GetRoshanKillTime = function() return 0 end
_G.PURCHASE_ITEM_SUCCESS = 0
_G.TOWER_TOP_1 = 11
_G.TOWER_MID_1 = 12
_G.TOWER_BOT_1 = 13
_G.LANE_TOP, _G.LANE_MID, _G.LANE_BOT = 1, 2, 3

-- A tower under attack in the top lane.
local towerTarget = {
    IsNull = function() return false end,
    GetUnitName = function() return "npc_dota_hero_enemy" end,
}
_G.GetTower = function(team, tower)
    return { IsNull = function() return false end,
             GetAbsOrigin = function() return { x = 100, y = 14000, z = 0 } end,
             GetLocation = function() return { x = 100, y = 14000, z = 0 } end }
end
_G.GetTowerAttackTarget = function(team, tower)
    if tower == _G.TOWER_TOP_1 then return towerTarget end
    return nil
end

-- Load the module the way the engine does.
local chunk = loadfile("vscripts/bots/team_desires.lua")
chunk()

-- ============================================================================
-- The five engine hooks must exist as globals.
-- ============================================================================
for _, name in ipairs({
    "UpdatePushLaneDesires", "UpdateDefendLaneDesires", "UpdateFarmLaneDesires",
    "UpdateRoamDesire", "UpdateRoshanDesire",
}) do
    check("team: " .. name .. " is a global function", type(_G[name]) == "function")
end

-- ============================================================================
-- The lane tables must have an entry per lane, both by name and by index.
-- ============================================================================
local push = UpdatePushLaneDesires()
check("team: push desires have a top, mid and bot entry",
    push.top ~= nil and push.mid ~= nil and push.bot ~= nil)
check("team: push desires are also indexed by LANE_TOP/MID/BOT",
    push[1] == push.top and push[2] == push.mid and push[3] == push.bot)
check("team: push desires are numbers between 0 and 1",
    type(push.top) == "number" and push.top >= 0 and push.top <= 1,
    tostring(push.top))

local defend = UpdateDefendLaneDesires()
check("team: defend desires have a top, mid and bot entry",
    defend.top ~= nil and defend.mid ~= nil and defend.bot ~= nil)
check("team: the lane whose tower is under attack has the highest defend desire",
    defend.top > defend.mid and defend.top > defend.bot,
    string.format("top=%s mid=%s bot=%s", tostring(defend.top),
        tostring(defend.mid), tostring(defend.bot)))

local farm = UpdateFarmLaneDesires()
check("team: farm desires have a top, mid and bot entry",
    farm.top ~= nil and farm.mid ~= nil and farm.bot ~= nil)

-- ============================================================================
-- Roam and Roshan.
-- ============================================================================
local roamDesire, roamTarget = UpdateRoamDesire()
check("team: UpdateRoamDesire() returns a number", type(roamDesire) == "number",
    tostring(roamDesire))
check("team: UpdateRoshanDesire() returns a number",
    type(UpdateRoshanDesire()) == "number", tostring(UpdateRoshanDesire()))

-- ============================================================================
-- The modes read the desires back through the engine getters.
-- ============================================================================
local stored = { push = { [1] = 0.1, [2] = 0.2, [3] = 0.9 } }
_G.GetPushLaneDesire = function(lane) return stored.push[lane] end
_G.GetDefendLaneDesire = function(lane) return 0.5 end
_G.GetFarmLaneDesire = function(lane) return 0.5 end
_G.GetRoamDesire = function() return 0.7 end
_G.GetRoamTarget = function() return nil end
_G.GetRoshanDesire = function() return 0.6 end

local pushMode = require("mode_push_lane_generic")
-- The bot is in the bottom lane (3), which the team wants pushed (0.9).
bot.GetAssignedLane = function() return 3 end
bot.GetPushingWaves = function() return { {}, {} } end
bot.GetNearbyAlliedHeroes = function()
    return { { IsNull = function() return false end, IsAlive = function() return true end,
               GetHealth = function() return 900 end, GetMaxHealth = function() return 1000 end } }
end
bot.GetNearbyEnemyHeroes = function() return {} end
local desire = pushMode.GetDesire()
check("team: the push mode reads the team's push desire for its lane",
    type(desire) == "number" and desire > 0.5,
    tostring(desire))

-- A lane the team does not want pushed must score lower.
bot.GetAssignedLane = function() return 1 end
local lowDesire = pushMode.GetDesire()
check("team: a lane the team does not want to push scores lower",
    lowDesire < desire, string.format("%s vs %s", tostring(lowDesire), tostring(desire)))

-- ============================================================================
-- The defend mode reacts to a tower under attack.
-- ============================================================================
local defendMode = require("mode_defend_generic")
bot.GetAssignedLane = function() return 1 end   -- top lane, the one under attack
bot.GetHealth = function() return 900 end
bot.GetMaxHealth = function() return 1000 end
bot.GetNearbyEnemyHeroes = function() return {} end
bot.GetNearbyAlliedHeroes = function()
    return { { IsNull = function() return false end, IsAlive = function() return true end,
               GetHealth = function() return 900 end, GetMaxHealth = function() return 1000 end } }
end
local defendDesire = defendMode.GetDesire()
check("team: the defend mode wants to defend a lane whose tower is under attack",
    type(defendDesire) == "number" and defendDesire > 0,
    tostring(defendDesire))

-- A lane with no attack is not worth defending.
bot.GetAssignedLane = function() return 3 end
local noDefend = defendMode.GetDesire()
check("team: the defend mode ignores a lane with no attack",
    noDefend == 0, tostring(noDefend))

-- ============================================================================
-- Per-hero rules.
-- ============================================================================
local HeroRules = require("hero_rules")
check("hero rules: a listed hero has an ultimate rule",
    HeroRules.For("npc_dota_hero_lina").ult == "burst",
    tostring(HeroRules.For("npc_dota_hero_lina").ult))
check("hero rules: an unlisted hero has no rules",
    HeroRules.For("npc_dota_hero_not_a_hero") == nil)
check("hero rules: the short name is stripped",
    HeroRules.ShortName("npc_dota_hero_axe") == "axe")

-- The ultimate decision follows the hero's rule.
local AbilityUsage = require("ability_item_usage_generic")

local function makeEnemy(hp)
    return {
        IsNull = function() return false end,
        IsAlive = function() return true end,
        GetHealth = function() return hp end,
        GetMaxHealth = function() return 600 end,
        GetAbsOrigin = function() return { x = 500, y = 0, z = 0 } end,
    }
end

local function makeUlt(name)
    local a = {
        GetName = function() return name end,
        IsNull = function() return false end,
        IsFullyCastable = function() return true end,
        CanAbilityBeUpgraded = function() return true end,
        IsUltimate = function() return true end,
    }
    return a
end

local function makeNormal(name)
    local a = {
        GetName = function() return name end,
        IsNull = function() return false end,
        IsFullyCastable = function() return true end,
        CanAbilityBeUpgraded = function() return true end,
        IsUltimate = function() return false end,
    }
    return a
end

-- Lina is a "burst" hero: her ultimate is NOT worth it on a full-health
-- single target, but it IS on a target below 40%.
local function ultBot(heroName, enemyHp, count)
    local b = {
        IsNull = function() return false end,
        IsAlive = function() return true end,
        GetHealth = function() return 900 end,
        GetMaxHealth = function() return 1000 end,
        GetUnitName = function() return "npc_dota_hero_" .. heroName end,
        GetAbsOrigin = function() return { x = 0, y = 0, z = 0 } end,
        GetAbilityPoints = function() return 0 end,
        GetAbilityByIndex = function(self, i)
            if i == 0 then return makeNormal("lina_dragon_slave") end
            if i == 1 then return makeUlt("lina_laguna_blade") end
            return nil
        end,
        GetNearbyEnemyHeroes = function()
            local out = {}
            for _ = 1, count do out[#out + 1] = makeEnemy(enemyHp) end
            return out
        end,
    }
    return b
end

local chosen = AbilityUsage:GetAbilityUsage(ultBot("lina", 600, 1))
check("hero rules: a burst ultimate is not used on a full-health single target",
    chosen and chosen:GetName() == "lina_dragon_slave",
    chosen and chosen:GetName() or "nil")

chosen = AbilityUsage:GetAbilityUsage(ultBot("lina", 200, 1))
check("hero rules: a burst ultimate is used on a low-health target",
    chosen and chosen:GetName() == "lina_laguna_blade",
    chosen and chosen:GetName() or "nil")

-- An "always" hero uses the ultimate even against one full-health enemy.
chosen = AbilityUsage:GetAbilityUsage(ultBot("zeus", 600, 1))
check("hero rules: an always ultimate is used on a single full-health target",
    chosen and chosen:GetName() == "lina_laguna_blade",
    chosen and chosen:GetName() or "nil")

-- An "initiate" hero needs two enemies.
chosen = AbilityUsage:GetAbilityUsage(ultBot("axe", 600, 1))
check("hero rules: an initiate ultimate waits for a second enemy",
    chosen and chosen:GetName() == "lina_dragon_slave",
    chosen and chosen:GetName() or "nil")
chosen = AbilityUsage:GetAbilityUsage(ultBot("axe", 600, 2))
check("hero rules: an initiate ultimate fires on two enemies",
    chosen and chosen:GetName() == "lina_laguna_blade",
    chosen and chosen:GetName() or "nil")

-- ============================================================================
-- The level order comes from the hero rules.
-- ============================================================================
local leveled = {}
local levelBot = {
    IsNull = function() return false end,
    IsAlive = function() return true end,
    GetUnitName = function() return "npc_dota_hero_antimage" end,
    GetAbilityPoints = function() return 1 end,
    GetAbilityByName = function(self, name)
        if name == "antimage_mana_break" then return makeNormal(name) end
        return nil
    end,
    GetAbilityByIndex = function() return makeNormal("antimage_blink") end,
    ActionImmediate_LevelAbility = function(self, name) leveled[#leveled + 1] = name end,
    ActionImmediate_LevelUpAbility = function(self, h) leveled[#leveled + 1] = h end,
}
AbilityUsage:AbilityLevelUpThink(levelBot)
check("hero rules: the level order decides which ability gets the point",
    #leveled == 1 and leveled[1] == "antimage_mana_break",
    #leveled == 1 and tostring(leveled[1]) or "none")

if failures == 0 then
    print("ALL PASS")
else
    print(failures .. " FAILURE(S)")
    os.exit(1)
end
