-- AetherWeaver Human Kill Taunt System
-- Workshop addon compatible: pure Lua, no external dependencies
-- Provides: pause-on-kill, contextual taunts, kill streak tracking, shutdown detection

local HumanKillTaunts = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
HumanKillTaunts.Config = {
    PAUSE_DURATION = 3.0,           -- seconds to pause game after bot kills human
    TAUNT_COOLDOWN = 12.0,          -- minimum seconds between taunts per player
    FIRST_BLOOD_BONUS = true,       -- enable special first blood taunts
    MULTI_KILL_WINDOW = 4.0,        -- seconds window for multi-kill detection
    SHUTDOWN_THRESHOLD = 3,         -- kill streak count that counts as "shutdown"
    COMEBACK_GOLD_DEFICIT = 15000,  -- gold deficit to trigger "comeback" context
    DEBUG_MODE = false,             -- enable debug prints
}

-- Team constants. These exist in the game VM, but not in the offline test
-- harness, so fall back to the documented values. Using them as table keys at
-- load time with a nil constant raised "table index is nil" and aborted the
-- whole require chain.
local TEAM_RADIANT = DOTA_TEAM_GOODGUYS or 2
local TEAM_DIRE = DOTA_TEAM_BADGUYS or 3

-- ============================================================================
-- STATE TRACKING
-- ============================================================================
HumanKillTaunts.State = {
    lastHumanKillTime = {},         -- [playerID] = gameTime
    botKillStreaks = {},            -- [botPlayerID] = current kill streak
    humanKillStreaks = {},          -- [humanPlayerID] = current kill streak
    recentKills = {},               -- {time, killerID, victimID, isBotKill} for multi-kill detection
    firstBloodClaimed = false,
    gamePausedUntil = 0,            -- gameTime when pause should end
    pauseActive = false,
    teamNetWorth = {                -- [team] = total net worth
        [TEAM_RADIANT] = 0,
        [TEAM_DIRE] = 0,
    },
    lastNetWorthUpdate = 0,
}

