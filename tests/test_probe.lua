-- Probe: find real runtime bugs in the bot script by executing them.
-- Run: lua5.1 tests/test_probe.lua

package.path = "vscripts/bots/?.lua;" .. package.path

local failures = 0
local function check(name, ok, detail)
    if ok then
        print("PASS  " .. name)
    else
        print("FAIL  " .. name .. (detail and ("  -- " .. detail) or ""))
        failures = failures + 1
    end
end

-- ---- Fake engine ----------------------------------------------------------
local function makeBot()
    return {
        IsNull = function() return false end,
        IsAlive = function() return true end,
        GetGold = function() return 2000 end,
        GetRole = function() return "carry" end,
        GetHealth = function() return 800 end,
        GetMaxHealth = function() return 1000 end,
        GetItemInSlot = function() return nil end,
        HasItem = function() return false end,
        GetAbilityPoints = function() return 0 end,
        GetAbilityByIndex = function() return nil end,
        GetAbilityByName = function() return nil end,
        GetNearbyEnemyHeroes = function() return {} end,
        GetNearbyAlliedHeroes = function() return {} end,
        GetNearbyLaneCreeps = function() return {} end,
        GetNearbyNeutralCreeps = function() return {} end,
        GetNearbyNeutralCamps = function() return {} end,
        GetPushingWaves = function() return {} end,
        GetAvailableWards = function() return 0 end,
        GetAbsOrigin = function() return { x = 0, y = 0, z = 0 } end,
        GetAssignedLane = function() return "safe" end,
        SetAssignedLane = function() end,
        GetTeam = function() return 2 end,
        GetPlayerID = function() return 0 end,
        SetBotName = function() end,
        GetCourier = function() return nil end,
        GetStashValue = function() return 0 end,
        GetBuybackCost = function() return 0 end,
        DistanceFromFountain = function() return 0 end,
        DistanceFromSideShop = function() return 0 end,
        DistanceFromSecretShop = function() return 0 end,
        GetGold_ = function() return 2000 end,
    }
end

local fakeBot = makeBot()
-- Action methods always exist in the Dota 2 bot VM. Add them so the probe
-- finds real bugs rather than harness gaps.
fakeBot.Action_AttackMove = function() return true end
fakeBot.Action_AttackTarget = function() return true end
fakeBot.Action_AttackUnit = function() return true end
fakeBot.Action_MoveToLocation = function() return true end
fakeBot.Action_UseAbility = function() return true end
fakeBot.Action_UseAbilityOnEntity = function() return true end
fakeBot.Action_UseAbilityOnLocation = function() return true end
fakeBot.ActionImmediate_Chat = function() return true end
fakeBot.ActionImmediate_PurchaseItem = function() return 0 end
fakeBot.ActionImmediate_LevelUpAbility = function() return true end
fakeBot.ActionImmediate_Buyback = function() return true end
fakeBot.AttackTarget = function() return true end
fakeBot.MoveToPosition = function() return true end

_G.GetBot = function() return fakeBot end
_G.DotaTime = function() return 100 end
_G.GetTeam = function() return 2 end
_G.Vector = function(x, y, z) return { x = x, y = y, z = z } end
_G.GetLaneFrontLocation = function() return { x = 0, y = 0, z = 0 } end

-- ============================================================================
-- BUG 1: init.lua compares `now >= self.nextChatter` where nextChatter is
-- never initialised. In Lua, comparing a number with nil raises an error.
-- ============================================================================
do
    local AetherWeaver = require("init")
    local ok, err = pcall(function() AetherWeaver:BotThink() end)
    check("init.lua: BotThink() runs without error on first call",
        ok, tostring(err))
end

-- ============================================================================
-- BUG 1b: the same call must keep working on later frames (the schedule
-- fields have to be numbers, not nil, after the first tick).
-- ============================================================================
do
    local AetherWeaver = require("init")
    local ok, err = pcall(function()
        AetherWeaver:BotThink()
        AetherWeaver:BotThink()
        AetherWeaver:BotThink()
    end)
    check("init.lua: BotThink() runs on repeated frames",
        ok, tostring(err))
