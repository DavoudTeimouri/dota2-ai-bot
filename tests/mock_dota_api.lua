--[[
Mock Dota 2 bot scripting API for unit testing.
Provides stub implementations of engine functions so bot Lua files can be
unit-tested without launching Dota 2.

Usage in test files:
    local bot = require("vscripts.bots.FunLib.jmz_func") -- etc.
    _G.GetBot = mock.GetBot
    _G.GetTeam = mock.GetTeam
    ...

Run with: lua5.1 tests/run_tests.lua
]]

local Mock = {}

-- Utility: create a fake unit handle
function Mock.Unit(unitName, team, hp, maxHp, posX, posY)
    return {
        GetUnitName = function() return unitName end,
        GetTeam = function() return team end,
        GetHealth = function() return hp end,
        GetMaxHealth = function() return maxHp end,
        GetLocation = function() return {x = posX or 0, y = posY or 0} end,
        IsAlive = function() return hp > 0 end,
        IsNull = function() return false end,
        IsHero = function() return string.find(unitName or "", "npc_dota_hero_") ~= nil end,
        IsInvulnerable = function() return false end,
        IsIllusion = function() return false end,
        IsAttackImmune = function() return false end,
        IsMagicImmune = function() return false end,
        IsStunned = function() return false end,
        IsRooted = function() return false end,
        IsSilenced = function() return false end,
        IsChanneling = function() return false end,
        IsCastingAbility = function() return false end,
        IsUsingAbility = function() return false end,
        GetAttackRange = function() return 600 end,
        GetAttackDamage = function() return 50 end,
        GetAbilityByName = function(name) return nil end,
        GetAbilityInSlot = function(slot) return nil end,
        GetItemInSlot = function(slot) return nil end,
        HasModifier = function(name) return false end,
        GetModifierTime = function(name) return 0 end,
        GetPlayerID = function() return 0 end,
        GetAbsOrigin = function() return {x = posX or 0, y = posY or 0} end,
        SetTarget = function() end,
        GetTarget = function() return nil end,
        GetCurrentActionType = function() return 0 end,
        WasRecentlyDamagedByAnyHero = function(seconds) return false end,
        DistanceFromFountain = function() return 5000 end,
    }
end

-- Bot handle
local theBot = Mock.Unit("npc_dota_hero_antimage", 2, 1000, 1000, 0, 0)

function Mock.GetBot() return theBot end
function Mock.GetTeam() return 2 end -- TEAM_RADIANT
function Mock.GetOpposingTeam() return 3 end -- TEAM_DIRE
function Mock.GetGameMode() return 0 end
function Mock.GetGameState() return 5 end -- GAME_STATE_HERO_SELECTION
function Mock.DotaTime() return 600 end -- 10 minutes in

-- Team players
function Mock.GetTeamPlayers(team)
    local players = {}
    for i = 0, 4 do
        table.insert(players, i)
    end
    return players
end

function Mock.GetHeroLevel(pid) return 5 end
function Mock.GetSelectedHeroName(pid) return "npc_dota_hero_antimage" end
function Mock.IsPlayerBot(pid) return true end
function Mock.IsHeroAlive(pid) return true end
function Mock.GetHeroLastSeenInfo(pid)
    return {location = {x = 1000, y = 1000}, time_since_seen = 10}
end