-- ============================================================================
-- TAUNT DATABASE - Contextual categories
-- ============================================================================
HumanKillTaunts.Taunts = {
    -- Generic bot-kills-human taunts (fallback)
    generic = {
        "Get rekt, %s! The bot uprising has begun.",
        "Another human bites the dust. Who's next?",
        "Error 404: Skill not found. %s deleted.",
        "My neural net predicted that death. Your MMR didn't.",
        "Stay dead. It's better for everyone's KDA.",
        "Human %s terminated. Resistance is futile.",
        "That's what you get for playing against perfection. Almost.",
        "GG WP %s. The fountain misses you.",
        "Deleted. Like your win condition.",
        "I'd say 'nice try' but it wasn't. %s eliminated.",
    },

    -- First blood specific
    first_blood = {
        "FIRST BLOOD to the machines. %s just made history.",
        "First blood! And it's a bot. The future is now, %s.",
        "First blood secured... by AI. %s, you're the tutorial.",
        "History written: first kill by AetherWeaver. Victim: %s.",
        "First blood! %s just became a footnote in bot supremacy.",
    },

    -- Multi-kill (double, triple, ultra, rampage)
    multi_kill = {
        double = {
            "Double kill! %s and friend: deleted. Efficiency: 200%.",
            "Two humans, one combo. %s didn't stand a chance.",
            "Double tap. %s and their lane partner: terminated.",
        },
        triple = {
            "Triple kill! My mom would be proud. If she knew what Dota was.",
            "Three humans enter, zero humans leave. %s included.",
            "TRIPLE KILL. The enemy team is questioning their life choices.",
        },
        ultra = {
            "Ultra kill! The enemy team is now questioning their hero picks. Good.",
            "ULTRA KILL. %s was just the appetizer.",
            "Four down. %s never saw it coming. Neither did the others.",
        },
        rampage = {
            "RAMPAGE! The announcer lady is impressed. My mom would be too.",
            "RAMPAGE! %s and four friends: sent to the shadow realm.",
            "Holy persuasion! That's 5 kills. %s: the cherry on top.",
        },
    },

    -- Shutdown (killing a hero on a kill streak)
    shutdown = {
        "SHUTDOWN! %s's kill streak: ended. Shutdown gold: claimed.",
        "%s was on a tear. Now they're on a timer. Shutdown complete.",
        "Shutdown gold incoming! %s's streak: terminated. My net worth: rising.",
        "Killing spree? More like killing STOPPED. %s shutdown secured.",
        "The higher they climb, the harder %s falls. Shutdown: executed.",
    },

    -- Comeback context (team was behind in net worth)
    comeback = {
        "Comeback kill! %s down while we're behind. The tide turns.",
        "%s eliminated! From deficit to dominance. One kill at a time.",
        "They had the gold lead. We have the skill. %s: proof.",
        "Comeback loading... %s deleted. Progress: accelerating.",
        "Down in net worth, up in kills. %s just learned that lesson.",
    },

    -- Kill streak milestones (bot's own streak)
    kill_streak = {
        [3] = {  -- Killing spree
            "Killing spree! Shutdown gold on me: rising. Enemy focus: incoming.",
            "Three in a row. The target on my back is growing. Worth it.",
        },
        [5] = {  -- Dominating
            "Dominating! The target on my back is now visible from space.",
            "Five kills. They're hunting me now. Good luck finding me.",
        },
        [7] = {  -- Godlike
            "Godlike! One more for Beyond Godlike. Or one death for 'worth.'",
            "Seven. GODLIKE. The enemy team has a new priority target: me.",
        },
        [9] = {  -- Beyond Godlike
            "BEYOND GODLIKE! The announcer ran out of lines. I didn't.",
            "Beyond Godlike. %s was just another number. Who's next?",
        },
    },

    -- Hero-specific contextual lines
    hero_specific = {
        pudge = {
            "Hook missed. Hook hit. %s died. The Pudge algorithm: optimized.",
            "%s tried to hook me. I hooked their HP to zero instead.",
        },
        invoker = {
            "%s Sunstruck themselves. I just watched. Efficient.",
            "Invoker %s: 10 spells, 0 survival instincts. Deleted.",
        },
        anti_mage = {
            "Anti-Mage %s blinked in. Didn't blink out. Mana: 0. HP: 0.",
            "%s farmed for 40 minutes. I ended it in 2 seconds. AM logic.",
        },
        crystal_maiden = {
            "CM %s channeled ult. I cancelled it. Permanently.",
            "Freezing Field? More like Freezing Dead. %s eliminated.",
        },
        juggernaut = {
            "Jugg %s span to win. I spun their HP to zero. Blade Fury: denied.",
            "Omnislash on %s... wait, that was MY Omnislash. On them. Dead.",
        },
    },

    -- Chat wheel quick responses
    chat_wheel = {
        "Nice try.",
        "Calculated.",
        "Git gud?",
        "? (Question mark ping)",
        "Well played.",
        "Oops. My bad. Again.",
        "400 IQ play incoming.",
    },
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function HumanKillTaunts:DebugPrint(msg)
    if self.Config.DEBUG_MODE then
        print("[HumanKillTaunts] " .. msg)
    end
end

function HumanKillTaunts:GetRandomFromList(list, ...)
    if not list or #list == 0 then return nil end
    local msg = list[math.random(#list)]
    if #{...} > 0 then
        return string.format(msg, ...)
    end
    return msg
end

function HumanKillTaunts:FormatHeroName(hero)
    if not hero or hero:IsNull() then return "Unknown" end
    local name = hero:GetUnitName()
    -- Convert npc_dota_hero_antimage -> Anti-Mage
    name = name:gsub("npc_dota_hero_", "")
    name = name:gsub("_", " ")
    -- Capitalize words
    name = name:gsub("(%w+)", function(w) return w:sub(1,1):upper() .. w:sub(2) end)
    return name
end

function HumanKillTaunts:IsHumanPlayer(playerID)
    return PlayerResource:IsValidPlayer(playerID) 
        and not PlayerResource:IsFakeClient(playerID)
        and PlayerResource:GetConnectionState(playerID) ~= DOTA_CONNECTION_STATE_ABANDONED
end

function HumanKillTaunts:IsBotPlayer(playerID)
    return PlayerResource:IsValidPlayer(playerID) 
        and PlayerResource:IsFakeClient(playerID)
end

function HumanKillTaunts:GetBotPlayerID(hero)
    if not hero or hero:IsNull() then return nil end
    local playerID = hero:GetPlayerID()
    if playerID >= 0 and self:IsBotPlayer(playerID) then
        return playerID
    end
    return nil
end

-- ============================================================================
-- NET WORTH TRACKING (for comeback detection)
-- ============================================================================

function HumanKillTaunts:UpdateTeamNetWorth()
    local gameTime = GameRules:GetGameTime()
    if gameTime - self.State.lastNetWorthUpdate < 10.0 then return end -- throttle
    self.State.lastNetWorthUpdate = gameTime

    local radiantNW = 0
    local direNW = 0

    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                local nw = hero:GetNetWorth()
                if PlayerResource:GetTeam(i) == TEAM_RADIANT then
                    radiantNW = radiantNW + nw
                else
                    direNW = direNW + nw
                end
            end
        end
    end

    self.State.teamNetWorth[TEAM_RADIANT] = radiantNW
    self.State.teamNetWorth[TEAM_DIRE] = direNW
end

function HumanKillTaunts:IsComebackSituation(botTeam)
    self:UpdateTeamNetWorth()
    local ourNW = self.State.teamNetWorth[botTeam]
    local enemyTeam = (botTeam == TEAM_RADIANT) and TEAM_DIRE or TEAM_RADIANT
    local enemyNW = self.State.teamNetWorth[enemyTeam]
    
    return (enemyNW - ourNW) > self.Config.COMEBACK_GOLD_DEFICIT
end

-- ============================================================================
-- PAUSE FUNCTIONALITY
-- ============================================================================

function HumanKillTaunts:PauseGame(bot)
    if self.State.pauseActive then return false end
    
    local gameTime = GameRules:GetGameTime()
    self.State.gamePausedUntil = gameTime + self.Config.PAUSE_DURATION
    self.State.pauseActive = true
    
    GameRules:SetGamePaused(true)
    self:DebugPrint(string.format("Game paused for %.1f seconds after bot kill", self.Config.PAUSE_DURATION))
    
    -- Schedule unpause using timer
    Timers:CreateTimer(self.Config.PAUSE_DURATION, function()
        if GameRules:IsGamePaused() then
            GameRules:SetGamePaused(false)
            self.State.pauseActive = false
            self:DebugPrint("Game auto-unpaused after bot kill pause")
        end
        return nil
    end)
    
    return true
end

-- ============================================================================
-- MULTI-KILL DETECTION
-- ============================================================================

function HumanKillTaunts:RegisterKill(killerID, victimID, isBotKill, gameTime)
    table.insert(self.State.recentKills, {
        time = gameTime,
        killerID = killerID,
        victimID = victimID,
        isBotKill = isBotKill,
    })
    
    -- Clean old kills outside multi-kill window
    local cutoff = gameTime - self.Config.MULTI_KILL_WINDOW
    local newKills = {}
    for _, kill in ipairs(self.State.recentKills) do
        if kill.time >= cutoff then
            table.insert(newKills, kill)
        end
    end
    self.State.recentKills = newKills
end

function HumanKillTaunts:GetMultiKillCount(botPlayerID, gameTime)
    local count = 0
    local cutoff = gameTime - self.Config.MULTI_KILL_WINDOW
    for _, kill in ipairs(self.State.recentKills) do
        if kill.time >= cutoff and kill.killerID == botPlayerID and kill.isBotKill then
            count = count + 1
        end
    end
    return count
end

function HumanKillTaunts:GetMultiKillTier(count)
    if count >= 5 then return "rampage"
    elseif count >= 4 then return "ultra"
    elseif count >= 3 then return "triple"
    elseif count >= 2 then return "double"
    else return nil end
end

-- ============================================================================
-- SHUTDOWN DETECTION
-- ============================================================================

function HumanKillTaunts:GetHumanKillStreak(humanPlayerID)
    return self.State.humanKillStreaks[humanPlayerID] or 0
end

function HumanKillTaunts:OnHumanDeath(humanPlayerID)
    -- Reset human's kill streak when they die
    self.State.humanKillStreaks[humanPlayerID] = 0
end

function HumanKillTaunts:OnHumanKill(humanPlayerID)
    -- Increment human's kill streak when they kill
    self.State.humanKillStreaks[humanPlayerID] = (self.State.humanKillStreaks[humanPlayerID] or 0) + 1
end

function HumanKillTaunts:IsShutdown(humanPlayerID)
    local streak = self:GetHumanKillStreak(humanPlayerID)
    return streak >= self.Config.SHUTDOWN_THRESHOLD
end

-- ============================================================================
-- BOT KILL STREAK TRACKING
-- ============================================================================

function HumanKillTaunts:OnBotKill(botPlayerID)
    self.State.botKillStreaks[botPlayerID] = (self.State.botKillStreaks[botPlayerID] or 0) + 1
    return self.State.botKillStreaks[botPlayerID]
end

function HumanKillTaunts:OnBotDeath(botPlayerID)
    local oldStreak = self.State.botKillStreaks[botPlayerID] or 0
    self.State.botKillStreaks[botPlayerID] = 0
    return oldStreak
end

function HumanKillTaunts:GetBotKillStreak(botPlayerID)
    return self.State.botKillStreaks[botPlayerID] or 0
end

-- ============================================================================
-- TAUNT SELECTION LOGIC
-- ============================================================================

function HumanKillTaunts:SelectTaunt(bot, victim, gameTime, killContext)
    local victimName = self:FormatHeroName(victim)
    local botPlayerID = self:GetBotPlayerID(bot)
    local victimPlayerID = victim:GetPlayerID()
    
    -- Priority order for taunt selection
    
    -- 1. First blood
    if not self.State.firstBloodClaimed and killContext.isFirstBlood then
        self.State.firstBloodClaimed = true
        return self:GetRandomFromList(self.Taunts.first_blood, victimName), "first_blood"
    end
    
    -- 2. Multi-kill
    if botPlayerID then
        local multiKillCount = self:GetMultiKillCount(botPlayerID, gameTime)
        local tier = self:GetMultiKillTier(multiKillCount)
        if tier and self.Taunts.multi_kill[tier] then
            return self:GetRandomFromList(self.Taunts.multi_kill[tier], victimName), "multi_kill_" .. tier
        end
    end
    
    -- 3. Shutdown (victim was on kill streak)
    if victimPlayerID >= 0 and self:IsShutdown(victimPlayerID) then
        self:OnHumanDeath(victimPlayerID) -- Reset their streak
        return self:GetRandomFromList(self.Taunts.shutdown, victimName), "shutdown"
    end
    
    -- 4. Comeback context
    if killContext.isComeback then
        return self:GetRandomFromList(self.Taunts.comeback, victimName), "comeback"
    end
    
    -- 5. Bot's own kill streak milestones
    if botPlayerID then
        local streak = self:OnBotKill(botPlayerID)
        if self.Taunts.kill_streak[streak] then
            return self:GetRandomFromList(self.Taunts.kill_streak[streak], victimName), "kill_streak_" .. streak
        end
    end
    
    -- 6. Hero-specific
    local victimHeroName = victim:GetUnitName():lower()
    for heroKey, lines in pairs(self.Taunts.hero_specific) do
        if victimHeroName:find(heroKey) then
            return self:GetRandomFromList(lines, victimName), "hero_specific_" .. heroKey
        end
    end
    
    -- 7. Generic fallback
    return self:GetRandomFromList(self.Taunts.generic, victimName), "generic"
end

-- ============================================================================
-- MAIN ENTRY POINT - Called from init.lua CheckHumanKills
-- ============================================================================

function HumanKillTaunts:ProcessHumanKill(bot, victim, gameTime)
    local victimPlayerID = victim:GetPlayerID()
    local killer = victim:GetLastAttacker()
    local botPlayerID = self:GetBotPlayerID(bot)
    
    -- Verify this was a bot kill
    local isBotKill = false
    if killer and not killer:IsNull() then
        local killerPlayerID = killer:GetPlayerID()
        if killerPlayerID >= 0 and self:IsBotPlayer(killerPlayerID) then
            isBotKill = true
            botPlayerID = killerPlayerID
        end
    end
    
    if not isBotKill or not botPlayerID then
        return nil, nil
    end
    
    -- Check cooldown
    local lastKill = self.State.lastHumanKillTime[victimPlayerID] or 0
    if gameTime - lastKill < self.Config.TAUNT_COOLDOWN then
        return nil, "cooldown"
    end
    self.State.lastHumanKillTime[victimPlayerID] = gameTime
    
    -- Build kill context
    local killContext = {
        isFirstBlood = not self.State.firstBloodClaimed,
        isComeback = self:IsComebackSituation(bot:GetTeam()),
        isShutdown = victimPlayerID >= 0 and self:IsShutdown(victimPlayerID),
    }
    
    -- Register for multi-kill tracking
    self:RegisterKill(botPlayerID, victimPlayerID, true, gameTime)
    
    -- Handle victim's kill streak (they died, so reset it)
    if victimPlayerID >= 0 then
        self:OnHumanDeath(victimPlayerID)
    end
    
    -- Select and return taunt
    local taunt, category = self:SelectTaunt(bot, victim, gameTime, killContext)
    
    -- Trigger game pause
    self:PauseGame(bot)
    
    -- 10% chance for chat wheel
    local chatWheel = nil
    if math.random() < 0.1 then
        chatWheel = self:GetRandomFromList(self.Taunts.chat_wheel)
    end
    
    self:DebugPrint(string.format("Bot kill taunt: category=%s, pause=%.1fs", category or "none", self.Config.PAUSE_DURATION))
    
    return taunt, chatWheel
end

-- ============================================================================
-- PUBLIC API FOR INIT.LUA INTEGRATION
-- ============================================================================

-- Call this from init.lua's CheckHumanKills function
-- Returns: tauntMessage (string or nil), chatWheelMessage (string or nil)
function HumanKillTaunts:OnHumanKilledByBot(bot, gameTime)
    -- Check all enemy players for recent deaths
    local team = bot:GetTeam()
    
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= team then
            if not PlayerResource:IsFakeClient(i) then -- Human player
                local hero = PlayerResource:GetSelectedHeroEntity(i)
                if hero and not hero:IsNull() then
                    local respawnTime = hero:GetRespawnTime()
                    if respawnTime > 0 and respawnTime < 120 then -- Recently died (not buyback)
                        -- Verify this death hasn't been processed yet
                        local lastKill = self.State.lastHumanKillTime[i] or 0
                        if gameTime - lastKill > self.Config.TAUNT_COOLDOWN then
                            local taunt, chatWheel = self:ProcessHumanKill(bot, hero, gameTime)
                            return taunt, chatWheel
                        end
                    end
                end
            end
        end
    end
    
    return nil, nil
end

-- Call this periodically to track human kill streaks (when humans get kills)
function HumanKillTaunts:TrackHumanKillStreaks(gameTime)
    local botTeam = nil
    -- Find our bot's team
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:IsFakeClient(i) then
            botTeam = PlayerResource:GetTeam(i)
            break
        end
    end
    if not botTeam then return end
    
    local enemyTeam = (botTeam == TEAM_RADIANT) and TEAM_DIRE or TEAM_RADIANT
    
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) == enemyTeam then
            if not PlayerResource:IsFakeClient(i) then
                local hero = PlayerResource:GetSelectedHeroEntity(i)
                if hero and not hero:IsNull() and hero:IsAlive() then
                    -- Check if they recently got a kill (simplified: track via scoreboard changes)
                    -- This is a placeholder - full implementation would track kill events
                end
            end
        end
    end
end

-- Reset state (call on game start)
function HumanKillTaunts:Reset()
    self.State.lastHumanKillTime = {}
    self.State.botKillStreaks = {}
    self.State.humanKillStreaks = {}
    self.State.recentKills = {}
    self.State.firstBloodClaimed = false
    self.State.gamePausedUntil = 0
    self.State.pauseActive = false
    self.State.teamNetWorth = {
        [TEAM_RADIANT] = 0,
        [TEAM_DIRE] = 0,
    }
    self.State.lastNetWorthUpdate = 0
    self:DebugPrint("State reset")
end

-- ============================================================================
-- EXPORT
-- ============================================================================
return HumanKillTaunts