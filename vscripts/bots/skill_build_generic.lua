-- Skill build generic
local SkillBuild = {}
function SkillBuild:AbilityLevelUpThink(bot)
    -- stub
end
function SkillBuildThink()
    local bot = GetBot()
    if bot and not bot:IsNull() then
        SkillBuild:AbilityLevelUpThink(bot)
    end
end