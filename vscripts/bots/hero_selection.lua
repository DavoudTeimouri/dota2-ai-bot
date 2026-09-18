-- Hero Selection: Role-based picking with GuideIntegration + Patch741f
-- Sequential pick/ban with role-specific intelligence

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

-- Position-to-hero pools with attribute preferences
local POSITION_HEROES = {
    [1] = { -- Safe Lane Carry - Agility preferred
        {hero = "npc_dota_hero_antimage", attr = "agi"},
        {hero = "npc_dota_hero_phantom_assassin", attr = "agi"},
        {hero = "npc_dota_hero_medusa", attr = "agi"},
        {hero = "npc_dota_hero_spectre", attr = "agi"},
        {hero = "npc_dota_hero_terrorblade", attr = "agi"},
        {hero = "npc_dota_hero_morphling", attr = "agi"},
        {hero = "npc_dota_hero_faceless_void", attr = "agi"},
        {hero = "npc_dota_hero_phantom_lancer", attr = "agi"},
        {hero = "npc_dota_hero_naga_siren", attr = "agi"},
        {hero = "npc_dota_hero_chaos_knight", attr = "str"},
        {hero = "npc_dota_hero_luna", attr = "agi"},
        {hero = "npc_dota_hero_juggernaut", attr = "agi"},
        {hero = "npc_dota_hero_sven", attr = "str"},
        {hero = "npc_dota_hero_lifestealer", attr = "str"},
        {hero = "npc_dota_hero_troll_warlord", attr = "agi"},
    },
    [2] = { -- Mid Lane - Intelligence preferred
        {hero = "npc_dota_hero_storm_spirit", attr = "int"},
        {hero = "npc_dota_hero_ember_spirit", attr = "agi"},
        {hero = "npc_dota_hero_invoker", attr = "int"},
        {hero = "npc_dota_hero_puck", attr = "int"},
        {hero = "npc_dota_hero_queenofpain", attr = "int"},
        {hero = "npc_dota_hero_templar_assassin", attr = "agi"},
        {hero = "npc_dota_hero_nevermore", attr = "agi"},
        {hero = "npc_dota_hero_outworld_destroyer", attr = "int"},
        {hero = "npc_dota_hero_pangolier", attr = "agi"},
        {hero = "npc_dota_hero_monkey_king", attr = "str"},
        {hero = "npc_dota_hero_void_spirit", attr = "int"},
        {hero = "npc_dota_hero_zeus", attr = "int"},
        {hero = "npc_dota_hero_lesherac", attr = "int"},
        {hero = "npc_dota_hero_lina", attr = "int"},
        {hero = "npc_dota_hero_sky_wrath_mage", attr = "int"},
    },
    [3] = { -- Offlane - Strength preferred (tanky)
        {hero = "npc_dota_hero_tidehunter", attr = "str"},
        {hero = "npc_dota_hero_axe", attr = "str"},
        {hero = "npc_dota_hero_centaur", attr = "str"},
        {hero = "npc_dota_hero_mars", attr = "str"},
        {hero = "npc_dota_hero_dark_seer", attr = "int"},
        {hero = "npc_dota_hero_timbersaw", attr = "str"},
        {hero = "npc_dota_hero_underlord", attr = "str"},
        {hero = "npc_dota_hero_beastmaster", attr = "str"},
        {hero = "npc_dota_hero_batrider", attr = "int"},
        {hero = "npc_dota_hero_enigma", attr = "int"},
        {hero = "npc_dota_hero_sand_king", attr = "str"},
        {hero = "npc_dota_hero_elder_titan", attr = "str"},
        {hero = "npc_dota_hero_primal_beast", attr = "str"},
        {hero = "npc_dota_hero_doom_bringer", attr = "str"},
        {hero = "npc_dota_hero_necrolyte", attr = "int"},
    },
    [4] = { -- Roaming Support / Soft Support - Intelligence preferred
        {hero = "npc_dota_hero_earthshaker", attr = "str"},
        {hero = "npc_dota_hero_mirana", attr = "agi"},
        {hero = "npc_dota_hero_bounty_hunter", attr = "agi"},
        {hero = "npc_dota_hero_riki", attr = "agi"},
        {hero = "npc_dota_hero_pudge", attr = "str"},
        {hero = "npc_dota_hero_spirit_breaker", attr = "str"},
        {hero = "npc_dota_hero_grimstroke", attr = "int"},
        {hero = "npc_dota_hero_marci", attr = "str"},
        {hero = "npc_dota_hero_hoodwink", attr = "agi"},
        {hero = "npc_dota_hero_willow", attr = "int"},
        {hero = "npc_dota_hero_shadow_shaman", attr = "int"},
        {hero = "npc_dota_hero_lion", attr = "int"},
        {hero = "npc_dota_hero_ogre_magi", attr = "int"},
        {hero = "npc_dota_hero_vengefulspirit", attr = "agi"},
        {hero = "npc_dota_hero_tusk", attr = "str"},
    },
    [5] = { -- Hard Support - Intelligence preferred
        {hero = "npc_dota_hero_crystal_maiden", attr = "int"},
        {hero = "npc_dota_hero_witch_doctor", attr = "int"},
        {hero = "npc_dota_hero_lich", attr = "int"},
        {hero = "npc_dota_hero_omniknight", attr = "str"},
        {hero = "npc_dota_hero_dazzle", attr = "int"},
        {hero = "npc_dota_hero_warlock", attr = "int"},
        {hero = "npc_dota_hero_shadow_demon", attr = "int"},
        {hero = "npc_dota_hero_bane", attr = "int"},
        {hero = "npc_dota_hero_jakiro", attr = "int"},
        {hero = "npc_dota_hero_snapfire", attr = "int"},
        {hero = "npc_dota_hero_treant", attr = "str"},
        {hero = "npc_dota_hero_keeper_of_the_light", attr = "int"},
        {hero = "npc_dota_hero_ancient_apparition", attr = "int"},
        {hero = "npc_dota_hero_disruptor", attr = "int"},
        {hero = "npc_dota_hero_rubick", attr = "int"},
    },
}

