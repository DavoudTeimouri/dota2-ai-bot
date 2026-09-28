-- Skill build think function (engine hook)
function SkillBuildThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        SkillBuildGeneric:SkillBuildThink(bot)
    end
end

-- Skill build module
local SkillBuildGeneric = {}

-- Generic skill builds per hero role
local SKILL_BUILDS = {
    -- Carry builds
    carry_generic = {
        max_first = {"1", "1", "2", "3", "1", "4", "1", "2", "2", "2", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
    -- Mid builds (often max nuke first)
    mid_generic = {
        max_first = {"2", "2", "1", "3", "2", "4", "2", "1", "1", "1", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
    -- Offlane builds (often tanky/sustain)
    offlane_generic = {
        max_first = {"1", "2", "1", "3", "1", "4", "1", "2", "2", "2", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
    -- Support builds (max utility)
    support_generic = {
        max_first = {"1", "2", "1", "3", "1", "4", "1", "2", "2", "2", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
}

-- Get skill build for bot
function SkillBuildGeneric:GetSkillBuild(bot)
    local heroName = bot:GetUnitName()
    local role = bot:GetRole() or "carry"
    local lane = bot:GetAssignedLane() or "safe"
    
    -- Try hero-specific override
    if self.heroOverrides[heroName] then
        return self.heroOverrides[heroName]
    end
    
    -- Role-based fallback
    if role == "mid" or lane == "mid" then return SKILL_BUILDS.mid_generic end
    if role == "offlane" or lane == "off" then return SKILL_BUILDS.offlane_generic end
    if role == "support" or role == "hard_support" then return SKILL_BUILDS.support_generic end
    return SKILL_BUILDS.carry_generic
end

-- Hero-specific overrides (partial examples)
SkillBuildGeneric.heroOverrides = {
    ["npc_dota_hero_antimage"] = {
        max_first = {"2", "1", "2", "3", "2", "4", "2", "1", "1", "1", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
    ["npc_dota_hero_crystal_maiden"] = {
        max_first = {"1", "2", "1", "3", "1", "4", "1", "2", "2", "2", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
    ["npc_dota_hero_axe"] = {
        max_first = {"1", "2", "1", "3", "1", "4", "1", "2", "2", "2", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
    ["npc_dota_hero_pudge"] = {
        max_first = {"2", "1", "2", "3", "2", "4", "2", "1", "1", "1", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
    ["npc_dota_hero_sniper"] = {
        max_first = {"1", "2", "1", "3", "1", "4", "1", "2", "2", "2", "4", "3", "3", "3", "4"},
        stats = {"stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats", "stats"},
    },
}

-- Main skill build think
function SkillBuildGeneric:SkillBuildThink(bot)
    if bot:GetAbilityPoints() <= 0 then return end
    
    local build = self:GetSkillBuild(bot)
    local maxFirst = build.max_first or {}
    
    -- Level up abilities in order
    for _, abilityIndex in ipairs(maxFirst) do
        if bot:GetAbilityPoints() <= 0 then break end
        local ability = bot:GetAbilityByIndex(tonumber(abilityIndex) - 1)
        if ability and ability:CanAbilityBeUpgraded() then
            bot:ActionImmediate_LevelAbility(ability:GetName())
            return
        end
    end
    
    -- If no specific build or all maxed, level any available
    for i = 0, 23 do
        if bot:GetAbilityPoints() <= 0 then break end
        local ability = bot:GetAbilityByIndex(i)
        if ability and ability:CanAbilityBeUpgraded() and not ability:IsAttributeBonus() then
            bot:ActionImmediate_LevelAbility(ability:GetName())
            return
        end
    end
    
    -- Level stats as last resort
    for _, _ in ipairs(build.stats or {}) do
        if bot:GetAbilityPoints() <= 0 then break end
        local statsAbility = bot:GetAbilityByIndex(23) -- Attribute bonus is usually last
        if statsAbility and statsAbility:CanAbilityBeUpgraded() then
            bot:ActionImmediate_LevelAbility(statsAbility:GetName())
            return
        end
    end
end

return SkillBuildGeneric