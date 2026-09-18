-- Bot Names: English + Persian (human-like)
local BotNames = {}

BotNames.radiant = {
    -- English
    "Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Avery", "Quinn",
    "Blake", "Drew", "Peyton", "Reese", "Rowan", "Sage", "Skyler", "Dakota",
    "River", "Phoenix", "Nova", "Orion", "Atlas", "Juno", "Kai", "Zion",
    -- Persian (transliterated)
    "Aria", "Dara", "Nika", "Sina", "Tara", "Yara", "Kian", "Mina",
    "Arash", "Baran", "Donya", "Eli", "Fara", "Giti", "Hana", "Iliya",
    "Jahan", "Kaveh", "Laleh", "Mehr", "Nava", "Omid", "Pari", "Raha",
    "Saba", "Taha", "Vana", "Yas", "Ziba", "Amin", "Bahar", "Cyrus",
    "Dana", "Ehsan", "Farhad", "Golnar", "Homa", "Iman", "Jasmin", "Kamran",
    "Leila", "Mahsa", "Nader", "Omid", "Parisa", "Ramin", "Sahar", "Tina",
}

BotNames.dire = {
    -- English
    "Sam", "Charlie", "Finley", "Harper", "Jesse", "Kendall", "Lennon", "Marley",
    "Noel", "Oakley", "Presley", "Quincy", "Remington", "Sawyer", "Tatum", "Winter",
    "Zion", "Amari", "Bowie", "Cleo", "Dallas", "Ellis", "Finnegan", "Gray",
    "Haven", "Indigo", "Jude", "Koa", "Lux", "Marlowe", "Navy", "Onyx",
    -- Persian (transliterated)
    "Amin", "Bahar", "Cyrus", "Dana", "Ehsan", "Farhad", "Golnar", "Homa",
    "Iman", "Jasmin", "Kamran", "Leila", "Mahsa", "Nader", "Omid", "Parisa",
    "Ramin", "Sahar", "Tina", "Vida", "Yasmin", "Zahra", "Arman", "Bita",
    "Caspian", "Donya", "Elham", "Farzad", "Ghazal", "Hana", "Iraj", "Javad",
    "Kourosh", "Laleh", "Maziar", "Narges", "Omid", "Pedram", "Roya", "Soroush",
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