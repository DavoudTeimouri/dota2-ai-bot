-- Ability & Item Usage System for AetherWeaver
-- Loads per-hero ability logic from Customize/hero -> BotLib -> generic fallback
-- Integrates with Patch 7.41f adjustments

local AbilityUsage = {}
local Patch741f = require("patch_741f")

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
        bot.abilityLogicSource = "customize"
        return true
    end
    
    -- Fallback to BotLib
    local botlibPath = "bots/BotLib/" .. string.gsub(heroName, "npc_dota_hero_", "") .. ".lua"
    ok, customBuild = pcall(dofile, botlibPath)
    if ok and customBuild and customBuild.SkillsComplement then
        bot.abilityLogic = customBuild
        bot.abilityLogicSource = "botlib"
        return true
    end
    
    -- Generic fallback
    bot.abilityLogic = self:GetGenericLogic(bot)
    bot.abilityLogicSource = "generic"
    return true
end

function AbilityUsage:GetGenericLogic(bot)
    local logic = {}
    logic.Abilities = {}
    
    -- Cache all abilities including ultimate
    for i = 0, 23 do
        local abil = bot:GetAbilityByIndex(i)
        if abil and not abil:IsPassive() and not abil:IsHidden() then
            table.insert(logic.Abilities, abil)
            if abil:IsUltimate() then
                logic.Ultimate = abil
            end
        end
    end
    
    function logic.SkillsComplement()
        -- Generic: use any ready ability on best target
        local target = self:GetBestTarget(bot)
        if not target then return end
        
        local patchAdj = bot.patchAdjustments or {}
        local gameTime = DotaTime()
        
        -- PRIORITY 1: Ultimate usage (smart timing)
        if logic.Ultimate and logic.Ultimate:IsFullyCastable() then
            if self:ShouldUseUltimate(bot, logic.Ultimate, target, gameTime) then
                self:CastUltimate(bot, logic.Ultimate, target)
                return
            end
        end
        
        -- PRIORITY 2: Regular abilities
        for _, abil in ipairs(logic.Abilities) do
            if abil ~= logic.Ultimate then
                if abil:IsFullyCastable() then
                    local castRange = abil:GetCastRange()
                    local dist = (bot:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
                    
                    local adj = self:ApplyPatchAdjustments(bot, abil:GetName())
                    if not (adj.mana_conserve and bot:GetMana() / bot:GetMaxMana() < 0.5) then
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
        end
    end
    
    return logic
end

function AbilityUsage:ShouldUseUltimate(bot, ulti, target, gameTime)
    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    local manaPct = bot:GetMana() / bot:GetMaxMana()
    local targetHpPct = target:GetHealth() / target:GetMaxHealth()
    local dist = (bot:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
    local castRange = ulti:GetCastRange()
    
    -- Don't use if out of range
    if dist > castRange + 300 then return false end
    
    -- Always use if target is killable
    if targetHpPct < 0.3 then return true end
    
    -- Use in teamfight (3+ enemies nearby)
    local enemies = bot:GetNearbyEnemyHeroes(1000)
    if #enemies >= 3 then return true end
    
    -- Hero-specific ult logic
    local ultiName = ulti:GetName()
    
    -- Global ults (Zeus, Spectre, etc.) - use when enemy low anywhere
    if ultiName:find("zeus_thundergods_wrath") or ultiName:find("spectre_haunt") then
        return true
    end
    
    -- Initiation ults (Enigma, Tidehunter, etc.) - use when multiple enemies
    if ultiName:find("enigma_black_hole") or ultiName:find("tidehunter_ravage") or
       ultiName:find("magnataur_reverse_polarity") or ultiName:find("earthshaker_echo_slam") then
        return #enemies >= 2
    end
    
    -- Defensive ults (Oracle, Dazzle, Abaddon) - use when ally low
    if ultiName:find("oracle_false_promise") or ultiName:find("dazzle_shallow_grave") or
       ultiName:find("abaddon_borrowed_time") then
        for _, ally in ipairs(GetTeamPlayers(GetTeam())) do
            if ally:IsAlive() and ally:GetHealth() / ally:GetMaxHealth() < 0.25 then
                return true
            end
        end
    end
    
    -- Burst ults (Lina, Lion, etc.) - use to finish target
    if ultiName:find("lina_laguna_blade") or ultiName:find("lion_finger_of_death") or
       ultiName:find("necrolyte_reapers_scythe") then
        return targetHpPct < 0.4
    end
    
    -- Transformation ults (Dragon Knight, Lone Druid) - use in fights
    if ultiName:find("dragon_knight_elder_dragon_form") or ultiName:find("lone_druid_true_form") then
        return #enemies >= 2 or targetHpPct < 0.5
    end
    
    -- Default: use when good opportunity
    return targetHpPct < 0.5 or #enemies >= 2
end

function AbilityUsage:CastUltimate(bot, ulti, target)
    local behavior = ulti:GetBehavior()
    
    if behavior == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
        bot:Action_UseAbilityOnEntity(ulti, target)
    elseif behavior == DOTA_ABILITY_BEHAVIOR_POINT then
        bot:Action_UseAbilityOnLocation(ulti, target:GetAbsOrigin())
    elseif behavior == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
        bot:Action_UseAbility(ulti)
    end
    MaybeSay("Ultimate: " .. ulti:GetName() .. "!")
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
            
            -- PRIORITY: Human players
            local playerID = enemy:GetPlayerID()
            if playerID and not PlayerResource:IsFakeClient(playerID) then
                score = score + 40
                
                -- Extra for human cores
                local heroName = enemy:GetUnitName()
                if heroName:find("antimage") or heroName:find("phantom_assassin") or 
                   heroName:find("spectre") or heroName:find("medusa") or
                   heroName:find("invoker") or heroName:find("storm_spirit") or
                   heroName:find("templar_assassin") or heroName:find("nevermore") then
                    score = score + 25
                end
            end
            
            if score > bestScore then
                bestScore = score
                bestTarget = enemy
            end
        end
    end
    return bestTarget
end

-- Apply patch 7.41f adjustments to ability usage
function AbilityUsage:ApplyPatchAdjustments(bot, abilityName)
    local adjustments = bot.patchAdjustments or {}
    
    -- Anti-Mage: more aggressive Mana Break
    if adjustments.mana_break_aggressive and abilityName == "antimage_mana_break" then
        return {priority_boost = 20}
    end
    
    -- Treant: conserve mana
    if adjustments.conserve_mana then
        local abil = bot:GetAbilityByName(abilityName)
        if abil and abil:GetManaCost() > 100 then
            return {mana_conserve = true}
        end
    end
    
    -- Invoker: Cold Snap less spammable
    if adjustments.cold_snap_conserve and abilityName == "invoker_cold_snap" then
        return {priority_reduce = 15}
    end
    
    return {}
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
                
                -- Apply patch adjustments for items
                local patchAdj = bot.patchAdjustments or {}
                
                -- Manta Style: ranged illusions deal less damage (less priority for ranged)
                if itemName == "item_manta" and patchAdj.manta_ranged_nerf then
                    -- Still use it, just slightly lower priority
                end
                
                -- Mask of Madness / Satanic: reduced lifesteal (affects usage timing)
                if (itemName == "item_mask_of_madness" or itemName == "item_satanic") and patchAdj.lifesteal_nerf then
                    -- Use more carefully, prefer when HP is lower
                    if target and bot:GetHealth() / bot:GetMaxHealth() > 0.5 then
                        -- Don't use if HP is high
                    else
                        if behavior == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
                            bot:Action_UseAbility(itemHandle)
                            return
                        end
                    end
                end
                
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