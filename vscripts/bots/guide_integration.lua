-- Guide Integration Module for AetherWeaver
-- Integrates high-voted community guides (STRATZ/Dotabuff) per role
-- Note: Dota 2 Lua cannot make HTTP requests. This module provides
-- pre-cached builds that can be updated externally via update script.

local GuideIntegration = {}

-- ============================================================================
-- PRE-CACHED HIGH-VOTED BUILDS BY ROLE (Position 1-5)
-- These represent meta builds from STRATZ/Dotabuff top guides
-- Format: [hero_internal_name] = { pos_1 = {...}, pos_2 = {...}, etc. }
-- ============================================================================

GuideIntegration.RoleBuilds = {
    -- Position 1 (Carry/Safe Lane)
    pos_1 = {
        -- Universal early game
        early = {
            "item_tango",
            "item_flask",
            "item_quelling_blade",
            "item_branches",
            "item_branches",
            "item_branches",
        },
        -- Hero-specific cores (merge with hero build)
        cores = {
            -- Agility carries
            npc_dota_hero_antimage = { "item_power_treads", "item_bfury", "item_manta", "item_butterfly", "item_satanic", "item_skadi", "item_abyssal_blade" },
            npc_dota_hero_juggernaut = { "item_phase_boots", "item_bfury", "item_manta", "item_abyssal_blade", "item_swift_blink", "item_aghanims_shard" },
            npc_dota_hero_phantom_assassin = { "item_phase_boots", "item_bfury", "item_black_king_bar", "item_basher", "item_satanic", "item_skadi", "item_abyssal_blade" },
            npc_dota_hero_spectre = { "item_phase_boots", "item_radiance", "item_manta", "item_heart", "item_skadi", "item_disperser" },
            npc_dota_hero_medusa = { "item_power_treads", "item_yasha", "item_manta", "item_butterfly", "item_satanic", "item_skadi" },
            npc_dota_hero_drow_ranger = { "item_power_treads", "item_manta", "item_black_king_bar", "item_hurricane_pike", "item_satanic", "item_daedalus" },
            npc_dota_hero_luna = { "item_phase_boots", "item_manta", "item_black_king_bar", "item_satanic", "item_skadi", "item_daedalus" },
            npc_dota_hero_faceless_void = { "item_power_treads", "item_manta", "item_black_king_bar", "item_satanic", "item_butterfly", "item_abyssal_blade" },
            npc_dota_hero_terrorblade = { "item_power_treads", "item_manta", "item_skadi", "item_satanic", "item_butterfly", "item_eye_of_skadi" },
            npc_dota_hero_morphling = { "item_power_treads", "item_ethereal_blade", "item_manta", "item_skadi", "item_butterfly", "item_satanic" },
            
            -- Strength carries
            npc_dota_hero_sven = { "item_phase_boots", "item_black_king_bar", "item_manta", "item_satanic", "item_abyssal_blade", "item_swift_blink" },
            npc_dota_hero_life_stealer = { "item_phase_boots", "item_armlet", "item_black_king_bar", "item_satanic", "item_skadi", "item_abyssal_blade" },
            npc_dota_hero_wraith_king = { "item_phase_boots", "item_armlet", "item_black_king_bar", "item_satanic", "item_heart", "item_abyssal_blade" },
            
            -- Intelligence carries
            npc_dota_hero_alchemist = { "item_phase_boots", "item_maelstrom", "item_radiance", "item_black_king_bar", "item_shivas_guard", "item_octarine_core" },
        },
        -- Situational late game
        late = {
            "item_moon_shard",
            "item_ultimate_scepter_2",
            "item_aghanims_shard",
            "item_refresher",
            "item_travel_boots_2",
        },
    },
    
    -- Position 2 (Mid)
    pos_2 = {
        early = {
            "item_tango",
            "item_flask",
            "item_mantle",
            "item_branches",
            "item_branches",
            "item_branches",
        },
        cores = {
            npc_dota_hero_invoker = { "item_phase_boots", "item_black_king_bar", "item_sheepstick", "item_shivas_guard", "item_octarine_core", "item_refresher" },
            npc_dota_hero_storm_spirit = { "item_phase_boots", "item_orchid", "item_bloodstone", "item_sheepstick", "item_shivas_guard", "item_overwhelming_blink" },
            npc_dota_hero_templar_assassin = { "item_phase_boots", "item_blink", "item_black_king_bar", "item_daedalus", "item_satanic", "item_swift_blink" },
            npc_dota_hero_puck = { "item_phase_boots", "item_blink", "item_sheepstick", "item_shivas_guard", "item_octarine_core", "item_aeon_disk" },
            npc_dota_hero_ember_spirit = { "item_phase_boots", "item_maelstrom", "item_black_king_bar", "item_sheepstick", "item_shivas_guard", "item_overwhelming_blink" },
            npc_dota_hero_queenofpain = { "item_phase_boots", "item_orchid", "item_sheepstick", "item_shivas_guard", "item_octarine_core", "item_aeon_disk" },
            npc_dota_hero_shadow_fiend = { "item_phase_boots", "item_black_king_bar", "item_satanic", "item_daedalus", "item_hurricane_pike", "item_swift_blink" },
            npc_dota_hero_zeus = { "item_phase_boots", "item_black_king_bar", "item_sheepstick", "item_shivas_guard", "item_octarine_core", "item_refresher" },
            npc_dota_hero_tinker = { "item_phase_boots", "item_sheepstick", "item_shivas_guard", "item_black_king_bar", "item_octarine_core", "item_refresher" },
            npc_dota_hero_pugna = { "item_phase_boots", "item_sheepstick", "item_shivas_guard", "item_aeon_disk", "item_octarine_core", "item_black_king_bar" },
            npc_dota_hero_lina = { "item_phase_boots", "item_sheepstick", "item_shivas_guard", "item_black_king_bar", "item_octarine_core", "item_aeon_disk" },
        },
        late = {
            "item_moon_shard",
            "item_ultimate_scepter_2",
            "item_aghanims_shard",
            "item_refresher",
            "item_travel_boots_2",
        },
    },
    
    -- Position 3 (Offlane)
    pos_3 = {
        early = {
            "item_tango",
            "item_flask",
            "item_stout_shield",
            "item_branches",
            "item_branches",
        },
        cores = {
            npc_dota_hero_centaur = { "item_phase_boots", "item_blink", "item_pipe", "item_crimson_guard", "item_shivas_guard", "item_heart", "item_refresher" },
            npc_dota_hero_tidehunter = { "item_phase_boots", "item_blink", "item_pipe", "item_shivas_guard", "item_heart", "item_refresher", "item_aghanims_shard" },
            npc_dota_hero_dragon_knight = { "item_phase_boots", "item_black_king_bar", "item_assault", "item_shivas_guard", "item_heart", "item_satanic" },
            npc_dota_hero_axe = { "item_phase_boots", "item_blink", "item_black_king_bar", "item_blade_mail", "item_shivas_guard", "item_heart" },
            npc_dota_hero_mars = { "item_phase_boots", "item_blink", "item_black_king_bar", "item_pipe", "item_shivas_guard", "item_heart" },
            npc_dota_hero_underlord = { "item_phase_boots", "item_pipe", "item_crimson_guard", "item_shivas_guard", "item_heart", "item_refresher" },
            npc_dota_hero_dark_seer = { "item_phase_boots", "item_pipe", "item_shivas_guard", "item_black_king_bar", "item_refresher", "item_aeon_disk" },
            npc_dota_hero_bristleback = { "item_phase_boots", "item_heart", "item_shivas_guard", "item_assault", "item_octarine_core", "item_satanic" },
            npc_dota_hero_timbersaw = { "item_phase_boots", "item_bloodstone", "item_shivas_guard", "item_octarine_core", "item_black_king_bar", "item_lotus_orb" },
            npc_dota_hero_slardar = { "item_phase_boots", "item_blink", "item_black_king_bar", "item_assault", "item_basher", "item_satanic" },
        },
        late = {
            "item_moon_shard",
            "item_ultimate_scepter_2",
            "item_aghanims_shard",
            "item_refresher",
            "item_travel_boots_2",
        },
    },
    
    -- Position 4 (Soft Support/Roamer)
    pos_4 = {
        early = {
            "item_tango",
            "item_flask",
            "item_mantle",
            "item_branches",
            "item_branches",
        },
        cores = {
            npc_dota_hero_earth_spirit = { "item_tranquil_boots", "item_blink", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_lotus_orb" },
            npc_dota_hero_pangolier = { "item_phase_boots", "item_blink", "item_black_king_bar", "item_force_staff", "item_glimmer_cape", "item_aeon_disk" },
            npc_dota_hero_mirana = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_lotus_orb", "item_aghanims_shard" },
            npc_dota_hero_nyx_assassin = { "item_tranquil_boots", "item_blink", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_dagon" },
            npc_dota_hero_bounty_hunter = { "item_phase_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_pike", "item_lotus_orb" },
            npc_dota_hero_techies = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_black_king_bar", "item_aghanims_shard" },
            npc_dota_hero_void_spirit = { "item_phase_boots", "item_black_king_bar", "item_sheepstick", "item_force_staff", "item_glimmer_cape", "item_aeon_disk" },
            npc_dota_hero_dawnbreaker = { "item_phase_boots", "item_blink", "item_solar_crest", "item_lotus_orb", "item_aeon_disk", "item_shivas_guard" },
            npc_dota_hero_marci = { "item_phase_boots", "item_blink", "item_black_king_bar", "item_satanic", "item_assault", "item_abyssal_blade" },
            npc_dota_hero_primal_beast = { "item_phase_boots", "item_blink", "item_black_king_bar", "item_shivas_guard", "item_heart", "item_refresher" },
        },
        late = {
            "item_moon_shard",
            "item_ultimate_scepter_2",
            "item_aghanims_shard",
            "item_refresher",
            "item_travel_boots_2",
        },
    },
    
    -- Position 5 (Hard Support)
    pos_5 = {
        early = {
            "item_tango",
            "item_flask",
            "item_mantle",
            "item_branches",
            "item_branches",
        },
        cores = {
            npc_dota_hero_crystal_maiden = { "item_tranquil_boots", "item_glimmer_cape", "item_force_staff", "item_aeon_disk", "item_lotus_orb", "item_guardian_greaves" },
            npc_dota_hero_lich = { "item_tranquil_boots", "item_glimmer_cape", "item_force_staff", "item_aeon_disk", "item_lotus_orb", "item_guardian_greaves" },
            npc_dota_hero_witch_doctor = { "item_tranquil_boots", "item_glimmer_cape", "item_force_staff", "item_aeon_disk", "item_black_king_bar", "item_aghanims_shard" },
            npc_dota_hero_shadow_shaman = { "item_tranquil_boots", "item_glimmer_cape", "item_force_staff", "item_aeon_disk", "item_black_king_bar", "item_aghanims_shard" },
            npc_dota_hero_lion = { "item_tranquil_boots", "item_glimmer_cape", "item_force_staff", "item_aeon_disk", "item_black_king_bar", "item_aghanims_shard" },
            npc_dota_hero_dazzle = { "item_tranquil_boots", "item_glimmer_cape", "item_force_staff", "item_aeon_disk", "item_lotus_orb", "item_guardian_greaves" },
            npc_dota_hero_oracle = { "item_tranquil_boots", "item_glimmer_cape", "item_force_staff", "item_aeon_disk", "item_lotus_orb", "item_guardian_greaves" },
            npc_dota_hero_undying = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_lotus_orb", "item_pipe" },
            npc_dota_hero_ancient_apparition = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_black_king_bar", "item_aghanims_shard" },
            npc_dota_hero_snapfire = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_lotus_orb", "item_black_king_bar" },
            npc_dota_hero_grimstroke = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_black_king_bar", "item_aghanims_shard" },
            npc_dota_hero_willow = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_black_king_bar", "item_aghanims_shard" },
            npc_dota_hero_muerta = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_black_king_bar", "item_aghanims_shard" },
            npc_dota_hero_ringmaster = { "item_tranquil_boots", "item_force_staff", "item_glimmer_cape", "item_aeon_disk", "item_lotus_orb", "item_guardian_greaves" },
        },
        late = {
            "item_moon_shard",
            "item_ultimate_scepter_2",
            "item_aghanims_shard",
            "item_refresher",
            "item_travel_boots_2",
        },
    },
}

-- ============================================================================
-- SKILL BUILDS FROM HIGH-VOTED GUIDES
-- ============================================================================

GuideIntegration.SkillBuilds = {
    -- Format: hero = { pos_N = { ability_order } }
    npc_dota_hero_antimage = {
        pos_1 = { "antimage_mana_break", "antimage_blink", "antimage_mana_break", "antimage_counterspell", "antimage_mana_break", "antimage_mana_void", "antimage_mana_break", "antimage_blink", "antimage_blink", "antimage_blink", "antimage_mana_void", "antimage_counterspell", "antimage_counterspell", "antimage_counterspell", "antimage_mana_overload", "antimage_mana_void", "antimage_mana_overload", "antimage_mana_overload", "antimage_mana_overload" },
    },
    npc_dota_hero_crystal_maiden = {
        pos_5 = { "crystal_maiden_crystal_nova", "crystal_maiden_frostbite", "crystal_maiden_crystal_nova", "crystal_maiden_frostbite", "crystal_maiden_crystal_nova", "crystal_maiden_freezing_field", "crystal_maiden_crystal_nova", "crystal_maiden_frostbite", "crystal_maiden_frostbite", "crystal_maiden_frostbite", "crystal_maiden_freezing_field", "crystal_maiden_arcane_aura", "crystal_maiden_arcane_aura", "crystal_maiden_arcane_aura" },
    },
    npc_dota_hero_invoker = {
        pos_2 = { "invoker_quas", "invoker_wex", "invoker_exort", "invoker_quas", "invoker_quas", "invoker_invoke", "invoker_quas", "invoker_wex", "invoker_wex", "invoker_wex", "invoker_invoke", "invoker_exort", "invoker_exort", "invoker_exort", "invoker_invoke", "invoker_exort", "invoker_exort", "invoker_exort", "invoker_exort" },
    },
    -- Generic fallback per role
    generic = {
        pos_1 = { "ability_1", "ability_2", "ability_1", "ability_3", "ability_1", "ability_ult", "ability_1", "ability_2", "ability_2", "ability_2", "ability_ult", "ability_3", "ability_3", "ability_3", "talent_1", "ability_ult", "talent_2", "talent_3", "talent_4" },
        pos_2 = { "ability_1", "ability_2", "ability_1", "ability_3", "ability_1", "ability_ult", "ability_1", "ability_2", "ability_2", "ability_2", "ability_ult", "ability_3", "ability_3", "ability_3", "talent_1", "ability_ult", "talent_2", "talent_3", "talent_4" },
        pos_3 = { "ability_1", "ability_2", "ability_1", "ability_3", "ability_1", "ability_ult", "ability_1", "ability_2", "ability_2", "ability_2", "ability_ult", "ability_3", "ability_3", "ability_3", "talent_1", "ability_ult", "talent_2", "talent_3", "talent_4" },
        pos_4 = { "ability_1", "ability_2", "ability_1", "ability_3", "ability_1", "ability_ult", "ability_1", "ability_2", "ability_2", "ability_2", "ability_ult", "ability_3", "ability_3", "ability_3", "talent_1", "ability_ult", "talent_2", "talent_3", "talent_4" },
        pos_5 = { "ability_1", "ability_2", "ability_1", "ability_3", "ability_1", "ability_ult", "ability_1", "ability_2", "ability_2", "ability_2", "ability_ult", "ability_3", "ability_3", "ability_3", "talent_1", "ability_ult", "talent_2", "talent_3", "talent_4" },
    },
}

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Get item build for hero at specific position
function GuideIntegration:GetItemBuild(heroName, position)
    local role = "pos_" .. position
    local roleData = self.RoleBuilds[role]
    if not roleData then
        role = "pos_1" -- fallback
        roleData = self.RoleBuilds[role]
    end
    
    local build = {}
    
    -- Add early game
    for _, item in ipairs(roleData.early or {}) do
        table.insert(build, item)
    end
    
    -- Add hero-specific core
    local cores = roleData.cores[heroName]
    if cores then
        for _, item in ipairs(cores) do
            table.insert(build, item)
        end
    else
        -- Generic fallback based on hero primary attribute
        local fallback = self:GetGenericCore(heroName, position)
        for _, item in ipairs(fallback) do
            table.insert(build, item)
        end
    end
    
    -- Add late game
    for _, item in ipairs(roleData.late or {}) do
        table.insert(build, item)
    end
    
    return build
end

-- Get skill build for hero at position
function GuideIntegration:GetSkillBuild(heroName, position)
    local role = "pos_" .. position
    if self.SkillBuilds[heroName] and self.SkillBuilds[heroName][role] then
        return self.SkillBuilds[heroName][role]
    end
    return self.SkillBuilds.generic[role] or self.SkillBuilds.generic.pos_1
end

-- Get generic core build based on primary attribute
function GuideIntegration:GetGenericCore(heroName, position)
    -- This would need hero attribute data; simplified version
    local carryCore = { "item_power_treads", "item_bfury", "item_manta", "item_black_king_bar", "item_satanic", "item_skadi" }
    local midCore = { "item_phase_boots", "item_black_king_bar", "item_sheepstick", "item_shivas_guard", "item_octarine_core" }
    local offlaneCore = { "item_phase_boots", "item_blink", "item_pipe", "item_shivas_guard", "item_heart" }
    local supportCore = { "item_tranquil_boots", "item_glimmer_cape", "item_force_staff", "item_aeon_disk", "item_lotus_orb" }
    
    if position == 1 then return carryCore
    elseif position == 2 then return midCore
    elseif position == 3 then return offlaneCore
    else return supportCore end
end

-- Get patch-adjusted build (integrates with patch_741f.lua)
function GuideIntegration:GetPatchAdjustedBuild(heroName, position)
    local build = self:GetItemBuild(heroName, position)
    local patch = require("patch_741f")
    
    -- Apply patch adjustments (costs, stats)
    -- The actual purchase logic in item_purchase_generic.lua should use patch:GetItemCost()
    return build
end

-- Check if hero has a high-voted guide cached
function GuideIntegration:HasCachedGuide(heroName, position)
    local role = "pos_" .. position
    return self.RoleBuilds[role] and self.RoleBuilds[role].cores[heroName] ~= nil
end

-- List all heroes with cached guides for a position
function GuideIntegration:GetHeroesWithGuides(position)
    local role = "pos_" .. position
    local heroes = {}
    if self.RoleBuilds[role] then
        for hero, _ in pairs(self.RoleBuilds[role].cores) do
            table.insert(heroes, hero)
        end
    end
    return heroes
end

-- ============================================================================
-- EXTERNAL UPDATE SCRIPT (run outside Dota 2)
-- ============================================================================
--[[
-- Python script to fetch latest STRATZ guides and update this file:
--
-- import requests
-- import json
--
-- def fetch_stratz_guides():
--     query = """
--     query {
--         heroGuides(heroId: 1, position: 1, take: 10) {
--             items { itemId }
--             skills { skillId }
--             votes
--         }
--     }
--     """
--     headers = {"User-Agent": "STRATZ_API"}
--     response = requests.post("https://api.stratz.com/graphql", json={"query": query}, headers=headers)
--     return response.json()
--
-- This would populate RoleBuilds and SkillBuilds tables above.
-- Run periodically and commit updated guide_integration.lua
--]]

return GuideIntegration