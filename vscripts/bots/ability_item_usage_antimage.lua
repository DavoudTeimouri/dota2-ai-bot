-- Anti-Mage per-hero ability usage.
--
-- The engine loads ability_item_usage_[hero].lua when that hero is picked, in
-- the same scope that ability_item_usage_generic.lua uses. Defining these
-- globals here overrides the generic behaviour for this hero only.
-- The old Customize/hero/antimage/*.lua files were never loaded by anything.
local AM = {}

-- Blink away when low, otherwise burn the lowest-HP enemy in range.
function AM:GetAbilityUsage(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return nil end

    local blink = bot:GetAbilityByName("antimage_blink")
    local manaBreak = bot:GetAbilityByName("antimage_mana_break")
    local spellShield = bot:GetAbilityByName("antimage_spell_shield")
    local enemies = bot:GetNearbyEnemyHeroes(1200, true)

    -- Nothing to burn and nothing to dodge: sit on Blink.
    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    if hpPct < 0.3 and blink and blink:IsFullyCastable() and #enemies > 0 then
        local pos = bot:GetAbsOrigin()
        local epos = enemies[1]:GetAbsOrigin()
        local dx, dy = pos.x - epos.x, pos.y - epos.y
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 1 and Vector then
            local away = Vector(pos.x + (dx / len) * 1200, pos.y + (dy / len) * 1200)
            if away then
                return blink, away
            end
        end
    end

    -- Mana Break on the weakest visible enemy.
    if manaBreak and manaBreak:IsFullyCastable() and #enemies > 0 then
        local best, bestHp = nil, math.huge
        for _, enemy in ipairs(enemies) do
            if enemy and not enemy:IsNull() and enemy:IsAlive() then
                local hp = enemy:GetHealth()
                if hp < bestHp then best, bestHp = enemy, hp end
            end
        end
        if best then
            return manaBreak, best
        end
    end

    -- Spell Shield has no target; it is a self buff.
    if spellShield and spellShield:IsFullyCastable() and hpPct < 0.8 then
        return spellShield, nil
    end

    return nil
end

-- Level in this order as levels come up.
AM.SKILL_PRIORITY = {
    "antimage_mana_break",
    "antimage_blink",
    "antimage_mana_break",
    "antimage_spell_shield",
    "antimage_mana_break",
    "antimage_chronosphere",
    "antimage_mana_break",
    "antimage_blink",
    "antimage_mana_break",
    "antimage_spell_shield",
    "antimage_spell_shield",
    "antimage_chronosphere",
    "antimage_spell_shield",
    "antimage_blink",
    "antimage_blink",
    "antimage_chronosphere",
}

function AM:AbilityLevelUpThink(bot)
    if not bot or bot:IsNull() then return false end
    if bot:GetAbilityPoints() <= 0 then return false end

    for _, name in ipairs(self.SKILL_PRIORITY) do
        local ability = bot:GetAbilityByName(name)
        if ability and not ability:IsNull() and ability:CanAbilityBeUpgraded() then
            return bot:ActionImmediate_LevelUpAbility(ability) and true or false
        end
    end
    return false
end

-- Engine hooks. Declared after the local table on purpose.

function AbilityUsageThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    local ability, target = AM:GetAbilityUsage(bot)
    if not ability then return end
    if target then
        if target.GetAbsOrigin and not target.GetHealth then
            -- A location, not a unit.
            bot:Action_UseAbilityOnLocation(ability, target)
        else
            bot:Action_UseAbilityOnEntity(ability, target)
        end
    else
        bot:Action_UseAbility(ability)
    end
end

function AbilityLevelUpThink()
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    AM:AbilityLevelUpThink(bot)
end

return AM