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
function HeroSelection:GetBestPick(humanRoles, enemyPicks, bannedHeroes)
    -- Determine our position
    local bot = GetBot()
    local position = GetBotPosition(bot)
    local pool = POSITION_HEROES[position] or POSITION_HEROES[1]
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
function HeroSelection:Think()
    -- Initialize on first call
    if not phaseState.initialized then
        phaseState.initialized = true
        print("[HeroSelection] Initialized")
    end
    
    local gameState = GameRules:State_Get()
    if gameState ~= DOTA_GAMERULES_STATE_HERO_SELECTION then
        return
    end
    
    local bot = GetBot()
    if not bot or bot:IsNull() then return end
    
    local playerID = bot:GetPlayerID()
    if playerID < 0 or playerID > 9 then return end
    
    -- Get current pick/ban state
    local pickState = GetHeroPickState()
    if not pickState then return end
    
    local team = bot:GetTeam()
    local isRadiant = team == DOTA_TEAM_GOODGUYS
    local teamKey = isRadiant and "radiant" or "dire"
    
    -- Get current phase
    local phase = pickState.phase or "ban"
    local currentPicker = pickState.currentPicker
    
    -- Check if it's our turn
    if currentPicker ~= playerID then
        return
    end
    
    -- Collect enemy picks and banned heroes
    local enemyPicks = {}
    local bannedHeroes = {}
    
    for _, pick in ipairs(pickState.picks or {}) do
        if pick.team ~= teamKey then
            table.insert(enemyPicks, pick.hero)
        end
    end
    
    for _, ban in ipairs(pickState.bans or {}) do
        table.insert(bannedHeroes, ban.hero)
    end
    
    -- Get human roles on our team
    local humanRoles = {}
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) == team and not PlayerResource:IsFakeClient(i) then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                local name = hero:GetUnitName()
                if name:find("antimage") or name:find("juggernaut") or name:find("phantom_assassin") or name:find("spectre") or name:find("medusa") then
                    humanRoles.carry = true
                elseif name:find("invoker") or name:find("storm") or name:find("templar") or name:find("puck") or name:find("ember") then
                    humanRoles.mid = true
                elseif name:find("centaur") or name:find("tidehunter") or name:find("dragon_knight") or name:find("axe") or name:find("mars") then
                    humanRoles.offlane = true
                else
                    humanRoles.support = true
                end
            end
        end
    end
    
    if phase == "ban" then
        local bans = self:GetBanRecommendations(enemyPicks, bannedHeroes)
        if #bans > 0 then
            Say("-ban " .. bans[1].hero)
            print("[HeroSelection] Banned: " .. bans[1].hero)
        end
    elseif phase == "pick" then
        local pick = self:GetBestPick(humanRoles, enemyPicks, bannedHeroes)
        if pick then
            Say("-pick " .. pick)
            print("[HeroSelection] Picked: " .. pick)
        end
    end
end

-- Export for use by init.lua
return HeroSelection