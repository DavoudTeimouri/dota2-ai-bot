local X = {}

local J = require(GetScriptDirectory()..'/FunLib/jmz_func')

-- Enemy ultimate cooldown tracker
-- Tracks when we observe enemy ultimates being cast, estimates when they'll be ready again
-- Values are stored keyed by player ID: { abilityName = { castTime = number, cooldown = number } }

local EnemyUltCD = {}

-- Known ultimate cooldowns by hero (base values at level 1; reduced by talents/Aghs)
-- This is a best-effort table; actual cooldowns vary by level and talents
local ULT_COOLDOWNS = {
    -- Strength
    npc_dota_hero_abaddon = 80,
    npc_dota_hero_axe = 60,
    npc_dota_hero_beastmaster = 70,
    npc_dota_hero_brewmaster = 110,
    npc_dota_hero_bristleback = 50,
    npc_dota_hero_chaos_knight = 90,
    npc_dota_hero_crystal_maiden = 120,
    npc_dota_hero_doom_bringer = 100,
    npc_dota_hero_dragon_knight = 100,
    npc_dota_hero_earthshaker = 120,
    npc_dota_hero_giant_killer = 90,
    npc_dota_hero_huskar = 80,
    npc_dota_hero_inkling = 80,
    npc_dota_hero_legion_commander = 80,
    npc_dota_hero_life_stealer = 70,
    npc_dota_hero_luna = 100,
    npc_dota_hero_magnataur = 120,
    npc_dota_hero_mars = 80,
    npc_dota_hero_nevermore = 100,
    npc_dota_hero_ogre_magi = 70,
    npc_dota_hero_omniknight = 100,
    npc_dota_hero_phoenix = 100,
    npc_dota_hero_primal_beast = 90,
    npc_dota_hero_pudge = 60,
    npc_dota_hero_sand_king = 100,
    npc_dota_hero_skeleton_king = 80,
    npc_dota_hero_sven = 90,
    npc_dota_hero_tidehunter = 120,
    npc_dota_hero_tiny = 80,
    npc_dota_hero_undertaker = 90,
    npc_dota_hero_wraith_king = 80,
    -- Agility
    npc_dota_hero_antimage = 80,
    npc_dota_hero_chaos_knight = 90,
    npc_dota_hero_drow_ranger = 90,
    npc_dota_hero_ember_spirit = 70,
    npc_dota_hero_juggernaut = 60,
    npc_dota_hero_kunkka = 90,
    npc_dota_hero_lycan = 90,
    npc_dota_hero_morphling = 100,
    npc_dota_hero_naga_siren = 110,
    npc_dota_hero_nevermore = 100,
    npc_dota_hero_panther = 70,
    npc_dota_hero_phantom_assassin = 100,
    npc_dota_hero_phantom_lancer = 100,
    npc_dota_hero_riki = 60,
    npc_dota_hero_rocket_rat = 80,
    npc_dota_hero_shadow_shaman = 100,
    npc_dota_hero_sniper = 120,
    npc_dota_hero_spectre = 100,
    npc_dota_hero_templar_assassin = 90,
    npc_dota_hero_terrorblade = 120,
    npc_dota_hero_ursa = 90,
    npc_dota_hero_vengefulspirit = 100,
    npc_dota_hero_viper = 100,
    -- Intelligence
    npc_dota_hero_ancient_apparition = 100,
    npc_dota_hero_arc_warden = 100,
    npc_dota_hero_bane = 90,
    npc_dota_hero_batrider = 100,
    npc_dota_hero_bloodseeker = 80,
    npc_dota_hero_centaur = 80,
    npc_dota_hero_dark_seer = 100,
    npc_dota_hero_dark_willow = 100,
    npc_dota_hero_dawnbreaker = 100,
    npc_dota_hero_death_prophet = 100,
    npc_dota_hero_disruptor = 100,
    npc_dota_hero_doom_bringer = 100,
    npc_dota_hero_enchress = 100,
    npc_dota_hero_enigma = 110,
    npc_dota_hero_faceless_void = 90,
    npc_dota_hero_grimstroke = 90,
    npc_dota_hero_invoker = 100,
    npc_dota_hero_jakiro = 100,
    npc_dota_hero_kezu = 90,
    npc_dota_hero_kitten = 80,
    npc_dota_hero_leslie = 90,
    npc_dota_hero_lina = 100,
    npc_dota_hero_lina = 100,
    npc_dota_hero_lion = 80,
    npc_dota_hero_lone_druid = 100,
    npc_dota_hero_lycan = 90,
    npc_dota_hero_mirana = 100,
    npc_dota_hero_morphling = 100,
    npc_dota_hero_naga_siren = 110,
    npc_dota_hero_obsidian_destroyer = 100,
    npc_dota_hero_oracle = 100,
    npc_dota_hero_puck = 60,
    npc_dota_hero_pudge = 60,
    npc_dota_hero_pugna = 80,
    npc_dota_hero_queenofpain = 100,
    npc_dota_hero_razor = 80,
    npc_dota_hero_rewrite = 80,
    npc_dota_hero_rubick = 100,
    npc_dota_hero_sand_king = 100,
    npc_dota_hero_shadow_demon = 80,
    npc_dota_hero_shadow_shaman = 100,
    npc_dota_hero_silencer = 100,
    npc_dota_hero_skywrath_mage = 100,
    npc_dota_hero_slardar = 100,
    npc_dota_hero_snapfire = 100,
    npc_dota_hero_sol = 90,
    npc_dota_hero_spectre = 100,
    npc_dota_hero_stone_fury = 100,
    npc_dota_hero_storm_spirit = 90,
    npc_dota_hero_sven = 90,
    npc_dota_hero_techies = 80,
    npc_dota_hero_templar_assassin = 90,
    npc_dota_hero_terrorblade = 120,
    npc_dota_hero_tidehunter = 120,
    npc_dota_hero_tinker = 100,
    npc_dota_hero_tiny = 80,
    npc_dota_hero_treant_protector = 100,
    npc_dota_hero_undying = 100,
    npc_dota_hero_ursa = 90,
    npc_dota_hero_vengefulspirit = 100,
    npc_dota_hero_venomancer = 100,
    npc_dota_hero_viper = 100,
    npc_dota_hero_void_spirit = 90,
    npc_dota_hero_warlock = 100,
    npc_dota_hero_weaver = 70,
    npc_dota_hero_windrunner = 100,
    npc_dota_hero_winter_wyvern = 100,
    npc_dota_hero_witch_doctor = 100,
    npc_dota_hero_zuus = 80,
}