-- Global constants
Mock.TEAM_RADIANT = 2
Mock.TEAM_DIRE = 3
Mock.TEAM_NEUTRAL = 4
Mock.TEAM_NONE = 5
Mock.GAMEMODE_CM = 2
Mock.GAMEMODE_REVERSE_CM = 4
Mock.GAMEMODE_TURBO = 23
Mock.GAMEMODE_ARDM = 20
Mock.GAMEMODE_ALL_PICK = 1
Mock.GAMEMODE_ALL_DRAFT = 6
Mock.GAMEMODE_CAPTAINSMODE = 2
Mock.GAMEMODE_RANDOM_DRAFT = 5
Mock.GAMEMODE_ALL_DEATH_MATCH = 8
Mock.GAMEMODE_ABILITY_DRAFT = 11
Mock.GAMEMODE_ARDM = 20
Mock.GAMEMODE_1V1MID = 24
Mock.BOT_MODE_NONE = 0
Mock.BOT_MODE_LANING = 1
Mock.BOT_MODE_RETREAT = 2
Mock.BOT_MODE_FARM = 3
Mock.BOT_MODE_PUSH_TOWER_TOP = 4
Mock.BOT_MODE_PUSH_TOWER_MID = 5
Mock.BOT_MODE_PUSH_TOWER_BOT = 6
Mock.BOT_MODE_DEFEND_TOWER_TOP = 7
Mock.BOT_MODE_DEFEND_TOWER_MID = 8
Mock.BOT_MODE_DEFEND_TOWER_BOT = 9
Mock.BOT_MODE_ROAM = 11
Mock.BOT_MODE_ATTACK = 12
Mock.BOT_MODE_DEFEND_ALLY = 13
Mock.BOT_MODE_ROSHAN = 14
Mock.BOT_MODE_EVASIVE_MANEUVERS = 15
Mock.BOT_MODE_VENDOR = 16
Mock.BOT_MODE_PUSH_ALL = 17
Mock.BOT_MODE_DEFEND_ALL = 18
Mock.BOT_ACTION_TYPE_DELAY = 12
Mock.BOT_ACTION_DESIRE_NONE = 0
Mock.BOT_ACTION_DESIRE_VERYHIGH = 1
Mock.BOT_ACTION_DESIRE_ABSOLUTE = 2
Mock.PURCHASE_ITEM_SUCCESS = 0
Mock.PURCHASE_ITEM_INSUFFICIENT_GOLD = 1
Mock.PURCHASE_ITEM_NOT_AT_HOME_SHOP = 2
Mock.PURCHASE_ITEM_NOT_AT_SECRET_SHOP = 3
Mock.PURCHASE_ITEM_NOT_AT_SIDE_SHOP = 4
Mock.PURCHASE_ITEM_OUT_OF_STOCK = 5
Mock.PURCHASE_ITEM_INVALID_ITEM_NAME = 6
Mock.PURCHASE_ITEM_DISALLOWED_ITEM = 7
Mock.UNIT_LIST_ALL = 1
Mock.UNIT_LIST_ALLIES = 2
Mock.UNIT_LIST_ENEMIES = 3
Mock.UNIT_LIST_ALLIED_HEROES = 4
Mock.UNIT_LIST_ENEMY_HEROES = 5
Mock.UNIT_LIST_ALLIED_CREEPS = 6
Mock.UNIT_LIST_ENEMY_CREEPS = 7
Mock.UNIT_LIST_WARDS = 9
Mock.UNIT_LIST_TREES = 10
Mock.DAMAGE_TYPE_ALL = 0
Mock.DAMAGE_TYPE_PHYSICAL = 1
Mock.DAMAGE_TYPE_MAGICAL = 2
Mock.DAMAGE_TYPE_PURE = 4
Mock.ABILITY_TARGET_TEAM_ENEMY = 1
Mock.ABILITY_TARGET_TEAM_FRIENDLY = 2
Mock.ABILITY_TARGET_TEAM_BOTH = 4
Mock.TOWER_TOP_1 = 1
Mock.TOWER_MID_1 = 2
Mock.TOWER_BOT_1 = 3
Mock.LANE_TOP = 1
Mock.LANE_MID = 2
Mock.LANE_BOT = 3
Mock.LANE_NONE = 0
Mock.MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE = 10

-- Global aliases
_G.GetBot = Mock.GetBot
_G.GetTeam = Mock.GetTeam
_G.GetOpposingTeam = Mock.GetOpposingTeam
_G.GetGameMode = Mock.GetGameMode
_G.GetGameState = Mock.GetGameState
_G.DotaTime = Mock.DotaTime
_G.GetTeamPlayers = Mock.GetTeamPlayers
_G.GetHeroLevel = Mock.GetHeroLevel
_Mock = Mock

return Mock
