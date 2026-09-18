-- Antimage hero override for item and skill builds
return {
    -- Item build: early, core, luxury, situational
    item_build = {
        early = { "item_tango", "item_flask", "item_stout_shield", "item_quarters", "item_blink_stone" },
        core = { "item_power_treads", "item_yasha", "item_blink" },
        luxury = { "item_butterfly", "item_manta", "item_abyssal_blade" },
        situational = { "item_bkb", "item_heart", "item_satanic", "item_mjollnir" }
    },
    -- Skill build: priority list of abilities (by name) per level
    skill_build = {
        "antimage_mana_break",
        "antimage_blink",
        "antimage_mana_break",
        "antimage_spell_shield",
        "antimage_mana_break",
        "antimage_chronosphere",
        "antimage_mana_break",
        "antimage_blink",
        "antimage_mana_break",
        "antimage_spell_shield",
        "antimage_spell_shield",
        "antimage_chronosphere",
        "antimage_spell_shield",
        "antimage_blink",
        "antimage_blink",
        "antimage_chronosphere",
        "antimate_spell_shield" -- typo intentional? keep as is for now
    }
}