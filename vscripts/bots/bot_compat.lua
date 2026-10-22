-- AetherWeaver bot API compatibility layer.
--
-- The Dota 2 bot scripting API has shipped in several shapes, and the
-- community reference does not cover every method. Rather than bet on one
-- spelling, every uncertain call goes through this module, which tries the
-- documented form first and falls back to the alternative.
--
-- Confirmed from the API reference:
--   bot:GetNearbyHeroes(nRadius, bEnemies, nMode)   -- pass BOT_MODE_NONE
--   bot:GetNearbyLaneCreeps(nRadius, bEnemies)
--   bot:GetNearbyNeutralCreeps(nRadius)
--   bot:GetLocation()
--   bot:GetItemInSlot(nSlot)
--   bot:AttackTarget(hUnit)
--
-- Used by the standard bot scripts but absent from that reference:
--   bot:GetNearbyEnemyHeroes(nRadius, bVisibleOnly)
--   bot:GetNearbyAlliedHeroes(nRadius)
--   bot:GetAbsOrigin()
--   bot:HasItem(sName)
--   bot:SetBotName(sName)
--   bot:GetRole()
--   bot:GetAvailableWards()
--   bot:GetPushingWaves(nRadius)
--   bot:GetNearbyNeutralCamps(nRadius)
--
-- Every wrapper degrades to "nothing found" or "no change" instead of
-- raising, so a missing method can never freeze a bot.

local Compat = {}

-- Bot mode filter meaning "all heroes", whatever the VM calls it.
local MODE_ALL = _G.BOT_MODE_NONE or 0

-- Enemy heroes within radius. Sorted by distance, closest first.
function Compat.Enemies(bot, radius)
    if not bot or bot:IsNull() then return {} end

    if bot.GetNearbyEnemyHeroes then
        return bot:GetNearbyEnemyHeroes(radius, true) or {}
    end
    if bot.GetNearbyHeroes then
        return bot:GetNearbyHeroes(radius, true, MODE_ALL) or {}
    end
    return {}
end

-- Allied heroes within radius.
function Compat.Allies(bot, radius)
    if not bot or bot:IsNull() then return {} end

    if bot.GetNearbyAlliedHeroes then
        return bot:GetNearbyAlliedHeroes(radius) or {}
    end
    if bot.GetNearbyHeroes then
        return bot:GetNearbyHeroes(radius, false, MODE_ALL) or {}
    end
    return {}
end

-- World position of a unit (bot, creep, enemy).
function Compat.Position(unit)
    if not unit then return nil end
    if unit.GetAbsOrigin then
        local p = unit:GetAbsOrigin()
        if p then return p end
    end
    if unit.GetLocation then
        local p = unit:GetLocation()
        if p then return p end
    end
    return nil
end

-- Does the bot hold this item? Falls back to scanning the inventory.
function Compat.HasItem(bot, name)
    if not bot or bot:IsNull() then return false end
    if bot.HasItem then
        return bot:HasItem(name) and true or false
    end
    if bot.GetItemInSlot then
        for s = 0, 8 do
            local it = bot:GetItemInSlot(s)
            if it and not it:IsNull() and it:GetName() == name then
                return true
            end
        end
    end
    return false
end

-- How many copies of an item the bot holds.
function Compat.CountItem(bot, name)
    if not bot or bot:IsNull() then return 0 end
    if not bot.GetItemInSlot then
        return (Compat.HasItem(bot, name)) and 1 or 0
    end
    local n = 0
    for s = 0, 8 do
        local it = bot:GetItemInSlot(s)
        if it and not it:IsNull() and it:GetName() == name then
            n = n + 1
        end
    end
    return n
end

-- Ability in a slot. The API documents GetAbilityInSlot(0-23); the older
-- bot scripts use GetAbilityByIndex(i).
function Compat.AbilityInSlot(bot, slot)
    if not bot or bot:IsNull() then return nil end
    if bot.GetAbilityInSlot then
        return bot:GetAbilityInSlot(slot)
    end
    if bot.GetAbilityByIndex then
        return bot:GetAbilityByIndex(slot)
    end
    return nil
end

-- Slot index of an item, or -1 when the bot does not hold it.
function Compat.ItemSlot(bot, name)
    if not bot or bot:IsNull() then return -1 end
    if bot.FindItemSlot then
        local ok, slot = pcall(bot.FindItemSlot, bot, name)
        if ok and slot then return slot end
    end
    if bot.GetItemInSlot then
        for s = 0, 8 do
            local it = bot:GetItemInSlot(s)
            if it and not it:IsNull() and it:GetName() == name then
                return s
            end
        end
    end
    return -1
end

-- Item handle by name, or nil when the bot does not hold it.
function Compat.ItemByName(bot, name)
    if not bot or bot:IsNull() then return nil end
    if not bot.GetItemInSlot then return nil end
    for s = 0, 8 do
        local it = bot:GetItemInSlot(s)
        if it and not it:IsNull() and it:GetName() == name then
            return it
        end
    end
    return nil
end

