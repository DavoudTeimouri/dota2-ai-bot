-- Skill Build System for AetherWeaver

local SkillBuild = {}

function SkillBuild:Initialize(bot)
    if not bot or bot:IsNull() or not bot:IsHero() or bot:IsIllusion() then
        return false
    end
    
    local heroName = bot:GetUnitName()
    if not heroName or not string.find(heroName, "hero") then
        return false
    end
    
    -- Try Customize/hero first
    local customizePath = "bots/Customize/hero/" .. string.gsub(heroName, "npc_dota_hero_", "") .. ".lua"
    local ok, customBuild = pcall(dofile, customizePath)
    if ok and customBuild and customBuild.sSkillList then
        bot.skillBuild = customBuild.sSkillList
        return true
    end
    
    -- Fallback to BotLib
    local botlibPath = "bots/BotLib/" .. string.gsub(heroName, "npc_dota_hero_", "") .. ".lua"
    ok, customBuild = pcall(dofile, botlibPath)
    if ok and customBuild and customBuild.sSkillList then
        bot.skillBuild = customBuild.sSkillList
        return true
    end
    
    -- Generic fallback
    bot.skillBuild = self:GetGenericSkillBuild(bot)
    return true
end

function SkillBuild:GetGenericSkillBuild(bot)
    local heroName = bot:GetUnitName()
    local abilities = {}
    local talents = {}
    
    -- Get all abilities and talents
    for i = 0, 23 do
        local abil = bot:GetAbilityByIndex(i)
        if abil and not abil:IsPassive() and not abil:IsHidden() then
            if abil:IsUltimate() then
                -- Ultimate is handled separately
            else
                table.insert(abilities, abil:GetName())
            end
        elseif abil and abil:IsHidden() and string.find(abil:GetName(), "special_bonus") then
            table.insert(talents, abil:GetName())
        end
    end
    
    -- Generic build: max first 3 abilities, then ult, then talents
    local build = {}
    local abilityLevels = {}
    
    for level = 1, 30 do
        if level == 6 or level == 12 or level == 18 then
            -- Level up ultimate
            table.insert(build, "ability_level_up") -- placeholder for ult
        elseif level == 10 or level == 15 or level == 20 or level == 25 then
            -- Talent
            table.insert(build, talents[math.random(#talents)] or "special_bonus_generic")
        else
            -- Regular ability
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