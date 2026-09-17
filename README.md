# AetherWeaver

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dota 2](https://img.shields.io/badge/Dota_2-Workshop_Addon-green.svg)](https://www.dota2.com/workshop/)

A smart Dota 2 bot that plays like a pro, communicates via chat wheel and messages, hints to human players, and works as a team worker. No external dependencies — pure Lua Workshop addon.

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
        └── init.lua           # Bot entry point (replace with your logic)
```

## How to Publish to Steam Workshop
1. **Clone or download** this repository
2. Open **Dota 2 Workshop Tools** (DLC required)
3. In the **Addon** panel, click **Publish** → select this folder
3. Fill in title ("AetherWeaver"), description, tags (dota2, ai, bot)
4. Set visibility to **Public** or **Friends Only**
5. Click **Upload**

## How to Use in Dota 2
1. **Subscribe** to the Workshop addon (or use local copy)
2. Create a **custom lobby** in Dota 2 Beta
3. Enable the **AetherWeaver** addon in the lobby settings
4. Launch the game — the bot will auto-join, pick a hero after human picks, and start playing

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
- Message library (`periodicMessages` table)
- Chat command handling
- Strategy logic in `BotThink`

## Requirements
- Dota 2 with Workshop Tools DLC
- Dota 2 Beta (for custom lobbies with addons)

## License
MIT — see [LICENSE](LICENSE) for details.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security
See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.