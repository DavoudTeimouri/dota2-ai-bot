# AetherWeaver

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dota 2](https://img.shields.io/badge/Dota_2-Workshop_Addon-green.svg)](https://www.dota2.com/workshop/)

A smart Dota 2 bot that plays like a pro, communicates via chat wheel and messages, hints to human players, and works as a team worker. No external dependencies — pure Lua Workshop addon.

## Features
- **Hero Selection**: Waits for human picks, then fills missing role and counters enemy lineup (falls back to POSITION_HEROES when GameRules unavailable).
- **Lane Assignment**: Assigns lane based on hero role with dynamic priority; can swap lanes when safer.
- **Per‑Hero Overrides**: Hero‑specific item builds, skill builds, and ability usage via `ability_item_usage_<hero>.lua` and `item_purchase_<hero>.lua` at the bot root.
- **Adaptive Items**: Full role‑based build order (starter → core → luxury) with shop gating (home/side/secret) and minGold thresholds.
- **Teamfight Positioning**: Simple retreat to nearest ally/tower when low HP and outnumbered.
- **Communication Pings**: Automatic missing‑enemy alerts and assist requests based on game state.
- **Vision Control**: Optimal ward placement considering rune times, gank paths, and depth (via `mode_ward_generic.lua`).
- **Behavioral Variance**: Occasional randomness to avoid predictability.
- **Mode‑Based Logic**: Eight modes that compete via GetDesire():
  - `mode_laning_generic.lua` – hold lane, last hit, do not feed
  - `mode_farm_generic.lua` – jungle and lane farming when laning is weak
  - `mode_ward_generic.lua` – place wards when safe
  - `mode_rune_generic.lua` – contest power runes around spawn windows
  - `mode_item_generic.lua` – walk to shop when next item is affordable
  - `mode_push_lane_generic.lua` – push lane with wave and numbers advantage
  - `mode_retreat_generic.lua` – disengage when low and outnumbered
  - `mode_team_roam_generic.lua` – join allied fights, focus fire
- **Phased Strategies**: Early farm/deny → mid‑game gank & tower pressure → late‑game Roshan & team fights.
- **Teamwork**: Shares vision hints, calls missing enemies, coordinates smoke ganks, buys courier upgrades, pulls/stacks jungle, heals/shields allies.
- **Team Fight**: Prioritizes targets (squishy > disable > carry), uses ability combos, positions safely, initiates/disengages as needed.
- **Supporting**: Buys wards, smoke, dust; pulls creep, stacks jungle; uses heal/shield items/abilities on allies.
- **Communicating & Guiding**: Sends contextual, funny, weighted chat messages and chat‑wheel hints.
- **Accept Human Orders**: Parses `!push <lane>`, `!roshan`, `!ward`, `!lane <lane>` in all‑chat and executes requested action.
- **Chat Wheels & Sprays**: Custom wheel slots for frequent hints; spray triggers on first blood, tower kill, Roshan kill.

## Bot Name
**AetherWeaver**

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
        ├── init.lua           # Bot entry point
        ├── game_intelligence.lua          # Core pick/ban, laning, farming, support, gank, push, teamfight, guidance
        ├── game_intelligence_extended.lua # Extended features: lane priority, adaptive items, teamfight positioning, communication pings, vision control, behavioral variance, economy sharing, hero micro, replay learning placeholder
        ├── ability_item_usage_generic.lua # Ability usage with hero override support
        ├── item_purchase_generic.lua      # Item purchase with hero override support
        ├── courier_generic.lua            # Stub (required by engine)
        ├── rune_generic.lua               # Stub (required by engine)
        ├── skill_build_generic.lua        # Stub (required by engine)
        ├── mode_farm_generic.lua          # Example mode‑based logic (farm)
        └── Customize/
            └── hero/
                └── antimage/
                    ├── antimage.lua       # Hero override: item/skill builds
                    └── ability.lua        # Hero override: ability usage
```

## How to Publish to Steam Workshop
1. **Clone or download** this repository
2. Open **Dota 2 Workshop Tools** (DLC required)
3. In the **Addon** panel, click **Publish** → select this folder
4. Fill in title ("AetherWeaver"), description, tags (dota2, ai, bot)
5. Set visibility to **Public** or **Friends Only**
6. Click **Upload**

## Chat Commands
| Command | Description |
|---------|-------------|
| `!push <lane>` | Push specified lane (top, mid, bot) |
| `!roshan` | Request Roshan attempt |
| `!ward` | Request ward placement |
| `!lane <lane>` | Override bot's lane assignment |

## Customizing the Bot
Edit `vscripts/bots/init.lua` to change:
- Hero pool and role mapping
- Message library (periodic messages)
- Chat command handling
- Strategy logic in `BotThink`

Edit hero‑specific overrides under `vscripts/bots/Customize/hero/<hero_name>/` to customize item builds, skill builds, and ability usage for any hero.

## Requirements
- Dota 2 with Workshop Tools DLC
- Dota 2 Beta (for custom lobbies with addons)

## License
MIT — see [LICENSE](LICENSE) for details.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security
See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.