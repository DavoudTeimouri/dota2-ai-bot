-- Ability & Item Usage System for AetherWeaver
-- Loads per-hero ability logic from BotLib or Customize/hero

local AbilityUsage = {}

function AbilityUsage:Initialize(bot)
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
    if ok and customBuild and customBuild.SkillsComplement then
        bot.abilityLogic = customBuild
        return true
    end
    
    -- Fallback to BotLib
    local botlibPath = "bots/BotLib/" .. string.gsub(heroName, "npc_dota_hero_", "") .. ".lua"
    ok, customBuild = pcall(dofile, botlibPath)
    if ok and customBuild and customBuild.SkillsComplement then
        bot.abilityLogic = customBuild
        return true
    end
    
    -- Generic fallback
    bot.abilityLogic = self:GetGenericLogic(bot)
    return true
end

function AbilityUsage:GetGenericLogic(bot)
    local logic = {}
    logic.Abilities = {}
    
    -- Cache all abilities
    for i = 0, 23 do
        local abil = bot:GetAbilityByIndex(i)
        if abil and not abil:IsPassive() and not abil:IsHidden() then
            table.insert(logic.Abilities, abil)
        end
    end
    
    function logic.SkillsComplement()
        -- Generic: use any ready ability on nearest enemy
        local target = self:GetBestTarget(bot)
        if not target then return end
        
        for _, abil in ipairs(logic.Abilities) do
            if abil:IsFullyCastable() then
                local castRange = abil:GetCastRange()
                local dist = (bot:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
                
                if abil:GetBehavior() == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
                    if dist <= castRange + 200 then
                        bot:Action_UseAbilityOnEntity(abil, target)
                        return
                    end
                elseif abil:GetBehavior() == DOTA_ABILITY_BEHAVIOR_POINT then
                    if dist <= castRange + 200 then
                        bot:Action_UseAbilityOnLocation(abil, target:GetAbsOrigin())
                        return
                    end
                elseif abil:GetBehavior() == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
                    bot:Action_UseAbility(abil)
                    return
                end
            end
        end
    end
    
    return logic
end

function AbilityUsage:GetBestTarget(bot)
    local enemies = bot:GetNearbyEnemyHeroes(1600)
    local bestTarget = nil
    local bestScore = -1
    
    for _, enemy in ipairs(enemies) do
        if not enemy:IsNull() and enemy:IsAlive() and not enemy:IsIllusion() then
            local score = 100
            local hpPct = enemy:GetHealth() / enemy:GetMaxHealth()
            score = score + (1 - hpPct) * 50  -- prefer low HP
            local dist = (bot:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
            score = score - dist / 20  -- prefer closer
            if enemy:IsMagicImmune() then score = score - 30 end
            if score > bestScore then
                bestScore = score
                bestTarget = enemy
            end
        end
    end
    return bestTarget
end

function AbilityUsage:Think(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    if not bot.abilityLogic then
        self:Initialize(bot)
        if not bot.abilityLogic then return end
    end
    
    -- Use items
    self:UseItems(bot)
    
    -- Use abilities
    if bot.abilityLogic.SkillsComplement then
        bot.abilityLogic.SkillsComplement()
    end
end

function AbilityUsage:UseItems(bot)
    -- Use active items on self or enemies
    local items = {
        "item_blink", "item_black_king_bar", "item_blade_mail", "item_manta",
        "item_satanic", "item_abyssal_blade", "item_heavens_halberd",
        "item_sheepstick", "item_ethereal_blade", "item_diffusal_blade",
        "item_necronomicon", "item_veil_of_discord", "item_shivas_guard",
        "item_pipe", "item_crimson_guard", "item_lotus_orb", "item_glimmer_cape",
        "item_force_staff", "item_hurricane_pike", "item_aeon_disk",
        "item_refresher", "item_octarine_core", "item_bloodthorn"
    }
    
    local target = self:GetBestTarget(bot)
    
    for _, itemName in ipairs(items) do
        local item = bot:FindItemSlot(itemName)
        if item >= 0 then
            local itemHandle = bot:GetItemInSlot(item)
            if itemHandle and itemHandle:IsFullyCastable() then
                local behavior = itemHandle:GetBehavior()
                local castRange = itemHandle:GetCastRange()
                local dist = target and (bot:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() or 9999
                
                if behavior == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET and target and dist <= castRange + 200 then
                    bot:Action_UseAbilityOnEntity(itemHandle, target)
                    return
                elseif behavior == DOTA_ABILITY_BEHAVIOR_POINT and target and dist <= castRange + 200 then
                    bot:Action_UseAbilityOnLocation(itemHandle, target:GetAbsOrigin())
                    return
                elseif behavior == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
                    bot:Action_UseAbility(itemHandle)
                    return
                end
            end
        end
    end
end

return AbilityUsage