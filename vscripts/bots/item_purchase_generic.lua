-- Item Purchase System for AetherWeaver
-- Loads per-hero build from BotLib or Customize/hero

local ItemPurchase = {}

function ItemPurchase:Initialize(bot)
    if not bot or bot:IsNull() or not bot:IsHero() or bot:IsIllusion() then
        return false
    end
    
    local heroName = bot:GetUnitName()
    if not heroName or not string.find(heroName, "hero") then
        return false
    end
    
    -- Try to load from Customize/hero first (user overrides)
    local customizePath = "bots/Customize/hero/" .. string.gsub(heroName, "npc_dota_hero_", "") .. ".lua"
    local ok, customBuild = pcall(dofile, customizePath)
    if ok and customBuild and customBuild.sBuyList then
        bot.itemBuild = customBuild.sBuyList
        bot.sellList = customBuild.sSellList or {}
        return true
    end
    
    -- Fallback to BotLib (built-in builds)
    local botlibPath = "bots/BotLib/" .. string.gsub(heroName, "npc_dota_hero_", "") .. ".lua"
    ok, customBuild = pcall(dofile, botlibPath)
    if ok and customBuild and customBuild.sBuyList then
        bot.itemBuild = customBuild.sBuyList
        bot.sellList = customBuild.sSellList or {}
        return true
    end
    
    -- Final fallback: generic role-based build
    bot.itemBuild = self:GetGenericBuild(bot)
    bot.sellList = {}
    return true
end

function ItemPurchase:GetGenericBuild(bot)
    local role = self:GetBotRole(bot)
    local builds = {
        carry = {
            "item_tango", "item_flask", "item_quelling_blade", "item_branches", "item_branches", "item_branches",
            "item_wraith_band", "item_power_treads", "item_bfury", "item_manta", "item_butterfly",
            "item_satanic", "item_skadi", "item_abyssal_blade", "item_moon_shard"
        },
        mid = {
            "item_tango", "item_flask", "item_mantle", "item_branches", "item_branches", "item_branches",
            "item_wraith_band", "item_power_treads", "item_oblivion_staff", "item_ultimate_orb",
            "item_sheepstick", "item_black_king_bar", "item_shivas_guard", "item_octarine_core"
        },
        offlane = {
            "item_tango", "item_flask", "item_stout_shield", "item_branches", "item_branches",
            "item_bracer", "item_phase_boots", "item_blink", "item_pipe", "item_crimson_guard",
            "item_shivas_guard", "item_heart", "item_refresher"
        },
        support = {
            "item_tango", "item_flask", "item_mantle", "item_branches", "item_branches",
            "item_boots", "item_magic_wand", "item_tranquil_boots", "item_glimmer_cape",
            "item_force_staff", "item_aeon_disk", "item_lotus_orb", "item_guardian_greaves"
        }
    }
    return builds[role] or builds.carry
end

function ItemPurchase:GetBotRole(bot)
    local heroName = bot:GetUnitName()
    local carryHeroes = {"antimage", "juggernaut", "phantom_assassin", "spectre", "medusa", "drow_ranger", "luna", "faceless_void", "terrorblade", "morphling"}
    local midHeroes = {"invoker", "storm_spirit", "templar_assassin", "puck", "ember_spirit", "queenofpain", "shadow_fiend", "zeus", "tinker", "pugna"}
    local offlaneHeroes = {"centaur", "tidehunter", "dragon_knight", "axe", "mars", "underlord", "dark_seer", "bristleback", "timbersaw", "slardar"}
    
    for _, h in ipairs(carryHeroes) do
        if heroName:find(h) then return "carry" end
    end
    for _, h in ipairs(midHeroes) do
        if heroName:find(h) then return "mid" end
    end
    for _, h in ipairs(offlaneHeroes) do
        if heroName:find(h) then return "offlane" end
    end
    return "support"
end

function ItemPurchase:Think(bot)
    if not bot or bot:IsNull() or not bot:IsAlive() then return end
    
    if not bot.itemBuild then
        self:Initialize(bot)
        if not bot.itemBuild then return end
    end
    
    local currentTime = DotaTime()
    if currentTime < 0 then return end
    
    -- Buy items from build list
    if #bot.itemBuild > 0 then
        local nextItem = bot.itemBuild[1]
        if bot:GetGold() >= GetItemCost(nextItem) then
            bot:ActionImmediate_PurchaseItem(nextItem)
            table.remove(bot.itemBuild, 1)
        end
    end
    
    -- Handle selling items
    if bot.sellList and #bot.sellList > 0 then
        for _, sellItem in ipairs(bot.sellList) do
            if bot:FindItemSlot(sellItem) >= 0 and bot:GetGold() < GetItemCost(bot.itemBuild[1] or "") then
                bot:ActionImmediate_SellItem(sellItem)
            end
        end
    end
    
    -- Buy TP scrolls
    if not bot:HasItem("item_tpscroll") and bot:GetGold() >= 50 and currentTime > 60 then
        bot:ActionImmediate_PurchaseItem("item_tpscroll")
    end
    
    -- Buy wards if support
    if self:GetBotRole(bot) == "support" then
        if not bot:HasItem("item_observer") and bot:GetGold() >= 50 then
            bot:ActionImmediate_PurchaseItem("item_observer")
        end
        if not bot:HasItem("item_sentry") and bot:GetGold() >= 50 then
            bot:ActionImmediate_PurchaseItem("item_sentry")
        end
    end
end

return ItemPurchase