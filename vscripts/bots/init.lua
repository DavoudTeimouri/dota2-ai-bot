-- AetherWeaver Dota 2 Bot
-- Workshop addon: vscripts/bots/init.lua

-- Module table
local AetherWeaver = {}

-- Configuration
local MSG_COOLDOWN = 8.0
local lastMsg = 0

-- Helper: Send chat message
local function Say(msg, playerID)
    if not playerID then playerID = 0 end
    -- Use GameRules:SendCustomMessage for all-chat
    if GameRules.SendCustomMessage then
        GameRules:SendCustomMessage(msg, playerID, 0)
    end
end

-- Helper: Maybe send message with cooldown
local function MaybeSay(msg)
    local now = GameRules:GetGameTime()
    if now - lastMsg < MSG_COOLDOWN then return end
    Say(msg)
    lastMsg = now
end

-- Helper: Get human heroes and their roles
local function GetHumanRoles()
    local roles = {carry = false, mid = false, offlane = false, support = false}
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and not PlayerResource:IsFakeClient(i) then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                local name = hero:GetUnitName()
                if name:find("antimage") or name:find("juggernaut") or name:find("phantom_assassin") or name:find("spectre") or name:find("medusa") then
                    roles.carry = true
                elseif name:find("invoker") or name:find("storm") or name:find("templar") or name:find("puck") or name:find("ember") then
                    roles.mid = true
                elseif name:find("centaur") or name:find("tidehunter") or name:find("dragon_knight") or name:find("axe") or name:find("mars") then
                    roles.offlane = true
                else
                    roles.support = true
                end
            end
        end
    end
    return roles
end

-- Pick hero after human picks
local function PickHeroAfterHumans()
    local roleHeroes = {
        carry = {"npc_dota_hero_antimage", "npc_dota_hero_juggernaut", "npc_dota_hero_phantom_assassin", "npc_dota_hero_spectre"},
        mid = {"npc_dota_hero_invoker", "npc_dota_hero_storm_spirit", "npc_dota_hero_templar_assassin", "npc_dota_hero_puck"},
        offlane = {"npc_dota_hero_centaur", "npc_dota_hero_tidehunter", "npc_dota_hero_dragon_knight", "npc_dota_hero_axe"},
        support = {"npc_dota_hero_crystal_maiden", "npc_dota_hero_lich", "npc_dota_hero_witch_doctor", "npc_dota_hero_shadow_shaman"}
    }
    local roles = GetHumanRoles()
    local needed = {}
    for role, _ in pairs(roleHeroes) do
        if not roles[role] then table.insert(needed, role) end
    end
    if #needed == 0 then needed = {"carry", "mid", "offlane", "support"} end
    local role = needed[math.random(#needed)]
    local heroName = roleHeroes[role][math.random(#roleHeroes[role])]
    Say("-pick " .. heroName)
    return heroName
end

-- Assign lane by hero
local function AssignLane(heroName)
    local laneMap = {
        npc_dota_hero_antimage = "safe", npc_dota_hero_juggernaut = "safe", npc_dota_hero_phantom_assassin = "safe", npc_dota_hero_spectre = "safe",
        npc_dota_hero_invoker = "mid", npc_dota_hero_storm_spirit = "mid", npc_dota_hero_templar_assassin = "mid", npc_dota_hero_puck = "mid",
        npc_dota_hero_centaur = "off", npc_dota_hero_tidehunter = "off", npc_dota_hero_dragon_knight = "off", npc_dota_hero_axe = "off",
        npc_dota_hero_crystal_maiden = "support", npc_dota_hero_lich = "support", npc_dota_hero_witch_doctor = "support", npc_dota_hero_shadow_shaman = "support"
    }
    return laneMap[heroName] or "safe"
end

-- Handle chat commands
local function HandleChat(text)
    if not text or text:sub(1,1) ~= "!" then return end
    local cmd = text:sub(2):lower()
    if cmd:find("^push%s+(%a+)") then
        local lane = cmd:match("^push%s+(%a+)")
        MaybeSay("Pushing " .. lane .. " lane!")
    elseif cmd == "roshan" then
        MaybeSay("Let's go Roshan!")
    elseif cmd:find("^ward") then
        MaybeSay("Warding suggested.")
    elseif cmd:find("^lane%s+(%a+)") then
        local lane = cmd:match("^lane%s+(%a+)")
        MaybeSay("Setting lane to " .. lane)
    else
        MaybeSay("Unknown command. Try !push <lane>, !roshan, !ward, !lane <lane>")
    end
end

-- Periodic messages
local periodicMessages = {
    "GL HF! Let's win this!",
    "Remember to buy wards!",
    "Keep an eye on the runes!",
    "Don't feed, play safe!",
    "I'm not a feeder, I'm a dietitian.",
    "Enemy missing mid - watch for ganks!",
    "Roshan spawns soon - prepare!",
    "Rune check time!"
}

-- Bot Think function (called every tick)
function AetherWeaver:BotThink()
    if not self.initialized then
        self.initialized = true
        print('[AetherWeaver] Initialized')
        
        -- Listen for chat
        ListenToGameEvent("player_chat", function(keys)
            if keys.text then HandleChat(keys.text) end
        end, self)
        
        -- Pick hero after delay
        Timers:CreateTimer(2.0, function()
            local hero = PickHeroAfterHumans()
            local lane = AssignLane(hero)
            MaybeSay("I will play " .. hero .. " in the " .. lane .. " lane.")
        end)
        
        -- Periodic messages
        Timers:CreateTimer(15.0, function()
            MaybeSay(periodicMessages[math.random(#periodicMessages)])
            return 15.0
        end)
    end
end

-- Entry point
function Activate()
    print('[AetherWeaver] Activating...')
    -- Register think
    GameRules:GetGameModeEntity():SetThink("BotThink", AetherWeaver, 0.1)
end

-- Make sure Timers library is available (Dota 2 provides it in addon context)
if not Timers then
    Timers = {}
    function Timers:CreateTimer(delay, callback)
        local thinkName = "AetherWeaverTimer" .. math.random(1000000)
        GameRules:GetGameModeEntity():SetThink(function()
            local result = callback()
            if result then return result end
            return nil
        end, thinkName, delay)
    end
end

return AetherWeaver