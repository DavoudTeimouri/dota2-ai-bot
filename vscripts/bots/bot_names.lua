-- AetherWeaver Bot Names
-- Workshop addon: vscripts/bots/bot_names.lua
-- Provides human-like names for bots

local BotNames = {}

-- English names
BotNames.english = {
    "Shadow", "Phantom", "Specter", "Wraith", "Revenant",
    "Viper", "Cobra", "Python", "Mamba", "Adder",
    "Raven", "Crow", "Hawk", "Falcon", "Eagle",
    "Blade", "Edge", "Razor", "Steel", "Iron",
    "Storm", "Thunder", "Lightning", "Gale", "Tempest",
    "Frost", "Ice", "Glacier", "Blizzard", "Hail",
    "Flame", "Ember", "Ash", "Cinder", "Spark",
    "Void", "Abyss", "Nexus", "Core", "Zenith",
    "Hunter", "Stalker", "Predator", "Tracker", "Scout",
    "Guardian", "Sentinel", "Warden", "Keeper", "Watchman",
}

-- Chinese names
BotNames.chinese = {
    "影", "幽灵", "幻影", "死神", "收割者",
    "毒蛇", "眼镜蛇", "蟒蛇", "黑曼巴", "蝰蛇",
    "渡鸦", "乌鸦", "苍鹰", "猎鹰", "雄鹰",
    "刀锋", "利刃", "剃刀", "钢铁", "铁甲",
    "风暴", "雷霆", "闪电", "狂风", "暴风",
    "寒冰", "冰霜", "冰川", "暴雪", "冰雹",
    "烈焰", "余烬", "灰烬", "火星", "火花",
    "虚空", "深渊", "枢纽", "核心", "顶点",
    "猎手", "追踪者", "掠食者", "侦察兵", "斥候",
    "守护者", "哨兵", "典狱长", "看门人", "守夜人",
}

-- Korean names
BotNames.korean = {
    "그림자", "유령", "환영", "사신", "수확자",
    "독사", "코브라", "비단뱀", "블랙맘바", "살모사",
    "까마귀", "까치", "매", "송골매", "독수리",
    "칼날", "날카로움", "면도날", "강철", "철갑",
    "폭풍", "천둥", "번개", "돌풍", "태풍",
    "서리", "얼음", "빙하", "눈보라", "우박",
    "불꽃", "잉걸", "재", "티끌", "불씨",
    "공허", "심연", "연결점", "핵심", "정점",
    "사냥꾼", "추적자", "포식자", "정찰병", "척후병",
    "수호자", "파수꾼", "간수", "지키미", "야경꾼",
}

-- Russian names
BotNames.russian = {
    "Тень", "Призрак", "Фантом", "Сборщик", "Мститель",
    "Змея", "Кобра", "Удав", "Мамба", "Гадюка",
    "Ворон", "Грач", "Ястреб", "Сокол", "Орел",
    "Лезвие", "Острие", "Бритва", "Сталь", "Железо",
    "Буря", "Гром", "Молния", "Шторм", "Ураган",
    "Мороз", "Лёд", "Ледник", "Метель", "Град",
    "Пламя", "Уголь", "Пепел", "Искра", "Огонёк",
    "Пустота", "Бездна", "Связь", "Ядро", "Вершина",
    "Охотник", "Следопыт", "Хищник", "Разведчик", "Следопыт",
    "Страж", "Часовой", "Надзиратель", "Хранитель", "Ночной Дозор",
}

-- Spanish names
BotNames.spanish = {
    "Sombra", "Fantasma", "Espectro", "Segador", "Aparición",
    "Víbora", "Cobra", "Pitón", "Mamba", "Cascabel",
    "Cuervo", "Gräjo", "Halcón", "Falcón", "Águila",
    "Hoja", "Filo", "Navaja", "Acero", "Hierro",
    "Tormenta", "Trueno", "Relámpago", "Vendaval", "Tempestad",
    "Escarcha", "Hielo", "Glaciar", "Ventisca", "Granizo",
    "Llama", "Brasa", "Ceniza", "Chispa", "Resplandor",
    "Vacío", "Abismo", "Nexo", "Núcleo", "Cénit",
    "Cazador", "Acechador", "Depredador", "Rastreador", "Explorador",
    "Guardián", "Centella", "Celador", "Vigía", "Vigilante",
}

-- All names combined
-- NOTE: iterate a snapshot of the language keys. Iterating BotNames directly
-- while inserting into BotNames.all re-hashes the table and the loop keeps
-- hitting the still-growing `all` key forever -- bot_names.lua never finished
-- loading, which hung init.lua and left every bot frozen.
local languages = {}
for key, list in pairs(BotNames) do
    if key ~= "all" and type(list) == "table" then
        languages[#languages + 1] = list
    end
end

BotNames.all = {}
for _, list in ipairs(languages) do
    for _, name in ipairs(list) do
        BotNames.all[#BotNames.all + 1] = name
    end
end

-- Get random name
function BotNames:GetRandom()
    return self.all[math.random(#self.all)]
end

-- Get random name for team (Radiant/Dire)
function BotNames:GetForTeam(team)
    return self:GetRandom()
end

-- Reset state
function BotNames:Reset()
    -- Nothing to reset for names
end

-- Set bot name (called during hero selection)
function BotNames:SetBotName(bot, team)
    local name = self:GetForTeam(team)
    if bot and not bot:IsNull() then
        bot:SetBotName(name)
    end
    return name
end

return BotNames