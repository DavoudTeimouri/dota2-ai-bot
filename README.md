# AetherWeaver

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dota 2](https://img.shields.io/badge/Dota_2-Workshop_Addon-green.svg)](https://www.dota2.com/workshop/)

A smart Dota 2 bot that plays like a pro, communicates via chat wheel and messages, hints to human players, and works as a team worker. No external dependencies — pure Lua Workshop addon.

**Updated for Dota 2 Patch 7.41f (TI 2026)**

## Features

- **Hero Selection**: Waits for human picks, then fills missing role and counters enemy lineup
- **Lane Assignment**: Assigns lane based on hero role (carry→safe, mid→mid, offlaner→offlane, support→jungle/rune)
- **Phased Strategies**: Early farm/deny → mid-game gank & tower pressure → late-game Roshan & team fights
- **Teamwork**: Shares vision hints, calls missing enemies, coordinates smoke ganks, buys courier upgrades, pulls/stacks jungle, heals/shields allies
- **Team Fight**: Prioritizes targets (squishy > disable > carry), uses ability combos, positions safely, initiates/disengages as needed
- **Supporting**: Buys wards, smoke, dust; pulls creep, stacks jungle; uses heal/shield items/abilities on allies
- **Communicating & Guiding**: Sends contextual, funny, weighted chat messages and chat-wheel hints
- **Accept Human Orders**: Parses `!push <lane>`, `!roshan`, `!ward`, `!lane <lane>` in all-chat and executes requested action
- **Chat Wheels & Sprays**: Custom wheel slots for frequent hints; spray triggers on first blood, tower kill, Roshan kill
- **Hero Override System**: Customize hero behavior via `Customize/hero/` directory
- **Lane Priority**: Dynamic lane assignment based on game state and hero suitability
- **Adaptive Items**: Item builds adapt to enemy lineup and game state
- **Teamfight Positioning**: Optimal positioning during team fights to maximize impact and safety
- **Communication Pings**: Uses pings to communicate with team (missing enemy, danger, on my way)
- **Vision Control**: Strategic ward placement and dewarding for map control
- **Behavioral Variance**: Introduces randomized behavior to avoid predictability
- **Enhanced Item and Ability Usage**: Hero-override support in `item_purchase_generic.lua` and `ability_item_usage_generic.lua`
- **Human-like Bot Names**: English + Persian names for Radiant and Dire
- **Per-Hero Skill/Item Builds**: 128+ heroes supported via BotLib with Customize/hero overrides
- **Patch 7.41f Integration**: Automatic item cost/stat adjustments, hero nerf/buff playstyle adaptations
- **High-Voted Guide Integration**: Pre-cached STRATZ/Dotabuff meta builds per role (Pos 1-5)

## Bot Names

Bots use human-like names in English and Persian (transliterated):

**Radiant**: Alex, Jordan, Taylor, Morgan, Casey, Riley, Avery, Quinn, Blake, Drew, Peyton, Reese, Rowan, Sage, Skyler, Dakota, River, Phoenix, Nova, Orion, Atlas, Juno, Kai, Zion, Aria, Dara, Nika, Sina, Tara, Yara, Kian, Mina, Arash, Baran, Donya, Eli, Fara, Giti, Hana, Iliya, Jahan, Kaveh, Laleh, Mehr, Nava, Omid, Pari, Raha, Saba, Taha, Vana, Yas, Ziba, Amin, Bahar, Cyrus, Dana, Ehsan, Farhad, Golnar, Homa, Iman, Jasmin, Kamran, Leila, Mahsa, Nader, Parisa, Ramin, Sahar, Tina

**Dire**: Sam, Charlie, Finley, Harper, Jesse, Kendall, Lennon, Marley, Noel, Oakley, Presley, Quincy, Remington, Sawyer, Tatum, Winter, Zion, Amari, Bowie, Cleo, Dallas, Ellis, Finnegan, Gray, Haven, Indigo, Jude, Koa, Lux, Marlowe, Navy, Onyx, Amin, Bahar, Cyrus, Dana, Ehsan, Farhad, Golnar, Homa, Iman, Jasmin, Kamran, Leila, Mahsa, Nader, Omid, Parisa, Ramin, Sahar, Tina, Vida, Yasmin, Zahra, Arman, Bita, Caspian, Donya, Elham, Farzad, Ghazal, Hana, Iraj, Javad, Kourosh, Laleh, Maziar, Narges, Omid, Pedram, Roya, Soroush

## Files

```
dota2-ai-bot/
├── addoninfo.txt              # Workshop metadata
├── LICENSE                    # MIT License
├── CONTRIBUTING.md            # Contribution guidelines
├── CODE_OF_CONDUCT.md         # Code of Conduct
├── SECURITY.md                # Security policy
├── README.md                  # This file
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   └── bug_report.yml     # Bug report template
│   └── PULL_REQUEST_TEMPLATE.md
└── vscripts/
    └── bots/
        ├── BotLib/                    # Built-in per-hero builds (128+ heroes)
        │   ├── hero_antimage.lua
        │   ├── hero_crystal_maiden.lua
        │   ├── hero_invoker.lua
        │   ├── hero_pudge.lua
        │   ├── hero_techies.lua
        │   ├── hero_meepo.lua
        │   ├── hero_template.lua      # Template for new heroes
        │   └── ... (128 total)
        ├── Customize/
        │   └── hero/                   # Hero-specific overrides (user-editable)
        │       ├── antimage.lua
        │       ├── crystal_maiden.lua
        │       └── ...
        ├── ability_item_usage_generic.lua   # Ability + item usage with hero override + patch adjustments
        ├── bot_names.lua                   # Human-like bot names (EN + FA)
        ├── courier_generic.lua
        ├── game_intelligence.lua           # Core game intelligence modules
        ├── game_intelligence_extended.lua  # Extended features (blink dodge, vision, etc.)
        ├── guide_integration.lua           # High-voted guide builds per role (STRATZ/Dotabuff)
        ├── init.lua                        # Main entry point
        ├── item_purchase_generic.lua       # Item purchasing with guide/BotLib/customize fallback + patch costs
        ├── patch_741f.lua                  # Patch 7.41f item/hero adjustments
        ├── rune_generic.lua                # Rune control logic
        └── skill_build_generic.lua         # Skill leveling with guide/BotLib/customize fallback
```

## How to Use in Dota 2

1. **Subscribe** to the Workshop addon (or use local copy)
2. Create a **custom lobby** in Dota 2 Beta
3. Enable the **AetherWeaver** addon in the lobby settings
4. Launch the game — the bot will auto-join, pick a hero after human picks, and start playing

## Local Testing (Without Workshop)

To test the bot without uploading to Steam Workshop:

1. Clone the repository.
2. Copy the `vscripts` folder to your Dota 2 beta game directory:
   `steamapps/common/Dota 2 Beta/game/dota_addons/AetherWeaver`
3. Launch Dota 2 Beta, create a custom lobby, and enable the AetherWeaver addon.
4. The bot will run as if subscribed from Workshop.

## Chat Commands

| Command | Description |
|---------|-------------|
| `!push <lane>` | Push specified lane (top, mid, bot) |
| `!roshan` | Request Roshan attempt |
| `!ward` | Request ward placement |
| `!lane <lane>` | Override bot's lane assignment |

## Patch 7.41f Integration

The bot automatically applies Patch 7.41f changes (live since Sep 15, 2026):

### Item Cost Changes
- **Daedalus**: 5,100 → 5,200 gold
- **Dragon Lance**: 1,900 → 2,000 gold (affects Hurricane Pike: 4,450 → 4,550)
- **Heart of Tarrasque**: 5,200 → 5,300 gold
- **Octarine Core**: 4,900 → 5,100 gold
- **Heaven's Halberd**: 3,400 → 3,300 gold
- **Hydra's Breath**: Recipe 1,100 → 1,000 (total unchanged at 5,900)

### Item Stat Changes
- **Manta Style**: Ranged illusion damage 28% → 25%
- **Mask of Madness**: Lifesteal 24% → 22%
- **Satanic**: Lifesteal bonus 30% → 25%
- **Infused Raindrops**: Mana regen 0.8 → 0.6
- **Essence Distiller**: Mana regen 1.75 → 1.5
- **Battle Fury**: Chop Tree CD 4s → 3s
- **Shiva's Guard**: Arctic Blast damage 260 → 225
- **Silver Edge**: Shadow Walk CD increased, MS bonus reduced

### Hero Adjustments (Auto-applied playstyle changes)
- **Anti-Mage** ✅: Mana Break damage 60% → 65% (more aggressive)
- **Treant Protector** ⚠️: Base Int 20→17, Leech Seed costs 35 mana, Living Armor min block 20→10, Nature's Guise linger 2s→1s (conserve mana)
- **Shadow Fiend** ⚠️: Shadowraze dmg/soul 3→2, Necromastery scaling changed (need more souls)
- **Bounty Hunter** ⚠️: Track self gold 130/225/320 → 80/160/240 (Track for vision, not gold)
- **Invoker** ⚠️: Cold Snap CD 19s, Ghost Walk Shard no creep damage (conserve Cold Snap)
- **Lina** ⚠️: Base Int 28, Fiery Soul AS/duration reduced
- **Winter Wyvern** ⚠️: Arctic Burn CD increased, Cold Embrace early heal reduced
- **Centaur** ⚠️: Base dmg -2, MS 300→295
- **Earth Spirit** ⚠️: Base AS 100→95, Stone Remnant charges slower, talent swap L20/25
- **Mirana, Kez, Hoodwink** ⚠️: Various nerfs
- **Huskar, Ursa, Mars, Chen, Warlock, Largo** ✅: Buffs/adjustments

## Guide Integration (STRATZ/Dotabuff)

The bot loads high-voted community guide builds per role:

### Build Priority Chain
1. **GuideIntegration** (highest voted STRATZ/Dotabuff builds, patch-adjusted)
2. **Customize/hero/** (your personal overrides — survives Workshop updates)
3. **BotLib/** (128 built-in hero builds from OpenHyperAI)
4. **Generic** (role-based fallback)

### Supported Heroes (Pre-cached)
- **Pos 1 (Carry)**: Anti-Mage, Juggernaut, PA, Spectre, Medusa, Drow, Luna, Void, TB, Morphling, Sven, Lifestealer, WK, Alchemist
- **Pos 2 (Mid)**: Invoker, Storm, TA, Puck, Ember, QoP, SF, Zeus, Tinker, Pugna, Lina
- **Pos 3 (Offlane)**: Centaur, Tide, DK, Axe, Mars, Underlord, Dark Seer, Bristleback, Timber, Slardar
- **Pos 4 (Roam)**: Earth Spirit, Pangolier, Mirana, Nyx, BH, Techies, Void Spirit, Dawnbreaker, Marci, Primal Beast
- **Pos 5 (Support)**: CM, Lich, WD, Shadow Shaman, Lion, Dazzle, Oracle, Undying, AA, Snapfire, Grimstroke, Willow, Muerta, Ringmaster

### Updating Guides
Run the external Python script (see `guide_integration.lua` comments) to fetch latest STRATZ GraphQL data and update the cached builds.

## Customizing the Bot

### Hero Overrides (Recommended)

Create Lua files in `vscripts/bots/Customize/hero/` named after the hero (e.g., `antimage.lua`). These override BotLib builds and survive Workshop updates.

Example structure:
```lua
local X = {}

X.sSkillList = { "ability_1", "ability_2", ... }
X.sBuyList = { "item_tango", "item_power_treads", ... }
X.sSellList = { "item_to_sell", ... }
X.bDeafaultAbility = false
X.bDeafaultItem = false

function X.SkillsComplement()
    -- Hero-specific ability logic
end

function X.MinionThink(hMinionUnit)
    -- Illusion/minion control
end

return X
```

### Built-in Hero Builds (BotLib)

128+ heroes have pre-configured skill builds, item builds, and ability logic in `vscripts/bots/BotLib/`. Copy from OpenHyperAI or create your own using `hero_template.lua`.

### Core Behavior

Edit `vscripts/bots/init.lua` to change:
- Hero pool and role mapping
- Message library
- Chat command handling
- Strategy logic in `BotThink`

## Architecture

- **init.lua**: Main bot think loop, initializes all subsystems
- **BotLib/**: 128+ per-hero builds (skills, items, ability logic)
- **Customize/hero/**: User overrides (takes priority over BotLib)
- **guide_integration.lua**: Pre-cached STRATZ/Dotabuff builds per role (Pos 1-5)
- **patch_741f.lua**: Patch 7.41f item cost/stat changes, hero playstyle adjustments
- **game_intelligence.lua**: Pick/ban, lanes, farming, support, teamfight, gank, push, guidance
- **game_intelligence_extended.lua**: Creep equilibrium, lane priority, adaptive items, teamfight positioning, communication pings, offline RL, blink dodge, economy sharing, vision control, behavioral variance
- **item_purchase_generic.lua**: Loads build from Guide → Customize → BotLib → generic fallback; uses patch-adjusted costs
- **ability_item_usage_generic.lua**: Loads ability logic from Customize → BotLib → generic fallback; applies patch adjustments
- **skill_build_generic.lua**: Loads skill build from Guide → Customize → BotLib → generic fallback
- **courier_generic.lua**: Courier upgrade + delivery
- **rune_generic.lua**: Rune control (bounty, power runes)
- **bot_names.lua**: 100+ human-like names (English + Persian)

## Requirements

- Dota 2 with Workshop Tools DLC
- Dota 2 Beta (for custom lobbies with addons)

## License

MIT — see [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.