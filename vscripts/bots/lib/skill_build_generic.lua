-- Skill Build System for AetherWeaver
-- Loads skill build from GuideIntegration -> Customize/hero -> BotLib -> generic fallback

local SkillBuild = {}

function SkillBuild:Initialize(bot, guideSkillBuild)
    if not bot or bot:IsNull() or not bot:IsHero() or bot:IsIllusion() then
        return false
    end
    
    local heroName = bot:GetUnitName()
    if not heroName or not string.find(heroName, "hero") then
        return false
    end
    
    -- Priority 1: Guide-based skill build
    if guideSkillBuild and #guideSkillBuild > 0 then
        bot.skillBuild = guideSkillBuild
        bot.skillBuildSource = "guide"
        return true
    end
    
    -- Priority 2: Customize/hero (user overrides)
    local customizePath = "bots/Customize/hero/" .. string.gsub(heroName, "npc_dota_hero_", "") .. ".lua"
    local ok, customBuild = pcall(dofile, customizePath)
    if ok and customBuild and customBuild.sSkillList then
        bot.skillBuild = customBuild.sSkillList
        bot.skillBuildSource = "customize"
        return true
    end
    
    -- Priority 3: BotLib (built-in builds)
    local botlibPath = "bots/BotLib/" .. string.gsub(heroName, "npc_dota_hero_", "") .. ".lua"
    ok, customBuild = pcall(dofile, botlibPath)
    if ok and customBuild and customBuild.sSkillList then
        bot.skillBuild = customBuild.sSkillList
        bot.skillBuildSource = "botlib"
        return true
    end
    
    -- Priority 4: Generic fallback
    bot.skillBuild = self:GetGenericSkillBuild(bot)
    bot.skillBuildSource = "generic"
    return true
end

function SkillBuild:GetGenericSkillBuild(bot)
    local heroName = bot:GetUnitName()
    local abilities = {}
    local talents = {}
    local ultimate = nil
    
    -- Get all abilities and talents
    for i = 0, 23 do
        local abil = bot:GetAbilityByIndex(i)
        if abil and not abil:IsPassive() and not abil:IsHidden() then
            if abil:IsUltimate() then
                ultimate = abil:GetName()
            else
                table.insert(abilities, abil:GetName())
            end
        elseif abil and abil:IsHidden() and string.find(abil:GetName(), "special_bonus") then
            table.insert(talents, abil:GetName())
        end
    end
    
    -- Generic build: max first 3 abilities, then ult, then talents
    local build = {}
    
    for level = 1, 30 do
        if level == 6 or level == 12 or level == 18 then
            -- Level up ultimate
            if ultimate then
                table.insert(build, ultimate)
            end
        elseif level == 10 or level == 15 or level == 20 or level == 25 then
            -- Talent
            table.insert(build, talents[math.random(#talents)] or "special_bonus_generic")
        else
            -- Regular ability (rotate through non-ult abilities)
            if #abilities > 0 then
                local abil = abilities[(level - 1) % #abilities + 1]
                table.insert(build, abil)
            end
        end
    end
    
    return build
end

function SkillBuild:Think(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    if not bot.skillBuild then
        self:Initialize(bot)
        if not bot.skillBuild then return end
    end
    
    local abilityPoints = bot:GetAbilityPoints()
    if abilityPoints <= 0 then return end
    
    -- Level up next skill in build
    if #bot.skillBuild > 0 then
        local nextSkill = bot.skillBuild[1]
        
        -- Find the ability handle
        for i = 0, 23 do
            local abil = bot:GetAbilityByIndex(i)
            if abil and abil:GetName() == nextSkill then
                if abil:CanAbilityBeUpgraded() then
                    bot:ActionImmediate_LevelAbility(abil:GetName())
                    table.remove(bot.skillBuild, 1)
                    return
                end
            end
        end
        
        -- If not found or can't upgrade, skip
        table.remove(bot.skillBuild, 1)
    end
end

return SkillBuild