-- Team roam mode: join a fight happening elsewhere.
--
-- Engine contract: GetDesire() runs every frame for every mode file. nil falls
-- back to Valve's desire; 0 opts out. This must stay below laning/farm/shop in
-- ordinary conditions or every bot leaves lane permanently.
function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    -- Healthy: farming and laning beat this.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.6 then return 0 end

    local enemies = bot:GetNearbyEnemyHeroes(2000, true)
    if #enemies == 0 then return nil end

    local allies = #bot:GetNearbyAlliedHeroes(2000)
    if allies <= 1 then return nil end   -- never roam alone

    -- A real fight: both sides present and worth joining.
    local desire = 0.45
    if allies > #enemies then desire = desire + 0.1 end

    -- Late game fights are worth more than an early skirmish.
    if DotaTime() > 1200 then desire = desire + 0.1 end

    return desire
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    local enemies = bot:GetNearbyEnemyHeroes(2000, true)
    if #enemies == 0 then return end

    -- Weakest visible enemy first: focus fire beats scattering damage.
    local best, bestHp = nil, math.huge
    for _, enemy in ipairs(enemies) do
        if enemy and not enemy:IsNull() and enemy:IsAlive() then
            local hp = enemy:GetHealth()
            if hp < bestHp then
                best, bestHp = enemy, hp
            end
        end
    end

    if best then
        bot:Action_AttackUnit(best)
    end
end