-- Give the bot a human-like name. Silent if the VM does not support it.
function Compat.SetName(bot, name)
    if not bot or bot:IsNull() then return false end
    if bot.SetBotName then
        bot:SetBotName(name)
        return true
    end
    return false
end

-- Order an attack on a unit. Action_AttackUnit is the documented form;
-- AttackTarget is the older spelling.
function Compat.Attack(bot, unit)
    if not bot or bot:IsNull() or not unit then return false end
    if bot.Action_AttackUnit then
        bot:Action_AttackUnit(unit)
        return true
    end
    if bot.AttackTarget then
        bot:AttackTarget(unit)
        return true
    end
    return false
end

-- Order an attack-move towards a location.
function Compat.AttackMove(bot, location)
    if not bot or bot:IsNull() or not location then return false end
    if bot.Action_AttackMove then
        bot:Action_AttackMove(location)
        return true
    end
    return false
end

-- Level up an ability.
-- The API reference documents ActionImmediate_LevelAbility(sAbilityName),
-- which takes the ability NAME string. Older scripts use
-- ActionImmediate_LevelUpAbility(hAbility), which takes the handle.
function Compat.LevelAbility(bot, ability)
    if not bot or bot:IsNull() or not ability then return false end

    if bot.ActionImmediate_LevelAbility then
        local name = nil
        if ability.GetName then
            local ok, n = pcall(ability.GetName, ability)
            if ok then name = n end
        end
        if name then
            local ok = pcall(bot.ActionImmediate_LevelAbility, bot, name)
            if ok then return true end
        end
    end

    if bot.ActionImmediate_LevelUpAbility then
        local ok = pcall(bot.ActionImmediate_LevelUpAbility, bot, ability)
        if ok then return true end
    end
    return false
end

-- Walk to a location. Action_MoveToLocation pathfinds; Action_MoveDirectly
-- goes in a straight line and gets stuck on terrain.
function Compat.MoveTo(bot, location)
    if not bot or bot:IsNull() or not location then return false end
    if bot.Action_MoveToLocation then
        bot:Action_MoveToLocation(location)
        return true
    end
    if bot.Action_MoveDirectly then
        bot:Action_MoveDirectly(location)
        return true
    end
    return false
end

-- Cast an ability. The target kind decides the variant:
--   nil       -> Action_UseAbility (no target)
--   unit      -> Action_UseAbilityOnEntity
--   location  -> Action_UseAbilityOnLocation
function Compat.UseAbility(bot, ability, target)
    if not bot or bot:IsNull() or not ability then return false end

    if target == nil then
        if bot.Action_UseAbility then
            bot:Action_UseAbility(ability)
            return true
        end
        return false
    end

    -- A unit handle has GetHealth (and usually IsNull); a location is a plain
    -- table with x and y.
    if target.GetHealth or target.IsNull then
        if bot.Action_UseAbilityOnEntity then
            bot:Action_UseAbilityOnEntity(ability, target)
            return true
        end
        return false
    end

    if bot.Action_UseAbilityOnLocation then
        bot:Action_UseAbilityOnLocation(ability, target)
        return true
    end
    return false
end

-- Neutral creeps within radius.
function Compat.NeutralCreeps(bot, radius)
    if not bot or bot:IsNull() then return {} end
    if bot.GetNearbyNeutralCreeps then
        return bot:GetNearbyNeutralCreeps(radius) or {}
    end
    if bot.GetNearbyNeutralCamps then
        return bot:GetNearbyNeutralCamps(radius) or {}
    end
    return {}
end

-- How many wards the bot can still place.
function Compat.AvailableWards(bot)
    if not bot or bot:IsNull() then return 0 end
    if bot.GetAvailableWards then
        return bot:GetAvailableWards() or 0
    end
    return 0
end

-- Creep waves the bot is pushing.
function Compat.PushingWaves(bot, radius)
    if not bot or bot:IsNull() then return {} end
    if bot.GetPushingWaves then
        return bot:GetPushingWaves(radius) or {}
    end
    return {}
end

-- The bot's role, or nil when the VM does not expose it.
function Compat.Role(bot)
    if not bot or bot:IsNull() then return nil end
    if bot.GetRole then
        return bot:GetRole()
    end
    return nil
end

-- The neutral item the bot picked up, or nil. The API documents slot 16 as
-- the neutral item slot.
function Compat.NeutralItem(bot)
    if not bot or bot:IsNull() then return nil end
    if not bot.GetItemInSlot then return nil end
    local ok, item = pcall(bot.GetItemInSlot, bot, 16)
    if not ok or not item then return nil end
    if item.IsNull and item:IsNull() then return nil end
    return item
end

-- Position along the lane: 0 = your ancient, 1 = the enemy ancient.
function Compat.LaneAmount(bot)
    if not bot or bot:IsNull() then return 0.5 end
    if bot.GetAmountAlongLane and bot.GetAssignedLane then
        local lane = bot:GetAssignedLane()
        local ok, amount = pcall(bot.GetAmountAlongLane, bot, lane)
        if ok and amount then return amount end
    end
    return 0.5
end

return Compat