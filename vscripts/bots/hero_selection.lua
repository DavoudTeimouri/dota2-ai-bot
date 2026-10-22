-- AetherWeaver Hero Selection
-- Workshop addon: vscripts/bots/hero_selection.lua
-- Provides Think() for hero pick/ban phase

local HeroSelection = {}

-- Position-based hero pools with preferred attributes
-- Pos1 (carry) prefers AGI, Pos2 (mid) prefers INT, Pos3 (offlane) prefers STR, Pos4/5 (support) prefer INT
local POSITION_HEROES = {
    -- Position 1 (Safe Lane Carry) - AGI preferred
    [1] = {
        {hero = "npc_dota_hero_antimage", attr = "agi"},
        {hero = "npc_dota_hero_juggernaut", attr = "agi"},
        {hero = "npc_dota_hero_phantom_assassin", attr = "agi"},
        {hero = "npc_dota_hero_spectre", attr = "agi"},
        {hero = "npc_dota_hero_medusa", attr = "agi"},
        {hero = "npc_dota_hero_luna", attr = "agi"},
        {hero = "npc_dota_hero_drow_ranger", attr = "agi"},
        {hero = "npc_dota_hero_terrorblade", attr = "agi"},
        {hero = "npc_dota_hero_morphling", attr = "agi"},
        {hero = "npc_dota_hero_faceless_void", attr = "agi"},
    },
    -- Position 2 (Mid) - INT preferred
    [2] = {
        {hero = "npc_dota_hero_invoker", attr = "int"},
        {hero = "npc_dota_hero_storm_spirit", attr = "int"},
        {hero = "npc_dota_hero_templar_assassin", attr = "agi"},
        {hero = "npc_dota_hero_puck", attr = "int"},
        {hero = "npc_dota_hero_ember_spirit", attr = "agi"},
        {hero = "npc_dota_hero_queenofpain", attr = "int"},
        {hero = "npc_dota_hero_shadow_fiend", attr = "agi"},
        {hero = "npc_dota_hero_tinker", attr = "int"},
        {hero = "npc_dota_hero_zeus", attr = "int"},
        {hero = "npc_dota_hero_obsidian_destroyer", attr = "int"},
    },
    -- Position 3 (Offlane) - STR preferred
    [3] = {
        {hero = "npc_dota_hero_centaur", attr = "str"},
        {hero = "npc_dota_hero_tidehunter", attr = "str"},
        {hero = "npc_dota_hero_dragon_knight", attr = "str"},
        {hero = "npc_dota_hero_axe", attr = "str"},
        {hero = "npc_dota_hero_mars", attr = "str"},
        {hero = "npc_dota_hero_underlord", attr = "str"},
        {hero = "npc_dota_hero_bristleback", attr = "str"},
        {hero = "npc_dota_hero_timbersaw", attr = "str"},
        {hero = "npc_dota_hero_dark_seer", attr = "int"},
        {hero = "npc_dota_hero_beastmaster", attr = "str"},
    },
    -- Position 4 (Roaming Support) - INT preferred
    [4] = {
        {hero = "npc_dota_hero_crystal_maiden", attr = "int"},
        {hero = "npc_dota_hero_lich", attr = "int"},
        {hero = "npc_dota_hero_witch_doctor", attr = "int"},
        {hero = "npc_dota_hero_shadow_shaman", attr = "int"},
        {hero = "npc_dota_hero_bane", attr = "int"},
        {hero = "npc_dota_hero_lion", attr = "int"},
        {hero = "npc_dota_hero_grimstroke", attr = "int"},
        {hero = "npc_dota_hero_snapfire", attr = "int"},
        {hero = "npc_dota_hero_hoodwink", attr = "agi"},
        {hero = "npc_dota_hero_marci", attr = "str"},
    },
    -- Position 5 (Hard Support) - INT preferred
    [5] = {
        {hero = "npc_dota_hero_dazzle", attr = "int"},
        {hero = "npc_dota_hero_oracle", attr = "int"},
        {hero = "npc_dota_hero_warlock", attr = "int"},
        {hero = "npc_dota_hero_keeper_of_the_light", attr = "int"},
        {hero = "npc_dota_hero_ancient_apparition", attr = "int"},
        {hero = "npc_dota_hero_jakiro", attr = "int"},
        {hero = "npc_dota_hero_ogre_magi", attr = "int"},
        {hero = "npc_dota_hero_treant", attr = "str"},
        {hero = "npc_dota_hero_omniknight", attr = "str"},
        {hero = "npc_dota_hero_abaddon", attr = "str"},
    },
}

