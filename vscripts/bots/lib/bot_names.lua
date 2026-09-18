-- Bot Names: English only (human-like)
local BotNames = {}

BotNames.radiant = {
    "Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Avery", "Quinn",
    "Blake", "Drew", "Peyton", "Reese", "Rowan", "Sage", "Skyler", "Dakota",
    "River", "Phoenix", "Nova", "Orion", "Atlas", "Juno", "Kai", "Zion",
    "Sam", "Charlie", "Finley", "Harper", "Jesse", "Kendall", "Lennon", "Marley",
    "Noel", "Oakley", "Presley", "Quincy", "Remington", "Sawyer", "Tatum", "Winter",
    "Amari", "Bowie", "Cleo", "Dallas", "Ellis", "Finnegan", "Gray",
    "Haven", "Indigo", "Jude", "Koa", "Lux", "Marlowe", "Navy", "Onyx",
    "Arden", "Bailey", "Cameron", "Devon", "Emery", "Frankie", "Gale", "Hayden",
    "Inari", "Journey", "Kirby", "Larkin", "Micah", "Nico", "Ocean", "Parker",
    "Quill", "Remy", "Shiloh", "Tristan", "Umbra", "Vesper", "Wynn", "Xander",
    "Yael", "Zephyr"
}

BotNames.dire = {
    "Sam", "Charlie", "Finley", "Harper", "Jesse", "Kendall", "Lennon", "Marley",
    "Noel", "Oakley", "Presley", "Quincy", "Remington", "Sawyer", "Tatum", "Winter",
    "Zion", "Amari", "Bowie", "Cleo", "Dallas", "Ellis", "Finnegan", "Gray",
    "Haven", "Indigo", "Jude", "Koa", "Lux", "Marlowe", "Navy", "Onyx",
    "Arden", "Bailey", "Cameron", "Devon", "Emery", "Frankie", "Gale", "Hayden",
    "Inari", "Journey", "Kirby", "Larkin", "Micah", "Nico", "Ocean", "Parker",
    "Quill", "Remy", "Shiloh", "Tristan", "Umbra", "Vesper", "Wynn", "Xander",
    "Yael", "Zephyr",
    "Atlas", "Juno", "Kai", "Nova", "Orion", "Phoenix", "River", "Sage",
    "Rowan", "Reese", "Peyton", "Drew", "Blake", "Quinn", "Avery", "Riley",
    "Casey", "Morgan", "Taylor", "Jordan", "Alex"
}

BotNames.all = {}
for _, name in ipairs(BotNames.radiant) do table.insert(BotNames.all, name) end
for _, name in ipairs(BotNames.dire) do table.insert(BotNames.all, name) end

function BotNames:GetRandom(team)
    local list = (team == DOTA_TEAM_GOODGUYS) and BotNames.radiant or BotNames.dire
    return list[math.random(#list)]
end

function BotNames:GetAnyRandom()
    return BotNames.all[math.random(#BotNames.all)]
end

return BotNames