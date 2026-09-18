-- Hero Selection: Role-based picking with GuideIntegration + Patch741f
local HeroSelection = {}
local GuideIntegration = require("guide_integration")
local Patch741f = require("patch_741f")

-- Role-to-position mapping for guide lookup
local ROLE_TO_POSITION = {
    [DOTA_BOT_HARD_CARRY] = 1,
    [DOTA_BOT_MID] = 2,
    [DOTA_BOT_OFFLANE] = 3,
    [DOTA_BOT_ROAMING_SUPPORT] = 4,
    [DOTA_BOT_HARD_SUPPORT] = 5,
}

-- Position-to-hero pools (meta heroes per position)
local POSITION_HEROES = {
    [1] = { -- Safe Lane Carry
        "npc_dota_hero_antimage", "npc_dota_hero_phantom_assassin", "npc_dota_hero_medusa",
        "npc_dota_hero_spectre", "npc_dota_hero_terrorblade", "npc_dota_hero_morphling",
        "npc_dota_hero_faceless_void", "npc_dota_hero_phantom_lancer", "npc_dota_hero_naga_siren",
        "npc_dota_hero_chaos_knight", "npc_dota_hero_luna", "npc_dota_hero_juggernaut",
        "npc_dota_hero_sven", "npc_dota_hero_lifestealer", "npc_dota_hero_troll_warlord",
    },
    [2] = { -- Mid Lane
        "npc_dota_hero_storm_spirit", "npc_dota_hero_ember_spirit", "npc_dota_hero_invoker",
        "npc_dota_hero_puck", "npc_dota_hero_queenofpain", "npc_dota_hero_templar_assassin",
        "npc_dota_hero_nevermore", "npc_dota_hero_outworld_destroyer", "npc_dota_hero_pangolier",
        "npc_dota_hero_monkey_king", "npc_dota_hero_void_spirit", "npc_dota_hero_zeus",
        "npc_dota_hero_lesherac", "npc_dota_hero_lina", "npc_dota_hero_sky_wrath_mage",
    },
    [3] = { -- Offlane
        "npc_dota_hero_tidehunter", "npc_dota_hero_axe", "npc_dota_hero_centaur",
        "npc_dota_hero_mars", "npc_dota_hero_dark_seer", "npc_dota_hero_timbersaw",
        "npc_dota_hero_underlord", "npc_dota_hero_beastmaster", "npc_dota_hero_batrider",
        "npc_dota_hero_enigma", "npc_dota_hero_sand_king", "npc_dota_hero_elder_titan",
        "npc_dota_hero_primal_beast", "npc_dota_hero_doom_bringer", "npc_dota_hero_necrolyte",
    },
    [4] = { -- Roaming Support / Soft Support
        "npc_dota_hero_earthshaker", "npc_dota_hero_mirana", "npc_dota_hero_bounty_hunter",
        "npc_dota_hero_riki", "npc_dota_hero_pudge", "npc_dota_hero_spirit_breaker",
        "npc_dota_hero_grimstroke", "npc_dota_hero_marci", "npc_dota_hero_hoodwink",
        "npc_dota_hero_willow", "npc_dota_hero_shadow_shaman", "npc_dota_hero_lion",
        "npc_dota_hero_ogre_magi", "npc_dota_hero_vengefulspirit", "npc_dota_hero_tusk",
    },
    [5] = { -- Hard Support
        "npc_dota_hero_crystal_maiden", "npc_dota_hero_witch_doctor", "npc_dota_hero_lich",
        "npc_dota_hero_omniknight", "npc_dota_hero_dazzle", "npc_dota_hero_warlock",
        "npc_dota_hero_shadow_demon", "npc_dota_hero_bane", "npc_dota_hero_jakiro",
        "npc_dota_hero_snapfire", "npc_dota_hero_treant", "npc_dota_hero_keeper_of_the_light",
        "npc_dota_hero_ancient_apparition", "npc_dota_hero_disruptor", "npc_dota_hero_rubick",
    },
}

-- Track picked heroes
local pickedHeroes = {}

function HeroSelection:GetBotPosition(bot)
    local role = bot:GetRole()
    return ROLE_TO_POSITION[role] or 3
end

function HeroSelection:GetAvailableHeroesForPosition(position)
    local pool = POSITION_HEROES[position] or POSITION_HEROES[3]
    local available = {}
    for _, hero in ipairs(pool) do
        if not pickedHeroes[hero] then
            table.insert(available, hero)
        end
    end
    return available
end

function HeroSelection:SelectHero(bot)
    local position = self:GetBotPosition(bot)
    local available = self:GetAvailableHeroesForPosition(position)
    
    if #available == 0 then
        available = self:GetAvailableHeroesForPosition(3)
    end
    
    -- Check for guide-recommended hero for this position
    local guideHero = GuideIntegration:GetRecommendedHero(position)
    if guideHero and not pickedHeroes[guideHero] then
        for _, hero in ipairs(available) do
            if hero == guideHero then
                pickedHeroes[hero] = true
                return hero
            end
        end
    end
    
    -- Weighted random: prefer heroes with guide builds
    local weighted = {}
    for _, hero in ipairs(available) do
        local weight = 1
        if GuideIntegration:GetHeroGuide(hero, position) then
            weight = 3
        end
        if Patch741f:GetHeroAdjustments(hero) then
            weight = weight + 1
        end
        for i = 1, weight do
            table.insert(weighted, hero)
        end
    end
    
    local selected = weighted[math.random(#weighted)]
    pickedHeroes[selected] = true
    return selected
end

function HeroSelection:OnHeroSelected(heroName)
    pickedHeroes[heroName] = true
end

function HeroSelection:Reset()
    pickedHeroes = {}
end

-- Required Dota 2 API
function Think()
    -- Called by engine during hero selection phase
end

return HeroSelection