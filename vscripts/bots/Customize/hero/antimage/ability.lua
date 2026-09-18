-- Antimage hero ability usage
return {
    AbilityUsage = function(bot)
        -- Try to use Mana Break if enemy hero nearby and we have enough mana
        local manaBreak = bot:GetAbilityByName("antimage_mana_break")
        if manaBreak and manaBreak:IsFullyCastable() then
            local target = bot:GetNearbyHero(1200, true) -- enemy hero
            if target then
                return manaBreak, target
            end
        end

        -- Try to blink to escape or initiate
        local blink = bot:GetAbilityByName("antimage_blink")
        if blink and blink:IsFullyCastable() then
            -- If we are low health, blink away from enemies
            local healthPercent = bot:GetHealth() / bot:GetMaxHealth()
            if healthPercent < 0.3 then
                local fountain = GetFountainLocation(bot:GetTeam())
                if fountain then
                    return blink, fountain
                end
            end
            -- Otherwise, blink towards enemy hero if we have mana break ready
            local manaBreak = bot:GetAbilityByName("antimage_mana_break")
            if manaBreak and manaBreak:IsFullyCastable() then
                local target = bot:GetNearbyHero(1200, true)
                if target then
                    return blink, target:GetAbsOrigin()
                end
            end
        end

        -- No ability to use
        return nil
    end
}