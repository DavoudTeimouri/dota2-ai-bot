-- Diagnostics: a report the bot prints so a lobby test is a paste-back
-- rather than an eyeball.
--
-- The whole bot is verified headless against a fake engine. That proves the
-- code paths run, but not that the real VM behaves the way the fake does.
-- This module prints, into the console:
--
--   1. which API shape the VM actually implements
--   2. what the bot thinks its state is (hero, role, lane, gold)
--   3. the team's desires
--   4. how many actions the bot actually issued since the last report
--
-- Run it in a cheat-enabled lobby and paste the output back.

local Diagnostics = {}

local Compat = require("bot_compat")
local BotLane = require("bot_lane")

-- The report is printed once at the horn and then every REPORT_INTERVAL.
local REPORT_INTERVAL = 30

local state = {
    nextReport = 0,
    reported = false,
}

-- One line per key, so the report is easy to read and easy to diff.
local function Line(label, value)
    print(string.format("[%s] %s", label, tostring(value)))
end

-- The API shape the VM implements. A "none" here means the bot has no way
-- to do that thing at all.
local function ReportApi()
    local shape = Compat.ApiShape()
    print("--- API shape ---")
    Line("heroQuery", shape.heroQuery)
    Line("position", shape.position)
    Line("abilitySlot", shape.abilitySlot)
    Line("levelUp", shape.levelUp)
    Line("courier", shape.courier)
    Line("courierAction", shape.courierAction)
    Line("itemCost", shape.itemCost)
    Line("itemShop", shape.itemShop)
    Line("itemStock", shape.itemStock)
    Line("roshan", shape.roshan)
    Line("glyph", shape.glyph)
    Line("tower", shape.tower)
    Line("selectHero", shape.selectHero)
    Line("pickControl", shape.pickControl)
    Line("pickState", shape.pickState)
    Line("cmBan", shape.cmBan)
    Line("teamPlayers", shape.teamPlayers)
    Line("isPlayerBot", shape.isPlayerBot)
    Line("netWorth", shape.netWorth)
end

-- What this bot thinks it is.
local function ReportBot()
    local bot = GetBot()
    if not bot or bot:IsNull() then
        Line("bot", "none")
        return
    end
    print("--- bot ---")
    if bot.GetUnitName then
        local ok, name = pcall(bot.GetUnitName, bot)
        Line("hero", ok and name or "?")
    end
    Line("role", BotLane.GetRole(bot))
    Line("lane", BotLane.GetAssigned(bot))
    Line("gold", bot.GetGold and bot:GetGold() or "?")
    if bot.GetHealth and bot.GetMaxHealth then
        Line("hp", string.format("%d/%d", bot:GetHealth(), bot:GetMaxHealth()))
    end
    if bot.GetAbilityPoints then
        Line("abilityPoints", bot:GetAbilityPoints())
    end
    local pos = Compat.Position(bot)
    if pos then
        Line("position", string.format("%.0f,%.0f", pos.x or 0, pos.y or 0))
    end
    Line("atFountain", bot.DistanceFromFountain and bot:DistanceFromFountain() == 0)
end

-- The team's plan.
local function ReportTeam()
    print("--- team ---")
    local function desire(name, getter)
        if not getter then
            Line(name, "no getter")
            return
        end
        local ok, value = pcall(getter)
        Line(name, ok and string.format("%.2f", value or 0) or "err")
    end
    desire("push.top", function() return GetPushLaneDesire(1) end)
    desire("push.mid", function() return GetPushLaneDesire(2) end)
    desire("push.bot", function() return GetPushLaneDesire(3) end)
    desire("defend.top", function() return GetDefendLaneDesire(1) end)
    desire("defend.mid", function() return GetDefendLaneDesire(2) end)
    desire("defend.bot", function() return GetDefendLaneDesire(3) end)
    desire("farm.mid", function() return GetFarmLaneDesire(2) end)
    desire("roam", function() return GetRoamDesire() end)
    desire("roshan", function() return GetRoshanDesire() end)

    local enemies = Compat.EnemyHeroes()
    local humans = 0
    for _, enemy in ipairs(enemies) do
        if not enemy.isBot then humans = humans + 1 end
    end
    Line("enemies", #enemies)
    Line("enemiesHuman", humans)
    Line("allies", #Compat.TeamMembers())
end

-- How much the bot actually did. Zero moves and zero purchases over a
-- minute means it is standing still, whatever the code says.
local function ReportActions()
    local stats = Compat.TakeStats()
    print("--- actions since the last report ---")
    Line("moves", stats.moves)
    Line("attacks", stats.attacks)
    Line("casts", stats.casts)
    Line("levels", stats.levels)
    Line("purchases", stats.purchases)
end

-- Print the whole report.
function Diagnostics:Report()
    local now = DotaTime and DotaTime() or 0
    print("")
    print("=========================================================")
    print(" AetherWeaver diagnostics    t=" .. string.format("%.0f", now))
    print("=========================================================")
    ReportApi()
    ReportBot()
    ReportTeam()
    ReportActions()
    print("=========================================================")
    print("")
end

-- Called from BotThink. Prints the first report at the horn and then on a
-- timer.
function Diagnostics:Think()
    local now = DotaTime and DotaTime() or 0
    if now < 0 then return end

    if not state.reported then
        state.reported = true
        state.nextReport = now + REPORT_INTERVAL
        self:Report()
        return
    end

    if now >= state.nextReport then
        state.nextReport = now + REPORT_INTERVAL
        self:Report()
    end
end

return Diagnostics
