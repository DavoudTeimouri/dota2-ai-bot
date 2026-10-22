# AetherWeaver

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dota 2](https://img.shields.io/badge/Dota_2-Workshop_Addon-green.svg)](https://www.dota2.com/workshop/)

A smart Dota 2 bot that plays like a pro, communicates via chat wheel and messages, hints to human players, and works as a team worker. No external dependencies — pure Lua Workshop addon. Synced to **Patch 7.41f**.

## Features
What the bot actually does today. Every line is backed by code in `vscripts/bots/`.

- **Hero Selection**: Position‑based hero pools with attribute filtering and counter‑pick weights (`hero_selection.lua`). Runs during pick/ban when the game exposes `GameRules`; otherwise Valve's own selection runs and the bot still gets its custom name.
- **Custom Bot Names**: Human‑like names from a 250‑name pool across EN/ZH/KO/RU/ES, assigned in `hero_selection.lua` so they apply in every game phase.
- **Lane Assignment**: Role‑based lane with the correct per‑team safe/offlane mapping. Lanes use the API's int constants (`LANE_TOP/MID/BOT`), normalised through `bot_lane.lua`.
- **Eight Competing Modes**: The engine calls `GetDesire()` every frame in each `mode_*_generic.lua` and runs the highest one:
  - `mode_laning_generic.lua` – hold lane, last hit, deny own dying creeps
  - `mode_farm_generic.lua` – neutral creeps (tiered) and lane wave
  - `mode_ward_generic.lua` – place wards at per‑lane spots, nearest first
  - `mode_rune_generic.lua` – contest power (2‑min) and bounty (5‑min) runes
  - `mode_item_generic.lua` – walk to the shop when the next item is affordable
  - `mode_push_lane_generic.lua` – push with a big wave and a numbers advantage
  - `mode_retreat_generic.lua` – disengage when hurt and outnumbered
  - `mode_team_roam_generic.lua` – join allied fights, focus the lowest‑HP enemy
- **Item Purchases**: Full per‑role build order (starter → core → luxury) with per‑item shop gating (home/side/secret) and gold thresholds. Repeated items (two tangos, three wards) are counted properly, so the bot buys every copy.
- **Ability Usage**: Picks the best castable ability and the best target (closest + lowest HP) each frame.
- **Item Active Usage**: Dust and smoke are cast on self (no target), Orchid of Malevolence on an enemy.
- **Skill Levelling**: Unspent ability points are spent as they appear.
- **Buyback**: Bought when dead and gold covers the cost.
- **Courier**: Picks up stashed starting items once.
- **Chat**: Contextual periodic messages (greeting, chit‑chat every 15s, a timed line every 60s) sent with `bot:ActionImmediate_Chat`. Team‑only; the bot VM cannot tell humans from bots.
- **Per‑Hero Overrides**: Hero‑specific ability and skill logic via `ability_item_usage_<hero>.lua` at the bot root (see `ability_item_usage_antimage.lua`).

### Not implemented
These are not in the code, and the bot scripting VM cannot support them without a server plugin:
- **Chat commands** (`!push`, `!roshan`, `!ward`, `!lane`). The bot VM has no `player_chat` event and no `GameRules:SendCustomMessage`, so a bot cannot read player chat. The only chat API is `ActionImmediate_Chat`, which sends.
- **Human‑vs‑bot detection, net‑worth comparison, pause‑on‑kill, sprays, chat wheels.** All need `PlayerResource` or `GameRules`, both nil in this VM.
- **Roshan coordination and tower‑defence execution.** `team_desires.lua` computes the desires, but acting on them needs map/entity queries the VM does not expose.

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
        ├── bot_lane.lua                     # Lane constants + role resolution helper
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
Not supported. The bot scripting VM has no `player_chat` event and no
`GameRules:SendCustomMessage`, so a bot can only send chat
(`bot:ActionImmediate_Chat`), never read it. See "Not implemented" above.

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