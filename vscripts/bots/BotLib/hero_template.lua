-- Generic Hero Template for BotLib
-- Copy this to create new hero builds

local X = {}

-- Skill build (ability internal names in order)
X.sSkillList = {
    "ability_1", "ability_2", "ability_1", "ability_3", "ability_1",
    "ability_ultimate", "ability_1", "ability_2", "ability_2", "ability_2",
    "ability_ultimate", "ability_3", "ability_3", "ability_3",
    "special_bonus_1", "ability_ultimate", "special_bonus_2",
    "special_bonus_3", "special_bonus_4", "special_bonus_5",
    "special_bonus_6", "special_bonus_7", "special_bonus_8",
}

-- Item build per position
X.sBuyList = {
    -- Early game
    "item_tango", "item_flask", "item_branches", "item_branches", "item_branches",
    -- Core
    "item_boots", "item_magic_wand", "item_power_treads",
    -- Mid game
    "item_echo_sabre", "item_black_king_bar",
    -- Late game
    "item_satanic", "item_butterfly", "item_abyssal_blade",
    "item_moon_shard", "item_ultimate_scepter_2", "item_aghanims_shard",
}

-- Items to sell when 6-slotted
X.sSellList = {
    "item_butterfly",
    "item_magic_wand",
}

X.bDeafaultAbility = false
X.bDeafaultItem = false

-- Ability logic
function X.SkillsComplement()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    -- Generic: use abilities on nearest enemy
    local enemies = bot:GetNearbyEnemyHeroes(1600)
    if #enemies == 0 then return end
    local target = enemies[1]
    
    for i = 0, 23 do
        local abil = bot:GetAbilityByIndex(i)
        if abil and abil:IsFullyCastable() and not abil:IsPassive() and not abil:IsHidden() then
            local behavior = abil:GetBehavior()
            local castRange = abil:GetCastRange()
            local dist = (bot:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
            
            if behavior == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET and dist <= castRange + 200 then
                bot:Action_UseAbilityOnEntity(abil, target)
                return
            elseif behavior == DOTA_ABILITY_BEHAVIOR_POINT and dist <= castRange + 200 then
                bot:Action_UseAbilityOnLocation(abil, target:GetAbsOrigin())
                return
            elseif behavior == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
                bot:Action_UseAbility(abil)
                return
            end
        end
    end
end

function X.MinionThink(hMinionUnit)
    -- Default: attack bot's target
    local bot = GetBot()
    if bot and not bot:IsNull() then
        local target = bot:GetAttackTarget()
        if target and not target:IsNull() then
            hMinionUnit:Action_AttackUnit(target, true)
        end
    end
end

return X