-- Ability usage logic with hero override support
local M = {}

local function LoadHeroOverride(heroName)
    local overridePath = string.format("Customize/hero/%s/ability.lua", string.lower(heroName))
    local status, override = pcall(require, overridePath)
    if status and override then
        return override
    end
    return nil
end

function M.GetAbilityUsage(bot)
    local heroName = bot:GetUnitName()
    local override = LoadHeroOverride(heroName)
    if override and override.AbilityUsage then
        return override.AbilityUsage(bot)
    end
    -- Fallback: do nothing
    return nil
end

return M