-- Track picked heroes
local pickedHeroes = {}

-- Track pick/ban phase state
HeroSelection.phaseState = {
    isCaptainMode = false,
    pickOrder = {},
    currentPickIndex = 1,
    bans = {},
    picks = {},
}

function HeroSelection:GetBotPosition(bot)
    local role = bot:GetRole()
    return ROLE_TO_POSITION[role] or 3
end

function HeroSelection:GetAvailableHeroesForPosition(position)
    local pool = POSITION_HEROES[position] or POSITION_HEROES[3]
    local available = {}
    for _, heroData in ipairs(pool) do
        if not pickedHeroes[heroData.hero] then
            table.insert(available, heroData)
        end
    end
    return available
end

function HeroSelection:FilterByAttribute(heroes, preferredAttr)
    -- Prefer heroes with matching primary attribute
    local filtered = {}
    for _, heroData in ipairs(heroes) do
        if heroData.attr == preferredAttr then
            table.insert(filtered, heroData)
        end
    end
    -- If no matches, return original list
    if #filtered == 0 then return heroes end
    return filtered
end

function HeroSelection:SelectHero(bot)
    local position = self:GetBotPosition(bot)
    local available = self:GetAvailableHeroesForPosition(position)
    
    if #available == 0 then
        available = self:GetAvailableHeroesForPosition(3)
    end
    
    -- Filter by preferred attribute for role
    local preferredAttr = self:GetPreferredAttribute(position)
    available = self:FilterByAttribute(available, preferredAttr)
    
    -- Check for guide-recommended hero for this position
    local guideHero = GuideIntegration:GetRecommendedHero(position)
    if guideHero and not pickedHeroes[guideHero] then
        for _, heroData in ipairs(available) do
            if heroData.hero == guideHero then
                pickedHeroes[heroData.hero] = true
                return heroData.hero
            end
        end
    end
    
    -- Weighted random: prefer heroes with guide builds
    local weighted = {}
    for _, heroData in ipairs(available) do
        local weight = 1
        if GuideIntegration:GetHeroGuide(heroData.hero, position) then
            weight = 3
        end
        if Patch741f:GetHeroAdjustments(heroData.hero) then
            weight = weight + 1
        end
        for i = 1, weight do
            table.insert(weighted, heroData.hero)
        end
    end
    
    local selected = weighted[math.random(#weighted)]
    pickedHeroes[selected] = true
    return selected
end

function HeroSelection:GetPreferredAttribute(position)
    -- Position 1 (Carry): Agility
    -- Position 2 (Mid): Intelligence
    -- Position 3 (Offlane): Strength
    -- Position 4 (Roaming Support): Intelligence
    -- Position 5 (Hard Support): Intelligence
    if position == 1 then return "agi"
    elseif position == 2 then return "int"
    elseif position == 3 then return "str"
    elseif position == 4 then return "int"
    elseif position == 5 then return "int"
    else return "int" end
end

function HeroSelection:OnHeroSelected(heroName)
    pickedHeroes[heroName] = true
end

function HeroSelection:Reset()
    pickedHeroes = {}
end

-- Sequential pick/ban logic for Captain's Mode
function HeroSelection:ProcessCaptainModePickBan()
    if not self.phaseState.isCaptainMode then return end
    
    -- This would be called during draft phase
    -- Implement sequential picking logic here
end

function HeroSelection:GetPickBanRecommendations()
    -- Return recommended picks/bans based on current draft state
    local recommendations = {picks = {}, bans = {}}
    
    -- Analyze enemy picks and suggest counters
    local humanRoles = self:GetHumanRoles()
    local enemyPicks = self:GetEnemyPicks()
    local bannedHeroes = self.phaseState.bans
    
    local pick = GameIntelligence.PickBan:GetBestPick(humanRoles, enemyPicks, bannedHeroes)
    if pick then
        table.insert(recommendations.picks, pick)
    end
    
    -- Ban suggestions: high meta strength heroes not yet banned
    for heroName, data in pairs(GameIntelligence.PickBan.heroDatabase) do
        if not bannedHeroes[heroName] and not self:IsPicked(heroName) then
            if data.metaStrength > 0.85 then
                table.insert(recommendations.bans, heroName)
            end
        end
    end
    
    return recommendations
end

function HeroSelection:GetHumanRoles()
    local roles = {carry = false, mid = false, offlane = false, support = false}
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and not PlayerResource:IsFakeClient(i) then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                local name = hero:GetUnitName()
                if name:find("antimage") or name:find("juggernaut") or name:find("phantom_assassin") or name:find("spectre") or name:find("medusa") then
                    roles.carry = true
                elseif name:find("invoker") or name:find("storm") or name:find("templar") or name:find("puck") or name:find("ember") then
                    roles.mid = true
                elseif name:find("centaur") or name:find("tidehunter") or name:find("dragon_knight") or name:find("axe") or name:find("mars") then
                    roles.offlane = true
                else
                    roles.support = true
                end
            end
        end
    end
    return roles
end

function HeroSelection:GetEnemyPicks()
    local picks = {}
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= GetTeam() then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                table.insert(picks, hero:GetUnitName())
            end
        end
    end
    return picks
end

function HeroSelection:IsPicked(heroName)
    return pickedHeroes[heroName] == true
end

-- Required Dota 2 API
function Think()
    -- Called by engine during hero selection phase
end

return HeroSelection