-- Record an ultimate cast for an enemy player
function X.NotifyUltCast(playerID, abilityName, castTime)
    if not EnemyUltCD[playerID] then
        EnemyUltCD[playerID] = {}
    end
    local cd = ULT_COOLDOWNS[abilityName] or 100
    EnemyUltCD[playerID][abilityName] = {
        castTime = castTime or DotaTime(),
        cooldown = cd,
    }
end

-- Get remaining cooldown for a hero's ultimate, or nil if unknown
function X.GetUltRemaining(playerID, abilityName)
    if not EnemyUltCD[playerID] or not EnemyUltCD[playerID][abilityName] then
        return nil
    end
    local data = EnemyUltCD[playerID][abilityName]
    local elapsed = DotaTime() - data.castTime
    local remaining = data.cooldown - elapsed
    if remaining <= 0 then
        return 0 -- Ready
    end
    return remaining
end

-- Check if a hero's ultimate is ready (unknown = assume ready)
function X.IsUltReady(playerID, abilityName)
    local rem = X.GetUltRemaining(playerID, abilityName)
    if rem == nil then
        return true -- Unknown, assume ready (conservative)
    end
    return rem <= 0
end

-- Get all tracked ultimates for a player
function X.GetPlayerUltCDs(playerID)
    return EnemyUltCD[playerID] or {}
end

-- Clear all tracking (call on new game)
function X.Reset()
    EnemyUltCD = {}
end

return X
