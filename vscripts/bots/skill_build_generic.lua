-- Skill build generic
-- Engine hook: SkillBuildThink(). Skill levelling lives in
-- ability_item_usage_generic.lua (AbilityLevelUpThink), which is the hook
-- Dota 2 actually calls. This file only forwards to it.
local SkillBuild = {}

function SkillBuild:AbilityLevelUpThink(bot)
    if not bot or bot:IsNull() then return false end
    local AbilityUsage = require("ability_item_usage_generic")
    return AbilityUsage:AbilityLevelUpThink(bot)
end

-- Engine hook. Declared after the local table on purpose.
function SkillBuildThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        SkillBuild:AbilityLevelUpThink(bot)
    end
end

return SkillBuild