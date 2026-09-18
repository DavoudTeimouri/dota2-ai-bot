-- Dota 2 Patch 7.41f Integration Module
-- Applies latest patch changes to bot behavior, item builds, and hero adjustments

local Patch741f = {}

-- ============================================================================
-- ITEM COST CHANGES (7.41f)
-- ============================================================================
Patch741f.ItemCostChanges = {
    -- Increased costs
    item_daedalus = {old = 5100, new = 5200, recipe = 1000},
    item_dragon_lance = {old = 1900, new = 2000, recipe = 550},
    item_hurricane_pike = {old = 4450, new = 4550},
    item_heart = {old = 5200, new = 5300, recipe = 800},
    item_octarine_core = {old = 4900, new = 5100, recipe = 400},
    -- Decreased costs
    item_heavens_halberd = {old = 3400, new = 3300},
    -- Neutral items / Hydra's Breath (recipe down but total same)
    item_hydra_breath = {old = 5900, new = 5900, recipe = 1000},
}

-- ============================================================================
-- ITEM STAT CHANGES (7.41f)
-- ============================================================================
Patch741f.ItemStatChanges = {
    item_manta = {illusion_damage_ranged = 0.25}, -- was 0.28
    item_mask_of_madness = {lifesteal = 0.22}, -- was 0.24
    item_satanic = {lifesteal_bonus = 0.25}, -- was 0.30
    item_infused_raindrop = {mana_regen = 0.6}, -- was 0.8
    item_essence_distiller = {mana_regen = 1.5}, -- was 1.75
    item_battle_fury = {chop_tree_cd = 3}, -- was 4
    item_shivas_guard = {arctic_blast_damage = 225}, -- was 260
    item_silver_edge = {shadow_walk_cd_increased = true, ms_bonus_reduced = true},
}

-- ============================================================================
-- HERO CHANGES (7.41f)
-- ============================================================================
Patch741f.HeroChanges = {
    -- Anti-Mage BUFF
    npc_dota_hero_antimage = {
        mana_break_damage_pct = 0.65, -- was 0.60
    },
    -- Treant Protector NERF
    npc_dota_hero_treant = {
        base_int = 17, -- was 20
        leech_seed_mana_cost = 35, -- was 0
        leech_seed_heal_pct = {0.10, 0.15, 0.20, 0.25}, -- was flat 0.20
        living_armor_min_block = 10, -- was 20
        natures_guise_linger = 1, -- was 2
    },
    -- Shadow Fiend NERF
    npc_dota_hero_nevermore = {
        shadowraze_damage_per_soul = 2, -- was 3
        necromastery_dmg_per_soul_changed = true,
        level_15_armor_talent_reduced = true,
    },
    -- Bounty Hunter NERF
    npc_dota_hero_bounty_hunter = {
        track_self_gold = {80, 160, 240}, -- was 130/225/320
        track_ally_gold = {40, 80, 120},
        shuriken_toss_slow_nerf = true,
        talent_swap = true,
    },
    -- Invoker NERF
    npc_dota_hero_invoker = {
        cold_snap_cd = 19, -- was lower
        ghost_walk_shard_no_creep_damage = true,
    },
    -- Lina NERF
    npc_dota_hero_lina = {
        base_int = 28,
        fiery_soul_attack_speed_reduced = true,
        fiery_soul_duration_reduced = true,
    },
    -- Winter Wyvern NERF
    npc_dota_hero_winter_wyvern = {
        arctic_burn_cd_increased = true,
        cold_embrace_early_heal_reduced = true,
    },
    -- Centaur Warrunner NERF
    npc_dota_hero_centaur = {
        base_damage_reduction = 2,
        move_speed = 295, -- was 300
    },
    -- Earth Spirit NERF
    npc_dota_hero_earth_spirit = {
        base_attack_speed = 95, -- was 100
        stone_remnant_charge_scaling = 5, -- was 4 levels per charge
        talent_swap_20_25 = true,
    },
    -- Mirana NERF
    npc_dota_hero_mirana = {
        -- Various nerfs
    },
    -- Kez NERF
    npc_dota_hero_kez = {
        -- Nerfs
    },
    -- Hoodwink NERF
    npc_dota_hero_hoodwink = {
        -- Nerfs
    },
    -- Huskar BUFF (net)
    npc_dota_hero_huskar = {
        str_gain = 3.4, -- was lower (but base str lowered)
    },
    -- Ursa BUFF
    npc_dota_hero_ursa = {
        maul_health_damage_pct = 0.0175, -- was 0.0125
    },
    -- Mars BUFF
    npc_dota_hero_mars = {
        base_armor = 1, -- +1
    },
    -- Chen BUFF
    npc_dota_hero_chen = {
        str_gain = 2.2,
    },
    -- Warlock BUFF
    npc_dota_hero_warlock = {
        base_attack_speed = 95, -- was 90
    },
    -- Largo ADJUSTMENT
    npc_dota_hero_largo = {
        island_elixir_heal_rescaled = true,
    },
}

-- ============================================================================
-- NEUTRAL ITEM / MAP CHANGES
-- ============================================================================
Patch741f.NeutralChanges = {
    -- Neutral items tier changes, etc.
    -- Tormentor, Wisdom rune, etc. unchanged
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get adjusted item cost for 7.41f
function Patch741f:GetItemCost(itemName)
    local change = self.ItemCostChanges[itemName]
    if change and change.new then
        return change.new
    end
    return nil -- Use default game cost
end

-- Get item stat overrides
function Patch741f:GetItemStats(itemName)
    return self.ItemStatChanges[itemName]
end

-- Get hero patch adjustments
function Patch741f:GetHeroAdjustments(heroName)
    return self.HeroChanges[heroName]
end

-- Apply patch adjustments to a bot's item build
function Patch741f:AdjustItemBuild(bot, itemBuild)
    if not itemBuild then return itemBuild end
    
    local adjusted = {}
    for _, item in ipairs(itemBuild) do
        table.insert(adjusted, item)
    end
    
    -- Note: Actual cost checking happens at purchase time via GetItemCost
    return adjusted
end

-- Should bot adjust playstyle for this hero?
function Patch741f:GetHeroPlaystyleAdjustments(heroName)
    local adj = self.HeroChanges[heroName]
    if not adj then return {} end
    
    local adjustments = {}
    
    -- Anti-Mage: more aggressive mana break usage
    if adj.mana_break_damage_pct then
        adjustments.mana_break_aggressive = true
    end
    
    -- Treant: more careful with mana, Living Armor less reliable
    if adj.leech_seed_mana_cost then
        adjustments.conserve_mana = true
        adjustments.living_armor_weaker = true
    end
    
    -- Shadow Fiend: fewer souls needed for same damage? No, less damage per soul
    if adj.shadowraze_damage_per_soul then
        adjustments.need_more_souls = true
    end
    
    -- Bounty Hunter: Track less valuable for gold, more for vision
    if adj.track_self_gold then
        adjustments.track_for_vision = true
    end
    
    -- Invoker: Cold Snap less spammable
    if adj.cold_snap_cd then
        adjustments.cold_snap_conserve = true
    end
    
    return adjustments
end

return Patch741f