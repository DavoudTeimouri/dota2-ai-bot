-- Anti-Mage Hero Override for AetherWeaver
-- Place in vscripts/bots/Customize/hero/antimage.lua

local X = {}

-- Skill build: Max Mana Break first, then Blink, then Counterspell
X.sSkillList = {
    "antimage_mana_break",
    "antimage_blink",
    "antimage_mana_break",
    "antimage_counterspell",
    "antimage_mana_break",
    "antimage_mana_void",
    "antimage_mana_break",
    "antimage_blink",
    "antimage_blink",
    "antimage_blink",
    "antimage_mana_void",
    "antimage_counterspell",
    "antimage_counterspell",
    "antimage_counterspell",
    "antimage_mana_overload",
    "antimage_mana_void",
    "antimage_mana_overload",
    "antimage_mana_overload",
    "antimage_mana_overload",
    "special_bonus_agility_20",
    "special_bonus_attack_speed_30",
    "special_bonus_hp_500",
    "special_bonus_movement_speed_30",
    "special_bonus_all_stats_10",
    "special_bonus_cooldown_reduction_15",
    "special_bonus_spell_lifesteal_30",
    "special_bonus_unique_antimage",
}

-- Item build for position 1 carry
X.sBuyList = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",
    "item_wraith_band",
    "item_magic_wand",
    "item_power_treads",
    "item_bfury",
    "item_manta",
    "item_butterfly",
    "item_basher",
    "item_skadi",
    "item_moon_shard",
    "item_disperser",
    "item_abyssal_blade",
    "item_ultimate_scepter_2",
    "item_aghanims_shard",
}

-- Sell list: sell early items when 6-slotted
X.sSellList = {
    "item_skadi",
    "item_magic_wand",
}

X.bDeafaultAbility = false
X.bDeafaultItem = false

-- Ability logic
local Blink = nil
local CounterSpell = nil
local CounterSpellAlly = nil
local BlinkFragment = nil
local ManaVoid = nil

function X.SkillsComplement()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    -- Initialize abilities
    if not Blink then Blink = bot:GetAbilityByName("antimage_blink") end
    if not CounterSpell then CounterSpell = bot:GetAbilityByName("antimage_counterspell") end
    if not CounterSpellAlly then CounterSpellAlly = bot:GetAbilityByName("antimage_counterspell_ally") end
    if not BlinkFragment then BlinkFragment = bot:GetAbilityByName("antimage_mana_overload") end
    if not ManaVoid then ManaVoid = bot:GetAbilityByName("antimage_mana_void") end
    
    local botTarget = J.GetProperTarget(bot)
    if not botTarget then return end
    
    -- Mana Void: Use on low mana enemies
    if ManaVoid and ManaVoid:IsFullyCastable() then
        local enemies = bot:GetNearbyEnemyHeroes(1600)
        for _, enemy in ipairs(enemies) do
            if not enemy:IsNull() and enemy:IsAlive() and not enemy:IsIllusion() then
                local manaPct = enemy:GetMana() / enemy:GetMaxMana()
                if manaPct < 0.3 then -- Enemy low on mana
                    bot:Action_UseAbilityOnEntity(ManaVoid, enemy)
                    return
                end
            end
        end
    end
    
    -- Counterspell: Reflect projectiles
    if CounterSpell and CounterSpell:IsFullyCastable() then
        local projectiles = bot:GetIncomingProjectiles() or {}
        for _, proj in ipairs(projectiles) do
            if proj.is_attack == false then -- Spell projectile
                bot:Action_UseAbility(CounterSpell)
                return
            end
        end
        -- Also use preemptively against heavy magic lineups
        local enemies = bot:GetNearbyEnemyHeroes(1200)
        local magicDamageCount = 0
        for _, enemy in ipairs(enemies) do
            if J.GetHeroMagicDamage(enemy) > 200 then
                magicDamageCount = magicDamageCount + 1
            end
        end
        if magicDamageCount >= 2 then
            bot:Action_UseAbility(CounterSpell)
            return
        end
    end
    
    -- Counterspell Ally: Save teammates
    if CounterSpellAlly and CounterSpellAlly:IsFullyCastable() then
        local allies = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
        for _, ally in ipairs(allies) do
            if not ally:IsNull() and ally:IsAlive() and ally:GetHealth() / ally:GetMaxHealth() < 0.3 then
                local enemies = ally:GetNearbyEnemyHeroes(800)
                for _, enemy in ipairs(enemies) do
                    if enemy:HasModifier("modifier_stunned") or enemy:HasModifier("modifier_rooted") then
                        bot:Action_UseAbilityOnEntity(CounterSpellAlly, ally)
                        return
                    end
                end
            end
        end
    end
    
    -- Blink Fragment: Farm/Escape
    if BlinkFragment and BlinkFragment:IsFullyCastable() then
        local enemies = bot:GetNearbyEnemyHeroes(1000)
        if #enemies == 0 then
            -- Farm with it
            local creeps = bot:GetNearbyCreeps(800, true)
            if #creeps >= 3 then
                local center = J.GetCenterOfUnits(creeps)
                bot:Action_UseAbilityOnLocation(BlinkFragment, center)
                return
            end
        else
            -- Escape
            local safePos = J.GetSafeLocation(bot, 600)
            if safePos then
                bot:Action_UseAbilityOnLocation(BlinkFragment, safePos)
                return
            end
        end
    end
    
    -- Blink: Engage/Escape/Position
    if Blink and Blink:IsFullyCastable() then
        -- Escape
        if bot:GetHealth() / bot:GetMaxHealth() < 0.3 then
            local safePos = J.GetSafeLocation(bot, 1200)
            if safePos then
                bot:Action_UseAbilityOnLocation(Blink, safePos)
                return
            end
        end
        
        -- Engage on isolated target
        if botTarget and not botTarget:IsNull() and botTarget:IsAlive() then
            local dist = (bot:GetAbsOrigin() - botTarget:GetAbsOrigin()):Length2D()
            if dist > 600 and dist < 1800 then
                local enemiesNearTarget = botTarget:GetNearbyEnemyHeroes(800)
                if #enemiesNearTarget <= 1 then
                    bot:Action_UseAbilityOnLocation(Blink, botTarget:GetAbsOrigin())
                    return
                end
            end
        end
    end
end

function X.MinionThink(hMinionUnit)
    -- Illusion logic
    if J.IsValidHero(hMinionUnit) and hMinionUnit:IsIllusion() then
        local bot = GetBot()
        if bot and not bot:IsNull() then
            -- Attack bot's target
            local target = bot:GetAttackTarget()
            if target and not target:IsNull() then
                hMinionUnit:Action_AttackUnit(target, true)
            else
                -- Farm nearest creep
                local creeps = hMinionUnit:GetNearbyCreeps(800, true)
                if #creeps > 0 then
                    hMinionUnit:Action_AttackUnit(creeps[1], true)
                end
            end
        end
    end
end

return X