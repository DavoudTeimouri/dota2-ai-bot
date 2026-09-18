-- Item purchase logic with hero override support
local M = {}

local function LoadHeroOverride(heroName)
    local overridePath = string.format("Customize/hero/%s.lua", string.lower(heroName))
    local status, override = pcall(require, overridePath)
    if status and override then
        return override
    end
    return nil
end

function M.PurchaseItem(bot)
    local heroName = bot:GetUnitName()
    local override = LoadHeroOverride(heroName)
    local build = override and override.item_build or {
        early = { "item_tango", "item_flask", "item_stout_shield", "item_quarters" },
        core = { "item_power_treads", "item_yasha", "item_blink" },
        luxury = { "item_butterfly", "item_manta", "item_abyssal_blade" },
        situational = { "item_bkb", "item_heart", "item_satanic", "item_mjollnir" }
    }

    -- Determine what to buy based on gold and current items
    local gold = bot:GetGold()
    local items = {}
    for i = 0, 8 do
        local item = bot:GetItemInSlot(i)
        if item ~= nil then
            table.insert(items, item:GetName())
        end
    end

    -- Simple buy logic: buy earliest missing item we can afford
    local function CanBuy(itemName)
        local cost = GetItemCost(itemName)
        return cost ~= nil and gold >= cost
    end

    -- Check early, then core, then luxury, then situational
    for _, phase in ipairs({ "early", "core", "luxury", "situational" }) do
        for _, itemName in ipairs(build[phase]) do
            if not HasItem(items, itemName) and CanBuy(itemName) then
                bot:ActionImmediate_PurchaseItem(itemName)
                return
            end
        end
    end
end

-- Helper functions
function HasItem(itemList, itemName)
    for _, name in ipairs(itemList) do
        if name == itemName then return true end
    end
    return false
end

function GetItemCost(itemName)
    -- Dota 2 does not expose item cost via API; we approximate or ignore.
    -- For simplicity, we assume we can buy if we have enough gold.
    -- In practice, you'd need a table or rely on bot's ability to purchase.
    return 0  -- placeholder
end

return M