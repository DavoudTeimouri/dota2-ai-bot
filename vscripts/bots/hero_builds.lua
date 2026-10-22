-- Per-hero item builds.
--
-- The role builds in item_purchase_generic.lua are the default and are
-- correct for most heroes. A hero whose role build is materially wrong for
-- it gets an entry here: an early Manta for a carry that wants to fight,
-- Aghanim's Scepter and a Meteor Hammer for a mage that wants to burst,
-- a Black King Bar for an offlane that has to survive.
--
-- The gold number in each entry is only a fallback. When the VM exposes
-- GetItemCost() the live price is used instead, and the same for the shop
-- through IsItemPurchasedFromSecretShop()/IsItemPurchasedFromSideShop().
--
-- A hero that is not listed here uses its role build.

local HeroBuilds = {}

-- Pos 1: carry. The role build buys Power Treads and a Butterfly, which is
-- too slow for a hero that has to fight early.
HeroBuilds.antimage = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_black_king_bar", 5100, "side" },
    { "item_butterfly",     2100, "side"  },
    { "item_daedalus",      5100, "side"  },
}
HeroBuilds.juggernaut = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_daedalus",      5100, "side"  },
    { "item_black_king_bar", 5100, "side" },
    { "item_butterfly",     2100, "side"  },
}
HeroBuilds.phantom_assassin = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_black_king_bar", 5100, "side" },
    { "item_butterfly",     2100, "side"  },
}
HeroBuilds.spectre = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_radiance",      4700, "side"  },
    { "item_butterfly",     2100, "side"  },
    { "item_daedalus",      5100, "side"  },
}
HeroBuilds.medusa = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_daedalus",      5100, "side"  },
    { "item_butterfly",     2100, "side"  },
}
HeroBuilds.drow_ranger = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_daedalus",      5100, "side"  },
    { "item_butterfly",     2100, "side"  },
    { "item_black_king_bar", 5100, "side" },
}
HeroBuilds.luna = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_daedalus",      5100, "side"  },
    { "item_butterfly",     2100, "side"  },
}
HeroBuilds.terrorblade = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_black_king_bar", 5100, "side" },
    { "item_butterfly",     2100, "side"  },
    { "item_daedalus",      5100, "side"  },
}
HeroBuilds.morphling = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_linken_sphere", 2100, "side"  },
    { "item_butterfly",     2100, "side"  },
    { "item_daedalus",      5100, "side"  },
}
HeroBuilds.faceless_void = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_tango",         90,  "home"  },
    { "item_black_king_bar", 5100, "side" },
    { "item_butterfly",     2100, "side"  },
    { "item_daedalus",      5100, "side"  },
}
HeroBuilds.slardar = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_tango",         90,  "home"  },
    { "item_blink",         2250, "side"  },
    { "item_black_king_bar", 5100, "side" },
    { "item_butterfly",     2100, "side"  },
    { "item_daedalus",      5100, "side"  },
}
HeroBuilds.void_spirit = {
    { "item_tango",         90,  "home"  },
    { "item_fairy_flare",   180, "home"  },
    { "item_tango",         90,  "home"  },
    { "item_manta_style",   4900, "side"  },
    { "item_black_king_bar", 5100, "side" },
    { "item_butterfly",     2100, "side"  },
}

-- Pos 2: mid. The role build ends in a Sheepstick; a mage wants Aghanim's
-- Scepter and something to burst with.
HeroBuilds.invoker = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_blink",           2250, "side"  },
}
HeroBuilds.zeus = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_arcane_blink",    7000, "side"  },
}
HeroBuilds.puck = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_blink",           2250, "side"  },
}
HeroBuilds.storm_spirit = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_scythe_of_vyse",  5600, "side"  },
}
HeroBuilds.queenofpain = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_blink",           2250, "side"  },
}
HeroBuilds.shadow_fiend = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_sheepstick",      1800, "side"  },
}
HeroBuilds.tinker = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_sheepstick",      1800, "side"  },
}
HeroBuilds.ember_spirit = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_blink",           2250, "side"  },
}
HeroBuilds.necrolyte = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
}
HeroBuilds.silencer = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_sheepstick",      1800, "side"  },
}
HeroBuilds.skywrath_mage = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
}
HeroBuilds.templar_assassin = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_null_talisman",   40,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_blink",           2250, "side"  },
}

-- Pos 3: offlane. The role build buys Branches and a Bravado, which is a
-- support's item. An offlane needs to survive the lane.
HeroBuilds.axe = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_blink",           2250, "side"  },
    { "item_black_king_bar",  5100, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_bravado",         1800, "side"  },
}
HeroBuilds.tidehunter = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_blink",           2250, "side"  },
    { "item_black_king_bar",  5100, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_bravado",         1800, "side"  },
}
HeroBuilds.centaur = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_blink",           2250, "side"  },
    { "item_black_king_bar",  5100, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.beastmaster = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_blink",           2250, "side"  },
    { "item_black_king_bar",  5100, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.mars = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_blink",           2250, "side"  },
    { "item_meteor_hammer",   7800, "side"  },
    { "item_black_king_bar",  5100, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.dragon_knight = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_blink",           2250, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_meteor_hammer",   7800, "side"  },
}
HeroBuilds.bristleback = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_black_king_bar",  5100, "side"  },
    { "item_vanguard",        2200, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.timbersaw = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_blink",           2250, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_shiv",            2700, "side"  },
}
HeroBuilds.underlord = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_arcana",          1900, "side"  },
    { "item_guardian_greaves", 1500, "side" },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.doom_bringer = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_black_king_bar",  5100, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_bravado",         1800, "side"  },
}
HeroBuilds.primal_beast = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_blink",           2250, "side"  },
    { "item_black_king_bar",  5100, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.viper = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_manta_style",     4900, "side"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_bravado",         1800, "side"  },
}
HeroBuilds.dark_seer = {
    { "item_tango",           90,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_cyclone",         2200, "side"  },
}

-- Pos 4 and 5: support. The role build ends in a Ghost Scepter and a
-- Medallion of Courage; most supports want Aghanim's Scepter and an aura
-- item for the carry.
HeroBuilds.oracle = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_glimmer_cape",    1800, "side"  },
}
HeroBuilds.dazzle = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.lion = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_force_staff",     2300, "side"  },
}
HeroBuilds.witch_doctor = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_force_staff",     2300, "side"  },
}
HeroBuilds.lich = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.ogre_magi = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_force_staff",     2300, "side"  },
}
HeroBuilds.keeper_of_the_light = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.jakiro = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.bane = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.abaddon = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.omniknight = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.warlock = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.grimstroke = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.hoodwink = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.snapfire = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.arc_warden = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
}
HeroBuilds.crystal_maiden = {
    { "item_tango",           90,   "home"  },
    { "item_ward_observer",   50,   "home"  },
    { "item_tango",           90,   "home"  },
    { "item_fairy_flare",     180,  "home"  },
    { "item_ward_sentry",     50,   "home"  },
    { "item_aghanims_scepter", 4200, "secret" },
    { "item_ghost_scepter",   1500, "side"  },
}

-- Strip the unit-name prefix and look the hero up.
function HeroBuilds.For(unitName)
    if not unitName then return nil end
    local short = string.lower(unitName)
    short = string.gsub(short, "^npc_dota_hero_", "")
    return HeroBuilds[short]
end

return HeroBuilds
