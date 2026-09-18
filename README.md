# AetherWeaver

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dota 2](https://img.shields.io/badge/Dota_2-Workshop_Addon-green.svg)](https://www.dota2.com/workshop/)

A smart Dota 2 bot that plays like a pro, communicates via chat wheel and messages, hints to human players, and works as a team worker. No external dependencies — pure Lua Workshop addon.

## Features
- **Hero Selection**: Waits for human picks, then fills missing role and counters enemy lineup
- **Lane Assignment**: Assigns lane based on hero role (carry→safe, mid→mid, offlaner→offlane, support→jungle/rune) with dynamic priority using hero matchup and missing enemy data
- **Hero Override System**: Per‑hero item builds, skill builds, and ability usage logic via `Customize/hero/<hero_name>/`
- **Adaptive Items**: Item builds adjust to enemy team composition (magic/physical damage, disables, healing)
- **Teamfight Positioning**: Evaluates enemy threat and suggests safe retreat zones behind allies and towers
- **Communication Pings**: Automatic missing‑enemy alerts and assist requests based on game state
- **Vision Control**: Optimal ward placement considering rune times, gank paths, and depth
- **Behavioral Variance**: Occasional randomness to avoid predictability
- **Mode‑Based Logic**: Example farm mode (`mode_farm_generic.lua`) for clean state‑based behavior
- **Phased Strategies**: Early farm/deny → mid‑game gank & tower pressure → late‑game Roshan & team fights
- **Teamwork**: Shares vision hints, calls missing enemies, coordinates smoke ganks, buys courier upgrades, pulls/stacks jungle, heals/shields allies
- **Team Fight**: Prioritizes targets (squishy > disable > carry), uses ability combos, positions safely, initiates/disengages as needed
- **Supporting**: Buys wards, smoke, dust; pulls creep, stacks jungle; uses heal/shield items/abilities on allies
- **Communicating & Guiding**: Sends contextual, funny, weighted chat messages and chat‑wheel hints
- **Accept Human Orders**: Parses `!push <lane>`, `!roshan`, `!ward`, `!lane <lane>` in all‑chat and executes requested action
- **Chat Wheels & Sprays**: Custom wheel slots for frequent hints; spray triggers on first blood, tower kill, Roshan kill

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

## How to Use in Dota 2 (Local Test – No Workshop Needed)
You can test the bot locally without uploading to the Workshop:
1. **Clone or download** this repository
2. Locate your Steam library folder (default: `C:\Program Files (x86)\Steam\steamapps\` or a custom library path)
3. Ensure you have opted into the Dota 2 Beta:
   - Steam → Library → right‑click **Dota 2** → Properties → **Betas** tab → select the beta update (usually “beta”)
4. Copy the `aetherweaver` folder (the repository root) to:
   ```
   <SteamLibrary>\steamapps\common\dota 2 beta\game\dota_addons\aetherweaver\
   ```
   The folder must contain exactly the files listed above (no extra files/folders).
5. Launch **Dota 2 Beta**
6. **Play → Create Lobby**
   - Game Mode: *All Pick* (or any you like)
   - **Enable Cheats** – tick this box
   - (The “Addons” checkbox may be missing in some UI versions; the game still loads addons from the folder)
7. Click **Start Lobby**, then **Launch Game**
8. Open the console (back‑tick key `` ` ``) and look for lines like:
   ```
   [AetherWeaver] Activating...
   [AetherWeaver] Initialized
   [AetherWeaver] I will play npc_dota_hero_antimage in the safe lane.
   ```
9. Test orders in **all‑chat** (press Enter, type command, hit Enter):
   - `!push mid` → Bot replies “Pushing mid lane!” and moves toward the mid lane
   - `!roshan` → “Let's go Roshan!” → groups toward the Rosh pit
   - `!ward` → “Warding suggested.” → attempts to place wards
   - `!lane top` → “Setting lane top” → switches assigned lane
10. If you see Lua errors in the console, edit the corresponding `.lua` file, save it, then type `dota_reload_scripts` in the console (or restart the lobby) to reload the scripts.
11. When everything works, the bot will farm, pull/stack camps at :15‑:17/:45‑:47/:53‑:55, place wards on rune spots (even minutes), attempt smoke ganks, join team fights, and respond to your orders.
12. Share the `aetherweaver` folder with others—they can copy it into their own `...\dota 2 beta\game\dota_addons\` folder and use it in a cheat‑enabled local lobby—**no Steam Workshop upload required**.

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

## Related Topics
- [Agency Agents](https://hermes-agent.nousresearch.com/docs/skills/agency-agents) – used to consult specialists for this project
- [Game Designer specialist](https://hermes-agent.nousresearch.com/docs/skills/game-designer) – provided core mechanics and balancing advice
- [Technical Writer specialist](https://hermes-agent.nousresearch.com/docs/skills/technical-writer) – helped author this README

## License
MIT — see [LICENSE](LICENSE) for details.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security
See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.