-- Meta strength values (0.0-1.0) for ban priority
local META_STRENGTH = {
    ["npc_dota_hero_muerta"] = 0.92,
    ["npc_dota_hero_ringmaster"] = 0.90,
    ["npc_dota_hero_kez"] = 0.88,
    ["npc_dota_hero_primal_beast"] = 0.87,
    ["npc_dota_hero_dawnbreaker"] = 0.86,
    ["npc_dota_hero_marci"] = 0.85,
    ["npc_dota_hero_void_spirit"] = 0.84,
    ["npc_dota_hero_arc_warden"] = 0.83,
    ["npc_dota_hero_puck"] = 0.82,
    ["npc_dota_hero_templar_assassin"] = 0.81,
}

-- Phase state tracking
local phaseState = {
    phase = "ban", -- "ban", "pick", "complete"
    bans = {radiant = {}, dire = {}},
    picks = {radiant = {}, dire = {}},
    currentTeam = "radiant",
    pickOrder = {},
    initialized = false
}

-- Get bot's position (slot-based)
-- Radiant: 0=P1, 1=P2, 2=P3, 3=P4, 4=P5
-- Dire: 5=P1, 6=P2, 7=P3, 8=P4, 9=P5
local function GetBotPosition(bot)
    if not bot then return 1 end
    local playerID = bot:GetPlayerID()
    if playerID < 0 or playerID > 9 then return 1 end
    
    if playerID <= 4 then -- Radiant
        return playerID + 1
    else -- Dire
        return playerID - 4
    end
end

-- Filter hero pool by attribute preference
local function FilterByAttribute(pool, preferredAttr)
    if not preferredAttr then return pool end
    
    local filtered = {}
    for _, entry in ipairs(pool) do
        if entry.attr == preferredAttr then
            table.insert(filtered, entry)
        end
    end
    
    -- Fallback to full pool if no matches
    if #filtered == 0 then
        return pool
    end
    return filtered
end

-- Get preferred attribute for position
local function GetPreferredAttr(position)
    if position == 1 then return "agi" end
    if position == 2 then return "int" end
    if position == 3 then return "str" end
    return "int" -- Pos 4/5
end

