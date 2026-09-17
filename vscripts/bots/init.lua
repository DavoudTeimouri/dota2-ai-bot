-- AetherWeaver Dota 2 Bot
-- Workshop addon: vscripts/bots/init.lua

-- Helper functions
local function say(msg, playerID)
    if not playerID then playerID = 0 end
    if SendToServerConsole then
        SendToServerConsole('say "' .. msg .. '"\n')
    else
        -- fallback: print
        print('[BOT] ' .. msg)
    end
end

local function getTeam()
    local player = Entities:GetLocalPlayer()
    if player then
        return player:GetTeamNumber()
    end
    return DOTA_TEAM_GOODGUYS
end

local function getHumanHeroes()
    local heroes = {}
    for i = 0, 9 do
        local player = PlayerResource:GetPlayer(i)
        if player and not PlayerResource:IsFakeClient(i) then
            local hero = player:GetAssignedHero()
            if hero and not hero:IsNull() then
                table.insert(heroes, hero)
            end
        end
    end
    return heroes
end

local function pickHeroAfterHumans()
    -- Simple hero table: map role to hero names (internal)
    local roleHeroes = {
        carry = {"npc_dota_hero_antimage", "npc_dota_hero_juggernaut", "npc_dota_hero_phantom_assassin"},
        mid   = {"npc_dota_hero_invoker", "npc_dota_hero_storm_spirit", "npc_dota_hero_templar_assassin"},
        offlane = {"npc_dota_hero_centaur", "npc_dota_hero_tidehunter", "npc_dota_hero_dragon_knight"},
        support = {"npc_dota_hero_crystal_maiden", "npc_dota_hero_lich", "npc_dota_hero_witch_doctor"}
    }
    local team = getTeam()
    -- Determine what roles are missing
    local pickedRoles = {}
    for _, hero in ipairs(getHumanHeroes()) do
        local name = hero:GetUnitName()
        if name == "npc_dota_hero_antimage" or name == "npc_dota_hero_juggernaut" or name == "npc_dota_hero_phantom_assassin" then
            pickedRoles.carry = true
        elseif name == "npc_dota_hero_invoker" or name == "npc_dota_hero_storm_spirit" or name == "npc_dota_hero_templar_assassin" then
            pickedRoles.mid = true
        elseif name == "npc_dota_hero_centaur" or name == "npc_dota_hero_tidehunter" or name == "npc_dota_hero_dragon_knight" then
            pickedRoles.offlane = true
        else
            pickedRoles.support = true
        end
    end
    local needed = {}
    for role, list in pairs(roleHeroes) do
        if not pickedRoles[role] then
            table.insert(needed, role)
        end
    end
    if #needed == 0 then needed = {"carry", "mid", "offlane", "support"} end
    local role = needed[math.random(#needed)]
    local heroName = roleHeroes[role][math.random(#roleHeroes[role])]
    -- Attempt to pick via chat command (requires cheats)
    say("-pick " .. heroName)
    return heroName
end

local function assignLane(heroName)
    local laneMap = {
        ["npc_dota_hero_antimage"] = "safe",
        ["npc_dota_hero_juggernaut"] = "safe",
        ["npc_dota_hero_phantom_assassin"] = "safe",
        ["npc_dota_hero_invoker"] = "mid",
        ["npc_dota_hero_storm_spirit"] = "mid",
        ["npc_dota_hero_templar_assassin"] = "mid",
        ["npc_dota_hero_centaur"] = "off",
        ["npc_dota_hero_tidehunter"] = "off",
        ["npc_dota_hero_dragon_knight"] = "off",
        ["npc_dota_hero_crystal_maiden"] = "support",
        ["npc_dota_hero_lich"] = "support",
        ["npc_dota_hero_witch_doctor"] = "support"
    }
    return laneMap[heroName] or "safe"
end

local lastMsg = 0
local MSG_COOLDOWN = 8.0

local function maybeSay(msg)
    local now = GameRules:GetGameTime()
    if now - lastMsg < MSG_COOLDOWN then return end
    say(msg)
    lastMsg = now
end

local function handleChat(event)
    if not event.text then return end
    local text = event.text:lower()
    if text:sub(1,1) == "!" then
        local cmd = text:sub(2)
        if cmd:sub(1,4) == "push" then
            local lane = cmd:sub(6):match("^%s*(%a+)"):lower()
            maybeSay("Pushing " .. lane .. "!")
            -- TODO: implement push logic
        elseif cmd == "roshan" then
            maybeSay("Let's go Roshan!")
        elseif cmd:sub(1,4) == "ward" then
            maybeSay("Warding suggested.")
        elseif cmd:sub(1,4) == "lane" then
            local lane = cmd:sub(6):match("^%s*(%a+)"):lower()
            maybeSay("Setting lane to " .. lane)
        else
            maybeSay("Unknown command.")
        end
    end
end

-- Initialize
function Activate()
    print('[AetherWeaver] Bot activated')
    -- Listen to chat
    ListenToGameEvent('player_chat', Dynamic_Wrap(AetherWeaver, 'OnPlayerChat'), self)
    -- Pick hero after a short delay
    Timers:CreateTimer(2.0, function()
        local hero = pickHeroAfterHumans()
        local lane = assignLane(hero)
        maybeSay("I will play " .. hero .. " in the " .. lane .. " lane.")
        return nil
    end)
    -- Periodic messages
    Timers:CreateTimer(15.0, function()
        local msgs = {
            "GL HF! Let's win this!",
            "Remember to buy wards!",
            "Keep an eye on the runes!",
            "Don't feed, play safe!",
            "I'm not a feeder, I'm a dietitian."
        }
        maybeSay(msgs[math.random(#msgs)])
        return 15.0
    end)
end

function AetherWeaver:OnPlayerChat(event)
    handleChat(event)
end

return AetherWeaver