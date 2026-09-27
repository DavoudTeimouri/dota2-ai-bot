-- AetherWeaver Rune Generic
-- Workshop addon: vscripts/bots/rune_generic.lua
-- Handles rune assignment and usage logic with per-bot distribution

local RuneGeneric = {}

-- Track assigned bots per rune spot
RuneGeneric.assignedBots = {}
RuneGeneric.lastRuneCheck = 0
RuneGeneric.RUNE_CHECK_INTERVAL = 1.0

-- Rune spot names
local RUNE_SPOTS = {
    POWERUP_1 = "powerup_1",
    POWERUP_2 = "powerup_2",
    BOUNTY_1 = "bounty_1",
    BOUNTY_2 = "bounty_2",
    BOUNTY_3 = "bounty_3",
    BOUNTY_4 = "bounty_4",
    WISDOM = "wisdom",
}

-- Get nearby runes
function RuneGeneric:GetNearbyRunes(bot, range)
    range = range or 5000
    local runes = {}
    for _, spotName in pairs(RUNE_SPOTS) do
        local rune = GetRune(spotName)
        if rune and not rune:IsNull() then
            local dist = (bot:GetLocation() - rune:GetLocation()):Length2D()
            if dist <= range then
                table.insert(runes, {spot = spotName, rune = rune, distance = dist})
            end
        end
    end
    table.sort(runes, function(a, b) return a.distance < b.distance end)
    return runes
end

-- Check if bot is assigned to a rune
function RuneGeneric:IsAssignedToRune(bot, spotName)
    return self.assignedBots[spotName] == bot
end

-- Assign bot to rune
function RuneGeneric:AssignBotToRune(bot, spotName)
    -- Unassign from any other rune
    for spot, assignedBot in pairs(self.assignedBots) do
        if assignedBot == bot then
            self.assignedBots[spot] = nil
        end
    end
    self.assignedBots[spotName] = bot
end

-- Unassign bot from rune
function RuneGeneric:UnassignBotFromRune(bot)
    for spot, assignedBot in pairs(self.assignedBots) do
        if assignedBot == bot then
            self.assignedBots[spot] = nil
        end
    end
end

-- Get best rune for bot based on role and situation
function RuneGeneric:GetBestRuneForBot(bot)
    local runes = self:GetNearbyRunes(bot)
    if #runes == 0 then return nil end
    
    local gameTime = GameRules:GetGameTime()
    local minutes = math.floor(gameTime / 60)
    local seconds = gameTime % 60
    local role = bot:GetRole() or "carry"
    local isMid = bot:GetAssignedLane() == "mid"
    
    -- Power runes (even minutes 0:00-0:30) -> mid priority
    local isPowerRuneTime = (minutes % 2 == 0) and (seconds < 30)
    
    -- Bounty runes (every 5 minutes, first 15 seconds) -> distributed
    local isBountyRuneTime = (minutes % 5 == 0) and (seconds < 15)
    
    -- Wisdom runes (post-Roshan, 20min+) -> contested
    local isWisdomTime = gameTime > 1200
    
    for _, runeInfo in ipairs(runes) do
        local spot = runeInfo.spot
        local rune = runeInfo.rune
        local runeType = rune:GetRuneType()
        
        -- Skip if already assigned to another bot
        if self.assignedBots[spot] and self.assignedBots[spot] ~= bot then
            -- Check if assigned bot is too far or dead
            local assigned = self.assignedBots[spot]
            if assigned:IsNull() or not assigned:IsAlive() or 
               (assigned:GetLocation() - rune:GetLocation()):Length2D() > 3000 then
                self.assignedBots[spot] = nil
            else
                goto continue
            end
        end
        
        -- Power rune logic
        if runeType == RUNE_DOUBLEDAMAGE or runeType == RUNE_HASTE or 
           runeType == RUNE_ILLUSION or runeType == RUNE_REGENERATION or 
           runeType == RUNE_ARCANE then
            if isMid or isPowerRuneTime then
                return runeInfo
            end
        end
        
        -- Bounty rune logic - distribute among team
        if runeType == RUNE_BOUNTY then
            if not isMid then -- Non-mid get priority for bounty
                return runeInfo
            end
        end
        
        -- Wisdom rune - contest if ahead or need levels
        if runeType == RUNE_WISDOM then
            if isWisdomTime and bot:GetLevel() < 25 then
                return runeInfo
            end
        end
        
        ::continue::
    end
    
    -- Fallback: closest unassigned rune
    for _, runeInfo in ipairs(runes) do
        if not self.assignedBots[runeInfo.spot] then
            return runeInfo
        end
    end
    
    return nil
end

-- Engine hook: RuneUsageThink
function RuneUsageThink()
    return nil -- We handle rune logic in bot's main think
end

-- Main think function called from init.lua
function RuneGeneric:Think(bot)
    local gameTime = GameRules:GetGameTime()
    
    -- Throttle
    if gameTime - self.lastRuneCheck < self.RUNE_CHECK_INTERVAL then
        return
    end
    self.lastRuneCheck = gameTime
    
    local runeInfo = self:GetBestRuneForBot(bot)
    if runeInfo then
        self:AssignBotToRune(bot, runeInfo.spot)
        bot:MoveToPosition(runeInfo.rune:GetLocation())
        return true
    end
    
    -- Unassign if no rune to go for
    self:UnassignBotFromRune(bot)
    return false
end

-- Reset state
function RuneGeneric:Reset()
    self.assignedBots = {}
    self.lastRuneCheck = 0
end

return RuneGeneric