-- Weighted random pick from pool
local function WeightedRandomPick(pool)
    if not pool or #pool == 0 then return nil end
    
    local totalWeight = 0
    for _, entry in ipairs(pool) do
        totalWeight = totalWeight + (entry.weight or 1)
    end
    
    local rand = math.random() * totalWeight
    local cumulative = 0
    for _, entry in ipairs(pool) do
        cumulative = cumulative + (entry.weight or 1)
        if rand <= cumulative then
            return entry.hero
        end
    end
    return pool[#pool].hero
end

-- Get counter-pick recommendations based on enemy lineup
local function GetCounterPicks(enemyPicks, bannedHeroes)
    local counters = {}
    local counterMap = {
        -- Anti-magic/Physical
        ["npc_dota_hero_antimage"] = {"npc_dota_hero_axe", "npc_dota_hero_slardar", "npc_dota_hero_doom_bringer"},
        ["npc_dota_hero_phantom_assassin"] = {"npc_dota_hero_centaur", "npc_dota_hero_tidehunter", "npc_dota_hero_bristleback"},
        ["npc_dota_hero_spectre"] = {"npc_dota_hero_undying", "npc_dota_hero_necrolyte", "npc_dota_hero_zeus"},
        -- Anti-mobility
        ["npc_dota_hero_storm_spirit"] = {"npc_dota_hero_silencer", "npc_dota_hero_skywrath_mage", "npc_dota_hero_bane"},
        ["npc_dota_hero_puck"] = {"npc_dota_hero_silencer", "npc_dota_hero_doom_bringer", "npc_dota_hero_bane"},
        ["npc_dota_hero_ember_spirit"] = {"npc_dota_hero_lion", "npc_dota_hero_shadow_shaman", "npc_dota_hero_bane"},
        -- Anti-tank
        ["npc_dota_hero_centaur"] = {"npc_dota_hero_necrolyte", "npc_dota_hero_ancient_apparition", "npc_dota_hero_viper"},
        ["npc_dota_hero_tidehunter"] = {"npc_dota_hero_necrolyte", "npc_dota_hero_reaper", "npc_dota_hero_ancient_apparition"},
    }
    
    for _, enemyHero in ipairs(enemyPicks) do
        local heroCounters = counterMap[enemyHero]
        if heroCounters then
            for _, counter in ipairs(heroCounters) do
                local banned = false
                for _, b in ipairs(bannedHeroes) do
                    if b == counter then banned = true break end
                end
                if not banned then
                    counters[counter] = (counters[counter] or 0) + 1
                end
            end
        end
    end
    
    -- Convert to sorted array
    local result = {}
    for hero, score in pairs(counters) do
        table.insert(result, {hero = hero, score = score})
    end
    table.sort(result, function(a, b) return a.score > b.score end)
    return result
end

-- Get best pick recommendation
-- poolOverride: the caller may pass the heroes that are actually still
-- available, already filtered against the bans and the enemy picks.
function HeroSelection:GetBestPick(humanRoles, enemyPicks, bannedHeroes, poolOverride)
    -- Determine our position
    local bot = GetBot()
    local position = GetBotPosition(bot)
    local pool = poolOverride or (POSITION_HEROES[position] or POSITION_HEROES[1])
    local preferredAttr = GetPreferredAttr(position)
    
    -- Filter by attribute
    pool = FilterByAttribute(pool, preferredAttr)
    
    -- Remove banned heroes
    local filteredPool = {}
    for _, entry in ipairs(pool) do
        local banned = false
        for _, b in ipairs(bannedHeroes) do
            if b == entry.hero then banned = true break end
        end
        for _, p in ipairs(enemyPicks) do
            if p == entry.hero then banned = true break end
        end
        if not banned then
            table.insert(filteredPool, entry)
        end
    end
    
    -- Get counter-picks and boost their weight
    local counters = GetCounterPicks(enemyPicks, bannedHeroes)
    for _, counter in ipairs(counters) do
        for _, entry in ipairs(filteredPool) do
            if entry.hero == counter.hero then
                entry.weight = (entry.weight or 1) + counter.score * 2
                break
            end
        end
    end
    
    -- Boost meta heroes not banned
    for _, entry in ipairs(filteredPool) do
        local meta = META_STRENGTH[entry.hero] or 0
        if meta > 0.8 then
            entry.weight = (entry.weight or 1) + meta * 3
        end
    end
    
    -- Pick
    local pick = WeightedRandomPick(filteredPool)
    return pick or filteredPool[1].hero or "npc_dota_hero_crystal_maiden"
end

-- Get ban recommendations
function HeroSelection:GetBanRecommendations(enemyPicks, bannedHeroes)
    local bans = {}
    
    -- Ban high meta strength heroes not yet banned/picked
    for hero, strength in pairs(META_STRENGTH) do
        if strength > 0.85 then
            local alreadyBanned = false
            for _, b in ipairs(bannedHeroes) do
                if b == hero then alreadyBanned = true break end
            end
            local alreadyPicked = false
            for _, p in ipairs(enemyPicks) do
                if p == hero then alreadyPicked = true break end
            end
            if not alreadyBanned and not alreadyPicked then
                table.insert(bans, {hero = hero, strength = strength})
            end
        end
    end
    
    table.sort(bans, function(a, b) return a.strength > b.strength end)
    return bans
end

-- Main Think function called by Dota 2 during pick/ban phase
-- Set the custom bot name exactly once per bot, and keep it across respawns.
local named = {}

-- Heroes already taken this game, per team, so two bots on the same team do
-- not pick the same hero.
local picked = { radiant = {}, dire = {} }

local function EnsureBotName(bot)
    if not bot or bot:IsNull() then return end
    if named[bot] then return end
    named[bot] = true
    local BotNames = require("bot_names")
    BotNames:SetBotName(bot, bot:GetTeam())
end

-- SelectHero() wants the short hero name ("antimage"), the pools hold the
-- full unit name ("npc_dota_hero_antimage").
local function ShortHeroName(full)
    if not full then return nil end
    return (full:gsub("^npc_dota_hero_", ""))
end

-- Actually lock the hero in. Returns true when SelectHero was called.
local function CommitPick(playerID, heroFull, teamKey)
    if not SelectHero then return false end
    if not heroFull then return false end
    if picked[teamKey] and picked[teamKey][heroFull] then return false end

    local short = ShortHeroName(heroFull)
    if not short or short == "" then return false end

    local ok = pcall(SelectHero, playerID, short)
    if not ok then return false end
    if not picked[teamKey] then picked[teamKey] = {} end
    picked[teamKey][heroFull] = true
    print("[HeroSelection] Selected: " .. short)
    return true
end

-- Say uses only bot API: ActionImmediate_Chat. PlayerResource is nil in this VM,
-- so we always speak to our own team (playerID == 0 means team chat).
local function Say(msg)
    local bot = GetBot()
    if bot and not bot:IsNull() then
        bot:ActionImmediate_Chat(msg, true)
    end
end

-- Team ID constants; GameRules may not expose them in the bot VM.
local DOTA_TEAM_GOODGUYS = 2
local DOTA_TEAM_BADGUYS = 3

-- Is it this player's turn to act in the pick phase?
-- This is the only gate that matters: it is false outside the pick phase
-- and false when it is somebody else's turn.
local function OurTurnToPick(playerID)
    if not IsPlayerInHeroSelectionControl then return false end
    local ok, inControl = pcall(IsPlayerInHeroSelectionControl, playerID)
    if not ok then return false end
    return inControl and true or false
end

-- The enemy team constant, for the Captains Mode queries.
local function EnemyTeam(team)
    if GetOpposingTeam then
        local ok, enemy = pcall(GetOpposingTeam)
        if ok and enemy then return enemy end
    end
    return (team == DOTA_TEAM_GOODGUYS) and DOTA_TEAM_BADGUYS or DOTA_TEAM_GOODGUYS
end

-- Has the enemy team already picked this hero?
local function EnemyPicked(enemyTeam, hero)
    if not IsCMPickedHero then return false end
    local ok, picked = pcall(IsCMPickedHero, enemyTeam, hero)
    if not ok then return false end
    return picked and true or false
end

-- Has this hero been banned?
local function IsBanned(hero)
    if not IsCMBannedHero then return false end
    local ok, banned = pcall(IsCMBannedHero, hero)
    if not ok then return false end
    return banned and true or false
end

-- The heroes a human on our team has already taken, so the bot does not
-- duplicate a role. Reads the selected hero name per player slot.
local function HumanRoles(team)
    local roles = {}
    if not GetTeamPlayers or not GetSelectedHeroName or not IsPlayerBot then
        return roles
    end
    local ok, players = pcall(GetTeamPlayers, team)
    if not ok or not players then return roles end
    for _, pid in ipairs(players) do
        local ok2, isBot = pcall(IsPlayerBot, pid)
        if ok2 and not isBot then
            local ok3, name = pcall(GetSelectedHeroName, pid)
            if ok3 and name then
                if name:find("antimage") or name:find("juggernaut")
                    or name:find("phantom_assassin") or name:find("spectre")
                    or name:find("medusa") or name:find("luna")
                    or name:find("drow_ranger") or name:find("terrorblade")
                    or name:find("morphling") or name:find("faceless_void") then
                    roles.carry = true
                elseif name:find("invoker") or name:find("storm_spirit")
                    or name:find("templar_assassin") or name:find("puck")
                    or name:find("ember_spirit") or name:find("queenofpain")
                    or name:find("shadow_fiend") or name:find("tinker")
                    or name:find("zeus") then
                    roles.mid = true
                elseif name:find("centaur") or name:find("tidehunter")
                    or name:find("dragon_knight") or name:find("axe")
                    or name:find("mars") or name:find("underlord")
                    or name:find("bristleback") or name:find("timbersaw") then
                    roles.offlane = true
                else
                    roles.support = true
                end
            end
        end
    end
    return roles
end

function HeroSelection:Think()
    -- Initialize on first call
    if not phaseState.initialized then
        phaseState.initialized = true
        print("[HeroSelection] Initialized")
    end

    local bot = GetBot()
    if not bot or bot:IsNull() then return end

    -- Naming works in every game phase, so do it before the pick/ban checks.
    EnsureBotName(bot)

    local playerID = bot:GetPlayerID()
    if playerID < 0 or playerID > 9 then return end

    -- Outside the pick phase there is nothing to do.
    if not OurTurnToPick(playerID) then return end

    local team = bot:GetTeam()
    local teamKey = (team == DOTA_TEAM_GOODGUYS) and "radiant" or "dire"
    local enemyTeam = EnemyTeam(team)

    -- Captains Mode has a ban phase before the picks.
    if IsInCMBanPhase and IsInCMBanPhase() then
        local bans = self:GetBanRecommendations({}, {})
        if #bans > 0 then
            Say("-ban " .. bans[1].hero)
            print("[HeroSelection] Banned: " .. bans[1].hero)
        end
        return
    end

    -- Pick a hero. The Captains Mode queries tell us which heroes are out.
    local pool = POSITION_HEROES[GetBotPosition(bot)] or POSITION_HEROES[1]
    local available = {}
    for _, entry in ipairs(pool) do
        if not IsBanned(entry.hero) and not EnemyPicked(enemyTeam, entry.hero) then
            available[#available + 1] = entry
        end
    end
    -- Every hero in the position is taken: widen the search to the whole pool.
    if #available == 0 then
        for _, entries in pairs(POSITION_HEROES) do
            for _, entry in ipairs(entries) do
                if not IsBanned(entry.hero) and not EnemyPicked(enemyTeam, entry.hero) then
                    available[#available + 1] = entry
                end
            end
        end
    end
    if #available == 0 then return end

    local humanRoles = HumanRoles(team)
    local pick = self:GetBestPick(humanRoles, {}, {}, available)
    if not pick then return end

    -- Lock the pick in, not just announce it.
    if CommitPick(playerID, pick, teamKey) then
        Say("-pick " .. ShortHeroName(pick))
        print("[HeroSelection] Picked: " .. pick)
    end
end

-- Engine hook. hero_selection.lua is the file the engine calls Think() in, so
-- the global MUST exist here -- a method on the module table is never reached.
function Think()
    HeroSelection:Think()
end

-- Export for use by init.lua
return HeroSelection