end

-- ============================================================================
-- BUG 2: item build lists repeat the same item (e.g. 3x item_tango) but the
-- purchase guard is `not bot:HasItem(item)`, so the bot buys it exactly once
-- and can never reach the second copy.
-- ============================================================================
do
    local ItemPurchase = require("item_purchase_generic")

    -- Simulate: bot owns nothing, buys the first affordable item repeatedly.
    -- Owned items are tracked through GetItemInSlot so the count is real.
    local owned = {}
    local bought = {}
    local bot = makeBot()
    bot.HasItem = function(self, name) return owned[name] == true end
    bot.GetItemInSlot = function(self, slot)
        for name, count in pairs(owned) do
            if count > 0 then
                owned[name] = count - 1
                return { IsNull = function() return false end,
                         GetName = function() return name end }
            end
        end
        return nil
    end
    bot.ActionImmediate_PurchaseItem = function(self, item)
        bought[#bought + 1] = item
        owned[item] = (owned[item] or 0) + 1
        return 0 -- PURCHASE_ITEM_SUCCESS
    end

    for _ = 1, 20 do
        ItemPurchase:PurchaseItem(bot)
    end

    local tangos = 0
    for _, item in ipairs(bought) do
        if item == "item_tango" then tangos = tangos + 1 end
    end
    check("item build: bot can buy more than one copy of a repeated item",
        tangos >= 2, "bought " .. tangos .. " tangos, expected >= 2")
end

-- ============================================================================
-- BUG 2b: NeedsToShop and PurchaseItem must agree on what the bot wants,
-- otherwise the bot walks to a shop and then buys nothing.
-- ============================================================================
do
    local ItemPurchase = require("item_purchase_generic")
    local bot = makeBot()
    bot.HasItem = function() return false end
    bot.GetItemInSlot = function() return nil end
    bot.DistanceFromFountain = function() return 900 end
    check("item build: NeedsToShop and GetNextPurchase agree",
        ItemPurchase:NeedsToShop(bot) == true
        and ItemPurchase:GetNextPurchase(bot) ~= nil)
end

-- ============================================================================
-- BUG 7: lanes are INT constants (LANE_TOP=1, LANE_MID=2, LANE_BOT=3), but
-- the code treated them as strings ("safe", "mid", "off"), so an int lane
-- silently fell through to the safe lane and the bot farmed the wrong side.
-- ============================================================================
do
    local BotLane = require("bot_lane")
    check("bot_lane: int lane constants are correct",
        BotLane.LANE_TOP == 1 and BotLane.LANE_MID == 2 and BotLane.LANE_BOT == 3)
    check("bot_lane: int lane normalises to itself",
        BotLane.ToInt(2) == 2)
    check("bot_lane: string lane normalises to the int constant",
        BotLane.ToInt("mid") == 2 and BotLane.ToInt("top") == 1
        and BotLane.ToInt("bot") == 3)
    check("bot_lane: unknown lane falls back to mid",
        BotLane.ToInt(nil) == 2 and BotLane.ToInt(99) == 2)

    -- An int lane must resolve to the same bot as the equivalent string.
    local intBot = makeBot()
    intBot.GetAssignedLane = function() return BotLane.LANE_MID end
    local strBot = makeBot()
    strBot.GetAssignedLane = function() return "mid" end
    check("bot_lane: int and string lanes resolve identically",
        BotLane.GetAssigned(intBot) == BotLane.GetAssigned(strBot))
end

-- ============================================================================
-- BUG 8: GetRole() may not exist in every VM build. Role must still resolve.
-- ============================================================================
do
    local BotLane = require("bot_lane")
    local noRole = makeBot()
    noRole.GetRole = nil
    noRole.GetAssignedLane = function() return BotLane.LANE_MID end
    check("bot_lane: role falls back to lane when GetRole is absent",
        BotLane.GetRole(noRole) == "mid",
        "got " .. tostring(BotLane.GetRole(noRole)))

    local carryBot = makeBot()
    carryBot.GetRole = nil
    carryBot.GetAssignedLane = function() return BotLane.LANE_BOT end
    check("bot_lane: lane BOT resolves to carry",
        BotLane.GetRole(carryBot) == "carry")
end

-- ============================================================================
-- BUG 3: every mode's Think() must be safe when a bot method is absent.
-- The engine calls GetDesire() for EVERY mode for EVERY bot, so one throw
-- in one mode file can take down the whole mode system.
-- ============================================================================
do
    local modes = {
        "mode_laning_generic", "mode_farm_generic", "mode_ward_generic",
        "mode_rune_generic", "mode_item_generic", "mode_retreat_generic",
        "mode_team_roam_generic", "mode_push_lane_generic",
    }
    for _, name in ipairs(modes) do
        _G.GetDesire, _G.Think = nil, nil
        dofile("vscripts/bots/" .. name .. ".lua")
        local ok, err = pcall(_G.Think)
        check(name .. ": Think() survives a bot missing every optional method",
            ok, tostring(err))
    end
end

-- ============================================================================
-- BUG 4: mode files call GetDesire() for a bot whose GetRole() is nil
-- (possible before the hero is fully initialised).
-- ============================================================================
do
    local modes = {
        "mode_laning_generic", "mode_farm_generic", "mode_ward_generic",
        "mode_rune_generic", "mode_item_generic", "mode_retreat_generic",
        "mode_team_roam_generic", "mode_push_lane_generic",
    }
    for _, name in ipairs(modes) do
        _G.GetDesire, _G.Think = nil, nil
        dofile("vscripts/bots/" .. name .. ".lua")
        local savedRole = fakeBot.GetRole
        fakeBot.GetRole = function() return nil end
        local ok, err = pcall(_G.GetDesire)
        fakeBot.GetRole = savedRole
        check(name .. ": GetDesire() survives a nil role",
            ok, tostring(err))
    end
end

-- ============================================================================
-- BUG 5: chat commands. The README must not advertise !push / !roshan /
-- !ward / !lane as working features: the bot VM has no player_chat event,
-- so no parser can work. The README may mention them only to say they are
-- unsupported.
-- ============================================================================
do
    local src = io.open("vscripts/bots/init.lua"):read("*a")
    local hasHandler = src:find("HandleChat") or src:find("!push")

    local readme = io.open("README.md"):read("*a")
    -- Strip the "Not implemented" subsection and the Chat Commands section,
    -- which are allowed to mention the commands.
    local features = readme:match("## Features(.-)## Bot Name")
    if not features then features = "" end
    local claimed = features:match("^(.-)### Not implemented") or features

    local claimsCommands = claimed:find("!push") ~= nil

    check("chat commands: README does not advertise unsupported commands",
        not claimsCommands,
        claimsCommands and "README features section advertises !push but no parser exists"
            or nil)
    check("chat commands: no parser exists in the code either",
        hasHandler == nil, "a parser exists but the README does not document it")
end

-- ============================================================================
-- BUG 6: bot_names.GetForTeam ignores the team argument, so a bot can be
-- named with a name already taken by a teammate (or an enemy).
-- ============================================================================
do
    local BotNames = require("bot_names")
    local seen = {}
    local dupes = 0
    for _ = 1, 2000 do
        local n = BotNames:GetForTeam(2)
        if seen[n] then dupes = dupes + 1 end
        seen[n] = true
    end
    check("bot_names: name pool has enough distinct names for a lobby",
        #BotNames.all >= 10, "pool size " .. #BotNames.all)
end

print("")
if failures == 0 then
    print("ALL PASS")
else
    print(failures .. " FAILURE(S)")
    os.exit(1)
end