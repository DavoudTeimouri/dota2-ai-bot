-- Crystal Maiden Hero Override for AetherWeaver
-- Place in vscripts/bots/Customize/hero/crystal_maiden.lua

local X = {}

X.sSkillList = {
    "crystal_maiden_crystal_nova",
    "crystal_maiden_frostbite",
    "crystal_maiden_crystal_nova",
    "crystal_maiden_frostbite",
    "crystal_maiden_crystal_nova",
    "crystal_maiden_freezing_field",
    "crystal_maiden_crystal_nova",
    "crystal_maiden_frostbite",
    "crystal_maiden_frostbite",
    "crystal_maiden_frostbite",
    "crystal_maiden_freezing_field",
    "crystal_maiden_arcane_aura",
    "crystal_maiden_arcane_aura",
    "crystal_maiden_arcane_aura",
    "special_bonus_mp_200",
    "crystal_maiden_freezing_field",
    "special_bonus_magic_resistance_15",
    "special_bonus_cast_range_125",
    "special_bonus_gold_income_20",
    "special_bonus_unique_crystal_maiden",
}

X.sBuyList = {
    "item_tango",
    "item_flask",
    "item_mantle",
    "item_branches",
    "item_branches",
    "item_boots",
    "item_magic_wand",
    "item_tranquil_boots",
    "item_glimmer_cape",
    "item_force_staff",
    "item_aeon_disk",
    "item_lotus_orb",
    "item_guardian_greaves",
    "item_ultimate_scepter_2",
    "item_aghanims_shard",
}

X.sSellList = {
    "item_guardian_greaves",
    "item_magic_wand",
}

X.bDeafaultAbility = false
X.bDeafaultItem = false

local CrystalNova = nil
local Frostbite = nil
local ArcaneAura = nil
local FreezingField = nil

function X.SkillsComplement()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    if not CrystalNova then CrystalNova = bot:GetAbilityByName("crystal_maiden_crystal_nova") end
    if not Frostbite then Frostbite = bot:GetAbilityByName("crystal_maiden_frostbite") end
    if not ArcaneAura then ArcaneAura = bot:GetAbilityByName("crystal_maiden_arcane_aura") end
    if not FreezingField then FreezingField = bot:GetAbilityByName("crystal_maiden_freezing_field") end
    
    local botTarget = J.GetProperTarget(bot)
    
    -- Freezing Field: Channel when enemies are grouped
    if FreezingField and FreezingField:IsFullyCastable() then
        local enemies = bot:GetNearbyEnemyHeroes(600)
        if #enemies >= 2 then
            bot:Action_UseAbility(FreezingField)
            return
        end
    end
    
    -- Frostbite: Disable priority target
    if Frostbite and Frostbite:IsFullyCastable() and botTarget then
        if not botTarget:IsMagicImmune() then
            bot:Action_UseAbilityOnEntity(Frostbite, botTarget)
            return
        end
    end
    
    -- Crystal Nova: Wave clear / harass
    if CrystalNova and CrystalNova:IsFullyCastable() then
        local enemies = bot:GetNearbyEnemyHeroes(800)
        if #enemies > 0 then
            bot:Action_UseAbilityOnLocation(CrystalNova, enemies[1]:GetAbsOrigin())
            return
        end
        -- Farm with it
        local creeps = bot:GetNearbyCreeps(600, true)
        if #creeps >= 3 then
            local center = J.GetCenterOfUnits(creeps)
            bot:Action_UseAbilityOnLocation(CrystalNova, center)
            return
        end
    end
end

function X.MinionThink(hMinionUnit)
    -- No minions for CM
end

return X