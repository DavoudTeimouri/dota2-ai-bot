# AetherWeaver

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dota 2](https://img.shields.io/badge/Dota_2-Workshop_Addon-green.svg)](https://www.dota2.com/workshop/)

A smart Dota 2 bot that plays like a pro, communicates via chat wheel and messages, hints to human players, and works as a team worker. No external dependencies — pure Lua Workshop addon. Synced to **Patch 7.41f**.

## Features
What the bot actually does today. Every line is backed by code in `vscripts/bots/`.

- **Hero Selection**: Position‑based hero pools with attribute filtering and counter‑pick weights (`hero_selection.lua`). It calls `SelectHero()` so the pick is locked in, not just announced in chat. `IsPlayerInHeroSelectionControl()` says whose turn it is, and the Captains Mode queries (`IsCMBannedHero`, `IsCMPickedHero`) say which heroes are still out. Two bots on the same team never pick the same hero.
- **Custom Bot Names**: Human‑like names from a 250‑name pool across EN/ZH/KO/RU/ES, assigned in `hero_selection.lua` so they apply in every game phase.
- **Lane Assignment**: Role‑based lane with the correct per‑team safe/offlane mapping. Lanes use the API's int constants (`LANE_TOP/MID/BOT`), normalised through `bot_lane.lua`.
- **Nine Competing Modes**: The engine calls `GetDesire()` every frame in each `mode_*_generic.lua` and runs the highest one:
  - `mode_laning_generic.lua` – hold lane, last hit, deny own dying creeps
  - `mode_farm_generic.lua` – neutral creeps (tiered) and lane wave
  - `mode_ward_generic.lua` – place wards at per‑lane spots, nearest first
  - `mode_rune_generic.lua` – contest power (2‑min) and bounty (5‑min) runes
  - `mode_item_generic.lua` – walk to the shop when the next item is affordable
  - `mode_push_lane_generic.lua` – push with a big wave and a numbers advantage
  - `mode_defend_generic.lua` – defend the tier‑1 tower that is under attack
  - `mode_retreat_generic.lua` – disengage when hurt and outnumbered
  - `mode_team_roam_generic.lua` – join allied fights, focus the lowest‑HP enemy
- **Team Strategy**: `team_desires.lua` implements the engine's team‑desire contract — `UpdatePushLaneDesires()`, `UpdateDefendLaneDesires()`, `UpdateFarmLaneDesires()`, `UpdateRoamDesire()` and `UpdateRoshanDesire()`. The engine stores those answers and the modes read them back through `GetPushLaneDesire(lane)`, `GetDefendLaneDesire(lane)`, `GetRoamDesire()` and `GetRoshanTarget()`. The push desire is higher in the lane the team outnumbers the enemy in, the defend desire spikes when a tier‑1 tower is being hit, and the farm desire drops in a contested lane.
- **Lane Rotation**: after 8 minutes a support rotates to whichever lane the team wants to defend; after 12 minutes an offlane helps the safe lane when the team wants to push it. The carry never leaves the safe lane.
- **Item Purchases**: Full per‑role build order (starter → core → luxury) with per‑item shop gating (home/side/secret) and gold thresholds. Repeated items (two tangos, three wards) are counted properly, so the bot buys every copy.
- **Per‑Hero Item Builds** (`hero_builds.lua`): the role build is the default; a hero whose role build is materially wrong for it gets its own — an early Manta for a carry that has to fight, Aghanim's Scepter and a Meteor Hammer for a mage that has to burst, a Black King Bar for an offlane that has to survive the lane.
- **Patch‑Proof Prices**: the price and the shop come from the live game (`GetItemCost`, `IsItemPurchasedFromSecretShop`, `IsItemPurchasedFromSideShop`) instead of a hand‑kept table, so an item that moves shops or changes price between patches needs no code change. `GetItemStockCount` stops the bot trying to buy an empty shelf.
- **Ability Usage**: Picks the best castable ability and the best target (closest + lowest HP) each frame.
- **Per‑Hero Rules** (`hero_rules.lua`): each hero the bot can pick has an ultimate rule — `always`, `initiate`, `burst`, `defend`, `transform` or `dodge` — so a Lion ult is saved for a low target while a Zeus ult is used the moment it is in range. Heroes whose level order differs from the default (Anti‑Mage, Invoker, Zeus, Puck, Faceless Void, Lion, Ogre Magi, Crystal Maiden, Lich, Bane) level their abilities in the right order.
- **Item Active Usage**: Dust is cast on self (no target), Orchid of Malevolence on an enemy. A neutral item picked up from a camp (slot 16) is used in a fight.
- **Skill Levelling**: Unspent ability points are spent as they appear, in the hero's own order when it has one.
- **Buyback**: Bought when dead and gold covers the cost.
- **Runes**: power and bounty runes are claimed per bot, so the team spreads over the spots instead of five bots walking to the same rune. The mid takes the power rune, because the buff is team-wide and it is closest to both spots.
- **Glyph of Fortification**: pressed by one bot while a tier‑1 tower is being hit, instead of five bots all pressing it.
- **Smoke of Deceit**: used as a group gank, only when two or more allies are nearby. A lone bot using it just walks into a gank by itself.
- **Courier**: delivers the stashed starting items, then runs items to a teammate who is stuck in lane without wards.
- **API Compatibility Layer** (`bot_compat.lua`): The bot scripting API ships in more than one shape. Every uncertain call (hero queries, inventory, ability slots, attack, move, cast, level‑up, neutral items, towers, team members) goes through this module, which tries the documented form first and falls back to the older spelling. A missing method returns "nothing found" instead of raising, so no single API difference can freeze a bot.
- **Human Detection**: `IsPlayerBot()` tells a human from a bot without `PlayerResource`, so the roam desire is higher when a human core is on the enemy team, and `GetNetWorth()` gives the net‑worth comparison the push and defend desires are built on.
- **Chat**: Contextual periodic messages (greeting, chit‑chat every 15s, a timed line every 60s) sent with `bot:ActionImmediate_Chat`. Team‑only, because the bot VM has no way to address one player. The bot can tell a human from a bot, but it cannot read a human's chat.
- **Per‑Hero Overrides**: Hero‑specific ability and skill logic via `ability_item_usage_<hero>.lua` at the bot root (see `ability_item_usage_antimage.lua`).

### Not implemented
These are not in the code, and the bot scripting VM cannot support them without a server plugin:
- **Chat commands** (`!push`, `!roshan`, `!ward`, `!lane`). The bot VM has no `player_chat` event and no `GameRules:SendCustomMessage`, so a bot cannot read player chat. The only chat API is `ActionImmediate_Chat`, which sends.
- **Pause‑on‑kill, sprays, chat wheels.** They need `GameRules` or a server plugin, both of which a bot script does not get.
- **Roshan execution.** The team sets the Roshan desire, but the API exposes no Roshan position, so the bot cannot walk to the pit. The engine's own Roshan mode uses that desire.
- **Per‑hero overrides as separate files.** Every hero is covered by `hero_rules.lua` and `hero_builds.lua` rather than 100+ near‑identical modules. A hero that needs genuinely bespoke logic still gets an `ability_item_usage_<hero>.lua` at the bot root.

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
        ├── bot_compat.lua                   # API compatibility layer (try documented, fall back)
        ├── bot_generic.lua                  # Minion AI entry point (MinionThink only)
        ├── bot_lane.lua                     # Lane constants + role resolution helper
        ├── bot_names.lua                    # Human‑like name pool (EN/ZH/KO/RU/ES)
        ├── courier_generic.lua              # Courier logic (the hook is in the ability file)
        ├── diagnostics.lua                  # Console report: API shape, state, actions
        ├── hero_builds.lua                  # Per‑hero item build overrides
        ├── hero_rules.lua                   # Per‑hero ultimate rule + level order
        ├── hero_selection.lua               # Hero pick/ban phase (SelectHero) + naming
        ├── init.lua                         # Message library + lane upkeep (BotThink)
        ├── item_purchase_generic.lua        # Generic item purchase hook with build orders
        ├── rune_generic.lua                 # Rune reset stub (required by engine)
        ├── skill_build_generic.lua          # Skill build hook (forwards to ability_item_usage)
        ├── team_desires.lua                 # Team desire calculator + the engine's five hooks
        ├── mode_defend_generic.lua          # Defend mode (tier‑1 tower under attack)
        ├── mode_farm_generic.lua            # Farm mode (neutral creeps + lane wave)
        ├── mode_item_generic.lua            # Item/shop mode (walk to shop when affordable)
        ├── mode_laning_generic.lua          # Laning mode (last hit + deny)
        ├── mode_push_lane_generic.lua       # Push mode (wave + numbers advantage)
        ├── mode_retreat_generic.lua         # Retreat mode (low HP + outnumbered)
        ├── mode_team_roam_generic.lua       # Team roam mode (join allied fights)
        ├── mode_ward_generic.lua            # Ward mode (per‑lane ward spots)
        └── mode_rune_generic.lua            # Rune mode (power + bounty runes)
```

## Tests
The bot logic runs headless under Lua 5.1, so the failure modes can be
reproduced without launching Dota 2:

```
lua5.1 tests/test_runtime.lua       # the two crashes that froze every bot
lua5.1 tests/test_engine_hooks.lua  # every engine hook is a global function
lua5.1 tests/test_probe.lua         # executes the real bot code against a fake engine
lua5.1 tests/test_lobby.lua         # one full game frame: bot must move and must buy
lua5.1 tests/test_team.lua          # team desire contract, defend mode, per‑hero rules
lua5.1 tests/test_builds.lua        # per‑hero item builds, live prices, shop, stock
```

`test_lobby.lua` is the one that matters: it drives the whole hook sequence
with a fake engine and asserts the bot issues a movement order, buys an item
at the fountain and spends its ability points.

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

### Verifying it in the lobby
The bot prints a **diagnostics report** into the console: once at the horn and
then every 30 seconds. It is the fastest way to tell a working bot from a
bot that is standing still.

```
=========================================================
 AetherWeaver diagnostics    t=300
=========================================================
--- API shape ---
[heroQuery] new
[position] new
[levelUp] new
[selectHero] yes
...
--- bot ---
[hero] npc_dota_hero_antimage
[role] carry
[lane] 3
[gold] 600
[atFountain] true
--- team ---
[push.top] 0.12
[defend.bot] 0.44
[roam] 0.00
[roshan] 0.00
[enemies] 5
[enemiesHuman] 1
--- actions since the last report ---
[moves] 18
[attacks] 4
[casts] 7
[levels] 1
[purchases] 2
=========================================================
```

What to look at:

| Line | What it means when it is wrong |
|---|---|
| `[heroQuery] none` | The bot cannot see enemies. Nothing else will work until the hero query shape is right. |
| `[hero] nil` | The bot has no hero, so it cannot move or buy. The pick never happened. |
| `[moves] 0` | The bot is not moving. Check `[atFountain]` and the team desires below it. |
| `[purchases] 0` | The bot is not buying. It has to be standing at the shop: check `[atFountain]`. |
| `[levels] 0` with `[abilityPoints] > 0` | The ability level-up call is not the shape the VM wants. |
| `[push.*] err` | The engine did not call `UpdatePushLaneDesires()`, so the team has no plan. |

Paste the report back and it says exactly what is wrong, without guessing
from the bot's behaviour in the game.

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