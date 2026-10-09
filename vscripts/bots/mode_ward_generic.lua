-- Ward mode: plant vision where it pays off.
--
-- Engine contract: GetDesire runs every frame for every mode; nil falls back
-- to Valve's desire. A support with no wards must return nil (not 0) so
-- Valve's built-in warding takes over instead of leaving the bot passive.
local function HasObserver(bot)
    return bot:HasItem("item_ward_observer") or bot:HasItem("item_ward_sentry")
end

function GetDesire()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return 0 end

    -- Only wards with something to plant.
    if not HasObserver(bot) then return nil end

    -- Very low HP: warding gets you killed, retreat should win.
    if bot:GetHealth() < bot:GetMaxHealth() * 0.35 then return 0 end

    local desire = 0.5

    -- Carry/mid have better things to do than sitting on sentries.
    local role = bot:GetRole()
    if role == "carry" then desire = 0.2
    elseif role == "mid" then desire = 0.3 end

    -- Standing in fountain with spare wards is a good time to place them.
    if bot:DistanceFromFountain() == 0 then desire = desire + 0.2 end

    -- If enemies are visible nearby, fight mode should win.
    if #bot:GetNearbyEnemyHeroes(1200, true) > 0 then
        desire = desire - 0.3
    end

    if desire <= 0 then return nil end
    return desire
end

-- Resolve a ward handle by scanning the inventory; slot 6 is not guaranteed.
local function FindWard(bot)
    for s = 0, 8 do
        local it = bot:GetItemInSlot(s)
        if it and not it:IsNull() then
            local name = it:GetName()
            if name == "item_ward_observer" or name == "item_ward_sentry" then
                return it
            end
        end
    end
    return nil
end

function Think()
    local bot = GetBot()
    if not bot or bot:IsNull() or not bot:IsAlive() then return end

    local ward = FindWard(bot)
    if not ward then return end

    -- Prefer the lane we are assigned to: stand forward and cover the approach.
    local lane = bot:GetAssignedLane() or "safe"
    local pos = GetLaneFrontLocation(GetTeam(), lane, 250)
    if pos then
        bot:Action_UseAbilityOnLocation(ward, pos)
    end
end