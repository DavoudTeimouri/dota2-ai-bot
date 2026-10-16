# AetherWeaver

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dota 2](https://img.shields.io/badge/Dota_2-Workshop_Addon-green.svg)](https://www.dota2.com/workshop/)

A smart Dota 2 bot that plays like a pro, communicates via chat wheel and messages, hints to human players, and works as a team worker. No external dependencies — pure Lua Workshop addon. Synced to **Patch 7.41f**.

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
  - `mode_laning_generic.lua` – hold lane, last hit, deny, do not feed
  - `mode_farm_generic.lua` – jungle and lane farming when laning is weak
  - `mode_ward_generic.lua` – place wards at per‑lane spots when safe
  - `mode_rune_generic.lua` – contest power and bounty runes around spawn windows
  - `mode_item_generic.lua` – walk to shop when next item is affordable
  - `mode_push_lane_generic.lua` – push lane with wave and numbers advantage
  - `mode_retreat_generic.lua` – disengage when low and outnumbered
  - `mode_team_roam_generic.lua` – join allied fights, focus fire
- **Deny Logic**: Attacks own low‑HP creeps when no clean last hit is available, denying enemy gold and XP.
- **Rune Control**: Contests both power runes (2‑min cycle) and bounty runes (5‑min cycle) around spawn windows.
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
        ├── ability_item_usage_generic.lua   # Generic ability/item/buyback/level-up hooks
        ├── ability_item_usage_antimage.lua  # Anti‑Mage per‑hero override (example)
        ├── bot_generic.lua                  # Minion AI entry point (MinionThink only)
        ├── bot_names.lua                    # Human‑like name pool (EN/ZH/KO/RU/ES)
        ├── courier_generic.lua              # Courier usage hook (stash delivery)
        ├── hero_selection.lua               # Hero pick/ban phase (Think) + naming
        ├── init.lua                         # Message library + lane upkeep (BotThink)
        ├── item_purchase_generic.lua        # Generic item purchase hook with build orders
        ├── rune_generic.lua                 # Rune reset stub (required by engine)
        ├── skill_build_generic.lua          # Skill build hook (forwards to ability_item_usage)
        ├── team_desires.lua                 # Team‑level desire calculator + TeamThink executor
        ├── mode_farm_generic.lua            # Farm mode (neutral creeps + lane wave)
        ├── mode_item_generic.lua            # Item/shop mode (walk to shop when affordable)
        ├── mode_laning_generic.lua          # Laning mode (last hit + deny)
        ├── mode_push_lane_generic.lua       # Push mode (wave + numbers advantage)
        ├── mode_retreat_generic.lua         # Retreat mode (low HP + outnumbered)
        ├── mode_team_roam_generic.lua       # Team roam mode (join allied fights)
        ├── mode_ward_generic.lua            # Ward mode (per‑lane ward spots)
        └── mode_rune_generic.lua            # Rune mode (power + bounty runes)
```

## How to Publish to Steam Workshop
1. Clone or download this repository.
2. Open **Dota 2 Workshop Tools** (DLC required).
3. In the **Addon** panel, click **Publish** → select this folder.
4. Fill in title ("AetherWeaver"), description, tags (dota2, ai, bot).
5. Set visibility to **Public** or **Friends Only**.
6. Click **Upload**.

## Running the Bot Locally (without Workshop) and use for lobby
You can test the bot in a local lobby using the **Local DevScript** option:

1. Ensure you have Dota 2 Beta and enable cheats in lobby settings.
2. Place the entire `vscripts/bots` folder into a temporary location, e.g. `/tmp/dota2_bot/`.
3. In the lobby console, run:
   ```
   dota_launch_custom_game <map_name> -vscripts /tmp/dota2_bot
   ```
   (Replace `<map_name>` with a map like `empty` or use the workshop ID if needed.)
   Alternatively, after launching a cheat-enabled lobby, you can reload the script with:
   ```
   script_reload vscripts/bots/bot_generic.lua
   ```
   assuming the bot folder is mounted at `vscripts/` relative to the game.
4. The bot will load and you should see its name and initial chat messages.
5. Use `script_reload` to iterate on changes without restarting the lobby.

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

Edit hero‑specific overrides at the bot root (`ability_item_usage_<hero>.lua` and `item_purchase_<hero>.lua`) to customize item builds, skill builds, and ability usage for any hero.

## Requirements
- Dota 2 with Workshop Tools DLC
- Dota 2 Beta (for custom lobbies with addons)

## License
MIT — see [LICENSE](LICENSE) for details.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security
See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.