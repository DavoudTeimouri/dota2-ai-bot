-- Per-hero rules.
--
-- The generic ability handler needs two things it cannot work out on its
-- own: the order a hero should level its abilities in, and when its
-- ultimate is worth spending. Both are data, so they live here instead of
-- in one file per hero.
--
-- Hero names are the short form ("lina"), the same form SelectHero() wants.
-- The generic handler strips the "npc_dota_hero_" prefix before looking a
-- hero up, and falls back to the default behaviour for any hero that is not
-- listed here.

local HeroRules = {}

-- How an ultimate should be used.
--
--   always    global or team-wide: use it whenever a target is in range
--   initiate  needs a crowd: use it on two or more enemies
--   burst     use it on a target that is already low
--   defend    use it on an ally that is in danger
--   transform use it in a fight, any fight
--   dodge     use it to escape when the hero is low
HeroRules.ULT_RULES = {
    -- Carry: an escape or a finishing blow.
    antimage = "dodge",
    juggernaut = "burst",
    luna = "dodge",
    drow_ranger = "always",
    spectre = "transform",
    medusa = "always",
    terrorblade = "transform",
    morphling = "transform",
    faceless_void = "burst",
    phantom_assassin = "burst",
    templar_assassin = "burst",
    slardar = "initiate",
    void_spirit = "initiate",

    -- Mid: a spell burst or a fight starter.
    invoker = "burst",
    lina = "burst",
    zeus = "always",
    puck = "burst",
    storm_spirit = "always",
    ember_spirit = "initiate",
    queenofpain = "burst",
    shadow_fiend = "always",
    tinker = "burst",
    nevermore = "always",
    ringmaster = "burst",

    -- Offlane: fight starters and a team buff.
    axe = "initiate",
    centaur = "initiate",
    tidehunter = "initiate",
    mars = "initiate",
    beastmaster = "initiate",
    underlord = "initiate",
    primal_beast = "initiate",
    dragon_knight = "transform",
    bristleback = "initiate",
    timbersaw = "burst",
    doom_bringer = "always",
    dark_seer = "always",
    viper = "always",
    dawnbreaker = "initiate",
    necrolyte = "always",

    -- Support: save an ally, or start the fight.
    oracle = "defend",
    dazzle = "defend",
    abaddon = "defend",
    omniknight = "defend",
    ancient_apparition = "defend",
    witch_doctor = "always",
    lion = "burst",
    shadow_shaman = "initiate",
    crystal_maiden = "burst",
    lich = "always",
    pugna = "burst",
    ogre_magi = "burst",
    keeper_of_the_light = "always",
    jakiro = "always",
    bane = "defend",
    grimstroke = "burst",
    hoodwink = "burst",
    snapfire = "always",
    warlock = "always",
    rubick = "burst",
    meepo = "burst",
    arc_warden = "always",
    muerta = "always",
    treant = "initiate",
    undying = "dodge",

    -- Late additions to the pool.
    marci = "dodge",
    obsidian_destroyer = "burst",
    silencer = "always",
    skywrath_mage = "burst",

    -- Two heroes that are too new to know the ultimates of. "default" is
    -- the built-in rule: two or more enemies in range, or a low target.
    kez = "default",
    reaper = "default",
}

-- The order a hero should level its abilities in. Only listed where the
-- default (slot order) is wrong. A hero that is not listed, or an ability
-- that does not exist, falls back to the slot order.
HeroRules.LEVEL_ORDER = {
    antimage = {
        "antimage_mana_break", "antimage_blink",
        "antimage_counterspell", "antimage_chronosphere",
    },
    invoker = {
        "invoker_quas", "invoker_wex", "invoker_exort", "invoker_invoke",
    },
    zeus = {
        "zeus_lightning_bolt", "zeus_arc_lightning",
        "zeus_static_field", "zeus_thundergods_wrath",
    },
    puck = {
        "puck_phase_shift", "puck_illusion_staff",
        "puck_waning_rune", "puck_dream_coil",
    },
    faceless_void = {
        "faceless_void_time_walk", "faceless_void_time_dilation",
        "faceless_void_chronosphere",
    },
    lion = {
        "lion_mana_drain", "lion_earth_spike",
        "lion_hex", "lion_finger_of_death",
    },
    ogre_magi = {
        "ogre_magi_fireblast", "ogre_magi_ignite",
        "ogre_magi_shapers_wrath", "ogre_magi_multicast",
    },
    crystal_maiden = {
        "crystal_maiden_crystal_nova", "crystal_maiden_frostbite",
        "crystal_maiden_arcane_orb", "crystal_maiden_freezing_field",
    },
    lich = {
        "lich_frost_bolt", "lich_ring_of_frost",
        "lich_arcane_orb", "lich_chain_frost",
    },
    bane = {
        "bane_enfeeble", "bane_brain_sap",
        "bane_nightmare", "bane_fiends_grip",
    },
}

-- Strip the unit-name prefix: "npc_dota_hero_lina" -> "lina".
function HeroRules.ShortName(unitName)
    if not unitName then return nil end
    return (unitName:gsub("^npc_dota_hero_", ""))
end

-- The rules for a hero, or nil when the hero is not listed.
function HeroRules.For(unitName)
    local short = HeroRules.ShortName(unitName)
    if not short then return nil end
    if not HeroRules.ULT_RULES[short] and not HeroRules.LEVEL_ORDER[short] then
        return nil
    end
    return {
        ult = HeroRules.ULT_RULES[short],
        level = HeroRules.LEVEL_ORDER[short],
    }
end

return HeroRules
