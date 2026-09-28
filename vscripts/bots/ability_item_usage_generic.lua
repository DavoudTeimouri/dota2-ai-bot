-- Ability usage think function (engine hook)
function AbilityUsageThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local ability, target = AbilityUsageGeneric:GetAbilityUsage(bot)
        if ability and target then
            if type(target) == "userdata" and target.IsAlive and target:IsAlive() then
                bot:Action_UseAbilityOnEntity(ability, target)
            elseif type(target) == "table" and target.x and target.y and target.z then
                bot:Action_UseAbilityOnLocation(ability, target)
            else
                bot:Action_UseAbility(ability)
            end
        end
    end
end

-- Ability usage module for internal use
local AbilityUsageGeneric = {}

-- Cache ultimate separately for smart usage
AbilityUsageGeneric.ultiCache = {}

-- Get ability usage for bot (hero override takes priority)
function AbilityUsageGeneric:GetAbilityUsage(bot)
    local heroName = bot:GetUnitName()
    
    -- Try hero-specific override first
    local override = self:GetHeroOverride(heroName)
    if override and override.GetAbilityUsage then
        return override:GetAbilityUsage(bot)
    end
    
    -- Generic logic
    return self:GenericAbilityUsage(bot)
end

-- Generic ability usage logic
function AbilityUsageGeneric:GenericAbilityUsage(bot)
    local abilities = {}
    
    -- Collect all abilities
    for i = 0, 23 do
        local ability = bot:GetAbilityByIndex(i)
        if ability and not ability:IsAttributeBonus() and not ability:IsHidden() and ability:IsFullyCastable() then
            table.insert(abilities, ability)
        end
    end
    
    -- Find enemies
    local enemies = bot:GetNearbyEnemyHeroes(1600)
    local target = enemies[1]
    
    if not target then
        -- Check for creep/unit targets
        local creeps = bot:GetNearbyCreeps(1600)
        if #creeps > 0 then target = creeps[1] end
    end
    
    -- Prioritize: ulti -> stun/disable -> nuke -> buff
    local ulti = nil
    local bestAbility = nil
    local bestScore = 0
    
    for _, ability in ipairs(abilities) do
        local name = ability:GetName()
        local behavior = ability:GetBehavior()
        local castRange = ability:GetCastRange()
        
        -- Cache ultimate
        if ability:IsUltimate() then
            ulti = ability
        end
        
        local score = 0
        
        -- Stun/disable highest priority
        if name:find("stun") or name:find("disable") or name:find("silence") or name:find("hex") then
            score = 100
        -- Nuke
        elseif name:find("bolt") or name:find("blast") or name:find("strike") or name:find("wave") or name:find("pulse") then
            score = 80
        -- Buff/heal
        elseif name:find("heal") or name:find("shield") or name:find("buff") or name:find("armor") then
            score = 60
        -- Escape/mobility
        elseif name:find("blink") or name:find("phase") or name:find("windwalk") or name:find("invis") then
            score = 40
        else
            score = 20
        end
        
        -- Target in range check
        if target and castRange > 0 then
            local dist = (bot:GetLocation() - target:GetLocation()):Length2D()
            if dist <= castRange + 100 then
                score = score + 20
            else
                score = score - 50
            end
        end
        
        -- Mana efficiency
        local manaCost = ability:GetManaCost()
        local manaPct = bot:GetMana() / bot:GetMaxMana()
        if manaCost > bot:GetMana() * 0.8 then
            score = score - 30
        end
        
        if score > bestScore then
            bestScore = score
            bestAbility = ability
        end
    end
    
    -- Smart ultimate usage
    if ulti and ulti:IsFullyCastable() then
        local shouldUseUlti = self:ShouldUseUltimate(bot, ulti, target)
        if shouldUseUlti then
            return ulti, target
        end
    end
    
    if bestAbility then
        return bestAbility, target
    end
    
    return nil, nil
end

-- Smart ultimate usage logic
function AbilityUsageGeneric:ShouldUseUltimate(bot, ulti, target)
    local name = ulti:GetName()
    local behavior = ulti:GetBehavior()
    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    
    -- Global ultimates (Zeus, Spectre, etc.) - always use when off cooldown and target exists
    if bit.band(behavior, ABILITY_BEHAVIOR_NO_TARGET) == ABILITY_BEHAVIOR_NO_TARGET then
        return target ~= nil
    end
    
    -- Initiation ultimates (Enigma, Tidehunter, Magnus) - use on 2+ enemies
    if name:find("black_hole") or name:find("ravage") or name:find("reverse_polarity") or name:find("echo_slam") then
        local enemies = bot:GetNearbyEnemyHeroes(600)
        return #enemies >= 2
    end
    
    -- Defensive ultimates (Oracle, Dazzle, Abaddon) - use on ally < 25% HP
    if name:find("false_promise") or name:find("shallow_grave") or name:find("borrowed_time") then
        local allies = bot:GetNearbyHeroes(800, false, BOT_MODE_NONE)
        for _, ally in ipairs(allies) do
            if ally:GetHealth() / ally:GetMaxHealth() < 0.25 then
                return true
            end
        end
    end
    
    -- Burst ultimates (Lina, Lion, Skywrath) - use on target < 40% HP
    if name:find("laguna_blade") or name:find("finger_of_death") or name:find("mystic_flare") then
        return target and (target:GetHealth() / target:GetMaxHealth() < 0.4)
    end
    
    -- Transformation ultimates (DK, LD, TB) - use in fights
    if name:find("dragon_form") or name:find("true_form") or name:find("metamorphosis") then
        local enemies = bot:GetNearbyEnemyHeroes(1000)
        return #enemies >= 1
    end
    
    -- Default: use on target < 50% HP or 2+ enemies
    if target then
        local targetHP = target:GetHealth() / target:GetMaxHealth()
        local enemies = bot:GetNearbyEnemyHeroes(800)
        return targetHP < 0.5 or #enemies >= 2
    end
    
    return false
end

-- Hero-specific overrides
function AbilityUsageGeneric:GetHeroOverride(heroName)
    -- This would require Customize/hero/<hero>/ability.lua files
    -- For now return nil - implemented via require in init.lua if exists
    local heroFile = "Customize/hero/" .. heroName:gsub("npc_dota_hero_", "") .. "/ability"
    -- Can't require dynamically in Dota 2, so we skip this for generic
    return nil
end

return AbilityUsageGeneric