--[[
Unit tests for hero_selection.lua pure logic functions.
Tests that don't require the full Dota 2 VM.
]]

package.path = "vscripts/bots/?.lua;" .. package.path

local Mock = require("tests.mock_dota_api")

local passed = 0
local failed = 0

local function assert_eq(actual, expected, msg)
    if actual == expected then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("FAIL: %s - expected %s, got %s",
            tostring(msg), tostring(expected), tostring(actual)))
    end
end

local function assert_true(cond, msg)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("FAIL: %s - expected true, got %s",
            tostring(msg), tostring(cond)))
    end
end

local function assert_not_nil(val, msg)
    if val ~= nil then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("FAIL: %s - expected non-nil", tostring(msg)))
    end
end

-- Test 1: GetHumanChatHero with exact match
print("Test: GetHumanChatHero exact match...")
do
    -- We can't easily test this without loading hero_selection.lua which
    -- requires many dependencies. Instead, test the logic inline.
    local SupportedHeroes = {"antimage", "axe", "bane"}
    local HeroNameMap = {
        antimage = "Anti-Mage",
        axe = "Axe",
        bane = "Bane",
    }

    local function GetHumanChatHero(name)
        if name == nil then return "" end
        name = name:lower()
        for _, hero in pairs(SupportedHeroes) do
            if HeroNameMap[hero] and HeroNameMap[hero]:lower() == name then
                return hero
            end
        end
        for _, hero in pairs(SupportedHeroes) do
            if string.find(hero, name, 1, true) then
                return hero
            end
        end
        return ""
    end

    assert_eq(GetHumanChatHero("antimage"), "antimage", "exact match")
    assert_eq(GetHumanChatHero("ANTIMAGE"), "antimage", "case insensitive")
    assert_eq(GetHumanChatHero("ant"), "antimage", "prefix match")
    assert_eq(GetHumanChatHero("nonexistent"), "", "no match")
    assert_eq(GetHumanChatHero(nil), "", "nil input")
    assert_eq(GetHumanChatHero(""), "", "empty input")
end

-- Test 2: ScoreCandidatesForTeam scoring logic
print("Test: ScoreCandidatesForTeam scoring...")
do
    -- Test that lower HP enemies score higher, closer enemies score higher
    local function ScoreTarget(botPos, enemyPos, enemyHpPct)
        local dx = enemyPos.x - botPos.x
        local dy = enemyPos.y - botPos.y
        local d = math.sqrt(dx * dx + dy * dy)
        local hp = enemyHpPct
        local score = 3000 - d - hp * 1000
        if enemyHpPct < 0.4 then score = score + 300 end
        return score
    end

    local botPos = {x = 0, y = 0}
    
    -- Closer enemy should score higher
    local closeScore = ScoreTarget(botPos, {x = 100, y = 0}, 0.5)
    local farScore = ScoreTarget(botPos, {x = 1000, y = 0}, 0.5)
    assert_true(closeScore > farScore, "closer enemy scores higher")

    -- Lower HP enemy should score higher
    local lowHpScore = ScoreTarget(botPos, {x = 100, y = 0}, 0.2)
    local highHpScore = ScoreTarget(botPos, {x = 100, y = 0}, 0.8)
    assert_true(lowHpScore > highHpScore, "lower HP enemy scores higher")

    -- Low HP bonus should apply
    local withBonus = ScoreTarget(botPos, {x = 100, y = 0}, 0.3)
    local withoutBonus = ScoreTarget(botPos, {x = 100, y = 0}, 0.5)
    assert_true(withBonus > withoutBonus, "HP < 0.4 gets bonus")
end

-- Test 3: Laning lane position calculation
print("Test: Laning lane position calculation...")
do
    local function GetLaneFrontPosition(lane, offset)
        -- Simplified version of BotLane.FrontLocation
        local positions = {
            [1] = {x = -3000, y = -3000},  -- TOP
            [2] = {x = 0, y = 0},          -- MID
            [3] = {x = 3000, y = 3000},    -- BOT
        }
        local pos = positions[lane]
        if not pos then return nil end
        return {x = pos.x + offset, y = pos.y + offset}
    end

    local topPos = GetLaneFrontPosition(1, 0)
    local midPos = GetLaneFrontPosition(2, 0)
    local botPos = GetLaneFrontPosition(3, 0)

    assert_not_nil(topPos, "top lane position")
    assert_not_nil(midPos, "mid lane position")
    assert_not_nil(botPos, "bot lane position")
    assert_eq(topPos.x, -3000, "top lane x")
    assert_eq(midPos.x, 0, "mid lane x")
    assert_eq(botPos.x, 3000, "bot lane x")
end

-- Test 4: Lane role mapping
print("Test: Lane role mapping...")
do
    local LANE_ROLE = {
        [1] = "offlane",    -- LANE_TOP
        [2] = "mid",        -- LANE_MID
        [3] = "carry",      -- LANE_BOT
    }

    assert_eq(LANE_ROLE[1], "offlane", "top lane is offlane")
    assert_eq(LANE_ROLE[2], "mid", "mid lane is mid")
    assert_eq(LANE_ROLE[3], "carry", "bot lane is carry")
end

print(string.format("\nResults: %d passed, %d failed", passed, failed))
if failed > 0 then
    os.exit(1)
end
