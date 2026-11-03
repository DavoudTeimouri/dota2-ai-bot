-- Laning mode: hold the assigned lane, last hit, and deny when the wave is near.
--
-- Engine contract (Valve):
--   GetDesire() is called EVERY FRAME for EVERY mode file. The highest desire
--   wins and that mode's Think() runs; nil falls back to Valve's own desire.
--   So GetDesire must be cheap and must never throw.
--
-- Lane roles. Support needs to leave lane to pull and ward, so its desire
-- drops off as soon as it has something to do.
local BotLane = require("bot_lane")
local Compat = require("bot_compat")

local function IsReadyToFarm(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return false end
    if bot:GetHealth() < bot:GetMaxHealth() * 0.25 then return false end
    return true
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end
    if bot:GetHealth() < bot:GetMaxHealth() * 0.25 then return 0 end

    local desire = 0.4

    -- Supports want to ward and roam, not stand on the wave.
    if BotLane.GetRole(bot) == "support" then desire = 0.2 end

    -- Give way when badly hurt so retreat/push can win.
    local hpPct = bot:GetHealth() / bot:GetMaxHealth()
    if hpPct < 0.5 then desire = desire * 0.5 end

    -- Supports with an unplaced observer want the ward mode to win instead.
    if BotLane.GetRole(bot) == "support" and Compat.AvailableWards(bot) > 0 then
        desire = desire * 0.5
    end

    return desire
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not IsReadyToFarm(bot) then return end

    local lane = BotLane.GetAssigned(bot)

    -- Fight back: attack the nearest enemy hero within reach before farming.
    -- A bot that only last-hits and never strikes back feeds for free.
    local attackRange = (bot:GetAttackRange and bot:GetAttackRange()) or 600
    local enemies = Compat.Enemies(bot, attackRange + 150)
    if #enemies > 0 then
        local best, bestDist = nil, math.huge
        local pos = Compat.Position(bot)
        for _, enemy in ipairs(enemies) do
            if enemy and not enemy:IsNull() and enemy:IsAlive() then
                local epos = Compat.Position(enemy)
                if pos and epos then
                    local dx = epos.x - pos.x
                    local dy = epos.y - pos.y
                    local d = math.sqrt(dx * dx + dy * dy)
                    if d < bestDist then
                        bestDist, best = d, enemy
                    end
                end
            end
        end
        if best then
            Compat.Attack(bot, best)
            return
        end
    end

    -- Last hit: only swing when the creep dies to it.
    local laneCreeps = bot:GetNearbyLaneCreeps(800, true)
    if #laneCreeps > 0 then
        local best, lowest = nil, math.huge
        for _, creep in ipairs(laneCreeps) do
            local hp = creep:GetHealth()
            if hp < lowest and hp <= bot:GetAttackDamage() then
                best, lowest = creep, hp
            end
        end
        -- Clean last hit available: take it.
        if best then
            Compat.Attack(bot, best)
            return
        end

        -- No clean last hit: push the lane by attacking the nearest enemy
        -- creep instead of standing idle.
        local nearest, nearestDist = nil, math.huge
        local bpos = Compat.Position(bot)
        for _, creep in ipairs(laneCreeps) do
            if creep and not creep:IsNull() then
                local cpos = Compat.Position(creep)
                if cpos and bpos then
                    local dx = cpos.x - bpos.x
                    local dy = cpos.y - bpos.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < nearestDist then
                        nearestDist, nearest = dist, creep
                    end
                end
            end
        end
        if nearest then
            Compat.Attack(bot, nearest)
            return
        end

        -- Deny our own creep if it's almost dead and enemy would get the last hit.
        -- Prevents free gold/xp for the opponent.
        local friendlyCreeps = bot:GetNearbyLaneCreeps(800, false)
        if #friendlyCreeps > 0 then
            local bestDeny, lowestDeny = nil, math.huge
            for _, creep in ipairs(friendlyCreeps) do
                local hp = creep:GetHealth()
                if hp < lowestDeny and hp <= bot:GetAttackDamage() then
                    bestDeny, lowestDeny = creep, hp
                end
            end
            if bestDeny then
                Compat.Attack(bot, bestDeny)
                return
            end
        end
    end

    -- Nothing to hit: walk to the front of our lane.
    local pos = BotLane.FrontLocation(bot, 0)
    if pos then
        Compat.AttackMove(bot, pos)
    end
end

-- The engine calls the global GetDesire()/Think() above. Returning the table
-- as well lets the module be required and tested without the engine.
return {
    GetDesire = GetDesire,
    Think = Think,
}